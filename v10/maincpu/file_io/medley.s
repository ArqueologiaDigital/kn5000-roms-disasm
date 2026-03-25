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
	pushw iz
	cp xbc, 0x1e50003
	jrl z, SeqName_GetIndexReturn
	ldw_d16 xhl, 0x82d8
	cp xbc, 0x1e50002
	jrl z, SeqName_SetIndexPlaying
	cp xbc, 0x1c00018
	jr z, SeqName_HandleNavigation
	cp xbc, 0x1c00017
	jr z, SeqName_HandleNavigation
	cp xbc, 0x1c0000b
	jr z, SeqName_InitAllSlots
	cp xbc, 0x1e50004
	jr nz, SeqName_ReturnZero
	stda32 0x82d4, xde
	cpdi8 0x84fe, 0
	jr nz, SeqName_SendCurrentIndex
	stdi16 0x82d8, 0

SeqName_SendCurrentIndex:
	ldw_d16 xde, 0x82d8
	extz xde
	ldda32 xwa, 0x82d4
	ld xbc, 0x1e50002
	jrl SeqName_PostEventExit

SeqName_InitAllSlots:
	lds iz, 0

SeqName_SendSlotLoop:
	ld bc, iz
	ld wa, bc
	lds de, 1
	calr BuildSlotLabel
	ld xde, xhl
	ldda32 xwa, 0x82d4
	ld xbc, 0x1c0000f
	call ApPostEvent
	inc 1, iz
	cp iz, 0xa
	jr lt, SeqName_SendSlotLoop

SeqName_ReturnZero:
	lds32 xhl, 0
	jrl SeqName_Exit

SeqName_HandleNavigation:
	ld wa, hl
	ld iz, hl
	or xde, xde
	jr nz, SeqName_HandlePlayAction
	cpdi8 0x84fe, 0
	jr nz, SeqName_HandlePlayAction
	cp xbc, 0x1c00018
	jr nz, SeqName_CheckPrevKey
	cp wa, 0x9
	jrl nc, SeqName_GetCurrentIndex
	inc 1, wa
	jr SeqName_UpdateIndex

SeqName_CheckPrevKey:
	cp xbc, 0x1c00017
	jrl nz, SeqName_GetCurrentIndex
	cps wa, 0
	jrl z, SeqName_GetCurrentIndex
	dec 1, wa

SeqName_UpdateIndex:
	stda16 0x82d8, xwa
	ld de, wa
	jrl SeqName_UpdateDisplay

SeqName_HandlePlayAction:
	cp xde, 0x4
	jrl nz, SeqName_HandleAction32
	cpdi8 0x84fe, 0
	jrl nz, SeqName_HandleAction32
	call CheckSongSlotHasData
	cps l, 0
	jr z, SeqName_CheckDiskAvail
	lda_d16 xwa, 0x8a0c
	bitm 7, (xwa + 1)
	jr nz, SeqName_CheckDiskAvail
	ld (xwa), 0x1
	lds32 xde, 1
	ld xwa, 0xffffffff
	ld xbc, 0x1c50004
	jr SeqName_PostAndExit

SeqName_CheckDiskAvail:
	call CheckFileSystemStatus
	cps hl, 0
	jr z, SeqName_LoadAndPlay
	cpib_da 0x0340ea, 0x00
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
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	lds wa, 0
	calr InitializeOperationState
	ldw_d16 xwa, 0x82d8
	call LoadFileMultiPass
	ld wa, hl
	lds bc, 5
	calr FileIO_ValidateSignedValue
	stb_d8 0x7f42, l
	call FileIO_ResetCurrentRecord
	call GetEncodedFreeSpaceData
	call GetEncodedFileSizeData
	stda16 0x8502, xhl
	calr SignalProgressUpdate
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0xee
	jr SeqName_ShowAndExit

SeqName_HandleAction32:
	cp xde, 0x32
	jr nz, SeqName_GetCurrentIndex
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	lds wa, 0
	calr InitializeOperationState
	ldw_d16 xwa, 0x82d8
	call LoadFileMultiPass
	ld wa, hl
	lds bc, 5
	calr FileIO_ValidateSignedValue
	stb_d8 0x7f42, l
	call FileIO_ResetCurrentRecord
	call GetEncodedFreeSpaceData
	call GetEncodedFileSizeData
	stda16 0x8502, xhl
	calr SignalProgressUpdate
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0xee

SeqName_ShowAndExit:
	call SoundCtrl_SendCommand

SeqName_GetCurrentIndex:
	ldw_d16 xde, 0x82d8

SeqName_UpdateDisplay:
	cp iz, de
	jrl z, SeqName_ReturnZero
	extz xde
	ldda32 xwa, 0x82d4
	ld xbc, 0x1e50002
	call ApPostEvent
	ld wa, iz
	ld bc, iz
	lds de, 1
	calr BuildSlotLabel
	ld xde, xhl
	ldda32 xwa, 0x82d4
	ld xbc, 0x1c0000f
	call ApPostEvent
	ldw_d16 xbc, 0x82d8
	ld wa, bc
	lds de, 1
	calr BuildSlotLabel
	ld xde, xhl
	ldda32 xwa, 0x82d4
	ld xbc, 0x1c0000f
	jr SeqName_PostEventExit

SeqName_SetIndexPlaying:
	cpdi8 0x84fe, 0
	jrl z, SeqName_ReturnZero
	ld iz, hl
	stda16 0x82d8, xde
	extz xde
	ldda32 xwa, 0x82d4
	ld xbc, 0x1e50002
	call ApPostEvent
	ld wa, iz
	ld bc, iz
	lds de, 1
	calr BuildSlotLabel
	ld xde, xhl
	ldda32 xwa, 0x82d4
	ld xbc, 0x1c0000f
	call ApPostEvent
	ldw_d16 xbc, 0x82d8
	ld wa, bc
	lds de, 1
	calr BuildSlotLabel
	ld xde, xhl
	ldda32 xwa, 0x82d4
	ld xbc, 0x1c0000f

SeqName_PostEventExit:
	call ApPostEvent
	jrl SeqName_ReturnZero

SeqName_GetIndexReturn:
	ldw_d16 xhl, 0x82d8
	extz xhl

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
	dec 8, xsp
	pushw iz
	ld (xsp + 6), xwa
	cp xbc, 0x1e5000a
	jrl z, IntMed_CheckContinue
	ld xwa, xde
	cp xbc, 0x1e50008
	jrl z, IntMed_StoreDelayFlag
	cp xbc, 0x1c00018
	jrl z, IntMed_HandleNavToggle
	cp xbc, 0x1c00017
	jrl z, IntMed_HandleNavToggle
	cp xbc, 0x1c0000b
	jrl z, IntMed_InitSlotDisplay
	cp xbc, 0x1e50004
	jrl z, IntMed_StoreWindowPtr
	cp xbc, 0x1c00013
	jrl nz, IntMed_Exit
	cp xde, 0x3
	jrl z, IntMed_HandleStop
	cp xde, 0x2
	jrl nz, IntMed_Exit
	cpdi8 0x8d37, 122
	jr z, IntMed_CheckPlaying
	call CDlike_InitModeAndLoadBank
	stdi8 0x84fe, 0
	stdi8 0x889c, 0
	stdi8 0x889a, 0
	lds iz, 0

IntMed_CheckSlotLoop:
	stb_erp A, 0xf8
	extz wa
	call SongBank_ScanActiveVoices
	cps l, 0
	jr z, IntMed_MarkSlotEmpty
	lda_d16 xwa, 0x8890
	ld bc, iz
	extz xbc
	add xbc, xwa
	ldmi16 (xbc), 0x889a
	incdi8 1, 0x889a
	jr IntMed_NextSlot

IntMed_MarkSlotEmpty:
	lda_d16 xwa, 0x8890
	ld bc, iz
	extz xbc
	add xbc, xwa
	ld (xbc), 0xff

IntMed_NextSlot:
	inc 1, iz
	cp iz, 0xa
	jr c, IntMed_CheckSlotLoop
	lds32 xwa, 0
	stda32 0x82de, xwa
	jrl IntMed_Exit

IntMed_CheckPlaying:
	call Medley_GetPlaybackStatus
	cps l, 1
	jrl nz, IntMed_HandleError
	stdi8 0x84fe, 1
	ldb_d8 a, 0x889c
	cpda8 a, 0x889a
	jr nc, IntMed_CheckRepeat
	lds iz, 0
	lda_d16 xbc, 0x8890

IntMed_FindCurrentSong:
	ld de, iz
	extz xde
	add xde, xbc
	cp (xde), a
	jr nz, IntMed_NextSongSearch
	ld de, iz
	extz xde
	ld xwa, (xsp + 6)
	ld xbc, 0x1e50002
	calr FmmSeqSongNameFunc
	stb_erp A, 0xf8
	extz wa
	call SongBank_SwitchAndUpdateTempo
	incdi8 1, 0x889c
	ldda32 xwa, 0x82de
	or xwa, xwa
	jrl z, IntMed_Exit
	ld xbc, 0x1e50009
	ld xde, 0x1e
	jr IntMed_PostDelayEvent

IntMed_NextSongSearch:
	inc 1, iz
	cp iz, 0xa
	jr c, IntMed_FindCurrentSong
	jrl IntMed_Exit

IntMed_CheckRepeat:
	cpdi8 0x889e, 0
	jr z, IntMed_ClearPlayFlag
	stdi8 0x889c, 0
	lds iz, 0
	lda_d16 xwa, 0x8890

IntMed_PlayFromStart:
	ld bc, iz
	extz xbc
	add xbc, xwa
	cp (xbc), 0x0
	jr nz, IntMed_NextSongLoop
	ld de, iz
	extz xde
	ld xwa, (xsp + 6)
	ld xbc, 0x1e50002
	calr FmmSeqSongNameFunc
	stb_erp A, 0xf8
	extz wa
	call SongBank_SwitchAndUpdateTempo
	incdi8 1, 0x889c
	ldda32 xwa, 0x82de
	or xwa, xwa
	jrl z, IntMed_Exit
	ld xbc, 0x1e50009
	ld xde, 0x1e

IntMed_PostDelayEvent:
	call ApPostEvent
	jrl IntMed_Exit

IntMed_NextSongLoop:
	inc 1, iz
	cp iz, 0xa
	jr c, IntMed_PlayFromStart
	jrl IntMed_Exit

IntMed_ClearPlayFlag:
	stdi8 0x84fe, 0
	jrl IntMed_Exit

IntMed_HandleError:
	call Medley_GetPlaybackStatus
	stdi8 0x84fe, 0
	cps l, 0
	jrl z, IntMed_Exit
	stdi8 0x7f42, 14
	ldw wa, 0xee
	call SoundCtrl_SendCommand
	jrl IntMed_Exit

IntMed_HandleStop:
	cpdi8 0x8d36, 122
	jrl z, IntMed_Exit
	call CDlike_ExitModeAndRestore
	stdi8 0x84fe, 0
	jrl IntMed_Exit

IntMed_StoreWindowPtr:
	stda32 0x82da, xwa
	jrl IntMed_Exit

IntMed_InitSlotDisplay:
	lds iz, 0

IntMed_FormatSlotLoop:
	ld wa, iz
	sll wa, 3
	lda_d16 xbc, 0x82e2
	extz xwa
	add xwa, xbc
	lda_d16 xbc, 0x8890
	ld de, iz
	extz xde
	add xde, xbc
	ld c, (xde)
	extz bc
	ld de, iz
	calr FormatMedleyNumber
	ld de, iz
	sll de, 3
	lda_d16 xwa, 0x82e2
	extz xde
	add xde, xwa
	ldda32 xwa, 0x82da
	ld xbc, 0x1c0000f
	call ApPostEvent
	inc 1, iz
	cp iz, 0xa
	jr c, IntMed_FormatSlotLoop
	jrl IntMed_Exit

IntMed_HandleNavToggle:
	lda_d16 xwa, 0x8890
	cp xde, 0xa
	jrl nz, IntMed_HandleSelectToggle
	cpdi8 0x84fe, 0
	jrl nz, IntMed_HandleSelectToggle
	lds iz, 0

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
	lda_d16 xwa, 0x8890
	ld bc, iz
	extz xbc
	add xbc, xwa
	ld a, (xbc)
	cp a, 0xfe
	jr nz, IntMed_NextAssignSlot
	ldb_d8 a, 0x889a
	ld (xbc), a
	incdi8 1, 0x889a
	ld wa, iz
	sll wa, 3
	lda_d16 xde, 0x82e2
	extz xwa
	add xwa, xde
	ld c, (xbc)
	extz bc
	ld de, iz
	calr FormatMedleyNumber
	ld de, iz
	sll de, 3
	lda_d16 xwa, 0x82e2
	extz xde
	add xde, xwa
	ldda32 xwa, 0x82da
	ld xbc, 0x1c0000f
	call ApPostEvent

IntMed_NextAssignSlot:
	inc 1, iz
	cp iz, 0xa
	jr c, IntMed_AssignOrderLoop
	jrl IntMed_Exit

IntMed_RemoveOrderLoop:
	lds iz, 0

IntMed_UnmarkSlotLoop:
	lda_d16 xwa, 0x8890
	ld bc, iz
	extz xbc
	add xbc, xwa
	ld a, (xbc)
	cp a, 0xfd
	jr ugt, IntMed_NextUnmark
	ld (xbc), 0xfe
	decdi8 1, 0x889a
	ld wa, iz
	sll wa, 3
	lda_d16 xde, 0x82e2
	extz xwa
	add xwa, xde
	ld c, (xbc)
	extz bc
	ld de, iz
	calr FormatMedleyNumber
	ld de, iz
	sll de, 3
	lda_d16 xwa, 0x82e2
	extz xde
	add xde, xwa
	ldda32 xwa, 0x82da
	ld xbc, 0x1c0000f
	call ApPostEvent

IntMed_NextUnmark:
	inc 1, iz
	cp iz, 0xa
	jr c, IntMed_UnmarkSlotLoop
	jrl IntMed_Exit

IntMed_HandleSelectToggle:
	cp xde, 0xb
	jrl nz, IntMed_HandleRepeatToggle
	cpdi8 0x84fe, 0
	jrl nz, IntMed_HandleRepeatToggle
	ld xwa, (xsp + 6)
	ld xbc, 0x1e50003
	lds32 xde, 0
	calr FmmSeqSongNameFunc
	ld iz, hl
	lda_d16 xwa, 0x8890
	ld de, iz
	extz xde
	add xde, xwa
	lda_d16 xbc, 0x82e2
	ld wa, iz
	sll wa, 3
	extz xwa
	add xwa, xbc
	ld c, (xde)
	cp c, 0xfe
	jr nz, IntMed_RemoveFromOrder
	ldb_d8 c, 0x889a
	ld (xde), c
	incdi8 1, 0x889a
	ld c, (xde)
	extz bc
	ld de, iz
	calr FormatMedleyNumber
	ld de, iz
	sll de, 3
	lda_d16 xbc, 0x82e2
	extz xde
	add xde, xbc
	ldda32 xwa, 0x82da
	ld xbc, 0x1c0000f
	call ApPostEvent
	jrl IntMed_Exit

IntMed_RemoveFromOrder:
	cp c, 0xfd
	jrl ugt, IntMed_Exit
	ld (xsp + 4), c
	ld (xde), 0xfe
	decdi8 1, 0x889a
	ld c, (xde)
	extz bc
	ld de, iz
	calr FormatMedleyNumber
	ld de, iz
	sll de, 3
	lda_d16 xbc, 0x82e2
	extz xde
	add xde, xbc
	ldda32 xwa, 0x82da
	ld xbc, 0x1c0000f
	call ApPostEvent
	ldw (xsp + 2), 0x0
	lds iz, 0
	ldb_d8 a, 0x889a
	extz wa
	cps wa, 0
	jrl ule, IntMed_Exit

IntMed_ReorderLoop:
	lda_d16 xwa, 0x8890
	ld de, iz
	extz xde
	add xde, xwa
	ld c, (xde)
	cp c, 0xfd
	jr ugt, IntMed_NextReorder
	incm 1, (xsp + 2)
	cp c, (xsp + 4)
	jr ule, IntMed_NextReorder
	dec 1, c
	ld (xde), c
	ld wa, iz
	sll wa, 3
	lda_d16 xde, 0x82e2
	extz xwa
	add xwa, xde
	extz bc
	ld de, iz
	calr FormatMedleyNumber
	ld de, iz
	sll de, 3
	lda_d16 xwa, 0x82e2
	extz xde
	add xde, xwa
	ldda32 xwa, 0x82da
	ld xbc, 0x1c0000f
	call ApPostEvent

IntMed_NextReorder:
	inc 1, iz
	ldb_d8 a, 0x889a
	extz wa
	cp (xsp + 2), wa
	jr c, IntMed_ReorderLoop
	jrl IntMed_Exit

IntMed_HandleRepeatToggle:
	cp xde, 0xc
	jr nz, IntMed_HandlePlay
	cp xbc, 0x1c00017
	jr nz, IntMed_SetRepeatOff
	stdi8 0x889e, 1
	jrl IntMed_Exit

IntMed_SetRepeatOff:
	stdi8 0x889e, 0
	jrl IntMed_Exit

IntMed_HandlePlay:
	cp xde, 0xd
	jrl nz, IntMed_Exit
	cpdi8 0x84fe, 0
	jr nz, IntMed_Exit
	stdi8 0x889c, 0
	lds iz, 0

IntMed_StartPlayLoop:
	ld bc, iz
	extz xbc
	add xbc, xwa
	cp (xbc), 0x0
	jr nz, IntMed_NextPlaySlot
	stdi8 0x84fe, 1
	ld de, iz
	extz xde
	ld xwa, (xsp + 6)
	ld xbc, 0x1e50002
	calr FmmSeqSongNameFunc
	stb_erp A, 0xf8
	extz wa
	call SongBank_SwitchAndUpdateTempo
	incdi8 1, 0x889c
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009a
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0x7a
	call UI_PostModeChangeEvent
	jr IntMed_Exit

IntMed_NextPlaySlot:
	inc 1, iz
	cp iz, 0xa
	jr c, IntMed_StartPlayLoop
	jr IntMed_Exit

IntMed_StoreDelayFlag:
	stda32 0x82de, xwa
	jr IntMed_Exit

IntMed_CheckContinue:
	cpdi8 0x84fe, 0
	jr z, IntMed_Exit
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009a
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0x7a
	call UI_PostModeChangeEvent

IntMed_Exit:
	lds32 xhl, 0
	popw iz
	inc 8, xsp
	ret

FmmDiskMedley1Func:
	pushw iz
	cp xbc, 0x1c0000b
	jr z, DiskMed1_InitLoop
	cp xbc, 0x1e50004
	jr nz, DiskMed1_Exit
	stda32 0x8332, xde
	jr DiskMed1_Exit

DiskMed1_InitLoop:
	lds iz, 0

DiskMed1_FormatLoop:
	ld wa, iz
	sll wa, 3
	lda_d16 xbc, 0x8336
	extz xwa
	add xwa, xbc
	lda_d16 xbc, 0x8926
	ld de, iz
	extz xde
	add xde, xbc
	ld c, (xde)
	extz bc
	ld de, iz
	calr FormatMedleyNumber
	ld de, iz
	sll de, 3
	lda_d16 xwa, 0x8336
	extz xde
	add xde, xwa
	ldda32 xwa, 0x8332
	ld xbc, 0x1c0000f
	call ApPostEvent
	inc 1, iz
	cp iz, 0xa
	jr c, DiskMed1_FormatLoop

DiskMed1_Exit:
	lds32 xhl, 0
	popw iz
	ret

FmmDiskMedley2Func:
	pushw iz
	cp xbc, 0x1c0000b
	jr z, DiskMed2_InitLoop
	cp xbc, 0x1e50004
	jr nz, DiskMed2_Exit
	stda32 0x8386, xde
	jr DiskMed2_Exit

DiskMed2_InitLoop:
	ldw iz, 0xa

DiskMed2_FormatLoop:
	ld wa, iz
	sll wa, 3
	lda_24 xbc, 0x00833a
	extz xwa
	add xwa, xbc
	lda_d16 xbc, 0x8926
	ld de, iz
	extz xde
	add xde, xbc
	ld c, (xde)
	extz bc
	ld de, iz
	sub de, 0xa
	calr FormatMedleyNumber
	ld wa, iz
	sll wa, 3
	lda_24 xbc, 0x00833a
	ld de, wa
	extz xde
	add xde, xbc
	ldda32 xwa, 0x8386
	ld xbc, 0x1c0000f
	call ApPostEvent
	inc 1, iz
	cp iz, 0x14
	jr c, DiskMed2_FormatLoop

DiskMed2_Exit:
	lds32 xhl, 0
	popw iz
	ret

DiskMed_PlayNextHelper:
	pushw iz
	cp xbc, 0x1c00018
	jr z, DiskMed_InitPlayOrder
	cp xbc, 0x1c00017
	jr z, DiskMed_InitPlayOrder
	cp xbc, 0x1c00013
	jrl nz, DiskMed_ReturnZero
	cp xde, 0x3
	jrl z, DiskMed_ReturnZero
	cp xde, 0x2
	jrl nz, DiskMed_ReturnZero
	cpdi8 0x84fe, 0
	jrl z, DiskMed_ReturnZero
	ldb_d8 a, 0x889c
	cpda8 a, 0x889a
	jr nc, DiskMed_ReturnFinished
	lds iz, 0
	lda_d16 xbc, 0x8890

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
	cp xde, 0xd
	jrl nz, DiskMed_ReturnZero
	stdi8 0x889c, 0
	stdi8 0x889a, 0
	stdi8 0x889e, 0
	lds iz, 0

DiskMed_CheckSlotLoop:
	stb_erp A, 0xf8
	extz wa
	call SongBank_ScanActiveVoices
	lda_d16 xbc, 0x8890
	ld wa, iz
	extz xwa
	add xwa, xbc
	cps l, 0
	jr z, DiskMed_MarkUnused
	ld (xwa), 0xfe
	jr DiskMed_NextSlotCheck

DiskMed_MarkUnused:
	ld (xwa), 0xff

DiskMed_NextSlotCheck:
	inc 1, iz
	cp iz, 0xa
	jr c, DiskMed_CheckSlotLoop
	cpdi8 0x8940, 0
	jr z, DiskMed_SingleSlotCheck
	lda_d16 xhl, 0x8890
	ld xbc, xhl
	lda xde, (xhl + 10)

DiskMed_AssignOrder:
	ld a, (xbc)
	cp a, 0xfe
	jr nz, DiskMed_NextAssign
	ldmi16 (xbc), 0x889a
	incdi8 1, 0x889a

DiskMed_NextAssign:
	inc 1, xbc
	cp xbc, xde
	jr c, DiskMed_AssignOrder
	lds iz, 0

DiskMed_FindFirstSong:
	ld wa, iz
	extz xwa
	add xwa, xhl
	ld a, (xwa)
	cpda8 a, 0x889c
	jr nz, DiskMed_NextFirst
	stb_erp A, 0xf8
	extz wa
	jr DiskMed_PlaySong

DiskMed_NextFirst:
	inc 1, iz
	cp iz, 0xa
	jr c, DiskMed_FindFirstSong
	jr DiskMed_ReturnZero

DiskMed_SingleSlotCheck:
	lda_d16 xbc, 0x8890
	cp (xbc), 0xfe
	jr nz, DiskMed_SingleSlotInit
	ldmi16 (xbc), 0x889a
	incdi8 1, 0x889a

DiskMed_SingleSlotInit:
	lds iz, 0

DiskMed_FindFirstLoop:
	ld wa, iz
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cpda8 a, 0x889c
	jr nz, DiskMed_NextFindFirst
	stb_erp A, 0xf8
	extz wa

DiskMed_PlaySong:
	call SongBank_SwitchAndUpdateTempo
	incdi8 1, 0x889c
	lds32 xhl, 1
	jr DiskMed_HelperExit

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
	lda xsp, (xsp - 14)
	push xiz
	ld (xsp + 6), xde
	ld (xsp + 10), xbc
	ld (xsp + 14), xwa
	ld xwa, (xsp + 10)
	cp xwa, 0x1c00018
	jrl z, DiskSel_HandleNavigation
	cp xwa, 0x1c00017
	jrl z, DiskSel_HandleNavigation
	cp xwa, 0x1c0000b
	jrl z, DiskSel_InitDisplay
	cp xwa, 0x1e50004
	jrl z, DiskSel_StoreWindowPtr
	cp xwa, 0x1c00013
	jrl nz, DiskSel_Exit
	ld xwa, (xsp + 6)
	cp xwa, 0x3
	jrl z, DiskSel_HandleStopEvent
	cp xwa, 0x2
	jrl nz, DiskSel_Exit
	lds wa, 0
	calr InitializeOperationState
	cpdi8 0x8d37, 120
	jrl z, DiskSel_CheckPlaying
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	call ApPostEvent
	cpdi16 0x8502, 0
	jr ge, DiskSel_InitState
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	call GetEncodedFileSizeData
	stda16 0x8502, xhl
	call FileIO_SearchAndLoadFile
	call GetEncodedFreeSpaceData
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	call ApPostEvent
	calr SignalProgressUpdate

DiskSel_InitState:
	stdi8 0x84fe, 0
	stdi8 0x893c, 0
	stdi8 0x893a, 0
	lds iz, 0

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
	lda_d16 xwa, 0x8926
	ldmmb_dri 0x07, 0xe0, 0xf8, 0x3a, 0x89
	incdi8 1, 0x893a
	jr DiskSel_NextFile

DiskSel_MarkUnavail:
	lda_d16 xwa, 0x8926
	stib_ind 0x07, 0xe0, 0xf8, 0xff

DiskSel_NextFile:
	inc 1, iz
	cp iz, 0x14
	jr lt, DiskSel_CheckFileLoop
	call CDlike_InitModeAndLoadBank
	jrl DiskSel_Exit

DiskSel_CheckPlaying:
	call Medley_GetPlaybackStatus
	cps l, 1
	jrl nz, DiskSel_HandleError
	stdi8 0x84fe, 1
	ld xwa, (xsp + 14)
	ld xbc, (xsp + 10)
	ld xde, (xsp + 6)
	calr DiskMed_PlayNextHelper
	cps l, 1
	jr nz, DiskSel_CheckFinished
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009a
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0x78
	jrl DiskSel_CallPauseMode

DiskSel_CheckFinished:
	cps l, 2
	jrl nz, DiskSel_Exit
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	call ApPostEvent
	ldb_d8 a, 0x893c
	cpda8 a, 0x893a
	jrl nc, DiskSel_CheckRepeat
	lds iz, 0

DiskSel_ClearSelections:
	stb_erp A, 0xf8
	extz wa
	call FileIO_FormatName_Loop
	inc 1, iz
	cp iz, 0x8
	jr lt, DiskSel_ClearSelections
	lds iz, 0

DiskSel_FindSongLoop:
	lda_d16 xwa, 0x8926
	ldb_sri A, 0x07, 0xe0, 0xf8
	cpda8 a, 0x893c
	jrl nz, DiskSel_NextSongLoop
	stda16 0x83de, xiz
	ld wa, iz
	call NotifyUIOfSelectionChange
	ldw_d16 xde, 0x83de
	exts xde
	ldda32 xwa, 0x83da
	ld xbc, 0x1e50002
	call ApPostEvent
	ldiw_erp 0xfa, 0

DiskSel_SendFileInfo:
	stw_erp DE, 0xfa
	sll de, 5
	lda_d16 xbc, 0x850c
	extz xde
	add xde, xbc
	ldda32 xwa, 0x83da
	ld xbc, 0x1c0000f
	call ApPostEvent
	inc1w_erp 0xfa
	cp_erpw 0xfa, 0x14, 0x00
	jr lt, DiskSel_SendFileInfo
	lds32 xwa, 0
	ld xbc, 0x1c0000b
	lds32 xde, 0
	calr FmmDiskMedley1Func
	lds32 xwa, 0
	ld xbc, 0x1c0000b
	lds32 xde, 0
	calr FmmDiskMedley2Func
	lds32 xwa, 0
	ld xbc, 0x1c0000b
	ld xde, 0x770008
	calr DiskNameFunc
	lds32 xwa, 0
	ld xbc, 0x1c0000b
	ld xde, 0x770009
	calr DiskInfoFunc
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	lds wa, 0
	calr InitializeOperationState
	call FileIO_ParseDirectoryEntry
	ldw_erp HL, 0xfa
	calr SignalProgressUpdate
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	call ApPostEvent
	cpiw_erp 0xfa, 0
	jr ge, DiskSel_PlayNext
	stdi8 0x84fe, 0
	ldw wa, 0x60
	call UI_PostModeChangeEvent
	stw_erp WA, 0xfa
	lds bc, 1
	calr FileIO_ValidateSignedValue
	stb_d8 0x7f42, l
	ldw wa, 0xee
	jrl DiskSel_ShowErrorAndExit

DiskSel_PlayNext:
	incdi8 1, 0x893c
	ld xwa, (xsp + 14)
	ld xbc, 0x1c00017
	ld xde, 0xd
	calr DiskMed_PlayNextHelper
	cps l, 1
	jr nz, DiskSel_NextSongLoop
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009a
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0x78
	call UI_PostModeChangeEvent
	jr DiskSel_ClearPlaying

DiskSel_NextSongLoop:
	inc 1, iz
	cp iz, 0x14
	jrl lt, DiskSel_FindSongLoop

DiskSel_ClearPlaying:
	stdi8 0x84fe, 0
	jrl DiskSel_Exit

DiskSel_CheckRepeat:
	cpdi8 0x893e, 0
	jr z, DiskSel_ClearPlaying
	stdi8 0x893c, 0
	lds iz, 0

DiskSel_RepeatClear:
	stb_erp A, 0xf8
	extz wa
	call FileIO_FormatName_Loop
	inc 1, iz
	cp iz, 0x8
	jr lt, DiskSel_RepeatClear
	lds iz, 0

DiskSel_RepeatFindLoop:
	lda_d16 xwa, 0x8926
	ldb_sri A, 0x07, 0xe0, 0xf8
	cpda8 a, 0x893c
	jrl nz, DiskSel_RepeatNext
	stda16 0x83de, xiz
	ld wa, iz
	call NotifyUIOfSelectionChange
	ldw_d16 xde, 0x83de
	exts xde
	ldda32 xwa, 0x83da
	ld xbc, 0x1e50002
	call ApPostEvent
	ldiw_erp 0xfa, 0

DiskSel_RepeatSendInfo:
	stw_erp DE, 0xfa
	sll de, 5
	lda_d16 xbc, 0x850c
	extz xde
	add xde, xbc
	ldda32 xwa, 0x83da
	ld xbc, 0x1c0000f
	call ApPostEvent
	inc1w_erp 0xfa
	cp_erpw 0xfa, 0x14, 0x00
	jr lt, DiskSel_RepeatSendInfo
	lds32 xwa, 0
	ld xbc, 0x1c0000b
	lds32 xde, 0
	calr FmmDiskMedley1Func
	lds32 xwa, 0
	ld xbc, 0x1c0000b
	lds32 xde, 0
	calr FmmDiskMedley2Func
	lds32 xwa, 0
	ld xbc, 0x1c0000b
	ld xde, 0x770008
	calr DiskNameFunc
	lds32 xwa, 0
	ld xbc, 0x1c0000b
	ld xde, 0x770009
	calr DiskInfoFunc
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	lds wa, 0
	calr InitializeOperationState
	call FileIO_ParseDirectoryEntry
	ldw_erp HL, 0xfa
	calr SignalProgressUpdate
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	call ApPostEvent
	cpiw_erp 0xfa, 0
	jr ge, DiskSel_RepeatPlayNext
	stdi8 0x84fe, 0
	ldw wa, 0x60
	call UI_PostModeChangeEvent
	stw_erp WA, 0xfa
	lds bc, 1
	calr FileIO_ValidateSignedValue
	stb_d8 0x7f42, l
	ldw wa, 0xee
	jrl DiskSel_ShowErrorAndExit

DiskSel_RepeatPlayNext:
	incdi8 1, 0x893c
	ld xwa, (xsp + 14)
	ld xbc, 0x1c00017
	ld xde, 0xd
	calr DiskMed_PlayNextHelper
	cps l, 1
	jr nz, DiskSel_RepeatNext
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009a
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0x78

DiskSel_CallPauseMode:
	call UI_PostModeChangeEvent
	jrl DiskSel_Exit

DiskSel_RepeatNext:
	inc 1, iz
	cp iz, 0x14
	jrl lt, DiskSel_RepeatFindLoop
	jrl DiskSel_Exit

DiskSel_HandleError:
	call Medley_GetPlaybackStatus
	stdi8 0x84fe, 0
	cps l, 0
	jr nz, DiskSel_ShowError
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	call ApPostEvent
	jrl DiskSel_Exit

DiskSel_ShowError:
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call ApPostEvent
	stdi8 0x7f42, 14
	ldw wa, 0xee
	jrl DiskSel_ShowErrorAndExit

DiskSel_HandleStopEvent:
	cpdi8 0x8d36, 120
	jr z, DiskSel_PostStopEvent
	call CDlike_ExitModeAndRestore
	stdi8 0x84fe, 0

DiskSel_PostStopEvent:
	calr CancelOperationCleanup
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	jrl DiskSel_PostEvent

DiskSel_StoreWindowPtr:
	ld xwa, (xsp + 6)
	stda32 0x83da, xwa
	call GetCurrentFileIndex
	stda16 0x83de, xhl
	cps hl, 0
	jr lt, DiskSel_DefaultIndex
	exts xhl
	ldda32 xwa, 0x83da
	ld xbc, 0x1e50002
	ld xde, xhl
	jrl DiskSel_PostEvent

DiskSel_DefaultIndex:
	stdi16 0x83de, 0
	ldda32 xwa, 0x83da
	ld xbc, 0x1e50002
	lds32 xde, 0
	jrl DiskSel_PostEvent

DiskSel_InitDisplay:
	lds iz, 0

DiskSel_DisplayLoop:
	ld wa, iz
	ld hl, wa
	sll hl, 5
	lda_d16 xde, 0x850c
	extz xhl
	add xhl, xde
	stb_erp C, 0xf8
	ld (xhl), c
	lds bc, 2
	call FileIO_CheckRecordByFile
	ld wa, iz
	cps l, 0
	jr nz, DiskSel_GetFileName
	ldw bc, 0x8
	call FileIO_CheckRecordByFile
	cps l, 0
	jr z, DiskSel_EmptyFileName
	ld wa, iz

DiskSel_GetFileName:
	call GetFileEntryPtr
	ld xbc, xhl
	jr DiskSel_FormatEntry

DiskSel_EmptyFileName:
	lda_24 xbc, Data_SaveLoadMenuTable_0x64

DiskSel_FormatEntry:
	ld de, iz
	ld wa, de
	sll wa, 5
	lds hl, 1
	add hl, wa
	lda_d16 xix, 0x850c
	extz xhl
	add xhl, xix
	inc 1, de
	pushw 0x6
	pushw 0x0
	ld xwa, xhl
	call FileIO_ReadHeader_ParseLoop
	ld de, iz
	sll de, 5
	lda_d16 xbc, 0x850c
	extz xde
	add xde, xbc
	ldda32 xwa, 0x83da
	ld xbc, 0x1c0000f
	call ApPostEvent
	inc 1, iz
	cp iz, 0x14
	jr lt, DiskSel_DisplayLoop
	jrl DiskSel_Exit

DiskSel_HandleNavigation:
	ldw_d16 xde, 0x83de
	ld (xsp + 4), de
	ld xbc, (xsp + 10)
	ld xwa, (xsp + 6)
	or xwa, xwa
	jr nz, DiskSel_CheckPage
	cpdi8 0x84fe, 0
	jr nz, DiskSel_CheckPage
	ld xwa, xbc
	cp xbc, 0x1c00018
	jr nz, DiskSel_CheckPrevKey
	cp de, 0x13
	jrl ge, DiskSel_GetCurrentIndex
	inc 1, de
	jr DiskSel_SaveIndex

DiskSel_CheckPrevKey:
	cp xwa, 0x1c00017
	jrl nz, DiskSel_GetCurrentIndex
	cps de, 0
	jrl le, DiskSel_GetCurrentIndex
	dec 1, de
	jr DiskSel_SaveIndex

DiskSel_CheckPage:
	ld xwa, (xsp + 6)
	cp xwa, 0x1
	jr nz, DiskSel_CheckPageDown
	cpdi8 0x84fe, 0
	jr nz, DiskSel_CheckPageDown
	cp de, 0xa
	jrl lt, DiskSel_GetCurrentIndex
	sub de, 0xa
	jr DiskSel_SaveIndex

DiskSel_CheckPageDown:
	ld xwa, (xsp + 6)
	cp xwa, 0x2
	jr nz, DiskSel_HandleToggle
	cpdi8 0x84fe, 0
	jr nz, DiskSel_HandleToggle
	ld wa, de
	add wa, 0xa
	cp wa, 0x13
	jrl gt, DiskSel_GetCurrentIndex
	add de, 0xa

DiskSel_SaveIndex:
	stda16 0x83de, xde
	jrl DiskSel_UpdateDisplay

DiskSel_HandleToggle:
	lda_d16 xhl, 0x8926
	ld xwa, (xsp + 6)
	cp xwa, 0xa
	jr nz, DiskSel_HandleSelect
	cpdi8 0x84fe, 0
	jr nz, DiskSel_HandleSelect
	lds iz, 0

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
	ld a, (xhl)
	cp a, 0xfe
	jr nz, DiskSel_NextAssign
	ldmi16 (xhl), 0x893a
	incdi8 1, 0x893a

DiskSel_NextAssign:
	inc 1, xhl
	cp xhl, xde
	jr c, DiskSel_AssignLoop
	jr DiskSel_RefreshDisplay

DiskSel_UnmarkLoop:
	ld a, (xhl)
	cp a, 0xfd
	jr ugt, DiskSel_NextUnmark
	ld (xhl), 0xfe
	decdi8 1, 0x893a

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
	ld xwa, (xsp + 6)
	cp xwa, 0xb
	jr nz, DiskSel_HandleRepeat
	cpdi8 0x84fe, 0
	jr nz, DiskSel_HandleRepeat
	ld xix, xhl
	stb_dri A, 0x07, 0xec, 0xe8
	ld a, (xbc)
	cp a, 0xfe
	jr nz, DiskSel_RemoveSelect
	ldmi16 (xbc), 0x893a
	incdi8 1, 0x893a
	jr DiskSel_RefreshAfterSelect

DiskSel_RemoveSelect:
	cp a, 0xfd
	jr ugt, DiskSel_RefreshAfterSelect
	cp de, 0x14
	jr ge, DiskSel_ReorderSlots
	ld (xbc), 0xfe
	decdi8 1, 0x893a

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
	ld xwa, (xsp + 6)
	cp xwa, 0xc
	jr nz, DiskSel_HandlePlayStart
	cp xbc, 0x1c00017
	jr nz, DiskSel_SetRepeatOff
	stdi8 0x893e, 1
	jrl DiskSel_GetCurrentIndex

DiskSel_SetRepeatOff:
	stdi8 0x893e, 0
	jrl DiskSel_GetCurrentIndex

DiskSel_HandlePlayStart:
	ld xwa, (xsp + 6)
	cp xwa, 0xd
	jrl nz, DiskSel_HandleAllCheck
	cpdi8 0x84fe, 0
	jrl nz, DiskSel_HandleAllCheck
	stdi8 0x893c, 0
	lds iz, 0

DiskSel_PlayClearLoop:
	stb_erp A, 0xf8
	extz wa
	call FileIO_FormatName_Loop
	inc 1, iz
	cp iz, 0x8
	jr lt, DiskSel_PlayClearLoop
	lds iz, 0

DiskSel_PlayFindLoop:
	lda_d16 xwa, 0x8926
	ldb_sri A, 0x07, 0xe0, 0xf8
	cpda8 a, 0x893c
	jrl nz, DiskSel_PlayNextLoop
	stda16 0x83de, xiz
	ld wa, iz
	call NotifyUIOfSelectionChange
	ldw_d16 xde, 0x83de
	exts xde
	ldda32 xwa, 0x83da
	ld xbc, 0x1e50002
	call ApPostEvent
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	call FileIO_ParseDirectoryEntry
	ldw_erp HL, 0xfa
	calr SignalProgressUpdate
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	call ApPostEvent
	cpiw_erp 0xfa, 0
	jr ge, DiskSel_PlayNextSong
	stdi8 0x84fe, 0
	ldw wa, 0x60
	call UI_PostModeChangeEvent
	stw_erp WA, 0xfa
	lds bc, 1
	calr FileIO_ValidateSignedValue
	stb_d8 0x7f42, l
	ldw wa, 0xee

DiskSel_ShowErrorAndExit:
	call SoundCtrl_SendCommand
	jrl DiskSel_Exit

DiskSel_PlayNextSong:
	ldmw2 (xsp + 4), 0x83de
	incdi8 1, 0x893c
	ld xwa, (xsp + 14)
	ld xbc, (xsp + 10)
	ld xde, (xsp + 6)
	calr DiskMed_PlayNextHelper
	cps l, 1
	jr nz, DiskSel_PlayNextLoop
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009a
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0x78
	call UI_PostModeChangeEvent
	jr DiskSel_GetCurrentIndex

DiskSel_PlayNextLoop:
	inc 1, iz
	cp iz, 0x14
	jrl lt, DiskSel_PlayFindLoop
	jr DiskSel_GetCurrentIndex

DiskSel_HandleAllCheck:
	ld xwa, (xsp + 6)
	cp xwa, 0xe
	jr nz, DiskSel_GetCurrentIndex
	cp xbc, 0x1c00017
	jr nz, DiskSel_SetAllOff
	stdi8 0x8940, 1
	jr DiskSel_GetCurrentIndex

DiskSel_SetAllOff:
	stdi8 0x8940, 0

DiskSel_GetCurrentIndex:
	ldw_d16 xde, 0x83de

DiskSel_UpdateDisplay:
	cp (xsp + 4), de
	jr z, DiskSel_Exit
	ld wa, de
	call NotifyUIOfSelectionChange
	ldw_d16 xde, 0x83de
	exts xde
	ldda32 xwa, 0x83da
	ld xbc, 0x1e50002
	call ApPostEvent
	ld de, (xsp + 4)
	sll de, 5
	lda_d16 xbc, 0x850c
	extz xde
	add xde, xbc
	ldda32 xwa, 0x83da
	ld xbc, 0x1c0000f
	call ApPostEvent
	ldw_d16 xde, 0x83de
	sll de, 5
	lda_d16 xbc, 0x850c
	extz xde
	add xde, xbc
	ldda32 xwa, 0x83da
	ld xbc, 0x1c0000f

DiskSel_PostEvent:
	call ApPostEvent

DiskSel_Exit:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 14)
	ret

GetPlayState1_Entry:
GetPlayState1:
	ldb_d8 l, 0x8942
	ret

GetPlayState2_Entry:
GetPlayState2:
	ldb_d8 l, 0x8944
	ret

SmfMedley_RawData:
	.byte 0xc9, 0xd8, 0xd8, 0x7e, 0xf1, 0x44, 0x89, 0x41
	ret

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
	cpdi16 0x8504, 0
	jr le, NavSong_Exit
	call GetFirstPageBase
	cps hl, 0
	jr lt, NavSong_Exit
	ld iz, hl
	add iz, (xsp + 2)
	jr ge, NavSong_WrapToEnd
	ldw_d16 xiz, 0x8504
	dec 1, iz
	jr NavSong_CheckEnd

NavSong_WrapToEnd:
	cpda16 xiz, 0x8504
	jr lt, NavSong_CheckEnd
	lds iz, 0

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
	cpdi16 0x8508, 0
	jr le, NavDoc_Exit
	call FileIO_GetCurrentFileIndex_Alt
	cps hl, 0
	jr lt, NavDoc_Exit
	ld wa, hl
	add wa, iz
	jr ge, NavDoc_WrapToEnd
	ldw_d16 xwa, 0x8508
	dec 1, wa
	jr NavDoc_CheckEnd

NavDoc_WrapToEnd:
	cpda16 xwa, 0x8508
	jr lt, NavDoc_CheckEnd
	lds wa, 0

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
	cpdi16 0x8506, 0
	jr le, NavPd_Exit
	call GetCurrentFileIndexAlt
	cps hl, 0
	jr lt, NavPd_Exit
	ld wa, hl
	add wa, iz
	jr ge, NavPd_WrapToEnd
	ldw_d16 xwa, 0x8506
	dec 1, wa
	jr NavPd_CheckEnd

NavPd_WrapToEnd:
	cpda16 xwa, 0x8506
	jr lt, NavPd_CheckEnd
	lds wa, 0

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
	ld wa, iz
	sll wa, 3
	lda_d16 xbc, 0x83e0
	extz xwa
	add xwa, xbc
	stw_erp BC, 0xfa
	add bc, iz
	lda_d16 xde, 0x88a0
	extz xbc
	add xbc, xde
	ld c, (xbc)
	extz bc
	ld de, iz
	calr FormatMedleyNumber
	ld de, iz
	sll de, 3
	lda_d16 xwa, 0x83e0
	extz xde
	add xde, xwa
	ld xwa, (xsp + 6)
	ld xbc, 0x1c0000f
	call ApPostEvent
	inc 1, iz
	cp iz, (xsp + 4)
	jr c, SmfFmt_FormatLoop

SmfFmt_FillEmpty:
	cp iz, 0xa
	jr nc, SmfFmt_Exit

SmfFmt_EmptyLoop:
	ld wa, iz
	sll wa, 3
	lda_d16 xbc, 0x83e0
	extz xwa
	add xwa, xbc
	ldw bc, 0xff
	ld de, iz
	calr FormatMedleyNumber
	ld de, iz
	sll de, 3
	lda_d16 xwa, 0x83e0
	extz xde
	add xde, xwa
	ld xwa, (xsp + 6)
	ld xbc, 0x1c0000f
	call ApPostEvent
	inc 1, iz
	cp iz, 0xa
	jr c, SmfFmt_EmptyLoop

SmfFmt_Exit:
	pop xiz
	inc 6, xsp
	ret

FmmSmfMedleyFunc:
	dec 4, xsp
	pushw iz
	ld xhl, xbc
	ld (xsp + 2), xwa
	cp xhl, 0x1e5000a
	jrl z, SmfMed_CheckContinue
	ld xwa, xde
	cp xhl, 0x1e50008
	jrl z, SmfMed_StoreDelayFlag
	ldw_d16 xbc, 0x8438
	cp xhl, 0x1c00018
	jrl z, SmfMed_HandleNavToggle
	cp xhl, 0x1c00017
	jrl z, SmfMed_HandleNavToggle
	cp xhl, 0x1c0000b
	jrl z, SmfMed_RefreshDisplay
	cp xhl, 0x1e50004
	jrl z, SmfMed_StoreWindowPtr
	cp xhl, 0x1c00013
	jrl nz, SmfMed_Exit
	cp xde, 0x3
	jrl z, SmfMed_HandleStop
	cp xde, 0x2
	jrl nz, SmfMed_Exit
	lds wa, 0
	calr InitializeOperationState
	ldb_d8 a, 0x8d37
	stb_d8 0x843a, a
	cp a, 0x6f
	jr z, SmfMed_CheckNotPlaying
	cp a, 0x72
	jr nz, SmfMed_CheckPlayMode

SmfMed_CheckNotPlaying:
	stdi8 0x84fe, 0
	call Medley_GetPlaybackStatus
	cps l, 4
	jr z, SmfMed_Error3F
	cps l, 3
	jr z, SmfMed_Error31
	cps l, 2
	jrl nz, SmfMed_Exit
	stdi8 0x7f42, 1
	ldw wa, 0xee
	jr SmfMed_ShowError

SmfMed_Error31:
	stdi8 0x7f42, 49
	ldw wa, 0xee
	jr SmfMed_ShowError

SmfMed_Error3F:
	stdi8 0x7f42, 63
	ldw wa, 0xee

SmfMed_ShowError:
	call SoundCtrl_SendCommand
	jrl SmfMed_Exit

SmfMed_CheckPlayMode:
	cp a, 0x73
	jr z, SmfMed_CheckPlaying
	cp a, 0x76
	jrl nz, SmfMed_InitFromDisk

SmfMed_CheckPlaying:
	call Medley_GetPlaybackStatus
	cps l, 1
	jrl c, SmfMed_CheckNotPlayError
	call Medley_GetPlaybackStatus
	cps l, 4
	jr z, SmfMed_PlayError3F
	cps l, 3
	jr z, SmfMed_PlayError31
	cps l, 2
	jr nz, SmfMed_SetPlaying
	stdi8 0x7f42, 1
	ldw wa, 0xee
	jr SmfMed_ShowPlayError

SmfMed_PlayError31:
	stdi8 0x7f42, 49
	ldw wa, 0xee
	jr SmfMed_ShowPlayError

SmfMed_PlayError3F:
	stdi8 0x7f42, 63
	ldw wa, 0xee

SmfMed_ShowPlayError:
	call SoundCtrl_SendCommand
	incdi8 1, 0x843c

SmfMed_SetPlaying:
	stdi8 0x84fe, 1
	ldb_d8 a, 0x8922
	cpda8 a, 0x8920
	jr nc, SmfMed_CheckRepeat
	lds iz, 0
	ldw_d16 xbc, 0x8438
	cps bc, 0
	jrl ule, SmfMed_Exit
	lda_d16 xde, 0x88a0

SmfMed_FindSongLoop:
	ld hl, iz
	extz xhl
	add xhl, xde
	cp (xhl), a
	jr nz, SmfMed_NextSong
	ld de, iz
	extz xde
	ld xwa, (xsp + 2)
	ld xbc, 0x1e50002
	calr FmmSmfFileNameFunc
	ldda32 xwa, 0x8430
	ldw_d16 xbc, 0x8438
	calr SmfMed_FormatSlotList
	incdi8 1, 0x8922
	ld wa, iz
	call GetFileEntryByIndex
	ldda32 xwa, 0x8434
	or xwa, xwa
	jrl z, SmfMed_Exit
	ld xbc, 0x1e50009
	ld xde, 0x1e
	jr SmfMed_PostDelayEvent

SmfMed_NextSong:
	inc 1, iz
	cp iz, bc
	jr c, SmfMed_FindSongLoop
	jrl SmfMed_Exit

SmfMed_CheckRepeat:
	cpdi8 0x8924, 0
	jr z, SmfMed_ClearRepeatCount
	cpdm8 0x843c, a
	jr nc, SmfMed_ClearRepeatCount
	stdi8 0x8922, 0
	stdi8 0x843c, 0
	lds iz, 0
	ldw_d16 xwa, 0x8438
	cps wa, 0
	jrl ule, SmfMed_Exit
	lda_d16 xbc, 0x88a0

SmfMed_RepeatFindLoop:
	ld de, iz
	extz xde
	add xde, xbc
	cp (xde), 0x0
	jr nz, SmfMed_RepeatNext
	ld de, iz
	extz xde
	ld xwa, (xsp + 2)
	ld xbc, 0x1e50002
	calr FmmSmfFileNameFunc
	ldda32 xwa, 0x8430
	ldw_d16 xbc, 0x8438
	calr SmfMed_FormatSlotList
	incdi8 1, 0x8922
	ld wa, iz
	call GetFileEntryByIndex
	ldda32 xwa, 0x8434
	or xwa, xwa
	jrl z, SmfMed_Exit
	ld xbc, 0x1e50009
	ld xde, 0x1e

SmfMed_PostDelayEvent:
	call ApPostEvent
	jrl SmfMed_Exit

SmfMed_RepeatNext:
	inc 1, iz
	cp iz, wa
	jr c, SmfMed_RepeatFindLoop
	jrl SmfMed_Exit

SmfMed_ClearRepeatCount:
	stdi8 0x843c, 0
	jr SmfMed_ClearPlaying

SmfMed_CheckNotPlayError:
	call Medley_GetPlaybackStatus
	cps l, 0
	jrl nz, SmfMed_Exit

SmfMed_ClearPlaying:
	stdi8 0x84fe, 0
	jrl SmfMed_Exit

SmfMed_InitFromDisk:
	lds32 xde, 0
	ldb_d8 e, 0x8944
	ld xwa, 0x6c0018
	ld xbc, 0x1e0003b
	call ApPostEvent
	cpdi16 0x8504, 0
	jr ge, SmfMed_InitState
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	call GetFileCountEncoded
	stda16 0x8504, xhl
	call FileIO_SearchAndLoadFile
	call GetEncodedFreeSpaceData
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	call ApPostEvent
	calr SignalProgressUpdate

SmfMed_InitState:
	stdi8 0x84fe, 0
	stdi8 0x8922, 0
	stdi8 0x8920, 0
	ldw bc, 0x80
	ldw_d16 xwa, 0x8504
	cp wa, 0x80
	jr ugt, SmfMed_ClampFileCount
	ld bc, wa

SmfMed_ClampFileCount:
	stda16 0x8438, xbc
	lds iz, 0
	cps bc, 0
	jr ule, SmfMed_FinishInit
	lda_d16 xwa, 0x88a0

SmfMed_ClearSlotsLoop:
	ld bc, iz
	extz xbc
	add xbc, xwa
	ld (xbc), 0xff
	inc 1, iz
	cpda16 xiz, 0x8438
	jr c, SmfMed_ClearSlotsLoop

SmfMed_FinishInit:
	call CDlike_InitModeAndLoadBank
	lds32 xwa, 0
	stda32 0x8434, xwa
	jrl SmfMed_Exit

SmfMed_HandleStop_Entry:
SmfMed_HandleStop:
	ldb_d8 a, 0x8d36
	cp a, 0x6f
	jrl z, SmfMed_Exit
	cp a, 0x72
	jrl z, SmfMed_Exit
	cp a, 0x73
	jrl z, SmfMed_Exit
	cp a, 0x76
	jrl z, SmfMed_Exit
	call CDlike_ExitModeAndRestore
	calr CancelOperationCleanup
	stdi8 0x84fe, 0
	jrl SmfMed_Exit

SmfMed_StoreWindowPtr:
	stda32 0x8430, xwa
	jrl SmfMed_Exit

SmfMed_RefreshDisplay:
	ldda32 xwa, 0x8430
	calr SmfMed_FormatSlotList
	jrl SmfMed_Exit

SmfMed_HandleNavToggle:
	lda_d16 xwa, 0x88a0
	cp xde, 0xa
	jr nz, SmfMed_HandleSelectToggle
	cpdi8 0x84fe, 0
	jr nz, SmfMed_HandleSelectToggle
	lds iz, 0
	ld de, bc
	cps bc, 0
	jr ule, SmfMed_CheckAllUnmarked

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
	cp iz, de
	jr nc, SmfMed_RemoveOrderLoop
	lds iz, 0
	cps de, 0
	jr ule, SmfMed_RefreshAfterToggle
	lda_d16 xde, 0x88a0

SmfMed_AssignOrderLoop:
	ld bc, iz
	extz xbc
	add xbc, xde
	ld a, (xbc)
	cp a, 0xff
	jr nz, SmfMed_NextAssign
	ldmi16 (xbc), 0x8920
	incdi8 1, 0x8920

SmfMed_NextAssign:
	inc 1, iz
	cpda16 xiz, 0x8438
	jr c, SmfMed_AssignOrderLoop
	jr SmfMed_RefreshAfterToggle

SmfMed_RemoveOrderLoop:
	lds iz, 0
	cps de, 0
	jr ule, SmfMed_RefreshAfterToggle
	lda_d16 xde, 0x88a0

SmfMed_UnmarkLoop:
	ld bc, iz
	extz xbc
	add xbc, xde
	ld a, (xbc)
	cp a, 0xfd
	jr ugt, SmfMed_NextUnmark
	ld (xbc), 0xff
	decdi8 1, 0x8920

SmfMed_NextUnmark:
	inc 1, iz
	cpda16 xiz, 0x8438
	jr c, SmfMed_UnmarkLoop

SmfMed_RefreshAfterToggle:
	ldda32 xwa, 0x8430
	ldw_d16 xbc, 0x8438
	jr SmfMed_CallFormatSlots

SmfMed_HandleSelectToggle:
	cp xde, 0xb
	jr nz, SmfMed_HandleRepeat
	cpdi8 0x84fe, 0
	jr nz, SmfMed_HandleRepeat
	ld xwa, (xsp + 2)
	ld xbc, 0x1e50003
	lds32 xde, 0
	calr FmmSmfFileNameFunc
	ld iz, hl
	lda_d16 xhl, 0x88a0
	ld wa, iz
	extz xwa
	add xwa, xhl
	ld c, (xwa)
	cp c, 0xff
	jr nz, SmfMed_RemoveFromOrder
	ldmi16 (xwa), 0x8920
	incdi8 1, 0x8920
	jr SmfMed_RefreshAfterSelect

SmfMed_RemoveFromOrder:
	cp c, 0xfd
	jr ugt, SmfMed_RefreshAfterSelect
	ld (xwa), 0xff
	ldb_d8 a, 0x8920
	dec 1, a
	stb_d8 0x8920, a
	lds iy, 0
	lds iz, 0
	extz wa
	cps wa, 0
	jr ule, SmfMed_RefreshAfterSelect
	ld ix, wa

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
	ldda32 xwa, 0x8430
	ldw_d16 xbc, 0x8438

SmfMed_CallFormatSlots:
	calr SmfMed_FormatSlotList
	jrl SmfMed_Exit

SmfMed_HandleRepeat:
	cp xde, 0xc
	jr nz, SmfMed_HandlePlay
	cp xhl, 0x1c00017
	jr nz, SmfMed_SetRepeatOff
	stdi8 0x8924, 1
	jrl SmfMed_Exit

SmfMed_SetRepeatOff:
	stdi8 0x8924, 0
	jrl SmfMed_Exit

SmfMed_HandlePlay:
	cp xde, 0xd
	jrl nz, SmfMed_Exit
	cpdi8 0x84fe, 0
	jrl nz, SmfMed_Exit
	stdi8 0x8922, 0
	stdi8 0x843c, 0
	lds iz, 0
	ldw_d16 xbc, 0x8438
	cps bc, 0
	jr ule, SmfMed_CheckAutoPlay

SmfMed_PlayFindLoop:
	ld de, iz
	extz xde
	add xde, xwa
	cp (xde), 0x0
	jr nz, SmfMed_PlayNextLoop
	stdi8 0x84fe, 1
	ld de, iz
	extz xde
	ld xwa, (xsp + 2)
	ld xbc, 0x1e50002
	calr FmmSmfFileNameFunc
	incdi8 1, 0x8922
	ld wa, iz
	call GetFileEntryByIndex
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009a
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0x73
	call UI_PostModeChangeEvent
	jr SmfMed_CheckAutoPlay

SmfMed_PlayNextLoop:
	inc 1, iz
	cp iz, bc
	jr c, SmfMed_PlayFindLoop

SmfMed_CheckAutoPlay:
	cpdi8 0x84fe, 0
	jr nz, SmfMed_Exit
	ld xwa, (xsp + 2)
	ld xbc, 0x1e50003
	lds32 xde, 0
	calr FmmSmfFileNameFunc
	ld iz, hl
	ld wa, iz
	call GetFileEntryByIndex
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009a
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0x6f
	jr SmfMed_CallPauseMode

SmfMed_StoreDelayFlag:
	stda32 0x8434, xwa
	jr SmfMed_Exit

SmfMed_CheckContinue:
	cpdi8 0x84fe, 0
	jr z, SmfMed_Exit
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009a
	lds32 xde, 0
	call ApPostEvent
	ldb_d8 a, 0x843a
	extz wa

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
	ld de, iz
	sll de, 5
	lda_d16 xbc, 0x850c
	extz xde
	add xde, xbc
	stb_erp A, 0xf8
	ld (xde), a
	ld wa, (xsp + 2)
	add wa, iz
	call GetFileRecordPtr
	ld xbc, xhl
	ld wa, iz
	sll wa, 5
	lds de, 1
	add de, wa
	lda_d16 xhl, 0x850c
	ld wa, de
	extz xwa
	add xwa, xhl
	ld de, (xsp + 2)
	add de, iz
	inc 1, de
	pushw 0x14
	pushw 0x1
	call FileIO_ReadHeader_ParseLoop
	ld de, iz
	sll de, 5
	lda_d16 xbc, 0x850c
	extz xde
	add xde, xbc
	ld xwa, (xsp + 4)
	ld xbc, 0x1c0000f
	call ApPostEvent
	inc 1, iz
	cp iz, 0xa
	jr lt, PdFmt_FormatLoop
	popw iz
	inc 6, xsp
	ret

FmmPdFileNameFunc:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xwa
	cp xbc, 0x1e50003
	jrl z, PdName_GetIndexReturn
	ldw_d16 xwa, 0x8442
	ld iz, wa
	cp xbc, 0x1e50002
	jrl z, PdName_SetIndexPlaying
	ld hl, wa
	exts xhl
	divs hl, 0xa
	cp xbc, 0x1c00018
	jr z, PdName_HandleNavigation
	cp xbc, 0x1c00017
	jr z, PdName_HandleNavigation
	cp xbc, 0x1c0000b
	jr z, PdName_RefreshList
	cp xbc, 0x1e50004
	jr nz, PdName_ReturnZero
	stda32 0x843e, xde
	call GetCurrentFileIndexAlt
	stda16 0x8442, xhl
	cps hl, 0
	jr ge, PdName_UpdateIndex
	stdi16 0x8442, 0

PdName_UpdateIndex:
	ldw_d16 xwa, 0x8442
	exts xwa
	divs wa, 0xa
	stw_erp DE, 0xe2
	exts xde
	ldda32 xwa, 0x843e
	ld xbc, 0x1e50002
	jrl PdName_PostEvent

PdName_RefreshList:
	muls hl, 0xa
	ldda32 xwa, 0x843e
	ld bc, hl
	calr PdMed_FormatFileList

PdName_ReturnZero:
	lds32 xhl, 0
	jrl PdName_Exit

PdName_HandleNavigation:
	or xde, xde
	jr nz, PdName_CheckPageUp
	cpdi8 0x84fe, 0
	jr nz, PdName_CheckPageUp
	cp xbc, 0x1c00018
	jr nz, PdName_CheckPrevKey
	ld bc, wa
	inc 1, bc
	cpda16 xbc, 0x8506
	jr ge, PdName_GetCurrentIndex
	inc 1, wa
	jr PdName_SaveIndex

PdName_CheckPrevKey:
	cp xbc, 0x1c00017
	jr nz, PdName_GetCurrentIndex
	cps wa, 0
	jr le, PdName_GetCurrentIndex
	dec 1, wa
	jr PdName_SaveIndex

PdName_CheckPageUp:
	cp xde, 0x1
	jr nz, PdName_CheckPageDown
	cpdi8 0x84fe, 0
	jr nz, PdName_CheckPageDown
	cp wa, 0xa
	jr lt, PdName_GetCurrentIndex
	sub wa, 0xa
	jr PdName_SaveIndex

PdName_CheckPageDown:
	cp xde, 0x2
	jr nz, PdName_GetCurrentIndex
	cpdi8 0x84fe, 0
	jr nz, PdName_GetCurrentIndex
	ld bc, wa
	add bc, 0xa
	ldw_d16 xde, 0x8506
	cp bc, de
	jr ge, PdName_CheckEndBound
	add wa, 0xa

PdName_SaveIndex:
	stda16 0x8442, xwa
	jr PdName_UpdateDisplay

PdName_CheckEndBound:
	ld bc, de
	dec 1, bc
	ld wa, bc
	exts xwa
	divs wa, 0xa
	cp hl, wa
	jr ge, PdName_GetCurrentIndex
	exts xde
	divs de, 0xa
	stw_erp WA, 0xea
	cps wa, 0
	jr z, PdName_GetCurrentIndex
	stda16 0x8442, xbc

PdName_GetCurrentIndex:
	ldw_d16 xwa, 0x8442

PdName_UpdateDisplay:
	cp iz, wa
	jrl z, PdName_ReturnZero
	call SetCurrentFileIndex
	ldw_d16 xwa, 0x8442
	exts xwa
	divs wa, 0xa
	stw_erp DE, 0xe2
	exts xde
	ldda32 xwa, 0x843e
	ld xbc, 0x1e50002
	call ApPostEvent
	ldw_d16 xbc, 0x8442
	exts xbc
	divs bc, 0xa
	ld de, iz
	exts xde
	divs de, 0xa
	ldda32 xwa, 0x843e
	cp de, bc
	jr nz, PdName_RefreshPage
	ld bc, iz
	exts xbc
	divs bc, 0xa
	stw_erp BC, 0xe6
	sll bc, 5
	lda_d16 xhl, 0x850c
	ld de, bc
	extz xde
	add xde, xhl
	ld xbc, 0x1c0000f
	call ApPostEvent
	ldw_d16 xwa, 0x8442
	exts xwa
	divs wa, 0xa
	stw_erp WA, 0xe2
	sll wa, 5
	lda_d16 xbc, 0x850c
	ld de, wa
	extz xde
	add xde, xbc
	ldda32 xwa, 0x843e
	ld xbc, 0x1c0000f
	call ApPostEvent
	jrl PdName_ReturnZero

PdName_RefreshPage:
	muls bc, 0xa
	calr PdMed_FormatFileList
	ld xwa, (xsp + 2)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	calr FmmPdMedleyFunc
	jrl PdName_ReturnZero

PdName_SetIndexPlaying:
	cpdi8 0x84fe, 0
	jrl z, PdName_ReturnZero
	stda16 0x8442, xde
	ld wa, de
	call SetCurrentFileIndex
	ldw_d16 xwa, 0x8442
	exts xwa
	divs wa, 0xa
	stw_erp DE, 0xe2
	exts xde
	ldda32 xwa, 0x843e
	ld xbc, 0x1e50002

PdName_PostEvent:
	call ApPostEvent
	jrl PdName_ReturnZero

PdName_GetIndexReturn:
	ldw_d16 xhl, 0x8442
	exts xhl

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
	ld wa, iz
	sll wa, 3
	lda_d16 xbc, 0x8444
	extz xwa
	add xwa, xbc
	stw_erp BC, 0xfa
	add bc, iz
	lda_d16 xde, 0x88a0
	extz xbc
	add xbc, xde
	ld c, (xbc)
	extz bc
	ld de, iz
	calr FormatMedleyNumber
	ld de, iz
	sll de, 3
	lda_d16 xwa, 0x8444
	extz xde
	add xde, xwa
	ld xwa, (xsp + 6)
	ld xbc, 0x1c0000f
	call ApPostEvent
	inc 1, iz
	cp iz, (xsp + 4)
	jr c, PdFmtSlot_FormatLoop

PdFmtSlot_FillEmpty:
	cp iz, 0xa
	jr nc, PdFmtSlot_Exit

PdFmtSlot_EmptyLoop:
	ld wa, iz
	sll wa, 3
	lda_d16 xbc, 0x8444
	extz xwa
	add xwa, xbc
	ldw bc, 0xff
	ld de, iz
	calr FormatMedleyNumber
	ld de, iz
	sll de, 3
	lda_d16 xwa, 0x8444
	extz xde
	add xde, xwa
	ld xwa, (xsp + 6)
	ld xbc, 0x1c0000f
	call ApPostEvent
	inc 1, iz
	cp iz, 0xa
	jr c, PdFmtSlot_EmptyLoop

PdFmtSlot_Exit:
	pop xiz
	inc 6, xsp
	ret

FmmPdMedleyFunc_Entry:
FmmPdMedleyFunc:
	push xiz
	ld xhl, xde
	ld xde, xbc
	ld xiz, xwa
	cp xde, 0x1e5000a
	jrl z, PdMed_CheckContinue
	ld xwa, xhl
	cp xde, 0x1e50008
	jrl z, PdMed_StoreDelayFlag
	ldw_d16 xbc, 0x849c
	cp xde, 0x1c00018
	jrl z, PdMed_HandleNavToggle
	cp xde, 0x1c00017
	jrl z, PdMed_HandleNavToggle
	cp xde, 0x1c0000b
	jrl z, PdMed_RefreshDisplay
	cp xde, 0x1e50004
	jrl z, PdMed_StoreWindowPtr
	cp xde, 0x1c00013
	jrl nz, PdMed_Exit
	cp xhl, 0x3
	jrl z, PdMed_HandleStop
	cp xhl, 0x2
	jrl nz, PdMed_Exit
	lds wa, 0
	call InitializeOperationState
	ldb_d8 a, 0x8d37
	cp a, 0x71
	jr nz, PdMed_CheckPlayMode
	stdi8 0x84fe, 0
	call Medley_GetPlaybackStatus
	cps l, 2
	jrl c, PdMed_Exit
	stdi8 0x7f42, 1
	ldw wa, 0xee
	jrl PdMed_ShowError

PdMed_CheckPlayMode:
	cp a, 0x75
	jrl nz, PdMed_InitFromDisk
	call Medley_GetPlaybackStatus
	cps l, 1
	jrl nz, PdMed_HandleError
	stdi8 0x84fe, 1
	ldb_d8 c, 0x8922
	lda_d16 xwa, 0x88a0
	cpda8 c, 0x8920
	jr nc, PdMed_CheckRepeat
	lds hl, 0
	ldw_d16 xde, 0x849c
	cps de, 0
	jrl ule, PdMed_Exit

PdMed_FindSongLoop:
	ld ix, hl
	extz xix
	add xix, xwa
	cp (xix), c
	jr nz, PdMed_NextSong
	extz xhl
	ld xwa, xiz
	ld xbc, 0x1e50002
	ld xde, xhl
	calr FmmPdFileNameFunc
	ldda32 xwa, 0x8494
	ldw_d16 xbc, 0x849c
	calr PdMed_FormatSlotList
	incdi8 1, 0x8922
	ldda32 xwa, 0x8498
	or xwa, xwa
	jrl z, PdMed_Exit
	ld xbc, 0x1e50009
	ld xde, 0x1e
	jr PdMed_PostDelayEvent

PdMed_NextSong:
	inc 1, hl
	cp hl, de
	jr c, PdMed_FindSongLoop
	jrl PdMed_Exit

PdMed_CheckRepeat:
	cpdi8 0x8924, 0
	jr z, PdMed_ClearPlaying
	stdi8 0x8922, 0
	lds hl, 0
	ldw_d16 xbc, 0x849c
	cps bc, 0
	jrl ule, PdMed_Exit

PdMed_RepeatFindLoop:
	ld de, hl
	extz xde
	add xde, xwa
	cp (xde), 0x0
	jr nz, PdMed_RepeatNext
	extz xhl
	ld xwa, xiz
	ld xbc, 0x1e50002
	ld xde, xhl
	calr FmmPdFileNameFunc
	ldda32 xwa, 0x8494
	ldw_d16 xbc, 0x849c
	calr PdMed_FormatSlotList
	incdi8 1, 0x8922
	ldda32 xwa, 0x8498
	or xwa, xwa
	jrl z, PdMed_Exit
	ld xbc, 0x1e50009
	ld xde, 0x1e

PdMed_PostDelayEvent:
	call ApPostEvent
	jrl PdMed_Exit

PdMed_RepeatNext:
	inc 1, hl
	cp hl, bc
	jr c, PdMed_RepeatFindLoop
	jrl PdMed_Exit

PdMed_ClearPlaying:
	stdi8 0x84fe, 0
	jrl PdMed_Exit

PdMed_HandleError:
	call Medley_GetPlaybackStatus
	stdi8 0x84fe, 0
	cps l, 0
	jrl z, PdMed_Exit
	stdi8 0x7f42, 1
	ldw wa, 0xee

PdMed_ShowError:
	call SoundCtrl_SendCommand
	jrl PdMed_Exit

PdMed_InitFromDisk_Entry:
PdMed_InitFromDisk:
	cpdi16 0x8506, 0
	jr ge, PdMed_InitState
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	call BuildPageRecordsAlt
	stda16 0x8506, xhl
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	call ApPostEvent
	call SignalProgressUpdate

PdMed_InitState:
	stdi8 0x84fe, 0
	stdi8 0x8922, 0
	stdi8 0x8920, 0
	ldw bc, 0x80
	ldw_d16 xwa, 0x8506
	cp wa, 0x80
	jr ugt, PdMed_ClampCount
	ld bc, wa

PdMed_ClampCount:
	stda16 0x849c, xbc
	lds hl, 0
	cps bc, 0
	jr ule, PdMed_FinishInit
	lda_d16 xwa, 0x88a0

PdMed_ClearSlotsLoop:
	ld bc, hl
	extz xbc
	add xbc, xwa
	ld (xbc), 0xff
	inc 1, hl
	cpda16 xhl, 0x849c
	jr c, PdMed_ClearSlotsLoop

PdMed_FinishInit:
	call CDlike_InitModeAndLoadBank
	lds32 xwa, 0
	stda32 0x8498, xwa
	jrl PdMed_Exit

PdMed_HandleStop:
	ldb_d8 a, 0x8d36
	cp a, 0x71
	jrl z, PdMed_Exit
	cp a, 0x75
	jrl z, PdMed_Exit
	call CDlike_ExitModeAndRestore
	call CancelOperationCleanup
	stdi8 0x84fe, 0
	jrl PdMed_Exit

PdMed_StoreWindowPtr:
	stda32 0x8494, xwa
	jrl PdMed_Exit

PdMed_RefreshDisplay:
	ldda32 xwa, 0x8494
	calr PdMed_FormatSlotList
	jrl PdMed_Exit

PdMed_HandleNavToggle:
	cp xhl, 0xa
	jrl nz, PdMed_HandleSelectToggle
	cpdi8 0x84fe, 0
	jr nz, PdMed_HandleSelectToggle
	lds hl, 0
	ld wa, bc
	cps bc, 0
	jr ule, PdMed_CheckAllUnmarked
	lda_d16 xbc, 0x88a0

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
	cp hl, wa
	jr nc, PdMed_RemoveOrderLoop
	lds hl, 0
	cps wa, 0
	jr ule, PdMed_RefreshAfterToggle
	lda_d16 xde, 0x88a0

PdMed_AssignOrderLoop:
	ld bc, hl
	extz xbc
	add xbc, xde
	ld a, (xbc)
	cp a, 0xff
	jr nz, PdMed_NextAssign
	ldmi16 (xbc), 0x8920
	incdi8 1, 0x8920

PdMed_NextAssign:
	inc 1, hl
	cpda16 xhl, 0x849c
	jr c, PdMed_AssignOrderLoop
	jr PdMed_RefreshAfterToggle

PdMed_RemoveOrderLoop:
	lds hl, 0
	cps wa, 0
	jr ule, PdMed_RefreshAfterToggle
	lda_d16 xde, 0x88a0

PdMed_UnmarkLoop:
	ld bc, hl
	extz xbc
	add xbc, xde
	ld a, (xbc)
	cp a, 0xfd
	jr ugt, PdMed_NextUnmark
	ld (xbc), 0xff
	decdi8 1, 0x8920

PdMed_NextUnmark:
	inc 1, hl
	cpda16 xhl, 0x849c
	jr c, PdMed_UnmarkLoop

PdMed_RefreshAfterToggle:
	ldda32 xwa, 0x8494
	ldw_d16 xbc, 0x849c
	jr PdMed_CallFormatSlots

PdMed_HandleSelectToggle:
	cp xhl, 0xb
	jr nz, PdMed_HandleRepeat
	cpdi8 0x84fe, 0
	jr nz, PdMed_HandleRepeat
	ld xwa, xiz
	ld xbc, 0x1e50003
	lds32 xde, 0
	calr FmmPdFileNameFunc
	lda_d16 xix, 0x88a0
	extz xhl
	add xhl, xix
	ld c, (xhl)
	cp c, 0xff
	jr nz, PdMed_RemoveFromOrder
	ldmi16 (xhl), 0x8920
	incdi8 1, 0x8920
	jr PdMed_RefreshAfterSelect

PdMed_RemoveFromOrder:
	cp c, 0xfd
	jr ugt, PdMed_RefreshAfterSelect
	ld (xhl), 0xff
	ldb_d8 a, 0x8920
	dec 1, a
	stb_d8 0x8920, a
	lds iz, 0
	lds hl, 0
	extz wa
	cps wa, 0
	jr ule, PdMed_RefreshAfterSelect
	ld iy, wa

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
	ldda32 xwa, 0x8494
	ldw_d16 xbc, 0x849c

PdMed_CallFormatSlots:
	calr PdMed_FormatSlotList
	jrl PdMed_Exit

PdMed_HandleRepeat:
	cp xhl, 0xc
	jr nz, PdMed_HandlePlay
	cp xde, 0x1c00017
	jr nz, PdMed_SetRepeatOff
	stdi8 0x8924, 1
	jrl PdMed_Exit

PdMed_SetRepeatOff:
	stdi8 0x8924, 0
	jrl PdMed_Exit

PdMed_HandlePlay:
	cp xhl, 0xd
	jrl nz, PdMed_Exit
	cpdi8 0x84fe, 0
	jrl nz, PdMed_Exit
	stdi8 0x8922, 0
	lds hl, 0
	ldw_d16 xwa, 0x849c
	cps wa, 0
	jr ule, PdMed_CheckAutoPlay
	lda_d16 xbc, 0x88a0

PdMed_PlayFindLoop:
	ld de, hl
	extz xde
	add xde, xbc
	cp (xde), 0x0
	jr nz, PdMed_PlayNextLoop
	stdi8 0x84fe, 1
	extz xhl
	ld xwa, xiz
	ld xbc, 0x1e50002
	ld xde, xhl
	calr FmmPdFileNameFunc
	incdi8 1, 0x8922
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009a
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0x75
	call UI_PostModeChangeEvent
	jr PdMed_CheckAutoPlay

PdMed_PlayNextLoop:
	inc 1, hl
	cp hl, wa
	jr c, PdMed_PlayFindLoop

PdMed_CheckAutoPlay:
	cpdi8 0x84fe, 0
	jr nz, PdMed_Exit
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009a
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0x71
	jr PdMed_CallPauseMode

PdMed_StoreDelayFlag:
	stda32 0x8498, xwa
	jr PdMed_Exit

PdMed_CheckContinue:
	cpdi8 0x84fe, 0
	jr z, PdMed_Exit
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009a
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0x75

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
	lda_d16 xbc, 0x878c
	cp (xhl), 0x0
	jr z, DocDisk_TerminateStr
	cp ix, 0x1e
	jr lt, DocDisk_CopyCharLoop

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
	ld de, iz
	sll de, 5
	lda_d16 xbc, 0x850c
	extz xde
	add xde, xbc
	stb_erp A, 0xf8
	ld (xde), a
	ld wa, (xsp + 2)
	add wa, iz
	call FileIO_GetFileEntryWithRefresh
	ld xbc, xhl
	ld wa, iz
	sll wa, 5
	lds de, 1
	add de, wa
	lda_d16 xhl, 0x850c
	ld wa, de
	extz xwa
	add xwa, xhl
	ld de, (xsp + 2)
	add de, iz
	inc 1, de
	pushw 0xc
	pushw 0x0
	call FileIO_ReadHeader_ParseLoop
	ld de, iz
	sll de, 5
	lda_d16 xbc, 0x850c
	extz xde
	add xde, xbc
	ld xwa, (xsp + 4)
	ld xbc, 0x1c0000f
	call ApPostEvent
	inc 1, iz
	cp iz, 0xa
	jr lt, DocFmt_FormatLoop
	popw iz
	inc 6, xsp
	ret

FmmDocFileNameFunc:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xwa
	cp xbc, 0x1e50003
	jrl z, DocName_GetIndexReturn
	ldw_d16 xwa, 0x84a2
	ld iz, wa
	cp xbc, 0x1e50002
	jrl z, DocName_SetIndexPlaying
	ld hl, wa
	exts xhl
	divs hl, 0xa
	cp xbc, 0x1c00018
	jr z, DocName_HandleNavigation
	cp xbc, 0x1c00017
	jr z, DocName_HandleNavigation
	cp xbc, 0x1c0000b
	jr z, DocName_RefreshList
	cp xbc, 0x1e50004
	jr nz, DocName_ReturnZero
	stda32 0x849e, xde
	call FileIO_GetCurrentFileIndex_Alt
	stda16 0x84a2, xhl
	cps hl, 0
	jr ge, DocName_UpdateIndex
	stdi16 0x84a2, 0

DocName_UpdateIndex:
	ldw_d16 xwa, 0x84a2
	exts xwa
	divs wa, 0xa
	stw_erp DE, 0xe2
	exts xde
	ldda32 xwa, 0x849e
	ld xbc, 0x1e50002
	jrl DocName_PostEvent

DocName_RefreshList:
	muls hl, 0xa
	ldda32 xwa, 0x849e
	ld bc, hl
	calr DocMed_FormatFileList

DocName_ReturnZero:
	lds32 xhl, 0
	jrl DocName_Exit

DocName_HandleNavigation:
	or xde, xde
	jr nz, DocName_CheckPageUp
	cpdi8 0x84fe, 0
	jr nz, DocName_CheckPageUp
	cp xbc, 0x1c00018
	jr nz, DocName_CheckPrevKey
	ld bc, wa
	inc 1, bc
	cpda16 xbc, 0x8508
	jr ge, DocName_GetCurrentIndex
	inc 1, wa
	jr DocName_SaveIndex

DocName_CheckPrevKey:
	cp xbc, 0x1c00017
	jr nz, DocName_GetCurrentIndex
	cps wa, 0
	jr le, DocName_GetCurrentIndex
	dec 1, wa
	jr DocName_SaveIndex

DocName_CheckPageUp:
	cp xde, 0x1
	jr nz, DocName_CheckPageDown
	cpdi8 0x84fe, 0
	jr nz, DocName_CheckPageDown
	cp wa, 0xa
	jr lt, DocName_GetCurrentIndex
	sub wa, 0xa
	jr DocName_SaveIndex

DocName_CheckPageDown:
	cp xde, 0x2
	jr nz, DocName_GetCurrentIndex
	cpdi8 0x84fe, 0
	jr nz, DocName_GetCurrentIndex
	ld bc, wa
	add bc, 0xa
	ldw_d16 xde, 0x8508
	cp bc, de
	jr ge, DocName_CheckEndBound
	add wa, 0xa

DocName_SaveIndex:
	stda16 0x84a2, xwa
	jr DocName_UpdateDisplay

DocName_CheckEndBound:
	ld bc, de
	dec 1, bc
	ld wa, bc
	exts xwa
	divs wa, 0xa
	cp hl, wa
	jr ge, DocName_GetCurrentIndex
	exts xde
	divs de, 0xa
	stw_erp WA, 0xea
	cps wa, 0
	jr z, DocName_GetCurrentIndex
	stda16 0x84a2, xbc

DocName_GetCurrentIndex:
	ldw_d16 xwa, 0x84a2

DocName_UpdateDisplay:
	cp iz, wa
	jrl z, DocName_ReturnZero
	call FileIO_SelectFileByIndex
	ldw_d16 xwa, 0x84a2
	exts xwa
	divs wa, 0xa
	stw_erp DE, 0xe2
	exts xde
	ldda32 xwa, 0x849e
	ld xbc, 0x1e50002
	call ApPostEvent
	ldw_d16 xbc, 0x84a2
	exts xbc
	divs bc, 0xa
	ld de, iz
	exts xde
	divs de, 0xa
	ldda32 xwa, 0x849e
	cp de, bc
	jr nz, DocName_RefreshPage
	ld bc, iz
	exts xbc
	divs bc, 0xa
	stw_erp BC, 0xe6
	sll bc, 5
	lda_d16 xhl, 0x850c
	ld de, bc
	extz xde
	add xde, xhl
	ld xbc, 0x1c0000f
	call ApPostEvent
	ldw_d16 xwa, 0x84a2
	exts xwa
	divs wa, 0xa
	stw_erp WA, 0xe2
	sll wa, 5
	lda_d16 xbc, 0x850c
	ld de, wa
	extz xde
	add xde, xbc
	ldda32 xwa, 0x849e
	ld xbc, 0x1c0000f
	call ApPostEvent
	jrl DocName_ReturnZero

DocName_RefreshPage:
	muls bc, 0xa
	calr DocMed_FormatFileList
	ld xwa, (xsp + 2)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	calr FmmDocMedleyFunc
	jrl DocName_ReturnZero

DocName_SetIndexPlaying:
	cpdi8 0x84fe, 0
	jrl z, DocName_ReturnZero
	stda16 0x84a2, xde
	ld wa, de
	call FileIO_SelectFileByIndex
	ldw_d16 xwa, 0x84a2
	exts xwa
	divs wa, 0xa
	stw_erp DE, 0xe2
	exts xde
	ldda32 xwa, 0x849e
	ld xbc, 0x1e50002

DocName_PostEvent:
	call ApPostEvent
	jrl DocName_ReturnZero

DocName_GetIndexReturn:
	ldw_d16 xhl, 0x84a2
	exts xhl

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
	ld wa, iz
	sll wa, 3
	lda_d16 xbc, 0x84a4
	extz xwa
	add xwa, xbc
	stw_erp BC, 0xfa
	add bc, iz
	lda_d16 xde, 0x88a0
	extz xbc
	add xbc, xde
	ld c, (xbc)
	extz bc
	ld de, iz
	calr FormatMedleyNumber
	ld de, iz
	sll de, 3
	lda_d16 xwa, 0x84a4
	extz xde
	add xde, xwa
	ld xwa, (xsp + 6)
	ld xbc, 0x1c0000f
	call ApPostEvent
	inc 1, iz
	cp iz, (xsp + 4)
	jr c, DocFmtSlot_FormatLoop

DocFmtSlot_FillEmpty:
	cp iz, 0xa
	jr nc, DocFmtSlot_Exit

DocFmtSlot_EmptyLoop:
	ld wa, iz
	sll wa, 3
	lda_d16 xbc, 0x84a4
	extz xwa
	add xwa, xbc
	ldw bc, 0xff
	ld de, iz
	calr FormatMedleyNumber
	ld de, iz
	sll de, 3
	lda_d16 xwa, 0x84a4
	extz xde
	add xde, xwa
	ld xwa, (xsp + 6)
	ld xbc, 0x1c0000f
	call ApPostEvent
	inc 1, iz
	cp iz, 0xa
	jr c, DocFmtSlot_EmptyLoop

DocFmtSlot_Exit:
	pop xiz
	inc 6, xsp
	ret

FmmDocMedleyFunc:
	push xiz
	ld xhl, xde
	ld xde, xbc
	ld xiz, xwa
	cp xde, 0x1e5000a
	jrl z, DocMed_CheckContinue
	ld xwa, xhl
	cp xde, 0x1e50008
	jrl z, DocMed_StoreDelayFlag
	ldw_d16 xbc, 0x84fc
	cp xde, 0x1c00018
	jrl z, DocMed_HandleNavToggle
	cp xde, 0x1c00017
	jrl z, DocMed_HandleNavToggle
	cp xde, 0x1c0000b
	jrl z, DocMed_RefreshDisplay
	cp xde, 0x1e50004
	jrl z, DocMed_StoreWindowPtr
	cp xde, 0x1c00013
	jrl nz, DocMed_Exit
	cp xhl, 0x3
	jrl z, DocMed_HandleStop
	cp xhl, 0x2
	jrl nz, DocMed_Exit
	lds wa, 0
	call InitializeOperationState
	ldb_d8 a, 0x8d37
	cp a, 0x70
	jr nz, DocMed_CheckPlayMode
	stdi8 0x84fe, 0
	call Medley_GetPlaybackStatus
	cps l, 2
	jrl c, DocMed_Exit
	stdi8 0x7f42, 1
	ldw wa, 0xee
	jrl DocMed_ShowError

DocMed_CheckPlayMode:
	cp a, 0x74
	jrl nz, DocMed_CheckInit
	call Medley_GetPlaybackStatus
	cps l, 1
	jrl nz, DocMed_HandleError
	stdi8 0x84fe, 1
	ldb_d8 c, 0x8922
	lda_d16 xwa, 0x88a0
	cpda8 c, 0x8920
	jr nc, DocMed_CheckRepeat
	lds hl, 0
	ldw_d16 xde, 0x84fc
	cps de, 0
	jrl ule, DocMed_Exit

DocMed_FindSongLoop:
	ld ix, hl
	extz xix
	add xix, xwa
	cp (xix), c
	jr nz, DocMed_NextSong
	extz xhl
	ld xwa, xiz
	ld xbc, 0x1e50002
	ld xde, xhl
	calr FmmDocFileNameFunc
	ldda32 xwa, 0x84f4
	ldw_d16 xbc, 0x84fc
	calr DocMed_FormatSlotList
	incdi8 1, 0x8922
	ldda32 xwa, 0x84f8
	or xwa, xwa
	jrl z, DocMed_Exit
	ld xbc, 0x1e50009
	ld xde, 0x1e
	jr DocMed_PostDelayEvent

DocMed_NextSong:
	inc 1, hl
	cp hl, de
	jr c, DocMed_FindSongLoop
	jrl DocMed_Exit

DocMed_CheckRepeat:
	cpdi8 0x8924, 0
	jr z, DocMed_ClearPlaying
	stdi8 0x8922, 0
	lds hl, 0
	ldw_d16 xbc, 0x84fc
	cps bc, 0
	jrl ule, DocMed_Exit

DocMed_RepeatFindLoop:
	ld de, hl
	extz xde
	add xde, xwa
	cp (xde), 0x0
	jr nz, DocMed_RepeatNext
	extz xhl
	ld xwa, xiz
	ld xbc, 0x1e50002
	ld xde, xhl
	calr FmmDocFileNameFunc
	ldda32 xwa, 0x84f4
	ldw_d16 xbc, 0x84fc
	calr DocMed_FormatSlotList
	incdi8 1, 0x8922
	ldda32 xwa, 0x84f8
	or xwa, xwa
	jrl z, DocMed_Exit
	ld xbc, 0x1e50009
	ld xde, 0x1e

DocMed_PostDelayEvent:
	call ApPostEvent
	jrl DocMed_Exit

DocMed_RepeatNext:
	inc 1, hl
	cp hl, bc
	jr c, DocMed_RepeatFindLoop
	jrl DocMed_Exit

DocMed_ClearPlaying:
	stdi8 0x84fe, 0
	jrl DocMed_Exit

DocMed_HandleError:
	call Medley_GetPlaybackStatus
	stdi8 0x84fe, 0
	cps l, 0
	jrl z, DocMed_Exit
	stdi8 0x7f42, 1
	ldw wa, 0xee

DocMed_ShowError:
	call SoundCtrl_SendCommand
	jrl DocMed_Exit

DocMed_CheckInit_Entry:
DocMed_CheckInit:
	cpdi16 0x8508, 0
	jr lt, DocMed_InitFromDisk
	cpdi16 0x8504, 0
	jr nz, DocMed_InitState

DocMed_InitFromDisk:
	stdi16 0x8504, 0xffff
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	call FileIO_InitFileNavigation
	stda16 0x8508, xhl
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	call ApPostEvent
	call SignalProgressUpdate

DocMed_InitState:
	stdi8 0x84fe, 0
	stdi8 0x8922, 0
	stdi8 0x8920, 0
	ldw bc, 0x80
	ldw_d16 xwa, 0x8508
	cp wa, 0x80
	jr ugt, DocMed_ClampCount
	ld bc, wa

DocMed_ClampCount:
	stda16 0x84fc, xbc
	lds hl, 0
	cps bc, 0
	jr ule, DocMed_FinishInit
	lda_d16 xwa, 0x88a0

DocMed_ClearSlotsLoop:
	ld bc, hl
	extz xbc
	add xbc, xwa
	ld (xbc), 0xff
	inc 1, hl
	cpda16 xhl, 0x84fc
	jr c, DocMed_ClearSlotsLoop

DocMed_FinishInit:
	call CDlike_InitModeAndLoadBank
	lds32 xwa, 0
	stda32 0x84f8, xwa
	jrl DocMed_Exit

DocMed_HandleStop:
	ldb_d8 a, 0x8d36
	cp a, 0x70
	jrl z, DocMed_Exit
	cp a, 0x74
	jrl z, DocMed_Exit
	call CDlike_ExitModeAndRestore
	call CancelOperationCleanup
	stdi8 0x84fe, 0
	jrl DocMed_Exit

DocMed_StoreWindowPtr:
	stda32 0x84f4, xwa
	jrl DocMed_Exit

DocMed_RefreshDisplay:
	ldda32 xwa, 0x84f4
	calr DocMed_FormatSlotList
	jrl DocMed_Exit

DocMed_HandleNavToggle:
	cp xhl, 0xa
	jrl nz, DocMed_HandleSelectToggle
	cpdi8 0x84fe, 0
	jr nz, DocMed_HandleSelectToggle
	lds hl, 0
	ld wa, bc
	cps bc, 0
	jr ule, DocMed_CheckAllUnmarked
	lda_d16 xbc, 0x88a0

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
	cp hl, wa
	jr nc, DocMed_RemoveOrderLoop
	lds hl, 0
	cps wa, 0
	jr ule, DocMed_RefreshAfterToggle
	lda_d16 xde, 0x88a0

DocMed_AssignOrderLoop:
	ld bc, hl
	extz xbc
	add xbc, xde
	ld a, (xbc)
	cp a, 0xff
	jr nz, DocMed_NextAssign
	ldmi16 (xbc), 0x8920
	incdi8 1, 0x8920

DocMed_NextAssign:
	inc 1, hl
	cpda16 xhl, 0x84fc
	jr c, DocMed_AssignOrderLoop
	jr DocMed_RefreshAfterToggle

DocMed_RemoveOrderLoop:
	lds hl, 0
	cps wa, 0
	jr ule, DocMed_RefreshAfterToggle
	lda_d16 xde, 0x88a0

DocMed_UnmarkLoop:
	ld bc, hl
	extz xbc
	add xbc, xde
	ld a, (xbc)
	cp a, 0xfd
	jr ugt, DocMed_NextUnmark
	ld (xbc), 0xff
	decdi8 1, 0x8920

DocMed_NextUnmark:
	inc 1, hl
	cpda16 xhl, 0x84fc
	jr c, DocMed_UnmarkLoop

DocMed_RefreshAfterToggle:
	ldda32 xwa, 0x84f4
	ldw_d16 xbc, 0x84fc
	jr DocMed_CallFormatSlots

DocMed_HandleSelectToggle:
	cp xhl, 0xb
	jr nz, DocMed_HandleRepeat
	cpdi8 0x84fe, 0
	jr nz, DocMed_HandleRepeat
	ld xwa, xiz
	ld xbc, 0x1e50003
	lds32 xde, 0
	calr FmmDocFileNameFunc
	lda_d16 xix, 0x88a0
	extz xhl
	add xhl, xix
	ld c, (xhl)
	cp c, 0xff
	jr nz, DocMed_RemoveFromOrder
	ldmi16 (xhl), 0x8920
	incdi8 1, 0x8920
	jr DocMed_RefreshAfterSelect

DocMed_RemoveFromOrder:
	cp c, 0xfd
	jr ugt, DocMed_RefreshAfterSelect
	ld (xhl), 0xff
	ldb_d8 a, 0x8920
	dec 1, a
	stb_d8 0x8920, a
	lds iz, 0
	lds hl, 0
	extz wa
	cps wa, 0
	jr ule, DocMed_RefreshAfterSelect
	ld iy, wa

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
	ldda32 xwa, 0x84f4
	ldw_d16 xbc, 0x84fc

DocMed_CallFormatSlots:
	calr DocMed_FormatSlotList
	jrl DocMed_Exit

DocMed_HandleRepeat:
	cp xhl, 0xc
	jr nz, DocMed_HandlePlay
	cp xde, 0x1c00017
	jr nz, DocMed_SetRepeatOff
	stdi8 0x8924, 1
	jrl DocMed_Exit

DocMed_SetRepeatOff:
	stdi8 0x8924, 0
	jrl DocMed_Exit

DocMed_HandlePlay:
	cp xhl, 0xd
	jrl nz, DocMed_Exit
	cpdi8 0x84fe, 0
	jrl nz, DocMed_Exit
	stdi8 0x8922, 0
	lds hl, 0
	ldw_d16 xwa, 0x84fc
	cps wa, 0
	jr ule, DocMed_CheckAutoPlay
	lda_d16 xbc, 0x88a0

DocMed_PlayFindLoop:
	ld de, hl
	extz xde
	add xde, xbc
	cp (xde), 0x0
	jr nz, DocMed_PlayNextLoop
	stdi8 0x84fe, 1
	extz xhl
	ld xwa, xiz
	ld xbc, 0x1e50002
	ld xde, xhl
	calr FmmDocFileNameFunc
	incdi8 1, 0x8922
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009a
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0x74
	call UI_PostModeChangeEvent
	jr DocMed_CheckAutoPlay

DocMed_PlayNextLoop:
	inc 1, hl
	cp hl, wa
	jr c, DocMed_PlayFindLoop

DocMed_CheckAutoPlay:
	cpdi8 0x84fe, 0
	jr nz, DocMed_Exit
	ld xwa, xiz
	ld xbc, 0x1e50003
	lds32 xde, 0
	calr FmmDocFileNameFunc
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009a
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0x70
	jr DocMed_CallPauseMode

DocMed_StoreDelayFlag:
	stda32 0x84f8, xwa
	jr DocMed_Exit

DocMed_CheckContinue:
	cpdi8 0x84fe, 0
	jr z, DocMed_Exit
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009a
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0x74

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
	lda_24 xhl, 0x0ab000
	ld de, wa
	sll de, 11
	extz xde
	add xhl, xde
	add xhl, 0x1c
	ld (xhl), bc
	ldb_da e, 0x00ffe3
	extz de
	cp de, wa
	ret nz
	lda_24 xhl, 0x00f180
	add xhl, 0x1c
	ld (xhl), bc
	ret

GetSongSlotValue_Entry:
GetSongSlotValue:
	lds hl, 0
	cp wa, 0xa
	ret nc
	lda_24 xbc, 0x0ab000
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
	stw_da 0x09480e, xwa
	ret

GetCurrentSlotIndex_Entry:
GetCurrentSlotIndex:
	ldw_da xhl, 0x09480e
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
	lda xsp, (xsp - 14)

	RegObjTable 0x1600004, 0xfa44e2, 0xea1186, 0xea0f46, 0x165
	RegObjTable 0x160000c, 0xfa58fb, 0xea11f2, 0xea1188, 0x1c5
	RegObjTable 0x160000d, 0xfa5948, 0xea1358, 0xea11f4, 0x1e5
	RegObjTabl 0x1600002, ApFunctionProc, 0x1d, 0xea0a56, 0x125
	RegObjTabl 0x1600002, ApFunctionProc, 0x1d, PtrTbl_DiskFuncNames, 0x425
	RegObjTabl 0x1600001, FunctionProc, 0xd, 0xea135a, 0x105
	RegObjTabl 0x1600001, FunctionProc, 0xd, PtrTbl_NakaModuleHandlers, 0x405
	RegObjTabl 0x1600003, MainFunctionProc, 0x39, 0xea7fce, 0x145
	RegObjTabl 0x1600003, MainFunctionProc, 0x39, 0xea80b6, 0x445
	RegObjTabl 0x1600010, ViewableProc, 0x4a, 0xea67b6, 0x60
	RegObjTabl 0x160000f, ResNameProc, 0x4a, 0xea6fe2, 0x360
	RegObjTabl 0x1600010, ViewableProc, 0x80, 0xea68e2, 0x61
	RegObjTabl 0x160000f, ResNameProc, 0x80, 0xea7228, 0x361
	RegObjTabl 0x1600010, ViewableProc, 0x0, 0xea6ae6, 0x62
	RegObjTabl 0x160000f, ResNameProc, 0x0, 0xea75c6, 0x362
	RegObjTabl 0x1600010, ViewableProc, 0x0, 0xea6aea, 0x63
	RegObjTabl 0x160000f, ResNameProc, 0x0, 0xea75cc, 0x363
	RegObjTabl 0x1600010, ViewableProc, 0x0, 0xea6aee, 0x64
	RegObjTabl 0x160000f, ResNameProc, 0x0, 0xea75d2, 0x364
	RegObjTabl 0x1600010, ViewableProc, 0x3, 0xea6af2, 0x65
	RegObjTabl 0x160000f, ResNameProc, 0x3, 0xea75d8, 0x365
	RegObjTabl 0x1600010, ViewableProc, 0x0, 0xea6b02, 0x66
	RegObjTabl 0x160000f, ResNameProc, 0x0, 0xea75fc, 0x366
	RegObjTabl 0x1600010, ViewableProc, 0x47, 0xea6b06, 0x67
	RegObjTabl 0x160000f, ResNameProc, 0x47, 0xea7602, 0x367
	RegObjTabl 0x1600010, ViewableProc, 0x0, 0xea6c26, 0x6a
	RegObjTabl 0x160000f, ResNameProc, 0x0, 0xea77e4, 0x36a
	RegObjTabl 0x1600010, ViewableProc, 0x15, 0xea6c2a, 0x6b
	RegObjTabl 0x160000f, ResNameProc, 0x15, 0xea77ea, 0x36b
	RegObjTabl 0x1600010, ViewableProc, 0x53, 0xea6c82, 0x6c
	RegObjTabl 0x160000f, ResNameProc, 0x53, 0xea7878, 0x36c
	RegObjTabl 0x1600010, ViewableProc, 0x0, 0xea6dd2, 0x6d
	RegObjTabl 0x160000f, ResNameProc, 0x0, 0xea7aca, 0x36d
	RegObjTabl 0x1600010, ViewableProc, 0x0, 0xea6dd6, 0x6e
	RegObjTabl 0x160000f, ResNameProc, 0x0, 0xea7ad0, 0x36e
	RegObjTabl 0x1600010, ViewableProc, 0x15, 0xea6dda, 0x77
	RegObjTabl 0x160000f, ResNameProc, 0x15, 0xea7ad6, 0x377
	RegObjTabl 0x1600010, ViewableProc, 0x0, 0xea6e32, 0x79
	RegObjTabl 0x160000f, ResNameProc, 0x0, 0xea7b8c, 0x379
	RegObjTabl 0x1600010, ViewableProc, 0x5e, 0xea6e36, 0x7b
	RegObjTabl 0x160000f, ResNameProc, 0x5e, 0xea7b92, 0x37b
	RegObjTabl 0x1600010, ViewableProc, 0x0, 0xea6fb2, 0x7c
	RegObjTabl 0x160000f, ResNameProc, 0x0, 0xea7e98, 0x37c
	RegObjTabl 0x1600010, ViewableProc, 0x0, 0xea6fb6, 0x7d
	RegObjTabl 0x160000f, ResNameProc, 0x0, 0xea7e9e, 0x37d
	RegObjTabl 0x1600010, ViewableProc, 0x8, 0xea6fba, 0x7e
	RegObjTabl 0x160000f, ResNameProc, 0x8, 0xea7ea4, 0x37e
	RegObjTabl 0x1600010, ViewableProc, 0x0, 0xea6fde, 0xbc
	RegObjTabl 0x160000f, ResNameProc, 0x0, 0xea7ee2, 0x3bc

	RegMode 0x5, 0xea, 0x7ee8, 0x6, 0x1200000, 0x1a00060

	RegTitle 0x5, 0xea, 0x7ef0, 0x60, 0x1200000, 0x600000
	RegTitle 0x5, 0xea, 0x7efa, 0x61, 0x1450027, 0x610000
	RegTitle 0x5, 0xea, 0x7f02, 0x62, 0x1450036, 0x610069
	RegTitle 0x5, 0xea, 0x7f10, 0x63, 0x1450037, 0x60002b
	RegTitle 0x5, 0xea, 0x7f1a, 0x64, 0x1450029, 0x61004b
	RegTitle 0x5, 0xea, 0x7f26, 0x65, 0x1200000, 0x650000
	RegTitle 0x5, 0xea, 0x7f32, 0x66, 0x1200000, 0x600018
	RegTitle 0x5, 0xea, 0x7f3e, 0x67, 0x1450028, 0x670000
	RegTitle 0x5, 0xea, 0x7f46, 0x6a, 0x1200000, 0x600028
	RegTitle 0x5, 0xea, 0x7f56, 0x6b, 0x145002d, 0x6b0000
	RegTitle 0x5, 0xea, 0x7f62, 0x6c, 0x145001c, 0x6c0000
	RegTitle 0x5, 0xea, 0x7f6e, 0x6d, 0x145001e, 0x6c0026
	RegTitle 0x5, 0xea, 0x7f7a, 0x6e, 0x145001d, 0x6c003d
	RegTitle 0x5, 0xea, 0x7f84, 0x77, 0x1450026, 0x770000
	RegTitle 0x5, 0xea, 0x7f8e, 0x79, 0x1450011, 0x60000a
	RegTitle 0x5, 0xea, 0x7f98, 0x7b, 0x1450031, 0x7b0000
	RegTitle 0x5, 0xea, 0x7fa0, 0x7c, 0x1450032, 0x7b0019
	RegTitle 0x5, 0xea, 0x7fac, 0x7d, 0x1450021, 0x7b0018
	RegTitle 0x5, 0xea, 0x7fb8, 0x7e, 0x1200000, 0x7e0000
	RegTitle 0x5, 0xea, 0x7fc4, 0xbc, 0x1450025, 0x60001b

	lda xsp, (xsp + 14)
	ret

PasswordText:
	cp xbc, 0x1e0009f
	jr nz, PasswordText_Exit
	lda_24 xhl, NakaInst_WaitWinCtlSmf_0x7C8
	ret

PasswordText_Exit:
	lds32 xhl, 0
	ret

CheckPasswordText:
	cp xbc, 0x1e0009f
	jr nz, CheckPwd_Exit
	ldb_da a, 0x02748e
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
	stib_da 0x02741a, 0x00
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
	incdi8_24 1, 0x02741a
	cpib_da 0x02741a, 0x07
	jr nz, WakeUp_ReturnZero
	stib_da 0x02741a, 0x00
	ld xwa, 0xffffffff
	ld xbc, 0x1c50000
	lds32 xde, 1
	call PostEvent
	ld xwa, 0x600040
	ld xbc, 0x1c00001
	lds32 xde, 0
	jr WakeUp_PostEvent

WakeUp_ClearCounter:
	stib_da 0x02741a, 0x00
	jr WakeUp_ReturnZero

WakeUp_StoreType:
	ld xwa, (xsp + 4)
	stb_da 0x02748e, a
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
	push xiz
	ld xiz, xwa
	cp xbc, 0x1c00007
	jr z, PwdOk_HandleConfirm
	cp xbc, 0x1e0007c
	jr z, PwdOk_Return2
	cp xbc, 0x1e00084
	jr z, PwdOk_ReturnZero
	cp xbc, 0x1e0003a
	jr nz, PwdOk_ReturnZero
	pushw 0xea
	pushw 0x8bf6
	push xde
	call Strcpy
	inc 8, xsp
	ld xhl, xiz
	jr PwdOk_Exit

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
	ldw_da xde, 0x02741c
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
	push xiz
	ld xiz, xwa
	cp xbc, 0x1c00007
	jr z, CheckOk_HandleConfirm
	cp xbc, 0x1e0007c
	jr z, CheckOk_Return2
	cp xbc, 0x1e00084
	jrl z, CheckOk_ReturnZero
	cp xbc, 0x1e0003a
	jrl nz, CheckOk_ReturnZero
	pushw 0xea
	pushw 0x8bfa
	push xde
	call Strcpy
	inc 8, xsp
	ld xhl, xiz
	jrl CheckOk_Exit

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
	lda_24 xwa, 0x027424
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
	lda_24 xhl, NakaInst_WaitWinCtlSmf_0xDFE
	ret

CheckNo_Type1:
	lds32 xhl, 0
	ret

DiskSure:
	cp xbc, 0x1e0009f
	jr nz, CheckNo_Type2
	lda_24 xhl, NakaInst_WaitWinCtlSmf_0xE5C
	ret

CheckNo_Type2:
	lds32 xhl, 0
	ret

FormatText:
	cp xbc, 0x1e0009f
	jr nz, CheckNo_Type3
	lda_24 xhl, DiskWarning_ConfirmStrings_0x30
	ret

CheckNo_Type3:
	lds32 xhl, 0
	ret

DeleteText:
	cp xbc, 0x1e0009f
	jr nz, CheckNo_CallFunc
	lda_24 xhl, DiskWarning_ConfirmStrings_0x1C4
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
	lda_24 xhl, DiskWarning_ConfirmStrings_0x47E
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
	lda_24 xhl, DiskWarning_ConfirmStrings_0x790
	ret

PwdDel_Type2:
	lds32 xhl, 0
	ret

TypePriorityText:
	cp xbc, 0x1e0009f
	jr nz, PwdDel_CallFunc
	lda_24 xhl, DiskWarning_ConfirmStrings_0x8AC
	ret

PwdDel_CallFunc:
	lds32 xhl, 0
	ret

