; =============================================================================
; file_io/smf_operations.asm - Standard MIDI File Operations
; =============================================================================
; SMF (Standard MIDI File) load, save, and naming routines.
;
; Key routines:
;   FmmSmfLoadTitleFunc              - SMF load title
;   FmmSmfSaveTitleFunc              - SMF save title
;   SaveFileNameSmfFunc              - SMF filename saving
;   SmfSeqToSongNumFunc              - SMF sequence to song number
;   SmfSeqFromSongNumFunc            - SMF sequence from song number
;   SmfSeqSongNameFunc               - SMF sequence song name
;   SmfLoadAsFunc                    - SMF load-as function
;   FmmSmfFileNameFunc               - SMF filename handling
; =============================================================================

FmmSmfLoadTitleFunc:
	cp xbc, 0x1c00007
	jrl z, SmfLoad_HandleOk
	cp xbc, 0x1c00013
	jrl nz, SmfLoad_Return
	cp xde, 0x3
	jrl z, SmfLoad_CancelCleanup
	cp xde, 0x2
	jrl nz, SmfLoad_Return
	stdi8 0x84FE, 0
	lds wa, 1
	calr InitializeOperationState
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	ldmm8 0x808A, 0x8D37
	cpdi16 0x8500, 0
	jr ge, SmfLoad_DispatchState
	call GetDiskSizeInfo
	extz hl
	stda16 0x8500, xhl
	calr SignalProgressUpdate

SmfLoad_DispatchState:
	ldda16 xwa, 0x8500
	cps wa, 1
	jrl z, SmfLoad_Success
	cps wa, 0
	jrl z, SmfLoad_ErrorCancel
	cps wa, 5
	jr z, SmfLoad_AbortPartial
	cpdi16 0x8504, 0
	jr ge, SmfLoad_CheckFileCount
	call GetFileCountEncoded
	stda16 0x8504, xhl
	call FileIO_SearchAndLoadFile
	call GetEncodedFreeSpaceData
	calr SignalProgressUpdate

SmfLoad_CheckFileCount:
	cpdi16 0x8504, 0
	jrl nz, SmfLoad_SendWait
	cpdi16 0x8502, 0
	jr ge, SmfLoad_CheckSlotCount
	call GetEncodedFileSizeData
	stda16 0x8502, xhl
	calr SignalProgressUpdate

SmfLoad_CheckSlotCount:
	cpdi16 0x8502, 0
	jrl le, SmfLoad_SendWait
	cpdi8 0x808A, 97
	jrl z, SmfLoad_SendWait
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0x61
	jrl SmfLoad_CallHandler

SmfLoad_AbortPartial:
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 1
	call ApPostEvent
	ldda8 a, 0x808A
	extz wa
	call UI_PostModeChangeEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call ApPostEvent
	stdi8 0x7F42, 0
	ldw wa, 0xee
	jr SmfLoad_CallStatusDisplay

SmfLoad_ErrorCancel:
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0x7d
	jrl SmfLoad_CallHandler

SmfLoad_Success:
	calr ResetProgressIndication
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 1
	call ApPostEvent
	ldda8 a, 0x808A
	extz wa
	call UI_PostModeChangeEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call ApPostEvent
	stdi8 0x7F42, 2
	ldw wa, 0xee

SmfLoad_CallStatusDisplay:
	call SoundCtrl_SendCommand
	jr SmfLoad_Return

SmfLoad_SendWait:
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	call ApPostEvent
	jr SmfLoad_Return

SmfLoad_CancelCleanup:
	calr CancelOperationCleanup
	jr SmfLoad_Return

SmfLoad_HandleOk:
	cp xde, 0xf
	jr nz, SmfLoad_Return
	cpdi8 0x8D34, 7
	jr nz, SmfLoad_OkReturnCode
	ldw wa, 0xd6
	jr SmfLoad_CallHandler

SmfLoad_OkReturnCode:
	ldw wa, 0x60

SmfLoad_CallHandler:
	call UI_PostModeChangeEvent

SmfLoad_Return:
	lds32 xhl, 0
	ret

FmmSmfSaveTitleFunc:
	cp xbc, 0x1c00013
	jr nz, SmfSave_Return
	cp xde, 0x3
	jr z, SmfSave_CancelCleanup
	cp xde, 0x2
	jr nz, SmfSave_Return
	stdi8 0x84FE, 0
	lds wa, 1
	calr InitializeOperationState
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	cpdi16 0x8504, 0
	jr ge, SmfSave_SendWait
	call GetFileCountEncoded
	stda16 0x8504, xhl
	call FileIO_SearchAndLoadFile
	call GetEncodedFreeSpaceData
	calr SignalProgressUpdate

SmfSave_SendWait:
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	call ApPostEvent
	jr SmfSave_Return

SmfSave_CancelCleanup:
	calr CancelOperationCleanup

SmfSave_Return:
	lds32 xhl, 0
	ret

RenderSmfFilename:
	extz bc
	stib_dri 0x07, 0xe0, 0xe4, 0x00
	lds ix, 0
	lda_24 xhl, 0xeed778
	jr RenderSmf_LoopCheck

RenderSmf_CheckSeparator:
	extz bc
	ld_srib3 C, 0x07, 0xec, 0xe4
	and c, 0x7
	jr nz, RenderSmf_IncIndex
	ld (xde), 0x5f

RenderSmf_IncIndex:
	inc 1, ix

RenderSmf_LoopCheck:
	cp ix, 0x8
	jr ge, RenderSmf_PadCheck
	st_dri3b B, 0x07, 0xe0, 0xf0
	ld c, (xde)
	cps c, 0
	jr nz, RenderSmf_CheckSeparator

RenderSmf_PadCheck:
	cp ix, 0x8
	ret ge

RenderSmf_PadLoop:
	stib_dri 0x07, 0xe0, 0xf0, 0x5f
	inc 1, ix
	cp ix, 0x8
	jr lt, RenderSmf_PadLoop
	ret

SaveFileNameSmfFunc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ldada xwa, 0x8850
	cp xbc, 0x1e00086
	jr z, SaveFN_HandleApply
	cp xbc, 0x1e0003a
	jr z, SaveFN_HandleTextChange
	cp xbc, 0x1c0000b
	jr z, SaveFN_HandleActivate
	cp xbc, 0x1e50004
	jrl nz, SaveFN_Return
	ld xwa, (xsp + 4)
	stda32 0x808C, xwa
	jrl SaveFN_Return

SaveFN_HandleActivate:
	ld (xwa), 0x0
	lda xiz, (xwa + 1)
	call FileIO_GetRecordPtrAlt
	ld xbc, xhl
	ld xwa, xiz
	call FileIO_CopyString
	ldada xwa, 0x8851
	call FileIO_GetRecordType_Extended
	ldda32 xwa, 0x808C
	ld xbc, 0x1c0000f
	ld xde, 0x8850
	jr SaveFN_SendEvent

SaveFN_HandleTextChange:
	ld xiz, xwa
	call FileIO_GetRecordPtrAlt
	ld xbc, xhl
	ld xwa, xiz
	call FileIO_CopyString
	ld xwa, 0x8850
	ldw bc, 0x8
	calr RenderSmfFilename
	ld xwa, (xsp + 4)
	ld xbc, 0x1e00086
	ld xde, 0x8850

SaveFN_SendEvent:
	call ApPostEvent
	jr SaveFN_Return

SaveFN_HandleApply:
	ld xbc, (xsp + 4)
	ldw de, 0x8
	call FileIO_CopyString_WriteNull
	ld xwa, 0x8850
	ldw bc, 0x8
	calr RenderSmfFilename
	ld xwa, 0x8850
	ld xbc, 0xea0736
	call FileIO_BuildFilePath
	ld xwa, 0x8850
	call FileIO_WriteRecordName

SaveFN_Return:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret

SmfSeqToSongNumFunc:
	push xiz
	cp xbc, 0x1c0000b
	jr z, SeqToSong_BuildEntry
	cp xbc, 0x1e50004
	jr nz, SeqToSong_Return
	stda32 0x8090, xde
	jr SeqToSong_Return

SeqToSong_BuildEntry:
	ldada xwa, 0x8094
	stib_dpi 0xe0, 0x00
	ld xbc, 0xea073c
	call FileIO_CopyString
	ldada xiz, 0x8095
	ldda8 a, 0x8948
	inc 1, a
	extz wa
	lds bc, 2
	calr NumToAscii_FormatNumber
	ld xbc, xhl
	ld xwa, xiz
	call FileIO_BuildFilePath
	ldda32 xwa, 0x8090
	ld xbc, 0x1c0000f
	ld xde, 0x8094
	call ApPostEvent

SeqToSong_Return:
	lds32 xhl, 0
	pop xiz
	ret

SmfSeqFromSongNumFunc:
	push xiz
	cp xbc, 0x1c0000b
	jr z, SeqFromSong_BuildEntry
	cp xbc, 0x1e50004
	jr nz, SeqFromSong_Return
	stda32 0x8114, xde
	jr SeqFromSong_Return

SeqFromSong_BuildEntry:
	ldada xwa, 0x8118
	stib_dpi 0xe0, 0x00
	ld xbc, 0xea0748
	call FileIO_CopyString
	ldada xiz, 0x8119
	ldda8 a, 0x8948
	inc 1, a
	extz wa
	lds bc, 2
	calr NumToAscii_FormatNumber
	ld xbc, xhl
	ld xwa, xiz
	call FileIO_BuildFilePath
	ldda32 xwa, 0x8114
	ld xbc, 0x1c0000f
	ld xde, 0x8118
	call ApPostEvent

SeqFromSong_Return:
	lds32 xhl, 0
	pop xiz
	ret

SmfSeqSongNameFunc:
	cp xbc, 0x1c0000b
	jr z, SeqSongName_BuildEntry
	cp xbc, 0x1e50004
	jr nz, SeqSongName_Return
	stda32 0x8198, xde
	jr SeqSongName_Return

SeqSongName_BuildEntry:
	ldda8 a, 0x8948
	extz wa
	lds bc, 0
	lds de, 0
	calr BuildSlotLabel
	ld xde, xhl
	ldda32 xwa, 0x8198
	ld xbc, 0x1c0000f
	call ApPostEvent

SeqSongName_Return:
	lds32 xhl, 0
	ret

SmfLoadAsFunc:
	cp xbc, 0x1c0000b
	jr z, SmfLoadAs_Apply
	cp xbc, 0x1e50004
	jr nz, SmfLoadAs_Return
	stda32 0x819C, xde
	jr SmfLoadAs_Return

SmfLoadAs_Apply:
	ldda8 a, 0x8946
	extz wa
	sla wa, 2
	lda_24 xbc, 0xea0754
	ld_sril3 XDE, 0x07, 0xe4, 0xe0
	ldda32 xwa, 0x819C
	ld xbc, 0x1c0000f
	call ApPostEvent

SmfLoadAs_Return:
	lds32 xhl, 0
	ret

TrimAndPadSmfFilename:
	lds ix, 0
	ld xhl, xwa
	jr TrimPad_LoopCheck

TrimPad_LoopBody:
	cp e, 0x7e
	jr nz, TrimPad_CheckCtrl
	ldb e, 0x5f
	jr TrimPad_StoreChar

TrimPad_CheckCtrl:
	ld e, (xwa)
	cp e, 0x20
	jr nc, TrimPad_AdvancePointers
	ldb e, 0x20

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
	cps e, 0
	jr nz, TrimPad_LoopBody

TrimPad_PadCheck:
	cp ix, bc
	jr nc, TrimPad_NullTerminate

TrimPad_PadLoop:
	stib_dpi 0xe0, 0x20
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
	lds wa, 0
	calr InitializeOperationState
	lds iz, 0

DispFileList_LoopBody:
	ld de, iz
	sll de, 5
	ldada xbc, 0x850C
	extz xde
	add xde, xbc
	ldto_berp A, 0xf8
	ld (xde), a
	ld wa, (xsp + 2)
	add wa, iz
	call GetRecordPtrForFile
	ld xbc, xhl
	ld wa, iz
	sll wa, 5
	lds de, 1
	add de, wa
	ldada xhl, 0x850C
	ld wa, de
	extz xwa
	add xwa, xhl
	ld de, (xsp + 2)
	add de, iz
	inc 1, de
	pushw 0xc
	pushw 0x1
	call FileIO_ReadHeader_ParseLoop
	ld de, iz
	sll de, 5
	ldada xbc, 0x850C
	extz xde
	add xde, xbc
	ld xwa, (xsp + 4)
	ld xbc, 0x1c0000f
	call ApPostEvent
	inc 1, iz
	cp iz, 0xa
	jr lt, DispFileList_LoopBody
	popw iz
	inc 6, xsp
	ret

ValidateSmfFilename:
	lds iy, 0
	lds hl, 0
	jr ValidateFN_LoopHead

ValidateFN_CheckSpace:
	cp e, 0x20
	jr z, ValidateFN_AdvancePointer
	ldb l, 0x0
	ret

ValidateFN_AdvancePointer:
	inc 1, iy
	inc 1, hl

ValidateFN_LoopHead:
	ld_srib3 E, 0x07, 0xe0, 0xf4
	cps e, 0
	jr z, ValidateFN_ReturnValid
	cp hl, bc
	jr c, ValidateFN_CheckSpace

ValidateFN_ReturnValid:
	ldb l, 0x1
	ret

FmmSmfFileNameFunc:
	lda xsp, (xsp - 32)
	push xiz
	ld xiz, xde
	ld (xsp + 28), xbc
	ld (xsp + 32), xwa
	ld xde, (xsp + 28)
	ldda32 xwa, 0x81A0
	ld xbc, (xsp + 28)
	cp xbc, 0x1c00018
	jrl z, SmfFN_NavSetup
	cp xbc, 0x1c00017
	jrl z, SmfFN_NavSetup
	cp xbc, 0x1c0000b
	jrl z, SmfFN_HandleActivate
	ld xbc, xiz
	sub xde, 0x1e50002
	cp xde, 0x0
	jrl lt, SmfFN_ReturnZero
	cp xde, 0x5
	jr gt, SmfFN_ReturnZero
	add xde, xde
	add xde, 0xea079e
	ld de, (xde)
	lda_24 xix, SmfFN_JumpTable
	jp_dri 8, 0x07, 0xf0, 0xe8
SmfFN_JumpTable:
	stda32	0x81A0, xbc
	lds32	xwa, 0
	stda32	0x81A4, xwa
	stda32	0x81A8, xwa
	cpdi8	0x8D36, 107
	jr	z, 20
	call	GetFirstPageBase
	stda16	0x81AC, hl
	cps	hl, 0
	jr	ge, 26
	stdi16	0x81AC, 0
	jr	18
	ldda16	wa, 0x8504
	stda16	0x81AC, wa
	cps	wa, 0
	jr	le, 2
	dec	1, wa
	call	NavigateToFileIndex
	ldda16	wa, 0x81AC
	exts	xwa
	divs	wa, 10
	ld	de, qwa
	exts	xde
	ldda32	xwa, 0x81A0
	ld	xbc, 0x01E50002
	jrl	1929

SmfFN_HandleActivate:
	ldda16 xbc, 0x81AC
	exts xbc
	divs bc, 0xa
	muls bc, 0xa
	calr DisplaySmfFileList

SmfFN_ReturnZero:
	lds32 xhl, 0
	jrl SmfFN_Return

SmfFN_NavSetup:
	ld xbc, 0x1c50001
	lds32 xde, 1
	call ApPostEvent
	ldda16 xix, 0x81AC
	ld (xsp + 4), ix
	or xiz, xiz
	jr nz, SmfFN_PageUp
	cpdi8 0x84FE, 0
	jr nz, SmfFN_PageUp
	ld xwa, (xsp + 28)
	cp xwa, 0x1c00018
	jr nz, SmfFN_NavUp
	ld bc, ix
	inc 1, bc
	cpdi8 0x8D36, 107
	jr z, SmfFN_NavDown_WrapCheck
	cpda16 xbc, 0x8504
	jr lt, SmfFN_NavDown_Apply
	jrl SmfFN_UpdateDisplay

SmfFN_NavDown_WrapCheck:
	ldda16 xwa, 0x8504
	inc 1, wa
	cp bc, wa
	jrl ge, SmfFN_UpdateDisplay

SmfFN_NavDown_Apply:
	inc 1, ix
	jrl SmfFN_StoreIndex

SmfFN_NavUp:
	cp xwa, 0x1c00017
	jrl nz, SmfFN_UpdateDisplay
	cps ix, 0
	jrl le, SmfFN_UpdateDisplay
	dec 1, ix
	jr SmfFN_StoreIndex

SmfFN_PageUp:
	cp xiz, 0x1
	jr nz, SmfFN_PageDown
	cpdi8 0x84FE, 0
	jr nz, SmfFN_PageDown
	cp ix, 0xa
	jrl lt, SmfFN_UpdateDisplay
	sub ix, 0xa
	jr SmfFN_StoreIndex

SmfFN_PageDown:
	cp xiz, 0x2
	jrl nz, SmfFN_HandleSave
	cpdi8 0x84FE, 0
	jr nz, SmfFN_HandleSave
	ld iy, ix
	add iy, 0xa
	ldda16 xbc, 0x8504
	ld de, ix
	exts xde
	divs de, 0xa
	cpdi8 0x8D36, 107
	jr z, SmfFN_PageDown_WrapCheck
	ld hl, bc
	cp iy, bc
	jr lt, SmfFN_PageDown_Add10
	ld bc, hl
	dec 1, bc
	ld wa, bc
	exts xwa
	divs wa, 0xa
	cp de, wa
	jrl ge, SmfFN_UpdateDisplay
	exts xhl
	divs hl, 0xa
	ldto_werp WA, 0xee
	cps wa, 0
	jrl z, SmfFN_UpdateDisplay
	stda16 0x81AC, xbc
	ld hl, bc
	jrl SmfFN_RefreshIfChanged

SmfFN_PageDown_WrapCheck:
	ld hl, bc
	inc 1, bc
	cp iy, bc
	jr ge, SmfFN_PageDown_ClampCheck

SmfFN_PageDown_Add10:
	add ix, 0xa

SmfFN_StoreIndex:
	stda16 0x81AC, xix
	ld hl, ix
	jrl SmfFN_RefreshIfChanged

SmfFN_PageDown_ClampCheck:
	ld wa, hl
	exts xwa
	divs wa, 0xa
	cp de, wa
	jrl ge, SmfFN_UpdateDisplay
	exts xbc
	divs bc, 0xa
	ldto_werp WA, 0xe6
	cps wa, 0
	jrl z, SmfFN_UpdateDisplay
	stda16 0x81AC, xhl
	jrl SmfFN_RefreshIfChanged

SmfFN_HandleSave:
	cp xiz, 0x3
	jrl nz, SmfFN_HandleOpen
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	lds wa, 0
	calr InitializeOperationState
	ldda8 a, 0x8948
	extz wa
	ldda8 c, 0x8946
	extz bc
	call LoadFileSMF
	ld (xsp + 6), hl
	calr SignalProgressUpdate
	cpw (xsp + 6), 0x0
	jr lt, SmfFN_Save_Finish
	ldda16 xwa, 0x81AC
	call GetFileEntryByIndex
	ld xbc, xhl
	lda xwa, (xsp + 8)
	ldw de, 0x10
	call FileIO_CopyString_WriteNull
	lda xwa, (xsp + 8)
	ldw bc, 0x10
	calr ValidateSmfFilename
	cps l, 0
	jr z, SmfFN_Save_WriteSlot
	ldda16 xwa, 0x81AC
	call GetRecordPtrForFile
	ld xbc, xhl
	lda xwa, (xsp + 8)
	ldw de, 0x8
	call FileIO_CopyString_WriteNull

SmfFN_Save_WriteSlot:
	lda xwa, (xsp + 8)
	ldw bc, 0x10
	calr TrimAndPadSmfFilename
	lda_24 xwa, 0x0ab000
	lds32 xbc, 0
	ldda8 c, 0x8948
	sll xbc, 11
	add xwa, xbc
	st_dri3b W, 0xe1, 0x00, 0x01
	lda xbc, (xsp + 8)
	ldw de, 0x10
	call FileIO_CopyString_WriteNull
	ld8_24 a, 0x00ffe3
	cpda8 a, 0x8948
	jr nz, SmfFN_Save_Finish
	lda_24 xwa, 0x00f180
	st_dri3b W, 0xe1, 0x00, 0x01
	lda xbc, (xsp + 8)
	ldw de, 0x10
	call FileIO_CopyString_WriteNull

SmfFN_Save_Finish:
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 1
	call ApPostEvent
	cpdi16 0xF19E, 0
	jr z, SmfFN_Save_NoAltSlot
	ldw wa, 0xa
	jr SmfFN_Save_CallResult

SmfFN_Save_NoAltSlot:
	lds wa, 1

SmfFN_Save_CallResult:
	call UI_PostPartChangeEvent
	ld wa, (xsp + 6)
	lds bc, 1
	calr FileIO_ValidateSignedValue
	stda8 0x7F42, l
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0xee
	jrl SmfFN_CallStatusDisplayAndExit

SmfFN_HandleOpen:
	cp xiz, 0x4
	jrl nz, SmfFN_HandleOpen2
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	call FileIO_GetRecordPtrAlt
	ld xwa, xhl
	call FileIO_CheckFileExists
	cps l, 0
	jr z, SmfFN_Open_Execute
	cpi8_24 0x0340ea, 0x00
	jr z, SmfFN_Open_Execute
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c50000
	lds32 xde, 1
	call ApPostEvent
	ld xwa, 0x600037
	ld xbc, 0x1c00001
	lds32 xde, 0
	jrl SmfFN_DispatchEvent

SmfFN_Open_Execute:
	lds wa, 0
	calr InitializeOperationState
	ldda8 a, 0x8948
	extz wa
	ldda8 c, 0x894A
	extz bc
	ldda8 e, 0x894C
	extz de
	call LoadFileVariant
	ld wa, hl
	lds bc, 5
	calr FileIO_ValidateSignedValue
	stda8 0x7F42, l
	call FileIO_ResetCurrentRecord
	call GetEncodedFreeSpaceData
	call GetFileCountEncoded
	stda16 0x8504, xhl
	calr SignalProgressUpdate
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 1
	call ApPostEvent
	lds wa, 1
	call UI_PostPartChangeEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0xee
	jrl SmfFN_CallStatusDisplayAndExit

SmfFN_HandleOpen2:
	cp xiz, 0x32
	jrl nz, SmfFN_HandleDelete
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	lds wa, 0
	calr InitializeOperationState
	ldda8 a, 0x8948
	extz wa
	ldda8 c, 0x894A
	extz bc
	ldda8 e, 0x894C
	extz de
	call LoadFileVariant
	ld wa, hl
	lds bc, 5
	calr FileIO_ValidateSignedValue
	stda8 0x7F42, l
	call FileIO_ResetCurrentRecord
	call GetEncodedFreeSpaceData
	call GetFileCountEncoded
	stda16 0x8504, xhl
	calr SignalProgressUpdate
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 1
	call ApPostEvent
	lds wa, 1
	call UI_PostPartChangeEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0xee
	jrl SmfFN_CallStatusDisplayAndExit

SmfFN_HandleDelete:
	cp xiz, 0x5
	jrl nz, SmfFN_HandleDelete2
	cpi8_24 0x0340ea, 0x00
	jr z, SmfFN_Delete_Execute
	ld xwa, 0xffffffff
	ld xbc, 0x1c50000
	lds32 xde, 1
	call ApPostEvent
	ld xwa, 0x7b0051
	ld xbc, 0x1c00001
	lds32 xde, 0
	jrl SmfFN_DispatchEvent

SmfFN_Delete_Execute:
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	lds wa, 0
	calr InitializeOperationState
	call GetFirstRecordAndOpen
	ld wa, hl
	lds bc, 5
	calr FileIO_ValidateSignedValue
	stda8 0x7F42, l
	calr SignalProgressUpdate
	call FileIO_ResetCurrentRecord
	call GetEncodedFreeSpaceData
	call GetFileCountEncoded
	stda16 0x8504, xhl
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ldda16 xwa, 0x81AC
	cpda16 xwa, 0x8504
	jr lt, SmfFN_Delete_AdjustIndex
	cps wa, 0
	jr le, SmfFN_Delete_AdjustIndex
	dec 1, wa
	stda16 0x81AC, xwa
	ld (xsp + 4), wa

SmfFN_Delete_AdjustIndex:
	ldw wa, 0xee
	jr SmfFN_CallStatusDisplayAndExit

SmfFN_HandleDelete2:
	cp xiz, 0x33
	jr nz, SmfFN_IgnoredEvents
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	lds wa, 0
	calr InitializeOperationState
	call GetFirstRecordAndOpen
	ld wa, hl
	lds bc, 5
	calr FileIO_ValidateSignedValue
	stda8 0x7F42, l
	calr SignalProgressUpdate
	call FileIO_ResetCurrentRecord
	call GetEncodedFreeSpaceData
	call GetFileCountEncoded
	stda16 0x8504, xhl
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ldda16 xwa, 0x81AC
	cpda16 xwa, 0x8504
	jr lt, SmfFN_Delete2_AdjustIndex
	cps wa, 0
	jr le, SmfFN_Delete2_AdjustIndex
	dec 1, wa
	stda16 0x81AC, xwa
	ld (xsp + 4), wa

SmfFN_Delete2_AdjustIndex:
	ldw wa, 0xee

SmfFN_CallStatusDisplayAndExit:
	call SoundCtrl_SendCommand
	jrl SmfFN_UpdateDisplay

SmfFN_IgnoredEvents:
	cp xiz, 0xa
	jrl z, SmfFN_UpdateDisplay
	cp xiz, 0xb
	jrl z, SmfFN_UpdateDisplay
	cp xiz, 0xc
	jrl z, SmfFN_UpdateDisplay
	cp xiz, 0xd
	jrl z, SmfFN_UpdateDisplay
	cp xiz, 0x14
	jr nz, SmfFN_HandleScrollFlag1
	cpdi8 0x84FE, 0
	jr nz, SmfFN_HandleScrollFlag1
	ld xwa, (xsp + 28)
	cp xwa, 0x1c00017
	jr nz, SmfFN_SetScrollDir0
	stdi8 0x8942, 1
	jrl SmfFN_UpdateDisplay

SmfFN_SetScrollDir0:
	stdi8 0x8942, 0
	jrl SmfFN_UpdateDisplay

SmfFN_HandleScrollFlag1:
	cp xiz, 0x15
	jr nz, SmfFN_HandleScrollFlag2
	ldda8 c, 0x8946
	ld a, c
	inc 1, a
	cps a, 3
	jr nc, SmfFN_LoadAs_Wrap
	inc 1, c
	stda8 0x8946, c
	ld xwa, (xsp + 32)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	jr SmfFN_LoadAs_Apply

SmfFN_LoadAs_Wrap:
	stdi8 0x8946, 0
	ld xwa, (xsp + 32)
	ld xbc, 0x1c0000b
	lds32 xde, 0

SmfFN_LoadAs_Apply:
	calr SmfLoadAsFunc
	jrl SmfFN_UpdateDisplay

SmfFN_HandleScrollFlag2:
	cp xiz, 0x16
	jr nz, SmfFN_HandleScrollFlag3
	ld xwa, (xsp + 28)
	cp xwa, 0x1c00017
	jr nz, SmfFN_SetTrackFlag0
	stdi8 0x894A, 1
	jrl SmfFN_UpdateDisplay

SmfFN_SetTrackFlag0:
	stdi8 0x894A, 0
	jrl SmfFN_UpdateDisplay

SmfFN_HandleScrollFlag3:
	ld xwa, (xsp + 28)
	cp xiz, 0x17
	jr nz, SmfFN_HandleScrollFlag4
	cp xwa, 0x1c00017
	jr nz, SmfFN_SetTransposeFlag0
	stdi8 0x894C, 1
	jrl SmfFN_UpdateDisplay

SmfFN_SetTransposeFlag0:
	stdi8 0x894C, 0
	jrl SmfFN_UpdateDisplay

SmfFN_HandleScrollFlag4:
	cp xiz, 0x18
	jr nz, SmfFN_HandleSeqSongNum
	cp xwa, 0x1c00017
	jr nz, SmfFN_SetFlag35140_0
	stdi8 0x8944, 1
	jrl SmfFN_UpdateDisplay

SmfFN_SetFlag35140_0:
	stdi8 0x8944, 0
	jrl SmfFN_UpdateDisplay

SmfFN_HandleSeqSongNum:
	ldda8 c, 0x8948
	ld a, c
	inc 1, a
	cp xiz, 0x1e
	jr nz, SmfFN_HandleSeqFromSong
	cp a, 0xa
	jr nc, SmfFN_SeqToSong_Wrap
	inc 1, c
	stda8 0x8948, c
	ld xwa, (xsp + 32)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	calr SmfSeqToSongNumFunc
	ld xwa, (xsp + 32)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	jr SmfFN_SeqSongName_Dispatch

SmfFN_SeqToSong_Wrap:
	stdi8 0x8948, 0
	ld xwa, (xsp + 32)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	calr SmfSeqToSongNumFunc
	ld xwa, (xsp + 32)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	jr SmfFN_SeqSongName_Dispatch

SmfFN_HandleSeqFromSong:
	cp xiz, 0x1f
	jr nz, SmfFN_HandleMedleyConfirm
	cp a, 0xa
	jr nc, SmfFN_SeqFromSong_Wrap
	inc 1, c
	stda8 0x8948, c
	ld xwa, (xsp + 32)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	calr SmfSeqFromSongNumFunc
	ld xwa, (xsp + 32)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	jr SmfFN_SeqSongName_Dispatch

SmfFN_SeqFromSong_Wrap:
	stdi8 0x8948, 0
	ld xwa, (xsp + 32)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	calr SmfSeqFromSongNumFunc
	ld xwa, (xsp + 32)
	ld xbc, 0x1c0000b
	lds32 xde, 0

SmfFN_SeqSongName_Dispatch:
	calr SmfSeqSongNameFunc
	jr SmfFN_UpdateDisplay

SmfFN_HandleMedleyConfirm:
	cp xiz, 0x28
	jr nz, SmfFN_UpdateDisplay
	cpdi16 0x81AE, 0
	jr z, SmfFN_UpdateDisplay
	ldda32 xwa, 0x81A4
	or xwa, xwa
	jr z, SmfFN_UpdateDisplay
	ld xbc, 0x1c0000a
	lds32 xde, 0

SmfFN_DispatchEvent:
	call ApPostEvent

SmfFN_UpdateDisplay:
	ldda16 xhl, 0x81AC

SmfFN_RefreshIfChanged:
	cp (xsp + 4), hl
	jrl z, SmfFN_SendOkState
	ld wa, hl
	call NavigateToFileIndex
	ldda16 xwa, 0x81AC
	exts xwa
	divs wa, 0xa
	ldto_werp DE, 0xe2
	exts xde
	ldda32 xwa, 0x81A0
	ld xbc, 0x1e50002
	call ApPostEvent
	ldda16 xbc, 0x81AC
	exts xbc
	divs bc, 0xa
	ld de, (xsp + 4)
	exts xde
	divs de, 0xa
	ldda32 xwa, 0x81A0
	cp de, bc
	jr nz, SmfFN_RedrawPage
	ld bc, (xsp + 4)
	exts xbc
	divs bc, 0xa
	ldto_werp BC, 0xe6
	sll bc, 5
	ldada xhl, 0x850C
	ld de, bc
	extz xde
	add xde, xhl
	ld xbc, 0x1c0000f
	call ApPostEvent
	ldda16 xwa, 0x81AC
	exts xwa
	divs wa, 0xa
	ldto_werp WA, 0xe2
	sll wa, 5
	ldada xbc, 0x850C
	ld de, wa
	extz xde
	add xde, xbc
	ldda32 xwa, 0x81A0
	ld xbc, 0x1c0000f
	call ApPostEvent
	jr SmfFN_UpdateFilenameField

SmfFN_RedrawPage:
	muls bc, 0xa
	calr DisplaySmfFileList
	cpdi8 0x8D36, 108
	jr nz, SmfFN_UpdateFilenameField
	ld xwa, (xsp + 32)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	calr FmmSmfMedleyFunc

SmfFN_UpdateFilenameField:
	cpdi8 0x8D36, 107
	jr nz, SmfFN_SendOkState
	ldada xiz, 0x8850
	ldda16 xwa, 0x81AC
	cpda16 xwa, 0x8504
	jr lt, SmfFN_FetchFilename
	cps wa, 0
	jr le, SmfFN_FetchFilename
	ld xwa, xiz
	ld xbc, 0xea0790
	call FileIO_CopyString
	jr SmfFN_WriteFilenameField

SmfFN_FetchFilename:
	call GetRecordPtrForFile
	ld xbc, xhl
	ld xwa, xiz
	call FileIO_CopyString
	ld xwa, 0x8850
	call FileIO_GetRecordType_Extended

SmfFN_WriteFilenameField:
	ld xwa, 0x8850
	call FileIO_WriteRecordName
	ld xwa, (xsp + 32)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	calr SaveFileNameSmfFunc

SmfFN_SendOkState:
	ldda32 xwa, 0x81A0
	ld xbc, 0x1c50001
	lds32 xde, 0
	jr SmfFN_DispatchFinalEvent
	stda32 0x81A4, xbc
	jrl SmfFN_ReturnZero
	stda32 0x81A8, xbc
	jrl SmfFN_ReturnZero
	stda16 0x81AE, xiz
	jrl SmfFN_ReturnZero
	cpdi8 0x84FE, 0
	jrl z, SmfFN_ReturnZero
	ld wa, iz
	stda16 0x81AC, xwa
	call NavigateToFileIndex
	ldda16 xwa, 0x81AC
	exts xwa
	divs wa, 0xa
	ldto_werp DE, 0xe2
	exts xde
	ldda32 xwa, 0x81A0
	ld xbc, 0x1e50002

SmfFN_DispatchFinalEvent:
	call ApPostEvent
	jrl SmfFN_ReturnZero
	ldda16 xhl, 0x81AC
	exts xhl

SmfFN_Return:
	pop xiz
	lda xsp, (xsp + 32)
	ret

DisplaySmfSequenceList:
	dec 6, xsp
	pushw iz
	ld (xsp + 2), bc
	ld (xsp + 4), xwa
	lds wa, 0
	calr InitializeOperationState
	lds iz, 0

DispSeqList_LoopBody:
	ld de, iz
	sll de, 5
	ldada xbc, 0x850C
	extz xde
	add xde, xbc
	ldto_berp A, 0xf8
	ld (xde), a
	ld wa, (xsp + 2)
	add wa, iz
	call FileIO_GetWallpaperEntry
	ld xbc, xhl
	ld wa, iz
	sll wa, 5
	lds de, 1
	add de, wa
	ldada xhl, 0x850C
	ld wa, de
	extz xwa
	add xwa, xhl
	ld de, (xsp + 2)
	add de, iz
	inc 1, de
	pushw 0xc
	pushw 0x1
	call FileIO_ReadHeader_ParseLoop
	ld de, iz
	sll de, 5
	ldada xbc, 0x850C
	extz xde
	add xde, xbc
	ld xwa, (xsp + 4)
	ld xbc, 0x1c0000f
	call ApPostEvent
	inc 1, iz
	cp iz, 0xa
	jr lt, DispSeqList_LoopBody
	popw iz
	inc 6, xsp
	ret

