
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
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_TEST6FUNC
; NakaInst_TEST6FUNC  --  naka_normal_mode +0x0..+0xa (ROM 0xed333c..0xed3346), 10 bytes
; Name strings of element 19 of MainFunction slot 0x442 (table 0xed32e6,
; 20 entries, InitializeToshi), names for MainFunction slot 0x142:
; "TEST6FUNC".
; -----------------------------------------------------------------------------
NakaInst_TEST6FUNC:
	.incbin "includes/generated/naka_normal_mode.bin", 0x0, 0xA
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_TEST4FUNC
; NakaInst_TEST4FUNC  --  naka_normal_mode +0xa..+0x14 (ROM 0xed3346..0xed3350), 10 bytes
; Name strings of element 18 of MainFunction slot 0x442 (table 0xed32e6,
; 20 entries, InitializeToshi), names for MainFunction slot 0x142:
; "TEST4FUNC".
; -----------------------------------------------------------------------------
NakaInst_TEST4FUNC:
	.incbin "includes/generated/naka_normal_mode.bin", 0xA, 0xA
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_TEST3FUNC
; NakaInst_TEST3FUNC  --  naka_normal_mode +0x14..+0x1e (ROM 0xed3350..0xed335a), 10 bytes
; Name strings of element 17 of MainFunction slot 0x442 (table 0xed32e6,
; 20 entries, InitializeToshi), names for MainFunction slot 0x142:
; "TEST3FUNC".
; -----------------------------------------------------------------------------
NakaInst_TEST3FUNC:
	.incbin "includes/generated/naka_normal_mode.bin", 0x14, 0xA
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_TEST2FUNC
; NakaInst_TEST2FUNC  --  naka_normal_mode +0x1e..+0x28 (ROM 0xed335a..0xed3364), 10 bytes
; Name strings of element 16 of MainFunction slot 0x442 (table 0xed32e6,
; 20 entries, InitializeToshi), names for MainFunction slot 0x142:
; "TEST2FUNC".
; -----------------------------------------------------------------------------
NakaInst_TEST2FUNC:
	.incbin "includes/generated/naka_normal_mode.bin", 0x1E, 0xA
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_MainWallSetFlashFunc
; NakaInst_MainWallSetFlashFunc  --  naka_normal_mode +0x28..+0x3e (ROM 0xed3364..0xed337a), 22 bytes
; Name strings of element 15 of MainFunction slot 0x442 (table 0xed32e6,
; 20 entries, InitializeToshi), names for MainFunction slot 0x142:
; "MainWallSetFlashFunc".
; -----------------------------------------------------------------------------
NakaInst_MainWallSetFlashFunc:
	.incbin "includes/generated/naka_normal_mode.bin", 0x28, 0x16
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_MainTimeFlashFunc
; NakaInst_MainTimeFlashFunc  --  naka_normal_mode +0x3e..+0x50 (ROM 0xed337a..0xed338c), 18 bytes
; Name strings of element 14 of MainFunction slot 0x442 (table 0xed32e6,
; 20 entries, InitializeToshi), names for MainFunction slot 0x142:
; "MainTimeFlashFunc".
; -----------------------------------------------------------------------------
NakaInst_MainTimeFlashFunc:
	.incbin "includes/generated/naka_normal_mode.bin", 0x3E, 0x12
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_MainMssSetUp
; NakaInst_MainMssSetUp  --  naka_normal_mode +0x50..+0x5e (ROM 0xed338c..0xed339a), 14 bytes
; Name strings of element 13 of MainFunction slot 0x442 (table 0xed32e6,
; 20 entries, InitializeToshi), names for MainFunction slot 0x142:
; "MainMssSetUp".
; -----------------------------------------------------------------------------
NakaInst_MainMssSetUp:
	.incbin "includes/generated/naka_normal_mode.bin", 0x50, 0xE
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_FswAsIniFunc
; NakaInst_FswAsIniFunc  --  naka_normal_mode +0x5e..+0x6c (ROM 0xed339a..0xed33a8), 14 bytes
; Name strings of element 12 of MainFunction slot 0x442 (table 0xed32e6,
; 20 entries, InitializeToshi), names for MainFunction slot 0x142:
; "FswAsIniFunc".
; -----------------------------------------------------------------------------
NakaInst_FswAsIniFunc:
	.incbin "includes/generated/naka_normal_mode.bin", 0x5E, 0xE
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_CntIniFunc
; NakaInst_CntIniFunc  --  naka_normal_mode +0x6c..+0x78 (ROM 0xed33a8..0xed33b4), 12 bytes
; Name strings of element 11 of MainFunction slot 0x442 (table 0xed32e6,
; 20 entries, InitializeToshi), names for MainFunction slot 0x142:
; "CntIniFunc".
; -----------------------------------------------------------------------------
NakaInst_CntIniFunc:
	.incbin "includes/generated/naka_normal_mode.bin", 0x6C, 0xC
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_MainSysControl
; NakaInst_MainSysControl  --  naka_normal_mode +0x78..+0x88 (ROM 0xed33b4..0xed33c4), 16 bytes
; Name strings of element 10 of MainFunction slot 0x442 (table 0xed32e6,
; 20 entries, InitializeToshi), names for MainFunction slot 0x142:
; "MainSysControl".
; -----------------------------------------------------------------------------
NakaInst_MainSysControl:
	.incbin "includes/generated/naka_normal_mode.bin", 0x78, 0x10
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_OneTchFUNC
; NakaInst_OneTchFUNC  --  naka_normal_mode +0x88..+0x94 (ROM 0xed33c4..0xed33d0), 12 bytes
; Name strings of element 9 of MainFunction slot 0x442 (table 0xed32e6,
; 20 entries, InitializeToshi), names for MainFunction slot 0x142:
; "OneTchFUNC".
; -----------------------------------------------------------------------------
NakaInst_OneTchFUNC:
	.incbin "includes/generated/naka_normal_mode.bin", 0x88, 0xC
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_MainPmGet
; NakaInst_MainPmGet  --  naka_normal_mode +0x94..+0x9e (ROM 0xed33d0..0xed33da), 10 bytes
; Name strings of element 8 of MainFunction slot 0x442 (table 0xed32e6,
; 20 entries, InitializeToshi), names for MainFunction slot 0x142:
; "MainPmGet".
; -----------------------------------------------------------------------------
NakaInst_MainPmGet:
	.incbin "includes/generated/naka_normal_mode.bin", 0x94, 0xA
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_MainChordPre
; NakaInst_MainChordPre  --  naka_normal_mode +0x9e..+0xac (ROM 0xed33da..0xed33e8), 14 bytes
; Name strings of element 7 of MainFunction slot 0x442 (table 0xed32e6,
; 20 entries, InitializeToshi), names for MainFunction slot 0x142:
; "MainChordPre".
; -----------------------------------------------------------------------------
NakaInst_MainChordPre:
	.incbin "includes/generated/naka_normal_mode.bin", 0x9E, 0xE
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_MainGetRhyGrpName
; NakaInst_MainGetRhyGrpName  --  naka_normal_mode +0xac..+0xbe (ROM 0xed33e8..0xed33fa), 18 bytes
; Name strings of element 6 of MainFunction slot 0x442 (table 0xed32e6,
; 20 entries, InitializeToshi), names for MainFunction slot 0x142:
; "MainGetRhyGrpName".
; -----------------------------------------------------------------------------
NakaInst_MainGetRhyGrpName:
	.incbin "includes/generated/naka_normal_mode.bin", 0xAC, 0x12
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_MainGetSndGrpName
; NakaInst_MainGetSndGrpName  --  naka_normal_mode +0xbe..+0xd0 (ROM 0xed33fa..0xed340c), 18 bytes
; Name strings of element 5 of MainFunction slot 0x442 (table 0xed32e6,
; 20 entries, InitializeToshi), names for MainFunction slot 0x142:
; "MainGetSndGrpName".
; -----------------------------------------------------------------------------
NakaInst_MainGetSndGrpName:
	.incbin "includes/generated/naka_normal_mode.bin", 0xBE, 0x12
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_MainGetRhyName
; NakaInst_MainGetRhyName  --  naka_normal_mode +0xd0..+0xe0 (ROM 0xed340c..0xed341c), 16 bytes
; Name strings of element 4 of MainFunction slot 0x442 (table 0xed32e6,
; 20 entries, InitializeToshi), names for MainFunction slot 0x142:
; "MainGetRhyName".
; -----------------------------------------------------------------------------
NakaInst_MainGetRhyName:
	.incbin "includes/generated/naka_normal_mode.bin", 0xD0, 0x10
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_MainRvariIni
; NakaInst_MainRvariIni  --  naka_normal_mode +0xe0..+0xee (ROM 0xed341c..0xed342a), 14 bytes
; Name strings of element 3 of MainFunction slot 0x442 (table 0xed32e6,
; 20 entries, InitializeToshi), names for MainFunction slot 0x142:
; "MainRvariIni".
; -----------------------------------------------------------------------------
NakaInst_MainRvariIni:
	.incbin "includes/generated/naka_normal_mode.bin", 0xE0, 0xE
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_MainGetSndName
; NakaInst_MainGetSndName  --  naka_normal_mode +0xee..+0xfe (ROM 0xed342a..0xed343a), 16 bytes
; Name strings of element 2 of MainFunction slot 0x442 (table 0xed32e6,
; 20 entries, InitializeToshi), names for MainFunction slot 0x142:
; "MainGetSndName".
; -----------------------------------------------------------------------------
NakaInst_MainGetSndName:
	.incbin "includes/generated/naka_normal_mode.bin", 0xEE, 0x10
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_MainSvariIni
; NakaInst_MainSvariIni  --  naka_normal_mode +0xfe..+0x10c (ROM 0xed343a..0xed3448), 14 bytes
; Name strings of element 1 of MainFunction slot 0x442 (table 0xed32e6,
; 20 entries, InitializeToshi), names for MainFunction slot 0x142:
; "MainSvariIni".
; -----------------------------------------------------------------------------
NakaInst_MainSvariIni:
	.incbin "includes/generated/naka_normal_mode.bin", 0xFE, 0xE
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaInst_MainVariSet
; NakaInst_MainVariSet  --  naka_normal_mode +0x10c..+0x118 (ROM 0xed3448..0xed3454), 12 bytes
; Name strings of element 0 of MainFunction slot 0x442 (table 0xed32e6,
; 20 entries, InitializeToshi), names for MainFunction slot 0x142:
; "MainVariSet".
; -----------------------------------------------------------------------------
NakaInst_MainVariSet:
	.incbin "includes/generated/naka_normal_mode.bin", 0x10C, 0xC
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_normal_mode+0x118
; naka_normal_mode+0x118  --  naka_normal_mode +0x118..+0x490 (ROM 0xed3454..0xed37cc), 888 bytes
; Widget records of elements 0-24 of Viewable slot 0x1 (table 0xed77ce,
; 63 entries, InitializeToshi), element 0 "Normal"; classes: TtlScreen
; (42 B, id 0x01600034), NormScreen (42 B, id 0x01620000), AcTempoBox
; (36 B, id 0x01600014), AcPmemName (36 B, id 0x0160003b), AcRhythmName
; (36 B, id 0x0160003a), AcSoundName (38 B, id 0x0160002a) x3, StringBox
; (38 B, id 0x01600037) x4, TransposeBox (36 B, id 0x01620003), ChordBox
; (36 B, id 0x01620004), AcLswBox (44 B, id 0x01600013),
; IvWindowPageControl (26 B, id 0x0162000c), FreeSplitBox (36 B, id
; 0x01620005), IvPageOverWr (28 B, id 0x0162001b) x6, IvExit (22 B, id
; 0x01600047), Window (36 B, id 0x01600035).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_normal_mode.bin", 0x118, 0x378
; External label offsets within the binary blob above.
