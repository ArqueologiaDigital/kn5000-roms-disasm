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
	ld xhl, 0:i3
	ret

SaveTtlJgFunc:
	cp xbc, 0x1c00007
	jr nz, SaveTtl_Return
	ldw wa, 0x67
	calr FileIO_GetDiskCapacity

SaveTtl_Return:
	ld xhl, 0:i3
	ret

SaveSmfTtlJgFunc:
	cp xbc, 0x1c00007
	jr nz, SaveSmfTtl_Return
	ldw wa, 0x6b
	calr FileIO_GetDiskCapacity

SaveSmfTtl_Return:
	ld xhl, 0:i3
	ret

DirectPlayTtlJgFunc:
	cp xbc, 0x1c00007
	call z, (FileIO_DetectFileTypeAndPost:24)
	ld xhl, 0:i3
	ret

SongMedleyTtlJgFunc:
	cp xbc, 0x1c00007
	jr nz, SongMedleyTtl_Return
	ldw wa, 0x77
	calr FileIO_GetDiskCapacity

SongMedleyTtl_Return:
	ld xhl, 0:i3
	ret

SetupFlashFunc:
	cp	xbc, 31784972
	jr	z, SetupFlash_HandleLoadEvent
	cp	xbc, 31784971
	jr	nz, SetupFlash_Return
	ld	(32422:16), 37
	ldw	wa, 238
	call	SoundCtrl_SendCommand
	ld	wa, 6:i3
	call	CtrlPanel_IndicatorJumpTable
	ld	(32422:16), 35
	ldw	wa, 238
	call	SoundCtrl_SendCommand
	jr	SetupFlash_Return
SetupFlash_HandleLoadEvent:
	ld wa, 6:i3
	call Audio_DispatchCommand

SetupFlash_Return:
	ld xhl, 0:i3
	ret
FmmUtilityTitleFunc:
	cp	xbc, 29360147
	jrl	nz, FmmUtility_Return
	cp	xde, 3
	jrl	z, FmmUtility_HandleAbort
	cp	xde, 2
	jrl	nz, FmmUtility_Return
	ld	(33890:16), 0
	ld	wa, 1:i3
	calr	InitializeOperationState
	ld	xwa, 8060947
	ld	xbc, 31784965
	ld	xde, 0:i3
	call	ApDeliveryEvent
	.byte 0xc1, 0x9b, 0x8c, 0x19, 0xc0, 0x7e
	cpw	(33892:16), 0
	jr	ge, FmmUtility_DispatchState
	call	GetDiskSizeInfo
	extz	hl
	ld	(33892:16), hl
	calr	SignalProgressUpdate
FmmUtility_DispatchState:
	ld	wa, (33892:16)
	cp	wa, 1:i3
	jrl	z, FmmUtility_HandleSuccess
	cp	wa, 0:i3
	jrl	z, FmmUtility_HandleError
	cp	wa, 5:i3
	jr	z, FmmUtility_HandleCancel
	cpw	(33894:16), 0
	jr	ge, FmmUtility_ScanFormat
	call	GetEncodedFileSizeData
	ld	(33894:16), hl
	call	FileIO_SearchAndLoadFile
	call	GetEncodedFreeSpaceData
	calr	SignalProgressUpdate
FmmUtility_ScanFormat:
	cpw	(33894:16), 0
	jrl	nz, FmmUtility_ContinueWait
	cpw	(33896:16), 0
	jr	ge, FmmUtility_CheckCapacity
	call	GetFileCountEncoded
	ld	(33896:16), hl
	calr	SignalProgressUpdate
FmmUtility_CheckCapacity:
	cpw	(33896:16), 0
	jrl	le, FmmUtility_ContinueWait
	cp	(32448:16), 124
	jrl	z, FmmUtility_ContinueWait
	ld	xwa, 8060947
	ld	xbc, 31784966
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ldw	wa, 124
	jr	FmmUtility_CallHandler
FmmUtility_HandleCancel:
	ld	xwa, 8060947
	ld	xbc, 31784966
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 4294967295
	ld	xbc, 31457438
	ld	xde, 1:i3
	call	ApPostEvent
	ld	a, (32448:16)
	extz	wa
	call	UI_PostModeChangeEvent
	ld	xwa, 4294967295
	ld	xbc, 31457438
	ld	xde, 0:i3
	call	ApPostEvent
	ld	(32422:16), 0
	ldw	wa, 238
	jr	FmmUtility_ShowStatus
FmmUtility_HandleError:
	ld xwa, 0x7b0013
	ld xbc, 0x1e50006
	ld xde, 0:i3
	call ApDeliveryEvent
	ldw wa, 0x7d

FmmUtility_CallHandler:
	call UI_PostModeChangeEvent
	jr FmmUtility_Return

FmmUtility_HandleSuccess:
	calr	ResetProgressIndication
	ld	xwa, 8060947
	ld	xbc, 31784966
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 4294967295
	ld	xbc, 31457438
	ld	xde, 1:i3
	call	ApPostEvent
	ld	a, (32448:16)
	extz	wa
	call	UI_PostModeChangeEvent
	ld	xwa, 4294967295
	ld	xbc, 31457438
	ld	xde, 0:i3
	call	ApPostEvent
	ld	(32422:16), 2
	ldw	wa, 238
FmmUtility_ShowStatus:
	call SoundCtrl_SendCommand
	jr FmmUtility_Return

FmmUtility_ContinueWait:
	ld xwa, 0x7b0013
	ld xbc, 0x1e50006
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	ld xde, 0:i3
	call ApPostEvent
	jr FmmUtility_Return

FmmUtility_HandleAbort:
	calr CancelOperationCleanup

FmmUtility_Return:
	ld xhl, 0:i3
	ret
FmmSmfUtilityTitleFunc:
	cp	xbc, 29360147
	jrl	nz, FmmSmfUtility_Return
	cp	xde, 3
	jrl	z, FmmSmfUtility_HandleAbort
	cp	xde, 2
	jrl	nz, FmmSmfUtility_Return
	ld	(33890:16), 0
	ld	wa, 1:i3
	calr	InitializeOperationState
	ld	xwa, 8060970
	ld	xbc, 31784965
	ld	xde, 0:i3
	call	ApDeliveryEvent
	.byte 0xc1, 0x9b, 0x8c, 0x19, 0xc2, 0x7e
	cpw	(33892:16), 0
	jr	ge, FmmSmfUtility_DispatchState
	call	GetDiskSizeInfo
	extz	hl
	ld	(33892:16), hl
	calr	SignalProgressUpdate
FmmSmfUtility_DispatchState:
	ld	wa, (33892:16)
	cp	wa, 1:i3
	jrl	z, FmmSmfUtility_HandleSuccess
	cp	wa, 0:i3
	jrl	z, FmmSmfUtility_HandleError
	cp	wa, 5:i3
	jr	z, FmmSmfUtility_HandleCancel
	cpw	(33896:16), 0
	jr	ge, FmmSmfUtility_ScanFormat
	call	GetFileCountEncoded
	ld	(33896:16), hl
	call	FileIO_SearchAndLoadFile
	call	GetEncodedFreeSpaceData
	calr	SignalProgressUpdate
FmmSmfUtility_ScanFormat:
	cpw	(33896:16), 0
	jrl	nz, FmmSmfUtility_ContinueWait
	cpw	(33894:16), 0
	jr	ge, FmmSmfUtility_CheckCapacity
	call	GetEncodedFileSizeData
	ld	(33894:16), hl
	calr	SignalProgressUpdate
FmmSmfUtility_CheckCapacity:
	cpw	(33894:16), 0
	jrl	le, FmmSmfUtility_ContinueWait
	cp	(32450:16), 123
	jrl	z, FmmSmfUtility_ContinueWait
	ld	xwa, 8060970
	ld	xbc, 31784966
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ldw	wa, 123
	jr	FmmSmfUtility_CallHandler
FmmSmfUtility_HandleCancel:
	ld	xwa, 8060970
	ld	xbc, 31784966
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 4294967295
	ld	xbc, 31457438
	ld	xde, 1:i3
	call	ApPostEvent
	ld	a, (32450:16)
	extz	wa
	call	UI_PostModeChangeEvent
	ld	xwa, 4294967295
	ld	xbc, 31457438
	ld	xde, 0:i3
	call	ApPostEvent
	ld	(32422:16), 0
	ldw	wa, 238
	jr	FmmSmfUtility_ShowStatus
FmmSmfUtility_HandleError:
	ld xwa, 0x7b002a
	ld xbc, 0x1e50006
	ld xde, 0:i3
	call ApDeliveryEvent
	ldw wa, 0x7d

FmmSmfUtility_CallHandler:
	call UI_PostModeChangeEvent
	jr FmmSmfUtility_Return

FmmSmfUtility_HandleSuccess:
	calr	ResetProgressIndication
	ld	xwa, 8060970
	ld	xbc, 31784966
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 4294967295
	ld	xbc, 31457438
	ld	xde, 1:i3
	call	ApPostEvent
	ld	a, (32450:16)
	extz	wa
	call	UI_PostModeChangeEvent
	ld	xwa, 4294967295
	ld	xbc, 31457438
	ld	xde, 0:i3
	call	ApPostEvent
	ld	(32422:16), 2
	ldw	wa, 238
FmmSmfUtility_ShowStatus:
	call SoundCtrl_SendCommand
	jr FmmSmfUtility_Return

FmmSmfUtility_ContinueWait:
	ld xwa, 0x7b002a
	ld xbc, 0x1e50006
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	ld xde, 0:i3
	call ApPostEvent
	jr FmmSmfUtility_Return

FmmSmfUtility_HandleAbort:
	calr CancelOperationCleanup

FmmSmfUtility_Return:
	ld xhl, 0:i3
	ret

