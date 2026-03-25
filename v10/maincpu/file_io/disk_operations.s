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
	cp xbc, 0x1c00018
	jrl z, FCopy_HandleScroll
	cp xbc, 0x1c00017
	jrl z, FCopy_HandleScroll
	cp xbc, 0x1c0000b
	jr z, FCopy_HandleExecute
	cp xbc, 0x1e50004
	jrl nz, FCopy_Return
	stda32 0x7f60, xiz
	call GetCurrentFileIndex
	stda16 0x7f64, xhl
	cps hl, 0
	jr lt, FCopy_ScrollNeg_Reset
	cp hl, 0x13
	jr ge, FCopy_ScrollDown_Clamp
	inc 1, hl
	stda16 0x7f66, xhl
	jrl FCopy_Return

FCopy_ScrollDown_Clamp:
	dec 1, hl
	stda16 0x7f66, xhl
	jrl FCopy_Return

FCopy_ScrollNeg_Reset:
	stdi16 0x7f64, 0
	stdi16 0x7f66, 1
	jrl FCopy_Return

FCopy_HandleExecute:
	stdi8 0x850c, 0
	ldw_d16 xwa, 0x7f66
	call GetFileEntryPtr
	ld xbc, xhl
	lda_d16 xwa, 0x850d
	ldw_d16 xde, 0x7f66
	inc 1, de
	pushw 0x6
	pushw 0x0
	call FileIO_ReadHeader_ParseLoop
	ldda32 xwa, 0x7f60
	ld xbc, 0x1c0000f
	ld xde, 0x850c
	call ApPostEvent
	jrl FCopy_Return

FCopy_HandleScroll:
	or xiz, xiz
	jrl nz, FCopy_HandleCopyContext
	ldw_d16 xwa, 0x7f66
	ld de, wa
	cp xbc, 0x1c00018
	jr nz, FCopy_ScrollUp_Adjust
	cps wa, 0
	jr le, FCopy_ScrollDown_CheckMin
	dec 1, wa
	stda16 0x7f66, xwa

FCopy_ScrollDown_CheckMin:
	ldw_d16 xwa, 0x7f66
	cpda16 xwa, 0x7f64
	jr nz, FCopy_ScrollDown_Reload
	cps wa, 0
	jr le, FCopy_ScrollDown_RestoreOld
	dec 1, wa
	stda16 0x7f66, xwa
	jr FCopy_Scroll_Apply

FCopy_ScrollDown_RestoreOld:
	stda16 0x7f66, xde

FCopy_ScrollDown_Reload:
	ldw_d16 xwa, 0x7f66

FCopy_Scroll_Apply:
	cp wa, de
	jrl z, FCopy_Return
	stdi8 0x850c, 0
	ldw_d16 xwa, 0x7f66
	call GetFileEntryPtr
	ld xbc, xhl
	lda_d16 xwa, 0x850d
	ldw_d16 xde, 0x7f66
	inc 1, de
	pushw 0x6
	pushw 0x0
	call FileIO_ReadHeader_ParseLoop
	ldda32 xwa, 0x7f60
	ld xbc, 0x1c0000f
	ld xde, 0x850c
	jr FCopy_DispatchFA9D58

FCopy_ScrollUp_Adjust:
	cp xbc, 0x1c00017
	jr nz, FCopy_ScrollDown_Reload
	cp wa, 0x13
	jr ge, FCopy_ScrollUp_CheckMax
	inc 1, wa
	stda16 0x7f66, xwa

FCopy_ScrollUp_CheckMax:
	ldw_d16 xwa, 0x7f66
	cpda16 xwa, 0x7f64
	jr nz, FCopy_ScrollDown_Reload
	cp wa, 0x13
	jr ge, FCopy_ScrollDown_RestoreOld
	inc 1, wa
	stda16 0x7f66, xwa
	jr FCopy_Scroll_Apply

FCopy_HandleCopyContext:
	cp xiz, 0x8
	jrl nz, FCopy_CopyExecute
	call CheckFileSystemStatus
	cps hl, 0
	jrl z, FCopy_CopyExecute
	ldw_d16 xwa, 0x7f66
	call FileIO_GetRecordFlags
	cps hl, 0
	jr z, FCopy_CopyConfirm_Execute
	cpib_da 0x0340ea, 0x00
	jr z, FCopy_CopyConfirm_Execute
	ld xwa, 0xffffffff
	ld xbc, 0x1c50000
	lds32 xde, 1
	call ApPostEvent
	ld xwa, 0x600037
	ld xbc, 0x1c00001
	lds32 xde, 0

FCopy_DispatchFA9D58:
	call ApPostEvent
	jrl FCopy_Return

FCopy_CopyConfirm_Execute:
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	lds wa, 0
	calr InitializeOperationState
	ldw_d16 xwa, 0x7f66
	call WriteFileWithVerify
	ld wa, hl
	lds bc, 5
	calr FileIO_ValidateSignedValue
	stb_d8 0x7f42, l
	calr SignalProgressUpdate
	call FileIO_ResetCurrentRecord
	call GetEncodedFreeSpaceData
	call GetEncodedFileSizeData
	stda16 0x8502, xhl
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 1
	call ApPostEvent
	ldw wa, 0x7b
	call UI_PostModeChangeEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0xee
	jr FCopy_NotifyComplete

FCopy_CopyExecute:
	cp xiz, 0x32
	jr nz, FCopy_Return
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	lds wa, 0
	calr InitializeOperationState
	ldw_d16 xwa, 0x7f66
	call WriteFileWithVerify
	ld wa, hl
	lds bc, 5
	calr FileIO_ValidateSignedValue
	stb_d8 0x7f42, l
	calr SignalProgressUpdate
	call FileIO_ResetCurrentRecord
	call GetEncodedFreeSpaceData
	call GetEncodedFileSizeData
	stda16 0x8502, xhl
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 1
	call ApPostEvent
	ldw wa, 0x7b
	call UI_PostModeChangeEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0xee

FCopy_NotifyComplete:
	call SoundCtrl_SendCommand

FCopy_Return:
	lds32 xhl, 0
	pop xiz
	ret

FileRenameFunc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	cp xbc, 0x1e00086
	jrl z, FRename_HandleApply
	cp xbc, 0x1e0003a
	jrl nz, FRename_Return
	call GetCurrentFileIndex
	cps hl, 0
	jr lt, FRename_TextChange_Error
	lda_d16 xiz, 0x8870
	ld wa, hl
	call GetFileEntryPtr
	ld xbc, xhl
	ld xwa, xiz
	call FileIO_CopyString
	lds iy, 0
	lda_24 xix, CharMap_FullPermutation_0x660
	lda_d16 xwa, 0x8870
	ld xhl, xwa
	jr FRename_PadLoop_Cond

FRename_PadLoop_CheckChar:
	extz bc
	ldb_sri C, 0x07, 0xf0, 0xe4
	and c, 0x7
	jr nz, FRename_PadLoop_Advance
	ld (xde), 0x5f

FRename_PadLoop_Advance:
	inc 1, iy

FRename_PadLoop_Cond:
	cps iy, 6
	jr ge, FRename_PadLoop_Fill
	stb_dri B, 0x07, 0xec, 0xf4
	ld c, (xde)
	cps c, 0
	jr nz, FRename_PadLoop_CheckChar

FRename_PadLoop_Fill:
	cps iy, 6
	jr ge, FRename_PadDone
	ld xbc, xwa

FRename_FillLoop:
	stib_ind 0x07, 0xe4, 0xf4, 0x5f
	inc 1, iy
	cps iy, 6
	jr lt, FRename_FillLoop

FRename_PadDone:
	ld (xwa + 6), 0x0
	jr FRename_TextChange_SendApply

FRename_TextChange_Error:
	ld xwa, 0x8870
	ld xbc, DiskOp_ChannelCfgTable_0x52
	call FileIO_CopyString

FRename_TextChange_SendApply:
	ld xwa, (xsp + 4)
	ld xbc, 0x1e00086
	ld xde, 0x8870
	call ApPostEvent
	jr FRename_Return

FRename_HandleApply:
	call CheckFileSystemStatus
	cps hl, 0
	jr z, FRename_Return
	ld xwa, 0x8870
	ld xbc, (xsp + 4)
	call FileIO_CopyString
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	lds wa, 0
	calr InitializeOperationState
	ld xwa, 0x8870
	call ReadDualFile
	ld wa, hl
	lds bc, 5
	calr FileIO_ValidateSignedValue
	stb_d8 0x7f42, l
	calr SignalProgressUpdate
	call GetEncodedFileSizeData
	stda16 0x8502, xhl
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0xee
	call SoundCtrl_SendCommand

FRename_Return:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret

FileRenameSmfFunc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	cp xbc, 0x1e00086
	jrl z, FRenameSmf_HandleApply
	cp xbc, 0x1e0003a
	jrl nz, FRenameSmf_Return
	call GetFirstPageBase
	cps hl, 0
	jr lt, FRenameSmf_TextChange_Error
	lda_d16 xiz, 0x8870
	ld wa, hl
	call GetRecordPtrForFile
	ld xbc, xhl
	ld xwa, xiz
	call FileIO_CopyString
	lds iy, 0
	lda_24 xix, CharMap_FullPermutation_0x660
	lda_d16 xwa, 0x8870
	ld xhl, xwa
	jr FRenameSmf_PadLoop_Cond

FRenameSmf_PadLoop_CheckChar:
	extz bc
	ldb_sri C, 0x07, 0xf0, 0xe4
	and c, 0x7
	jr nz, FRenameSmf_PadLoop_Advance
	ld (xde), 0x5f

FRenameSmf_PadLoop_Advance:
	inc 1, iy

FRenameSmf_PadLoop_Cond:
	cp iy, 0x8
	jr ge, FRenameSmf_PadLoop_Fill
	stb_dri B, 0x07, 0xec, 0xf4
	ld c, (xde)
	cps c, 0
	jr nz, FRenameSmf_PadLoop_CheckChar

FRenameSmf_PadLoop_Fill:
	cp iy, 0x8
	jr ge, FRenameSmf_PadDone
	ld xbc, xwa

FRenameSmf_FillLoop:
	stib_ind 0x07, 0xe4, 0xf4, 0x5f
	inc 1, iy
	cp iy, 0x8
	jr lt, FRenameSmf_FillLoop

FRenameSmf_PadDone:
	ld (xwa + 8), 0x0
	jr FRenameSmf_TextChange_SendApply

FRenameSmf_TextChange_Error:
	ld xwa, 0x8870
	ld xbc, DiskOp_ChannelCfgTable_0x5A
	call FileIO_CopyString

FRenameSmf_TextChange_SendApply:
	ld xwa, (xsp + 4)
	ld xbc, 0x1e00086
	ld xde, 0x8870
	call ApPostEvent
	jr FRenameSmf_Return

FRenameSmf_HandleApply:
	ld xwa, 0x8870
	ld xbc, (xsp + 4)
	call FileIO_CopyString
	ld xwa, 0x8870
	ld xbc, DiskOp_ChannelCfgTable_0x64
	call FileIO_BuildFilePath
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	lds wa, 0
	calr InitializeOperationState
	ld xwa, 0x8870
	call SearchAndOpen
	ld wa, hl
	lds bc, 5
	calr FileIO_ValidateSignedValue
	stb_d8 0x7f42, l
	calr SignalProgressUpdate
	call GetFileCountEncoded
	stda16 0x8504, xhl
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0xee
	call SoundCtrl_SendCommand

FRenameSmf_Return:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret

FmmFormatFunc:
	pushw iz
	cp xbc, 0x1c00007
	jrl z, FmmFmt_HandleProgress
	cp xbc, 0x1c00013
	jrl nz, FmmFmt_Return
	cp xde, 0x3
	jr z, FmmFmt_HandleCancel
	cp xde, 0x2
	jrl nz, FmmFmt_Return
	lds wa, 1
	calr InitializeOperationState
	ldmm8 0x7f6a, 0x8d37
	cpdi16 0x8500, 0
	jr ge, FmmFmt_InitPhase_CheckDrive
	call GetDiskSizeInfo
	extz hl
	stda16 0x8500, xhl
	calr SignalProgressUpdate

FmmFmt_InitPhase_CheckDrive:
	ldw_d16 xwa, 0x8500
	cps wa, 2
	jr z, FmmFmt_InitPhase_DriveType23
	cps wa, 3
	jr nz, FmmFmt_InitPhase_OtherDrive

FmmFmt_InitPhase_DriveType23:
	stb_d8 0x7f68, a
	ld xwa, 0x7b0036
	ld xbc, 0x1c00001
	lds32 xde, 0
	call ApPostEvent
	stdi8 0x84fe, 0
	jr FmmFmt_InitPhase_SetActive

FmmFmt_InitPhase_OtherDrive:
	ld xwa, 0x7b003f
	ld xbc, 0x1c00001
	lds32 xde, 0
	call ApPostEvent
	stdi8 0x84fe, 2

FmmFmt_InitPhase_SetActive:
	stdi8 0x7f6c, 1
	jrl FmmFmt_Return

FmmFmt_HandleCancel:
	calr CancelOperationCleanup
	stdi8 0x84fe, 0
	stdi8 0x7f6c, 0
	jrl FmmFmt_Return

FmmFmt_HandleProgress:
	cpdi8 0x7f6c, 0
	jrl z, FmmFmt_Return
	ldb_d8 a, 0x7f6a
	extz wa
	cp xde, 0xf
	jrl z, FmmFmt_HandleAbortFinal
	ldb_d8 c, 0x84fe
	cp xde, 0xb
	jrl z, FmmFmt_HandleAbort
	cp xde, 0xa
	jrl nz, FmmFmt_Return
	ld a, c
	cps c, 0
	jrl nz, FmmFmt_ExecutePhase2
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	lds wa, 0
	calr InitializeOperationState
	ldb_d8 a, 0x7f68
	extz wa
	call FileIO_ValidateRecord_CheckSize
	ld iz, hl
	calr SignalProgressUpdate
	calr ResetProgressIndication
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	cps iz, 0
	jr ge, FmmFmt_FormatSuccess
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 1
	call ApPostEvent
	ldb_d8 a, 0x7f6a
	extz wa
	call UI_PostModeChangeEvent
	stdi8 0x7f6c, 0
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call ApPostEvent
	ld wa, iz
	ldw bc, 0x8
	calr FileIO_ValidateSignedValue
	stb_d8 0x7f42, l
	ldw wa, 0xee
	call SoundCtrl_SendCommand
	jrl FmmFmt_NotifyComplete

FmmFmt_FormatSuccess:
	ld xwa, 0x7b0036
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0x7b0031
	ld xbc, 0x1c00001
	lds32 xde, 0
	call ApPostEvent
	stdi8 0x84fe, 1
	jr FmmFmt_Return

FmmFmt_ExecutePhase2:
	cps a, 2
	jr nz, FmmFmt_Return
	stdi8 0x7f68, 3
	ld xwa, 0x7b003f
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0x7b0036
	ld xbc, 0x1c00001
	lds32 xde, 0
	jr FmmFmt_DispatchAndNotify

FmmFmt_HandleAbort:
	ld e, c
	cps c, 0
	jr nz, FmmFmt_AbortPhase2
	call UI_PostModeChangeEvent
	stdi8 0x7f6c, 0
	jr FmmFmt_Return

FmmFmt_AbortPhase2:
	cps e, 2
	jr nz, FmmFmt_Return
	stdi8 0x7f68, 2
	ld xwa, 0x7b003f
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0x7b0036
	ld xbc, 0x1c00001
	lds32 xde, 0

FmmFmt_DispatchAndNotify:
	call ApPostEvent
	jr FmmFmt_NotifyComplete

FmmFmt_HandleAbortFinal:
	call UI_PostModeChangeEvent
	stdi8 0x7f6c, 0

FmmFmt_NotifyComplete:
	stdi8 0x84fe, 0

FmmFmt_Return:
	lds32 xhl, 0
	popw iz
	ret

UtilityTtlJgFunc:
	cp xbc, 0x1c00007
	jr nz, UtilTtlJg_Return
	ldw wa, 0x7b
	ldw bc, 0x7c
	calr FileIO_DiskEventDispatch

UtilTtlJg_Return:
	lds32 xhl, 0
	ret

FmmLoadTitleFunc:
	pushw iz
	cp xbc, 0x1c00007
	jrl z, FmmLoadTtl_HandleOk
	cp xbc, 0x1c00013
	jrl nz, FmmLoadTtl_Return
	cp xde, 0x3
	jrl z, FmmLoadTtl_HandleCancelOp
	cp xde, 0x9
	jrl z, FmmLoadTtl_HandleScrollNav
	cp xde, 0x2
	jrl nz, FmmLoadTtl_Return
	stdi8 0x84fe, 0
	ldmm16 0x7f70, 0x8500
	lds wa, 1
	calr InitializeOperationState
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	ldmm8 0x7f6e, 0x8d37
	cpdi16 0x8500, 0
	jr ge, FmmLoadTtl_StateDispatch
	call GetDiskSizeInfo
	extz hl
	stda16 0x8500, xhl
	calr SignalProgressUpdate

FmmLoadTtl_StateDispatch:
	ldw_d16 xwa, 0x8500
	cps wa, 1
	jrl z, FmmLoadTtl_StateSuccess
	cps wa, 0
	jrl z, FmmLoadTtl_StateIdle
	cps wa, 5
	jr z, FmmLoadTtl_StateCancelLoad
	cpdi16 0x8502, 0
	jr ge, FmmLoadTtl_CheckFileHandle
	call GetEncodedFileSizeData
	stda16 0x8502, xhl
	call FileIO_SearchAndLoadFile
	call GetEncodedFreeSpaceData
	calr SignalProgressUpdate

FmmLoadTtl_CheckFileHandle:
	cpdi16 0x8502, 0
	jrl nz, FmmLoadTtl_LoadSlots
	cpdi16 0x8504, 0
	jr ge, FmmLoadTtl_CheckSmfHandle
	call GetFileCountEncoded
	stda16 0x8504, xhl
	calr SignalProgressUpdate

FmmLoadTtl_CheckSmfHandle:
	cpdi16 0x8504, 0
	jrl le, FmmLoadTtl_LoadSlots
	cpdi8 0x7f6e, 100
	jrl z, FmmLoadTtl_LoadSlots
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0x64
	jrl FmmLoadTtl_PlaySound

FmmLoadTtl_StateCancelLoad:
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 1
	call ApPostEvent
	ldb_d8 a, 0x7f6e
	extz wa
	call UI_PostModeChangeEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call ApPostEvent
	stdi8 0x7f42, 0
	ldw wa, 0xee
	jr FmmLoadTtl_NotifyComplete

FmmLoadTtl_StateIdle:
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0x7d
	jrl FmmLoadTtl_PlaySound

FmmLoadTtl_StateSuccess:
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	calr ResetProgressIndication
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 1
	call ApPostEvent
	ldb_d8 a, 0x7f6e
	extz wa
	call UI_PostModeChangeEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call ApPostEvent
	stdi8 0x7f42, 2
	ldw wa, 0xee

FmmLoadTtl_NotifyComplete:
	call SoundCtrl_SendCommand
	jrl FmmLoadTtl_Return

FmmLoadTtl_LoadSlots:
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	call ApPostEvent
	stdi8 0x89fc, 0
	stdi8 0x89fe, 0
	stdi8 0x8a00, 0
	stdi8 0x8a02, 0
	stdi8 0x8a04, 0
	stdi8 0x8a06, 0
	stdi8 0x8a08, 0
	lds iz, 0

FmmLoadTtl_SlotLoop:
	stb_erp A, 0xf8
	extz wa
	call FileIO_FormatName_Loop
	inc 1, iz
	cp iz, 0x8
	jr lt, FmmLoadTtl_SlotLoop
	stdi8 0x89f8, 4
	jr FmmLoadTtl_Return

FmmLoadTtl_HandleScrollNav:
	cpdi16 0x7f70, 0
	jr lt, FmmLoadTtl_Return
	call GetCurrentFileIndex
	ld iz, hl
	cps iz, 0
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
	ld xbc, 0x1e0007f
	lds32 xde, 1
	call ApPostEvent
	jr FmmLoadTtl_Return

FmmLoadTtl_HandleOk:
	cp xde, 0xf
	jr nz, FmmLoadTtl_Return
	cpdi8 0x8d34, 7
	jr nz, FmmLoadTtl_Ok_DefaultSound
	ldw wa, 0xd6
	jr FmmLoadTtl_PlaySound

FmmLoadTtl_Ok_DefaultSound:
	ldw wa, 0x60

FmmLoadTtl_PlaySound:
	call UI_PostModeChangeEvent

FmmLoadTtl_Return:
	lds32 xhl, 0
	popw iz
	ret

FmmSaveTitleFunc:
	pushw iz
	cp xbc, 0x1c00007
	jrl z, FmmSaveTtl_HandleOk
	cp xbc, 0x1c00013
	jrl nz, FmmSaveTtl_Return
	cp xde, 0x3
	jrl z, FmmSaveTtl_HandleCancel
	cp xde, 0x2
	jrl nz, FmmSaveTtl_Return
	stdi8 0x84fe, 0
	lds wa, 1
	calr InitializeOperationState
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	cpdi16 0x8502, 0
	jr ge, FmmSaveTtl_CheckFont
	call GetEncodedFileSizeData
	stda16 0x8502, xhl
	call FileIO_SearchAndLoadFile
	call GetEncodedFreeSpaceData
	calr SignalProgressUpdate

FmmSaveTtl_CheckFont:
	cpdi8 0x8d37, 102
	jr z, FmmSaveTtl_CommitSave
	lds iz, 0

FmmSaveTtl_SlotLoop:
	stb_erp A, 0xf8
	extz wa
	call FileIO_BuildRecordPath_Done
	inc 1, iz
	cps iz, 6
	jr lt, FmmSaveTtl_SlotLoop
	lds wa, 6
	call FileIO_BuildRecordPath_Return
	lds wa, 7
	call FileIO_BuildRecordPath_Return
	call FileIO_SetModeFlag_Reading
	ld xiy, BankStr_Memory_0xA
	ld xix, 0x8a0c
	ldiw

FmmSaveTtl_CommitSave:
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	jr FmmSaveTtl_DispatchAndReturn

FmmSaveTtl_HandleCancel:
	calr CancelOperationCleanup
	ld xwa, 0x670001
	ld xbc, 0x1e0007f
	lds32 xde, 1

FmmSaveTtl_DispatchAndReturn:
	call ApPostEvent
	jr FmmSaveTtl_Return

FmmSaveTtl_HandleOk:
	cp xde, 0xf
	jr nz, FmmSaveTtl_Return
	ldw wa, 0x60
	call UI_PostModeChangeEvent

FmmSaveTtl_Return:
	lds32 xhl, 0
	popw iz
	ret

DiskNameFunc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	cp xbc, 0x1e00086
	jrl z, DiskName_HandleApply
	cp xbc, 0x1e0003a
	jr z, DiskName_TextChange
	cp xbc, 0x1c0000b
	jrl nz, DiskName_Return
	lds wa, 0
	calr InitializeOperationState
	lda_d16 xiz, 0x878c
	call FileIO_SearchAndLoadFile
	ld xbc, xhl
	ld xwa, xiz
	call FileIO_CopyString
	ld xwa, (xsp + 4)
	ld xbc, 0x1c0000f
	ld xde, 0x878c
	jr DiskName_Dispatch

DiskName_TextChange:
	lds wa, 0
	calr InitializeOperationState
	lda_d16 xiz, 0x878c
	call FileIO_SearchAndLoadFile
	ld xbc, xhl
	ld xwa, xiz
	call FileIO_CopyString
	lds iy, 0
	lda_d16 xix, 0x8870
	lda_24 xiz, CharMap_FullPermutation_0x660
	lda_d16 xde, 0x878c
	ld xhl, xde
	jr DiskName_PadLoop_Cond

DiskName_PadLoop_CheckChar:
	ldb_sri A, 0x07, 0xf0, 0xf4
	extz wa
	ldb_sri A, 0x07, 0xf8, 0xe0
	and a, 0x7
	jr nz, DiskName_PadLoop_Advance
	ld (xbc), 0x5f

DiskName_PadLoop_Advance:
	inc 1, iy

DiskName_PadLoop_Cond:
	cp iy, 0xb
	jr ge, DiskName_PadLoop_Fill
	stb_dri A, 0x07, 0xec, 0xf4
	cp (xbc), 0x0
	jr nz, DiskName_PadLoop_CheckChar

DiskName_PadLoop_Fill:
	cp iy, 0xb
	jr ge, DiskName_PadDone
	ld xwa, xde

DiskName_FillLoop:
	stib_ind 0x07, 0xe0, 0xf4, 0x5f
	inc 1, iy
	cp iy, 0xb
	jr lt, DiskName_FillLoop

DiskName_PadDone:
	ld (xde + 11), 0x0
	ld xwa, (xsp + 4)
	ld xbc, 0x1e00086

DiskName_Dispatch:
	call ApPostEvent
	jr DiskName_Return

DiskName_HandleApply:
	ld xwa, 0x878c
	ld xbc, (xsp + 4)
	call FileIO_CopyString
	lds wa, 0
	calr InitializeOperationState
	ld xwa, 0x878c
	call FileIO_CheckPathAndVolumeLabel
	calr SignalProgressUpdate
	calr ResetProgressIndication
	ldw wa, 0x60
	call UI_PostModeChangeEvent

DiskName_Return:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret

DiskInfoFunc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 16), xde
	cp xbc, 0x1c0000b
	jrl nz, DiskInfo_Return
	lds wa, 0
	calr InitializeOperationState
	cpdi16 0x8500, 0
	jr ge, DiskInfo_ReadDriveType
	call GetDiskSizeInfo
	extz hl
	stda16 0x8500, xhl

DiskInfo_ReadDriveType:
	ldw_d16 xwa, 0x8500
	cps wa, 1
	jr z, DiskInfo_ResetCapacity
	cps wa, 0
	jr z, DiskInfo_ResetCapacity
	cps wa, 2
	jr z, DiskInfo_ReadCapacity
	cps wa, 3
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
	lds32 xwa, 0
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
	lds32 xwa, 0
	ld (xsp + 8), xwa

DiskInfo_RenderStrings:
	ld xwa, (xsp + 4)
	ld xbc, xwa
	sra xbc, 15
	sra xbc, 0
	and xbc, 0x3ff
	add xbc, xwa
	ld (xsp + 4), xbc
	sra xbc, 10
	ld (xsp + 4), xbc
	ldw_d16 xwa, 0x8500
	sla wa, 2
	lda_24 xbc, DiskType_CodeTable
	ld_sril3 XBC, 0x07, 0xe4, 0xe0
	ld xwa, 0x87ce
	call FileIO_CopyString
	ld xwa, 0x87ce
	ld xbc, DiskOp_ChannelCfgTable_0x6A
	call FileIO_BuildFilePath
	lda_d16 xwa, 0x87ce
	ld (xsp + 12), xwa
	ld xwa, (xsp + 4)
	lds bc, 4
	calr NumToAscii_FormatNumber
	ld xbc, xhl
	ld xwa, (xsp + 12)
	call FileIO_BuildFilePath
	ld xwa, 0x87ce
	ld xbc, DiskOp_ChannelCfgTable_0x6E
	call FileIO_BuildFilePath
	lda_d16 xwa, 0x87ce
	ld (xsp + 12), xwa
	ld xwa, (xsp + 8)
	lds bc, 3
	calr NumToAscii_FormatNumber
	ld xbc, xhl
	ld xwa, (xsp + 12)
	call FileIO_BuildFilePath
	ld xwa, 0x87ce
	ld xbc, DiskOp_ChannelCfgTable_0x78
	call FileIO_BuildFilePath
	ld xwa, (xsp + 16)
	ld xbc, 0x1c0000f
	ld xde, 0x87ce
	call ApPostEvent

DiskInfo_Return:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 16)
	ret

SongNameFunc:
	dec 8, xsp
	pushw iz
	ld (xsp + 6), xde
	cp xbc, 0x1c0000b
	jr nz, SongName_Return
	call GetFirstPageBase
	ld iz, hl
	cps iz, 0
	jr lt, SongName_NoSlot
	lds wa, 0
	calr InitializeOperationState
	lda_d16 xwa, 0x880e
	ld (xsp + 2), xwa
	ld wa, iz
	call GetFileEntryByIndex
	ld xbc, xhl
	ld xwa, (xsp + 2)
	call FileIO_CopyString
	lda_d16 xwa, 0x880e
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
	stdi8 0x880e, 0

SongName_SendDisplay:
	ld xwa, (xsp + 6)
	ld xbc, 0x1c0000f
	ld xde, 0x880e
	call ApPostEvent

SongName_Return:
	lds32 xhl, 0
	popw iz
	inc 8, xsp
	ret

SaveFileNameNumFunc:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xde
	cp xbc, 0x1c0000b
	jr nz, SaveFileNum_Return
	call GetCurrentFileIndex
	ld iz, hl
	cps iz, 0
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
	stdi8 0x8850, 0

SaveFileNum_SendDisplay:
	ld xwa, (xsp + 2)
	ld xbc, 0x1c0000f
	ld xde, 0x8850
	call ApPostEvent

SaveFileNum_Return:
	lds32 xhl, 0
	popw iz
	inc 4, xsp
	ret

SaveFileNameFunc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	cp xbc, 0x1e00086
	jrl z, SaveFileName_HandleApply
	cp xbc, 0x1e0003a
	jr z, SaveFileName_TextChange
	cp xbc, 0x1c0000b
	jrl nz, SaveFileName_Return
	lda_d16 xiz, 0x8850
	call FileIO_GetRecordByType
	ld xbc, xhl
	ld xwa, xiz
	call FileIO_CopyString
	ld xwa, 0x8850
	call FileIO_GetRecordType_Extended
	ld xwa, (xsp + 4)
	ld xbc, 0x1c0000f
	ld xde, 0x8850
	jr SaveFileName_Dispatch

SaveFileName_TextChange:
	lda_d16 xiz, 0x8850
	call FileIO_GetRecordByType
	ld xbc, xhl
	ld xwa, xiz
	call FileIO_CopyString
	lds iy, 0
	lda_24 xix, CharMap_FullPermutation_0x660
	lda_d16 xde, 0x8850
	ld xhl, xde
	jr SaveFileName_PadLoop_Cond

SaveFileName_PadLoop_CheckChar:
	extz wa
	ldb_sri A, 0x07, 0xf0, 0xe0
	and a, 0x7
	jr nz, SaveFileName_PadLoop_Advance
	ld (xbc), 0x5f

SaveFileName_PadLoop_Advance:
	inc 1, iy

SaveFileName_PadLoop_Cond:
	cps iy, 6
	jr ge, SaveFileName_PadLoop_Fill
	stb_dri A, 0x07, 0xec, 0xf4
	ld a, (xbc)
	cps a, 0
	jr nz, SaveFileName_PadLoop_CheckChar

SaveFileName_PadLoop_Fill:
	cps iy, 6
	jr ge, SaveFileName_PadDone
	ld xwa, xde

SaveFileName_FillLoop:
	stib_ind 0x07, 0xe0, 0xf4, 0x5f
	inc 1, iy
	cps iy, 6
	jr lt, SaveFileName_FillLoop

SaveFileName_PadDone:
	ld (xde + 6), 0x0
	ld xwa, (xsp + 4)
	ld xbc, 0x1e00086

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
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret

CurFileNameFunc:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xde
	cp xbc, 0x1c0000b
	jr nz, CurFileName_Return
	call GetCurrentFileIndex
	ld iz, hl
	cps iz, 0
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
	stdi8 0x8870, 0

CurFileName_SendDisplay:
	ld xwa, (xsp + 2)
	ld xbc, 0x1c0000f
	ld xde, 0x8870
	call ApPostEvent

CurFileName_Return:
	lds32 xhl, 0
	popw iz
	inc 4, xsp
	ret

