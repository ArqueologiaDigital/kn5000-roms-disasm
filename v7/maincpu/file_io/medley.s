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
	cp XBC,EVT_GET_SELECTED_FILE_NUMBER
	jrl z, SeqName_GetIndexReturn
	ld hl, (0x823c:16)
	cp XBC,EVT_SET_SELECTED_FILE_NUMBER
	jrl z, SeqName_SetIndexPlaying
	cp XBC,EVT_INDEXSW_DOWN
	jr z, SeqName_HandleNavigation
	cp XBC,EVT_INDEXSW_UP
	jr z, SeqName_HandleNavigation
	cp XBC,EVT_PAINT
	jr z, SeqName_InitAllSlots
	cp XBC,EVT_PS_FILE_NAME_BOX_ID
	jr nz, SeqName_ReturnZero
	ld (0x8238:16), xde
	cp (0x8462:16), 0x00
	jr nz, SeqName_SendCurrentIndex
	ldw (0x823c:16), 0x0000
SeqName_SendCurrentIndex:
	ld	de, (33340:16)
	extz	xde
	ld	xwa, (33336:16)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	jrl	SeqName_PostEventExit
SeqName_InitAllSlots:
	ld iz, 0:i3

SeqName_SendSlotLoop:
	ld	bc, iz
	ld	wa, bc
	ld	de, 1:i3
	calr	BuildSlotLabel
	ld	xde, xhl
	ld	xwa, (33336:16)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	inc	1, iz
	cp	iz, 10
	jr	lt, SeqName_SendSlotLoop
SeqName_ReturnZero:
	ld xhl, 0:i3
	jrl SeqName_Exit

SeqName_HandleNavigation:
	ld	wa, hl
	ld	iz, hl
	or	xde, xde
	jr	nz, SeqName_HandlePlayAction
	cp	(33890:16), 0
	jr	nz, SeqName_HandlePlayAction
	cp	xbc, EVT_INDEXSW_DOWN
	jr	nz, SeqName_CheckPrevKey
	cp	wa, 9
	jrl	nc, SeqName_GetCurrentIndex
	inc	1, wa
	jr	SeqName_UpdateIndex
SeqName_CheckPrevKey:
	cp xbc, EVT_INDEXSW_UP
	jrl nz, SeqName_GetCurrentIndex
	cp wa, 0:i3
	jrl z, SeqName_GetCurrentIndex
	dec 1, wa

SeqName_UpdateIndex:
	ld	(33340:16), wa
	ld	de, wa
	jrl	SeqName_UpdateDisplay
SeqName_HandlePlayAction:
	cp	xde, 0x4
	jrl	nz, SeqName_HandleAction32
	cp	(0x8462:16), 0
	jrl	nz, SeqName_HandleAction32
	call	CheckSongSlotHasData
	cp	l, 0:i3
	jr	z, SeqName_CheckDiskAvail
	lda	xwa, (0x8970:16)
	bitm	7, (xwa + 1)
	jr	nz, SeqName_CheckDiskAvail
	ld	(xwa), 0x1
	ld	xde, 1:i3
	ld	xwa, 0xffffffff
	ld	xbc, EVT_WAKEUP_PASSWORD
	jr	SeqName_PostAndExit
SeqName_CheckDiskAvail:
	call CheckFileSystemStatus
	cp hl, 0:i3
	jr z, SeqName_LoadAndPlay
	cp (0x0340ea:24), 0x00
	jr z, SeqName_LoadAndPlay
	ld xwa, 0xffffffff
	ld xbc, EVT_NOT_PARA_DRAW
	ld xde, 1:i3
	call ApPostEvent
	ld xwa, 0x600037
	ld xbc, EVT_SHOW
	ld xde, 0:i3

SeqName_PostAndExit:
	call ApPostEvent
	jrl SeqName_GetCurrentIndex

SeqName_LoadAndPlay:
	ld	xwa, 6291494
	ld	xbc, EVT_SHOW
	ld	xde, 5:i3
	call	ApPostEvent
	ld	wa, 0:i3
	calr	InitializeOperationState
	ld	wa, (33340:16)
	call	LoadFileMultiPass
	ld	wa, hl
	ld	bc, 5:i3
	calr	FileIO_ValidateSignedValue
	ld	(32422:16), l
	call	FileIO_ResetCurrentRecord
	call	GetEncodedFreeSpaceData
	call	GetEncodedFileSizeData
	ld	(33894:16), hl
	calr	SignalProgressUpdate
	ld	xwa, 6291494
	ld	xbc, EVT_HIDE
	ld	xde, 0:i3
	call	ApPostEvent
	ldw	wa, 238
	jr	SeqName_ShowAndExit
SeqName_HandleAction32:
	cp	xde, 50
	jr	nz, SeqName_GetCurrentIndex
	ld	xwa, 6291494
	ld	xbc, EVT_SHOW
	ld	xde, 5:i3
	call	ApPostEvent
	ld	wa, 0:i3
	calr	InitializeOperationState
	ld	wa, (33340:16)
	call	LoadFileMultiPass
	ld	wa, hl
	ld	bc, 5:i3
	calr	FileIO_ValidateSignedValue
	ld	(32422:16), l
	call	FileIO_ResetCurrentRecord
	call	GetEncodedFreeSpaceData
	call	GetEncodedFileSizeData
	ld	(33894:16), hl
	calr	SignalProgressUpdate
	ld	xwa, 6291494
	ld	xbc, EVT_HIDE
	ld	xde, 0:i3
	call	ApPostEvent
	ldw	wa, 238
SeqName_ShowAndExit:
	call SoundCtrl_SendCommand

SeqName_GetCurrentIndex:
	ld	de, (33340:16)
SeqName_UpdateDisplay:
	cp	iz, de
	jrl	z, SeqName_ReturnZero
	extz	xde
	ld	xwa, (33336:16)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	call	ApPostEvent
	ld	wa, iz
	ld	bc, iz
	ld	de, 1:i3
	calr	BuildSlotLabel
	ld	xde, xhl
	ld	xwa, (33336:16)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	ld	bc, (33340:16)
	ld	wa, bc
	ld	de, 1:i3
	calr	BuildSlotLabel
	ld	xde, xhl
	ld	xwa, (33336:16)
	ld	xbc, EVT_PARA_DRAW
	jr	SeqName_PostEventExit
SeqName_SetIndexPlaying:
	cp (0x8462:16), 0x00
	jrl z, SeqName_ReturnZero
	ld IZ,HL
	ld (0x823c:16), de
	extz XDE
	ld xwa, (0x8238:16)
	ld XBC,EVT_SET_SELECTED_FILE_NUMBER
	call ApPostEvent
	ld WA,IZ
	ld BC,IZ
	ld de, 1:i3
	calr BuildSlotLabel
	ld XDE,XHL
	ld xwa, (0x8238:16)
	ld XBC,EVT_PARA_DRAW
	call ApPostEvent
	ld bc, (0x823c:16)
	ld WA,BC
	ld de, 1:i3
	calr BuildSlotLabel
	ld XDE,XHL
	ld xwa, (0x8238:16)
	ld XBC,EVT_PARA_DRAW
SeqName_PostEventExit:
	call ApPostEvent
	jrl SeqName_ReturnZero

SeqName_GetIndexReturn:
	ld	hl, (33340:16)
	extz	xhl
SeqName_Exit:
	popw iz
	ret

FormatMedleyNumber:
	ld (xwa+), e
	cp c, 0xff
	jr nz, FmtNum_CheckMarked
	ld c, 0x20:opc
	jr FmtNum_WriteSpacePad

FmtNum_CheckMarked:
	cp c, 0xfe
	jr nz, FmtNum_FormatNumber
	ld c, 0x4d:opc

FmtNum_WriteSpacePad:
	ld (xwa+), c
	ld (xwa+), 0x20
	ld (xwa), 0x20
	ret

FmtNum_FormatNumber:
	inc 1, c
	cp c, 0x64
	jr c, FmtNum_WriteM
	lda xhl, (xwa+:1)
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
	ld (xwa+), 0x4d

FmtNum_WriteTensUnits:
	cp c, 0xa
	jr nc, FmtNum_WriteTwoDigits
	ld (xwa+), 0x30
	add c, 0x30
	ld (xwa), c
	ret

FmtNum_WriteTwoDigits:
	lda xhl, (xwa+:1)
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
	dec 8,XSP
	pushw iz
	ld (XSP+0x06),XWA
	cp XBC,EVT_WAKE_UP_NOW
	jrl z, IntMed_CheckContinue
	ld XWA,XDE
	cp XBC,EVT_I_WILL_WAKE_UP
	jrl z, IntMed_StoreDelayFlag
	cp XBC,EVT_INDEXSW_DOWN
	jrl z, IntMed_HandleNavToggle
	cp XBC,EVT_INDEXSW_UP
	jrl z, IntMed_HandleNavToggle
	cp XBC,EVT_PAINT
	jrl z, IntMed_InitSlotDisplay
	cp XBC,EVT_PS_FILE_NAME_BOX_ID
	jrl z, IntMed_StoreWindowPtr
	cp XBC,EVT_ACTIVATE_STATE
	jrl nz, IntMed_Exit
	cp XDE,0x00000003
	jrl z, IntMed_HandleStop
	cp XDE,0x00000002
	jrl nz, IntMed_Exit
	cp (0x8c9b:16), 0x7a
	jr z, IntMed_CheckPlaying
	call CDlike_InitModeAndLoadBank
	ld (0x8462:16), 0x00
	ld (0x8800:16), 0x00
	ld (0x87fe:16), 0x00
	ld iz, 0:i3
IntMed_CheckSlotLoop:
	ld_erpb_rr a, 0xf8
	extz WA
	call SongBank_ScanActiveVoices
	cp l, 0:i3
	jr z, IntMed_MarkSlotEmpty
	lda xwa, (0x87f4:16)
	ld BC,IZ
	extz XBC
	add XBC,XWA
	ldmi16	(xbc), 0x87fe
	inc	1, (0x87fe:16)
	jr	IntMed_NextSlot
IntMed_MarkSlotEmpty:
	lda	xwa, (34804:16)
	ld	bc, iz
	extz	xbc
	add	xbc, xwa
	ld	(xbc), 255
IntMed_NextSlot:
	inc	1, iz
	cp	iz, 10
	jr	c, IntMed_CheckSlotLoop
	ld	xwa, 0:i3
	ld	(33346:16), xwa
	jrl	IntMed_Exit
IntMed_CheckPlaying:
	call	Medley_GetPlaybackStatus
	cp	l, 1:i3
	jrl	nz, IntMed_HandleError
	ld	(33890:16), 1
	ld	a, (34816:16)
	cp	a, (34814:16)
	jr	nc, IntMed_CheckRepeat
	ld	iz, 0:i3
	lda	xbc, (34804:16)
IntMed_FindCurrentSong:
	ld	de, iz
	extz	xde
	add	xde, xbc
	cp	(xde), a
	jr	nz, IntMed_NextSongSearch
	ld	de, iz
	extz	xde
	ld	xwa, (xsp+6)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	calr	FmmSeqSongNameFunc
	ldto_berp	a, 248
	extz	wa
	call	SongBank_SwitchAndUpdateTempo
	inc	1, (34816:16)
	ld	xwa, (33346:16)
	or	xwa, xwa
	jrl	z, IntMed_Exit
	ld	xbc, EVT_WAKE_UP_TIME
	ld	xde, 30
	jr	IntMed_PostDelayEvent
IntMed_NextSongSearch:
	inc 1, iz
	cp iz, 0xa
	jr c, IntMed_FindCurrentSong
	jrl IntMed_Exit
IntMed_CheckRepeat:
	cp	(34818:16), 0
	jr	z, IntMed_ClearPlayFlag
	ld	(34816:16), 0
	ld	iz, 0:i3
	lda	xwa, (34804:16)
IntMed_PlayFromStart:
	ld	bc, iz
	extz	xbc
	add	xbc, xwa
	cp	(xbc), 0
	jr	nz, IntMed_NextSongLoop
	ld	de, iz
	extz	xde
	ld	xwa, (xsp+6)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	calr	FmmSeqSongNameFunc
	ldto_berp	a, 248
	extz	wa
	call	SongBank_SwitchAndUpdateTempo
	inc	1, (34816:16)
	ld	xwa, (33346:16)
	or	xwa, xwa
	jrl	z, IntMed_Exit
	ld	xbc, EVT_WAKE_UP_TIME
	ld	xde, 30
IntMed_PostDelayEvent:
	call ApPostEvent
	jrl IntMed_Exit

IntMed_NextSongLoop:
	inc 1, iz
	cp iz, 0xa
	jr c, IntMed_PlayFromStart
	jrl IntMed_Exit

IntMed_ClearPlayFlag:
	ld	(33890:16), 0
	jrl	IntMed_Exit
IntMed_HandleError:
	call	Medley_GetPlaybackStatus
	ld	(33890:16), 0
	cp	l, 0:i3
	jrl	z, IntMed_Exit
	ld	(32422:16), 14
	ldw	wa, 238
	call	SoundCtrl_SendCommand
	jrl	IntMed_Exit
IntMed_HandleStop:
	cp (0x8c9a:16), 0x7a
	jrl z, IntMed_Exit
	call CDlike_ExitModeAndRestore
	ld (0x8462:16), 0x00
	jrl t, IntMed_Exit



IntMed_StoreWindowPtr:
	ld	(33342:16), xwa
	jrl	IntMed_Exit
IntMed_InitSlotDisplay:
	ld iz, 0:i3

IntMed_FormatSlotLoop:
	ld	wa, iz
	sll	wa, 3
	lda	xbc, (33350:16)
	extz	xwa
	add	xwa, xbc
	lda	xbc, (34804:16)
	ld	de, iz
	extz	xde
	add	xde, xbc
	ld	c, (xde)
	extz	bc
	ld	de, iz
	calr	FormatMedleyNumber
	ld	de, iz
	sll	de, 3
	lda	xwa, (33350:16)
	extz	xde
	add	xde, xwa
	ld	xwa, (33342:16)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	inc	1, iz
	cp	iz, 10
	jr	c, IntMed_FormatSlotLoop
	jrl	IntMed_Exit
IntMed_HandleNavToggle:
	lda xwa, (0x87f4:16)
	cp XDE,0x0000000a
	jrl nz, IntMed_HandleSelectToggle
	cp (0x8462:16), 0x00
	jrl nz, IntMed_HandleSelectToggle
	ld iz, 0:i3
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
	ld iz, 0:i3

IntMed_AssignOrderLoop:
	lda	xwa, (34804:16)
	ld	bc, iz
	extz	xbc
	add	xbc, xwa
	ld	a, (xbc)
	cp	a, 254
	jr	nz, IntMed_NextAssignSlot
	ld	a, (34814:16)
	ld	(xbc), a
	inc	1, (34814:16)
	ld	wa, iz
	sll	wa, 3
	lda	xde, (33350:16)
	extz	xwa
	add	xwa, xde
	ld	c, (xbc)
	extz	bc
	ld	de, iz
	calr	FormatMedleyNumber
	ld	de, iz
	sll	de, 3
	lda	xwa, (33350:16)
	extz	xde
	add	xde, xwa
	ld	xwa, (33342:16)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
IntMed_NextAssignSlot:
	inc 1, iz
	cp iz, 0xa
	jr c, IntMed_AssignOrderLoop
	jrl IntMed_Exit

IntMed_RemoveOrderLoop:
	ld iz, 0:i3

IntMed_UnmarkSlotLoop:
	lda	xwa, (34804:16)
	ld	bc, iz
	extz	xbc
	add	xbc, xwa
	ld	a, (xbc)
	cp	a, 253
	jr	ugt, IntMed_NextUnmark
	ld	(xbc), 254
	dec	1, (34814:16)
	ld	wa, iz
	sll	wa, 3
	lda	xde, (33350:16)
	extz	xwa
	add	xwa, xde
	ld	c, (xbc)
	extz	bc
	ld	de, iz
	calr	FormatMedleyNumber
	ld	de, iz
	sll	de, 3
	lda	xwa, (33350:16)
	extz	xde
	add	xde, xwa
	ld	xwa, (33342:16)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
IntMed_NextUnmark:
	inc 1, iz
	cp iz, 0xa
	jr c, IntMed_UnmarkSlotLoop
	jrl IntMed_Exit

IntMed_HandleSelectToggle:
	cp XDE,0x0000000b
	jrl nz, IntMed_HandleRepeatToggle
	cp (0x8462:16), 0x00
	jrl nz, IntMed_HandleRepeatToggle
	ld XWA,(XSP+0x06)
	ld XBC,EVT_GET_SELECTED_FILE_NUMBER
	ld xde, 0:i3
	calr FmmSeqSongNameFunc
	ld IZ,HL
	lda xwa, (0x87f4:16)
	ld DE,IZ
	extz XDE
	add XDE,XWA
	lda xbc, (0x8246:16)
	ld WA,IZ
	sll WA, 0x03
	extz XWA
	add XWA,XBC
	ld C,(XDE)
	cp C,0xfe
	jr nz, .Lc_f91c70
	ld c, (0x87fe:16)
	ld (XDE),C
	inc 1, (0x87fe:16)
	ld C,(XDE)
	extz BC
	ld DE,IZ
	calr FormatMedleyNumber
	ld DE,IZ
	sll DE, 0x03
	lda xbc, (0x8246:16)
	extz XDE
	add XDE,XBC
	ld xwa, (0x823e:16)
	ld XBC,EVT_PARA_DRAW
	call ApPostEvent
	jrl t, IntMed_Exit
IntMed_RemoveFromOrder:
.Lc_f91c70:
	cp C,0xfd
	jrl ugt, IntMed_Exit
	ld (XSP+0x04),C
	ld (XDE),0xfe
	dec 1, (0x87fe:16)
	ld C,(XDE)
	extz BC
	ld DE,IZ
	calr FormatMedleyNumber
	ld DE,IZ
	sll DE, 0x03
	lda xbc, (0x8246:16)
	extz XDE
	add XDE,XBC
	ld xwa, (0x823e:16)
	ld XBC,EVT_PARA_DRAW
	call ApPostEvent
	ldw (XSP+0x02), 0x0000
	ld iz, 0:i3
	ld a, (0x87fe:16)
	extz WA
	cp wa, 0:i3
	jrl ule, IntMed_Exit
IntMed_ReorderLoop:
	lda xwa, (0x87f4:16)
	ld DE,IZ
	extz XDE
	add XDE,XWA
	ld C,(XDE)
	cp C,0xfd
	jr ugt, IntMed_NextReorder
	incw	1, (xsp + 2)
	cp	c, (xsp + 4)
	jr	ule, IntMed_NextReorder
	dec	1, c
	ld	(xde), c
	ld	wa, iz
	sll	wa, 3
	lda	xde, (0x8246:16)
	extz	xwa
	add	xwa, xde
	extz	bc
	ld	de, iz
	calr	FormatMedleyNumber
	ld	de, iz
	sll	de, 3
	lda	xwa, (0x8246:16)
	extz	xde
	add	xde, xwa
	ld	xwa, (0x823e:16)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
IntMed_NextReorder:
	inc	1, iz
	ld	a, (34814:16)
	extz	wa
	cp	(xsp+2), wa
	jr	c, IntMed_ReorderLoop
	jrl	IntMed_Exit
IntMed_HandleRepeatToggle:
	cp	xde, 12
	jr	nz, IntMed_HandlePlay
	cp	xbc, EVT_INDEXSW_UP
	jr	nz, IntMed_SetRepeatOff
	ld	(34818:16), 1
	jrl	IntMed_Exit
IntMed_SetRepeatOff:
	ld	(34818:16), 0
	jrl	IntMed_Exit
IntMed_HandlePlay:
	cp	xde, 13
	jrl	nz, IntMed_Exit
	cp	(33890:16), 0
	jr	nz, IntMed_Exit
	ld	(34816:16), 0
	ld	iz, 0:i3
IntMed_StartPlayLoop:
	ld	bc, iz
	extz	xbc
	add	xbc, xwa
	cp	(xbc), 0
	jr	nz, IntMed_NextPlaySlot
	ld	(33890:16), 1
	ld	de, iz
	extz	xde
	ld	xwa, (xsp+6)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	calr	FmmSeqSongNameFunc
	ldto_berp	a, 248
	extz	wa
	call	SongBank_SwitchAndUpdateTempo
	inc	1, (34816:16)
	ld	xwa, 4294967295
	ld	xbc, EVT_SET_HOLD
	ld	xde, 0:i3
	call	ApPostEvent
	ldw	wa, 122
	call	UI_PostModeChangeEvent
	jr	IntMed_Exit
IntMed_NextPlaySlot:
	inc 1, iz
	cp iz, 0xa
	jr c, IntMed_StartPlayLoop
	jr IntMed_Exit

IntMed_StoreDelayFlag:
	ld	(33346:16), xwa
	jr	IntMed_Exit
IntMed_CheckContinue:
	cp (0x8462:16), 0x00
	jr z, IntMed_Exit
	ld XWA,0xffffffff
	ld XBC,EVT_SET_HOLD
	ld xde, 0:i3
	call ApPostEvent
	ldw WA, 0x007a
	call UI_PostModeChangeEvent
IntMed_Exit:
	ld xhl, 0:i3
	popw iz
	inc 8, xsp
	ret

FmmDiskMedley1Func:
	pushw	iz
	cp	xbc, EVT_PAINT
	jr	z, DiskMed1_InitLoop
	cp	xbc, EVT_PS_FILE_NAME_BOX_ID
	jr	nz, DiskMed1_Exit
	ld	(33430:16), xde
	jr	DiskMed1_Exit
DiskMed1_InitLoop:
	ld iz, 0:i3

DiskMed1_FormatLoop:
	ld	wa, iz
	sll	wa, 3
	lda	xbc, (33434:16)
	extz	xwa
	add	xwa, xbc
	lda	xbc, (34954:16)
	ld	de, iz
	extz	xde
	add	xde, xbc
	ld	c, (xde)
	extz	bc
	ld	de, iz
	calr	FormatMedleyNumber
	ld	de, iz
	sll	de, 3
	lda	xwa, (33434:16)
	extz	xde
	add	xde, xwa
	ld	xwa, (33430:16)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	inc	1, iz
	cp	iz, 10
	jr	c, DiskMed1_FormatLoop
DiskMed1_Exit:
	ld xhl, 0:i3
	popw iz
	ret

FmmDiskMedley2Func:
	pushw	iz
	cp	xbc, EVT_PAINT
	jr	z, DiskMed2_InitLoop
	cp	xbc, EVT_PS_FILE_NAME_BOX_ID
	jr	nz, DiskMed2_Exit
	ld	(33514:16), xde
	jr	DiskMed2_Exit
DiskMed2_InitLoop:
	ldw iz, 0xa

DiskMed2_FormatLoop:
	ld	wa, iz
	sll	wa, 3
	lda	xbc, (33438:24)
	extz	xwa
	add	xwa, xbc
	lda	xbc, (34954:16)
	ld	de, iz
	extz	xde
	add	xde, xbc
	ld	c, (xde)
	extz	bc
	ld	de, iz
	sub	de, 10
	calr	FormatMedleyNumber
	ld	wa, iz
	sll	wa, 3
	lda	xbc, (33438:24)
	ld	de, wa
	extz	xde
	add	xde, xbc
	ld	xwa, (33514:16)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	inc	1, iz
	cp	iz, 20
	jr	c, DiskMed2_FormatLoop
DiskMed2_Exit:
	ld xhl, 0:i3
	popw iz
	ret

DiskMed_PlayNextHelper:
	pushw iz
	cp XBC,EVT_INDEXSW_DOWN
	jr z, DiskMed_InitPlayOrder
	cp XBC,EVT_INDEXSW_UP
	jr z, DiskMed_InitPlayOrder
	cp XBC,EVT_ACTIVATE_STATE
	jrl nz, DiskMed_ReturnZero
	cp XDE,0x00000003
	jrl z, DiskMed_ReturnZero
	cp XDE,0x00000002
	jrl nz, DiskMed_ReturnZero
	cp (0x8462:16), 0x00
	jrl z, DiskMed_ReturnZero
	ld a, (0x8800:16)
	cp a, (0x87fe:16)
	jr nc, DiskMed_ReturnFinished
	ld iz, 0:i3
	lda xbc, (0x87f4:16)
DiskMed_FindSongLoop:
	ld de, iz
	extz xde
	add xde, xbc
	cp (xde), a
	jr nz, DiskMed_NextSong
	ldto_berp A, 0xf8
	extz wa
	jrl DiskMed_PlaySong

DiskMed_NextSong:
	inc 1, iz
	cp iz, 0xa
	jr c, DiskMed_FindSongLoop
	jrl DiskMed_ReturnZero

DiskMed_ReturnFinished:
	ld xhl, 2:i3
	jrl DiskMed_HelperExit

DiskMed_InitPlayOrder:
	cp	xde, 13
	jrl	nz, DiskMed_ReturnZero
	ld	(34816:16), 0
	ld	(34814:16), 0
	ld	(34818:16), 0
	ld	iz, 0:i3
DiskMed_CheckSlotLoop:
	ldto_berp	a, 248
	extz	wa
	call	SongBank_ScanActiveVoices
	lda	xbc, (34804:16)
	ld	wa, iz
	extz	xwa
	add	xwa, xbc
	cp	l, 0:i3
	jr	z, DiskMed_MarkUnused
	ld	(xwa), 254
	jr	DiskMed_NextSlotCheck
DiskMed_MarkUnused:
	ld (xwa), 0xff

DiskMed_NextSlotCheck:
	inc	1, iz
	cp	iz, 0xa
	jr	c, DiskMed_CheckSlotLoop
	cp	(0x88a4:16), 0
	jr	z, DiskMed_SingleSlotCheck
	lda	xhl, (0x87f4:16)
	ld	xbc, xhl
	lda	xde, (xhl + 10)
DiskMed_AssignOrder:
	ld	a, (xbc)
	cp	a, 0xfe
	jr	nz, DiskMed_NextAssign
	ldmi16	(xbc), 0x87fe
	inc	1, (0x87fe:16)
DiskMed_NextAssign:
	inc 1, xbc
	cp xbc, xde
	jr c, DiskMed_AssignOrder
	ld iz, 0:i3

DiskMed_FindFirstSong:
	ld	wa, iz
	extz	xwa
	add	xwa, xhl
	ld	a, (xwa)
	cp	a, (34816:16)
	jr	nz, DiskMed_NextFirst
	ldto_berp	a, 248
	extz	wa
	jr	DiskMed_PlaySong
DiskMed_NextFirst:
	inc 1, iz
	cp iz, 0xa
	jr c, DiskMed_FindFirstSong
	jr DiskMed_ReturnZero

DiskMed_SingleSlotCheck:
	lda	xbc, (0x87f4:16)
	cp	(xbc), 0xfe
	jr	nz, DiskMed_SingleSlotInit
	ldmi16	(xbc), 0x87fe
	inc	1, (0x87fe:16)
DiskMed_SingleSlotInit:
	ld iz, 0:i3

DiskMed_FindFirstLoop:
	ld	wa, iz
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	cp	a, (34816:16)
	jr	nz, DiskMed_NextFindFirst	; -> 0xF91FA6
	ldto_berp	a, 248
	extz	wa
DiskMed_PlaySong:
	call	SongBank_SwitchAndUpdateTempo
	inc	1, (34816:16)
	ld	xhl, 1:i3
	jr	DiskMed_HelperExit
DiskMed_NextFindFirst:
	inc 1, iz
	cp iz, 0xa
	jr c, DiskMed_FindFirstLoop

DiskMed_ReturnZero:
	ld xhl, 0:i3

DiskMed_HelperExit:
	popw iz
	ret

FmmDiskMedleySelectFunc:
	lda xsp, (xsp - 0x0e)
	push XIZ
	ld (XSP+0x06),XDE
	ld (XSP+0x0a),XBC
	ld (XSP+0x0e),XWA
	ld XWA,(XSP+0x0a)
	cp XWA,EVT_INDEXSW_DOWN
	jrl z, DiskSel_HandleNavigation
	cp XWA,EVT_INDEXSW_UP
	jrl z, DiskSel_HandleNavigation
	cp XWA,EVT_PAINT
	jrl z, DiskSel_InitDisplay
	cp XWA,EVT_PS_FILE_NAME_BOX_ID
	jrl z, DiskSel_StoreWindowPtr
	cp XWA,EVT_ACTIVATE_STATE
	jrl nz, DiskSel_Exit
	ld XWA,(XSP+0x06)
	cp XWA,0x00000003
	jrl z, DiskSel_HandleStopEvent
	cp XWA,0x00000002
	jrl nz, DiskSel_Exit
	ld wa, 0:i3
	calr InitializeOperationState
	cp (0x8c9b:16), 0x78
	jrl z, DiskSel_CheckPlaying
	ld XWA,0xffffffff
	ld XBC,EVT_SET_NOT_DRAW_FLAG
	ld xde, 0:i3
	call ApPostEvent
	ld XWA,0xffffffff
	ld XBC,EVT_ALL_PAINT
	ld xde, 0:i3
	call ApPostEvent
	cpw (0x8466:16), 0x0000
	jr ge, DiskSel_InitState
	ld XWA,0x00600026
	ld XBC,EVT_SHOW
	ld xde, 5:i3
	call ApPostEvent
	call GetEncodedFileSizeData
	ld (0x8466:16), hl
	call FileIO_SearchAndLoadFile
	call GetEncodedFreeSpaceData
	ld XWA,0x00600026
	ld XBC,EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ld XWA,0xffffffff
	ld XBC,EVT_ALL_PAINT
	ld xde, 0:i3
	call ApPostEvent
	calr SignalProgressUpdate
DiskSel_InitState:
	ld	(33890:16), 0
	ld	(34976:16), 0
	ld	(34974:16), 0
	ld	iz, 0:i3
DiskSel_CheckFileLoop:
	ld wa, iz
	ld bc, 2:i3
	call FileIO_CheckRecordByFile
	cp l, 0:i3
	jr nz, DiskSel_FileAvailable
	ld wa, iz
	ldw bc, 0x8
	call FileIO_CheckRecordByFile
	cp l, 0:i3
	jr z, DiskSel_MarkUnavail

DiskSel_FileAvailable:
	lda	xwa, (0x888a:16)
	ldmmb_dri	0x07, 0xe0, 0xf8, 0x9e, 0x88
	inc	1, (0x889e:16)
	jr	DiskSel_NextFile
DiskSel_MarkUnavail:
	lda	xwa, (0x888a:16)
	stib_ind	0x07, 0xe0, 0xf8, 0xff
DiskSel_NextFile:
	inc 1, iz
	cp iz, 0x14
	jr lt, DiskSel_CheckFileLoop
	call CDlike_InitModeAndLoadBank
	jrl DiskSel_Exit

DiskSel_CheckPlaying:
	call	Medley_GetPlaybackStatus
	cp	l, 1:i3
	jrl	nz, DiskSel_HandleError
	ld	(33890:16), 1
	ld	xwa, (xsp+14)
	ld	xbc, (xsp+10)
	ld	xde, (xsp+6)
	calr	DiskMed_PlayNextHelper
	cp	l, 1:i3
	jr	nz, DiskSel_CheckFinished
	ld	xwa, 4294967295
	ld	xbc, EVT_SET_NOT_DRAW_FLAG
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, 4294967295
	ld	xbc, EVT_SET_HOLD
	ld	xde, 0:i3
	call	ApPostEvent
	ldw	wa, 120
	jrl	DiskSel_CallPauseMode
DiskSel_CheckFinished:
	cp	l, 2:i3
	jrl	nz, DiskSel_Exit	; -> 0xF927FA
	ld	xwa, 4294967295
	ld	xbc, EVT_SET_NOT_DRAW_FLAG
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, 4294967295
	ld	xbc, EVT_ALL_PAINT
	ld	xde, 0:i3
	call	ApPostEvent
	ld	a, (34976:16)
	cp	a, (34974:16)
	jrl	nc, DiskSel_CheckRepeat	; -> 0xF92288
	ld	iz, 0:i3
DiskSel_ClearSelections:
	ldto_berp A, 0xf8
	extz wa
	call FileIO_FormatName_Loop
	inc 1, iz
	cp iz, 0x8
	jr lt, DiskSel_ClearSelections
	ld iz, 0:i3

DiskSel_FindSongLoop:
	lda xwa, (0x888a:16)
	ldb_dri a, 0x07, 0xe0, 0xf8
	cp a, (0x88a0:16)
	jrl nz, DiskSel_NextSongLoop
	ld (0x8342:16), iz
	ld WA,IZ
	call NotifyUIOfSelectionChange
	ld de, (0x8342:16)
	exts XDE
	ld xwa, (0x833e:16)
	ld XBC,EVT_SET_SELECTED_FILE_NUMBER
	call ApPostEvent
	ld QIZ,0
DiskSel_SendFileInfo:
	ld	de, qiz
	sll	de, 5
	lda	xbc, (33904:16)
	extz	xde
	add	xde, xbc
	ld	xwa, (33598:16)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	inc	1, qiz
	cpw	qiz, 20
	jr	lt, DiskSel_SendFileInfo
	ld	xwa, 0:i3
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	calr	FmmDiskMedley1Func
	ld	xwa, 0:i3
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	calr	FmmDiskMedley2Func
	ld	xwa, 0:i3
	ld	xbc, EVT_PAINT
	ld	xde, 7798792
	calr	DiskNameFunc
	ld	xwa, 0:i3
	ld	xbc, EVT_PAINT
	ld	xde, 7798793
	calr	DiskInfoFunc
	ld	xwa, 6291494
	ld	xbc, EVT_SHOW
	ld	xde, 5:i3
	call	ApPostEvent
	ld	wa, 0:i3
	calr	InitializeOperationState
	call	FileIO_ParseDirectoryEntry
	ld	qiz, hl
	calr	SignalProgressUpdate
	ld	xwa, 6291494
	ld	xbc, EVT_HIDE
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, 4294967295
	ld	xbc, EVT_ALL_PAINT
	ld	xde, 0:i3
	call	ApPostEvent
	cp	qiz, 0
	jr	ge, DiskSel_PlayNext
	ld	(33890:16), 0
	ldw	wa, 96
	call	UI_PostModeChangeEvent
	ld	wa, qiz
	ld	bc, 1:i3
	calr	FileIO_ValidateSignedValue
	ld	(32422:16), l
	ldw	wa, 238
	jrl	DiskSel_ShowErrorAndExit
DiskSel_PlayNext:
	inc	1, (34976:16)
	ld	xwa, (xsp+14)
	ld	xbc, EVT_INDEXSW_UP
	ld	xde, 13
	calr	DiskMed_PlayNextHelper
	cp	l, 1:i3
	jr	nz, DiskSel_NextSongLoop
	ld	xwa, 4294967295
	ld	xbc, EVT_SET_HOLD
	ld	xde, 0:i3
	call	ApPostEvent
	ldw	wa, 120
	call	UI_PostModeChangeEvent
	jr	DiskSel_ClearPlaying
DiskSel_NextSongLoop:
	inc 1, iz
	cp iz, 0x14
	jrl lt, DiskSel_FindSongLoop

DiskSel_ClearPlaying:
	ld	(33890:16), 0
	jrl	DiskSel_Exit
DiskSel_CheckRepeat:
	cp	(34978:16), 0
	jr	z, DiskSel_ClearPlaying
	ld	(34976:16), 0
	ld	iz, 0:i3
DiskSel_RepeatClear:
	ldto_berp A, 0xf8
	extz wa
	call FileIO_FormatName_Loop
	inc 1, iz
	cp iz, 0x8
	jr lt, DiskSel_RepeatClear
	ld iz, 0:i3

DiskSel_RepeatFindLoop:
	lda xwa, (0x888a:16)
	ldb_dri a, 0x07, 0xe0, 0xf8
	cp a, (0x88a0:16)
	jrl nz, DiskSel_RepeatNext
	ld (0x8342:16), iz
	ld WA,IZ
	call NotifyUIOfSelectionChange
	ld de, (0x8342:16)
	exts XDE
	ld xwa, (0x833e:16)
	ld XBC,EVT_SET_SELECTED_FILE_NUMBER
	call ApPostEvent
	ld QIZ,0
DiskSel_RepeatSendInfo:
	ld	de, qiz
	sll	de, 5
	lda	xbc, (33904:16)
	extz	xde
	add	xde, xbc
	ld	xwa, (33598:16)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	inc	1, qiz
	cpw	qiz, 20
	jr	lt, DiskSel_RepeatSendInfo
	ld	xwa, 0:i3
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	calr	FmmDiskMedley1Func
	ld	xwa, 0:i3
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	calr	FmmDiskMedley2Func
	ld	xwa, 0:i3
	ld	xbc, EVT_PAINT
	ld	xde, 7798792
	calr	DiskNameFunc
	ld	xwa, 0:i3
	ld	xbc, EVT_PAINT
	ld	xde, 7798793
	calr	DiskInfoFunc
	ld	xwa, 6291494
	ld	xbc, EVT_SHOW
	ld	xde, 5:i3
	call	ApPostEvent
	ld	wa, 0:i3
	calr	InitializeOperationState
	call	FileIO_ParseDirectoryEntry
	ld	qiz, hl
	calr	SignalProgressUpdate
	ld	xwa, 6291494
	ld	xbc, EVT_HIDE
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, 4294967295
	ld	xbc, EVT_ALL_PAINT
	ld	xde, 0:i3
	call	ApPostEvent
	cp	qiz, 0
	jr	ge, DiskSel_RepeatPlayNext
	ld	(33890:16), 0
	ldw	wa, 96
	call	UI_PostModeChangeEvent
	ld	wa, qiz
	ld	bc, 1:i3
	calr	FileIO_ValidateSignedValue
	ld	(32422:16), l
	ldw	wa, 238
	jrl	DiskSel_ShowErrorAndExit
DiskSel_RepeatPlayNext:
	inc	1, (34976:16)
	ld	xwa, (xsp+14)
	ld	xbc, EVT_INDEXSW_UP
	ld	xde, 13
	calr	DiskMed_PlayNextHelper
	cp	l, 1:i3
	jr	nz, DiskSel_RepeatNext
	ld	xwa, 4294967295
	ld	xbc, EVT_SET_HOLD
	ld	xde, 0:i3
	call	ApPostEvent
	ldw	wa, 120
DiskSel_CallPauseMode:
	call UI_PostModeChangeEvent
	jrl DiskSel_Exit

DiskSel_RepeatNext:
	inc 1, iz
	cp iz, 0x14
	jrl lt, DiskSel_RepeatFindLoop
	jrl DiskSel_Exit

DiskSel_HandleError:
	call	Medley_GetPlaybackStatus
	ld	(33890:16), 0
	cp	l, 0:i3
	jr	nz, DiskSel_ShowError
	ld	xwa, 4294967295
	ld	xbc, EVT_SET_NOT_DRAW_FLAG
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, 4294967295
	ld	xbc, EVT_ALL_PAINT
	ld	xde, 0:i3
	call	ApPostEvent
	jrl	DiskSel_Exit
DiskSel_ShowError:
	ld	xwa, 4294967295
	ld	xbc, EVT_SET_NOT_DRAW_FLAG
	ld	xde, 0:i3
	call	ApPostEvent
	ld	(32422:16), 14
	ldw	wa, 238
	jrl	DiskSel_ShowErrorAndExit
DiskSel_HandleStopEvent:
	cp (0x8c9a:16), 0x78
	jr z, DiskSel_PostStopEvent
	call CDlike_ExitModeAndRestore
	ld (0x8462:16), 0x00
DiskSel_PostStopEvent:
	calr CancelOperationCleanup
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 0:i3
	jrl DiskSel_PostEvent

DiskSel_StoreWindowPtr:
	ld	xwa, (xsp+6)
	ld	(33598:16), xwa
	call	GetCurrentFileIndex
	ld	(33602:16), hl
	cp	hl, 0:i3
	jr	lt, DiskSel_DefaultIndex
	exts	xhl
	ld	xwa, (33598:16)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, xhl
	jrl	DiskSel_PostEvent
DiskSel_DefaultIndex:
	ldw	(33602:16), 0
	ld	xwa, (33598:16)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, 0:i3
	jrl	DiskSel_PostEvent
DiskSel_InitDisplay:
	ld iz, 0:i3

DiskSel_DisplayLoop:
	ld	wa, iz
	ld	hl, wa
	sll	hl, 5
	lda	xde, (33904:16)
	extz	xhl
	add	xhl, xde
	ldto_berp	c, 248
	ld	(xhl), c
	ld	bc, 2:i3
	call	FileIO_CheckRecordByFile
	ld	wa, iz
	cp	l, 0:i3
	jr	nz, DiskSel_GetFileName
	ldw	bc, 8
	call	FileIO_CheckRecordByFile
	cp	l, 0:i3
	jr	z, DiskSel_EmptyFileName
	ld	wa, iz
DiskSel_GetFileName:
	call GetFileEntryPtr
	ld xbc, xhl
	jr DiskSel_FormatEntry

DiskSel_EmptyFileName:
	lda xbc, (Data_SaveLoadMenuTable_0x64:24)

DiskSel_FormatEntry:
	ld	de, iz
	ld	wa, de
	sll	wa, 5
	ld	hl, 1:i3
	add	hl, wa
	lda	xix, (33904:16)
	extz	xhl
	add	xhl, xix
	inc	1, de
	pushw	6
	pushw	0
	ld	xwa, xhl
	call	FileIO_ReadHeader_ParseLoop
	ld	de, iz
	sll	de, 5
	lda	xbc, (33904:16)
	extz	xde
	add	xde, xbc
	ld	xwa, (33598:16)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	inc	1, iz
	cp	iz, 20
	jr	lt, DiskSel_DisplayLoop
	jrl	DiskSel_Exit
DiskSel_HandleNavigation:
	ld de, (0x8342:16)
	ld (XSP+0x04),DE
	ld XBC,(XSP+0x0a)
	ld XWA,(XSP+0x06)
	or XWA,XWA
	jr nz, DiskSel_CheckPage
	cp (0x8462:16), 0x00
	jr nz, DiskSel_CheckPage
	ld XWA,XBC
	cp XBC,EVT_INDEXSW_DOWN
	jr nz, DiskSel_CheckPrevKey
	cp DE,0x0013
	jrl ge, DiskSel_GetCurrentIndex
	inc 1,DE
	jr t, DiskSel_SaveIndex
DiskSel_CheckPrevKey:
	cp xwa, EVT_INDEXSW_UP
	jrl nz, DiskSel_GetCurrentIndex
	cp de, 0:i3
	jrl le, DiskSel_GetCurrentIndex
	dec 1, de
	jr DiskSel_SaveIndex

DiskSel_CheckPage:
	ld	xwa, (xsp + 6)
	cp	xwa, 0x1
	jr	nz, DiskSel_CheckPageDown
	cp	(0x8462:16), 0
	jr	nz, DiskSel_CheckPageDown
	cp	de, 0xa
	jrl	lt, DiskSel_GetCurrentIndex
	sub	de, 0xa
	jr	DiskSel_SaveIndex
DiskSel_CheckPageDown:
	ld	xwa, (xsp + 6)
	cp	xwa, 0x2
	jr	nz, DiskSel_HandleToggle
	cp	(0x8462:16), 0
	jr	nz, DiskSel_HandleToggle
	ld	wa, de
	add	wa, 0xa
	cp	wa, 0x13
	jrl	gt, DiskSel_GetCurrentIndex
	add	de, 0xa
DiskSel_SaveIndex:
	ld	(33602:16), de
	jrl	DiskSel_UpdateDisplay
DiskSel_HandleToggle:
	lda	xhl, (34954:16)
	ld	xwa, (xsp+6)
	cp	xwa, 10
	jr	nz, DiskSel_HandleSelect
	cp	(33890:16), 0
	jr	nz, DiskSel_HandleSelect
	ld	iz, 0:i3
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
	ld	a, (xhl)
	cp	a, 0xfe
	jr	nz, DiskSel_NextAssign
	ldmi16	(xhl), 0x889e
	inc	1, (0x889e:16)
DiskSel_NextAssign:
	inc 1, xhl
	cp xhl, xde
	jr c, DiskSel_AssignLoop
	jr DiskSel_RefreshDisplay

DiskSel_UnmarkLoop:
	ld	a, (xhl)
	cp	a, 253
	jr	ugt, DiskSel_NextUnmark
	ld	(xhl), 254
	dec	1, (34974:16)
DiskSel_NextUnmark:
	inc 1, xhl
	cp xhl, xde
	jr c, DiskSel_UnmarkLoop

DiskSel_RefreshDisplay:
	ld xwa, 0:i3
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	calr FmmDiskMedley1Func
	ld xwa, 0:i3
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	jr DiskSel_RefreshBoth

DiskSel_HandleSelect:
	ld	xwa, (xsp + 6)
	cp	xwa, 0xb
	jr	nz, DiskSel_HandleRepeat
	cp	(0x8462:16), 0
	jr	nz, DiskSel_HandleRepeat
	ld	xix, xhl
	lda_dri	XBC, 0x07, 0xec, 0xe8
	ld	a, (xbc)
	cp	a, 0xfe
	jr	nz, DiskSel_RemoveSelect
	ldmi16	(xbc), 0x889e
	inc	1, (0x889e:16)
	jr	DiskSel_RefreshAfterSelect
DiskSel_RemoveSelect:
	cp	a, 253
	jr	ugt, DiskSel_RefreshAfterSelect
	cp	de, 20
	jr	ge, DiskSel_ReorderSlots
	ld	(xbc), 254
	dec	1, (34974:16)
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
	ld xwa, 0:i3
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	calr FmmDiskMedley1Func
	ld xwa, 0:i3
	ld xbc, EVT_PAINT
	ld xde, 0:i3

DiskSel_RefreshBoth:
	calr FmmDiskMedley2Func
	jrl DiskSel_GetCurrentIndex

DiskSel_HandleRepeat:
	ld	xwa, (xsp+6)
	cp	xwa, 12
	jr	nz, DiskSel_HandlePlayStart
	cp	xbc, EVT_INDEXSW_UP
	jr	nz, DiskSel_SetRepeatOff
	ld	(34978:16), 1
	jrl	DiskSel_GetCurrentIndex
DiskSel_SetRepeatOff:
	ld	(34978:16), 0
	jrl	DiskSel_GetCurrentIndex
DiskSel_HandlePlayStart:
	ld xwa, (xsp + 6)

	cp xwa, 0xd

; jrl nz, DiskSel_HandleAllCheck (v7 displacement)
	jrl	nz, DiskSel_HandleAllCheck
; cpdi8 (0x84fe), 0 (v7 patched)
	cp	(0x8462:16), 0
; jrl nz, DiskSel_HandleAllCheck (v7 displacement)
	jrl	nz, DiskSel_HandleAllCheck
; stdi8 (0x893c), 0 (v7 patched)
	ld	(0x88a0:16), 0

	ld iz, 0:i3



DiskSel_PlayClearLoop:
	ldto_berp A, 0xf8
	extz wa
	call FileIO_FormatName_Loop
	inc 1, iz
	cp iz, 0x8
	jr lt, DiskSel_PlayClearLoop
	ld iz, 0:i3

DiskSel_PlayFindLoop:
	lda xwa, (0x888a:16)
	ldb_dri a, 0x07, 0xe0, 0xf8
	cp a, (0x88a0:16)
	jrl nz, DiskSel_PlayNextLoop
	ld (0x8342:16), iz
	ld WA,IZ
	call NotifyUIOfSelectionChange
	ld de, (0x8342:16)
	exts XDE
	ld xwa, (0x833e:16)
	ld XBC,EVT_SET_SELECTED_FILE_NUMBER
	call ApPostEvent
	ld XWA,0x00600026
	ld XBC,EVT_SHOW
	ld xde, 5:i3
	call ApPostEvent
	call FileIO_ParseDirectoryEntry
	ld QIZ,HL
	calr SignalProgressUpdate
	ld XWA,0x00600026
	ld XBC,EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ld XWA,0xffffffff
	ld XBC,EVT_ALL_PAINT
	ld xde, 0:i3
	call ApPostEvent
	cp QIZ,0
	jr ge, DiskSel_PlayNextSong
	ld (0x8462:16), 0x00
	ldw WA, 0x0060
	call UI_PostModeChangeEvent
	ld WA,QIZ
	ld bc, 1:i3
	calr FileIO_ValidateSignedValue
	ld (0x7ea6:16), l
	ldw WA, 0x00ee
DiskSel_ShowErrorAndExit:
	call SoundCtrl_SendCommand
	jrl DiskSel_Exit

DiskSel_PlayNextSong:
	ldmw2	(xsp + 4), 0x8342
	inc	1, (0x88a0:16)
	ld	xwa, (xsp + 14)
	ld	xbc, (xsp + 10)
	ld	xde, (xsp + 6)
	calr	DiskMed_PlayNextHelper
	cp	l, 1:i3
	jr	nz, DiskSel_PlayNextLoop
	ld	xwa, 0xffffffff
	ld	xbc, EVT_SET_HOLD
	ld	xde, 0:i3
	call	ApPostEvent
	ldw	wa, 0x78
	call	UI_PostModeChangeEvent
	jr	DiskSel_GetCurrentIndex
DiskSel_PlayNextLoop:
	inc 1, iz
	cp iz, 0x14
	jrl lt, DiskSel_PlayFindLoop
	jr DiskSel_GetCurrentIndex

DiskSel_HandleAllCheck:
	ld	xwa, (xsp+6)
	cp	xwa, 14
	jr	nz, DiskSel_GetCurrentIndex
	cp	xbc, EVT_INDEXSW_UP
	jr	nz, DiskSel_SetAllOff
	ld	(34980:16), 1
	jr	DiskSel_GetCurrentIndex
DiskSel_SetAllOff:
	ld	(34980:16), 0
DiskSel_GetCurrentIndex:
	ld	de, (33602:16)
DiskSel_UpdateDisplay:
	cp	(xsp+4), de
	jr	z, DiskSel_Exit
	ld	wa, de
	call	NotifyUIOfSelectionChange
	ld	de, (33602:16)
	exts	xde
	ld	xwa, (33598:16)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	call	ApPostEvent
	ld	de, (xsp+4)
	sll	de, 5
	lda	xbc, (33904:16)
	extz	xde
	add	xde, xbc
	ld	xwa, (33598:16)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	ld	de, (33602:16)
	sll	de, 5
	lda	xbc, (33904:16)
	extz	xde
	add	xde, xbc
	ld	xwa, (33598:16)
	ld	xbc, EVT_PARA_DRAW
DiskSel_PostEvent:
	call ApPostEvent

DiskSel_Exit:
	ld xhl, 0:i3
	pop xiz
	lda xsp, (xsp + 14)
	ret

GetPlayState1_Entry:
GetPlayState1:
	ld	l, (34982:16)
	ret
GetPlayState2_Entry:
GetPlayState2:
	ld	l, (34984:16)
	ret
SmfMedley_RawData:
	cp a, 0:i3
	scc NZ,WA
	ld (0x88a8:16), a
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
	cpw	(0x8468:16), 0
	jr	le, NavSong_Exit
	call	GetFirstPageBase
	cp	hl, 0:i3
	jr	lt, NavSong_Exit
	ld	iz, hl
	add	iz, (xsp + 2)
	jr	ge, NavSong_WrapToEnd
	ld	iz, (0x8468:16)
	dec	1, iz
	jr	NavSong_CheckEnd
NavSong_WrapToEnd:
	cp	iz, (0x8468:16)
	jr	lt, NavSong_CheckEnd
	ld	iz, 0:i3
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
	cp iz, 1:i3
	jr z, NavDoc_CheckBounds
	cp iz, 0xffff
	jr nz, NavDoc_Exit

NavDoc_CheckBounds:
	cpw	(0x846c:16), 0
	jr	le, NavDoc_Exit
	call	FileIO_GetCurrentFileIndex_Alt
	cp	hl, 0:i3
	jr	lt, NavDoc_Exit
	ld	wa, hl
	add	wa, iz
	jr	ge, NavDoc_WrapToEnd
	ld	wa, (0x846c:16)
	dec	1, wa
	jr	NavDoc_CheckEnd
NavDoc_WrapToEnd:
	cp	wa, (0x846c:16)
	jr	lt, NavDoc_CheckEnd
	ld	wa, 0:i3
NavDoc_CheckEnd:
	cp hl, wa
	call nz, (FileIO_SelectFileByIndex:24)

NavDoc_Exit:
	popw iz
	ret

NavigatePdList_Entry:
NavigatePdList:
	pushw iz
	ld iz, wa
	cp iz, 1:i3
	jr z, NavPd_CheckBounds
	cp iz, 0xffff
	jr nz, NavPd_Exit

NavPd_CheckBounds:
	cpw	(0x846a:16), 0
	jr	le, NavPd_Exit
	call	GetCurrentFileIndexAlt
	cp	hl, 0:i3
	jr	lt, NavPd_Exit
	ld	wa, hl
	add	wa, iz
	jr	ge, NavPd_WrapToEnd
	ld	wa, (0x846a:16)
	dec	1, wa
	jr	NavPd_CheckEnd
NavPd_WrapToEnd:
	cp	wa, (0x846a:16)
	jr	lt, NavPd_CheckEnd
	ld	wa, 0:i3
NavPd_CheckEnd:
	cp hl, wa
	call nz, (SetCurrentFileIndex:24)

NavPd_Exit:
	popw iz
	ret

SmfMed_FormatSlotList:
	dec 6, xsp
	push xiz
	ld iz, bc
	ld (xsp + 6), xwa
	ld xwa, 0:i3
	ld xbc, EVT_GET_SELECTED_FILE_NUMBER
	ld xde, 0:i3
	calr FmmSmfFileNameFunc
	ldfr_werp HL, 0xfa
	ldto_werp WA, 0xfa
	extz xwa
	div wa, 0xa
	ldfr_werp WA, 0xfa
	mul wa, 0xa
	ldfr_werp WA, 0xfa
	ldw (xsp + 4), 0xa
	ldto_werp WA, 0xfa
	add wa, 0xa
	cp wa, iz
	jr c, SmfFmt_CalcVisible
	ld (xsp + 4), iz
	ldto_werp WA, 0xfa
	sub (xsp + 4), wa

SmfFmt_CalcVisible:
	ld iz, 0:i3
	cpw (xsp + 4), 0x0
	jr ule, SmfFmt_FillEmpty
SmfFmt_FormatLoop:
	ld	wa, iz
	sll	wa, 3
	lda	xbc, (33604:16)
	extz	xwa
	add	xwa, xbc
	ld	bc, qiz
	add	bc, iz
	lda	xde, (34820:16)
	extz	xbc
	add	xbc, xde
	ld	c, (xbc)
	extz	bc
	ld	de, iz
	calr	FormatMedleyNumber
	ld	de, iz
	sll	de, 3
	lda	xwa, (33604:16)
	extz	xde
	add	xde, xwa
	ld	xwa, (xsp+6)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	inc	1, iz
	cp	iz, (xsp+0x4)
	jr	c, SmfFmt_FormatLoop
SmfFmt_FillEmpty:
	cp iz, 0xa
	jr nc, SmfFmt_Exit

SmfFmt_EmptyLoop:
	ld	wa, iz
	sll	wa, 3
	lda	xbc, (33604:16)
	extz	xwa
	add	xwa, xbc
	ldw	bc, 255
	ld	de, iz
	calr	FormatMedleyNumber
	ld	de, iz
	sll	de, 3
	lda	xwa, (33604:16)
	extz	xde
	add	xde, xwa
	ld	xwa, (xsp+6)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	inc	1, iz
	cp	iz, 10
	jr	c, SmfFmt_EmptyLoop
SmfFmt_Exit:
	pop xiz
	inc 6, xsp
	ret

FmmSmfMedleyFunc:
	dec	4, xsp
	pushw	iz
	ld	xhl, xbc
	ld	(xsp+2), xwa
	cp	xhl, EVT_WAKE_UP_NOW
	jrl	z, SmfMed_CheckContinue
	ld	xwa, xde
	cp	xhl, EVT_I_WILL_WAKE_UP
	jrl	z, SmfMed_StoreDelayFlag
	ld	bc, (33692:16)
	cp	xhl, EVT_INDEXSW_DOWN
	jrl	z, SmfMed_HandleNavToggle
	cp	xhl, EVT_INDEXSW_UP
	jrl	z, SmfMed_HandleNavToggle
	cp	xhl, EVT_PAINT
	jrl	z, SmfMed_RefreshDisplay
	cp	xhl, EVT_PS_FILE_NAME_BOX_ID
	jrl	z, SmfMed_StoreWindowPtr
	cp	xhl, EVT_ACTIVATE_STATE
	jrl	nz, SmfMed_Exit
	cp	xde, 3
	jrl	z, SmfMed_HandleStop
	cp	xde, 2
	jrl	nz, SmfMed_Exit
	ld	wa, 0:i3
	calr	InitializeOperationState
	ld	a, (35995:16)
	ld	(33694:16), a
	cp	a, 111
	jr	z, SmfMed_CheckNotPlaying
	cp	a, 114
	jr	nz, SmfMed_CheckPlayMode
SmfMed_CheckNotPlaying:
	ld	(33890:16), 0
	call	Medley_GetPlaybackStatus
	cp	l, 4:i3
	jr	z, SmfMed_Error3F
	cp	l, 3:i3
	jr	z, SmfMed_Error31
	cp	l, 2:i3
	jrl	nz, SmfMed_Exit
	ld	(32422:16), 1
	ldw	wa, 238
	jr	SmfMed_ShowError
SmfMed_Error31:
	ld	(32422:16), 49
	ldw	wa, 238
	jr	SmfMed_ShowError
SmfMed_Error3F:
	ld	(32422:16), 63
	ldw	wa, 238
SmfMed_ShowError:
	call SoundCtrl_SendCommand
	jrl SmfMed_Exit

SmfMed_CheckPlayMode:
	cp a, 0x73
	jr z, SmfMed_CheckPlaying
	cp a, 0x76
	jrl nz, SmfMed_InitFromDisk

SmfMed_CheckPlaying:
	call	Medley_GetPlaybackStatus
	cp	l, 1:i3
	jrl	c, SmfMed_CheckNotPlayError
	call	Medley_GetPlaybackStatus
	cp	l, 4:i3
	jr	z, SmfMed_PlayError3F
	cp	l, 3:i3
	jr	z, SmfMed_PlayError31
	cp	l, 2:i3
	jr	nz, SmfMed_SetPlaying
	ld	(32422:16), 1
	ldw	wa, 238
	jr	SmfMed_ShowPlayError
SmfMed_PlayError31:
	ld	(32422:16), 49
	ldw	wa, 238
	jr	SmfMed_ShowPlayError
SmfMed_PlayError3F:
	ld	(32422:16), 63
	ldw	wa, 238
SmfMed_ShowPlayError:
	call	SoundCtrl_SendCommand
	inc	1, (33696:16)
SmfMed_SetPlaying:
	ld	(33890:16), 1
	ld	a, (34950:16)
	cp	a, (34948:16)
	jr	nc, SmfMed_CheckRepeat	; -> 0xF92B0B
	ld	iz, 0:i3
	ld	bc, (33692:16)
	cp	bc, 0:i3
	jrl	ule, SmfMed_Exit	; -> 0xF92E70
	lda	xde, (34820:16)
SmfMed_FindSongLoop:
	ld	hl, iz
	extz	xhl
	add	xhl, xde
	cp	(xhl), a
	jr	nz, SmfMed_NextSong
	ld	de, iz
	extz	xde
	ld	xwa, (xsp+2)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	calr	FmmSmfFileNameFunc
	ld	xwa, (33684:16)
	ld	bc, (33692:16)
	calr	SmfMed_FormatSlotList
	inc	1, (34950:16)
	ld	wa, iz
	call	GetFileEntryByIndex
	ld	xwa, (33688:16)
	or	xwa, xwa
	jrl	z, SmfMed_Exit
	ld	xbc, EVT_WAKE_UP_TIME
	ld	xde, 30
	jr	SmfMed_PostDelayEvent
SmfMed_NextSong:
	inc 1, iz
	cp iz, bc
	jr c, SmfMed_FindSongLoop
	jrl SmfMed_Exit
SmfMed_CheckRepeat:
	cp	(34952:16), 0
	jr	z, SmfMed_ClearRepeatCount
	cp	(33696:16), a
	jr	nc, SmfMed_ClearRepeatCount
	ld	(34950:16), 0
	ld	(33696:16), 0
	ld	iz, 0:i3
	ld	wa, (33692:16)
	cp	wa, 0:i3
	jrl	ule, SmfMed_Exit
	lda	xbc, (34820:16)
SmfMed_RepeatFindLoop:
	ld	de, iz
	extz	xde
	add	xde, xbc
	cp	(xde), 0
	jr	nz, SmfMed_RepeatNext
	ld	de, iz
	extz	xde
	ld	xwa, (xsp+2)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	calr	FmmSmfFileNameFunc
	ld	xwa, (33684:16)
	ld	bc, (33692:16)
	calr	SmfMed_FormatSlotList
	inc	1, (34950:16)
	ld	wa, iz
	call	GetFileEntryByIndex
	ld	xwa, (33688:16)
	or	xwa, xwa
	jrl	z, SmfMed_Exit
	ld	xbc, EVT_WAKE_UP_TIME
	ld	xde, 30
SmfMed_PostDelayEvent:
	call ApPostEvent
	jrl SmfMed_Exit

SmfMed_RepeatNext:
	inc 1, iz
	cp iz, wa
	jr c, SmfMed_RepeatFindLoop
	jrl SmfMed_Exit

SmfMed_ClearRepeatCount:
	ld	(33696:16), 0
	jr	SmfMed_ClearPlaying
SmfMed_CheckNotPlayError:
	call Medley_GetPlaybackStatus
	cp l, 0:i3
	jrl nz, SmfMed_Exit

SmfMed_ClearPlaying:
	ld	(33890:16), 0
	jrl	SmfMed_Exit
SmfMed_InitFromDisk:
	ld xde, 0:i3
	ld e, (0x88a8:16)
	ld XWA,0x006c0018
	ld XBC,EVT_SET_PARAM
	call ApPostEvent
	cpw (0x8468:16), 0x0000
	jr ge, SmfMed_InitState
	ld XWA,0x00600026
	ld XBC,EVT_SHOW
	ld xde, 5:i3
	call ApPostEvent
	call GetFileCountEncoded
	ld (0x8468:16), hl
	call FileIO_SearchAndLoadFile
	call GetEncodedFreeSpaceData
	ld XWA,0x00600026
	ld XBC,EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ld XWA,0xffffffff
	ld XBC,EVT_ALL_PAINT
	ld xde, 0:i3
	call ApPostEvent
	calr SignalProgressUpdate
SmfMed_InitState:
	ld	(33890:16), 0
	ld	(34950:16), 0
	ld	(34948:16), 0
	ldw	bc, 128
	ld	wa, (33896:16)
	cp	wa, 128
	jr	ugt, SmfMed_ClampFileCount
	ld	bc, wa
SmfMed_ClampFileCount:
	ld	(33692:16), bc
	ld	iz, 0:i3
	cp	bc, 0:i3
	jr	ule, SmfMed_FinishInit
	lda	xwa, (34820:16)
SmfMed_ClearSlotsLoop:
	ld	bc, iz
	extz	xbc
	add	xbc, xwa
	ld	(xbc), 255
	inc	1, iz
	cp	iz, (33692:16)
	jr	c, SmfMed_ClearSlotsLoop	; -> 0xF92C26
SmfMed_FinishInit:
	call	CDlike_InitModeAndLoadBank
	ld	xwa, 0:i3
	ld	(33688:16), xwa
	jrl	SmfMed_Exit
SmfMed_HandleStop_Entry:
SmfMed_HandleStop:
	ld	a, (35994:16)
	cp	a, 111
	jrl	z, SmfMed_Exit
	cp	a, 114
	jrl	z, SmfMed_Exit
	cp	a, 115
	jrl	z, SmfMed_Exit
	cp	a, 118
	jrl	z, SmfMed_Exit
	call	CDlike_ExitModeAndRestore
	calr	CancelOperationCleanup
	ld	(33890:16), 0
	jrl	SmfMed_Exit
SmfMed_StoreWindowPtr:
	ld	(33684:16), xwa
	jrl	SmfMed_Exit
SmfMed_RefreshDisplay:
	ld	xwa, (33684:16)
	calr	SmfMed_FormatSlotList
	jrl	SmfMed_Exit
SmfMed_HandleNavToggle:
	lda xwa, (0x8804:16)
	cp XDE,0x0000000a
	jr nz, SmfMed_HandleSelectToggle
	cp (0x8462:16), 0x00
	jr nz, SmfMed_HandleSelectToggle
	ld iz, 0:i3
	ld DE,BC
	cp bc, 0:i3
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
	cp	iz, de
	jr	nc, SmfMed_RemoveOrderLoop
	ld	iz, 0:i3
	cp	de, 0:i3
	jr	ule, SmfMed_RefreshAfterToggle
	lda	xde, (34820:16)
SmfMed_AssignOrderLoop:
	ld	bc, iz
	extz	xbc
	add	xbc, xde
	ld	a, (xbc)
	cp	a, 0xff
	jr	nz, SmfMed_NextAssign
	ldmi16	(xbc), 0x8884
	inc	1, (0x8884:16)
SmfMed_NextAssign:
	inc	1, iz
	cp	iz, (0x839c:16)
	jr	c, SmfMed_AssignOrderLoop
	jr	SmfMed_RefreshAfterToggle
SmfMed_RemoveOrderLoop:
	ld	iz, 0:i3
	cp	de, 0:i3
	jr	ule, SmfMed_RefreshAfterToggle
	lda	xde, (34820:16)
SmfMed_UnmarkLoop:
	ld	bc, iz
	extz	xbc
	add	xbc, xde
	ld	a, (xbc)
	cp	a, 253
	jr	ugt, SmfMed_NextUnmark
	ld	(xbc), 255
	dec	1, (34948:16)
SmfMed_NextUnmark:
	inc	1, iz
	cp	iz, (0x839c:16)
	jr	c, SmfMed_UnmarkLoop
SmfMed_RefreshAfterToggle:
	ld	xwa, (33684:16)
	ld	bc, (33692:16)
	jr	SmfMed_CallFormatSlots
SmfMed_HandleSelectToggle:
	cp	xde, 0xb
	jr	nz, SmfMed_HandleRepeat
	cp	(0x8462:16), 0
	jr	nz, SmfMed_HandleRepeat
	ld	xwa, (xsp + 2)
	ld	xbc, EVT_GET_SELECTED_FILE_NUMBER
	ld	xde, 0:i3
	calr	FmmSmfFileNameFunc
	ld	iz, hl
	lda	xhl, (0x8804:16)
	ld	wa, iz
	extz	xwa
	add	xwa, xhl
	ld	c, (xwa)
	cp	c, 0xff
	jr	nz, SmfMed_RemoveFromOrder
	ldmi16	(xwa), 0x8884
	inc	1, (0x8884:16)
	jr	SmfMed_RefreshAfterSelect
SmfMed_RemoveFromOrder:
	cp	c, 253
	jr	ugt, SmfMed_RefreshAfterSelect
	ld	(xwa), 255
	ld	a, (34948:16)
	dec	1, a
	ld	(34948:16), a
	ld	iy, 0:i3
	ld	iz, 0:i3
	extz	wa
	cp	wa, 0:i3
	jr	ule, SmfMed_RefreshAfterSelect
	ld	ix, wa
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
	ld	xwa, (33684:16)
	ld	bc, (33692:16)
SmfMed_CallFormatSlots:
	calr SmfMed_FormatSlotList
	jrl SmfMed_Exit

SmfMed_HandleRepeat:
	cp	xde, 12
	jr	nz, SmfMed_HandlePlay
	cp	xhl, EVT_INDEXSW_UP
	jr	nz, SmfMed_SetRepeatOff
	ld	(34952:16), 1
	jrl	SmfMed_Exit
SmfMed_SetRepeatOff:
	ld	(34952:16), 0
	jrl	SmfMed_Exit
SmfMed_HandlePlay:
	cp	xde, 13
	jrl	nz, SmfMed_Exit
	cp	(33890:16), 0
	jrl	nz, SmfMed_Exit
	ld	(34950:16), 0
	ld	(33696:16), 0
	ld	iz, 0:i3
	ld	bc, (33692:16)
	cp	bc, 0:i3
	jr	ule, SmfMed_CheckAutoPlay
SmfMed_PlayFindLoop:
	ld	de, iz
	extz	xde
	add	xde, xwa
	cp	(xde), 0
	jr	nz, SmfMed_PlayNextLoop
	ld	(33890:16), 1
	ld	de, iz
	extz	xde
	ld	xwa, (xsp+2)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	calr	FmmSmfFileNameFunc
	inc	1, (34950:16)
	ld	wa, iz
	call	GetFileEntryByIndex
	ld	xwa, 4294967295
	ld	xbc, EVT_SET_HOLD
	ld	xde, 0:i3
	call	ApPostEvent
	ldw	wa, 115
	call	UI_PostModeChangeEvent
	jr	SmfMed_CheckAutoPlay
SmfMed_PlayNextLoop:
	inc 1, iz
	cp iz, bc
	jr c, SmfMed_PlayFindLoop

SmfMed_CheckAutoPlay:
	cp	(33890:16), 0
	jr	nz, SmfMed_Exit
	ld	xwa, (xsp+2)
	ld	xbc, EVT_GET_SELECTED_FILE_NUMBER
	ld	xde, 0:i3
	calr	FmmSmfFileNameFunc
	ld	iz, hl
	ld	wa, iz
	call	GetFileEntryByIndex
	ld	xwa, 4294967295
	ld	xbc, EVT_SET_HOLD
	ld	xde, 0:i3
	call	ApPostEvent
	ldw	wa, 111
	jr	SmfMed_CallPauseMode
SmfMed_StoreDelayFlag:
	ld	(33688:16), xwa
	jr	SmfMed_Exit
SmfMed_CheckContinue:
	cp (0x8462:16), 0x00
	jr z, SmfMed_Exit
	ld XWA,0xffffffff
	ld XBC,EVT_SET_HOLD
	ld xde, 0:i3
	call ApPostEvent
	ld a, (0x839e:16)
	extz WA
SmfMed_CallPauseMode:
	call UI_PostModeChangeEvent

SmfMed_Exit:
	ld xhl, 0:i3
	popw iz
	inc 4, xsp
	ret

PdMed_FormatFileList_Entry:
PdMed_FormatFileList:
	dec 6, xsp
	pushw iz
	ld (xsp + 2), bc
	ld (xsp + 4), xwa
	ld iz, 0:i3
PdFmt_FormatLoop:
	ld	de, iz
	sll	de, 5
	lda	xbc, (33904:16)
	extz	xde
	add	xde, xbc
	ldto_berp	a, 248
	ld	(xde), a
	ld	wa, (xsp+2)
	add	wa, iz
	call	GetFileRecordPtr
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
	pushw	0x14
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
	jr	lt, PdFmt_FormatLoop
	popw	iz
	inc	6, xsp
	ret
FmmPdFileNameFunc:
	dec	4, xsp
	pushw	iz
	ld	(xsp+2), xwa
	cp	xbc, EVT_GET_SELECTED_FILE_NUMBER
	jrl	z, PdName_GetIndexReturn
	ld	wa, (33702:16)
	ld	iz, wa
	cp	xbc, EVT_SET_SELECTED_FILE_NUMBER
	jrl	z, PdName_SetIndexPlaying
	ld	hl, wa
	exts	xhl
	divs	hl, 10
	cp	xbc, EVT_INDEXSW_DOWN
	jr	z, PdName_HandleNavigation
	cp	xbc, EVT_INDEXSW_UP
	jr	z, PdName_HandleNavigation
	cp	xbc, EVT_PAINT
	jr	z, PdName_RefreshList
	cp	xbc, EVT_PS_FILE_NAME_BOX_ID
	jr	nz, PdName_ReturnZero
	ld	(33698:16), xde
	call	GetCurrentFileIndexAlt
	ld	(33702:16), hl
	cp	hl, 0:i3
	jr	ge, PdName_UpdateIndex
	ldw	(33702:16), 0
PdName_UpdateIndex:
	ld	wa, (33702:16)
	exts	xwa
	divs	wa, 10
	ld	de, qwa
	exts	xde
	ld	xwa, (33698:16)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	jrl	PdName_PostEvent
PdName_RefreshList:
	muls	hl, 10
	ld	xwa, (33698:16)
	ld	bc, hl
	calr	PdMed_FormatFileList
PdName_ReturnZero:
	ld xhl, 0:i3
	jrl PdName_Exit

PdName_HandleNavigation:
	or	xde, xde
	jr	nz, PdName_CheckPageUp
	cp	(0x8462:16), 0
	jr	nz, PdName_CheckPageUp
	cp	xbc, EVT_INDEXSW_DOWN
	jr	nz, PdName_CheckPrevKey
	ld	bc, wa
	inc	1, bc
	cp	bc, (0x846a:16)
	jr	ge, PdName_GetCurrentIndex
	inc	1, wa
	jr	PdName_SaveIndex
PdName_CheckPrevKey:
	cp xbc, EVT_INDEXSW_UP
	jr nz, PdName_GetCurrentIndex
	cp wa, 0:i3
	jr le, PdName_GetCurrentIndex
	dec 1, wa
	jr PdName_SaveIndex

PdName_CheckPageUp:
	cp	xde, 0x1
	jr	nz, PdName_CheckPageDown
	cp	(0x8462:16), 0
	jr	nz, PdName_CheckPageDown
	cp	wa, 0xa
	jr	lt, PdName_GetCurrentIndex
	sub	wa, 0xa
	jr	PdName_SaveIndex
PdName_CheckPageDown:
	cp	xde, 0x2
	jr	nz, PdName_GetCurrentIndex
	cp	(0x8462:16), 0
	jr	nz, PdName_GetCurrentIndex
	ld	bc, wa
	add	bc, 0xa
	ld	de, (0x846a:16)
	cp	bc, de
	jr	ge, PdName_CheckEndBound
	add	wa, 0xa
PdName_SaveIndex:
	ld	(33702:16), wa
	jr	PdName_UpdateDisplay
PdName_CheckEndBound:
	ld	bc, de
	dec	1, bc
	ld	wa, bc
	exts	xwa
	divs	wa, 10
	cp	hl, wa
	jr	ge, PdName_GetCurrentIndex
	exts	xde
	divs	de, 10
	ld	wa, qde
	cp	wa, 0:i3
	jr	z, PdName_GetCurrentIndex
	ld	(33702:16), bc
PdName_GetCurrentIndex:
	ld	wa, (33702:16)
PdName_UpdateDisplay:
	cp	iz, wa
	jrl	z, PdName_ReturnZero
	call	SetCurrentFileIndex
	ld	wa, (33702:16)
	exts	xwa
	divs	wa, 10
	ld	de, qwa
	exts	xde
	ld	xwa, (33698:16)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	call	ApPostEvent
	ld	bc, (33702:16)
	exts	xbc
	divs	bc, 10
	ld	de, iz
	exts	xde
	divs	de, 10
	ld	xwa, (33698:16)
	cp	de, bc
	jr	nz, PdName_RefreshPage
	ld	bc, iz
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
	ld	wa, (33702:16)
	exts	xwa
	divs	wa, 10
	ld	wa, qwa
	sll	wa, 5
	lda	xbc, (33904:16)
	ld	de, wa
	extz	xde
	add	xde, xbc
	ld	xwa, (33698:16)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	jrl	PdName_ReturnZero
PdName_RefreshPage:
	muls bc, 0xa
	calr PdMed_FormatFileList
	ld xwa, (xsp + 2)
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	calr FmmPdMedleyFunc
	jrl PdName_ReturnZero

PdName_SetIndexPlaying:
	cp (0x8462:16), 0x00
	jrl z, PdName_ReturnZero
	ld (0x83a6:16), de

	ld wa, de

; call SetCurrentFileIndex (v7 addr)
	call	SetCurrentFileIndex
; ldw_d16 xwa, (0x8442) (v7 patched)
	ld	wa, (0x83a6:16)

	exts xwa

	divs wa, 0xa

	ldto_werp DE, 0xe2

	exts xde

	ld xwa, (33698:16)

	ld xbc, EVT_SET_SELECTED_FILE_NUMBER



PdName_PostEvent:
	call ApPostEvent
	jrl PdName_ReturnZero

PdName_GetIndexReturn:
	ld	hl, (33702:16)
	exts	xhl
PdName_Exit:
	popw iz
	inc 4, xsp
	ret

PdMed_FormatSlotList:
	dec 6, xsp
	push xiz
	ld iz, bc
	ld (xsp + 6), xwa
	ld xwa, 0:i3
	ld xbc, EVT_GET_SELECTED_FILE_NUMBER
	ld xde, 0:i3
	calr FmmPdFileNameFunc
	ldfr_werp HL, 0xfa
	ldto_werp WA, 0xfa
	extz xwa
	div wa, 0xa
	ldfr_werp WA, 0xfa
	mul wa, 0xa
	ldfr_werp WA, 0xfa
	ldw (xsp + 4), 0xa
	ldto_werp WA, 0xfa
	add wa, 0xa
	cp wa, iz
	jr c, PdFmtSlot_CalcVisible
	ld (xsp + 4), iz
	ldto_werp WA, 0xfa
	sub (xsp + 4), wa

PdFmtSlot_CalcVisible:
	ld iz, 0:i3
	cpw (xsp + 4), 0x0
	jr ule, PdFmtSlot_FillEmpty
PdFmtSlot_FormatLoop:
	ld	wa, iz
	sll	wa, 3
	lda	xbc, (33704:16)
	extz	xwa
	add	xwa, xbc
	ld	bc, qiz
	add	bc, iz
	lda	xde, (34820:16)
	extz	xbc
	add	xbc, xde
	ld	c, (xbc)
	extz	bc
	ld	de, iz
	calr	FormatMedleyNumber
	ld	de, iz
	sll	de, 3
	lda	xwa, (33704:16)
	extz	xde
	add	xde, xwa
	ld	xwa, (xsp+6)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	inc	1, iz
	cp	iz, (xsp+0x4)
	jr	c, PdFmtSlot_FormatLoop
PdFmtSlot_FillEmpty:
	cp iz, 0xa
	jr nc, PdFmtSlot_Exit

PdFmtSlot_EmptyLoop:
	ld	wa, iz
	sll	wa, 3
	lda	xbc, (33704:16)
	extz	xwa
	add	xwa, xbc
	ldw	bc, 255
	ld	de, iz
	calr	FormatMedleyNumber
	ld	de, iz
	sll	de, 3
	lda	xwa, (33704:16)
	extz	xde
	add	xde, xwa
	ld	xwa, (xsp+6)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	inc	1, iz
	cp	iz, 10
	jr	c, PdFmtSlot_EmptyLoop
PdFmtSlot_Exit:
	pop xiz
	inc 6, xsp
	ret

FmmPdMedleyFunc_Entry:
FmmPdMedleyFunc:
	push	xiz
	ld	xhl, xde
	ld	xde, xbc
	ld	xiz, xwa
	cp	xde, EVT_WAKE_UP_NOW
	jrl	z, PdMed_CheckContinue
	ld	xwa, xhl
	cp	xde, EVT_I_WILL_WAKE_UP
	jrl	z, PdMed_StoreDelayFlag
	ld	bc, (33792:16)
	cp	xde, EVT_INDEXSW_DOWN
	jrl	z, PdMed_HandleNavToggle
	cp	xde, EVT_INDEXSW_UP
	jrl	z, PdMed_HandleNavToggle
	cp	xde, EVT_PAINT
	jrl	z, PdMed_RefreshDisplay
	cp	xde, EVT_PS_FILE_NAME_BOX_ID
	jrl	z, PdMed_StoreWindowPtr
	cp	xde, EVT_ACTIVATE_STATE
	jrl	nz, PdMed_Exit
	cp	xhl, 3
	jrl	z, PdMed_HandleStop
	cp	xhl, 2
	jrl	nz, PdMed_Exit
	ld	wa, 0:i3
	call	InitializeOperationState
	ld	a, (35995:16)
	cp	a, 113
	jr	nz, PdMed_CheckPlayMode
	ld	(33890:16), 0
	call	Medley_GetPlaybackStatus
	cp	l, 2:i3
	jrl	c, PdMed_Exit
	ld	(32422:16), 1
	ldw	wa, 238
	jrl	PdMed_ShowError
PdMed_CheckPlayMode:
	cp	a, 117
	jrl	nz, PdMed_InitFromDisk	; -> 0xF93332
	call	Medley_GetPlaybackStatus
	cp	l, 1:i3
	jrl	nz, PdMed_HandleError	; -> 0xF93315
	ld	(33890:16), 1
	ld	c, (34950:16)
	lda	xwa, (34820:16)
	cp	c, (34948:16)
	jr	nc, PdMed_CheckRepeat	; -> 0xF932AB
	ld	hl, 0:i3
	ld	de, (33792:16)
	cp	de, 0:i3
	jrl	ule, PdMed_Exit	; -> 0xF935BD
PdMed_FindSongLoop:
	ld	ix, hl
	extz	xix
	add	xix, xwa
	cp	(xix), c
	jr	nz, PdMed_NextSong
	extz	xhl
	ld	xwa, xiz
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, xhl
	calr	FmmPdFileNameFunc
	ld	xwa, (33784:16)
	ld	bc, (33792:16)
	calr	PdMed_FormatSlotList
	inc	1, (34950:16)
	ld	xwa, (33788:16)
	or	xwa, xwa
	jrl	z, PdMed_Exit
	ld	xbc, EVT_WAKE_UP_TIME
	ld	xde, 30
	jr	PdMed_PostDelayEvent
PdMed_NextSong:
	inc 1, hl
	cp hl, de
	jr c, PdMed_FindSongLoop
	jrl PdMed_Exit

PdMed_CheckRepeat:
	cp	(0x8888:16), 0
	jr	z, PdMed_ClearPlaying
	ld	(0x8886:16), 0
	ld	hl, 0:i3
	ld	bc, (0x8400:16)
	cp	bc, 0:i3
	jrl	ule, PdMed_Exit
PdMed_RepeatFindLoop:
	ld	de, hl
	extz	xde
	add	xde, xwa
	cp	(xde), 0x0
	jr	nz, PdMed_RepeatNext
	extz	xhl
	ld	xwa, xiz
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, xhl
	calr	FmmPdFileNameFunc
	ld	xwa, (0x83f8:16)
	ld	bc, (0x8400:16)
	calr	PdMed_FormatSlotList
	inc	1, (0x8886:16)
	ld	xwa, (0x83fc:16)
	or	xwa, xwa
	jrl	z, PdMed_Exit
	ld	xbc, EVT_WAKE_UP_TIME
	ld	xde, 0x1e
PdMed_PostDelayEvent:
	call ApPostEvent
	jrl PdMed_Exit

PdMed_RepeatNext:
	inc 1, hl
	cp hl, bc
	jr c, PdMed_RepeatFindLoop
	jrl PdMed_Exit

PdMed_ClearPlaying:
	ld	(33890:16), 0
	jrl	PdMed_Exit
PdMed_HandleError:
	call	Medley_GetPlaybackStatus
	ld	(33890:16), 0
	cp	l, 0:i3
	jrl	z, PdMed_Exit
	ld	(32422:16), 1
	ldw	wa, 238
PdMed_ShowError:
	call SoundCtrl_SendCommand
	jrl PdMed_Exit

PdMed_InitFromDisk_Entry:
PdMed_InitFromDisk:
	cpw	(0x846a:16), 0
	jr	ge, PdMed_InitState
	ld	xwa, 0x600026
	ld	xbc, EVT_SHOW
	ld	xde, 5:i3
	call	ApPostEvent
	call	BuildPageRecordsAlt
	ld	(0x846a:16), hl
	ld	xwa, 0x600026
	ld	xbc, EVT_HIDE
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, 0xffffffff
	ld	xbc, EVT_ALL_PAINT
	ld	xde, 0:i3
	call	ApPostEvent
	call	SignalProgressUpdate
PdMed_InitState:
	ld	(33890:16), 0
	ld	(34950:16), 0
	ld	(34948:16), 0
	ldw	bc, 128
	ld	wa, (33898:16)
	cp	wa, 128
	jr	ugt, PdMed_ClampCount
	ld	bc, wa
PdMed_ClampCount:
	ld	(33792:16), bc
	ld	hl, 0:i3
	cp	bc, 0:i3
	jr	ule, PdMed_FinishInit
	lda	xwa, (34820:16)
PdMed_ClearSlotsLoop:
	ld	bc, hl
	extz	xbc
	add	xbc, xwa
	ld	(xbc), 255
	inc	1, hl
	cp	hl, (33792:16)
	jr	c, PdMed_ClearSlotsLoop	; -> 0xF933A2
PdMed_FinishInit:
	call	CDlike_InitModeAndLoadBank
	ld	xwa, 0:i3
	ld	(33788:16), xwa
	jrl	PdMed_Exit
PdMed_HandleStop:
	ld	a, (35994:16)
	cp	a, 113
	jrl	z, PdMed_Exit
	cp	a, 117
	jrl	z, PdMed_Exit
	call	CDlike_ExitModeAndRestore
	call	CancelOperationCleanup
	ld	(33890:16), 0
	jrl	PdMed_Exit
PdMed_StoreWindowPtr:
	ld	(33784:16), xwa
	jrl	PdMed_Exit
PdMed_RefreshDisplay:
	ld	xwa, (33784:16)
	calr	PdMed_FormatSlotList
	jrl	PdMed_Exit
PdMed_HandleNavToggle:
	cp XHL,0x0000000a
	jrl nz, PdMed_HandleSelectToggle
	cp (0x8462:16), 0x00
	jr nz, PdMed_HandleSelectToggle
	ld hl, 0:i3
	ld WA,BC
	cp bc, 0:i3
	jr ule, PdMed_CheckAllUnmarked
	lda xbc, (0x8804:16)
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
	cp	hl, wa
	jr	nc, PdMed_RemoveOrderLoop
	ld	hl, 0:i3
	cp	wa, 0:i3
	jr	ule, PdMed_RefreshAfterToggle
	lda	xde, (34820:16)
PdMed_AssignOrderLoop:
	ld	bc, hl
	extz	xbc
	add	xbc, xde
	ld	a, (xbc)
	cp	a, 0xff
	jr	nz, PdMed_NextAssign
	ldmi16	(xbc), 0x8884
	inc	1, (0x8884:16)
PdMed_NextAssign:
	inc	1, hl
	cp	hl, (0x8400:16)
	jr	c, PdMed_AssignOrderLoop
	jr	PdMed_RefreshAfterToggle
PdMed_RemoveOrderLoop:
	ld	hl, 0:i3
	cp	wa, 0:i3
	jr	ule, PdMed_RefreshAfterToggle
	lda	xde, (34820:16)
PdMed_UnmarkLoop:
	ld	bc, hl
	extz	xbc
	add	xbc, xde
	ld	a, (xbc)
	cp	a, 253
	jr	ugt, PdMed_NextUnmark
	ld	(xbc), 255
	dec	1, (34948:16)
PdMed_NextUnmark:
	inc	1, hl
	cp	hl, (0x8400:16)
	jr	c, PdMed_UnmarkLoop
PdMed_RefreshAfterToggle:
	ld	xwa, (33784:16)
	ld	bc, (33792:16)
	jr	PdMed_CallFormatSlots
PdMed_HandleSelectToggle:
	cp XHL,0x0000000b
	jr nz, PdMed_HandleRepeat
	cp (0x8462:16), 0x00
	jr nz, PdMed_HandleRepeat
	ld XWA,XIZ
	ld XBC,EVT_GET_SELECTED_FILE_NUMBER
	ld xde, 0:i3
	calr FmmPdFileNameFunc
	lda xix, (0x8804:16)
	extz XHL
	add XHL,XIX
	ld C,(XHL)
	cp C,0xff
	jr nz, PdMed_RemoveFromOrder
	ldmi16	(xhl), 0x8884
	inc	1, (0x8884:16)
	jr	PdMed_RefreshAfterSelect
PdMed_RemoveFromOrder:
	cp	c, 253
	jr	ugt, PdMed_RefreshAfterSelect
	ld	(xhl), 255
	ld	a, (34948:16)
	dec	1, a
	ld	(34948:16), a
	ld	iz, 0:i3
	ld	hl, 0:i3
	extz	wa
	cp	wa, 0:i3
	jr	ule, PdMed_RefreshAfterSelect
	ld	iy, wa
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
	ld	xwa, (33784:16)
	ld	bc, (33792:16)
PdMed_CallFormatSlots:
	calr PdMed_FormatSlotList
	jrl PdMed_Exit

PdMed_HandleRepeat:
	cp	xhl, 12
	jr	nz, PdMed_HandlePlay
	cp	xde, EVT_INDEXSW_UP
	jr	nz, PdMed_SetRepeatOff
	ld	(34952:16), 1
	jrl	PdMed_Exit
PdMed_SetRepeatOff:
	ld	(34952:16), 0
	jrl	PdMed_Exit
PdMed_HandlePlay:
	cp	xhl, 13
	jrl	nz, PdMed_Exit
	cp	(33890:16), 0
	jrl	nz, PdMed_Exit
	ld	(34950:16), 0
	ld	hl, 0:i3
	ld	wa, (33792:16)
	cp	wa, 0:i3
	jr	ule, PdMed_CheckAutoPlay
	lda	xbc, (34820:16)
PdMed_PlayFindLoop:
	ld	de, hl
	extz	xde
	add	xde, xbc
	cp	(xde), 0
	jr	nz, PdMed_PlayNextLoop
	ld	(33890:16), 1
	extz	xhl
	ld	xwa, xiz
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, xhl
	calr	FmmPdFileNameFunc
	inc	1, (34950:16)
	ld	xwa, 4294967295
	ld	xbc, EVT_SET_HOLD
	ld	xde, 0:i3
	call	ApPostEvent
	ldw	wa, 117
	call	UI_PostModeChangeEvent
	jr	PdMed_CheckAutoPlay
PdMed_PlayNextLoop:
	inc 1, hl
	cp hl, wa
	jr c, PdMed_PlayFindLoop

PdMed_CheckAutoPlay:
	cp	(33890:16), 0
	jr	nz, PdMed_Exit
	ld	xwa, 4294967295
	ld	xbc, EVT_SET_HOLD
	ld	xde, 0:i3
	call	ApPostEvent
	ldw	wa, 113
	jr	PdMed_CallPauseMode
PdMed_StoreDelayFlag:
	ld	(33788:16), xwa
	jr	PdMed_Exit
PdMed_CheckContinue:
	cp (0x8462:16), 0x00
	jr z, PdMed_Exit
	ld XWA,0xffffffff
	ld XBC,EVT_SET_HOLD
	ld xde, 0:i3
	call ApPostEvent
	ldw WA, 0x0075
PdMed_CallPauseMode:
	call UI_PostModeChangeEvent

PdMed_Exit:
	ld xhl, 0:i3
	pop xiz
	ret

DocDiskNameFunc_Entry:
DocDiskNameFunc:
	push xiz
	ld xiz, xde
	cp xbc, EVT_PAINT
	jr nz, DocDisk_Exit
	call FileIO_SearchAndLoadFile
	ld ix, 0:i3
	jr DocDisk_CopyLoop

DocDisk_CopyCharLoop:
	cp (xhl), 0x20
	jr z, DocDisk_SkipSpace
	ld de, ix
	inc 1, ix
	ld a, (xhl)
	stb_dri A, 0x07, 0xe4, 0xe8

DocDisk_SkipSpace:
	inc 1, xhl

DocDisk_CopyLoop:
	lda	xbc, (0x86f0:16)
	cp	(xhl), 0x0
	jr	z, DocDisk_TerminateStr
	cp	ix, 0x1e
	jr	lt, DocDisk_CopyCharLoop
DocDisk_TerminateStr:
	ld xde, xbc
	stib_ind 0x07, 0xe4, 0xf0, 0x00
	jr DocDisk_TrimLoop

DocDisk_ClearTrailing:
	ld (xwa), 0x0

DocDisk_TrimLoop:
	dec 1, ix
	lda_dri XWA, 0x07, 0xe8, 0xf0
	cp (xwa), 0x20
	jr nz, DocDisk_PostEvent
	cp ix, 0:i3
	jr gt, DocDisk_ClearTrailing

DocDisk_PostEvent:
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	call ApPostEvent

DocDisk_Exit:
	ld xhl, 0:i3
	pop xiz
	ret

DocMed_FormatFileList:
	dec 6, xsp
	pushw iz
	ld (xsp + 2), bc
	ld (xsp + 4), xwa
	ld iz, 0:i3
DocFmt_FormatLoop:
	ld	de, iz
	sll	de, 5
	lda	xbc, (33904:16)
	extz	xde
	add	xde, xbc
	ldto_berp	a, 248
	ld	(xde), a
	ld	wa, (xsp+2)
	add	wa, iz
	call	FileIO_GetFileEntryWithRefresh
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
	pushw 12
	pushw 0
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
	jr	lt, DocFmt_FormatLoop
	popw	iz
	inc	6, xsp
	ret
FmmDocFileNameFunc:
	dec	4, xsp
	pushw	iz
	ld	(xsp+2), xwa
	cp	xbc, EVT_GET_SELECTED_FILE_NUMBER
	jrl	z, DocName_GetIndexReturn
	ld	wa, (33798:16)
	ld	iz, wa
	cp	xbc, EVT_SET_SELECTED_FILE_NUMBER
	jrl	z, DocName_SetIndexPlaying
	ld	hl, wa
	exts	xhl
	divs	hl, 10
	cp	xbc, EVT_INDEXSW_DOWN
	jr	z, DocName_HandleNavigation
	cp	xbc, EVT_INDEXSW_UP
	jr	z, DocName_HandleNavigation
	cp	xbc, EVT_PAINT
	jr	z, DocName_RefreshList
	cp	xbc, EVT_PS_FILE_NAME_BOX_ID
	jr	nz, DocName_ReturnZero
	ld	(33794:16), xde
	call	FileIO_GetCurrentFileIndex_Alt
	ld	(33798:16), hl
	cp	hl, 0:i3
	jr	ge, DocName_UpdateIndex
	ldw	(33798:16), 0
DocName_UpdateIndex:
	ld	wa, (33798:16)
	exts	xwa
	divs	wa, 10
	ld	de, qwa
	exts	xde
	ld	xwa, (33794:16)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	jrl	DocName_PostEvent
DocName_RefreshList:
	muls	hl, 10
	ld	xwa, (33794:16)
	ld	bc, hl
	calr	DocMed_FormatFileList
DocName_ReturnZero:
	ld xhl, 0:i3
	jrl DocName_Exit

DocName_HandleNavigation:
	or	xde, xde
	jr	nz, DocName_CheckPageUp
	cp	(0x8462:16), 0
	jr	nz, DocName_CheckPageUp
	cp	xbc, EVT_INDEXSW_DOWN
	jr	nz, DocName_CheckPrevKey
	ld	bc, wa
	inc	1, bc
	cp	bc, (0x846c:16)
	jr	ge, DocName_GetCurrentIndex
	inc	1, wa
	jr	DocName_SaveIndex
DocName_CheckPrevKey:
	cp xbc, EVT_INDEXSW_UP
	jr nz, DocName_GetCurrentIndex
	cp wa, 0:i3
	jr le, DocName_GetCurrentIndex
	dec 1, wa
	jr DocName_SaveIndex

DocName_CheckPageUp:
	cp	xde, 0x1
	jr	nz, DocName_CheckPageDown
	cp	(0x8462:16), 0
	jr	nz, DocName_CheckPageDown
	cp	wa, 0xa
	jr	lt, DocName_GetCurrentIndex
	sub	wa, 0xa
	jr	DocName_SaveIndex
DocName_CheckPageDown:
	cp	xde, 0x2
	jr	nz, DocName_GetCurrentIndex
	cp	(0x8462:16), 0
	jr	nz, DocName_GetCurrentIndex
	ld	bc, wa
	add	bc, 0xa
	ld	de, (0x846c:16)
	cp	bc, de
	jr	ge, DocName_CheckEndBound
	add	wa, 0xa
DocName_SaveIndex:
	ld	(33798:16), wa
	jr	DocName_UpdateDisplay
DocName_CheckEndBound:
	ld	bc, de
	dec	1, bc
	ld	wa, bc
	exts	xwa
	divs	wa, 10
	cp	hl, wa
	jr	ge, DocName_GetCurrentIndex
	exts	xde
	divs	de, 10
	ld	wa, qde
	cp	wa, 0:i3
	jr	z, DocName_GetCurrentIndex
	ld	(33798:16), bc
DocName_GetCurrentIndex:
	ld	wa, (33798:16)
DocName_UpdateDisplay:
	cp	iz, wa
	jrl	z, DocName_ReturnZero
	call	FileIO_SelectFileByIndex
	ld	wa, (33798:16)
	exts	xwa
	divs	wa, 10
	ld	de, qwa
	exts	xde
	ld	xwa, (33794:16)
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	call	ApPostEvent
	ld	bc, (33798:16)
	exts	xbc
	divs	bc, 10
	ld	de, iz
	exts	xde
	divs	de, 10
	ld	xwa, (33794:16)
	cp	de, bc
	jr	nz, DocName_RefreshPage
	ld	bc, iz
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
	ld	wa, (33798:16)
	exts	xwa
	divs	wa, 10
	ld	wa, qwa
	sll	wa, 5
	lda	xbc, (33904:16)
	ld	de, wa
	extz	xde
	add	xde, xbc
	ld	xwa, (33794:16)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	jrl	DocName_ReturnZero
DocName_RefreshPage:
	muls bc, 0xa
	calr DocMed_FormatFileList
	ld xwa, (xsp + 2)
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	calr FmmDocMedleyFunc
	jrl DocName_ReturnZero

DocName_SetIndexPlaying:
	cp (0x8462:16), 0x00
	jrl z, DocName_ReturnZero
	ld (0x8406:16), de

	ld wa, de

; call FileIO_SelectFileByIndex (v7 addr)
	call	FileIO_SelectFileByIndex
; ldw_d16 xwa, (0x84a2) (v7 patched)
	ld	wa, (0x8406:16)

	exts xwa

	divs wa, 0xa

	ldto_werp DE, 0xe2

	exts xde

	ld xwa, (33794:16)

	ld xbc, EVT_SET_SELECTED_FILE_NUMBER



DocName_PostEvent:
	call ApPostEvent
	jrl DocName_ReturnZero

DocName_GetIndexReturn:
	ld	hl, (33798:16)
	exts	xhl
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
	ld xwa, 0:i3
	ld xbc, EVT_GET_SELECTED_FILE_NUMBER
	ld xde, 0:i3
	calr FmmDocFileNameFunc
	ldfr_werp HL, 0xfa
	ldto_werp WA, 0xfa
	extz xwa
	div wa, 0xa
	ldfr_werp WA, 0xfa
	mul wa, 0xa
	ldfr_werp WA, 0xfa
	ldw (xsp + 4), 0xa
	ldto_werp WA, 0xfa
	add wa, 0xa
	cp wa, iz
	jr c, DocFmtSlot_CalcVisible
	ld (xsp + 4), iz
	ldto_werp WA, 0xfa
	sub (xsp + 4), wa

DocFmtSlot_CalcVisible:
	ld iz, 0:i3
	cpw (xsp + 4), 0x0
	jr ule, DocFmtSlot_FillEmpty
DocFmtSlot_FormatLoop:
	ld	wa, iz
	sll	wa, 3
	lda	xbc, (33800:16)
	extz	xwa
	add	xwa, xbc
	ld	bc, qiz
	add	bc, iz
	lda	xde, (34820:16)
	extz	xbc
	add	xbc, xde
	ld	c, (xbc)
	extz	bc
	ld	de, iz
	calr	FormatMedleyNumber
	ld	de, iz
	sll	de, 3
	lda	xwa, (33800:16)
	extz	xde
	add	xde, xwa
	ld	xwa, (xsp+6)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	inc	1, iz
	cp	iz, (xsp+0x4)
	jr	c, DocFmtSlot_FormatLoop
DocFmtSlot_FillEmpty:
	cp iz, 0xa
	jr nc, DocFmtSlot_Exit

DocFmtSlot_EmptyLoop:
	ld	wa, iz
	sll	wa, 3
	lda	xbc, (33800:16)
	extz	xwa
	add	xwa, xbc
	ldw	bc, 255
	ld	de, iz
	calr	FormatMedleyNumber
	ld	de, iz
	sll	de, 3
	lda	xwa, (33800:16)
	extz	xde
	add	xde, xwa
	ld	xwa, (xsp+6)
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	inc	1, iz
	cp	iz, 10
	jr	c, DocFmtSlot_EmptyLoop
DocFmtSlot_Exit:
	pop xiz
	inc 6, xsp
	ret

FmmDocMedleyFunc:
	push	xiz
	ld	xhl, xde
	ld	xde, xbc
	ld	xiz, xwa
	cp	xde, EVT_WAKE_UP_NOW
	jrl	z, DocMed_CheckContinue
	ld	xwa, xhl
	cp	xde, EVT_I_WILL_WAKE_UP
	jrl	z, DocMed_StoreDelayFlag
	ld	bc, (33888:16)
	cp	xde, EVT_INDEXSW_DOWN
	jrl	z, DocMed_HandleNavToggle
	cp	xde, EVT_INDEXSW_UP
	jrl	z, DocMed_HandleNavToggle
	cp	xde, EVT_PAINT
	jrl	z, DocMed_RefreshDisplay
	cp	xde, EVT_PS_FILE_NAME_BOX_ID
	jrl	z, DocMed_StoreWindowPtr
	cp	xde, EVT_ACTIVATE_STATE
	jrl	nz, DocMed_Exit
	cp	xhl, 3
	jrl	z, DocMed_HandleStop
	cp	xhl, 2
	jrl	nz, DocMed_Exit
	ld	wa, 0:i3
	call	InitializeOperationState
	ld	a, (35995:16)
	cp	a, 112
	jr	nz, DocMed_CheckPlayMode
	ld	(33890:16), 0
	call	Medley_GetPlaybackStatus
	cp	l, 2:i3
	jrl	c, DocMed_Exit
	ld	(32422:16), 1
	ldw	wa, 238
	jrl	DocMed_ShowError
DocMed_CheckPlayMode:
	cp	a, 116
	jrl	nz, DocMed_CheckInit	; -> 0xF93ADD
	call	Medley_GetPlaybackStatus
	cp	l, 1:i3
	jrl	nz, DocMed_HandleError	; -> 0xF93AC0
	ld	(33890:16), 1
	ld	c, (34950:16)
	lda	xwa, (34820:16)
	cp	c, (34948:16)
	jr	nc, DocMed_CheckRepeat	; -> 0xF93A56
	ld	hl, 0:i3
	ld	de, (33888:16)
	cp	de, 0:i3
	jrl	ule, DocMed_Exit	; -> 0xF93D82
DocMed_FindSongLoop:
	ld	ix, hl
	extz	xix
	add	xix, xwa
	cp	(xix), c
	jr	nz, DocMed_NextSong
	extz	xhl
	ld	xwa, xiz
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, xhl
	calr	FmmDocFileNameFunc
	ld	xwa, (33880:16)
	ld	bc, (33888:16)
	calr	DocMed_FormatSlotList
	inc	1, (34950:16)
	ld	xwa, (33884:16)
	or	xwa, xwa
	jrl	z, DocMed_Exit
	ld	xbc, EVT_WAKE_UP_TIME
	ld	xde, 30
	jr	DocMed_PostDelayEvent
DocMed_NextSong:
	inc 1, hl
	cp hl, de
	jr c, DocMed_FindSongLoop
	jrl DocMed_Exit

DocMed_CheckRepeat:
	cp	(0x8888:16), 0
	jr	z, DocMed_ClearPlaying
	ld	(0x8886:16), 0
	ld	hl, 0:i3
	ld	bc, (0x8460:16)
	cp	bc, 0:i3
	jrl	ule, DocMed_Exit
DocMed_RepeatFindLoop:
	ld	de, hl
	extz	xde
	add	xde, xwa
	cp	(xde), 0x0
	jr	nz, DocMed_RepeatNext
	extz	xhl
	ld	xwa, xiz
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, xhl
	calr	FmmDocFileNameFunc
	ld	xwa, (0x8458:16)
	ld	bc, (0x8460:16)
	calr	DocMed_FormatSlotList
	inc	1, (0x8886:16)
	ld	xwa, (0x845c:16)
	or	xwa, xwa
	jrl	z, DocMed_Exit
	ld	xbc, EVT_WAKE_UP_TIME
	ld	xde, 0x1e
DocMed_PostDelayEvent:
	call ApPostEvent
	jrl DocMed_Exit

DocMed_RepeatNext:
	inc 1, hl
	cp hl, bc
	jr c, DocMed_RepeatFindLoop
	jrl DocMed_Exit

DocMed_ClearPlaying:
	ld	(33890:16), 0
	jrl	DocMed_Exit
DocMed_HandleError:
	call	Medley_GetPlaybackStatus
	ld	(33890:16), 0
	cp	l, 0:i3
	jrl	z, DocMed_Exit
	ld	(32422:16), 1
	ldw	wa, 238
DocMed_ShowError:
	call SoundCtrl_SendCommand
	jrl DocMed_Exit

DocMed_CheckInit_Entry:
DocMed_CheckInit:
	cpw	(33900:16), 0
	jr	lt, DocMed_InitFromDisk
	cpw	(33896:16), 0
	jr	nz, DocMed_InitState
DocMed_InitFromDisk:
	ldw	(33896:16), 65535
	ld	xwa, 6291494
	ld	xbc, EVT_SHOW
	ld	xde, 5:i3
	call	ApPostEvent
	call	FileIO_InitFileNavigation
	ld	(33900:16), hl
	ld	xwa, 6291494
	ld	xbc, EVT_HIDE
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, 4294967295
	ld	xbc, EVT_ALL_PAINT
	ld	xde, 0:i3
	call	ApPostEvent
	call	SignalProgressUpdate
DocMed_InitState:
	ld	(33890:16), 0
	ld	(34950:16), 0
	ld	(34948:16), 0
	ldw	bc, 128
	ld	wa, (33900:16)
	cp	wa, 128
	jr	ugt, DocMed_ClampCount
	ld	bc, wa
DocMed_ClampCount:
	ld	(33888:16), bc
	ld	hl, 0:i3
	cp	bc, 0:i3
	jr	ule, DocMed_FinishInit
	lda	xwa, (34820:16)
DocMed_ClearSlotsLoop:
	ld	bc, hl
	extz	xbc
	add	xbc, xwa
	ld	(xbc), 255
	inc	1, hl
	cp	hl, (33888:16)
	jr	c, DocMed_ClearSlotsLoop	; -> 0xF93B5B
DocMed_FinishInit:
	call	CDlike_InitModeAndLoadBank
	ld	xwa, 0:i3
	ld	(33884:16), xwa
	jrl	DocMed_Exit
DocMed_HandleStop:
	ld	a, (35994:16)
	cp	a, 112
	jrl	z, DocMed_Exit
	cp	a, 116
	jrl	z, DocMed_Exit
	call	CDlike_ExitModeAndRestore
	call	CancelOperationCleanup
	ld	(33890:16), 0
	jrl	DocMed_Exit
DocMed_StoreWindowPtr:
	ld	(33880:16), xwa
	jrl	DocMed_Exit
DocMed_RefreshDisplay:
	ld	xwa, (33880:16)
	calr	DocMed_FormatSlotList
	jrl	DocMed_Exit
DocMed_HandleNavToggle:
	cp XHL,0x0000000a
	jrl nz, DocMed_HandleSelectToggle
	cp (0x8462:16), 0x00
	jr nz, DocMed_HandleSelectToggle
	ld hl, 0:i3
	ld WA,BC
	cp bc, 0:i3
	jr ule, DocMed_CheckAllUnmarked
	lda xbc, (0x8804:16)
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
	cp	hl, wa
	jr	nc, DocMed_RemoveOrderLoop
	ld	hl, 0:i3
	cp	wa, 0:i3
	jr	ule, DocMed_RefreshAfterToggle
	lda	xde, (34820:16)
DocMed_AssignOrderLoop:
	ld	bc, hl
	extz	xbc
	add	xbc, xde
	ld	a, (xbc)
	cp	a, 0xff
	jr	nz, DocMed_NextAssign
	ldmi16	(xbc), 0x8884
	inc	1, (0x8884:16)
DocMed_NextAssign:
	inc	1, hl
	cp	hl, (0x8460:16)
	jr	c, DocMed_AssignOrderLoop
	jr	DocMed_RefreshAfterToggle
DocMed_RemoveOrderLoop:
	ld	hl, 0:i3
	cp	wa, 0:i3
	jr	ule, DocMed_RefreshAfterToggle
	lda	xde, (34820:16)
DocMed_UnmarkLoop:
	ld	bc, hl
	extz	xbc
	add	xbc, xde
	ld	a, (xbc)
	cp	a, 253
	jr	ugt, DocMed_NextUnmark
	ld	(xbc), 255
	dec	1, (34948:16)
DocMed_NextUnmark:
	inc	1, hl
	cp	hl, (0x8460:16)
	jr	c, DocMed_UnmarkLoop
DocMed_RefreshAfterToggle:
	ld	xwa, (33880:16)
	ld	bc, (33888:16)
	jr	DocMed_CallFormatSlots
DocMed_HandleSelectToggle:
	cp XHL,0x0000000b
	jr nz, DocMed_HandleRepeat
	cp (0x8462:16), 0x00
	jr nz, DocMed_HandleRepeat
	ld XWA,XIZ
	ld XBC,EVT_GET_SELECTED_FILE_NUMBER
	ld xde, 0:i3
	calr FmmDocFileNameFunc
	lda xix, (0x8804:16)
	extz XHL
	add XHL,XIX
	ld C,(XHL)
	cp C,0xff
	jr nz, DocMed_RemoveFromOrder
	ldmi16	(xhl), 0x8884
	inc	1, (0x8884:16)
	jr	DocMed_RefreshAfterSelect
DocMed_RemoveFromOrder:
	cp	c, 253
	jr	ugt, DocMed_RefreshAfterSelect
	ld	(xhl), 255
	ld	a, (34948:16)
	dec	1, a
	ld	(34948:16), a
	ld	iz, 0:i3
	ld	hl, 0:i3
	extz	wa
	cp	wa, 0:i3
	jr	ule, DocMed_RefreshAfterSelect
	ld	iy, wa
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
	ld	xwa, (33880:16)
	ld	bc, (33888:16)
DocMed_CallFormatSlots:
	calr DocMed_FormatSlotList
	jrl DocMed_Exit

DocMed_HandleRepeat:
	cp	xhl, 12
	jr	nz, DocMed_HandlePlay
	cp	xde, EVT_INDEXSW_UP
	jr	nz, DocMed_SetRepeatOff
	ld	(34952:16), 1
	jrl	DocMed_Exit
DocMed_SetRepeatOff:
	ld	(34952:16), 0
	jrl	DocMed_Exit
DocMed_HandlePlay:
	cp	xhl, 13
	jrl	nz, DocMed_Exit
	cp	(33890:16), 0
	jrl	nz, DocMed_Exit
	ld	(34950:16), 0
	ld	hl, 0:i3
	ld	wa, (33888:16)
	cp	wa, 0:i3
	jr	ule, DocMed_CheckAutoPlay
	lda	xbc, (34820:16)
DocMed_PlayFindLoop:
	ld	de, hl
	extz	xde
	add	xde, xbc
	cp	(xde), 0
	jr	nz, DocMed_PlayNextLoop
	ld	(33890:16), 1
	extz	xhl
	ld	xwa, xiz
	ld	xbc, EVT_SET_SELECTED_FILE_NUMBER
	ld	xde, xhl
	calr	FmmDocFileNameFunc
	inc	1, (34950:16)
	ld	xwa, 4294967295
	ld	xbc, EVT_SET_HOLD
	ld	xde, 0:i3
	call	ApPostEvent
	ldw	wa, 116
	call	UI_PostModeChangeEvent
	jr	DocMed_CheckAutoPlay
DocMed_PlayNextLoop:
	inc 1, hl
	cp hl, wa
	jr c, DocMed_PlayFindLoop

DocMed_CheckAutoPlay:
	cp	(33890:16), 0
	jr	nz, DocMed_Exit
	ld	xwa, xiz
	ld	xbc, EVT_GET_SELECTED_FILE_NUMBER
	ld	xde, 0:i3
	calr	FmmDocFileNameFunc
	ld	xwa, 4294967295
	ld	xbc, EVT_SET_HOLD
	ld	xde, 0:i3
	call	ApPostEvent
	ldw	wa, 112
	jr	DocMed_CallPauseMode
DocMed_StoreDelayFlag:
	ld	(33884:16), xwa
	jr	DocMed_Exit
DocMed_CheckContinue:
	cp (0x8462:16), 0x00
	jr z, DocMed_Exit
	ld XWA,0xffffffff
	ld XBC,EVT_SET_HOLD
	ld xde, 0:i3
	call ApPostEvent
	ldw WA, 0x0074
DocMed_CallPauseMode:
	call UI_PostModeChangeEvent

DocMed_Exit:
	ld xhl, 0:i3
	pop xiz
	ret

; SetSongSlotValue - Store a value into a song/medley slot
; Entry: WA = slot index (0-9), BC = value to store
; Computes slot address at 0x0AB000 + (index * 2048) + 0x1C
SetSongSlotValue:
	cp wa, 0xa
	ret nc
	lda xhl, (0x0ab000:24)
	ld de, wa
	sll de, 11
	extz xde
	add xhl, xde
	add xhl, 0x1c
	ld (xhl), bc
	ld e, (0x00ffe3:24)
	extz de
	cp de, wa
	ret nz
	lda xhl, (0x00f180:24)
	add xhl, 0x1c
	ld (xhl), bc
	ret

GetSongSlotValue_Entry:
GetSongSlotValue:
	ld hl, 0:i3
	cp wa, 0xa
	ret nc
	lda xbc, (0x0ab000:24)
	sll wa, 11
	extz xwa
	add xbc, xwa
	add xbc, 0x1c
	ld hl, (xbc)
	ret

CheckSongSlotHasData_Entry:
CheckSongSlotHasData:
	calr GetSongSlotValue
	cp hl, 0:i3
	scc16 nz, hl
	ret

SongSlot_RawData_Start:
SongSlot_RawData:
	pushw	iz
	ld	iz, bc
	calr	GetSongSlotValue
	cp	hl, iz
	scc	z, hl
	popw	iz
	ret

FindFirstEmptySlot_Entry:
FindFirstEmptySlot:
	pushw iz
	ld iz, 0:i3

FindEmpty_Loop:
	ld wa, iz
	calr GetSongSlotValue
	cp hl, 0:i3
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
	ldto_werp WA, 0xfa
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
	cp wa, 0:i3
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
	cp hl, 0:i3
	scc16 nz, hl
	ret

SetCurrentSlotIndex_Entry:
SetCurrentSlotIndex:
	ld (0x09480e:24), wa
	ret

GetCurrentSlotIndex_Entry:
GetCurrentSlotIndex:
	ld hl, (0x09480e:24)
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
	cp hl, 0:i3
	scc16 nz, hl
	ret

InitializeCheap:
	lda xsp, (xsp - 0x0e)
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Class
	ld (XBC),XWA
	lda xwa, (ClassProc:24)
	ld (XBC+0x04),XWA
	ld wa, (0xea1186:24)
	ld (XBC+0x08),WA
	lda xwa, (0xea0f46:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0165
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResEvent
	ld (XBC),XWA
	lda xwa, (ResEventProc:24)
	ld (XBC+0x04),XWA
	ld wa, (0xea11f2:24)
	ld (XBC+0x08),WA
	lda xwa, (PtrTbl_EventNames_EA1188:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x01c5
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResMethod
	ld (XBC),XWA
	lda xwa, (ResMethodProc:24)
	ld (XBC+0x04),XWA
	ld wa, (0xea1358:24)
	ld (XBC+0x08),WA
	lda xwa, (0xea11f4:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x01e5
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ApFunction
	ld (XBC),XWA
	lda xwa, (ApFunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x001d
	lda xwa, (0xea0a56:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0125
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ApFunction
	ld (XBC),XWA
	lda xwa, (ApFunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x001d
	lda xwa, (PtrTbl_DiskFuncNames:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0425
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Function
	ld (XBC),XWA
	lda xwa, (FunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x000d
	lda xwa, (0xea135a:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0105
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Function
	ld (XBC),XWA
	lda xwa, (FunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x000d
	lda xwa, (PtrTbl_NakaModuleHandlers:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0405
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_MainFunction
	ld (XBC),XWA
	lda xwa, (MainFunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0039
	lda xwa, (0xea7fce:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0145
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_MainFunction
	ld (XBC),XWA
	lda xwa, (MainFunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0039
	lda xwa, (0xea80b6:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0445
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x004a
	lda xwa, (0xea67b6:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0060
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x004a
	lda xwa, (0xea6fe2:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0360
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0080
	lda xwa, (0xea68e2:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0061
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0080
	lda xwa, (0xea7228:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0361
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda xwa, (0xea6ae6:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0062
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda xwa, (0xea75c6:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0362
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda xwa, (0xea6aea:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0063
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda xwa, (0xea75cc:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0363
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda xwa, (0xea6aee:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0064
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda xwa, (0xea75d2:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0364
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0003
	lda xwa, (0xea6af2:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0065
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0003
	lda xwa, (0xea75d8:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0365
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda xwa, (0xea6b02:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0066
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda xwa, (0xea75fc:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0366
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0047
	lda xwa, (0xea6b06:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0067
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0047
	lda xwa, (0xea7602:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0367
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda xwa, (0xea6c26:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x006a
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda xwa, (0xea77e4:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x036a
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0015
	lda xwa, (0xea6c2a:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x006b
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0015
	lda xwa, (0xea77ea:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x036b
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0053
	lda xwa, (0xea6c82:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x006c
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0053
	lda xwa, (0xea7878:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x036c
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda xwa, (0xea6dd2:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x006d
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda xwa, (0xea7aca:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x036d
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda xwa, (0xea6dd6:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x006e
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda xwa, (0xea7ad0:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x036e
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0015
	lda xwa, (0xea6dda:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0077
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0015
	lda xwa, (0xea7ad6:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0377
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda xwa, (0xea6e32:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0079
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda xwa, (0xea7b8c:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0379
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x005e
	lda xwa, (0xea6e36:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x007b
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x005e
	lda xwa, (0xea7b92:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x037b
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda xwa, (0xea6fb2:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x007c
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda xwa, (0xea7e98:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x037c
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda xwa, (0xea6fb6:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x007d
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda xwa, (0xea7e9e:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x037d
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0008
	lda xwa, (0xea6fba:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x007e
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0008
	lda xwa, (0xea7ea4:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x037e
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda xwa, (0xea6fde:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00bc
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda xwa, (0xea7ee2:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03bc
	call RegisterObjectTable
	pushw 0x0005
	pushw InitializeCheap_Str_MD_DISK@hi16
	pushw InitializeCheap_Str_MD_DISK@lo16
	ld	xwa, 6:i3
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 0x1a00060
	call	RegisterMode
	RegTitle	0x5, InitializeCheap_Str_TT_DKMENU, 0x60, 0x1200000, 0x600000
	RegTitle	0x5, InitializeCheap_Str_TT_DKLD, 0x61, 0x1450027, 0x610000
	RegTitle	0x5, InitializeCheap_Str_TT_CMPLDSNGL, 0x62, 0x1450036, 0x610069
	RegTitle	0x5, InitializeCheap_Str_TT_DKWPLD, 0x63, 0x1450037, 0x60002b
	RegTitle	0x5, InitializeCheap_Str_TT_DKLDSMF, 0x64, 0x1450029, 0x61004b
	RegTitle	0x5, InitializeCheap_Str_TT_DKSVMENU, 0x65, 0x1200000, 0x650000
	RegTitle	0x5, InitializeCheap_Str_TT_DKSVNAME, 0x66, 0x1200000, 0x600018
	RegTitle	0x5, InitializeCheap_Str_TT_DKSV, 0x67, 0x1450028, 0x670000
	RegTitle	0x5, InitializeCheap_Str_TT_DKSVNAMESMF, 0x6a, 0x1200000, 0x600028
	RegTitle	0x5, InitializeCheap_Str_TT_DKSVSMF, 0x6b, 0x145002d, 0x6b0000
	RegTitle	0x5, InitializeCheap_Str_TT_DKDPSMF, 0x6c, 0x145001c, 0x6c0000
	RegTitle	0x5, InitializeCheap_Str_TT_DKDPDOC, 0x6d, 0x145001e, 0x6c0026
	RegTitle	0x5, InitializeCheap_Str_TT_DKDPPD, 0x6e, 0x145001d, 0x6c003d
	RegTitle	0x5, InitializeCheap_Str_TT_DKMDLY, 0x77, 0x1450026, 0x770000
	RegTitle	0x5, InitializeCheap_Str_TT_SQMDLY, 0x79, 0x1450011, 0x60000a
	RegTitle	0x5, InitializeCheap_Str_TT_DKUT, 0x7b, 0x1450031, 0x7b0000
	RegTitle	0x5, InitializeCheap_Str_TT_DKUTSMF, 0x7c, 0x1450032, 0x7b0019
	RegTitle	0x5, InitializeCheap_Str_TT_DKUTFRMT, 0x7d, 0x1450021, 0x7b0018
	RegTitle	0x5, InitializeCheap_Str_TT_DKSETUP, 0x7e, 0x1200000, 0x7e0000
	RegTitle	0x5, InitializeCheap_Str_TT_CMPLD, 0xbc, 0x1450025, 0x60001b
	lda	xsp, (xsp + 14)
	ret
PasswordText:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, PasswordText_Exit
	lda xhl, (PasswordText_PtrTable:24)
	ret

PasswordText_Exit:
	ld xhl, 0:i3
	ret

CheckPasswordText:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, CheckPwd_Exit
	ld a, (0x02748e:24)
	cp a, 2:i3
	jr z, CheckPwd_Type2
	cp a, 1:i3
	jr nz, CheckPwd_Type0
	ld xhl, CheckPasswordText_PtrTable
	jr CheckPwd_Return

CheckPwd_Type2:
	ld xhl, CheckPwd_Type2_PtrTable
	jr CheckPwd_Return

CheckPwd_Type0:
	ld xhl, CheckPwd_Type0_PtrTable

CheckPwd_Return:
	ret

CheckPwd_Exit:
	ld xhl, 0:i3
	ret

WakeUpPassword:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xwa
	cp xbc, EVT_WAKEUP_PASSWORD
	jrl z, WakeUp_StoreType
	cp xbc, EVT_SW_IN
	jr z, WakeUp_HandleOk
	cp xbc, EVT_SHOW
	jr z, WakeUp_HandleInit
	cp xbc, EVT_DRAW
	jr z, WakeUp_HandleDirect
	cp xbc, EVT_ARE_YOU_CLASS_PROC
	jr z, WakeUp_Return1
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	jrl WakeUp_Exit

WakeUp_Return1:
	ld xhl, 1:i3
	jrl WakeUp_Exit

WakeUp_HandleDirect:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	ld xde, WakeUp_HandleDirect_Str_CcEv
	call SendEvent
	jrl WakeUp_ReturnZero

WakeUp_HandleInit:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld (0x02741a:24), 0x00
	jrl WakeUp_ReturnZero

WakeUp_HandleOk:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, 0x670001
	ld xbc, EVT_GET_PAGE_NOW
	ld xde, 0:i3
	call SendEvent
	cp xhl, 0x3
	jr z, WakeUp_ReturnZero
	ld xwa, (xsp + 4)
	cp xwa, 0x8c
	jr nz, WakeUp_ClearCounter
	inc 1, (0x02741a:24)
	cp (0x02741a:24), 0x07
	jr nz, WakeUp_ReturnZero
	ld (0x02741a:24), 0x00
	ld xwa, 0xffffffff
	ld xbc, EVT_NOT_PARA_DRAW
	ld xde, 1:i3
	call PostEvent
	ld xwa, 0x600040
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	jr WakeUp_PostEvent

WakeUp_ClearCounter:
	ld (0x02741a:24), 0x00
	jr WakeUp_ReturnZero

WakeUp_StoreType:
	ld xwa, (xsp + 4)
	ld (0x02748e:24), a
	ld xwa, 0xffffffff
	ld xbc, EVT_NOT_PARA_DRAW
	ld xde, 1:i3
	call PostEvent
	ld xwa, 0x600045
	ld xbc, EVT_SHOW
	ld xde, 0:i3

WakeUp_PostEvent:
	call PostEvent

WakeUp_ReturnZero:
	ld xhl, 0:i3

WakeUp_Exit:
	pop xiz
	inc 4, xsp
	ret

PasswordOk:
	push	xiz
	ld	xiz, xwa
	cp	xbc, EVT_SW_IN
	jr	z, PwdOk_HandleConfirm
	cp	xbc, EVT_GET_STRING_LENGTH
	jr	z, PwdOk_Return2
	cp	xbc, EVT_GET_NAMING_MODE
	jr	z, PwdOk_ReturnZero
	cp	xbc, EVT_GET_STRING
	jr	nz, PwdOk_ReturnZero
	pushw	PasswordOk_Str_Query_Query@hi16
	pushw	PasswordOk_Str_Query_Query@lo16
	push	xde
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, xiz
	jr	PwdOk_Exit
PwdOk_Return2:
	ld xhl, 2:i3
	jr PwdOk_Exit

PwdOk_HandleConfirm:
	call GetNamingWindowID
	ld xwa, xhl
	ld xbc, EVT_GET_STRING
	ld xde, 0x2741c
	call SendEvent
	ld xwa, 0x600040
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_NOT_PARA_DRAW
	ld xde, 0:i3
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_ALL_PAINT
	ld xde, 0:i3
	call PostEvent
	ld de, (0x02741c:24)
	extz xde
	ld xwa, NAKA_MAINFUNC_FmmPasswordFunc
	ld xbc, EVT_SET_PASSWORD
	call MainFuncCall

PwdOk_ReturnZero:
	ld xhl, 0:i3

PwdOk_Exit:
	pop xiz
	ret

CheckPasswordOk:
	push	xiz
	ld	xiz, xwa
	cp	xbc, EVT_SW_IN
	jr	z, CheckOk_HandleConfirm
	cp	xbc, EVT_GET_STRING_LENGTH
	jr	z, CheckOk_Return2
	cp	xbc, EVT_GET_NAMING_MODE
	jrl	z, CheckOk_ReturnZero
	cp	xbc, EVT_GET_STRING
	jrl	nz, CheckOk_ReturnZero
	pushw	CheckPasswordOk_Str_Query_Query@hi16
	pushw	CheckPasswordOk_Str_Query_Query@lo16
	push	xde
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, xiz
	jrl	CheckOk_Exit
CheckOk_Return2:
	ld xhl, 2:i3
	jrl CheckOk_Exit

CheckOk_HandleConfirm:
	call GetNamingWindowID
	ld xwa, xhl
	ld xbc, EVT_GET_STRING
	ld xde, 0x27424
	call SendEvent
	ld xwa, 0x600045
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_NOT_PARA_DRAW
	ld xde, 0:i3
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_ALL_PAINT
	ld xde, 0:i3
	call PostEvent
	ld xwa, 0x670001
	ld xbc, EVT_GET_PAGE_NOW
	ld xde, 0:i3
	call SendEvent
	lda xwa, (0x027424:24)
	cp hl, 1:i3
	jr nz, CheckOk_Type2
	ld de, (xwa)
	extz xde
	ld xwa, NAKA_MAINFUNC_FmmPasswordFunc
	ld xbc, EVT_CHECK_PASSWORD
	jr CheckOk_CallFunc

CheckOk_Type2:
	cp hl, 2:i3
	jr nz, CheckOk_Type3
	ld de, (xwa)
	extz xde
	ld xwa, NAKA_MAINFUNC_FmmPasswordFunc
	ld xbc, EVT_CHECK_PASSWORD2
	jr CheckOk_CallFunc

CheckOk_Type3:
	cp hl, 3:i3
	jr nz, CheckOk_ReturnZero
	ld de, (xwa)
	extz xde
	ld xwa, NAKA_MAINFUNC_FmmPasswordFunc
	ld xbc, EVT_CHECK_PASSWORD3

CheckOk_CallFunc:
	call MainFuncCall

CheckOk_ReturnZero:
	ld xhl, 0:i3

CheckOk_Exit:
	pop xiz
	ret

PasswordNo:
	cp xbc, EVT_SW_IN
	jr nz, PwdNo_Exit
	ld xwa, 0x600040
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_NOT_PARA_DRAW
	ld xde, 0:i3
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_ALL_PAINT
	ld xde, 0:i3
	call PostEvent

PwdNo_Exit:
	ld xhl, 0:i3
	ret

CheckPasswordNo:
	cp xbc, EVT_SW_IN
	jr nz, CheckNo_HandleConfirm
	ld xwa, 0x600045
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_NOT_PARA_DRAW
	ld xde, 0:i3
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_ALL_PAINT
	ld xde, 0:i3
	call PostEvent

CheckNo_HandleConfirm:
	ld xhl, 0:i3
	ret

DiskAttention:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, CheckNo_Type1
	lda xhl, (DiskAttention_PtrTable:24)
	ret

CheckNo_Type1:
	ld xhl, 0:i3
	ret

DiskSure:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, CheckNo_Type2
	lda xhl, (DiskSure_PtrTable:24)
	ret

CheckNo_Type2:
	ld xhl, 0:i3
	ret

FormatText:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, CheckNo_Type3
	lda xhl, (FormatText_PtrTable:24)
	ret

CheckNo_Type3:
	ld xhl, 0:i3
	ret

DeleteText:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, CheckNo_CallFunc
	lda xhl, (DeleteText_PtrTable:24)
	ret

CheckNo_CallFunc:
	ld xhl, 0:i3
	ret

DeleteYes:
	cp xbc, EVT_SW_IN
	jr nz, PwdChange_HandleOk
	ld xwa, 0x7b0051
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_NOT_PARA_DRAW
	ld xde, 0:i3
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_ALL_PAINT
	ld xde, 0:i3
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEXSW_UP
	ld xde, 0x33
	call PostEvent

PwdChange_HandleOk:
	ld xhl, 0:i3
	ret

DeleteNo:
	cp xbc, EVT_SW_IN
	jr nz, PwdChange_Type1
	ld xwa, 0x7b0051
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_NOT_PARA_DRAW
	ld xde, 0:i3
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_ALL_PAINT
	ld xde, 0:i3
	call PostEvent

PwdChange_Type1:
	ld xhl, 0:i3
	ret

SaveText:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, PwdChange_CallFunc
	lda xhl, (SaveText_PtrTable:24)
	ret

PwdChange_CallFunc:
	ld xhl, 0:i3
	ret

SaveYes:
	cp xbc, EVT_SW_IN
	jr nz, PwdDel_HandleOk
	ld xwa, 0x600037
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_NOT_PARA_DRAW
	ld xde, 0:i3
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_ALL_PAINT
	ld xde, 0:i3
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEXSW_UP
	ld xde, 0x32
	call PostEvent

PwdDel_HandleOk:
	ld xhl, 0:i3
	ret

SaveNo:
	cp xbc, EVT_SW_IN
	jr nz, PwdDel_Type1
	ld xwa, 0x600037
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_NOT_PARA_DRAW
	ld xde, 0:i3
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_ALL_PAINT
	ld xde, 0:i3
	call PostEvent

PwdDel_Type1:
	ld xhl, 0:i3
	ret

InsertOptionText:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, PwdDel_Type2
	lda xhl, (InsertOptionText_PtrTable:24)
	ret

PwdDel_Type2:
	ld xhl, 0:i3
	ret

TypePriorityText:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, PwdDel_CallFunc
	lda xhl, (TypePriorityText_PtrTable:24)
	ret

PwdDel_CallFunc:
	ld xhl, 0:i3
	ret

