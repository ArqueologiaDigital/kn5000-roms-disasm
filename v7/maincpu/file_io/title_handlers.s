; =============================================================================
; file_io/title_handlers.asm - Load/Save Title Entry Handlers
; =============================================================================
; Entry point handlers for file manager dialogs.
;
; Key routines:
;   LoadTtlJgFunc, SaveTtlJgFunc     - Load/Save title handlers
;   SaveSmfTtlJgFunc                 - SMF save handler
;   DirectPlayTtlJgFunc              - Direct play handler
;   SongMedleyTtlJgFunc              - Song medley handler
;   SetupFlashFunc                   - Flash setup
;   FmmUtilityTitleFunc              - File Manager utility menu
;   FmmSmfUtilityTitleFunc           - SMF utility menu
; =============================================================================

LoadTtlJgFunc:
	cp xbc, 0x1c00007
	jr nz, LoadTtl_Return
	ldw wa, 0x61
	ldw bc, 0x64
	calr FileIO_DiskEventDispatch

LoadTtl_Return:
	lds32 xhl, 0
	ret

SaveTtlJgFunc:
	cp xbc, 0x1c00007
	jr nz, SaveTtl_Return
	ldw wa, 0x67
	calr FileIO_GetDiskCapacity

SaveTtl_Return:
	lds32 xhl, 0
	ret

SaveSmfTtlJgFunc:
	cp xbc, 0x1c00007
	jr nz, SaveSmfTtl_Return
	ldw wa, 0x6b
	calr FileIO_GetDiskCapacity

SaveSmfTtl_Return:
	lds32 xhl, 0
	ret

DirectPlayTtlJgFunc:
	cp xbc, 0x1c00007
	call_24 z, FileIO_DetectFileTypeAndPost
	lds32 xhl, 0
	ret

SongMedleyTtlJgFunc:
	cp xbc, 0x1c00007
	jr nz, SongMedleyTtl_Return
	ldw wa, 0x77
	calr FileIO_GetDiskCapacity

SongMedleyTtl_Return:
	lds32 xhl, 0
	ret

SetupFlashFunc:
	.incbin "includes/generated/v7_transplant_SetupFlashFunc.bin"
SetupFlash_HandleLoadEvent:
	lds wa, 6
	call Audio_DispatchCommand

SetupFlash_Return:
	lds32 xhl, 0
	ret

FmmUtilityTitleFunc:
	.incbin "includes/generated/v7_transplant_FmmUtilityTitleFunc.bin"
FmmUtility_DispatchState:
	.incbin "includes/generated/v7_transplant_FmmUtility_DispatchState.bin"
FmmUtility_ScanFormat:
	.incbin "includes/generated/v7_transplant_FmmUtility_ScanFormat.bin"
FmmUtility_CheckCapacity:
	.incbin "includes/generated/v7_transplant_FmmUtility_CheckCapacity.bin"
FmmUtility_HandleCancel:
	.incbin "includes/generated/v7_transplant_FmmUtility_HandleCancel.bin"
FmmUtility_HandleError:
	ld xwa, 0x7b0013
	ld xbc, 0x1e50006
	lds32 xde, 0
	call ApDeliveryEvent
	ldw wa, 0x7d

FmmUtility_CallHandler:
	call UI_PostModeChangeEvent
	jr FmmUtility_Return

FmmUtility_HandleSuccess:
	.incbin "includes/generated/v7_transplant_FmmUtility_HandleSuccess.bin"
FmmUtility_ShowStatus:
	call SoundCtrl_SendCommand
	jr FmmUtility_Return

FmmUtility_ContinueWait:
	ld xwa, 0x7b0013
	ld xbc, 0x1e50006
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	call ApPostEvent
	jr FmmUtility_Return

FmmUtility_HandleAbort:
	calr CancelOperationCleanup

FmmUtility_Return:
	lds32 xhl, 0
	ret

FmmSmfUtilityTitleFunc:
	.incbin "includes/generated/v7_transplant_FmmSmfUtilityTitleFunc.bin"
FmmSmfUtility_DispatchState:
	.incbin "includes/generated/v7_transplant_FmmSmfUtility_DispatchState.bin"
FmmSmfUtility_ScanFormat:
	.incbin "includes/generated/v7_transplant_FmmSmfUtility_ScanFormat.bin"
FmmSmfUtility_CheckCapacity:
	.incbin "includes/generated/v7_transplant_FmmSmfUtility_CheckCapacity.bin"
FmmSmfUtility_HandleCancel:
	.incbin "includes/generated/v7_transplant_FmmSmfUtility_HandleCancel.bin"
FmmSmfUtility_HandleError:
	ld xwa, 0x7b002a
	ld xbc, 0x1e50006
	lds32 xde, 0
	call ApDeliveryEvent
	ldw wa, 0x7d

FmmSmfUtility_CallHandler:
	call UI_PostModeChangeEvent
	jr FmmSmfUtility_Return

FmmSmfUtility_HandleSuccess:
	.incbin "includes/generated/v7_transplant_FmmSmfUtility_HandleSuccess.bin"
FmmSmfUtility_ShowStatus:
	call SoundCtrl_SendCommand
	jr FmmSmfUtility_Return

FmmSmfUtility_ContinueWait:
	ld xwa, 0x7b002a
	ld xbc, 0x1e50006
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	call ApPostEvent
	jr FmmSmfUtility_Return

FmmSmfUtility_HandleAbort:
	calr CancelOperationCleanup

FmmSmfUtility_Return:
	lds32 xhl, 0
	ret

