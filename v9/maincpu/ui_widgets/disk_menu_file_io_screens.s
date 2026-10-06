
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
NakaInst_IvWaitWinCtlProc:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x0, 0x12
; [nakarest] NakaInst_IvIndexSwDelayProc  +0x12..+0x26 (0xea13de, 20 B)
; [nakarest] name string, entry 11 of Function slot 0x405 (table 0xea1392, 13 entries,
; [nakarest] InitializeCheap) (names for Function slot 0x105): "IvIndexSwDelayProc".
NakaInst_IvIndexSwDelayProc:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x12, 0x14
; [nakarest] NakaInst_AcRotStrBoxProc  +0x26..+0x36 (0xea13f2, 16 B)
; [nakarest] name string, entry 10 of Function slot 0x405 (table 0xea1392, 13 entries,
; [nakarest] InitializeCheap) (names for Function slot 0x105): "AcRotStrBoxProc".
NakaInst_AcRotStrBoxProc:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x26, 0x10
; [nakarest] NakaInst_IvIndexSwCtrlProc  +0x36..+0x48 (0xea1402, 18 B)
; [nakarest] name string, entry 9 of Function slot 0x405 (table 0xea1392, 13 entries,
; [nakarest] InitializeCheap) (names for Function slot 0x105): "IvIndexSwCtrlProc".
NakaInst_IvIndexSwCtrlProc:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x36, 0x12
; [nakarest] NakaInst_ArrowProc  +0x48..+0x52 (0xea1414, 10 B)
; [nakarest] name string, entry 8 of Function slot 0x405 (table 0xea1392, 13 entries,
; [nakarest] InitializeCheap) (names for Function slot 0x105): "ArrowProc".
NakaInst_ArrowProc:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x48, 0xA
; [nakarest] NakaInst_VwScreenTitleProc  +0x52..+0x64 (0xea141e, 18 B)
; [nakarest] name string, entry 7 of Function slot 0x405 (table 0xea1392, 13 entries,
; [nakarest] InitializeCheap) (names for Function slot 0x105): "VwScreenTitleProc".
NakaInst_VwScreenTitleProc:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x52, 0x12
; [nakarest] NakaInst_IvOneShotTimerProc  +0x64..+0x78 (0xea1430, 20 B)
; [nakarest] name string, entry 6 of Function slot 0x405 (table 0xea1392, 13 entries,
; [nakarest] InitializeCheap) (names for Function slot 0x105): "IvOneShotTimerProc".
NakaInst_IvOneShotTimerProc:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x64, 0x14
; [nakarest] NakaInst_AcMonoIndexToggleProc  +0x78..+0x8e (0xea1444, 22 B)
; [nakarest] name string, entry 5 of Function slot 0x405 (table 0xea1392, 13 entries,
; [nakarest] InitializeCheap) (names for Function slot 0x105): "AcMonoIndexToggleProc".
NakaInst_AcMonoIndexToggleProc:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x78, 0x16
; [nakarest] NakaInst_AcFileSfxBoxProc  +0x8e..+0xa0 (0xea145a, 18 B)
; [nakarest] name string, entry 4 of Function slot 0x405 (table 0xea1392, 13 entries,
; [nakarest] InitializeCheap) (names for Function slot 0x105): "AcFileSfxBoxProc".
NakaInst_AcFileSfxBoxProc:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x8E, 0x12
; [nakarest] NakaInst_AcParaStrBoxProc  +0xa0..+0xb2 (0xea146c, 18 B)
; [nakarest] name string, entry 3 of Function slot 0x405 (table 0xea1392, 13 entries,
; [nakarest] InitializeCheap) (names for Function slot 0x105): "AcParaStrBoxProc".
NakaInst_AcParaStrBoxProc:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xA0, 0x12
; [nakarest] NakaInst_AcTtlJgBoxProc  +0xb2..+0xc2 (0xea147e, 16 B)
; [nakarest] name string, entry 2 of Function slot 0x405 (table 0xea1392, 13 entries,
; [nakarest] InitializeCheap) (names for Function slot 0x105): "AcTtlJgBoxProc".
NakaInst_AcTtlJgBoxProc:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xB2, 0x10
; [nakarest] NakaInst_PsWindowToggleProc  +0xc2..+0xd6 (0xea148e, 20 B)
; [nakarest] name string, entry 1 of Function slot 0x405 (table 0xea1392, 13 entries,
; [nakarest] InitializeCheap) (names for Function slot 0x105): "PsWindowToggleProc".
NakaInst_PsWindowToggleProc:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xC2, 0x14
; [nakarest] NakaInst_PsFileNameBoxProc  +0xd6..+0xe8 (0xea14a2, 18 B)
; [nakarest] name string, entry 0 of Function slot 0x405 (table 0xea1392, 13 entries,
; [nakarest] InitializeCheap) (names for Function slot 0x105): "PsFileNameBoxProc".
NakaInst_PsFileNameBoxProc:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xD6, 0x12
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
NakaWidget_DiskMenu:				.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xE8, 0x34
NakaWidget_DiskMenu_1_AcTitleMenu:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x11C, 0x58
NakaWidget_DiskMenu_3_AcTitleMenu:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x174, 0x42
NakaWidget_DiskMenu_4_AcTitleMenu:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1B6, 0x3C
NakaWidget_DiskMenu_5_AcTtlJgBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1F2, 0x42
NakaWidget_DiskMenu_6_AcTtlJgBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x234, 0x3C
NakaWidget_DiskMenu_7_IvExitMode:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x270, 0x1A
NakaWidget_DiskMenu_8_AcTtlJgBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x28A, 0x42
NakaWidget_DiskMenu_9_AcTtlJgBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2CC, 0x42
NakaWidget_IntSongMedley:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x30E, 0x40
NakaWidget_DiskMenu_11_AcIndexWideES:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x34E, 0x2A
NakaWidget_DiskMenu_12_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x378, 0x28
NakaWidget_DiskMenu_13_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3A0, 0x28
NakaWidget_DiskMenu_14_PsFileNameBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3C8, 0x3A
NakaWidget_DiskMenu_15_PsFileNameBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x402, 0x3A
NakaWidget_DiskMenu_16_Line:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x43C, 0x1A
NakaWidget_DiskMenu_17_AcMonoIndexToggle:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x456, 0x32
NakaWidget_DiskMenu_18_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x488, 0x28
NakaWidget_DiskMenu_19_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4B0, 0x26
NakaWidget_DiskMenu_20_IvOneShotTimer:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4D6, 0x1A
NakaWidget_DiskMenu_21_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4F0, 0x24
NakaWidget_DiskMenu_22_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x514, 0x24
NakaWidget_DiskMenu_23_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x538, 0x26
NakaWidget_DiskSaveName:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x55E, 0x3C
NakaWidget_DiskMenu_25_AcFuncEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x59A, 0x2C
NakaWidget_DiskMenu_26_IvNaming:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5C6, 0x1A
NakaWidget_ComposerLoad:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5E0, 0x38
NakaWidget_DiskMenu_28_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x618, 0x28
NakaWidget_DiskMenu_29_AcIndexWideES:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x640, 0x2A
NakaWidget_DiskMenu_30_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x66A, 0x28
NakaWidget_DiskMenu_31_PsFileNameBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x692, 0x3A
NakaWidget_DiskMenu_32_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6CC, 0x2C
NakaWidget_DiskMenu_33_AcParaStrBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6F8, 0x2C
NakaWidget_DiskMenu_34_AcParaStrBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x724, 0x2C
NakaWidget_DiskMenu_35_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x750, 0x28
NakaWidget_DiskMenu_36_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x778, 0x26
NakaWidget_DiskMenu_37_IvExitMode:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x79E, 0x1A
NakaWidget_DiskWaitWin:				.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x7B8, 0x24
NakaWidget_DiskMenu_39_AcRotStrBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x7DC, 0x30
NakaWidget_DiskSaveNameSMF:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x80C, 0x3C
NakaWidget_DiskMenu_41_AcFuncEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x848, 0x2C
NakaWidget_DiskMenu_42_IvNaming:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x874, 0x1A
NakaWidget_WallpaperLoad:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x88E, 0x3A
NakaWidget_DiskMenu_44_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x8C8, 0x28
NakaWidget_DiskMenu_45_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x8F0, 0x26
NakaWidget_DiskMenu_46_AcIndexWideES:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x916, 0x2A
NakaWidget_DiskMenu_47_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x940, 0x28
NakaWidget_DiskMenu_48_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x968, 0x26
NakaWidget_DiskMenu_49_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x98E, 0x20
Str_DISKNAME:					.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x9AE, 0xC
NakaWidget_DiskMenu_50_AcParaStrBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x9BA, 0x2C
NakaWidget_DiskMenu_51_AcParaStrBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x9E6, 0x2C
NakaWidget_DiskMenu_52_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xA12, 0x28
NakaWidget_DiskMenu_53_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xA3A, 0x26
NakaWidget_DiskMenu_54_PsFileNameBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xA60, 0x3A
NakaWidget_DiskSaveSureWin:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xA9A, 0x24
NakaWidget_DiskMenu_56_VwBox:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xABE, 0x1C
NakaWidget_DiskMenu_57_AcLanguageText:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xADA, 0x2A
NakaWidget_DiskMenu_58_Line:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xB04, 0x1A
NakaWidget_DiskMenu_59_AcLanguageText:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xB1E, 0x2A
NakaWidget_DiskMenu_60_AcLanguageText:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xB48, 0x2A
NakaWidget_DiskMenu_61_AcFuncEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xB72, 0x2C
NakaWidget_DiskMenu_62_AcFuncEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xB9E, 0x2C
NakaWidget_DiskMenu_63_AcFuncEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xBCA, 0x2C
NakaWidget_PasswordWin:				.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xBF6, 0x24
NakaWidget_DiskMenu_65_IvNaming:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xC1A, 0x1A
NakaWidget_DiskMenu_66_AcFuncEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xC34, 0x2C
NakaWidget_DiskMenu_67_AcFuncEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xC60, 0x2C
NakaWidget_DiskMenu_68_AcLanguageText:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xC8C, 0x2A
NakaWidget_CheckPasswordWin:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xCB6, 0x24
NakaWidget_DiskMenu_70_IvNaming:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xCDA, 0x1A
NakaWidget_DiskMenu_71_AcFuncEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xCF4, 0x2C
NakaWidget_DiskMenu_72_AcFuncEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xD20, 0x2C
NakaWidget_DiskMenu_73_AcLanguageText:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xD4C, 0x2A
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
NakaWidget_DiskLoad:				.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xD76, 0x2C
NakaWidget_DiskLoadPage:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xDA2, 0x24
NakaWidget_DiskLoad_2_IvPageControl:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xDC6, 0x1C
NakaWidget_DiskLoad_3_IvPageControl:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xDE2, 0x1C
NakaWidget_DiskLoad_4_IvPageControl:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xDFE, 0x1C
NakaWidget_DiskLoad_5_IvExit:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xE1A, 0x16
NakaWidget_DiskLoad_6_IvMainEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xE30, 0x1A
NakaWidget_DiskLoadP1:				.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xE4A, 0x24
NakaWidget_DiskLoad_8_PsFileNameBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xE6E, 0x3A
NakaWidget_DiskLoad_9_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xEA8, 0x28
NakaWidget_DiskLoad_10_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xED0, 0x26
NakaWidget_DiskLoad_11_AcFileSfxBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xEF6, 0x22
NakaWidget_DiskLoad_12_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xF18, 0x2C
NakaWidget_DiskLoad_13_AcTitleMenu:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xF44, 0x3A
NakaWidget_DiskLoad_14_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xF7E, 0x28
NakaWidget_DiskLoad_15_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xFA6, 0x28
NakaWidget_DiskLoad_16_AcIndexWideES:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xFCE, 0x2A
NakaWidget_DiskLoad_17_AcParaStrBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xFF8, 0x2C
NakaWidget_DiskLoad_18_AcParaStrBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1024, 0x2C
NakaWidget_DiskLoad_19_VwScreenTitle:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1050, 0x26
Str_LOAD:					.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1076, 0x6
NakaWidget_DiskLoadP2:				.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x107C, 0x24
NakaWidget_DiskLoad_21_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x10A0, 0x28
NakaWidget_DiskLoad_22_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x10C8, 0x28
NakaWidget_DiskLoad_23_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x10F0, 0x28
NakaWidget_DiskLoad_24_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1118, 0x28
NakaWidget_DiskLoad_25_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1140, 0x28
NakaWidget_DiskLoad_26_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1168, 0x28
NakaWidget_DiskLoad_27_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1190, 0x28
NakaWidget_DiskLoad_28_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x11B8, 0x28
NakaWidget_DiskLoad_29_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x11E0, 0x24
NakaWidget_DiskLoad_30_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1204, 0x26
NakaWidget_DiskLoad_31_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x122A, 0x24
NakaWidget_DiskLoad_32_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x124E, 0x20
Str_COMP:					.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x126E, 0x6
NakaWidget_DiskLoad_33_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1274, 0x26
NakaWidget_DiskLoad_34_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x129A, 0x24
NakaWidget_DiskLoad_35_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x12BE, 0x20
Str_CUSTOM:					.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x12DE, 0x8
NakaWidget_DiskLoad_36_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x12E6, 0x20
Str_MIDI:					.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1306, 0x6
NakaWidget_DiskLoad_37_AcParaStrBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x130C, 0x2C
NakaWidget_DiskLoad_38_VwBox:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1338, 0x1C
NakaWidget_DiskLoad_39_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1354, 0x2E
NakaWidget_DiskLoad_40_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1382, 0x34
NakaWidget_DiskLoad_41_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x13B6, 0x20
Str_RHYTHM_CUSTOM:				.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x13D6, 0xE
NakaWidget_DiskLoad_42_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x13E4, 0x24
NakaWidget_DiskLoad_43_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1408, 0x2E
NakaWidget_DiskLoad_44_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1436, 0x20
Str_COMPOSER:					.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1456, 0xA
NakaWidget_DiskLoad_45_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1460, 0x2A
NakaWidget_DiskLoad_46_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x148A, 0x2E
NakaWidget_DiskLoad_47_PsFileNameBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x14B8, 0x3A
NakaWidget_DiskLoad_48_Line:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x14F2, 0x1A
NakaWidget_DiskLoad_49_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x150C, 0x28
NakaWidget_DiskLoad_50_VwScreenTitle:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1534, 0x32
NakaWidget_DiskLoad_51_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1566, 0x20
Str_LOAD_2952:					.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1586, 0x6
NakaWidget_DiskLoadP3:				.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x158C, 0x24
NakaWidget_DiskLoad_53_VwScreenTitle:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x15B0, 0x26
Str_SINGLE_LOAD:				.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x15D6, 0xC
NakaWidget_SingleLoadSwCtl:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x15E2, 0x20
NakaWidget_DiskLoad_55_IvIndexSwDelay:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1602, 0x1E
NakaWidget_DiskLoad_56_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1620, 0x28
NakaWidget_DiskLoad_57_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1648, 0x26
NakaWidget_DiskLoad_58_Arrow:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x166E, 0x20
NakaWidget_DiskLoad_59_AcIndexWideES:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x168E, 0x2A
NakaWidget_DiskLoad_60_AcIndexWideES:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x16B8, 0x2A
NakaWidget_DiskLoad_61_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x16E2, 0x28
NakaWidget_DiskLoad_62_PsFileNameBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x170A, 0x3A
NakaWidget_DiskLoad_63_AcIndexWideES:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1744, 0x2A
NakaWidget_DiskLoad_64_AcIndexWideES:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x176E, 0x2A
NakaWidget_DiskLoad_65_AcParaStrBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1798, 0x2C
NakaWidget_DiskLoad_66_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x17C4, 0x24
NakaWidget_DiskLoad_67_PsFileNameBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x17E8, 0x3A
NakaWidget_DiskLoad_68_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1822, 0x26
NakaWidget_DiskLoad_69_PsFileNameBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1848, 0x3A
NakaWidget_DiskLoad_70_PsFileNameBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1882, 0x3A
NakaWidget_DiskLoad_71_PsFileNameBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x18BC, 0x3A
NakaWidget_DiskLoad_72_PsFileNameBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x18F6, 0x3A
NakaWidget_DiskLoad_73_PsFileNameBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1930, 0x3A
NakaStr_Single:					.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x196A, 0x8
NakaStr_Bank:					.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1972, 0x6
NakaWidget_DiskLoadSMF:				.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1978, 0x34
NakaWidget_DiskLoad_76_AcTitleMenu:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x19AC, 0x3C
NakaWidget_DiskLoad_77_AcIndexWideES:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x19E8, 0x2A
NakaWidget_DiskLoad_78_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1A12, 0x28
NakaWidget_DiskLoad_79_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1A3A, 0x20
Str_PREV:					.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1A5A, 0x6
NakaWidget_DiskLoad_80_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1A60, 0x28
NakaWidget_DiskLoad_81_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1A88, 0x26
NakaWidget_DiskLoad_82_PsFileNameBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1AAE, 0x3A
NakaWidget_DiskLoad_83_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1AE8, 0x26
NakaWidget_DiskLoad_84_PsWindowToggle:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1B0E, 0x34
Str_DISK:					.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1B42, 0xC
NakaWidget_DiskLoad_85_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1B4E, 0x20
Str_LOAD_AS:					.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1B6E, 0x8
NakaWidget_DiskLoad_86_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1B76, 0x28
NakaWidget_DiskLoad_87_PsFileNameBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1B9E, 0x3A
NakaWidget_DiskLoad_88_PsFileNameBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1BD8, 0x3A
NakaWidget_DiskLoad_89_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1C12, 0x28
NakaWidget_DiskLoad_90_PsFileNameBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1C3A, 0x3A
NakaWidget_DiskLoad_91_IvMainEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1C74, 0x1A
NakaWidget_DiskLoad_92_IvExit:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1C8E, 0x16
NakaWidget_DiskLoad_93_IvIndexSwDelay:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1CA4, 0x1E
NakaWidget_DiskLoad_94_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1CC2, 0x28
NakaWidget_SongNameSmfLdWin:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1CEA, 0x24
NakaWidget_DiskLoad_96_AcParaStrBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1D0E, 0x2C
NakaWidget_DiskLoad_97_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1D3A, 0x28
NakaWidget_DiskLoad_98_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1D62, 0x26
NakaWidget_DiskInfoSmfLdWin:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1D88, 0x24
NakaWidget_DiskLoad_100_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1DAC, 0x2C
NakaWidget_DiskLoad_101_AcParaStrBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1DD8, 0x2C
NakaWidget_DiskLoad_102_AcParaStrBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1E04, 0x2C
NakaWidget_DiskLoad_103_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1E30, 0x28
NakaWidget_DiskLoad_104_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1E58, 0x26
NakaWidget_CmpSingleLoad:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1E7E, 0x40
NakaWidget_DiskLoad_106_AcIndexWideES:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1EBE, 0x2A
NakaWidget_DiskLoad_107_AcIndexWideES:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1EE8, 0x2A
NakaWidget_DiskLoad_108_AcIndexWideES:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1F12, 0x2A
NakaWidget_DiskLoad_109_AcIndexWideES:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1F3C, 0x2A
NakaWidget_DiskLoad_110_PsFileNameBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1F66, 0x3A
NakaWidget_DiskLoad_111_PsFileNameBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1FA0, 0x3A
NakaWidget_DiskLoad_112_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x1FDA, 0x28
NakaWidget_DiskLoad_113_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2002, 0x26
NakaWidget_DiskLoad_114_Arrow:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2028, 0x20
NakaWidget_DiskLoad_115_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2048, 0x24
NakaWidget_DiskLoad_116_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x206C, 0x26
NakaWidget_DiskLoad_117_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2092, 0x28
NakaWidget_DiskLoad_118_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x20BA, 0x28
NakaWidget_DiskLoad_119_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x20E2, 0x26
NakaWidget_DiskLoad_120_PsFileNameBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2108, 0x3A
NakaWidget_DiskLoad_121_AcMonoIndexToggle:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2142, 0x38
NakaWidget_DiskLoad_122_PsFileNameBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x217A, 0x3A
NakaWidget_DiskLoad_123_PsFileNameBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x21B4, 0x3A
NakaWidget_DiskLoad_124_PsFileNameBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x21EE, 0x3A
NakaWidget_DiskLoad_125_PsFileNameBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2228, 0x3A
NakaWidget_CmpSingleLoadSwCtl:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2262, 0x20
NakaWidget_DiskLoad_127_IvIndexSwDelay:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2282, 0x1E
; [nakarest] naka_disk_menu_file_io+0x22a0  +0x22a0..+0x235a (0xea366c, 186 B)
; [nakarest] widget records, elements 0-2 of Viewable slot 0x65 (table 0xea6af2, 3 entries,
; [nakarest] InitializeCheap) ("DiskSaveMenu"): TtlScreen (42 B), AcTtlJgBox (54 B) x2. 3 texts
; [nakarest] the records point at (Viewable slot 0x65 (table 0xea6af2, 3 entries,
; [nakarest] InitializeCheap)): "SAVE" (TtlScreen.title of element 0); "TECHNICS FORMAT"
; [nakarest] (AcTtlJgBox.str of element 1); "SMF FORMAT 0" (AcTtlJgBox.str of element 2).
NakaWidget_DiskSaveMenu:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x22A0, 0x30
NakaWidget_DiskSaveMenu_1_AcTtlJgBox:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x22D0, 0x46
NakaWidget_DiskSaveMenu_2_AcTtlJgBox:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2316, 0x44
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
NakaWidget_DiskSave:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x235A, 0x2C
NakaWidget_DiskSavePage:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2386, 0x24
NakaWidget_DiskSave_2_IvPageControl:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x23AA, 0x1C
NakaWidget_DiskSave_3_IvPageControl:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x23C6, 0x1C
NakaWidget_DiskSave_4_IvPageControl:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x23E2, 0x1C
NakaWidget_DiskSave_5_IvExit:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x23FE, 0x16
NakaWidget_DiskSave_6_IvMainEditSw:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2414, 0x1A
NakaWidget_DiskSaveP1:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x242E, 0x24
NakaWidget_DiskSave_8_AcIndexWideES:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2452, 0x2A
NakaWidget_DiskSave_9_AcIndexEditSw:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x247C, 0x28
NakaWidget_DiskSave_10_AcIndexEditSw:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x24A4, 0x28
NakaWidget_DiskSave_11_AcParaStrBox:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x24CC, 0x2C
NakaWidget_DiskSave_12_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x24F8, 0x2A
NakaWidget_DiskSave_13_AcParaStrBox:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2522, 0x2C
NakaWidget_DiskSave_14_AcTitleMenu:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x254E, 0x3C
NakaWidget_DiskSave_15_PsFileNameBox:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x258A, 0x3A
NakaWidget_DiskSave_16_AcIndexEditSw:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x25C4, 0x28
NakaWidget_DiskSave_17_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x25EC, 0x26
NakaWidget_DiskSave_18_AcFileSfxBox:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2612, 0x22
NakaWidget_DiskSave_19_IvCatchEvent:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2634, 0x1A
NakaWidget_DiskSave_20_VwScreenTitle:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x264E, 0x2C
NakaWidget_DiskSaveP2:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x267A, 0x24
NakaWidget_DiskSave_22_VwBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x269E, 0x1C
NakaWidget_DiskSave_23_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x26BA, 0x2E
NakaWidget_DiskSave_24_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x26E8, 0x34
NakaWidget_DiskSave_25_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x271C, 0x2E
NakaWidget_DiskSave_26_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x274A, 0x24
NakaWidget_DiskSave_27_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x276E, 0x20
Str_SOUND_MEMORY:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x278E, 0xE
NakaWidget_DiskSave_28_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x279C, 0x2A
NakaWidget_DiskSave_29_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x27C6, 0x20
Str_SEQUENCER:				.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x27E6, 0xA
NakaWidget_DiskSave_30_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x27F0, 0x2E
NakaWidget_DiskSave_31_PsFileNameBox:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x281E, 0x3A
NakaWidget_DiskSave_32_Line:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2858, 0x1A
NakaWidget_DiskSave_33_AcIndexEditSw:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2872, 0x28
NakaWidget_DiskSave_34_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x289A, 0x26
NakaWidget_DiskSave_35_AcParaStrBox:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x28C0, 0x2C
NakaWidget_DiskSave_36_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x28EC, 0x2A
NakaWidget_DiskSave_37_AcIndexEditSw:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2916, 0x28
NakaWidget_DiskSave_38_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x293E, 0x20
Str_PERFORM:				.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x295E, 0x8
NakaWidget_DiskSave_39_AcIndexEditSw:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2966, 0x28
NakaWidget_DiskSave_40_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x298E, 0x20
Str_BACKUP:				.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x29AE, 0x8
NakaWidget_DiskSave_41_AcIndexEditSw:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x29B6, 0x28
NakaWidget_DiskSave_42_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x29DE, 0x20
Str_PNL:				.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x29FE, 0x4
NakaWidget_DiskSave_43_IvCatchEvent:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2A02, 0x1A
NakaWidget_DiskSave_44_AcIndexEditSw:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2A1C, 0x28
NakaWidget_DiskSave_45_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2A44, 0x26
NakaWidget_DiskSave_46_AcIndexEditSw:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2A6A, 0x28
NakaWidget_DiskSave_47_AcIndexEditSw:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2A92, 0x28
NakaWidget_DiskSave_48_AcIndexEditSw:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2ABA, 0x28
NakaWidget_DiskSave_49_AcIndexEditSw:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2AE2, 0x28
NakaWidget_DiskSave_50_AcIndexEditSw:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2B0A, 0x28
NakaWidget_DiskSave_51_AcIndexEditSw:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2B32, 0x28
NakaWidget_DiskSave_52_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2B5A, 0x24
NakaWidget_DiskSave_53_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2B7E, 0x20
Str_COMP_3F6A:				.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2B9E, 0x6
NakaWidget_DiskSave_54_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2BA4, 0x24
NakaWidget_DiskSave_55_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2BC8, 0x26
NakaWidget_DiskSave_56_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2BEE, 0x20
Str_CUSTOM_3FDA:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2C0E, 0x8
NakaWidget_DiskSave_57_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2C16, 0x20
Str_MIDI_4002:				.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2C36, 0x6
NakaWidget_DiskSave_58_VwScreenTitle:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2C3C, 0x32
NakaWidget_DiskSave_59_AcIndexEditSw:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2C6E, 0x28
NakaWidget_DiskSave_60_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2C96, 0x20
Str_ALL_OFF:				.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2CB6, 0x8
NakaWidget_DiskSaveP3:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2CBE, 0x24
NakaWidget_DiskSave_62_PsFileNameBox:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2CE2, 0x3A
NakaWidget_DiskSave_63_AcIndexWideES:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2D1C, 0x2A
NakaWidget_DiskSave_64_AcIndexEditSw:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2D46, 0x28
NakaWidget_DiskSave_65_AcParaStrBox:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2D6E, 0x2C
NakaWidget_DiskSave_66_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2D9A, 0x26
NakaWidget_DiskSave_67_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2DC0, 0x26
NakaWidget_DiskSave_68_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2DE6, 0x20
Str_SAVE:				.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2E06, 0x6
NakaWidget_DiskSave_69_VwScreenTitle:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2E0C, 0x3A
NakaWidget_DiskSave_70_IvCatchEvent:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2E46, 0x1A
; [nakarest] naka_disk_menu_file_io+0x2e60  +0x2e60..+0x322e (0xea422c, 974 B)
; [nakarest] widget records, elements 0-20 of Viewable slot 0x6b (table 0xea6c2a, 21 entries,
; [nakarest] InitializeCheap) ("DiskSmfSave"): TtlScreen (42 B), PsFileNameBox (58 B) x4,
; [nakarest] AcIndexWideES (42 B), AcIndexEditSw (40 B) x4, Label (32 B) x7, AcMonoIndexToggle
; [nakarest] (42 B) x2, AcTitleMenu (54 B), AcParaStrBox (44 B). 13 texts the records point at
; [nakarest] (Viewable slot 0x6b (table 0xea6c2a, 21 entries, InitializeCheap)): "SMF SAVE"
; [nakarest] (TtlScreen.title of element 0); "PREV" (Label.str of element 4); "NEXT" (Label.str
; [nakarest] of element 6); "OFF" (AcMonoIndexToggle.stroff of element 7); ....
NakaWidget_DiskSmfSave:				.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2E60, 0x34
NakaWidget_DiskSmfSave_1_PsFileNameBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2E94, 0x3A
NakaWidget_DiskSmfSave_2_AcIndexWideES:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2ECE, 0x2A
NakaWidget_DiskSmfSave_3_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2EF8, 0x28
NakaWidget_DiskSmfSave_4_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2F20, 0x26
NakaWidget_DiskSmfSave_5_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2F46, 0x28
NakaWidget_DiskSmfSave_6_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2F6E, 0x20
Str_NEXT:					.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2F8E, 0x6
NakaWidget_DiskSmfSave_7_AcMonoIndexToggle:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2F94, 0x32
NakaWidget_DiskSmfSave_8_AcMonoIndexToggle:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2FC6, 0x2A
Str_OFF:					.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2FF0, 0x8
NakaWidget_DiskSmfSave_9_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2FF8, 0x2E
NakaWidget_DiskSmfSave_10_AcTitleMenu:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3026, 0x3C
NakaWidget_DiskSmfSave_11_AcParaStrBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3062, 0x2C
NakaWidget_DiskSmfSave_12_AcIndexEditSw:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x308E, 0x28
NakaWidget_DiskSmfSave_13_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x30B6, 0x20
Str_SAVE_44A2:					.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x30D6, 0x6
NakaWidget_DiskSmfSave_14_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x30DC, 0x30
NakaWidget_DiskSmfSave_15_PsFileNameBox:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x310C, 0x3A
NakaWidget_DiskSmfSave_16_AcIndexEditSw:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3146, 0x28
NakaWidget_DiskSmfSave_17_PsFileNameBox:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x316E, 0x3A
NakaWidget_DiskSmfSave_18_PsFileNameBox:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x31A8, 0x3A
NakaWidget_DiskSmfSave_19_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x31E2, 0x26
NakaWidget_DiskSmfSave_20_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3208, 0x26
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
NakaWidget_DiskSmfDirectPlay:				.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x322E, 0x3A
NakaWidget_DiskSmfDirectPlay_1_PsFileNameBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3268, 0x3A
NakaWidget_DiskSmfDirectPlay_2_PsFileNameBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x32A2, 0x3A
NakaWidget_DiskSmfDirectPlay_3_AcIndexWideES:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x32DC, 0x2A
NakaWidget_DiskSmfDirectPlay_4_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3306, 0x28
NakaWidget_DiskSmfDirectPlay_5_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x332E, 0x20
Str_PREV_471A:						.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x334E, 0x6
NakaWidget_DiskSmfDirectPlay_6_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3354, 0x28
NakaWidget_DiskSmfDirectPlay_7_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x337C, 0x26
NakaWidget_DiskSmfDirectPlay_8_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x33A2, 0x26
NakaWidget_DiskSmfDirectPlay_9_PsWindowToggle:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x33C8, 0x40
NakaWidget_DiskSmfDirectPlay_10_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3408, 0x28
NakaWidget_DiskSmfDirectPlay_11_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3430, 0x28
NakaWidget_DiskSmfDirectPlay_12_AcMonoIndexToggle:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3458, 0x32
NakaWidget_DiskSmfDirectPlay_13_AcMonoIndexToggle:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x348A, 0x34
NakaWidget_DiskSmfDirectPlay_14_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x34BE, 0x28
NakaWidget_DiskSmfDirectPlay_15_Line:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x34E6, 0x1A
NakaWidget_DiskSmfDirectPlay_16_Line:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3500, 0x1A
NakaWidget_DiskSmfDirectPlay_17_Line:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x351A, 0x1A
NakaWidget_DiskSmfDirectPlay_18_Line:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3534, 0x1A
NakaWidget_DiskSmfDirectPlay_19_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x354E, 0x26
NakaWidget_DiskSmfDirectPlay_20_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3574, 0x28
NakaWidget_DiskSmfDirectPlay_21_IvOneShotTimer:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x359C, 0x1A
NakaWidget_DiskSmfDirectPlay_22_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x35B6, 0x24
NakaWidget_DiskSmfDirectPlay_23_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x35DA, 0x24
NakaWidget_SmfMidiOut:					.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x35FE, 0x32
NakaWidget_DiskSmfDirectPlay_25_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3630, 0x2A
NakaWidget_DiskSmfDirectPlay_26_IvIndexSwDelay:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x365A, 0x1E
NakaWidget_DiskSmfDirectPlay_27_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3678, 0x28
NakaWidget_SongNameDPSmfWin:				.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x36A0, 0x24
NakaWidget_DiskSmfDirectPlay_29_AcParaStrBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x36C4, 0x2C
NakaWidget_DiskSmfDirectPlay_30_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x36F0, 0x28
NakaWidget_DiskSmfDirectPlay_31_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3718, 0x26
NakaWidget_DiskInfoDPSmfWin:				.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x373E, 0x24
NakaWidget_DiskSmfDirectPlay_33_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3762, 0x2C
NakaWidget_DiskSmfDirectPlay_34_AcParaStrBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x378E, 0x2C
NakaWidget_DiskSmfDirectPlay_35_AcParaStrBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x37BA, 0x2C
NakaWidget_DiskSmfDirectPlay_36_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x37E6, 0x28
NakaWidget_DiskSmfDirectPlay_37_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x380E, 0x26
NakaWidget_DiskDocDirectPlay:				.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3834, 0x3A
NakaWidget_DiskSmfDirectPlay_39_PsFileNameBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x386E, 0x3A
NakaWidget_DiskSmfDirectPlay_40_PsFileNameBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x38A8, 0x3A
NakaWidget_DiskSmfDirectPlay_41_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x38E2, 0x28
NakaWidget_DiskSmfDirectPlay_42_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x390A, 0x26
NakaWidget_DiskSmfDirectPlay_43_AcIndexWideES:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3930, 0x2A
NakaWidget_DiskSmfDirectPlay_44_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x395A, 0x28
NakaWidget_DiskSmfDirectPlay_45_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3982, 0x26
NakaWidget_DiskSmfDirectPlay_46_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x39A8, 0x28
NakaWidget_DiskSmfDirectPlay_47_IvOneShotTimer:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x39D0, 0x1A
NakaWidget_DiskSmfDirectPlay_48_Line:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x39EA, 0x1A
NakaWidget_DiskSmfDirectPlay_49_Line:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3A04, 0x1A
NakaWidget_DiskSmfDirectPlay_50_Line:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3A1E, 0x1A
NakaWidget_DiskSmfDirectPlay_51_Line:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3A38, 0x1A
NakaWidget_DiskSmfDirectPlay_52_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3A52, 0x28
NakaWidget_DiskSmfDirectPlay_53_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3A7A, 0x28
NakaWidget_DiskSmfDirectPlay_54_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3AA2, 0x26
NakaWidget_DiskSmfDirectPlay_55_AcMonoIndexToggle:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3AC8, 0x32
NakaWidget_DiskSmfDirectPlay_56_AcParaStrBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3AFA, 0x2C
NakaWidget_DiskSmfDirectPlay_57_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3B26, 0x28
NakaWidget_DiskSmfDirectPlay_58_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3B4E, 0x26
NakaWidget_DiskSmfDirectPlay_59_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3B74, 0x24
NakaWidget_DiskSmfDirectPlay_60_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3B98, 0x24
NakaWidget_DiskPdDirectPlay:				.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3BBC, 0x42
NakaWidget_DiskSmfDirectPlay_62_PsFileNameBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3BFE, 0x3A
NakaWidget_DiskSmfDirectPlay_63_PsFileNameBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3C38, 0x3A
NakaWidget_DiskSmfDirectPlay_64_AcIndexWideES:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3C72, 0x2A
NakaWidget_DiskSmfDirectPlay_65_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3C9C, 0x28
NakaWidget_DiskSmfDirectPlay_66_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3CC4, 0x26
NakaWidget_DiskSmfDirectPlay_67_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3CEA, 0x28
NakaWidget_DiskSmfDirectPlay_68_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3D12, 0x26
NakaWidget_DiskSmfDirectPlay_69_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3D38, 0x28
NakaWidget_DiskSmfDirectPlay_70_IvOneShotTimer:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3D60, 0x1A
NakaWidget_DiskSmfDirectPlay_71_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3D7A, 0x28
NakaWidget_DiskSmfDirectPlay_72_AcMonoIndexToggle:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3DA2, 0x32
NakaWidget_DiskSmfDirectPlay_73_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3DD4, 0x26
NakaWidget_DiskSmfDirectPlay_74_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3DFA, 0x28
NakaWidget_DiskSmfDirectPlay_75_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3E22, 0x26
NakaWidget_DiskSmfDirectPlay_76_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3E48, 0x28
NakaWidget_DiskSmfDirectPlay_77_Line:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3E70, 0x1A
NakaWidget_DiskSmfDirectPlay_78_Line:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3E8A, 0x1A
NakaWidget_DiskSmfDirectPlay_79_Line:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3EA4, 0x1A
NakaWidget_DiskSmfDirectPlay_80_Line:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3EBE, 0x1A
NakaWidget_DiskSmfDirectPlay_81_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3ED8, 0x24
NakaWidget_DiskSmfDirectPlay_82_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3EFC, 0x24
; [nakarest] naka_disk_menu_file_io+0x3f20  +0x3f20..+0x42b8 (0xea52ec, 920 B)
; [nakarest] widget records, elements 0-20 of Viewable slot 0x77 (table 0xea6dda, 21 entries,
; [nakarest] InitializeCheap) ("DiskSongMedley"): TtlScreen (42 B), AcIndexEditSw (40 B) x5,
; [nakarest] AcIndexWideES (42 B), PsFileNameBox (58 B) x3, Label (32 B) x6, AcParaStrBox (44 B)
; [nakarest] x2, AcMonoIndexToggle (42 B) x2, IvShowHide (26 B). 11 texts the records point at
; [nakarest] (Viewable slot 0x77 (table 0xea6dda, 21 entries, InitializeCheap)): "SONG MEDLEY"
; [nakarest] (TtlScreen.title of element 0); "DISK NAME:" (Label.str of element 7); "START"
; [nakarest] (Label.str of element 11); "ALL" (Label.str of element 13); ....
NakaWidget_DiskSongMedley:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3F20, 0x36
NakaWidget_DiskSongMedley_1_AcIndexEditSw:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3F56, 0x28
NakaWidget_DiskSongMedley_2_AcIndexWideES:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3F7E, 0x2A
NakaWidget_DiskSongMedley_3_AcIndexEditSw:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3FA8, 0x28
NakaWidget_DiskSongMedley_4_PsFileNameBox:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3FD0, 0x3A
NakaWidget_DiskSongMedley_5_PsFileNameBox:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x400A, 0x3A
NakaWidget_DiskSongMedley_6_PsFileNameBox:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4044, 0x3A
NakaWidget_DiskSongMedley_7_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x407E, 0x2C
NakaWidget_SongMedleyDiskName:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x40AA, 0x2C
NakaWidget_SongMedleyDiskInfo:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x40D6, 0x2C
NakaWidget_DiskSongMedley_10_AcIndexEditSw:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4102, 0x28
NakaWidget_DiskSongMedley_11_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x412A, 0x26
NakaWidget_DiskSongMedley_12_AcIndexEditSw:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4150, 0x28
NakaWidget_DiskSongMedley_13_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4178, 0x24
NakaWidget_DiskSongMedley_14_AcIndexEditSw:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x419C, 0x28
NakaWidget_DiskSongMedley_15_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x41C4, 0x24
NakaWidget_DiskSongMedley_16_AcMonoIndexToggle:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x41E8, 0x32
NakaWidget_DiskSongMedley_17_AcMonoIndexToggle:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x421A, 0x38
NakaWidget_DiskSongMedley_18_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4252, 0x26
NakaWidget_DiskSongMedley_19_IvShowHide:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4278, 0x1A
NakaWidget_DiskSongMedley_20_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4292, 0x26
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
NakaWidget_DiskUtility:				.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x42B8, 0x36
NakaWidget_DiskUtility_1_AcIndexWideES:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x42EE, 0x2A
NakaWidget_DiskUtility_2_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4318, 0x28
NakaWidget_DiskUtility_3_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4340, 0x28
NakaWidget_DiskUtility_4_AcTitleMenu:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4368, 0x3A
NakaWidget_DiskUtility_5_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x43A2, 0x2C
NakaWidget_DiskUtility_6_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x43CE, 0x28
NakaWidget_DiskUtility_7_AcIndexEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x43F6, 0x28
NakaWidget_DiskUtility_8_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x441E, 0x24
NakaWidget_DiskUtility_9_Label:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4442, 0x26
NakaWidget_DiskUtility_10_AcTitleMenu:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4468, 0x38
NakaWidget_DiskUtility_11_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x44A0, 0x28
NakaWidget_DiskUtility_12_AcScreenMenu:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x44C8, 0x38
NakaWidget_DiskUtility_13_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4500, 0x28
NakaWidget_DiskUtility_14_AcIndexEditSw:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4528, 0x28
NakaWidget_DiskUtility_15_AcScreenMenu:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4550, 0x3C
NakaWidget_DiskUtility_16_AcParaStrBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x458C, 0x2C
NakaWidget_DiskUtility_17_AcParaStrBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x45B8, 0x2C
NakaWidget_DiskUtility_18_PsFileNameBox:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x45E4, 0x3A
NakaWidget_WaitWinCtl:				.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x461E, 0x1A
NakaWidget_FileRename:				.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4638, 0x22
NakaWidget_DiskUtility_21_VwScreenTitle:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x465A, 0x32
NakaWidget_DiskUtility_22_IvNaming:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x468C, 0x1A
NakaWidget_DiskUtility_23_AcFuncEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x46A6, 0x2C
NakaWidget_DiskFormat:				.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x46D2, 0x3E
NakaWidget_DiskUtilitySMF:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4710, 0x3A
NakaWidget_DiskUtility_26_AcTitleMenu:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x474A, 0x3C
NakaWidget_DiskUtility_27_AcIndexEditSw:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4786, 0x28
NakaWidget_DiskUtility_28_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x47AE, 0x26
NakaWidget_DiskUtility_29_AcIndexWideES:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x47D4, 0x2A
NakaWidget_DiskUtility_30_AcIndexEditSw:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x47FE, 0x28
NakaWidget_DiskUtility_31_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4826, 0x26
NakaWidget_DiskUtility_32_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x484C, 0x26
NakaWidget_DiskUtility_33_PsFileNameBox:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4872, 0x3A
NakaWidget_DiskUtility_34_PsWindowToggle:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x48AC, 0x40
NakaWidget_DiskUtility_35_AcTitleMenu:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x48EC, 0x38
NakaWidget_DiskUtility_36_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4924, 0x28
NakaWidget_DiskUtility_37_AcIndexEditSw:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x494C, 0x28
NakaWidget_DiskUtility_38_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4974, 0x24
NakaWidget_DiskUtility_39_AcScreenMenu:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4998, 0x38
NakaWidget_DiskUtility_40_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x49D0, 0x28
NakaWidget_DiskUtility_41_IvIndexSwDelay:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x49F8, 0x1E
NakaWidget_WaitWinCtlSmf:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4A16, 0x1A
NakaWidget_DiskInfoWin:				.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4A30, 0x24
NakaWidget_DiskUtility_44_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4A54, 0x2C
NakaWidget_DiskUtility_45_AcParaStrBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4A80, 0x2C
NakaWidget_DiskUtility_46_AcParaStrBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4AAC, 0x2C
NakaWidget_SongNameWin:				.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4AD8, 0x24
NakaWidget_DiskUtility_48_AcParaStrBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4AFC, 0x2C
NakaWidget_DiskFormatNamingWin:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4B28, 0x24
NakaWidget_DiskUtility_50_IvNaming:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4B4C, 0x1A
NakaWidget_DiskUtility_51_AcFuncEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4B66, 0x2C
NakaWidget_DiskUtility_52_IvMainEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4B92, 0x1A
NakaWidget_DiskUtility_53_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4BAC, 0x2C
NakaWidget_DiskFormatSureWin:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4BD8, 0x24
NakaWidget_DiskUtility_55_VwBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4BFC, 0x1C
NakaWidget_DiskUtility_56_AcLanguageText:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4C18, 0x2A
NakaWidget_DiskUtility_57_Line:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4C42, 0x1A
NakaWidget_DiskUtility_58_AcLanguageText:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4C5C, 0x2A
NakaWidget_DiskUtility_59_AcLanguageText:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4C86, 0x2A
NakaWidget_DiskUtility_60_VwEditSwBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4CB0, 0x2E
NakaWidget_DiskUtility_61_VwEditSwBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4CDE, 0x2E
NakaWidget_DiskUtility_62_IvMainEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4D0C, 0x1A
NakaWidget_DiskFormatSelectWin:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4D26, 0x24
NakaWidget_DiskUtility_64_IvMainEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4D4A, 0x1A
NakaWidget_DiskUtility_65_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4D64, 0x46
NakaWidget_DiskUtility_66_VwMenuBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4DAA, 0x4E
NakaWidget_DiskUtility_67_VwMenuBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4DF8, 0x4E
NakaWidget_FileCopy:				.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4E46, 0x22
NakaWidget_DiskUtility_69_VwScreenTitle:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4E68, 0x30
NakaWidget_DiskUtility_70_Arrow:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4E98, 0x20
NakaWidget_DiskUtility_71_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4EB8, 0x24
NakaWidget_DiskUtility_72_AcParaStrBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4EDC, 0x2C
NakaWidget_DiskUtility_73_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4F08, 0x26
NakaWidget_DiskUtility_74_AcIndexWideES:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4F2E, 0x2A
NakaWidget_DiskUtility_75_AcIndexEditSw:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4F58, 0x28
NakaWidget_DiskUtility_76_PsFileNameBox:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4F80, 0x3A
NakaWidget_FileRenameSMF:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4FBA, 0x22
NakaWidget_DiskUtility_78_VwScreenTitle:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x4FDC, 0x32
NakaWidget_DiskUtility_79_IvNaming:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x500E, 0x1A
NakaWidget_DiskUtility_80_AcFuncEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5028, 0x2C
NakaWidget_DiskDeleteSureWin:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5054, 0x24
NakaWidget_DiskUtility_82_VwBox:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5078, 0x1C
NakaWidget_DiskUtility_83_AcLanguageText:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5094, 0x2A
NakaWidget_DiskUtility_84_Line:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x50BE, 0x1A
NakaWidget_DiskUtility_85_AcLanguageText:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x50D8, 0x2A
NakaWidget_DiskUtility_86_AcLanguageText:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5102, 0x2A
NakaWidget_DiskUtility_87_AcFuncEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x512C, 0x2C
NakaWidget_DiskUtility_88_AcFuncEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5158, 0x2C
NakaWidget_DiskUtility_89_AcFuncEditSw:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5184, 0x2C
NakaWidget_DiskDeleteSureScr:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x51B0, 0x22
NakaWidget_DiskUtility_91_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x51D2, 0x2C
NakaWidget_DiskSaveSureScr:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x51FE, 0x22
NakaWidget_DiskUtility_93_Label:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5220, 0x30
; [nakarest] naka_disk_menu_file_io+0x5250  +0x5250..+0x53ea (0xea661c, 410 B)
; [nakarest] widget records, elements 0-7 of Viewable slot 0x7e (table 0xea6fba, 8 entries,
; [nakarest] InitializeCheap) ("DiskSetup"): TtlScreen (42 B), AcIndexWideES (42 B),
; [nakarest] AcRamEditBox (58 B), AcBitEditBox (58 B), AcFuncEditSw (44 B), IvCatchEvent (26 B),
; [nakarest] AcLanguageText (42 B) x2. 3 texts the records point at (Viewable slot 0x7e (table
; [nakarest] 0xea6fba, 8 entries, InitializeCheap)): "PREFERENCES" (TtlScreen.title of element
; [nakarest] 0); "DISK INSERT OPTION :" (AcRamEditBox.caption of element 2); "FILE TYPE PRIORITY
; [nakarest] :" (AcBitEditBox.caption of element 3).
NakaWidget_DiskSetup:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5250, 0x36
NakaWidget_DiskSetup_1_AcIndexWideES:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5286, 0x2A
NakaWidget_DiskSetup_2_AcRamEditBox:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x52B0, 0x3A
Str_DISKINSERTOPTION:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x52EA, 0x16
NakaWidget_DiskSetup_3_AcBitEditBox:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5300, 0x3A
Str_FILETYPEPRIORITY:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x533A, 0x16
NakaWidget_DiskSetup_4_AcFuncEditSw:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5350, 0x2C
NakaWidget_DiskSetup_5_IvCatchEvent:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x537C, 0x1A
NakaWidget_DiskSetup_6_AcLanguageText:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5396, 0x2A
NakaWidget_DiskSetup_7_AcLanguageText:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x53C0, 0x2A
; [nakarest] naka_disk_menu_file_io+0x53ea  +0x53ea..+0x5516 (0xea67b6, 300 B)
; [nakarest] the table itself: Viewable slot 0x60 (table 0xea67b6, 74 entries, InitializeCheap),
; [nakarest] 74 entry pointers x 4 bytes.
Cheap_ViewableTable_060:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x53EA, 0x12C
; [nakarest] naka_disk_menu_file_io+0x5516  +0x5516..+0x571a (0xea68e2, 516 B)
; [nakarest] the table itself: Viewable slot 0x61 (table 0xea68e2, 128 entries,
; [nakarest] InitializeCheap), 128 entry pointers x 4 bytes.
Cheap_ViewableTable_061:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5516, 0x204
; [nakarest] naka_disk_menu_file_io+0x571a  +0x571a..+0x571e (0xea6ae6, 4 B)
; [nakarest] the table itself: Viewable slot 0x62 (table 0xea6ae6, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
Cheap_ViewableTable_062:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x571A, 0x4
; [nakarest] naka_disk_menu_file_io+0x571e  +0x571e..+0x5722 (0xea6aea, 4 B)
; [nakarest] the table itself: Viewable slot 0x63 (table 0xea6aea, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
Cheap_ViewableTable_063:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x571E, 0x4
; [nakarest] naka_disk_menu_file_io+0x5722  +0x5722..+0x5726 (0xea6aee, 4 B)
; [nakarest] the table itself: Viewable slot 0x64 (table 0xea6aee, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
Cheap_ViewableTable_064:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5722, 0x4
; [nakarest] naka_disk_menu_file_io+0x5726  +0x5726..+0x5736 (0xea6af2, 16 B)
; [nakarest] the table itself: Viewable slot 0x65 (table 0xea6af2, 3 entries, InitializeCheap),
; [nakarest] 3 entry pointers x 4 bytes.
Cheap_ViewableTable_065:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5726, 0x10
; [nakarest] naka_disk_menu_file_io+0x5736  +0x5736..+0x573a (0xea6b02, 4 B)
; [nakarest] the table itself: Viewable slot 0x66 (table 0xea6b02, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
Cheap_ViewableTable_066:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5736, 0x4
; [nakarest] naka_disk_menu_file_io+0x573a  +0x573a..+0x585a (0xea6b06, 288 B)
; [nakarest] the table itself: Viewable slot 0x67 (table 0xea6b06, 71 entries, InitializeCheap),
; [nakarest] 71 entry pointers x 4 bytes.
Cheap_ViewableTable_067:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x573A, 0x120
; [nakarest] naka_disk_menu_file_io+0x585a  +0x585a..+0x585e (0xea6c26, 4 B)
; [nakarest] the table itself: Viewable slot 0x6a (table 0xea6c26, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
Cheap_ViewableTable_06A:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x585A, 0x4
; [nakarest] naka_disk_menu_file_io+0x585e  +0x585e..+0x58b6 (0xea6c2a, 88 B)
; [nakarest] the table itself: Viewable slot 0x6b (table 0xea6c2a, 21 entries, InitializeCheap),
; [nakarest] 21 entry pointers x 4 bytes.
Cheap_ViewableTable_06B:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x585E, 0x58
; [nakarest] naka_disk_menu_file_io+0x58b6  +0x58b6..+0x5a06 (0xea6c82, 336 B)
; [nakarest] the table itself: Viewable slot 0x6c (table 0xea6c82, 83 entries, InitializeCheap),
; [nakarest] 83 entry pointers x 4 bytes.
Cheap_ViewableTable_06C:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x58B6, 0x150
; [nakarest] naka_disk_menu_file_io+0x5a06  +0x5a06..+0x5a0a (0xea6dd2, 4 B)
; [nakarest] the table itself: Viewable slot 0x6d (table 0xea6dd2, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
Cheap_ViewableTable_06D:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5A06, 0x4
; [nakarest] naka_disk_menu_file_io+0x5a0a  +0x5a0a..+0x5a0e (0xea6dd6, 4 B)
; [nakarest] the table itself: Viewable slot 0x6e (table 0xea6dd6, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
Cheap_ViewableTable_06E:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5A0A, 0x4
; [nakarest] naka_disk_menu_file_io+0x5a0e  +0x5a0e..+0x5a66 (0xea6dda, 88 B)
; [nakarest] the table itself: Viewable slot 0x77 (table 0xea6dda, 21 entries, InitializeCheap),
; [nakarest] 21 entry pointers x 4 bytes.
Cheap_ViewableTable_077:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5A0E, 0x58
; [nakarest] naka_disk_menu_file_io+0x5a66  +0x5a66..+0x5a6a (0xea6e32, 4 B)
; [nakarest] the table itself: Viewable slot 0x79 (table 0xea6e32, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
Cheap_ViewableTable_079:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5A66, 0x4
; [nakarest] naka_disk_menu_file_io+0x5a6a  +0x5a6a..+0x5be6 (0xea6e36, 380 B)
; [nakarest] the table itself: Viewable slot 0x7b (table 0xea6e36, 94 entries, InitializeCheap),
; [nakarest] 94 entry pointers x 4 bytes.
Cheap_ViewableTable_07B:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5A6A, 0x17C
; [nakarest] naka_disk_menu_file_io+0x5be6  +0x5be6..+0x5bea (0xea6fb2, 4 B)
; [nakarest] the table itself: Viewable slot 0x7c (table 0xea6fb2, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
Cheap_ViewableTable_07C:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5BE6, 0x4
; [nakarest] naka_disk_menu_file_io+0x5bea  +0x5bea..+0x5bee (0xea6fb6, 4 B)
; [nakarest] the table itself: Viewable slot 0x7d (table 0xea6fb6, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
Cheap_ViewableTable_07D:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5BEA, 0x4
; [nakarest] naka_disk_menu_file_io+0x5bee  +0x5bee..+0x5c12 (0xea6fba, 36 B)
; [nakarest] the table itself: Viewable slot 0x7e (table 0xea6fba, 8 entries, InitializeCheap),
; [nakarest] 8 entry pointers x 4 bytes.
Cheap_ViewableTable_07E:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5BEE, 0x24
; [nakarest] naka_disk_menu_file_io+0x5c12  +0x5c12..+0x5c16 (0xea6fde, 4 B)
; [nakarest] the table itself: Viewable slot 0xbc (table 0xea6fde, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
Cheap_ViewableTable_0BC:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5C12, 0x4
; [nakarest] naka_disk_menu_file_io+0x5c16  +0x5c16..+0x5d44 (0xea6fe2, 302 B)
; [nakarest] the table itself: ResName slot 0x360 (table 0xea6fe2, 74 entries, InitializeCheap),
; [nakarest] 74 entry pointers x 4 bytes.
Cheap_ResNameTable_360:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5C16, 0x12E
; [nakarest] naka_disk_menu_file_io+0x5d44  +0x5d44..+0x5e5c (0xea7110, 280 B)
; [nakarest] name strings, entries 0-73 of ResName slot 0x360 (table 0xea6fe2, 74 entries,
; [nakarest] InitializeCheap) (names for Viewable slot 0x60): "", "", "", "",
; [nakarest] "CheckPasswordWin", "", ....
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5D44, 0x118
; [nakarest] naka_disk_menu_file_io+0x5e5c  +0x5e5c..+0x5f00 (0xea7228, 164 B)
; [nakarest] the table itself: ResName slot 0x361 (table 0xea7228, 128 entries,
; [nakarest] InitializeCheap), 128 entry pointers x 4 bytes.
Cheap_ResNameTable_361:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5E5C, 0xA4
	.long NakaWidget_DiskLoad_41_Label_Name
	.long NakaWidget_DiskLoad_42_Label_Name
	.long NakaWidget_DiskLoad_43_Label_Name
	.long NakaWidget_DiskLoad_44_Label_Name
	.long NakaWidget_DiskLoad_45_Label_Name
	.long NakaWidget_DiskLoad_46_Label_Name
	.long NakaWidget_DiskLoad_47_PsFileNameBox_Name
	.long NakaWidget_DiskLoad_48_Line_Name
	.long NakaWidget_DiskLoad_49_AcIndexEditSw_Name
	.long NakaWidget_DiskLoad_50_VwScreenTitle_Name
	.long NakaWidget_DiskLoad_51_Label_Name
	.long NakaWidget_DiskLoadP3_Name
	.long NakaWidget_DiskLoad_53_VwScreenTitle_Name
	.long NakaWidget_SingleLoadSwCtl_Name
	.long NakaWidget_DiskLoad_55_IvIndexSwDelay_Name
	.long NakaWidget_DiskLoad_56_AcIndexEditSw_Name
	.long NakaWidget_DiskLoad_57_Label_Name
	.long NakaWidget_DiskLoad_58_Arrow_Name
	.long NakaWidget_DiskLoad_59_AcIndexWideES_Name
	.long NakaWidget_DiskLoad_60_AcIndexWideES_Name
	.long NakaWidget_DiskLoad_61_AcIndexEditSw_Name
	.long NakaWidget_DiskLoad_62_PsFileNameBox_Name
	.long NakaWidget_DiskLoad_63_AcIndexWideES_Name
	.long NakaWidget_DiskLoad_64_AcIndexWideES_Name
	.long NakaWidget_DiskLoad_65_AcParaStrBox_Name
	.long NakaWidget_DiskLoad_66_Label_Name
	.long NakaWidget_DiskLoad_67_PsFileNameBox_Name
	.long NakaWidget_DiskLoad_68_Label_Name
	.long NakaWidget_DiskLoad_69_PsFileNameBox_Name
	.long NakaWidget_DiskLoad_70_PsFileNameBox_Name
	.long NakaWidget_DiskLoad_71_PsFileNameBox_Name
	.long NakaWidget_DiskLoad_72_PsFileNameBox_Name
	.long NakaWidget_DiskLoad_73_PsFileNameBox_Name
	.long Cheap_ResNameTable_361_Str_SingleBankToggle
	.long NakaWidget_DiskLoadSMF_Name
	.long NakaWidget_DiskLoad_76_AcTitleMenu_Name
	.long NakaWidget_DiskLoad_77_AcIndexWideES_Name
	.long NakaWidget_DiskLoad_78_AcIndexEditSw_Name
	.long NakaWidget_DiskLoad_79_Label_Name
	.long NakaWidget_DiskLoad_80_AcIndexEditSw_Name
	.long NakaWidget_DiskLoad_81_Label_Name
	.long NakaWidget_DiskLoad_82_PsFileNameBox_Name
	.long NakaWidget_DiskLoad_83_Label_Name
	.long NakaWidget_DiskLoad_84_PsWindowToggle_Name
	.long NakaWidget_DiskLoad_85_Label_Name
	.long NakaWidget_DiskLoad_86_AcIndexEditSw_Name
	.long NakaWidget_DiskLoad_87_PsFileNameBox_Name
	.long NakaWidget_DiskLoad_88_PsFileNameBox_Name
	.long NakaWidget_DiskLoad_89_AcIndexEditSw_Name
	.long NakaWidget_DiskLoad_90_PsFileNameBox_Name
	.long NakaWidget_DiskLoad_91_IvMainEditSw_Name
	.long NakaWidget_DiskLoad_92_IvExit_Name
	.long NakaWidget_DiskLoad_93_IvIndexSwDelay_Name
	.long NakaWidget_DiskLoad_94_AcIndexEditSw_Name
	.long NakaWidget_SongNameSmfLdWin_Name
	.long NakaWidget_DiskLoad_96_AcParaStrBox_Name
	.long NakaWidget_DiskLoad_97_AcIndexEditSw_Name
	.long NakaWidget_DiskLoad_98_Label_Name
	.long NakaWidget_DiskInfoSmfLdWin_Name
	.long NakaWidget_DiskLoad_100_Label_Name
	.long NakaWidget_DiskLoad_101_AcParaStrBox_Name
	.long NakaWidget_DiskLoad_102_AcParaStrBox_Name
	.long NakaWidget_DiskLoad_103_AcIndexEditSw_Name
	.long NakaWidget_DiskLoad_104_Label_Name
; [nakarest] naka_disk_menu_file_io+0x6000  +0x6000..+0x6062 (0xea73cc, 98 B)
; [nakarest] 6 B at 0xea7428: the end marker of ResName slot 0x361 (table 0xea7228, 128 entries, InitializeCheap) -- entry 128, a pointer to the empty string right after it ("", 00 ff), as every ResName table ends.
; [nakarest] Continues the table itself: ResName slot 0x361 (table 0xea7228, 128 entries,
; [nakarest] InitializeCheap), 128 entry pointers x 4 bytes (starts 0xea7228, 92 of its 512
; [nakarest] bytes are here or later).
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6000, 0x62
; [nakarest] naka_disk_menu_file_io+0x6062  +0x6062..+0x61fa (0xea742e, 408 B)
; [nakarest] name strings, entries 0-127 of ResName slot 0x361 (table 0xea7228, 128 entries,
; [nakarest] InitializeCheap) (names for Viewable slot 0x61): "", "CmpSingleLoadSwCtl", "", "",
; [nakarest] "", "", ....
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6062, 0x4C
NakaWidget_DiskLoad_104_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x60AE, 0x2
NakaWidget_DiskLoad_103_AcIndexEditSw_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x60B0, 0x2
NakaWidget_DiskLoad_102_AcParaStrBox_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x60B2, 0x2
NakaWidget_DiskLoad_101_AcParaStrBox_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x60B4, 0x2
NakaWidget_DiskLoad_100_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x60B6, 0x2
NakaWidget_DiskInfoSmfLdWin_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x60B8, 0x12
NakaWidget_DiskLoad_98_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x60CA, 0x2
NakaWidget_DiskLoad_97_AcIndexEditSw_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x60CC, 0x2
NakaWidget_DiskLoad_96_AcParaStrBox_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x60CE, 0x2
NakaWidget_SongNameSmfLdWin_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x60D0, 0x12
NakaWidget_DiskLoad_94_AcIndexEditSw_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x60E2, 0x2
NakaWidget_DiskLoad_93_IvIndexSwDelay_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x60E4, 0x2
NakaWidget_DiskLoad_92_IvExit_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x60E6, 0x2
NakaWidget_DiskLoad_91_IvMainEditSw_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x60E8, 0x2
NakaWidget_DiskLoad_90_PsFileNameBox_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x60EA, 0x2
NakaWidget_DiskLoad_89_AcIndexEditSw_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x60EC, 0x2
NakaWidget_DiskLoad_88_PsFileNameBox_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x60EE, 0x2
NakaWidget_DiskLoad_87_PsFileNameBox_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x60F0, 0x2
NakaWidget_DiskLoad_86_AcIndexEditSw_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x60F2, 0x2
NakaWidget_DiskLoad_85_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x60F4, 0x2
NakaWidget_DiskLoad_84_PsWindowToggle_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x60F6, 0x2
NakaWidget_DiskLoad_83_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x60F8, 0x2
NakaWidget_DiskLoad_82_PsFileNameBox_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x60FA, 0x2
NakaWidget_DiskLoad_81_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x60FC, 0x2
NakaWidget_DiskLoad_80_AcIndexEditSw_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x60FE, 0x2
NakaWidget_DiskLoad_79_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6100, 0x2
NakaWidget_DiskLoad_78_AcIndexEditSw_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6102, 0x2
NakaWidget_DiskLoad_77_AcIndexWideES_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6104, 0x2
NakaWidget_DiskLoad_76_AcTitleMenu_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6106, 0x2
NakaWidget_DiskLoadSMF_Name:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6108, 0xC
Cheap_ResNameTable_361_Str_SingleBankToggle:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6114, 0x12
NakaWidget_DiskLoad_73_PsFileNameBox_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6126, 0x2
NakaWidget_DiskLoad_72_PsFileNameBox_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6128, 0x2
NakaWidget_DiskLoad_71_PsFileNameBox_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x612A, 0x2
NakaWidget_DiskLoad_70_PsFileNameBox_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x612C, 0x2
NakaWidget_DiskLoad_69_PsFileNameBox_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x612E, 0x2
NakaWidget_DiskLoad_68_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6130, 0x2
NakaWidget_DiskLoad_67_PsFileNameBox_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6132, 0x2
NakaWidget_DiskLoad_66_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6134, 0x2
NakaWidget_DiskLoad_65_AcParaStrBox_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6136, 0x2
NakaWidget_DiskLoad_64_AcIndexWideES_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6138, 0x2
NakaWidget_DiskLoad_63_AcIndexWideES_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x613A, 0x2
NakaWidget_DiskLoad_62_PsFileNameBox_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x613C, 0x2
NakaWidget_DiskLoad_61_AcIndexEditSw_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x613E, 0x2
NakaWidget_DiskLoad_60_AcIndexWideES_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6140, 0x2
NakaWidget_DiskLoad_59_AcIndexWideES_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6142, 0x2
NakaWidget_DiskLoad_58_Arrow_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6144, 0x2
NakaWidget_DiskLoad_57_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6146, 0x2
NakaWidget_DiskLoad_56_AcIndexEditSw_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6148, 0x2
NakaWidget_DiskLoad_55_IvIndexSwDelay_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x614A, 0x2
NakaWidget_SingleLoadSwCtl_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x614C, 0x10
NakaWidget_DiskLoad_53_VwScreenTitle_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x615C, 0x2
NakaWidget_DiskLoadP3_Name:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x615E, 0xC
NakaWidget_DiskLoad_51_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x616A, 0x2
NakaWidget_DiskLoad_50_VwScreenTitle_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x616C, 0x2
NakaWidget_DiskLoad_49_AcIndexEditSw_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x616E, 0x2
NakaWidget_DiskLoad_48_Line_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6170, 0x2
NakaWidget_DiskLoad_47_PsFileNameBox_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6172, 0x2
NakaWidget_DiskLoad_46_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6174, 0x2
NakaWidget_DiskLoad_45_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6176, 0x2
NakaWidget_DiskLoad_44_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6178, 0x2
NakaWidget_DiskLoad_43_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x617A, 0x2
NakaWidget_DiskLoad_42_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x617C, 0x2
NakaWidget_DiskLoad_41_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x617E, 0x7C
; [nakarest] naka_disk_menu_file_io+0x61fa  +0x61fa..+0x6200 (0xea75c6, 6 B)
; [nakarest] the table itself: ResName slot 0x362 (table 0xea75c6, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
Cheap_ResNameTable_362:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x61FA, 0x6
; [nakarest] naka_disk_menu_file_io+0x6200  +0x6200..+0x6206 (0xea75cc, 6 B)
; [nakarest] the table itself: ResName slot 0x363 (table 0xea75cc, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
Cheap_ResNameTable_363:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6200, 0x6
; [nakarest] naka_disk_menu_file_io+0x6206  +0x6206..+0x620c (0xea75d2, 6 B)
; [nakarest] the table itself: ResName slot 0x364 (table 0xea75d2, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
Cheap_ResNameTable_364:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6206, 0x6
; [nakarest] naka_disk_menu_file_io+0x620c  +0x620c..+0x621e (0xea75d8, 18 B)
; [nakarest] the table itself: ResName slot 0x365 (table 0xea75d8, 3 entries, InitializeCheap),
; [nakarest] 3 entry pointers x 4 bytes.
Cheap_ResNameTable_365:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x620C, 0x12
; [nakarest] naka_disk_menu_file_io+0x621e  +0x621e..+0x6230 (0xea75ea, 18 B)
; [nakarest] name strings, entries 0-2 of ResName slot 0x365 (table 0xea75d8, 3 entries,
; [nakarest] InitializeCheap) (names for Viewable slot 0x65): "", "", "DiskSaveMenu".
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x621E, 0x12
; [nakarest] naka_disk_menu_file_io+0x6230  +0x6230..+0x6236 (0xea75fc, 6 B)
; [nakarest] the table itself: ResName slot 0x366 (table 0xea75fc, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
InitializeCheap_Str_Empty:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6230, 0x1
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6231, 0x5	; 5 bytes after InitializeCheap_Str_Empty's string; unnamed (they sat under its label until 2026-10-03)
; [nakarest] naka_disk_menu_file_io+0x6236  +0x6236..+0x6358 (0xea7602, 290 B)
; [nakarest] the table itself: ResName slot 0x367 (table 0xea7602, 71 entries, InitializeCheap),
; [nakarest] 71 entry pointers x 4 bytes.
Cheap_ResNameTable_367:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6236, 0x122
; [nakarest] naka_disk_menu_file_io+0x6358  +0x6358..+0x6418 (0xea7724, 192 B)
; [nakarest] name strings, entries 0-70 of ResName slot 0x367 (table 0xea7602, 71 entries,
; [nakarest] InitializeCheap) (names for Viewable slot 0x67): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6358, 0xC0
; [nakarest] naka_disk_menu_file_io+0x6418  +0x6418..+0x641e (0xea77e4, 6 B)
; [nakarest] the table itself: ResName slot 0x36a (table 0xea77e4, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
Cheap_ResNameTable_36A:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6418, 0x6
; [nakarest] naka_disk_menu_file_io+0x641e  +0x641e..+0x6478 (0xea77ea, 90 B)
; [nakarest] the table itself: ResName slot 0x36b (table 0xea77ea, 21 entries, InitializeCheap),
; [nakarest] 21 entry pointers x 4 bytes.
Cheap_ResNameTable_36B:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x641E, 0x5A
; [nakarest] naka_disk_menu_file_io+0x6478  +0x6478..+0x64ac (0xea7844, 52 B)
; [nakarest] name strings, entries 0-20 of ResName slot 0x36b (table 0xea77ea, 21 entries,
; [nakarest] InitializeCheap) (names for Viewable slot 0x6b): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6478, 0x34
; [nakarest] naka_disk_menu_file_io+0x64ac  +0x64ac..+0x6500 (0xea7878, 84 B)
; [nakarest] the table itself: ResName slot 0x36c (table 0xea7878, 83 entries, InitializeCheap),
; [nakarest] 83 entry pointers x 4 bytes.
Cheap_ResNameTable_36C:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x64AC, 0x54
	.long NakaWidget_DiskSmfDirectPlay_21_IvOneShotTimer_Name
	.long NakaWidget_DiskSmfDirectPlay_22_Label_Name
	.long NakaWidget_DiskSmfDirectPlay_23_Label_Name
	.long NakaWidget_SmfMidiOut_Name
	.long NakaWidget_DiskSmfDirectPlay_25_Label_Name
	.long NakaWidget_DiskSmfDirectPlay_26_IvIndexSwDelay_Name
	.long NakaWidget_DiskSmfDirectPlay_27_AcIndexEditSw_Name
	.long NakaWidget_SongNameDPSmfWin_Name
	.long NakaWidget_DiskSmfDirectPlay_29_AcParaStrBox_Name
	.long NakaWidget_DiskSmfDirectPlay_30_AcIndexEditSw_Name
	.long NakaWidget_DiskSmfDirectPlay_31_Label_Name
	.long NakaWidget_DiskInfoDPSmfWin_Name
	.long NakaWidget_DiskSmfDirectPlay_33_Label_Name
	.long NakaWidget_DiskSmfDirectPlay_34_AcParaStrBox_Name
	.long NakaWidget_DiskSmfDirectPlay_35_AcParaStrBox_Name
	.long NakaWidget_DiskSmfDirectPlay_36_AcIndexEditSw_Name
	.long NakaWidget_DiskSmfDirectPlay_37_Label_Name
	.long NakaWidget_DiskDocDirectPlay_Name
	.long NakaWidget_DiskSmfDirectPlay_39_PsFileNameBox_Name
	.long NakaWidget_DiskSmfDirectPlay_40_PsFileNameBox_Name
	.long NakaWidget_DiskSmfDirectPlay_41_AcIndexEditSw_Name
	.long NakaWidget_DiskSmfDirectPlay_42_Label_Name
	.long NakaWidget_DiskSmfDirectPlay_43_AcIndexWideES_Name
	.long NakaWidget_DiskSmfDirectPlay_44_AcIndexEditSw_Name
	.long NakaWidget_DiskSmfDirectPlay_45_Label_Name
	.long NakaWidget_DiskSmfDirectPlay_46_Label_Name
	.long NakaWidget_DiskSmfDirectPlay_47_IvOneShotTimer_Name
	.long NakaWidget_DiskSmfDirectPlay_48_Line_Name
	.long NakaWidget_DiskSmfDirectPlay_49_Line_Name
	.long NakaWidget_DiskSmfDirectPlay_50_Line_Name
	.long NakaWidget_DiskSmfDirectPlay_51_Line_Name
	.long NakaWidget_DiskSmfDirectPlay_52_AcIndexEditSw_Name
	.long NakaWidget_DiskSmfDirectPlay_53_AcIndexEditSw_Name
	.long NakaWidget_DiskSmfDirectPlay_54_Label_Name
	.long NakaWidget_DiskSmfDirectPlay_55_AcMonoIndexToggle_Name
	.long NakaWidget_DiskSmfDirectPlay_56_AcParaStrBox_Name
	.long NakaWidget_DiskSmfDirectPlay_57_AcIndexEditSw_Name
	.long NakaWidget_DiskSmfDirectPlay_58_Label_Name
	.long NakaWidget_DiskSmfDirectPlay_59_Label_Name
	.long NakaWidget_DiskSmfDirectPlay_60_Label_Name
	.long NakaWidget_DiskPdDirectPlay_Name
	.long NakaWidget_DiskSmfDirectPlay_62_PsFileNameBox_Name
	.long NakaWidget_DiskSmfDirectPlay_63_PsFileNameBox_Name
	.long NakaWidget_DiskSmfDirectPlay_64_AcIndexWideES_Name
	.long NakaWidget_DiskSmfDirectPlay_65_AcIndexEditSw_Name
	.long NakaWidget_DiskSmfDirectPlay_66_Label_Name
	.long NakaWidget_DiskSmfDirectPlay_67_AcIndexEditSw_Name
	.long NakaWidget_DiskSmfDirectPlay_68_Label_Name
	.long NakaWidget_DiskSmfDirectPlay_69_AcIndexEditSw_Name
	.long NakaWidget_DiskSmfDirectPlay_70_IvOneShotTimer_Name
	.long NakaWidget_DiskSmfDirectPlay_71_AcIndexEditSw_Name
	.long NakaWidget_DiskSmfDirectPlay_72_AcMonoIndexToggle_Name
	.long NakaWidget_DiskSmfDirectPlay_73_Label_Name
	.long NakaWidget_DiskSmfDirectPlay_74_AcIndexEditSw_Name
	.long NakaWidget_DiskSmfDirectPlay_75_Label_Name
	.long NakaWidget_DiskSmfDirectPlay_76_Label_Name
	.long NakaWidget_DiskSmfDirectPlay_77_Line_Name
	.long NakaWidget_DiskSmfDirectPlay_78_Line_Name
	.long NakaWidget_DiskSmfDirectPlay_79_Line_Name
	.long NakaWidget_DiskSmfDirectPlay_80_Line_Name
	.long NakaWidget_DiskSmfDirectPlay_81_Label_Name
	.long NakaWidget_DiskSmfDirectPlay_82_Label_Name
	.long InitializeCheap_PtrTable_5_EndName
; [nakarest] naka_disk_menu_file_io+0x65fc  +0x65fc..+0x65fe (0xea79c8, 2 B)
; [nakarest] purpose not established: layout of 2 B at 0xea79c8 not derived; readers below
; [nakarest] Readers: source references Cheap_ResNameTable_36C
; [nakarest] (ui_widgets/disk_menu_file_io_screens.s: `.long 0x00ea79c8`); 1 data word in
; [nakarest] Cheap_ResNameTable_36C (at 0xea79c4).
InitializeCheap_PtrTable_5_EndName:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x65FC, 0x2
; [nakarest] naka_disk_menu_file_io+0x65fe  +0x65fe..+0x66fe (0xea79ca, 256 B)
; [nakarest] name strings, entries 0-82 of ResName slot 0x36c (table 0xea7878, 83 entries,
; [nakarest] InitializeCheap) (names for Viewable slot 0x6c): "", "", "", "", "", "", ....
NakaWidget_DiskSmfDirectPlay_82_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x65FE, 0x2
NakaWidget_DiskSmfDirectPlay_81_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6600, 0x2
NakaWidget_DiskSmfDirectPlay_80_Line_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6602, 0x2
NakaWidget_DiskSmfDirectPlay_79_Line_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6604, 0x2
NakaWidget_DiskSmfDirectPlay_78_Line_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6606, 0x2
NakaWidget_DiskSmfDirectPlay_77_Line_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6608, 0x2
NakaWidget_DiskSmfDirectPlay_76_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x660A, 0x2
NakaWidget_DiskSmfDirectPlay_75_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x660C, 0x2
NakaWidget_DiskSmfDirectPlay_74_AcIndexEditSw_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x660E, 0x2
NakaWidget_DiskSmfDirectPlay_73_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6610, 0x2
NakaWidget_DiskSmfDirectPlay_72_AcMonoIndexToggle_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6612, 0x2
NakaWidget_DiskSmfDirectPlay_71_AcIndexEditSw_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6614, 0x2
NakaWidget_DiskSmfDirectPlay_70_IvOneShotTimer_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6616, 0x2
NakaWidget_DiskSmfDirectPlay_69_AcIndexEditSw_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6618, 0x2
NakaWidget_DiskSmfDirectPlay_68_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x661A, 0x2
NakaWidget_DiskSmfDirectPlay_67_AcIndexEditSw_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x661C, 0x2
NakaWidget_DiskSmfDirectPlay_66_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x661E, 0x2
NakaWidget_DiskSmfDirectPlay_65_AcIndexEditSw_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6620, 0x2
NakaWidget_DiskSmfDirectPlay_64_AcIndexWideES_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6622, 0x2
NakaWidget_DiskSmfDirectPlay_63_PsFileNameBox_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6624, 0x2
NakaWidget_DiskSmfDirectPlay_62_PsFileNameBox_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6626, 0x2
NakaWidget_DiskPdDirectPlay_Name:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6628, 0x12
NakaWidget_DiskSmfDirectPlay_60_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x663A, 0x2
NakaWidget_DiskSmfDirectPlay_59_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x663C, 0x2
NakaWidget_DiskSmfDirectPlay_58_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x663E, 0x2
NakaWidget_DiskSmfDirectPlay_57_AcIndexEditSw_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6640, 0x2
NakaWidget_DiskSmfDirectPlay_56_AcParaStrBox_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6642, 0x2
NakaWidget_DiskSmfDirectPlay_55_AcMonoIndexToggle_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6644, 0x2
NakaWidget_DiskSmfDirectPlay_54_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6646, 0x2
NakaWidget_DiskSmfDirectPlay_53_AcIndexEditSw_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6648, 0x2
NakaWidget_DiskSmfDirectPlay_52_AcIndexEditSw_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x664A, 0x2
NakaWidget_DiskSmfDirectPlay_51_Line_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x664C, 0x2
NakaWidget_DiskSmfDirectPlay_50_Line_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x664E, 0x2
NakaWidget_DiskSmfDirectPlay_49_Line_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6650, 0x2
NakaWidget_DiskSmfDirectPlay_48_Line_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6652, 0x2
NakaWidget_DiskSmfDirectPlay_47_IvOneShotTimer_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6654, 0x2
NakaWidget_DiskSmfDirectPlay_46_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6656, 0x2
NakaWidget_DiskSmfDirectPlay_45_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6658, 0x2
NakaWidget_DiskSmfDirectPlay_44_AcIndexEditSw_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x665A, 0x2
NakaWidget_DiskSmfDirectPlay_43_AcIndexWideES_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x665C, 0x2
NakaWidget_DiskSmfDirectPlay_42_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x665E, 0x2
NakaWidget_DiskSmfDirectPlay_41_AcIndexEditSw_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6660, 0x2
NakaWidget_DiskSmfDirectPlay_40_PsFileNameBox_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6662, 0x2
NakaWidget_DiskSmfDirectPlay_39_PsFileNameBox_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6664, 0x2
NakaWidget_DiskDocDirectPlay_Name:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6666, 0x12
NakaWidget_DiskSmfDirectPlay_37_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6678, 0x2
NakaWidget_DiskSmfDirectPlay_36_AcIndexEditSw_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x667A, 0x2
NakaWidget_DiskSmfDirectPlay_35_AcParaStrBox_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x667C, 0x2
NakaWidget_DiskSmfDirectPlay_34_AcParaStrBox_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x667E, 0x2
NakaWidget_DiskSmfDirectPlay_33_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6680, 0x2
NakaWidget_DiskInfoDPSmfWin_Name:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6682, 0x12
NakaWidget_DiskSmfDirectPlay_31_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6694, 0x2
NakaWidget_DiskSmfDirectPlay_30_AcIndexEditSw_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6696, 0x2
NakaWidget_DiskSmfDirectPlay_29_AcParaStrBox_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6698, 0x2
NakaWidget_SongNameDPSmfWin_Name:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x669A, 0x12
NakaWidget_DiskSmfDirectPlay_27_AcIndexEditSw_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x66AC, 0x2
NakaWidget_DiskSmfDirectPlay_26_IvIndexSwDelay_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x66AE, 0x2
NakaWidget_DiskSmfDirectPlay_25_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x66B0, 0x2
NakaWidget_SmfMidiOut_Name:				.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x66B2, 0xC
NakaWidget_DiskSmfDirectPlay_23_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x66BE, 0x2
NakaWidget_DiskSmfDirectPlay_22_Label_Name:		.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x66C0, 0x2
NakaWidget_DiskSmfDirectPlay_21_IvOneShotTimer_Name:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x66C2, 0x3C
; [nakarest] naka_disk_menu_file_io+0x66fe  +0x66fe..+0x6704 (0xea7aca, 6 B)
; [nakarest] the table itself: ResName slot 0x36d (table 0xea7aca, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
Cheap_ResNameTable_36D:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x66FE, 0x6
; [nakarest] naka_disk_menu_file_io+0x6704  +0x6704..+0x670a (0xea7ad0, 6 B)
; [nakarest] the table itself: ResName slot 0x36e (table 0xea7ad0, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
Cheap_ResNameTable_36E:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6704, 0x6
; [nakarest] naka_disk_menu_file_io+0x670a  +0x670a..+0x6764 (0xea7ad6, 90 B)
; [nakarest] the table itself: ResName slot 0x377 (table 0xea7ad6, 21 entries, InitializeCheap),
; [nakarest] 21 entry pointers x 4 bytes.
Cheap_ResNameTable_377:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x670A, 0x5A
; [nakarest] naka_disk_menu_file_io+0x6764  +0x6764..+0x67c0 (0xea7b30, 92 B)
; [nakarest] name strings, entries 0-20 of ResName slot 0x377 (table 0xea7ad6, 21 entries,
; [nakarest] InitializeCheap) (names for Viewable slot 0x77): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6764, 0x5C
; [nakarest] naka_disk_menu_file_io+0x67c0  +0x67c0..+0x67c6 (0xea7b8c, 6 B)
; [nakarest] the table itself: ResName slot 0x379 (table 0xea7b8c, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
Cheap_ResNameTable_379:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x67C0, 0x6
; [nakarest] naka_disk_menu_file_io+0x67c6  +0x67c6..+0x6944 (0xea7b92, 382 B)
; [nakarest] the table itself: ResName slot 0x37b (table 0xea7b92, 94 entries, InitializeCheap),
; [nakarest] 94 entry pointers x 4 bytes.
Cheap_ResNameTable_37B:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x67C6, 0x17E
; [nakarest] naka_disk_menu_file_io+0x6944  +0x6944..+0x6a34 (0xea7d10, 240 B)
; [nakarest] name strings, entries 43-93 of ResName slot 0x37b (table 0xea7b92, 94 entries,
; [nakarest] InitializeCheap) (names for Viewable slot 0x7b): "", "DiskSaveSureScr", "",
; [nakarest] "DiskDeleteSureScr", "", "", ....
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6944, 0xF0
; [nakarest] NakaInst_WaitWinCtlSmf  +0x6a34..+0x6acc (0xea7e00, 152 B)
; [nakarest] name strings, entries 0-42 of ResName slot 0x37b (table 0xea7b92, 94 entries,
; [nakarest] InitializeCheap) (names for Viewable slot 0x7b): "WaitWinCtlSmf", "", "", "", "",
; [nakarest] "", ....
NakaInst_WaitWinCtlSmf:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6A34, 0x98
; [nakarest] naka_disk_menu_file_io+0x6acc  +0x6acc..+0x6ad2 (0xea7e98, 6 B)
; [nakarest] the table itself: ResName slot 0x37c (table 0xea7e98, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
Cheap_ResNameTable_37C:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6ACC, 0x6
; [nakarest] naka_disk_menu_file_io+0x6ad2  +0x6ad2..+0x6ad8 (0xea7e9e, 6 B)
; [nakarest] the table itself: ResName slot 0x37d (table 0xea7e9e, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
Cheap_ResNameTable_37D:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6AD2, 0x6
; [nakarest] naka_disk_menu_file_io+0x6ad8  +0x6ad8..+0x6afe (0xea7ea4, 38 B)
; [nakarest] the table itself: ResName slot 0x37e (table 0xea7ea4, 8 entries, InitializeCheap),
; [nakarest] 8 entry pointers x 4 bytes.
Cheap_ResNameTable_37E:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6AD8, 0x26
; [nakarest] naka_disk_menu_file_io+0x6afe  +0x6afe..+0x6b16 (0xea7eca, 24 B)
; [nakarest] name strings, entries 0-7 of ResName slot 0x37e (table 0xea7ea4, 8 entries,
; [nakarest] InitializeCheap) (names for Viewable slot 0x7e): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6AFE, 0x18
; [nakarest] naka_disk_menu_file_io+0x6b16  +0x6b16..+0x6c02 (0xea7ee2, 236 B)
; [nakarest] the table itself: ResName slot 0x3bc (table 0xea7ee2, 0 entries, InitializeCheap),
; [nakarest] 0 entry pointers x 4 bytes.
Cheap_ResNameTable_3BC:			.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6B16, 0x6
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
Cheap_MainFunctionTable_145:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6C02, 0xE8
; [nakarest] naka_disk_menu_file_io+0x6cea  +0x6cea..+0x6dd4 (0xea80b6, 234 B)
; [nakarest] the table itself: MainFunction slot 0x445 (table 0xea80b6, 57 entries,
; [nakarest] InitializeCheap), 57 entry pointers x 4 bytes.
Cheap_MainFunctionTable_445:	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6CEA, 0xEA
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
