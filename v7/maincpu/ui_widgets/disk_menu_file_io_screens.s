
; Disk Menu & File I/O screen widgets (382 widgets, 30944 bytes)
; Source: maincpu/ui_widgets/naka_disk_menu_file_io.c (C struct with named fields)
; -----------------------------------------------------------------------------
; [nakarest_retype] registered NAKA tables: naka_disk_menu_file_io
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
; Viewable slot 0x60: RegObjTabl 0x1600010, ViewableProc, 0x4a,
; 0xea67b6, 0x60 in InitializeCheap (file_io/medley.s), i.e.
; RegisterObjectTable stores {class, proc, 74, table} at 0x27ed2 +
; 14*0x60. Element 0 is named "DiskMenu" in ResName slot 0x360. Links: 3
; of 74 records have a disagreeing link (elements 1-3); element 2 points
; outside the program ROM (RAM records).
;
; Viewable slot 0x61: RegObjTabl 0x1600010, ViewableProc, 0x80,
; 0xea68e2, 0x61 in InitializeCheap (file_io/medley.s), i.e.
; RegisterObjectTable stores {class, proc, 128, table} at 0x27ed2 +
; 14*0x61. Element 0 is named "DiskLoad" in ResName slot 0x361. Links: 2
; of 128 records have a disagreeing link (elements 73-74); element 74
; points outside the program ROM (RAM records).
;
; Viewable slot 0x62: RegObjTabl 0x1600010, ViewableProc, 0x0, 0xea6ae6,
; 0x62 in InitializeCheap (file_io/medley.s), i.e. RegisterObjectTable
; stores {class, proc, 0, table} at 0x27ed2 + 14*0x62. Element 0 is
; named "" in ResName slot 0x362. Links: all 0 records consistent.
;
; Viewable slot 0x63: RegObjTabl 0x1600010, ViewableProc, 0x0, 0xea6aea,
; 0x63 in InitializeCheap (file_io/medley.s), i.e. RegisterObjectTable
; stores {class, proc, 0, table} at 0x27ed2 + 14*0x63. Element 0 is
; named "" in ResName slot 0x363. Links: all 0 records consistent.
;
; Viewable slot 0x64: RegObjTabl 0x1600010, ViewableProc, 0x0, 0xea6aee,
; 0x64 in InitializeCheap (file_io/medley.s), i.e. RegisterObjectTable
; stores {class, proc, 0, table} at 0x27ed2 + 14*0x64. Element 0 is
; named "" in ResName slot 0x364. Links: all 0 records consistent.
;
; Viewable slot 0x65: RegObjTabl 0x1600010, ViewableProc, 0x3, 0xea6af2,
; 0x65 in InitializeCheap (file_io/medley.s), i.e. RegisterObjectTable
; stores {class, proc, 3, table} at 0x27ed2 + 14*0x65. Element 0 is
; named "DiskSaveMenu" in ResName slot 0x365. Links: all 3 records
; consistent.
;
; Viewable slot 0x66: RegObjTabl 0x1600010, ViewableProc, 0x0, 0xea6b02,
; 0x66 in InitializeCheap (file_io/medley.s), i.e. RegisterObjectTable
; stores {class, proc, 0, table} at 0x27ed2 + 14*0x66. Element 0 is
; named "" in ResName slot 0x366. Links: all 0 records consistent.
;
; Viewable slot 0x67: RegObjTabl 0x1600010, ViewableProc, 0x47,
; 0xea6b06, 0x67 in InitializeCheap (file_io/medley.s), i.e.
; RegisterObjectTable stores {class, proc, 71, table} at 0x27ed2 +
; 14*0x67. Element 0 is named "DiskSave" in ResName slot 0x367. Links:
; all 71 records consistent.
;
; Viewable slot 0x6a: RegObjTabl 0x1600010, ViewableProc, 0x0, 0xea6c26,
; 0x6a in InitializeCheap (file_io/medley.s), i.e. RegisterObjectTable
; stores {class, proc, 0, table} at 0x27ed2 + 14*0x6a. Element 0 is
; named "" in ResName slot 0x36a. Links: all 0 records consistent.
;
; Viewable slot 0x6b: RegObjTabl 0x1600010, ViewableProc, 0x15,
; 0xea6c2a, 0x6b in InitializeCheap (file_io/medley.s), i.e.
; RegisterObjectTable stores {class, proc, 21, table} at 0x27ed2 +
; 14*0x6b. Element 0 is named "DiskSmfSave" in ResName slot 0x36b.
; Links: all 21 records consistent.
;
; Viewable slot 0x6c: RegObjTabl 0x1600010, ViewableProc, 0x53,
; 0xea6c82, 0x6c in InitializeCheap (file_io/medley.s), i.e.
; RegisterObjectTable stores {class, proc, 83, table} at 0x27ed2 +
; 14*0x6c. Element 0 is named "DiskSmfDirectPlay" in ResName slot 0x36c.
; Links: all 83 records consistent.
;
; Viewable slot 0x6d: RegObjTabl 0x1600010, ViewableProc, 0x0, 0xea6dd2,
; 0x6d in InitializeCheap (file_io/medley.s), i.e. RegisterObjectTable
; stores {class, proc, 0, table} at 0x27ed2 + 14*0x6d. Element 0 is
; named "" in ResName slot 0x36d. Links: all 0 records consistent.
;
; Viewable slot 0x6e: RegObjTabl 0x1600010, ViewableProc, 0x0, 0xea6dd6,
; 0x6e in InitializeCheap (file_io/medley.s), i.e. RegisterObjectTable
; stores {class, proc, 0, table} at 0x27ed2 + 14*0x6e. Element 0 is
; named "" in ResName slot 0x36e. Links: all 0 records consistent.
;
; Viewable slot 0x77: RegObjTabl 0x1600010, ViewableProc, 0x15,
; 0xea6dda, 0x77 in InitializeCheap (file_io/medley.s), i.e.
; RegisterObjectTable stores {class, proc, 21, table} at 0x27ed2 +
; 14*0x77. Element 0 is named "DiskSongMedley" in ResName slot 0x377.
; Links: all 21 records consistent.
;
; Viewable slot 0x79: RegObjTabl 0x1600010, ViewableProc, 0x0, 0xea6e32,
; 0x79 in InitializeCheap (file_io/medley.s), i.e. RegisterObjectTable
; stores {class, proc, 0, table} at 0x27ed2 + 14*0x79. Element 0 is
; named "" in ResName slot 0x379. Links: all 0 records consistent.
;
; Viewable slot 0x7b: RegObjTabl 0x1600010, ViewableProc, 0x5e,
; 0xea6e36, 0x7b in InitializeCheap (file_io/medley.s), i.e.
; RegisterObjectTable stores {class, proc, 94, table} at 0x27ed2 +
; 14*0x7b. Element 0 is named "DiskUtility" in ResName slot 0x37b.
; Links: all 94 records consistent.
;
; Viewable slot 0x7c: RegObjTabl 0x1600010, ViewableProc, 0x0, 0xea6fb2,
; 0x7c in InitializeCheap (file_io/medley.s), i.e. RegisterObjectTable
; stores {class, proc, 0, table} at 0x27ed2 + 14*0x7c. Element 0 is
; named "" in ResName slot 0x37c. Links: all 0 records consistent.
;
; Viewable slot 0x7d: RegObjTabl 0x1600010, ViewableProc, 0x0, 0xea6fb6,
; 0x7d in InitializeCheap (file_io/medley.s), i.e. RegisterObjectTable
; stores {class, proc, 0, table} at 0x27ed2 + 14*0x7d. Element 0 is
; named "" in ResName slot 0x37d. Links: all 0 records consistent.
;
; Viewable slot 0x7e: RegObjTabl 0x1600010, ViewableProc, 0x8, 0xea6fba,
; 0x7e in InitializeCheap (file_io/medley.s), i.e. RegisterObjectTable
; stores {class, proc, 8, table} at 0x27ed2 + 14*0x7e. Element 0 is
; named "DiskSetup" in ResName slot 0x37e. Links: all 8 records
; consistent.
;
; Viewable slot 0xbc: RegObjTabl 0x1600010, ViewableProc, 0x0, 0xea6fde,
; 0xbc in InitializeCheap (file_io/medley.s), i.e. RegisterObjectTable
; stores {class, proc, 0, table} at 0x27ed2 + 14*0xbc. Element 0 is
; named "" in ResName slot 0x3bc. Links: all 0 records consistent.
;
; MainFunction slot 0x145: RegObjTabl 0x1600003, MainFunctionProc, 0x39,
; 0xea7fce, 0x145 in InitializeCheap (file_io/medley.s), i.e.
; RegisterObjectTable stores {class, proc, 57, table} at 0x27ed2 +
; 14*0x145.
;
; ResName slot 0x360: RegObjTabl 0x160000f, ResNameProc, 0x4a, 0xea6fe2,
; 0x360 in InitializeCheap (file_io/medley.s), i.e. RegisterObjectTable
; stores {class, proc, 74, table} at 0x27ed2 + 14*0x360.
;
; ResName slot 0x361: RegObjTabl 0x160000f, ResNameProc, 0x80, 0xea7228,
; 0x361 in InitializeCheap (file_io/medley.s), i.e. RegisterObjectTable
; stores {class, proc, 128, table} at 0x27ed2 + 14*0x361.
;
; ResName slot 0x362: RegObjTabl 0x160000f, ResNameProc, 0x0, 0xea75c6,
; 0x362 in InitializeCheap (file_io/medley.s), i.e. RegisterObjectTable
; stores {class, proc, 0, table} at 0x27ed2 + 14*0x362.
;
; ResName slot 0x363: RegObjTabl 0x160000f, ResNameProc, 0x0, 0xea75cc,
; 0x363 in InitializeCheap (file_io/medley.s), i.e. RegisterObjectTable
; stores {class, proc, 0, table} at 0x27ed2 + 14*0x363.
;
; ResName slot 0x364: RegObjTabl 0x160000f, ResNameProc, 0x0, 0xea75d2,
; 0x364 in InitializeCheap (file_io/medley.s), i.e. RegisterObjectTable
; stores {class, proc, 0, table} at 0x27ed2 + 14*0x364.
;
; ResName slot 0x365: RegObjTabl 0x160000f, ResNameProc, 0x3, 0xea75d8,
; 0x365 in InitializeCheap (file_io/medley.s), i.e. RegisterObjectTable
; stores {class, proc, 3, table} at 0x27ed2 + 14*0x365.
;
; ResName slot 0x366: RegObjTabl 0x160000f, ResNameProc, 0x0, 0xea75fc,
; 0x366 in InitializeCheap (file_io/medley.s), i.e. RegisterObjectTable
; stores {class, proc, 0, table} at 0x27ed2 + 14*0x366.
;
; ResName slot 0x367: RegObjTabl 0x160000f, ResNameProc, 0x47, 0xea7602,
; 0x367 in InitializeCheap (file_io/medley.s), i.e. RegisterObjectTable
; stores {class, proc, 71, table} at 0x27ed2 + 14*0x367.
;
; ResName slot 0x36a: RegObjTabl 0x160000f, ResNameProc, 0x0, 0xea77e4,
; 0x36a in InitializeCheap (file_io/medley.s), i.e. RegisterObjectTable
; stores {class, proc, 0, table} at 0x27ed2 + 14*0x36a.
;
; ResName slot 0x36b: RegObjTabl 0x160000f, ResNameProc, 0x15, 0xea77ea,
; 0x36b in InitializeCheap (file_io/medley.s), i.e. RegisterObjectTable
; stores {class, proc, 21, table} at 0x27ed2 + 14*0x36b.
;
; ResName slot 0x36c: RegObjTabl 0x160000f, ResNameProc, 0x53, 0xea7878,
; 0x36c in InitializeCheap (file_io/medley.s), i.e. RegisterObjectTable
; stores {class, proc, 83, table} at 0x27ed2 + 14*0x36c.
;
; ResName slot 0x36d: RegObjTabl 0x160000f, ResNameProc, 0x0, 0xea7aca,
; 0x36d in InitializeCheap (file_io/medley.s), i.e. RegisterObjectTable
; stores {class, proc, 0, table} at 0x27ed2 + 14*0x36d.
;
; ResName slot 0x36e: RegObjTabl 0x160000f, ResNameProc, 0x0, 0xea7ad0,
; 0x36e in InitializeCheap (file_io/medley.s), i.e. RegisterObjectTable
; stores {class, proc, 0, table} at 0x27ed2 + 14*0x36e.
;
; ResName slot 0x377: RegObjTabl 0x160000f, ResNameProc, 0x15, 0xea7ad6,
; 0x377 in InitializeCheap (file_io/medley.s), i.e. RegisterObjectTable
; stores {class, proc, 21, table} at 0x27ed2 + 14*0x377.
;
; ResName slot 0x379: RegObjTabl 0x160000f, ResNameProc, 0x0, 0xea7b8c,
; 0x379 in InitializeCheap (file_io/medley.s), i.e. RegisterObjectTable
; stores {class, proc, 0, table} at 0x27ed2 + 14*0x379.
;
; ResName slot 0x37b: RegObjTabl 0x160000f, ResNameProc, 0x5e, 0xea7b92,
; 0x37b in InitializeCheap (file_io/medley.s), i.e. RegisterObjectTable
; stores {class, proc, 94, table} at 0x27ed2 + 14*0x37b.
;
; ResName slot 0x37c: RegObjTabl 0x160000f, ResNameProc, 0x0, 0xea7e98,
; 0x37c in InitializeCheap (file_io/medley.s), i.e. RegisterObjectTable
; stores {class, proc, 0, table} at 0x27ed2 + 14*0x37c.
;
; ResName slot 0x37d: RegObjTabl 0x160000f, ResNameProc, 0x0, 0xea7e9e,
; 0x37d in InitializeCheap (file_io/medley.s), i.e. RegisterObjectTable
; stores {class, proc, 0, table} at 0x27ed2 + 14*0x37d.
;
; ResName slot 0x37e: RegObjTabl 0x160000f, ResNameProc, 0x8, 0xea7ea4,
; 0x37e in InitializeCheap (file_io/medley.s), i.e. RegisterObjectTable
; stores {class, proc, 8, table} at 0x27ed2 + 14*0x37e.
;
; ResName slot 0x3bc: RegObjTabl 0x160000f, ResNameProc, 0x0, 0xea7ee2,
; 0x3bc in InitializeCheap (file_io/medley.s), i.e. RegisterObjectTable
; stores {class, proc, 0, table} at 0x27ed2 + 14*0x3bc.
;
; Function slot 0x405: RegObjTabl 0x1600001, FunctionProc, 0xd,
; 0xea1392, 0x405 in InitializeCheap (file_io/medley.s), i.e.
; RegisterObjectTable stores {class, proc, 13, table} at 0x27ed2 +
; 14*0x405.
;
; MainFunction slot 0x445: RegObjTabl 0x1600003, MainFunctionProc, 0x39,
; 0xea80b6, 0x445 in InitializeCheap (file_io/medley.s), i.e.
; RegisterObjectTable stores {class, proc, 57, table} at 0x27ed2 +
; 14*0x445.
; -----------------------------------------------------------------------------

; [nakarest] NakaInst_IvWaitWinCtlProc  +0x0..+0x12 (0xea13cc, 18 B)
; [nakarest] name string, entry 12 of Function slot 0x405 (table 0xea1392, 13 entries,
; [nakarest] InitializeCheap) (names for Function slot 0x105): "IvWaitWinCtlProc".
NakaInst_IvWaitWinCtlProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x0, 0x12
; [nakarest] NakaInst_IvIndexSwDelayProc  +0x12..+0x26 (0xea13de, 20 B)
; [nakarest] name string, entry 11 of Function slot 0x405 (table 0xea1392, 13 entries,
; [nakarest] InitializeCheap) (names for Function slot 0x105): "IvIndexSwDelayProc".
NakaInst_IvIndexSwDelayProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x12, 0x14
; [nakarest] NakaInst_AcRotStrBoxProc  +0x26..+0x36 (0xea13f2, 16 B)
; [nakarest] name string, entry 10 of Function slot 0x405 (table 0xea1392, 13 entries,
; [nakarest] InitializeCheap) (names for Function slot 0x105): "AcRotStrBoxProc".
NakaInst_AcRotStrBoxProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x26, 0x10
; [nakarest] NakaInst_IvIndexSwCtrlProc  +0x36..+0x48 (0xea1402, 18 B)
; [nakarest] name string, entry 9 of Function slot 0x405 (table 0xea1392, 13 entries,
; [nakarest] InitializeCheap) (names for Function slot 0x105): "IvIndexSwCtrlProc".
NakaInst_IvIndexSwCtrlProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x36, 0x12
; [nakarest] NakaInst_ArrowProc  +0x48..+0x52 (0xea1414, 10 B)
; [nakarest] name string, entry 8 of Function slot 0x405 (table 0xea1392, 13 entries,
; [nakarest] InitializeCheap) (names for Function slot 0x105): "ArrowProc".
NakaInst_ArrowProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x48, 0xA
; [nakarest] NakaInst_VwScreenTitleProc  +0x52..+0x64 (0xea141e, 18 B)
; [nakarest] name string, entry 7 of Function slot 0x405 (table 0xea1392, 13 entries,
; [nakarest] InitializeCheap) (names for Function slot 0x105): "VwScreenTitleProc".
NakaInst_VwScreenTitleProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x52, 0x12
; [nakarest] NakaInst_IvOneShotTimerProc  +0x64..+0x78 (0xea1430, 20 B)
; [nakarest] name string, entry 6 of Function slot 0x405 (table 0xea1392, 13 entries,
; [nakarest] InitializeCheap) (names for Function slot 0x105): "IvOneShotTimerProc".
NakaInst_IvOneShotTimerProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x64, 0x14
; [nakarest] NakaInst_AcMonoIndexToggleProc  +0x78..+0x8e (0xea1444, 22 B)
; [nakarest] name string, entry 5 of Function slot 0x405 (table 0xea1392, 13 entries,
; [nakarest] InitializeCheap) (names for Function slot 0x105): "AcMonoIndexToggleProc".
NakaInst_AcMonoIndexToggleProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x78, 0x16
; [nakarest] NakaInst_AcFileSfxBoxProc  +0x8e..+0xa0 (0xea145a, 18 B)
; [nakarest] name string, entry 4 of Function slot 0x405 (table 0xea1392, 13 entries,
; [nakarest] InitializeCheap) (names for Function slot 0x105): "AcFileSfxBoxProc".
NakaInst_AcFileSfxBoxProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x8E, 0x12
; [nakarest] NakaInst_AcParaStrBoxProc  +0xa0..+0xb2 (0xea146c, 18 B)
; [nakarest] name string, entry 3 of Function slot 0x405 (table 0xea1392, 13 entries,
; [nakarest] InitializeCheap) (names for Function slot 0x105): "AcParaStrBoxProc".
NakaInst_AcParaStrBoxProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xA0, 0x12
; [nakarest] NakaInst_AcTtlJgBoxProc  +0xb2..+0xc2 (0xea147e, 16 B)
; [nakarest] name string, entry 2 of Function slot 0x405 (table 0xea1392, 13 entries,
; [nakarest] InitializeCheap) (names for Function slot 0x105): "AcTtlJgBoxProc".
NakaInst_AcTtlJgBoxProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xB2, 0x10
; [nakarest] NakaInst_PsWindowToggleProc  +0xc2..+0xd6 (0xea148e, 20 B)
; [nakarest] name string, entry 1 of Function slot 0x405 (table 0xea1392, 13 entries,
; [nakarest] InitializeCheap) (names for Function slot 0x105): "PsWindowToggleProc".
NakaInst_PsWindowToggleProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xC2, 0x14
; [nakarest] NakaInst_PsFileNameBoxProc  +0xd6..+0xe8 (0xea14a2, 18 B)
; [nakarest] name string, entry 0 of Function slot 0x405 (table 0xea1392, 13 entries,
; [nakarest] InitializeCheap) (names for Function slot 0x105): "PsFileNameBoxProc".
NakaInst_PsFileNameBoxProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xD6, 0x12
; [nakarest] naka_disk_menu_file_io+0xe8  +0xe8..+0xd76 (0xea14b4, 3214 B)
; [nakarest] widget records, elements 0-1, 3-73 of Viewable slot 0x60 (table 0xea67b6, 74
; [nakarest] entries, InitializeCheap) ("DiskMenu"): TtlScreen (42 B) x6, AcTitleMenu (54 B) x3,
; [nakarest] AcTtlJgBox (54 B) x4, IvExitMode (26 B) x2, AcIndexWideES (42 B) x3, AcIndexEditSw
; [nakarest] (40 B) x9, PsFileNameBox (58 B) x4, Line (26 B) x2, AcMonoIndexToggle (42 B), Label
; [nakarest] (32 B) x10, IvOneShotTimer (26 B), AcFuncEditSw (44 B) x9, IvNaming (26 B) x4,
; [nakarest] AcParaStrBox (44 B) x4, Window (36 B) x4, AcRotStrBox (48 B), VwBox (28 B),
; [nakarest] AcLanguageText (42 B) x5. 25 texts the records point at (Viewable slot 0x60 (table
; [nakarest] 0xea67b6, 74 entries, InitializeCheap)): "DISK MENU" (TtlScreen.title of element
; [nakarest] 0); "STYLE CONVERT" (AcTitleMenu.str of element 1); "PREFERENCES" (AcTitleMenu.str
; [nakarest] of element 3); "SAVE" (AcTitleMenu.str of element 4); ....
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xE8, 0xC8E
; [nakarest] naka_disk_menu_file_io+0xd76  +0xd76..+0x22a0 (0xea2142, 5418 B)
; [nakarest] widget records, elements 0-73, 75-127 of Viewable slot 0x61 (table 0xea68e2, 128
; [nakarest] entries, InitializeCheap) ("DiskLoad"): TtlScreen (42 B) x3, AcWindowPage (36 B),
; [nakarest] IvPageControl (28 B) x3, IvExit (22 B) x2, IvMainEditSw (26 B) x2, Window (36 B)
; [nakarest] x5, PsFileNameBox (58 B) x20, AcIndexEditSw (40 B) x24, Label (32 B) x33,
; [nakarest] AcFileSfxBox (34 B), AcTitleMenu (54 B) x2, AcIndexWideES (42 B) x10, AcParaStrBox
; [nakarest] (44 B) x7, VwScreenTitle (38 B) x3, VwBox (28 B), Line (26 B), IvIndexSwCtrl (32 B)
; [nakarest] x2, IvIndexSwDelay (30 B) x3, Arrow (32 B) x2, PsWindowToggle (52 B),
; [nakarest] AcMonoIndexToggle (42 B). 45 texts the records point at (Viewable slot 0x61 (table
; [nakarest] 0xea68e2, 128 entries, InitializeCheap)): "" (TtlScreen.title of element 0); "LOAD"
; [nakarest] (Label.str of element 10); "DISK NAME:" (Label.str of element 12); "SMF"
; [nakarest] (AcTitleMenu.str of element 13); ....
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xD76, 0x152A
; [nakarest] naka_disk_menu_file_io+0x22a0  +0x22a0..+0x235a (0xea366c, 186 B)
; [nakarest] widget records, elements 0-2 of Viewable slot 0x65 (table 0xea6af2, 3 entries,
; [nakarest] InitializeCheap) ("DiskSaveMenu"): TtlScreen (42 B), AcTtlJgBox (54 B) x2. 3 texts
; [nakarest] the records point at (Viewable slot 0x65 (table 0xea6af2, 3 entries,
; [nakarest] InitializeCheap)): "SAVE" (TtlScreen.title of element 0); "TECHNICS FORMAT"
; [nakarest] (AcTtlJgBox.str of element 1); "SMF FORMAT 0" (AcTtlJgBox.str of element 2).
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x22A0, 0xBA
; [nakarest] naka_disk_menu_file_io+0x235a  +0x235a..+0x2e60 (0xea3726, 2822 B)
; [nakarest] widget records, elements 0-70 of Viewable slot 0x67 (table 0xea6b06, 71 entries,
; [nakarest] InitializeCheap) ("DiskSave"): TtlScreen (42 B), AcWindowPage (36 B), IvPageControl
; [nakarest] (28 B) x3, IvExit (22 B), IvMainEditSw (26 B), Window (36 B) x3, AcIndexWideES (42
; [nakarest] B) x2, AcIndexEditSw (40 B) x16, AcParaStrBox (44 B) x4, Label (32 B) x26,
; [nakarest] AcTitleMenu (54 B), PsFileNameBox (58 B) x3, AcFileSfxBox (34 B), IvCatchEvent (26
; [nakarest] B) x3, VwScreenTitle (38 B) x3, VwBox (28 B), Line (26 B). 31 texts the records
; [nakarest] point at (Viewable slot 0x67 (table 0xea6b06, 71 entries, InitializeCheap)): ""
; [nakarest] (TtlScreen.title of element 0); "SAVE AS :" (Label.str of element 12); "NAME"
; [nakarest] (AcTitleMenu.str of element 14); "SAVE" (Label.str of element 17); ....
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x235A, 0xB06
; [nakarest] naka_disk_menu_file_io+0x2e60  +0x2e60..+0x322e (0xea422c, 974 B)
; [nakarest] widget records, elements 0-20 of Viewable slot 0x6b (table 0xea6c2a, 21 entries,
; [nakarest] InitializeCheap) ("DiskSmfSave"): TtlScreen (42 B), PsFileNameBox (58 B) x4,
; [nakarest] AcIndexWideES (42 B), AcIndexEditSw (40 B) x4, Label (32 B) x7, AcMonoIndexToggle
; [nakarest] (42 B) x2, AcTitleMenu (54 B), AcParaStrBox (44 B). 13 texts the records point at
; [nakarest] (Viewable slot 0x6b (table 0xea6c2a, 21 entries, InitializeCheap)): "SMF SAVE"
; [nakarest] (TtlScreen.title of element 0); "PREV" (Label.str of element 4); "NEXT" (Label.str
; [nakarest] of element 6); "OFF" (AcMonoIndexToggle.stroff of element 7); ....
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2E60, 0x3CE
; [nakarest] naka_disk_menu_file_io+0x322e  +0x322e..+0x3f20 (0xea45fa, 3314 B)
; [nakarest] widget records, elements 0-82 of Viewable slot 0x6c (table 0xea6c82, 83 entries,
; [nakarest] InitializeCheap) ("DiskSmfDirectPlay"): TtlScreen (42 B) x3, PsFileNameBox (58 B)
; [nakarest] x6, AcIndexWideES (42 B) x3, AcIndexEditSw (40 B) x17, Label (32 B) x26,
; [nakarest] PsWindowToggle (52 B), AcMonoIndexToggle (42 B) x5, Line (26 B) x12, IvOneShotTimer
; [nakarest] (26 B) x3, IvIndexSwDelay (30 B), Window (36 B) x2, AcParaStrBox (44 B) x4. 41
; [nakarest] texts the records point at (Viewable slot 0x6c (table 0xea6c82, 83 entries,
; [nakarest] InitializeCheap)): "SMF DIRECT PLAY" (TtlScreen.title of element 0); "PREV"
; [nakarest] (Label.str of element 5); "NEXT" (Label.str of element 7); "INFO" (Label.str of
; [nakarest] element 8); ....
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x322E, 0xCF2
; [nakarest] naka_disk_menu_file_io+0x3f20  +0x3f20..+0x42b8 (0xea52ec, 920 B)
; [nakarest] widget records, elements 0-20 of Viewable slot 0x77 (table 0xea6dda, 21 entries,
; [nakarest] InitializeCheap) ("DiskSongMedley"): TtlScreen (42 B), AcIndexEditSw (40 B) x5,
; [nakarest] AcIndexWideES (42 B), PsFileNameBox (58 B) x3, Label (32 B) x6, AcParaStrBox (44 B)
; [nakarest] x2, AcMonoIndexToggle (42 B) x2, IvShowHide (26 B). 11 texts the records point at
; [nakarest] (Viewable slot 0x77 (table 0xea6dda, 21 entries, InitializeCheap)): "SONG MEDLEY"
; [nakarest] (TtlScreen.title of element 0); "DISK NAME:" (Label.str of element 7); "START"
; [nakarest] (Label.str of element 11); "ALL" (Label.str of element 13); ....
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3F20, 0x398
; [nakarest] naka_disk_menu_file_io+0x42b8  +0x42b8..+0x5250 (0xea5684, 3992 B)
; [nakarest] widget records, elements 0-93 of Viewable slot 0x7b (table 0xea6e36, 94 entries,
; [nakarest] InitializeCheap) ("DiskUtility"): TtlScreen (42 B) x3, AcIndexWideES (42 B) x3,
; [nakarest] AcIndexEditSw (40 B) x9, AcTitleMenu (54 B) x4, Label (32 B) x18, AcScreenMenu (54
; [nakarest] B) x3, AcParaStrBox (44 B) x6, PsFileNameBox (58 B) x3, IvWaitWinCtl (26 B) x2,
; [nakarest] Screen (34 B) x5, VwScreenTitle (38 B) x3, IvNaming (26 B) x3, AcFuncEditSw (44 B)
; [nakarest] x6, PsWindowToggle (52 B), IvIndexSwDelay (30 B), Window (36 B) x6, IvMainEditSw
; [nakarest] (26 B) x3, VwBox (28 B) x2, AcLanguageText (42 B) x6, Line (26 B) x2, VwEditSwBox
; [nakarest] (44 B) x2, VwMenuBox (50 B) x2, Arrow (32 B). 37 texts the records point at
; [nakarest] (Viewable slot 0x7b (table 0xea6e36, 94 entries, InitializeCheap)): "DISK TOOLS"
; [nakarest] (TtlScreen.title of element 0); "SMF" (AcTitleMenu.str of element 4); "DISK NAME:"
; [nakarest] (Label.str of element 5); "DEL" (Label.str of element 8); ....
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x42B8, 0xF98
; [nakarest] naka_disk_menu_file_io+0x5250  +0x5250..+0x53ea (0xea661c, 410 B)
; [nakarest] widget records, elements 0-7 of Viewable slot 0x7e (table 0xea6fba, 8 entries,
; [nakarest] InitializeCheap) ("DiskSetup"): TtlScreen (42 B), AcIndexWideES (42 B),
; [nakarest] AcRamEditBox (58 B), AcBitEditBox (58 B), AcFuncEditSw (44 B), IvCatchEvent (26 B),
; [nakarest] AcLanguageText (42 B) x2. 3 texts the records point at (Viewable slot 0x7e (table
; [nakarest] 0xea6fba, 8 entries, InitializeCheap)): "PREFERENCES" (TtlScreen.title of element
; [nakarest] 0); "DISK INSERT OPTION :" (AcRamEditBox.caption of element 2); "FILE TYPE PRIORITY
; [nakarest] :" (AcBitEditBox.caption of element 3).
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5250, 0x19A
; [nakarest] naka_disk_menu_file_io+0x53ea  +0x53ea..+0x5516 (0xea67b6, 300 B)
; [nakarest] the table itself: Viewable slot 0x60 (table 0xea67b6, 74 entries, InitializeCheap),
; [nakarest] 74 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x53EA, 0x12C
; [nakarest] naka_disk_menu_file_io+0x5516  +0x5516..+0x571a (0xea68e2, 516 B)
; [nakarest] the table itself: Viewable slot 0x61 (table 0xea68e2, 128 entries,
; [nakarest] InitializeCheap), 128 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5516, 0x204
; [nakarest] naka_disk_menu_file_io+0x571a  +0x571a..+0x571e (0xea6ae6, 4 B)
; [nakarest] the table itself: Viewable slot 0x62 (table 0xea6ae6, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x571A, 0x4
; [nakarest] naka_disk_menu_file_io+0x571e  +0x571e..+0x5722 (0xea6aea, 4 B)
; [nakarest] the table itself: Viewable slot 0x63 (table 0xea6aea, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x571E, 0x4
; [nakarest] naka_disk_menu_file_io+0x5722  +0x5722..+0x5726 (0xea6aee, 4 B)
; [nakarest] the table itself: Viewable slot 0x64 (table 0xea6aee, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5722, 0x4
; [nakarest] naka_disk_menu_file_io+0x5726  +0x5726..+0x5736 (0xea6af2, 16 B)
; [nakarest] the table itself: Viewable slot 0x65 (table 0xea6af2, 3 entries, InitializeCheap),
; [nakarest] 3 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5726, 0x10
; [nakarest] naka_disk_menu_file_io+0x5736  +0x5736..+0x573a (0xea6b02, 4 B)
; [nakarest] the table itself: Viewable slot 0x66 (table 0xea6b02, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5736, 0x4
; [nakarest] naka_disk_menu_file_io+0x573a  +0x573a..+0x585a (0xea6b06, 288 B)
; [nakarest] the table itself: Viewable slot 0x67 (table 0xea6b06, 71 entries, InitializeCheap),
; [nakarest] 71 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x573A, 0x120
; [nakarest] naka_disk_menu_file_io+0x585a  +0x585a..+0x585e (0xea6c26, 4 B)
; [nakarest] the table itself: Viewable slot 0x6a (table 0xea6c26, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x585A, 0x4
; [nakarest] naka_disk_menu_file_io+0x585e  +0x585e..+0x58b6 (0xea6c2a, 88 B)
; [nakarest] the table itself: Viewable slot 0x6b (table 0xea6c2a, 21 entries, InitializeCheap),
; [nakarest] 21 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x585E, 0x58
; [nakarest] naka_disk_menu_file_io+0x58b6  +0x58b6..+0x5a06 (0xea6c82, 336 B)
; [nakarest] the table itself: Viewable slot 0x6c (table 0xea6c82, 83 entries, InitializeCheap),
; [nakarest] 83 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x58B6, 0x150
; [nakarest] naka_disk_menu_file_io+0x5a06  +0x5a06..+0x5a0a (0xea6dd2, 4 B)
; [nakarest] the table itself: Viewable slot 0x6d (table 0xea6dd2, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5A06, 0x4
; [nakarest] naka_disk_menu_file_io+0x5a0a  +0x5a0a..+0x5a0e (0xea6dd6, 4 B)
; [nakarest] the table itself: Viewable slot 0x6e (table 0xea6dd6, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5A0A, 0x4
; [nakarest] naka_disk_menu_file_io+0x5a0e  +0x5a0e..+0x5a66 (0xea6dda, 88 B)
; [nakarest] the table itself: Viewable slot 0x77 (table 0xea6dda, 21 entries, InitializeCheap),
; [nakarest] 21 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5A0E, 0x58
; [nakarest] naka_disk_menu_file_io+0x5a66  +0x5a66..+0x5a6a (0xea6e32, 4 B)
; [nakarest] the table itself: Viewable slot 0x79 (table 0xea6e32, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5A66, 0x4
; [nakarest] naka_disk_menu_file_io+0x5a6a  +0x5a6a..+0x5be6 (0xea6e36, 380 B)
; [nakarest] the table itself: Viewable slot 0x7b (table 0xea6e36, 94 entries, InitializeCheap),
; [nakarest] 94 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5A6A, 0x17C
; [nakarest] naka_disk_menu_file_io+0x5be6  +0x5be6..+0x5bea (0xea6fb2, 4 B)
; [nakarest] the table itself: Viewable slot 0x7c (table 0xea6fb2, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5BE6, 0x4
; [nakarest] naka_disk_menu_file_io+0x5bea  +0x5bea..+0x5bee (0xea6fb6, 4 B)
; [nakarest] the table itself: Viewable slot 0x7d (table 0xea6fb6, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5BEA, 0x4
; [nakarest] naka_disk_menu_file_io+0x5bee  +0x5bee..+0x5c12 (0xea6fba, 36 B)
; [nakarest] the table itself: Viewable slot 0x7e (table 0xea6fba, 8 entries, InitializeCheap),
; [nakarest] 8 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5BEE, 0x24
; [nakarest] naka_disk_menu_file_io+0x5c12  +0x5c12..+0x5c16 (0xea6fde, 4 B)
; [nakarest] the table itself: Viewable slot 0xbc (table 0xea6fde, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5C12, 0x4
; [nakarest] naka_disk_menu_file_io+0x5c16  +0x5c16..+0x5d44 (0xea6fe2, 302 B)
; [nakarest] the table itself: ResName slot 0x360 (table 0xea6fe2, 74 entries, InitializeCheap),
; [nakarest] 74 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5C16, 0x12E
; [nakarest] naka_disk_menu_file_io+0x5d44  +0x5d44..+0x5e5c (0xea7110, 280 B)
; [nakarest] name strings, entries 0-73 of ResName slot 0x360 (table 0xea6fe2, 74 entries,
; [nakarest] InitializeCheap) (names for Viewable slot 0x60): "", "", "", "",
; [nakarest] "CheckPasswordWin", "", ....
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5D44, 0x118
; [nakarest] naka_disk_menu_file_io+0x5e5c  +0x5e5c..+0x5f00 (0xea7228, 164 B)
; [nakarest] the table itself: ResName slot 0x361 (table 0xea7228, 128 entries,
; [nakarest] InitializeCheap), 128 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5E5C, 0xA4
EmbeddedPtrTable_v7_naka_disk_menu_file_io_005F00:
	.long 0x00EA754A
	.long 0x00EA7548
	.long 0x00EA7546
	.long 0x00EA7544
	.long 0x00EA7542
	.long 0x00EA7540
	.long 0x00EA753E
	.long 0x00EA753C
	.long 0x00EA753A
	.long 0x00EA7538
	.long 0x00EA7536
	.long 0x00EA752A
	.long 0x00EA7528
	.long 0x00EA7518
	.long 0x00EA7516
	.long 0x00EA7514
	.long 0x00EA7512
	.long 0x00EA7510
	.long 0x00EA750E
	.long 0x00EA750C
	.long 0x00EA750A
	.long 0x00EA7508
	.long 0x00EA7506
	.long 0x00EA7504
	.long 0x00EA7502
	.long 0x00EA7500
	.long 0x00EA74FE
	.long 0x00EA74FC
	.long 0x00EA74FA
	.long 0x00EA74F8
	.long 0x00EA74F6
	.long 0x00EA74F4
	.long 0x00EA74F2
	.long 0x00EA74E0
	.long 0x00EA74D4
	.long 0x00EA74D2
	.long 0x00EA74D0
	.long 0x00EA74CE
	.long 0x00EA74CC
	.long 0x00EA74CA
	.long 0x00EA74C8
	.long 0x00EA74C6
	.long 0x00EA74C4
	.long 0x00EA74C2
	.long 0x00EA74C0
	.long 0x00EA74BE
	.long 0x00EA74BC
	.long 0x00EA74BA
	.long 0x00EA74B8
	.long 0x00EA74B6
	.long 0x00EA74B4
	.long 0x00EA74B2
	.long 0x00EA74B0
	.long 0x00EA74AE
	.long 0x00EA749C
	.long 0x00EA749A
	.long 0x00EA7498
	.long 0x00EA7496
	.long 0x00EA7484
	.long 0x00EA7482
	.long 0x00EA7480
	.long 0x00EA747E
	.long 0x00EA747C
	.long 0x00EA747A
; [nakarest] naka_disk_menu_file_io+0x6000  +0x6000..+0x6062 (0xea73cc, 98 B)
; [nakarest] purpose not established: 6 B at 0xea7428 that no registered NAKA table, symbol, 24/32-bit literal or data word points into
; [nakarest] Continues the table itself: ResName slot 0x361 (table 0xea7228, 128 entries,
; [nakarest] InitializeCheap), 128 entry pointers x 4 bytes (starts 0xea7228, 92 of its 512
; [nakarest] bytes are here or later).
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6000, 0x62
; [nakarest] naka_disk_menu_file_io+0x6062  +0x6062..+0x61fa (0xea742e, 408 B)
; [nakarest] name strings, entries 0-127 of ResName slot 0x361 (table 0xea7228, 128 entries,
; [nakarest] InitializeCheap) (names for Viewable slot 0x61): "", "CmpSingleLoadSwCtl", "", "",
; [nakarest] "", "", ....
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6062, 0x198
; [nakarest] naka_disk_menu_file_io+0x61fa  +0x61fa..+0x6200 (0xea75c6, 6 B)
; [nakarest] the table itself: ResName slot 0x362 (table 0xea75c6, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x61FA, 0x6
; [nakarest] naka_disk_menu_file_io+0x6200  +0x6200..+0x6206 (0xea75cc, 6 B)
; [nakarest] the table itself: ResName slot 0x363 (table 0xea75cc, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6200, 0x6
; [nakarest] naka_disk_menu_file_io+0x6206  +0x6206..+0x620c (0xea75d2, 6 B)
; [nakarest] the table itself: ResName slot 0x364 (table 0xea75d2, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6206, 0x6
; [nakarest] naka_disk_menu_file_io+0x620c  +0x620c..+0x621e (0xea75d8, 18 B)
; [nakarest] the table itself: ResName slot 0x365 (table 0xea75d8, 3 entries, InitializeCheap),
; [nakarest] 3 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x620C, 0x12
; [nakarest] naka_disk_menu_file_io+0x621e  +0x621e..+0x6230 (0xea75ea, 18 B)
; [nakarest] name strings, entries 0-2 of ResName slot 0x365 (table 0xea75d8, 3 entries,
; [nakarest] InitializeCheap) (names for Viewable slot 0x65): "", "", "DiskSaveMenu".
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x621E, 0x12
; [nakarest] naka_disk_menu_file_io+0x6230  +0x6230..+0x6236 (0xea75fc, 6 B)
; [nakarest] the table itself: ResName slot 0x366 (table 0xea75fc, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6230, 0x6
; [nakarest] naka_disk_menu_file_io+0x6236  +0x6236..+0x6358 (0xea7602, 290 B)
; [nakarest] the table itself: ResName slot 0x367 (table 0xea7602, 71 entries, InitializeCheap),
; [nakarest] 71 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6236, 0x122
; [nakarest] naka_disk_menu_file_io+0x6358  +0x6358..+0x6418 (0xea7724, 192 B)
; [nakarest] name strings, entries 0-70 of ResName slot 0x367 (table 0xea7602, 71 entries,
; [nakarest] InitializeCheap) (names for Viewable slot 0x67): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6358, 0xC0
; [nakarest] naka_disk_menu_file_io+0x6418  +0x6418..+0x641e (0xea77e4, 6 B)
; [nakarest] the table itself: ResName slot 0x36a (table 0xea77e4, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6418, 0x6
; [nakarest] naka_disk_menu_file_io+0x641e  +0x641e..+0x6478 (0xea77ea, 90 B)
; [nakarest] the table itself: ResName slot 0x36b (table 0xea77ea, 21 entries, InitializeCheap),
; [nakarest] 21 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x641E, 0x5A
; [nakarest] naka_disk_menu_file_io+0x6478  +0x6478..+0x64ac (0xea7844, 52 B)
; [nakarest] name strings, entries 0-20 of ResName slot 0x36b (table 0xea77ea, 21 entries,
; [nakarest] InitializeCheap) (names for Viewable slot 0x6b): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6478, 0x34
; [nakarest] naka_disk_menu_file_io+0x64ac  +0x64ac..+0x6500 (0xea7878, 84 B)
; [nakarest] the table itself: ResName slot 0x36c (table 0xea7878, 83 entries, InitializeCheap),
; [nakarest] 83 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x64AC, 0x54
EmbeddedPtrTable_v7_naka_disk_menu_file_io_006500:
	.long 0x00EA7A8E
	.long 0x00EA7A8C
	.long 0x00EA7A8A
	.long 0x00EA7A7E
	.long 0x00EA7A7C
	.long 0x00EA7A7A
	.long 0x00EA7A78
	.long 0x00EA7A66
	.long 0x00EA7A64
	.long 0x00EA7A62
	.long 0x00EA7A60
	.long 0x00EA7A4E
	.long 0x00EA7A4C
	.long 0x00EA7A4A
	.long 0x00EA7A48
	.long 0x00EA7A46
	.long 0x00EA7A44
	.long 0x00EA7A32
	.long 0x00EA7A30
	.long 0x00EA7A2E
	.long 0x00EA7A2C
	.long 0x00EA7A2A
	.long 0x00EA7A28
	.long 0x00EA7A26
	.long 0x00EA7A24
	.long 0x00EA7A22
	.long 0x00EA7A20
	.long 0x00EA7A1E
	.long 0x00EA7A1C
	.long 0x00EA7A1A
	.long 0x00EA7A18
	.long 0x00EA7A16
	.long 0x00EA7A14
	.long 0x00EA7A12
	.long 0x00EA7A10
	.long 0x00EA7A0E
	.long 0x00EA7A0C
	.long 0x00EA7A0A
	.long 0x00EA7A08
	.long 0x00EA7A06
	.long 0x00EA79F4
	.long 0x00EA79F2
	.long 0x00EA79F0
	.long 0x00EA79EE
	.long 0x00EA79EC
	.long 0x00EA79EA
	.long 0x00EA79E8
	.long 0x00EA79E6
	.long 0x00EA79E4
	.long 0x00EA79E2
	.long 0x00EA79E0
	.long 0x00EA79DE
	.long 0x00EA79DC
	.long 0x00EA79DA
	.long 0x00EA79D8
	.long 0x00EA79D6
	.long 0x00EA79D4
	.long 0x00EA79D2
	.long 0x00EA79D0
	.long 0x00EA79CE
	.long 0x00EA79CC
	.long 0x00EA79CA
	.long 0x00EA79C8
; [nakarest] naka_disk_menu_file_io+0x65fc  +0x65fc..+0x65fe (0xea79c8, 2 B)
; [nakarest] purpose not established: layout of 2 B at 0xea79c8 not derived; readers below
; [nakarest] Readers: source references EmbeddedPtrTable_v7_naka_disk_menu_file_io_006500
; [nakarest] (ui_widgets/disk_menu_file_io_screens.s: `.long 0x00ea79c8`); 1 data word in
; [nakarest] EmbeddedPtrTable_v7_naka_disk_menu_file_io_006500 (at 0xea79c4).
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x65FC, 0x2
; [nakarest] naka_disk_menu_file_io+0x65fe  +0x65fe..+0x66fe (0xea79ca, 256 B)
; [nakarest] name strings, entries 0-82 of ResName slot 0x36c (table 0xea7878, 83 entries,
; [nakarest] InitializeCheap) (names for Viewable slot 0x6c): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x65FE, 0x100
; [nakarest] naka_disk_menu_file_io+0x66fe  +0x66fe..+0x6704 (0xea7aca, 6 B)
; [nakarest] the table itself: ResName slot 0x36d (table 0xea7aca, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x66FE, 0x6
; [nakarest] naka_disk_menu_file_io+0x6704  +0x6704..+0x670a (0xea7ad0, 6 B)
; [nakarest] the table itself: ResName slot 0x36e (table 0xea7ad0, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6704, 0x6
; [nakarest] naka_disk_menu_file_io+0x670a  +0x670a..+0x6764 (0xea7ad6, 90 B)
; [nakarest] the table itself: ResName slot 0x377 (table 0xea7ad6, 21 entries, InitializeCheap),
; [nakarest] 21 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x670A, 0x5A
; [nakarest] naka_disk_menu_file_io+0x6764  +0x6764..+0x67c0 (0xea7b30, 92 B)
; [nakarest] name strings, entries 0-20 of ResName slot 0x377 (table 0xea7ad6, 21 entries,
; [nakarest] InitializeCheap) (names for Viewable slot 0x77): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6764, 0x5C
; [nakarest] naka_disk_menu_file_io+0x67c0  +0x67c0..+0x67c6 (0xea7b8c, 6 B)
; [nakarest] the table itself: ResName slot 0x379 (table 0xea7b8c, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x67C0, 0x6
; [nakarest] naka_disk_menu_file_io+0x67c6  +0x67c6..+0x6944 (0xea7b92, 382 B)
; [nakarest] the table itself: ResName slot 0x37b (table 0xea7b92, 94 entries, InitializeCheap),
; [nakarest] 94 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x67C6, 0x17E
; [nakarest] naka_disk_menu_file_io+0x6944  +0x6944..+0x6a34 (0xea7d10, 240 B)
; [nakarest] name strings, entries 43-93 of ResName slot 0x37b (table 0xea7b92, 94 entries,
; [nakarest] InitializeCheap) (names for Viewable slot 0x7b): "", "DiskSaveSureScr", "",
; [nakarest] "DiskDeleteSureScr", "", "", ....
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6944, 0xF0
; [nakarest] NakaInst_WaitWinCtlSmf  +0x6a34..+0x6acc (0xea7e00, 152 B)
; [nakarest] name strings, entries 0-42 of ResName slot 0x37b (table 0xea7b92, 94 entries,
; [nakarest] InitializeCheap) (names for Viewable slot 0x7b): "WaitWinCtlSmf", "", "", "", "",
; [nakarest] "", ....
NakaInst_WaitWinCtlSmf:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6A34, 0x98
; [nakarest] naka_disk_menu_file_io+0x6acc  +0x6acc..+0x6ad2 (0xea7e98, 6 B)
; [nakarest] the table itself: ResName slot 0x37c (table 0xea7e98, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6ACC, 0x6
; [nakarest] naka_disk_menu_file_io+0x6ad2  +0x6ad2..+0x6ad8 (0xea7e9e, 6 B)
; [nakarest] the table itself: ResName slot 0x37d (table 0xea7e9e, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6AD2, 0x6
; [nakarest] naka_disk_menu_file_io+0x6ad8  +0x6ad8..+0x6afe (0xea7ea4, 38 B)
; [nakarest] the table itself: ResName slot 0x37e (table 0xea7ea4, 8 entries, InitializeCheap),
; [nakarest] 8 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6AD8, 0x26
; [nakarest] naka_disk_menu_file_io+0x6afe  +0x6afe..+0x6b16 (0xea7eca, 24 B)
; [nakarest] name strings, entries 0-7 of ResName slot 0x37e (table 0xea7ea4, 8 entries,
; [nakarest] InitializeCheap) (names for Viewable slot 0x7e): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6AFE, 0x18
; [nakarest] naka_disk_menu_file_io+0x6b16  +0x6b16..+0x6c02 (0xea7ee2, 236 B)
; [nakarest] the table itself: ResName slot 0x3bc (table 0xea7ee2, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6B16, 0x6
InitializeCheap_Str_MD_DISK:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6B1C, 0x8	; "MD_DISK"
InitializeCheap_Str_TT_DKMENU:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6B24, 0xA	; "TT_DKMENU"
InitializeCheap_Str_TT_DKLD:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6B2E, 0x8	; "TT_DKLD"
InitializeCheap_Str_TT_CMPLDSNGL:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6B36, 0xE	; "TT_CMPLDSNGL"
InitializeCheap_Str_TT_DKWPLD:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6B44, 0xA	; "TT_DKWPLD"
InitializeCheap_Str_TT_DKLDSMF:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6B4E, 0xC	; "TT_DKLDSMF"
InitializeCheap_Str_TT_DKSVMENU:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6B5A, 0xC	; "TT_DKSVMENU"
InitializeCheap_Str_TT_DKSVNAME:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6B66, 0xC	; "TT_DKSVNAME"
InitializeCheap_Str_TT_DKSV:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6B72, 0x8	; "TT_DKSV"
InitializeCheap_Str_TT_DKSVNAMESMF:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6B7A, 0x10	; "TT_DKSVNAMESMF"
InitializeCheap_Str_TT_DKSVSMF:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6B8A, 0xC	; "TT_DKSVSMF"
InitializeCheap_Str_TT_DKDPSMF:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6B96, 0xC	; "TT_DKDPSMF"
InitializeCheap_Str_TT_DKDPDOC:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6BA2, 0xC	; "TT_DKDPDOC"
InitializeCheap_Str_TT_DKDPPD:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6BAE, 0xA	; "TT_DKDPPD"
InitializeCheap_Str_TT_DKMDLY:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6BB8, 0xA	; "TT_DKMDLY"
InitializeCheap_Str_TT_SQMDLY:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6BC2, 0xA	; "TT_SQMDLY"
InitializeCheap_Str_TT_DKUT:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6BCC, 0x8	; "TT_DKUT"
InitializeCheap_Str_TT_DKUTSMF:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6BD4, 0xC	; "TT_DKUTSMF"
InitializeCheap_Str_TT_DKUTFRMT:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6BE0, 0xC	; "TT_DKUTFRMT"
InitializeCheap_Str_TT_DKSETUP:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6BEC, 0xC	; "TT_DKSETUP"
InitializeCheap_Str_TT_CMPLD:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6BF8, 0xA	; "TT_CMPLD"
; [nakarest] naka_disk_menu_file_io+0x6c02  +0x6c02..+0x6cea (0xea7fce, 232 B)
; [nakarest] the table itself: MainFunction slot 0x145 (table 0xea7fce, 57 entries,
; [nakarest] InitializeCheap), 57 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6C02, 0xE8
; [nakarest] naka_disk_menu_file_io+0x6cea  +0x6cea..+0x6dd4 (0xea80b6, 234 B)
; [nakarest] the table itself: MainFunction slot 0x445 (table 0xea80b6, 57 entries,
; [nakarest] InitializeCheap), 57 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6CEA, 0xEA
; [nakarest] naka_disk_menu_file_io+0x6dd4  +0x6dd4..+0x71fc (0xea81a0, 1064 B)
; [nakarest] name strings, entries 0-56 of MainFunction slot 0x445 (table 0xea80b6, 57 entries,
; [nakarest] InitializeCheap) (names for MainFunction slot 0x145): "FmmPasswordFunc",
; [nakarest] "FmmWallpaperLoadFunc", "FmmCmpSingleLoadFunc", "CmpSingleLoadDstFunc",
; [nakarest] "CmpSingleLoadSrcFunc", "CmpSingleLoadFileFunc", ....
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6DD4, 0x428
; [nakarest] naka_disk_menu_file_io+0x71fc  +0x71fc..+0x72c2 (0xea85c8, 198 B)
; [nakarest] A table of 6 pointers into this piece (198 B at 0xea85c8), then text; entry 0
; [nakarest] points at "Please enter the password."; no registered NAKA table points into it;
; [nakarest] reached through source references PasswordText (file_io/medley.s: `lda xhl,
; [nakarest] (PasswordText_PtrTable:24)`).
PasswordText_PtrTable:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x71FC, 0xC6	; 6 x 32-bit pointer
; [nakarest] naka_disk_menu_file_io+0x72c2  +0x72c2..+0x7466 (0xea868e, 420 B)
; [nakarest] A table of 6 pointers into this piece (420 B at 0xea868e), then text; entry 0
; [nakarest] points at "The data is already copy protected. Please enter"; no registered NAKA
; [nakarest] table points into it; reached through source references CheckPwd_Type0
; [nakarest] (file_io/medley.s: `ld xhl, CheckPwd_Type0_PtrTable`).
CheckPwd_Type0_PtrTable:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x72C2, 0x1A4	; 6 x 32-bit pointer
; [nakarest] naka_disk_menu_file_io+0x7466  +0x7466..+0x7640 (0xea8832, 474 B)
; [nakarest] A table of 6 pointers into this piece (474 B at 0xea8832), then text; entry 0
; [nakarest] points at "The songs in the Sequencer are copy protected. P"; no registered NAKA
; [nakarest] table points into it; reached through source references CheckPasswordText
; [nakarest] (file_io/medley.s: `ld xhl, CheckPasswordText_PtrTable`).
CheckPasswordText_PtrTable:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x7466, 0x1DA	; 6 x 32-bit pointer
; [nakarest] naka_disk_menu_file_io+0x7640  +0x7640..+0x7824 (0xea8a0c, 484 B)
; [nakarest] A table of 6 pointers into this piece (484 B at 0xea8a0c), then text; entry 0
; [nakarest] points at "The patterns in the Composer are copy protected."; no registered NAKA
; [nakarest] table points into it; reached through source references CheckPwd_Type2
; [nakarest] (file_io/medley.s: `ld xhl, CheckPwd_Type2_PtrTable`).
CheckPwd_Type2_PtrTable:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x7640, 0x1E4	; 6 x 32-bit pointer
; [nakarest] naka_disk_menu_file_io+0x7824  +0x7824..+0x7832 (0xea8bf0, 14 B)
; [nakarest] Text (14 B at 0xea8bf0), first string "CcEv"; no registered NAKA table points into
; [nakarest] it; reached through source references WakeUp_HandleDirect (file_io/medley.s: `ld
; [nakarest] xde, WakeUp_HandleDirect_Str_CcEv`).
WakeUp_HandleDirect_Str_CcEv:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x7824, 0x6	; "CcEv"
PasswordOk_Str_Query_Query:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x782A, 0x4	; "??"
CheckPasswordOk_Str_Query_Query:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x782E, 0x4	; "??"
; [nakarest] naka_disk_menu_file_io+0x7832  +0x7832..+0x7890 (0xea8bfe, 94 B)
; [nakarest] purpose not established: layout of 94 B at 0xea8bfe not derived; readers below
; [nakarest] Readers: source references DiskAttention (file_io/medley.s: `lda xhl,
; [nakarest] (DiskAttention_PtrTable:24)`).
DiskAttention_PtrTable:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x7832, 0x5E	; 6 x 32-bit pointer
; [nakarest] naka_disk_menu_file_io+0x7890  +0x7890..+0x78e0 (0xea8c5c, 80 B)
; [nakarest] purpose not established: layout of 80 B at 0xea8c5c not derived; readers below
; [nakarest] Readers: source references DiskSure (file_io/medley.s: `lda xhl,
; [nakarest] (DiskSure_PtrTable:24)`).
DiskSure_PtrTable:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x7890, 0x50	; 6 x 32-bit pointer

; External label offsets within the binary blob above.
