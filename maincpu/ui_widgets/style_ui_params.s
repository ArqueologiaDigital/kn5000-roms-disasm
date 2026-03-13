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

StyleUI_ParamBlock_BAL:		.include "includes/style_ui_paramblock_bal.s"
StyleUI_ParamBlock_VALUE:	.include "includes/style_ui_paramblock_value.s"
StyleUI_ParamBlock_Common:	.include "includes/style_ui_paramblock_common.s"
StyleUI_ParamBlock_Short:	.include "includes/style_ui_paramblock_short.s"
StyleUI_ParamBlock_Extended:	.include "includes/style_ui_paramblock_extended.s"
StyleUI_ParamBlock_Medium:	.include "includes/style_ui_paramblock_medium.s"
StyleUI_ParamBlock_MEAS:	.include "includes/style_ui_paramblock_meas.s"
StyleUI_ParamBlock_AltA:	.include "includes/style_ui_paramblock_alta.s"
StyleUI_ParamBlock_AltB:	.include "includes/style_ui_paramblock_altb.s"
StyleUI_ParamBlock_AltC:	.include "includes/style_ui_paramblock_altc.s"
StyleUI_ParamBlock_AltD:	.include "includes/style_ui_paramblock_altd.s"
StyleUI_ParamBlock_AltE:	.include "includes/style_ui_paramblock_alte.s"

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

StyleUI_ScreenData_Main:	.include "includes/style_ui_screendata_main.s"
StyleUI_ScreenData_MeasCursor:	.include "includes/style_ui_screendata_meascursor.s"
StyleUI_ScreenData_YesCtl:	.include "includes/style_ui_screendata_yesctl.s"
StyleUI_ScreenData_CtlOnly:	.include "includes/style_ui_screendata_ctlonly.s"

