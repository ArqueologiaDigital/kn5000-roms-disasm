
; NAKA Widget Pointer Tables Part 1 (13 widgets, 12878 bytes)
; Source: maincpu/ui_widgets/naka_widget_tables_1.c (C struct with named fields)
NakaData_WidgetTables1:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x0, 0x18
NakaHdr_Perf2MeasureBoxData:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x18, 0x1A
NakaHdr_Perf2FileListData:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x32, 0x28
NakaWidgetPtrTbl_SmfDp:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x5A, 0xFA6
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
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x1100, 0x163C
MedleyDisp_Blank:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x273C, 0x2C
PlayModeStr_Play:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2768, 0x20
PlayModeStr_Pause:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x2788, 0x8C8
NakaDesc_FuncTtlNo_B:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x3050, 0x1C
NakaDesc_Empty_C:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x306C, 0x6
NakaDesc_Empty_D:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x3072, 0x6
NakaDesc_FuncIndex:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x3078, 0x22
NakaDesc_Mode:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x309A, 0x10
NakaDesc_ColorFontPageFunc:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x30AA, 0x42
NakaDesc_Empty_E:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x30EC, 0x6
NakaDesc_Empty_F:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x30F2, 0x6
NakaDesc_Empty_G:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x30F8, 0x6
NakaDesc_Empty_H:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x30FE, 0x6
NakaDesc_Empty_I:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x3104, 0x6
NakaDesc_StyleFunc:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x310A, 0x1A
NakaDesc_Empty_J:
	.incbin "includes/generated/naka_widget_tables_1.bin", 0x3124, 0x12A

; External label offsets within the binary blob above.
