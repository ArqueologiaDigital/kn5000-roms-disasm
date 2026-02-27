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
	cp xbc, 0x1E50003
	jrl z, SeqName_GetIndexReturn
	ldda16 xhl, 33496
	cp xbc, 0x1E50002
	jrl z, SeqName_SetIndexPlaying
	cp xbc, 0x1C00018
	jr z, SeqName_HandleNavigation
	cp xbc, 0x1C00017
	jr z, SeqName_HandleNavigation
	cp xbc, 0x1C0000B
	jr z, SeqName_InitAllSlots
	cp xbc, 0x1E50004
	jr nz, SeqName_ReturnZero
	stda32 33492, xde
	cpdi8 34046, 0
	jr nz, SeqName_SendCurrentIndex
	stdi16 33496, 0

SeqName_SendCurrentIndex:
	ldda16 xde, 33496
	extz xde
	ldda32 xwa, 33492
	ld xbc, 0x1E50002
	jrl SeqName_PostEventExit

SeqName_InitAllSlots:
	lds iz, 0

SeqName_SendSlotLoop:
	ld bc, iz
	ld wa, bc
	lds de, 1
	calr LABEL_F919E3
	ld xde, xhl
	ldda32 xwa, 33492
	ld xbc, 0x1C0000F
	call 0xFA9D58
	inc 1, iz
	cp iz, 0xA
	jr lt, SeqName_SendSlotLoop

SeqName_ReturnZero:
	lds32 xhl, 0
	jrl SeqName_Exit

SeqName_HandleNavigation:
	ld wa, hl
	ld iz, hl
	or xde, xde
	jr nz, SeqName_HandlePlayAction
	cpdi8 34046, 0
	jr nz, SeqName_HandlePlayAction
	cp xbc, 0x1C00018
	jr nz, SeqName_CheckPrevKey
	cp wa, 0x9
	jrl nc, SeqName_GetCurrentIndex
	inc 1, wa
	jr SeqName_UpdateIndex

SeqName_CheckPrevKey:
	cp xbc, 0x1C00017
	jrl nz, SeqName_GetCurrentIndex
	cps wa, 0
	jrl z, SeqName_GetCurrentIndex
	dec 1, wa

SeqName_UpdateIndex:
	stda16 33496, xwa
	ld de, wa
	jrl SeqName_UpdateDisplay

SeqName_HandlePlayAction:
	cp xde, 0x4
	jrl nz, SeqName_HandleAction32
	cpdi8 34046, 0
	jrl nz, SeqName_HandleAction32
	call CheckSongSlotHasData
	cps l, 0
	jr z, SeqName_CheckDiskAvail
	ldada xwa, 35340
	bitm 7, (xwa + 1)
	jr nz, SeqName_CheckDiskAvail
	ld (xwa), 0x1
	lds32 xde, 1
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C50004
	jr SeqName_PostAndExit

SeqName_CheckDiskAvail:
	call 0xF8943E
	cps hl, 0
	jr z, SeqName_LoadAndPlay
	cpi8_24 0x0340ea, 0x00
	jr z, SeqName_LoadAndPlay
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C50000
	lds32 xde, 1
	call 0xFA9D58
	ld xwa, 0x600037
	ld xbc, 0x1C00001
	lds32 xde, 0

SeqName_PostAndExit:
	call 0xFA9D58
	jrl SeqName_GetCurrentIndex

SeqName_LoadAndPlay:
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	lds wa, 0
	calr InitializeOperationState
	ldda16 xwa, 33496
	call LABEL_F880AD
	ld wa, hl
	lds bc, 5
	calr LABEL_F8B48E
	stda8 32578, l
	call LABEL_F89568
	call 0xF8953B
	call 0xF8987D
	stda16 34050, xhl
	calr SignalProgressUpdate
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0xEE
	jr SeqName_ShowAndExit

SeqName_HandleAction32:
	cp xde, 0x32
	jr nz, SeqName_GetCurrentIndex
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	lds wa, 0
	calr InitializeOperationState
	ldda16 xwa, 33496
	call LABEL_F880AD
	ld wa, hl
	lds bc, 5
	calr LABEL_F8B48E
	stda8 32578, l
	call LABEL_F89568
	call 0xF8953B
	call 0xF8987D
	stda16 34050, xhl
	calr SignalProgressUpdate
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0xEE

SeqName_ShowAndExit:
	call LABEL_F994BD

SeqName_GetCurrentIndex:
	ldda16 xde, 33496

SeqName_UpdateDisplay:
	cp iz, de
	jrl z, SeqName_ReturnZero
	extz xde
	ldda32 xwa, 33492
	ld xbc, 0x1E50002
	call 0xFA9D58
	ld wa, iz
	ld bc, iz
	lds de, 1
	calr LABEL_F919E3
	ld xde, xhl
	ldda32 xwa, 33492
	ld xbc, 0x1C0000F
	call 0xFA9D58
	ldda16 xbc, 33496
	ld wa, bc
	lds de, 1
	calr LABEL_F919E3
	ld xde, xhl
	ldda32 xwa, 33492
	ld xbc, 0x1C0000F
	jr SeqName_PostEventExit

SeqName_SetIndexPlaying:
	cpdi8 34046, 0
	jrl z, SeqName_ReturnZero
	ld iz, hl
	stda16 33496, xde
	extz xde
	ldda32 xwa, 33492
	ld xbc, 0x1E50002
	call 0xFA9D58
	ld wa, iz
	ld bc, iz
	lds de, 1
	calr LABEL_F919E3
	ld xde, xhl
	ldda32 xwa, 33492
	ld xbc, 0x1C0000F
	call 0xFA9D58
	ldda16 xbc, 33496
	ld wa, bc
	lds de, 1
	calr LABEL_F919E3
	ld xde, xhl
	ldda32 xwa, 33492
	ld xbc, 0x1C0000F

SeqName_PostEventExit:
	call 0xFA9D58
	jrl SeqName_ReturnZero

SeqName_GetIndexReturn:
	ldda16 xhl, 33496
	extz xhl

SeqName_Exit:
	popw iz
	ret

FormatMedleyNumber:
	lda_dpi XIY, 0xE0
	cp c, 0xFF
	jr nz, FmtNum_CheckMarked
	ldb c, 0x20
	jr FmtNum_WriteSpacePad

FmtNum_CheckMarked:
	cp c, 0xFE
	jr nz, FmtNum_FormatNumber
	ldb c, 0x4D

FmtNum_WriteSpacePad:
	lda_dpi XHL, 0xE0
	stib_dpi 0xE0, 0x20
	ld (xwa), 0x20
	ret

FmtNum_FormatNumber:
	inc 1, c
	cp c, 0x64
	jr c, FmtNum_WriteM
	st_dpib C, 0xE0
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
	stib_dpi 0xE0, 0x4D

FmtNum_WriteTensUnits:
	cp c, 0xA
	jr nc, FmtNum_WriteTwoDigits
	stib_dpi 0xE0, 0x30
	add c, 0x30
	ld (xwa), c
	ret

FmtNum_WriteTwoDigits:
	st_dpib C, 0xE0
	ld e, c
	extz de
	div e, 0xA
	add e, 0x30
	ld (xhl), e
	extz bc
	div c, 0xA
	ld c, b
	add c, 0x30
	ld (xwa), c
	ret

FmmIntMedleyFunc:
	dec 8, xsp
	pushw iz
	ld (xsp + 6), xwa
	cp xbc, 0x1E5000A
	jrl z, IntMed_CheckContinue
	ld xwa, xde
	cp xbc, 0x1E50008
	jrl z, IntMed_StoreDelayFlag
	cp xbc, 0x1C00018
	jrl z, IntMed_HandleNavToggle
	cp xbc, 0x1C00017
	jrl z, IntMed_HandleNavToggle
	cp xbc, 0x1C0000B
	jrl z, IntMed_InitSlotDisplay
	cp xbc, 0x1E50004
	jrl z, IntMed_StoreWindowPtr
	cp xbc, 0x1C00013
	jrl nz, IntMed_Exit
	cp xde, 0x3
	jrl z, IntMed_HandleStop
	cp xde, 0x2
	jrl nz, IntMed_Exit
	cpdi8 36151, 122
	jr z, IntMed_CheckPlaying
	call LABEL_F20ACD
	stdi8 34046, 0
	stdi8 34972, 0
	stdi8 34970, 0
	lds iz, 0

IntMed_CheckSlotLoop:
	ldto_berp A, 0xF8
	extz wa
	call LABEL_F2065A
	cps l, 0
	jr z, IntMed_MarkSlotEmpty
	ldada xwa, 34960
	ld bc, iz
	extz xbc
	add xbc, xwa
	ldmi16 (xbc), 0x889A
	incdi8 1, 34970
	jr IntMed_NextSlot

IntMed_MarkSlotEmpty:
	ldada xwa, 34960
	ld bc, iz
	extz xbc
	add xbc, xwa
	ld (xbc), 0xFF

IntMed_NextSlot:
	inc 1, iz
	cp iz, 0xA
	jr c, IntMed_CheckSlotLoop
	lds32 xwa, 0
	stda32 33502, xwa
	jrl IntMed_Exit

IntMed_CheckPlaying:
	call LABEL_F2076D
	cps l, 1
	jrl nz, IntMed_HandleError
	stdi8 34046, 1
	ldda8 a, 34972
	cpda8 a, 34970
	jr nc, IntMed_CheckRepeat
	lds iz, 0
	ldada xbc, 34960

IntMed_FindCurrentSong:
	ld de, iz
	extz xde
	add xde, xbc
	cp (xde), a
	jr nz, IntMed_NextSongSearch
	ld de, iz
	extz xde
	ld xwa, (xsp + 6)
	ld xbc, 0x1E50002
	calr FmmSeqSongNameFunc
	ldto_berp A, 0xF8
	extz wa
	call LABEL_F20BCE
	incdi8 1, 34972
	ldda32 xwa, 33502
	or xwa, xwa
	jrl z, IntMed_Exit
	ld xbc, 0x1E50009
	ld xde, 0x1E
	jr IntMed_PostDelayEvent

IntMed_NextSongSearch:
	inc 1, iz
	cp iz, 0xA
	jr c, IntMed_FindCurrentSong
	jrl IntMed_Exit

IntMed_CheckRepeat:
	cpdi8 34974, 0
	jr z, IntMed_ClearPlayFlag
	stdi8 34972, 0
	lds iz, 0
	ldada xwa, 34960

IntMed_PlayFromStart:
	ld bc, iz
	extz xbc
	add xbc, xwa
	cp (xbc), 0x0
	jr nz, IntMed_NextSongLoop
	ld de, iz
	extz xde
	ld xwa, (xsp + 6)
	ld xbc, 0x1E50002
	calr FmmSeqSongNameFunc
	ldto_berp A, 0xF8
	extz wa
	call LABEL_F20BCE
	incdi8 1, 34972
	ldda32 xwa, 33502
	or xwa, xwa
	jrl z, IntMed_Exit
	ld xbc, 0x1E50009
	ld xde, 0x1E

IntMed_PostDelayEvent:
	call 0xFA9D58
	jrl IntMed_Exit

IntMed_NextSongLoop:
	inc 1, iz
	cp iz, 0xA
	jr c, IntMed_PlayFromStart
	jrl IntMed_Exit

IntMed_ClearPlayFlag:
	stdi8 34046, 0
	jrl IntMed_Exit

IntMed_HandleError:
	call LABEL_F2076D
	stdi8 34046, 0
	cps l, 0
	jrl z, IntMed_Exit
	stdi8 32578, 14
	ldw wa, 0xEE
	call LABEL_F994BD
	jrl IntMed_Exit

IntMed_HandleStop:
	cpdi8 36150, 122
	jrl z, IntMed_Exit
	call LABEL_F20B70
	stdi8 34046, 0
	jrl IntMed_Exit

IntMed_StoreWindowPtr:
	stda32 33498, xwa
	jrl IntMed_Exit

IntMed_InitSlotDisplay:
	lds iz, 0

IntMed_FormatSlotLoop:
	ld wa, iz
	sll wa, 3
	ldada xbc, 33506
	extz xwa
	add xwa, xbc
	ldada xbc, 34960
	ld de, iz
	extz xde
	add xde, xbc
	ld c, (xde)
	extz bc
	ld de, iz
	calr FormatMedleyNumber
	ld de, iz
	sll de, 3
	ldada xwa, 33506
	extz xde
	add xde, xwa
	ldda32 xwa, 33498
	ld xbc, 0x1C0000F
	call 0xFA9D58
	inc 1, iz
	cp iz, 0xA
	jr c, IntMed_FormatSlotLoop
	jrl IntMed_Exit

IntMed_HandleNavToggle:
	ldada xwa, 34960
	cp xde, 0xA
	jrl nz, IntMed_HandleSelectToggle
	cpdi8 34046, 0
	jrl nz, IntMed_HandleSelectToggle
	lds iz, 0

IntMed_FindMarkedSlot:
	ld bc, iz
	extz xbc
	add xbc, xwa
	cp (xbc), 0xFE
	jr z, IntMed_CheckAllMarked
	inc 1, iz
	cp iz, 0xA
	jr c, IntMed_FindMarkedSlot

IntMed_CheckAllMarked:
	cp iz, 0xA
	jr nc, IntMed_RemoveOrderLoop
	lds iz, 0

IntMed_AssignOrderLoop:
	ldada xwa, 34960
	ld bc, iz
	extz xbc
	add xbc, xwa
	ld a, (xbc)
	cp a, 0xFE
	jr nz, IntMed_NextAssignSlot
	ldda8 a, 34970
	ld (xbc), a
	incdi8 1, 34970
	ld wa, iz
	sll wa, 3
	ldada xde, 33506
	extz xwa
	add xwa, xde
	ld c, (xbc)
	extz bc
	ld de, iz
	calr FormatMedleyNumber
	ld de, iz
	sll de, 3
	ldada xwa, 33506
	extz xde
	add xde, xwa
	ldda32 xwa, 33498
	ld xbc, 0x1C0000F
	call 0xFA9D58

IntMed_NextAssignSlot:
	inc 1, iz
	cp iz, 0xA
	jr c, IntMed_AssignOrderLoop
	jrl IntMed_Exit

IntMed_RemoveOrderLoop:
	lds iz, 0

IntMed_UnmarkSlotLoop:
	ldada xwa, 34960
	ld bc, iz
	extz xbc
	add xbc, xwa
	ld a, (xbc)
	cp a, 0xFD
	jr ugt, IntMed_NextUnmark
	ld (xbc), 0xFE
	decdi8 1, 34970
	ld wa, iz
	sll wa, 3
	ldada xde, 33506
	extz xwa
	add xwa, xde
	ld c, (xbc)
	extz bc
	ld de, iz
	calr FormatMedleyNumber
	ld de, iz
	sll de, 3
	ldada xwa, 33506
	extz xde
	add xde, xwa
	ldda32 xwa, 33498
	ld xbc, 0x1C0000F
	call 0xFA9D58

IntMed_NextUnmark:
	inc 1, iz
	cp iz, 0xA
	jr c, IntMed_UnmarkSlotLoop
	jrl IntMed_Exit

IntMed_HandleSelectToggle:
	cp xde, 0xB
	jrl nz, IntMed_HandleRepeatToggle
	cpdi8 34046, 0
	jrl nz, IntMed_HandleRepeatToggle
	ld xwa, (xsp + 6)
	ld xbc, 0x1E50003
	lds32 xde, 0
	calr FmmSeqSongNameFunc
	ld iz, hl
	ldada xwa, 34960
	ld de, iz
	extz xde
	add xde, xwa
	ldada xbc, 33506
	ld wa, iz
	sll wa, 3
	extz xwa
	add xwa, xbc
	ld c, (xde)
	cp c, 0xFE
	jr nz, IntMed_RemoveFromOrder
	ldda8 c, 34970
	ld (xde), c
	incdi8 1, 34970
	ld c, (xde)
	extz bc
	ld de, iz
	calr FormatMedleyNumber
	ld de, iz
	sll de, 3
	ldada xbc, 33506
	extz xde
	add xde, xbc
	ldda32 xwa, 33498
	ld xbc, 0x1C0000F
	call 0xFA9D58
	jrl IntMed_Exit

IntMed_RemoveFromOrder:
	cp c, 0xFD
	jrl ugt, IntMed_Exit
	ld (xsp + 4), c
	ld (xde), 0xFE
	decdi8 1, 34970
	ld c, (xde)
	extz bc
	ld de, iz
	calr FormatMedleyNumber
	ld de, iz
	sll de, 3
	ldada xbc, 33506
	extz xde
	add xde, xbc
	ldda32 xwa, 33498
	ld xbc, 0x1C0000F
	call 0xFA9D58
	ldw (xsp + 2), 0x0
	lds iz, 0
	ldda8 a, 34970
	extz wa
	cps wa, 0
	jrl ule, IntMed_Exit

IntMed_ReorderLoop:
	ldada xwa, 34960
	ld de, iz
	extz xde
	add xde, xwa
	ld c, (xde)
	cp c, 0xFD
	jr ugt, IntMed_NextReorder
	incm 1, (xsp + 2)
	cp c, (xsp + 4)
	jr ule, IntMed_NextReorder
	dec 1, c
	ld (xde), c
	ld wa, iz
	sll wa, 3
	ldada xde, 33506
	extz xwa
	add xwa, xde
	extz bc
	ld de, iz
	calr FormatMedleyNumber
	ld de, iz
	sll de, 3
	ldada xwa, 33506
	extz xde
	add xde, xwa
	ldda32 xwa, 33498
	ld xbc, 0x1C0000F
	call 0xFA9D58

IntMed_NextReorder:
	inc 1, iz
	ldda8 a, 34970
	extz wa
	cp (xsp + 2), wa
	jr c, IntMed_ReorderLoop
	jrl IntMed_Exit

IntMed_HandleRepeatToggle:
	cp xde, 0xC
	jr nz, IntMed_HandlePlay
	cp xbc, 0x1C00017
	jr nz, IntMed_SetRepeatOff
	stdi8 34974, 1
	jrl IntMed_Exit

IntMed_SetRepeatOff:
	stdi8 34974, 0
	jrl IntMed_Exit

IntMed_HandlePlay:
	cp xde, 0xD
	jrl nz, IntMed_Exit
	cpdi8 34046, 0
	jr nz, IntMed_Exit
	stdi8 34972, 0
	lds iz, 0

IntMed_StartPlayLoop:
	ld bc, iz
	extz xbc
	add xbc, xwa
	cp (xbc), 0x0
	jr nz, IntMed_NextPlaySlot
	stdi8 34046, 1
	ld de, iz
	extz xde
	ld xwa, (xsp + 6)
	ld xbc, 0x1E50002
	calr FmmSeqSongNameFunc
	ldto_berp A, 0xF8
	extz wa
	call LABEL_F20BCE
	incdi8 1, 34972
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009A
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0x7A
	call 0xF99490
	jr IntMed_Exit

IntMed_NextPlaySlot:
	inc 1, iz
	cp iz, 0xA
	jr c, IntMed_StartPlayLoop
	jr IntMed_Exit

IntMed_StoreDelayFlag:
	stda32 33502, xwa
	jr IntMed_Exit

IntMed_CheckContinue:
	cpdi8 34046, 0
	jr z, IntMed_Exit
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009A
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0x7A
	call 0xF99490

IntMed_Exit:
	lds32 xhl, 0
	popw iz
	inc 8, xsp
	ret

FmmDiskMedley1Func:
	pushw iz
	cp xbc, 0x1C0000B
	jr z, DiskMed1_InitLoop
	cp xbc, 0x1E50004
	jr nz, DiskMed1_Exit
	stda32 33586, xde
	jr DiskMed1_Exit

DiskMed1_InitLoop:
	lds iz, 0

DiskMed1_FormatLoop:
	ld wa, iz
	sll wa, 3
	ldada xbc, 33590
	extz xwa
	add xwa, xbc
	ldada xbc, 35110
	ld de, iz
	extz xde
	add xde, xbc
	ld c, (xde)
	extz bc
	ld de, iz
	calr FormatMedleyNumber
	ld de, iz
	sll de, 3
	ldada xwa, 33590
	extz xde
	add xde, xwa
	ldda32 xwa, 33586
	ld xbc, 0x1C0000F
	call 0xFA9D58
	inc 1, iz
	cp iz, 0xA
	jr c, DiskMed1_FormatLoop

DiskMed1_Exit:
	lds32 xhl, 0
	popw iz
	ret

FmmDiskMedley2Func:
	pushw iz
	cp xbc, 0x1C0000B
	jr z, DiskMed2_InitLoop
	cp xbc, 0x1E50004
	jr nz, DiskMed2_Exit
	stda32 33670, xde
	jr DiskMed2_Exit

DiskMed2_InitLoop:
	ldw iz, 0xA

DiskMed2_FormatLoop:
	ld wa, iz
	sll wa, 3
	lda_24 xbc, 0x00833a
	extz xwa
	add xwa, xbc
	ldada xbc, 35110
	ld de, iz
	extz xde
	add xde, xbc
	ld c, (xde)
	extz bc
	ld de, iz
	sub de, 0xA
	calr FormatMedleyNumber
	ld wa, iz
	sll wa, 3
	lda_24 xbc, 0x00833a
	ld de, wa
	extz xde
	add xde, xbc
	ldda32 xwa, 33670
	ld xbc, 0x1C0000F
	call 0xFA9D58
	inc 1, iz
	cp iz, 0x14
	jr c, DiskMed2_FormatLoop

DiskMed2_Exit:
	lds32 xhl, 0
	popw iz
	ret

DiskMed_PlayNextHelper:
	pushw iz
	cp xbc, 0x1C00018
	jr z, DiskMed_InitPlayOrder
	cp xbc, 0x1C00017
	jr z, DiskMed_InitPlayOrder
	cp xbc, 0x1C00013
	jrl nz, DiskMed_ReturnZero
	cp xde, 0x3
	jrl z, DiskMed_ReturnZero
	cp xde, 0x2
	jrl nz, DiskMed_ReturnZero
	cpdi8 34046, 0
	jrl z, DiskMed_ReturnZero
	ldda8 a, 34972
	cpda8 a, 34970
	jr nc, DiskMed_ReturnFinished
	lds iz, 0
	ldada xbc, 34960

DiskMed_FindSongLoop:
	ld de, iz
	extz xde
	add xde, xbc
	cp (xde), a
	jr nz, DiskMed_NextSong
	ldto_berp A, 0xF8
	extz wa
	jrl DiskMed_PlaySong

DiskMed_NextSong:
	inc 1, iz
	cp iz, 0xA
	jr c, DiskMed_FindSongLoop
	jrl DiskMed_ReturnZero

DiskMed_ReturnFinished:
	lds32 xhl, 2
	jrl DiskMed_HelperExit

DiskMed_InitPlayOrder:
	cp xde, 0xD
	jrl nz, DiskMed_ReturnZero
	stdi8 34972, 0
	stdi8 34970, 0
	stdi8 34974, 0
	lds iz, 0

DiskMed_CheckSlotLoop:
	ldto_berp A, 0xF8
	extz wa
	call LABEL_F2065A
	ldada xbc, 34960
	ld wa, iz
	extz xwa
	add xwa, xbc
	cps l, 0
	jr z, DiskMed_MarkUnused
	ld (xwa), 0xFE
	jr DiskMed_NextSlotCheck

DiskMed_MarkUnused:
	ld (xwa), 0xFF

DiskMed_NextSlotCheck:
	inc 1, iz
	cp iz, 0xA
	jr c, DiskMed_CheckSlotLoop
	cpdi8 35136, 0
	jr z, DiskMed_SingleSlotCheck
	ldada xhl, 34960
	ld xbc, xhl
	lda xde, (xhl + 10)

DiskMed_AssignOrder:
	ld a, (xbc)
	cp a, 0xFE
	jr nz, DiskMed_NextAssign
	ldmi16 (xbc), 0x889A
	incdi8 1, 34970

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
	cpda8 a, 34972
	jr nz, DiskMed_NextFirst
	ldto_berp A, 0xF8
	extz wa
	jr DiskMed_PlaySong

DiskMed_NextFirst:
	inc 1, iz
	cp iz, 0xA
	jr c, DiskMed_FindFirstSong
	jr DiskMed_ReturnZero

DiskMed_SingleSlotCheck:
	ldada xbc, 34960
	cp (xbc), 0xFE
	jr nz, DiskMed_SingleSlotInit
	ldmi16 (xbc), 0x889A
	incdi8 1, 34970

DiskMed_SingleSlotInit:
	lds iz, 0

DiskMed_FindFirstLoop:
	ld wa, iz
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cpda8 a, 34972
	jr nz, DiskMed_NextFindFirst
	ldto_berp A, 0xF8
	extz wa

DiskMed_PlaySong:
	call LABEL_F20BCE
	incdi8 1, 34972
	lds32 xhl, 1
	jr DiskMed_HelperExit

DiskMed_NextFindFirst:
	inc 1, iz
	cp iz, 0xA
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
	cp xwa, 0x1C00018
	jrl z, DiskSel_HandleNavigation
	cp xwa, 0x1C00017
	jrl z, DiskSel_HandleNavigation
	cp xwa, 0x1C0000B
	jrl z, DiskSel_InitDisplay
	cp xwa, 0x1E50004
	jrl z, DiskSel_StoreWindowPtr
	cp xwa, 0x1C00013
	jrl nz, DiskSel_Exit
	ld xwa, (xsp + 6)
	cp xwa, 0x3
	jrl z, DiskSel_HandleStopEvent
	cp xwa, 0x2
	jrl nz, DiskSel_Exit
	lds wa, 0
	calr InitializeOperationState
	cpdi8 36151, 120
	jrl z, DiskSel_CheckPlaying
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	call 0xFA9D58
	cpdi16 34050, 0
	jr ge, DiskSel_InitState
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	call 0xF8987D
	stda16 34050, xhl
	call LABEL_F8958D
	call 0xF8953B
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	call 0xFA9D58
	calr SignalProgressUpdate

DiskSel_InitState:
	stdi8 34046, 0
	stdi8 35132, 0
	stdi8 35130, 0
	lds iz, 0

DiskSel_CheckFileLoop:
	ld wa, iz
	lds bc, 2
	call LABEL_F89408
	cps l, 0
	jr nz, DiskSel_FileAvailable
	ld wa, iz
	ldw bc, 0x8
	call LABEL_F89408
	cps l, 0
	jr z, DiskSel_MarkUnavail

DiskSel_FileAvailable:
	ldada xwa, 35110
	ldmmb_dri 0x07, 0xE0, 0xF8, 0x3A, 0x89
	incdi8 1, 35130
	jr DiskSel_NextFile

DiskSel_MarkUnavail:
	ldada xwa, 35110
	stib_dri 0x07, 0xE0, 0xF8, 0xFF

DiskSel_NextFile:
	inc 1, iz
	cp iz, 0x14
	jr lt, DiskSel_CheckFileLoop
	call LABEL_F20ACD
	jrl DiskSel_Exit

DiskSel_CheckPlaying:
	call LABEL_F2076D
	cps l, 1
	jrl nz, DiskSel_HandleError
	stdi8 34046, 1
	ld xwa, (xsp + 14)
	ld xbc, (xsp + 10)
	ld xde, (xsp + 6)
	calr DiskMed_PlayNextHelper
	cps l, 1
	jr nz, DiskSel_CheckFinished
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009A
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0x78
	jrl DiskSel_CallPauseMode

DiskSel_CheckFinished:
	cps l, 2
	jrl nz, DiskSel_Exit
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	call 0xFA9D58
	ldda8 a, 35132
	cpda8 a, 35130
	jrl nc, DiskSel_CheckRepeat
	lds iz, 0

DiskSel_ClearSelections:
	ldto_berp A, 0xF8
	extz wa
	call LABEL_F89321
	inc 1, iz
	cp iz, 0x8
	jr lt, DiskSel_ClearSelections
	lds iz, 0

DiskSel_FindSongLoop:
	ldada xwa, 35110
	ld_srib3 A, 0x07, 0xE0, 0xF8
	cpda8 a, 35132
	jrl nz, DiskSel_NextSongLoop
	stda16 33758, xiz
	ld wa, iz
	call 0xF89605
	ldda16 xde, 33758
	exts xde
	ldda32 xwa, 33754
	ld xbc, 0x1E50002
	call 0xFA9D58
	ldi_werp 0xFA, 0

DiskSel_SendFileInfo:
	ldto_werp DE, 0xFA
	sll de, 5
	ldada xbc, 34060
	extz xde
	add xde, xbc
	ldda32 xwa, 33754
	ld xbc, 0x1C0000F
	call 0xFA9D58
	inc1_werp 0xFA
	cp_erpw 0xFA, 0x14, 0x00
	jr lt, DiskSel_SendFileInfo
	lds32 xwa, 0
	ld xbc, 0x1C0000B
	lds32 xde, 0
	calr FmmDiskMedley1Func
	lds32 xwa, 0
	ld xbc, 0x1C0000B
	lds32 xde, 0
	calr FmmDiskMedley2Func
	lds32 xwa, 0
	ld xbc, 0x1C0000B
	ld xde, 0x770008
	calr DiskNameFunc
	lds32 xwa, 0
	ld xbc, 0x1C0000B
	ld xde, 0x770009
	calr DiskInfoFunc
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	lds wa, 0
	calr InitializeOperationState
	call LABEL_F87A08
	ldfr_werp HL, 0xFA
	calr SignalProgressUpdate
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	call 0xFA9D58
	cpi_werp 0xFA, 0
	jr ge, DiskSel_PlayNext
	stdi8 34046, 0
	ldw wa, 0x60
	call 0xF99490
	ldto_werp WA, 0xFA
	lds bc, 1
	calr LABEL_F8B48E
	stda8 32578, l
	ldw wa, 0xEE
	jrl DiskSel_ShowErrorAndExit

DiskSel_PlayNext:
	incdi8 1, 35132
	ld xwa, (xsp + 14)
	ld xbc, 0x1C00017
	ld xde, 0xD
	calr DiskMed_PlayNextHelper
	cps l, 1
	jr nz, DiskSel_NextSongLoop
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009A
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0x78
	call 0xF99490
	jr DiskSel_ClearPlaying

DiskSel_NextSongLoop:
	inc 1, iz
	cp iz, 0x14
	jrl lt, DiskSel_FindSongLoop

DiskSel_ClearPlaying:
	stdi8 34046, 0
	jrl DiskSel_Exit

DiskSel_CheckRepeat:
	cpdi8 35134, 0
	jr z, DiskSel_ClearPlaying
	stdi8 35132, 0
	lds iz, 0

DiskSel_RepeatClear:
	ldto_berp A, 0xF8
	extz wa
	call LABEL_F89321
	inc 1, iz
	cp iz, 0x8
	jr lt, DiskSel_RepeatClear
	lds iz, 0

DiskSel_RepeatFindLoop:
	ldada xwa, 35110
	ld_srib3 A, 0x07, 0xE0, 0xF8
	cpda8 a, 35132
	jrl nz, DiskSel_RepeatNext
	stda16 33758, xiz
	ld wa, iz
	call 0xF89605
	ldda16 xde, 33758
	exts xde
	ldda32 xwa, 33754
	ld xbc, 0x1E50002
	call 0xFA9D58
	ldi_werp 0xFA, 0

DiskSel_RepeatSendInfo:
	ldto_werp DE, 0xFA
	sll de, 5
	ldada xbc, 34060
	extz xde
	add xde, xbc
	ldda32 xwa, 33754
	ld xbc, 0x1C0000F
	call 0xFA9D58
	inc1_werp 0xFA
	cp_erpw 0xFA, 0x14, 0x00
	jr lt, DiskSel_RepeatSendInfo
	lds32 xwa, 0
	ld xbc, 0x1C0000B
	lds32 xde, 0
	calr FmmDiskMedley1Func
	lds32 xwa, 0
	ld xbc, 0x1C0000B
	lds32 xde, 0
	calr FmmDiskMedley2Func
	lds32 xwa, 0
	ld xbc, 0x1C0000B
	ld xde, 0x770008
	calr DiskNameFunc
	lds32 xwa, 0
	ld xbc, 0x1C0000B
	ld xde, 0x770009
	calr DiskInfoFunc
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	lds wa, 0
	calr InitializeOperationState
	call LABEL_F87A08
	ldfr_werp HL, 0xFA
	calr SignalProgressUpdate
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	call 0xFA9D58
	cpi_werp 0xFA, 0
	jr ge, DiskSel_RepeatPlayNext
	stdi8 34046, 0
	ldw wa, 0x60
	call 0xF99490
	ldto_werp WA, 0xFA
	lds bc, 1
	calr LABEL_F8B48E
	stda8 32578, l
	ldw wa, 0xEE
	jrl DiskSel_ShowErrorAndExit

DiskSel_RepeatPlayNext:
	incdi8 1, 35132
	ld xwa, (xsp + 14)
	ld xbc, 0x1C00017
	ld xde, 0xD
	calr DiskMed_PlayNextHelper
	cps l, 1
	jr nz, DiskSel_RepeatNext
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009A
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0x78

DiskSel_CallPauseMode:
	call 0xF99490
	jrl DiskSel_Exit

DiskSel_RepeatNext:
	inc 1, iz
	cp iz, 0x14
	jrl lt, DiskSel_RepeatFindLoop
	jrl DiskSel_Exit

DiskSel_HandleError:
	call LABEL_F2076D
	stdi8 34046, 0
	cps l, 0
	jr nz, DiskSel_ShowError
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	call 0xFA9D58
	jrl DiskSel_Exit

DiskSel_ShowError:
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	stdi8 32578, 14
	ldw wa, 0xEE
	jrl DiskSel_ShowErrorAndExit

DiskSel_HandleStopEvent:
	cpdi8 36150, 120
	jr z, DiskSel_PostStopEvent
	call LABEL_F20B70
	stdi8 34046, 0

DiskSel_PostStopEvent:
	calr CancelOperationCleanup
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	jrl DiskSel_PostEvent

DiskSel_StoreWindowPtr:
	ld xwa, (xsp + 6)
	stda32 33754, xwa
	call 0xF895EF
	stda16 33758, xhl
	cps hl, 0
	jr lt, DiskSel_DefaultIndex
	exts xhl
	ldda32 xwa, 33754
	ld xbc, 0x1E50002
	ld xde, xhl
	jrl DiskSel_PostEvent

DiskSel_DefaultIndex:
	stdi16 33758, 0
	ldda32 xwa, 33754
	ld xbc, 0x1E50002
	lds32 xde, 0
	jrl DiskSel_PostEvent

DiskSel_InitDisplay:
	lds iz, 0

DiskSel_DisplayLoop:
	ld wa, iz
	ld hl, wa
	sll hl, 5
	ldada xde, 34060
	extz xhl
	add xhl, xde
	ldto_berp C, 0xF8
	ld (xhl), c
	lds bc, 2
	call LABEL_F89408
	ld wa, iz
	cps l, 0
	jr nz, DiskSel_GetFileName
	ldw bc, 0x8
	call LABEL_F89408
	cps l, 0
	jr z, DiskSel_EmptyFileName
	ld wa, iz

DiskSel_GetFileName:
	call LABEL_F89623
	ld xbc, xhl
	jr DiskSel_FormatEntry

DiskSel_EmptyFileName:
	lda_24 xbc, 0xea0a54

DiskSel_FormatEntry:
	ld de, iz
	ld wa, de
	sll wa, 5
	lds hl, 1
	add hl, wa
	ldada xix, 34060
	extz xhl
	add xhl, xix
	inc 1, de
	pushw 0x6
	pushw 0x0
	ld xwa, xhl
	call LABEL_F891DD
	ld de, iz
	sll de, 5
	ldada xbc, 34060
	extz xde
	add xde, xbc
	ldda32 xwa, 33754
	ld xbc, 0x1C0000F
	call 0xFA9D58
	inc 1, iz
	cp iz, 0x14
	jr lt, DiskSel_DisplayLoop
	jrl DiskSel_Exit

DiskSel_HandleNavigation:
	ldda16 xde, 33758
	ld (xsp + 4), de
	ld xbc, (xsp + 10)
	ld xwa, (xsp + 6)
	or xwa, xwa
	jr nz, DiskSel_CheckPage
	cpdi8 34046, 0
	jr nz, DiskSel_CheckPage
	ld xwa, xbc
	cp xbc, 0x1C00018
	jr nz, DiskSel_CheckPrevKey
	cp de, 0x13
	jrl ge, DiskSel_GetCurrentIndex
	inc 1, de
	jr DiskSel_SaveIndex

DiskSel_CheckPrevKey:
	cp xwa, 0x1C00017
	jrl nz, DiskSel_GetCurrentIndex
	cps de, 0
	jrl le, DiskSel_GetCurrentIndex
	dec 1, de
	jr DiskSel_SaveIndex

DiskSel_CheckPage:
	ld xwa, (xsp + 6)
	cp xwa, 0x1
	jr nz, DiskSel_CheckPageDown
	cpdi8 34046, 0
	jr nz, DiskSel_CheckPageDown
	cp de, 0xA
	jrl lt, DiskSel_GetCurrentIndex
	sub de, 0xA
	jr DiskSel_SaveIndex

DiskSel_CheckPageDown:
	ld xwa, (xsp + 6)
	cp xwa, 0x2
	jr nz, DiskSel_HandleToggle
	cpdi8 34046, 0
	jr nz, DiskSel_HandleToggle
	ld wa, de
	add wa, 0xA
	cp wa, 0x13
	jrl gt, DiskSel_GetCurrentIndex
	add de, 0xA

DiskSel_SaveIndex:
	stda16 33758, xde
	jrl DiskSel_UpdateDisplay

DiskSel_HandleToggle:
	ldada xhl, 35110
	ld xwa, (xsp + 6)
	cp xwa, 0xA
	jr nz, DiskSel_HandleSelect
	cpdi8 34046, 0
	jr nz, DiskSel_HandleSelect
	lds iz, 0

DiskSel_FindMarkedLoop:
	cp_srib_im 0x07, 0xEC, 0xF8, 0xFE
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
	cp a, 0xFE
	jr nz, DiskSel_NextAssign
	ldmi16 (xhl), 0x893A
	incdi8 1, 35130

DiskSel_NextAssign:
	inc 1, xhl
	cp xhl, xde
	jr c, DiskSel_AssignLoop
	jr DiskSel_RefreshDisplay

DiskSel_UnmarkLoop:
	ld a, (xhl)
	cp a, 0xFD
	jr ugt, DiskSel_NextUnmark
	ld (xhl), 0xFE
	decdi8 1, 35130

DiskSel_NextUnmark:
	inc 1, xhl
	cp xhl, xde
	jr c, DiskSel_UnmarkLoop

DiskSel_RefreshDisplay:
	lds32 xwa, 0
	ld xbc, 0x1C0000B
	lds32 xde, 0
	calr FmmDiskMedley1Func
	lds32 xwa, 0
	ld xbc, 0x1C0000B
	lds32 xde, 0
	jr DiskSel_RefreshBoth

DiskSel_HandleSelect:
	ld xwa, (xsp + 6)
	cp xwa, 0xB
	jr nz, DiskSel_HandleRepeat
	cpdi8 34046, 0
	jr nz, DiskSel_HandleRepeat
	ld xix, xhl
	st_dri3b A, 0x07, 0xEC, 0xE8
	ld a, (xbc)
	cp a, 0xFE
	jr nz, DiskSel_RemoveSelect
	ldmi16 (xbc), 0x893A
	incdi8 1, 35130
	jr DiskSel_RefreshAfterSelect

DiskSel_RemoveSelect:
	cp a, 0xFD
	jr ugt, DiskSel_RefreshAfterSelect
	cp de, 0x14
	jr ge, DiskSel_ReorderSlots
	ld (xbc), 0xFE
	decdi8 1, 35130

DiskSel_ReorderSlots:
	ld xde, xix
	lda xhl, (xix + 20)

DiskSel_ReorderLoop:
	ld c, (xde)
	cp c, 0xFD
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
	ld xbc, 0x1C0000B
	lds32 xde, 0
	calr FmmDiskMedley1Func
	lds32 xwa, 0
	ld xbc, 0x1C0000B
	lds32 xde, 0

DiskSel_RefreshBoth:
	calr FmmDiskMedley2Func
	jrl DiskSel_GetCurrentIndex

DiskSel_HandleRepeat:
	ld xwa, (xsp + 6)
	cp xwa, 0xC
	jr nz, DiskSel_HandlePlayStart
	cp xbc, 0x1C00017
	jr nz, DiskSel_SetRepeatOff
	stdi8 35134, 1
	jrl DiskSel_GetCurrentIndex

DiskSel_SetRepeatOff:
	stdi8 35134, 0
	jrl DiskSel_GetCurrentIndex

DiskSel_HandlePlayStart:
	ld xwa, (xsp + 6)
	cp xwa, 0xD
	jrl nz, DiskSel_HandleAllCheck
	cpdi8 34046, 0
	jrl nz, DiskSel_HandleAllCheck
	stdi8 35132, 0
	lds iz, 0

DiskSel_PlayClearLoop:
	ldto_berp A, 0xF8
	extz wa
	call LABEL_F89321
	inc 1, iz
	cp iz, 0x8
	jr lt, DiskSel_PlayClearLoop
	lds iz, 0

DiskSel_PlayFindLoop:
	ldada xwa, 35110
	ld_srib3 A, 0x07, 0xE0, 0xF8
	cpda8 a, 35132
	jrl nz, DiskSel_PlayNextLoop
	stda16 33758, xiz
	ld wa, iz
	call 0xF89605
	ldda16 xde, 33758
	exts xde
	ldda32 xwa, 33754
	ld xbc, 0x1E50002
	call 0xFA9D58
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	call LABEL_F87A08
	ldfr_werp HL, 0xFA
	calr SignalProgressUpdate
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	call 0xFA9D58
	cpi_werp 0xFA, 0
	jr ge, DiskSel_PlayNextSong
	stdi8 34046, 0
	ldw wa, 0x60
	call 0xF99490
	ldto_werp WA, 0xFA
	lds bc, 1
	calr LABEL_F8B48E
	stda8 32578, l
	ldw wa, 0xEE

DiskSel_ShowErrorAndExit:
	call LABEL_F994BD
	jrl DiskSel_Exit

DiskSel_PlayNextSong:
	ldmw2 (xsp + 4), 0x83DE
	incdi8 1, 35132
	ld xwa, (xsp + 14)
	ld xbc, (xsp + 10)
	ld xde, (xsp + 6)
	calr DiskMed_PlayNextHelper
	cps l, 1
	jr nz, DiskSel_PlayNextLoop
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009A
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0x78
	call 0xF99490
	jr DiskSel_GetCurrentIndex

DiskSel_PlayNextLoop:
	inc 1, iz
	cp iz, 0x14
	jrl lt, DiskSel_PlayFindLoop
	jr DiskSel_GetCurrentIndex

DiskSel_HandleAllCheck:
	ld xwa, (xsp + 6)
	cp xwa, 0xE
	jr nz, DiskSel_GetCurrentIndex
	cp xbc, 0x1C00017
	jr nz, DiskSel_SetAllOff
	stdi8 35136, 1
	jr DiskSel_GetCurrentIndex

DiskSel_SetAllOff:
	stdi8 35136, 0

DiskSel_GetCurrentIndex:
	ldda16 xde, 33758

DiskSel_UpdateDisplay:
	cp (xsp + 4), de
	jr z, DiskSel_Exit
	ld wa, de
	call 0xF89605
	ldda16 xde, 33758
	exts xde
	ldda32 xwa, 33754
	ld xbc, 0x1E50002
	call 0xFA9D58
	ld de, (xsp + 4)
	sll de, 5
	ldada xbc, 34060
	extz xde
	add xde, xbc
	ldda32 xwa, 33754
	ld xbc, 0x1C0000F
	call 0xFA9D58
	ldda16 xde, 33758
	sll de, 5
	ldada xbc, 34060
	extz xde
	add xde, xbc
	ldda32 xwa, 33754
	ld xbc, 0x1C0000F

DiskSel_PostEvent:
	call 0xFA9D58

DiskSel_Exit:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 14)
	ret

LABEL_F92C0E:
GetPlayState1:
	ldda8 l, 35138
	ret

LABEL_F92C13:
GetPlayState2:
	ldda8 l, 35140
	ret

SmfMedley_RawData:
	.byte 0xc9, 0xd8, 0xd8, 0x7e, 0xf1, 0x44, 0x89, 0x41
	.byte 0x0e

LABEL_F92C21:
NavigateSongList:
	dec 2, xsp
	pushw iz
	ld (xsp + 2), wa
	cpw (xsp + 2), 0x1
	jr z, NavSong_CheckBounds
	cpw (xsp + 2), 0xFFFF
	jr nz, NavSong_Exit

NavSong_CheckBounds:
	cpdi16 34052, 0
	jr le, NavSong_Exit
	call LABEL_F89AC7
	cps hl, 0
	jr lt, NavSong_Exit
	ld iz, hl
	add iz, (xsp + 2)
	jr ge, NavSong_WrapToEnd
	ldda16 xiz, 34052
	dec 1, iz
	jr NavSong_CheckEnd

NavSong_WrapToEnd:
	cpda16 xiz, 34052
	jr lt, NavSong_CheckEnd
	lds iz, 0

NavSong_CheckEnd:
	cp hl, iz
	jr z, NavSong_Exit
	ld wa, iz
	call LABEL_F89BA4
	ld wa, iz
	call LABEL_F8A07F

NavSong_Exit:
	popw iz
	inc 2, xsp
	ret

LABEL_F92C70:
NavigateDocList:
	pushw iz
	ld iz, wa
	cps iz, 1
	jr z, NavDoc_CheckBounds
	cp iz, 0xFFFF
	jr nz, NavDoc_Exit

NavDoc_CheckBounds:
	cpdi16 34056, 0
	jr le, NavDoc_Exit
	call LABEL_F8A7CE
	cps hl, 0
	jr lt, NavDoc_Exit
	ld wa, hl
	add wa, iz
	jr ge, NavDoc_WrapToEnd
	ldda16 xwa, 34056
	dec 1, wa
	jr NavDoc_CheckEnd

NavDoc_WrapToEnd:
	cpda16 xwa, 34056
	jr lt, NavDoc_CheckEnd
	lds wa, 0

NavDoc_CheckEnd:
	cp hl, wa
	call_24 nz, 0xF8A956

NavDoc_Exit:
	popw iz
	ret

LABEL_F92CAC:
NavigatePdList:
	pushw iz
	ld iz, wa
	cps iz, 1
	jr z, NavPd_CheckBounds
	cp iz, 0xFFFF
	jr nz, NavPd_Exit

NavPd_CheckBounds:
	cpdi16 34054, 0
	jr le, NavPd_Exit
	call LABEL_F8A4C8
	cps hl, 0
	jr lt, NavPd_Exit
	ld wa, hl
	add wa, iz
	jr ge, NavPd_WrapToEnd
	ldda16 xwa, 34054
	dec 1, wa
	jr NavPd_CheckEnd

NavPd_WrapToEnd:
	cpda16 xwa, 34054
	jr lt, NavPd_CheckEnd
	lds wa, 0

NavPd_CheckEnd:
	cp hl, wa
	call_24 nz, 0xF8A5A5

NavPd_Exit:
	popw iz
	ret

SmfMed_FormatSlotList:
	dec 6, xsp
	push xiz
	ld iz, bc
	ld (xsp + 6), xwa
	lds32 xwa, 0
	ld xbc, 0x1E50003
	lds32 xde, 0
	calr FmmSmfFileNameFunc
	ldfr_werp HL, 0xFA
	ldto_werp WA, 0xFA
	extz xwa
	div wa, 0xA
	ldfr_werp WA, 0xFA
	mul wa, 0xA
	ldfr_werp WA, 0xFA
	ldw (xsp + 4), 0xA
	ldto_werp WA, 0xFA
	add wa, 0xA
	cp wa, iz
	jr c, SmfFmt_CalcVisible
	ld (xsp + 4), iz
	ldto_werp WA, 0xFA
	sub (xsp + 4), wa

SmfFmt_CalcVisible:
	lds iz, 0
	cpw (xsp + 4), 0x0
	jr ule, SmfFmt_FillEmpty

SmfFmt_FormatLoop:
	ld wa, iz
	sll wa, 3
	ldada xbc, 33760
	extz xwa
	add xwa, xbc
	ldto_werp BC, 0xFA
	add bc, iz
	ldada xde, 34976
	extz xbc
	add xbc, xde
	ld c, (xbc)
	extz bc
	ld de, iz
	calr FormatMedleyNumber
	ld de, iz
	sll de, 3
	ldada xwa, 33760
	extz xde
	add xde, xwa
	ld xwa, (xsp + 6)
	ld xbc, 0x1C0000F
	call 0xFA9D58
	inc 1, iz
	cp iz, (xsp + 4)
	jr c, SmfFmt_FormatLoop

SmfFmt_FillEmpty:
	cp iz, 0xA
	jr nc, SmfFmt_Exit

SmfFmt_EmptyLoop:
	ld wa, iz
	sll wa, 3
	ldada xbc, 33760
	extz xwa
	add xwa, xbc
	ldw bc, 0xFF
	ld de, iz
	calr FormatMedleyNumber
	ld de, iz
	sll de, 3
	ldada xwa, 33760
	extz xde
	add xde, xwa
	ld xwa, (xsp + 6)
	ld xbc, 0x1C0000F
	call 0xFA9D58
	inc 1, iz
	cp iz, 0xA
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
	cp xhl, 0x1E5000A
	jrl z, SmfMed_CheckContinue
	ld xwa, xde
	cp xhl, 0x1E50008
	jrl z, SmfMed_StoreDelayFlag
	ldda16 xbc, 33848
	cp xhl, 0x1C00018
	jrl z, SmfMed_HandleNavToggle
	cp xhl, 0x1C00017
	jrl z, SmfMed_HandleNavToggle
	cp xhl, 0x1C0000B
	jrl z, SmfMed_RefreshDisplay
	cp xhl, 0x1E50004
	jrl z, SmfMed_StoreWindowPtr
	cp xhl, 0x1C00013
	jrl nz, SmfMed_Exit
	cp xde, 0x3
	jrl z, SmfMed_HandleStop
	cp xde, 0x2
	jrl nz, SmfMed_Exit
	lds wa, 0
	calr InitializeOperationState
	ldda8 a, 36151
	stda8 33850, a
	cp a, 0x6F
	jr z, SmfMed_CheckNotPlaying
	cp a, 0x72
	jr nz, SmfMed_CheckPlayMode

SmfMed_CheckNotPlaying:
	stdi8 34046, 0
	call LABEL_F2076D
	cps l, 4
	jr z, SmfMed_Error3F
	cps l, 3
	jr z, SmfMed_Error31
	cps l, 2
	jrl nz, SmfMed_Exit
	stdi8 32578, 1
	ldw wa, 0xEE
	jr SmfMed_ShowError

SmfMed_Error31:
	stdi8 32578, 49
	ldw wa, 0xEE
	jr SmfMed_ShowError

SmfMed_Error3F:
	stdi8 32578, 63
	ldw wa, 0xEE

SmfMed_ShowError:
	call LABEL_F994BD
	jrl SmfMed_Exit

SmfMed_CheckPlayMode:
	cp a, 0x73
	jr z, SmfMed_CheckPlaying
	cp a, 0x76
	jrl nz, SmfMed_InitFromDisk

SmfMed_CheckPlaying:
	call LABEL_F2076D
	cps l, 1
	jrl c, SmfMed_CheckNotPlayError
	call LABEL_F2076D
	cps l, 4
	jr z, SmfMed_PlayError3F
	cps l, 3
	jr z, SmfMed_PlayError31
	cps l, 2
	jr nz, SmfMed_SetPlaying
	stdi8 32578, 1
	ldw wa, 0xEE
	jr SmfMed_ShowPlayError

SmfMed_PlayError31:
	stdi8 32578, 49
	ldw wa, 0xEE
	jr SmfMed_ShowPlayError

SmfMed_PlayError3F:
	stdi8 32578, 63
	ldw wa, 0xEE

SmfMed_ShowPlayError:
	call LABEL_F994BD
	incdi8 1, 33852

SmfMed_SetPlaying:
	stdi8 34046, 1
	ldda8 a, 35106
	cpda8 a, 35104
	jr nc, SmfMed_CheckRepeat
	lds iz, 0
	ldda16 xbc, 33848
	cps bc, 0
	jrl ule, SmfMed_Exit
	ldada xde, 34976

SmfMed_FindSongLoop:
	ld hl, iz
	extz xhl
	add xhl, xde
	cp (xhl), a
	jr nz, SmfMed_NextSong
	ld de, iz
	extz xde
	ld xwa, (xsp + 2)
	ld xbc, 0x1E50002
	calr FmmSmfFileNameFunc
	ldda32 xwa, 33840
	ldda16 xbc, 33848
	calr SmfMed_FormatSlotList
	incdi8 1, 35106
	ld wa, iz
	call LABEL_F8A07F
	ldda32 xwa, 33844
	or xwa, xwa
	jrl z, SmfMed_Exit
	ld xbc, 0x1E50009
	ld xde, 0x1E
	jr SmfMed_PostDelayEvent

SmfMed_NextSong:
	inc 1, iz
	cp iz, bc
	jr c, SmfMed_FindSongLoop
	jrl SmfMed_Exit

SmfMed_CheckRepeat:
	cpdi8 35108, 0
	jr z, SmfMed_ClearRepeatCount
	cpdm8 33852, a
	jr nc, SmfMed_ClearRepeatCount
	stdi8 35106, 0
	stdi8 33852, 0
	lds iz, 0
	ldda16 xwa, 33848
	cps wa, 0
	jrl ule, SmfMed_Exit
	ldada xbc, 34976

SmfMed_RepeatFindLoop:
	ld de, iz
	extz xde
	add xde, xbc
	cp (xde), 0x0
	jr nz, SmfMed_RepeatNext
	ld de, iz
	extz xde
	ld xwa, (xsp + 2)
	ld xbc, 0x1E50002
	calr FmmSmfFileNameFunc
	ldda32 xwa, 33840
	ldda16 xbc, 33848
	calr SmfMed_FormatSlotList
	incdi8 1, 35106
	ld wa, iz
	call LABEL_F8A07F
	ldda32 xwa, 33844
	or xwa, xwa
	jrl z, SmfMed_Exit
	ld xbc, 0x1E50009
	ld xde, 0x1E

SmfMed_PostDelayEvent:
	call 0xFA9D58
	jrl SmfMed_Exit

SmfMed_RepeatNext:
	inc 1, iz
	cp iz, wa
	jr c, SmfMed_RepeatFindLoop
	jrl SmfMed_Exit

SmfMed_ClearRepeatCount:
	stdi8 33852, 0
	jr SmfMed_ClearPlaying

SmfMed_CheckNotPlayError:
	call LABEL_F2076D
	cps l, 0
	jrl nz, SmfMed_Exit

SmfMed_ClearPlaying:
	stdi8 34046, 0
	jrl SmfMed_Exit

SmfMed_InitFromDisk:
	lds32 xde, 0
	ldda8 e, 35140
	ld xwa, 0x6C0018
	ld xbc, 0x1E0003B
	call 0xFA9D58
	cpdi16 34052, 0
	jr ge, SmfMed_InitState
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	call 0xF89C78
	stda16 34052, xhl
	call LABEL_F8958D
	call 0xF8953B
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	call 0xFA9D58
	calr SignalProgressUpdate

SmfMed_InitState:
	stdi8 34046, 0
	stdi8 35106, 0
	stdi8 35104, 0
	ldw bc, 0x80
	ldda16 xwa, 34052
	cp wa, 0x80
	jr ugt, SmfMed_ClampFileCount
	ld bc, wa

SmfMed_ClampFileCount:
	stda16 33848, xbc
	lds iz, 0
	cps bc, 0
	jr ule, SmfMed_FinishInit
	ldada xwa, 34976

SmfMed_ClearSlotsLoop:
	ld bc, iz
	extz xbc
	add xbc, xwa
	ld (xbc), 0xFF
	inc 1, iz
	cpda16 xiz, 33848
	jr c, SmfMed_ClearSlotsLoop

SmfMed_FinishInit:
	call LABEL_F20ACD
	lds32 xwa, 0
	stda32 33844, xwa
	jrl SmfMed_Exit

LABEL_F93051:
SmfMed_HandleStop:
	ldda8 a, 36150
	cp a, 0x6F
	jrl z, SmfMed_Exit
	cp a, 0x72
	jrl z, SmfMed_Exit
	cp a, 0x73
	jrl z, SmfMed_Exit
	cp a, 0x76
	jrl z, SmfMed_Exit
	call LABEL_F20B70
	calr CancelOperationCleanup
	stdi8 34046, 0
	jrl SmfMed_Exit

SmfMed_StoreWindowPtr:
	stda32 33840, xwa
	jrl SmfMed_Exit

SmfMed_RefreshDisplay:
	ldda32 xwa, 33840
	calr SmfMed_FormatSlotList
	jrl SmfMed_Exit

SmfMed_HandleNavToggle:
	ldada xwa, 34976
	cp xde, 0xA
	jr nz, SmfMed_HandleSelectToggle
	cpdi8 34046, 0
	jr nz, SmfMed_HandleSelectToggle
	lds iz, 0
	ld de, bc
	cps bc, 0
	jr ule, SmfMed_CheckAllUnmarked

SmfMed_FindUnmarkedLoop:
	ld bc, iz
	extz xbc
	add xbc, xwa
	cp (xbc), 0xFF
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
	ldada xde, 34976

SmfMed_AssignOrderLoop:
	ld bc, iz
	extz xbc
	add xbc, xde
	ld a, (xbc)
	cp a, 0xFF
	jr nz, SmfMed_NextAssign
	ldmi16 (xbc), 0x8920
	incdi8 1, 35104

SmfMed_NextAssign:
	inc 1, iz
	cpda16 xiz, 33848
	jr c, SmfMed_AssignOrderLoop
	jr SmfMed_RefreshAfterToggle

SmfMed_RemoveOrderLoop:
	lds iz, 0
	cps de, 0
	jr ule, SmfMed_RefreshAfterToggle
	ldada xde, 34976

SmfMed_UnmarkLoop:
	ld bc, iz
	extz xbc
	add xbc, xde
	ld a, (xbc)
	cp a, 0xFD
	jr ugt, SmfMed_NextUnmark
	ld (xbc), 0xFF
	decdi8 1, 35104

SmfMed_NextUnmark:
	inc 1, iz
	cpda16 xiz, 33848
	jr c, SmfMed_UnmarkLoop

SmfMed_RefreshAfterToggle:
	ldda32 xwa, 33840
	ldda16 xbc, 33848
	jr SmfMed_CallFormatSlots

SmfMed_HandleSelectToggle:
	cp xde, 0xB
	jr nz, SmfMed_HandleRepeat
	cpdi8 34046, 0
	jr nz, SmfMed_HandleRepeat
	ld xwa, (xsp + 2)
	ld xbc, 0x1E50003
	lds32 xde, 0
	calr FmmSmfFileNameFunc
	ld iz, hl
	ldada xhl, 34976
	ld wa, iz
	extz xwa
	add xwa, xhl
	ld c, (xwa)
	cp c, 0xFF
	jr nz, SmfMed_RemoveFromOrder
	ldmi16 (xwa), 0x8920
	incdi8 1, 35104
	jr SmfMed_RefreshAfterSelect

SmfMed_RemoveFromOrder:
	cp c, 0xFD
	jr ugt, SmfMed_RefreshAfterSelect
	ld (xwa), 0xFF
	ldda8 a, 35104
	dec 1, a
	stda8 35104, a
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
	cp a, 0xFD
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
	ldda32 xwa, 33840
	ldda16 xbc, 33848

SmfMed_CallFormatSlots:
	calr SmfMed_FormatSlotList
	jrl SmfMed_Exit

SmfMed_HandleRepeat:
	cp xde, 0xC
	jr nz, SmfMed_HandlePlay
	cp xhl, 0x1C00017
	jr nz, SmfMed_SetRepeatOff
	stdi8 35108, 1
	jrl SmfMed_Exit

SmfMed_SetRepeatOff:
	stdi8 35108, 0
	jrl SmfMed_Exit

SmfMed_HandlePlay:
	cp xde, 0xD
	jrl nz, SmfMed_Exit
	cpdi8 34046, 0
	jrl nz, SmfMed_Exit
	stdi8 35106, 0
	stdi8 33852, 0
	lds iz, 0
	ldda16 xbc, 33848
	cps bc, 0
	jr ule, SmfMed_CheckAutoPlay

SmfMed_PlayFindLoop:
	ld de, iz
	extz xde
	add xde, xwa
	cp (xde), 0x0
	jr nz, SmfMed_PlayNextLoop
	stdi8 34046, 1
	ld de, iz
	extz xde
	ld xwa, (xsp + 2)
	ld xbc, 0x1E50002
	calr FmmSmfFileNameFunc
	incdi8 1, 35106
	ld wa, iz
	call LABEL_F8A07F
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009A
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0x73
	call 0xF99490
	jr SmfMed_CheckAutoPlay

SmfMed_PlayNextLoop:
	inc 1, iz
	cp iz, bc
	jr c, SmfMed_PlayFindLoop

SmfMed_CheckAutoPlay:
	cpdi8 34046, 0
	jr nz, SmfMed_Exit
	ld xwa, (xsp + 2)
	ld xbc, 0x1E50003
	lds32 xde, 0
	calr FmmSmfFileNameFunc
	ld iz, hl
	ld wa, iz
	call LABEL_F8A07F
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009A
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0x6F
	jr SmfMed_CallPauseMode

SmfMed_StoreDelayFlag:
	stda32 33844, xwa
	jr SmfMed_Exit

SmfMed_CheckContinue:
	cpdi8 34046, 0
	jr z, SmfMed_Exit
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009A
	lds32 xde, 0
	call 0xFA9D58
	ldda8 a, 33850
	extz wa

SmfMed_CallPauseMode:
	call 0xF99490

SmfMed_Exit:
	lds32 xhl, 0
	popw iz
	inc 4, xsp
	ret

LABEL_F93283:
PdMed_FormatFileList:
	dec 6, xsp
	pushw iz
	ld (xsp + 2), bc
	ld (xsp + 4), xwa
	lds iz, 0

PdFmt_FormatLoop:
	ld de, iz
	sll de, 5
	ldada xbc, 34060
	extz xde
	add xde, xbc
	ldto_berp A, 0xF8
	ld (xde), a
	ld wa, (xsp + 2)
	add wa, iz
	call LABEL_F8A5F1
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
	pushw 0x14
	pushw 0x1
	call LABEL_F891DD
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
	jr lt, PdFmt_FormatLoop
	popw iz
	inc 6, xsp
	ret

FmmPdFileNameFunc:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xwa
	cp xbc, 0x1E50003
	jrl z, PdName_GetIndexReturn
	ldda16 xwa, 33858
	ld iz, wa
	cp xbc, 0x1E50002
	jrl z, PdName_SetIndexPlaying
	ld hl, wa
	exts xhl
	divs hl, 0xA
	cp xbc, 0x1C00018
	jr z, PdName_HandleNavigation
	cp xbc, 0x1C00017
	jr z, PdName_HandleNavigation
	cp xbc, 0x1C0000B
	jr z, PdName_RefreshList
	cp xbc, 0x1E50004
	jr nz, PdName_ReturnZero
	stda32 33854, xde
	call LABEL_F8A4C8
	stda16 33858, xhl
	cps hl, 0
	jr ge, PdName_UpdateIndex
	stdi16 33858, 0

PdName_UpdateIndex:
	ldda16 xwa, 33858
	exts xwa
	divs wa, 0xA
	ldto_werp DE, 0xE2
	exts xde
	ldda32 xwa, 33854
	ld xbc, 0x1E50002
	jrl PdName_PostEvent

PdName_RefreshList:
	muls hl, 0xA
	ldda32 xwa, 33854
	ld bc, hl
	calr PdMed_FormatFileList

PdName_ReturnZero:
	lds32 xhl, 0
	jrl PdName_Exit

PdName_HandleNavigation:
	or xde, xde
	jr nz, PdName_CheckPageUp
	cpdi8 34046, 0
	jr nz, PdName_CheckPageUp
	cp xbc, 0x1C00018
	jr nz, PdName_CheckPrevKey
	ld bc, wa
	inc 1, bc
	cpda16 xbc, 34054
	jr ge, PdName_GetCurrentIndex
	inc 1, wa
	jr PdName_SaveIndex

PdName_CheckPrevKey:
	cp xbc, 0x1C00017
	jr nz, PdName_GetCurrentIndex
	cps wa, 0
	jr le, PdName_GetCurrentIndex
	dec 1, wa
	jr PdName_SaveIndex

PdName_CheckPageUp:
	cp xde, 0x1
	jr nz, PdName_CheckPageDown
	cpdi8 34046, 0
	jr nz, PdName_CheckPageDown
	cp wa, 0xA
	jr lt, PdName_GetCurrentIndex
	sub wa, 0xA
	jr PdName_SaveIndex

PdName_CheckPageDown:
	cp xde, 0x2
	jr nz, PdName_GetCurrentIndex
	cpdi8 34046, 0
	jr nz, PdName_GetCurrentIndex
	ld bc, wa
	add bc, 0xA
	ldda16 xde, 34054
	cp bc, de
	jr ge, PdName_CheckEndBound
	add wa, 0xA

PdName_SaveIndex:
	stda16 33858, xwa
	jr PdName_UpdateDisplay

PdName_CheckEndBound:
	ld bc, de
	dec 1, bc
	ld wa, bc
	exts xwa
	divs wa, 0xA
	cp hl, wa
	jr ge, PdName_GetCurrentIndex
	exts xde
	divs de, 0xA
	ldto_werp WA, 0xEA
	cps wa, 0
	jr z, PdName_GetCurrentIndex
	stda16 33858, xbc

PdName_GetCurrentIndex:
	ldda16 xwa, 33858

PdName_UpdateDisplay:
	cp iz, wa
	jrl z, PdName_ReturnZero
	call LABEL_F8A5A5
	ldda16 xwa, 33858
	exts xwa
	divs wa, 0xA
	ldto_werp DE, 0xE2
	exts xde
	ldda32 xwa, 33854
	ld xbc, 0x1E50002
	call 0xFA9D58
	ldda16 xbc, 33858
	exts xbc
	divs bc, 0xA
	ld de, iz
	exts xde
	divs de, 0xA
	ldda32 xwa, 33854
	cp de, bc
	jr nz, PdName_RefreshPage
	ld bc, iz
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
	ldda16 xwa, 33858
	exts xwa
	divs wa, 0xA
	ldto_werp WA, 0xE2
	sll wa, 5
	ldada xbc, 34060
	ld de, wa
	extz xde
	add xde, xbc
	ldda32 xwa, 33854
	ld xbc, 0x1C0000F
	call 0xFA9D58
	jrl PdName_ReturnZero

PdName_RefreshPage:
	muls bc, 0xA
	calr PdMed_FormatFileList
	ld xwa, (xsp + 2)
	ld xbc, 0x1C0000B
	lds32 xde, 0
	calr FmmPdMedleyFunc
	jrl PdName_ReturnZero

PdName_SetIndexPlaying:
	cpdi8 34046, 0
	jrl z, PdName_ReturnZero
	stda16 33858, xde
	ld wa, de
	call LABEL_F8A5A5
	ldda16 xwa, 33858
	exts xwa
	divs wa, 0xA
	ldto_werp DE, 0xE2
	exts xde
	ldda32 xwa, 33854
	ld xbc, 0x1E50002

PdName_PostEvent:
	call 0xFA9D58
	jrl PdName_ReturnZero

PdName_GetIndexReturn:
	ldda16 xhl, 33858
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
	ld xbc, 0x1E50003
	lds32 xde, 0
	calr FmmPdFileNameFunc
	ldfr_werp HL, 0xFA
	ldto_werp WA, 0xFA
	extz xwa
	div wa, 0xA
	ldfr_werp WA, 0xFA
	mul wa, 0xA
	ldfr_werp WA, 0xFA
	ldw (xsp + 4), 0xA
	ldto_werp WA, 0xFA
	add wa, 0xA
	cp wa, iz
	jr c, PdFmtSlot_CalcVisible
	ld (xsp + 4), iz
	ldto_werp WA, 0xFA
	sub (xsp + 4), wa

PdFmtSlot_CalcVisible:
	lds iz, 0
	cpw (xsp + 4), 0x0
	jr ule, PdFmtSlot_FillEmpty

PdFmtSlot_FormatLoop:
	ld wa, iz
	sll wa, 3
	ldada xbc, 33860
	extz xwa
	add xwa, xbc
	ldto_werp BC, 0xFA
	add bc, iz
	ldada xde, 34976
	extz xbc
	add xbc, xde
	ld c, (xbc)
	extz bc
	ld de, iz
	calr FormatMedleyNumber
	ld de, iz
	sll de, 3
	ldada xwa, 33860
	extz xde
	add xde, xwa
	ld xwa, (xsp + 6)
	ld xbc, 0x1C0000F
	call 0xFA9D58
	inc 1, iz
	cp iz, (xsp + 4)
	jr c, PdFmtSlot_FormatLoop

PdFmtSlot_FillEmpty:
	cp iz, 0xA
	jr nc, PdFmtSlot_Exit

PdFmtSlot_EmptyLoop:
	ld wa, iz
	sll wa, 3
	ldada xbc, 33860
	extz xwa
	add xwa, xbc
	ldw bc, 0xFF
	ld de, iz
	calr FormatMedleyNumber
	ld de, iz
	sll de, 3
	ldada xwa, 33860
	extz xde
	add xde, xwa
	ld xwa, (xsp + 6)
	ld xbc, 0x1C0000F
	call 0xFA9D58
	inc 1, iz
	cp iz, 0xA
	jr c, PdFmtSlot_EmptyLoop

PdFmtSlot_Exit:
	pop xiz
	inc 6, xsp
	ret

LABEL_F935C0:
FmmPdMedleyFunc:
	push xiz
	ld xhl, xde
	ld xde, xbc
	ld xiz, xwa
	cp xde, 0x1E5000A
	jrl z, PdMed_CheckContinue
	ld xwa, xhl
	cp xde, 0x1E50008
	jrl z, PdMed_StoreDelayFlag
	ldda16 xbc, 33948
	cp xde, 0x1C00018
	jrl z, PdMed_HandleNavToggle
	cp xde, 0x1C00017
	jrl z, PdMed_HandleNavToggle
	cp xde, 0x1C0000B
	jrl z, PdMed_RefreshDisplay
	cp xde, 0x1E50004
	jrl z, PdMed_StoreWindowPtr
	cp xde, 0x1C00013
	jrl nz, PdMed_Exit
	cp xhl, 0x3
	jrl z, PdMed_HandleStop
	cp xhl, 0x2
	jrl nz, PdMed_Exit
	lds wa, 0
	call 0xF8B204
	ldda8 a, 36151
	cp a, 0x71
	jr nz, PdMed_CheckPlayMode
	stdi8 34046, 0
	call LABEL_F2076D
	cps l, 2
	jrl c, PdMed_Exit
	stdi8 32578, 1
	ldw wa, 0xEE
	jrl PdMed_ShowError

PdMed_CheckPlayMode:
	cp a, 0x75
	jrl nz, PdMed_InitFromDisk
	call LABEL_F2076D
	cps l, 1
	jrl nz, PdMed_HandleError
	stdi8 34046, 1
	ldda8 c, 35106
	ldada xwa, 34976
	cpda8 c, 35104
	jr nc, PdMed_CheckRepeat
	lds hl, 0
	ldda16 xde, 33948
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
	ld xbc, 0x1E50002
	ld xde, xhl
	calr FmmPdFileNameFunc
	ldda32 xwa, 33940
	ldda16 xbc, 33948
	calr PdMed_FormatSlotList
	incdi8 1, 35106
	ldda32 xwa, 33944
	or xwa, xwa
	jrl z, PdMed_Exit
	ld xbc, 0x1E50009
	ld xde, 0x1E
	jr PdMed_PostDelayEvent

PdMed_NextSong:
	inc 1, hl
	cp hl, de
	jr c, PdMed_FindSongLoop
	jrl PdMed_Exit

PdMed_CheckRepeat:
	cpdi8 35108, 0
	jr z, PdMed_ClearPlaying
	stdi8 35106, 0
	lds hl, 0
	ldda16 xbc, 33948
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
	ld xbc, 0x1E50002
	ld xde, xhl
	calr FmmPdFileNameFunc
	ldda32 xwa, 33940
	ldda16 xbc, 33948
	calr PdMed_FormatSlotList
	incdi8 1, 35106
	ldda32 xwa, 33944
	or xwa, xwa
	jrl z, PdMed_Exit
	ld xbc, 0x1E50009
	ld xde, 0x1E

PdMed_PostDelayEvent:
	call 0xFA9D58
	jrl PdMed_Exit

PdMed_RepeatNext:
	inc 1, hl
	cp hl, bc
	jr c, PdMed_RepeatFindLoop
	jrl PdMed_Exit

PdMed_ClearPlaying:
	stdi8 34046, 0
	jrl PdMed_Exit

PdMed_HandleError:
	call LABEL_F2076D
	stdi8 34046, 0
	cps l, 0
	jrl z, PdMed_Exit
	stdi8 32578, 1
	ldw wa, 0xEE

PdMed_ShowError:
	call LABEL_F994BD
	jrl PdMed_Exit

LABEL_F9373F:
PdMed_InitFromDisk:
	cpdi16 34054, 0
	jr ge, PdMed_InitState
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	call LABEL_F8A625
	stda16 34054, xhl
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	call 0xFA9D58
	call 0xF8B260

PdMed_InitState:
	stdi8 34046, 0
	stdi8 35106, 0
	stdi8 35104, 0
	ldw bc, 0x80
	ldda16 xwa, 34054
	cp wa, 0x80
	jr ugt, PdMed_ClampCount
	ld bc, wa

PdMed_ClampCount:
	stda16 33948, xbc
	lds hl, 0
	cps bc, 0
	jr ule, PdMed_FinishInit
	ldada xwa, 34976

PdMed_ClearSlotsLoop:
	ld bc, hl
	extz xbc
	add xbc, xwa
	ld (xbc), 0xFF
	inc 1, hl
	cpda16 xhl, 33948
	jr c, PdMed_ClearSlotsLoop

PdMed_FinishInit:
	call LABEL_F20ACD
	lds32 xwa, 0
	stda32 33944, xwa
	jrl PdMed_Exit

PdMed_HandleStop:
	ldda8 a, 36150
	cp a, 0x71
	jrl z, PdMed_Exit
	cp a, 0x75
	jrl z, PdMed_Exit
	call LABEL_F20B70
	call 0xF8B244
	stdi8 34046, 0
	jrl PdMed_Exit

PdMed_StoreWindowPtr:
	stda32 33940, xwa
	jrl PdMed_Exit

PdMed_RefreshDisplay:
	ldda32 xwa, 33940
	calr PdMed_FormatSlotList
	jrl PdMed_Exit

PdMed_HandleNavToggle:
	cp xhl, 0xA
	jrl nz, PdMed_HandleSelectToggle
	cpdi8 34046, 0
	jr nz, PdMed_HandleSelectToggle
	lds hl, 0
	ld wa, bc
	cps bc, 0
	jr ule, PdMed_CheckAllUnmarked
	ldada xbc, 34976

PdMed_FindUnmarkedLoop:
	ld de, hl
	extz xde
	add xde, xbc
	cp (xde), 0xFF
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
	ldada xde, 34976

PdMed_AssignOrderLoop:
	ld bc, hl
	extz xbc
	add xbc, xde
	ld a, (xbc)
	cp a, 0xFF
	jr nz, PdMed_NextAssign
	ldmi16 (xbc), 0x8920
	incdi8 1, 35104

PdMed_NextAssign:
	inc 1, hl
	cpda16 xhl, 33948
	jr c, PdMed_AssignOrderLoop
	jr PdMed_RefreshAfterToggle

PdMed_RemoveOrderLoop:
	lds hl, 0
	cps wa, 0
	jr ule, PdMed_RefreshAfterToggle
	ldada xde, 34976

PdMed_UnmarkLoop:
	ld bc, hl
	extz xbc
	add xbc, xde
	ld a, (xbc)
	cp a, 0xFD
	jr ugt, PdMed_NextUnmark
	ld (xbc), 0xFF
	decdi8 1, 35104

PdMed_NextUnmark:
	inc 1, hl
	cpda16 xhl, 33948
	jr c, PdMed_UnmarkLoop

PdMed_RefreshAfterToggle:
	ldda32 xwa, 33940
	ldda16 xbc, 33948
	jr PdMed_CallFormatSlots

PdMed_HandleSelectToggle:
	cp xhl, 0xB
	jr nz, PdMed_HandleRepeat
	cpdi8 34046, 0
	jr nz, PdMed_HandleRepeat
	ld xwa, xiz
	ld xbc, 0x1E50003
	lds32 xde, 0
	calr FmmPdFileNameFunc
	ldada xix, 34976
	extz xhl
	add xhl, xix
	ld c, (xhl)
	cp c, 0xFF
	jr nz, PdMed_RemoveFromOrder
	ldmi16 (xhl), 0x8920
	incdi8 1, 35104
	jr PdMed_RefreshAfterSelect

PdMed_RemoveFromOrder:
	cp c, 0xFD
	jr ugt, PdMed_RefreshAfterSelect
	ld (xhl), 0xFF
	ldda8 a, 35104
	dec 1, a
	stda8 35104, a
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
	cp a, 0xFD
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
	ldda32 xwa, 33940
	ldda16 xbc, 33948

PdMed_CallFormatSlots:
	calr PdMed_FormatSlotList
	jrl PdMed_Exit

PdMed_HandleRepeat:
	cp xhl, 0xC
	jr nz, PdMed_HandlePlay
	cp xde, 0x1C00017
	jr nz, PdMed_SetRepeatOff
	stdi8 35108, 1
	jrl PdMed_Exit

PdMed_SetRepeatOff:
	stdi8 35108, 0
	jrl PdMed_Exit

PdMed_HandlePlay:
	cp xhl, 0xD
	jrl nz, PdMed_Exit
	cpdi8 34046, 0
	jrl nz, PdMed_Exit
	stdi8 35106, 0
	lds hl, 0
	ldda16 xwa, 33948
	cps wa, 0
	jr ule, PdMed_CheckAutoPlay
	ldada xbc, 34976

PdMed_PlayFindLoop:
	ld de, hl
	extz xde
	add xde, xbc
	cp (xde), 0x0
	jr nz, PdMed_PlayNextLoop
	stdi8 34046, 1
	extz xhl
	ld xwa, xiz
	ld xbc, 0x1E50002
	ld xde, xhl
	calr FmmPdFileNameFunc
	incdi8 1, 35106
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009A
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0x75
	call 0xF99490
	jr PdMed_CheckAutoPlay

PdMed_PlayNextLoop:
	inc 1, hl
	cp hl, wa
	jr c, PdMed_PlayFindLoop

PdMed_CheckAutoPlay:
	cpdi8 34046, 0
	jr nz, PdMed_Exit
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009A
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0x71
	jr PdMed_CallPauseMode

PdMed_StoreDelayFlag:
	stda32 33944, xwa
	jr PdMed_Exit

PdMed_CheckContinue:
	cpdi8 34046, 0
	jr z, PdMed_Exit
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009A
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0x75

PdMed_CallPauseMode:
	call 0xF99490

PdMed_Exit:
	lds32 xhl, 0
	pop xiz
	ret

LABEL_F939CE:
DocDiskNameFunc:
	push xiz
	ld xiz, xde
	cp xbc, 0x1C0000B
	jr nz, DocDisk_Exit
	call LABEL_F8958D
	lds ix, 0
	jr DocDisk_CopyLoop

DocDisk_CopyCharLoop:
	cp (xhl), 0x20
	jr z, DocDisk_SkipSpace
	ld de, ix
	inc 1, ix
	ld a, (xhl)
	lda_dri3 XBC, 0x07, 0xE4, 0xE8

DocDisk_SkipSpace:
	inc 1, xhl

DocDisk_CopyLoop:
	ldada xbc, 34700
	cp (xhl), 0x0
	jr z, DocDisk_TerminateStr
	cp ix, 0x1E
	jr lt, DocDisk_CopyCharLoop

DocDisk_TerminateStr:
	ld xde, xbc
	stib_dri 0x07, 0xE4, 0xF0, 0x00
	jr DocDisk_TrimLoop

DocDisk_ClearTrailing:
	ld (xwa), 0x0

DocDisk_TrimLoop:
	dec 1, ix
	st_dri3b W, 0x07, 0xE8, 0xF0
	cp (xwa), 0x20
	jr nz, DocDisk_PostEvent
	cps ix, 0
	jr gt, DocDisk_ClearTrailing

DocDisk_PostEvent:
	ld xwa, xiz
	ld xbc, 0x1C0000F
	call 0xFA9D58

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
	ldada xbc, 34060
	extz xde
	add xde, xbc
	ldto_berp A, 0xF8
	ld (xde), a
	ld wa, (xsp + 2)
	add wa, iz
	call LABEL_F8ABBB
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
	pushw 0x0
	call LABEL_F891DD
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
	jr lt, DocFmt_FormatLoop
	popw iz
	inc 6, xsp
	ret

FmmDocFileNameFunc:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xwa
	cp xbc, 0x1E50003
	jrl z, DocName_GetIndexReturn
	ldda16 xwa, 33954
	ld iz, wa
	cp xbc, 0x1E50002
	jrl z, DocName_SetIndexPlaying
	ld hl, wa
	exts xhl
	divs hl, 0xA
	cp xbc, 0x1C00018
	jr z, DocName_HandleNavigation
	cp xbc, 0x1C00017
	jr z, DocName_HandleNavigation
	cp xbc, 0x1C0000B
	jr z, DocName_RefreshList
	cp xbc, 0x1E50004
	jr nz, DocName_ReturnZero
	stda32 33950, xde
	call LABEL_F8A7CE
	stda16 33954, xhl
	cps hl, 0
	jr ge, DocName_UpdateIndex
	stdi16 33954, 0

DocName_UpdateIndex:
	ldda16 xwa, 33954
	exts xwa
	divs wa, 0xA
	ldto_werp DE, 0xE2
	exts xde
	ldda32 xwa, 33950
	ld xbc, 0x1E50002
	jrl DocName_PostEvent

DocName_RefreshList:
	muls hl, 0xA
	ldda32 xwa, 33950
	ld bc, hl
	calr DocMed_FormatFileList

DocName_ReturnZero:
	lds32 xhl, 0
	jrl DocName_Exit

DocName_HandleNavigation:
	or xde, xde
	jr nz, DocName_CheckPageUp
	cpdi8 34046, 0
	jr nz, DocName_CheckPageUp
	cp xbc, 0x1C00018
	jr nz, DocName_CheckPrevKey
	ld bc, wa
	inc 1, bc
	cpda16 xbc, 34056
	jr ge, DocName_GetCurrentIndex
	inc 1, wa
	jr DocName_SaveIndex

DocName_CheckPrevKey:
	cp xbc, 0x1C00017
	jr nz, DocName_GetCurrentIndex
	cps wa, 0
	jr le, DocName_GetCurrentIndex
	dec 1, wa
	jr DocName_SaveIndex

DocName_CheckPageUp:
	cp xde, 0x1
	jr nz, DocName_CheckPageDown
	cpdi8 34046, 0
	jr nz, DocName_CheckPageDown
	cp wa, 0xA
	jr lt, DocName_GetCurrentIndex
	sub wa, 0xA
	jr DocName_SaveIndex

DocName_CheckPageDown:
	cp xde, 0x2
	jr nz, DocName_GetCurrentIndex
	cpdi8 34046, 0
	jr nz, DocName_GetCurrentIndex
	ld bc, wa
	add bc, 0xA
	ldda16 xde, 34056
	cp bc, de
	jr ge, DocName_CheckEndBound
	add wa, 0xA

DocName_SaveIndex:
	stda16 33954, xwa
	jr DocName_UpdateDisplay

DocName_CheckEndBound:
	ld bc, de
	dec 1, bc
	ld wa, bc
	exts xwa
	divs wa, 0xA
	cp hl, wa
	jr ge, DocName_GetCurrentIndex
	exts xde
	divs de, 0xA
	ldto_werp WA, 0xEA
	cps wa, 0
	jr z, DocName_GetCurrentIndex
	stda16 33954, xbc

DocName_GetCurrentIndex:
	ldda16 xwa, 33954

DocName_UpdateDisplay:
	cp iz, wa
	jrl z, DocName_ReturnZero
	call LABEL_F8A956
	ldda16 xwa, 33954
	exts xwa
	divs wa, 0xA
	ldto_werp DE, 0xE2
	exts xde
	ldda32 xwa, 33950
	ld xbc, 0x1E50002
	call 0xFA9D58
	ldda16 xbc, 33954
	exts xbc
	divs bc, 0xA
	ld de, iz
	exts xde
	divs de, 0xA
	ldda32 xwa, 33950
	cp de, bc
	jr nz, DocName_RefreshPage
	ld bc, iz
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
	ldda16 xwa, 33954
	exts xwa
	divs wa, 0xA
	ldto_werp WA, 0xE2
	sll wa, 5
	ldada xbc, 34060
	ld de, wa
	extz xde
	add xde, xbc
	ldda32 xwa, 33950
	ld xbc, 0x1C0000F
	call 0xFA9D58
	jrl DocName_ReturnZero

DocName_RefreshPage:
	muls bc, 0xA
	calr DocMed_FormatFileList
	ld xwa, (xsp + 2)
	ld xbc, 0x1C0000B
	lds32 xde, 0
	calr FmmDocMedleyFunc
	jrl DocName_ReturnZero

DocName_SetIndexPlaying:
	cpdi8 34046, 0
	jrl z, DocName_ReturnZero
	stda16 33954, xde
	ld wa, de
	call LABEL_F8A956
	ldda16 xwa, 33954
	exts xwa
	divs wa, 0xA
	ldto_werp DE, 0xE2
	exts xde
	ldda32 xwa, 33950
	ld xbc, 0x1E50002

DocName_PostEvent:
	call 0xFA9D58
	jrl DocName_ReturnZero

DocName_GetIndexReturn:
	ldda16 xhl, 33954
	exts xhl

DocName_Exit:
	popw iz
	inc 4, xsp
	ret

LABEL_F93C9C:
DocMed_FormatSlotList:
	dec 6, xsp
	push xiz
	ld iz, bc
	ld (xsp + 6), xwa
	lds32 xwa, 0
	ld xbc, 0x1E50003
	lds32 xde, 0
	calr FmmDocFileNameFunc
	ldfr_werp HL, 0xFA
	ldto_werp WA, 0xFA
	extz xwa
	div wa, 0xA
	ldfr_werp WA, 0xFA
	mul wa, 0xA
	ldfr_werp WA, 0xFA
	ldw (xsp + 4), 0xA
	ldto_werp WA, 0xFA
	add wa, 0xA
	cp wa, iz
	jr c, DocFmtSlot_CalcVisible
	ld (xsp + 4), iz
	ldto_werp WA, 0xFA
	sub (xsp + 4), wa

DocFmtSlot_CalcVisible:
	lds iz, 0
	cpw (xsp + 4), 0x0
	jr ule, DocFmtSlot_FillEmpty

DocFmtSlot_FormatLoop:
	ld wa, iz
	sll wa, 3
	ldada xbc, 33956
	extz xwa
	add xwa, xbc
	ldto_werp BC, 0xFA
	add bc, iz
	ldada xde, 34976
	extz xbc
	add xbc, xde
	ld c, (xbc)
	extz bc
	ld de, iz
	calr FormatMedleyNumber
	ld de, iz
	sll de, 3
	ldada xwa, 33956
	extz xde
	add xde, xwa
	ld xwa, (xsp + 6)
	ld xbc, 0x1C0000F
	call 0xFA9D58
	inc 1, iz
	cp iz, (xsp + 4)
	jr c, DocFmtSlot_FormatLoop

DocFmtSlot_FillEmpty:
	cp iz, 0xA
	jr nc, DocFmtSlot_Exit

DocFmtSlot_EmptyLoop:
	ld wa, iz
	sll wa, 3
	ldada xbc, 33956
	extz xwa
	add xwa, xbc
	ldw bc, 0xFF
	ld de, iz
	calr FormatMedleyNumber
	ld de, iz
	sll de, 3
	ldada xwa, 33956
	extz xde
	add xde, xwa
	ld xwa, (xsp + 6)
	ld xbc, 0x1C0000F
	call 0xFA9D58
	inc 1, iz
	cp iz, 0xA
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
	cp xde, 0x1E5000A
	jrl z, DocMed_CheckContinue
	ld xwa, xhl
	cp xde, 0x1E50008
	jrl z, DocMed_StoreDelayFlag
	ldda16 xbc, 34044
	cp xde, 0x1C00018
	jrl z, DocMed_HandleNavToggle
	cp xde, 0x1C00017
	jrl z, DocMed_HandleNavToggle
	cp xde, 0x1C0000B
	jrl z, DocMed_RefreshDisplay
	cp xde, 0x1E50004
	jrl z, DocMed_StoreWindowPtr
	cp xde, 0x1C00013
	jrl nz, DocMed_Exit
	cp xhl, 0x3
	jrl z, DocMed_HandleStop
	cp xhl, 0x2
	jrl nz, DocMed_Exit
	lds wa, 0
	call 0xF8B204
	ldda8 a, 36151
	cp a, 0x70
	jr nz, DocMed_CheckPlayMode
	stdi8 34046, 0
	call LABEL_F2076D
	cps l, 2
	jrl c, DocMed_Exit
	stdi8 32578, 1
	ldw wa, 0xEE
	jrl DocMed_ShowError

DocMed_CheckPlayMode:
	cp a, 0x74
	jrl nz, DocMed_CheckInit
	call LABEL_F2076D
	cps l, 1
	jrl nz, DocMed_HandleError
	stdi8 34046, 1
	ldda8 c, 35106
	ldada xwa, 34976
	cpda8 c, 35104
	jr nc, DocMed_CheckRepeat
	lds hl, 0
	ldda16 xde, 34044
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
	ld xbc, 0x1E50002
	ld xde, xhl
	calr FmmDocFileNameFunc
	ldda32 xwa, 34036
	ldda16 xbc, 34044
	calr DocMed_FormatSlotList
	incdi8 1, 35106
	ldda32 xwa, 34040
	or xwa, xwa
	jrl z, DocMed_Exit
	ld xbc, 0x1E50009
	ld xde, 0x1E
	jr DocMed_PostDelayEvent

DocMed_NextSong:
	inc 1, hl
	cp hl, de
	jr c, DocMed_FindSongLoop
	jrl DocMed_Exit

DocMed_CheckRepeat:
	cpdi8 35108, 0
	jr z, DocMed_ClearPlaying
	stdi8 35106, 0
	lds hl, 0
	ldda16 xbc, 34044
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
	ld xbc, 0x1E50002
	ld xde, xhl
	calr FmmDocFileNameFunc
	ldda32 xwa, 34036
	ldda16 xbc, 34044
	calr DocMed_FormatSlotList
	incdi8 1, 35106
	ldda32 xwa, 34040
	or xwa, xwa
	jrl z, DocMed_Exit
	ld xbc, 0x1E50009
	ld xde, 0x1E

DocMed_PostDelayEvent:
	call 0xFA9D58
	jrl DocMed_Exit

DocMed_RepeatNext:
	inc 1, hl
	cp hl, bc
	jr c, DocMed_RepeatFindLoop
	jrl DocMed_Exit

DocMed_ClearPlaying:
	stdi8 34046, 0
	jrl DocMed_Exit

DocMed_HandleError:
	call LABEL_F2076D
	stdi8 34046, 0
	cps l, 0
	jrl z, DocMed_Exit
	stdi8 32578, 1
	ldw wa, 0xEE

DocMed_ShowError:
	call LABEL_F994BD
	jrl DocMed_Exit

LABEL_F93EEA:
DocMed_CheckInit:
	cpdi16 34056, 0
	jr lt, DocMed_InitFromDisk
	cpdi16 34052, 0
	jr nz, DocMed_InitState

DocMed_InitFromDisk:
	stdi16 34052, 65535
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	call LABEL_F8A9D6
	stda16 34056, xhl
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	call 0xFA9D58
	call 0xF8B260

DocMed_InitState:
	stdi8 34046, 0
	stdi8 35106, 0
	stdi8 35104, 0
	ldw bc, 0x80
	ldda16 xwa, 34056
	cp wa, 0x80
	jr ugt, DocMed_ClampCount
	ld bc, wa

DocMed_ClampCount:
	stda16 34044, xbc
	lds hl, 0
	cps bc, 0
	jr ule, DocMed_FinishInit
	ldada xwa, 34976

DocMed_ClearSlotsLoop:
	ld bc, hl
	extz xbc
	add xbc, xwa
	ld (xbc), 0xFF
	inc 1, hl
	cpda16 xhl, 34044
	jr c, DocMed_ClearSlotsLoop

DocMed_FinishInit:
	call LABEL_F20ACD
	lds32 xwa, 0
	stda32 34040, xwa
	jrl DocMed_Exit

DocMed_HandleStop:
	ldda8 a, 36150
	cp a, 0x70
	jrl z, DocMed_Exit
	cp a, 0x74
	jrl z, DocMed_Exit
	call LABEL_F20B70
	call 0xF8B244
	stdi8 34046, 0
	jrl DocMed_Exit

DocMed_StoreWindowPtr:
	stda32 34036, xwa
	jrl DocMed_Exit

DocMed_RefreshDisplay:
	ldda32 xwa, 34036
	calr DocMed_FormatSlotList
	jrl DocMed_Exit

DocMed_HandleNavToggle:
	cp xhl, 0xA
	jrl nz, DocMed_HandleSelectToggle
	cpdi8 34046, 0
	jr nz, DocMed_HandleSelectToggle
	lds hl, 0
	ld wa, bc
	cps bc, 0
	jr ule, DocMed_CheckAllUnmarked
	ldada xbc, 34976

DocMed_FindUnmarkedLoop:
	ld de, hl
	extz xde
	add xde, xbc
	cp (xde), 0xFF
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
	ldada xde, 34976

DocMed_AssignOrderLoop:
	ld bc, hl
	extz xbc
	add xbc, xde
	ld a, (xbc)
	cp a, 0xFF
	jr nz, DocMed_NextAssign
	ldmi16 (xbc), 0x8920
	incdi8 1, 35104

DocMed_NextAssign:
	inc 1, hl
	cpda16 xhl, 34044
	jr c, DocMed_AssignOrderLoop
	jr DocMed_RefreshAfterToggle

DocMed_RemoveOrderLoop:
	lds hl, 0
	cps wa, 0
	jr ule, DocMed_RefreshAfterToggle
	ldada xde, 34976

DocMed_UnmarkLoop:
	ld bc, hl
	extz xbc
	add xbc, xde
	ld a, (xbc)
	cp a, 0xFD
	jr ugt, DocMed_NextUnmark
	ld (xbc), 0xFF
	decdi8 1, 35104

DocMed_NextUnmark:
	inc 1, hl
	cpda16 xhl, 34044
	jr c, DocMed_UnmarkLoop

DocMed_RefreshAfterToggle:
	ldda32 xwa, 34036
	ldda16 xbc, 34044
	jr DocMed_CallFormatSlots

DocMed_HandleSelectToggle:
	cp xhl, 0xB
	jr nz, DocMed_HandleRepeat
	cpdi8 34046, 0
	jr nz, DocMed_HandleRepeat
	ld xwa, xiz
	ld xbc, 0x1E50003
	lds32 xde, 0
	calr FmmDocFileNameFunc
	ldada xix, 34976
	extz xhl
	add xhl, xix
	ld c, (xhl)
	cp c, 0xFF
	jr nz, DocMed_RemoveFromOrder
	ldmi16 (xhl), 0x8920
	incdi8 1, 35104
	jr DocMed_RefreshAfterSelect

DocMed_RemoveFromOrder:
	cp c, 0xFD
	jr ugt, DocMed_RefreshAfterSelect
	ld (xhl), 0xFF
	ldda8 a, 35104
	dec 1, a
	stda8 35104, a
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
	cp a, 0xFD
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
	ldda32 xwa, 34036
	ldda16 xbc, 34044

DocMed_CallFormatSlots:
	calr DocMed_FormatSlotList
	jrl DocMed_Exit

DocMed_HandleRepeat:
	cp xhl, 0xC
	jr nz, DocMed_HandlePlay
	cp xde, 0x1C00017
	jr nz, DocMed_SetRepeatOff
	stdi8 35108, 1
	jrl DocMed_Exit

DocMed_SetRepeatOff:
	stdi8 35108, 0
	jrl DocMed_Exit

DocMed_HandlePlay:
	cp xhl, 0xD
	jrl nz, DocMed_Exit
	cpdi8 34046, 0
	jrl nz, DocMed_Exit
	stdi8 35106, 0
	lds hl, 0
	ldda16 xwa, 34044
	cps wa, 0
	jr ule, DocMed_CheckAutoPlay
	ldada xbc, 34976

DocMed_PlayFindLoop:
	ld de, hl
	extz xde
	add xde, xbc
	cp (xde), 0x0
	jr nz, DocMed_PlayNextLoop
	stdi8 34046, 1
	extz xhl
	ld xwa, xiz
	ld xbc, 0x1E50002
	ld xde, xhl
	calr FmmDocFileNameFunc
	incdi8 1, 35106
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009A
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0x74
	call 0xF99490
	jr DocMed_CheckAutoPlay

DocMed_PlayNextLoop:
	inc 1, hl
	cp hl, wa
	jr c, DocMed_PlayFindLoop

DocMed_CheckAutoPlay:
	cpdi8 34046, 0
	jr nz, DocMed_Exit
	ld xwa, xiz
	ld xbc, 0x1E50003
	lds32 xde, 0
	calr FmmDocFileNameFunc
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009A
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0x70
	jr DocMed_CallPauseMode

DocMed_StoreDelayFlag:
	stda32 34040, xwa
	jr DocMed_Exit

DocMed_CheckContinue:
	cpdi8 34046, 0
	jr z, DocMed_Exit
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009A
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0x74

DocMed_CallPauseMode:
	call 0xF99490

DocMed_Exit:
	lds32 xhl, 0
	pop xiz
	ret

LABEL_F94193:
SetSongSlotValue:
	cp wa, 0xA
	ret nc
	lda_24 xhl, 0x0ab000
	ld de, wa
	sll de, 11
	extz xde
	add xhl, xde
	add xhl, 0x1C
	ld (xhl), bc
	ld8_24 e, 0x00ffe3
	extz de
	cp de, wa
	ret nz
	lda_24 xhl, 0x00f180
	add xhl, 0x1C
	ld (xhl), bc
	ret

LABEL_F941C8:
GetSongSlotValue:
	lds hl, 0
	cp wa, 0xA
	ret nc
	lda_24 xbc, 0x0ab000
	sll wa, 11
	extz xwa
	add xbc, xwa
	add xbc, 0x1C
	ld hl, (xbc)
	ret

LABEL_F941E5:
CheckSongSlotHasData:
	calr GetSongSlotValue
	cps hl, 0
	scc16 nz, hl
	ret

LABEL_F941ED:
SongSlot_RawData:
	.byte 0x2e, 0xd9, 0x8e, 0x1e, 0xd5, 0xff, 0xde, 0xf3
	.byte 0xdb, 0x76, 0x4e, 0x0e

LABEL_F941F9:
FindFirstEmptySlot:
	pushw iz
	lds iz, 0

FindEmpty_Loop:
	ld wa, iz
	calr GetSongSlotValue
	cps hl, 0
	jr nz, FindEmpty_Exit
	inc 1, iz
	cp iz, 0xA
	jr c, FindEmpty_Loop

FindEmpty_Exit:
	popw iz
	ret

LABEL_F9420F:
ClearAllSongSlots:
	push xiz
	ld iz, wa
	ldi_werp 0xFA, 0

ClearSlots_Loop:
	ldto_werp WA, 0xFA
	ld bc, iz
	calr SetSongSlotValue
	inc1_werp 0xFA
	cp_erpw 0xFA, 0x0A, 0x00
	jr c, ClearSlots_Loop
	pop xiz
	ret

LABEL_F94229:
ResetSlotsIfEmpty:
	calr FindFirstEmptySlot
	ld wa, hl
	cps wa, 0
	ret z
	calr ClearAllSongSlots
	ret

LABEL_F94236:
CheckSlotIsSelected:
	pushw iz
	ld iz, wa
	calr FindFirstEmptySlot
	cp hl, iz
	scc16 z, hl
	popw iz
	ret

LABEL_F94242:
CheckAnySlotHasData:
	calr FindFirstEmptySlot
	cps hl, 0
	scc16 nz, hl
	ret

LABEL_F9424A:
SetCurrentSlotIndex:
	st16_24 0x09480e, xwa
	ret

LABEL_F94250:
GetCurrentSlotIndex:
	ld16_24 xhl, 0x09480e
	ret

LABEL_F94256:
CheckIsCurrentSlot:
	pushw iz
	ld iz, wa
	calr GetCurrentSlotIndex
	cp hl, iz
	scc16 z, hl
	popw iz
	ret

LABEL_F94262:
CheckSlotIndexValid:
	calr GetCurrentSlotIndex
	cps hl, 0
	scc16 nz, hl
	ret

InitializeCheap:
	lda xsp, (xsp - 14)

	RegObjTable 0x1600004, 0xFA44E2, 0xEA1186, 0xEA0F46, 0x165
	RegObjTable 0x160000c, 0xFA58FB, 0xEA11F2, 0xEA1188, 0x1c5
	RegObjTable 0x160000d, 0xFA5948, 0xEA1358, 0xEA11F4, 0x1e5
	RegObjTabl 0x1600002, 0xFA496C, 0x1d, 0xEA0A56, 0x125
	RegObjTabl 0x1600002, 0xFA496C, 0x1d, 0xEA0ACE, 0x425
	RegObjTabl 0x1600001, 0xFA48A9, 0xd, 0xEA135A, 0x105
	RegObjTabl 0x1600001, 0xFA48A9, 0xd, 0xEA1392, 0x405
	RegObjTabl 0x1600003, 0xFA4A18, 0x39, 0xEA7FCE, 0x145
	RegObjTabl 0x1600003, 0xFA4A18, 0x39, 0xEA80B6, 0x445
	RegObjTabl 0x1600010, 0xFA5995, 0x4a, 0xEA67B6, 0x60
	RegObjTabl 0x160000f, 0xFA62CB, 0x4a, 0xEA6FE2, 0x360
	RegObjTabl 0x1600010, 0xFA5995, 0x80, 0xEA68E2, 0x61
	RegObjTabl 0x160000f, 0xFA62CB, 0x80, 0xEA7228, 0x361
	RegObjTabl 0x1600010, 0xFA5995, 0x0, 0xEA6AE6, 0x62
	RegObjTabl 0x160000f, 0xFA62CB, 0x0, 0xEA75C6, 0x362
	RegObjTabl 0x1600010, 0xFA5995, 0x0, 0xEA6AEA, 0x63
	RegObjTabl 0x160000f, 0xFA62CB, 0x0, 0xEA75CC, 0x363
	RegObjTabl 0x1600010, 0xFA5995, 0x0, 0xEA6AEE, 0x64
	RegObjTabl 0x160000f, 0xFA62CB, 0x0, 0xEA75D2, 0x364
	RegObjTabl 0x1600010, 0xFA5995, 0x3, 0xEA6AF2, 0x65
	RegObjTabl 0x160000f, 0xFA62CB, 0x3, 0xEA75D8, 0x365
	RegObjTabl 0x1600010, 0xFA5995, 0x0, 0xEA6B02, 0x66
	RegObjTabl 0x160000f, 0xFA62CB, 0x0, 0xEA75FC, 0x366
	RegObjTabl 0x1600010, 0xFA5995, 0x47, 0xEA6B06, 0x67
	RegObjTabl 0x160000f, 0xFA62CB, 0x47, 0xEA7602, 0x367
	RegObjTabl 0x1600010, 0xFA5995, 0x0, 0xEA6C26, 0x6a
	RegObjTabl 0x160000f, 0xFA62CB, 0x0, 0xEA77E4, 0x36a
	RegObjTabl 0x1600010, 0xFA5995, 0x15, 0xEA6C2A, 0x6b
	RegObjTabl 0x160000f, 0xFA62CB, 0x15, 0xEA77EA, 0x36b
	RegObjTabl 0x1600010, 0xFA5995, 0x53, 0xEA6C82, 0x6c
	RegObjTabl 0x160000f, 0xFA62CB, 0x53, 0xEA7878, 0x36c
	RegObjTabl 0x1600010, 0xFA5995, 0x0, 0xEA6DD2, 0x6d
	RegObjTabl 0x160000f, 0xFA62CB, 0x0, 0xEA7ACA, 0x36d
	RegObjTabl 0x1600010, 0xFA5995, 0x0, 0xEA6DD6, 0x6e
	RegObjTabl 0x160000f, 0xFA62CB, 0x0, 0xEA7AD0, 0x36e
	RegObjTabl 0x1600010, 0xFA5995, 0x15, 0xEA6DDA, 0x77
	RegObjTabl 0x160000f, 0xFA62CB, 0x15, 0xEA7AD6, 0x377
	RegObjTabl 0x1600010, 0xFA5995, 0x0, 0xEA6E32, 0x79
	RegObjTabl 0x160000f, 0xFA62CB, 0x0, 0xEA7B8C, 0x379
	RegObjTabl 0x1600010, 0xFA5995, 0x5e, 0xEA6E36, 0x7b
	RegObjTabl 0x160000f, 0xFA62CB, 0x5e, 0xEA7B92, 0x37b
	RegObjTabl 0x1600010, 0xFA5995, 0x0, 0xEA6FB2, 0x7c
	RegObjTabl 0x160000f, 0xFA62CB, 0x0, 0xEA7E98, 0x37c
	RegObjTabl 0x1600010, 0xFA5995, 0x0, 0xEA6FB6, 0x7d
	RegObjTabl 0x160000f, 0xFA62CB, 0x0, 0xEA7E9E, 0x37d
	RegObjTabl 0x1600010, 0xFA5995, 0x8, 0xEA6FBA, 0x7e
	RegObjTabl 0x160000f, 0xFA62CB, 0x8, 0xEA7EA4, 0x37e
	RegObjTabl 0x1600010, 0xFA5995, 0x0, 0xEA6FDE, 0xbc
	RegObjTabl 0x160000f, 0xFA62CB, 0x0, 0xEA7EE2, 0x3bc

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
	cp xbc, 0x1E0009F
	jr nz, PasswordText_Exit
	lda_24 xhl, 0xea85c8
	ret

PasswordText_Exit:
	lds32 xhl, 0
	ret

CheckPasswordText:
	cp xbc, 0x1E0009F
	jr nz, CheckPwd_Exit
	ld8_24 a, 0x02748e
	cps a, 2
	jr z, CheckPwd_Type2
	cps a, 1
	jr nz, CheckPwd_Type0
	ld xhl, 0xEA8832
	jr CheckPwd_Return

CheckPwd_Type2:
	ld xhl, 0xEA8A0C
	jr CheckPwd_Return

CheckPwd_Type0:
	ld xhl, 0xEA868E

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
	cp xbc, 0x1C50004
	jrl z, WakeUp_StoreType
	cp xbc, 0x1C00007
	jr z, WakeUp_HandleOk
	cp xbc, 0x1C00001
	jr z, WakeUp_HandleInit
	cp xbc, 0x1C0000D
	jr z, WakeUp_HandleDirect
	cp xbc, 0x1E00085
	jr z, WakeUp_Return1
	ld xwa, xiz
	ld xde, (xsp + 4)
	call 0xFA4409
	jrl WakeUp_Exit

WakeUp_Return1:
	lds32 xhl, 1
	jrl WakeUp_Exit

WakeUp_HandleDirect:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call 0xFA4409
	ld xwa, xiz
	ld xbc, 0x1C0000F
	ld xde, 0xEA8BF0
	call 0xFA9660
	jrl WakeUp_ReturnZero

WakeUp_HandleInit:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call 0xFA4409
	sti8_24 0x02741a, 0x00
	jrl WakeUp_ReturnZero

WakeUp_HandleOk:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call 0xFA4409
	ld xwa, 0x670001
	ld xbc, 0x1E00056
	lds32 xde, 0
	call 0xFA9660
	cp xhl, 0x3
	jr z, WakeUp_ReturnZero
	ld xwa, (xsp + 4)
	cp xwa, 0x8C
	jr nz, WakeUp_ClearCounter
	incdi8_24 1, 160794
	cpi8_24 0x02741a, 0x07
	jr nz, WakeUp_ReturnZero
	sti8_24 0x02741a, 0x00
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C50000
	lds32 xde, 1
	call LABEL_FA9752
	ld xwa, 0x600040
	ld xbc, 0x1C00001
	lds32 xde, 0
	jr WakeUp_PostEvent

WakeUp_ClearCounter:
	sti8_24 0x02741a, 0x00
	jr WakeUp_ReturnZero

WakeUp_StoreType:
	ld xwa, (xsp + 4)
	st8_24 0x02748e, a
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C50000
	lds32 xde, 1
	call LABEL_FA9752
	ld xwa, 0x600045
	ld xbc, 0x1C00001
	lds32 xde, 0

WakeUp_PostEvent:
	call LABEL_FA9752

WakeUp_ReturnZero:
	lds32 xhl, 0

WakeUp_Exit:
	pop xiz
	inc 4, xsp
	ret

PasswordOk:
	push xiz
	ld xiz, xwa
	cp xbc, 0x1C00007
	jr z, PwdOk_HandleConfirm
	cp xbc, 0x1E0007C
	jr z, PwdOk_Return2
	cp xbc, 0x1E00084
	jr z, PwdOk_ReturnZero
	cp xbc, 0x1E0003A
	jr nz, PwdOk_ReturnZero
	pushw 0xEA
	pushw 0x8BF6
	push xde
	call LABEL_FF0F4D
	inc 8, xsp
	ld xhl, xiz
	jr PwdOk_Exit

PwdOk_Return2:
	lds32 xhl, 2
	jr PwdOk_Exit

PwdOk_HandleConfirm:
	call 0xFA1FC7
	ld xwa, xhl
	ld xbc, 0x1E0003A
	ld xde, 0x2741C
	call 0xFA9660
	ld xwa, 0x600040
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9660
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C50000
	lds32 xde, 0
	call LABEL_FA9752
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	call LABEL_FA9752
	ld16_24 xde, 0x02741c
	extz xde
	ld xwa, 0x1450038
	ld xbc, 0x1E5000D
	call 0xFA4A63

PwdOk_ReturnZero:
	lds32 xhl, 0

PwdOk_Exit:
	pop xiz
	ret

CheckPasswordOk:
	push xiz
	ld xiz, xwa
	cp xbc, 0x1C00007
	jr z, CheckOk_HandleConfirm
	cp xbc, 0x1E0007C
	jr z, CheckOk_Return2
	cp xbc, 0x1E00084
	jrl z, CheckOk_ReturnZero
	cp xbc, 0x1E0003A
	jrl nz, CheckOk_ReturnZero
	pushw 0xEA
	pushw 0x8BFA
	push xde
	call LABEL_FF0F4D
	inc 8, xsp
	ld xhl, xiz
	jrl CheckOk_Exit

CheckOk_Return2:
	lds32 xhl, 2
	jrl CheckOk_Exit

CheckOk_HandleConfirm:
	call 0xFA1FC7
	ld xwa, xhl
	ld xbc, 0x1E0003A
	ld xde, 0x27424
	call 0xFA9660
	ld xwa, 0x600045
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9660
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C50000
	lds32 xde, 0
	call LABEL_FA9752
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	call LABEL_FA9752
	ld xwa, 0x670001
	ld xbc, 0x1E00056
	lds32 xde, 0
	call 0xFA9660
	lda_24 xwa, 0x027424
	cps hl, 1
	jr nz, CheckOk_Type2
	ld de, (xwa)
	extz xde
	ld xwa, 0x1450038
	ld xbc, 0x1E5000E
	jr CheckOk_CallFunc

CheckOk_Type2:
	cps hl, 2
	jr nz, CheckOk_Type3
	ld de, (xwa)
	extz xde
	ld xwa, 0x1450038
	ld xbc, 0x1E5000F
	jr CheckOk_CallFunc

CheckOk_Type3:
	cps hl, 3
	jr nz, CheckOk_ReturnZero
	ld de, (xwa)
	extz xde
	ld xwa, 0x1450038
	ld xbc, 0x1E50010

CheckOk_CallFunc:
	call 0xFA4A63

CheckOk_ReturnZero:
	lds32 xhl, 0

CheckOk_Exit:
	pop xiz
	ret

PasswordNo:
	cp xbc, 0x1C00007
	jr nz, PwdNo_Exit
	ld xwa, 0x600040
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9660
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C50000
	lds32 xde, 0
	call LABEL_FA9752
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	call LABEL_FA9752

PwdNo_Exit:
	lds32 xhl, 0
	ret

CheckPasswordNo:
	cp xbc, 0x1C00007
	jr nz, CheckNo_HandleConfirm
	ld xwa, 0x600045
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9660
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C50000
	lds32 xde, 0
	call LABEL_FA9752
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	call LABEL_FA9752

CheckNo_HandleConfirm:
	lds32 xhl, 0
	ret

DiskAttention:
	cp xbc, 0x1E0009F
	jr nz, CheckNo_Type1
	lda_24 xhl, 0xea8bfe
	ret

CheckNo_Type1:
	lds32 xhl, 0
	ret

DiskSure:
	cp xbc, 0x1E0009F
	jr nz, CheckNo_Type2
	lda_24 xhl, 0xea8c5c
	ret

CheckNo_Type2:
	lds32 xhl, 0
	ret

FormatText:
	cp xbc, 0x1E0009F
	jr nz, CheckNo_Type3
	lda_24 xhl, 0xea8cdc
	ret

CheckNo_Type3:
	lds32 xhl, 0
	ret

DeleteText:
	cp xbc, 0x1E0009F
	jr nz, CheckNo_CallFunc
	lda_24 xhl, 0xea8e70
	ret

CheckNo_CallFunc:
	lds32 xhl, 0
	ret

DeleteYes:
	cp xbc, 0x1C00007
	jr nz, PwdChange_HandleOk
	ld xwa, 0x7B0051
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9660
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C50000
	lds32 xde, 0
	call LABEL_FA9752
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	call LABEL_FA9752
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00017
	ld xde, 0x33
	call LABEL_FA9752

PwdChange_HandleOk:
	lds32 xhl, 0
	ret

DeleteNo:
	cp xbc, 0x1C00007
	jr nz, PwdChange_Type1
	ld xwa, 0x7B0051
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9660
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C50000
	lds32 xde, 0
	call LABEL_FA9752
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	call LABEL_FA9752

PwdChange_Type1:
	lds32 xhl, 0
	ret

SaveText:
	cp xbc, 0x1E0009F
	jr nz, PwdChange_CallFunc
	lda_24 xhl, 0xea912a
	ret

PwdChange_CallFunc:
	lds32 xhl, 0
	ret

SaveYes:
	cp xbc, 0x1C00007
	jr nz, PwdDel_HandleOk
	ld xwa, 0x600037
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9660
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C50000
	lds32 xde, 0
	call LABEL_FA9752
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	call LABEL_FA9752
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00017
	ld xde, 0x32
	call LABEL_FA9752

PwdDel_HandleOk:
	lds32 xhl, 0
	ret

SaveNo:
	cp xbc, 0x1C00007
	jr nz, PwdDel_Type1
	ld xwa, 0x600037
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9660
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C50000
	lds32 xde, 0
	call LABEL_FA9752
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	call LABEL_FA9752

PwdDel_Type1:
	lds32 xhl, 0
	ret

InsertOptionText:
	cp xbc, 0x1E0009F
	jr nz, PwdDel_Type2
	lda_24 xhl, 0xea943c
	ret

PwdDel_Type2:
	lds32 xhl, 0
	ret

TypePriorityText:
	cp xbc, 0x1E0009F
	jr nz, PwdDel_CallFunc
	lda_24 xhl, 0xea9558
	ret

PwdDel_CallFunc:
	lds32 xhl, 0
	ret

