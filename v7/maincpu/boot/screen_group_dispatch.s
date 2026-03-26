; =============================================================================
; Screen Group Dispatch
; =============================================================================
;
; Boot screen group dispatcher for startup screens and error
; dialogs. Also contains the system reinitialization routine
; called during display mode transitions.
; =============================================================================

ScreenGroup_ReInit:
	.incbin "includes/generated/v7_transplant_ScreenGroup_ReInit.bin"
ScreenGroup_Dispatch:
ScreenGroup_DispatchAlt:
	.incbin "includes/generated/v7_transplant_ScreenGroup_DispatchAlt.bin"
ScreenGroup_SetupWidgetPtr:
	.incbin "includes/generated/v7_transplant_ScreenGroup_SetupWidgetPtr.bin"
VoiceInit_Dispatch:
	.incbin "includes/generated/v7_transplant_VoiceInit_Dispatch.bin"
ScreenGroup_WidgetLoop:
	.incbin "includes/generated/v7_transplant_ScreenGroup_WidgetLoop.bin"
ScreenGroup_InitState:
	.incbin "includes/generated/v7_transplant_ScreenGroup_InitState.bin"
ScreenGroup_InitVoiceLoop:
	.incbin "includes/generated/v7_transplant_ScreenGroup_InitVoiceLoop.bin"
ScreenGroup_InitParams16:
	.incbin "includes/generated/v7_transplant_ScreenGroup_InitParams16.bin"
ScreenGroup_InitParam16Loop:
	.incbin "includes/generated/v7_transplant_ScreenGroup_InitParam16Loop.bin"
ScreenGroup_InitParams8:
	.incbin "includes/generated/v7_transplant_ScreenGroup_InitParams8.bin"
ScreenGroup_InitParam8Loop:
	.incbin "includes/generated/v7_transplant_ScreenGroup_InitParam8Loop.bin"
ScreenGroup_InitParams8Complex:
	.incbin "includes/generated/v7_transplant_ScreenGroup_InitParams8Complex.bin"
ScreenGroup_InitParam8ComplexLoop:
	.incbin "includes/generated/v7_transplant_ScreenGroup_InitParam8ComplexLoop.bin"
ScreenGroup_FinalInit:
	.incbin "includes/generated/v7_transplant_ScreenGroup_FinalInit.bin"
ScreenGroup_InitWordPairsLoop:
	.incbin "includes/generated/v7_transplant_ScreenGroup_InitWordPairsLoop.bin"
ScreenGroup_InitFinalize:
	.incbin "includes/generated/v7_block_screengroup_initfinalize.bin"
