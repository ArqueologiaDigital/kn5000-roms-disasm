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

StyleUI_ParamBlock_BAL:		.incbin "includes/generated/style_ui_paramblock_bal.bin"
StyleUI_ParamBlock_VALUE:	.incbin "includes/generated/style_ui_paramblock_value.bin"
StyleUI_ParamBlock_Common:	.incbin "includes/generated/style_ui_paramblock_common.bin"
StyleUI_ParamBlock_Short:	.incbin "includes/generated/style_ui_paramblock_short.bin"
StyleUI_ParamBlock_Extended:	.incbin "includes/generated/style_ui_paramblock_extended.bin"
StyleUI_ParamBlock_Medium:	.incbin "includes/generated/style_ui_paramblock_medium.bin"
StyleUI_ParamBlock_MEAS:	.incbin "includes/generated/style_ui_paramblock_meas.bin"
StyleUI_ParamBlock_AltA:	.incbin "includes/generated/style_ui_paramblock_alta.bin"
StyleUI_ParamBlock_AltB:	.incbin "includes/generated/style_ui_paramblock_altb.bin"
StyleUI_ParamBlock_AltC:	.incbin "includes/generated/style_ui_paramblock_altc.bin"
StyleUI_ParamBlock_AltD:	.incbin "includes/generated/style_ui_paramblock_altd.bin"
StyleUI_ParamBlock_AltE:	.incbin "includes/generated/style_ui_paramblock_alte.bin"

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

StyleUI_ScreenData_Main:	.incbin "includes/generated/style_ui_screendata_main.bin"
StyleUI_ScreenData_MeasCursor:	.incbin "includes/generated/style_ui_screendata_meascursor.bin"
StyleUI_ScreenData_YesCtl:	.incbin "includes/generated/style_ui_screendata_yesctl.bin"
StyleUI_ScreenData_CtlOnly:	.incbin "includes/generated/style_ui_screendata_ctlonly.bin"

