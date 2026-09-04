FmmSmfLoadTitleFunc:
	cp	xbc, 29360135
	jrl	z, 396
	cp	xbc, 29360147
	jrl	nz, 414
	cp	xde, 3
	jrl	z, 373
	cp	xde, 2
	jrl	nz, 396
	ld	(33890:16), 0
	lds	wa, 1
	calr	-10615
	ld	xwa, 6291494
	ld	xbc, 29360129
	lds32	xde, 5
	call	16423243
	.byte 0xc1, 0x9b, 0x8c, 0x19, 0xee, 0x7f
	cpw	(33892:16), 0
	jr	ge, 13
	call	16290067
	extz	hl
	ld	(33892:16), hl
	calr	-10566
SmfLoad_DispatchState:
	ld	wa, (33892:16)
	cps	wa, 1
	jrl	z, 193
	cps	wa, 0
	jrl	z, 166
	cps	wa, 5
	jr	z, 94
	cpw	(33896:16), 0
	jr	ge, 19
	call	16291947
	ld	(33896:16), hl
	call	16290176
	call	16290094
	calr	-10611
SmfLoad_CheckFileCount:
	cpw	(33896:16), 0
	jrl	nz, 223
	cpw	(33894:16), 0
	jr	ge, 11
	call	16290928
	ld	(33894:16), hl
	calr	-10639
SmfLoad_CheckSlotCount:
	.byte 0xd1, 0x66, 0x84, 0x3f, 0x00, 0x00	; cpdi16 0x8502, 0 (v7 patched)

	.byte 0x72, 0xc3, 0x00	; jrl le, SmfLoad_SendWait (v7 displacement)

	.byte 0xc1, 0xee, 0x7f, 0x3f, 0x61	; cpdi8 (0x808a), 97 (v7 patched)

	.byte 0x76, 0xbb, 0x00	; jrl z, SmfLoad_SendWait (v7 displacement)

	ld xwa, 0x600026

	ld xbc, 0x1c00002

	lds32 xde, 0

	call	16423243

	ldw wa, 0x61

	jrl	227



SmfLoad_AbortPartial:
	ld	xwa, 6291494
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 1
	call	16423243
	ld	a, (32750:16)
	extz	wa
	call	16355459
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 0
	call	16423243
	ld	(32422:16), 0
	ldw	wa, 238
	jr	91
SmfLoad_ErrorCancel:
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0x7d
	jrl SmfLoad_CallHandler

SmfLoad_Success:
	calr	54569
	ld	xwa, 6291494
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 1
	call	16423243
	ld	a, (32750:16)
	extz	wa
	call	16355459
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 0
	call	16423243
	ld	(32422:16), 2
	ldw	wa, 238
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
	cp	xde, 15
	jr	nz, 19
	cp	(35992:16), 7
	jr	nz, 5
	ldw	wa, 214
	jr	3
SmfLoad_OkReturnCode:
	ldw wa, 0x60

SmfLoad_CallHandler:
	call UI_PostModeChangeEvent

SmfLoad_Return:
	lds32 xhl, 0
	ret
FmmSmfSaveTitleFunc:
	cp	xbc, 29360147
	jr	nz, 106
	cp	xde, 3
	jr	z, 95
	cp	xde, 2
	jr	nz, 90
	ld	(33890:16), 0
	lds	wa, 1
	calr	-11038
	ld	xwa, 6291494
	ld	xbc, 29360129
	lds32	xde, 5
	call	16423243
	cpw	(33896:16), 0
	jr	ge, 19
	call	16291947
	ld	(33896:16), hl
	call	16290176
	call	16290094
	calr	-10989
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
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	lda	xwa, (34740:16)
	cp	xbc, 31457414
	jr	z, 121
	cp	xbc, 31457338
	jr	z, 69
	cp	xbc, 29360139
	jr	z, 19
	cp	xbc, 31784964
	jrl	nz, 140
	ld	xwa, (xsp+4)
	ld	(32752:16), xwa
	jrl	130
SaveFN_HandleActivate:
	ld	(xwa), 0
	lda	xiz, (xwa+1)
	call	16289480
	ld	xbc, xhl
	ld	xwa, xiz
	call	16288975
	lda	xwa, (34741:16)
	call	16289424
	ld	xwa, (32752:16)
	ld	xbc, 29360143
	ld	xde, 34740
	jr	38
SaveFN_HandleTextChange:
	ld	xiz, xwa
	call	16289480
	ld	xbc, xhl
	ld	xwa, xiz
	call	16288975
	ld	xwa, 34740
	ldw	bc, 8
	calr	65344
	ld	xwa, (xsp+4)
	ld	xbc, 31457414
	ld	xde, 34740
SaveFN_SendEvent:
	call ApPostEvent
	jr SaveFN_Return

SaveFN_HandleApply:
	ld	xbc, (xsp+4)
	ldw	de, 8
	call	16288997
	ld	xwa, 34740
	ldw	bc, 8
	calr	65304
	ld	xwa, 34740
	ld	xbc, 15337270
	call	16289030
	ld	xwa, 34740
	call	16289486
SaveFN_Return:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret

SmfSeqToSongNumFunc:
	push	xiz
	cp	xbc, 29360139
	jr	z, 14
	cp	xbc, 31784964
	jr	nz, 66
	ld	(32756:16), xde
	jr	60
SeqToSong_BuildEntry:
	lda	xwa, (32760:16)
	stib_dsp	224, 0
	ld	xbc, 15337276
	call	16288975
	lda	xiz, (32761:16)
	ld	a, (34988:16)
	inc	1, a
	extz	wa
	lds	bc, 2
	calr	55244
	ld	xbc, xhl
	ld	xwa, xiz
	call	16289030
	ld	xwa, (32756:16)
	ld	xbc, 29360143
	ld	xde, 32760
	call	16423243
SeqToSong_Return:
	lds32 xhl, 0
	pop xiz
	ret

SmfSeqFromSongNumFunc:
	push	xiz
	cp	xbc, 29360139
	jr	z, 14
	cp	xbc, 31784964
	jr	nz, 66
	ld	(32888:16), xde
	jr	60
SeqFromSong_BuildEntry:
	lda	xwa, (32892:16)
	stib_dsp	224, 0
	ld	xbc, 15337288
	call	16288975
	lda	xiz, (32893:16)
	ld	a, (34988:16)
	inc	1, a
	extz	wa
	lds	bc, 2
	calr	55157
	ld	xbc, xhl
	ld	xwa, xiz
	call	16289030
	ld	xwa, (32888:16)
	ld	xbc, 29360143
	ld	xde, 32892
	call	16423243
SeqFromSong_Return:
	lds32 xhl, 0
	pop xiz
	ret

SmfSeqSongNameFunc:
	cp	xbc, 29360139
	jr	z, 14
	cp	xbc, 31784964
	jr	nz, 34
	ld	(33020:16), xde
	jr	28
SeqSongName_BuildEntry:
	ld	a, (34988:16)
	extz	wa
	lds	bc, 0
	lds	de, 0
	calr	15000
	ld	xde, xhl
	ld	xwa, (33020:16)
	ld	xbc, 29360143
	call	16423243
SeqSongName_Return:
	lds32 xhl, 0
	ret

SmfLoadAsFunc:
	cp	xbc, 29360139
	jr	z, 14
	cp	xbc, 31784964
	jr	nz, 38
	ld	(33024:16), xde
	jr	32
SmfLoadAs_Apply:
	ld	a, (34986:16)
	extz	wa
	sla	wa, 2
	lda	xbc, (15337300:24)
	ld_rrl	xde, xbc, wa
	ld	xwa, (33024:16)
	ld	xbc, 29360143
	call	16423243
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
	ld	de, iz
	sll	de, 5
	lda	xbc, (33904:16)
	extz	xde
	add	xde, xbc
	stb_erp	a, 248
	ld	(xde), a
	ld	wa, (xsp+2)
	add	wa, iz
	call	16291811
	ld	xbc, xhl
	ld	wa, iz
	sll	wa, 5
	lds	de, 1
	add	de, wa
	lda	xhl, (33904:16)
	ld	wa, de
	extz	xwa
	add	xwa, xhl
	ld	de, (xsp+2)
	add	de, iz
	inc	1, de
	.byte 0x0b, 0x0c, 0x00, 0x0b, 0x01, 0x00
	call	16289232
	ld	de, iz
	sll	de, 5
	lda	xbc, (33904:16)
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
	lda xsp, (xsp - 0x20)
	push XIZ
	ld XIZ,XDE
	ld (XSP+0x1c),XBC
	ld (XSP+0x20),XWA
	ld XDE,(XSP+0x1c)
	ld	xwa, (33028:16)
	ld	xbc, (xsp+28)
	cp	xbc, 29360152
	jrl	z, 171
	cp	xbc, 29360151
	jrl	z, 162
	cp	xbc, 29360139
	jrl	z, 131
	ld	xbc, xiz
	sub	xde, 31784962
	cp	xde, 0
	jrl	lt, 131
	cp	xde, 5
	jr	gt, 123
	add	xde, xde
	add	xde, 15337374
	ld	de, (xde)
	lda	xix, (16309435:24)
SmfFN_JumpTable:
	jp_rr 8, xix, de
	ld	(33028:16), xbc
	lds32	xwa, 0
	ld	(33032:16), xwa
	ld	(33036:16), xwa
	cp	(35994:16), 107
	jr	z, 20
	call	16291514
	ld	(33040:16), hl
	cps	hl, 0
	jr	ge, 26
	ldw	(33040:16), 0
	jr	18
	ld	wa, (33896:16)
	ld	(33040:16), wa
	cps	wa, 0
	jr	le, 2
	dec	1, wa
	call	16291735
	ld	wa, (33040:16)
	exts	xwa
	divs	wa, 10
	ld	de, qwa
	exts	xde
	ld	xwa, (33028:16)
	ld	xbc, 31784962
	jrl	1929
SmfFN_HandleActivate:
	ld	bc, (33040:16)
	exts	xbc
	divs	bc, 10
	muls	bc, 10
	calr	65187
SmfFN_ReturnZero:
	lds32 xhl, 0
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
	jrl	ge, 1506
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
	jrl	1351
SmfFN_PageDown_ClampCheck:
	ld	wa, hl
	exts	xwa
	divs	wa, 10
	cp	de, wa
	jrl	ge, 1334
	exts	xbc
	divs	bc, 10
	ld	wa, qbc
	cps	wa, 0
	jrl	z, 1320
	ld	(33040:16), hl
	jrl	1317
SmfFN_HandleSave:
	cp	xiz, 3
	jrl	nz, 259
	ld	xwa, 6291494
	ld	xbc, 29360129
	lds32	xde, 5
	call	16423243
	lds	wa, 0
	calr	-12374
	ld	a, (34988:16)
	extz	wa
	ld	c, (34986:16)
	extz	bc
	call	16284664
	ld	(xsp+6), hl
	calr	-12304
	.byte 0x9f, 0x06, 0x3f, 0x00, 0x00
	jr	lt, 124
	ld	wa, (33040:16)
	call	16292978
	ld	xbc, xhl
	lda	xwa, (xsp+8)
	ldw	de, 16
	call	16288997
	lda	xwa, (xsp+8)
	ldw	bc, 16
	calr	-588
	cps	l, 0
	jr	z, 20
	ld	wa, (33040:16)
	call	16291811
	ld	xbc, xhl
	lda	xwa, (xsp+8)
	ldw	de, 8
	call	16288997
SmfFN_Save_WriteSlot:
	lda	xwa, (xsp+8)
	ldw	bc, 16
	calr	-799
	lda	xwa, (700416:24)
	lds32	xbc, 0
	ld	c, (34988:16)
	sll	xbc, 11
	add	xwa, xbc
	.byte 0xf3, 0xe1, 0x00, 0x01, 0x30
	lda	xbc, (xsp+8)
	ldw	de, 16
	call	16288997
	ld	a, (65507:24)
	cp	a, (34988:16)
	jr	nz, 20
	lda	xwa, (61824:24)
	.byte 0xf3, 0xe1, 0x00, 0x01, 0x30
	lda	xbc, (xsp+8)
	ldw	de, 16
	call	16288997
SmfFN_Save_Finish:
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 1
	call ApPostEvent
	cpw (0xf19e:16), 0
	jr z, SmfFN_Save_NoAltSlot
	ldw wa, 0xa
	jr SmfFN_Save_CallResult

SmfFN_Save_NoAltSlot:
	lds wa, 1

SmfFN_Save_CallResult:
	call	16355414
	ld	wa, (xsp+6)
	lds	bc, 1
	calr	53600
	ld	(32422:16), l
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 0
	call	16423243
	ldw	wa, 238
	jrl	605
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
	cp (0x0340ea:24), 0x00
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
	lds	wa, 0
	calr	52825
	ld	a, (34988:16)
	extz	wa
	ld	c, (34990:16)
	extz	bc
	ld	e, (34992:16)
	extz	de
	call	16284750
	ld	wa, hl
	lds	bc, 5
	calr	53446
	ld	(32422:16), l
	call	16290139
	call	16290094
	call	16291947
	ld	(33896:16), hl
	calr	52865
	ld	xwa, 6291494
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 1
	call	16423243
	lds	wa, 1
	call	16355414
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 0
	call	16423243
	ldw	wa, 238
	jrl	394
SmfFN_HandleOpen2:
	cp	xiz, 50
	jrl	nz, 133
	ld	xwa, 6291494
	ld	xbc, 29360129
	lds32	xde, 5
	call	16423243
	lds	wa, 0
	calr	52683
	ld	a, (34988:16)
	extz	wa
	ld	c, (34990:16)
	extz	bc
	ld	e, (34992:16)
	extz	de
	call	16284750
	ld	wa, hl
	lds	bc, 5
	calr	53304
	ld	(32422:16), l
	call	16290139
	call	16290094
	call	16291947
	ld	(33896:16), hl
	calr	52723
	ld	xwa, 6291494
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 1
	call	16423243
	lds	wa, 1
	call	16355414
	ld	xwa, 4294967295
	ld	xbc, 31457438
	lds32	xde, 0
	call	16423243
	ldw	wa, 238
	jrl	252
SmfFN_HandleDelete:
	cp xiz, 0x5
	jrl nz, SmfFN_HandleDelete2
	cp (0x0340ea:24), 0x00
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
	ld	xwa, 6291494
	ld	xbc, 29360129
	lds32	xde, 5
	call	16423243
	lds	wa, 0
	calr	-13034
	call	16287509
	ld	wa, hl
	lds	bc, 5
	calr	-12395
	ld	(32422:16), l
	calr	-12960
	call	16290139
	call	16290094
	call	16291947
	ld	(33896:16), hl
	ld	xwa, 6291494
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	ld	wa, (33040:16)
	cp wa, (33896:16)
	jr	lt, 13
	cps	wa, 0
	jr	le, 9
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
	lds32 xde, 5
	call ApPostEvent
	lds wa, 0
	calr InitializeOperationState
	call GetFirstRecordAndOpen
	ld WA,HL
	lds bc, 5
	calr FileIO_ValidateSignedValue
	ld (0x7ea6:16), l
	calr SignalProgressUpdate
	call FileIO_ResetCurrentRecord
	call GetEncodedFreeSpaceData
	call GetFileCountEncoded
	ld (0x8468:16), hl
	ld XWA,0x00600026
	ld XBC,0x01c00002
	lds32 xde, 0
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
	jrl	z, 424
	cp	xiz, 11
	jrl	z, 415
	cp	xiz, 12
	jrl	z, 406
	cp	xiz, 13
	jrl	z, 397
	cp	xiz, 20
	jr	nz, 34
	cp	(33890:16), 0
	jr	nz, 27
	ld	xwa, (xsp+28)
	cp	xwa, 29360151
	jr	nz, 8
	ld	(34982:16), 1
	jrl	363
SmfFN_SetScrollDir0:
	ld	(34982:16), 0
	jrl	355
SmfFN_HandleScrollFlag1:
	cp	xiz, 21
	jr	nz, 51
	ld	c, (34986:16)
	ld	a, c
	inc	1, a
	cps	a, 3
	jr	nc, 18
	inc	1, c
	ld	(34986:16), c
	ld	xwa, (xsp+32)
	ld	xbc, 29360139
	lds32	xde, 0
	jr	15
SmfFN_LoadAs_Wrap:
	ld	(34986:16), 0
	ld	xwa, (xsp+32)
	ld	xbc, 29360139
	lds32	xde, 0
SmfFN_LoadAs_Apply:
	calr SmfLoadAsFunc
	jrl SmfFN_UpdateDisplay

SmfFN_HandleScrollFlag2:
	cp	xiz, 22
	jr	nz, 27
	ld	xwa, (xsp+28)
	cp	xwa, 29360151
	jr	nz, 8
	ld	(34990:16), 1
	jrl	269
SmfFN_SetTrackFlag0:
	ld	(34990:16), 0
	jrl	261
SmfFN_HandleScrollFlag3:
	ld	xwa, (xsp+28)
	cp	xiz, 23
	jr	nz, 24
	cp	xwa, 29360151
	jr	nz, 8
	ld	(34992:16), 1
	jrl	234
SmfFN_SetTransposeFlag0:
	ld	(34992:16), 0
	jrl	226
SmfFN_HandleScrollFlag4:
	cp	xiz, 24
	jr	nz, 24
	cp	xwa, 29360151
	jr	nz, 8
	ld	(34984:16), 1
	jrl	202
SmfFN_SetFlag35140_0:
	ld	(34984:16), 0
	jrl	194
SmfFN_HandleSeqSongNum:
	ld	c, (34988:16)
	ld	a, c
	inc	1, a
	cp	xiz, 30
	jr	nz, 66
	cp	a, 10
	jr	nc, 31
	inc	1, c
	ld	(34988:16), c
	ld	xwa, (xsp+32)
	ld	xbc, 29360139
	lds32	xde, 0
	calr	63415
	ld	xwa, (xsp+32)
	ld	xbc, 29360139
	lds32	xde, 0
	jr	102
SmfFN_SeqToSong_Wrap:
	ld	(34988:16), 0
	ld	xwa, (xsp+32)
	ld	xbc, 29360139
	lds32	xde, 0
	calr	63385
	ld	xwa, (xsp+32)
	ld	xbc, 29360139
	lds32	xde, 0
	jr	72
SmfFN_HandleSeqFromSong:
	cp	xiz, 31
	jr	nz, 69
	cp	a, 10
	jr	nc, 31
	inc	1, c
	ld	(34988:16), c
	ld	xwa, (xsp+32)
	ld	xbc, 29360139
	lds32	xde, 0
	calr	63428
	ld	xwa, (xsp+32)
	ld	xbc, 29360139
	lds32	xde, 0
	jr	28
SmfFN_SeqFromSong_Wrap:
	ld	(34988:16), 0
	ld	xwa, (xsp+32)
	ld	xbc, 29360139
	lds32	xde, 0
	calr	63398
	ld	xwa, (xsp+32)
	ld	xbc, 29360139
	lds32	xde, 0
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
	jrl	z, 244
	ld	wa, hl
	call	16291735
	ld	wa, (33040:16)
	exts	xwa
	divs	wa, 10
	ld	de, qwa
	exts	xde
	ld	xwa, (33028:16)
	ld	xbc, 31784962
	call	16423243
	ld	bc, (33040:16)
	exts	xbc
	divs	bc, 10
	ld	de, (xsp+4)
	exts	xde
	divs	de, 10
	ld	xwa, (33028:16)
	cp	de, bc
	jr	nz, 75
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
	call	16423243
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
	call	16423243
	jr	27
SmfFN_RedrawPage:
	muls	bc, 10
	calr	-2084
	cp	(35994:16), 108
	jr	nz, 13
	ld	xwa, (xsp+32)
	ld	xbc, 29360139
	lds32	xde, 0
	calr	17837
SmfFN_UpdateFilenameField:
	cp	(35994:16), 107
	jr	nz, 74
	lda	xiz, (34740:16)
	ld	wa, (33040:16)
	cp wa, (33896:16)
	jr	lt, 17
	cps	wa, 0
	jr	le, 13
	ld	xwa, xiz
	ld	xbc, 15337360
	call	16288975
	jr	21
SmfFN_FetchFilename:
	call	16291811
	ld	xbc, xhl
	ld	xwa, xiz
	call	16288975
	ld	xwa, 34740
	call	16289424
SmfFN_WriteFilenameField:
	ld	xwa, 34740
	call	16289486
	ld	xwa, (xsp+32)
	ld	xbc, 29360139
	lds32	xde, 0
	calr	62818
SmfFN_SendOkState:
	ld xwa, (0x8104:16)
	ld XBC,0x01c50001
	lds32 xde, 0
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
	call	16423243
	jrl	-1919
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
	lds wa, 0
	calr InitializeOperationState
	lds iz, 0

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
	call	16297264
	ld	xbc, xhl
	ld	wa, iz
	sll	wa, 5
	lds	de, 1
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
	call	16289232
	ld	de, iz
	sll	de, 5
	lda	xbc, (33904:16)
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
