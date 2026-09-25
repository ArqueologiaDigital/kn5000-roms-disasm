
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
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaStr_PaintArrowProc_Empty
; NakaStr_PaintArrowProc_Empty  --  naka_composer_style +0x0..+0x2 (ROM 0xe176e4..0xe176e6), 2 bytes
; No RegObjTabl-registered table points at the start of these 2 bytes
; (0xe176e4..0xe176e6); purpose not established by that route.
; -----------------------------------------------------------------------------
NakaStr_PaintArrowProc_Empty:
	.incbin "includes/generated/naka_composer_style.bin", 0x0, 0x2
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_composer_style+0x2
; naka_composer_style+0x2  --  naka_composer_style +0x2..+0x12 (ROM 0xe176e6..0xe176f6), 16 bytes
; Name strings of element 0 of Function slot 0x404 (table 0xe176dc, 1
; entries, InitializeSuna), names for Function slot 0x104:
; "PaintArrowProc".
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_composer_style.bin", 0x2, 0x10
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_composer_style+0x12
; naka_composer_style+0x12  --  naka_composer_style +0x12..+0x90 (ROM 0xe176f6..0xe17774), 126 bytes
; Widget records of elements 0-2 of Viewable slot 0x10 (table 0xe1b4e2,
; 3 entries, InitializeSuna), element 0 "StylCnvWaitScreen"; classes:
; TtlScreen (42 B, id 0x01600034), VwBox (28 B, id 0x01600011),
; AcLanguageText (42 B, id 0x01600066).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_composer_style.bin", 0x12, 0x7E
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_composer_style+0x90
; naka_composer_style+0x90  --  naka_composer_style +0x90..+0x1f6 (ROM 0xe17774..0xe178da), 358 bytes
; Widget records of elements 0-7 of Viewable slot 0x11 (table 0xe1b4f2,
; 8 entries, InitializeSuna), element 0 "StylCnvModlScreen"; classes:
; TtlScreen (42 B, id 0x01600034), IvMainEditSw (26 B, id 0x01600029),
; PsParaListBox (42 B, id 0x01640021), VwEditSwBox (44 B, id 0x0160003e)
; x3, VwWideESBox (46 B, id 0x0160003f), PsStylCnvVer (36 B, id
; 0x01640028).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_composer_style.bin", 0x90, 0x166
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_composer_style+0x1f6
; naka_composer_style+0x1f6  --  naka_composer_style +0x1f6..+0x334 (ROM 0xe178da..0xe17a18), 318 bytes
; Widget records of elements 0-6 of Viewable slot 0x12 (table 0xe1b516,
; 7 entries, InitializeSuna), element 0 "StylCnvCnvtScreen"; classes:
; TtlScreen (42 B, id 0x01600034), IvMainEditSw (26 B, id 0x01600029),
; PsParaListBox (42 B, id 0x01640021), VwEditSwBox (44 B, id 0x0160003e)
; x3, VwWideESBox (46 B, id 0x0160003f).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_composer_style.bin", 0x1F6, 0x13E
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_composer_style+0x334
; naka_composer_style+0x334  --  naka_composer_style +0x334..+0x410 (ROM 0xe17a18..0xe17af4), 220 bytes
; Widget records of elements 0-3 of Viewable slot 0x13 (table 0xe1b536,
; 4 entries, InitializeSuna), element 0 "StylCnvStorScreen"; classes:
; TtlScreen (42 B, id 0x01600034), AcRamEditBox (58 B, id 0x0160001b),
; AcIndexWideES (42 B, id 0x01600022), AcFuncEditSw (44 B, id
; 0x01600020).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_composer_style.bin", 0x334, 0xDC
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_composer_style+0x410
; naka_composer_style+0x410  --  naka_composer_style +0x410..+0x4a4 (ROM 0xe17af4..0xe17b88), 148 bytes
; Widget records of elements 0-3 of Viewable slot 0x14 (table 0xe1b54a,
; 4 entries, InitializeSuna), element 0 "StylCnvTxtScreen"; classes:
; TtlScreen (42 B, id 0x01600034), VwBox (28 B, id 0x01600011),
; PSSCTxtBox2 (38 B, id 0x01640023), IvMainEditSw (26 B, id 0x01600029).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_composer_style.bin", 0x410, 0x94
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_composer_style+0x4a4
; naka_composer_style+0x4a4  --  naka_composer_style +0x4a4..+0x606 (ROM 0xe17b88..0xe17cea), 354 bytes
; Widget records of elements 0-7 of Viewable slot 0x15 (table 0xe1b55e,
; 8 entries, InitializeSuna), element 0 "StylCnvSelScreen"; classes:
; TtlScreen (42 B, id 0x01600034), IvMainEditSw (26 B, id 0x01600029),
; PsParaListBox (42 B, id 0x01640021), VwEditSwBox (44 B, id 0x0160003e)
; x3, VwWideESBox (46 B, id 0x0160003f), PsSCTxtBox (36 B, id
; 0x01640022).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_composer_style.bin", 0x4A4, 0x162
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_composer_style+0x606
; naka_composer_style+0x606  --  naka_composer_style +0x606..+0x722 (ROM 0xe17cea..0xe17e06), 284 bytes
; Widget records of elements 0-6 of Viewable slot 0x16 (table 0xe1b582,
; 7 entries, InitializeSuna), element 0 "StylCnvContScreen"; classes:
; TtlScreen (42 B, id 0x01600034), IvMainEditSw (26 B, id 0x01600029),
; VwBox (28 B, id 0x01600011), Label (32 B, id 0x0160002b) x2,
; VwEditSwBox (44 B, id 0x0160003e) x2.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_composer_style.bin", 0x606, 0x11C
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_composer_style+0x722
; naka_composer_style+0x722  --  naka_composer_style +0x722..+0xa8c (ROM 0xe17e06..0xe18170), 874 bytes
; Widget records of elements 0-17 of Viewable slot 0xb0 (table 0xe1b5a2,
; 18 entries, InitializeSuna), element 0 "CmpMenuScreen"; classes:
; TtlScreen (42 B, id 0x01600034), AcTitleMenu (54 B, id 0x0160001d) x6,
; Line (26 B, id 0x0160002e) x4, Label (32 B, id 0x0160002b) x2,
; IvMainEditSw (26 B, id 0x01600029), VwMenuBox (50 B, id 0x0160003d)
; x3, IvExitMode (26 B, id 0x01600048).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_composer_style.bin", 0x722, 0x36A
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_composer_style+0xa8c
; naka_composer_style+0xa8c  --  naka_composer_style +0xa8c..+0xd46 (ROM 0xe18170..0xe1842a), 698 bytes
; Widget records of elements 0-11 of Viewable slot 0xb1 (table 0xe1b5ee,
; 12 entries, InitializeSuna), element 0 "CmpBkslScreen"; classes:
; TtlScreen (42 B, id 0x01600034), IvMainEditSw (26 B, id 0x01600029),
; VwMenuBox (50 B, id 0x0160003d) x10.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_composer_style.bin", 0xA8C, 0x2BA
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_composer_style+0xd46
; naka_composer_style+0xd46  --  naka_composer_style +0xd46..+0x10fa (ROM 0xe1842a..0xe187de), 948 bytes
; Widget records of elements 0-21 of Viewable slot 0xb2 (table 0xe1b622,
; 22 entries, InitializeSuna), element 0 "CmpBkslSScreen"; classes:
; TtlScreen (42 B, id 0x01600034), Box (26 B, id 0x01600031), Label (32
; B, id 0x0160002b) x2, IvMainEditSw (26 B, id 0x01600029), VwMenuBox
; (50 B, id 0x0160003d) x2, VwEditSwBox (44 B, id 0x0160003e) x5,
; AcMemNoBox (36 B, id 0x01640000), Line (26 B, id 0x0160002e) x4,
; CmpNameMenuBox (50 B, id 0x01640026), Window (36 B, id 0x01600035),
; AcFuncEditSw (44 B, id 0x01600020) x2, AcLanguageText (42 B, id
; 0x01600066).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_composer_style.bin", 0xD46, 0x3B4
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_composer_style+0x10fa
; naka_composer_style+0x10fa  --  naka_composer_style +0x10fa..+0x11ca (ROM 0xe187de..0xe188ae), 208 bytes
; Widget records of elements 0-4 of Viewable slot 0xb3 (table 0xe1b67e,
; 5 entries, InitializeSuna), element 0 "CmpNamingScreen"; classes:
; TtlScreen (42 B, id 0x01600034), IvNaming (26 B, id 0x0160004d),
; AcFuncEditSw (44 B, id 0x01600020), Label (32 B, id 0x0160002b),
; AcMemNoBox (36 B, id 0x01640000).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_composer_style.bin", 0x10FA, 0xD0
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_composer_style+0x11ca
; naka_composer_style+0x11ca  --  naka_composer_style +0x11ca..+0x1580 (ROM 0xe188ae..0xe18c64), 950 bytes
; Widget records of elements 0-17 of Viewable slot 0xb4 (table 0xe1b696,
; 18 entries, InitializeSuna), element 0 "CmpSetScreen"; classes:
; TtlScreen (42 B, id 0x01600034), IvMainEditSw (26 B, id 0x01600029),
; AcWindowPage (36 B, id 0x01600025), IvPageControl (28 B, id
; 0x01600028) x2, IvShowHide (26 B, id 0x01600064), Window (36 B, id
; 0x01600035) x2, AcCmpSetGridBox (74 B, id 0x01640016), Label (32 B, id
; 0x0160002b) x3, AcIndexWideES (42 B, id 0x01600022) x5, AcGridBox (74
; B, id 0x01600056).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_composer_style.bin", 0x11CA, 0x3B6
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_composer_style+0x1580
; naka_composer_style+0x1580  --  naka_composer_style +0x1580..+0x1a2a (ROM 0xe18c64..0xe1910e), 1194 bytes
; Widget records of elements 0-23, 29-30 of Viewable slot 0xb5 (table
; 0xe1b6e2, 31 entries, InitializeSuna), element 0 "CmpRealScreen";
; classes: TtlScreen (42 B, id 0x01600034), Box (26 B, id 0x01600031),
; PsCmpMemBox (36 B, id 0x01640004), Label (32 B, id 0x0160002b) x6,
; IvMainEditSw (26 B, id 0x01600029), VwEditSwBox (44 B, id 0x0160003e)
; x5, AcCmpTempoBox (36 B, id 0x01640011), AcTitleMenu (54 B, id
; 0x0160001d) x2, AcMemNoBox (36 B, id 0x01640000), VwMenuBox (50 B, id
; 0x0160003d) x5, PsCmpQtzBox (36 B, id 0x01640002), PsCmpMeasBox (36 B,
; id 0x01640003).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_composer_style.bin", 0x1580, 0x4AA
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_composer_style+0x1a2a
; naka_composer_style+0x1a2a  --  naka_composer_style +0x1a2a..+0x1a4c (ROM 0xe1910e..0xe19130), 34 bytes
; Widget records of element 0 of Viewable slot 0xb6 (table 0xe1b762, 1
; entries, InitializeSuna); classes: IvDirmdScreen (34 B, id
; 0x0160005a).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_composer_style.bin", 0x1A2A, 0x22
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_composer_style+0x1a4c
; naka_composer_style+0x1a4c  --  naka_composer_style +0x1a4c..+0x1b24 (ROM 0xe19130..0xe19208), 216 bytes
; Widget records of elements 0-5 of Viewable slot 0xb7 (table 0xe1b76a,
; 6 entries, InitializeSuna), element 0 "CmpBalScreen"; classes:
; TtlScreen (42 B, id 0x01600034), AcMixerVol (32 B, id 0x0160003c) x5.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_composer_style.bin", 0x1A4C, 0xD8
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_composer_style+0x1b24
; naka_composer_style+0x1b24  --  naka_composer_style +0x1b24..+0x1eba (ROM 0xe19208..0xe1959e), 918 bytes
; Widget records of elements 0-17, 19-25 of Viewable slot 0xb8 (table
; 0xe1b786, 33 entries, InitializeSuna), element 0 "CmpNcpScreen";
; classes: TtlScreen (42 B, id 0x01600034), IvMainEditSw (26 B, id
; 0x01600029), VwWideESBox (46 B, id 0x0160003f) x4, Label (32 B, id
; 0x0160002b) x8, Line (26 B, id 0x0160002e) x8, Box (26 B, id
; 0x01600031) x2, VwEditSwBox (44 B, id 0x0160003e).
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_composer_style.bin", 0x1B24, 0x396
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaLabel_PatternCopy_MemoryLabel
; NakaLabel_PatternCopy_MemoryLabel  --  naka_composer_style +0x1eba..+0x1ee2 (ROM 0xe1959e..0xe195c6), 40 bytes
; Widget records of element 28 of Viewable slot 0xb8 (table 0xe1b786, 33
; entries, InitializeSuna), element 0 "CmpNcpScreen"; classes: Label (32
; B, id 0x0160002b).
; -----------------------------------------------------------------------------
NakaLabel_PatternCopy_MemoryLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x1EBA, 0x28
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaLabel_PatternCopy_PatMemLabel
; NakaLabel_PatternCopy_PatMemLabel  --  naka_composer_style +0x1ee2..+0x1f0c (ROM 0xe195c6..0xe195f0), 42 bytes
; Widget records of element 29 of Viewable slot 0xb8 (table 0xe1b786, 33
; entries, InitializeSuna), element 0 "CmpNcpScreen"; classes: Label (32
; B, id 0x0160002b).
; -----------------------------------------------------------------------------
NakaLabel_PatternCopy_PatMemLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x1EE2, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_PatternCopy_ProgressBar
; NakaNode_PatternCopy_ProgressBar  --  naka_composer_style +0x1f0c..+0x1f2c (ROM 0xe195f0..0xe19610), 32 bytes
; Widget records of element 32 of Viewable slot 0xb8 (table 0xe1b786, 33
; entries, InitializeSuna), element 0 "CmpNcpScreen"; classes: Yajirushi
; (32 B, id 0x01640025).
; -----------------------------------------------------------------------------
NakaNode_PatternCopy_ProgressBar:
	.incbin "includes/generated/naka_composer_style.bin", 0x1F0C, 0x20
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaContainer_SeqToComposer_Root
; NakaContainer_SeqToComposer_Root  --  naka_composer_style +0x1f2c..+0x1f6c (ROM 0xe19610..0xe19650), 64 bytes
; Widget records of element 0 of Viewable slot 0xb9 (table 0xe1b80e, 37
; entries, InitializeSuna), element 0 "S2CScreen"; classes: TtlScreen
; (42 B, id 0x01600034).
; -----------------------------------------------------------------------------
NakaContainer_SeqToComposer_Root:
	.incbin "includes/generated/naka_composer_style.bin", 0x1F2C, 0x40
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x3e_SeqToComposer_DrmBtn
; Naka0x3e_SeqToComposer_DrmBtn  --  naka_composer_style +0x1f6c..+0x1f9a (ROM 0xe19650..0xe1967e), 46 bytes
; Widget records of element 1 of Viewable slot 0xb9 (table 0xe1b80e, 37
; entries, InitializeSuna), element 0 "S2CScreen"; classes: VwEditSwBox
; (44 B, id 0x0160003e).
; -----------------------------------------------------------------------------
Naka0x3E_SeqToComposer_DrmBtn:
	.incbin "includes/generated/naka_composer_style.bin", 0x1F6C, 0x2E
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x3e_SeqToComposer_Ac3Btn
; Naka0x3e_SeqToComposer_Ac3Btn  --  naka_composer_style +0x1f9a..+0x1fc8 (ROM 0xe1967e..0xe196ac), 46 bytes
; Widget records of element 2 of Viewable slot 0xb9 (table 0xe1b80e, 37
; entries, InitializeSuna), element 0 "S2CScreen"; classes: VwEditSwBox
; (44 B, id 0x0160003e).
; -----------------------------------------------------------------------------
Naka0x3E_SeqToComposer_Ac3Btn:
	.incbin "includes/generated/naka_composer_style.bin", 0x1F9A, 0x2E
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x3e_SeqToComposer_Ac2Btn
; Naka0x3e_SeqToComposer_Ac2Btn  --  naka_composer_style +0x1fc8..+0x1ff6 (ROM 0xe196ac..0xe196da), 46 bytes
; Widget records of element 3 of Viewable slot 0xb9 (table 0xe1b80e, 37
; entries, InitializeSuna), element 0 "S2CScreen"; classes: VwEditSwBox
; (44 B, id 0x0160003e).
; -----------------------------------------------------------------------------
Naka0x3E_SeqToComposer_Ac2Btn:
	.incbin "includes/generated/naka_composer_style.bin", 0x1FC8, 0x2E
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x29_SeqToComposer_Scrollbar
; Naka0x29_SeqToComposer_Scrollbar  --  naka_composer_style +0x1ff6..+0x2010 (ROM 0xe196da..0xe196f4), 26 bytes
; Widget records of element 4 of Viewable slot 0xb9 (table 0xe1b80e, 37
; entries, InitializeSuna), element 0 "S2CScreen"; classes: IvMainEditSw
; (26 B, id 0x01600029).
; -----------------------------------------------------------------------------
Naka0x29_SeqToComposer_Scrollbar:
	.incbin "includes/generated/naka_composer_style.bin", 0x1FF6, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x3e_SeqToComposer_SourceBtn
; Naka0x3e_SeqToComposer_SourceBtn  --  naka_composer_style +0x2010..+0x203e (ROM 0xe196f4..0xe19722), 46 bytes
; Widget records of element 5 of Viewable slot 0xb9 (table 0xe1b80e, 37
; entries, InitializeSuna), element 0 "S2CScreen"; classes: VwEditSwBox
; (44 B, id 0x0160003e).
; -----------------------------------------------------------------------------
Naka0x3E_SeqToComposer_SourceBtn:
	.incbin "includes/generated/naka_composer_style.bin", 0x2010, 0x2E
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x3e_SeqToComposer_DestBtn
; Naka0x3e_SeqToComposer_DestBtn  --  naka_composer_style +0x203e..+0x206c (ROM 0xe19722..0xe19750), 46 bytes
; Widget records of element 6 of Viewable slot 0xb9 (table 0xe1b80e, 37
; entries, InitializeSuna), element 0 "S2CScreen"; classes: VwEditSwBox
; (44 B, id 0x0160003e).
; -----------------------------------------------------------------------------
Naka0x3E_SeqToComposer_DestBtn:
	.incbin "includes/generated/naka_composer_style.bin", 0x203E, 0x2E
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x3e_SeqToComposer_InfoBtn
; Naka0x3e_SeqToComposer_InfoBtn  --  naka_composer_style +0x206c..+0x209a (ROM 0xe19750..0xe1977e), 46 bytes
; Widget records of element 7 of Viewable slot 0xb9 (table 0xe1b80e, 37
; entries, InitializeSuna), element 0 "S2CScreen"; classes: VwEditSwBox
; (44 B, id 0x0160003e).
; -----------------------------------------------------------------------------
Naka0x3E_SeqToComposer_InfoBtn:
	.incbin "includes/generated/naka_composer_style.bin", 0x206C, 0x2E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaLabel_SeqToComposer_FirstLast
; NakaLabel_SeqToComposer_FirstLast  --  naka_composer_style +0x209a..+0x20c6 (ROM 0xe1977e..0xe197aa), 44 bytes
; Widget records of element 8 of Viewable slot 0xb9 (table 0xe1b80e, 37
; entries, InitializeSuna), element 0 "S2CScreen"; classes: Label (32 B,
; id 0x0160002b).
; -----------------------------------------------------------------------------
NakaLabel_SeqToComposer_FirstLast:
	.incbin "includes/generated/naka_composer_style.bin", 0x209A, 0x2C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaLabel_SeqToComposer_MeasureLabel
; NakaLabel_SeqToComposer_MeasureLabel  --  naka_composer_style +0x20c6..+0x20ee (ROM 0xe197aa..0xe197d2), 40 bytes
; Widget records of element 9 of Viewable slot 0xb9 (table 0xe1b80e, 37
; entries, InitializeSuna), element 0 "S2CScreen"; classes: Label (32 B,
; id 0x0160002b).
; -----------------------------------------------------------------------------
NakaLabel_SeqToComposer_MeasureLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x20C6, 0x28
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaValue_SeqToComposer_MeasVal1
; NakaValue_SeqToComposer_MeasVal1  --  naka_composer_style +0x20ee..+0x2108 (ROM 0xe197d2..0xe197ec), 26 bytes
; Widget records of element 10 of Viewable slot 0xb9 (table 0xe1b80e, 37
; entries, InitializeSuna), element 0 "S2CScreen"; classes: Line (26 B,
; id 0x0160002e).
; -----------------------------------------------------------------------------
NakaValue_SeqToComposer_MeasVal1:
	.incbin "includes/generated/naka_composer_style.bin", 0x20EE, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaValue_SeqToComposer_MeasVal2
; NakaValue_SeqToComposer_MeasVal2  --  naka_composer_style +0x2108..+0x2122 (ROM 0xe197ec..0xe19806), 26 bytes
; Widget records of element 11 of Viewable slot 0xb9 (table 0xe1b80e, 37
; entries, InitializeSuna), element 0 "S2CScreen"; classes: Line (26 B,
; id 0x0160002e).
; -----------------------------------------------------------------------------
NakaValue_SeqToComposer_MeasVal2:
	.incbin "includes/generated/naka_composer_style.bin", 0x2108, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaValue_SeqToComposer_MeasVal3
; NakaValue_SeqToComposer_MeasVal3  --  naka_composer_style +0x2122..+0x213c (ROM 0xe19806..0xe19820), 26 bytes
; Widget records of element 12 of Viewable slot 0xb9 (table 0xe1b80e, 37
; entries, InitializeSuna), element 0 "S2CScreen"; classes: Line (26 B,
; id 0x0160002e).
; -----------------------------------------------------------------------------
NakaValue_SeqToComposer_MeasVal3:
	.incbin "includes/generated/naka_composer_style.bin", 0x2122, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaValue_SeqToComposer_MeasVal4
; NakaValue_SeqToComposer_MeasVal4  --  naka_composer_style +0x213c..+0x2156 (ROM 0xe19820..0xe1983a), 26 bytes
; Widget records of element 13 of Viewable slot 0xb9 (table 0xe1b80e, 37
; entries, InitializeSuna), element 0 "S2CScreen"; classes: Line (26 B,
; id 0x0160002e).
; -----------------------------------------------------------------------------
NakaValue_SeqToComposer_MeasVal4:
	.incbin "includes/generated/naka_composer_style.bin", 0x213C, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaLabel_SeqToComposer_TransLabel
; NakaLabel_SeqToComposer_TransLabel  --  naka_composer_style +0x2156..+0x217c (ROM 0xe1983a..0xe19860), 38 bytes
; Widget records of element 14 of Viewable slot 0xb9 (table 0xe1b80e, 37
; entries, InitializeSuna), element 0 "S2CScreen"; classes: Label (32 B,
; id 0x0160002b).
; -----------------------------------------------------------------------------
NakaLabel_SeqToComposer_TransLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x2156, 0x26
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaLabel_SeqToComposer_TransPose
; NakaLabel_SeqToComposer_TransPose  --  naka_composer_style +0x217c..+0x21a2 (ROM 0xe19860..0xe19886), 38 bytes
; Widget records of element 15 of Viewable slot 0xb9 (table 0xe1b80e, 37
; entries, InitializeSuna), element 0 "S2CScreen"; classes: Label (32 B,
; id 0x0160002b).
; -----------------------------------------------------------------------------
NakaLabel_SeqToComposer_TransPose:
	.incbin "includes/generated/naka_composer_style.bin", 0x217C, 0x26
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaLabel_SeqToComposer_SequencerLabel
; NakaLabel_SeqToComposer_SequencerLabel  --  naka_composer_style +0x21a2..+0x21cc (ROM 0xe19886..0xe198b0), 42 bytes
; Widget records of element 16 of Viewable slot 0xb9 (table 0xe1b80e, 37
; entries, InitializeSuna), element 0 "S2CScreen"; classes: Label (32 B,
; id 0x0160002b).
; -----------------------------------------------------------------------------
NakaLabel_SeqToComposer_SequencerLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x21A2, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaGroup_SeqToComposer_SeqGroup
; NakaGroup_SeqToComposer_SeqGroup  --  naka_composer_style +0x21cc..+0x21e6 (ROM 0xe198b0..0xe198ca), 26 bytes
; Widget records of element 17 of Viewable slot 0xb9 (table 0xe1b80e, 37
; entries, InitializeSuna), element 0 "S2CScreen"; classes: Box (26 B,
; id 0x01600031).
; -----------------------------------------------------------------------------
NakaGroup_SeqToComposer_SeqGroup:
	.incbin "includes/generated/naka_composer_style.bin", 0x21CC, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaValue_SeqToComposer_SeqValue
; NakaValue_SeqToComposer_SeqValue  --  naka_composer_style +0x21e6..+0x2200 (ROM 0xe198ca..0xe198e4), 26 bytes
; Widget records of element 18 of Viewable slot 0xb9 (table 0xe1b80e, 37
; entries, InitializeSuna), element 0 "S2CScreen"; classes: Line (26 B,
; id 0x0160002e).
; -----------------------------------------------------------------------------
NakaValue_SeqToComposer_SeqValue:
	.incbin "includes/generated/naka_composer_style.bin", 0x21E6, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaLabel_SeqToComposer_FirstLabel
; NakaLabel_SeqToComposer_FirstLabel  --  naka_composer_style +0x2200..+0x2226 (ROM 0xe198e4..0xe1990a), 38 bytes
; Widget records of element 19 of Viewable slot 0xb9 (table 0xe1b80e, 37
; entries, InitializeSuna), element 0 "S2CScreen"; classes: Label (32 B,
; id 0x0160002b).
; -----------------------------------------------------------------------------
NakaLabel_SeqToComposer_FirstLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x2200, 0x26
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaLabel_SeqToComposer_MeasFirstLabel
; NakaLabel_SeqToComposer_MeasFirstLabel  --  naka_composer_style +0x2226..+0x224c (ROM 0xe1990a..0xe19930), 38 bytes
; Widget records of element 20 of Viewable slot 0xb9 (table 0xe1b80e, 37
; entries, InitializeSuna), element 0 "S2CScreen"; classes: Label (32 B,
; id 0x0160002b).
; -----------------------------------------------------------------------------
NakaLabel_SeqToComposer_MeasFirstLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x2226, 0x26
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaLabel_SeqToComposer_LastLabel
; NakaLabel_SeqToComposer_LastLabel  --  naka_composer_style +0x224c..+0x2272 (ROM 0xe19930..0xe19956), 38 bytes
; Widget records of element 21 of Viewable slot 0xb9 (table 0xe1b80e, 37
; entries, InitializeSuna), element 0 "S2CScreen"; classes: Label (32 B,
; id 0x0160002b).
; -----------------------------------------------------------------------------
NakaLabel_SeqToComposer_LastLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x224C, 0x26
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaLabel_SeqToComposer_MeasLastLabel
; NakaLabel_SeqToComposer_MeasLastLabel  --  naka_composer_style +0x2272..+0x2298 (ROM 0xe19956..0xe1997c), 38 bytes
; Widget records of element 22 of Viewable slot 0xb9 (table 0xe1b80e, 37
; entries, InitializeSuna), element 0 "S2CScreen"; classes: Label (32 B,
; id 0x0160002b).
; -----------------------------------------------------------------------------
NakaLabel_SeqToComposer_MeasLastLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x2272, 0x26
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaGroup_SeqToComposer_TransGroup
; NakaGroup_SeqToComposer_TransGroup  --  naka_composer_style +0x2298..+0x22b2 (ROM 0xe1997c..0xe19996), 26 bytes
; Widget records of element 23 of Viewable slot 0xb9 (table 0xe1b80e, 37
; entries, InitializeSuna), element 0 "S2CScreen"; classes: Box (26 B,
; id 0x01600031).
; -----------------------------------------------------------------------------
NakaGroup_SeqToComposer_TransGroup:
	.incbin "includes/generated/naka_composer_style.bin", 0x2298, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaLabel_SeqToComposer_TrnLabel
; NakaLabel_SeqToComposer_TrnLabel  --  naka_composer_style +0x22b2..+0x22d6 (ROM 0xe19996..0xe199ba), 36 bytes
; Widget records of element 25 of Viewable slot 0xb9 (table 0xe1b80e, 37
; entries, InitializeSuna), element 0 "S2CScreen"; classes: Label (32 B,
; id 0x0160002b).
; -----------------------------------------------------------------------------
NakaLabel_SeqToComposer_TrnLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x22B2, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaLabel_SeqToComposer_MemLabel
; NakaLabel_SeqToComposer_MemLabel  --  naka_composer_style +0x22d6..+0x22fa (ROM 0xe199ba..0xe199de), 36 bytes
; Widget records of element 26 of Viewable slot 0xb9 (table 0xe1b80e, 37
; entries, InitializeSuna), element 0 "S2CScreen"; classes: Label (32 B,
; id 0x0160002b).
; -----------------------------------------------------------------------------
NakaLabel_SeqToComposer_MemLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x22D6, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaLabel_SeqToComposer_ComposerMemory
; NakaLabel_SeqToComposer_ComposerMemory  --  naka_composer_style +0x22fa..+0x232a (ROM 0xe199de..0xe19a0e), 48 bytes
; Widget records of element 27 of Viewable slot 0xb9 (table 0xe1b80e, 37
; entries, InitializeSuna), element 0 "S2CScreen"; classes: Label (32 B,
; id 0x0160002b).
; -----------------------------------------------------------------------------
NakaLabel_SeqToComposer_ComposerMemory:
	.incbin "includes/generated/naka_composer_style.bin", 0x22FA, 0x30
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_SeqToComposer_ControlField
; NakaNode_SeqToComposer_ControlField  --  naka_composer_style +0x232a..+0x234e (ROM 0xe19a0e..0xe19a32), 36 bytes
; Widget records of element 29 of Viewable slot 0xb9 (table 0xe1b80e, 37
; entries, InitializeSuna), element 0 "S2CScreen"; classes:
; PsSeqSongNoBox (36 B, id 0x01640008).
; -----------------------------------------------------------------------------
NakaNode_SeqToComposer_ControlField:
	.incbin "includes/generated/naka_composer_style.bin", 0x232A, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_SeqToComposer_StyleField
; NakaNode_SeqToComposer_StyleField  --  naka_composer_style +0x234e..+0x2372 (ROM 0xe19a32..0xe19a56), 36 bytes
; Widget records of element 30 of Viewable slot 0xb9 (table 0xe1b80e, 37
; entries, InitializeSuna), element 0 "S2CScreen"; classes:
; AcS2cMemNoBox (36 B, id 0x01640005).
; -----------------------------------------------------------------------------
NakaNode_SeqToComposer_StyleField:
	.incbin "includes/generated/naka_composer_style.bin", 0x234E, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_SeqToComposer_ProgressBar
; NakaNode_SeqToComposer_ProgressBar  --  naka_composer_style +0x2372..+0x2392 (ROM 0xe19a56..0xe19a76), 32 bytes
; Widget records of element 32 of Viewable slot 0xb9 (table 0xe1b80e, 37
; entries, InitializeSuna), element 0 "S2CScreen"; classes: Yajirushi
; (32 B, id 0x01640025).
; -----------------------------------------------------------------------------
NakaNode_SeqToComposer_ProgressBar:
	.incbin "includes/generated/naka_composer_style.bin", 0x2372, 0x20
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_SeqToComposer_PartDisplay
; NakaNode_SeqToComposer_PartDisplay  --  naka_composer_style +0x2392..+0x2410 (ROM 0xe19a76..0xe19af4), 126 bytes
; Widget records of element 33 of Viewable slot 0xb9 (table 0xe1b80e, 37
; entries, InitializeSuna), element 0 "S2CScreen"; classes: S2cGridBox
; (74 B, id 0x01640027).
; -----------------------------------------------------------------------------
NakaNode_SeqToComposer_PartDisplay:
	.incbin "includes/generated/naka_composer_style.bin", 0x2392, 0x7E
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x1f_SeqToComposer_PartSel1
; Naka0x1f_SeqToComposer_PartSel1  --  naka_composer_style +0x2410..+0x2438 (ROM 0xe19af4..0xe19b1c), 40 bytes
; Widget records of element 34 of Viewable slot 0xb9 (table 0xe1b80e, 37
; entries, InitializeSuna), element 0 "S2CScreen"; classes:
; AcIndexEditSw (40 B, id 0x0160001f).
; -----------------------------------------------------------------------------
Naka0x1F_SeqToComposer_PartSel1:
	.incbin "includes/generated/naka_composer_style.bin", 0x2410, 0x28
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x1f_SeqToComposer_PartSel2
; Naka0x1f_SeqToComposer_PartSel2  --  naka_composer_style +0x2438..+0x2460 (ROM 0xe19b1c..0xe19b44), 40 bytes
; Widget records of element 35 of Viewable slot 0xb9 (table 0xe1b80e, 37
; entries, InitializeSuna), element 0 "S2CScreen"; classes:
; AcIndexEditSw (40 B, id 0x0160001f).
; -----------------------------------------------------------------------------
Naka0x1F_SeqToComposer_PartSel2:
	.incbin "includes/generated/naka_composer_style.bin", 0x2438, 0x28
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x64_SeqToComposer_TabContent
; Naka0x64_SeqToComposer_TabContent  --  naka_composer_style +0x2460..+0x247a (ROM 0xe19b44..0xe19b5e), 26 bytes
; Widget records of element 36 of Viewable slot 0xb9 (table 0xe1b80e, 37
; entries, InitializeSuna), element 0 "S2CScreen"; classes: IvShowHide
; (26 B, id 0x01600064).
; -----------------------------------------------------------------------------
Naka0x64_SeqToComposer_TabContent:
	.incbin "includes/generated/naka_composer_style.bin", 0x2460, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaContainer_EasyComposer_Root
; NakaContainer_EasyComposer_Root  --  naka_composer_style +0x247a..+0x24b2 (ROM 0xe19b5e..0xe19b96), 56 bytes
; Widget records of element 0 of Viewable slot 0xba (table 0xe1b8a6, 14
; entries, InitializeSuna), element 0 "CmpEasyScreen"; classes:
; TtlScreen (42 B, id 0x01600034).
; -----------------------------------------------------------------------------
NakaContainer_EasyComposer_Root:
	.incbin "includes/generated/naka_composer_style.bin", 0x247A, 0x38
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x29_EasyComposer_Scrollbar
; Naka0x29_EasyComposer_Scrollbar  --  naka_composer_style +0x24b2..+0x24cc (ROM 0xe19b96..0xe19bb0), 26 bytes
; Widget records of element 1 of Viewable slot 0xba (table 0xe1b8a6, 14
; entries, InitializeSuna), element 0 "CmpEasyScreen"; classes:
; IvMainEditSw (26 B, id 0x01600029).
; -----------------------------------------------------------------------------
Naka0x29_EasyComposer_Scrollbar:
	.incbin "includes/generated/naka_composer_style.bin", 0x24B2, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x3d_EasyComposer_EditBtn
; Naka0x3d_EasyComposer_EditBtn  --  naka_composer_style +0x24cc..+0x2504 (ROM 0xe19bb0..0xe19be8), 56 bytes
; Widget records of element 2 of Viewable slot 0xba (table 0xe1b8a6, 14
; entries, InitializeSuna), element 0 "CmpEasyScreen"; classes:
; VwMenuBox (50 B, id 0x0160003d).
; -----------------------------------------------------------------------------
Naka0x3D_EasyComposer_EditBtn:
	.incbin "includes/generated/naka_composer_style.bin", 0x24CC, 0x38
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x3e_EasyComposer_DestBtn
; Naka0x3e_EasyComposer_DestBtn  --  naka_composer_style +0x2504..+0x2532 (ROM 0xe19be8..0xe19c16), 46 bytes
; Widget records of element 3 of Viewable slot 0xba (table 0xe1b8a6, 14
; entries, InitializeSuna), element 0 "CmpEasyScreen"; classes:
; VwEditSwBox (44 B, id 0x0160003e).
; -----------------------------------------------------------------------------
Naka0x3E_EasyComposer_DestBtn:
	.incbin "includes/generated/naka_composer_style.bin", 0x2504, 0x2E
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x3e_EasyComposer_SourceBtn
; Naka0x3e_EasyComposer_SourceBtn  --  naka_composer_style +0x2532..+0x2560 (ROM 0xe19c16..0xe19c44), 46 bytes
; Widget records of element 4 of Viewable slot 0xba (table 0xe1b8a6, 14
; entries, InitializeSuna), element 0 "CmpEasyScreen"; classes:
; VwEditSwBox (44 B, id 0x0160003e).
; -----------------------------------------------------------------------------
Naka0x3E_EasyComposer_SourceBtn:
	.incbin "includes/generated/naka_composer_style.bin", 0x2532, 0x2E
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x3e_EasyComposer_InfoBtn
; Naka0x3e_EasyComposer_InfoBtn  --  naka_composer_style +0x2560..+0x2590 (ROM 0xe19c44..0xe19c74), 48 bytes
; Widget records of element 5 of Viewable slot 0xba (table 0xe1b8a6, 14
; entries, InitializeSuna), element 0 "CmpEasyScreen"; classes:
; VwEditSwBox (44 B, id 0x0160003e).
; -----------------------------------------------------------------------------
Naka0x3E_EasyComposer_InfoBtn:
	.incbin "includes/generated/naka_composer_style.bin", 0x2560, 0x30
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaLabel_EasyComposer_CompMemLabel
; NakaLabel_EasyComposer_CompMemLabel  --  naka_composer_style +0x2590..+0x25c2 (ROM 0xe19c74..0xe19ca6), 50 bytes
; Widget records of element 6 of Viewable slot 0xba (table 0xe1b8a6, 14
; entries, InitializeSuna), element 0 "CmpEasyScreen"; classes: Label
; (32 B, id 0x0160002b).
; -----------------------------------------------------------------------------
NakaLabel_EasyComposer_CompMemLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x2590, 0x32
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaLabel_EasyComposer_MemField
; NakaLabel_EasyComposer_MemField  --  naka_composer_style +0x25c2..+0x25e6 (ROM 0xe19ca6..0xe19cca), 36 bytes
; Widget records of element 7 of Viewable slot 0xba (table 0xe1b8a6, 14
; entries, InitializeSuna), element 0 "CmpEasyScreen"; classes: Label
; (32 B, id 0x0160002b).
; -----------------------------------------------------------------------------
NakaLabel_EasyComposer_MemField:
	.incbin "includes/generated/naka_composer_style.bin", 0x25C2, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x11_EasyComposer_ListFrame
; Naka0x11_EasyComposer_ListFrame  --  naka_composer_style +0x25e6..+0x2602 (ROM 0xe19cca..0xe19ce6), 28 bytes
; Widget records of element 8 of Viewable slot 0xba (table 0xe1b8a6, 14
; entries, InitializeSuna), element 0 "CmpEasyScreen"; classes: VwBox
; (28 B, id 0x01600011).
; -----------------------------------------------------------------------------
Naka0x11_EasyComposer_ListFrame:
	.incbin "includes/generated/naka_composer_style.bin", 0x25E6, 0x1C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_EasyComposer_StatusField
; NakaNode_EasyComposer_StatusField  --  naka_composer_style +0x2602..+0x2626 (ROM 0xe19ce6..0xe19d0a), 36 bytes
; Widget records of element 9 of Viewable slot 0xba (table 0xe1b8a6, 14
; entries, InitializeSuna), element 0 "CmpEasyScreen"; classes:
; AcMemNoBox (36 B, id 0x01640000).
; -----------------------------------------------------------------------------
NakaNode_EasyComposer_StatusField:
	.incbin "includes/generated/naka_composer_style.bin", 0x2602, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_EasyComposer_PartDisplay
; NakaNode_EasyComposer_PartDisplay  --  naka_composer_style +0x2626..+0x26d6 (ROM 0xe19d0a..0xe19dba), 176 bytes
; Widget records of element 10 of Viewable slot 0xba (table 0xe1b8a6, 14
; entries, InitializeSuna), element 0 "CmpEasyScreen"; classes:
; AcEasyCmpGridBox (74 B, id 0x01640018).
; -----------------------------------------------------------------------------
NakaNode_EasyComposer_PartDisplay:
	.incbin "includes/generated/naka_composer_style.bin", 0x2626, 0xB0
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x22_EasyComposer_PartSel1
; Naka0x22_EasyComposer_PartSel1  --  naka_composer_style +0x26d6..+0x2700 (ROM 0xe19dba..0xe19de4), 42 bytes
; Widget records of element 11 of Viewable slot 0xba (table 0xe1b8a6, 14
; entries, InitializeSuna), element 0 "CmpEasyScreen"; classes:
; AcIndexWideES (42 B, id 0x01600022).
; -----------------------------------------------------------------------------
Naka0x22_EasyComposer_PartSel1:
	.incbin "includes/generated/naka_composer_style.bin", 0x26D6, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x22_EasyComposer_PartSel2
; Naka0x22_EasyComposer_PartSel2  --  naka_composer_style +0x2700..+0x272a (ROM 0xe19de4..0xe19e0e), 42 bytes
; Widget records of element 12 of Viewable slot 0xba (table 0xe1b8a6, 14
; entries, InitializeSuna), element 0 "CmpEasyScreen"; classes:
; AcIndexWideES (42 B, id 0x01600022).
; -----------------------------------------------------------------------------
Naka0x22_EasyComposer_PartSel2:
	.incbin "includes/generated/naka_composer_style.bin", 0x2700, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x1f_EasyComposer_PartSel3
; Naka0x1f_EasyComposer_PartSel3  --  naka_composer_style +0x272a..+0x2752 (ROM 0xe19e0e..0xe19e36), 40 bytes
; Widget records of element 13 of Viewable slot 0xba (table 0xe1b8a6, 14
; entries, InitializeSuna), element 0 "CmpEasyScreen"; classes:
; AcIndexEditSw (40 B, id 0x0160001f).
; -----------------------------------------------------------------------------
Naka0x1F_EasyComposer_PartSel3:
	.incbin "includes/generated/naka_composer_style.bin", 0x272A, 0x28
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaContainer_BendRange_Root
; NakaContainer_BendRange_Root  --  naka_composer_style +0x2752..+0x279e (ROM 0xe19e36..0xe19e82), 76 bytes
; Widget records of element 0 of Viewable slot 0xbb (table 0xe1b8e2, 4
; entries, InitializeSuna), element 0 "CmpBendScreen"; classes:
; TtlScreen (42 B, id 0x01600034).
; -----------------------------------------------------------------------------
NakaContainer_BendRange_Root:
	.incbin "includes/generated/naka_composer_style.bin", 0x2752, 0x4C
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x22_BendRange_PartSelector
; Naka0x22_BendRange_PartSelector  --  naka_composer_style +0x279e..+0x27c8 (ROM 0xe19e82..0xe19eac), 42 bytes
; Widget records of element 1 of Viewable slot 0xbb (table 0xe1b8e2, 4
; entries, InitializeSuna), element 0 "CmpBendScreen"; classes:
; AcIndexWideES (42 B, id 0x01600022).
; -----------------------------------------------------------------------------
Naka0x22_BendRange_PartSelector:
	.incbin "includes/generated/naka_composer_style.bin", 0x279E, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x1a_BendRange_RangeControl
; Naka0x1a_BendRange_RangeControl  --  naka_composer_style +0x27c8..+0x2816 (ROM 0xe19eac..0xe19efa), 78 bytes
; Widget records of element 2 of Viewable slot 0xbb (table 0xe1b8e2, 4
; entries, InitializeSuna), element 0 "CmpBendScreen"; classes:
; AcLswEditBox (58 B, id 0x0160001a).
; -----------------------------------------------------------------------------
Naka0x1A_BendRange_RangeControl:
	.incbin "includes/generated/naka_composer_style.bin", 0x27C8, 0x4E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaLabel_BendRange_ValueLabel
; NakaLabel_BendRange_ValueLabel  --  naka_composer_style +0x2816..+0x283c (ROM 0xe19efa..0xe19f20), 38 bytes
; Widget records of element 3 of Viewable slot 0xbb (table 0xe1b8e2, 4
; entries, InitializeSuna), element 0 "CmpBendScreen"; classes: Label
; (32 B, id 0x0160002b).
; -----------------------------------------------------------------------------
NakaLabel_BendRange_ValueLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x2816, 0x26
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaContainer_ModeSelect_Root
; NakaContainer_ModeSelect_Root  --  naka_composer_style +0x283c..+0x2872 (ROM 0xe19f20..0xe19f56), 54 bytes
; Widget records of element 0 of Viewable slot 0xbd (table 0xe1b8f6, 11
; entries, InitializeSuna), element 0 "CmpModeScreen"; classes:
; TtlScreen (42 B, id 0x01600034).
; -----------------------------------------------------------------------------
NakaContainer_ModeSelect_Root:
	.incbin "includes/generated/naka_composer_style.bin", 0x283C, 0x36
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaLabel_ModeSelect_IntroFillIns
; NakaLabel_ModeSelect_IntroFillIns  --  naka_composer_style +0x2872..+0x28b0 (ROM 0xe19f56..0xe19f94), 62 bytes
; Widget records of element 1 of Viewable slot 0xbd (table 0xe1b8f6, 11
; entries, InitializeSuna), element 0 "CmpModeScreen"; classes: Label
; (32 B, id 0x0160002b).
; -----------------------------------------------------------------------------
NakaLabel_ModeSelect_IntroFillIns:
	.incbin "includes/generated/naka_composer_style.bin", 0x2872, 0x3E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaLabel_ModeSelect_ForEachPattern
; NakaLabel_ModeSelect_ForEachPattern  --  naka_composer_style +0x28b0..+0x28ee (ROM 0xe19f94..0xe19fd2), 62 bytes
; Widget records of element 2 of Viewable slot 0xbd (table 0xe1b8f6, 11
; entries, InitializeSuna), element 0 "CmpModeScreen"; classes: Label
; (32 B, id 0x0160002b).
; -----------------------------------------------------------------------------
NakaLabel_ModeSelect_ForEachPattern:
	.incbin "includes/generated/naka_composer_style.bin", 0x28B0, 0x3E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaLabel_ModeSelect_BeCopied
; NakaLabel_ModeSelect_BeCopied  --  naka_composer_style +0x28ee..+0x2932 (ROM 0xe19fd2..0xe1a016), 68 bytes
; Widget records of element 3 of Viewable slot 0xbd (table 0xe1b8f6, 11
; entries, InitializeSuna), element 0 "CmpModeScreen"; classes: Label
; (32 B, id 0x0160002b).
; -----------------------------------------------------------------------------
NakaLabel_ModeSelect_BeCopied:
	.incbin "includes/generated/naka_composer_style.bin", 0x28EE, 0x44
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaLabel_ModeSelect_MemAssigned
; NakaLabel_ModeSelect_MemAssigned  --  naka_composer_style +0x2932..+0x2970 (ROM 0xe1a016..0xe1a054), 62 bytes
; Widget records of element 4 of Viewable slot 0xbd (table 0xe1b8f6, 11
; entries, InitializeSuna), element 0 "CmpModeScreen"; classes: Label
; (32 B, id 0x0160002b).
; -----------------------------------------------------------------------------
NakaLabel_ModeSelect_MemAssigned:
	.incbin "includes/generated/naka_composer_style.bin", 0x2932, 0x3E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaLabel_ModeSelect_ToEachIntro
; NakaLabel_ModeSelect_ToEachIntro  --  naka_composer_style +0x2970..+0x29b0 (ROM 0xe1a054..0xe1a094), 64 bytes
; Widget records of element 5 of Viewable slot 0xbd (table 0xe1b8f6, 11
; entries, InitializeSuna), element 0 "CmpModeScreen"; classes: Label
; (32 B, id 0x0160002b).
; -----------------------------------------------------------------------------
NakaLabel_ModeSelect_ToEachIntro:
	.incbin "includes/generated/naka_composer_style.bin", 0x2970, 0x40
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaLabel_ModeSelect_FillInEnding
; NakaLabel_ModeSelect_FillInEnding  --  naka_composer_style +0x29b0..+0x29f0 (ROM 0xe1a094..0xe1a0d4), 64 bytes
; Widget records of element 6 of Viewable slot 0xbd (table 0xe1b8f6, 11
; entries, InitializeSuna), element 0 "CmpModeScreen"; classes: Label
; (32 B, id 0x0160002b).
; -----------------------------------------------------------------------------
NakaLabel_ModeSelect_FillInEnding:
	.incbin "includes/generated/naka_composer_style.bin", 0x29B0, 0x40
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaLabel_ModeSelect_SoYouCanCreate
; NakaLabel_ModeSelect_SoYouCanCreate  --  naka_composer_style +0x29f0..+0x2a2c (ROM 0xe1a0d4..0xe1a110), 60 bytes
; Widget records of element 7 of Viewable slot 0xbd (table 0xe1b8f6, 11
; entries, InitializeSuna), element 0 "CmpModeScreen"; classes: Label
; (32 B, id 0x0160002b).
; -----------------------------------------------------------------------------
NakaLabel_ModeSelect_SoYouCanCreate:
	.incbin "includes/generated/naka_composer_style.bin", 0x29F0, 0x3C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaLabel_ModeSelect_IntroFillEnding
; NakaLabel_ModeSelect_IntroFillEnding  --  naka_composer_style +0x2a2c..+0x2a66 (ROM 0xe1a110..0xe1a14a), 58 bytes
; Widget records of element 8 of Viewable slot 0xbd (table 0xe1b8f6, 11
; entries, InitializeSuna), element 0 "CmpModeScreen"; classes: Label
; (32 B, id 0x0160002b).
; -----------------------------------------------------------------------------
NakaLabel_ModeSelect_IntroFillEnding:
	.incbin "includes/generated/naka_composer_style.bin", 0x2A2C, 0x3A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_ModeSelect_NormalMode
; NakaNode_ModeSelect_NormalMode  --  naka_composer_style +0x2a66..+0x2aa8 (ROM 0xe1a14a..0xe1a18c), 66 bytes
; Widget records of element 9 of Viewable slot 0xbd (table 0xe1b8f6, 11
; entries, InitializeSuna), element 0 "CmpModeScreen"; classes:
; AcCmpMdBox (52 B, id 0x0164000d).
; -----------------------------------------------------------------------------
NakaNode_ModeSelect_NormalMode:
	.incbin "includes/generated/naka_composer_style.bin", 0x2A66, 0x42
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_ModeSelect_ExpandMode
; NakaNode_ModeSelect_ExpandMode  --  naka_composer_style +0x2aa8..+0x2aea (ROM 0xe1a18c..0xe1a1ce), 66 bytes
; Widget records of element 10 of Viewable slot 0xbd (table 0xe1b8f6, 11
; entries, InitializeSuna), element 0 "CmpModeScreen"; classes:
; AcCmpMdBox (52 B, id 0x0164000d).
; -----------------------------------------------------------------------------
NakaNode_ModeSelect_ExpandMode:
	.incbin "includes/generated/naka_composer_style.bin", 0x2AA8, 0x42
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_CustomCopy_RootOuter
; NakaNode_CustomCopy_RootOuter  --  naka_composer_style +0x2aea..+0x2b20 (ROM 0xe1a1ce..0xe1a204), 54 bytes
; Widget records of element 0 of Viewable slot 0xbe (table 0xe1b926, 33
; entries, InitializeSuna), element 0 "CmpCstmCpScreen"; classes:
; TtlScreen (42 B, id 0x01600034).
; -----------------------------------------------------------------------------
NakaNode_CustomCopy_RootOuter:
	.incbin "includes/generated/naka_composer_style.bin", 0x2AEA, 0x36
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaLabel_CustomCopy_FromLabel
; NakaLabel_CustomCopy_FromLabel  --  naka_composer_style +0x2b20..+0x2b46 (ROM 0xe1a204..0xe1a22a), 38 bytes
; Widget records of element 1 of Viewable slot 0xbe (table 0xe1b926, 33
; entries, InitializeSuna), element 0 "CmpCstmCpScreen"; classes: Label
; (32 B, id 0x0160002b).
; -----------------------------------------------------------------------------
NakaLabel_CustomCopy_FromLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x2B20, 0x26
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x11_CustomCopy_FromFrame
; Naka0x11_CustomCopy_FromFrame  --  naka_composer_style +0x2b46..+0x2b62 (ROM 0xe1a22a..0xe1a246), 28 bytes
; Widget records of element 2 of Viewable slot 0xbe (table 0xe1b926, 33
; entries, InitializeSuna), element 0 "CmpCstmCpScreen"; classes: VwBox
; (28 B, id 0x01600011).
; -----------------------------------------------------------------------------
Naka0x11_CustomCopy_FromFrame:
	.incbin "includes/generated/naka_composer_style.bin", 0x2B46, 0x1C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_CustomCopy_FromField
; NakaNode_CustomCopy_FromField  --  naka_composer_style +0x2b62..+0x2b88 (ROM 0xe1a246..0xe1a26c), 38 bytes
; Widget records of element 3 of Viewable slot 0xbe (table 0xe1b926, 33
; entries, InitializeSuna), element 0 "CmpCstmCpScreen"; classes:
; PsCstmCpBnkBox (38 B, id 0x0164000a).
; -----------------------------------------------------------------------------
NakaNode_CustomCopy_FromField:
	.incbin "includes/generated/naka_composer_style.bin", 0x2B62, 0x26
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_CustomCopy_ToFieldTop
; NakaNode_CustomCopy_ToFieldTop  --  naka_composer_style +0x2b88..+0x2bae (ROM 0xe1a26c..0xe1a292), 38 bytes
; Widget records of element 4 of Viewable slot 0xbe (table 0xe1b926, 33
; entries, InitializeSuna), element 0 "CmpCstmCpScreen"; classes:
; PsCstmCpNameBox (38 B, id 0x0164001e).
; -----------------------------------------------------------------------------
NakaNode_CustomCopy_ToFieldTop:
	.incbin "includes/generated/naka_composer_style.bin", 0x2B88, 0x26
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaLabel_CustomCopy_ToLabel
; NakaLabel_CustomCopy_ToLabel  --  naka_composer_style +0x2bae..+0x2bd2 (ROM 0xe1a292..0xe1a2b6), 36 bytes
; Widget records of element 5 of Viewable slot 0xbe (table 0xe1b926, 33
; entries, InitializeSuna), element 0 "CmpCstmCpScreen"; classes: Label
; (32 B, id 0x0160002b).
; -----------------------------------------------------------------------------
NakaLabel_CustomCopy_ToLabel:
	.incbin "includes/generated/naka_composer_style.bin", 0x2BAE, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x11_CustomCopy_ToFrame
; Naka0x11_CustomCopy_ToFrame  --  naka_composer_style +0x2bd2..+0x2bee (ROM 0xe1a2b6..0xe1a2d2), 28 bytes
; Widget records of element 6 of Viewable slot 0xbe (table 0xe1b926, 33
; entries, InitializeSuna), element 0 "CmpCstmCpScreen"; classes: VwBox
; (28 B, id 0x01600011).
; -----------------------------------------------------------------------------
Naka0x11_CustomCopy_ToFrame:
	.incbin "includes/generated/naka_composer_style.bin", 0x2BD2, 0x1C
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x29_CustomCopy_Scrollbar
; Naka0x29_CustomCopy_Scrollbar  --  naka_composer_style +0x2bee..+0x2c08 (ROM 0xe1a2d2..0xe1a2ec), 26 bytes
; Widget records of element 7 of Viewable slot 0xbe (table 0xe1b926, 33
; entries, InitializeSuna), element 0 "CmpCstmCpScreen"; classes:
; IvMainEditSw (26 B, id 0x01600029).
; -----------------------------------------------------------------------------
Naka0x29_CustomCopy_Scrollbar:
	.incbin "includes/generated/naka_composer_style.bin", 0x2BEE, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x3f_CustomCopy_Selector1
; Naka0x3f_CustomCopy_Selector1  --  naka_composer_style +0x2c08..+0x2c38 (ROM 0xe1a2ec..0xe1a31c), 48 bytes
; Widget records of element 8 of Viewable slot 0xbe (table 0xe1b926, 33
; entries, InitializeSuna), element 0 "CmpCstmCpScreen"; classes:
; VwWideESBox (46 B, id 0x0160003f).
; -----------------------------------------------------------------------------
Naka0x3F_CustomCopy_Selector1:
	.incbin "includes/generated/naka_composer_style.bin", 0x2C08, 0x30
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x3f_CustomCopy_Selector2
; Naka0x3f_CustomCopy_Selector2  --  naka_composer_style +0x2c38..+0x2c70 (ROM 0xe1a31c..0xe1a354), 56 bytes
; Widget records of element 9 of Viewable slot 0xbe (table 0xe1b926, 33
; entries, InitializeSuna), element 0 "CmpCstmCpScreen"; classes:
; VwWideESBox (46 B, id 0x0160003f).
; -----------------------------------------------------------------------------
Naka0x3F_CustomCopy_Selector2:
	.incbin "includes/generated/naka_composer_style.bin", 0x2C38, 0x38
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x3f_CustomCopy_Selector3
; Naka0x3f_CustomCopy_Selector3  --  naka_composer_style +0x2c70..+0x2caa (ROM 0xe1a354..0xe1a38e), 58 bytes
; Widget records of element 10 of Viewable slot 0xbe (table 0xe1b926, 33
; entries, InitializeSuna), element 0 "CmpCstmCpScreen"; classes:
; VwWideESBox (46 B, id 0x0160003f).
; -----------------------------------------------------------------------------
Naka0x3F_CustomCopy_Selector3:
	.incbin "includes/generated/naka_composer_style.bin", 0x2C70, 0x3A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_CustomCopy_DestField
; NakaNode_CustomCopy_DestField  --  naka_composer_style +0x2caa..+0x2cd0 (ROM 0xe1a38e..0xe1a3b4), 38 bytes
; Widget records of element 11 of Viewable slot 0xbe (table 0xe1b926, 33
; entries, InitializeSuna), element 0 "CmpCstmCpScreen"; classes:
; PsCstmCpBnkBox (38 B, id 0x0164000a).
; -----------------------------------------------------------------------------
NakaNode_CustomCopy_DestField:
	.incbin "includes/generated/naka_composer_style.bin", 0x2CAA, 0x26
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x3e_CustomCopy_InfoBtn
; Naka0x3e_CustomCopy_InfoBtn  --  naka_composer_style +0x2cd0..+0x2cfe (ROM 0xe1a3b4..0xe1a3e2), 46 bytes
; Widget records of element 12 of Viewable slot 0xbe (table 0xe1b926, 33
; entries, InitializeSuna), element 0 "CmpCstmCpScreen"; classes:
; VwEditSwBox (44 B, id 0x0160003e).
; -----------------------------------------------------------------------------
Naka0x3E_CustomCopy_InfoBtn:
	.incbin "includes/generated/naka_composer_style.bin", 0x2CD0, 0x2E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_CustomCopy_SrcPatternField
; NakaNode_CustomCopy_SrcPatternField  --  naka_composer_style +0x2cfe..+0x2d24 (ROM 0xe1a3e2..0xe1a408), 38 bytes
; Widget records of element 13 of Viewable slot 0xbe (table 0xe1b926, 33
; entries, InitializeSuna), element 0 "CmpCstmCpScreen"; classes:
; PsCstmCpSwBox (38 B, id 0x0164000b).
; -----------------------------------------------------------------------------
NakaNode_CustomCopy_SrcPatternField:
	.incbin "includes/generated/naka_composer_style.bin", 0x2CFE, 0x26
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_CustomCopy_DstPatternField
; NakaNode_CustomCopy_DstPatternField  --  naka_composer_style +0x2d24..+0x2d4a (ROM 0xe1a408..0xe1a42e), 38 bytes
; Widget records of element 14 of Viewable slot 0xbe (table 0xe1b926, 33
; entries, InitializeSuna), element 0 "CmpCstmCpScreen"; classes:
; PsCstmCpSwBox (38 B, id 0x0164000b).
; -----------------------------------------------------------------------------
NakaNode_CustomCopy_DstPatternField:
	.incbin "includes/generated/naka_composer_style.bin", 0x2D24, 0x26
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_CustomCopy_MemoryField
; NakaNode_CustomCopy_MemoryField  --  naka_composer_style +0x2d4a..+0x2d70 (ROM 0xe1a42e..0xe1a454), 38 bytes
; Widget records of element 15 of Viewable slot 0xbe (table 0xe1b926, 33
; entries, InitializeSuna), element 0 "CmpCstmCpScreen"; classes:
; PsCstmCpNameBox (38 B, id 0x0164001e).
; -----------------------------------------------------------------------------
NakaNode_CustomCopy_MemoryField:
	.incbin "includes/generated/naka_composer_style.bin", 0x2D4A, 0x26
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_CustomCopy_ProgressBar
; NakaNode_CustomCopy_ProgressBar  --  naka_composer_style +0x2d70..+0x2d90 (ROM 0xe1a454..0xe1a474), 32 bytes
; Widget records of element 16 of Viewable slot 0xbe (table 0xe1b926, 33
; entries, InitializeSuna), element 0 "CmpCstmCpScreen"; classes:
; Yajirushi (32 B, id 0x01640025).
; -----------------------------------------------------------------------------
NakaNode_CustomCopy_ProgressBar:
	.incbin "includes/generated/naka_composer_style.bin", 0x2D70, 0x20
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x35_CustomCopy_SongBar
; Naka0x35_CustomCopy_SongBar  --  naka_composer_style +0x2d90..+0x2db4 (ROM 0xe1a474..0xe1a498), 36 bytes
; Widget records of element 17 of Viewable slot 0xbe (table 0xe1b926, 33
; entries, InitializeSuna), element 0 "CmpCstmCpScreen"; classes: Window
; (36 B, id 0x01600035).
; -----------------------------------------------------------------------------
Naka0x35_CustomCopy_SongBar:
	.incbin "includes/generated/naka_composer_style.bin", 0x2D90, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x11_CustomCopy_PresetFrame
; Naka0x11_CustomCopy_PresetFrame  --  naka_composer_style +0x2db4..+0x2dd0 (ROM 0xe1a498..0xe1a4b4), 28 bytes
; Widget records of element 18 of Viewable slot 0xbe (table 0xe1b926, 33
; entries, InitializeSuna), element 0 "CmpCstmCpScreen"; classes: VwBox
; (28 B, id 0x01600011).
; -----------------------------------------------------------------------------
Naka0x11_CustomCopy_PresetFrame:
	.incbin "includes/generated/naka_composer_style.bin", 0x2DB4, 0x1C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaList_CustomCopy_PresetList
; NakaList_CustomCopy_PresetList  --  naka_composer_style +0x2dd0..+0x2dfa (ROM 0xe1a4b4..0xe1a4de), 42 bytes
; Widget records of element 19 of Viewable slot 0xbe (table 0xe1b926, 33
; entries, InitializeSuna), element 0 "CmpCstmCpScreen"; classes:
; AcLanguageText (42 B, id 0x01600066).
; -----------------------------------------------------------------------------
NakaList_CustomCopy_PresetList:
	.incbin "includes/generated/naka_composer_style.bin", 0x2DD0, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaList_CustomCopy_GroupList
; NakaList_CustomCopy_GroupList  --  naka_composer_style +0x2dfa..+0x2e24 (ROM 0xe1a4de..0xe1a508), 42 bytes
; Widget records of element 20 of Viewable slot 0xbe (table 0xe1b926, 33
; entries, InitializeSuna), element 0 "CmpCstmCpScreen"; classes:
; AcLanguageText (42 B, id 0x01600066).
; -----------------------------------------------------------------------------
NakaList_CustomCopy_GroupList:
	.incbin "includes/generated/naka_composer_style.bin", 0x2DFA, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaList_CustomCopy_RhythmList
; NakaList_CustomCopy_RhythmList  --  naka_composer_style +0x2e24..+0x2e4e (ROM 0xe1a508..0xe1a532), 42 bytes
; Widget records of element 21 of Viewable slot 0xbe (table 0xe1b926, 33
; entries, InitializeSuna), element 0 "CmpCstmCpScreen"; classes:
; AcLanguageText (42 B, id 0x01600066).
; -----------------------------------------------------------------------------
NakaList_CustomCopy_RhythmList:
	.incbin "includes/generated/naka_composer_style.bin", 0x2E24, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_CustomCopy_RhythmStatus
; NakaNode_CustomCopy_RhythmStatus  --  naka_composer_style +0x2e4e..+0x2e72 (ROM 0xe1a532..0xe1a556), 36 bytes
; Widget records of element 22 of Viewable slot 0xbe (table 0xe1b926, 33
; entries, InitializeSuna), element 0 "CmpCstmCpScreen"; classes:
; PsCtmAttStrBox (36 B, id 0x0164000c).
; -----------------------------------------------------------------------------
NakaNode_CustomCopy_RhythmStatus:
	.incbin "includes/generated/naka_composer_style.bin", 0x2E4E, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x3e_CustomCopy_ExecuteBtn
; Naka0x3e_CustomCopy_ExecuteBtn  --  naka_composer_style +0x2e72..+0x2ea6 (ROM 0xe1a556..0xe1a58a), 52 bytes
; Widget records of element 23 of Viewable slot 0xbe (table 0xe1b926, 33
; entries, InitializeSuna), element 0 "CmpCstmCpScreen"; classes:
; VwEditSwBox (44 B, id 0x0160003e).
; -----------------------------------------------------------------------------
Naka0x3E_CustomCopy_ExecuteBtn:
	.incbin "includes/generated/naka_composer_style.bin", 0x2E72, 0x34
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x3e_CustomCopy_AbortBtn1
; Naka0x3e_CustomCopy_AbortBtn1  --  naka_composer_style +0x2ea6..+0x2ed8 (ROM 0xe1a58a..0xe1a5bc), 50 bytes
; Widget records of element 24 of Viewable slot 0xbe (table 0xe1b926, 33
; entries, InitializeSuna), element 0 "CmpCstmCpScreen"; classes:
; VwEditSwBox (44 B, id 0x0160003e).
; -----------------------------------------------------------------------------
Naka0x3E_CustomCopy_AbortBtn1:
	.incbin "includes/generated/naka_composer_style.bin", 0x2EA6, 0x32
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x35_CustomCopy_DestSongBar
; Naka0x35_CustomCopy_DestSongBar  --  naka_composer_style +0x2ed8..+0x2efc (ROM 0xe1a5bc..0xe1a5e0), 36 bytes
; Widget records of element 25 of Viewable slot 0xbe (table 0xe1b926, 33
; entries, InitializeSuna), element 0 "CmpCstmCpScreen"; classes: Window
; (36 B, id 0x01600035).
; -----------------------------------------------------------------------------
Naka0x35_CustomCopy_DestSongBar:
	.incbin "includes/generated/naka_composer_style.bin", 0x2ED8, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x11_CustomCopy_DestFrame
; Naka0x11_CustomCopy_DestFrame  --  naka_composer_style +0x2efc..+0x2f18 (ROM 0xe1a5e0..0xe1a5fc), 28 bytes
; Widget records of element 26 of Viewable slot 0xbe (table 0xe1b926, 33
; entries, InitializeSuna), element 0 "CmpCstmCpScreen"; classes: VwBox
; (28 B, id 0x01600011).
; -----------------------------------------------------------------------------
Naka0x11_CustomCopy_DestFrame:
	.incbin "includes/generated/naka_composer_style.bin", 0x2EFC, 0x1C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaList_CustomCopy_DestPresetList
; NakaList_CustomCopy_DestPresetList  --  naka_composer_style +0x2f18..+0x2f42 (ROM 0xe1a5fc..0xe1a626), 42 bytes
; Widget records of element 27 of Viewable slot 0xbe (table 0xe1b926, 33
; entries, InitializeSuna), element 0 "CmpCstmCpScreen"; classes:
; AcLanguageText (42 B, id 0x01600066).
; -----------------------------------------------------------------------------
NakaList_CustomCopy_DestPresetList:
	.incbin "includes/generated/naka_composer_style.bin", 0x2F18, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaList_CustomCopy_DestGroupList
; NakaList_CustomCopy_DestGroupList  --  naka_composer_style +0x2f42..+0x2f6c (ROM 0xe1a626..0xe1a650), 42 bytes
; Widget records of element 28 of Viewable slot 0xbe (table 0xe1b926, 33
; entries, InitializeSuna), element 0 "CmpCstmCpScreen"; classes:
; AcLanguageText (42 B, id 0x01600066).
; -----------------------------------------------------------------------------
NakaList_CustomCopy_DestGroupList:
	.incbin "includes/generated/naka_composer_style.bin", 0x2F42, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaList_CustomCopy_DestRhythmList
; NakaList_CustomCopy_DestRhythmList  --  naka_composer_style +0x2f6c..+0x2f96 (ROM 0xe1a650..0xe1a67a), 42 bytes
; Widget records of element 29 of Viewable slot 0xbe (table 0xe1b926, 33
; entries, InitializeSuna), element 0 "CmpCstmCpScreen"; classes:
; AcLanguageText (42 B, id 0x01600066).
; -----------------------------------------------------------------------------
NakaList_CustomCopy_DestRhythmList:
	.incbin "includes/generated/naka_composer_style.bin", 0x2F6C, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_CustomCopy_DestRhythmStatus
; NakaNode_CustomCopy_DestRhythmStatus  --  naka_composer_style +0x2f96..+0x2fba (ROM 0xe1a67a..0xe1a69e), 36 bytes
; Widget records of element 30 of Viewable slot 0xbe (table 0xe1b926, 33
; entries, InitializeSuna), element 0 "CmpCstmCpScreen"; classes:
; PsCtmAttStrBox (36 B, id 0x0164000c).
; -----------------------------------------------------------------------------
NakaNode_CustomCopy_DestRhythmStatus:
	.incbin "includes/generated/naka_composer_style.bin", 0x2F96, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x3e_CustomCopy_ExecuteBtn2
; Naka0x3e_CustomCopy_ExecuteBtn2  --  naka_composer_style +0x2fba..+0x2fee (ROM 0xe1a69e..0xe1a6d2), 52 bytes
; Widget records of element 31 of Viewable slot 0xbe (table 0xe1b926, 33
; entries, InitializeSuna), element 0 "CmpCstmCpScreen"; classes:
; VwEditSwBox (44 B, id 0x0160003e).
; -----------------------------------------------------------------------------
Naka0x3E_CustomCopy_ExecuteBtn2:
	.incbin "includes/generated/naka_composer_style.bin", 0x2FBA, 0x34
; -----------------------------------------------------------------------------
; [nakarest_retype] Naka0x3e_CustomCopy_AbortBtn2
; Naka0x3e_CustomCopy_AbortBtn2  --  naka_composer_style +0x2fee..+0x3020 (ROM 0xe1a6d2..0xe1a704), 50 bytes
; Widget records of element 32 of Viewable slot 0xbe (table 0xe1b926, 33
; entries, InitializeSuna), element 0 "CmpCstmCpScreen"; classes:
; VwEditSwBox (44 B, id 0x0160003e).
; -----------------------------------------------------------------------------
Naka0x3E_CustomCopy_AbortBtn2:
	.incbin "includes/generated/naka_composer_style.bin", 0x2FEE, 0x32
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaContainer_CustomCopy_FinalRoot
; NakaContainer_CustomCopy_FinalRoot  --  naka_composer_style +0x3020..+0x304a (ROM 0xe1a704..0xe1a72e), 42 bytes
; Widget records of element 0 of Viewable slot 0xc8 (table 0xe1b9ae, 27
; entries, InitializeSuna), element 0 "MspBkslScreen"; classes:
; TtlScreen (42 B, id 0x01600034).
; -----------------------------------------------------------------------------
NakaContainer_CustomCopy_FinalRoot:
	.incbin "includes/generated/naka_composer_style.bin", 0x3020, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] String_MSP_BANK_SELECT
; String_MSP_BANK_SELECT  --  naka_composer_style +0x304a..+0x305a (ROM 0xe1a72e..0xe1a73e), 16 bytes
; No RegObjTabl-registered table points at the start of these 16 bytes
; (0xe1a72e..0xe1a73e); purpose not established by that route.
; -----------------------------------------------------------------------------
String_MSP_BANK_SELECT:
	.incbin "includes/generated/naka_composer_style.bin", 0x304A, 0x10
; External label offsets within the binary blob above.
