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
	cp xbc, 0x1c0000b
	jr z, SLMode_HandleShow
	cp xbc, 0x1e50004
	jr nz, SLMode_Return
	stda32 0x81B6, xde
	jr SLMode_Return

SLMode_HandleShow:
	ldda8 a, 0x89F8
	extz wa
	sla wa, 2
	lda_24 xbc, StorageArea_NameTable
	ld_sril3 XDE, 0x07, 0xe4, 0xe0
	ldda32 xwa, 0x81B6
	ld xbc, 0x1c0000f
	call ApPostEvent

SLMode_Return:
	lds32 xhl, 0
	ret

SingleLoadDstBankFunc:
	cp xbc, 0x1c0000b
	jr z, SLDstBank_HandleShow
	cp xbc, 0x1e50004
	jr nz, SLDstBank_Return
	stda32 0x81BA, xde
	jr SLDstBank_Return

SLDstBank_HandleShow:
	ldda8 a, 0x89F8
	extz wa
	sla wa, 2
	lda_24 xbc, 0xea05f2
	ld_sril3 XDE, 0x07, 0xe4, 0xe0
	ldda32 xwa, 0x81BA
	ld xbc, 0x1c0000f
	call ApPostEvent

SLDstBank_Return:
	lds32 xhl, 0
	ret

SingleLoadDstMemFunc:
	cp xbc, 0x1c0000b
	jr z, SLDstMem_HandleShow
	cp xbc, 0x1e50004
	jr nz, SLDstMem_Return
	stda32 0x81BE, xde
	jr SLDstMem_Return

SLDstMem_HandleShow:
	ldda32 xwa, 0x81BE
	lda_24 xde, 0xea0624
	cpdi8 0x89FA, 0
	jr z, SLDstMem_ShowFromBank
	cpdi8 0x89F8, 1
	jr z, SLDstMem_ShowFromBank
	ld xde, (xde + 16)
	ld xbc, 0x1c0000f
	jr SLDstMem_DispatchShow

SLDstMem_ShowFromBank:
	ldda8 c, 0x89F8
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
	cp xbc, 0x1c0000b
	jr z, SLSrcBank_HandleShow
	cp xbc, 0x1e50004
	jr nz, SLSrcBank_Return
	stda32 0x81C2, xde
	jr SLSrcBank_Return

SLSrcBank_HandleShow:
	ldda32 xwa, 0x81C2
	lda_24 xde, 0xea05f2
	ldda8 c, 0x89F8
	cps c, 0
	jr nz, SLSrcBank_ShowFromIndex
	cpdi8 0x8A0A, 0
	jr z, SLSrcBank_ShowFromIndex
	ld xde, (xde + 16)
	ld xbc, 0x1c0000f
	jr SLSrcBank_DispatchShow

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
	cp xbc, 0x1c0000b
	jr z, SLSrcMem_HandleShow
	cp xbc, 0x1e50004
	jr nz, SLSrcMem_Return
	stda32 0x81C6, xde
	jr SLSrcMem_Return

SLSrcMem_HandleShow:
	ldda32 xwa, 0x81C6
	lda_24 xde, 0xea0624
	ldda8 c, 0x89F8
	cps c, 1
	jr z, SLSrcMem_ShowDirect
	cpdi8 0x89FA, 0
	jr z, SLSrcMem_ShowFromIndex

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
	ldada	xwa, 0x894E
	.byte 0xf5, 0xe0
	nop
	nop
	ldda8	c, 0x89F8
	extz	bc
	sla	bc, 2
	lda_24	xde, 0xEA05F2
	.byte 0xe3
	reti
	or	xix, xwa
	ldb	a, 233
	jr	lt, 29
	adc	wa, ix
	swi	0
	ldada	xwa, 0x894F
	ld	xbc, 0xEA0938
	call	FileIO_BuildFilePath
	ldada	xiz, 0x894F
	ldda8	a, 0x89FC
	extz	wa
	.byte 0x8f, 0x04, 0x51
	inc	1, a
	extz	wa
	lds	bc, 0
	calr	50553
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_BuildFilePath
	ldada	xwa, 0x894F
	ldw	bc, 16
	calr	61054
	ld	xwa, (xsp+6)
	ld	xbc, 0x01C0000F
	ld	xde, 0x894E
	call	ApPostEvent
	pop	xiz
	inc	6, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xwa
	ldada	xwa, 0x894E
	ld	(xwa+21), 1
	lda	xiz, (xwa+22)
	ldda8	a, 0x89FC
	extz	wa
	div8rr	a, c
	extz	wa
	call	0xF8A10E
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_CopyString
	ldada	xwa, 0x8964
	ldw	bc, 16
	calr	60984
	ldada	xde, 0x8963
	ld	xwa, (xsp+4)
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	pop	xiz
	inc	4, xsp
	ret
	dec	6, xsp
	push	xiz
	ld	(xsp+4), c
	ld	(xsp+6), xwa
	ldada	xwa, 0x894E
	ld	(xwa+42), 2
	lda	xwa, (xwa+43)
	ldda8	c, 0x89F8
	extz	bc
	sla	bc, 2
	lda_24	xde, 0xEA0624
	.byte 0xe3
	reti
	or	xix, xwa
	ldb	a, 233
	jr	lt, 29
	adc	wa, ix
	swi	0
	ldada	xwa, 0x8979
	ld	xbc, 0xEA093C
	call	FileIO_BuildFilePath
	.byte 0xc1
	swi	2
	.byte 0x89
	push	xsp
	nop
	jr	nz, 32
	ldada	xiz, 0x8979
	ldda8	a, 0x89FC
	extz	wa
	.byte 0x8f, 0x04, 0x51
	ld	a, w
	inc	1, a
	extz	wa
	lds	bc, 0
	calr	50356
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_BuildFilePath
	ldada	xwa, 0x8979
	ldw	bc, 16
	calr	60857
	ldada	xde, 0x8978
	ld	xwa, (xsp+6)
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	.byte 0xc1
	swi	2
	.byte 0x89
	push	xsp
	nop
	jr	z, 36
	ldada	xwa, 0x894E
	ld	(xwa+63), 3
	lda	xwa, (xwa+64)
	ld	xbc, 0xEA0940
	call	FileIO_CopyString
	ldada	xde, 0x898D
	ld	xwa, (xsp+6)
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	pop	xiz
	inc	6, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xwa
	.byte 0xc1
	swi	2
	.byte 0x89
	push	xsp
	nop
	jr	nz, 55
	ldada	xwa, 0x894E
	ld	(xwa+63), 3
	lda	xiz, (xwa+64)
	ldda8	a, 0x89FC
	extz	wa
	call	0xF8A188
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_CopyString
	ldada	xwa, 0x898E
	ldw	bc, 16
	calr	60742
	ldada	xde, 0x898D
	ld	xwa, (xsp+4)
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	pop	xiz
	inc	4, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	ld	xiz, xwa
	cp	xbc, 0x01C00018
	jr	z, 98
	cp	xbc, 0x01C00017
	jr	z, 90
	cp	xbc, 0x01C0000B
	jrl	nz, 534
	.byte 0xc1
	ldwio	138, 63
	jr	z, 15
	ldda8	a, 0x89FC
	extz	wa
	.byte 0xc2, 0x52
	push	234
	.byte 0x51
	stda8	0x89FC, w
	ld8_24	c, 0xEA0952
	ld	xwa, xiz
	calr	65044
	ld8_24	c, 0xEA0952
	ld	xwa, xiz
	calr	65219
	ld8_24	c, 0xEA0952
	ld	xwa, xiz
	calr	65140
	ld8_24	c, 0xEA0952
	ld	xwa, xiz
	calr	65369
	lds32	xwa, 0
	stda32	0x81CA, xwa
	stdi8	0x81CE, 0
	stdi8	0x81D0, 0
	jrl	453
	ldda8	e, 0x89FC
	ld	xwa, (xsp+4)
	cp	xwa, 5
	jrl	nz, 154
	.byte 0xc1
	ldwio	138, 63
	jr	nz, 108
	ld	xix, xbc
	cp	xbc, 0x01C00017
	jr	nz, 43
	ld8_24	l, 0xEA0952
	ld	a, l
	ld	c, e
	add	a, e
	.byte 0xc2, 0x54
	push	234
	.byte 0xf1
	jr	nc, 25
	add	c, l
	stda8	0x89FC, c
	ld8_24	c, 0xEA0952
	ld	xwa, xiz
	calr	64928
	ld8_24	c, 0xEA0952
	ld	xwa, xiz
	jr	42
	cp	xix, 0x01C00018
	jr	nz, 47
	ld	a, e
	ld8_24	c, 0xEA0952
	cp	e, c
	jr	c, 36
	sub	a, c
	stda8	0x89FC, a
	ld8_24	c, 0xEA0952
	ld	xwa, xiz
	calr	64884
	ld8_24	c, 0xEA0952
	ld	xwa, xiz
	calr	65059
	stdi8	0x81D0, 1
	stdi8	0x81CE, 1
	ldda32	xwa, 0x81CA
	.byte 0xaf, 0x04, 0xf0
	jrl	z, 312
	ldada	xde, 0x8963
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	ldada	xde, 0x898D
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	jrl	215
	ld	xwa, (xsp+4)
	cp	xwa, 6
	jrl	nz, 149
	ld	xhl, xbc
	cp	xbc, 0x01C00017
	jr	nz, 49
	ld	c, e
	ld	a, e
	inc	1, a
	.byte 0xc2, 0x54
	push	234
	.byte 0xf1
	jr	nc, 36
	ld8_24	e, 0xEA0952
	ld	l, e
	ld	a, c
	extz	wa
	div8rr	a, l
	ld	a, w
	inc	1, a
	cp	a, e
	jr	nc, 67
	inc	1, c
	stda8	0x89FC, c
	ld8_24	c, 0xEA0952
	ld	xwa, xiz
	jr	44
	cp	xhl, 0x01C00018
	jr	nz, 44
	ld	c, e
	cps	e, 0
	jr	z, 38
	ld8_24	e, 0xEA0952
	ld	a, c
	extz	wa
	div8rr	a, e
	ld	a, w
	cps	a, 0
	jr	z, 21
	dec	1, c
	stda8	0x89FC, c
	ld8_24	c, 0xEA0952
	ld	xwa, xiz
	calr	64892
	stdi8	0x81CE, 1
	ldda32	xwa, 0x81CA
	.byte 0xaf, 0x04, 0xf0
	jrl	z, 150
	ldada	xde, 0x8963
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	ldada	xde, 0x898D
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	jr	54
	ld	xwa, (xsp+4)
	cp	xwa, 7
	jr	z, 8
	cp	xwa, 8
	jr	nz, 48
	ldda32	xwa, 0x81CA
	.byte 0xaf, 0x04, 0xf0
	jr	z, 94
	ldada	xde, 0x8963
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	ldada	xde, 0x898D
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	ld	xwa, (xsp+4)
	stda32	0x81CA, xwa
	jr	55
	ld	xwa, (xsp+4)
	cp	xwa, 40
	jr	nz, 44
	.byte 0xc1, 0xd0, 0x81
	push	xsp
	nop
	jr	z, 15
	ld8_24	c, 0xEA0952
	ld	xwa, xiz
	calr	64685
	stdi8	0x81D0, 0
	.byte 0xc1
	add	a, h
	push	xsp
	nop
	jr	z, 15
	ld8_24	c, 0xEA0952
	ld	xwa, xiz
	calr	64902
	stdi8	0x81CE, 0
	lds32	xhl, 0
	pop	xiz
	inc	4, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xwa
	cp	xbc, 0x01C0000B
	jrl	nz, 196
	ldada	xwa, 0x894E
	.byte 0xf5, 0xe0
	nop
	nop
	ld	(xwa), 0
	ldw	bc, 16
	calr	60117
	ldada	xwa, 0x894E
	ld	(xwa+21), 1
	lda	xwa, (xwa+22)
	ldda8	c, 0x89F8
	extz	bc
	sla	bc, 2
	lda_24	xde, 0xEA0624
	.byte 0xe3
	reti
	or	xix, xwa
	ldb	a, 233
	jr	lt, 29
	adc	wa, ix
	swi	0
	ldada	xwa, 0x8964
	ld	xbc, 0xEA0958
	call	FileIO_BuildFilePath
	ldada	xwa, 0x8964
	ldw	bc, 16
	calr	60058
	ldada	xwa, 0x894E
	ld	(xwa+42), 2
	lda	xiz, (xwa+43)
	lds	wa, 0
	call	0xF8A21B
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_CopyString
	ldada	xwa, 0x8979
	ldw	bc, 16
	calr	60023
	ldada	xwa, 0x894E
	ld	(xwa+63), 3
	lda	xwa, (xwa+64)
	ld	(xwa), 0
	ldw	bc, 16
	calr	60003
	ld	xwa, (xsp+4)
	ld	xbc, 0x01C0000F
	ld	xde, 0x894E
	call	ApPostEvent
	ldada	xde, 0x8963
	ld	xwa, (xsp+4)
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	ldada	xde, 0x8978
	ld	xwa, (xsp+4)
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	ldada	xde, 0x898D
	ld	xwa, (xsp+4)
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	lds32	xhl, 0
	pop	xiz
	inc	4, xsp
	ret
	dec	2, xsp
	push	xiz
	ld	(xsp+4), c
	ld	xiz, xwa
	ldada	xwa, 0x894E
	.byte 0xf5, 0xe0
	nop
	nop
	ldda8	c, 0x89F8
	extz	bc
	sla	bc, 2
	lda_24	xde, 0xEA05F2
	.byte 0xe3
	reti
	or	xix, xwa
	ldb	a, 233
	jr	lt, 29
	adc	wa, ix
	swi	0
	ldada	xwa, 0x894F
	ld	xbc, 0xEA095A
	call	FileIO_BuildFilePath
	ldada	xwa, 0x894F
	ldw	bc, 16
	calr	59868
	ldada	xwa, 0x8963
	ldda8	c, 0x89FE
	extz	bc
	.byte 0x8f, 0x04, 0x53
	extz	bc
	lds	de, 1
	calr	63586
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	ld	xde, 0x894E
	call	ApPostEvent
	ldada	xde, 0x8963
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	pop	xiz
	inc	2, xsp
	ret
	dec	8, xsp
	push	xiz
	ld	(xsp+6), c
	ld	(xsp+8), xwa
	ldda8	a, 0x89FE
	extz	wa
	.byte 0x8f, 0x06, 0x51
	ld	a, w
	extz	wa
	ld	(xsp+4), wa
	ldada	xwa, 0x894E
	ld	(xwa+42), 2
	lda	xwa, (xwa+43)
	ldda8	c, 0x89F8
	extz	bc
	sla	bc, 2
	lda_24	xde, 0xEA0624
	.byte 0xe3
	reti
	or	xix, xwa
	ldb	a, 233
	jr	lt, 29
	adc	wa, ix
	swi	0
	ldada	xwa, 0x8979
	ld	xbc, 0xEA095E
	call	FileIO_BuildFilePath
	.byte 0xc1
	swi	2
	.byte 0x89
	push	xsp
	nop
	jr	nz, 18
	ldada	xiz, 0x8979
	ld	wa, (xsp+4)
	calr	63498
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_BuildFilePath
	ldada	xwa, 0x8979
	ldw	bc, 16
	calr	59704
	ldada	xde, 0x8978
	ld	xwa, (xsp+8)
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	ldada	xbc, 0x894E
	lda	xwa, (xbc+63)
	.byte 0xc1
	swi	2
	.byte 0x89
	push	xsp
	nop
	jr	z, 29
	ld	(xwa), 3
	lda	xwa, (xbc+64)
	ld	xbc, 0xEA0962
	call	FileIO_CopyString
	ldada	xde, 0x898D
	ld	xwa, (xsp+8)
	ld	xbc, 0x01C0000F
	jr	39
	.byte 0x9f, 0x04
	push	xsp
	.byte 0x04
	nop
	jr	c, 36
	ldda8	c, 0x89FE
	extz	bc
	.byte 0x8f, 0x06, 0x53
	extz	bc
	pushw	3
	ld	de, (xsp+6)
	calr	63409
	ldada	xde, 0x898D
	ld	xwa, (xsp+8)
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	pop	xiz
	inc	8, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	e, c
	ld	(xsp+4), xwa
	ldda8	a, 0x89FE
	extz	wa
	div8rr	a, e
	ld	c, w
	extz	bc
	.byte 0xc1
	swi	2
	.byte 0x89
	push	xsp
	nop
	jr	nz, 63
	cps	bc, 4
	jr	nc, 59
	ldada	xwa, 0x894E
	ld	(xwa+63), 3
	lda	xiz, (xwa+64)
	ldda8	a, 0x89FE
	extz	wa
	div8rr	a, e
	extz	wa
	call	0xF8A295
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_CopyString
	ldada	xwa, 0x898E
	ldw	bc, 16
	calr	59524
	ldada	xde, 0x898D
	ld	xwa, (xsp+4)
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	pop	xiz
	inc	4, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	ld	xde, xbc
	ld	xiz, xwa
	ld8_24	c, 0xEA0974
	cp	xde, 0x01C00018
	jr	z, 51
	cp	xde, 0x01C00017
	jr	z, 43
	cp	xde, 0x01C0000B
	jrl	nz, 447
	ld	xwa, xiz
	calr	65182
	ld8_24	c, 0xEA0974
	ld	xwa, xiz
	calr	65053
	ld8_24	c, 0xEA0974
	ld	xwa, xiz
	calr	65377
	lds32	xwa, 0
	stda32	0x81D2, xwa
	jrl	408
	ldda8	l, 0x89FE
	ld	xwa, (xsp+4)
	cp	xwa, 5
	jrl	nz, 142
	ld	xix, xde
	cp	xde, 0x01C00017
	jr	nz, 43
	ld8_24	e, 0xEA0974
	ld	a, e
	ld	c, l
	add	a, l
	.byte 0xc2
	jrl	z, -5623
	.byte 0xf1
	jr	nc, 25
	add	c, e
	stda8	0x89FE, c
	ld8_24	c, 0xEA0974
	ld	xwa, xiz
	calr	64974
	ld8_24	c, 0xEA0974
	ld	xwa, xiz
	jr	42
	cp	xix, 0x01C00018
	jr	nz, 42
	ld	a, l
	ld8_24	c, 0xEA0974
	cp	l, c
	jr	c, 31
	sub	a, c
	stda8	0x89FE, a
	ld8_24	c, 0xEA0974
	ld	xwa, xiz
	calr	64930
	ld8_24	c, 0xEA0974
	ld	xwa, xiz
	calr	65039
	stdi8	0x81D6, 1
	ldda32	xwa, 0x81D2
	.byte 0xaf, 0x04, 0xf0
	jrl	z, 284
	ldada	xde, 0x8963
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	ldada	xde, 0x898D
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	jrl	214
	ld	xwa, (xsp+4)
	cp	xwa, 6
	jrl	nz, 148
	ld	xix, xde
	cp	xde, 0x01C00017
	jr	nz, 49
	ld	c, l
	ld	a, l
	inc	1, a
	.byte 0xc2
	jrl	z, -5623
	.byte 0xf1
	jr	nc, 36
	ld8_24	e, 0xEA0974
	ld	l, e
	ld	a, c
	extz	wa
	div8rr	a, l
	ld	a, w
	inc	1, a
	cp	a, e
	jr	nc, 67
	inc	1, c
	stda8	0x89FE, c
	ld8_24	c, 0xEA0974
	ld	xwa, xiz
	jr	44
	cp	xix, 0x01C00018
	jr	nz, 44
	ld	c, l
	cps	l, 0
	jr	z, 38
	ld8_24	e, 0xEA0974
	ld	a, c
	extz	wa
	div8rr	a, e
	ld	a, w
	cps	a, 0
	jr	z, 21
	dec	1, c
	stda8	0x89FE, c
	ld8_24	c, 0xEA0974
	ld	xwa, xiz
	calr	64877
	stdi8	0x81D6, 1
	ldda32	xwa, 0x81D2
	.byte 0xaf, 0x04, 0xf0
	jr	z, 123
	ldada	xde, 0x8963
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	ldada	xde, 0x898D
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	jr	54
	ld	xwa, (xsp+4)
	cp	xwa, 7
	jr	z, 8
	cp	xwa, 8
	jr	nz, 48
	ldda32	xwa, 0x81D2
	.byte 0xaf, 0x04, 0xf0
	jr	z, 67
	ldada	xde, 0x8963
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	ldada	xde, 0x898D
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	ld	xwa, (xsp+4)
	stda32	0x81D2, xwa
	jr	28
	ld	xwa, (xsp+4)
	cp	xwa, 40
	jr	nz, 17
	.byte 0xc1, 0xd6, 0x81
	push	xsp
	nop
	jr	z, 10
	ld	xwa, xiz
	calr	64960
	stdi8	0x81D6, 0
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
	ld	xbc, 0x01C0000F
	lds32	xde, 0
	calr	5221
	jr	16
	ld	a, (xix)
	ld	(xde), a
	lds32	xwa, 0
	ld	xbc, 0x01C0000B
	lds32	xde, 0
	calr	1335
	retd	4
	dec	6, xsp
	ld	(xsp), c
	ld	(xsp+2), xwa
	ldada	xwa, 0x894E
	.byte 0xf5, 0xe0
	nop
	nop
	ldda8	c, 0x89F8
	extz	bc
	sla	bc, 2
	lda_24	xde, 0xEA05F2
	.byte 0xe3
	reti
	or	xix, xwa
	ldb	a, 233
	jr	lt, 29
	adc	wa, ix
	swi	0
	ldada	xwa, 0x894F
	ld	xbc, 0xEA0978
	call	FileIO_BuildFilePath
	ldada	xwa, 0x894F
	ldw	bc, 16
	calr	58856
	ld	xwa, (xsp+2)
	ld	xbc, 0x01C0000F
	ld	xde, 0x894E
	call	ApPostEvent
	ld	a, (xsp)
	.byte 0x87, 0x81
	ldda8	c, 0x8A00
	cp	c, a
	jr	nc, 31
	ldada	xwa, 0x8963
	extz	bc
	.byte 0x87, 0x53
	extz	bc
	lds	de, 1
	calr	62683
	ldada	xde, 0x8963
	ld	xwa, (xsp+2)
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	inc	6, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xwa
	ld	a, c
	add	a, c
	cpdm8	0x8A00, a
	jr	c, 49
	ldada	xwa, 0x894E
	ld	(xwa+21), 1
	lda	xiz, (xwa+22)
	call	0xF8A394
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_CopyString
	ldada	xwa, 0x8964
	ldw	bc, 16
	calr	58744
	ldada	xde, 0x8963
	ld	xwa, (xsp+4)
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	pop	xiz
	inc	4, xsp
	ret
	dec	6, xsp
	push	xiz
	ld	(xsp+4), c
	ld	(xsp+6), xwa
	ldada	xwa, 0x894E
	ld	(xwa+42), 2
	lda	xwa, (xwa+43)
	ldda8	c, 0x89F8
	extz	bc
	sla	bc, 2
	lda_24	xde, 0xEA0624
	.byte 0xe3
	reti
	or	xix, xwa
	ldb	a, 233
	jr	lt, 29
	adc	wa, ix
	swi	0
	ldada	xwa, 0x8979
	ld	xbc, 0xEA097C
	call	FileIO_BuildFilePath
	.byte 0xc1
	swi	2
	.byte 0x89
	push	xsp
	nop
	jr	nz, 65
	ld	e, (xsp+4)
	.byte 0x8f, 0x04, 0x85
	ldda8	c, 0x8A00
	ldada	xwa, 0x8979
	cp	c, e
	jr	c, 21
	ld	xiz, xwa
	sub	c, e
	inc	1, c
	extz	bc
	ld	wa, bc
	lds	bc, 0
	calr	48107
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
	calr	48083
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_BuildFilePath
	ldada	xwa, 0x8979
	ldw	bc, 16
	calr	58584
	ldada	xde, 0x8978
	ld	xwa, (xsp+6)
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	.byte 0xc1
	swi	2
	.byte 0x89
	push	xsp
	nop
	jr	z, 36
	ldada	xwa, 0x894E
	ld	(xwa+63), 3
	lda	xwa, (xwa+64)
	.byte 0x41
	.long Str_AllOption_EA0980
	call	FileIO_CopyString
	ldada	xde, 0x898D
	ld	xwa, (xsp+6)
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	pop	xiz
	inc	6, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xwa
	.byte 0xc1
	swi	2
	.byte 0x89
	push	xsp
	nop
	jr	nz, 77
	ldada	xwa, 0x894E
	ld	(xwa+63), 3
	ld	e, c
	add	e, c
	lda	xiz, (xwa+64)
	ldda8	a, 0x8A00
	cp	a, e
	jr	c, 14
	sub	a, e
	extz	wa
	call	0xF8A404
	ld	xbc, xhl
	ld	xwa, xiz
	jr	10
	extz	wa
	call	0xF8A319
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_CopyString
	ldada	xwa, 0x898E
	ldw	bc, 16
	calr	58447
	ldada	xde, 0x898D
	ld	xwa, (xsp+4)
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	pop	xiz
	inc	4, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	ld	xiz, xwa
	ld8_24	e, 0xEA0992
	cp	xbc, 0x01C00018
	jr	z, 73
	cp	xbc, 0x01C00017
	jr	z, 65
	cp	xbc, 0x01C0000B
	jrl	nz, 704
	ld	xwa, xiz
	ld	c, e
	calr	64999
	ld8_24	c, 0xEA0992
	ld	xwa, xiz
	calr	65184
	ld8_24	c, 0xEA0992
	ld	xwa, xiz
	calr	65105
	ld8_24	c, 0xEA0992
	ld	xwa, xiz
	calr	65367
	lds32	xwa, 0
	stda32	0x81D8, xwa
	stdi8	0x81DC, 0
	stdi8	0x81DE, 0
	jrl	648
	ldda8	l, 0x8A00
	ld	xwa, (xsp+4)
	cp	xwa, 5
	jrl	nz, 212
	ld	xde, xbc
	cp	xbc, 0x01C00017
	jr	nz, 72
	ld8_24	c, 0xEA0992
	ld	w, c
	add	w, c
	ld	a, l
	cp	l, w
	jr	nc, 57
	cp	a, c
	jr	nc, 8
	add	a, c
	stda8	0x8A00, a
	jr	4
	stda8	0x8A00, w
	ld8_24	c, 0xEA0992
	ld	xwa, xiz
	calr	64883
	ld8_24	c, 0xEA0992
	ld	xwa, xiz
	calr	65068
	ld8_24	c, 0xEA0992
	pushw	0
	pushw	0x8A08
	ld	xwa, (xsp+8)
	ld	xde, 0x8A00
	jr	78
	cp	xde, 0x01C00018
	jr	nz, 83
	ld	c, l
	ld8_24	e, 0xEA0992
	cp	l, e
	jr	c, 72
	ld	a, e
	add	a, e
	cp	c, a
	jr	nc, 8
	sub	c, e
	stda8	0x8A00, c
	jr	4
	stda8	0x8A00, e
	ld8_24	c, 0xEA0992
	ld	xwa, xiz
	calr	64803
	ld8_24	c, 0xEA0992
	ld	xwa, xiz
	calr	64988
	ld8_24	c, 0xEA0992
	pushw	0
	pushw	0x8A08
	ld	xwa, (xsp+8)
	ld	xde, 0x8A00
	calr	64679
	stdi8	0x81DE, 1
	stdi8	0x81DC, 1
	ldda32	xwa, 0x81D8
	.byte 0xaf, 0x04, 0xf0
	jrl	z, 449
	ldada	xde, 0x8963
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	ldada	xde, 0x898D
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	jrl	355
	ld	xwa, (xsp+4)
	cp	xwa, 6
	jrl	nz, 289
	ld	xde, xbc
	cp	xbc, 0x01C00017
	jr	nz, 118
	ld	c, l
	ld	a, l
	inc	1, a
	.byte 0xc2, 0x94
	push	234
	.byte 0xf1
	jr	nc, 105
	ld8_24	e, 0xEA0992
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
	stda8	0x8A00, c
	ld8_24	c, 0xEA0992
	ld	xwa, xiz
	calr	64836
	ld8_24	c, 0xEA0992
	pushw	0
	pushw	0x8A08
	ld	xwa, (xsp+8)
	ld	xde, 0x8A00
	jrl	152
	inc	1, c
	stda8	0x8A00, c
	ld8_24	c, 0xEA0992
	ld	xwa, xiz
	calr	64798
	ld8_24	c, 0xEA0992
	pushw	0
	pushw	0x8A08
	ld	xwa, (xsp+8)
	ld	xde, 0x8A00
	jr	115
	cp	xde, 0x01C00018
	jr	nz, 115
	ld	c, l
	cps	l, 0
	jr	z, 109
	ld8_24	e, 0xEA0992
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
	stda8	0x8A00, c
	ld8_24	c, 0xEA0992
	ld	xwa, xiz
	calr	64722
	ld8_24	c, 0xEA0992
	pushw	0
	pushw	0x8A08
	ld	xwa, (xsp+8)
	ld	xde, 0x8A00
	jr	39
	cp	c, a
	jr	ule, 43
	dec	1, c
	stda8	0x8A00, c
	ld8_24	c, 0xEA0992
	ld	xwa, xiz
	calr	64681
	ld8_24	c, 0xEA0992
	pushw	0
	pushw	0x8A08
	ld	xwa, (xsp+8)
	ld	xde, 0x8A00
	calr	64372
	stdi8	0x81DC, 1
	ldda32	xwa, 0x81D8
	.byte 0xaf, 0x04, 0xf0
	jrl	z, 147
	ldada	xde, 0x8963
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	ldada	xde, 0x898D
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	jr	54
	ld	xwa, (xsp+4)
	cp	xwa, 7
	jr	z, 8
	cp	xwa, 8
	jr	nz, 48
	ldda32	xwa, 0x81D8
	.byte 0xaf, 0x04, 0xf0
	jr	z, 91
	ldada	xde, 0x8963
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	ldada	xde, 0x898D
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	ld	xwa, (xsp+4)
	stda32	0x81D8, xwa
	jr	52
	ld	xwa, (xsp+4)
	cp	xwa, 40
	jr	nz, 41
	.byte 0xc1
	add	bc, iz
	push	xsp
	nop
	jr	z, 12
	ld	xwa, xiz
	ld	c, e
	calr	64455
	stdi8	0x81DE, 0
	.byte 0xc1
	add	bc, ix
	push	xsp
	nop
	jr	z, 15
	ld8_24	c, 0xEA0992
	ld	xwa, xiz
	calr	64705
	stdi8	0x81DC, 0
	lds32	xhl, 0
	pop	xiz
	inc	4, xsp
	ret
	dec	4, xsp
	pushw	iz
	ld	(xsp+2), xwa
	cp	xbc, 0x01C0000B
	jr	nz, 72
	lds	iz, 0
	ld	de, iz
	mul	de, 21
	ldada	xbc, 0x894E
	ld	hl, de
	extz	xhl
	add	xhl, xbc
	.byte 0xc7
	swi	0
	.byte 0x89
	ld	(xhl), a
	lds	wa, 1
	add	wa, de
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 0
	ldw	bc, 16
	calr	57625
	ld	de, iz
	mul	de, 21
	ldada	xwa, 0x894E
	extz	xde
	add	xde, xwa
	ld	xwa, (xsp+2)
	ld	xbc, 0x01C0000F
	call	ApPostEvent
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
	cp xwa, 0x1e50003
	jrl z, SLSrc_ReturnCapture
	cp xwa, 0x1c00018
	jr z, SLSrc_HandleScroll
	cp xwa, 0x1c00017
	jr z, SLSrc_HandleScroll
	cp xwa, 0x1c0000b
	jr z, SLSrc_HandleShow
	cp xwa, 0x1e50004
	jrl nz, SLSrc_Return
	ld xwa, xiz
	stda32 0x81E0, xwa
	ld xbc, 0x1e50002
	ld xde, 0xffffffff
	call ApPostEvent
	jrl SLSrc_Return

SLSrc_HandleShow:
	ldda32 xwa, 0x81E0
	ld xbc, 0x1e50002
	ld xde, 0xffffffff
	call ApPostEvent
	ldda32 xwa, 0x81E0
	ldda8 c, 0x89F8
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0996
	st_dri3b C, 0x07, 0xe8, 0xe4
	ld xbc, (xsp + 4)
	ld xde, xiz
	ld xhl, (xhl)
	call (xhl)
	calr SignalProgressUpdate
	jrl SLSrc_Return

SLSrc_HandleScroll:
	cp xiz, 0x5
	jr nz, SLSrc_ScrollMode6
	cpdi8 0x89F8, 1
	jr z, SLSrc_ScrollMode5_Prev
	ldda32 xwa, 0x81E0
	ld xbc, 0x1e50002
	lds32 xde, 1
	jr SLSrc_ScrollMode5_Dispatch

SLSrc_ScrollMode5_Prev:
	ldda32 xwa, 0x81E0
	ld xbc, 0x1e50002
	ld xde, 0xffffffff

SLSrc_ScrollMode5_Dispatch:
	call ApPostEvent
	ldda32 xwa, 0x81E0
	ldda8 c, 0x89F8
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0996
	st_dri3b C, 0x07, 0xe8, 0xe4
	ld xbc, (xsp + 4)
	ld xde, xiz
	ld xhl, (xhl)
	call (xhl)
	jrl SLSrc_Return

SLSrc_ScrollMode6:
	cp xiz, 0x6
	jr nz, SLSrc_ScrollMode7
	cpdi8 0x89F8, 1
	jr z, SLSrc_ScrollMode6_NoStep
	cpdi8 0x89FA, 0
	jr nz, SLSrc_ScrollMode6_NoStep
	ldda32 xwa, 0x81E0
	ld xbc, 0x1e50002
	lds32 xde, 3
	jr SLSrc_ScrollMode6_Dispatch

SLSrc_ScrollMode6_NoStep:
	ldda32 xwa, 0x81E0
	ld xbc, 0x1e50002
	ld xde, 0xffffffff

SLSrc_ScrollMode6_Dispatch:
	call ApPostEvent
	ldda32 xwa, 0x81E0
	ldda8 c, 0x89F8
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0996
	st_dri3b C, 0x07, 0xe8, 0xe4
	ld xbc, (xsp + 4)
	ld xde, xiz
	ld xhl, (xhl)
	call (xhl)
	jrl SLSrc_Return

SLSrc_ScrollMode7:
	ldda32 xwa, 0x81E0
	cp xiz, 0x7
	jr nz, SLSrc_ScrollMode8
	ld xbc, 0x1e50002
	ld xde, 0xffffffff
	call ApPostEvent
	ldda32 xwa, 0x81E0
	ldda8 c, 0x89F8
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0996
	st_dri3b C, 0x07, 0xe8, 0xe4
	ld xbc, (xsp + 4)
	ld xde, xiz
	ld xhl, (xhl)
	call (xhl)
	jr SLSrc_Return

SLSrc_ScrollMode8:
	cp xiz, 0x8
	jr nz, SLSrc_ScrollMode40
	ld xbc, 0x1e50002
	ld xde, 0xffffffff
	call ApPostEvent
	ldda32 xwa, 0x81E0
	ldda8 c, 0x89F8
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0996
	st_dri3b C, 0x07, 0xe8, 0xe4
	ld xbc, (xsp + 4)
	ld xde, xiz
	ld xhl, (xhl)
	call (xhl)
	jr SLSrc_Return

SLSrc_ScrollMode40:
	cp xiz, 0x28
	jr nz, SLSrc_Return
	ldda8 c, 0x89F8
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0996
	st_dri3b C, 0x07, 0xe8, 0xe4
	ld xbc, (xsp + 4)
	ld xde, xiz
	ld xhl, (xhl)
	call (xhl)

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
	ldada	xwa, 0x89A2
	.byte 0xf5, 0xe0
	nop
	nop
	ldda8	c, 0x89F8
	extz	bc
	sla	bc, 2
	lda_24	xde, 0xEA05F2
	.byte 0xe3
	reti
	or	xix, xwa
	ldb	a, 233
	jr	lt, 29
	adc	wa, ix
	swi	0
	ldada	xwa, 0x89A3
	ld	xbc, 0xEA09AA
	call	FileIO_BuildFilePath
	ldada	xiz, 0x89A3
	ldda8	a, 0x8A02
	extz	wa
	.byte 0x8f, 0x04, 0x51
	inc	1, a
	extz	wa
	lds	bc, 0
	calr	46525
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_BuildFilePath
	ldada	xwa, 0x89A3
	ldw	bc, 16
	calr	57026
	ldada	xwa, 0x89B7
	ldda8	c, 0x8A02
	extz	bc
	.byte 0x8f, 0x04, 0x53
	extz	bc
	lds	de, 1
	calr	60650
	ldada	xwa, 0x89B8
	ldw	bc, 16
	calr	56996
	ld	xwa, (xsp+6)
	ld	xbc, 0x01C0000F
	ld	xde, 0x89A2
	call	ApPostEvent
	ldada	xde, 0x89B7
	ld	xwa, (xsp+6)
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	pop	xiz
	inc	6, xsp
	ret
	dec	6, xsp
	push	xiz
	ld	(xsp+4), c
	ld	(xsp+6), xwa
	ldada	xde, 0x89A2
	ld	(xde+42), 2
	ld	(xde+63), 3
	ldda8	a, 0x89F8
	extz	wa
	lda_24	xhl, 0xEA0624
	ld	bc, wa
	sla	bc, 2
	lda	xwa, (xde+43)
	.byte 0xe3
	reti
	or	xix, xix
	ldb	a, 233
	jr	lt, -63
	swi	2
	.byte 0x89
	push	xsp
	nop
	jr	z, 42
	call	FileIO_CopyString
	ldada	xwa, 0x89CD
	ld	xbc, 0xEA09AE
	call	FileIO_BuildFilePath
	ldada	xwa, 0x89CD
	ldw	bc, 16
	calr	56878
	ldada	xwa, 0x89E2
	.byte 0x41
	.long Str_AllOption_EA09B2
	call	FileIO_CopyString
	jr	74
	call	FileIO_CopyString
	ldada	xwa, 0x89CD
	ld	xbc, 0xEA09C4
	call	FileIO_BuildFilePath
	ldada	xiz, 0x89CD
	ldda8	a, 0x8A02
	extz	wa
	.byte 0x8f, 0x04, 0x51
	ld	a, w
	inc	1, a
	extz	wa
	lds	bc, 0
	calr	46303
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_BuildFilePath
	ldada	xwa, 0x89CD
	ldw	bc, 16
	calr	56804
	ldada	xwa, 0x89E1
	ldda8	c, 0x8A02
	extz	bc
	lds	de, 3
	calr	60479
	ldada	xde, 0x89CC
	ld	xwa, (xsp+6)
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	ldada	xde, 0x89E1
	ld	xwa, (xsp+6)
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	pop	xiz
	inc	6, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	ld	xde, xbc
	ld	xiz, xwa
	ld8_24	c, 0xEA09C8
	cp	xde, 0x01C00018
	jr	z, 41
	cp	xde, 0x01C00017
	jr	z, 33
	cp	xde, 0x01C0000B
	jrl	nz, 184
	ld	xwa, xiz
	calr	65123
	ld8_24	c, 0xEA09C8
	ld	xwa, xiz
	calr	65275
	lds32	xwa, 0
	stda32	0x81E4, xwa
	jrl	160
	ldda8	l, 0x8A02
	ld	xwa, (xsp+4)
	cp	xwa, 7
	jrl	nz, 149
	ld	xix, xde
	cp	xde, 0x01C00017
	jr	nz, 43
	ld8_24	e, 0xEA09C8
	ld	a, e
	ld	c, l
	add	a, l
	.byte 0xc2
	muls	b, 234
	.byte 0xf1
	jr	nc, 25
	add	c, e
	stda8	0x8A02, c
	ld8_24	c, 0xEA09C8
	ld	xwa, xiz
	calr	65044
	ld8_24	c, 0xEA09C8
	ld	xwa, xiz
	jr	42
	cp	xix, 0x01C00018
	jr	nz, 37
	ld	a, l
	ld8_24	c, 0xEA09C8
	cp	l, c
	jr	c, 26
	sub	a, c
	stda8	0x8A02, a
	ld8_24	c, 0xEA09C8
	ld	xwa, xiz
	calr	65000
	ld8_24	c, 0xEA09C8
	ld	xwa, xiz
	calr	65152
	ldda32	xwa, 0x81E4
	.byte 0xaf, 0x04, 0xf0
	jr	z, 37
	ldada	xde, 0x89B7
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	ldada	xde, 0x89E1
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	ld	xwa, (xsp+4)
	stda32	0x81E4, xwa
	lds32	xhl, 0
	jrl	282
	ld	xwa, (xsp+4)
	cp	xwa, 8
	jrl	nz, 145
	ld	xix, xde
	cp	xde, 0x01C00017
	jr	nz, 49
	ld	c, l
	ld	a, l
	inc	1, a
	.byte 0xc2
	muls	b, 234
	.byte 0xf1
	jr	nc, 36
	ld8_24	e, 0xEA09C8
	ld	l, e
	ld	a, c
	extz	wa
	div8rr	a, l
	ld	a, w
	inc	1, a
	cp	a, e
	jr	nc, 62
	inc	1, c
	stda8	0x8A02, c
	ld8_24	c, 0xEA09C8
	ld	xwa, xiz
	jr	44
	cp	xix, 0x01C00018
	jr	nz, 39
	ld	c, l
	cps	l, 0
	jr	z, 33
	ld8_24	e, 0xEA09C8
	ld	a, c
	extz	wa
	div8rr	a, e
	ld	a, w
	cps	a, 0
	jr	z, 16
	dec	1, c
	stda8	0x8A02, c
	ld8_24	c, 0xEA09C8
	ld	xwa, xiz
	calr	64983
	ldda32	xwa, 0x81E4
	.byte 0xaf, 0x04, 0xf0
	jrl	z, -133
	ldada	xde, 0x89B7
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	ldada	xde, 0x89E1
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	jrl	-173
	ld	xwa, (xsp+4)
	cp	xwa, 5
	jr	z, 8
	cp	xwa, 6
	jr	nz, 39
	ldda32	xwa, 0x81E4
	.byte 0xaf, 0x04, 0xf0
	jrl	z, -191
	ldada	xde, 0x89B7
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	ldada	xde, 0x89E1
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	jrl	-231
	ld	xwa, (xsp+4)
	cp	xwa, 10
	jrl	nz, -232
	.byte 0xc1
	swi	2
	.byte 0x89
	push	xsp
	nop
	jr	z, 30
	ldda8	a, 0x89FC
	extz	wa
	div8rr	a, c
	extz	wa
	ldda8	e, 0x8A02
	extz	de
	div8rr	e, c
	extz	de
	ld	bc, de
	call	0xF88256
	exts	xhl
	jr	18
	ldda8	a, 0x89FC
	extz	wa
	ldda8	c, 0x8A02
	extz	bc
	call	FileIO_ByteBlock_DemoProc1
	exts	xhl
	pop	xiz
	inc	4, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xwa
	ldada	xwa, 0x89A2
	ld	(xwa+21), 1
	lda	xwa, (xwa+22)
	ldda8	c, 0x89F8
	extz	bc
	sla	bc, 2
	lda_24	xde, 0xEA0624
	.byte 0xe3
	reti
	or	xix, xwa
	ldb	a, 233
	jr	lt, 29
	adc	wa, ix
	swi	0
	ldada	xwa, 0x89B8
	ld	xbc, 0xEA09CC
	call	FileIO_BuildFilePath
	ldada	xiz, 0x89B8
	ldda8	a, 0x8A04
	inc	1, a
	extz	wa
	lds	bc, 0
	calr	45647
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_BuildFilePath
	ldada	xwa, 0x89B8
	ldw	bc, 16
	calr	56148
	ldada	xiz, 0x89CC
	ldda8	a, 0x8A04
	extz	wa
	lds	bc, 2
	lds	de, 0
	calr	5520
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_CopyString
	ldada	xde, 0x89B7
	ld	xwa, (xsp+4)
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	ldada	xde, 0x89CC
	ld	xwa, (xsp+4)
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	pop	xiz
	inc	4, xsp
	ret
	push	xiz
	ld	xiz, xwa
	cp	xbc, 0x01C00018
	jr	z, 88
	cp	xbc, 0x01C00017
	jr	z, 80
	cp	xbc, 0x01C0000B
	jr	nz, 122
	ldada	xwa, 0x89A2
	.byte 0xf5, 0xe0
	nop
	nop
	ld	(xwa), 0
	ldw	bc, 16
	calr	56043
	ldada	xwa, 0x89A2
	ld	(xwa+63), 3
	lda	xwa, (xwa+64)
	ld	(xwa), 0
	ldw	bc, 16
	calr	56023
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	ld	xde, 0x89A2
	call	ApPostEvent
	ldada	xde, 0x89E1
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	ld	xwa, xiz
	jr	47
	ldda8	w, 0x8A04
	ldada	xhl, 0x89CC
	cp	xde, 8
	jr	nz, 73
	ld	xde, xbc
	cp	xde, 0x01C00017
	jr	nz, 28
	ld	c, w
	ld	a, w
	inc	1, a
	.byte 0xc2, 0xd0
	push	234
	.byte 0xf1
	jr	nc, 15
	inc	1, c
	stda8	0x8A04, c
	ld	xwa, xiz
	calr	65236
	lds32	xhl, 0
	jr	86
	cp	xde, 0x01C00018
	jr	nz, 16
	ld	a, w
	cps	w, 0
	jr	z, 10
	dec	1, a
	stda8	0x8A04, a
	ld	xwa, xiz
	jr	-31
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	ld	xde, xhl
	jr	25
	cp	xde, 5
	jr	c, 23
	cp	xde, 7
	jr	ugt, 15
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	ld	xde, xhl
	call	ApPostEvent
	jr	-70
	cp	xde, 10
	jr	nz, -78
	ldda8	a, 0x8A04
	extz	wa
	call	0xF88376
	exts	xhl
	pop	xiz
	ret
	dec	2, xsp
	push	xiz
	ld	(xsp+4), c
	ld	xiz, xwa
	ldada	xwa, 0x89A2
	.byte 0xf5, 0xe0
	nop
	nop
	ldda8	c, 0x89F8
	extz	bc
	sla	bc, 2
	lda_24	xde, 0xEA05F2
	.byte 0xe3
	reti
	or	xix, xwa
	ldb	a, 233
	jr	lt, 29
	adc	wa, ix
	swi	0
	ldada	xwa, 0x89A3
	ld	xbc, 0xEA09D2
	call	FileIO_BuildFilePath
	ldada	xwa, 0x89A3
	ldw	bc, 16
	calr	55782
	ldada	xwa, 0x89B7
	ldda8	c, 0x8A06
	extz	bc
	.byte 0x8f, 0x04, 0x53
	extz	bc
	lds	de, 1
	calr	59500
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	ld	xde, 0x89A2
	call	ApPostEvent
	ldada	xde, 0x89B7
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	pop	xiz
	inc	2, xsp
	ret
	dec	6, xsp
	push	xiz
	ld	(xsp+4), c
	ld	(xsp+6), xwa
	ldada	xwa, 0x89A2
	ld	(xwa+42), 2
	lda	xwa, (xwa+43)
	ldda8	c, 0x89F8
	extz	bc
	sla	bc, 2
	lda_24	xde, 0xEA0624
	.byte 0xe3
	reti
	or	xix, xwa
	ldb	a, 233
	jr	lt, 29
	adc	wa, ix
	swi	0
	ldada	xwa, 0x89CD
	ld	xbc, 0xEA09D6
	call	FileIO_BuildFilePath
	.byte 0xc1
	swi	2
	.byte 0x89
	push	xsp
	nop
	jr	nz, 28
	ldada	xiz, 0x89CD
	ldda8	a, 0x8A06
	extz	wa
	.byte 0x8f, 0x04, 0x51
	ld	a, w
	extz	wa
	calr	59418
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_BuildFilePath
	ldada	xwa, 0x89CD
	ldw	bc, 16
	calr	55624
	ldada	xbc, 0x89A2
	lda	xwa, (xbc+63)
	.byte 0xc1
	swi	2
	.byte 0x89
	push	xsp
	nop
	jr	z, 17
	ld	(xwa), 3
	lda	xwa, (xbc+64)
	ld	xbc, 0xEA09DA
	call	FileIO_CopyString
	jr	28
	ldda8	e, 0x8A06
	ld	c, e
	extz	bc
	.byte 0x8f, 0x04, 0x53
	extz	bc
	extz	de
	.byte 0x8f, 0x04, 0x55
	ld	e, d
	extz	de
	pushw	3
	calr	59356
	ldada	xde, 0x89CC
	ld	xwa, (xsp+6)
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	ldada	xde, 0x89E1
	ld	xwa, (xsp+6)
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	pop	xiz
	inc	6, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	ld	xde, xbc
	ld	xiz, xwa
	ld8_24	c, 0xEA09EC
	cp	xde, 0x01C00018
	jr	z, 41
	cp	xde, 0x01C00017
	jr	z, 33
	cp	xde, 0x01C0000B
	jrl	nz, 184
	ld	xwa, xiz
	calr	65174
	ld8_24	c, 0xEA09EC
	ld	xwa, xiz
	calr	65283
	lds32	xwa, 0
	stda32	0x81E8, xwa
	jrl	160
	ldda8	l, 0x8A06
	ld	xwa, (xsp+4)
	cp	xwa, 7
	jrl	nz, 149
	ld	xix, xde
	cp	xde, 0x01C00017
	jr	nz, 43
	ld8_24	e, 0xEA09EC
	ld	a, e
	ld	c, l
	add	a, l
	.byte 0xc2, 0xee
	push	234
	.byte 0xf1
	jr	nc, 25
	add	c, e
	stda8	0x8A06, c
	ld8_24	c, 0xEA09EC
	ld	xwa, xiz
	calr	65095
	ld8_24	c, 0xEA09EC
	ld	xwa, xiz
	jr	42
	cp	xix, 0x01C00018
	jr	nz, 37
	ld	a, l
	ld8_24	c, 0xEA09EC
	cp	l, c
	jr	c, 26
	sub	a, c
	stda8	0x8A06, a
	ld8_24	c, 0xEA09EC
	ld	xwa, xiz
	calr	65051
	ld8_24	c, 0xEA09EC
	ld	xwa, xiz
	calr	65160
	ldda32	xwa, 0x81E8
	.byte 0xaf, 0x04, 0xf0
	jr	z, 37
	ldada	xde, 0x89B7
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	ldada	xde, 0x89E1
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	ld	xwa, (xsp+4)
	stda32	0x81E8, xwa
	lds32	xhl, 0
	jrl	282
	ld	xwa, (xsp+4)
	cp	xwa, 8
	jrl	nz, 145
	ld	xix, xde
	cp	xde, 0x01C00017
	jr	nz, 49
	ld	c, l
	ld	a, l
	inc	1, a
	.byte 0xc2, 0xee
	push	234
	.byte 0xf1
	jr	nc, 36
	ld8_24	e, 0xEA09EC
	ld	l, e
	ld	a, c
	extz	wa
	div8rr	a, l
	ld	a, w
	inc	1, a
	cp	a, e
	jr	nc, 62
	inc	1, c
	stda8	0x8A06, c
	ld8_24	c, 0xEA09EC
	ld	xwa, xiz
	jr	44
	cp	xix, 0x01C00018
	jr	nz, 39
	ld	c, l
	cps	l, 0
	jr	z, 33
	ld8_24	e, 0xEA09EC
	ld	a, c
	extz	wa
	div8rr	a, e
	ld	a, w
	cps	a, 0
	jr	z, 16
	dec	1, c
	stda8	0x8A06, c
	ld8_24	c, 0xEA09EC
	ld	xwa, xiz
	calr	64991
	ldda32	xwa, 0x81E8
	.byte 0xaf, 0x04, 0xf0
	jrl	z, -133
	ldada	xde, 0x89B7
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	ldada	xde, 0x89E1
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	jrl	-173
	ld	xwa, (xsp+4)
	cp	xwa, 5
	jr	z, 8
	cp	xwa, 6
	jr	nz, 39
	ldda32	xwa, 0x81E8
	.byte 0xaf, 0x04, 0xf0
	jrl	z, -191
	ldada	xde, 0x89B7
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	ldada	xde, 0x89E1
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	jrl	-231
	ld	xwa, (xsp+4)
	cp	xwa, 10
	jrl	nz, -232
	.byte 0xc1
	swi	2
	.byte 0x89
	push	xsp
	nop
	jr	z, 30
	ldda8	a, 0x89FE
	extz	wa
	div8rr	a, c
	add	a, 30
	extz	wa
	ldda8	e, 0x8A06
	extz	de
	div8rr	e, c
	add	e, 30
	extz	de
	ld	bc, de
	jr	12
	ldda8	a, 0x89FE
	extz	wa
	ldda8	c, 0x8A06
	extz	bc
	call	0xF8845C
	exts	xhl
	pop	xiz
	inc	4, xsp
	ret
	dec	6, xsp
	ld	(xsp), c
	ld	(xsp+2), xwa
	ldada	xwa, 0x89A2
	.byte 0xf5, 0xe0
	nop
	nop
	ldda8	c, 0x89F8
	extz	bc
	sla	bc, 2
	lda_24	xde, 0xEA05F2
	.byte 0xe3
	reti
	or	xix, xwa
	ldb	a, 233
	jr	lt, 29
	adc	wa, ix
	swi	0
	ldada	xwa, 0x89A3
	.byte 0x41
	.long Data_SaveLoadMenuTable
	call	FileIO_BuildFilePath
	ldada	xwa, 0x89A3
	ldw	bc, 16
	calr	54951
	ld	e, (xsp)
	.byte 0x87, 0x85
	ldda8	c, 0x8A08
	ldada	xwa, 0x89B7
	cp	c, e
	jr	nc, 13
	extz	bc
	.byte 0x87, 0x53
	extz	bc
	lds	de, 1
	calr	58795
	jr	5
	lds	bc, 1
	calr	58871
	ld	xwa, (xsp+2)
	ld	xbc, 0x01C0000F
	ld	xde, 0x89A2
	call	ApPostEvent
	ldada	xde, 0x89B7
	ld	xwa, (xsp+2)
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	inc	6, xsp
	ret
	dec	6, xsp
	push	xiz
	ld	(xsp+4), c
	ld	(xsp+6), xwa
	lda_24	xde, 0xEA0624
	.byte 0xc1
	swi	2
	.byte 0x89
	push	xsp
	nop
	jr	z, 77
	ldada	xwa, 0x89A2
	ld	(xwa+42), 2
	lda	xwa, (xwa+43)
	ldda8	c, 0x89F8
	extz	bc
	sla	bc, 2
	.byte 0xe3
	reti
	or	xix, xwa
	ldb	a, 233
	jr	lt, 29
	adc	wa, ix
	swi	0
	ldada	xwa, 0x89CD
	ld	xbc, 0xEA09F4
	call	FileIO_BuildFilePath
	ldada	xwa, 0x89CD
	ldw	bc, 16
	calr	54806
	ldada	xwa, 0x89A2
	ld	(xwa+63), 3
	lda	xwa, (xwa+64)
	ld	xbc, 0xEA09F8
	call	FileIO_CopyString
	jrl	214
	ld	l, (xsp+4)
	.byte 0x8f, 0x04, 0x87
	ldada	xbc, 0x89A2
	lda	xwa, (xbc+43)
	ld	(xbc+42), 2
	cpdm8	0x8A08, l
	jr	c, 101
	ldda8	c, 0x89F8
	extz	bc
	sla	bc, 2
	.byte 0xe3
	reti
	or	xix, xwa
	ldb	a, 233
	jr	lt, 29
	adc	wa, ix
	swi	0
	ldada	xwa, 0x89CD
	ld	xbc, 0xEA0A0A
	call	FileIO_BuildFilePath
	ldada	xiz, 0x89CD
	ld	c, (xsp+4)
	.byte 0x8f, 0x04, 0x83
	ldda8	a, 0x8A08
	sub	a, c
	inc	1, a
	extz	wa
	lds	bc, 0
	calr	44183
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_BuildFilePath
	ldada	xwa, 0x89CD
	ldw	bc, 16
	calr	54684
	ldada	xwa, 0x89E1
	ld	e, (xsp+4)
	.byte 0x8f, 0x04, 0x85
	ldda8	c, 0x8A08
	sub	c, e
	extz	bc
	lds	de, 3
	calr	58651
	jr	90
	ldda8	c, 0x89F8
	extz	bc
	sla	bc, 2
	.byte 0xe3
	reti
	or	xix, xwa
	ldb	a, 233
	jr	lt, 29
	adc	wa, ix
	swi	0
	ldada	xwa, 0x89CD
	ld	xbc, 0xEA0A0E
	call	FileIO_BuildFilePath
	ldada	xiz, 0x89CD
	ldda8	a, 0x8A08
	extz	wa
	.byte 0x8f, 0x04, 0x51
	ld	a, w
	inc	1, a
	extz	wa
	lds	bc, 0
	calr	44083
	ld	xbc, xhl
	ld	xwa, xiz
	call	FileIO_BuildFilePath
	ldada	xwa, 0x89CD
	ldw	bc, 16
	calr	54584
	ldada	xwa, 0x89E1
	ldda8	c, 0x8A08
	extz	bc
	lds	de, 3
	calr	58478
	ldada	xde, 0x89CC
	ld	xwa, (xsp+6)
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	ldada	xde, 0x89E1
	ld	xwa, (xsp+6)
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	pop	xiz
	inc	6, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	ld	xiz, xwa
	ld8_24	e, 0xEA0A12
	cp	xbc, 0x01C00018
	jr	z, 43
	cp	xbc, 0x01C00017
	jr	z, 35
	cp	xbc, 0x01C0000B
	jrl	nz, 255
	ld	xwa, xiz
	ld	c, e
	calr	65010
	ld8_24	c, 0xEA0A12
	ld	xwa, xiz
	calr	65133
	lds32	xwa, 0
	.byte 0xf1
	add	xbc, xix
	.long NakaInst_95_Bass_Pedals_95_Ext_Sequencer_95
	ldda8	l, 0x8A08
	ld	xwa, (xsp+4)
	cp	xwa, 7
	jrl	nz, 218
	ld	xde, xbc
	cp	xbc, 0x01C00017
	jr	nz, 72
	ld8_24	c, 0xEA0A12
	ld	w, c
	add	w, c
	ld	a, l
	cp	l, w
	jr	nc, 57
	cp	a, c
	jr	nc, 8
	add	a, c
	stda8	0x8A08, a
	jr	4
	stda8	0x8A08, w
	ld8_24	c, 0xEA0A12
	ld	xwa, xiz
	calr	64924
	ld8_24	c, 0xEA0A12
	ld	xwa, xiz
	calr	65047
	ld8_24	c, 0xEA0A12
	pushw	0
	pushw	0x8A08
	ld	xwa, (xsp+8)
	ld	xde, 0x8A00
	jr	82
	cp	xde, 0x01C00018
	jr	nz, 77
	ld	c, l
	ld8_24	e, 0xEA0A12
	cp	l, e
	jr	c, 66
	ld	a, e
	add	a, e
	cp	c, a
	jr	nc, 8
	sub	c, e
	stda8	0x8A08, c
	jr	8
	cp	c, a
	jr	c, 4
	stda8	0x8A08, e
	ld8_24	c, 0xEA0A12
	ld	xwa, xiz
	calr	64840
	ld8_24	c, 0xEA0A12
	ld	xwa, xiz
	calr	64963
	ld8_24	c, 0xEA0A12
	pushw	0
	pushw	0x8A08
	ld	xwa, (xsp+8)
	ld	xde, 0x8A00
	calr	60811
	ldda32	xwa, 0x81EC
	.byte 0xaf, 0x04, 0xf0
	jr	z, 37
	ldada	xde, 0x89B7
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	ldada	xde, 0x89E1
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	ld	xwa, (xsp+4)
	stda32	0x81EC, xwa
	lds32	xhl, 0
	jrl	420
	ld	xwa, (xsp+4)
	cp	xwa, 8
	jrl	nz, 285
	ld	xde, xbc
	cp	xbc, 0x01C00017
	jr	nz, 118
	ld	c, l
	ld	a, l
	inc	1, a
	.byte 0xc2
	push_a
	ldwio	234, 0x6FF1
	jr	ge, -62
	ccf
	ldwio	234, 0xCD25
	.byte 0x89
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
	stda8	0x8A08, c
	ld8_24	c, 0xEA0A12
	ld	xwa, xiz
	calr	64809
	ld8_24	c, 0xEA0A12
	pushw	0
	pushw	0x8A08
	ld	xwa, (xsp+8)
	ld	xde, 0x8A00
	jrl	152
	inc	1, c
	stda8	0x8A08, c
	ld8_24	c, 0xEA0A12
	ld	xwa, xiz
	calr	64771
	ld8_24	c, 0xEA0A12
	pushw	0
	pushw	0x8A08
	ld	xwa, (xsp+8)
	ld	xde, 0x8A00
	jr	115
	cp	xde, 0x01C00018
	jr	nz, 110
	ld	c, l
	cps	l, 0
	jr	z, 104
	ld8_24	e, 0xEA0A12
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
	stda8	0x8A08, c
	ld8_24	c, 0xEA0A12
	ld	xwa, xiz
	calr	64695
	ld8_24	c, 0xEA0A12
	pushw	0
	pushw	0x8A08
	ld	xwa, (xsp+8)
	ld	xde, 0x8A00
	jr	39
	cp	c, a
	jr	ule, 38
	dec	1, c
	stda8	0x8A08, c
	ld8_24	c, 0xEA0A12
	ld	xwa, xiz
	calr	64654
	ld8_24	c, 0xEA0A12
	pushw	0
	pushw	0x8A08
	ld	xwa, (xsp+8)
	ld	xde, 0x8A00
	calr	60502
	ldda32	xwa, 0x81EC
	.byte 0xaf, 0x04, 0xf0
	jrl	z, -273
	ldada	xde, 0x89B7
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	ldada	xde, 0x89E1
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	jrl	-313
	ld	xwa, (xsp+4)
	cp	xwa, 5
	jr	z, 8
	cp	xwa, 6
	jr	nz, 39
	ldda32	xwa, 0x81EC
	.byte 0xaf, 0x04, 0xf0
	jrl	z, -331
	ldada	xde, 0x89B7
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	call	ApPostEvent
	ldada	xde, 0x89E1
	ld	xwa, xiz
	ld	xbc, 0x01C0000F
	jrl	-371
	ld	xwa, (xsp+4)
	cp	xwa, 10
	jrl	nz, -372
	.byte 0xc1
	swi	2
	.byte 0x89
	push	xsp
	nop
	jr	z, 28
	ldda8	a, 0x8A00
	extz	wa
	div8rr	a, e
	extz	wa
	ldda8	c, 0x8A08
	extz	bc
	div8rr	c, e
	extz	bc
	call	0xF8862A
	exts	xhl
	jr	18
	ldda8	a, 0x8A00
	extz	wa
	ldda8	c, 0x8A08
	extz	bc
	call	0xF884D4
	exts	xhl
	pop	xiz
	inc	4, xsp
	ret
	dec	4, xsp
	pushw	iz
	ld	(xsp+2), xwa
	cp	xbc, 0x01C0000B
	jr	nz, 72
	lds	iz, 0
	ld	de, iz
	mul	de, 21
	ldada	xbc, 0x89A2
	ld	hl, de
	extz	xhl
	add	xhl, xbc
	.byte 0xc7
	swi	0
	.byte 0x89
	ld	(xhl), a
	lds	wa, 1
	add	wa, de
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 0
	ldw	bc, 16
	calr	53757
	ld	de, iz
	mul	de, 21
	ldada	xwa, 0x89A2
	extz	xde
	add	xde, xwa
	ld	xwa, (xsp+2)
	ld	xbc, 0x01C0000F
	call	ApPostEvent
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
	cp xwa, 0x1e50003
	jrl z, SLDst_ReturnCapture
	cp xwa, 0x1c00018
	jrl z, SLDst_HandleScroll
	cp xwa, 0x1c00017
	jrl z, SLDst_HandleScroll
	cp xwa, 0x1c0000f
	jrl z, SLDst_HandleConfirm
	cp xwa, 0x1c0000b
	jr z, SLDst_HandleShow
	cp xwa, 0x1e50004
	jr nz, SLDst_Return
	ld xwa, (xsp + 4)
	stda32 0x81F0, xwa
	lds wa, 0
	calr InitializeOperationState
	calr SignalProgressUpdate
	calr WP_ScanAvailability
	calr SignalProgressUpdate
	cpdi8 0x89F8, 1
	jr z, SLDst_ShowHide_Internal
	ld xwa, 0x61004a
	ld xbc, 0x1e0009c
	lds32 xde, 1
	jr SLDst_ShowHide_Dispatch

SLDst_ShowHide_Internal:
	ld xwa, 0x61004a
	ld xbc, 0x1e0009c
	lds32 xde, 0

SLDst_ShowHide_Dispatch:
	call ApPostEvent
	ldda32 xwa, 0x81F0
	ld xbc, 0x1e50002
	ld xde, 0xffffffff
	call ApPostEvent
	cpdi8 0x89F8, 0
	jr nz, SLDst_ClearFloppyFlag
	call FileIO_ValidateWithExtHeader
	cps hl, 0
	jr z, SLDst_ClearFloppyFlag
	stdi8 0x8A0A, 1
	jr SLDst_Return

SLDst_ClearFloppyFlag:
	stdi8 0x8A0A, 0

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
	ldda32 xwa, 0x81F0
	ld xbc, 0x1e50002
	ld xde, 0xffffffff
	call ApPostEvent
	ld xwa, 0x610036
	ld xbc, 0x1e0003b
	lds32 xde, 0
	call ApPostEvent
	ldda32 xwa, 0x81F0
	ldda8 c, 0x89F8
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a16
	st_dri3b C, 0x07, 0xe8, 0xe4
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl SLDst_Return

SLDst_HandleConfirm:
	ldda32 xwa, 0x81F0
	ld xbc, 0x1e50002
	ld xde, 0xffffffff
	call ApPostEvent
	ldda32 xwa, 0x81F0
	ldda8 c, 0x89F8
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a16
	st_dri3b C, 0x07, 0xe8, 0xe4
	ld xbc, 0x1c0000b
	lds32 xde, 0
	ld xhl, (xhl)
	call (xhl)
	jrl SLDst_Return

SLDst_HandleScroll:
	ld xwa, (xsp + 4)
	cp xwa, 0x3
	jr nz, SLDst_ScrollMode4
	cpdi8 0x89F8, 1
	jr z, SLDst_ScrollMode4
	ld xwa, (xsp + 8)
	cp xwa, 0x1c00017
	scc8 z, a
	stda8 0x89FA, a
	ld xwa, xiz
	ld xbc, 0x1c0000b
	lds32 xde, 0
	calr SingleLoadSrcMemFunc
	ld xwa, xiz
	ld xbc, 0x1c0000b
	lds32 xde, 0
	calr SingleLoadDstMemFunc
	ldda32 xwa, 0x81F0
	ld xbc, 0x1e50002
	ld xde, 0xffffffff
	call ApPostEvent
	ld xwa, 0x610036
	ld xbc, 0x1e0003b
	lds32 xde, 0
	call ApPostEvent
	ldda32 xwa, 0x81F0
	ldda8 c, 0x89F8
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a16
	st_dri3b C, 0x07, 0xe8, 0xe4
	ld xbc, 0x1c0000b
	lds32 xde, 0
	ld xhl, (xhl)
	call (xhl)
	ld xwa, xiz
	ld xbc, 0x1c0000b
	lds32 xde, 0
	jrl SLDst_ScrollMode3_CallSrcMem

SLDst_ScrollMode4:
	ld xwa, (xsp + 4)
	cp xwa, 0x4
	jrl nz, SLDst_ScrollDispatch
	calr WP_FindNextSlot
	cps l, 0
	jrl z, SLDst_Return
	cpdi8 0x89F8, 1
	jr z, SLDst_ScrollMode4_Internal
	ld xwa, 0x61004a
	ld xbc, 0x1e0009c
	lds32 xde, 1
	jr SLDst_ScrollMode4_Dispatch

SLDst_ScrollMode4_Internal:
	ld xwa, 0x61004a
	ld xbc, 0x1e0009c
	lds32 xde, 0

SLDst_ScrollMode4_Dispatch:
	call ApPostEvent
	ld xwa, xiz
	ld xbc, 0x1c0000b
	lds32 xde, 0
	calr SingleLoadModeFunc
	ld xwa, xiz
	ld xbc, 0x1c0000b
	lds32 xde, 0
	calr SingleLoadSrcBankFunc
	ld xwa, xiz
	ld xbc, 0x1c0000b
	lds32 xde, 0
	calr SingleLoadSrcMemFunc
	ld xwa, xiz
	ld xbc, 0x1c0000b
	lds32 xde, 0
	calr SingleLoadDstBankFunc
	ld xwa, xiz
	ld xbc, 0x1c0000b
	lds32 xde, 0
	calr SingleLoadDstMemFunc
	ldda32 xwa, 0x81F0
	ld xbc, 0x1e50002
	ld xde, 0xffffffff
	call ApPostEvent
	ld xwa, 0x610036
	ld xbc, 0x1e0003b
	lds32 xde, 0
	call ApPostEvent
	ldda32 xwa, 0x81F0
	ldda8 c, 0x89F8
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a16
	st_dri3b C, 0x07, 0xe8, 0xe4
	ld xbc, 0x1c0000b
	lds32 xde, 0
	ld xhl, (xhl)
	call (xhl)
	ld xwa, xiz
	ld xbc, 0x1c0000b
	lds32 xde, 0

SLDst_ScrollMode3_CallSrcMem:
	calr SingleLoadSrcFunc
	jrl SLDst_Return

SLDst_ScrollDispatch:
	ld xwa, (xsp + 4)
	cp xwa, 0xa
	jr nz, SLDst_Scroll_ChildReturn
	cpdi8 0x89F8, 4
	jr z, SLDst_Scroll_ChildReturn
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	lds wa, 0
	calr InitializeOperationState
	ldda32 xwa, 0x81F0
	ldda8 c, 0x89F8
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a16
	st_dri3b C, 0x07, 0xe8, 0xe4
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xix, (xhl)
	call (xix)
	ld wa, hl
	lds bc, 1
	calr FileIO_ValidateSignedValue
	stda8 0x7F42, l
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0xee
	call SoundCtrl_SendCommand
	jrl SLDst_Return

SLDst_Scroll_ChildReturn:
	ld xwa, (xsp + 4)
	cp xwa, 0x7
	jr nz, SLDst_Scroll_SubMode2
	cpdi8 0x89F8, 1
	jr z, SLDst_Scroll_SubMode
	ldda32 xwa, 0x81F0
	ld xbc, 0x1e50002
	lds32 xde, 1
	call ApPostEvent
	ldda32 xwa, 0x81F0
	ldda8 c, 0x89F8
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a16
	st_dri3b C, 0x07, 0xe8, 0xe4
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl SLDst_Return

SLDst_Scroll_SubMode:
	ldda32 xwa, 0x81F0
	ld xbc, 0x1e50002
	ld xde, 0xffffffff
	call ApPostEvent
	ldda32 xwa, 0x81F0
	ldda8 c, 0x89F8
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a16
	st_dri3b C, 0x07, 0xe8, 0xe4
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl SLDst_Return

SLDst_Scroll_SubMode2:
	ldda32 xwa, 0x81F0
	ld xbc, (xsp + 4)
	cp xbc, 0x8
	jrl nz, SLDst_Scroll_SubMode5
	cpdi8 0x89F8, 1
	jr nz, SLDst_Scroll_SubMode3
	ld xbc, 0x1e50002
	lds32 xde, 2
	call ApPostEvent
	ldda32 xwa, 0x81F0
	ldda8 c, 0x89F8
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a16
	st_dri3b C, 0x07, 0xe8, 0xe4
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl SLDst_Return

SLDst_Scroll_SubMode3:
	cpdi8 0x89FA, 0
	jr nz, SLDst_Scroll_SubMode4
	ld xbc, 0x1e50002
	lds32 xde, 3
	call ApPostEvent
	ldda32 xwa, 0x81F0
	ldda8 c, 0x89F8
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a16
	st_dri3b C, 0x07, 0xe8, 0xe4
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl SLDst_Return

SLDst_Scroll_SubMode4:
	ld xbc, 0x1e50002
	ld xde, 0xffffffff
	call ApPostEvent
	ldda32 xwa, 0x81F0
	ldda8 c, 0x89F8
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a16
	st_dri3b C, 0x07, 0xe8, 0xe4
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl SLDst_Return

SLDst_Scroll_SubMode5:
	ld xbc, (xsp + 4)
	cp xbc, 0x5
	jr nz, SLDst_Scroll_SubMode6
	ld xbc, 0x1e50002
	ld xde, 0xffffffff
	call ApPostEvent
	ldda32 xwa, 0x81F0
	ldda8 c, 0x89F8
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a16
	st_dri3b C, 0x07, 0xe8, 0xe4
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl SLDst_Return

SLDst_Scroll_SubMode6:
	ld xbc, (xsp + 4)
	cp xbc, 0x6
	jrl nz, SLDst_Return
	ld xbc, 0x1e50002
	ld xde, 0xffffffff
	call ApPostEvent
	ldda32 xwa, 0x81F0
	ldda8 c, 0x89F8
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a16
	st_dri3b C, 0x07, 0xe8, 0xe4
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl SLDst_Return

SLDst_ReturnCapture:
	ld xhl, 0xffffffff

SLDst_Epilogue:
	pop xiz
	inc 8, xsp
	ret

CmpSingleLoadSrcFunc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	cp xiz, 0x1e50003
	jrl z, CmpSrc_ReturnCapture
	cp xiz, 0x1c00018
	jr z, CmpSrc_HandleScroll
	cp xiz, 0x1c00017
	jr z, CmpSrc_HandleScroll
	cp xiz, 0x1c0000b
	jr z, CmpSrc_HandleShow
	cp xiz, 0x1e50004
	jrl nz, CmpSrc_Return
	ld xwa, (xsp + 4)
	stda32 0x81F4, xwa
	ld xbc, 0x1e50002
	ld xde, 0xffffffff
	call ApPostEvent
	jrl CmpSrc_Return

CmpSrc_HandleShow:
	ldda32 xwa, 0x81F4
	ld xbc, 0x1e50002
	ld xde, 0xffffffff
	call ApPostEvent
	ldda32 xwa, 0x81F4
	ldda8 c, 0x89F8
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a2a
	st_dri3b C, 0x07, 0xe8, 0xe4
	ld xbc, xiz
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl CmpSrc_Return

CmpSrc_HandleScroll:
	ld xwa, (xsp + 4)
	cp xwa, 0x5
	jr nz, CmpSrc_ScrollMode6
	ldda32 xwa, 0x81F4
	ld xbc, 0x1e50002
	lds32 xde, 1
	call ApPostEvent
	ldda32 xwa, 0x81F4
	ldda8 c, 0x89F8
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a2a
	st_dri3b C, 0x07, 0xe8, 0xe4
	ld xbc, xiz
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl CmpSrc_Return

CmpSrc_ScrollMode6:
	ld xwa, (xsp + 4)
	cp xwa, 0x6
	jr nz, CmpSrc_ScrollMode7
	cpdi8 0x89FA, 0
	jr nz, CmpSrc_ScrollMode6_NoStep
	ldda32 xwa, 0x81F4
	ld xbc, 0x1e50002
	lds32 xde, 3
	call ApPostEvent
	ldda32 xwa, 0x81F4
	ldda8 c, 0x89F8
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a2a
	st_dri3b C, 0x07, 0xe8, 0xe4
	ld xbc, xiz
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl CmpSrc_Return

CmpSrc_ScrollMode6_NoStep:
	ldda32 xwa, 0x81F4
	ld xbc, 0x1e50002
	ld xde, 0xffffffff
	call ApPostEvent
	ldda32 xwa, 0x81F4
	ldda8 c, 0x89F8
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a2a
	st_dri3b C, 0x07, 0xe8, 0xe4
	ld xbc, xiz
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl CmpSrc_Return

CmpSrc_ScrollMode7:
	ldda32 xwa, 0x81F4
	ld xbc, (xsp + 4)
	cp xbc, 0x7
	jr nz, CmpSrc_ScrollMode8
	ld xbc, 0x1e50002
	ld xde, 0xffffffff
	call ApPostEvent
	ldda32 xwa, 0x81F4
	ldda8 c, 0x89F8
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a2a
	st_dri3b C, 0x07, 0xe8, 0xe4
	ld xbc, xiz
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jr CmpSrc_Return

CmpSrc_ScrollMode8:
	ld xbc, (xsp + 4)
	cp xbc, 0x8
	jr nz, CmpSrc_ScrollMode40
	cpdi8 0x89FA, 0
	jr nz, CmpSrc_ScrollMode40
	ld xbc, 0x1e50002
	ld xde, 0xffffffff
	call ApPostEvent
	ldda32 xwa, 0x81F4
	ldda8 c, 0x89F8
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a2a
	st_dri3b C, 0x07, 0xe8, 0xe4
	ld xbc, xiz
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jr CmpSrc_Return

CmpSrc_ScrollMode40:
	ld xbc, (xsp + 4)
	cp xbc, 0x28
	jr nz, CmpSrc_Return
	ldda8 c, 0x89F8
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a2a
	st_dri3b C, 0x07, 0xe8, 0xe4
	ld xbc, xiz
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)

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
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld xiz, xwa
	ld xwa, (xsp + 8)
	cp xwa, 0x1e50003
	jrl z, CmpDst_ReturnCapture
	cp xwa, 0x1c00018
	jrl z, CmpDst_HandleScroll
	cp xwa, 0x1c00017
	jrl z, CmpDst_HandleScroll
	cp xwa, 0x1c0000b
	jr z, CmpDst_HandleShow
	cp xwa, 0x1e50004
	jrl nz, CmpDst_Return
	ld xwa, (xsp + 4)
	stda32 0x81F8, xwa
	ld xbc, 0x1e50002
	ld xde, 0xffffffff
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
	ldda32 xwa, 0x81F8
	ld xbc, 0x1e50002
	ld xde, 0xffffffff
	call ApPostEvent
	ld xwa, 0x61007e
	ld xbc, 0x1e0003b
	lds32 xde, 0
	call ApPostEvent
	ldda32 xwa, 0x81F8
	ldda8 c, 0x89F8
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a3e
	st_dri3b C, 0x07, 0xe8, 0xe4
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
	cp xwa, 0x1c00017
	scc8 z, a
	stda8 0x89FA, a
	ld xwa, xiz
	ld xbc, 0x1c0000b
	lds32 xde, 0
	calr SingleLoadSrcMemFunc
	ld xwa, xiz
	ld xbc, 0x1c0000b
	lds32 xde, 0
	calr SingleLoadDstMemFunc
	ldda32 xwa, 0x81F8
	ld xbc, 0x1e50002
	ld xde, 0xffffffff
	call ApPostEvent
	ld xwa, 0x61007e
	ld xbc, 0x1e0003b
	lds32 xde, 0
	call ApPostEvent
	ldda32 xwa, 0x81F8
	ldda8 c, 0x89F8
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a3e
	st_dri3b C, 0x07, 0xe8, 0xe4
	ld xbc, 0x1c0000b
	lds32 xde, 0
	ld xhl, (xhl)
	call (xhl)
	ld xwa, xiz
	ld xbc, 0x1c0000b
	lds32 xde, 0
	calr CmpSingleLoadSrcFunc
	jrl CmpDst_Return

CmpDst_ScrollModeA:
	ld xwa, (xsp + 4)
	cp xwa, 0xa
	jr nz, CmpDst_ScrollMode7
	cpdi8 0x89F8, 4
	jr z, CmpDst_ScrollMode7
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	lds wa, 0
	calr InitializeOperationState
	ldda32 xwa, 0x81F8
	ldda8 c, 0x89F8
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a3e
	st_dri3b C, 0x07, 0xe8, 0xe4
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xix, (xhl)
	call (xix)
	ld wa, hl
	lds bc, 1
	calr FileIO_ValidateSignedValue
	stda8 0x7F42, l
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0xee
	call SoundCtrl_SendCommand
	jrl CmpDst_Return

CmpDst_ScrollMode7:
	ld xwa, (xsp + 4)
	cp xwa, 0x7
	jr nz, CmpDst_ScrollMode8
	ldda32 xwa, 0x81F8
	ld xbc, 0x1e50002
	lds32 xde, 1
	call ApPostEvent
	ldda32 xwa, 0x81F8
	ldda8 c, 0x89F8
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a3e
	st_dri3b C, 0x07, 0xe8, 0xe4
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl CmpDst_Return

CmpDst_ScrollMode8:
	ldda32 xwa, 0x81F8
	ld xbc, (xsp + 4)
	cp xbc, 0x8
	jr nz, CmpDst_ScrollMode5
	cpdi8 0x89FA, 0
	jr nz, CmpDst_ScrollMode8_NoStep
	ld xbc, 0x1e50002
	lds32 xde, 3
	call ApPostEvent
	ldda32 xwa, 0x81F8
	ldda8 c, 0x89F8
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a3e
	st_dri3b C, 0x07, 0xe8, 0xe4
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jrl CmpDst_Return

CmpDst_ScrollMode8_NoStep:
	ld xbc, 0x1e50002
	ld xde, 0xffffffff
	call ApPostEvent
	ldda32 xwa, 0x81F8
	ldda8 c, 0x89F8
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a3e
	st_dri3b C, 0x07, 0xe8, 0xe4
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jr CmpDst_Return

CmpDst_ScrollMode5:
	ld xbc, (xsp + 4)
	cp xbc, 0x5
	jr nz, CmpDst_ScrollMode6
	ld xbc, 0x1e50002
	ld xde, 0xffffffff
	call ApPostEvent
	ldda32 xwa, 0x81F8
	ldda8 c, 0x89F8
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a3e
	st_dri3b C, 0x07, 0xe8, 0xe4
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)
	jr CmpDst_Return

CmpDst_ScrollMode6:
	ld xbc, (xsp + 4)
	cp xbc, 0x6
	jr nz, CmpDst_Return
	cpdi8 0x89FA, 0
	jr nz, CmpDst_Return
	ld xbc, 0x1e50002
	ld xde, 0xffffffff
	call ApPostEvent
	ldda32 xwa, 0x81F8
	ldda8 c, 0x89F8
	extz bc
	sla bc, 2
	lda_24 xde, 0xea0a3e
	st_dri3b C, 0x07, 0xe8, 0xe4
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	ld xhl, (xhl)
	call (xhl)

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
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	cp xbc, 0x1c00018
	jrl z, CmpFile_HandleScroll
	cp xbc, 0x1c00017
	jr z, CmpFile_HandleScroll
	cp xbc, 0x1c0000b
	jr z, CmpFile_HandleShow
	cp xbc, 0x1e50004
	jrl nz, CmpFile_Return
	stda32 0x81FC, xde
	call GetCurrentFileIndex
	stda16 0x8200, xhl
	cps hl, 0
	jr ge, CmpFile_Selection_Clamp
	stdi16 0x8200, 0

CmpFile_Selection_Clamp:
	ldda32 xwa, 0x81FC
	ld xbc, 0x1e50002
	ld xde, 0xffffffff
	jr CmpFile_ShowDispatch

CmpFile_HandleShow:
	stdi8 0x8870, 0
	cpdi8 0x89F8, 2
	jr nz, CmpFile_ShowDefault
	ldda16 xwa, 0x8200
	call GetFileEntryPtr
	ld xiz, xhl
	jr CmpFile_ShowDraw

CmpFile_ShowDefault:
	lda_24 xiz, 0xea0a52

CmpFile_ShowDraw:
	ldada xwa, 0x8871
	ldda16 xde, 0x8200
	inc 1, de
	pushw 0x6
	pushw 0x0
	ld xbc, xiz
	call FileIO_ReadHeader_ParseLoop
	ldda32 xwa, 0x81FC
	ld xbc, 0x1c0000f
	ld xde, 0x8870

CmpFile_ShowDispatch:
	call ApPostEvent
	jrl CmpFile_Return

CmpFile_HandleScroll:
	ldda16 xwa, 0x8200
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
	stda16 0x8200, xwa

CmpFile_ScrollRedraw:
	ldda16 xwa, 0x8200
	cp wa, hl
	jr z, CmpFile_Return
	call NotifyUIOfSelectionChange
	stdi8 0x8870, 0
	lda_24 xiz, 0xea0a52
	stdi8 0x89F8, 4
	lds wa, 3
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, CmpFile_RedrawDispatch
	call FileIO_ValidateAndOpenFile
	cps hl, 0
	jr z, CmpFile_RedrawDispatch
	stdi8 0x89F8, 2
	ldda16 xwa, 0x8200
	call GetFileEntryPtr
	ld xiz, xhl

CmpFile_RedrawDispatch:
	ldada xwa, 0x8871
	ldda16 xde, 0x8200
	inc 1, de
	pushw 0x6
	pushw 0x0
	ld xbc, xiz
	call FileIO_ReadHeader_ParseLoop
	ldda32 xwa, 0x81FC
	ld xbc, 0x1c0000f
	ld xde, 0x8870
	call ApPostEvent
	ld xwa, (xsp + 4)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	calr CmpSingleLoadSrcFunc
	ld xwa, (xsp + 4)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	calr CmpSingleLoadDstFunc

CmpFile_Return:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret

FmmCmpSingleLoadFunc:
	cp xbc, 0x1c00013
	jrl nz, FmmCmpLoad_Return
	cp xde, 0x3
	jrl z, FmmCmpLoad_HandleAbort
	cp xde, 0x2
	jrl nz, FmmCmpLoad_Return
	lds wa, 1
	calr InitializeOperationState
	ld xwa, 0x61004a
	ld xbc, 0x1e0009c
	lds32 xde, 1
	call ApPostEvent
	ld xwa, 0x600026
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	cpdi16 0x8500, 0
	jr ge, FmmCmpLoad_DispatchState
	call GetDiskSizeInfo
	extz hl
	stda16 0x8500, xhl
	calr SignalProgressUpdate

FmmCmpLoad_DispatchState:
	ldda16 xwa, 0x8500
	cps wa, 1
	jrl z, FmmCmpLoad_HandleSuccess
	cps wa, 0
	jrl z, FmmCmpLoad_HandleError
	cps wa, 5
	jr z, FmmCmpLoad_HandleCancel
	cpdi16 0x8502, 0
	jr ge, FmmCmpLoad_ContinueLoad
	call GetEncodedFileSizeData
	stda16 0x8502, xhl
	call FileIO_SearchAndLoadFile
	call GetEncodedFreeSpaceData
	calr SignalProgressUpdate

FmmCmpLoad_ContinueLoad:
	stdi8 0x89F8, 4
	lds wa, 3
	call FileIO_CheckRecordValid
	cps l, 0
	jr z, FmmCmpLoad_CloseProgress
	call FileIO_ValidateAndOpenFile
	cps hl, 0
	jr z, FmmCmpLoad_SignalProgress
	stdi8 0x89F8, 2

FmmCmpLoad_SignalProgress:
	calr SignalProgressUpdate

FmmCmpLoad_CloseProgress:
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	call ApPostEvent
	stdi8 0x89FE, 0
	stdi8 0x8A06, 0
	jr FmmCmpLoad_Return

FmmCmpLoad_HandleCancel:
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0xb0
	call UI_PostModeChangeEvent
	stdi8 0x7F42, 0
	ldw wa, 0xee
	jr FmmCmpLoad_CallStatusDisplay

FmmCmpLoad_HandleError:
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0x7d
	call UI_PostModeChangeEvent
	jr FmmCmpLoad_Return

FmmCmpLoad_HandleSuccess:
	calr ResetProgressIndication
	ld xwa, 0x600026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ldw wa, 0xb0
	call UI_PostModeChangeEvent
	stdi8 0x7F42, 2
	ldw wa, 0xee

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
	st_dri3b A, 0xe5, 0x00, 0x01
	ld wa, (xsp + 4)
	mul wa, 0x15
	ldada xix, 0x8202
	ld iz, wa
	extz xiz
	add xiz, xix
	lda_dpi XSP, 0xf8
	cps e, 0
	jr z, BuildSlotLabel_WriteContent
	cpw (xsp + 4), 0x9
	jr nz, BuildSlotLabel_WriteLetter
	stib_dpi 0xf8, 0x31
	ld (xiz), 0x30
	jr BuildSlotLabel_WriteColon

BuildSlotLabel_WriteLetter:
	stib_dpi 0xf8, 0x20
	ld wa, (xsp + 4)
	add a, 0x31
	ld (xiz), a

BuildSlotLabel_WriteColon:
	inc 1, xiz
	stib_dpi 0xf8, 0x3a

BuildSlotLabel_WriteContent:
	ld xwa, xiz
	ldw de, 0x10
	call FileIO_CopyString_WriteNull
	ld (xiz + 16), 0x0
	ld wa, (xsp + 4)
	mul wa, 0x15
	ldada xbc, 0x8202
	extz xwa
	add xwa, xbc
	ld xhl, xwa
	pop xiz
	inc 2, xsp
	ret

