
; Composer & Style Convert screen widgets (239 widgets, 12336 bytes)
; Source: maincpu/ui_widgets/naka_composer_style.c (C struct with named fields)
; -----------------------------------------------------------------------------
; [nakarest_retype] registered NAKA tables: naka_composer_style
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
; Viewable slot 0x10: RegObjTabl 0x1600010, ViewableProc, 0x3, 0xe1b4e2,
; 0x10 in InitializeSuna (storage/flash_floppy_handlers.s), i.e.
; RegisterObjectTable stores {class, proc, 3, table} at 0x27ed2 +
; 14*0x10. Element 0 is named "StylCnvWaitScreen" in ResName slot 0x310.
; Links: all 3 records consistent.
;
; Viewable slot 0x11: RegObjTabl 0x1600010, ViewableProc, 0x8, 0xe1b4f2,
; 0x11 in InitializeSuna (storage/flash_floppy_handlers.s), i.e.
; RegisterObjectTable stores {class, proc, 8, table} at 0x27ed2 +
; 14*0x11. Element 0 is named "StylCnvModlScreen" in ResName slot 0x311.
; Links: all 8 records consistent.
;
; Viewable slot 0x12: RegObjTabl 0x1600010, ViewableProc, 0x7, 0xe1b516,
; 0x12 in InitializeSuna (storage/flash_floppy_handlers.s), i.e.
; RegisterObjectTable stores {class, proc, 7, table} at 0x27ed2 +
; 14*0x12. Element 0 is named "StylCnvCnvtScreen" in ResName slot 0x312.
; Links: all 7 records consistent.
;
; Viewable slot 0x13: RegObjTabl 0x1600010, ViewableProc, 0x4, 0xe1b536,
; 0x13 in InitializeSuna (storage/flash_floppy_handlers.s), i.e.
; RegisterObjectTable stores {class, proc, 4, table} at 0x27ed2 +
; 14*0x13. Element 0 is named "StylCnvStorScreen" in ResName slot 0x313.
; Links: all 4 records consistent.
;
; Viewable slot 0x14: RegObjTabl 0x1600010, ViewableProc, 0x4, 0xe1b54a,
; 0x14 in InitializeSuna (storage/flash_floppy_handlers.s), i.e.
; RegisterObjectTable stores {class, proc, 4, table} at 0x27ed2 +
; 14*0x14. Element 0 is named "StylCnvTxtScreen" in ResName slot 0x314.
; Links: all 4 records consistent.
;
; Viewable slot 0x15: RegObjTabl 0x1600010, ViewableProc, 0x8, 0xe1b55e,
; 0x15 in InitializeSuna (storage/flash_floppy_handlers.s), i.e.
; RegisterObjectTable stores {class, proc, 8, table} at 0x27ed2 +
; 14*0x15. Element 0 is named "StylCnvSelScreen" in ResName slot 0x315.
; Links: all 8 records consistent.
;
; Viewable slot 0x16: RegObjTabl 0x1600010, ViewableProc, 0x7, 0xe1b582,
; 0x16 in InitializeSuna (storage/flash_floppy_handlers.s), i.e.
; RegisterObjectTable stores {class, proc, 7, table} at 0x27ed2 +
; 14*0x16. Element 0 is named "StylCnvContScreen" in ResName slot 0x316.
; Links: all 7 records consistent.
;
; Viewable slot 0xb0: RegObjTabl 0x1600010, ViewableProc, 0x12,
; 0xe1b5a2, 0xb0 in InitializeSuna (storage/flash_floppy_handlers.s),
; i.e. RegisterObjectTable stores {class, proc, 18, table} at 0x27ed2 +
; 14*0xb0. Element 0 is named "CmpMenuScreen" in ResName slot 0x3b0.
; Links: all 18 records consistent.
;
; Viewable slot 0xb1: RegObjTabl 0x1600010, ViewableProc, 0xc, 0xe1b5ee,
; 0xb1 in InitializeSuna (storage/flash_floppy_handlers.s), i.e.
; RegisterObjectTable stores {class, proc, 12, table} at 0x27ed2 +
; 14*0xb1. Element 0 is named "CmpBkslScreen" in ResName slot 0x3b1.
; Links: all 12 records consistent.
;
; Viewable slot 0xb2: RegObjTabl 0x1600010, ViewableProc, 0x16,
; 0xe1b622, 0xb2 in InitializeSuna (storage/flash_floppy_handlers.s),
; i.e. RegisterObjectTable stores {class, proc, 22, table} at 0x27ed2 +
; 14*0xb2. Element 0 is named "CmpBkslSScreen" in ResName slot 0x3b2.
; Links: all 22 records consistent.
;
; Viewable slot 0xb3: RegObjTabl 0x1600010, ViewableProc, 0x5, 0xe1b67e,
; 0xb3 in InitializeSuna (storage/flash_floppy_handlers.s), i.e.
; RegisterObjectTable stores {class, proc, 5, table} at 0x27ed2 +
; 14*0xb3. Element 0 is named "CmpNamingScreen" in ResName slot 0x3b3.
; Links: all 5 records consistent.
;
; Viewable slot 0xb4: RegObjTabl 0x1600010, ViewableProc, 0x12,
; 0xe1b696, 0xb4 in InitializeSuna (storage/flash_floppy_handlers.s),
; i.e. RegisterObjectTable stores {class, proc, 18, table} at 0x27ed2 +
; 14*0xb4. Element 0 is named "CmpSetScreen" in ResName slot 0x3b4.
; Links: all 18 records consistent.
;
; Viewable slot 0xb5: RegObjTabl 0x1600010, ViewableProc, 0x1f,
; 0xe1b6e2, 0xb5 in InitializeSuna (storage/flash_floppy_handlers.s),
; i.e. RegisterObjectTable stores {class, proc, 31, table} at 0x27ed2 +
; 14*0xb5. Element 0 is named "CmpRealScreen" in ResName slot 0x3b5.
; Links: 7 of 31 records have a disagreeing link (elements 23-29);
; elements 24-28 point outside the program ROM (RAM records).
;
; Viewable slot 0xb6: RegObjTabl 0x1600010, ViewableProc, 0x1, 0xe1b762,
; 0xb6 in InitializeSuna (storage/flash_floppy_handlers.s), i.e.
; RegisterObjectTable stores {class, proc, 1, table} at 0x27ed2 +
; 14*0xb6. Element 0 is named "" in ResName slot 0x3b6. Links: all 1
; records consistent.
;
; Viewable slot 0xb7: RegObjTabl 0x1600010, ViewableProc, 0x6, 0xe1b76a,
; 0xb7 in InitializeSuna (storage/flash_floppy_handlers.s), i.e.
; RegisterObjectTable stores {class, proc, 6, table} at 0x27ed2 +
; 14*0xb7. Element 0 is named "CmpBalScreen" in ResName slot 0x3b7.
; Links: all 6 records consistent.
;
; Viewable slot 0xb8: RegObjTabl 0x1600010, ViewableProc, 0x21,
; 0xe1b786, 0xb8 in InitializeSuna (storage/flash_floppy_handlers.s),
; i.e. RegisterObjectTable stores {class, proc, 33, table} at 0x27ed2 +
; 14*0xb8. Element 0 is named "CmpNcpScreen" in ResName slot 0x3b8.
; Links: 9 of 33 records have a disagreeing link (elements 17-18, 25-27,
; 29-32); elements 18, 26-27, 30-31 point outside the program ROM (RAM
; records).
;
; Viewable slot 0xb9: RegObjTabl 0x1600010, ViewableProc, 0x25,
; 0xe1b80e, 0xb9 in InitializeSuna (storage/flash_floppy_handlers.s),
; i.e. RegisterObjectTable stores {class, proc, 37, table} at 0x27ed2 +
; 14*0xb9. Element 0 is named "S2CScreen" in ResName slot 0x3b9. Links:
; 8 of 37 records have a disagreeing link (elements 23-24, 27-32);
; elements 24, 28, 31 point outside the program ROM (RAM records).
;
; Viewable slot 0xba: RegObjTabl 0x1600010, ViewableProc, 0xe, 0xe1b8a6,
; 0xba in InitializeSuna (storage/flash_floppy_handlers.s), i.e.
; RegisterObjectTable stores {class, proc, 14, table} at 0x27ed2 +
; 14*0xba. Element 0 is named "CmpEasyScreen" in ResName slot 0x3ba.
; Links: all 14 records consistent.
;
; Viewable slot 0xbb: RegObjTabl 0x1600010, ViewableProc, 0x4, 0xe1b8e2,
; 0xbb in InitializeSuna (storage/flash_floppy_handlers.s), i.e.
; RegisterObjectTable stores {class, proc, 4, table} at 0x27ed2 +
; 14*0xbb. Element 0 is named "CmpBendScreen" in ResName slot 0x3bb.
; Links: all 4 records consistent.
;
; Viewable slot 0xbd: RegObjTabl 0x1600010, ViewableProc, 0xb, 0xe1b8f6,
; 0xbd in InitializeSuna (storage/flash_floppy_handlers.s), i.e.
; RegisterObjectTable stores {class, proc, 11, table} at 0x27ed2 +
; 14*0xbd. Element 0 is named "CmpModeScreen" in ResName slot 0x3bd.
; Links: all 11 records consistent.
;
; Viewable slot 0xbe: RegObjTabl 0x1600010, ViewableProc, 0x21,
; 0xe1b926, 0xbe in InitializeSuna (storage/flash_floppy_handlers.s),
; i.e. RegisterObjectTable stores {class, proc, 33, table} at 0x27ed2 +
; 14*0xbe. Element 0 is named "CmpCstmCpScreen" in ResName slot 0x3be.
; Links: all 33 records consistent.
;
; Viewable slot 0xc8: RegObjTabl 0x1600010, ViewableProc, 0x1b,
; 0xe1b9ae, 0xc8 in InitializeSuna (storage/flash_floppy_handlers.s),
; i.e. RegisterObjectTable stores {class, proc, 27, table} at 0x27ed2 +
; 14*0xc8. Element 0 is named "MspBkslScreen" in ResName slot 0x3c8.
; Links: all 27 records consistent.
;
; Function slot 0x404: RegObjTabl 0x1600001, FunctionProc, 0x1,
; 0xe176dc, 0x404 in InitializeSuna (storage/flash_floppy_handlers.s),
; i.e. RegisterObjectTable stores {class, proc, 1, table} at 0x27ed2 +
; 14*0x404.
; -----------------------------------------------------------------------------

; [nakarest] NakaStr_PaintArrowProc_Empty  +0x0..+0x2 (0xe176e4, 2 B)
; [nakarest] purpose not established: layout of 2 B at 0xe176e4 not derived; readers below
; [nakarest] Readers: source references MTStr_CmpNameSet
; [nakarest] (ui_widgets/naka_property_descriptors.s: `.long NakaStr_PaintArrowProc_Empty + 2`);
; [nakarest] 1 data word in MTStr_CmpNameSet (at 0xe176e0), which is read by
; [nakarest] NakaMethodTable_PtrsStart (ui_widgets/naka_property_descriptors.s: `.long
; [nakarest] MTStr_CmpNameSet`).
NakaStr_PaintArrowProc_Empty:
	.incbin "includes/generated/naka_composer_style.bin", 0x0, 0x2
; [nakarest] naka_composer_style+0x2  +0x2..+0x12 (0xe176e6, 16 B)
; [nakarest] name string, entry 0 of Function slot 0x404 (table 0xe176dc, 1 entries,
; [nakarest] InitializeSuna) (names for Function slot 0x104): "PaintArrowProc".
	.incbin "includes/generated/naka_composer_style.bin", 0x2, 0x10
; [nakarest] naka_composer_style+0x12  +0x12..+0x90 (0xe176f6, 126 B)
; [nakarest] widget records, elements 0-2 of Viewable slot 0x10 (table 0xe1b4e2, 3 entries,
; [nakarest] InitializeSuna) ("StylCnvWaitScreen"): TtlScreen (42 B), VwBox (28 B),
; [nakarest] AcLanguageText (42 B). 1 text the records point at (Viewable slot 0x10 (table
; [nakarest] 0xe1b4e2, 3 entries, InitializeSuna)): "STYLE CONVERT" (TtlScreen.title of element
; [nakarest] 0).
NakaWidget_StylCnvWaitScreen:			.incbin "includes/generated/naka_composer_style.bin", 0x12, 0x38
NakaWidget_StylCnvWaitScreen_1_VwBox:		.incbin "includes/generated/naka_composer_style.bin", 0x4A, 0x1C
NakaWidget_StylCnvWaitScreen_2_AcLanguageText:	.incbin "includes/generated/naka_composer_style.bin", 0x66, 0x2A
; [nakarest] naka_composer_style+0x90  +0x90..+0x1f6 (0xe17774, 358 B)
; [nakarest] widget records, elements 0-7 of Viewable slot 0x11 (table 0xe1b4f2, 8 entries,
; [nakarest] InitializeSuna) ("StylCnvModlScreen"): TtlScreen (42 B), IvMainEditSw (26 B),
; [nakarest] PsParaListBox (42 B), VwEditSwBox (44 B) x3, VwWideESBox (46 B), PsStylCnvVer (36
; [nakarest] B). 5 texts the records point at (Viewable slot 0x11 (table 0xe1b4f2, 8 entries,
; [nakarest] InitializeSuna)): "STYLE TYPE SELECT" (TtlScreen.title of element 0); "PREV"
; [nakarest] (VwEditSwBox.str of element 3); "" (VwWideESBox.str of element 4); "NEXT"
; [nakarest] (VwEditSwBox.str of element 5); ....
NakaWidget_StylCnvModlScreen:			.incbin "includes/generated/naka_composer_style.bin", 0x90, 0x3C
NakaWidget_StylCnvModlScreen_1_IvMainEditSw:	.incbin "includes/generated/naka_composer_style.bin", 0xCC, 0x1A
NakaWidget_StylCnvModlBox:			.incbin "includes/generated/naka_composer_style.bin", 0xE6, 0x2A
NakaWidget_StylCnvModlScreen_3_VwEditSwBox:	.incbin "includes/generated/naka_composer_style.bin", 0x110, 0x32
NakaWidget_StylCnvModlScreen_4_VwWideESBox:	.incbin "includes/generated/naka_composer_style.bin", 0x142, 0x30
NakaWidget_StylCnvModlScreen_5_VwEditSwBox:	.incbin "includes/generated/naka_composer_style.bin", 0x172, 0x32
NakaWidget_StylCnvModlScreen_6_VwEditSwBox:	.incbin "includes/generated/naka_composer_style.bin", 0x1A4, 0x2E
NakaWidget_StylCnvVer:				.incbin "includes/generated/naka_composer_style.bin", 0x1D2, 0x24
; [nakarest] naka_composer_style+0x1f6  +0x1f6..+0x334 (0xe178da, 318 B)
; [nakarest] widget records, elements 0-6 of Viewable slot 0x12 (table 0xe1b516, 7 entries,
; [nakarest] InitializeSuna) ("StylCnvCnvtScreen"): TtlScreen (42 B), IvMainEditSw (26 B),
; [nakarest] PsParaListBox (42 B), VwEditSwBox (44 B) x3, VwWideESBox (46 B). 5 texts the
; [nakarest] records point at (Viewable slot 0x12 (table 0xe1b516, 7 entries, InitializeSuna)):
; [nakarest] "STYLE CONVERT" (TtlScreen.title of element 0); "PREV" (VwEditSwBox.str of element
; [nakarest] 3); "" (VwWideESBox.str of element 4); "NEXT" (VwEditSwBox.str of element 5); ....
NakaWidget_StylCnvCnvtScreen:			.incbin "includes/generated/naka_composer_style.bin", 0x1F6, 0x38
NakaWidget_StylCnvCnvtScreen_1_IvMainEditSw:	.incbin "includes/generated/naka_composer_style.bin", 0x22E, 0x1A
NakaWidget_StylCnvCnvtBox:			.incbin "includes/generated/naka_composer_style.bin", 0x248, 0x2A
NakaWidget_StylCnvCnvtScreen_3_VwEditSwBox:	.incbin "includes/generated/naka_composer_style.bin", 0x272, 0x32
NakaWidget_StylCnvCnvtScreen_4_VwWideESBox:	.incbin "includes/generated/naka_composer_style.bin", 0x2A4, 0x30
NakaWidget_StylCnvCnvtScreen_5_VwEditSwBox:	.incbin "includes/generated/naka_composer_style.bin", 0x2D4, 0x32
NakaWidget_StylCnvCnvtScreen_6_VwEditSwBox:	.incbin "includes/generated/naka_composer_style.bin", 0x306, 0x2E
; [nakarest] naka_composer_style+0x334  +0x334..+0x410 (0xe17a18, 220 B)
; [nakarest] widget records, elements 0-3 of Viewable slot 0x13 (table 0xe1b536, 4 entries,
; [nakarest] InitializeSuna) ("StylCnvStorScreen"): TtlScreen (42 B), AcRamEditBox (58 B),
; [nakarest] AcIndexWideES (42 B), AcFuncEditSw (44 B). 2 texts the records point at (Viewable
; [nakarest] slot 0x13 (table 0xe1b536, 4 entries, InitializeSuna)): "STORAGE DATA"
; [nakarest] (TtlScreen.title of element 0); " Data Storage to :" (AcRamEditBox.caption of
; [nakarest] element 1).
NakaWidget_StylCnvStorScreen:			.incbin "includes/generated/naka_composer_style.bin", 0x334, 0x38
NakaWidget_StylCnvStorScreen_1_AcRamEditBox:	.incbin "includes/generated/naka_composer_style.bin", 0x36C, 0x4E
NakaWidget_StylCnvStorScreen_2_AcIndexWideES:	.incbin "includes/generated/naka_composer_style.bin", 0x3BA, 0x2A
NakaWidget_StylCnvStorScreen_3_AcFuncEditSw:	.incbin "includes/generated/naka_composer_style.bin", 0x3E4, 0x2C
; [nakarest] naka_composer_style+0x410  +0x410..+0x4a4 (0xe17af4, 148 B)
; [nakarest] widget records, elements 0-3 of Viewable slot 0x14 (table 0xe1b54a, 4 entries,
; [nakarest] InitializeSuna) ("StylCnvTxtScreen"): TtlScreen (42 B), VwBox (28 B), PSSCTxtBox2
; [nakarest] (38 B), IvMainEditSw (26 B). 1 text the records point at (Viewable slot 0x14 (table
; [nakarest] 0xe1b54a, 4 entries, InitializeSuna)): "STYLE CONVERT" (TtlScreen.title of element
; [nakarest] 0).
NakaWidget_StylCnvTxtScreen:			.incbin "includes/generated/naka_composer_style.bin", 0x410, 0x38
NakaWidget_StylCnvTxtScreen_1_VwBox:		.incbin "includes/generated/naka_composer_style.bin", 0x448, 0x1C
NakaWidget_StylCnvTxtScreen_2_PSSCTxtBox2:	.incbin "includes/generated/naka_composer_style.bin", 0x464, 0x26
NakaWidget_StylCnvTxtScreen_3_IvMainEditSw:	.incbin "includes/generated/naka_composer_style.bin", 0x48A, 0x1A
; [nakarest] naka_composer_style+0x4a4  +0x4a4..+0x606 (0xe17b88, 354 B)
; [nakarest] widget records, elements 0-7 of Viewable slot 0x15 (table 0xe1b55e, 8 entries,
; [nakarest] InitializeSuna) ("StylCnvSelScreen"): TtlScreen (42 B), IvMainEditSw (26 B),
; [nakarest] PsParaListBox (42 B), VwEditSwBox (44 B) x3, VwWideESBox (46 B), PsSCTxtBox (36 B).
; [nakarest] 5 texts the records point at (Viewable slot 0x15 (table 0xe1b55e, 8 entries,
; [nakarest] InitializeSuna)): "STYLE CONVERT" (TtlScreen.title of element 0); "PREV"
; [nakarest] (VwEditSwBox.str of element 3); "" (VwWideESBox.str of element 4); "NEXT"
; [nakarest] (VwEditSwBox.str of element 5); ....
NakaWidget_StylCnvSelScreen:			.incbin "includes/generated/naka_composer_style.bin", 0x4A4, 0x38
NakaWidget_StylCnvSelScreen_1_IvMainEditSw:	.incbin "includes/generated/naka_composer_style.bin", 0x4DC, 0x1A
NakaWidget_StylCnvSelBox:			.incbin "includes/generated/naka_composer_style.bin", 0x4F6, 0x2A
NakaWidget_StylCnvSelScreen_3_VwEditSwBox:	.incbin "includes/generated/naka_composer_style.bin", 0x520, 0x32
NakaWidget_StylCnvSelScreen_4_VwWideESBox:	.incbin "includes/generated/naka_composer_style.bin", 0x552, 0x30
NakaWidget_StylCnvSelScreen_5_VwEditSwBox:	.incbin "includes/generated/naka_composer_style.bin", 0x582, 0x32
NakaWidget_StylCnvSelScreen_6_VwEditSwBox:	.incbin "includes/generated/naka_composer_style.bin", 0x5B4, 0x2E
NakaWidget_StylCnvSelScreen_7_PsSCTxtBox:	.incbin "includes/generated/naka_composer_style.bin", 0x5E2, 0x24
; [nakarest] naka_composer_style+0x606  +0x606..+0x722 (0xe17cea, 284 B)
; [nakarest] widget records, elements 0-6 of Viewable slot 0x16 (table 0xe1b582, 7 entries,
; [nakarest] InitializeSuna) ("StylCnvContScreen"): TtlScreen (42 B), IvMainEditSw (26 B), VwBox
; [nakarest] (28 B), Label (32 B) x2, VwEditSwBox (44 B) x2. 5 texts the records point at
; [nakarest] (Viewable slot 0x16 (table 0xe1b582, 7 entries, InitializeSuna)): "STYLE CONVERT"
; [nakarest] (TtlScreen.title of element 0); "Continue" (Label.str of element 3); "Next ?"
; [nakarest] (Label.str of element 4); "" (VwEditSwBox.str of element 5); ....
NakaWidget_StylCnvContScreen:			.incbin "includes/generated/naka_composer_style.bin", 0x606, 0x38
NakaWidget_StylCnvContScreen_1_IvMainEditSw:	.incbin "includes/generated/naka_composer_style.bin", 0x63E, 0x1A
NakaWidget_StylCnvContScreen_2_VwBox:		.incbin "includes/generated/naka_composer_style.bin", 0x658, 0x1C
NakaWidget_StylCnvContScreen_3_Label:		.incbin "includes/generated/naka_composer_style.bin", 0x674, 0x2A
NakaWidget_StylCnvContScreen_4_Label:		.incbin "includes/generated/naka_composer_style.bin", 0x69E, 0x28
NakaWidget_StylCnvContScreen_5_VwEditSwBox:	.incbin "includes/generated/naka_composer_style.bin", 0x6C6, 0x2E
NakaWidget_StylCnvContScreen_6_VwEditSwBox:	.incbin "includes/generated/naka_composer_style.bin", 0x6F4, 0x2E
; [nakarest] naka_composer_style+0x722  +0x722..+0xa8c (0xe17e06, 874 B)
; [nakarest] widget records, elements 0-17 of Viewable slot 0xb0 (table 0xe1b5a2, 18 entries,
; [nakarest] InitializeSuna) ("CmpMenuScreen"): TtlScreen (42 B), AcTitleMenu (54 B) x6, Line
; [nakarest] (26 B) x4, Label (32 B) x2, IvMainEditSw (26 B), VwMenuBox (50 B) x3, IvExitMode
; [nakarest] (26 B). 12 texts the records point at (Viewable slot 0xb0 (table 0xe1b5a2, 18
; [nakarest] entries, InitializeSuna)): "COMPOSER MENU" (TtlScreen.title of element 0); "BEND
; [nakarest] RANGE SET" (AcTitleMenu.str of element 1); "EASY COMPOSER" (AcTitleMenu.str of
; [nakarest] element 2); "PATTERN COPY" (AcTitleMenu.str of element 3); ....
NakaWidget_CmpMenuScreen:			.incbin "includes/generated/naka_composer_style.bin", 0x722, 0x38
NakaWidget_CmpMenuScreen_1_AcTitleMenu:		.incbin "includes/generated/naka_composer_style.bin", 0x75A, 0x46
NakaWidget_CmpMenuScreen_2_AcTitleMenu:		.incbin "includes/generated/naka_composer_style.bin", 0x7A0, 0x44
NakaWidget_CmpMenuScreen_3_AcTitleMenu:		.incbin "includes/generated/naka_composer_style.bin", 0x7E4, 0x44
NakaWidget_CmpMenuScreen_4_AcTitleMenu:		.incbin "includes/generated/naka_composer_style.bin", 0x828, 0x42
NakaWidget_CmpMenuScreen_5_AcTitleMenu:		.incbin "includes/generated/naka_composer_style.bin", 0x86A, 0x4C
NakaWidget_CmpMenuScreen_6_AcTitleMenu:		.incbin "includes/generated/naka_composer_style.bin", 0x8B6, 0x4C
NakaWidget_CmpMenuScreen_7_Line:		.incbin "includes/generated/naka_composer_style.bin", 0x902, 0x1A
NakaWidget_CmpMenuScreen_8_Line:		.incbin "includes/generated/naka_composer_style.bin", 0x91C, 0x1A
NakaWidget_CmpMenuScreen_9_Line:		.incbin "includes/generated/naka_composer_style.bin", 0x936, 0x1A
NakaWidget_CmpMenuScreen_10_Line:		.incbin "includes/generated/naka_composer_style.bin", 0x950, 0x1A
NakaWidget_CmpMenuScreen_11_Label:		.incbin "includes/generated/naka_composer_style.bin", 0x96A, 0x2A
NakaWidget_CmpMenuScreen_12_Label:		.incbin "includes/generated/naka_composer_style.bin", 0x994, 0x28
NakaWidget_CmpMenuScreen_13_IvMainEditSw:	.incbin "includes/generated/naka_composer_style.bin", 0x9BC, 0x1A
NakaWidget_CmpMenuScreen_14_VwMenuBox:		.incbin "includes/generated/naka_composer_style.bin", 0x9D6, 0x34
NakaWidget_CmpMenuScreen_15_VwMenuBox:		.incbin "includes/generated/naka_composer_style.bin", 0xA0A, 0x34
NakaWidget_CmpMenuScreen_16_VwMenuBox:		.incbin "includes/generated/naka_composer_style.bin", 0xA3E, 0x34
NakaWidget_CmpMenuScreen_17_IvExitMode:		.incbin "includes/generated/naka_composer_style.bin", 0xA72, 0x1A
; [nakarest] naka_composer_style+0xa8c  +0xa8c..+0xd46 (0xe18170, 698 B)
; [nakarest] widget records, elements 0-11 of Viewable slot 0xb1 (table 0xe1b5ee, 12 entries,
; [nakarest] InitializeSuna) ("CmpBkslScreen"): TtlScreen (42 B), IvMainEditSw (26 B), VwMenuBox
; [nakarest] (50 B) x10. 11 texts the records point at (Viewable slot 0xb1 (table 0xe1b5ee, 12
; [nakarest] entries, InitializeSuna)): "RECORD MEMORY" (TtlScreen.title of element 0);
; [nakarest] "VARIATION 1" (VwMenuBox.str of element 2); "VARIATION 3" (VwMenuBox.str of element
; [nakarest] 3); "INTRO 1" (VwMenuBox.str of element 4); ....
NakaWidget_CmpBkslScreen:			.incbin "includes/generated/naka_composer_style.bin", 0xA8C, 0x38
NakaWidget_CmpBkslScreen_1_IvMainEditSw:	.incbin "includes/generated/naka_composer_style.bin", 0xAC4, 0x1A
NakaWidget_CmpBkslScreen_2_VwMenuBox:		.incbin "includes/generated/naka_composer_style.bin", 0xADE, 0x3E
NakaWidget_CmpBkslScreen_3_VwMenuBox:		.incbin "includes/generated/naka_composer_style.bin", 0xB1C, 0x3E
NakaWidget_CmpBkslScreen_4_VwMenuBox:		.incbin "includes/generated/naka_composer_style.bin", 0xB5A, 0x3A
NakaWidget_CmpBkslScreen_5_VwMenuBox:		.incbin "includes/generated/naka_composer_style.bin", 0xB94, 0x3C
NakaWidget_CmpBkslScreen_6_VwMenuBox:		.incbin "includes/generated/naka_composer_style.bin", 0xBD0, 0x3C
NakaWidget_CmpBkslScreen_7_VwMenuBox:		.incbin "includes/generated/naka_composer_style.bin", 0xC0C, 0x44
NakaWidget_CmpBkslScreen_8_VwMenuBox:		.incbin "includes/generated/naka_composer_style.bin", 0xC50, 0x44
NakaWidget_CmpBkslScreen_9_VwMenuBox:		.incbin "includes/generated/naka_composer_style.bin", 0xC94, 0x3A
NakaWidget_CmpBkslScreen_10_VwMenuBox:		.incbin "includes/generated/naka_composer_style.bin", 0xCCE, 0x3C
NakaWidget_CmpBkslScreen_11_VwMenuBox:		.incbin "includes/generated/naka_composer_style.bin", 0xD0A, 0x3C
; [nakarest] naka_composer_style+0xd46  +0xd46..+0x10fa (0xe1842a, 948 B)
; [nakarest] widget records, elements 0-21 of Viewable slot 0xb2 (table 0xe1b622, 22 entries,
; [nakarest] InitializeSuna) ("CmpBkslSScreen"): TtlScreen (42 B), Box (26 B), Label (32 B) x2,
; [nakarest] IvMainEditSw (26 B), VwMenuBox (50 B) x2, VwEditSwBox (44 B) x5, AcMemNoBox (36 B),
; [nakarest] Line (26 B) x4, CmpNameMenuBox (50 B), Window (36 B), AcFuncEditSw (44 B) x2,
; [nakarest] AcLanguageText (42 B). 11 texts the records point at (Viewable slot 0xb2 (table
; [nakarest] 0xe1b622, 22 entries, InitializeSuna)): "RECORDING" (TtlScreen.title of element 0);
; [nakarest] "Memory:" (Label.str of element 2); "RECORD SETTING" (VwMenuBox.str of element 4);
; [nakarest] "DRM" (VwEditSwBox.str of element 5); ....
NakaWidget_CmpBkslSScreen:			.incbin "includes/generated/naka_composer_style.bin", 0xD46, 0x34
NakaWidget_CmpBkslSScreen_1_Box:		.incbin "includes/generated/naka_composer_style.bin", 0xD7A, 0x1A
NakaWidget_CmpBkslSScreen_2_Label:		.incbin "includes/generated/naka_composer_style.bin", 0xD94, 0x28
NakaWidget_CmpBkslSScreen_3_IvMainEditSw:	.incbin "includes/generated/naka_composer_style.bin", 0xDBC, 0x1A
NakaWidget_CmpBkslSScreen_4_VwMenuBox:		.incbin "includes/generated/naka_composer_style.bin", 0xDD6, 0x42
NakaWidget_CmpBkslSScreen_5_VwEditSwBox:	.incbin "includes/generated/naka_composer_style.bin", 0xE18, 0x30
NakaWidget_CmpBkslSScreen_6_VwEditSwBox:	.incbin "includes/generated/naka_composer_style.bin", 0xE48, 0x30
NakaWidget_CmpBkslSScreen_7_VwEditSwBox:	.incbin "includes/generated/naka_composer_style.bin", 0xE78, 0x30
NakaWidget_CmpBkslSScreen_8_VwEditSwBox:	.incbin "includes/generated/naka_composer_style.bin", 0xEA8, 0x30
NakaWidget_CmpBkslSScreen_9_VwEditSwBox:	.incbin "includes/generated/naka_composer_style.bin", 0xED8, 0x30
NakaWidget_CmpBkslSScreen_10_AcMemNoBox:	.incbin "includes/generated/naka_composer_style.bin", 0xF08, 0x24
NakaWidget_CmpBkslSScreen_11_Label:		.incbin "includes/generated/naka_composer_style.bin", 0xF2C, 0x30
NakaWidget_CmpBkslSScreen_12_Line:		.incbin "includes/generated/naka_composer_style.bin", 0xF5C, 0x1A
NakaWidget_CmpBkslSScreen_13_Line:		.incbin "includes/generated/naka_composer_style.bin", 0xF76, 0x1A
NakaWidget_CmpBkslSScreen_14_Line:		.incbin "includes/generated/naka_composer_style.bin", 0xF90, 0x1A
NakaWidget_CmpBkslSScreen_15_Line:		.incbin "includes/generated/naka_composer_style.bin", 0xFAA, 0x1A
NakaWidget_CmpNameMenu:				.incbin "includes/generated/naka_composer_style.bin", 0xFC4, 0x44
NakaWidget_CmpBkslSScreen_17_VwMenuBox:		.incbin "includes/generated/naka_composer_style.bin", 0x1008, 0x4C
NakaWidget_CmpClrSure:				.incbin "includes/generated/naka_composer_style.bin", 0x1054, 0x24
NakaWidget_CmpClrYesSw:				.incbin "includes/generated/naka_composer_style.bin", 0x1078, 0x2C
NakaWidget_CmpClrNoSw:				.incbin "includes/generated/naka_composer_style.bin", 0x10A4, 0x2C
NakaWidget_CmpBkslSScreen_21_AcLanguageText:	.incbin "includes/generated/naka_composer_style.bin", 0x10D0, 0x2A
; [nakarest] naka_composer_style+0x10fa  +0x10fa..+0x11ca (0xe187de, 208 B)
; [nakarest] widget records, elements 0-4 of Viewable slot 0xb3 (table 0xe1b67e, 5 entries,
; [nakarest] InitializeSuna) ("CmpNamingScreen"): TtlScreen (42 B), IvNaming (26 B),
; [nakarest] AcFuncEditSw (44 B), Label (32 B), AcMemNoBox (36 B). 2 texts the records point at
; [nakarest] (Viewable slot 0xb3 (table 0xe1b67e, 5 entries, InitializeSuna)): "VARIATION
; [nakarest] NAMING" (TtlScreen.title of element 0); "MEMORY :" (Label.str of element 3).
NakaWidget_CmpNamingScreen:			.incbin "includes/generated/naka_composer_style.bin", 0x10FA, 0x3C
NakaWidget_CmpNamingScreen_1_IvNaming:		.incbin "includes/generated/naka_composer_style.bin", 0x1136, 0x1A
NakaWidget_CmpNamingScreen_2_AcFuncEditSw:	.incbin "includes/generated/naka_composer_style.bin", 0x1150, 0x2C
NakaWidget_NameMemLabel:			.incbin "includes/generated/naka_composer_style.bin", 0x117C, 0x2A
NakaWidget_NamingMem:				.incbin "includes/generated/naka_composer_style.bin", 0x11A6, 0x24
; [nakarest] naka_composer_style+0x11ca  +0x11ca..+0x1580 (0xe188ae, 950 B)
; [nakarest] widget records, elements 0-17 of Viewable slot 0xb4 (table 0xe1b696, 18 entries,
; [nakarest] InitializeSuna) ("CmpSetScreen"): TtlScreen (42 B), IvMainEditSw (26 B),
; [nakarest] AcWindowPage (36 B), IvPageControl (28 B) x2, IvShowHide (26 B), Window (36 B) x2,
; [nakarest] AcCmpSetGridBox (74 B), Label (32 B) x3, AcIndexWideES (42 B) x5, AcGridBox (74 B).
; [nakarest] 8 texts the records point at (Viewable slot 0xb4 (table 0xe1b696, 18 entries,
; [nakarest] InitializeSuna)): "RECORD SETTING" (TtlScreen.title of element 0); "|MEASURE :|TIME
; [nakarest] SIGNATURE:|-| | KEY " (AcCmpSetGridBox.fixedrow of element 7); " MEASURE &|TIME
; [nakarest] SIGNATURE" (AcCmpSetGridBox.fixedcol of element 7); "RECORD SETTING" (Label.str of
; [nakarest] element 8); ....
NakaWidget_CmpSetScreen:			.incbin "includes/generated/naka_composer_style.bin", 0x11CA, 0x3A
NakaWidget_CmpSetScreen_1_IvMainEditSw:		.incbin "includes/generated/naka_composer_style.bin", 0x1204, 0x1A
NakaWidget_CmSetPage:				.incbin "includes/generated/naka_composer_style.bin", 0x121E, 0x24
NakaWidget_CmSetP1Ctl:				.incbin "includes/generated/naka_composer_style.bin", 0x1242, 0x1C
NakaWidget_CmSetP2Ctl:				.incbin "includes/generated/naka_composer_style.bin", 0x125E, 0x1C
NakaWidget_CmpSetScreen_5_IvShowHide:		.incbin "includes/generated/naka_composer_style.bin", 0x127A, 0x1A
NakaWidget_CmSetPage1:				.incbin "includes/generated/naka_composer_style.bin", 0x1294, 0x24
NakaWidget_CmSetP1Grid:				.incbin "includes/generated/naka_composer_style.bin", 0x12B8, 0xCE
NakaWidget_CmpSetScreen_8_Label:		.incbin "includes/generated/naka_composer_style.bin", 0x1386, 0x30
NakaWidget_CmpSetScreen_9_AcIndexWideES:	.incbin "includes/generated/naka_composer_style.bin", 0x13B6, 0x2A
NakaWidget_CmpSetScreen_10_AcIndexWideES:	.incbin "includes/generated/naka_composer_style.bin", 0x13E0, 0x2A
NakaWidget_CmpSetScreen_11_Label:		.incbin "includes/generated/naka_composer_style.bin", 0x140A, 0x26
NakaWidget_CmpSetScreen_12_Label:		.incbin "includes/generated/naka_composer_style.bin", 0x1430, 0x26
NakaWidget_CmSetPage2:				.incbin "includes/generated/naka_composer_style.bin", 0x1456, 0x24
NakaWidget_CmpSetGrid:				.incbin "includes/generated/naka_composer_style.bin", 0x147A, 0x88
NakaWidget_CmSetPartSw:				.incbin "includes/generated/naka_composer_style.bin", 0x1502, 0x2A
NakaWidget_CmSetPanSw:				.incbin "includes/generated/naka_composer_style.bin", 0x152C, 0x2A
NakaWidget_CmSetRLmtSw:				.incbin "includes/generated/naka_composer_style.bin", 0x1556, 0x2A
; [nakarest] naka_composer_style+0x1580  +0x1580..+0x1a2a (0xe18c64, 1194 B)
; [nakarest] widget records, elements 0-23, 29-30 of Viewable slot 0xb5 (table 0xe1b6e2, 31
; [nakarest] entries, InitializeSuna) ("CmpRealScreen"): TtlScreen (42 B), Box (26 B),
; [nakarest] PsCmpMemBox (36 B), Label (32 B) x6, IvMainEditSw (26 B), VwEditSwBox (44 B) x5,
; [nakarest] AcCmpTempoBox (36 B), AcTitleMenu (54 B) x2, AcMemNoBox (36 B), VwMenuBox (50 B)
; [nakarest] x5, PsCmpQtzBox (36 B), PsCmpMeasBox (36 B). 19 texts the records point at
; [nakarest] (Viewable slot 0xb5 (table 0xe1b6e2, 31 entries, InitializeSuna)): "REALTIME
; [nakarest] RECORDING" (TtlScreen.title of element 0); "%" (Label.str of element 3); "PATTERN
; [nakarest] =" (Label.str of element 4); "TEMPO =" (Label.str of element 5); ....
NakaWidget_CmpRealScreen:			.incbin "includes/generated/naka_composer_style.bin", 0x1580, 0x3E
NakaWidget_CmpRealScreen_1_Box:			.incbin "includes/generated/naka_composer_style.bin", 0x15BE, 0x1A
NakaWidget_CmpMem:				.incbin "includes/generated/naka_composer_style.bin", 0x15D8, 0x24
NakaWidget_CmpRealScreen_3_Label:		.incbin "includes/generated/naka_composer_style.bin", 0x15FC, 0x22
NakaWidget_CmpRealScreen_4_Label:		.incbin "includes/generated/naka_composer_style.bin", 0x161E, 0x2A
NakaWidget_CmpRealScreen_5_Label:		.incbin "includes/generated/naka_composer_style.bin", 0x1648, 0x20
Str_TEMPO:					.incbin "includes/generated/naka_composer_style.bin", 0x1668, 0xA
NakaWidget_CmpRealScreen_6_Label:		.incbin "includes/generated/naka_composer_style.bin", 0x1672, 0x2A
NakaWidget_CmpRealScreen_7_Label:		.incbin "includes/generated/naka_composer_style.bin", 0x169C, 0x2A
NakaWidget_CmpRealScreen_8_Label:		.incbin "includes/generated/naka_composer_style.bin", 0x16C6, 0x2A
NakaWidget_CmpRealScreen_9_IvMainEditSw:	.incbin "includes/generated/naka_composer_style.bin", 0x16F0, 0x1A
NakaWidget_CmpRealScreen_10_VwEditSwBox:	.incbin "includes/generated/naka_composer_style.bin", 0x170A, 0x30
NakaWidget_CmpRealScreen_11_VwEditSwBox:	.incbin "includes/generated/naka_composer_style.bin", 0x173A, 0x30
NakaWidget_CmpRealScreen_12_VwEditSwBox:	.incbin "includes/generated/naka_composer_style.bin", 0x176A, 0x30
NakaWidget_CmpRealScreen_13_VwEditSwBox:	.incbin "includes/generated/naka_composer_style.bin", 0x179A, 0x30
NakaWidget_CmpRealScreen_14_VwEditSwBox:	.incbin "includes/generated/naka_composer_style.bin", 0x17CA, 0x30
NakaWidget_CmpRealScreen_15_AcCmpTempoBox:	.incbin "includes/generated/naka_composer_style.bin", 0x17FA, 0x24
NakaWidget_CmpRealScreen_16_AcTitleMenu:	.incbin "includes/generated/naka_composer_style.bin", 0x181E, 0x3A
NakaWidget_CmpRealScreen_17_AcTitleMenu:	.incbin "includes/generated/naka_composer_style.bin", 0x1858, 0x3C
NakaWidget_CmpRealScreen_18_AcMemNoBox:		.incbin "includes/generated/naka_composer_style.bin", 0x1894, 0x24
NakaWidget_CmpRealScreen_19_VwMenuBox:		.incbin "includes/generated/naka_composer_style.bin", 0x18B8, 0x3C
NakaWidget_CmpRealScreen_20_VwMenuBox:		.incbin "includes/generated/naka_composer_style.bin", 0x18F4, 0x3C
NakaWidget_CmpRealScreen_21_VwMenuBox:		.incbin "includes/generated/naka_composer_style.bin", 0x1930, 0x3C
NakaWidget_CmpRealScreen_22_VwMenuBox:		.incbin "includes/generated/naka_composer_style.bin", 0x196C, 0x3C
NakaWidget_CmpRealScreen_23_VwMenuBox:		.incbin "includes/generated/naka_composer_style.bin", 0x19A8, 0x3A
NakaWidget_CmpQtz:				.incbin "includes/generated/naka_composer_style.bin", 0x19E2, 0x24
NakaWidget_CmpMeas:				.incbin "includes/generated/naka_composer_style.bin", 0x1A06, 0x24
; [nakarest] naka_composer_style+0x1a2a  +0x1a2a..+0x1a4c (0xe1910e, 34 B)
; [nakarest] widget record, element 0 of Viewable slot 0xb6 (table 0xe1b762, 1 entries,
; [nakarest] InitializeSuna): IvDirmdScreen (34 B).
NakaWidget_SunaView0B6_0_IvDirmdScreen:	.incbin "includes/generated/naka_composer_style.bin", 0x1A2A, 0x22
; [nakarest] naka_composer_style+0x1a4c  +0x1a4c..+0x1b24 (0xe19130, 216 B)
; [nakarest] widget records, elements 0-5 of Viewable slot 0xb7 (table 0xe1b76a, 6 entries,
; [nakarest] InitializeSuna) ("CmpBalScreen"): TtlScreen (42 B), AcMixerVol (32 B) x5. 1 text
; [nakarest] the records point at (Viewable slot 0xb7 (table 0xe1b76a, 6 entries,
; [nakarest] InitializeSuna)): "PART BALANCE" (TtlScreen.title of element 0).
NakaWidget_CmpBalScreen:	.incbin "includes/generated/naka_composer_style.bin", 0x1A4C, 0x38
NakaWidget_CmpDrmVol:		.incbin "includes/generated/naka_composer_style.bin", 0x1A84, 0x20
NakaWidget_CmpAc3Vol:		.incbin "includes/generated/naka_composer_style.bin", 0x1AA4, 0x20
NakaWidget_CmpAc2Vol:		.incbin "includes/generated/naka_composer_style.bin", 0x1AC4, 0x20
NakaWidget_CmpAc1Vol:		.incbin "includes/generated/naka_composer_style.bin", 0x1AE4, 0x20
NakaWidget_CmpBasVol:		.incbin "includes/generated/naka_composer_style.bin", 0x1B04, 0x20
; [nakarest] naka_composer_style+0x1b24  +0x1b24..+0x1eba (0xe19208, 918 B)
; [nakarest] widget records, elements 0-17, 19-25 of Viewable slot 0xb8 (table 0xe1b786, 33
; [nakarest] entries, InitializeSuna) ("CmpNcpScreen"): TtlScreen (42 B), IvMainEditSw (26 B),
; [nakarest] VwWideESBox (46 B) x4, Label (32 B) x8, Line (26 B) x8, Box (26 B) x2, VwEditSwBox
; [nakarest] (44 B). 14 texts the records point at (Viewable slot 0xb8 (table 0xe1b786, 33
; [nakarest] entries, InitializeSuna)): "PATTERN COPY" (TtlScreen.title of element 0); ""
; [nakarest] (VwWideESBox.str of element 2); "" (VwWideESBox.str of element 3); ""
; [nakarest] (VwWideESBox.str of element 4); ....
NakaWidget_CmpNcpScreen:		.incbin "includes/generated/naka_composer_style.bin", 0x1B24, 0x38
NakaWidget_CmpNcpScreen_1_IvMainEditSw:	.incbin "includes/generated/naka_composer_style.bin", 0x1B5C, 0x1A
NakaWidget_CmpNcpFitmSw:		.incbin "includes/generated/naka_composer_style.bin", 0x1B76, 0x30
NakaWidget_CmpNcpScreen_3_VwWideESBox:	.incbin "includes/generated/naka_composer_style.bin", 0x1BA6, 0x30
NakaWidget_CmpNcpTitmSw:		.incbin "includes/generated/naka_composer_style.bin", 0x1BD6, 0x30
NakaWidget_CmpNcpScreen_5_VwWideESBox:	.incbin "includes/generated/naka_composer_style.bin", 0x1C06, 0x30
NakaWidget_CmpNcpScreen_6_Label:	.incbin "includes/generated/naka_composer_style.bin", 0x1C36, 0x44
NakaWidget_CmpNcpScreen_7_Label:	.incbin "includes/generated/naka_composer_style.bin", 0x1C7A, 0x26
NakaWidget_CmpNcpScreen_8_Line:		.incbin "includes/generated/naka_composer_style.bin", 0x1CA0, 0x1A
NakaWidget_CmpNcpScreen_9_Line:		.incbin "includes/generated/naka_composer_style.bin", 0x1CBA, 0x1A
NakaWidget_CmpNcpScreen_10_Line:	.incbin "includes/generated/naka_composer_style.bin", 0x1CD4, 0x1A
NakaWidget_CmpNcpScreen_11_Line:	.incbin "includes/generated/naka_composer_style.bin", 0x1CEE, 0x1A
NakaWidget_CmpNcpScreen_12_Label:	.incbin "includes/generated/naka_composer_style.bin", 0x1D08, 0x24
NakaWidget_CmpNcpScreen_13_Line:	.incbin "includes/generated/naka_composer_style.bin", 0x1D2C, 0x1A
NakaWidget_CmpNcpScreen_14_Line:	.incbin "includes/generated/naka_composer_style.bin", 0x1D46, 0x1A
NakaWidget_CmpNcpScreen_15_Line:	.incbin "includes/generated/naka_composer_style.bin", 0x1D60, 0x1A
NakaWidget_CmpNcpScreen_16_Line:	.incbin "includes/generated/naka_composer_style.bin", 0x1D7A, 0x1A
NakaWidget_CmpNcpScreen_17_Box:		.incbin "includes/generated/naka_composer_style.bin", 0x1D94, 0x1A
NakaWidget_CmpNcpScreen_19_Label:	.incbin "includes/generated/naka_composer_style.bin", 0x1DAE, 0x28
NakaWidget_CmpNcpScreen_20_Label:	.incbin "includes/generated/naka_composer_style.bin", 0x1DD6, 0x28
NakaWidget_CmpNcpScreen_21_Label:	.incbin "includes/generated/naka_composer_style.bin", 0x1DFE, 0x2A
NakaWidget_CmpNcpScreen_22_Label:	.incbin "includes/generated/naka_composer_style.bin", 0x1E28, 0x26
NakaWidget_CmpNcpScreen_23_Label:	.incbin "includes/generated/naka_composer_style.bin", 0x1E4E, 0x24
NakaWidget_CmpNcpScreen_24_VwEditSwBox:	.incbin "includes/generated/naka_composer_style.bin", 0x1E72, 0x2E
NakaWidget_CmpNcpScreen_25_Box:		.incbin "includes/generated/naka_composer_style.bin", 0x1EA0, 0x1A
; [nakarest] NakaLabel_PatternCopy_MemoryLabel  +0x1eba..+0x1ee2 (0xe1959e, 40 B)
; [nakarest] widget record, element 28 of Viewable slot 0xb8 (table 0xe1b786, 33 entries,
; [nakarest] InitializeSuna) ("CmpNcpScreen"): Label (32 B). 1 text the records point at
; [nakarest] (Viewable slot 0xb8 (table 0xe1b786, 33 entries, InitializeSuna)): "MEMORY:"
; [nakarest] (Label.str of element 28).
NakaLabel_PatternCopy_MemoryLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x1EBA, 0x28
; [nakarest] NakaLabel_PatternCopy_PatMemLabel  +0x1ee2..+0x1f0c (0xe195c6, 42 B)
; [nakarest] widget record, element 29 of Viewable slot 0xb8 (table 0xe1b786, 33 entries,
; [nakarest] InitializeSuna) ("CmpNcpScreen"): Label (32 B). 1 text the records point at
; [nakarest] (Viewable slot 0xb8 (table 0xe1b786, 33 entries, InitializeSuna)): "PATTERN:"
; [nakarest] (Label.str of element 29).
NakaLabel_PatternCopy_PatMemLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x1EE2, 0x2A
; [nakarest] NakaNode_PatternCopy_ProgressBar  +0x1f0c..+0x1f2c (0xe195f0, 32 B)
; [nakarest] widget record, element 32 of Viewable slot 0xb8 (table 0xe1b786, 33 entries,
; [nakarest] InitializeSuna) ("CmpNcpScreen"): Yajirushi (32 B).
NakaNode_PatternCopy_ProgressBar:
	.incbin "includes/generated/naka_composer_style.bin", 0x1F0C, 0x20
; [nakarest] NakaContainer_SeqToComposer_Root  +0x1f2c..+0x1f6c (0xe19610, 64 B)
; [nakarest] widget record, element 0 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): TtlScreen (42 B). 1 text the records point at
; [nakarest] (Viewable slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna)): "SEQ TO COMPOSER
; [nakarest] COPY" (TtlScreen.title of element 0).
NakaContainer_SeqToComposer_Root:
	.incbin "includes/generated/naka_composer_style.bin", 0x1F2C, 0x40
; [nakarest] Naka0x3E_SeqToComposer_DrmBtn  +0x1f6c..+0x1f9a (0xe19650, 46 B)
; [nakarest] widget record, element 1 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): VwEditSwBox (44 B). 1 text the records point at
; [nakarest] (Viewable slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna)): ""
; [nakarest] (VwEditSwBox.str of element 1).
Naka0x3E_SeqToComposer_DrmBtn:
	.incbin "includes/generated/naka_composer_style.bin", 0x1F6C, 0x2E
; [nakarest] Naka0x3E_SeqToComposer_Ac3Btn  +0x1f9a..+0x1fc8 (0xe1967e, 46 B)
; [nakarest] widget record, element 2 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): VwEditSwBox (44 B). 1 text the records point at
; [nakarest] (Viewable slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna)): ""
; [nakarest] (VwEditSwBox.str of element 2).
Naka0x3E_SeqToComposer_Ac3Btn:
	.incbin "includes/generated/naka_composer_style.bin", 0x1F9A, 0x2E
; [nakarest] Naka0x3E_SeqToComposer_Ac2Btn  +0x1fc8..+0x1ff6 (0xe196ac, 46 B)
; [nakarest] widget record, element 3 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): VwEditSwBox (44 B). 1 text the records point at
; [nakarest] (Viewable slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna)): ""
; [nakarest] (VwEditSwBox.str of element 3).
Naka0x3E_SeqToComposer_Ac2Btn:
	.incbin "includes/generated/naka_composer_style.bin", 0x1FC8, 0x2E
; [nakarest] Naka0x29_SeqToComposer_Scrollbar  +0x1ff6..+0x2010 (0xe196da, 26 B)
; [nakarest] widget record, element 4 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): IvMainEditSw (26 B).
Naka0x29_SeqToComposer_Scrollbar:
	.incbin "includes/generated/naka_composer_style.bin", 0x1FF6, 0x1A
; [nakarest] Naka0x3E_SeqToComposer_SourceBtn  +0x2010..+0x203e (0xe196f4, 46 B)
; [nakarest] widget record, element 5 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): VwEditSwBox (44 B). 1 text the records point at
; [nakarest] (Viewable slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna)): ""
; [nakarest] (VwEditSwBox.str of element 5).
Naka0x3E_SeqToComposer_SourceBtn:
	.incbin "includes/generated/naka_composer_style.bin", 0x2010, 0x2E
; [nakarest] Naka0x3E_SeqToComposer_DestBtn  +0x203e..+0x206c (0xe19722, 46 B)
; [nakarest] widget record, element 6 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): VwEditSwBox (44 B). 1 text the records point at
; [nakarest] (Viewable slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna)): ""
; [nakarest] (VwEditSwBox.str of element 6).
Naka0x3E_SeqToComposer_DestBtn:
	.incbin "includes/generated/naka_composer_style.bin", 0x203E, 0x2E
; [nakarest] Naka0x3E_SeqToComposer_InfoBtn  +0x206c..+0x209a (0xe19750, 46 B)
; [nakarest] widget record, element 7 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): VwEditSwBox (44 B). 1 text the records point at
; [nakarest] (Viewable slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna)): ""
; [nakarest] (VwEditSwBox.str of element 7).
Naka0x3E_SeqToComposer_InfoBtn:
	.incbin "includes/generated/naka_composer_style.bin", 0x206C, 0x2E
; [nakarest] NakaLabel_SeqToComposer_FirstLast  +0x209a..+0x20c6 (0xe1977e, 44 B)
; [nakarest] widget record, element 8 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): Label (32 B). 1 text the records point at (Viewable
; [nakarest] slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna)): "FIRST LAST" (Label.str of
; [nakarest] element 8).
NakaLabel_SeqToComposer_FirstLast:
	.incbin "includes/generated/naka_composer_style.bin", 0x209A, 0x2C
; [nakarest] NakaLabel_SeqToComposer_MeasureLabel  +0x20c6..+0x20ee (0xe197aa, 40 B)
; [nakarest] widget record, element 9 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): Label (32 B). 1 text the records point at (Viewable
; [nakarest] slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna)): "MEASURE" (Label.str of
; [nakarest] element 9).
NakaLabel_SeqToComposer_MeasureLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x20C6, 0x28
; [nakarest] NakaValue_SeqToComposer_MeasVal1  +0x20ee..+0x2108 (0xe197d2, 26 B)
; [nakarest] widget record, element 10 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): Line (26 B).
NakaValue_SeqToComposer_MeasVal1:
	.incbin "includes/generated/naka_composer_style.bin", 0x20EE, 0x1A
; [nakarest] NakaValue_SeqToComposer_MeasVal2  +0x2108..+0x2122 (0xe197ec, 26 B)
; [nakarest] widget record, element 11 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): Line (26 B).
NakaValue_SeqToComposer_MeasVal2:
	.incbin "includes/generated/naka_composer_style.bin", 0x2108, 0x1A
; [nakarest] NakaValue_SeqToComposer_MeasVal3  +0x2122..+0x213c (0xe19806, 26 B)
; [nakarest] widget record, element 12 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): Line (26 B).
NakaValue_SeqToComposer_MeasVal3:
	.incbin "includes/generated/naka_composer_style.bin", 0x2122, 0x1A
; [nakarest] NakaValue_SeqToComposer_MeasVal4  +0x213c..+0x2156 (0xe19820, 26 B)
; [nakarest] widget record, element 13 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): Line (26 B).
NakaValue_SeqToComposer_MeasVal4:
	.incbin "includes/generated/naka_composer_style.bin", 0x213C, 0x1A
; [nakarest] NakaLabel_SeqToComposer_TransLabel  +0x2156..+0x217c (0xe1983a, 38 B)
; [nakarest] widget record, element 14 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): Label (32 B). 1 text the records point at (Viewable
; [nakarest] slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna)): "TRANS" (Label.str of
; [nakarest] element 14).
NakaLabel_SeqToComposer_TransLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x2156, 0x26
; [nakarest] NakaLabel_SeqToComposer_TransPose  +0x217c..+0x21a2 (0xe19860, 38 B)
; [nakarest] widget record, element 15 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): Label (32 B). 1 text the records point at (Viewable
; [nakarest] slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna)): "-POSE" (Label.str of
; [nakarest] element 15).
NakaLabel_SeqToComposer_TransPose:
	.incbin "includes/generated/naka_composer_style.bin", 0x217C, 0x26
; [nakarest] NakaLabel_SeqToComposer_SequencerLabel  +0x21a2..+0x21cc (0xe19886, 42 B)
; [nakarest] widget record, element 16 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): Label (32 B). 1 text the records point at (Viewable
; [nakarest] slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna)): "SEQUENCER" (Label.str of
; [nakarest] element 16).
NakaLabel_SeqToComposer_SequencerLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x21A2, 0x2A
; [nakarest] NakaGroup_SeqToComposer_SeqGroup  +0x21cc..+0x21e6 (0xe198b0, 26 B)
; [nakarest] widget record, element 17 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): Box (26 B).
NakaGroup_SeqToComposer_SeqGroup:
	.incbin "includes/generated/naka_composer_style.bin", 0x21CC, 0x1A
; [nakarest] NakaValue_SeqToComposer_SeqValue  +0x21e6..+0x2200 (0xe198ca, 26 B)
; [nakarest] widget record, element 18 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): Line (26 B).
NakaValue_SeqToComposer_SeqValue:
	.incbin "includes/generated/naka_composer_style.bin", 0x21E6, 0x1A
; [nakarest] NakaLabel_SeqToComposer_FirstLabel  +0x2200..+0x2226 (0xe198e4, 38 B)
; [nakarest] widget record, element 19 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): Label (32 B). 1 text the records point at (Viewable
; [nakarest] slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna)): "FIRST" (Label.str of
; [nakarest] element 19).
NakaLabel_SeqToComposer_FirstLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x2200, 0x26
; [nakarest] NakaLabel_SeqToComposer_MeasFirstLabel  +0x2226..+0x224c (0xe1990a, 38 B)
; [nakarest] widget record, element 20 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): Label (32 B). 1 text the records point at (Viewable
; [nakarest] slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna)): "MEAS:" (Label.str of
; [nakarest] element 20).
NakaLabel_SeqToComposer_MeasFirstLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x2226, 0x26
; [nakarest] NakaLabel_SeqToComposer_LastLabel  +0x224c..+0x2272 (0xe19930, 38 B)
; [nakarest] widget record, element 21 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): Label (32 B). 1 text the records point at (Viewable
; [nakarest] slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna)): "LAST" (Label.str of
; [nakarest] element 21).
NakaLabel_SeqToComposer_LastLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x224C, 0x26
; [nakarest] NakaLabel_SeqToComposer_MeasLastLabel  +0x2272..+0x2298 (0xe19956, 38 B)
; [nakarest] widget record, element 22 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): Label (32 B). 1 text the records point at (Viewable
; [nakarest] slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna)): "MEAS:" (Label.str of
; [nakarest] element 22).
NakaLabel_SeqToComposer_MeasLastLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x2272, 0x26
; [nakarest] NakaGroup_SeqToComposer_TransGroup  +0x2298..+0x22b2 (0xe1997c, 26 B)
; [nakarest] widget record, element 23 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): Box (26 B).
NakaGroup_SeqToComposer_TransGroup:
	.incbin "includes/generated/naka_composer_style.bin", 0x2298, 0x1A
; [nakarest] NakaLabel_SeqToComposer_TrnLabel  +0x22b2..+0x22d6 (0xe19996, 36 B)
; [nakarest] widget record, element 25 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): Label (32 B). 1 text the records point at (Viewable
; [nakarest] slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna)): "TRN" (Label.str of
; [nakarest] element 25).
NakaLabel_SeqToComposer_TrnLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x22B2, 0x24
; [nakarest] NakaLabel_SeqToComposer_MemLabel  +0x22d6..+0x22fa (0xe199ba, 36 B)
; [nakarest] widget record, element 26 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): Label (32 B). 1 text the records point at (Viewable
; [nakarest] slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna)): "MEM" (Label.str of
; [nakarest] element 26).
NakaLabel_SeqToComposer_MemLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x22D6, 0x24
; [nakarest] NakaLabel_SeqToComposer_ComposerMemory  +0x22fa..+0x232a (0xe199de, 48 B)
; [nakarest] widget record, element 27 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): Label (32 B). 1 text the records point at (Viewable
; [nakarest] slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna)): "COMPOSER MEMORY"
; [nakarest] (Label.str of element 27).
NakaLabel_SeqToComposer_ComposerMemory:
	.incbin "includes/generated/naka_composer_style.bin", 0x22FA, 0x30
; [nakarest] NakaNode_SeqToComposer_ControlField  +0x232a..+0x234e (0xe19a0e, 36 B)
; [nakarest] widget record, element 29 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): PsSeqSongNoBox (36 B).
NakaNode_SeqToComposer_ControlField:
	.incbin "includes/generated/naka_composer_style.bin", 0x232A, 0x24
; [nakarest] NakaNode_SeqToComposer_StyleField  +0x234e..+0x2372 (0xe19a32, 36 B)
; [nakarest] widget record, element 30 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): AcS2cMemNoBox (36 B).
NakaNode_SeqToComposer_StyleField:
	.incbin "includes/generated/naka_composer_style.bin", 0x234E, 0x24
; [nakarest] NakaNode_SeqToComposer_ProgressBar  +0x2372..+0x2392 (0xe19a56, 32 B)
; [nakarest] widget record, element 32 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): Yajirushi (32 B).
NakaNode_SeqToComposer_ProgressBar:
	.incbin "includes/generated/naka_composer_style.bin", 0x2372, 0x20
; [nakarest] NakaNode_SeqToComposer_PartDisplay  +0x2392..+0x2410 (0xe19a76, 126 B)
; [nakarest] widget record, element 33 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): S2cGridBox (74 B). 2 texts the records point at
; [nakarest] (Viewable slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna)):
; [nakarest] "|-|DRUMS|BASS|ACCOMP1|ACCOMP2|ACCOMP3" (S2cGridBox.fixedrow of element 33); " PART
; [nakarest] |TRACK" (S2cGridBox.fixedcol of element 33).
NakaNode_SeqToComposer_PartDisplay:
	.incbin "includes/generated/naka_composer_style.bin", 0x2392, 0x7E
; [nakarest] Naka0x1F_SeqToComposer_PartSel1  +0x2410..+0x2438 (0xe19af4, 40 B)
; [nakarest] widget record, element 34 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): AcIndexEditSw (40 B).
Naka0x1F_SeqToComposer_PartSel1:
	.incbin "includes/generated/naka_composer_style.bin", 0x2410, 0x28
; [nakarest] Naka0x1F_SeqToComposer_PartSel2  +0x2438..+0x2460 (0xe19b1c, 40 B)
; [nakarest] widget record, element 35 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): AcIndexEditSw (40 B).
Naka0x1F_SeqToComposer_PartSel2:
	.incbin "includes/generated/naka_composer_style.bin", 0x2438, 0x28
; [nakarest] Naka0x64_SeqToComposer_TabContent  +0x2460..+0x247a (0xe19b44, 26 B)
; [nakarest] widget record, element 36 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): IvShowHide (26 B).
Naka0x64_SeqToComposer_TabContent:
	.incbin "includes/generated/naka_composer_style.bin", 0x2460, 0x1A
; [nakarest] NakaContainer_EasyComposer_Root  +0x247a..+0x24b2 (0xe19b5e, 56 B)
; [nakarest] widget record, element 0 of Viewable slot 0xba (table 0xe1b8a6, 14 entries,
; [nakarest] InitializeSuna) ("CmpEasyScreen"): TtlScreen (42 B). 1 text the records point at
; [nakarest] (Viewable slot 0xba (table 0xe1b8a6, 14 entries, InitializeSuna)): "EASY COMPOSER"
; [nakarest] (TtlScreen.title of element 0).
NakaContainer_EasyComposer_Root:
	.incbin "includes/generated/naka_composer_style.bin", 0x247A, 0x38
; [nakarest] Naka0x29_EasyComposer_Scrollbar  +0x24b2..+0x24cc (0xe19b96, 26 B)
; [nakarest] widget record, element 1 of Viewable slot 0xba (table 0xe1b8a6, 14 entries,
; [nakarest] InitializeSuna) ("CmpEasyScreen"): IvMainEditSw (26 B).
Naka0x29_EasyComposer_Scrollbar:
	.incbin "includes/generated/naka_composer_style.bin", 0x24B2, 0x1A
; [nakarest] Naka0x3D_EasyComposer_EditBtn  +0x24cc..+0x2504 (0xe19bb0, 56 B)
; [nakarest] widget record, element 2 of Viewable slot 0xba (table 0xe1b8a6, 14 entries,
; [nakarest] InitializeSuna) ("CmpEasyScreen"): VwMenuBox (50 B). 1 text the records point at
; [nakarest] (Viewable slot 0xba (table 0xe1b8a6, 14 entries, InitializeSuna)): "EDIT"
; [nakarest] (VwMenuBox.str of element 2).
Naka0x3D_EasyComposer_EditBtn:
	.incbin "includes/generated/naka_composer_style.bin", 0x24CC, 0x38
; [nakarest] Naka0x3E_EasyComposer_DestBtn  +0x2504..+0x2532 (0xe19be8, 46 B)
; [nakarest] widget record, element 3 of Viewable slot 0xba (table 0xe1b8a6, 14 entries,
; [nakarest] InitializeSuna) ("CmpEasyScreen"): VwEditSwBox (44 B). 1 text the records point at
; [nakarest] (Viewable slot 0xba (table 0xe1b8a6, 14 entries, InitializeSuna)): ""
; [nakarest] (VwEditSwBox.str of element 3).
Naka0x3E_EasyComposer_DestBtn:
	.incbin "includes/generated/naka_composer_style.bin", 0x2504, 0x2E
; [nakarest] Naka0x3E_EasyComposer_SourceBtn  +0x2532..+0x2560 (0xe19c16, 46 B)
; [nakarest] widget record, element 4 of Viewable slot 0xba (table 0xe1b8a6, 14 entries,
; [nakarest] InitializeSuna) ("CmpEasyScreen"): VwEditSwBox (44 B). 1 text the records point at
; [nakarest] (Viewable slot 0xba (table 0xe1b8a6, 14 entries, InitializeSuna)): ""
; [nakarest] (VwEditSwBox.str of element 4).
Naka0x3E_EasyComposer_SourceBtn:
	.incbin "includes/generated/naka_composer_style.bin", 0x2532, 0x2E
; [nakarest] Naka0x3E_EasyComposer_InfoBtn  +0x2560..+0x2590 (0xe19c44, 48 B)
; [nakarest] widget record, element 5 of Viewable slot 0xba (table 0xe1b8a6, 14 entries,
; [nakarest] InitializeSuna) ("CmpEasyScreen"): VwEditSwBox (44 B). 1 text the records point at
; [nakarest] (Viewable slot 0xba (table 0xe1b8a6, 14 entries, InitializeSuna)): "SET"
; [nakarest] (VwEditSwBox.str of element 5).
Naka0x3E_EasyComposer_InfoBtn:
	.incbin "includes/generated/naka_composer_style.bin", 0x2560, 0x30
; [nakarest] NakaLabel_EasyComposer_CompMemLabel  +0x2590..+0x25c2 (0xe19c74, 50 B)
; [nakarest] widget record, element 6 of Viewable slot 0xba (table 0xe1b8a6, 14 entries,
; [nakarest] InitializeSuna) ("CmpEasyScreen"): Label (32 B). 1 text the records point at
; [nakarest] (Viewable slot 0xba (table 0xe1b8a6, 14 entries, InitializeSuna)): "COMPOSER MEMORY
; [nakarest] :" (Label.str of element 6).
NakaLabel_EasyComposer_CompMemLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x2590, 0x32
; [nakarest] NakaLabel_EasyComposer_MemField  +0x25c2..+0x25e6 (0xe19ca6, 36 B)
; [nakarest] widget record, element 7 of Viewable slot 0xba (table 0xe1b8a6, 14 entries,
; [nakarest] InitializeSuna) ("CmpEasyScreen"): Label (32 B). 1 text the records point at
; [nakarest] (Viewable slot 0xba (table 0xe1b8a6, 14 entries, InitializeSuna)): "MEM" (Label.str
; [nakarest] of element 7).
NakaLabel_EasyComposer_MemField:
	.incbin "includes/generated/naka_composer_style.bin", 0x25C2, 0x24
; [nakarest] Naka0x11_EasyComposer_ListFrame  +0x25e6..+0x2602 (0xe19cca, 28 B)
; [nakarest] widget record, element 8 of Viewable slot 0xba (table 0xe1b8a6, 14 entries,
; [nakarest] InitializeSuna) ("CmpEasyScreen"): VwBox (28 B).
Naka0x11_EasyComposer_ListFrame:
	.incbin "includes/generated/naka_composer_style.bin", 0x25E6, 0x1C
; [nakarest] NakaNode_EasyComposer_StatusField  +0x2602..+0x2626 (0xe19ce6, 36 B)
; [nakarest] widget record, element 9 of Viewable slot 0xba (table 0xe1b8a6, 14 entries,
; [nakarest] InitializeSuna) ("CmpEasyScreen"): AcMemNoBox (36 B).
NakaNode_EasyComposer_StatusField:
	.incbin "includes/generated/naka_composer_style.bin", 0x2602, 0x24
; [nakarest] NakaNode_EasyComposer_PartDisplay  +0x2626..+0x26d6 (0xe19d0a, 176 B)
; [nakarest] widget record, element 10 of Viewable slot 0xba (table 0xe1b8a6, 14 entries,
; [nakarest] InitializeSuna) ("CmpEasyScreen"): AcEasyCmpGridBox (74 B). 2 texts the records
; [nakarest] point at (Viewable slot 0xba (table 0xe1b8a6, 14 entries, InitializeSuna)):
; [nakarest] "|-|BsDr&Snare|HHat&Cymbal|Percussion|Bass|Accomp" (AcEasyCmpGridBox.fixedrow of
; [nakarest] element 10); " PART | STYLE |VARI" (AcEasyCmpGridBox.fixedcol of element 10).
NakaNode_EasyComposer_PartDisplay:
	.incbin "includes/generated/naka_composer_style.bin", 0x2626, 0xB0
; [nakarest] Naka0x22_EasyComposer_PartSel1  +0x26d6..+0x2700 (0xe19dba, 42 B)
; [nakarest] widget record, element 11 of Viewable slot 0xba (table 0xe1b8a6, 14 entries,
; [nakarest] InitializeSuna) ("CmpEasyScreen"): AcIndexWideES (42 B).
Naka0x22_EasyComposer_PartSel1:
	.incbin "includes/generated/naka_composer_style.bin", 0x26D6, 0x2A
; [nakarest] Naka0x22_EasyComposer_PartSel2  +0x2700..+0x272a (0xe19de4, 42 B)
; [nakarest] widget record, element 12 of Viewable slot 0xba (table 0xe1b8a6, 14 entries,
; [nakarest] InitializeSuna) ("CmpEasyScreen"): AcIndexWideES (42 B).
Naka0x22_EasyComposer_PartSel2:
	.incbin "includes/generated/naka_composer_style.bin", 0x2700, 0x2A
; [nakarest] Naka0x1F_EasyComposer_PartSel3  +0x272a..+0x2752 (0xe19e0e, 40 B)
; [nakarest] widget record, element 13 of Viewable slot 0xba (table 0xe1b8a6, 14 entries,
; [nakarest] InitializeSuna) ("CmpEasyScreen"): AcIndexEditSw (40 B).
Naka0x1F_EasyComposer_PartSel3:
	.incbin "includes/generated/naka_composer_style.bin", 0x272A, 0x28
; [nakarest] NakaContainer_BendRange_Root  +0x2752..+0x279e (0xe19e36, 76 B)
; [nakarest] widget record, element 0 of Viewable slot 0xbb (table 0xe1b8e2, 4 entries,
; [nakarest] InitializeSuna) ("CmpBendScreen"): TtlScreen (42 B). 1 text the records point at
; [nakarest] (Viewable slot 0xbb (table 0xe1b8e2, 4 entries, InitializeSuna)): "COMPOSER PITCH
; [nakarest] BEND RANGE SETTING" (TtlScreen.title of element 0).
NakaContainer_BendRange_Root:
	.incbin "includes/generated/naka_composer_style.bin", 0x2752, 0x4C
; [nakarest] Naka0x22_BendRange_PartSelector  +0x279e..+0x27c8 (0xe19e82, 42 B)
; [nakarest] widget record, element 1 of Viewable slot 0xbb (table 0xe1b8e2, 4 entries,
; [nakarest] InitializeSuna) ("CmpBendScreen"): AcIndexWideES (42 B).
Naka0x22_BendRange_PartSelector:
	.incbin "includes/generated/naka_composer_style.bin", 0x279E, 0x2A
; [nakarest] Naka0x1A_BendRange_RangeControl  +0x27c8..+0x2816 (0xe19eac, 78 B)
; [nakarest] widget record, element 2 of Viewable slot 0xbb (table 0xe1b8e2, 4 entries,
; [nakarest] InitializeSuna) ("CmpBendScreen"): AcLswEditBox (58 B). 1 text the records point at
; [nakarest] (Viewable slot 0xbb (table 0xe1b8e2, 4 entries, InitializeSuna)): " BEND RANGE : "
; [nakarest] (AcLswEditBox.caption of element 2).
Naka0x1A_BendRange_RangeControl:
	.incbin "includes/generated/naka_composer_style.bin", 0x27C8, 0x4E
; [nakarest] NakaLabel_BendRange_ValueLabel  +0x2816..+0x283c (0xe19efa, 38 B)
; [nakarest] widget record, element 3 of Viewable slot 0xbb (table 0xe1b8e2, 4 entries,
; [nakarest] InitializeSuna) ("CmpBendScreen"): Label (32 B). 1 text the records point at
; [nakarest] (Viewable slot 0xbb (table 0xe1b8e2, 4 entries, InitializeSuna)): "VALUE"
; [nakarest] (Label.str of element 3).
NakaLabel_BendRange_ValueLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x2816, 0x26
; [nakarest] NakaContainer_ModeSelect_Root  +0x283c..+0x2872 (0xe19f20, 54 B)
; [nakarest] widget record, element 0 of Viewable slot 0xbd (table 0xe1b8f6, 11 entries,
; [nakarest] InitializeSuna) ("CmpModeScreen"): TtlScreen (42 B). 1 text the records point at
; [nakarest] (Viewable slot 0xbd (table 0xe1b8f6, 11 entries, InitializeSuna)): "MODE SELECT"
; [nakarest] (TtlScreen.title of element 0).
NakaContainer_ModeSelect_Root:
	.incbin "includes/generated/naka_composer_style.bin", 0x283C, 0x36
; [nakarest] NakaLabel_ModeSelect_IntroFillIns  +0x2872..+0x28b0 (0xe19f56, 62 B)
; [nakarest] widget record, element 1 of Viewable slot 0xbd (table 0xe1b8f6, 11 entries,
; [nakarest] InitializeSuna) ("CmpModeScreen"): Label (32 B). 1 text the records point at
; [nakarest] (Viewable slot 0xbd (table 0xe1b8f6, 11 entries, InitializeSuna)): "The
; [nakarest] Intro,Fill-Ins and Ending" (Label.str of element 1).
NakaLabel_ModeSelect_IntroFillIns:
	.incbin "includes/generated/naka_composer_style.bin", 0x2872, 0x3E
; [nakarest] NakaLabel_ModeSelect_ForEachPattern  +0x28b0..+0x28ee (0xe19f94, 62 B)
; [nakarest] widget record, element 2 of Viewable slot 0xbd (table 0xe1b8f6, 11 entries,
; [nakarest] InitializeSuna) ("CmpModeScreen"): Label (32 B). 1 text the records point at
; [nakarest] (Viewable slot 0xbd (table 0xe1b8f6, 11 entries, InitializeSuna)): "for each
; [nakarest] Composer Pattern can" (Label.str of element 2).
NakaLabel_ModeSelect_ForEachPattern:
	.incbin "includes/generated/naka_composer_style.bin", 0x28B0, 0x3E
; [nakarest] NakaLabel_ModeSelect_BeCopied  +0x28ee..+0x2932 (0xe19fd2, 68 B)
; [nakarest] widget record, element 3 of Viewable slot 0xbd (table 0xe1b8f6, 11 entries,
; [nakarest] InitializeSuna) ("CmpModeScreen"): Label (32 B). 1 text the records point at
; [nakarest] (Viewable slot 0xbd (table 0xe1b8f6, 11 entries, InitializeSuna)): "be copied from
; [nakarest] any preset pattern." (Label.str of element 3).
NakaLabel_ModeSelect_BeCopied:
	.incbin "includes/generated/naka_composer_style.bin", 0x28EE, 0x44
; [nakarest] NakaLabel_ModeSelect_MemAssigned  +0x2932..+0x2970 (0xe1a016, 62 B)
; [nakarest] widget record, element 4 of Viewable slot 0xbd (table 0xe1b8f6, 11 entries,
; [nakarest] InitializeSuna) ("CmpModeScreen"): Label (32 B). 1 text the records point at
; [nakarest] (Viewable slot 0xbd (table 0xe1b8f6, 11 entries, InitializeSuna)): "A Composer
; [nakarest] Memory is assigned" (Label.str of element 4).
NakaLabel_ModeSelect_MemAssigned:
	.incbin "includes/generated/naka_composer_style.bin", 0x2932, 0x3E
; [nakarest] NakaLabel_ModeSelect_ToEachIntro  +0x2970..+0x29b0 (0xe1a054, 64 B)
; [nakarest] widget record, element 5 of Viewable slot 0xbd (table 0xe1b8f6, 11 entries,
; [nakarest] InitializeSuna) ("CmpModeScreen"): Label (32 B). 1 text the records point at
; [nakarest] (Viewable slot 0xbd (table 0xe1b8f6, 11 entries, InitializeSuna)): "to each of The
; [nakarest] Intro Fill-In 1," (Label.str of element 5).
NakaLabel_ModeSelect_ToEachIntro:
	.incbin "includes/generated/naka_composer_style.bin", 0x2970, 0x40
; [nakarest] NakaLabel_ModeSelect_FillInEnding  +0x29b0..+0x29f0 (0xe1a094, 64 B)
; [nakarest] widget record, element 6 of Viewable slot 0xbd (table 0xe1b8f6, 11 entries,
; [nakarest] InitializeSuna) ("CmpModeScreen"): Label (32 B). 1 text the records point at
; [nakarest] (Viewable slot 0xbd (table 0xe1b8f6, 11 entries, InitializeSuna)): "Fill -In 2 and
; [nakarest] Ending buttons," (Label.str of element 6).
NakaLabel_ModeSelect_FillInEnding:
	.incbin "includes/generated/naka_composer_style.bin", 0x29B0, 0x40
; [nakarest] NakaLabel_ModeSelect_SoYouCanCreate  +0x29f0..+0x2a2c (0xe1a0d4, 60 B)
; [nakarest] widget record, element 7 of Viewable slot 0xbd (table 0xe1b8f6, 11 entries,
; [nakarest] InitializeSuna) ("CmpModeScreen"): Label (32 B). 1 text the records point at
; [nakarest] (Viewable slot 0xbd (table 0xe1b8f6, 11 entries, InitializeSuna)): "so you can
; [nakarest] create your own" (Label.str of element 7).
NakaLabel_ModeSelect_SoYouCanCreate:
	.incbin "includes/generated/naka_composer_style.bin", 0x29F0, 0x3C
; [nakarest] NakaLabel_ModeSelect_IntroFillEnding  +0x2a2c..+0x2a66 (0xe1a110, 58 B)
; [nakarest] widget record, element 8 of Viewable slot 0xbd (table 0xe1b8f6, 11 entries,
; [nakarest] InitializeSuna) ("CmpModeScreen"): Label (32 B). 1 text the records point at
; [nakarest] (Viewable slot 0xbd (table 0xe1b8f6, 11 entries, InitializeSuna)): "Intro,Fill-Ins
; [nakarest] & Ending." (Label.str of element 8).
NakaLabel_ModeSelect_IntroFillEnding:
	.incbin "includes/generated/naka_composer_style.bin", 0x2A2C, 0x3A
; [nakarest] NakaNode_ModeSelect_NormalMode  +0x2a66..+0x2aa8 (0xe1a14a, 66 B)
; [nakarest] widget record, element 9 of Viewable slot 0xbd (table 0xe1b8f6, 11 entries,
; [nakarest] InitializeSuna) ("CmpModeScreen"): AcCmpMdBox (52 B). 1 text the records point at
; [nakarest] (Viewable slot 0xbd (table 0xe1b8f6, 11 entries, InitializeSuna)): " NORMAL MODE:"
; [nakarest] (AcCmpMdBox.caption of element 9).
NakaNode_ModeSelect_NormalMode:
	.incbin "includes/generated/naka_composer_style.bin", 0x2A66, 0x42
; [nakarest] NakaNode_ModeSelect_ExpandMode  +0x2aa8..+0x2aea (0xe1a18c, 66 B)
; [nakarest] widget record, element 10 of Viewable slot 0xbd (table 0xe1b8f6, 11 entries,
; [nakarest] InitializeSuna) ("CmpModeScreen"): AcCmpMdBox (52 B). 1 text the records point at
; [nakarest] (Viewable slot 0xbd (table 0xe1b8f6, 11 entries, InitializeSuna)): " EXPAND MODE:"
; [nakarest] (AcCmpMdBox.caption of element 10).
NakaNode_ModeSelect_ExpandMode:
	.incbin "includes/generated/naka_composer_style.bin", 0x2AA8, 0x42
; [nakarest] NakaNode_CustomCopy_RootOuter  +0x2aea..+0x2b20 (0xe1a1ce, 54 B)
; [nakarest] widget record, element 0 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): TtlScreen (42 B). 1 text the records point at
; [nakarest] (Viewable slot 0xbe (table 0xe1b926, 33 entries, InitializeSuna)): "CUSTOM COPY"
; [nakarest] (TtlScreen.title of element 0).
NakaNode_CustomCopy_RootOuter:
	.incbin "includes/generated/naka_composer_style.bin", 0x2AEA, 0x36
; [nakarest] NakaLabel_CustomCopy_FromLabel  +0x2b20..+0x2b46 (0xe1a204, 38 B)
; [nakarest] widget record, element 1 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): Label (32 B). 1 text the records point at
; [nakarest] (Viewable slot 0xbe (table 0xe1b926, 33 entries, InitializeSuna)): "FROM"
; [nakarest] (Label.str of element 1).
NakaLabel_CustomCopy_FromLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x2B20, 0x20
Str_FROM:	.incbin "includes/generated/naka_composer_style.bin", 0x2B40, 0x6
; [nakarest] Naka0x11_CustomCopy_FromFrame  +0x2b46..+0x2b62 (0xe1a22a, 28 B)
; [nakarest] widget record, element 2 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): VwBox (28 B).
Naka0x11_CustomCopy_FromFrame:
	.incbin "includes/generated/naka_composer_style.bin", 0x2B46, 0x1C
; [nakarest] NakaNode_CustomCopy_FromField  +0x2b62..+0x2b88 (0xe1a246, 38 B)
; [nakarest] widget record, element 3 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): PsCstmCpBnkBox (38 B).
NakaNode_CustomCopy_FromField:
	.incbin "includes/generated/naka_composer_style.bin", 0x2B62, 0x26
; [nakarest] NakaNode_CustomCopy_ToFieldTop  +0x2b88..+0x2bae (0xe1a26c, 38 B)
; [nakarest] widget record, element 4 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): PsCstmCpNameBox (38 B).
NakaNode_CustomCopy_ToFieldTop:
	.incbin "includes/generated/naka_composer_style.bin", 0x2B88, 0x26
; [nakarest] NakaLabel_CustomCopy_ToLabel  +0x2bae..+0x2bd2 (0xe1a292, 36 B)
; [nakarest] widget record, element 5 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): Label (32 B). 1 text the records point at
; [nakarest] (Viewable slot 0xbe (table 0xe1b926, 33 entries, InitializeSuna)): "TO" (Label.str
; [nakarest] of element 5).
NakaLabel_CustomCopy_ToLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x2BAE, 0x24
; [nakarest] Naka0x11_CustomCopy_ToFrame  +0x2bd2..+0x2bee (0xe1a2b6, 28 B)
; [nakarest] widget record, element 6 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): VwBox (28 B).
Naka0x11_CustomCopy_ToFrame:
	.incbin "includes/generated/naka_composer_style.bin", 0x2BD2, 0x1C
; [nakarest] Naka0x29_CustomCopy_Scrollbar  +0x2bee..+0x2c08 (0xe1a2d2, 26 B)
; [nakarest] widget record, element 7 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): IvMainEditSw (26 B).
Naka0x29_CustomCopy_Scrollbar:
	.incbin "includes/generated/naka_composer_style.bin", 0x2BEE, 0x1A
; [nakarest] Naka0x3F_CustomCopy_Selector1  +0x2c08..+0x2c38 (0xe1a2ec, 48 B)
; [nakarest] widget record, element 8 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): VwWideESBox (46 B). 1 text the records point
; [nakarest] at (Viewable slot 0xbe (table 0xe1b926, 33 entries, InitializeSuna)): ""
; [nakarest] (VwWideESBox.str of element 8).
Naka0x3F_CustomCopy_Selector1:
	.incbin "includes/generated/naka_composer_style.bin", 0x2C08, 0x30
; [nakarest] Naka0x3F_CustomCopy_Selector2  +0x2c38..+0x2c70 (0xe1a31c, 56 B)
; [nakarest] widget record, element 9 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): VwWideESBox (46 B). 1 text the records point
; [nakarest] at (Viewable slot 0xbe (table 0xe1b926, 33 entries, InitializeSuna)): "DIRECTION"
; [nakarest] (VwWideESBox.str of element 9).
Naka0x3F_CustomCopy_Selector2:
	.incbin "includes/generated/naka_composer_style.bin", 0x2C38, 0x38
; [nakarest] Naka0x3F_CustomCopy_Selector3  +0x2c70..+0x2caa (0xe1a354, 58 B)
; [nakarest] widget record, element 10 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): VwWideESBox (46 B). 1 text the records point
; [nakarest] at (Viewable slot 0xbe (table 0xe1b926, 33 entries, InitializeSuna)): "CstmCpToSw"
; [nakarest] (VwWideESBox.str of element 10).
Naka0x3F_CustomCopy_Selector3:
	.incbin "includes/generated/naka_composer_style.bin", 0x2C70, 0x3A
; [nakarest] NakaNode_CustomCopy_DestField  +0x2caa..+0x2cd0 (0xe1a38e, 38 B)
; [nakarest] widget record, element 11 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): PsCstmCpBnkBox (38 B).
NakaNode_CustomCopy_DestField:
	.incbin "includes/generated/naka_composer_style.bin", 0x2CAA, 0x26
; [nakarest] Naka0x3E_CustomCopy_InfoBtn  +0x2cd0..+0x2cfe (0xe1a3b4, 46 B)
; [nakarest] widget record, element 12 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): VwEditSwBox (44 B). 1 text the records point
; [nakarest] at (Viewable slot 0xbe (table 0xe1b926, 33 entries, InitializeSuna)): ""
; [nakarest] (VwEditSwBox.str of element 12).
Naka0x3E_CustomCopy_InfoBtn:
	.incbin "includes/generated/naka_composer_style.bin", 0x2CD0, 0x2E
; [nakarest] NakaNode_CustomCopy_SrcPatternField  +0x2cfe..+0x2d24 (0xe1a3e2, 38 B)
; [nakarest] widget record, element 13 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): PsCstmCpSwBox (38 B).
NakaNode_CustomCopy_SrcPatternField:
	.incbin "includes/generated/naka_composer_style.bin", 0x2CFE, 0x26
; [nakarest] NakaNode_CustomCopy_DstPatternField  +0x2d24..+0x2d4a (0xe1a408, 38 B)
; [nakarest] widget record, element 14 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): PsCstmCpSwBox (38 B).
NakaNode_CustomCopy_DstPatternField:
	.incbin "includes/generated/naka_composer_style.bin", 0x2D24, 0x26
; [nakarest] NakaNode_CustomCopy_MemoryField  +0x2d4a..+0x2d70 (0xe1a42e, 38 B)
; [nakarest] widget record, element 15 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): PsCstmCpNameBox (38 B).
NakaNode_CustomCopy_MemoryField:
	.incbin "includes/generated/naka_composer_style.bin", 0x2D4A, 0x26
; [nakarest] NakaNode_CustomCopy_ProgressBar  +0x2d70..+0x2d90 (0xe1a454, 32 B)
; [nakarest] widget record, element 16 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): Yajirushi (32 B).
NakaNode_CustomCopy_ProgressBar:
	.incbin "includes/generated/naka_composer_style.bin", 0x2D70, 0x20
; [nakarest] Naka0x35_CustomCopy_SongBar  +0x2d90..+0x2db4 (0xe1a474, 36 B)
; [nakarest] widget record, element 17 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): Window (36 B).
Naka0x35_CustomCopy_SongBar:
	.incbin "includes/generated/naka_composer_style.bin", 0x2D90, 0x24
; [nakarest] Naka0x11_CustomCopy_PresetFrame  +0x2db4..+0x2dd0 (0xe1a498, 28 B)
; [nakarest] widget record, element 18 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): VwBox (28 B).
Naka0x11_CustomCopy_PresetFrame:
	.incbin "includes/generated/naka_composer_style.bin", 0x2DB4, 0x1C
; [nakarest] NakaList_CustomCopy_PresetList  +0x2dd0..+0x2dfa (0xe1a4b4, 42 B)
; [nakarest] widget record, element 19 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): AcLanguageText (42 B).
NakaList_CustomCopy_PresetList:
	.incbin "includes/generated/naka_composer_style.bin", 0x2DD0, 0x2A
; [nakarest] NakaList_CustomCopy_GroupList  +0x2dfa..+0x2e24 (0xe1a4de, 42 B)
; [nakarest] widget record, element 20 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): AcLanguageText (42 B).
NakaList_CustomCopy_GroupList:
	.incbin "includes/generated/naka_composer_style.bin", 0x2DFA, 0x2A
; [nakarest] NakaList_CustomCopy_RhythmList  +0x2e24..+0x2e4e (0xe1a508, 42 B)
; [nakarest] widget record, element 21 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): AcLanguageText (42 B).
NakaList_CustomCopy_RhythmList:
	.incbin "includes/generated/naka_composer_style.bin", 0x2E24, 0x2A
; [nakarest] NakaNode_CustomCopy_RhythmStatus  +0x2e4e..+0x2e72 (0xe1a532, 36 B)
; [nakarest] widget record, element 22 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): PsCtmAttStrBox (36 B).
NakaNode_CustomCopy_RhythmStatus:
	.incbin "includes/generated/naka_composer_style.bin", 0x2E4E, 0x24
; [nakarest] Naka0x3E_CustomCopy_ExecuteBtn  +0x2e72..+0x2ea6 (0xe1a556, 52 B)
; [nakarest] widget record, element 23 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): VwEditSwBox (44 B). 1 text the records point
; [nakarest] at (Viewable slot 0xbe (table 0xe1b926, 33 entries, InitializeSuna)): "EXECUTE"
; [nakarest] (VwEditSwBox.str of element 23).
Naka0x3E_CustomCopy_ExecuteBtn:
	.incbin "includes/generated/naka_composer_style.bin", 0x2E72, 0x34
; [nakarest] Naka0x3E_CustomCopy_AbortBtn1  +0x2ea6..+0x2ed8 (0xe1a58a, 50 B)
; [nakarest] widget record, element 24 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): VwEditSwBox (44 B). 1 text the records point
; [nakarest] at (Viewable slot 0xbe (table 0xe1b926, 33 entries, InitializeSuna)): "ABORT"
; [nakarest] (VwEditSwBox.str of element 24).
Naka0x3E_CustomCopy_AbortBtn1:
	.incbin "includes/generated/naka_composer_style.bin", 0x2EA6, 0x32
; [nakarest] Naka0x35_CustomCopy_DestSongBar  +0x2ed8..+0x2efc (0xe1a5bc, 36 B)
; [nakarest] widget record, element 25 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): Window (36 B).
Naka0x35_CustomCopy_DestSongBar:
	.incbin "includes/generated/naka_composer_style.bin", 0x2ED8, 0x24
; [nakarest] Naka0x11_CustomCopy_DestFrame  +0x2efc..+0x2f18 (0xe1a5e0, 28 B)
; [nakarest] widget record, element 26 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): VwBox (28 B).
Naka0x11_CustomCopy_DestFrame:
	.incbin "includes/generated/naka_composer_style.bin", 0x2EFC, 0x1C
; [nakarest] NakaList_CustomCopy_DestPresetList  +0x2f18..+0x2f42 (0xe1a5fc, 42 B)
; [nakarest] widget record, element 27 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): AcLanguageText (42 B).
NakaList_CustomCopy_DestPresetList:
	.incbin "includes/generated/naka_composer_style.bin", 0x2F18, 0x2A
; [nakarest] NakaList_CustomCopy_DestGroupList  +0x2f42..+0x2f6c (0xe1a626, 42 B)
; [nakarest] widget record, element 28 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): AcLanguageText (42 B).
NakaList_CustomCopy_DestGroupList:
	.incbin "includes/generated/naka_composer_style.bin", 0x2F42, 0x2A
; [nakarest] NakaList_CustomCopy_DestRhythmList  +0x2f6c..+0x2f96 (0xe1a650, 42 B)
; [nakarest] widget record, element 29 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): AcLanguageText (42 B).
NakaList_CustomCopy_DestRhythmList:
	.incbin "includes/generated/naka_composer_style.bin", 0x2F6C, 0x2A
; [nakarest] NakaNode_CustomCopy_DestRhythmStatus  +0x2f96..+0x2fba (0xe1a67a, 36 B)
; [nakarest] widget record, element 30 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): PsCtmAttStrBox (36 B).
NakaNode_CustomCopy_DestRhythmStatus:
	.incbin "includes/generated/naka_composer_style.bin", 0x2F96, 0x24
; [nakarest] Naka0x3E_CustomCopy_ExecuteBtn2  +0x2fba..+0x2fee (0xe1a69e, 52 B)
; [nakarest] widget record, element 31 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): VwEditSwBox (44 B). 1 text the records point
; [nakarest] at (Viewable slot 0xbe (table 0xe1b926, 33 entries, InitializeSuna)): "EXECUTE"
; [nakarest] (VwEditSwBox.str of element 31).
Naka0x3E_CustomCopy_ExecuteBtn2:
	.incbin "includes/generated/naka_composer_style.bin", 0x2FBA, 0x34
; [nakarest] Naka0x3E_CustomCopy_AbortBtn2  +0x2fee..+0x3020 (0xe1a6d2, 50 B)
; [nakarest] widget record, element 32 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): VwEditSwBox (44 B). 1 text the records point
; [nakarest] at (Viewable slot 0xbe (table 0xe1b926, 33 entries, InitializeSuna)): "ABORT"
; [nakarest] (VwEditSwBox.str of element 32).
Naka0x3E_CustomCopy_AbortBtn2:
	.incbin "includes/generated/naka_composer_style.bin", 0x2FEE, 0x32
; [nakarest] NakaContainer_CustomCopy_FinalRoot  +0x3020..+0x304a (0xe1a704, 42 B)
; [nakarest] widget record, element 0 of Viewable slot 0xc8 (table 0xe1b9ae, 27 entries,
; [nakarest] InitializeSuna) ("MspBkslScreen"): TtlScreen (42 B).
NakaContainer_CustomCopy_FinalRoot:
	.incbin "includes/generated/naka_composer_style.bin", 0x3020, 0x2A
; [nakarest] String_MSP_BANK_SELECT  +0x304a..+0x305a (0xe1a72e, 16 B)
; [nakarest] 1 text the records point at (Viewable slot 0xc8 (table 0xe1b9ae, 27 entries,
; [nakarest] InitializeSuna)): "MSP BANK SELECT" (TtlScreen.title of element 0).
String_MSP_BANK_SELECT:
	.incbin "includes/generated/naka_composer_style.bin", 0x304A, 0x10
; External label offsets within the binary blob above.
