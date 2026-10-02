
; Technichord Part Settings screen widgets (221 widgets, 17024 bytes)
; Source: maincpu/ui_widgets/naka_technichord_part.c (C struct with named fields)
; -----------------------------------------------------------------------------
; [nakarest_retype] registered NAKA tables: naka_technichord_part
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
; Viewable slot 0x2: RegObjTabl 0x1600010, ViewableProc, 0x14, 0xe85470,
; 0x2 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 20, table} at 0x27ed2 +
; 14*0x2. Element 0 is named "Sdmenu" in ResName slot 0x302. Links: all
; 20 records consistent.
;
; Viewable slot 0x3: RegObjTabl 0x1600010, ViewableProc, 0x54, 0xe854c4,
; 0x3 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 84, table} at 0x27ed2 +
; 14*0x3. Element 0 is named "Sdpart" in ResName slot 0x303. Links: all
; 84 records consistent.
;
; Viewable slot 0x4: RegObjTabl 0x1600010, ViewableProc, 0x4, 0xe85618,
; 0x4 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 4, table} at 0x27ed2 +
; 14*0x4. Element 0 is named "Sdmtune" in ResName slot 0x304. Links: all
; 4 records consistent.
;
; Viewable slot 0x5: RegObjTabl 0x1600010, ViewableProc, 0x36, 0xe8562c,
; 0x5 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 54, table} at 0x27ed2 +
; 14*0x5. Element 0 is named "Sdscltyp" in ResName slot 0x305. Links:
; all 54 records consistent.
;
; Viewable slot 0x7: RegObjTabl 0x1600010, ViewableProc, 0x3, 0xe85708,
; 0x7 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 3, table} at 0x27ed2 +
; 14*0x7. Element 0 is named "Sdlfthld" in ResName slot 0x307. Links:
; all 3 records consistent.
;
; Viewable slot 0x8: RegObjTabl 0x1600010, ViewableProc, 0x4, 0xe85718,
; 0x8 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 4, table} at 0x27ed2 +
; 14*0x8. Element 0 is named "Sdmixer" in ResName slot 0x308. Links: all
; 4 records consistent.
;
; Viewable slot 0xd: RegObjTabl 0x1600010, ViewableProc, 0x1d, 0xe8572c,
; 0xd in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 29, table} at 0x27ed2 +
; 14*0xd. Element 0 is named "Sdtecd" in ResName slot 0x30d. Links: all
; 29 records consistent.
;
; Viewable slot 0xa5: RegObjTabl 0x1600010, ViewableProc, 0x4, 0xe857a4,
; 0xa5 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 4, table} at 0x27ed2 +
; 14*0xa5. Element 0 is named "Sqmixer" in ResName slot 0x3a5. Links:
; all 4 records consistent.
;
; Viewable slot 0xe4: RegObjTabl 0x1600010, ViewableProc, 0xf, 0xe857b8,
; 0xe4 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 15, table} at 0x27ed2 +
; 14*0xe4. Element 0 is named "Demofeature" in ResName slot 0x3e4.
; Links: all 15 records consistent.
;
; Viewable slot 0xea: RegObjTabl 0x1600010, ViewableProc, 0x2c,
; 0xe857f8, 0xea in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 44, table} at 0x27ed2 +
; 14*0xea. Element 0 is named "Drawbar" in ResName slot 0x3ea. Links:
; all 44 records consistent.
;
; Viewable slot 0xeb: RegObjTabl 0x1600010, ViewableProc, 0x25,
; 0xe858ac, 0xeb in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 37, table} at 0x27ed2 +
; 14*0xeb. Element 0 is named "Accordion" in ResName slot 0x3eb. Links:
; all 37 records consistent.
;
; Viewable slot 0xee: RegObjTabl 0x1600010, ViewableProc, 0x18,
; 0xe85944, 0xee in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 24, table} at 0x27ed2 +
; 14*0xee. Element 0 is named "Mesage" in ResName slot 0x3ee. Links: all
; 24 records consistent.
;
; Viewable slot 0xef: RegObjTabl 0x1600010, ViewableProc, 0xb, 0xe859a8,
; 0xef in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 11, table} at 0x27ed2 +
; 14*0xef. Element 0 is named "Welcom" in ResName slot 0x3ef. Links: all
; 11 records consistent.
;
; Viewable slot 0xf0: RegObjTabl 0x1600010, ViewableProc, 0x6, 0xe859d8,
; 0xf0 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 6, table} at 0x27ed2 +
; 14*0xf0. Element 0 is named "Softver" in ResName slot 0x3f0. Links:
; all 6 records consistent.
;
; ResName slot 0x302: RegObjTabl 0x160000f, ResNameProc, 0x14, 0xe859f4,
; 0x302 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 20, table} at 0x27ed2 +
; 14*0x302.
;
; ResName slot 0x303: RegObjTabl 0x160000f, ResNameProc, 0x54, 0xe85a8e,
; 0x303 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 84, table} at 0x27ed2 +
; 14*0x303.
;
; ResName slot 0x304: RegObjTabl 0x160000f, ResNameProc, 0x4, 0xe85cf0,
; 0x304 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 4, table} at 0x27ed2 +
; 14*0x304.
;
; ResName slot 0x305: RegObjTabl 0x160000f, ResNameProc, 0x36, 0xe85d14,
; 0x305 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 54, table} at 0x27ed2 +
; 14*0x305.
;
; ResName slot 0x307: RegObjTabl 0x160000f, ResNameProc, 0x3, 0xe85f0a,
; 0x307 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 3, table} at 0x27ed2 +
; 14*0x307.
;
; ResName slot 0x308: RegObjTabl 0x160000f, ResNameProc, 0x4, 0xe85f2a,
; 0x308 in InitializeMurai (ui/drawbar_panel_ui.s), i.e.
; RegisterObjectTable stores {class, proc, 4, table} at 0x27ed2 +
; 14*0x308.
; -----------------------------------------------------------------------------

; [nakarest] NakaInst_TECHNI_CHORD  +0x0..+0xe (0xe81cce, 14 B)
; [nakarest] 1 text the records point at (Viewable slot 0x2 (table 0xe85470, 20 entries,
; [nakarest] InitializeMurai)): "TECHNI-CHORD" (AcTitleMenu.str of element 19).
NakaInst_TECHNI_CHORD:
	.incbin "includes/generated/naka_technichord_part.bin", 0x0, 0xE
; [nakarest] naka_technichord_part+0xe  +0xe..+0x1064 (0xe81cdc, 4182 B)
; [nakarest] widget records, elements 0-83 of Viewable slot 0x3 (table 0xe854c4, 84 entries,
; [nakarest] InitializeMurai) ("Sdpart"): TtlScreen (42 B), AcIndexEditSw (40 B) x10, Line (26
; [nakarest] B) x6, Label (32 B) x2, PsParaBox (36 B) x2, AcStrRadioBox (48 B) x8, VwEditSwBox
; [nakarest] (44 B) x8, IvSdpart (22 B), Window (36 B) x9, AcLswPartEditBox (58 B) x25, VwBox
; [nakarest] (28 B) x9, AcVolPartEditBox (62 B) x2, AcLswPartPan (36 B). 46 texts the records
; [nakarest] point at (Viewable slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai)): "SOUND
; [nakarest] PART SETTING" (TtlScreen.title of element 0); "PART SELECT :" (Label.str of element
; [nakarest] 9); "VOL" (AcStrRadioBox.str of element 12); "PAN" (AcStrRadioBox.str of element
; [nakarest] 13); ....
NakaWidget_Sdpart:			.incbin "includes/generated/naka_technichord_part.bin", 0xE, 0x3E
NakaWidget_Sdpart_1_AcIndexEditSw:	.incbin "includes/generated/naka_technichord_part.bin", 0x4C, 0x28
NakaWidget_Sdpart_2_AcIndexEditSw:	.incbin "includes/generated/naka_technichord_part.bin", 0x74, 0x28
NakaWidget_Sdpart_3_Line:		.incbin "includes/generated/naka_technichord_part.bin", 0x9C, 0x1A
NakaWidget_Sdpart_4_Line:		.incbin "includes/generated/naka_technichord_part.bin", 0xB6, 0x1A
NakaWidget_Sdpart_5_Line:		.incbin "includes/generated/naka_technichord_part.bin", 0xD0, 0x1A
NakaWidget_Sdpart_6_Line:		.incbin "includes/generated/naka_technichord_part.bin", 0xEA, 0x1A
NakaWidget_Sdpart_7_Line:		.incbin "includes/generated/naka_technichord_part.bin", 0x104, 0x1A
NakaWidget_Sdpart_8_Line:		.incbin "includes/generated/naka_technichord_part.bin", 0x11E, 0x1A
NakaWidget_Sdpart_9_Label:		.incbin "includes/generated/naka_technichord_part.bin", 0x138, 0x2E
NakaWidget_SdpartSound:			.incbin "includes/generated/naka_technichord_part.bin", 0x166, 0x24
NakaWidget_SdpartPart:			.incbin "includes/generated/naka_technichord_part.bin", 0x18A, 0x24
NakaWidget_Sdpart_12_AcStrRadioBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x1AE, 0x34
NakaWidget_Sdpart_13_AcStrRadioBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x1E2, 0x34
NakaWidget_Sdpart_14_AcStrRadioBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x216, 0x34
NakaWidget_Sdpart_15_AcStrRadioBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x24A, 0x34
NakaWidget_Sdpart_16_AcStrRadioBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x27E, 0x34
NakaWidget_Sdpart_17_AcStrRadioBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x2B2, 0x34
NakaWidget_Sdpart_18_AcStrRadioBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x2E6, 0x34
NakaWidget_Sdpart_19_AcStrRadioBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x31A, 0x34
NakaWidget_Sdpart_20_VwEditSwBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x34E, 0x2E
NakaWidget_Sdpart_21_VwEditSwBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x37C, 0x2E
NakaWidget_Sdpart_22_VwEditSwBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x3AA, 0x2E
NakaWidget_Sdpart_23_VwEditSwBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x3D8, 0x2E
NakaWidget_Sdpart_24_VwEditSwBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x406, 0x2E
NakaWidget_Sdpart_25_VwEditSwBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x434, 0x2E
NakaWidget_Sdpart_26_VwEditSwBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x462, 0x2E
NakaWidget_Sdpart_27_VwEditSwBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x490, 0x2E
NakaWidget_Sdpart_28_IvSdpart:		.incbin "includes/generated/naka_technichord_part.bin", 0x4BE, 0x16
NakaWidget_SdpartMain:			.incbin "includes/generated/naka_technichord_part.bin", 0x4D4, 0x24
NakaWidget_Sdpart_30_AcLswPartEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x4F8, 0x48
NakaWidget_Sdpart_31_AcLswPartEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x540, 0x48
NakaWidget_Sdpart_32_AcLswPartEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x588, 0x48
NakaWidget_Sdpart_33_AcLswPartEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x5D0, 0x48
NakaWidget_Sdpart_34_AcLswPartEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x618, 0x48
NakaWidget_Sdpart_35_VwBox:		.incbin "includes/generated/naka_technichord_part.bin", 0x660, 0x1C
NakaWidget_Sdpart_36_AcLswPartEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x67C, 0x48
NakaWidget_Sdpart_37_AcLswPartEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x6C4, 0x48
NakaWidget_Sdpart_38_AcLswPartEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x70C, 0x48
NakaWidget_Sdpart_39_AcLswPartEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x754, 0x48
NakaWidget_Sdpart_40_AcLswPartEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x79C, 0x48
NakaWidget_Sdpart_41_AcLswPartEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x7E4, 0x48
NakaWidget_Sdpart_42_AcVolPartEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x82C, 0x4C
NakaWidget_SdpartVol:			.incbin "includes/generated/naka_technichord_part.bin", 0x878, 0x24
NakaWidget_Sdpart_44_AcIndexEditSw:	.incbin "includes/generated/naka_technichord_part.bin", 0x89C, 0x28
NakaWidget_Sdpart_45_VwBox:		.incbin "includes/generated/naka_technichord_part.bin", 0x8C4, 0x1C
NakaWidget_Sdpart_46_AcVolPartEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x8E0, 0x4E
NakaWidget_SdpartPan:			.incbin "includes/generated/naka_technichord_part.bin", 0x92E, 0x24
NakaWidget_Sdpart_48_VwBox:		.incbin "includes/generated/naka_technichord_part.bin", 0x952, 0x1C
NakaWidget_Sdpart_49_AcLswPartEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x96E, 0x40
NakaWidget_Sdpart_50_Label:		.incbin "includes/generated/naka_technichord_part.bin", 0x9AE, 0x3C
NakaWidget_Sdpart_51_AcLswPartPan:	.incbin "includes/generated/naka_technichord_part.bin", 0x9EA, 0x24
NakaWidget_Sdpart_52_AcIndexEditSw:	.incbin "includes/generated/naka_technichord_part.bin", 0xA0E, 0x28
NakaWidget_Sdpart_53_VwBox:		.incbin "includes/generated/naka_technichord_part.bin", 0xA36, 0x1C
NakaWidget_SdpartEff:			.incbin "includes/generated/naka_technichord_part.bin", 0xA52, 0x24
NakaWidget_Sdpart_55_AcLswPartEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0xA76, 0x48
NakaWidget_Sdpart_56_AcLswPartEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0xABE, 0x48
NakaWidget_Sdpart_57_AcLswPartEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0xB06, 0x48
NakaWidget_Sdpart_58_AcIndexEditSw:	.incbin "includes/generated/naka_technichord_part.bin", 0xB4E, 0x28
NakaWidget_Sdpart_59_VwBox:		.incbin "includes/generated/naka_technichord_part.bin", 0xB76, 0x1C
NakaWidget_SdpartSus:			.incbin "includes/generated/naka_technichord_part.bin", 0xB92, 0x24
NakaWidget_Sdpart_61_AcIndexEditSw:	.incbin "includes/generated/naka_technichord_part.bin", 0xBB6, 0x28
NakaWidget_Sdpart_62_AcLswPartEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0xBDE, 0x4E
NakaWidget_Sdpart_63_AcLswPartEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0xC2C, 0x4E
NakaWidget_Sdpart_64_VwBox:		.incbin "includes/generated/naka_technichord_part.bin", 0xC7A, 0x1C
NakaWidget_SdpartKey:			.incbin "includes/generated/naka_technichord_part.bin", 0xC96, 0x24
NakaWidget_Sdpart_66_AcLswPartEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0xCBA, 0x4A
NakaWidget_Sdpart_67_AcIndexEditSw:	.incbin "includes/generated/naka_technichord_part.bin", 0xD04, 0x28
NakaWidget_Sdpart_68_VwBox:		.incbin "includes/generated/naka_technichord_part.bin", 0xD2C, 0x1C
NakaWidget_SdpartTun:			.incbin "includes/generated/naka_technichord_part.bin", 0xD48, 0x24
NakaWidget_Sdpart_70_AcLswPartEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0xD6C, 0x4A
NakaWidget_Sdpart_71_AcIndexEditSw:	.incbin "includes/generated/naka_technichord_part.bin", 0xDB6, 0x28
NakaWidget_Sdpart_72_VwBox:		.incbin "includes/generated/naka_technichord_part.bin", 0xDDE, 0x1C
NakaWidget_SdpartBnd:			.incbin "includes/generated/naka_technichord_part.bin", 0xDFA, 0x24
NakaWidget_Sdpart_74_AcLswPartEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0xE1E, 0x4E
NakaWidget_Sdpart_75_AcIndexEditSw:	.incbin "includes/generated/naka_technichord_part.bin", 0xE6C, 0x28
NakaWidget_Sdpart_76_VwBox:		.incbin "includes/generated/naka_technichord_part.bin", 0xE94, 0x1C
NakaWidget_SdpartOth:			.incbin "includes/generated/naka_technichord_part.bin", 0xEB0, 0x24
NakaWidget_Sdpart_78_AcLswPartEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0xED4, 0x48
NakaWidget_Sdpart_79_AcLswPartEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0xF1C, 0x48
NakaWidget_Sdpart_80_AcLswPartEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0xF64, 0x48
NakaWidget_Sdpart_81_AcIndexEditSw:	.incbin "includes/generated/naka_technichord_part.bin", 0xFAC, 0x28
NakaWidget_Sdpart_82_AcLswPartEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0xFD4, 0x48
NakaWidget_Sdpart_83_AcLswPartEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x101C, 0x48
; [nakarest] naka_technichord_part+0x1064  +0x1064..+0x1132 (0xe82d32, 206 B)
; [nakarest] widget records, elements 0-3 of Viewable slot 0x4 (table 0xe85618, 4 entries,
; [nakarest] InitializeMurai) ("Sdmtune"): TtlScreen (42 B), AcLswEditBox (58 B), Label (32 B),
; [nakarest] AcIndexWideES (42 B). 3 texts the records point at (Viewable slot 0x4 (table
; [nakarest] 0xe85618, 4 entries, InitializeMurai)): "MASTER TUNING" (TtlScreen.title of element
; [nakarest] 0); "MASTER TUNING :" (AcLswEditBox.caption of element 1); "Hz" (Label.str of
; [nakarest] element 2).
NakaWidget_Sdmtune:			.incbin "includes/generated/naka_technichord_part.bin", 0x1064, 0x38
NakaWidget_Sdmtune_1_AcLswEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x109C, 0x4C
NakaWidget_Sdmtune_2_Label:		.incbin "includes/generated/naka_technichord_part.bin", 0x10E8, 0x24
NakaWidget_Sdmtune_3_AcIndexWideES:	.incbin "includes/generated/naka_technichord_part.bin", 0x110C, 0x26
; [nakarest] Naka_KeyScaling_NavTrail  +0x1132..+0x1136 (0xe82e00, 4 B)
; [nakarest] Continues widget record, element 3 of Viewable slot 0x4 (table 0xe85618, 4 entries,
; [nakarest] InitializeMurai) ("Sdmtune"): AcIndexWideES (42 B) (starts 0xe82dda, 4 of its 42
; [nakarest] bytes are here or later).
Naka_KeyScaling_NavTrail:
	.incbin "includes/generated/naka_technichord_part.bin", 0x1132, 0x4
; [nakarest] naka_technichord_part+0x1136  +0x1136..+0x1996 (0xe82e04, 2144 B)
; [nakarest] widget records, elements 0-53 of Viewable slot 0x5 (table 0xe8562c, 54 entries,
; [nakarest] InitializeMurai) ("Sdscltyp"): TtlScreen (42 B), AcWindowPage (36 B), IvPageControl
; [nakarest] (28 B) x2, IvShowHide (26 B), Window (36 B) x2, AcIndexWideES (42 B) x4,
; [nakarest] AcLswEditBox (58 B) x15, AcLswBox (44 B), Label (32 B), Icon (26 B), VwBox (28 B)
; [nakarest] x12, Line (26 B) x12, IvSdscltyp2 (22 B). 17 texts the records point at (Viewable
; [nakarest] slot 0x5 (table 0xe8562c, 54 entries, InitializeMurai)): "KEY SCALING"
; [nakarest] (TtlScreen.title of element 0); "SCALING TYPE :" (AcLswEditBox.caption of element
; [nakarest] 7); "SCALING SHIFT :" (AcLswEditBox.caption of element 8); "SCALING MODE :"
; [nakarest] (AcLswEditBox.caption of element 10); ....
NakaWidget_Sdscltyp:			.incbin "includes/generated/naka_technichord_part.bin", 0x1136, 0x36
NakaWidget_SdscltypPage:		.incbin "includes/generated/naka_technichord_part.bin", 0x116C, 0x24
NakaWidget_Sdscltyp_2_IvPageControl:	.incbin "includes/generated/naka_technichord_part.bin", 0x1190, 0x1C
NakaWidget_Sdscltyp_3_IvPageControl:	.incbin "includes/generated/naka_technichord_part.bin", 0x11AC, 0x1C
NakaWidget_Sdscltyp_4_IvShowHide:	.incbin "includes/generated/naka_technichord_part.bin", 0x11C8, 0x1A
NakaWidget_Sdscltyp1:			.incbin "includes/generated/naka_technichord_part.bin", 0x11E2, 0x24
NakaWidget_Sdscltyp_6_AcIndexWideES:	.incbin "includes/generated/naka_technichord_part.bin", 0x1206, 0x2A
NakaWidget_ScalingType:			.incbin "includes/generated/naka_technichord_part.bin", 0x1230, 0x4A
NakaWidget_Sdscltyp_8_AcLswEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x127A, 0x4A
NakaWidget_Sdscltyp_9_AcLswBox:		.incbin "includes/generated/naka_technichord_part.bin", 0x12C4, 0x2C
NakaWidget_Sdscltyp_10_AcLswEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x12F0, 0x4A
NakaWidget_Sdscltyp2:			.incbin "includes/generated/naka_technichord_part.bin", 0x133A, 0x24
NakaWidget_Sdscltyp_12_Label:		.incbin "includes/generated/naka_technichord_part.bin", 0x135E, 0x32
NakaWidget_Sdscltyp_13_Icon:		.incbin "includes/generated/naka_technichord_part.bin", 0x1390, 0x1A
NakaWidget_Sdscltyp_14_AcIndexWideES:	.incbin "includes/generated/naka_technichord_part.bin", 0x13AA, 0x2A
NakaWidget_Sdscltyp_15_AcIndexWideES:	.incbin "includes/generated/naka_technichord_part.bin", 0x13D4, 0x2A
NakaWidget_Sdscltyp_16_AcIndexWideES:	.incbin "includes/generated/naka_technichord_part.bin", 0x13FE, 0x2A
NakaWidget_ScalingKey1:			.incbin "includes/generated/naka_technichord_part.bin", 0x1428, 0x3C
NakaWidget_ScalingKey2:			.incbin "includes/generated/naka_technichord_part.bin", 0x1464, 0x3C
NakaWidget_ScalingKey3:			.incbin "includes/generated/naka_technichord_part.bin", 0x14A0, 0x3C
NakaWidget_ScalingKey4:			.incbin "includes/generated/naka_technichord_part.bin", 0x14DC, 0x3C
NakaWidget_ScalingKey5:			.incbin "includes/generated/naka_technichord_part.bin", 0x1518, 0x3C
NakaWidget_ScalingKey6:			.incbin "includes/generated/naka_technichord_part.bin", 0x1554, 0x3C
NakaWidget_ScalingKey7:			.incbin "includes/generated/naka_technichord_part.bin", 0x1590, 0x3C
NakaWidget_ScalingKey8:			.incbin "includes/generated/naka_technichord_part.bin", 0x15CC, 0x3C
NakaWidget_ScalingKey9:			.incbin "includes/generated/naka_technichord_part.bin", 0x1608, 0x3C
NakaWidget_ScalingKey10:		.incbin "includes/generated/naka_technichord_part.bin", 0x1644, 0x3C
NakaWidget_ScalingKey11:		.incbin "includes/generated/naka_technichord_part.bin", 0x1680, 0x3C
NakaWidget_ScalingKey12:		.incbin "includes/generated/naka_technichord_part.bin", 0x16BC, 0x3C
NakaWidget_Sdscltyp_29_VwBox:		.incbin "includes/generated/naka_technichord_part.bin", 0x16F8, 0x1C
NakaWidget_Sdscltyp_30_VwBox:		.incbin "includes/generated/naka_technichord_part.bin", 0x1714, 0x1C
NakaWidget_Sdscltyp_31_VwBox:		.incbin "includes/generated/naka_technichord_part.bin", 0x1730, 0x1C
NakaWidget_Sdscltyp_32_VwBox:		.incbin "includes/generated/naka_technichord_part.bin", 0x174C, 0x1C
NakaWidget_Sdscltyp_33_VwBox:		.incbin "includes/generated/naka_technichord_part.bin", 0x1768, 0x1C
NakaWidget_Sdscltyp_34_VwBox:		.incbin "includes/generated/naka_technichord_part.bin", 0x1784, 0x1C
NakaWidget_Sdscltyp_35_VwBox:		.incbin "includes/generated/naka_technichord_part.bin", 0x17A0, 0x1C
NakaWidget_Sdscltyp_36_VwBox:		.incbin "includes/generated/naka_technichord_part.bin", 0x17BC, 0x1C
NakaWidget_Sdscltyp_37_VwBox:		.incbin "includes/generated/naka_technichord_part.bin", 0x17D8, 0x1C
NakaWidget_Sdscltyp_38_VwBox:		.incbin "includes/generated/naka_technichord_part.bin", 0x17F4, 0x1C
NakaWidget_Sdscltyp_39_VwBox:		.incbin "includes/generated/naka_technichord_part.bin", 0x1810, 0x1C
NakaWidget_Sdscltyp_40_VwBox:		.incbin "includes/generated/naka_technichord_part.bin", 0x182C, 0x1C
NakaWidget_Sdscltyp_41_Line:		.incbin "includes/generated/naka_technichord_part.bin", 0x1848, 0x1A
NakaWidget_Sdscltyp_42_Line:		.incbin "includes/generated/naka_technichord_part.bin", 0x1862, 0x1A
NakaWidget_Sdscltyp_43_Line:		.incbin "includes/generated/naka_technichord_part.bin", 0x187C, 0x1A
NakaWidget_Sdscltyp_44_Line:		.incbin "includes/generated/naka_technichord_part.bin", 0x1896, 0x1A
NakaWidget_Sdscltyp_45_Line:		.incbin "includes/generated/naka_technichord_part.bin", 0x18B0, 0x1A
NakaWidget_Sdscltyp_46_Line:		.incbin "includes/generated/naka_technichord_part.bin", 0x18CA, 0x1A
NakaWidget_Sdscltyp_47_Line:		.incbin "includes/generated/naka_technichord_part.bin", 0x18E4, 0x1A
NakaWidget_Sdscltyp_48_Line:		.incbin "includes/generated/naka_technichord_part.bin", 0x18FE, 0x1A
NakaWidget_Sdscltyp_49_Line:		.incbin "includes/generated/naka_technichord_part.bin", 0x1918, 0x1A
NakaWidget_Sdscltyp_50_Line:		.incbin "includes/generated/naka_technichord_part.bin", 0x1932, 0x1A
NakaWidget_Sdscltyp_51_Line:		.incbin "includes/generated/naka_technichord_part.bin", 0x194C, 0x1A
NakaWidget_Sdscltyp_52_Line:		.incbin "includes/generated/naka_technichord_part.bin", 0x1966, 0x1A
NakaWidget_Sdscltyp_53_IvSdscltyp2:	.incbin "includes/generated/naka_technichord_part.bin", 0x1980, 0x16
; [nakarest] naka_technichord_part+0x1996  +0x1996..+0x1a48 (0xe83664, 178 B)
; [nakarest] widget records, elements 0-2 of Viewable slot 0x7 (table 0xe85708, 3 entries,
; [nakarest] InitializeMurai) ("Sdlfthld"): TtlScreen (42 B), AcIndexWideES (42 B), AcLswEditBox
; [nakarest] (58 B). 2 texts the records point at (Viewable slot 0x7 (table 0xe85708, 3 entries,
; [nakarest] InitializeMurai)): "LEFT HOLD SETTING" (TtlScreen.title of element 0); "LEFT HOLD
; [nakarest] :" (AcLswEditBox.caption of element 2).
NakaWidget_Sdlfthld:			.incbin "includes/generated/naka_technichord_part.bin", 0x1996, 0x3C
NakaWidget_Sdlfthld_1_AcIndexWideES:	.incbin "includes/generated/naka_technichord_part.bin", 0x19D2, 0x2A
NakaWidget_Sdlfthld_2_AcLswEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x19FC, 0x4C
; [nakarest] naka_technichord_part+0x1a48  +0x1a48..+0x1ad6 (0xe83716, 142 B)
; [nakarest] widget records, elements 0-3 of Viewable slot 0x8 (table 0xe85718, 4 entries,
; [nakarest] InitializeMurai) ("Sdmixer"): TtlScreen (42 B), AcResetPage (36 B), AcPartMixer (36
; [nakarest] B), IvExit (22 B). 1 text the records point at (Viewable slot 0x8 (table 0xe85718,
; [nakarest] 4 entries, InitializeMurai)): "MIXER" (TtlScreen.title of element 0).
NakaWidget_Sdmixer:			.incbin "includes/generated/naka_technichord_part.bin", 0x1A48, 0x30
NakaWidget_Sdmixer_1_AcResetPage:	.incbin "includes/generated/naka_technichord_part.bin", 0x1A78, 0x24
NakaWidget_Sdmixer_2_AcPartMixer:	.incbin "includes/generated/naka_technichord_part.bin", 0x1A9C, 0x24
NakaWidget_Sdmixer_3_IvExit:		.incbin "includes/generated/naka_technichord_part.bin", 0x1AC0, 0x16
; [nakarest] naka_technichord_part+0x1ad6  +0x1ad6..+0x2026 (0xe837a4, 1360 B)
; [nakarest] widget records, elements 0-28 of Viewable slot 0xd (table 0xe8572c, 29 entries,
; [nakarest] InitializeMurai) ("Sdtecd"): TtlScreen (42 B), AcWindowPage (36 B), IvPageControl
; [nakarest] (28 B) x2, IvSdtecd (22 B), IvIntEasySet (24 B), Window (36 B) x2, AcIndexWideES
; [nakarest] (42 B) x2, AcIndexEditSw (40 B) x2, PsLabelBox (48 B) x14, IvSdtecd1 (22 B),
; [nakarest] AcLswEditBox (58 B), Label (32 B). 17 texts the records point at (Viewable slot 0xd
; [nakarest] (table 0xe8572c, 29 entries, InitializeMurai)): "TECHNI-CHORD" (TtlScreen.title of
; [nakarest] element 0); "CLOSE" (PsLabelBox.str of element 10); "OPEN 1" (PsLabelBox.str of
; [nakarest] element 11); "OPEN 2" (PsLabelBox.str of element 12); ....
NakaWidget_Sdtecd:			.incbin "includes/generated/naka_technichord_part.bin", 0x1AD6, 0x38
NakaWidget_SdtecdPage:			.incbin "includes/generated/naka_technichord_part.bin", 0x1B0E, 0x24
NakaWidget_Sdtecd_2_IvPageControl:	.incbin "includes/generated/naka_technichord_part.bin", 0x1B32, 0x1C
NakaWidget_Sdtecd_3_IvPageControl:	.incbin "includes/generated/naka_technichord_part.bin", 0x1B4E, 0x1C
NakaWidget_Sdtecd_4_IvSdtecd:		.incbin "includes/generated/naka_technichord_part.bin", 0x1B6A, 0x16
NakaWidget_Sdtecd_5_IvIntEasySet:	.incbin "includes/generated/naka_technichord_part.bin", 0x1B80, 0x18
NakaWidget_Sdtecd1:			.incbin "includes/generated/naka_technichord_part.bin", 0x1B98, 0x24
NakaWidget_Sdtecd_7_AcIndexWideES:	.incbin "includes/generated/naka_technichord_part.bin", 0x1BBC, 0x2A
NakaWidget_Sdtecd_8_AcIndexEditSw:	.incbin "includes/generated/naka_technichord_part.bin", 0x1BE6, 0x28
NakaWidget_Sdtecd_9_AcIndexEditSw:	.incbin "includes/generated/naka_technichord_part.bin", 0x1C0E, 0x28
NakaWidget_TcClose:			.incbin "includes/generated/naka_technichord_part.bin", 0x1C36, 0x36
NakaWidget_TcOpen1:			.incbin "includes/generated/naka_technichord_part.bin", 0x1C6C, 0x38
NakaWidget_TcOpen2:			.incbin "includes/generated/naka_technichord_part.bin", 0x1CA4, 0x38
NakaWidget_TcDuet1:			.incbin "includes/generated/naka_technichord_part.bin", 0x1CDC, 0x38
NakaWidget_TcDuet2:			.incbin "includes/generated/naka_technichord_part.bin", 0x1D14, 0x38
NakaWidget_TcCountry:			.incbin "includes/generated/naka_technichord_part.bin", 0x1D4C, 0x38
NakaWidget_TcTheatre:			.incbin "includes/generated/naka_technichord_part.bin", 0x1D84, 0x38
NakaWidget_TcHymn:			.incbin "includes/generated/naka_technichord_part.bin", 0x1DBC, 0x36
NakaWidget_TcBigBandBrass:		.incbin "includes/generated/naka_technichord_part.bin", 0x1DF2, 0x40
NakaWidget_TcBigBandReeds:		.incbin "includes/generated/naka_technichord_part.bin", 0x1E32, 0x40
NakaWidget_TcOctave:			.incbin "includes/generated/naka_technichord_part.bin", 0x1E72, 0x38
NakaWidget_TcBlock:			.incbin "includes/generated/naka_technichord_part.bin", 0x1EAA, 0x36
NakaWidget_TcHardRock:			.incbin "includes/generated/naka_technichord_part.bin", 0x1EE0, 0x3A
NakaWidget_TcFanfare:			.incbin "includes/generated/naka_technichord_part.bin", 0x1F1A, 0x38
NakaWidget_Sdtecd_24_IvSdtecd1:		.incbin "includes/generated/naka_technichord_part.bin", 0x1F52, 0x16
NakaWidget_Sdtecd2:			.incbin "includes/generated/naka_technichord_part.bin", 0x1F68, 0x24
NakaWidget_Sdtecd_26_AcIndexWideES:	.incbin "includes/generated/naka_technichord_part.bin", 0x1F8C, 0x2A
NakaWidget_Sdtecd_27_AcLswEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x1FB6, 0x4A
NakaWidget_Sdtecd_28_Label:		.incbin "includes/generated/naka_technichord_part.bin", 0x2000, 0x26
; [nakarest] naka_technichord_part+0x2026  +0x2026..+0x20ba (0xe83cf4, 148 B)
; [nakarest] widget records, elements 0-3 of Viewable slot 0xa5 (table 0xe857a4, 4 entries,
; [nakarest] InitializeMurai) ("Sqmixer"): TtlScreen (42 B), AcResetPage (36 B), AcTrackMixer
; [nakarest] (36 B), IvExit (22 B). 1 text the records point at (Viewable slot 0xa5 (table
; [nakarest] 0xe857a4, 4 entries, InitializeMurai)): "TRACK MIXER" (TtlScreen.title of element
; [nakarest] 0).
NakaWidget_Sqmixer:			.incbin "includes/generated/naka_technichord_part.bin", 0x2026, 0x36
NakaWidget_Sqmixer_1_AcResetPage:	.incbin "includes/generated/naka_technichord_part.bin", 0x205C, 0x24
NakaWidget_Sqmixer_2_AcTrackMixer:	.incbin "includes/generated/naka_technichord_part.bin", 0x2080, 0x24
NakaWidget_Sqmixer_3_IvExit:		.incbin "includes/generated/naka_technichord_part.bin", 0x20A4, 0x16
; [nakarest] naka_technichord_part+0x20ba  +0x20ba..+0x2338 (0xe83d88, 638 B)
; [nakarest] widget records, elements 0-14 of Viewable slot 0xe4 (table 0xe857b8, 15 entries,
; [nakarest] InitializeMurai) ("Demofeature"): AcFdemoScreen (42 B), AcPresentationBox (48 B)
; [nakarest] x2, Window (36 B) x2, IvDemofeature1 (22 B), AcLanguageText (42 B), IvDemofeature2
; [nakarest] (22 B), PsParaBox (36 B) x2, Screen (34 B) x2, AcPresentationControl (36 B), Label
; [nakarest] (32 B) x2. 5 texts the records point at (Viewable slot 0xe4 (table 0xe857b8, 15
; [nakarest] entries, InitializeMurai)): "FEATURE PRESENTATION" (AcFdemoScreen.title of element
; [nakarest] 0); "Start the internal DEMO" (AcPresentationBox.str of element 1); "Start the
; [nakarest] loaded DEMO" (AcPresentationBox.str of element 7); "Presentation Mode" (Label.str
; [nakarest] of element 11); ....
NakaWidget_Demofeature:				.incbin "includes/generated/naka_technichord_part.bin", 0x20BA, 0x40
NakaWidget_Demofeature_1_AcPresentationBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x20FA, 0x48
NakaWidget_Demofeature1:			.incbin "includes/generated/naka_technichord_part.bin", 0x2142, 0x24
NakaWidget_Demofeature_3_IvDemofeature1:	.incbin "includes/generated/naka_technichord_part.bin", 0x2166, 0x16
NakaWidget_Demofeature_4_AcLanguageText:	.incbin "includes/generated/naka_technichord_part.bin", 0x217C, 0x2A
NakaWidget_Demofeature2:			.incbin "includes/generated/naka_technichord_part.bin", 0x21A6, 0x24
NakaWidget_Demofeature_6_IvDemofeature2:	.incbin "includes/generated/naka_technichord_part.bin", 0x21CA, 0x16
NakaWidget_Demofeature_7_AcPresentationBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x21E0, 0x46
NakaWidget_FDemoTitleBox:			.incbin "includes/generated/naka_technichord_part.bin", 0x2226, 0x24
NakaWidget_PlainScreen:				.incbin "includes/generated/naka_technichord_part.bin", 0x224A, 0x22
NakaWidget_PresentationControl:			.incbin "includes/generated/naka_technichord_part.bin", 0x226C, 0x24
NakaWidget_Demofeature_11_Label:		.incbin "includes/generated/naka_technichord_part.bin", 0x2290, 0x32
NakaWidget_LoadingPresentation:			.incbin "includes/generated/naka_technichord_part.bin", 0x22C2, 0x22
NakaWidget_Demofeature_13_Label:		.incbin "includes/generated/naka_technichord_part.bin", 0x22E4, 0x30
NakaWidget_PresentationTitle:			.incbin "includes/generated/naka_technichord_part.bin", 0x2314, 0x24
; [nakarest] naka_technichord_part+0x2338  +0x2338..+0x2a16 (0xe84006, 1758 B)
; [nakarest] widget records, elements 0-43 of Viewable slot 0xea (table 0xe857f8, 44 entries,
; [nakarest] InitializeMurai) ("Drawbar"): TtlScreen (42 B), IvIntVari (24 B), AcIndexToggle (44
; [nakarest] B) x3, Label (32 B) x11, IvExit (22 B), IvPageOverWrite (28 B) x2, IvDrawbar (22
; [nakarest] B), AcDrawSetting (44 B), Window (36 B) x4, VwBox (28 B) x3, StringBox (38 B),
; [nakarest] IvDrawbar1 (22 B), VwUserBitmapSp (26 B), AcDrawEditBox (58 B) x4, AcIndexWideES
; [nakarest] (42 B), IvDrawbar2 (22 B), AcDrawbarName (40 B), PsParaBox (36 B), IvDrawbarNorm
; [nakarest] (22 B), Icon (26 B) x2, IvDrawbarSndE (22 B), AcTitleMenu (54 B). 26 texts the
; [nakarest] records point at (Viewable slot 0xea (table 0xe857f8, 44 entries,
; [nakarest] InitializeMurai)): "" (TtlScreen.title of element 0); " 4'" (AcIndexToggle.stroff
; [nakarest] of element 2); " 4'" (AcIndexToggle.stron of element 2); "2 '"
; [nakarest] (AcIndexToggle.stroff of element 3); ....
NakaWidget_Drawbar:			.incbin "includes/generated/naka_technichord_part.bin", 0x2338, 0x2C
NakaWidget_Drawbar_1_IvIntVari:		.incbin "includes/generated/naka_technichord_part.bin", 0x2364, 0x18
NakaWidget_DrawPerc4:			.incbin "includes/generated/naka_technichord_part.bin", 0x237C, 0x34
NakaWidget_DrawPerc223:			.incbin "includes/generated/naka_technichord_part.bin", 0x23B0, 0x38
NakaWidget_White23:			.incbin "includes/generated/naka_technichord_part.bin", 0x23E8, 0x24
NakaWidget_Black23:			.incbin "includes/generated/naka_technichord_part.bin", 0x240C, 0x24
NakaWidget_Drawbar_6_Label:		.incbin "includes/generated/naka_technichord_part.bin", 0x2430, 0x2C
NakaWidget_Drawbar_7_IvExit:		.incbin "includes/generated/naka_technichord_part.bin", 0x245C, 0x16
NakaWidget_Drawbar_8_Label:		.incbin "includes/generated/naka_technichord_part.bin", 0x2472, 0x26
NakaWidget_Drawbar_9_IvPageOverWrite:	.incbin "includes/generated/naka_technichord_part.bin", 0x2498, 0x1C
NakaWidget_Drawbar_10_IvPageOverWrite:	.incbin "includes/generated/naka_technichord_part.bin", 0x24B4, 0x1C
NakaWidget_Drawbar_11_IvDrawbar:	.incbin "includes/generated/naka_technichord_part.bin", 0x24D0, 0x16
NakaWidget_DrawSetting:			.incbin "includes/generated/naka_technichord_part.bin", 0x24E6, 0x4C
NakaWidget_Drawbar1:			.incbin "includes/generated/naka_technichord_part.bin", 0x2532, 0x24
NakaWidget_Drawbar_14_VwBox:		.incbin "includes/generated/naka_technichord_part.bin", 0x2556, 0x1C
NakaWidget_Drawbar_15_StringBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x2572, 0x4A
NakaWidget_Drawbar_16_Label:		.incbin "includes/generated/naka_technichord_part.bin", 0x25BC, 0x24
NakaWidget_Drawbar_17_Label:		.incbin "includes/generated/naka_technichord_part.bin", 0x25E0, 0x24
NakaWidget_Drawbar_18_Label:		.incbin "includes/generated/naka_technichord_part.bin", 0x2604, 0x24
NakaWidget_Drawbar_19_Label:		.incbin "includes/generated/naka_technichord_part.bin", 0x2628, 0x24
NakaWidget_Drawbar_20_IvDrawbar1:	.incbin "includes/generated/naka_technichord_part.bin", 0x264C, 0x16
NakaWidget_Drawbar_21_VwUserBitmapSp:	.incbin "includes/generated/naka_technichord_part.bin", 0x2662, 0x1A
NakaWidget_Drawbar2:			.incbin "includes/generated/naka_technichord_part.bin", 0x267C, 0x24
NakaWidget_Drawbar_23_AcDrawEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x26A0, 0x42
NakaWidget_Drawbar_24_AcDrawEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x26E2, 0x42
NakaWidget_Drawbar_25_AcDrawEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x2724, 0x4A
NakaWidget_Drawbar_26_AcDrawEditBox:	.incbin "includes/generated/naka_technichord_part.bin", 0x276E, 0x4A
NakaWidget_Drawbar_27_AcIndexWideES:	.incbin "includes/generated/naka_technichord_part.bin", 0x27B8, 0x2A
NakaWidget_Drawbar_28_IvDrawbar2:	.incbin "includes/generated/naka_technichord_part.bin", 0x27E2, 0x16
NakaWidget_Drawbar_29_AcDrawbarName:	.incbin "includes/generated/naka_technichord_part.bin", 0x27F8, 0x28
NakaWidget_DrawbarNorm:			.incbin "includes/generated/naka_technichord_part.bin", 0x2820, 0x24
NakaWidget_DrawbarPart:			.incbin "includes/generated/naka_technichord_part.bin", 0x2844, 0x24
NakaWidget_DrawTremolo:			.incbin "includes/generated/naka_technichord_part.bin", 0x2868, 0x38
NakaWidget_Drawbar_33_Label:		.incbin "includes/generated/naka_technichord_part.bin", 0x28A0, 0x28
NakaWidget_Drawbar_34_IvDrawbarNorm:	.incbin "includes/generated/naka_technichord_part.bin", 0x28C8, 0x16
NakaWidget_Drawbar_35_VwBox:		.incbin "includes/generated/naka_technichord_part.bin", 0x28DE, 0x1C
NakaWidget_Drawbar_36_Icon:		.incbin "includes/generated/naka_technichord_part.bin", 0x28FA, 0x1A
NakaWidget_Drawbar_37_Label:		.incbin "includes/generated/naka_technichord_part.bin", 0x2914, 0x28
NakaWidget_DrawbarSndE:			.incbin "includes/generated/naka_technichord_part.bin", 0x293C, 0x24
NakaWidget_Drawbar_39_IvDrawbarSndE:	.incbin "includes/generated/naka_technichord_part.bin", 0x2960, 0x16
NakaWidget_Drawbar_40_AcTitleMenu:	.incbin "includes/generated/naka_technichord_part.bin", 0x2976, 0x3C
NakaWidget_Drawbar_41_VwBox:		.incbin "includes/generated/naka_technichord_part.bin", 0x29B2, 0x1C
NakaWidget_Drawbar_42_Icon:		.incbin "includes/generated/naka_technichord_part.bin", 0x29CE, 0x1A
NakaWidget_Drawbar_43_Label:		.incbin "includes/generated/naka_technichord_part.bin", 0x29E8, 0x2E
; [nakarest] naka_technichord_part+0x2a16  +0x2a16..+0x3182 (0xe846e4, 1900 B)
; [nakarest] widget records, elements 0-36 of Viewable slot 0xeb (table 0xe858ac, 37 entries,
; [nakarest] InitializeMurai) ("Accordion"): Screen (34 B), Icon (26 B), IvIntVari (24 B), Label
; [nakarest] (32 B) x4, AcIndexEditSw (40 B) x2, PsParaBox (36 B), IvAccordion (22 B), Window
; [nakarest] (36 B) x2, VwUserBitmapSp (26 B) x2, AcIndexToggle (44 B) x4, AcAccordionTab (52 B)
; [nakarest] x16, IvAccordionX (22 B) x2. 76 texts the records point at (Viewable slot 0xeb
; [nakarest] (table 0xe858ac, 37 entries, InitializeMurai)): "ACCORDION REGISTER" (Label.str of
; [nakarest] element 3); "TYPE" (Label.str of element 6); "TYPE : GERMAN" (Label.str of element
; [nakarest] 10); "BASS1" (AcIndexToggle.stroff of element 12); ....
NakaWidget_Accordion:			.incbin "includes/generated/naka_technichord_part.bin", 0x2A16, 0x22
NakaWidget_Accordion_1_Icon:		.incbin "includes/generated/naka_technichord_part.bin", 0x2A38, 0x1A
NakaWidget_Accordion_2_IvIntVari:	.incbin "includes/generated/naka_technichord_part.bin", 0x2A52, 0x18
NakaWidget_Accordion_3_Label:		.incbin "includes/generated/naka_technichord_part.bin", 0x2A6A, 0x34
NakaWidget_Accordion_4_AcIndexEditSw:	.incbin "includes/generated/naka_technichord_part.bin", 0x2A9E, 0x28
NakaWidget_Accordion_5_AcIndexEditSw:	.incbin "includes/generated/naka_technichord_part.bin", 0x2AC6, 0x28
NakaWidget_Accordion_6_Label:		.incbin "includes/generated/naka_technichord_part.bin", 0x2AEE, 0x26
NakaWidget_AccordionPart:		.incbin "includes/generated/naka_technichord_part.bin", 0x2B14, 0x24
NakaWidget_Accordion_8_IvAccordion:	.incbin "includes/generated/naka_technichord_part.bin", 0x2B38, 0x16
NakaWidget_Accordion1:			.incbin "includes/generated/naka_technichord_part.bin", 0x2B4E, 0x24
NakaWidget_Accordion_10_Label:		.incbin "includes/generated/naka_technichord_part.bin", 0x2B72, 0x2E
NakaWidget_Accordion_11_VwUserBitmapSp:	.incbin "includes/generated/naka_technichord_part.bin", 0x2BA0, 0x1A
NakaWidget_Accordion_12_AcIndexToggle:	.incbin "includes/generated/naka_technichord_part.bin", 0x2BBA, 0x38
NakaWidget_Accordion_13_AcIndexToggle:	.incbin "includes/generated/naka_technichord_part.bin", 0x2BF2, 0x38
NakaWidget_Accordion_14_AcAccordionTab:	.incbin "includes/generated/naka_technichord_part.bin", 0x2C2A, 0x44
NakaWidget_Accordion_15_AcAccordionTab:	.incbin "includes/generated/naka_technichord_part.bin", 0x2C6E, 0x42
NakaWidget_Accordion_16_AcAccordionTab:	.incbin "includes/generated/naka_technichord_part.bin", 0x2CB0, 0x40
NakaWidget_Accordion_17_AcAccordionTab:	.incbin "includes/generated/naka_technichord_part.bin", 0x2CF0, 0x50
NakaWidget_Accordion_18_AcAccordionTab:	.incbin "includes/generated/naka_technichord_part.bin", 0x2D40, 0x4A
NakaWidget_Accordion_19_AcAccordionTab:	.incbin "includes/generated/naka_technichord_part.bin", 0x2D8A, 0x4C
NakaWidget_Accordion_20_AcAccordionTab:	.incbin "includes/generated/naka_technichord_part.bin", 0x2DD6, 0x42
NakaWidget_Accordion_21_AcAccordionTab:	.incbin "includes/generated/naka_technichord_part.bin", 0x2E18, 0x40
NakaWidget_Accordion_22_IvAccordionX:	.incbin "includes/generated/naka_technichord_part.bin", 0x2E58, 0x16
NakaWidget_Accordion2:			.incbin "includes/generated/naka_technichord_part.bin", 0x2E6E, 0x24
NakaWidget_Accordion_24_Label:		.incbin "includes/generated/naka_technichord_part.bin", 0x2E92, 0x30
NakaWidget_Accordion_25_VwUserBitmapSp:	.incbin "includes/generated/naka_technichord_part.bin", 0x2EC2, 0x1A
NakaWidget_Accordion_26_AcIndexToggle:	.incbin "includes/generated/naka_technichord_part.bin", 0x2EDC, 0x38
NakaWidget_Accordion_27_AcIndexToggle:	.incbin "includes/generated/naka_technichord_part.bin", 0x2F14, 0x38
NakaWidget_Accordion_28_AcAccordionTab:	.incbin "includes/generated/naka_technichord_part.bin", 0x2F4C, 0x42
NakaWidget_Accordion_29_AcAccordionTab:	.incbin "includes/generated/naka_technichord_part.bin", 0x2F8E, 0x3E
NakaWidget_Accordion_30_AcAccordionTab:	.incbin "includes/generated/naka_technichord_part.bin", 0x2FCC, 0x40
NakaWidget_Accordion_31_AcAccordionTab:	.incbin "includes/generated/naka_technichord_part.bin", 0x300C, 0x4C
NakaWidget_Accordion_32_AcAccordionTab:	.incbin "includes/generated/naka_technichord_part.bin", 0x3058, 0x4A
NakaWidget_Accordion_33_AcAccordionTab:	.incbin "includes/generated/naka_technichord_part.bin", 0x30A2, 0x48
NakaWidget_Accordion_34_AcAccordionTab:	.incbin "includes/generated/naka_technichord_part.bin", 0x30EA, 0x42
NakaWidget_Accordion_35_AcAccordionTab:	.incbin "includes/generated/naka_technichord_part.bin", 0x312C, 0x40
NakaWidget_Accordion_36_IvAccordionX:	.incbin "includes/generated/naka_technichord_part.bin", 0x316C, 0x16
; [nakarest] naka_technichord_part+0x3182  +0x3182..+0x34fa (0xe84e50, 888 B)
; [nakarest] widget records, elements 0-23 of Viewable slot 0xee (table 0xe85944, 24 entries,
; [nakarest] InitializeMurai) ("Mesage"): IvScreen (34 B), IvMesage (22 B), Window (36 B) x7,
; [nakarest] AcLanguageText (42 B) x6, IvIntComplete (24 B), IvIntReminder (24 B), IvIntError
; [nakarest] (24 B), EditSw (40 B) x2, AcRamBox (44 B) x3, AcPleaseWait (36 B). 2 texts the
; [nakarest] records point at (Viewable slot 0xee (table 0xe85944, 24 entries,
; [nakarest] InitializeMurai)): "~81" (EditSw.str of element 16); "~81" (EditSw.str of element
; [nakarest] 19).
NakaWidget_Mesage:			.incbin "includes/generated/naka_technichord_part.bin", 0x3182, 0x22
NakaWidget_Mesage_1_IvMesage:		.incbin "includes/generated/naka_technichord_part.bin", 0x31A4, 0x16
NakaWidget_Completed:			.incbin "includes/generated/naka_technichord_part.bin", 0x31BA, 0x24
NakaWidget_Mesage_3_AcLanguageText:	.incbin "includes/generated/naka_technichord_part.bin", 0x31DE, 0x2A
NakaWidget_Mesage_4_IvIntComplete:	.incbin "includes/generated/naka_technichord_part.bin", 0x3208, 0x18
NakaWidget_Reminder:			.incbin "includes/generated/naka_technichord_part.bin", 0x3220, 0x24
NakaWidget_Mesage_6_AcLanguageText:	.incbin "includes/generated/naka_technichord_part.bin", 0x3244, 0x2A
NakaWidget_Mesage_7_AcLanguageText:	.incbin "includes/generated/naka_technichord_part.bin", 0x326E, 0x2A
NakaWidget_Mesage_8_IvIntReminder:	.incbin "includes/generated/naka_technichord_part.bin", 0x3298, 0x18
NakaWidget_Error:			.incbin "includes/generated/naka_technichord_part.bin", 0x32B0, 0x24
NakaWidget_Mesage_10_IvIntError:	.incbin "includes/generated/naka_technichord_part.bin", 0x32D4, 0x18
NakaWidget_Mesage_11_AcLanguageText:	.incbin "includes/generated/naka_technichord_part.bin", 0x32EC, 0x2A
NakaWidget_Mesage_12_AcLanguageText:	.incbin "includes/generated/naka_technichord_part.bin", 0x3316, 0x2A
NakaWidget_Other:			.incbin "includes/generated/naka_technichord_part.bin", 0x3340, 0x24
NakaWidget_Mesage_14_AcLanguageText:	.incbin "includes/generated/naka_technichord_part.bin", 0x3364, 0x2A
NakaWidget_CheckMessage:		.incbin "includes/generated/naka_technichord_part.bin", 0x338E, 0x24
NakaWidget_Mesage_16_EditSw:		.incbin "includes/generated/naka_technichord_part.bin", 0x33B2, 0x2C
NakaWidget_Mesage_17_AcRamBox:		.incbin "includes/generated/naka_technichord_part.bin", 0x33DE, 0x2C
NakaWidget_Mesage_18_AcRamBox:		.incbin "includes/generated/naka_technichord_part.bin", 0x340A, 0x2C
NakaWidget_Mesage_19_EditSw:		.incbin "includes/generated/naka_technichord_part.bin", 0x3436, 0x2C
NakaWidget_NoMessage:			.incbin "includes/generated/naka_technichord_part.bin", 0x3462, 0x24
NakaWidget_Mesage_21_AcRamBox:		.incbin "includes/generated/naka_technichord_part.bin", 0x3486, 0x2C
NakaWidget_PleaseWait:			.incbin "includes/generated/naka_technichord_part.bin", 0x34B2, 0x24
NakaWidget_Mesage_23_AcPleaseWait:	.incbin "includes/generated/naka_technichord_part.bin", 0x34D6, 0x24
; [nakarest] naka_technichord_part+0x34fa  +0x34fa..+0x364c (0xe851c8, 338 B)
; [nakarest] widget records, elements 0-10 of Viewable slot 0xef (table 0xe859a8, 11 entries,
; [nakarest] InitializeMurai) ("Welcom"): AcWelcomScreen (34 B), IvIntWelcome (24 B) x3,
; [nakarest] VwUserBitmapSp (26 B) x2, Screen (34 B) x2, Label (32 B), IvMPver (22 B), PsParaBox
; [nakarest] (36 B). 1 text the records point at (Viewable slot 0xef (table 0xe859a8, 11
; [nakarest] entries, InitializeMurai)): "ALL INITIAL SETTING!" (Label.str of element 5).
NakaWidget_Welcom:			.incbin "includes/generated/naka_technichord_part.bin", 0x34FA, 0x22
NakaWidget_Welcom_1_IvIntWelcome:	.incbin "includes/generated/naka_technichord_part.bin", 0x351C, 0x18
NakaWidget_Welcom_2_VwUserBitmapSp:	.incbin "includes/generated/naka_technichord_part.bin", 0x3534, 0x1A
NakaWidget_Welcom_3_VwUserBitmapSp:	.incbin "includes/generated/naka_technichord_part.bin", 0x354E, 0x1A
NakaWidget_AllInitial:			.incbin "includes/generated/naka_technichord_part.bin", 0x3568, 0x22
NakaWidget_Welcom_5_Label:		.incbin "includes/generated/naka_technichord_part.bin", 0x358A, 0x36
NakaWidget_Welcom_6_IvIntWelcome:	.incbin "includes/generated/naka_technichord_part.bin", 0x35C0, 0x18
NakaWidget_MPVersion:			.incbin "includes/generated/naka_technichord_part.bin", 0x35D8, 0x22
NakaWidget_Welcom_8_IvMPver:		.incbin "includes/generated/naka_technichord_part.bin", 0x35FA, 0x16
NakaWidget_Welcom_9_IvIntWelcome:	.incbin "includes/generated/naka_technichord_part.bin", 0x3610, 0x18
NakaWidget_MPver:			.incbin "includes/generated/naka_technichord_part.bin", 0x3628, 0x24
; [nakarest] naka_technichord_part+0x364c  +0x364c..+0x37a2 (0xe8531a, 342 B)
; [nakarest] widget records, elements 0-5 of Viewable slot 0xf0 (table 0xe859d8, 6 entries,
; [nakarest] InitializeMurai) ("Softver"): TtlScreen (42 B), PsEditBox (50 B) x4, IvSoftver (22
; [nakarest] B). 5 texts the records point at (Viewable slot 0xf0 (table 0xe859d8, 6 entries,
; [nakarest] InitializeMurai)): "SOFT VERSION" (TtlScreen.title of element 0); "MAIN PROGRAM :"
; [nakarest] (PsEditBox.caption of element 1); "MAIN TABLE :" (PsEditBox.caption of element 2);
; [nakarest] "SUB PROGRAM :" (PsEditBox.caption of element 3); ....
NakaWidget_Softver:		.incbin "includes/generated/naka_technichord_part.bin", 0x364C, 0x38
NakaWidget_MainProgram:		.incbin "includes/generated/naka_technichord_part.bin", 0x3684, 0x42
NakaWidget_MainTable:		.incbin "includes/generated/naka_technichord_part.bin", 0x36C6, 0x42
NakaWidget_SubProgram:		.incbin "includes/generated/naka_technichord_part.bin", 0x3708, 0x42
NakaWidget_SoundTable:		.incbin "includes/generated/naka_technichord_part.bin", 0x374A, 0x42
NakaWidget_Softver_5_IvSoftver:	.incbin "includes/generated/naka_technichord_part.bin", 0x378C, 0x16
; [nakarest] naka_technichord_part+0x37a2  +0x37a2..+0x37f6 (0xe85470, 84 B)
; [nakarest] the table itself: Viewable slot 0x2 (table 0xe85470, 20 entries, InitializeMurai),
; [nakarest] 20 entry pointers x 4 bytes.
Murai_ViewableTable_002:	.incbin "includes/generated/naka_technichord_part.bin", 0x37A2, 0x54
; [nakarest] naka_technichord_part+0x37f6  +0x37f6..+0x394a (0xe854c4, 340 B)
; [nakarest] the table itself: Viewable slot 0x3 (table 0xe854c4, 84 entries, InitializeMurai),
; [nakarest] 84 entry pointers x 4 bytes.
Murai_ViewableTable_003:	.incbin "includes/generated/naka_technichord_part.bin", 0x37F6, 0x154
; [nakarest] naka_technichord_part+0x394a  +0x394a..+0x395e (0xe85618, 20 B)
; [nakarest] the table itself: Viewable slot 0x4 (table 0xe85618, 4 entries, InitializeMurai), 4
; [nakarest] entry pointers x 4 bytes.
Murai_ViewableTable_004:	.incbin "includes/generated/naka_technichord_part.bin", 0x394A, 0x14
; [nakarest] naka_technichord_part+0x395e  +0x395e..+0x3a3a (0xe8562c, 220 B)
; [nakarest] the table itself: Viewable slot 0x5 (table 0xe8562c, 54 entries, InitializeMurai),
; [nakarest] 54 entry pointers x 4 bytes.
Murai_ViewableTable_005:	.incbin "includes/generated/naka_technichord_part.bin", 0x395E, 0xDC
; [nakarest] naka_technichord_part+0x3a3a  +0x3a3a..+0x3a4a (0xe85708, 16 B)
; [nakarest] the table itself: Viewable slot 0x7 (table 0xe85708, 3 entries, InitializeMurai), 3
; [nakarest] entry pointers x 4 bytes.
Murai_ViewableTable_007:	.incbin "includes/generated/naka_technichord_part.bin", 0x3A3A, 0x10
; [nakarest] naka_technichord_part+0x3a4a  +0x3a4a..+0x3a5e (0xe85718, 20 B)
; [nakarest] the table itself: Viewable slot 0x8 (table 0xe85718, 4 entries, InitializeMurai), 4
; [nakarest] entry pointers x 4 bytes.
Murai_ViewableTable_008:	.incbin "includes/generated/naka_technichord_part.bin", 0x3A4A, 0x14
; [nakarest] naka_technichord_part+0x3a5e  +0x3a5e..+0x3ad6 (0xe8572c, 120 B)
; [nakarest] the table itself: Viewable slot 0xd (table 0xe8572c, 29 entries, InitializeMurai),
; [nakarest] 29 entry pointers x 4 bytes.
Murai_ViewableTable_00D:	.incbin "includes/generated/naka_technichord_part.bin", 0x3A5E, 0x78
; [nakarest] naka_technichord_part+0x3ad6  +0x3ad6..+0x3aea (0xe857a4, 20 B)
; [nakarest] the table itself: Viewable slot 0xa5 (table 0xe857a4, 4 entries, InitializeMurai),
; [nakarest] 4 entry pointers x 4 bytes.
Murai_ViewableTable_0A5:	.incbin "includes/generated/naka_technichord_part.bin", 0x3AD6, 0x14
; [nakarest] naka_technichord_part+0x3aea  +0x3aea..+0x3b2a (0xe857b8, 64 B)
; [nakarest] the table itself: Viewable slot 0xe4 (table 0xe857b8, 15 entries, InitializeMurai),
; [nakarest] 15 entry pointers x 4 bytes.
Murai_ViewableTable_0E4:	.incbin "includes/generated/naka_technichord_part.bin", 0x3AEA, 0x40
; [nakarest] naka_technichord_part+0x3b2a  +0x3b2a..+0x3bde (0xe857f8, 180 B)
; [nakarest] the table itself: Viewable slot 0xea (table 0xe857f8, 44 entries, InitializeMurai),
; [nakarest] 44 entry pointers x 4 bytes.
Murai_ViewableTable_0EA:	.incbin "includes/generated/naka_technichord_part.bin", 0x3B2A, 0xB4
; [nakarest] naka_technichord_part+0x3bde  +0x3bde..+0x3c76 (0xe858ac, 152 B)
; [nakarest] the table itself: Viewable slot 0xeb (table 0xe858ac, 37 entries, InitializeMurai),
; [nakarest] 37 entry pointers x 4 bytes.
Murai_ViewableTable_0EB:	.incbin "includes/generated/naka_technichord_part.bin", 0x3BDE, 0x98
; [nakarest] naka_technichord_part+0x3c76  +0x3c76..+0x3cda (0xe85944, 100 B)
; [nakarest] the table itself: Viewable slot 0xee (table 0xe85944, 24 entries, InitializeMurai),
; [nakarest] 24 entry pointers x 4 bytes.
Murai_ViewableTable_0EE:	.incbin "includes/generated/naka_technichord_part.bin", 0x3C76, 0x64
; [nakarest] naka_technichord_part+0x3cda  +0x3cda..+0x3d0a (0xe859a8, 48 B)
; [nakarest] the table itself: Viewable slot 0xef (table 0xe859a8, 11 entries, InitializeMurai),
; [nakarest] 11 entry pointers x 4 bytes.
Murai_ViewableTable_0EF:	.incbin "includes/generated/naka_technichord_part.bin", 0x3CDA, 0x30
; [nakarest] naka_technichord_part+0x3d0a  +0x3d0a..+0x3d26 (0xe859d8, 28 B)
; [nakarest] the table itself: Viewable slot 0xf0 (table 0xe859d8, 6 entries, InitializeMurai),
; [nakarest] 6 entry pointers x 4 bytes.
Murai_ViewableTable_0F0:	.incbin "includes/generated/naka_technichord_part.bin", 0x3D0A, 0x1C
; [nakarest] naka_technichord_part+0x3d26  +0x3d26..+0x3d7c (0xe859f4, 86 B)
; [nakarest] the table itself: ResName slot 0x302 (table 0xe859f4, 20 entries, InitializeMurai),
; [nakarest] 20 entry pointers x 4 bytes.
Murai_ResNameTable_302:	.incbin "includes/generated/naka_technichord_part.bin", 0x3D26, 0x56
; [nakarest] naka_technichord_part+0x3d7c  +0x3d7c..+0x3dc0 (0xe85a4a, 68 B)
; [nakarest] name strings, entries 0-19 of ResName slot 0x302 (table 0xe859f4, 20 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0x2): "", "", "Sdmenu2", "", "", "", ....
	.incbin "includes/generated/naka_technichord_part.bin", 0x3D7C, 0x44
; [nakarest] naka_technichord_part+0x3dc0  +0x3dc0..+0x3e00 (0xe85a8e, 64 B)
; [nakarest] the table itself: ResName slot 0x303 (table 0xe85a8e, 84 entries, InitializeMurai),
; [nakarest] 84 entry pointers x 4 bytes.
Murai_ResNameTable_303:	.incbin "includes/generated/naka_technichord_part.bin", 0x3DC0, 0x40
	.long NakaWidget_Sdpart_16_AcStrRadioBox_Name
	.long NakaWidget_Sdpart_17_AcStrRadioBox_Name
	.long NakaWidget_Sdpart_18_AcStrRadioBox_Name
	.long NakaWidget_Sdpart_19_AcStrRadioBox_Name
	.long NakaWidget_Sdpart_20_VwEditSwBox_Name
	.long NakaWidget_Sdpart_21_VwEditSwBox_Name
	.long NakaWidget_Sdpart_22_VwEditSwBox_Name
	.long NakaWidget_Sdpart_23_VwEditSwBox_Name
	.long NakaWidget_Sdpart_24_VwEditSwBox_Name
	.long NakaWidget_Sdpart_25_VwEditSwBox_Name
	.long NakaWidget_Sdpart_26_VwEditSwBox_Name
	.long NakaWidget_Sdpart_27_VwEditSwBox_Name
	.long NakaWidget_Sdpart_28_IvSdpart_Name
	.long NakaWidget_SdpartMain_Name
	.long NakaWidget_Sdpart_30_AcLswPartEditBox_Name
	.long NakaWidget_Sdpart_31_AcLswPartEditBox_Name
	.long NakaWidget_Sdpart_32_AcLswPartEditBox_Name
	.long NakaWidget_Sdpart_33_AcLswPartEditBox_Name
	.long NakaWidget_Sdpart_34_AcLswPartEditBox_Name
	.long NakaWidget_Sdpart_35_VwBox_Name
	.long NakaWidget_Sdpart_36_AcLswPartEditBox_Name
	.long NakaWidget_Sdpart_37_AcLswPartEditBox_Name
	.long NakaWidget_Sdpart_38_AcLswPartEditBox_Name
	.long NakaWidget_Sdpart_39_AcLswPartEditBox_Name
	.long NakaWidget_Sdpart_40_AcLswPartEditBox_Name
	.long NakaWidget_Sdpart_41_AcLswPartEditBox_Name
	.long NakaWidget_Sdpart_42_AcVolPartEditBox_Name
	.long NakaWidget_SdpartVol_Name
	.long NakaWidget_Sdpart_44_AcIndexEditSw_Name
	.long NakaWidget_Sdpart_45_VwBox_Name
	.long NakaWidget_Sdpart_46_AcVolPartEditBox_Name
	.long NakaWidget_SdpartPan_Name
	.long NakaWidget_Sdpart_48_VwBox_Name
	.long NakaWidget_Sdpart_49_AcLswPartEditBox_Name
	.long NakaWidget_Sdpart_50_Label_Name
	.long NakaWidget_Sdpart_51_AcLswPartPan_Name
	.long NakaWidget_Sdpart_52_AcIndexEditSw_Name
	.long NakaWidget_Sdpart_53_VwBox_Name
	.long NakaWidget_SdpartEff_Name
	.long NakaWidget_Sdpart_55_AcLswPartEditBox_Name
	.long NakaWidget_Sdpart_56_AcLswPartEditBox_Name
	.long NakaWidget_Sdpart_57_AcLswPartEditBox_Name
	.long NakaWidget_Sdpart_58_AcIndexEditSw_Name
	.long NakaWidget_Sdpart_59_VwBox_Name
	.long NakaWidget_SdpartSus_Name
	.long NakaWidget_Sdpart_61_AcIndexEditSw_Name
	.long NakaWidget_Sdpart_62_AcLswPartEditBox_Name
	.long NakaWidget_Sdpart_63_AcLswPartEditBox_Name
	.long NakaWidget_Sdpart_64_VwBox_Name
	.long NakaWidget_SdpartKey_Name
	.long NakaWidget_Sdpart_66_AcLswPartEditBox_Name
	.long NakaWidget_Sdpart_67_AcIndexEditSw_Name
	.long NakaWidget_Sdpart_68_VwBox_Name
	.long NakaWidget_SdpartTun_Name
	.long NakaWidget_Sdpart_70_AcLswPartEditBox_Name
	.long NakaWidget_Sdpart_71_AcIndexEditSw_Name
	.long NakaWidget_Sdpart_72_VwBox_Name
	.long NakaWidget_SdpartBnd_Name
	.long NakaWidget_Sdpart_74_AcLswPartEditBox_Name
	.long NakaWidget_Sdpart_75_AcIndexEditSw_Name
	.long NakaWidget_Sdpart_76_VwBox_Name
	.long NakaWidget_SdpartOth_Name
	.long NakaWidget_Sdpart_78_AcLswPartEditBox_Name
	.long NakaWidget_Sdpart_79_AcLswPartEditBox_Name
; [nakarest] naka_technichord_part+0x3f00  +0x3f00..+0x3f16 (0xe85bce, 22 B)
; [nakarest] 6 B at 0xe85bde: the end marker of ResName slot 0x303 (table 0xe85a8e, 84 entries, InitializeMurai) -- entry 84, a pointer to the empty string right after it ("", 00 ff), as every ResName table ends.
; [nakarest] Continues the table itself: ResName slot 0x303 (table 0xe85a8e, 84 entries,
; [nakarest] InitializeMurai), 84 entry pointers x 4 bytes (starts 0xe85a8e, 16 of its 336 bytes
; [nakarest] are here or later).
	.incbin "includes/generated/naka_technichord_part.bin", 0x3F00, 0x16
; [nakarest] naka_technichord_part+0x3f16  +0x3f16..+0x4022 (0xe85be4, 268 B)
; [nakarest] name strings, entries 0-83 of ResName slot 0x303 (table 0xe85a8e, 84 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0x3): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_technichord_part.bin", 0x3F16, 0x8
NakaWidget_Sdpart_79_AcLswPartEditBox_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3F1E, 0x2
NakaWidget_Sdpart_78_AcLswPartEditBox_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3F20, 0x2
NakaWidget_SdpartOth_Name:			.incbin "includes/generated/naka_technichord_part.bin", 0x3F22, 0xA
NakaWidget_Sdpart_76_VwBox_Name:		.incbin "includes/generated/naka_technichord_part.bin", 0x3F2C, 0x2
NakaWidget_Sdpart_75_AcIndexEditSw_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3F2E, 0x2
NakaWidget_Sdpart_74_AcLswPartEditBox_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3F30, 0x2
NakaWidget_SdpartBnd_Name:			.incbin "includes/generated/naka_technichord_part.bin", 0x3F32, 0xA
NakaWidget_Sdpart_72_VwBox_Name:		.incbin "includes/generated/naka_technichord_part.bin", 0x3F3C, 0x2
NakaWidget_Sdpart_71_AcIndexEditSw_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3F3E, 0x2
NakaWidget_Sdpart_70_AcLswPartEditBox_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3F40, 0x2
NakaWidget_SdpartTun_Name:			.incbin "includes/generated/naka_technichord_part.bin", 0x3F42, 0xA
NakaWidget_Sdpart_68_VwBox_Name:		.incbin "includes/generated/naka_technichord_part.bin", 0x3F4C, 0x2
NakaWidget_Sdpart_67_AcIndexEditSw_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3F4E, 0x2
NakaWidget_Sdpart_66_AcLswPartEditBox_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3F50, 0x2
NakaWidget_SdpartKey_Name:			.incbin "includes/generated/naka_technichord_part.bin", 0x3F52, 0xA
NakaWidget_Sdpart_64_VwBox_Name:		.incbin "includes/generated/naka_technichord_part.bin", 0x3F5C, 0x2
NakaWidget_Sdpart_63_AcLswPartEditBox_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3F5E, 0x2
NakaWidget_Sdpart_62_AcLswPartEditBox_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3F60, 0x2
NakaWidget_Sdpart_61_AcIndexEditSw_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3F62, 0x2
NakaWidget_SdpartSus_Name:			.incbin "includes/generated/naka_technichord_part.bin", 0x3F64, 0xA
NakaWidget_Sdpart_59_VwBox_Name:		.incbin "includes/generated/naka_technichord_part.bin", 0x3F6E, 0x2
NakaWidget_Sdpart_58_AcIndexEditSw_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3F70, 0x2
NakaWidget_Sdpart_57_AcLswPartEditBox_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3F72, 0x2
NakaWidget_Sdpart_56_AcLswPartEditBox_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3F74, 0x2
NakaWidget_Sdpart_55_AcLswPartEditBox_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3F76, 0x2
NakaWidget_SdpartEff_Name:			.incbin "includes/generated/naka_technichord_part.bin", 0x3F78, 0xA
NakaWidget_Sdpart_53_VwBox_Name:		.incbin "includes/generated/naka_technichord_part.bin", 0x3F82, 0x2
NakaWidget_Sdpart_52_AcIndexEditSw_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3F84, 0x2
NakaWidget_Sdpart_51_AcLswPartPan_Name:		.incbin "includes/generated/naka_technichord_part.bin", 0x3F86, 0x2
NakaWidget_Sdpart_50_Label_Name:		.incbin "includes/generated/naka_technichord_part.bin", 0x3F88, 0x2
NakaWidget_Sdpart_49_AcLswPartEditBox_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3F8A, 0x2
NakaWidget_Sdpart_48_VwBox_Name:		.incbin "includes/generated/naka_technichord_part.bin", 0x3F8C, 0x2
NakaWidget_SdpartPan_Name:			.incbin "includes/generated/naka_technichord_part.bin", 0x3F8E, 0xA
NakaWidget_Sdpart_46_AcVolPartEditBox_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3F98, 0x2
NakaWidget_Sdpart_45_VwBox_Name:		.incbin "includes/generated/naka_technichord_part.bin", 0x3F9A, 0x2
NakaWidget_Sdpart_44_AcIndexEditSw_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3F9C, 0x2
NakaWidget_SdpartVol_Name:			.incbin "includes/generated/naka_technichord_part.bin", 0x3F9E, 0xA
NakaWidget_Sdpart_42_AcVolPartEditBox_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3FA8, 0x2
NakaWidget_Sdpart_41_AcLswPartEditBox_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3FAA, 0x2
NakaWidget_Sdpart_40_AcLswPartEditBox_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3FAC, 0x2
NakaWidget_Sdpart_39_AcLswPartEditBox_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3FAE, 0x2
NakaWidget_Sdpart_38_AcLswPartEditBox_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3FB0, 0x2
NakaWidget_Sdpart_37_AcLswPartEditBox_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3FB2, 0x2
NakaWidget_Sdpart_36_AcLswPartEditBox_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3FB4, 0x2
NakaWidget_Sdpart_35_VwBox_Name:		.incbin "includes/generated/naka_technichord_part.bin", 0x3FB6, 0x2
NakaWidget_Sdpart_34_AcLswPartEditBox_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3FB8, 0x2
NakaWidget_Sdpart_33_AcLswPartEditBox_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3FBA, 0x2
NakaWidget_Sdpart_32_AcLswPartEditBox_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3FBC, 0x2
NakaWidget_Sdpart_31_AcLswPartEditBox_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3FBE, 0x2
NakaWidget_Sdpart_30_AcLswPartEditBox_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3FC0, 0x2
NakaWidget_SdpartMain_Name:			.incbin "includes/generated/naka_technichord_part.bin", 0x3FC2, 0xC
NakaWidget_Sdpart_28_IvSdpart_Name:		.incbin "includes/generated/naka_technichord_part.bin", 0x3FCE, 0x2
NakaWidget_Sdpart_27_VwEditSwBox_Name:		.incbin "includes/generated/naka_technichord_part.bin", 0x3FD0, 0x2
NakaWidget_Sdpart_26_VwEditSwBox_Name:		.incbin "includes/generated/naka_technichord_part.bin", 0x3FD2, 0x2
NakaWidget_Sdpart_25_VwEditSwBox_Name:		.incbin "includes/generated/naka_technichord_part.bin", 0x3FD4, 0x2
NakaWidget_Sdpart_24_VwEditSwBox_Name:		.incbin "includes/generated/naka_technichord_part.bin", 0x3FD6, 0x2
NakaWidget_Sdpart_23_VwEditSwBox_Name:		.incbin "includes/generated/naka_technichord_part.bin", 0x3FD8, 0x2
NakaWidget_Sdpart_22_VwEditSwBox_Name:		.incbin "includes/generated/naka_technichord_part.bin", 0x3FDA, 0x2
NakaWidget_Sdpart_21_VwEditSwBox_Name:		.incbin "includes/generated/naka_technichord_part.bin", 0x3FDC, 0x2
NakaWidget_Sdpart_20_VwEditSwBox_Name:		.incbin "includes/generated/naka_technichord_part.bin", 0x3FDE, 0x2
NakaWidget_Sdpart_19_AcStrRadioBox_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3FE0, 0x2
NakaWidget_Sdpart_18_AcStrRadioBox_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3FE2, 0x2
NakaWidget_Sdpart_17_AcStrRadioBox_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3FE4, 0x2
NakaWidget_Sdpart_16_AcStrRadioBox_Name:	.incbin "includes/generated/naka_technichord_part.bin", 0x3FE6, 0x3C
; [nakarest] naka_technichord_part+0x4022  +0x4022..+0x4038 (0xe85cf0, 22 B)
; [nakarest] the table itself: ResName slot 0x304 (table 0xe85cf0, 4 entries, InitializeMurai),
; [nakarest] 4 entry pointers x 4 bytes.
InitializeMurai_PtrTable:	.incbin "includes/generated/naka_technichord_part.bin", 0x4022, 0x16
; [nakarest] naka_technichord_part+0x4038  +0x4038..+0x4046 (0xe85d06, 14 B)
; [nakarest] name strings, entries 0-3 of ResName slot 0x304 (table 0xe85cf0, 4 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0x4): "", "", "", "Sdmtune".
	.incbin "includes/generated/naka_technichord_part.bin", 0x4038, 0xE
; [nakarest] naka_technichord_part+0x4046  +0x4046..+0x4124 (0xe85d14, 222 B)
; [nakarest] the table itself: ResName slot 0x305 (table 0xe85d14, 54 entries, InitializeMurai),
; [nakarest] 54 entry pointers x 4 bytes.
InitializeMurai_PtrTable_2:	.incbin "includes/generated/naka_technichord_part.bin", 0x4046, 0xDE
; [nakarest] naka_technichord_part+0x4124  +0x4124..+0x423c (0xe85df2, 280 B)
; [nakarest] name strings, entries 0-53 of ResName slot 0x305 (table 0xe85d14, 54 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0x5): "", "", "", "", "", "", ....
	.incbin "includes/generated/naka_technichord_part.bin", 0x4124, 0x118
; [nakarest] naka_technichord_part+0x423c  +0x423c..+0x424e (0xe85f0a, 18 B)
; [nakarest] the table itself: ResName slot 0x307 (table 0xe85f0a, 3 entries, InitializeMurai),
; [nakarest] 3 entry pointers x 4 bytes.
InitializeMurai_PtrTable_3:	.incbin "includes/generated/naka_technichord_part.bin", 0x423C, 0x12
; [nakarest] naka_technichord_part+0x424e  +0x424e..+0x425c (0xe85f1c, 14 B)
; [nakarest] name strings, entries 0-2 of ResName slot 0x307 (table 0xe85f0a, 3 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0x7): "", "", "Sdlfthld".
	.incbin "includes/generated/naka_technichord_part.bin", 0x424E, 0xE
; [nakarest] naka_technichord_part+0x425c  +0x425c..+0x4272 (0xe85f2a, 22 B)
; [nakarest] the table itself: ResName slot 0x308 (table 0xe85f2a, 4 entries, InitializeMurai),
; [nakarest] 4 entry pointers x 4 bytes.
InitializeMurai_PtrTable_4:	.incbin "includes/generated/naka_technichord_part.bin", 0x425C, 0x16
; [nakarest] naka_technichord_part+0x4272  +0x4272..+0x4280 (0xe85f40, 14 B)
; [nakarest] name strings, entries 0-3 of ResName slot 0x308 (table 0xe85f2a, 4 entries,
; [nakarest] InitializeMurai) (names for Viewable slot 0x8): "", "", "", "Sdmixer".
	.incbin "includes/generated/naka_technichord_part.bin", 0x4272, 0xE

; External label offsets within the binary blob above.
