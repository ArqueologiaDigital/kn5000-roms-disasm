FmmSmfLoadTitleFunc:
	cp	xbc, 29360135
	jrl	z, SmfLoad_HandleOk
	cp	xbc, 29360147
	jrl	nz, SmfLoad_Return
	cp	xde, 3
	jrl	z, SmfLoad_CancelCleanup
	cp	xde, 2
	jrl	nz, SmfLoad_Return
	ld	(33890:16), 0
	ld	wa, 1:i3
	calr	InitializeOperationState
	ld	xwa, 6291494
	ld	xbc, 29360129
	ld	xde, 5:i3
	call	ApPostEvent
	.byte 0xc1, 0x9b, 0x8c, 0x19, 0xee, 0x7f
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
	.byte 0xd1, 0x66, 0x84, 0x3f, 0x00, 0x00	; cpdi16 0x8502, 0 (v7 patched)

	.byte 0x72, 0xc3, 0x00	; jrl le, SmfLoad_SendWait (v7 displacement)

	.byte 0xc1, 0xee, 0x7f, 0x3f, 0x61	; cpdi8 (0x808a), 97 (v7 patched)

	.byte 0x76, 0xbb, 0x00	; jrl z, SmfLoad_SendWait (v7 displacement)

	ld xwa, 0x600026

	ld xbc, 0x1c00002

	ld xde, 0:i3

	call	ApPostEvent

	ldw wa, 0x61

	jrl	SmfLoad_CallHandler



SmfLoad_AbortPartial:
	ld	xwa, 6291494
	ld	xbc, 29360130
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, 4294967295
	ld	xbc, 31457438
	ld	xde, 1:i3
	call	ApPostEvent
	ld	a, (32750:16)
	extz	wa
	call	UI_PostModeChangeEvent
	ld	xwa, 4294967295
	ld	xbc, 31457438
	ld	xde, 0:i3
	call	ApPostEvent
	ld	(32422:16), 0
	ldw	wa, 238
	jr	SmfLoad_CallStatusDisplay
SmfLoad_ErrorCancel:
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	ld xde, 0:i3
	call ApPostEvent
	ldw wa, 0x7d
	jrl SmfLoad_CallHandler

SmfLoad_Success:
	calr	ResetProgressIndication
	ld	xwa, 6291494
	ld	xbc, 29360130
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, 4294967295
	ld	xbc, 31457438
	ld	xde, 1:i3
	call	ApPostEvent
	ld	a, (32750:16)
	extz	wa
	call	UI_PostModeChangeEvent
	ld	xwa, 4294967295
	ld	xbc, 31457438
	ld	xde, 0:i3
	call	ApPostEvent
	ld	(32422:16), 2
	ldw	wa, 238
SmfLoad_CallStatusDisplay:
	call SoundCtrl_SendCommand
	jr SmfLoad_Return

SmfLoad_SendWait:
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	ld xde, 0:i3
	call ApPostEvent
	jr SmfLoad_Return

SmfLoad_CancelCleanup:
	calr CancelOperationCleanup
	jr SmfLoad_Return

SmfLoad_HandleOk:
	cp	xde, 15
	jr	nz, SmfLoad_Return
	cp	(35992:16), 7
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
	cp	xbc, 29360147
	jr	nz, SmfSave_Return
	cp	xde, 3
	jr	z, SmfSave_CancelCleanup
	cp	xde, 2
	jr	nz, SmfSave_Return
	ld	(33890:16), 0
	ld	wa, 1:i3
	calr	InitializeOperationState
	ld	xwa, 6291494
	ld	xbc, 29360129
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
	ld xbc, 0x1c00002
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
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
	stib_ind 0x07, 0xe0, 0xe4, 0x00
	ld ix, 0:i3
	lda xhl, (CharMap_FullPermutation_0x660:24)
	jr RenderSmf_LoopCheck

RenderSmf_CheckSeparator:
	extz bc
	ldb_sri C, 0x07, 0xec, 0xe4
	and c, 0x7
	jr nz, RenderSmf_IncIndex
	ld (xde), 0x5f

RenderSmf_IncIndex:
	inc 1, ix

RenderSmf_LoopCheck:
	cp ix, 0x8
	jr ge, RenderSmf_PadCheck
	lda_dri XDE, 0x07, 0xe0, 0xf0
	ld c, (xde)
	cp c, 0:i3
	jr nz, RenderSmf_CheckSeparator

RenderSmf_PadCheck:
	cp ix, 0x8
	ret ge

RenderSmf_PadLoop:
	stib_ind 0x07, 0xe0, 0xf0, 0x5f
	inc 1, ix
	cp ix, 0x8
	jr lt, RenderSmf_PadLoop
	ret

SaveFileNameSmfFunc:
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	lda	xwa, (34740:16)
	cp	xbc, 31457414
	jr	z, SaveFN_HandleApply
	cp	xbc, 31457338
	jr	z, SaveFN_HandleTextChange
	cp	xbc, 29360139
	jr	z, SaveFN_HandleActivate
	cp	xbc, 31784964
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
	ld	xbc, 29360143
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
	ld	xbc, 31457414
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
	ld	xbc, 15337270
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
	cp	xbc, 29360139
	jr	z, SeqToSong_BuildEntry
	cp	xbc, 31784964
	jr	nz, SeqToSong_Return
	ld	(32756:16), xde
	jr	SeqToSong_Return
SeqToSong_BuildEntry:
	lda	xwa, (32760:16)
	stib_dsp	224, 0
	ld	xbc, 15337276
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
	ld	xbc, 29360143
	ld	xde, 32760
	call	ApPostEvent
SeqToSong_Return:
	ld xhl, 0:i3
	pop xiz
	ret

SmfSeqFromSongNumFunc:
	push	xiz
	cp	xbc, 29360139
	jr	z, SeqFromSong_BuildEntry
	cp	xbc, 31784964
	jr	nz, SeqFromSong_Return
	ld	(32888:16), xde
	jr	SeqFromSong_Return
SeqFromSong_BuildEntry:
	lda	xwa, (32892:16)
	stib_dsp	224, 0
	ld	xbc, 15337288
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
	ld	xbc, 29360143
	ld	xde, 32892
	call	ApPostEvent
SeqFromSong_Return:
	ld xhl, 0:i3
	pop xiz
	ret

SmfSeqSongNameFunc:
	cp	xbc, 29360139
	jr	z, SeqSongName_BuildEntry
	cp	xbc, 31784964
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
	ld	xbc, 29360143
	call	ApPostEvent
SeqSongName_Return:
	ld xhl, 0:i3
	ret

SmfLoadAsFunc:
	cp	xbc, 29360139
	jr	z, SmfLoadAs_Apply
	cp	xbc, 31784964
	jr	nz, SmfLoadAs_Return
	ld	(33024:16), xde
	jr	SmfLoadAs_Return
SmfLoadAs_Apply:
	ld	a, (34986:16)
	extz	wa
	sla	wa, 2
	lda	xbc, (15337300:24)
	ld_rrl	xde, xbc, wa
	ld	xwa, (33024:16)
	ld	xbc, 29360143
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
	stib_dsp 0xe0, 0x20
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
	stb_erp	a, 248
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
	.byte 0x0b, 0x0c, 0x00, 0x0b, 0x01, 0x00
	call	FileIO_ReadHeader_ParseLoop
	ld	de, iz
	sll	de, 5
	lda	xbc, (33904:16)
	extz	xde
	add	xde, xbc
	ld	xwa, (xsp+4)
	ld	xbc, 29360143
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
	ldb_sri E, 0x07, 0xe0, 0xf4
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
	cp	xbc, 29360152
	jrl	z, SmfFN_NavSetup
	cp	xbc, 29360151
	jrl	z, SmfFN_NavSetup
	cp	xbc, 29360139
	jrl	z, SmfFN_HandleActivate
	ld	xbc, xiz
	sub	xde, 31784962
	cp	xde, 0
	jrl	lt, SmfFN_ReturnZero
	cp	xde, 5
	jr	gt, SmfFN_ReturnZero
	add	xde, xde
	add	xde, 15337374
	ld	de, (xde)
	lda	xix, (16309435:24)
SmfFN_JumpTable:
	jp_rr 8, xix, de
	ld	(33028:16), xbc
	ld	xwa, 0:i3
	ld	(33032:16), xwa
	ld	(33036:16), xwa
	cp	(35994:16), 107
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
	ld	xbc, 31784962
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
	.byte 0x41, 0x01, 0x00, 0xc5, 0x01, 0xea, 0xa9, 0x1d
	.byte 0x4b, 0x99, 0xfa, 0xd1, 0x10, 0x81, 0x24, 0xbf
	.byte 0x04, 0x54, 0xee, 0xe6, 0x6e, 0x48, 0xc1, 0x62
	.byte 0x84, 0x3f, 0x00, 0x6e, 0x41, 0xaf, 0x1c, 0x20
	.byte 0xe8, 0xcf, 0x18, 0x00, 0xc0, 0x01, 0x6e, 0x24
	.byte 0xdc, 0x89, 0xd9, 0x61, 0xc1, 0x9a, 0x8c, 0x3f
	.byte 0x6b, 0x66, 0x09, 0xd1, 0x68, 0x84, 0xf1, 0x61
	.byte 0x0e, 0x78, 0xed, 0x05
SmfFN_NavDown_WrapCheck:
	ld	wa, (33896:16)
	inc	1, wa
	cp	bc, wa
	jrl	ge, SmfFN_UpdateDisplay
SmfFN_NavDown_Apply:
	inc 1, ix
	jrl SmfFN_StoreIndex

SmfFN_NavUp:
	cp xwa, 0x1c00017
	jrl nz, SmfFN_UpdateDisplay
	cp ix, 0:i3
	jrl le, SmfFN_UpdateDisplay
	dec 1, ix
	jr SmfFN_StoreIndex

SmfFN_PageUp:
	.byte 0xee, 0xcf, 0x01, 0x00, 0x00, 0x00, 0x6e, 0x14
	.byte 0xc1, 0x62, 0x84, 0x3f, 0x00, 0x6e, 0x0d, 0xdc
	.byte 0xcf, 0x0a, 0x00, 0x71, 0xb5, 0x05, 0xdc, 0xca
	.byte 0x0a, 0x00, 0x68, 0x63
SmfFN_PageDown:
	.byte 0xee, 0xcf, 0x02, 0x00, 0x00, 0x00, 0x7e, 0x85
	.byte 0x00, 0xc1, 0x62, 0x84, 0x3f, 0x00, 0x6e, 0x7e
	.byte 0xdc, 0x8d, 0xdd, 0xc8, 0x0a, 0x00, 0xd1, 0x68
	.byte 0x84, 0x21, 0xdc, 0x8a, 0xea, 0x13, 0xda, 0x0b
	.byte 0x0a, 0x00, 0xc1, 0x9a, 0x8c, 0x3f, 0x6b, 0x66
	.byte 0x2e, 0xd9, 0x8b, 0xd9, 0xf5, 0x61, 0x30, 0xdb
	.byte 0x89, 0xd9, 0x69, 0xd9, 0x88, 0xe8, 0x13, 0xd8
	.byte 0x0b, 0x0a, 0x00, 0xd8, 0xf2, 0x79, 0x6f, 0x05
	.byte 0xeb, 0x13, 0xdb, 0x0b, 0x0a, 0x00, 0xd7, 0xee
	.byte 0x88, 0xd8, 0xd8, 0x76, 0x61, 0x05, 0xf1, 0x10
	.byte 0x81, 0x51, 0xd9, 0x8b, 0x78, 0x5c, 0x05
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
	ld	xbc, 29360129
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
	.byte 0x9f, 0x06, 0x3f, 0x00, 0x00
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
	lda	xwa, (700416:24)
	ld	xbc, 0:i3
	ld	c, (34988:16)
	sll	xbc, 11
	add	xwa, xbc
	.byte 0xf3, 0xe1, 0x00, 0x01, 0x30
	lda	xbc, (xsp+8)
	ldw	de, 16
	call	FileIO_CopyString_WriteNull
	ld	a, (65507:24)
	cp	a, (34988:16)
	jr	nz, SmfFN_Save_Finish
	lda	xwa, (61824:24)
	.byte 0xf3, 0xe1, 0x00, 0x01, 0x30
	lda	xbc, (xsp+8)
	ldw	de, 16
	call	FileIO_CopyString_WriteNull
SmfFN_Save_Finish:
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
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
	ld	(32422:16), l
	ld	xwa, 4294967295
	ld	xbc, 31457438
	ld	xde, 0:i3
	call	ApPostEvent
	ldw	wa, 238
	jrl	SmfFN_CallStatusDisplayAndExit
SmfFN_HandleOpen:
	cp xiz, 0x4
	jrl nz, SmfFN_HandleOpen2
	ld xwa, 0x600026
	ld xbc, 0x1c00001
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
	ld xbc, 0x1c00002
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c50000
	ld xde, 1:i3
	call ApPostEvent
	ld xwa, 0x600037
	ld xbc, 0x1c00001
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
	ld	(32422:16), l
	call	FileIO_ResetCurrentRecord
	call	GetEncodedFreeSpaceData
	call	GetFileCountEncoded
	ld	(33896:16), hl
	calr	SignalProgressUpdate
	ld	xwa, 6291494
	ld	xbc, 29360130
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, 4294967295
	ld	xbc, 31457438
	ld	xde, 1:i3
	call	ApPostEvent
	ld	wa, 1:i3
	call	UI_PostPartChangeEvent
	ld	xwa, 4294967295
	ld	xbc, 31457438
	ld	xde, 0:i3
	call	ApPostEvent
	ldw	wa, 238
	jrl	SmfFN_CallStatusDisplayAndExit
SmfFN_HandleOpen2:
	cp	xiz, 50
	jrl	nz, SmfFN_HandleDelete
	ld	xwa, 6291494
	ld	xbc, 29360129
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
	ld	(32422:16), l
	call	FileIO_ResetCurrentRecord
	call	GetEncodedFreeSpaceData
	call	GetFileCountEncoded
	ld	(33896:16), hl
	calr	SignalProgressUpdate
	ld	xwa, 6291494
	ld	xbc, 29360130
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, 4294967295
	ld	xbc, 31457438
	ld	xde, 1:i3
	call	ApPostEvent
	ld	wa, 1:i3
	call	UI_PostPartChangeEvent
	ld	xwa, 4294967295
	ld	xbc, 31457438
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
	ld xbc, 0x1c50000
	ld xde, 1:i3
	call ApPostEvent
	ld xwa, 0x7b0051
	ld xbc, 0x1c00001
	ld xde, 0:i3
	jrl SmfFN_DispatchEvent
SmfFN_Delete_Execute:
	ld	xwa, 6291494
	ld	xbc, 29360129
	ld	xde, 5:i3
	call	ApPostEvent
	ld	wa, 0:i3
	calr	InitializeOperationState
	call	GetFirstRecordAndOpen
	ld	wa, hl
	ld	bc, 5:i3
	calr	FileIO_ValidateSignedValue
	ld	(32422:16), l
	calr	SignalProgressUpdate
	call	FileIO_ResetCurrentRecord
	call	GetEncodedFreeSpaceData
	call	GetFileCountEncoded
	ld	(33896:16), hl
	ld	xwa, 6291494
	ld	xbc, 29360130
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
	ld XBC,0x01c00001
	ld xde, 5:i3
	call ApPostEvent
	ld wa, 0:i3
	calr InitializeOperationState
	call GetFirstRecordAndOpen
	ld WA,HL
	ld bc, 5:i3
	calr FileIO_ValidateSignedValue
	ld (0x7ea6:16), l
	calr SignalProgressUpdate
	call FileIO_ResetCurrentRecord
	call GetEncodedFreeSpaceData
	call GetFileCountEncoded
	ld (0x8468:16), hl
	ld XWA,0x00600026
	ld XBC,0x01c00002
	ld xde, 0:i3
	call ApPostEvent
	ld wa, (0x8110:16)
	.byte 0xd1, 0x68, 0x84, 0xf0, 0x61, 0x0d, 0xd8, 0xd8
	.byte 0x62, 0x09, 0xd8, 0x69, 0xf1, 0x10, 0x81, 0x50
	.byte 0xbf, 0x04, 0x50
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
	cp	(33890:16), 0
	jr	nz, SmfFN_HandleScrollFlag1
	ld	xwa, (xsp+28)
	cp	xwa, 29360151
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
	ld	xbc, 29360139
	ld	xde, 0:i3
	jr	SmfFN_LoadAs_Apply
SmfFN_LoadAs_Wrap:
	ld	(34986:16), 0
	ld	xwa, (xsp+32)
	ld	xbc, 29360139
	ld	xde, 0:i3
SmfFN_LoadAs_Apply:
	calr SmfLoadAsFunc
	jrl SmfFN_UpdateDisplay

SmfFN_HandleScrollFlag2:
	cp	xiz, 22
	jr	nz, SmfFN_HandleScrollFlag3
	ld	xwa, (xsp+28)
	cp	xwa, 29360151
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
	cp	xwa, 29360151
	jr	nz, SmfFN_SetTransposeFlag0
	ld	(34992:16), 1
	jrl	SmfFN_UpdateDisplay
SmfFN_SetTransposeFlag0:
	ld	(34992:16), 0
	jrl	SmfFN_UpdateDisplay
SmfFN_HandleScrollFlag4:
	cp	xiz, 24
	jr	nz, SmfFN_HandleSeqSongNum
	cp	xwa, 29360151
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
	ld	xbc, 29360139
	ld	xde, 0:i3
	calr	SmfSeqToSongNumFunc
	ld	xwa, (xsp+32)
	ld	xbc, 29360139
	ld	xde, 0:i3
	jr	SmfFN_SeqSongName_Dispatch
SmfFN_SeqToSong_Wrap:
	ld	(34988:16), 0
	ld	xwa, (xsp+32)
	ld	xbc, 29360139
	ld	xde, 0:i3
	calr	SmfSeqToSongNumFunc
	ld	xwa, (xsp+32)
	ld	xbc, 29360139
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
	ld	xbc, 29360139
	ld	xde, 0:i3
	calr	SmfSeqFromSongNumFunc
	ld	xwa, (xsp+32)
	ld	xbc, 29360139
	ld	xde, 0:i3
	jr	SmfFN_SeqSongName_Dispatch
SmfFN_SeqFromSong_Wrap:
	ld	(34988:16), 0
	ld	xwa, (xsp+32)
	ld	xbc, 29360139
	ld	xde, 0:i3
	calr	SmfSeqFromSongNumFunc
	ld	xwa, (xsp+32)
	ld	xbc, 29360139
	ld	xde, 0:i3
SmfFN_SeqSongName_Dispatch:
	calr SmfSeqSongNameFunc
	jr SmfFN_UpdateDisplay

SmfFN_HandleMedleyConfirm:
	.byte 0xee, 0xcf, 0x28, 0x00, 0x00, 0x00, 0x6e, 0x1b
	.byte 0xd1, 0x12, 0x81, 0x3f, 0x00, 0x00, 0x66, 0x13
	.byte 0xe1, 0x08, 0x81, 0x20, 0xe8, 0xe0, 0x66, 0x0b
	.byte 0x41, 0x0a, 0x00, 0xc0, 0x01, 0xea, 0xa8
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
	ld	xbc, 31784962
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
	ld	xbc, 29360143
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
	ld	xbc, 29360143
	call	ApPostEvent
	jr	SmfFN_UpdateFilenameField
SmfFN_RedrawPage:
	muls	bc, 10
	calr	DisplaySmfFileList
	cp	(35994:16), 108
	jr	nz, SmfFN_UpdateFilenameField
	ld	xwa, (xsp+32)
	ld	xbc, 29360139
	ld	xde, 0:i3
	calr	FmmSmfMedleyFunc
SmfFN_UpdateFilenameField:
	cp	(35994:16), 107
	jr	nz, SmfFN_SendOkState
	lda	xiz, (34740:16)
	ld	wa, (33040:16)
	cp wa, (33896:16)
	jr	lt, SmfFN_FetchFilename
	cp	wa, 0:i3
	jr	le, SmfFN_FetchFilename
	ld	xwa, xiz
	ld	xbc, 15337360
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
	ld	xbc, 29360139
	ld	xde, 0:i3
	calr	SaveFileNameSmfFunc
SmfFN_SendOkState:
	ld xwa, (0x8104:16)
	ld XBC,0x01c50001
	ld xde, 0:i3
	jr t, SmfFN_DispatchFinalEvent
	ld (0x8108:16), xbc
	jrl t, SmfFN_ReturnZero
	ld (0x810c:16), xbc
	jrl t, SmfFN_ReturnZero
	ld (0x8112:16), iz
	jrl t, SmfFN_ReturnZero
	cp (0x8462:16), 0x00
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
	ld XBC,0x01e50002
SmfFN_DispatchFinalEvent:
	call	ApPostEvent
	jrl	SmfFN_ReturnZero
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
	stb_erp	a, 248
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
	ld	xbc, 29360143
	call	ApPostEvent
	inc	1, iz
	cp	iz, 10
	jr	lt, DispSeqList_LoopBody
	popw	iz
	inc	6, xsp
	ret	
