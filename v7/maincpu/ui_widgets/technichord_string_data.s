
; TechniChord & UI String Data Tables (13 widgets, 111742 bytes)
; Source: maincpu/ui_widgets/naka_technichord_strings.c (raw byte array)
; -----------------------------------------------------------------------------
; [nakarest_retype] registered NAKA tables: naka_technichord_strings
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
; Function slot 0x105: RegObjTabl 0x1600001, FunctionProc, 0xd,
; 0xea135a, 0x105 in InitializeCheap (file_io/medley.s), i.e.
; RegisterObjectTable stores {class, proc, 13, table} at 0x27ed2 +
; 14*0x105.
;
; MainFunction slot 0x141: RegObjTabl 0x1600003, MainFunctionProc, 0x2,
; 0xe86638, 0x141 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 2, table} at 0x27ed2 +
; 14*0x141.
;
; Class slot 0x165: RegObjTable 0x1600004, ClassProc, 0xea1186,
; 0xea0f46, 0x165 in InitializeCheap (file_io/medley.s) -- the count,
; 13, is the word at 0xea1186; RegisterObjectTable stores {class, proc,
; count, table} at 0x27ed2 + 14*0x165.
;
; ResEvent slot 0x1c5: RegObjTable 0x160000c, ResEventProc, 0xea11f2,
; 0xea1188, 0x1c5 in InitializeCheap (file_io/medley.s) -- the count, 5,
; is the word at 0xea11f2; RegisterObjectTable stores {class, proc,
; count, table} at 0x27ed2 + 14*0x1c5.
;
; ResMethod slot 0x1e5: RegObjTable 0x160000d, ResMethodProc, 0xea1358,
; 0xea11f4, 0x1e5 in InitializeCheap (file_io/medley.s) -- the count,
; 17, is the word at 0xea1358; RegisterObjectTable stores {class, proc,
; count, table} at 0x27ed2 + 14*0x1e5.
;
; ResName slot 0x30d: RegObjTabl 0x160000f, ResNameProc, 0x1d, 0xe85f4e,
; 0x30d in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 29, table} at 0x27ed2 +
; 14*0x30d.
;
; ResName slot 0x3a5: RegObjTabl 0x160000f, ResNameProc, 0x4, 0xe8608e,
; 0x3a5 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 4, table} at 0x27ed2 +
; 14*0x3a5.
;
; ResName slot 0x3e4: RegObjTabl 0x160000f, ResNameProc, 0xf, 0xe860b2,
; 0x3e4 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 15, table} at 0x27ed2 +
; 14*0x3e4.
;
; ResName slot 0x3ea: RegObjTabl 0x160000f, ResNameProc, 0x2c, 0xe8617e,
; 0x3ea in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 44, table} at 0x27ed2 +
; 14*0x3ea.
;
; ResName slot 0x3eb: RegObjTabl 0x160000f, ResNameProc, 0x25, 0xe862f2,
; 0x3eb in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 37, table} at 0x27ed2 +
; 14*0x3eb.
;
; ResName slot 0x3ee: RegObjTabl 0x160000f, ResNameProc, 0x18, 0xe863fe,
; 0x3ee in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 24, table} at 0x27ed2 +
; 14*0x3ee.
;
; ResName slot 0x3ef: RegObjTabl 0x160000f, ResNameProc, 0xb, 0xe864d0,
; 0x3ef in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 11, table} at 0x27ed2 +
; 14*0x3ef.
;
; ResName slot 0x3f0: RegObjTabl 0x160000f, ResNameProc, 0x6, 0xe86534,
; 0x3f0 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 6, table} at 0x27ed2 +
; 14*0x3f0.
;
; Function slot 0x405: RegObjTabl 0x1600001, FunctionProc, 0xd,
; 0xea1392, 0x405 in InitializeCheap (file_io/medley.s), i.e.
; RegisterObjectTable stores {class, proc, 13, table} at 0x27ed2 +
; 14*0x405.
;
; ApFunction slot 0x425: RegObjTabl 0x1600002, ApFunctionProc, 0x1d,
; 0xea0ace, 0x425 in InitializeCheap (file_io/medley.s), i.e.
; RegisterObjectTable stores {class, proc, 29, table} at 0x27ed2 +
; 14*0x425.
;
; MainFunction slot 0x441: RegObjTabl 0x1600003, MainFunctionProc, 0x2,
; 0xe86644, 0x441 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 2, table} at 0x27ed2 +
; 14*0x441.
; -----------------------------------------------------------------------------

; [nakarest] NakaData_TechniChordStrings  +0x0..+0x28 (0xe85f4e, 40 B)
; [nakarest] the table itself: ResName slot 0x30d (table 0xe85f4e, 29 entries, InitializeMurai),
; [nakarest] 29 entry pointers x 4 bytes.
NakaData_TechniChordStrings:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x0, 0x28
; [nakarest] TechniChord_StyleDispatch_Table  +0x28..+0x7a (0xe85f76, 82 B)
; [nakarest] purpose not established: 6 bytes at 0xe85fc2 that no registered NAKA table points into
; [nakarest] Continues the table itself: ResName slot 0x30d (table 0xe85f4e, 29 entries,
; [nakarest] InitializeMurai), 29 entry pointers x 4 bytes (starts 0xe85f4e, 76 of its 116 bytes
; [nakarest] are here or later).
TechniChord_StyleDispatch_Table:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x28, 0x52
; [nakarest] naka_technichord_strings+0x7a  +0x7a..+0x8a (0xe85fc8, 16 B)
; [nakarest] name strings, entries 24-28 of ResName slot 0x30d (table 0xe85f4e, 29 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xd): "", "", "", "Sdtecd2", "".
	.incbin "includes/generated/naka_technichord_strings.bin", 0x7A, 0x10
; [nakarest] NakaInst_TcFanfare  +0x8a..+0x94 (0xe85fd8, 10 B)
; [nakarest] name string, entry 23 of ResName slot 0x30d (table 0xe85f4e, 29 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xd): "TcFanfare".
NakaInst_TcFanfare:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x8A, 0xA
; [nakarest] NakaInst_TcHardRock  +0x94..+0xa0 (0xe85fe2, 12 B)
; [nakarest] name string, entry 22 of ResName slot 0x30d (table 0xe85f4e, 29 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xd): "TcHardRock".
NakaInst_TcHardRock:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x94, 0xC
; [nakarest] NakaInst_TcBlock  +0xa0..+0xa8 (0xe85fee, 8 B)
; [nakarest] name string, entry 21 of ResName slot 0x30d (table 0xe85f4e, 29 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xd): "TcBlock".
NakaInst_TcBlock:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xA0, 0x8
; [nakarest] NakaInst_TcOctave  +0xa8..+0xb2 (0xe85ff6, 10 B)
; [nakarest] name string, entry 20 of ResName slot 0x30d (table 0xe85f4e, 29 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xd): "TcOctave".
NakaInst_TcOctave:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xA8, 0xA
; [nakarest] NakaInst_TcBigBandReeds  +0xb2..+0xc2 (0xe86000, 16 B)
; [nakarest] name string, entry 19 of ResName slot 0x30d (table 0xe85f4e, 29 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xd): "TcBigBandReeds".
NakaInst_TcBigBandReeds:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xB2, 0x10
; [nakarest] NakaInst_TcBigBandBrass  +0xc2..+0xd2 (0xe86010, 16 B)
; [nakarest] name string, entry 18 of ResName slot 0x30d (table 0xe85f4e, 29 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xd): "TcBigBandBrass".
NakaInst_TcBigBandBrass:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xC2, 0x10
; [nakarest] NakaInst_TcHymn  +0xd2..+0xda (0xe86020, 8 B)
; [nakarest] name string, entry 17 of ResName slot 0x30d (table 0xe85f4e, 29 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xd): "TcHymn".
NakaInst_TcHymn:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xD2, 0x8
; [nakarest] NakaInst_TcTheatre  +0xda..+0xe4 (0xe86028, 10 B)
; [nakarest] name string, entry 16 of ResName slot 0x30d (table 0xe85f4e, 29 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xd): "TcTheatre".
NakaInst_TcTheatre:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xDA, 0xA
; [nakarest] NakaInst_TcCountry  +0xe4..+0xee (0xe86032, 10 B)
; [nakarest] name string, entry 15 of ResName slot 0x30d (table 0xe85f4e, 29 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xd): "TcCountry".
NakaInst_TcCountry:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xE4, 0xA
; [nakarest] NakaInst_TcDuet2  +0xee..+0xf6 (0xe8603c, 8 B)
; [nakarest] name string, entry 14 of ResName slot 0x30d (table 0xe85f4e, 29 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xd): "TcDuet2".
NakaInst_TcDuet2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xEE, 0x8
; [nakarest] NakaInst_TcDuet1  +0xf6..+0xfe (0xe86044, 8 B)
; [nakarest] name string, entry 13 of ResName slot 0x30d (table 0xe85f4e, 29 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xd): "TcDuet1".
NakaInst_TcDuet1:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF6, 0x8
; [nakarest] NakaInst_TcOpen2  +0xfe..+0x106 (0xe8604c, 8 B)
; [nakarest] name string, entry 12 of ResName slot 0x30d (table 0xe85f4e, 29 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xd): "TcOpen2".
NakaInst_TcOpen2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xFE, 0x8
; [nakarest] NakaInst_TcOpen1  +0x106..+0x10e (0xe86054, 8 B)
; [nakarest] name string, entry 11 of ResName slot 0x30d (table 0xe85f4e, 29 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xd): "TcOpen1".
NakaInst_TcOpen1:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x106, 0x8
; [nakarest] NakaInst_TcClose  +0x10e..+0x118 (0xe8605c, 10 B)
; [nakarest] name strings, entries 9-10 of ResName slot 0x30d (table 0xe85f4e, 29 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xd): "TcClose", "".
NakaInst_TcClose:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x10E, 0xA
; [nakarest] NakaInst_TcClose_Terminator  +0x118..+0x11a (0xe86066, 2 B)
; [nakarest] name string, entry 8 of ResName slot 0x30d (table 0xe85f4e, 29 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xd): "".
NakaInst_TcClose_Terminator:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x118, 0x2
; [nakarest] NakaInst_TcClose_Pad  +0x11a..+0x11c (0xe86068, 2 B)
; [nakarest] name string, entry 7 of ResName slot 0x30d (table 0xe85f4e, 29 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xd): "".
NakaInst_TcClose_Pad:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x11A, 0x2
; [nakarest] NakaInst_Sdtecd1  +0x11c..+0x126 (0xe8606a, 10 B)
; [nakarest] name strings, entries 5-6 of ResName slot 0x30d (table 0xe85f4e, 29 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xd): "Sdtecd1", "".
NakaInst_Sdtecd1:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x11C, 0xA
; [nakarest] NakaInst_Sdtecd1_Terminator  +0x126..+0x128 (0xe86074, 2 B)
; [nakarest] name string, entry 4 of ResName slot 0x30d (table 0xe85f4e, 29 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xd): "".
NakaInst_Sdtecd1_Terminator:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x126, 0x2
; [nakarest] NakaInst_SdtecdGroup_Term2  +0x128..+0x12a (0xe86076, 2 B)
; [nakarest] name string, entry 3 of ResName slot 0x30d (table 0xe85f4e, 29 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xd): "".
NakaInst_SdtecdGroup_Term2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x128, 0x2
; [nakarest] NakaInst_SdtecdGroup_Pad  +0x12a..+0x12c (0xe86078, 2 B)
; [nakarest] name string, entry 2 of ResName slot 0x30d (table 0xe85f4e, 29 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xd): "".
NakaInst_SdtecdGroup_Pad:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x12A, 0x2
; [nakarest] NakaInst_SdtecdPage  +0x12c..+0x138 (0xe8607a, 12 B)
; [nakarest] name string, entry 1 of ResName slot 0x30d (table 0xe85f4e, 29 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xd): "SdtecdPage".
NakaInst_SdtecdPage:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x12C, 0xC
; [nakarest] NakaInst_Sdtecd  +0x138..+0x140 (0xe86086, 8 B)
; [nakarest] name string, entry 0 of ResName slot 0x30d (table 0xe85f4e, 29 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xd): "Sdtecd".
NakaInst_Sdtecd:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x138, 0x8
; [nakarest] naka_technichord_strings+0x140  +0x140..+0x154 (0xe8608e, 20 B)
; [nakarest] the table itself: ResName slot 0x3a5 (table 0xe8608e, 4 entries, InitializeMurai),
; [nakarest] 4 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_technichord_strings.bin", 0x140, 0x14
; [nakarest] NakaInst_Sqmixer_Term1  +0x154..+0x156 (0xe860a2, 2 B)
; [nakarest] purpose not established: 2 bytes at 0xe860a2 that no registered NAKA table points into
NakaInst_Sqmixer_Term1:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x154, 0x2
; [nakarest] NakaInst_Sqmixer_Term2  +0x156..+0x158 (0xe860a4, 2 B)
; [nakarest] name string, entry 3 of ResName slot 0x3a5 (table 0xe8608e, 4 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xa5): "".
NakaInst_Sqmixer_Term2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x156, 0x2
; [nakarest] NakaInst_Sqmixer_Term3  +0x158..+0x15a (0xe860a6, 2 B)
; [nakarest] name string, entry 2 of ResName slot 0x3a5 (table 0xe8608e, 4 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xa5): "".
NakaInst_Sqmixer_Term3:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x158, 0x2
; [nakarest] NakaInst_Sqmixer_Pad  +0x15a..+0x15c (0xe860a8, 2 B)
; [nakarest] name string, entry 1 of ResName slot 0x3a5 (table 0xe8608e, 4 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xa5): "".
NakaInst_Sqmixer_Pad:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x15A, 0x2
; [nakarest] NakaInst_Sqmixer  +0x15c..+0x164 (0xe860aa, 8 B)
; [nakarest] name string, entry 0 of ResName slot 0x3a5 (table 0xe8608e, 4 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xa5): "Sqmixer".
NakaInst_Sqmixer:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x15C, 0x8
; [nakarest] naka_technichord_strings+0x164  +0x164..+0x1a4 (0xe860b2, 64 B)
; [nakarest] the table itself: ResName slot 0x3e4 (table 0xe860b2, 15 entries, InitializeMurai),
; [nakarest] 15 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_technichord_strings.bin", 0x164, 0x40
; [nakarest] NakaInst_Sqmixer_PtrEnd  +0x1a4..+0x1a6 (0xe860f2, 2 B)
; [nakarest] purpose not established: 2 bytes at 0xe860f2 that no registered NAKA table points into
NakaInst_Sqmixer_PtrEnd:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A4, 0x2
; [nakarest] NakaInst_PresentationTitle  +0x1a6..+0x1b8 (0xe860f4, 18 B)
; [nakarest] name string, entry 14 of ResName slot 0x3e4 (table 0xe860b2, 15 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xe4): "PresentationTitle".
NakaInst_PresentationTitle:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A6, 0x12
; [nakarest] NakaInst_PresentationTitle_Pad  +0x1b8..+0x1ba (0xe86106, 2 B)
; [nakarest] name string, entry 13 of ResName slot 0x3e4 (table 0xe860b2, 15 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xe4): "".
NakaInst_PresentationTitle_Pad:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B8, 0x2
; [nakarest] NakaInst_LoadingPresentation  +0x1ba..+0x1ce (0xe86108, 20 B)
; [nakarest] name string, entry 12 of ResName slot 0x3e4 (table 0xe860b2, 15 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xe4): "LoadingPresentation".
NakaInst_LoadingPresentation:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1BA, 0x14
; [nakarest] NakaInst_LoadingPresentation_Pad  +0x1ce..+0x1d0 (0xe8611c, 2 B)
; [nakarest] name string, entry 11 of ResName slot 0x3e4 (table 0xe860b2, 15 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xe4): "".
NakaInst_LoadingPresentation_Pad:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1CE, 0x2
; [nakarest] NakaInst_PresentationControl  +0x1d0..+0x1e4 (0xe8611e, 20 B)
; [nakarest] name string, entry 10 of ResName slot 0x3e4 (table 0xe860b2, 15 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xe4): "PresentationControl".
NakaInst_PresentationControl:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1D0, 0x14
; [nakarest] NakaInst_PlainScreen  +0x1e4..+0x1f0 (0xe86132, 12 B)
; [nakarest] name string, entry 9 of ResName slot 0x3e4 (table 0xe860b2, 15 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xe4): "PlainScreen".
NakaInst_PlainScreen:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1E4, 0xC
; [nakarest] NakaInst_FDemoTitleBox  +0x1f0..+0x200 (0xe8613e, 16 B)
; [nakarest] name strings, entries 7-8 of ResName slot 0x3e4 (table 0xe860b2, 15 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xe4): "FDemoTitleBox", "".
NakaInst_FDemoTitleBox:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1F0, 0x10
; [nakarest] NakaInst_FDemoTitleBox_Terminator  +0x200..+0x202 (0xe8614e, 2 B)
; [nakarest] name string, entry 6 of ResName slot 0x3e4 (table 0xe860b2, 15 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xe4): "".
NakaInst_FDemoTitleBox_Terminator:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x200, 0x2
; [nakarest] NakaInst_Demofeature2  +0x202..+0x210 (0xe86150, 14 B)
; [nakarest] name string, entry 5 of ResName slot 0x3e4 (table 0xe860b2, 15 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xe4): "Demofeature2".
NakaInst_Demofeature2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x202, 0xE
; [nakarest] NakaInst_Demofeature2_Pad  +0x210..+0x212 (0xe8615e, 2 B)
; [nakarest] name string, entry 4 of ResName slot 0x3e4 (table 0xe860b2, 15 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xe4): "".
NakaInst_Demofeature2_Pad:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x210, 0x2
; [nakarest] NakaInst_Demofeature2_Pad2  +0x212..+0x214 (0xe86160, 2 B)
; [nakarest] name string, entry 3 of ResName slot 0x3e4 (table 0xe860b2, 15 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xe4): "".
NakaInst_Demofeature2_Pad2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x212, 0x2
; [nakarest] NakaInst_Demofeature1  +0x214..+0x222 (0xe86162, 14 B)
; [nakarest] name string, entry 2 of ResName slot 0x3e4 (table 0xe860b2, 15 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xe4): "Demofeature1".
NakaInst_Demofeature1:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x214, 0xE
; [nakarest] NakaInst_Demofeature1_Pad  +0x222..+0x224 (0xe86170, 2 B)
; [nakarest] name string, entry 1 of ResName slot 0x3e4 (table 0xe860b2, 15 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xe4): "".
NakaInst_Demofeature1_Pad:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x222, 0x2
; [nakarest] NakaInst_Demofeature  +0x224..+0x230 (0xe86172, 12 B)
; [nakarest] name string, entry 0 of ResName slot 0x3e4 (table 0xe860b2, 15 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xe4): "Demofeature".
NakaInst_Demofeature:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x224, 0xC
; [nakarest] naka_technichord_strings+0x230  +0x230..+0x238 (0xe8617e, 8 B)
; [nakarest] the table itself: ResName slot 0x3ea (table 0xe8617e, 44 entries, InitializeMurai),
; [nakarest] 44 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_technichord_strings.bin", 0x230, 0x8
; [nakarest] NakaInst_DrawbarPtrTable  +0x238..+0x2e6 (0xe86186, 174 B)
; [nakarest] purpose not established: 6 bytes at 0xe8622e that no registered NAKA table points into
; [nakarest] Continues the table itself: ResName slot 0x3ea (table 0xe8617e, 44 entries,
; [nakarest] InitializeMurai), 44 entry pointers x 4 bytes (starts 0xe8617e, 168 of its 176
; [nakarest] bytes are here or later).
NakaInst_DrawbarPtrTable:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x238, 0xAE
; [nakarest] naka_technichord_strings+0x2e6  +0x2e6..+0x374 (0xe86234, 142 B)
; [nakarest] name strings, entries 6-43 of ResName slot 0x3ea (table 0xe8617e, 44 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xea): "", "", "", "", "", "DrawbarSndE",
; [nakarest] ....
	.incbin "includes/generated/naka_technichord_strings.bin", 0x2E6, 0x8E
; [nakarest] Str_Drawbar_Black23  +0x374..+0x37c (0xe862c2, 8 B)
; [nakarest] name string, entry 5 of ResName slot 0x3ea (table 0xe8617e, 44 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xea): "Black23".
Str_Drawbar_Black23:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x374, 0x8
; [nakarest] Str_Drawbar_White23  +0x37c..+0x384 (0xe862ca, 8 B)
; [nakarest] name string, entry 4 of ResName slot 0x3ea (table 0xe8617e, 44 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xea): "White23".
Str_Drawbar_White23:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x37C, 0x8
; [nakarest] Str_Drawbar_DrawPerc223  +0x384..+0x390 (0xe862d2, 12 B)
; [nakarest] name string, entry 3 of ResName slot 0x3ea (table 0xe8617e, 44 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xea): "DrawPerc223".
Str_Drawbar_DrawPerc223:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x384, 0xC
; [nakarest] Str_Drawbar_DrawPerc4  +0x390..+0x39a (0xe862de, 10 B)
; [nakarest] name string, entry 2 of ResName slot 0x3ea (table 0xe8617e, 44 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xea): "DrawPerc4".
Str_Drawbar_DrawPerc4:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x390, 0xA
; [nakarest] Str_Drawbar_Empty  +0x39a..+0x39c (0xe862e8, 2 B)
; [nakarest] name string, entry 1 of ResName slot 0x3ea (table 0xe8617e, 44 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xea): "".
Str_Drawbar_Empty:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x39A, 0x2
; [nakarest] Str_Drawbar_Drawbar  +0x39c..+0x3a4 (0xe862ea, 8 B)
; [nakarest] name string, entry 0 of ResName slot 0x3ea (table 0xe8617e, 44 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xea): "Drawbar".
Str_Drawbar_Drawbar:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x39C, 0x8
; [nakarest] naka_technichord_strings+0x3a4  +0x3a4..+0x43c (0xe862f2, 152 B)
; [nakarest] the table itself: ResName slot 0x3eb (table 0xe862f2, 37 entries, InitializeMurai),
; [nakarest] 37 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_technichord_strings.bin", 0x3A4, 0x98
; [nakarest] DrawbarStrNull_E8638A  +0x43c..+0x43e (0xe8638a, 2 B)
; [nakarest] purpose not established: 2 bytes at 0xe8638a that no registered NAKA table points into
DrawbarStrNull_E8638A:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x43C, 0x2
; [nakarest] DrawbarStrNull_E8638C  +0x43e..+0x440 (0xe8638c, 2 B)
; [nakarest] name string, entry 36 of ResName slot 0x3eb (table 0xe862f2, 37 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xeb): "".
DrawbarStrNull_E8638C:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x43E, 0x2
; [nakarest] DrawbarStrNull_E8638E  +0x440..+0x444 (0xe8638e, 4 B)
; [nakarest] name strings, entries 34-35 of ResName slot 0x3eb (table 0xe862f2, 37 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xeb): "", "".
DrawbarStrNull_E8638E:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x440, 0x4
; [nakarest] DrawbarStrNull_E86392  +0x444..+0x446 (0xe86392, 2 B)
; [nakarest] name string, entry 33 of ResName slot 0x3eb (table 0xe862f2, 37 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xeb): "".
DrawbarStrNull_E86392:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x444, 0x2
; [nakarest] DrawbarStrNull_E86394  +0x446..+0x448 (0xe86394, 2 B)
; [nakarest] name string, entry 32 of ResName slot 0x3eb (table 0xe862f2, 37 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xeb): "".
DrawbarStrNull_E86394:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x446, 0x2
; [nakarest] DrawbarStrNull_E86396  +0x448..+0x44c (0xe86396, 4 B)
; [nakarest] name strings, entries 30-31 of ResName slot 0x3eb (table 0xe862f2, 37 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xeb): "", "".
DrawbarStrNull_E86396:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x448, 0x4
; [nakarest] DrawbarStrNull_E8639A  +0x44c..+0x44e (0xe8639a, 2 B)
; [nakarest] name string, entry 29 of ResName slot 0x3eb (table 0xe862f2, 37 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xeb): "".
DrawbarStrNull_E8639A:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x44C, 0x2
; [nakarest] DrawbarStrNull_E8639C  +0x44e..+0x450 (0xe8639c, 2 B)
; [nakarest] name string, entry 28 of ResName slot 0x3eb (table 0xe862f2, 37 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xeb): "".
DrawbarStrNull_E8639C:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x44E, 0x2
; [nakarest] DrawbarStrNull_E8639E  +0x450..+0x454 (0xe8639e, 4 B)
; [nakarest] name strings, entries 26-27 of ResName slot 0x3eb (table 0xe862f2, 37 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xeb): "", "".
DrawbarStrNull_E8639E:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x450, 0x4
; [nakarest] DrawbarStrNull_E863A2  +0x454..+0x456 (0xe863a2, 2 B)
; [nakarest] name string, entry 25 of ResName slot 0x3eb (table 0xe862f2, 37 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xeb): "".
DrawbarStrNull_E863A2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x454, 0x2
; [nakarest] DrawbarStrNull_E863A4  +0x456..+0x458 (0xe863a4, 2 B)
; [nakarest] name string, entry 24 of ResName slot 0x3eb (table 0xe862f2, 37 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xeb): "".
DrawbarStrNull_E863A4:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x456, 0x2
; [nakarest] Str_Accordion_Accordion2  +0x458..+0x466 (0xe863a6, 14 B)
; [nakarest] name strings, entries 22-23 of ResName slot 0x3eb (table 0xe862f2, 37 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xeb): "Accordion2", "".
Str_Accordion_Accordion2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x458, 0xE
; [nakarest] AccordionStrNull_E863B4  +0x466..+0x468 (0xe863b4, 2 B)
; [nakarest] name string, entry 21 of ResName slot 0x3eb (table 0xe862f2, 37 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xeb): "".
AccordionStrNull_E863B4:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x466, 0x2
; [nakarest] AccordionStrNull_E863B6  +0x468..+0x46c (0xe863b6, 4 B)
; [nakarest] name strings, entries 19-20 of ResName slot 0x3eb (table 0xe862f2, 37 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xeb): "", "".
AccordionStrNull_E863B6:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x468, 0x4
; [nakarest] AccordionStrNull_E863BA  +0x46c..+0x46e (0xe863ba, 2 B)
; [nakarest] name string, entry 18 of ResName slot 0x3eb (table 0xe862f2, 37 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xeb): "".
AccordionStrNull_E863BA:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x46C, 0x2
; [nakarest] AccordionStrNull_E863BC  +0x46e..+0x470 (0xe863bc, 2 B)
; [nakarest] name string, entry 17 of ResName slot 0x3eb (table 0xe862f2, 37 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xeb): "".
AccordionStrNull_E863BC:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x46E, 0x2
; [nakarest] AccordionStrNull_E863BE  +0x470..+0x474 (0xe863be, 4 B)
; [nakarest] name strings, entries 15-16 of ResName slot 0x3eb (table 0xe862f2, 37 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xeb): "", "".
AccordionStrNull_E863BE:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x470, 0x4
; [nakarest] AccordionStrNull_E863C2  +0x474..+0x476 (0xe863c2, 2 B)
; [nakarest] name string, entry 14 of ResName slot 0x3eb (table 0xe862f2, 37 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xeb): "".
AccordionStrNull_E863C2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x474, 0x2
; [nakarest] AccordionStrNull_E863C4  +0x476..+0x478 (0xe863c4, 2 B)
; [nakarest] name string, entry 13 of ResName slot 0x3eb (table 0xe862f2, 37 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xeb): "".
AccordionStrNull_E863C4:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x476, 0x2
; [nakarest] AccordionStrNull_E863C6  +0x478..+0x47c (0xe863c6, 4 B)
; [nakarest] name strings, entries 11-12 of ResName slot 0x3eb (table 0xe862f2, 37 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xeb): "", "".
AccordionStrNull_E863C6:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x478, 0x4
; [nakarest] AccordionStrNull_E863CA  +0x47c..+0x47e (0xe863ca, 2 B)
; [nakarest] name string, entry 10 of ResName slot 0x3eb (table 0xe862f2, 37 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xeb): "".
AccordionStrNull_E863CA:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x47C, 0x2
; [nakarest] Str_Accordion_Accordion1  +0x47e..+0x48a (0xe863cc, 12 B)
; [nakarest] name string, entry 9 of ResName slot 0x3eb (table 0xe862f2, 37 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xeb): "Accordion1".
Str_Accordion_Accordion1:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x47E, 0xC
; [nakarest] Str_Accordion_Empty  +0x48a..+0x48c (0xe863d8, 2 B)
; [nakarest] name string, entry 8 of ResName slot 0x3eb (table 0xe862f2, 37 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xeb): "".
Str_Accordion_Empty:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x48A, 0x2
; [nakarest] Str_Accordion_AccordionPart  +0x48c..+0x49c (0xe863da, 16 B)
; [nakarest] name strings, entries 6-7 of ResName slot 0x3eb (table 0xe862f2, 37 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xeb): "AccordionPart", "".
Str_Accordion_AccordionPart:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x48C, 0x10
; [nakarest] AccordionStrNull_E863EA  +0x49c..+0x49e (0xe863ea, 2 B)
; [nakarest] name string, entry 5 of ResName slot 0x3eb (table 0xe862f2, 37 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xeb): "".
AccordionStrNull_E863EA:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x49C, 0x2
; [nakarest] AccordionStrNull_E863EC  +0x49e..+0x4a0 (0xe863ec, 2 B)
; [nakarest] name string, entry 4 of ResName slot 0x3eb (table 0xe862f2, 37 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xeb): "".
AccordionStrNull_E863EC:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x49E, 0x2
; [nakarest] AccordionStrNull_E863EE  +0x4a0..+0x4a4 (0xe863ee, 4 B)
; [nakarest] name strings, entries 2-3 of ResName slot 0x3eb (table 0xe862f2, 37 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xeb): "", "".
AccordionStrNull_E863EE:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x4A0, 0x4
; [nakarest] AccordionStrNull_E863F2  +0x4a4..+0x4a6 (0xe863f2, 2 B)
; [nakarest] name string, entry 1 of ResName slot 0x3eb (table 0xe862f2, 37 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xeb): "".
AccordionStrNull_E863F2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x4A4, 0x2
; [nakarest] Str_Accordion_Accordion  +0x4a6..+0x4b0 (0xe863f4, 10 B)
; [nakarest] name string, entry 0 of ResName slot 0x3eb (table 0xe862f2, 37 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xeb): "Accordion".
Str_Accordion_Accordion:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x4A6, 0xA
; [nakarest] naka_technichord_strings+0x4b0  +0x4b0..+0x516 (0xe863fe, 102 B)
; [nakarest] the table itself: ResName slot 0x3ee (table 0xe863fe, 24 entries, InitializeMurai),
; [nakarest] 24 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_technichord_strings.bin", 0x4B0, 0x66
; [nakarest] naka_technichord_strings+0x516  +0x516..+0x582 (0xe86464, 108 B)
; [nakarest] name strings, entries 0-23 of ResName slot 0x3ee (table 0xe863fe, 24 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xee): "", "PleaseWait", "", "NoMessage",
; [nakarest] "", "", ....
	.incbin "includes/generated/naka_technichord_strings.bin", 0x516, 0x6C
; [nakarest] StrTable_WelcomVersion  +0x582..+0x5b2 (0xe864d0, 48 B)
; [nakarest] the table itself: ResName slot 0x3ef (table 0xe864d0, 11 entries, InitializeMurai),
; [nakarest] 11 entry pointers x 4 bytes.
StrTable_WelcomVersion:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x582, 0x30
; [nakarest] Str_Version_Empty1  +0x5b2..+0x5b4 (0xe86500, 2 B)
; [nakarest] purpose not established: 2 bytes at 0xe86500 that no registered NAKA table points into
Str_Version_Empty1:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x5B2, 0x2
; [nakarest] Str_Version_MPver  +0x5b4..+0x5ba (0xe86502, 6 B)
; [nakarest] name string, entry 10 of ResName slot 0x3ef (table 0xe864d0, 11 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xef): "MPver".
Str_Version_MPver:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x5B4, 0x6
; [nakarest] Str_Version_Empty2  +0x5ba..+0x5bc (0xe86508, 2 B)
; [nakarest] name string, entry 9 of ResName slot 0x3ef (table 0xe864d0, 11 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xef): "".
Str_Version_Empty2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x5BA, 0x2
; [nakarest] Str_Version_Empty3  +0x5bc..+0x5be (0xe8650a, 2 B)
; [nakarest] name string, entry 8 of ResName slot 0x3ef (table 0xe864d0, 11 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xef): "".
Str_Version_Empty3:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x5BC, 0x2
; [nakarest] Str_Version_MPVersion  +0x5be..+0x5c8 (0xe8650c, 10 B)
; [nakarest] name string, entry 7 of ResName slot 0x3ef (table 0xe864d0, 11 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xef): "MPVersion".
Str_Version_MPVersion:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x5BE, 0xA
; [nakarest] Str_Version_Empty4  +0x5c8..+0x5ca (0xe86516, 2 B)
; [nakarest] name string, entry 6 of ResName slot 0x3ef (table 0xe864d0, 11 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xef): "".
Str_Version_Empty4:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x5C8, 0x2
; [nakarest] Str_Version_Empty5  +0x5ca..+0x5cc (0xe86518, 2 B)
; [nakarest] name string, entry 5 of ResName slot 0x3ef (table 0xe864d0, 11 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xef): "".
Str_Version_Empty5:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x5CA, 0x2
; [nakarest] Str_Version_AllInitial  +0x5cc..+0x5d8 (0xe8651a, 12 B)
; [nakarest] name string, entry 4 of ResName slot 0x3ef (table 0xe864d0, 11 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xef): "AllInitial".
Str_Version_AllInitial:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x5CC, 0xC
; [nakarest] Str_Version_Empty6  +0x5d8..+0x5da (0xe86526, 2 B)
; [nakarest] name string, entry 3 of ResName slot 0x3ef (table 0xe864d0, 11 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xef): "".
Str_Version_Empty6:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x5D8, 0x2
; [nakarest] Str_Version_Empty7  +0x5da..+0x5dc (0xe86528, 2 B)
; [nakarest] name string, entry 2 of ResName slot 0x3ef (table 0xe864d0, 11 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xef): "".
Str_Version_Empty7:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x5DA, 0x2
; [nakarest] Str_Version_Empty8  +0x5dc..+0x5de (0xe8652a, 2 B)
; [nakarest] name string, entry 1 of ResName slot 0x3ef (table 0xe864d0, 11 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xef): "".
Str_Version_Empty8:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x5DC, 0x2
; [nakarest] Str_Version_Welcom  +0x5de..+0x5e6 (0xe8652c, 8 B)
; [nakarest] name string, entry 0 of ResName slot 0x3ef (table 0xe864d0, 11 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xef): "Welcom".
Str_Version_Welcom:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x5DE, 0x8
; [nakarest] naka_technichord_strings+0x5e6  +0x5e6..+0x5ea (0xe86534, 4 B)
; [nakarest] the table itself: ResName slot 0x3f0 (table 0xe86534, 6 entries, InitializeMurai),
; [nakarest] 6 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_technichord_strings.bin", 0x5E6, 0x4
; [nakarest] StrTable_SoftwareVersionComps  +0x5ea..+0x602 (0xe86538, 24 B)
; [nakarest] purpose not established: 4 bytes at 0xe8654c that no registered NAKA table points into
; [nakarest] Continues the table itself: ResName slot 0x3f0 (table 0xe86534, 6 entries,
; [nakarest] InitializeMurai), 6 entry pointers x 4 bytes (starts 0xe86534, 20 of its 24 bytes
; [nakarest] are here or later).
StrTable_SoftwareVersionComps:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x5EA, 0x18
; [nakarest] Str_SoftVer_Empty1  +0x602..+0x604 (0xe86550, 2 B)
; [nakarest] purpose not established: 2 bytes at 0xe86550 that no registered NAKA table points into
Str_SoftVer_Empty1:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x602, 0x2
; [nakarest] Str_SoftVer_Empty2  +0x604..+0x606 (0xe86552, 2 B)
; [nakarest] name string, entry 5 of ResName slot 0x3f0 (table 0xe86534, 6 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xf0): "".
Str_SoftVer_Empty2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x604, 0x2
; [nakarest] Str_SoftVer_SoundTable  +0x606..+0x612 (0xe86554, 12 B)
; [nakarest] name string, entry 4 of ResName slot 0x3f0 (table 0xe86534, 6 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xf0): "SoundTable".
Str_SoftVer_SoundTable:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x606, 0xC
; [nakarest] Str_SoftVer_SubProgram  +0x612..+0x61e (0xe86560, 12 B)
; [nakarest] name string, entry 3 of ResName slot 0x3f0 (table 0xe86534, 6 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xf0): "SubProgram".
Str_SoftVer_SubProgram:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x612, 0xC
; [nakarest] Str_SoftVer_MainTable  +0x61e..+0x628 (0xe8656c, 10 B)
; [nakarest] name string, entry 2 of ResName slot 0x3f0 (table 0xe86534, 6 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xf0): "MainTable".
Str_SoftVer_MainTable:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x61E, 0xA
; [nakarest] Str_SoftVer_MainProgram  +0x628..+0x634 (0xe86576, 12 B)
; [nakarest] name string, entry 1 of ResName slot 0x3f0 (table 0xe86534, 6 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xf0): "MainProgram".
Str_SoftVer_MainProgram:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x628, 0xC
; [nakarest] Str_SoftVer_Softver  +0x634..+0x6ea (0xe86582, 182 B)
; [nakarest] name string, entry 0 of ResName slot 0x3f0 (table 0xe86534, 6 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0xf0): "Softver".
Str_SoftVer_Softver:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x634, 0xB6
; [nakarest] naka_technichord_strings+0x6ea  +0x6ea..+0x6f6 (0xe86638, 12 B)
; [nakarest] the table itself: MainFunction slot 0x141 (table 0xe86638, 2 entries,
; [nakarest] InitializeMurai), 2 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_technichord_strings.bin", 0x6EA, 0xC
; [nakarest] naka_technichord_strings+0x6f6  +0x6f6..+0x702 (0xe86644, 12 B)
; [nakarest] the table itself: MainFunction slot 0x441 (table 0xe86644, 2 entries,
; [nakarest] InitializeMurai), 2 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_technichord_strings.bin", 0x6F6, 0xC
; [nakarest] Str_DrawCtrl_Empty  +0x702..+0x704 (0xe86650, 2 B)
; [nakarest] purpose not established: 2 bytes at 0xe86650 that no registered NAKA table points into
Str_DrawCtrl_Empty:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x702, 0x2
; [nakarest] Str_DrawCtrl_MainMemDrawCtrl  +0x704..+0x718 (0xe86652, 20 B)
; [nakarest] name string, entry 1 of MainFunction slot 0x441 (table 0xe86644, 2 entries,
; [nakarest] InitializeMurai) (names for MainFunction slot 0x141): "MainMemDrawControl".
Str_DrawCtrl_MainMemDrawCtrl:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x704, 0x14
; [nakarest] Str_DrawCtrl_MainPreControl  +0x718..+0x728 (0xe86666, 16 B)
; [nakarest] name string, entry 0 of MainFunction slot 0x441 (table 0xe86644, 2 entries,
; [nakarest] InitializeMurai) (names for MainFunction slot 0x141): "MainPreControl".
Str_DrawCtrl_MainPreControl:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x718, 0x10
; -----------------------------------------------------------------------------
; [nakarest_retype] Bitmap_Accita16
; Bitmap_Accita16  --  120 x 95 bitmap, 8 bpp, row stride 120, 11400 bytes
;
; What it shows (render): A piano accordion, body red, bellows black,
; keyboard on the left, on the green (index 0xf7) background. Same
; drawing as Bitmap_Accger16 with a different body colour; 'ita'/'ger'
; in the firmware's names presumably mean Italian/German -- an inference
; from the names, not from code.
;
; Reader: BitmapAccita16 (v10/v9 0xf7b46d, v7 0xf7b069) answers
; 0x1e000a1 with this address, 0x1e000a2 with 0x78 (width 120) and
; 0x1e000a3 with 0x5f (height 95). The routine is one entry of the
; 44-entry ApFunction table that InitializeMurai (v10/v9 0xf7ad77, v7
; 0xf7a973) registers with RegObjTabl 0x1600002, ApFunctionProc, 0x2c,
; 0xe8070a, slot 0x121 (naka_widget_tables_2.c member ptrs_341); its
; name string "BitmapAccita16" sits in the parallel name table at
; 0xe807be, slot 0x421. Drawn by the UserBitmap view class:
; VwUserBitmapProc (v10/v9 0xf9c54c, v7 0xf9c13f), on paint (0x1c0000d),
; calls the instance's function (+22 of the instance) with 0x1e000a1
; (address), 0x1e000a2 (width) and 0x1e000a3 (height) through ApFuncCall
; and hands the three to DrawBitmapSPFast (v10/v9 0xfac3db, v7
; 0xfabfce).
;
; Pixel format, from DrawBitmapSPFast_Impl (v10/v9 0xfac457, v7
; 0xfac04a): 8 bpp, one palette index per byte (palette:
; Palette_8bit_RGBA), rows top to bottom. The routine copies `width`
; bytes per row to VRAM 0x43c00 + 320*y + x with Mem_Copy and then
; advances the source by (width + 1) & ~1, so a row occupies the width
; rounded up to even; the pad byte of an odd-width row is never drawn.
;
; Dimensions pinned twice: the reader's own width/height constants, and
; width-rounded-to-even x height == the slice length. A PNG render
; (scripts/converters/nakarest_retype.py --render DIR) shows the drawing
; upright; a wrong width would shear it.
;
; Typed in naka_technichord_strings.c as uint8_t
; Bitmap_Accita16[95][120] (rows of 120 bytes).
; -----------------------------------------------------------------------------
Bitmap_Accita16:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x728, 0x2C88
; -----------------------------------------------------------------------------
; [nakarest_retype] Bitmap_Accger16
; Bitmap_Accger16  --  120 x 95 bitmap, 8 bpp, row stride 120, 11400 bytes
;
; What it shows (render): The same piano accordion as Bitmap_Accita16
; with the body grey instead of red.
;
; Reader: BitmapAccger16 (v10/v9 0xf7b49a, v7 0xf7b096) answers
; 0x1e000a1 with this address, 0x1e000a2 with 0x78 (width 120) and
; 0x1e000a3 with 0x5f (height 95). The routine is one entry of the
; 44-entry ApFunction table that InitializeMurai (v10/v9 0xf7ad77, v7
; 0xf7a973) registers with RegObjTabl 0x1600002, ApFunctionProc, 0x2c,
; 0xe8070a, slot 0x121 (naka_widget_tables_2.c member ptrs_341); its
; name string "BitmapAccger16" sits in the parallel name table at
; 0xe807be, slot 0x421. Drawn by the UserBitmap view class:
; VwUserBitmapProc (v10/v9 0xf9c54c, v7 0xf9c13f), on paint (0x1c0000d),
; calls the instance's function (+22 of the instance) with 0x1e000a1
; (address), 0x1e000a2 (width) and 0x1e000a3 (height) through ApFuncCall
; and hands the three to DrawBitmapSPFast (v10/v9 0xfac3db, v7
; 0xfabfce).
;
; Pixel format, from DrawBitmapSPFast_Impl (v10/v9 0xfac457, v7
; 0xfac04a): 8 bpp, one palette index per byte (palette:
; Palette_8bit_RGBA), rows top to bottom. The routine copies `width`
; bytes per row to VRAM 0x43c00 + 320*y + x with Mem_Copy and then
; advances the source by (width + 1) & ~1, so a row occupies the width
; rounded up to even; the pad byte of an odd-width row is never drawn.
;
; Dimensions pinned twice: the reader's own width/height constants, and
; width-rounded-to-even x height == the slice length. A PNG render
; (scripts/converters/nakarest_retype.py --render DIR) shows the drawing
; upright; a wrong width would shear it.
;
; Typed in naka_technichord_strings.c as uint8_t
; Bitmap_Accger16[95][120] (rows of 120 bytes).
; -----------------------------------------------------------------------------
Bitmap_Accger16:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x33B0, 0x2C88
; -----------------------------------------------------------------------------
; [nakarest_retype] Bitmap_SomeArrows
; Bitmap_SomeArrows  --  294 x 6 bitmap, 8 bpp, row stride 294, 1764 bytes
;
; What it shows (render): A 294 x 6 strip of red slanted wedge marks on
; the green background, spaced unevenly across the width. What it marks
; on screen was not traced (the instance that uses BitmapDrawsw was not
; followed); the label name Bitmap_SomeArrows predates this header.
;
; Reader: BitmapDrawsw (v10/v9 0xf7b4c7, v7 0xf7b0c3) answers 0x1e000a1
; with this address, 0x1e000a2 with 0x126 (width 294) and 0x1e000a3 with
; 0x6 (height 6). The routine is one entry of the 44-entry ApFunction
; table that InitializeMurai (v10/v9 0xf7ad77, v7 0xf7a973) registers
; with RegObjTabl 0x1600002, ApFunctionProc, 0x2c, 0xe8070a, slot 0x121
; (naka_widget_tables_2.c member ptrs_341); its name string
; "BitmapDrawsw" sits in the parallel name table at 0xe807be, slot
; 0x421. Drawn by the UserBitmap view class: VwUserBitmapProc (v10/v9
; 0xf9c54c, v7 0xf9c13f), on paint (0x1c0000d), calls the instance's
; function (+22 of the instance) with 0x1e000a1 (address), 0x1e000a2
; (width) and 0x1e000a3 (height) through ApFuncCall and hands the three
; to DrawBitmapSPFast (v10/v9 0xfac3db, v7 0xfabfce).
;
; Pixel format, from DrawBitmapSPFast_Impl (v10/v9 0xfac457, v7
; 0xfac04a): 8 bpp, one palette index per byte (palette:
; Palette_8bit_RGBA), rows top to bottom. The routine copies `width`
; bytes per row to VRAM 0x43c00 + 320*y + x with Mem_Copy and then
; advances the source by (width + 1) & ~1, so a row occupies the width
; rounded up to even; the pad byte of an odd-width row is never drawn.
;
; Dimensions pinned twice: the reader's own width/height constants, and
; width-rounded-to-even x height == the slice length. A PNG render
; (scripts/converters/nakarest_retype.py --render DIR) shows the drawing
; upright; a wrong width would shear it.
;
; Typed in naka_technichord_strings.c as uint8_t
; Bitmap_SomeArrows[6][294] (rows of 294 bytes).
; -----------------------------------------------------------------------------
Bitmap_SomeArrows:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x6038, 0x6E4
; -----------------------------------------------------------------------------
; [nakarest_retype] Bitmap_DrawbarNumberedSlider_1
; Bitmap_DrawbarNumberedSlider_1  --  22 x 222 bitmap, 8 bpp, row stride 22, 4884 bytes
;
; What it shows (render): A drawbar: a black scale numbered 8 (top) to 1
; with tick marks, above a BROWN (dark red) handle and a grey shaft.
;
; Reader: Width and height: one of three near-identical handlers in
; ui/drawbar_panel_ui.s that start at Bitmap_QueryProperties3x (v10/v9
; 0xf7b4f1, v7 0xf7b0ed) (the first is labelled; the second and third
; follow it unlabelled): each answers 0x1e000a1 with one slider bitmap's
; address, 0x1e000a2 with 22 (width) and 0x1e000a3 with 222 (height),
; which is how the 22 x 222 shape is pinned. None of the three handler
; entry points (0xf7b4f1, 0xf7b51e, 0xf7b54b in v10) occurs as a 32-bit
; or 24-bit little-endian value anywhere in the v10 program, table data,
; custom data or HD-AE5000 images (searched 2026-09-25): what reaches
; them, if anything, was not found. The bitmaps themselves are also
; pointed at by a 9-entry table inside Naka_DrawbarSlider_Resources
; (naka_sequencer_channels.c member ptrs_5, 0xeeefcc) in the order
; 1,1,2,2,3,2,3,3,2 -- the colour sequence of the nine organ drawbars
; (16' and 5 1/3' brown; 8', 4' white; 2 2/3' black; 2' white; 1 3/5'
; and 1 1/3' black; 1' white), which matches the renders: _1 has a brown
; handle, _2 white, _3 black. The reader of that table was not traced.
;
; Pixel format, from DrawBitmapSPFast_Impl (v10/v9 0xfac457, v7
; 0xfac04a): 8 bpp, one palette index per byte (palette:
; Palette_8bit_RGBA), rows top to bottom. The routine copies `width`
; bytes per row to VRAM 0x43c00 + 320*y + x with Mem_Copy and then
; advances the source by (width + 1) & ~1, so a row occupies the width
; rounded up to even; the pad byte of an odd-width row is never drawn.
;
; Dimensions pinned twice: the reader's own width/height constants, and
; width-rounded-to-even x height == the slice length. A PNG render
; (scripts/converters/nakarest_retype.py --render DIR) shows the drawing
; upright; a wrong width would shear it.
;
; Typed in naka_technichord_strings.c as uint8_t
; Bitmap_DrawbarNumberedSlider_1[222][22] (rows of 22 bytes).
; -----------------------------------------------------------------------------
BitmapBound_DrawbarSlider1_Start:
Bitmap_DrawbarNumberedSlider_1:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x671C, 0x1314
; -----------------------------------------------------------------------------
; [nakarest_retype] Bitmap_DrawbarNumberedSlider_2
; Bitmap_DrawbarNumberedSlider_2  --  22 x 222 bitmap, 8 bpp, row stride 22, 4884 bytes
;
; What it shows (render): The same drawbar with a WHITE handle.
;
; Reader: Width and height: one of three near-identical handlers in
; ui/drawbar_panel_ui.s that start at Bitmap_QueryProperties3x (v10/v9
; 0xf7b4f1, v7 0xf7b0ed) (the first is labelled; the second and third
; follow it unlabelled): each answers 0x1e000a1 with one slider bitmap's
; address, 0x1e000a2 with 22 (width) and 0x1e000a3 with 222 (height),
; which is how the 22 x 222 shape is pinned. None of the three handler
; entry points (0xf7b4f1, 0xf7b51e, 0xf7b54b in v10) occurs as a 32-bit
; or 24-bit little-endian value anywhere in the v10 program, table data,
; custom data or HD-AE5000 images (searched 2026-09-25): what reaches
; them, if anything, was not found. The bitmaps themselves are also
; pointed at by a 9-entry table inside Naka_DrawbarSlider_Resources
; (naka_sequencer_channels.c member ptrs_5, 0xeeefcc) in the order
; 1,1,2,2,3,2,3,3,2 -- the colour sequence of the nine organ drawbars
; (16' and 5 1/3' brown; 8', 4' white; 2 2/3' black; 2' white; 1 3/5'
; and 1 1/3' black; 1' white), which matches the renders: _1 has a brown
; handle, _2 white, _3 black. The reader of that table was not traced.
;
; Pixel format, from DrawBitmapSPFast_Impl (v10/v9 0xfac457, v7
; 0xfac04a): 8 bpp, one palette index per byte (palette:
; Palette_8bit_RGBA), rows top to bottom. The routine copies `width`
; bytes per row to VRAM 0x43c00 + 320*y + x with Mem_Copy and then
; advances the source by (width + 1) & ~1, so a row occupies the width
; rounded up to even; the pad byte of an odd-width row is never drawn.
;
; Dimensions pinned twice: the reader's own width/height constants, and
; width-rounded-to-even x height == the slice length. A PNG render
; (scripts/converters/nakarest_retype.py --render DIR) shows the drawing
; upright; a wrong width would shear it.
;
; Typed in naka_technichord_strings.c as uint8_t
; Bitmap_DrawbarNumberedSlider_2[222][22] (rows of 22 bytes).
; -----------------------------------------------------------------------------
BitmapBound_DrawbarSlider2_Start:
Bitmap_DrawbarNumberedSlider_2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x7A30, 0x1314
; -----------------------------------------------------------------------------
; [nakarest_retype] Bitmap_DrawbarNumberedSlider_3
; Bitmap_DrawbarNumberedSlider_3  --  22 x 222 bitmap, 8 bpp, row stride 22, 4884 bytes
;
; What it shows (render): The same drawbar with a BLACK handle.
;
; Reader: Width and height: one of three near-identical handlers in
; ui/drawbar_panel_ui.s that start at Bitmap_QueryProperties3x (v10/v9
; 0xf7b4f1, v7 0xf7b0ed) (the first is labelled; the second and third
; follow it unlabelled): each answers 0x1e000a1 with one slider bitmap's
; address, 0x1e000a2 with 22 (width) and 0x1e000a3 with 222 (height),
; which is how the 22 x 222 shape is pinned. None of the three handler
; entry points (0xf7b4f1, 0xf7b51e, 0xf7b54b in v10) occurs as a 32-bit
; or 24-bit little-endian value anywhere in the v10 program, table data,
; custom data or HD-AE5000 images (searched 2026-09-25): what reaches
; them, if anything, was not found. The bitmaps themselves are also
; pointed at by a 9-entry table inside Naka_DrawbarSlider_Resources
; (naka_sequencer_channels.c member ptrs_5, 0xeeefcc) in the order
; 1,1,2,2,3,2,3,3,2 -- the colour sequence of the nine organ drawbars
; (16' and 5 1/3' brown; 8', 4' white; 2 2/3' black; 2' white; 1 3/5'
; and 1 1/3' black; 1' white), which matches the renders: _1 has a brown
; handle, _2 white, _3 black. The reader of that table was not traced.
;
; Pixel format, from DrawBitmapSPFast_Impl (v10/v9 0xfac457, v7
; 0xfac04a): 8 bpp, one palette index per byte (palette:
; Palette_8bit_RGBA), rows top to bottom. The routine copies `width`
; bytes per row to VRAM 0x43c00 + 320*y + x with Mem_Copy and then
; advances the source by (width + 1) & ~1, so a row occupies the width
; rounded up to even; the pad byte of an odd-width row is never drawn.
;
; Dimensions pinned twice: the reader's own width/height constants, and
; width-rounded-to-even x height == the slice length. A PNG render
; (scripts/converters/nakarest_retype.py --render DIR) shows the drawing
; upright; a wrong width would shear it.
;
; Typed in naka_technichord_strings.c as uint8_t
; Bitmap_DrawbarNumberedSlider_3[222][22] (rows of 22 bytes).
; -----------------------------------------------------------------------------
BitmapBound_DrawbarSlider3_Start:
Bitmap_DrawbarNumberedSlider_3:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x8D44, 0x1314
; -----------------------------------------------------------------------------
; [nakarest_retype] Bitmap_Technics_Logo
; Bitmap_Technics_Logo  --  312 x 45 bitmap, 8 bpp, row stride 312, 14040 bytes
;
; What it shows (render): The word Technics in the brand's serif
; logotype, black on green.
;
; Reader: BitmapTechnics (v10/v9 0xf7b578, v7 0xf7b174) answers
; 0x1e000a1 with this address, 0x1e000a2 with 0x138 (width 312) and
; 0x1e000a3 with 0x2d (height 45). The routine is one entry of the
; 44-entry ApFunction table that InitializeMurai (v10/v9 0xf7ad77, v7
; 0xf7a973) registers with RegObjTabl 0x1600002, ApFunctionProc, 0x2c,
; 0xe8070a, slot 0x121 (naka_widget_tables_2.c member ptrs_341); its
; name string "BitmapTechnics" sits in the parallel name table at
; 0xe807be, slot 0x421. Drawn by the UserBitmap view class:
; VwUserBitmapProc (v10/v9 0xf9c54c, v7 0xf9c13f), on paint (0x1c0000d),
; calls the instance's function (+22 of the instance) with 0x1e000a1
; (address), 0x1e000a2 (width) and 0x1e000a3 (height) through ApFuncCall
; and hands the three to DrawBitmapSPFast (v10/v9 0xfac3db, v7
; 0xfabfce).
;
; Pixel format, from DrawBitmapSPFast_Impl (v10/v9 0xfac457, v7
; 0xfac04a): 8 bpp, one palette index per byte (palette:
; Palette_8bit_RGBA), rows top to bottom. The routine copies `width`
; bytes per row to VRAM 0x43c00 + 320*y + x with Mem_Copy and then
; advances the source by (width + 1) & ~1, so a row occupies the width
; rounded up to even; the pad byte of an odd-width row is never drawn.
;
; Dimensions pinned twice: the reader's own width/height constants, and
; width-rounded-to-even x height == the slice length. A PNG render
; (scripts/converters/nakarest_retype.py --render DIR) shows the drawing
; upright; a wrong width would shear it.
;
; Typed in naka_technichord_strings.c as uint8_t
; Bitmap_Technics_Logo[45][312] (rows of 312 bytes).
; -----------------------------------------------------------------------------
Bitmap_Technics_Logo:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xA058, 0x36D8
; -----------------------------------------------------------------------------
; [nakarest_retype] Bitmap_KN5000_Logo
; Bitmap_KN5000_Logo  --  199 x 36 bitmap, 8 bpp, row stride 200, 7200 bytes
;
; What it shows (render): 'KN-5000' in black italic sans-serif on green.
;
; Reader: BitmapKn5000 (v10/v9 0xf7b5a5, v7 0xf7b1a1) answers 0x1e000a1
; with this address, 0x1e000a2 with 0xc7 (width 199) and 0x1e000a3 with
; 0x24 (height 36). The routine is one entry of the 44-entry ApFunction
; table that InitializeMurai (v10/v9 0xf7ad77, v7 0xf7a973) registers
; with RegObjTabl 0x1600002, ApFunctionProc, 0x2c, 0xe8070a, slot 0x121
; (naka_widget_tables_2.c member ptrs_341); its name string
; "BitmapKn5000" sits in the parallel name table at 0xe807be, slot
; 0x421. Drawn by the UserBitmap view class: VwUserBitmapProc (v10/v9
; 0xf9c54c, v7 0xf9c13f), on paint (0x1c0000d), calls the instance's
; function (+22 of the instance) with 0x1e000a1 (address), 0x1e000a2
; (width) and 0x1e000a3 (height) through ApFuncCall and hands the three
; to DrawBitmapSPFast (v10/v9 0xfac3db, v7 0xfabfce).
;
; Pixel format, from DrawBitmapSPFast_Impl (v10/v9 0xfac457, v7
; 0xfac04a): 8 bpp, one palette index per byte (palette:
; Palette_8bit_RGBA), rows top to bottom. The routine copies `width`
; bytes per row to VRAM 0x43c00 + 320*y + x with Mem_Copy and then
; advances the source by (width + 1) & ~1, so a row occupies the width
; rounded up to even; the pad byte of an odd-width row is never drawn.
;
; Dimensions pinned twice: the reader's own width/height constants, and
; width-rounded-to-even x height == the slice length. A PNG render
; (scripts/converters/nakarest_retype.py --render DIR) shows the drawing
; upright; a wrong width would shear it.
;
; Typed in naka_technichord_strings.c as uint8_t
; Bitmap_KN5000_Logo[36][200] (rows of 200 bytes).
; -----------------------------------------------------------------------------
Bitmap_KN5000_Logo:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xD730, 0x1C20
; [nakarest] Str_Mixer_ON  +0xf350..+0xf354 (0xe9529e, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe9529e that no registered NAKA table points into
Str_Mixer_ON:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF350, 0x4
; [nakarest] MixerPartTable_Start  +0xf354..+0xf4bc (0xe952a2, 360 B)
; [nakarest] purpose not established: 360 bytes at 0xe952a2 that no registered NAKA table points into
MixerPartTable_Start:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF354, 0x168
; [nakarest] Str_PartName_Empty  +0xf4bc..+0xf4c6 (0xe9540a, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9540a that no registered NAKA table points into
Str_PartName_Empty:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF4BC, 0xA
; [nakarest] Str_PartName_Rhythm  +0xf4c6..+0xf4d2 (0xe95414, 12 B)
; [nakarest] purpose not established: 12 bytes at 0xe95414 that no registered NAKA table points into
Str_PartName_Rhythm:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF4C6, 0xC
; [nakarest] Str_PartName_Control  +0xf4d2..+0xf4dc (0xe95420, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe95420 that no registered NAKA table points into
Str_PartName_Control:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF4D2, 0xA
; [nakarest] Str_PartName_APC  +0xf4dc..+0xf4e6 (0xe9542a, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9542a that no registered NAKA table points into
Str_PartName_APC:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF4DC, 0xA
; [nakarest] Str_PartName_MIC  +0xf4e6..+0xf4f0 (0xe95434, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe95434 that no registered NAKA table points into
Str_PartName_MIC:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF4E6, 0xA
; [nakarest] Str_PartName_Metronome  +0xf4f0..+0xf4fa (0xe9543e, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9543e that no registered NAKA table points into
Str_PartName_Metronome:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF4F0, 0xA
; [nakarest] Str_PartName_MSP  +0xf4fa..+0xf504 (0xe95448, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe95448 that no registered NAKA table points into
Str_PartName_MSP:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF4FA, 0xA
; [nakarest] Str_PartName_Drums  +0xf504..+0xf50e (0xe95452, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe95452 that no registered NAKA table points into
Str_PartName_Drums:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF504, 0xA
; [nakarest] Str_PartName_Bass  +0xf50e..+0xf51a (0xe9545c, 12 B)
; [nakarest] purpose not established: 12 bytes at 0xe9545c that no registered NAKA table points into
Str_PartName_Bass:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF50E, 0xC
; [nakarest] Str_PartName_Accomp3  +0xf51a..+0xf524 (0xe95468, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe95468 that no registered NAKA table points into
Str_PartName_Accomp3:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF51A, 0xA
; [nakarest] Str_PartName_Accomp2  +0xf524..+0xf52e (0xe95472, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe95472 that no registered NAKA table points into
Str_PartName_Accomp2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF524, 0xA
; [nakarest] Str_PartName_Accomp1  +0xf52e..+0xf538 (0xe9547c, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9547c that no registered NAKA table points into
Str_PartName_Accomp1:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF52E, 0xA
; [nakarest] Str_PartName_RBass  +0xf538..+0xf544 (0xe95486, 12 B)
; [nakarest] purpose not established: 12 bytes at 0xe95486 that no registered NAKA table points into
Str_PartName_RBass:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF538, 0xC
; [nakarest] Str_PartName_Chord  +0xf544..+0xf54e (0xe95492, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe95492 that no registered NAKA table points into
Str_PartName_Chord:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF544, 0xA
; [nakarest] Str_PartName_Part16  +0xf54e..+0xf558 (0xe9549c, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9549c that no registered NAKA table points into
Str_PartName_Part16:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF54E, 0xA
; [nakarest] Str_PartName_Part15  +0xf558..+0xf562 (0xe954a6, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe954a6 that no registered NAKA table points into
Str_PartName_Part15:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF558, 0xA
; [nakarest] Str_PartName_Part14  +0xf562..+0xf56c (0xe954b0, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe954b0 that no registered NAKA table points into
Str_PartName_Part14:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF562, 0xA
; [nakarest] Str_PartName_Part13  +0xf56c..+0xf576 (0xe954ba, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe954ba that no registered NAKA table points into
Str_PartName_Part13:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF56C, 0xA
; [nakarest] Str_PartName_Part12  +0xf576..+0xf580 (0xe954c4, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe954c4 that no registered NAKA table points into
Str_PartName_Part12:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF576, 0xA
; [nakarest] Str_PartName_Part11  +0xf580..+0xf58a (0xe954ce, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe954ce that no registered NAKA table points into
Str_PartName_Part11:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF580, 0xA
; [nakarest] Str_PartName_Part10  +0xf58a..+0xf594 (0xe954d8, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe954d8 that no registered NAKA table points into
Str_PartName_Part10:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF58A, 0xA
; [nakarest] Str_PartName_Part9  +0xf594..+0xf5a0 (0xe954e2, 12 B)
; [nakarest] purpose not established: 12 bytes at 0xe954e2 that no registered NAKA table points into
Str_PartName_Part9:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF594, 0xC
; [nakarest] Str_PartName_Part8  +0xf5a0..+0xf5ac (0xe954ee, 12 B)
; [nakarest] purpose not established: 12 bytes at 0xe954ee that no registered NAKA table points into
Str_PartName_Part8:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF5A0, 0xC
; [nakarest] Str_PartName_Part7  +0xf5ac..+0xf5b8 (0xe954fa, 12 B)
; [nakarest] purpose not established: 12 bytes at 0xe954fa that no registered NAKA table points into
Str_PartName_Part7:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF5AC, 0xC
; [nakarest] Str_PartName_Part6  +0xf5b8..+0xf5c4 (0xe95506, 12 B)
; [nakarest] purpose not established: 12 bytes at 0xe95506 that no registered NAKA table points into
Str_PartName_Part6:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF5B8, 0xC
; [nakarest] Str_PartName_Part5  +0xf5c4..+0xf5d0 (0xe95512, 12 B)
; [nakarest] purpose not established: 12 bytes at 0xe95512 that no registered NAKA table points into
Str_PartName_Part5:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF5C4, 0xC
; [nakarest] Str_PartName_Part4  +0xf5d0..+0xf5dc (0xe9551e, 12 B)
; [nakarest] purpose not established: 12 bytes at 0xe9551e that no registered NAKA table points into
Str_PartName_Part4:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF5D0, 0xC
; [nakarest] Str_PartName_Left  +0xf5dc..+0xf5e8 (0xe9552a, 12 B)
; [nakarest] purpose not established: 12 bytes at 0xe9552a that no registered NAKA table points into
Str_PartName_Left:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF5DC, 0xC
; [nakarest] Str_PartName_Right2  +0xf5e8..+0xf5f2 (0xe95536, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe95536 that no registered NAKA table points into
Str_PartName_Right2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF5E8, 0xA
; [nakarest] Str_PartName_Right1  +0xf5f2..+0xf720 (0xe95540, 302 B)
; [nakarest] purpose not established: 302 bytes at 0xe95540 that no registered NAKA table points into
Str_PartName_Right1:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF5F2, 0x12E
; [nakarest] StrTable_LangHeaders  +0xf720..+0xf738 (0xe9566e, 24 B)
; [nakarest] purpose not established: 24 bytes at 0xe9566e that no registered NAKA table points into
StrTable_LangHeaders:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF720, 0x18
; [nakarest] Str_Header_Indonesian  +0xf738..+0xf74a (0xe95686, 18 B)
; [nakarest] purpose not established: 18 bytes at 0xe95686 that no registered NAKA table points into
Str_Header_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF738, 0x12
; [nakarest] Str_Header_Italian  +0xf74a..+0xf75a (0xe95698, 16 B)
; [nakarest] purpose not established: 16 bytes at 0xe95698 that no registered NAKA table points into
Str_Header_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF74A, 0x10
; [nakarest] Str_Header_Spanish  +0xf75a..+0xf76a (0xe956a8, 16 B)
; [nakarest] purpose not established: 16 bytes at 0xe956a8 that no registered NAKA table points into
Str_Header_Spanish:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF75A, 0x10
; [nakarest] Str_Header_French  +0xf76a..+0xf778 (0xe956b8, 14 B)
; [nakarest] purpose not established: 14 bytes at 0xe956b8 that no registered NAKA table points into
Str_Header_French:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF76A, 0xE
; [nakarest] Str_Header_German  +0xf778..+0xf786 (0xe956c6, 14 B)
; [nakarest] purpose not established: 14 bytes at 0xe956c6 that no registered NAKA table points into
Str_Header_German:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF778, 0xE
; [nakarest] Str_Header_English  +0xf786..+0xf796 (0xe956d4, 16 B)
; [nakarest] purpose not established: 16 bytes at 0xe956d4 that no registered NAKA table points into
Str_Header_English:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF786, 0x10
; [nakarest] StrTable_LangTexts  +0xf796..+0xf7ae (0xe956e4, 24 B)
; [nakarest] purpose not established: 24 bytes at 0xe956e4 that no registered NAKA table points into
StrTable_LangTexts:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF796, 0x18
; [nakarest] Str_Text_Indonesian  +0xf7ae..+0xf7be (0xe956fc, 16 B)
; [nakarest] purpose not established: 16 bytes at 0xe956fc that no registered NAKA table points into
Str_Text_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF7AE, 0x10
; [nakarest] Str_Text_Italian  +0xf7be..+0xf7cc (0xe9570c, 14 B)
; [nakarest] purpose not established: 14 bytes at 0xe9570c that no registered NAKA table points into
Str_Text_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF7BE, 0xE
; [nakarest] Str_Text_Spanish  +0xf7cc..+0xf7da (0xe9571a, 14 B)
; [nakarest] purpose not established: 14 bytes at 0xe9571a that no registered NAKA table points into
Str_Text_Spanish:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF7CC, 0xE
; [nakarest] Str_Text_French  +0xf7da..+0xf7e6 (0xe95728, 12 B)
; [nakarest] purpose not established: 12 bytes at 0xe95728 that no registered NAKA table points into
Str_Text_French:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF7DA, 0xC
; [nakarest] Str_Text_German  +0xf7e6..+0xf7f2 (0xe95734, 12 B)
; [nakarest] purpose not established: 12 bytes at 0xe95734 that no registered NAKA table points into
Str_Text_German:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF7E6, 0xC
; [nakarest] Str_Text_English  +0xf7f2..+0xf800 (0xe95740, 14 B)
; [nakarest] purpose not established: 14 bytes at 0xe95740 that no registered NAKA table points into
Str_Text_English:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF7F2, 0xE
; [nakarest] StrTable_ErrorLabel  +0xf800..+0xf818 (0xe9574e, 24 B)
; [nakarest] purpose not established: 24 bytes at 0xe9574e that no registered NAKA table points into
StrTable_ErrorLabel:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF800, 0x18
; [nakarest] Str_ErrorLabel_Indonesian  +0xf818..+0xf81e (0xe95766, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe95766 that no registered NAKA table points into
Str_ErrorLabel_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF818, 0x6
; [nakarest] Str_ErrorLabel_Italian  +0xf81e..+0xf824 (0xe9576c, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9576c that no registered NAKA table points into
Str_ErrorLabel_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF81E, 0x6
; [nakarest] Str_ErrorLabel_Spanish  +0xf824..+0xf82a (0xe95772, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe95772 that no registered NAKA table points into
Str_ErrorLabel_Spanish:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF824, 0x6
; [nakarest] Str_ErrorLabel_French  +0xf82a..+0xf832 (0xe95778, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe95778 that no registered NAKA table points into
Str_ErrorLabel_French:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF82A, 0x8
; [nakarest] Str_ErrorLabel_German  +0xf832..+0xf838 (0xe95780, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe95780 that no registered NAKA table points into
Str_ErrorLabel_German:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF832, 0x6
; [nakarest] Str_ErrorLabel_English  +0xf838..+0xf842 (0xe95786, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe95786 that no registered NAKA table points into
Str_ErrorLabel_English:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF838, 0xA
; [nakarest] StrTable_ReminderLabel  +0xf842..+0xf856 (0xe95790, 20 B)
; [nakarest] purpose not established: 20 bytes at 0xe95790 that no registered NAKA table points into
StrTable_ReminderLabel:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF842, 0x14
; [nakarest] Str_Reminder_Indonesian  +0xf856..+0xf862 (0xe957a4, 12 B)
; [nakarest] purpose not established: 12 bytes at 0xe957a4 that no registered NAKA table points into
Str_Reminder_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF856, 0xC
; [nakarest] Str_Reminder_Italian  +0xf862..+0xf86e (0xe957b0, 12 B)
; [nakarest] purpose not established: 12 bytes at 0xe957b0 that no registered NAKA table points into
Str_Reminder_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF862, 0xC
; [nakarest] Str_Reminder_Spanish  +0xf86e..+0xf87a (0xe957bc, 12 B)
; [nakarest] purpose not established: 12 bytes at 0xe957bc that no registered NAKA table points into
Str_Reminder_Spanish:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF86E, 0xC
; [nakarest] Str_Reminder_French  +0xf87a..+0xf884 (0xe957c8, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe957c8 that no registered NAKA table points into
Str_Reminder_French:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF87A, 0xA
; [nakarest] Str_Reminder_German  +0xf884..+0xf89c (0xe957d2, 24 B)
; [nakarest] purpose not established: 24 bytes at 0xe957d2 that no registered NAKA table points into
Str_Reminder_German:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF884, 0x18
; [nakarest] StrTable_CompletedLabel  +0xf89c..+0xf8b4 (0xe957ea, 24 B)
; [nakarest] purpose not established: 24 bytes at 0xe957ea that no registered NAKA table points into
StrTable_CompletedLabel:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF89C, 0x18
; [nakarest] Str_Completed_Indonesian  +0xf8b4..+0xf8c2 (0xe95802, 14 B)
; [nakarest] purpose not established: 14 bytes at 0xe95802 that no registered NAKA table points into
Str_Completed_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF8B4, 0xE
; [nakarest] Str_Completed_Italian  +0xf8c2..+0xf904 (0xe95810, 66 B)
; [nakarest] purpose not established: 66 bytes at 0xe95810 that no registered NAKA table points into
Str_Completed_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF8C2, 0x42
; [nakarest] StrTable_PleaseWaitLabel  +0xf904..+0xf91c (0xe95852, 24 B)
; [nakarest] purpose not established: 24 bytes at 0xe95852 that no registered NAKA table points into
StrTable_PleaseWaitLabel:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF904, 0x18
; [nakarest] Str_PleaseWait_Indonesian  +0xf91c..+0xf92e (0xe9586a, 18 B)
; [nakarest] purpose not established: 18 bytes at 0xe9586a that no registered NAKA table points into
Str_PleaseWait_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF91C, 0x12
; [nakarest] Str_PleaseWait_Italian  +0xf92e..+0xf998 (0xe9587c, 106 B)
; [nakarest] purpose not established: 106 bytes at 0xe9587c that no registered NAKA table points into
Str_PleaseWait_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF92E, 0x6A
; [nakarest] Str_MemReminder_Indonesian  +0xf998..+0xfa12 (0xe958e6, 122 B)
; [nakarest] purpose not established: 122 bytes at 0xe958e6 that no registered NAKA table points into
Str_MemReminder_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xF998, 0x7A
; [nakarest] Str_MemReminder_Italian  +0xfa12..+0xfc3a (0xe95960, 552 B)
; [nakarest] purpose not established: 552 bytes at 0xe95960 that no registered NAKA table points into
Str_MemReminder_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xFA12, 0x228
; [nakarest] StrTable_SettingsNotSaved  +0xfc3a..+0xfc52 (0xe95b88, 24 B)
; [nakarest] purpose not established: 24 bytes at 0xe95b88 that no registered NAKA table points into
StrTable_SettingsNotSaved:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xFC3A, 0x18
; [nakarest] Str_SettingsNotSaved_ID  +0xfc52..+0xfce4 (0xe95ba0, 146 B)
; [nakarest] purpose not established: 146 bytes at 0xe95ba0 that no registered NAKA table points into
Str_SettingsNotSaved_ID:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xFC52, 0x92
; [nakarest] Str_SettingsNotSaved_IT  +0xfce4..+0xfcee (0xe95c32, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe95c32 that no registered NAKA table points into
Str_SettingsNotSaved_IT:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xFCE4, 0xA
; [nakarest] Str_SettingsNotSaved_ES  +0xfcee..+0xfdc0 (0xe95c3c, 210 B)
; [nakarest] purpose not established: 210 bytes at 0xe95c3c that no registered NAKA table points into
Str_SettingsNotSaved_ES:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xFCEE, 0xD2
; [nakarest] Str_SettingsNotSaved_FR  +0xfdc0..+0xfe5e (0xe95d0e, 158 B)
; [nakarest] purpose not established: 158 bytes at 0xe95d0e that no registered NAKA table points into
Str_SettingsNotSaved_FR:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xFDC0, 0x9E
; [nakarest] Str_SettingsNotSaved_DE  +0xfe5e..+0xff04 (0xe95dac, 166 B)
; [nakarest] purpose not established: 166 bytes at 0xe95dac that no registered NAKA table points into
Str_SettingsNotSaved_DE:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xFE5E, 0xA6
; [nakarest] Str_SettingsNotSaved_EN  +0xff04..+0xffac (0xe95e52, 168 B)
; [nakarest] purpose not established: 168 bytes at 0xe95e52 that no registered NAKA table points into
Str_SettingsNotSaved_EN:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xFF04, 0xA8
; [nakarest] StrTable_GenericError  +0xffac..+0xffc4 (0xe95efa, 24 B)
; [nakarest] purpose not established: 24 bytes at 0xe95efa that no registered NAKA table points into
StrTable_GenericError:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xFFAC, 0x18
; [nakarest] Str_GenericErr_Indonesian  +0xffc4..+0xffcc (0xe95f12, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe95f12 that no registered NAKA table points into
Str_GenericErr_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xFFC4, 0x8
; [nakarest] Str_GenericErr_Italian  +0xffcc..+0xffd4 (0xe95f1a, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe95f1a that no registered NAKA table points into
Str_GenericErr_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xFFCC, 0x8
; [nakarest] Str_GenericErr_Spanish  +0xffd4..+0xffdc (0xe95f22, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe95f22 that no registered NAKA table points into
Str_GenericErr_Spanish:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xFFD4, 0x8
; [nakarest] Str_GenericErr_French  +0xffdc..+0xffe4 (0xe95f2a, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe95f2a that no registered NAKA table points into
Str_GenericErr_French:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xFFDC, 0x8
; [nakarest] Str_GenericErr_German  +0xffe4..+0xffec (0xe95f32, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe95f32 that no registered NAKA table points into
Str_GenericErr_German:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xFFE4, 0x8
; [nakarest] Str_GenericErr_English  +0xffec..+0x1000c (0xe95f3a, 32 B)
; [nakarest] purpose not established: 32 bytes at 0xe95f3a that no registered NAKA table points into
Str_GenericErr_English:
	.incbin "includes/generated/naka_technichord_strings.bin", 0xFFEC, 0x20
; [nakarest] Str_DiskErr00_Indonesian  +0x1000c..+0x1005a (0xe95f5a, 78 B)
; [nakarest] purpose not established: 78 bytes at 0xe95f5a that no registered NAKA table points into
Str_DiskErr00_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1000C, 0x4E
; [nakarest] Str_DiskErr00_Italian  +0x1005a..+0x1018a (0xe95fa8, 304 B)
; [nakarest] purpose not established: 304 bytes at 0xe95fa8 that no registered NAKA table points into
Str_DiskErr00_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1005A, 0x130
; [nakarest] StrTable_DiskErr01  +0x1018a..+0x101a2 (0xe960d8, 24 B)
; [nakarest] purpose not established: 24 bytes at 0xe960d8 that no registered NAKA table points into
StrTable_DiskErr01:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1018A, 0x18
; [nakarest] Str_DiskErr01_Indonesian  +0x101a2..+0x101ee (0xe960f0, 76 B)
; [nakarest] purpose not established: 76 bytes at 0xe960f0 that no registered NAKA table points into
Str_DiskErr01_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x101A2, 0x4C
; [nakarest] Str_DiskErr01_Italian  +0x101ee..+0x101f8 (0xe9613c, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9613c that no registered NAKA table points into
Str_DiskErr01_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x101EE, 0xA
; [nakarest] Str_DiskErr01_Spanish  +0x101f8..+0x10240 (0xe96146, 72 B)
; [nakarest] purpose not established: 72 bytes at 0xe96146 that no registered NAKA table points into
Str_DiskErr01_Spanish:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x101F8, 0x48
; [nakarest] Str_DiskErr01_French  +0x10240..+0x1028e (0xe9618e, 78 B)
; [nakarest] purpose not established: 78 bytes at 0xe9618e that no registered NAKA table points into
Str_DiskErr01_French:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x10240, 0x4E
; [nakarest] Str_DiskErr01_German  +0x1028e..+0x102e4 (0xe961dc, 86 B)
; [nakarest] purpose not established: 86 bytes at 0xe961dc that no registered NAKA table points into
Str_DiskErr01_German:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1028E, 0x56
; [nakarest] Str_DiskErr01_English  +0x102e4..+0x103fa (0xe96232, 278 B)
; [nakarest] purpose not established: 278 bytes at 0xe96232 that no registered NAKA table points into
Str_DiskErr01_English:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x102E4, 0x116
; [nakarest] StrTable_DiskErr03  +0x103fa..+0x1040e (0xe96348, 20 B)
; [nakarest] purpose not established: 20 bytes at 0xe96348 that no registered NAKA table points into
StrTable_DiskErr03:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x103FA, 0x14
; [nakarest] Str_DiskErr03_Indonesian  +0x1040e..+0x10464 (0xe9635c, 86 B)
; [nakarest] purpose not established: 86 bytes at 0xe9635c that no registered NAKA table points into
Str_DiskErr03_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1040E, 0x56
; [nakarest] Str_DiskErr03_Italian  +0x10464..+0x1046e (0xe963b2, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe963b2 that no registered NAKA table points into
Str_DiskErr03_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x10464, 0xA
; [nakarest] Str_DiskErr03_Spanish  +0x1046e..+0x1049a (0xe963bc, 44 B)
; [nakarest] purpose not established: 44 bytes at 0xe963bc that no registered NAKA table points into
Str_DiskErr03_Spanish:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1046E, 0x2C
; [nakarest] Str_DiskErr03_French  +0x1049a..+0x104d0 (0xe963e8, 54 B)
; [nakarest] purpose not established: 54 bytes at 0xe963e8 that no registered NAKA table points into
Str_DiskErr03_French:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1049A, 0x36
; [nakarest] Str_DiskErr03_German  +0x104d0..+0x10534 (0xe9641e, 100 B)
; [nakarest] purpose not established: 100 bytes at 0xe9641e that no registered NAKA table points into
Str_DiskErr03_German:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x104D0, 0x64
; [nakarest] StrTable_DiskErr05  +0x10534..+0x1054c (0xe96482, 24 B)
; [nakarest] purpose not established: 24 bytes at 0xe96482 that no registered NAKA table points into
StrTable_DiskErr05:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x10534, 0x18
; [nakarest] Str_DiskErr05_Indonesian  +0x1054c..+0x1058e (0xe9649a, 66 B)
; [nakarest] purpose not established: 66 bytes at 0xe9649a that no registered NAKA table points into
Str_DiskErr05_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1054C, 0x42
; [nakarest] Str_DiskErr05_Italian  +0x1058e..+0x10598 (0xe964dc, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe964dc that no registered NAKA table points into
Str_DiskErr05_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1058E, 0xA
; [nakarest] Str_DiskErr05_Spanish  +0x10598..+0x106da (0xe964e6, 322 B)
; [nakarest] purpose not established: 322 bytes at 0xe964e6 that no registered NAKA table points into
Str_DiskErr05_Spanish:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x10598, 0x142
; [nakarest] StrTable_DiskErr06  +0x106da..+0x106f2 (0xe96628, 24 B)
; [nakarest] purpose not established: 24 bytes at 0xe96628 that no registered NAKA table points into
StrTable_DiskErr06:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x106DA, 0x18
; [nakarest] Str_DiskErr06_Indonesian  +0x106f2..+0x10754 (0xe96640, 98 B)
; [nakarest] purpose not established: 98 bytes at 0xe96640 that no registered NAKA table points into
Str_DiskErr06_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x106F2, 0x62
; [nakarest] Str_DiskErr06_Italian  +0x10754..+0x1075e (0xe966a2, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe966a2 that no registered NAKA table points into
Str_DiskErr06_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x10754, 0xA
; [nakarest] Str_DiskErr06_Spanish  +0x1075e..+0x107d6 (0xe966ac, 120 B)
; [nakarest] purpose not established: 120 bytes at 0xe966ac that no registered NAKA table points into
Str_DiskErr06_Spanish:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1075E, 0x78
; [nakarest] Str_DiskErr06_French  +0x107d6..+0x10848 (0xe96724, 114 B)
; [nakarest] purpose not established: 114 bytes at 0xe96724 that no registered NAKA table points into
Str_DiskErr06_French:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x107D6, 0x72
; [nakarest] Str_DiskErr06_German  +0x10848..+0x108ae (0xe96796, 102 B)
; [nakarest] purpose not established: 102 bytes at 0xe96796 that no registered NAKA table points into
Str_DiskErr06_German:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x10848, 0x66
; [nakarest] Str_DiskErr06_English  +0x108ae..+0x10910 (0xe967fc, 98 B)
; [nakarest] purpose not established: 98 bytes at 0xe967fc that no registered NAKA table points into
Str_DiskErr06_English:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x108AE, 0x62
; [nakarest] StrTable_DiskErr07  +0x10910..+0x10928 (0xe9685e, 24 B)
; [nakarest] purpose not established: 24 bytes at 0xe9685e that no registered NAKA table points into
StrTable_DiskErr07:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x10910, 0x18
; [nakarest] Str_DiskErr07_Indonesian  +0x10928..+0x10972 (0xe96876, 74 B)
; [nakarest] purpose not established: 74 bytes at 0xe96876 that no registered NAKA table points into
Str_DiskErr07_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x10928, 0x4A
; [nakarest] Str_DiskErr07_Italian  +0x10972..+0x10a7a (0xe968c0, 264 B)
; [nakarest] purpose not established: 264 bytes at 0xe968c0 that no registered NAKA table points into
Str_DiskErr07_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x10972, 0x108
; [nakarest] StrTable_DiskErr08  +0x10a7a..+0x10a92 (0xe969c8, 24 B)
; [nakarest] purpose not established: 24 bytes at 0xe969c8 that no registered NAKA table points into
StrTable_DiskErr08:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x10A7A, 0x18
; [nakarest] Str_DiskErr08_Indonesian  +0x10a92..+0x10b10 (0xe969e0, 126 B)
; [nakarest] purpose not established: 126 bytes at 0xe969e0 that no registered NAKA table points into
Str_DiskErr08_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x10A92, 0x7E
; [nakarest] Str_DiskErr08_Italian  +0x10b10..+0x10b1a (0xe96a5e, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe96a5e that no registered NAKA table points into
Str_DiskErr08_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x10B10, 0xA
; [nakarest] Str_DiskErr08_Spanish  +0x10b1a..+0x10bb8 (0xe96a68, 158 B)
; [nakarest] purpose not established: 158 bytes at 0xe96a68 that no registered NAKA table points into
Str_DiskErr08_Spanish:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x10B1A, 0x9E
; [nakarest] Str_DiskErr08_French  +0x10bb8..+0x10c58 (0xe96b06, 160 B)
; [nakarest] purpose not established: 160 bytes at 0xe96b06 that no registered NAKA table points into
Str_DiskErr08_French:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x10BB8, 0xA0
; [nakarest] Str_DiskErr08_German  +0x10c58..+0x10ca6 (0xe96ba6, 78 B)
; [nakarest] purpose not established: 78 bytes at 0xe96ba6 that no registered NAKA table points into
Str_DiskErr08_German:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x10C58, 0x4E
; [nakarest] Str_DiskErr08_English  +0x10ca6..+0x10d2a (0xe96bf4, 132 B)
; [nakarest] purpose not established: 132 bytes at 0xe96bf4 that no registered NAKA table points into
Str_DiskErr08_English:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x10CA6, 0x84
; [nakarest] StrTable_DiskErr09  +0x10d2a..+0x10d42 (0xe96c78, 24 B)
; [nakarest] purpose not established: 24 bytes at 0xe96c78 that no registered NAKA table points into
StrTable_DiskErr09:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x10D2A, 0x18
; [nakarest] Str_DiskErr09_Indonesian  +0x10d42..+0x10d8a (0xe96c90, 72 B)
; [nakarest] purpose not established: 72 bytes at 0xe96c90 that no registered NAKA table points into
Str_DiskErr09_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x10D42, 0x48
; [nakarest] Str_DiskErr09_Italian  +0x10d8a..+0x10d9e (0xe96cd8, 20 B)
; [nakarest] purpose not established: 20 bytes at 0xe96cd8 that no registered NAKA table points into
Str_DiskErr09_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x10D8A, 0x14
; [nakarest] Str_DiskErr09_Spanish  +0x10d9e..+0x10df4 (0xe96cec, 86 B)
; [nakarest] purpose not established: 86 bytes at 0xe96cec that no registered NAKA table points into
Str_DiskErr09_Spanish:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x10D9E, 0x56
; [nakarest] Str_DiskErr09_French  +0x10df4..+0x10e36 (0xe96d42, 66 B)
; [nakarest] purpose not established: 66 bytes at 0xe96d42 that no registered NAKA table points into
Str_DiskErr09_French:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x10DF4, 0x42
; [nakarest] Str_DiskErr09_German  +0x10e36..+0x10e8e (0xe96d84, 88 B)
; [nakarest] purpose not established: 88 bytes at 0xe96d84 that no registered NAKA table points into
Str_DiskErr09_German:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x10E36, 0x58
; [nakarest] Str_DiskErr09_English  +0x10e8e..+0x10ed2 (0xe96ddc, 68 B)
; [nakarest] purpose not established: 68 bytes at 0xe96ddc that no registered NAKA table points into
Str_DiskErr09_English:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x10E8E, 0x44
; [nakarest] StrTable_DiskErr10  +0x10ed2..+0x10eea (0xe96e20, 24 B)
; [nakarest] purpose not established: 24 bytes at 0xe96e20 that no registered NAKA table points into
StrTable_DiskErr10:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x10ED2, 0x18
; [nakarest] Str_DiskErr10_Indonesian  +0x10eea..+0x10f00 (0xe96e38, 22 B)
; [nakarest] purpose not established: 22 bytes at 0xe96e38 that no registered NAKA table points into
Str_DiskErr10_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x10EEA, 0x16
; [nakarest] Str_DiskErr10_Italian  +0x10f00..+0x10f0a (0xe96e4e, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe96e4e that no registered NAKA table points into
Str_DiskErr10_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x10F00, 0xA
; [nakarest] Str_DiskErr10_Spanish  +0x10f0a..+0x10f3a (0xe96e58, 48 B)
; [nakarest] purpose not established: 48 bytes at 0xe96e58 that no registered NAKA table points into
Str_DiskErr10_Spanish:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x10F0A, 0x30
; [nakarest] Str_DiskErr10_French  +0x10f3a..+0x10f66 (0xe96e88, 44 B)
; [nakarest] purpose not established: 44 bytes at 0xe96e88 that no registered NAKA table points into
Str_DiskErr10_French:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x10F3A, 0x2C
; [nakarest] Str_DiskErr10_German  +0x10f66..+0x10f90 (0xe96eb4, 42 B)
; [nakarest] purpose not established: 42 bytes at 0xe96eb4 that no registered NAKA table points into
Str_DiskErr10_German:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x10F66, 0x2A
; [nakarest] Str_DiskErr10_English  +0x10f90..+0x10fb4 (0xe96ede, 36 B)
; [nakarest] purpose not established: 36 bytes at 0xe96ede that no registered NAKA table points into
Str_DiskErr10_English:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x10F90, 0x24
; [nakarest] StrTable_DiskErr11  +0x10fb4..+0x10fcc (0xe96f02, 24 B)
; [nakarest] purpose not established: 24 bytes at 0xe96f02 that no registered NAKA table points into
StrTable_DiskErr11:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x10FB4, 0x18
; [nakarest] Str_DiskErr11_Indonesian  +0x10fcc..+0x10ff0 (0xe96f1a, 36 B)
; [nakarest] purpose not established: 36 bytes at 0xe96f1a that no registered NAKA table points into
Str_DiskErr11_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x10FCC, 0x24
; [nakarest] Str_DiskErr11_Italian  +0x10ff0..+0x1109a (0xe96f3e, 170 B)
; [nakarest] purpose not established: 170 bytes at 0xe96f3e that no registered NAKA table points into
Str_DiskErr11_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x10FF0, 0xAA
; [nakarest] StrTable_DiskErr12  +0x1109a..+0x110ae (0xe96fe8, 20 B)
; [nakarest] purpose not established: 20 bytes at 0xe96fe8 that no registered NAKA table points into
StrTable_DiskErr12:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1109A, 0x14
; [nakarest] Str_DiskErr12_Indonesian  +0x110ae..+0x110fa (0xe96ffc, 76 B)
; [nakarest] purpose not established: 76 bytes at 0xe96ffc that no registered NAKA table points into
Str_DiskErr12_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x110AE, 0x4C
; [nakarest] Str_DiskErr12_Italian  +0x110fa..+0x11104 (0xe97048, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe97048 that no registered NAKA table points into
Str_DiskErr12_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x110FA, 0xA
; [nakarest] Str_DiskErr12_Spanish  +0x11104..+0x1116c (0xe97052, 104 B)
; [nakarest] purpose not established: 104 bytes at 0xe97052 that no registered NAKA table points into
Str_DiskErr12_Spanish:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x11104, 0x68
; [nakarest] Str_DiskErr12_French  +0x1116c..+0x113b2 (0xe970ba, 582 B)
; [nakarest] purpose not established: 582 bytes at 0xe970ba that no registered NAKA table points into
Str_DiskErr12_French:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1116C, 0x246
; [nakarest] StrTable_DiskErr16  +0x113b2..+0x113c6 (0xe97300, 20 B)
; [nakarest] purpose not established: 20 bytes at 0xe97300 that no registered NAKA table points into
StrTable_DiskErr16:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x113B2, 0x14
; [nakarest] Str_DiskErr16_Indonesian  +0x113c6..+0x11416 (0xe97314, 80 B)
; [nakarest] purpose not established: 80 bytes at 0xe97314 that no registered NAKA table points into
Str_DiskErr16_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x113C6, 0x50
; [nakarest] Str_DiskErr16_Italian  +0x11416..+0x11428 (0xe97364, 18 B)
; [nakarest] purpose not established: 18 bytes at 0xe97364 that no registered NAKA table points into
Str_DiskErr16_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x11416, 0x12
; [nakarest] Str_DiskErr16_Spanish  +0x11428..+0x1147a (0xe97376, 82 B)
; [nakarest] purpose not established: 82 bytes at 0xe97376 that no registered NAKA table points into
Str_DiskErr16_Spanish:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x11428, 0x52
; [nakarest] Str_DiskErr16_French  +0x1147a..+0x114d6 (0xe973c8, 92 B)
; [nakarest] purpose not established: 92 bytes at 0xe973c8 that no registered NAKA table points into
Str_DiskErr16_French:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1147A, 0x5C
; [nakarest] Str_DiskErr16_German  +0x114d6..+0x11586 (0xe97424, 176 B)
; [nakarest] purpose not established: 176 bytes at 0xe97424 that no registered NAKA table points into
Str_DiskErr16_German:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x114D6, 0xB0
; [nakarest] StrPtr_DiskErr17Table  +0x11586..+0x1158a (0xe974d4, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe974d4 that no registered NAKA table points into
StrPtr_DiskErr17Table:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x11586, 0x4
; [nakarest] StrTable_DiskErr17  +0x1158a..+0x1159e (0xe974d8, 20 B)
; [nakarest] purpose not established: 20 bytes at 0xe974d8 that no registered NAKA table points into
StrTable_DiskErr17:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1158A, 0x14
; [nakarest] Str_DiskErr17_Indonesian  +0x1159e..+0x115bc (0xe974ec, 30 B)
; [nakarest] purpose not established: 30 bytes at 0xe974ec that no registered NAKA table points into
Str_DiskErr17_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1159E, 0x1E
; [nakarest] Str_DiskErr17_Italian  +0x115bc..+0x115d2 (0xe9750a, 22 B)
; [nakarest] purpose not established: 22 bytes at 0xe9750a that no registered NAKA table points into
Str_DiskErr17_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x115BC, 0x16
; [nakarest] Str_DiskErr17_Spanish  +0x115d2..+0x115f8 (0xe97520, 38 B)
; [nakarest] purpose not established: 38 bytes at 0xe97520 that no registered NAKA table points into
Str_DiskErr17_Spanish:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x115D2, 0x26
; [nakarest] Str_DiskErr17_French  +0x115f8..+0x11628 (0xe97546, 48 B)
; [nakarest] purpose not established: 48 bytes at 0xe97546 that no registered NAKA table points into
Str_DiskErr17_French:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x115F8, 0x30
; [nakarest] Str_DiskErr17_German  +0x11628..+0x11684 (0xe97576, 92 B)
; [nakarest] purpose not established: 92 bytes at 0xe97576 that no registered NAKA table points into
Str_DiskErr17_German:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x11628, 0x5C
; [nakarest] Str_DiskErr18_Indonesian  +0x11684..+0x116d8 (0xe975d2, 84 B)
; [nakarest] purpose not established: 84 bytes at 0xe975d2 that no registered NAKA table points into
Str_DiskErr18_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x11684, 0x54
; [nakarest] Str_DiskErr18_Italian  +0x116d8..+0x11860 (0xe97626, 392 B)
; [nakarest] purpose not established: 392 bytes at 0xe97626 that no registered NAKA table points into
Str_DiskErr18_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x116D8, 0x188
; [nakarest] StrTable_DiskErr19  +0x11860..+0x11878 (0xe977ae, 24 B)
; [nakarest] purpose not established: 24 bytes at 0xe977ae that no registered NAKA table points into
StrTable_DiskErr19:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x11860, 0x18
; [nakarest] Str_DiskErr19_Indonesian  +0x11878..+0x118d0 (0xe977c6, 88 B)
; [nakarest] purpose not established: 88 bytes at 0xe977c6 that no registered NAKA table points into
Str_DiskErr19_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x11878, 0x58
; [nakarest] Str_DiskErr19_Italian  +0x118d0..+0x118e0 (0xe9781e, 16 B)
; [nakarest] purpose not established: 16 bytes at 0xe9781e that no registered NAKA table points into
Str_DiskErr19_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x118D0, 0x10
; [nakarest] Str_DiskErr19_Spanish  +0x118e0..+0x11a54 (0xe9782e, 372 B)
; [nakarest] purpose not established: 372 bytes at 0xe9782e that no registered NAKA table points into
Str_DiskErr19_Spanish:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x118E0, 0x174
; [nakarest] Str_DiskErr20_Indonesian  +0x11a54..+0x11ac0 (0xe979a2, 108 B)
; [nakarest] purpose not established: 108 bytes at 0xe979a2 that no registered NAKA table points into
Str_DiskErr20_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x11A54, 0x6C
; [nakarest] Str_DiskErr20_Italian  +0x11ac0..+0x120a2 (0xe97a0e, 1506 B)
; [nakarest] purpose not established: 1506 bytes at 0xe97a0e that no registered NAKA table points into
Str_DiskErr20_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x11AC0, 0x5E2
; [nakarest] StrTable_DiskErr24_Rhythm  +0x120a2..+0x120b6 (0xe97ff0, 20 B)
; [nakarest] purpose not established: 20 bytes at 0xe97ff0 that no registered NAKA table points into
StrTable_DiskErr24_Rhythm:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x120A2, 0x14
; [nakarest] Str_Err24Rhythm_Indonesian  +0x120b6..+0x12106 (0xe98004, 80 B)
; [nakarest] purpose not established: 80 bytes at 0xe98004 that no registered NAKA table points into
Str_Err24Rhythm_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x120B6, 0x50
; [nakarest] Str_Err24Rhythm_Italian  +0x12106..+0x12110 (0xe98054, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe98054 that no registered NAKA table points into
Str_Err24Rhythm_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x12106, 0xA
; [nakarest] Str_Err24Rhythm_Spanish  +0x12110..+0x1215a (0xe9805e, 74 B)
; [nakarest] purpose not established: 74 bytes at 0xe9805e that no registered NAKA table points into
Str_Err24Rhythm_Spanish:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x12110, 0x4A
; [nakarest] Str_Err24Rhythm_French  +0x1215a..+0x121be (0xe980a8, 100 B)
; [nakarest] purpose not established: 100 bytes at 0xe980a8 that no registered NAKA table points into
Str_Err24Rhythm_French:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1215A, 0x64
; [nakarest] Str_Err24Rhythm_German  +0x121be..+0x1226a (0xe9810c, 172 B)
; [nakarest] purpose not established: 172 bytes at 0xe9810c that no registered NAKA table points into
Str_Err24Rhythm_German:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x121BE, 0xAC
; [nakarest] StrTable_DiskErr24_Chord  +0x1226a..+0x12282 (0xe981b8, 24 B)
; [nakarest] purpose not established: 24 bytes at 0xe981b8 that no registered NAKA table points into
StrTable_DiskErr24_Chord:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1226A, 0x18
; [nakarest] Str_Err24Chord_Indonesian  +0x12282..+0x122d0 (0xe981d0, 78 B)
; [nakarest] purpose not established: 78 bytes at 0xe981d0 that no registered NAKA table points into
Str_Err24Chord_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x12282, 0x4E
; [nakarest] Str_Err24Chord_Italian  +0x122d0..+0x122da (0xe9821e, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9821e that no registered NAKA table points into
Str_Err24Chord_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x122D0, 0xA
; [nakarest] Str_Err24Chord_Spanish  +0x122da..+0x12326 (0xe98228, 76 B)
; [nakarest] purpose not established: 76 bytes at 0xe98228 that no registered NAKA table points into
Str_Err24Chord_Spanish:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x122DA, 0x4C
; [nakarest] Str_Err24Chord_French  +0x12326..+0x1238a (0xe98274, 100 B)
; [nakarest] purpose not established: 100 bytes at 0xe98274 that no registered NAKA table points into
Str_Err24Chord_French:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x12326, 0x64
; [nakarest] Str_Err24Chord_German  +0x1238a..+0x123e6 (0xe982d8, 92 B)
; [nakarest] purpose not established: 92 bytes at 0xe982d8 that no registered NAKA table points into
Str_Err24Chord_German:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1238A, 0x5C
; [nakarest] Str_Err24Chord_English  +0x123e6..+0x1244c (0xe98334, 102 B)
; [nakarest] purpose not established: 102 bytes at 0xe98334 that no registered NAKA table points into
Str_Err24Chord_English:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x123E6, 0x66
; [nakarest] Str_Err24Ctrl_Indonesian  +0x1244c..+0x1249e (0xe9839a, 82 B)
; [nakarest] purpose not established: 82 bytes at 0xe9839a that no registered NAKA table points into
Str_Err24Ctrl_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1244C, 0x52
; [nakarest] Str_Err24Ctrl_Italian  +0x1249e..+0x12612 (0xe983ec, 372 B)
; [nakarest] purpose not established: 372 bytes at 0xe983ec that no registered NAKA table points into
Str_Err24Ctrl_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1249E, 0x174
; [nakarest] StrTable_DiskErr24_APC  +0x12612..+0x12626 (0xe98560, 20 B)
; [nakarest] purpose not established: 20 bytes at 0xe98560 that no registered NAKA table points into
StrTable_DiskErr24_APC:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x12612, 0x14
; [nakarest] Str_Err24APC_Indonesian  +0x12626..+0x12670 (0xe98574, 74 B)
; [nakarest] purpose not established: 74 bytes at 0xe98574 that no registered NAKA table points into
Str_Err24APC_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x12626, 0x4A
; [nakarest] Str_Err24APC_Italian  +0x12670..+0x1267a (0xe985be, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe985be that no registered NAKA table points into
Str_Err24APC_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x12670, 0xA
; [nakarest] Str_Err24APC_Spanish  +0x1267a..+0x126c6 (0xe985c8, 76 B)
; [nakarest] purpose not established: 76 bytes at 0xe985c8 that no registered NAKA table points into
Str_Err24APC_Spanish:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1267A, 0x4C
; [nakarest] Str_Err24APC_French  +0x126c6..+0x12e0a (0xe98614, 1860 B)
; [nakarest] purpose not established: 1860 bytes at 0xe98614 that no registered NAKA table points into
Str_Err24APC_French:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x126C6, 0x744
; [nakarest] StrTable_DiskErr28  +0x12e0a..+0x12e1e (0xe98d58, 20 B)
; [nakarest] purpose not established: 20 bytes at 0xe98d58 that no registered NAKA table points into
StrTable_DiskErr28:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x12E0A, 0x14
; [nakarest] Str_DiskErr28_Indonesian  +0x12e1e..+0x12e58 (0xe98d6c, 58 B)
; [nakarest] purpose not established: 58 bytes at 0xe98d6c that no registered NAKA table points into
Str_DiskErr28_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x12E1E, 0x3A
; [nakarest] Str_DiskErr28_Italian  +0x12e58..+0x12e62 (0xe98da6, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe98da6 that no registered NAKA table points into
Str_DiskErr28_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x12E58, 0xA
; [nakarest] Str_DiskErr28_Spanish  +0x12e62..+0x12eac (0xe98db0, 74 B)
; [nakarest] purpose not established: 74 bytes at 0xe98db0 that no registered NAKA table points into
Str_DiskErr28_Spanish:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x12E62, 0x4A
; [nakarest] Str_DiskErr28_French  +0x12eac..+0x12f04 (0xe98dfa, 88 B)
; [nakarest] purpose not established: 88 bytes at 0xe98dfa that no registered NAKA table points into
Str_DiskErr28_French:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x12EAC, 0x58
; [nakarest] Str_DiskErr28_German  +0x12f04..+0x12f78 (0xe98e52, 116 B)
; [nakarest] purpose not established: 116 bytes at 0xe98e52 that no registered NAKA table points into
Str_DiskErr28_German:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x12F04, 0x74
; [nakarest] StrTable_DiskErr29  +0x12f78..+0x12f90 (0xe98ec6, 24 B)
; [nakarest] purpose not established: 24 bytes at 0xe98ec6 that no registered NAKA table points into
StrTable_DiskErr29:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x12F78, 0x18
; [nakarest] Str_DiskErr29_Indonesian  +0x12f90..+0x1301a (0xe98ede, 138 B)
; [nakarest] purpose not established: 138 bytes at 0xe98ede that no registered NAKA table points into
Str_DiskErr29_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x12F90, 0x8A
; [nakarest] Str_DiskErr29_Italian  +0x1301a..+0x13024 (0xe98f68, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe98f68 that no registered NAKA table points into
Str_DiskErr29_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1301A, 0xA
; [nakarest] Str_DiskErr29_Spanish  +0x13024..+0x132a0 (0xe98f72, 636 B)
; [nakarest] purpose not established: 636 bytes at 0xe98f72 that no registered NAKA table points into
Str_DiskErr29_Spanish:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x13024, 0x27C
; [nakarest] StrTable_DiskErr30  +0x132a0..+0x132b8 (0xe991ee, 24 B)
; [nakarest] purpose not established: 24 bytes at 0xe991ee that no registered NAKA table points into
StrTable_DiskErr30:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x132A0, 0x18
; [nakarest] Str_DiskErr30_Indonesian  +0x132b8..+0x13382 (0xe99206, 202 B)
; [nakarest] purpose not established: 202 bytes at 0xe99206 that no registered NAKA table points into
Str_DiskErr30_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x132B8, 0xCA
; [nakarest] Str_DiskErr30_Italian  +0x13382..+0x13d8a (0xe992d0, 2568 B)
; [nakarest] purpose not established: 2568 bytes at 0xe992d0 that no registered NAKA table points into
Str_DiskErr30_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x13382, 0xA08
; [nakarest] StrTable_DiskErr41  +0x13d8a..+0x13d9e (0xe99cd8, 20 B)
; [nakarest] purpose not established: 20 bytes at 0xe99cd8 that no registered NAKA table points into
StrTable_DiskErr41:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x13D8A, 0x14
; [nakarest] Str_DiskErr41_Indonesian  +0x13d9e..+0x13e38 (0xe99cec, 154 B)
; [nakarest] purpose not established: 154 bytes at 0xe99cec that no registered NAKA table points into
Str_DiskErr41_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x13D9E, 0x9A
; [nakarest] Str_DiskErr41_Italian  +0x13e38..+0x13e42 (0xe99d86, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe99d86 that no registered NAKA table points into
Str_DiskErr41_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x13E38, 0xA
; [nakarest] Str_DiskErr41_Spanish  +0x13e42..+0x13ee6 (0xe99d90, 164 B)
; [nakarest] purpose not established: 164 bytes at 0xe99d90 that no registered NAKA table points into
Str_DiskErr41_Spanish:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x13E42, 0xA4
; [nakarest] Str_DiskErr41_French  +0x13ee6..+0x1437a (0xe99e34, 1172 B)
; [nakarest] purpose not established: 1172 bytes at 0xe99e34 that no registered NAKA table points into
Str_DiskErr41_French:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x13EE6, 0x494
; [nakarest] StrTable_DiskErr43  +0x1437a..+0x1438e (0xe9a2c8, 20 B)
; [nakarest] purpose not established: 20 bytes at 0xe9a2c8 that no registered NAKA table points into
StrTable_DiskErr43:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1437A, 0x14
; [nakarest] Str_DiskErr43_Indonesian  +0x1438e..+0x1442a (0xe9a2dc, 156 B)
; [nakarest] purpose not established: 156 bytes at 0xe9a2dc that no registered NAKA table points into
Str_DiskErr43_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1438E, 0x9C
; [nakarest] Str_DiskErr43_Italian  +0x1442a..+0x14434 (0xe9a378, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9a378 that no registered NAKA table points into
Str_DiskErr43_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1442A, 0xA
; [nakarest] Str_DiskErr43_Spanish  +0x14434..+0x144b0 (0xe9a382, 124 B)
; [nakarest] purpose not established: 124 bytes at 0xe9a382 that no registered NAKA table points into
Str_DiskErr43_Spanish:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x14434, 0x7C
; [nakarest] Str_DiskErr43_French  +0x144b0..+0x14546 (0xe9a3fe, 150 B)
; [nakarest] purpose not established: 150 bytes at 0xe9a3fe that no registered NAKA table points into
Str_DiskErr43_French:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x144B0, 0x96
; [nakarest] Str_DiskErr43_German  +0x14546..+0x1467a (0xe9a494, 308 B)
; [nakarest] purpose not established: 308 bytes at 0xe9a494 that no registered NAKA table points into
Str_DiskErr43_German:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x14546, 0x134
; [nakarest] StrTable_DiskErr44  +0x1467a..+0x14692 (0xe9a5c8, 24 B)
; [nakarest] purpose not established: 24 bytes at 0xe9a5c8 that no registered NAKA table points into
StrTable_DiskErr44:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1467A, 0x18
; [nakarest] Str_DiskErr44_Indonesian  +0x14692..+0x14714 (0xe9a5e0, 130 B)
; [nakarest] purpose not established: 130 bytes at 0xe9a5e0 that no registered NAKA table points into
Str_DiskErr44_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x14692, 0x82
; [nakarest] Str_DiskErr44_Italian  +0x14714..+0x1471e (0xe9a662, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9a662 that no registered NAKA table points into
Str_DiskErr44_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x14714, 0xA
; [nakarest] Str_DiskErr44_Spanish  +0x1471e..+0x147a4 (0xe9a66c, 134 B)
; [nakarest] purpose not established: 134 bytes at 0xe9a66c that no registered NAKA table points into
Str_DiskErr44_Spanish:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1471E, 0x86
; [nakarest] Str_DiskErr44_French  +0x147a4..+0x1482a (0xe9a6f2, 134 B)
; [nakarest] purpose not established: 134 bytes at 0xe9a6f2 that no registered NAKA table points into
Str_DiskErr44_French:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x147A4, 0x86
; [nakarest] Str_DiskErr44_German  +0x1482a..+0x148ac (0xe9a778, 130 B)
; [nakarest] purpose not established: 130 bytes at 0xe9a778 that no registered NAKA table points into
Str_DiskErr44_German:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1482A, 0x82
; [nakarest] Str_DiskErr44_English  +0x148ac..+0x1491c (0xe9a7fa, 112 B)
; [nakarest] purpose not established: 112 bytes at 0xe9a7fa that no registered NAKA table points into
Str_DiskErr44_English:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x148AC, 0x70
; [nakarest] StrTable_DiskErr46  +0x1491c..+0x14934 (0xe9a86a, 24 B)
; [nakarest] purpose not established: 24 bytes at 0xe9a86a that no registered NAKA table points into
StrTable_DiskErr46:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1491C, 0x18
; [nakarest] Str_DiskErr46_Indonesian  +0x14934..+0x1499e (0xe9a882, 106 B)
; [nakarest] purpose not established: 106 bytes at 0xe9a882 that no registered NAKA table points into
Str_DiskErr46_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x14934, 0x6A
; [nakarest] Str_DiskErr46_Italian  +0x1499e..+0x14b92 (0xe9a8ec, 500 B)
; [nakarest] purpose not established: 500 bytes at 0xe9a8ec that no registered NAKA table points into
Str_DiskErr46_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1499E, 0x1F4
; [nakarest] StrTable_DiskErr47  +0x14b92..+0x14ba6 (0xe9aae0, 20 B)
; [nakarest] purpose not established: 20 bytes at 0xe9aae0 that no registered NAKA table points into
StrTable_DiskErr47:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x14B92, 0x14
; [nakarest] Str_DiskErr47_Indonesian  +0x14ba6..+0x14c22 (0xe9aaf4, 124 B)
; [nakarest] purpose not established: 124 bytes at 0xe9aaf4 that no registered NAKA table points into
Str_DiskErr47_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x14BA6, 0x7C
; [nakarest] Str_DiskErr47_Italian  +0x14c22..+0x14c2c (0xe9ab70, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9ab70 that no registered NAKA table points into
Str_DiskErr47_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x14C22, 0xA
; [nakarest] Str_DiskErr47_Spanish  +0x14c2c..+0x14caa (0xe9ab7a, 126 B)
; [nakarest] purpose not established: 126 bytes at 0xe9ab7a that no registered NAKA table points into
Str_DiskErr47_Spanish:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x14C2C, 0x7E
; [nakarest] Str_DiskErr47_French  +0x14caa..+0x14d1e (0xe9abf8, 116 B)
; [nakarest] purpose not established: 116 bytes at 0xe9abf8 that no registered NAKA table points into
Str_DiskErr47_French:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x14CAA, 0x74
; [nakarest] Str_DiskErr47_German  +0x14d1e..+0x14dfa (0xe9ac6c, 220 B)
; [nakarest] purpose not established: 220 bytes at 0xe9ac6c that no registered NAKA table points into
Str_DiskErr47_German:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x14D1E, 0xDC
; [nakarest] StrTable_DiskErr48  +0x14dfa..+0x14e12 (0xe9ad48, 24 B)
; [nakarest] purpose not established: 24 bytes at 0xe9ad48 that no registered NAKA table points into
StrTable_DiskErr48:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x14DFA, 0x18
; [nakarest] NakaInst_Tipe_disket_yang_digunakan  +0x14e12..+0x14e72 (0xe9ad60, 96 B)
; [nakarest] purpose not established: 96 bytes at 0xe9ad60 that no registered NAKA table points into
NakaInst_Tipe_disket_yang_digunakan:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x14E12, 0x60
; [nakarest] NakaInst_ERR0R_48  +0x14e72..+0x14e7c (0xe9adc0, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9adc0 that no registered NAKA table points into
NakaInst_ERR0R_48:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x14E72, 0xA
; [nakarest] NakaInst_lo_pueden_usarse_los_disquetes_de_tipo  +0x14e7c..+0x14ee2 (0xe9adca, 102 B)
; [nakarest] purpose not established: 102 bytes at 0xe9adca that no registered NAKA table points into
NakaInst_lo_pueden_usarse_los_disquetes_de_tipo:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x14E7C, 0x66
; [nakarest] Str_DiskErr48_French  +0x14ee2..+0x14f4c (0xe9ae30, 106 B)
; [nakarest] purpose not established: 106 bytes at 0xe9ae30 that no registered NAKA table points into
Str_DiskErr48_French:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x14EE2, 0x6A
; [nakarest] Str_DiskErr48_German  +0x14f4c..+0x14fb4 (0xe9ae9a, 104 B)
; [nakarest] purpose not established: 104 bytes at 0xe9ae9a that no registered NAKA table points into
Str_DiskErr48_German:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x14F4C, 0x68
; [nakarest] Str_DiskErr48_English  +0x14fb4..+0x15020 (0xe9af02, 108 B)
; [nakarest] purpose not established: 108 bytes at 0xe9af02 that no registered NAKA table points into
Str_DiskErr48_English:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x14FB4, 0x6C
; [nakarest] NakaInst_Jumlah_lagu_melebihi_kapasitas_KN_5000_Coba_lagi  +0x15020..+0x15098 (0xe9af6e, 120 B)
; [nakarest] purpose not established: 120 bytes at 0xe9af6e that no registered NAKA table points into
NakaInst_Jumlah_lagu_melebihi_kapasitas_KN_5000_Coba_lagi:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x15020, 0x78
; [nakarest] NakaInst_ERROR_49  +0x15098..+0x1532e (0xe9afe6, 662 B)
; [nakarest] purpose not established: 662 bytes at 0xe9afe6 that no registered NAKA table points into
NakaInst_ERROR_49:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x15098, 0x296
; [nakarest] StrTable_DiskErr49_PtrEnd  +0x1532e..+0x15332 (0xe9b27c, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe9b27c that no registered NAKA table points into
StrTable_DiskErr49_PtrEnd:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1532E, 0x4
; [nakarest] Str_SongCapacityExceeded_Multilingual  +0x15332..+0x15346 (0xe9b280, 20 B)
; [nakarest] purpose not established: 20 bytes at 0xe9b280 that no registered NAKA table points into
Str_SongCapacityExceeded_Multilingual:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x15332, 0x14
; [nakarest] NakaInst_Tidak_mungkin_merekam_dengan_menggunakan_Preset  +0x15346..+0x153ce (0xe9b294, 136 B)
; [nakarest] purpose not established: 136 bytes at 0xe9b294 that no registered NAKA table points into
NakaInst_Tidak_mungkin_merekam_dengan_menggunakan_Preset:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x15346, 0x88
; [nakarest] NakaInst_ERROR_54  +0x153ce..+0x153d8 (0xe9b31c, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9b31c that no registered NAKA table points into
NakaInst_ERROR_54:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x153CE, 0xA
; [nakarest] NakaInst_No_es_posible_grabar_sobre_los_bancos  +0x153d8..+0x15476 (0xe9b326, 158 B)
; [nakarest] purpose not established: 158 bytes at 0xe9b326 that no registered NAKA table points into
NakaInst_No_es_posible_grabar_sobre_los_bancos:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x153D8, 0x9E
; [nakarest] NakaInst_Il_n_est_pas_possible_d_effectuer_un  +0x15476..+0x15532 (0xe9b3c4, 188 B)
; [nakarest] purpose not established: 188 bytes at 0xe9b3c4 that no registered NAKA table points into
NakaInst_Il_n_est_pas_possible_d_effectuer_un:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x15476, 0xBC
; [nakarest] NakaInst_It_is_not_possible_to_record_using_preset_banks  +0x15532..+0x15638 (0xe9b480, 262 B)
; [nakarest] purpose not established: 262 bytes at 0xe9b480 that no registered NAKA table points into
NakaInst_It_is_not_possible_to_record_using_preset_banks:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x15532, 0x106
; [nakarest] NakaInst_Special_Tracks_seperti_Chord_APC_Rhythm_dan  +0x15638..+0x156e6 (0xe9b586, 174 B)
; [nakarest] purpose not established: 174 bytes at 0xe9b586 that no registered NAKA table points into
NakaInst_Special_Tracks_seperti_Chord_APC_Rhythm_dan:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x15638, 0xAE
; [nakarest] NakaInst_ERROR_55  +0x156e6..+0x165da (0xe9b634, 3828 B)
; [nakarest] purpose not established: 3828 bytes at 0xe9b634 that no registered NAKA table points into
NakaInst_ERROR_55:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x156E6, 0xEF4
; [nakarest] Str_RKBLKBSpecialTracks_Multilingual  +0x165da..+0x165ee (0xe9c528, 20 B)
; [nakarest] purpose not established: 20 bytes at 0xe9c528 that no registered NAKA table points into
Str_RKBLKBSpecialTracks_Multilingual:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x165DA, 0x14
; [nakarest] NakaInst_s_v  +0x165ee..+0x165f4 (0xe9c53c, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9c53c that no registered NAKA table points into
NakaInst_s_v:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x165EE, 0x6
; [nakarest] NakaInst_ERROR_60  +0x165f4..+0x165fe (0xe9c542, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9c542 that no registered NAKA table points into
NakaInst_ERROR_60:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x165F4, 0xA
; [nakarest] NakaInst_es_RKB_LKB_pistas_especiales  +0x165fe..+0x166dc (0xe9c54c, 222 B)
; [nakarest] purpose not established: 222 bytes at 0xe9c54c that no registered NAKA table points into
NakaInst_es_RKB_LKB_pistas_especiales:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x165FE, 0xDE
; [nakarest] NakaInst_es_qui_ne_peuvent_tre_utilis_es_en_association  +0x166dc..+0x16fca (0xe9c62a, 2286 B)
; [nakarest] purpose not established: 2286 bytes at 0xe9c62a that no registered NAKA table points into
NakaInst_es_qui_ne_peuvent_tre_utilis_es_en_association:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x166DC, 0x8EE
; [nakarest] Str_InitSettingWarning_Multilingual  +0x16fca..+0x16fde (0xe9cf18, 20 B)
; [nakarest] purpose not established: 20 bytes at 0xe9cf18 that no registered NAKA table points into
Str_InitSettingWarning_Multilingual:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x16FCA, 0x14
; [nakarest] NakaInst_Bitmap_adalah_salah_format_dari_KN_5000_dan  +0x16fde..+0x17060 (0xe9cf2c, 130 B)
; [nakarest] purpose not established: 130 bytes at 0xe9cf2c that no registered NAKA table points into
NakaInst_Bitmap_adalah_salah_format_dari_KN_5000_dan:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x16FDE, 0x82
; [nakarest] NakaInst_ERROR_63  +0x17060..+0x1706a (0xe9cfae, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9cfae that no registered NAKA table points into
NakaInst_ERROR_63:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17060, 0xA
; [nakarest] NakaInst_es_Bitmap_formato_incorrecto  +0x1706a..+0x170fc (0xe9cfb8, 146 B)
; [nakarest] purpose not established: 146 bytes at 0xe9cfb8 that no registered NAKA table points into
NakaInst_es_Bitmap_formato_incorrecto:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1706A, 0x92
; [nakarest] NakaInst_Cette_configuration_Bitmap_n_est_pas_au_bon  +0x170fc..+0x17192 (0xe9d04a, 150 B)
; [nakarest] purpose not established: 150 bytes at 0xe9d04a that no registered NAKA table points into
NakaInst_Cette_configuration_Bitmap_n_est_pas_au_bon:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x170FC, 0x96
; [nakarest] NakaInst_This_Bitmap_is_in_the_wrong_format_for_the_KN5000  +0x17192..+0x17284 (0xe9d0e0, 242 B)
; [nakarest] purpose not established: 242 bytes at 0xe9d0e0 that no registered NAKA table points into
NakaInst_This_Bitmap_is_in_the_wrong_format_for_the_KN5000:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17192, 0xF2
; [nakarest] StrTable_DiskErr64_PtrEnd  +0x17284..+0x1729c (0xe9d1d2, 24 B)
; [nakarest] purpose not established: 24 bytes at 0xe9d1d2 that no registered NAKA table points into
StrTable_DiskErr64_PtrEnd:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17284, 0x18
; [nakarest] NakaInst_Pilihlah_Panel_Memory_yang_ingin_anda_berikan_nama  +0x1729c..+0x172d0 (0xe9d1ea, 52 B)
; [nakarest] purpose not established: 52 bytes at 0xe9d1ea that no registered NAKA table points into
NakaInst_Pilihlah_Panel_Memory_yang_ingin_anda_berikan_nama:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1729C, 0x34
; [nakarest] NakaInst_ERROR_64  +0x172d0..+0x172da (0xe9d21e, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9d21e that no registered NAKA table points into
NakaInst_ERROR_64:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x172D0, 0xA
; [nakarest] NakaInst_Por_favor_seleccione_el_Panel_Memory_al_que_desea  +0x172da..+0x17894 (0xe9d228, 1466 B)
; [nakarest] purpose not established: 1466 bytes at 0xe9d228 that no registered NAKA table points into
NakaInst_Por_favor_seleccione_el_Panel_Memory_al_que_desea:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x172DA, 0x5BA
; [nakarest] NakaInst_SILAHKAN_TUNGGU  +0x17894..+0x178a6 (0xe9d7e2, 18 B)
; [nakarest] purpose not established: 18 bytes at 0xe9d7e2 that no registered NAKA table points into
NakaInst_SILAHKAN_TUNGGU:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17894, 0x12
; [nakarest] NakaInst_PLEASE_WAIT  +0x178a6..+0x178f8 (0xe9d7f4, 82 B)
; [nakarest] purpose not established: 82 bytes at 0xe9d7f4 that no registered NAKA table points into
NakaInst_PLEASE_WAIT:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x178A6, 0x52
; [nakarest] Str_PleaseWait_Multilingual  +0x178f8..+0x17910 (0xe9d846, 24 B)
; [nakarest] purpose not established: 24 bytes at 0xe9d846 that no registered NAKA table points into
Str_PleaseWait_Multilingual:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x178F8, 0x18
; [nakarest] NakaInst_Indonesian_E9D85E  +0x17910..+0x1791c (0xe9d85e, 12 B)
; [nakarest] purpose not established: 12 bytes at 0xe9d85e that no registered NAKA table points into
NakaInst_Indonesian_E9D85E:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17910, 0xC
; [nakarest] NakaInst_Italian_E9D86A  +0x1791c..+0x17924 (0xe9d86a, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9d86a that no registered NAKA table points into
NakaInst_Italian_E9D86A:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1791C, 0x8
; [nakarest] NakaInst_Spanish_E9D872  +0x17924..+0x1792c (0xe9d872, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9d872 that no registered NAKA table points into
NakaInst_Spanish_E9D872:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17924, 0x8
; [nakarest] NakaInst_French_E9D87A  +0x1792c..+0x17934 (0xe9d87a, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9d87a that no registered NAKA table points into
NakaInst_French_E9D87A:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1792C, 0x8
; [nakarest] NakaInst_German_E9D882  +0x17934..+0x1793c (0xe9d882, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9d882 that no registered NAKA table points into
NakaInst_German_E9D882:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17934, 0x8
; [nakarest] NakaInst_English_E9D88A  +0x1793c..+0x1795e (0xe9d88a, 34 B)
; [nakarest] purpose not established: 34 bytes at 0xe9d88a that no registered NAKA table points into
NakaInst_English_E9D88A:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1793C, 0x22
; [nakarest] NakaInst_METRO  +0x1795e..+0x17968 (0xe9d8ac, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9d8ac that no registered NAKA table points into
NakaInst_METRO:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1795E, 0xA
; [nakarest] NakaInst_CONTROL  +0x17968..+0x17972 (0xe9d8b6, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9d8b6 that no registered NAKA table points into
NakaInst_CONTROL:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17968, 0xA
; [nakarest] NakaInst_MSP  +0x17972..+0x1797c (0xe9d8c0, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9d8c0 that no registered NAKA table points into
NakaInst_MSP:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17972, 0xA
; [nakarest] NakaInst_MSP_E9D8CA  +0x1797c..+0x17986 (0xe9d8ca, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9d8ca that no registered NAKA table points into
NakaInst_MSP_E9D8CA:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1797C, 0xA
; [nakarest] NakaInst_R_BASS  +0x17986..+0x17990 (0xe9d8d4, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9d8d4 that no registered NAKA table points into
NakaInst_R_BASS:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17986, 0xA
; [nakarest] NakaInst_CHORD  +0x17990..+0x1799a (0xe9d8de, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9d8de that no registered NAKA table points into
NakaInst_CHORD:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17990, 0xA
; [nakarest] NakaInst_DRUM_E9D8E8  +0x1799a..+0x179a4 (0xe9d8e8, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9d8e8 that no registered NAKA table points into
NakaInst_DRUM_E9D8E8:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1799A, 0xA
; [nakarest] NakaInst_BASS_E9D8F2  +0x179a4..+0x179ae (0xe9d8f2, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9d8f2 that no registered NAKA table points into
NakaInst_BASS_E9D8F2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x179A4, 0xA
; [nakarest] NakaInst_ACCOMP3  +0x179ae..+0x179b8 (0xe9d8fc, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9d8fc that no registered NAKA table points into
NakaInst_ACCOMP3:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x179AE, 0xA
; [nakarest] NakaInst_ACCOMP2  +0x179b8..+0x179c2 (0xe9d906, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9d906 that no registered NAKA table points into
NakaInst_ACCOMP2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x179B8, 0xA
; [nakarest] NakaInst_ACCOMP1  +0x179c2..+0x179cc (0xe9d910, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9d910 that no registered NAKA table points into
NakaInst_ACCOMP1:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x179C2, 0xA
; [nakarest] NakaInst_PART_16  +0x179cc..+0x179d6 (0xe9d91a, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9d91a that no registered NAKA table points into
NakaInst_PART_16:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x179CC, 0xA
; [nakarest] NakaInst_PART_15  +0x179d6..+0x179e0 (0xe9d924, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9d924 that no registered NAKA table points into
NakaInst_PART_15:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x179D6, 0xA
; [nakarest] NakaInst_PART_14  +0x179e0..+0x179ea (0xe9d92e, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9d92e that no registered NAKA table points into
NakaInst_PART_14:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x179E0, 0xA
; [nakarest] NakaInst_PART_13  +0x179ea..+0x179f4 (0xe9d938, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9d938 that no registered NAKA table points into
NakaInst_PART_13:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x179EA, 0xA
; [nakarest] NakaInst_PART_12  +0x179f4..+0x179fe (0xe9d942, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9d942 that no registered NAKA table points into
NakaInst_PART_12:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x179F4, 0xA
; [nakarest] NakaInst_PART_11  +0x179fe..+0x17a08 (0xe9d94c, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9d94c that no registered NAKA table points into
NakaInst_PART_11:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x179FE, 0xA
; [nakarest] NakaInst_PART_10  +0x17a08..+0x17a12 (0xe9d956, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9d956 that no registered NAKA table points into
NakaInst_PART_10:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17A08, 0xA
; [nakarest] NakaInst_PART_9  +0x17a12..+0x17a1c (0xe9d960, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9d960 that no registered NAKA table points into
NakaInst_PART_9:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17A12, 0xA
; [nakarest] NakaInst_PART_8  +0x17a1c..+0x17a26 (0xe9d96a, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9d96a that no registered NAKA table points into
NakaInst_PART_8:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17A1C, 0xA
; [nakarest] NakaInst_PART_7  +0x17a26..+0x17a30 (0xe9d974, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9d974 that no registered NAKA table points into
NakaInst_PART_7:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17A26, 0xA
; [nakarest] NakaInst_PART_6  +0x17a30..+0x17a3a (0xe9d97e, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9d97e that no registered NAKA table points into
NakaInst_PART_6:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17A30, 0xA
; [nakarest] NakaInst_PART_5  +0x17a3a..+0x17a44 (0xe9d988, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9d988 that no registered NAKA table points into
NakaInst_PART_5:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17A3A, 0xA
; [nakarest] NakaInst_PART_4  +0x17a44..+0x17a4e (0xe9d992, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9d992 that no registered NAKA table points into
NakaInst_PART_4:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17A44, 0xA
; [nakarest] NakaInst_LEFT_E9D99C  +0x17a4e..+0x17a58 (0xe9d99c, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9d99c that no registered NAKA table points into
NakaInst_LEFT_E9D99C:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17A4E, 0xA
; [nakarest] NakaInst_RIGHT_2_E9D9A6  +0x17a58..+0x17a62 (0xe9d9a6, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9d9a6 that no registered NAKA table points into
NakaInst_RIGHT_2_E9D9A6:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17A58, 0xA
; [nakarest] NakaInst_RIGHT_1_E9D9B0  +0x17a62..+0x17ada (0xe9d9b0, 120 B)
; [nakarest] purpose not established: 120 bytes at 0xe9d9b0 that no registered NAKA table points into
NakaInst_RIGHT_1_E9D9B0:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17A62, 0x78
; [nakarest] Naka_TechniChord1_Screens  +0x17ada..+0x17b1e (0xe9da28, 68 B)
; [nakarest] purpose not established: 68 bytes at 0xe9da28 that no registered NAKA table points into
Naka_TechniChord1_Screens:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17ADA, 0x44
; [nakarest] NakaInst_CONDUCTOR  +0x17b1e..+0x17b28 (0xe9da6c, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9da6c that no registered NAKA table points into
NakaInst_CONDUCTOR:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17B1E, 0xA
; [nakarest] NakaInst_PART_16_E9DA76  +0x17b28..+0x17b32 (0xe9da76, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9da76 that no registered NAKA table points into
NakaInst_PART_16_E9DA76:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17B28, 0xA
; [nakarest] NakaInst_PART_15_E9DA80  +0x17b32..+0x17b3c (0xe9da80, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9da80 that no registered NAKA table points into
NakaInst_PART_15_E9DA80:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17B32, 0xA
; [nakarest] NakaInst_PART_14_E9DA8A  +0x17b3c..+0x17b46 (0xe9da8a, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9da8a that no registered NAKA table points into
NakaInst_PART_14_E9DA8A:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17B3C, 0xA
; [nakarest] NakaInst_PART_13_E9DA94  +0x17b46..+0x17b50 (0xe9da94, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9da94 that no registered NAKA table points into
NakaInst_PART_13_E9DA94:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17B46, 0xA
; [nakarest] NakaInst_PART_12_E9DA9E  +0x17b50..+0x17b5a (0xe9da9e, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9da9e that no registered NAKA table points into
NakaInst_PART_12_E9DA9E:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17B50, 0xA
; [nakarest] NakaInst_PART_11_E9DAA8  +0x17b5a..+0x17b64 (0xe9daa8, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9daa8 that no registered NAKA table points into
NakaInst_PART_11_E9DAA8:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17B5A, 0xA
; [nakarest] NakaInst_PART_10_E9DAB2  +0x17b64..+0x17b6e (0xe9dab2, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9dab2 that no registered NAKA table points into
NakaInst_PART_10_E9DAB2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17B64, 0xA
; [nakarest] NakaInst_PART_9_E9DABC  +0x17b6e..+0x17b78 (0xe9dabc, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9dabc that no registered NAKA table points into
NakaInst_PART_9_E9DABC:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17B6E, 0xA
; [nakarest] NakaInst_PART_8_E9DAC6  +0x17b78..+0x17b82 (0xe9dac6, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9dac6 that no registered NAKA table points into
NakaInst_PART_8_E9DAC6:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17B78, 0xA
; [nakarest] NakaInst_PART_7_E9DAD0  +0x17b82..+0x17b8c (0xe9dad0, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9dad0 that no registered NAKA table points into
NakaInst_PART_7_E9DAD0:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17B82, 0xA
; [nakarest] NakaInst_PART_6_E9DADA  +0x17b8c..+0x17b96 (0xe9dada, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9dada that no registered NAKA table points into
NakaInst_PART_6_E9DADA:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17B8C, 0xA
; [nakarest] NakaInst_PART_5_E9DAE4  +0x17b96..+0x17ba0 (0xe9dae4, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9dae4 that no registered NAKA table points into
NakaInst_PART_5_E9DAE4:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17B96, 0xA
; [nakarest] NakaInst_PART_4_E9DAEE  +0x17ba0..+0x17baa (0xe9daee, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9daee that no registered NAKA table points into
NakaInst_PART_4_E9DAEE:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17BA0, 0xA
; [nakarest] NakaInst_LEFT_E9DAF8  +0x17baa..+0x17bb4 (0xe9daf8, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9daf8 that no registered NAKA table points into
NakaInst_LEFT_E9DAF8:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17BAA, 0xA
; [nakarest] NakaInst_RIGHT_2_E9DB02  +0x17bb4..+0x17bbe (0xe9db02, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9db02 that no registered NAKA table points into
NakaInst_RIGHT_2_E9DB02:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17BB4, 0xA
; [nakarest] NakaInst_RIGHT_1_E9DB0C  +0x17bbe..+0x17c88 (0xe9db0c, 202 B)
; [nakarest] purpose not established: 202 bytes at 0xe9db0c that no registered NAKA table points into
NakaInst_RIGHT_1_E9DB0C:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17BBE, 0xCA
; [nakarest] Naka_Scale2_Screens  +0x17c88..+0x17ccc (0xe9dbd6, 68 B)
; [nakarest] purpose not established: 68 bytes at 0xe9dbd6 that no registered NAKA table points into
Naka_Scale2_Screens:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17C88, 0x44
; [nakarest] NakaInst_NO_TYPE  +0x17ccc..+0x17cda (0xe9dc1a, 14 B)
; [nakarest] purpose not established: 14 bytes at 0xe9dc1a that no registered NAKA table points into
NakaInst_NO_TYPE:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17CCC, 0xE
; [nakarest] NakaInst_USER  +0x17cda..+0x17ce8 (0xe9dc28, 14 B)
; [nakarest] purpose not established: 14 bytes at 0xe9dc28 that no registered NAKA table points into
NakaInst_USER:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17CDA, 0xE
; [nakarest] NakaInst_USER_E9DC36  +0x17ce8..+0x17cf6 (0xe9dc36, 14 B)
; [nakarest] purpose not established: 14 bytes at 0xe9dc36 that no registered NAKA table points into
NakaInst_USER_E9DC36:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17CE8, 0xE
; [nakarest] NakaInst_PELOG  +0x17cf6..+0x17d04 (0xe9dc44, 14 B)
; [nakarest] purpose not established: 14 bytes at 0xe9dc44 that no registered NAKA table points into
NakaInst_PELOG:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17CF6, 0xE
; [nakarest] NakaInst_SLENDRO  +0x17d04..+0x17d12 (0xe9dc52, 14 B)
; [nakarest] purpose not established: 14 bytes at 0xe9dc52 that no registered NAKA table points into
NakaInst_SLENDRO:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17D04, 0xE
; [nakarest] NakaInst_ARABIC_5  +0x17d12..+0x17d20 (0xe9dc60, 14 B)
; [nakarest] purpose not established: 14 bytes at 0xe9dc60 that no registered NAKA table points into
NakaInst_ARABIC_5:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17D12, 0xE
; [nakarest] NakaInst_ARABIC_4  +0x17d20..+0x17d2e (0xe9dc6e, 14 B)
; [nakarest] purpose not established: 14 bytes at 0xe9dc6e that no registered NAKA table points into
NakaInst_ARABIC_4:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17D20, 0xE
; [nakarest] NakaInst_ARABIC_3  +0x17d2e..+0x17d3c (0xe9dc7c, 14 B)
; [nakarest] purpose not established: 14 bytes at 0xe9dc7c that no registered NAKA table points into
NakaInst_ARABIC_3:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17D2E, 0xE
; [nakarest] NakaInst_ARABIC_2  +0x17d3c..+0x17d4a (0xe9dc8a, 14 B)
; [nakarest] purpose not established: 14 bytes at 0xe9dc8a that no registered NAKA table points into
NakaInst_ARABIC_2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17D3C, 0xE
; [nakarest] NakaInst_ARABIC_1  +0x17d4a..+0x17d58 (0xe9dc98, 14 B)
; [nakarest] purpose not established: 14 bytes at 0xe9dc98 that no registered NAKA table points into
NakaInst_ARABIC_1:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17D4A, 0xE
; [nakarest] NakaInst_KIRNBERGER  +0x17d58..+0x17d66 (0xe9dca6, 14 B)
; [nakarest] purpose not established: 14 bytes at 0xe9dca6 that no registered NAKA table points into
NakaInst_KIRNBERGER:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17D58, 0xE
; [nakarest] NakaInst_WERCKMEISTER  +0x17d66..+0x17d74 (0xe9dcb4, 14 B)
; [nakarest] purpose not established: 14 bytes at 0xe9dcb4 that no registered NAKA table points into
NakaInst_WERCKMEISTER:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17D66, 0xE
; [nakarest] NakaInst_PYTHAGOREAN  +0x17d74..+0x17d82 (0xe9dcc2, 14 B)
; [nakarest] purpose not established: 14 bytes at 0xe9dcc2 that no registered NAKA table points into
NakaInst_PYTHAGOREAN:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17D74, 0xE
; [nakarest] NakaInst_ORCHESTRA  +0x17d82..+0x17d90 (0xe9dcd0, 14 B)
; [nakarest] purpose not established: 14 bytes at 0xe9dcd0 that no registered NAKA table points into
NakaInst_ORCHESTRA:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17D82, 0xE
; [nakarest] NakaInst_PIANO  +0x17d90..+0x17d9e (0xe9dcde, 14 B)
; [nakarest] purpose not established: 14 bytes at 0xe9dcde that no registered NAKA table points into
NakaInst_PIANO:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17D90, 0xE
; [nakarest] NakaInst_RANDOM  +0x17d9e..+0x17dac (0xe9dcec, 14 B)
; [nakarest] purpose not established: 14 bytes at 0xe9dcec that no registered NAKA table points into
NakaInst_RANDOM:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17D9E, 0xE
; [nakarest] NakaInst_OFF_E9DCFA  +0x17dac..+0x17dc8 (0xe9dcfa, 28 B)
; [nakarest] purpose not established: 28 bytes at 0xe9dcfa that no registered NAKA table points into
NakaInst_OFF_E9DCFA:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17DAC, 0x1C
; [nakarest] Scale_Arabic2_NameTable  +0x17dc8..+0x17df8 (0xe9dd16, 48 B)
; [nakarest] purpose not established: 48 bytes at 0xe9dd16 that no registered NAKA table points into
Scale_Arabic2_NameTable:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17DC8, 0x30
; [nakarest] Scale_Arabic2_Plus11  +0x17df8..+0x17dfc (0xe9dd46, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe9dd46 that no registered NAKA table points into
Scale_Arabic2_Plus11:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17DF8, 0x4
; [nakarest] Scale_Arabic2_Plus10  +0x17dfc..+0x17e00 (0xe9dd4a, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe9dd4a that no registered NAKA table points into
Scale_Arabic2_Plus10:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17DFC, 0x4
; [nakarest] Scale_Arabic2_Plus9  +0x17e00..+0x17e04 (0xe9dd4e, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe9dd4e that no registered NAKA table points into
Scale_Arabic2_Plus9:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17E00, 0x4
; [nakarest] Scale_Arabic2_Plus8  +0x17e04..+0x17e08 (0xe9dd52, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe9dd52 that no registered NAKA table points into
Scale_Arabic2_Plus8:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17E04, 0x4
; [nakarest] Scale_Arabic2_Plus7  +0x17e08..+0x17e0c (0xe9dd56, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe9dd56 that no registered NAKA table points into
Scale_Arabic2_Plus7:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17E08, 0x4
; [nakarest] Scale_Arabic2_Plus6  +0x17e0c..+0x17e10 (0xe9dd5a, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe9dd5a that no registered NAKA table points into
Scale_Arabic2_Plus6:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17E0C, 0x4
; [nakarest] Scale_Arabic2_Plus5  +0x17e10..+0x17e14 (0xe9dd5e, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe9dd5e that no registered NAKA table points into
Scale_Arabic2_Plus5:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17E10, 0x4
; [nakarest] Scale_Arabic2_Plus4  +0x17e14..+0x17e18 (0xe9dd62, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe9dd62 that no registered NAKA table points into
Scale_Arabic2_Plus4:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17E14, 0x4
; [nakarest] Scale_Arabic2_Plus3  +0x17e18..+0x17e1c (0xe9dd66, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe9dd66 that no registered NAKA table points into
Scale_Arabic2_Plus3:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17E18, 0x4
; [nakarest] Scale_Arabic2_Plus2  +0x17e1c..+0x17e20 (0xe9dd6a, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe9dd6a that no registered NAKA table points into
Scale_Arabic2_Plus2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17E1C, 0x4
; [nakarest] Scale_Arabic2_Plus1  +0x17e20..+0x17e24 (0xe9dd6e, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe9dd6e that no registered NAKA table points into
Scale_Arabic2_Plus1:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17E20, 0x4
; [nakarest] Scale_Arabic2_Zero  +0x17e24..+0x17e28 (0xe9dd72, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe9dd72 that no registered NAKA table points into
Scale_Arabic2_Zero:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17E24, 0x4
; [nakarest] Scale_Names_Table  +0x17e28..+0x17e58 (0xe9dd76, 48 B)
; [nakarest] purpose not established: 48 bytes at 0xe9dd76 that no registered NAKA table points into
Scale_Names_Table:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17E28, 0x30
; [nakarest] NakaInst_KEY_B  +0x17e58..+0x17e62 (0xe9dda6, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9dda6 that no registered NAKA table points into
NakaInst_KEY_B:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17E58, 0xA
; [nakarest] NakaInst_KEY_A  +0x17e62..+0x17e6c (0xe9ddb0, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9ddb0 that no registered NAKA table points into
NakaInst_KEY_A:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17E62, 0xA
; [nakarest] NakaInst_KEY_A_E9DDBA  +0x17e6c..+0x17e76 (0xe9ddba, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9ddba that no registered NAKA table points into
NakaInst_KEY_A_E9DDBA:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17E6C, 0xA
; [nakarest] NakaInst_KEY_G  +0x17e76..+0x17e80 (0xe9ddc4, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9ddc4 that no registered NAKA table points into
NakaInst_KEY_G:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17E76, 0xA
; [nakarest] NakaInst_KEY_G_E9DDCE  +0x17e80..+0x17e8a (0xe9ddce, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9ddce that no registered NAKA table points into
NakaInst_KEY_G_E9DDCE:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17E80, 0xA
; [nakarest] NakaInst_KEY_F  +0x17e8a..+0x17e94 (0xe9ddd8, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9ddd8 that no registered NAKA table points into
NakaInst_KEY_F:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17E8A, 0xA
; [nakarest] NakaInst_KEY_F_E9DDE2  +0x17e94..+0x17e9e (0xe9dde2, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9dde2 that no registered NAKA table points into
NakaInst_KEY_F_E9DDE2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17E94, 0xA
; [nakarest] NakaInst_KEY_E  +0x17e9e..+0x17ea8 (0xe9ddec, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9ddec that no registered NAKA table points into
NakaInst_KEY_E:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17E9E, 0xA
; [nakarest] NakaInst_KEY_D  +0x17ea8..+0x17eb2 (0xe9ddf6, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9ddf6 that no registered NAKA table points into
NakaInst_KEY_D:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17EA8, 0xA
; [nakarest] NakaInst_KEY_D_E9DE00  +0x17eb2..+0x17ebc (0xe9de00, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9de00 that no registered NAKA table points into
NakaInst_KEY_D_E9DE00:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17EB2, 0xA
; [nakarest] NakaInst_KEY_C  +0x17ebc..+0x17ec6 (0xe9de0a, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9de0a that no registered NAKA table points into
NakaInst_KEY_C:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17EBC, 0xA
; [nakarest] NakaInst_KEY_C_E9DE14  +0x17ec6..+0x17ed8 (0xe9de14, 18 B)
; [nakarest] purpose not established: 18 bytes at 0xe9de14 that no registered NAKA table points into
NakaInst_KEY_C_E9DE14:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17EC6, 0x12
; [nakarest] Str_SOUND  +0x17ed8..+0x17ede (0xe9de26, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9de26 that no registered NAKA table points into
Str_SOUND:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17ED8, 0x6
NakaInst_TOTAL:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17EDE, 0x34
; -----------------------------------------------------------------------------
; [nakarest_retype] WelcomeGlyph_C
; WelcomeGlyph_C  --  'C', 1 glyph of 16 x 17 pixels, 1 bpp, 34 bytes
;
; What it is: the letter C, read from the bit pictures in the C
; (upside-down there, because the rows are stored bottom-up). No label
; of its own in the .s: other files reach it as NakaInst_TOTAL_0x34
; (.set in shared/positional_labels.s); it shares the old NakaInst_TOTAL
; slice with the strings above it. Drawn by the welcome-script op
; handlers: 'C' by op 4 alone and ops 9/12 as the first letter of
; COLO(U)R.
;
; Format, from DrawBitmapSP2_Impl (v10/v9 0xfac59d, v7 0xfac190): 1 bpp,
; each row one big-endian 16-bit word (MSB = leftmost pixel; the routine
; byte-swaps the word it loads), (width + 15) / 16 words per row; a set
; bit is drawn in the colour argument, a clear bit is not drawn. Rows
; are stored BOTTOM-UP: row i is drawn at y0 + height - i. The callers
; push height 0x11 (17) and pass width 0x10 (16) -- `pushw 0x11 ... ldw
; de, 0x10; call DrawBitmapSP2` -- in the welcome-script op handlers
; that follow AcWelcomScreen_RenderBytecode (v10/v9 0xf7f649, v7
; 0xf7f245) (ui/drawbar_panel_ui.s; that code is only partly framed as
; instructions there, and was checked against unidasm), so each glyph is
; 17 x 2 = 34 bytes.
;
; Which op draws which glyph (handlers at AcWelcomScreen_RenderBytecode
; + the WelcomeScript_OpJumpOffsets entry, decoded with unidasm because
; ui/drawbar_panel_ui.s frames that code only partly): op 4 C, op 5 O,
; op 6 L, op 7 R, op 11 U, op 8 I then N, and ops 9 and 12 (one shared
; handler, offset 386) C-O-L-O-R with the U drawn only when op == 12
; (`cp (XBC+0x08),0x000c; jr NZ` around it). Step table A (region code
; 2) uses ops 4/5/6/7 and 9 -- COLOR; table B uses 4/5/6/11/7 and 12 --
; COLOUR. Ops 4/5/6/7/11 push the step's arg as the colour (`pushw
; (xde)`, xde = &arg); op 8 pushes 0xff.
;
; Typed in naka_technichord_strings.c as uint8_t WelcomeGlyph_C[17][2].
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17F12, 0x22
; -----------------------------------------------------------------------------
; [nakarest_retype] Bitmap_Digit1
; Bitmap_Digit1  --  'I', 1 glyph of 16 x 17 pixels, 1 bpp, 34 bytes
;
; What it is: the letter I, read from the bit pictures in the C
; (upside-down there, because the rows are stored bottom-up). The label
; name (Digit1) predates this header: the glyph is the letter I, not a
; digit. Drawn by the welcome-script op handlers: 'I' by op 8, before
; the N.
;
; Format and readers: as WelcomeGlyph_C (the first glyph, above):
; DrawBitmapSP2_Impl (v10/v9 0xfac59d, v7 0xfac190) draws 16 x 17, 1
; bpp, one big-endian word per row, rows bottom-up; the op handlers
; after AcWelcomScreen_RenderBytecode (v10/v9 0xf7f649, v7 0xf7f245)
; pass width 0x10 and height 0x11.
;
; Typed in naka_technichord_strings.c as uint8_t Bitmap_Digit1[17][2].
; -----------------------------------------------------------------------------
Bitmap_Digit1:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17F34, 0x22
; -----------------------------------------------------------------------------
; [nakarest_retype] Bitmap_DigitL
; Bitmap_DigitL  --  'L', 'N', 'O', 3 glyphs of 16 x 17 pixels, 1 bpp, 102 bytes
;
; What it is: the letters L/N/O, read from the bit pictures in the C
; (upside-down there, because the rows are stored bottom-up). Glyphs 1
; and 2 are reached as Bitmap_DigitL_0x22 and Bitmap_DigitL_0x44 (.set
; in shared/positional_labels.s). Drawn by the welcome-script op
; handlers: 'L' by op 6 alone and ops 9/12 in COLO(U)R; 'N' by op 8,
; after the I; 'O' by op 5 alone and ops 9/12 twice in COLO(U)R.
;
; Format and readers: as WelcomeGlyph_C (the first glyph, above):
; DrawBitmapSP2_Impl (v10/v9 0xfac59d, v7 0xfac190) draws 16 x 17, 1
; bpp, one big-endian word per row, rows bottom-up; the op handlers
; after AcWelcomScreen_RenderBytecode (v10/v9 0xf7f649, v7 0xf7f245)
; pass width 0x10 and height 0x11.
;
; Typed in naka_technichord_strings.c as uint8_t
; Bitmap_DigitL[3][17][2].
; -----------------------------------------------------------------------------
Bitmap_DigitL:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17F56, 0x66
; -----------------------------------------------------------------------------
; [nakarest_retype] Bitmap_DigitR
; Bitmap_DigitR  --  'R', 1 glyph of 16 x 17 pixels, 1 bpp, 34 bytes
;
; What it is: the letter R, read from the bit pictures in the C
; (upside-down there, because the rows are stored bottom-up). Drawn by
; the welcome-script op handlers: 'R' by op 7 alone and ops 9/12 as the
; last letter of COLO(U)R.
;
; Format and readers: as WelcomeGlyph_C (the first glyph, above):
; DrawBitmapSP2_Impl (v10/v9 0xfac59d, v7 0xfac190) draws 16 x 17, 1
; bpp, one big-endian word per row, rows bottom-up; the op handlers
; after AcWelcomScreen_RenderBytecode (v10/v9 0xf7f649, v7 0xf7f245)
; pass width 0x10 and height 0x11.
;
; Typed in naka_technichord_strings.c as uint8_t Bitmap_DigitR[17][2].
; -----------------------------------------------------------------------------
Bitmap_DigitR:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17FBC, 0x22
; -----------------------------------------------------------------------------
; [nakarest_retype] Bitmap_DigitD
; Bitmap_DigitD  --  'U', 1 glyph of 16 x 17 pixels, 1 bpp, 34 bytes
;
; What it is: the letter U, read from the bit pictures in the C
; (upside-down there, because the rows are stored bottom-up). The old
; Bitmap_DigitD slice ran 0x121c bytes: this glyph and the five objects
; that follow it, which are split off below. Drawn by the welcome-script
; op handlers: 'U' by op 11 alone and ops 9/12 only when op == 12
; (COLOUR).
;
; Format and readers: as WelcomeGlyph_C (the first glyph, above):
; DrawBitmapSP2_Impl (v10/v9 0xfac59d, v7 0xfac190) draws 16 x 17, 1
; bpp, one big-endian word per row, rows bottom-up; the op handlers
; after AcWelcomScreen_RenderBytecode (v10/v9 0xf7f649, v7 0xf7f245)
; pass width 0x10 and height 0x11.
;
; Typed in naka_technichord_strings.c as uint8_t Bitmap_DigitD[17][2].
; -----------------------------------------------------------------------------
Bitmap_DigitD:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x17FDE, 0x22
; -----------------------------------------------------------------------------
; [nakarest_retype] WelcomeScript_Steps_A
; WelcomeScript_Steps_A  --  186 welcome_step_t records x 12 bytes = 2232 bytes
;
; The welcome-screen animation script used when Get_Region_Code returns
; 2. Reached by other files as Bitmap_DigitD_0x22 (.set in
; shared/positional_labels.s).
;
; Reader: AcWelcomScreenProc (v10/v9 0xf7f4a6, v7 0xf7f0a2), on its init
; message (0x1c00001), calls Get_Region_Code and stores the table
; address at 0x024786: Bitmap_DigitD+0x22 when the region code is 2,
; Bitmap_DigitD+0x8da otherwise (the two `ld xwa, Bitmap_DigitD_0x...`
; loads; those names are .set in shared/positional_labels.s). The step
; index lives at 0x024784; a step is table + 12*index (add, add, sll 2).
; AcWelcomScreen_Select_NextStep (v10/v9 0xf7f9c9, v7 0xf7f5c5)
; increments the index, reads the step's +0 and hands it to SetApTimer
; (a zero delay runs the next step at once); AcWelcomScreen_Select
; (v10/v9 0xf7f605, v7 0xf7f201) loads +8 as the op, runs it only when 0
; <= op <= 12, through WelcomeScript_OpJumpOffsets below, with the
; address of +10 in xde.
;
; Record layout (welcome_step_t, defined in naka_technichord_strings.c):
; +0 u32 delay (SetApTimer), +4 s16 x, +6 s16 y, +8 s16 op, +10 u16 arg.
; Count pinned by the layout: the table starts where the other one ends
; (or at the U glyph's end) and runs to the next object
; (WelcomeScreen_ClearRect) at a whole number of records; the only op-0
; step is the last one, and op 0's jump offset is 0 -- the code at
; AcWelcomScreen_RenderBytecode itself, which posts event 0x1e000b3, the
; event AcWelcomScreen_Init_SwitchMode also posts to leave the screen.
; Op histogram: op 0 x1, op 1 x1, op 2 x125, op 3 x1, op 4 x5, op 5 x10,
; op 6 x5, op 7 x5, op 8 x1, op 9 x32.
;
; Typed in naka_technichord_strings.c as welcome_step_t
; WelcomeScript_Steps_A[186].
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_strings.bin", 0x18000, 0x8B8
; -----------------------------------------------------------------------------
; [nakarest_retype] WelcomeScript_Steps_B
; WelcomeScript_Steps_B  --  191 welcome_step_t records x 12 bytes = 2292 bytes
;
; The welcome-screen animation script used for every other region code.
; Reached by other files as Bitmap_DigitD_0x8da (.set in
; shared/positional_labels.s).
;
; Reader: AcWelcomScreenProc (v10/v9 0xf7f4a6, v7 0xf7f0a2), on its init
; message (0x1c00001), calls Get_Region_Code and stores the table
; address at 0x024786: Bitmap_DigitD+0x22 when the region code is 2,
; Bitmap_DigitD+0x8da otherwise (the two `ld xwa, Bitmap_DigitD_0x...`
; loads; those names are .set in shared/positional_labels.s). The step
; index lives at 0x024784; a step is table + 12*index (add, add, sll 2).
; AcWelcomScreen_Select_NextStep (v10/v9 0xf7f9c9, v7 0xf7f5c5)
; increments the index, reads the step's +0 and hands it to SetApTimer
; (a zero delay runs the next step at once); AcWelcomScreen_Select
; (v10/v9 0xf7f605, v7 0xf7f201) loads +8 as the op, runs it only when 0
; <= op <= 12, through WelcomeScript_OpJumpOffsets below, with the
; address of +10 in xde.
;
; Record layout (welcome_step_t, defined in naka_technichord_strings.c):
; +0 u32 delay (SetApTimer), +4 s16 x, +6 s16 y, +8 s16 op, +10 u16 arg.
; Count pinned by the layout: the table starts where the other one ends
; (or at the U glyph's end) and runs to the next object
; (WelcomeScreen_ClearRect) at a whole number of records; the only op-0
; step is the last one, and op 0's jump offset is 0 -- the code at
; AcWelcomScreen_RenderBytecode itself, which posts event 0x1e000b3, the
; event AcWelcomScreen_Init_SwitchMode also posts to leave the screen.
; Op histogram: op 0 x1, op 1 x1, op 2 x125, op 3 x1, op 4 x5, op 5 x10,
; op 6 x5, op 7 x5, op 8 x1, op 11 x5, op 12 x32.
;
; Typed in naka_technichord_strings.c as welcome_step_t
; WelcomeScript_Steps_B[191].
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_strings.bin", 0x188B8, 0x8F4
; -----------------------------------------------------------------------------
; [nakarest_retype] WelcomeScreen_ClearRect
; WelcomeScreen_ClearRect  --  4 x s16 {x1, y1, x2, y2} = {0, 0, 319, 239}
;
; The whole 320 x 240 screen. AcWelcomScreen_Activate (v10/v9 0xf7f595,
; v7 0xf7f191) (when CheckNotDrawFlag is clear) turns the LCD off,
; passes this rectangle to DrawBox with colour 0, updates the screen and
; turns the LCD back on (`ld xwa, Bitmap_DigitD_0x11ce; ld bc, 0; call
; DrawBox`; the name is .set in shared/positional_labels.s). The
; generator had read its last four bytes 3F 01 EF 00 as a pointer to
; Naka_PresentationRootState (0x00ef013f); they are x2 = 319, y2 = 239.
;
; Typed as int16_t WelcomeScreen_ClearRect[4].
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_strings.bin", 0x191AC, 0x8
; -----------------------------------------------------------------------------
; [nakarest_retype] WelcomeScript_OpJumpOffsets
; WelcomeScript_OpJumpOffsets  --  13 x s16 code offsets, one per op 0..12
;
; AcWelcomScreen_Select (v10/v9 0xf7f605, v7 0xf7f201) doubles the op
; (add hl, hl), loads the word at Bitmap_DigitD_0x11d6 + 2*op (the name
; is .set in shared/positional_labels.s), loads xix with
; AcWelcomScreen_RenderBytecode and jumps indirectly -- so each entry is
; the offset of an op handler from AcWelcomScreen_RenderBytecode.
; Values: 0, 896, 15, 162, 179, 208, 237, 293, 321, 386, 860, 265, 386.
; What each handler does (decoded with unidasm at label + offset, v10):
; op 0 (+0) posts 0x1e000b3 and ends the script; op 1 (+896) just
; advances to the next step; op 2 (+15) reads arg (cp iz, 2) and a
; 12-byte record table in RAM at 0x03ea0c (that table was not followed);
; op 3 (+162) calls SendEvent with 0x1c0000c; ops 4/5/6/7/11
; (+179/+208/+237/+293/+265) draw one glyph each -- C, O, L, R, U; op 8
; (+321) draws I then N; ops 9 and 12 (+386) draw C-O-L-O(-U)-R; op 10
; (+860) calls ApFuncCall on 0x120000b with 0x1e000ac, CaptureLcd, then
; 0x1e000ad. That code is not yet framed as instructions in
; ui/drawbar_panel_ui.s, so the targets stay offsets, not labels.
;
; Typed as int16_t WelcomeScript_OpJumpOffsets[13].
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_strings.bin", 0x191B4, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] PsMixer_ControlProcTable
; PsMixer_ControlProcTable  --  11 x u32 code addresses
;
; PsMixer_ControlHelper (v10/v9 0xf7fcb0, v7 0xf7f8ac)
; (ui/drawbar_panel_ui.s) loads the word at +2 of a control record,
; multiplies it by 4 and indexes this table (lda xbc,
; Bitmap_DigitD_0x11f0 -- .set in shared/positional_labels.s -- then an
; indexed load into xhl), and calls the entry with xbc = 0x1c0000d, the
; paint message; the same `lda xbc, Bitmap_DigitD_0x11f0` occurs at 14
; sites in that file. The eleven values (v10/v9) are 0xf80b7d, 0xf81ed2,
; 0xf81b56, 0xf80ee9, 0xf815e5, 0xf80b80, 0xf80d21, 0xf812af, 0xf8231b,
; 0xf81890, 0xf82222: all inside the AudioCtrl_DataBlock_* stretch of
; ui/drawbar_panel_ui.s, where only 0xf812af, 0xf81890 and 0xf81ed2 are
; on a label (AudioCtrl_DataBlock_Helper6/7/8) -- the other eight are
; entry points that file's framing does not show. v7 moves every entry
; by -0x404 through v7_c_divergence.json (offsets 102862..102902), which
; is itself evidence that they are code addresses. Kept numeric here
; because the targets have no labels to name.
;
; Typed as uint32_t PsMixer_ControlProcTable[11].
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_technichord_strings.bin", 0x191CE, 0x2C
; [nakarest] MidiParam_PanelCfgTable  +0x191fa..+0x192ae (0xe9f148, 180 B)
; [nakarest] purpose not established: 180 bytes at 0xe9f148 that no registered NAKA table points into
MidiParam_PanelCfgTable:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x191FA, 0xB4
; [nakarest] MidiParamStr1_Local  +0x192ae..+0x192b6 (0xe9f1fc, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f1fc that no registered NAKA table points into
MidiParamStr1_Local:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x192AE, 0x8
; [nakarest] MidiParamStr1_Midi  +0x192b6..+0x192be (0xe9f204, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f204 that no registered NAKA table points into
MidiParamStr1_Midi:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x192B6, 0x8
; [nakarest] MidiParamStr1_Empty  +0x192be..+0x192c2 (0xe9f20c, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe9f20c that no registered NAKA table points into
MidiParamStr1_Empty:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x192BE, 0x4
; [nakarest] MidiParamStr1_KeyShift  +0x192c2..+0x192d8 (0xe9f210, 22 B)
; [nakarest] purpose not established: 22 bytes at 0xe9f210 that no registered NAKA table points into
MidiParamStr1_KeyShift:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x192C2, 0x16
; [nakarest] MidiParamStr1_DspEff  +0x192d8..+0x192e8 (0xe9f226, 16 B)
; [nakarest] purpose not established: 16 bytes at 0xe9f226 that no registered NAKA table points into
MidiParamStr1_DspEff:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x192D8, 0x10
; [nakarest] MidiParamStr1_Volume  +0x192e8..+0x192f2 (0xe9f236, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9f236 that no registered NAKA table points into
MidiParamStr1_Volume:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x192E8, 0xA
; [nakarest] MidiParamStr1_Pan  +0x192f2..+0x192fc (0xe9f240, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9f240 that no registered NAKA table points into
MidiParamStr1_Pan:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x192F2, 0xA
; [nakarest] MidiParamStr1_End  +0x192fc..+0x192fe (0xe9f24a, 2 B)
; [nakarest] purpose not established: 2 bytes at 0xe9f24a that no registered NAKA table points into
MidiParamStr1_End:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x192FC, 0x2
; [nakarest] Midi_PartToChMappingTable  +0x192fe..+0x1933e (0xe9f24c, 64 B)
; [nakarest] purpose not established: 64 bytes at 0xe9f24c that no registered NAKA table points into
Midi_PartToChMappingTable:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x192FE, 0x40
; [nakarest] PartName6_Blank  +0x1933e..+0x19346 (0xe9f28c, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f28c that no registered NAKA table points into
PartName6_Blank:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1933E, 0x8
; [nakarest] PartName6_Rhythm  +0x19346..+0x1934e (0xe9f294, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f294 that no registered NAKA table points into
PartName6_Rhythm:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19346, 0x8
; [nakarest] PartName6_Ctrl  +0x1934e..+0x19356 (0xe9f29c, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f29c that no registered NAKA table points into
PartName6_Ctrl:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1934E, 0x8
; [nakarest] PartName6_Apc  +0x19356..+0x1935e (0xe9f2a4, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f2a4 that no registered NAKA table points into
PartName6_Apc:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19356, 0x8
; [nakarest] PartName6_Mic  +0x1935e..+0x19366 (0xe9f2ac, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f2ac that no registered NAKA table points into
PartName6_Mic:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1935E, 0x8
; [nakarest] PartName6_Metro  +0x19366..+0x1936e (0xe9f2b4, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f2b4 that no registered NAKA table points into
PartName6_Metro:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19366, 0x8
; [nakarest] PartName6_Msp  +0x1936e..+0x19376 (0xe9f2bc, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f2bc that no registered NAKA table points into
PartName6_Msp:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1936E, 0x8
; [nakarest] PartName6_Drums  +0x19376..+0x1937e (0xe9f2c4, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f2c4 that no registered NAKA table points into
PartName6_Drums:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19376, 0x8
; [nakarest] PartName6_Bass  +0x1937e..+0x19386 (0xe9f2cc, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f2cc that no registered NAKA table points into
PartName6_Bass:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1937E, 0x8
; [nakarest] PartName6_Acomp3  +0x19386..+0x1938e (0xe9f2d4, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f2d4 that no registered NAKA table points into
PartName6_Acomp3:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19386, 0x8
; [nakarest] PartName6_Acomp2  +0x1938e..+0x19396 (0xe9f2dc, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f2dc that no registered NAKA table points into
PartName6_Acomp2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1938E, 0x8
; [nakarest] PartName6_Acomp1  +0x19396..+0x1939e (0xe9f2e4, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f2e4 that no registered NAKA table points into
PartName6_Acomp1:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19396, 0x8
; [nakarest] PartName6_RBass  +0x1939e..+0x193a6 (0xe9f2ec, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f2ec that no registered NAKA table points into
PartName6_RBass:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1939E, 0x8
; [nakarest] PartName6_Chord  +0x193a6..+0x193ae (0xe9f2f4, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f2f4 that no registered NAKA table points into
PartName6_Chord:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x193A6, 0x8
; [nakarest] PartName6_Part16  +0x193ae..+0x193b6 (0xe9f2fc, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f2fc that no registered NAKA table points into
PartName6_Part16:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x193AE, 0x8
; [nakarest] PartName6_Part15  +0x193b6..+0x193be (0xe9f304, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f304 that no registered NAKA table points into
PartName6_Part15:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x193B6, 0x8
; [nakarest] PartName6_Part14  +0x193be..+0x193c6 (0xe9f30c, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f30c that no registered NAKA table points into
PartName6_Part14:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x193BE, 0x8
; [nakarest] PartName6_Part13  +0x193c6..+0x193ce (0xe9f314, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f314 that no registered NAKA table points into
PartName6_Part13:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x193C6, 0x8
; [nakarest] PartName6_Part12  +0x193ce..+0x193d6 (0xe9f31c, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f31c that no registered NAKA table points into
PartName6_Part12:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x193CE, 0x8
; [nakarest] PartName6_Part11  +0x193d6..+0x193de (0xe9f324, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f324 that no registered NAKA table points into
PartName6_Part11:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x193D6, 0x8
; [nakarest] PartName6_Part10  +0x193de..+0x193e6 (0xe9f32c, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f32c that no registered NAKA table points into
PartName6_Part10:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x193DE, 0x8
; [nakarest] PartName6_Part9  +0x193e6..+0x193ee (0xe9f334, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f334 that no registered NAKA table points into
PartName6_Part9:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x193E6, 0x8
; [nakarest] PartName6_Part8  +0x193ee..+0x193f6 (0xe9f33c, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f33c that no registered NAKA table points into
PartName6_Part8:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x193EE, 0x8
; [nakarest] PartName6_Part7  +0x193f6..+0x193fe (0xe9f344, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f344 that no registered NAKA table points into
PartName6_Part7:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x193F6, 0x8
; [nakarest] PartName6_Part6  +0x193fe..+0x19406 (0xe9f34c, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f34c that no registered NAKA table points into
PartName6_Part6:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x193FE, 0x8
; [nakarest] PartName6_Part5  +0x19406..+0x1940e (0xe9f354, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f354 that no registered NAKA table points into
PartName6_Part5:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19406, 0x8
; [nakarest] PartName6_Part4  +0x1940e..+0x19416 (0xe9f35c, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f35c that no registered NAKA table points into
PartName6_Part4:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1940E, 0x8
; [nakarest] PartName6_Left  +0x19416..+0x1941e (0xe9f364, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f364 that no registered NAKA table points into
PartName6_Left:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19416, 0x8
; [nakarest] PartName6_Right2  +0x1941e..+0x19426 (0xe9f36c, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f36c that no registered NAKA table points into
PartName6_Right2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1941E, 0x8
; [nakarest] PartName6_Right1  +0x19426..+0x1942e (0xe9f374, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f374 that no registered NAKA table points into
PartName6_Right1:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19426, 0x8
; [nakarest] PartName6_TableEnd  +0x1942e..+0x19434 (0xe9f37c, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f37c that no registered NAKA table points into
PartName6_TableEnd:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1942E, 0x6
; [nakarest] PartName4_Rhythm  +0x19434..+0x1943a (0xe9f382, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f382 that no registered NAKA table points into
PartName4_Rhythm:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19434, 0x6
; [nakarest] PartName4_Ctrl  +0x1943a..+0x19440 (0xe9f388, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f388 that no registered NAKA table points into
PartName4_Ctrl:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1943A, 0x6
; [nakarest] PartName4_Apc  +0x19440..+0x19446 (0xe9f38e, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f38e that no registered NAKA table points into
PartName4_Apc:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19440, 0x6
; [nakarest] PartName4_Mic  +0x19446..+0x1944c (0xe9f394, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f394 that no registered NAKA table points into
PartName4_Mic:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19446, 0x6
; [nakarest] PartName4_Metro  +0x1944c..+0x19452 (0xe9f39a, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f39a that no registered NAKA table points into
PartName4_Metro:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1944C, 0x6
; [nakarest] PartName4_Msp  +0x19452..+0x19458 (0xe9f3a0, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f3a0 that no registered NAKA table points into
PartName4_Msp:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19452, 0x6
; [nakarest] PartName4_Drums  +0x19458..+0x1945e (0xe9f3a6, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f3a6 that no registered NAKA table points into
PartName4_Drums:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19458, 0x6
; [nakarest] PartName4_Bass  +0x1945e..+0x19464 (0xe9f3ac, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f3ac that no registered NAKA table points into
PartName4_Bass:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1945E, 0x6
; [nakarest] PartName4_Acomp3  +0x19464..+0x1946a (0xe9f3b2, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f3b2 that no registered NAKA table points into
PartName4_Acomp3:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19464, 0x6
; [nakarest] PartName4_Acomp2  +0x1946a..+0x19470 (0xe9f3b8, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f3b8 that no registered NAKA table points into
PartName4_Acomp2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1946A, 0x6
; [nakarest] PartName4_Acomp1  +0x19470..+0x19476 (0xe9f3be, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f3be that no registered NAKA table points into
PartName4_Acomp1:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19470, 0x6
; [nakarest] PartName4_RBass  +0x19476..+0x1947c (0xe9f3c4, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f3c4 that no registered NAKA table points into
PartName4_RBass:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19476, 0x6
; [nakarest] PartName4_Chord  +0x1947c..+0x19482 (0xe9f3ca, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f3ca that no registered NAKA table points into
PartName4_Chord:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1947C, 0x6
; [nakarest] PartName4_Part16  +0x19482..+0x19488 (0xe9f3d0, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f3d0 that no registered NAKA table points into
PartName4_Part16:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19482, 0x6
; [nakarest] PartName4_Part15  +0x19488..+0x1948e (0xe9f3d6, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f3d6 that no registered NAKA table points into
PartName4_Part15:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19488, 0x6
; [nakarest] PartName4_Part14  +0x1948e..+0x19494 (0xe9f3dc, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f3dc that no registered NAKA table points into
PartName4_Part14:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1948E, 0x6
; [nakarest] PartName4_Part13  +0x19494..+0x1949a (0xe9f3e2, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f3e2 that no registered NAKA table points into
PartName4_Part13:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19494, 0x6
; [nakarest] PartName4_Part12  +0x1949a..+0x194a0 (0xe9f3e8, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f3e8 that no registered NAKA table points into
PartName4_Part12:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1949A, 0x6
; [nakarest] PartName4_Part11  +0x194a0..+0x194a6 (0xe9f3ee, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f3ee that no registered NAKA table points into
PartName4_Part11:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x194A0, 0x6
; [nakarest] PartName4_Part10  +0x194a6..+0x194ac (0xe9f3f4, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f3f4 that no registered NAKA table points into
PartName4_Part10:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x194A6, 0x6
; [nakarest] PartName4_Part9  +0x194ac..+0x194b2 (0xe9f3fa, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f3fa that no registered NAKA table points into
PartName4_Part9:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x194AC, 0x6
; [nakarest] PartName4_Part8  +0x194b2..+0x194b8 (0xe9f400, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f400 that no registered NAKA table points into
PartName4_Part8:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x194B2, 0x6
; [nakarest] PartName4_Part7  +0x194b8..+0x194be (0xe9f406, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f406 that no registered NAKA table points into
PartName4_Part7:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x194B8, 0x6
; [nakarest] PartName4_Part6  +0x194be..+0x194c4 (0xe9f40c, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f40c that no registered NAKA table points into
PartName4_Part6:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x194BE, 0x6
; [nakarest] PartName4_Part5  +0x194c4..+0x194ca (0xe9f412, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f412 that no registered NAKA table points into
PartName4_Part5:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x194C4, 0x6
; [nakarest] PartName4_Part4  +0x194ca..+0x194d0 (0xe9f418, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f418 that no registered NAKA table points into
PartName4_Part4:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x194CA, 0x6
; [nakarest] PartName4_Left  +0x194d0..+0x194d6 (0xe9f41e, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f41e that no registered NAKA table points into
PartName4_Left:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x194D0, 0x6
; [nakarest] PartName4_Right2  +0x194d6..+0x194dc (0xe9f424, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f424 that no registered NAKA table points into
PartName4_Right2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x194D6, 0x6
; [nakarest] PartName4_Right1  +0x194dc..+0x194e2 (0xe9f42a, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f42a that no registered NAKA table points into
PartName4_Right1:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x194DC, 0x6
; [nakarest] AccompName6_Chord  +0x194e2..+0x194ea (0xe9f430, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f430 that no registered NAKA table points into
AccompName6_Chord:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x194E2, 0x8
; [nakarest] AccompName6_RBass  +0x194ea..+0x194f2 (0xe9f438, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f438 that no registered NAKA table points into
AccompName6_RBass:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x194EA, 0x8
; [nakarest] AccompName6_Msp  +0x194f2..+0x194fa (0xe9f440, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f440 that no registered NAKA table points into
AccompName6_Msp:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x194F2, 0x8
; [nakarest] AccompName6_Bass  +0x194fa..+0x19502 (0xe9f448, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f448 that no registered NAKA table points into
AccompName6_Bass:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x194FA, 0x8
; [nakarest] AccompName6_Acomp1  +0x19502..+0x1950a (0xe9f450, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f450 that no registered NAKA table points into
AccompName6_Acomp1:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19502, 0x8
; [nakarest] AccompName6_Acomp2  +0x1950a..+0x19512 (0xe9f458, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f458 that no registered NAKA table points into
AccompName6_Acomp2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1950A, 0x8
; [nakarest] AccompName6_Acomp3  +0x19512..+0x1951a (0xe9f460, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f460 that no registered NAKA table points into
AccompName6_Acomp3:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19512, 0x8
; [nakarest] AccompName6_Drums  +0x1951a..+0x19522 (0xe9f468, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f468 that no registered NAKA table points into
AccompName6_Drums:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1951A, 0x8
; [nakarest] TrackName6_Tr16  +0x19522..+0x1952a (0xe9f470, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f470 that no registered NAKA table points into
TrackName6_Tr16:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19522, 0x8
; [nakarest] TrackName6_Tr15  +0x1952a..+0x19532 (0xe9f478, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f478 that no registered NAKA table points into
TrackName6_Tr15:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1952A, 0x8
; [nakarest] TrackName6_Tr14  +0x19532..+0x1953a (0xe9f480, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f480 that no registered NAKA table points into
TrackName6_Tr14:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19532, 0x8
; [nakarest] TrackName6_Tr13  +0x1953a..+0x19542 (0xe9f488, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f488 that no registered NAKA table points into
TrackName6_Tr13:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1953A, 0x8
; [nakarest] TrackName6_Tr12  +0x19542..+0x1954a (0xe9f490, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f490 that no registered NAKA table points into
TrackName6_Tr12:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19542, 0x8
; [nakarest] TrackName6_Tr11  +0x1954a..+0x19552 (0xe9f498, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f498 that no registered NAKA table points into
TrackName6_Tr11:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1954A, 0x8
; [nakarest] TrackName6_Tr10  +0x19552..+0x1955a (0xe9f4a0, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f4a0 that no registered NAKA table points into
TrackName6_Tr10:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19552, 0x8
; [nakarest] TrackName6_Tr9  +0x1955a..+0x19562 (0xe9f4a8, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f4a8 that no registered NAKA table points into
TrackName6_Tr9:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1955A, 0x8
; [nakarest] TrackName6_Tr8  +0x19562..+0x1956a (0xe9f4b0, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f4b0 that no registered NAKA table points into
TrackName6_Tr8:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19562, 0x8
; [nakarest] TrackName6_Tr7  +0x1956a..+0x19572 (0xe9f4b8, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f4b8 that no registered NAKA table points into
TrackName6_Tr7:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1956A, 0x8
; [nakarest] TrackName6_Tr6  +0x19572..+0x1957a (0xe9f4c0, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f4c0 that no registered NAKA table points into
TrackName6_Tr6:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19572, 0x8
; [nakarest] TrackName6_Tr5  +0x1957a..+0x19582 (0xe9f4c8, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f4c8 that no registered NAKA table points into
TrackName6_Tr5:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1957A, 0x8
; [nakarest] TrackName6_Tr4  +0x19582..+0x1958a (0xe9f4d0, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f4d0 that no registered NAKA table points into
TrackName6_Tr4:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19582, 0x8
; [nakarest] TrackName6_Tr3  +0x1958a..+0x19592 (0xe9f4d8, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f4d8 that no registered NAKA table points into
TrackName6_Tr3:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1958A, 0x8
; [nakarest] TrackName6_Tr2  +0x19592..+0x1959a (0xe9f4e0, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f4e0 that no registered NAKA table points into
TrackName6_Tr2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19592, 0x8
; [nakarest] TrackName6_Tr1  +0x1959a..+0x195a2 (0xe9f4e8, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f4e8 that no registered NAKA table points into
TrackName6_Tr1:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1959A, 0x8
; [nakarest] TrackName6_Unassigned  +0x195a2..+0x195a8 (0xe9f4f0, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f4f0 that no registered NAKA table points into
TrackName6_Unassigned:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x195A2, 0x6
; [nakarest] TrackName6_Unassigned_02  +0x195a8..+0x195ae (0xe9f4f6, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f4f6 that no registered NAKA table points into
TrackName6_Unassigned_02:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x195A8, 0x6
; [nakarest] TrackName6_Unassigned_03  +0x195ae..+0x195b4 (0xe9f4fc, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f4fc that no registered NAKA table points into
TrackName6_Unassigned_03:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x195AE, 0x6
; [nakarest] TrackName6_Unassigned_04  +0x195b4..+0x195ba (0xe9f502, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f502 that no registered NAKA table points into
TrackName6_Unassigned_04:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x195B4, 0x6
; [nakarest] TrackName6_Unassigned_05  +0x195ba..+0x195c0 (0xe9f508, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f508 that no registered NAKA table points into
TrackName6_Unassigned_05:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x195BA, 0x6
; [nakarest] TrackName6_Unassigned_06  +0x195c0..+0x195c6 (0xe9f50e, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f50e that no registered NAKA table points into
TrackName6_Unassigned_06:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x195C0, 0x6
; [nakarest] TrackName6_Unassigned_07  +0x195c6..+0x195cc (0xe9f514, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f514 that no registered NAKA table points into
TrackName6_Unassigned_07:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x195C6, 0x6
; [nakarest] TrackName6_Unassigned_08  +0x195cc..+0x195d2 (0xe9f51a, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f51a that no registered NAKA table points into
TrackName6_Unassigned_08:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x195CC, 0x6
; [nakarest] TrackName4_Tr16  +0x195d2..+0x195d8 (0xe9f520, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f520 that no registered NAKA table points into
TrackName4_Tr16:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x195D2, 0x6
; [nakarest] TrackName4_Tr15  +0x195d8..+0x195de (0xe9f526, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f526 that no registered NAKA table points into
TrackName4_Tr15:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x195D8, 0x6
; [nakarest] TrackName4_Tr14  +0x195de..+0x195e4 (0xe9f52c, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f52c that no registered NAKA table points into
TrackName4_Tr14:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x195DE, 0x6
; [nakarest] TrackName4_Tr13  +0x195e4..+0x195ea (0xe9f532, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f532 that no registered NAKA table points into
TrackName4_Tr13:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x195E4, 0x6
; [nakarest] TrackName4_Tr12  +0x195ea..+0x195f0 (0xe9f538, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f538 that no registered NAKA table points into
TrackName4_Tr12:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x195EA, 0x6
; [nakarest] TrackName4_Tr11  +0x195f0..+0x195f6 (0xe9f53e, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f53e that no registered NAKA table points into
TrackName4_Tr11:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x195F0, 0x6
; [nakarest] TrackName4_Tr10  +0x195f6..+0x195fc (0xe9f544, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f544 that no registered NAKA table points into
TrackName4_Tr10:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x195F6, 0x6
; [nakarest] TrackName4_Tr9  +0x195fc..+0x19602 (0xe9f54a, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f54a that no registered NAKA table points into
TrackName4_Tr9:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x195FC, 0x6
; [nakarest] TrackName4_Tr8  +0x19602..+0x19608 (0xe9f550, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f550 that no registered NAKA table points into
TrackName4_Tr8:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19602, 0x6
; [nakarest] TrackName4_Tr7  +0x19608..+0x1960e (0xe9f556, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f556 that no registered NAKA table points into
TrackName4_Tr7:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19608, 0x6
; [nakarest] TrackName4_Tr6  +0x1960e..+0x19614 (0xe9f55c, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f55c that no registered NAKA table points into
TrackName4_Tr6:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1960E, 0x6
; [nakarest] TrackName4_Tr5  +0x19614..+0x1961a (0xe9f562, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f562 that no registered NAKA table points into
TrackName4_Tr5:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19614, 0x6
; [nakarest] TrackName4_Tr4  +0x1961a..+0x19620 (0xe9f568, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f568 that no registered NAKA table points into
TrackName4_Tr4:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1961A, 0x6
; [nakarest] TrackName4_Tr3  +0x19620..+0x19626 (0xe9f56e, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f56e that no registered NAKA table points into
TrackName4_Tr3:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19620, 0x6
; [nakarest] TrackName4_Tr2  +0x19626..+0x1962c (0xe9f574, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9f574 that no registered NAKA table points into
TrackName4_Tr2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19626, 0x6
; [nakarest] TrackName4_Tr1  +0x1962c..+0x19722 (0xe9f57a, 246 B)
; [nakarest] purpose not established: 246 bytes at 0xe9f57a that no registered NAKA table points into
TrackName4_Tr1:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1962C, 0xF6
; [nakarest] MidiParamStr2_End  +0x19722..+0x19724 (0xe9f670, 2 B)
; [nakarest] purpose not established: 2 bytes at 0xe9f670 that no registered NAKA table points into
MidiParamStr2_End:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19722, 0x2
; [nakarest] MidiParamStr2_Local  +0x19724..+0x19730 (0xe9f672, 12 B)
; [nakarest] purpose not established: 12 bytes at 0xe9f672 that no registered NAKA table points into
MidiParamStr2_Local:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19724, 0xC
; [nakarest] MidiParamStr2_Empty  +0x19730..+0x19734 (0xe9f67e, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe9f67e that no registered NAKA table points into
MidiParamStr2_Empty:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19730, 0x4
; [nakarest] MidiParamStr2_KeyShift  +0x19734..+0x19740 (0xe9f682, 12 B)
; [nakarest] purpose not established: 12 bytes at 0xe9f682 that no registered NAKA table points into
MidiParamStr2_KeyShift:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19734, 0xC
; [nakarest] MidiParamStr2_DspEff  +0x19740..+0x19754 (0xe9f68e, 20 B)
; [nakarest] purpose not established: 20 bytes at 0xe9f68e that no registered NAKA table points into
MidiParamStr2_DspEff:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19740, 0x14
; [nakarest] MidiParamStr2_Reverb  +0x19754..+0x1975e (0xe9f6a2, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9f6a2 that no registered NAKA table points into
MidiParamStr2_Reverb:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19754, 0xA
; [nakarest] MidiParamStr2_Volume  +0x1975e..+0x1976a (0xe9f6ac, 12 B)
; [nakarest] purpose not established: 12 bytes at 0xe9f6ac that no registered NAKA table points into
MidiParamStr2_Volume:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1975E, 0xC
; [nakarest] MidiParamStr2_Sound  +0x1976a..+0x19866 (0xe9f6b8, 252 B)
; [nakarest] purpose not established: 252 bytes at 0xe9f6b8 that no registered NAKA table points into
MidiParamStr2_Sound:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1976A, 0xFC
; [nakarest] MidiParamStr3_Local  +0x19866..+0x1986e (0xe9f7b4, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f7b4 that no registered NAKA table points into
MidiParamStr3_Local:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19866, 0x8
; [nakarest] MidiParamStr3_Midi  +0x1986e..+0x19876 (0xe9f7bc, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9f7bc that no registered NAKA table points into
MidiParamStr3_Midi:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1986E, 0x8
; [nakarest] MidiParamStr3_Empty  +0x19876..+0x1987a (0xe9f7c4, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe9f7c4 that no registered NAKA table points into
MidiParamStr3_Empty:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19876, 0x4
; [nakarest] MidiParamStr3_KeyShift  +0x1987a..+0x19890 (0xe9f7c8, 22 B)
; [nakarest] purpose not established: 22 bytes at 0xe9f7c8 that no registered NAKA table points into
MidiParamStr3_KeyShift:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1987A, 0x16
; [nakarest] MidiParamStr3_DspEff  +0x19890..+0x198a0 (0xe9f7de, 16 B)
; [nakarest] purpose not established: 16 bytes at 0xe9f7de that no registered NAKA table points into
MidiParamStr3_DspEff:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19890, 0x10
; [nakarest] MidiParamStr3_Volume  +0x198a0..+0x198aa (0xe9f7ee, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9f7ee that no registered NAKA table points into
MidiParamStr3_Volume:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x198A0, 0xA
; [nakarest] MidiParamStr3_Pan  +0x198aa..+0x198b4 (0xe9f7f8, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xe9f7f8 that no registered NAKA table points into
MidiParamStr3_Pan:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x198AA, 0xA
; [nakarest] MidiParam_MixerCfgData  +0x198b4..+0x1995c (0xe9f802, 168 B)
; [nakarest] purpose not established: 168 bytes at 0xe9f802 that no registered NAKA table points into
MidiParam_MixerCfgData:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x198B4, 0xA8
; [nakarest] KeyShift_DisplayStrTable  +0x1995c..+0x1999c (0xe9f8aa, 64 B)
; [nakarest] purpose not established: 64 bytes at 0xe9f8aa that no registered NAKA table points into
KeyShift_DisplayStrTable:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1995C, 0x40
; [nakarest] KeyShiftStr_Minus1  +0x1999c..+0x199a0 (0xe9f8ea, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe9f8ea that no registered NAKA table points into
KeyShiftStr_Minus1:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1999C, 0x4
; [nakarest] KeyShiftStr_Minus2  +0x199a0..+0x199a4 (0xe9f8ee, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe9f8ee that no registered NAKA table points into
KeyShiftStr_Minus2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x199A0, 0x4
; [nakarest] KeyShiftStr_Minus3  +0x199a4..+0x199a8 (0xe9f8f2, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe9f8f2 that no registered NAKA table points into
KeyShiftStr_Minus3:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x199A4, 0x4
; [nakarest] KeyShiftStr_Minus4  +0x199a8..+0x199ac (0xe9f8f6, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe9f8f6 that no registered NAKA table points into
KeyShiftStr_Minus4:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x199A8, 0x4
; [nakarest] KeyShiftStr_Minus5  +0x199ac..+0x199b0 (0xe9f8fa, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe9f8fa that no registered NAKA table points into
KeyShiftStr_Minus5:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x199AC, 0x4
; [nakarest] KeyShiftStr_Minus6  +0x199b0..+0x199b4 (0xe9f8fe, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe9f8fe that no registered NAKA table points into
KeyShiftStr_Minus6:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x199B0, 0x4
; [nakarest] KeyShiftStr_Minus7  +0x199b4..+0x199b8 (0xe9f902, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe9f902 that no registered NAKA table points into
KeyShiftStr_Minus7:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x199B4, 0x4
; [nakarest] KeyShiftStr_Minus8  +0x199b8..+0x199bc (0xe9f906, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe9f906 that no registered NAKA table points into
KeyShiftStr_Minus8:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x199B8, 0x4
; [nakarest] KeyShiftStr_Plus7  +0x199bc..+0x199c0 (0xe9f90a, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe9f90a that no registered NAKA table points into
KeyShiftStr_Plus7:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x199BC, 0x4
; [nakarest] KeyShiftStr_Plus6  +0x199c0..+0x199c4 (0xe9f90e, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe9f90e that no registered NAKA table points into
KeyShiftStr_Plus6:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x199C0, 0x4
; [nakarest] KeyShiftStr_Plus5  +0x199c4..+0x199c8 (0xe9f912, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe9f912 that no registered NAKA table points into
KeyShiftStr_Plus5:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x199C4, 0x4
; [nakarest] KeyShiftStr_Plus4  +0x199c8..+0x199cc (0xe9f916, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe9f916 that no registered NAKA table points into
KeyShiftStr_Plus4:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x199C8, 0x4
; [nakarest] KeyShiftStr_Plus3  +0x199cc..+0x199d0 (0xe9f91a, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe9f91a that no registered NAKA table points into
KeyShiftStr_Plus3:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x199CC, 0x4
; [nakarest] KeyShiftStr_Plus2  +0x199d0..+0x199d4 (0xe9f91e, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe9f91e that no registered NAKA table points into
KeyShiftStr_Plus2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x199D0, 0x4
; [nakarest] KeyShiftStr_Plus1  +0x199d4..+0x199d8 (0xe9f922, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe9f922 that no registered NAKA table points into
KeyShiftStr_Plus1:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x199D4, 0x4
; [nakarest] KeyShiftStr_Zero  +0x199d8..+0x19a7a (0xe9f926, 162 B)
; [nakarest] purpose not established: 162 bytes at 0xe9f926 that no registered NAKA table points into
KeyShiftStr_Zero:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x199D8, 0xA2
; [nakarest] DemoDisk_LangPromptTable  +0x19a7a..+0x19a92 (0xe9f9c8, 24 B)
; [nakarest] purpose not established: 24 bytes at 0xe9f9c8 that no registered NAKA table points into
DemoDisk_LangPromptTable:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19A7A, 0x18
; [nakarest] DemoDiskPrompt_Indonesian  +0x19a92..+0x19b34 (0xe9f9e0, 162 B)
; [nakarest] purpose not established: 162 bytes at 0xe9f9e0 that no registered NAKA table points into
DemoDiskPrompt_Indonesian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19A92, 0xA2
; [nakarest] DemoDiskPrompt_Italian  +0x19b34..+0x19b3c (0xe9fa82, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9fa82 that no registered NAKA table points into
DemoDiskPrompt_Italian:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19B34, 0x8
; [nakarest] DemoDiskPrompt_English2  +0x19b3c..+0x19bc2 (0xe9fa8a, 134 B)
; [nakarest] purpose not established: 134 bytes at 0xe9fa8a that no registered NAKA table points into
DemoDiskPrompt_English2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19B3C, 0x86
; [nakarest] DemoDiskPrompt_English3  +0x19bc2..+0x19c48 (0xe9fb10, 134 B)
; [nakarest] purpose not established: 134 bytes at 0xe9fb10 that no registered NAKA table points into
DemoDiskPrompt_English3:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19BC2, 0x86
; [nakarest] DemoDiskPrompt_German  +0x19c48..+0x19cf0 (0xe9fb96, 168 B)
; [nakarest] purpose not established: 168 bytes at 0xe9fb96 that no registered NAKA table points into
DemoDiskPrompt_German:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19C48, 0xA8
; [nakarest] DemoDiskPrompt_English1  +0x19cf0..+0x19e8e (0xe9fc3e, 414 B)
; [nakarest] purpose not established: 414 bytes at 0xe9fc3e that no registered NAKA table points into
DemoDiskPrompt_English1:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19CF0, 0x19E
; [nakarest] ErrStr_GetInstanceID  +0x19e8e..+0x19ea6 (0xe9fddc, 24 B)
; [nakarest] purpose not established: 24 bytes at 0xe9fddc that no registered NAKA table points into
ErrStr_GetInstanceID:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19E8E, 0x18
; [nakarest] FileType_NameTable  +0x19ea6..+0x19eb6 (0xe9fdf4, 16 B)
; [nakarest] purpose not established: 16 bytes at 0xe9fdf4 that no registered NAKA table points into
FileType_NameTable:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19EA6, 0x10
; [nakarest] FileTypeName_Empty  +0x19eb6..+0x19eb8 (0xe9fe04, 2 B)
; [nakarest] purpose not established: 2 bytes at 0xe9fe04 that no registered NAKA table points into
FileTypeName_Empty:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19EB6, 0x2
; [nakarest] FileTypeName_Name  +0x19eb8..+0x19ebe (0xe9fe06, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9fe06 that no registered NAKA table points into
FileTypeName_Name:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19EB8, 0x6
; [nakarest] FileTypeName_Src  +0x19ebe..+0x19ec2 (0xe9fe0c, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe9fe0c that no registered NAKA table points into
FileTypeName_Src:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19EBE, 0x4
; [nakarest] FileTypeName_Song  +0x19ec2..+0x19f28 (0xe9fe10, 102 B)
; [nakarest] purpose not established: 102 bytes at 0xe9fe10 that no registered NAKA table points into
FileTypeName_Song:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19EC2, 0x66
; [nakarest] UIStr_Pan  +0x19f28..+0x19f2e (0xe9fe76, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9fe76 that no registered NAKA table points into
UIStr_Pan:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19F28, 0x6
; [nakarest] UIStr_No  +0x19f2e..+0x19f3e (0xe9fe7c, 16 B)
; [nakarest] purpose not established: 16 bytes at 0xe9fe7c that no registered NAKA table points into
UIStr_No:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19F2E, 0x10
; [nakarest] ImgAttr_Empty  +0x19f3e..+0x19f40 (0xe9fe8c, 2 B)
; [nakarest] purpose not established: 2 bytes at 0xe9fe8c that no registered NAKA table points into
ImgAttr_Empty:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19F3E, 0x2
; [nakarest] ImgAttr_Color  +0x19f40..+0x19f46 (0xe9fe8e, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9fe8e that no registered NAKA table points into
ImgAttr_Color:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19F40, 0x6
; [nakarest] ImgAttr_Size  +0x19f46..+0x19f74 (0xe9fe94, 46 B)
; [nakarest] purpose not established: 46 bytes at 0xe9fe94 that no registered NAKA table points into
ImgAttr_Size:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19F46, 0x2E
; [nakarest] ImgAttr_NameTable  +0x19f74..+0x19f9c (0xe9fec2, 40 B)
; [nakarest] purpose not established: 40 bytes at 0xe9fec2 that no registered NAKA table points into
ImgAttr_NameTable:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19F74, 0x28
; [nakarest] ImgAttrName_Empty  +0x19f9c..+0x19f9e (0xe9feea, 2 B)
; [nakarest] purpose not established: 2 bytes at 0xe9feea that no registered NAKA table points into
ImgAttrName_Empty:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19F9C, 0x2
; [nakarest] ImgAttrName_Border  +0x19f9e..+0x19fa6 (0xe9feec, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9feec that no registered NAKA table points into
ImgAttrName_Border:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19F9E, 0x8
; [nakarest] ImgAttrName_Lowsrc  +0x19fa6..+0x19fae (0xe9fef4, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9fef4 that no registered NAKA table points into
ImgAttrName_Lowsrc:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19FA6, 0x8
; [nakarest] ImgAttrName_Height  +0x19fae..+0x19fb6 (0xe9fefc, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9fefc that no registered NAKA table points into
ImgAttrName_Height:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19FAE, 0x8
; [nakarest] ImgAttrName_Width  +0x19fb6..+0x19fbc (0xe9ff04, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9ff04 that no registered NAKA table points into
ImgAttrName_Width:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19FB6, 0x6
; [nakarest] ImgAttrName_Hspace  +0x19fbc..+0x19fc4 (0xe9ff0a, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9ff0a that no registered NAKA table points into
ImgAttrName_Hspace:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19FBC, 0x8
; [nakarest] ImgAttrName_Vspace  +0x19fc4..+0x19fcc (0xe9ff12, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xe9ff12 that no registered NAKA table points into
ImgAttrName_Vspace:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19FC4, 0x8
; [nakarest] ImgAttrName_Align  +0x19fcc..+0x19fd2 (0xe9ff1a, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xe9ff1a that no registered NAKA table points into
ImgAttrName_Align:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19FCC, 0x6
; [nakarest] ImgAttrName_Alt  +0x19fd2..+0x19fd6 (0xe9ff20, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xe9ff20 that no registered NAKA table points into
ImgAttrName_Alt:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19FD2, 0x4
; [nakarest] ImgAttrName_Src  +0x19fd6..+0x1a066 (0xe9ff24, 144 B)
; [nakarest] purpose not established: 144 bytes at 0xe9ff24 that no registered NAKA table points into
ImgAttrName_Src:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x19FD6, 0x90
; [nakarest] ObjAttr_Empty  +0x1a066..+0x1a068 (0xe9ffb4, 2 B)
; [nakarest] purpose not established: 2 bytes at 0xe9ffb4 that no registered NAKA table points into
ObjAttr_Empty:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A066, 0x2
; [nakarest] ObjAttr_Obj  +0x1a068..+0x1a0b2 (0xe9ffb6, 74 B)
; [nakarest] purpose not established: 74 bytes at 0xe9ffb6 that no registered NAKA table points into
ObjAttr_Obj:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A068, 0x4A
; [nakarest] Presentation_RootEntry  +0x1a0b2..+0x1a0ba (0xea0000, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xea0000 that no registered NAKA table points into
Presentation_RootEntry:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A0B2, 0x8
; [nakarest] Presentation_TagStrTable  +0x1a0ba..+0x1a1f1 (0xea0008, 311 B)
; [nakarest] purpose not established: 311 bytes at 0xea0008 that no registered NAKA table points into
Presentation_TagStrTable:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A0BA, 0x137
; [nakarest] Presentation_TagTableEnd  +0x1a1f1..+0x1a2aa (0xea013f, 185 B)
; [nakarest] purpose not established: 185 bytes at 0xea013f that no registered NAKA table points into
Presentation_TagTableEnd:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A1F1, 0xB9
; [nakarest] Resource_Region7_Start  +0x1a2aa..+0x1a2ae (0xea01f8, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xea01f8 that no registered NAKA table points into
Resource_Region7_Start:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A2AA, 0x4
; [nakarest] Resource_Region2_Start  +0x1a2ae..+0x1a2b2 (0xea01fc, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xea01fc that no registered NAKA table points into
Resource_Region2_Start:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A2AE, 0x4
; [nakarest] Resource_Region3_Start  +0x1a2b2..+0x1a2fe (0xea0200, 76 B)
; [nakarest] purpose not established: 76 bytes at 0xea0200 that no registered NAKA table points into
Resource_Region3_Start:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A2B2, 0x4C
; [nakarest] Resource_RegionPad  +0x1a2fe..+0x1a3f2 (0xea024c, 244 B)
; [nakarest] purpose not established: 244 bytes at 0xea024c that no registered NAKA table points into
Resource_RegionPad:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A2FE, 0xF4
; [nakarest] SeqFileType_CodeTable  +0x1a3f2..+0x1a41a (0xea0340, 40 B)
; [nakarest] purpose not established: 40 bytes at 0xea0340 that no registered NAKA table points into
SeqFileType_CodeTable:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A3F2, 0x28
; [nakarest] SeqFileTypeCode_Seq  +0x1a41a..+0x1a41e (0xea0368, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xea0368 that no registered NAKA table points into
SeqFileTypeCode_Seq:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A41A, 0x4
; [nakarest] SeqFileTypeCode_Sqf  +0x1a41e..+0x1a422 (0xea036c, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xea036c that no registered NAKA table points into
SeqFileTypeCode_Sqf:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A41E, 0x4
; [nakarest] SeqFileTypeCode_Md  +0x1a422..+0x1a426 (0xea0370, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xea0370 that no registered NAKA table points into
SeqFileTypeCode_Md:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A422, 0x4
; [nakarest] SeqFileTypeCode_Rcm  +0x1a426..+0x1a42a (0xea0374, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xea0374 that no registered NAKA table points into
SeqFileTypeCode_Rcm:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A426, 0x4
; [nakarest] SeqFileTypeCode_Msp  +0x1a42a..+0x1a42e (0xea0378, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xea0378 that no registered NAKA table points into
SeqFileTypeCode_Msp:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A42A, 0x4
; [nakarest] SeqFileTypeCode_Tm  +0x1a42e..+0x1a432 (0xea037c, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xea037c that no registered NAKA table points into
SeqFileTypeCode_Tm:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A42E, 0x4
; [nakarest] SeqFileTypeCode_Cmp  +0x1a432..+0x1a436 (0xea0380, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xea0380 that no registered NAKA table points into
SeqFileTypeCode_Cmp:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A432, 0x4
; [nakarest] SeqFileTypeCode_Sqt  +0x1a436..+0x1a43a (0xea0384, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xea0384 that no registered NAKA table points into
SeqFileTypeCode_Sqt:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A436, 0x4
; [nakarest] SeqFileTypeCode_Pmt  +0x1a43a..+0x1a43e (0xea0388, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xea0388 that no registered NAKA table points into
SeqFileTypeCode_Pmt:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A43A, 0x4
; [nakarest] SeqFileTypeCode_Lsw  +0x1a43e..+0x1a4fa (0xea038c, 188 B)
; [nakarest] purpose not established: 188 bytes at 0xea038c that no registered NAKA table points into
SeqFileTypeCode_Lsw:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A43E, 0xBC
; [nakarest] Filename_TemplateArea  +0x1a4fa..+0x1a574 (0xea0448, 122 B)
; [nakarest] purpose not established: 122 bytes at 0xea0448 that no registered NAKA table points into
Filename_TemplateArea:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A4FA, 0x7A
; [nakarest] FileOp_StubAndDirNames  +0x1a574..+0x1a60a (0xea04c2, 150 B)
; [nakarest] purpose not established: 150 bytes at 0xea04c2 that no registered NAKA table points into
FileOp_StubAndDirNames:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A574, 0x96
; [nakarest] DiskType_CodeTable  +0x1a60a..+0x1a62a (0xea0558, 32 B)
; [nakarest] purpose not established: 32 bytes at 0xea0558 that no registered NAKA table points into
DiskType_CodeTable:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A60A, 0x20
; [nakarest] DiskTypeCode_Doc1  +0x1a62a..+0x1a62e (0xea0578, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xea0578 that no registered NAKA table points into
DiskTypeCode_Doc1:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A62A, 0x4
; [nakarest] DiskTypeCode_Doc2  +0x1a62e..+0x1a632 (0xea057c, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xea057c that no registered NAKA table points into
DiskTypeCode_Doc2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A62E, 0x4
; [nakarest] DiskTypeCode_Pd  +0x1a632..+0x1a636 (0xea0580, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xea0580 that no registered NAKA table points into
DiskTypeCode_Pd:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A632, 0x4
; [nakarest] DiskTypeCode_2DD1  +0x1a636..+0x1a63a (0xea0584, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xea0584 that no registered NAKA table points into
DiskTypeCode_2DD1:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A636, 0x4
; [nakarest] DiskTypeCode_2HD  +0x1a63a..+0x1a63e (0xea0588, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xea0588 that no registered NAKA table points into
DiskTypeCode_2HD:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A63A, 0x4
; [nakarest] DiskTypeCode_2DD2  +0x1a63e..+0x1a642 (0xea058c, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xea058c that no registered NAKA table points into
DiskTypeCode_2DD2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A63E, 0x4
; [nakarest] DiskTypeCode_Dashes1  +0x1a642..+0x1a646 (0xea0590, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xea0590 that no registered NAKA table points into
DiskTypeCode_Dashes1:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A642, 0x4
; [nakarest] DiskTypeCode_Dashes2  +0x1a646..+0x1a64a (0xea0594, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xea0594 that no registered NAKA table points into
DiskTypeCode_Dashes2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A646, 0x4
; [nakarest] StorageArea_NameTable  +0x1a64a..+0x1a65e (0xea0598, 20 B)
; [nakarest] purpose not established: 20 bytes at 0xea0598 that no registered NAKA table points into
StorageArea_NameTable:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A64A, 0x14
; [nakarest] StorageAreaName_Blank  +0x1a65e..+0x1a66c (0xea05ac, 14 B)
; [nakarest] purpose not established: 14 bytes at 0xea05ac that no registered NAKA table points into
StorageAreaName_Blank:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A65E, 0xE
; [nakarest] StorageAreaName_SoundMemory  +0x1a66c..+0x1a67a (0xea05ba, 14 B)
; [nakarest] purpose not established: 14 bytes at 0xea05ba that no registered NAKA table points into
StorageAreaName_SoundMemory:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A66C, 0xE
; [nakarest] StorageAreaName_Composer  +0x1a67a..+0x1a688 (0xea05c8, 14 B)
; [nakarest] purpose not established: 14 bytes at 0xea05c8 that no registered NAKA table points into
StorageAreaName_Composer:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A67A, 0xE
; [nakarest] StorageAreaName_Sequencer  +0x1a688..+0x1a696 (0xea05d6, 14 B)
; [nakarest] purpose not established: 14 bytes at 0xea05d6 that no registered NAKA table points into
StorageAreaName_Sequencer:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A688, 0xE
; [nakarest] StorageAreaName_PanelMemory  +0x1a696..+0x1a6b8 (0xea05e4, 34 B)
; [nakarest] purpose not established: 34 bytes at 0xea05e4 that no registered NAKA table points into
StorageAreaName_PanelMemory:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A696, 0x22
; [nakarest] BankStr_Dashes  +0x1a6b8..+0x1a6be (0xea0606, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xea0606 that no registered NAKA table points into
BankStr_Dashes:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A6B8, 0x6
; [nakarest] BankStr_Bank1  +0x1a6be..+0x1a6c4 (0xea060c, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xea060c that no registered NAKA table points into
BankStr_Bank1:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A6BE, 0x6
; [nakarest] BankStr_Bank2  +0x1a6c4..+0x1a6ca (0xea0612, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xea0612 that no registered NAKA table points into
BankStr_Bank2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A6C4, 0x6
; [nakarest] BankStr_Dashes2  +0x1a6ca..+0x1a6d0 (0xea0618, 6 B)
; [nakarest] purpose not established: 6 bytes at 0xea0618 that no registered NAKA table points into
BankStr_Dashes2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A6CA, 0x6
; [nakarest] BankStr_Bank3  +0x1a6d0..+0x1a6da (0xea061e, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xea061e that no registered NAKA table points into
BankStr_Bank3:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A6D0, 0xA
; [nakarest] DiskItem_TypeTable  +0x1a6da..+0x1a6ea (0xea0628, 16 B)
; [nakarest] purpose not established: 16 bytes at 0xea0628 that no registered NAKA table points into
DiskItem_TypeTable:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A6DA, 0x10
; [nakarest] DiskItemType_Dashes  +0x1a6ea..+0x1a6f4 (0xea0638, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xea0638 that no registered NAKA table points into
DiskItemType_Dashes:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A6EA, 0xA
; [nakarest] DiskItemType_Memory  +0x1a6f4..+0x1a6fe (0xea0642, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xea0642 that no registered NAKA table points into
DiskItemType_Memory:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A6F4, 0xA
; [nakarest] DiskItemType_Pattern  +0x1a6fe..+0x1a708 (0xea064c, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xea064c that no registered NAKA table points into
DiskItemType_Pattern:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A6FE, 0xA
; [nakarest] DiskItemType_Song  +0x1a708..+0x1a712 (0xea0656, 10 B)
; [nakarest] purpose not established: 10 bytes at 0xea0656 that no registered NAKA table points into
DiskItemType_Song:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A708, 0xA
; [nakarest] BankStr_Memory  +0x1a712..+0x1a71e (0xea0660, 12 B)
; [nakarest] purpose not established: 12 bytes at 0xea0660 that no registered NAKA table points into
BankStr_Memory:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A712, 0xC
; [nakarest] DiskOp_ChannelCfgTable  +0x1a71e..+0x1a812 (0xea066c, 244 B)
; [nakarest] purpose not established: 244 bytes at 0xea066c that no registered NAKA table points into
DiskOp_ChannelCfgTable:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A71E, 0xF4
; [nakarest] Str_SmfConvert_GmToTech  +0x1a812..+0x1a822 (0xea0760, 16 B)
; [nakarest] purpose not established: 16 bytes at 0xea0760 that no registered NAKA table points into
Str_SmfConvert_GmToTech:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A812, 0x10
; [nakarest] Str_SmfConvert_TechToTech  +0x1a822..+0x1a832 (0xea0770, 16 B)
; [nakarest] purpose not established: 16 bytes at 0xea0770 that no registered NAKA table points into
Str_SmfConvert_TechToTech:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A822, 0x10
; [nakarest] Str_SmfConvert_GmToGm  +0x1a832..+0x1a86c (0xea0780, 58 B)
; [nakarest] purpose not established: 58 bytes at 0xea0780 that no registered NAKA table points into
Str_SmfConvert_GmToGm:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A832, 0x3A
; [nakarest] Str_MemorySlot_C  +0x1a86c..+0x1a87c (0xea07ba, 16 B)
; [nakarest] purpose not established: 16 bytes at 0xea07ba that no registered NAKA table points into
Str_MemorySlot_C:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A86C, 0x10
; [nakarest] Str_MemorySlot_B  +0x1a87c..+0x1a88c (0xea07ca, 16 B)
; [nakarest] purpose not established: 16 bytes at 0xea07ca that no registered NAKA table points into
Str_MemorySlot_B:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A87C, 0x10
; [nakarest] Str_MemorySlot_A  +0x1a88c..+0x1a89c (0xea07da, 16 B)
; [nakarest] purpose not established: 16 bytes at 0xea07da that no registered NAKA table points into
Str_MemorySlot_A:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A88C, 0x10
; [nakarest] PtrTbl_VariationNames  +0x1a89c..+0x1a8c6 (0xea07ea, 42 B)
; [nakarest] purpose not established: 42 bytes at 0xea07ea that no registered NAKA table points into
PtrTbl_VariationNames:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A89C, 0x2A
; [nakarest] Data_VariPad_EA0814  +0x1a8c6..+0x1a8c8 (0xea0814, 2 B)
; [nakarest] purpose not established: 2 bytes at 0xea0814 that no registered NAKA table points into
Data_VariPad_EA0814:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A8C6, 0x2
; [nakarest] Data_VariPad_EA0816  +0x1a8c8..+0x1a8ca (0xea0816, 2 B)
; [nakarest] purpose not established: 2 bytes at 0xea0816 that no registered NAKA table points into
Data_VariPad_EA0816:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A8C8, 0x2
; [nakarest] Data_VariPad_EA0818  +0x1a8ca..+0x1a8ce (0xea0818, 4 B)
; [nakarest] purpose not established: 4 bytes at 0xea0818 that no registered NAKA table points into
Data_VariPad_EA0818:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A8CA, 0x4
; [nakarest] Data_VariPad_EA081C  +0x1a8ce..+0x1a8d0 (0xea081c, 2 B)
; [nakarest] purpose not established: 2 bytes at 0xea081c that no registered NAKA table points into
Data_VariPad_EA081C:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A8CE, 0x2
; [nakarest] Str_Variation4  +0x1a8d0..+0x1a8d8 (0xea081e, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xea081e that no registered NAKA table points into
Str_Variation4:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A8D0, 0x8
; [nakarest] Str_Variation3  +0x1a8d8..+0x1a8e0 (0xea0826, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xea0826 that no registered NAKA table points into
Str_Variation3:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A8D8, 0x8
; [nakarest] Str_Variation2  +0x1a8e0..+0x1a8e8 (0xea082e, 8 B)
; [nakarest] purpose not established: 8 bytes at 0xea082e that no registered NAKA table points into
Str_Variation2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A8E0, 0x8
; [nakarest] Str_Variation1  +0x1a8e8..+0x1a900 (0xea0836, 24 B)
; [nakarest] purpose not established: 24 bytes at 0xea0836 that no registered NAKA table points into
Str_Variation1:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A8E8, 0x18
; [nakarest] PtrTbl_RhythmSectionNames  +0x1a900..+0x1a918 (0xea084e, 24 B)
; [nakarest] purpose not established: 24 bytes at 0xea084e that no registered NAKA table points into
PtrTbl_RhythmSectionNames:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A900, 0x18
; [nakarest] Str_Ending2  +0x1a918..+0x1a92a (0xea0866, 18 B)
; [nakarest] purpose not established: 18 bytes at 0xea0866 that no registered NAKA table points into
Str_Ending2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A918, 0x12
; [nakarest] Str_Ending1  +0x1a92a..+0x1a93c (0xea0878, 18 B)
; [nakarest] purpose not established: 18 bytes at 0xea0878 that no registered NAKA table points into
Str_Ending1:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A92A, 0x12
; [nakarest] Str_FillIn2  +0x1a93c..+0x1a94e (0xea088a, 18 B)
; [nakarest] purpose not established: 18 bytes at 0xea088a that no registered NAKA table points into
Str_FillIn2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A93C, 0x12
; [nakarest] Str_FillIn1  +0x1a94e..+0x1a960 (0xea089c, 18 B)
; [nakarest] purpose not established: 18 bytes at 0xea089c that no registered NAKA table points into
Str_FillIn1:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A94E, 0x12
; [nakarest] Str_Intro2  +0x1a960..+0x1a972 (0xea08ae, 18 B)
; [nakarest] purpose not established: 18 bytes at 0xea08ae that no registered NAKA table points into
Str_Intro2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A960, 0x12
; [nakarest] Str_Intro1  +0x1a972..+0x1a986 (0xea08c0, 20 B)
; [nakarest] purpose not established: 20 bytes at 0xea08c0 that no registered NAKA table points into
Str_Intro1:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A972, 0x14
; [nakarest] Data_DrumKitPad_EA08D4  +0x1a986..+0x1a988 (0xea08d4, 2 B)
; [nakarest] purpose not established: 2 bytes at 0xea08d4 that no registered NAKA table points into
Data_DrumKitPad_EA08D4:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A986, 0x2
; [nakarest] Data_DrumKitPad_EA08D6  +0x1a988..+0x1a98a (0xea08d6, 2 B)
; [nakarest] purpose not established: 2 bytes at 0xea08d6 that no registered NAKA table points into
Data_DrumKitPad_EA08D6:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A988, 0x2
; [nakarest] PtrTbl_DrumKitNames  +0x1a98a..+0x1aa32 (0xea08d8, 168 B)
; [nakarest] purpose not established: 168 bytes at 0xea08d8 that no registered NAKA table points into
PtrTbl_DrumKitNames:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1A98A, 0xA8
; [nakarest] Str_AllOption_EA0980  +0x1aa32..+0x1aa64 (0xea0980, 50 B)
; [nakarest] purpose not established: 50 bytes at 0xea0980 that no registered NAKA table points into
Str_AllOption_EA0980:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AA32, 0x32
; [nakarest] Str_AllOption_EA09B2  +0x1aa64..+0x1aaa2 (0xea09b2, 62 B)
; [nakarest] purpose not established: 62 bytes at 0xea09b2 that no registered NAKA table points into
Str_AllOption_EA09B2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AA64, 0x3E
; [nakarest] Data_SaveLoadMenuTable  +0x1aaa2..+0x1ab00 (0xea09f0, 94 B)
; [nakarest] purpose not established: 94 bytes at 0xea09f0 that no registered NAKA table points into
Data_SaveLoadMenuTable:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AAA2, 0x5E
EmbeddedPtrTable_v7_naka_technichord_strings_01AB00:
	.long 0x00F90956
	.long 0xFF00FF00
	.long InsertOptionText
	.long TypePriorityText
	.long JumpInsertFunc
	.long FilePriorityFunc
	.long SetupOkFunc
	.long SetupExitFunc
	.long TechnicsFileNaming
	.long TechnicsFileRename
	.long SmfFileRename
	.long SmfFileNaming
	.long FormatDiskNaming
	.long WaitingFunc
	.long DiskMedleyShowHideFunc
	.long DiskAttention
	.long DiskSure
	.long FormatText
	.long DeleteText
	.long SaveText
	.long DeleteYes
	.long DeleteNo
	.long SaveYes
	.long SaveNo
	.long WakeUpPassword
	.long PasswordOk
	.long PasswordNo
	.long PasswordText
	.long CheckPasswordText
	.long CheckPasswordOk
	.long CheckPasswordNo
	.long 0x00000000
PtrTbl_DiskFuncNames:
	.long Str_InsertOptionText
	.long Str_TypePriorityText
	.long Str_JumpInsertFunc
	.long Str_FilePriorityFunc
	.long Str_SetupOkFunc
	.long Str_SetupExitFunc
	.long Str_TechnicsFileNaming
	.long Str_TechnicsFileRename
	.long Str_SmfFileRename
	.long Str_SmfFileNaming
	.long Str_FormatDiskNaming
	.long Str_WaitingFunc
	.long Str_DiskMedleyShowHideFunc
	.long Str_DiskAttention
	.long Str_DiskSure
	.long Str_FormatText
	.long Str_DeleteText
Data_DiskFuncPtrTbl_EA0B12:
	.long Str_SaveText
	.long Str_DeleteYes
	.long Str_DeleteNo
	.long Str_SaveYes
	.long Str_SaveNo
	.long Str_WakeUpPassword
	.long Str_PasswordOk
	.long Str_PasswordNo
	.long Str_PasswordText
	.long Str_CheckPasswordText
	.long Str_CheckPasswordOk
	.long Str_CheckPasswordNo
	.long Data_PasswordSep_EA0B46
Data_PasswordSep_EA0B46:
	.long 0x6843FF00
	.long 0x506B6365
; [nakarest] naka_technichord_strings+0x1ac00  +0x1ac00..+0x1ac0a (0xea0b4e, 10 B)
; [nakarest] Continues name string, entry 28 of ApFunction slot 0x425 (table 0xea0ace, 29
; [nakarest] entries, InitializeCheap) (names for ApFunction slot 0x125): "CheckPasswordNo"
; [nakarest] (starts 0xea0b48, 10 of its 16 bytes are here or later).
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AC00, 0xA
; [nakarest] Str_CheckPasswordOk  +0x1ac0a..+0x1ac1a (0xea0b58, 16 B)
; [nakarest] name string, entry 27 of ApFunction slot 0x425 (table 0xea0ace, 29 entries,
; [nakarest] InitializeCheap) (names for ApFunction slot 0x125): "CheckPasswordOk".
Str_CheckPasswordOk:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AC0A, 0x10
; [nakarest] Str_CheckPasswordText  +0x1ac1a..+0x1ac2c (0xea0b68, 18 B)
; [nakarest] name string, entry 26 of ApFunction slot 0x425 (table 0xea0ace, 29 entries,
; [nakarest] InitializeCheap) (names for ApFunction slot 0x125): "CheckPasswordText".
Str_CheckPasswordText:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AC1A, 0x12
; [nakarest] Str_PasswordText  +0x1ac2c..+0x1ac3a (0xea0b7a, 14 B)
; [nakarest] name string, entry 25 of ApFunction slot 0x425 (table 0xea0ace, 29 entries,
; [nakarest] InitializeCheap) (names for ApFunction slot 0x125): "PasswordText".
Str_PasswordText:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AC2C, 0xE
; [nakarest] Str_PasswordNo  +0x1ac3a..+0x1ac46 (0xea0b88, 12 B)
; [nakarest] name string, entry 24 of ApFunction slot 0x425 (table 0xea0ace, 29 entries,
; [nakarest] InitializeCheap) (names for ApFunction slot 0x125): "PasswordNo".
Str_PasswordNo:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AC3A, 0xC
; [nakarest] Str_PasswordOk  +0x1ac46..+0x1ac52 (0xea0b94, 12 B)
; [nakarest] name string, entry 23 of ApFunction slot 0x425 (table 0xea0ace, 29 entries,
; [nakarest] InitializeCheap) (names for ApFunction slot 0x125): "PasswordOk".
Str_PasswordOk:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AC46, 0xC
; [nakarest] Str_WakeUpPassword  +0x1ac52..+0x1ac62 (0xea0ba0, 16 B)
; [nakarest] name string, entry 22 of ApFunction slot 0x425 (table 0xea0ace, 29 entries,
; [nakarest] InitializeCheap) (names for ApFunction slot 0x125): "WakeUpPassword".
Str_WakeUpPassword:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AC52, 0x10
; [nakarest] Str_SaveNo  +0x1ac62..+0x1ac6a (0xea0bb0, 8 B)
; [nakarest] name string, entry 21 of ApFunction slot 0x425 (table 0xea0ace, 29 entries,
; [nakarest] InitializeCheap) (names for ApFunction slot 0x125): "SaveNo".
Str_SaveNo:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AC62, 0x8
; [nakarest] Str_SaveYes  +0x1ac6a..+0x1ac72 (0xea0bb8, 8 B)
; [nakarest] name string, entry 20 of ApFunction slot 0x425 (table 0xea0ace, 29 entries,
; [nakarest] InitializeCheap) (names for ApFunction slot 0x125): "SaveYes".
Str_SaveYes:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AC6A, 0x8
; [nakarest] Str_DeleteNo  +0x1ac72..+0x1ac7c (0xea0bc0, 10 B)
; [nakarest] name string, entry 19 of ApFunction slot 0x425 (table 0xea0ace, 29 entries,
; [nakarest] InitializeCheap) (names for ApFunction slot 0x125): "DeleteNo".
Str_DeleteNo:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AC72, 0xA
; [nakarest] Str_DeleteYes  +0x1ac7c..+0x1ac86 (0xea0bca, 10 B)
; [nakarest] name string, entry 18 of ApFunction slot 0x425 (table 0xea0ace, 29 entries,
; [nakarest] InitializeCheap) (names for ApFunction slot 0x125): "DeleteYes".
Str_DeleteYes:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AC7C, 0xA
; [nakarest] Str_SaveText  +0x1ac86..+0x1ac90 (0xea0bd4, 10 B)
; [nakarest] name string, entry 17 of ApFunction slot 0x425 (table 0xea0ace, 29 entries,
; [nakarest] InitializeCheap) (names for ApFunction slot 0x125): "SaveText".
Str_SaveText:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AC86, 0xA
; [nakarest] Str_DeleteText  +0x1ac90..+0x1ac9c (0xea0bde, 12 B)
; [nakarest] name string, entry 16 of ApFunction slot 0x425 (table 0xea0ace, 29 entries,
; [nakarest] InitializeCheap) (names for ApFunction slot 0x125): "DeleteText".
Str_DeleteText:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AC90, 0xC
; [nakarest] Str_FormatText  +0x1ac9c..+0x1aca8 (0xea0bea, 12 B)
; [nakarest] name string, entry 15 of ApFunction slot 0x425 (table 0xea0ace, 29 entries,
; [nakarest] InitializeCheap) (names for ApFunction slot 0x125): "FormatText".
Str_FormatText:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AC9C, 0xC
; [nakarest] Str_DiskSure  +0x1aca8..+0x1acb2 (0xea0bf6, 10 B)
; [nakarest] name string, entry 14 of ApFunction slot 0x425 (table 0xea0ace, 29 entries,
; [nakarest] InitializeCheap) (names for ApFunction slot 0x125): "DiskSure".
Str_DiskSure:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1ACA8, 0xA
; [nakarest] Str_DiskAttention  +0x1acb2..+0x1acc0 (0xea0c00, 14 B)
; [nakarest] name string, entry 13 of ApFunction slot 0x425 (table 0xea0ace, 29 entries,
; [nakarest] InitializeCheap) (names for ApFunction slot 0x125): "DiskAttention".
Str_DiskAttention:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1ACB2, 0xE
; [nakarest] Str_DiskMedleyShowHideFunc  +0x1acc0..+0x1acd8 (0xea0c0e, 24 B)
; [nakarest] name string, entry 12 of ApFunction slot 0x425 (table 0xea0ace, 29 entries,
; [nakarest] InitializeCheap) (names for ApFunction slot 0x125): "DiskMedleyShowHideFunc".
Str_DiskMedleyShowHideFunc:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1ACC0, 0x18
; [nakarest] Str_WaitingFunc  +0x1acd8..+0x1ace4 (0xea0c26, 12 B)
; [nakarest] name string, entry 11 of ApFunction slot 0x425 (table 0xea0ace, 29 entries,
; [nakarest] InitializeCheap) (names for ApFunction slot 0x125): "WaitingFunc".
Str_WaitingFunc:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1ACD8, 0xC
; [nakarest] Str_FormatDiskNaming  +0x1ace4..+0x1acf6 (0xea0c32, 18 B)
; [nakarest] name string, entry 10 of ApFunction slot 0x425 (table 0xea0ace, 29 entries,
; [nakarest] InitializeCheap) (names for ApFunction slot 0x125): "FormatDiskNaming".
Str_FormatDiskNaming:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1ACE4, 0x12
; [nakarest] Str_SmfFileNaming  +0x1acf6..+0x1ad04 (0xea0c44, 14 B)
; [nakarest] name string, entry 9 of ApFunction slot 0x425 (table 0xea0ace, 29 entries,
; [nakarest] InitializeCheap) (names for ApFunction slot 0x125): "SmfFileNaming".
Str_SmfFileNaming:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1ACF6, 0xE
; [nakarest] Str_SmfFileRename  +0x1ad04..+0x1ad12 (0xea0c52, 14 B)
; [nakarest] name string, entry 8 of ApFunction slot 0x425 (table 0xea0ace, 29 entries,
; [nakarest] InitializeCheap) (names for ApFunction slot 0x125): "SmfFileRename".
Str_SmfFileRename:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AD04, 0xE
; [nakarest] Str_TechnicsFileRename  +0x1ad12..+0x1ad26 (0xea0c60, 20 B)
; [nakarest] name string, entry 7 of ApFunction slot 0x425 (table 0xea0ace, 29 entries,
; [nakarest] InitializeCheap) (names for ApFunction slot 0x125): "TechnicsFileRename".
Str_TechnicsFileRename:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AD12, 0x14
; [nakarest] Str_TechnicsFileNaming  +0x1ad26..+0x1ad3a (0xea0c74, 20 B)
; [nakarest] name string, entry 6 of ApFunction slot 0x425 (table 0xea0ace, 29 entries,
; [nakarest] InitializeCheap) (names for ApFunction slot 0x125): "TechnicsFileNaming".
Str_TechnicsFileNaming:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AD26, 0x14
; [nakarest] Str_SetupExitFunc  +0x1ad3a..+0x1ad48 (0xea0c88, 14 B)
; [nakarest] name string, entry 5 of ApFunction slot 0x425 (table 0xea0ace, 29 entries,
; [nakarest] InitializeCheap) (names for ApFunction slot 0x125): "SetupExitFunc".
Str_SetupExitFunc:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AD3A, 0xE
; [nakarest] Str_SetupOkFunc  +0x1ad48..+0x1ad54 (0xea0c96, 12 B)
; [nakarest] name string, entry 4 of ApFunction slot 0x425 (table 0xea0ace, 29 entries,
; [nakarest] InitializeCheap) (names for ApFunction slot 0x125): "SetupOkFunc".
Str_SetupOkFunc:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AD48, 0xC
; [nakarest] Str_FilePriorityFunc  +0x1ad54..+0x1ad66 (0xea0ca2, 18 B)
; [nakarest] name string, entry 3 of ApFunction slot 0x425 (table 0xea0ace, 29 entries,
; [nakarest] InitializeCheap) (names for ApFunction slot 0x125): "FilePriorityFunc".
Str_FilePriorityFunc:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AD54, 0x12
; [nakarest] Str_JumpInsertFunc  +0x1ad66..+0x1ad76 (0xea0cb4, 16 B)
; [nakarest] name string, entry 2 of ApFunction slot 0x425 (table 0xea0ace, 29 entries,
; [nakarest] InitializeCheap) (names for ApFunction slot 0x125): "JumpInsertFunc".
Str_JumpInsertFunc:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AD66, 0x10
; [nakarest] Str_TypePriorityText  +0x1ad76..+0x1ad88 (0xea0cc4, 18 B)
; [nakarest] name string, entry 1 of ApFunction slot 0x425 (table 0xea0ace, 29 entries,
; [nakarest] InitializeCheap) (names for ApFunction slot 0x125): "TypePriorityText".
Str_TypePriorityText:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AD76, 0x12
; [nakarest] Str_InsertOptionText  +0x1ad88..+0x1ad9a (0xea0cd6, 18 B)
; [nakarest] name string, entry 0 of ApFunction slot 0x425 (table 0xea0ace, 29 entries,
; [nakarest] InitializeCheap) (names for ApFunction slot 0x125): "InsertOptionText".
Str_InsertOptionText:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AD88, 0x12
; [nakarest] PtrTbl_UiWidgetProps_EA0CE8  +0x1ad9a..+0x1adc6 (0xea0ce8, 44 B)
; [nakarest] propname block (the +20 field-name table) of class 0 of Class slot 0x165 (table
; [nakarest] 0xea0f46, 13 entries, InitializeCheap): PsFileNameBox {font, fontcolor, main_func,
; [nakarest] column, row, sel_num, dial, auto_inc, paintok, aicok}.
PtrTbl_UiWidgetProps_EA0CE8:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AD9A, 0x2C
; [nakarest] Str_UiProp_Empty_EA0D14  +0x1adc6..+0x1adc8 (0xea0d14, 2 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 0 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): PsFileNameBox {font, fontcolor,
; [nakarest] main_func, column, row, sel_num, dial, auto_inc, paintok, aicok} (starts 0xea0ce8,
; [nakarest] 78 of its 122 bytes are here or later).
Str_UiProp_Empty_EA0D14:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1ADC6, 0x2
; [nakarest] Str_UiProp_Aicok  +0x1adc8..+0x1adce (0xea0d16, 6 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 0 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): PsFileNameBox {font, fontcolor,
; [nakarest] main_func, column, row, sel_num, dial, auto_inc, paintok, aicok} (starts 0xea0ce8,
; [nakarest] 76 of its 122 bytes are here or later).
Str_UiProp_Aicok:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1ADC8, 0x6
; [nakarest] Str_UiProp_Paintok  +0x1adce..+0x1add6 (0xea0d1c, 8 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 0 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): PsFileNameBox {font, fontcolor,
; [nakarest] main_func, column, row, sel_num, dial, auto_inc, paintok, aicok} (starts 0xea0ce8,
; [nakarest] 70 of its 122 bytes are here or later).
Str_UiProp_Paintok:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1ADCE, 0x8
; [nakarest] Str_UiProp_AutoInc  +0x1add6..+0x1ade0 (0xea0d24, 10 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 0 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): PsFileNameBox {font, fontcolor,
; [nakarest] main_func, column, row, sel_num, dial, auto_inc, paintok, aicok} (starts 0xea0ce8,
; [nakarest] 62 of its 122 bytes are here or later).
Str_UiProp_AutoInc:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1ADD6, 0xA
; [nakarest] Str_UiProp_Dial  +0x1ade0..+0x1ade6 (0xea0d2e, 6 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 0 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): PsFileNameBox {font, fontcolor,
; [nakarest] main_func, column, row, sel_num, dial, auto_inc, paintok, aicok} (starts 0xea0ce8,
; [nakarest] 52 of its 122 bytes are here or later).
Str_UiProp_Dial:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1ADE0, 0x6
; [nakarest] Str_UiProp_SelNum  +0x1ade6..+0x1adee (0xea0d34, 8 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 0 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): PsFileNameBox {font, fontcolor,
; [nakarest] main_func, column, row, sel_num, dial, auto_inc, paintok, aicok} (starts 0xea0ce8,
; [nakarest] 46 of its 122 bytes are here or later).
Str_UiProp_SelNum:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1ADE6, 0x8
; [nakarest] Str_UiProp_Row  +0x1adee..+0x1adf2 (0xea0d3c, 4 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 0 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): PsFileNameBox {font, fontcolor,
; [nakarest] main_func, column, row, sel_num, dial, auto_inc, paintok, aicok} (starts 0xea0ce8,
; [nakarest] 38 of its 122 bytes are here or later).
Str_UiProp_Row:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1ADEE, 0x4
; [nakarest] Str_UiProp_Column  +0x1adf2..+0x1adfa (0xea0d40, 8 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 0 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): PsFileNameBox {font, fontcolor,
; [nakarest] main_func, column, row, sel_num, dial, auto_inc, paintok, aicok} (starts 0xea0ce8,
; [nakarest] 34 of its 122 bytes are here or later).
Str_UiProp_Column:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1ADF2, 0x8
; [nakarest] Str_UiProp_MainFunc  +0x1adfa..+0x1ae04 (0xea0d48, 10 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 0 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): PsFileNameBox {font, fontcolor,
; [nakarest] main_func, column, row, sel_num, dial, auto_inc, paintok, aicok} (starts 0xea0ce8,
; [nakarest] 26 of its 122 bytes are here or later).
Str_UiProp_MainFunc:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1ADFA, 0xA
; [nakarest] Str_UiProp_FontColor  +0x1ae04..+0x1ae0e (0xea0d52, 10 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 0 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): PsFileNameBox {font, fontcolor,
; [nakarest] main_func, column, row, sel_num, dial, auto_inc, paintok, aicok} (starts 0xea0ce8,
; [nakarest] 16 of its 122 bytes are here or later).
Str_UiProp_FontColor:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AE04, 0xA
; [nakarest] Str_UiProp_Font  +0x1ae0e..+0x1ae24 (0xea0d5c, 22 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 0 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): PsFileNameBox {font, fontcolor,
; [nakarest] main_func, column, row, sel_num, dial, auto_inc, paintok, aicok} (starts 0xea0ce8,
; [nakarest] 6 of its 122 bytes are here or later). propname block (the +20 field-name table) of
; [nakarest] class 1 of Class slot 0x165 (table 0xea0f46, 13 entries, InitializeCheap):
; [nakarest] PsWindowToggle {onwin, offwin, main_func}.
Str_UiProp_Font:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AE0E, 0x16
; [nakarest] Data_UiWidgetSep_EA0D72  +0x1ae24..+0x1ae26 (0xea0d72, 2 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 1 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): PsWindowToggle {onwin, offwin,
; [nakarest] main_func} (starts 0xea0d62, 26 of its 42 bytes are here or later).
Data_UiWidgetSep_EA0D72:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AE24, 0x2
; [nakarest] Str_UiProp_MainFunc_EA0D74  +0x1ae26..+0x1ae30 (0xea0d74, 10 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 1 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): PsWindowToggle {onwin, offwin,
; [nakarest] main_func} (starts 0xea0d62, 24 of its 42 bytes are here or later).
Str_UiProp_MainFunc_EA0D74:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AE26, 0xA
; [nakarest] Str_UiProp_FwOn_EA0D7E  +0x1ae30..+0x1ae3a (0xea0d7e, 10 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 1 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): PsWindowToggle {onwin, offwin,
; [nakarest] main_func} (starts 0xea0d62, 14 of its 42 bytes are here or later).
Str_UiProp_FwOn_EA0D7E:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AE30, 0xA
; [nakarest] Str_UiProp_Win_EA0D86  +0x1ae3a..+0x1ae46 (0xea0d88, 12 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 1 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): PsWindowToggle {onwin, offwin,
; [nakarest] main_func} (starts 0xea0d62, 4 of its 42 bytes are here or later). propname block
; [nakarest] (the +20 field-name table) of class 2 of Class slot 0x165 (table 0xea0f46, 13
; [nakarest] entries, InitializeCheap): AcTtlJgBox {main_func}.
Str_UiProp_Win_EA0D86:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AE3A, 0xC
; [nakarest] Str_UiProp_Empty_EA0D94  +0x1ae46..+0x1ae48 (0xea0d94, 2 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 2 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): AcTtlJgBox {main_func} (starts
; [nakarest] 0xea0d8c, 12 of its 20 bytes are here or later).
Str_UiProp_Empty_EA0D94:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AE46, 0x2
; [nakarest] Str_UiProp_MainFunc_EA0D96  +0x1ae48..+0x1ae5e (0xea0d96, 22 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 2 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): AcTtlJgBox {main_func} (starts
; [nakarest] 0xea0d8c, 10 of its 20 bytes are here or later). propname block (the +20 field-name
; [nakarest] table) of class 3 of Class slot 0x165 (table 0xea0f46, 13 entries,
; [nakarest] InitializeCheap): AcParaStrBox {main_func, paintok}.
Str_UiProp_MainFunc_EA0D96:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AE48, 0x16
; [nakarest] Str_UiProp_Empty_EA0DAC  +0x1ae5e..+0x1ae60 (0xea0dac, 2 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 3 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): AcParaStrBox {main_func, paintok}
; [nakarest] (starts 0xea0da0, 20 of its 32 bytes are here or later).
Str_UiProp_Empty_EA0DAC:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AE5E, 0x2
; [nakarest] Str_UiProp_Paintok_EA0DAE  +0x1ae60..+0x1ae68 (0xea0dae, 8 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 3 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): AcParaStrBox {main_func, paintok}
; [nakarest] (starts 0xea0da0, 18 of its 32 bytes are here or later).
Str_UiProp_Paintok_EA0DAE:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AE60, 0x8
; [nakarest] Str_UiProp_MainFunc_EA0DB6  +0x1ae68..+0x1ae72 (0xea0db6, 10 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 3 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): AcParaStrBox {main_func, paintok}
; [nakarest] (starts 0xea0da0, 10 of its 32 bytes are here or later).
Str_UiProp_MainFunc_EA0DB6:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AE68, 0xA
; [nakarest] PtrTbl_UiWidgetProps_EA0DC0  +0x1ae72..+0x1ae82 (0xea0dc0, 16 B)
; [nakarest] propname block (the +20 field-name table) of class 4 of Class slot 0x165 (table
; [nakarest] 0xea0f46, 13 entries, InitializeCheap): AcFileSfxBox {font, main_func, paintok}.
PtrTbl_UiWidgetProps_EA0DC0:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AE72, 0x10
; [nakarest] Str_UiProp_Empty_EA0DD0  +0x1ae82..+0x1ae84 (0xea0dd0, 2 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 4 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): AcFileSfxBox {font, main_func,
; [nakarest] paintok} (starts 0xea0dc0, 26 of its 42 bytes are here or later).
Str_UiProp_Empty_EA0DD0:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AE82, 0x2
; [nakarest] Str_UiProp_Paintok_EA0DD2  +0x1ae84..+0x1ae8c (0xea0dd2, 8 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 4 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): AcFileSfxBox {font, main_func,
; [nakarest] paintok} (starts 0xea0dc0, 24 of its 42 bytes are here or later).
Str_UiProp_Paintok_EA0DD2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AE84, 0x8
; [nakarest] Str_UiProp_MainFunc_EA0DDA  +0x1ae8c..+0x1ae96 (0xea0dda, 10 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 4 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): AcFileSfxBox {font, main_func,
; [nakarest] paintok} (starts 0xea0dc0, 16 of its 42 bytes are here or later).
Str_UiProp_MainFunc_EA0DDA:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AE8C, 0xA
; [nakarest] Str_UiProp_Font_EA0DE4  +0x1ae96..+0x1aea4 (0xea0de4, 14 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 4 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): AcFileSfxBox {font, main_func,
; [nakarest] paintok} (starts 0xea0dc0, 6 of its 42 bytes are here or later). propname block
; [nakarest] (the +20 field-name table) of class 5 of Class slot 0x165 (table 0xea0f46, 13
; [nakarest] entries, InitializeCheap): AcMonoIndexToggle {index}.
Str_UiProp_Font_EA0DE4:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AE96, 0xE
; [nakarest] Data_IndexPropSep_EA0DF2  +0x1aea4..+0x1aea6 (0xea0df2, 2 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 5 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): AcMonoIndexToggle {index} (starts
; [nakarest] 0xea0dea, 8 of its 16 bytes are here or later).
Data_IndexPropSep_EA0DF2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AEA4, 0x2
; [nakarest] Str_UiProp_Index  +0x1aea6..+0x1aeb4 (0xea0df4, 14 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 5 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): AcMonoIndexToggle {index} (starts
; [nakarest] 0xea0dea, 6 of its 16 bytes are here or later). propname block (the +20 field-name
; [nakarest] table) of class 6 of Class slot 0x165 (table 0xea0f46, 13 entries,
; [nakarest] InitializeCheap): IvOneShotTimer {main_func}.
Str_UiProp_Index:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AEA6, 0xE
; [nakarest] Data_MainFuncPropSep_EA0E02  +0x1aeb4..+0x1aeb6 (0xea0e02, 2 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 6 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): IvOneShotTimer {main_func} (starts
; [nakarest] 0xea0dfa, 12 of its 20 bytes are here or later).
Data_MainFuncPropSep_EA0E02:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AEB4, 0x2
; [nakarest] Str_UiProp_MainFunc_EA0E04  +0x1aeb6..+0x1aed0 (0xea0e04, 26 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 6 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): IvOneShotTimer {main_func} (starts
; [nakarest] 0xea0dfa, 10 of its 20 bytes are here or later). propname block (the +20 field-name
; [nakarest] table) of class 7 of Class slot 0x165 (table 0xea0f46, 13 entries,
; [nakarest] InitializeCheap): VwScreenTitle {title, icon, page}.
Str_UiProp_MainFunc_EA0E04:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AEB6, 0x1A
; [nakarest] Data_PageIconPropSep_EA0E1E  +0x1aed0..+0x1aed2 (0xea0e1e, 2 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 7 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): VwScreenTitle {title, icon, page}
; [nakarest] (starts 0xea0e0e, 20 of its 36 bytes are here or later).
Data_PageIconPropSep_EA0E1E:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AED0, 0x2
; [nakarest] Str_UiProp_Page  +0x1aed2..+0x1aed8 (0xea0e20, 6 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 7 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): VwScreenTitle {title, icon, page}
; [nakarest] (starts 0xea0e0e, 18 of its 36 bytes are here or later).
Str_UiProp_Page:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AED2, 0x6
; [nakarest] Str_UiProp_Icon  +0x1aed8..+0x1aede (0xea0e26, 6 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 7 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): VwScreenTitle {title, icon, page}
; [nakarest] (starts 0xea0e0e, 12 of its 36 bytes are here or later).
Str_UiProp_Icon:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AED8, 0x6
; [nakarest] Str_UiProp_Title  +0x1aede..+0x1aee4 (0xea0e2c, 6 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 7 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): VwScreenTitle {title, icon, page}
; [nakarest] (starts 0xea0e0e, 6 of its 36 bytes are here or later).
Str_UiProp_Title:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AEDE, 0x6
; [nakarest] PtrTbl_UiWidgetProps_EA0E32  +0x1aee4..+0x1aefc (0xea0e32, 24 B)
; [nakarest] propname block (the +20 field-name table) of class 8 of Class slot 0x165 (table
; [nakarest] 0xea0f46, 13 entries, InitializeCheap): Arrow {color, frame_only, dir, tail_x_rate,
; [nakarest] tail_y_rate}.
PtrTbl_UiWidgetProps_EA0E32:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AEE4, 0x18
; [nakarest] Data_TailPropSep_EA0E4A  +0x1aefc..+0x1aefe (0xea0e4a, 2 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 8 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): Arrow {color, frame_only, dir,
; [nakarest] tail_x_rate, tail_y_rate} (starts 0xea0e32, 48 of its 72 bytes are here or later).
Data_TailPropSep_EA0E4A:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AEFC, 0x2
; [nakarest] Str_UiProp_TailYRate  +0x1aefe..+0x1af0a (0xea0e4c, 12 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 8 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): Arrow {color, frame_only, dir,
; [nakarest] tail_x_rate, tail_y_rate} (starts 0xea0e32, 46 of its 72 bytes are here or later).
Str_UiProp_TailYRate:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AEFE, 0xC
; [nakarest] Str_UiProp_TailXRate  +0x1af0a..+0x1af16 (0xea0e58, 12 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 8 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): Arrow {color, frame_only, dir,
; [nakarest] tail_x_rate, tail_y_rate} (starts 0xea0e32, 34 of its 72 bytes are here or later).
Str_UiProp_TailXRate:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AF0A, 0xC
; [nakarest] Str_UiProp_Dir  +0x1af16..+0x1af1a (0xea0e64, 4 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 8 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): Arrow {color, frame_only, dir,
; [nakarest] tail_x_rate, tail_y_rate} (starts 0xea0e32, 22 of its 72 bytes are here or later).
Str_UiProp_Dir:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AF16, 0x4
; [nakarest] Str_UiProp_FrameOnly  +0x1af1a..+0x1af26 (0xea0e68, 12 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 8 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): Arrow {color, frame_only, dir,
; [nakarest] tail_x_rate, tail_y_rate} (starts 0xea0e32, 18 of its 72 bytes are here or later).
Str_UiProp_FrameOnly:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AF1A, 0xC
; [nakarest] Str_UiProp_Color  +0x1af26..+0x1af2c (0xea0e74, 6 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 8 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): Arrow {color, frame_only, dir,
; [nakarest] tail_x_rate, tail_y_rate} (starts 0xea0e32, 6 of its 72 bytes are here or later).
Str_UiProp_Color:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AF26, 0x6
; [nakarest] PtrTbl_UiWidgetProps_EA0E7A  +0x1af2c..+0x1af44 (0xea0e7a, 24 B)
; [nakarest] propname block (the +20 field-name table) of class 9 of Class slot 0x165 (table
; [nakarest] 0xea0f46, 13 entries, InitializeCheap): IvIndexSwCtrl {index_min, index_max, dial,
; [nakarest] dial_inv, auto_inc}.
PtrTbl_UiWidgetProps_EA0E7A:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AF2C, 0x18
; [nakarest] Data_DialPropSep_EA0E92  +0x1af44..+0x1af46 (0xea0e92, 2 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 9 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): IvIndexSwCtrl {index_min, index_max,
; [nakarest] dial, dial_inv, auto_inc} (starts 0xea0e7a, 48 of its 72 bytes are here or later).
Data_DialPropSep_EA0E92:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AF44, 0x2
; [nakarest] Str_UiProp_AutoInc_EA0E94  +0x1af46..+0x1af50 (0xea0e94, 10 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 9 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): IvIndexSwCtrl {index_min, index_max,
; [nakarest] dial, dial_inv, auto_inc} (starts 0xea0e7a, 46 of its 72 bytes are here or later).
Str_UiProp_AutoInc_EA0E94:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AF46, 0xA
; [nakarest] Str_UiProp_DialInv  +0x1af50..+0x1af5a (0xea0e9e, 10 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 9 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): IvIndexSwCtrl {index_min, index_max,
; [nakarest] dial, dial_inv, auto_inc} (starts 0xea0e7a, 36 of its 72 bytes are here or later).
Str_UiProp_DialInv:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AF50, 0xA
; [nakarest] Str_UiProp_Dial_EA0EA8  +0x1af5a..+0x1af60 (0xea0ea8, 6 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 9 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): IvIndexSwCtrl {index_min, index_max,
; [nakarest] dial, dial_inv, auto_inc} (starts 0xea0e7a, 26 of its 72 bytes are here or later).
Str_UiProp_Dial_EA0EA8:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AF5A, 0x6
; [nakarest] Str_UiProp_IndexMax  +0x1af60..+0x1af6a (0xea0eae, 10 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 9 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): IvIndexSwCtrl {index_min, index_max,
; [nakarest] dial, dial_inv, auto_inc} (starts 0xea0e7a, 20 of its 72 bytes are here or later).
Str_UiProp_IndexMax:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AF60, 0xA
; [nakarest] Str_UiProp_IndexMin  +0x1af6a..+0x1af74 (0xea0eb8, 10 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 9 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): IvIndexSwCtrl {index_min, index_max,
; [nakarest] dial, dial_inv, auto_inc} (starts 0xea0e7a, 10 of its 72 bytes are here or later).
Str_UiProp_IndexMin:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AF6A, 0xA
; [nakarest] PtrTbl_UiWidgetProps_EA0EC2  +0x1af74..+0x1af88 (0xea0ec2, 20 B)
; [nakarest] propname block (the +20 field-name table) of class 10 of Class slot 0x165 (table
; [nakarest] 0xea0f46, 13 entries, InitializeCheap): AcRotStrBox {func, interval, length,
; [nakarest] paintok}.
PtrTbl_UiWidgetProps_EA0EC2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AF74, 0x14
; [nakarest] Data_PaintokPropSep_EA0ED6  +0x1af88..+0x1af8a (0xea0ed6, 2 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 10 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): AcRotStrBox {func, interval, length,
; [nakarest] paintok} (starts 0xea0ec2, 34 of its 54 bytes are here or later).
Data_PaintokPropSep_EA0ED6:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AF88, 0x2
; [nakarest] Str_UiProp_Paintok_EA0ED8  +0x1af8a..+0x1af92 (0xea0ed8, 8 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 10 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): AcRotStrBox {func, interval, length,
; [nakarest] paintok} (starts 0xea0ec2, 32 of its 54 bytes are here or later).
Str_UiProp_Paintok_EA0ED8:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AF8A, 0x8
; [nakarest] Str_UiProp_Length  +0x1af92..+0x1af9a (0xea0ee0, 8 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 10 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): AcRotStrBox {func, interval, length,
; [nakarest] paintok} (starts 0xea0ec2, 24 of its 54 bytes are here or later).
Str_UiProp_Length:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AF92, 0x8
; [nakarest] Str_UiProp_Interval  +0x1af9a..+0x1afa4 (0xea0ee8, 10 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 10 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): AcRotStrBox {func, interval, length,
; [nakarest] paintok} (starts 0xea0ec2, 16 of its 54 bytes are here or later).
Str_UiProp_Interval:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AF9A, 0xA
; [nakarest] Str_UiProp_Func  +0x1afa4..+0x1afaa (0xea0ef2, 6 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 10 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): AcRotStrBox {func, interval, length,
; [nakarest] paintok} (starts 0xea0ec2, 6 of its 54 bytes are here or later).
Str_UiProp_Func:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AFA4, 0x6
; [nakarest] PtrTbl_UiWidgetProps_EA0EF8  +0x1afaa..+0x1afbe (0xea0ef8, 20 B)
; [nakarest] propname block (the +20 field-name table) of class 11 of Class slot 0x165 (table
; [nakarest] 0xea0f46, 13 entries, InitializeCheap): IvIndexSwDelay {index_min, index_max,
; [nakarest] interval, send_index}.
PtrTbl_UiWidgetProps_EA0EF8:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AFAA, 0x14
; [nakarest] Str_UiProp_Empty_EA0F0C  +0x1afbe..+0x1afc0 (0xea0f0c, 2 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 11 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): IvIndexSwDelay {index_min,
; [nakarest] index_max, interval, send_index} (starts 0xea0ef8, 44 of its 64 bytes are here or
; [nakarest] later).
Str_UiProp_Empty_EA0F0C:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AFBE, 0x2
; [nakarest] Str_UiProp_SendIndex  +0x1afc0..+0x1afcc (0xea0f0e, 12 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 11 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): IvIndexSwDelay {index_min,
; [nakarest] index_max, interval, send_index} (starts 0xea0ef8, 42 of its 64 bytes are here or
; [nakarest] later).
Str_UiProp_SendIndex:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AFC0, 0xC
; [nakarest] Str_UiProp_Interval_EA0F1A  +0x1afcc..+0x1afd6 (0xea0f1a, 10 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 11 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): IvIndexSwDelay {index_min,
; [nakarest] index_max, interval, send_index} (starts 0xea0ef8, 30 of its 64 bytes are here or
; [nakarest] later).
Str_UiProp_Interval_EA0F1A:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AFCC, 0xA
; [nakarest] Str_UiProp_IndexMax_EA0F24  +0x1afd6..+0x1afe0 (0xea0f24, 10 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 11 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): IvIndexSwDelay {index_min,
; [nakarest] index_max, interval, send_index} (starts 0xea0ef8, 20 of its 64 bytes are here or
; [nakarest] later).
Str_UiProp_IndexMax_EA0F24:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AFD6, 0xA
; [nakarest] Str_UiProp_IndexMin_EA0F2E  +0x1afe0..+0x1aff2 (0xea0f2e, 18 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 11 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): IvIndexSwDelay {index_min,
; [nakarest] index_max, interval, send_index} (starts 0xea0ef8, 10 of its 64 bytes are here or
; [nakarest] later). propname block (the +20 field-name table) of class 12 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): IvWaitWinCtl {win}.
Str_UiProp_IndexMin_EA0F2E:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AFE0, 0x12
; [nakarest] Str_UiProp_Empty_EA0F40  +0x1aff2..+0x1aff4 (0xea0f40, 2 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 12 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): IvWaitWinCtl {win} (starts 0xea0f38,
; [nakarest] 6 of its 14 bytes are here or later).
Str_UiProp_Empty_EA0F40:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AFF2, 0x2
; [nakarest] Data_WinProp_EA0F42  +0x1aff4..+0x1aff8 (0xea0f42, 4 B)
; [nakarest] Continues propname block (the +20 field-name table) of class 12 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap): IvWaitWinCtl {win} (starts 0xea0f38,
; [nakarest] 4 of its 14 bytes are here or later).
Data_WinProp_EA0F42:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AFF4, 0x4
; [nakarest] naka_technichord_strings+0x1aff8  +0x1aff8..+0x1b148 (0xea0f46, 336 B)
; [nakarest] the table itself: Class slot 0x165 (table 0xea0f46, 13 entries, InitializeCheap),
; [nakarest] 13 class definitions x 24 bytes. class definition entries 0-12 of Class slot 0x165
; [nakarest] (table 0xea0f46, 13 entries, InitializeCheap) (24 bytes each: proc, parent,
; [nakarest] allsize, selfsize, name, propdata, propname): PsFileNameBox, PsWindowToggle,
; [nakarest] AcTtlJgBox, AcParaStrBox, AcFileSfxBox, AcMonoIndexToggle, IvOneShotTimer,
; [nakarest] VwScreenTitle, Arrow, IvIndexSwCtrl, ....
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1AFF8, 0x150
; [nakarest] naka_technichord_strings+0x1b148  +0x1b148..+0x1b14a (0xea1096, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 12 of Class slot 0x165 (table
; [nakarest] 0xea0f46, 13 entries, InitializeCheap): IvWaitWinCtl "t".
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B148, 0x2
; [nakarest] naka_technichord_strings+0x1b14a  +0x1b14a..+0x1b158 (0xea1098, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 12 of Class slot 0x165 (table
; [nakarest] 0xea0f46, 13 entries, InitializeCheap): IvWaitWinCtl.
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B14A, 0xE
; [nakarest] naka_technichord_strings+0x1b158  +0x1b158..+0x1b15e (0xea10a6, 6 B)
; [nakarest] propdata strings (the +16 field signature) of class 11 of Class slot 0x165 (table
; [nakarest] 0xea0f46, 13 entries, InitializeCheap): IvIndexSwDelay "BBBA".
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B158, 0x6
; [nakarest] naka_technichord_strings+0x1b15e  +0x1b15e..+0x1b16e (0xea10ac, 16 B)
; [nakarest] class-name strings (the +12 name) of classes 11 of Class slot 0x165 (table
; [nakarest] 0xea0f46, 13 entries, InitializeCheap): IvIndexSwDelay.
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B15E, 0x10
; [nakarest] naka_technichord_strings+0x1b16e  +0x1b16e..+0x1b174 (0xea10bc, 6 B)
; [nakarest] propdata strings (the +16 field signature) of class 10 of Class slot 0x165 (table
; [nakarest] 0xea0f46, 13 entries, InitializeCheap): AcRotStrBox "jBBm".
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B16E, 0x6
; [nakarest] naka_technichord_strings+0x1b174  +0x1b174..+0x1b180 (0xea10c2, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 10 of Class slot 0x165 (table
; [nakarest] 0xea0f46, 13 entries, InitializeCheap): AcRotStrBox.
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B174, 0xC
; [nakarest] naka_technichord_strings+0x1b180  +0x1b180..+0x1b186 (0xea10ce, 6 B)
; [nakarest] propdata strings (the +16 field signature) of class 9 of Class slot 0x165 (table
; [nakarest] 0xea0f46, 13 entries, InitializeCheap): IvIndexSwCtrl "BBGGG".
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B180, 0x6
; [nakarest] naka_technichord_strings+0x1b186  +0x1b186..+0x1b194 (0xea10d4, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 9 of Class slot 0x165 (table 0xea0f46,
; [nakarest] 13 entries, InitializeCheap): IvIndexSwCtrl.
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B186, 0xE
; [nakarest] naka_technichord_strings+0x1b194  +0x1b194..+0x1b19a (0xea10e2, 6 B)
; [nakarest] propdata strings (the +16 field signature) of class 8 of Class slot 0x165 (table
; [nakarest] 0xea0f46, 13 entries, InitializeCheap): Arrow "^GBBB".
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B194, 0x6
; [nakarest] naka_technichord_strings+0x1b19a  +0x1b19a..+0x1b1a0 (0xea10e8, 6 B)
; [nakarest] class-name strings (the +12 name) of classes 8 of Class slot 0x165 (table 0xea0f46,
; [nakarest] 13 entries, InitializeCheap): Arrow.
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B19A, 0x6
; [nakarest] naka_technichord_strings+0x1b1a0  +0x1b1a0..+0x1b1a4 (0xea10ee, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 7 of Class slot 0x165 (table
; [nakarest] 0xea0f46, 13 entries, InitializeCheap): VwScreenTitle "XbG".
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B1A0, 0x4
; [nakarest] naka_technichord_strings+0x1b1a4  +0x1b1a4..+0x1b1b2 (0xea10f2, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 7 of Class slot 0x165 (table 0xea0f46,
; [nakarest] 13 entries, InitializeCheap): VwScreenTitle.
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B1A4, 0xE
; [nakarest] naka_technichord_strings+0x1b1b2  +0x1b1b2..+0x1b1b4 (0xea1100, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 6 of Class slot 0x165 (table
; [nakarest] 0xea0f46, 13 entries, InitializeCheap): IvOneShotTimer "k".
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B1B2, 0x2
; [nakarest] naka_technichord_strings+0x1b1b4  +0x1b1b4..+0x1b1c4 (0xea1102, 16 B)
; [nakarest] class-name strings (the +12 name) of classes 6 of Class slot 0x165 (table 0xea0f46,
; [nakarest] 13 entries, InitializeCheap): IvOneShotTimer.
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B1B4, 0x10
; [nakarest] naka_technichord_strings+0x1b1c4  +0x1b1c4..+0x1b1c6 (0xea1112, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 5 of Class slot 0x165 (table
; [nakarest] 0xea0f46, 13 entries, InitializeCheap): AcMonoIndexToggle "A".
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B1C4, 0x2
; [nakarest] naka_technichord_strings+0x1b1c6  +0x1b1c6..+0x1b1d8 (0xea1114, 18 B)
; [nakarest] class-name strings (the +12 name) of classes 5 of Class slot 0x165 (table 0xea0f46,
; [nakarest] 13 entries, InitializeCheap): AcMonoIndexToggle.
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B1C6, 0x12
; [nakarest] naka_technichord_strings+0x1b1d8  +0x1b1d8..+0x1b1dc (0xea1126, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 4 of Class slot 0x165 (table
; [nakarest] 0xea0f46, 13 entries, InitializeCheap): AcFileSfxBox "ckm".
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B1D8, 0x4
; [nakarest] naka_technichord_strings+0x1b1dc  +0x1b1dc..+0x1b1ea (0xea112a, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 4 of Class slot 0x165 (table 0xea0f46,
; [nakarest] 13 entries, InitializeCheap): AcFileSfxBox.
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B1DC, 0xE
; [nakarest] naka_technichord_strings+0x1b1ea  +0x1b1ea..+0x1b1ee (0xea1138, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 3 of Class slot 0x165 (table
; [nakarest] 0xea0f46, 13 entries, InitializeCheap): AcParaStrBox "km".
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B1EA, 0x4
; [nakarest] naka_technichord_strings+0x1b1ee  +0x1b1ee..+0x1b1fc (0xea113c, 14 B)
; [nakarest] class-name strings (the +12 name) of classes 3 of Class slot 0x165 (table 0xea0f46,
; [nakarest] 13 entries, InitializeCheap): AcParaStrBox.
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B1EE, 0xE
; [nakarest] naka_technichord_strings+0x1b1fc  +0x1b1fc..+0x1b1fe (0xea114a, 2 B)
; [nakarest] propdata strings (the +16 field signature) of class 2 of Class slot 0x165 (table
; [nakarest] 0xea0f46, 13 entries, InitializeCheap): AcTtlJgBox "k".
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B1FC, 0x2
; [nakarest] naka_technichord_strings+0x1b1fe  +0x1b1fe..+0x1b20a (0xea114c, 12 B)
; [nakarest] class-name strings (the +12 name) of classes 2 of Class slot 0x165 (table 0xea0f46,
; [nakarest] 13 entries, InitializeCheap): AcTtlJgBox.
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B1FE, 0xC
; [nakarest] naka_technichord_strings+0x1b20a  +0x1b20a..+0x1b20e (0xea1158, 4 B)
; [nakarest] propdata strings (the +16 field signature) of class 1 of Class slot 0x165 (table
; [nakarest] 0xea0f46, 13 entries, InitializeCheap): PsWindowToggle "ttk".
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B20A, 0x4
; [nakarest] naka_technichord_strings+0x1b20e  +0x1b20e..+0x1b21e (0xea115c, 16 B)
; [nakarest] class-name strings (the +12 name) of classes 1 of Class slot 0x165 (table 0xea0f46,
; [nakarest] 13 entries, InitializeCheap): PsWindowToggle.
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B20E, 0x10
; [nakarest] naka_technichord_strings+0x1b21e  +0x1b21e..+0x1b22a (0xea116c, 12 B)
; [nakarest] propdata strings (the +16 field signature) of class 0 of Class slot 0x165 (table
; [nakarest] 0xea0f46, 13 entries, InitializeCheap): PsFileNameBox "c^kAAnGGmm".
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B21E, 0xC
; [nakarest] naka_technichord_strings+0x1b22a  +0x1b22a..+0x1b23a (0xea1178, 16 B)
; [nakarest] class-name strings (the +12 name) of classes 0 of Class slot 0x165 (table 0xea0f46,
; [nakarest] 13 entries, InitializeCheap): PsFileNameBox.
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B22A, 0x10
; [nakarest] PtrTbl_EventNames_EA1188  +0x1b23a..+0x1b252 (0xea1188, 24 B)
; [nakarest] the table itself: ResEvent slot 0x1c5 (table 0xea1188, 5 entries, InitializeCheap),
; [nakarest] 5 entry pointers x 4 bytes.
PtrTbl_EventNames_EA1188:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B23A, 0x18
; [nakarest] Str_Ev_WakeUpPassword  +0x1b252..+0x1b264 (0xea11a0, 18 B)
; [nakarest] name string, entry 4 of ResEvent slot 0x1c5 (table 0xea1188, 5 entries,
; [nakarest] InitializeCheap): "EV_WAKEUPPASSWORD".
Str_Ev_WakeUpPassword:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B252, 0x12
; [nakarest] Str_Ev_IndexSwDownD  +0x1b264..+0x1b276 (0xea11b2, 18 B)
; [nakarest] name string, entry 3 of ResEvent slot 0x1c5 (table 0xea1188, 5 entries,
; [nakarest] InitializeCheap): "EV_INDEXSW_DOWN_D".
Str_Ev_IndexSwDownD:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B264, 0x12
; [nakarest] Str_Ev_IndexSwUpD  +0x1b276..+0x1b286 (0xea11c4, 16 B)
; [nakarest] name string, entry 2 of ResEvent slot 0x1c5 (table 0xea1188, 5 entries,
; [nakarest] InitializeCheap): "EV_INDEXSW_UP_D".
Str_Ev_IndexSwUpD:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B276, 0x10
; [nakarest] Str_Ev_NotPostAic  +0x1b286..+0x1b294 (0xea11d4, 14 B)
; [nakarest] name string, entry 1 of ResEvent slot 0x1c5 (table 0xea1188, 5 entries,
; [nakarest] InitializeCheap): "EV_NOTPOSTAIC".
Str_Ev_NotPostAic:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B286, 0xE
; [nakarest] Str_Ev_NotParaDraw  +0x1b294..+0x1b2a6 (0xea11e2, 18 B)
; [nakarest] name string, entry 0 of ResEvent slot 0x1c5 (table 0xea1188, 5 entries,
; [nakarest] InitializeCheap): "EV_NOTPARADRAW".
Str_Ev_NotParaDraw:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B294, 0x12
; [nakarest] naka_technichord_strings+0x1b2a6  +0x1b2a6..+0x1b2aa (0xea11f4, 4 B)
; [nakarest] the table itself: ResMethod slot 0x1e5 (table 0xea11f4, 17 entries,
; [nakarest] InitializeCheap), 17 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B2A6, 0x4
; [nakarest] PtrTbl_MsgTypeNames_EA11F8  +0x1b2aa..+0x1b2ee (0xea11f8, 68 B)
; [nakarest] purpose not established: 4 bytes at 0xea1238 that no registered NAKA table points into
; [nakarest] Continues the table itself: ResMethod slot 0x1e5 (table 0xea11f4, 17 entries,
; [nakarest] InitializeCheap), 17 entry pointers x 4 bytes (starts 0xea11f4, 64 of its 68 bytes
; [nakarest] are here or later).
PtrTbl_MsgTypeNames_EA11F8:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B2AA, 0x44
; [nakarest] Str_Mt_CheckPassword3  +0x1b2ee..+0x1b300 (0xea123c, 18 B)
; [nakarest] name string, entry 16 of ResMethod slot 0x1e5 (table 0xea11f4, 17 entries,
; [nakarest] InitializeCheap): "MT_CheckPassword3".
Str_Mt_CheckPassword3:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B2EE, 0x12
; [nakarest] Str_Mt_CheckPassword2  +0x1b300..+0x1b312 (0xea124e, 18 B)
; [nakarest] name string, entry 15 of ResMethod slot 0x1e5 (table 0xea11f4, 17 entries,
; [nakarest] InitializeCheap): "MT_CheckPassword2".
Str_Mt_CheckPassword2:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B300, 0x12
; [nakarest] Str_Mt_CheckPassword  +0x1b312..+0x1b324 (0xea1260, 18 B)
; [nakarest] name string, entry 14 of ResMethod slot 0x1e5 (table 0xea11f4, 17 entries,
; [nakarest] InitializeCheap): "MT_CheckPassword".
Str_Mt_CheckPassword:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B312, 0x12
; [nakarest] Str_Mt_SetPassword  +0x1b324..+0x1b334 (0xea1272, 16 B)
; [nakarest] name string, entry 13 of ResMethod slot 0x1e5 (table 0xea11f4, 17 entries,
; [nakarest] InitializeCheap): "MT_SetPassword".
Str_Mt_SetPassword:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B324, 0x10
; [nakarest] Str_Mt_FlashLoad  +0x1b334..+0x1b342 (0xea1282, 14 B)
; [nakarest] name string, entry 12 of ResMethod slot 0x1e5 (table 0xea11f4, 17 entries,
; [nakarest] InitializeCheap): "MT_FlashLoad".
Str_Mt_FlashLoad:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B334, 0xE
; [nakarest] Str_Mt_FlashWrite  +0x1b342..+0x1b350 (0xea1290, 14 B)
; [nakarest] name string, entry 11 of ResMethod slot 0x1e5 (table 0xea11f4, 17 entries,
; [nakarest] InitializeCheap): "MT_FlashWrite".
Str_Mt_FlashWrite:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B342, 0xE
; [nakarest] Str_Mt_WakeUpNow  +0x1b350..+0x1b35e (0xea129e, 14 B)
; [nakarest] name string, entry 10 of ResMethod slot 0x1e5 (table 0xea11f4, 17 entries,
; [nakarest] InitializeCheap): "MT_WakeUpNow".
Str_Mt_WakeUpNow:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B350, 0xE
; [nakarest] Str_Mt_WakeUpTime  +0x1b35e..+0x1b36c (0xea12ac, 14 B)
; [nakarest] name string, entry 9 of ResMethod slot 0x1e5 (table 0xea11f4, 17 entries,
; [nakarest] InitializeCheap): "MT_WakeUpTime".
Str_Mt_WakeUpTime:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B35E, 0xE
; [nakarest] Str_Mt_IWillWakeUp  +0x1b36c..+0x1b37c (0xea12ba, 16 B)
; [nakarest] name string, entry 8 of ResMethod slot 0x1e5 (table 0xea11f4, 17 entries,
; [nakarest] InitializeCheap): "MT_IWillWakeUp".
Str_Mt_IWillWakeUp:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B36C, 0x10
; [nakarest] Str_Mt_WhichWindow  +0x1b37c..+0x1b38c (0xea12ca, 16 B)
; [nakarest] name string, entry 7 of ResMethod slot 0x1e5 (table 0xea11f4, 17 entries,
; [nakarest] InitializeCheap): "MT_WhichWindow".
Str_Mt_WhichWindow:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B37C, 0x10
; [nakarest] Str_Mt_OffWindow  +0x1b38c..+0x1b39a (0xea12da, 14 B)
; [nakarest] name string, entry 6 of ResMethod slot 0x1e5 (table 0xea11f4, 17 entries,
; [nakarest] InitializeCheap): "MT_OffWindow".
Str_Mt_OffWindow:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B38C, 0xE
; [nakarest] Str_Mt_OnWindow  +0x1b39a..+0x1b3a6 (0xea12e8, 12 B)
; [nakarest] name string, entry 5 of ResMethod slot 0x1e5 (table 0xea11f4, 17 entries,
; [nakarest] InitializeCheap): "MT_OnWindow".
Str_Mt_OnWindow:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B39A, 0xC
; [nakarest] Str_Mt_PsFileNameBoxId  +0x1b3a6..+0x1b3ba (0xea12f4, 20 B)
; [nakarest] name string, entry 4 of ResMethod slot 0x1e5 (table 0xea11f4, 17 entries,
; [nakarest] InitializeCheap): "MT_PsFileNameBoxID".
Str_Mt_PsFileNameBoxId:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B3A6, 0x14
; [nakarest] Str_Mt_GetSelectedFileNumber  +0x1b3ba..+0x1b3d4 (0xea1308, 26 B)
; [nakarest] name string, entry 3 of ResMethod slot 0x1e5 (table 0xea11f4, 17 entries,
; [nakarest] InitializeCheap): "MT_GetSelectedFileNumber".
Str_Mt_GetSelectedFileNumber:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B3BA, 0x1A
; [nakarest] Str_Mt_SetSelectedFileNumber  +0x1b3d4..+0x1b3ee (0xea1322, 26 B)
; [nakarest] name string, entry 2 of ResMethod slot 0x1e5 (table 0xea11f4, 17 entries,
; [nakarest] InitializeCheap): "MT_SetSelectedFileNumber".
Str_Mt_SetSelectedFileNumber:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B3D4, 0x1A
; [nakarest] Str_Mt_SetFileSfx  +0x1b3ee..+0x1b40c (0xea133c, 30 B)
; [nakarest] name strings, entries 0-1 of ResMethod slot 0x1e5 (table 0xea11f4, 17 entries,
; [nakarest] InitializeCheap): "MT_SetFileSfx", "MT_GetFileSfx".
Str_Mt_SetFileSfx:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B3EE, 0x1E
; [nakarest] naka_technichord_strings+0x1b40c  +0x1b40c..+0x1b444 (0xea135a, 56 B)
; [nakarest] the table itself: Function slot 0x105 (table 0xea135a, 13 entries,
; [nakarest] InitializeCheap), 13 entry pointers x 4 bytes.
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B40C, 0x38
; [nakarest] PtrTbl_NakaModuleHandlers  +0x1b444..+0x1b47c (0xea1392, 56 B)
; [nakarest] the table itself: Function slot 0x405 (table 0xea1392, 13 entries,
; [nakarest] InitializeCheap), 13 entry pointers x 4 bytes.
PtrTbl_NakaModuleHandlers:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B444, 0x38
; [nakarest] Data_NakaSep_EA13CA  +0x1b47c..+0x1b47e (0xea13ca, 2 B)
; [nakarest] purpose not established: 2 bytes at 0xea13ca that no registered NAKA table points into
Data_NakaSep_EA13CA:
	.incbin "includes/generated/naka_technichord_strings.bin", 0x1B47C, 0x2

; External label offsets within the binary blob above.
	.equ Data_DiskFuncPtrTbl_EA0B00, NakaData_TechniChordStrings + 0x1abb2
	.equ Str_CheckPasswordNo, NakaData_TechniChordStrings + 0x1abfa
