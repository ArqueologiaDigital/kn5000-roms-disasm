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
	push	xiz
	ld	xiz, xde
	cp	xbc, 29360152
	jrl	z, 137
	cp	xbc, 29360151
	jrl	z, 128
	cp	xbc, 29360139
	jr	z, 64
	cp	xbc, 31784964
	jrl	nz, 591
	stda32	(32452), xiz
	call	16290274
	stda16	(32456), hl
	cps	hl, 0
	jr	lt, 24
	cp	hl, 19
	jr	ge, 9
	inc	1, hl
	stda16	(32458), hl
	jrl	560
FCopy_ScrollDown_Clamp:
	dec	1, hl
	stda16	(32458), hl
	jrl	551
FCopy_ScrollNeg_Reset:
	stdi16	(32456), 0
	stdi16	(32458), 1
	jrl	536
FCopy_HandleExecute:
	stdi8	(33904), 0
	ld	wa, (32458:16)
	call	16290326
	ld	xbc, xhl
	lda	xwa, (33905:16)
	ld	de, (32458:16)
	inc	1, de
	pushw	6
	pushw	0
	call	16289232
	ld	xwa, (32452:16)
	ld	xbc, 29360143
	ld	xde, 33904
	call	16423243
	jrl	480
FCopy_HandleScroll:
	or	xiz, xiz
	jrl	nz, 154
	ld	wa, (32458:16)
	ld	de, wa
	cp	xbc, 29360152
	jr	nz, 96
	cps	wa, 0
	jr	le, 6
	dec	1, wa
	stda16	(32458), wa
FCopy_ScrollDown_CheckMin:
	ld	wa, (32458:16)
	cpda16	xwa, (32456)
	jr	nz, 16	; -> 0xF8B862
	cps	wa, 0
	jr	le, 8	; -> 0xF8B85E
	dec	1, wa
	stda16	(32458), wa
	jr	8	; -> 0xF8B866
FCopy_ScrollDown_RestoreOld:
	stda16	(32458), de
FCopy_ScrollDown_Reload:
	ld	wa, (32458:16)
FCopy_Scroll_Apply:
	cp	wa, de
	jrl	z, 416
	stdi8	(33904), 0
	ld	wa, (32458:16)
	call	16290326
	ld	xbc, xhl
	lda	xwa, (33905:16)
	ld	de, (32458:16)
	inc	1, de
	pushw	6
	pushw	0
	call	16289232
	ld	xwa, (32452:16)
	ld	xbc, 29360143
	ld	xde, 33904
	jr	110
FCopy_ScrollUp_Adjust:
	cp	xbc, 29360151
	jr	nz, -68
	cp	wa, 19
	jr	ge, 6
	inc	1, wa
	stda16	(32458), wa
FCopy_ScrollUp_CheckMax:
	ld	wa, (32458:16)
	cpda16	xwa, (32456)
	jr	nz, -90	; -> 0xF8B862
	cp	wa, 19
	jr	ge, -100	; -> 0xF8B85E
	inc	1, wa
	stda16	(32458), wa
	jr	-100	; -> 0xF8B866
FCopy_HandleCopyContext:
	cp XIZ,0x00000008
	jrl nz, FCopy_CopyExecute
	call CheckFileSystemStatus
	cps hl, 0
	jrl z, FCopy_CopyExecute
	ld wa, (0x7eca:16)
	call FileIO_GetRecordFlags
	cps hl, 0
	jr z, FCopy_CopyConfirm_Execute
	.byte 0xc2, 0xea, 0x40, 0x03, 0x3f, 0x00, 0x66, 0x23
	.byte 0x40, 0xff, 0xff, 0xff, 0xff, 0x41, 0x00, 0x00
	.byte 0xc5, 0x01, 0xea, 0xa9, 0x1d, 0x4b, 0x99, 0xfa
	.byte 0x40, 0x37, 0x00, 0x60, 0x00, 0x41, 0x01, 0x00
	.byte 0xc0, 0x01, 0xea, 0xa8
FCopy_DispatchFA9D58:
	call ApPostEvent
	jrl FCopy_Return

FCopy_CopyConfirm_Execute:
	ld	xwa, 6291494
	ld	xbc, 29360129
	lds32	xde, 5
	call	16423243
	lds	wa, 0
	calr	62671
	ld	wa, (32458:16)
	call	16287180
	ld	wa, hl
	lds	bc, 5
	calr	63306
	ld	(32422:16), l
	calr	62741
	call	16290139
	call	16290094
	call	16290928
	stda16	(33894), hl
	ld	xwa, 6291494
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 1
	call	16423243
	ldw	wa, 123
	call	16355459
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 0
	call	16423243
	ldw	wa, 238
	jr	125
FCopy_CopyExecute:
	cp	xiz, 50
	jr	nz, 121
	ld	xwa, 6291494
	ld	xbc, 29360129
	lds32	xde, 5
	call	16423243
	lds	wa, 0
	calr	62544
	ld	wa, (32458:16)
	call	16287180
	ld	wa, hl
	lds	bc, 5
	calr	63179
	ld	(32422:16), l
	calr	62614
	call	16290139
	call	16290094
	call	16290928
	stda16	(33894), hl
	ld	xwa, 6291494
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 1
	call	16423243
	ldw	wa, 123
	call	16355459
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 0
	call	16423243
	ldw	wa, 238
FCopy_NotifyComplete:
	call SoundCtrl_SendCommand

FCopy_Return:
	lds32 xhl, 0
	pop xiz
	ret

FileRenameFunc:
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	cp	xbc, 31457414
	jrl	z, 139
	cp	xbc, 31457338
	jrl	nz, 225
	call	16290274
	cps	hl, 0
	jr	lt, 89
	lda	xiz, (34772:16)
	ld	wa, hl
	call	16290326
	ld	xbc, xhl
	ld	xwa, xiz
	call	16288975
	lds	iy, 0
	lda	xix, (15652728:24)
	lda	xwa, (34772:16)
	ld	xhl, xwa
	jr	17
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
	lda_dri XDE, 0x07, 0xec, 0xf4
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
	ld	xwa, 34772
	ld	xbc, 15337150
	call	16288975
FRename_TextChange_SendApply:
	ld	xwa, (xsp+4)
	ld	xbc, 31457414
	ld	xde, 34772
	call	16423243
	jr	95
FRename_HandleApply:
	call	16289841
	cps	hl, 0
	jr	z, 87
	ld	xwa, 34772
	ld	xbc, (xsp+4)
	call	16288975
	ld	xwa, 6291494
	ld	xbc, 29360129
	lds32	xde, 5
	call	16423243
	lds	wa, 0
	calr	62245
	ld	xwa, 34772
	call	16286609
	ld	wa, hl
	lds	bc, 5
	calr	62879
	ld	(32422:16), l
	calr	62314
	call	16290928
	stda16	(33894), hl
	ld	xwa, 6291494
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	ldw	wa, 238
	call	16355504
FRename_Return:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret

FileRenameSmfFunc:
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	cp	xbc, 31457414
	jrl	z, 145
	cp	xbc, 31457338
	jrl	nz, 237
	call	16291514
	cps	hl, 0
	jr	lt, 95
	lda	xiz, (34772:16)
	ld	wa, hl
	call	16291811
	ld	xbc, xhl
	ld	xwa, xiz
	call	16288975
	lds	iy, 0
	lda	xix, (15652728:24)
	lda	xwa, (34772:16)
	ld	xhl, xwa
	jr	17
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
	lda_dri XDE, 0x07, 0xec, 0xf4
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
	ld	xwa, 34772
	ld	xbc, 15337158
	call	16288975
FRenameSmf_TextChange_SendApply:
	ld	xwa, (xsp+4)
	ld	xbc, 31457414
	ld	xde, 34772
	call	16423243
	jr	101
FRenameSmf_HandleApply:
	ld	xwa, 34772
	ld	xbc, (xsp+4)
	call	16288975
	ld	xwa, 34772
	ld	xbc, 15337168
	call	16289030
	ld	xwa, 6291494
	ld	xbc, 29360129
	lds32	xde, 5
	call	16423243
	lds	wa, 0
	calr	61978
	ld	xwa, 34772
	call	16287533
	ld	wa, hl
	lds	bc, 5
	calr	62612
	ld	(32422:16), l
	calr	62047
	call	16291947
	stda16	(33896), hl
	ld	xwa, 6291494
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	ldw	wa, 238
	call	16355504
FRenameSmf_Return:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret
FmmFormatFunc:
	pushw	iz
	cp	xbc, 29360135
	jrl	z, 142
	cp	xbc, 29360147
	jrl	nz, 465
	cp	xde, 3
	jr	z, 109
	cp	xde, 2
	jrl	nz, 448
	lds	wa, 1
	calr	-3659
	.byte 0xc1, 0x9b, 0x8c, 0x19, 0xce, 0x7e
	cpdi16	33892, 0
	jr	ge, 13
	call	16290067
	extz	hl
	stda16	33892, hl
	calr	-3594
FmmFmt_InitPhase_CheckDrive:
	ld	wa, (33892:16)
	cps	wa, 2
	jr	z, 4
	cps	wa, 3
	jr	nz, 27
FmmFmt_InitPhase_DriveType23:
	ld	(32460:16), a
	ld	xwa, 8060982
	ld	xbc, 29360129
	lds32	xde, 0
	call	16423243
	stdi8	(33890), 0
	jr	21
FmmFmt_InitPhase_OtherDrive:
	ld	xwa, 8060991
	ld	xbc, 29360129
	lds32	xde, 0
	call	16423243
	stdi8	(33890), 2
FmmFmt_InitPhase_SetActive:
	stdi8	(32464), 1
	jrl	348
FmmFmt_HandleCancel:
	calr	61843
	stdi8	(33890), 0
	stdi8	(32464), 0
	jrl	332
FmmFmt_HandleProgress:
	cpdi8	32464, 0
	jrl	z, 324
	ld	a, (32462:16)
	extz	wa
	cp	xde, 15
	jrl	z, 295
	ld	c, (33890:16)
	cp	xde, 11
	jrl	z, 222
	cp	xde, 10
	jrl	nz, 287
	ld	a, c
	cps	c, 0
	jrl	nz, 167
	ld	xwa, 6291494
	ld	xbc, 29360129
	lds32	xde, 5
	call	16423243
	lds	wa, 0
	calr	-3843
	ld	a, (32460:16)
	extz	wa
	call	16288900
	ld	iz, hl
	calr	-3766
	calr	-3965
	ld	xwa, 6291494
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	cps	iz, 0
	jr	ge, 69
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 1
	call	16423243
	ld	a, (32462:16)
	extz	wa
	call	16355459
	stdi8	32464, 0
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 0
	call	16423243
	ld	wa, iz
	ldw	bc, 8
	calr	-3286
	ld	(32422:16), l
	ldw	wa, 238
	call	16355504
	jrl	147
FmmFmt_FormatSuccess:
	ld	xwa, 8060982
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	ld	xwa, 8060977
	ld	xbc, 29360129
	lds32	xde, 0
	call	16423243
	stdi8	(33890), 1
	jr	113
FmmFmt_ExecutePhase2:
	cps	a, 2
	jr	nz, 109
	stdi8	(32460), 3
	ld	xwa, 8060991
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	ld	xwa, 8060982
	ld	xbc, 29360129
	lds32	xde, 0
	jr	54
FmmFmt_HandleAbort:
	ld	e, c
	cps	c, 0
	jr	nz, 11
	call	16355459
	stdi8	(32464), 0
	jr	57
FmmFmt_AbortPhase2:
	cps	e, 2
	jr	nz, 53
	stdi8	(32460), 2
	ld	xwa, 8060991
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	ld	xwa, 8060982
	ld	xbc, 29360129
	lds32	xde, 0
FmmFmt_DispatchAndNotify:
	call ApPostEvent
	jr FmmFmt_NotifyComplete

FmmFmt_HandleAbortFinal:
	call	16355459
	stdi8	(32464), 0
FmmFmt_NotifyComplete:
	stdi8	(33890), 0
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
	pushw	iz
	cp	xbc, 29360135
	jrl	z, 521
	cp	xbc, 29360147
	jrl	nz, 539
	cp	xde, 3
	jrl	z, 482
	cp	xde, 9
	jrl	z, 439
	cp	xde, 2
	jrl	nz, 512
	stdi8	33890, 0
	.byte 0xd1, 0x64, 0x84, 0x19, 0xd4, 0x7e
	lds	wa, 1
	calr	-4188
	ld	xwa, 6291494
	ld	xbc, 29360129
	lds32	xde, 5
	call	16423243
	.byte 0xc1, 0x9b, 0x8c, 0x19, 0xd2, 0x7e
	cpdi16	33892, 0
	jr	ge, 13
	call	16290067
	extz	hl
	stda16	33892, hl
	calr	-4139
FmmLoadTtl_StateDispatch:
	ld	wa, (33892:16)
	cps	wa, 1
	jrl	z, 193
	cps	wa, 0
	jrl	z, 166
	cps	wa, 5
	jr	z, 94
	cpdi16	33894, 0
	jr	ge, 19
	call	16290928
	stda16	33894, hl
	call	16290176
	call	16290094
	calr	-4184
FmmLoadTtl_CheckFileHandle:
	cpdi16	33894, 0
	jrl	nz, 224
	cpdi16	33896, 0
	jr	ge, 11
	call	16291947
	stda16	33896, hl
	calr	-4212
FmmLoadTtl_CheckSmfHandle:
	.byte 0xd1, 0x68, 0x84, 0x3f, 0x00, 0x00	; cpdi16 0x8504, 0 (v7 patched)

	.byte 0x72, 0xc4, 0x00	; jrl le, FmmLoadTtl_LoadSlots (v7 displacement)

	.byte 0xc1, 0xd2, 0x7e, 0x3f, 0x64	; cpdi8 (0x7f6e), 100 (v7 patched)

	.byte 0x76, 0xbc, 0x00	; jrl z, FmmLoadTtl_LoadSlots (v7 displacement)

	ld xwa, 0x600026

	ld xbc, 0x1c00002

	lds32 xde, 0

	call	16423243

	ldw wa, 0x64

	jrl	337



FmmLoadTtl_StateCancelLoad:
	ld	xwa, 6291494
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 1
	call	16423243
	ld	a, (32466:16)
	extz	wa
	call	16355459
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 0
	call	16423243
	stdi8	(32422), 0
	ldw	wa, 238
	jr	91
FmmLoadTtl_StateIdle:
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0x7d
	jrl FmmLoadTtl_PlaySound

FmmLoadTtl_StateSuccess:
	ld	xwa, 6291494
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	calr	60980
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 1
	call	16423243
	ld	a, (32466:16)
	extz	wa
	call	16355459
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 0
	call	16423243
	stdi8	(32422), 2
	ldw	wa, 238
FmmLoadTtl_NotifyComplete:
	call SoundCtrl_SendCommand
	jrl FmmLoadTtl_Return

FmmLoadTtl_LoadSlots:
	ld	xwa, 6291494
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	ld	xwa, 4294967295
	ld	xbc, 29360138
	lds32	xde, 0
	call	16423243
	stdi8	(35168), 0
	stdi8	(35170), 0
	stdi8	(35172), 0
	stdi8	(35174), 0
	stdi8	(35176), 0
	stdi8	(35178), 0
	stdi8	(35180), 0
	lds	iz, 0
FmmLoadTtl_SlotLoop:
	stb_erp	a, 248
	extz	wa
	call	FileIO_FormatName_Loop
	inc	1, iz
	cp	iz, 8
	jr	lt, -17	; -> 0xF8BFD9
	stdi8	(35164), 4
	jr	82	; -> 0xF8C043
FmmLoadTtl_HandleScrollNav:
	.byte 0xd1, 0xd4, 0x7e, 0x3f, 0x00, 0x00, 0x61, 0x4a
	.byte 0x1d, 0xe2, 0x91, 0xf8, 0xdb, 0x8e, 0xde, 0xd8
	.byte 0x61, 0x40, 0xde, 0xcf, 0x13, 0x00, 0x69, 0x3a
	.byte 0xde, 0x88, 0xd8, 0x61, 0x1d, 0xf8, 0x91, 0xf8
	.byte 0x68, 0x30
FmmLoadTtl_HandleCancelOp:
	calr CancelOperationCleanup
	ld xwa, 0x610001
	ld xbc, 0x1e0007f
	lds32 xde, 1
	call ApPostEvent
	jr FmmLoadTtl_Return

FmmLoadTtl_HandleOk:
	cp	xde, 15
	jr	nz, 19
	cpdi8	35992, 7
	jr	nz, 5
	ldw	wa, 214
	jr	3
FmmLoadTtl_Ok_DefaultSound:
	ldw wa, 0x60

FmmLoadTtl_PlaySound:
	call UI_PostModeChangeEvent

FmmLoadTtl_Return:
	lds32 xhl, 0
	popw iz
	ret
FmmSaveTitleFunc:
	pushw	iz
	cp	xbc, 29360135
	jrl	z, 183
	cp	xbc, 29360147
	jrl	nz, 189
	cp	xde, 3
	jrl	z, 144
	cp	xde, 2
	jrl	nz, 171
	stdi8	33890, 0
	lds	wa, 1
	calr	-4735
	ld	xwa, 6291494
	ld	xbc, 29360129
	lds32	xde, 5
	call	16423243
	cpdi16	33894, 0
	jr	ge, 19
	call	16290928
	stda16	33894, hl
	call	16290176
	call	16290094
	calr	-4686
FmmSaveTtl_CheckFont:
	cpdi8	35995, 102
	jr	z, 45
	lds	iz, 0
FmmSaveTtl_SlotLoop:
	stb_erp	a, 248
	extz	wa
	call	16289650
	inc	1, iz
	cps	iz, 6
	jr	lt, -15
	lds	wa, 6
	call	16289670
	lds	wa, 7
	call	16289670
	call	16289725
	ld	xiy, 15337066
	ld	xix, 35184
	.byte 0x95, 0x10
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
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	cp	xbc, 31457414
	jrl	z, 171
	cp	xbc, 31457338
	jr	z, 45
	cp	xbc, 29360139
	jrl	nz, 193
	lds	wa, 0
	calr	60599
	lda	xiz, (34544:16)
	call	16290176
	ld	xbc, xhl
	ld	xwa, xiz
	call	16288975
	ld	xwa, (xsp+4)
	ld	xbc, 29360143
	ld	xde, 34544
	jr	112
DiskName_TextChange:
	lds	wa, 0
	calr	60563
	lda	xiz, (34544:16)
	call	16290176
	ld	xbc, xhl
	ld	xwa, xiz
	call	16288975
	lds	iy, 0
	lda	xix, (34772:16)
	lda	xiz, (15652728:24)
	lda	xde, (34544:16)
	ld	xhl, xde
	jr	22
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
	lda_dri XBC, 0x07, 0xec, 0xf4
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
	ld	xwa, 34544
	ld	xbc, (xsp+4)
	call	16288975
	lds	wa, 0
	calr	60433
	ld	xwa, 34544
	call	16065688
	calr	60513
	calr	60314
	ldw	wa, 96
	call	16355459
DiskName_Return:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret

DiskInfoFunc:
	lda xsp, (xsp - 0x10)
	push XIZ
	ld (XSP+0x10),XDE
	cp XBC,0x01c0000b
	jrl nz, DiskInfo_Return
	lds wa, 0
	calr InitializeOperationState
	cpdi16 (0x8464), 0x0000
	jr ge, DiskInfo_ReadDriveType
	call GetDiskSizeInfo
	extz HL
	stda16 (0x8464), hl
DiskInfo_ReadDriveType:
	ld	wa, (33892:16)
	cps	wa, 1
	jr	z, 28
	cps	wa, 0
	jr	z, 24
	cps	wa, 2
	jr	z, 4
	cps	wa, 3
	jr	nz, 19
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
	.byte 0xaf, 0x0c, 0x20, 0xe8, 0xcf, 0x00, 0x00, 0x00
	.byte 0x00, 0x62, 0x1f, 0xaf, 0x0c, 0x20, 0xaf, 0x04
	.byte 0xa0, 0x41, 0x64, 0x00, 0x00, 0x00, 0x1d, 0x7f
	.byte 0x02, 0xff, 0xeb, 0x8e, 0xaf, 0x0c, 0x21, 0xee
	.byte 0x88, 0x1d, 0x31, 0x04, 0xff, 0xbf, 0x08, 0x63
	.byte 0x68, 0x05
DiskInfo_ZeroPercent:
	lds32 xwa, 0
	ld (xsp + 8), xwa
DiskInfo_RenderStrings:
	ld	xwa, (xsp+4)
	ld	xbc, xwa
	sra	xbc, 15
	sra	xbc, 0
	and	xbc, 1023
	add	xbc, xwa
	ld	(xsp+4), xbc
	sra	xbc, 10
	ld	(xsp+4), xbc
	ld	wa, (33892:16)
	sla	wa, 2
	lda	xbc, (15336792:24)
	ld_rrl	xbc, xbc, wa
	ld	xwa, 34610
	call	16288975
	ld	xwa, 34610
	ld	xbc, 15337174
	call	16289030
	lda	xwa, (34610:16)
	ld	(xsp+12), xwa
	ld	xwa, (xsp+4)
	lds	bc, 4
	calr	-4200
	ld	xbc, xhl
	ld	xwa, (xsp+12)
	call	16289030
	ld	xwa, 34610
	ld	xbc, 15337178
	call	16289030
	lda	xwa, (34610:16)
	ld	(xsp+12), xwa
	ld	xwa, (xsp+8)
	lds	bc, 3
	calr	-4238
	ld	xbc, xhl
	ld	xwa, (xsp+12)
	call	16289030
	ld	xwa, 34610
	ld	xbc, 15337188
	call	16289030
	ld	xwa, (xsp+16)
	ld	xbc, 29360143
	ld	xde, 34610
	call	16423243
DiskInfo_Return:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 16)
	ret

SongNameFunc:
	dec	8, xsp
	pushw	iz
	ld	(xsp+6), xde
	cp	xbc, 29360139
	jr	nz, 99
	call	16291514
	ld	iz, hl
	cps	iz, 0
	jr	lt, 67
	lds	wa, 0
	calr	60075
	lda	xwa, (34674:16)
	ld	(xsp+2), xwa
	ld	wa, iz
	call	16292978
	ld	xbc, xhl
	ld	xwa, (xsp+2)
	call	16288975
	lda	xwa, (34674:16)
	ld	(xwa+30), 0
	lda	xbc, (xwa+29)
	ld	xde, xbc
	lda	xhl, (xbc-29)
	jr	5
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
	stdi8	(34674), 0
SongName_SendDisplay:
	ld	xwa, (xsp+6)
	ld	xbc, 29360143
	ld	xde, 34674
	call	16423243
SongName_Return:
	lds32 xhl, 0
	popw iz
	inc 8, xsp
	ret

SaveFileNameNumFunc:
	dec	4, xsp
	pushw	iz
	ld	(xsp+2), xde
	cp	xbc, 29360139
	jr	nz, 59
	call	16290274
	ld	iz, hl
	cps	iz, 0
	jr	lt, 27
	call	16289455
	ld	xbc, xhl
	ld	de, iz
	inc	1, de
	pushw	6
	pushw	0
	ld	xwa, 34740
	call	16289232
	jr	5
SaveFileNum_NoSlot:
	stdi8	(34740), 0
SaveFileNum_SendDisplay:
	ld	xwa, (xsp+2)
	ld	xbc, 29360143
	ld	xde, 34740
	call	16423243
SaveFileNum_Return:
	lds32 xhl, 0
	popw iz
	inc 4, xsp
	ret

SaveFileNameFunc:
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	cp	xbc, 31457414
	jrl	z, 156
	cp	xbc, 31457338
	jr	z, 49
	cp	xbc, 29360139
	jrl	nz, 160
	lda	xiz, (34740:16)
	call	16289455
	ld	xbc, xhl
	ld	xwa, xiz
	call	16288975
	ld	xwa, 34740
	call	16289424
	ld	xwa, (xsp+4)
	ld	xbc, 29360143
	ld	xde, 34740
	jr	93
SaveFileName_TextChange:
	lda	xiz, (34740:16)
	call	16289455
	ld	xbc, xhl
	ld	xwa, xiz
	call	16288975
	lds	iy, 0
	lda	xix, (15652728:24)
	lda	xde, (34740:16)
	ld	xhl, xde
	jr	17
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
	lda_dri XBC, 0x07, 0xec, 0xf4
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
	ld	xwa, 34740
	ld	xbc, (xsp+4)
	call	16288975
	ld	xwa, 34740
	call	16289461
SaveFileName_Return:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret

CurFileNameFunc:
	dec	4, xsp
	pushw	iz
	ld	(xsp+2), xde
	cp	xbc, 29360139
	jr	nz, 61
	call	16290274
	ld	iz, hl
	cps	iz, 0
	jr	lt, 29
	ld	wa, iz
	call	16290326
	ld	xbc, xhl
	ld	de, iz
	inc	1, de
	pushw	6
	pushw	0
	ld	xwa, 34772
	call	16289232
	jr	5
CurFileName_NoSlot:
	stdi8	(34772), 0
CurFileName_SendDisplay:
	ld	xwa, (xsp+2)
	ld	xbc, 29360143
	ld	xde, 34772
	call	16423243
CurFileName_Return:
	lds32 xhl, 0
	popw iz
	inc 4, xsp
	ret

