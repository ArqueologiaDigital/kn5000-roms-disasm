
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
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp7_Widget27
; NakaNode_Accomp7_Widget27  --  naka_msp_recording +0x0..+0x40 (ROM 0xe1ab58..0xe1ab98), 64 bytes
; Widget records of element 0 of Viewable slot 0xc9 (table 0xe1ba1e, 16
; entries, InitializeSuna), element 0 "MspRecScreen"; classes: TtlScreen
; (42 B, id 0x01600034).
; -----------------------------------------------------------------------------
NakaNode_Accomp7_Widget27:
	.incbin "includes/generated/naka_msp_recording.bin", 0x0, 0x40
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp8_Widget01
; NakaNode_Accomp8_Widget01  --  naka_msp_recording +0x40..+0x5c (ROM 0xe1ab98..0xe1abb4), 28 bytes
; Widget records of element 1 of Viewable slot 0xc9 (table 0xe1ba1e, 16
; entries, InitializeSuna), element 0 "MspRecScreen"; classes: VwBox (28
; B, id 0x01600011).
; -----------------------------------------------------------------------------
NakaNode_Accomp8_Widget01:
	.incbin "includes/generated/naka_msp_recording.bin", 0x40, 0x1C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp8_Widget02
; NakaNode_Accomp8_Widget02  --  naka_msp_recording +0x5c..+0x8e (ROM 0xe1abb4..0xe1abe6), 50 bytes
; Widget records of element 2 of Viewable slot 0xc9 (table 0xe1ba1e, 16
; entries, InitializeSuna), element 0 "MspRecScreen"; classes: Label (32
; B, id 0x0160002b).
; -----------------------------------------------------------------------------
NakaNode_Accomp8_Widget02:
	.incbin "includes/generated/naka_msp_recording.bin", 0x5C, 0x32
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp8_Widget03
; NakaNode_Accomp8_Widget03  --  naka_msp_recording +0x8e..+0xb6 (ROM 0xe1abe6..0xe1ac0e), 40 bytes
; Widget records of element 3 of Viewable slot 0xc9 (table 0xe1ba1e, 16
; entries, InitializeSuna), element 0 "MspRecScreen"; classes: Label (32
; B, id 0x0160002b).
; -----------------------------------------------------------------------------
NakaNode_Accomp8_Widget03:
	.incbin "includes/generated/naka_msp_recording.bin", 0x8E, 0x28
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp8_Widget04
; NakaNode_Accomp8_Widget04  --  naka_msp_recording +0xb6..+0xda (ROM 0xe1ac0e..0xe1ac32), 36 bytes
; Widget records of element 4 of Viewable slot 0xc9 (table 0xe1ba1e, 16
; entries, InitializeSuna), element 0 "MspRecScreen"; classes:
; PsMspRecPadBox (36 B, id 0x0164001b).
; -----------------------------------------------------------------------------
NakaNode_Accomp8_Widget04:
	.incbin "includes/generated/naka_msp_recording.bin", 0xB6, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp8_Widget05
; NakaNode_Accomp8_Widget05  --  naka_msp_recording +0xda..+0xfe (ROM 0xe1ac32..0xe1ac56), 36 bytes
; Widget records of element 5 of Viewable slot 0xc9 (table 0xe1ba1e, 16
; entries, InitializeSuna), element 0 "MspRecScreen"; classes:
; PsMspRecBnkBox (36 B, id 0x0164001c).
; -----------------------------------------------------------------------------
NakaNode_Accomp8_Widget05:
	.incbin "includes/generated/naka_msp_recording.bin", 0xDA, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp8_Widget06
; NakaNode_Accomp8_Widget06  --  naka_msp_recording +0xfe..+0x11a (ROM 0xe1ac56..0xe1ac72), 28 bytes
; Widget records of element 6 of Viewable slot 0xc9 (table 0xe1ba1e, 16
; entries, InitializeSuna), element 0 "MspRecScreen"; classes: VwBox (28
; B, id 0x01600011).
; -----------------------------------------------------------------------------
NakaNode_Accomp8_Widget06:
	.incbin "includes/generated/naka_msp_recording.bin", 0xFE, 0x1C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp8_Widget07
; NakaNode_Accomp8_Widget07  --  naka_msp_recording +0x11a..+0x144 (ROM 0xe1ac72..0xe1ac9c), 42 bytes
; Widget records of element 7 of Viewable slot 0xc9 (table 0xe1ba1e, 16
; entries, InitializeSuna), element 0 "MspRecScreen"; classes: Label (32
; B, id 0x0160002b).
; -----------------------------------------------------------------------------
NakaNode_Accomp8_Widget07:
	.incbin "includes/generated/naka_msp_recording.bin", 0x11A, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp8_Widget08
; NakaNode_Accomp8_Widget08  --  naka_msp_recording +0x144..+0x168 (ROM 0xe1ac9c..0xe1acc0), 36 bytes
; Widget records of element 8 of Viewable slot 0xc9 (table 0xe1ba1e, 16
; entries, InitializeSuna), element 0 "MspRecScreen"; classes:
; AcCmpTempoBox (36 B, id 0x01640011).
; -----------------------------------------------------------------------------
NakaNode_Accomp8_Widget08:
	.incbin "includes/generated/naka_msp_recording.bin", 0x144, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp8_Widget09
; NakaNode_Accomp8_Widget09  --  naka_msp_recording +0x168..+0x18c (ROM 0xe1acc0..0xe1ace4), 36 bytes
; Widget records of element 9 of Viewable slot 0xc9 (table 0xe1ba1e, 16
; entries, InitializeSuna), element 0 "MspRecScreen"; classes:
; PsMspMeasBox (36 B, id 0x01640019).
; -----------------------------------------------------------------------------
NakaNode_Accomp8_Widget09:
	.incbin "includes/generated/naka_msp_recording.bin", 0x168, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp8_Widget10
; NakaNode_Accomp8_Widget10  --  naka_msp_recording +0x18c..+0x1b0 (ROM 0xe1ace4..0xe1ad08), 36 bytes
; Widget records of element 10 of Viewable slot 0xc9 (table 0xe1ba1e, 16
; entries, InitializeSuna), element 0 "MspRecScreen"; classes:
; PsMspMemBox (36 B, id 0x0164001a).
; -----------------------------------------------------------------------------
NakaNode_Accomp8_Widget10:
	.incbin "includes/generated/naka_msp_recording.bin", 0x18C, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp8_Widget11
; NakaNode_Accomp8_Widget11  --  naka_msp_recording +0x1b0..+0x1d2 (ROM 0xe1ad08..0xe1ad2a), 34 bytes
; Widget records of element 11 of Viewable slot 0xc9 (table 0xe1ba1e, 16
; entries, InitializeSuna), element 0 "MspRecScreen"; classes: Label (32
; B, id 0x0160002b).
; -----------------------------------------------------------------------------
NakaNode_Accomp8_Widget11:
	.incbin "includes/generated/naka_msp_recording.bin", 0x1B0, 0x22
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp8_Widget12
; NakaNode_Accomp8_Widget12  --  naka_msp_recording +0x1d2..+0x1fa (ROM 0xe1ad2a..0xe1ad52), 40 bytes
; Widget records of element 12 of Viewable slot 0xc9 (table 0xe1ba1e, 16
; entries, InitializeSuna), element 0 "MspRecScreen"; classes: Label (32
; B, id 0x0160002b).
; -----------------------------------------------------------------------------
NakaNode_Accomp8_Widget12:
	.incbin "includes/generated/naka_msp_recording.bin", 0x1D2, 0x28
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp8_Widget13
; NakaNode_Accomp8_Widget13  --  naka_msp_recording +0x1fa..+0x240 (ROM 0xe1ad52..0xe1ad98), 70 bytes
; Widget records of element 13 of Viewable slot 0xc9 (table 0xe1ba1e, 16
; entries, InitializeSuna), element 0 "MspRecScreen"; classes:
; AcRamEditBox (58 B, id 0x0160001b).
; -----------------------------------------------------------------------------
NakaNode_Accomp8_Widget13:
	.incbin "includes/generated/naka_msp_recording.bin", 0x1FA, 0x46
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp8_Widget14
; NakaNode_Accomp8_Widget14  --  naka_msp_recording +0x240..+0x26a (ROM 0xe1ad98..0xe1adc2), 42 bytes
; Widget records of element 14 of Viewable slot 0xc9 (table 0xe1ba1e, 16
; entries, InitializeSuna), element 0 "MspRecScreen"; classes:
; AcIndexWideES (42 B, id 0x01600022).
; -----------------------------------------------------------------------------
NakaNode_Accomp8_Widget14:
	.incbin "includes/generated/naka_msp_recording.bin", 0x240, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp8_Widget15
; NakaNode_Accomp8_Widget15  --  naka_msp_recording +0x26a..+0x284 (ROM 0xe1adc2..0xe1addc), 26 bytes
; Widget records of element 15 of Viewable slot 0xc9 (table 0xe1ba1e, 16
; entries, InitializeSuna), element 0 "MspRecScreen"; classes:
; IvExitMode (26 B, id 0x01600048).
; -----------------------------------------------------------------------------
NakaNode_Accomp8_Widget15:
	.incbin "includes/generated/naka_msp_recording.bin", 0x26A, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp9_Widget01
; NakaNode_Accomp9_Widget01  --  naka_msp_recording +0x284..+0x2b8 (ROM 0xe1addc..0xe1ae10), 52 bytes
; Widget records of element 0 of Viewable slot 0xca (table 0xe1ba62, 6
; entries, InitializeSuna), element 0 "MspMenuScreen"; classes:
; TtlScreen (42 B, id 0x01600034).
; -----------------------------------------------------------------------------
NakaNode_Accomp9_Widget01:
	.incbin "includes/generated/naka_msp_recording.bin", 0x284, 0x34
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp9_Widget02
; NakaNode_Accomp9_Widget02  --  naka_msp_recording +0x2b8..+0x2fa (ROM 0xe1ae10..0xe1ae52), 66 bytes
; Widget records of element 1 of Viewable slot 0xca (table 0xe1ba62, 6
; entries, InitializeSuna), element 0 "MspMenuScreen"; classes:
; AcTitleMenu (54 B, id 0x0160001d).
; -----------------------------------------------------------------------------
NakaNode_Accomp9_Widget02:
	.incbin "includes/generated/naka_msp_recording.bin", 0x2B8, 0x42
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp9_Widget03
; NakaNode_Accomp9_Widget03  --  naka_msp_recording +0x2fa..+0x34e (ROM 0xe1ae52..0xe1aea6), 84 bytes
; Widget records of element 2 of Viewable slot 0xca (table 0xe1ba62, 6
; entries, InitializeSuna), element 0 "MspMenuScreen"; classes:
; AcTitleMenu (54 B, id 0x0160001d).
; -----------------------------------------------------------------------------
NakaNode_Accomp9_Widget03:
	.incbin "includes/generated/naka_msp_recording.bin", 0x2FA, 0x54
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp9_Widget04
; NakaNode_Accomp9_Widget04  --  naka_msp_recording +0x34e..+0x368 (ROM 0xe1aea6..0xe1aec0), 26 bytes
; Widget records of element 3 of Viewable slot 0xca (table 0xe1ba62, 6
; entries, InitializeSuna), element 0 "MspMenuScreen"; classes:
; IvExitMode (26 B, id 0x01600048).
; -----------------------------------------------------------------------------
NakaNode_Accomp9_Widget04:
	.incbin "includes/generated/naka_msp_recording.bin", 0x34E, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp9_Widget05
; NakaNode_Accomp9_Widget05  --  naka_msp_recording +0x368..+0x3b0 (ROM 0xe1aec0..0xe1af08), 72 bytes
; Widget records of element 4 of Viewable slot 0xca (table 0xe1ba62, 6
; entries, InitializeSuna), element 0 "MspMenuScreen"; classes:
; AcRamEditBox (58 B, id 0x0160001b).
; -----------------------------------------------------------------------------
NakaNode_Accomp9_Widget05:
	.incbin "includes/generated/naka_msp_recording.bin", 0x368, 0x48
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp9_Widget06
; NakaNode_Accomp9_Widget06  --  naka_msp_recording +0x3b0..+0x3da (ROM 0xe1af08..0xe1af32), 42 bytes
; Widget records of element 5 of Viewable slot 0xca (table 0xe1ba62, 6
; entries, InitializeSuna), element 0 "MspMenuScreen"; classes:
; AcIndexWideES (42 B, id 0x01600022).
; -----------------------------------------------------------------------------
NakaNode_Accomp9_Widget06:
	.incbin "includes/generated/naka_msp_recording.bin", 0x3B0, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp10_Widget01
; NakaNode_Accomp10_Widget01  --  naka_msp_recording +0x3da..+0x40c (ROM 0xe1af32..0xe1af64), 50 bytes
; Widget records of element 0 of Viewable slot 0xcb (table 0xe1ba7e, 4
; entries, InitializeSuna), element 0 "MspNamingScreen"; classes:
; TtlScreen (42 B, id 0x01600034).
; -----------------------------------------------------------------------------
NakaNode_Accomp10_Widget01:
	.incbin "includes/generated/naka_msp_recording.bin", 0x3DA, 0x32
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp10_Widget02
; NakaNode_Accomp10_Widget02  --  naka_msp_recording +0x40c..+0x438 (ROM 0xe1af64..0xe1af90), 44 bytes
; Widget records of element 1 of Viewable slot 0xcb (table 0xe1ba7e, 4
; entries, InitializeSuna), element 0 "MspNamingScreen"; classes:
; AcFuncEditSw (44 B, id 0x01600020).
; -----------------------------------------------------------------------------
NakaNode_Accomp10_Widget02:
	.incbin "includes/generated/naka_msp_recording.bin", 0x40C, 0x2C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp10_Widget03
; NakaNode_Accomp10_Widget03  --  naka_msp_recording +0x438..+0x452 (ROM 0xe1af90..0xe1afaa), 26 bytes
; Widget records of element 2 of Viewable slot 0xcb (table 0xe1ba7e, 4
; entries, InitializeSuna), element 0 "MspNamingScreen"; classes:
; IvNaming (26 B, id 0x0160004d).
; -----------------------------------------------------------------------------
NakaNode_Accomp10_Widget03:
	.incbin "includes/generated/naka_msp_recording.bin", 0x438, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp10_Widget04
; NakaNode_Accomp10_Widget04  --  naka_msp_recording +0x452..+0x476 (ROM 0xe1afaa..0xe1afce), 36 bytes
; Widget records of element 3 of Viewable slot 0xcb (table 0xe1ba7e, 4
; entries, InitializeSuna), element 0 "MspNamingScreen"; classes:
; PsMspNameBnk (36 B, id 0x0164001d).
; -----------------------------------------------------------------------------
NakaNode_Accomp10_Widget04:
	.incbin "includes/generated/naka_msp_recording.bin", 0x452, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp11_Widget01
; NakaNode_Accomp11_Widget01  --  naka_msp_recording +0x476..+0x4b4 (ROM 0xe1afce..0xe1b00c), 62 bytes
; Widget records of element 0 of Viewable slot 0xcc (table 0xe1ba92, 9
; entries, InitializeSuna), element 0 "MspReGrpScreen"; classes:
; TtlScreen (42 B, id 0x01600034).
; -----------------------------------------------------------------------------
NakaNode_Accomp11_Widget01:
	.incbin "includes/generated/naka_msp_recording.bin", 0x476, 0x3E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp11_Widget02
; NakaNode_Accomp11_Widget02  --  naka_msp_recording +0x4b4..+0x4e0 (ROM 0xe1b00c..0xe1b038), 44 bytes
; Widget records of element 1 of Viewable slot 0xcc (table 0xe1ba92, 9
; entries, InitializeSuna), element 0 "MspReGrpScreen"; classes:
; AcFuncEditSw (44 B, id 0x01600020).
; -----------------------------------------------------------------------------
NakaNode_Accomp11_Widget02:
	.incbin "includes/generated/naka_msp_recording.bin", 0x4B4, 0x2C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp11_Widget03
; NakaNode_Accomp11_Widget03  --  naka_msp_recording +0x4e0..+0x50c (ROM 0xe1b038..0xe1b064), 44 bytes
; Widget records of element 2 of Viewable slot 0xcc (table 0xe1ba92, 9
; entries, InitializeSuna), element 0 "MspReGrpScreen"; classes:
; StringBox (38 B, id 0x01600037).
; -----------------------------------------------------------------------------
NakaNode_Accomp11_Widget03:
	.incbin "includes/generated/naka_msp_recording.bin", 0x4E0, 0x2C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp11_Widget04
; NakaNode_Accomp11_Widget04  --  naka_msp_recording +0x50c..+0x594 (ROM 0xe1b064..0xe1b0ec), 136 bytes
; Widget records of element 3 of Viewable slot 0xcc (table 0xe1ba92, 9
; entries, InitializeSuna), element 0 "MspReGrpScreen"; classes:
; AcGridBox (74 B, id 0x01600056).
; -----------------------------------------------------------------------------
NakaNode_Accomp11_Widget04:
	.incbin "includes/generated/naka_msp_recording.bin", 0x50C, 0x88
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp11_Widget05
; NakaNode_Accomp11_Widget05  --  naka_msp_recording +0x594..+0x5bc (ROM 0xe1b0ec..0xe1b114), 40 bytes
; Widget records of element 4 of Viewable slot 0xcc (table 0xe1ba92, 9
; entries, InitializeSuna), element 0 "MspReGrpScreen"; classes:
; AcIndexEditSw (40 B, id 0x0160001f).
; -----------------------------------------------------------------------------
NakaNode_Accomp11_Widget05:
	.incbin "includes/generated/naka_msp_recording.bin", 0x594, 0x28
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp11_Widget06
; NakaNode_Accomp11_Widget06  --  naka_msp_recording +0x5bc..+0x5e6 (ROM 0xe1b114..0xe1b13e), 42 bytes
; Widget records of element 5 of Viewable slot 0xcc (table 0xe1ba92, 9
; entries, InitializeSuna), element 0 "MspReGrpScreen"; classes:
; AcIndexWideES (42 B, id 0x01600022).
; -----------------------------------------------------------------------------
NakaNode_Accomp11_Widget06:
	.incbin "includes/generated/naka_msp_recording.bin", 0x5BC, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp11_Widget07
; NakaNode_Accomp11_Widget07  --  naka_msp_recording +0x5e6..+0x610 (ROM 0xe1b13e..0xe1b168), 42 bytes
; Widget records of element 6 of Viewable slot 0xcc (table 0xe1ba92, 9
; entries, InitializeSuna), element 0 "MspReGrpScreen"; classes:
; AcIndexWideES (42 B, id 0x01600022).
; -----------------------------------------------------------------------------
NakaNode_Accomp11_Widget07:
	.incbin "includes/generated/naka_msp_recording.bin", 0x5E6, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp11_Widget08
; NakaNode_Accomp11_Widget08  --  naka_msp_recording +0x610..+0x634 (ROM 0xe1b168..0xe1b18c), 36 bytes
; Widget records of element 7 of Viewable slot 0xcc (table 0xe1ba92, 9
; entries, InitializeSuna), element 0 "MspReGrpScreen"; classes:
; PsRgpSetBnkBox (36 B, id 0x01640017).
; -----------------------------------------------------------------------------
NakaNode_Accomp11_Widget08:
	.incbin "includes/generated/naka_msp_recording.bin", 0x610, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp11_Widget09
; NakaNode_Accomp11_Widget09  --  naka_msp_recording +0x634..+0x64e (ROM 0xe1b18c..0xe1b1a6), 26 bytes
; Widget records of element 8 of Viewable slot 0xcc (table 0xe1ba92, 9
; entries, InitializeSuna), element 0 "MspReGrpScreen"; classes:
; IvShowHide (26 B, id 0x01600064).
; -----------------------------------------------------------------------------
NakaNode_Accomp11_Widget09:
	.incbin "includes/generated/naka_msp_recording.bin", 0x634, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp12_Widget01
; NakaNode_Accomp12_Widget01  --  naka_msp_recording +0x64e..+0x688 (ROM 0xe1b1a6..0xe1b1e0), 58 bytes
; Widget records of element 0 of Viewable slot 0xdc (table 0xe1baba, 8
; entries, InitializeSuna), element 0 "SndArgrScreen"; classes:
; TtlScreen (42 B, id 0x01600034).
; -----------------------------------------------------------------------------
NakaNode_Accomp12_Widget01:
	.incbin "includes/generated/naka_msp_recording.bin", 0x64E, 0x3A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp12_Widget02
; NakaNode_Accomp12_Widget02  --  naka_msp_recording +0x688..+0x6ba (ROM 0xe1b1e0..0xe1b212), 50 bytes
; Widget records of element 1 of Viewable slot 0xdc (table 0xe1baba, 8
; entries, InitializeSuna), element 0 "SndArgrScreen"; classes:
; StringBox (38 B, id 0x01600037).
; -----------------------------------------------------------------------------
NakaNode_Accomp12_Widget02:
	.incbin "includes/generated/naka_msp_recording.bin", 0x688, 0x32
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp12_Widget03
; NakaNode_Accomp12_Widget03  --  naka_msp_recording +0x6ba..+0x6de (ROM 0xe1b212..0xe1b236), 36 bytes
; Widget records of element 2 of Viewable slot 0xdc (table 0xe1baba, 8
; entries, InitializeSuna), element 0 "SndArgrScreen"; classes:
; PsCmpCpFVariBox (36 B, id 0x01640013).
; -----------------------------------------------------------------------------
NakaNode_Accomp12_Widget03:
	.incbin "includes/generated/naka_msp_recording.bin", 0x6BA, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp12_Widget04
; NakaNode_Accomp12_Widget04  --  naka_msp_recording +0x6de..+0x6f8 (ROM 0xe1b236..0xe1b250), 26 bytes
; Widget records of element 3 of Viewable slot 0xdc (table 0xe1baba, 8
; entries, InitializeSuna), element 0 "SndArgrScreen"; classes:
; IvExitMode (26 B, id 0x01600048).
; -----------------------------------------------------------------------------
NakaNode_Accomp12_Widget04:
	.incbin "includes/generated/naka_msp_recording.bin", 0x6DE, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp12_Widget05
; NakaNode_Accomp12_Widget05  --  naka_msp_recording +0x6f8..+0x712 (ROM 0xe1b250..0xe1b26a), 26 bytes
; Widget records of element 4 of Viewable slot 0xdc (table 0xe1baba, 8
; entries, InitializeSuna), element 0 "SndArgrScreen"; classes:
; IvShowHide (26 B, id 0x01600064).
; -----------------------------------------------------------------------------
NakaNode_Accomp12_Widget05:
	.incbin "includes/generated/naka_msp_recording.bin", 0x6F8, 0x1A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp12_Widget06
; NakaNode_Accomp12_Widget06  --  naka_msp_recording +0x712..+0x7aa (ROM 0xe1b26a..0xe1b302), 152 bytes
; Widget records of element 5 of Viewable slot 0xdc (table 0xe1baba, 8
; entries, InitializeSuna), element 0 "SndArgrScreen"; classes:
; AcSndArgGridBox (74 B, id 0x01640020).
; -----------------------------------------------------------------------------
NakaNode_Accomp12_Widget06:
	.incbin "includes/generated/naka_msp_recording.bin", 0x712, 0x98
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp12_Widget07
; NakaNode_Accomp12_Widget07  --  naka_msp_recording +0x7aa..+0x7d4 (ROM 0xe1b302..0xe1b32c), 42 bytes
; Widget records of element 6 of Viewable slot 0xdc (table 0xe1baba, 8
; entries, InitializeSuna), element 0 "SndArgrScreen"; classes:
; AcIndexWideES (42 B, id 0x01600022).
; -----------------------------------------------------------------------------
NakaNode_Accomp12_Widget07:
	.incbin "includes/generated/naka_msp_recording.bin", 0x7AA, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp12_Widget08
; NakaNode_Accomp12_Widget08  --  naka_msp_recording +0x7d4..+0x7fe (ROM 0xe1b32c..0xe1b356), 42 bytes
; Widget records of element 7 of Viewable slot 0xdc (table 0xe1baba, 8
; entries, InitializeSuna), element 0 "SndArgrScreen"; classes:
; AcLanguageText (42 B, id 0x01600066).
; -----------------------------------------------------------------------------
NakaNode_Accomp12_Widget08:
	.incbin "includes/generated/naka_msp_recording.bin", 0x7D4, 0x2A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp13_Widget01
; NakaNode_Accomp13_Widget01  --  naka_msp_recording +0x7fe..+0x838 (ROM 0xe1b356..0xe1b390), 58 bytes
; Widget records of element 0 of Viewable slot 0xed (table 0xe1bade, 6
; entries, InitializeSuna), element 0 "ApcSelScreen"; classes: TtlScreen
; (42 B, id 0x01600034).
; -----------------------------------------------------------------------------
NakaNode_Accomp13_Widget01:
	.incbin "includes/generated/naka_msp_recording.bin", 0x7FE, 0x3A
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp13_Widget02
; NakaNode_Accomp13_Widget02  --  naka_msp_recording +0x838..+0x878 (ROM 0xe1b390..0xe1b3d0), 64 bytes
; Widget records of element 1 of Viewable slot 0xed (table 0xe1bade, 6
; entries, InitializeSuna), element 0 "ApcSelScreen"; classes:
; AcApcMdBox (52 B, id 0x0164000e).
; -----------------------------------------------------------------------------
NakaNode_Accomp13_Widget02:
	.incbin "includes/generated/naka_msp_recording.bin", 0x838, 0x40
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp13_Widget03
; NakaNode_Accomp13_Widget03  --  naka_msp_recording +0x878..+0x8b6 (ROM 0xe1b3d0..0xe1b40e), 62 bytes
; Widget records of element 2 of Viewable slot 0xed (table 0xe1bade, 6
; entries, InitializeSuna), element 0 "ApcSelScreen"; classes:
; AcApcMdBox (52 B, id 0x0164000e).
; -----------------------------------------------------------------------------
NakaNode_Accomp13_Widget03:
	.incbin "includes/generated/naka_msp_recording.bin", 0x878, 0x3E
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp13_Widget04
; NakaNode_Accomp13_Widget04  --  naka_msp_recording +0x8b6..+0x8f2 (ROM 0xe1b40e..0xe1b44a), 60 bytes
; Widget records of element 3 of Viewable slot 0xed (table 0xe1bade, 6
; entries, InitializeSuna), element 0 "ApcSelScreen"; classes:
; AcApcMdBox (52 B, id 0x0164000e).
; -----------------------------------------------------------------------------
NakaNode_Accomp13_Widget04:
	.incbin "includes/generated/naka_msp_recording.bin", 0x8B6, 0x3C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp13_Widget05
; NakaNode_Accomp13_Widget05  --  naka_msp_recording +0x8f2..+0x93e (ROM 0xe1b44a..0xe1b496), 76 bytes
; Widget records of element 4 of Viewable slot 0xed (table 0xe1bade, 6
; entries, InitializeSuna), element 0 "ApcSelScreen"; classes:
; AcApcToggle (48 B, id 0x0164001f).
; -----------------------------------------------------------------------------
NakaNode_Accomp13_Widget05:
	.incbin "includes/generated/naka_msp_recording.bin", 0x8F2, 0x4C
; -----------------------------------------------------------------------------
; [nakarest_retype] NakaNode_Accomp13_Widget06
; NakaNode_Accomp13_Widget06  --  naka_msp_recording +0x93e..+0x98a (ROM 0xe1b496..0xe1b4e2), 76 bytes
; Widget records of element 5 of Viewable slot 0xed (table 0xe1bade, 6
; entries, InitializeSuna), element 0 "ApcSelScreen"; classes:
; AcApcToggle (48 B, id 0x0164001f).
; -----------------------------------------------------------------------------
NakaNode_Accomp13_Widget06:
	.incbin "includes/generated/naka_msp_recording.bin", 0x93E, 0x4C
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_msp_recording+0x98a
; naka_msp_recording+0x98a  --  naka_msp_recording +0x98a..+0x99a (ROM 0xe1b4e2..0xe1b4f2), 16 bytes
; The table itself: Viewable slot 0x10 (table 0xe1b4e2, 3 entries,
; InitializeSuna) -- 3 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_msp_recording.bin", 0x98A, 0x10
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_msp_recording+0x99a
; naka_msp_recording+0x99a  --  naka_msp_recording +0x99a..+0x9be (ROM 0xe1b4f2..0xe1b516), 36 bytes
; The table itself: Viewable slot 0x11 (table 0xe1b4f2, 8 entries,
; InitializeSuna) -- 8 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_msp_recording.bin", 0x99A, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_msp_recording+0x9be
; naka_msp_recording+0x9be  --  naka_msp_recording +0x9be..+0x9de (ROM 0xe1b516..0xe1b536), 32 bytes
; The table itself: Viewable slot 0x12 (table 0xe1b516, 7 entries,
; InitializeSuna) -- 7 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_msp_recording.bin", 0x9BE, 0x20
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_msp_recording+0x9de
; naka_msp_recording+0x9de  --  naka_msp_recording +0x9de..+0x9f2 (ROM 0xe1b536..0xe1b54a), 20 bytes
; The table itself: Viewable slot 0x13 (table 0xe1b536, 4 entries,
; InitializeSuna) -- 4 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_msp_recording.bin", 0x9DE, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_msp_recording+0x9f2
; naka_msp_recording+0x9f2  --  naka_msp_recording +0x9f2..+0xa06 (ROM 0xe1b54a..0xe1b55e), 20 bytes
; The table itself: Viewable slot 0x14 (table 0xe1b54a, 4 entries,
; InitializeSuna) -- 4 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_msp_recording.bin", 0x9F2, 0x14
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_msp_recording+0xa06
; naka_msp_recording+0xa06  --  naka_msp_recording +0xa06..+0xa2a (ROM 0xe1b55e..0xe1b582), 36 bytes
; The table itself: Viewable slot 0x15 (table 0xe1b55e, 8 entries,
; InitializeSuna) -- 8 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_msp_recording.bin", 0xA06, 0x24
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_msp_recording+0xa2a
; naka_msp_recording+0xa2a  --  naka_msp_recording +0xa2a..+0xa4a (ROM 0xe1b582..0xe1b5a2), 32 bytes
; The table itself: Viewable slot 0x16 (table 0xe1b582, 7 entries,
; InitializeSuna) -- 7 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_msp_recording.bin", 0xA2A, 0x20
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_msp_recording+0xa4a
; naka_msp_recording+0xa4a  --  naka_msp_recording +0xa4a..+0xa96 (ROM 0xe1b5a2..0xe1b5ee), 76 bytes
; The table itself: Viewable slot 0xb0 (table 0xe1b5a2, 18 entries,
; InitializeSuna) -- 18 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_msp_recording.bin", 0xA4A, 0x4C
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_msp_recording+0xa96
; naka_msp_recording+0xa96  --  naka_msp_recording +0xa96..+0xaca (ROM 0xe1b5ee..0xe1b622), 52 bytes
; The table itself: Viewable slot 0xb1 (table 0xe1b5ee, 12 entries,
; InitializeSuna) -- 12 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_msp_recording.bin", 0xA96, 0x34
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_msp_recording+0xaca
; naka_msp_recording+0xaca  --  naka_msp_recording +0xaca..+0xb26 (ROM 0xe1b622..0xe1b67e), 92 bytes
; The table itself: Viewable slot 0xb2 (table 0xe1b622, 22 entries,
; InitializeSuna) -- 22 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_msp_recording.bin", 0xACA, 0x5C
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_msp_recording+0xb26
; naka_msp_recording+0xb26  --  naka_msp_recording +0xb26..+0xb3e (ROM 0xe1b67e..0xe1b696), 24 bytes
; The table itself: Viewable slot 0xb3 (table 0xe1b67e, 5 entries,
; InitializeSuna) -- 5 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_msp_recording.bin", 0xB26, 0x18
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_msp_recording+0xb3e
; naka_msp_recording+0xb3e  --  naka_msp_recording +0xb3e..+0xb8a (ROM 0xe1b696..0xe1b6e2), 76 bytes
; The table itself: Viewable slot 0xb4 (table 0xe1b696, 18 entries,
; InitializeSuna) -- 18 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_msp_recording.bin", 0xB3E, 0x4C
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_msp_recording+0xb8a
; naka_msp_recording+0xb8a  --  naka_msp_recording +0xb8a..+0xc0a (ROM 0xe1b6e2..0xe1b762), 128 bytes
; The table itself: Viewable slot 0xb5 (table 0xe1b6e2, 31 entries,
; InitializeSuna) -- 31 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_msp_recording.bin", 0xB8A, 0x80
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_msp_recording+0xc0a
; naka_msp_recording+0xc0a  --  naka_msp_recording +0xc0a..+0xc12 (ROM 0xe1b762..0xe1b76a), 8 bytes
; The table itself: Viewable slot 0xb6 (table 0xe1b762, 1 entries,
; InitializeSuna) -- 1 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_msp_recording.bin", 0xC0A, 0x8
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_msp_recording+0xc12
; naka_msp_recording+0xc12  --  naka_msp_recording +0xc12..+0xc2e (ROM 0xe1b76a..0xe1b786), 28 bytes
; The table itself: Viewable slot 0xb7 (table 0xe1b76a, 6 entries,
; InitializeSuna) -- 6 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_msp_recording.bin", 0xC12, 0x1C
; -----------------------------------------------------------------------------
; [nakarest_retype] naka_msp_recording+0xc2e
; naka_msp_recording+0xc2e  --  naka_msp_recording +0xc2e..+0xc96 (ROM 0xe1b786..0xe1b7ee), 104 bytes
; The table itself: Viewable slot 0xb8 (table 0xe1b786, 33 entries,
; InitializeSuna) -- 33 x u32 entry pointers.
; -----------------------------------------------------------------------------
	.incbin "includes/generated/naka_msp_recording.bin", 0xC2E, 0x68
; External label offsets within the binary blob above.
; Referenced from naka_screen_dispatch.s (widget pointer tables).
