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
	cp	xbc, 29360139
	jr	z, 14
	cp	xbc, 31784964
	jr	nz, 38
	stda32	(33050), xde
	jr	32
SLMode_HandleShow:
	ldb_d8	a, 35164
	extz	wa
	sla	wa, 2
	lda_24	xbc, 15336856
	ld_rrl	xde, xbc, wa
	ld	xwa, (33050:16)
	ld	xbc, 29360143
	call	16423243
SLMode_Return:
	lds32 xhl, 0
	ret

SingleLoadDstBankFunc:
	cp	xbc, 29360139
	jr	z, 14
	cp	xbc, 31784964
	jr	nz, 38
	stda32	(33054), xde
	jr	32
SLDstBank_HandleShow:
	ldb_d8	a, 35164
	extz	wa
	sla	wa, 2
	lda_24	xbc, 15336946
	ld_rrl	xde, xbc, wa
	ld	xwa, (33054:16)
	ld	xbc, 29360143
	call	16423243
SLDstBank_Return:
	lds32 xhl, 0
	ret

SingleLoadDstMemFunc:
	cp	xbc, 29360139
	jr	z, 14
	cp	xbc, 31784964
	jr	nz, 62
	stda32	(33058), xde
	jr	56
SLDstMem_HandleShow:
	.byte 0xe1, 0x22, 0x81, 0x20, 0xf2, 0x24, 0x06, 0xea
	.byte 0x32, 0xc1, 0x5e, 0x89, 0x3f, 0x00, 0x66, 0x11
	.byte 0xc1, 0x5c, 0x89, 0x3f, 0x01, 0x66, 0x0a, 0xaa
	.byte 0x10, 0x22, 0x41, 0x0f, 0x00, 0xc0, 0x01, 0x68
	.byte 0x13
SLDstMem_ShowFromBank:
	ldb_d8 c, (35164)

	extz bc

	sla bc, 2

	ld_sril3 XDE, 0x07, 0xe8, 0xe4

	ld xbc, 0x1c0000f



SLDstMem_DispatchShow:
	call ApPostEvent

SLDstMem_Return:
	lds32 xhl, 0
	ret

SingleLoadSrcBankFunc:
	cp	xbc, 29360139
	jr	z, 14
	cp	xbc, 31784964
	jr	nz, 59
	stda32	(33062), xde
	jr	53
SLSrcBank_HandleShow:
	ld	xwa, (33062:16)
	lda_24	xde, 15336946
	ldb_d8	c, 35164
	cps	c, 0
	jr	nz, 17
	cpdi8	35182, 0
	jr	z, 10
	ld	xde, (xde+16)
	ld	xbc, 29360143
	jr	15
SLSrcBank_ShowFromIndex:
	extz bc
	sla bc, 2
	ld_sril3 XDE, 0x07, 0xe8, 0xe4
	ld xbc, 0x1c0000f

SLSrcBank_DispatchShow:
	call ApPostEvent

SLSrcBank_Return:
	lds32 xhl, 0
	ret

SingleLoadSrcMemFunc:
	cp	xbc, 29360139
	jr	z, 14
	cp	xbc, 31784964
	jr	nz, 59
	stda32	(33066), xde
	jr	53
SLSrcMem_HandleShow:
	ld	xwa, (33066:16)
	lda_24	xde, 15336996
	ldb_d8	c, 35164
	cps	c, 1
	jr	z, 7
	cpdi8	35166, 0
	jr	z, 10
SLSrcMem_ShowDirect:
	ld xde, (xde + 16)
	ld xbc, 0x1c0000f
	jr SLSrcMem_DispatchShow

SLSrcMem_ShowFromIndex:
	extz bc
	sla bc, 2
	ld_sril3 XDE, 0x07, 0xe8, 0xe4
	ld xbc, 0x1c0000f

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
	lda_d16	xwa, 34994
	stib_dsp	224, 0
	ldb_d8	c, 35164
	extz	bc
	sla	bc, 2
	lda_24	xde, 15336946
	ld_rrl	xbc, xde, bc
	inc	1, xbc
	call	16288975
	lda_d16	xwa, 34995
	ld	xbc, 15337784
	call	16289030
	lda_d16	xiz, 34995
	ldb_d8	a, 35168
	extz	wa
	.byte 0x8f, 0x04, 0x51
	inc	1, a
	extz	wa
	lds	bc, 0
	calr	-14983
	ld	xbc, xhl
	ld	xwa, xiz
	call	16289030
	lda_d16	xwa, 34995
	ldw	bc, 16
	calr	-4482
	ld	xwa, (xsp+6)
	ld	xbc, 29360143
	ld	xde, 34994
	call	16423243
	pop	xiz
	inc	6, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xwa
	lda_d16	xwa, 34994
	ld	(xwa+21), 1
	lda	xiz, (xwa+22)
	ldb_d8	a, 35168
	extz	wa
	div8rr	a, c
	extz	wa
	call	16293121
	ld	xbc, xhl
	ld	xwa, xiz
	call	16288975
	lda_d16	xwa, 35016
	ldw	bc, 16
	calr	-4552
	lda_d16	xde, 35015
	ld	xwa, (xsp+4)
	ld	xbc, 29360143
	call	16423243
	pop	xiz
	inc	4, xsp
	ret
	dec	6, xsp
	push	xiz
	ld	(xsp+4), c
	ld	(xsp+6), xwa
	lda_d16	xwa, 34994
	ld	(xwa+42), 2
	lda	xwa, (xwa+43)
	ldb_d8	c, 35164
	extz	bc
	sla	bc, 2
	lda_24	xde, 15336996
	ld_rrl	xbc, xde, bc
	inc	1, xbc
	call	16288975
	lda_d16	xwa, 35037
	ld	xbc, 15337788
	call	16289030
	cpdi8	35166, 0
	jr	nz, 32
	lda_d16	xiz, 35037
	ldb_d8	a, 35168
	extz	wa
	.byte 0x8f, 0x04, 0x51
	ld	a, w
	inc	1, a
	extz	wa
	lds	bc, 0
	calr	-15180
	ld	xbc, xhl
	ld	xwa, xiz
	call	16289030
	lda_d16	xwa, 35037
	ldw	bc, 16
	calr	-4679
	lda_d16	xde, 35036
	ld	xwa, (xsp+6)
	ld	xbc, 29360143
	call	16423243
	cpdi8	35166, 0
	jr	z, 36
	lda_d16	xwa, 34994
	ld	(xwa+63), 3
	lda	xwa, (xwa+64)
	ld	xbc, 15337792
	call	16288975
	lda_d16	xde, 35057
	ld	xwa, (xsp+6)
	ld	xbc, 29360143
	call	16423243
	pop	xiz
	inc	6, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xwa
	cpdi8	35166, 0
	jr	nz, 55
	lda_d16	xwa, 34994
	ld	(xwa+63), 3
	lda	xiz, (xwa+64)
	ldb_d8	a, 35168
	extz	wa
	call	16293243
	ld	xbc, xhl
	ld	xwa, xiz
	call	16288975
	lda_d16	xwa, 35058
	ldw	bc, 16
	calr	-4794
	lda_d16	xde, 35057
	ld	xwa, (xsp+4)
	ld	xbc, 29360143
	call	16423243
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
	cpdi8	35182, 0
	jr	z, 15
	ldb_d8	a, 35168
	extz	wa
	.byte 0xc2, 0x52, 0x09, 0xea, 0x51
	stb_d8	35168, w
	ldb_da	c, (15337810)
	ld	xwa, xiz
	calr	-492
	ldb_da	c, (15337810)
	ld	xwa, xiz
	calr	-317
	ldb_da	c, (15337810)
	ld	xwa, xiz
	calr	-396
	ldb_da	c, (15337810)
	ld	xwa, xiz
	calr	-167
	lds32	xwa, 0
	stda32	33070, xwa
	stdi8	33074, 0
	stdi8	33076, 0
	jrl	453
	ldb_d8	e, 35168
	ld	xwa, (xsp+4)
	cp	xwa, 5
	jrl	nz, 154
	cpdi8	35182, 0
	jr	nz, 108
	ld	xix, xbc
	cp	xbc, 29360151
	jr	nz, 43
	ldb_da	l, (15337810)
	ld	a, l
	ld	c, e
	add	a, e
	cpda8_24 xbc, (15337812)
	jr	nc, 25
	add	c, l
	stb_d8	35168, c
	ldb_da	c, (15337810)
	ld	xwa, xiz
	calr	-608
	ldb_da	c, (15337810)
	ld	xwa, xiz
	jr	42
	cp	xix, 29360152
	jr	nz, 47
	ld	a, e
	ldb_da	c, (15337810)
	cp	e, c
	jr	c, 36
	sub	a, c
	stb_d8	35168, a
	ldb_da	c, (15337810)
	ld	xwa, xiz
	calr	-652
	ldb_da	c, (15337810)
	ld	xwa, xiz
	calr	-477
	stdi8	33076, 1
	stdi8	33074, 1
	ld	xwa, (33070:16)
	.byte 0xaf, 0x04, 0xf0
	jrl	z, 312
	lda_d16	xde, 35015
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16423243
	lda_d16	xde, 35057
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
	cpda8_24 xbc, (15337812)
	jr	nc, 36
	ldb_da	e, (15337810)
	ld	l, e
	ld	a, c
	extz	wa
	div8rr	a, l
	ld	a, w
	inc	1, a
	cp	a, e
	jr	nc, 67
	inc	1, c
	stb_d8	35168, c
	ldb_da	c, (15337810)
	ld	xwa, xiz
	jr	44
	cp	xhl, 29360152
	jr	nz, 44
	ld	c, e
	cps	e, 0
	jr	z, 38
	ldb_da	e, (15337810)
	ld	a, c
	extz	wa
	div8rr	a, e
	ld	a, w
	cps	a, 0
	jr	z, 21
	dec	1, c
	stb_d8	35168, c
	ldb_da	c, (15337810)
	ld	xwa, xiz
	calr	-644
	stdi8	33074, 1
	ld	xwa, (33070:16)
	.byte 0xaf, 0x04, 0xf0
	jrl	z, 150
	lda_d16	xde, 35015
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16423243
	lda_d16	xde, 35057
	ld	xwa, xiz
	ld	xbc, 29360143
	jr	54
	ld	xwa, (xsp+4)
	cp	xwa, 7
	jr	z, 8
	cp	xwa, 8
	jr	nz, 48
	ld	xwa, (33070:16)
	.byte 0xaf, 0x04, 0xf0
	jr	z, 94
	lda_d16	xde, 35015
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16423243
	lda_d16	xde, 35057
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16423243
	ld	xwa, (xsp+4)
	stda32	33070, xwa
	jr	55
	ld	xwa, (xsp+4)
	cp	xwa, 40
	jr	nz, 44
	cpdi8	33076, 0
	jr	z, 15
	ldb_da	c, (15337810)
	ld	xwa, xiz
	calr	-851
	stdi8	33076, 0
	cpdi8	33074, 0
	jr	z, 15
	ldb_da	c, (15337810)
	ld	xwa, xiz
	calr	-634
	stdi8	33074, 0
	lds32	xhl, 0
	pop	xiz
	inc	4, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xwa
	cp	xbc, 29360139
	jrl	nz, 196
	lda_d16	xwa, 34994
	stib_dsp	224, 0
	ld	(xwa), 0
	ldw	bc, 16
	calr	-5419
	lda_d16	xwa, 34994
	ld	(xwa+21), 1
	lda	xwa, (xwa+22)
	ldb_d8	c, 35164
	extz	bc
	sla	bc, 2
	lda_24	xde, 15336996
	ld_rrl	xbc, xde, bc
	inc	1, xbc
	call	16288975
	lda_d16	xwa, 35016
	ld	xbc, 15337816
	call	16289030
	lda_d16	xwa, 35016
	ldw	bc, 16
	calr	-5478
	lda_d16	xwa, 34994
	ld	(xwa+42), 2
	lda	xiz, (xwa+43)
	lds	wa, 0
	call	16293390
	ld	xbc, xhl
	ld	xwa, xiz
	call	16288975
	lda_d16	xwa, 35037
	ldw	bc, 16
	calr	-5513
	lda_d16	xwa, 34994
	ld	(xwa+63), 3
	lda	xwa, (xwa+64)
	ld	(xwa), 0
	ldw	bc, 16
	calr	-5533
	ld	xwa, (xsp+4)
	ld	xbc, 29360143
	ld	xde, 34994
	call	16423243
	lda_d16	xde, 35015
	ld	xwa, (xsp+4)
	ld	xbc, 29360143
	call	16423243
	lda_d16	xde, 35036
	ld	xwa, (xsp+4)
	ld	xbc, 29360143
	call	16423243
	lda_d16	xde, 35057
	ld	xwa, (xsp+4)
	ld	xbc, 29360143
	call	16423243
	lds32	xhl, 0
	pop	xiz
	inc	4, xsp
	ret
	dec	2, xsp
	push	xiz
	ld	(xsp+4), c
	ld	xiz, xwa
	lda_d16	xwa, 34994
	stib_dsp	224, 0
	ldb_d8	c, 35164
	extz	bc
	sla	bc, 2
	lda_24	xde, 15336946
	ld_rrl	xbc, xde, bc
	inc	1, xbc
	call	16288975
	lda_d16	xwa, 34995
	ld	xbc, 15337818
	call	16289030
	lda_d16	xwa, 34995
	ldw	bc, 16
	calr	-5668
	lda_d16	xwa, 35015
	ldb_d8	c, 35170
	extz	bc
	.byte 0x8f, 0x04, 0x53
	extz	bc
	lds	de, 1
	calr	-1950
	ld	xwa, xiz
	ld	xbc, 29360143
	ld	xde, 34994
	call	16423243
	lda_d16	xde, 35015
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16423243
	pop	xiz
	inc	2, xsp
	ret
	dec	8, xsp
	push	xiz
	ld	(xsp+6), c
	ld	(xsp+8), xwa
	ldb_d8	a, 35170
	extz	wa
	.byte 0x8f, 0x06, 0x51
	ld	a, w
	extz	wa
	ld	(xsp+4), wa
	lda_d16	xwa, 34994
	ld	(xwa+42), 2
	lda	xwa, (xwa+43)
	ldb_d8	c, 35164
	extz	bc
	sla	bc, 2
	lda_24	xde, 15336996
	ld_rrl	xbc, xde, bc
	inc	1, xbc
	call	16288975
	lda_d16	xwa, 35037
	ld	xbc, 15337822
	call	16289030
	cpdi8	35166, 0
	jr	nz, 18
	lda_d16	xiz, 35037
	ld	wa, (xsp+4)
	calr	-2038
	ld	xbc, xhl
	ld	xwa, xiz
	call	16289030
	lda_d16	xwa, 35037
	ldw	bc, 16
	calr	-5832
	lda_d16	xde, 35036
	ld	xwa, (xsp+8)
	ld	xbc, 29360143
	call	16423243
	lda_d16	xbc, 34994
	lda	xwa, (xbc+63)
	cpdi8	35166, 0
	jr	z, 29
	ld	(xwa), 3
	lda	xwa, (xbc+64)
	ld	xbc, 15337826
	call	16288975
	lda_d16	xde, 35057
	ld	xwa, (xsp+8)
	ld	xbc, 29360143
	jr	39
	.byte 0x9f, 0x04, 0x3f, 0x04, 0x00
	jr	c, 36
	ldb_d8	c, 35170
	extz	bc
	.byte 0x8f, 0x06, 0x53
	extz	bc
	pushw 3
	ld	de, (xsp+6)
	calr	-2127
	lda_d16	xde, 35057
	ld	xwa, (xsp+8)
	ld	xbc, 29360143
	call	16423243
	pop	xiz
	inc	8, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	e, c
	ld	(xsp+4), xwa
	ldb_d8	a, 35170
	extz	wa
	div8rr	a, e
	ld	c, w
	extz	bc
	cpdi8	35166, 0
	jr	nz, 63
	cps	bc, 4
	jr	nc, 59
	lda_d16	xwa, 34994
	ld	(xwa+63), 3
	lda	xiz, (xwa+64)
	ldb_d8	a, 35170
	extz	wa
	div8rr	a, e
	extz	wa
	call	16293512
	ld	xbc, xhl
	ld	xwa, xiz
	call	16288975
	lda_d16	xwa, 35058
	ldw	bc, 16
	calr	-6012
	lda_d16	xde, 35057
	ld	xwa, (xsp+4)
	ld	xbc, 29360143
	call	16423243
	pop	xiz
	inc	4, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	ld	xde, xbc
	ld	xiz, xwa
	ldb_da	c, (15337844)
	cp	xde, 29360152
	jr	z, 51
	cp	xde, 29360151
	jr	z, 43
	cp	xde, 29360139
	jrl	nz, 447
	ld	xwa, xiz
	calr	-354
	ldb_da	c, (15337844)
	ld	xwa, xiz
	calr	-483
	ldb_da	c, (15337844)
	ld	xwa, xiz
	calr	-159
	lds32	xwa, 0
	stda32	33078, xwa
	jrl	408
	ldb_d8	l, 35170
	ld	xwa, (xsp+4)
	cp	xwa, 5
	jrl	nz, 142
	ld	xix, xde
	cp	xde, 29360151
	jr	nz, 43
	ldb_da	e, (15337844)
	ld	a, e
	ld	c, l
	add	a, l
	cpda8_24 xbc, (15337846)
	jr	nc, 25
	add	c, e
	stb_d8	35170, c
	ldb_da	c, (15337844)
	ld	xwa, xiz
	calr	-562
	ldb_da	c, (15337844)
	ld	xwa, xiz
	jr	42
	cp	xix, 29360152
	jr	nz, 42
	ld	a, l
	ldb_da	c, (15337844)
	cp	l, c
	jr	c, 31
	sub	a, c
	stb_d8	35170, a
	ldb_da	c, (15337844)
	ld	xwa, xiz
	calr	-606
	ldb_da	c, (15337844)
	ld	xwa, xiz
	calr	-497
	stdi8	33082, 1
	ld	xwa, (33078:16)
	.byte 0xaf, 0x04, 0xf0
	jrl	z, 284
	lda_d16	xde, 35015
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16423243
	lda_d16	xde, 35057
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
	cpda8_24 xbc, (15337846)
	jr	nc, 36
	ldb_da	e, (15337844)
	ld	l, e
	ld	a, c
	extz	wa
	div8rr	a, l
	ld	a, w
	inc	1, a
	cp	a, e
	jr	nc, 67
	inc	1, c
	stb_d8	35170, c
	ldb_da	c, (15337844)
	ld	xwa, xiz
	jr	44
	cp	xix, 29360152
	jr	nz, 44
	ld	c, l
	cps	l, 0
	jr	z, 38
	ldb_da	e, (15337844)
	ld	a, c
	extz	wa
	div8rr	a, e
	ld	a, w
	cps	a, 0
	jr	z, 21
	dec	1, c
	stb_d8	35170, c
	ldb_da	c, (15337844)
	ld	xwa, xiz
	calr	-659
	stdi8	33082, 1
	ld	xwa, (33078:16)
	.byte 0xaf, 0x04, 0xf0
	jr	z, 123
	lda_d16	xde, 35015
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16423243
	lda_d16	xde, 35057
	ld	xwa, xiz
	ld	xbc, 29360143
	jr	54
	ld	xwa, (xsp+4)
	cp	xwa, 7
	jr	z, 8
	cp	xwa, 8
	jr	nz, 48
	ld	xwa, (33078:16)
	.byte 0xaf, 0x04, 0xf0
	jr	z, 67
	lda_d16	xde, 35015
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16423243
	lda_d16	xde, 35057
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16423243
	ld	xwa, (xsp+4)
	stda32	33078, xwa
	jr	28
	ld	xwa, (xsp+4)
	cp	xwa, 40
	jr	nz, 17
	cpdi8	33082, 0
	jr	z, 10
	ld	xwa, xiz
	calr	-576
	stdi8	33082, 0
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
	lda_d16	xwa, 34994
	stib_dsp	224, 0
	ldb_d8	c, 35164
	extz	bc
	sla	bc, 2
	lda_24	xde, 15336946
	ld_rrl	xbc, xde, bc
	inc	1, xbc
	call	16288975
	lda_d16	xwa, 34995
	ld	xbc, 15337848
	call	16289030
	lda_d16	xwa, 34995
	ldw	bc, 16
	calr	-6680
	ld	xwa, (xsp+2)
	ld	xbc, 29360143
	ld	xde, 34994
	call	16423243
	ld	a, (xsp)
	.byte 0x87, 0x81
	ldb_d8	c, 35172
	cp	c, a
	jr	nc, 31
	lda_d16	xwa, 35015
	extz	bc
	.byte 0x87, 0x53
	extz	bc
	lds	de, 1
	calr	-2853
	lda_d16	xde, 35015
	ld	xwa, (xsp+2)
	ld	xbc, 29360143
	call	16423243
	inc	6, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xwa
	ld	a, c
	add	a, c
	cpdm8	35172, a
	jr	c, 49
	lda_d16	xwa, 34994
	ld	(xwa+21), 1
	lda	xiz, (xwa+22)
	call	16293767
	ld	xbc, xhl
	ld	xwa, xiz
	call	16288975
	lda_d16	xwa, 35016
	ldw	bc, 16
	calr	-6792
	lda_d16	xde, 35015
	ld	xwa, (xsp+4)
	ld	xbc, 29360143
	call	16423243
	pop	xiz
	inc	4, xsp
	ret
	dec	6, xsp
	push	xiz
	ld	(xsp+4), c
	ld	(xsp+6), xwa
	lda_d16	xwa, 34994
	ld	(xwa+42), 2
	lda	xwa, (xwa+43)
	ldb_d8	c, 35164
	extz	bc
	sla	bc, 2
	lda_24	xde, 15336996
	ld_rrl	xbc, xde, bc
	inc	1, xbc
	call	16288975
	lda_d16	xwa, 35037
	ld	xbc, 15337852
	call	16289030
	cpdi8	35166, 0
	jr	nz, 65
	ld	e, (xsp+4)
	.byte 0x8f, 0x04, 0x85
	ldb_d8	c, 35172
	lda_d16	xwa, 35037
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
	call	16289030
	lda_d16	xwa, 35037
	ldw	bc, 16
	calr	-6952
	lda_d16	xde, 35036
	ld	xwa, (xsp+6)
	ld	xbc, 29360143
	call	16423243
	cpdi8	35166, 0
	jr	z, 36
	lda_d16	xwa, 34994
	ld	(xwa+63), 3
	lda	xwa, (xwa+64)
	ld	xbc, 15337856
	call	16288975
	lda_d16	xde, 35057
	ld	xwa, (xsp+6)
	ld	xbc, 29360143
	call	16423243
	pop	xiz
	inc	6, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xwa
	cpdi8	35166, 0
	jr	nz, 77
	lda_d16	xwa, 34994
	ld	(xwa+63), 3
	ld	e, c
	add	e, c
	lda	xiz, (xwa+64)
	ldb_d8	a, 35172
	cp	a, e
	jr	c, 14
	sub	a, e
	extz	wa
	call	16293879
	ld	xbc, xhl
	ld	xwa, xiz
	jr	10
	extz	wa
	call	16293644
	ld	xbc, xhl
	ld	xwa, xiz
	call	16288975
	lda_d16	xwa, 35058
	ldw	bc, 16
	calr	-7089
	lda_d16	xde, 35057
	ld	xwa, (xsp+4)
	ld	xbc, 29360143
	call	16423243
	pop	xiz
	inc	4, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	ld	xiz, xwa
	ldb_da	e, (15337874)
	cp	xbc, 29360152
	jr	z, 73
	cp	xbc, 29360151
	jr	z, 65
	cp	xbc, 29360139
	jrl	nz, 704
	ld	xwa, xiz
	ld	c, e
	calr	-537
	ldb_da	c, (15337874)
	ld	xwa, xiz
	calr	-352
	ldb_da	c, (15337874)
	ld	xwa, xiz
	calr	-431
	ldb_da	c, (15337874)
	ld	xwa, xiz
	calr	-169
	lds32	xwa, 0
	stda32	33084, xwa
	stdi8	33088, 0
	stdi8	33090, 0
	jrl	648
	ldb_d8	l, 35172
	ld	xwa, (xsp+4)
	cp	xwa, 5
	jrl	nz, 212
	ld	xde, xbc
	cp	xbc, 29360151
	jr	nz, 72
	ldb_da	c, (15337874)
	ld	w, c
	add	w, c
	ld	a, l
	cp	l, w
	jr	nc, 57
	cp	a, c
	jr	nc, 8
	add	a, c
	stb_d8	35172, a
	jr	4
	stb_d8	35172, w
	ldb_da	c, (15337874)
	ld	xwa, xiz
	calr	-653
	ldb_da	c, (15337874)
	ld	xwa, xiz
	calr	-468
	ldb_da	c, (15337874)
	pushw 0
	pushw 35180
	ld	xwa, (xsp+8)
	ld	xde, 35172
	jr	78
	cp	xde, 29360152
	jr	nz, 83
	ld	c, l
	ldb_da	e, (15337874)
	cp	l, e
	jr	c, 72
	ld	a, e
	add	a, e
	cp	c, a
	jr	nc, 8
	sub	c, e
	stb_d8	35172, c
	jr	4
	stb_d8	35172, e
	ldb_da	c, (15337874)
	ld	xwa, xiz
	calr	-733
	ldb_da	c, (15337874)
	ld	xwa, xiz
	calr	-548
	ldb_da	c, (15337874)
	pushw 0
	pushw 35180
	ld	xwa, (xsp+8)
	ld	xde, 35172
	calr	-857
	stdi8	33090, 1
	stdi8	33088, 1
	ld	xwa, (33084:16)
	.byte 0xaf, 0x04, 0xf0
	jrl	z, 449
	lda_d16	xde, 35015
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16423243
	lda_d16	xde, 35057
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
	cpda8_24 xbc, (15337876)
	jr	nc, 105
	ldb_da	e, (15337874)
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
	stb_d8	35172, c
	ldb_da	c, (15337874)
	ld	xwa, xiz
	calr	-700
	ldb_da	c, (15337874)
	pushw 0
	pushw 35180
	ld	xwa, (xsp+8)
	ld	xde, 35172
	jrl	152
	inc	1, c
	stb_d8	35172, c
	ldb_da	c, (15337874)
	ld	xwa, xiz
	calr	-738
	ldb_da	c, (15337874)
	pushw 0
	pushw 35180
	ld	xwa, (xsp+8)
	ld	xde, 35172
	jr	115
	cp	xde, 29360152
	jr	nz, 115
	ld	c, l
	cps	l, 0
	jr	z, 109
	ldb_da	e, (15337874)
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
	stb_d8	35172, c
	ldb_da	c, (15337874)
	ld	xwa, xiz
	calr	-814
	ldb_da	c, (15337874)
	pushw 0
	pushw 35180
	ld	xwa, (xsp+8)
	ld	xde, 35172
	jr	39
	cp	c, a
	jr	ule, 43
	dec	1, c
	stb_d8	35172, c
	ldb_da	c, (15337874)
	ld	xwa, xiz
	calr	-855
	ldb_da	c, (15337874)
	pushw 0
	pushw 35180
	ld	xwa, (xsp+8)
	ld	xde, 35172
	calr	-1164
	stdi8	33088, 1
	ld	xwa, (33084:16)
	.byte 0xaf, 0x04, 0xf0
	jrl	z, 147
	lda_d16	xde, 35015
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16423243
	lda_d16	xde, 35057
	ld	xwa, xiz
	ld	xbc, 29360143
	jr	54
	ld	xwa, (xsp+4)
	cp	xwa, 7
	jr	z, 8
	cp	xwa, 8
	jr	nz, 48
	ld	xwa, (33084:16)
	.byte 0xaf, 0x04, 0xf0
	jr	z, 91
	lda_d16	xde, 35015
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16423243
	lda_d16	xde, 35057
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16423243
	ld	xwa, (xsp+4)
	stda32	33084, xwa
	jr	52
	ld	xwa, (xsp+4)
	cp	xwa, 40
	jr	nz, 41
	cpdi8	33090, 0
	jr	z, 12
	ld	xwa, xiz
	ld	c, e
	calr	-1081
	stdi8	33090, 0
	cpdi8	33088, 0
	jr	z, 15
	ldb_da	c, (15337874)
	ld	xwa, xiz
	calr	-831
	stdi8	33088, 0
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
	lda_d16	xbc, 34994
	ld	hl, de
	extz	xhl
	add	xhl, xbc
	stb_erp	a, 248
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
	lda_d16	xwa, 34994
	extz	xde
	add	xde, xwa
	ld	xwa, (xsp+2)
	ld	xbc, 29360143
	call	16423243
	inc	1, iz
	cps	iz, 4
	jr	c, -70
	lds32	xhl, 0
	popw	iz
	inc	4, xsp
	ret
SingleLoadSrcFunc:
	dec	4, xsp
	push	xiz
	ld	xiz, xde
	ld	(xsp+4), xbc
	ld	xwa, (xsp+4)
	cp	xwa, 31784963
	jrl	z, 437
	cp	xwa, 29360152
	jr	z, 104
	cp	xwa, 29360151
	jr	z, 96
	cp	xwa, 29360139
	jr	z, 32
	cp	xwa, 31784964
	jrl	nz, 400
	ld	xwa, xiz
	stda32	(33092), xwa
	ld	xbc, 31784962
	ld	xde, 4294967295
	call	16423243
	jrl	377
SLSrc_HandleShow:
	ld	xwa, (33092:16)
	ld	xbc, 31784962
	ld	xde, 4294967295
	call	16423243
	ld	xwa, (33092:16)
	ldb_d8	c, 35164
	extz	bc
	sla	bc, 2
	lda_24	xde, 15337878
	lda_rr	xhl, xde, bc
	ld	xbc, (xsp+4)
	ld	xde, xiz
	ld	xhl, (xhl)
	call (xhl)
	calr	-19652
	jrl	321
SLSrc_HandleScroll:
	cp	xiz, 5
	jr	nz, 73
	cpdi8	35164, 1
	jr	z, 13
	ld	xwa, (33092:16)
	ld	xbc, 31784962
	lds32	xde, 1
	jr	14
SLSrc_ScrollMode5_Prev:
	ld	xwa, (33092:16)
	ld	xbc, 31784962
	ld	xde, 4294967295
SLSrc_ScrollMode5_Dispatch:
	call	16423243
	ld	xwa, (33092:16)
	ldb_d8	c, 35164
	extz	bc
	sla	bc, 2
	lda_24	xde, 15337878
	lda_rr	xhl, xde, bc
	ld	xbc, (xsp+4)
	ld	xde, xiz
	ld	xhl, (xhl)
	call (xhl)
	jrl	240
SLSrc_ScrollMode6:
	cp	xiz, 6
	jr	nz, 80
	cpdi8	35164, 1
	jr	z, 20
	cpdi8	35166, 0
	jr	nz, 13
	ld	xwa, (33092:16)
	ld	xbc, 31784962
	lds32	xde, 3
	jr	14
SLSrc_ScrollMode6_NoStep:
	ld	xwa, (33092:16)
	ld	xbc, 31784962
	ld	xde, 4294967295
SLSrc_ScrollMode6_Dispatch:
	call	ApPostEvent
	ld	xwa, (33092:16)
	ldb_d8	c, (35164)
	extz	bc
	sla	bc, 2
	lda_24	xde, (15337878)
	lda_rr	xhl, xde, bc
	ld	xbc, (xsp+4)
	ld	xde, xiz
	ld	xhl, (xhl)
	call	(xhl)
	jrl	152	; -> 0xF8FC5B
SLSrc_ScrollMode7:
	ld	xwa, (33092:16)
	cp	xiz, 7
	jr	nz, 48	; -> 0xF8FBFF
	ld	xbc, 31784962
	ld	xde, 4294967295
	call	ApPostEvent
	ld	xwa, (33092:16)
	ldb_d8	c, (35164)
	extz	bc
	sla	bc, 2
	lda_24	xde, (15337878)
	lda_rr	xhl, xde, bc
	ld	xbc, (xsp+4)
	ld	xde, xiz
	ld	xhl, (xhl)
	call	(xhl)
	jr	92	; -> 0xF8FC5B
SLSrc_ScrollMode8:
	cp	xiz, 8
	jr	nz, 48	; -> 0xF8FC37
	ld	xbc, 31784962
	ld	xde, 4294967295
	call	ApPostEvent
	ld	xwa, (33092:16)
	ldb_d8	c, (35164)
	extz	bc
	sla	bc, 2
	lda_24	xde, (15337878)
	lda_rr	xhl, xde, bc
	ld	xbc, (xsp+4)
	ld	xde, xiz
	ld	xhl, (xhl)
	call	(xhl)
	jr	36	; -> 0xF8FC5B
SLSrc_ScrollMode40:
	cp	xiz, 40
	jr	nz, 28	; -> 0xF8FC5B
	ldb_d8	c, (35164)
	extz	bc
	sla	bc, 2
	lda_24	xde, (15337878)
	lda_rr	xhl, xde, bc
	ld	xbc, (xsp+4)
	ld	xde, xiz
	ld	xhl, (xhl)
	call	(xhl)
SLSrc_Return:
	lds32 xhl, 0
	jr SLSrc_Epilogue

SLSrc_ReturnCapture:
	ld xhl, 0xffffffff

SLSrc_Epilogue:
	pop xiz
	inc 4, xsp
	ret
SLDstBankList_FuncBody:
	dec	6, xsp
	push	xiz
	ld	(xsp+4), c
	ld	(xsp+6), xwa
	lda_d16	xwa, 35078
	stib_dsp	224, 0
	ldb_d8	c, 35164
	extz	bc
	sla	bc, 2
	lda_24	xde, 15336946
	ld_rrl	xbc, xde, bc
	inc	1, xbc
	call	16288975
	lda_d16	xwa, 35079
	ld	xbc, 15337898
	call	16289030
	lda_d16	xiz, 35079
	ldb_d8	a, 35174
	extz	wa
	.byte 0x8f, 0x04, 0x51
	inc	1, a
	extz	wa
	lds	bc, 0
	calr	-19011
	ld	xbc, xhl
	ld	xwa, xiz
	call	16289030
	lda_d16	xwa, 35079
	ldw	bc, 16
	calr	-8510
	lda_d16	xwa, 35099
	ldb_d8	c, 35174
	extz	bc
	.byte 0x8f, 0x04, 0x53
	extz	bc
	lds	de, 1
	calr	-4886
	lda_d16	xwa, 35100
	ldw	bc, 16
	calr	-8540
	ld	xwa, (xsp+6)
	ld	xbc, 29360143
	ld	xde, 35078
	call	16423243
	lda_d16	xde, 35099
	ld	xwa, (xsp+6)
	ld	xbc, 29360143
	call	16423243
	pop	xiz
	inc	6, xsp
	ret
	dec	6, xsp
	push	xiz
	ld	(xsp+4), c
	ld	(xsp+6), xwa
	lda_d16	xde, 35078
	ld	(xde+42), 2
	ld	(xde+63), 3
	ldb_d8	a, 35164
	extz	wa
	lda_24	xhl, 15336996
	ld	bc, wa
	sla	bc, 2
	lda	xwa, (xde+43)
	ld_rrl	xbc, xhl, bc
	inc	1, xbc
	cpdi8	35166, 0
	jr	z, 42
	call	16288975
	lda_d16	xwa, 35121
	ld	xbc, 15337902
	call	16289030
	lda_d16	xwa, 35121
	ldw	bc, 16
	calr	-8658
	lda_d16	xwa, 35142
	ld	xbc, 15337906
	call	16288975
	jr	74
	call	16288975
	lda_d16	xwa, 35121
	ld	xbc, 15337924
	call	16289030
	lda_d16	xiz, 35121
	ldb_d8	a, 35174
	extz	wa
	.byte 0x8f, 0x04, 0x51
	ld	a, w
	inc	1, a
	extz	wa
	lds	bc, 0
	calr	-19233
	ld	xbc, xhl
	ld	xwa, xiz
	call	16289030
	lda_d16	xwa, 35121
	ldw	bc, 16
	calr	-8732
	lda_d16	xwa, 35141
	ldb_d8	c, 35174
	extz	bc
	lds	de, 3
	calr	-5057
	lda_d16	xde, 35120
	ld	xwa, (xsp+6)
	ld	xbc, 29360143
	call	16423243
	lda_d16	xde, 35141
	ld	xwa, (xsp+6)
	ld	xbc, 29360143
	call	16423243
	pop	xiz
	inc	6, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	ld	xde, xbc
	ld	xiz, xwa
	ldb_da	c, (15337928)
	cp	xde, 29360152
	jr	z, 41
	cp	xde, 29360151
	jr	z, 33
	cp	xde, 29360139
	jrl	nz, 184
	ld	xwa, xiz
	calr	-413
	ldb_da	c, (15337928)
	ld	xwa, xiz
	calr	-261
	lds32	xwa, 0
	stda32	33096, xwa
	jrl	160
	ldb_d8	l, 35174
	ld	xwa, (xsp+4)
	cp	xwa, 7
	jrl	nz, 149
	ld	xix, xde
	cp	xde, 29360151
	jr	nz, 43
	ldb_da	e, (15337928)
	ld	a, e
	ld	c, l
	add	a, l
	cpda8_24 xbc, (15337930)
	jr	nc, 25
	add	c, e
	stb_d8	35174, c
	ldb_da	c, (15337928)
	ld	xwa, xiz
	calr	-492
	ldb_da	c, (15337928)
	ld	xwa, xiz
	jr	42
	cp	xix, 29360152
	jr	nz, 37
	ld	a, l
	ldb_da	c, (15337928)
	cp	l, c
	jr	c, 26
	sub	a, c
	stb_d8	35174, a
	ldb_da	c, (15337928)
	ld	xwa, xiz
	calr	-536
	ldb_da	c, (15337928)
	ld	xwa, xiz
	calr	-384
	ld	xwa, (33096:16)
	.byte 0xaf, 0x04, 0xf0
	jr	z, 37
	lda_d16	xde, 35099
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16423243
	lda_d16	xde, 35141
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16423243
	ld	xwa, (xsp+4)
	stda32	33096, xwa
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
	cpda8_24 xbc, (15337930)
	jr	nc, 36
	ldb_da	e, (15337928)
	ld	l, e
	ld	a, c
	extz	wa
	div8rr	a, l
	ld	a, w
	inc	1, a
	cp	a, e
	jr	nc, 62
	inc	1, c
	stb_d8	35174, c
	ldb_da	c, (15337928)
	ld	xwa, xiz
	jr	44
	cp	xix, 29360152
	jr	nz, 39
	ld	c, l
	cps	l, 0
	jr	z, 33
	ldb_da	e, (15337928)
	ld	a, c
	extz	wa
	div8rr	a, e
	ld	a, w
	cps	a, 0
	jr	z, 16
	dec	1, c
	stb_d8	35174, c
	ldb_da	c, (15337928)
	ld	xwa, xiz
	calr	-553
	ld	xwa, (33096:16)
	.byte 0xaf, 0x04, 0xf0
	jrl	z, -133
	lda_d16	xde, 35099
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16423243
	lda_d16	xde, 35141
	ld	xwa, xiz
	ld	xbc, 29360143
	jrl	-173
	ld	xwa, (xsp+4)
	cp	xwa, 5
	jr	z, 8
	cp	xwa, 6
	jr	nz, 39
	ld	xwa, (33096:16)
	.byte 0xaf, 0x04, 0xf0
	jrl	z, -191
	lda_d16	xde, 35099
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16423243
	lda_d16	xde, 35141
	ld	xwa, xiz
	ld	xbc, 29360143
	jrl	-231
	ld	xwa, (xsp+4)
	cp	xwa, 10
	jrl	nz, -232
	cpdi8	35166, 0
	jr	z, 30
	ldb_d8	a, 35168
	extz	wa
	div8rr	a, c
	extz	wa
	ldb_d8	e, 35174
	extz	de
	div8rr	e, c
	extz	de
	ld	bc, de
	call	16285257
	exts	xhl
	jr	18
	ldb_d8	a, 35168
	extz	wa
	ldb_d8	c, 35174
	extz	bc
	call	16285041
	exts	xhl
	pop	xiz
	inc	4, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xwa
	lda_d16	xwa, 35078
	ld	(xwa+21), 1
	lda	xwa, (xwa+22)
	ldb_d8	c, 35164
	extz	bc
	sla	bc, 2
	lda_24	xde, 15336996
	ld_rrl	xbc, xde, bc
	inc	1, xbc
	call	16288975
	lda_d16	xwa, 35100
	ld	xbc, 15337932
	call	16289030
	lda_d16	xiz, 35100
	ldb_d8	a, 35176
	inc	1, a
	extz	wa
	lds	bc, 0
	calr	-19889
	ld	xbc, xhl
	ld	xwa, xiz
	call	16289030
	lda_d16	xwa, 35100
	ldw	bc, 16
	calr	-9388
	lda_d16	xiz, 35120
	ldb_d8	a, 35176
	extz	wa
	lds	bc, 2
	lds	de, 0
	calr	5520
	ld	xbc, xhl
	ld	xwa, xiz
	call	16288975
	lda_d16	xde, 35099
	ld	xwa, (xsp+4)
	ld	xbc, 29360143
	call	16423243
	lda_d16	xde, 35120
	ld	xwa, (xsp+4)
	ld	xbc, 29360143
	call	16423243
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
	lda_d16	xwa, 35078
	stib_dsp	224, 0
	ld	(xwa), 0
	ldw	bc, 16
	calr	-9493
	lda_d16	xwa, 35078
	ld	(xwa+63), 3
	lda	xwa, (xwa+64)
	ld	(xwa), 0
	ldw	bc, 16
	calr	-9513
	ld	xwa, xiz
	ld	xbc, 29360143
	ld	xde, 35078
	call	16423243
	lda_d16	xde, 35141
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16423243
	ld	xwa, xiz
	jr	47
	ldb_d8	w, 35176
	lda_d16	xhl, 35120
	cp	xde, 8
	jr	nz, 73
	ld	xde, xbc
	cp	xde, 29360151
	jr	nz, 28
	ld	c, w
	ld	a, w
	inc	1, a
	cpda8_24 xbc, (15337936)
	jr	nc, 15
	inc	1, c
	stb_d8	35176, c
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
	stb_d8	35176, a
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
	call	16423243
	jr	-70
	cp	xde, 10
	jr	nz, -78
	ldb_d8	a, 35176
	extz	wa
	call	16285545
	exts	xhl
	pop	xiz
	ret
	dec	2, xsp
	push	xiz
	ld	(xsp+4), c
	ld	xiz, xwa
	lda_d16	xwa, 35078
	stib_dsp	224, 0
	ldb_d8	c, 35164
	extz	bc
	sla	bc, 2
	lda_24	xde, 15336946
	ld_rrl	xbc, xde, bc
	inc	1, xbc
	call	16288975
	lda_d16	xwa, 35079
	ld	xbc, 15337938
	call	16289030
	lda_d16	xwa, 35079
	ldw	bc, 16
	calr	-9754
	lda_d16	xwa, 35099
	ldb_d8	c, 35178
	extz	bc
	.byte 0x8f, 0x04, 0x53
	extz	bc
	lds	de, 1
	calr	-6036
	ld	xwa, xiz
	ld	xbc, 29360143
	ld	xde, 35078
	call	16423243
	lda_d16	xde, 35099
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16423243
	pop	xiz
	inc	2, xsp
	ret
	dec	6, xsp
	push	xiz
	ld	(xsp+4), c
	ld	(xsp+6), xwa
	lda_d16	xwa, 35078
	ld	(xwa+42), 2
	lda	xwa, (xwa+43)
	ldb_d8	c, 35164
	extz	bc
	sla	bc, 2
	lda_24	xde, 15336996
	ld_rrl	xbc, xde, bc
	inc	1, xbc
	call	16288975
	lda_d16	xwa, 35121
	ld	xbc, 15337942
	call	16289030
	cpdi8	35166, 0
	jr	nz, 28
	lda_d16	xiz, 35121
	ldb_d8	a, 35178
	extz	wa
	.byte 0x8f, 0x04, 0x51
	ld	a, w
	extz	wa
	calr	-6118
	ld	xbc, xhl
	ld	xwa, xiz
	call	16289030
	lda_d16	xwa, 35121
	ldw	bc, 16
	calr	-9912
	lda_d16	xbc, 35078
	lda	xwa, (xbc+63)
	cpdi8	35166, 0
	jr	z, 17
	ld	(xwa), 3
	lda	xwa, (xbc+64)
	ld	xbc, 15337946
	call	16288975
	jr	28
	ldb_d8	e, 35178
	ld	c, e
	extz	bc
	.byte 0x8f, 0x04, 0x53
	extz	bc
	extz	de
	.byte 0x8f, 0x04, 0x55
	ld	e, d
	extz	de
	pushw 3
	calr	-6180
	lda_d16	xde, 35120
	ld	xwa, (xsp+6)
	ld	xbc, 29360143
	call	16423243
	lda_d16	xde, 35141
	ld	xwa, (xsp+6)
	ld	xbc, 29360143
	call	16423243
	pop	xiz
	inc	6, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	ld	xde, xbc
	ld	xiz, xwa
	ldb_da	c, (15337964)
	cp	xde, 29360152
	jr	z, 41
	cp	xde, 29360151
	jr	z, 33
	cp	xde, 29360139
	jrl	nz, 184
	ld	xwa, xiz
	calr	-362
	ldb_da	c, (15337964)
	ld	xwa, xiz
	calr	-253
	lds32	xwa, 0
	stda32	33100, xwa
	jrl	160
	ldb_d8	l, 35178
	ld	xwa, (xsp+4)
	cp	xwa, 7
	jrl	nz, 149
	ld	xix, xde
	cp	xde, 29360151
	jr	nz, 43
	ldb_da	e, (15337964)
	ld	a, e
	ld	c, l
	add	a, l
	cpda8_24 xbc, (15337966)
	jr	nc, 25
	add	c, e
	stb_d8	35178, c
	ldb_da	c, (15337964)
	ld	xwa, xiz
	calr	-441
	ldb_da	c, (15337964)
	ld	xwa, xiz
	jr	42
	cp	xix, 29360152
	jr	nz, 37
	ld	a, l
	ldb_da	c, (15337964)
	cp	l, c
	jr	c, 26
	sub	a, c
	stb_d8	35178, a
	ldb_da	c, (15337964)
	ld	xwa, xiz
	calr	-485
	ldb_da	c, (15337964)
	ld	xwa, xiz
	calr	-376
	ld	xwa, (33100:16)
	.byte 0xaf, 0x04, 0xf0
	jr	z, 37
	lda_d16	xde, 35099
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16423243
	lda_d16	xde, 35141
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16423243
	ld	xwa, (xsp+4)
	stda32	33100, xwa
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
	cpda8_24 xbc, (15337966)
	jr	nc, 36
	ldb_da	e, (15337964)
	ld	l, e
	ld	a, c
	extz	wa
	div8rr	a, l
	ld	a, w
	inc	1, a
	cp	a, e
	jr	nc, 62
	inc	1, c
	stb_d8	35178, c
	ldb_da	c, (15337964)
	ld	xwa, xiz
	jr	44
	cp	xix, 29360152
	jr	nz, 39
	ld	c, l
	cps	l, 0
	jr	z, 33
	ldb_da	e, (15337964)
	ld	a, c
	extz	wa
	div8rr	a, e
	ld	a, w
	cps	a, 0
	jr	z, 16
	dec	1, c
	stb_d8	35178, c
	ldb_da	c, (15337964)
	ld	xwa, xiz
	calr	-545
	ld	xwa, (33100:16)
	.byte 0xaf, 0x04, 0xf0
	jrl	z, -133
	lda_d16	xde, 35099
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16423243
	lda_d16	xde, 35141
	ld	xwa, xiz
	ld	xbc, 29360143
	jrl	-173
	ld	xwa, (xsp+4)
	cp	xwa, 5
	jr	z, 8
	cp	xwa, 6
	jr	nz, 39
	ld	xwa, (33100:16)
	.byte 0xaf, 0x04, 0xf0
	jrl	z, -191
	lda_d16	xde, 35099
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16423243
	lda_d16	xde, 35141
	ld	xwa, xiz
	ld	xbc, 29360143
	jrl	-231
	ld	xwa, (xsp+4)
	cp	xwa, 10
	jrl	nz, -232
	cpdi8	35166, 0
	jr	z, 30
	ldb_d8	a, 35170
	extz	wa
	div8rr	a, c
	add	a, 30
	extz	wa
	ldb_d8	e, 35178
	extz	de
	div8rr	e, c
	add	e, 30
	extz	de
	ld	bc, de
	jr	12
	ldb_d8	a, 35170
	extz	wa
	ldb_d8	c, 35178
	extz	bc
	call	16285775
	exts	xhl
	pop	xiz
	inc	4, xsp
	ret
	dec	6, xsp
	ld	(xsp), c
	ld	(xsp+2), xwa
	lda_d16	xwa, 35078
	stib_dsp	224, 0
	ldb_d8	c, 35164
	extz	bc
	sla	bc, 2
	lda_24	xde, 15336946
	ld_rrl	xbc, xde, bc
	inc	1, xbc
	call	16288975
	lda_d16	xwa, 35079
	ld	xbc, 15337968
	call	16289030
	lda_d16	xwa, 35079
	ldw	bc, 16
	calr	-10585
	ld	e, (xsp)
	.byte 0x87, 0x85
	ldb_d8	c, 35180
	lda_d16	xwa, 35099
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
	ld	xde, 35078
	call	16423243
	lda_d16	xde, 35099
	ld	xwa, (xsp+2)
	ld	xbc, 29360143
	call	16423243
	inc	6, xsp
	ret
	dec	6, xsp
	push	xiz
	ld	(xsp+4), c
	ld	(xsp+6), xwa
	lda_24	xde, 15336996
	cpdi8	35166, 0
	jr	z, 77
	lda_d16	xwa, 35078
	ld	(xwa+42), 2
	lda	xwa, (xwa+43)
	ldb_d8	c, 35164
	extz	bc
	sla	bc, 2
	ld_rrl	xbc, xde, bc
	inc	1, xbc
	call	16288975
	lda_d16	xwa, 35121
	ld	xbc, 15337972
	call	16289030
	lda_d16	xwa, 35121
	ldw	bc, 16
	calr	-10730
	lda_d16	xwa, 35078
	ld	(xwa+63), 3
	lda	xwa, (xwa+64)
	ld	xbc, 15337976
	call	16288975
	jrl	214
	ld	l, (xsp+4)
	.byte 0x8f, 0x04, 0x87
	lda_d16	xbc, 35078
	lda	xwa, (xbc+43)
	ld	(xbc+42), 2
	cpdm8	35180, l
	jr	c, 101
	ldb_d8	c, 35164
	extz	bc
	sla	bc, 2
	ld_rrl	xbc, xde, bc
	inc	1, xbc
	call	16288975
	lda_d16	xwa, 35121
	ld	xbc, 15337994
	call	16289030
	lda_d16	xiz, 35121
	ld	c, (xsp+4)
	.byte 0x8f, 0x04, 0x83
	ldb_d8	a, 35180
	sub	a, c
	inc	1, a
	extz	wa
	lds	bc, 0
	calr	-21353
	ld	xbc, xhl
	ld	xwa, xiz
	call	16289030
	lda_d16	xwa, 35121
	ldw	bc, 16
	calr	-10852
	lda_d16	xwa, 35141
	ld	e, (xsp+4)
	.byte 0x8f, 0x04, 0x85
	ldb_d8	c, 35180
	sub	c, e
	extz	bc
	lds	de, 3
	calr	-6885
	jr	90
	ldb_d8	c, 35164
	extz	bc
	sla	bc, 2
	ld_rrl	xbc, xde, bc
	inc	1, xbc
	call	16288975
	lda_d16	xwa, 35121
	ld	xbc, 15337998
	call	16289030
	lda_d16	xiz, 35121
	ldb_d8	a, 35180
	extz	wa
	.byte 0x8f, 0x04, 0x51
	ld	a, w
	inc	1, a
	extz	wa
	lds	bc, 0
	calr	-21453
	ld	xbc, xhl
	ld	xwa, xiz
	call	16289030
	lda_d16	xwa, 35121
	ldw	bc, 16
	calr	-10952
	lda_d16	xwa, 35141
	ldb_d8	c, 35180
	extz	bc
	lds	de, 3
	calr	-7058
	lda_d16	xde, 35120
	ld	xwa, (xsp+6)
	ld	xbc, 29360143
	call	16423243
	lda_d16	xde, 35141
	ld	xwa, (xsp+6)
	ld	xbc, 29360143
	call	16423243
	pop	xiz
	inc	6, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	ld	xiz, xwa
	ldb_da	e, (15338002)
	cp	xbc, 29360152
	jr	z, 43
	cp	xbc, 29360151
	jr	z, 35
	cp	xbc, 29360139
	jrl	nz, 255
	ld	xwa, xiz
	ld	c, e
	calr	-526
	ldb_da	c, (15338002)
	ld	xwa, xiz
	calr	-403
	lds32	xwa, 0
	stda32	33104, xwa
	jrl	229
	ldb_d8	l, 35180
	ld	xwa, (xsp+4)
	cp	xwa, 7
	jrl	nz, 218
	ld	xde, xbc
	cp	xbc, 29360151
	jr	nz, 72
	ldb_da	c, (15338002)
	ld	w, c
	add	w, c
	ld	a, l
	cp	l, w
	jr	nc, 57
	cp	a, c
	jr	nc, 8
	add	a, c
	stb_d8	35180, a
	jr	4
	stb_d8	35180, w
	ldb_da	c, (15338002)
	ld	xwa, xiz
	calr	-612
	ldb_da	c, (15338002)
	ld	xwa, xiz
	calr	-489
	ldb_da	c, (15338002)
	pushw 0
	pushw 35180
	ld	xwa, (xsp+8)
	ld	xde, 35172
	jr	82
	cp	xde, 29360152
	jr	nz, 77
	ld	c, l
	ldb_da	e, (15338002)
	cp	l, e
	jr	c, 66
	ld	a, e
	add	a, e
	cp	c, a
	jr	nc, 8
	sub	c, e
	stb_d8	35180, c
	jr	8
	cp	c, a
	jr	c, 4
	stb_d8	35180, e
	ldb_da	c, (15338002)
	ld	xwa, xiz
	calr	-696
	ldb_da	c, (15338002)
	ld	xwa, xiz
	calr	-573
	ldb_da	c, (15338002)
	pushw 0
	pushw 35180
	ld	xwa, (xsp+8)
	ld	xde, 35172
	calr	-4725
	ld	xwa, (33104:16)
	.byte 0xaf, 0x04, 0xf0
	jr	z, 37
	lda_d16	xde, 35099
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16423243
	lda_d16	xde, 35141
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16423243
	ld	xwa, (xsp+4)
	stda32	33104, xwa
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
	cpda8_24 xbc, (15338004)
	jr	nc, 105
	ldb_da	e, (15338002)
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
	stb_d8	35180, c
	ldb_da	c, (15338002)
	ld	xwa, xiz
	calr	-727
	ldb_da	c, (15338002)
	pushw 0
	pushw 35180
	ld	xwa, (xsp+8)
	ld	xde, 35172
	jrl	152
	inc	1, c
	stb_d8	35180, c
	ldb_da	c, (15338002)
	ld	xwa, xiz
	calr	-765
	ldb_da	c, (15338002)
	pushw 0
	pushw 35180
	ld	xwa, (xsp+8)
	ld	xde, 35172
	jr	115
	cp	xde, 29360152
	jr	nz, 110
	ld	c, l
	cps	l, 0
	jr	z, 104
	ldb_da	e, (15338002)
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
	stb_d8	35180, c
	ldb_da	c, (15338002)
	ld	xwa, xiz
	calr	-841
	ldb_da	c, (15338002)
	pushw 0
	pushw 35180
	ld	xwa, (xsp+8)
	ld	xde, 35172
	jr	39
	cp	c, a
	jr	ule, 38
	dec	1, c
	stb_d8	35180, c
	ldb_da	c, (15338002)
	ld	xwa, xiz
	calr	-882
	ldb_da	c, (15338002)
	pushw 0
	pushw 35180
	ld	xwa, (xsp+8)
	ld	xde, 35172
	calr	-5034
	ld	xwa, (33104:16)
	.byte 0xaf, 0x04, 0xf0
	jrl	z, -273
	lda_d16	xde, 35099
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16423243
	lda_d16	xde, 35141
	ld	xwa, xiz
	ld	xbc, 29360143
	jrl	-313
	ld	xwa, (xsp+4)
	cp	xwa, 5
	jr	z, 8
	cp	xwa, 6
	jr	nz, 39
	ld	xwa, (33104:16)
	.byte 0xaf, 0x04, 0xf0
	jrl	z, -331
	lda_d16	xde, 35099
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16423243
	lda_d16	xde, 35141
	ld	xwa, xiz
	ld	xbc, 29360143
	jrl	-371
	ld	xwa, (xsp+4)
	cp	xwa, 10
	jrl	nz, -372
	cpdi8	35166, 0
	jr	z, 28
	ldb_d8	a, 35172
	extz	wa
	div8rr	a, e
	extz	wa
	ldb_d8	c, 35180
	extz	bc
	div8rr	c, e
	extz	bc
	call	16286237
	exts	xhl
	jr	18
	ldb_d8	a, 35172
	extz	wa
	ldb_d8	c, 35180
	extz	bc
	call	16285895
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
	lda_d16	xbc, 35078
	ld	hl, de
	extz	xhl
	add	xhl, xbc
	stb_erp	a, 248
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
	lda_d16	xwa, 35078
	extz	xde
	add	xde, xwa
	ld	xwa, (xsp+2)
	ld	xbc, 29360143
	call	16423243
	inc	1, iz
	cps	iz, 4
	jr	c, -70
	lds32	xhl, 0
	popw	iz
	inc	4, xsp
	ret
SingleLoadDstFunc:
	dec	8, xsp
	push	xiz
	ld	(xsp+4), xde
	ld	(xsp+8), xbc
	ld	xiz, xwa
	ld	xwa, (xsp+8)
	cp	xwa, 31784963
	jrl	z, 1197
	cp	xwa, 29360152
	jrl	z, 322
	cp	xwa, 29360151
	jrl	z, 313
	cp	xwa, 29360143
	jrl	z, 249
	cp	xwa, 29360139
	jr	z, 116
	cp	xwa, 31784964
	jr	nz, 103
	ld	xwa, (xsp+4)
	stda32	33108, xwa
	lds	wa, 0
	calr	-23561
	calr	-23472
	calr	-8544
	calr	-23478
	cpdi8	35164, 1
	jr	z, 14
	ld	xwa, 6357066
	ld	xbc, 31457436
	lds32	xde, 1
	jr	12
SLDst_ShowHide_Internal:
	ld xwa, 0x61004a
	ld xbc, 0x1e0009c
	lds32 xde, 0

SLDst_ShowHide_Dispatch:
	call	16423243
	ld	xwa, (33108:16)
	ld	xbc, 31784962
	ld	xde, 4294967295
	call	16423243
	cpdi8	35164, 0
	jr	nz, 15
	call	16281577
	cps	hl, 0
	jr	z, 7
	stdi8	35182, 1
	jr	5
SLDst_ClearFloppyFlag:
	stdi8	(35182), 0
SLDst_Return:
	lds32 xhl, 0
	jrl SLDst_Epilogue
SLDst_HandleShow:
	ld	xwa, xiz
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	calr	-7966
	ld	xwa, xiz
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	calr	-7782
	ld	xwa, xiz
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	calr	-7715
	ld	xwa, xiz
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	calr	-7942
	ld	xwa, xiz
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	calr	-7896
	ld	xwa, (33108:16)
	ld	xbc, 31784962
	ld	xde, 4294967295
	call	16423243
	ld	xwa, 6357046
	ld	xbc, 31457339
	lds32	xde, 0
	call	16423243
	ld	xwa, (33108:16)
	ldb_d8	c, 35164
	extz	bc
	sla	bc, 2
	lda_24	xde, 15338006
	lda_rr	xhl, xde, bc
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	ld	xhl, (xhl)
	call (xhl)
	jrl	-130
SLDst_HandleConfirm:
	ld	xwa, (33108:16)
	ld	xbc, 31784962
	ld	xde, 4294967295
	call	16423243
	ld	xwa, (33108:16)
	ldb_d8	c, 35164
	extz	bc
	sla	bc, 2
	lda_24	xde, 15338006
	lda_rr	xhl, xde, bc
	ld	xbc, 29360139
	lds32	xde, 0
	ld	xhl, (xhl)
	call (xhl)
	jrl	-185
SLDst_HandleScroll:
	ld	xwa, (xsp+4)
	cp	xwa, 3
	jr	nz, 126
	cpdi8	35164, 1
	jr	z, 119
	ld	xwa, (xsp+8)
	cp	xwa, 29360151
	scc	z, a
	stb_d8	35166, a
	ld	xwa, xiz
	ld	xbc, 29360139
	lds32	xde, 0
	calr	-7907
	ld	xwa, xiz
	ld	xbc, 29360139
	lds32	xde, 0
	calr	-8078
	ld	xwa, (33108:16)
	ld	xbc, 31784962
	ld	xde, 4294967295
	call	16423243
	ld	xwa, 6357046
	ld	xbc, 31457339
	lds32	xde, 0
	call	16423243
	ld	xwa, (33108:16)
	ldb_d8	c, 35164
	extz	bc
	sla	bc, 2
	lda_24	xde, 15338006
	lda_rr	xhl, xde, bc
	ld	xbc, 29360139
	lds32	xde, 0
	ld	xhl, (xhl)
	call (xhl)
	ld	xwa, xiz
	ld	xbc, 29360139
	lds32	xde, 0
	jrl	194
SLDst_ScrollMode4:
	ld	xwa, (xsp+4)
	cp	xwa, 4
	jrl	nz, 188
	calr	-8758
	cps	l, 0
	jrl	z, -342
	cpdi8	35164, 1
	jr	z, 14
	ld	xwa, 6357066
	ld	xbc, 31457436
	lds32	xde, 1
	jr	12
SLDst_ScrollMode4_Internal:
	ld xwa, 0x61004a
	ld xbc, 0x1e0009c
	lds32 xde, 0

SLDst_ScrollMode4_Dispatch:
	call	ApPostEvent
	ld	xwa, xiz
	ld	xbc, 29360139
	lds32	xde, 0
	calr	57195
	ld	xwa, xiz
	ld	xbc, 29360139
	lds32	xde, 0
	calr	57378
	ld	xwa, xiz
	ld	xbc, 29360139
	lds32	xde, 0
	calr	57444
	ld	xwa, xiz
	ld	xbc, 29360139
	lds32	xde, 0
	calr	57216
	ld	xwa, xiz
	ld	xbc, 29360139
	lds32	xde, 0
	calr	57261
	ld	xwa, (33108:16)
	ld	xbc, 31784962
	ld	xde, 4294967295
	call	ApPostEvent
	ld	xwa, 6357046
	ld	xbc, 31457339
	lds32	xde, 0
	call	ApPostEvent
	ld	xwa, (33108:16)
	ldb_d8	c, (35164)
	extz	bc
	sla	bc, 2
	lda_24	xde, (15338006)
	lda_rr	xhl, xde, bc
	ld	xbc, 29360139
	lds32	xde, 0
	ld	xhl, (xhl)
	call	(xhl)
	ld	xwa, xiz
	ld	xbc, 29360139
	lds32	xde, 0
SLDst_ScrollMode3_CallSrcMem:
	calr SingleLoadSrcFunc
	jrl SLDst_Return
SLDst_ScrollDispatch:
	ld	xwa, (xsp+4)
	cp	xwa, 10
	jr	nz, 98
	cpdi8	35164, 4
	jr	z, 91
	ld	xwa, 6291494
	ld	xbc, 29360129
	lds32	xde, 5
	call	16423243
	lds	wa, 0
	calr	-24213
	ld	xwa, (33108:16)
	ldb_d8	c, 35164
	extz	bc
	sla	bc, 2
	lda_24	xde, 15338006
	lda_rr	xhl, xde, bc
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	ld	xix, (xhl)
	call (xix)
	ld	wa, hl
	lds	bc, 1
	calr	-23603
	stb_d8	32422, l
	ld	xwa, 6291494
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	ldw	wa, 238
	call	16355504
	jrl	-631
SLDst_Scroll_ChildReturn:
	ld	xwa, (xsp+4)
	cp	xwa, 7
	jr	nz, 112
	cpdi8	35164, 1
	jr	z, 51
	ld	xwa, (33108:16)
	ld	xbc, 31784962
	lds32	xde, 1
	call	16423243
	ld	xwa, (33108:16)
	ldb_d8	c, 35164
	extz	bc
	sla	bc, 2
	lda_24	xde, 15338006
	lda_rr	xhl, xde, bc
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	ld	xhl, (xhl)
	call (xhl)
	jrl	-700
SLDst_Scroll_SubMode:
	ld	xwa, (33108:16)
	ld	xbc, 31784962
	ld	xde, 4294967295
	call	16423243
	ld	xwa, (33108:16)
	ldb_d8	c, 35164
	extz	bc
	sla	bc, 2
	lda_24	xde, 15338006
	lda_rr	xhl, xde, bc
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	ld	xhl, (xhl)
	call (xhl)
	jrl	-754
SLDst_Scroll_SubMode2:
	ld	xwa, (33108:16)
	ld	xbc, (xsp+4)
	cp	xbc, 8
	jrl	nz, 158
	cpdi8	35164, 1
	jr	nz, 47
	ld	xbc, 31784962
	lds32	xde, 2
	call	16423243
	ld	xwa, (33108:16)
	ldb_d8	c, 35164
	extz	bc
	sla	bc, 2
	lda_24	xde, 15338006
	lda_rr	xhl, xde, bc
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	ld	xhl, (xhl)
	call (xhl)
	jrl	-824
SLDst_Scroll_SubMode3:
	cpdi8	35166, 0
	jr	nz, 47
	ld	xbc, 31784962
	lds32	xde, 3
	call	16423243
	ld	xwa, (33108:16)
	ldb_d8	c, 35164
	extz	bc
	sla	bc, 2
	lda_24	xde, 15338006
	lda_rr	xhl, xde, bc
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	ld	xhl, (xhl)
	call (xhl)
	jrl	-878
SLDst_Scroll_SubMode4:
	ld	xbc, 31784962
	ld	xde, 4294967295
	call	16423243
	ld	xwa, (33108:16)
	ldb_d8	c, 35164
	extz	bc
	sla	bc, 2
	lda_24	xde, 15338006
	lda_rr	xhl, xde, bc
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	ld	xhl, (xhl)
	call (xhl)
	jrl	-928
SLDst_Scroll_SubMode5:
	ld	xbc, (xsp+4)
	cp	xbc, 5
	jr	nz, 50
	ld	xbc, 31784962
	ld	xde, 4294967295
	call	16423243
	ld	xwa, (33108:16)
	ldb_d8	c, 35164
	extz	bc
	sla	bc, 2
	lda_24	xde, 15338006
	lda_rr	xhl, xde, bc
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	ld	xhl, (xhl)
	call (xhl)
	jrl	-989
SLDst_Scroll_SubMode6:
	ld	xbc, (xsp+4)
	cp	xbc, 6
	jrl	nz, -1001
	ld	xbc, 31784962
	ld	xde, 4294967295
	call	16423243
	ld	xwa, (33108:16)
	ldb_d8	c, 35164
	extz	bc
	sla	bc, 2
	lda_24	xde, 15338006
	lda_rr	xhl, xde, bc
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	ld	xhl, (xhl)
	call (xhl)
	jrl	-1051
SLDst_ReturnCapture:
	ld xhl, 0xffffffff

SLDst_Epilogue:
	pop xiz
	inc 8, xsp
	ret

CmpSingleLoadSrcFunc:
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	ld	xiz, xbc
	cp	xiz, 31784963
	jrl	z, 464
	cp	xiz, 29360152
	jr	z, 102
	cp	xiz, 29360151
	jr	z, 94
	cp	xiz, 29360139
	jr	z, 33
	cp	xiz, 31784964
	jrl	nz, 427
	ld	xwa, (xsp+4)
	stda32	(33112), xwa
	ld	xbc, 31784962
	ld	xde, 4294967295
	call	16423243
	jrl	403
CmpSrc_HandleShow:
	ld	xwa, (33112:16)
	ld	xbc, 31784962
	ld	xde, 4294967295
	call	ApPostEvent
	ld	xwa, (33112:16)
	ldb_d8	c, (35164)
	extz	bc
	sla	bc, 2
	lda_24	xde, (15338026)
	lda_rr	xhl, xde, bc
	ld	xbc, xiz
	ld	xde, (xsp+4)
	ld	xhl, (xhl)
	call	(xhl)
	jrl	350	; -> 0xF9105C
CmpSrc_HandleScroll:
	ld	xwa, (xsp+4)
	cp	xwa, 5
	jr	nz, 50	; -> 0xF90F3B
	ld	xwa, (33112:16)
	ld	xbc, 31784962
	lds32	xde, 1
	call	ApPostEvent
	ld	xwa, (33112:16)
	ldb_d8	c, (35164)
	extz	bc
	sla	bc, 2
	lda_24	xde, (15338026)
	lda_rr	xhl, xde, bc
	ld	xbc, xiz
	ld	xde, (xsp+4)
	ld	xhl, (xhl)
	call	(xhl)
	jrl	289	; -> 0xF9105C
CmpSrc_ScrollMode6:
	.byte 0xaf, 0x04, 0x20, 0xe8, 0xcf, 0x06, 0x00, 0x00
	.byte 0x00, 0x6e, 0x6e, 0xc1, 0x5e, 0x89, 0x3f, 0x00
	.byte 0x6e, 0x32, 0xe1, 0x58, 0x81, 0x20, 0x41, 0x02
	.byte 0x00, 0xe5, 0x01, 0xea, 0xab, 0x1d, 0x4b, 0x99
	.byte 0xfa, 0xe1, 0x58, 0x81, 0x20, 0xc1, 0x5c, 0x89
	.byte 0x23, 0xd9, 0x12, 0xd9, 0xec, 0x02, 0xf2, 0x2a
	.byte 0x0a, 0xea, 0x32, 0xf3, 0x07, 0xe8, 0xe4, 0x33
	.byte 0xee, 0x89, 0xaf, 0x04, 0x22, 0xa3, 0x23, 0xb3
	.byte 0xe8, 0x78, 0xdd, 0x00
CmpSrc_ScrollMode6_NoStep:
	ld	xwa, (33112:16)
	ld	xbc, 31784962
	ld	xde, 4294967295
	call	ApPostEvent
	ld	xwa, (33112:16)
	ldb_d8	c, (35164)
	extz	bc
	sla	bc, 2
	lda_24	xde, (15338026)
	lda_rr	xhl, xde, bc
	ld	xbc, xiz
	ld	xde, (xsp+4)
	ld	xhl, (xhl)
	call	(xhl)
	jrl	168	; -> 0xF9105C
CmpSrc_ScrollMode7:
	ld	xwa, (33112:16)
	ld	xbc, (xsp+4)
	cp	xbc, 7
	jr	nz, 48	; -> 0xF90FF3
	ld	xbc, 31784962
	ld	xde, 4294967295
	call	ApPostEvent
	ld	xwa, (33112:16)
	ldb_d8	c, (35164)
	extz	bc
	sla	bc, 2
	lda_24	xde, (15338026)
	lda_rr	xhl, xde, bc
	ld	xbc, xiz
	ld	xde, (xsp+4)
	ld	xhl, (xhl)
	call	(xhl)
	jr	105	; -> 0xF9105C
CmpSrc_ScrollMode8:
	.byte 0xaf, 0x04, 0x21, 0xe9, 0xcf, 0x08, 0x00, 0x00
	.byte 0x00, 0x6e, 0x37, 0xc1, 0x5e, 0x89, 0x3f, 0x00
	.byte 0x6e, 0x30, 0x41, 0x02, 0x00, 0xe5, 0x01, 0x42
	.byte 0xff, 0xff, 0xff, 0xff, 0x1d, 0x4b, 0x99, 0xfa
	.byte 0xe1, 0x58, 0x81, 0x20, 0xc1, 0x5c, 0x89, 0x23
	.byte 0xd9, 0x12, 0xd9, 0xec, 0x02, 0xf2, 0x2a, 0x0a
	.byte 0xea, 0x32, 0xf3, 0x07, 0xe8, 0xe4, 0x33, 0xee
	.byte 0x89, 0xaf, 0x04, 0x22, 0xa3, 0x23, 0xb3, 0xe8
	.byte 0x68, 0x27
CmpSrc_ScrollMode40:
	ld	xbc, (xsp+4)
	cp	xbc, 40
	jr	nz, 28	; -> 0xF9105C
	ldb_d8	c, (35164)
	extz	bc
	sla	bc, 2
	lda_24	xde, (15338026)
	lda_rr	xhl, xde, bc
	ld	xbc, xiz
	ld	xde, (xsp+4)
	ld	xhl, (xhl)
	call	(xhl)
CmpSrc_Return:
	lds32 xhl, 0
	jr CmpSrc_Epilogue

CmpSrc_ReturnCapture:
	ld xhl, 0xffffffff

CmpSrc_Epilogue:
	pop xiz
	inc 4, xsp
	ret

CmpSingleLoadDstFunc:
	dec	8, xsp
	push	xiz
	ld	(xsp+4), xde
	ld	(xsp+8), xbc
	ld	xiz, xwa
	ld	xwa, (xsp+8)
	cp	xwa, 31784963
	jrl	z, 724
	cp	xwa, 29360152
	jrl	z, 164
	cp	xwa, 29360151
	jrl	z, 155
	cp	xwa, 29360139
	jr	z, 33
	cp	xwa, 31784964
	jrl	nz, 685
	ld	xwa, (xsp+4)
	stda32	(33116), xwa
	ld	xbc, 31784962
	ld	xde, 4294967295
	call	16423243
	jrl	661
CmpDst_HandleShow:
	ld	xwa, xiz
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	calr	56216
	ld	xwa, xiz
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	calr	56127
	ld	xwa, xiz
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	calr	56035
	ld	xwa, xiz
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	calr	55967
	ld	xwa, (33116:16)
	ld	xbc, 31784962
	ld	xde, 4294967295
	call	ApPostEvent
	ld	xwa, 6357118
	ld	xbc, 31457339
	lds32	xde, 0
	call	ApPostEvent
	ld	xwa, (33116:16)
	ldb_d8	c, (35164)
	extz	bc
	sla	bc, 2
	lda_24	xde, (15338046)
	lda_rr	xhl, xde, bc
	ld	xbc, (xsp+8)
	ld	xde, (xsp+4)
	ld	xhl, (xhl)
	call	(xhl)
	jrl	547	; -> 0xF91350
CmpDst_HandleScroll:
	ld XWA,(XSP+0x04)
	cp XWA,0x00000003
	jr nz, .Lc_f911b2
	ld XWA,(XSP+0x08)
	cp XWA,0x01c00017
	scc Z,A
	stb_d8 (0x895e), a
	ld XWA,XIZ
	ld XBC,0x01c0000b
	lds32 xde, 0
	calr SingleLoadSrcMemFunc
	ld XWA,XIZ
	ld XBC,0x01c0000b
	lds32 xde, 0
	calr SingleLoadDstMemFunc
	ld xwa, (0x815c:16)
	ld XBC,0x01e50002
	ld XDE,0xffffffff
	call ApPostEvent
	ld XWA,0x0061007e
	ld XBC,0x01e0003b
	lds32 xde, 0
	call ApPostEvent
	ld xwa, (0x815c:16)
	ldb_d8 c, (0x895c)
	extz BC
	sla BC, 0x02
	lda_24 xde, (Data_SaveLoadMenuTable_0x4E)
	lda_dri xhl, 0x07, 0xe8, 0xe4
	ld XBC,0x01c0000b
	lds32 xde, 0
	ld XHL,(XHL)
	call (XHL)
	ld XWA,XIZ
	ld XBC,0x01c0000b
	lds32 xde, 0
	calr CmpSingleLoadSrcFunc
	jrl t, CmpDst_Return
CmpDst_ScrollModeA:
.Lc_f911b2:
	ld XWA,(XSP+0x04)
	cp XWA,0x0000000a
	jr nz, .Lc_f9121f
	cpdi8 (0x895c), 0x04
	jr z, .Lc_f9121f
	ld XWA,0x00600026
	ld XBC,0x01c00001
	lds32 xde, 5
	call ApPostEvent
	lds wa, 0
	calr InitializeOperationState
	ld xwa, (0x815c:16)
	ldb_d8 c, (0x895c)
	extz BC
	sla BC, 0x02
	lda_24 xde, (Data_SaveLoadMenuTable_0x4E)
	lda_dri xhl, 0x07, 0xe8, 0xe4
	ld XBC,(XSP+0x08)
	ld XDE,(XSP+0x04)
	ld XIX,(XHL)
	call (XIX)
	ld WA,HL
	lds bc, 1
	calr FileIO_ValidateSignedValue
	stb_d8 (0x7ea6), l
	ld XWA,0x00600026
	ld XBC,0x01c00002
	lds32 xde, 0
	call ApPostEvent
	ldw WA, 0x00ee
	call SoundCtrl_SendCommand
	jrl t, CmpDst_Return
CmpDst_ScrollMode7:
.Lc_f9121f:
	ld XWA,(XSP+0x04)
	cp XWA,0x00000007
	jr nz, .Lc_f9125d
	ld xwa, (0x815c:16)
	ld XBC,0x01e50002
	lds32 xde, 1
	call ApPostEvent
	ld xwa, (0x815c:16)
	ldb_d8 c, (0x895c)
	extz BC
	sla BC, 0x02
	lda_24 xde, (Data_SaveLoadMenuTable_0x4E)
	lda_dri xhl, 0x07, 0xe8, 0xe4
	ld XBC,(XSP+0x08)
	ld XDE,(XSP+0x04)
	ld XHL,(XHL)
	call (XHL)
	jrl t, CmpDst_Return
CmpDst_ScrollMode8:
.Lc_f9125d:
	ld xwa, (0x815c:16)
	ld XBC,(XSP+0x04)
	cp XBC,0x00000008
	jr nz, .Lc_f912d3
	cpdi8 (0x895e), 0x00
	jr nz, .Lc_f912a2
	ld XBC,0x01e50002
	lds32 xde, 3
	call ApPostEvent
	ld xwa, (0x815c:16)
	ldb_d8 c, (0x895c)
	extz BC
	sla BC, 0x02
	lda_24 xde, (Data_SaveLoadMenuTable_0x4E)
	lda_dri xhl, 0x07, 0xe8, 0xe4
	ld XBC,(XSP+0x08)
	ld XDE,(XSP+0x04)
	ld XHL,(XHL)
	call (XHL)
	jrl t, CmpDst_Return
CmpDst_ScrollMode8_NoStep:
.Lc_f912a2:
	ld XBC,0x01e50002
	ld XDE,0xffffffff
	call ApPostEvent
	ld xwa, (0x815c:16)
	ldb_d8 c, (0x895c)
	extz BC
	sla BC, 0x02
	lda_24 xde, (Data_SaveLoadMenuTable_0x4E)
	lda_dri xhl, 0x07, 0xe8, 0xe4
	ld XBC,(XSP+0x08)
	ld XDE,(XSP+0x04)
	ld XHL,(XHL)
	call (XHL)
	jr t, CmpDst_Return
CmpDst_ScrollMode5:
.Lc_f912d3:
	ld XBC,(XSP+0x04)
	cp XBC,0x00000005
	jr nz, .Lc_f9130f
	ld XBC,0x01e50002
	ld XDE,0xffffffff
	call ApPostEvent
	ld xwa, (0x815c:16)
	ldb_d8 c, (0x895c)
	extz BC
	sla BC, 0x02
	lda_24 xde, (Data_SaveLoadMenuTable_0x4E)
	lda_dri xhl, 0x07, 0xe8, 0xe4
	ld XBC,(XSP+0x08)
	ld XDE,(XSP+0x04)
	ld XHL,(XHL)
	call (XHL)
	jr t, CmpDst_Return
CmpDst_ScrollMode6:
.Lc_f9130f:
	ld XBC,(XSP+0x04)
	cp XBC,0x00000006
	jr nz, CmpDst_Return
	cpdi8 (0x895e), 0x00
	jr nz, CmpDst_Return
	ld XBC,0x01e50002
	ld XDE,0xffffffff
	call ApPostEvent
	ld xwa, (0x815c:16)
	ldb_d8 c, (0x895c)
	extz BC
	sla BC, 0x02
	lda_24 xde, (Data_SaveLoadMenuTable_0x4E)
	lda_dri xhl, 0x07, 0xe8, 0xe4
	ld XBC,(XSP+0x08)
	ld XDE,(XSP+0x04)
	ld XHL,(XHL)
	call (XHL)
CmpDst_Return:
	lds32 xhl, 0
	jr CmpDst_Epilogue

CmpDst_ReturnCapture:
	ld xhl, 0xffffffff

CmpDst_Epilogue:
	pop xiz
	inc 8, xsp
	ret

CmpSingleLoadFileFunc:
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xwa
	cp	xbc, 29360152
	jrl	z, 135
	cp	xbc, 29360151
	jr	z, 127
	cp	xbc, 29360139
	jr	z, 47
	cp	xbc, 31784964
	jrl	nz, 278
	stda32	(33120), xde
	call	16290274
	stda16	(33124), hl
	cps	hl, 0
	jr	ge, 6
	stdi16	(33124), 0
CmpFile_Selection_Clamp:
	ld	xwa, (33120:16)
	ld	xbc, 31784962
	ld	xde, 4294967295
	jr	65
CmpFile_HandleShow:
	stdi8	34772, 0
	cpdi8	35164, 2
	jr	nz, 12
	ldw_d16	wa, 33124
	call	16290326
	ld	xiz, xhl
	jr	5
CmpFile_ShowDefault:
	lda_24 xiz, (Data_SaveLoadMenuTable_0x62)

CmpFile_ShowDraw:
	lda_d16	xwa, (34773)
	ldw_d16	de, (33124)
	inc	1, de
	pushw	6
	pushw	0
	ld	xbc, xiz
	call	16289232
	ld	xwa, (33120:16)
	ld	xbc, 29360143
	ld	xde, 34772
CmpFile_ShowDispatch:
	call ApPostEvent
	jrl CmpFile_Return

CmpFile_HandleScroll:
	ldw_d16	wa, (33124)
	ld	hl, wa
	or	xde, xde
	jr	nz, 14
	ld	bc, wa
	inc	1, bc
	cp	bc, 20
	jr	ge, 22
	inc	1, wa
	jr	14
CmpFile_ScrollDown:
	cp xde, 0x1
	jr nz, CmpFile_ScrollRedraw
	cps wa, 0
	jr le, CmpFile_ScrollRedraw
	dec 1, wa

CmpFile_ScrollStore:
	stda16	(33124), wa
CmpFile_ScrollRedraw:
	ldw_d16	wa, (33124)
	cp	wa, hl
	jr	z, 118
	call	16290296
	stdi8	(34772), 0
	lda_24	xiz, (15338066)
	stdi8	(35164), 4
	lds	wa, 3
	call	16289732
	cps	l, 0
	jr	z, 23
	call	16281313
	cps	hl, 0
	jr	z, 15
	stdi8	(35164), 2
	ldw_d16	wa, (33124)
	call	16290326
	ld	xiz, xhl
CmpFile_RedrawDispatch:
	lda_d16	xwa, (34773)
	ldw_d16	de, (33124)
	inc	1, de
	pushw	6
	pushw	0
	ld	xbc, xiz
	call	16289232
	ld	xwa, (33120:16)
	ld	xbc, 29360143
	ld	xde, 34772
	call	16423243
	ld	xwa, (xsp+4)
	ld	xbc, 29360139
	lds32	xde, 0
	calr	63985
	ld	xwa, (xsp+4)
	ld	xbc, 29360139
	lds32	xde, 0
	calr	64462
CmpFile_Return:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret
FmmCmpSingleLoadFunc:
	cp	xbc, 29360147
	jrl	nz, 297
	cp	xde, 3
	jrl	z, 285
	cp	xde, 2
	jrl	nz, 279
	lds	wa, 1
	calr	-26314
	ld	xwa, 6357066
	ld	xbc, 31457436
	lds32	xde, 1
	call	16423243
	ld	xwa, 6291494
	ld	xbc, 29360129
	lds32	xde, 5
	call	16423243
	cpdi16	33892, 0
	jr	ge, 13
	call	16290067
	extz	hl
	stda16	33892, hl
	calr	-26275
FmmCmpLoad_DispatchState:
	ldw_d16	wa, 33892
	cps	wa, 1
	jrl	z, 169
	cps	wa, 0
	jrl	z, 139
	cps	wa, 5
	jr	z, 102
	cpdi16	33894, 0
	jr	ge, 19
	call	16290928
	stda16	33894, hl
	call	16290176
	call	16290094
	calr	-26320
FmmCmpLoad_ContinueLoad:
	stdi8	(35164), 4
	lds	wa, 3
	call	16289732
	cps	l, 0
	jr	z, 16
	call	16281313
	cps	hl, 0
	jr	z, 5
	stdi8	(35164), 2
FmmCmpLoad_SignalProgress:
	calr SignalProgressUpdate

FmmCmpLoad_CloseProgress:
	ld	xwa, 6291494
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	ld	xwa, 4294967295
	ld	xbc, 29360138
	lds32	xde, 0
	call	16423243
	stdi8	(35170), 0
	stdi8	(35178), 0
	jr	101
FmmCmpLoad_HandleCancel:
	ld	xwa, 6291494
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	ldw	wa, 176
	call	16355459
	stdi8	(32422), 0
	ldw	wa, 238
	jr	59
FmmCmpLoad_HandleError:
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0x7d
	call UI_PostModeChangeEvent
	jr FmmCmpLoad_Return

FmmCmpLoad_HandleSuccess:
	calr	38884
	ld	xwa, 6291494
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	ldw	wa, 176
	call	16355459
	stdi8	(32422), 2
	ldw	wa, 238
FmmCmpLoad_CallStatusDisplay:
	call SoundCtrl_SendCommand
	jr FmmCmpLoad_Return

FmmCmpLoad_HandleAbort:
	calr CancelOperationCleanup

FmmCmpLoad_Return:
	lds32 xhl, 0
	ret

BuildSlotLabel:
	dec 2,XSP
	push XIZ
	ld HL,BC
	ld (XSP+0x04),WA
	lda_24 xbc, (0x0ab000)
	ld WA,(XSP+0x04)
	extz XWA
	sll XWA, 0x0b
	add XBC,XWA
	.byte 0xf3, 0xe5, 0x00, 0x01, 0x31, 0x9f, 0x04, 0x20
	.byte 0xd8, 0x08, 0x15, 0x00, 0xf1, 0x66, 0x81, 0x34
	.byte 0xd8, 0x8e, 0xee, 0x12, 0xec, 0x86, 0xf5, 0xf8
	.byte 0x47, 0xcd, 0xd8, 0x66, 0x22, 0x9f, 0x04, 0x3f
	.byte 0x09, 0x00, 0x6e, 0x09, 0xf5, 0xf8, 0x00, 0x31
	.byte 0xb6, 0x00, 0x30, 0x68, 0x0c
BuildSlotLabel_WriteLetter:
	stib_dsp 0xf8, 0x20
	ld wa, (xsp + 4)
	add a, 0x31
	ld (xiz), a

BuildSlotLabel_WriteColon:
	inc 1, xiz
	stib_dsp 0xf8, 0x3a

BuildSlotLabel_WriteContent:
	; Disassembled from the committed romslice (no source of any kind existed):
	; llvm-mc round-trips these 34 B byte-exact. v9/v10's BuildSlotLabel_WriteContent
	; is line-for-line identical in shape (ld xwa,xiz / ldw de,0x10 /
	; call FileIO_CopyString_WriteNull / ld (xiz+16),0x0 / ...); the call target
	; and table-base address are left numeric because this v7 link doesn't name them.
	ld	xwa, xiz
	ldw	de, 16
	call	16288997
	ld	(xiz+16), 0
	ld	wa, (xsp+4)
	mul	wa, 21
	lda_d16	xbc, (33126)
	extz	xwa
	add	xwa, xbc
	ld	xhl, xwa
	pop	xiz
	inc	2, xsp
	ret
