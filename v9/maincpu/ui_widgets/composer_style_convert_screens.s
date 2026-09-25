
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
; [nakarest] purpose not established: 2 bytes at 0xe176e4 that no registered NAKA table points into
NakaStr_PaintArrowProc_Empty:
	.incbin "includes/generated/naka_composer_style.bin", 0x0, 0x2
; [nakarest] naka_composer_style+0x2  +0x2..+0x12 (0xe176e6, 16 B)
; [nakarest] name string, entry 0 of Function slot 0x404 (table 0xe176dc, 1 entries,
; [nakarest] InitializeSuna) (names for Function slot 0x104): "PaintArrowProc".
	.incbin "includes/generated/naka_composer_style.bin", 0x2, 0x10
; [nakarest] naka_composer_style+0x12  +0x12..+0x90 (0xe176f6, 126 B)
; [nakarest] widget record, element 0 of Viewable slot 0x10 (table 0xe1b4e2, 3 entries,
; [nakarest] InitializeSuna) ("StylCnvWaitScreen"): TtlScreen (42 B). text the records point at,
; [nakarest] in Viewable slot 0x10 (table 0xe1b4e2, 3 entries, InitializeSuna): "STYLE CONVERT"
; [nakarest] (TtlScreen.title of element 0). widget records, elements 1-2 of Viewable slot 0x10
; [nakarest] (table 0xe1b4e2, 3 entries, InitializeSuna) ("StylCnvWaitScreen"): VwBox (28 B),
; [nakarest] AcLanguageText (42 B).
	.incbin "includes/generated/naka_composer_style.bin", 0x12, 0x7E
; [nakarest] naka_composer_style+0x90  +0x90..+0x1f6 (0xe17774, 358 B)
; [nakarest] widget record, element 0 of Viewable slot 0x11 (table 0xe1b4f2, 8 entries,
; [nakarest] InitializeSuna) ("StylCnvModlScreen"): TtlScreen (42 B). text the records point at,
; [nakarest] in Viewable slot 0x11 (table 0xe1b4f2, 8 entries, InitializeSuna): "STYLE TYPE
; [nakarest] SELECT" (TtlScreen.title of element 0). widget records, elements 1-3 of Viewable
; [nakarest] slot 0x11 (table 0xe1b4f2, 8 entries, InitializeSuna) ("StylCnvModlScreen"):
; [nakarest] IvMainEditSw (26 B), PsParaListBox (42 B), VwEditSwBox (44 B). text the records
; [nakarest] point at, in Viewable slot 0x11 (table 0xe1b4f2, 8 entries, InitializeSuna): "PREV"
; [nakarest] (VwEditSwBox.str of element 3). widget record, element 4 of Viewable slot 0x11
; [nakarest] (table 0xe1b4f2, 8 entries, InitializeSuna) ("StylCnvModlScreen"): VwWideESBox (46
; [nakarest] B). text the records point at, in Viewable slot 0x11 (table 0xe1b4f2, 8 entries,
; [nakarest] InitializeSuna): "" (VwWideESBox.str of element 4). widget record, element 5 of
; [nakarest] Viewable slot 0x11 (table 0xe1b4f2, 8 entries, InitializeSuna)
; [nakarest] ("StylCnvModlScreen"): VwEditSwBox (44 B). text the records point at, in Viewable
; [nakarest] slot 0x11 (table 0xe1b4f2, 8 entries, InitializeSuna): "NEXT" (VwEditSwBox.str of
; [nakarest] element 5). widget record, element 6 of Viewable slot 0x11 (table 0xe1b4f2, 8
; [nakarest] entries, InitializeSuna) ("StylCnvModlScreen"): VwEditSwBox (44 B). text the
; [nakarest] records point at, in Viewable slot 0x11 (table 0xe1b4f2, 8 entries,
; [nakarest] InitializeSuna): "" (VwEditSwBox.str of element 6). widget record, element 7 of
; [nakarest] Viewable slot 0x11 (table 0xe1b4f2, 8 entries, InitializeSuna)
; [nakarest] ("StylCnvModlScreen"): PsStylCnvVer (36 B).
	.incbin "includes/generated/naka_composer_style.bin", 0x90, 0x166
; [nakarest] naka_composer_style+0x1f6  +0x1f6..+0x334 (0xe178da, 318 B)
; [nakarest] widget record, element 0 of Viewable slot 0x12 (table 0xe1b516, 7 entries,
; [nakarest] InitializeSuna) ("StylCnvCnvtScreen"): TtlScreen (42 B). text the records point at,
; [nakarest] in Viewable slot 0x12 (table 0xe1b516, 7 entries, InitializeSuna): "STYLE CONVERT"
; [nakarest] (TtlScreen.title of element 0). widget records, elements 1-3 of Viewable slot 0x12
; [nakarest] (table 0xe1b516, 7 entries, InitializeSuna) ("StylCnvCnvtScreen"): IvMainEditSw (26
; [nakarest] B), PsParaListBox (42 B), VwEditSwBox (44 B). text the records point at, in
; [nakarest] Viewable slot 0x12 (table 0xe1b516, 7 entries, InitializeSuna): "PREV"
; [nakarest] (VwEditSwBox.str of element 3). widget record, element 4 of Viewable slot 0x12
; [nakarest] (table 0xe1b516, 7 entries, InitializeSuna) ("StylCnvCnvtScreen"): VwWideESBox (46
; [nakarest] B). text the records point at, in Viewable slot 0x12 (table 0xe1b516, 7 entries,
; [nakarest] InitializeSuna): "" (VwWideESBox.str of element 4). widget record, element 5 of
; [nakarest] Viewable slot 0x12 (table 0xe1b516, 7 entries, InitializeSuna)
; [nakarest] ("StylCnvCnvtScreen"): VwEditSwBox (44 B). text the records point at, in Viewable
; [nakarest] slot 0x12 (table 0xe1b516, 7 entries, InitializeSuna): "NEXT" (VwEditSwBox.str of
; [nakarest] element 5). widget record, element 6 of Viewable slot 0x12 (table 0xe1b516, 7
; [nakarest] entries, InitializeSuna) ("StylCnvCnvtScreen"): VwEditSwBox (44 B). text the
; [nakarest] records point at, in Viewable slot 0x12 (table 0xe1b516, 7 entries,
; [nakarest] InitializeSuna): "" (VwEditSwBox.str of element 6).
	.incbin "includes/generated/naka_composer_style.bin", 0x1F6, 0x13E
; [nakarest] naka_composer_style+0x334  +0x334..+0x410 (0xe17a18, 220 B)
; [nakarest] widget record, element 0 of Viewable slot 0x13 (table 0xe1b536, 4 entries,
; [nakarest] InitializeSuna) ("StylCnvStorScreen"): TtlScreen (42 B). text the records point at,
; [nakarest] in Viewable slot 0x13 (table 0xe1b536, 4 entries, InitializeSuna): "STORAGE DATA"
; [nakarest] (TtlScreen.title of element 0). widget record, element 1 of Viewable slot 0x13
; [nakarest] (table 0xe1b536, 4 entries, InitializeSuna) ("StylCnvStorScreen"): AcRamEditBox (58
; [nakarest] B). text the records point at, in Viewable slot 0x13 (table 0xe1b536, 4 entries,
; [nakarest] InitializeSuna): " Data Storage to :" (AcRamEditBox.caption of element 1). widget
; [nakarest] records, elements 2-3 of Viewable slot 0x13 (table 0xe1b536, 4 entries,
; [nakarest] InitializeSuna) ("StylCnvStorScreen"): AcIndexWideES (42 B), AcFuncEditSw (44 B).
	.incbin "includes/generated/naka_composer_style.bin", 0x334, 0xDC
; [nakarest] naka_composer_style+0x410  +0x410..+0x4a4 (0xe17af4, 148 B)
; [nakarest] widget record, element 0 of Viewable slot 0x14 (table 0xe1b54a, 4 entries,
; [nakarest] InitializeSuna) ("StylCnvTxtScreen"): TtlScreen (42 B). text the records point at,
; [nakarest] in Viewable slot 0x14 (table 0xe1b54a, 4 entries, InitializeSuna): "STYLE CONVERT"
; [nakarest] (TtlScreen.title of element 0). widget records, elements 1-3 of Viewable slot 0x14
; [nakarest] (table 0xe1b54a, 4 entries, InitializeSuna) ("StylCnvTxtScreen"): VwBox (28 B),
; [nakarest] PSSCTxtBox2 (38 B), IvMainEditSw (26 B).
	.incbin "includes/generated/naka_composer_style.bin", 0x410, 0x94
; [nakarest] naka_composer_style+0x4a4  +0x4a4..+0x606 (0xe17b88, 354 B)
; [nakarest] widget record, element 0 of Viewable slot 0x15 (table 0xe1b55e, 8 entries,
; [nakarest] InitializeSuna) ("StylCnvSelScreen"): TtlScreen (42 B). text the records point at,
; [nakarest] in Viewable slot 0x15 (table 0xe1b55e, 8 entries, InitializeSuna): "STYLE CONVERT"
; [nakarest] (TtlScreen.title of element 0). widget records, elements 1-3 of Viewable slot 0x15
; [nakarest] (table 0xe1b55e, 8 entries, InitializeSuna) ("StylCnvSelScreen"): IvMainEditSw (26
; [nakarest] B), PsParaListBox (42 B), VwEditSwBox (44 B). text the records point at, in
; [nakarest] Viewable slot 0x15 (table 0xe1b55e, 8 entries, InitializeSuna): "PREV"
; [nakarest] (VwEditSwBox.str of element 3). widget record, element 4 of Viewable slot 0x15
; [nakarest] (table 0xe1b55e, 8 entries, InitializeSuna) ("StylCnvSelScreen"): VwWideESBox (46
; [nakarest] B). text the records point at, in Viewable slot 0x15 (table 0xe1b55e, 8 entries,
; [nakarest] InitializeSuna): "" (VwWideESBox.str of element 4). widget record, element 5 of
; [nakarest] Viewable slot 0x15 (table 0xe1b55e, 8 entries, InitializeSuna)
; [nakarest] ("StylCnvSelScreen"): VwEditSwBox (44 B). text the records point at, in Viewable
; [nakarest] slot 0x15 (table 0xe1b55e, 8 entries, InitializeSuna): "NEXT" (VwEditSwBox.str of
; [nakarest] element 5). widget record, element 6 of Viewable slot 0x15 (table 0xe1b55e, 8
; [nakarest] entries, InitializeSuna) ("StylCnvSelScreen"): VwEditSwBox (44 B). text the records
; [nakarest] point at, in Viewable slot 0x15 (table 0xe1b55e, 8 entries, InitializeSuna): ""
; [nakarest] (VwEditSwBox.str of element 6). widget record, element 7 of Viewable slot 0x15
; [nakarest] (table 0xe1b55e, 8 entries, InitializeSuna) ("StylCnvSelScreen"): PsSCTxtBox (36
; [nakarest] B).
	.incbin "includes/generated/naka_composer_style.bin", 0x4A4, 0x162
; [nakarest] naka_composer_style+0x606  +0x606..+0x722 (0xe17cea, 284 B)
; [nakarest] widget record, element 0 of Viewable slot 0x16 (table 0xe1b582, 7 entries,
; [nakarest] InitializeSuna) ("StylCnvContScreen"): TtlScreen (42 B). text the records point at,
; [nakarest] in Viewable slot 0x16 (table 0xe1b582, 7 entries, InitializeSuna): "STYLE CONVERT"
; [nakarest] (TtlScreen.title of element 0). widget records, elements 1-3 of Viewable slot 0x16
; [nakarest] (table 0xe1b582, 7 entries, InitializeSuna) ("StylCnvContScreen"): IvMainEditSw (26
; [nakarest] B), VwBox (28 B), Label (32 B). text the records point at, in Viewable slot 0x16
; [nakarest] (table 0xe1b582, 7 entries, InitializeSuna): "Continue" (Label.str of element 3).
; [nakarest] widget record, element 4 of Viewable slot 0x16 (table 0xe1b582, 7 entries,
; [nakarest] InitializeSuna) ("StylCnvContScreen"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0x16 (table 0xe1b582, 7 entries, InitializeSuna): "Next ?" (Label.str
; [nakarest] of element 4). widget record, element 5 of Viewable slot 0x16 (table 0xe1b582, 7
; [nakarest] entries, InitializeSuna) ("StylCnvContScreen"): VwEditSwBox (44 B). text the
; [nakarest] records point at, in Viewable slot 0x16 (table 0xe1b582, 7 entries,
; [nakarest] InitializeSuna): "" (VwEditSwBox.str of element 5). widget record, element 6 of
; [nakarest] Viewable slot 0x16 (table 0xe1b582, 7 entries, InitializeSuna)
; [nakarest] ("StylCnvContScreen"): VwEditSwBox (44 B). text the records point at, in Viewable
; [nakarest] slot 0x16 (table 0xe1b582, 7 entries, InitializeSuna): "" (VwEditSwBox.str of
; [nakarest] element 6).
	.incbin "includes/generated/naka_composer_style.bin", 0x606, 0x11C
; [nakarest] naka_composer_style+0x722  +0x722..+0xa8c (0xe17e06, 874 B)
; [nakarest] widget record, element 0 of Viewable slot 0xb0 (table 0xe1b5a2, 18 entries,
; [nakarest] InitializeSuna) ("CmpMenuScreen"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0xb0 (table 0xe1b5a2, 18 entries, InitializeSuna): "COMPOSER MENU"
; [nakarest] (TtlScreen.title of element 0). widget record, element 1 of Viewable slot 0xb0
; [nakarest] (table 0xe1b5a2, 18 entries, InitializeSuna) ("CmpMenuScreen"): AcTitleMenu (54 B).
; [nakarest] text the records point at, in Viewable slot 0xb0 (table 0xe1b5a2, 18 entries,
; [nakarest] InitializeSuna): "BEND RANGE SET" (AcTitleMenu.str of element 1). widget record,
; [nakarest] element 2 of Viewable slot 0xb0 (table 0xe1b5a2, 18 entries, InitializeSuna)
; [nakarest] ("CmpMenuScreen"): AcTitleMenu (54 B). text the records point at, in Viewable slot
; [nakarest] 0xb0 (table 0xe1b5a2, 18 entries, InitializeSuna): "EASY COMPOSER" (AcTitleMenu.str
; [nakarest] of element 2). widget record, element 3 of Viewable slot 0xb0 (table 0xe1b5a2, 18
; [nakarest] entries, InitializeSuna) ("CmpMenuScreen"): AcTitleMenu (54 B). text the records
; [nakarest] point at, in Viewable slot 0xb0 (table 0xe1b5a2, 18 entries, InitializeSuna):
; [nakarest] "PATTERN COPY" (AcTitleMenu.str of element 3). widget record, element 4 of Viewable
; [nakarest] slot 0xb0 (table 0xe1b5a2, 18 entries, InitializeSuna) ("CmpMenuScreen"):
; [nakarest] AcTitleMenu (54 B). text the records point at, in Viewable slot 0xb0 (table
; [nakarest] 0xe1b5a2, 18 entries, InitializeSuna): "CUSTOM COPY" (AcTitleMenu.str of element
; [nakarest] 4). widget record, element 5 of Viewable slot 0xb0 (table 0xe1b5a2, 18 entries,
; [nakarest] InitializeSuna) ("CmpMenuScreen"): AcTitleMenu (54 B). text the records point at,
; [nakarest] in Viewable slot 0xb0 (table 0xe1b5a2, 18 entries, InitializeSuna): "SEQ TO
; [nakarest] COMPOSER COPY" (AcTitleMenu.str of element 5). widget record, element 6 of Viewable
; [nakarest] slot 0xb0 (table 0xe1b5a2, 18 entries, InitializeSuna) ("CmpMenuScreen"):
; [nakarest] AcTitleMenu (54 B). text the records point at, in Viewable slot 0xb0 (table
; [nakarest] 0xe1b5a2, 18 entries, InitializeSuna): "LOAD SINGLE COMPOSER" (AcTitleMenu.str of
; [nakarest] element 6). widget records, elements 7-11 of Viewable slot 0xb0 (table 0xe1b5a2, 18
; [nakarest] entries, InitializeSuna) ("CmpMenuScreen"): Line (26 B) x4, Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0xb0 (table 0xe1b5a2, 18 entries,
; [nakarest] InitializeSuna): "RECORDING" (Label.str of element 11). widget record, element 12
; [nakarest] of Viewable slot 0xb0 (table 0xe1b5a2, 18 entries, InitializeSuna)
; [nakarest] ("CmpMenuScreen"): Label (32 B). text the records point at, in Viewable slot 0xb0
; [nakarest] (table 0xe1b5a2, 18 entries, InitializeSuna): "MEMORY" (Label.str of element 12).
; [nakarest] widget records, elements 13-14 of Viewable slot 0xb0 (table 0xe1b5a2, 18 entries,
; [nakarest] InitializeSuna) ("CmpMenuScreen"): IvMainEditSw (26 B), VwMenuBox (50 B). text the
; [nakarest] records point at, in Viewable slot 0xb0 (table 0xe1b5a2, 18 entries,
; [nakarest] InitializeSuna): "A" (VwMenuBox.str of element 14). widget record, element 15 of
; [nakarest] Viewable slot 0xb0 (table 0xe1b5a2, 18 entries, InitializeSuna) ("CmpMenuScreen"):
; [nakarest] VwMenuBox (50 B). text the records point at, in Viewable slot 0xb0 (table 0xe1b5a2,
; [nakarest] 18 entries, InitializeSuna): "B" (VwMenuBox.str of element 15). widget record,
; [nakarest] element 16 of Viewable slot 0xb0 (table 0xe1b5a2, 18 entries, InitializeSuna)
; [nakarest] ("CmpMenuScreen"): VwMenuBox (50 B). text the records point at, in Viewable slot
; [nakarest] 0xb0 (table 0xe1b5a2, 18 entries, InitializeSuna): "C" (VwMenuBox.str of element
; [nakarest] 16). widget record, element 17 of Viewable slot 0xb0 (table 0xe1b5a2, 18 entries,
; [nakarest] InitializeSuna) ("CmpMenuScreen"): IvExitMode (26 B).
	.incbin "includes/generated/naka_composer_style.bin", 0x722, 0x36A
; [nakarest] naka_composer_style+0xa8c  +0xa8c..+0xd46 (0xe18170, 698 B)
; [nakarest] widget record, element 0 of Viewable slot 0xb1 (table 0xe1b5ee, 12 entries,
; [nakarest] InitializeSuna) ("CmpBkslScreen"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0xb1 (table 0xe1b5ee, 12 entries, InitializeSuna): "RECORD MEMORY"
; [nakarest] (TtlScreen.title of element 0). widget records, elements 1-2 of Viewable slot 0xb1
; [nakarest] (table 0xe1b5ee, 12 entries, InitializeSuna) ("CmpBkslScreen"): IvMainEditSw (26
; [nakarest] B), VwMenuBox (50 B). text the records point at, in Viewable slot 0xb1 (table
; [nakarest] 0xe1b5ee, 12 entries, InitializeSuna): "VARIATION 1" (VwMenuBox.str of element 2).
; [nakarest] widget record, element 3 of Viewable slot 0xb1 (table 0xe1b5ee, 12 entries,
; [nakarest] InitializeSuna) ("CmpBkslScreen"): VwMenuBox (50 B). text the records point at, in
; [nakarest] Viewable slot 0xb1 (table 0xe1b5ee, 12 entries, InitializeSuna): "VARIATION 3"
; [nakarest] (VwMenuBox.str of element 3). widget record, element 4 of Viewable slot 0xb1 (table
; [nakarest] 0xe1b5ee, 12 entries, InitializeSuna) ("CmpBkslScreen"): VwMenuBox (50 B). text the
; [nakarest] records point at, in Viewable slot 0xb1 (table 0xe1b5ee, 12 entries,
; [nakarest] InitializeSuna): "INTRO 1" (VwMenuBox.str of element 4). widget record, element 5
; [nakarest] of Viewable slot 0xb1 (table 0xe1b5ee, 12 entries, InitializeSuna)
; [nakarest] ("CmpBkslScreen"): VwMenuBox (50 B). text the records point at, in Viewable slot
; [nakarest] 0xb1 (table 0xe1b5ee, 12 entries, InitializeSuna): "FILL IN 1" (VwMenuBox.str of
; [nakarest] element 5). widget record, element 6 of Viewable slot 0xb1 (table 0xe1b5ee, 12
; [nakarest] entries, InitializeSuna) ("CmpBkslScreen"): VwMenuBox (50 B). text the records
; [nakarest] point at, in Viewable slot 0xb1 (table 0xe1b5ee, 12 entries, InitializeSuna):
; [nakarest] "ENDING 1" (VwMenuBox.str of element 6). widget record, element 7 of Viewable slot
; [nakarest] 0xb1 (table 0xe1b5ee, 12 entries, InitializeSuna) ("CmpBkslScreen"): VwMenuBox (50
; [nakarest] B). text the records point at, in Viewable slot 0xb1 (table 0xe1b5ee, 12 entries,
; [nakarest] InitializeSuna): " VARIATION 2" (VwMenuBox.str of element 7). widget record,
; [nakarest] element 8 of Viewable slot 0xb1 (table 0xe1b5ee, 12 entries, InitializeSuna)
; [nakarest] ("CmpBkslScreen"): VwMenuBox (50 B). text the records point at, in Viewable slot
; [nakarest] 0xb1 (table 0xe1b5ee, 12 entries, InitializeSuna): " VARIATION 4" (VwMenuBox.str of
; [nakarest] element 8). widget record, element 9 of Viewable slot 0xb1 (table 0xe1b5ee, 12
; [nakarest] entries, InitializeSuna) ("CmpBkslScreen"): VwMenuBox (50 B). text the records
; [nakarest] point at, in Viewable slot 0xb1 (table 0xe1b5ee, 12 entries, InitializeSuna):
; [nakarest] "INTRO 2" (VwMenuBox.str of element 9). widget record, element 10 of Viewable slot
; [nakarest] 0xb1 (table 0xe1b5ee, 12 entries, InitializeSuna) ("CmpBkslScreen"): VwMenuBox (50
; [nakarest] B). text the records point at, in Viewable slot 0xb1 (table 0xe1b5ee, 12 entries,
; [nakarest] InitializeSuna): "FILL IN 2" (VwMenuBox.str of element 10). widget record, element
; [nakarest] 11 of Viewable slot 0xb1 (table 0xe1b5ee, 12 entries, InitializeSuna)
; [nakarest] ("CmpBkslScreen"): VwMenuBox (50 B). text the records point at, in Viewable slot
; [nakarest] 0xb1 (table 0xe1b5ee, 12 entries, InitializeSuna): "ENDING 2" (VwMenuBox.str of
; [nakarest] element 11).
	.incbin "includes/generated/naka_composer_style.bin", 0xA8C, 0x2BA
; [nakarest] naka_composer_style+0xd46  +0xd46..+0x10fa (0xe1842a, 948 B)
; [nakarest] widget record, element 0 of Viewable slot 0xb2 (table 0xe1b622, 22 entries,
; [nakarest] InitializeSuna) ("CmpBkslSScreen"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0xb2 (table 0xe1b622, 22 entries, InitializeSuna): "RECORDING"
; [nakarest] (TtlScreen.title of element 0). widget records, elements 1-2 of Viewable slot 0xb2
; [nakarest] (table 0xe1b622, 22 entries, InitializeSuna) ("CmpBkslSScreen"): Box (26 B), Label
; [nakarest] (32 B). text the records point at, in Viewable slot 0xb2 (table 0xe1b622, 22
; [nakarest] entries, InitializeSuna): "Memory:" (Label.str of element 2). widget records,
; [nakarest] elements 3-4 of Viewable slot 0xb2 (table 0xe1b622, 22 entries, InitializeSuna)
; [nakarest] ("CmpBkslSScreen"): IvMainEditSw (26 B), VwMenuBox (50 B). text the records point
; [nakarest] at, in Viewable slot 0xb2 (table 0xe1b622, 22 entries, InitializeSuna): "RECORD
; [nakarest] SETTING" (VwMenuBox.str of element 4). widget record, element 5 of Viewable slot
; [nakarest] 0xb2 (table 0xe1b622, 22 entries, InitializeSuna) ("CmpBkslSScreen"): VwEditSwBox
; [nakarest] (44 B). text the records point at, in Viewable slot 0xb2 (table 0xe1b622, 22
; [nakarest] entries, InitializeSuna): "DRM" (VwEditSwBox.str of element 5). widget record,
; [nakarest] element 6 of Viewable slot 0xb2 (table 0xe1b622, 22 entries, InitializeSuna)
; [nakarest] ("CmpBkslSScreen"): VwEditSwBox (44 B). text the records point at, in Viewable slot
; [nakarest] 0xb2 (table 0xe1b622, 22 entries, InitializeSuna): "AC3" (VwEditSwBox.str of
; [nakarest] element 6). widget record, element 7 of Viewable slot 0xb2 (table 0xe1b622, 22
; [nakarest] entries, InitializeSuna) ("CmpBkslSScreen"): VwEditSwBox (44 B). text the records
; [nakarest] point at, in Viewable slot 0xb2 (table 0xe1b622, 22 entries, InitializeSuna): "AC2"
; [nakarest] (VwEditSwBox.str of element 7). widget record, element 8 of Viewable slot 0xb2
; [nakarest] (table 0xe1b622, 22 entries, InitializeSuna) ("CmpBkslSScreen"): VwEditSwBox (44
; [nakarest] B). text the records point at, in Viewable slot 0xb2 (table 0xe1b622, 22 entries,
; [nakarest] InitializeSuna): "AC1" (VwEditSwBox.str of element 8). widget record, element 9 of
; [nakarest] Viewable slot 0xb2 (table 0xe1b622, 22 entries, InitializeSuna) ("CmpBkslSScreen"):
; [nakarest] VwEditSwBox (44 B). text the records point at, in Viewable slot 0xb2 (table
; [nakarest] 0xe1b622, 22 entries, InitializeSuna): "BAS" (VwEditSwBox.str of element 9). widget
; [nakarest] records, elements 10-11 of Viewable slot 0xb2 (table 0xe1b622, 22 entries,
; [nakarest] InitializeSuna) ("CmpBkslSScreen"): AcMemNoBox (36 B), Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0xb2 (table 0xe1b622, 22 entries,
; [nakarest] InitializeSuna): "START RECORDING" (Label.str of element 11). widget records,
; [nakarest] elements 12-16 of Viewable slot 0xb2 (table 0xe1b622, 22 entries, InitializeSuna)
; [nakarest] ("CmpBkslSScreen"): Line (26 B) x4, CmpNameMenuBox (50 B). text the records point
; [nakarest] at, in Viewable slot 0xb2 (table 0xe1b622, 22 entries, InitializeSuna): "VARIATION
; [nakarest] NAMING" (CmpNameMenuBox.str of element 16). widget record, element 17 of Viewable
; [nakarest] slot 0xb2 (table 0xe1b622, 22 entries, InitializeSuna) ("CmpBkslSScreen"):
; [nakarest] VwMenuBox (50 B). text the records point at, in Viewable slot 0xb2 (table 0xe1b622,
; [nakarest] 22 entries, InitializeSuna): "CLEAR THE ENTIRE PATTERN" (VwMenuBox.str of element
; [nakarest] 17). widget records, elements 18-21 of Viewable slot 0xb2 (table 0xe1b622, 22
; [nakarest] entries, InitializeSuna) ("CmpBkslSScreen"): Window (36 B), AcFuncEditSw (44 B) x2,
; [nakarest] AcLanguageText (42 B).
	.incbin "includes/generated/naka_composer_style.bin", 0xD46, 0x3B4
; [nakarest] naka_composer_style+0x10fa  +0x10fa..+0x11ca (0xe187de, 208 B)
; [nakarest] widget record, element 0 of Viewable slot 0xb3 (table 0xe1b67e, 5 entries,
; [nakarest] InitializeSuna) ("CmpNamingScreen"): TtlScreen (42 B). text the records point at,
; [nakarest] in Viewable slot 0xb3 (table 0xe1b67e, 5 entries, InitializeSuna): "VARIATION
; [nakarest] NAMING" (TtlScreen.title of element 0). widget records, elements 1-3 of Viewable
; [nakarest] slot 0xb3 (table 0xe1b67e, 5 entries, InitializeSuna) ("CmpNamingScreen"): IvNaming
; [nakarest] (26 B), AcFuncEditSw (44 B), Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xb3 (table 0xe1b67e, 5 entries, InitializeSuna): "MEMORY :" (Label.str of
; [nakarest] element 3). widget record, element 4 of Viewable slot 0xb3 (table 0xe1b67e, 5
; [nakarest] entries, InitializeSuna) ("CmpNamingScreen"): AcMemNoBox (36 B).
	.incbin "includes/generated/naka_composer_style.bin", 0x10FA, 0xD0
; [nakarest] naka_composer_style+0x11ca  +0x11ca..+0x1580 (0xe188ae, 950 B)
; [nakarest] widget record, element 0 of Viewable slot 0xb4 (table 0xe1b696, 18 entries,
; [nakarest] InitializeSuna) ("CmpSetScreen"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0xb4 (table 0xe1b696, 18 entries, InitializeSuna): "RECORD SETTING"
; [nakarest] (TtlScreen.title of element 0). widget records, elements 1-7 of Viewable slot 0xb4
; [nakarest] (table 0xe1b696, 18 entries, InitializeSuna) ("CmpSetScreen"): IvMainEditSw (26 B),
; [nakarest] AcWindowPage (36 B), IvPageControl (28 B) x2, IvShowHide (26 B), Window (36 B),
; [nakarest] AcCmpSetGridBox (74 B). text the records point at, in Viewable slot 0xb4 (table
; [nakarest] 0xe1b696, 18 entries, InitializeSuna): "|MEASURE :|TIME SIGNATURE:|-| | KEY "
; [nakarest] (AcCmpSetGridBox.fixedrow of element 7); " MEASURE &|TIME SIGNATURE"
; [nakarest] (AcCmpSetGridBox.fixedcol of element 7). widget record, element 8 of Viewable slot
; [nakarest] 0xb4 (table 0xe1b696, 18 entries, InitializeSuna) ("CmpSetScreen"): Label (32 B).
; [nakarest] text the records point at, in Viewable slot 0xb4 (table 0xe1b696, 18 entries,
; [nakarest] InitializeSuna): "RECORD SETTING" (Label.str of element 8). widget records,
; [nakarest] elements 9-11 of Viewable slot 0xb4 (table 0xe1b696, 18 entries, InitializeSuna)
; [nakarest] ("CmpSetScreen"): AcIndexWideES (42 B) x2, Label (32 B). text the records point at,
; [nakarest] in Viewable slot 0xb4 (table 0xe1b696, 18 entries, InitializeSuna): "ITEM"
; [nakarest] (Label.str of element 11). widget record, element 12 of Viewable slot 0xb4 (table
; [nakarest] 0xe1b696, 18 entries, InitializeSuna) ("CmpSetScreen"): Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0xb4 (table 0xe1b696, 18 entries,
; [nakarest] InitializeSuna): "VALUE" (Label.str of element 12). widget records, elements 13-14
; [nakarest] of Viewable slot 0xb4 (table 0xe1b696, 18 entries, InitializeSuna)
; [nakarest] ("CmpSetScreen"): Window (36 B), AcGridBox (74 B). text the records point at, in
; [nakarest] Viewable slot 0xb4 (table 0xe1b696, 18 entries, InitializeSuna):
; [nakarest] "|-|BASS|ACCOMP1|ACCOMP2|ACCOMP3" (AcGridBox.fixedrow of element 14); " PART |
; [nakarest] PANPOT |PITCH POINT" (AcGridBox.fixedcol of element 14). widget records, elements
; [nakarest] 15-17 of Viewable slot 0xb4 (table 0xe1b696, 18 entries, InitializeSuna)
; [nakarest] ("CmpSetScreen"): AcIndexWideES (42 B) x3.
	.incbin "includes/generated/naka_composer_style.bin", 0x11CA, 0x3B6
; [nakarest] naka_composer_style+0x1580  +0x1580..+0x1a2a (0xe18c64, 1194 B)
; [nakarest] widget record, element 0 of Viewable slot 0xb5 (table 0xe1b6e2, 31 entries,
; [nakarest] InitializeSuna) ("CmpRealScreen"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0xb5 (table 0xe1b6e2, 31 entries, InitializeSuna): "REALTIME
; [nakarest] RECORDING" (TtlScreen.title of element 0). widget records, elements 1-3 of Viewable
; [nakarest] slot 0xb5 (table 0xe1b6e2, 31 entries, InitializeSuna) ("CmpRealScreen"): Box (26
; [nakarest] B), PsCmpMemBox (36 B), Label (32 B). text the records point at, in Viewable slot
; [nakarest] 0xb5 (table 0xe1b6e2, 31 entries, InitializeSuna): "%" (Label.str of element 3).
; [nakarest] widget record, element 4 of Viewable slot 0xb5 (table 0xe1b6e2, 31 entries,
; [nakarest] InitializeSuna) ("CmpRealScreen"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xb5 (table 0xe1b6e2, 31 entries, InitializeSuna): "PATTERN ="
; [nakarest] (Label.str of element 4). widget record, element 5 of Viewable slot 0xb5 (table
; [nakarest] 0xe1b6e2, 31 entries, InitializeSuna) ("CmpRealScreen"): Label (32 B). text the
; [nakarest] records point at, in Viewable slot 0xb5 (table 0xe1b6e2, 31 entries,
; [nakarest] InitializeSuna): "TEMPO =" (Label.str of element 5). widget record, element 6 of
; [nakarest] Viewable slot 0xb5 (table 0xe1b6e2, 31 entries, InitializeSuna) ("CmpRealScreen"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0xb5 (table 0xe1b6e2, 31
; [nakarest] entries, InitializeSuna): "QUANTIZE=" (Label.str of element 6). widget record,
; [nakarest] element 7 of Viewable slot 0xb5 (table 0xe1b6e2, 31 entries, InitializeSuna)
; [nakarest] ("CmpRealScreen"): Label (32 B). text the records point at, in Viewable slot 0xb5
; [nakarest] (table 0xe1b6e2, 31 entries, InitializeSuna): "MEASURE =" (Label.str of element 7).
; [nakarest] widget record, element 8 of Viewable slot 0xb5 (table 0xe1b6e2, 31 entries,
; [nakarest] InitializeSuna) ("CmpRealScreen"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xb5 (table 0xe1b6e2, 31 entries, InitializeSuna): "MEMORY ="
; [nakarest] (Label.str of element 8). widget records, elements 9-10 of Viewable slot 0xb5
; [nakarest] (table 0xe1b6e2, 31 entries, InitializeSuna) ("CmpRealScreen"): IvMainEditSw (26
; [nakarest] B), VwEditSwBox (44 B). text the records point at, in Viewable slot 0xb5 (table
; [nakarest] 0xe1b6e2, 31 entries, InitializeSuna): "DRM" (VwEditSwBox.str of element 10).
; [nakarest] widget record, element 11 of Viewable slot 0xb5 (table 0xe1b6e2, 31 entries,
; [nakarest] InitializeSuna) ("CmpRealScreen"): VwEditSwBox (44 B). text the records point at,
; [nakarest] in Viewable slot 0xb5 (table 0xe1b6e2, 31 entries, InitializeSuna): "AC3"
; [nakarest] (VwEditSwBox.str of element 11). widget record, element 12 of Viewable slot 0xb5
; [nakarest] (table 0xe1b6e2, 31 entries, InitializeSuna) ("CmpRealScreen"): VwEditSwBox (44 B).
; [nakarest] text the records point at, in Viewable slot 0xb5 (table 0xe1b6e2, 31 entries,
; [nakarest] InitializeSuna): "AC2" (VwEditSwBox.str of element 12). widget record, element 13
; [nakarest] of Viewable slot 0xb5 (table 0xe1b6e2, 31 entries, InitializeSuna)
; [nakarest] ("CmpRealScreen"): VwEditSwBox (44 B). text the records point at, in Viewable slot
; [nakarest] 0xb5 (table 0xe1b6e2, 31 entries, InitializeSuna): "AC1" (VwEditSwBox.str of
; [nakarest] element 13). widget record, element 14 of Viewable slot 0xb5 (table 0xe1b6e2, 31
; [nakarest] entries, InitializeSuna) ("CmpRealScreen"): VwEditSwBox (44 B). text the records
; [nakarest] point at, in Viewable slot 0xb5 (table 0xe1b6e2, 31 entries, InitializeSuna): "BAS"
; [nakarest] (VwEditSwBox.str of element 14). widget records, elements 15-16 of Viewable slot
; [nakarest] 0xb5 (table 0xe1b6e2, 31 entries, InitializeSuna) ("CmpRealScreen"): AcCmpTempoBox
; [nakarest] (36 B), AcTitleMenu (54 B). text the records point at, in Viewable slot 0xb5 (table
; [nakarest] 0xe1b6e2, 31 entries, InitializeSuna): "BAL" (AcTitleMenu.str of element 16).
; [nakarest] widget record, element 17 of Viewable slot 0xb5 (table 0xe1b6e2, 31 entries,
; [nakarest] InitializeSuna) ("CmpRealScreen"): AcTitleMenu (54 B). text the records point at,
; [nakarest] in Viewable slot 0xb5 (table 0xe1b6e2, 31 entries, InitializeSuna): "STEP"
; [nakarest] (AcTitleMenu.str of element 17). widget records, elements 18-19 of Viewable slot
; [nakarest] 0xb5 (table 0xe1b6e2, 31 entries, InitializeSuna) ("CmpRealScreen"): AcMemNoBox (36
; [nakarest] B), VwMenuBox (50 B). text the records point at, in Viewable slot 0xb5 (table
; [nakarest] 0xe1b6e2, 31 entries, InitializeSuna): "PART CLR" (VwMenuBox.str of element 19).
; [nakarest] widget record, element 20 of Viewable slot 0xb5 (table 0xe1b6e2, 31 entries,
; [nakarest] InitializeSuna) ("CmpRealScreen"): VwMenuBox (50 B). text the records point at, in
; [nakarest] Viewable slot 0xb5 (table 0xe1b6e2, 31 entries, InitializeSuna): "ALL ERAS"
; [nakarest] (VwMenuBox.str of element 20). widget record, element 21 of Viewable slot 0xb5
; [nakarest] (table 0xe1b6e2, 31 entries, InitializeSuna) ("CmpRealScreen"): VwMenuBox (50 B).
; [nakarest] text the records point at, in Viewable slot 0xb5 (table 0xe1b6e2, 31 entries,
; [nakarest] InitializeSuna): "INST ERS" (VwMenuBox.str of element 21). widget record, element
; [nakarest] 22 of Viewable slot 0xb5 (table 0xe1b6e2, 31 entries, InitializeSuna)
; [nakarest] ("CmpRealScreen"): VwMenuBox (50 B). text the records point at, in Viewable slot
; [nakarest] 0xb5 (table 0xe1b6e2, 31 entries, InitializeSuna): "QUANTIZE" (VwMenuBox.str of
; [nakarest] element 22). widget record, element 23 of Viewable slot 0xb5 (table 0xe1b6e2, 31
; [nakarest] entries, InitializeSuna) ("CmpRealScreen"): VwMenuBox (50 B). text the records
; [nakarest] point at, in Viewable slot 0xb5 (table 0xe1b6e2, 31 entries, InitializeSuna): "
; [nakarest] SOLO" (VwMenuBox.str of element 23). widget records, elements 29-30 of Viewable
; [nakarest] slot 0xb5 (table 0xe1b6e2, 31 entries, InitializeSuna) ("CmpRealScreen"):
; [nakarest] PsCmpQtzBox (36 B), PsCmpMeasBox (36 B).
	.incbin "includes/generated/naka_composer_style.bin", 0x1580, 0x4AA
; [nakarest] naka_composer_style+0x1a2a  +0x1a2a..+0x1a4c (0xe1910e, 34 B)
; [nakarest] widget record, element 0 of Viewable slot 0xb6 (table 0xe1b762, 1 entries,
; [nakarest] InitializeSuna): IvDirmdScreen (34 B).
	.incbin "includes/generated/naka_composer_style.bin", 0x1A2A, 0x22
; [nakarest] naka_composer_style+0x1a4c  +0x1a4c..+0x1b24 (0xe19130, 216 B)
; [nakarest] widget record, element 0 of Viewable slot 0xb7 (table 0xe1b76a, 6 entries,
; [nakarest] InitializeSuna) ("CmpBalScreen"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0xb7 (table 0xe1b76a, 6 entries, InitializeSuna): "PART BALANCE"
; [nakarest] (TtlScreen.title of element 0). widget records, elements 1-5 of Viewable slot 0xb7
; [nakarest] (table 0xe1b76a, 6 entries, InitializeSuna) ("CmpBalScreen"): AcMixerVol (32 B) x5.
	.incbin "includes/generated/naka_composer_style.bin", 0x1A4C, 0xD8
; [nakarest] naka_composer_style+0x1b24  +0x1b24..+0x1eba (0xe19208, 918 B)
; [nakarest] widget record, element 0 of Viewable slot 0xb8 (table 0xe1b786, 33 entries,
; [nakarest] InitializeSuna) ("CmpNcpScreen"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0xb8 (table 0xe1b786, 33 entries, InitializeSuna): "PATTERN COPY"
; [nakarest] (TtlScreen.title of element 0). widget records, elements 1-2 of Viewable slot 0xb8
; [nakarest] (table 0xe1b786, 33 entries, InitializeSuna) ("CmpNcpScreen"): IvMainEditSw (26 B),
; [nakarest] VwWideESBox (46 B). text the records point at, in Viewable slot 0xb8 (table
; [nakarest] 0xe1b786, 33 entries, InitializeSuna): "" (VwWideESBox.str of element 2). widget
; [nakarest] record, element 3 of Viewable slot 0xb8 (table 0xe1b786, 33 entries,
; [nakarest] InitializeSuna) ("CmpNcpScreen"): VwWideESBox (46 B). text the records point at, in
; [nakarest] Viewable slot 0xb8 (table 0xe1b786, 33 entries, InitializeSuna): ""
; [nakarest] (VwWideESBox.str of element 3). widget record, element 4 of Viewable slot 0xb8
; [nakarest] (table 0xe1b786, 33 entries, InitializeSuna) ("CmpNcpScreen"): VwWideESBox (46 B).
; [nakarest] text the records point at, in Viewable slot 0xb8 (table 0xe1b786, 33 entries,
; [nakarest] InitializeSuna): "" (VwWideESBox.str of element 4). widget record, element 5 of
; [nakarest] Viewable slot 0xb8 (table 0xe1b786, 33 entries, InitializeSuna) ("CmpNcpScreen"):
; [nakarest] VwWideESBox (46 B). text the records point at, in Viewable slot 0xb8 (table
; [nakarest] 0xe1b786, 33 entries, InitializeSuna): "" (VwWideESBox.str of element 5). widget
; [nakarest] record, element 6 of Viewable slot 0xb8 (table 0xe1b786, 33 entries,
; [nakarest] InitializeSuna) ("CmpNcpScreen"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xb8 (table 0xe1b786, 33 entries, InitializeSuna): "ITEM VALUE ITEM
; [nakarest] VALUE" (Label.str of element 6). widget record, element 7 of Viewable slot 0xb8
; [nakarest] (table 0xe1b786, 33 entries, InitializeSuna) ("CmpNcpScreen"): Label (32 B). text
; [nakarest] the records point at, in Viewable slot 0xb8 (table 0xe1b786, 33 entries,
; [nakarest] InitializeSuna): "FROM" (Label.str of element 7). widget records, elements 8-12 of
; [nakarest] Viewable slot 0xb8 (table 0xe1b786, 33 entries, InitializeSuna) ("CmpNcpScreen"):
; [nakarest] Line (26 B) x4, Label (32 B). text the records point at, in Viewable slot 0xb8
; [nakarest] (table 0xe1b786, 33 entries, InitializeSuna): "TO" (Label.str of element 12).
; [nakarest] widget records, elements 13-17, 19 of Viewable slot 0xb8 (table 0xe1b786, 33
; [nakarest] entries, InitializeSuna) ("CmpNcpScreen"): Line (26 B) x4, Box (26 B), Label (32
; [nakarest] B). text the records point at, in Viewable slot 0xb8 (table 0xe1b786, 33 entries,
; [nakarest] InitializeSuna): "GROUP:" (Label.str of element 19). widget record, element 20 of
; [nakarest] Viewable slot 0xb8 (table 0xe1b786, 33 entries, InitializeSuna) ("CmpNcpScreen"):
; [nakarest] Label (32 B). text the records point at, in Viewable slot 0xb8 (table 0xe1b786, 33
; [nakarest] entries, InitializeSuna): "RHYTHM:" (Label.str of element 20). widget record,
; [nakarest] element 21 of Viewable slot 0xb8 (table 0xe1b786, 33 entries, InitializeSuna)
; [nakarest] ("CmpNcpScreen"): Label (32 B). text the records point at, in Viewable slot 0xb8
; [nakarest] (table 0xe1b786, 33 entries, InitializeSuna): "PATTERN:" (Label.str of element 21).
; [nakarest] widget record, element 22 of Viewable slot 0xb8 (table 0xe1b786, 33 entries,
; [nakarest] InitializeSuna) ("CmpNcpScreen"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xb8 (table 0xe1b786, 33 entries, InitializeSuna): "FROM" (Label.str
; [nakarest] of element 22). widget record, element 23 of Viewable slot 0xb8 (table 0xe1b786, 33
; [nakarest] entries, InitializeSuna) ("CmpNcpScreen"): Label (32 B). text the records point at,
; [nakarest] in Viewable slot 0xb8 (table 0xe1b786, 33 entries, InitializeSuna): "TO" (Label.str
; [nakarest] of element 23). widget record, element 24 of Viewable slot 0xb8 (table 0xe1b786, 33
; [nakarest] entries, InitializeSuna) ("CmpNcpScreen"): VwEditSwBox (44 B). text the records
; [nakarest] point at, in Viewable slot 0xb8 (table 0xe1b786, 33 entries, InitializeSuna): ""
; [nakarest] (VwEditSwBox.str of element 24). widget record, element 25 of Viewable slot 0xb8
; [nakarest] (table 0xe1b786, 33 entries, InitializeSuna) ("CmpNcpScreen"): Box (26 B).
	.incbin "includes/generated/naka_composer_style.bin", 0x1B24, 0x396
; [nakarest] NakaLabel_PatternCopy_MemoryLabel  +0x1eba..+0x1ee2 (0xe1959e, 40 B)
; [nakarest] widget record, element 28 of Viewable slot 0xb8 (table 0xe1b786, 33 entries,
; [nakarest] InitializeSuna) ("CmpNcpScreen"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xb8 (table 0xe1b786, 33 entries, InitializeSuna): "MEMORY:"
; [nakarest] (Label.str of element 28).
NakaLabel_PatternCopy_MemoryLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x1EBA, 0x28
; [nakarest] NakaLabel_PatternCopy_PatMemLabel  +0x1ee2..+0x1f0c (0xe195c6, 42 B)
; [nakarest] widget record, element 29 of Viewable slot 0xb8 (table 0xe1b786, 33 entries,
; [nakarest] InitializeSuna) ("CmpNcpScreen"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xb8 (table 0xe1b786, 33 entries, InitializeSuna): "PATTERN:"
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
; [nakarest] InitializeSuna) ("S2CScreen"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna): "SEQ TO COMPOSER
; [nakarest] COPY" (TtlScreen.title of element 0).
NakaContainer_SeqToComposer_Root:
	.incbin "includes/generated/naka_composer_style.bin", 0x1F2C, 0x40
; [nakarest] Naka0x3e_SeqToComposer_DrmBtn  +0x1f6c..+0x1f9a (0xe19650, 46 B)
; [nakarest] widget record, element 1 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): VwEditSwBox (44 B). text the records point at, in
; [nakarest] Viewable slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna): ""
; [nakarest] (VwEditSwBox.str of element 1).
Naka0x3E_SeqToComposer_DrmBtn:
	.incbin "includes/generated/naka_composer_style.bin", 0x1F6C, 0x2E
; [nakarest] Naka0x3e_SeqToComposer_Ac3Btn  +0x1f9a..+0x1fc8 (0xe1967e, 46 B)
; [nakarest] widget record, element 2 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): VwEditSwBox (44 B). text the records point at, in
; [nakarest] Viewable slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna): ""
; [nakarest] (VwEditSwBox.str of element 2).
Naka0x3E_SeqToComposer_Ac3Btn:
	.incbin "includes/generated/naka_composer_style.bin", 0x1F9A, 0x2E
; [nakarest] Naka0x3e_SeqToComposer_Ac2Btn  +0x1fc8..+0x1ff6 (0xe196ac, 46 B)
; [nakarest] widget record, element 3 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): VwEditSwBox (44 B). text the records point at, in
; [nakarest] Viewable slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna): ""
; [nakarest] (VwEditSwBox.str of element 3).
Naka0x3E_SeqToComposer_Ac2Btn:
	.incbin "includes/generated/naka_composer_style.bin", 0x1FC8, 0x2E
; [nakarest] Naka0x29_SeqToComposer_Scrollbar  +0x1ff6..+0x2010 (0xe196da, 26 B)
; [nakarest] widget record, element 4 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): IvMainEditSw (26 B).
Naka0x29_SeqToComposer_Scrollbar:
	.incbin "includes/generated/naka_composer_style.bin", 0x1FF6, 0x1A
; [nakarest] Naka0x3e_SeqToComposer_SourceBtn  +0x2010..+0x203e (0xe196f4, 46 B)
; [nakarest] widget record, element 5 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): VwEditSwBox (44 B). text the records point at, in
; [nakarest] Viewable slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna): ""
; [nakarest] (VwEditSwBox.str of element 5).
Naka0x3E_SeqToComposer_SourceBtn:
	.incbin "includes/generated/naka_composer_style.bin", 0x2010, 0x2E
; [nakarest] Naka0x3e_SeqToComposer_DestBtn  +0x203e..+0x206c (0xe19722, 46 B)
; [nakarest] widget record, element 6 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): VwEditSwBox (44 B). text the records point at, in
; [nakarest] Viewable slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna): ""
; [nakarest] (VwEditSwBox.str of element 6).
Naka0x3E_SeqToComposer_DestBtn:
	.incbin "includes/generated/naka_composer_style.bin", 0x203E, 0x2E
; [nakarest] Naka0x3e_SeqToComposer_InfoBtn  +0x206c..+0x209a (0xe19750, 46 B)
; [nakarest] widget record, element 7 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): VwEditSwBox (44 B). text the records point at, in
; [nakarest] Viewable slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna): ""
; [nakarest] (VwEditSwBox.str of element 7).
Naka0x3E_SeqToComposer_InfoBtn:
	.incbin "includes/generated/naka_composer_style.bin", 0x206C, 0x2E
; [nakarest] NakaLabel_SeqToComposer_FirstLast  +0x209a..+0x20c6 (0xe1977e, 44 B)
; [nakarest] widget record, element 8 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna): "FIRST LAST" (Label.str of
; [nakarest] element 8).
NakaLabel_SeqToComposer_FirstLast:
	.incbin "includes/generated/naka_composer_style.bin", 0x209A, 0x2C
; [nakarest] NakaLabel_SeqToComposer_MeasureLabel  +0x20c6..+0x20ee (0xe197aa, 40 B)
; [nakarest] widget record, element 9 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna): "MEASURE" (Label.str of
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
; [nakarest] InitializeSuna) ("S2CScreen"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna): "TRANS" (Label.str of
; [nakarest] element 14).
NakaLabel_SeqToComposer_TransLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x2156, 0x26
; [nakarest] NakaLabel_SeqToComposer_TransPose  +0x217c..+0x21a2 (0xe19860, 38 B)
; [nakarest] widget record, element 15 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna): "-POSE" (Label.str of
; [nakarest] element 15).
NakaLabel_SeqToComposer_TransPose:
	.incbin "includes/generated/naka_composer_style.bin", 0x217C, 0x26
; [nakarest] NakaLabel_SeqToComposer_SequencerLabel  +0x21a2..+0x21cc (0xe19886, 42 B)
; [nakarest] widget record, element 16 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna): "SEQUENCER" (Label.str of
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
; [nakarest] InitializeSuna) ("S2CScreen"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna): "FIRST" (Label.str of
; [nakarest] element 19).
NakaLabel_SeqToComposer_FirstLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x2200, 0x26
; [nakarest] NakaLabel_SeqToComposer_MeasFirstLabel  +0x2226..+0x224c (0xe1990a, 38 B)
; [nakarest] widget record, element 20 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna): "MEAS:" (Label.str of
; [nakarest] element 20).
NakaLabel_SeqToComposer_MeasFirstLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x2226, 0x26
; [nakarest] NakaLabel_SeqToComposer_LastLabel  +0x224c..+0x2272 (0xe19930, 38 B)
; [nakarest] widget record, element 21 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna): "LAST" (Label.str of
; [nakarest] element 21).
NakaLabel_SeqToComposer_LastLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x224C, 0x26
; [nakarest] NakaLabel_SeqToComposer_MeasLastLabel  +0x2272..+0x2298 (0xe19956, 38 B)
; [nakarest] widget record, element 22 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna): "MEAS:" (Label.str of
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
; [nakarest] InitializeSuna) ("S2CScreen"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna): "TRN" (Label.str of element
; [nakarest] 25).
NakaLabel_SeqToComposer_TrnLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x22B2, 0x24
; [nakarest] NakaLabel_SeqToComposer_MemLabel  +0x22d6..+0x22fa (0xe199ba, 36 B)
; [nakarest] widget record, element 26 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna): "MEM" (Label.str of element
; [nakarest] 26).
NakaLabel_SeqToComposer_MemLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x22D6, 0x24
; [nakarest] NakaLabel_SeqToComposer_ComposerMemory  +0x22fa..+0x232a (0xe199de, 48 B)
; [nakarest] widget record, element 27 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): Label (32 B). text the records point at, in Viewable
; [nakarest] slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna): "COMPOSER MEMORY"
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
; [nakarest] InitializeSuna) ("S2CScreen"): S2cGridBox (74 B). text the records point at, in
; [nakarest] Viewable slot 0xb9 (table 0xe1b80e, 37 entries, InitializeSuna):
; [nakarest] "|-|DRUMS|BASS|ACCOMP1|ACCOMP2|ACCOMP3" (S2cGridBox.fixedrow of element 33); " PART
; [nakarest] |TRACK" (S2cGridBox.fixedcol of element 33).
NakaNode_SeqToComposer_PartDisplay:
	.incbin "includes/generated/naka_composer_style.bin", 0x2392, 0x7E
; [nakarest] Naka0x1f_SeqToComposer_PartSel1  +0x2410..+0x2438 (0xe19af4, 40 B)
; [nakarest] widget record, element 34 of Viewable slot 0xb9 (table 0xe1b80e, 37 entries,
; [nakarest] InitializeSuna) ("S2CScreen"): AcIndexEditSw (40 B).
Naka0x1F_SeqToComposer_PartSel1:
	.incbin "includes/generated/naka_composer_style.bin", 0x2410, 0x28
; [nakarest] Naka0x1f_SeqToComposer_PartSel2  +0x2438..+0x2460 (0xe19b1c, 40 B)
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
; [nakarest] InitializeSuna) ("CmpEasyScreen"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0xba (table 0xe1b8a6, 14 entries, InitializeSuna): "EASY COMPOSER"
; [nakarest] (TtlScreen.title of element 0).
NakaContainer_EasyComposer_Root:
	.incbin "includes/generated/naka_composer_style.bin", 0x247A, 0x38
; [nakarest] Naka0x29_EasyComposer_Scrollbar  +0x24b2..+0x24cc (0xe19b96, 26 B)
; [nakarest] widget record, element 1 of Viewable slot 0xba (table 0xe1b8a6, 14 entries,
; [nakarest] InitializeSuna) ("CmpEasyScreen"): IvMainEditSw (26 B).
Naka0x29_EasyComposer_Scrollbar:
	.incbin "includes/generated/naka_composer_style.bin", 0x24B2, 0x1A
; [nakarest] Naka0x3d_EasyComposer_EditBtn  +0x24cc..+0x2504 (0xe19bb0, 56 B)
; [nakarest] widget record, element 2 of Viewable slot 0xba (table 0xe1b8a6, 14 entries,
; [nakarest] InitializeSuna) ("CmpEasyScreen"): VwMenuBox (50 B). text the records point at, in
; [nakarest] Viewable slot 0xba (table 0xe1b8a6, 14 entries, InitializeSuna): "EDIT"
; [nakarest] (VwMenuBox.str of element 2).
Naka0x3D_EasyComposer_EditBtn:
	.incbin "includes/generated/naka_composer_style.bin", 0x24CC, 0x38
; [nakarest] Naka0x3e_EasyComposer_DestBtn  +0x2504..+0x2532 (0xe19be8, 46 B)
; [nakarest] widget record, element 3 of Viewable slot 0xba (table 0xe1b8a6, 14 entries,
; [nakarest] InitializeSuna) ("CmpEasyScreen"): VwEditSwBox (44 B). text the records point at,
; [nakarest] in Viewable slot 0xba (table 0xe1b8a6, 14 entries, InitializeSuna): ""
; [nakarest] (VwEditSwBox.str of element 3).
Naka0x3E_EasyComposer_DestBtn:
	.incbin "includes/generated/naka_composer_style.bin", 0x2504, 0x2E
; [nakarest] Naka0x3e_EasyComposer_SourceBtn  +0x2532..+0x2560 (0xe19c16, 46 B)
; [nakarest] widget record, element 4 of Viewable slot 0xba (table 0xe1b8a6, 14 entries,
; [nakarest] InitializeSuna) ("CmpEasyScreen"): VwEditSwBox (44 B). text the records point at,
; [nakarest] in Viewable slot 0xba (table 0xe1b8a6, 14 entries, InitializeSuna): ""
; [nakarest] (VwEditSwBox.str of element 4).
Naka0x3E_EasyComposer_SourceBtn:
	.incbin "includes/generated/naka_composer_style.bin", 0x2532, 0x2E
; [nakarest] Naka0x3e_EasyComposer_InfoBtn  +0x2560..+0x2590 (0xe19c44, 48 B)
; [nakarest] widget record, element 5 of Viewable slot 0xba (table 0xe1b8a6, 14 entries,
; [nakarest] InitializeSuna) ("CmpEasyScreen"): VwEditSwBox (44 B). text the records point at,
; [nakarest] in Viewable slot 0xba (table 0xe1b8a6, 14 entries, InitializeSuna): "SET"
; [nakarest] (VwEditSwBox.str of element 5).
Naka0x3E_EasyComposer_InfoBtn:
	.incbin "includes/generated/naka_composer_style.bin", 0x2560, 0x30
; [nakarest] NakaLabel_EasyComposer_CompMemLabel  +0x2590..+0x25c2 (0xe19c74, 50 B)
; [nakarest] widget record, element 6 of Viewable slot 0xba (table 0xe1b8a6, 14 entries,
; [nakarest] InitializeSuna) ("CmpEasyScreen"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xba (table 0xe1b8a6, 14 entries, InitializeSuna): "COMPOSER MEMORY
; [nakarest] :" (Label.str of element 6).
NakaLabel_EasyComposer_CompMemLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x2590, 0x32
; [nakarest] NakaLabel_EasyComposer_MemField  +0x25c2..+0x25e6 (0xe19ca6, 36 B)
; [nakarest] widget record, element 7 of Viewable slot 0xba (table 0xe1b8a6, 14 entries,
; [nakarest] InitializeSuna) ("CmpEasyScreen"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xba (table 0xe1b8a6, 14 entries, InitializeSuna): "MEM" (Label.str
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
; [nakarest] InitializeSuna) ("CmpEasyScreen"): AcEasyCmpGridBox (74 B). text the records point
; [nakarest] at, in Viewable slot 0xba (table 0xe1b8a6, 14 entries, InitializeSuna):
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
; [nakarest] Naka0x1f_EasyComposer_PartSel3  +0x272a..+0x2752 (0xe19e0e, 40 B)
; [nakarest] widget record, element 13 of Viewable slot 0xba (table 0xe1b8a6, 14 entries,
; [nakarest] InitializeSuna) ("CmpEasyScreen"): AcIndexEditSw (40 B).
Naka0x1F_EasyComposer_PartSel3:
	.incbin "includes/generated/naka_composer_style.bin", 0x272A, 0x28
; [nakarest] NakaContainer_BendRange_Root  +0x2752..+0x279e (0xe19e36, 76 B)
; [nakarest] widget record, element 0 of Viewable slot 0xbb (table 0xe1b8e2, 4 entries,
; [nakarest] InitializeSuna) ("CmpBendScreen"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0xbb (table 0xe1b8e2, 4 entries, InitializeSuna): "COMPOSER PITCH
; [nakarest] BEND RANGE SETTING" (TtlScreen.title of element 0).
NakaContainer_BendRange_Root:
	.incbin "includes/generated/naka_composer_style.bin", 0x2752, 0x4C
; [nakarest] Naka0x22_BendRange_PartSelector  +0x279e..+0x27c8 (0xe19e82, 42 B)
; [nakarest] widget record, element 1 of Viewable slot 0xbb (table 0xe1b8e2, 4 entries,
; [nakarest] InitializeSuna) ("CmpBendScreen"): AcIndexWideES (42 B).
Naka0x22_BendRange_PartSelector:
	.incbin "includes/generated/naka_composer_style.bin", 0x279E, 0x2A
; [nakarest] Naka0x1a_BendRange_RangeControl  +0x27c8..+0x2816 (0xe19eac, 78 B)
; [nakarest] widget record, element 2 of Viewable slot 0xbb (table 0xe1b8e2, 4 entries,
; [nakarest] InitializeSuna) ("CmpBendScreen"): AcLswEditBox (58 B). text the records point at,
; [nakarest] in Viewable slot 0xbb (table 0xe1b8e2, 4 entries, InitializeSuna): " BEND RANGE : "
; [nakarest] (AcLswEditBox.caption of element 2).
Naka0x1A_BendRange_RangeControl:
	.incbin "includes/generated/naka_composer_style.bin", 0x27C8, 0x4E
; [nakarest] NakaLabel_BendRange_ValueLabel  +0x2816..+0x283c (0xe19efa, 38 B)
; [nakarest] widget record, element 3 of Viewable slot 0xbb (table 0xe1b8e2, 4 entries,
; [nakarest] InitializeSuna) ("CmpBendScreen"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xbb (table 0xe1b8e2, 4 entries, InitializeSuna): "VALUE" (Label.str
; [nakarest] of element 3).
NakaLabel_BendRange_ValueLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x2816, 0x26
; [nakarest] NakaContainer_ModeSelect_Root  +0x283c..+0x2872 (0xe19f20, 54 B)
; [nakarest] widget record, element 0 of Viewable slot 0xbd (table 0xe1b8f6, 11 entries,
; [nakarest] InitializeSuna) ("CmpModeScreen"): TtlScreen (42 B). text the records point at, in
; [nakarest] Viewable slot 0xbd (table 0xe1b8f6, 11 entries, InitializeSuna): "MODE SELECT"
; [nakarest] (TtlScreen.title of element 0).
NakaContainer_ModeSelect_Root:
	.incbin "includes/generated/naka_composer_style.bin", 0x283C, 0x36
; [nakarest] NakaLabel_ModeSelect_IntroFillIns  +0x2872..+0x28b0 (0xe19f56, 62 B)
; [nakarest] widget record, element 1 of Viewable slot 0xbd (table 0xe1b8f6, 11 entries,
; [nakarest] InitializeSuna) ("CmpModeScreen"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xbd (table 0xe1b8f6, 11 entries, InitializeSuna): "The
; [nakarest] Intro,Fill-Ins and Ending" (Label.str of element 1).
NakaLabel_ModeSelect_IntroFillIns:
	.incbin "includes/generated/naka_composer_style.bin", 0x2872, 0x3E
; [nakarest] NakaLabel_ModeSelect_ForEachPattern  +0x28b0..+0x28ee (0xe19f94, 62 B)
; [nakarest] widget record, element 2 of Viewable slot 0xbd (table 0xe1b8f6, 11 entries,
; [nakarest] InitializeSuna) ("CmpModeScreen"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xbd (table 0xe1b8f6, 11 entries, InitializeSuna): "for each Composer
; [nakarest] Pattern can" (Label.str of element 2).
NakaLabel_ModeSelect_ForEachPattern:
	.incbin "includes/generated/naka_composer_style.bin", 0x28B0, 0x3E
; [nakarest] NakaLabel_ModeSelect_BeCopied  +0x28ee..+0x2932 (0xe19fd2, 68 B)
; [nakarest] widget record, element 3 of Viewable slot 0xbd (table 0xe1b8f6, 11 entries,
; [nakarest] InitializeSuna) ("CmpModeScreen"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xbd (table 0xe1b8f6, 11 entries, InitializeSuna): "be copied from
; [nakarest] any preset pattern." (Label.str of element 3).
NakaLabel_ModeSelect_BeCopied:
	.incbin "includes/generated/naka_composer_style.bin", 0x28EE, 0x44
; [nakarest] NakaLabel_ModeSelect_MemAssigned  +0x2932..+0x2970 (0xe1a016, 62 B)
; [nakarest] widget record, element 4 of Viewable slot 0xbd (table 0xe1b8f6, 11 entries,
; [nakarest] InitializeSuna) ("CmpModeScreen"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xbd (table 0xe1b8f6, 11 entries, InitializeSuna): "A Composer Memory
; [nakarest] is assigned" (Label.str of element 4).
NakaLabel_ModeSelect_MemAssigned:
	.incbin "includes/generated/naka_composer_style.bin", 0x2932, 0x3E
; [nakarest] NakaLabel_ModeSelect_ToEachIntro  +0x2970..+0x29b0 (0xe1a054, 64 B)
; [nakarest] widget record, element 5 of Viewable slot 0xbd (table 0xe1b8f6, 11 entries,
; [nakarest] InitializeSuna) ("CmpModeScreen"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xbd (table 0xe1b8f6, 11 entries, InitializeSuna): "to each of The
; [nakarest] Intro Fill-In 1," (Label.str of element 5).
NakaLabel_ModeSelect_ToEachIntro:
	.incbin "includes/generated/naka_composer_style.bin", 0x2970, 0x40
; [nakarest] NakaLabel_ModeSelect_FillInEnding  +0x29b0..+0x29f0 (0xe1a094, 64 B)
; [nakarest] widget record, element 6 of Viewable slot 0xbd (table 0xe1b8f6, 11 entries,
; [nakarest] InitializeSuna) ("CmpModeScreen"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xbd (table 0xe1b8f6, 11 entries, InitializeSuna): "Fill -In 2 and
; [nakarest] Ending buttons," (Label.str of element 6).
NakaLabel_ModeSelect_FillInEnding:
	.incbin "includes/generated/naka_composer_style.bin", 0x29B0, 0x40
; [nakarest] NakaLabel_ModeSelect_SoYouCanCreate  +0x29f0..+0x2a2c (0xe1a0d4, 60 B)
; [nakarest] widget record, element 7 of Viewable slot 0xbd (table 0xe1b8f6, 11 entries,
; [nakarest] InitializeSuna) ("CmpModeScreen"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xbd (table 0xe1b8f6, 11 entries, InitializeSuna): "so you can create
; [nakarest] your own" (Label.str of element 7).
NakaLabel_ModeSelect_SoYouCanCreate:
	.incbin "includes/generated/naka_composer_style.bin", 0x29F0, 0x3C
; [nakarest] NakaLabel_ModeSelect_IntroFillEnding  +0x2a2c..+0x2a66 (0xe1a110, 58 B)
; [nakarest] widget record, element 8 of Viewable slot 0xbd (table 0xe1b8f6, 11 entries,
; [nakarest] InitializeSuna) ("CmpModeScreen"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xbd (table 0xe1b8f6, 11 entries, InitializeSuna): "Intro,Fill-Ins &
; [nakarest] Ending." (Label.str of element 8).
NakaLabel_ModeSelect_IntroFillEnding:
	.incbin "includes/generated/naka_composer_style.bin", 0x2A2C, 0x3A
; [nakarest] NakaNode_ModeSelect_NormalMode  +0x2a66..+0x2aa8 (0xe1a14a, 66 B)
; [nakarest] widget record, element 9 of Viewable slot 0xbd (table 0xe1b8f6, 11 entries,
; [nakarest] InitializeSuna) ("CmpModeScreen"): AcCmpMdBox (52 B). text the records point at, in
; [nakarest] Viewable slot 0xbd (table 0xe1b8f6, 11 entries, InitializeSuna): " NORMAL MODE:"
; [nakarest] (AcCmpMdBox.caption of element 9).
NakaNode_ModeSelect_NormalMode:
	.incbin "includes/generated/naka_composer_style.bin", 0x2A66, 0x42
; [nakarest] NakaNode_ModeSelect_ExpandMode  +0x2aa8..+0x2aea (0xe1a18c, 66 B)
; [nakarest] widget record, element 10 of Viewable slot 0xbd (table 0xe1b8f6, 11 entries,
; [nakarest] InitializeSuna) ("CmpModeScreen"): AcCmpMdBox (52 B). text the records point at, in
; [nakarest] Viewable slot 0xbd (table 0xe1b8f6, 11 entries, InitializeSuna): " EXPAND MODE:"
; [nakarest] (AcCmpMdBox.caption of element 10).
NakaNode_ModeSelect_ExpandMode:
	.incbin "includes/generated/naka_composer_style.bin", 0x2AA8, 0x42
; [nakarest] NakaNode_CustomCopy_RootOuter  +0x2aea..+0x2b20 (0xe1a1ce, 54 B)
; [nakarest] widget record, element 0 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): TtlScreen (42 B). text the records point at,
; [nakarest] in Viewable slot 0xbe (table 0xe1b926, 33 entries, InitializeSuna): "CUSTOM COPY"
; [nakarest] (TtlScreen.title of element 0).
NakaNode_CustomCopy_RootOuter:
	.incbin "includes/generated/naka_composer_style.bin", 0x2AEA, 0x36
; [nakarest] NakaLabel_CustomCopy_FromLabel  +0x2b20..+0x2b46 (0xe1a204, 38 B)
; [nakarest] widget record, element 1 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xbe (table 0xe1b926, 33 entries, InitializeSuna): "FROM" (Label.str
; [nakarest] of element 1).
NakaLabel_CustomCopy_FromLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x2B20, 0x26
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
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): Label (32 B). text the records point at, in
; [nakarest] Viewable slot 0xbe (table 0xe1b926, 33 entries, InitializeSuna): "TO" (Label.str of
; [nakarest] element 5).
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
; [nakarest] Naka0x3f_CustomCopy_Selector1  +0x2c08..+0x2c38 (0xe1a2ec, 48 B)
; [nakarest] widget record, element 8 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): VwWideESBox (46 B). text the records point at,
; [nakarest] in Viewable slot 0xbe (table 0xe1b926, 33 entries, InitializeSuna): ""
; [nakarest] (VwWideESBox.str of element 8).
Naka0x3F_CustomCopy_Selector1:
	.incbin "includes/generated/naka_composer_style.bin", 0x2C08, 0x30
; [nakarest] Naka0x3f_CustomCopy_Selector2  +0x2c38..+0x2c70 (0xe1a31c, 56 B)
; [nakarest] widget record, element 9 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): VwWideESBox (46 B). text the records point at,
; [nakarest] in Viewable slot 0xbe (table 0xe1b926, 33 entries, InitializeSuna): "DIRECTION"
; [nakarest] (VwWideESBox.str of element 9).
Naka0x3F_CustomCopy_Selector2:
	.incbin "includes/generated/naka_composer_style.bin", 0x2C38, 0x38
; [nakarest] Naka0x3f_CustomCopy_Selector3  +0x2c70..+0x2caa (0xe1a354, 58 B)
; [nakarest] widget record, element 10 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): VwWideESBox (46 B). text the records point at,
; [nakarest] in Viewable slot 0xbe (table 0xe1b926, 33 entries, InitializeSuna): "CstmCpToSw"
; [nakarest] (VwWideESBox.str of element 10).
Naka0x3F_CustomCopy_Selector3:
	.incbin "includes/generated/naka_composer_style.bin", 0x2C70, 0x3A
; [nakarest] NakaNode_CustomCopy_DestField  +0x2caa..+0x2cd0 (0xe1a38e, 38 B)
; [nakarest] widget record, element 11 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): PsCstmCpBnkBox (38 B).
NakaNode_CustomCopy_DestField:
	.incbin "includes/generated/naka_composer_style.bin", 0x2CAA, 0x26
; [nakarest] Naka0x3e_CustomCopy_InfoBtn  +0x2cd0..+0x2cfe (0xe1a3b4, 46 B)
; [nakarest] widget record, element 12 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): VwEditSwBox (44 B). text the records point at,
; [nakarest] in Viewable slot 0xbe (table 0xe1b926, 33 entries, InitializeSuna): ""
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
; [nakarest] Naka0x3e_CustomCopy_ExecuteBtn  +0x2e72..+0x2ea6 (0xe1a556, 52 B)
; [nakarest] widget record, element 23 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): VwEditSwBox (44 B). text the records point at,
; [nakarest] in Viewable slot 0xbe (table 0xe1b926, 33 entries, InitializeSuna): "EXECUTE"
; [nakarest] (VwEditSwBox.str of element 23).
Naka0x3E_CustomCopy_ExecuteBtn:
	.incbin "includes/generated/naka_composer_style.bin", 0x2E72, 0x34
; [nakarest] Naka0x3e_CustomCopy_AbortBtn1  +0x2ea6..+0x2ed8 (0xe1a58a, 50 B)
; [nakarest] widget record, element 24 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): VwEditSwBox (44 B). text the records point at,
; [nakarest] in Viewable slot 0xbe (table 0xe1b926, 33 entries, InitializeSuna): "ABORT"
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
; [nakarest] Naka0x3e_CustomCopy_ExecuteBtn2  +0x2fba..+0x2fee (0xe1a69e, 52 B)
; [nakarest] widget record, element 31 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): VwEditSwBox (44 B). text the records point at,
; [nakarest] in Viewable slot 0xbe (table 0xe1b926, 33 entries, InitializeSuna): "EXECUTE"
; [nakarest] (VwEditSwBox.str of element 31).
Naka0x3E_CustomCopy_ExecuteBtn2:
	.incbin "includes/generated/naka_composer_style.bin", 0x2FBA, 0x34
; [nakarest] Naka0x3e_CustomCopy_AbortBtn2  +0x2fee..+0x3020 (0xe1a6d2, 50 B)
; [nakarest] widget record, element 32 of Viewable slot 0xbe (table 0xe1b926, 33 entries,
; [nakarest] InitializeSuna) ("CmpCstmCpScreen"): VwEditSwBox (44 B). text the records point at,
; [nakarest] in Viewable slot 0xbe (table 0xe1b926, 33 entries, InitializeSuna): "ABORT"
; [nakarest] (VwEditSwBox.str of element 32).
Naka0x3E_CustomCopy_AbortBtn2:
	.incbin "includes/generated/naka_composer_style.bin", 0x2FEE, 0x32
; [nakarest] NakaContainer_CustomCopy_FinalRoot  +0x3020..+0x304a (0xe1a704, 42 B)
; [nakarest] widget record, element 0 of Viewable slot 0xc8 (table 0xe1b9ae, 27 entries,
; [nakarest] InitializeSuna) ("MspBkslScreen"): TtlScreen (42 B).
NakaContainer_CustomCopy_FinalRoot:
	.incbin "includes/generated/naka_composer_style.bin", 0x3020, 0x2A
; [nakarest] String_MSP_BANK_SELECT  +0x304a..+0x305a (0xe1a72e, 16 B)
; [nakarest] text the records point at, in Viewable slot 0xc8 (table 0xe1b9ae, 27 entries,
; [nakarest] InitializeSuna): "MSP BANK SELECT" (TtlScreen.title of element 0).
String_MSP_BANK_SELECT:
	.incbin "includes/generated/naka_composer_style.bin", 0x304A, 0x10
; External label offsets within the binary blob above.
