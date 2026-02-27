; =============================================================================
; file_io/composer_filters.asm - Composer Load and Filter Operations
; =============================================================================
; Composer file loading and load/save filter routines.
;
; Key routines:
;   FmmComposerLoadFunc              - Composer file loading
;   FmmLoadFilterFunc                - Load filter settings
;   FmmSaveFilterFunc                - Save filter settings
; =============================================================================

FmmComposerLoadFunc:
	dec 2, xsp
	pushw iz
	cp xbc, 0x1C00018
	jrl z, LABEL_F8D380
	cp xbc, 0x1C00017
	jrl z, LABEL_F8D380
	cp xbc, 0x1C0000B
	jrl z, LABEL_F8D30B
	cp xbc, 0x1E50004
	jrl z, LABEL_F8D2D7
	cp xbc, 0x1C00013
	jrl nz, LABEL_F8D4CA
	cp xde, 0x3
	jrl z, LABEL_F8D2D1
	cp xde, 0x2
	jrl nz, LABEL_F8D4CA
	stdi8 34046, 0
	lds wa, 1
	calr InitializeOperationState
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	cpdi16 34048, 0
	jr ge, LABEL_F8D1E4
	call 0xF89520
	extz hl
	stda16 34048, xhl
	calr SignalProgressUpdate

LABEL_F8D1E4:
	ldda16 xwa, 34048
	cps wa, 1
	jrl z, LABEL_F8D289
	cps wa, 0
	jr z, LABEL_F8D26F
	cps wa, 5
	jr z, LABEL_F8D22F
	cpdi16 34050, 0
	jr ge, LABEL_F8D210
	call 0xF8987D
	stda16 34050, xhl
	call LABEL_F8958D
	call 0xF8953B
	calr SignalProgressUpdate

LABEL_F8D210:
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	jrl LABEL_F8D4C6

LABEL_F8D22F:
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
	stdi8 32578, 0
	ldw wa, 0xEE
	jr LABEL_F8D2CA

LABEL_F8D26F:
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0x7D
	call 0xF99490
	jrl LABEL_F8D4CA

LABEL_F8D289:
	calr ResetProgressIndication
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
	stdi8 32578, 2
	ldw wa, 0xEE

LABEL_F8D2CA:
	call LABEL_F994BD
	jrl LABEL_F8D4CA

LABEL_F8D2D1:
	calr CancelOperationCleanup
	jrl LABEL_F8D4CA

LABEL_F8D2D7:
	stda32 32636, xde
	call 0xF895EF
	stda16 32640, xhl
	cps hl, 0
	jr lt, LABEL_F8D2F7
	exts xhl
	ldda32 xwa, 32636
	ld xbc, 0x1E50002
	ld xde, xhl
	jrl LABEL_F8D4C6

LABEL_F8D2F7:
	stdi16 32640, 0
	ldda32 xwa, 32636
	ld xbc, 0x1E50002
	lds32 xde, 0
	jrl LABEL_F8D4C6

LABEL_F8D30B:
	lds iz, 0

LABEL_F8D30D:
	ld wa, iz
	ld hl, wa
	sll hl, 5
	ldada xde, 34060
	extz xhl
	add xhl, xde
	ldto_berp C, 0xF8
	ld (xhl), c
	lds bc, 3
	call LABEL_F89408
	cps l, 0
	jr z, LABEL_F8D335
	ld wa, iz
	call LABEL_F89623
	ld xbc, xhl
	jr LABEL_F8D33A

LABEL_F8D335:
	lda_24 xbc, 0xea06ec

LABEL_F8D33A:
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
	ldda32 xwa, 32636
	ld xbc, 0x1C0000F
	call 0xFA9D58
	inc 1, iz
	cp iz, 0x14
	jr lt, LABEL_F8D30D
	jrl LABEL_F8D4CA

LABEL_F8D380:
	ldda16 xwa, 32640
	ld (xsp + 2), wa
	or xde, xde
	jr nz, LABEL_F8D3B0
	cp xbc, 0x1C00018
	jr nz, LABEL_F8D39E
	cp wa, 0x13
	jrl ge, LABEL_F8D473
	inc 1, wa
	jr LABEL_F8D3DE

LABEL_F8D39E:
	cp xbc, 0x1C00017
	jrl nz, LABEL_F8D473
	cps wa, 0
	jrl le, LABEL_F8D473
	dec 1, wa
	jr LABEL_F8D3DE

LABEL_F8D3B0:
	cp xde, 0x1
	jr nz, LABEL_F8D3C5
	cp wa, 0xA
	jrl lt, LABEL_F8D473
	sub wa, 0xA
	jr LABEL_F8D3DE

LABEL_F8D3C5:
	cp xde, 0x2
	jr nz, LABEL_F8D3E5
	ld bc, wa
	add bc, 0xA
	cp bc, 0x13
	jrl gt, LABEL_F8D473
	add wa, 0xA

LABEL_F8D3DE:
	stda16 32640, xwa
	jrl LABEL_F8D477

LABEL_F8D3E5:
	cp xde, 0x3
	jrl nz, LABEL_F8D473
	call 0xF8943E
	cps hl, 0
	jr z, LABEL_F8D473
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	lds iz, 0

LABEL_F8D408:
	ldto_berp A, 0xF8
	extz wa
	call LABEL_F89335
	inc 1, iz
	cp iz, 0x8
	jr lt, LABEL_F8D408
	lds wa, 3
	call LABEL_F89321
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
	lds wa, 1
	call LABEL_F99463
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0xEE
	call LABEL_F994BD

LABEL_F8D473:
	ldda16 xwa, 32640

LABEL_F8D477:
	cp (xsp + 2), wa
	jr z, LABEL_F8D4CA
	call 0xF89605
	ldda16 xde, 32640
	exts xde
	ldda32 xwa, 32636
	ld xbc, 0x1E50002
	call 0xFA9D58
	ld de, (xsp + 2)
	sll de, 5
	ldada xbc, 34060
	extz xde
	add xde, xbc
	ldda32 xwa, 32636
	ld xbc, 0x1C0000F
	call 0xFA9D58
	ldda16 xde, 32640
	sll de, 5
	ldada xbc, 34060
	extz xde
	add xde, xbc
	ldda32 xwa, 32636
	ld xbc, 0x1C0000F

LABEL_F8D4C6:
	call 0xFA9D58

LABEL_F8D4CA:
	lds32 xhl, 0
	popw iz
	inc 2, xsp
	ret

RenderFilterDisplay:
	dec 6, xsp
	ld (xsp), c
	ld (xsp + 2), xwa
	ld xwa, (xsp + 2)
	ld c, (xsp)
	lda_dpi XHL, 0xE0
	ld (xsp + 2), xwa
	cpmi8 (xsp), 0x0
	jr nz, LABEL_F8D4FA
	call LABEL_F8964C
	cps l, 0
	jr z, LABEL_F8D4FA
	ld xwa, (xsp + 2)
	ld xbc, 0xEA06EE
	jrl LABEL_F8D5A9

LABEL_F8D4FA:
	cpmi8 (xsp), 0x1
	jr nz, LABEL_F8D53A
	call LABEL_F8964C
	cps l, 0
	jr z, LABEL_F8D53A
	lds wa, 0
	call LABEL_F893D1
	cps l, 0
	jr z, LABEL_F8D530
	lds wa, 0
	call LABEL_F892F5
	cps l, 0
	jr z, LABEL_F8D526
	ld xwa, (xsp + 2)
	ld xbc, 0xEA06F4
	jrl LABEL_F8D5A9

LABEL_F8D526:
	ld xwa, (xsp + 2)
	ld xbc, 0xEA06FA
	jr LABEL_F8D5A9

LABEL_F8D530:
	ld xwa, (xsp + 2)
	ld xbc, 0xEA0700
	jr LABEL_F8D5A9

LABEL_F8D53A:
	ld a, (xsp)
	extz wa
	call LABEL_F893D1
	cps l, 0
	jr z, LABEL_F8D566
	ld a, (xsp)
	extz wa
	call LABEL_F892F5
	cps l, 0
	jr z, LABEL_F8D55C
	ld xwa, (xsp + 2)
	ld xbc, 0xEA0706
	jr LABEL_F8D5A9

LABEL_F8D55C:
	ld xwa, (xsp + 2)
	ld xbc, 0xEA070C
	jr LABEL_F8D5A9

LABEL_F8D566:
	cpmi8 (xsp), 0x2
	jr nz, LABEL_F8D5A1
	ldw wa, 0x8
	call LABEL_F893D1
	cps l, 0
	jr z, LABEL_F8D5A1
	ldw wa, 0x9
	call LABEL_F893D1
	cps l, 0
	jr z, LABEL_F8D5A1
	ld a, (xsp)
	extz wa
	call LABEL_F892F5
	cps l, 0
	jr z, LABEL_F8D597
	ld xwa, (xsp + 2)
	ld xbc, 0xEA0712
	jr LABEL_F8D5A9

LABEL_F8D597:
	ld xwa, (xsp + 2)
	ld xbc, 0xEA0718
	jr LABEL_F8D5A9

LABEL_F8D5A1:
	ld xwa, (xsp + 2)
	ld xbc, 0xEA071E

LABEL_F8D5A9:
	call LABEL_F890DC
	inc 6, xsp
	ret

FmmLoadFilterFunc:
	dec 6, xsp
	ld (xsp + 2), xde
	cp xbc, 0x1C00018
	jr z, LABEL_F8D61D
	cp xbc, 0x1C00017
	jr z, LABEL_F8D61D
	cp xbc, 0x1C0000B
	jr z, LABEL_F8D5E0
	cp xbc, 0x1E50004
	jrl nz, LABEL_F8D77F
	ld xwa, (xsp + 2)
	stda32 32642, xwa
	jrl LABEL_F8D77F

LABEL_F8D5E0:
	ldmw (xsp), 0x0

LABEL_F8D5E4:
	ld wa, (xsp)
	sll wa, 4
	ldada xbc, 32646
	extz xwa
	add xwa, xbc
	ld bc, (xsp)
	extz bc
	calr RenderFilterDisplay
	ld de, (xsp)
	sll de, 4
	ldada xbc, 32646
	extz xde
	add xde, xbc
	ldda32 xwa, 32642
	ld xbc, 0x1C0000F
	call 0xFA9D58
	incm 1, (xsp)
	cpmi16 (xsp), 0x8
	jr lt, LABEL_F8D5E4
	jrl LABEL_F8D77F

LABEL_F8D61D:
	ld xwa, (xsp + 2)
	cp xwa, 0x8
	jrl nc, LABEL_F8D6C6
	cp xbc, 0x1C00017
	jr nz, LABEL_F8D65F
	cp xwa, 0x1
	jr nz, LABEL_F8D645
	call LABEL_F8964C
	cps l, 0
	jr z, LABEL_F8D645
	lds wa, 0
	jr LABEL_F8D659

LABEL_F8D645:
	ld xwa, (xsp + 2)
	or xwa, xwa
	jr nz, LABEL_F8D654
	call LABEL_F8964C
	cps l, 0
	jr nz, LABEL_F8D68E

LABEL_F8D654:
	ld xwa, (xsp + 2)
	extz wa

LABEL_F8D659:
	call LABEL_F89321
	jr LABEL_F8D68E

LABEL_F8D65F:
	ld xwa, (xsp + 2)
	cp xwa, 0x1
	jr nz, LABEL_F8D676
	call LABEL_F8964C
	cps l, 0
	jr z, LABEL_F8D676
	lds wa, 0
	jr LABEL_F8D68A

LABEL_F8D676:
	ld xwa, (xsp + 2)
	or xwa, xwa
	jr nz, LABEL_F8D685
	call LABEL_F8964C
	cps l, 0
	jr nz, LABEL_F8D68E

LABEL_F8D685:
	ld xwa, (xsp + 2)
	extz wa

LABEL_F8D68A:
	call LABEL_F89335

LABEL_F8D68E:
	ld xwa, (xsp + 2)
	ld c, a
	extz bc
	ld wa, bc
	sla wa, 4
	ldada xde, 32646
	exts xwa
	add xwa, xde
	calr RenderFilterDisplay
	ld xwa, (xsp + 2)
	extz wa
	sla wa, 4
	ldada xbc, 32646
	st_dri3b B, 0x07, 0xE4, 0xE0
	ldda32 xwa, 32642
	ld xbc, 0x1C0000F
	call 0xFA9D58
	jrl LABEL_F8D77F

LABEL_F8D6C6:
	ld xwa, (xsp + 2)
	cp xwa, 0xA
	jrl nz, LABEL_F8D77F
	call 0xF8943E
	cps hl, 0
	jrl z, LABEL_F8D77F
	call LABEL_F892EF
	cps hl, 0
	jrl z, LABEL_F8D77F
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call 0xFA9D58
	call 0xF895EF
	extz hl
	ld wa, hl
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
	jr z, LABEL_F8D762
	lds wa, 2
	call LABEL_F892F5
	cps l, 0
	jr z, LABEL_F8D762
	lds wa, 2
	call LABEL_F893D1
	cps l, 0
	jr nz, LABEL_F8D75D
	ldw wa, 0x8
	call LABEL_F893D1
	cps l, 0
	jr z, LABEL_F8D762

LABEL_F8D75D:
	ldw wa, 0xA
	jr LABEL_F8D764

LABEL_F8D762:
	lds wa, 1

LABEL_F8D764:
	call LABEL_F99463
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call 0xFA9D58
	ldw wa, 0xEE
	call LABEL_F994BD

LABEL_F8D77F:
	lds32 xhl, 0
	inc 6, xsp
	ret

RenderSaveFilterDisplay:
	dec 6, xsp
	ld (xsp), c
	ld (xsp + 2), xwa
	ld xwa, (xsp + 2)
	ld c, (xsp)
	lda_dpi XHL, 0xE0
	ld (xsp + 2), xwa
	ld a, c
	extz wa
	call LABEL_F89353
	cps l, 0
	jr z, LABEL_F8D7C3
	cpmi8 (xsp), 0x1
	jr nz, LABEL_F8D7B9
	call LABEL_F893AB
	cps l, 0
	jr z, LABEL_F8D7B9
	ld xwa, (xsp + 2)
	ld xbc, 0xEA0724
	jr LABEL_F8D7CB

LABEL_F8D7B9:
	ld xwa, (xsp + 2)
	ld xbc, 0xEA072A
	jr LABEL_F8D7CB

LABEL_F8D7C3:
	ld xwa, (xsp + 2)
	ld xbc, 0xEA0730

LABEL_F8D7CB:
	call LABEL_F890DC
	inc 6, xsp
	ret

FmmSaveFilterFunc:
	dec 6, xsp
	ld (xsp + 2), xde
	cp xbc, 0x1C00018
	jr z, LABEL_F8D83F
	cp xbc, 0x1C00017
	jr z, LABEL_F8D83F
	cp xbc, 0x1C0000B
	jr z, LABEL_F8D802
	cp xbc, 0x1E50004
	jrl nz, LABEL_F8DB48
	ld xwa, (xsp + 2)
	stda32 32774, xwa
	jrl LABEL_F8DB48

LABEL_F8D802:
	ldmw (xsp), 0x0

LABEL_F8D806:
	ld wa, (xsp)
	sll wa, 4
	ldada xbc, 32778
	extz xwa
	add xwa, xbc
	ld bc, (xsp)
	extz bc
	calr RenderSaveFilterDisplay
	ld de, (xsp)
	sll de, 4
	ldada xbc, 32778
	extz xde
	add xde, xbc
	ldda32 xwa, 32774
	ld xbc, 0x1C0000F
	call 0xFA9D58
	incm 1, (xsp)
	cpmi16 (xsp), 0x8
	jr lt, LABEL_F8D806
	jrl LABEL_F8DB48

LABEL_F8D83F:
	ld xwa, (xsp + 2)
	cp xwa, 0x8
	jrl nc, LABEL_F8D8EF
	cp xwa, 0x1
	jr nz, LABEL_F8D8A4
	cp xbc, 0x1C00017
	jr nz, LABEL_F8D875
	call LABEL_F893AB
	cps l, 0
	jr z, LABEL_F8D86E
	call LABEL_F893CA
	ld xwa, (xsp + 2)
	extz wa
	jr LABEL_F8D8B7

LABEL_F8D86E:
	ld xwa, (xsp + 2)
	extz wa
	jr LABEL_F8D8B1

LABEL_F8D875:
	ld xwa, (xsp + 2)
	extz wa
	call LABEL_F89353
	cps l, 0
	jr z, LABEL_F8D891
	call LABEL_F893AB
	cps l, 0
	jr nz, LABEL_F8D8BB
	ld xwa, (xsp + 2)
	extz wa
	jr LABEL_F8D8B7

LABEL_F8D891:
	call LABEL_F893AB
	cps l, 0
	jr nz, LABEL_F8D8BB
	call LABEL_F893C3
	ld xwa, (xsp + 2)
	extz wa
	jr LABEL_F8D8B1

LABEL_F8D8A4:
	ld xwa, (xsp + 2)
	extz wa
	cp xbc, 0x1C00017
	jr nz, LABEL_F8D8B7

LABEL_F8D8B1:
	call LABEL_F8937F
	jr LABEL_F8D8BB

LABEL_F8D8B7:
	call LABEL_F89393

LABEL_F8D8BB:
	ld xwa, (xsp + 2)
	ld c, a
	extz bc
	ld wa, bc
	sla wa, 4
	ldada xde, 32778
	exts xwa
	add xwa, xde
	calr RenderSaveFilterDisplay
	ld xwa, (xsp + 2)
	extz wa
	sla wa, 4
	ldada xbc, 32778
	st_dri3b B, 0x07, 0xE4, 0xE0
	ldda32 xwa, 32774
	ld xbc, 0x1C0000F
	jrl LABEL_F8D9FD

LABEL_F8D8EF:
	ld xwa, (xsp + 2)
	cp xwa, 0x8
	jr nz, LABEL_F8D94F
	call LABEL_F893CA
	ldmw (xsp), 0x0

LABEL_F8D902:
	ld wa, (xsp)
	extz wa
	cpmi16 (xsp), 0x6
	jr ge, LABEL_F8D912
	call LABEL_F8937F
	jr LABEL_F8D916

LABEL_F8D912:
	call LABEL_F89393

LABEL_F8D916:
	ld wa, (xsp)
	sll wa, 4
	ldada xbc, 32778
	extz xwa
	add xwa, xbc
	ld bc, (xsp)
	extz bc
	calr RenderSaveFilterDisplay
	ld de, (xsp)
	sll de, 4
	ldada xbc, 32778
	extz xde
	add xde, xbc
	ldda32 xwa, 32774
	ld xbc, 0x1C0000F
	call 0xFA9D58
	incm 1, (xsp)
	cpmi16 (xsp), 0x8
	jr lt, LABEL_F8D902
	jrl LABEL_F8DB48

LABEL_F8D94F:
	ld xwa, (xsp + 2)
	cp xwa, 0x9
	jr nz, LABEL_F8D9A3
	call LABEL_F893CA
	ldmw (xsp), 0x0

LABEL_F8D962:
	ld wa, (xsp)
	extz wa
	call LABEL_F8937F
	ld wa, (xsp)
	sll wa, 4
	ldada xbc, 32778
	extz xwa
	add xwa, xbc
	ld bc, (xsp)
	extz bc
	calr RenderSaveFilterDisplay
	ld de, (xsp)
	sll de, 4
	ldada xbc, 32778
	extz xde
	add xde, xbc
	ldda32 xwa, 32774
	ld xbc, 0x1C0000F
	call 0xFA9D58
	incm 1, (xsp)
	cpmi16 (xsp), 0x8
	jr lt, LABEL_F8D962
	jrl LABEL_F8DB48

LABEL_F8D9A3:
	ld xwa, (xsp + 2)
	cp xwa, 0xA
	jrl nz, LABEL_F8DA76
	call LABEL_F8934D
	cps hl, 0
	jrl z, LABEL_F8DA76
	calr SelectPasswordMode
	cps hl, 0
	jr z, LABEL_F8D9D1
	lds32 xde, 0
	ldda8 e, 35340
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C50004
	jr LABEL_F8D9FD

LABEL_F8D9D1:
	call 0xF8943E
	cps hl, 0
	jr z, LABEL_F8DA04
	cpi8_24 0x0340ea, 0x00
	jr z, LABEL_F8DA04
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C50000
	lds32 xde, 1
	call 0xFA9D58
	ld xwa, 0x600037
	ld xbc, 0x1C00001
	lds32 xde, 0

LABEL_F8D9FD:
	call 0xFA9D58
	jrl LABEL_F8DB48

LABEL_F8DA04:
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
	jr LABEL_F8DAF1

LABEL_F8DA76:
	ld xwa, (xsp + 2)
	cp xwa, 0x32
	jr nz, LABEL_F8DAF7
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

LABEL_F8DAF1:
	call LABEL_F994BD
	jr LABEL_F8DB48

LABEL_F8DAF7:
	ld xwa, (xsp + 2)
	cp xwa, 0xB
	jr nz, LABEL_F8DB48
	call LABEL_F893CA
	ldmw (xsp), 0x0

LABEL_F8DB0A:
	ld wa, (xsp)
	extz wa
	call LABEL_F89393
	ld wa, (xsp)
	sll wa, 4
	ldada xbc, 32778
	extz xwa
	add xwa, xbc
	ld bc, (xsp)
	extz bc
	calr RenderSaveFilterDisplay
	ld de, (xsp)
	sll de, 4
	ldada xbc, 32778
	extz xde
	add xde, xbc
	ldda32 xwa, 32774
	ld xbc, 0x1C0000F
	call 0xFA9D58
	incm 1, (xsp)
	cpmi16 (xsp), 0x8
	jr lt, LABEL_F8DB0A

LABEL_F8DB48:
	lds32 xhl, 0
	inc 6, xsp
	ret

