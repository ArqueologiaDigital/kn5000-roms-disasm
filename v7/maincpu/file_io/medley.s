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
	cp XBC,0x01e50003
	jrl z, SeqName_GetIndexReturn
	ldw_d16 hl, (0x823c)
	cp XBC,0x01e50002
	jrl z, SeqName_SetIndexPlaying
	cp XBC,0x01c00018
	jr z, SeqName_HandleNavigation
	cp XBC,0x01c00017
	jr z, SeqName_HandleNavigation
	cp XBC,0x01c0000b
	jr z, SeqName_InitAllSlots
	cp XBC,0x01e50004
	jr nz, SeqName_ReturnZero
	stda32 (0x8238), xde
	cpdi8 (0x8462), 0x00
	jr nz, SeqName_SendCurrentIndex
	stdi16 (0x823c), 0x0000
SeqName_SendCurrentIndex:
	ldw_d16	de, (33340)
	extz	xde
	ldda32	xwa, (33336)
	ld	xbc, 31784962
	jrl	517
SeqName_InitAllSlots:
	lds iz, 0

SeqName_SendSlotLoop:
	ld	bc, iz
	ld	wa, bc
	lds	de, 1
	calr	65315
	ld	xde, xhl
	ldda32	xwa, (33336)
	ld	xbc, 29360143
	call	16423243
	inc	1, iz
	cp	iz, 10
	jr	lt, -32
SeqName_ReturnZero:
	lds32 xhl, 0
	jrl SeqName_Exit

SeqName_HandleNavigation:
	ld	wa, hl
	ld	iz, hl
	or	xde, xde
	jr	nz, 51
	cpdi8	33890, 0
	jr	nz, 44
	cp	xbc, 29360152
	jr	nz, 11
	cp	wa, 9
	jrl	nc, 301
	inc	1, wa
	jr	16
SeqName_CheckPrevKey:
	cp xbc, 0x1c00017
	jrl nz, SeqName_GetCurrentIndex
	cps wa, 0
	jrl z, SeqName_GetCurrentIndex
	dec 1, wa

SeqName_UpdateIndex:
	stda16	(33340), wa
	ld	de, wa
	jrl	276
SeqName_HandlePlayAction:
	.byte 0xea, 0xcf, 0x04, 0x00, 0x00, 0x00, 0x7e, 0xad
	.byte 0x00, 0xc1, 0x62, 0x84, 0x3f, 0x00, 0x7e, 0xa5
	.byte 0x00, 0x1d, 0xd8, 0x3d, 0xf9, 0xcf, 0xd8, 0x66
	.byte 0x1a, 0xf1, 0x70, 0x89, 0x30, 0xb8, 0x01, 0xcf
	.byte 0x6e, 0x11, 0xb0, 0x00, 0x01, 0xea, 0xa9, 0x40
	.byte 0xff, 0xff, 0xff, 0xff, 0x41, 0x04, 0x00, 0xc5
	.byte 0x01, 0x68, 0x2c
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
	ld	xwa, 6291494
	ld	xbc, 29360129
	lds32	xde, 5
	call	16423243
	lds	wa, 0
	calr	38514
	ldw_d16	wa, (33340)
	call	16284832
	ld	wa, hl
	lds	bc, 5
	calr	39149
	stb_d8	(32422), l
	call	16290139
	call	16290094
	call	16290928
	stda16	(33894), hl
	calr	38568
	ld	xwa, 6291494
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	ldw	wa, 238
	jr	86
SeqName_HandleAction32:
	cp	xde, 50
	jr	nz, 82
	ld	xwa, 6291494
	ld	xbc, 29360129
	lds32	xde, 5
	call	16423243
	lds	wa, 0
	calr	38426
	ldw_d16	wa, (33340)
	call	16284832
	ld	wa, hl
	lds	bc, 5
	calr	39061
	stb_d8	(32422), l
	call	16290139
	call	16290094
	call	16290928
	stda16	(33894), hl
	calr	38480
	ld	xwa, 6291494
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	ldw	wa, 238
SeqName_ShowAndExit:
	call SoundCtrl_SendCommand

SeqName_GetCurrentIndex:
	ldw_d16	de, (33340)
SeqName_UpdateDisplay:
	cp	iz, de
	jrl	z, -345
	extz	xde
	ldda32	xwa, (33336)
	ld	xbc, 31784962
	call	16423243
	ld	wa, iz
	ld	bc, iz
	lds	de, 1
	calr	64923
	ld	xde, xhl
	ldda32	xwa, (33336)
	ld	xbc, 29360143
	call	16423243
	ldw_d16	bc, (33340)
	ld	wa, bc
	lds	de, 1
	calr	64897
	ld	xde, xhl
	ldda32	xwa, (33336)
	ld	xbc, 29360143
	jr	75
SeqName_SetIndexPlaying:
	cpdi8 (0x8462), 0x00
	jrl z, SeqName_ReturnZero
	ld IZ,HL
	stda16 (0x823c), de
	extz XDE
	ldda32 xwa, (0x8238)
	ld XBC,0x01e50002
	call ApPostEvent
	ld WA,IZ
	ld BC,IZ
	lds de, 1
	calr BuildSlotLabel
	ld XDE,XHL
	ldda32 xwa, (0x8238)
	ld XBC,0x01c0000f
	call ApPostEvent
	ldw_d16 bc, (0x823c)
	ld WA,BC
	lds de, 1
	calr BuildSlotLabel
	ld XDE,XHL
	ldda32 xwa, (0x8238)
	ld XBC,0x01c0000f
SeqName_PostEventExit:
	call ApPostEvent
	jrl SeqName_ReturnZero

SeqName_GetIndexReturn:
	ldw_d16	hl, (33340)
	extz	xhl
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
	dec 0,XSP
	pushw iz
	ld (XSP+0x06),XWA
	cp XBC,0x01e5000a
	jrl z, IntMed_CheckContinue
	ld XWA,XDE
	cp XBC,0x01e50008
	jrl z, IntMed_StoreDelayFlag
	cp XBC,0x01c00018
	jrl z, IntMed_HandleNavToggle
	cp XBC,0x01c00017
	jrl z, IntMed_HandleNavToggle
	cp XBC,0x01c0000b
	jrl z, IntMed_InitSlotDisplay
	cp XBC,0x01e50004
	jrl z, IntMed_StoreWindowPtr
	cp XBC,0x01c00013
	jrl nz, IntMed_Exit
	cp XDE,0x00000003
	jrl z, IntMed_HandleStop
	cp XDE,0x00000002
	jrl nz, IntMed_Exit
	cpdi8 (0x8c9b), 0x7a
	jr z, IntMed_CheckPlaying
	call CDlike_InitModeAndLoadBank
	stdi8 (0x8462), 0x00
	stdi8 (0x8800), 0x00
	stdi8 (0x87fe), 0x00
	lds iz, 0
IntMed_CheckSlotLoop:
	ld_erpb_rr a, 0xf8
	extz WA
	call SongBank_ScanActiveVoices
	cps l, 0
	jr z, IntMed_MarkSlotEmpty
	lda_d16 xwa, (0x87f4)
	ld BC,IZ
	extz XBC
	add XBC,XWA
	.byte 0xb1, 0x14, 0xfe, 0x87, 0xc1, 0xfe, 0x87, 0x61
	.byte 0x68, 0x0d
IntMed_MarkSlotEmpty:
	lda_d16	xwa, (34804)
	ld	bc, iz
	extz	xbc
	add	xbc, xwa
	ld	(xbc), 255
IntMed_NextSlot:
	inc	1, iz
	cp	iz, 10
	jr	c, -54
	lds32	xwa, 0
	stda32	(33346), xwa
	jrl	990
IntMed_CheckPlaying:
	call	15861571
	cps	l, 1
	jrl	nz, 193
	stdi8	33890, 1
	ldb_d8	a, 34816
	cpda8	a, 34814
	jr	nc, 76
	lds	iz, 0
	lda_d16	xbc, 34804
IntMed_FindCurrentSong:
	ld	de, iz
	extz	xde
	add	xde, xbc
	cp	(xde), a
	jr	nz, 49
	ld	de, iz
	extz	xde
	ld	xwa, (xsp+6)
	ld	xbc, 31784962
	calr	-965
	stb_erp	a, 248
	extz	wa
	call	15862692
	incdi8	1, (34816)
	ldda32	xwa, 33346
	or	xwa, xwa
	jrl	z, 913
	ld	xbc, 31784969
	ld	xde, 30
	jr	87
IntMed_NextSongSearch:
	inc 1, iz
	cp iz, 0xa
	jr c, IntMed_FindCurrentSong
	jrl IntMed_Exit
IntMed_CheckRepeat:
	cpdi8	34818, 0
	jr	z, 87
	stdi8	34816, 0
	lds	iz, 0
	lda_d16	xwa, 34804
IntMed_PlayFromStart:
	ld	bc, iz
	extz	xbc
	add	xbc, xwa
	.byte 0x81, 0x3f, 0x00
	jr	nz, 54
	ld	de, iz
	extz	xde
	ld	xwa, (xsp+6)
	ld	xbc, 31784962
	calr	-1054
	stb_erp	a, 248
	extz	wa
	call	15862692
	incdi8	1, (34816)
	ldda32	xwa, 33346
	or	xwa, xwa
	jrl	z, 824
	ld	xbc, 31784969
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
	stdi8	(33890), 0
	jrl	788
IntMed_HandleError:
	call	15861571
	stdi8	(33890), 0
	cps	l, 0
	jrl	z, 774
	stdi8	(32422), 14
	ldw	wa, 238
	call	16355504
	jrl	759
IntMed_HandleStop:
	cpdi8 (0x8c9a), 0x7a
	jrl z, IntMed_Exit
	call CDlike_ExitModeAndRestore
	stdi8 (0x8462), 0x00
	jrl t, IntMed_Exit



IntMed_StoreWindowPtr:
	stda32	(33342), xwa
	jrl	732
IntMed_InitSlotDisplay:
	lds iz, 0

IntMed_FormatSlotLoop:
	ld	wa, iz
	sll	wa, 3
	lda_d16	xbc, (33350)
	extz	xwa
	add	xwa, xbc
	lda_d16	xbc, (34804)
	ld	de, iz
	extz	xde
	add	xde, xbc
	ld	c, (xde)
	extz	bc
	ld	de, iz
	calr	64956
	ld	de, iz
	sll	de, 3
	lda_d16	xwa, (33350)
	extz	xde
	add	xde, xwa
	ldda32	xwa, (33342)
	ld	xbc, 29360143
	call	16423243
	inc	1, iz
	cp	iz, 10
	jr	c, -66
	jrl	661
IntMed_HandleNavToggle:
	lda_d16 xwa, (0x87f4)
	cp XDE,0x0000000a
	jrl nz, IntMed_HandleSelectToggle
	cpdi8 (0x8462), 0x00
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
	lda_d16	xwa, (34804)
	ld	bc, iz
	extz	xbc
	add	xbc, xwa
	ld	a, (xbc)
	cp	a, 254
	jr	nz, 58
	ldb_d8	a, (34814)
	ld	(xbc), a
	incdi8	1, (34814)
	ld	wa, iz
	sll	wa, 3
	lda_d16	xde, (33350)
	extz	xwa
	add	xwa, xde
	ld	c, (xbc)
	extz	bc
	ld	de, iz
	calr	64820
	ld	de, iz
	sll	de, 3
	lda_d16	xwa, (33350)
	extz	xde
	add	xde, xwa
	ldda32	xwa, (33342)
	ld	xbc, 29360143
	call	16423243
IntMed_NextAssignSlot:
	inc 1, iz
	cp iz, 0xa
	jr c, IntMed_AssignOrderLoop
	jrl IntMed_Exit

IntMed_RemoveOrderLoop:
	lds iz, 0

IntMed_UnmarkSlotLoop:
	lda_d16	xwa, (34804)
	ld	bc, iz
	extz	xbc
	add	xbc, xwa
	ld	a, (xbc)
	cp	a, 253
	jr	ugt, 55
	ld	(xbc), 254
	decdi8	1, (34814)
	ld	wa, iz
	sll	wa, 3
	lda_d16	xde, (33350)
	extz	xwa
	add	xwa, xde
	ld	c, (xbc)
	extz	bc
	ld	de, iz
	calr	64735
	ld	de, iz
	sll	de, 3
	lda_d16	xwa, (33350)
	extz	xde
	add	xde, xwa
	ldda32	xwa, (33342)
	ld	xbc, 29360143
	call	16423243
IntMed_NextUnmark:
	inc 1, iz
	cp iz, 0xa
	jr c, IntMed_UnmarkSlotLoop
	jrl IntMed_Exit

IntMed_HandleSelectToggle:
	cp XDE,0x0000000b
	jrl nz, IntMed_HandleRepeatToggle
	cpdi8 (0x8462), 0x00
	jrl nz, IntMed_HandleRepeatToggle
	ld XWA,(XSP+0x06)
	ld XBC,0x01e50003
	lds32 xde, 0
	calr FmmSeqSongNameFunc
	ld IZ,HL
	lda_d16 xwa, (0x87f4)
	ld DE,IZ
	extz XDE
	add XDE,XWA
	lda_d16 xbc, (0x8246)
	ld WA,IZ
	sll WA, 0x03
	extz XWA
	add XWA,XBC
	ld C,(XDE)
	cp C,0xfe
	jr nz, .Lc_f91c70
	ldb_d8 c, (0x87fe)
	ld (XDE),C
	incdi8 1, 0x87fe
	ld C,(XDE)
	extz BC
	ld DE,IZ
	calr FormatMedleyNumber
	ld DE,IZ
	sll DE, 0x03
	lda_d16 xbc, (0x8246)
	extz XDE
	add XDE,XBC
	ldda32 xwa, (0x823e)
	ld XBC,0x01c0000f
	call ApPostEvent
	jrl t, IntMed_Exit
IntMed_RemoveFromOrder:
.Lc_f91c70:
	cp C,0xfd
	jrl ugt, IntMed_Exit
	ld (XSP+0x04),C
	ld (XDE),0xfe
	decdi8 1, 0x87fe
	ld C,(XDE)
	extz BC
	ld DE,IZ
	calr FormatMedleyNumber
	ld DE,IZ
	sll DE, 0x03
	lda_d16 xbc, (0x8246)
	extz XDE
	add XDE,XBC
	ldda32 xwa, (0x823e)
	ld XBC,0x01c0000f
	call ApPostEvent
	ldw (XSP+0x02), 0x0000
	lds iz, 0
	ldb_d8 a, (0x87fe)
	extz WA
	cps wa, 0
	jrl ule, IntMed_Exit
IntMed_ReorderLoop:
	lda_d16 xwa, (0x87f4)
	ld DE,IZ
	extz XDE
	add XDE,XWA
	ld C,(XDE)
	cp C,0xfd
	jr ugt, IntMed_NextReorder
	.byte 0x9f, 0x02, 0x61, 0x8f, 0x04, 0xf3, 0x63, 0x32
	.byte 0xcb, 0x69, 0xb2, 0x43, 0xde, 0x88, 0xd8, 0xee
	.byte 0x03, 0xf1, 0x46, 0x82, 0x32, 0xe8, 0x12, 0xea
	.byte 0x80, 0xd9, 0x12, 0xde, 0x8a, 0x1e, 0xd6, 0xfb
	.byte 0xde, 0x8a, 0xda, 0xee, 0x03, 0xf1, 0x46, 0x82
	.byte 0x30, 0xea, 0x12, 0xe8, 0x82, 0xe1, 0x3e, 0x82
	.byte 0x20, 0x41, 0x0f, 0x00, 0xc0, 0x01, 0x1d, 0x4b
	.byte 0x99, 0xfa
IntMed_NextReorder:
	inc	1, iz
	ldb_d8	a, (34814)
	extz	wa
	cp	(xsp+2), wa
	jr	c, -88
	jrl	170
IntMed_HandleRepeatToggle:
	cp	xde, 12
	jr	nz, 24
	cp	xbc, 29360151
	jr	nz, 8
	stdi8	(34818), 1
	jrl	146
IntMed_SetRepeatOff:
	stdi8	(34818), 0
	jrl	138
IntMed_HandlePlay:
	cp	xde, 13
	jrl	nz, 129
	cpdi8	33890, 0
	jr	nz, 122
	stdi8	34816, 0
	lds	iz, 0
IntMed_StartPlayLoop:
	ld	bc, iz
	extz	xbc
	add	xbc, xwa
	.byte 0x81, 0x3f, 0x00
	jr	nz, 58
	stdi8	33890, 1
	ld	de, iz
	extz	xde
	ld	xwa, (xsp+6)
	ld	xbc, 31784962
	calr	-1816
	stb_erp	a, 248
	extz	wa
	call	15862692
	incdi8	1, (34816)
	ld	xwa, 4294967295
	ld	xbc, 31457434
	lds32	xde, 0
	call	16423243
	ldw	wa, 122
	call	16355459
	jr	46
IntMed_NextPlaySlot:
	inc 1, iz
	cp iz, 0xa
	jr c, IntMed_StartPlayLoop
	jr IntMed_Exit

IntMed_StoreDelayFlag:
	stda32	(33346), xwa
	jr	30
IntMed_CheckContinue:
	cpdi8 (0x8462), 0x00
	jr z, IntMed_Exit
	ld XWA,0xffffffff
	ld XBC,0x01e0009a
	lds32 xde, 0
	call ApPostEvent
	ldw WA, 0x007a
	call UI_PostModeChangeEvent
IntMed_Exit:
	lds32 xhl, 0
	popw iz
	inc 8, xsp
	ret

FmmDiskMedley1Func:
	pushw	iz
	cp	xbc, 29360139
	jr	z, 14
	cp	xbc, 31784964
	jr	nz, 74
	stda32	(33430), xde
	jr	68
DiskMed1_InitLoop:
	lds iz, 0

DiskMed1_FormatLoop:
	ld	wa, iz
	sll	wa, 3
	lda_d16	xbc, (33434)
	extz	xwa
	add	xwa, xbc
	lda_d16	xbc, (34954)
	ld	de, iz
	extz	xde
	add	xde, xbc
	ld	c, (xde)
	extz	bc
	ld	de, iz
	calr	64195
	ld	de, iz
	sll	de, 3
	lda_d16	xwa, (33434)
	extz	xde
	add	xde, xwa
	ldda32	xwa, (33430)
	ld	xbc, 29360143
	call	16423243
	inc	1, iz
	cp	iz, 10
	jr	c, -66
DiskMed1_Exit:
	lds32 xhl, 0
	popw iz
	ret

FmmDiskMedley2Func:
	pushw	iz
	cp	xbc, 29360139
	jr	z, 14
	cp	xbc, 31784964
	jr	nz, 83
	stda32	(33514), xde
	jr	77
DiskMed2_InitLoop:
	ldw iz, 0xa

DiskMed2_FormatLoop:
	ld	wa, iz
	sll	wa, 3
	lda_24	xbc, (33438)
	extz	xwa
	add	xwa, xbc
	lda_d16	xbc, (34954)
	ld	de, iz
	extz	xde
	add	xde, xbc
	ld	c, (xde)
	extz	bc
	ld	de, iz
	sub	de, 10
	calr	64094
	ld	wa, iz
	sll	wa, 3
	lda_24	xbc, (33438)
	ld	de, wa
	extz	xde
	add	xde, xbc
	ldda32	xwa, (33514)
	ld	xbc, 29360143
	call	16423243
	inc	1, iz
	cp	iz, 20
	jr	c, -74
DiskMed2_Exit:
	lds32 xhl, 0
	popw iz
	ret

DiskMed_PlayNextHelper:
	pushw iz
	cp XBC,0x01c00018
	jr z, DiskMed_InitPlayOrder
	cp XBC,0x01c00017
	jr z, DiskMed_InitPlayOrder
	cp XBC,0x01c00013
	jrl nz, DiskMed_ReturnZero
	cp XDE,0x00000003
	jrl z, DiskMed_ReturnZero
	cp XDE,0x00000002
	jrl nz, DiskMed_ReturnZero
	cpdi8 (0x8462), 0x00
	jrl z, DiskMed_ReturnZero
	ldb_d8 a, (0x8800)
	cpda8 a, (0x87fe)
	jr nc, DiskMed_ReturnFinished
	lds iz, 0
	lda_d16 xbc, (0x87f4)
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
	cp	xde, 13
	jrl	nz, 184
	stdi8	(34816), 0
	stdi8	(34814), 0
	stdi8	(34818), 0
	lds	iz, 0
DiskMed_CheckSlotLoop:
	stb_erp	a, 248
	extz	wa
	call	15861296
	lda_d16	xbc, 34804
	ld	wa, iz
	extz	xwa
	add	xwa, xbc
	cps	l, 0
	jr	z, 5
	ld	(xwa), 254
	jr	3
DiskMed_MarkUnused:
	ld (xwa), 0xff

DiskMed_NextSlotCheck:
	.byte 0xde, 0x61, 0xde, 0xcf, 0x0a, 0x00, 0x67, 0xd9
	.byte 0xc1, 0xa4, 0x88, 0x3f, 0x00, 0x66, 0x3f, 0xf1
	.byte 0xf4, 0x87, 0x33, 0xeb, 0x89, 0xbb, 0x0a, 0x32
DiskMed_AssignOrder:
	.byte 0x81, 0x21, 0xc9, 0xcf, 0xfe, 0x6e, 0x08, 0xb1
	.byte 0x14, 0xfe, 0x87, 0xc1, 0xfe, 0x87, 0x61
DiskMed_NextAssign:
	inc 1, xbc
	cp xbc, xde
	jr c, DiskMed_AssignOrder
	lds iz, 0

DiskMed_FindFirstSong:
	ld	wa, iz
	extz	xwa
	add	xwa, xhl
	ld	a, (xwa)
	cpda8	a, 34816
	jr	nz, 7
	stb_erp	a, 248
	extz	wa
	jr	48
DiskMed_NextFirst:
	inc 1, iz
	cp iz, 0xa
	jr c, DiskMed_FindFirstSong
	jr DiskMed_ReturnZero

DiskMed_SingleSlotCheck:
	.byte 0xf1, 0xf4, 0x87, 0x31, 0x81, 0x3f, 0xfe, 0x6e
	.byte 0x08, 0xb1, 0x14, 0xfe, 0x87, 0xc1, 0xfe, 0x87
	.byte 0x61
DiskMed_SingleSlotInit:
	lds iz, 0

DiskMed_FindFirstLoop:
	ld	wa, iz
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	cpda8	xbc, (34816)
	jr	nz, 17	; -> 0xF91FA6
	stb_erp	a, 248
	extz	wa
DiskMed_PlaySong:
	call	15862692
	incdi8	1, (34816)
	lds32	xhl, 1
	jr	10
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
	lda xsp, (xsp - 0x0e)
	push XIZ
	ld (XSP+0x06),XDE
	ld (XSP+0x0a),XBC
	ld (XSP+0x0e),XWA
	ld XWA,(XSP+0x0a)
	cp XWA,0x01c00018
	jrl z, DiskSel_HandleNavigation
	cp XWA,0x01c00017
	jrl z, DiskSel_HandleNavigation
	cp XWA,0x01c0000b
	jrl z, DiskSel_InitDisplay
	cp XWA,0x01e50004
	jrl z, DiskSel_StoreWindowPtr
	cp XWA,0x01c00013
	jrl nz, DiskSel_Exit
	ld XWA,(XSP+0x06)
	cp XWA,0x00000003
	jrl z, DiskSel_HandleStopEvent
	cp XWA,0x00000002
	jrl nz, DiskSel_Exit
	lds wa, 0
	calr InitializeOperationState
	cpdi8 (0x8c9b), 0x78
	jrl z, DiskSel_CheckPlaying
	ld XWA,0xffffffff
	ld XBC,0x01e0009e
	lds32 xde, 0
	call ApPostEvent
	ld XWA,0xffffffff
	ld XBC,0x01c0000a
	lds32 xde, 0
	call ApPostEvent
	cpdi16 (0x8466), 0x0000
	jr ge, DiskSel_InitState
	ld XWA,0x00600026
	ld XBC,0x01c00001
	lds32 xde, 5
	call ApPostEvent
	call GetEncodedFileSizeData
	stda16 (0x8466), hl
	call FileIO_SearchAndLoadFile
	call GetEncodedFreeSpaceData
	ld XWA,0x00600026
	ld XBC,0x01c00002
	lds32 xde, 0
	call ApPostEvent
	ld XWA,0xffffffff
	ld XBC,0x01c0000a
	lds32 xde, 0
	call ApPostEvent
	calr SignalProgressUpdate
DiskSel_InitState:
	stdi8	(33890), 0
	stdi8	(34976), 0
	stdi8	(34974), 0
	lds	iz, 0
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
	.byte 0xf1, 0x8a, 0x88, 0x30, 0xf3, 0x07, 0xe0, 0xf8
	.byte 0x14, 0x9e, 0x88, 0xc1, 0x9e, 0x88, 0x61, 0x68
	.byte 0x0a
DiskSel_MarkUnavail:
	.byte 0xf1, 0x8a, 0x88, 0x30, 0xf3, 0x07, 0xe0, 0xf8
	.byte 0x00, 0xff
DiskSel_NextFile:
	inc 1, iz
	cp iz, 0x14
	jr lt, DiskSel_CheckFileLoop
	call CDlike_InitModeAndLoadBank
	jrl DiskSel_Exit

DiskSel_CheckPlaying:
	call	15861571
	cps	l, 1
	jrl	nz, 763
	stdi8	(33890), 1
	ld	xwa, (xsp+14)
	ld	xbc, (xsp+10)
	ld	xde, (xsp+6)
	calr	64925
	cps	l, 1
	jr	nz, 38
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 0
	call	16423243
	ld	xwa, 4294967295
	ld	xbc, 31457434
	lds32	xde, 0
	call	16423243
	ldw	wa, 120
	jrl	685
DiskSel_CheckFinished:
	cps	l, 2
	jrl	nz, 1761	; -> 0xF927FA
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 0
	call	ApPostEvent
	ld	xwa, 4294967295
	ld	xbc, 29360138
	lds32	xde, 0
	call	ApPostEvent
	ldb_d8	a, (34976)
	cpda8	xbc, (34974)
	jrl	nc, 324	; -> 0xF92288
	lds	iz, 0
DiskSel_ClearSelections:
	stb_erp A, 0xf8
	extz wa
	call FileIO_FormatName_Loop
	inc 1, iz
	cp iz, 0x8
	jr lt, DiskSel_ClearSelections
	lds iz, 0

DiskSel_FindSongLoop:
	lda_d16 xwa, (0x888a)
	ldb_dri a, 0x07, 0xe0, 0xf8
	cpda8 a, (0x88a0)
	jrl nz, DiskSel_NextSongLoop
	stda16 (0x8342), iz
	ld WA,IZ
	call NotifyUIOfSelectionChange
	ldw_d16 de, (0x8342)
	exts XDE
	ldda32 xwa, (0x833e)
	ld XBC,0x01e50002
	call ApPostEvent
	ld QIZ,0
DiskSel_SendFileInfo:
	ld	de, qiz
	sll	de, 5
	lda_d16	xbc, (33904)
	extz	xde
	add	xde, xbc
	ldda32	xwa, (33598)
	ld	xbc, 29360143
	call	16423243
	inc	1, qiz
	cpw	qiz, 20
	jr	lt, -37
	lds32	xwa, 0
	ld	xbc, 29360139
	lds32	xde, 0
	calr	64518
	lds32	xwa, 0
	ld	xbc, 29360139
	lds32	xde, 0
	calr	64601
	lds32	xwa, 0
	ld	xbc, 29360139
	ld	xde, 7798792
	calr	40774
	lds32	xwa, 0
	ld	xbc, 29360139
	ld	xde, 7798793
	calr	40990
	ld	xwa, 6291494
	ld	xbc, 29360129
	lds32	xde, 5
	call	16423243
	lds	wa, 0
	calr	35838
	call	16283131
	ld	qiz, hl
	calr	35920
	ld	xwa, 6291494
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	ld	xwa, 4294967295
	ld	xbc, 29360138
	lds32	xde, 0
	call	16423243
	cp	qiz, 0
	jr	ge, 30
	stdi8	(33890), 0
	ldw	wa, 96
	call	16355459
	ld	wa, qiz
	lds	bc, 1
	calr	36421
	stb_d8	(32422), l
	ldw	wa, 238
	jrl	1272
DiskSel_PlayNext:
	incdi8	1, (34976)
	ld	xwa, (xsp+14)
	ld	xbc, 29360151
	ld	xde, 13
	calr	64557
	cps	l, 1
	jr	nz, 25
	ld	xwa, 4294967295
	ld	xbc, 31457434
	lds32	xde, 0
	call	16423243
	ldw	wa, 120
	call	16355459
	jr	9
DiskSel_NextSongLoop:
	inc 1, iz
	cp iz, 0x14
	jrl lt, DiskSel_FindSongLoop

DiskSel_ClearPlaying:
	stdi8	(33890), 0
	jrl	1394
DiskSel_CheckRepeat:
	cpdi8	34978, 0
	jr	z, -15
	stdi8	34976, 0
	lds	iz, 0
DiskSel_RepeatClear:
	stb_erp A, 0xf8
	extz wa
	call FileIO_FormatName_Loop
	inc 1, iz
	cp iz, 0x8
	jr lt, DiskSel_RepeatClear
	lds iz, 0

DiskSel_RepeatFindLoop:
	lda_d16 xwa, (0x888a)
	ldb_dri a, 0x07, 0xe0, 0xf8
	cpda8 a, (0x88a0)
	jrl nz, DiskSel_RepeatNext
	stda16 (0x8342), iz
	ld WA,IZ
	call NotifyUIOfSelectionChange
	ldw_d16 de, (0x8342)
	exts XDE
	ldda32 xwa, (0x833e)
	ld XBC,0x01e50002
	call ApPostEvent
	ld QIZ,0
DiskSel_RepeatSendInfo:
	ld	de, qiz
	sll	de, 5
	lda_d16	xbc, (33904)
	extz	xde
	add	xde, xbc
	ldda32	xwa, (33598)
	ld	xbc, 29360143
	call	16423243
	inc	1, qiz
	cpw	qiz, 20
	jr	lt, -37
	lds32	xwa, 0
	ld	xbc, 29360139
	lds32	xde, 0
	calr	64182
	lds32	xwa, 0
	ld	xbc, 29360139
	lds32	xde, 0
	calr	64265
	lds32	xwa, 0
	ld	xbc, 29360139
	ld	xde, 7798792
	calr	40438
	lds32	xwa, 0
	ld	xbc, 29360139
	ld	xde, 7798793
	calr	40654
	ld	xwa, 6291494
	ld	xbc, 29360129
	lds32	xde, 5
	call	16423243
	lds	wa, 0
	calr	35502
	call	16283131
	ld	qiz, hl
	calr	35584
	ld	xwa, 6291494
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	ld	xwa, 4294967295
	ld	xbc, 29360138
	lds32	xde, 0
	call	16423243
	cp	qiz, 0
	jr	ge, 30
	stdi8	(33890), 0
	ldw	wa, 96
	call	16355459
	ld	wa, qiz
	lds	bc, 1
	calr	36085
	stb_d8	(32422), l
	ldw	wa, 238
	jrl	936
DiskSel_RepeatPlayNext:
	incdi8	1, (34976)
	ld	xwa, (xsp+14)
	ld	xbc, 29360151
	ld	xde, 13
	calr	64221
	cps	l, 1
	jr	nz, 26
	ld	xwa, 4294967295
	ld	xbc, 31457434
	lds32	xde, 0
	call	16423243
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
	call	15861571
	stdi8	(33890), 0
	cps	l, 0
	jr	nz, 35
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 0
	call	16423243
	ld	xwa, 4294967295
	ld	xbc, 29360138
	lds32	xde, 0
	call	16423243
	jrl	1014
DiskSel_ShowError:
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 0
	call	16423243
	stdi8	(32422), 14
	ldw	wa, 238
	jrl	799
DiskSel_HandleStopEvent:
	cpdi8 (0x8c9a), 0x78
	jr z, DiskSel_PostStopEvent
	call CDlike_ExitModeAndRestore
	stdi8 (0x8462), 0x00
DiskSel_PostStopEvent:
	calr CancelOperationCleanup
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	jrl DiskSel_PostEvent

DiskSel_StoreWindowPtr:
	ld	xwa, (xsp+6)
	stda32	(33598), xwa
	call	16290274
	stda16	(33602), hl
	cps	hl, 0
	jr	lt, 16
	exts	xhl
	ldda32	xwa, (33598)
	ld	xbc, 31784962
	ld	xde, xhl
	jrl	914
DiskSel_DefaultIndex:
	stdi16	(33602), 0
	ldda32	xwa, (33598)
	ld	xbc, 31784962
	lds32	xde, 0
	jrl	894
DiskSel_InitDisplay:
	lds iz, 0

DiskSel_DisplayLoop:
	ld	wa, iz
	ld	hl, wa
	sll	hl, 5
	lda_d16	xde, 33904
	extz	xhl
	add	xhl, xde
	stb_erp	c, 248
	ld	(xhl), c
	lds	bc, 2
	call	16289787
	ld	wa, iz
	cps	l, 0
	jr	nz, 13
	ldw	bc, 8
	call	16289787
	cps	l, 0
	jr	z, 10
	ld	wa, iz
DiskSel_GetFileName:
	call GetFileEntryPtr
	ld xbc, xhl
	jr DiskSel_FormatEntry

DiskSel_EmptyFileName:
	lda_24 xbc, (Data_SaveLoadMenuTable_0x64)

DiskSel_FormatEntry:
	ld	de, iz
	ld	wa, de
	sll	wa, 5
	lds	hl, 1
	add	hl, wa
	lda_d16	xix, (33904)
	extz	xhl
	add	xhl, xix
	inc	1, de
	pushw	6
	pushw	0
	ld	xwa, xhl
	call	16289232
	ld	de, iz
	sll	de, 5
	lda_d16	xbc, (33904)
	extz	xde
	add	xde, xbc
	ldda32	xwa, (33598)
	ld	xbc, 29360143
	call	16423243
	inc	1, iz
	cp	iz, 20
	jr	lt, -125
	jrl	768
DiskSel_HandleNavigation:
	ldw_d16 de, (0x8342)
	ld (XSP+0x04),DE
	ld XBC,(XSP+0x0a)
	ld XWA,(XSP+0x06)
	or XWA,XWA
	jr nz, DiskSel_CheckPage
	cpdi8 (0x8462), 0x00
	jr nz, DiskSel_CheckPage
	ld XWA,XBC
	cp XBC,0x01c00018
	jr nz, DiskSel_CheckPrevKey
	cp DE,0x0013
	jrl ge, DiskSel_GetCurrentIndex
	inc 1,DE
	jr t, DiskSel_SaveIndex
DiskSel_CheckPrevKey:
	cp xwa, 0x1c00017
	jrl nz, DiskSel_GetCurrentIndex
	cps de, 0
	jrl le, DiskSel_GetCurrentIndex
	dec 1, de
	jr DiskSel_SaveIndex

DiskSel_CheckPage:
	.byte 0xaf, 0x06, 0x20, 0xe8, 0xcf, 0x01, 0x00, 0x00
	.byte 0x00, 0x6e, 0x14, 0xc1, 0x62, 0x84, 0x3f, 0x00
	.byte 0x6e, 0x0d, 0xda, 0xcf, 0x0a, 0x00, 0x71, 0x4f
	.byte 0x02, 0xda, 0xca, 0x0a, 0x00, 0x68, 0x23
DiskSel_CheckPageDown:
	.byte 0xaf, 0x06, 0x20, 0xe8, 0xcf, 0x02, 0x00, 0x00
	.byte 0x00, 0x6e, 0x1f, 0xc1, 0x62, 0x84, 0x3f, 0x00
	.byte 0x6e, 0x18, 0xda, 0x88, 0xd8, 0xc8, 0x0a, 0x00
	.byte 0xd8, 0xcf, 0x13, 0x00, 0x7a, 0x2a, 0x02, 0xda
	.byte 0xc8, 0x0a, 0x00
DiskSel_SaveIndex:
	stda16	(33602), de
	jrl	547
DiskSel_HandleToggle:
	lda_d16	xhl, 34954
	ld	xwa, (xsp+6)
	cp	xwa, 10
	jr	nz, 100
	cpdi8	33890, 0
	jr	nz, 93
	lds	iz, 0
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
	.byte 0x83, 0x21, 0xc9, 0xcf, 0xfe, 0x6e, 0x08, 0xb3
	.byte 0x14, 0x9e, 0x88, 0xc1, 0x9e, 0x88, 0x61
DiskSel_NextAssign:
	inc 1, xhl
	cp xhl, xde
	jr c, DiskSel_AssignLoop
	jr DiskSel_RefreshDisplay

DiskSel_UnmarkLoop:
	ld	a, (xhl)
	cp	a, 253
	jr	ugt, 7
	ld	(xhl), 254
	decdi8	1, (34974)
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
	.byte 0xaf, 0x06, 0x20, 0xe8, 0xcf, 0x0b, 0x00, 0x00
	.byte 0x00, 0x6e, 0x66, 0xc1, 0x62, 0x84, 0x3f, 0x00
	.byte 0x6e, 0x5f, 0xeb, 0x8c, 0xf3, 0x07, 0xec, 0xe8
	.byte 0x31, 0x81, 0x21, 0xc9, 0xcf, 0xfe, 0x6e, 0x0a
	.byte 0xb1, 0x14, 0x9e, 0x88, 0xc1, 0x9e, 0x88, 0x61
	.byte 0x68, 0x2c
DiskSel_RemoveSelect:
	cp	a, 253
	jr	ugt, 39
	cp	de, 20
	jr	ge, 7
	ld	(xbc), 254
	decdi8	1, (34974)
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
	ld	xwa, (xsp+6)
	cp	xwa, 12
	jr	nz, 24
	cp	xbc, 29360151
	jr	nz, 8
	stdi8	(34978), 1
	jrl	288
DiskSel_SetRepeatOff:
	stdi8	(34978), 0
	jrl	280
DiskSel_HandlePlayStart:
	ld xwa, (xsp + 6)

	cp xwa, 0xd

	.byte 0x7e, 0xed, 0x00	; jrl nz, DiskSel_HandleAllCheck (v7 displacement)

	.byte 0xc1, 0x62, 0x84, 0x3f, 0x00	; cpdi8 (0x84fe), 0 (v7 patched)

	.byte 0x7e, 0xe5, 0x00	; jrl nz, DiskSel_HandleAllCheck (v7 displacement)

	.byte 0xf1, 0xa0, 0x88, 0x00, 0x00	; stdi8 (0x893c), 0 (v7 patched)

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
	lda_d16 xwa, (0x888a)
	ldb_dri a, 0x07, 0xe0, 0xf8
	cpda8 a, (0x88a0)
	jrl nz, DiskSel_PlayNextLoop
	stda16 (0x8342), iz
	ld WA,IZ
	call NotifyUIOfSelectionChange
	ldw_d16 de, (0x8342)
	exts XDE
	ldda32 xwa, (0x833e)
	ld XBC,0x01e50002
	call ApPostEvent
	ld XWA,0x00600026
	ld XBC,0x01c00001
	lds32 xde, 5
	call ApPostEvent
	call FileIO_ParseDirectoryEntry
	ld QIZ,HL
	calr SignalProgressUpdate
	ld XWA,0x00600026
	ld XBC,0x01c00002
	lds32 xde, 0
	call ApPostEvent
	ld XWA,0xffffffff
	ld XBC,0x01c0000a
	lds32 xde, 0
	call ApPostEvent
	cp QIZ,0
	jr ge, DiskSel_PlayNextSong
	stdi8 (0x8462), 0x00
	ldw WA, 0x0060
	call UI_PostModeChangeEvent
	ld WA,QIZ
	lds bc, 1
	calr FileIO_ValidateSignedValue
	stb_d8 (0x7ea6), l
	ldw WA, 0x00ee
DiskSel_ShowErrorAndExit:
	call SoundCtrl_SendCommand
	jrl DiskSel_Exit

DiskSel_PlayNextSong:
	.byte 0xbf, 0x04, 0x16, 0x42, 0x83, 0xc1, 0xa0, 0x88
	.byte 0x61, 0xaf, 0x0e, 0x20, 0xaf, 0x0a, 0x21, 0xaf
	.byte 0x06, 0x22, 0x1e, 0x2d, 0xf7, 0xcf, 0xd9, 0x6e
	.byte 0x19, 0x40, 0xff, 0xff, 0xff, 0xff, 0x41, 0x9a
	.byte 0x00, 0xe0, 0x01, 0xea, 0xa8, 0x1d, 0x4b, 0x99
	.byte 0xfa, 0x30, 0x78, 0x00, 0x1d, 0x83, 0x90, 0xf9
	.byte 0x68, 0x2a
DiskSel_PlayNextLoop:
	inc 1, iz
	cp iz, 0x14
	jrl lt, DiskSel_PlayFindLoop
	jr DiskSel_GetCurrentIndex

DiskSel_HandleAllCheck:
	ld	xwa, (xsp+6)
	cp	xwa, 14
	jr	nz, 20
	cp	xbc, 29360151
	jr	nz, 7
	stdi8	(34980), 1
	jr	5
DiskSel_SetAllOff:
	stdi8	(34980), 0
DiskSel_GetCurrentIndex:
	ldw_d16	de, (33602)
DiskSel_UpdateDisplay:
	cp	(xsp+4), de
	jr	z, 80
	ld	wa, de
	call	16290296
	ldw_d16	de, (33602)
	exts	xde
	ldda32	xwa, (33598)
	ld	xbc, 31784962
	call	16423243
	ld	de, (xsp+4)
	sll	de, 5
	lda_d16	xbc, (33904)
	extz	xde
	add	xde, xbc
	ldda32	xwa, (33598)
	ld	xbc, 29360143
	call	16423243
	ldw_d16	de, (33602)
	sll	de, 5
	lda_d16	xbc, (33904)
	extz	xde
	add	xde, xbc
	ldda32	xwa, (33598)
	ld	xbc, 29360143
DiskSel_PostEvent:
	call ApPostEvent

DiskSel_Exit:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 14)
	ret

GetPlayState1_Entry:
GetPlayState1:
	ldb_d8	l, (34982)
	ret
GetPlayState2_Entry:
GetPlayState2:
	ldb_d8	l, (34984)
	ret
SmfMedley_RawData:
	cps a, 0
	scc NZ,WA
	stb_d8 (0x88a8), a
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
	.byte 0xd1, 0x68, 0x84, 0x3f, 0x00, 0x00, 0x62, 0x2f
	.byte 0x1d, 0xba, 0x96, 0xf8, 0xdb, 0xd8, 0x61, 0x27
	.byte 0xdb, 0x8e, 0x9f, 0x02, 0x86, 0x69, 0x08, 0xd1
	.byte 0x68, 0x84, 0x26, 0xde, 0x69, 0x68, 0x08
NavSong_WrapToEnd:
	.byte 0xd1, 0x68, 0x84, 0xf6, 0x61, 0x02, 0xde, 0xa8
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
	.byte 0xd1, 0x6c, 0x84, 0x3f, 0x00, 0x00, 0x62, 0x25
	.byte 0x1d, 0xc1, 0xa3, 0xf8, 0xdb, 0xd8, 0x61, 0x1d
	.byte 0xdb, 0x88, 0xde, 0x80, 0x69, 0x08, 0xd1, 0x6c
	.byte 0x84, 0x20, 0xd8, 0x69, 0x68, 0x08
NavDoc_WrapToEnd:
	.byte 0xd1, 0x6c, 0x84, 0xf0, 0x61, 0x02, 0xd8, 0xa8
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
	.byte 0xd1, 0x6a, 0x84, 0x3f, 0x00, 0x00, 0x62, 0x25
	.byte 0x1d, 0xbb, 0xa0, 0xf8, 0xdb, 0xd8, 0x61, 0x1d
	.byte 0xdb, 0x88, 0xde, 0x80, 0x69, 0x08, 0xd1, 0x6a
	.byte 0x84, 0x20, 0xd8, 0x69, 0x68, 0x08
NavPd_WrapToEnd:
	.byte 0xd1, 0x6a, 0x84, 0xf0, 0x61, 0x02, 0xd8, 0xa8
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
	ld	wa, iz
	sll	wa, 3
	lda_d16	xbc, 33604
	extz	xwa
	add	xwa, xbc
	ld	bc, qiz
	add	bc, iz
	lda_d16	xde, 34820
	extz	xbc
	add	xbc, xde
	ld	c, (xbc)
	extz	bc
	ld	de, iz
	calr	-4238
	ld	de, iz
	sll	de, 3
	lda_d16	xwa, 33604
	extz	xde
	add	xde, xwa
	ld	xwa, (xsp+6)
	ld	xbc, 29360143
	call	16423243
	inc	1, iz
	.byte 0x9f, 0x04, 0xf6
	jr	c, -67
SmfFmt_FillEmpty:
	cp iz, 0xa
	jr nc, SmfFmt_Exit

SmfFmt_EmptyLoop:
	ld	wa, iz
	sll	wa, 3
	lda_d16	xbc, (33604)
	extz	xwa
	add	xwa, xbc
	ldw	bc, 255
	ld	de, iz
	calr	61239
	ld	de, iz
	sll	de, 3
	lda_d16	xwa, (33604)
	extz	xde
	add	xde, xwa
	ld	xwa, (xsp+6)
	ld	xbc, 29360143
	call	16423243
	inc	1, iz
	cp	iz, 10
	jr	c, -54
SmfFmt_Exit:
	pop xiz
	inc 6, xsp
	ret

FmmSmfMedleyFunc:
	dec	4, xsp
	pushw	iz
	ld	xhl, xbc
	ld	(xsp+2), xwa
	cp	xhl, 31784970
	jrl	z, 1172
	ld	xwa, xde
	cp	xhl, 31784968
	jrl	z, 1155
	ldw_d16	bc, (33692)
	cp	xhl, 29360152
	jrl	z, 685
	cp	xhl, 29360151
	jrl	z, 676
	cp	xhl, 29360139
	jrl	z, 657
	cp	xhl, 31784964
	jrl	z, 641
	cp	xhl, 29360147
	jrl	nz, 1145
	cp	xde, 3
	jrl	z, 580
	cp	xde, 2
	jrl	nz, 1127
	lds	wa, 0
	calr	33769
	ldb_d8	a, (35995)
	stb_d8	(33694), a
	cp	a, 111
	jr	z, 5
	cp	a, 114
	jr	nz, 57
SmfMed_CheckNotPlaying:
	stdi8	(33890), 0
	call	15861571
	cps	l, 4
	jr	z, 29
	cps	l, 3
	jr	z, 15
	cps	l, 2
	jrl	nz, 1082
	stdi8	(32422), 1
	ldw	wa, 238
	jr	18
SmfMed_Error31:
	stdi8	(32422), 49
	ldw	wa, 238
	jr	8
SmfMed_Error3F:
	stdi8	(32422), 63
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
	call	15861571
	cps	l, 1
	jrl	c, 285
	call	15861571
	cps	l, 4
	jr	z, 28
	cps	l, 3
	jr	z, 14
	cps	l, 2
	jr	nz, 36
	stdi8	(32422), 1
	ldw	wa, 238
	jr	18
SmfMed_PlayError31:
	stdi8	(32422), 49
	ldw	wa, 238
	jr	8
SmfMed_PlayError3F:
	stdi8	(32422), 63
	ldw	wa, 238
SmfMed_ShowPlayError:
	call	16355504
	incdi8	1, (33696)
SmfMed_SetPlaying:
	stdi8	(33890), 1
	ldb_d8	a, (34950)
	cpda8	xbc, (34948)
	jr	nc, 91	; -> 0xF92B0B
	lds	iz, 0
	ldw_d16	bc, (33692)
	cps	bc, 0
	jrl	ule, 949	; -> 0xF92E70
	lda_d16	xde, (34820)
SmfMed_FindSongLoop:
	ld	hl, iz
	extz	xhl
	add	xhl, xde
	cp	(xhl), a
	jr	nz, 57
	ld	de, iz
	extz	xde
	ld	xwa, (xsp+2)
	ld	xbc, 31784962
	calr	45445
	ldda32	xwa, (33684)
	ldw_d16	bc, (33692)
	calr	65016
	incdi8	1, (34950)
	ld	wa, iz
	call	16292978
	ldda32	xwa, (33688)
	or	xwa, xwa
	jrl	z, 890
	ld	xbc, 31784969
	ld	xde, 30
	jr	113
SmfMed_NextSong:
	inc 1, iz
	cp iz, bc
	jr c, SmfMed_FindSongLoop
	jrl SmfMed_Exit
SmfMed_CheckRepeat:
	cpdi8	34952, 0
	jr	z, 113
	cpdm8	33696, a
	jr	nc, 107
	stdi8	34950, 0
	stdi8	33696, 0
	lds	iz, 0
	ldw_d16	wa, 33692
	cps	wa, 0
	jrl	ule, 835
	lda_d16	xbc, 34820
SmfMed_RepeatFindLoop:
	ld	de, iz
	extz	xde
	add	xde, xbc
	.byte 0x82, 0x3f, 0x00
	jr	nz, 62
	ld	de, iz
	extz	xde
	ld	xwa, (xsp+2)
	ld	xbc, 31784962
	calr	-20206
	ldda32	xwa, 33684
	ldw_d16	bc, 33692
	calr	-635
	incdi8	1, (34950)
	ld	wa, iz
	call	16292978
	ldda32	xwa, 33688
	or	xwa, xwa
	jrl	z, 775
	ld	xbc, 31784969
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
	stdi8	(33696), 0
	jr	9
SmfMed_CheckNotPlayError:
	call Medley_GetPlaybackStatus
	cps l, 0
	jrl nz, SmfMed_Exit

SmfMed_ClearPlaying:
	stdi8	(33890), 0
	jrl	725
SmfMed_InitFromDisk:
	lds32 xde, 0
	ldb_d8 e, (0x88a8)
	ld XWA,0x006c0018
	ld XBC,0x01e0003b
	call ApPostEvent
	cpdi16 (0x8468), 0x0000
	jr ge, SmfMed_InitState
	ld XWA,0x00600026
	ld XBC,0x01c00001
	lds32 xde, 5
	call ApPostEvent
	call GetFileCountEncoded
	stda16 (0x8468), hl
	call FileIO_SearchAndLoadFile
	call GetEncodedFreeSpaceData
	ld XWA,0x00600026
	ld XBC,0x01c00002
	lds32 xde, 0
	call ApPostEvent
	ld XWA,0xffffffff
	ld XBC,0x01c0000a
	lds32 xde, 0
	call ApPostEvent
	calr SignalProgressUpdate
SmfMed_InitState:
	stdi8	(33890), 0
	stdi8	(34950), 0
	stdi8	(34948), 0
	ldw	bc, 128
	ldw_d16	wa, (33896)
	cp	wa, 128
	jr	ugt, 2
	ld	bc, wa
SmfMed_ClampFileCount:
	stda16	(33692), bc
	lds	iz, 0
	cps	bc, 0
	jr	ule, 21
	lda_d16	xwa, (34820)
SmfMed_ClearSlotsLoop:
	ld	bc, iz
	extz	xbc
	add	xbc, xwa
	ld	(xbc), 255
	inc	1, iz
	cpda16	xiz, (33692)
	jr	c, -17	; -> 0xF92C26
SmfMed_FinishInit:
	call	15862435
	lds32	xwa, 0
	stda32	(33688), xwa
	jrl	556
SmfMed_HandleStop_Entry:
SmfMed_HandleStop:
	ldb_d8	a, (35994)
	cp	a, 111
	jrl	z, 546
	cp	a, 114
	jrl	z, 540
	cp	a, 115
	jrl	z, 534
	cp	a, 118
	jrl	z, 528
	call	15862598
	calr	33232
	stdi8	(33890), 0
	jrl	513
SmfMed_StoreWindowPtr:
	stda32	(33684), xwa
	jrl	506
SmfMed_RefreshDisplay:
	ldda32	xwa, (33684)
	calr	64606
	jrl	496
SmfMed_HandleNavToggle:
	lda_d16 xwa, (0x8804)
	cp XDE,0x0000000a
	jr nz, SmfMed_HandleSelectToggle
	cpdi8 (0x8462), 0x00
	jr nz, SmfMed_HandleSelectToggle
	lds iz, 0
	ld DE,BC
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
	cp	iz, de
	jr	nc, 41
	lds	iz, 0
	cps	de, 0
	jr	ule, 73
	lda_d16	xde, (34820)
SmfMed_AssignOrderLoop:
	.byte 0xde, 0x89, 0xe9, 0x12, 0xea, 0x81, 0x81, 0x21
	.byte 0xc9, 0xcf, 0xff, 0x6e, 0x08, 0xb1, 0x14, 0x84
	.byte 0x88, 0xc1, 0x84, 0x88, 0x61
SmfMed_NextAssign:
	.byte 0xde, 0x61, 0xd1, 0x9c, 0x83, 0xf6, 0x67, 0xe3
	.byte 0x68, 0x26
SmfMed_RemoveOrderLoop:
	lds	iz, 0
	cps	de, 0
	jr	ule, 32
	lda_d16	xde, (34820)
SmfMed_UnmarkLoop:
	ld	bc, iz
	extz	xbc
	add	xbc, xde
	ld	a, (xbc)
	cp	a, 253
	jr	ugt, 7
	ld	(xbc), 255
	decdi8	1, (34948)
SmfMed_NextUnmark:
	.byte 0xde, 0x61, 0xd1, 0x9c, 0x83, 0xf6, 0x67, 0xe4
SmfMed_RefreshAfterToggle:
	ldda32	xwa, (33684)
	ldw_d16	bc, (33692)
	jr	124
SmfMed_HandleSelectToggle:
	.byte 0xea, 0xcf, 0x0b, 0x00, 0x00, 0x00, 0x6e, 0x7a
	.byte 0xc1, 0x62, 0x84, 0x3f, 0x00, 0x6e, 0x73, 0xaf
	.byte 0x02, 0x20, 0x41, 0x03, 0x00, 0xe5, 0x01, 0xea
	.byte 0xa8, 0x1e, 0x38, 0xaf, 0xdb, 0x8e, 0xf1, 0x04
	.byte 0x88, 0x33, 0xde, 0x88, 0xe8, 0x12, 0xeb, 0x80
	.byte 0x80, 0x23, 0xcb, 0xcf, 0xff, 0x6e, 0x0a, 0xb0
	.byte 0x14, 0x84, 0x88, 0xc1, 0x84, 0x88, 0x61, 0x68
	.byte 0x3b
SmfMed_RemoveFromOrder:
	cp	c, 253
	jr	ugt, 54
	ld	(xwa), 255
	ldb_d8	a, (34948)
	dec	1, a
	stb_d8	(34948), a
	lds	iy, 0
	lds	iz, 0
	extz	wa
	cps	wa, 0
	jr	ule, 31
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
	ldda32	xwa, (33684)
	ldw_d16	bc, (33692)
SmfMed_CallFormatSlots:
	calr SmfMed_FormatSlotList
	jrl SmfMed_Exit

SmfMed_HandleRepeat:
	cp	xde, 12
	jr	nz, 24
	cp	xhl, 29360151
	jr	nz, 8
	stdi8	(34952), 1
	jrl	205
SmfMed_SetRepeatOff:
	stdi8	(34952), 0
	jrl	197
SmfMed_HandlePlay:
	cp	xde, 13
	jrl	nz, 188
	cpdi8	33890, 0
	jrl	nz, 180
	stdi8	34950, 0
	stdi8	33696, 0
	lds	iz, 0
	ldw_d16	bc, 33692
	cps	bc, 0
	jr	ule, 72
SmfMed_PlayFindLoop:
	ld	de, iz
	extz	xde
	add	xde, xwa
	.byte 0x82, 0x3f, 0x00
	jr	nz, 55
	stdi8	33890, 1
	ld	de, iz
	extz	xde
	ld	xwa, (xsp+2)
	ld	xbc, 31784962
	calr	-20882
	incdi8	1, (34950)
	ld	wa, iz
	call	16292978
	ld	xwa, 4294967295
	ld	xbc, 31457434
	lds32	xde, 0
	call	16423243
	ldw	wa, 115
	call	16355459
	jr	6
SmfMed_PlayNextLoop:
	inc 1, iz
	cp iz, bc
	jr c, SmfMed_PlayFindLoop

SmfMed_CheckAutoPlay:
	cpdi8	33890, 0
	jr	nz, 81
	ld	xwa, (xsp+2)
	ld	xbc, 31784963
	lds32	xde, 0
	calr	-20943
	ld	iz, hl
	ld	wa, iz
	call	16292978
	ld	xwa, 4294967295
	ld	xbc, 31457434
	lds32	xde, 0
	call	16423243
	ldw	wa, 111
	jr	35
SmfMed_StoreDelayFlag:
	stda32	(33688), xwa
	jr	33
SmfMed_CheckContinue:
	cpdi8 (0x8462), 0x00
	jr z, SmfMed_Exit
	ld XWA,0xffffffff
	ld XBC,0x01e0009a
	lds32 xde, 0
	call ApPostEvent
	ldb_d8 a, (0x839e)
	extz WA
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
	ld	de, iz
	sll	de, 5
	lda_d16	xbc, 33904
	extz	xde
	add	xde, xbc
	stb_erp	a, 248
	ld	(xde), a
	ld	wa, (xsp+2)
	add	wa, iz
	call	16294372
	ld	xbc, xhl
	ld	wa, iz
	sll	wa, 5
	lds	de, 1
	add	de, wa
	lda_d16	xhl, 33904
	ld	wa, de
	extz	xwa
	add	xwa, xhl
	ld	de, (xsp+2)
	add	de, iz
	inc	1, de
	.byte 0x0b, 0x14, 0x00, 0x0b, 0x01, 0x00
	call	16289232
	ld	de, iz
	sll	de, 5
	lda_d16	xbc, 33904
	extz	xde
	add	xde, xbc
	ld	xwa, (xsp+4)
	ld	xbc, 29360143
	call	16423243
	inc	1, iz
	cp	iz, 10
	jr	lt, -98
	popw	iz
	inc	6, xsp
	ret
FmmPdFileNameFunc:
	dec	4, xsp
	pushw	iz
	ld	(xsp+2), xwa
	cp	xbc, 31784963
	jrl	z, 484
	ldw_d16	wa, (33702)
	ld	iz, wa
	cp	xbc, 31784962
	jrl	z, 420
	ld	hl, wa
	exts	xhl
	divs	hl, 10
	cp	xbc, 29360152
	jr	z, 91
	cp	xbc, 29360151
	jr	z, 83
	cp	xbc, 29360139
	jr	z, 57
	cp	xbc, 31784964
	jr	nz, 62
	stda32	(33698), xde
	call	16294075
	stda16	(33702), hl
	cps	hl, 0
	jr	ge, 6
	stdi16	(33702), 0
PdName_UpdateIndex:
	ldw_d16	wa, (33702)
	exts	xwa
	divs	wa, 10
	ld	de, qwa
	exts	xde
	ldda32	xwa, (33698)
	ld	xbc, 31784962
	jrl	373
PdName_RefreshList:
	muls	hl, 10
	ldda32	xwa, (33698)
	ld	bc, hl
	calr	65291
PdName_ReturnZero:
	lds32 xhl, 0
	jrl PdName_Exit

PdName_HandleNavigation:
	.byte 0xea, 0xe2, 0x6e, 0x2d, 0xc1, 0x62, 0x84, 0x3f
	.byte 0x00, 0x6e, 0x26, 0xe9, 0xcf, 0x18, 0x00, 0xc0
	.byte 0x01, 0x6e, 0x0e, 0xd8, 0x89, 0xd9, 0x61, 0xd1
	.byte 0x6a, 0x84, 0xf1, 0x69, 0x77, 0xd8, 0x61, 0x68
	.byte 0x4c
PdName_CheckPrevKey:
	cp xbc, 0x1c00017
	jr nz, PdName_GetCurrentIndex
	cps wa, 0
	jr le, PdName_GetCurrentIndex
	dec 1, wa
	jr PdName_SaveIndex

PdName_CheckPageUp:
	.byte 0xea, 0xcf, 0x01, 0x00, 0x00, 0x00, 0x6e, 0x13
	.byte 0xc1, 0x62, 0x84, 0x3f, 0x00, 0x6e, 0x0c, 0xd8
	.byte 0xcf, 0x0a, 0x00, 0x61, 0x4e, 0xd8, 0xca, 0x0a
	.byte 0x00, 0x68, 0x21
PdName_CheckPageDown:
	.byte 0xea, 0xcf, 0x02, 0x00, 0x00, 0x00, 0x6e, 0x40
	.byte 0xc1, 0x62, 0x84, 0x3f, 0x00, 0x6e, 0x39, 0xd8
	.byte 0x89, 0xd9, 0xc8, 0x0a, 0x00, 0xd1, 0x6a, 0x84
	.byte 0x22, 0xda, 0xf1, 0x69, 0x0a, 0xd8, 0xc8, 0x0a
	.byte 0x00
PdName_SaveIndex:
	stda16	(33702), wa
	jr	37
PdName_CheckEndBound:
	ld	bc, de
	dec	1, bc
	ld	wa, bc
	exts	xwa
	divs	wa, 10
	cp	hl, wa
	jr	ge, 17
	exts	xde
	divs	de, 10
	ld	wa, qde
	cps	wa, 0
	jr	z, 4
	stda16	(33702), bc
PdName_GetCurrentIndex:
	ldw_d16	wa, (33702)
PdName_UpdateDisplay:
	cp	iz, wa
	jrl	z, -162
	call	16294296
	ldw_d16	wa, (33702)
	exts	xwa
	divs	wa, 10
	ld	de, qwa
	exts	xde
	ldda32	xwa, (33698)
	ld	xbc, 31784962
	call	16423243
	ldw_d16	bc, (33702)
	exts	xbc
	divs	bc, 10
	ld	de, iz
	exts	xde
	divs	de, 10
	ldda32	xwa, (33698)
	cp	de, bc
	jr	nz, 75
	ld	bc, iz
	exts	xbc
	divs	bc, 10
	ld	bc, qbc
	sll	bc, 5
	lda_d16	xhl, (33904)
	ld	de, bc
	extz	xde
	add	xde, xhl
	ld	xbc, 29360143
	call	16423243
	ldw_d16	wa, (33702)
	exts	xwa
	divs	wa, 10
	ld	wa, qwa
	sll	wa, 5
	lda_d16	xbc, (33904)
	ld	de, wa
	extz	xde
	add	xde, xbc
	ldda32	xwa, (33698)
	ld	xbc, 29360143
	call	16423243
	jrl	-295
PdName_RefreshPage:
	muls bc, 0xa
	calr PdMed_FormatFileList
	ld xwa, (xsp + 2)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	calr FmmPdMedleyFunc
	jrl PdName_ReturnZero

PdName_SetIndexPlaying:
	cpdi8 (0x8462), 0x00
	jrl z, PdName_ReturnZero
	stda16 (0x83a6), de

	ld wa, de

	.byte 0x1d, 0x98, 0xa1, 0xf8	; call SetCurrentFileIndex (v7 addr)

	.byte 0xd1, 0xa6, 0x83, 0x20	; ldw_d16 xwa, (0x8442) (v7 patched)

	exts xwa

	divs wa, 0xa

	stw_erp DE, 0xe2

	exts xde

	ldda32 xwa, (33698)

	ld xbc, 0x1e50002



PdName_PostEvent:
	call ApPostEvent
	jrl PdName_ReturnZero

PdName_GetIndexReturn:
	ldw_d16	hl, (33702)
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
	ld	wa, iz
	sll	wa, 3
	lda_d16	xbc, 33704
	extz	xwa
	add	xwa, xbc
	ld	bc, qiz
	add	bc, iz
	lda_d16	xde, 34820
	extz	xbc
	add	xbc, xde
	ld	c, (xbc)
	extz	bc
	ld	de, iz
	calr	-6295
	ld	de, iz
	sll	de, 3
	lda_d16	xwa, 33704
	extz	xde
	add	xde, xwa
	ld	xwa, (xsp+6)
	ld	xbc, 29360143
	call	16423243
	inc	1, iz
	.byte 0x9f, 0x04, 0xf6
	jr	c, -67
PdFmtSlot_FillEmpty:
	cp iz, 0xa
	jr nc, PdFmtSlot_Exit

PdFmtSlot_EmptyLoop:
	ld	wa, iz
	sll	wa, 3
	lda_d16	xbc, (33704)
	extz	xwa
	add	xwa, xbc
	ldw	bc, 255
	ld	de, iz
	calr	59182
	ld	de, iz
	sll	de, 3
	lda_d16	xwa, (33704)
	extz	xde
	add	xde, xwa
	ld	xwa, (xsp+6)
	ld	xbc, 29360143
	call	16423243
	inc	1, iz
	cp	iz, 10
	jr	c, -54
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
	cp	xde, 31784970
	jrl	z, 988
	ld	xwa, xhl
	cp	xde, 31784968
	jrl	z, 971
	ldw_d16	bc, (33792)
	cp	xde, 29360152
	jrl	z, 534
	cp	xde, 29360151
	jrl	z, 525
	cp	xde, 29360139
	jrl	z, 506
	cp	xde, 31784964
	jrl	z, 490
	cp	xde, 29360147
	jrl	nz, 958
	cp	xhl, 3
	jrl	z, 440
	cp	xhl, 2
	jrl	nz, 940
	lds	wa, 0
	call	16297463
	ldb_d8	a, (35995)
	cp	a, 113
	jr	nz, 25
	stdi8	(33890), 0
	call	15861571
	cps	l, 2
	jrl	c, 911
	stdi8	(32422), 1
	ldw	wa, 238
	jrl	242
PdMed_CheckPlayMode:
	cp	a, 117
	jrl	nz, 243	; -> 0xF93332
	call	Medley_GetPlaybackStatus
	cps	l, 1
	jrl	nz, 205	; -> 0xF93315
	stdi8	(33890), 1
	ldb_d8	c, (34950)
	lda_d16	xwa, (34820)
	cpda8	xhl, (34948)
	jr	nc, 80	; -> 0xF932AB
	lds	hl, 0
	ldw_d16	de, (33792)
	cps	de, 0
	jrl	ule, 855	; -> 0xF935BD
PdMed_FindSongLoop:
	ld	ix, hl
	extz	xix
	add	xix, xwa
	cp	(xix), c
	jr	nz, 50
	extz	xhl
	ld	xwa, xiz
	ld	xbc, 31784962
	ld	xde, xhl
	calr	64617
	ldda32	xwa, (33784)
	ldw_d16	bc, (33792)
	calr	65115
	incdi8	1, (34950)
	ldda32	xwa, (33788)
	or	xwa, xwa
	jrl	z, 807
	ld	xbc, 31784969
	ld	xde, 30
	jr	91
PdMed_NextSong:
	inc 1, hl
	cp hl, de
	jr c, PdMed_FindSongLoop
	jrl PdMed_Exit

PdMed_CheckRepeat:
	.byte 0xc1, 0x88, 0x88, 0x3f, 0x00, 0x66, 0x5b, 0xf1
	.byte 0x86, 0x88, 0x00, 0x00, 0xdb, 0xa8, 0xd1, 0x00
	.byte 0x84, 0x21, 0xd9, 0xd8, 0x73, 0xfb, 0x02
PdMed_RepeatFindLoop:
	.byte 0xdb, 0x8a, 0xea, 0x12, 0xe8, 0x82, 0x82, 0x3f
	.byte 0x00, 0x6e, 0x37, 0xeb, 0x12, 0xee, 0x88, 0x41
	.byte 0x02, 0x00, 0xe5, 0x01, 0xeb, 0x8a, 0x1e, 0x0c
	.byte 0xfc, 0xe1, 0xf8, 0x83, 0x20, 0xd1, 0x00, 0x84
	.byte 0x21, 0x1e, 0xfe, 0xfd, 0xc1, 0x86, 0x88, 0x61
	.byte 0xe1, 0xfc, 0x83, 0x20, 0xe8, 0xe0, 0x76, 0xca
	.byte 0x02, 0x41, 0x09, 0x00, 0xe5, 0x01, 0x42, 0x1e
	.byte 0x00, 0x00, 0x00
PdMed_PostDelayEvent:
	call ApPostEvent
	jrl PdMed_Exit

PdMed_RepeatNext:
	inc 1, hl
	cp hl, bc
	jr c, PdMed_RepeatFindLoop
	jrl PdMed_Exit

PdMed_ClearPlaying:
	stdi8	(33890), 0
	jrl	680
PdMed_HandleError:
	call	15861571
	stdi8	(33890), 0
	cps	l, 0
	jrl	z, 666
	stdi8	(32422), 1
	ldw	wa, 238
PdMed_ShowError:
	call SoundCtrl_SendCommand
	jrl PdMed_Exit

PdMed_InitFromDisk_Entry:
PdMed_InitFromDisk:
	.byte 0xd1, 0x6a, 0x84, 0x3f, 0x00, 0x00, 0x69, 0x3c
	.byte 0x40, 0x26, 0x00, 0x60, 0x00, 0x41, 0x01, 0x00
	.byte 0xc0, 0x01, 0xea, 0xad, 0x1d, 0x4b, 0x99, 0xfa
	.byte 0x1d, 0x18, 0xa2, 0xf8, 0xf1, 0x6a, 0x84, 0x53
	.byte 0x40, 0x26, 0x00, 0x60, 0x00, 0x41, 0x02, 0x00
	.byte 0xc0, 0x01, 0xea, 0xa8, 0x1d, 0x4b, 0x99, 0xfa
	.byte 0x40, 0xff, 0xff, 0xff, 0xff, 0x41, 0x0a, 0x00
	.byte 0xc0, 0x01, 0xea, 0xa8, 0x1d, 0x4b, 0x99, 0xfa
	.byte 0x1d, 0x53, 0xae, 0xf8
PdMed_InitState:
	stdi8	(33890), 0
	stdi8	(34950), 0
	stdi8	(34948), 0
	ldw	bc, 128
	ldw_d16	wa, (33898)
	cp	wa, 128
	jr	ugt, 2
	ld	bc, wa
PdMed_ClampCount:
	stda16	(33792), bc
	lds	hl, 0
	cps	bc, 0
	jr	ule, 21
	lda_d16	xwa, (34820)
PdMed_ClearSlotsLoop:
	ld	bc, hl
	extz	xbc
	add	xbc, xwa
	ld	(xbc), 255
	inc	1, hl
	cpda16	xhl, (33792)
	jr	c, -17	; -> 0xF933A2
PdMed_FinishInit:
	call	15862435
	lds32	xwa, 0
	stda32	(33788), xwa
	jrl	509
PdMed_HandleStop:
	ldb_d8	a, (35994)
	cp	a, 113
	jrl	z, 499
	cp	a, 117
	jrl	z, 493
	call	15862598
	call	16297527
	stdi8	(33890), 0
	jrl	477
PdMed_StoreWindowPtr:
	stda32	(33784), xwa
	jrl	470
PdMed_RefreshDisplay:
	ldda32	xwa, (33784)
	calr	64758
	jrl	460
PdMed_HandleNavToggle:
	cp XHL,0x0000000a
	jrl nz, PdMed_HandleSelectToggle
	cpdi8 (0x8462), 0x00
	jr nz, PdMed_HandleSelectToggle
	lds hl, 0
	ld WA,BC
	cps bc, 0
	jr ule, PdMed_CheckAllUnmarked
	lda_d16 xbc, (0x8804)
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
	jr	nc, 41
	lds	hl, 0
	cps	wa, 0
	jr	ule, 73
	lda_d16	xde, (34820)
PdMed_AssignOrderLoop:
	.byte 0xdb, 0x89, 0xe9, 0x12, 0xea, 0x81, 0x81, 0x21
	.byte 0xc9, 0xcf, 0xff, 0x6e, 0x08, 0xb1, 0x14, 0x84
	.byte 0x88, 0xc1, 0x84, 0x88, 0x61
PdMed_NextAssign:
	.byte 0xdb, 0x61, 0xd1, 0x00, 0x84, 0xf3, 0x67, 0xe3
	.byte 0x68, 0x26
PdMed_RemoveOrderLoop:
	lds	hl, 0
	cps	wa, 0
	jr	ule, 32
	lda_d16	xde, (34820)
PdMed_UnmarkLoop:
	ld	bc, hl
	extz	xbc
	add	xbc, xde
	ld	a, (xbc)
	cp	a, 253
	jr	ugt, 7
	ld	(xbc), 255
	decdi8	1, (34948)
PdMed_NextUnmark:
	.byte 0xdb, 0x61, 0xd1, 0x00, 0x84, 0xf3, 0x67, 0xe4
PdMed_RefreshAfterToggle:
	ldda32	xwa, (33784)
	ldw_d16	bc, (33792)
	jr	119
PdMed_HandleSelectToggle:
	cp XHL,0x0000000b
	jr nz, PdMed_HandleRepeat
	cpdi8 (0x8462), 0x00
	jr nz, PdMed_HandleRepeat
	ld XWA,XIZ
	ld XBC,0x01e50003
	lds32 xde, 0
	calr FmmPdFileNameFunc
	lda_d16 xix, (0x8804)
	extz XHL
	add XHL,XIX
	ld C,(XHL)
	cp C,0xff
	jr nz, PdMed_RemoveFromOrder
	.byte 0xb3, 0x14, 0x84, 0x88, 0xc1, 0x84, 0x88, 0x61
	.byte 0x68, 0x3b
PdMed_RemoveFromOrder:
	cp	c, 253
	jr	ugt, 54
	ld	(xhl), 255
	ldb_d8	a, (34948)
	dec	1, a
	stb_d8	(34948), a
	lds	iz, 0
	lds	hl, 0
	extz	wa
	cps	wa, 0
	jr	ule, 31
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
	ldda32	xwa, (33784)
	ldw_d16	bc, (33792)
PdMed_CallFormatSlots:
	calr PdMed_FormatSlotList
	jrl PdMed_Exit

PdMed_HandleRepeat:
	cp	xhl, 12
	jr	nz, 24
	cp	xde, 29360151
	jr	nz, 8
	stdi8	(34952), 1
	jrl	173
PdMed_SetRepeatOff:
	stdi8	(34952), 0
	jrl	165
PdMed_HandlePlay:
	cp	xhl, 13
	jrl	nz, 156
	cpdi8	33890, 0
	jrl	nz, 148
	stdi8	34950, 0
	lds	hl, 0
	ldw_d16	wa, 33792
	cps	wa, 0
	jr	ule, 69
	lda_d16	xbc, 34820
PdMed_PlayFindLoop:
	ld	de, hl
	extz	xde
	add	xde, xbc
	.byte 0x82, 0x3f, 0x00
	jr	nz, 48
	stdi8	33890, 1
	extz	xhl
	ld	xwa, xiz
	ld	xbc, 31784962
	ld	xde, xhl
	calr	-1651
	incdi8	1, (34950)
	ld	xwa, 4294967295
	ld	xbc, 31457434
	lds32	xde, 0
	call	16423243
	ldw	wa, 117
	call	16355459
	jr	6
PdMed_PlayNextLoop:
	inc 1, hl
	cp hl, wa
	jr c, PdMed_PlayFindLoop

PdMed_CheckAutoPlay:
	cpdi8	33890, 0
	jr	nz, 57
	ld	xwa, 4294967295
	ld	xbc, 31457434
	lds32	xde, 0
	call	16423243
	ldw	wa, 113
	jr	32
PdMed_StoreDelayFlag:
	stda32	(33788), xwa
	jr	30
PdMed_CheckContinue:
	cpdi8 (0x8462), 0x00
	jr z, PdMed_Exit
	ld XWA,0xffffffff
	ld XBC,0x01e0009a
	lds32 xde, 0
	call ApPostEvent
	ldw WA, 0x0075
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
	stb_dri A, 0x07, 0xe4, 0xe8

DocDisk_SkipSpace:
	inc 1, xhl

DocDisk_CopyLoop:
	.byte 0xf1, 0xf0, 0x86, 0x31, 0x83, 0x3f, 0x00, 0x66
	.byte 0x06, 0xdc, 0xcf, 0x1e, 0x00, 0x61, 0xdf
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
	ld	de, iz
	sll	de, 5
	lda_d16	xbc, 33904
	extz	xde
	add	xde, xbc
	stb_erp	a, 248
	ld	(xde), a
	ld	wa, (xsp+2)
	add	wa, iz
	call	16295854
	ld	xbc, xhl
	ld	wa, iz
	sll	wa, 5
	lds	de, 1
	add	de, wa
	lda_d16	xhl, 33904
	ld	wa, de
	extz	xwa
	add	xwa, xhl
	ld	de, (xsp+2)
	add	de, iz
	inc	1, de
	pushw 12
	pushw 0
	call	16289232
	ld	de, iz
	sll	de, 5
	lda_d16	xbc, 33904
	extz	xde
	add	xde, xbc
	ld	xwa, (xsp+4)
	ld	xbc, 29360143
	call	16423243
	inc	1, iz
	cp	iz, 10
	jr	lt, -98
	popw	iz
	inc	6, xsp
	ret
FmmDocFileNameFunc:
	dec	4, xsp
	pushw	iz
	ld	(xsp+2), xwa
	cp	xbc, 31784963
	jrl	z, 484
	ldw_d16	wa, (33798)
	ld	iz, wa
	cp	xbc, 31784962
	jrl	z, 420
	ld	hl, wa
	exts	xhl
	divs	hl, 10
	cp	xbc, 29360152
	jr	z, 91
	cp	xbc, 29360151
	jr	z, 83
	cp	xbc, 29360139
	jr	z, 57
	cp	xbc, 31784964
	jr	nz, 62
	stda32	(33794), xde
	call	16294849
	stda16	(33798), hl
	cps	hl, 0
	jr	ge, 6
	stdi16	(33798), 0
DocName_UpdateIndex:
	ldw_d16	wa, (33798)
	exts	xwa
	divs	wa, 10
	ld	de, qwa
	exts	xde
	ldda32	xwa, (33794)
	ld	xbc, 31784962
	jrl	373
DocName_RefreshList:
	muls	hl, 10
	ldda32	xwa, (33794)
	ld	bc, hl
	calr	65291
DocName_ReturnZero:
	lds32 xhl, 0
	jrl DocName_Exit

DocName_HandleNavigation:
	.byte 0xea, 0xe2, 0x6e, 0x2d, 0xc1, 0x62, 0x84, 0x3f
	.byte 0x00, 0x6e, 0x26, 0xe9, 0xcf, 0x18, 0x00, 0xc0
	.byte 0x01, 0x6e, 0x0e, 0xd8, 0x89, 0xd9, 0x61, 0xd1
	.byte 0x6c, 0x84, 0xf1, 0x69, 0x77, 0xd8, 0x61, 0x68
	.byte 0x4c
DocName_CheckPrevKey:
	cp xbc, 0x1c00017
	jr nz, DocName_GetCurrentIndex
	cps wa, 0
	jr le, DocName_GetCurrentIndex
	dec 1, wa
	jr DocName_SaveIndex

DocName_CheckPageUp:
	.byte 0xea, 0xcf, 0x01, 0x00, 0x00, 0x00, 0x6e, 0x13
	.byte 0xc1, 0x62, 0x84, 0x3f, 0x00, 0x6e, 0x0c, 0xd8
	.byte 0xcf, 0x0a, 0x00, 0x61, 0x4e, 0xd8, 0xca, 0x0a
	.byte 0x00, 0x68, 0x21
DocName_CheckPageDown:
	.byte 0xea, 0xcf, 0x02, 0x00, 0x00, 0x00, 0x6e, 0x40
	.byte 0xc1, 0x62, 0x84, 0x3f, 0x00, 0x6e, 0x39, 0xd8
	.byte 0x89, 0xd9, 0xc8, 0x0a, 0x00, 0xd1, 0x6c, 0x84
	.byte 0x22, 0xda, 0xf1, 0x69, 0x0a, 0xd8, 0xc8, 0x0a
	.byte 0x00
DocName_SaveIndex:
	stda16	(33798), wa
	jr	37
DocName_CheckEndBound:
	ld	bc, de
	dec	1, bc
	ld	wa, bc
	exts	xwa
	divs	wa, 10
	cp	hl, wa
	jr	ge, 17
	exts	xde
	divs	de, 10
	ld	wa, qde
	cps	wa, 0
	jr	z, 4
	stda16	(33798), bc
DocName_GetCurrentIndex:
	ldw_d16	wa, (33798)
DocName_UpdateDisplay:
	cp	iz, wa
	jrl	z, -162
	call	16295241
	ldw_d16	wa, (33798)
	exts	xwa
	divs	wa, 10
	ld	de, qwa
	exts	xde
	ldda32	xwa, (33794)
	ld	xbc, 31784962
	call	16423243
	ldw_d16	bc, (33798)
	exts	xbc
	divs	bc, 10
	ld	de, iz
	exts	xde
	divs	de, 10
	ldda32	xwa, (33794)
	cp	de, bc
	jr	nz, 75
	ld	bc, iz
	exts	xbc
	divs	bc, 10
	ld	bc, qbc
	sll	bc, 5
	lda_d16	xhl, (33904)
	ld	de, bc
	extz	xde
	add	xde, xhl
	ld	xbc, 29360143
	call	16423243
	ldw_d16	wa, (33798)
	exts	xwa
	divs	wa, 10
	ld	wa, qwa
	sll	wa, 5
	lda_d16	xbc, (33904)
	ld	de, wa
	extz	xde
	add	xde, xbc
	ldda32	xwa, (33794)
	ld	xbc, 29360143
	call	16423243
	jrl	-295
DocName_RefreshPage:
	muls bc, 0xa
	calr DocMed_FormatFileList
	ld xwa, (xsp + 2)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	calr FmmDocMedleyFunc
	jrl DocName_ReturnZero

DocName_SetIndexPlaying:
	cpdi8 (0x8462), 0x00
	jrl z, DocName_ReturnZero
	stda16 (0x8406), de

	ld wa, de

	.byte 0x1d, 0x49, 0xa5, 0xf8	; call FileIO_SelectFileByIndex (v7 addr)

	.byte 0xd1, 0x06, 0x84, 0x20	; ldw_d16 xwa, (0x84a2) (v7 patched)

	exts xwa

	divs wa, 0xa

	stw_erp DE, 0xe2

	exts xde

	ldda32 xwa, (33794)

	ld xbc, 0x1e50002



DocName_PostEvent:
	call ApPostEvent
	jrl DocName_ReturnZero

DocName_GetIndexReturn:
	ldw_d16	hl, (33798)
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
	ld	wa, iz
	sll	wa, 3
	lda_d16	xbc, 33800
	extz	xwa
	add	xwa, xbc
	ld	bc, qiz
	add	bc, iz
	lda_d16	xde, 34820
	extz	xbc
	add	xbc, xde
	ld	c, (xbc)
	extz	bc
	ld	de, iz
	calr	-8258
	ld	de, iz
	sll	de, 3
	lda_d16	xwa, 33800
	extz	xde
	add	xde, xwa
	ld	xwa, (xsp+6)
	ld	xbc, 29360143
	call	16423243
	inc	1, iz
	.byte 0x9f, 0x04, 0xf6
	jr	c, -67
DocFmtSlot_FillEmpty:
	cp iz, 0xa
	jr nc, DocFmtSlot_Exit

DocFmtSlot_EmptyLoop:
	ld	wa, iz
	sll	wa, 3
	lda_d16	xbc, (33800)
	extz	xwa
	add	xwa, xbc
	ldw	bc, 255
	ld	de, iz
	calr	57219
	ld	de, iz
	sll	de, 3
	lda_d16	xwa, (33800)
	extz	xde
	add	xde, xwa
	ld	xwa, (xsp+6)
	ld	xbc, 29360143
	call	16423243
	inc	1, iz
	cp	iz, 10
	jr	c, -54
DocFmtSlot_Exit:
	pop xiz
	inc 6, xsp
	ret

FmmDocMedleyFunc:
	push	xiz
	ld	xhl, xde
	ld	xde, xbc
	ld	xiz, xwa
	cp	xde, 31784970
	jrl	z, 1014
	ld	xwa, xhl
	cp	xde, 31784968
	jrl	z, 997
	ldw_d16	bc, (33888)
	cp	xde, 29360152
	jrl	z, 548
	cp	xde, 29360151
	jrl	z, 539
	cp	xde, 29360139
	jrl	z, 520
	cp	xde, 31784964
	jrl	z, 504
	cp	xde, 29360147
	jrl	nz, 984
	cp	xhl, 3
	jrl	z, 454
	cp	xhl, 2
	jrl	nz, 966
	lds	wa, 0
	call	16297463
	ldb_d8	a, (35995)
	cp	a, 112
	jr	nz, 25
	stdi8	(33890), 0
	call	15861571
	cps	l, 2
	jrl	c, 937
	stdi8	(32422), 1
	ldw	wa, 238
	jrl	242
DocMed_CheckPlayMode:
	cp	a, 116
	jrl	nz, 243	; -> 0xF93ADD
	call	Medley_GetPlaybackStatus
	cps	l, 1
	jrl	nz, 205	; -> 0xF93AC0
	stdi8	(33890), 1
	ldb_d8	c, (34950)
	lda_d16	xwa, (34820)
	cpda8	xhl, (34948)
	jr	nc, 80	; -> 0xF93A56
	lds	hl, 0
	ldw_d16	de, (33888)
	cps	de, 0
	jrl	ule, 881	; -> 0xF93D82
DocMed_FindSongLoop:
	ld	ix, hl
	extz	xix
	add	xix, xwa
	cp	(xix), c
	jr	nz, 50
	extz	xhl
	ld	xwa, xiz
	ld	xbc, 31784962
	ld	xde, xhl
	calr	64617
	ldda32	xwa, (33880)
	ldw_d16	bc, (33888)
	calr	65115
	incdi8	1, (34950)
	ldda32	xwa, (33884)
	or	xwa, xwa
	jrl	z, 833
	ld	xbc, 31784969
	ld	xde, 30
	jr	91
DocMed_NextSong:
	inc 1, hl
	cp hl, de
	jr c, DocMed_FindSongLoop
	jrl DocMed_Exit

DocMed_CheckRepeat:
	.byte 0xc1, 0x88, 0x88, 0x3f, 0x00, 0x66, 0x5b, 0xf1
	.byte 0x86, 0x88, 0x00, 0x00, 0xdb, 0xa8, 0xd1, 0x60
	.byte 0x84, 0x21, 0xd9, 0xd8, 0x73, 0x15, 0x03
DocMed_RepeatFindLoop:
	.byte 0xdb, 0x8a, 0xea, 0x12, 0xe8, 0x82, 0x82, 0x3f
	.byte 0x00, 0x6e, 0x37, 0xeb, 0x12, 0xee, 0x88, 0x41
	.byte 0x02, 0x00, 0xe5, 0x01, 0xeb, 0x8a, 0x1e, 0x0c
	.byte 0xfc, 0xe1, 0x58, 0x84, 0x20, 0xd1, 0x60, 0x84
	.byte 0x21, 0x1e, 0xfe, 0xfd, 0xc1, 0x86, 0x88, 0x61
	.byte 0xe1, 0x5c, 0x84, 0x20, 0xe8, 0xe0, 0x76, 0xe4
	.byte 0x02, 0x41, 0x09, 0x00, 0xe5, 0x01, 0x42, 0x1e
	.byte 0x00, 0x00, 0x00
DocMed_PostDelayEvent:
	call ApPostEvent
	jrl DocMed_Exit

DocMed_RepeatNext:
	inc 1, hl
	cp hl, bc
	jr c, DocMed_RepeatFindLoop
	jrl DocMed_Exit

DocMed_ClearPlaying:
	stdi8	(33890), 0
	jrl	706
DocMed_HandleError:
	call	15861571
	stdi8	(33890), 0
	cps	l, 0
	jrl	z, 692
	stdi8	(32422), 1
	ldw	wa, 238
DocMed_ShowError:
	call SoundCtrl_SendCommand
	jrl DocMed_Exit

DocMed_CheckInit_Entry:
DocMed_CheckInit:
	cpdi16	33900, 0
	jr	lt, 8
	cpdi16	33896, 0
	jr	nz, 66
DocMed_InitFromDisk:
	stdi16	(33896), 65535
	ld	xwa, 6291494
	ld	xbc, 29360129
	lds32	xde, 5
	call	16423243
	call	16295369
	stda16	(33900), hl
	ld	xwa, 6291494
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	ld	xwa, 4294967295
	ld	xbc, 29360138
	lds32	xde, 0
	call	16423243
	call	16297555
DocMed_InitState:
	stdi8	(33890), 0
	stdi8	(34950), 0
	stdi8	(34948), 0
	ldw	bc, 128
	ldw_d16	wa, (33900)
	cp	wa, 128
	jr	ugt, 2
	ld	bc, wa
DocMed_ClampCount:
	stda16	(33888), bc
	lds	hl, 0
	cps	bc, 0
	jr	ule, 21
	lda_d16	xwa, (34820)
DocMed_ClearSlotsLoop:
	ld	bc, hl
	extz	xbc
	add	xbc, xwa
	ld	(xbc), 255
	inc	1, hl
	cpda16	xhl, (33888)
	jr	c, -17	; -> 0xF93B5B
DocMed_FinishInit:
	call	15862435
	lds32	xwa, 0
	stda32	(33884), xwa
	jrl	521
DocMed_HandleStop:
	ldb_d8	a, (35994)
	cp	a, 112
	jrl	z, 511
	cp	a, 116
	jrl	z, 505
	call	15862598
	call	16297527
	stdi8	(33890), 0
	jrl	489
DocMed_StoreWindowPtr:
	stda32	(33880), xwa
	jrl	482
DocMed_RefreshDisplay:
	ldda32	xwa, (33880)
	calr	64744
	jrl	472
DocMed_HandleNavToggle:
	cp XHL,0x0000000a
	jrl nz, DocMed_HandleSelectToggle
	cpdi8 (0x8462), 0x00
	jr nz, DocMed_HandleSelectToggle
	lds hl, 0
	ld WA,BC
	cps bc, 0
	jr ule, DocMed_CheckAllUnmarked
	lda_d16 xbc, (0x8804)
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
	jr	nc, 41
	lds	hl, 0
	cps	wa, 0
	jr	ule, 73
	lda_d16	xde, (34820)
DocMed_AssignOrderLoop:
	.byte 0xdb, 0x89, 0xe9, 0x12, 0xea, 0x81, 0x81, 0x21
	.byte 0xc9, 0xcf, 0xff, 0x6e, 0x08, 0xb1, 0x14, 0x84
	.byte 0x88, 0xc1, 0x84, 0x88, 0x61
DocMed_NextAssign:
	.byte 0xdb, 0x61, 0xd1, 0x60, 0x84, 0xf3, 0x67, 0xe3
	.byte 0x68, 0x26
DocMed_RemoveOrderLoop:
	lds	hl, 0
	cps	wa, 0
	jr	ule, 32
	lda_d16	xde, (34820)
DocMed_UnmarkLoop:
	ld	bc, hl
	extz	xbc
	add	xbc, xde
	ld	a, (xbc)
	cp	a, 253
	jr	ugt, 7
	ld	(xbc), 255
	decdi8	1, (34948)
DocMed_NextUnmark:
	.byte 0xdb, 0x61, 0xd1, 0x60, 0x84, 0xf3, 0x67, 0xe4
DocMed_RefreshAfterToggle:
	ldda32	xwa, (33880)
	ldw_d16	bc, (33888)
	jr	119
DocMed_HandleSelectToggle:
	cp XHL,0x0000000b
	jr nz, DocMed_HandleRepeat
	cpdi8 (0x8462), 0x00
	jr nz, DocMed_HandleRepeat
	ld XWA,XIZ
	ld XBC,0x01e50003
	lds32 xde, 0
	calr FmmDocFileNameFunc
	lda_d16 xix, (0x8804)
	extz XHL
	add XHL,XIX
	ld C,(XHL)
	cp C,0xff
	jr nz, DocMed_RemoveFromOrder
	.byte 0xb3, 0x14, 0x84, 0x88, 0xc1, 0x84, 0x88, 0x61
	.byte 0x68, 0x3b
DocMed_RemoveFromOrder:
	cp	c, 253
	jr	ugt, 54
	ld	(xhl), 255
	ldb_d8	a, (34948)
	dec	1, a
	stb_d8	(34948), a
	lds	iz, 0
	lds	hl, 0
	extz	wa
	cps	wa, 0
	jr	ule, 31
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
	ldda32	xwa, (33880)
	ldw_d16	bc, (33888)
DocMed_CallFormatSlots:
	calr DocMed_FormatSlotList
	jrl DocMed_Exit

DocMed_HandleRepeat:
	cp	xhl, 12
	jr	nz, 24
	cp	xde, 29360151
	jr	nz, 8
	stdi8	(34952), 1
	jrl	185
DocMed_SetRepeatOff:
	stdi8	(34952), 0
	jrl	177
DocMed_HandlePlay:
	cp	xhl, 13
	jrl	nz, 168
	cpdi8	33890, 0
	jrl	nz, 160
	stdi8	34950, 0
	lds	hl, 0
	ldw_d16	wa, 33888
	cps	wa, 0
	jr	ule, 69
	lda_d16	xbc, 34820
DocMed_PlayFindLoop:
	ld	de, hl
	extz	xde
	add	xde, xbc
	.byte 0x82, 0x3f, 0x00
	jr	nz, 48
	stdi8	33890, 1
	extz	xhl
	ld	xwa, xiz
	ld	xbc, 31784962
	ld	xde, xhl
	calr	-1665
	incdi8	1, (34950)
	ld	xwa, 4294967295
	ld	xbc, 31457434
	lds32	xde, 0
	call	16423243
	ldw	wa, 116
	call	16355459
	jr	6
DocMed_PlayNextLoop:
	inc 1, hl
	cp hl, wa
	jr c, DocMed_PlayFindLoop

DocMed_CheckAutoPlay:
	cpdi8	33890, 0
	jr	nz, 69
	ld	xwa, xiz
	ld	xbc, 31784963
	lds32	xde, 0
	calr	-1719
	ld	xwa, 4294967295
	ld	xbc, 31457434
	lds32	xde, 0
	call	16423243
	ldw	wa, 112
	jr	32
DocMed_StoreDelayFlag:
	stda32	(33884), xwa
	jr	30
DocMed_CheckContinue:
	cpdi8 (0x8462), 0x00
	jr z, DocMed_Exit
	ld XWA,0xffffffff
	ld XBC,0x01e0009a
	lds32 xde, 0
	call ApPostEvent
	ldw WA, 0x0074
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
	pushw	iz
	ld	iz, bc
	calr	-43
	cp	hl, iz
	scc	z, hl
	popw	iz
	ret

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
	lda xsp, (xsp - 0x0e)
	lda XBC, (XSP)
	ld XWA,0x01600004
	ld (XBC),XWA
	lda_24 xwa, (ClassProc)
	ld (XBC+0x04),XWA
	ldw_da wa, (0xea1186)
	ld (XBC+0x08),WA
	lda_24 xwa, (0xea0f46)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0165
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000c
	ld (XBC),XWA
	lda_24 xwa, (ResEventProc)
	ld (XBC+0x04),XWA
	ldw_da wa, (0xea11f2)
	ld (XBC+0x08),WA
	lda_24 xwa, (PtrTbl_EventNames_EA1188)
	ld (XBC+0x0a),XWA
	ldw WA, 0x01c5
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000d
	ld (XBC),XWA
	lda_24 xwa, (ResMethodProc)
	ld (XBC+0x04),XWA
	ldw_da wa, (0xea1358)
	ld (XBC+0x08),WA
	lda_24 xwa, (0xea11f4)
	ld (XBC+0x0a),XWA
	ldw WA, 0x01e5
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600002
	ld (XBC),XWA
	lda_24 xwa, (ApFunctionProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x001d
	lda_24 xwa, (0xea0a56)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0125
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600002
	ld (XBC),XWA
	lda_24 xwa, (ApFunctionProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x001d
	lda_24 xwa, (PtrTbl_DiskFuncNames)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0425
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600001
	ld (XBC),XWA
	lda_24 xwa, (FunctionProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x000d
	lda_24 xwa, (0xea135a)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0105
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600001
	ld (XBC),XWA
	lda_24 xwa, (FunctionProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x000d
	lda_24 xwa, (PtrTbl_NakaModuleHandlers)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0405
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600003
	ld (XBC),XWA
	lda_24 xwa, (MainFunctionProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0039
	lda_24 xwa, (0xea7fce)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0145
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600003
	ld (XBC),XWA
	lda_24 xwa, (MainFunctionProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0039
	lda_24 xwa, (0xea80b6)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0445
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x004a
	lda_24 xwa, (0xea67b6)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0060
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x004a
	lda_24 xwa, (0xea6fe2)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0360
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0080
	lda_24 xwa, (0xea68e2)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0061
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0080
	lda_24 xwa, (0xea7228)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0361
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda_24 xwa, (0xea6ae6)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0062
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda_24 xwa, (0xea75c6)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0362
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda_24 xwa, (0xea6aea)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0063
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda_24 xwa, (0xea75cc)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0363
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda_24 xwa, (0xea6aee)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0064
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda_24 xwa, (0xea75d2)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0364
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0003
	lda_24 xwa, (0xea6af2)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0065
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0003
	lda_24 xwa, (0xea75d8)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0365
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda_24 xwa, (0xea6b02)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0066
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda_24 xwa, (0xea75fc)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0366
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0047
	lda_24 xwa, (0xea6b06)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0067
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0047
	lda_24 xwa, (0xea7602)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0367
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda_24 xwa, (0xea6c26)
	ld (XBC+0x0a),XWA
	ldw WA, 0x006a
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda_24 xwa, (0xea77e4)
	ld (XBC+0x0a),XWA
	ldw WA, 0x036a
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0015
	lda_24 xwa, (0xea6c2a)
	ld (XBC+0x0a),XWA
	ldw WA, 0x006b
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0015
	lda_24 xwa, (0xea77ea)
	ld (XBC+0x0a),XWA
	ldw WA, 0x036b
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0053
	lda_24 xwa, (0xea6c82)
	ld (XBC+0x0a),XWA
	ldw WA, 0x006c
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0053
	lda_24 xwa, (0xea7878)
	ld (XBC+0x0a),XWA
	ldw WA, 0x036c
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda_24 xwa, (0xea6dd2)
	ld (XBC+0x0a),XWA
	ldw WA, 0x006d
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda_24 xwa, (0xea7aca)
	ld (XBC+0x0a),XWA
	ldw WA, 0x036d
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda_24 xwa, (0xea6dd6)
	ld (XBC+0x0a),XWA
	ldw WA, 0x006e
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda_24 xwa, (0xea7ad0)
	ld (XBC+0x0a),XWA
	ldw WA, 0x036e
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0015
	lda_24 xwa, (0xea6dda)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0077
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0015
	lda_24 xwa, (0xea7ad6)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0377
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda_24 xwa, (0xea6e32)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0079
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda_24 xwa, (0xea7b8c)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0379
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x005e
	lda_24 xwa, (0xea6e36)
	ld (XBC+0x0a),XWA
	ldw WA, 0x007b
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x005e
	lda_24 xwa, (0xea7b92)
	ld (XBC+0x0a),XWA
	ldw WA, 0x037b
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda_24 xwa, (0xea6fb2)
	ld (XBC+0x0a),XWA
	ldw WA, 0x007c
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda_24 xwa, (0xea7e98)
	ld (XBC+0x0a),XWA
	ldw WA, 0x037c
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda_24 xwa, (0xea6fb6)
	ld (XBC+0x0a),XWA
	ldw WA, 0x007d
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda_24 xwa, (0xea7e9e)
	ld (XBC+0x0a),XWA
	ldw WA, 0x037d
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0008
	lda_24 xwa, (0xea6fba)
	ld (XBC+0x0a),XWA
	ldw WA, 0x007e
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0008
	lda_24 xwa, (0xea7ea4)
	ld (XBC+0x0a),XWA
	ldw WA, 0x037e
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x01600010
	ld (XBC),XWA
	lda_24 xwa, (ViewableProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda_24 xwa, (0xea6fde)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00bc
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,0x0160000f
	ld (XBC),XWA
	lda_24 xwa, (ResNameProc)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0000
	lda_24 xwa, (0xea7ee2)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03bc
	call RegisterObjectTable
	pushw 0x0005
	pushw 0x00ea
	pushw 0x7ee8
	.byte 0xe8, 0xae, 0x41, 0x00, 0x00, 0x20, 0x01, 0x42
	.byte 0x60, 0x00, 0xa0, 0x01, 0x1d, 0x1e, 0x49, 0xfa
	.byte 0x0b, 0x05, 0x00, 0x0b, 0xea, 0x00, 0x0b, 0xf0
	.byte 0x7e, 0x40, 0x60, 0x00, 0x00, 0x00, 0x41, 0x00
	.byte 0x00, 0x20, 0x01, 0x42, 0x00, 0x00, 0x60, 0x00
	.byte 0x1d, 0x73, 0x49, 0xfa, 0x0b, 0x05, 0x00, 0x0b
	.byte 0xea, 0x00, 0x0b, 0xfa, 0x7e, 0x40, 0x61, 0x00
	.byte 0x00, 0x00, 0x41, 0x27, 0x00, 0x45, 0x01, 0x42
	.byte 0x00, 0x00, 0x61, 0x00, 0x1d, 0x73, 0x49, 0xfa
	.byte 0x0b, 0x05, 0x00, 0x0b, 0xea, 0x00, 0x0b, 0x02
	.byte 0x7f, 0x40, 0x62, 0x00, 0x00, 0x00, 0x41, 0x36
	.byte 0x00, 0x45, 0x01, 0x42, 0x69, 0x00, 0x61, 0x00
	.byte 0x1d, 0x73, 0x49, 0xfa, 0x0b, 0x05, 0x00, 0x0b
	.byte 0xea, 0x00, 0x0b, 0x10, 0x7f, 0x40, 0x63, 0x00
	.byte 0x00, 0x00, 0x41, 0x37, 0x00, 0x45, 0x01, 0x42
	.byte 0x2b, 0x00, 0x60, 0x00, 0x1d, 0x73, 0x49, 0xfa
	.byte 0x0b, 0x05, 0x00, 0x0b, 0xea, 0x00, 0x0b, 0x1a
	.byte 0x7f, 0x40, 0x64, 0x00, 0x00, 0x00, 0x41, 0x29
	.byte 0x00, 0x45, 0x01, 0x42, 0x4b, 0x00, 0x61, 0x00
	.byte 0x1d, 0x73, 0x49, 0xfa, 0x0b, 0x05, 0x00, 0x0b
	.byte 0xea, 0x00, 0x0b, 0x26, 0x7f, 0x40, 0x65, 0x00
	.byte 0x00, 0x00, 0x41, 0x00, 0x00, 0x20, 0x01, 0x42
	.byte 0x00, 0x00, 0x65, 0x00, 0x1d, 0x73, 0x49, 0xfa
	.byte 0x0b, 0x05, 0x00, 0x0b, 0xea, 0x00, 0x0b, 0x32
	.byte 0x7f, 0x40, 0x66, 0x00, 0x00, 0x00, 0x41, 0x00
	.byte 0x00, 0x20, 0x01, 0x42, 0x18, 0x00, 0x60, 0x00
	.byte 0x1d, 0x73, 0x49, 0xfa, 0x0b, 0x05, 0x00, 0x0b
	.byte 0xea, 0x00, 0x0b, 0x3e, 0x7f, 0x40, 0x67, 0x00
	.byte 0x00, 0x00, 0x41, 0x28, 0x00, 0x45, 0x01, 0x42
	.byte 0x00, 0x00, 0x67, 0x00, 0x1d, 0x73, 0x49, 0xfa
	.byte 0x0b, 0x05, 0x00, 0x0b, 0xea, 0x00, 0x0b, 0x46
	.byte 0x7f, 0x40, 0x6a, 0x00, 0x00, 0x00, 0x41, 0x00
	.byte 0x00, 0x20, 0x01, 0x42, 0x28, 0x00, 0x60, 0x00
	.byte 0x1d, 0x73, 0x49, 0xfa, 0x0b, 0x05, 0x00, 0x0b
	.byte 0xea, 0x00, 0x0b, 0x56, 0x7f, 0x40, 0x6b, 0x00
	.byte 0x00, 0x00, 0x41, 0x2d, 0x00, 0x45, 0x01, 0x42
	.byte 0x00, 0x00, 0x6b, 0x00, 0x1d, 0x73, 0x49, 0xfa
	.byte 0x0b, 0x05, 0x00, 0x0b, 0xea, 0x00, 0x0b, 0x62
	.byte 0x7f, 0x40, 0x6c, 0x00, 0x00, 0x00, 0x41, 0x1c
	.byte 0x00, 0x45, 0x01, 0x42, 0x00, 0x00, 0x6c, 0x00
	.byte 0x1d, 0x73, 0x49, 0xfa, 0x0b, 0x05, 0x00, 0x0b
	.byte 0xea, 0x00, 0x0b, 0x6e, 0x7f, 0x40, 0x6d, 0x00
	.byte 0x00, 0x00, 0x41, 0x1e, 0x00, 0x45, 0x01, 0x42
	.byte 0x26, 0x00, 0x6c, 0x00, 0x1d, 0x73, 0x49, 0xfa
	.byte 0x0b, 0x05, 0x00, 0x0b, 0xea, 0x00, 0x0b, 0x7a
	.byte 0x7f, 0x40, 0x6e, 0x00, 0x00, 0x00, 0x41, 0x1d
	.byte 0x00, 0x45, 0x01, 0x42, 0x3d, 0x00, 0x6c, 0x00
	.byte 0x1d, 0x73, 0x49, 0xfa, 0x0b, 0x05, 0x00, 0x0b
	.byte 0xea, 0x00, 0x0b, 0x84, 0x7f, 0x40, 0x77, 0x00
	.byte 0x00, 0x00, 0x41, 0x26, 0x00, 0x45, 0x01, 0x42
	.byte 0x00, 0x00, 0x77, 0x00, 0x1d, 0x73, 0x49, 0xfa
	.byte 0x0b, 0x05, 0x00, 0x0b, 0xea, 0x00, 0x0b, 0x8e
	.byte 0x7f, 0x40, 0x79, 0x00, 0x00, 0x00, 0x41, 0x11
	.byte 0x00, 0x45, 0x01, 0x42, 0x0a, 0x00, 0x60, 0x00
	.byte 0x1d, 0x73, 0x49, 0xfa, 0x0b, 0x05, 0x00, 0x0b
	.byte 0xea, 0x00, 0x0b, 0x98, 0x7f, 0x40, 0x7b, 0x00
	.byte 0x00, 0x00, 0x41, 0x31, 0x00, 0x45, 0x01, 0x42
	.byte 0x00, 0x00, 0x7b, 0x00, 0x1d, 0x73, 0x49, 0xfa
	.byte 0x0b, 0x05, 0x00, 0x0b, 0xea, 0x00, 0x0b, 0xa0
	.byte 0x7f, 0x40, 0x7c, 0x00, 0x00, 0x00, 0x41, 0x32
	.byte 0x00, 0x45, 0x01, 0x42, 0x19, 0x00, 0x7b, 0x00
	.byte 0x1d, 0x73, 0x49, 0xfa, 0x0b, 0x05, 0x00, 0x0b
	.byte 0xea, 0x00, 0x0b, 0xac, 0x7f, 0x40, 0x7d, 0x00
	.byte 0x00, 0x00, 0x41, 0x21, 0x00, 0x45, 0x01, 0x42
	.byte 0x18, 0x00, 0x7b, 0x00, 0x1d, 0x73, 0x49, 0xfa
	.byte 0x0b, 0x05, 0x00, 0x0b, 0xea, 0x00, 0x0b, 0xb8
	.byte 0x7f, 0x40, 0x7e, 0x00, 0x00, 0x00, 0x41, 0x00
	.byte 0x00, 0x20, 0x01, 0x42, 0x00, 0x00, 0x7e, 0x00
	.byte 0x1d, 0x73, 0x49, 0xfa, 0x0b, 0x05, 0x00, 0x0b
	.byte 0xea, 0x00, 0x0b, 0xc4, 0x7f, 0x40, 0xbc, 0x00
	.byte 0x00, 0x00, 0x41, 0x25, 0x00, 0x45, 0x01, 0x42
	.byte 0x1b, 0x00, 0x60, 0x00, 0x1d, 0x73, 0x49, 0xfa
	.byte 0xbf, 0x0e, 0x37, 0x0e
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
	push	xiz
	ld	xiz, xwa
	cp	xbc, 29360135
	jr	z, 45
	cp	xbc, 31457404
	jr	z, 33
	cp	xbc, 31457412
	jr	z, 118
	cp	xbc, 31457338
	jr	nz, 110
	pushw	234
	pushw	35830
	push	xde
	call	16713584
	inc	8, xsp
	ld	xhl, xiz
	jr	95
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
	push	xiz
	ld	xiz, xwa
	cp	xbc, 29360135
	jr	z, 49
	cp	xbc, 31457404
	jr	z, 36
	cp	xbc, 31457412
	jrl	z, 183
	cp	xbc, 31457338
	jrl	nz, 174
	pushw	234
	pushw	35834
	push	xde
	call	16713584
	inc	8, xsp
	ld	xhl, xiz
	jrl	158
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

