; =============================================================================
; file_io/composer_filters.asm - Composer Load and Filter Operations
; =============================================================================
; Composer file loading and load/save filter routines.
;
; Key routines:
;   FmmComposerLoadFunc              - Composer file loading
;   FmmLoadFilterFunc                - Load filter settings
;   FmmSaveFilterFunc                - Save filter settings
; =============================================================================

FmmComposerLoadFunc:
	.incbin "includes/generated/v7_transplant_FmmComposerLoadFunc.bin"
CompLoad_DispatchState:
	.incbin "includes/generated/v7_transplant_CompLoad_DispatchState.bin"
CompLoad_ContinueWait:
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	jrl CompLoad_DispatchWidget

CompLoad_HandleCancel:
	.incbin "includes/generated/v7_transplant_CompLoad_HandleCancel.bin"
CompLoad_HandleError:
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0x7d
	call UI_PostModeChangeEvent
	jrl CompLoad_Return

CompLoad_HandleSuccess:
	.incbin "includes/generated/v7_transplant_CompLoad_HandleSuccess.bin"
CompLoad_CallStatusDisplay:
	call SoundCtrl_SendCommand
	jrl CompLoad_Return

CompLoad_HandleAbort:
	calr CancelOperationCleanup
	jrl CompLoad_Return

CompLoad_HandleSelection:
	.incbin "includes/generated/v7_transplant_CompLoad_HandleSelection.bin"
CompLoad_Selection_Negative:
	.incbin "includes/generated/v7_transplant_CompLoad_Selection_Negative.bin"
CompLoad_HandleShow:
	lds iz, 0

CompLoad_DrawItemLoop:
	.incbin "includes/generated/v7_transplant_CompLoad_DrawItemLoop.bin"
CompLoad_DrawItem_Empty:
	lda_24 xbc, (DiskOp_ChannelCfgTable_0x80)

CompLoad_DrawItem_Continue:
	.incbin "includes/generated/v7_transplant_CompLoad_DrawItem_Continue.bin"
CompLoad_HandleScroll:
	.incbin "includes/generated/v7_transplant_CompLoad_HandleScroll.bin"
CompLoad_ScrollUp:
	cp xbc, 0x1c00017
	jrl nz, CompLoad_GetSelection
	cps wa, 0
	jrl le, CompLoad_GetSelection
	dec 1, wa
	jr CompLoad_StorePosition

CompLoad_PageScroll:
	cp xde, 0x1
	jr nz, CompLoad_PageDown
	cp wa, 0xa
	jrl lt, CompLoad_GetSelection
	sub wa, 0xa
	jr CompLoad_StorePosition

CompLoad_PageDown:
	cp xde, 0x2
	jr nz, CompLoad_OpLoad
	ld bc, wa
	add bc, 0xa
	cp bc, 0x13
	jrl gt, CompLoad_GetSelection
	add wa, 0xa

CompLoad_StorePosition:
	.incbin "includes/generated/v7_transplant_CompLoad_StorePosition.bin"
CompLoad_OpLoad:
	cp xde, 0x3
	jrl nz, CompLoad_GetSelection
	call CheckFileSystemStatus
	cps hl, 0
	jr z, CompLoad_GetSelection
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	lds iz, 0

CompLoad_HideButtons_Loop:
	.incbin "includes/generated/v7_transplant_CompLoad_HideButtons_Loop.bin"
CompLoad_GetSelection:
	.incbin "includes/generated/v7_transplant_CompLoad_GetSelection.bin"
CompLoad_UpdateDisplay:
	.incbin "includes/generated/v7_transplant_CompLoad_UpdateDisplay.bin"
CompLoad_DispatchWidget:
	call ApPostEvent

CompLoad_Return:
	lds32 xhl, 0
	popw iz
	inc 2, xsp
	ret

RenderFilterDisplay:
	dec 6, xsp
	ld (xsp), c
	ld (xsp + 2), xwa
	ld xwa, (xsp + 2)
	ld c, (xsp)
	lda_dpi XHL, 0xe0
	ld (xsp + 2), xwa
	cp (xsp), 0x0
	jr nz, RenderFilter_CheckType1
	call GetCurrentFileType
	cps l, 0
	jr z, RenderFilter_CheckType1
	ld xwa, (xsp + 2)
	ld xbc, DiskOp_ChannelCfgTable_0x82
	jrl RenderFilter_CopyAndReturn

RenderFilter_CheckType1:
	cp (xsp), 0x1
	jr nz, RenderFilter_CheckGeneric
	call GetCurrentFileType
	cps l, 0
	jr z, RenderFilter_CheckGeneric
	lds wa, 0
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, RenderFilter_Type1_Unavail
	lds wa, 0
	call FileIO_WriteRecordName_Done
	cps l, 0
	jr z, RenderFilter_Type1_Restricted
	ld xwa, (xsp + 2)
	ld xbc, DiskOp_ChannelCfgTable_0x88
	jrl RenderFilter_CopyAndReturn

RenderFilter_Type1_Restricted:
	ld xwa, (xsp + 2)
	ld xbc, DiskOp_ChannelCfgTable_0x8E
	jr RenderFilter_CopyAndReturn

RenderFilter_Type1_Unavail:
	ld xwa, (xsp + 2)
	ld xbc, DiskOp_ChannelCfgTable_0x94
	jr RenderFilter_CopyAndReturn

RenderFilter_CheckGeneric:
	ld a, (xsp)
	extz wa
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, RenderFilter_CheckType2
	ld a, (xsp)
	extz wa
	call FileIO_WriteRecordName_Done
	cps l, 0
	jr z, RenderFilter_Generic_Restricted
	ld xwa, (xsp + 2)
	ld xbc, DiskOp_ChannelCfgTable_0x9A
	jr RenderFilter_CopyAndReturn

RenderFilter_Generic_Restricted:
	ld xwa, (xsp + 2)
	ld xbc, DiskOp_ChannelCfgTable_0xA0
	jr RenderFilter_CopyAndReturn

RenderFilter_CheckType2:
	cp (xsp), 0x2
	jr nz, RenderFilter_Default
	ldw wa, 0x8
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, RenderFilter_Default
	ldw wa, 0x9
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, RenderFilter_Default
	ld a, (xsp)
	extz wa
	call FileIO_WriteRecordName_Done
	cps l, 0
	jr z, RenderFilter_Type2_Restricted
	ld xwa, (xsp + 2)
	ld xbc, DiskOp_ChannelCfgTable_0xA6
	jr RenderFilter_CopyAndReturn

RenderFilter_Type2_Restricted:
	ld xwa, (xsp + 2)
	ld xbc, DiskOp_ChannelCfgTable_0xAC
	jr RenderFilter_CopyAndReturn

RenderFilter_Default:
	ld xwa, (xsp + 2)
	ld xbc, DiskOp_ChannelCfgTable_0xB2

RenderFilter_CopyAndReturn:
	call FileIO_CopyString
	inc 6, xsp
	ret

FmmLoadFilterFunc:
	.incbin "includes/generated/v7_transplant_FmmLoadFilterFunc.bin"
LoadFilter_HandleShow:
	ldw (xsp), 0x0

LoadFilter_DrawLoop:
	.incbin "includes/generated/v7_transplant_LoadFilter_DrawLoop.bin"
LoadFilter_HandleScroll:
	ld xwa, (xsp + 2)
	cp xwa, 0x8
	jrl nc, LoadFilter_OpLoad
	cp xbc, 0x1c00017
	jr nz, LoadFilter_ScrollDown
	cp xwa, 0x1
	jr nz, LoadFilter_ScrollUp_CheckZero
	call GetCurrentFileType
	cps l, 0
	jr z, LoadFilter_ScrollUp_CheckZero
	lds wa, 0
	jr LoadFilter_ShowButton

LoadFilter_ScrollUp_CheckZero:
	ld xwa, (xsp + 2)
	or xwa, xwa
	jr nz, LoadFilter_ScrollUp_Restore
	call GetCurrentFileType
	cps l, 0
	jr nz, LoadFilter_UpdateDisplay

LoadFilter_ScrollUp_Restore:
	ld xwa, (xsp + 2)
	extz wa

LoadFilter_ShowButton:
	call FileIO_FormatName_Loop
	jr LoadFilter_UpdateDisplay

LoadFilter_ScrollDown:
	ld xwa, (xsp + 2)
	cp xwa, 0x1
	jr nz, LoadFilter_ScrollDown_CheckZero
	call GetCurrentFileType
	cps l, 0
	jr z, LoadFilter_ScrollDown_CheckZero
	lds wa, 0
	jr LoadFilter_HideButton

LoadFilter_ScrollDown_CheckZero:
	ld xwa, (xsp + 2)
	or xwa, xwa
	jr nz, LoadFilter_ScrollDown_Restore
	call GetCurrentFileType
	cps l, 0
	jr nz, LoadFilter_UpdateDisplay

LoadFilter_ScrollDown_Restore:
	ld xwa, (xsp + 2)
	extz wa

LoadFilter_HideButton:
	call FileIO_FormatName_Copy

LoadFilter_UpdateDisplay:
	.incbin "includes/generated/v7_transplant_LoadFilter_UpdateDisplay.bin"
LoadFilter_OpLoad:
	.incbin "includes/generated/v7_transplant_LoadFilter_OpLoad.bin"
LoadFilter_Load_ShowCodeA:
	ldw wa, 0xa
	jr LoadFilter_Load_CallHandler

LoadFilter_Load_ShowCode1:
	lds wa, 1

LoadFilter_Load_CallHandler:
	call UI_PostPartChangeEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0xee
	call SoundCtrl_SendCommand

LoadFilter_Return:
	lds32 xhl, 0
	inc 6, xsp
	ret

RenderSaveFilterDisplay:
	dec 6, xsp
	ld (xsp), c
	ld (xsp + 2), xwa
	ld xwa, (xsp + 2)
	ld c, (xsp)
	lda_dpi XHL, 0xe0
	ld (xsp + 2), xwa
	ld a, c
	extz wa
	call FileIO_FormatName_Return
	cps l, 0
	jr z, RenderSaveFilter_Unavail
	cp (xsp), 0x1
	jr nz, RenderSaveFilter_Available
	call FileIO_GetRecordAttr_Check
	cps l, 0
	jr z, RenderSaveFilter_Available
	ld xwa, (xsp + 2)
	ld xbc, DiskOp_ChannelCfgTable_0xB8
	jr RenderSaveFilter_CopyAndReturn

RenderSaveFilter_Available:
	ld xwa, (xsp + 2)
	ld xbc, DiskOp_ChannelCfgTable_0xBE
	jr RenderSaveFilter_CopyAndReturn

RenderSaveFilter_Unavail:
	ld xwa, (xsp + 2)
	ld xbc, DiskOp_ChannelCfgTable_0xC4

RenderSaveFilter_CopyAndReturn:
	call FileIO_CopyString
	inc 6, xsp
	ret

FmmSaveFilterFunc:
	.incbin "includes/generated/v7_transplant_FmmSaveFilterFunc.bin"
SaveFilter_HandleShow:
	ldw (xsp), 0x0

SaveFilter_DrawLoop:
	.incbin "includes/generated/v7_transplant_SaveFilter_DrawLoop.bin"
SaveFilter_HandleScroll:
	ld xwa, (xsp + 2)
	cp xwa, 0x8
	jrl nc, SaveFilter_SelectAll
	cp xwa, 0x1
	jr nz, SaveFilter_ScrollOther
	cp xbc, 0x1c00017
	jr nz, SaveFilter_ScrollDown
	call FileIO_GetRecordAttr_Check
	cps l, 0
	jr z, SaveFilter_ScrollUp_Unavail
	call FileIO_SetModeFlag_Reading
	ld xwa, (xsp + 2)
	extz wa
	jr SaveFilter_UnlockFilter

SaveFilter_ScrollUp_Unavail:
	ld xwa, (xsp + 2)
	extz wa
	jr SaveFilter_LockFilter

SaveFilter_ScrollDown:
	ld xwa, (xsp + 2)
	extz wa
	call FileIO_FormatName_Return
	cps l, 0
	jr z, SaveFilter_ScrollDown_Unlock
	call FileIO_GetRecordAttr_Check
	cps l, 0
	jr nz, SaveFilter_UpdateDisplay
	ld xwa, (xsp + 2)
	extz wa
	jr SaveFilter_UnlockFilter

SaveFilter_ScrollDown_Unlock:
	call FileIO_GetRecordAttr_Check
	cps l, 0
	jr nz, SaveFilter_UpdateDisplay
	call FileIO_SetModeFlag_Writing
	ld xwa, (xsp + 2)
	extz wa
	jr SaveFilter_LockFilter

SaveFilter_ScrollOther:
	ld xwa, (xsp + 2)
	extz wa
	cp xbc, 0x1c00017
	jr nz, SaveFilter_UnlockFilter

SaveFilter_LockFilter:
	call FileIO_BuildRecordPath_Done
	jr SaveFilter_UpdateDisplay

SaveFilter_UnlockFilter:
	call FileIO_BuildRecordPath_Return

SaveFilter_UpdateDisplay:
	.incbin "includes/generated/v7_transplant_SaveFilter_UpdateDisplay.bin"
SaveFilter_SelectAll:
	ld xwa, (xsp + 2)
	cp xwa, 0x8
	jr nz, SaveFilter_DeselectAll
	call FileIO_SetModeFlag_Reading
	ldw (xsp), 0x0

SaveFilter_SelectAll_Loop:
	ld wa, (xsp)
	extz wa
	cpw (xsp), 0x6
	jr ge, SaveFilter_SelectAll_Unlock
	call FileIO_BuildRecordPath_Done
	jr SaveFilter_SelectAll_Update

SaveFilter_SelectAll_Unlock:
	call FileIO_BuildRecordPath_Return

SaveFilter_SelectAll_Update:
	.incbin "includes/generated/v7_transplant_SaveFilter_SelectAll_Update.bin"
SaveFilter_DeselectAll:
	ld xwa, (xsp + 2)
	cp xwa, 0x9
	jr nz, SaveFilter_OpSave
	call FileIO_SetModeFlag_Reading
	ldw (xsp), 0x0

SaveFilter_DeselectAll_Loop:
	.incbin "includes/generated/v7_transplant_SaveFilter_DeselectAll_Loop.bin"
SaveFilter_OpSave:
	.incbin "includes/generated/v7_transplant_SaveFilter_OpSave.bin"
SaveFilter_Save_NoPwd:
	call CheckFileSystemStatus
	cps hl, 0
	jr z, SaveFilter_Save_Execute
	cpib_da (0x0340ea), 0x00
	jr z, SaveFilter_Save_Execute
	ld xwa, 0xffffffff
	ld xbc, 0x1c50000
	lds32 xde, 1
	call ApPostEvent
	ld xwa, 0x600037
	ld xbc, 0x1c00001
	lds32 xde, 0

SaveFilter_DispatchWidget:
	call ApPostEvent
	jrl SaveFilter_Return

SaveFilter_Save_Execute:
	.incbin "includes/generated/v7_transplant_SaveFilter_Save_Execute.bin"
SaveFilter_OpFormat:
	.incbin "includes/generated/v7_transplant_SaveFilter_OpFormat.bin"
SaveFilter_CallStatusDisplay:
	call SoundCtrl_SendCommand
	jr SaveFilter_Return

SaveFilter_ResetAll:
	ld xwa, (xsp + 2)
	cp xwa, 0xb
	jr nz, SaveFilter_Return
	call FileIO_SetModeFlag_Reading
	ldw (xsp), 0x0

SaveFilter_ResetAll_Loop:
	.incbin "includes/generated/v7_transplant_SaveFilter_ResetAll_Loop.bin"
SaveFilter_Return:
	lds32 xhl, 0
	inc 6, xsp
	ret

