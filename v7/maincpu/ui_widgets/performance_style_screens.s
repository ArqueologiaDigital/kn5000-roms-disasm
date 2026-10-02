
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
	.incbin "includes/generated/naka_perf_style.bin", 0x0, 0x2C
NakaWidget_ftdemobmptop:		.incbin "includes/generated/naka_perf_style.bin", 0x2C, 0x22
NakaWidget_ftdemo02:			.incbin "includes/generated/naka_perf_style.bin", 0x4E, 0x2C
NakaWidget_ftdemo01_3_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x7A, 0x1A
NakaWidget_ftdemo01_4_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x94, 0x1A
NakaWidget_ftdemo01_5_Label:		.incbin "includes/generated/naka_perf_style.bin", 0xAE, 0x2C
NakaWidget_ftdemo01_6_Label:		.incbin "includes/generated/naka_perf_style.bin", 0xDA, 0x2C
NakaWidget_ftdemo01_7_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x106, 0x1A
NakaWidget_ftdemo01_8_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x120, 0x2A
NakaWidget_ftdemo01_9_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x14A, 0x1A
NakaWidget_ftdemo01_10_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x164, 0x2C
NakaWidget_ftdemo01_11_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x190, 0x28
NakaWidget_ftdemo01_12_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x1B8, 0x1A
NakaWidget_ftdemo01_13_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x1D2, 0x1A
NakaWidget_ftdemo01_14_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x1EC, 0x1A
NakaWidget_ftdemo01_15_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x206, 0x24
NakaWidget_ftdemo01_16_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x22A, 0x1A
NakaWidget_ftdemo01_17_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x244, 0x1A
NakaWidget_ftdemo01_18_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x25E, 0x24
NakaWidget_ftdemo01_19_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x282, 0x1A
NakaWidget_ftdemo01_20_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x29C, 0x1A
NakaWidget_ftdemo01_21_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x2B6, 0x1A
NakaWidget_ftdemo01_22_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x2D0, 0x1A
NakaWidget_ftdemo01_23_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x2EA, 0x1A
NakaWidget_ftdemo01_24_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x304, 0x1A
NakaWidget_ftdemo01_25_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x31E, 0x1A
NakaWidget_ftdemo01_26_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x338, 0x24
NakaWidget_ftdemo01_27_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x35C, 0x1A
NakaWidget_ftdemo01_28_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x376, 0x1A
NakaWidget_ftdemo01_29_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x390, 0x24
NakaWidget_ftdemo01_30_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3B4, 0x24
NakaWidget_ftdemo01_31_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x3D8, 0x1A
NakaWidget_ftdemo01_32_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x3F2, 0x1A
NakaWidget_ftdemo01_33_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x40C, 0x24
NakaWidget_ftdemo01_34_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x430, 0x2A
NakaWidget_ftdemo01_35_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x45A, 0x2E
NakaWidget_ftdemo01_36_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x488, 0x2A
NakaWidget_ftdemo01_37_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x4B2, 0x24
NakaWidget_ftdemo01_38_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x4D6, 0x1A
NakaWidget_ftdemo01_39_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x4F0, 0x1A
NakaWidget_ftdemo01_40_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x50A, 0x1A
NakaWidget_ftdemo01_41_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x524, 0x1A
NakaWidget_ftdemo01_42_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x53E, 0x1A
NakaWidget_ftdemo01_43_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x558, 0x1A
NakaWidget_ftdemo01_44_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x572, 0x1A
NakaWidget_ftdemo01_45_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x58C, 0x1A
NakaWidget_ftdemo01_46_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x5A6, 0x1A
NakaWidget_ftdemo01_47_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x5C0, 0x1A
NakaWidget_ftdemo01_48_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x5DA, 0x1A
NakaWidget_ftdemo01_49_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x5F4, 0x1A
NakaWidget_ftdemo01_50_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x60E, 0x1A
NakaWidget_ftdemo01_51_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x628, 0x1A
NakaWidget_ftdemo01_52_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x642, 0x1A
NakaWidget_ftdemo01_53_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x65C, 0x1A
NakaWidget_ftdemo01_54_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x676, 0x1A
NakaWidget_ftdemo01_55_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x690, 0x1A
NakaWidget_ftdemo01_56_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x6AA, 0x1A
NakaWidget_ftdemo01_57_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x6C4, 0x1A
NakaWidget_ftdemo01_58_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x6DE, 0x1A
NakaWidget_ftdemo01_59_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x6F8, 0x1A
NakaWidget_ftdemo01_60_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x712, 0x1A
NakaWidget_ftdemo01_61_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x72C, 0x1A
NakaWidget_ftdemo01_62_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x746, 0x1A
NakaWidget_ftdemo01_63_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x760, 0x1A
NakaWidget_ftdemo01_64_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x77A, 0x1A
NakaWidget_ftdemo03:			.incbin "includes/generated/naka_perf_style.bin", 0x794, 0x2C
NakaWidget_ftdemo01_66_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x7C0, 0x1A
NakaWidget_ftdemo01_67_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x7DA, 0x2C
NakaWidget_ftdemo01_68_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x806, 0x1A
NakaWidget_ftdemo01_69_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x820, 0x2A
NakaWidget_ftdemo01_70_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x84A, 0x1A
NakaWidget_ftdemo01_71_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x864, 0x2C
NakaWidget_ftdemo01_72_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x890, 0x24
NakaWidget_ftdemo01_73_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x8B4, 0x1A
NakaWidget_ftdemo01_74_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x8CE, 0x1A
NakaWidget_ftdemo01_75_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x8E8, 0x1A
NakaWidget_ftdemo01_76_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x902, 0x1A
NakaWidget_ftdemo01_77_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x91C, 0x1A
NakaWidget_ftdemo01_78_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x936, 0x1A
NakaWidget_ftdemo01_79_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x950, 0x1A
NakaWidget_ftdemo01_80_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x96A, 0x1A
NakaWidget_ftdemo01_81_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x984, 0x1A
NakaWidget_ftdemo01_82_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x99E, 0x2E
NakaWidget_ftdemo01_83_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x9CC, 0x1A
NakaWidget_ftdemo01_84_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x9E6, 0x1A
NakaWidget_ftdemo01_85_Box:		.incbin "includes/generated/naka_perf_style.bin", 0xA00, 0x1A
NakaWidget_ftdemo01_86_Box:		.incbin "includes/generated/naka_perf_style.bin", 0xA1A, 0x1A
NakaWidget_ftdemo01_87_Box:		.incbin "includes/generated/naka_perf_style.bin", 0xA34, 0x1A
NakaWidget_ftdemo01_88_Box:		.incbin "includes/generated/naka_perf_style.bin", 0xA4E, 0x1A
NakaWidget_ftdemo01_89_Label:		.incbin "includes/generated/naka_perf_style.bin", 0xA68, 0x24
NakaWidget_ftdemo01_90_Box:		.incbin "includes/generated/naka_perf_style.bin", 0xA8C, 0x1A
NakaWidget_ftdemo01_91_Box:		.incbin "includes/generated/naka_perf_style.bin", 0xAA6, 0x1A
NakaWidget_ftdemo01_92_Box:		.incbin "includes/generated/naka_perf_style.bin", 0xAC0, 0x1A
NakaWidget_ftdemo01_93_Box:		.incbin "includes/generated/naka_perf_style.bin", 0xADA, 0x1A
NakaWidget_ftdemo01_94_Label:		.incbin "includes/generated/naka_perf_style.bin", 0xAF4, 0x24
NakaWidget_ftdemo01_95_Box:		.incbin "includes/generated/naka_perf_style.bin", 0xB18, 0x1A
NakaWidget_ftdemo01_96_Box:		.incbin "includes/generated/naka_perf_style.bin", 0xB32, 0x1A
NakaWidget_ftdemo01_97_Box:		.incbin "includes/generated/naka_perf_style.bin", 0xB4C, 0x1A
NakaWidget_ftdemo01_98_Box:		.incbin "includes/generated/naka_perf_style.bin", 0xB66, 0x1A
NakaWidget_ftdemo01_99_Label:		.incbin "includes/generated/naka_perf_style.bin", 0xB80, 0x24
NakaWidget_ftdemo01_100_Box:		.incbin "includes/generated/naka_perf_style.bin", 0xBA4, 0x1A
NakaWidget_ftdemo01_101_Box:		.incbin "includes/generated/naka_perf_style.bin", 0xBBE, 0x1A
NakaWidget_ftdemo01_102_Label:		.incbin "includes/generated/naka_perf_style.bin", 0xBD8, 0x24
NakaWidget_ftdemo01_103_Box:		.incbin "includes/generated/naka_perf_style.bin", 0xBFC, 0x1A
NakaWidget_ftdemo01_104_Box:		.incbin "includes/generated/naka_perf_style.bin", 0xC16, 0x1A
NakaWidget_ftdemo01_105_Label:		.incbin "includes/generated/naka_perf_style.bin", 0xC30, 0x24
NakaWidget_ftdemo01_106_Label:		.incbin "includes/generated/naka_perf_style.bin", 0xC54, 0x24
NakaWidget_ftdemo01_107_Label:		.incbin "includes/generated/naka_perf_style.bin", 0xC78, 0x2E
NakaWidget_ftdemo01_108_Label:		.incbin "includes/generated/naka_perf_style.bin", 0xCA6, 0x36
NakaWidget_ftdemo04:			.incbin "includes/generated/naka_perf_style.bin", 0xCDC, 0x2C
NakaWidget_ftdemobmp3D:			.incbin "includes/generated/naka_perf_style.bin", 0xD08, 0x22
NakaWidget_ftdemo01_111_AcLanguageText:	.incbin "includes/generated/naka_perf_style.bin", 0xD2A, 0x2A
NakaWidget_ftdemo01_112_Box:		.incbin "includes/generated/naka_perf_style.bin", 0xD54, 0x1A
NakaWidget_ftdemo01_113_AcLanguageText:	.incbin "includes/generated/naka_perf_style.bin", 0xD6E, 0x2A
NakaWidget_ftdemo01_114_AcLanguageText:	.incbin "includes/generated/naka_perf_style.bin", 0xD98, 0x2A
NakaWidget_ftdemo05:			.incbin "includes/generated/naka_perf_style.bin", 0xDC2, 0x2C
NakaWidget_ftdemo01_116_AcLanguageText:	.incbin "includes/generated/naka_perf_style.bin", 0xDEE, 0x2A
NakaWidget_ftdemo01_117_AcLanguageText:	.incbin "includes/generated/naka_perf_style.bin", 0xE18, 0x2A
NakaWidget_ftdemo06:			.incbin "includes/generated/naka_perf_style.bin", 0xE42, 0x2C
NakaWidget_ftdemo01_119_AcLanguageText:	.incbin "includes/generated/naka_perf_style.bin", 0xE6E, 0x2A
NakaWidget_ftdemobmpsoft:		.incbin "includes/generated/naka_perf_style.bin", 0xE98, 0x22
NakaWidget_ftdemo07:			.incbin "includes/generated/naka_perf_style.bin", 0xEBA, 0x2C
NakaWidget_ftdemobmpcnv:		.incbin "includes/generated/naka_perf_style.bin", 0xEE6, 0x22
NakaWidget_ftdemo01_123_AcLanguageText:	.incbin "includes/generated/naka_perf_style.bin", 0xF08, 0x2A
NakaWidget_ftdemo08:			.incbin "includes/generated/naka_perf_style.bin", 0xF32, 0x2C
NakaWidget_ftdemo01_125_AcLanguageText:	.incbin "includes/generated/naka_perf_style.bin", 0xF5E, 0x2A
NakaWidget_ftdemo09:			.incbin "includes/generated/naka_perf_style.bin", 0xF88, 0x2C
NakaWidget_ftdemo01_127_AcLanguageText:	.incbin "includes/generated/naka_perf_style.bin", 0xFB4, 0x2A
NakaWidget_ftdemo01_128_AcLanguageText:	.incbin "includes/generated/naka_perf_style.bin", 0xFDE, 0x2A
NakaWidget_ftdemo10:			.incbin "includes/generated/naka_perf_style.bin", 0x1008, 0x2C
NakaWidget_ftdemo01_130_AcLanguageText:	.incbin "includes/generated/naka_perf_style.bin", 0x1034, 0x2A
NakaWidget_ftdemo01_131_AcLanguageText:	.incbin "includes/generated/naka_perf_style.bin", 0x105E, 0x2A
NakaWidget_ftdemo20:			.incbin "includes/generated/naka_perf_style.bin", 0x1088, 0x2C
NakaWidget_ftdemo01_133_AcLanguageText:	.incbin "includes/generated/naka_perf_style.bin", 0x10B4, 0x2A
NakaWidget_ftdemo01_134_AcLanguageText:	.incbin "includes/generated/naka_perf_style.bin", 0x10DE, 0x2A
NakaWidget_ftdemobmpill:		.incbin "includes/generated/naka_perf_style.bin", 0x1108, 0x22
NakaWidget_ftdemo21:			.incbin "includes/generated/naka_perf_style.bin", 0x112A, 0x2C
NakaWidget_ftdemo01_137_AcLanguageText:	.incbin "includes/generated/naka_perf_style.bin", 0x1156, 0x2A
NakaWidget_ftdemo22:			.incbin "includes/generated/naka_perf_style.bin", 0x1180, 0x34
NakaWidget_ftdemo01_139_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x11B4, 0x1A
NakaWidget_ftdemo01_140_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x11CE, 0x38
NakaWidget_ftdemo01_141_PsEditSwBox:	.incbin "includes/generated/naka_perf_style.bin", 0x1206, 0x26
NakaWidget_ftdemo01_142_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x122C, 0x24
NakaWidget_ftdemo01_143_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1250, 0x24
NakaWidget_ftdemo01_144_EditSw:		.incbin "includes/generated/naka_perf_style.bin", 0x1274, 0x2C
NakaWidget_ftdemo01_145_EditSw:		.incbin "includes/generated/naka_perf_style.bin", 0x12A0, 0x2C
NakaWidget_ftdemo01_146_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x12CC, 0x26
NakaWidget_ftdemo01_147_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x12F2, 0x28
NakaWidget_ftdemo01_148_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x131A, 0x28
NakaWidget_ftdemo01_149_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1342, 0x28
NakaWidget_ftdemo01_150_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x136A, 0x1A
NakaWidget_ftdemo01_151_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1384, 0x32
NakaWidget_ftdemo01_152_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x13B6, 0x2E
NakaWidget_ftdemo01_153_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x13E4, 0x32
NakaWidget_ftdemo01_154_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1416, 0x30
NakaWidget_ftdemo01_155_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1446, 0x30
NakaWidget_ftdemo01_156_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1476, 0x34
NakaWidget_ftdemo01_157_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x14AA, 0x2C
NakaWidget_ftdemo01_158_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x14D6, 0x30
NakaWidget_ftdemo01_159_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1506, 0x26
NakaWidget_ftdemo01_160_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x152C, 0x1A
NakaWidget_ftdemo01_161_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1546, 0x2A
NakaWidget_ftdemo23:			.incbin "includes/generated/naka_perf_style.bin", 0x1570, 0x3C
NakaWidget_ftdemo01_163_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x15AC, 0x28
NakaWidget_ftdemo01_164_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x15D4, 0x24
NakaWidget_ftdemo01_165_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x15F8, 0x24
NakaWidget_ftdemo01_166_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x161C, 0x1A
NakaWidget_ftdemo01_167_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1636, 0x3C
NakaWidget_ftdemo01_168_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1672, 0x25
CDlikeSwTtl_SetRecordAndNotify_Data:	.incbin "includes/generated/naka_perf_style.bin", 0x1697, 0x1
NakaWidget_ftdemo01_169_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1698, 0x34
NakaWidget_ftdemo01_170_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x16CC, 0x40
NakaWidget_ftdemo01_171_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x170C, 0x30
NakaWidget_ftdemo01_172_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x173C, 0x30
NakaWidget_ftdemo01_173_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x176C, 0x22
NakaWidget_ftdemo01_174_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x178E, 0x26
NakaWidget_ftdemo01_175_VwEditSwBox:	.incbin "includes/generated/naka_perf_style.bin", 0x17B4, 0x2E
NakaWidget_ftdemo01_176_Bitmap:		.incbin "includes/generated/naka_perf_style.bin", 0x17E2, 0x1A
NakaWidget_ftdemo01_177_PsEditSwBox:	.incbin "includes/generated/naka_perf_style.bin", 0x17FC, 0x26
NakaWidget_ftdemo01_178_Bitmap:		.incbin "includes/generated/naka_perf_style.bin", 0x1822, 0x1A
NakaWidget_ftdemo01_179_PsEditSwBox:	.incbin "includes/generated/naka_perf_style.bin", 0x183C, 0x26
NakaWidget_ftdemo01_180_Bitmap:		.incbin "includes/generated/naka_perf_style.bin", 0x1862, 0x1A
NakaWidget_ftdemo01_181_VwEditSwBox:	.incbin "includes/generated/naka_perf_style.bin", 0x187C, 0x2E
NakaWidget_ftdemo01_182_Bitmap:		.incbin "includes/generated/naka_perf_style.bin", 0x18AA, 0x1A
NakaWidget_ftdemo01_183_VwEditSwBox:	.incbin "includes/generated/naka_perf_style.bin", 0x18C4, 0x2E
NakaWidget_ftdemo01_184_Bitmap:		.incbin "includes/generated/naka_perf_style.bin", 0x18F2, 0x1A
NakaWidget_ftdemo24:			.incbin "includes/generated/naka_perf_style.bin", 0x190C, 0x36
NakaWidget_ftdemo01_186_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x1942, 0x1A
NakaWidget_ftdemo01_187_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x195C, 0x1A
NakaWidget_ftdemo01_188_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1976, 0x38
NakaWidget_ftdemo01_189_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x19AE, 0x2E
NakaWidget_ftdemo01_190_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x19DC, 0x38
NakaWidget_ftdemo01_191_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1A14, 0x2E
NakaWidget_ftdemo01_192_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1A42, 0x38
NakaWidget_ftdemo01_193_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1A7A, 0x38
NakaWidget_ftdemo01_194_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1AB2, 0x38
NakaWidget_ftdemo01_195_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1AEA, 0x38
NakaWidget_ftdemo01_196_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x1B22, 0x1A
NakaWidget_ftdemo01_197_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1B3C, 0x26
NakaWidget_ftdemo01_198_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1B62, 0x24
NakaWidget_ftdemo01_199_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1B86, 0x24
NakaWidget_ftdemo01_200_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1BAA, 0x24
NakaWidget_ftdemo01_201_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1BCE, 0x24
NakaWidget_ftdemo01_202_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1BF2, 0x24
NakaWidget_ftdemo01_203_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1C16, 0x2A
NakaWidget_ftdemo01_204_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1C40, 0x2C
NakaWidget_ftdemo01_205_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1C6C, 0x2C
NakaWidget_ftdemo01_206_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1C98, 0x28
NakaWidget_ftdemo01_207_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1CC0, 0x26
NakaWidget_ftdemo01_208_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1CE6, 0x2A
NakaWidget_ftdemo01_209_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x1D10, 0x1A
NakaWidget_ftdemo01_210_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1D2A, 0x2E
NakaWidget_ftdemo01_211_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x1D58, 0x1A
NakaWidget_ftdemo01_212_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1D72, 0x26
NakaWidget_ftdemo01_213_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x1D98, 0x1A
NakaWidget_ftdemo01_214_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1DB2, 0x24
NakaWidget_ftdemo01_215_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x1DD6, 0x1A
NakaWidget_ftdemo01_216_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1DF0, 0x24
NakaWidget_ftdemo01_217_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x1E14, 0x1A
NakaWidget_ftdemo01_218_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1E2E, 0x24
NakaWidget_ftdemo01_219_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x1E52, 0x1A
NakaWidget_ftdemo01_220_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1E6C, 0x24
NakaWidget_ftdemo01_221_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1E90, 0x26
NakaWidget_ftdemo01_222_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1EB6, 0x26
NakaWidget_ftdemo01_223_Frame:		.incbin "includes/generated/naka_perf_style.bin", 0x1EDC, 0x1C
NakaWidget_ftdemo25:			.incbin "includes/generated/naka_perf_style.bin", 0x1EF8, 0x2C
NakaWidget_ftdemobmpend:		.incbin "includes/generated/naka_perf_style.bin", 0x1F24, 0x22
NakaWidget_ftdemo26:			.incbin "includes/generated/naka_perf_style.bin", 0x1F46, 0x3E
NakaWidget_ftdemo01_227_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x1F84, 0x1A
NakaWidget_ftdemo01_228_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1F9E, 0x28
NakaWidget_ftdemo01_229_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1FC6, 0x36
NakaWidget_ftdemo01_230_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x1FFC, 0x2A
NakaWidget_ftdemo01_231_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2026, 0x40
NakaWidget_ftdemo01_232_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2066, 0x3C
NakaWidget_ftdemo01_233_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x20A2, 0x3C
NakaWidget_ftdemo01_234_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x20DE, 0x3C
NakaWidget_ftdemo01_235_Frame:		.incbin "includes/generated/naka_perf_style.bin", 0x211A, 0x1C
NakaWidget_ftdemo01_236_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x2136, 0x1A
NakaWidget_ftdemo01_237_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2150, 0x2A
NakaWidget_ftdemo01_238_PsEditSwBox:	.incbin "includes/generated/naka_perf_style.bin", 0x217A, 0x26
NakaWidget_ftdemo01_239_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x21A0, 0x24
NakaWidget_ftdemo01_240_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x21C4, 0x24
NakaWidget_ftdemo01_241_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x21E8, 0x1A
NakaWidget_ftdemo01_242_PsEditSwBox:	.incbin "includes/generated/naka_perf_style.bin", 0x2202, 0x26
NakaWidget_ftdemo01_243_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2228, 0x24
NakaWidget_ftdemo01_244_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x224C, 0x24
NakaWidget_ftdemo01_245_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x2270, 0x1A
NakaWidget_ftdemo40:			.incbin "includes/generated/naka_perf_style.bin", 0x228A, 0x2C
NakaWidget_ftdemo01_247_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x22B6, 0x1A
NakaWidget_ftdemo01_248_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x22D0, 0x1A
NakaWidget_ftdemo01_249_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x22EA, 0x2E
NakaWidget_ftdemo01_250_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2318, 0x44
NakaWidget_ftdemo01_251_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x235C, 0x3A
NakaWidget_ftdemo01_252_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2396, 0x3C
NakaWidget_ftdemo41:			.incbin "includes/generated/naka_perf_style.bin", 0x23D2, 0x3A
NakaWidget_ftdemo01_254_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x240C, 0x1A
NakaWidget_ftdemo01_255_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2426, 0x30
NakaWidget_ftdemo01_256_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2456, 0x2C
NakaWidget_ftdemo01_257_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2482, 0x2C
NakaWidget_ftdemo01_258_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x24AE, 0x2A
NakaWidget_ftdemo01_259_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x24D8, 0x32
NakaWidget_ftdemo01_260_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x250A, 0x2E
NakaWidget_ftdemo01_261_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2538, 0x30
NakaWidget_ftdemo01_262_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2568, 0x2C
NakaWidget_ftdemo01_263_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2594, 0x28
NakaWidget_ftdemo01_264_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x25BC, 0x2E
NakaWidget_ftdemo01_265_Frame:		.incbin "includes/generated/naka_perf_style.bin", 0x25EA, 0x1C
NakaWidget_ftdemo01_266_PsEditSwBox:	.incbin "includes/generated/naka_perf_style.bin", 0x2606, 0x26
NakaWidget_ftdemo01_267_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x262C, 0x24
NakaWidget_ftdemo01_268_PsEditSwBox:	.incbin "includes/generated/naka_perf_style.bin", 0x2650, 0x26
NakaWidget_ftdemo01_269_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2676, 0x24
NakaWidget_ftdemo01_270_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x269A, 0x24
NakaWidget_ftdemo01_271_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x26BE, 0x1A
NakaWidget_ftdemo01_272_PsEditSwBox:	.incbin "includes/generated/naka_perf_style.bin", 0x26D8, 0x26
NakaWidget_ftdemo01_273_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x26FE, 0x24
NakaWidget_ftdemo01_274_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2722, 0x24
NakaWidget_ftdemo01_275_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x2746, 0x1A
NakaWidget_ftdemo01_276_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2760, 0x2E
NakaWidget_ftdemo01_277_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x278E, 0x1A
NakaWidget_ftdemo01_278_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x27A8, 0x30
NakaWidget_ftdemo01_279_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x27D8, 0x2A
NakaWidget_ftdemo01_280_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2802, 0x32
NakaWidget_ftdemo01_281_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2834, 0x30
NakaWidget_ftdemo01_282_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2864, 0x30
NakaWidget_ftdemo01_283_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2894, 0x30
NakaWidget_ftdemo01_284_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x28C4, 0x2A
NakaWidget_ftdemo01_285_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x28EE, 0x2E
NakaWidget_ftdemo01_286_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x291C, 0x32
NakaWidget_ftdemo01_287_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x294E, 0x2A
NakaWidget_ftdemo01_288_Frame:		.incbin "includes/generated/naka_perf_style.bin", 0x2978, 0x1C
NakaWidget_ftdemo01_289_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2994, 0x2E
NakaWidget_ftdemo01_290_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x29C2, 0x24
NakaWidget_ftdemo42:			.incbin "includes/generated/naka_perf_style.bin", 0x29E6, 0x3A
NakaWidget_ftdemo01_292_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x2A20, 0x1A
NakaWidget_ftdemo01_293_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2A3A, 0x30
NakaWidget_ftdemo01_294_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2A6A, 0x2C
NakaWidget_ftdemo01_295_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2A96, 0x2C
NakaWidget_ftdemo01_296_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2AC2, 0x2A
NakaWidget_ftdemo01_297_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2AEC, 0x32
NakaWidget_ftdemo01_298_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2B1E, 0x2E
NakaWidget_ftdemo01_299_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2B4C, 0x30
NakaWidget_ftdemo01_300_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2B7C, 0x2C
NakaWidget_ftdemo01_301_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2BA8, 0x28
NakaWidget_ftdemo01_302_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2BD0, 0x2E
NakaWidget_ftdemo01_303_Frame:		.incbin "includes/generated/naka_perf_style.bin", 0x2BFE, 0x1C
NakaWidget_ftdemo01_304_PsEditSwBox:	.incbin "includes/generated/naka_perf_style.bin", 0x2C1A, 0x26
NakaWidget_ftdemo01_305_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2C40, 0x24
NakaWidget_ftdemo01_306_PsEditSwBox:	.incbin "includes/generated/naka_perf_style.bin", 0x2C64, 0x26
NakaWidget_ftdemo01_307_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2C8A, 0x24
NakaWidget_ftdemo01_308_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2CAE, 0x24
NakaWidget_ftdemo01_309_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x2CD2, 0x1A
NakaWidget_ftdemo01_310_PsEditSwBox:	.incbin "includes/generated/naka_perf_style.bin", 0x2CEC, 0x26
NakaWidget_ftdemo01_311_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2D12, 0x24
NakaWidget_ftdemo01_312_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2D36, 0x24
NakaWidget_ftdemo01_313_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x2D5A, 0x1A
NakaWidget_ftdemo01_314_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2D74, 0x2E
NakaWidget_ftdemo01_315_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x2DA2, 0x1A
NakaWidget_ftdemo01_316_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2DBC, 0x30
NakaWidget_ftdemo01_317_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2DEC, 0x2A
NakaWidget_ftdemo01_318_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2E16, 0x32
NakaWidget_ftdemo01_319_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2E48, 0x30
NakaWidget_ftdemo01_320_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2E78, 0x30
NakaWidget_ftdemo01_321_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2EA8, 0x30
NakaWidget_ftdemo01_322_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2ED8, 0x2A
NakaWidget_ftdemo01_323_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2F02, 0x2E
NakaWidget_ftdemo01_324_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2F30, 0x32
NakaWidget_ftdemo01_325_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2F62, 0x2A
NakaWidget_ftdemo01_326_Frame:		.incbin "includes/generated/naka_perf_style.bin", 0x2F8C, 0x1C
NakaWidget_ftdemo01_327_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2FA8, 0x2E
NakaWidget_ftdemo01_328_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x2FD6, 0x24
NakaWidget_ftdemo44:			.incbin "includes/generated/naka_perf_style.bin", 0x2FFA, 0x3A
NakaWidget_ftdemo01_330_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x3034, 0x1A
NakaWidget_ftdemo01_331_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x304E, 0x46
NakaWidget_ftdemo01_332_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3094, 0x40
NakaWidget_ftdemo01_333_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x30D4, 0x40
NakaWidget_ftdemo01_334_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3114, 0x40
NakaWidget_ftdemo01_335_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3154, 0x40
NakaWidget_ftdemo01_336_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3194, 0x46
NakaWidget_ftdemo01_337_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x31DA, 0x40
NakaWidget_ftdemo01_338_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x321A, 0x40
NakaWidget_ftdemo01_339_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x325A, 0x40
NakaWidget_ftdemo01_340_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x329A, 0x40
NakaWidget_ftdemo01_341_Frame:		.incbin "includes/generated/naka_perf_style.bin", 0x32DA, 0x1C
NakaWidget_ftdemo01_342_PsEditSwBox:	.incbin "includes/generated/naka_perf_style.bin", 0x32F6, 0x26
NakaWidget_ftdemo01_343_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x331C, 0x26
NakaWidget_ftdemo01_344_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3342, 0x24
NakaWidget_ftdemo01_345_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3366, 0x24
NakaWidget_ftdemo01_346_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x338A, 0x1A
NakaWidget_ftdemo01_347_PsEditSwBox:	.incbin "includes/generated/naka_perf_style.bin", 0x33A4, 0x26
NakaWidget_ftdemo01_348_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x33CA, 0x24
NakaWidget_ftdemo01_349_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x33EE, 0x24
NakaWidget_ftdemo01_350_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x3412, 0x1A
NakaWidget_ftdemo01_351_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x342C, 0x36
NakaWidget_ftdemo45:			.incbin "includes/generated/naka_perf_style.bin", 0x3462, 0x3A
NakaWidget_ftdemo01_353_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x349C, 0x1A
NakaWidget_ftdemo01_354_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x34B6, 0x46
NakaWidget_ftdemo01_355_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x34FC, 0x40
NakaWidget_ftdemo01_356_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x353C, 0x40
NakaWidget_ftdemo01_357_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x357C, 0x40
NakaWidget_ftdemo01_358_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x35BC, 0x40
NakaWidget_ftdemo01_359_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x35FC, 0x46
NakaWidget_ftdemo01_360_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3642, 0x40
NakaWidget_ftdemo01_361_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3682, 0x40
NakaWidget_ftdemo01_362_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x36C2, 0x40
NakaWidget_ftdemo01_363_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3702, 0x40
NakaWidget_ftdemo01_364_Frame:		.incbin "includes/generated/naka_perf_style.bin", 0x3742, 0x1C
NakaWidget_ftdemo01_365_PsEditSwBox:	.incbin "includes/generated/naka_perf_style.bin", 0x375E, 0x26
NakaWidget_ftdemo01_366_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3784, 0x26
NakaWidget_ftdemo01_367_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x37AA, 0x24
NakaWidget_ftdemo01_368_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x37CE, 0x24
NakaWidget_ftdemo01_369_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x37F2, 0x1A
NakaWidget_ftdemo01_370_PsEditSwBox:	.incbin "includes/generated/naka_perf_style.bin", 0x380C, 0x26
NakaWidget_ftdemo01_371_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3832, 0x24
NakaWidget_ftdemo01_372_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3856, 0x24
NakaWidget_ftdemo01_373_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x387A, 0x1A
NakaWidget_ftdemo01_374_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3894, 0x36
NakaWidget_ftdemo46:			.incbin "includes/generated/naka_perf_style.bin", 0x38CA, 0x40
NakaWidget_ftdemo01_376_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x390A, 0x1A
NakaWidget_ftdemo01_377_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3924, 0x44
NakaWidget_ftdemo01_378_Frame:		.incbin "includes/generated/naka_perf_style.bin", 0x3968, 0x1C
NakaWidget_ftdemo01_379_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3984, 0x40
NakaWidget_ftdemo01_380_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x39C4, 0x40
NakaWidget_ftdemo01_381_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3A04, 0x40
NakaWidget_ftdemo01_382_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3A44, 0x40
NakaWidget_ftdemo01_383_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3A84, 0x40
NakaWidget_ftdemo01_384_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3AC4, 0x40
NakaWidget_ftdemo01_385_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3B04, 0x40
NakaWidget_ftdemo01_386_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3B44, 0x40
NakaWidget_ftdemo01_387_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3B84, 0x40
NakaWidget_ftdemo01_388_PsEditSwBox:	.incbin "includes/generated/naka_perf_style.bin", 0x3BC4, 0x26
NakaWidget_ftdemo01_389_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3BEA, 0x24
NakaWidget_ftdemo01_390_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3C0E, 0x24
NakaWidget_ftdemo01_391_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3C32, 0x24
NakaWidget_ftdemo01_392_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x3C56, 0x1A
NakaWidget_ftdemo01_393_PsEditSwBox:	.incbin "includes/generated/naka_perf_style.bin", 0x3C70, 0x26
NakaWidget_ftdemo01_394_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3C96, 0x26
NakaWidget_ftdemo01_395_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3CBC, 0x24
NakaWidget_ftdemo01_396_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3CE0, 0x24
NakaWidget_ftdemo01_397_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x3D04, 0x1A
NakaWidget_ftdemo47:			.incbin "includes/generated/naka_perf_style.bin", 0x3D1E, 0x40
NakaWidget_ftdemo01_399_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x3D5E, 0x1A
NakaWidget_ftdemo01_400_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3D78, 0x44
NakaWidget_ftdemo01_401_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3DBC, 0x40
NakaWidget_ftdemo01_402_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3DFC, 0x40
NakaWidget_ftdemo01_403_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3E3C, 0x40
NakaWidget_ftdemo01_404_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3E7C, 0x40
NakaWidget_ftdemo01_405_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3EBC, 0x40
NakaWidget_ftdemo01_406_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3EFC, 0x40
NakaWidget_ftdemo01_407_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3F3C, 0x40
NakaWidget_ftdemo01_408_Frame:		.incbin "includes/generated/naka_perf_style.bin", 0x3F7C, 0x1C
NakaWidget_ftdemo01_409_PsEditSwBox:	.incbin "includes/generated/naka_perf_style.bin", 0x3F98, 0x26
NakaWidget_ftdemo01_410_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3FBE, 0x24
NakaWidget_ftdemo01_411_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x3FE2, 0x24
NakaWidget_ftdemo01_412_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x4006, 0x24
NakaWidget_ftdemo01_413_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x402A, 0x1A
NakaWidget_ftdemo01_414_PsEditSwBox:	.incbin "includes/generated/naka_perf_style.bin", 0x4044, 0x26
NakaWidget_ftdemo01_415_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x406A, 0x26
NakaWidget_ftdemo01_416_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x4090, 0x24
NakaWidget_ftdemo01_417_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x40B4, 0x24
NakaWidget_ftdemo01_418_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x40D8, 0x1A
NakaWidget_ftdemo48:			.incbin "includes/generated/naka_perf_style.bin", 0x40F2, 0x40
NakaWidget_ftdemo01_420_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x4132, 0x1A
NakaWidget_ftdemo01_421_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x414C, 0x44
NakaWidget_ftdemo01_422_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x4190, 0x40
NakaWidget_ftdemo01_423_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x41D0, 0x40
NakaWidget_ftdemo01_424_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x4210, 0x40
NakaWidget_ftdemo01_425_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x4250, 0x40
NakaWidget_ftdemo01_426_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x4290, 0x40
NakaWidget_ftdemo01_427_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x42D0, 0x40
NakaWidget_ftdemo01_428_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x4310, 0x40
NakaWidget_ftdemo01_429_Frame:		.incbin "includes/generated/naka_perf_style.bin", 0x4350, 0x1C
NakaWidget_ftdemo01_430_PsEditSwBox:	.incbin "includes/generated/naka_perf_style.bin", 0x436C, 0x26
NakaWidget_ftdemo01_431_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x4392, 0x24
NakaWidget_ftdemo01_432_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x43B6, 0x24
NakaWidget_ftdemo01_433_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x43DA, 0x24
NakaWidget_ftdemo01_434_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x43FE, 0x1A
NakaWidget_ftdemo01_435_PsEditSwBox:	.incbin "includes/generated/naka_perf_style.bin", 0x4418, 0x26
NakaWidget_ftdemo01_436_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x443E, 0x26
NakaWidget_ftdemo01_437_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x4464, 0x24
NakaWidget_ftdemo01_438_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x4488, 0x24
NakaWidget_ftdemo01_439_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x44AC, 0x1A
NakaWidget_ftdemo43:			.incbin "includes/generated/naka_perf_style.bin", 0x44C6, 0x3A
NakaWidget_ftdemo01_441_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x4500, 0x1A
NakaWidget_ftdemo01_442_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x451A, 0x30
NakaWidget_ftdemo01_443_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x454A, 0x2C
NakaWidget_ftdemo01_444_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x4576, 0x2C
NakaWidget_ftdemo01_445_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x45A2, 0x2A
NakaWidget_ftdemo01_446_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x45CC, 0x32
NakaWidget_ftdemo01_447_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x45FE, 0x2E
NakaWidget_ftdemo01_448_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x462C, 0x30
NakaWidget_ftdemo01_449_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x465C, 0x2C
NakaWidget_ftdemo01_450_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x4688, 0x28
NakaWidget_ftdemo01_451_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x46B0, 0x2E
NakaWidget_ftdemo01_452_Frame:		.incbin "includes/generated/naka_perf_style.bin", 0x46DE, 0x1C
NakaWidget_ftdemo01_453_PsEditSwBox:	.incbin "includes/generated/naka_perf_style.bin", 0x46FA, 0x26
NakaWidget_ftdemo01_454_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x4720, 0x24
NakaWidget_ftdemo01_455_PsEditSwBox:	.incbin "includes/generated/naka_perf_style.bin", 0x4744, 0x26
NakaWidget_ftdemo01_456_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x476A, 0x24
NakaWidget_ftdemo01_457_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x478E, 0x24
NakaWidget_ftdemo01_458_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x47B2, 0x1A
NakaWidget_ftdemo01_459_PsEditSwBox:	.incbin "includes/generated/naka_perf_style.bin", 0x47CC, 0x26
NakaWidget_ftdemo01_460_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x47F2, 0x24
NakaWidget_ftdemo01_461_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x4816, 0x24
NakaWidget_ftdemo01_462_Line:		.incbin "includes/generated/naka_perf_style.bin", 0x483A, 0x1A
NakaWidget_ftdemo01_463_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x4854, 0x2E
NakaWidget_ftdemo01_464_Box:		.incbin "includes/generated/naka_perf_style.bin", 0x4882, 0x1A
NakaWidget_ftdemo01_465_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x489C, 0x30
NakaWidget_ftdemo01_466_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x48CC, 0x2A
NakaWidget_ftdemo01_467_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x48F6, 0x32
NakaWidget_ftdemo01_468_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x4928, 0x30
NakaWidget_ftdemo01_469_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x4958, 0x30
NakaWidget_ftdemo01_470_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x4988, 0x30
NakaWidget_ftdemo01_471_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x49B8, 0x2A
NakaWidget_ftdemo01_472_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x49E2, 0x2E
NakaWidget_ftdemo01_473_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x4A10, 0x32
NakaWidget_ftdemo01_474_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x4A42, 0x2A
NakaWidget_ftdemo01_475_Frame:		.incbin "includes/generated/naka_perf_style.bin", 0x4A6C, 0x1C
NakaWidget_ftdemo01_476_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x4A88, 0x2E
NakaWidget_ftdemo01_477_Label:		.incbin "includes/generated/naka_perf_style.bin", 0x4AB6, 0x24
; [nakarest] NAKA_UIObjectTable  +0x4ada..+0x5256 (0xe1344e, 1916 B)
; [nakarest] the table itself: Viewable slot 0xfd (table 0xe1344e, 478 entries, InitializeNaka),
; [nakarest] 478 entry pointers x 4 bytes.
NAKA_UIObjectTable:
	.incbin "includes/generated/naka_perf_style.bin", 0x4ADA, 0x77C
; [nakarest] naka_perf_style+0x5256  +0x5256..+0x59d4 (0xe13bca, 1918 B)
; [nakarest] the table itself: ResName slot 0x3fd (table 0xe13bca, 478 entries, InitializeNaka),
; [nakarest] 478 entry pointers x 4 bytes.
Naka_ResNameTable_3FD:
	.incbin "includes/generated/naka_perf_style.bin", 0x5256, 0x77E
; [nakarest] naka_perf_style+0x59d4  +0x59d4..+0x5eb0 (0xe14348, 1244 B)
; [nakarest] name strings, entries 0-477 of ResName slot 0x3fd (table 0xe13bca, 478 entries,
; [nakarest] InitializeNaka) (names for Viewable slot 0xfd): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_perf_style.bin", 0x59D4, 0x4D2
InitializeNaka_Str_TT_FDMSP:	.incbin "includes/generated/naka_perf_style.bin", 0x5EA6, 0xA	; "TT_FDMSP"
; [nakarest] naka_perf_style+0x5eb0  +0x5eb0..+0x5eb4 (0xe14824, 4 B)
; [nakarest] the table itself: MainFunction slot 0x14b (table 0xe14824, 0 entries,
; [nakarest] InitializeNaka), 0 entry pointers x 4 bytes.
Naka_MainFunctionTable_14B:
	.incbin "includes/generated/naka_perf_style.bin", 0x5EB0, 0x4
; [nakarest] naka_perf_style+0x5eb4  +0x5eb4..+0x5eba (0xe14828, 6 B)
; [nakarest] the table itself: MainFunction slot 0x44b (table 0xe14828, 0 entries,
; [nakarest] InitializeNaka), 0 entry pointers x 4 bytes.
Naka_MainFunctionTable_44B:
	.incbin "includes/generated/naka_perf_style.bin", 0x5EB4, 0x6
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
NAKA_InitDataBlock_PtrTable_5:	.incbin "includes/generated/naka_perf_style.bin", 0x61D6, 0xE8	; 6 x 32-bit pointer
NakaUI_ObjectTable_End:		.incbin "includes/generated/naka_perf_style.bin", 0x62BE, 0x54
LongStr_Explore_1000_Musical:	.incbin "includes/generated/naka_perf_style.bin", 0x6312, 0x34
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
