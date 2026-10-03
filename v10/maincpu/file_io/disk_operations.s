; =============================================================================
; file_io/disk_operations.asm - Disk and File Operations
; =============================================================================
; File copy, rename, format, and disk information routines.
;
; Key routines:
;   FileCopyFunc, FileRenameFunc     - File copy and rename
;   FileRenameSmfFunc                - SMF file rename
;   FmmFormatFunc                    - Disk format
;   UtilityTtlJgFunc                 - Utility title handler
;   FmmLoadTitleFunc, FmmSaveTitleFunc - Load/Save titles
;   DiskNameFunc, DiskInfoFunc       - Disk information
;   SongNameFunc                     - Song naming
;   SaveFileNameNumFunc, SaveFileNameFunc - Save filename handling
;   CurFileNameFunc                  - Current filename
; =============================================================================

FileCopyFunc:
	push xiz
	ld xiz, xde
	cp xbc, EVT_INDEXSW_DOWN
	jrl z, FCopy_HandleScroll
	cp xbc, EVT_INDEXSW_UP
	jrl z, FCopy_HandleScroll
	cp xbc, EVT_PAINT
	jr z, FCopy_HandleExecute
	cp xbc, EVT_PS_FILE_NAME_BOX_ID
	jrl nz, FCopy_Return
	ld (0x7f60:16), xiz
	call GetCurrentFileIndex
	ld (0x7f64:16), hl
	cp hl, 0:i3
	jr lt, FCopy_ScrollNeg_Reset
	cp hl, 0x13
	jr ge, FCopy_ScrollDown_Clamp
	inc 1, hl
	ld (0x7f66:16), hl
	jrl FCopy_Return

FCopy_ScrollDown_Clamp:
	dec 1, hl
	ld (0x7f66:16), hl
	jrl FCopy_Return

FCopy_ScrollNeg_Reset:
	ldw (0x7f64:16), 0
	ldw (0x7f66:16), 1
	jrl FCopy_Return

FCopy_HandleExecute:
	ld (0x850c:16), 0
	ld wa, (0x7f66:16)
	call GetFileEntryPtr
	ld xbc, xhl
	lda xwa, (0x850d:16)
	ld de, (0x7f66:16)
	inc 1, de
	pushw 0x6
	pushw 0x0
	call FileIO_ReadHeader_ParseLoop
	ld xwa, (0x7f60:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x850c
	call ApPostEvent
	jrl FCopy_Return

FCopy_HandleScroll:
	or xiz, xiz
	jrl nz, FCopy_HandleCopyContext
	ld wa, (0x7f66:16)
	ld de, wa
	cp xbc, EVT_INDEXSW_DOWN
	jr nz, FCopy_ScrollUp_Adjust
	cp wa, 0:i3
	jr le, FCopy_ScrollDown_CheckMin
	dec 1, wa
	ld (0x7f66:16), wa

FCopy_ScrollDown_CheckMin:
	ld wa, (0x7f66:16)
	cp wa, (0x7f64:16)
	jr nz, FCopy_ScrollDown_Reload
	cp wa, 0:i3
	jr le, FCopy_ScrollDown_RestoreOld
	dec 1, wa
	ld (0x7f66:16), wa
	jr FCopy_Scroll_Apply

FCopy_ScrollDown_RestoreOld:
	ld (0x7f66:16), de

FCopy_ScrollDown_Reload:
	ld wa, (0x7f66:16)

FCopy_Scroll_Apply:
	cp wa, de
	jrl z, FCopy_Return
	ld (0x850c:16), 0
	ld wa, (0x7f66:16)
	call GetFileEntryPtr
	ld xbc, xhl
	lda xwa, (0x850d:16)
	ld de, (0x7f66:16)
	inc 1, de
	pushw 0x6
	pushw 0x0
	call FileIO_ReadHeader_ParseLoop
	ld xwa, (0x7f60:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x850c
	jr FCopy_DispatchFA9D58

FCopy_ScrollUp_Adjust:
	cp xbc, EVT_INDEXSW_UP
	jr nz, FCopy_ScrollDown_Reload
	cp wa, 0x13
	jr ge, FCopy_ScrollUp_CheckMax
	inc 1, wa
	ld (0x7f66:16), wa

FCopy_ScrollUp_CheckMax:
	ld wa, (0x7f66:16)
	cp wa, (0x7f64:16)
	jr nz, FCopy_ScrollDown_Reload
	cp wa, 0x13
	jr ge, FCopy_ScrollDown_RestoreOld
	inc 1, wa
	ld (0x7f66:16), wa
	jr FCopy_Scroll_Apply

FCopy_HandleCopyContext:
	cp xiz, 0x8
	jrl nz, FCopy_CopyExecute
	call CheckFileSystemStatus
	cp hl, 0:i3
	jrl z, FCopy_CopyExecute
	ld wa, (0x7f66:16)
	call FileIO_GetRecordFlags
	cp hl, 0:i3
	jr z, FCopy_CopyConfirm_Execute
	cp (0x0340ea:24), 0x00
	jr z, FCopy_CopyConfirm_Execute
	ld xwa, 0xffffffff
	ld xbc, EVT_NOT_PARA_DRAW
	ld xde, 1:i3
	call ApPostEvent
	ld xwa, 0x600037
	ld xbc, EVT_SHOW
	ld xde, 0:i3

FCopy_DispatchFA9D58:
	call ApPostEvent
	jrl FCopy_Return

FCopy_CopyConfirm_Execute:
	ld xwa, 0x600026
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	call ApPostEvent
	ld wa, 0:i3
	calr InitializeOperationState
	ld wa, (0x7f66:16)
	call WriteFileWithVerify
	ld wa, hl
	ld bc, 5:i3
	calr FileIO_ValidateSignedValue
	ld (GLOBAL_ERROR_CODE:16), l
	calr SignalProgressUpdate
	call FileIO_ResetCurrentRecord
	call GetEncodedFreeSpaceData
	call GetEncodedFileSizeData
	ld (0x8502:16), hl
	ld xwa, 0x600026
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 1:i3
	call ApPostEvent
	ldw wa, 0x7b
	call UI_PostModeChangeEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 0:i3
	call ApPostEvent
	ldw wa, 0xee
	jr FCopy_NotifyComplete

FCopy_CopyExecute:
	cp xiz, 0x32
	jr nz, FCopy_Return
	ld xwa, 0x600026
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	call ApPostEvent
	ld wa, 0:i3
	calr InitializeOperationState
	ld wa, (0x7f66:16)
	call WriteFileWithVerify
	ld wa, hl
	ld bc, 5:i3
	calr FileIO_ValidateSignedValue
	ld (GLOBAL_ERROR_CODE:16), l
	calr SignalProgressUpdate
	call FileIO_ResetCurrentRecord
	call GetEncodedFreeSpaceData
	call GetEncodedFileSizeData
	ld (0x8502:16), hl
	ld xwa, 0x600026
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 1:i3
	call ApPostEvent
	ldw wa, 0x7b
	call UI_PostModeChangeEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 0:i3
	call ApPostEvent
	ldw wa, 0xee

FCopy_NotifyComplete:
	call SoundCtrl_SendCommand

FCopy_Return:
	ld xhl, 0:i3
	pop xiz
	ret

FileRenameFunc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	cp xbc, EVT_SET_STRING
	jrl z, FRename_HandleApply
	cp xbc, EVT_GET_STRING
	jrl nz, FRename_Return
	call GetCurrentFileIndex
	cp hl, 0:i3
	jr lt, FRename_TextChange_Error
	lda xiz, (0x8870:16)
	ld wa, hl
	call GetFileEntryPtr
	ld xbc, xhl
	ld xwa, xiz
	call FileIO_CopyString
	ld iy, 0:i3
	lda xix, (CType_ClassTable:24)
	lda xwa, (0x8870:16)
	ld xhl, xwa
	jr FRename_PadLoop_Cond

FRename_PadLoop_CheckChar:
	extz bc
	ld	c, (xix+bc)
	and c, 0x7
	jr nz, FRename_PadLoop_Advance
	ld (xde), 0x5f

FRename_PadLoop_Advance:
	inc 1, iy

FRename_PadLoop_Cond:
	cp iy, 6:i3
	jr ge, FRename_PadLoop_Fill
	lda	xde, (xhl+iy)
	ld c, (xde)
	cp c, 0:i3
	jr nz, FRename_PadLoop_CheckChar

FRename_PadLoop_Fill:
	cp iy, 6:i3
	jr ge, FRename_PadDone
	ld xbc, xwa

FRename_FillLoop:
	ld	(xbc+iy), 0x5f
	inc 1, iy
	cp iy, 6:i3
	jr lt, FRename_FillLoop

FRename_PadDone:
	ld (xwa + 6), 0x0
	jr FRename_TextChange_SendApply

FRename_TextChange_Error:
	ld xwa, 0x8870
	ld xbc, FRename_TextChange_Error_Str_Under_Under_Under_Under
	call FileIO_CopyString

FRename_TextChange_SendApply:
	ld xwa, (xsp + 4)
	ld xbc, EVT_SET_STRING
	ld xde, 0x8870
	call ApPostEvent
	jr FRename_Return

FRename_HandleApply:
	call CheckFileSystemStatus
	cp hl, 0:i3
	jr z, FRename_Return
	ld xwa, 0x8870
	ld xbc, (xsp + 4)
	call FileIO_CopyString
	ld xwa, 0x600026
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	call ApPostEvent
	ld wa, 0:i3
	calr InitializeOperationState
	ld xwa, 0x8870
	call ReadDualFile
	ld wa, hl
	ld bc, 5:i3
	calr FileIO_ValidateSignedValue
	ld (GLOBAL_ERROR_CODE:16), l
	calr SignalProgressUpdate
	call GetEncodedFileSizeData
	ld (0x8502:16), hl
	ld xwa, 0x600026
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ldw wa, 0xee
	call SoundCtrl_SendCommand

FRename_Return:
	ld xhl, 0:i3
	pop xiz
	inc 4, xsp
	ret

FileRenameSmfFunc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	cp xbc, EVT_SET_STRING
	jrl z, FRenameSmf_HandleApply
	cp xbc, EVT_GET_STRING
	jrl nz, FRenameSmf_Return
	call GetFirstPageBase
	cp hl, 0:i3
	jr lt, FRenameSmf_TextChange_Error
	lda xiz, (0x8870:16)
	ld wa, hl
	call GetRecordPtrForFile
	ld xbc, xhl
	ld xwa, xiz
	call FileIO_CopyString
	ld iy, 0:i3
	lda xix, (CType_ClassTable:24)
	lda xwa, (0x8870:16)
	ld xhl, xwa
	jr FRenameSmf_PadLoop_Cond

FRenameSmf_PadLoop_CheckChar:
	extz bc
	ld	c, (xix+bc)
	and c, 0x7
	jr nz, FRenameSmf_PadLoop_Advance
	ld (xde), 0x5f

FRenameSmf_PadLoop_Advance:
	inc 1, iy

FRenameSmf_PadLoop_Cond:
	cp iy, 0x8
	jr ge, FRenameSmf_PadLoop_Fill
	lda	xde, (xhl+iy)
	ld c, (xde)
	cp c, 0:i3
	jr nz, FRenameSmf_PadLoop_CheckChar

FRenameSmf_PadLoop_Fill:
	cp iy, 0x8
	jr ge, FRenameSmf_PadDone
	ld xbc, xwa

FRenameSmf_FillLoop:
	ld	(xbc+iy), 0x5f
	inc 1, iy
	cp iy, 0x8
	jr lt, FRenameSmf_FillLoop

FRenameSmf_PadDone:
	ld (xwa + 8), 0x0
	jr FRenameSmf_TextChange_SendApply

FRenameSmf_TextChange_Error:
	ld xwa, 0x8870
	ld xbc, FRenameSmf_TextChange_Error_Str_Under_Under_Under_Under
	call FileIO_CopyString

FRenameSmf_TextChange_SendApply:
	ld xwa, (xsp + 4)
	ld xbc, EVT_SET_STRING
	ld xde, 0x8870
	call ApPostEvent
	jr FRenameSmf_Return

FRenameSmf_HandleApply:
	ld xwa, 0x8870
	ld xbc, (xsp + 4)
	call FileIO_CopyString
	ld xwa, 0x8870
	ld xbc, FRenameSmf_HandleApply_Str_MID
	call FileIO_BuildFilePath
	ld xwa, 0x600026
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	call ApPostEvent
	ld wa, 0:i3
	calr InitializeOperationState
	ld xwa, 0x8870
	call SearchAndOpen
	ld wa, hl
	ld bc, 5:i3
	calr FileIO_ValidateSignedValue
	ld (GLOBAL_ERROR_CODE:16), l
	calr SignalProgressUpdate
	call GetFileCountEncoded
	ld (0x8504:16), hl
	ld xwa, 0x600026
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ldw wa, 0xee
	call SoundCtrl_SendCommand

FRenameSmf_Return:
	ld xhl, 0:i3
	pop xiz
	inc 4, xsp
	ret

FmmFormatFunc:
	pushw iz
	cp xbc, EVT_SW_IN
	jrl z, FmmFmt_HandleProgress
	cp xbc, EVT_ACTIVATE_STATE
	jrl nz, FmmFmt_Return
	cp xde, 0x3
	jr z, FmmFmt_HandleCancel
	cp xde, 0x2
	jrl nz, FmmFmt_Return
	ld wa, 1:i3
	calr InitializeOperationState
	ldmm8 0x7f6a, PREVIOUS_TITLE
	cpw (0x8500:16), 0
	jr ge, FmmFmt_InitPhase_CheckDrive
	call GetDiskSizeInfo
	extz hl
	ld (0x8500:16), hl
	calr SignalProgressUpdate

FmmFmt_InitPhase_CheckDrive:
	ld wa, (0x8500:16)
	cp wa, 2:i3
	jr z, FmmFmt_InitPhase_DriveType23
	cp wa, 3:i3
	jr nz, FmmFmt_InitPhase_OtherDrive

FmmFmt_InitPhase_DriveType23:
	ld (0x7f68:16), a
	ld xwa, 0x7b0036
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	call ApPostEvent
	ld (MEDLEY_PLAY_FLAG:16), 0
	jr FmmFmt_InitPhase_SetActive

FmmFmt_InitPhase_OtherDrive:
	ld xwa, 0x7b003f
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	call ApPostEvent
	ld (MEDLEY_PLAY_FLAG:16), 2

FmmFmt_InitPhase_SetActive:
	ld (0x7f6c:16), 1
	jrl FmmFmt_Return

FmmFmt_HandleCancel:
	calr CancelOperationCleanup
	ld (MEDLEY_PLAY_FLAG:16), 0
	ld (0x7f6c:16), 0
	jrl FmmFmt_Return

FmmFmt_HandleProgress:
	cp (0x7f6c:16), 0
	jrl z, FmmFmt_Return
	ld a, (0x7f6a:16)
	extz wa
	cp xde, 0xf
	jrl z, FmmFmt_HandleAbortFinal
	ld c, (MEDLEY_PLAY_FLAG:16)
	cp xde, 0xb
	jrl z, FmmFmt_HandleAbort
	cp xde, 0xa
	jrl nz, FmmFmt_Return
	ld a, c
	cp c, 0:i3
	jrl nz, FmmFmt_ExecutePhase2
	ld xwa, 0x600026
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	call ApPostEvent
	ld wa, 0:i3
	calr InitializeOperationState
	ld a, (0x7f68:16)
	extz wa
	call FileIO_ValidateRecord_CheckSize
	ld iz, hl
	calr SignalProgressUpdate
	calr ResetProgressIndication
	ld xwa, 0x600026
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	cp iz, 0:i3
	jr ge, FmmFmt_FormatSuccess
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 1:i3
	call ApPostEvent
	ld a, (0x7f6a:16)
	extz wa
	call UI_PostModeChangeEvent
	ld (0x7f6c:16), 0
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 0:i3
	call ApPostEvent
	ld wa, iz
	ldw bc, 0x8
	calr FileIO_ValidateSignedValue
	ld (GLOBAL_ERROR_CODE:16), l
	ldw wa, 0xee
	call SoundCtrl_SendCommand
	jrl FmmFmt_NotifyComplete

FmmFmt_FormatSuccess:
	ld xwa, 0x7b0036
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, 0x7b0031
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	call ApPostEvent
	ld (MEDLEY_PLAY_FLAG:16), 1
	jr FmmFmt_Return

FmmFmt_ExecutePhase2:
	cp a, 2:i3
	jr nz, FmmFmt_Return
	ld (0x7f68:16), 3
	ld xwa, 0x7b003f
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, 0x7b0036
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	jr FmmFmt_DispatchAndNotify

FmmFmt_HandleAbort:
	ld e, c
	cp c, 0:i3
	jr nz, FmmFmt_AbortPhase2
	call UI_PostModeChangeEvent
	ld (0x7f6c:16), 0
	jr FmmFmt_Return

FmmFmt_AbortPhase2:
	cp e, 2:i3
	jr nz, FmmFmt_Return
	ld (0x7f68:16), 2
	ld xwa, 0x7b003f
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, 0x7b0036
	ld xbc, EVT_SHOW
	ld xde, 0:i3

FmmFmt_DispatchAndNotify:
	call ApPostEvent
	jr FmmFmt_NotifyComplete

FmmFmt_HandleAbortFinal:
	call UI_PostModeChangeEvent
	ld (0x7f6c:16), 0

FmmFmt_NotifyComplete:
	ld (MEDLEY_PLAY_FLAG:16), 0

FmmFmt_Return:
	ld xhl, 0:i3
	popw iz
	ret

UtilityTtlJgFunc:
	cp xbc, EVT_SW_IN
	jr nz, UtilTtlJg_Return
	ldw wa, 0x7b
	ldw bc, 0x7c
	calr FileIO_DiskEventDispatch

UtilTtlJg_Return:
	ld xhl, 0:i3
	ret

FmmLoadTitleFunc:
	pushw iz
	cp xbc, EVT_SW_IN
	jrl z, FmmLoadTtl_HandleOk
	cp xbc, EVT_ACTIVATE_STATE
	jrl nz, FmmLoadTtl_Return
	cp xde, 0x3
	jrl z, FmmLoadTtl_HandleCancelOp
	cp xde, 0x9
	jrl z, FmmLoadTtl_HandleScrollNav
	cp xde, 0x2
	jrl nz, FmmLoadTtl_Return
	ld (MEDLEY_PLAY_FLAG:16), 0
	ldmm16 0x7f70, 0x8500
	ld wa, 1:i3
	calr InitializeOperationState
	ld xwa, 0x600026
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	call ApPostEvent
	ldmm8 0x7f6e, PREVIOUS_TITLE
	cpw (0x8500:16), 0
	jr ge, FmmLoadTtl_StateDispatch
	call GetDiskSizeInfo
	extz hl
	ld (0x8500:16), hl
	calr SignalProgressUpdate

FmmLoadTtl_StateDispatch:
	ld wa, (0x8500:16)
	cp wa, 1:i3
	jrl z, FmmLoadTtl_StateSuccess
	cp wa, 0:i3
	jrl z, FmmLoadTtl_StateIdle
	cp wa, 5:i3
	jr z, FmmLoadTtl_StateCancelLoad
	cpw (0x8502:16), 0
	jr ge, FmmLoadTtl_CheckFileHandle
	call GetEncodedFileSizeData
	ld (0x8502:16), hl
	call FileIO_SearchAndLoadFile
	call GetEncodedFreeSpaceData
	calr SignalProgressUpdate

FmmLoadTtl_CheckFileHandle:
	cpw (0x8502:16), 0
	jrl nz, FmmLoadTtl_LoadSlots
	cpw (0x8504:16), 0
	jr ge, FmmLoadTtl_CheckSmfHandle
	call GetFileCountEncoded
	ld (0x8504:16), hl
	calr SignalProgressUpdate

FmmLoadTtl_CheckSmfHandle:
	cpw (0x8504:16), 0
	jrl le, FmmLoadTtl_LoadSlots
	cp (0x7f6e:16), 100
	jrl z, FmmLoadTtl_LoadSlots
	ld xwa, 0x600026
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ldw wa, 0x64
	jrl FmmLoadTtl_PlaySound

FmmLoadTtl_StateCancelLoad:
	ld xwa, 0x600026
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 1:i3
	call ApPostEvent
	ld a, (0x7f6e:16)
	extz wa
	call UI_PostModeChangeEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 0:i3
	call ApPostEvent
	ld (GLOBAL_ERROR_CODE:16), 0
	ldw wa, 0xee
	jr FmmLoadTtl_NotifyComplete

FmmLoadTtl_StateIdle:
	ld xwa, 0x600026
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ldw wa, 0x7d
	jrl FmmLoadTtl_PlaySound

FmmLoadTtl_StateSuccess:
	ld xwa, 0x600026
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	calr ResetProgressIndication
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 1:i3
	call ApPostEvent
	ld a, (0x7f6e:16)
	extz wa
	call UI_PostModeChangeEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 0:i3
	call ApPostEvent
	ld (GLOBAL_ERROR_CODE:16), 2
	ldw wa, 0xee

FmmLoadTtl_NotifyComplete:
	call SoundCtrl_SendCommand
	jrl FmmLoadTtl_Return

FmmLoadTtl_LoadSlots:
	ld xwa, 0x600026
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_ALL_PAINT
	ld xde, 0:i3
	call ApPostEvent
	ld (0x89fc:16), 0
	ld (0x89fe:16), 0
	ld (0x8a00:16), 0
	ld (0x8a02:16), 0
	ld (0x8a04:16), 0
	ld (0x8a06:16), 0
	ld (0x8a08:16), 0
	ld iz, 0:i3

FmmLoadTtl_SlotLoop:
	ldto_berp A, 0xf8
	extz wa
	call FileIO_FormatName_Loop
	inc 1, iz
	cp iz, 0x8
	jr lt, FmmLoadTtl_SlotLoop
	ld (0x89f8:16), 4
	jr FmmLoadTtl_Return

FmmLoadTtl_HandleScrollNav:
	cpw (0x7f70:16), 0
	jr lt, FmmLoadTtl_Return
	call GetCurrentFileIndex
	ld iz, hl
	cp iz, 0:i3
	jr lt, FmmLoadTtl_Return
	cp iz, 0x13
	jr ge, FmmLoadTtl_Return
	ld wa, iz
	inc 1, wa
	call NotifyUIOfSelectionChange
	jr FmmLoadTtl_Return

FmmLoadTtl_HandleCancelOp:
	calr CancelOperationCleanup
	ld xwa, 0x610001
	ld xbc, EVT_SET_PAGE
	ld xde, 1:i3
	call ApPostEvent
	jr FmmLoadTtl_Return

FmmLoadTtl_HandleOk:
	cp xde, 0xf
	jr nz, FmmLoadTtl_Return
	cp (CURRENT_MODE:16), 7
	jr nz, FmmLoadTtl_Ok_DefaultSound
	ldw wa, 0xd6
	jr FmmLoadTtl_PlaySound

FmmLoadTtl_Ok_DefaultSound:
	ldw wa, 0x60

FmmLoadTtl_PlaySound:
	call UI_PostModeChangeEvent

FmmLoadTtl_Return:
	ld xhl, 0:i3
	popw iz
	ret

FmmSaveTitleFunc:
	pushw iz
	cp xbc, EVT_SW_IN
	jrl z, FmmSaveTtl_HandleOk
	cp xbc, EVT_ACTIVATE_STATE
	jrl nz, FmmSaveTtl_Return
	cp xde, 0x3
	jrl z, FmmSaveTtl_HandleCancel
	cp xde, 0x2
	jrl nz, FmmSaveTtl_Return
	ld (MEDLEY_PLAY_FLAG:16), 0
	ld wa, 1:i3
	calr InitializeOperationState
	ld xwa, 0x600026
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	call ApPostEvent
	cpw (0x8502:16), 0
	jr ge, FmmSaveTtl_CheckFont
	call GetEncodedFileSizeData
	ld (0x8502:16), hl
	call FileIO_SearchAndLoadFile
	call GetEncodedFreeSpaceData
	calr SignalProgressUpdate

FmmSaveTtl_CheckFont:
	cp (PREVIOUS_TITLE:16), 102
	jr z, FmmSaveTtl_CommitSave
	ld iz, 0:i3

FmmSaveTtl_SlotLoop:
	ldto_berp A, 0xf8
	extz wa
	call FileIO_BuildRecordPath_Done
	inc 1, iz
	cp iz, 6:i3
	jr lt, FmmSaveTtl_SlotLoop
	ld wa, 6:i3
	call FileIO_BuildRecordPath_Return
	ld wa, 7:i3
	call FileIO_BuildRecordPath_Return
	call FileIO_SetModeFlag_Reading
	ld xiy, ResetProgressIndication_Data
	ld xix, 0x8a0c
	ldiw

FmmSaveTtl_CommitSave:
	ld xwa, 0x600026
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_ALL_PAINT
	ld xde, 0:i3
	jr FmmSaveTtl_DispatchAndReturn

FmmSaveTtl_HandleCancel:
	calr CancelOperationCleanup
	ld xwa, 0x670001
	ld xbc, EVT_SET_PAGE
	ld xde, 1:i3

FmmSaveTtl_DispatchAndReturn:
	call ApPostEvent
	jr FmmSaveTtl_Return

FmmSaveTtl_HandleOk:
	cp xde, 0xf
	jr nz, FmmSaveTtl_Return
	ldw wa, 0x60
	call UI_PostModeChangeEvent

FmmSaveTtl_Return:
	ld xhl, 0:i3
	popw iz
	ret

DiskNameFunc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	cp xbc, EVT_SET_STRING
	jrl z, DiskName_HandleApply
	cp xbc, EVT_GET_STRING
	jr z, DiskName_TextChange
	cp xbc, EVT_PAINT
	jrl nz, DiskName_Return
	ld wa, 0:i3
	calr InitializeOperationState
	lda xiz, (0x878c:16)
	call FileIO_SearchAndLoadFile
	ld xbc, xhl
	ld xwa, xiz
	call FileIO_CopyString
	ld xwa, (xsp + 4)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x878c
	jr DiskName_Dispatch

DiskName_TextChange:
	ld wa, 0:i3
	calr InitializeOperationState
	lda xiz, (0x878c:16)
	call FileIO_SearchAndLoadFile
	ld xbc, xhl
	ld xwa, xiz
	call FileIO_CopyString
	ld iy, 0:i3
	lda xix, (0x8870:16)
	lda xiz, (CType_ClassTable:24)
	lda xde, (0x878c:16)
	ld xhl, xde
	jr DiskName_PadLoop_Cond

DiskName_PadLoop_CheckChar:
	ld	a, (xix+iy)
	extz wa
	ld	a, (xiz+wa)
	and a, 0x7
	jr nz, DiskName_PadLoop_Advance
	ld (xbc), 0x5f

DiskName_PadLoop_Advance:
	inc 1, iy

DiskName_PadLoop_Cond:
	cp iy, 0xb
	jr ge, DiskName_PadLoop_Fill
	lda	xbc, (xhl+iy)
	cp (xbc), 0x0
	jr nz, DiskName_PadLoop_CheckChar

DiskName_PadLoop_Fill:
	cp iy, 0xb
	jr ge, DiskName_PadDone
	ld xwa, xde

DiskName_FillLoop:
	ld	(xwa+iy), 0x5f
	inc 1, iy
	cp iy, 0xb
	jr lt, DiskName_FillLoop

DiskName_PadDone:
	ld (xde + 11), 0x0
	ld xwa, (xsp + 4)
	ld xbc, EVT_SET_STRING

DiskName_Dispatch:
	call ApPostEvent
	jr DiskName_Return

DiskName_HandleApply:
	ld xwa, 0x878c
	ld xbc, (xsp + 4)
	call FileIO_CopyString
	ld wa, 0:i3
	calr InitializeOperationState
	ld xwa, 0x878c
	call FileIO_CheckPathAndVolumeLabel
	calr SignalProgressUpdate
	calr ResetProgressIndication
	ldw wa, 0x60
	call UI_PostModeChangeEvent

DiskName_Return:
	ld xhl, 0:i3
	pop xiz
	inc 4, xsp
	ret

DiskInfoFunc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 16), xde
	cp xbc, EVT_PAINT
	jrl nz, DiskInfo_Return
	ld wa, 0:i3
	calr InitializeOperationState
	cpw (0x8500:16), 0
	jr ge, DiskInfo_ReadDriveType
	call GetDiskSizeInfo
	extz hl
	ld (0x8500:16), hl

DiskInfo_ReadDriveType:
	ld wa, (0x8500:16)
	cp wa, 1:i3
	jr z, DiskInfo_ResetCapacity
	cp wa, 0:i3
	jr z, DiskInfo_ResetCapacity
	cp wa, 2:i3
	jr z, DiskInfo_ReadCapacity
	cp wa, 3:i3
	jr nz, DiskInfo_ZeroCapacity

DiskInfo_ReadCapacity:
	call GetEncodedFreeSpaceData
	ld (xsp + 4), xhl
	call FileIO_GetDiskRecordPtr
	ld (xsp + 12), xhl
	jr DiskInfo_ComputePercent

DiskInfo_ResetCapacity:
	calr ResetProgressIndication

DiskInfo_ZeroCapacity:
	ld xwa, 0:i3
	ld (xsp + 12), xwa
	ld (xsp + 4), xwa

DiskInfo_ComputePercent:
	ld xwa, (xsp + 12)
	cp xwa, 0x0
	jr le, DiskInfo_ZeroPercent
	ld xwa, (xsp + 12)
	sub xwa, (xsp + 4)
	ld xbc, 0x64
	call Math_MultiplyAccumulate
	ld xiz, xhl
	ld xbc, (xsp + 12)
	ld xwa, xiz
	call Math_DivideSigned32
	ld (xsp + 8), xhl
	jr DiskInfo_RenderStrings

DiskInfo_ZeroPercent:
	ld xwa, 0:i3
	ld (xsp + 8), xwa

DiskInfo_RenderStrings:
	ld xwa, (xsp + 4)
	ld xbc, xwa
	sra xbc, 15
	sra xbc, 16
	and xbc, 0x3ff
	add xbc, xwa
	ld (xsp + 4), xbc
	sra xbc, 10
	ld (xsp + 4), xbc
	ld wa, (0x8500:16)
	sla wa, 2
	lda xbc, (DiskType_CodeTable:24)
	ld	xbc, (xbc+wa)
	ld xwa, 0x87ce
	call FileIO_CopyString
	ld xwa, 0x87ce
	ld xbc, DiskInfo_RenderStrings_Str_Colon
	call FileIO_BuildFilePath
	lda xwa, (0x87ce:16)
	ld (xsp + 12), xwa
	ld xwa, (xsp + 4)
	ld bc, 4:i3
	calr NumToAscii_FormatNumber
	ld xbc, xhl
	ld xwa, (xsp + 12)
	call FileIO_BuildFilePath
	ld xwa, 0x87ce
	ld xbc, DiskInfo_RenderStrings_Str_KB_free
	call FileIO_BuildFilePath
	lda xwa, (0x87ce:16)
	ld (xsp + 12), xwa
	ld xwa, (xsp + 8)
	ld bc, 3:i3
	calr NumToAscii_FormatNumber
	ld xbc, xhl
	ld xwa, (xsp + 12)
	call FileIO_BuildFilePath
	ld xwa, 0x87ce
	ld xbc, DiskInfo_RenderStrings_Str_Fmtu_sed
	call FileIO_BuildFilePath
	ld xwa, (xsp + 16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x87ce
	call ApPostEvent

DiskInfo_Return:
	ld xhl, 0:i3
	pop xiz
	lda xsp, (xsp + 16)
	ret

SongNameFunc:
	dec 8, xsp
	pushw iz
	ld (xsp + 6), xde
	cp xbc, EVT_PAINT
	jr nz, SongName_Return
	call GetFirstPageBase
	ld iz, hl
	cp iz, 0:i3
	jr lt, SongName_NoSlot
	ld wa, 0:i3
	calr InitializeOperationState
	lda xwa, (0x880e:16)
	ld (xsp + 2), xwa
	ld wa, iz
	call GetFileEntryByIndex
	ld xbc, xhl
	ld xwa, (xsp + 2)
	call FileIO_CopyString
	lda xwa, (0x880e:16)
	ld (xwa + 30), 0x0
	lda xbc, (xwa + 29)
	ld xde, xbc
	lda xhl, (xbc - 29)
	jr SongName_TrimLoop_Cond

SongName_TrimLoop_ZeroChar:
	ld (xde), 0x0
	dec 1, xde

SongName_TrimLoop_Cond:
	ld c, (xde)
	cp c, 0x20
	jr nz, SongName_TrimDone
	cp xde, xhl
	jr ugt, SongName_TrimLoop_ZeroChar

SongName_TrimDone:
	call FileIO_GetRecordType_Extended
	jr SongName_SendDisplay

SongName_NoSlot:
	ld (0x880e:16), 0

SongName_SendDisplay:
	ld xwa, (xsp + 6)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x880e
	call ApPostEvent

SongName_Return:
	ld xhl, 0:i3
	popw iz
	inc 8, xsp
	ret

SaveFileNameNumFunc:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xde
	cp xbc, EVT_PAINT
	jr nz, SaveFileNum_Return
	call GetCurrentFileIndex
	ld iz, hl
	cp iz, 0:i3
	jr lt, SaveFileNum_NoSlot
	call FileIO_GetRecordByType
	ld xbc, xhl
	ld de, iz
	inc 1, de
	pushw 0x6
	pushw 0x0
	ld xwa, 0x8850
	call FileIO_ReadHeader_ParseLoop
	jr SaveFileNum_SendDisplay

SaveFileNum_NoSlot:
	ld (0x8850:16), 0

SaveFileNum_SendDisplay:
	ld xwa, (xsp + 2)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x8850
	call ApPostEvent

SaveFileNum_Return:
	ld xhl, 0:i3
	popw iz
	inc 4, xsp
	ret

SaveFileNameFunc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	cp xbc, EVT_SET_STRING
	jrl z, SaveFileName_HandleApply
	cp xbc, EVT_GET_STRING
	jr z, SaveFileName_TextChange
	cp xbc, EVT_PAINT
	jrl nz, SaveFileName_Return
	lda xiz, (0x8850:16)
	call FileIO_GetRecordByType
	ld xbc, xhl
	ld xwa, xiz
	call FileIO_CopyString
	ld xwa, 0x8850
	call FileIO_GetRecordType_Extended
	ld xwa, (xsp + 4)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x8850
	jr SaveFileName_Dispatch

SaveFileName_TextChange:
	lda xiz, (0x8850:16)
	call FileIO_GetRecordByType
	ld xbc, xhl
	ld xwa, xiz
	call FileIO_CopyString
	ld iy, 0:i3
	lda xix, (CType_ClassTable:24)
	lda xde, (0x8850:16)
	ld xhl, xde
	jr SaveFileName_PadLoop_Cond

SaveFileName_PadLoop_CheckChar:
	extz wa
	ld	a, (xix+wa)
	and a, 0x7
	jr nz, SaveFileName_PadLoop_Advance
	ld (xbc), 0x5f

SaveFileName_PadLoop_Advance:
	inc 1, iy

SaveFileName_PadLoop_Cond:
	cp iy, 6:i3
	jr ge, SaveFileName_PadLoop_Fill
	lda	xbc, (xhl+iy)
	ld a, (xbc)
	cp a, 0:i3
	jr nz, SaveFileName_PadLoop_CheckChar

SaveFileName_PadLoop_Fill:
	cp iy, 6:i3
	jr ge, SaveFileName_PadDone
	ld xwa, xde

SaveFileName_FillLoop:
	ld	(xwa+iy), 0x5f
	inc 1, iy
	cp iy, 6:i3
	jr lt, SaveFileName_FillLoop

SaveFileName_PadDone:
	ld (xde + 6), 0x0
	ld xwa, (xsp + 4)
	ld xbc, EVT_SET_STRING

SaveFileName_Dispatch:
	call ApPostEvent
	jr SaveFileName_Return

SaveFileName_HandleApply:
	ld xwa, 0x8850
	ld xbc, (xsp + 4)
	call FileIO_CopyString
	ld xwa, 0x8850
	call FileIO_GetRecordByType_Lookup

SaveFileName_Return:
	ld xhl, 0:i3
	pop xiz
	inc 4, xsp
	ret

CurFileNameFunc:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xde
	cp xbc, EVT_PAINT
	jr nz, CurFileName_Return
	call GetCurrentFileIndex
	ld iz, hl
	cp iz, 0:i3
	jr lt, CurFileName_NoSlot
	ld wa, iz
	call GetFileEntryPtr
	ld xbc, xhl
	ld de, iz
	inc 1, de
	pushw 0x6
	pushw 0x0
	ld xwa, 0x8870
	call FileIO_ReadHeader_ParseLoop
	jr CurFileName_SendDisplay

CurFileName_NoSlot:
	ld (0x8870:16), 0

CurFileName_SendDisplay:
	ld xwa, (xsp + 2)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x8870
	call ApPostEvent

CurFileName_Return:
	ld xhl, 0:i3
	popw iz
	inc 4, xsp
	ret

