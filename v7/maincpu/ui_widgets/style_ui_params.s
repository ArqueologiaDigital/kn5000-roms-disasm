; ===========================================================================
; Style UI Parameter Blocks & Screen Data
; ===========================================================================
;
; Style UI widget definitions for the accompaniment style editor.
; ParamBlock variants define different parameter layouts (BAL, VALUE, MEAS,
; Short, Medium, Extended, Common, Alt A-E). The pointer table maps UI
; screen indices to the appropriate ParamBlock.
;
; ScreenData blocks define full screen layouts (Main, MeasCursor, YesCtl,
; CtlOnly) referenced by the style editor's display system.
;
; ===========================================================================

; [nakarest] StyleUI_ParamBlock_BAL: Style-UI ScreenData bytecode -- the sd_* commands of
; [nakarest] style_ui/screendata_types.h (lines, rects, labelled refs, strings), typed in
; [nakarest] style_ui/paramblock/bal.c -- drawn by UIRender_TwoTableGeneral, which hands its
; [nakarest] xiy/xix pair to Scoop_EventLoop_12Entry (display/scoop_display.s).  Reached through
; [nakarest] StyleUI_ParamBlockPtrTable entries 0, 38.
StyleUI_ParamBlock_BAL:		.incbin "includes/generated/style_ui_paramblock_bal.bin"
; [nakarest] StyleUI_ParamBlock_VALUE: Style-UI ScreenData bytecode -- the sd_* commands of
; [nakarest] style_ui/screendata_types.h (lines, rects, labelled refs, strings), typed in
; [nakarest] style_ui/paramblock/value.c -- drawn by UIRender_TwoTableGeneral, which hands its
; [nakarest] xiy/xix pair to Scoop_EventLoop_12Entry (display/scoop_display.s).  Reached through
; [nakarest] StyleUI_ParamBlockPtrTable entries 9-10, 19, 47-48, 57.
StyleUI_ParamBlock_VALUE:	.incbin "includes/generated/style_ui_paramblock_value.bin"
; [nakarest] StyleUI_ParamBlock_Common: Style-UI ScreenData bytecode -- the sd_* commands of
; [nakarest] style_ui/screendata_types.h (lines, rects, labelled refs, strings), typed in
; [nakarest] style_ui/paramblock/common.c -- drawn by UIRender_TwoTableGeneral, which hands its
; [nakarest] xiy/xix pair to Scoop_EventLoop_12Entry (display/scoop_display.s).  Reached through
; [nakarest] StyleUI_ParamBlockPtrTable entries 4-5, 7-8, 39, 42-43, 45-46.
StyleUI_ParamBlock_Common:	.incbin "includes/generated/style_ui_paramblock_common.bin"
; [nakarest] StyleUI_ParamBlock_Short: Style-UI ScreenData bytecode -- the sd_* commands of
; [nakarest] style_ui/screendata_types.h (lines, rects, labelled refs, strings), typed in
; [nakarest] style_ui/paramblock/short.c -- drawn by UIRender_TwoTableGeneral, which hands its
; [nakarest] xiy/xix pair to Scoop_EventLoop_12Entry (display/scoop_display.s).  Reached through
; [nakarest] StyleUI_ParamBlockPtrTable entries 23-24, 27-29, 58, 61-62, 65-67.
StyleUI_ParamBlock_Short:	.incbin "includes/generated/style_ui_paramblock_short.bin"
; [nakarest] StyleUI_ParamBlock_Extended: Style-UI ScreenData bytecode -- the sd_* commands of
; [nakarest] style_ui/screendata_types.h (lines, rects, labelled refs, strings), typed in
; [nakarest] style_ui/paramblock/extended.c -- drawn by UIRender_TwoTableGeneral, which hands
; [nakarest] its xiy/xix pair to Scoop_EventLoop_12Entry (display/scoop_display.s).  Reached
; [nakarest] through StyleUI_ParamBlockPtrTable entries 2, 6, 26, 40, 44, 64.
StyleUI_ParamBlock_Extended:	.incbin "includes/generated/style_ui_paramblock_extended.bin"
; [nakarest] StyleUI_ParamBlock_Medium: Style-UI ScreenData bytecode -- the sd_* commands of
; [nakarest] style_ui/screendata_types.h (lines, rects, labelled refs, strings), typed in
; [nakarest] style_ui/paramblock/medium.c -- drawn by UIRender_TwoTableGeneral, which hands its
; [nakarest] xiy/xix pair to Scoop_EventLoop_12Entry (display/scoop_display.s).  Reached through
; [nakarest] StyleUI_ParamBlockPtrTable entries 3, 21, 25, 41, 59, 63.
StyleUI_ParamBlock_Medium:	.incbin "includes/generated/style_ui_paramblock_medium.bin"
; [nakarest] StyleUI_ParamBlock_MEAS: Style-UI ScreenData bytecode -- the sd_* commands of
; [nakarest] style_ui/screendata_types.h (lines, rects, labelled refs, strings), typed in
; [nakarest] style_ui/paramblock/meas.c -- drawn by UIRender_TwoTableGeneral, which hands its
; [nakarest] xiy/xix pair to Scoop_EventLoop_12Entry (display/scoop_display.s).  Reached through
; [nakarest] StyleUI_ParamBlockPtrTable entries 12-15, 17, 22, 50-53, 55, 60.
StyleUI_ParamBlock_MEAS:	.incbin "includes/generated/style_ui_paramblock_meas.bin"
; [nakarest] StyleUI_ParamBlock_AltA: Style-UI ScreenData bytecode -- the sd_* commands of
; [nakarest] style_ui/screendata_types.h (lines, rects, labelled refs, strings), typed in
; [nakarest] style_ui/paramblock/alta.c -- drawn by UIRender_TwoTableGeneral, which hands its
; [nakarest] xiy/xix pair to Scoop_EventLoop_12Entry (display/scoop_display.s).  Reached through
; [nakarest] StyleUI_ParamBlockPtrTable entries 31-34, 69-72.
StyleUI_ParamBlock_AltA:	.incbin "includes/generated/style_ui_paramblock_alta.bin"
; [nakarest] StyleUI_ParamBlock_AltB: Style-UI ScreenData bytecode -- the sd_* commands of
; [nakarest] style_ui/screendata_types.h (lines, rects, labelled refs, strings), typed in
; [nakarest] style_ui/paramblock/altb.c -- drawn by UIRender_TwoTableGeneral, which hands its
; [nakarest] xiy/xix pair to Scoop_EventLoop_12Entry (display/scoop_display.s).  Reached through
; [nakarest] StyleUI_ParamBlockPtrTable entries 36, 74; loaded directly by
; [nakarest] Scoop_SetupDisplayTables.
StyleUI_ParamBlock_AltB:	.incbin "includes/generated/style_ui_paramblock_altb.bin"
; [nakarest] StyleUI_ParamBlock_AltC: Style-UI ScreenData bytecode -- the sd_* commands of
; [nakarest] style_ui/screendata_types.h (lines, rects, labelled refs, strings), typed in
; [nakarest] style_ui/paramblock/altc.c -- drawn by UIRender_TwoTableGeneral, which hands its
; [nakarest] xiy/xix pair to Scoop_EventLoop_12Entry (display/scoop_display.s).  Reached through
; [nakarest] StyleUI_ParamBlockPtrTable entries 16, 54; loaded directly by
; [nakarest] Scoop_SetupDisplayTables.
StyleUI_ParamBlock_AltC:	.incbin "includes/generated/style_ui_paramblock_altc.bin"
; [nakarest] StyleUI_ParamBlock_AltD: Style-UI ScreenData bytecode -- the sd_* commands of
; [nakarest] style_ui/screendata_types.h (lines, rects, labelled refs, strings), typed in
; [nakarest] style_ui/paramblock/altd.c -- drawn by UIRender_TwoTableGeneral, which hands its
; [nakarest] xiy/xix pair to Scoop_EventLoop_12Entry (display/scoop_display.s).  Reached through
; [nakarest] StyleUI_ParamBlockPtrTable entries 18, 35, 56, 73; loaded directly by
; [nakarest] Display_RedrawStatusBar.
StyleUI_ParamBlock_AltD:	.incbin "includes/generated/style_ui_paramblock_altd.bin"
; [nakarest] StyleUI_ParamBlock_AltE: Style-UI ScreenData bytecode -- the sd_* commands of
; [nakarest] style_ui/screendata_types.h (lines, rects, labelled refs, strings), typed in
; [nakarest] style_ui/paramblock/alte.c -- drawn by UIRender_TwoTableGeneral, which hands its
; [nakarest] xiy/xix pair to Scoop_EventLoop_12Entry (display/scoop_display.s).  Reached through
; [nakarest] StyleUI_ParamBlockPtrTable entries 37, 75; loaded directly by
; [nakarest] Display_RedrawStatusBar, Scoop_InitDisplayFull.
StyleUI_ParamBlock_AltE:	.incbin "includes/generated/style_ui_paramblock_alte.bin"

; [nakarest] StyleUI_ParamBlockPtrTable: 4 tables x 19 pointers (76 entries).
; [nakarest] Scoop_InitPartDisplay and Scoop_SelectModeTable_2Part scale a mode index by 4 (`sla
; [nakarest] hl, 2`), load xiy from +0x00 and xix from +0x4c -- or from +0x98 and +0xe4 when the
; [nakarest] byte at 0x0d65 is 2 -- and hand the pair to UIRender_TwoTableGeneral;
; [nakarest] Scoop_InitDisplayFull reads it too.  Every entry is one of the ParamBlock /
; [nakarest] ScreenData objects of this file (the .long lines below).
StyleUI_ParamBlockPtrTable:
	.long StyleUI_ParamBlock_BAL
	.long StyleUI_ScreenData_MeasCursor
	.long StyleUI_ParamBlock_Extended
	.long StyleUI_ParamBlock_Medium
	.long StyleUI_ParamBlock_Common
	.long StyleUI_ParamBlock_Common
	.long StyleUI_ParamBlock_Extended
	.long StyleUI_ParamBlock_Common
	.long StyleUI_ParamBlock_Common
	.long StyleUI_ParamBlock_VALUE
	.long StyleUI_ParamBlock_VALUE
	.long StyleUI_ScreenData_YesCtl
	.long StyleUI_ParamBlock_MEAS
	.long StyleUI_ParamBlock_MEAS
	.long StyleUI_ParamBlock_MEAS
	.long StyleUI_ParamBlock_MEAS
	.long StyleUI_ParamBlock_AltC
	.long StyleUI_ParamBlock_MEAS
	.long StyleUI_ParamBlock_AltD
Scoop_SelectModeTable_2Part_Data:
	.long StyleUI_ParamBlock_VALUE
	.long StyleUI_ScreenData_YesCtl
	.long StyleUI_ParamBlock_Medium
	.long StyleUI_ParamBlock_MEAS
	.long StyleUI_ParamBlock_Short
	.long StyleUI_ParamBlock_Short
	.long StyleUI_ParamBlock_Medium
	.long StyleUI_ParamBlock_Extended
	.long StyleUI_ParamBlock_Short
	.long StyleUI_ParamBlock_Short
	.long StyleUI_ParamBlock_Short
	.long StyleUI_ScreenData_CtlOnly
	.long StyleUI_ParamBlock_AltA
	.long StyleUI_ParamBlock_AltA
	.long StyleUI_ParamBlock_AltA
	.long StyleUI_ParamBlock_AltA
	.long StyleUI_ParamBlock_AltD
	.long StyleUI_ParamBlock_AltB
	.long StyleUI_ParamBlock_AltE
Scoop_InitPartDisplay_Data:
	.long StyleUI_ParamBlock_BAL
	.long StyleUI_ParamBlock_Common
	.long StyleUI_ParamBlock_Extended
	.long StyleUI_ParamBlock_Medium
	.long StyleUI_ParamBlock_Common
	.long StyleUI_ParamBlock_Common
	.long StyleUI_ParamBlock_Extended
	.long StyleUI_ParamBlock_Common
	.long StyleUI_ParamBlock_Common
	.long StyleUI_ParamBlock_VALUE
	.long StyleUI_ParamBlock_VALUE
	.long StyleUI_ScreenData_YesCtl
	.long StyleUI_ParamBlock_MEAS
	.long StyleUI_ParamBlock_MEAS
	.long StyleUI_ParamBlock_MEAS
	.long StyleUI_ParamBlock_MEAS
	.long StyleUI_ParamBlock_AltC
	.long StyleUI_ParamBlock_MEAS
	.long StyleUI_ParamBlock_AltD
Scoop_SelectModeTable_2Part_Data_2:
	.long StyleUI_ParamBlock_VALUE
	.long StyleUI_ParamBlock_Short
	.long StyleUI_ParamBlock_Medium
	.long StyleUI_ParamBlock_MEAS
	.long StyleUI_ParamBlock_Short
	.long StyleUI_ParamBlock_Short
	.long StyleUI_ParamBlock_Medium
	.long StyleUI_ParamBlock_Extended
	.long StyleUI_ParamBlock_Short
	.long StyleUI_ParamBlock_Short
	.long StyleUI_ParamBlock_Short
	.long StyleUI_ScreenData_CtlOnly
	.long StyleUI_ParamBlock_AltA
	.long StyleUI_ParamBlock_AltA
	.long StyleUI_ParamBlock_AltA
	.long StyleUI_ParamBlock_AltA
	.long StyleUI_ParamBlock_AltD
	.long StyleUI_ParamBlock_AltB
	.long StyleUI_ParamBlock_AltE

; [nakarest] StyleUI_ScreenData_Main: Style-UI ScreenData bytecode -- the sd_* commands of
; [nakarest] style_ui/screendata_types.h (lines, rects, labelled refs, strings), typed in
; [nakarest] style_ui/main.c -- drawn by UIRender_TwoTableGeneral, which hands its xiy/xix pair
; [nakarest] to Scoop_EventLoop_12Entry (display/scoop_display.s).  Reached through no
; [nakarest] StyleUI_ParamBlockPtrTable entry; loaded directly by
; [nakarest] Scoop_TitleBar_DisplayPartTable.
StyleUI_ScreenData_Main:		.incbin "includes/generated/style_ui_screendata_main.bin", 0x0, 0xB4
Scoop_TitleBar_GetPartConfig_Data:	.incbin "includes/generated/style_ui_screendata_main.bin", 0xB4, 0x10E
Scoop_TitleBar_ShowBPM_Part0_Data:	.incbin "includes/generated/style_ui_screendata_main.bin", 0x1C2, 0xA
Scoop_TitleBar_ShowBPM_Part1_Data:	.incbin "includes/generated/style_ui_screendata_main.bin", 0x1CC, 0xA
Scoop_TitleBar_ShowBPM_Part2_Data:	.incbin "includes/generated/style_ui_screendata_main.bin", 0x1D6, 0xA
Display_RedrawTitleBar_Data:		.incbin "includes/generated/style_ui_screendata_main.bin", 0x1E0, 0x5
Scoop_TitleBar_Part1Check_Data:		.incbin "includes/generated/style_ui_screendata_main.bin", 0x1E5, 0x5
Scoop_TitleBar_Part2Check_Data:		.incbin "includes/generated/style_ui_screendata_main.bin", 0x1EA, 0x5
Scoop_InitPartDisplay_Data_2:		.incbin "includes/generated/style_ui_screendata_main.bin", 0x1EF, 0xA
Display_RedrawMainContent_Data:		.incbin "includes/generated/style_ui_screendata_main.bin", 0x1F9, 0x23
Display_RedrawFooter_Data:		.incbin "includes/generated/style_ui_screendata_main.bin", 0x21C, 0x3C
Display_RedrawFooter_Data_2:		.incbin "includes/generated/style_ui_screendata_main.bin", 0x258, 0x1E
Scoop_FooterShowPartValue_Data:		.incbin "includes/generated/style_ui_screendata_main.bin", 0x276, 0x168
Display_RedrawButtonLabels_Data:	.incbin "includes/generated/style_ui_screendata_main.bin", 0x3DE, 0x168
Display_RedrawButtonLabels_Data_2:	.incbin "includes/generated/style_ui_screendata_main.bin", 0x546, 0x168
Display_RedrawButtonLabels_Data_3:	.incbin "includes/generated/style_ui_screendata_main.bin", 0x6AE, 0x2D0
Scoop_Selection_RedrawActive_Data:	.incbin "includes/generated/style_ui_screendata_main.bin", 0x97E, 0x8
Scoop_Selection_RedrawActive_Data_2:	.incbin "includes/generated/style_ui_screendata_main.bin", 0x986, 0xA
Scoop_Selection_DrawMode1_Data:		.incbin "includes/generated/style_ui_screendata_main.bin", 0x990, 0x2B
Scoop_Selection_RedrawActive_Data_3:	.incbin "includes/generated/style_ui_screendata_main.bin", 0x9BB, 0x4B
Scoop_Selection_DrawMode1_Data_2:	.incbin "includes/generated/style_ui_screendata_main.bin", 0xA06, 0x113
Scoop_SidePanel_StoreAndDraw_Data:	.incbin "includes/generated/style_ui_screendata_main.bin", 0xB19, 0x21
Scoop_SidePanel_StoreAndDraw_Data_2:	.incbin "includes/generated/style_ui_screendata_main.bin", 0xB3A, 0x5A
Scoop_SidePanel_DrawOneSlot_Data:	.incbin "includes/generated/style_ui_screendata_main.bin", 0xB94, 0x40
Display_RedrawButtonLabels_Data_4:	.incbin "includes/generated/style_ui_screendata_main.bin", 0xBD4, 0x168
Display_RedrawButtonLabels_Data_5:	.incbin "includes/generated/style_ui_screendata_main.bin", 0xD3C, 0x3
Scoop_SelectModeTable_2Part_XIX_Data:	.incbin "includes/generated/style_ui_screendata_main.bin", 0xD3F, 0x8C
; [nakarest] StyleUI_ScreenData_MeasCursor: Style-UI ScreenData bytecode -- the sd_* commands of
; [nakarest] style_ui/screendata_types.h (lines, rects, labelled refs, strings), typed in
; [nakarest] style_ui/meascursor.c -- drawn by UIRender_TwoTableGeneral, which hands its xiy/xix
; [nakarest] pair to Scoop_EventLoop_12Entry (display/scoop_display.s).  Reached through
; [nakarest] StyleUI_ParamBlockPtrTable entries 1; loaded directly by
; [nakarest] Scoop_SelectModeTable_2Part_XIX.
StyleUI_ScreenData_MeasCursor:	.incbin "includes/generated/style_ui_screendata_meascursor.bin"
; [nakarest] StyleUI_ScreenData_YesCtl: Style-UI ScreenData bytecode -- the sd_* commands of
; [nakarest] style_ui/screendata_types.h (lines, rects, labelled refs, strings), typed in
; [nakarest] style_ui/yesctl.c -- drawn by UIRender_TwoTableGeneral, which hands its xiy/xix
; [nakarest] pair to Scoop_EventLoop_12Entry (display/scoop_display.s).  Reached through
; [nakarest] StyleUI_ParamBlockPtrTable entries 11, 20, 49.
StyleUI_ScreenData_YesCtl:	.incbin "includes/generated/style_ui_screendata_yesctl.bin"
; [nakarest] StyleUI_ScreenData_CtlOnly: Style-UI ScreenData bytecode -- the sd_* commands of
; [nakarest] style_ui/screendata_types.h (lines, rects, labelled refs, strings), typed in
; [nakarest] style_ui/ctlonly.c -- drawn by UIRender_TwoTableGeneral, which hands its xiy/xix
; [nakarest] pair to Scoop_EventLoop_12Entry (display/scoop_display.s).  Reached through
; [nakarest] StyleUI_ParamBlockPtrTable entries 30, 68.
StyleUI_ScreenData_CtlOnly:			.incbin "includes/generated/style_ui_screendata_ctlonly.bin", 0x0, 0x20
Display_RedrawAltContent_Str_END:		.incbin "includes/generated/style_ui_screendata_ctlonly.bin", 0x20, 0x3
Scoop_CurveUpdate_Finalize_Data:		.incbin "includes/generated/style_ui_screendata_ctlonly.bin", 0x23, 0x100
Scoop_EnvCalc_Handler1_Data:			.incbin "includes/generated/style_ui_screendata_ctlonly.bin", 0x123, 0x8
Scoop_GlideParam_Configure_Data:		.incbin "includes/generated/style_ui_screendata_ctlonly.bin", 0x12B, 0x8
Scoop_GlideCalc_Handler0_Data:			.incbin "includes/generated/style_ui_screendata_ctlonly.bin", 0x133, 0x8
Scoop_EventLoop_12Entry_Data:			.incbin "includes/generated/style_ui_screendata_ctlonly.bin", 0x13B, 0x90
Scoop_EventLoop_12Entry_Process_Data:		.incbin "includes/generated/style_ui_screendata_ctlonly.bin", 0x1CB, 0x8
Scoop_EventLoop_12Entry_Process_Str_Fmt1d:	.incbin "includes/generated/style_ui_screendata_ctlonly.bin", 0x1D3, 0x4
Scoop_EventLoop_12Entry_Process_Str_Fmt2d:	.incbin "includes/generated/style_ui_screendata_ctlonly.bin", 0x1D7, 0x4
Scoop_EventLoop_12Entry_Process_Str_Fmt3d:	.incbin "includes/generated/style_ui_screendata_ctlonly.bin", 0x1DB, 0x4
Scoop_EventLoop_12Entry_Process_Data_2:		.incbin "includes/generated/style_ui_screendata_ctlonly.bin", 0x1DF, 0x8
Scoop_EventLoop_12Entry_Process_Str_Fmt1d_2:	.incbin "includes/generated/style_ui_screendata_ctlonly.bin", 0x1E7, 0x4
Scoop_EventLoop_12Entry_Process_Str_Fmt2d_2:	.incbin "includes/generated/style_ui_screendata_ctlonly.bin", 0x1EB, 0x4
Scoop_EventLoop_12Entry_Process_Str_Fmt3d_2:	.incbin "includes/generated/style_ui_screendata_ctlonly.bin", 0x1EF, 0x4
Scoop_EventLoop_12Entry_Process_Str_Fmt2d_3:	.incbin "includes/generated/style_ui_screendata_ctlonly.bin", 0x1F3, 0x4
Scoop_EventLoop_12Entry_Process_Str_Fmt3d_3:	.incbin "includes/generated/style_ui_screendata_ctlonly.bin", 0x1F7, 0x4
Scoop_EventLoop_12Entry_Process_Str_Fmt4d:	.incbin "includes/generated/style_ui_screendata_ctlonly.bin", 0x1FB, 0x4
Scoop_EventLoop_36Entry_Data_2:			.incbin "includes/generated/style_ui_screendata_ctlonly.bin", 0x1FF, 0x8
Scoop_EventLoop_36Entry_Str_Fmt1d:		.incbin "includes/generated/style_ui_screendata_ctlonly.bin", 0x207, 0x4
Scoop_EventLoop_36Entry_Branch1_Str_Fmt2d:	.incbin "includes/generated/style_ui_screendata_ctlonly.bin", 0x20B, 0x8
Scoop_EventLoop_36Entry_Branch3_Data_4:		.incbin "includes/generated/style_ui_screendata_ctlonly.bin", 0x213, 0x8
Scoop_EventLoop_36Entry_Branch3_Str_Fmt1d_3:	.incbin "includes/generated/style_ui_screendata_ctlonly.bin", 0x21B, 0x4
Scoop_EventLoop_36Entry_Branch3_Str_Fmt2d_4:	.incbin "includes/generated/style_ui_screendata_ctlonly.bin", 0x21F, 0x4
Scoop_EventLoop_36Entry_Branch3_Str_Fmt3d_4:	.incbin "includes/generated/style_ui_screendata_ctlonly.bin", 0x223, 0x4

