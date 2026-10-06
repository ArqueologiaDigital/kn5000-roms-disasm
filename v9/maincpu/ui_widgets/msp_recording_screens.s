
; MSP Recording & Accompaniment screen widgets (32 widgets, 3222 bytes)
; Source: maincpu/ui_widgets/naka_msp_recording.c (C struct with named fields)
; -----------------------------------------------------------------------------
; [nakarest_retype] registered NAKA tables: naka_msp_recording
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
; Viewable slot 0xc9: RegObjTabl 0x1600010, ViewableProc, 0x10,
; 0xe1ba1e, 0xc9 in InitializeSuna (storage/flash_floppy_handlers.s),
; i.e. RegisterObjectTable stores {class, proc, 16, table} at 0x27ed2 +
; 14*0xc9. Element 0 is named "MspRecScreen" in ResName slot 0x3c9.
; Links: all 16 records consistent.
;
; Viewable slot 0xca: RegObjTabl 0x1600010, ViewableProc, 0x6, 0xe1ba62,
; 0xca in InitializeSuna (storage/flash_floppy_handlers.s), i.e.
; RegisterObjectTable stores {class, proc, 6, table} at 0x27ed2 +
; 14*0xca. Element 0 is named "MspMenuScreen" in ResName slot 0x3ca.
; Links: all 6 records consistent.
;
; Viewable slot 0xcb: RegObjTabl 0x1600010, ViewableProc, 0x4, 0xe1ba7e,
; 0xcb in InitializeSuna (storage/flash_floppy_handlers.s), i.e.
; RegisterObjectTable stores {class, proc, 4, table} at 0x27ed2 +
; 14*0xcb. Element 0 is named "MspNamingScreen" in ResName slot 0x3cb.
; Links: all 4 records consistent.
;
; Viewable slot 0xcc: RegObjTabl 0x1600010, ViewableProc, 0x9, 0xe1ba92,
; 0xcc in InitializeSuna (storage/flash_floppy_handlers.s), i.e.
; RegisterObjectTable stores {class, proc, 9, table} at 0x27ed2 +
; 14*0xcc. Element 0 is named "MspReGrpScreen" in ResName slot 0x3cc.
; Links: all 9 records consistent.
;
; Viewable slot 0xdc: RegObjTabl 0x1600010, ViewableProc, 0x8, 0xe1baba,
; 0xdc in InitializeSuna (storage/flash_floppy_handlers.s), i.e.
; RegisterObjectTable stores {class, proc, 8, table} at 0x27ed2 +
; 14*0xdc. Element 0 is named "SndArgrScreen" in ResName slot 0x3dc.
; Links: all 8 records consistent.
;
; Viewable slot 0xed: RegObjTabl 0x1600010, ViewableProc, 0x6, 0xe1bade,
; 0xed in InitializeSuna (storage/flash_floppy_handlers.s), i.e.
; RegisterObjectTable stores {class, proc, 6, table} at 0x27ed2 +
; 14*0xed. Element 0 is named "ApcSelScreen" in ResName slot 0x3ed.
; Links: all 6 records consistent.
; -----------------------------------------------------------------------------

; [nakarest] NakaNode_Accomp7_Widget27  +0x0..+0x40 (0xe1ab58, 64 B)
; [nakarest] widget record, element 0 of Viewable slot 0xc9 (table 0xe1ba1e, 16 entries,
; [nakarest] InitializeSuna) ("MspRecScreen"): TtlScreen (42 B). 1 text the records point at
; [nakarest] (Viewable slot 0xc9 (table 0xe1ba1e, 16 entries, InitializeSuna)): "MSP PHRASE
; [nakarest] RECORDING" (TtlScreen.title of element 0).
NakaNode_Accomp7_Widget27:	.incbin "includes/generated/naka_msp_recording.bin", 0x0, 0x40
; [nakarest] NakaNode_Accomp8_Widget01  +0x40..+0x5c (0xe1ab98, 28 B)
; [nakarest] widget record, element 1 of Viewable slot 0xc9 (table 0xe1ba1e, 16 entries,
; [nakarest] InitializeSuna) ("MspRecScreen"): VwBox (28 B).
NakaNode_Accomp8_Widget01:	.incbin "includes/generated/naka_msp_recording.bin", 0x40, 0x1C
; [nakarest] NakaNode_Accomp8_Widget02  +0x5c..+0x8e (0xe1abb4, 50 B)
; [nakarest] widget record, element 2 of Viewable slot 0xc9 (table 0xe1ba1e, 16 entries,
; [nakarest] InitializeSuna) ("MspRecScreen"): Label (32 B). 1 text the records point at
; [nakarest] (Viewable slot 0xc9 (table 0xe1ba1e, 16 entries, InitializeSuna)): "Recording
; [nakarest] Phrase" (Label.str of element 2).
NakaNode_Accomp8_Widget02:	.incbin "includes/generated/naka_msp_recording.bin", 0x5C, 0x32
; [nakarest] NakaNode_Accomp8_Widget03  +0x8e..+0xb6 (0xe1abe6, 40 B)
; [nakarest] widget record, element 3 of Viewable slot 0xc9 (table 0xe1ba1e, 16 entries,
; [nakarest] InitializeSuna) ("MspRecScreen"): Label (32 B). 1 text the records point at
; [nakarest] (Viewable slot 0xc9 (table 0xe1ba1e, 16 entries, InitializeSuna)): "BANK :"
; [nakarest] (Label.str of element 3).
NakaNode_Accomp8_Widget03:	.incbin "includes/generated/naka_msp_recording.bin", 0x8E, 0x28
; [nakarest] NakaNode_Accomp8_Widget04  +0xb6..+0xda (0xe1ac0e, 36 B)
; [nakarest] widget record, element 4 of Viewable slot 0xc9 (table 0xe1ba1e, 16 entries,
; [nakarest] InitializeSuna) ("MspRecScreen"): PsMspRecPadBox (36 B).
NakaNode_Accomp8_Widget04:	.incbin "includes/generated/naka_msp_recording.bin", 0xB6, 0x24
; [nakarest] NakaNode_Accomp8_Widget05  +0xda..+0xfe (0xe1ac32, 36 B)
; [nakarest] widget record, element 5 of Viewable slot 0xc9 (table 0xe1ba1e, 16 entries,
; [nakarest] InitializeSuna) ("MspRecScreen"): PsMspRecBnkBox (36 B).
NakaNode_Accomp8_Widget05:	.incbin "includes/generated/naka_msp_recording.bin", 0xDA, 0x24
; [nakarest] NakaNode_Accomp8_Widget06  +0xfe..+0x11a (0xe1ac56, 28 B)
; [nakarest] widget record, element 6 of Viewable slot 0xc9 (table 0xe1ba1e, 16 entries,
; [nakarest] InitializeSuna) ("MspRecScreen"): VwBox (28 B).
NakaNode_Accomp8_Widget06:	.incbin "includes/generated/naka_msp_recording.bin", 0xFE, 0x1C
; [nakarest] NakaNode_Accomp8_Widget07  +0x11a..+0x144 (0xe1ac72, 42 B)
; [nakarest] widget record, element 7 of Viewable slot 0xc9 (table 0xe1ba1e, 16 entries,
; [nakarest] InitializeSuna) ("MspRecScreen"): Label (32 B). 1 text the records point at
; [nakarest] (Viewable slot 0xc9 (table 0xe1ba1e, 16 entries, InitializeSuna)): "TEMPO ="
; [nakarest] (Label.str of element 7).
NakaNode_Accomp8_Widget07:	.incbin "includes/generated/naka_msp_recording.bin", 0x11A, 0x2A
; [nakarest] NakaNode_Accomp8_Widget08  +0x144..+0x168 (0xe1ac9c, 36 B)
; [nakarest] widget record, element 8 of Viewable slot 0xc9 (table 0xe1ba1e, 16 entries,
; [nakarest] InitializeSuna) ("MspRecScreen"): AcCmpTempoBox (36 B).
NakaNode_Accomp8_Widget08:	.incbin "includes/generated/naka_msp_recording.bin", 0x144, 0x24
; [nakarest] NakaNode_Accomp8_Widget09  +0x168..+0x18c (0xe1acc0, 36 B)
; [nakarest] widget record, element 9 of Viewable slot 0xc9 (table 0xe1ba1e, 16 entries,
; [nakarest] InitializeSuna) ("MspRecScreen"): PsMspMeasBox (36 B).
NakaNode_Accomp8_Widget09:	.incbin "includes/generated/naka_msp_recording.bin", 0x168, 0x24
; [nakarest] NakaNode_Accomp8_Widget10  +0x18c..+0x1b0 (0xe1ace4, 36 B)
; [nakarest] widget record, element 10 of Viewable slot 0xc9 (table 0xe1ba1e, 16 entries,
; [nakarest] InitializeSuna) ("MspRecScreen"): PsMspMemBox (36 B).
NakaNode_Accomp8_Widget10:	.incbin "includes/generated/naka_msp_recording.bin", 0x18C, 0x24
; [nakarest] NakaNode_Accomp8_Widget11  +0x1b0..+0x1d2 (0xe1ad08, 34 B)
; [nakarest] widget record, element 11 of Viewable slot 0xc9 (table 0xe1ba1e, 16 entries,
; [nakarest] InitializeSuna) ("MspRecScreen"): Label (32 B). 1 text the records point at
; [nakarest] (Viewable slot 0xc9 (table 0xe1ba1e, 16 entries, InitializeSuna)): "%" (Label.str
; [nakarest] of element 11).
NakaNode_Accomp8_Widget11:	.incbin "includes/generated/naka_msp_recording.bin", 0x1B0, 0x22
; [nakarest] NakaNode_Accomp8_Widget12  +0x1d2..+0x1fa (0xe1ad2a, 40 B)
; [nakarest] widget record, element 12 of Viewable slot 0xc9 (table 0xe1ba1e, 16 entries,
; [nakarest] InitializeSuna) ("MspRecScreen"): Label (32 B). 1 text the records point at
; [nakarest] (Viewable slot 0xc9 (table 0xe1ba1e, 16 entries, InitializeSuna)): "PAD :"
; [nakarest] (Label.str of element 12).
NakaNode_Accomp8_Widget12:	.incbin "includes/generated/naka_msp_recording.bin", 0x1D2, 0x28
; [nakarest] NakaNode_Accomp8_Widget13  +0x1fa..+0x240 (0xe1ad52, 70 B)
; [nakarest] widget record, element 13 of Viewable slot 0xc9 (table 0xe1ba1e, 16 entries,
; [nakarest] InitializeSuna) ("MspRecScreen"): AcRamEditBox (58 B). 1 text the records point at
; [nakarest] (Viewable slot 0xc9 (table 0xe1ba1e, 16 entries, InitializeSuna)): "play mode :"
; [nakarest] (AcRamEditBox.caption of element 13).
NakaNode_Accomp8_Widget13:	.incbin "includes/generated/naka_msp_recording.bin", 0x1FA, 0x46
; [nakarest] NakaNode_Accomp8_Widget14  +0x240..+0x26a (0xe1ad98, 42 B)
; [nakarest] widget record, element 14 of Viewable slot 0xc9 (table 0xe1ba1e, 16 entries,
; [nakarest] InitializeSuna) ("MspRecScreen"): AcIndexWideES (42 B).
NakaNode_Accomp8_Widget14:	.incbin "includes/generated/naka_msp_recording.bin", 0x240, 0x2A
; [nakarest] NakaNode_Accomp8_Widget15  +0x26a..+0x284 (0xe1adc2, 26 B)
; [nakarest] widget record, element 15 of Viewable slot 0xc9 (table 0xe1ba1e, 16 entries,
; [nakarest] InitializeSuna) ("MspRecScreen"): IvExitMode (26 B).
NakaNode_Accomp8_Widget15:	.incbin "includes/generated/naka_msp_recording.bin", 0x26A, 0x1A
; [nakarest] NakaNode_Accomp9_Widget01  +0x284..+0x2b8 (0xe1addc, 52 B)
; [nakarest] widget record, element 0 of Viewable slot 0xca (table 0xe1ba62, 6 entries,
; [nakarest] InitializeSuna) ("MspMenuScreen"): TtlScreen (42 B). 1 text the records point at
; [nakarest] (Viewable slot 0xca (table 0xe1ba62, 6 entries, InitializeSuna)): "MSP MENU"
; [nakarest] (TtlScreen.title of element 0).
NakaNode_Accomp9_Widget01:	.incbin "includes/generated/naka_msp_recording.bin", 0x284, 0x34
; [nakarest] NakaNode_Accomp9_Widget02  +0x2b8..+0x2fa (0xe1ae10, 66 B)
; [nakarest] widget record, element 1 of Viewable slot 0xca (table 0xe1ba62, 6 entries,
; [nakarest] InitializeSuna) ("MspMenuScreen"): AcTitleMenu (54 B). 1 text the records point at
; [nakarest] (Viewable slot 0xca (table 0xe1ba62, 6 entries, InitializeSuna)): "COMPILE SET"
; [nakarest] (AcTitleMenu.str of element 1).
NakaNode_Accomp9_Widget02:	.incbin "includes/generated/naka_msp_recording.bin", 0x2B8, 0x42
; [nakarest] NakaNode_Accomp9_Widget03  +0x2fa..+0x34e (0xe1ae52, 84 B)
; [nakarest] widget record, element 2 of Viewable slot 0xca (table 0xe1ba62, 6 entries,
; [nakarest] InitializeSuna) ("MspMenuScreen"): AcTitleMenu (54 B). 1 text the records point at
; [nakarest] (Viewable slot 0xca (table 0xe1ba62, 6 entries, InitializeSuna)): "Naming for
; [nakarest] User&COMPILE Banks" (AcTitleMenu.str of element 2).
NakaNode_Accomp9_Widget03:	.incbin "includes/generated/naka_msp_recording.bin", 0x2FA, 0x54
; [nakarest] NakaNode_Accomp9_Widget04  +0x34e..+0x368 (0xe1aea6, 26 B)
; [nakarest] widget record, element 3 of Viewable slot 0xca (table 0xe1ba62, 6 entries,
; [nakarest] InitializeSuna) ("MspMenuScreen"): IvExitMode (26 B).
NakaNode_Accomp9_Widget04:	.incbin "includes/generated/naka_msp_recording.bin", 0x34E, 0x1A
; [nakarest] NakaNode_Accomp9_Widget05  +0x368..+0x3b0 (0xe1aec0, 72 B)
; [nakarest] widget record, element 4 of Viewable slot 0xca (table 0xe1ba62, 6 entries,
; [nakarest] InitializeSuna) ("MspMenuScreen"): AcRamEditBox (58 B). 1 text the records point at
; [nakarest] (Viewable slot 0xca (table 0xe1ba62, 6 entries, InitializeSuna)): "Naming Bank :"
; [nakarest] (AcRamEditBox.caption of element 4).
NakaNode_Accomp9_Widget05:	.incbin "includes/generated/naka_msp_recording.bin", 0x368, 0x48
; [nakarest] NakaNode_Accomp9_Widget06  +0x3b0..+0x3da (0xe1af08, 42 B)
; [nakarest] widget record, element 5 of Viewable slot 0xca (table 0xe1ba62, 6 entries,
; [nakarest] InitializeSuna) ("MspMenuScreen"): AcIndexWideES (42 B).
NakaNode_Accomp9_Widget06:	.incbin "includes/generated/naka_msp_recording.bin", 0x3B0, 0x2A
; [nakarest] NakaNode_Accomp10_Widget01  +0x3da..+0x40c (0xe1af32, 50 B)
; [nakarest] widget record, element 0 of Viewable slot 0xcb (table 0xe1ba7e, 4 entries,
; [nakarest] InitializeSuna) ("MspNamingScreen"): TtlScreen (42 B). 1 text the records point at
; [nakarest] (Viewable slot 0xcb (table 0xe1ba7e, 4 entries, InitializeSuna)): "NAMING"
; [nakarest] (TtlScreen.title of element 0).
NakaNode_Accomp10_Widget01:	.incbin "includes/generated/naka_msp_recording.bin", 0x3DA, 0x32
; [nakarest] NakaNode_Accomp10_Widget02  +0x40c..+0x438 (0xe1af64, 44 B)
; [nakarest] widget record, element 1 of Viewable slot 0xcb (table 0xe1ba7e, 4 entries,
; [nakarest] InitializeSuna) ("MspNamingScreen"): AcFuncEditSw (44 B).
NakaNode_Accomp10_Widget02:	.incbin "includes/generated/naka_msp_recording.bin", 0x40C, 0x2C
; [nakarest] NakaNode_Accomp10_Widget03  +0x438..+0x452 (0xe1af90, 26 B)
; [nakarest] widget record, element 2 of Viewable slot 0xcb (table 0xe1ba7e, 4 entries,
; [nakarest] InitializeSuna) ("MspNamingScreen"): IvNaming (26 B).
NakaNode_Accomp10_Widget03:	.incbin "includes/generated/naka_msp_recording.bin", 0x438, 0x1A
; [nakarest] NakaNode_Accomp10_Widget04  +0x452..+0x476 (0xe1afaa, 36 B)
; [nakarest] widget record, element 3 of Viewable slot 0xcb (table 0xe1ba7e, 4 entries,
; [nakarest] InitializeSuna) ("MspNamingScreen"): PsMspNameBnk (36 B).
NakaNode_Accomp10_Widget04:	.incbin "includes/generated/naka_msp_recording.bin", 0x452, 0x24
; [nakarest] NakaNode_Accomp11_Widget01  +0x476..+0x4b4 (0xe1afce, 62 B)
; [nakarest] widget record, element 0 of Viewable slot 0xcc (table 0xe1ba92, 9 entries,
; [nakarest] InitializeSuna) ("MspReGrpScreen"): TtlScreen (42 B). 1 text the records point at
; [nakarest] (Viewable slot 0xcc (table 0xe1ba92, 9 entries, InitializeSuna)): "MSP COMPILE
; [nakarest] SETTING" (TtlScreen.title of element 0).
NakaNode_Accomp11_Widget01:	.incbin "includes/generated/naka_msp_recording.bin", 0x476, 0x3E
; [nakarest] NakaNode_Accomp11_Widget02  +0x4b4..+0x4e0 (0xe1b00c, 44 B)
; [nakarest] widget record, element 1 of Viewable slot 0xcc (table 0xe1ba92, 9 entries,
; [nakarest] InitializeSuna) ("MspReGrpScreen"): AcFuncEditSw (44 B).
NakaNode_Accomp11_Widget02:	.incbin "includes/generated/naka_msp_recording.bin", 0x4B4, 0x2C
; [nakarest] NakaNode_Accomp11_Widget03  +0x4e0..+0x50c (0xe1b038, 44 B)
; [nakarest] widget record, element 2 of Viewable slot 0xcc (table 0xe1ba92, 9 entries,
; [nakarest] InitializeSuna) ("MspReGrpScreen"): StringBox (38 B). 1 text the records point at
; [nakarest] (Viewable slot 0xcc (table 0xe1ba92, 9 entries, InitializeSuna)): "BANK"
; [nakarest] (StringBox.str of element 2).
NakaNode_Accomp11_Widget03:	.incbin "includes/generated/naka_msp_recording.bin", 0x4E0, 0x2C
; [nakarest] NakaNode_Accomp11_Widget04  +0x50c..+0x594 (0xe1b064, 136 B)
; [nakarest] widget record, element 3 of Viewable slot 0xcc (table 0xe1ba92, 9 entries,
; [nakarest] InitializeSuna) ("MspReGrpScreen"): AcGridBox (74 B). 2 texts the records point at
; [nakarest] (Viewable slot 0xcc (table 0xe1ba92, 9 entries, InitializeSuna)):
; [nakarest] "|-|PAD1|PAD2|PAD3|PAD4|PAD5|PAD6" (AcGridBox.fixedrow of element 3); "PADS| BANK
; [nakarest] |PHRASE" (AcGridBox.fixedcol of element 3).
NakaNode_Accomp11_Widget04:	.incbin "includes/generated/naka_msp_recording.bin", 0x50C, 0x88
; [nakarest] NakaNode_Accomp11_Widget05  +0x594..+0x5bc (0xe1b0ec, 40 B)
; [nakarest] widget record, element 4 of Viewable slot 0xcc (table 0xe1ba92, 9 entries,
; [nakarest] InitializeSuna) ("MspReGrpScreen"): AcIndexEditSw (40 B).
NakaNode_Accomp11_Widget05:	.incbin "includes/generated/naka_msp_recording.bin", 0x594, 0x28
; [nakarest] NakaNode_Accomp11_Widget06  +0x5bc..+0x5e6 (0xe1b114, 42 B)
; [nakarest] widget record, element 5 of Viewable slot 0xcc (table 0xe1ba92, 9 entries,
; [nakarest] InitializeSuna) ("MspReGrpScreen"): AcIndexWideES (42 B).
NakaNode_Accomp11_Widget06:	.incbin "includes/generated/naka_msp_recording.bin", 0x5BC, 0x2A
; [nakarest] NakaNode_Accomp11_Widget07  +0x5e6..+0x610 (0xe1b13e, 42 B)
; [nakarest] widget record, element 6 of Viewable slot 0xcc (table 0xe1ba92, 9 entries,
; [nakarest] InitializeSuna) ("MspReGrpScreen"): AcIndexWideES (42 B).
NakaNode_Accomp11_Widget07:	.incbin "includes/generated/naka_msp_recording.bin", 0x5E6, 0x2A
; [nakarest] NakaNode_Accomp11_Widget08  +0x610..+0x634 (0xe1b168, 36 B)
; [nakarest] widget record, element 7 of Viewable slot 0xcc (table 0xe1ba92, 9 entries,
; [nakarest] InitializeSuna) ("MspReGrpScreen"): PsRgpSetBnkBox (36 B).
NakaNode_Accomp11_Widget08:	.incbin "includes/generated/naka_msp_recording.bin", 0x610, 0x24
; [nakarest] NakaNode_Accomp11_Widget09  +0x634..+0x64e (0xe1b18c, 26 B)
; [nakarest] widget record, element 8 of Viewable slot 0xcc (table 0xe1ba92, 9 entries,
; [nakarest] InitializeSuna) ("MspReGrpScreen"): IvShowHide (26 B).
NakaNode_Accomp11_Widget09:	.incbin "includes/generated/naka_msp_recording.bin", 0x634, 0x1A
; [nakarest] NakaNode_Accomp12_Widget01  +0x64e..+0x688 (0xe1b1a6, 58 B)
; [nakarest] widget record, element 0 of Viewable slot 0xdc (table 0xe1baba, 8 entries,
; [nakarest] InitializeSuna) ("SndArgrScreen"): TtlScreen (42 B). 1 text the records point at
; [nakarest] (Viewable slot 0xdc (table 0xe1baba, 8 entries, InitializeSuna)): "SOUND ARRANGER"
; [nakarest] (TtlScreen.title of element 0).
NakaNode_Accomp12_Widget01:	.incbin "includes/generated/naka_msp_recording.bin", 0x64E, 0x3A
; [nakarest] NakaNode_Accomp12_Widget02  +0x688..+0x6ba (0xe1b1e0, 50 B)
; [nakarest] widget record, element 1 of Viewable slot 0xdc (table 0xe1baba, 8 entries,
; [nakarest] InitializeSuna) ("SndArgrScreen"): StringBox (38 B). 1 text the records point at
; [nakarest] (Viewable slot 0xdc (table 0xe1baba, 8 entries, InitializeSuna)): " PATTERN :"
; [nakarest] (StringBox.str of element 1).
NakaNode_Accomp12_Widget02:	.incbin "includes/generated/naka_msp_recording.bin", 0x688, 0x32
; [nakarest] NakaNode_Accomp12_Widget03  +0x6ba..+0x6de (0xe1b212, 36 B)
; [nakarest] widget record, element 2 of Viewable slot 0xdc (table 0xe1baba, 8 entries,
; [nakarest] InitializeSuna) ("SndArgrScreen"): PsCmpCpFVariBox (36 B).
NakaNode_Accomp12_Widget03:	.incbin "includes/generated/naka_msp_recording.bin", 0x6BA, 0x24
; [nakarest] NakaNode_Accomp12_Widget04  +0x6de..+0x6f8 (0xe1b236, 26 B)
; [nakarest] widget record, element 3 of Viewable slot 0xdc (table 0xe1baba, 8 entries,
; [nakarest] InitializeSuna) ("SndArgrScreen"): IvExitMode (26 B).
NakaNode_Accomp12_Widget04:	.incbin "includes/generated/naka_msp_recording.bin", 0x6DE, 0x1A
; [nakarest] NakaNode_Accomp12_Widget05  +0x6f8..+0x712 (0xe1b250, 26 B)
; [nakarest] widget record, element 4 of Viewable slot 0xdc (table 0xe1baba, 8 entries,
; [nakarest] InitializeSuna) ("SndArgrScreen"): IvShowHide (26 B).
NakaNode_Accomp12_Widget05:	.incbin "includes/generated/naka_msp_recording.bin", 0x6F8, 0x1A
; [nakarest] NakaNode_Accomp12_Widget06  +0x712..+0x7aa (0xe1b26a, 152 B)
; [nakarest] widget record, element 5 of Viewable slot 0xdc (table 0xe1baba, 8 entries,
; [nakarest] InitializeSuna) ("SndArgrScreen"): AcSndArgGridBox (74 B). 2 texts the records
; [nakarest] point at (Viewable slot 0xdc (table 0xe1baba, 8 entries, InitializeSuna)):
; [nakarest] "|-|DRUMS|BASS|ACCOMP1|ACCOMP2|ACCOMP3" (AcSndArgGridBox.fixedrow of element 5); "
; [nakarest] PART | SOUND |D.EFFECT" (AcSndArgGridBox.fixedcol of element 5).
NakaNode_Accomp12_Widget06:	.incbin "includes/generated/naka_msp_recording.bin", 0x712, 0x98
; [nakarest] NakaNode_Accomp12_Widget07  +0x7aa..+0x7d4 (0xe1b302, 42 B)
; [nakarest] widget record, element 6 of Viewable slot 0xdc (table 0xe1baba, 8 entries,
; [nakarest] InitializeSuna) ("SndArgrScreen"): AcIndexWideES (42 B).
NakaNode_Accomp12_Widget07:	.incbin "includes/generated/naka_msp_recording.bin", 0x7AA, 0x2A
; [nakarest] NakaNode_Accomp12_Widget08  +0x7d4..+0x7fe (0xe1b32c, 42 B)
; [nakarest] widget record, element 7 of Viewable slot 0xdc (table 0xe1baba, 8 entries,
; [nakarest] InitializeSuna) ("SndArgrScreen"): AcLanguageText (42 B).
NakaNode_Accomp12_Widget08:	.incbin "includes/generated/naka_msp_recording.bin", 0x7D4, 0x2A
; [nakarest] NakaNode_Accomp13_Widget01  +0x7fe..+0x838 (0xe1b356, 58 B)
; [nakarest] widget record, element 0 of Viewable slot 0xed (table 0xe1bade, 6 entries,
; [nakarest] InitializeSuna) ("ApcSelScreen"): TtlScreen (42 B). 1 text the records point at
; [nakarest] (Viewable slot 0xed (table 0xe1bade, 6 entries, InitializeSuna)): "AUTO PLAY CHORD"
; [nakarest] (TtlScreen.title of element 0).
NakaNode_Accomp13_Widget01:	.incbin "includes/generated/naka_msp_recording.bin", 0x7FE, 0x3A
; [nakarest] NakaNode_Accomp13_Widget02  +0x838..+0x878 (0xe1b390, 64 B)
; [nakarest] widget record, element 1 of Viewable slot 0xed (table 0xe1bade, 6 entries,
; [nakarest] InitializeSuna) ("ApcSelScreen"): AcApcMdBox (52 B). 1 text the records point at
; [nakarest] (Viewable slot 0xed (table 0xe1bade, 6 entries, InitializeSuna)): "ONE FINGER"
; [nakarest] (AcApcMdBox.caption of element 1).
NakaNode_Accomp13_Widget02:	.incbin "includes/generated/naka_msp_recording.bin", 0x838, 0x40
; [nakarest] NakaNode_Accomp13_Widget03  +0x878..+0x8b6 (0xe1b3d0, 62 B)
; [nakarest] widget record, element 2 of Viewable slot 0xed (table 0xe1bade, 6 entries,
; [nakarest] InitializeSuna) ("ApcSelScreen"): AcApcMdBox (52 B). 1 text the records point at
; [nakarest] (Viewable slot 0xed (table 0xe1bade, 6 entries, InitializeSuna)): "FINGERED"
; [nakarest] (AcApcMdBox.caption of element 2).
NakaNode_Accomp13_Widget03:	.incbin "includes/generated/naka_msp_recording.bin", 0x878, 0x3E
; [nakarest] NakaNode_Accomp13_Widget04  +0x8b6..+0x8f2 (0xe1b40e, 60 B)
; [nakarest] widget record, element 3 of Viewable slot 0xed (table 0xe1bade, 6 entries,
; [nakarest] InitializeSuna) ("ApcSelScreen"): AcApcMdBox (52 B). 1 text the records point at
; [nakarest] (Viewable slot 0xed (table 0xe1bade, 6 entries, InitializeSuna)): "PIANIST"
; [nakarest] (AcApcMdBox.caption of element 3).
NakaNode_Accomp13_Widget04:	.incbin "includes/generated/naka_msp_recording.bin", 0x8B6, 0x3C
; [nakarest] NakaNode_Accomp13_Widget05  +0x8f2..+0x93e (0xe1b44a, 76 B)
; [nakarest] widget record, element 4 of Viewable slot 0xed (table 0xe1bade, 6 entries,
; [nakarest] InitializeSuna) ("ApcSelScreen"): AcApcToggle (48 B). 2 texts the records point at
; [nakarest] (Viewable slot 0xed (table 0xe1bade, 6 entries, InitializeSuna)): " MEMORY : OFF"
; [nakarest] (AcApcToggle.stroff of element 4); " MEMORY : ON" (AcApcToggle.stron of element 4).
NakaNode_Accomp13_Widget05:	.incbin "includes/generated/naka_msp_recording.bin", 0x8F2, 0x4C
; [nakarest] NakaNode_Accomp13_Widget06  +0x93e..+0x98a (0xe1b496, 76 B)
; [nakarest] widget record, element 5 of Viewable slot 0xed (table 0xe1bade, 6 entries,
; [nakarest] InitializeSuna) ("ApcSelScreen"): AcApcToggle (48 B). 2 texts the records point at
; [nakarest] (Viewable slot 0xed (table 0xe1bade, 6 entries, InitializeSuna)): "ON BASS : OFF"
; [nakarest] (AcApcToggle.stroff of element 5); "ON BASS : ON" (AcApcToggle.stron of element 5).
NakaNode_Accomp13_Widget06:	.incbin "includes/generated/naka_msp_recording.bin", 0x93E, 0x4C
; [nakarest] naka_msp_recording+0x98a  +0x98a..+0x99a (0xe1b4e2, 16 B)
; [nakarest] the table itself: Viewable slot 0x10 (table 0xe1b4e2, 3 entries, InitializeSuna), 3
; [nakarest] entry pointers x 4 bytes.
Suna_ViewableTable_010:	.incbin "includes/generated/naka_msp_recording.bin", 0x98A, 0x10
; [nakarest] naka_msp_recording+0x99a  +0x99a..+0x9be (0xe1b4f2, 36 B)
; [nakarest] the table itself: Viewable slot 0x11 (table 0xe1b4f2, 8 entries, InitializeSuna), 8
; [nakarest] entry pointers x 4 bytes.
Suna_ViewableTable_011:	.incbin "includes/generated/naka_msp_recording.bin", 0x99A, 0x24
; [nakarest] naka_msp_recording+0x9be  +0x9be..+0x9de (0xe1b516, 32 B)
; [nakarest] the table itself: Viewable slot 0x12 (table 0xe1b516, 7 entries, InitializeSuna), 7
; [nakarest] entry pointers x 4 bytes.
Suna_ViewableTable_012:	.incbin "includes/generated/naka_msp_recording.bin", 0x9BE, 0x20
; [nakarest] naka_msp_recording+0x9de  +0x9de..+0x9f2 (0xe1b536, 20 B)
; [nakarest] the table itself: Viewable slot 0x13 (table 0xe1b536, 4 entries, InitializeSuna), 4
; [nakarest] entry pointers x 4 bytes.
Suna_ViewableTable_013:	.incbin "includes/generated/naka_msp_recording.bin", 0x9DE, 0x14
; [nakarest] naka_msp_recording+0x9f2  +0x9f2..+0xa06 (0xe1b54a, 20 B)
; [nakarest] the table itself: Viewable slot 0x14 (table 0xe1b54a, 4 entries, InitializeSuna), 4
; [nakarest] entry pointers x 4 bytes.
Suna_ViewableTable_014:	.incbin "includes/generated/naka_msp_recording.bin", 0x9F2, 0x14
; [nakarest] naka_msp_recording+0xa06  +0xa06..+0xa2a (0xe1b55e, 36 B)
; [nakarest] the table itself: Viewable slot 0x15 (table 0xe1b55e, 8 entries, InitializeSuna), 8
; [nakarest] entry pointers x 4 bytes.
Suna_ViewableTable_015:	.incbin "includes/generated/naka_msp_recording.bin", 0xA06, 0x24
; [nakarest] naka_msp_recording+0xa2a  +0xa2a..+0xa4a (0xe1b582, 32 B)
; [nakarest] the table itself: Viewable slot 0x16 (table 0xe1b582, 7 entries, InitializeSuna), 7
; [nakarest] entry pointers x 4 bytes.
Suna_ViewableTable_016:	.incbin "includes/generated/naka_msp_recording.bin", 0xA2A, 0x20
; [nakarest] naka_msp_recording+0xa4a  +0xa4a..+0xa96 (0xe1b5a2, 76 B)
; [nakarest] the table itself: Viewable slot 0xb0 (table 0xe1b5a2, 18 entries, InitializeSuna),
; [nakarest] 18 entry pointers x 4 bytes.
Suna_ViewableTable_0B0:	.incbin "includes/generated/naka_msp_recording.bin", 0xA4A, 0x4C
; [nakarest] naka_msp_recording+0xa96  +0xa96..+0xaca (0xe1b5ee, 52 B)
; [nakarest] the table itself: Viewable slot 0xb1 (table 0xe1b5ee, 12 entries, InitializeSuna),
; [nakarest] 12 entry pointers x 4 bytes.
Suna_ViewableTable_0B1:	.incbin "includes/generated/naka_msp_recording.bin", 0xA96, 0x34
; [nakarest] naka_msp_recording+0xaca  +0xaca..+0xb26 (0xe1b622, 92 B)
; [nakarest] the table itself: Viewable slot 0xb2 (table 0xe1b622, 22 entries, InitializeSuna),
; [nakarest] 22 entry pointers x 4 bytes.
Suna_ViewableTable_0B2:	.incbin "includes/generated/naka_msp_recording.bin", 0xACA, 0x5C
; [nakarest] naka_msp_recording+0xb26  +0xb26..+0xb3e (0xe1b67e, 24 B)
; [nakarest] the table itself: Viewable slot 0xb3 (table 0xe1b67e, 5 entries, InitializeSuna), 5
; [nakarest] entry pointers x 4 bytes.
Suna_ViewableTable_0B3:	.incbin "includes/generated/naka_msp_recording.bin", 0xB26, 0x18
; [nakarest] naka_msp_recording+0xb3e  +0xb3e..+0xb8a (0xe1b696, 76 B)
; [nakarest] the table itself: Viewable slot 0xb4 (table 0xe1b696, 18 entries, InitializeSuna),
; [nakarest] 18 entry pointers x 4 bytes.
Suna_ViewableTable_0B4:	.incbin "includes/generated/naka_msp_recording.bin", 0xB3E, 0x4C
; [nakarest] naka_msp_recording+0xb8a  +0xb8a..+0xc0a (0xe1b6e2, 128 B)
; [nakarest] the table itself: Viewable slot 0xb5 (table 0xe1b6e2, 31 entries, InitializeSuna),
; [nakarest] 31 entry pointers x 4 bytes.
Suna_ViewableTable_0B5:	.incbin "includes/generated/naka_msp_recording.bin", 0xB8A, 0x80
; [nakarest] naka_msp_recording+0xc0a  +0xc0a..+0xc12 (0xe1b762, 8 B)
; [nakarest] the table itself: Viewable slot 0xb6 (table 0xe1b762, 1 entries, InitializeSuna), 1
; [nakarest] entry pointers x 4 bytes.
Suna_ViewableTable_0B6:	.incbin "includes/generated/naka_msp_recording.bin", 0xC0A, 0x8
; [nakarest] naka_msp_recording+0xc12  +0xc12..+0xc2e (0xe1b76a, 28 B)
; [nakarest] the table itself: Viewable slot 0xb7 (table 0xe1b76a, 6 entries, InitializeSuna), 6
; [nakarest] entry pointers x 4 bytes.
Suna_ViewableTable_0B7:	.incbin "includes/generated/naka_msp_recording.bin", 0xC12, 0x1C
; [nakarest] naka_msp_recording+0xc2e  +0xc2e..+0xc96 (0xe1b786, 104 B)
; [nakarest] the table itself: Viewable slot 0xb8 (table 0xe1b786, 33 entries, InitializeSuna),
; [nakarest] 33 entry pointers x 4 bytes.
Suna_ViewableTable_0B8:	.incbin "includes/generated/naka_msp_recording.bin", 0xC2E, 0x68
; External label offsets within the binary blob above.
; Referenced from naka_screen_dispatch.s (widget pointer tables).
