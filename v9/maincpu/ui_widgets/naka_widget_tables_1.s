
; NAKA Widget Pointer Tables Part 1 (13 widgets, 12878 bytes)
; Source: maincpu/ui_widgets/naka_widget_tables_1.c (C struct with named fields)
; -----------------------------------------------------------------------------
; NakaWidget_Perf3RhythmSel_Tail -- the last 8 bytes of widget record
; NakaWidget_Perf3RhythmSel (a 42-byte PsWideToggle, element 9 of Viewable slot
; 0xe3), split across the blob boundary: direct_play_medley_screens.s holds its
; first 34 bytes.  Then the record's two captions: its +30 word points at
; NakaWidget_Perf3RhythmSel_StrOn, its +26 word (stroff, by the other
; PsWideToggle records) at NakaWidget_Perf3RhythmSel_StrOff.
; -----------------------------------------------------------------------------
NakaWidget_Perf3RhythmSel_Tail:	.incbin "includes/generated/naka_widget_tables_1.bin", 0x0, 0x8
NakaWidget_Perf3RhythmSel_StrOn:	.incbin "includes/generated/naka_widget_tables_1.bin", 0x8, 0x8
NakaWidget_Perf3RhythmSel_StrOff:	.incbin "includes/generated/naka_widget_tables_1.bin", 0x10, 0x8
; -----------------------------------------------------------------------------
; [naka_s_headers] NakaHdr_Perf2MeasureBoxData
; NakaHdr_Perf2MeasureBoxData -- widget record, entry 10 of
; Yoko_ViewTable_0E3 (registered by InitializeYoko (v10/v9 0xf29e6d, v7
; 0xf29e43), sequencer/sequencer_ui.s:65): it begins with class id
; 0x1600029 = IvMainEditSw, whose descriptor gives record_size 26.
;
; Typed in naka_widget_tables_1.c as uint8_t
; NakaHdr_Perf2MeasureBoxData[26].
; -----------------------------------------------------------------------------
NakaHdr_Perf2MeasureBoxData:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x18, 0x1A
; -----------------------------------------------------------------------------
; [naka_s_headers] NakaHdr_Perf2FileListData
; NakaHdr_Perf2FileListData -- widget record, entry 11 of
; Yoko_ViewTable_0E3 (registered by InitializeYoko (v10/v9 0xf29e6d, v7
; 0xf29e43), sequencer/sequencer_ui.s:65): it begins with class id
; 0x1670014 = AcDemoMedleyDispBox, whose descriptor gives record_size
; 36.
;
; Typed in naka_widget_tables_1.c as uint8_t
; NakaHdr_Perf2FileListData[36].
; -----------------------------------------------------------------------------
NakaHdr_Perf2FileListData:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x32, 0x24
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ViewTable_06F
; Yoko_ViewTable_06F -- object table: InitializeYoko (v10/v9 0xf29e6d,
; v7 0xf29e43) (sequencer/sequencer_ui.s:21) registers it with
; `RegObjTabl 0x1600010, ViewableProc, 43, 0xe240ac, 0x6f` -- class
; 0x1600010 (ViewableProc), 43 objects, base id 0x6f. Entries: pointers
; to widget records then a 0 terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ViewTable_06F[44].
; -----------------------------------------------------------------------------
Yoko_ViewTable_06F:	.incbin "includes/generated/naka_widget_tables_1.bin", 0x56, 0x4
NakaWidgetPtrTbl_SmfDp:	.incbin "includes/generated/naka_widget_tables_1.bin", 0x5A, 0xAC
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ViewTable_070
; Yoko_ViewTable_070 -- object table: InitializeYoko (v10/v9 0xf29e6d,
; v7 0xf29e43) (sequencer/sequencer_ui.s:23) registers it with
; `RegObjTabl 0x1600010, ViewableProc, 12, 0xe2415c, 0x70` -- class
; 0x1600010 (ViewableProc), 12 objects, base id 0x70. Entries: pointers
; to widget records then a 0 terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ViewTable_070[13].
; -----------------------------------------------------------------------------
Yoko_ViewTable_070:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x106, 0x34
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ViewTable_071
; Yoko_ViewTable_071 -- object table: InitializeYoko (v10/v9 0xf29e6d,
; v7 0xf29e43) (sequencer/sequencer_ui.s:25) registers it with
; `RegObjTabl 0x1600010, ViewableProc, 11, 0xe24190, 0x71` -- class
; 0x1600010 (ViewableProc), 11 objects, base id 0x71. Entries: pointers
; to widget records then a 0 terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ViewTable_071[12].
; -----------------------------------------------------------------------------
Yoko_ViewTable_071:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x13A, 0x30
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ViewTable_072
; Yoko_ViewTable_072 -- object table: InitializeYoko (v10/v9 0xf29e6d,
; v7 0xf29e43) (sequencer/sequencer_ui.s:27) registers it with
; `RegObjTabl 0x1600010, ViewableProc, 7, 0xe241c0, 0x72` -- class
; 0x1600010 (ViewableProc), 7 objects, base id 0x72. Entries: pointers
; to widget records then a 0 terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ViewTable_072[8].
; -----------------------------------------------------------------------------
Yoko_ViewTable_072:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x16A, 0x20
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ViewTable_073
; Yoko_ViewTable_073 -- object table: InitializeYoko (v10/v9 0xf29e6d,
; v7 0xf29e43) (sequencer/sequencer_ui.s:29) registers it with
; `RegObjTabl 0x1600010, ViewableProc, 16, 0xe241e0, 0x73` -- class
; 0x1600010 (ViewableProc), 16 objects, base id 0x73. Entries: pointers
; to widget records then a 0 terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ViewTable_073[17].
; -----------------------------------------------------------------------------
Yoko_ViewTable_073:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x18A, 0x44
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ViewTable_074
; Yoko_ViewTable_074 -- object table: InitializeYoko (v10/v9 0xf29e6d,
; v7 0xf29e43) (sequencer/sequencer_ui.s:31) registers it with
; `RegObjTabl 0x1600010, ViewableProc, 15, 0xe24224, 0x74` -- class
; 0x1600010 (ViewableProc), 15 objects, base id 0x74. Entries: pointers
; to widget records then a 0 terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ViewTable_074[16].
; -----------------------------------------------------------------------------
Yoko_ViewTable_074:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x1CE, 0x40
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ViewTable_075
; Yoko_ViewTable_075 -- object table: InitializeYoko (v10/v9 0xf29e6d,
; v7 0xf29e43) (sequencer/sequencer_ui.s:33) registers it with
; `RegObjTabl 0x1600010, ViewableProc, 13, 0xe24264, 0x75` -- class
; 0x1600010 (ViewableProc), 13 objects, base id 0x75. Entries: pointers
; to widget records then a 0 terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ViewTable_075[14].
; -----------------------------------------------------------------------------
Yoko_ViewTable_075:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x20E, 0x38
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ViewTable_076
; Yoko_ViewTable_076 -- object table: InitializeYoko (v10/v9 0xf29e6d,
; v7 0xf29e43) (sequencer/sequencer_ui.s:35) registers it with
; `RegObjTabl 0x1600010, ViewableProc, 8, 0xe2429c, 0x76` -- class
; 0x1600010 (ViewableProc), 8 objects, base id 0x76. Entries: pointers
; to widget records then a 0 terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ViewTable_076[9].
; -----------------------------------------------------------------------------
Yoko_ViewTable_076:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x246, 0x24
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ViewTable_078
; Yoko_ViewTable_078 -- object table: InitializeYoko (v10/v9 0xf29e6d,
; v7 0xf29e43) (sequencer/sequencer_ui.s:37) registers it with
; `RegObjTabl 0x1600010, ViewableProc, 30, 0xe242c0, 0x78` -- class
; 0x1600010 (ViewableProc), 30 objects, base id 0x78. Entries: pointers
; to widget records then a 0 terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ViewTable_078[31].
; -----------------------------------------------------------------------------
Yoko_ViewTable_078:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x26A, 0x7C
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ViewTable_07A
; Yoko_ViewTable_07A -- object table: InitializeYoko (v10/v9 0xf29e6d,
; v7 0xf29e43) (sequencer/sequencer_ui.s:39) registers it with
; `RegObjTabl 0x1600010, ViewableProc, 12, 0xe2433c, 0x7a` -- class
; 0x1600010 (ViewableProc), 12 objects, base id 0x7a. Entries: pointers
; to widget records then a 0 terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ViewTable_07A[13].
; -----------------------------------------------------------------------------
Yoko_ViewTable_07A:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2E6, 0x34
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ViewTable_089
; Yoko_ViewTable_089 -- object table: InitializeYoko (v10/v9 0xf29e6d,
; v7 0xf29e43) (sequencer/sequencer_ui.s:41) registers it with
; `RegObjTabl 0x1600010, ViewableProc, 5, 0xe24370, 0x89` -- class
; 0x1600010 (ViewableProc), 5 objects, base id 0x89. Entries: pointers
; to widget records then a 0 terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ViewTable_089[6].
; -----------------------------------------------------------------------------
Yoko_ViewTable_089:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x31A, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ViewTable_08A
; Yoko_ViewTable_08A -- object table: InitializeYoko (v10/v9 0xf29e6d,
; v7 0xf29e43) (sequencer/sequencer_ui.s:43) registers it with
; `RegObjTabl 0x1600010, ViewableProc, 1, 0xe24388, 0x8a` -- class
; 0x1600010 (ViewableProc), 1 objects, base id 0x8a. Entries: pointers
; to widget records then a 0 terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ViewTable_08A[2].
; -----------------------------------------------------------------------------
Yoko_ViewTable_08A:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x332, 0x8
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ViewTable_08B
; Yoko_ViewTable_08B -- object table: InitializeYoko (v10/v9 0xf29e6d,
; v7 0xf29e43) (sequencer/sequencer_ui.s:45) registers it with
; `RegObjTabl 0x1600010, ViewableProc, 22, 0xe24390, 0x8b` -- class
; 0x1600010 (ViewableProc), 22 objects, base id 0x8b. Entries: pointers
; to widget records then a 0 terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ViewTable_08B[23].
; -----------------------------------------------------------------------------
Yoko_ViewTable_08B:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x33A, 0x5C
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ViewTable_08C
; Yoko_ViewTable_08C -- object table: InitializeYoko (v10/v9 0xf29e6d,
; v7 0xf29e43) (sequencer/sequencer_ui.s:47) registers it with
; `RegObjTabl 0x1600010, ViewableProc, 28, 0xe243ec, 0x8c` -- class
; 0x1600010 (ViewableProc), 28 objects, base id 0x8c. Entries: pointers
; to widget records then a 0 terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ViewTable_08C[29].
; -----------------------------------------------------------------------------
Yoko_ViewTable_08C:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x396, 0x74
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ViewTable_08E
; Yoko_ViewTable_08E -- object table: InitializeYoko (v10/v9 0xf29e6d,
; v7 0xf29e43) (sequencer/sequencer_ui.s:49) registers it with
; `RegObjTabl 0x1600010, ViewableProc, 5, 0xe24460, 0x8e` -- class
; 0x1600010 (ViewableProc), 5 objects, base id 0x8e. Entries: pointers
; to widget records then a 0 terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ViewTable_08E[6].
; -----------------------------------------------------------------------------
Yoko_ViewTable_08E:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x40A, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ViewTable_08F
; Yoko_ViewTable_08F -- object table: InitializeYoko (v10/v9 0xf29e6d,
; v7 0xf29e43) (sequencer/sequencer_ui.s:51) registers it with
; `RegObjTabl 0x1600010, ViewableProc, 6, 0xe24478, 0x8f` -- class
; 0x1600010 (ViewableProc), 6 objects, base id 0x8f. Entries: pointers
; to widget records then a 0 terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ViewTable_08F[7].
; -----------------------------------------------------------------------------
Yoko_ViewTable_08F:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x422, 0x1C
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ViewTable_092
; Yoko_ViewTable_092 -- object table: InitializeYoko (v10/v9 0xf29e6d,
; v7 0xf29e43) (sequencer/sequencer_ui.s:53) registers it with
; `RegObjTabl 0x1600010, ViewableProc, 4, 0xe24494, 0x92` -- class
; 0x1600010 (ViewableProc), 4 objects, base id 0x92. Entries: pointers
; to widget records then a 0 terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ViewTable_092[5].
; -----------------------------------------------------------------------------
Yoko_ViewTable_092:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x43E, 0x14
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ViewTable_0A7
; Yoko_ViewTable_0A7 -- object table: InitializeYoko (v10/v9 0xf29e6d,
; v7 0xf29e43) (sequencer/sequencer_ui.s:55) registers it with
; `RegObjTabl 0x1600010, ViewableProc, 0, 0xe244a8, 0xa7` -- class
; 0x1600010 (ViewableProc), 0 objects, base id 0xa7. Entries: pointers
; to widget records then a 0 terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ViewTable_0A7[1].
; -----------------------------------------------------------------------------
Yoko_ViewTable_0A7:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x452, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ViewTable_0A9
; Yoko_ViewTable_0A9 -- object table: InitializeYoko (v10/v9 0xf29e6d,
; v7 0xf29e43) (sequencer/sequencer_ui.s:57) registers it with
; `RegObjTabl 0x1600010, ViewableProc, 6, 0xe244ac, 0xa9` -- class
; 0x1600010 (ViewableProc), 6 objects, base id 0xa9. Entries: pointers
; to widget records then a 0 terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ViewTable_0A9[7].
; -----------------------------------------------------------------------------
Yoko_ViewTable_0A9:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x456, 0x1C
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ViewTable_0E0
; Yoko_ViewTable_0E0 -- object table: InitializeYoko (v10/v9 0xf29e6d,
; v7 0xf29e43) (sequencer/sequencer_ui.s:59) registers it with
; `RegObjTabl 0x1600010, ViewableProc, 4, 0xe244c8, 0xe0` -- class
; 0x1600010 (ViewableProc), 4 objects, base id 0xe0. Entries: pointers
; to widget records then a 0 terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ViewTable_0E0[5].
; -----------------------------------------------------------------------------
Yoko_ViewTable_0E0:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x472, 0x14
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ViewTable_0E1
; Yoko_ViewTable_0E1 -- object table: InitializeYoko (v10/v9 0xf29e6d,
; v7 0xf29e43) (sequencer/sequencer_ui.s:61) registers it with
; `RegObjTabl 0x1600010, ViewableProc, 12, 0xe244dc, 0xe1` -- class
; 0x1600010 (ViewableProc), 12 objects, base id 0xe1. Entries: pointers
; to widget records then a 0 terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ViewTable_0E1[13].
; -----------------------------------------------------------------------------
Yoko_ViewTable_0E1:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x486, 0x34
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ViewTable_0E2
; Yoko_ViewTable_0E2 -- object table: InitializeYoko (v10/v9 0xf29e6d,
; v7 0xf29e43) (sequencer/sequencer_ui.s:63) registers it with
; `RegObjTabl 0x1600010, ViewableProc, 12, 0xe24510, 0xe2` -- class
; 0x1600010 (ViewableProc), 12 objects, base id 0xe2. Entries: pointers
; to widget records then a 0 terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ViewTable_0E2[13].
; -----------------------------------------------------------------------------
Yoko_ViewTable_0E2:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x4BA, 0x34
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ViewTable_0E3
; Yoko_ViewTable_0E3 -- object table: InitializeYoko (v10/v9 0xf29e6d,
; v7 0xf29e43) (sequencer/sequencer_ui.s:65) registers it with
; `RegObjTabl 0x1600010, ViewableProc, 12, 0xe24544, 0xe3` -- class
; 0x1600010 (ViewableProc), 12 objects, base id 0xe3. Entries: pointers
; to widget records then a 0 terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ViewTable_0E3[13].
; -----------------------------------------------------------------------------
Yoko_ViewTable_0E3:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x4EE, 0x34
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNameTable_36F
; Yoko_ResNameTable_36F -- object table: InitializeYoko (v10/v9
; 0xf29e6d, v7 0xf29e43) (sequencer/sequencer_ui.s:22) registers it with
; `RegObjTabl 0x160000f, ResNameProc, 43, 0xe24578, 0x36f` -- class
; 0x160000f (ResNameProc), 43 objects, base id 0x36f. Entries: pointers
; to resource-name strings then a "" terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ResNameTable_36F[44].
; -----------------------------------------------------------------------------
Yoko_ResNameTable_36F:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x522, 0xB0
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNames_36F
; Yoko_ResNames_36F -- the strings Yoko_ResNameTable_36F points at: 44
; NUL-terminated names (0xff pads to even length), 160 bytes.
;
; Typed in naka_widget_tables_1.c as char Yoko_ResNames_36F[160].
; -----------------------------------------------------------------------------
Yoko_ResNames_36F:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x5D2, 0xA0
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNameTable_370
; Yoko_ResNameTable_370 -- object table: InitializeYoko (v10/v9
; 0xf29e6d, v7 0xf29e43) (sequencer/sequencer_ui.s:24) registers it with
; `RegObjTabl 0x160000f, ResNameProc, 12, 0xe246c8, 0x370` -- class
; 0x160000f (ResNameProc), 12 objects, base id 0x370. Entries: pointers
; to resource-name strings then a "" terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ResNameTable_370[13].
; -----------------------------------------------------------------------------
Yoko_ResNameTable_370:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x672, 0x34
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNames_370
; Yoko_ResNames_370 -- the strings Yoko_ResNameTable_370 points at: 13
; NUL-terminated names (0xff pads to even length), 50 bytes.
;
; Typed in naka_widget_tables_1.c as char Yoko_ResNames_370[50].
; -----------------------------------------------------------------------------
Yoko_ResNames_370:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x6A6, 0x32
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNameTable_371
; Yoko_ResNameTable_371 -- object table: InitializeYoko (v10/v9
; 0xf29e6d, v7 0xf29e43) (sequencer/sequencer_ui.s:26) registers it with
; `RegObjTabl 0x160000f, ResNameProc, 11, 0xe2472e, 0x371` -- class
; 0x160000f (ResNameProc), 11 objects, base id 0x371. Entries: pointers
; to resource-name strings then a "" terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ResNameTable_371[12].
; -----------------------------------------------------------------------------
Yoko_ResNameTable_371:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x6D8, 0x30
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNames_371
; Yoko_ResNames_371 -- the strings Yoko_ResNameTable_371 points at: 12
; NUL-terminated names (0xff pads to even length), 42 bytes.
;
; Typed in naka_widget_tables_1.c as char Yoko_ResNames_371[42].
; -----------------------------------------------------------------------------
Yoko_ResNames_371:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x708, 0x2A
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNameTable_372
; Yoko_ResNameTable_372 -- object table: InitializeYoko (v10/v9
; 0xf29e6d, v7 0xf29e43) (sequencer/sequencer_ui.s:28) registers it with
; `RegObjTabl 0x160000f, ResNameProc, 7, 0xe24788, 0x372` -- class
; 0x160000f (ResNameProc), 7 objects, base id 0x372. Entries: pointers
; to resource-name strings then a "" terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ResNameTable_372[8].
; -----------------------------------------------------------------------------
Yoko_ResNameTable_372:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x732, 0x20
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNames_372
; Yoko_ResNames_372 -- the strings Yoko_ResNameTable_372 points at: 8
; NUL-terminated names (0xff pads to even length), 34 bytes.
;
; Typed in naka_widget_tables_1.c as char Yoko_ResNames_372[34].
; -----------------------------------------------------------------------------
Yoko_ResNames_372:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x752, 0x22
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNameTable_373
; Yoko_ResNameTable_373 -- object table: InitializeYoko (v10/v9
; 0xf29e6d, v7 0xf29e43) (sequencer/sequencer_ui.s:30) registers it with
; `RegObjTabl 0x160000f, ResNameProc, 16, 0xe247ca, 0x373` -- class
; 0x160000f (ResNameProc), 16 objects, base id 0x373. Entries: pointers
; to resource-name strings then a "" terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ResNameTable_373[17].
; -----------------------------------------------------------------------------
Yoko_ResNameTable_373:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x774, 0x44
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNames_373
; Yoko_ResNames_373 -- the strings Yoko_ResNameTable_373 points at: 17
; NUL-terminated names (0xff pads to even length), 54 bytes.
;
; Typed in naka_widget_tables_1.c as char Yoko_ResNames_373[54].
; -----------------------------------------------------------------------------
Yoko_ResNames_373:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x7B8, 0x36
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNameTable_374
; Yoko_ResNameTable_374 -- object table: InitializeYoko (v10/v9
; 0xf29e6d, v7 0xf29e43) (sequencer/sequencer_ui.s:32) registers it with
; `RegObjTabl 0x160000f, ResNameProc, 15, 0xe24844, 0x374` -- class
; 0x160000f (ResNameProc), 15 objects, base id 0x374. Entries: pointers
; to resource-name strings then a "" terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ResNameTable_374[16].
; -----------------------------------------------------------------------------
Yoko_ResNameTable_374:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x7EE, 0x40
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNames_374
; Yoko_ResNames_374 -- the strings Yoko_ResNameTable_374 points at: 16
; NUL-terminated names (0xff pads to even length), 72 bytes.
;
; Typed in naka_widget_tables_1.c as char Yoko_ResNames_374[72].
; -----------------------------------------------------------------------------
Yoko_ResNames_374:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x82E, 0x48
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNameTable_375
; Yoko_ResNameTable_375 -- object table: InitializeYoko (v10/v9
; 0xf29e6d, v7 0xf29e43) (sequencer/sequencer_ui.s:34) registers it with
; `RegObjTabl 0x160000f, ResNameProc, 13, 0xe248cc, 0x375` -- class
; 0x160000f (ResNameProc), 13 objects, base id 0x375. Entries: pointers
; to resource-name strings then a "" terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ResNameTable_375[14].
; -----------------------------------------------------------------------------
Yoko_ResNameTable_375:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x876, 0x38
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNames_375
; Yoko_ResNames_375 -- the strings Yoko_ResNameTable_375 points at: 14
; NUL-terminated names (0xff pads to even length), 54 bytes.
;
; Typed in naka_widget_tables_1.c as char Yoko_ResNames_375[54].
; -----------------------------------------------------------------------------
Yoko_ResNames_375:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x8AE, 0x36
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNameTable_376
; Yoko_ResNameTable_376 -- object table: InitializeYoko (v10/v9
; 0xf29e6d, v7 0xf29e43) (sequencer/sequencer_ui.s:36) registers it with
; `RegObjTabl 0x160000f, ResNameProc, 8, 0xe2493a, 0x376` -- class
; 0x160000f (ResNameProc), 8 objects, base id 0x376. Entries: pointers
; to resource-name strings then a "" terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ResNameTable_376[9].
; -----------------------------------------------------------------------------
Yoko_ResNameTable_376:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x8E4, 0x24
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNames_376
; Yoko_ResNames_376 -- the strings Yoko_ResNameTable_376 points at: 9
; NUL-terminated names (0xff pads to even length), 30 bytes.
;
; Typed in naka_widget_tables_1.c as char Yoko_ResNames_376[30].
; -----------------------------------------------------------------------------
Yoko_ResNames_376:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x908, 0x1E
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNameTable_378
; Yoko_ResNameTable_378 -- object table: InitializeYoko (v10/v9
; 0xf29e6d, v7 0xf29e43) (sequencer/sequencer_ui.s:38) registers it with
; `RegObjTabl 0x160000f, ResNameProc, 30, 0xe2497c, 0x378` -- class
; 0x160000f (ResNameProc), 30 objects, base id 0x378. Entries: pointers
; to resource-name strings then a "" terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ResNameTable_378[31].
; -----------------------------------------------------------------------------
Yoko_ResNameTable_378:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x926, 0x7C
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNames_378
; Yoko_ResNames_378 -- the strings Yoko_ResNameTable_378 points at: 31
; NUL-terminated names (0xff pads to even length), 70 bytes.
;
; Typed in naka_widget_tables_1.c as char Yoko_ResNames_378[70].
; -----------------------------------------------------------------------------
Yoko_ResNames_378:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x9A2, 0x46
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNameTable_37A
; Yoko_ResNameTable_37A -- object table: InitializeYoko (v10/v9
; 0xf29e6d, v7 0xf29e43) (sequencer/sequencer_ui.s:40) registers it with
; `RegObjTabl 0x160000f, ResNameProc, 12, 0xe24a3e, 0x37a` -- class
; 0x160000f (ResNameProc), 12 objects, base id 0x37a. Entries: pointers
; to resource-name strings then a "" terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ResNameTable_37A[13].
; -----------------------------------------------------------------------------
Yoko_ResNameTable_37A:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x9E8, 0x34
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNames_37A
; Yoko_ResNames_37A -- the strings Yoko_ResNameTable_37A points at: 13
; NUL-terminated names (0xff pads to even length), 34 bytes.
;
; Typed in naka_widget_tables_1.c as char Yoko_ResNames_37A[34].
; -----------------------------------------------------------------------------
Yoko_ResNames_37A:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0xA1C, 0x22
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNameTable_389
; Yoko_ResNameTable_389 -- object table: InitializeYoko (v10/v9
; 0xf29e6d, v7 0xf29e43) (sequencer/sequencer_ui.s:42) registers it with
; `RegObjTabl 0x160000f, ResNameProc, 5, 0xe24a94, 0x389` -- class
; 0x160000f (ResNameProc), 5 objects, base id 0x389. Entries: pointers
; to resource-name strings then a "" terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ResNameTable_389[6].
; -----------------------------------------------------------------------------
Yoko_ResNameTable_389:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0xA3E, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNames_389
; Yoko_ResNames_389 -- the strings Yoko_ResNameTable_389 points at: 6
; NUL-terminated names (0xff pads to even length), 18 bytes.
;
; Typed in naka_widget_tables_1.c as char Yoko_ResNames_389[18].
; -----------------------------------------------------------------------------
Yoko_ResNames_389:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0xA56, 0x12
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNameTable_38A
; Yoko_ResNameTable_38A -- object table: InitializeYoko (v10/v9
; 0xf29e6d, v7 0xf29e43) (sequencer/sequencer_ui.s:44) registers it with
; `RegObjTabl 0x160000f, ResNameProc, 1, 0xe24abe, 0x38a` -- class
; 0x160000f (ResNameProc), 1 objects, base id 0x38a. Entries: pointers
; to resource-name strings then a "" terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ResNameTable_38A[2].
; -----------------------------------------------------------------------------
Yoko_ResNameTable_38A:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0xA68, 0x8
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNames_38A
; Yoko_ResNames_38A -- the strings Yoko_ResNameTable_38A points at: 2
; NUL-terminated names (0xff pads to even length), 4 bytes.
;
; Typed in naka_widget_tables_1.c as char Yoko_ResNames_38A[4].
; -----------------------------------------------------------------------------
Yoko_ResNames_38A:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0xA70, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNameTable_38B
; Yoko_ResNameTable_38B -- object table: InitializeYoko (v10/v9
; 0xf29e6d, v7 0xf29e43) (sequencer/sequencer_ui.s:46) registers it with
; `RegObjTabl 0x160000f, ResNameProc, 22, 0xe24aca, 0x38b` -- class
; 0x160000f (ResNameProc), 22 objects, base id 0x38b. Entries: pointers
; to resource-name strings then a "" terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ResNameTable_38B[23].
; -----------------------------------------------------------------------------
Yoko_ResNameTable_38B:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0xA74, 0x5C
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNames_38B
; Yoko_ResNames_38B -- the strings Yoko_ResNameTable_38B points at: 23
; NUL-terminated names (0xff pads to even length), 90 bytes.
;
; Typed in naka_widget_tables_1.c as char Yoko_ResNames_38B[90].
; -----------------------------------------------------------------------------
Yoko_ResNames_38B:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0xAD0, 0x5A
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNameTable_38C
; Yoko_ResNameTable_38C -- object table: InitializeYoko (v10/v9
; 0xf29e6d, v7 0xf29e43) (sequencer/sequencer_ui.s:48) registers it with
; `RegObjTabl 0x160000f, ResNameProc, 28, 0xe24b80, 0x38c` -- class
; 0x160000f (ResNameProc), 28 objects, base id 0x38c. Entries: pointers
; to resource-name strings then a "" terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ResNameTable_38C[29].
; -----------------------------------------------------------------------------
Yoko_ResNameTable_38C:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0xB2A, 0x74
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNames_38C
; Yoko_ResNames_38C -- the strings Yoko_ResNameTable_38C points at: 29
; NUL-terminated names (0xff pads to even length), 124 bytes.
;
; Typed in naka_widget_tables_1.c as char Yoko_ResNames_38C[124].
; -----------------------------------------------------------------------------
Yoko_ResNames_38C:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0xB9E, 0x7C
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNameTable_38E
; Yoko_ResNameTable_38E -- object table: InitializeYoko (v10/v9
; 0xf29e6d, v7 0xf29e43) (sequencer/sequencer_ui.s:50) registers it with
; `RegObjTabl 0x160000f, ResNameProc, 5, 0xe24c70, 0x38e` -- class
; 0x160000f (ResNameProc), 5 objects, base id 0x38e. Entries: pointers
; to resource-name strings then a "" terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ResNameTable_38E[6].
; -----------------------------------------------------------------------------
Yoko_ResNameTable_38E:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0xC1A, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNames_38E
; Yoko_ResNames_38E -- the strings Yoko_ResNameTable_38E points at: 6
; NUL-terminated names (0xff pads to even length), 20 bytes.
;
; Typed in naka_widget_tables_1.c as char Yoko_ResNames_38E[20].
; -----------------------------------------------------------------------------
Yoko_ResNames_38E:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0xC32, 0x14
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNameTable_38F
; Yoko_ResNameTable_38F -- object table: InitializeYoko (v10/v9
; 0xf29e6d, v7 0xf29e43) (sequencer/sequencer_ui.s:52) registers it with
; `RegObjTabl 0x160000f, ResNameProc, 6, 0xe24c9c, 0x38f` -- class
; 0x160000f (ResNameProc), 6 objects, base id 0x38f. Entries: pointers
; to resource-name strings then a "" terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ResNameTable_38F[7].
; -----------------------------------------------------------------------------
Yoko_ResNameTable_38F:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0xC46, 0x1C
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNames_38F
; Yoko_ResNames_38F -- the strings Yoko_ResNameTable_38F points at: 7
; NUL-terminated names (0xff pads to even length), 22 bytes.
;
; Typed in naka_widget_tables_1.c as char Yoko_ResNames_38F[22].
; -----------------------------------------------------------------------------
Yoko_ResNames_38F:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0xC62, 0x16
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNameTable_392
; Yoko_ResNameTable_392 -- object table: InitializeYoko (v10/v9
; 0xf29e6d, v7 0xf29e43) (sequencer/sequencer_ui.s:54) registers it with
; `RegObjTabl 0x160000f, ResNameProc, 4, 0xe24cce, 0x392` -- class
; 0x160000f (ResNameProc), 4 objects, base id 0x392. Entries: pointers
; to resource-name strings then a "" terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ResNameTable_392[5].
; -----------------------------------------------------------------------------
Yoko_ResNameTable_392:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0xC78, 0x14
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNames_392
; Yoko_ResNames_392 -- the strings Yoko_ResNameTable_392 points at: 5
; NUL-terminated names (0xff pads to even length), 22 bytes.
;
; Typed in naka_widget_tables_1.c as char Yoko_ResNames_392[22].
; -----------------------------------------------------------------------------
Yoko_ResNames_392:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0xC8C, 0x16
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNameTable_3A7
; Yoko_ResNameTable_3A7 -- object table: InitializeYoko (v10/v9
; 0xf29e6d, v7 0xf29e43) (sequencer/sequencer_ui.s:56) registers it with
; `RegObjTabl 0x160000f, ResNameProc, 0, 0xe24cf8, 0x3a7` -- class
; 0x160000f (ResNameProc), 0 objects, base id 0x3a7. Entries: pointers
; to resource-name strings then a "" terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ResNameTable_3A7[1].
; -----------------------------------------------------------------------------
Yoko_ResNameTable_3A7:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0xCA2, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNames_3A7
; Yoko_ResNames_3A7 -- the strings Yoko_ResNameTable_3A7 points at: 1
; NUL-terminated names (0xff pads to even length), 2 bytes.
;
; Typed in naka_widget_tables_1.c as char Yoko_ResNames_3A7[2].
; -----------------------------------------------------------------------------
Yoko_ResNames_3A7:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0xCA6, 0x2
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNameTable_3A9
; Yoko_ResNameTable_3A9 -- object table: InitializeYoko (v10/v9
; 0xf29e6d, v7 0xf29e43) (sequencer/sequencer_ui.s:58) registers it with
; `RegObjTabl 0x160000f, ResNameProc, 6, 0xe24cfe, 0x3a9` -- class
; 0x160000f (ResNameProc), 6 objects, base id 0x3a9. Entries: pointers
; to resource-name strings then a "" terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ResNameTable_3A9[7].
; -----------------------------------------------------------------------------
Yoko_ResNameTable_3A9:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0xCA8, 0x1C
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNames_3A9
; Yoko_ResNames_3A9 -- the strings Yoko_ResNameTable_3A9 points at: 7
; NUL-terminated names (0xff pads to even length), 24 bytes.
;
; Typed in naka_widget_tables_1.c as char Yoko_ResNames_3A9[24].
; -----------------------------------------------------------------------------
Yoko_ResNames_3A9:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0xCC4, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNameTable_3E0
; Yoko_ResNameTable_3E0 -- object table: InitializeYoko (v10/v9
; 0xf29e6d, v7 0xf29e43) (sequencer/sequencer_ui.s:60) registers it with
; `RegObjTabl 0x160000f, ResNameProc, 4, 0xe24d32, 0x3e0` -- class
; 0x160000f (ResNameProc), 4 objects, base id 0x3e0. Entries: pointers
; to resource-name strings then a "" terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ResNameTable_3E0[5].
; -----------------------------------------------------------------------------
Yoko_ResNameTable_3E0:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0xCDC, 0x14
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNames_3E0
; Yoko_ResNames_3E0 -- the strings Yoko_ResNameTable_3E0 points at: 5
; NUL-terminated names (0xff pads to even length), 18 bytes.
;
; Typed in naka_widget_tables_1.c as char Yoko_ResNames_3E0[18].
; -----------------------------------------------------------------------------
Yoko_ResNames_3E0:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0xCF0, 0x12
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNameTable_3E1
; Yoko_ResNameTable_3E1 -- object table: InitializeYoko (v10/v9
; 0xf29e6d, v7 0xf29e43) (sequencer/sequencer_ui.s:62) registers it with
; `RegObjTabl 0x160000f, ResNameProc, 12, 0xe24d58, 0x3e1` -- class
; 0x160000f (ResNameProc), 12 objects, base id 0x3e1. Entries: pointers
; to resource-name strings then a "" terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ResNameTable_3E1[13].
; -----------------------------------------------------------------------------
Yoko_ResNameTable_3E1:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0xD02, 0x34
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNames_3E1
; Yoko_ResNames_3E1 -- the strings Yoko_ResNameTable_3E1 points at: 13
; NUL-terminated names (0xff pads to even length), 90 bytes.
;
; Typed in naka_widget_tables_1.c as char Yoko_ResNames_3E1[90].
; -----------------------------------------------------------------------------
Yoko_ResNames_3E1:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0xD36, 0x5A
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNameTable_3E2
; Yoko_ResNameTable_3E2 -- object table: InitializeYoko (v10/v9
; 0xf29e6d, v7 0xf29e43) (sequencer/sequencer_ui.s:64) registers it with
; `RegObjTabl 0x160000f, ResNameProc, 12, 0xe24de6, 0x3e2` -- class
; 0x160000f (ResNameProc), 12 objects, base id 0x3e2. Entries: pointers
; to resource-name strings then a "" terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ResNameTable_3E2[13].
; -----------------------------------------------------------------------------
Yoko_ResNameTable_3E2:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0xD90, 0x34
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNames_3E2
; Yoko_ResNames_3E2 -- the strings Yoko_ResNameTable_3E2 points at: 13
; NUL-terminated names (0xff pads to even length), 94 bytes.
;
; Typed in naka_widget_tables_1.c as char Yoko_ResNames_3E2[94].
; -----------------------------------------------------------------------------
Yoko_ResNames_3E2:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0xDC4, 0x5E
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNameTable_3E3
; Yoko_ResNameTable_3E3 -- object table: InitializeYoko (v10/v9
; 0xf29e6d, v7 0xf29e43) (sequencer/sequencer_ui.s:66) registers it with
; `RegObjTabl 0x160000f, ResNameProc, 12, 0xe24e78, 0x3e3` -- class
; 0x160000f (ResNameProc), 12 objects, base id 0x3e3. Entries: pointers
; to resource-name strings then a "" terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Yoko_ResNameTable_3E3[13].
; -----------------------------------------------------------------------------
Yoko_ResNameTable_3E3:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0xE22, 0x34
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNames_3E3
; Yoko_ResNames_3E3 -- the strings Yoko_ResNameTable_3E3 points at: 13
; NUL-terminated names (0xff pads to even length), 100 bytes.
;
; Typed in naka_widget_tables_1.c as char Yoko_ResNames_3E3[100].
; -----------------------------------------------------------------------------
Yoko_ResNames_3E3:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0xE56, 0x64
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_ResNames_3E3_Strings
; Yoko_ResNames_3E3_Strings -- 306 bytes of NUL-terminated strings after
; Yoko_ResNames_3E3; that code reaches: the labels below name each string after the routine that
; reaches it first (scripts/converters/split_blobs_at_far_pointers.py).
;
; Typed in naka_widget_tables_1.c as char
; Yoko_ResNames_3E3_Strings[306].
; Readers (claims_lint.py unread-claims, 2026-10-02): InitializeYoko (0xF2A66F, pushw far pointer);
;   InitializeYoko (0xF2A68B, pushw far pointer); InitializeYoko (0xF2A6A7, pushw far pointer); and
;   22 more
; -----------------------------------------------------------------------------
Yoko_ResNames_3E3_Strings:		.incbin "includes/generated/naka_widget_tables_1.bin", 0xEBA, 0xC
InitializeYoko_Str_MD_DEMO:		.incbin "includes/generated/naka_widget_tables_1.bin", 0xEC6, 0x8	; "MD_DEMO"
InitializeYoko_Str_TT_DPSMF:		.incbin "includes/generated/naka_widget_tables_1.bin", 0xECE, 0xA	; "TT_DPSMF"
InitializeYoko_Str_TT_DPDOC:		.incbin "includes/generated/naka_widget_tables_1.bin", 0xED8, 0xA	; "TT_DPDOC"
InitializeYoko_Str_TT_DPPD:		.incbin "includes/generated/naka_widget_tables_1.bin", 0xEE2, 0x8	; "TT_DPPD"
InitializeYoko_Str_TT_DPSMFLYR:		.incbin "includes/generated/naka_widget_tables_1.bin", 0xEEA, 0xC	; "TT_DPSMFLYR"
InitializeYoko_Str_TT_DPMDLYSMF:	.incbin "includes/generated/naka_widget_tables_1.bin", 0xEF6, 0xE	; "TT_DPMDLYSMF"
InitializeYoko_Str_TT_DPMDLYDOC:	.incbin "includes/generated/naka_widget_tables_1.bin", 0xF04, 0xE	; "TT_DPMDLYDOC"
InitializeYoko_Str_TT_DPMDLYPD:		.incbin "includes/generated/naka_widget_tables_1.bin", 0xF12, 0xC	; "TT_DPMDLYPD"
InitializeYoko_Str_TT_DPMDLYSMFLYR:	.incbin "includes/generated/naka_widget_tables_1.bin", 0xF1E, 0x10	; "TT_DPMDLYSMFLYR"
InitializeYoko_Str_TT_DKMDLYPLY:	.incbin "includes/generated/naka_widget_tables_1.bin", 0xF2E, 0xE	; "TT_DKMDLYPLY"
InitializeYoko_Str_TT_SQMDLYPLY:	.incbin "includes/generated/naka_widget_tables_1.bin", 0xF3C, 0xE	; "TT_SQMDLYPLY"
InitializeYoko_Str_TT_SQTRSEL:		.incbin "includes/generated/naka_widget_tables_1.bin", 0xF4A, 0xC	; "TT_SQTRSEL"
InitializeYoko_Str_TT_SQSTEP:		.incbin "includes/generated/naka_widget_tables_1.bin", 0xF56, 0xA	; "TT_SQSTEP"
InitializeYoko_Str_TT_SQTRAS:		.incbin "includes/generated/naka_widget_tables_1.bin", 0xF60, 0xA	; "TT_SQTRAS"
InitializeYoko_Str_TT_SQTRASPS:		.incbin "includes/generated/naka_widget_tables_1.bin", 0xF6A, 0xC	; "TT_SQTRASPS"
InitializeYoko_Str_TT_SQSNGSEL:		.incbin "includes/generated/naka_widget_tables_1.bin", 0xF76, 0xC	; "TT_SQSNGSEL"
InitializeYoko_Str_TT_SQSNGNAME:	.incbin "includes/generated/naka_widget_tables_1.bin", 0xF82, 0xE	; "TT_SQSNGNAME"
InitializeYoko_Str_TT_SQAFTSET:		.incbin "includes/generated/naka_widget_tables_1.bin", 0xF90, 0xC	; "TT_SQAFTSET"
InitializeYoko_Str_TT_SQEASYNAME:	.incbin "includes/generated/naka_widget_tables_1.bin", 0xF9C, 0xE	; "TT_SQEASYNAME"
InitializeYoko_Str_TT_SQSTEPBAL:	.incbin "includes/generated/naka_widget_tables_1.bin", 0xFAA, 0xE	; "TT_SQSTEPBAL"
InitializeYoko_Str_TT_DEMOMENU:		.incbin "includes/generated/naka_widget_tables_1.bin", 0xFB8, 0xC	; "TT_DEMOMENU"
InitializeYoko_Str_TT_DEMOSTYLE:	.incbin "includes/generated/naka_widget_tables_1.bin", 0xFC4, 0xE	; "TT_DEMOSTYLE"
InitializeYoko_Str_TT_DEMOSOUND:	.incbin "includes/generated/naka_widget_tables_1.bin", 0xFD2, 0xE	; "TT_DEMOSOUND"
InitializeYoko_Str_TT_DEMORHY:		.incbin "includes/generated/naka_widget_tables_1.bin", 0xFE0, 0xC	; "TT_DEMORHY"
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_MainFuncTable_147
; Yoko_MainFuncTable_147 -- object table: InitializeYoko (v10/v9
; 0xf29e6d, v7 0xf29e43) (sequencer/sequencer_ui.s:19) registers it with
; `RegObjTabl 0x1600003, MainFunctionProc, 31, 0xe25042, 0x147` -- class
; 0x1600003 (MainFunctionProc), 31 objects, base id 0x147. Entries:
; procedure addresses then a 0 terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t
; Yoko_MainFuncTable_147[32].
; -----------------------------------------------------------------------------
Yoko_MainFuncTable_147:
	.long SeqSongNameFunc
	.long SeqSongMemoryFunc
	.long CDlikeSwTtlFunc
	.long SqAftSetTtlFunc
	.long SqSngSelTtlFunc
	.long SqSngNameTtlFunc
	.long SqTrAsTtlFunc
	.long SqTrAsSureFunc
	.long SqTrAsPsTtlFunc
	.long SqTrAsPsSureFunc
	.long SqMdlyPlyTtlFunc
	.long DkMdlyPlyTtlFunc
	.long DpMdlyDocTtlFunc
	.long DpMdlyPdTtlFunc
	.long DpMdlySmfTtlFunc
	.long DpMdlySmfLyrTtlFunc
	.long DpDocTtlFunc
	.long DpPdTtlFunc
	.long DpSmfTtlFunc
	.long DpSmfLyrTtlFunc
	.long SeqStepModeFunc
	.long SqTrSelTtlFunc
	.long SqStepTtlFunc
	.long DemoModeFunc
	.long DemoMenuTtlFunc
	.long DemoStyleTtlFunc
	.long DemoSoundTtlFunc
	.long DemoRhyTtlFunc
	.long MiddleFuncCall
	.long NameGetFuncCall
	.long ApPlaySyori
	.long 0x00000000
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_MainFuncNameTable_447
; Yoko_MainFuncNameTable_447 -- object table: InitializeYoko (v10/v9
; 0xf29e6d, v7 0xf29e43) (sequencer/sequencer_ui.s:20) registers it with
; `RegObjTabl 0x1600003, MainFunctionProc, 31, 0xe250c2, 0x447` -- class
; 0x1600003 (MainFunctionProc), 31 objects, base id 0x447. Entries:
; pointers to the procedures' name strings then a "" terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t
; Yoko_MainFuncNameTable_447[32].
; -----------------------------------------------------------------------------
Yoko_MainFuncNameTable_447:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x106C, 0x80
; -----------------------------------------------------------------------------
; [naka_s_headers] Yoko_MainFuncNames_447
; Yoko_MainFuncNames_447 -- the strings Yoko_MainFuncNameTable_447
; points at: 32 NUL-terminated names (0xff pads to even length), 502
; bytes.
;
; Typed in naka_widget_tables_1.c as char Yoko_MainFuncNames_447[502].
; -----------------------------------------------------------------------------
Yoko_MainFuncNames_447:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x10EC, 0x1F6
; -----------------------------------------------------------------------------
; [naka_s_headers] PartSelLangCheck_Strings
; PartSelLangCheck_Strings -- the 6 strings PartSelLangCheck_PtrTable
; points at (NUL-terminated, 0xff pad to even length), 620 bytes.
;
; Typed in naka_widget_tables_1.c as char PartSelLangCheck_Strings[620].
; -----------------------------------------------------------------------------
PartSelLangCheck_Strings:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x12E2, 0x26C
; -----------------------------------------------------------------------------
; [naka_s_headers] AfterLangCheck_Strings
; AfterLangCheck_Strings -- the 6 strings AfterLangCheck_PtrTable points
; at (NUL-terminated, 0xff pad to even length), 378 bytes.
;
; Typed in naka_widget_tables_1.c as char AfterLangCheck_Strings[378].
; -----------------------------------------------------------------------------
AfterLangCheck_Strings:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x154E, 0x17A
; -----------------------------------------------------------------------------
; [naka_s_headers] TrAsPreLangCheck_Strings
; TrAsPreLangCheck_Strings -- the 6 strings TrAsPreLangCheck_PtrTable
; points at (NUL-terminated, 0xff pad to even length), 358 bytes.
;
; Typed in naka_widget_tables_1.c as char TrAsPreLangCheck_Strings[358].
; -----------------------------------------------------------------------------
TrAsPreLangCheck_Strings:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x16C8, 0x166
; -----------------------------------------------------------------------------
; [naka_s_headers] AtentionLangCheck_Strings
; AtentionLangCheck_Strings -- the 6 strings AtentionLangCheck_PtrTable
; points at (NUL-terminated, 0xff pad to even length), 70 bytes.
;
; Typed in naka_widget_tables_1.c as char AtentionLangCheck_Strings[70].
; -----------------------------------------------------------------------------
AtentionLangCheck_Strings:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x182E, 0x46
; -----------------------------------------------------------------------------
; [naka_s_headers] AreYouSureLangCheck_Strings
; AreYouSureLangCheck_Strings -- the 6 strings
; AreYouSureLangCheck_PtrTable points at (NUL-terminated, 0xff pad to
; even length), 104 bytes.
;
; Typed in naka_widget_tables_1.c as char
; AreYouSureLangCheck_Strings[104].
; -----------------------------------------------------------------------------
AreYouSureLangCheck_Strings:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x1874, 0x68
; -----------------------------------------------------------------------------
; [naka_s_headers] GmOnSureLangCheck_Strings
; GmOnSureLangCheck_Strings -- the 6 strings GmOnSureLangCheck_PtrTable
; points at (NUL-terminated, 0xff pad to even length), 596 bytes.
;
; Typed in naka_widget_tables_1.c as char
; GmOnSureLangCheck_Strings[596].
; -----------------------------------------------------------------------------
GmOnSureLangCheck_Strings:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x18DC, 0x254
; -----------------------------------------------------------------------------
; [naka_s_headers] GmOffSureLangCheck_Strings
; GmOffSureLangCheck_Strings -- the 6 strings
; GmOffSureLangCheck_PtrTable points at (NUL-terminated, 0xff pad to
; even length), 714 bytes.
;
; Typed in naka_widget_tables_1.c as char
; GmOffSureLangCheck_Strings[714].
; -----------------------------------------------------------------------------
GmOffSureLangCheck_Strings:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x1B30, 0x2CA
; -----------------------------------------------------------------------------
; [naka_s_headers] TrAsSureLangCheck_PtrTable
; TrAsSureLangCheck_PtrTable -- 6 u32 addresses, read by
; TrAsSureLangCheck (v10/v9 0xf2a9a3, v7 0xf2a979) (`lda xbc,
; (TrAsSureLangCheck_PtrTable:24)`).
;
; Typed in naka_widget_tables_1.c as uint32_t
; TrAsSureLangCheck_PtrTable[6].
; -----------------------------------------------------------------------------
TrAsSureLangCheck_PtrTable:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x1DFA, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] TrAsSureLangCheck_Strings
; TrAsSureLangCheck_Strings -- the 6 strings TrAsSureLangCheck_PtrTable
; points at (NUL-terminated, 0xff pad to even length), 528 bytes.
;
; Typed in naka_widget_tables_1.c as char
; TrAsSureLangCheck_Strings[528].
; -----------------------------------------------------------------------------
TrAsSureLangCheck_Strings:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x1E12, 0x210
; -----------------------------------------------------------------------------
; [naka_s_headers] PartSelLangCheck_PtrTable
; PartSelLangCheck_PtrTable -- 6 u32 addresses, read by PartSelLangCheck
; (v10/v9 0xf2a92c, v7 0xf2a902) (`lda xhl,
; (PartSelLangCheck_PtrTable:24)`).
;
; Typed in naka_widget_tables_1.c as uint32_t
; PartSelLangCheck_PtrTable[6].
; -----------------------------------------------------------------------------
PartSelLangCheck_PtrTable:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2022, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] AfterLangCheck_PtrTable
; AfterLangCheck_PtrTable -- 6 u32 addresses, read by AfterLangCheck
; (v10/v9 0xf2a93d, v7 0xf2a913) (`lda xhl,
; (AfterLangCheck_PtrTable:24)`).
;
; Typed in naka_widget_tables_1.c as uint32_t
; AfterLangCheck_PtrTable[6].
; -----------------------------------------------------------------------------
AfterLangCheck_PtrTable:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x203A, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] TrAsPreLangCheck_PtrTable
; TrAsPreLangCheck_PtrTable -- 6 u32 addresses, read by TrAsPreLangCheck
; (v10/v9 0xf2a94e, v7 0xf2a924) (`lda xhl,
; (TrAsPreLangCheck_PtrTable:24)`).
;
; Typed in naka_widget_tables_1.c as uint32_t
; TrAsPreLangCheck_PtrTable[6].
; -----------------------------------------------------------------------------
TrAsPreLangCheck_PtrTable:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2052, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] AtentionLangCheck_PtrTable
; AtentionLangCheck_PtrTable -- 6 u32 addresses, read by
; AtentionLangCheck (v10/v9 0xf2a95f, v7 0xf2a935) (`lda xhl,
; (AtentionLangCheck_PtrTable:24)`).
;
; Typed in naka_widget_tables_1.c as uint32_t
; AtentionLangCheck_PtrTable[6].
; -----------------------------------------------------------------------------
AtentionLangCheck_PtrTable:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x206A, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] AreYouSureLangCheck_PtrTable
; AreYouSureLangCheck_PtrTable -- 6 u32 addresses, read by
; AreYouSureLangCheck (v10/v9 0xf2a970, v7 0xf2a946) (`lda xhl,
; (AreYouSureLangCheck_PtrTable:24)`).
;
; Typed in naka_widget_tables_1.c as uint32_t
; AreYouSureLangCheck_PtrTable[6].
; -----------------------------------------------------------------------------
AreYouSureLangCheck_PtrTable:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2082, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] GmOnSureLangCheck_PtrTable
; GmOnSureLangCheck_PtrTable -- 6 u32 addresses, read by
; GmOnSureLangCheck (v10/v9 0xf2a981, v7 0xf2a957) (`lda xhl,
; (GmOnSureLangCheck_PtrTable:24)`).
;
; Typed in naka_widget_tables_1.c as uint32_t
; GmOnSureLangCheck_PtrTable[6].
; -----------------------------------------------------------------------------
GmOnSureLangCheck_PtrTable:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x209A, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] GmOffSureLangCheck_PtrTable
; GmOffSureLangCheck_PtrTable -- 6 u32 addresses, read by
; GmOffSureLangCheck (v10/v9 0xf2a992, v7 0xf2a968) (`lda xhl,
; (GmOffSureLangCheck_PtrTable:24)`).
;
; Typed in naka_widget_tables_1.c as uint32_t
; GmOffSureLangCheck_PtrTable[6].
; -----------------------------------------------------------------------------
GmOffSureLangCheck_PtrTable:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x20B2, 0x18
; -----------------------------------------------------------------------------
; [naka_s_headers] TrAsSureLangCheck_PtrTable_2
; TrAsSureLangCheck_PtrTable_2 -- 20 u32 addresses, read by
; TrAsSureLangCheck (v10/v9 0xf2a9a3, v7 0xf2a979) (`lda xbc,
; (TrAsSureLangCheck_PtrTable_2:24)`).
;
; Typed in naka_widget_tables_1.c as uint32_t
; TrAsSureLangCheck_PtrTable_2[20].
; -----------------------------------------------------------------------------
TrAsSureLangCheck_PtrTable_2:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x20CA, 0x50
; -----------------------------------------------------------------------------
; [naka_s_headers] TrAsSureLangCheck_Strings_2
; TrAsSureLangCheck_Strings_2 -- the 20 strings
; TrAsSureLangCheck_PtrTable_2 points at (NUL-terminated, 0xff pad to
; even length), 138 bytes.
;
; Typed in naka_widget_tables_1.c as char
; TrAsSureLangCheck_Strings_2[138].
; -----------------------------------------------------------------------------
TrAsSureLangCheck_Strings_2:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x211A, 0x8A
; -----------------------------------------------------------------------------
; [naka_s_headers] NakaT1_Str021A4
; NakaT1_Str021A4 -- 208 bytes of NUL-terminated strings after the
; string block before it; that code reaches: the labels below name each string after the routine
; that reaches it first (scripts/converters/split_blobs_at_far_pointers.py).
;
; Typed in naka_widget_tables_1.c as char NakaT1_Str021A4[208].
; Readers (claims_lint.py unread-claims, 2026-10-02): LyricsBoxFunc_CopyString (0xF2B256, pushw far
;   pointer); MeasureBoxFunc_DrawMeasure (0xF2B6B5, pushw far pointer); AcDiskFileName_HandleEventF
;   (0xF2B732, pushw far pointer); and 7 more
; -----------------------------------------------------------------------------
NakaT1_Str021A4:				.incbin "includes/generated/naka_widget_tables_1.bin", 0x21A4, 0x6
MeasureBoxFunc_DrawMeasure_Str_MEASURE_Fmt3d:	.incbin "includes/generated/naka_widget_tables_1.bin", 0x21AA, 0xE	; "MEASURE = %3d"
AcDiskFileName_HandleEventF_Str_Blank25:	.incbin "includes/generated/naka_widget_tables_1.bin", 0x21B8, 0x1A	; "                         "
AcSmfFileName_HandleEventF_Str_Blank25:		.incbin "includes/generated/naka_widget_tables_1.bin", 0x21D2, 0x1A	; "                         "
AcSmfSongName_HandleEventF_Str_Blank25:		.incbin "includes/generated/naka_widget_tables_1.bin", 0x21EC, 0x1A	; "                         "
AcDocSongName_HandleEventF_Str_Blank25:		.incbin "includes/generated/naka_widget_tables_1.bin", 0x2206, 0x1A	; "                         "
AcDocFileNo_HandleEventF_Str_Blank25:		.incbin "includes/generated/naka_widget_tables_1.bin", 0x2220, 0x1A	; "                         "
AcPDSongName_HandleEventF_Str_Blank25:		.incbin "includes/generated/naka_widget_tables_1.bin", 0x223A, 0x1A	; "                         "
AcPDFileNo_HandleEventF_Str_Blank25:		.incbin "includes/generated/naka_widget_tables_1.bin", 0x2254, 0x1A	; "                         "
IvNamingExit_CopyString_Str_ExMD:		.incbin "includes/generated/naka_widget_tables_1.bin", 0x226E, 0x6	; "ExMD"
; -----------------------------------------------------------------------------
; [naka_s_headers] TrAsGridChk_Part1_SendAudio_PtrTable
; TrAsGridChk_Part1_SendAudio_PtrTable -- 20 u32 addresses, read by
; TrAsGridChk_Part1_SendAudio (v10/v9 0xf2c798, v7 0xf2c76e) (`ld xbc,
; TrAsGridChk_Part1_SendAudio_PtrTable`).
;
; Typed in naka_widget_tables_1.c as uint32_t
; TrAsGridChk_Part1_SendAudio_PtrTable[20].
; -----------------------------------------------------------------------------
TrAsGridChk_Part1_SendAudio_PtrTable:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2274, 0x50
; -----------------------------------------------------------------------------
; [naka_s_headers] TrAsGridChk_Part1_SendAudio_Strings
; TrAsGridChk_Part1_SendAudio_Strings -- the 20 strings
; TrAsGridChk_Part1_SendAudio_PtrTable points at (NUL-terminated, 0xff
; pad to even length), 200 bytes.
;
; Typed in naka_widget_tables_1.c as char
; TrAsGridChk_Part1_SendAudio_Strings[200].
; -----------------------------------------------------------------------------
TrAsGridChk_Part1_SendAudio_Strings:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x22C4, 0xC8
; -----------------------------------------------------------------------------
; [naka_s_headers] TrAsGrid_GetDirectionLabel_Str
; TrAsGrid_GetDirectionLabel_Str -- NUL-terminated string(s), 44 bytes,
; used by TrAsGrid_GetDirectionLabel (v10/v9 0xf2c2ff, v7 0xf2c2d5) (`ld
; xwa, TrAsGrid_GetDirectionLabel_Str`).
;
; Typed in naka_widget_tables_1.c as char
; TrAsGrid_GetDirectionLabel_Str[44].
; -----------------------------------------------------------------------------
TrAsGrid_GetDirectionLabel_Str:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x238C, 0x2C
; -----------------------------------------------------------------------------
; [naka_s_headers] TrAsGrid_DirectionLabel2_Str
; TrAsGrid_DirectionLabel2_Str -- NUL-terminated string(s), 44 bytes,
; used by TrAsGrid_DirectionLabel2 (v10/v9 0xf2c30c, v7 0xf2c2e2) (`ld
; xwa, TrAsGrid_DirectionLabel2_Str`).
;
; Typed in naka_widget_tables_1.c as char
; TrAsGrid_DirectionLabel2_Str[44].
; -----------------------------------------------------------------------------
TrAsGrid_DirectionLabel2_Str:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x23B8, 0x2C
; -----------------------------------------------------------------------------
; [naka_s_headers] AcTrAsGridBoxProc_CaseTable
; AcTrAsGridBoxProc_CaseTable -- jump table of a compiled `switch` in
; AcTrAsGridBoxProc (v10/v9 0xf2bf1e, v7 0xf2bef4) (`add xbc,
; AcTrAsGridBoxProc_CaseTable`): 7 u16 case offsets from
; TrAsGrid_HandleInit.
;
; Typed in naka_widget_tables_1.c as uint16_t
; AcTrAsGridBoxProc_CaseTable[7].
; -----------------------------------------------------------------------------
AcTrAsGridBoxProc_CaseTable:
	.short	AcTrAsGridBoxProc_OnIndexswUp - TrAsGrid_HandleInit
	.short	AcTrAsGridBoxProc_OnIndexswDown - TrAsGrid_HandleInit
	.short	AcTrAsGridBoxProc_OnIndexswUp - TrAsGrid_HandleInit
	.short	AcTrAsGridBoxProc_OnIndexswDown - TrAsGrid_HandleInit
	.short	TrAsGrid_PassThrough - TrAsGrid_HandleInit
	.short	TrAsGrid_HandleSelectEvent - TrAsGrid_HandleInit
	.short	TrAsGrid_HandleSelectEvent - TrAsGrid_HandleInit
; -----------------------------------------------------------------------------
; [naka_s_headers] TrAsGrid_LookupTable_Table
; TrAsGrid_LookupTable_Table -- read by TrAsGrid_LookupTable (v10/v9
; 0xf2c40b, v7 0xf2c3e1) (`lda xbc,
; (TrAsGrid_LookupTable_Table:24)`). 32 bytes to the next object; the
; layout beyond that access is not established.
;
; Typed in naka_widget_tables_1.c as uint8_t
; TrAsGrid_LookupTable_Table[32].
; -----------------------------------------------------------------------------
TrAsGrid_LookupTable_Table:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x23F2, 0x20
; -----------------------------------------------------------------------------
; [naka_s_headers] TrAsGrid_ByteData1_Table
; TrAsGrid_ByteData1_Table -- read by TrAsGrid_StepListValue (v10/v9
; 0xf2c41a, v7 0xf2c3f0) (`lda xde,
; (TrAsGrid_ByteData1_Table:24)`). 20 bytes to the next object; the
; layout beyond that access is not established.
;
; Typed in naka_widget_tables_1.c as uint8_t
; TrAsGrid_ByteData1_Table[20].
; -----------------------------------------------------------------------------
TrAsGrid_ByteData1_Table:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2412, 0x14
; -----------------------------------------------------------------------------
; [naka_s_headers] TrAsGrid_ByteData1_Table_2
; TrAsGrid_ByteData1_Table_2 -- read by TrAsGrid_StepListValue (v10/v9
; 0xf2c41a, v7 0xf2c3f0) (`ld xbc, TrAsGrid_ByteData1_Table_2`). 20
; bytes to the next object; the layout beyond that access is not
; established.
;
; Typed in naka_widget_tables_1.c as uint8_t
; TrAsGrid_ByteData1_Table_2[20].
; -----------------------------------------------------------------------------
TrAsGrid_ByteData1_Table_2:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2426, 0x14
; -----------------------------------------------------------------------------
; [naka_s_headers] TrAsGridChk_Part2_Start_Str
; TrAsGridChk_Part2_Start_Str -- NUL-terminated string(s), 4 bytes, used
; by TrAsGridChk_Part2_Start (v10/v9 0xf2c7c3, v7 0xf2c799) (`ld xwa,
; TrAsGridChk_Part2_Start_Str`).
;
; Typed in naka_widget_tables_1.c as char
; TrAsGridChk_Part2_Start_Str[4].
; -----------------------------------------------------------------------------
TrAsGridChk_Part2_Start_Str:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x243A, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] TrAsGridChk_Part2_Start_Str_2
; TrAsGridChk_Part2_Start_Str_2 -- NUL-terminated string(s), 4 bytes,
; used by TrAsGridChk_Part2_Start (v10/v9 0xf2c7c3, v7 0xf2c799) (`ld
; xwa, TrAsGridChk_Part2_Start_Str_2`).
;
; Typed in naka_widget_tables_1.c as char
; TrAsGridChk_Part2_Start_Str_2[4].
; -----------------------------------------------------------------------------
TrAsGridChk_Part2_Start_Str_2:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x243E, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] TrAsGridChk_Part2_PushCmd_Str
; TrAsGridChk_Part2_PushCmd_Str -- NUL-terminated string(s), 4 bytes,
; used by TrAsGridChk_Part2_PushCmd (v10/v9 0xf2c7e5, v7 0xf2c7bb) (`ld
; xwa, TrAsGridChk_Part2_PushCmd_Str`).
;
; Typed in naka_widget_tables_1.c as char
; TrAsGridChk_Part2_PushCmd_Str[4].
; -----------------------------------------------------------------------------
TrAsGridChk_Part2_PushCmd_Str:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2442, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] TrAsGridChk_Part2_PushCmd_Str_2
; TrAsGridChk_Part2_PushCmd_Str_2 -- NUL-terminated string(s), 4 bytes,
; used by TrAsGridChk_Part2_PushCmd (v10/v9 0xf2c7e5, v7 0xf2c7bb) (`ld
; xwa, TrAsGridChk_Part2_PushCmd_Str_2`).
;
; Typed in naka_widget_tables_1.c as char
; TrAsGridChk_Part2_PushCmd_Str_2[4].
; -----------------------------------------------------------------------------
TrAsGridChk_Part2_PushCmd_Str_2:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2446, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] TrAsGridChk_Part2_UpDir_Str
; TrAsGridChk_Part2_UpDir_Str -- NUL-terminated string(s), 4 bytes, used
; by TrAsGridChk_Part2_UpDir (v10/v9 0xf2c82e, v7 0xf2c804) (`ld xwa,
; TrAsGridChk_Part2_UpDir_Str`).
;
; Typed in naka_widget_tables_1.c as char
; TrAsGridChk_Part2_UpDir_Str[4].
; -----------------------------------------------------------------------------
TrAsGridChk_Part2_UpDir_Str:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x244A, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] TrAsGridChk_Part2_UpDir_Str_2
; TrAsGridChk_Part2_UpDir_Str_2 -- NUL-terminated string(s), 4 bytes,
; used by TrAsGridChk_Part2_UpDir (v10/v9 0xf2c82e, v7 0xf2c804) (`ld
; xwa, TrAsGridChk_Part2_UpDir_Str_2`).
;
; Typed in naka_widget_tables_1.c as char
; TrAsGridChk_Part2_UpDir_Str_2[4].
; -----------------------------------------------------------------------------
TrAsGridChk_Part2_UpDir_Str_2:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x244E, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] TrAsGridChk_Part2_UpPushCmd_Str
; TrAsGridChk_Part2_UpPushCmd_Str -- NUL-terminated string(s), 4 bytes,
; used by TrAsGridChk_Part2_UpPushCmd (v10/v9 0xf2c84a, v7 0xf2c820)
; (`ld xwa, TrAsGridChk_Part2_UpPushCmd_Str`).
;
; Typed in naka_widget_tables_1.c as char
; TrAsGridChk_Part2_UpPushCmd_Str[4].
; -----------------------------------------------------------------------------
TrAsGridChk_Part2_UpPushCmd_Str:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2452, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] TrAsGridChk_Part2_UpCheckType0_Str
; TrAsGridChk_Part2_UpCheckType0_Str -- NUL-terminated string(s), 4
; bytes, used by TrAsGridChk_Part2_UpCheckType0 (v10/v9 0xf2c882, v7
; 0xf2c858) (`ld xwa, TrAsGridChk_Part2_UpCheckType0_Str`).
;
; Typed in naka_widget_tables_1.c as char
; TrAsGridChk_Part2_UpCheckType0_Str[4].
; -----------------------------------------------------------------------------
TrAsGridChk_Part2_UpCheckType0_Str:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2456, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] TrAsGridChk_Part3_Start_Str
; TrAsGridChk_Part3_Start_Str -- NUL-terminated string(s), 4 bytes, used
; by TrAsGridChk_Part3_Start (v10/v9 0xf2c8ac, v7 0xf2c882) (`ld xwa,
; TrAsGridChk_Part3_Start_Str`).
;
; Typed in naka_widget_tables_1.c as char
; TrAsGridChk_Part3_Start_Str[4].
; -----------------------------------------------------------------------------
TrAsGridChk_Part3_Start_Str:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x245A, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] TrAsGridChk_Part3_Start_Str_2
; TrAsGridChk_Part3_Start_Str_2 -- NUL-terminated string(s), 4 bytes,
; used by TrAsGridChk_Part3_Start (v10/v9 0xf2c8ac, v7 0xf2c882) (`ld
; xwa, TrAsGridChk_Part3_Start_Str_2`).
;
; Typed in naka_widget_tables_1.c as char
; TrAsGridChk_Part3_Start_Str_2[4].
; -----------------------------------------------------------------------------
TrAsGridChk_Part3_Start_Str_2:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x245E, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] TrAsGridChk_Part3_PushCmd_Str
; TrAsGridChk_Part3_PushCmd_Str -- NUL-terminated string(s), 4 bytes,
; used by TrAsGridChk_Part3_PushCmd (v10/v9 0xf2c8cb, v7 0xf2c8a1) (`ld
; xwa, TrAsGridChk_Part3_PushCmd_Str`).
;
; Typed in naka_widget_tables_1.c as char
; TrAsGridChk_Part3_PushCmd_Str[4].
; -----------------------------------------------------------------------------
TrAsGridChk_Part3_PushCmd_Str:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2462, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] TrAsGridChk_Part3_PushCmd_Str_2
; TrAsGridChk_Part3_PushCmd_Str_2 -- NUL-terminated string(s), 4 bytes,
; used by TrAsGridChk_Part3_PushCmd (v10/v9 0xf2c8cb, v7 0xf2c8a1) (`ld
; xwa, TrAsGridChk_Part3_PushCmd_Str_2`).
;
; Typed in naka_widget_tables_1.c as char
; TrAsGridChk_Part3_PushCmd_Str_2[4].
; -----------------------------------------------------------------------------
TrAsGridChk_Part3_PushCmd_Str_2:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2466, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] TrAsGridChk_Part3_UpDir_Str
; TrAsGridChk_Part3_UpDir_Str -- NUL-terminated string(s), 4 bytes, used
; by TrAsGridChk_Part3_UpDir (v10/v9 0xf2c917, v7 0xf2c8ed) (`ld xwa,
; TrAsGridChk_Part3_UpDir_Str`).
;
; Typed in naka_widget_tables_1.c as char
; TrAsGridChk_Part3_UpDir_Str[4].
; -----------------------------------------------------------------------------
TrAsGridChk_Part3_UpDir_Str:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x246A, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] TrAsGridChk_Part3_UpDir_Str_2
; TrAsGridChk_Part3_UpDir_Str_2 -- NUL-terminated string(s), 4 bytes,
; used by TrAsGridChk_Part3_UpDir (v10/v9 0xf2c917, v7 0xf2c8ed) (`ld
; xwa, TrAsGridChk_Part3_UpDir_Str_2`).
;
; Typed in naka_widget_tables_1.c as char
; TrAsGridChk_Part3_UpDir_Str_2[4].
; -----------------------------------------------------------------------------
TrAsGridChk_Part3_UpDir_Str_2:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x246E, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] TrAsGridChk_Part3_UpPushCmd_Str
; TrAsGridChk_Part3_UpPushCmd_Str -- NUL-terminated string(s), 4 bytes,
; used by TrAsGridChk_Part3_UpPushCmd (v10/v9 0xf2c930, v7 0xf2c906)
; (`ld xwa, TrAsGridChk_Part3_UpPushCmd_Str`).
;
; Typed in naka_widget_tables_1.c as char
; TrAsGridChk_Part3_UpPushCmd_Str[4].
; -----------------------------------------------------------------------------
TrAsGridChk_Part3_UpPushCmd_Str:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2472, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] TrAsGridChk_Part3_UpCheckType0_Str
; TrAsGridChk_Part3_UpCheckType0_Str -- NUL-terminated string(s), 4
; bytes, used by TrAsGridChk_Part3_UpCheckType0 (v10/v9 0xf2c96b, v7
; 0xf2c941) (`ld xwa, TrAsGridChk_Part3_UpCheckType0_Str`).
;
; Typed in naka_widget_tables_1.c as char
; TrAsGridChk_Part3_UpCheckType0_Str[4].
; -----------------------------------------------------------------------------
TrAsGridChk_Part3_UpCheckType0_Str:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2476, 0x4
; -----------------------------------------------------------------------------
; [naka_s_headers] TrAsGridCheck_CaseTable
; TrAsGridCheck_CaseTable -- jump table of a compiled `switch` in
; TrAsGridCheck (v10/v9 0xf2c477, v7 0xf2c44d) (`add xwa,
; TrAsGridCheck_CaseTable`): 7 u16 case offsets from
; TrAsGridCheck_Cases.
;
; Typed in naka_widget_tables_1.c as uint16_t
; TrAsGridCheck_CaseTable[7].
; -----------------------------------------------------------------------------
TrAsGridCheck_CaseTable:
	.short	TrAsGridCheck_Cases - TrAsGridCheck_Cases
	.short	TrAsGridCheck_OnIndexswDown - TrAsGridCheck_Cases
	.short	TrAsGridCheck_Cases - TrAsGridCheck_Cases
	.short	TrAsGridCheck_OnIndexswDown - TrAsGridCheck_Cases
	.short	TrAsGridChk_ReturnZero - TrAsGridCheck_Cases
	.short	TrAsGridChk_ReturnZero - TrAsGridCheck_Cases
	.short	TrAsGridChk_ReturnZero - TrAsGridCheck_Cases
; -----------------------------------------------------------------------------
; [naka_s_headers] VoiceConfig_LookupByScreenType_Table
; VoiceConfig_LookupByScreenType_Table -- read by
; VoiceConfig_LookupByScreenType (v10/v9 0xf2ca12, v7 0xf2c9e8) (`ld
; xwa, VoiceConfig_LookupByScreenType_Table`). 6 bytes to the next object; the
; layout beyond that access is not established.
;
; Typed in naka_widget_tables_1.c as uint8_t
; VoiceConfig_LookupByScreenType_Table[6].
; -----------------------------------------------------------------------------
VoiceConfig_LookupByScreenType_Table:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2488, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] VoiceConfig_LoadTableA_Table
; VoiceConfig_LoadTableA_Table -- read by VoiceConfig_LoadTableA (v10/v9
; 0xf2ca4a, v7 0xf2ca20) (`ld xwa, VoiceConfig_LoadTableA_Table`). 6
; bytes to the next object; the layout beyond that access is not
; established.
;
; Typed in naka_widget_tables_1.c as uint8_t
; VoiceConfig_LoadTableA_Table[6].
; -----------------------------------------------------------------------------
VoiceConfig_LoadTableA_Table:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x248E, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] VoiceConfig_LoadTableB_Table
; VoiceConfig_LoadTableB_Table -- read by VoiceConfig_LoadTableB (v10/v9
; 0xf2ca51, v7 0xf2ca27) (`ld xwa, VoiceConfig_LoadTableB_Table`). 38
; bytes to the next object; the layout beyond that access is not
; established.
;
; Typed in naka_widget_tables_1.c as uint8_t
; VoiceConfig_LoadTableB_Table[38].
; -----------------------------------------------------------------------------
VoiceConfig_LoadTableB_Table:		.incbin "includes/generated/naka_widget_tables_1.bin", 0x2494, 0x6
AcCurSongName_HandleFocusGained_Data:	.incbin "includes/generated/naka_widget_tables_1.bin", 0x249A, 0x8
AcCurSongName_HandleEventF_Str_Blank22:	.incbin "includes/generated/naka_widget_tables_1.bin", 0x24A2, 0x18	; "                      "
; -----------------------------------------------------------------------------
; [naka_s_headers] MuteChSel_Dispatch_PtrTable
; MuteChSel_Dispatch_PtrTable -- 16 u32 addresses, read by
; MuteChSel_Dispatch (v10/v9 0xf2cc54, v7 0xf2cc2a) (`ld xbc,
; MuteChSel_Dispatch_PtrTable`).
;
; Typed in naka_widget_tables_1.c as uint32_t
; MuteChSel_Dispatch_PtrTable[16].
; -----------------------------------------------------------------------------
MuteChSel_Dispatch_PtrTable:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x24BA, 0x40
; -----------------------------------------------------------------------------
; [naka_s_headers] MuteChSel_Dispatch_Strings
; MuteChSel_Dispatch_Strings -- the 16 strings
; MuteChSel_Dispatch_PtrTable points at (NUL-terminated, 0xff pad to
; even length), 96 bytes.
;
; Typed in naka_widget_tables_1.c as char
; MuteChSel_Dispatch_Strings[96].
; -----------------------------------------------------------------------------
MuteChSel_Dispatch_Strings:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x24FA, 0x60
; -----------------------------------------------------------------------------
; [naka_s_headers] SmfMuteChSelFunc_CaseTable
; SmfMuteChSelFunc_CaseTable -- jump table of a compiled `switch` in
; SmfMuteChSelFunc (v10/v9 0xf2cc27, v7 0xf2cbfd) (`add xbc,
; SmfMuteChSelFunc_CaseTable`): 10 u16 case offsets from
; MuteChSel_Dispatch.
;
; Typed in naka_widget_tables_1.c as uint16_t
; SmfMuteChSelFunc_CaseTable[10].
; -----------------------------------------------------------------------------
SmfMuteChSelFunc_CaseTable:
	.short	SmfMuteChSelFunc_OnGetLargeStep - MuteChSel_Dispatch
	.short	SmfMuteChSelFunc_OnGetLargeStep - MuteChSel_Dispatch
	.short	MuteChSel_ReturnZero - MuteChSel_Dispatch
	.short	MuteChSel_ReturnZero - MuteChSel_Dispatch
	.short	MuteChSel_ReturnZero - MuteChSel_Dispatch
	.short	SmfMuteChSelFunc_OnGetMax - MuteChSel_Dispatch
	.short	MuteChSel_ReturnZero - MuteChSel_Dispatch
	.short	SmfMuteChSelFunc_OnGetRamAddress - MuteChSel_Dispatch
	.short	SmfMuteChSelFunc_OnGetLargeStep - MuteChSel_Dispatch
	.short	MuteChSel_Dispatch - MuteChSel_Dispatch
; -----------------------------------------------------------------------------
; [naka_s_headers] SqTrAsPsSong_Dispatch_PtrTable
; SqTrAsPsSong_Dispatch_PtrTable -- 11 u32 addresses, read by
; SqTrAsPsSong_Dispatch (v10/v9 0xf2ccb5, v7 0xf2cc8b) (`ld xbc,
; SqTrAsPsSong_Dispatch_PtrTable`).
;
; Typed in naka_widget_tables_1.c as uint32_t
; SqTrAsPsSong_Dispatch_PtrTable[11].
; -----------------------------------------------------------------------------
SqTrAsPsSong_Dispatch_PtrTable:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x256E, 0x2C
; -----------------------------------------------------------------------------
; [naka_s_headers] SqTrAsPsSong_Dispatch_Strings
; SqTrAsPsSong_Dispatch_Strings -- the 11 strings
; SqTrAsPsSong_Dispatch_PtrTable points at (NUL-terminated, 0xff pad to
; even length), 110 bytes.
;
; Typed in naka_widget_tables_1.c as char
; SqTrAsPsSong_Dispatch_Strings[110].
; -----------------------------------------------------------------------------
SqTrAsPsSong_Dispatch_Strings:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x259A, 0x6E
; -----------------------------------------------------------------------------
; [naka_s_headers] SqTrAsPsSongFunc_CaseTable
; SqTrAsPsSongFunc_CaseTable -- jump table of a compiled `switch` in
; SqTrAsPsSongFunc (v10/v9 0xf2cc88, v7 0xf2cc5e) (`add xbc,
; SqTrAsPsSongFunc_CaseTable`): 10 u16 case offsets from
; SqTrAsPsSong_Dispatch.
;
; Typed in naka_widget_tables_1.c as uint16_t
; SqTrAsPsSongFunc_CaseTable[10].
; -----------------------------------------------------------------------------
SqTrAsPsSongFunc_CaseTable:
	.short	SqTrAsPsSongFunc_OnGetLargeStep - SqTrAsPsSong_Dispatch
	.short	SqTrAsPsSongFunc_OnGetLargeStep - SqTrAsPsSong_Dispatch
	.short	SqTrAsPsSong_ReturnZero - SqTrAsPsSong_Dispatch
	.short	SqTrAsPsSong_ReturnZero - SqTrAsPsSong_Dispatch
	.short	SqTrAsPsSong_ReturnZero - SqTrAsPsSong_Dispatch
	.short	SqTrAsPsSongFunc_OnGetMax - SqTrAsPsSong_Dispatch
	.short	SqTrAsPsSong_ReturnZero - SqTrAsPsSong_Dispatch
	.short	SqTrAsPsSongFunc_OnGetRamAddress - SqTrAsPsSong_Dispatch
	.short	SqTrAsPsSongFunc_OnGetLargeStep - SqTrAsPsSong_Dispatch
	.short	SqTrAsPsSong_Dispatch - SqTrAsPsSong_Dispatch
; -----------------------------------------------------------------------------
; [naka_s_headers] SqAftSetFunc_PtrTable
; SqAftSetFunc_PtrTable -- 2 u32 addresses, read by SqAftSetFunc (v10/v9
; 0xf2cce8, v7 0xf2ccbe) (`lda xbc,
; (SqAftSetFunc_PtrTable:24)`).
;
; Typed in naka_widget_tables_1.c as uint32_t SqAftSetFunc_PtrTable[2].
; -----------------------------------------------------------------------------
SqAftSetFunc_PtrTable:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x261C, 0x8
; -----------------------------------------------------------------------------
; [naka_s_headers] SqAftSetFunc_Strings
; SqAftSetFunc_Strings -- the 2 strings SqAftSetFunc_PtrTable points at
; (NUL-terminated, 0xff pad to even length), 12 bytes.
;
; Typed in naka_widget_tables_1.c as char SqAftSetFunc_Strings[12].
; -----------------------------------------------------------------------------
SqAftSetFunc_Strings:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2624, 0xC
; -----------------------------------------------------------------------------
; [naka_s_headers] SqAftSet_LookupTableEntry_Table
; SqAftSet_LookupTableEntry_Table -- read by SqAftSet_LookupTableEntry
; (v10/v9 0xf2cd39, v7 0xf2cd0f) (`lda xbc,
; (SqAftSet_LookupTableEntry_Table:24)`). 32 bytes to the next object; the
; layout beyond that access is not established.
;
; Typed in naka_widget_tables_1.c as uint8_t
; SqAftSet_LookupTableEntry_Table[32].
; -----------------------------------------------------------------------------
SqAftSet_LookupTableEntry_Table:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2630, 0x20
; -----------------------------------------------------------------------------
; [naka_s_headers] MuteChSet_Dispatch_PtrTable
; MuteChSet_Dispatch_PtrTable -- 16 u32 addresses, read by
; MuteChSet_Dispatch (v10/v9 0xf2cd84, v7 0xf2cd5a) (`ld xbc,
; MuteChSet_Dispatch_PtrTable`).
;
; Typed in naka_widget_tables_1.c as uint32_t
; MuteChSet_Dispatch_PtrTable[16].
; -----------------------------------------------------------------------------
MuteChSet_Dispatch_PtrTable:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2650, 0x40
; -----------------------------------------------------------------------------
; [naka_s_headers] MuteChSet_Dispatch_Strings
; MuteChSet_Dispatch_Strings -- the 16 strings
; MuteChSet_Dispatch_PtrTable points at (NUL-terminated, 0xff pad to
; even length), 128 bytes.
;
; Typed in naka_widget_tables_1.c as char
; MuteChSet_Dispatch_Strings[128].
; -----------------------------------------------------------------------------
MuteChSet_Dispatch_Strings:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2690, 0x80
; -----------------------------------------------------------------------------
; [naka_s_headers] MuteChSetFunc_CaseTable
; MuteChSetFunc_CaseTable -- jump table of a compiled `switch` in
; MuteChSetFunc (v10/v9 0xf2cd4d, v7 0xf2cd23) (`add xwa,
; MuteChSetFunc_CaseTable`): 10 u16 case offsets from
; MuteChSet_Dispatch.
;
; Typed in naka_widget_tables_1.c as uint16_t
; MuteChSetFunc_CaseTable[10].
; -----------------------------------------------------------------------------
MuteChSetFunc_CaseTable:
	.short	MuteChSetFunc_OnGetLargeStep - MuteChSet_Dispatch
	.short	MuteChSetFunc_OnGetLargeStep - MuteChSet_Dispatch
	.short	MuteChSetFunc_Exit - MuteChSet_Dispatch
	.short	MuteChSetFunc_Exit - MuteChSet_Dispatch
	.short	MuteChSetFunc_Exit - MuteChSet_Dispatch
	.short	MuteChSetFunc_OnGetMax - MuteChSet_Dispatch
	.short	MuteChSetFunc_Exit - MuteChSet_Dispatch
	.short	MuteChSetFunc_OnGetRamAddress - MuteChSet_Dispatch
	.short	MuteChSetFunc_OnGetLargeStep - MuteChSet_Dispatch
	.short	MuteChSet_Dispatch - MuteChSet_Dispatch
; -----------------------------------------------------------------------------
; [naka_s_headers] AcDemoMedley_HandleScrollEvent_Str
; AcDemoMedley_HandleScrollEvent_Str -- NUL-terminated string(s), 12
; bytes, used by AcDemoMedley_HandleScrollEvent (v10/v9 0xf2d078, v7
; 0xf2d04e) (`ld xwa, AcDemoMedley_HandleScrollEvent_Str`).
;
; Typed in naka_widget_tables_1.c as char
; AcDemoMedley_HandleScrollEvent_Str[12].
; -----------------------------------------------------------------------------
AcDemoMedley_HandleScrollEvent_Str:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2724, 0xC
; -----------------------------------------------------------------------------
; [naka_s_headers] AcDemoMedley_HandleScrollEvent_Str_2
; AcDemoMedley_HandleScrollEvent_Str_2 -- NUL-terminated string(s), 12
; bytes, used by AcDemoMedley_HandleScrollEvent (v10/v9 0xf2d078, v7
; 0xf2d04e) (`ld xwa, AcDemoMedley_HandleScrollEvent_Str_2`).
;
; Typed in naka_widget_tables_1.c as char
; AcDemoMedley_HandleScrollEvent_Str_2[12].
; -----------------------------------------------------------------------------
AcDemoMedley_HandleScrollEvent_Str_2:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2730, 0xC
; -----------------------------------------------------------------------------
; [naka_s_headers] MedleyDisp_Blank
; MedleyDisp_Blank -- NUL-terminated string(s), 12 bytes, used by
; DemoMedDsp_Dispatch (v10/v9 0xf2d0e9, v7 0xf2d0bf) (`.long
; MedleyDisp_Blank`).
;
; Typed in naka_widget_tables_1.c as char MedleyDisp_Blank[12].
; -----------------------------------------------------------------------------
MedleyDisp_Blank:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x273C, 0xC
; -----------------------------------------------------------------------------
; [naka_s_headers] DemoMedDsp_Dispatch_Str
; DemoMedDsp_Dispatch_Str -- NUL-terminated string(s), 12 bytes, used by
; DemoMedDsp_Dispatch (v10/v9 0xf2d0e9, v7 0xf2d0bf) (`ld xwa,
; DemoMedDsp_Dispatch_Str`).
;
; Typed in naka_widget_tables_1.c as char DemoMedDsp_Dispatch_Str[12].
; -----------------------------------------------------------------------------
DemoMedDsp_Dispatch_Str:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2748, 0xC
; -----------------------------------------------------------------------------
; [naka_s_headers] DemoMedDspCheck_CaseTable
; DemoMedDspCheck_CaseTable -- jump table of a compiled `switch` in
; DemoMedDspCheck (v10/v9 0xf2d0b2, v7 0xf2d088) (`add xwa,
; DemoMedDspCheck_CaseTable`): 10 u16 case offsets from DemoMedDsp_Dispatch.
;
; Typed in naka_widget_tables_1.c as uint16_t
; DemoMedDspCheck_CaseTable[10].
; -----------------------------------------------------------------------------
DemoMedDspCheck_CaseTable:
	.short	DemoMedDspCheck_OnGetLargeStep - DemoMedDsp_Dispatch
	.short	DemoMedDspCheck_OnGetSmallStep - DemoMedDsp_Dispatch
	.short	DPLoad_DspReturn - DemoMedDsp_Dispatch
	.short	DPLoad_DspReturn - DemoMedDsp_Dispatch
	.short	DPLoad_DspReturn - DemoMedDsp_Dispatch
	.short	DemoMedDspCheck_OnGetMax - DemoMedDsp_Dispatch
	.short	DemoMedDspCheck_OnGetMin - DemoMedDsp_Dispatch
	.short	DemoMedDspCheck_OnGetRamAddress - DemoMedDsp_Dispatch
	.short	DemoMedDspCheck_OnGetSmallStep - DemoMedDsp_Dispatch
	.short	DemoMedDsp_Dispatch - DemoMedDsp_Dispatch
; -----------------------------------------------------------------------------
; [naka_s_headers] PlayModeStr_Play
; PlayModeStr_Play -- NUL-terminated string(s), 6 bytes, used by
; DPPlayDsp_Dispatch (v10/v9 0xf2d161, v7 0xf2d137) (`.long
; PlayModeStr_Play`).
;
; Typed in naka_widget_tables_1.c as char PlayModeStr_Play[6].
; -----------------------------------------------------------------------------
PlayModeStr_Play:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2768, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] DPPlayDsp_Dispatch_Str
; DPPlayDsp_Dispatch_Str -- NUL-terminated string(s), 6 bytes, used by
; DPPlayDsp_Dispatch (v10/v9 0xf2d161, v7 0xf2d137) (`ld xwa,
; DPPlayDsp_Dispatch_Str`).
;
; Typed in naka_widget_tables_1.c as char DPPlayDsp_Dispatch_Str[6].
; -----------------------------------------------------------------------------
DPPlayDsp_Dispatch_Str:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x276E, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] DPPlayDspCheck_CaseTable
; DPPlayDspCheck_CaseTable -- jump table of a compiled `switch` in
; DPPlayDspCheck (v10/v9 0xf2d12a, v7 0xf2d100) (`add xwa,
; DPPlayDspCheck_CaseTable`): 10 u16 case offsets from DPPlayDsp_Dispatch.
;
; Typed in naka_widget_tables_1.c as uint16_t
; DPPlayDspCheck_CaseTable[10].
; -----------------------------------------------------------------------------
DPPlayDspCheck_CaseTable:
	.short	DPPlayDspCheck_OnGetLargeStep - DPPlayDsp_Dispatch
	.short	DPPlayDspCheck_OnGetSmallStep - DPPlayDsp_Dispatch
	.short	DPPlay_DspReturn - DPPlayDsp_Dispatch
	.short	DPPlay_DspReturn - DPPlayDsp_Dispatch
	.short	DPPlay_DspReturn - DPPlayDsp_Dispatch
	.short	DPPlayDspCheck_OnGetMax - DPPlayDsp_Dispatch
	.short	DPPlayDspCheck_OnGetMin - DPPlayDsp_Dispatch
	.short	DPPlayDspCheck_OnGetRamAddress - DPPlayDsp_Dispatch
	.short	DPPlayDspCheck_OnGetSmallStep - DPPlayDsp_Dispatch
	.short	DPPlayDsp_Dispatch - DPPlayDsp_Dispatch
; -----------------------------------------------------------------------------
; [naka_s_headers] PlayModeStr_Pause
; PlayModeStr_Pause -- NUL-terminated string(s), 6 bytes, used by
; DPPauseDsp_Dispatch (v10/v9 0xf2d1d9, v7 0xf2d1af) (`.long
; PlayModeStr_Pause`).
;
; Typed in naka_widget_tables_1.c as char PlayModeStr_Pause[6].
; -----------------------------------------------------------------------------
PlayModeStr_Pause:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2788, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] DPPauseDsp_Dispatch_Str
; DPPauseDsp_Dispatch_Str -- NUL-terminated string(s), 6 bytes, used by
; DPPauseDsp_Dispatch (v10/v9 0xf2d1d9, v7 0xf2d1af) (`ld xwa,
; DPPauseDsp_Dispatch_Str`).
;
; Typed in naka_widget_tables_1.c as char DPPauseDsp_Dispatch_Str[6].
; -----------------------------------------------------------------------------
DPPauseDsp_Dispatch_Str:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x278E, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] DPPauseDspCheck_CaseTable
; DPPauseDspCheck_CaseTable -- jump table of a compiled `switch` in
; DPPauseDspCheck (v10/v9 0xf2d1a2, v7 0xf2d178) (`add xwa,
; DPPauseDspCheck_CaseTable`): 10 u16 case offsets from DPPauseDsp_Dispatch.
;
; Typed in naka_widget_tables_1.c as uint16_t
; DPPauseDspCheck_CaseTable[10].
; -----------------------------------------------------------------------------
DPPauseDspCheck_CaseTable:
	.short	DPPauseDspCheck_OnGetLargeStep - DPPauseDsp_Dispatch
	.short	DPPauseDspCheck_OnGetSmallStep - DPPauseDsp_Dispatch
	.short	DPPause_DspReturn - DPPauseDsp_Dispatch
	.short	DPPause_DspReturn - DPPauseDsp_Dispatch
	.short	DPPause_DspReturn - DPPauseDsp_Dispatch
	.short	DPPauseDspCheck_OnGetMax - DPPauseDsp_Dispatch
	.short	DPPauseDspCheck_OnGetMin - DPPauseDsp_Dispatch
	.short	DPPauseDspCheck_OnGetRamAddress - DPPauseDsp_Dispatch
	.short	DPPauseDspCheck_OnGetSmallStep - DPPauseDsp_Dispatch
	.short	DPPauseDsp_Dispatch - DPPauseDsp_Dispatch
; -----------------------------------------------------------------------------
; [naka_s_headers] DPPauseDspCheck_CaseTable_Strings
; DPPauseDspCheck_CaseTable_Strings -- 6 bytes of NUL-terminated strings
; after DPPauseDspCheck_CaseTable; that code DOES reach (Readers below) (searched: RegObjTabl tables, slice and positional
; labels). Which code uses them is not established.
;
; Typed in naka_widget_tables_1.c as char
; DPPauseDspCheck_CaseTable_Strings[6].
; Readers (claims_lint.py unread-claims, 2026-10-02): IvExitTrSel_CopyString (0xF2D242, pushw far
;   pointer)
; -----------------------------------------------------------------------------
DPPauseDspCheck_CaseTable_Strings:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x27A8, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] Kubo_ApFuncTable_128
; Kubo_ApFuncTable_128 -- object table: InitializeKubo (v10/v9 0xf2d2c4,
; v7 0xf2d29a) (sequencer/sequencer_ui.s:4301) registers it with
; `RegObjTabl 0x1600002, ApFunctionProc, 73, 0xe26804, 0x128` -- class
; 0x1600002 (ApFunctionProc), 73 objects, base id 0x128. Entries:
; procedure addresses then a 0 terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t Kubo_ApFuncTable_128[74].
; -----------------------------------------------------------------------------
Kubo_ApFuncTable_128:
	.long EffectBoxProc
	.long EqualizerBoxProc
	.long SqedtValProc
	.long SqedtVal2Proc
	.long SqedtFixProc
	.long IvSongCopyExitProc
	.long SqplyValProc
	.long SqedtVal3Proc
	.long AccIllProc
	.long AcEntertainerGridBoxProc
	.long SngSelProc
	.long SngSel2Proc
	.long NoteEditBoxProc
	.long EqOnOffFuncToggleProc
	.long MsgToTtlProc
	.long AcIndexWideToggleProc
	.long IvPlayExitProc
	.long HelpTtlProc
	.long IvPnlWrExitProc
	.long IvSdrevProc
	.long IvSddspProc
	.long IvSdaccProc
	.long IvPunchExitProc
	.long IvAutoPunchExitProc
	.long AcPanicEditSwProc
	.long IvRealRecExitProc
	.long DspItem0CngFunc
	.long EqualizerCngFunc
	.long SqedtFunc
	.long MainExeFunc
	.long CycleOnOffFunc
	.long MetroOnOffFunc
	.long SqplyFunc
	.long EntertainerGridCheck
	.long SngSelFunc
	.long PlySngSelFunc
	.long PlySngSel2Func
	.long PunchInOutFunc
	.long NoteEditFunc
	.long EqInOutFunc
	.long TrkMixerIntTtlFunc
	.long BitmapNtedt0d
	.long BitmapNtedt0k
	.long BitmapDredt0d
	.long BitmapDredt0k
	.long MimeOnOffFunc
	.long AttAreYouSureCheck
	.long AttAttentionCheck
	.long StsSeqMenu1Check
	.long StsSeqMenu2Check
	.long StsEasyRec1Check
	.long StsEasyRec2Check
	.long StsPnlWrtCheck
	.long StsTrkClr1Check
	.long StsTrkClr2Check
	.long StsNtDrEditCheck
	.long AttTrkClrCheck
	.long AttSongClrCheck
	.long AcIndexWideToggleFunc
	.long HelpTtlFunc
	.long HelpLangChkFunc
	.long HelpStsCheck
	.long HelpStsP2Check
	.long HelpStsP3Check
	.long HelpStsP4Check
	.long HelpMenuCheck
	.long HelpOkSwFunc
	.long HelpFuncChkFunc
	.long StsAtPunchCheck
	.long EdMenuPageFunc
	.long SureJudgeFunc
	.long PanicFunc
	.long AutoPunchTtlRqFunc
	.long 0x00000000
; -----------------------------------------------------------------------------
; [naka_s_headers] Kubo_ApFuncNameTable_428
; Kubo_ApFuncNameTable_428 -- object table: InitializeKubo (v10/v9
; 0xf2d2c4, v7 0xf2d29a) (sequencer/sequencer_ui.s:4302) registers it
; with `RegObjTabl 0x1600002, ApFunctionProc, 73, 0xe2692c, 0x428` --
; class 0x1600002 (ApFunctionProc), 73 objects, base id 0x428. Entries:
; pointers to the procedures' name strings then a "" terminator.
;
; Typed in naka_widget_tables_1.c as uint32_t
; Kubo_ApFuncNameTable_428[74].
; -----------------------------------------------------------------------------
Kubo_ApFuncNameTable_428:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x28D6, 0x128
; -----------------------------------------------------------------------------
; [naka_s_headers] Kubo_ApFuncNames_428
; Kubo_ApFuncNames_428 -- the strings Kubo_ApFuncNameTable_428 points
; at: 74 NUL-terminated names (0xff pads to even length), 1146 bytes.
;
; Typed in naka_widget_tables_1.c as char Kubo_ApFuncNames_428[1146].
; -----------------------------------------------------------------------------
Kubo_ApFuncNames_428:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x29FE, 0x47A
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_EffectBox
; ClassProps_EffectBox -- property names of class EffectBox (descriptor
; 0 of Kubo_ClassTable_168, whose +0x14 points here): 4 pointers, one
; per letter of its signature "jBBC" -- "func", "data", "data2",
; "ttl_no" -- then a pointer to "", then the names themselves.
;
; Typed in naka_widget_tables_1.c as uint32_t ClassProps_EffectBox[5]
; and char ClassProps_EffectBox_Names[].
; -----------------------------------------------------------------------------
ClassProps_EffectBox:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2E78, 0x30
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_EqualizerBox
; ClassProps_EqualizerBox -- property names of class EqualizerBox
; (descriptor 1 of Kubo_ClassTable_168, whose +0x14 points here): 2
; pointers, one per letter of its signature "jC" -- "func", "ttl_no" --
; then a pointer to "", then the names themselves.
;
; Typed in naka_widget_tables_1.c as uint32_t ClassProps_EqualizerBox[3]
; and char ClassProps_EqualizerBox_Names[].
; -----------------------------------------------------------------------------
ClassProps_EqualizerBox:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2EA8, 0x1C
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_SqedtVal
; ClassProps_SqedtVal -- property names of class SqedtVal (descriptor 2
; of Kubo_ClassTable_168, whose +0x14 points here): 4 pointers, one per
; letter of its signature "^^jC" -- "color", "fontcolor", "func",
; "ttl_no" -- then a pointer to "", then the names themselves.
;
; Typed in naka_widget_tables_1.c as uint32_t ClassProps_SqedtVal[5] and
; char ClassProps_SqedtVal_Names[].
; -----------------------------------------------------------------------------
ClassProps_SqedtVal:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2EC4, 0x34
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_SqedtVal2
; ClassProps_SqedtVal2 -- property names of class SqedtVal2 (descriptor
; 3 of Kubo_ClassTable_168, whose +0x14 points here): 3 pointers, one
; per letter of its signature "^^j" -- "color", "fontcolor", "func" --
; then a pointer to "", then the names themselves.
;
; Typed in naka_widget_tables_1.c as uint32_t ClassProps_SqedtVal2[4]
; and char ClassProps_SqedtVal2_Names[].
; -----------------------------------------------------------------------------
ClassProps_SqedtVal2:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2EF8, 0x28
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_SqedtFix
; ClassProps_SqedtFix -- property names of class SqedtFix (descriptor 4
; of Kubo_ClassTable_168, whose +0x14 points here): 3 pointers, one per
; letter of its signature "^^_" -- "color", "fontcolor", "border" --
; then a pointer to "", then the names themselves.
;
; Typed in naka_widget_tables_1.c as uint32_t ClassProps_SqedtFix[4] and
; char ClassProps_SqedtFix_Names[].
; -----------------------------------------------------------------------------
ClassProps_SqedtFix:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2F20, 0x2A
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_IvSongCopyExit
; ClassProps_IvSongCopyExit -- property names of class IvSongCopyExit
; (descriptor 5 of Kubo_ClassTable_168, whose +0x14 points here): 0
; pointers, one per letter of its signature "" -- none -- then a pointer
; to "", then the names themselves.
;
; Typed in naka_widget_tables_1.c as uint32_t
; ClassProps_IvSongCopyExit[1] and char
; ClassProps_IvSongCopyExit_Names[].
; -----------------------------------------------------------------------------
ClassProps_IvSongCopyExit:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2F4A, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_SqplyVal
; ClassProps_SqplyVal -- property names of class SqplyVal (descriptor 6
; of Kubo_ClassTable_168, whose +0x14 points here): 4 pointers, one per
; letter of its signature "^^jC" -- "color", "fontcolor", "func",
; "ttl_no" -- then a pointer to "", then the names themselves.
;
; Typed in naka_widget_tables_1.c as uint32_t ClassProps_SqplyVal[5] and
; char ClassProps_SqplyVal_Names[].
; -----------------------------------------------------------------------------
ClassProps_SqplyVal:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2F50, 0x34
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_SqedtVal3
; ClassProps_SqedtVal3 -- property names of class SqedtVal3 (descriptor
; 7 of Kubo_ClassTable_168, whose +0x14 points here): 3 pointers, one
; per letter of its signature "^^j" -- "color", "fontcolor", "func" --
; then a pointer to "", then the names themselves.
;
; Typed in naka_widget_tables_1.c as uint32_t ClassProps_SqedtVal3[4]
; and char ClassProps_SqedtVal3_Names[].
; -----------------------------------------------------------------------------
ClassProps_SqedtVal3:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2F84, 0x28
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_AccIll
; ClassProps_AccIll -- property names of class AccIll (descriptor 8 of
; Kubo_ClassTable_168, whose +0x14 points here): 4 pointers, one per
; letter of its signature "^^jC" -- "color", "fontcolor", "func",
; "ttl_no" -- then a pointer to "", then the names themselves.
;
; Typed in naka_widget_tables_1.c as uint32_t ClassProps_AccIll[5] and
; char ClassProps_AccIll_Names[].
; -----------------------------------------------------------------------------
ClassProps_AccIll:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2FAC, 0x34
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_AcEntertainerGridBox
; ClassProps_AcEntertainerGridBox -- property names of class
; AcEntertainerGridBox (descriptor 9 of Kubo_ClassTable_168, whose +0x14
; points here): 3 pointers, one per letter of its signature "XXj" --
; "fixedcol", "fixedrow", "func" -- then a pointer to "", then the names
; themselves.
;
; Typed in naka_widget_tables_1.c as uint32_t
; ClassProps_AcEntertainerGridBox[4] and char
; ClassProps_AcEntertainerGridBox_Names[].
; -----------------------------------------------------------------------------
ClassProps_AcEntertainerGridBox:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2FE0, 0x2C
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_SngSel
; ClassProps_SngSel -- property names of class SngSel (descriptor 10 of
; Kubo_ClassTable_168, whose +0x14 points here): 5 pointers, one per
; letter of its signature "c^^jC" -- "font", "color", "fontcolor",
; "func", "ttl_no" -- then a pointer to "", then the names themselves.
;
; Typed in naka_widget_tables_1.c as uint32_t ClassProps_SngSel[6] and
; char ClassProps_SngSel_Names[].
; -----------------------------------------------------------------------------
ClassProps_SngSel:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x300C, 0x3E
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_SngSel2
; ClassProps_SngSel2 -- property names of class SngSel2 (descriptor 11
; of Kubo_ClassTable_168, whose +0x14 points here): 0 pointers, one per
; letter of its signature "" -- none -- then a pointer to "", then the
; names themselves.
;
; Typed in naka_widget_tables_1.c as uint32_t ClassProps_SngSel2[1] and
; char ClassProps_SngSel2_Names[].
; -----------------------------------------------------------------------------
ClassProps_SngSel2:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x304A, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_NoteEditBox
; ClassProps_NoteEditBox -- property names of class NoteEditBox
; (descriptor 12 of Kubo_ClassTable_168, whose +0x14 points here): 2
; pointers, one per letter of its signature "jC" -- "func", "ttl_no" --
; then a pointer to "", then the names themselves.
;
; Typed in naka_widget_tables_1.c as uint32_t ClassProps_NoteEditBox[3]
; and char ClassProps_NoteEditBox_Names[].
; -----------------------------------------------------------------------------
ClassProps_NoteEditBox:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x3050, 0x1C
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_EqOnOffFuncToggle
; ClassProps_EqOnOffFuncToggle -- property names of class
; EqOnOffFuncToggle (descriptor 13 of Kubo_ClassTable_168, whose +0x14
; points here): 0 pointers, one per letter of its signature "" -- none
; -- then a pointer to "", then the names themselves.
;
; Typed in naka_widget_tables_1.c as uint32_t
; ClassProps_EqOnOffFuncToggle[1] and char
; ClassProps_EqOnOffFuncToggle_Names[].
; -----------------------------------------------------------------------------
ClassProps_EqOnOffFuncToggle:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x306C, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_MsgToTtl
; ClassProps_MsgToTtl -- property names of class MsgToTtl (descriptor 14
; of Kubo_ClassTable_168, whose +0x14 points here): 0 pointers, one per
; letter of its signature "" -- none -- then a pointer to "", then the
; names themselves.
;
; Typed in naka_widget_tables_1.c as uint32_t ClassProps_MsgToTtl[1] and
; char ClassProps_MsgToTtl_Names[].
; -----------------------------------------------------------------------------
ClassProps_MsgToTtl:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x3072, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_AcIndexWideToggle
; ClassProps_AcIndexWideToggle -- property names of class
; AcIndexWideToggle (descriptor 15 of Kubo_ClassTable_168, whose +0x14
; points here): 3 pointers, one per letter of its signature "AAj" --
; "index", "tag", "func" -- then a pointer to "", then the names
; themselves.
;
; Typed in naka_widget_tables_1.c as uint32_t
; ClassProps_AcIndexWideToggle[4] and char
; ClassProps_AcIndexWideToggle_Names[].
; -----------------------------------------------------------------------------
ClassProps_AcIndexWideToggle:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x3078, 0x1C
NakaFld_TabIndexFunc:	.incbin "includes/generated/naka_widget_tables_1.bin", 0x3094, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_IvPlayExit
; ClassProps_IvPlayExit -- property names of class IvPlayExit
; (descriptor 16 of Kubo_ClassTable_168, whose +0x14 points here): 1
; pointers, one per letter of its signature "`" -- "mode" -- then a
; pointer to "", then the names themselves.
;
; Typed in naka_widget_tables_1.c as uint32_t ClassProps_IvPlayExit[2]
; and char ClassProps_IvPlayExit_Names[].
; -----------------------------------------------------------------------------
ClassProps_IvPlayExit:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x309A, 0x10
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_HelpTtl
; ClassProps_HelpTtl -- property names of class HelpTtl (descriptor 17
; of Kubo_ClassTable_168, whose +0x14 points here): 5 pointers, one per
; letter of its signature "^^cGj" -- "color", "fontcolor", "font",
; "page", "func" -- then a pointer to "", then the names themselves.
;
; Typed in naka_widget_tables_1.c as uint32_t ClassProps_HelpTtl[6] and
; char ClassProps_HelpTtl_Names[].
; -----------------------------------------------------------------------------
ClassProps_HelpTtl:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x30AA, 0x3C
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_IvPnlWrExit
; ClassProps_IvPnlWrExit -- property names of class IvPnlWrExit
; (descriptor 18 of Kubo_ClassTable_168, whose +0x14 points here): 0
; pointers, one per letter of its signature "" -- none -- then a pointer
; to "", then the names themselves.
;
; Typed in naka_widget_tables_1.c as uint32_t ClassProps_IvPnlWrExit[1]
; and char ClassProps_IvPnlWrExit_Names[].
; -----------------------------------------------------------------------------
ClassProps_IvPnlWrExit:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x30E6, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_IvSdrev
; ClassProps_IvSdrev -- property names of class IvSdrev (descriptor 19
; of Kubo_ClassTable_168, whose +0x14 points here): 0 pointers, one per
; letter of its signature "" -- none -- then a pointer to "", then the
; names themselves.
;
; Typed in naka_widget_tables_1.c as uint32_t ClassProps_IvSdrev[1] and
; char ClassProps_IvSdrev_Names[].
; -----------------------------------------------------------------------------
ClassProps_IvSdrev:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x30EC, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_IvSddsp
; ClassProps_IvSddsp -- property names of class IvSddsp (descriptor 20
; of Kubo_ClassTable_168, whose +0x14 points here): 0 pointers, one per
; letter of its signature "" -- none -- then a pointer to "", then the
; names themselves.
;
; Typed in naka_widget_tables_1.c as uint32_t ClassProps_IvSddsp[1] and
; char ClassProps_IvSddsp_Names[].
; -----------------------------------------------------------------------------
ClassProps_IvSddsp:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x30F2, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_IvSdacc
; ClassProps_IvSdacc -- property names of class IvSdacc (descriptor 21
; of Kubo_ClassTable_168, whose +0x14 points here): 0 pointers, one per
; letter of its signature "" -- none -- then a pointer to "", then the
; names themselves.
;
; Typed in naka_widget_tables_1.c as uint32_t ClassProps_IvSdacc[1] and
; char ClassProps_IvSdacc_Names[].
; -----------------------------------------------------------------------------
ClassProps_IvSdacc:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x30F8, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_IvPunchExit
; ClassProps_IvPunchExit -- property names of class IvPunchExit
; (descriptor 22 of Kubo_ClassTable_168, whose +0x14 points here): 0
; pointers, one per letter of its signature "" -- none -- then a pointer
; to "", then the names themselves.
;
; Typed in naka_widget_tables_1.c as uint32_t ClassProps_IvPunchExit[1]
; and char ClassProps_IvPunchExit_Names[].
; -----------------------------------------------------------------------------
ClassProps_IvPunchExit:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x30FE, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_IvAutoPunchExit
; ClassProps_IvAutoPunchExit -- property names of class IvAutoPunchExit
; (descriptor 23 of Kubo_ClassTable_168, whose +0x14 points here): 0
; pointers, one per letter of its signature "" -- none -- then a pointer
; to "", then the names themselves.
;
; Typed in naka_widget_tables_1.c as uint32_t
; ClassProps_IvAutoPunchExit[1] and char
; ClassProps_IvAutoPunchExit_Names[].
; -----------------------------------------------------------------------------
ClassProps_IvAutoPunchExit:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x3104, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_AcPanicEditSw
; ClassProps_AcPanicEditSw -- property names of class AcPanicEditSw
; (descriptor 24 of Kubo_ClassTable_168, whose +0x14 points here): 2
; pointers, one per letter of its signature "fj" -- "style", "func" --
; then a pointer to "", then the names themselves.
;
; Typed in naka_widget_tables_1.c as uint32_t
; ClassProps_AcPanicEditSw[3] and char ClassProps_AcPanicEditSw_Names[].
; -----------------------------------------------------------------------------
ClassProps_AcPanicEditSw:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x310A, 0x1A
; -----------------------------------------------------------------------------
; [naka_s_headers] ClassProps_IvRealRecExit
; ClassProps_IvRealRecExit -- property names of class IvRealRecExit
; (descriptor 25 of Kubo_ClassTable_168, whose +0x14 points here): 0
; pointers, one per letter of its signature "" -- none -- then a pointer
; to "", then the names themselves.
;
; Typed in naka_widget_tables_1.c as uint32_t
; ClassProps_IvRealRecExit[1] and char ClassProps_IvRealRecExit_Names[].
; -----------------------------------------------------------------------------
ClassProps_IvRealRecExit:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x3124, 0x6
; -----------------------------------------------------------------------------
; [naka_s_headers] Kubo_ClassTable_168
; Kubo_ClassTable_168 -- class table: InitializeKubo (v10/v9 0xf2d2c4,
; v7 0xf2d29a) (sequencer/sequencer_ui.s:4298) registers it with
; `RegObjTable 0x1600004, 0xfa44e2, (count at 0xe27596 = 26), 0xe27180,
; 0x168` -- 26 naka_class_t descriptors (naka_types.h: proc, base class,
; two u16, name, field-type letters, property data), 12 of them inside
; this blob; the table runs on into the next blob, and the 4 bytes left
; here begin descriptor 12.
;
; Typed in naka_widget_tables_1.c as naka_class_t
; Kubo_ClassTable_168[12].
; -----------------------------------------------------------------------------
Kubo_ClassTable_168:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x312A, 0x120
; -----------------------------------------------------------------------------
; [naka_s_headers] Kubo_ClassTable_168_Desc12Head
; Kubo_ClassTable_168_Desc12Head -- the first u32 (proc) of descriptor
; 12 of Kubo_ClassTable_168; the rest of that table is in the next blob.
;
; Typed in naka_widget_tables_1.c as uint32_t
; Kubo_ClassTable_168_Desc12Head[1].
; -----------------------------------------------------------------------------
Kubo_ClassTable_168_Desc12Head:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x324A, 0x4

; External label offsets within the binary blob above.
