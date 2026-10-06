FmmSmfLoadTitleFunc:
	cp	xbc, EVT_SW_IN
	jrl	z, SmfLoad_HandleOk
	cp	xbc, EVT_ACTIVATE_STATE
	jrl	nz, SmfLoad_Return
	cp	xde, 3
	jrl	z, SmfLoad_CancelCleanup
	cp	xde, 2
	jrl	nz, SmfLoad_Return
	ld	(MEDLEY_PLAY_FLAG:16), 0
	ld	wa, 1:i3
	calr	InitializeOperationState
	ld	xwa, 6291494
	ld	xbc, EVT_SHOW
	ld	xde, 5:i3
	call	ApPostEvent
	ldmm8	0x7fee, PREVIOUS_TITLE
	cpw	(33892:16), 0
	jr	ge, SmfLoad_DispatchState
	call	GetDiskSizeInfo
	extz	hl
	ld	(33892:16), hl
	calr	SignalProgressUpdate
SmfLoad_DispatchState:
	ld	wa, (33892:16)
	cp	wa, 1:i3
	jrl	z, SmfLoad_Success
	cp	wa, 0:i3
	jrl	z, SmfLoad_ErrorCancel
	cp	wa, 5:i3
	jr	z, SmfLoad_AbortPartial
	cpw	(33896:16), 0
	jr	ge, SmfLoad_CheckFileCount
	call	GetFileCountEncoded
	ld	(33896:16), hl
	call	FileIO_SearchAndLoadFile
	call	GetEncodedFreeSpaceData
	calr	SignalProgressUpdate
SmfLoad_CheckFileCount:
	cpw	(33896:16), 0
	jrl	nz, SmfLoad_SendWait
	cpw	(33894:16), 0
	jr	ge, SmfLoad_CheckSlotCount
	call	GetEncodedFileSizeData
	ld	(33894:16), hl
	calr	SignalProgressUpdate
SmfLoad_CheckSlotCount:
; cpdi16 0x8502, 0 (v7 patched)
	cpw	(0x8466:16), 0
; jrl le, SmfLoad_SendWait (v7 displacement)
	jrl	le, SmfLoad_SendWait
; cpdi8 (0x808a), 97 (v7 patched)
	cp	(0x7fee:16), 97
; jrl z, SmfLoad_SendWait (v7 displacement)
	jrl	z, SmfLoad_SendWait

	ld xwa, 0x600026

	ld xbc, EVT_HIDE

	ld xde, 0:i3

	call	ApPostEvent

	ldw wa, 0x61

	jrl	SmfLoad_CallHandler



SmfLoad_AbortPartial:
	ld	xwa, 6291494
	ld	xbc, EVT_HIDE
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, 4294967295
	ld	xbc, EVT_SET_NOT_DRAW_FLAG
	ld	xde, 1:i3
	call	ApPostEvent
	ld	a, (32750:16)
	extz	wa
	call	UI_PostModeChangeEvent
	ld	xwa, 4294967295
	ld	xbc, EVT_SET_NOT_DRAW_FLAG
	ld	xde, 0:i3
	call	ApPostEvent
	ld	(GLOBAL_ERROR_CODE:16), 0
	ldw	wa, 238
	jr	SmfLoad_CallStatusDisplay
SmfLoad_ErrorCancel:
	ld xwa, 0x600026
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ldw wa, 0x7d
	jrl SmfLoad_CallHandler

SmfLoad_Success:
	calr	ResetProgressIndication
	ld	xwa, 6291494
	ld	xbc, EVT_HIDE
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, 4294967295
	ld	xbc, EVT_SET_NOT_DRAW_FLAG
	ld	xde, 1:i3
	call	ApPostEvent
	ld	a, (32750:16)
	extz	wa
	call	UI_PostModeChangeEvent
	ld	xwa, 4294967295
	ld	xbc, EVT_SET_NOT_DRAW_FLAG
	ld	xde, 0:i3
	call	ApPostEvent
	ld	(GLOBAL_ERROR_CODE:16), 2
	ldw	wa, 238
SmfLoad_CallStatusDisplay:
	call SoundCtrl_SendCommand
	jr SmfLoad_Return

SmfLoad_SendWait:
	ld xwa, 0x600026
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_ALL_PAINT
	ld xde, 0:i3
	call ApPostEvent
	jr SmfLoad_Return

SmfLoad_CancelCleanup:
	calr CancelOperationCleanup
	jr SmfLoad_Return

SmfLoad_HandleOk:
	cp	xde, 15
	jr	nz, SmfLoad_Return
	cp	(CURRENT_MODE:16), 7
	jr	nz, SmfLoad_OkReturnCode
	ldw	wa, 214
	jr	SmfLoad_CallHandler
SmfLoad_OkReturnCode:
	ldw wa, 0x60

SmfLoad_CallHandler:
	call UI_PostModeChangeEvent

SmfLoad_Return:
	ld xhl, 0:i3
	ret
FmmSmfSaveTitleFunc:
	cp	xbc, EVT_ACTIVATE_STATE
	jr	nz, SmfSave_Return
	cp	xde, 3
	jr	z, SmfSave_CancelCleanup
	cp	xde, 2
	jr	nz, SmfSave_Return
	ld	(MEDLEY_PLAY_FLAG:16), 0
	ld	wa, 1:i3
	calr	InitializeOperationState
	ld	xwa, 6291494
	ld	xbc, EVT_SHOW
	ld	xde, 5:i3
	call	ApPostEvent
	cpw	(33896:16), 0
	jr	ge, SmfSave_SendWait
	call	GetFileCountEncoded
	ld	(33896:16), hl
	call	FileIO_SearchAndLoadFile
	call	GetEncodedFreeSpaceData
	calr	SignalProgressUpdate
SmfSave_SendWait:
	ld xwa, 0x600026
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_ALL_PAINT
	ld xde, 0:i3
	call ApPostEvent
	jr SmfSave_Return

SmfSave_CancelCleanup:
	calr CancelOperationCleanup

SmfSave_Return:
	ld xhl, 0:i3
	ret

RenderSmfFilename:
	extz bc
	ld	(xwa+bc), 0x00
	ld ix, 0:i3
	lda xhl, (CType_ClassTable:24)
	jr RenderSmf_LoopCheck

RenderSmf_CheckSeparator:
	extz bc
	ld	c, (xhl+bc)
	and c, 0x7
	jr nz, RenderSmf_IncIndex
	ld (xde), 0x5f

RenderSmf_IncIndex:
	inc 1, ix

RenderSmf_LoopCheck:
	cp ix, 0x8
	jr ge, RenderSmf_PadCheck
	lda	xde, (xwa+ix)
	ld c, (xde)
	cp c, 0:i3
	jr nz, RenderSmf_CheckSeparator

RenderSmf_PadCheck:
	cp ix, 0x8
	ret ge

RenderSmf_PadLoop:
	ld	(xwa+ix), 0x5f
	inc 1, ix
	cp ix, 0x8
	jr lt, RenderSmf_PadLoop
	ret

SaveFileNameSmfFunc:
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	lda	xwa, (34740:16)
	cp	xbc, EVT_SET_STRING
	jr	z, SaveFN_HandleApply
	cp	xbc, EVT_GET_STRING
	jr	z, SaveFN_HandleTextChange
	cp	xbc, EVT_PAINT
	jr	z, SaveFN_HandleActivate
	cp	xbc, EVT_PS_FILE_NAME_BOX_ID
	jrl	nz, SaveFN_Return
	ld	xwa, (xsp+4)
	ld	(32752:16), xwa
	jrl	SaveFN_Return
SaveFN_HandleActivate:
	ld	(xwa), 0
	lda	xiz, (xwa+1)
	call	FileIO_GetRecordPtrAlt
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_CopyString
	lda	xwa, (34741:16)
	call	FileIO_GetRecordType_Extended
	ld	xwa, (32752:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 34740
	jr	SaveFN_SendEvent
SaveFN_HandleTextChange:
	ld	xiz, xwa
	call	FileIO_GetRecordPtrAlt
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_CopyString
	ld	xwa, 34740
	ldw	bc, 8
	calr	RenderSmfFilename
	ld	xwa, (xsp+4)
	ld	xbc, EVT_SET_STRING
	ld	xde, 34740
SaveFN_SendEvent:
	call ApPostEvent
	jr SaveFN_Return

SaveFN_HandleApply:
	ld	xbc, (xsp+4)
	ldw	de, 8
	call	FileIO_CopyString_WriteNull
	ld	xwa, 34740
	ldw	bc, 8
	calr	RenderSmfFilename
	ld	xwa, 34740
	ld	xbc, SaveFN_HandleApply_Str_MID
	call	FileIO_BuildFilePath
	ld	xwa, 34740
	call	FileIO_WriteRecordName
SaveFN_Return:
	ld xhl, 0:i3
	pop xiz
	inc 4, xsp
	ret

SmfSeqToSongNumFunc:
	push	xiz
	cp	xbc, EVT_PAINT
	jr	z, SeqToSong_BuildEntry
	cp	xbc, EVT_PS_FILE_NAME_BOX_ID
	jr	nz, SeqToSong_Return
	ld	(32756:16), xde
	jr	SeqToSong_Return
SeqToSong_BuildEntry:
	lda	xwa, (32760:16)
	ld	(xwa+), 0
	ld	xbc, SeqToSong_BuildEntry_Str_TO_SONG
	call	FileIO_CopyString
	lda	xiz, (32761:16)
	ld	a, (34988:16)
	inc	1, a
	extz	wa
	ld	bc, 2:i3
	calr	NumToAscii_FormatNumber
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_BuildFilePath
	ld	xwa, (32756:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 32760
	call	ApPostEvent
SeqToSong_Return:
	ld xhl, 0:i3
	pop xiz
	ret

SmfSeqFromSongNumFunc:
	push	xiz
	cp	xbc, EVT_PAINT
	jr	z, SeqFromSong_BuildEntry
	cp	xbc, EVT_PS_FILE_NAME_BOX_ID
	jr	nz, SeqFromSong_Return
	ld	(32888:16), xde
	jr	SeqFromSong_Return
SeqFromSong_BuildEntry:
	lda	xwa, (32892:16)
	ld	(xwa+), 0
	ld	xbc, SeqFromSong_BuildEntry_Str_FROM_SONG
	call	FileIO_CopyString
	lda	xiz, (32893:16)
	ld	a, (34988:16)
	inc	1, a
	extz	wa
	ld	bc, 2:i3
	calr	NumToAscii_FormatNumber
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_BuildFilePath
	ld	xwa, (32888:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 32892
	call	ApPostEvent
SeqFromSong_Return:
	ld xhl, 0:i3
	pop xiz
	ret

SmfSeqSongNameFunc:
	cp	xbc, EVT_PAINT
	jr	z, SeqSongName_BuildEntry
	cp	xbc, EVT_PS_FILE_NAME_BOX_ID
	jr	nz, SeqSongName_Return
	ld	(33020:16), xde
	jr	SeqSongName_Return
SeqSongName_BuildEntry:
	ld	a, (34988:16)
	extz	wa
	ld	bc, 0:i3
	ld	de, 0:i3
	calr	BuildSlotLabel
	ld	xde, xhl
	ld	xwa, (33020:16)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
SeqSongName_Return:
	ld xhl, 0:i3
	ret

SmfLoadAsFunc:
	cp	xbc, EVT_PAINT
	jr	z, SmfLoadAs_Apply
	cp	xbc, EVT_PS_FILE_NAME_BOX_ID
	jr	nz, SmfLoadAs_Return
	ld	(33024:16), xde
	jr	SmfLoadAs_Return
SmfLoadAs_Apply:
	ld	a, (34986:16)
	extz	wa
	sla	wa, 2
	lda	xbc, (SmfLoadAs_Apply_PtrTable:24)
	ld	xde, (xbc+wa)
	ld	xwa, (33024:16)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
SmfLoadAs_Return:
	ld xhl, 0:i3
	ret

TrimAndPadSmfFilename:
	ld ix, 0:i3
	ld xhl, xwa
	jr TrimPad_LoopCheck

TrimPad_LoopBody:
	cp e, 0x7e
	jr nz, TrimPad_CheckCtrl
	ld e, 0x5f:opc
	jr TrimPad_StoreChar

TrimPad_CheckCtrl:
	ld e, (xwa)
	cp e, 0x20
	jr nc, TrimPad_AdvancePointers
	ld e, 0x20:opc

TrimPad_StoreChar:
	ld (xwa), e

TrimPad_AdvancePointers:
	inc 1, ix
	inc 1, xwa
	inc 1, xhl

TrimPad_LoopCheck:
	cp ix, bc
	jr nc, TrimPad_PadCheck
	ld e, (xhl)
	cp e, 0:i3
	jr nz, TrimPad_LoopBody

TrimPad_PadCheck:
	cp ix, bc
	jr nc, TrimPad_NullTerminate

TrimPad_PadLoop:
	ld (xwa+), 0x20
	inc 1, ix
	cp ix, bc
	jr c, TrimPad_PadLoop

TrimPad_NullTerminate:
	ld (xwa), 0x0
	ret

DisplaySmfFileList:
	dec 6, xsp
	pushw iz
	ld (xsp + 2), bc
	ld (xsp + 4), xwa
	ld wa, 0:i3
	calr InitializeOperationState
	ld iz, 0:i3
DispFileList_LoopBody:
	ld	de, iz
	sll	de, 5
	lda	xbc, (33904:16)
	extz	xde
	add	xde, xbc
	ldto_berp	a, 248
	ld	(xde), a
	ld	wa, (xsp+2)
	add	wa, iz
	call	GetRecordPtrForFile
	ld	xbc, xhl
	ld	wa, iz
	sll	wa, 5
	ld	de, 1:i3
	add	de, wa
	lda	xhl, (33904:16)
	ld	wa, de
	extz	xwa
	add	xwa, xhl
	ld	de, (xsp+2)
	add	de, iz
	inc	1, de
	pushw	0xc
	pushw	0x1
	call	FileIO_ReadHeader_ParseLoop
	ld	de, iz
	sll	de, 5
	lda	xbc, (33904:16)
	extz	xde
	add	xde, xbc
	ld	xwa, (xsp+4)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	inc	1, iz
	cp	iz, 10
	jr	lt, DispFileList_LoopBody
	popw	iz
	inc	6, xsp
	ret
ValidateSmfFilename:
	ld iy, 0:i3
	ld hl, 0:i3
	jr ValidateFN_LoopHead

ValidateFN_CheckSpace:
	cp e, 0x20
	jr z, ValidateFN_AdvancePointer
	ld l, 0x0:opc
	ret

ValidateFN_AdvancePointer:
	inc 1, iy
	inc 1, hl

ValidateFN_LoopHead:
	ld	e, (xwa+iy)
	cp e, 0:i3
	jr z, ValidateFN_ReturnValid
	cp hl, bc
	jr c, ValidateFN_CheckSpace

ValidateFN_ReturnValid:
	ld l, 0x1:opc
	ret

FmmSmfFileNameFunc:
	lda xsp, (xsp - 0x20)
	push XIZ
	ld XIZ,XDE
	ld (XSP+0x1c),XBC
	ld (XSP+0x20),XWA
	ld XDE,(XSP+0x1c)
	ld	xwa, (33028:16)
	ld	xbc, (xsp+28)
	cp	xbc, EVT_INDEXSW_DOWN
	jrl	z, SmfFN_NavSetup
	cp	xbc, EVT_INDEXSW_UP
	jrl	z, SmfFN_NavSetup
	cp	xbc, EVT_PAINT
	jrl	z, SmfFN_HandleActivate
	ld	xbc, xiz
	sub	xde, EVT_SET_SELECTED_FILE_NUMBER
	cp	xde, 0
	jrl	lt, SmfFN_ReturnZero
	cp	xde, 5
	jr	gt, SmfFN_ReturnZero
	add	xde, xde
	add	xde, FmmSmfFileNameFunc_Data
	ld	de, (xde)
	lda	xix, (FmmSmfFileNameFunc_Code:24)
SmfFN_JumpTable:
	jp	t, (xix+de)
FmmSmfFileNameFunc_Code:
	ld	(33028:16), xbc
	ld	xwa, 0:i3
	ld	(33032:16), xwa
	ld	(33036:16), xwa
	cp	(CURRENT_TITLE:16), 107
	jr	z, FmmSmfFileNameFunc_Skip
	call	GetFirstPageBase
	ld	(33040:16), hl
	cp	hl, 0:i3
	jr	ge, FmmSmfFileNameFunc_Join
	ldw	(33040:16), 0
	jr	FmmSmfFileNameFunc_Join
FmmSmfFileNameFunc_Skip:
	ld	wa, (33896:16)
	ld	(33040:16), wa
	cp	wa, 0:i3
	jr	le, FmmSmfFileNameFunc_Skip2
	dec	1, wa
FmmSmfFileNameFunc_Skip2:
	call	NavigateToFileIndex
FmmSmfFileNameFunc_Join:
	ld	wa, (33040:16)
	exts	xwa
	divs	wa, 10
	ld	de, qwa
	exts	xde
	ld	xwa, (33028:16)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	jrl	SmfFN_DispatchFinalEvent
SmfFN_HandleActivate:
	ld	bc, (33040:16)
	exts	xbc
	divs	bc, 10
	muls	bc, 10
	calr	DisplaySmfFileList
SmfFN_ReturnZero:
	ld xhl, 0:i3
	jrl SmfFN_Return

SmfFN_NavSetup:
	ld	xbc, EVT_NOT_POST_AIC
	ld	xde, 1:i3
	call	ApPostEvent
	ld	ix, (0x8110:16)
	ld	(xsp + 4), ix
	or	xiz, xiz
	jr	nz, SmfFN_PageUp
	cp	(MEDLEY_PLAY_FLAG:16), 0
	jr	nz, SmfFN_PageUp
	ld	xwa, (xsp + 28)
	cp	xwa, EVT_INDEXSW_DOWN
	jr	nz, SmfFN_NavUp
	ld	bc, ix
	inc	1, bc
	cp	(CURRENT_TITLE:16), 107
	jr	z, SmfFN_NavDown_WrapCheck
	cp	bc, (0x8468:16)
	jr	lt, SmfFN_NavDown_Apply
	jrl	SmfFN_UpdateDisplay
SmfFN_NavDown_WrapCheck:
	ld	wa, (33896:16)
	inc	1, wa
	cp	bc, wa
	jrl	ge, SmfFN_UpdateDisplay
SmfFN_NavDown_Apply:
	inc 1, ix
	jrl SmfFN_StoreIndex

SmfFN_NavUp:
	cp xwa, EVT_INDEXSW_UP
	jrl nz, SmfFN_UpdateDisplay
	cp ix, 0:i3
	jrl le, SmfFN_UpdateDisplay
	dec 1, ix
	jr SmfFN_StoreIndex

SmfFN_PageUp:
	cp	xiz, 0x1
	jr	nz, SmfFN_PageDown
	cp	(MEDLEY_PLAY_FLAG:16), 0
	jr	nz, SmfFN_PageDown
	cp	ix, 0xa
	jrl	lt, SmfFN_UpdateDisplay
	sub	ix, 0xa
	jr	SmfFN_StoreIndex
SmfFN_PageDown:
	cp	xiz, 0x2
	jrl	nz, SmfFN_HandleSave
	cp	(MEDLEY_PLAY_FLAG:16), 0
	jr	nz, SmfFN_HandleSave
	ld	iy, ix
	add	iy, 0xa
	ld	bc, (0x8468:16)
	ld	de, ix
	exts	xde
	divs	de, 0xa
	cp	(CURRENT_TITLE:16), 107
	jr	z, SmfFN_PageDown_WrapCheck
	ld	hl, bc
	cp	iy, bc
	jr	lt, SmfFN_PageDown_Add10
	ld	bc, hl
	dec	1, bc
	ld	wa, bc
	exts	xwa
	divs	wa, 0xa
	cp	de, wa
	jrl	ge, SmfFN_UpdateDisplay
	exts	xhl
	divs	hl, 0xa
	ldto_werp	WA, 0xee
	cp	wa, 0:i3
	jrl	z, SmfFN_UpdateDisplay
	ld	(0x8110:16), bc
	ld	hl, bc
	jrl	SmfFN_RefreshIfChanged
SmfFN_PageDown_WrapCheck:
	ld hl, bc
	inc 1, bc
	cp iy, bc
	jr ge, SmfFN_PageDown_ClampCheck

SmfFN_PageDown_Add10:
	add ix, 0xa

SmfFN_StoreIndex:
	ld	(33040:16), ix
	ld	hl, ix
	jrl	SmfFN_RefreshIfChanged
SmfFN_PageDown_ClampCheck:
	ld	wa, hl
	exts	xwa
	divs	wa, 10
	cp	de, wa
	jrl	ge, SmfFN_UpdateDisplay
	exts	xbc
	divs	bc, 10
	ld	wa, qbc
	cp	wa, 0:i3
	jrl	z, SmfFN_UpdateDisplay
	ld	(33040:16), hl
	jrl	SmfFN_RefreshIfChanged
SmfFN_HandleSave:
	cp	xiz, 3
	jrl	nz, SmfFN_HandleOpen
	ld	xwa, 6291494
	ld	xbc, EVT_SHOW
	ld	xde, 5:i3
	call	ApPostEvent
	ld	wa, 0:i3
	calr	InitializeOperationState
	ld	a, (34988:16)
	extz	wa
	ld	c, (34986:16)
	extz	bc
	call	LoadFileSMF
	ld	(xsp+6), hl
	calr	SignalProgressUpdate
	cpw	(xsp + 6), 0x0
	jr	lt, SmfFN_Save_Finish
	ld	wa, (33040:16)
	call	GetFileEntryByIndex
	ld	xbc, xhl
	lda	xwa, (xsp+8)
	ldw	de, 16
	call	FileIO_CopyString_WriteNull
	lda	xwa, (xsp+8)
	ldw	bc, 16
	calr	ValidateSmfFilename
	cp	l, 0:i3
	jr	z, SmfFN_Save_WriteSlot
	ld	wa, (33040:16)
	call	GetRecordPtrForFile
	ld	xbc, xhl
	lda	xwa, (xsp+8)
	ldw	de, 8
	call	FileIO_CopyString_WriteNull
SmfFN_Save_WriteSlot:
	lda	xwa, (xsp+8)
	ldw	bc, 16
	calr	TrimAndPadSmfFilename
	lda	xwa, (SEQ_SONG_SLOTS:24)
	ld	xbc, 0:i3
	ld	c, (34988:16)
	sll	xbc, 11
	add	xwa, xbc
	lda	xwa, (xwa+256)
	lda	xbc, (xsp+8)
	ldw	de, 16
	call	FileIO_CopyString_WriteNull
	ld	a, (65507:24)
	cp	a, (34988:16)
	jr	nz, SmfFN_Save_Finish
	lda	xwa, (61824:24)
	lda	xwa, (xwa+256)
	lda	xbc, (xsp+8)
	ldw	de, 16
	call	FileIO_CopyString_WriteNull
SmfFN_Save_Finish:
	ld xwa, 0x600026
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 1:i3
	call ApPostEvent
	cpw (0xf19e:16), 0
	jr z, SmfFN_Save_NoAltSlot
	ldw wa, 0xa
	jr SmfFN_Save_CallResult

SmfFN_Save_NoAltSlot:
	ld wa, 1:i3

SmfFN_Save_CallResult:
	call	UI_PostPartChangeEvent
	ld	wa, (xsp+6)
	ld	bc, 1:i3
	calr	FileIO_ValidateSignedValue
	ld	(GLOBAL_ERROR_CODE:16), l
	ld	xwa, 4294967295
	ld	xbc, EVT_SET_NOT_DRAW_FLAG
	ld	xde, 0:i3
	call	ApPostEvent
	ldw	wa, 238
	jrl	SmfFN_CallStatusDisplayAndExit
SmfFN_HandleOpen:
	cp xiz, 0x4
	jrl nz, SmfFN_HandleOpen2
	ld xwa, 0x600026
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	call ApPostEvent
	call FileIO_GetRecordPtrAlt
	ld xwa, xhl
	call FileIO_CheckFileExists
	cp l, 0:i3
	jr z, SmfFN_Open_Execute
	cp (0x0340ea:24), 0x00
	jr z, SmfFN_Open_Execute
	ld xwa, 0x600026
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_NOT_PARA_DRAW
	ld xde, 1:i3
	call ApPostEvent
	ld xwa, 0x600037
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	jrl SmfFN_DispatchEvent

SmfFN_Open_Execute:
	ld	wa, 0:i3
	calr	InitializeOperationState
	ld	a, (34988:16)
	extz	wa
	ld	c, (34990:16)
	extz	bc
	ld	e, (34992:16)
	extz	de
	call	LoadFileVariant
	ld	wa, hl
	ld	bc, 5:i3
	calr	FileIO_ValidateSignedValue
	ld	(GLOBAL_ERROR_CODE:16), l
	call	FileIO_ResetCurrentRecord
	call	GetEncodedFreeSpaceData
	call	GetFileCountEncoded
	ld	(33896:16), hl
	calr	SignalProgressUpdate
	ld	xwa, 6291494
	ld	xbc, EVT_HIDE
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, 4294967295
	ld	xbc, EVT_SET_NOT_DRAW_FLAG
	ld	xde, 1:i3
	call	ApPostEvent
	ld	wa, 1:i3
	call	UI_PostPartChangeEvent
	ld	xwa, 4294967295
	ld	xbc, EVT_SET_NOT_DRAW_FLAG
	ld	xde, 0:i3
	call	ApPostEvent
	ldw	wa, 238
	jrl	SmfFN_CallStatusDisplayAndExit
SmfFN_HandleOpen2:
	cp	xiz, 50
	jrl	nz, SmfFN_HandleDelete
	ld	xwa, 6291494
	ld	xbc, EVT_SHOW
	ld	xde, 5:i3
	call	ApPostEvent
	ld	wa, 0:i3
	calr	InitializeOperationState
	ld	a, (34988:16)
	extz	wa
	ld	c, (34990:16)
	extz	bc
	ld	e, (34992:16)
	extz	de
	call	LoadFileVariant
	ld	wa, hl
	ld	bc, 5:i3
	calr	FileIO_ValidateSignedValue
	ld	(GLOBAL_ERROR_CODE:16), l
	call	FileIO_ResetCurrentRecord
	call	GetEncodedFreeSpaceData
	call	GetFileCountEncoded
	ld	(33896:16), hl
	calr	SignalProgressUpdate
	ld	xwa, 6291494
	ld	xbc, EVT_HIDE
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, 4294967295
	ld	xbc, EVT_SET_NOT_DRAW_FLAG
	ld	xde, 1:i3
	call	ApPostEvent
	ld	wa, 1:i3
	call	UI_PostPartChangeEvent
	ld	xwa, 4294967295
	ld	xbc, EVT_SET_NOT_DRAW_FLAG
	ld	xde, 0:i3
	call	ApPostEvent
	ldw	wa, 238
	jrl	SmfFN_CallStatusDisplayAndExit
SmfFN_HandleDelete:
	cp xiz, 0x5
	jrl nz, SmfFN_HandleDelete2
	cp (0x0340ea:24), 0x00
	jr z, SmfFN_Delete_Execute
	ld xwa, 0xffffffff
	ld xbc, EVT_NOT_PARA_DRAW
	ld xde, 1:i3
	call ApPostEvent
	ld xwa, 0x7b0051
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	jrl SmfFN_DispatchEvent
SmfFN_Delete_Execute:
	ld	xwa, 6291494
	ld	xbc, EVT_SHOW
	ld	xde, 5:i3
	call	ApPostEvent
	ld	wa, 0:i3
	calr	InitializeOperationState
	call	GetFirstRecordAndOpen
	ld	wa, hl
	ld	bc, 5:i3
	calr	FileIO_ValidateSignedValue
	ld	(GLOBAL_ERROR_CODE:16), l
	calr	SignalProgressUpdate
	call	FileIO_ResetCurrentRecord
	call	GetEncodedFreeSpaceData
	call	GetFileCountEncoded
	ld	(33896:16), hl
	ld	xwa, 6291494
	ld	xbc, EVT_HIDE
	ld	xde, 0:i3
	call	ApPostEvent
	ld	wa, (33040:16)
	cp wa, (33896:16)
	jr	lt, SmfFN_Delete_AdjustIndex
	cp	wa, 0:i3
	jr	le, SmfFN_Delete_AdjustIndex
	dec	1, wa
	ld	(33040:16), wa
	ld	(xsp+4), wa
SmfFN_Delete_AdjustIndex:
	ldw wa, 0xee
	jr SmfFN_CallStatusDisplayAndExit

SmfFN_HandleDelete2:
	cp XIZ,0x00000033
	jr nz, SmfFN_IgnoredEvents
	ld XWA,0x00600026
	ld XBC,EVT_SHOW
	ld xde, 5:i3
	call ApPostEvent
	ld wa, 0:i3
	calr InitializeOperationState
	call GetFirstRecordAndOpen
	ld WA,HL
	ld bc, 5:i3
	calr FileIO_ValidateSignedValue
	ld (GLOBAL_ERROR_CODE:16), l
	calr SignalProgressUpdate
	call FileIO_ResetCurrentRecord
	call GetEncodedFreeSpaceData
	call GetFileCountEncoded
	ld (0x8468:16), hl
	ld XWA,0x00600026
	ld XBC,EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ld wa, (0x8110:16)
	cp	wa, (0x8468:16)
	jr	lt, SmfFN_Delete2_AdjustIndex
	cp	wa, 0:i3
	jr	le, SmfFN_Delete2_AdjustIndex
	dec	1, wa
	ld	(0x8110:16), wa
	ld	(xsp + 4), wa
SmfFN_Delete2_AdjustIndex:
	ldw wa, 0xee

SmfFN_CallStatusDisplayAndExit:
	call SoundCtrl_SendCommand
	jrl SmfFN_UpdateDisplay
SmfFN_IgnoredEvents:
	cp	xiz, 10
	jrl	z, SmfFN_UpdateDisplay
	cp	xiz, 11
	jrl	z, SmfFN_UpdateDisplay
	cp	xiz, 12
	jrl	z, SmfFN_UpdateDisplay
	cp	xiz, 13
	jrl	z, SmfFN_UpdateDisplay
	cp	xiz, 20
	jr	nz, SmfFN_HandleScrollFlag1
	cp	(MEDLEY_PLAY_FLAG:16), 0
	jr	nz, SmfFN_HandleScrollFlag1
	ld	xwa, (xsp+28)
	cp	xwa, EVT_INDEXSW_UP
	jr	nz, SmfFN_SetScrollDir0
	ld	(34982:16), 1
	jrl	SmfFN_UpdateDisplay
SmfFN_SetScrollDir0:
	ld	(34982:16), 0
	jrl	SmfFN_UpdateDisplay
SmfFN_HandleScrollFlag1:
	cp	xiz, 21
	jr	nz, SmfFN_HandleScrollFlag2
	ld	c, (34986:16)
	ld	a, c
	inc	1, a
	cp	a, 3:i3
	jr	nc, SmfFN_LoadAs_Wrap
	inc	1, c
	ld	(34986:16), c
	ld	xwa, (xsp+32)
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	jr	SmfFN_LoadAs_Apply
SmfFN_LoadAs_Wrap:
	ld	(34986:16), 0
	ld	xwa, (xsp+32)
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
SmfFN_LoadAs_Apply:
	calr SmfLoadAsFunc
	jrl SmfFN_UpdateDisplay

SmfFN_HandleScrollFlag2:
	cp	xiz, 22
	jr	nz, SmfFN_HandleScrollFlag3
	ld	xwa, (xsp+28)
	cp	xwa, EVT_INDEXSW_UP
	jr	nz, SmfFN_SetTrackFlag0
	ld	(34990:16), 1
	jrl	SmfFN_UpdateDisplay
SmfFN_SetTrackFlag0:
	ld	(34990:16), 0
	jrl	SmfFN_UpdateDisplay
SmfFN_HandleScrollFlag3:
	ld	xwa, (xsp+28)
	cp	xiz, 23
	jr	nz, SmfFN_HandleScrollFlag4
	cp	xwa, EVT_INDEXSW_UP
	jr	nz, SmfFN_SetTransposeFlag0
	ld	(34992:16), 1
	jrl	SmfFN_UpdateDisplay
SmfFN_SetTransposeFlag0:
	ld	(34992:16), 0
	jrl	SmfFN_UpdateDisplay
SmfFN_HandleScrollFlag4:
	cp	xiz, 24
	jr	nz, SmfFN_HandleSeqSongNum
	cp	xwa, EVT_INDEXSW_UP
	jr	nz, SmfFN_SetFlag35140_0
	ld	(34984:16), 1
	jrl	SmfFN_UpdateDisplay
SmfFN_SetFlag35140_0:
	ld	(34984:16), 0
	jrl	SmfFN_UpdateDisplay
SmfFN_HandleSeqSongNum:
	ld	c, (34988:16)
	ld	a, c
	inc	1, a
	cp	xiz, 30
	jr	nz, SmfFN_HandleSeqFromSong
	cp	a, 10
	jr	nc, SmfFN_SeqToSong_Wrap
	inc	1, c
	ld	(34988:16), c
	ld	xwa, (xsp+32)
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	calr	SmfSeqToSongNumFunc
	ld	xwa, (xsp+32)
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	jr	SmfFN_SeqSongName_Dispatch
SmfFN_SeqToSong_Wrap:
	ld	(34988:16), 0
	ld	xwa, (xsp+32)
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	calr	SmfSeqToSongNumFunc
	ld	xwa, (xsp+32)
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	jr	SmfFN_SeqSongName_Dispatch
SmfFN_HandleSeqFromSong:
	cp	xiz, 31
	jr	nz, SmfFN_HandleMedleyConfirm
	cp	a, 10
	jr	nc, SmfFN_SeqFromSong_Wrap
	inc	1, c
	ld	(34988:16), c
	ld	xwa, (xsp+32)
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	calr	SmfSeqFromSongNumFunc
	ld	xwa, (xsp+32)
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	jr	SmfFN_SeqSongName_Dispatch
SmfFN_SeqFromSong_Wrap:
	ld	(34988:16), 0
	ld	xwa, (xsp+32)
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	calr	SmfSeqFromSongNumFunc
	ld	xwa, (xsp+32)
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
SmfFN_SeqSongName_Dispatch:
	calr SmfSeqSongNameFunc
	jr SmfFN_UpdateDisplay

SmfFN_HandleMedleyConfirm:
	cp	xiz, 0x28
	jr	nz, SmfFN_UpdateDisplay
	cpw	(0x8112:16), 0
	jr	z, SmfFN_UpdateDisplay
	ld	xwa, (0x8108:16)
	or	xwa, xwa
	jr	z, SmfFN_UpdateDisplay
	ld	xbc, EVT_ALL_PAINT
	ld	xde, 0:i3
SmfFN_DispatchEvent:
	call ApPostEvent

SmfFN_UpdateDisplay:
	ld	hl, (33040:16)
SmfFN_RefreshIfChanged:
	cp	(xsp+4), hl
	jrl	z, SmfFN_SendOkState
	ld	wa, hl
	call	NavigateToFileIndex
	ld	wa, (33040:16)
	exts	xwa
	divs	wa, 10
	ld	de, qwa
	exts	xde
	ld	xwa, (33028:16)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	call	ApPostEvent
	ld	bc, (33040:16)
	exts	xbc
	divs	bc, 10
	ld	de, (xsp+4)
	exts	xde
	divs	de, 10
	ld	xwa, (33028:16)
	cp	de, bc
	jr	nz, SmfFN_RedrawPage
	ld	bc, (xsp+4)
	exts	xbc
	divs	bc, 10
	ld	bc, qbc
	sll	bc, 5
	lda	xhl, (33904:16)
	ld	de, bc
	extz	xde
	add	xde, xhl
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	ld	wa, (33040:16)
	exts	xwa
	divs	wa, 10
	ld	wa, qwa
	sll	wa, 5
	lda	xbc, (33904:16)
	ld	de, wa
	extz	xde
	add	xde, xbc
	ld	xwa, (33028:16)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	jr	SmfFN_UpdateFilenameField
SmfFN_RedrawPage:
	muls	bc, 10
	calr	DisplaySmfFileList
	cp	(CURRENT_TITLE:16), 108
	jr	nz, SmfFN_UpdateFilenameField
	ld	xwa, (xsp+32)
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	calr	FmmSmfMedleyFunc
SmfFN_UpdateFilenameField:
	cp	(CURRENT_TITLE:16), 107
	jr	nz, SmfFN_SendOkState
	lda	xiz, (34740:16)
	ld	wa, (33040:16)
	cp wa, (33896:16)
	jr	lt, SmfFN_FetchFilename
	cp	wa, 0:i3
	jr	le, SmfFN_FetchFilename
	ld	xwa, xiz
	ld	xbc, SmfFN_UpdateFilenameField_Str_MID
	call	FileIO_CopyString
	jr	SmfFN_WriteFilenameField
SmfFN_FetchFilename:
	call	GetRecordPtrForFile
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_CopyString
	ld	xwa, 34740
	call	FileIO_GetRecordType_Extended
SmfFN_WriteFilenameField:
	ld	xwa, 34740
	call	FileIO_WriteRecordName
	ld	xwa, (xsp+32)
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	calr	SaveFileNameSmfFunc
SmfFN_SendOkState:
	ld xwa, (0x8104:16)
	ld XBC,EVT_NOT_POST_AIC
	ld xde, 0:i3
	jr t, SmfFN_DispatchFinalEvent
FmmSmfFileNameFunc_OnOnWindow:
	ld (0x8108:16), xbc
	jrl t, SmfFN_ReturnZero
FmmSmfFileNameFunc_OnOffWindow:
	ld (0x810c:16), xbc
	jrl t, SmfFN_ReturnZero
FmmSmfFileNameFunc_OnWhichWindow:
	ld (0x8112:16), iz
	jrl t, SmfFN_ReturnZero
FmmSmfFileNameFunc_OnSetSelectedFileNumber:
	cp (MEDLEY_PLAY_FLAG:16), 0x00
	jrl z, SmfFN_ReturnZero
	ld WA,IZ
	ld (0x8110:16), wa
	call NavigateToFileIndex
	ld wa, (0x8110:16)
	exts XWA
	divs WA,0x000a
	ld DE,QWA
	exts XDE
	ld xwa, (0x8104:16)
	ld XBC,EVT_SET_SELECTED_FILE_NUMBER
SmfFN_DispatchFinalEvent:
	call	ApPostEvent
	jrl	SmfFN_ReturnZero
FmmSmfFileNameFunc_OnGetSelectedFileNumber:
	ld	hl, (33040:16)
	exts	xhl
SmfFN_Return:
	pop xiz
	lda xsp, (xsp + 32)
	ret

DisplaySmfSequenceList:
	dec 6, xsp
	pushw iz
	ld (xsp + 2), bc
	ld (xsp + 4), xwa
	ld wa, 0:i3
	calr InitializeOperationState
	ld iz, 0:i3

DispSeqList_LoopBody:
	ld	de, iz
	sll	de, 5
	lda	xbc, (33904:16)
	extz	xde
	add	xde, xbc
	ldto_berp	a, 248
	ld	(xde), a
	ld	wa, (xsp+2)
	add	wa, iz
	call	FileIO_GetWallpaperEntry
	ld	xbc, xhl
	ld	wa, iz
	sll	wa, 5
	ld	de, 1:i3
	add	de, wa
	lda	xhl, (33904:16)
	ld	wa, de
	extz	xwa
	add	xwa, xhl
	ld	de, (xsp+2)
	add	de, iz
	inc	1, de
	pushw	12
	pushw	1
	call	FileIO_ReadHeader_ParseLoop
	ld	de, iz
	sll	de, 5
	lda	xbc, (33904:16)
	extz	xde
	add	xde, xbc
	ld	xwa, (xsp+4)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	inc	1, iz
	cp	iz, 10
	jr	lt, DispSeqList_LoopBody
	popw	iz
	inc	6, xsp
	ret	
