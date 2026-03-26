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
	.incbin "includes/generated/v7_transplant_FmmPasswordFunc.bin"
Password_ShowError:
	.incbin "includes/generated/v7_transplant_Password_ShowError.bin"
Password_ClearAndSetSlot:
	.incbin "includes/generated/v7_transplant_Password_ClearAndSetSlot.bin"
Password_HandleDeleteEvent:
	.incbin "includes/generated/v7_transplant_Password_HandleDeleteEvent.bin"
Password_Delete_CheckLoadOnly:
	.incbin "includes/generated/v7_transplant_Password_Delete_CheckLoadOnly.bin"
Password_Delete_CheckSaveOnly:
	.incbin "includes/generated/v7_transplant_Password_Delete_CheckSaveOnly.bin"
Password_ForwardToFileName:
	calr FmmFileNameFunc
	jrl Password_Return

Password_ShowErrorStatus:
	.incbin "includes/generated/v7_transplant_Password_ShowErrorStatus.bin"
Password_HandleSaveEvent:
	.incbin "includes/generated/v7_transplant_Password_HandleSaveEvent.bin"
Password_Save_CheckLoadOnly:
	.incbin "includes/generated/v7_transplant_Password_Save_CheckLoadOnly.bin"
Password_Save_CheckSaveOnly:
	.incbin "includes/generated/v7_transplant_Password_Save_CheckSaveOnly.bin"
Password_ForwardToSaveFilter:
	calr FmmSaveFilterFunc
	jr Password_Return

Password_SaveErrorStatus:
	.incbin "includes/generated/v7_transplant_Password_SaveErrorStatus.bin"
Password_HandleLoadEvent:
	.incbin "includes/generated/v7_transplant_Password_HandleLoadEvent.bin"
Password_LoadErrorStatus:
	.incbin "includes/generated/v7_transplant_Password_LoadErrorStatus.bin"
Password_CallStatusDisplay:
	call SoundCtrl_SendCommand

Password_Return:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret

SelectPasswordMode:
	.incbin "includes/generated/v7_transplant_SelectPasswordMode.bin"
SelectMode_CheckSaveAvail:
	.incbin "includes/generated/v7_transplant_SelectMode_CheckSaveAvail.bin"
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
	.incbin "includes/generated/v7_transplant_SelectMode_SetBothMode.bin"
SelectMode_SingleMode:
	.incbin "includes/generated/v7_transplant_SelectMode_SingleMode.bin"
SelectMode_CheckSaveOnlyMode:
	ldb a, 0x0
	cpib_erp 0xfb, 0
	jr z, SelectMode_StoreMode
	ldb a, 0x2

SelectMode_StoreMode:
	ld (xbc), a

SelectMode_Return:
	.incbin "includes/generated/v7_transplant_SelectMode_Return.bin"
FmmFileNameFunc:
	.incbin "includes/generated/v7_transplant_FmmFileNameFunc.bin"
FileName_ListSelect_Negative:
	.incbin "includes/generated/v7_transplant_FileName_ListSelect_Negative.bin"
FileName_ListSelect_Forward:
	.incbin "includes/generated/v7_transplant_FileName_ListSelect_Forward.bin"
FileName_HandleShow:
	ldw (xsp + 6), 0x0

FileName_DrawItemLoop:
	.incbin "includes/generated/v7_transplant_FileName_DrawItemLoop.bin"
FileName_HandleScroll:
	.incbin "includes/generated/v7_transplant_FileName_HandleScroll.bin"
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
	.incbin "includes/generated/v7_transplant_FileName_ScrollApply.bin"
FileName_OpSave:
	.incbin "includes/generated/v7_transplant_FileName_OpSave.bin"
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
	.incbin "includes/generated/v7_transplant_FileName_OpLoad.bin"
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
	.incbin "includes/generated/v7_transplant_FileName_OpLoad_Execute.bin"
FileName_OpFormat:
	.incbin "includes/generated/v7_transplant_FileName_OpFormat.bin"
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
	.incbin "includes/generated/v7_transplant_FileName_OpDelete_Execute.bin"
FileName_OpFormatVariant:
	.incbin "includes/generated/v7_transplant_FileName_OpFormatVariant.bin"
FileName_OpNavigate:
	.incbin "includes/generated/v7_transplant_FileName_OpNavigate.bin"
FileName_Navigate_ScrollUp:
	.incbin "includes/generated/v7_transplant_FileName_Navigate_ScrollUp.bin"
FileName_Navigate_CheckChanged:
	.incbin "includes/generated/v7_transplant_FileName_Navigate_CheckChanged.bin"
FileName_CallStatusDisplay:
	call SoundCtrl_SendCommand

FileName_GetSelection:
	.incbin "includes/generated/v7_transplant_FileName_GetSelection.bin"
FileName_UpdateDisplay:
	.incbin "includes/generated/v7_transplant_FileName_UpdateDisplay.bin"
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
	.incbin "includes/generated/v7_transplant_FileName_CheckCallback.bin"
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
	.incbin "includes/generated/v7_transplant_FileName_Callback_Send.bin"
FileName_Callback_Simple:
	.incbin "includes/generated/v7_transplant_FileName_Callback_Simple.bin"
FileName_HandleRegister:
	.incbin "includes/generated/v7_transplant_FileName_HandleRegister.bin"
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
	.incbin "includes/generated/v7_transplant_FileName_Register_Send.bin"
FileName_Register_Simple:
	.incbin "includes/generated/v7_transplant_FileName_Register_Simple.bin"
FileName_DispatchWidget:
	call ApPostEvent

FileName_Return:
	lds32 xhl, 0
	pop xiz
	inc 8, xsp
	ret

