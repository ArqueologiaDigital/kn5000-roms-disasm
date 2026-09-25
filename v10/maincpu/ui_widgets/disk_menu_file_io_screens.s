
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
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_IvWaitWinCtlProc
; NakaInst_IvWaitWinCtlProc  --  naka_disk_menu_file_io +0x0..+0x12 (ROM 0xea13cc..0xea13de), 18 bytes
; Name strings of element 12 of Function slot 0x405 (table 0xea1392, 13
; entries, InitializeCheap), names for Function slot 0x105:
; "IvWaitWinCtlProc".
; -----------------------------------------------------------------------------
NakaInst_IvWaitWinCtlProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x0, 0x12
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_IvIndexSwDelayProc
; NakaInst_IvIndexSwDelayProc  --  naka_disk_menu_file_io +0x12..+0x26 (ROM 0xea13de..0xea13f2), 20 bytes
; Name strings of element 11 of Function slot 0x405 (table 0xea1392, 13
; entries, InitializeCheap), names for Function slot 0x105:
; "IvIndexSwDelayProc".
; -----------------------------------------------------------------------------
NakaInst_IvIndexSwDelayProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x12, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_AcRotStrBoxProc
; NakaInst_AcRotStrBoxProc  --  naka_disk_menu_file_io +0x26..+0x36 (ROM 0xea13f2..0xea1402), 16 bytes
; Name strings of element 10 of Function slot 0x405 (table 0xea1392, 13
; entries, InitializeCheap), names for Function slot 0x105:
; "AcRotStrBoxProc".
; -----------------------------------------------------------------------------
NakaInst_AcRotStrBoxProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x26, 0x10
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_IvIndexSwCtrlProc
; NakaInst_IvIndexSwCtrlProc  --  naka_disk_menu_file_io +0x36..+0x48 (ROM 0xea1402..0xea1414), 18 bytes
; Name strings of element 9 of Function slot 0x405 (table 0xea1392, 13
; entries, InitializeCheap), names for Function slot 0x105:
; "IvIndexSwCtrlProc".
; -----------------------------------------------------------------------------
NakaInst_IvIndexSwCtrlProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x36, 0x12
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_ArrowProc
; NakaInst_ArrowProc  --  naka_disk_menu_file_io +0x48..+0x52 (ROM 0xea1414..0xea141e), 10 bytes
; Name strings of element 8 of Function slot 0x405 (table 0xea1392, 13
; entries, InitializeCheap), names for Function slot 0x105: "ArrowProc".
; -----------------------------------------------------------------------------
NakaInst_ArrowProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x48, 0xA
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_VwScreenTitleProc
; NakaInst_VwScreenTitleProc  --  naka_disk_menu_file_io +0x52..+0x64 (ROM 0xea141e..0xea1430), 18 bytes
; Name strings of element 7 of Function slot 0x405 (table 0xea1392, 13
; entries, InitializeCheap), names for Function slot 0x105:
; "VwScreenTitleProc".
; -----------------------------------------------------------------------------
NakaInst_VwScreenTitleProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x52, 0x12
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_IvOneShotTimerProc
; NakaInst_IvOneShotTimerProc  --  naka_disk_menu_file_io +0x64..+0x78 (ROM 0xea1430..0xea1444), 20 bytes
; Name strings of element 6 of Function slot 0x405 (table 0xea1392, 13
; entries, InitializeCheap), names for Function slot 0x105:
; "IvOneShotTimerProc".
; -----------------------------------------------------------------------------
NakaInst_IvOneShotTimerProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x64, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_AcMonoIndexToggleProc
; NakaInst_AcMonoIndexToggleProc  --  naka_disk_menu_file_io +0x78..+0x8e (ROM 0xea1444..0xea145a), 22 bytes
; Name strings of element 5 of Function slot 0x405 (table 0xea1392, 13
; entries, InitializeCheap), names for Function slot 0x105:
; "AcMonoIndexToggleProc".
; -----------------------------------------------------------------------------
NakaInst_AcMonoIndexToggleProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x78, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_AcFileSfxBoxProc
; NakaInst_AcFileSfxBoxProc  --  naka_disk_menu_file_io +0x8e..+0xa0 (ROM 0xea145a..0xea146c), 18 bytes
; Name strings of element 4 of Function slot 0x405 (table 0xea1392, 13
; entries, InitializeCheap), names for Function slot 0x105:
; "AcFileSfxBoxProc".
; -----------------------------------------------------------------------------
NakaInst_AcFileSfxBoxProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x8E, 0x12
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_AcParaStrBoxProc
; NakaInst_AcParaStrBoxProc  --  naka_disk_menu_file_io +0xa0..+0xb2 (ROM 0xea146c..0xea147e), 18 bytes
; Name strings of element 3 of Function slot 0x405 (table 0xea1392, 13
; entries, InitializeCheap), names for Function slot 0x105:
; "AcParaStrBoxProc".
; -----------------------------------------------------------------------------
NakaInst_AcParaStrBoxProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xA0, 0x12
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_AcTtlJgBoxProc
; NakaInst_AcTtlJgBoxProc  --  naka_disk_menu_file_io +0xb2..+0xc2 (ROM 0xea147e..0xea148e), 16 bytes
; Name strings of element 2 of Function slot 0x405 (table 0xea1392, 13
; entries, InitializeCheap), names for Function slot 0x105:
; "AcTtlJgBoxProc".
; -----------------------------------------------------------------------------
NakaInst_AcTtlJgBoxProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xB2, 0x10
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_PsWindowToggleProc
; NakaInst_PsWindowToggleProc  --  naka_disk_menu_file_io +0xc2..+0xd6 (ROM 0xea148e..0xea14a2), 20 bytes
; Name strings of element 1 of Function slot 0x405 (table 0xea1392, 13
; entries, InitializeCheap), names for Function slot 0x105:
; "PsWindowToggleProc".
; -----------------------------------------------------------------------------
NakaInst_PsWindowToggleProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xC2, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_PsFileNameBoxProc
; NakaInst_PsFileNameBoxProc  --  naka_disk_menu_file_io +0xd6..+0xe8 (ROM 0xea14a2..0xea14b4), 18 bytes
; Name strings of element 0 of Function slot 0x405 (table 0xea1392, 13
; entries, InitializeCheap), names for Function slot 0x105:
; "PsFileNameBoxProc".
; -----------------------------------------------------------------------------
NakaInst_PsFileNameBoxProc:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xD6, 0x12
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0xe8
; naka_disk_menu_file_io+0xe8  --  naka_disk_menu_file_io +0xe8..+0xd76 (ROM 0xea14b4..0xea2142), 3214 bytes
; Widget records of elements 0-1, 3-73 of Viewable slot 0x60 (table
; 0xea67b6, 74 entries, InitializeCheap), element 0 "DiskMenu"; classes:
; TtlScreen (42 B, id 0x01600034) x6, AcTitleMenu (54 B, id 0x0160001d)
; x3, AcTtlJgBox (54 B, id 0x01650002) x4, IvExitMode (26 B, id
; 0x01600048) x2, AcIndexWideES (42 B, id 0x01600022) x3, AcIndexEditSw
; (40 B, id 0x0160001f) x9, PsFileNameBox (58 B, id 0x01650000) x4, Line
; (26 B, id 0x0160002e) x2, AcMonoIndexToggle (42 B, id 0x01650005),
; Label (32 B, id 0x0160002b) x10, IvOneShotTimer (26 B, id 0x01650006),
; AcFuncEditSw (44 B, id 0x01600020) x9, IvNaming (26 B, id 0x0160004d)
; x4, AcParaStrBox (44 B, id 0x01650003) x4, Window (36 B, id
; 0x01600035) x4, AcRotStrBox (48 B, id 0x0165000a), VwBox (28 B, id
; 0x01600011), AcLanguageText (42 B, id 0x01600066) x5.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xE8, 0xC8E
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0xd76
; naka_disk_menu_file_io+0xd76  --  naka_disk_menu_file_io +0xd76..+0x22a0 (ROM 0xea2142..0xea366c), 5418 bytes
; Widget records of elements 0-73, 75-127 of Viewable slot 0x61 (table
; 0xea68e2, 128 entries, InitializeCheap), element 0 "DiskLoad";
; classes: TtlScreen (42 B, id 0x01600034) x3, AcWindowPage (36 B, id
; 0x01600025), IvPageControl (28 B, id 0x01600028) x3, IvExit (22 B, id
; 0x01600047) x2, IvMainEditSw (26 B, id 0x01600029) x2, Window (36 B,
; id 0x01600035) x5, PsFileNameBox (58 B, id 0x01650000) x20,
; AcIndexEditSw (40 B, id 0x0160001f) x24, Label (32 B, id 0x0160002b)
; x33, AcFileSfxBox (34 B, id 0x01650004), AcTitleMenu (54 B, id
; 0x0160001d) x2, AcIndexWideES (42 B, id 0x01600022) x10, AcParaStrBox
; (44 B, id 0x01650003) x7, VwScreenTitle (38 B, id 0x01650007) x3,
; VwBox (28 B, id 0x01600011), Line (26 B, id 0x0160002e), IvIndexSwCtrl
; (32 B, id 0x01650009) x2, IvIndexSwDelay (30 B, id 0x0165000b) x3,
; Arrow (32 B, id 0x01650008) x2, PsWindowToggle (52 B, id 0x01650001),
; AcMonoIndexToggle (42 B, id 0x01650005).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0xD76, 0x152A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x22a0
; naka_disk_menu_file_io+0x22a0  --  naka_disk_menu_file_io +0x22a0..+0x235a (ROM 0xea366c..0xea3726), 186 bytes
; Widget records of elements 0-2 of Viewable slot 0x65 (table 0xea6af2,
; 3 entries, InitializeCheap), element 0 "DiskSaveMenu"; classes:
; TtlScreen (42 B, id 0x01600034), AcTtlJgBox (54 B, id 0x01650002) x2.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x22A0, 0xBA
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x235a
; naka_disk_menu_file_io+0x235a  --  naka_disk_menu_file_io +0x235a..+0x2e60 (ROM 0xea3726..0xea422c), 2822 bytes
; Widget records of elements 0-70 of Viewable slot 0x67 (table 0xea6b06,
; 71 entries, InitializeCheap), element 0 "DiskSave"; classes: TtlScreen
; (42 B, id 0x01600034), AcWindowPage (36 B, id 0x01600025),
; IvPageControl (28 B, id 0x01600028) x3, IvExit (22 B, id 0x01600047),
; IvMainEditSw (26 B, id 0x01600029), Window (36 B, id 0x01600035) x3,
; AcIndexWideES (42 B, id 0x01600022) x2, AcIndexEditSw (40 B, id
; 0x0160001f) x16, AcParaStrBox (44 B, id 0x01650003) x4, Label (32 B,
; id 0x0160002b) x26, AcTitleMenu (54 B, id 0x0160001d), PsFileNameBox
; (58 B, id 0x01650000) x3, AcFileSfxBox (34 B, id 0x01650004),
; IvCatchEvent (26 B, id 0x01600052) x3, VwScreenTitle (38 B, id
; 0x01650007) x3, VwBox (28 B, id 0x01600011), Line (26 B, id
; 0x0160002e).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x235A, 0xB06
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x2e60
; naka_disk_menu_file_io+0x2e60  --  naka_disk_menu_file_io +0x2e60..+0x322e (ROM 0xea422c..0xea45fa), 974 bytes
; Widget records of elements 0-20 of Viewable slot 0x6b (table 0xea6c2a,
; 21 entries, InitializeCheap), element 0 "DiskSmfSave"; classes:
; TtlScreen (42 B, id 0x01600034), PsFileNameBox (58 B, id 0x01650000)
; x4, AcIndexWideES (42 B, id 0x01600022), AcIndexEditSw (40 B, id
; 0x0160001f) x4, Label (32 B, id 0x0160002b) x7, AcMonoIndexToggle (42
; B, id 0x01650005) x2, AcTitleMenu (54 B, id 0x0160001d), AcParaStrBox
; (44 B, id 0x01650003).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x2E60, 0x3CE
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x322e
; naka_disk_menu_file_io+0x322e  --  naka_disk_menu_file_io +0x322e..+0x3f20 (ROM 0xea45fa..0xea52ec), 3314 bytes
; Widget records of elements 0-82 of Viewable slot 0x6c (table 0xea6c82,
; 83 entries, InitializeCheap), element 0 "DiskSmfDirectPlay"; classes:
; TtlScreen (42 B, id 0x01600034) x3, PsFileNameBox (58 B, id
; 0x01650000) x6, AcIndexWideES (42 B, id 0x01600022) x3, AcIndexEditSw
; (40 B, id 0x0160001f) x17, Label (32 B, id 0x0160002b) x26,
; PsWindowToggle (52 B, id 0x01650001), AcMonoIndexToggle (42 B, id
; 0x01650005) x5, Line (26 B, id 0x0160002e) x12, IvOneShotTimer (26 B,
; id 0x01650006) x3, IvIndexSwDelay (30 B, id 0x0165000b), Window (36 B,
; id 0x01600035) x2, AcParaStrBox (44 B, id 0x01650003) x4.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x322E, 0xCF2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x3f20
; naka_disk_menu_file_io+0x3f20  --  naka_disk_menu_file_io +0x3f20..+0x42b8 (ROM 0xea52ec..0xea5684), 920 bytes
; Widget records of elements 0-20 of Viewable slot 0x77 (table 0xea6dda,
; 21 entries, InitializeCheap), element 0 "DiskSongMedley"; classes:
; TtlScreen (42 B, id 0x01600034), AcIndexEditSw (40 B, id 0x0160001f)
; x5, AcIndexWideES (42 B, id 0x01600022), PsFileNameBox (58 B, id
; 0x01650000) x3, Label (32 B, id 0x0160002b) x6, AcParaStrBox (44 B, id
; 0x01650003) x2, AcMonoIndexToggle (42 B, id 0x01650005) x2, IvShowHide
; (26 B, id 0x01600064).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x3F20, 0x398
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x42b8
; naka_disk_menu_file_io+0x42b8  --  naka_disk_menu_file_io +0x42b8..+0x5250 (ROM 0xea5684..0xea661c), 3992 bytes
; Widget records of elements 0-93 of Viewable slot 0x7b (table 0xea6e36,
; 94 entries, InitializeCheap), element 0 "DiskUtility"; classes:
; TtlScreen (42 B, id 0x01600034) x3, AcIndexWideES (42 B, id
; 0x01600022) x3, AcIndexEditSw (40 B, id 0x0160001f) x9, AcTitleMenu
; (54 B, id 0x0160001d) x4, Label (32 B, id 0x0160002b) x18,
; AcScreenMenu (54 B, id 0x01600041) x3, AcParaStrBox (44 B, id
; 0x01650003) x6, PsFileNameBox (58 B, id 0x01650000) x3, IvWaitWinCtl
; (26 B, id 0x0165000c) x2, Screen (34 B, id 0x01600033) x5,
; VwScreenTitle (38 B, id 0x01650007) x3, IvNaming (26 B, id 0x0160004d)
; x3, AcFuncEditSw (44 B, id 0x01600020) x6, PsWindowToggle (52 B, id
; 0x01650001), IvIndexSwDelay (30 B, id 0x0165000b), Window (36 B, id
; 0x01600035) x6, IvMainEditSw (26 B, id 0x01600029) x3, VwBox (28 B, id
; 0x01600011) x2, AcLanguageText (42 B, id 0x01600066) x6, Line (26 B,
; id 0x0160002e) x2, VwEditSwBox (44 B, id 0x0160003e) x2, VwMenuBox (50
; B, id 0x0160003d) x2, Arrow (32 B, id 0x01650008).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x42B8, 0xF98
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x5250
; naka_disk_menu_file_io+0x5250  --  naka_disk_menu_file_io +0x5250..+0x53ea (ROM 0xea661c..0xea67b6), 410 bytes
; Widget records of elements 0-7 of Viewable slot 0x7e (table 0xea6fba,
; 8 entries, InitializeCheap), element 0 "DiskSetup"; classes: TtlScreen
; (42 B, id 0x01600034), AcIndexWideES (42 B, id 0x01600022),
; AcRamEditBox (58 B, id 0x0160001b), AcBitEditBox (58 B, id
; 0x01600043), AcFuncEditSw (44 B, id 0x01600020), IvCatchEvent (26 B,
; id 0x01600052), AcLanguageText (42 B, id 0x01600066) x2.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5250, 0x19A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x53ea
; naka_disk_menu_file_io+0x53ea  --  naka_disk_menu_file_io +0x53ea..+0x5516 (ROM 0xea67b6..0xea68e2), 300 bytes
; The table itself: Viewable slot 0x60 (table 0xea67b6, 74 entries,
; InitializeCheap) -- 74 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x53EA, 0x12C
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x5516
; naka_disk_menu_file_io+0x5516  --  naka_disk_menu_file_io +0x5516..+0x571a (ROM 0xea68e2..0xea6ae6), 516 bytes
; The table itself: Viewable slot 0x61 (table 0xea68e2, 128 entries,
; InitializeCheap) -- 128 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5516, 0x204
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x571a
; naka_disk_menu_file_io+0x571a  --  naka_disk_menu_file_io +0x571a..+0x571e (ROM 0xea6ae6..0xea6aea), 4 bytes
; The table itself: Viewable slot 0x62 (table 0xea6ae6, 0 entries,
; InitializeCheap) -- 0 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x571A, 0x4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x571e
; naka_disk_menu_file_io+0x571e  --  naka_disk_menu_file_io +0x571e..+0x5722 (ROM 0xea6aea..0xea6aee), 4 bytes
; The table itself: Viewable slot 0x63 (table 0xea6aea, 0 entries,
; InitializeCheap) -- 0 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x571E, 0x4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x5722
; naka_disk_menu_file_io+0x5722  --  naka_disk_menu_file_io +0x5722..+0x5726 (ROM 0xea6aee..0xea6af2), 4 bytes
; The table itself: Viewable slot 0x64 (table 0xea6aee, 0 entries,
; InitializeCheap) -- 0 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5722, 0x4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x5726
; naka_disk_menu_file_io+0x5726  --  naka_disk_menu_file_io +0x5726..+0x5736 (ROM 0xea6af2..0xea6b02), 16 bytes
; The table itself: Viewable slot 0x65 (table 0xea6af2, 3 entries,
; InitializeCheap) -- 3 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5726, 0x10
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x5736
; naka_disk_menu_file_io+0x5736  --  naka_disk_menu_file_io +0x5736..+0x573a (ROM 0xea6b02..0xea6b06), 4 bytes
; The table itself: Viewable slot 0x66 (table 0xea6b02, 0 entries,
; InitializeCheap) -- 0 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5736, 0x4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x573a
; naka_disk_menu_file_io+0x573a  --  naka_disk_menu_file_io +0x573a..+0x585a (ROM 0xea6b06..0xea6c26), 288 bytes
; The table itself: Viewable slot 0x67 (table 0xea6b06, 71 entries,
; InitializeCheap) -- 71 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x573A, 0x120
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x585a
; naka_disk_menu_file_io+0x585a  --  naka_disk_menu_file_io +0x585a..+0x585e (ROM 0xea6c26..0xea6c2a), 4 bytes
; The table itself: Viewable slot 0x6a (table 0xea6c26, 0 entries,
; InitializeCheap) -- 0 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x585A, 0x4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x585e
; naka_disk_menu_file_io+0x585e  --  naka_disk_menu_file_io +0x585e..+0x58b6 (ROM 0xea6c2a..0xea6c82), 88 bytes
; The table itself: Viewable slot 0x6b (table 0xea6c2a, 21 entries,
; InitializeCheap) -- 21 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x585E, 0x58
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x58b6
; naka_disk_menu_file_io+0x58b6  --  naka_disk_menu_file_io +0x58b6..+0x5a06 (ROM 0xea6c82..0xea6dd2), 336 bytes
; The table itself: Viewable slot 0x6c (table 0xea6c82, 83 entries,
; InitializeCheap) -- 83 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x58B6, 0x150
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x5a06
; naka_disk_menu_file_io+0x5a06  --  naka_disk_menu_file_io +0x5a06..+0x5a0a (ROM 0xea6dd2..0xea6dd6), 4 bytes
; The table itself: Viewable slot 0x6d (table 0xea6dd2, 0 entries,
; InitializeCheap) -- 0 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5A06, 0x4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x5a0a
; naka_disk_menu_file_io+0x5a0a  --  naka_disk_menu_file_io +0x5a0a..+0x5a0e (ROM 0xea6dd6..0xea6dda), 4 bytes
; The table itself: Viewable slot 0x6e (table 0xea6dd6, 0 entries,
; InitializeCheap) -- 0 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5A0A, 0x4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x5a0e
; naka_disk_menu_file_io+0x5a0e  --  naka_disk_menu_file_io +0x5a0e..+0x5a66 (ROM 0xea6dda..0xea6e32), 88 bytes
; The table itself: Viewable slot 0x77 (table 0xea6dda, 21 entries,
; InitializeCheap) -- 21 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5A0E, 0x58
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x5a66
; naka_disk_menu_file_io+0x5a66  --  naka_disk_menu_file_io +0x5a66..+0x5a6a (ROM 0xea6e32..0xea6e36), 4 bytes
; The table itself: Viewable slot 0x79 (table 0xea6e32, 0 entries,
; InitializeCheap) -- 0 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5A66, 0x4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x5a6a
; naka_disk_menu_file_io+0x5a6a  --  naka_disk_menu_file_io +0x5a6a..+0x5be6 (ROM 0xea6e36..0xea6fb2), 380 bytes
; The table itself: Viewable slot 0x7b (table 0xea6e36, 94 entries,
; InitializeCheap) -- 94 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5A6A, 0x17C
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x5be6
; naka_disk_menu_file_io+0x5be6  --  naka_disk_menu_file_io +0x5be6..+0x5bea (ROM 0xea6fb2..0xea6fb6), 4 bytes
; The table itself: Viewable slot 0x7c (table 0xea6fb2, 0 entries,
; InitializeCheap) -- 0 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5BE6, 0x4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x5bea
; naka_disk_menu_file_io+0x5bea  --  naka_disk_menu_file_io +0x5bea..+0x5bee (ROM 0xea6fb6..0xea6fba), 4 bytes
; The table itself: Viewable slot 0x7d (table 0xea6fb6, 0 entries,
; InitializeCheap) -- 0 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5BEA, 0x4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x5bee
; naka_disk_menu_file_io+0x5bee  --  naka_disk_menu_file_io +0x5bee..+0x5c12 (ROM 0xea6fba..0xea6fde), 36 bytes
; The table itself: Viewable slot 0x7e (table 0xea6fba, 8 entries,
; InitializeCheap) -- 8 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5BEE, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x5c12
; naka_disk_menu_file_io+0x5c12  --  naka_disk_menu_file_io +0x5c12..+0x5c16 (ROM 0xea6fde..0xea6fe2), 4 bytes
; The table itself: Viewable slot 0xbc (table 0xea6fde, 0 entries,
; InitializeCheap) -- 0 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5C12, 0x4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x5c16
; naka_disk_menu_file_io+0x5c16  --  naka_disk_menu_file_io +0x5c16..+0x5d44 (ROM 0xea6fe2..0xea7110), 302 bytes
; The table itself: ResName slot 0x360 (table 0xea6fe2, 74 entries,
; InitializeCheap) -- 74 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5C16, 0x12E
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x5d44
; naka_disk_menu_file_io+0x5d44  --  naka_disk_menu_file_io +0x5d44..+0x5e5c (ROM 0xea7110..0xea7228), 280 bytes
; Name strings of elements 0-73 of ResName slot 0x360 (table 0xea6fe2,
; 74 entries, InitializeCheap), names for Viewable slot 0x60: "", "",
; "", "", "CheckPasswordWin", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5D44, 0x118
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x5e5c
; naka_disk_menu_file_io+0x5e5c  --  naka_disk_menu_file_io +0x5e5c..+0x5f00 (ROM 0xea7228..0xea72cc), 164 bytes
; The table itself: ResName slot 0x361 (table 0xea7228, 128 entries,
; InitializeCheap) -- 128 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x5E5C, 0xA4
EmbeddedPtrTable_v10_naka_disk_menu_file_io_005F00:
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
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x6000
; naka_disk_menu_file_io+0x6000  --  naka_disk_menu_file_io +0x6000..+0x6062 (ROM 0xea73cc..0xea742e), 98 bytes
; No RegObjTabl-registered table points at the start of these 98 bytes
; (0xea73cc..0xea742e); purpose not established by that route.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6000, 0x62
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x6062
; naka_disk_menu_file_io+0x6062  --  naka_disk_menu_file_io +0x6062..+0x61fa (ROM 0xea742e..0xea75c6), 408 bytes
; Name strings of elements 0-127 of ResName slot 0x361 (table 0xea7228,
; 128 entries, InitializeCheap), names for Viewable slot 0x61: "",
; "CmpSingleLoadSwCtl", "", "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6062, 0x198
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x61fa
; naka_disk_menu_file_io+0x61fa  --  naka_disk_menu_file_io +0x61fa..+0x6200 (ROM 0xea75c6..0xea75cc), 6 bytes
; The table itself: ResName slot 0x362 (table 0xea75c6, 0 entries,
; InitializeCheap) -- 0 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x61FA, 0x6
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x6200
; naka_disk_menu_file_io+0x6200  --  naka_disk_menu_file_io +0x6200..+0x6206 (ROM 0xea75cc..0xea75d2), 6 bytes
; The table itself: ResName slot 0x363 (table 0xea75cc, 0 entries,
; InitializeCheap) -- 0 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6200, 0x6
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x6206
; naka_disk_menu_file_io+0x6206  --  naka_disk_menu_file_io +0x6206..+0x620c (ROM 0xea75d2..0xea75d8), 6 bytes
; The table itself: ResName slot 0x364 (table 0xea75d2, 0 entries,
; InitializeCheap) -- 0 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6206, 0x6
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x620c
; naka_disk_menu_file_io+0x620c  --  naka_disk_menu_file_io +0x620c..+0x621e (ROM 0xea75d8..0xea75ea), 18 bytes
; The table itself: ResName slot 0x365 (table 0xea75d8, 3 entries,
; InitializeCheap) -- 3 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x620C, 0x12
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x621e
; naka_disk_menu_file_io+0x621e  --  naka_disk_menu_file_io +0x621e..+0x6230 (ROM 0xea75ea..0xea75fc), 18 bytes
; Name strings of elements 0-2 of ResName slot 0x365 (table 0xea75d8, 3
; entries, InitializeCheap), names for Viewable slot 0x65: "", "",
; "DiskSaveMenu".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x621E, 0x12
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x6230
; naka_disk_menu_file_io+0x6230  --  naka_disk_menu_file_io +0x6230..+0x6236 (ROM 0xea75fc..0xea7602), 6 bytes
; The table itself: ResName slot 0x366 (table 0xea75fc, 0 entries,
; InitializeCheap) -- 0 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6230, 0x6
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x6236
; naka_disk_menu_file_io+0x6236  --  naka_disk_menu_file_io +0x6236..+0x6358 (ROM 0xea7602..0xea7724), 290 bytes
; The table itself: ResName slot 0x367 (table 0xea7602, 71 entries,
; InitializeCheap) -- 71 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6236, 0x122
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x6358
; naka_disk_menu_file_io+0x6358  --  naka_disk_menu_file_io +0x6358..+0x6418 (ROM 0xea7724..0xea77e4), 192 bytes
; Name strings of elements 0-70 of ResName slot 0x367 (table 0xea7602,
; 71 entries, InitializeCheap), names for Viewable slot 0x67: "", "",
; "", "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6358, 0xC0
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x6418
; naka_disk_menu_file_io+0x6418  --  naka_disk_menu_file_io +0x6418..+0x641e (ROM 0xea77e4..0xea77ea), 6 bytes
; The table itself: ResName slot 0x36a (table 0xea77e4, 0 entries,
; InitializeCheap) -- 0 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6418, 0x6
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x641e
; naka_disk_menu_file_io+0x641e  --  naka_disk_menu_file_io +0x641e..+0x6478 (ROM 0xea77ea..0xea7844), 90 bytes
; The table itself: ResName slot 0x36b (table 0xea77ea, 21 entries,
; InitializeCheap) -- 21 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x641E, 0x5A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x6478
; naka_disk_menu_file_io+0x6478  --  naka_disk_menu_file_io +0x6478..+0x64ac (ROM 0xea7844..0xea7878), 52 bytes
; Name strings of elements 0-20 of ResName slot 0x36b (table 0xea77ea,
; 21 entries, InitializeCheap), names for Viewable slot 0x6b: "", "",
; "", "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6478, 0x34
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x64ac
; naka_disk_menu_file_io+0x64ac  --  naka_disk_menu_file_io +0x64ac..+0x6500 (ROM 0xea7878..0xea78cc), 84 bytes
; The table itself: ResName slot 0x36c (table 0xea7878, 83 entries,
; InitializeCheap) -- 83 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x64AC, 0x54
EmbeddedPtrTable_v10_naka_disk_menu_file_io_006500:
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
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x65fc
; naka_disk_menu_file_io+0x65fc  --  naka_disk_menu_file_io +0x65fc..+0x65fe (ROM 0xea79c8..0xea79ca), 2 bytes
; No RegObjTabl-registered table points at the start of these 2 bytes
; (0xea79c8..0xea79ca); purpose not established by that route.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x65FC, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x65fe
; naka_disk_menu_file_io+0x65fe  --  naka_disk_menu_file_io +0x65fe..+0x66fe (ROM 0xea79ca..0xea7aca), 256 bytes
; Name strings of elements 0-82 of ResName slot 0x36c (table 0xea7878,
; 83 entries, InitializeCheap), names for Viewable slot 0x6c: "", "",
; "", "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x65FE, 0x100
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x66fe
; naka_disk_menu_file_io+0x66fe  --  naka_disk_menu_file_io +0x66fe..+0x6704 (ROM 0xea7aca..0xea7ad0), 6 bytes
; The table itself: ResName slot 0x36d (table 0xea7aca, 0 entries,
; InitializeCheap) -- 0 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x66FE, 0x6
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x6704
; naka_disk_menu_file_io+0x6704  --  naka_disk_menu_file_io +0x6704..+0x670a (ROM 0xea7ad0..0xea7ad6), 6 bytes
; The table itself: ResName slot 0x36e (table 0xea7ad0, 0 entries,
; InitializeCheap) -- 0 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6704, 0x6
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x670a
; naka_disk_menu_file_io+0x670a  --  naka_disk_menu_file_io +0x670a..+0x6764 (ROM 0xea7ad6..0xea7b30), 90 bytes
; The table itself: ResName slot 0x377 (table 0xea7ad6, 21 entries,
; InitializeCheap) -- 21 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x670A, 0x5A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x6764
; naka_disk_menu_file_io+0x6764  --  naka_disk_menu_file_io +0x6764..+0x67c0 (ROM 0xea7b30..0xea7b8c), 92 bytes
; Name strings of elements 0-20 of ResName slot 0x377 (table 0xea7ad6,
; 21 entries, InitializeCheap), names for Viewable slot 0x77: "", "",
; "", "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6764, 0x5C
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x67c0
; naka_disk_menu_file_io+0x67c0  --  naka_disk_menu_file_io +0x67c0..+0x67c6 (ROM 0xea7b8c..0xea7b92), 6 bytes
; The table itself: ResName slot 0x379 (table 0xea7b8c, 0 entries,
; InitializeCheap) -- 0 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x67C0, 0x6
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x67c6
; naka_disk_menu_file_io+0x67c6  --  naka_disk_menu_file_io +0x67c6..+0x6944 (ROM 0xea7b92..0xea7d10), 382 bytes
; The table itself: ResName slot 0x37b (table 0xea7b92, 94 entries,
; InitializeCheap) -- 94 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x67C6, 0x17E
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x6944
; naka_disk_menu_file_io+0x6944  --  naka_disk_menu_file_io +0x6944..+0x6a34 (ROM 0xea7d10..0xea7e00), 240 bytes
; Name strings of elements 43-93 of ResName slot 0x37b (table 0xea7b92,
; 94 entries, InitializeCheap), names for Viewable slot 0x7b: "",
; "DiskSaveSureScr", "", "DiskDeleteSureScr", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6944, 0xF0
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_WaitWinCtlSmf
; NakaInst_WaitWinCtlSmf  --  naka_disk_menu_file_io +0x6a34..+0x6acc (ROM 0xea7e00..0xea7e98), 152 bytes
; Name strings of elements 0-42 of ResName slot 0x37b (table 0xea7b92,
; 94 entries, InitializeCheap), names for Viewable slot 0x7b:
; "WaitWinCtlSmf", "", "", "", "", "", ....
; -----------------------------------------------------------------------------
NakaInst_WaitWinCtlSmf:
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6A34, 0x98
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x6acc
; naka_disk_menu_file_io+0x6acc  --  naka_disk_menu_file_io +0x6acc..+0x6ad2 (ROM 0xea7e98..0xea7e9e), 6 bytes
; The table itself: ResName slot 0x37c (table 0xea7e98, 0 entries,
; InitializeCheap) -- 0 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6ACC, 0x6
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x6ad2
; naka_disk_menu_file_io+0x6ad2  --  naka_disk_menu_file_io +0x6ad2..+0x6ad8 (ROM 0xea7e9e..0xea7ea4), 6 bytes
; The table itself: ResName slot 0x37d (table 0xea7e9e, 0 entries,
; InitializeCheap) -- 0 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6AD2, 0x6
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x6ad8
; naka_disk_menu_file_io+0x6ad8  --  naka_disk_menu_file_io +0x6ad8..+0x6afe (ROM 0xea7ea4..0xea7eca), 38 bytes
; The table itself: ResName slot 0x37e (table 0xea7ea4, 8 entries,
; InitializeCheap) -- 8 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6AD8, 0x26
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x6afe
; naka_disk_menu_file_io+0x6afe  --  naka_disk_menu_file_io +0x6afe..+0x6b16 (ROM 0xea7eca..0xea7ee2), 24 bytes
; Name strings of elements 0-7 of ResName slot 0x37e (table 0xea7ea4, 8
; entries, InitializeCheap), names for Viewable slot 0x7e: "", "", "",
; "", "", "", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6AFE, 0x18
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x6b16
; naka_disk_menu_file_io+0x6b16  --  naka_disk_menu_file_io +0x6b16..+0x6c02 (ROM 0xea7ee2..0xea7fce), 236 bytes
; The table itself: ResName slot 0x3bc (table 0xea7ee2, 0 entries,
; InitializeCheap) -- 0 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6B16, 0xEC
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x6c02
; naka_disk_menu_file_io+0x6c02  --  naka_disk_menu_file_io +0x6c02..+0x6cea (ROM 0xea7fce..0xea80b6), 232 bytes
; The table itself: MainFunction slot 0x145 (table 0xea7fce, 57 entries,
; InitializeCheap) -- 57 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6C02, 0xE8
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x6cea
; naka_disk_menu_file_io+0x6cea  --  naka_disk_menu_file_io +0x6cea..+0x6dd4 (ROM 0xea80b6..0xea81a0), 234 bytes
; The table itself: MainFunction slot 0x445 (table 0xea80b6, 57 entries,
; InitializeCheap) -- 57 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6CEA, 0xEA
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_disk_menu_file_io+0x6dd4
; naka_disk_menu_file_io+0x6dd4  --  naka_disk_menu_file_io +0x6dd4..+0x78e0 (ROM 0xea81a0..0xea8cac), 2828 bytes
; Name strings of elements 0-56 of MainFunction slot 0x445 (table
; 0xea80b6, 57 entries, InitializeCheap), names for MainFunction slot
; 0x145: "FmmPasswordFunc", "FmmWallpaperLoadFunc",
; "FmmCmpSingleLoadFunc", "CmpSingleLoadDstFunc",
; "CmpSingleLoadSrcFunc", "CmpSingleLoadFileFunc", ....
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_disk_menu_file_io.bin", 0x6DD4, 0xB0C

; External label offsets within the binary blob above.
