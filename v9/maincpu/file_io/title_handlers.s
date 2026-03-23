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
	call_24 z, 0xf8b3d8
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
	cp xbc, 0x1e5000c
	jr z, SetupFlash_HandleLoadEvent
	cp xbc, 0x1e5000b
	jr nz, SetupFlash_Return
	stdi8 32578, 37
	ldw wa, 0xee
	call SoundCtrl_SendCommand
	lds wa, 6
	call CtrlPanel_IndicatorJumpTable
	stdi8 32578, 35
	ldw wa, 0xee
	call SoundCtrl_SendCommand
	jr SetupFlash_Return

SetupFlash_HandleLoadEvent:
	lds wa, 6
	call Audio_DispatchCommand

SetupFlash_Return:
	lds32 xhl, 0
	ret

FmmUtilityTitleFunc:
	cp xbc, 0x1c00013
	jrl nz, FmmUtility_Return
	cp xde, 0x3
	jrl z, FmmUtility_HandleAbort
	cp xde, 0x2
	jrl nz, FmmUtility_Return
	stdi8 34046, 0
	lds wa, 1
	calr InitializeOperationState
	ld xwa, 0x7b0013
	ld xbc, 0x1e50005
	lds32 xde, 0
	call ApDeliveryEvent
	ldmm8 32604, 36151
	cpdi16 34048, 0
	jr ge, FmmUtility_DispatchState
	call GetDiskSizeInfo
	extz hl
	stda16 34048, xhl
	calr SignalProgressUpdate

FmmUtility_DispatchState:
	ldda16 xwa, 34048
	cps wa, 1
	jrl z, FmmUtility_HandleSuccess
	cps wa, 0
	jrl z, FmmUtility_HandleError
	cps wa, 5
	jr z, FmmUtility_HandleCancel
	cpdi16 34050, 0
	jr ge, FmmUtility_ScanFormat
	call GetEncodedFileSizeData
	stda16 34050, xhl
	call FileIO_SearchAndLoadFile
	call GetEncodedFreeSpaceData
	calr SignalProgressUpdate

FmmUtility_ScanFormat:
	cpdi16 34050, 0
	jrl nz, FmmUtility_ContinueWait
	cpdi16 34052, 0
	jr ge, FmmUtility_CheckCapacity
	call GetFileCountEncoded
	stda16 34052, xhl
	calr SignalProgressUpdate

FmmUtility_CheckCapacity:
	cpdi16 34052, 0
	jrl le, FmmUtility_ContinueWait
	cpdi8 32604, 124
	jrl z, FmmUtility_ContinueWait
	ld xwa, 0x7b0013
	ld xbc, 0x1e50006
	lds32 xde, 0
	call ApDeliveryEvent
	ldw wa, 0x7c
	jr FmmUtility_CallHandler

FmmUtility_HandleCancel:
	ld xwa, 0x7b0013
	ld xbc, 0x1e50006
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 1
	call ApPostEvent
	ldda8 a, 32604
	extz wa
	call UI_PostModeChangeEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call ApPostEvent
	stdi8 32578, 0
	ldw wa, 0xee
	jr FmmUtility_ShowStatus

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
	calr ResetProgressIndication
	ld xwa, 0x7b0013
	ld xbc, 0x1e50006
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 1
	call ApPostEvent
	ldda8 a, 32604
	extz wa
	call UI_PostModeChangeEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call ApPostEvent
	stdi8 32578, 2
	ldw wa, 0xee

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
	cp xbc, 0x1c00013
	jrl nz, FmmSmfUtility_Return
	cp xde, 0x3
	jrl z, FmmSmfUtility_HandleAbort
	cp xde, 0x2
	jrl nz, FmmSmfUtility_Return
	stdi8 34046, 0
	lds wa, 1
	calr InitializeOperationState
	ld xwa, 0x7b002a
	ld xbc, 0x1e50005
	lds32 xde, 0
	call ApDeliveryEvent
	ldmm8 32606, 36151
	cpdi16 34048, 0
	jr ge, FmmSmfUtility_DispatchState
	call GetDiskSizeInfo
	extz hl
	stda16 34048, xhl
	calr SignalProgressUpdate

FmmSmfUtility_DispatchState:
	ldda16 xwa, 34048
	cps wa, 1
	jrl z, FmmSmfUtility_HandleSuccess
	cps wa, 0
	jrl z, FmmSmfUtility_HandleError
	cps wa, 5
	jr z, FmmSmfUtility_HandleCancel
	cpdi16 34052, 0
	jr ge, FmmSmfUtility_ScanFormat
	call GetFileCountEncoded
	stda16 34052, xhl
	call FileIO_SearchAndLoadFile
	call GetEncodedFreeSpaceData
	calr SignalProgressUpdate

FmmSmfUtility_ScanFormat:
	cpdi16 34052, 0
	jrl nz, FmmSmfUtility_ContinueWait
	cpdi16 34050, 0
	jr ge, FmmSmfUtility_CheckCapacity
	call GetEncodedFileSizeData
	stda16 34050, xhl
	calr SignalProgressUpdate

FmmSmfUtility_CheckCapacity:
	cpdi16 34050, 0
	jrl le, FmmSmfUtility_ContinueWait
	cpdi8 32606, 123
	jrl z, FmmSmfUtility_ContinueWait
	ld xwa, 0x7b002a
	ld xbc, 0x1e50006
	lds32 xde, 0
	call ApDeliveryEvent
	ldw wa, 0x7b
	jr FmmSmfUtility_CallHandler

FmmSmfUtility_HandleCancel:
	ld xwa, 0x7b002a
	ld xbc, 0x1e50006
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 1
	call ApPostEvent
	ldda8 a, 32606
	extz wa
	call UI_PostModeChangeEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call ApPostEvent
	stdi8 32578, 0
	ldw wa, 0xee
	jr FmmSmfUtility_ShowStatus

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
	calr ResetProgressIndication
	ld xwa, 0x7b002a
	ld xbc, 0x1e50006
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 1
	call ApPostEvent
	ldda8 a, 32606
	extz wa
	call UI_PostModeChangeEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call ApPostEvent
	stdi8 32578, 2
	ldw wa, 0xee

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

