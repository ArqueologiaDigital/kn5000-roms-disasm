; =============================================================================
; file_io/filename_password.asm - Filename and Password UI
; =============================================================================
; Password entry and filename input routines.
;
; Key routines:
;   FmmPasswordFunc                  - Password entry dialog
;   FmmFileNameFunc                  - Filename input/display
; =============================================================================

FmmPasswordFunc:
	dec 4, xsp
	push xiz
	ld xiz, xde
	ld (xsp + 4), xwa
	ld wa, iz
	cp xbc, EVT_CHECK_PASSWORD3
	jrl z, Password_HandleLoadEvent
	lda xde, (0x8a0c:16)
	cp xbc, EVT_CHECK_PASSWORD2
	jrl z, Password_HandleSaveEvent
	cp xbc, EVT_CHECK_PASSWORD
	jr z, Password_HandleDeleteEvent
	cp xbc, EVT_SET_PASSWORD
	jrl nz, Password_Return
	call CheckAnySlotHasData
	cp l, 0:i3
	jr nz, Password_ShowError
	call CheckSlotIndexValid
	cp l, 0:i3
	jr z, Password_ClearAndSetSlot

Password_ShowError:
	ld (0x7f42:16), 10
	ldw wa, 0xee
	call SoundCtrl_SendCommand
	jrl Password_Return

Password_ClearAndSetSlot:
	ld wa, iz
	call ClearAllSongSlots
	ld wa, iz
	call SetCurrentSlotIndex
	lda xwa, (0x8a0d:16)
	setm 7, (xwa)
	setm 6, (xwa)
	jrl Password_Return

Password_HandleDeleteEvent:
	cp (xde), 0x3
	jr nz, Password_Delete_CheckLoadOnly
	call CheckSlotIsSelected
	cp l, 0:i3
	jr z, Password_Delete_CheckLoadOnly
	ld wa, iz
	call CheckIsCurrentSlot
	cp l, 0:i3
	jr z, Password_Delete_CheckLoadOnly
	lda xwa, (0x8a0d:16)
	setm 7, (xwa)
	setm 6, (xwa)
	ld xwa, (xsp + 4)
	ld xbc, EVT_INDEXSW_UP
	ld xde, 4:i3
	jr Password_ForwardToFileName

Password_Delete_CheckLoadOnly:
	cp (0x8a0c:16), 1
	jr nz, Password_Delete_CheckSaveOnly
	ld wa, iz
	call CheckSlotIsSelected
	cp l, 0:i3
	jr z, Password_Delete_CheckSaveOnly
	set 7, (0x8a0d:16)
	ld xwa, (xsp + 4)
	ld xbc, EVT_INDEXSW_UP
	ld xde, 4:i3
	jr Password_ForwardToFileName

Password_Delete_CheckSaveOnly:
	cp (0x8a0c:16), 2
	jr nz, Password_ShowErrorStatus
	ld wa, iz
	call CheckIsCurrentSlot
	cp l, 0:i3
	jr z, Password_ShowErrorStatus
	set 6, (0x8a0d:16)
	ld xwa, (xsp + 4)
	ld xbc, EVT_INDEXSW_UP
	ld xde, 4:i3

Password_ForwardToFileName:
	calr FmmFileNameFunc
	jrl Password_Return

Password_ShowErrorStatus:
	ld (0x7f42:16), 11
	ldw wa, 0xee
	jrl Password_CallStatusDisplay

Password_HandleSaveEvent:
	cp (xde), 0x3
	jr nz, Password_Save_CheckLoadOnly
	call CheckSlotIsSelected
	cp l, 0:i3
	jr z, Password_Save_CheckLoadOnly
	ld wa, iz
	call CheckIsCurrentSlot
	cp l, 0:i3
	jr z, Password_Save_CheckLoadOnly
	lda xwa, (0x8a0d:16)
	setm 7, (xwa)
	setm 6, (xwa)
	ld xwa, (xsp + 4)
	ld xbc, EVT_INDEXSW_UP
	ld xde, 0xa
	jr Password_ForwardToSaveFilter

Password_Save_CheckLoadOnly:
	cp (0x8a0c:16), 1
	jr nz, Password_Save_CheckSaveOnly
	ld wa, iz
	call CheckSlotIsSelected
	cp l, 0:i3
	jr z, Password_Save_CheckSaveOnly
	set 7, (0x8a0d:16)
	ld xwa, (xsp + 4)
	ld xbc, EVT_INDEXSW_UP
	ld xde, 0xa
	jr Password_ForwardToSaveFilter

Password_Save_CheckSaveOnly:
	cp (0x8a0c:16), 2
	jr nz, Password_SaveErrorStatus
	ld wa, iz
	call CheckIsCurrentSlot
	cp l, 0:i3
	jr z, Password_SaveErrorStatus
	set 6, (0x8a0d:16)
	ld xwa, (xsp + 4)
	ld xbc, EVT_INDEXSW_UP
	ld xde, 0xa

Password_ForwardToSaveFilter:
	calr FmmSaveFilterFunc
	jr Password_Return

Password_SaveErrorStatus:
	ld (0x7f42:16), 11
	ldw wa, 0xee
	jr Password_CallStatusDisplay

Password_HandleLoadEvent:
	call CheckSlotIsSelected
	cp l, 0:i3
	jr z, Password_LoadErrorStatus
	set 7, (0x8a0d:16)
	ld xwa, (xsp + 4)
	ld xbc, EVT_INDEXSW_UP
	ld xde, 4:i3
	calr FmmSeqSongNameFunc
	jr Password_Return

Password_LoadErrorStatus:
	ld (0x7f42:16), 11
	ldw wa, 0xee

Password_CallStatusDisplay:
	call SoundCtrl_SendCommand

Password_Return:
	ld xhl, 0:i3
	pop xiz
	inc 4, xsp
	ret

SelectPasswordMode:
	push xiz
	ldib_erp 0xfb, 0
	ldib_erp 0xfa, 0
	ld wa, 2:i3
	call FileIO_FormatName_Return
	cp l, 0:i3
	jr z, SelectMode_CheckSaveAvail
	call CheckAnySlotHasData
	cp l, 0:i3
	jr z, SelectMode_CheckSaveAvail
	bit 7, (0x8a0d:16)
	jr nz, SelectMode_CheckSaveAvail
	ldib_erp 0xfa, 1

SelectMode_CheckSaveAvail:
	ld wa, 3:i3
	call FileIO_FormatName_Return
	cp l, 0:i3
	jr z, SelectMode_DetermineMode
	call CheckSlotIndexValid
	cp l, 0:i3
	jr z, SelectMode_DetermineMode
	bit 6, (0x8a0d:16)
	jr nz, SelectMode_DetermineMode
	ldib_erp 0xfb, 1

SelectMode_DetermineMode:
	cpib_erp 0xfa, 0
	jr z, SelectMode_SingleMode
	cpib_erp 0xfb, 0
	jr z, SelectMode_SingleMode
	call GetCurrentSlotIndex
	ld iz, hl
	call FindFirstEmptySlot
	ld a, 0x1:opc
	cp hl, iz
	jr nz, SelectMode_SetBothMode
	ld a, 0x3:opc

SelectMode_SetBothMode:
	ld (0x8a0c:16), a
	jr SelectMode_Return

SelectMode_SingleMode:
	lda xbc, (0x8a0c:16)
	cpib_erp 0xfa, 0
	jr z, SelectMode_CheckSaveOnlyMode
	ld (xbc), 0x1
	jr SelectMode_Return

SelectMode_CheckSaveOnlyMode:
	ld a, 0x0:opc
	cpib_erp 0xfb, 0
	jr z, SelectMode_StoreMode
	ld a, 0x2:opc

SelectMode_StoreMode:
	ld (xbc), a

SelectMode_Return:
	ld l, (0x8a0c:16)
	extz hl
	pop xiz
	ret

FmmFileNameFunc:
	dec 8, xsp
	push xiz
	ld xiz, xde
	ld (xsp + 8), xbc
	ld xbc, xiz
	ld xwa, (xsp + 8)
	cp xwa, EVT_GET_FILE_SFX
	jrl z, FileName_HandleRegister
	cp xwa, EVT_INDEXSW_DOWN
	jrl z, FileName_HandleScroll
	cp xwa, EVT_INDEXSW_UP
	jrl z, FileName_HandleScroll
	cp xwa, EVT_PAINT
	jr z, FileName_HandleShow
	cp xwa, EVT_PS_FILE_NAME_BOX_ID
	jrl nz, FileName_Return
	ld (0x7f72:16), xbc
	call GetCurrentFileIndex
	ld (0x7f7a:16), hl
	cp hl, 0:i3
	jr lt, FileName_ListSelect_Negative
	exts xhl
	ld xwa, (0x7f72:16)
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, xhl
	jr FileName_ListSelect_Forward

FileName_ListSelect_Negative:
	ldw (0x7f7a:16), 0
	ld xwa, (0x7f72:16)
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld xde, 0:i3

FileName_ListSelect_Forward:
	call ApPostEvent
	ld xwa, 0:i3
	ld (0x7f76:16), xwa
	jrl FileName_Return

FileName_HandleShow:
	ldw (xsp + 6), 0x0

FileName_DrawItemLoop:
	ld wa, (xsp + 6)
	ld hl, wa
	sll hl, 5
	lda xde, (0x850c:16)
	extz xhl
	add xhl, xde
	ld bc, (xsp + 6)
	ld (xhl), c
	call GetFileEntryPtr
	ld xbc, xhl
	ld de, (xsp + 6)
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
	ld de, (xsp + 6)
	sll de, 5
	lda xbc, (0x850c:16)
	extz xde
	add xde, xbc
	ld xwa, (0x7f72:16)
	ld xbc, EVT_PARA_DRAW
	call ApPostEvent
	incw 1, (xsp + 6)
	cpw (xsp + 6), 0x14
	jr lt, FileName_DrawItemLoop
	jrl FileName_Return

FileName_HandleScroll:
	ldmw2 (xsp + 6), 0x7f7a
	ld wa, (xsp + 6)
	ld (xsp + 4), wa
	or xiz, xiz
	jr nz, FileName_PageUp
	ld xwa, (xsp + 8)
	cp xwa, EVT_INDEXSW_DOWN
	jr nz, FileName_ScrollUp
	cpw (xsp + 6), 0x13
	jrl ge, FileName_GetSelection
	incw 1, (xsp + 6)
	jr FileName_ScrollApply

FileName_ScrollUp:
	cp xwa, EVT_INDEXSW_UP
	jrl nz, FileName_GetSelection
	cpw (xsp + 6), 0x0
	jrl le, FileName_GetSelection
	decm 1, (xsp + 6)
	jr FileName_ScrollApply

FileName_PageUp:
	cp xiz, 0x1
	jr nz, FileName_PageDown
	cpw (xsp + 6), 0xa
	jrl lt, FileName_GetSelection
	submi16 (xsp + 6), 0xa
	jr FileName_ScrollApply

FileName_PageDown:
	cp xiz, 0x2
	jr nz, FileName_OpSave
	ld wa, (xsp + 6)
	add wa, 0xa
	cp wa, 0x13
	jrl gt, FileName_GetSelection
	addiw_da (xsp + 6), 0xa

FileName_ScrollApply:
	mrdw5 0x9f, 0x06, 0x19, 0x7a, 0x7f
	ld wa, (xsp + 6)
	jrl FileName_UpdateDisplay

FileName_OpSave:
	cp xiz, 0x3
	jrl nz, FileName_OpLoad
	call CheckFileSystemStatus
	cp hl, 0:i3
	jrl z, FileName_OpLoad
	call FileIO_WriteRecordName_Loop
	cp hl, 0:i3
	jrl z, FileName_OpLoad
	ld xwa, 0x600026
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	call ApPostEvent
	ld wa, (0x7f7a:16)
	extz wa
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
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 1:i3
	call ApPostEvent
	cpw (0xf19e:16), 0
	jr z, FileName_OpSave_ShowCode1
	ld wa, 2:i3
	call FileIO_WriteRecordName_Done
	cp l, 0:i3
	jr z, FileName_OpSave_ShowCode1
	ld wa, 2:i3
	call FileIO_CheckRecordValid
	cp l, 0:i3
	jr nz, FileName_OpSave_ShowCodeA
	ldw wa, 0x8
	call FileIO_CheckRecordValid
	cp l, 0:i3
	jr z, FileName_OpSave_ShowCode1

FileName_OpSave_ShowCodeA:
	ldw wa, 0xa
	jr FileName_OpSave_CallHandler

FileName_OpSave_ShowCode1:
	ld wa, 1:i3

FileName_OpSave_CallHandler:
	call UI_PostPartChangeEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 0:i3
	call ApPostEvent
	ldw wa, 0xee
	jrl FileName_CallStatusDisplay

FileName_OpLoad:
	cp xiz, 0x4
	jrl nz, FileName_OpFormat
	call FileIO_FormatName_Done
	cp hl, 0:i3
	jrl z, FileName_OpFormat
	calr SelectPasswordMode
	cp hl, 0:i3
	jr z, FileName_OpLoad_NoPwd
	ld xde, 0:i3
	ld e, (0x8a0c:16)
	ld xwa, 0xffffffff
	ld xbc, EVT_WAKEUP_PASSWORD
	jrl FileName_OpDispatch

FileName_OpLoad_NoPwd:
	call CheckFileSystemStatus
	cp hl, 0:i3
	jr z, FileName_OpLoad_Execute
	cp (0x0340ea:24), 0x00
	jr z, FileName_OpLoad_Execute
	ld xwa, 0xffffffff
	ld xbc, EVT_NOT_PARA_DRAW
	ld xde, 1:i3
	call ApPostEvent
	ld xwa, 0x600037
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	jrl FileName_OpDispatch

FileName_OpLoad_Execute:
	ld xwa, 0x600026
	ld xbc, EVT_SHOW
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
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 1:i3
	call ApPostEvent
	ld wa, 1:i3
	call UI_PostPartChangeEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 0:i3
	call ApPostEvent
	ldw wa, 0xee
	jrl FileName_CallStatusDisplay

FileName_OpFormat:
	cp xiz, 0x32
	jr nz, FileName_OpDelete
	ld xwa, 0x600026
	ld xbc, EVT_SHOW
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
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 1:i3
	call ApPostEvent
	ld wa, 1:i3
	call UI_PostPartChangeEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 0:i3
	call ApPostEvent
	ldw wa, 0xee
	jrl FileName_CallStatusDisplay

FileName_OpDelete:
	cp xiz, 0x5
	jrl nz, FileName_OpFormatVariant
	call CheckFileSystemStatus
	cp hl, 0:i3
	jr z, FileName_OpFormatVariant
	cp (0x0340ea:24), 0x00
	jr z, FileName_OpDelete_Execute
	ld xwa, 0xffffffff
	ld xbc, EVT_NOT_PARA_DRAW
	ld xde, 1:i3
	call ApPostEvent
	ld xwa, 0x7b0051
	ld xbc, EVT_SHOW
	ld xde, 0:i3

FileName_OpDispatch:
	call ApPostEvent
	jrl FileName_GetSelection

FileName_OpDelete_Execute:
	ld xwa, 0x600026
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	call ApPostEvent
	ld wa, 0:i3
	calr InitializeOperationState
	call ReadSingleFile
	ld wa, hl
	ld bc, 5:i3
	calr FileIO_ValidateSignedValue
	ld (0x7f42:16), l
	calr SignalProgressUpdate
	call FileIO_ResetCurrentRecord
	call GetEncodedFreeSpaceData
	call GetEncodedFileSizeData
	ld (0x8502:16), hl
	ld xwa, 0x600026
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ldw wa, 0xee
	jrl FileName_CallStatusDisplay

FileName_OpFormatVariant:
	cp xiz, 0x33
	jr nz, FileName_OpNavigate
	ld xwa, 0x600026
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	call ApPostEvent
	ld wa, 0:i3
	calr InitializeOperationState
	call ReadSingleFile
	ld wa, hl
	ld bc, 5:i3
	calr FileIO_ValidateSignedValue
	ld (0x7f42:16), l
	calr SignalProgressUpdate
	call FileIO_ResetCurrentRecord
	call GetEncodedFreeSpaceData
	call GetEncodedFileSizeData
	ld (0x8502:16), hl
	ld xwa, 0x600026
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ldw wa, 0xee
	jrl FileName_CallStatusDisplay

FileName_OpNavigate:
	cp xiz, 0x6
	jrl nz, FileName_GetSelection
	call CheckFileSystemStatus
	cp hl, 0:i3
	jrl z, FileName_GetSelection
	ld xbc, (xsp + 8)
	ld wa, (0x7f7a:16)
	cp xbc, EVT_INDEXSW_DOWN
	jr nz, FileName_Navigate_ScrollUp
	ld bc, wa
	cp wa, 0x13
	jr ge, FileName_Navigate_CheckChanged
	inc 1, bc
	ld (0x7f7a:16), bc
	jr FileName_Navigate_CheckChanged

FileName_Navigate_ScrollUp:
	cp xbc, EVT_INDEXSW_UP
	jr nz, FileName_Navigate_CheckChanged
	ld bc, wa
	cp wa, 0:i3
	jr le, FileName_Navigate_CheckChanged
	dec 1, bc
	ld (0x7f7a:16), bc

FileName_Navigate_CheckChanged:
	ld wa, (xsp + 6)
	cp wa, (0x7f7a:16)
	jr z, FileName_GetSelection
	ld xwa, 0x600026
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	call ApPostEvent
	ld wa, 0:i3
	calr InitializeOperationState
	ld wa, (0x7f7a:16)
	call ReadDualFileEx
	ld wa, hl
	ld bc, 5:i3
	calr FileIO_ValidateSignedValue
	ld (0x7f42:16), l
	calr SignalProgressUpdate
	call GetEncodedFileSizeData
	ld (0x8502:16), hl
	ld xwa, 0x600026
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ldw wa, 0xee

FileName_CallStatusDisplay:
	call SoundCtrl_SendCommand

FileName_GetSelection:
	ld wa, (0x7f7a:16)

FileName_UpdateDisplay:
	cp (xsp + 4), wa
	jrl z, FileName_Return
	call NotifyUIOfSelectionChange
	ld (0x89f8:16), 4
	ld de, (0x7f7a:16)
	exts xde
	ld xwa, (0x7f72:16)
	ld xbc, EVT_SET_SELECTED_FILE_NUMBER
	call ApPostEvent
	ld de, (xsp + 4)
	sll de, 5
	lda xbc, (0x850c:16)
	extz xde
	add xde, xbc
	ld xwa, (0x7f72:16)
	ld xbc, EVT_PARA_DRAW
	call ApPostEvent
	ld de, (0x7f7a:16)
	sll de, 5
	lda xbc, (0x850c:16)
	extz xde
	add xde, xbc
	ld xwa, (0x7f72:16)
	ld xbc, EVT_PARA_DRAW
	call ApPostEvent
	ldw (xsp + 6), 0x0

FileName_UpdateButtons_Loop:
	ld wa, (xsp + 6)
	extz wa
	call FileIO_CheckRecordValid
	ld wa, (xsp + 6)
	extz wa
	cp l, 0:i3
	jr z, FileName_UpdateButtons_Hide
	call FileIO_FormatName_Loop
	jr FileName_UpdateButtons_Check

FileName_UpdateButtons_Hide:
	call FileIO_FormatName_Copy

FileName_UpdateButtons_Check:
	incw 1, (xsp + 6)
	cpw (xsp + 6), 0x8
	jr lt, FileName_UpdateButtons_Loop
	ldw wa, 0x8
	call FileIO_CheckRecordValid
	cp l, 0:i3
	jr z, FileName_CheckCallback
	ldw wa, 0x9
	call FileIO_CheckRecordValid
	cp l, 0:i3
	jr z, FileName_CheckCallback
	ld wa, 2:i3
	call FileIO_FormatName_Loop

FileName_CheckCallback:
	ld xwa, (0x7f76:16)
	or xwa, xwa
	jrl z, FileName_Return
	cp (SEQ_MASTER_STATE:16), 103
	jr z, FileName_Callback_Simple
	call CheckFileSystemStatus
	ld iz, hl
	ldw wa, 0x8
	call FileIO_CheckRecordValid
	cp l, 0:i3
	jr z, FileName_Callback_SetFilter
	ldw wa, 0x9
	call FileIO_CheckRecordValid
	cp l, 0:i3
	jr z, FileName_Callback_SetFilter
	set 2, iz

FileName_Callback_SetFilter:
	call FileIO_WriteRecordName_Loop
	and iz, hl
	bit 0, iz
	jr z, FileName_Callback_Send
	call GetCurrentFileType
	cp l, 0:i3
	jr z, FileName_Callback_Send
	res 0, iz
	set 1, iz

FileName_Callback_Send:
	ld de, iz
	extz xde
	ld xwa, (0x7f76:16)
	ld xbc, EVT_SET_FILE_SFX
	jr FileName_DispatchWidget

FileName_Callback_Simple:
	call FileIO_FormatName_Done
	extz xhl
	ld xwa, (0x7f76:16)
	ld xbc, EVT_SET_FILE_SFX
	ld xde, xhl
	jr FileName_DispatchWidget

FileName_HandleRegister:
	ld (0x7f76:16), xbc
	cp (SEQ_MASTER_STATE:16), 103
	jr z, FileName_Register_Simple
	call CheckFileSystemStatus
	ld iz, hl
	ldw wa, 0x8
	call FileIO_CheckRecordValid
	cp l, 0:i3
	jr z, FileName_Register_SetFilter
	ldw wa, 0x9
	call FileIO_CheckRecordValid
	cp l, 0:i3
	jr z, FileName_Register_SetFilter
	set 2, iz

FileName_Register_SetFilter:
	call FileIO_WriteRecordName_Loop
	and iz, hl
	bit 0, iz
	jr z, FileName_Register_Send
	call GetCurrentFileType
	cp l, 0:i3
	jr z, FileName_Register_Send
	res 0, iz
	set 1, iz

FileName_Register_Send:
	ld de, iz
	extz xde
	ld xwa, (0x7f76:16)
	ld xbc, EVT_SET_FILE_SFX
	jr FileName_DispatchWidget

FileName_Register_Simple:
	call FileIO_FormatName_Done
	extz xhl
	ld xwa, (0x7f76:16)
	ld xbc, EVT_SET_FILE_SFX
	ld xde, xhl

FileName_DispatchWidget:
	call ApPostEvent

FileName_Return:
	ld xhl, 0:i3
	pop xiz
	inc 8, xsp
	ret

