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
	dec 2, xsp
	pushw iz
	cp xbc, 0x1c00018
	jrl z, CompLoad_HandleScroll
	cp xbc, 0x1c00017
	jrl z, CompLoad_HandleScroll
	cp xbc, 0x1c0000b
	jrl z, CompLoad_HandleShow
	cp xbc, 0x1e50004
	jrl z, CompLoad_HandleSelection
	cp xbc, 0x1c00013
	jrl nz, CompLoad_Return
	cp xde, 0x3
	jrl z, CompLoad_HandleAbort
	cp xde, 0x2
	jrl nz, CompLoad_Return
	ld (0x84fe:16), 0
	ld wa, 1:i3
	calr InitializeOperationState
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	ld xde, 5:i3
	call ApPostEvent
	cpw (0x8500:16), 0
	jr ge, CompLoad_DispatchState
	call GetDiskSizeInfo
	extz hl
	ld (0x8500:16), hl
	calr SignalProgressUpdate

CompLoad_DispatchState:
	ld wa, (0x8500:16)
	cp wa, 1:i3
	jrl z, CompLoad_HandleSuccess
	cp wa, 0:i3
	jr z, CompLoad_HandleError
	cp wa, 5:i3
	jr z, CompLoad_HandleCancel
	cpw (0x8502:16), 0
	jr ge, CompLoad_ContinueWait
	call GetEncodedFileSizeData
	ld (0x8502:16), hl
	call FileIO_SearchAndLoadFile
	call GetEncodedFreeSpaceData
	calr SignalProgressUpdate

CompLoad_ContinueWait:
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	ld xde, 0:i3
	jrl CompLoad_DispatchWidget

CompLoad_HandleCancel:
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	ld xde, 1:i3
	call ApPostEvent
	ld wa, 1:i3
	call UI_PostPartChangeEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	ld xde, 0:i3
	call ApPostEvent
	ld (0x7f42:16), 0
	ldw wa, 0xee
	jr CompLoad_CallStatusDisplay

CompLoad_HandleError:
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	ld xde, 0:i3
	call ApPostEvent
	ldw wa, 0x7d
	call UI_PostModeChangeEvent
	jrl CompLoad_Return

CompLoad_HandleSuccess:
	calr ResetProgressIndication
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	ld xde, 1:i3
	call ApPostEvent
	ld wa, 1:i3
	call UI_PostPartChangeEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	ld xde, 0:i3
	call ApPostEvent
	ld (0x7f42:16), 2
	ldw wa, 0xee

CompLoad_CallStatusDisplay:
	call SoundCtrl_SendCommand
	jrl CompLoad_Return

CompLoad_HandleAbort:
	calr CancelOperationCleanup
	jrl CompLoad_Return

CompLoad_HandleSelection:
	ld (0x7f7c:16), xde
	call GetCurrentFileIndex
	ld (0x7f80:16), hl
	cp hl, 0:i3
	jr lt, CompLoad_Selection_Negative
	exts xhl
	ld xwa, (0x7f7c:16)
	ld xbc, 0x1e50002
	ld xde, xhl
	jrl CompLoad_DispatchWidget

CompLoad_Selection_Negative:
	ldw (0x7f80:16), 0
	ld xwa, (0x7f7c:16)
	ld xbc, 0x1e50002
	ld xde, 0:i3
	jrl CompLoad_DispatchWidget

CompLoad_HandleShow:
	ld iz, 0:i3

CompLoad_DrawItemLoop:
	ld wa, iz
	ld hl, wa
	sll hl, 5
	lda xde, (0x850c:16)
	extz xhl
	add xhl, xde
	stb_erp C, 0xf8
	ld (xhl), c
	ld bc, 3:i3
	call FileIO_CheckRecordByFile
	cp l, 0:i3
	jr z, CompLoad_DrawItem_Empty
	ld wa, iz
	call GetFileEntryPtr
	ld xbc, xhl
	jr CompLoad_DrawItem_Continue

CompLoad_DrawItem_Empty:
	lda xbc, (DiskOp_ChannelCfgTable_0x80:24)

CompLoad_DrawItem_Continue:
	ld de, iz
	ld wa, de
	sll wa, 5
	ld hl, 1:i3
	add hl, wa
	lda xix, (0x850c:16)
	extz xhl
	add xhl, xix
	inc 1, de
	pushw 0x6
	pushw 0x0
	ld xwa, xhl
	call FileIO_ReadHeader_ParseLoop
	ld de, iz
	sll de, 5
	lda xbc, (0x850c:16)
	extz xde
	add xde, xbc
	ld xwa, (0x7f7c:16)
	ld xbc, 0x1c0000f
	call ApPostEvent
	inc 1, iz
	cp iz, 0x14
	jr lt, CompLoad_DrawItemLoop
	jrl CompLoad_Return

CompLoad_HandleScroll:
	ld wa, (0x7f80:16)
	ld (xsp + 2), wa
	or xde, xde
	jr nz, CompLoad_PageScroll
	cp xbc, 0x1c00018
	jr nz, CompLoad_ScrollUp
	cp wa, 0x13
	jrl ge, CompLoad_GetSelection
	inc 1, wa
	jr CompLoad_StorePosition

CompLoad_ScrollUp:
	cp xbc, 0x1c00017
	jrl nz, CompLoad_GetSelection
	cp wa, 0:i3
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
	ld (0x7f80:16), wa
	jrl CompLoad_UpdateDisplay

CompLoad_OpLoad:
	cp xde, 0x3
	jrl nz, CompLoad_GetSelection
	call CheckFileSystemStatus
	cp hl, 0:i3
	jr z, CompLoad_GetSelection
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	ld xde, 5:i3
	call ApPostEvent
	ld iz, 0:i3

CompLoad_HideButtons_Loop:
	stb_erp A, 0xf8
	extz wa
	call FileIO_FormatName_Copy
	inc 1, iz
	cp iz, 0x8
	jr lt, CompLoad_HideButtons_Loop
	ld wa, 3:i3
	call FileIO_FormatName_Loop
	ld wa, 0:i3
	calr InitializeOperationState
	call FileIO_ParseDirectoryEntry
	ld wa, hl
	ld bc, 1:i3
	calr FileIO_ValidateSignedValue
	ld (0x7f42:16), l
	calr SignalProgressUpdate
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	ld xde, 1:i3
	call ApPostEvent
	ld wa, 1:i3
	call UI_PostPartChangeEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	ld xde, 0:i3
	call ApPostEvent
	ldw wa, 0xee
	call SoundCtrl_SendCommand

CompLoad_GetSelection:
	ld wa, (0x7f80:16)

CompLoad_UpdateDisplay:
	cp (xsp + 2), wa
	jr z, CompLoad_Return
	call NotifyUIOfSelectionChange
	ld de, (0x7f80:16)
	exts xde
	ld xwa, (0x7f7c:16)
	ld xbc, 0x1e50002
	call ApPostEvent
	ld de, (xsp + 2)
	sll de, 5
	lda xbc, (0x850c:16)
	extz xde
	add xde, xbc
	ld xwa, (0x7f7c:16)
	ld xbc, 0x1c0000f
	call ApPostEvent
	ld de, (0x7f80:16)
	sll de, 5
	lda xbc, (0x850c:16)
	extz xde
	add xde, xbc
	ld xwa, (0x7f7c:16)
	ld xbc, 0x1c0000f

CompLoad_DispatchWidget:
	call ApPostEvent

CompLoad_Return:
	ld xhl, 0:i3
	popw iz
	inc 2, xsp
	ret

RenderFilterDisplay:
	dec 6, xsp
	ld (xsp), c
	ld (xsp + 2), xwa
	ld xwa, (xsp + 2)
	ld c, (xsp)
	ld (xwa+), c
	ld (xsp + 2), xwa
	cp (xsp), 0x0
	jr nz, RenderFilter_CheckType1
	call GetCurrentFileType
	cp l, 0:i3
	jr z, RenderFilter_CheckType1
	ld xwa, (xsp + 2)
	ld xbc, DiskOp_ChannelCfgTable_0x82
	jrl RenderFilter_CopyAndReturn

RenderFilter_CheckType1:
	cp (xsp), 0x1
	jr nz, RenderFilter_CheckGeneric
	call GetCurrentFileType
	cp l, 0:i3
	jr z, RenderFilter_CheckGeneric
	ld wa, 0:i3
	call FileIO_CheckRecordValid
	cp l, 0:i3
	jr z, RenderFilter_Type1_Unavail
	ld wa, 0:i3
	call FileIO_WriteRecordName_Done
	cp l, 0:i3
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
	cp l, 0:i3
	jr z, RenderFilter_CheckType2
	ld a, (xsp)
	extz wa
	call FileIO_WriteRecordName_Done
	cp l, 0:i3
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
	cp l, 0:i3
	jr z, RenderFilter_Default
	ldw wa, 0x9
	call FileIO_CheckRecordValid
	cp l, 0:i3
	jr z, RenderFilter_Default
	ld a, (xsp)
	extz wa
	call FileIO_WriteRecordName_Done
	cp l, 0:i3
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
	dec 6, xsp
	ld (xsp + 2), xde
	cp xbc, 0x1c00018
	jr z, LoadFilter_HandleScroll
	cp xbc, 0x1c00017
	jr z, LoadFilter_HandleScroll
	cp xbc, 0x1c0000b
	jr z, LoadFilter_HandleShow
	cp xbc, 0x1e50004
	jrl nz, LoadFilter_Return
	ld xwa, (xsp + 2)
	ld (0x7f82:16), xwa
	jrl LoadFilter_Return

LoadFilter_HandleShow:
	ldw (xsp), 0x0

LoadFilter_DrawLoop:
	ld wa, (xsp)
	sll wa, 4
	lda xbc, (0x7f86:16)
	extz xwa
	add xwa, xbc
	ld bc, (xsp)
	extz bc
	calr RenderFilterDisplay
	ld de, (xsp)
	sll de, 4
	lda xbc, (0x7f86:16)
	extz xde
	add xde, xbc
	ld xwa, (0x7f82:16)
	ld xbc, 0x1c0000f
	call ApPostEvent
	incw 1, (xsp)
	cpw (xsp), 0x8
	jr lt, LoadFilter_DrawLoop
	jrl LoadFilter_Return

LoadFilter_HandleScroll:
	ld xwa, (xsp + 2)
	cp xwa, 0x8
	jrl nc, LoadFilter_OpLoad
	cp xbc, 0x1c00017
	jr nz, LoadFilter_ScrollDown
	cp xwa, 0x1
	jr nz, LoadFilter_ScrollUp_CheckZero
	call GetCurrentFileType
	cp l, 0:i3
	jr z, LoadFilter_ScrollUp_CheckZero
	ld wa, 0:i3
	jr LoadFilter_ShowButton

LoadFilter_ScrollUp_CheckZero:
	ld xwa, (xsp + 2)
	or xwa, xwa
	jr nz, LoadFilter_ScrollUp_Restore
	call GetCurrentFileType
	cp l, 0:i3
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
	cp l, 0:i3
	jr z, LoadFilter_ScrollDown_CheckZero
	ld wa, 0:i3
	jr LoadFilter_HideButton

LoadFilter_ScrollDown_CheckZero:
	ld xwa, (xsp + 2)
	or xwa, xwa
	jr nz, LoadFilter_ScrollDown_Restore
	call GetCurrentFileType
	cp l, 0:i3
	jr nz, LoadFilter_UpdateDisplay

LoadFilter_ScrollDown_Restore:
	ld xwa, (xsp + 2)
	extz wa

LoadFilter_HideButton:
	call FileIO_FormatName_Copy

LoadFilter_UpdateDisplay:
	ld xwa, (xsp + 2)
	ld c, a
	extz bc
	ld wa, bc
	sla wa, 4
	lda xde, (0x7f86:16)
	exts xwa
	add xwa, xde
	calr RenderFilterDisplay
	ld xwa, (xsp + 2)
	extz wa
	sla wa, 4
	lda xbc, (0x7f86:16)
	lda_dri XDE, 0x07, 0xe4, 0xe0
	ld xwa, (0x7f82:16)
	ld xbc, 0x1c0000f
	call ApPostEvent
	jrl LoadFilter_Return

LoadFilter_OpLoad:
	ld xwa, (xsp + 2)
	cp xwa, 0xa
	jrl nz, LoadFilter_Return
	call CheckFileSystemStatus
	cp hl, 0:i3
	jrl z, LoadFilter_Return
	call FileIO_WriteRecordName_Loop
	cp hl, 0:i3
	jrl z, LoadFilter_Return
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	ld xde, 5:i3
	call ApPostEvent
	call GetCurrentFileIndex
	extz hl
	ld wa, hl
	calr FileIO_MidiOutSendByte
	ld wa, 0:i3
	calr InitializeOperationState
	call FileIO_ParseDirectoryEntry
	ld wa, hl
	ld bc, 1:i3
	calr FileIO_ValidateSignedValue
	ld (0x7f42:16), l
	calr SignalProgressUpdate
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	ld xde, 1:i3
	call ApPostEvent
	cpw (0xf19e:16), 0
	jr z, LoadFilter_Load_ShowCode1
	ld wa, 2:i3
	call FileIO_WriteRecordName_Done
	cp l, 0:i3
	jr z, LoadFilter_Load_ShowCode1
	ld wa, 2:i3
	call FileIO_CheckRecordValid
	cp l, 0:i3
	jr nz, LoadFilter_Load_ShowCodeA
	ldw wa, 0x8
	call FileIO_CheckRecordValid
	cp l, 0:i3
	jr z, LoadFilter_Load_ShowCode1

LoadFilter_Load_ShowCodeA:
	ldw wa, 0xa
	jr LoadFilter_Load_CallHandler

LoadFilter_Load_ShowCode1:
	ld wa, 1:i3

LoadFilter_Load_CallHandler:
	call UI_PostPartChangeEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	ld xde, 0:i3
	call ApPostEvent
	ldw wa, 0xee
	call SoundCtrl_SendCommand

LoadFilter_Return:
	ld xhl, 0:i3
	inc 6, xsp
	ret

RenderSaveFilterDisplay:
	dec 6, xsp
	ld (xsp), c
	ld (xsp + 2), xwa
	ld xwa, (xsp + 2)
	ld c, (xsp)
	ld (xwa+), c
	ld (xsp + 2), xwa
	ld a, c
	extz wa
	call FileIO_FormatName_Return
	cp l, 0:i3
	jr z, RenderSaveFilter_Unavail
	cp (xsp), 0x1
	jr nz, RenderSaveFilter_Available
	call FileIO_GetRecordAttr_Check
	cp l, 0:i3
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
	dec 6, xsp
	ld (xsp + 2), xde
	cp xbc, 0x1c00018
	jr z, SaveFilter_HandleScroll
	cp xbc, 0x1c00017
	jr z, SaveFilter_HandleScroll
	cp xbc, 0x1c0000b
	jr z, SaveFilter_HandleShow
	cp xbc, 0x1e50004
	jrl nz, SaveFilter_Return
	ld xwa, (xsp + 2)
	ld (0x8006:16), xwa
	jrl SaveFilter_Return

SaveFilter_HandleShow:
	ldw (xsp), 0x0

SaveFilter_DrawLoop:
	ld wa, (xsp)
	sll wa, 4
	lda xbc, (0x800a:16)
	extz xwa
	add xwa, xbc
	ld bc, (xsp)
	extz bc
	calr RenderSaveFilterDisplay
	ld de, (xsp)
	sll de, 4
	lda xbc, (0x800a:16)
	extz xde
	add xde, xbc
	ld xwa, (0x8006:16)
	ld xbc, 0x1c0000f
	call ApPostEvent
	incw 1, (xsp)
	cpw (xsp), 0x8
	jr lt, SaveFilter_DrawLoop
	jrl SaveFilter_Return

SaveFilter_HandleScroll:
	ld xwa, (xsp + 2)
	cp xwa, 0x8
	jrl nc, SaveFilter_SelectAll
	cp xwa, 0x1
	jr nz, SaveFilter_ScrollOther
	cp xbc, 0x1c00017
	jr nz, SaveFilter_ScrollDown
	call FileIO_GetRecordAttr_Check
	cp l, 0:i3
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
	cp l, 0:i3
	jr z, SaveFilter_ScrollDown_Unlock
	call FileIO_GetRecordAttr_Check
	cp l, 0:i3
	jr nz, SaveFilter_UpdateDisplay
	ld xwa, (xsp + 2)
	extz wa
	jr SaveFilter_UnlockFilter

SaveFilter_ScrollDown_Unlock:
	call FileIO_GetRecordAttr_Check
	cp l, 0:i3
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
	ld xwa, (xsp + 2)
	ld c, a
	extz bc
	ld wa, bc
	sla wa, 4
	lda xde, (0x800a:16)
	exts xwa
	add xwa, xde
	calr RenderSaveFilterDisplay
	ld xwa, (xsp + 2)
	extz wa
	sla wa, 4
	lda xbc, (0x800a:16)
	lda_dri XDE, 0x07, 0xe4, 0xe0
	ld xwa, (0x8006:16)
	ld xbc, 0x1c0000f
	jrl SaveFilter_DispatchWidget

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
	ld wa, (xsp)
	sll wa, 4
	lda xbc, (0x800a:16)
	extz xwa
	add xwa, xbc
	ld bc, (xsp)
	extz bc
	calr RenderSaveFilterDisplay
	ld de, (xsp)
	sll de, 4
	lda xbc, (0x800a:16)
	extz xde
	add xde, xbc
	ld xwa, (0x8006:16)
	ld xbc, 0x1c0000f
	call ApPostEvent
	incw 1, (xsp)
	cpw (xsp), 0x8
	jr lt, SaveFilter_SelectAll_Loop
	jrl SaveFilter_Return

SaveFilter_DeselectAll:
	ld xwa, (xsp + 2)
	cp xwa, 0x9
	jr nz, SaveFilter_OpSave
	call FileIO_SetModeFlag_Reading
	ldw (xsp), 0x0

SaveFilter_DeselectAll_Loop:
	ld wa, (xsp)
	extz wa
	call FileIO_BuildRecordPath_Done
	ld wa, (xsp)
	sll wa, 4
	lda xbc, (0x800a:16)
	extz xwa
	add xwa, xbc
	ld bc, (xsp)
	extz bc
	calr RenderSaveFilterDisplay
	ld de, (xsp)
	sll de, 4
	lda xbc, (0x800a:16)
	extz xde
	add xde, xbc
	ld xwa, (0x8006:16)
	ld xbc, 0x1c0000f
	call ApPostEvent
	incw 1, (xsp)
	cpw (xsp), 0x8
	jr lt, SaveFilter_DeselectAll_Loop
	jrl SaveFilter_Return

SaveFilter_OpSave:
	ld xwa, (xsp + 2)
	cp xwa, 0xa
	jrl nz, SaveFilter_OpFormat
	call FileIO_FormatName_Done
	cp hl, 0:i3
	jrl z, SaveFilter_OpFormat
	calr SelectPasswordMode
	cp hl, 0:i3
	jr z, SaveFilter_Save_NoPwd
	ld xde, 0:i3
	ld e, (0x8a0c:16)
	ld xwa, 0xffffffff
	ld xbc, 0x1c50004
	jr SaveFilter_DispatchWidget

SaveFilter_Save_NoPwd:
	call CheckFileSystemStatus
	cp hl, 0:i3
	jr z, SaveFilter_Save_Execute
	cp (0x0340ea:24), 0x00
	jr z, SaveFilter_Save_Execute
	ld xwa, 0xffffffff
	ld xbc, 0x1c50000
	ld xde, 1:i3
	call ApPostEvent
	ld xwa, 0x600037
	ld xbc, 0x1c00001
	ld xde, 0:i3

SaveFilter_DispatchWidget:
	call ApPostEvent
	jrl SaveFilter_Return

SaveFilter_Save_Execute:
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	ld xde, 5:i3
	call ApPostEvent
	ld wa, 0:i3
	calr InitializeOperationState
	call FileIO_SaveAllRegions
	ld wa, hl
	ld bc, 5:i3
	calr FileIO_ValidateSignedValue
	ld (0x7f42:16), l
	call FileIO_ResetCurrentRecord
	call GetEncodedFreeSpaceData
	call GetEncodedFileSizeData
	ld (0x8502:16), hl
	calr SignalProgressUpdate
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	ld xde, 1:i3
	call ApPostEvent
	ld wa, 1:i3
	call UI_PostPartChangeEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	ld xde, 0:i3
	call ApPostEvent
	ldw wa, 0xee
	jr SaveFilter_CallStatusDisplay

SaveFilter_OpFormat:
	ld xwa, (xsp + 2)
	cp xwa, 0x32
	jr nz, SaveFilter_ResetAll
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	ld xde, 5:i3
	call ApPostEvent
	ld wa, 0:i3
	calr InitializeOperationState
	call FileIO_SaveAllRegions
	ld wa, hl
	ld bc, 5:i3
	calr FileIO_ValidateSignedValue
	ld (0x7f42:16), l
	call FileIO_ResetCurrentRecord
	call GetEncodedFreeSpaceData
	call GetEncodedFileSizeData
	ld (0x8502:16), hl
	calr SignalProgressUpdate
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	ld xde, 1:i3
	call ApPostEvent
	ld wa, 1:i3
	call UI_PostPartChangeEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	ld xde, 0:i3
	call ApPostEvent
	ldw wa, 0xee

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
	ld wa, (xsp)
	extz wa
	call FileIO_BuildRecordPath_Return
	ld wa, (xsp)
	sll wa, 4
	lda xbc, (0x800a:16)
	extz xwa
	add xwa, xbc
	ld bc, (xsp)
	extz bc
	calr RenderSaveFilterDisplay
	ld de, (xsp)
	sll de, 4
	lda xbc, (0x800a:16)
	extz xde
	add xde, xbc
	ld xwa, (0x8006:16)
	ld xbc, 0x1c0000f
	call ApPostEvent
	incw 1, (xsp)
	cpw (xsp), 0x8
	jr lt, SaveFilter_ResetAll_Loop

SaveFilter_Return:
	ld xhl, 0:i3
	inc 6, xsp
	ret

