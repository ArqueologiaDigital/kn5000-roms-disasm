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
	cp xbc, 0x1C00007
	jrl z, SmfLoad_HandleOk
	cp xbc, 0x1C00013
	jrl nz, SmfLoad_Return
	cp xde, 0x3
	jrl z, SmfLoad_CancelCleanup
	cp xde, 0x2
	jrl nz, SmfLoad_Return
	stdi8 34046, 0
	lds wa, 1
	calr InitializeOperationState
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	ldmm8 32906, 36151
	cpdi16 34048, 0
	jr ge, SmfLoad_DispatchState
	call 0xF89520
	extz hl
	stda16 34048, xhl
	calr SignalProgressUpdate

SmfLoad_DispatchState:
	ldda16 xwa, 34048
	cps wa, 1
	jrl z, SmfLoad_Success
	cps wa, 0
	jrl z, SmfLoad_ErrorCancel
	cps wa, 5
	jr z, SmfLoad_AbortPartial
	cpdi16 34052, 0
	jr ge, SmfLoad_CheckFileCount
	call 0xF89C78
	stda16 34052, xhl
	call LABEL_F8958D
	call 0xF8953B
	calr SignalProgressUpdate

SmfLoad_CheckFileCount:
	cpdi16 34052, 0
	jrl nz, SmfLoad_SendWait
	cpdi16 34050, 0
	jr ge, SmfLoad_CheckSlotCount
	call 0xF8987D
	stda16 34050, xhl
	calr SignalProgressUpdate

SmfLoad_CheckSlotCount:
	cpdi16 34050, 0
	jrl le, SmfLoad_SendWait
	cpdi8 32906, 97
	jrl z, SmfLoad_SendWait
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0x61
	jrl SmfLoad_CallHandler

SmfLoad_AbortPartial:
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call 0xFA9D58
	ldda8 a, 32906
	extz wa
	call 0xF99490
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	stdi8 32578, 0
	ldw wa, 0xEE
	jr SmfLoad_CallStatusDisplay

SmfLoad_ErrorCancel:
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0x7D
	jrl SmfLoad_CallHandler

SmfLoad_Success:
	calr ResetProgressIndication
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call 0xFA9D58
	ldda8 a, 32906
	extz wa
	call 0xF99490
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	stdi8 32578, 2
	ldw wa, 0xEE

SmfLoad_CallStatusDisplay:
	call SoundCtrl_SendCommand
	jr SmfLoad_Return

SmfLoad_SendWait:
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	call 0xFA9D58
	jr SmfLoad_Return

SmfLoad_CancelCleanup:
	calr CancelOperationCleanup
	jr SmfLoad_Return

SmfLoad_HandleOk:
	cp xde, 0xF
	jr nz, SmfLoad_Return
	cpdi8 36148, 7
	jr nz, SmfLoad_OkReturnCode
	ldw wa, 0xD6
	jr SmfLoad_CallHandler

SmfLoad_OkReturnCode:
	ldw wa, 0x60

SmfLoad_CallHandler:
	call 0xF99490

SmfLoad_Return:
	lds32 xhl, 0
	ret

FmmSmfSaveTitleFunc:
	cp xbc, 0x1C00013
	jr nz, SmfSave_Return
	cp xde, 0x3
	jr z, SmfSave_CancelCleanup
	cp xde, 0x2
	jr nz, SmfSave_Return
	stdi8 34046, 0
	lds wa, 1
	calr InitializeOperationState
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	cpdi16 34052, 0
	jr ge, SmfSave_SendWait
	call 0xF89C78
	stda16 34052, xhl
	call LABEL_F8958D
	call 0xF8953B
	calr SignalProgressUpdate

SmfSave_SendWait:
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	call 0xFA9D58
	jr SmfSave_Return

SmfSave_CancelCleanup:
	calr CancelOperationCleanup

SmfSave_Return:
	lds32 xhl, 0
	ret

RenderSmfFilename:
	extz bc
	stib_dri 0x07, 0xE0, 0xE4, 0x00
	lds ix, 0
	lda_24 xhl, 0xeed778
	jr RenderSmf_LoopCheck

RenderSmf_CheckSeparator:
	extz bc
	ld_srib3 C, 0x07, 0xEC, 0xE4
	and c, 0x7
	jr nz, RenderSmf_IncIndex
	ld (xde), 0x5F

RenderSmf_IncIndex:
	inc 1, ix

RenderSmf_LoopCheck:
	cp ix, 0x8
	jr ge, RenderSmf_PadCheck
	st_dri3b B, 0x07, 0xE0, 0xF0
	ld c, (xde)
	cps c, 0
	jr nz, RenderSmf_CheckSeparator

RenderSmf_PadCheck:
	cp ix, 0x8
	ret ge

RenderSmf_PadLoop:
	stib_dri 0x07, 0xE0, 0xF0, 0x5F
	inc 1, ix
	cp ix, 0x8
	jr lt, RenderSmf_PadLoop
	ret

SaveFileNameSmfFunc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ldada xwa, 34896
	cp xbc, 0x1E00086
	jr z, SaveFN_HandleApply
	cp xbc, 0x1E0003A
	jr z, SaveFN_HandleTextChange
	cp xbc, 0x1C0000B
	jr z, SaveFN_HandleActivate
	cp xbc, 0x1E50004
	jrl nz, SaveFN_Return
	ld xwa, (xsp + 4)
	stda32 32908, xwa
	jrl SaveFN_Return

SaveFN_HandleActivate:
	ld (xwa), 0x0
	lda xiz, (xwa + 1)
	call FileIO_GetRecordPtrAlt
	ld xbc, xhl
	ld xwa, xiz
	call FileIO_CopyString
	ldada xwa, 34897
	call FileIO_GetRecordType_Extended
	ldda32 xwa, 32908
	ld xbc, 0x1C0000F
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
	ld xbc, 0x1E00086
	ld xde, 0x8850

SaveFN_SendEvent:
	call 0xFA9D58
	jr SaveFN_Return

SaveFN_HandleApply:
	ld xbc, (xsp + 4)
	ldw de, 0x8
	call FileIO_CopyString_WriteNull
	ld xwa, 0x8850
	ldw bc, 0x8
	calr RenderSmfFilename
	ld xwa, 0x8850
	ld xbc, 0xEA0736
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
	cp xbc, 0x1C0000B
	jr z, SeqToSong_BuildEntry
	cp xbc, 0x1E50004
	jr nz, SeqToSong_Return
	stda32 32912, xde
	jr SeqToSong_Return

SeqToSong_BuildEntry:
	ldada xwa, 32916
	stib_dpi 0xE0, 0x00
	ld xbc, 0xEA073C
	call FileIO_CopyString
	ldada xiz, 32917
	ldda8 a, 35144
	inc 1, a
	extz wa
	lds bc, 2
	calr LABEL_F8B67F
	ld xbc, xhl
	ld xwa, xiz
	call FileIO_BuildFilePath
	ldda32 xwa, 32912
	ld xbc, 0x1C0000F
	ld xde, 0x8094
	call 0xFA9D58

SeqToSong_Return:
	lds32 xhl, 0
	pop xiz
	ret

SmfSeqFromSongNumFunc:
	push xiz
	cp xbc, 0x1C0000B
	jr z, SeqFromSong_BuildEntry
	cp xbc, 0x1E50004
	jr nz, SeqFromSong_Return
	stda32 33044, xde
	jr SeqFromSong_Return

SeqFromSong_BuildEntry:
	ldada xwa, 33048
	stib_dpi 0xE0, 0x00
	ld xbc, 0xEA0748
	call FileIO_CopyString
	ldada xiz, 33049
	ldda8 a, 35144
	inc 1, a
	extz wa
	lds bc, 2
	calr LABEL_F8B67F
	ld xbc, xhl
	ld xwa, xiz
	call FileIO_BuildFilePath
	ldda32 xwa, 33044
	ld xbc, 0x1C0000F
	ld xde, 0x8118
	call 0xFA9D58

SeqFromSong_Return:
	lds32 xhl, 0
	pop xiz
	ret

SmfSeqSongNameFunc:
	cp xbc, 0x1C0000B
	jr z, SeqSongName_BuildEntry
	cp xbc, 0x1E50004
	jr nz, SeqSongName_Return
	stda32 33176, xde
	jr SeqSongName_Return

SeqSongName_BuildEntry:
	ldda8 a, 35144
	extz wa
	lds bc, 0
	lds de, 0
	calr BuildSlotLabel
	ld xde, xhl
	ldda32 xwa, 33176
	ld xbc, 0x1C0000F
	call 0xFA9D58

SeqSongName_Return:
	lds32 xhl, 0
	ret

SmfLoadAsFunc:
	cp xbc, 0x1C0000B
	jr z, SmfLoadAs_Apply
	cp xbc, 0x1E50004
	jr nz, SmfLoadAs_Return
	stda32 33180, xde
	jr SmfLoadAs_Return

SmfLoadAs_Apply:
	ldda8 a, 35142
	extz wa
	sla wa, 2
	lda_24 xbc, 0xea0754
	ld_sril3 XDE, 0x07, 0xE4, 0xE0
	ldda32 xwa, 33180
	ld xbc, 0x1C0000F
	call 0xFA9D58

SmfLoadAs_Return:
	lds32 xhl, 0
	ret

TrimAndPadSmfFilename:
	lds ix, 0
	ld xhl, xwa
	jr TrimPad_LoopCheck

TrimPad_LoopBody:
	cp e, 0x7E
	jr nz, TrimPad_CheckCtrl
	ldb e, 0x5F
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
	stib_dpi 0xE0, 0x20
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
	ldada xbc, 34060
	extz xde
	add xde, xbc
	ldto_berp A, 0xF8
	ld (xde), a
	ld wa, (xsp + 2)
	add wa, iz
	call GetRecordPtrForFile
	ld xbc, xhl
	ld wa, iz
	sll wa, 5
	lds de, 1
	add de, wa
	ldada xhl, 34060
	ld wa, de
	extz xwa
	add xwa, xhl
	ld de, (xsp + 2)
	add de, iz
	inc 1, de
	pushw 0xC
	pushw 0x1
	call FileIO_ReadHeader_ParseLoop
	ld de, iz
	sll de, 5
	ldada xbc, 34060
	extz xde
	add xde, xbc
	ld xwa, (xsp + 4)
	ld xbc, 0x1C0000F
	call 0xFA9D58
	inc 1, iz
	cp iz, 0xA
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
	ld_srib3 E, 0x07, 0xE0, 0xF4
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
	ldda32 xwa, 33184
	ld xbc, (xsp + 28)
	cp xbc, 0x1C00018
	jrl z, SmfFN_NavSetup
	cp xbc, 0x1C00017
	jrl z, SmfFN_NavSetup
	cp xbc, 0x1C0000B
	jrl z, SmfFN_HandleActivate
	ld xbc, xiz
	sub xde, 0x1E50002
	cp xde, 0x0
	jrl lt, SmfFN_ReturnZero
	cp xde, 0x5
	jr gt, SmfFN_ReturnZero
	add xde, xde
	add xde, 0xEA079E
	ld de, (xde)
	lda_24 xix, 0xf8e0c8
	jp_dri 8, 0x07, 0xF0, 0xE8
SmfFN_JumpTable:
	.byte 0xf1, 0xa0, 0x81, 0x61, 0xe8, 0xa8, 0xf1, 0xa4
	.byte 0x81, 0x60, 0xf1, 0xa8, 0x81, 0x60, 0xc1, 0x36
	.byte 0x8d, 0x3f, 0x6b, 0x66, 0x14, 0x1d, 0xc7, 0x9a
	.byte 0xf8, 0xf1, 0xac, 0x81, 0x53, 0xdb, 0xd8, 0x69
	.byte 0x1a, 0xf1, 0xac, 0x81, 0x02, 0x00, 0x00, 0x68
	.byte 0x12, 0xd1, 0x04, 0x85, 0x20, 0xf1, 0xac, 0x81
	.byte 0x50, 0xd8, 0xd8, 0x62, 0x02, 0xd8, 0x69, 0x1d
	.byte 0xa4, 0x9b, 0xf8, 0xd1, 0xac, 0x81, 0x20, 0xe8
	.byte 0x13, 0xd8, 0x0b, 0x0a, 0x00, 0xd7, 0xe2, 0x8a
	.byte 0xea, 0x13, 0xe1, 0xa0, 0x81, 0x20, 0x41, 0x02
	.byte 0x00, 0xe5, 0x01, 0x78, 0x89, 0x07

SmfFN_HandleActivate:
	ldda16 xbc, 33196
	exts xbc
	divs bc, 0xA
	muls bc, 0xA
	calr DisplaySmfFileList

SmfFN_ReturnZero:
	lds32 xhl, 0
	jrl SmfFN_Return

SmfFN_NavSetup:
	ld xbc, 0x1C50001
	lds32 xde, 1
	call 0xFA9D58
	ldda16 xix, 33196
	ld (xsp + 4), ix
	or xiz, xiz
	jr nz, SmfFN_PageUp
	cpdi8 34046, 0
	jr nz, SmfFN_PageUp
	ld xwa, (xsp + 28)
	cp xwa, 0x1C00018
	jr nz, SmfFN_NavUp
	ld bc, ix
	inc 1, bc
	cpdi8 36150, 107
	jr z, SmfFN_NavDown_WrapCheck
	cpda16 xbc, 34052
	jr lt, SmfFN_NavDown_Apply
	jrl SmfFN_UpdateDisplay

SmfFN_NavDown_WrapCheck:
	ldda16 xwa, 34052
	inc 1, wa
	cp bc, wa
	jrl ge, SmfFN_UpdateDisplay

SmfFN_NavDown_Apply:
	inc 1, ix
	jrl SmfFN_StoreIndex

SmfFN_NavUp:
	cp xwa, 0x1C00017
	jrl nz, SmfFN_UpdateDisplay
	cps ix, 0
	jrl le, SmfFN_UpdateDisplay
	dec 1, ix
	jr SmfFN_StoreIndex

SmfFN_PageUp:
	cp xiz, 0x1
	jr nz, SmfFN_PageDown
	cpdi8 34046, 0
	jr nz, SmfFN_PageDown
	cp ix, 0xA
	jrl lt, SmfFN_UpdateDisplay
	sub ix, 0xA
	jr SmfFN_StoreIndex

SmfFN_PageDown:
	cp xiz, 0x2
	jrl nz, SmfFN_HandleSave
	cpdi8 34046, 0
	jr nz, SmfFN_HandleSave
	ld iy, ix
	add iy, 0xA
	ldda16 xbc, 34052
	ld de, ix
	exts xde
	divs de, 0xA
	cpdi8 36150, 107
	jr z, SmfFN_PageDown_WrapCheck
	ld hl, bc
	cp iy, bc
	jr lt, SmfFN_PageDown_Add10
	ld bc, hl
	dec 1, bc
	ld wa, bc
	exts xwa
	divs wa, 0xA
	cp de, wa
	jrl ge, SmfFN_UpdateDisplay
	exts xhl
	divs hl, 0xA
	ldto_werp WA, 0xEE
	cps wa, 0
	jrl z, SmfFN_UpdateDisplay
	stda16 33196, xbc
	ld hl, bc
	jrl SmfFN_RefreshIfChanged

SmfFN_PageDown_WrapCheck:
	ld hl, bc
	inc 1, bc
	cp iy, bc
	jr ge, SmfFN_PageDown_ClampCheck

SmfFN_PageDown_Add10:
	add ix, 0xA

SmfFN_StoreIndex:
	stda16 33196, xix
	ld hl, ix
	jrl SmfFN_RefreshIfChanged

SmfFN_PageDown_ClampCheck:
	ld wa, hl
	exts xwa
	divs wa, 0xA
	cp de, wa
	jrl ge, SmfFN_UpdateDisplay
	exts xbc
	divs bc, 0xA
	ldto_werp WA, 0xE6
	cps wa, 0
	jrl z, SmfFN_UpdateDisplay
	stda16 33196, xhl
	jrl SmfFN_RefreshIfChanged

SmfFN_HandleSave:
	cp xiz, 0x3
	jrl nz, SmfFN_HandleOpen
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	lds wa, 0
	calr InitializeOperationState
	ldda8 a, 35144
	extz wa
	ldda8 c, 35142
	extz bc
	call 0xF88005
	ld (xsp + 6), hl
	calr SignalProgressUpdate
	cpw (xsp + 6), 0x0
	jr lt, SmfFN_Save_Finish
	ldda16 xwa, 33196
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
	ldda16 xwa, 33196
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
	ldda8 c, 35144
	sll xbc, 11
	add xwa, xbc
	st_dri3b W, 0xE1, 0x00, 0x01
	lda xbc, (xsp + 8)
	ldw de, 0x10
	call FileIO_CopyString_WriteNull
	ld8_24 a, 0x00ffe3
	cpda8 a, 35144
	jr nz, SmfFN_Save_Finish
	lda_24 xwa, 0x00f180
	st_dri3b W, 0xE1, 0x00, 0x01
	lda xbc, (xsp + 8)
	ldw de, 0x10
	call FileIO_CopyString_WriteNull

SmfFN_Save_Finish:
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call 0xFA9D58
	cpdi16 61854, 0
	jr z, SmfFN_Save_NoAltSlot
	ldw wa, 0xA
	jr SmfFN_Save_CallResult

SmfFN_Save_NoAltSlot:
	lds wa, 1

SmfFN_Save_CallResult:
	call UI_PostPartChangeEvent
	ld wa, (xsp + 6)
	lds bc, 1
	calr LABEL_F8B48E
	stda8 32578, l
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0xEE
	jrl SmfFN_CallStatusDisplayAndExit

SmfFN_HandleOpen:
	cp xiz, 0x4
	jrl nz, SmfFN_HandleOpen2
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	call FileIO_GetRecordPtrAlt
	ld xwa, xhl
	call LABEL_F8947D
	cps l, 0
	jr z, SmfFN_Open_Execute
	cpi8_24 0x0340ea, 0x00
	jr z, SmfFN_Open_Execute
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C50000
	lds32 xde, 1
	call 0xFA9D58
	ld xwa, 0x600037
	ld xbc, 0x1C00001
	lds32 xde, 0
	jrl SmfFN_DispatchEvent

SmfFN_Open_Execute:
	lds wa, 0
	calr InitializeOperationState
	ldda8 a, 35144
	extz wa
	ldda8 c, 35146
	extz bc
	ldda8 e, 35148
	extz de
	call LoadFileVariant
	ld wa, hl
	lds bc, 5
	calr LABEL_F8B48E
	stda8 32578, l
	call LABEL_F89568
	call 0xF8953B
	call 0xF89C78
	stda16 34052, xhl
	calr SignalProgressUpdate
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call 0xFA9D58
	lds wa, 1
	call UI_PostPartChangeEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0xEE
	jrl SmfFN_CallStatusDisplayAndExit

SmfFN_HandleOpen2:
	cp xiz, 0x32
	jrl nz, SmfFN_HandleDelete
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	lds wa, 0
	calr InitializeOperationState
	ldda8 a, 35144
	extz wa
	ldda8 c, 35146
	extz bc
	ldda8 e, 35148
	extz de
	call LoadFileVariant
	ld wa, hl
	lds bc, 5
	calr LABEL_F8B48E
	stda8 32578, l
	call LABEL_F89568
	call 0xF8953B
	call 0xF89C78
	stda16 34052, xhl
	calr SignalProgressUpdate
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call 0xFA9D58
	lds wa, 1
	call UI_PostPartChangeEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0xEE
	jrl SmfFN_CallStatusDisplayAndExit

SmfFN_HandleDelete:
	cp xiz, 0x5
	jrl nz, SmfFN_HandleDelete2
	cpi8_24 0x0340ea, 0x00
	jr z, SmfFN_Delete_Execute
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C50000
	lds32 xde, 1
	call 0xFA9D58
	ld xwa, 0x7B0051
	ld xbc, 0x1C00001
	lds32 xde, 0
	jrl SmfFN_DispatchEvent

SmfFN_Delete_Execute:
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	lds wa, 0
	calr InitializeOperationState
	call GetFirstRecordAndOpen
	ld wa, hl
	lds bc, 5
	calr LABEL_F8B48E
	stda8 32578, l
	calr SignalProgressUpdate
	call LABEL_F89568
	call 0xF8953B
	call 0xF89C78
	stda16 34052, xhl
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ldda16 xwa, 33196
	cpda16 xwa, 34052
	jr lt, SmfFN_Delete_AdjustIndex
	cps wa, 0
	jr le, SmfFN_Delete_AdjustIndex
	dec 1, wa
	stda16 33196, xwa
	ld (xsp + 4), wa

SmfFN_Delete_AdjustIndex:
	ldw wa, 0xEE
	jr SmfFN_CallStatusDisplayAndExit

SmfFN_HandleDelete2:
	cp xiz, 0x33
	jr nz, SmfFN_IgnoredEvents
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	lds wa, 0
	calr InitializeOperationState
	call GetFirstRecordAndOpen
	ld wa, hl
	lds bc, 5
	calr LABEL_F8B48E
	stda8 32578, l
	calr SignalProgressUpdate
	call LABEL_F89568
	call 0xF8953B
	call 0xF89C78
	stda16 34052, xhl
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ldda16 xwa, 33196
	cpda16 xwa, 34052
	jr lt, SmfFN_Delete2_AdjustIndex
	cps wa, 0
	jr le, SmfFN_Delete2_AdjustIndex
	dec 1, wa
	stda16 33196, xwa
	ld (xsp + 4), wa

SmfFN_Delete2_AdjustIndex:
	ldw wa, 0xEE

SmfFN_CallStatusDisplayAndExit:
	call SoundCtrl_SendCommand
	jrl SmfFN_UpdateDisplay

SmfFN_IgnoredEvents:
	cp xiz, 0xA
	jrl z, SmfFN_UpdateDisplay
	cp xiz, 0xB
	jrl z, SmfFN_UpdateDisplay
	cp xiz, 0xC
	jrl z, SmfFN_UpdateDisplay
	cp xiz, 0xD
	jrl z, SmfFN_UpdateDisplay
	cp xiz, 0x14
	jr nz, SmfFN_HandleScrollFlag1
	cpdi8 34046, 0
	jr nz, SmfFN_HandleScrollFlag1
	ld xwa, (xsp + 28)
	cp xwa, 0x1C00017
	jr nz, SmfFN_SetScrollDir0
	stdi8 35138, 1
	jrl SmfFN_UpdateDisplay

SmfFN_SetScrollDir0:
	stdi8 35138, 0
	jrl SmfFN_UpdateDisplay

SmfFN_HandleScrollFlag1:
	cp xiz, 0x15
	jr nz, SmfFN_HandleScrollFlag2
	ldda8 c, 35142
	ld a, c
	inc 1, a
	cps a, 3
	jr nc, SmfFN_LoadAs_Wrap
	inc 1, c
	stda8 35142, c
	ld xwa, (xsp + 32)
	ld xbc, 0x1C0000B
	lds32 xde, 0
	jr SmfFN_LoadAs_Apply

SmfFN_LoadAs_Wrap:
	stdi8 35142, 0
	ld xwa, (xsp + 32)
	ld xbc, 0x1C0000B
	lds32 xde, 0

SmfFN_LoadAs_Apply:
	calr SmfLoadAsFunc
	jrl SmfFN_UpdateDisplay

SmfFN_HandleScrollFlag2:
	cp xiz, 0x16
	jr nz, SmfFN_HandleScrollFlag3
	ld xwa, (xsp + 28)
	cp xwa, 0x1C00017
	jr nz, SmfFN_SetTrackFlag0
	stdi8 35146, 1
	jrl SmfFN_UpdateDisplay

SmfFN_SetTrackFlag0:
	stdi8 35146, 0
	jrl SmfFN_UpdateDisplay

SmfFN_HandleScrollFlag3:
	ld xwa, (xsp + 28)
	cp xiz, 0x17
	jr nz, SmfFN_HandleScrollFlag4
	cp xwa, 0x1C00017
	jr nz, SmfFN_SetTransposeFlag0
	stdi8 35148, 1
	jrl SmfFN_UpdateDisplay

SmfFN_SetTransposeFlag0:
	stdi8 35148, 0
	jrl SmfFN_UpdateDisplay

SmfFN_HandleScrollFlag4:
	cp xiz, 0x18
	jr nz, SmfFN_HandleSeqSongNum
	cp xwa, 0x1C00017
	jr nz, SmfFN_SetFlag35140_0
	stdi8 35140, 1
	jrl SmfFN_UpdateDisplay

SmfFN_SetFlag35140_0:
	stdi8 35140, 0
	jrl SmfFN_UpdateDisplay

SmfFN_HandleSeqSongNum:
	ldda8 c, 35144
	ld a, c
	inc 1, a
	cp xiz, 0x1E
	jr nz, SmfFN_HandleSeqFromSong
	cp a, 0xA
	jr nc, SmfFN_SeqToSong_Wrap
	inc 1, c
	stda8 35144, c
	ld xwa, (xsp + 32)
	ld xbc, 0x1C0000B
	lds32 xde, 0
	calr SmfSeqToSongNumFunc
	ld xwa, (xsp + 32)
	ld xbc, 0x1C0000B
	lds32 xde, 0
	jr SmfFN_SeqSongName_Dispatch

SmfFN_SeqToSong_Wrap:
	stdi8 35144, 0
	ld xwa, (xsp + 32)
	ld xbc, 0x1C0000B
	lds32 xde, 0
	calr SmfSeqToSongNumFunc
	ld xwa, (xsp + 32)
	ld xbc, 0x1C0000B
	lds32 xde, 0
	jr SmfFN_SeqSongName_Dispatch

SmfFN_HandleSeqFromSong:
	cp xiz, 0x1F
	jr nz, SmfFN_HandleMedleyConfirm
	cp a, 0xA
	jr nc, SmfFN_SeqFromSong_Wrap
	inc 1, c
	stda8 35144, c
	ld xwa, (xsp + 32)
	ld xbc, 0x1C0000B
	lds32 xde, 0
	calr SmfSeqFromSongNumFunc
	ld xwa, (xsp + 32)
	ld xbc, 0x1C0000B
	lds32 xde, 0
	jr SmfFN_SeqSongName_Dispatch

SmfFN_SeqFromSong_Wrap:
	stdi8 35144, 0
	ld xwa, (xsp + 32)
	ld xbc, 0x1C0000B
	lds32 xde, 0
	calr SmfSeqFromSongNumFunc
	ld xwa, (xsp + 32)
	ld xbc, 0x1C0000B
	lds32 xde, 0

SmfFN_SeqSongName_Dispatch:
	calr SmfSeqSongNameFunc
	jr SmfFN_UpdateDisplay

SmfFN_HandleMedleyConfirm:
	cp xiz, 0x28
	jr nz, SmfFN_UpdateDisplay
	cpdi16 33198, 0
	jr z, SmfFN_UpdateDisplay
	ldda32 xwa, 33188
	or xwa, xwa
	jr z, SmfFN_UpdateDisplay
	ld xbc, 0x1C0000A
	lds32 xde, 0

SmfFN_DispatchEvent:
	call 0xFA9D58

SmfFN_UpdateDisplay:
	ldda16 xhl, 33196

SmfFN_RefreshIfChanged:
	cp (xsp + 4), hl
	jrl z, SmfFN_SendOkState
	ld wa, hl
	call NavigateToFileIndex
	ldda16 xwa, 33196
	exts xwa
	divs wa, 0xA
	ldto_werp DE, 0xE2
	exts xde
	ldda32 xwa, 33184
	ld xbc, 0x1E50002
	call 0xFA9D58
	ldda16 xbc, 33196
	exts xbc
	divs bc, 0xA
	ld de, (xsp + 4)
	exts xde
	divs de, 0xA
	ldda32 xwa, 33184
	cp de, bc
	jr nz, SmfFN_RedrawPage
	ld bc, (xsp + 4)
	exts xbc
	divs bc, 0xA
	ldto_werp BC, 0xE6
	sll bc, 5
	ldada xhl, 34060
	ld de, bc
	extz xde
	add xde, xhl
	ld xbc, 0x1C0000F
	call 0xFA9D58
	ldda16 xwa, 33196
	exts xwa
	divs wa, 0xA
	ldto_werp WA, 0xE2
	sll wa, 5
	ldada xbc, 34060
	ld de, wa
	extz xde
	add xde, xbc
	ldda32 xwa, 33184
	ld xbc, 0x1C0000F
	call 0xFA9D58
	jr SmfFN_UpdateFilenameField

SmfFN_RedrawPage:
	muls bc, 0xA
	calr DisplaySmfFileList
	cpdi8 36150, 108
	jr nz, SmfFN_UpdateFilenameField
	ld xwa, (xsp + 32)
	ld xbc, 0x1C0000B
	lds32 xde, 0
	calr FmmSmfMedleyFunc

SmfFN_UpdateFilenameField:
	cpdi8 36150, 107
	jr nz, SmfFN_SendOkState
	ldada xiz, 34896
	ldda16 xwa, 33196
	cpda16 xwa, 34052
	jr lt, SmfFN_FetchFilename
	cps wa, 0
	jr le, SmfFN_FetchFilename
	ld xwa, xiz
	ld xbc, 0xEA0790
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
	ld xbc, 0x1C0000B
	lds32 xde, 0
	calr SaveFileNameSmfFunc

SmfFN_SendOkState:
	ldda32 xwa, 33184
	ld xbc, 0x1C50001
	lds32 xde, 0
	jr SmfFN_DispatchFinalEvent
	stda32 33188, xbc
	jrl SmfFN_ReturnZero
	stda32 33192, xbc
	jrl SmfFN_ReturnZero
	stda16 33198, xiz
	jrl SmfFN_ReturnZero
	cpdi8 34046, 0
	jrl z, SmfFN_ReturnZero
	ld wa, iz
	stda16 33196, xwa
	call NavigateToFileIndex
	ldda16 xwa, 33196
	exts xwa
	divs wa, 0xA
	ldto_werp DE, 0xE2
	exts xde
	ldda32 xwa, 33184
	ld xbc, 0x1E50002

SmfFN_DispatchFinalEvent:
	call 0xFA9D58
	jrl SmfFN_ReturnZero
	ldda16 xhl, 33196
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
	ldada xbc, 34060
	extz xde
	add xde, xbc
	ldto_berp A, 0xF8
	ld (xde), a
	ld wa, (xsp + 2)
	add wa, iz
	call LABEL_F8B13D
	ld xbc, xhl
	ld wa, iz
	sll wa, 5
	lds de, 1
	add de, wa
	ldada xhl, 34060
	ld wa, de
	extz xwa
	add xwa, xhl
	ld de, (xsp + 2)
	add de, iz
	inc 1, de
	pushw 0xC
	pushw 0x1
	call FileIO_ReadHeader_ParseLoop
	ld de, iz
	sll de, 5
	ldada xbc, 34060
	extz xde
	add xde, xbc
	ld xwa, (xsp + 4)
	ld xbc, 0x1C0000F
	call 0xFA9D58
	inc 1, iz
	cp iz, 0xA
	jr lt, DispSeqList_LoopBody
	popw iz
	inc 6, xsp
	ret

