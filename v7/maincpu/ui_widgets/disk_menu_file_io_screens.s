
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
; [nakarest] widget record, element 0 of Viewable slot 0x60 (table 0xea67b6, 74 entries,
; [nakarest] InitializeCheap) ("DiskMenu"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0x60 (table 0xea67b6, 74 entries, InitializeCheap): "DISK MENU"
; [nakarest] (TtlScreen.title of element 0). widget record, element 1 of Viewable slot 0x60
; [nakarest] (table 0xea67b6, 74 entries, InitializeCheap) ("DiskMenu"): AcTitleMenu (54 B).
; [nakarest] text the records point at, in Viewable slot 0x60 (table 0xea67b6, 74 entries,
; [nakarest] InitializeCheap): "STYLE CONVERT" (AcTitleMenu.str of element 1). widget record,
; [nakarest] element 3 of Viewable slot 0x60 (table 0xea67b6, 74 entries, InitializeCheap)
; [nakarest] ("DiskMenu"): AcTitleMenu (54 B). text the records point at, in Viewable slot 0x60
; [nakarest] (table 0xea67b6, 74 entries, InitializeCheap): "PREFERENCES" (AcTitleMenu.str of
; [nakarest] element 3). widget record, element 4 of Viewable slot 0x60 (table 0xea67b6, 74
; [nakarest] entries, InitializeCheap) ("DiskMenu"): AcTitleMenu (54 B). text the records point
; [nakarest] at, in Viewable slot 0x60 (table 0xea67b6, 74 entries, InitializeCheap): "SAVE"
; [nakarest] (AcTitleMenu.str of element 4). widget record, element 5 of Viewable slot 0x60
; [nakarest] (table 0xea67b6, 74 entries, InitializeCheap) ("DiskMenu"): AcTtlJgBox (54 B). text
; [nakarest] the records point at, in Viewable slot 0x60 (table 0xea67b6, 74 entries,
; [nakarest] InitializeCheap): "DISK TOOLS" (AcTtlJgBox.str of element 5). widget record,
; [nakarest] element 6 of Viewable slot 0x60 (table 0xea67b6, 74 entries, InitializeCheap)
; [nakarest] ("DiskMenu"): AcTtlJgBox (54 B). text the records point at, in Viewable slot 0x60
; [nakarest] (table 0xea67b6, 74 entries, InitializeCheap): "LOAD" (AcTtlJgBox.str of element
; [nakarest] 6). widget records, elements 7-8 of Viewable slot 0x60 (table 0xea67b6, 74 entries,
; [nakarest] InitializeCheap) ("DiskMenu"): IvExitMode (26 B), AcTtlJgBox (54 B). text the
; [nakarest] records point at, in Viewable slot 0x60 (table 0xea67b6, 74 entries,
; [nakarest] InitializeCheap): "DIRECT PLAY" (AcTtlJgBox.str of element 8). widget record,
; [nakarest] element 9 of Viewable slot 0x60 (table 0xea67b6, 74 entries, InitializeCheap)
; [nakarest] ("DiskMenu"): AcTtlJgBox (54 B). text the records point at, in Viewable slot 0x60
; [nakarest] (table 0xea67b6, 74 entries, InitializeCheap): "SONG MEDLEY" (AcTtlJgBox.str of
; [nakarest] element 9). widget record, element 10 of Viewable slot 0x60 (table 0xea67b6, 74
; [nakarest] entries, InitializeCheap) ("DiskMenu"): TtlScreen (42 B). text the records point
; [nakarest] at, in Viewable slot 0x60 (table 0xea67b6, 74 entries, InitializeCheap): "INTERNAL
; [nakarest] SONG MEDLEY" (TtlScreen.title of element 10). widget records, elements 11-17 of
; [nakarest] Viewable slot 0x60 (table 0xea67b6, 74 entries, InitializeCheap) ("DiskMenu"):
; [nakarest] AcIndexWideES (42 B), AcIndexEditSw (40 B) x2, PsFileNameBox (58 B) x2, Line (26
; [nakarest] B), AcMonoIndexToggle (42 B). text the records point at, in Viewable slot 0x60
; [nakarest] (table 0xea67b6, 74 entries, InitializeCheap): "OFF" (AcMonoIndexToggle.stroff of
; [nakarest] element 17); "ON" (AcMonoIndexToggle.stron of element 17). widget records, elements
; [nakarest] 18-19 of Viewable slot 0x60 (table 0xea67b6, 74 entries, InitializeCheap)
; [nakarest] ("DiskMenu"): AcIndexEditSw (40 B), Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x60 (table 0xea67b6, 74 entries, InitializeCheap): "START"
; [nakarest] (Label.str of element 19). widget records, elements 20-21 of Viewable slot 0x60
; [nakarest] (table 0xea67b6, 74 entries, InitializeCheap) ("DiskMenu"): IvOneShotTimer (26 B),
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0x60 (table 0xea67b6, 74
; [nakarest] entries, InitializeCheap): "ALL" (Label.str of element 21). widget record, element
; [nakarest] 22 of Viewable slot 0x60 (table 0xea67b6, 74 entries, InitializeCheap)
; [nakarest] ("DiskMenu"): Label (32 B). text the records point at, in Viewable slot 0x60 (table
; [nakarest] 0xea67b6, 74 entries, InitializeCheap): "ADD" (Label.str of element 22). widget
; [nakarest] record, element 23 of Viewable slot 0x60 (table 0xea67b6, 74 entries,
; [nakarest] InitializeCheap) ("DiskMenu"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0x60 (table 0xea67b6, 74 entries, InitializeCheap): "LOOP" (Label.str of
; [nakarest] element 23). widget record, element 24 of Viewable slot 0x60 (table 0xea67b6, 74
; [nakarest] entries, InitializeCheap) ("DiskMenu"): TtlScreen (42 B). text the records point
; [nakarest] at, in Viewable slot 0x60 (table 0xea67b6, 74 entries, InitializeCheap): "SAVE FILE
; [nakarest] NAMING" (TtlScreen.title of element 24). widget records, elements 25-27 of Viewable
; [nakarest] slot 0x60 (table 0xea67b6, 74 entries, InitializeCheap) ("DiskMenu"): AcFuncEditSw
; [nakarest] (44 B), IvNaming (26 B), TtlScreen (42 B). text the records point at, in Viewable
; [nakarest] slot 0x60 (table 0xea67b6, 74 entries, InitializeCheap): "COMPOSER LOAD"
; [nakarest] (TtlScreen.title of element 27). widget records, elements 28-32 of Viewable slot
; [nakarest] 0x60 (table 0xea67b6, 74 entries, InitializeCheap) ("DiskMenu"): AcIndexEditSw (40
; [nakarest] B) x2, AcIndexWideES (42 B), PsFileNameBox (58 B), Label (32 B). text the records
; [nakarest] point at, in Viewable slot 0x60 (table 0xea67b6, 74 entries, InitializeCheap):
; [nakarest] "DISK NAME:" (Label.str of element 32). widget records, elements 33-36 of Viewable
; [nakarest] slot 0x60 (table 0xea67b6, 74 entries, InitializeCheap) ("DiskMenu"): AcParaStrBox
; [nakarest] (44 B) x2, AcIndexEditSw (40 B), Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x60 (table 0xea67b6, 74 entries, InitializeCheap): "LOAD" (Label.str
; [nakarest] of element 36). widget records, elements 37-40 of Viewable slot 0x60 (table
; [nakarest] 0xea67b6, 74 entries, InitializeCheap) ("DiskMenu"): IvExitMode (26 B), Window (36
; [nakarest] B), AcRotStrBox (48 B), TtlScreen (42 B). text the records point at, in Viewable
; [nakarest] slot 0x60 (table 0xea67b6, 74 entries, InitializeCheap): "SAVE FILE NAMING"
; [nakarest] (TtlScreen.title of element 40). widget records, elements 41-43 of Viewable slot
; [nakarest] 0x60 (table 0xea67b6, 74 entries, InitializeCheap) ("DiskMenu"): AcFuncEditSw (44
; [nakarest] B), IvNaming (26 B), TtlScreen (42 B). text the records point at, in Viewable slot
; [nakarest] 0x60 (table 0xea67b6, 74 entries, InitializeCheap): "WALLPAPER LOAD"
; [nakarest] (TtlScreen.title of element 43). widget records, elements 44-45 of Viewable slot
; [nakarest] 0x60 (table 0xea67b6, 74 entries, InitializeCheap) ("DiskMenu"): AcIndexEditSw (40
; [nakarest] B), Label (32 B). text the records point at, in Viewable slot 0x60 (table 0xea67b6,
; [nakarest] 74 entries, InitializeCheap): "PREV" (Label.str of element 45). widget records,
; [nakarest] elements 46-48 of Viewable slot 0x60 (table 0xea67b6, 74 entries, InitializeCheap)
; [nakarest] ("DiskMenu"): AcIndexWideES (42 B), AcIndexEditSw (40 B), Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0x60 (table 0xea67b6, 74 entries,
; [nakarest] InitializeCheap): "NEXT" (Label.str of element 48). widget record, element 49 of
; [nakarest] Viewable slot 0x60 (table 0xea67b6, 74 entries, InitializeCheap) ("DiskMenu"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0x60 (table 0xea67b6, 74
; [nakarest] entries, InitializeCheap): "DISK NAME:" (Label.str of element 49). widget records,
; [nakarest] elements 50-53 of Viewable slot 0x60 (table 0xea67b6, 74 entries, InitializeCheap)
; [nakarest] ("DiskMenu"): AcParaStrBox (44 B) x2, AcIndexEditSw (40 B), Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0x60 (table 0xea67b6, 74 entries,
; [nakarest] InitializeCheap): "LOAD" (Label.str of element 53). widget records, elements 54-73
; [nakarest] of Viewable slot 0x60 (table 0xea67b6, 74 entries, InitializeCheap) ("DiskMenu"):
; [nakarest] PsFileNameBox (58 B), Window (36 B) x3, VwBox (28 B), AcLanguageText (42 B) x5,
; [nakarest] Line (26 B), AcFuncEditSw (44 B) x7, IvNaming (26 B) x2.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xE8, 0xC8E
; [nakarest] naka_disk_menu_file_io+0xd76  +0xd76..+0x22a0 (0xea2142, 5418 B)
; [nakarest] widget record, element 0 of Viewable slot 0x61 (table 0xea68e2, 128 entries,
; [nakarest] InitializeCheap) ("DiskLoad"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0x61 (table 0xea68e2, 128 entries, InitializeCheap): ""
; [nakarest] (TtlScreen.title of element 0). widget records, elements 1-10 of Viewable slot 0x61
; [nakarest] (table 0xea68e2, 128 entries, InitializeCheap) ("DiskLoad"): AcWindowPage (36 B),
; [nakarest] IvPageControl (28 B) x3, IvExit (22 B), IvMainEditSw (26 B), Window (36 B),
; [nakarest] PsFileNameBox (58 B), AcIndexEditSw (40 B), Label (32 B). text the records point
; [nakarest] at, in Viewable slot 0x61 (table 0xea68e2, 128 entries, InitializeCheap): "LOAD"
; [nakarest] (Label.str of element 10). widget records, elements 11-12 of Viewable slot 0x61
; [nakarest] (table 0xea68e2, 128 entries, InitializeCheap) ("DiskLoad"): AcFileSfxBox (34 B),
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0x61 (table 0xea68e2, 128
; [nakarest] entries, InitializeCheap): "DISK NAME:" (Label.str of element 12). widget record,
; [nakarest] element 13 of Viewable slot 0x61 (table 0xea68e2, 128 entries, InitializeCheap)
; [nakarest] ("DiskLoad"): AcTitleMenu (54 B). text the records point at, in Viewable slot 0x61
; [nakarest] (table 0xea68e2, 128 entries, InitializeCheap): "SMF" (AcTitleMenu.str of element
; [nakarest] 13). widget records, elements 14-19 of Viewable slot 0x61 (table 0xea68e2, 128
; [nakarest] entries, InitializeCheap) ("DiskLoad"): AcIndexEditSw (40 B) x2, AcIndexWideES (42
; [nakarest] B), AcParaStrBox (44 B) x2, VwScreenTitle (38 B). text the records point at, in
; [nakarest] Viewable slot 0x61 (table 0xea68e2, 128 entries, InitializeCheap): "LOAD"
; [nakarest] (VwScreenTitle.title of element 19). widget records, elements 20-29 of Viewable
; [nakarest] slot 0x61 (table 0xea68e2, 128 entries, InitializeCheap) ("DiskLoad"): Window (36
; [nakarest] B), AcIndexEditSw (40 B) x8, Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0x61 (table 0xea68e2, 128 entries, InitializeCheap): "PNL" (Label.str of
; [nakarest] element 29). widget record, element 30 of Viewable slot 0x61 (table 0xea68e2, 128
; [nakarest] entries, InitializeCheap) ("DiskLoad"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x61 (table 0xea68e2, 128 entries, InitializeCheap): "P.MEM"
; [nakarest] (Label.str of element 30). widget record, element 31 of Viewable slot 0x61 (table
; [nakarest] 0xea68e2, 128 entries, InitializeCheap) ("DiskLoad"): Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0x61 (table 0xea68e2, 128 entries,
; [nakarest] InitializeCheap): "SEQ" (Label.str of element 31). widget record, element 32 of
; [nakarest] Viewable slot 0x61 (table 0xea68e2, 128 entries, InitializeCheap) ("DiskLoad"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0x61 (table 0xea68e2, 128
; [nakarest] entries, InitializeCheap): "COMP" (Label.str of element 32). widget record, element
; [nakarest] 33 of Viewable slot 0x61 (table 0xea68e2, 128 entries, InitializeCheap)
; [nakarest] ("DiskLoad"): Label (32 B). text the records point at, in Viewable slot 0x61 (table
; [nakarest] 0xea68e2, 128 entries, InitializeCheap): "SOUND" (Label.str of element 33). widget
; [nakarest] record, element 34 of Viewable slot 0x61 (table 0xea68e2, 128 entries,
; [nakarest] InitializeCheap) ("DiskLoad"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0x61 (table 0xea68e2, 128 entries, InitializeCheap): "MSP" (Label.str of
; [nakarest] element 34). widget record, element 35 of Viewable slot 0x61 (table 0xea68e2, 128
; [nakarest] entries, InitializeCheap) ("DiskLoad"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x61 (table 0xea68e2, 128 entries, InitializeCheap): "CUSTOM"
; [nakarest] (Label.str of element 35). widget record, element 36 of Viewable slot 0x61 (table
; [nakarest] 0xea68e2, 128 entries, InitializeCheap) ("DiskLoad"): Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0x61 (table 0xea68e2, 128 entries,
; [nakarest] InitializeCheap): "MIDI" (Label.str of element 36). widget records, elements 37-39
; [nakarest] of Viewable slot 0x61 (table 0xea68e2, 128 entries, InitializeCheap) ("DiskLoad"):
; [nakarest] AcParaStrBox (44 B), VwBox (28 B), Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x61 (table 0xea68e2, 128 entries, InitializeCheap): "CURRENT PANEL"
; [nakarest] (Label.str of element 39). widget record, element 40 of Viewable slot 0x61 (table
; [nakarest] 0xea68e2, 128 entries, InitializeCheap) ("DiskLoad"): Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0x61 (table 0xea68e2, 128 entries,
; [nakarest] InitializeCheap): "USER MIDI SETTINGS" (Label.str of element 40). widget record,
; [nakarest] element 41 of Viewable slot 0x61 (table 0xea68e2, 128 entries, InitializeCheap)
; [nakarest] ("DiskLoad"): Label (32 B). text the records point at, in Viewable slot 0x61 (table
; [nakarest] 0xea68e2, 128 entries, InitializeCheap): "RHYTHM CUSTOM" (Label.str of element 41).
; [nakarest] widget record, element 42 of Viewable slot 0x61 (table 0xea68e2, 128 entries,
; [nakarest] InitializeCheap) ("DiskLoad"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0x61 (table 0xea68e2, 128 entries, InitializeCheap): "MSP" (Label.str of
; [nakarest] element 42). widget record, element 43 of Viewable slot 0x61 (table 0xea68e2, 128
; [nakarest] entries, InitializeCheap) ("DiskLoad"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x61 (table 0xea68e2, 128 entries, InitializeCheap): "SOUND MEMORY"
; [nakarest] (Label.str of element 43). widget record, element 44 of Viewable slot 0x61 (table
; [nakarest] 0xea68e2, 128 entries, InitializeCheap) ("DiskLoad"): Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0x61 (table 0xea68e2, 128 entries,
; [nakarest] InitializeCheap): "COMPOSER" (Label.str of element 44). widget record, element 45
; [nakarest] of Viewable slot 0x61 (table 0xea68e2, 128 entries, InitializeCheap) ("DiskLoad"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0x61 (table 0xea68e2, 128
; [nakarest] entries, InitializeCheap): "SEQUENCER" (Label.str of element 45). widget record,
; [nakarest] element 46 of Viewable slot 0x61 (table 0xea68e2, 128 entries, InitializeCheap)
; [nakarest] ("DiskLoad"): Label (32 B). text the records point at, in Viewable slot 0x61 (table
; [nakarest] 0xea68e2, 128 entries, InitializeCheap): "PANEL MEMORY" (Label.str of element 46).
; [nakarest] widget records, elements 47-50 of Viewable slot 0x61 (table 0xea68e2, 128 entries,
; [nakarest] InitializeCheap) ("DiskLoad"): PsFileNameBox (58 B), Line (26 B), AcIndexEditSw (40
; [nakarest] B), VwScreenTitle (38 B). text the records point at, in Viewable slot 0x61 (table
; [nakarest] 0xea68e2, 128 entries, InitializeCheap): "LOAD OPTION" (VwScreenTitle.title of
; [nakarest] element 50). widget record, element 51 of Viewable slot 0x61 (table 0xea68e2, 128
; [nakarest] entries, InitializeCheap) ("DiskLoad"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x61 (table 0xea68e2, 128 entries, InitializeCheap): "LOAD"
; [nakarest] (Label.str of element 51). widget records, elements 52-53 of Viewable slot 0x61
; [nakarest] (table 0xea68e2, 128 entries, InitializeCheap) ("DiskLoad"): Window (36 B),
; [nakarest] VwScreenTitle (38 B). text the records point at, in Viewable slot 0x61 (table
; [nakarest] 0xea68e2, 128 entries, InitializeCheap): "SINGLE LOAD" (VwScreenTitle.title of
; [nakarest] element 53). widget records, elements 54-57 of Viewable slot 0x61 (table 0xea68e2,
; [nakarest] 128 entries, InitializeCheap) ("DiskLoad"): IvIndexSwCtrl (32 B), IvIndexSwDelay
; [nakarest] (30 B), AcIndexEditSw (40 B), Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0x61 (table 0xea68e2, 128 entries, InitializeCheap): "LOAD" (Label.str of
; [nakarest] element 57). widget records, elements 58-66 of Viewable slot 0x61 (table 0xea68e2,
; [nakarest] 128 entries, InitializeCheap) ("DiskLoad"): Arrow (32 B), AcIndexWideES (42 B) x4,
; [nakarest] AcIndexEditSw (40 B), PsFileNameBox (58 B), AcParaStrBox (44 B), Label (32 B). text
; [nakarest] the records point at, in Viewable slot 0x61 (table 0xea68e2, 128 entries,
; [nakarest] InitializeCheap): "TO" (Label.str of element 66). widget records, elements 67-68 of
; [nakarest] Viewable slot 0x61 (table 0xea68e2, 128 entries, InitializeCheap) ("DiskLoad"):
; [nakarest] PsFileNameBox (58 B), Label (32 B). text the records point at, in Viewable slot
; [nakarest] 0x61 (table 0xea68e2, 128 entries, InitializeCheap): "MODE" (Label.str of element
; [nakarest] 68). widget records, elements 69-73, 75 of Viewable slot 0x61 (table 0xea68e2, 128
; [nakarest] entries, InitializeCheap) ("DiskLoad"): PsFileNameBox (58 B) x5, TtlScreen (42 B).
; [nakarest] text the records point at, in Viewable slot 0x61 (table 0xea68e2, 128 entries,
; [nakarest] InitializeCheap): "SMF LOAD" (TtlScreen.title of element 75). widget record,
; [nakarest] element 76 of Viewable slot 0x61 (table 0xea68e2, 128 entries, InitializeCheap)
; [nakarest] ("DiskLoad"): AcTitleMenu (54 B). text the records point at, in Viewable slot 0x61
; [nakarest] (table 0xea68e2, 128 entries, InitializeCheap): "TECH" (AcTitleMenu.str of element
; [nakarest] 76). widget records, elements 77-79 of Viewable slot 0x61 (table 0xea68e2, 128
; [nakarest] entries, InitializeCheap) ("DiskLoad"): AcIndexWideES (42 B), AcIndexEditSw (40 B),
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0x61 (table 0xea68e2, 128
; [nakarest] entries, InitializeCheap): "PREV" (Label.str of element 79). widget records,
; [nakarest] elements 80-81 of Viewable slot 0x61 (table 0xea68e2, 128 entries, InitializeCheap)
; [nakarest] ("DiskLoad"): AcIndexEditSw (40 B), Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x61 (table 0xea68e2, 128 entries, InitializeCheap): "NEXT"
; [nakarest] (Label.str of element 81). widget records, elements 82-83 of Viewable slot 0x61
; [nakarest] (table 0xea68e2, 128 entries, InitializeCheap) ("DiskLoad"): PsFileNameBox (58 B),
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0x61 (table 0xea68e2, 128
; [nakarest] entries, InitializeCheap): "INFO" (Label.str of element 83). widget record, element
; [nakarest] 84 of Viewable slot 0x61 (table 0xea68e2, 128 entries, InitializeCheap)
; [nakarest] ("DiskLoad"): PsWindowToggle (52 B). text the records point at, in Viewable slot
; [nakarest] 0x61 (table 0xea68e2, 128 entries, InitializeCheap): "DISK" (PsWindowToggle.stroff
; [nakarest] of element 84); "SONG" (PsWindowToggle.stron of element 84). widget record, element
; [nakarest] 85 of Viewable slot 0x61 (table 0xea68e2, 128 entries, InitializeCheap)
; [nakarest] ("DiskLoad"): Label (32 B). text the records point at, in Viewable slot 0x61 (table
; [nakarest] 0xea68e2, 128 entries, InitializeCheap): "LOAD AS" (Label.str of element 85).
; [nakarest] widget records, elements 86-98 of Viewable slot 0x61 (table 0xea68e2, 128 entries,
; [nakarest] InitializeCheap) ("DiskLoad"): AcIndexEditSw (40 B) x4, PsFileNameBox (58 B) x3,
; [nakarest] IvMainEditSw (26 B), IvExit (22 B), IvIndexSwDelay (30 B), Window (36 B),
; [nakarest] AcParaStrBox (44 B), Label (32 B). text the records point at, in Viewable slot 0x61
; [nakarest] (table 0xea68e2, 128 entries, InitializeCheap): "LOAD" (Label.str of element 98).
; [nakarest] widget records, elements 99-100 of Viewable slot 0x61 (table 0xea68e2, 128 entries,
; [nakarest] InitializeCheap) ("DiskLoad"): Window (36 B), Label (32 B). text the records point
; [nakarest] at, in Viewable slot 0x61 (table 0xea68e2, 128 entries, InitializeCheap): "DISK
; [nakarest] NAME:" (Label.str of element 100). widget records, elements 101-104 of Viewable
; [nakarest] slot 0x61 (table 0xea68e2, 128 entries, InitializeCheap) ("DiskLoad"): AcParaStrBox
; [nakarest] (44 B) x2, AcIndexEditSw (40 B), Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x61 (table 0xea68e2, 128 entries, InitializeCheap): "LOAD"
; [nakarest] (Label.str of element 104). widget record, element 105 of Viewable slot 0x61 (table
; [nakarest] 0xea68e2, 128 entries, InitializeCheap) ("DiskLoad"): TtlScreen (42 B). text the
; [nakarest] records point at, in Viewable slot 0x61 (table 0xea68e2, 128 entries,
; [nakarest] InitializeCheap): "LOAD SINGLE COMPOSER" (TtlScreen.title of element 105). widget
; [nakarest] records, elements 106-113 of Viewable slot 0x61 (table 0xea68e2, 128 entries,
; [nakarest] InitializeCheap) ("DiskLoad"): AcIndexWideES (42 B) x4, PsFileNameBox (58 B) x2,
; [nakarest] AcIndexEditSw (40 B), Label (32 B). text the records point at, in Viewable slot
; [nakarest] 0x61 (table 0xea68e2, 128 entries, InitializeCheap): "LOAD" (Label.str of element
; [nakarest] 113). widget records, elements 114-115 of Viewable slot 0x61 (table 0xea68e2, 128
; [nakarest] entries, InitializeCheap) ("DiskLoad"): Arrow (32 B), Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0x61 (table 0xea68e2, 128 entries,
; [nakarest] InitializeCheap): "TO" (Label.str of element 115). widget record, element 116 of
; [nakarest] Viewable slot 0x61 (table 0xea68e2, 128 entries, InitializeCheap) ("DiskLoad"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0x61 (table 0xea68e2, 128
; [nakarest] entries, InitializeCheap): "FROM" (Label.str of element 116). widget records,
; [nakarest] elements 117-119 of Viewable slot 0x61 (table 0xea68e2, 128 entries,
; [nakarest] InitializeCheap) ("DiskLoad"): AcIndexEditSw (40 B) x2, Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0x61 (table 0xea68e2, 128 entries,
; [nakarest] InitializeCheap): "FILE" (Label.str of element 119). widget records, elements
; [nakarest] 120-121 of Viewable slot 0x61 (table 0xea68e2, 128 entries, InitializeCheap)
; [nakarest] ("DiskLoad"): PsFileNameBox (58 B), AcMonoIndexToggle (42 B). text the records
; [nakarest] point at, in Viewable slot 0x61 (table 0xea68e2, 128 entries, InitializeCheap):
; [nakarest] "SINGLE" (AcMonoIndexToggle.stroff of element 121); "BANK" (AcMonoIndexToggle.stron
; [nakarest] of element 121). widget records, elements 122-127 of Viewable slot 0x61 (table
; [nakarest] 0xea68e2, 128 entries, InitializeCheap) ("DiskLoad"): PsFileNameBox (58 B) x4,
; [nakarest] IvIndexSwCtrl (32 B), IvIndexSwDelay (30 B).
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xD76, 0x152A
; [nakarest] naka_disk_menu_file_io+0x22a0  +0x22a0..+0x235a (0xea366c, 186 B)
; [nakarest] widget record, element 0 of Viewable slot 0x65 (table 0xea6af2, 3 entries,
; [nakarest] InitializeCheap) ("DiskSaveMenu"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0x65 (table 0xea6af2, 3 entries, InitializeCheap): "SAVE"
; [nakarest] (TtlScreen.title of element 0). widget record, element 1 of Viewable slot 0x65
; [nakarest] (table 0xea6af2, 3 entries, InitializeCheap) ("DiskSaveMenu"): AcTtlJgBox (54 B).
; [nakarest] text the records point at, in Viewable slot 0x65 (table 0xea6af2, 3 entries,
; [nakarest] InitializeCheap): "TECHNICS FORMAT" (AcTtlJgBox.str of element 1). widget record,
; [nakarest] element 2 of Viewable slot 0x65 (table 0xea6af2, 3 entries, InitializeCheap)
; [nakarest] ("DiskSaveMenu"): AcTtlJgBox (54 B). text the records point at, in Viewable slot
; [nakarest] 0x65 (table 0xea6af2, 3 entries, InitializeCheap): "SMF FORMAT 0" (AcTtlJgBox.str
; [nakarest] of element 2).
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x22A0, 0xBA
; [nakarest] naka_disk_menu_file_io+0x235a  +0x235a..+0x2e60 (0xea3726, 2822 B)
; [nakarest] widget record, element 0 of Viewable slot 0x67 (table 0xea6b06, 71 entries,
; [nakarest] InitializeCheap) ("DiskSave"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0x67 (table 0xea6b06, 71 entries, InitializeCheap): ""
; [nakarest] (TtlScreen.title of element 0). widget records, elements 1-12 of Viewable slot 0x67
; [nakarest] (table 0xea6b06, 71 entries, InitializeCheap) ("DiskSave"): AcWindowPage (36 B),
; [nakarest] IvPageControl (28 B) x3, IvExit (22 B), IvMainEditSw (26 B), Window (36 B),
; [nakarest] AcIndexWideES (42 B), AcIndexEditSw (40 B) x2, AcParaStrBox (44 B), Label (32 B).
; [nakarest] text the records point at, in Viewable slot 0x67 (table 0xea6b06, 71 entries,
; [nakarest] InitializeCheap): "SAVE AS :" (Label.str of element 12). widget records, elements
; [nakarest] 13-14 of Viewable slot 0x67 (table 0xea6b06, 71 entries, InitializeCheap)
; [nakarest] ("DiskSave"): AcParaStrBox (44 B), AcTitleMenu (54 B). text the records point at,
; [nakarest] in Viewable slot 0x67 (table 0xea6b06, 71 entries, InitializeCheap): "NAME"
; [nakarest] (AcTitleMenu.str of element 14). widget records, elements 15-17 of Viewable slot
; [nakarest] 0x67 (table 0xea6b06, 71 entries, InitializeCheap) ("DiskSave"): PsFileNameBox (58
; [nakarest] B), AcIndexEditSw (40 B), Label (32 B). text the records point at, in Viewable slot
; [nakarest] 0x67 (table 0xea6b06, 71 entries, InitializeCheap): "SAVE" (Label.str of element
; [nakarest] 17). widget records, elements 18-20 of Viewable slot 0x67 (table 0xea6b06, 71
; [nakarest] entries, InitializeCheap) ("DiskSave"): AcFileSfxBox (34 B), IvCatchEvent (26 B),
; [nakarest] VwScreenTitle (38 B). text the records point at, in Viewable slot 0x67 (table
; [nakarest] 0xea6b06, 71 entries, InitializeCheap): "SAVE" (VwScreenTitle.title of element 20).
; [nakarest] widget records, elements 21-23 of Viewable slot 0x67 (table 0xea6b06, 71 entries,
; [nakarest] InitializeCheap) ("DiskSave"): Window (36 B), VwBox (28 B), Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0x67 (table 0xea6b06, 71 entries,
; [nakarest] InitializeCheap): "CURRENT PANEL" (Label.str of element 23). widget record, element
; [nakarest] 24 of Viewable slot 0x67 (table 0xea6b06, 71 entries, InitializeCheap)
; [nakarest] ("DiskSave"): Label (32 B). text the records point at, in Viewable slot 0x67 (table
; [nakarest] 0xea6b06, 71 entries, InitializeCheap): "USER MIDI SETTINGS" (Label.str of element
; [nakarest] 24). widget record, element 25 of Viewable slot 0x67 (table 0xea6b06, 71 entries,
; [nakarest] InitializeCheap) ("DiskSave"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0x67 (table 0xea6b06, 71 entries, InitializeCheap): "RHYTHM CUSTOM" (Label.str
; [nakarest] of element 25). widget record, element 26 of Viewable slot 0x67 (table 0xea6b06, 71
; [nakarest] entries, InitializeCheap) ("DiskSave"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x67 (table 0xea6b06, 71 entries, InitializeCheap): "MSP" (Label.str
; [nakarest] of element 26). widget record, element 27 of Viewable slot 0x67 (table 0xea6b06, 71
; [nakarest] entries, InitializeCheap) ("DiskSave"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x67 (table 0xea6b06, 71 entries, InitializeCheap): "SOUND MEMORY"
; [nakarest] (Label.str of element 27). widget record, element 28 of Viewable slot 0x67 (table
; [nakarest] 0xea6b06, 71 entries, InitializeCheap) ("DiskSave"): Label (32 B). text the records
; [nakarest] point at, in Viewable slot 0x67 (table 0xea6b06, 71 entries, InitializeCheap):
; [nakarest] "COMPOSER" (Label.str of element 28). widget record, element 29 of Viewable slot
; [nakarest] 0x67 (table 0xea6b06, 71 entries, InitializeCheap) ("DiskSave"): Label (32 B). text
; [nakarest] the records point at, in Viewable slot 0x67 (table 0xea6b06, 71 entries,
; [nakarest] InitializeCheap): "SEQUENCER" (Label.str of element 29). widget record, element 30
; [nakarest] of Viewable slot 0x67 (table 0xea6b06, 71 entries, InitializeCheap) ("DiskSave"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0x67 (table 0xea6b06, 71
; [nakarest] entries, InitializeCheap): "PANEL MEMORY" (Label.str of element 30). widget
; [nakarest] records, elements 31-34 of Viewable slot 0x67 (table 0xea6b06, 71 entries,
; [nakarest] InitializeCheap) ("DiskSave"): PsFileNameBox (58 B), Line (26 B), AcIndexEditSw (40
; [nakarest] B), Label (32 B). text the records point at, in Viewable slot 0x67 (table 0xea6b06,
; [nakarest] 71 entries, InitializeCheap): "SAVE" (Label.str of element 34). widget records,
; [nakarest] elements 35-36 of Viewable slot 0x67 (table 0xea6b06, 71 entries, InitializeCheap)
; [nakarest] ("DiskSave"): AcParaStrBox (44 B), Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x67 (table 0xea6b06, 71 entries, InitializeCheap): "SAVE AS :"
; [nakarest] (Label.str of element 36). widget records, elements 37-38 of Viewable slot 0x67
; [nakarest] (table 0xea6b06, 71 entries, InitializeCheap) ("DiskSave"): AcIndexEditSw (40 B),
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0x67 (table 0xea6b06, 71
; [nakarest] entries, InitializeCheap): "PERFORM" (Label.str of element 38). widget records,
; [nakarest] elements 39-40 of Viewable slot 0x67 (table 0xea6b06, 71 entries, InitializeCheap)
; [nakarest] ("DiskSave"): AcIndexEditSw (40 B), Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x67 (table 0xea6b06, 71 entries, InitializeCheap): "BACKUP"
; [nakarest] (Label.str of element 40). widget records, elements 41-42 of Viewable slot 0x67
; [nakarest] (table 0xea6b06, 71 entries, InitializeCheap) ("DiskSave"): AcIndexEditSw (40 B),
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0x67 (table 0xea6b06, 71
; [nakarest] entries, InitializeCheap): "PNL" (Label.str of element 42). widget records,
; [nakarest] elements 43-45 of Viewable slot 0x67 (table 0xea6b06, 71 entries, InitializeCheap)
; [nakarest] ("DiskSave"): IvCatchEvent (26 B), AcIndexEditSw (40 B), Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0x67 (table 0xea6b06, 71 entries,
; [nakarest] InitializeCheap): "P.MEM" (Label.str of element 45). widget records, elements 46-52
; [nakarest] of Viewable slot 0x67 (table 0xea6b06, 71 entries, InitializeCheap) ("DiskSave"):
; [nakarest] AcIndexEditSw (40 B) x6, Label (32 B). text the records point at, in Viewable slot
; [nakarest] 0x67 (table 0xea6b06, 71 entries, InitializeCheap): "SEQ" (Label.str of element
; [nakarest] 52). widget record, element 53 of Viewable slot 0x67 (table 0xea6b06, 71 entries,
; [nakarest] InitializeCheap) ("DiskSave"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0x67 (table 0xea6b06, 71 entries, InitializeCheap): "COMP" (Label.str of
; [nakarest] element 53). widget record, element 54 of Viewable slot 0x67 (table 0xea6b06, 71
; [nakarest] entries, InitializeCheap) ("DiskSave"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x67 (table 0xea6b06, 71 entries, InitializeCheap): "MSP" (Label.str
; [nakarest] of element 54). widget record, element 55 of Viewable slot 0x67 (table 0xea6b06, 71
; [nakarest] entries, InitializeCheap) ("DiskSave"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x67 (table 0xea6b06, 71 entries, InitializeCheap): "SOUND"
; [nakarest] (Label.str of element 55). widget record, element 56 of Viewable slot 0x67 (table
; [nakarest] 0xea6b06, 71 entries, InitializeCheap) ("DiskSave"): Label (32 B). text the records
; [nakarest] point at, in Viewable slot 0x67 (table 0xea6b06, 71 entries, InitializeCheap):
; [nakarest] "CUSTOM" (Label.str of element 56). widget record, element 57 of Viewable slot 0x67
; [nakarest] (table 0xea6b06, 71 entries, InitializeCheap) ("DiskSave"): Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0x67 (table 0xea6b06, 71 entries,
; [nakarest] InitializeCheap): "MIDI" (Label.str of element 57). widget record, element 58 of
; [nakarest] Viewable slot 0x67 (table 0xea6b06, 71 entries, InitializeCheap) ("DiskSave"):
; [nakarest] VwScreenTitle (38 B). text the records point at, in Viewable slot 0x67 (table
; [nakarest] 0xea6b06, 71 entries, InitializeCheap): "SAVE OPTION" (VwScreenTitle.title of
; [nakarest] element 58). widget records, elements 59-60 of Viewable slot 0x67 (table 0xea6b06,
; [nakarest] 71 entries, InitializeCheap) ("DiskSave"): AcIndexEditSw (40 B), Label (32 B). text
; [nakarest] the records point at, in Viewable slot 0x67 (table 0xea6b06, 71 entries,
; [nakarest] InitializeCheap): "ALL OFF" (Label.str of element 60). widget records, elements
; [nakarest] 61-66 of Viewable slot 0x67 (table 0xea6b06, 71 entries, InitializeCheap)
; [nakarest] ("DiskSave"): Window (36 B), PsFileNameBox (58 B), AcIndexWideES (42 B),
; [nakarest] AcIndexEditSw (40 B), AcParaStrBox (44 B), Label (32 B). text the records point at,
; [nakarest] in Viewable slot 0x67 (table 0xea6b06, 71 entries, InitializeCheap): "SAVE"
; [nakarest] (Label.str of element 66). widget record, element 67 of Viewable slot 0x67 (table
; [nakarest] 0xea6b06, 71 entries, InitializeCheap) ("DiskSave"): Label (32 B). text the records
; [nakarest] point at, in Viewable slot 0x67 (table 0xea6b06, 71 entries, InitializeCheap): "
; [nakarest] AS:" (Label.str of element 67). widget record, element 68 of Viewable slot 0x67
; [nakarest] (table 0xea6b06, 71 entries, InitializeCheap) ("DiskSave"): Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0x67 (table 0xea6b06, 71 entries,
; [nakarest] InitializeCheap): "SAVE" (Label.str of element 68). widget record, element 69 of
; [nakarest] Viewable slot 0x67 (table 0xea6b06, 71 entries, InitializeCheap) ("DiskSave"):
; [nakarest] VwScreenTitle (38 B). text the records point at, in Viewable slot 0x67 (table
; [nakarest] 0xea6b06, 71 entries, InitializeCheap): "SEQUENCER SONG SAVE" (VwScreenTitle.title
; [nakarest] of element 69). widget record, element 70 of Viewable slot 0x67 (table 0xea6b06, 71
; [nakarest] entries, InitializeCheap) ("DiskSave"): IvCatchEvent (26 B).
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x235A, 0xB06
; [nakarest] naka_disk_menu_file_io+0x2e60  +0x2e60..+0x322e (0xea422c, 974 B)
; [nakarest] widget record, element 0 of Viewable slot 0x6b (table 0xea6c2a, 21 entries,
; [nakarest] InitializeCheap) ("DiskSmfSave"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0x6b (table 0xea6c2a, 21 entries, InitializeCheap): "SMF SAVE"
; [nakarest] (TtlScreen.title of element 0). widget records, elements 1-4 of Viewable slot 0x6b
; [nakarest] (table 0xea6c2a, 21 entries, InitializeCheap) ("DiskSmfSave"): PsFileNameBox (58
; [nakarest] B), AcIndexWideES (42 B), AcIndexEditSw (40 B), Label (32 B). text the records
; [nakarest] point at, in Viewable slot 0x6b (table 0xea6c2a, 21 entries, InitializeCheap):
; [nakarest] "PREV" (Label.str of element 4). widget records, elements 5-6 of Viewable slot 0x6b
; [nakarest] (table 0xea6c2a, 21 entries, InitializeCheap) ("DiskSmfSave"): AcIndexEditSw (40
; [nakarest] B), Label (32 B). text the records point at, in Viewable slot 0x6b (table 0xea6c2a,
; [nakarest] 21 entries, InitializeCheap): "NEXT" (Label.str of element 6). widget record,
; [nakarest] element 7 of Viewable slot 0x6b (table 0xea6c2a, 21 entries, InitializeCheap)
; [nakarest] ("DiskSmfSave"): AcMonoIndexToggle (42 B). text the records point at, in Viewable
; [nakarest] slot 0x6b (table 0xea6c2a, 21 entries, InitializeCheap): "OFF"
; [nakarest] (AcMonoIndexToggle.stroff of element 7); "ON" (AcMonoIndexToggle.stron of element
; [nakarest] 7). widget record, element 8 of Viewable slot 0x6b (table 0xea6c2a, 21 entries,
; [nakarest] InitializeCheap) ("DiskSmfSave"): AcMonoIndexToggle (42 B). text the records point
; [nakarest] at, in Viewable slot 0x6b (table 0xea6c2a, 21 entries, InitializeCheap): "OFF"
; [nakarest] (AcMonoIndexToggle.stroff of element 8); "ON" (AcMonoIndexToggle.stron of element
; [nakarest] 8). widget record, element 9 of Viewable slot 0x6b (table 0xea6c2a, 21 entries,
; [nakarest] InitializeCheap) ("DiskSmfSave"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x6b (table 0xea6c2a, 21 entries, InitializeCheap): "PANEL HEADER"
; [nakarest] (Label.str of element 9). widget record, element 10 of Viewable slot 0x6b (table
; [nakarest] 0xea6c2a, 21 entries, InitializeCheap) ("DiskSmfSave"): AcTitleMenu (54 B). text
; [nakarest] the records point at, in Viewable slot 0x6b (table 0xea6c2a, 21 entries,
; [nakarest] InitializeCheap): "NAME" (AcTitleMenu.str of element 10). widget records, elements
; [nakarest] 11-13 of Viewable slot 0x6b (table 0xea6c2a, 21 entries, InitializeCheap)
; [nakarest] ("DiskSmfSave"): AcParaStrBox (44 B), AcIndexEditSw (40 B), Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0x6b (table 0xea6c2a, 21 entries,
; [nakarest] InitializeCheap): "SAVE" (Label.str of element 13). widget record, element 14 of
; [nakarest] Viewable slot 0x6b (table 0xea6c2a, 21 entries, InitializeCheap) ("DiskSmfSave"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0x6b (table 0xea6c2a, 21
; [nakarest] entries, InitializeCheap): "1 MEASURE SPACE" (Label.str of element 14). widget
; [nakarest] records, elements 15-19 of Viewable slot 0x6b (table 0xea6c2a, 21 entries,
; [nakarest] InitializeCheap) ("DiskSmfSave"): PsFileNameBox (58 B) x3, AcIndexEditSw (40 B),
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0x6b (table 0xea6c2a, 21
; [nakarest] entries, InitializeCheap): "SAVE" (Label.str of element 19). widget record, element
; [nakarest] 20 of Viewable slot 0x6b (table 0xea6c2a, 21 entries, InitializeCheap)
; [nakarest] ("DiskSmfSave"): Label (32 B). text the records point at, in Viewable slot 0x6b
; [nakarest] (table 0xea6c2a, 21 entries, InitializeCheap): " AS:" (Label.str of element 20).
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2E60, 0x3CE
; [nakarest] naka_disk_menu_file_io+0x322e  +0x322e..+0x3f20 (0xea45fa, 3314 B)
; [nakarest] widget record, element 0 of Viewable slot 0x6c (table 0xea6c82, 83 entries,
; [nakarest] InitializeCheap) ("DiskSmfDirectPlay"): TtlScreen (42 B). text the records point
; [nakarest] at, in Viewable slot 0x6c (table 0xea6c82, 83 entries, InitializeCheap): "SMF
; [nakarest] DIRECT PLAY" (TtlScreen.title of element 0). widget records, elements 1-5 of
; [nakarest] Viewable slot 0x6c (table 0xea6c82, 83 entries, InitializeCheap)
; [nakarest] ("DiskSmfDirectPlay"): PsFileNameBox (58 B) x2, AcIndexWideES (42 B), AcIndexEditSw
; [nakarest] (40 B), Label (32 B). text the records point at, in Viewable slot 0x6c (table
; [nakarest] 0xea6c82, 83 entries, InitializeCheap): "PREV" (Label.str of element 5). widget
; [nakarest] records, elements 6-7 of Viewable slot 0x6c (table 0xea6c82, 83 entries,
; [nakarest] InitializeCheap) ("DiskSmfDirectPlay"): AcIndexEditSw (40 B), Label (32 B). text
; [nakarest] the records point at, in Viewable slot 0x6c (table 0xea6c82, 83 entries,
; [nakarest] InitializeCheap): "NEXT" (Label.str of element 7). widget record, element 8 of
; [nakarest] Viewable slot 0x6c (table 0xea6c82, 83 entries, InitializeCheap)
; [nakarest] ("DiskSmfDirectPlay"): Label (32 B). text the records point at, in Viewable slot
; [nakarest] 0x6c (table 0xea6c82, 83 entries, InitializeCheap): "INFO" (Label.str of element
; [nakarest] 8). widget record, element 9 of Viewable slot 0x6c (table 0xea6c82, 83 entries,
; [nakarest] InitializeCheap) ("DiskSmfDirectPlay"): PsWindowToggle (52 B). text the records
; [nakarest] point at, in Viewable slot 0x6c (table 0xea6c82, 83 entries, InitializeCheap):
; [nakarest] "DISK" (PsWindowToggle.stroff of element 9); "SONG" (PsWindowToggle.stron of
; [nakarest] element 9). widget records, elements 10-12 of Viewable slot 0x6c (table 0xea6c82,
; [nakarest] 83 entries, InitializeCheap) ("DiskSmfDirectPlay"): AcIndexEditSw (40 B) x2,
; [nakarest] AcMonoIndexToggle (42 B). text the records point at, in Viewable slot 0x6c (table
; [nakarest] 0xea6c82, 83 entries, InitializeCheap): "OFF" (AcMonoIndexToggle.stroff of element
; [nakarest] 12); "ON" (AcMonoIndexToggle.stron of element 12). widget record, element 13 of
; [nakarest] Viewable slot 0x6c (table 0xea6c82, 83 entries, InitializeCheap)
; [nakarest] ("DiskSmfDirectPlay"): AcMonoIndexToggle (42 B). text the records point at, in
; [nakarest] Viewable slot 0x6c (table 0xea6c82, 83 entries, InitializeCheap): "TECH"
; [nakarest] (AcMonoIndexToggle.stroff of element 13); "GM" (AcMonoIndexToggle.stron of element
; [nakarest] 13). widget record, element 14 of Viewable slot 0x6c (table 0xea6c82, 83 entries,
; [nakarest] InitializeCheap) ("DiskSmfDirectPlay"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x6c (table 0xea6c82, 83 entries, InitializeCheap): "PLAY AS"
; [nakarest] (Label.str of element 14). widget records, elements 15-19 of Viewable slot 0x6c
; [nakarest] (table 0xea6c82, 83 entries, InitializeCheap) ("DiskSmfDirectPlay"): Line (26 B)
; [nakarest] x4, Label (32 B). text the records point at, in Viewable slot 0x6c (table 0xea6c82,
; [nakarest] 83 entries, InitializeCheap): "LOOP" (Label.str of element 19). widget record,
; [nakarest] element 20 of Viewable slot 0x6c (table 0xea6c82, 83 entries, InitializeCheap)
; [nakarest] ("DiskSmfDirectPlay"): Label (32 B). text the records point at, in Viewable slot
; [nakarest] 0x6c (table 0xea6c82, 83 entries, InitializeCheap): "MEDLEY" (Label.str of element
; [nakarest] 20). widget records, elements 21-22 of Viewable slot 0x6c (table 0xea6c82, 83
; [nakarest] entries, InitializeCheap) ("DiskSmfDirectPlay"): IvOneShotTimer (26 B), Label (32
; [nakarest] B). text the records point at, in Viewable slot 0x6c (table 0xea6c82, 83 entries,
; [nakarest] InitializeCheap): "ALL" (Label.str of element 22). widget record, element 23 of
; [nakarest] Viewable slot 0x6c (table 0xea6c82, 83 entries, InitializeCheap)
; [nakarest] ("DiskSmfDirectPlay"): Label (32 B). text the records point at, in Viewable slot
; [nakarest] 0x6c (table 0xea6c82, 83 entries, InitializeCheap): "ADD" (Label.str of element
; [nakarest] 23). widget record, element 24 of Viewable slot 0x6c (table 0xea6c82, 83 entries,
; [nakarest] InitializeCheap) ("DiskSmfDirectPlay"): AcMonoIndexToggle (42 B). text the records
; [nakarest] point at, in Viewable slot 0x6c (table 0xea6c82, 83 entries, InitializeCheap):
; [nakarest] "OFF" (AcMonoIndexToggle.stroff of element 24); "ON" (AcMonoIndexToggle.stron of
; [nakarest] element 24). widget record, element 25 of Viewable slot 0x6c (table 0xea6c82, 83
; [nakarest] entries, InitializeCheap) ("DiskSmfDirectPlay"): Label (32 B). text the records
; [nakarest] point at, in Viewable slot 0x6c (table 0xea6c82, 83 entries, InitializeCheap):
; [nakarest] "MIDI OUT" (Label.str of element 25). widget records, elements 26-31 of Viewable
; [nakarest] slot 0x6c (table 0xea6c82, 83 entries, InitializeCheap) ("DiskSmfDirectPlay"):
; [nakarest] IvIndexSwDelay (30 B), AcIndexEditSw (40 B) x2, Window (36 B), AcParaStrBox (44 B),
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0x6c (table 0xea6c82, 83
; [nakarest] entries, InitializeCheap): "START" (Label.str of element 31). widget records,
; [nakarest] elements 32-33 of Viewable slot 0x6c (table 0xea6c82, 83 entries, InitializeCheap)
; [nakarest] ("DiskSmfDirectPlay"): Window (36 B), Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x6c (table 0xea6c82, 83 entries, InitializeCheap): "DISK NAME:"
; [nakarest] (Label.str of element 33). widget records, elements 34-37 of Viewable slot 0x6c
; [nakarest] (table 0xea6c82, 83 entries, InitializeCheap) ("DiskSmfDirectPlay"): AcParaStrBox
; [nakarest] (44 B) x2, AcIndexEditSw (40 B), Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x6c (table 0xea6c82, 83 entries, InitializeCheap): "START"
; [nakarest] (Label.str of element 37). widget record, element 38 of Viewable slot 0x6c (table
; [nakarest] 0xea6c82, 83 entries, InitializeCheap) ("DiskSmfDirectPlay"): TtlScreen (42 B).
; [nakarest] text the records point at, in Viewable slot 0x6c (table 0xea6c82, 83 entries,
; [nakarest] InitializeCheap): "DOC DIRECT PLAY" (TtlScreen.title of element 38). widget
; [nakarest] records, elements 39-42 of Viewable slot 0x6c (table 0xea6c82, 83 entries,
; [nakarest] InitializeCheap) ("DiskSmfDirectPlay"): PsFileNameBox (58 B) x2, AcIndexEditSw (40
; [nakarest] B), Label (32 B). text the records point at, in Viewable slot 0x6c (table 0xea6c82,
; [nakarest] 83 entries, InitializeCheap): "PREV" (Label.str of element 42). widget records,
; [nakarest] elements 43-45 of Viewable slot 0x6c (table 0xea6c82, 83 entries, InitializeCheap)
; [nakarest] ("DiskSmfDirectPlay"): AcIndexWideES (42 B), AcIndexEditSw (40 B), Label (32 B).
; [nakarest] text the records point at, in Viewable slot 0x6c (table 0xea6c82, 83 entries,
; [nakarest] InitializeCheap): "NEXT" (Label.str of element 45). widget record, element 46 of
; [nakarest] Viewable slot 0x6c (table 0xea6c82, 83 entries, InitializeCheap)
; [nakarest] ("DiskSmfDirectPlay"): Label (32 B). text the records point at, in Viewable slot
; [nakarest] 0x6c (table 0xea6c82, 83 entries, InitializeCheap): "MEDLEY" (Label.str of element
; [nakarest] 46). widget records, elements 47-54 of Viewable slot 0x6c (table 0xea6c82, 83
; [nakarest] entries, InitializeCheap) ("DiskSmfDirectPlay"): IvOneShotTimer (26 B), Line (26 B)
; [nakarest] x4, AcIndexEditSw (40 B) x2, Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0x6c (table 0xea6c82, 83 entries, InitializeCheap): "LOOP" (Label.str of
; [nakarest] element 54). widget record, element 55 of Viewable slot 0x6c (table 0xea6c82, 83
; [nakarest] entries, InitializeCheap) ("DiskSmfDirectPlay"): AcMonoIndexToggle (42 B). text the
; [nakarest] records point at, in Viewable slot 0x6c (table 0xea6c82, 83 entries,
; [nakarest] InitializeCheap): "OFF" (AcMonoIndexToggle.stroff of element 55); "ON"
; [nakarest] (AcMonoIndexToggle.stron of element 55). widget records, elements 56-58 of Viewable
; [nakarest] slot 0x6c (table 0xea6c82, 83 entries, InitializeCheap) ("DiskSmfDirectPlay"):
; [nakarest] AcParaStrBox (44 B), AcIndexEditSw (40 B), Label (32 B). text the records point at,
; [nakarest] in Viewable slot 0x6c (table 0xea6c82, 83 entries, InitializeCheap): "START"
; [nakarest] (Label.str of element 58). widget record, element 59 of Viewable slot 0x6c (table
; [nakarest] 0xea6c82, 83 entries, InitializeCheap) ("DiskSmfDirectPlay"): Label (32 B). text
; [nakarest] the records point at, in Viewable slot 0x6c (table 0xea6c82, 83 entries,
; [nakarest] InitializeCheap): "ALL" (Label.str of element 59). widget record, element 60 of
; [nakarest] Viewable slot 0x6c (table 0xea6c82, 83 entries, InitializeCheap)
; [nakarest] ("DiskSmfDirectPlay"): Label (32 B). text the records point at, in Viewable slot
; [nakarest] 0x6c (table 0xea6c82, 83 entries, InitializeCheap): "ADD" (Label.str of element
; [nakarest] 60). widget record, element 61 of Viewable slot 0x6c (table 0xea6c82, 83 entries,
; [nakarest] InitializeCheap) ("DiskSmfDirectPlay"): TtlScreen (42 B). text the records point
; [nakarest] at, in Viewable slot 0x6c (table 0xea6c82, 83 entries, InitializeCheap): "PIANO
; [nakarest] DISC DIRECT PLAY" (TtlScreen.title of element 61). widget records, elements 62-66
; [nakarest] of Viewable slot 0x6c (table 0xea6c82, 83 entries, InitializeCheap)
; [nakarest] ("DiskSmfDirectPlay"): PsFileNameBox (58 B) x2, AcIndexWideES (42 B), AcIndexEditSw
; [nakarest] (40 B), Label (32 B). text the records point at, in Viewable slot 0x6c (table
; [nakarest] 0xea6c82, 83 entries, InitializeCheap): "PREV" (Label.str of element 66). widget
; [nakarest] records, elements 67-68 of Viewable slot 0x6c (table 0xea6c82, 83 entries,
; [nakarest] InitializeCheap) ("DiskSmfDirectPlay"): AcIndexEditSw (40 B), Label (32 B). text
; [nakarest] the records point at, in Viewable slot 0x6c (table 0xea6c82, 83 entries,
; [nakarest] InitializeCheap): "NEXT" (Label.str of element 68). widget records, elements 69-72
; [nakarest] of Viewable slot 0x6c (table 0xea6c82, 83 entries, InitializeCheap)
; [nakarest] ("DiskSmfDirectPlay"): AcIndexEditSw (40 B) x2, IvOneShotTimer (26 B),
; [nakarest] AcMonoIndexToggle (42 B). text the records point at, in Viewable slot 0x6c (table
; [nakarest] 0xea6c82, 83 entries, InitializeCheap): "OFF" (AcMonoIndexToggle.stroff of element
; [nakarest] 72); "ON" (AcMonoIndexToggle.stron of element 72). widget record, element 73 of
; [nakarest] Viewable slot 0x6c (table 0xea6c82, 83 entries, InitializeCheap)
; [nakarest] ("DiskSmfDirectPlay"): Label (32 B). text the records point at, in Viewable slot
; [nakarest] 0x6c (table 0xea6c82, 83 entries, InitializeCheap): "LOOP" (Label.str of element
; [nakarest] 73). widget records, elements 74-75 of Viewable slot 0x6c (table 0xea6c82, 83
; [nakarest] entries, InitializeCheap) ("DiskSmfDirectPlay"): AcIndexEditSw (40 B), Label (32
; [nakarest] B). text the records point at, in Viewable slot 0x6c (table 0xea6c82, 83 entries,
; [nakarest] InitializeCheap): "START" (Label.str of element 75). widget record, element 76 of
; [nakarest] Viewable slot 0x6c (table 0xea6c82, 83 entries, InitializeCheap)
; [nakarest] ("DiskSmfDirectPlay"): Label (32 B). text the records point at, in Viewable slot
; [nakarest] 0x6c (table 0xea6c82, 83 entries, InitializeCheap): "MEDLEY" (Label.str of element
; [nakarest] 76). widget records, elements 77-81 of Viewable slot 0x6c (table 0xea6c82, 83
; [nakarest] entries, InitializeCheap) ("DiskSmfDirectPlay"): Line (26 B) x4, Label (32 B). text
; [nakarest] the records point at, in Viewable slot 0x6c (table 0xea6c82, 83 entries,
; [nakarest] InitializeCheap): "ALL" (Label.str of element 81). widget record, element 82 of
; [nakarest] Viewable slot 0x6c (table 0xea6c82, 83 entries, InitializeCheap)
; [nakarest] ("DiskSmfDirectPlay"): Label (32 B). text the records point at, in Viewable slot
; [nakarest] 0x6c (table 0xea6c82, 83 entries, InitializeCheap): "ADD" (Label.str of element
; [nakarest] 82).
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x322E, 0xCF2
; [nakarest] naka_disk_menu_file_io+0x3f20  +0x3f20..+0x42b8 (0xea52ec, 920 B)
; [nakarest] widget record, element 0 of Viewable slot 0x77 (table 0xea6dda, 21 entries,
; [nakarest] InitializeCheap) ("DiskSongMedley"): TtlScreen (42 B). text the records point at,
; [nakarest] in Viewable slot 0x77 (table 0xea6dda, 21 entries, InitializeCheap): "SONG MEDLEY"
; [nakarest] (TtlScreen.title of element 0). widget records, elements 1-7 of Viewable slot 0x77
; [nakarest] (table 0xea6dda, 21 entries, InitializeCheap) ("DiskSongMedley"): AcIndexEditSw (40
; [nakarest] B) x2, AcIndexWideES (42 B), PsFileNameBox (58 B) x3, Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0x77 (table 0xea6dda, 21 entries,
; [nakarest] InitializeCheap): "DISK NAME:" (Label.str of element 7). widget records, elements
; [nakarest] 8-11 of Viewable slot 0x77 (table 0xea6dda, 21 entries, InitializeCheap)
; [nakarest] ("DiskSongMedley"): AcParaStrBox (44 B) x2, AcIndexEditSw (40 B), Label (32 B).
; [nakarest] text the records point at, in Viewable slot 0x77 (table 0xea6dda, 21 entries,
; [nakarest] InitializeCheap): "START" (Label.str of element 11). widget records, elements 12-13
; [nakarest] of Viewable slot 0x77 (table 0xea6dda, 21 entries, InitializeCheap)
; [nakarest] ("DiskSongMedley"): AcIndexEditSw (40 B), Label (32 B). text the records point at,
; [nakarest] in Viewable slot 0x77 (table 0xea6dda, 21 entries, InitializeCheap): "ALL"
; [nakarest] (Label.str of element 13). widget records, elements 14-15 of Viewable slot 0x77
; [nakarest] (table 0xea6dda, 21 entries, InitializeCheap) ("DiskSongMedley"): AcIndexEditSw (40
; [nakarest] B), Label (32 B). text the records point at, in Viewable slot 0x77 (table 0xea6dda,
; [nakarest] 21 entries, InitializeCheap): "ADD" (Label.str of element 15). widget record,
; [nakarest] element 16 of Viewable slot 0x77 (table 0xea6dda, 21 entries, InitializeCheap)
; [nakarest] ("DiskSongMedley"): AcMonoIndexToggle (42 B). text the records point at, in
; [nakarest] Viewable slot 0x77 (table 0xea6dda, 21 entries, InitializeCheap): "OFF"
; [nakarest] (AcMonoIndexToggle.stroff of element 16); "ON" (AcMonoIndexToggle.stron of element
; [nakarest] 16). widget record, element 17 of Viewable slot 0x77 (table 0xea6dda, 21 entries,
; [nakarest] InitializeCheap) ("DiskSongMedley"): AcMonoIndexToggle (42 B). text the records
; [nakarest] point at, in Viewable slot 0x77 (table 0xea6dda, 21 entries, InitializeCheap):
; [nakarest] "1SONG" (AcMonoIndexToggle.stroff of element 17); "10SNGS" (AcMonoIndexToggle.stron
; [nakarest] of element 17). widget record, element 18 of Viewable slot 0x77 (table 0xea6dda, 21
; [nakarest] entries, InitializeCheap) ("DiskSongMedley"): Label (32 B). text the records point
; [nakarest] at, in Viewable slot 0x77 (table 0xea6dda, 21 entries, InitializeCheap): "MODE"
; [nakarest] (Label.str of element 18). widget records, elements 19-20 of Viewable slot 0x77
; [nakarest] (table 0xea6dda, 21 entries, InitializeCheap) ("DiskSongMedley"): IvShowHide (26
; [nakarest] B), Label (32 B). text the records point at, in Viewable slot 0x77 (table 0xea6dda,
; [nakarest] 21 entries, InitializeCheap): "LOOP" (Label.str of element 20).
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3F20, 0x398
; [nakarest] naka_disk_menu_file_io+0x42b8  +0x42b8..+0x5250 (0xea5684, 3992 B)
; [nakarest] widget record, element 0 of Viewable slot 0x7b (table 0xea6e36, 94 entries,
; [nakarest] InitializeCheap) ("DiskUtility"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0x7b (table 0xea6e36, 94 entries, InitializeCheap): "DISK TOOLS"
; [nakarest] (TtlScreen.title of element 0). widget records, elements 1-4 of Viewable slot 0x7b
; [nakarest] (table 0xea6e36, 94 entries, InitializeCheap) ("DiskUtility"): AcIndexWideES (42
; [nakarest] B), AcIndexEditSw (40 B) x2, AcTitleMenu (54 B). text the records point at, in
; [nakarest] Viewable slot 0x7b (table 0xea6e36, 94 entries, InitializeCheap): "SMF"
; [nakarest] (AcTitleMenu.str of element 4). widget record, element 5 of Viewable slot 0x7b
; [nakarest] (table 0xea6e36, 94 entries, InitializeCheap) ("DiskUtility"): Label (32 B). text
; [nakarest] the records point at, in Viewable slot 0x7b (table 0xea6e36, 94 entries,
; [nakarest] InitializeCheap): "DISK NAME:" (Label.str of element 5). widget records, elements
; [nakarest] 6-8 of Viewable slot 0x7b (table 0xea6e36, 94 entries, InitializeCheap)
; [nakarest] ("DiskUtility"): AcIndexEditSw (40 B) x2, Label (32 B). text the records point at,
; [nakarest] in Viewable slot 0x7b (table 0xea6e36, 94 entries, InitializeCheap): "DEL"
; [nakarest] (Label.str of element 8). widget record, element 9 of Viewable slot 0x7b (table
; [nakarest] 0xea6e36, 94 entries, InitializeCheap) ("DiskUtility"): Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0x7b (table 0xea6e36, 94 entries,
; [nakarest] InitializeCheap): "MOVE" (Label.str of element 9). widget record, element 10 of
; [nakarest] Viewable slot 0x7b (table 0xea6e36, 94 entries, InitializeCheap) ("DiskUtility"):
; [nakarest] AcTitleMenu (54 B). text the records point at, in Viewable slot 0x7b (table
; [nakarest] 0xea6e36, 94 entries, InitializeCheap): "" (AcTitleMenu.str of element 10). widget
; [nakarest] record, element 11 of Viewable slot 0x7b (table 0xea6e36, 94 entries,
; [nakarest] InitializeCheap) ("DiskUtility"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x7b (table 0xea6e36, 94 entries, InitializeCheap): "FORMAT"
; [nakarest] (Label.str of element 11). widget record, element 12 of Viewable slot 0x7b (table
; [nakarest] 0xea6e36, 94 entries, InitializeCheap) ("DiskUtility"): AcScreenMenu (54 B). text
; [nakarest] the records point at, in Viewable slot 0x7b (table 0xea6e36, 94 entries,
; [nakarest] InitializeCheap): "" (AcScreenMenu.str of element 12). widget record, element 13 of
; [nakarest] Viewable slot 0x7b (table 0xea6e36, 94 entries, InitializeCheap) ("DiskUtility"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0x7b (table 0xea6e36, 94
; [nakarest] entries, InitializeCheap): "RENAME" (Label.str of element 13). widget records,
; [nakarest] elements 14-15 of Viewable slot 0x7b (table 0xea6e36, 94 entries, InitializeCheap)
; [nakarest] ("DiskUtility"): AcIndexEditSw (40 B), AcScreenMenu (54 B). text the records point
; [nakarest] at, in Viewable slot 0x7b (table 0xea6e36, 94 entries, InitializeCheap): "COPY"
; [nakarest] (AcScreenMenu.str of element 15). widget records, elements 16-21 of Viewable slot
; [nakarest] 0x7b (table 0xea6e36, 94 entries, InitializeCheap) ("DiskUtility"): AcParaStrBox
; [nakarest] (44 B) x2, PsFileNameBox (58 B), IvWaitWinCtl (26 B), Screen (34 B), VwScreenTitle
; [nakarest] (38 B). text the records point at, in Viewable slot 0x7b (table 0xea6e36, 94
; [nakarest] entries, InitializeCheap): "FILE RENAME" (VwScreenTitle.title of element 21).
; [nakarest] widget records, elements 22-24 of Viewable slot 0x7b (table 0xea6e36, 94 entries,
; [nakarest] InitializeCheap) ("DiskUtility"): IvNaming (26 B), AcFuncEditSw (44 B), TtlScreen
; [nakarest] (42 B). text the records point at, in Viewable slot 0x7b (table 0xea6e36, 94
; [nakarest] entries, InitializeCheap): "FLOPPY DISK FORMAT" (TtlScreen.title of element 24).
; [nakarest] widget record, element 25 of Viewable slot 0x7b (table 0xea6e36, 94 entries,
; [nakarest] InitializeCheap) ("DiskUtility"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0x7b (table 0xea6e36, 94 entries, InitializeCheap): "SMF DISK TOOLS"
; [nakarest] (TtlScreen.title of element 25). widget record, element 26 of Viewable slot 0x7b
; [nakarest] (table 0xea6e36, 94 entries, InitializeCheap) ("DiskUtility"): AcTitleMenu (54 B).
; [nakarest] text the records point at, in Viewable slot 0x7b (table 0xea6e36, 94 entries,
; [nakarest] InitializeCheap): "TECH" (AcTitleMenu.str of element 26). widget records, elements
; [nakarest] 27-28 of Viewable slot 0x7b (table 0xea6e36, 94 entries, InitializeCheap)
; [nakarest] ("DiskUtility"): AcIndexEditSw (40 B), Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x7b (table 0xea6e36, 94 entries, InitializeCheap): "PREV" (Label.str
; [nakarest] of element 28). widget records, elements 29-31 of Viewable slot 0x7b (table
; [nakarest] 0xea6e36, 94 entries, InitializeCheap) ("DiskUtility"): AcIndexWideES (42 B),
; [nakarest] AcIndexEditSw (40 B), Label (32 B). text the records point at, in Viewable slot
; [nakarest] 0x7b (table 0xea6e36, 94 entries, InitializeCheap): "NEXT" (Label.str of element
; [nakarest] 31). widget record, element 32 of Viewable slot 0x7b (table 0xea6e36, 94 entries,
; [nakarest] InitializeCheap) ("DiskUtility"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x7b (table 0xea6e36, 94 entries, InitializeCheap): "INFO" (Label.str
; [nakarest] of element 32). widget records, elements 33-34 of Viewable slot 0x7b (table
; [nakarest] 0xea6e36, 94 entries, InitializeCheap) ("DiskUtility"): PsFileNameBox (58 B),
; [nakarest] PsWindowToggle (52 B). text the records point at, in Viewable slot 0x7b (table
; [nakarest] 0xea6e36, 94 entries, InitializeCheap): "DISK" (PsWindowToggle.stroff of element
; [nakarest] 34); "SONG" (PsWindowToggle.stron of element 34). widget record, element 35 of
; [nakarest] Viewable slot 0x7b (table 0xea6e36, 94 entries, InitializeCheap) ("DiskUtility"):
; [nakarest] AcTitleMenu (54 B). text the records point at, in Viewable slot 0x7b (table
; [nakarest] 0xea6e36, 94 entries, InitializeCheap): "" (AcTitleMenu.str of element 35). widget
; [nakarest] record, element 36 of Viewable slot 0x7b (table 0xea6e36, 94 entries,
; [nakarest] InitializeCheap) ("DiskUtility"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x7b (table 0xea6e36, 94 entries, InitializeCheap): "FORMAT"
; [nakarest] (Label.str of element 36). widget records, elements 37-38 of Viewable slot 0x7b
; [nakarest] (table 0xea6e36, 94 entries, InitializeCheap) ("DiskUtility"): AcIndexEditSw (40
; [nakarest] B), Label (32 B). text the records point at, in Viewable slot 0x7b (table 0xea6e36,
; [nakarest] 94 entries, InitializeCheap): "DEL" (Label.str of element 38). widget record,
; [nakarest] element 39 of Viewable slot 0x7b (table 0xea6e36, 94 entries, InitializeCheap)
; [nakarest] ("DiskUtility"): AcScreenMenu (54 B). text the records point at, in Viewable slot
; [nakarest] 0x7b (table 0xea6e36, 94 entries, InitializeCheap): "" (AcScreenMenu.str of element
; [nakarest] 39). widget record, element 40 of Viewable slot 0x7b (table 0xea6e36, 94 entries,
; [nakarest] InitializeCheap) ("DiskUtility"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x7b (table 0xea6e36, 94 entries, InitializeCheap): "RENAME"
; [nakarest] (Label.str of element 40). widget records, elements 41-44 of Viewable slot 0x7b
; [nakarest] (table 0xea6e36, 94 entries, InitializeCheap) ("DiskUtility"): IvIndexSwDelay (30
; [nakarest] B), IvWaitWinCtl (26 B), Window (36 B), Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x7b (table 0xea6e36, 94 entries, InitializeCheap): "DISK NAME:"
; [nakarest] (Label.str of element 44). widget records, elements 45-53 of Viewable slot 0x7b
; [nakarest] (table 0xea6e36, 94 entries, InitializeCheap) ("DiskUtility"): AcParaStrBox (44 B)
; [nakarest] x3, Window (36 B) x2, IvNaming (26 B), AcFuncEditSw (44 B), IvMainEditSw (26 B),
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0x7b (table 0xea6e36, 94
; [nakarest] entries, InitializeCheap): "DISK NAMING" (Label.str of element 53). widget records,
; [nakarest] elements 54-60 of Viewable slot 0x7b (table 0xea6e36, 94 entries, InitializeCheap)
; [nakarest] ("DiskUtility"): Window (36 B), VwBox (28 B), AcLanguageText (42 B) x3, Line (26
; [nakarest] B), VwEditSwBox (44 B). text the records point at, in Viewable slot 0x7b (table
; [nakarest] 0xea6e36, 94 entries, InitializeCheap): "" (VwEditSwBox.str of element 60). widget
; [nakarest] record, element 61 of Viewable slot 0x7b (table 0xea6e36, 94 entries,
; [nakarest] InitializeCheap) ("DiskUtility"): VwEditSwBox (44 B). text the records point at, in
; [nakarest] Viewable slot 0x7b (table 0xea6e36, 94 entries, InitializeCheap): ""
; [nakarest] (VwEditSwBox.str of element 61). widget records, elements 62-65 of Viewable slot
; [nakarest] 0x7b (table 0xea6e36, 94 entries, InitializeCheap) ("DiskUtility"): IvMainEditSw
; [nakarest] (26 B) x2, Window (36 B), Label (32 B). text the records point at, in Viewable slot
; [nakarest] 0x7b (table 0xea6e36, 94 entries, InitializeCheap): "Select the FORMAT type for
; [nakarest] your disk." (Label.str of element 65). widget record, element 66 of Viewable slot
; [nakarest] 0x7b (table 0xea6e36, 94 entries, InitializeCheap) ("DiskUtility"): VwMenuBox (50
; [nakarest] B). text the records point at, in Viewable slot 0x7b (table 0xea6e36, 94 entries,
; [nakarest] InitializeCheap): " 720K Byte format : 2DD" (VwMenuBox.str of element 66). widget
; [nakarest] record, element 67 of Viewable slot 0x7b (table 0xea6e36, 94 entries,
; [nakarest] InitializeCheap) ("DiskUtility"): VwMenuBox (50 B). text the records point at, in
; [nakarest] Viewable slot 0x7b (table 0xea6e36, 94 entries, InitializeCheap): " 1.44M Byte
; [nakarest] format : 2HD" (VwMenuBox.str of element 67). widget records, elements 68-69 of
; [nakarest] Viewable slot 0x7b (table 0xea6e36, 94 entries, InitializeCheap) ("DiskUtility"):
; [nakarest] Screen (34 B), VwScreenTitle (38 B). text the records point at, in Viewable slot
; [nakarest] 0x7b (table 0xea6e36, 94 entries, InitializeCheap): "FILE COPY"
; [nakarest] (VwScreenTitle.title of element 69). widget records, elements 70-71 of Viewable
; [nakarest] slot 0x7b (table 0xea6e36, 94 entries, InitializeCheap) ("DiskUtility"): Arrow (32
; [nakarest] B), Label (32 B). text the records point at, in Viewable slot 0x7b (table 0xea6e36,
; [nakarest] 94 entries, InitializeCheap): "TO" (Label.str of element 71). widget records,
; [nakarest] elements 72-73 of Viewable slot 0x7b (table 0xea6e36, 94 entries, InitializeCheap)
; [nakarest] ("DiskUtility"): AcParaStrBox (44 B), Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x7b (table 0xea6e36, 94 entries, InitializeCheap): "FROM" (Label.str
; [nakarest] of element 73). widget records, elements 74-78 of Viewable slot 0x7b (table
; [nakarest] 0xea6e36, 94 entries, InitializeCheap) ("DiskUtility"): AcIndexWideES (42 B),
; [nakarest] AcIndexEditSw (40 B), PsFileNameBox (58 B), Screen (34 B), VwScreenTitle (38 B).
; [nakarest] text the records point at, in Viewable slot 0x7b (table 0xea6e36, 94 entries,
; [nakarest] InitializeCheap): "FILE RENAME" (VwScreenTitle.title of element 78). widget
; [nakarest] records, elements 79-91 of Viewable slot 0x7b (table 0xea6e36, 94 entries,
; [nakarest] InitializeCheap) ("DiskUtility"): IvNaming (26 B), AcFuncEditSw (44 B) x4, Window
; [nakarest] (36 B), VwBox (28 B), AcLanguageText (42 B) x3, Line (26 B), Screen (34 B), Label
; [nakarest] (32 B). text the records point at, in Viewable slot 0x7b (table 0xea6e36, 94
; [nakarest] entries, InitializeCheap): "DELETE SURE" (Label.str of element 91). widget records,
; [nakarest] elements 92-93 of Viewable slot 0x7b (table 0xea6e36, 94 entries, InitializeCheap)
; [nakarest] ("DiskUtility"): Screen (34 B), Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x7b (table 0xea6e36, 94 entries, InitializeCheap): "OVERWRITE SURE"
; [nakarest] (Label.str of element 93).
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x42B8, 0xF98
; [nakarest] naka_disk_menu_file_io+0x5250  +0x5250..+0x53ea (0xea661c, 410 B)
; [nakarest] widget record, element 0 of Viewable slot 0x7e (table 0xea6fba, 8 entries,
; [nakarest] InitializeCheap) ("DiskSetup"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0x7e (table 0xea6fba, 8 entries, InitializeCheap): "PREFERENCES"
; [nakarest] (TtlScreen.title of element 0). widget records, elements 1-2 of Viewable slot 0x7e
; [nakarest] (table 0xea6fba, 8 entries, InitializeCheap) ("DiskSetup"): AcIndexWideES (42 B),
; [nakarest] AcRamEditBox (58 B). text the records point at, in Viewable slot 0x7e (table
; [nakarest] 0xea6fba, 8 entries, InitializeCheap): "DISK INSERT OPTION :" (AcRamEditBox.caption
; [nakarest] of element 2). widget record, element 3 of Viewable slot 0x7e (table 0xea6fba, 8
; [nakarest] entries, InitializeCheap) ("DiskSetup"): AcBitEditBox (58 B). text the records
; [nakarest] point at, in Viewable slot 0x7e (table 0xea6fba, 8 entries, InitializeCheap): "FILE
; [nakarest] TYPE PRIORITY :" (AcBitEditBox.caption of element 3). widget records, elements 4-7
; [nakarest] of Viewable slot 0x7e (table 0xea6fba, 8 entries, InitializeCheap) ("DiskSetup"):
; [nakarest] AcFuncEditSw (44 B), IvCatchEvent (26 B), AcLanguageText (42 B) x2.
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
; [nakarest] purpose not established: 6 bytes at 0xea7428 that no registered NAKA table points into
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
; [nakarest] purpose not established: 2 bytes at 0xea79c8 that no registered NAKA table points into
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
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6B16, 0xEC
; [nakarest] naka_disk_menu_file_io+0x6c02  +0x6c02..+0x6cea (0xea7fce, 232 B)
; [nakarest] the table itself: MainFunction slot 0x145 (table 0xea7fce, 57 entries,
; [nakarest] InitializeCheap), 57 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6C02, 0xE8
; [nakarest] naka_disk_menu_file_io+0x6cea  +0x6cea..+0x6dd4 (0xea80b6, 234 B)
; [nakarest] the table itself: MainFunction slot 0x445 (table 0xea80b6, 57 entries,
; [nakarest] InitializeCheap), 57 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6CEA, 0xEA
; [nakarest] naka_disk_menu_file_io+0x6dd4  +0x6dd4..+0x78e0 (0xea81a0, 2828 B)
; [nakarest] name strings, entries 0-56 of MainFunction slot 0x445 (table 0xea80b6, 57 entries,
; [nakarest] InitializeCheap) (names for MainFunction slot 0x145): "FmmPasswordFunc",
; [nakarest] "FmmWallpaperLoadFunc", "FmmCmpSingleLoadFunc", "CmpSingleLoadDstFunc",
; [nakarest] "CmpSingleLoadSrcFunc", "CmpSingleLoadFileFunc", ....
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6DD4, 0xB0C

; External label offsets within the binary blob above.
