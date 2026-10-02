
; Normal Mode screen layout (14 widgets, 1168 bytes)
; Source: maincpu/ui_widgets/naka_normal_mode.c (C struct with named fields)
; -----------------------------------------------------------------------------
; [nakarest_retype] registered NAKA tables: naka_normal_mode
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
; Viewable slot 0x1: RegObjTabl 0x1600010, ViewableProc, 0x3f, 0xed77ce,
; 0x1 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 63, table} at 0x27ed2 +
; 14*0x1. Element 0 is named "Normal" in ResName slot 0x301. Links: all
; 63 records consistent.
;
; MainFunction slot 0x442: RegObjTabl 0x1600003, MainFunctionProc, 0x14,
; 0xed32e6, 0x442 in InitializeToshi (extensions/extension_init.s), i.e.
; RegisterObjectTable stores {class, proc, 20, table} at 0x27ed2 +
; 14*0x442.
; -----------------------------------------------------------------------------

; [nakarest] NakaInst_TEST6FUNC  +0x0..+0xa (0xed333c, 10 B)
; [nakarest] name string, entry 19 of MainFunction slot 0x442 (table 0xed32e6, 20 entries,
; [nakarest] InitializeToshi) (names for MainFunction slot 0x142): "TEST6FUNC".
NakaInst_TEST6FUNC:
	.incbin "includes/generated/naka_normal_mode.bin", 0x0, 0xA
; [nakarest] NakaInst_TEST4FUNC  +0xa..+0x14 (0xed3346, 10 B)
; [nakarest] name string, entry 18 of MainFunction slot 0x442 (table 0xed32e6, 20 entries,
; [nakarest] InitializeToshi) (names for MainFunction slot 0x142): "TEST4FUNC".
NakaInst_TEST4FUNC:
	.incbin "includes/generated/naka_normal_mode.bin", 0xA, 0xA
; [nakarest] NakaInst_TEST3FUNC  +0x14..+0x1e (0xed3350, 10 B)
; [nakarest] name string, entry 17 of MainFunction slot 0x442 (table 0xed32e6, 20 entries,
; [nakarest] InitializeToshi) (names for MainFunction slot 0x142): "TEST3FUNC".
NakaInst_TEST3FUNC:
	.incbin "includes/generated/naka_normal_mode.bin", 0x14, 0xA
; [nakarest] NakaInst_TEST2FUNC  +0x1e..+0x28 (0xed335a, 10 B)
; [nakarest] name string, entry 16 of MainFunction slot 0x442 (table 0xed32e6, 20 entries,
; [nakarest] InitializeToshi) (names for MainFunction slot 0x142): "TEST2FUNC".
NakaInst_TEST2FUNC:
	.incbin "includes/generated/naka_normal_mode.bin", 0x1E, 0xA
; [nakarest] NakaInst_MainWallSetFlashFunc  +0x28..+0x3e (0xed3364, 22 B)
; [nakarest] name string, entry 15 of MainFunction slot 0x442 (table 0xed32e6, 20 entries,
; [nakarest] InitializeToshi) (names for MainFunction slot 0x142): "MainWallSetFlashFunc".
NakaInst_MainWallSetFlashFunc:
	.incbin "includes/generated/naka_normal_mode.bin", 0x28, 0x16
; [nakarest] NakaInst_MainTimeFlashFunc  +0x3e..+0x50 (0xed337a, 18 B)
; [nakarest] name string, entry 14 of MainFunction slot 0x442 (table 0xed32e6, 20 entries,
; [nakarest] InitializeToshi) (names for MainFunction slot 0x142): "MainTimeFlashFunc".
NakaInst_MainTimeFlashFunc:
	.incbin "includes/generated/naka_normal_mode.bin", 0x3E, 0x12
; [nakarest] NakaInst_MainMssSetUp  +0x50..+0x5e (0xed338c, 14 B)
; [nakarest] name string, entry 13 of MainFunction slot 0x442 (table 0xed32e6, 20 entries,
; [nakarest] InitializeToshi) (names for MainFunction slot 0x142): "MainMssSetUp".
NakaInst_MainMssSetUp:
	.incbin "includes/generated/naka_normal_mode.bin", 0x50, 0xE
; [nakarest] NakaInst_FswAsIniFunc  +0x5e..+0x6c (0xed339a, 14 B)
; [nakarest] name string, entry 12 of MainFunction slot 0x442 (table 0xed32e6, 20 entries,
; [nakarest] InitializeToshi) (names for MainFunction slot 0x142): "FswAsIniFunc".
NakaInst_FswAsIniFunc:
	.incbin "includes/generated/naka_normal_mode.bin", 0x5E, 0xE
; [nakarest] NakaInst_CntIniFunc  +0x6c..+0x78 (0xed33a8, 12 B)
; [nakarest] name string, entry 11 of MainFunction slot 0x442 (table 0xed32e6, 20 entries,
; [nakarest] InitializeToshi) (names for MainFunction slot 0x142): "CntIniFunc".
NakaInst_CntIniFunc:
	.incbin "includes/generated/naka_normal_mode.bin", 0x6C, 0xC
; [nakarest] NakaInst_MainSysControl  +0x78..+0x88 (0xed33b4, 16 B)
; [nakarest] name string, entry 10 of MainFunction slot 0x442 (table 0xed32e6, 20 entries,
; [nakarest] InitializeToshi) (names for MainFunction slot 0x142): "MainSysControl".
NakaInst_MainSysControl:
	.incbin "includes/generated/naka_normal_mode.bin", 0x78, 0x10
; [nakarest] NakaInst_OneTchFUNC  +0x88..+0x94 (0xed33c4, 12 B)
; [nakarest] name string, entry 9 of MainFunction slot 0x442 (table 0xed32e6, 20 entries,
; [nakarest] InitializeToshi) (names for MainFunction slot 0x142): "OneTchFUNC".
NakaInst_OneTchFUNC:
	.incbin "includes/generated/naka_normal_mode.bin", 0x88, 0xC
; [nakarest] NakaInst_MainPmGet  +0x94..+0x9e (0xed33d0, 10 B)
; [nakarest] name string, entry 8 of MainFunction slot 0x442 (table 0xed32e6, 20 entries,
; [nakarest] InitializeToshi) (names for MainFunction slot 0x142): "MainPmGet".
NakaInst_MainPmGet:
	.incbin "includes/generated/naka_normal_mode.bin", 0x94, 0xA
; [nakarest] NakaInst_MainChordPre  +0x9e..+0xac (0xed33da, 14 B)
; [nakarest] name string, entry 7 of MainFunction slot 0x442 (table 0xed32e6, 20 entries,
; [nakarest] InitializeToshi) (names for MainFunction slot 0x142): "MainChordPre".
NakaInst_MainChordPre:
	.incbin "includes/generated/naka_normal_mode.bin", 0x9E, 0xE
; [nakarest] NakaInst_MainGetRhyGrpName  +0xac..+0xbe (0xed33e8, 18 B)
; [nakarest] name string, entry 6 of MainFunction slot 0x442 (table 0xed32e6, 20 entries,
; [nakarest] InitializeToshi) (names for MainFunction slot 0x142): "MainGetRhyGrpName".
NakaInst_MainGetRhyGrpName:
	.incbin "includes/generated/naka_normal_mode.bin", 0xAC, 0x12
; [nakarest] NakaInst_MainGetSndGrpName  +0xbe..+0xd0 (0xed33fa, 18 B)
; [nakarest] name string, entry 5 of MainFunction slot 0x442 (table 0xed32e6, 20 entries,
; [nakarest] InitializeToshi) (names for MainFunction slot 0x142): "MainGetSndGrpName".
NakaInst_MainGetSndGrpName:
	.incbin "includes/generated/naka_normal_mode.bin", 0xBE, 0x12
; [nakarest] NakaInst_MainGetRhyName  +0xd0..+0xe0 (0xed340c, 16 B)
; [nakarest] name string, entry 4 of MainFunction slot 0x442 (table 0xed32e6, 20 entries,
; [nakarest] InitializeToshi) (names for MainFunction slot 0x142): "MainGetRhyName".
NakaInst_MainGetRhyName:
	.incbin "includes/generated/naka_normal_mode.bin", 0xD0, 0x10
; [nakarest] NakaInst_MainRvariIni  +0xe0..+0xee (0xed341c, 14 B)
; [nakarest] name string, entry 3 of MainFunction slot 0x442 (table 0xed32e6, 20 entries,
; [nakarest] InitializeToshi) (names for MainFunction slot 0x142): "MainRvariIni".
NakaInst_MainRvariIni:
	.incbin "includes/generated/naka_normal_mode.bin", 0xE0, 0xE
; [nakarest] NakaInst_MainGetSndName  +0xee..+0xfe (0xed342a, 16 B)
; [nakarest] name string, entry 2 of MainFunction slot 0x442 (table 0xed32e6, 20 entries,
; [nakarest] InitializeToshi) (names for MainFunction slot 0x142): "MainGetSndName".
NakaInst_MainGetSndName:
	.incbin "includes/generated/naka_normal_mode.bin", 0xEE, 0x10
; [nakarest] NakaInst_MainSvariIni  +0xfe..+0x10c (0xed343a, 14 B)
; [nakarest] name string, entry 1 of MainFunction slot 0x442 (table 0xed32e6, 20 entries,
; [nakarest] InitializeToshi) (names for MainFunction slot 0x142): "MainSvariIni".
NakaInst_MainSvariIni:
	.incbin "includes/generated/naka_normal_mode.bin", 0xFE, 0xE
; [nakarest] NakaInst_MainVariSet  +0x10c..+0x118 (0xed3448, 12 B)
; [nakarest] name string, entry 0 of MainFunction slot 0x442 (table 0xed32e6, 20 entries,
; [nakarest] InitializeToshi) (names for MainFunction slot 0x142): "MainVariSet".
NakaInst_MainVariSet:
	.incbin "includes/generated/naka_normal_mode.bin", 0x10C, 0xC
; [nakarest] naka_normal_mode+0x118  +0x118..+0x490 (0xed3454, 888 B)
; [nakarest] widget records, elements 0-24 of Viewable slot 0x1 (table 0xed77ce, 63 entries,
; [nakarest] InitializeToshi) ("Normal"): TtlScreen (42 B), NormScreen (42 B), AcTempoBox (36
; [nakarest] B), AcPmemName (36 B), AcRhythmName (36 B), AcSoundName (38 B) x3, StringBox (38 B)
; [nakarest] x4, TransposeBox (36 B), ChordBox (36 B), AcLswBox (44 B), IvWindowPageControl (26
; [nakarest] B), FreeSplitBox (36 B), IvPageOverWr (28 B) x6, IvExit (22 B), Window (36 B). 6
; [nakarest] texts the records point at (Viewable slot 0x1 (table 0xed77ce, 63 entries,
; [nakarest] InitializeToshi)): "NORMAL" (TtlScreen.title of element 0); "" (NormScreen.title of
; [nakarest] element 1); "RIGHT2" (StringBox.str of element 7); "RIGHT1" (StringBox.str of
; [nakarest] element 9); ....
NakaWidget_Normal:				.incbin "includes/generated/naka_normal_mode.bin", 0x118, 0x32
NakaWidget_normal:				.incbin "includes/generated/naka_normal_mode.bin", 0x14A, 0x2C
NakaWidget_Normal_2_AcTempoBox:			.incbin "includes/generated/naka_normal_mode.bin", 0x176, 0x24
NakaWidget_Normal_3_AcPmemName:			.incbin "includes/generated/naka_normal_mode.bin", 0x19A, 0x24
NakaWidget_Normal_4_AcRhythmName:		.incbin "includes/generated/naka_normal_mode.bin", 0x1BE, 0x24
NakaWidget_Normal_5_AcSoundName:		.incbin "includes/generated/naka_normal_mode.bin", 0x1E2, 0x26
NakaWidget_Normal_6_AcSoundName:		.incbin "includes/generated/naka_normal_mode.bin", 0x208, 0x26
NakaWidget_Normal_7_StringBox:			.incbin "includes/generated/naka_normal_mode.bin", 0x22E, 0x2E
NakaWidget_Normal_8_AcSoundName:		.incbin "includes/generated/naka_normal_mode.bin", 0x25C, 0x26
NakaWidget_Normal_9_StringBox:			.incbin "includes/generated/naka_normal_mode.bin", 0x282, 0x2E
NakaWidget_Normal_10_StringBox:			.incbin "includes/generated/naka_normal_mode.bin", 0x2B0, 0x2C
NakaWidget_Normal_11_StringBox:			.incbin "includes/generated/naka_normal_mode.bin", 0x2DC, 0x2E
NakaWidget_Normal_12_TransposeBox:		.incbin "includes/generated/naka_normal_mode.bin", 0x30A, 0x24
NakaWidget_Normal_13_ChordBox:			.incbin "includes/generated/naka_normal_mode.bin", 0x32E, 0x24
NakaWidget_Normal_14_AcLswBox:			.incbin "includes/generated/naka_normal_mode.bin", 0x352, 0x2C
NakaWidget_Normal_15_IvWindowPageControl:	.incbin "includes/generated/naka_normal_mode.bin", 0x37E, 0x1A
NakaWidget_Normal_16_FreeSplitBox:		.incbin "includes/generated/naka_normal_mode.bin", 0x398, 0x24
NakaWidget_Normal_17_IvPageOverWr:		.incbin "includes/generated/naka_normal_mode.bin", 0x3BC, 0x1C
NakaWidget_Normal_18_IvPageOverWr:		.incbin "includes/generated/naka_normal_mode.bin", 0x3D8, 0x1C
NakaWidget_Normal_19_IvPageOverWr:		.incbin "includes/generated/naka_normal_mode.bin", 0x3F4, 0x1C
NakaWidget_Normal_20_IvPageOverWr:		.incbin "includes/generated/naka_normal_mode.bin", 0x410, 0x1C
NakaWidget_Normal_21_IvPageOverWr:		.incbin "includes/generated/naka_normal_mode.bin", 0x42C, 0x1C
NakaWidget_Normal_22_IvPageOverWr:		.incbin "includes/generated/naka_normal_mode.bin", 0x448, 0x1C
NakaWidget_Normal_23_IvExit:			.incbin "includes/generated/naka_normal_mode.bin", 0x464, 0x16
NakaWidget_N1:					.incbin "includes/generated/naka_normal_mode.bin", 0x47A, 0x16
; External label offsets within the binary blob above.
