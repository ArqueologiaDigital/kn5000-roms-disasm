
; NAKA Widget Pointer Tables Part 1 (13 widgets, 12878 bytes)
; Source: maincpu/ui_widgets/naka_widget_tables_1.c (C struct with named fields)
NakaData_WidgetTables1:
	.incbin "includes/generated/naka_widget_tables_1.bin"

; External label offsets within the binary blob above.
	.equ NakaHdr_Perf2MeasureBoxData, NakaData_WidgetTables1 + 0x0018
	.equ NakaHdr_Perf2FileListData, NakaData_WidgetTables1 + 0x0032
	.equ NakaWidgetPtrTbl_SmfDp, NakaData_WidgetTables1 + 0x005A
	.equ MedleyDisp_Blank, NakaData_WidgetTables1 + 0x273C
	.equ PlayModeStr_Play, NakaData_WidgetTables1 + 0x2768
	.equ PlayModeStr_Pause, NakaData_WidgetTables1 + 0x2788
	.equ NakaDesc_FuncTtlNo_B, NakaData_WidgetTables1 + 0x3050
	.equ NakaDesc_Empty_C, NakaData_WidgetTables1 + 0x306C
	.equ NakaDesc_Empty_D, NakaData_WidgetTables1 + 0x3072
	.equ NakaDesc_FuncIndex, NakaData_WidgetTables1 + 0x3078
	.equ NakaDesc_Mode, NakaData_WidgetTables1 + 0x309A
	.equ NakaDesc_ColorFontPageFunc, NakaData_WidgetTables1 + 0x30AA
	.equ NakaDesc_Empty_E, NakaData_WidgetTables1 + 0x30EC
	.equ NakaDesc_Empty_F, NakaData_WidgetTables1 + 0x30F2
	.equ NakaDesc_Empty_G, NakaData_WidgetTables1 + 0x30F8
	.equ NakaDesc_Empty_H, NakaData_WidgetTables1 + 0x30FE
	.equ NakaDesc_Empty_I, NakaData_WidgetTables1 + 0x3104
	.equ NakaDesc_StyleFunc, NakaData_WidgetTables1 + 0x310A
	.equ NakaDesc_Empty_J, NakaData_WidgetTables1 + 0x3124
