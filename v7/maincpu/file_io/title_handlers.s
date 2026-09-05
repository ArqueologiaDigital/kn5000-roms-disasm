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
	call z, (FileIO_DetectFileTypeAndPost:24)
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
	cp	xbc, 31784972
	jr	z, 40
	cp	xbc, 31784971
	jr	nz, 38
	ld	(32422:16), 37
	ldw	wa, 238
	call	16355504
	ld	wa, 6:i3
	call	16535006
	ld	(32422:16), 35
	ldw	wa, 238
	call	16355504
	jr	6
SetupFlash_HandleLoadEvent:
	ld wa, 6:i3
	call Audio_DispatchCommand

SetupFlash_Return:
	lds32 xhl, 0
	ret
FmmUtilityTitleFunc:
	cp	xbc, 29360147
	jrl	nz, 387
	cp	xde, 3
	jrl	z, 375
	cp	xde, 2
	jrl	nz, 369
	ld	(33890:16), 0
	ld	wa, 1:i3
	calr	-1702
	ld	xwa, 8060947
	ld	xbc, 31784965
	lds32	xde, 0
	call	16423418
	.byte 0xc1, 0x9b, 0x8c, 0x19, 0xc0, 0x7e
	cpw	(33892:16), 0
	jr	ge, 13
	call	16290067
	extz	hl
	ld	(33892:16), hl
	calr	-1653
FmmUtility_DispatchState:
	ld	wa, (33892:16)
	cp	wa, 1:i3
	jrl	z, 195
	cp	wa, 0:i3
	jrl	z, 165
	cp	wa, 5:i3
	jr	z, 93
	cpw	(33894:16), 0
	jr	ge, 19
	call	16290928
	ld	(33894:16), hl
	call	16290176
	call	16290094
	calr	-1698
FmmUtility_ScanFormat:
	cpw	(33894:16), 0
	jrl	nz, 225
	cpw	(33896:16), 0
	jr	ge, 11
	call	16291947
	ld	(33896:16), hl
	calr	-1726
FmmUtility_CheckCapacity:
	cpw	(33896:16), 0
	jrl	le, 197
	cp	(32448:16), 124
	jrl	z, 189
	ld	xwa, 8060947
	ld	xbc, 31784966
	lds32	xde, 0
	call	16423418
	ldw	wa, 124
	jr	87
FmmUtility_HandleCancel:
	ld	xwa, 8060947
	ld	xbc, 31784966
	lds32	xde, 0
	call	16423418
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 1
	call	16423243
	ld	a, (32448:16)
	extz	wa
	call	16355459
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 0
	call	16423243
	ld	(32422:16), 0
	ldw	wa, 238
	jr	94
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
	calr	63480
	ld	xwa, 8060947
	ld	xbc, 31784966
	lds32	xde, 0
	call	16423418
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 1
	call	16423243
	ld	a, (32448:16)
	extz	wa
	call	16355459
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 0
	call	16423243
	ld	(32422:16), 2
	ldw	wa, 238
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
	cp	xbc, 29360147
	jrl	nz, 387
	cp	xde, 3
	jrl	z, 375
	cp	xde, 2
	jrl	nz, 369
	ld	(33890:16), 0
	ld	wa, 1:i3
	calr	-2101
	ld	xwa, 8060970
	ld	xbc, 31784965
	lds32	xde, 0
	call	16423418
	.byte 0xc1, 0x9b, 0x8c, 0x19, 0xc2, 0x7e
	cpw	(33892:16), 0
	jr	ge, 13
	call	16290067
	extz	hl
	ld	(33892:16), hl
	calr	-2052
FmmSmfUtility_DispatchState:
	ld	wa, (33892:16)
	cp	wa, 1:i3
	jrl	z, 195
	cp	wa, 0:i3
	jrl	z, 165
	cp	wa, 5:i3
	jr	z, 93
	cpw	(33896:16), 0
	jr	ge, 19
	call	16291947
	ld	(33896:16), hl
	call	16290176
	call	16290094
	calr	-2097
FmmSmfUtility_ScanFormat:
	cpw	(33896:16), 0
	jrl	nz, 225
	cpw	(33894:16), 0
	jr	ge, 11
	call	16290928
	ld	(33894:16), hl
	calr	-2125
FmmSmfUtility_CheckCapacity:
	cpw	(33894:16), 0
	jrl	le, 197
	cp	(32450:16), 123
	jrl	z, 189
	ld	xwa, 8060970
	ld	xbc, 31784966
	lds32	xde, 0
	call	16423418
	ldw	wa, 123
	jr	87
FmmSmfUtility_HandleCancel:
	ld	xwa, 8060970
	ld	xbc, 31784966
	lds32	xde, 0
	call	16423418
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 1
	call	16423243
	ld	a, (32450:16)
	extz	wa
	call	16355459
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 0
	call	16423243
	ld	(32422:16), 0
	ldw	wa, 238
	jr	94
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
	calr	63081
	ld	xwa, 8060970
	ld	xbc, 31784966
	lds32	xde, 0
	call	16423418
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 1
	call	16423243
	ld	a, (32450:16)
	extz	wa
	call	16355459
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 0
	call	16423243
	ld	(32422:16), 2
	ldw	wa, 238
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

