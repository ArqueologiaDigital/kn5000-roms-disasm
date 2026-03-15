; =============================================================================
; file_io/single_load.asm - Single File Load Operations
; =============================================================================
; Single file load mode with source/destination selection.
;
; Key routines:
;   SingleLoadModeFunc               - Single load mode entry
;   SingleLoadDstBankFunc            - Destination bank selection
;   SingleLoadDstMemFunc             - Destination memory selection
;   SingleLoadSrcBankFunc            - Source bank selection
;   SingleLoadSrcMemFunc             - Source memory selection
;   SingleLoadSrcFunc                - Source file selection
;   SingleLoadDstFunc                - Destination selection
;   CmpSingleLoadSrcFunc             - Composer single load source
;   CmpSingleLoadDstFunc             - Composer single load destination
;   CmpSingleLoadFileFunc            - Composer single load file
;   FmmCmpSingleLoadFunc             - Composer single load handler
; =============================================================================

SingleLoadModeFunc:
	cp xbc, 0x1C0000B
	jr z, SLMode_HandleShow
	cp xbc, 0x1E50004
	jr nz, SLMode_Return
	stda32 33206, xde
	jr SLMode_Return

SLMode_HandleShow:
	ldda8 a, 35320
	extz wa
	sla wa, 2
	lda_24 xbc, 0xea0598
	ld_sril3 XDE, 0x07, 0xE4, 0xE0
	ldda32 xwa, 33206
	ld xbc, 0x1C0000F
	call ApPostEvent

SLMode_Return:
	lds32 xhl, 0
	ret

SingleLoadDstBankFunc:
	cp xbc, 0x1C0000B
	jr z, SLDstBank_HandleShow
	cp xbc, 0x1E50004
	jr nz, SLDstBank_Return
	stda32 33210, xde
	jr SLDstBank_Return

SLDstBank_HandleShow:
	ldda8 a, 35320
	extz wa
	sla wa, 2
	lda_24 xbc, 0xea05f2
	ld_sril3 XDE, 0x07, 0xE4, 0xE0
	ldda32 xwa, 33210
	ld xbc, 0x1C0000F
	call ApPostEvent

SLDstBank_Return:
	lds32 xhl, 0
	ret

SingleLoadDstMemFunc:
	cp xbc, 0x1C0000B
	jr z, SLDstMem_HandleShow
	cp xbc, 0x1E50004
	jr nz, SLDstMem_Return
	stda32 33214, xde
	jr SLDstMem_Return

SLDstMem_HandleShow:
	ldda32 xwa, 33214
	lda_24 xde, 0xea0624
	cpdi8 35322, 0
	jr z, SLDstMem_ShowFromBank
	cpdi8 35320, 1
	jr z, SLDstMem_ShowFromBank
	ld xde, (xde + 16)
	ld xbc, 0x1C0000F
	jr SLDstMem_DispatchShow

SLDstMem_ShowFromBank:
	ldda8 c, 35320
	extz bc
	sla bc, 2
	ld_sril3 XDE, 0x07, 0xE8, 0xE4
	ld xbc, 0x1C0000F

SLDstMem_DispatchShow:
	call ApPostEvent

SLDstMem_Return:
	lds32 xhl, 0
	ret

SingleLoadSrcBankFunc:
	cp xbc, 0x1C0000B
	jr z, SLSrcBank_HandleShow
	cp xbc, 0x1E50004
	jr nz, SLSrcBank_Return
	stda32 33218, xde
	jr SLSrcBank_Return

SLSrcBank_HandleShow:
	ldda32 xwa, 33218
	lda_24 xde, 0xea05f2
	ldda8 c, 35320
	cps c, 0
	jr nz, SLSrcBank_ShowFromIndex
	cpdi8 35338, 0
	jr z, SLSrcBank_ShowFromIndex
	ld xde, (xde + 16)
	ld xbc, 0x1C0000F
	jr SLSrcBank_DispatchShow

SLSrcBank_ShowFromIndex:
	extz bc
	sla bc, 2
	ld_sril3 XDE, 0x07, 0xE8, 0xE4
	ld xbc, 0x1C0000F

SLSrcBank_DispatchShow:
	call ApPostEvent

SLSrcBank_Return:
	lds32 xhl, 0
	ret

SingleLoadSrcMemFunc:
	cp xbc, 0x1C0000B
	jr z, SLSrcMem_HandleShow
	cp xbc, 0x1E50004
	jr nz, SLSrcMem_Return
	stda32 33222, xde
	jr SLSrcMem_Return

SLSrcMem_HandleShow:
	ldda32 xwa, 33222
	lda_24 xde, 0xea0624
	ldda8 c, 35320
	cps c, 1
	jr z, SLSrcMem_ShowDirect
	cpdi8 35322, 0
	jr z, SLSrcMem_ShowFromIndex

SLSrcMem_ShowDirect:
	ld xde, (xde + 16)
	ld xbc, 0x1C0000F
	jr SLSrcMem_DispatchShow

SLSrcMem_ShowFromIndex:
	extz bc
	sla bc, 2
	ld_sril3 XDE, 0x07, 0xE8, 0xE4
	ld xbc, 0x1C0000F

SLSrcMem_DispatchShow:
	call ApPostEvent

SLSrcMem_Return:
	lds32 xhl, 0
	ret

SLSrcBankList_FuncBody:
	dec	6, xsp
	push	xiz
	ld	(xsp+4), c
	ld	(xsp+6), xwa
	ldada	xwa, 35150
	.byte 0xf5, 0xe0, 0x00, 0x00
	ldda8	c, 35320
	extz	bc
	.byte 0xd9, 0xec, 0x02
	lda_24	xde, 15336946
	.byte 0xe3, 0x07, 0xe8, 0xe4, 0x21
	inc	1, xbc
	call	16290012
	ldada	xwa, 35151
	ld	xbc, 15337784
	call	16290067
	ldada	xiz, 35151
	ldda8	a, 35324
	extz	wa
	.byte 0x8f, 0x04, 0x51
	inc	1, a
	extz	wa
	lds	bc, 0
	calr	-14983
	ld	xbc, xhl
	ld	xwa, xiz
	call	16290067
	ldada	xwa, 35151
	ldw	bc, 16
	calr	-4482
	ld	xwa, (xsp+6)
	ld	xbc, 29360143
	ld	xde, 35150
	call	16424280
	pop	xiz
	inc	6, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xwa
	ldada	xwa, 35150
	ld	(xwa+21), 1
	lda	xiz, (xwa+22)
	ldda8	a, 35324
	extz	wa
	div8rr	a, c
	extz	wa
	call	16294158
	ld	xbc, xhl
	ld	xwa, xiz
	call	16290012
	ldada	xwa, 35172
	ldw	bc, 16
	calr	-4552
	ldada	xde, 35171
	ld	xwa, (xsp+4)
	ld	xbc, 29360143
	call	16424280
	pop	xiz
	inc	4, xsp
	ret
	dec	6, xsp
	push	xiz
	ld	(xsp+4), c
	ld	(xsp+6), xwa
	ldada	xwa, 35150
	ld	(xwa+42), 2
	lda	xwa, (xwa+43)
	ldda8	c, 35320
	extz	bc
	.byte 0xd9, 0xec, 0x02
	lda_24	xde, 15336996
	.byte 0xe3, 0x07, 0xe8, 0xe4, 0x21
	inc	1, xbc
	call	16290012
	ldada	xwa, 35193
	ld	xbc, 15337788
	call	16290067
	cpdi8	35322, 0
	jr	nz, 32
	ldada	xiz, 35193
	ldda8	a, 35324
	extz	wa
	.byte 0x8f, 0x04, 0x51
	ld	a, w
	inc	1, a
	extz	wa
	lds	bc, 0
	calr	-15180
	ld	xbc, xhl
	ld	xwa, xiz
	call	16290067
	ldada	xwa, 35193
	ldw	bc, 16
	calr	-4679
	ldada	xde, 35192
	ld	xwa, (xsp+6)
	ld	xbc, 29360143
	call	16424280
	cpdi8	35322, 0
	jr	z, 36
	ldada	xwa, 35150
	ld	(xwa+63), 3
	lda	xwa, (xwa+64)
	ld	xbc, 15337792
	call	16290012
	ldada	xde, 35213
	ld	xwa, (xsp+6)
	ld	xbc, 29360143
	call	16424280
	pop	xiz
	inc	6, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xwa
	cpdi8	35322, 0
	jr	nz, 55
	ldada	xwa, 35150
	ld	(xwa+63), 3
	lda	xiz, (xwa+64)
	ldda8	a, 35324
	extz	wa
	call	16294280
	ld	xbc, xhl
	ld	xwa, xiz
	call	16290012
	ldada	xwa, 35214
	ldw	bc, 16
	calr	-4794
	ldada	xde, 35213
	ld	xwa, (xsp+4)
	ld	xbc, 29360143
	call	16424280
	pop	xiz
	inc	4, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	ld	xiz, xwa
	cp	xbc, 29360152
	jr	z, 98
	cp	xbc, 29360151
	jr	z, 90
	cp	xbc, 29360139
	jrl	nz, 534
	cpdi8	35338, 0
	jr	z, 15
	ldda8	a, 35324
	extz	wa
	.byte 0xc2, 0x52, 0x09, 0xea, 0x51
	stda8	35324, w
	ld8_24	c, 15337810
	ld	xwa, xiz
	calr	-492
	ld8_24	c, 15337810
	ld	xwa, xiz
	calr	-317
	ld8_24	c, 15337810
	ld	xwa, xiz
	calr	-396
	ld8_24	c, 15337810
	ld	xwa, xiz
	calr	-167
	lds32	xwa, 0
	stda32	33226, xwa
	stdi8	33230, 0
	stdi8	33232, 0
	jrl	453
	ldda8	e, 35324
	ld	xwa, (xsp+4)
	cp	xwa, 5
	jrl	nz, 154
	cpdi8	35338, 0
	jr	nz, 108
	ld	xix, xbc
	cp	xbc, 29360151
	jr	nz, 43
	ld8_24	l, 15337810
	ld	a, l
	ld	c, e
	add	a, e
	.byte 0xc2, 0x54, 0x09, 0xea, 0xf1
	jr	nc, 25
	add	c, l
	stda8	35324, c
	ld8_24	c, 15337810
	ld	xwa, xiz
	calr	-608
	ld8_24	c, 15337810
	ld	xwa, xiz
	jr	42
	cp	xix, 29360152
	jr	nz, 47
	ld	a, e
	ld8_24	c, 15337810
	cp	e, c
	jr	c, 36
	sub	a, c
	stda8	35324, a
	ld8_24	c, 15337810
	ld	xwa, xiz
	calr	-652
	ld8_24	c, 15337810
	ld	xwa, xiz
	calr	-477
	stdi8	33232, 1
	stdi8	33230, 1
	ldda32	xwa, 33226
	.byte 0xaf, 0x04, 0xf0
	jrl	z, 312
	ldada	xde, 35171
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16424280
	ldada	xde, 35213
	ld	xwa, xiz
	ld	xbc, 29360143
	jrl	215
	ld	xwa, (xsp+4)
	cp	xwa, 6
	jrl	nz, 149
	ld	xhl, xbc
	cp	xbc, 29360151
	jr	nz, 49
	ld	c, e
	ld	a, e
	inc	1, a
	.byte 0xc2, 0x54, 0x09, 0xea, 0xf1
	jr	nc, 36
	ld8_24	e, 15337810
	ld	l, e
	ld	a, c
	extz	wa
	div8rr	a, l
	ld	a, w
	inc	1, a
	cp	a, e
	jr	nc, 67
	inc	1, c
	stda8	35324, c
	ld8_24	c, 15337810
	ld	xwa, xiz
	jr	44
	cp	xhl, 29360152
	jr	nz, 44
	ld	c, e
	cps	e, 0
	jr	z, 38
	ld8_24	e, 15337810
	ld	a, c
	extz	wa
	div8rr	a, e
	ld	a, w
	cps	a, 0
	jr	z, 21
	dec	1, c
	stda8	35324, c
	ld8_24	c, 15337810
	ld	xwa, xiz
	calr	-644
	stdi8	33230, 1
	ldda32	xwa, 33226
	.byte 0xaf, 0x04, 0xf0
	jrl	z, 150
	ldada	xde, 35171
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16424280
	ldada	xde, 35213
	ld	xwa, xiz
	ld	xbc, 29360143
	jr	54
	ld	xwa, (xsp+4)
	cp	xwa, 7
	jr	z, 8
	cp	xwa, 8
	jr	nz, 48
	ldda32	xwa, 33226
	.byte 0xaf, 0x04, 0xf0
	jr	z, 94
	ldada	xde, 35171
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16424280
	ldada	xde, 35213
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16424280
	ld	xwa, (xsp+4)
	stda32	33226, xwa
	jr	55
	ld	xwa, (xsp+4)
	cp	xwa, 40
	jr	nz, 44
	cpdi8	33232, 0
	jr	z, 15
	ld8_24	c, 15337810
	ld	xwa, xiz
	calr	-851
	stdi8	33232, 0
	cpdi8	33230, 0
	jr	z, 15
	ld8_24	c, 15337810
	ld	xwa, xiz
	calr	-634
	stdi8	33230, 0
	lds32	xhl, 0
	pop	xiz
	inc	4, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xwa
	cp	xbc, 29360139
	jrl	nz, 196
	ldada	xwa, 35150
	.byte 0xf5, 0xe0, 0x00, 0x00
	ld	(xwa), 0
	ldw	bc, 16
	calr	-5419
	ldada	xwa, 35150
	ld	(xwa+21), 1
	lda	xwa, (xwa+22)
	ldda8	c, 35320
	extz	bc
	.byte 0xd9, 0xec, 0x02
	lda_24	xde, 15336996
	.byte 0xe3, 0x07, 0xe8, 0xe4, 0x21
	inc	1, xbc
	call	16290012
	ldada	xwa, 35172
	ld	xbc, 15337816
	call	16290067
	ldada	xwa, 35172
	ldw	bc, 16
	calr	-5478
	ldada	xwa, 35150
	ld	(xwa+42), 2
	lda	xiz, (xwa+43)
	lds	wa, 0
	call	16294427
	ld	xbc, xhl
	ld	xwa, xiz
	call	16290012
	ldada	xwa, 35193
	ldw	bc, 16
	calr	-5513
	ldada	xwa, 35150
	ld	(xwa+63), 3
	lda	xwa, (xwa+64)
	ld	(xwa), 0
	ldw	bc, 16
	calr	-5533
	ld	xwa, (xsp+4)
	ld	xbc, 29360143
	ld	xde, 35150
	call	16424280
	ldada	xde, 35171
	ld	xwa, (xsp+4)
	ld	xbc, 29360143
	call	16424280
	ldada	xde, 35192
	ld	xwa, (xsp+4)
	ld	xbc, 29360143
	call	16424280
	ldada	xde, 35213
	ld	xwa, (xsp+4)
	ld	xbc, 29360143
	call	16424280
	lds32	xhl, 0
	pop	xiz
	inc	4, xsp
	ret
	dec	2, xsp
	push	xiz
	ld	(xsp+4), c
	ld	xiz, xwa
	ldada	xwa, 35150
	.byte 0xf5, 0xe0, 0x00, 0x00
	ldda8	c, 35320
	extz	bc
	.byte 0xd9, 0xec, 0x02
	lda_24	xde, 15336946
	.byte 0xe3, 0x07, 0xe8, 0xe4, 0x21
	inc	1, xbc
	call	16290012
	ldada	xwa, 35151
	ld	xbc, 15337818
	call	16290067
	ldada	xwa, 35151
	ldw	bc, 16
	calr	-5668
	ldada	xwa, 35171
	ldda8	c, 35326
	extz	bc
	.byte 0x8f, 0x04, 0x53
	extz	bc
	lds	de, 1
	calr	-1950
	ld	xwa, xiz
	ld	xbc, 29360143
	ld	xde, 35150
	call	16424280
	ldada	xde, 35171
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16424280
	pop	xiz
	inc	2, xsp
	ret
	dec	8, xsp
	push	xiz
	ld	(xsp+6), c
	ld	(xsp+8), xwa
	ldda8	a, 35326
	extz	wa
	.byte 0x8f, 0x06, 0x51
	ld	a, w
	extz	wa
	ld	(xsp+4), wa
	ldada	xwa, 35150
	ld	(xwa+42), 2
	lda	xwa, (xwa+43)
	ldda8	c, 35320
	extz	bc
	.byte 0xd9, 0xec, 0x02
	lda_24	xde, 15336996
	.byte 0xe3, 0x07, 0xe8, 0xe4, 0x21
	inc	1, xbc
	call	16290012
	ldada	xwa, 35193
	ld	xbc, 15337822
	call	16290067
	cpdi8	35322, 0
	jr	nz, 18
	ldada	xiz, 35193
	ld	wa, (xsp+4)
	calr	-2038
	ld	xbc, xhl
	ld	xwa, xiz
	call	16290067
	ldada	xwa, 35193
	ldw	bc, 16
	calr	-5832
	ldada	xde, 35192
	ld	xwa, (xsp+8)
	ld	xbc, 29360143
	call	16424280
	ldada	xbc, 35150
	lda	xwa, (xbc+63)
	cpdi8	35322, 0
	jr	z, 29
	ld	(xwa), 3
	lda	xwa, (xbc+64)
	ld	xbc, 15337826
	call	16290012
	ldada	xde, 35213
	ld	xwa, (xsp+8)
	ld	xbc, 29360143
	jr	39
	.byte 0x9f, 0x04, 0x3f, 0x04, 0x00
	jr	c, 36
	ldda8	c, 35326
	extz	bc
	.byte 0x8f, 0x06, 0x53
	extz	bc
	.byte 0x0b, 0x03, 0x00
	ld	de, (xsp+6)
	calr	-2127
	ldada	xde, 35213
	ld	xwa, (xsp+8)
	ld	xbc, 29360143
	call	16424280
	pop	xiz
	inc	8, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	e, c
	ld	(xsp+4), xwa
	ldda8	a, 35326
	extz	wa
	div8rr	a, e
	ld	c, w
	extz	bc
	cpdi8	35322, 0
	jr	nz, 63
	cps	bc, 4
	jr	nc, 59
	ldada	xwa, 35150
	ld	(xwa+63), 3
	lda	xiz, (xwa+64)
	ldda8	a, 35326
	extz	wa
	div8rr	a, e
	extz	wa
	call	16294549
	ld	xbc, xhl
	ld	xwa, xiz
	call	16290012
	ldada	xwa, 35214
	ldw	bc, 16
	calr	-6012
	ldada	xde, 35213
	ld	xwa, (xsp+4)
	ld	xbc, 29360143
	call	16424280
	pop	xiz
	inc	4, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	ld	xde, xbc
	ld	xiz, xwa
	ld8_24	c, 15337844
	cp	xde, 29360152
	jr	z, 51
	cp	xde, 29360151
	jr	z, 43
	cp	xde, 29360139
	jrl	nz, 447
	ld	xwa, xiz
	calr	-354
	ld8_24	c, 15337844
	ld	xwa, xiz
	calr	-483
	ld8_24	c, 15337844
	ld	xwa, xiz
	calr	-159
	lds32	xwa, 0
	stda32	33234, xwa
	jrl	408
	ldda8	l, 35326
	ld	xwa, (xsp+4)
	cp	xwa, 5
	jrl	nz, 142
	ld	xix, xde
	cp	xde, 29360151
	jr	nz, 43
	ld8_24	e, 15337844
	ld	a, e
	ld	c, l
	add	a, l
	.byte 0xc2, 0x76, 0x09, 0xea, 0xf1
	jr	nc, 25
	add	c, e
	stda8	35326, c
	ld8_24	c, 15337844
	ld	xwa, xiz
	calr	-562
	ld8_24	c, 15337844
	ld	xwa, xiz
	jr	42
	cp	xix, 29360152
	jr	nz, 42
	ld	a, l
	ld8_24	c, 15337844
	cp	l, c
	jr	c, 31
	sub	a, c
	stda8	35326, a
	ld8_24	c, 15337844
	ld	xwa, xiz
	calr	-606
	ld8_24	c, 15337844
	ld	xwa, xiz
	calr	-497
	stdi8	33238, 1
	ldda32	xwa, 33234
	.byte 0xaf, 0x04, 0xf0
	jrl	z, 284
	ldada	xde, 35171
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16424280
	ldada	xde, 35213
	ld	xwa, xiz
	ld	xbc, 29360143
	jrl	214
	ld	xwa, (xsp+4)
	cp	xwa, 6
	jrl	nz, 148
	ld	xix, xde
	cp	xde, 29360151
	jr	nz, 49
	ld	c, l
	ld	a, l
	inc	1, a
	.byte 0xc2, 0x76, 0x09, 0xea, 0xf1
	jr	nc, 36
	ld8_24	e, 15337844
	ld	l, e
	ld	a, c
	extz	wa
	div8rr	a, l
	ld	a, w
	inc	1, a
	cp	a, e
	jr	nc, 67
	inc	1, c
	stda8	35326, c
	ld8_24	c, 15337844
	ld	xwa, xiz
	jr	44
	cp	xix, 29360152
	jr	nz, 44
	ld	c, l
	cps	l, 0
	jr	z, 38
	ld8_24	e, 15337844
	ld	a, c
	extz	wa
	div8rr	a, e
	ld	a, w
	cps	a, 0
	jr	z, 21
	dec	1, c
	stda8	35326, c
	ld8_24	c, 15337844
	ld	xwa, xiz
	calr	-659
	stdi8	33238, 1
	ldda32	xwa, 33234
	.byte 0xaf, 0x04, 0xf0
	jr	z, 123
	ldada	xde, 35171
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16424280
	ldada	xde, 35213
	ld	xwa, xiz
	ld	xbc, 29360143
	jr	54
	ld	xwa, (xsp+4)
	cp	xwa, 7
	jr	z, 8
	cp	xwa, 8
	jr	nz, 48
	ldda32	xwa, 33234
	.byte 0xaf, 0x04, 0xf0
	jr	z, 67
	ldada	xde, 35171
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16424280
	ldada	xde, 35213
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16424280
	ld	xwa, (xsp+4)
	stda32	33234, xwa
	jr	28
	ld	xwa, (xsp+4)
	cp	xwa, 40
	jr	nz, 17
	cpdi8	33238, 0
	jr	z, 10
	ld	xwa, xiz
	calr	-576
	stdi8	33238, 0
	lds32	xhl, 0
	pop	xiz
	inc	4, xsp
	ret
	ld	xix, (xsp+4)
	ld	l, c
	add	l, c
	cp	(xde), l
	jr	nc, 4
	cp	(xix), l
	jr	c, 74
	cp	(xde), l
	jr	c, 4
	cp	(xix), l
	jr	nc, 66
	cp	xwa, 8
	jr	z, 42
	cp	xwa, 7
	jr	z, 34
	cp	xwa, 6
	jr	z, 8
	cp	xwa, 5
	jr	nz, 34
	ld	a, (xde)
	ld	(xix), a
	lds32	xwa, 0
	ld	xbc, 29360143
	lds32	xde, 0
	calr	5221
	jr	16
	ld	a, (xix)
	ld	(xde), a
	lds32	xwa, 0
	ld	xbc, 29360139
	lds32	xde, 0
	calr	1335
	retd	0x0004
	dec	6, xsp
	ld	(xsp), c
	ld	(xsp+2), xwa
	ldada	xwa, 35150
	.byte 0xf5, 0xe0, 0x00, 0x00
	ldda8	c, 35320
	extz	bc
	.byte 0xd9, 0xec, 0x02
	lda_24	xde, 15336946
	.byte 0xe3, 0x07, 0xe8, 0xe4, 0x21
	inc	1, xbc
	call	16290012
	ldada	xwa, 35151
	ld	xbc, 15337848
	call	16290067
	ldada	xwa, 35151
	ldw	bc, 16
	calr	-6680
	ld	xwa, (xsp+2)
	ld	xbc, 29360143
	ld	xde, 35150
	call	16424280
	ld	a, (xsp)
	.byte 0x87, 0x81
	ldda8	c, 35328
	cp	c, a
	jr	nc, 31
	ldada	xwa, 35171
	extz	bc
	.byte 0x87, 0x53
	extz	bc
	lds	de, 1
	calr	-2853
	ldada	xde, 35171
	ld	xwa, (xsp+2)
	ld	xbc, 29360143
	call	16424280
	inc	6, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xwa
	ld	a, c
	add	a, c
	cpdm8	35328, a
	jr	c, 49
	ldada	xwa, 35150
	ld	(xwa+21), 1
	lda	xiz, (xwa+22)
	call	16294804
	ld	xbc, xhl
	ld	xwa, xiz
	call	16290012
	ldada	xwa, 35172
	ldw	bc, 16
	calr	-6792
	ldada	xde, 35171
	ld	xwa, (xsp+4)
	ld	xbc, 29360143
	call	16424280
	pop	xiz
	inc	4, xsp
	ret
	dec	6, xsp
	push	xiz
	ld	(xsp+4), c
	ld	(xsp+6), xwa
	ldada	xwa, 35150
	ld	(xwa+42), 2
	lda	xwa, (xwa+43)
	ldda8	c, 35320
	extz	bc
	.byte 0xd9, 0xec, 0x02
	lda_24	xde, 15336996
	.byte 0xe3, 0x07, 0xe8, 0xe4, 0x21
	inc	1, xbc
	call	16290012
	ldada	xwa, 35193
	ld	xbc, 15337852
	call	16290067
	cpdi8	35322, 0
	jr	nz, 65
	ld	e, (xsp+4)
	.byte 0x8f, 0x04, 0x85
	ldda8	c, 35328
	ldada	xwa, 35193
	cp	c, e
	jr	c, 21
	ld	xiz, xwa
	sub	c, e
	inc	1, c
	extz	bc
	ld	wa, bc
	lds	bc, 0
	calr	-17429
	ld	xbc, xhl
	ld	xwa, xiz
	jr	22
	ld	xiz, xwa
	extz	bc
	.byte 0x8f, 0x04, 0x53
	ld	a, b
	inc	1, a
	extz	wa
	lds	bc, 0
	calr	-17453
	ld	xbc, xhl
	ld	xwa, xiz
	call	16290067
	ldada	xwa, 35193
	ldw	bc, 16
	calr	-6952
	ldada	xde, 35192
	ld	xwa, (xsp+6)
	ld	xbc, 29360143
	call	16424280
	cpdi8	35322, 0
	jr	z, 36
	ldada	xwa, 35150
	ld	(xwa+63), 3
	lda	xwa, (xwa+64)
	.byte 0x41
	.long Str_AllOption_EA0980
	call	16290012
	ldada	xde, 35213
	ld	xwa, (xsp+6)
	ld	xbc, 29360143
	call	16424280
	pop	xiz
	inc	6, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xwa
	cpdi8	35322, 0
	jr	nz, 77
	ldada	xwa, 35150
	ld	(xwa+63), 3
	ld	e, c
	add	e, c
	lda	xiz, (xwa+64)
	ldda8	a, 35328
	cp	a, e
	jr	c, 14
	sub	a, e
	extz	wa
	call	16294916
	ld	xbc, xhl
	ld	xwa, xiz
	jr	10
	extz	wa
	call	16294681
	ld	xbc, xhl
	ld	xwa, xiz
	call	16290012
	ldada	xwa, 35214
	ldw	bc, 16
	calr	-7089
	ldada	xde, 35213
	ld	xwa, (xsp+4)
	ld	xbc, 29360143
	call	16424280
	pop	xiz
	inc	4, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	ld	xiz, xwa
	ld8_24	e, 15337874
	cp	xbc, 29360152
	jr	z, 73
	cp	xbc, 29360151
	jr	z, 65
	cp	xbc, 29360139
	jrl	nz, 704
	ld	xwa, xiz
	ld	c, e
	calr	-537
	ld8_24	c, 15337874
	ld	xwa, xiz
	calr	-352
	ld8_24	c, 15337874
	ld	xwa, xiz
	calr	-431
	ld8_24	c, 15337874
	ld	xwa, xiz
	calr	-169
	lds32	xwa, 0
	stda32	33240, xwa
	stdi8	33244, 0
	stdi8	33246, 0
	jrl	648
	ldda8	l, 35328
	ld	xwa, (xsp+4)
	cp	xwa, 5
	jrl	nz, 212
	ld	xde, xbc
	cp	xbc, 29360151
	jr	nz, 72
	ld8_24	c, 15337874
	ld	w, c
	add	w, c
	ld	a, l
	cp	l, w
	jr	nc, 57
	cp	a, c
	jr	nc, 8
	add	a, c
	stda8	35328, a
	jr	4
	stda8	35328, w
	ld8_24	c, 15337874
	ld	xwa, xiz
	calr	-653
	ld8_24	c, 15337874
	ld	xwa, xiz
	calr	-468
	ld8_24	c, 15337874
	.byte 0x0b, 0x00, 0x00, 0x0b, 0x08, 0x8a
	ld	xwa, (xsp+8)
	ld	xde, 35328
	jr	78
	cp	xde, 29360152
	jr	nz, 83
	ld	c, l
	ld8_24	e, 15337874
	cp	l, e
	jr	c, 72
	ld	a, e
	add	a, e
	cp	c, a
	jr	nc, 8
	sub	c, e
	stda8	35328, c
	jr	4
	stda8	35328, e
	ld8_24	c, 15337874
	ld	xwa, xiz
	calr	-733
	ld8_24	c, 15337874
	ld	xwa, xiz
	calr	-548
	ld8_24	c, 15337874
	.byte 0x0b, 0x00, 0x00, 0x0b, 0x08, 0x8a
	ld	xwa, (xsp+8)
	ld	xde, 35328
	calr	-857
	stdi8	33246, 1
	stdi8	33244, 1
	ldda32	xwa, 33240
	.byte 0xaf, 0x04, 0xf0
	jrl	z, 449
	ldada	xde, 35171
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16424280
	ldada	xde, 35213
	ld	xwa, xiz
	ld	xbc, 29360143
	jrl	355
	ld	xwa, (xsp+4)
	cp	xwa, 6
	jrl	nz, 289
	ld	xde, xbc
	cp	xbc, 29360151
	jr	nz, 118
	ld	c, l
	ld	a, l
	inc	1, a
	.byte 0xc2, 0x94, 0x09, 0xea, 0xf1
	jr	nc, 105
	ld8_24	e, 15337874
	ld	a, e
	add	a, e
	cp	c, a
	jr	nc, 55
	ld	l, e
	ld	a, c
	extz	wa
	div8rr	a, l
	ld	a, w
	inc	1, a
	cp	a, e
	jrl	nc, 198
	inc	1, c
	stda8	35328, c
	ld8_24	c, 15337874
	ld	xwa, xiz
	calr	-700
	ld8_24	c, 15337874
	.byte 0x0b, 0x00, 0x00, 0x0b, 0x08, 0x8a
	ld	xwa, (xsp+8)
	ld	xde, 35328
	jrl	152
	inc	1, c
	stda8	35328, c
	ld8_24	c, 15337874
	ld	xwa, xiz
	calr	-738
	ld8_24	c, 15337874
	.byte 0x0b, 0x00, 0x00, 0x0b, 0x08, 0x8a
	ld	xwa, (xsp+8)
	ld	xde, 35328
	jr	115
	cp	xde, 29360152
	jr	nz, 115
	ld	c, l
	cps	l, 0
	jr	z, 109
	ld8_24	e, 15337874
	ld	a, e
	add	a, e
	cp	c, a
	jr	nc, 49
	ld	a, c
	extz	wa
	div8rr	a, e
	ld	a, w
	cps	a, 0
	jr	z, 84
	dec	1, c
	stda8	35328, c
	ld8_24	c, 15337874
	ld	xwa, xiz
	calr	-814
	ld8_24	c, 15337874
	.byte 0x0b, 0x00, 0x00, 0x0b, 0x08, 0x8a
	ld	xwa, (xsp+8)
	ld	xde, 35328
	jr	39
	cp	c, a
	jr	ule, 43
	dec	1, c
	stda8	35328, c
	ld8_24	c, 15337874
	ld	xwa, xiz
	calr	-855
	ld8_24	c, 15337874
	.byte 0x0b, 0x00, 0x00, 0x0b, 0x08, 0x8a
	ld	xwa, (xsp+8)
	ld	xde, 35328
	calr	-1164
	stdi8	33244, 1
	ldda32	xwa, 33240
	.byte 0xaf, 0x04, 0xf0
	jrl	z, 147
	ldada	xde, 35171
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16424280
	ldada	xde, 35213
	ld	xwa, xiz
	ld	xbc, 29360143
	jr	54
	ld	xwa, (xsp+4)
	cp	xwa, 7
	jr	z, 8
	cp	xwa, 8
	jr	nz, 48
	ldda32	xwa, 33240
	.byte 0xaf, 0x04, 0xf0
	jr	z, 91
	ldada	xde, 35171
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16424280
	ldada	xde, 35213
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16424280
	ld	xwa, (xsp+4)
	stda32	33240, xwa
	jr	52
	ld	xwa, (xsp+4)
	cp	xwa, 40
	jr	nz, 41
	cpdi8	33246, 0
	jr	z, 12
	ld	xwa, xiz
	ld	c, e
	calr	-1081
	stdi8	33246, 0
	cpdi8	33244, 0
	jr	z, 15
	ld8_24	c, 15337874
	ld	xwa, xiz
	calr	-831
	stdi8	33244, 0
	lds32	xhl, 0
	pop	xiz
	inc	4, xsp
	ret
	dec	4, xsp
	pushw	iz
	ld	(xsp+2), xwa
	cp	xbc, 29360139
	jr	nz, 72
	lds	iz, 0
	ld	de, iz
	mul	de, 21
	ldada	xbc, 35150
	ld	hl, de
	extz	xhl
	add	xhl, xbc
	.byte 0xc7, 0xf8, 0x89
	ld	(xhl), a
	lds	wa, 1
	add	wa, de
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 0
	ldw	bc, 16
	calr	-7911
	ld	de, iz
	mul	de, 21
	ldada	xwa, 35150
	extz	xde
	add	xde, xwa
	ld	xwa, (xsp+2)
	ld	xbc, 29360143
	call	16424280
	inc	1, iz
	cps	iz, 4
	jr	c, -70
	lds32	xhl, 0
	popw	iz
	inc	4, xsp
	ret

SingleLoadSrcFunc:
	dec 4, xsp
	push xiz
	ld xiz, xde
	ld (xsp + 4), xbc
	ld xwa, (xsp + 4)
	cp xwa, 0x1E50003
	jrl z, SLSrc_ReturnCapture
	cp xwa, 0x1C00018
	jr z, SLSrc_HandleScroll
	cp xwa, 0x1C00017
	jr z, SLSrc_HandleScroll
	cp xwa, 0x1C0000B
	jr z, SLSrc_HandleShow
	cp xwa, 0x1E50004
	jrl nz, SLSrc_Return
	ld xwa, xiz
	stda32 33248, xwa
	ld xbc, 0x1E50002
	ld xde, 0xFFFFFFFF
	call ApPostEvent
	jrl SLSrc_Return

SLSrc_HandleShow:
	ldda32 xwa, 33248
	ld xbc, 0x1E50002
	ld xde, 0xFFFFFFFF
	call ApPostEvent
	ldda32 xwa, 33248
	ldda8 c, 35320
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0996
	st_dri3b C, 0x07, 0xE8, 0xE4
	ld xbc, (xsp + 4)
	ld xde, xiz
	ld xhl, (xhl)
	call (xhl)
	calr SignalProgressUpdate
	jrl SLSrc_Return

SLSrc_HandleScroll:
	cp xiz, 0x5
	jr nz, SLSrc_ScrollMode6
	cpdi8 35320, 1
	jr z, SLSrc_ScrollMode5_Prev
	ldda32 xwa, 33248
	ld xbc, 0x1E50002
	lds32 xde, 1
	jr SLSrc_ScrollMode5_Dispatch

SLSrc_ScrollMode5_Prev:
	ldda32 xwa, 33248
	ld xbc, 0x1E50002
	ld xde, 0xFFFFFFFF

SLSrc_ScrollMode5_Dispatch:
	call ApPostEvent
	ldda32 xwa, 33248
	ldda8 c, 35320
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0996
	st_dri3b C, 0x07, 0xE8, 0xE4
	ld xbc, (xsp + 4)
	ld xde, xiz
	ld xhl, (xhl)
	call (xhl)
	jrl SLSrc_Return

SLSrc_ScrollMode6:
	cp xiz, 0x6
	jr nz, SLSrc_ScrollMode7
	cpdi8 35320, 1
	jr z, SLSrc_ScrollMode6_NoStep
	cpdi8 35322, 0
	jr nz, SLSrc_ScrollMode6_NoStep
	ldda32 xwa, 33248
	ld xbc, 0x1E50002
	lds32 xde, 3
	jr SLSrc_ScrollMode6_Dispatch

SLSrc_ScrollMode6_NoStep:
	ldda32 xwa, 33248
	ld xbc, 0x1E50002
	ld xde, 0xFFFFFFFF

SLSrc_ScrollMode6_Dispatch:
	call ApPostEvent
	ldda32 xwa, 33248
	ldda8 c, 35320
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0996
	st_dri3b C, 0x07, 0xE8, 0xE4
	ld xbc, (xsp + 4)
	ld xde, xiz
	ld xhl, (xhl)
	call (xhl)
	jrl SLSrc_Return

SLSrc_ScrollMode7:
	ldda32 xwa, 33248
	cp xiz, 0x7
	jr nz, SLSrc_ScrollMode8
	ld xbc, 0x1E50002
	ld xde, 0xFFFFFFFF
	call ApPostEvent
	ldda32 xwa, 33248
	ldda8 c, 35320
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0996
	st_dri3b C, 0x07, 0xE8, 0xE4
	ld xbc, (xsp + 4)
	ld xde, xiz
	ld xhl, (xhl)
	call (xhl)
	jr SLSrc_Return

SLSrc_ScrollMode8:
	cp xiz, 0x8
	jr nz, SLSrc_ScrollMode40
	ld xbc, 0x1E50002
	ld xde, 0xFFFFFFFF
	call ApPostEvent
	ldda32 xwa, 33248
	ldda8 c, 35320
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0996
	st_dri3b C, 0x07, 0xE8, 0xE4
	ld xbc, (xsp + 4)
	ld xde, xiz
	ld xhl, (xhl)
	call (xhl)
	jr SLSrc_Return

SLSrc_ScrollMode40:
	cp xiz, 0x28
	jr nz, SLSrc_Return
	ldda8 c, 35320
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0996
	st_dri3b C, 0x07, 0xE8, 0xE4
	ld xbc, (xsp + 4)
	ld xde, xiz
	ld xhl, (xhl)
	call (xhl)

SLSrc_Return:
	lds32 xhl, 0
	jr SLSrc_Epilogue

SLSrc_ReturnCapture:
	ld xhl, 0xFFFFFFFF

SLSrc_Epilogue:
	pop xiz
	inc 4, xsp
	ret

SLDstBankList_FuncBody:
	dec	6, xsp
	push	xiz
	ld	(xsp+4), c
	ld	(xsp+6), xwa
	ldada	xwa, 35234
	.byte 0xf5, 0xe0, 0x00, 0x00
	ldda8	c, 35320
	extz	bc
	.byte 0xd9, 0xec, 0x02
	lda_24	xde, 15336946
	.byte 0xe3, 0x07, 0xe8, 0xe4, 0x21
	inc	1, xbc
	call	16290012
	ldada	xwa, 35235
	ld	xbc, 15337898
	call	16290067
	ldada	xiz, 35235
	ldda8	a, 35330
	extz	wa
	.byte 0x8f, 0x04, 0x51
	inc	1, a
	extz	wa
	lds	bc, 0
	calr	-19011
	ld	xbc, xhl
	ld	xwa, xiz
	call	16290067
	ldada	xwa, 35235
	ldw	bc, 16
	calr	-8510
	ldada	xwa, 35255
	ldda8	c, 35330
	extz	bc
	.byte 0x8f, 0x04, 0x53
	extz	bc
	lds	de, 1
	calr	-4886
	ldada	xwa, 35256
	ldw	bc, 16
	calr	-8540
	ld	xwa, (xsp+6)
	ld	xbc, 29360143
	ld	xde, 35234
	call	16424280
	ldada	xde, 35255
	ld	xwa, (xsp+6)
	ld	xbc, 29360143
	call	16424280
	pop	xiz
	inc	6, xsp
	ret
	dec	6, xsp
	push	xiz
	ld	(xsp+4), c
	ld	(xsp+6), xwa
	ldada	xde, 35234
	ld	(xde+42), 2
	ld	(xde+63), 3
	ldda8	a, 35320
	extz	wa
	lda_24	xhl, 15336996
	ld	bc, wa
	.byte 0xd9, 0xec, 0x02
	lda	xwa, (xde+43)
	.byte 0xe3, 0x07, 0xec, 0xe4, 0x21
	inc	1, xbc
	cpdi8	35322, 0
	jr	z, 42
	call	16290012
	ldada	xwa, 35277
	ld	xbc, 15337902
	call	16290067
	ldada	xwa, 35277
	ldw	bc, 16
	calr	-8658
	ldada	xwa, 35298
	.byte 0x41
	.long Str_AllOption_EA09B2
	call	16290012
	jr	74
	call	16290012
	ldada	xwa, 35277
	ld	xbc, 15337924
	call	16290067
	ldada	xiz, 35277
	ldda8	a, 35330
	extz	wa
	.byte 0x8f, 0x04, 0x51
	ld	a, w
	inc	1, a
	extz	wa
	lds	bc, 0
	calr	-19233
	ld	xbc, xhl
	ld	xwa, xiz
	call	16290067
	ldada	xwa, 35277
	ldw	bc, 16
	calr	-8732
	ldada	xwa, 35297
	ldda8	c, 35330
	extz	bc
	lds	de, 3
	calr	-5057
	ldada	xde, 35276
	ld	xwa, (xsp+6)
	ld	xbc, 29360143
	call	16424280
	ldada	xde, 35297
	ld	xwa, (xsp+6)
	ld	xbc, 29360143
	call	16424280
	pop	xiz
	inc	6, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	ld	xde, xbc
	ld	xiz, xwa
	ld8_24	c, 15337928
	cp	xde, 29360152
	jr	z, 41
	cp	xde, 29360151
	jr	z, 33
	cp	xde, 29360139
	jrl	nz, 184
	ld	xwa, xiz
	calr	-413
	ld8_24	c, 15337928
	ld	xwa, xiz
	calr	-261
	lds32	xwa, 0
	stda32	33252, xwa
	jrl	160
	ldda8	l, 35330
	ld	xwa, (xsp+4)
	cp	xwa, 7
	jrl	nz, 149
	ld	xix, xde
	cp	xde, 29360151
	jr	nz, 43
	ld8_24	e, 15337928
	ld	a, e
	ld	c, l
	add	a, l
	.byte 0xc2, 0xca, 0x09, 0xea, 0xf1
	jr	nc, 25
	add	c, e
	stda8	35330, c
	ld8_24	c, 15337928
	ld	xwa, xiz
	calr	-492
	ld8_24	c, 15337928
	ld	xwa, xiz
	jr	42
	cp	xix, 29360152
	jr	nz, 37
	ld	a, l
	ld8_24	c, 15337928
	cp	l, c
	jr	c, 26
	sub	a, c
	stda8	35330, a
	ld8_24	c, 15337928
	ld	xwa, xiz
	calr	-536
	ld8_24	c, 15337928
	ld	xwa, xiz
	calr	-384
	ldda32	xwa, 33252
	.byte 0xaf, 0x04, 0xf0
	jr	z, 37
	ldada	xde, 35255
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16424280
	ldada	xde, 35297
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16424280
	ld	xwa, (xsp+4)
	stda32	33252, xwa
	lds32	xhl, 0
	jrl	282
	ld	xwa, (xsp+4)
	cp	xwa, 8
	jrl	nz, 145
	ld	xix, xde
	cp	xde, 29360151
	jr	nz, 49
	ld	c, l
	ld	a, l
	inc	1, a
	.byte 0xc2, 0xca, 0x09, 0xea, 0xf1
	jr	nc, 36
	ld8_24	e, 15337928
	ld	l, e
	ld	a, c
	extz	wa
	div8rr	a, l
	ld	a, w
	inc	1, a
	cp	a, e
	jr	nc, 62
	inc	1, c
	stda8	35330, c
	ld8_24	c, 15337928
	ld	xwa, xiz
	jr	44
	cp	xix, 29360152
	jr	nz, 39
	ld	c, l
	cps	l, 0
	jr	z, 33
	ld8_24	e, 15337928
	ld	a, c
	extz	wa
	div8rr	a, e
	ld	a, w
	cps	a, 0
	jr	z, 16
	dec	1, c
	stda8	35330, c
	ld8_24	c, 15337928
	ld	xwa, xiz
	calr	-553
	ldda32	xwa, 33252
	.byte 0xaf, 0x04, 0xf0
	jrl	z, -133
	ldada	xde, 35255
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16424280
	ldada	xde, 35297
	ld	xwa, xiz
	ld	xbc, 29360143
	jrl	-173
	ld	xwa, (xsp+4)
	cp	xwa, 5
	jr	z, 8
	cp	xwa, 6
	jr	nz, 39
	ldda32	xwa, 33252
	.byte 0xaf, 0x04, 0xf0
	jrl	z, -191
	ldada	xde, 35255
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16424280
	ldada	xde, 35297
	ld	xwa, xiz
	ld	xbc, 29360143
	jrl	-231
	ld	xwa, (xsp+4)
	cp	xwa, 10
	jrl	nz, -232
	cpdi8	35322, 0
	jr	z, 30
	ldda8	a, 35324
	extz	wa
	div8rr	a, c
	extz	wa
	ldda8	e, 35330
	extz	de
	div8rr	e, c
	extz	de
	ld	bc, de
	call	16286294
	exts	xhl
	jr	18
	ldda8	a, 35324
	extz	wa
	ldda8	c, 35330
	extz	bc
	call	16286078
	exts	xhl
	pop	xiz
	inc	4, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xwa
	ldada	xwa, 35234
	ld	(xwa+21), 1
	lda	xwa, (xwa+22)
	ldda8	c, 35320
	extz	bc
	.byte 0xd9, 0xec, 0x02
	lda_24	xde, 15336996
	.byte 0xe3, 0x07, 0xe8, 0xe4, 0x21
	inc	1, xbc
	call	16290012
	ldada	xwa, 35256
	ld	xbc, 15337932
	call	16290067
	ldada	xiz, 35256
	ldda8	a, 35332
	inc	1, a
	extz	wa
	lds	bc, 0
	calr	-19889
	ld	xbc, xhl
	ld	xwa, xiz
	call	16290067
	ldada	xwa, 35256
	ldw	bc, 16
	calr	-9388
	ldada	xiz, 35276
	ldda8	a, 35332
	extz	wa
	lds	bc, 2
	lds	de, 0
	calr	5520
	ld	xbc, xhl
	ld	xwa, xiz
	call	16290012
	ldada	xde, 35255
	ld	xwa, (xsp+4)
	ld	xbc, 29360143
	call	16424280
	ldada	xde, 35276
	ld	xwa, (xsp+4)
	ld	xbc, 29360143
	call	16424280
	pop	xiz
	inc	4, xsp
	ret
	push	xiz
	ld	xiz, xwa
	cp	xbc, 29360152
	jr	z, 88
	cp	xbc, 29360151
	jr	z, 80
	cp	xbc, 29360139
	jr	nz, 122
	ldada	xwa, 35234
	.byte 0xf5, 0xe0, 0x00, 0x00
	ld	(xwa), 0
	ldw	bc, 16
	calr	-9493
	ldada	xwa, 35234
	ld	(xwa+63), 3
	lda	xwa, (xwa+64)
	ld	(xwa), 0
	ldw	bc, 16
	calr	-9513
	ld	xwa, xiz
	ld	xbc, 29360143
	ld	xde, 35234
	call	16424280
	ldada	xde, 35297
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16424280
	ld	xwa, xiz
	jr	47
	ldda8	w, 35332
	ldada	xhl, 35276
	cp	xde, 8
	jr	nz, 73
	ld	xde, xbc
	cp	xde, 29360151
	jr	nz, 28
	ld	c, w
	ld	a, w
	inc	1, a
	.byte 0xc2, 0xd0, 0x09, 0xea, 0xf1
	jr	nc, 15
	inc	1, c
	stda8	35332, c
	ld	xwa, xiz
	calr	-300
	lds32	xhl, 0
	jr	86
	cp	xde, 29360152
	jr	nz, 16
	ld	a, w
	cps	w, 0
	jr	z, 10
	dec	1, a
	stda8	35332, a
	ld	xwa, xiz
	jr	-31
	ld	xwa, xiz
	ld	xbc, 29360143
	ld	xde, xhl
	jr	25
	cp	xde, 5
	jr	c, 23
	cp	xde, 7
	jr	ugt, 15
	ld	xwa, xiz
	ld	xbc, 29360143
	ld	xde, xhl
	call	16424280
	jr	-70
	cp	xde, 10
	jr	nz, -78
	ldda8	a, 35332
	extz	wa
	call	16286582
	exts	xhl
	pop	xiz
	ret
	dec	2, xsp
	push	xiz
	ld	(xsp+4), c
	ld	xiz, xwa
	ldada	xwa, 35234
	.byte 0xf5, 0xe0, 0x00, 0x00
	ldda8	c, 35320
	extz	bc
	.byte 0xd9, 0xec, 0x02
	lda_24	xde, 15336946
	.byte 0xe3, 0x07, 0xe8, 0xe4, 0x21
	inc	1, xbc
	call	16290012
	ldada	xwa, 35235
	ld	xbc, 15337938
	call	16290067
	ldada	xwa, 35235
	ldw	bc, 16
	calr	-9754
	ldada	xwa, 35255
	ldda8	c, 35334
	extz	bc
	.byte 0x8f, 0x04, 0x53
	extz	bc
	lds	de, 1
	calr	-6036
	ld	xwa, xiz
	ld	xbc, 29360143
	ld	xde, 35234
	call	16424280
	ldada	xde, 35255
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16424280
	pop	xiz
	inc	2, xsp
	ret
	dec	6, xsp
	push	xiz
	ld	(xsp+4), c
	ld	(xsp+6), xwa
	ldada	xwa, 35234
	ld	(xwa+42), 2
	lda	xwa, (xwa+43)
	ldda8	c, 35320
	extz	bc
	.byte 0xd9, 0xec, 0x02
	lda_24	xde, 15336996
	.byte 0xe3, 0x07, 0xe8, 0xe4, 0x21
	inc	1, xbc
	call	16290012
	ldada	xwa, 35277
	ld	xbc, 15337942
	call	16290067
	cpdi8	35322, 0
	jr	nz, 28
	ldada	xiz, 35277
	ldda8	a, 35334
	extz	wa
	.byte 0x8f, 0x04, 0x51
	ld	a, w
	extz	wa
	calr	-6118
	ld	xbc, xhl
	ld	xwa, xiz
	call	16290067
	ldada	xwa, 35277
	ldw	bc, 16
	calr	-9912
	ldada	xbc, 35234
	lda	xwa, (xbc+63)
	cpdi8	35322, 0
	jr	z, 17
	ld	(xwa), 3
	lda	xwa, (xbc+64)
	ld	xbc, 15337946
	call	16290012
	jr	28
	ldda8	e, 35334
	ld	c, e
	extz	bc
	.byte 0x8f, 0x04, 0x53
	extz	bc
	extz	de
	.byte 0x8f, 0x04, 0x55
	ld	e, d
	extz	de
	.byte 0x0b, 0x03, 0x00
	calr	-6180
	ldada	xde, 35276
	ld	xwa, (xsp+6)
	ld	xbc, 29360143
	call	16424280
	ldada	xde, 35297
	ld	xwa, (xsp+6)
	ld	xbc, 29360143
	call	16424280
	pop	xiz
	inc	6, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	ld	xde, xbc
	ld	xiz, xwa
	ld8_24	c, 15337964
	cp	xde, 29360152
	jr	z, 41
	cp	xde, 29360151
	jr	z, 33
	cp	xde, 29360139
	jrl	nz, 184
	ld	xwa, xiz
	calr	-362
	ld8_24	c, 15337964
	ld	xwa, xiz
	calr	-253
	lds32	xwa, 0
	stda32	33256, xwa
	jrl	160
	ldda8	l, 35334
	ld	xwa, (xsp+4)
	cp	xwa, 7
	jrl	nz, 149
	ld	xix, xde
	cp	xde, 29360151
	jr	nz, 43
	ld8_24	e, 15337964
	ld	a, e
	ld	c, l
	add	a, l
	.byte 0xc2, 0xee, 0x09, 0xea, 0xf1
	jr	nc, 25
	add	c, e
	stda8	35334, c
	ld8_24	c, 15337964
	ld	xwa, xiz
	calr	-441
	ld8_24	c, 15337964
	ld	xwa, xiz
	jr	42
	cp	xix, 29360152
	jr	nz, 37
	ld	a, l
	ld8_24	c, 15337964
	cp	l, c
	jr	c, 26
	sub	a, c
	stda8	35334, a
	ld8_24	c, 15337964
	ld	xwa, xiz
	calr	-485
	ld8_24	c, 15337964
	ld	xwa, xiz
	calr	-376
	ldda32	xwa, 33256
	.byte 0xaf, 0x04, 0xf0
	jr	z, 37
	ldada	xde, 35255
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16424280
	ldada	xde, 35297
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16424280
	ld	xwa, (xsp+4)
	stda32	33256, xwa
	lds32	xhl, 0
	jrl	282
	ld	xwa, (xsp+4)
	cp	xwa, 8
	jrl	nz, 145
	ld	xix, xde
	cp	xde, 29360151
	jr	nz, 49
	ld	c, l
	ld	a, l
	inc	1, a
	.byte 0xc2, 0xee, 0x09, 0xea, 0xf1
	jr	nc, 36
	ld8_24	e, 15337964
	ld	l, e
	ld	a, c
	extz	wa
	div8rr	a, l
	ld	a, w
	inc	1, a
	cp	a, e
	jr	nc, 62
	inc	1, c
	stda8	35334, c
	ld8_24	c, 15337964
	ld	xwa, xiz
	jr	44
	cp	xix, 29360152
	jr	nz, 39
	ld	c, l
	cps	l, 0
	jr	z, 33
	ld8_24	e, 15337964
	ld	a, c
	extz	wa
	div8rr	a, e
	ld	a, w
	cps	a, 0
	jr	z, 16
	dec	1, c
	stda8	35334, c
	ld8_24	c, 15337964
	ld	xwa, xiz
	calr	-545
	ldda32	xwa, 33256
	.byte 0xaf, 0x04, 0xf0
	jrl	z, -133
	ldada	xde, 35255
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16424280
	ldada	xde, 35297
	ld	xwa, xiz
	ld	xbc, 29360143
	jrl	-173
	ld	xwa, (xsp+4)
	cp	xwa, 5
	jr	z, 8
	cp	xwa, 6
	jr	nz, 39
	ldda32	xwa, 33256
	.byte 0xaf, 0x04, 0xf0
	jrl	z, -191
	ldada	xde, 35255
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16424280
	ldada	xde, 35297
	ld	xwa, xiz
	ld	xbc, 29360143
	jrl	-231
	ld	xwa, (xsp+4)
	cp	xwa, 10
	jrl	nz, -232
	cpdi8	35322, 0
	jr	z, 30
	ldda8	a, 35326
	extz	wa
	div8rr	a, c
	add	a, 30
	extz	wa
	ldda8	e, 35334
	extz	de
	div8rr	e, c
	add	e, 30
	extz	de
	ld	bc, de
	jr	12
	ldda8	a, 35326
	extz	wa
	ldda8	c, 35334
	extz	bc
	call	16286812
	exts	xhl
	pop	xiz
	inc	4, xsp
	ret
	dec	6, xsp
	ld	(xsp), c
	ld	(xsp+2), xwa
	ldada	xwa, 35234
	.byte 0xf5, 0xe0, 0x00, 0x00
	ldda8	c, 35320
	extz	bc
	.byte 0xd9, 0xec, 0x02
	lda_24	xde, 15336946
	.byte 0xe3, 0x07, 0xe8, 0xe4, 0x21
	inc	1, xbc
	call	16290012
	ldada	xwa, 35235
	.byte 0x41
	.long Data_SaveLoadMenuTable
	call	16290067
	ldada	xwa, 35235
	ldw	bc, 16
	calr	-10585
	ld	e, (xsp)
	.byte 0x87, 0x85
	ldda8	c, 35336
	ldada	xwa, 35255
	cp	c, e
	jr	nc, 13
	extz	bc
	.byte 0x87, 0x53
	extz	bc
	lds	de, 1
	calr	-6741
	jr	5
	lds	bc, 1
	calr	-6665
	ld	xwa, (xsp+2)
	ld	xbc, 29360143
	ld	xde, 35234
	call	16424280
	ldada	xde, 35255
	ld	xwa, (xsp+2)
	ld	xbc, 29360143
	call	16424280
	inc	6, xsp
	ret
	dec	6, xsp
	push	xiz
	ld	(xsp+4), c
	ld	(xsp+6), xwa
	lda_24	xde, 15336996
	cpdi8	35322, 0
	jr	z, 77
	ldada	xwa, 35234
	ld	(xwa+42), 2
	lda	xwa, (xwa+43)
	ldda8	c, 35320
	extz	bc
	.byte 0xd9, 0xec, 0x02, 0xe3, 0x07, 0xe8, 0xe4, 0x21
	inc	1, xbc
	call	16290012
	ldada	xwa, 35277
	ld	xbc, 15337972
	call	16290067
	ldada	xwa, 35277
	ldw	bc, 16
	calr	-10730
	ldada	xwa, 35234
	ld	(xwa+63), 3
	lda	xwa, (xwa+64)
	ld	xbc, 15337976
	call	16290012
	jrl	214
	ld	l, (xsp+4)
	.byte 0x8f, 0x04, 0x87
	ldada	xbc, 35234
	lda	xwa, (xbc+43)
	ld	(xbc+42), 2
	cpdm8	35336, l
	jr	c, 101
	ldda8	c, 35320
	extz	bc
	.byte 0xd9, 0xec, 0x02, 0xe3, 0x07, 0xe8, 0xe4, 0x21
	inc	1, xbc
	call	16290012
	ldada	xwa, 35277
	ld	xbc, 15337994
	call	16290067
	ldada	xiz, 35277
	ld	c, (xsp+4)
	.byte 0x8f, 0x04, 0x83
	ldda8	a, 35336
	sub	a, c
	inc	1, a
	extz	wa
	lds	bc, 0
	calr	-21353
	ld	xbc, xhl
	ld	xwa, xiz
	call	16290067
	ldada	xwa, 35277
	ldw	bc, 16
	calr	-10852
	ldada	xwa, 35297
	ld	e, (xsp+4)
	.byte 0x8f, 0x04, 0x85
	ldda8	c, 35336
	sub	c, e
	extz	bc
	lds	de, 3
	calr	-6885
	jr	90
	ldda8	c, 35320
	extz	bc
	.byte 0xd9, 0xec, 0x02, 0xe3, 0x07, 0xe8, 0xe4, 0x21
	inc	1, xbc
	call	16290012
	ldada	xwa, 35277
	ld	xbc, 15337998
	call	16290067
	ldada	xiz, 35277
	ldda8	a, 35336
	extz	wa
	.byte 0x8f, 0x04, 0x51
	ld	a, w
	inc	1, a
	extz	wa
	lds	bc, 0
	calr	-21453
	ld	xbc, xhl
	ld	xwa, xiz
	call	16290067
	ldada	xwa, 35277
	ldw	bc, 16
	calr	-10952
	ldada	xwa, 35297
	ldda8	c, 35336
	extz	bc
	lds	de, 3
	calr	-7058
	ldada	xde, 35276
	ld	xwa, (xsp+6)
	ld	xbc, 29360143
	call	16424280
	ldada	xde, 35297
	ld	xwa, (xsp+6)
	ld	xbc, 29360143
	call	16424280
	pop	xiz
	inc	6, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	ld	xiz, xwa
	ld8_24	e, 15338002
	cp	xbc, 29360152
	jr	z, 43
	cp	xbc, 29360151
	jr	z, 35
	cp	xbc, 29360139
	jrl	nz, 255
	ld	xwa, xiz
	ld	c, e
	calr	-526
	ld8_24	c, 15338002
	ld	xwa, xiz
	calr	-403
	lds32	xwa, 0
	.byte 0xf1, 0xec, 0x81
	.long NakaInst_95_Bass_Pedals_95_Ext_Sequencer_95
	ldda8	l, 35336
	ld	xwa, (xsp+4)
	cp	xwa, 7
	jrl	nz, 218
	ld	xde, xbc
	cp	xbc, 29360151
	jr	nz, 72
	ld8_24	c, 15338002
	ld	w, c
	add	w, c
	ld	a, l
	cp	l, w
	jr	nc, 57
	cp	a, c
	jr	nc, 8
	add	a, c
	stda8	35336, a
	jr	4
	stda8	35336, w
	ld8_24	c, 15338002
	ld	xwa, xiz
	calr	-612
	ld8_24	c, 15338002
	ld	xwa, xiz
	calr	-489
	ld8_24	c, 15338002
	.byte 0x0b, 0x00, 0x00, 0x0b, 0x08, 0x8a
	ld	xwa, (xsp+8)
	ld	xde, 35328
	jr	82
	cp	xde, 29360152
	jr	nz, 77
	ld	c, l
	ld8_24	e, 15338002
	cp	l, e
	jr	c, 66
	ld	a, e
	add	a, e
	cp	c, a
	jr	nc, 8
	sub	c, e
	stda8	35336, c
	jr	8
	cp	c, a
	jr	c, 4
	stda8	35336, e
	ld8_24	c, 15338002
	ld	xwa, xiz
	calr	-696
	ld8_24	c, 15338002
	ld	xwa, xiz
	calr	-573
	ld8_24	c, 15338002
	.byte 0x0b, 0x00, 0x00, 0x0b, 0x08, 0x8a
	ld	xwa, (xsp+8)
	ld	xde, 35328
	calr	-4725
	ldda32	xwa, 33260
	.byte 0xaf, 0x04, 0xf0
	jr	z, 37
	ldada	xde, 35255
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16424280
	ldada	xde, 35297
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16424280
	ld	xwa, (xsp+4)
	stda32	33260, xwa
	lds32	xhl, 0
	jrl	420
	ld	xwa, (xsp+4)
	cp	xwa, 8
	jrl	nz, 285
	ld	xde, xbc
	cp	xbc, 29360151
	jr	nz, 118
	ld	c, l
	ld	a, l
	inc	1, a
	.byte 0xc2, 0x14, 0x0a, 0xea, 0xf1
	jr	nc, 105
	ld8_24	e, 15338002
	ld	a, e
	add	a, e
	cp	c, a
	jr	nc, 55
	ld	l, e
	ld	a, c
	extz	wa
	div8rr	a, l
	ld	a, w
	inc	1, a
	cp	a, e
	jrl	nc, 193
	inc	1, c
	stda8	35336, c
	ld8_24	c, 15338002
	ld	xwa, xiz
	calr	-727
	ld8_24	c, 15338002
	.byte 0x0b, 0x00, 0x00, 0x0b, 0x08, 0x8a
	ld	xwa, (xsp+8)
	ld	xde, 35328
	jrl	152
	inc	1, c
	stda8	35336, c
	ld8_24	c, 15338002
	ld	xwa, xiz
	calr	-765
	ld8_24	c, 15338002
	.byte 0x0b, 0x00, 0x00, 0x0b, 0x08, 0x8a
	ld	xwa, (xsp+8)
	ld	xde, 35328
	jr	115
	cp	xde, 29360152
	jr	nz, 110
	ld	c, l
	cps	l, 0
	jr	z, 104
	ld8_24	e, 15338002
	ld	a, e
	add	a, e
	cp	c, a
	jr	nc, 49
	ld	a, c
	extz	wa
	div8rr	a, e
	ld	a, w
	cps	a, 0
	jr	z, 79
	dec	1, c
	stda8	35336, c
	ld8_24	c, 15338002
	ld	xwa, xiz
	calr	-841
	ld8_24	c, 15338002
	.byte 0x0b, 0x00, 0x00, 0x0b, 0x08, 0x8a
	ld	xwa, (xsp+8)
	ld	xde, 35328
	jr	39
	cp	c, a
	jr	ule, 38
	dec	1, c
	stda8	35336, c
	ld8_24	c, 15338002
	ld	xwa, xiz
	calr	-882
	ld8_24	c, 15338002
	.byte 0x0b, 0x00, 0x00, 0x0b, 0x08, 0x8a
	ld	xwa, (xsp+8)
	ld	xde, 35328
	calr	-5034
	ldda32	xwa, 33260
	.byte 0xaf, 0x04, 0xf0
	jrl	z, -273
	ldada	xde, 35255
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16424280
	ldada	xde, 35297
	ld	xwa, xiz
	ld	xbc, 29360143
	jrl	-313
	ld	xwa, (xsp+4)
	cp	xwa, 5
	jr	z, 8
	cp	xwa, 6
	jr	nz, 39
	ldda32	xwa, 33260
	.byte 0xaf, 0x04, 0xf0
	jrl	z, -331
	ldada	xde, 35255
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16424280
	ldada	xde, 35297
	ld	xwa, xiz
	ld	xbc, 29360143
	jrl	-371
	ld	xwa, (xsp+4)
	cp	xwa, 10
	jrl	nz, -372
	cpdi8	35322, 0
	jr	z, 28
	ldda8	a, 35328
	extz	wa
	div8rr	a, e
	extz	wa
	ldda8	c, 35336
	extz	bc
	div8rr	c, e
	extz	bc
	call	16287274
	exts	xhl
	jr	18
	ldda8	a, 35328
	extz	wa
	ldda8	c, 35336
	extz	bc
	call	16286932
	exts	xhl
	pop	xiz
	inc	4, xsp
	ret
	dec	4, xsp
	pushw	iz
	ld	(xsp+2), xwa
	cp	xbc, 29360139
	jr	nz, 72
	lds	iz, 0
	ld	de, iz
	mul	de, 21
	ldada	xbc, 35234
	ld	hl, de
	extz	xhl
	add	xhl, xbc
	.byte 0xc7, 0xf8, 0x89
	ld	(xhl), a
	lds	wa, 1
	add	wa, de
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 0
	ldw	bc, 16
	calr	-11779
	ld	de, iz
	mul	de, 21
	ldada	xwa, 35234
	extz	xde
	add	xde, xwa
	ld	xwa, (xsp+2)
	ld	xbc, 29360143
	call	16424280
	inc	1, iz
	cps	iz, 4
	jr	c, -70
	lds32	xhl, 0
	popw	iz
	inc	4, xsp
	ret

SingleLoadDstFunc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld xiz, xwa
	ld xwa, (xsp + 8)
	cp xwa, 0x1E50003
	jrl z, SLDst_ReturnCapture
	cp xwa, 0x1C00018
	jrl z, SLDst_HandleScroll
	cp xwa, 0x1C00017
	jrl z, SLDst_HandleScroll
	cp xwa, 0x1C0000F
	jrl z, SLDst_HandleConfirm
	cp xwa, 0x1C0000B
	jr z, SLDst_HandleShow
	cp xwa, 0x1E50004
	jr nz, SLDst_Return
	ld xwa, (xsp + 4)
	stda32 33264, xwa
	lds wa, 0
	calr InitializeOperationState
	calr SignalProgressUpdate
	calr WP_ScanAvailability
	calr SignalProgressUpdate
	cpdi8 35320, 1
	jr z, SLDst_ShowHide_Internal
	ld xwa, 0x61004A
	ld xbc, 0x1E0009C
	lds32 xde, 1
	jr SLDst_ShowHide_Dispatch

SLDst_ShowHide_Internal:
	ld xwa, 0x61004A
	ld xbc, 0x1E0009C
	lds32 xde, 0

SLDst_ShowHide_Dispatch:
	call ApPostEvent
	ldda32 xwa, 33264
	ld xbc, 0x1E50002
	ld xde, 0xFFFFFFFF
	call ApPostEvent
	cpdi8 35320, 0
	jr nz, SLDst_ClearFloppyFlag
	call FileIO_ValidateWithExtHeader
	cps hl, 0
	jr z, SLDst_ClearFloppyFlag
	stdi8 35338, 1
	jr SLDst_Return

SLDst_ClearFloppyFlag:
	stdi8 35338, 0

SLDst_Return:
	lds32 xhl, 0
	jrl SLDst_Epilogue

SLDst_HandleShow:
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	calr SingleLoadModeFunc
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	calr SingleLoadSrcBankFunc
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	calr SingleLoadSrcMemFunc
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	calr SingleLoadDstBankFunc
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	calr SingleLoadDstMemFunc
	ldda32 xwa, 33264
	ld xbc, 0x1E50002
	ld xde, 0xFFFFFFFF
	call ApPostEvent
	ld xwa, 0x610036
	ld xbc, 0x1E0003B
	lds32 xde, 0
	call ApPostEvent
	ldda32 xwa, 33264
	ldda8 c, 35320
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a16
	st_dri3b C, 0x07, 0xE8, 0xE4
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl SLDst_Return

SLDst_HandleConfirm:
	ldda32 xwa, 33264
	ld xbc, 0x1E50002
	ld xde, 0xFFFFFFFF
	call ApPostEvent
	ldda32 xwa, 33264
	ldda8 c, 35320
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a16
	st_dri3b C, 0x07, 0xE8, 0xE4
	ld xbc, 0x1C0000B
	lds32 xde, 0
	ld xhl, (xhl)
	call (xhl)
	jrl SLDst_Return

SLDst_HandleScroll:
	ld xwa, (xsp + 4)
	cp xwa, 0x3
	jr nz, SLDst_ScrollMode4
	cpdi8 35320, 1
	jr z, SLDst_ScrollMode4
	ld xwa, (xsp + 8)
	cp xwa, 0x1C00017
	scc8 z, a
	stda8 35322, a
	ld xwa, xiz
	ld xbc, 0x1C0000B
	lds32 xde, 0
	calr SingleLoadSrcMemFunc
	ld xwa, xiz
	ld xbc, 0x1C0000B
	lds32 xde, 0
	calr SingleLoadDstMemFunc
	ldda32 xwa, 33264
	ld xbc, 0x1E50002
	ld xde, 0xFFFFFFFF
	call ApPostEvent
	ld xwa, 0x610036
	ld xbc, 0x1E0003B
	lds32 xde, 0
	call ApPostEvent
	ldda32 xwa, 33264
	ldda8 c, 35320
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a16
	st_dri3b C, 0x07, 0xE8, 0xE4
	ld xbc, 0x1C0000B
	lds32 xde, 0
	ld xhl, (xhl)
	call (xhl)
	ld xwa, xiz
	ld xbc, 0x1C0000B
	lds32 xde, 0
	jrl SLDst_ScrollMode3_CallSrcMem

SLDst_ScrollMode4:
	ld xwa, (xsp + 4)
	cp xwa, 0x4
	jrl nz, SLDst_ScrollDispatch
	calr WP_FindNextSlot
	cps l, 0
	jrl z, SLDst_Return
	cpdi8 35320, 1
	jr z, SLDst_ScrollMode4_Internal
	ld xwa, 0x61004A
	ld xbc, 0x1E0009C
	lds32 xde, 1
	jr SLDst_ScrollMode4_Dispatch

SLDst_ScrollMode4_Internal:
	ld xwa, 0x61004A
	ld xbc, 0x1E0009C
	lds32 xde, 0

SLDst_ScrollMode4_Dispatch:
	call ApPostEvent
	ld xwa, xiz
	ld xbc, 0x1C0000B
	lds32 xde, 0
	calr SingleLoadModeFunc
	ld xwa, xiz
	ld xbc, 0x1C0000B
	lds32 xde, 0
	calr SingleLoadSrcBankFunc
	ld xwa, xiz
	ld xbc, 0x1C0000B
	lds32 xde, 0
	calr SingleLoadSrcMemFunc
	ld xwa, xiz
	ld xbc, 0x1C0000B
	lds32 xde, 0
	calr SingleLoadDstBankFunc
	ld xwa, xiz
	ld xbc, 0x1C0000B
	lds32 xde, 0
	calr SingleLoadDstMemFunc
	ldda32 xwa, 33264
	ld xbc, 0x1E50002
	ld xde, 0xFFFFFFFF
	call ApPostEvent
	ld xwa, 0x610036
	ld xbc, 0x1E0003B
	lds32 xde, 0
	call ApPostEvent
	ldda32 xwa, 33264
	ldda8 c, 35320
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a16
	st_dri3b C, 0x07, 0xE8, 0xE4
	ld xbc, 0x1C0000B
	lds32 xde, 0
	ld xhl, (xhl)
	call (xhl)
	ld xwa, xiz
	ld xbc, 0x1C0000B
	lds32 xde, 0

SLDst_ScrollMode3_CallSrcMem:
	calr SingleLoadSrcFunc
	jrl SLDst_Return

SLDst_ScrollDispatch:
	ld xwa, (xsp + 4)
	cp xwa, 0xA
	jr nz, SLDst_Scroll_ChildReturn
	cpdi8 35320, 4
	jr z, SLDst_Scroll_ChildReturn
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call ApPostEvent
	lds wa, 0
	calr InitializeOperationState
	ldda32 xwa, 33264
	ldda8 c, 35320
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a16
	st_dri3b C, 0x07, 0xE8, 0xE4
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xix, (xhl)
	call (xix)
	ld wa, hl
	lds bc, 1
	calr FileIO_ValidateSignedValue
	stda8 32578, l
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0xEE
	call SoundCtrl_SendCommand
	jrl SLDst_Return

SLDst_Scroll_ChildReturn:
	ld xwa, (xsp + 4)
	cp xwa, 0x7
	jr nz, SLDst_Scroll_SubMode2
	cpdi8 35320, 1
	jr z, SLDst_Scroll_SubMode
	ldda32 xwa, 33264
	ld xbc, 0x1E50002
	lds32 xde, 1
	call ApPostEvent
	ldda32 xwa, 33264
	ldda8 c, 35320
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a16
	st_dri3b C, 0x07, 0xE8, 0xE4
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl SLDst_Return

SLDst_Scroll_SubMode:
	ldda32 xwa, 33264
	ld xbc, 0x1E50002
	ld xde, 0xFFFFFFFF
	call ApPostEvent
	ldda32 xwa, 33264
	ldda8 c, 35320
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a16
	st_dri3b C, 0x07, 0xE8, 0xE4
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl SLDst_Return

SLDst_Scroll_SubMode2:
	ldda32 xwa, 33264
	ld xbc, (xsp + 4)
	cp xbc, 0x8
	jrl nz, SLDst_Scroll_SubMode5
	cpdi8 35320, 1
	jr nz, SLDst_Scroll_SubMode3
	ld xbc, 0x1E50002
	lds32 xde, 2
	call ApPostEvent
	ldda32 xwa, 33264
	ldda8 c, 35320
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a16
	st_dri3b C, 0x07, 0xE8, 0xE4
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl SLDst_Return

SLDst_Scroll_SubMode3:
	cpdi8 35322, 0
	jr nz, SLDst_Scroll_SubMode4
	ld xbc, 0x1E50002
	lds32 xde, 3
	call ApPostEvent
	ldda32 xwa, 33264
	ldda8 c, 35320
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a16
	st_dri3b C, 0x07, 0xE8, 0xE4
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl SLDst_Return

SLDst_Scroll_SubMode4:
	ld xbc, 0x1E50002
	ld xde, 0xFFFFFFFF
	call ApPostEvent
	ldda32 xwa, 33264
	ldda8 c, 35320
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a16
	st_dri3b C, 0x07, 0xE8, 0xE4
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl SLDst_Return

SLDst_Scroll_SubMode5:
	ld xbc, (xsp + 4)
	cp xbc, 0x5
	jr nz, SLDst_Scroll_SubMode6
	ld xbc, 0x1E50002
	ld xde, 0xFFFFFFFF
	call ApPostEvent
	ldda32 xwa, 33264
	ldda8 c, 35320
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a16
	st_dri3b C, 0x07, 0xE8, 0xE4
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl SLDst_Return

SLDst_Scroll_SubMode6:
	ld xbc, (xsp + 4)
	cp xbc, 0x6
	jrl nz, SLDst_Return
	ld xbc, 0x1E50002
	ld xde, 0xFFFFFFFF
	call ApPostEvent
	ldda32 xwa, 33264
	ldda8 c, 35320
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a16
	st_dri3b C, 0x07, 0xE8, 0xE4
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl SLDst_Return

SLDst_ReturnCapture:
	ld xhl, 0xFFFFFFFF

SLDst_Epilogue:
	pop xiz
	inc 8, xsp
	ret

CmpSingleLoadSrcFunc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	cp xiz, 0x1E50003
	jrl z, CmpSrc_ReturnCapture
	cp xiz, 0x1C00018
	jr z, CmpSrc_HandleScroll
	cp xiz, 0x1C00017
	jr z, CmpSrc_HandleScroll
	cp xiz, 0x1C0000B
	jr z, CmpSrc_HandleShow
	cp xiz, 0x1E50004
	jrl nz, CmpSrc_Return
	ld xwa, (xsp + 4)
	stda32 33268, xwa
	ld xbc, 0x1E50002
	ld xde, 0xFFFFFFFF
	call ApPostEvent
	jrl CmpSrc_Return

CmpSrc_HandleShow:
	ldda32 xwa, 33268
	ld xbc, 0x1E50002
	ld xde, 0xFFFFFFFF
	call ApPostEvent
	ldda32 xwa, 33268
	ldda8 c, 35320
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a2a
	st_dri3b C, 0x07, 0xE8, 0xE4
	ld xbc, xiz
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl CmpSrc_Return

CmpSrc_HandleScroll:
	ld xwa, (xsp + 4)
	cp xwa, 0x5
	jr nz, CmpSrc_ScrollMode6
	ldda32 xwa, 33268
	ld xbc, 0x1E50002
	lds32 xde, 1
	call ApPostEvent
	ldda32 xwa, 33268
	ldda8 c, 35320
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a2a
	st_dri3b C, 0x07, 0xE8, 0xE4
	ld xbc, xiz
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl CmpSrc_Return

CmpSrc_ScrollMode6:
	ld xwa, (xsp + 4)
	cp xwa, 0x6
	jr nz, CmpSrc_ScrollMode7
	cpdi8 35322, 0
	jr nz, CmpSrc_ScrollMode6_NoStep
	ldda32 xwa, 33268
	ld xbc, 0x1E50002
	lds32 xde, 3
	call ApPostEvent
	ldda32 xwa, 33268
	ldda8 c, 35320
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a2a
	st_dri3b C, 0x07, 0xE8, 0xE4
	ld xbc, xiz
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl CmpSrc_Return

CmpSrc_ScrollMode6_NoStep:
	ldda32 xwa, 33268
	ld xbc, 0x1E50002
	ld xde, 0xFFFFFFFF
	call ApPostEvent
	ldda32 xwa, 33268
	ldda8 c, 35320
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a2a
	st_dri3b C, 0x07, 0xE8, 0xE4
	ld xbc, xiz
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl CmpSrc_Return

CmpSrc_ScrollMode7:
	ldda32 xwa, 33268
	ld xbc, (xsp + 4)
	cp xbc, 0x7
	jr nz, CmpSrc_ScrollMode8
	ld xbc, 0x1E50002
	ld xde, 0xFFFFFFFF
	call ApPostEvent
	ldda32 xwa, 33268
	ldda8 c, 35320
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a2a
	st_dri3b C, 0x07, 0xE8, 0xE4
	ld xbc, xiz
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jr CmpSrc_Return

CmpSrc_ScrollMode8:
	ld xbc, (xsp + 4)
	cp xbc, 0x8
	jr nz, CmpSrc_ScrollMode40
	cpdi8 35322, 0
	jr nz, CmpSrc_ScrollMode40
	ld xbc, 0x1E50002
	ld xde, 0xFFFFFFFF
	call ApPostEvent
	ldda32 xwa, 33268
	ldda8 c, 35320
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a2a
	st_dri3b C, 0x07, 0xE8, 0xE4
	ld xbc, xiz
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jr CmpSrc_Return

CmpSrc_ScrollMode40:
	ld xbc, (xsp + 4)
	cp xbc, 0x28
	jr nz, CmpSrc_Return
	ldda8 c, 35320
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a2a
	st_dri3b C, 0x07, 0xE8, 0xE4
	ld xbc, xiz
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)

CmpSrc_Return:
	lds32 xhl, 0
	jr CmpSrc_Epilogue

CmpSrc_ReturnCapture:
	ld xhl, 0xFFFFFFFF

CmpSrc_Epilogue:
	pop xiz
	inc 4, xsp
	ret

CmpSingleLoadDstFunc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld xiz, xwa
	ld xwa, (xsp + 8)
	cp xwa, 0x1E50003
	jrl z, CmpDst_ReturnCapture
	cp xwa, 0x1C00018
	jrl z, CmpDst_HandleScroll
	cp xwa, 0x1C00017
	jrl z, CmpDst_HandleScroll
	cp xwa, 0x1C0000B
	jr z, CmpDst_HandleShow
	cp xwa, 0x1E50004
	jrl nz, CmpDst_Return
	ld xwa, (xsp + 4)
	stda32 33272, xwa
	ld xbc, 0x1E50002
	ld xde, 0xFFFFFFFF
	call ApPostEvent
	jrl CmpDst_Return

CmpDst_HandleShow:
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	calr SingleLoadSrcMemFunc
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	calr SingleLoadSrcBankFunc
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	calr SingleLoadDstMemFunc
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	calr SingleLoadDstBankFunc
	ldda32 xwa, 33272
	ld xbc, 0x1E50002
	ld xde, 0xFFFFFFFF
	call ApPostEvent
	ld xwa, 0x61007E
	ld xbc, 0x1E0003B
	lds32 xde, 0
	call ApPostEvent
	ldda32 xwa, 33272
	ldda8 c, 35320
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a3e
	st_dri3b C, 0x07, 0xE8, 0xE4
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl CmpDst_Return

CmpDst_HandleScroll:
	ld xwa, (xsp + 4)
	cp xwa, 0x3
	jr nz, CmpDst_ScrollModeA
	ld xwa, (xsp + 8)
	cp xwa, 0x1C00017
	scc8 z, a
	stda8 35322, a
	ld xwa, xiz
	ld xbc, 0x1C0000B
	lds32 xde, 0
	calr SingleLoadSrcMemFunc
	ld xwa, xiz
	ld xbc, 0x1C0000B
	lds32 xde, 0
	calr SingleLoadDstMemFunc
	ldda32 xwa, 33272
	ld xbc, 0x1E50002
	ld xde, 0xFFFFFFFF
	call ApPostEvent
	ld xwa, 0x61007E
	ld xbc, 0x1E0003B
	lds32 xde, 0
	call ApPostEvent
	ldda32 xwa, 33272
	ldda8 c, 35320
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a3e
	st_dri3b C, 0x07, 0xE8, 0xE4
	ld xbc, 0x1C0000B
	lds32 xde, 0
	ld xhl, (xhl)
	call (xhl)
	ld xwa, xiz
	ld xbc, 0x1C0000B
	lds32 xde, 0
	calr CmpSingleLoadSrcFunc
	jrl CmpDst_Return

CmpDst_ScrollModeA:
	ld xwa, (xsp + 4)
	cp xwa, 0xA
	jr nz, CmpDst_ScrollMode7
	cpdi8 35320, 4
	jr z, CmpDst_ScrollMode7
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call ApPostEvent
	lds wa, 0
	calr InitializeOperationState
	ldda32 xwa, 33272
	ldda8 c, 35320
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a3e
	st_dri3b C, 0x07, 0xE8, 0xE4
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xix, (xhl)
	call (xix)
	ld wa, hl
	lds bc, 1
	calr FileIO_ValidateSignedValue
	stda8 32578, l
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0xEE
	call SoundCtrl_SendCommand
	jrl CmpDst_Return

CmpDst_ScrollMode7:
	ld xwa, (xsp + 4)
	cp xwa, 0x7
	jr nz, CmpDst_ScrollMode8
	ldda32 xwa, 33272
	ld xbc, 0x1E50002
	lds32 xde, 1
	call ApPostEvent
	ldda32 xwa, 33272
	ldda8 c, 35320
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a3e
	st_dri3b C, 0x07, 0xE8, 0xE4
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl CmpDst_Return

CmpDst_ScrollMode8:
	ldda32 xwa, 33272
	ld xbc, (xsp + 4)
	cp xbc, 0x8
	jr nz, CmpDst_ScrollMode5
	cpdi8 35322, 0
	jr nz, CmpDst_ScrollMode8_NoStep
	ld xbc, 0x1E50002
	lds32 xde, 3
	call ApPostEvent
	ldda32 xwa, 33272
	ldda8 c, 35320
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a3e
	st_dri3b C, 0x07, 0xE8, 0xE4
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl CmpDst_Return

CmpDst_ScrollMode8_NoStep:
	ld xbc, 0x1E50002
	ld xde, 0xFFFFFFFF
	call ApPostEvent
	ldda32 xwa, 33272
	ldda8 c, 35320
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a3e
	st_dri3b C, 0x07, 0xE8, 0xE4
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jr CmpDst_Return

CmpDst_ScrollMode5:
	ld xbc, (xsp + 4)
	cp xbc, 0x5
	jr nz, CmpDst_ScrollMode6
	ld xbc, 0x1E50002
	ld xde, 0xFFFFFFFF
	call ApPostEvent
	ldda32 xwa, 33272
	ldda8 c, 35320
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a3e
	st_dri3b C, 0x07, 0xE8, 0xE4
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jr CmpDst_Return

CmpDst_ScrollMode6:
	ld xbc, (xsp + 4)
	cp xbc, 0x6
	jr nz, CmpDst_Return
	cpdi8 35322, 0
	jr nz, CmpDst_Return
	ld xbc, 0x1E50002
	ld xde, 0xFFFFFFFF
	call ApPostEvent
	ldda32 xwa, 33272
	ldda8 c, 35320
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a3e
	st_dri3b C, 0x07, 0xE8, 0xE4
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)

CmpDst_Return:
	lds32 xhl, 0
	jr CmpDst_Epilogue

CmpDst_ReturnCapture:
	ld xhl, 0xFFFFFFFF

CmpDst_Epilogue:
	pop xiz
	inc 8, xsp
	ret

CmpSingleLoadFileFunc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	cp xbc, 0x1C00018
	jrl z, CmpFile_HandleScroll
	cp xbc, 0x1C00017
	jr z, CmpFile_HandleScroll
	cp xbc, 0x1C0000B
	jr z, CmpFile_HandleShow
	cp xbc, 0x1E50004
	jrl nz, CmpFile_Return
	stda32 33276, xde
	call GetCurrentFileIndex
	stda16 33280, xhl
	cps hl, 0
	jr ge, CmpFile_Selection_Clamp
	stdi16 33280, 0

CmpFile_Selection_Clamp:
	ldda32 xwa, 33276
	ld xbc, 0x1E50002
	ld xde, 0xFFFFFFFF
	jr CmpFile_ShowDispatch

CmpFile_HandleShow:
	stdi8 34928, 0
	cpdi8 35320, 2
	jr nz, CmpFile_ShowDefault
	ldda16 xwa, 33280
	call GetFileEntryPtr
	ld xiz, xhl
	jr CmpFile_ShowDraw

CmpFile_ShowDefault:
	lda_24 xiz, 0xea0a52

CmpFile_ShowDraw:
	ldada xwa, 34929
	ldda16 xde, 33280
	inc 1, de
	pushw 0x6
	pushw 0x0
	ld xbc, xiz
	call FileIO_ReadHeader_ParseLoop
	ldda32 xwa, 33276
	ld xbc, 0x1C0000F
	ld xde, 0x8870

CmpFile_ShowDispatch:
	call ApPostEvent
	jrl CmpFile_Return

CmpFile_HandleScroll:
	ldda16 xwa, 33280
	ld hl, wa
	or xde, xde
	jr nz, CmpFile_ScrollDown
	ld bc, wa
	inc 1, bc
	cp bc, 0x14
	jr ge, CmpFile_ScrollRedraw
	inc 1, wa
	jr CmpFile_ScrollStore

CmpFile_ScrollDown:
	cp xde, 0x1
	jr nz, CmpFile_ScrollRedraw
	cps wa, 0
	jr le, CmpFile_ScrollRedraw
	dec 1, wa

CmpFile_ScrollStore:
	stda16 33280, xwa

CmpFile_ScrollRedraw:
	ldda16 xwa, 33280
	cp wa, hl
	jr z, CmpFile_Return
	call NotifyUIOfSelectionChange
	stdi8 34928, 0
	lda_24 xiz, 0xea0a52
	stdi8 35320, 4
	lds wa, 3
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, CmpFile_RedrawDispatch
	call FileIO_ValidateAndOpenFile
	cps hl, 0
	jr z, CmpFile_RedrawDispatch
	stdi8 35320, 2
	ldda16 xwa, 33280
	call GetFileEntryPtr
	ld xiz, xhl

CmpFile_RedrawDispatch:
	ldada xwa, 34929
	ldda16 xde, 33280
	inc 1, de
	pushw 0x6
	pushw 0x0
	ld xbc, xiz
	call FileIO_ReadHeader_ParseLoop
	ldda32 xwa, 33276
	ld xbc, 0x1C0000F
	ld xde, 0x8870
	call ApPostEvent
	ld xwa, (xsp + 4)
	ld xbc, 0x1C0000B
	lds32 xde, 0
	calr CmpSingleLoadSrcFunc
	ld xwa, (xsp + 4)
	ld xbc, 0x1C0000B
	lds32 xde, 0
	calr CmpSingleLoadDstFunc

CmpFile_Return:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret

FmmCmpSingleLoadFunc:
	cp xbc, 0x1C00013
	jrl nz, FmmCmpLoad_Return
	cp xde, 0x3
	jrl z, FmmCmpLoad_HandleAbort
	cp xde, 0x2
	jrl nz, FmmCmpLoad_Return
	lds wa, 1
	calr InitializeOperationState
	ld xwa, 0x61004A
	ld xbc, 0x1E0009C
	lds32 xde, 1
	call ApPostEvent
	ld xwa, 0x600026
	ld xbc, 0x1C00001
	lds32 xde, 5
	call ApPostEvent
	cpdi16 34048, 0
	jr ge, FmmCmpLoad_DispatchState
	call GetDiskSizeInfo
	extz hl
	stda16 34048, xhl
	calr SignalProgressUpdate

FmmCmpLoad_DispatchState:
	ldda16 xwa, 34048
	cps wa, 1
	jrl z, FmmCmpLoad_HandleSuccess
	cps wa, 0
	jrl z, FmmCmpLoad_HandleError
	cps wa, 5
	jr z, FmmCmpLoad_HandleCancel
	cpdi16 34050, 0
	jr ge, FmmCmpLoad_ContinueLoad
	call GetEncodedFileSizeData
	stda16 34050, xhl
	call FileIO_SearchAndLoadFile
	call GetEncodedFreeSpaceData
	calr SignalProgressUpdate

FmmCmpLoad_ContinueLoad:
	stdi8 35320, 4
	lds wa, 3
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, FmmCmpLoad_CloseProgress
	call FileIO_ValidateAndOpenFile
	cps hl, 0
	jr z, FmmCmpLoad_SignalProgress
	stdi8 35320, 2

FmmCmpLoad_SignalProgress:
	calr SignalProgressUpdate

FmmCmpLoad_CloseProgress:
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0000A
	lds32 xde, 0
	call ApPostEvent
	stdi8 35326, 0
	stdi8 35334, 0
	jr FmmCmpLoad_Return

FmmCmpLoad_HandleCancel:
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0xB0
	call UI_PostModeChangeEvent
	stdi8 32578, 0
	ldw wa, 0xEE
	jr FmmCmpLoad_CallStatusDisplay

FmmCmpLoad_HandleError:
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0x7D
	call UI_PostModeChangeEvent
	jr FmmCmpLoad_Return

FmmCmpLoad_HandleSuccess:
	calr ResetProgressIndication
	ld xwa, 0x600026
	ld xbc, 0x1C00002
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0xB0
	call UI_PostModeChangeEvent
	stdi8 32578, 2
	ldw wa, 0xEE

FmmCmpLoad_CallStatusDisplay:
	call SoundCtrl_SendCommand
	jr FmmCmpLoad_Return

FmmCmpLoad_HandleAbort:
	calr CancelOperationCleanup

FmmCmpLoad_Return:
	lds32 xhl, 0
	ret

BuildSlotLabel:
	dec 2, xsp
	push xiz
	ld hl, bc
	ld (xsp + 4), wa
	lda_24 xbc, 0x0ab000
	ld wa, (xsp + 4)
	extz xwa
	sll xwa, 11
	add xbc, xwa
	st_dri3b A, 0xE5, 0x00, 0x01
	ld wa, (xsp + 4)
	mul wa, 0x15
	ldada xix, 33282
	ld iz, wa
	extz xiz
	add xiz, xix
	lda_dpi XSP, 0xF8
	cps e, 0
	jr z, BuildSlotLabel_WriteContent
	cpw (xsp + 4), 0x9
	jr nz, BuildSlotLabel_WriteLetter
	stib_dpi 0xF8, 0x31
	ld (xiz), 0x30
	jr BuildSlotLabel_WriteColon

BuildSlotLabel_WriteLetter:
	stib_dpi 0xF8, 0x20
	ld wa, (xsp + 4)
	add a, 0x31
	ld (xiz), a

BuildSlotLabel_WriteColon:
	inc 1, xiz
	stib_dpi 0xF8, 0x3A

BuildSlotLabel_WriteContent:
	ld xwa, xiz
	ldw de, 0x10
	call FileIO_CopyString_WriteNull
	ld (xiz + 16), 0x0
	ld wa, (xsp + 4)
	mul wa, 0x15
	ldada xbc, 33282
	extz xwa
	add xwa, xbc
	ld xhl, xwa
	pop xiz
	inc 2, xsp
	ret

