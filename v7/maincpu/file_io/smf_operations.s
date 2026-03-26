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
	.incbin "includes/generated/v7_transplant_FmmSmfLoadTitleFunc.bin"
SmfLoad_DispatchState:
	.incbin "includes/generated/v7_transplant_SmfLoad_DispatchState.bin"
SmfLoad_CheckFileCount:
	.incbin "includes/generated/v7_transplant_SmfLoad_CheckFileCount.bin"
SmfLoad_CheckSlotCount:
	.incbin "includes/generated/v7_transplant_SmfLoad_CheckSlotCount.bin"
SmfLoad_AbortPartial:
	.incbin "includes/generated/v7_transplant_SmfLoad_AbortPartial.bin"
SmfLoad_ErrorCancel:
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0x7d
	jrl SmfLoad_CallHandler

SmfLoad_Success:
	.incbin "includes/generated/v7_transplant_SmfLoad_Success.bin"
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
	.incbin "includes/generated/v7_transplant_SmfLoad_HandleOk.bin"
SmfLoad_OkReturnCode:
	ldw wa, 0x60

SmfLoad_CallHandler:
	call UI_PostModeChangeEvent

SmfLoad_Return:
	lds32 xhl, 0
	ret

FmmSmfSaveTitleFunc:
	.incbin "includes/generated/v7_transplant_FmmSmfSaveTitleFunc.bin"
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
	stib_ind 0x07, 0xe0, 0xe4, 0x00
	lds ix, 0
	lda_24 xhl, (CharMap_FullPermutation_0x660)
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
	stb_dri B, 0x07, 0xe0, 0xf0
	ld c, (xde)
	cps c, 0
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
	.incbin "includes/generated/v7_transplant_SaveFileNameSmfFunc.bin"
SaveFN_HandleActivate:
	.incbin "includes/generated/v7_transplant_SaveFN_HandleActivate.bin"
SaveFN_HandleTextChange:
	.incbin "includes/generated/v7_transplant_SaveFN_HandleTextChange.bin"
SaveFN_SendEvent:
	call ApPostEvent
	jr SaveFN_Return

SaveFN_HandleApply:
	.incbin "includes/generated/v7_transplant_SaveFN_HandleApply.bin"
SaveFN_Return:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret

SmfSeqToSongNumFunc:
	.incbin "includes/generated/v7_transplant_SmfSeqToSongNumFunc.bin"
SeqToSong_BuildEntry:
	.incbin "includes/generated/v7_transplant_SeqToSong_BuildEntry.bin"
SeqToSong_Return:
	lds32 xhl, 0
	pop xiz
	ret

SmfSeqFromSongNumFunc:
	.incbin "includes/generated/v7_transplant_SmfSeqFromSongNumFunc.bin"
SeqFromSong_BuildEntry:
	.incbin "includes/generated/v7_transplant_SeqFromSong_BuildEntry.bin"
SeqFromSong_Return:
	lds32 xhl, 0
	pop xiz
	ret

SmfSeqSongNameFunc:
	.incbin "includes/generated/v7_transplant_SmfSeqSongNameFunc.bin"
SeqSongName_BuildEntry:
	.incbin "includes/generated/v7_transplant_SeqSongName_BuildEntry.bin"
SeqSongName_Return:
	lds32 xhl, 0
	ret

SmfLoadAsFunc:
	.incbin "includes/generated/v7_transplant_SmfLoadAsFunc.bin"
SmfLoadAs_Apply:
	.incbin "includes/generated/v7_transplant_SmfLoadAs_Apply.bin"
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
	lds wa, 0
	calr InitializeOperationState
	lds iz, 0

DispFileList_LoopBody:
	.incbin "includes/generated/v7_transplant_DispFileList_LoopBody.bin"
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
	ldb_sri E, 0x07, 0xe0, 0xf4
	cps e, 0
	jr z, ValidateFN_ReturnValid
	cp hl, bc
	jr c, ValidateFN_CheckSpace

ValidateFN_ReturnValid:
	ldb l, 0x1
	ret

FmmSmfFileNameFunc:
	.incbin "includes/generated/v7_transplant_FmmSmfFileNameFunc.bin"
SmfFN_JumpTable:
	.incbin "includes/generated/v7_transplant_SmfFN_JumpTable.bin"
SmfFN_HandleActivate:
	.incbin "includes/generated/v7_transplant_SmfFN_HandleActivate.bin"
SmfFN_ReturnZero:
	lds32 xhl, 0
	jrl SmfFN_Return

SmfFN_NavSetup:
	.incbin "includes/generated/v7_transplant_SmfFN_NavSetup.bin"
SmfFN_NavDown_WrapCheck:
	.incbin "includes/generated/v7_transplant_SmfFN_NavDown_WrapCheck.bin"
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
	.incbin "includes/generated/v7_transplant_SmfFN_PageUp.bin"
SmfFN_PageDown:
	.incbin "includes/generated/v7_transplant_SmfFN_PageDown.bin"
SmfFN_PageDown_WrapCheck:
	ld hl, bc
	inc 1, bc
	cp iy, bc
	jr ge, SmfFN_PageDown_ClampCheck

SmfFN_PageDown_Add10:
	add ix, 0xa

SmfFN_StoreIndex:
	.incbin "includes/generated/v7_transplant_SmfFN_StoreIndex.bin"
SmfFN_PageDown_ClampCheck:
	.incbin "includes/generated/v7_transplant_SmfFN_PageDown_ClampCheck.bin"
SmfFN_HandleSave:
	.incbin "includes/generated/v7_transplant_SmfFN_HandleSave.bin"
SmfFN_Save_WriteSlot:
	.incbin "includes/generated/v7_transplant_SmfFN_Save_WriteSlot.bin"
SmfFN_Save_Finish:
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 1
	call ApPostEvent
	cpdi16 0xf19e, 0
	jr z, SmfFN_Save_NoAltSlot
	ldw wa, 0xa
	jr SmfFN_Save_CallResult

SmfFN_Save_NoAltSlot:
	lds wa, 1

SmfFN_Save_CallResult:
	.incbin "includes/generated/v7_transplant_SmfFN_Save_CallResult.bin"
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
	cpib_da (0x0340ea), 0x00
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
	.incbin "includes/generated/v7_transplant_SmfFN_Open_Execute.bin"
SmfFN_HandleOpen2:
	.incbin "includes/generated/v7_transplant_SmfFN_HandleOpen2.bin"
SmfFN_HandleDelete:
	cp xiz, 0x5
	jrl nz, SmfFN_HandleDelete2
	cpib_da (0x0340ea), 0x00
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
	.incbin "includes/generated/v7_transplant_SmfFN_Delete_Execute.bin"
SmfFN_Delete_AdjustIndex:
	ldw wa, 0xee
	jr SmfFN_CallStatusDisplayAndExit

SmfFN_HandleDelete2:
	.incbin "includes/generated/v7_transplant_SmfFN_HandleDelete2.bin"
SmfFN_Delete2_AdjustIndex:
	ldw wa, 0xee

SmfFN_CallStatusDisplayAndExit:
	call SoundCtrl_SendCommand
	jrl SmfFN_UpdateDisplay

SmfFN_IgnoredEvents:
	.incbin "includes/generated/v7_transplant_SmfFN_IgnoredEvents.bin"
SmfFN_SetScrollDir0:
	.incbin "includes/generated/v7_transplant_SmfFN_SetScrollDir0.bin"
SmfFN_HandleScrollFlag1:
	.incbin "includes/generated/v7_transplant_SmfFN_HandleScrollFlag1.bin"
SmfFN_LoadAs_Wrap:
	.incbin "includes/generated/v7_transplant_SmfFN_LoadAs_Wrap.bin"
SmfFN_LoadAs_Apply:
	calr SmfLoadAsFunc
	jrl SmfFN_UpdateDisplay

SmfFN_HandleScrollFlag2:
	.incbin "includes/generated/v7_transplant_SmfFN_HandleScrollFlag2.bin"
SmfFN_SetTrackFlag0:
	.incbin "includes/generated/v7_transplant_SmfFN_SetTrackFlag0.bin"
SmfFN_HandleScrollFlag3:
	.incbin "includes/generated/v7_transplant_SmfFN_HandleScrollFlag3.bin"
SmfFN_SetTransposeFlag0:
	.incbin "includes/generated/v7_transplant_SmfFN_SetTransposeFlag0.bin"
SmfFN_HandleScrollFlag4:
	.incbin "includes/generated/v7_transplant_SmfFN_HandleScrollFlag4.bin"
SmfFN_SetFlag35140_0:
	.incbin "includes/generated/v7_transplant_SmfFN_SetFlag35140_0.bin"
SmfFN_HandleSeqSongNum:
	.incbin "includes/generated/v7_transplant_SmfFN_HandleSeqSongNum.bin"
SmfFN_SeqToSong_Wrap:
	.incbin "includes/generated/v7_transplant_SmfFN_SeqToSong_Wrap.bin"
SmfFN_HandleSeqFromSong:
	.incbin "includes/generated/v7_transplant_SmfFN_HandleSeqFromSong.bin"
SmfFN_SeqFromSong_Wrap:
	.incbin "includes/generated/v7_transplant_SmfFN_SeqFromSong_Wrap.bin"
SmfFN_SeqSongName_Dispatch:
	calr SmfSeqSongNameFunc
	jr SmfFN_UpdateDisplay

SmfFN_HandleMedleyConfirm:
	.incbin "includes/generated/v7_transplant_SmfFN_HandleMedleyConfirm.bin"
SmfFN_DispatchEvent:
	call ApPostEvent

SmfFN_UpdateDisplay:
	.incbin "includes/generated/v7_transplant_SmfFN_UpdateDisplay.bin"
SmfFN_RefreshIfChanged:
	.incbin "includes/generated/v7_transplant_SmfFN_RefreshIfChanged.bin"
SmfFN_RedrawPage:
	.incbin "includes/generated/v7_transplant_SmfFN_RedrawPage.bin"
SmfFN_UpdateFilenameField:
	.incbin "includes/generated/v7_transplant_SmfFN_UpdateFilenameField.bin"
SmfFN_FetchFilename:
	.incbin "includes/generated/v7_transplant_SmfFN_FetchFilename.bin"
SmfFN_WriteFilenameField:
	.incbin "includes/generated/v7_transplant_SmfFN_WriteFilenameField.bin"
SmfFN_SendOkState:
	.incbin "includes/generated/v7_transplant_SmfFN_SendOkState.bin"
SmfFN_DispatchFinalEvent:
	.incbin "includes/generated/v7_transplant_SmfFN_DispatchFinalEvent.bin"
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
	.incbin "includes/generated/v7_fix_dispseqlist_loopbody.bin"
