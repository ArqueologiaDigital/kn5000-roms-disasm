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
	jrl z, LABEL_F8DCE2
	cp xbc, 0x1C00013
	jrl nz, LABEL_F8DCFD
	cp xde, 0x3
	jrl z, LABEL_F8DCDD
	cp xde, 0x2
	jrl nz, LABEL_F8DCFD
	stdi8 34046, 0
	lds wa, 1
	calr InitializeOperationState
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	ldmm8 32906, 36151
	cpdi16 34048, 0
	jr ge, LABEL_F8DBA6
	call 0xF89520
	extz hl
	stda16 34048, xhl
	calr SignalProgressUpdate

LABEL_F8DBA6:
	ldda16 xwa, 34048
	cps wa, 1
	jrl z, LABEL_F8DC70
	cps wa, 0
	jrl z, LABEL_F8DC5A
	cps wa, 5
	jr z, LABEL_F8DC16
	cpdi16 34052, 0
	jr ge, LABEL_F8DBD3
	call 0xF89C78
	stda16 34052, xhl
	call LABEL_F8958D
	call 0xF8953B
	calr SignalProgressUpdate

LABEL_F8DBD3:
	cpdi16 34052, 0
	jrl nz, LABEL_F8DCBB
	cpdi16 34050, 0
	jr ge, LABEL_F8DBEF
	call 0xF8987D
	stda16 34050, xhl
	calr SignalProgressUpdate

LABEL_F8DBEF:
	cpdi16 34050, 0
	jrl le, LABEL_F8DCBB
	cpdi8 32906, 97
	jrl z, LABEL_F8DCBB
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0x61
	jrl LABEL_F8DCF9

LABEL_F8DC16:
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
	jr LABEL_F8DCB5

LABEL_F8DC5A:
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0x7D
	jrl LABEL_F8DCF9

LABEL_F8DC70:
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

LABEL_F8DCB5:
	call LABEL_F994BD
	jr LABEL_F8DCFD

LABEL_F8DCBB:
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	call 0xFA9D58
	jr LABEL_F8DCFD

LABEL_F8DCDD:
	calr CancelOperationCleanup
	jr LABEL_F8DCFD

LABEL_F8DCE2:
	cp xde, 0xF
	jr nz, LABEL_F8DCFD
	cpdi8 36148, 7
	jr nz, LABEL_F8DCF6
	ldw wa, 0xD6
	jr LABEL_F8DCF9

LABEL_F8DCF6:
	ldw wa, 0x60

LABEL_F8DCF9:
	call 0xF99490

LABEL_F8DCFD:
	lds32 xhl, 0
	ret

FmmSmfSaveTitleFunc:
	cp xbc, 0x1C00013
	jr nz, LABEL_F8DD72
	cp xde, 0x3
	jr z, LABEL_F8DD6F
	cp xde, 0x2
	jr nz, LABEL_F8DD72
	stdi8 34046, 0
	lds wa, 1
	calr InitializeOperationState
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	cpdi16 34052, 0
	jr ge, LABEL_F8DD4D
	call 0xF89C78
	stda16 34052, xhl
	call LABEL_F8958D
	call 0xF8953B
	calr SignalProgressUpdate

LABEL_F8DD4D:
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	call 0xFA9D58
	jr LABEL_F8DD72

LABEL_F8DD6F:
	calr CancelOperationCleanup

LABEL_F8DD72:
	lds32 xhl, 0
	ret

RenderSmfFilename:
	extz bc
	stib_dri 0x07, 0xE0, 0xE4, 0x00
	lds ix, 0
	ldada_24 xhl, 15652728
	jr LABEL_F8DD97

LABEL_F8DD86:
	extz bc
	ld_srib3 C, 0x07, 0xEC, 0xE4
	and c, 0x7
	jr nz, LABEL_F8DD95
	ldmi8 (xde), 0x5F

LABEL_F8DD95:
	inc 1, ix

LABEL_F8DD97:
	cp ix, 0x8
	jr ge, LABEL_F8DDA8
	st_dri3b B, 0x07, 0xE0, 0xF0
	ld c, (xde)
	cps c, 0
	jr nz, LABEL_F8DD86

LABEL_F8DDA8:
	cp ix, 0x8
	ret ge

LABEL_F8DDAE:
	stib_dri 0x07, 0xE0, 0xF0, 0x5F
	inc 1, ix
	cp ix, 0x8
	jr lt, LABEL_F8DDAE
	ret

SaveFileNameSmfFunc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ldada xwa, 34896
	cp xbc, 0x1E00086
	jr z, LABEL_F8DE48
	cp xbc, 0x1E0003A
	jr z, LABEL_F8DE1C
	cp xbc, 0x1C0000B
	jr z, LABEL_F8DDF2
	cp xbc, 0x1E50004
	jrl nz, LABEL_F8DE74
	ld xwa, (xsp + 4)
	stda32 32908, xwa
	jrl LABEL_F8DE74

LABEL_F8DDF2:
	ldmi8 (xwa), 0x0
	lda xiz, (xwa + 1)
	call LABEL_F892D5
	ld xbc, xhl
	ld xwa, xiz
	call LABEL_F890DC
	ldada xwa, 34897
	call LABEL_F8929D
	ldda32 xwa, 32908
	ld xbc, 0x1C0000F
	ld xde, 0x8850
	jr LABEL_F8DE42

LABEL_F8DE1C:
	ld xiz, xwa
	call LABEL_F892D5
	ld xbc, xhl
	ld xwa, xiz
	call LABEL_F890DC
	ld xwa, 0x8850
	ldw bc, 0x8
	calr RenderSmfFilename
	ld xwa, (xsp + 4)
	ld xbc, 0x1E00086
	ld xde, 0x8850

LABEL_F8DE42:
	call 0xFA9D58
	jr LABEL_F8DE74

LABEL_F8DE48:
	ld xbc, (xsp + 4)
	ldw de, 0x8
	call LABEL_F890F2
	ld xwa, 0x8850
	ldw bc, 0x8
	calr RenderSmfFilename
	ld xwa, 0x8850
	ld xbc, 0xEA0736
	call LABEL_F89113
	ld xwa, 0x8850
	call LABEL_F892DB

LABEL_F8DE74:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret

SmfSeqToSongNumFunc:
	push xiz
	cp xbc, 0x1C0000B
	jr z, LABEL_F8DE91
	cp xbc, 0x1E50004
	jr nz, LABEL_F8DECD
	stda32 32912, xde
	jr LABEL_F8DECD

LABEL_F8DE91:
	ldada xwa, 32916
	stib_dpi 0xE0, 0x00
	ld xbc, 0xEA073C
	call LABEL_F890DC
	ldada xiz, 32917
	ldda8 a, 35144
	inc 1, a
	extz wa
	lds bc, 2
	calr LABEL_F8B67F
	ld xbc, xhl
	ld xwa, xiz
	call LABEL_F89113
	ldda32 xwa, 32912
	ld xbc, 0x1C0000F
	ld xde, 0x8094
	call 0xFA9D58

LABEL_F8DECD:
	lds32 xhl, 0
	pop xiz
	ret

SmfSeqFromSongNumFunc:
	push xiz
	cp xbc, 0x1C0000B
	jr z, LABEL_F8DEE8
	cp xbc, 0x1E50004
	jr nz, LABEL_F8DF24
	stda32 33044, xde
	jr LABEL_F8DF24

LABEL_F8DEE8:
	ldada xwa, 33048
	stib_dpi 0xE0, 0x00
	ld xbc, 0xEA0748
	call LABEL_F890DC
	ldada xiz, 33049
	ldda8 a, 35144
	inc 1, a
	extz wa
	lds bc, 2
	calr LABEL_F8B67F
	ld xbc, xhl
	ld xwa, xiz
	call LABEL_F89113
	ldda32 xwa, 33044
	ld xbc, 0x1C0000F
	ld xde, 0x8118
	call 0xFA9D58

LABEL_F8DF24:
	lds32 xhl, 0
	pop xiz
	ret

SmfSeqSongNameFunc:
	cp xbc, 0x1C0000B
	jr z, LABEL_F8DF3E
	cp xbc, 0x1E50004
	jr nz, LABEL_F8DF5A
	stda32 33176, xde
	jr LABEL_F8DF5A

LABEL_F8DF3E:
	ldda8 a, 35144
	extz wa
	lds bc, 0
	lds de, 0
	calr LABEL_F919E3
	ld xde, xhl
	ldda32 xwa, 33176
	ld xbc, 0x1C0000F
	call 0xFA9D58

LABEL_F8DF5A:
	lds32 xhl, 0
	ret

SmfLoadAsFunc:
	cp xbc, 0x1C0000B
	jr z, LABEL_F8DF73
	cp xbc, 0x1E50004
	jr nz, LABEL_F8DF93
	stda32 33180, xde
	jr LABEL_F8DF93

LABEL_F8DF73:
	ldda8 a, 35142
	extz wa
	sla wa, 2
	ldada_24 xbc, 15337300
	ld_sril3 XDE, 0x07, 0xE4, 0xE0
	ldda32 xwa, 33180
	ld xbc, 0x1C0000F
	call 0xFA9D58

LABEL_F8DF93:
	lds32 xhl, 0
	ret

TrimAndPadSmfFilename:
	lds ix, 0
	ld xhl, xwa
	jr LABEL_F8DFB6

LABEL_F8DF9C:
	cp e, 0x7E
	jr nz, LABEL_F8DFA5
	ldb e, 0x5F
	jr LABEL_F8DFAE

LABEL_F8DFA5:
	ld e, (xwa)
	cp e, 0x20
	jr nc, LABEL_F8DFB0
	ldb e, 0x20

LABEL_F8DFAE:
	ld (xwa), e

LABEL_F8DFB0:
	inc 1, ix
	inc 1, xwa
	inc 1, xhl

LABEL_F8DFB6:
	cp ix, bc
	jr nc, LABEL_F8DFC0
	ld e, (xhl)
	cps e, 0
	jr nz, LABEL_F8DF9C

LABEL_F8DFC0:
	cp ix, bc
	jr nc, LABEL_F8DFCE

LABEL_F8DFC4:
	stib_dpi 0xE0, 0x20
	inc 1, ix
	cp ix, bc
	jr c, LABEL_F8DFC4

LABEL_F8DFCE:
	ldmi8 (xwa), 0x0
	ret

DisplaySmfFileList:
	dec 6, xsp
	pushw iz
	ld (xsp + 2), bc
	ld (xsp + 4), xwa
	lds wa, 0
	calr InitializeOperationState
	lds iz, 0

LABEL_F8DFE2:
	ld de, iz
	sll de, 5
	ldada xbc, 34060
	extz xde
	add xde, xbc
	ldto_berp A, 0xF8
	ld (xde), a
	ld wa, (xsp + 2)
	add wa, iz
	call LABEL_F89BF0
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
	jr lt, LABEL_F8DFE2
	popw iz
	inc 6, xsp
	ret

ValidateSmfFilename:
	lds iy, 0
	lds hl, 0
	jr LABEL_F8E05A

LABEL_F8E04E:
	cp e, 0x20
	jr z, LABEL_F8E056
	ldb l, 0x0
	ret

LABEL_F8E056:
	inc 1, iy
	inc 1, hl

LABEL_F8E05A:
	ld_srib3 E, 0x07, 0xE0, 0xF4
	cps e, 0
	jr z, LABEL_F8E067
	cp hl, bc
	jr c, LABEL_F8E04E

LABEL_F8E067:
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
	jrl z, LABEL_F8E134
	cp xbc, 0x1C00017
	jrl z, LABEL_F8E134
	cp xbc, 0x1C0000B
	jrl z, LABEL_F8E11E
	ld xbc, xiz
	sub xde, 0x1E50002
	cp xde, 0x0
	jrl lt, LABEL_F8E12F
	cp xde, 0x5
	jr gt, LABEL_F8E12F
	add xde, xde
	add xde, 0xEA079E
	ld de, (xde)
	ldada_24 xix, 16310472
	jp_dri 8, 0x07, 0xF0, 0xE8
LABEL_F8E0C8:
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

LABEL_F8E11E:
	ldda16 xbc, 33196
	exts xbc
	divs bc, 0xA
	muls bc, 0xA
	calr DisplaySmfFileList

LABEL_F8E12F:
	lds32 xhl, 0
	jrl LABEL_F8E8B4

LABEL_F8E134:
	ld xbc, 0x1C50001
	lds32 xde, 1
	call 0xFA9D58
	ldda16 xix, 33196
	ld (xsp + 4), ix
	or xiz, xiz
	jr nz, LABEL_F8E192
	cpdi8 34046, 0
	jr nz, LABEL_F8E192
	ld xwa, (xsp + 28)
	cp xwa, 0x1C00018
	jr nz, LABEL_F8E180
	ld bc, ix
	inc 1, bc
	cpdi8 36150, 107
	jr z, LABEL_F8E170
	cpda16 xbc, 34052
	jr lt, LABEL_F8E17B
	jrl LABEL_F8E75D

LABEL_F8E170:
	ldda16 xwa, 34052
	inc 1, wa
	cp bc, wa
	jrl ge, LABEL_F8E75D

LABEL_F8E17B:
	inc 1, ix
	jrl LABEL_F8E211

LABEL_F8E180:
	cp xwa, 0x1C00017
	jrl nz, LABEL_F8E75D
	cps ix, 0
	jrl le, LABEL_F8E75D
	dec 1, ix
	jr LABEL_F8E211

LABEL_F8E192:
	cp xiz, 0x1
	jr nz, LABEL_F8E1AE
	cpdi8 34046, 0
	jr nz, LABEL_F8E1AE
	cp ix, 0xA
	jrl lt, LABEL_F8E75D
	sub ix, 0xA
	jr LABEL_F8E211

LABEL_F8E1AE:
	cp xiz, 0x2
	jrl nz, LABEL_F8E23C
	cpdi8 34046, 0
	jr nz, LABEL_F8E23C
	ld iy, ix
	add iy, 0xA
	ldda16 xbc, 34052
	ld de, ix
	exts xde
	divs de, 0xA
	cpdi8 36150, 107
	jr z, LABEL_F8E205
	ld hl, bc
	cp iy, bc
	jr lt, LABEL_F8E20D
	ld bc, hl
	dec 1, bc
	ld wa, bc
	exts xwa
	divs wa, 0xA
	cp de, wa
	jrl ge, LABEL_F8E75D
	exts xhl
	divs hl, 0xA
	ldto_werp WA, 0xEE
	cps wa, 0
	jrl z, LABEL_F8E75D
	stda16 33196, xbc
	ld hl, bc
	jrl LABEL_F8E761

LABEL_F8E205:
	ld hl, bc
	inc 1, bc
	cp iy, bc
	jr ge, LABEL_F8E21A

LABEL_F8E20D:
	add ix, 0xA

LABEL_F8E211:
	stda16 33196, xix
	ld hl, ix
	jrl LABEL_F8E761

LABEL_F8E21A:
	ld wa, hl
	exts xwa
	divs wa, 0xA
	cp de, wa
	jrl ge, LABEL_F8E75D
	exts xbc
	divs bc, 0xA
	ldto_werp WA, 0xE6
	cps wa, 0
	jrl z, LABEL_F8E75D
	stda16 33196, xhl
	jrl LABEL_F8E761

LABEL_F8E23C:
	cp xiz, 0x3
	jrl nz, LABEL_F8E348
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
	cpmi16 (xsp + 6), 0x0
	jr lt, LABEL_F8E2F3
	ldda16 xwa, 33196
	call LABEL_F8A07F
	ld xbc, xhl
	lda xwa, (xsp + 8)
	ldw de, 0x10
	call LABEL_F890F2
	lda xwa, (xsp + 8)
	ldw bc, 0x10
	calr ValidateSmfFilename
	cps l, 0
	jr z, LABEL_F8E2AC
	ldda16 xwa, 33196
	call LABEL_F89BF0
	ld xbc, xhl
	lda xwa, (xsp + 8)
	ldw de, 0x8
	call LABEL_F890F2

LABEL_F8E2AC:
	lda xwa, (xsp + 8)
	ldw bc, 0x10
	calr TrimAndPadSmfFilename
	ldada_24 xwa, 700416
	lds32 xbc, 0
	ldda8 c, 35144
	sll xbc, 11
	add xwa, xbc
	st_dri3b W, 0xE1, 0x00, 0x01
	lda xbc, (xsp + 8)
	ldw de, 0x10
	call LABEL_F890F2
	ldda8_24 a, 65507
	cpda8 a, 35144
	jr nz, LABEL_F8E2F3
	ldada_24 xwa, 61824
	st_dri3b W, 0xE1, 0x00, 0x01
	lda xbc, (xsp + 8)
	ldw de, 0x10
	call LABEL_F890F2

LABEL_F8E2F3:
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call 0xFA9D58
	cpdi16 61854, 0
	jr z, LABEL_F8E320
	ldw wa, 0xA
	jr LABEL_F8E322

LABEL_F8E320:
	lds wa, 1

LABEL_F8E322:
	call LABEL_F99463
	ld wa, (xsp + 6)
	lds bc, 1
	calr LABEL_F8B48E
	stda8 32578, l
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0xEE
	jrl LABEL_F8E5A5

LABEL_F8E348:
	cp xiz, 0x4
	jrl nz, LABEL_F8E41B
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	call LABEL_F892D5
	ld xwa, xhl
	call LABEL_F8947D
	cps l, 0
	jr z, LABEL_F8E3A6
	cpdi8_24 213226, 0
	jr z, LABEL_F8E3A6
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
	jrl LABEL_F8E759

LABEL_F8E3A6:
	lds wa, 0
	calr InitializeOperationState
	ldda8 a, 35144
	extz wa
	ldda8 c, 35146
	extz bc
	ldda8 e, 35148
	extz de
	call LABEL_F8805B
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
	call LABEL_F99463
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0xEE
	jrl LABEL_F8E5A5

LABEL_F8E41B:
	cp xiz, 0x32
	jrl nz, LABEL_F8E4A9
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
	call LABEL_F8805B
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
	call LABEL_F99463
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0xEE
	jrl LABEL_F8E5A5

LABEL_F8E4A9:
	cp xiz, 0x5
	jrl nz, LABEL_F8E53C
	cpdi8_24 213226, 0
	jr z, LABEL_F8E4D9
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C50000
	lds32 xde, 1
	call 0xFA9D58
	ld xwa, 0x7B0051
	ld xbc, 0x1C00001
	lds32 xde, 0
	jrl LABEL_F8E759

LABEL_F8E4D9:
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	lds wa, 0
	calr InitializeOperationState
	call LABEL_F88B22
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
	jr lt, LABEL_F8E537
	cps wa, 0
	jr le, LABEL_F8E537
	dec 1, wa
	stda16 33196, xwa
	ld (xsp + 4), wa

LABEL_F8E537:
	ldw wa, 0xEE
	jr LABEL_F8E5A5

LABEL_F8E53C:
	cp xiz, 0x33
	jr nz, LABEL_F8E5AC
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	lds wa, 0
	calr InitializeOperationState
	call LABEL_F88B22
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
	jr lt, LABEL_F8E5A2
	cps wa, 0
	jr le, LABEL_F8E5A2
	dec 1, wa
	stda16 33196, xwa
	ld (xsp + 4), wa

LABEL_F8E5A2:
	ldw wa, 0xEE

LABEL_F8E5A5:
	call LABEL_F994BD
	jrl LABEL_F8E75D

LABEL_F8E5AC:
	cp xiz, 0xA
	jrl z, LABEL_F8E75D
	cp xiz, 0xB
	jrl z, LABEL_F8E75D
	cp xiz, 0xC
	jrl z, LABEL_F8E75D
	cp xiz, 0xD
	jrl z, LABEL_F8E75D
	cp xiz, 0x14
	jr nz, LABEL_F8E5FA
	cpdi8 34046, 0
	jr nz, LABEL_F8E5FA
	ld xwa, (xsp + 28)
	cp xwa, 0x1C00017
	jr nz, LABEL_F8E5F2
	stdi8 35138, 1
	jrl LABEL_F8E75D

LABEL_F8E5F2:
	stdi8 35138, 0
	jrl LABEL_F8E75D

LABEL_F8E5FA:
	cp xiz, 0x15
	jr nz, LABEL_F8E635
	ldda8 c, 35142
	ld a, c
	inc 1, a
	cps a, 3
	jr nc, LABEL_F8E620
	inc 1, c
	stda8 35142, c
	ld xwa, (xsp + 32)
	ld xbc, 0x1C0000B
	lds32 xde, 0
	jr LABEL_F8E62F

LABEL_F8E620:
	stdi8 35142, 0
	ld xwa, (xsp + 32)
	ld xbc, 0x1C0000B
	lds32 xde, 0

LABEL_F8E62F:
	calr SmfLoadAsFunc
	jrl LABEL_F8E75D

LABEL_F8E635:
	cp xiz, 0x16
	jr nz, LABEL_F8E658
	ld xwa, (xsp + 28)
	cp xwa, 0x1C00017
	jr nz, LABEL_F8E650
	stdi8 35146, 1
	jrl LABEL_F8E75D

LABEL_F8E650:
	stdi8 35146, 0
	jrl LABEL_F8E75D

LABEL_F8E658:
	ld xwa, (xsp + 28)
	cp xiz, 0x17
	jr nz, LABEL_F8E67B
	cp xwa, 0x1C00017
	jr nz, LABEL_F8E673
	stdi8 35148, 1
	jrl LABEL_F8E75D

LABEL_F8E673:
	stdi8 35148, 0
	jrl LABEL_F8E75D

LABEL_F8E67B:
	cp xiz, 0x18
	jr nz, LABEL_F8E69B
	cp xwa, 0x1C00017
	jr nz, LABEL_F8E693
	stdi8 35140, 1
	jrl LABEL_F8E75D

LABEL_F8E693:
	stdi8 35140, 0
	jrl LABEL_F8E75D

LABEL_F8E69B:
	ldda8 c, 35144
	ld a, c
	inc 1, a
	cp xiz, 0x1E
	jr nz, LABEL_F8E6ED
	cp a, 0xA
	jr nc, LABEL_F8E6CF
	inc 1, c
	stda8 35144, c
	ld xwa, (xsp + 32)
	ld xbc, 0x1C0000B
	lds32 xde, 0
	calr SmfSeqToSongNumFunc
	ld xwa, (xsp + 32)
	ld xbc, 0x1C0000B
	lds32 xde, 0
	jr LABEL_F8E735

LABEL_F8E6CF:
	stdi8 35144, 0
	ld xwa, (xsp + 32)
	ld xbc, 0x1C0000B
	lds32 xde, 0
	calr SmfSeqToSongNumFunc
	ld xwa, (xsp + 32)
	ld xbc, 0x1C0000B
	lds32 xde, 0
	jr LABEL_F8E735

LABEL_F8E6ED:
	cp xiz, 0x1F
	jr nz, LABEL_F8E73A
	cp a, 0xA
	jr nc, LABEL_F8E719
	inc 1, c
	stda8 35144, c
	ld xwa, (xsp + 32)
	ld xbc, 0x1C0000B
	lds32 xde, 0
	calr SmfSeqFromSongNumFunc
	ld xwa, (xsp + 32)
	ld xbc, 0x1C0000B
	lds32 xde, 0
	jr LABEL_F8E735

LABEL_F8E719:
	stdi8 35144, 0
	ld xwa, (xsp + 32)
	ld xbc, 0x1C0000B
	lds32 xde, 0
	calr SmfSeqFromSongNumFunc
	ld xwa, (xsp + 32)
	ld xbc, 0x1C0000B
	lds32 xde, 0

LABEL_F8E735:
	calr SmfSeqSongNameFunc
	jr LABEL_F8E75D

LABEL_F8E73A:
	cp xiz, 0x28
	jr nz, LABEL_F8E75D
	cpdi16 33198, 0
	jr z, LABEL_F8E75D
	ldda32 xwa, 33188
	or xwa, xwa
	jr z, LABEL_F8E75D
	ld xbc, 0x1C0000A
	lds32 xde, 0

LABEL_F8E759:
	call 0xFA9D58

LABEL_F8E75D:
	ldda16 xhl, 33196

LABEL_F8E761:
	cp (xsp + 4), hl
	jrl z, LABEL_F8E85B
	ld wa, hl
	call LABEL_F89BA4
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
	jr nz, LABEL_F8E7EF
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
	jr LABEL_F8E80A

LABEL_F8E7EF:
	muls bc, 0xA
	calr DisplaySmfFileList
	cpdi8 36150, 108
	jr nz, LABEL_F8E80A
	ld xwa, (xsp + 32)
	ld xbc, 0x1C0000B
	lds32 xde, 0
	calr FmmSmfMedleyFunc

LABEL_F8E80A:
	cpdi8 36150, 107
	jr nz, LABEL_F8E85B
	ldada xiz, 34896
	ldda16 xwa, 33196
	cpda16 xwa, 34052
	jr lt, LABEL_F8E830
	cps wa, 0
	jr le, LABEL_F8E830
	ld xwa, xiz
	ld xbc, 0xEA0790
	call LABEL_F890DC
	jr LABEL_F8E845

LABEL_F8E830:
	call LABEL_F89BF0
	ld xbc, xhl
	ld xwa, xiz
	call LABEL_F890DC
	ld xwa, 0x8850
	call LABEL_F8929D

LABEL_F8E845:
	ld xwa, 0x8850
	call LABEL_F892DB
	ld xwa, (xsp + 32)
	ld xbc, 0x1C0000B
	lds32 xde, 0
	calr SaveFileNameSmfFunc

LABEL_F8E85B:
	ldda32 xwa, 33184
	ld xbc, 0x1C50001
	lds32 xde, 0
	jr LABEL_F8E8A7
	stda32 33188, xbc
	jrl LABEL_F8E12F
	stda32 33192, xbc
	jrl LABEL_F8E12F
	stda16 33198, xiz
	jrl LABEL_F8E12F
	cpdi8 34046, 0
	jrl z, LABEL_F8E12F
	ld wa, iz
	stda16 33196, xwa
	call LABEL_F89BA4
	ldda16 xwa, 33196
	exts xwa
	divs wa, 0xA
	ldto_werp DE, 0xE2
	exts xde
	ldda32 xwa, 33184
	ld xbc, 0x1E50002

LABEL_F8E8A7:
	call 0xFA9D58
	jrl LABEL_F8E12F
	ldda16 xhl, 33196
	exts xhl

LABEL_F8E8B4:
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

LABEL_F8E8C9:
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
	jr lt, LABEL_F8E8C9
	popw iz
	inc 6, xsp
	ret

