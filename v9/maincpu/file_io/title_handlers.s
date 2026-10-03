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
	cp xbc, EVT_SW_IN
	jr nz, LoadTtl_Return
	ldw wa, 0x61
	ldw bc, 0x64
	calr FileIO_DiskEventDispatch

LoadTtl_Return:
	ld xhl, 0:i3
	ret

SaveTtlJgFunc:
	cp xbc, EVT_SW_IN
	jr nz, SaveTtl_Return
	ldw wa, 0x67
	calr FileIO_GetDiskCapacity

SaveTtl_Return:
	ld xhl, 0:i3
	ret

SaveSmfTtlJgFunc:
	cp xbc, EVT_SW_IN
	jr nz, SaveSmfTtl_Return
	ldw wa, 0x6b
	calr FileIO_GetDiskCapacity

SaveSmfTtl_Return:
	ld xhl, 0:i3
	ret

DirectPlayTtlJgFunc:
	cp xbc, EVT_SW_IN
	call z, (FileIO_DetectFileTypeAndPost:24)
	ld xhl, 0:i3
	ret

SongMedleyTtlJgFunc:
	cp xbc, EVT_SW_IN
	jr nz, SongMedleyTtl_Return
	ldw wa, 0x77
	calr FileIO_GetDiskCapacity

SongMedleyTtl_Return:
	ld xhl, 0:i3
	ret

SetupFlashFunc:
	cp xbc, EVT_CHEAP_FLASH_LOAD
	jr z, SetupFlash_HandleLoadEvent
	cp xbc, EVT_CHEAP_FLASH_WRITE
	jr nz, SetupFlash_Return
	ld (GLOBAL_ERROR_CODE:16), 37
	ldw wa, 0xee
	call SoundCtrl_SendCommand
	ld wa, 6:i3
	call CtrlPanel_IndicatorJumpTable
	ld (GLOBAL_ERROR_CODE:16), 35
	ldw wa, 0xee
	call SoundCtrl_SendCommand
	jr SetupFlash_Return

SetupFlash_HandleLoadEvent:
	ld wa, 6:i3
	call Audio_DispatchCommand

SetupFlash_Return:
	ld xhl, 0:i3
	ret

FmmUtilityTitleFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jrl nz, FmmUtility_Return
	cp xde, 0x3
	jrl z, FmmUtility_HandleAbort
	cp xde, 0x2
	jrl nz, FmmUtility_Return
	ld (MEDLEY_PLAY_FLAG:16), 0
	ld wa, 1:i3
	calr InitializeOperationState
	ld xwa, 0x7b0013
	ld xbc, EVT_ON_WINDOW
	ld xde, 0:i3
	call ApDeliveryEvent
	ldmm8 0x7f5c, 0x8d37
	cpw (0x8500:16), 0
	jr ge, FmmUtility_DispatchState
	call GetDiskSizeInfo
	extz hl
	ld (0x8500:16), hl
	calr SignalProgressUpdate

FmmUtility_DispatchState:
	ld wa, (0x8500:16)
	cp wa, 1:i3
	jrl z, FmmUtility_HandleSuccess
	cp wa, 0:i3
	jrl z, FmmUtility_HandleError
	cp wa, 5:i3
	jr z, FmmUtility_HandleCancel
	cpw (0x8502:16), 0
	jr ge, FmmUtility_ScanFormat
	call GetEncodedFileSizeData
	ld (0x8502:16), hl
	call FileIO_SearchAndLoadFile
	call GetEncodedFreeSpaceData
	calr SignalProgressUpdate

FmmUtility_ScanFormat:
	cpw (0x8502:16), 0
	jrl nz, FmmUtility_ContinueWait
	cpw (0x8504:16), 0
	jr ge, FmmUtility_CheckCapacity
	call GetFileCountEncoded
	ld (0x8504:16), hl
	calr SignalProgressUpdate

FmmUtility_CheckCapacity:
	cpw (0x8504:16), 0
	jrl le, FmmUtility_ContinueWait
	cp (0x7f5c:16), 124
	jrl z, FmmUtility_ContinueWait
	ld xwa, 0x7b0013
	ld xbc, EVT_OFF_WINDOW
	ld xde, 0:i3
	call ApDeliveryEvent
	ldw wa, 0x7c
	jr FmmUtility_CallHandler

FmmUtility_HandleCancel:
	ld xwa, 0x7b0013
	ld xbc, EVT_OFF_WINDOW
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 1:i3
	call ApPostEvent
	ld a, (0x7f5c:16)
	extz wa
	call UI_PostModeChangeEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 0:i3
	call ApPostEvent
	ld (GLOBAL_ERROR_CODE:16), 0
	ldw wa, 0xee
	jr FmmUtility_ShowStatus

FmmUtility_HandleError:
	ld xwa, 0x7b0013
	ld xbc, EVT_OFF_WINDOW
	ld xde, 0:i3
	call ApDeliveryEvent
	ldw wa, 0x7d

FmmUtility_CallHandler:
	call UI_PostModeChangeEvent
	jr FmmUtility_Return

FmmUtility_HandleSuccess:
	calr ResetProgressIndication
	ld xwa, 0x7b0013
	ld xbc, EVT_OFF_WINDOW
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 1:i3
	call ApPostEvent
	ld a, (0x7f5c:16)
	extz wa
	call UI_PostModeChangeEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 0:i3
	call ApPostEvent
	ld (GLOBAL_ERROR_CODE:16), 2
	ldw wa, 0xee

FmmUtility_ShowStatus:
	call SoundCtrl_SendCommand
	jr FmmUtility_Return

FmmUtility_ContinueWait:
	ld xwa, 0x7b0013
	ld xbc, EVT_OFF_WINDOW
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_ALL_PAINT
	ld xde, 0:i3
	call ApPostEvent
	jr FmmUtility_Return

FmmUtility_HandleAbort:
	calr CancelOperationCleanup

FmmUtility_Return:
	ld xhl, 0:i3
	ret

FmmSmfUtilityTitleFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jrl nz, FmmSmfUtility_Return
	cp xde, 0x3
	jrl z, FmmSmfUtility_HandleAbort
	cp xde, 0x2
	jrl nz, FmmSmfUtility_Return
	ld (MEDLEY_PLAY_FLAG:16), 0
	ld wa, 1:i3
	calr InitializeOperationState
	ld xwa, 0x7b002a
	ld xbc, EVT_ON_WINDOW
	ld xde, 0:i3
	call ApDeliveryEvent
	ldmm8 0x7f5e, 0x8d37
	cpw (0x8500:16), 0
	jr ge, FmmSmfUtility_DispatchState
	call GetDiskSizeInfo
	extz hl
	ld (0x8500:16), hl
	calr SignalProgressUpdate

FmmSmfUtility_DispatchState:
	ld wa, (0x8500:16)
	cp wa, 1:i3
	jrl z, FmmSmfUtility_HandleSuccess
	cp wa, 0:i3
	jrl z, FmmSmfUtility_HandleError
	cp wa, 5:i3
	jr z, FmmSmfUtility_HandleCancel
	cpw (0x8504:16), 0
	jr ge, FmmSmfUtility_ScanFormat
	call GetFileCountEncoded
	ld (0x8504:16), hl
	call FileIO_SearchAndLoadFile
	call GetEncodedFreeSpaceData
	calr SignalProgressUpdate

FmmSmfUtility_ScanFormat:
	cpw (0x8504:16), 0
	jrl nz, FmmSmfUtility_ContinueWait
	cpw (0x8502:16), 0
	jr ge, FmmSmfUtility_CheckCapacity
	call GetEncodedFileSizeData
	ld (0x8502:16), hl
	calr SignalProgressUpdate

FmmSmfUtility_CheckCapacity:
	cpw (0x8502:16), 0
	jrl le, FmmSmfUtility_ContinueWait
	cp (0x7f5e:16), 123
	jrl z, FmmSmfUtility_ContinueWait
	ld xwa, 0x7b002a
	ld xbc, EVT_OFF_WINDOW
	ld xde, 0:i3
	call ApDeliveryEvent
	ldw wa, 0x7b
	jr FmmSmfUtility_CallHandler

FmmSmfUtility_HandleCancel:
	ld xwa, 0x7b002a
	ld xbc, EVT_OFF_WINDOW
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 1:i3
	call ApPostEvent
	ld a, (0x7f5e:16)
	extz wa
	call UI_PostModeChangeEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 0:i3
	call ApPostEvent
	ld (GLOBAL_ERROR_CODE:16), 0
	ldw wa, 0xee
	jr FmmSmfUtility_ShowStatus

FmmSmfUtility_HandleError:
	ld xwa, 0x7b002a
	ld xbc, EVT_OFF_WINDOW
	ld xde, 0:i3
	call ApDeliveryEvent
	ldw wa, 0x7d

FmmSmfUtility_CallHandler:
	call UI_PostModeChangeEvent
	jr FmmSmfUtility_Return

FmmSmfUtility_HandleSuccess:
	calr ResetProgressIndication
	ld xwa, 0x7b002a
	ld xbc, EVT_OFF_WINDOW
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 1:i3
	call ApPostEvent
	ld a, (0x7f5e:16)
	extz wa
	call UI_PostModeChangeEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 0:i3
	call ApPostEvent
	ld (GLOBAL_ERROR_CODE:16), 2
	ldw wa, 0xee

FmmSmfUtility_ShowStatus:
	call SoundCtrl_SendCommand
	jr FmmSmfUtility_Return

FmmSmfUtility_ContinueWait:
	ld xwa, 0x7b002a
	ld xbc, EVT_OFF_WINDOW
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_ALL_PAINT
	ld xde, 0:i3
	call ApPostEvent
	jr FmmSmfUtility_Return

FmmSmfUtility_HandleAbort:
	calr CancelOperationCleanup

FmmSmfUtility_Return:
	ld xhl, 0:i3
	ret

