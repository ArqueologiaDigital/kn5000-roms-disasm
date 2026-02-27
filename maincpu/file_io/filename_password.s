; =============================================================================
; file_io/filename_password.asm - Filename and Password UI
; =============================================================================
; Password entry and filename input routines.
;
; Key routines:
;   FmmPasswordFunc                  - Password entry dialog
;   FmmFileNameFunc                  - Filename input/display
; =============================================================================

FmmPasswordFunc:
	dec 4, xsp
	push xiz
	ld xiz, xde
	ld (xsp + 4), xwa
	ld wa, iz
	cp xbc, 0x1E50010
	jrl z, LABEL_F8CA7F
	ldada xde, 35340
	cp xbc, 0x1E5000F
	jrl z, LABEL_F8C9FC
	cp xbc, 0x1E5000E
	jr z, LABEL_F8C980
	cp xbc, 0x1E5000D
	jrl nz, LABEL_F8CAA6
	call CheckAnySlotHasData
	cps l, 0
	jr nz, LABEL_F8C95A
	call CheckSlotIndexValid
	cps l, 0
	jr z, LABEL_F8C969

LABEL_F8C95A:
	stdi8 32578, 10
	ldw wa, 0xEE
	call LABEL_F994BD
	jrl LABEL_F8CAA6

LABEL_F8C969:
	ld wa, iz
	call ClearAllSongSlots
	ld wa, iz
	call SetCurrentSlotIndex
	ldada xwa, 35341
	setm 7, (xwa)
	setm 6, (xwa)
	jrl LABEL_F8CAA6

LABEL_F8C980:
	cpmi8 (xde), 0x3
	jr nz, LABEL_F8C9AB
	call CheckSlotIsSelected
	cps l, 0
	jr z, LABEL_F8C9AB
	ld wa, iz
	call CheckIsCurrentSlot
	cps l, 0
	jr z, LABEL_F8C9AB
	ldada xwa, 35341
	setm 7, (xwa)
	setm 6, (xwa)
	ld xwa, (xsp + 4)
	ld xbc, 0x1C00017
	lds32 xde, 4
	jr LABEL_F8C9EB

LABEL_F8C9AB:
	cpdi8 35340, 1
	jr nz, LABEL_F8C9CC
	ld wa, iz
	call CheckSlotIsSelected
	cps l, 0
	jr z, LABEL_F8C9CC
	setda 7, 35341
	ld xwa, (xsp + 4)
	ld xbc, 0x1C00017
	lds32 xde, 4
	jr LABEL_F8C9EB

LABEL_F8C9CC:
	cpdi8 35340, 2
	jr nz, LABEL_F8C9F1
	ld wa, iz
	call CheckIsCurrentSlot
	cps l, 0
	jr z, LABEL_F8C9F1
	setda 6, 35341
	ld xwa, (xsp + 4)
	ld xbc, 0x1C00017
	lds32 xde, 4

LABEL_F8C9EB:
	calr FmmFileNameFunc
	jrl LABEL_F8CAA6

LABEL_F8C9F1:
	stdi8 32578, 11
	ldw wa, 0xEE
	jrl LABEL_F8CAA2

LABEL_F8C9FC:
	cpmi8 (xde), 0x3
	jr nz, LABEL_F8CA2A
	call CheckSlotIsSelected
	cps l, 0
	jr z, LABEL_F8CA2A
	ld wa, iz
	call CheckIsCurrentSlot
	cps l, 0
	jr z, LABEL_F8CA2A
	ldada xwa, 35341
	setm 7, (xwa)
	setm 6, (xwa)
	ld xwa, (xsp + 4)
	ld xbc, 0x1C00017
	ld xde, 0xA
	jr LABEL_F8CA70

LABEL_F8CA2A:
	cpdi8 35340, 1
	jr nz, LABEL_F8CA4E
	ld wa, iz
	call CheckSlotIsSelected
	cps l, 0
	jr z, LABEL_F8CA4E
	setda 7, 35341
	ld xwa, (xsp + 4)
	ld xbc, 0x1C00017
	ld xde, 0xA
	jr LABEL_F8CA70

LABEL_F8CA4E:
	cpdi8 35340, 2
	jr nz, LABEL_F8CA75
	ld wa, iz
	call CheckIsCurrentSlot
	cps l, 0
	jr z, LABEL_F8CA75
	setda 6, 35341
	ld xwa, (xsp + 4)
	ld xbc, 0x1C00017
	ld xde, 0xA

LABEL_F8CA70:
	calr FmmSaveFilterFunc
	jr LABEL_F8CAA6

LABEL_F8CA75:
	stdi8 32578, 11
	ldw wa, 0xEE
	jr LABEL_F8CAA2

LABEL_F8CA7F:
	call CheckSlotIsSelected
	cps l, 0
	jr z, LABEL_F8CA9A
	setda 7, 35341
	ld xwa, (xsp + 4)
	ld xbc, 0x1C00017
	lds32 xde, 4
	calr FmmSeqSongNameFunc
	jr LABEL_F8CAA6

LABEL_F8CA9A:
	stdi8 32578, 11
	ldw wa, 0xEE

LABEL_F8CAA2:
	call LABEL_F994BD

LABEL_F8CAA6:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret

SelectPasswordMode:
	push xiz
	ldi_berp 0xFB, 0
	ldi_berp 0xFA, 0
	lds wa, 2
	call LABEL_F89353
	cps l, 0
	jr z, LABEL_F8CACE
	call CheckAnySlotHasData
	cps l, 0
	jr z, LABEL_F8CACE
	bitda 7, 35341
	jr nz, LABEL_F8CACE
	ldi_berp 0xFA, 1

LABEL_F8CACE:
	lds wa, 3
	call LABEL_F89353
	cps l, 0
	jr z, LABEL_F8CAE9
	call CheckSlotIndexValid
	cps l, 0
	jr z, LABEL_F8CAE9
	bitda 6, 35341
	jr nz, LABEL_F8CAE9
	ldi_berp 0xFB, 1

LABEL_F8CAE9:
	cpi_berp 0xFA, 0
	jr z, LABEL_F8CB0B
	cpi_berp 0xFB, 0
	jr z, LABEL_F8CB0B
	call GetCurrentSlotIndex
	ld iz, hl
	call FindFirstEmptySlot
	ldb a, 0x1
	cp hl, iz
	jr nz, LABEL_F8CB05
	ldb a, 0x3

LABEL_F8CB05:
	stda8 35340, a
	jr LABEL_F8CB24

LABEL_F8CB0B:
	ldada xbc, 35340
	cpi_berp 0xFA, 0
	jr z, LABEL_F8CB19
	ldmi8 (xbc), 0x1
	jr LABEL_F8CB24

LABEL_F8CB19:
	ldb a, 0x0
	cpi_berp 0xFB, 0
	jr z, LABEL_F8CB22
	ldb a, 0x2

LABEL_F8CB22:
	ld (xbc), a

LABEL_F8CB24:
	ldda8 l, 35340
	extz hl
	pop xiz
	ret

FmmFileNameFunc:
	dec 8, xsp
	push xiz
	ld xiz, xde
	ld (xsp + 8), xbc
	ld xbc, xiz
	ld xwa, (xsp + 8)
	cp xwa, 0x1E50000
	jrl z, LABEL_F8D106
	cp xwa, 0x1C00018
	jrl z, LABEL_F8CC0C
	cp xwa, 0x1C00017
	jrl z, LABEL_F8CC0C
	cp xwa, 0x1C0000B
	jr z, LABEL_F8CBA2
	cp xwa, 0x1E50004
	jrl nz, LABEL_F8D16D
	stda32 32626, xbc
	call 0xF895EF
	stda16 32634, xhl
	cps hl, 0
	jr lt, LABEL_F8CB84
	exts xhl
	ldda32 xwa, 32626
	ld xbc, 0x1E50002
	ld xde, xhl
	jr LABEL_F8CB95

LABEL_F8CB84:
	stdi16 32634, 0
	ldda32 xwa, 32626
	ld xbc, 0x1E50002
	lds32 xde, 0

LABEL_F8CB95:
	call 0xFA9D58
	lds32 xwa, 0
	stda32 32630, xwa
	jrl LABEL_F8D16D

LABEL_F8CBA2:
	ldmw (xsp + 6), 0x0

LABEL_F8CBA7:
	ld wa, (xsp + 6)
	ld hl, wa
	sll hl, 5
	ldada xde, 34060
	extz xhl
	add xhl, xde
	ld bc, (xsp + 6)
	ld (xhl), c
	call LABEL_F89623
	ld xbc, xhl
	ld de, (xsp + 6)
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
	ld de, (xsp + 6)
	sll de, 5
	ldada xbc, 34060
	extz xde
	add xde, xbc
	ldda32 xwa, 32626
	ld xbc, 0x1C0000F
	call 0xFA9D58
	incm 1, (xsp + 6)
	cpmi16 (xsp + 6), 0x14
	jr lt, LABEL_F8CBA7
	jrl LABEL_F8D16D

LABEL_F8CC0C:
	ldmw2 (xsp + 6), 0x7F7A
	ld wa, (xsp + 6)
	ld (xsp + 4), wa
	or xiz, xiz
	jr nz, LABEL_F8CC49
	ld xwa, (xsp + 8)
	cp xwa, 0x1C00018
	jr nz, LABEL_F8CC33
	cpmi16 (xsp + 6), 0x13
	jrl ge, LABEL_F8CFF8
	incm 1, (xsp + 6)
	jr LABEL_F8CC7B

LABEL_F8CC33:
	cp xwa, 0x1C00017
	jrl nz, LABEL_F8CFF8
	cpmi16 (xsp + 6), 0x0
	jrl le, LABEL_F8CFF8
	decm 1, (xsp + 6)
	jr LABEL_F8CC7B

LABEL_F8CC49:
	cp xiz, 0x1
	jr nz, LABEL_F8CC60
	cpmi16 (xsp + 6), 0xA
	jrl lt, LABEL_F8CFF8
	submi16 (xsp + 6), 0xA
	jr LABEL_F8CC7B

LABEL_F8CC60:
	cp xiz, 0x2
	jr nz, LABEL_F8CC86
	ld wa, (xsp + 6)
	add wa, 0xA
	cp wa, 0x13
	jrl gt, LABEL_F8CFF8
	addmi16 (xsp + 6), 0xA

LABEL_F8CC7B:
	mrdw5 0x9F, 0x06, 0x19, 0x7A, 0x7F
	ld wa, (xsp + 6)
	jrl LABEL_F8CFFC

LABEL_F8CC86:
	cp xiz, 0x3
	jrl nz, LABEL_F8CD39
	call 0xF8943E
	cps hl, 0
	jrl z, LABEL_F8CD39
	call LABEL_F892EF
	cps hl, 0
	jrl z, LABEL_F8CD39
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	ldda16 xwa, 32634
	extz wa
	calr LABEL_F8B337
	lds wa, 0
	calr InitializeOperationState
	call LABEL_F87A08
	ld wa, hl
	lds bc, 1
	calr LABEL_F8B48E
	stda8 32578, l
	calr SignalProgressUpdate
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call 0xFA9D58
	cpdi16 61854, 0
	jr z, LABEL_F8CD1D
	lds wa, 2
	call LABEL_F892F5
	cps l, 0
	jr z, LABEL_F8CD1D
	lds wa, 2
	call LABEL_F893D1
	cps l, 0
	jr nz, LABEL_F8CD18
	ldw wa, 0x8
	call LABEL_F893D1
	cps l, 0
	jr z, LABEL_F8CD1D

LABEL_F8CD18:
	ldw wa, 0xA
	jr LABEL_F8CD1F

LABEL_F8CD1D:
	lds wa, 1

LABEL_F8CD1F:
	call LABEL_F99463
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0xEE
	jrl LABEL_F8CFF4

LABEL_F8CD39:
	cp xiz, 0x4
	jrl nz, LABEL_F8CE07
	call LABEL_F8934D
	cps hl, 0
	jrl z, LABEL_F8CE07
	calr SelectPasswordMode
	cps hl, 0
	jr z, LABEL_F8CD65
	lds32 xde, 0
	ldda8 e, 35340
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C50004
	jrl LABEL_F8CEB7

LABEL_F8CD65:
	call 0xF8943E
	cps hl, 0
	jr z, LABEL_F8CD94
	cpdi8_24 0x0340ea, 0x00
	jr z, LABEL_F8CD94
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C50000
	lds32 xde, 1
	call 0xFA9D58
	ld xwa, 0x600037
	ld xbc, 0x1C00001
	lds32 xde, 0
	jrl LABEL_F8CEB7

LABEL_F8CD94:
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	lds wa, 0
	calr InitializeOperationState
	call LABEL_F87EAD
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
	jrl LABEL_F8CFF4

LABEL_F8CE07:
	cp xiz, 0x32
	jr nz, LABEL_F8CE82
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	lds wa, 0
	calr InitializeOperationState
	call LABEL_F87EAD
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
	jrl LABEL_F8CFF4

LABEL_F8CE82:
	cp xiz, 0x5
	jrl nz, LABEL_F8CF0B
	call 0xF8943E
	cps hl, 0
	jr z, LABEL_F8CF0B
	cpdi8_24 0x0340ea, 0x00
	jr z, LABEL_F8CEBE
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C50000
	lds32 xde, 1
	call 0xFA9D58
	ld xwa, 0x7B0051
	ld xbc, 0x1C00001
	lds32 xde, 0

LABEL_F8CEB7:
	call 0xFA9D58
	jrl LABEL_F8CFF8

LABEL_F8CEBE:
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	lds wa, 0
	calr InitializeOperationState
	call LABEL_F8872D
	ld wa, hl
	lds bc, 5
	calr LABEL_F8B48E
	stda8 32578, l
	calr SignalProgressUpdate
	call LABEL_F89568
	call 0xF8953B
	call 0xF8987D
	stda16 34050, xhl
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0xEE
	jrl LABEL_F8CFF4

LABEL_F8CF0B:
	cp xiz, 0x33
	jr nz, LABEL_F8CF60
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	lds wa, 0
	calr InitializeOperationState
	call LABEL_F8872D
	ld wa, hl
	lds bc, 5
	calr LABEL_F8B48E
	stda8 32578, l
	calr SignalProgressUpdate
	call LABEL_F89568
	call 0xF8953B
	call 0xF8987D
	stda16 34050, xhl
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0xEE
	jrl LABEL_F8CFF4

LABEL_F8CF60:
	cp xiz, 0x6
	jrl nz, LABEL_F8CFF8
	call 0xF8943E
	cps hl, 0
	jrl z, LABEL_F8CFF8
	ld xbc, (xsp + 8)
	ldda16 xwa, 32634
	cp xbc, 0x1C00018
	jr nz, LABEL_F8CF91
	ld bc, wa
	cp wa, 0x13
	jr ge, LABEL_F8CFA5
	inc 1, bc
	stda16 32634, xbc
	jr LABEL_F8CFA5

LABEL_F8CF91:
	cp xbc, 0x1C00017
	jr nz, LABEL_F8CFA5
	ld bc, wa
	cps wa, 0
	jr le, LABEL_F8CFA5
	dec 1, bc
	stda16 32634, xbc

LABEL_F8CFA5:
	ld wa, (xsp + 6)
	cpda16 xwa, 32634
	jr z, LABEL_F8CFF8
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	lds wa, 0
	calr InitializeOperationState
	ldda16 xwa, 32634
	call LABEL_F88838
	ld wa, hl
	lds bc, 5
	calr LABEL_F8B48E
	stda8 32578, l
	calr SignalProgressUpdate
	call 0xF8987D
	stda16 34050, xhl
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0xEE

LABEL_F8CFF4:
	call LABEL_F994BD

LABEL_F8CFF8:
	ldda16 xwa, 32634

LABEL_F8CFFC:
	cp (xsp + 4), wa
	jrl z, LABEL_F8D16D
	call 0xF89605
	stdi8 35320, 4
	ldda16 xde, 32634
	exts xde
	ldda32 xwa, 32626
	ld xbc, 0x1E50002
	call 0xFA9D58
	ld de, (xsp + 4)
	sll de, 5
	ldada xbc, 34060
	extz xde
	add xde, xbc
	ldda32 xwa, 32626
	ld xbc, 0x1C0000F
	call 0xFA9D58
	ldda16 xde, 32634
	sll de, 5
	ldada xbc, 34060
	extz xde
	add xde, xbc
	ldda32 xwa, 32626
	ld xbc, 0x1C0000F
	call 0xFA9D58
	ldmw (xsp + 6), 0x0

LABEL_F8D05A:
	ld wa, (xsp + 6)
	extz wa
	call LABEL_F893D1
	ld wa, (xsp + 6)
	extz wa
	cps l, 0
	jr z, LABEL_F8D072
	call LABEL_F89321
	jr LABEL_F8D076

LABEL_F8D072:
	call LABEL_F89335

LABEL_F8D076:
	incm 1, (xsp + 6)
	cpmi16 (xsp + 6), 0x8
	jr lt, LABEL_F8D05A
	ldw wa, 0x8
	call LABEL_F893D1
	cps l, 0
	jr z, LABEL_F8D09C
	ldw wa, 0x9
	call LABEL_F893D1
	cps l, 0
	jr z, LABEL_F8D09C
	lds wa, 2
	call LABEL_F89321

LABEL_F8D09C:
	ldda32 xwa, 32630
	or xwa, xwa
	jrl z, LABEL_F8D16D
	cpdi8 36150, 103
	jr z, LABEL_F8D0F3
	call 0xF8943E
	ld iz, hl
	ldw wa, 0x8
	call LABEL_F893D1
	cps l, 0
	jr z, LABEL_F8D0CB
	ldw wa, 0x9
	call LABEL_F893D1
	cps l, 0
	jr z, LABEL_F8D0CB
	set 2, iz

LABEL_F8D0CB:
	call LABEL_F892EF
	and iz, hl
	bit 0, iz
	jr z, LABEL_F8D0E4
	call LABEL_F8964C
	cps l, 0
	jr z, LABEL_F8D0E4
	res 0, iz
	set 1, iz

LABEL_F8D0E4:
	ld de, iz
	extz xde
	ldda32 xwa, 32630
	ld xbc, 0x1E50001
	jr LABEL_F8D169

LABEL_F8D0F3:
	call LABEL_F8934D
	extz xhl
	ldda32 xwa, 32630
	ld xbc, 0x1E50001
	ld xde, xhl
	jr LABEL_F8D169

LABEL_F8D106:
	stda32 32630, xbc
	cpdi8 36150, 103
	jr z, LABEL_F8D158
	call 0xF8943E
	ld iz, hl
	ldw wa, 0x8
	call LABEL_F893D1
	cps l, 0
	jr z, LABEL_F8D130
	ldw wa, 0x9
	call LABEL_F893D1
	cps l, 0
	jr z, LABEL_F8D130
	set 2, iz

LABEL_F8D130:
	call LABEL_F892EF
	and iz, hl
	bit 0, iz
	jr z, LABEL_F8D149
	call LABEL_F8964C
	cps l, 0
	jr z, LABEL_F8D149
	res 0, iz
	set 1, iz

LABEL_F8D149:
	ld de, iz
	extz xde
	ldda32 xwa, 32630
	ld xbc, 0x1E50001
	jr LABEL_F8D169

LABEL_F8D158:
	call LABEL_F8934D
	extz xhl
	ldda32 xwa, 32630
	ld xbc, 0x1E50001
	ld xde, xhl

LABEL_F8D169:
	call 0xFA9D58

LABEL_F8D16D:
	lds32 xhl, 0
	pop xiz
	inc 8, xsp
	ret

