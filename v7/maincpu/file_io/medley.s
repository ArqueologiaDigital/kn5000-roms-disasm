; =============================================================================
; file_io/medley.asm - Medley Playback Operations
; =============================================================================
; All medley playback modes: internal, disk, SMF, performance data, document.
;
; Key routines:
;   FmmSeqSongNameFunc               - Sequence song name
;   FmmIntMedleyFunc                 - Internal medley
;   FmmDiskMedley1Func               - Disk medley 1
;   FmmDiskMedley2Func               - Disk medley 2
;   FmmDiskMedleySelectFunc          - Disk medley selection
;   FmmSmfMedleyFunc                 - SMF medley
;   FmmPdFileNameFunc                - Performance data filename
;   FmmPdMedleyFunc                  - Performance data medley
;   DocDiskNameFunc                  - Document disk name
;   FmmDocFileNameFunc               - Document filename
;   FmmDocMedleyFunc                 - Document medley
; =============================================================================

FmmSeqSongNameFunc:
	.incbin "includes/generated/v7_transplant_FmmSeqSongNameFunc.bin"
SeqName_SendCurrentIndex:
	.incbin "includes/generated/v7_transplant_SeqName_SendCurrentIndex.bin"
SeqName_InitAllSlots:
	lds iz, 0

SeqName_SendSlotLoop:
	.incbin "includes/generated/v7_transplant_SeqName_SendSlotLoop.bin"
SeqName_ReturnZero:
	lds32 xhl, 0
	jrl SeqName_Exit

SeqName_HandleNavigation:
	.incbin "includes/generated/v7_transplant_SeqName_HandleNavigation.bin"
SeqName_CheckPrevKey:
	cp xbc, 0x1c00017
	jrl nz, SeqName_GetCurrentIndex
	cps wa, 0
	jrl z, SeqName_GetCurrentIndex
	dec 1, wa

SeqName_UpdateIndex:
	.incbin "includes/generated/v7_transplant_SeqName_UpdateIndex.bin"
SeqName_HandlePlayAction:
	.incbin "includes/generated/v7_transplant_SeqName_HandlePlayAction.bin"
SeqName_CheckDiskAvail:
	call CheckFileSystemStatus
	cps hl, 0
	jr z, SeqName_LoadAndPlay
	cpib_da (0x0340ea), 0x00
	jr z, SeqName_LoadAndPlay
	ld xwa, 0xffffffff
	ld xbc, 0x1c50000
	lds32 xde, 1
	call ApPostEvent
	ld xwa, 0x600037
	ld xbc, 0x1c00001
	lds32 xde, 0

SeqName_PostAndExit:
	call ApPostEvent
	jrl SeqName_GetCurrentIndex

SeqName_LoadAndPlay:
	.incbin "includes/generated/v7_transplant_SeqName_LoadAndPlay.bin"
SeqName_HandleAction32:
	.incbin "includes/generated/v7_transplant_SeqName_HandleAction32.bin"
SeqName_ShowAndExit:
	call SoundCtrl_SendCommand

SeqName_GetCurrentIndex:
	.incbin "includes/generated/v7_transplant_SeqName_GetCurrentIndex.bin"
SeqName_UpdateDisplay:
	.incbin "includes/generated/v7_transplant_SeqName_UpdateDisplay.bin"
SeqName_SetIndexPlaying:
	.incbin "includes/generated/v7_transplant_SeqName_SetIndexPlaying.bin"
SeqName_PostEventExit:
	call ApPostEvent
	jrl SeqName_ReturnZero

SeqName_GetIndexReturn:
	.incbin "includes/generated/v7_transplant_SeqName_GetIndexReturn.bin"
SeqName_Exit:
	popw iz
	ret

FormatMedleyNumber:
	lda_dpi XIY, 0xe0
	cp c, 0xff
	jr nz, FmtNum_CheckMarked
	ldb c, 0x20
	jr FmtNum_WriteSpacePad

FmtNum_CheckMarked:
	cp c, 0xfe
	jr nz, FmtNum_FormatNumber
	ldb c, 0x4d

FmtNum_WriteSpacePad:
	lda_dpi XHL, 0xe0
	stib_dsp 0xe0, 0x20
	ld (xwa), 0x20
	ret

FmtNum_FormatNumber:
	inc 1, c
	cp c, 0x64
	jr c, FmtNum_WriteM
	stb_dpi C, 0xe0
	ld e, c
	extz de
	div e, 0x64
	add e, 0x30
	ld (xhl), e
	extz bc
	div c, 0x64
	ld c, b
	jr FmtNum_WriteTensUnits

FmtNum_WriteM:
	stib_dsp 0xe0, 0x4d

FmtNum_WriteTensUnits:
	cp c, 0xa
	jr nc, FmtNum_WriteTwoDigits
	stib_dsp 0xe0, 0x30
	add c, 0x30
	ld (xwa), c
	ret

FmtNum_WriteTwoDigits:
	stb_dpi C, 0xe0
	ld e, c
	extz de
	div e, 0xa
	add e, 0x30
	ld (xhl), e
	extz bc
	div c, 0xa
	ld c, b
	add c, 0x30
	ld (xwa), c
	ret

FmmIntMedleyFunc:
	.incbin "includes/generated/v7_transplant_FmmIntMedleyFunc.bin"
IntMed_CheckSlotLoop:
	.incbin "includes/generated/v7_transplant_IntMed_CheckSlotLoop.bin"
IntMed_MarkSlotEmpty:
	.incbin "includes/generated/v7_transplant_IntMed_MarkSlotEmpty.bin"
IntMed_NextSlot:
	.incbin "includes/generated/v7_transplant_IntMed_NextSlot.bin"
IntMed_CheckPlaying:
	.incbin "includes/generated/v7_transplant_IntMed_CheckPlaying.bin"
IntMed_FindCurrentSong:
	.incbin "includes/generated/v7_transplant_IntMed_FindCurrentSong.bin"
IntMed_NextSongSearch:
	inc 1, iz
	cp iz, 0xa
	jr c, IntMed_FindCurrentSong
	jrl IntMed_Exit

IntMed_CheckRepeat:
	.incbin "includes/generated/v7_transplant_IntMed_CheckRepeat.bin"
IntMed_PlayFromStart:
	.incbin "includes/generated/v7_transplant_IntMed_PlayFromStart.bin"
IntMed_PostDelayEvent:
	call ApPostEvent
	jrl IntMed_Exit

IntMed_NextSongLoop:
	inc 1, iz
	cp iz, 0xa
	jr c, IntMed_PlayFromStart
	jrl IntMed_Exit

IntMed_ClearPlayFlag:
	.incbin "includes/generated/v7_transplant_IntMed_ClearPlayFlag.bin"
IntMed_HandleError:
	.incbin "includes/generated/v7_transplant_IntMed_HandleError.bin"
IntMed_HandleStop:
	.incbin "includes/generated/v7_transplant_IntMed_HandleStop.bin"
IntMed_StoreWindowPtr:
	.incbin "includes/generated/v7_transplant_IntMed_StoreWindowPtr.bin"
IntMed_InitSlotDisplay:
	lds iz, 0

IntMed_FormatSlotLoop:
	.incbin "includes/generated/v7_transplant_IntMed_FormatSlotLoop.bin"
IntMed_HandleNavToggle:
	.incbin "includes/generated/v7_transplant_IntMed_HandleNavToggle.bin"
IntMed_FindMarkedSlot:
	ld bc, iz
	extz xbc
	add xbc, xwa
	cp (xbc), 0xfe
	jr z, IntMed_CheckAllMarked
	inc 1, iz
	cp iz, 0xa
	jr c, IntMed_FindMarkedSlot

IntMed_CheckAllMarked:
	cp iz, 0xa
	jr nc, IntMed_RemoveOrderLoop
	lds iz, 0

IntMed_AssignOrderLoop:
	.incbin "includes/generated/v7_transplant_IntMed_AssignOrderLoop.bin"
IntMed_NextAssignSlot:
	inc 1, iz
	cp iz, 0xa
	jr c, IntMed_AssignOrderLoop
	jrl IntMed_Exit

IntMed_RemoveOrderLoop:
	lds iz, 0

IntMed_UnmarkSlotLoop:
	.incbin "includes/generated/v7_transplant_IntMed_UnmarkSlotLoop.bin"
IntMed_NextUnmark:
	inc 1, iz
	cp iz, 0xa
	jr c, IntMed_UnmarkSlotLoop
	jrl IntMed_Exit

IntMed_HandleSelectToggle:
	.incbin "includes/generated/v7_transplant_IntMed_HandleSelectToggle.bin"
IntMed_RemoveFromOrder:
	.incbin "includes/generated/v7_transplant_IntMed_RemoveFromOrder.bin"
IntMed_ReorderLoop:
	.incbin "includes/generated/v7_transplant_IntMed_ReorderLoop.bin"
IntMed_NextReorder:
	.incbin "includes/generated/v7_transplant_IntMed_NextReorder.bin"
IntMed_HandleRepeatToggle:
	.incbin "includes/generated/v7_transplant_IntMed_HandleRepeatToggle.bin"
IntMed_SetRepeatOff:
	.incbin "includes/generated/v7_transplant_IntMed_SetRepeatOff.bin"
IntMed_HandlePlay:
	.incbin "includes/generated/v7_transplant_IntMed_HandlePlay.bin"
IntMed_StartPlayLoop:
	.incbin "includes/generated/v7_transplant_IntMed_StartPlayLoop.bin"
IntMed_NextPlaySlot:
	inc 1, iz
	cp iz, 0xa
	jr c, IntMed_StartPlayLoop
	jr IntMed_Exit

IntMed_StoreDelayFlag:
	.incbin "includes/generated/v7_transplant_IntMed_StoreDelayFlag.bin"
IntMed_CheckContinue:
	.incbin "includes/generated/v7_transplant_IntMed_CheckContinue.bin"
IntMed_Exit:
	lds32 xhl, 0
	popw iz
	inc 8, xsp
	ret

FmmDiskMedley1Func:
	.incbin "includes/generated/v7_transplant_FmmDiskMedley1Func.bin"
DiskMed1_InitLoop:
	lds iz, 0

DiskMed1_FormatLoop:
	.incbin "includes/generated/v7_transplant_DiskMed1_FormatLoop.bin"
DiskMed1_Exit:
	lds32 xhl, 0
	popw iz
	ret

FmmDiskMedley2Func:
	.incbin "includes/generated/v7_transplant_FmmDiskMedley2Func.bin"
DiskMed2_InitLoop:
	ldw iz, 0xa

DiskMed2_FormatLoop:
	.incbin "includes/generated/v7_transplant_DiskMed2_FormatLoop.bin"
DiskMed2_Exit:
	lds32 xhl, 0
	popw iz
	ret

DiskMed_PlayNextHelper:
	.incbin "includes/generated/v7_transplant_DiskMed_PlayNextHelper.bin"
DiskMed_FindSongLoop:
	ld de, iz
	extz xde
	add xde, xbc
	cp (xde), a
	jr nz, DiskMed_NextSong
	stb_erp A, 0xf8
	extz wa
	jrl DiskMed_PlaySong

DiskMed_NextSong:
	inc 1, iz
	cp iz, 0xa
	jr c, DiskMed_FindSongLoop
	jrl DiskMed_ReturnZero

DiskMed_ReturnFinished:
	lds32 xhl, 2
	jrl DiskMed_HelperExit

DiskMed_InitPlayOrder:
	.incbin "includes/generated/v7_transplant_DiskMed_InitPlayOrder.bin"
DiskMed_CheckSlotLoop:
	.incbin "includes/generated/v7_transplant_DiskMed_CheckSlotLoop.bin"
DiskMed_MarkUnused:
	ld (xwa), 0xff

DiskMed_NextSlotCheck:
	.incbin "includes/generated/v7_transplant_DiskMed_NextSlotCheck.bin"
DiskMed_AssignOrder:
	.incbin "includes/generated/v7_transplant_DiskMed_AssignOrder.bin"
DiskMed_NextAssign:
	inc 1, xbc
	cp xbc, xde
	jr c, DiskMed_AssignOrder
	lds iz, 0

DiskMed_FindFirstSong:
	.incbin "includes/generated/v7_transplant_DiskMed_FindFirstSong.bin"
DiskMed_NextFirst:
	inc 1, iz
	cp iz, 0xa
	jr c, DiskMed_FindFirstSong
	jr DiskMed_ReturnZero

DiskMed_SingleSlotCheck:
	.incbin "includes/generated/v7_transplant_DiskMed_SingleSlotCheck.bin"
DiskMed_SingleSlotInit:
	lds iz, 0

DiskMed_FindFirstLoop:
	.incbin "includes/generated/v7_transplant_DiskMed_FindFirstLoop.bin"
DiskMed_PlaySong:
	.incbin "includes/generated/v7_transplant_DiskMed_PlaySong.bin"
DiskMed_NextFindFirst:
	inc 1, iz
	cp iz, 0xa
	jr c, DiskMed_FindFirstLoop

DiskMed_ReturnZero:
	lds32 xhl, 0

DiskMed_HelperExit:
	popw iz
	ret

FmmDiskMedleySelectFunc:
	.incbin "includes/generated/v7_transplant_FmmDiskMedleySelectFunc.bin"
DiskSel_InitState:
	.incbin "includes/generated/v7_transplant_DiskSel_InitState.bin"
DiskSel_CheckFileLoop:
	ld wa, iz
	lds bc, 2
	call FileIO_CheckRecordByFile
	cps l, 0
	jr nz, DiskSel_FileAvailable
	ld wa, iz
	ldw bc, 0x8
	call FileIO_CheckRecordByFile
	cps l, 0
	jr z, DiskSel_MarkUnavail

DiskSel_FileAvailable:
	.incbin "includes/generated/v7_transplant_DiskSel_FileAvailable.bin"
DiskSel_MarkUnavail:
	.incbin "includes/generated/v7_transplant_DiskSel_MarkUnavail.bin"
DiskSel_NextFile:
	inc 1, iz
	cp iz, 0x14
	jr lt, DiskSel_CheckFileLoop
	call CDlike_InitModeAndLoadBank
	jrl DiskSel_Exit

DiskSel_CheckPlaying:
	.incbin "includes/generated/v7_transplant_DiskSel_CheckPlaying.bin"
DiskSel_CheckFinished:
	.incbin "includes/generated/v7_transplant_DiskSel_CheckFinished.bin"
DiskSel_ClearSelections:
	stb_erp A, 0xf8
	extz wa
	call FileIO_FormatName_Loop
	inc 1, iz
	cp iz, 0x8
	jr lt, DiskSel_ClearSelections
	lds iz, 0

DiskSel_FindSongLoop:
	.incbin "includes/generated/v7_transplant_DiskSel_FindSongLoop.bin"
DiskSel_SendFileInfo:
	.incbin "includes/generated/v7_transplant_DiskSel_SendFileInfo.bin"
DiskSel_PlayNext:
	.incbin "includes/generated/v7_transplant_DiskSel_PlayNext.bin"
DiskSel_NextSongLoop:
	inc 1, iz
	cp iz, 0x14
	jrl lt, DiskSel_FindSongLoop

DiskSel_ClearPlaying:
	.incbin "includes/generated/v7_transplant_DiskSel_ClearPlaying.bin"
DiskSel_CheckRepeat:
	.incbin "includes/generated/v7_transplant_DiskSel_CheckRepeat.bin"
DiskSel_RepeatClear:
	stb_erp A, 0xf8
	extz wa
	call FileIO_FormatName_Loop
	inc 1, iz
	cp iz, 0x8
	jr lt, DiskSel_RepeatClear
	lds iz, 0

DiskSel_RepeatFindLoop:
	.incbin "includes/generated/v7_transplant_DiskSel_RepeatFindLoop.bin"
DiskSel_RepeatSendInfo:
	.incbin "includes/generated/v7_transplant_DiskSel_RepeatSendInfo.bin"
DiskSel_RepeatPlayNext:
	.incbin "includes/generated/v7_transplant_DiskSel_RepeatPlayNext.bin"
DiskSel_CallPauseMode:
	call UI_PostModeChangeEvent
	jrl DiskSel_Exit

DiskSel_RepeatNext:
	inc 1, iz
	cp iz, 0x14
	jrl lt, DiskSel_RepeatFindLoop
	jrl DiskSel_Exit

DiskSel_HandleError:
	.incbin "includes/generated/v7_transplant_DiskSel_HandleError.bin"
DiskSel_ShowError:
	.incbin "includes/generated/v7_transplant_DiskSel_ShowError.bin"
DiskSel_HandleStopEvent:
	.incbin "includes/generated/v7_transplant_DiskSel_HandleStopEvent.bin"
DiskSel_PostStopEvent:
	calr CancelOperationCleanup
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	jrl DiskSel_PostEvent

DiskSel_StoreWindowPtr:
	.incbin "includes/generated/v7_transplant_DiskSel_StoreWindowPtr.bin"
DiskSel_DefaultIndex:
	.incbin "includes/generated/v7_transplant_DiskSel_DefaultIndex.bin"
DiskSel_InitDisplay:
	lds iz, 0

DiskSel_DisplayLoop:
	.incbin "includes/generated/v7_transplant_DiskSel_DisplayLoop.bin"
DiskSel_GetFileName:
	call GetFileEntryPtr
	ld xbc, xhl
	jr DiskSel_FormatEntry

DiskSel_EmptyFileName:
	lda_24 xbc, (Data_SaveLoadMenuTable_0x64)

DiskSel_FormatEntry:
	.incbin "includes/generated/v7_transplant_DiskSel_FormatEntry.bin"
DiskSel_HandleNavigation:
	.incbin "includes/generated/v7_transplant_DiskSel_HandleNavigation.bin"
DiskSel_CheckPrevKey:
	cp xwa, 0x1c00017
	jrl nz, DiskSel_GetCurrentIndex
	cps de, 0
	jrl le, DiskSel_GetCurrentIndex
	dec 1, de
	jr DiskSel_SaveIndex

DiskSel_CheckPage:
	.incbin "includes/generated/v7_transplant_DiskSel_CheckPage.bin"
DiskSel_CheckPageDown:
	.incbin "includes/generated/v7_transplant_DiskSel_CheckPageDown.bin"
DiskSel_SaveIndex:
	.incbin "includes/generated/v7_transplant_DiskSel_SaveIndex.bin"
DiskSel_HandleToggle:
	.incbin "includes/generated/v7_transplant_DiskSel_HandleToggle.bin"
DiskSel_FindMarkedLoop:
	cpib_sri 0x07, 0xec, 0xf8, 0xfe
	jr z, DiskSel_ToggleStart
	inc 1, iz
	cp iz, 0x14
	jr lt, DiskSel_FindMarkedLoop

DiskSel_ToggleStart:
	lda xde, (xhl + 20)
	cp iz, 0x14
	jr ge, DiskSel_UnmarkLoop

DiskSel_AssignLoop:
	.incbin "includes/generated/v7_transplant_DiskSel_AssignLoop.bin"
DiskSel_NextAssign:
	inc 1, xhl
	cp xhl, xde
	jr c, DiskSel_AssignLoop
	jr DiskSel_RefreshDisplay

DiskSel_UnmarkLoop:
	.incbin "includes/generated/v7_transplant_DiskSel_UnmarkLoop.bin"
DiskSel_NextUnmark:
	inc 1, xhl
	cp xhl, xde
	jr c, DiskSel_UnmarkLoop

DiskSel_RefreshDisplay:
	lds32 xwa, 0
	ld xbc, 0x1c0000b
	lds32 xde, 0
	calr FmmDiskMedley1Func
	lds32 xwa, 0
	ld xbc, 0x1c0000b
	lds32 xde, 0
	jr DiskSel_RefreshBoth

DiskSel_HandleSelect:
	.incbin "includes/generated/v7_transplant_DiskSel_HandleSelect.bin"
DiskSel_RemoveSelect:
	.incbin "includes/generated/v7_transplant_DiskSel_RemoveSelect.bin"
DiskSel_ReorderSlots:
	ld xde, xix
	lda xhl, (xix + 20)

DiskSel_ReorderLoop:
	ld c, (xde)
	cp c, 0xfd
	jr ugt, DiskSel_NextReorder
	cp c, a
	jr ule, DiskSel_NextReorder
	dec 1, c
	ld (xde), c

DiskSel_NextReorder:
	inc 1, xde
	cp xde, xhl
	jr c, DiskSel_ReorderLoop

DiskSel_RefreshAfterSelect:
	lds32 xwa, 0
	ld xbc, 0x1c0000b
	lds32 xde, 0
	calr FmmDiskMedley1Func
	lds32 xwa, 0
	ld xbc, 0x1c0000b
	lds32 xde, 0

DiskSel_RefreshBoth:
	calr FmmDiskMedley2Func
	jrl DiskSel_GetCurrentIndex

DiskSel_HandleRepeat:
	.incbin "includes/generated/v7_transplant_DiskSel_HandleRepeat.bin"
DiskSel_SetRepeatOff:
	.incbin "includes/generated/v7_transplant_DiskSel_SetRepeatOff.bin"
DiskSel_HandlePlayStart:
	.incbin "includes/generated/v7_transplant_DiskSel_HandlePlayStart.bin"
DiskSel_PlayClearLoop:
	stb_erp A, 0xf8
	extz wa
	call FileIO_FormatName_Loop
	inc 1, iz
	cp iz, 0x8
	jr lt, DiskSel_PlayClearLoop
	lds iz, 0

DiskSel_PlayFindLoop:
	.incbin "includes/generated/v7_transplant_DiskSel_PlayFindLoop.bin"
DiskSel_ShowErrorAndExit:
	call SoundCtrl_SendCommand
	jrl DiskSel_Exit

DiskSel_PlayNextSong:
	.incbin "includes/generated/v7_transplant_DiskSel_PlayNextSong.bin"
DiskSel_PlayNextLoop:
	inc 1, iz
	cp iz, 0x14
	jrl lt, DiskSel_PlayFindLoop
	jr DiskSel_GetCurrentIndex

DiskSel_HandleAllCheck:
	.incbin "includes/generated/v7_transplant_DiskSel_HandleAllCheck.bin"
DiskSel_SetAllOff:
	.incbin "includes/generated/v7_transplant_DiskSel_SetAllOff.bin"
DiskSel_GetCurrentIndex:
	.incbin "includes/generated/v7_transplant_DiskSel_GetCurrentIndex.bin"
DiskSel_UpdateDisplay:
	.incbin "includes/generated/v7_transplant_DiskSel_UpdateDisplay.bin"
DiskSel_PostEvent:
	call ApPostEvent

DiskSel_Exit:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 14)
	ret

GetPlayState1_Entry:
GetPlayState1:
	.incbin "includes/generated/v7_transplant_GetPlayState1.bin"
GetPlayState2_Entry:
GetPlayState2:
	.incbin "includes/generated/v7_transplant_GetPlayState2.bin"
SmfMedley_RawData:
	.incbin "includes/generated/v7_transplant_SmfMedley_RawData.bin"
NavigateSongList_Entry:
NavigateSongList:
	dec 2, xsp
	pushw iz
	ld (xsp + 2), wa
	cpw (xsp + 2), 0x1
	jr z, NavSong_CheckBounds
	cpw (xsp + 2), 0xffff
	jr nz, NavSong_Exit

NavSong_CheckBounds:
	.incbin "includes/generated/v7_transplant_NavSong_CheckBounds.bin"
NavSong_WrapToEnd:
	.incbin "includes/generated/v7_transplant_NavSong_WrapToEnd.bin"
NavSong_CheckEnd:
	cp hl, iz
	jr z, NavSong_Exit
	ld wa, iz
	call NavigateToFileIndex
	ld wa, iz
	call GetFileEntryByIndex

NavSong_Exit:
	popw iz
	inc 2, xsp
	ret

NavigateDocList_Entry:
NavigateDocList:
	pushw iz
	ld iz, wa
	cps iz, 1
	jr z, NavDoc_CheckBounds
	cp iz, 0xffff
	jr nz, NavDoc_Exit

NavDoc_CheckBounds:
	.incbin "includes/generated/v7_transplant_NavDoc_CheckBounds.bin"
NavDoc_WrapToEnd:
	.incbin "includes/generated/v7_transplant_NavDoc_WrapToEnd.bin"
NavDoc_CheckEnd:
	cp hl, wa
	call_24 nz, FileIO_SelectFileByIndex

NavDoc_Exit:
	popw iz
	ret

NavigatePdList_Entry:
NavigatePdList:
	pushw iz
	ld iz, wa
	cps iz, 1
	jr z, NavPd_CheckBounds
	cp iz, 0xffff
	jr nz, NavPd_Exit

NavPd_CheckBounds:
	.incbin "includes/generated/v7_transplant_NavPd_CheckBounds.bin"
NavPd_WrapToEnd:
	.incbin "includes/generated/v7_transplant_NavPd_WrapToEnd.bin"
NavPd_CheckEnd:
	cp hl, wa
	call_24 nz, SetCurrentFileIndex

NavPd_Exit:
	popw iz
	ret

SmfMed_FormatSlotList:
	dec 6, xsp
	push xiz
	ld iz, bc
	ld (xsp + 6), xwa
	lds32 xwa, 0
	ld xbc, 0x1e50003
	lds32 xde, 0
	calr FmmSmfFileNameFunc
	ldw_erp HL, 0xfa
	stw_erp WA, 0xfa
	extz xwa
	div wa, 0xa
	ldw_erp WA, 0xfa
	mul wa, 0xa
	ldw_erp WA, 0xfa
	ldw (xsp + 4), 0xa
	stw_erp WA, 0xfa
	add wa, 0xa
	cp wa, iz
	jr c, SmfFmt_CalcVisible
	ld (xsp + 4), iz
	stw_erp WA, 0xfa
	sub (xsp + 4), wa

SmfFmt_CalcVisible:
	lds iz, 0
	cpw (xsp + 4), 0x0
	jr ule, SmfFmt_FillEmpty

SmfFmt_FormatLoop:
	.incbin "includes/generated/v7_transplant_SmfFmt_FormatLoop.bin"
SmfFmt_FillEmpty:
	cp iz, 0xa
	jr nc, SmfFmt_Exit

SmfFmt_EmptyLoop:
	.incbin "includes/generated/v7_transplant_SmfFmt_EmptyLoop.bin"
SmfFmt_Exit:
	pop xiz
	inc 6, xsp
	ret

FmmSmfMedleyFunc:
	.incbin "includes/generated/v7_transplant_FmmSmfMedleyFunc.bin"
SmfMed_CheckNotPlaying:
	.incbin "includes/generated/v7_transplant_SmfMed_CheckNotPlaying.bin"
SmfMed_Error31:
	.incbin "includes/generated/v7_transplant_SmfMed_Error31.bin"
SmfMed_Error3F:
	.incbin "includes/generated/v7_transplant_SmfMed_Error3F.bin"
SmfMed_ShowError:
	call SoundCtrl_SendCommand
	jrl SmfMed_Exit

SmfMed_CheckPlayMode:
	cp a, 0x73
	jr z, SmfMed_CheckPlaying
	cp a, 0x76
	jrl nz, SmfMed_InitFromDisk

SmfMed_CheckPlaying:
	.incbin "includes/generated/v7_transplant_SmfMed_CheckPlaying.bin"
SmfMed_PlayError31:
	.incbin "includes/generated/v7_transplant_SmfMed_PlayError31.bin"
SmfMed_PlayError3F:
	.incbin "includes/generated/v7_transplant_SmfMed_PlayError3F.bin"
SmfMed_ShowPlayError:
	.incbin "includes/generated/v7_transplant_SmfMed_ShowPlayError.bin"
SmfMed_SetPlaying:
	.incbin "includes/generated/v7_transplant_SmfMed_SetPlaying.bin"
SmfMed_FindSongLoop:
	.incbin "includes/generated/v7_transplant_SmfMed_FindSongLoop.bin"
SmfMed_NextSong:
	inc 1, iz
	cp iz, bc
	jr c, SmfMed_FindSongLoop
	jrl SmfMed_Exit

SmfMed_CheckRepeat:
	.incbin "includes/generated/v7_transplant_SmfMed_CheckRepeat.bin"
SmfMed_RepeatFindLoop:
	.incbin "includes/generated/v7_transplant_SmfMed_RepeatFindLoop.bin"
SmfMed_PostDelayEvent:
	call ApPostEvent
	jrl SmfMed_Exit

SmfMed_RepeatNext:
	inc 1, iz
	cp iz, wa
	jr c, SmfMed_RepeatFindLoop
	jrl SmfMed_Exit

SmfMed_ClearRepeatCount:
	.incbin "includes/generated/v7_transplant_SmfMed_ClearRepeatCount.bin"
SmfMed_CheckNotPlayError:
	call Medley_GetPlaybackStatus
	cps l, 0
	jrl nz, SmfMed_Exit

SmfMed_ClearPlaying:
	.incbin "includes/generated/v7_transplant_SmfMed_ClearPlaying.bin"
SmfMed_InitFromDisk:
	.incbin "includes/generated/v7_transplant_SmfMed_InitFromDisk.bin"
SmfMed_InitState:
	.incbin "includes/generated/v7_transplant_SmfMed_InitState.bin"
SmfMed_ClampFileCount:
	.incbin "includes/generated/v7_transplant_SmfMed_ClampFileCount.bin"
SmfMed_ClearSlotsLoop:
	.incbin "includes/generated/v7_transplant_SmfMed_ClearSlotsLoop.bin"
SmfMed_FinishInit:
	.incbin "includes/generated/v7_transplant_SmfMed_FinishInit.bin"
SmfMed_HandleStop_Entry:
SmfMed_HandleStop:
	.incbin "includes/generated/v7_transplant_SmfMed_HandleStop.bin"
SmfMed_StoreWindowPtr:
	.incbin "includes/generated/v7_transplant_SmfMed_StoreWindowPtr.bin"
SmfMed_RefreshDisplay:
	.incbin "includes/generated/v7_transplant_SmfMed_RefreshDisplay.bin"
SmfMed_HandleNavToggle:
	.incbin "includes/generated/v7_transplant_SmfMed_HandleNavToggle.bin"
SmfMed_FindUnmarkedLoop:
	ld bc, iz
	extz xbc
	add xbc, xwa
	cp (xbc), 0xff
	jr z, SmfMed_CheckAllUnmarked
	inc 1, iz
	cp iz, de
	jr c, SmfMed_FindUnmarkedLoop

SmfMed_CheckAllUnmarked:
	.incbin "includes/generated/v7_transplant_SmfMed_CheckAllUnmarked.bin"
SmfMed_AssignOrderLoop:
	.incbin "includes/generated/v7_transplant_SmfMed_AssignOrderLoop.bin"
SmfMed_NextAssign:
	.incbin "includes/generated/v7_transplant_SmfMed_NextAssign.bin"
SmfMed_RemoveOrderLoop:
	.incbin "includes/generated/v7_transplant_SmfMed_RemoveOrderLoop.bin"
SmfMed_UnmarkLoop:
	.incbin "includes/generated/v7_transplant_SmfMed_UnmarkLoop.bin"
SmfMed_NextUnmark:
	.incbin "includes/generated/v7_transplant_SmfMed_NextUnmark.bin"
SmfMed_RefreshAfterToggle:
	.incbin "includes/generated/v7_transplant_SmfMed_RefreshAfterToggle.bin"
SmfMed_HandleSelectToggle:
	.incbin "includes/generated/v7_transplant_SmfMed_HandleSelectToggle.bin"
SmfMed_RemoveFromOrder:
	.incbin "includes/generated/v7_transplant_SmfMed_RemoveFromOrder.bin"
SmfMed_ReorderLoop:
	ld de, iz
	extz xde
	add xde, xhl
	ld a, (xde)
	cp a, 0xfd
	jr ugt, SmfMed_NextReorder
	inc 1, iy
	cp a, c
	jr ule, SmfMed_NextReorder
	dec 1, a
	ld (xde), a

SmfMed_NextReorder:
	inc 1, iz
	cp iy, ix
	jr c, SmfMed_ReorderLoop

SmfMed_RefreshAfterSelect:
	.incbin "includes/generated/v7_transplant_SmfMed_RefreshAfterSelect.bin"
SmfMed_CallFormatSlots:
	calr SmfMed_FormatSlotList
	jrl SmfMed_Exit

SmfMed_HandleRepeat:
	.incbin "includes/generated/v7_transplant_SmfMed_HandleRepeat.bin"
SmfMed_SetRepeatOff:
	.incbin "includes/generated/v7_transplant_SmfMed_SetRepeatOff.bin"
SmfMed_HandlePlay:
	.incbin "includes/generated/v7_transplant_SmfMed_HandlePlay.bin"
SmfMed_PlayFindLoop:
	.incbin "includes/generated/v7_transplant_SmfMed_PlayFindLoop.bin"
SmfMed_PlayNextLoop:
	inc 1, iz
	cp iz, bc
	jr c, SmfMed_PlayFindLoop

SmfMed_CheckAutoPlay:
	.incbin "includes/generated/v7_transplant_SmfMed_CheckAutoPlay.bin"
SmfMed_StoreDelayFlag:
	.incbin "includes/generated/v7_transplant_SmfMed_StoreDelayFlag.bin"
SmfMed_CheckContinue:
	.incbin "includes/generated/v7_transplant_SmfMed_CheckContinue.bin"
SmfMed_CallPauseMode:
	call UI_PostModeChangeEvent

SmfMed_Exit:
	lds32 xhl, 0
	popw iz
	inc 4, xsp
	ret

PdMed_FormatFileList_Entry:
PdMed_FormatFileList:
	dec 6, xsp
	pushw iz
	ld (xsp + 2), bc
	ld (xsp + 4), xwa
	lds iz, 0

PdFmt_FormatLoop:
	.incbin "includes/generated/v7_transplant_PdFmt_FormatLoop.bin"
FmmPdFileNameFunc:
	.incbin "includes/generated/v7_transplant_FmmPdFileNameFunc.bin"
PdName_UpdateIndex:
	.incbin "includes/generated/v7_transplant_PdName_UpdateIndex.bin"
PdName_RefreshList:
	.incbin "includes/generated/v7_transplant_PdName_RefreshList.bin"
PdName_ReturnZero:
	lds32 xhl, 0
	jrl PdName_Exit

PdName_HandleNavigation:
	.incbin "includes/generated/v7_transplant_PdName_HandleNavigation.bin"
PdName_CheckPrevKey:
	cp xbc, 0x1c00017
	jr nz, PdName_GetCurrentIndex
	cps wa, 0
	jr le, PdName_GetCurrentIndex
	dec 1, wa
	jr PdName_SaveIndex

PdName_CheckPageUp:
	.incbin "includes/generated/v7_transplant_PdName_CheckPageUp.bin"
PdName_CheckPageDown:
	.incbin "includes/generated/v7_transplant_PdName_CheckPageDown.bin"
PdName_SaveIndex:
	.incbin "includes/generated/v7_transplant_PdName_SaveIndex.bin"
PdName_CheckEndBound:
	.incbin "includes/generated/v7_transplant_PdName_CheckEndBound.bin"
PdName_GetCurrentIndex:
	.incbin "includes/generated/v7_transplant_PdName_GetCurrentIndex.bin"
PdName_UpdateDisplay:
	.incbin "includes/generated/v7_transplant_PdName_UpdateDisplay.bin"
PdName_RefreshPage:
	muls bc, 0xa
	calr PdMed_FormatFileList
	ld xwa, (xsp + 2)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	calr FmmPdMedleyFunc
	jrl PdName_ReturnZero

PdName_SetIndexPlaying:
	.incbin "includes/generated/v7_transplant_PdName_SetIndexPlaying.bin"
PdName_PostEvent:
	call ApPostEvent
	jrl PdName_ReturnZero

PdName_GetIndexReturn:
	.incbin "includes/generated/v7_transplant_PdName_GetIndexReturn.bin"
PdName_Exit:
	popw iz
	inc 4, xsp
	ret

PdMed_FormatSlotList:
	dec 6, xsp
	push xiz
	ld iz, bc
	ld (xsp + 6), xwa
	lds32 xwa, 0
	ld xbc, 0x1e50003
	lds32 xde, 0
	calr FmmPdFileNameFunc
	ldw_erp HL, 0xfa
	stw_erp WA, 0xfa
	extz xwa
	div wa, 0xa
	ldw_erp WA, 0xfa
	mul wa, 0xa
	ldw_erp WA, 0xfa
	ldw (xsp + 4), 0xa
	stw_erp WA, 0xfa
	add wa, 0xa
	cp wa, iz
	jr c, PdFmtSlot_CalcVisible
	ld (xsp + 4), iz
	stw_erp WA, 0xfa
	sub (xsp + 4), wa

PdFmtSlot_CalcVisible:
	lds iz, 0
	cpw (xsp + 4), 0x0
	jr ule, PdFmtSlot_FillEmpty

PdFmtSlot_FormatLoop:
	.incbin "includes/generated/v7_transplant_PdFmtSlot_FormatLoop.bin"
PdFmtSlot_FillEmpty:
	cp iz, 0xa
	jr nc, PdFmtSlot_Exit

PdFmtSlot_EmptyLoop:
	.incbin "includes/generated/v7_transplant_PdFmtSlot_EmptyLoop.bin"
PdFmtSlot_Exit:
	pop xiz
	inc 6, xsp
	ret

FmmPdMedleyFunc_Entry:
FmmPdMedleyFunc:
	.incbin "includes/generated/v7_transplant_FmmPdMedleyFunc.bin"
PdMed_CheckPlayMode:
	.incbin "includes/generated/v7_transplant_PdMed_CheckPlayMode.bin"
PdMed_FindSongLoop:
	.incbin "includes/generated/v7_transplant_PdMed_FindSongLoop.bin"
PdMed_NextSong:
	inc 1, hl
	cp hl, de
	jr c, PdMed_FindSongLoop
	jrl PdMed_Exit

PdMed_CheckRepeat:
	.incbin "includes/generated/v7_transplant_PdMed_CheckRepeat.bin"
PdMed_RepeatFindLoop:
	.incbin "includes/generated/v7_transplant_PdMed_RepeatFindLoop.bin"
PdMed_PostDelayEvent:
	call ApPostEvent
	jrl PdMed_Exit

PdMed_RepeatNext:
	inc 1, hl
	cp hl, bc
	jr c, PdMed_RepeatFindLoop
	jrl PdMed_Exit

PdMed_ClearPlaying:
	.incbin "includes/generated/v7_transplant_PdMed_ClearPlaying.bin"
PdMed_HandleError:
	.incbin "includes/generated/v7_transplant_PdMed_HandleError.bin"
PdMed_ShowError:
	call SoundCtrl_SendCommand
	jrl PdMed_Exit

PdMed_InitFromDisk_Entry:
PdMed_InitFromDisk:
	.incbin "includes/generated/v7_transplant_PdMed_InitFromDisk.bin"
PdMed_InitState:
	.incbin "includes/generated/v7_transplant_PdMed_InitState.bin"
PdMed_ClampCount:
	.incbin "includes/generated/v7_transplant_PdMed_ClampCount.bin"
PdMed_ClearSlotsLoop:
	.incbin "includes/generated/v7_transplant_PdMed_ClearSlotsLoop.bin"
PdMed_FinishInit:
	.incbin "includes/generated/v7_transplant_PdMed_FinishInit.bin"
PdMed_HandleStop:
	.incbin "includes/generated/v7_transplant_PdMed_HandleStop.bin"
PdMed_StoreWindowPtr:
	.incbin "includes/generated/v7_transplant_PdMed_StoreWindowPtr.bin"
PdMed_RefreshDisplay:
	.incbin "includes/generated/v7_transplant_PdMed_RefreshDisplay.bin"
PdMed_HandleNavToggle:
	.incbin "includes/generated/v7_transplant_PdMed_HandleNavToggle.bin"
PdMed_FindUnmarkedLoop:
	ld de, hl
	extz xde
	add xde, xbc
	cp (xde), 0xff
	jr z, PdMed_CheckAllUnmarked
	inc 1, hl
	cp hl, wa
	jr c, PdMed_FindUnmarkedLoop

PdMed_CheckAllUnmarked:
	.incbin "includes/generated/v7_transplant_PdMed_CheckAllUnmarked.bin"
PdMed_AssignOrderLoop:
	.incbin "includes/generated/v7_transplant_PdMed_AssignOrderLoop.bin"
PdMed_NextAssign:
	.incbin "includes/generated/v7_transplant_PdMed_NextAssign.bin"
PdMed_RemoveOrderLoop:
	.incbin "includes/generated/v7_transplant_PdMed_RemoveOrderLoop.bin"
PdMed_UnmarkLoop:
	.incbin "includes/generated/v7_transplant_PdMed_UnmarkLoop.bin"
PdMed_NextUnmark:
	.incbin "includes/generated/v7_transplant_PdMed_NextUnmark.bin"
PdMed_RefreshAfterToggle:
	.incbin "includes/generated/v7_transplant_PdMed_RefreshAfterToggle.bin"
PdMed_HandleSelectToggle:
	.incbin "includes/generated/v7_transplant_PdMed_HandleSelectToggle.bin"
PdMed_RemoveFromOrder:
	.incbin "includes/generated/v7_transplant_PdMed_RemoveFromOrder.bin"
PdMed_ReorderLoop:
	ld de, hl
	extz xde
	add xde, xix
	ld a, (xde)
	cp a, 0xfd
	jr ugt, PdMed_NextReorder
	inc 1, iz
	cp a, c
	jr ule, PdMed_NextReorder
	dec 1, a
	ld (xde), a

PdMed_NextReorder:
	inc 1, hl
	cp iz, iy
	jr c, PdMed_ReorderLoop

PdMed_RefreshAfterSelect:
	.incbin "includes/generated/v7_transplant_PdMed_RefreshAfterSelect.bin"
PdMed_CallFormatSlots:
	calr PdMed_FormatSlotList
	jrl PdMed_Exit

PdMed_HandleRepeat:
	.incbin "includes/generated/v7_transplant_PdMed_HandleRepeat.bin"
PdMed_SetRepeatOff:
	.incbin "includes/generated/v7_transplant_PdMed_SetRepeatOff.bin"
PdMed_HandlePlay:
	.incbin "includes/generated/v7_transplant_PdMed_HandlePlay.bin"
PdMed_PlayFindLoop:
	.incbin "includes/generated/v7_transplant_PdMed_PlayFindLoop.bin"
PdMed_PlayNextLoop:
	inc 1, hl
	cp hl, wa
	jr c, PdMed_PlayFindLoop

PdMed_CheckAutoPlay:
	.incbin "includes/generated/v7_transplant_PdMed_CheckAutoPlay.bin"
PdMed_StoreDelayFlag:
	.incbin "includes/generated/v7_transplant_PdMed_StoreDelayFlag.bin"
PdMed_CheckContinue:
	.incbin "includes/generated/v7_transplant_PdMed_CheckContinue.bin"
PdMed_CallPauseMode:
	call UI_PostModeChangeEvent

PdMed_Exit:
	lds32 xhl, 0
	pop xiz
	ret

DocDiskNameFunc_Entry:
DocDiskNameFunc:
	push xiz
	ld xiz, xde
	cp xbc, 0x1c0000b
	jr nz, DocDisk_Exit
	call FileIO_SearchAndLoadFile
	lds ix, 0
	jr DocDisk_CopyLoop

DocDisk_CopyCharLoop:
	cp (xhl), 0x20
	jr z, DocDisk_SkipSpace
	ld de, ix
	inc 1, ix
	ld a, (xhl)
	lda_dri XBC, 0x07, 0xe4, 0xe8

DocDisk_SkipSpace:
	inc 1, xhl

DocDisk_CopyLoop:
	.incbin "includes/generated/v7_transplant_DocDisk_CopyLoop.bin"
DocDisk_TerminateStr:
	ld xde, xbc
	stib_ind 0x07, 0xe4, 0xf0, 0x00
	jr DocDisk_TrimLoop

DocDisk_ClearTrailing:
	ld (xwa), 0x0

DocDisk_TrimLoop:
	dec 1, ix
	stb_dri W, 0x07, 0xe8, 0xf0
	cp (xwa), 0x20
	jr nz, DocDisk_PostEvent
	cps ix, 0
	jr gt, DocDisk_ClearTrailing

DocDisk_PostEvent:
	ld xwa, xiz
	ld xbc, 0x1c0000f
	call ApPostEvent

DocDisk_Exit:
	lds32 xhl, 0
	pop xiz
	ret

DocMed_FormatFileList:
	dec 6, xsp
	pushw iz
	ld (xsp + 2), bc
	ld (xsp + 4), xwa
	lds iz, 0

DocFmt_FormatLoop:
	.incbin "includes/generated/v7_transplant_DocFmt_FormatLoop.bin"
FmmDocFileNameFunc:
	.incbin "includes/generated/v7_transplant_FmmDocFileNameFunc.bin"
DocName_UpdateIndex:
	.incbin "includes/generated/v7_transplant_DocName_UpdateIndex.bin"
DocName_RefreshList:
	.incbin "includes/generated/v7_transplant_DocName_RefreshList.bin"
DocName_ReturnZero:
	lds32 xhl, 0
	jrl DocName_Exit

DocName_HandleNavigation:
	.incbin "includes/generated/v7_transplant_DocName_HandleNavigation.bin"
DocName_CheckPrevKey:
	cp xbc, 0x1c00017
	jr nz, DocName_GetCurrentIndex
	cps wa, 0
	jr le, DocName_GetCurrentIndex
	dec 1, wa
	jr DocName_SaveIndex

DocName_CheckPageUp:
	.incbin "includes/generated/v7_transplant_DocName_CheckPageUp.bin"
DocName_CheckPageDown:
	.incbin "includes/generated/v7_transplant_DocName_CheckPageDown.bin"
DocName_SaveIndex:
	.incbin "includes/generated/v7_transplant_DocName_SaveIndex.bin"
DocName_CheckEndBound:
	.incbin "includes/generated/v7_transplant_DocName_CheckEndBound.bin"
DocName_GetCurrentIndex:
	.incbin "includes/generated/v7_transplant_DocName_GetCurrentIndex.bin"
DocName_UpdateDisplay:
	.incbin "includes/generated/v7_transplant_DocName_UpdateDisplay.bin"
DocName_RefreshPage:
	muls bc, 0xa
	calr DocMed_FormatFileList
	ld xwa, (xsp + 2)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	calr FmmDocMedleyFunc
	jrl DocName_ReturnZero

DocName_SetIndexPlaying:
	.incbin "includes/generated/v7_transplant_DocName_SetIndexPlaying.bin"
DocName_PostEvent:
	call ApPostEvent
	jrl DocName_ReturnZero

DocName_GetIndexReturn:
	.incbin "includes/generated/v7_transplant_DocName_GetIndexReturn.bin"
DocName_Exit:
	popw iz
	inc 4, xsp
	ret

DocMed_FormatSlotList_Entry:
DocMed_FormatSlotList:
	dec 6, xsp
	push xiz
	ld iz, bc
	ld (xsp + 6), xwa
	lds32 xwa, 0
	ld xbc, 0x1e50003
	lds32 xde, 0
	calr FmmDocFileNameFunc
	ldw_erp HL, 0xfa
	stw_erp WA, 0xfa
	extz xwa
	div wa, 0xa
	ldw_erp WA, 0xfa
	mul wa, 0xa
	ldw_erp WA, 0xfa
	ldw (xsp + 4), 0xa
	stw_erp WA, 0xfa
	add wa, 0xa
	cp wa, iz
	jr c, DocFmtSlot_CalcVisible
	ld (xsp + 4), iz
	stw_erp WA, 0xfa
	sub (xsp + 4), wa

DocFmtSlot_CalcVisible:
	lds iz, 0
	cpw (xsp + 4), 0x0
	jr ule, DocFmtSlot_FillEmpty

DocFmtSlot_FormatLoop:
	.incbin "includes/generated/v7_transplant_DocFmtSlot_FormatLoop.bin"
DocFmtSlot_FillEmpty:
	cp iz, 0xa
	jr nc, DocFmtSlot_Exit

DocFmtSlot_EmptyLoop:
	.incbin "includes/generated/v7_transplant_DocFmtSlot_EmptyLoop.bin"
DocFmtSlot_Exit:
	pop xiz
	inc 6, xsp
	ret

FmmDocMedleyFunc:
	.incbin "includes/generated/v7_transplant_FmmDocMedleyFunc.bin"
DocMed_CheckPlayMode:
	.incbin "includes/generated/v7_transplant_DocMed_CheckPlayMode.bin"
DocMed_FindSongLoop:
	.incbin "includes/generated/v7_transplant_DocMed_FindSongLoop.bin"
DocMed_NextSong:
	inc 1, hl
	cp hl, de
	jr c, DocMed_FindSongLoop
	jrl DocMed_Exit

DocMed_CheckRepeat:
	.incbin "includes/generated/v7_transplant_DocMed_CheckRepeat.bin"
DocMed_RepeatFindLoop:
	.incbin "includes/generated/v7_transplant_DocMed_RepeatFindLoop.bin"
DocMed_PostDelayEvent:
	call ApPostEvent
	jrl DocMed_Exit

DocMed_RepeatNext:
	inc 1, hl
	cp hl, bc
	jr c, DocMed_RepeatFindLoop
	jrl DocMed_Exit

DocMed_ClearPlaying:
	.incbin "includes/generated/v7_transplant_DocMed_ClearPlaying.bin"
DocMed_HandleError:
	.incbin "includes/generated/v7_transplant_DocMed_HandleError.bin"
DocMed_ShowError:
	call SoundCtrl_SendCommand
	jrl DocMed_Exit

DocMed_CheckInit_Entry:
DocMed_CheckInit:
	.incbin "includes/generated/v7_transplant_DocMed_CheckInit.bin"
DocMed_InitFromDisk:
	.incbin "includes/generated/v7_transplant_DocMed_InitFromDisk.bin"
DocMed_InitState:
	.incbin "includes/generated/v7_transplant_DocMed_InitState.bin"
DocMed_ClampCount:
	.incbin "includes/generated/v7_transplant_DocMed_ClampCount.bin"
DocMed_ClearSlotsLoop:
	.incbin "includes/generated/v7_transplant_DocMed_ClearSlotsLoop.bin"
DocMed_FinishInit:
	.incbin "includes/generated/v7_transplant_DocMed_FinishInit.bin"
DocMed_HandleStop:
	.incbin "includes/generated/v7_transplant_DocMed_HandleStop.bin"
DocMed_StoreWindowPtr:
	.incbin "includes/generated/v7_transplant_DocMed_StoreWindowPtr.bin"
DocMed_RefreshDisplay:
	.incbin "includes/generated/v7_transplant_DocMed_RefreshDisplay.bin"
DocMed_HandleNavToggle:
	.incbin "includes/generated/v7_transplant_DocMed_HandleNavToggle.bin"
DocMed_FindUnmarkedLoop:
	ld de, hl
	extz xde
	add xde, xbc
	cp (xde), 0xff
	jr z, DocMed_CheckAllUnmarked
	inc 1, hl
	cp hl, wa
	jr c, DocMed_FindUnmarkedLoop

DocMed_CheckAllUnmarked:
	.incbin "includes/generated/v7_transplant_DocMed_CheckAllUnmarked.bin"
DocMed_AssignOrderLoop:
	.incbin "includes/generated/v7_transplant_DocMed_AssignOrderLoop.bin"
DocMed_NextAssign:
	.incbin "includes/generated/v7_transplant_DocMed_NextAssign.bin"
DocMed_RemoveOrderLoop:
	.incbin "includes/generated/v7_transplant_DocMed_RemoveOrderLoop.bin"
DocMed_UnmarkLoop:
	.incbin "includes/generated/v7_transplant_DocMed_UnmarkLoop.bin"
DocMed_NextUnmark:
	.incbin "includes/generated/v7_transplant_DocMed_NextUnmark.bin"
DocMed_RefreshAfterToggle:
	.incbin "includes/generated/v7_transplant_DocMed_RefreshAfterToggle.bin"
DocMed_HandleSelectToggle:
	.incbin "includes/generated/v7_transplant_DocMed_HandleSelectToggle.bin"
DocMed_RemoveFromOrder:
	.incbin "includes/generated/v7_transplant_DocMed_RemoveFromOrder.bin"
DocMed_ReorderLoop:
	ld de, hl
	extz xde
	add xde, xix
	ld a, (xde)
	cp a, 0xfd
	jr ugt, DocMed_NextReorder
	inc 1, iz
	cp a, c
	jr ule, DocMed_NextReorder
	dec 1, a
	ld (xde), a

DocMed_NextReorder:
	inc 1, hl
	cp iz, iy
	jr c, DocMed_ReorderLoop

DocMed_RefreshAfterSelect:
	.incbin "includes/generated/v7_transplant_DocMed_RefreshAfterSelect.bin"
DocMed_CallFormatSlots:
	calr DocMed_FormatSlotList
	jrl DocMed_Exit

DocMed_HandleRepeat:
	.incbin "includes/generated/v7_transplant_DocMed_HandleRepeat.bin"
DocMed_SetRepeatOff:
	.incbin "includes/generated/v7_transplant_DocMed_SetRepeatOff.bin"
DocMed_HandlePlay:
	.incbin "includes/generated/v7_transplant_DocMed_HandlePlay.bin"
DocMed_PlayFindLoop:
	.incbin "includes/generated/v7_transplant_DocMed_PlayFindLoop.bin"
DocMed_PlayNextLoop:
	inc 1, hl
	cp hl, wa
	jr c, DocMed_PlayFindLoop

DocMed_CheckAutoPlay:
	.incbin "includes/generated/v7_transplant_DocMed_CheckAutoPlay.bin"
DocMed_StoreDelayFlag:
	.incbin "includes/generated/v7_transplant_DocMed_StoreDelayFlag.bin"
DocMed_CheckContinue:
	.incbin "includes/generated/v7_transplant_DocMed_CheckContinue.bin"
DocMed_CallPauseMode:
	call UI_PostModeChangeEvent

DocMed_Exit:
	lds32 xhl, 0
	pop xiz
	ret

; SetSongSlotValue - Store a value into a song/medley slot
; Entry: WA = slot index (0-9), BC = value to store
; Computes slot address at 0x0AB000 + (index * 2048) + 0x1C
SetSongSlotValue:
	cp wa, 0xa
	ret nc
	lda_24 xhl, (0x0ab000)
	ld de, wa
	sll de, 11
	extz xde
	add xhl, xde
	add xhl, 0x1c
	ld (xhl), bc
	ldb_da e, (0x00ffe3)
	extz de
	cp de, wa
	ret nz
	lda_24 xhl, (0x00f180)
	add xhl, 0x1c
	ld (xhl), bc
	ret

GetSongSlotValue_Entry:
GetSongSlotValue:
	lds hl, 0
	cp wa, 0xa
	ret nc
	lda_24 xbc, (0x0ab000)
	sll wa, 11
	extz xwa
	add xbc, xwa
	add xbc, 0x1c
	ld hl, (xbc)
	ret

CheckSongSlotHasData_Entry:
CheckSongSlotHasData:
	calr GetSongSlotValue
	cps hl, 0
	scc16 nz, hl
	ret

SongSlot_RawData_Start:
SongSlot_RawData:
	.byte 0x2e, 0xd9, 0x8e, 0x1e, 0xd5, 0xff, 0xde, 0xf3
	.byte 0xdb, 0x76, 0x4e, 0x0e

FindFirstEmptySlot_Entry:
FindFirstEmptySlot:
	pushw iz
	lds iz, 0

FindEmpty_Loop:
	ld wa, iz
	calr GetSongSlotValue
	cps hl, 0
	jr nz, FindEmpty_Exit
	inc 1, iz
	cp iz, 0xa
	jr c, FindEmpty_Loop

FindEmpty_Exit:
	popw iz
	ret

ClearAllSongSlots_Entry:
ClearAllSongSlots:
	push xiz
	ld iz, wa
	ldiw_erp 0xfa, 0

ClearSlots_Loop:
	stw_erp WA, 0xfa
	ld bc, iz
	calr SetSongSlotValue
	inc1w_erp 0xfa
	cp_erpw 0xfa, 0x0a, 0x00
	jr c, ClearSlots_Loop
	pop xiz
	ret

ResetSlotsIfEmpty_Entry:
ResetSlotsIfEmpty:
	calr FindFirstEmptySlot
	ld wa, hl
	cps wa, 0
	ret z
	calr ClearAllSongSlots
	ret

CheckSlotIsSelected_Entry:
CheckSlotIsSelected:
	pushw iz
	ld iz, wa
	calr FindFirstEmptySlot
	cp hl, iz
	scc16 z, hl
	popw iz
	ret

CheckAnySlotHasData_Entry:
CheckAnySlotHasData:
	calr FindFirstEmptySlot
	cps hl, 0
	scc16 nz, hl
	ret

SetCurrentSlotIndex_Entry:
SetCurrentSlotIndex:
	stw_da (0x09480e), xwa
	ret

GetCurrentSlotIndex_Entry:
GetCurrentSlotIndex:
	ldw_da xhl, (0x09480e)
	ret

CheckIsCurrentSlot_Entry:
CheckIsCurrentSlot:
	pushw iz
	ld iz, wa
	calr GetCurrentSlotIndex
	cp hl, iz
	scc16 z, hl
	popw iz
	ret

CheckSlotIndexValid_Entry:
CheckSlotIndexValid:
	calr GetCurrentSlotIndex
	cps hl, 0
	scc16 nz, hl
	ret

InitializeCheap:
	.incbin "includes/generated/v7_transplant_InitializeCheap.bin"
PasswordText:
	cp xbc, 0x1e0009f
	jr nz, PasswordText_Exit
	lda_24 xhl, (NakaInst_WaitWinCtlSmf_0x7C8)
	ret

PasswordText_Exit:
	lds32 xhl, 0
	ret

CheckPasswordText:
	cp xbc, 0x1e0009f
	jr nz, CheckPwd_Exit
	ldb_da a, (0x02748e)
	cps a, 2
	jr z, CheckPwd_Type2
	cps a, 1
	jr nz, CheckPwd_Type0
	ld xhl, NakaInst_WaitWinCtlSmf_0xA32
	jr CheckPwd_Return

CheckPwd_Type2:
	ld xhl, NakaInst_WaitWinCtlSmf_0xC0C
	jr CheckPwd_Return

CheckPwd_Type0:
	ld xhl, NakaInst_WaitWinCtlSmf_0x88E

CheckPwd_Return:
	ret

CheckPwd_Exit:
	lds32 xhl, 0
	ret

WakeUpPassword:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xwa
	cp xbc, 0x1c50004
	jrl z, WakeUp_StoreType
	cp xbc, 0x1c00007
	jr z, WakeUp_HandleOk
	cp xbc, 0x1c00001
	jr z, WakeUp_HandleInit
	cp xbc, 0x1c0000d
	jr z, WakeUp_HandleDirect
	cp xbc, 0x1e00085
	jr z, WakeUp_Return1
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	jrl WakeUp_Exit

WakeUp_Return1:
	lds32 xhl, 1
	jrl WakeUp_Exit

WakeUp_HandleDirect:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1c0000f
	ld xde, NakaInst_WaitWinCtlSmf_0xDF0
	call SendEvent
	jrl WakeUp_ReturnZero

WakeUp_HandleInit:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	stib_da (0x02741a), 0x00
	jrl WakeUp_ReturnZero

WakeUp_HandleOk:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, 0x670001
	ld xbc, 0x1e00056
	lds32 xde, 0
	call SendEvent
	cp xhl, 0x3
	jr z, WakeUp_ReturnZero
	ld xwa, (xsp + 4)
	cp xwa, 0x8c
	jr nz, WakeUp_ClearCounter
	incdi8_24 1, (0x02741a)
	cpib_da (0x02741a), 0x07
	jr nz, WakeUp_ReturnZero
	stib_da (0x02741a), 0x00
	ld xwa, 0xffffffff
	ld xbc, 0x1c50000
	lds32 xde, 1
	call PostEvent
	ld xwa, 0x600040
	ld xbc, 0x1c00001
	lds32 xde, 0
	jr WakeUp_PostEvent

WakeUp_ClearCounter:
	stib_da (0x02741a), 0x00
	jr WakeUp_ReturnZero

WakeUp_StoreType:
	ld xwa, (xsp + 4)
	stb_da (0x02748e), a
	ld xwa, 0xffffffff
	ld xbc, 0x1c50000
	lds32 xde, 1
	call PostEvent
	ld xwa, 0x600045
	ld xbc, 0x1c00001
	lds32 xde, 0

WakeUp_PostEvent:
	call PostEvent

WakeUp_ReturnZero:
	lds32 xhl, 0

WakeUp_Exit:
	pop xiz
	inc 4, xsp
	ret

PasswordOk:
	.incbin "includes/generated/v7_transplant_PasswordOk.bin"
PwdOk_Return2:
	lds32 xhl, 2
	jr PwdOk_Exit

PwdOk_HandleConfirm:
	call GetNamingWindowID
	ld xwa, xhl
	ld xbc, 0x1e0003a
	ld xde, 0x2741c
	call SendEvent
	ld xwa, 0x600040
	ld xbc, 0x1c00002
	lds32 xde, 0
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c50000
	lds32 xde, 0
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	call PostEvent
	ldw_da xde, (0x02741c)
	extz xde
	ld xwa, 0x1450038
	ld xbc, 0x1e5000d
	call MainFuncCall

PwdOk_ReturnZero:
	lds32 xhl, 0

PwdOk_Exit:
	pop xiz
	ret

CheckPasswordOk:
	.incbin "includes/generated/v7_transplant_CheckPasswordOk.bin"
CheckOk_Return2:
	lds32 xhl, 2
	jrl CheckOk_Exit

CheckOk_HandleConfirm:
	call GetNamingWindowID
	ld xwa, xhl
	ld xbc, 0x1e0003a
	ld xde, 0x27424
	call SendEvent
	ld xwa, 0x600045
	ld xbc, 0x1c00002
	lds32 xde, 0
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c50000
	lds32 xde, 0
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	call PostEvent
	ld xwa, 0x670001
	ld xbc, 0x1e00056
	lds32 xde, 0
	call SendEvent
	lda_24 xwa, (0x027424)
	cps hl, 1
	jr nz, CheckOk_Type2
	ld de, (xwa)
	extz xde
	ld xwa, 0x1450038
	ld xbc, 0x1e5000e
	jr CheckOk_CallFunc

CheckOk_Type2:
	cps hl, 2
	jr nz, CheckOk_Type3
	ld de, (xwa)
	extz xde
	ld xwa, 0x1450038
	ld xbc, 0x1e5000f
	jr CheckOk_CallFunc

CheckOk_Type3:
	cps hl, 3
	jr nz, CheckOk_ReturnZero
	ld de, (xwa)
	extz xde
	ld xwa, 0x1450038
	ld xbc, 0x1e50010

CheckOk_CallFunc:
	call MainFuncCall

CheckOk_ReturnZero:
	lds32 xhl, 0

CheckOk_Exit:
	pop xiz
	ret

PasswordNo:
	cp xbc, 0x1c00007
	jr nz, PwdNo_Exit
	ld xwa, 0x600040
	ld xbc, 0x1c00002
	lds32 xde, 0
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c50000
	lds32 xde, 0
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	call PostEvent

PwdNo_Exit:
	lds32 xhl, 0
	ret

CheckPasswordNo:
	cp xbc, 0x1c00007
	jr nz, CheckNo_HandleConfirm
	ld xwa, 0x600045
	ld xbc, 0x1c00002
	lds32 xde, 0
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c50000
	lds32 xde, 0
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	call PostEvent

CheckNo_HandleConfirm:
	lds32 xhl, 0
	ret

DiskAttention:
	cp xbc, 0x1e0009f
	jr nz, CheckNo_Type1
	lda_24 xhl, (NakaInst_WaitWinCtlSmf_0xDFE)
	ret

CheckNo_Type1:
	lds32 xhl, 0
	ret

DiskSure:
	cp xbc, 0x1e0009f
	jr nz, CheckNo_Type2
	lda_24 xhl, (NakaInst_WaitWinCtlSmf_0xE5C)
	ret

CheckNo_Type2:
	lds32 xhl, 0
	ret

FormatText:
	cp xbc, 0x1e0009f
	jr nz, CheckNo_Type3
	lda_24 xhl, (DiskWarning_ConfirmStrings_0x30)
	ret

CheckNo_Type3:
	lds32 xhl, 0
	ret

DeleteText:
	cp xbc, 0x1e0009f
	jr nz, CheckNo_CallFunc
	lda_24 xhl, (DiskWarning_ConfirmStrings_0x1C4)
	ret

CheckNo_CallFunc:
	lds32 xhl, 0
	ret

DeleteYes:
	cp xbc, 0x1c00007
	jr nz, PwdChange_HandleOk
	ld xwa, 0x7b0051
	ld xbc, 0x1c00002
	lds32 xde, 0
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c50000
	lds32 xde, 0
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c00017
	ld xde, 0x33
	call PostEvent

PwdChange_HandleOk:
	lds32 xhl, 0
	ret

DeleteNo:
	cp xbc, 0x1c00007
	jr nz, PwdChange_Type1
	ld xwa, 0x7b0051
	ld xbc, 0x1c00002
	lds32 xde, 0
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c50000
	lds32 xde, 0
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	call PostEvent

PwdChange_Type1:
	lds32 xhl, 0
	ret

SaveText:
	cp xbc, 0x1e0009f
	jr nz, PwdChange_CallFunc
	lda_24 xhl, (DiskWarning_ConfirmStrings_0x47E)
	ret

PwdChange_CallFunc:
	lds32 xhl, 0
	ret

SaveYes:
	cp xbc, 0x1c00007
	jr nz, PwdDel_HandleOk
	ld xwa, 0x600037
	ld xbc, 0x1c00002
	lds32 xde, 0
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c50000
	lds32 xde, 0
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c00017
	ld xde, 0x32
	call PostEvent

PwdDel_HandleOk:
	lds32 xhl, 0
	ret

SaveNo:
	cp xbc, 0x1c00007
	jr nz, PwdDel_Type1
	ld xwa, 0x600037
	ld xbc, 0x1c00002
	lds32 xde, 0
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c50000
	lds32 xde, 0
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	call PostEvent

PwdDel_Type1:
	lds32 xhl, 0
	ret

InsertOptionText:
	cp xbc, 0x1e0009f
	jr nz, PwdDel_Type2
	lda_24 xhl, (DiskWarning_ConfirmStrings_0x790)
	ret

PwdDel_Type2:
	lds32 xhl, 0
	ret

TypePriorityText:
	cp xbc, 0x1e0009f
	jr nz, PwdDel_CallFunc
	lda_24 xhl, (DiskWarning_ConfirmStrings_0x8AC)
	ret

PwdDel_CallFunc:
	lds32 xhl, 0
	ret

