
; NAKA Widget Pointer Tables Part 1 (13 widgets, 12878 bytes)
; Source: maincpu/ui_widgets/naka_widget_tables_1.c (C struct with named fields)
NakaData_WidgetTables1:
	.incbin "includes/generated/naka_widget_tables_1.bin"

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
