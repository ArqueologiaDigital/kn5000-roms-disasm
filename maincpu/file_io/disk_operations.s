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
	cp xbc, 0x1C00018
	jrl z, FCopy_HandleScroll
	cp xbc, 0x1C00017
	jrl z, FCopy_HandleScroll
	cp xbc, 0x1C0000B
	jr z, FCopy_HandleExecute
	cp xbc, 0x1E50004
	jrl nz, FCopy_Return
	stda32 32608, xiz
	call 0xF895EF
	stda16 32612, xhl
	cps hl, 0
	jr lt, FCopy_ScrollNeg_Reset
	cp hl, 0x13
	jr ge, FCopy_ScrollDown_Clamp
	inc 1, hl
	stda16 32614, xhl
	jrl FCopy_Return

FCopy_ScrollDown_Clamp:
	dec 1, hl
	stda16 32614, xhl
	jrl FCopy_Return

FCopy_ScrollNeg_Reset:
	stdi16 32612, 0
	stdi16 32614, 1
	jrl FCopy_Return

FCopy_HandleExecute:
	stdi8 34060, 0
	ldda16 xwa, 32614
	call LABEL_F89623
	ld xbc, xhl
	ldada xwa, 34061
	ldda16 xde, 32614
	inc 1, de
	pushw 0x6
	pushw 0x0
	call LABEL_F891DD
	ldda32 xwa, 32608
	ld xbc, 0x1C0000F
	ld xde, 0x850C
	call 0xFA9D58
	jrl FCopy_Return

FCopy_HandleScroll:
	or xiz, xiz
	jrl nz, FCopy_HandleCopyContext
	ldda16 xwa, 32614
	ld de, wa
	cp xbc, 0x1C00018
	jr nz, FCopy_ScrollUp_Adjust
	cps wa, 0
	jr le, FCopy_ScrollDown_CheckMin
	dec 1, wa
	stda16 32614, xwa

FCopy_ScrollDown_CheckMin:
	ldda16 xwa, 32614
	cpda16 xwa, 32612
	jr nz, FCopy_ScrollDown_Reload
	cps wa, 0
	jr le, FCopy_ScrollDown_RestoreOld
	dec 1, wa
	stda16 32614, xwa
	jr FCopy_Scroll_Apply

FCopy_ScrollDown_RestoreOld:
	stda16 32614, xde

FCopy_ScrollDown_Reload:
	ldda16 xwa, 32614

FCopy_Scroll_Apply:
	cp wa, de
	jrl z, FCopy_Return
	stdi8 34060, 0
	ldda16 xwa, 32614
	call LABEL_F89623
	ld xbc, xhl
	ldada xwa, 34061
	ldda16 xde, 32614
	inc 1, de
	pushw 0x6
	pushw 0x0
	call LABEL_F891DD
	ldda32 xwa, 32608
	ld xbc, 0x1C0000F
	ld xde, 0x850C
	jr FCopy_DispatchFA9D58

FCopy_ScrollUp_Adjust:
	cp xbc, 0x1C00017
	jr nz, FCopy_ScrollDown_Reload
	cp wa, 0x13
	jr ge, FCopy_ScrollUp_CheckMax
	inc 1, wa
	stda16 32614, xwa

FCopy_ScrollUp_CheckMax:
	ldda16 xwa, 32614
	cpda16 xwa, 32612
	jr nz, FCopy_ScrollDown_Reload
	cp wa, 0x13
	jr ge, FCopy_ScrollDown_RestoreOld
	inc 1, wa
	stda16 32614, xwa
	jr FCopy_Scroll_Apply

FCopy_HandleCopyContext:
	cp xiz, 0x8
	jrl nz, FCopy_CopyExecute
	call 0xF8943E
	cps hl, 0
	jrl z, FCopy_CopyExecute
	ldda16 xwa, 32614
	call LABEL_F8945F
	cps hl, 0
	jr z, FCopy_CopyConfirm_Execute
	cpi8_24 0x0340ea, 0x00
	jr z, FCopy_CopyConfirm_Execute
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C50000
	lds32 xde, 1
	call 0xFA9D58
	ld xwa, 0x600037
	ld xbc, 0x1C00001
	lds32 xde, 0

FCopy_DispatchFA9D58:
	call 0xFA9D58
	jrl FCopy_Return

FCopy_CopyConfirm_Execute:
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	lds wa, 0
	calr InitializeOperationState
	ldda16 xwa, 32614
	call LABEL_F889D9
	ld wa, hl
	lds bc, 5
	calr LABEL_F8B48E
	stda8 32578, l
	calr SignalProgressUpdate
	call LABEL_F89568
	call 0xF8953B
	call 0xF8987D
	stda16 34050, xhl
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call 0xFA9D58
	ldw wa, 0x7B
	call 0xF99490
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0xEE
	jr FCopy_NotifyComplete

FCopy_CopyExecute:
	cp xiz, 0x32
	jr nz, FCopy_Return
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	lds wa, 0
	calr InitializeOperationState
	ldda16 xwa, 32614
	call LABEL_F889D9
	ld wa, hl
	lds bc, 5
	calr LABEL_F8B48E
	stda8 32578, l
	calr SignalProgressUpdate
	call LABEL_F89568
	call 0xF8953B
	call 0xF8987D
	stda16 34050, xhl
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call 0xFA9D58
	ldw wa, 0x7B
	call 0xF99490
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0xEE

FCopy_NotifyComplete:
	call LABEL_F994BD

FCopy_Return:
	lds32 xhl, 0
	pop xiz
	ret

FileRenameFunc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	cp xbc, 0x1E00086
	jrl z, FRename_HandleApply
	cp xbc, 0x1E0003A
	jrl nz, FRename_Return
	call 0xF895EF
	cps hl, 0
	jr lt, FRename_TextChange_Error
	ldada xiz, 34928
	ld wa, hl
	call LABEL_F89623
	ld xbc, xhl
	ld xwa, xiz
	call LABEL_F890DC
	lds iy, 0
	lda_24 xix, 0xeed778
	ldada xwa, 34928
	ld xhl, xwa
	jr FRename_PadLoop_Cond

FRename_PadLoop_CheckChar:
	extz bc
	ld_srib3 C, 0x07, 0xF0, 0xE4
	and c, 0x7
	jr nz, FRename_PadLoop_Advance
	ld (xde), 0x5F

FRename_PadLoop_Advance:
	inc 1, iy

FRename_PadLoop_Cond:
	cps iy, 6
	jr ge, FRename_PadLoop_Fill
	st_dri3b B, 0x07, 0xEC, 0xF4
	ld c, (xde)
	cps c, 0
	jr nz, FRename_PadLoop_CheckChar

FRename_PadLoop_Fill:
	cps iy, 6
	jr ge, FRename_PadDone
	ld xbc, xwa

FRename_FillLoop:
	stib_dri 0x07, 0xE4, 0xF4, 0x5F
	inc 1, iy
	cps iy, 6
	jr lt, FRename_FillLoop

FRename_PadDone:
	ld (xwa + 6), 0x0
	jr FRename_TextChange_SendApply

FRename_TextChange_Error:
	ld xwa, 0x8870
	ld xbc, 0xEA06BE
	call LABEL_F890DC

FRename_TextChange_SendApply:
	ld xwa, (xsp + 4)
	ld xbc, 0x1E00086
	ld xde, 0x8870
	call 0xFA9D58
	jr FRename_Return

FRename_HandleApply:
	call 0xF8943E
	cps hl, 0
	jr z, FRename_Return
	ld xwa, 0x8870
	ld xbc, (xsp + 4)
	call LABEL_F890DC
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	lds wa, 0
	calr InitializeOperationState
	ld xwa, 0x8870
	call LABEL_F8879E
	ld wa, hl
	lds bc, 5
	calr LABEL_F8B48E
	stda8 32578, l
	calr SignalProgressUpdate
	call 0xF8987D
	stda16 34050, xhl
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0xEE
	call LABEL_F994BD

FRename_Return:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret

FileRenameSmfFunc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	cp xbc, 0x1E00086
	jrl z, FRenameSmf_HandleApply
	cp xbc, 0x1E0003A
	jrl nz, FRenameSmf_Return
	call LABEL_F89AC7
	cps hl, 0
	jr lt, FRenameSmf_TextChange_Error
	ldada xiz, 34928
	ld wa, hl
	call LABEL_F89BF0
	ld xbc, xhl
	ld xwa, xiz
	call LABEL_F890DC
	lds iy, 0
	lda_24 xix, 0xeed778
	ldada xwa, 34928
	ld xhl, xwa
	jr FRenameSmf_PadLoop_Cond

FRenameSmf_PadLoop_CheckChar:
	extz bc
	ld_srib3 C, 0x07, 0xF0, 0xE4
	and c, 0x7
	jr nz, FRenameSmf_PadLoop_Advance
	ld (xde), 0x5F

FRenameSmf_PadLoop_Advance:
	inc 1, iy

FRenameSmf_PadLoop_Cond:
	cp iy, 0x8
	jr ge, FRenameSmf_PadLoop_Fill
	st_dri3b B, 0x07, 0xEC, 0xF4
	ld c, (xde)
	cps c, 0
	jr nz, FRenameSmf_PadLoop_CheckChar

FRenameSmf_PadLoop_Fill:
	cp iy, 0x8
	jr ge, FRenameSmf_PadDone
	ld xbc, xwa

FRenameSmf_FillLoop:
	stib_dri 0x07, 0xE4, 0xF4, 0x5F
	inc 1, iy
	cp iy, 0x8
	jr lt, FRenameSmf_FillLoop

FRenameSmf_PadDone:
	ld (xwa + 8), 0x0
	jr FRenameSmf_TextChange_SendApply

FRenameSmf_TextChange_Error:
	ld xwa, 0x8870
	ld xbc, 0xEA06C6
	call LABEL_F890DC

FRenameSmf_TextChange_SendApply:
	ld xwa, (xsp + 4)
	ld xbc, 0x1E00086
	ld xde, 0x8870
	call 0xFA9D58
	jr FRenameSmf_Return

FRenameSmf_HandleApply:
	ld xwa, 0x8870
	ld xbc, (xsp + 4)
	call LABEL_F890DC
	ld xwa, 0x8870
	ld xbc, 0xEA06D0
	call LABEL_F89113
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	lds wa, 0
	calr InitializeOperationState
	ld xwa, 0x8870
	call LABEL_F88B3A
	ld wa, hl
	lds bc, 5
	calr LABEL_F8B48E
	stda8 32578, l
	calr SignalProgressUpdate
	call 0xF89C78
	stda16 34052, xhl
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0xEE
	call LABEL_F994BD

FRenameSmf_Return:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret

FmmFormatFunc:
	pushw iz
	cp xbc, 0x1C00007
	jrl z, FmmFmt_HandleProgress
	cp xbc, 0x1C00013
	jrl nz, FmmFmt_Return
	cp xde, 0x3
	jr z, FmmFmt_HandleCancel
	cp xde, 0x2
	jrl nz, FmmFmt_Return
	lds wa, 1
	calr InitializeOperationState
	ldmm8 32618, 36151
	cpdi16 34048, 0
	jr ge, FmmFmt_InitPhase_CheckDrive
	call 0xF89520
	extz hl
	stda16 34048, xhl
	calr SignalProgressUpdate

FmmFmt_InitPhase_CheckDrive:
	ldda16 xwa, 34048
	cps wa, 2
	jr z, FmmFmt_InitPhase_DriveType23
	cps wa, 3
	jr nz, FmmFmt_InitPhase_OtherDrive

FmmFmt_InitPhase_DriveType23:
	stda8 32616, a
	ld xwa, 0x7B0036
	ld xbc, 0x1C00001
	lds32 xde, 0
	call 0xFA9D58
	stdi8 34046, 0
	jr FmmFmt_InitPhase_SetActive

FmmFmt_InitPhase_OtherDrive:
	ld xwa, 0x7B003F
	ld xbc, 0x1C00001
	lds32 xde, 0
	call 0xFA9D58
	stdi8 34046, 2

FmmFmt_InitPhase_SetActive:
	stdi8 32620, 1
	jrl FmmFmt_Return

FmmFmt_HandleCancel:
	calr CancelOperationCleanup
	stdi8 34046, 0
	stdi8 32620, 0
	jrl FmmFmt_Return

FmmFmt_HandleProgress:
	cpdi8 32620, 0
	jrl z, FmmFmt_Return
	ldda8 a, 32618
	extz wa
	cp xde, 0xF
	jrl z, FmmFmt_HandleAbortFinal
	ldda8 c, 34046
	cp xde, 0xB
	jrl z, FmmFmt_HandleAbort
	cp xde, 0xA
	jrl nz, FmmFmt_Return
	ld a, c
	cps c, 0
	jrl nz, FmmFmt_ExecutePhase2
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	lds wa, 0
	calr InitializeOperationState
	ldda8 a, 32616
	extz wa
	call LABEL_F89091
	ld iz, hl
	calr SignalProgressUpdate
	calr ResetProgressIndication
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	cps iz, 0
	jr ge, FmmFmt_FormatSuccess
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call 0xFA9D58
	ldda8 a, 32618
	extz wa
	call 0xF99490
	stdi8 32620, 0
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	ld wa, iz
	ldw bc, 0x8
	calr LABEL_F8B48E
	stda8 32578, l
	ldw wa, 0xEE
	call LABEL_F994BD
	jrl FmmFmt_NotifyComplete

FmmFmt_FormatSuccess:
	ld xwa, 0x7B0036
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0x7B0031
	ld xbc, 0x1C00001
	lds32 xde, 0
	call 0xFA9D58
	stdi8 34046, 1
	jr FmmFmt_Return

FmmFmt_ExecutePhase2:
	cps a, 2
	jr nz, FmmFmt_Return
	stdi8 32616, 3
	ld xwa, 0x7B003F
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0x7B0036
	ld xbc, 0x1C00001
	lds32 xde, 0
	jr FmmFmt_DispatchAndNotify

FmmFmt_HandleAbort:
	ld e, c
	cps c, 0
	jr nz, FmmFmt_AbortPhase2
	call 0xF99490
	stdi8 32620, 0
	jr FmmFmt_Return

FmmFmt_AbortPhase2:
	cps e, 2
	jr nz, FmmFmt_Return
	stdi8 32616, 2
	ld xwa, 0x7B003F
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0x7B0036
	ld xbc, 0x1C00001
	lds32 xde, 0

FmmFmt_DispatchAndNotify:
	call 0xFA9D58
	jr FmmFmt_NotifyComplete

FmmFmt_HandleAbortFinal:
	call 0xF99490
	stdi8 32620, 0

FmmFmt_NotifyComplete:
	stdi8 34046, 0

FmmFmt_Return:
	lds32 xhl, 0
	popw iz
	ret

UtilityTtlJgFunc:
	cp xbc, 0x1C00007
	jr nz, UtilTtlJg_Return
	ldw wa, 0x7B
	ldw bc, 0x7C
	calr LABEL_F8B36E

UtilTtlJg_Return:
	lds32 xhl, 0
	ret

FmmLoadTitleFunc:
	pushw iz
	cp xbc, 0x1C00007
	jrl z, FmmLoadTtl_HandleOk
	cp xbc, 0x1C00013
	jrl nz, FmmLoadTtl_Return
	cp xde, 0x3
	jrl z, FmmLoadTtl_HandleCancelOp
	cp xde, 0x9
	jrl z, FmmLoadTtl_HandleScrollNav
	cp xde, 0x2
	jrl nz, FmmLoadTtl_Return
	stdi8 34046, 0
	ldmm16 32624, 34048
	lds wa, 1
	calr InitializeOperationState
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	ldmm8 32622, 36151
	cpdi16 34048, 0
	jr ge, FmmLoadTtl_StateDispatch
	call 0xF89520
	extz hl
	stda16 34048, xhl
	calr SignalProgressUpdate

FmmLoadTtl_StateDispatch:
	ldda16 xwa, 34048
	cps wa, 1
	jrl z, FmmLoadTtl_StateSuccess
	cps wa, 0
	jrl z, FmmLoadTtl_StateIdle
	cps wa, 5
	jr z, FmmLoadTtl_StateCancelLoad
	cpdi16 34050, 0
	jr ge, FmmLoadTtl_CheckFileHandle
	call 0xF8987D
	stda16 34050, xhl
	call LABEL_F8958D
	call 0xF8953B
	calr SignalProgressUpdate

FmmLoadTtl_CheckFileHandle:
	cpdi16 34050, 0
	jrl nz, FmmLoadTtl_LoadSlots
	cpdi16 34052, 0
	jr ge, FmmLoadTtl_CheckSmfHandle
	call 0xF89C78
	stda16 34052, xhl
	calr SignalProgressUpdate

FmmLoadTtl_CheckSmfHandle:
	cpdi16 34052, 0
	jrl le, FmmLoadTtl_LoadSlots
	cpdi8 32622, 100
	jrl z, FmmLoadTtl_LoadSlots
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0x64
	jrl FmmLoadTtl_PlaySound

FmmLoadTtl_StateCancelLoad:
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call 0xFA9D58
	ldda8 a, 32622
	extz wa
	call 0xF99490
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	stdi8 32578, 0
	ldw wa, 0xEE
	jr FmmLoadTtl_NotifyComplete

FmmLoadTtl_StateIdle:
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0x7D
	jrl FmmLoadTtl_PlaySound

FmmLoadTtl_StateSuccess:
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	calr ResetProgressIndication
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call 0xFA9D58
	ldda8 a, 32622
	extz wa
	call 0xF99490
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	stdi8 32578, 2
	ldw wa, 0xEE

FmmLoadTtl_NotifyComplete:
	call LABEL_F994BD
	jrl FmmLoadTtl_Return

FmmLoadTtl_LoadSlots:
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	call 0xFA9D58
	stdi8 35324, 0
	stdi8 35326, 0
	stdi8 35328, 0
	stdi8 35330, 0
	stdi8 35332, 0
	stdi8 35334, 0
	stdi8 35336, 0
	lds iz, 0

FmmLoadTtl_SlotLoop:
	ldto_berp A, 0xF8
	extz wa
	call LABEL_F89321
	inc 1, iz
	cp iz, 0x8
	jr lt, FmmLoadTtl_SlotLoop
	stdi8 35320, 4
	jr FmmLoadTtl_Return

FmmLoadTtl_HandleScrollNav:
	cpdi16 32624, 0
	jr lt, FmmLoadTtl_Return
	call 0xF895EF
	ld iz, hl
	cps iz, 0
	jr lt, FmmLoadTtl_Return
	cp iz, 0x13
	jr ge, FmmLoadTtl_Return
	ld wa, iz
	inc 1, wa
	call 0xF89605
	jr FmmLoadTtl_Return

FmmLoadTtl_HandleCancelOp:
	calr CancelOperationCleanup
	ld xwa, 0x610001
	ld xbc, 0x1E0007F
	lds32 xde, 1
	call 0xFA9D58
	jr FmmLoadTtl_Return

FmmLoadTtl_HandleOk:
	cp xde, 0xF
	jr nz, FmmLoadTtl_Return
	cpdi8 36148, 7
	jr nz, FmmLoadTtl_Ok_DefaultSound
	ldw wa, 0xD6
	jr FmmLoadTtl_PlaySound

FmmLoadTtl_Ok_DefaultSound:
	ldw wa, 0x60

FmmLoadTtl_PlaySound:
	call 0xF99490

FmmLoadTtl_Return:
	lds32 xhl, 0
	popw iz
	ret

FmmSaveTitleFunc:
	pushw iz
	cp xbc, 0x1C00007
	jrl z, FmmSaveTtl_HandleOk
	cp xbc, 0x1C00013
	jrl nz, FmmSaveTtl_Return
	cp xde, 0x3
	jrl z, FmmSaveTtl_HandleCancel
	cp xde, 0x2
	jrl nz, FmmSaveTtl_Return
	stdi8 34046, 0
	lds wa, 1
	calr InitializeOperationState
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	cpdi16 34050, 0
	jr ge, FmmSaveTtl_CheckFont
	call 0xF8987D
	stda16 34050, xhl
	call LABEL_F8958D
	call 0xF8953B
	calr SignalProgressUpdate

FmmSaveTtl_CheckFont:
	cpdi8 36151, 102
	jr z, FmmSaveTtl_CommitSave
	lds iz, 0

FmmSaveTtl_SlotLoop:
	ldto_berp A, 0xF8
	extz wa
	call LABEL_F8937F
	inc 1, iz
	cps iz, 6
	jr lt, FmmSaveTtl_SlotLoop
	lds wa, 6
	call LABEL_F89393
	lds wa, 7
	call LABEL_F89393
	call LABEL_F893CA
	ld xiy, 0xEA066A
	ld xix, 0x8A0C
	ldiw

FmmSaveTtl_CommitSave:
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	jr FmmSaveTtl_DispatchAndReturn

FmmSaveTtl_HandleCancel:
	calr CancelOperationCleanup
	ld xwa, 0x670001
	ld xbc, 0x1E0007F
	lds32 xde, 1

FmmSaveTtl_DispatchAndReturn:
	call 0xFA9D58
	jr FmmSaveTtl_Return

FmmSaveTtl_HandleOk:
	cp xde, 0xF
	jr nz, FmmSaveTtl_Return
	ldw wa, 0x60
	call 0xF99490

FmmSaveTtl_Return:
	lds32 xhl, 0
	popw iz
	ret

DiskNameFunc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	cp xbc, 0x1E00086
	jrl z, DiskName_HandleApply
	cp xbc, 0x1E0003A
	jr z, DiskName_TextChange
	cp xbc, 0x1C0000B
	jrl nz, DiskName_Return
	lds wa, 0
	calr InitializeOperationState
	ldada xiz, 34700
	call LABEL_F8958D
	ld xbc, xhl
	ld xwa, xiz
	call LABEL_F890DC
	ld xwa, (xsp + 4)
	ld xbc, 0x1C0000F
	ld xde, 0x878C
	jr DiskName_Dispatch

DiskName_TextChange:
	lds wa, 0
	calr InitializeOperationState
	ldada xiz, 34700
	call LABEL_F8958D
	ld xbc, xhl
	ld xwa, xiz
	call LABEL_F890DC
	lds iy, 0
	ldada xix, 34928
	lda_24 xiz, 0xeed778
	ldada xde, 34700
	ld xhl, xde
	jr DiskName_PadLoop_Cond

DiskName_PadLoop_CheckChar:
	ld_srib3 A, 0x07, 0xF0, 0xF4
	extz wa
	ld_srib3 A, 0x07, 0xF8, 0xE0
	and a, 0x7
	jr nz, DiskName_PadLoop_Advance
	ld (xbc), 0x5F

DiskName_PadLoop_Advance:
	inc 1, iy

DiskName_PadLoop_Cond:
	cp iy, 0xB
	jr ge, DiskName_PadLoop_Fill
	st_dri3b A, 0x07, 0xEC, 0xF4
	cp (xbc), 0x0
	jr nz, DiskName_PadLoop_CheckChar

DiskName_PadLoop_Fill:
	cp iy, 0xB
	jr ge, DiskName_PadDone
	ld xwa, xde

DiskName_FillLoop:
	stib_dri 0x07, 0xE0, 0xF4, 0x5F
	inc 1, iy
	cp iy, 0xB
	jr lt, DiskName_FillLoop

DiskName_PadDone:
	ld (xde + 11), 0x0
	ld xwa, (xsp + 4)
	ld xbc, 0x1E00086

DiskName_Dispatch:
	call 0xFA9D58
	jr DiskName_Return

DiskName_HandleApply:
	ld xwa, 0x878C
	ld xbc, (xsp + 4)
	call LABEL_F890DC
	lds wa, 0
	calr InitializeOperationState
	ld xwa, 0x878C
	call LABEL_F5289C
	calr SignalProgressUpdate
	calr ResetProgressIndication
	ldw wa, 0x60
	call 0xF99490

DiskName_Return:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret

DiskInfoFunc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 16), xde
	cp xbc, 0x1C0000B
	jrl nz, DiskInfo_Return
	lds wa, 0
	calr InitializeOperationState
	cpdi16 34048, 0
	jr ge, DiskInfo_ReadDriveType
	call 0xF89520
	extz hl
	stda16 34048, xhl

DiskInfo_ReadDriveType:
	ldda16 xwa, 34048
	cps wa, 1
	jr z, DiskInfo_ResetCapacity
	cps wa, 0
	jr z, DiskInfo_ResetCapacity
	cps wa, 2
	jr z, DiskInfo_ReadCapacity
	cps wa, 3
	jr nz, DiskInfo_ZeroCapacity

DiskInfo_ReadCapacity:
	call 0xF8953B
	ld (xsp + 4), xhl
	call LABEL_F89573
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
	call LABEL_FF0C0E
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
	and xbc, 0x3FF
	add xbc, xwa
	ld (xsp + 4), xbc
	sra xbc, 10
	ld (xsp + 4), xbc
	ldda16 xwa, 34048
	sla wa, 2
	lda_24 xbc, 0xea0558
	ld_sril3 XBC, 0x07, 0xE4, 0xE0
	ld xwa, 0x87CE
	call LABEL_F890DC
	ld xwa, 0x87CE
	ld xbc, 0xEA06D6
	call LABEL_F89113
	ldada xwa, 34766
	ld (xsp + 12), xwa
	ld xwa, (xsp + 4)
	lds bc, 4
	calr LABEL_F8B67F
	ld xbc, xhl
	ld xwa, (xsp + 12)
	call LABEL_F89113
	ld xwa, 0x87CE
	ld xbc, 0xEA06DA
	call LABEL_F89113
	ldada xwa, 34766
	ld (xsp + 12), xwa
	ld xwa, (xsp + 8)
	lds bc, 3
	calr LABEL_F8B67F
	ld xbc, xhl
	ld xwa, (xsp + 12)
	call LABEL_F89113
	ld xwa, 0x87CE
	ld xbc, 0xEA06E4
	call LABEL_F89113
	ld xwa, (xsp + 16)
	ld xbc, 0x1C0000F
	ld xde, 0x87CE
	call 0xFA9D58

DiskInfo_Return:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 16)
	ret

SongNameFunc:
	dec 8, xsp
	pushw iz
	ld (xsp + 6), xde
	cp xbc, 0x1C0000B
	jr nz, SongName_Return
	call LABEL_F89AC7
	ld iz, hl
	cps iz, 0
	jr lt, SongName_NoSlot
	lds wa, 0
	calr InitializeOperationState
	ldada xwa, 34830
	ld (xsp + 2), xwa
	ld wa, iz
	call LABEL_F8A07F
	ld xbc, xhl
	ld xwa, (xsp + 2)
	call LABEL_F890DC
	ldada xwa, 34830
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
	call LABEL_F8929D
	jr SongName_SendDisplay

SongName_NoSlot:
	stdi8 34830, 0

SongName_SendDisplay:
	ld xwa, (xsp + 6)
	ld xbc, 0x1C0000F
	ld xde, 0x880E
	call 0xFA9D58

SongName_Return:
	lds32 xhl, 0
	popw iz
	inc 8, xsp
	ret

SaveFileNameNumFunc:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xde
	cp xbc, 0x1C0000B
	jr nz, SaveFileNum_Return
	call 0xF895EF
	ld iz, hl
	cps iz, 0
	jr lt, SaveFileNum_NoSlot
	call LABEL_F892BC
	ld xbc, xhl
	ld de, iz
	inc 1, de
	pushw 0x6
	pushw 0x0
	ld xwa, 0x8850
	call LABEL_F891DD
	jr SaveFileNum_SendDisplay

SaveFileNum_NoSlot:
	stdi8 34896, 0

SaveFileNum_SendDisplay:
	ld xwa, (xsp + 2)
	ld xbc, 0x1C0000F
	ld xde, 0x8850
	call 0xFA9D58

SaveFileNum_Return:
	lds32 xhl, 0
	popw iz
	inc 4, xsp
	ret

SaveFileNameFunc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	cp xbc, 0x1E00086
	jrl z, SaveFileName_HandleApply
	cp xbc, 0x1E0003A
	jr z, SaveFileName_TextChange
	cp xbc, 0x1C0000B
	jrl nz, SaveFileName_Return
	ldada xiz, 34896
	call LABEL_F892BC
	ld xbc, xhl
	ld xwa, xiz
	call LABEL_F890DC
	ld xwa, 0x8850
	call LABEL_F8929D
	ld xwa, (xsp + 4)
	ld xbc, 0x1C0000F
	ld xde, 0x8850
	jr SaveFileName_Dispatch

SaveFileName_TextChange:
	ldada xiz, 34896
	call LABEL_F892BC
	ld xbc, xhl
	ld xwa, xiz
	call LABEL_F890DC
	lds iy, 0
	lda_24 xix, 0xeed778
	ldada xde, 34896
	ld xhl, xde
	jr SaveFileName_PadLoop_Cond

SaveFileName_PadLoop_CheckChar:
	extz wa
	ld_srib3 A, 0x07, 0xF0, 0xE0
	and a, 0x7
	jr nz, SaveFileName_PadLoop_Advance
	ld (xbc), 0x5F

SaveFileName_PadLoop_Advance:
	inc 1, iy

SaveFileName_PadLoop_Cond:
	cps iy, 6
	jr ge, SaveFileName_PadLoop_Fill
	st_dri3b A, 0x07, 0xEC, 0xF4
	ld a, (xbc)
	cps a, 0
	jr nz, SaveFileName_PadLoop_CheckChar

SaveFileName_PadLoop_Fill:
	cps iy, 6
	jr ge, SaveFileName_PadDone
	ld xwa, xde

SaveFileName_FillLoop:
	stib_dri 0x07, 0xE0, 0xF4, 0x5F
	inc 1, iy
	cps iy, 6
	jr lt, SaveFileName_FillLoop

SaveFileName_PadDone:
	ld (xde + 6), 0x0
	ld xwa, (xsp + 4)
	ld xbc, 0x1E00086

SaveFileName_Dispatch:
	call 0xFA9D58
	jr SaveFileName_Return

SaveFileName_HandleApply:
	ld xwa, 0x8850
	ld xbc, (xsp + 4)
	call LABEL_F890DC
	ld xwa, 0x8850
	call LABEL_F892C2

SaveFileName_Return:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret

CurFileNameFunc:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xde
	cp xbc, 0x1C0000B
	jr nz, CurFileName_Return
	call 0xF895EF
	ld iz, hl
	cps iz, 0
	jr lt, CurFileName_NoSlot
	ld wa, iz
	call LABEL_F89623
	ld xbc, xhl
	ld de, iz
	inc 1, de
	pushw 0x6
	pushw 0x0
	ld xwa, 0x8870
	call LABEL_F891DD
	jr CurFileName_SendDisplay

CurFileName_NoSlot:
	stdi8 34928, 0

CurFileName_SendDisplay:
	ld xwa, (xsp + 2)
	ld xbc, 0x1C0000F
	ld xde, 0x8870
	call 0xFA9D58

CurFileName_Return:
	lds32 xhl, 0
	popw iz
	inc 4, xsp
	ret

