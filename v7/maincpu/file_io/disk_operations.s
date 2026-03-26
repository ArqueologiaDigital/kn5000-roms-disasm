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
	.incbin "includes/generated/v7_transplant_FileCopyFunc.bin"
FCopy_ScrollDown_Clamp:
	.incbin "includes/generated/v7_transplant_FCopy_ScrollDown_Clamp.bin"
FCopy_ScrollNeg_Reset:
	.incbin "includes/generated/v7_transplant_FCopy_ScrollNeg_Reset.bin"
FCopy_HandleExecute:
	.incbin "includes/generated/v7_transplant_FCopy_HandleExecute.bin"
FCopy_HandleScroll:
	.incbin "includes/generated/v7_transplant_FCopy_HandleScroll.bin"
FCopy_ScrollDown_CheckMin:
	.incbin "includes/generated/v7_transplant_FCopy_ScrollDown_CheckMin.bin"
FCopy_ScrollDown_RestoreOld:
	.incbin "includes/generated/v7_transplant_FCopy_ScrollDown_RestoreOld.bin"
FCopy_ScrollDown_Reload:
	.incbin "includes/generated/v7_transplant_FCopy_ScrollDown_Reload.bin"
FCopy_Scroll_Apply:
	.incbin "includes/generated/v7_transplant_FCopy_Scroll_Apply.bin"
FCopy_ScrollUp_Adjust:
	.incbin "includes/generated/v7_transplant_FCopy_ScrollUp_Adjust.bin"
FCopy_ScrollUp_CheckMax:
	.incbin "includes/generated/v7_transplant_FCopy_ScrollUp_CheckMax.bin"
FCopy_HandleCopyContext:
	.incbin "includes/generated/v7_transplant_FCopy_HandleCopyContext.bin"
FCopy_DispatchFA9D58:
	call ApPostEvent
	jrl FCopy_Return

FCopy_CopyConfirm_Execute:
	.incbin "includes/generated/v7_transplant_FCopy_CopyConfirm_Execute.bin"
FCopy_CopyExecute:
	.incbin "includes/generated/v7_transplant_FCopy_CopyExecute.bin"
FCopy_NotifyComplete:
	call SoundCtrl_SendCommand

FCopy_Return:
	lds32 xhl, 0
	pop xiz
	ret

FileRenameFunc:
	.incbin "includes/generated/v7_transplant_FileRenameFunc.bin"
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
	.incbin "includes/generated/v7_transplant_FRename_TextChange_Error.bin"
FRename_TextChange_SendApply:
	.incbin "includes/generated/v7_transplant_FRename_TextChange_SendApply.bin"
FRename_HandleApply:
	.incbin "includes/generated/v7_transplant_FRename_HandleApply.bin"
FRename_Return:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret

FileRenameSmfFunc:
	.incbin "includes/generated/v7_transplant_FileRenameSmfFunc.bin"
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
	.incbin "includes/generated/v7_transplant_FRenameSmf_TextChange_Error.bin"
FRenameSmf_TextChange_SendApply:
	.incbin "includes/generated/v7_transplant_FRenameSmf_TextChange_SendApply.bin"
FRenameSmf_HandleApply:
	.incbin "includes/generated/v7_transplant_FRenameSmf_HandleApply.bin"
FRenameSmf_Return:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret

FmmFormatFunc:
	.incbin "includes/generated/v7_transplant_FmmFormatFunc.bin"
FmmFmt_InitPhase_CheckDrive:
	.incbin "includes/generated/v7_transplant_FmmFmt_InitPhase_CheckDrive.bin"
FmmFmt_InitPhase_DriveType23:
	.incbin "includes/generated/v7_transplant_FmmFmt_InitPhase_DriveType23.bin"
FmmFmt_InitPhase_OtherDrive:
	.incbin "includes/generated/v7_transplant_FmmFmt_InitPhase_OtherDrive.bin"
FmmFmt_InitPhase_SetActive:
	.incbin "includes/generated/v7_transplant_FmmFmt_InitPhase_SetActive.bin"
FmmFmt_HandleCancel:
	.incbin "includes/generated/v7_transplant_FmmFmt_HandleCancel.bin"
FmmFmt_HandleProgress:
	.incbin "includes/generated/v7_transplant_FmmFmt_HandleProgress.bin"
FmmFmt_FormatSuccess:
	.incbin "includes/generated/v7_transplant_FmmFmt_FormatSuccess.bin"
FmmFmt_ExecutePhase2:
	.incbin "includes/generated/v7_transplant_FmmFmt_ExecutePhase2.bin"
FmmFmt_HandleAbort:
	.incbin "includes/generated/v7_transplant_FmmFmt_HandleAbort.bin"
FmmFmt_AbortPhase2:
	.incbin "includes/generated/v7_transplant_FmmFmt_AbortPhase2.bin"
FmmFmt_DispatchAndNotify:
	call ApPostEvent
	jr FmmFmt_NotifyComplete

FmmFmt_HandleAbortFinal:
	.incbin "includes/generated/v7_transplant_FmmFmt_HandleAbortFinal.bin"
FmmFmt_NotifyComplete:
	.incbin "includes/generated/v7_transplant_FmmFmt_NotifyComplete.bin"
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
	.incbin "includes/generated/v7_transplant_FmmLoadTitleFunc.bin"
FmmLoadTtl_StateDispatch:
	.incbin "includes/generated/v7_transplant_FmmLoadTtl_StateDispatch.bin"
FmmLoadTtl_CheckFileHandle:
	.incbin "includes/generated/v7_transplant_FmmLoadTtl_CheckFileHandle.bin"
FmmLoadTtl_CheckSmfHandle:
	.incbin "includes/generated/v7_transplant_FmmLoadTtl_CheckSmfHandle.bin"
FmmLoadTtl_StateCancelLoad:
	.incbin "includes/generated/v7_transplant_FmmLoadTtl_StateCancelLoad.bin"
FmmLoadTtl_StateIdle:
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0x7d
	jrl FmmLoadTtl_PlaySound

FmmLoadTtl_StateSuccess:
	.incbin "includes/generated/v7_transplant_FmmLoadTtl_StateSuccess.bin"
FmmLoadTtl_NotifyComplete:
	call SoundCtrl_SendCommand
	jrl FmmLoadTtl_Return

FmmLoadTtl_LoadSlots:
	.incbin "includes/generated/v7_transplant_FmmLoadTtl_LoadSlots.bin"
FmmLoadTtl_SlotLoop:
	.incbin "includes/generated/v7_transplant_FmmLoadTtl_SlotLoop.bin"
FmmLoadTtl_HandleScrollNav:
	.incbin "includes/generated/v7_transplant_FmmLoadTtl_HandleScrollNav.bin"
FmmLoadTtl_HandleCancelOp:
	calr CancelOperationCleanup
	ld xwa, 0x610001
	ld xbc, 0x1e0007f
	lds32 xde, 1
	call ApPostEvent
	jr FmmLoadTtl_Return

FmmLoadTtl_HandleOk:
	.incbin "includes/generated/v7_transplant_FmmLoadTtl_HandleOk.bin"
FmmLoadTtl_Ok_DefaultSound:
	ldw wa, 0x60

FmmLoadTtl_PlaySound:
	call UI_PostModeChangeEvent

FmmLoadTtl_Return:
	lds32 xhl, 0
	popw iz
	ret

FmmSaveTitleFunc:
	.incbin "includes/generated/v7_transplant_FmmSaveTitleFunc.bin"
FmmSaveTtl_CheckFont:
	.incbin "includes/generated/v7_transplant_FmmSaveTtl_CheckFont.bin"
FmmSaveTtl_SlotLoop:
	.incbin "includes/generated/v7_transplant_FmmSaveTtl_SlotLoop.bin"
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
	.incbin "includes/generated/v7_transplant_DiskNameFunc.bin"
DiskName_TextChange:
	.incbin "includes/generated/v7_transplant_DiskName_TextChange.bin"
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
	.incbin "includes/generated/v7_transplant_DiskName_HandleApply.bin"
DiskName_Return:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret

DiskInfoFunc:
	.incbin "includes/generated/v7_transplant_DiskInfoFunc.bin"
DiskInfo_ReadDriveType:
	.incbin "includes/generated/v7_transplant_DiskInfo_ReadDriveType.bin"
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
	.incbin "includes/generated/v7_transplant_DiskInfo_ComputePercent.bin"
DiskInfo_ZeroPercent:
	lds32 xwa, 0
	ld (xsp + 8), xwa

DiskInfo_RenderStrings:
	.incbin "includes/generated/v7_transplant_DiskInfo_RenderStrings.bin"
DiskInfo_Return:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 16)
	ret

SongNameFunc:
	.incbin "includes/generated/v7_transplant_SongNameFunc.bin"
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
	.incbin "includes/generated/v7_transplant_SongName_NoSlot.bin"
SongName_SendDisplay:
	.incbin "includes/generated/v7_transplant_SongName_SendDisplay.bin"
SongName_Return:
	lds32 xhl, 0
	popw iz
	inc 8, xsp
	ret

SaveFileNameNumFunc:
	.incbin "includes/generated/v7_transplant_SaveFileNameNumFunc.bin"
SaveFileNum_NoSlot:
	.incbin "includes/generated/v7_transplant_SaveFileNum_NoSlot.bin"
SaveFileNum_SendDisplay:
	.incbin "includes/generated/v7_transplant_SaveFileNum_SendDisplay.bin"
SaveFileNum_Return:
	lds32 xhl, 0
	popw iz
	inc 4, xsp
	ret

SaveFileNameFunc:
	.incbin "includes/generated/v7_transplant_SaveFileNameFunc.bin"
SaveFileName_TextChange:
	.incbin "includes/generated/v7_transplant_SaveFileName_TextChange.bin"
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
	.incbin "includes/generated/v7_transplant_SaveFileName_HandleApply.bin"
SaveFileName_Return:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret

CurFileNameFunc:
	.incbin "includes/generated/v7_transplant_CurFileNameFunc.bin"
CurFileName_NoSlot:
	.incbin "includes/generated/v7_transplant_CurFileName_NoSlot.bin"
CurFileName_SendDisplay:
	.incbin "includes/generated/v7_transplant_CurFileName_SendDisplay.bin"
CurFileName_Return:
	lds32 xhl, 0
	popw iz
	inc 4, xsp
	ret

