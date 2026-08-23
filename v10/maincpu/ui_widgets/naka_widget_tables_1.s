
; NAKA Widget Pointer Tables Part 1 (13 widgets, 12878 bytes)
; Source: maincpu/ui_widgets/naka_widget_tables_1.c (C struct with named fields)
NakaData_WidgetTables1:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x0, 0x1000
EmbeddedPtrTable_v10_naka_widget_tables_1_001000:
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
	.long 0x00E25328
	.long 0x00E25316
	.long 0x00E25306
	.long 0x00E252F6
	.long 0x00E252E6
	.long 0x00E252D4
	.long 0x00E252C6
	.long 0x00E252B6
	.long 0x00E252A6
	.long 0x00E25294
	.long 0x00E25282
	.long 0x00E25270
	.long 0x00E2525E
	.long 0x00E2524E
	.long 0x00E2523C
	.long 0x00E25228
	.long 0x00E2521A
	.long 0x00E2520E
	.long 0x00E25200
	.long 0x00E251F0
	.long 0x00E251E0
	.long 0x00E251D0
	.long 0x00E251C2
	.long 0x00E251B4
	.long 0x00E251A4
	.long 0x00E25192
	.long 0x00E25180
	.long 0x00E25170
	.long 0x00E25160
	.long 0x00E25150
	.long 0x00E25144
	.long 0x00E25142
	.long 0x7041FF00
	.long 0x79616C50
	.long 0x726F7953
	.long 0x614E0069
	.long 0x6547656D
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x1100, 0x214E

; External label offsets within the binary blob above.
	.equ NakaHdr_Perf2MeasureBoxData, NakaData_WidgetTables1 + 0x0018
	.equ NakaHdr_Perf2FileListData, NakaData_WidgetTables1 + 0x0032
	.equ NakaWidgetPtrTbl_SmfDp, NakaData_WidgetTables1 + 0x005a
	.equ MedleyDisp_Blank, NakaData_WidgetTables1 + 0x273c
	.equ PlayModeStr_Play, NakaData_WidgetTables1 + 0x2768
	.equ PlayModeStr_Pause, NakaData_WidgetTables1 + 0x2788
	.equ NakaDesc_FuncTtlNo_B, NakaData_WidgetTables1 + 0x3050
	.equ NakaDesc_Empty_C, NakaData_WidgetTables1 + 0x306c
	.equ NakaDesc_Empty_D, NakaData_WidgetTables1 + 0x3072
	.equ NakaDesc_FuncIndex, NakaData_WidgetTables1 + 0x3078
	.equ NakaDesc_Mode, NakaData_WidgetTables1 + 0x309a
	.equ NakaDesc_ColorFontPageFunc, NakaData_WidgetTables1 + 0x30aa
	.equ NakaDesc_Empty_E, NakaData_WidgetTables1 + 0x30ec
	.equ NakaDesc_Empty_F, NakaData_WidgetTables1 + 0x30f2
	.equ NakaDesc_Empty_G, NakaData_WidgetTables1 + 0x30f8
	.equ NakaDesc_Empty_H, NakaData_WidgetTables1 + 0x30fe
	.equ NakaDesc_Empty_I, NakaData_WidgetTables1 + 0x3104
	.equ NakaDesc_StyleFunc, NakaData_WidgetTables1 + 0x310a
	.equ NakaDesc_Empty_J, NakaData_WidgetTables1 + 0x3124
