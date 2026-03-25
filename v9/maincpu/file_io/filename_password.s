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
	cp xbc, 0x1e50010
	jrl z, Password_HandleLoadEvent
	lda_d16 xde, (0x8a0c)
	cp xbc, 0x1e5000f
	jrl z, Password_HandleSaveEvent
	cp xbc, 0x1e5000e
	jr z, Password_HandleDeleteEvent
	cp xbc, 0x1e5000d
	jrl nz, Password_Return
	call CheckAnySlotHasData
	cps l, 0
	jr nz, Password_ShowError
	call CheckSlotIndexValid
	cps l, 0
	jr z, Password_ClearAndSetSlot

Password_ShowError:
	stdi8 (0x7f42), 10
	ldw wa, 0xee
	call SoundCtrl_SendCommand
	jrl Password_Return

Password_ClearAndSetSlot:
	ld wa, iz
	call ClearAllSongSlots
	ld wa, iz
	call SetCurrentSlotIndex
	lda_d16 xwa, (0x8a0d)
	setm 7, (xwa)
	setm 6, (xwa)
	jrl Password_Return

Password_HandleDeleteEvent:
	cp (xde), 0x3
	jr nz, Password_Delete_CheckLoadOnly
	call CheckSlotIsSelected
	cps l, 0
	jr z, Password_Delete_CheckLoadOnly
	ld wa, iz
	call CheckIsCurrentSlot
	cps l, 0
	jr z, Password_Delete_CheckLoadOnly
	lda_d16 xwa, (0x8a0d)
	setm 7, (xwa)
	setm 6, (xwa)
	ld xwa, (xsp + 4)
	ld xbc, 0x1c00017
	lds32 xde, 4
	jr Password_ForwardToFileName

Password_Delete_CheckLoadOnly:
	cpdi8 (0x8a0c), 1
	jr nz, Password_Delete_CheckSaveOnly
	ld wa, iz
	call CheckSlotIsSelected
	cps l, 0
	jr z, Password_Delete_CheckSaveOnly
	setda 7, 0x8a0d
	ld xwa, (xsp + 4)
	ld xbc, 0x1c00017
	lds32 xde, 4
	jr Password_ForwardToFileName

Password_Delete_CheckSaveOnly:
	cpdi8 (0x8a0c), 2
	jr nz, Password_ShowErrorStatus
	ld wa, iz
	call CheckIsCurrentSlot
	cps l, 0
	jr z, Password_ShowErrorStatus
	setda 6, 0x8a0d
	ld xwa, (xsp + 4)
	ld xbc, 0x1c00017
	lds32 xde, 4

Password_ForwardToFileName:
	calr FmmFileNameFunc
	jrl Password_Return

Password_ShowErrorStatus:
	stdi8 (0x7f42), 11
	ldw wa, 0xee
	jrl Password_CallStatusDisplay

Password_HandleSaveEvent:
	cp (xde), 0x3
	jr nz, Password_Save_CheckLoadOnly
	call CheckSlotIsSelected
	cps l, 0
	jr z, Password_Save_CheckLoadOnly
	ld wa, iz
	call CheckIsCurrentSlot
	cps l, 0
	jr z, Password_Save_CheckLoadOnly
	lda_d16 xwa, (0x8a0d)
	setm 7, (xwa)
	setm 6, (xwa)
	ld xwa, (xsp + 4)
	ld xbc, 0x1c00017
	ld xde, 0xa
	jr Password_ForwardToSaveFilter

Password_Save_CheckLoadOnly:
	cpdi8 (0x8a0c), 1
	jr nz, Password_Save_CheckSaveOnly
	ld wa, iz
	call CheckSlotIsSelected
	cps l, 0
	jr z, Password_Save_CheckSaveOnly
	setda 7, 0x8a0d
	ld xwa, (xsp + 4)
	ld xbc, 0x1c00017
	ld xde, 0xa
	jr Password_ForwardToSaveFilter

Password_Save_CheckSaveOnly:
	cpdi8 (0x8a0c), 2
	jr nz, Password_SaveErrorStatus
	ld wa, iz
	call CheckIsCurrentSlot
	cps l, 0
	jr z, Password_SaveErrorStatus
	setda 6, 0x8a0d
	ld xwa, (xsp + 4)
	ld xbc, 0x1c00017
	ld xde, 0xa

Password_ForwardToSaveFilter:
	calr FmmSaveFilterFunc
	jr Password_Return

Password_SaveErrorStatus:
	stdi8 (0x7f42), 11
	ldw wa, 0xee
	jr Password_CallStatusDisplay

Password_HandleLoadEvent:
	call CheckSlotIsSelected
	cps l, 0
	jr z, Password_LoadErrorStatus
	setda 7, 0x8a0d
	ld xwa, (xsp + 4)
	ld xbc, 0x1c00017
	lds32 xde, 4
	calr FmmSeqSongNameFunc
	jr Password_Return

Password_LoadErrorStatus:
	stdi8 (0x7f42), 11
	ldw wa, 0xee

Password_CallStatusDisplay:
	call SoundCtrl_SendCommand

Password_Return:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret

SelectPasswordMode:
	push xiz
	ldib_erp 0xfb, 0
	ldib_erp 0xfa, 0
	lds wa, 2
	call FileIO_FormatName_Return
	cps l, 0
	jr z, SelectMode_CheckSaveAvail
	call CheckAnySlotHasData
	cps l, 0
	jr z, SelectMode_CheckSaveAvail
	bitda 7, (0x8a0d)
	jr nz, SelectMode_CheckSaveAvail
	ldib_erp 0xfa, 1

SelectMode_CheckSaveAvail:
	lds wa, 3
	call FileIO_FormatName_Return
	cps l, 0
	jr z, SelectMode_DetermineMode
	call CheckSlotIndexValid
	cps l, 0
	jr z, SelectMode_DetermineMode
	bitda 6, (0x8a0d)
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
	ldb a, 0x1
	cp hl, iz
	jr nz, SelectMode_SetBothMode
	ldb a, 0x3

SelectMode_SetBothMode:
	stb_d8 (0x8a0c), a
	jr SelectMode_Return

SelectMode_SingleMode:
	lda_d16 xbc, (0x8a0c)
	cpib_erp 0xfa, 0
	jr z, SelectMode_CheckSaveOnlyMode
	ld (xbc), 0x1
	jr SelectMode_Return

SelectMode_CheckSaveOnlyMode:
	ldb a, 0x0
	cpib_erp 0xfb, 0
	jr z, SelectMode_StoreMode
	ldb a, 0x2

SelectMode_StoreMode:
	ld (xbc), a

SelectMode_Return:
	ldb_d8 l, (0x8a0c)
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
	cp xwa, 0x1e50000
	jrl z, FileName_HandleRegister
	cp xwa, 0x1c00018
	jrl z, FileName_HandleScroll
	cp xwa, 0x1c00017
	jrl z, FileName_HandleScroll
	cp xwa, 0x1c0000b
	jr z, FileName_HandleShow
	cp xwa, 0x1e50004
	jrl nz, FileName_Return
	stda32 0x7f72, xbc
	call GetCurrentFileIndex
	stda16 (0x7f7a), xhl
	cps hl, 0
	jr lt, FileName_ListSelect_Negative
	exts xhl
	ldda32 xwa, (0x7f72)
	ld xbc, 0x1e50002
	ld xde, xhl
	jr FileName_ListSelect_Forward

FileName_ListSelect_Negative:
	stdi16 (0x7f7a), 0
	ldda32 xwa, (0x7f72)
	ld xbc, 0x1e50002
	lds32 xde, 0

FileName_ListSelect_Forward:
	call ApPostEvent
	lds32 xwa, 0
	stda32 0x7f76, xwa
	jrl FileName_Return

FileName_HandleShow:
	ldw (xsp + 6), 0x0

FileName_DrawItemLoop:
	ld wa, (xsp + 6)
	ld hl, wa
	sll hl, 5
	lda_d16 xde, (0x850c)
	extz xhl
	add xhl, xde
	ld bc, (xsp + 6)
	ld (xhl), c
	call GetFileEntryPtr
	ld xbc, xhl
	ld de, (xsp + 6)
	ld wa, de
	sll wa, 5
	lds hl, 1
	add hl, wa
	lda_d16 xix, (0x850c)
	extz xhl
	add xhl, xix
	inc 1, de
	pushw 0x6
	pushw 0x0
	ld xwa, xhl
	call FileIO_ReadHeader_ParseLoop
	ld de, (xsp + 6)
	sll de, 5
	lda_d16 xbc, (0x850c)
	extz xde
	add xde, xbc
	ldda32 xwa, (0x7f72)
	ld xbc, 0x1c0000f
	call ApPostEvent
	incm 1, (xsp + 6)
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
	cp xwa, 0x1c00018
	jr nz, FileName_ScrollUp
	cpw (xsp + 6), 0x13
	jrl ge, FileName_GetSelection
	incm 1, (xsp + 6)
	jr FileName_ScrollApply

FileName_ScrollUp:
	cp xwa, 0x1c00017
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
	cps hl, 0
	jrl z, FileName_OpLoad
	call FileIO_WriteRecordName_Loop
	cps hl, 0
	jrl z, FileName_OpLoad
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	ldw_d16 xwa, (0x7f7a)
	extz wa
	calr FileIO_MidiOutSendByte
	lds wa, 0
	calr InitializeOperationState
	call FileIO_ParseDirectoryEntry
	ld wa, hl
	lds bc, 1
	calr FileIO_ValidateSignedValue
	stb_d8 (0x7f42), l
	calr SignalProgressUpdate
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 1
	call ApPostEvent
	cpdi16 0xf19e, 0
	jr z, FileName_OpSave_ShowCode1
	lds wa, 2
	call FileIO_WriteRecordName_Done
	cps l, 0
	jr z, FileName_OpSave_ShowCode1
	lds wa, 2
	call FileIO_CheckRecordValid
	cps l, 0
	jr nz, FileName_OpSave_ShowCodeA
	ldw wa, 0x8
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, FileName_OpSave_ShowCode1

FileName_OpSave_ShowCodeA:
	ldw wa, 0xa
	jr FileName_OpSave_CallHandler

FileName_OpSave_ShowCode1:
	lds wa, 1

FileName_OpSave_CallHandler:
	call UI_PostPartChangeEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0xee
	jrl FileName_CallStatusDisplay

FileName_OpLoad:
	cp xiz, 0x4
	jrl nz, FileName_OpFormat
	call FileIO_FormatName_Done
	cps hl, 0
	jrl z, FileName_OpFormat
	calr SelectPasswordMode
	cps hl, 0
	jr z, FileName_OpLoad_NoPwd
	lds32 xde, 0
	ldb_d8 e, (0x8a0c)
	ld xwa, 0xffffffff
	ld xbc, 0x1c50004
	jrl FileName_OpDispatch

FileName_OpLoad_NoPwd:
	call CheckFileSystemStatus
	cps hl, 0
	jr z, FileName_OpLoad_Execute
	cpib_da (0x0340ea), 0x00
	jr z, FileName_OpLoad_Execute
	ld xwa, 0xffffffff
	ld xbc, 0x1c50000
	lds32 xde, 1
	call ApPostEvent
	ld xwa, 0x600037
	ld xbc, 0x1c00001
	lds32 xde, 0
	jrl FileName_OpDispatch

FileName_OpLoad_Execute:
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	lds wa, 0
	calr InitializeOperationState
	call FileIO_SaveAllRegions
	ld wa, hl
	lds bc, 5
	calr FileIO_ValidateSignedValue
	stb_d8 (0x7f42), l
	call FileIO_ResetCurrentRecord
	call GetEncodedFreeSpaceData
	call GetEncodedFileSizeData
	stda16 (0x8502), xhl
	calr SignalProgressUpdate
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 1
	call ApPostEvent
	lds wa, 1
	call UI_PostPartChangeEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0xee
	jrl FileName_CallStatusDisplay

FileName_OpFormat:
	cp xiz, 0x32
	jr nz, FileName_OpDelete
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	lds wa, 0
	calr InitializeOperationState
	call FileIO_SaveAllRegions
	ld wa, hl
	lds bc, 5
	calr FileIO_ValidateSignedValue
	stb_d8 (0x7f42), l
	call FileIO_ResetCurrentRecord
	call GetEncodedFreeSpaceData
	call GetEncodedFileSizeData
	stda16 (0x8502), xhl
	calr SignalProgressUpdate
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 1
	call ApPostEvent
	lds wa, 1
	call UI_PostPartChangeEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0xee
	jrl FileName_CallStatusDisplay

FileName_OpDelete:
	cp xiz, 0x5
	jrl nz, FileName_OpFormatVariant
	call CheckFileSystemStatus
	cps hl, 0
	jr z, FileName_OpFormatVariant
	cpib_da (0x0340ea), 0x00
	jr z, FileName_OpDelete_Execute
	ld xwa, 0xffffffff
	ld xbc, 0x1c50000
	lds32 xde, 1
	call ApPostEvent
	ld xwa, 0x7b0051
	ld xbc, 0x1c00001
	lds32 xde, 0

FileName_OpDispatch:
	call ApPostEvent
	jrl FileName_GetSelection

FileName_OpDelete_Execute:
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	lds wa, 0
	calr InitializeOperationState
	call ReadSingleFile
	ld wa, hl
	lds bc, 5
	calr FileIO_ValidateSignedValue
	stb_d8 (0x7f42), l
	calr SignalProgressUpdate
	call FileIO_ResetCurrentRecord
	call GetEncodedFreeSpaceData
	call GetEncodedFileSizeData
	stda16 (0x8502), xhl
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0xee
	jrl FileName_CallStatusDisplay

FileName_OpFormatVariant:
	cp xiz, 0x33
	jr nz, FileName_OpNavigate
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	lds wa, 0
	calr InitializeOperationState
	call ReadSingleFile
	ld wa, hl
	lds bc, 5
	calr FileIO_ValidateSignedValue
	stb_d8 (0x7f42), l
	calr SignalProgressUpdate
	call FileIO_ResetCurrentRecord
	call GetEncodedFreeSpaceData
	call GetEncodedFileSizeData
	stda16 (0x8502), xhl
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0xee
	jrl FileName_CallStatusDisplay

FileName_OpNavigate:
	cp xiz, 0x6
	jrl nz, FileName_GetSelection
	call CheckFileSystemStatus
	cps hl, 0
	jrl z, FileName_GetSelection
	ld xbc, (xsp + 8)
	ldw_d16 xwa, (0x7f7a)
	cp xbc, 0x1c00018
	jr nz, FileName_Navigate_ScrollUp
	ld bc, wa
	cp wa, 0x13
	jr ge, FileName_Navigate_CheckChanged
	inc 1, bc
	stda16 (0x7f7a), xbc
	jr FileName_Navigate_CheckChanged

FileName_Navigate_ScrollUp:
	cp xbc, 0x1c00017
	jr nz, FileName_Navigate_CheckChanged
	ld bc, wa
	cps wa, 0
	jr le, FileName_Navigate_CheckChanged
	dec 1, bc
	stda16 (0x7f7a), xbc

FileName_Navigate_CheckChanged:
	ld wa, (xsp + 6)
	cpda16 xwa, 0x7f7a
	jr z, FileName_GetSelection
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	lds wa, 0
	calr InitializeOperationState
	ldw_d16 xwa, (0x7f7a)
	call ReadDualFileEx
	ld wa, hl
	lds bc, 5
	calr FileIO_ValidateSignedValue
	stb_d8 (0x7f42), l
	calr SignalProgressUpdate
	call GetEncodedFileSizeData
	stda16 (0x8502), xhl
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0xee

FileName_CallStatusDisplay:
	call SoundCtrl_SendCommand

FileName_GetSelection:
	ldw_d16 xwa, (0x7f7a)

FileName_UpdateDisplay:
	cp (xsp + 4), wa
	jrl z, FileName_Return
	call NotifyUIOfSelectionChange
	stdi8 (0x89f8), 4
	ldw_d16 xde, (0x7f7a)
	exts xde
	ldda32 xwa, (0x7f72)
	ld xbc, 0x1e50002
	call ApPostEvent
	ld de, (xsp + 4)
	sll de, 5
	lda_d16 xbc, (0x850c)
	extz xde
	add xde, xbc
	ldda32 xwa, (0x7f72)
	ld xbc, 0x1c0000f
	call ApPostEvent
	ldw_d16 xde, (0x7f7a)
	sll de, 5
	lda_d16 xbc, (0x850c)
	extz xde
	add xde, xbc
	ldda32 xwa, (0x7f72)
	ld xbc, 0x1c0000f
	call ApPostEvent
	ldw (xsp + 6), 0x0

FileName_UpdateButtons_Loop:
	ld wa, (xsp + 6)
	extz wa
	call FileIO_CheckRecordValid
	ld wa, (xsp + 6)
	extz wa
	cps l, 0
	jr z, FileName_UpdateButtons_Hide
	call FileIO_FormatName_Loop
	jr FileName_UpdateButtons_Check

FileName_UpdateButtons_Hide:
	call FileIO_FormatName_Copy

FileName_UpdateButtons_Check:
	incm 1, (xsp + 6)
	cpw (xsp + 6), 0x8
	jr lt, FileName_UpdateButtons_Loop
	ldw wa, 0x8
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, FileName_CheckCallback
	ldw wa, 0x9
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, FileName_CheckCallback
	lds wa, 2
	call FileIO_FormatName_Loop

FileName_CheckCallback:
	ldda32 xwa, (0x7f76)
	or xwa, xwa
	jrl z, FileName_Return
	cpdi8 (0x8d36), 103
	jr z, FileName_Callback_Simple
	call CheckFileSystemStatus
	ld iz, hl
	ldw wa, 0x8
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, FileName_Callback_SetFilter
	ldw wa, 0x9
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, FileName_Callback_SetFilter
	set 2, iz

FileName_Callback_SetFilter:
	call FileIO_WriteRecordName_Loop
	and iz, hl
	bit 0, iz
	jr z, FileName_Callback_Send
	call GetCurrentFileType
	cps l, 0
	jr z, FileName_Callback_Send
	res 0, iz
	set 1, iz

FileName_Callback_Send:
	ld de, iz
	extz xde
	ldda32 xwa, (0x7f76)
	ld xbc, 0x1e50001
	jr FileName_DispatchWidget

FileName_Callback_Simple:
	call FileIO_FormatName_Done
	extz xhl
	ldda32 xwa, (0x7f76)
	ld xbc, 0x1e50001
	ld xde, xhl
	jr FileName_DispatchWidget

FileName_HandleRegister:
	stda32 0x7f76, xbc
	cpdi8 (0x8d36), 103
	jr z, FileName_Register_Simple
	call CheckFileSystemStatus
	ld iz, hl
	ldw wa, 0x8
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, FileName_Register_SetFilter
	ldw wa, 0x9
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, FileName_Register_SetFilter
	set 2, iz

FileName_Register_SetFilter:
	call FileIO_WriteRecordName_Loop
	and iz, hl
	bit 0, iz
	jr z, FileName_Register_Send
	call GetCurrentFileType
	cps l, 0
	jr z, FileName_Register_Send
	res 0, iz
	set 1, iz

FileName_Register_Send:
	ld de, iz
	extz xde
	ldda32 xwa, (0x7f76)
	ld xbc, 0x1e50001
	jr FileName_DispatchWidget

FileName_Register_Simple:
	call FileIO_FormatName_Done
	extz xhl
	ldda32 xwa, (0x7f76)
	ld xbc, 0x1e50001
	ld xde, xhl

FileName_DispatchWidget:
	call ApPostEvent

FileName_Return:
	lds32 xhl, 0
	pop xiz
	inc 8, xsp
	ret

