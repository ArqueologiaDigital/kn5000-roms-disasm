; =============================================================================
; Flash & Floppy Handlers
; =============================================================================
;
; Flash memory sector write routines, floppy disk note event
; loading, and FDC format UI. Bridges storage hardware to the
; file I/O subsystem.
; =============================================================================

FlashWrite_BlockHandler_Table:
	.long FlashWrite_BlockData_Type0
	.long FlashWrite_BlockData_Type1
	.long FlashWrite_BlockData_Type0
	.long FlashWrite_BlockData_Type1
	.long FlashWrite_BlockData_Type0
	.long FlashWrite_BlockData_Type1
	.long FlashWrite_BlockData_Type0
	.long FlashWrite_BlockData_Type1
	.long FlashWrite_BlockData_Type2
	.long FlashRead_BlockHandler_Table
	.long FlashWrite_BlockData_Type2
	.long FlashRead_BlockHandler_Table
	.long FlashWrite_BlockData_Type3
	.long FlashWrite_BlockRef_Type3
	.long FlashWrite_BlockData_Type4
	.long FlashWrite_BlockRef_Type4
	.long FlashWrite_BlockData_Type5
	.long FlashWrite_BlockRef_Type5
	.long FlashWrite_BlockData_Type4
	.long FlashWrite_BlockRef_Type4
	.long FlashWrite_BlockData_Type6
	.long FlashWrite_BlockRef_Type6
	.long FlashWrite_BlockData_Type6
	.long FlashWrite_BlockRef_Type6
FlashWrite_BlockData_Type0:
	nop
	ldwio	97, 0xff06
	nop
	ldb	w, 12
	pushw	2
	ldwio	98, 0xff06
	nop
	ldb	w, 100
	decf
	push_sr
	halt
	pushw	1635
	swi	7
	nop
	ldb	w, 187
	retd	2
	nop
	ldwio	100, 0xff06
	nop
	ldb	w, 20
	ccf
	push_sr
	nop
	ldwio	101, 0xff06
	nop
	ldb	w, 107
	push_a
	pop_sr
FlashWrite_BlockData_Type1:
	reti
	pop	xbc
	.byte 0xf1
	nop
	reti
	pop	xbc
	.byte 0xf1
	nop
	scf
	pop	xbc
	.byte 0xf1
	nop
	jp	0xf159
	ldb	h, 89
	.byte 0xf1
	nop
	ldw	wa, 0xf159
	nop
FlashWrite_BlockData_Type2:
	nop
	ldwio	97, 0xff06
	nop
	ldb	w, 12
	.byte 0x0b
	push_sr
FlashRead_BlockData_Field2:
	nop
	ldwio	98, 0xff06
	nop
	ldb	w, 100
	decf
	push_sr
FlashRead_BlockData_Field3:
	nop
	ldwio	99, 0xff06
	nop
	ldb	w, 188
	.byte 0x0f
	push_sr
FlashRead_BlockData_Field4:
	nop
	ldwio	100, 0xff06
	nop
	ldb	w, 20
	ccf
	push_sr
FlashRead_BlockData_Field5:
	halt
	pushw	1637
	swi	7
	nop
	ldb	w, 107
	push_a
	push_sr
	nop
FlashRead_BlockData_Field6:
	nop
	.byte 0x0a
	.long TmFlashWrite_Block3
	ldb	w, 196
	ex_ff
	push_sr
FlashRead_BlockHandler_Table:
	.long FlashWrite_BlockData_Type2
	.long FlashWrite_BlockData_Type2
	.long FlashRead_BlockData_Field2
	.long FlashRead_BlockData_Field3
	.long FlashRead_BlockData_Field4
	.long FlashRead_BlockData_Field5
	.long FlashRead_BlockData_Field6
	.long FlashRead_BlockData_Field7
	.long FlashRead_BlockData_Field8
FlashWrite_BlockData_Type3:
	nop
	ldwio	97, 0xff06
	nop
	ldb	w, 12
	pushw 2
	.byte 0x0a
	.long TmFlashWrite_Block2
	ldb	w, 100
	decf
	push_sr
	push_sr
	retd	1635
	retd	8192
	ldw	iz, 0xf135
	nop
	pop_sr
	nop
	ld	(xhl+15), 10
	jr	ov, 6
	swi	7
	nop
	ldb	w, 19
	ccf
	pop_sr
FlashWrite_BlockRef_Type3:
	.byte 0xb3
	pop	xbc
	.byte 0xf1
	nop
	.byte 0xb3
	pop	xbc
	.byte 0xf1
	nop
	.byte 0xbd
	pop	xbc
	.byte 0xf1
	nop
	.byte 0xc7
	pop	xbc
	.byte 0xf1
	nop
	.byte 0xd6
	pop	xbc
	.byte 0xf1
	nop
FlashWrite_BlockData_Type4:
	nop
	ldwio	97, 0xff06
	nop
	ldb	w, 12
	pushw	2
	ldwio	98, 0xff06
	nop
	ldb	w, 100
	decf
	push_sr
	nop
	ldwio	99, 0xff06
	nop
	ldb	w, 188
	retd	2
	ldwio	100, 0xff06
	nop
	ldb	w, 20
	ccf
	push_sr
FlashWrite_BlockRef_Type4:
	.byte 0xf4
	pop	xbc
	.byte 0xf1
	nop
	.byte 0xf4
	pop	xbc
	.byte 0xf1
	nop
	swi	6
	pop	xbc
	.byte 0xf1
	nop
	ldio	90, 241
	nop
	ccf
	pop	xde
	.byte 0xf1
	nop
FlashWrite_BlockData_Type5:
	nop
	ldwio	97, 0xff06
	nop
	ldb	w, 12
	pushw	1282
	pushw	1634
	swi	7
	nop
	ldb	w, 99
	decf
	push_sr
	nop
	halt
	pushw	1635
	swi	7
	nop
	ldb	w, 187
	retd	2
	nop
	ldwio	100, 0xff06
	nop
	ldb	w, 19
	ccf
	pop_sr
FlashWrite_BlockRef_Type5:
	ldw	wa, 0xf15a
	nop
	ldw	wa, 0xf15a
	nop
	push	xde
	pop	xde
	.byte 0xf1
	nop
	ld	xiy, 0x5000f15a
	pop	xde
	.byte 0xf1
	nop
FlashWrite_BlockData_Type6:
	push_sr
	retd	1633
	.byte 0x01
	nop
	ldb	w, 209
	push_a
	stdi8	768, 11
	pushw	2560
	jr	le, 6
	swi	7
	nop
	ldb	w, 100
	decf
	push_sr
	nop
	ldwio	99, 0xff06
	nop
	ldb	w, 187
	.byte 0x0f
	pop_sr
FlashWrite_BlockRef_Type6:
	jr	nz, 90
	.byte 0xf1
	nop
	jr	nz, 90
	.byte 0xf1
	nop
	jrl	pl, -3750
	nop
	.byte 0x87
	pop	xde
	.byte 0xf1
	nop
	push	xde
	pop	xbc
	.byte 0xf1
	nop
	push	xde
	pop	xbc
	.byte 0xf1
	nop
	push	xde
	pop	xbc
	.byte 0xf1
	nop
	push	xde
	pop	xbc
	.byte 0xf1
	nop
	.byte 0x8f
	pop	xbc
	.byte 0xf1
	nop
	.byte 0x8f
	pop	xbc
	.byte 0xf1
	nop
	.byte 0xe0
	pop	xbc
	.byte 0xf1
	nop
	.byte 0x1c
	pop	xde
	.byte 0xf1
	nop
	pop	xde
	pop	xde
	.byte 0xf1
	nop
	.byte 0x1c
	pop	xde
	.byte 0xf1
	nop
	.byte 0x91
	pop	xde
	.byte 0xf1
	nop
	.byte 0x91
	pop	xde
	stda16	0x6800, hl
	stda16	0x6800, hl
	stda16	0x6800, hl
	stda16	0x6800, hl
	stda16	0x8600, hl
	stda16	0x8600, hl
	stda16	0x4a00, hl
	stda16	0x4a00, hl
	stda16	0x4a00, hl
	stda16	0x4a00, hl
	stda16	0x2c00, hl
	stda16	0x2c00, hl
	.byte 0xf1
	nop
	.ascii "CELESTE 1    CELESTE 2    CHORUS 1     CHORUS 2     ENSEMBLE 1   ENSEMBLE 2   TREMOLO      ORGAN TREMOLOSINGLE DELAY REPEAT DELAY SOLO EFFECT 1SOLO EFFECT 2MONO  STEREO#"
	halt
	jr	le, -124
	nop
	.byte 0x1c
	retd	123
	halt
	nop
	.byte 0x45, 0x41, 0x53
	.ascii "Y EDIT"
	.byte 0x17
	rcf
	di
	reti
	nop
	.ascii "SOUND EDIT"
	reti
	halt
	.byte 0x50
	halt
	rcf
	.byte 0x06
	push	162
	halt
	.byte 0x57, 0x52
	popw	bc
	.byte 0x54
	ld	xiy, 0xa8e1107
	.ascii "0CTAVE SHIFT:"
	reti
	ccf
	.byte 0xa2, 0x0a
	.ascii "BRILLIANCE   :"
	reti
	halt
	jr	11
	rcf
	reti
	halt
	.byte 0x8f
	pushw	1809
	scf
	.byte 0xa6
	rcf
	.byte 0x41, 0x54, 0x54
	.ascii "ACK TIME :"
	reti
	ccf
	ld	(xde+16), iz
	popw	bc
	.ascii "BRAT0 DEPTH:"
	reti
	halt
	ldir
	rcf
	reti
	halt
	.byte 0xa7
	scf
	scf
	reti
	scf
	ret
	.byte 0x17
	.ascii "RELEASE TIME:"
	reti
	ccf
	ldb	b, 23
	.ascii "VIBRAT0 SPEED:"
	reti
	halt
	.byte 0x98, 0x17
	rcf
	reti
	halt
	.byte 0xbf, 0x17
	scf
	reti
	zcf
	ldw	iz, 0x441c
	.ascii "IGITAL EFFECT:"
	reti
	ccf
	jr	le, 0x1d
	.ascii "VIBRAT0 DELAY:"
	reti
	halt
	.byte 0xb0
	call	0x50710
	.byte 0xd7
	call	0x50711
	.byte 0xd1
	ldb	a, 141
	.byte 0x06
	push	20
	.ascii "#VALUE"
	reti
	halt
	jr	lt, 35
	.byte 0x8e
	push	10
	.byte 0x04
	nop
	.byte 0x04
	nop
	ld	xix, 0x9001000
	ldwio	11, 7680
	nop
	push	xiy
	nop
	ldw	hl, 2304
	ldwio	13, 8192
	nop
	push	xhl
	nop
	ldw	bc, 2304
	ldwio	163, 0x3900
	nop
	ldw	ix, 0x5901
	nop
	push	10
	pushw	0x3a00
	nop
	.byte 0x9c
	nop
	pop	xbc
	nop
	push	10
	pushw	0x6100
	nop
	.byte 0x9c
	nop
	.byte 0x80
	nop
	push	10
	.byte 0xa3
	nop
	jr	lt, 0
	ldw	ix, 0x8001
	nop
	push	10
	pushw	0x8900
	nop
	.byte 0x9c
	nop
	.byte 0xa8
	nop
	push	10
	.byte 0xa3
	nop
	.byte 0x89
	nop
	ldw	ix, 0xa801
	nop
	push	10
	pushw	0xb200
	nop
	.byte 0x9c
	nop
	.byte 0xd1
	nop
	push	10
	.byte 0xa3
	nop
	ld	(xde), 52
	.byte 0x01, 0xd1
	nop
	ldb	b, 10
	jrl	pl, -9728
	nop
	.byte 0x9a
	nop
	.byte 0xec
	nop
	.byte 0x01
	ldwio	125, 0xe300
	nop
	.byte 0x9a
	nop
	.byte 0xe3
	nop
	.byte 0x1c
	ret
	jrl	f, 2304
	nop
	.byte 0x55, 0x53, 0x45
	.ascii "R KIT"
	.byte 0x17
	rcf
	di
	reti
	nop
	.ascii "SOUND EDIT"
	.byte 0x17
	reti
	ldw	iz, 7937
	nop
	.byte 0x91
	reti
	halt
	popw	ix
	halt
	.byte 0x8d
	reti
	halt
	sub	(xsp+5), bc
	.byte 0x1c
	reti
	pop	xiz
	nop
	ldw	iy, 0x3a00
	.byte 0x17
	pushw	277
	push	xwa
	nop
	.byte 0x53
	popw	sp
	.byte 0x55
	popw	iz
	ld	xix, 0x1360717
	ld	xiz, 0x5079100
	add	(xix+11), h
	reti
	halt
	.byte 0xb7
	pushw	6057
	scf
	ld	xsp, 0x54006400
	.ascii "ONE SELECT"
	.byte 0x17
	pushw	162
	jr	ov, 0
	popw	ix
	ld	xiy, 0x174c4556
	push	199
	nop
	jr	ov, 0
	popw	hl
	ld	xiy, 0xe10a1759
	nop
	jr	ov, 0
	.byte 0x54, 0x55
	popw	iz
	ld	xiy, 0x1020917
	jr	ov, 0
	.byte 0x50
	ld	xbc, 0x1d09174e
	.byte 0x01
	jr	ov, 0
	.byte 0x52
	ld	xiy, 0xd0050656
	scf
	rcf
	.byte 0x17
	reti
	ld	xix, 0x2e007600
	.byte 0x17
	reti
	ld	xhl, 0x91007b00
	.byte 0x17
	reti
	ld	xix, 0x2e009400
	ei	5
	.byte 0xe8, 0x17
	rcf
	.byte 0x17
	reti
	ld	xhl, 0x91009900
	.byte 0x06
	retd	7482
	.ascii "NOTE SELECT"
	.byte 0x06
	retd	7507
	.ascii "DETAIL EDIT"
	ei	5
	.byte 0xb0
	call	0x50610
	.byte 0xd7
	call	0xc1711
	nop
	nop
	.byte 0xd1
	nop
	popw	sp
	popw	iz
	pushw	sp
	popw	sp
	ld	xiz, 0x2d0b1746
	nop
	.byte 0xd1
	nop
	ld	xsp, 0x50554f52
	.byte 0x17
	ldwio	88, 0xd100
	nop
	.byte 0x54
	popw	sp
	popw	iz
	ld	xiy, 0x7d0b17
	.byte 0xd1
	nop
	popw	ix
	ld	xiy, 0x174c4556
	push	170
	nop
	.byte 0xd1
	nop
	popw	hl
	ld	xiy, 0xcf0a1759
	nop
	.byte 0xd1
	nop
	.byte 0x54, 0x55
	popw	iz
	ld	xiy, 0xfa0917
	.byte 0xd1
	nop
	.byte 0x50
	ld	xbc, 0x2309174e
	.byte 0x01, 0xd1
	nop
	.byte 0x52
	ld	xiy, 0x12050656
	ldb	b, 141
	ei	5
	.byte 0x17
	ldb	b, 141
	ei	5
	.byte 0x1c
	ldb	b, 141
	ei	5
	ldb	a, 34
	.byte 0x8d
	ei	5
	ldb	h, 34
	.byte 0x8d
	ei	5
	pushw	hl
	ldb	b, 141
	ei	5
	ldw	wa, 0x8d22
	ei	5
	ldw	iy, 0x8d22
	ei	5
	ld	xhl, (xde)
	.byte 0x8e
	ei	5
	ld	xhl, (xsp)
	.byte 0x8e
	ei	5
	add	(xix+35), xiz
	ei	5
	.byte 0xb1
	ldb	c, 142
	ei	5
	.byte 0xb6
	ldb	c, 142
	ei	5
	.byte 0xbb
	ldb	c, 142
	ei	5
	.byte 0xc0
	ldb	c, 142
	ei	5
	.byte 0xc5
	ldb	c, 142
	push	10
	.byte 0x04
	nop
	.byte 0x04
	nop
	ld	xix, 0x9001000
	ldwio	18, 7681
	nop
	ldw	iy, 0x3101
	nop
	push	10
	push_a
	.byte 0x01
	ldb	w, 0
	ldw	hl, 0x2f01
	nop
	push	10
	.byte 0x37
	nop
	pushw	iz
	nop
	swi	5
	nop
	popw	bc
	nop
	push	10
	push	xbc
	nop
	ldw	wa, 0xfb00
	nop
	ld	xsp, 0x120a0900
	.byte 0x01
	ld	xiy, 0x58013500
	nop
	push	10
	push_a
	.byte 0x01
	ld	xsp, 0x56013300
	nop
	ldb	b, 10
	pushw	0x5e00
	nop
	ldw	iy, 0xaa01
	nop
	push	10
	ldwio	0, 181
	jr	nz, 0
	.byte 0xca
	nop
	push	10
	incf
	nop
	ld	(xsp), 108
	nop
	.byte 0xc8
	nop
	push	10
	.byte 0xd2
	nop
	ld	(xiy), 53
	.byte 0x01, 0xca
	nop
	push	10
	.byte 0xd4
	nop
	ld	(xsp), 51
	.byte 0x01, 0xc8
	nop
	ldb	b, 10
	push	0
	.byte 0xda
	nop
	calr	60928
	nop
	ldb	b, 10
	ldw	bc, 0xda00
	nop
	ld	xiz, 0x2200ee00
	ldwio	89, 0xda00
	nop
	jr	nz, 0
	.byte 0xee
	nop
	ldb	b, 10
	.byte 0x81
	nop
	.byte 0xda
	nop
	.byte 0x96
	nop
	.byte 0xee
	nop
	ldb	b, 10
	.byte 0xa9
	nop
	.byte 0xda
	nop
	.byte 0xbe
	nop
	.byte 0xee
	nop
	ldb	b, 10
	.byte 0xd1
	nop
	.byte 0xda
	nop
	.byte 0xe6
	nop
	.byte 0xee
	nop
	ldb	b, 10
	swi	1
	nop
	.byte 0xda
	nop
	ret
	.byte 0x01, 0xee
	nop
	ldb	b, 10
	ldb	a, 1
	.byte 0xda
	nop
	ldw	iz, 0xee01
	nop
	.byte 0x01
	ldwio	11, 0x6f00
	nop
	ldw	iy, 0x6f01
	nop
	.byte 0x01
	ldwio	11, 0x8c00
	nop
	pop_f
	.byte 0x01, 0x8c
	nop
	.byte 0x01
	ldwio	9, 0xe400
	nop
	calr	58368
	nop
	.byte 0x01
	ldwio	49, 0xe400
	nop
	ld	xiz, 0x100e400
	ldwio	89, 0xe400
	nop
	jr	nz, 0
	.byte 0xe4
	nop
	.byte 0x01
	ldwio	129, 0xe400
	nop
	.byte 0x96
	nop
	.byte 0xe4
	nop
	.byte 0x01
	ldwio	169, 0xe400
	nop
	.byte 0xbe
	nop
	.byte 0xe4
	nop
	.byte 0x01
	ldwio	209, 0xe400
	nop
	.byte 0xe6
	nop
	.byte 0xe4
	nop
	.byte 0x01
	ldwio	249, 0xe400
	nop
	ret
	.byte 0x01, 0xe4
	nop
	.byte 0x01
	ldwio	33, 0xe401
	nop
	ldw	iz, 0xe401
	nop
	push_sr
	ldwio	56, 0x5e00
	nop
	push	xwa
	nop
	.byte 0xaa
	nop
	push_sr
	ldwio	157, 0x5e00
	nop
	.byte 0x9d
	nop
	.byte 0xaa
	nop
	push_sr
	ldwio	25, 0x5e01
	nop
	pop_f
	.byte 0x01, 0xaa
	nop
	jp	0x1190a
	jrl	lt, 0x3300
	.byte 0x01, 0xa8
	nop
	halt
	ldwio	25, 0x7101
	nop
	ldw	hl, 0xa801
	nop
	reti
	scf
	jr	lt, 6
	jrl	nc, 7168
	jrl	le, -3781
	nop
	pop_sr
	nop
	push	xiy
	nop
	ldw	iy, 1792
	scf
	nop
	nop
	nop
	nop
	.byte 0x1c, 0xf3
	pushw	2
	decf
	nop
	jr	ge, 0
	ldw	iy, 1792
	scf
	jr	nc, 6
	.byte 0x1f
	nop
	.byte 0x17, 0xcf
	pushw	ix
	stdi8	512, 61
	nop
	jrl	gt, 1792
	scf
	nop
	nop
	nop
	nop
	.byte 0x17
	pop_sr
	incf
	push_sr
	nop
	decf
	nop
	popw	bc
	nop
	jrl	gt, 2304
	incf
	jr	ule, 6
	jrl	nc, 5888
	.byte 0xa5
	nop
	jrl	gt, 768
	pushw	0x650d
	.byte 0x06
	swi	7
	nop
	.byte 0x17, 0xc3
	nop
	jrl	gt, 512
	nop
	pushw	0x670d
	.byte 0x06
	swi	7
	nop
	.byte 0x17, 0xe1
	nop
	jrl	gt, 512
	nop
	reti
	scf
	jrl	f, 7942
	nop
	.byte 0x17, 0xcf
	pushw	ix
	stdi8	512, 61
	nop
	.byte 0x98
	nop
	reti
	scf
	nop
	nop
	nop
	nop
	.byte 0x17
	zcf
	incf
	push_sr
	nop
	decf
	nop
	popw	bc
	nop
	.byte 0x98
	nop
	push	12
	jr	ov, 6
	jrl	nc, 5888
	.byte 0xa5
	nop
	.byte 0x98
	nop
	pop_sr
	pushw	0x660d
	.byte 0x06
	swi	7
	nop
	.byte 0x17, 0xc3
	nop
	.byte 0x98
	nop
	push_sr
	nop
	pushw	0x680d
	.byte 0x06
	swi	7
	nop
	.byte 0x17, 0xe1
	nop
	.byte 0x98
	nop
	push_sr
	nop
	push	12
	jr	ugt, 6
	jrl	nc, 5888
	.byte 0x1c, 0x01, 0x89
	nop
	pop_sr
	reti
	scf
	jr	nov, 6
	pop_sr
	nop
	.byte 0x17
	pop	xwa
	ld	xiz, 0x300f1
	pop_sr
	.byte 0x01
	jrl	gt, 1792
	scf
	jr	nov, 6
	incf
	push_sr
	.byte 0x17
	pop	xwa
	ld	xiz, 0x300f1
	pop_sr
	.byte 0x01, 0x98
	nop
	pop_sr
	pushw	1632
	pop_sr
	nop
	halt
	push	97
	.byte 0xf1
	nop
	push	12
	jr	pl, 6
	jrl	nc, 5888
	push	1
	jrl	gt, 512
	push	12
	jr	nz, 6
	jrl	nc, 5888
	push	1
	.byte 0x98
	nop
	push_sr
	decf
	nop
	jrl	lt, 6144
	.byte 0x01, 0x8a
	nop
	decf
	nop
	jrl	lt, 6144
	.byte 0x01, 0x8a
	nop
	decf
	nop
	.byte 0x8d
	nop
	push_f
	.byte 0x01, 0xa8
	nop
	jp	3338
	jrl	lt, 6144
	.byte 0x01, 0xa8
	nop
	.byte 0xe6
	jr	f, -15
	nop
DrumDetailEdit_Menu_Table:
	.long DrumDetailEdit_Entry_01
	.long DrumDetailEdit_Entry_01
	.long DrumDetailEdit_Entry_03
	.long DrumDetailEdit_Entry_07
	.long DrumDetailEdit_Entry_04
	.long DrumDetailEdit_Entry_08
	.long DrumDetailEdit_Entry_05
	.long DrumDetailEdit_Entry_09
	.long Data_Dispatch_Entry
	.long Data_Dispatch_Entry
	.long Data_Dispatch_Entry
	.long Data_Dispatch_Entry_0x39
	.long Data_Dispatch_Entry_0x39
	.long Data_Dispatch_Entry_0x45
	.long DrumDetailEdit_Entry_02
	.long DrumDetailEdit_Entry_06
	.byte 0x23, 0x05, 0x10, 0x7f, 0x00, 0x23, 0x05, 0x63
	.byte 0xa3, 0x0a, 0x23, 0x05, 0x61, 0xc2, 0x0a, 0x23
	.byte 0x05, 0x21, 0xbb, 0x10, 0x23, 0x05, 0x5f, 0xda
	.byte 0x10, 0x1c, 0x16, 0x58, 0x00, 0x08, 0x00, 0x44
	.ascii "RUM DETAIL EDIT"
	.byte 0x06
	.byte 0x08, 0x7c, 0x0b
	.byte 0x54, 0x30, 0x4e, 0x45
	.byte 0x06
	.byte 0x0c, 0x81, 0x0b
	ld	xix, 0x4d414e59
	.byte 0x49, 0x43, 0x53, 0x06, 0x0d, 0x97, 0x0b, 0x41
	.ascii "MPLITUDE"
	.byte 0x06, 0x05, 0xb8, 0x0b, 0x10, 0x06, 0x05, 0xdf
	.byte 0x0b, 0x11, 0x17, 0x19, 0x8e, 0x00, 0x65, 0x00
	.ascii "TOTAL KIT PARAMETER"
	.byte 0x06, 0x05, 0xa8, 0x11, 0x10
	.byte 0x06, 0x05, 0xcf, 0x11, 0x11, 0x06, 0x0e, 0xbe
	.byte 0x11
	.ascii "C0NTR0LLER"
	.byte 0x06, 0x0a, 0xd7, 0x11, 0x46
	.byte 0x49, 0x4c, 0x54, 0x45, 0x52
	.byte 0x06, 0x17, 0x15
	.byte 0x1e
	.ascii "DRUM S0UND NAMING "
	.byte 0x11, 0x09, 0x0a, 0x0f, 0x00
	.byte 0x37, 0x00, 0x31, 0x01, 0x8f, 0x00, 0x09, 0x0a
	.byte 0xa3, 0x00, 0xba, 0x00, 0x35, 0x01, 0xcf, 0x00
	.byte 0x09, 0x0a, 0xa5, 0x00, 0xbc, 0x00, 0x33, 0x01
	.byte 0xcd, 0x00, 0x17, 0x0b, 0x3b, 0x00, 0x3e, 0x00
	.byte 0x54, 0x4f, 0x55, 0x43, 0x48
	.byte 0x17, 0x0b, 0x6b
	.byte 0x00, 0x3e, 0x00
	ld	xhl, 0x45565255
	.byte 0x17, 0x0b, 0x54, 0x00, 0xd1, 0x00, 0x54, 0x4f
	.byte 0x55, 0x43, 0x48, 0x17, 0x0b, 0x7d, 0x00, 0xd1
	.byte 0x00
	ld	xhl, 0x45565255
	.byte 0x06, 0x05
	.byte 0x1c, 0x22, 0x8d, 0x06, 0x05, 0x21, 0x22, 0x8d
	.byte 0x06, 0x05, 0xac, 0x23, 0x8e, 0x06, 0x05, 0xb1
	.byte 0x23, 0x8e, 0x22, 0x0a, 0x0b, 0x00, 0x38, 0x00
	.byte 0x9c, 0x00, 0x8a, 0x00, 0x22, 0x0a, 0x59, 0x00
	.byte 0xda, 0x00, 0x6e, 0x00, 0xee, 0x00, 0x22, 0x0a
	.byte 0x81, 0x00, 0xda, 0x00, 0x96, 0x00, 0xee, 0x00
	.byte 0x01, 0x0a, 0x0b, 0x00, 0x4a, 0x00, 0x9c, 0x00
	.byte 0x4a, 0x00, 0x01, 0x0a, 0x0b, 0x00, 0x6a, 0x00
	.byte 0x9c, 0x00, 0x6a, 0x00, 0x01, 0x0a, 0x59, 0x00
	.byte 0xe4, 0x00, 0x6e, 0x00, 0xe4, 0x00, 0x01, 0x0a
	.long Pad_NakaExternal_Block4
	.long NakaData_ExternalPadBlock_A
	.byte 0x02, 0x0a, 0x2e, 0x00, 0x38, 0x00, 0x2e, 0x00
	.byte 0x8a, 0x00, 0x05, 0x0a, 0x16, 0x01, 0x43, 0x00
	.byte 0x32, 0x01, 0x5c, 0x00, 0x06, 0x13, 0x60, 0x1d
	.byte 0x10
	.ascii "KEY OFF MODE :"
	.byte 0x17
	.byte 0x0b, 0x18, 0x01, 0xc2, 0x00, 0x54, 0x4f, 0x55
	.byte 0x43, 0x48, 0x17, 0x09, 0x09, 0x00, 0xcf, 0x00
	.byte 0x41, 0x54, 0x4b, 0x17, 0x0c, 0x27, 0x00, 0xcf
	.byte 0x00
	.ascii "DECAY1"
	.byte 0x17
	.byte 0x0b, 0x51, 0x00, 0xcf, 0x00, 0x53, 0x55, 0x53
	.byte 0x54, 0x31, 0x17, 0x0c, 0x7b, 0x00, 0xcf, 0x00
	.ascii "DECAY2"
	.byte 0x17, 0x0b
	.byte 0xa5, 0x00, 0xcf, 0x00
	.byte 0x53, 0x55, 0x53, 0x54
	.byte 0x32, 0x17, 0x0d, 0xcf, 0x00, 0xcf, 0x00, 0x52
	.ascii "ELEASE"
	.byte 0x17, 0x0c
	.byte 0x18, 0x01, 0xcf, 0x00
	.byte 0x41, 0x54, 0x54, 0x41
	.byte 0x43, 0x4b, 0x07, 0x05, 0x1a, 0x24, 0x12, 0x07
	.byte 0x05, 0x1f, 0x24, 0x12, 0x07, 0x05, 0x24, 0x24
	.byte 0x12, 0x07, 0x05, 0x29, 0x24, 0x12, 0x07, 0x05
	.byte 0x2e, 0x24, 0x12, 0x07, 0x05, 0x34, 0x24, 0x12
	.byte 0x07, 0x05, 0x3e, 0x24, 0x12, 0x09, 0x0a, 0x03
	.byte 0x00, 0xcb, 0x00, 0xfd, 0x00, 0xe8, 0x00, 0x09
	.byte 0x0a, 0x14, 0x01, 0xcb, 0x00, 0x3f, 0x01, 0xe8
	.byte 0x00, 0x01, 0x0a, 0x03, 0x00, 0xd9, 0x00, 0xfd
	.byte 0x00, 0xd9, 0x00, 0x01, 0x0a, 0x14, 0x01, 0xd9
	.byte 0x00, 0x3f, 0x01, 0xd9, 0x00, 0x05, 0x0a, 0x16
	.byte 0x01, 0x27, 0x00, 0x32, 0x01, 0x34, 0x00, 0x05
	.byte 0x0a, 0x04, 0x00, 0xda, 0x00, 0xfc, 0x00, 0xe7
	.byte 0x00, 0x05, 0x0a, 0x15, 0x01, 0xda, 0x00, 0x3e
	.byte 0x01, 0xe7, 0x00
; se_apply_confirm: 55 bytes (5 commands)
; Compiled from C source (maincpu/audio/sound_editor_screens/se_apply_confirm.c)
	.incbin "includes/generated/se_apply_confirm.bin"
	.byte 0xd6, 0x63, 0xf1, 0x00, 0xaa, 0x63
	.byte 0xf1, 0x00, 0xb5, 0x63, 0xf1, 0x00, 0xc0, 0x63
	.byte 0xf1, 0x00, 0xcb, 0x63, 0xf1, 0x00, 0x1b, 0x0a
	.byte 0x0d, 0x00, 0x4c, 0x00, 0x9a, 0x00, 0x88, 0x00
	.byte 0x0d, 0x00, 0x4c, 0x00, 0x9a, 0x00, 0x68, 0x00
	.byte 0x0d, 0x00, 0x4c, 0x00, 0x9a, 0x00, 0x68, 0x00
	.byte 0x0d, 0x00, 0x6c, 0x00, 0x9a, 0x00, 0x88, 0x00
	.byte 0x02, 0x0f, 0x60, 0x06, 0x20, 0x05, 0x20, 0xd1
	.byte 0x14, 0xf1, 0x00, 0x03, 0x00, 0x70, 0x1d, 0x00
	.byte 0x0a, 0x61, 0x06, 0x7f, 0x00, 0x20, 0x61, 0x22
	.byte 0x03, 0x00, 0x0a, 0x62, 0x06, 0x7f, 0x00, 0x20
	.byte 0x65, 0x22, 0x03, 0x00, 0x0a, 0x63, 0x06, 0x7f
	.byte 0x00, 0x20, 0x6a, 0x22, 0x03, 0x00, 0x0a, 0x64
	.byte 0x06, 0x7f, 0x00, 0x20, 0x6f, 0x22, 0x03, 0x05
	.byte 0x0b, 0x67, 0x06, 0xff, 0x00, 0x20, 0x84, 0x22
	.byte 0x02, 0x00, 0x17, 0x64, 0xf1, 0x00, 0x26, 0x64
	.byte 0xf1, 0x00, 0x30, 0x64, 0xf1, 0x00, 0x3a, 0x64
	.byte 0xf1, 0x00, 0x44, 0x64, 0xf1, 0x00, 0x79, 0x64
	.byte 0xf1, 0x00, 0x83, 0x64, 0xf1, 0x00, 0x4e, 0x64
	.byte 0xf1, 0x00, 0x00, 0x0a, 0x65, 0x06, 0x7f, 0x00
	.byte 0x20, 0x74, 0x22, 0x03, 0x00, 0x0a, 0x66, 0x06
	.byte 0x7f, 0x00, 0x20, 0x7a, 0x22, 0x03, 0x20, 0x07
	.ascii "t\" -- "
	.byte 0x07, 0x7a
	.ascii "\" --"
	.byte 0x05, 0x0b, 0x61, 0x06
	.byte 0xff, 0x00, 0x20, 0xb0, 0x0a, 0x02, 0x00, 0x02
	.byte 0x0f, 0x62, 0x06, 0x1f, 0x00, 0x20, 0xa9, 0x65
	.byte 0xf1, 0x00, 0x03, 0x00, 0xc8, 0x10, 0x05, 0x0b
	.byte 0x63, 0x06, 0xff, 0x00, 0x20, 0x30, 0x17, 0x02
	.byte 0x00, 0x05, 0x0b, 0x64, 0x06, 0xff, 0x00, 0x20
	.byte 0x70, 0x1d, 0x02, 0x00, 0x05, 0x0b, 0x69, 0x06
	.byte 0x0f, 0x00, 0x20, 0x9b, 0x0a, 0x02, 0x08, 0x05
	.byte 0x0b, 0x66, 0x06, 0xff, 0x00, 0x20, 0xb3, 0x10
	.byte 0x02, 0x00, 0x05, 0x0b, 0x67, 0x06, 0xff, 0x00
	.byte 0x20, 0x1b, 0x17, 0x02, 0x00, 0x03, 0x0b, 0x60
	.byte 0x06, 0x0f, 0x00, 0x05, 0x57, 0x65, 0xf1, 0x00
	.byte 0x02, 0x0f, 0x6a, 0x06, 0x0f, 0x00, 0x20, 0x01
	.byte 0x5b, 0xf1, 0x00, 0x0d, 0x00, 0x8e, 0x1e, 0x02
	.byte 0x0f, 0x6a, 0x06, 0x80, 0x07, 0x20, 0x15, 0x65
	.byte 0xf1, 0x00, 0x0d, 0x00, 0x8e, 0x1e, 0x4f, 0x46
	.ascii "F          OFF          "
EffectParam_Edit_Table:
	.long EffectParamEdit_Entry_08
	.long EffectParamEdit_Entry_01
	.long EffectParamEdit_Entry_02
	.long EffectParamEdit_Entry_03
	.long EffectParamEdit_Entry_04
	.long EffectParamEdit_Entry_04
	.long EffectParamEdit_Entry_06
	.long EffectParamEdit_Entry_07
	.long EffectParamEdit_Entry_07
	.long EffectParamEdit_Entry_05
	.byte 0x0c, 0x00, 0x3b, 0x00, 0x9b, 0x00, 0x58, 0x00
	.byte 0x0c, 0x00, 0x3b, 0x00, 0x9b, 0x00, 0x58, 0x00
	.byte 0x0c, 0x00, 0x62, 0x00, 0x9b, 0x00, 0x7f, 0x00
	.byte 0x0c, 0x00, 0x8a, 0x00, 0x9b, 0x00, 0xa7, 0x00
	.byte 0x0c, 0x00, 0xb3, 0x00, 0x9b, 0x00, 0xd0, 0x00
	.byte 0xa4, 0x00, 0x3a, 0x00, 0x33, 0x01, 0x58, 0x00
	.byte 0xa4, 0x00, 0x62, 0x00, 0x33, 0x01, 0x7f, 0x00
	.byte 0xa4, 0x00, 0x8a, 0x00, 0x33, 0x01, 0xa7, 0x00
	.byte 0xa4, 0x00, 0xb3, 0x00, 0x33, 0x01, 0xd0, 0x00
	.byte 0x1b, 0x0a, 0x0c, 0x00, 0x3b, 0x00, 0x33, 0x01
	.byte 0xd0, 0x00
	.ascii "OFF-10- 9- 8- 7- 6- 5- 4- 3- 2- 1  0+ 1+ 2+ 3+ 4+ 5+ 6+ 7+ 8+ 9+10"

InitializeNaka:
	lda xsp, (xsp - 14)

	RegObjTable 0x1600004, 0xfa44e2, 0xe0e95c, 0xe0e944, 0x16b
	RegObjTable 0x160000c, 0xfa58fb, 0xe0e962, 0xe0e95e, 0x1cb
	RegObjTable 0x160000d, 0xfa5948, 0xe0e968, 0xe0e964, 0x1eb
	RegObjTabl 0x1600002, 0xfa496c, 0x12, 0xe0e7ae, 0x12b
	RegObjTabl 0x1600002, 0xfa496c, 0x12, 0xe0e7fa, 0x42b
	RegObjTabl 0x1600001, 0xfa48a9, 0x0, 0xe0e96a, 0x10b
	RegObjTabl 0x1600001, 0xfa48a9, 0x0, 0xe0e96e, 0x40b
	RegObjTabl 0x1600003, 0xfa4a18, 0x0, 0xe14824, 0x14b
	RegObjTabl 0x1600003, 0xfa4a18, 0x0, 0xe14828, 0x44b
	RegObjTabl 0x1600010, 0xfa5995, 0x1de, NAKA_UIObjectTable, 0xfd
	RegObjTabl 0x160000f, 0xfa62cb, 0x1de, 0xe13bca, 0x3fd

	RegTitle 0xb, 0xe1, 0x481a, 0xfd, 0x1200000, 0xfd0000
	lda xsp, (xsp + 14)
	ret

NAKA_InitDataBlock:
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, NAKA_UIObjectTable_0x13E0
	ret
	lds32	xhl, 0
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, NAKA_UIObjectTable_0x1452
	ret
	lds32	xhl, 0
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, NAKA_UIObjectTable_0x1492
	ret
	lds32	xhl, 0
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, NAKA_UIObjectTable_0x1684
	ret
	lds32	xhl, 0
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, NAKA_UIObjectTable_0x16FC
	ret
	lds32	xhl, 0
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, NAKA_UIObjectTable_0x186C
	ret
	lds32	xhl, 0
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, NAKA_UIObjectTable_0x19FE
	ret
	lds32	xhl, 0
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, NAKA_UIObjectTable_0x1B8A
	ret
	lds32	xhl, 0
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, NAKA_UIObjectTable_0x1D6E
	ret
	lds32	xhl, 0
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, NAKA_UIObjectTable_0x1DF2
	ret
	lds32	xhl, 0
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, NAKA_UIObjectTable_0x1F94
	ret
	lds32	xhl, 0
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, NAKA_UIObjectTable_0x2004
	ret
	lds32	xhl, 0
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, NAKA_UIObjectTable_0x2166
	ret
	lds32	xhl, 0
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, NAKA_UIObjectTable_0x21E0
	ret
	lds32	xhl, 0
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, NAKA_UIObjectTable_0x2342
	ret
	lds32	xhl, 0
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, NAKA_UIObjectTable_0x24B2
	ret
	lds32	xhl, 0
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, NAKA_UIObjectTable_0x2512
	ret
	lds32	xhl, 0
	ret
	cp	xbc, 0x1e0009f
	jr	nz, 6
	lda_24	xhl, NAKA_UIObjectTable_0x2572
	ret
	lds32	xhl, 0
	ret
	calr	371
	calr	56
	lds	wa, 1
	calr	2205
	calr	48
	lds	wa, 2
	calr	2197
	calr	40
	lds	wa, 3
	calr	2189
	calr	32
	lds	wa, 4
	calr	2181
	calr	24
	lds	wa, 5
	calr	2173
	calr	16
	lds	wa, 6
	calr	2165
	calr	8
	lds	wa, 7
	calr	2157
	jrl	5626

NoteEvent_LoadSoundGenParams:
	st_dri3b L, 0xfd, 0x94, 0xfe
	push xiz
	ld xiy, NAKA_UIObjectTable_0x26D2
	st_dri3b D, 0xfd, 0x10, 0x01
	ldw bc, 0x30
	ldirw
	ld xiy, NAKA_UIObjectTable_0x25D2
	lda xix, (xsp + 16)
	ldw bc, 0x80
	ldirw
	ldda32 xix, 3186
	ld xiy, MSP_Default_Signature1
	ldw bc, 0x30
	ldirw
	ldda32 xwa, 3186
	ld xiy, MSP_Default_VoiceEnable
	st_dri3b D, 0xe1, 0xc0, 0x13
	ldw bc, 0x20
	ldirw
	ldda32 xbc, 3186
	ld xwa, 0xba0
	add xbc, xwa
	ld xwa, xbc
	st_dri3b B, 0xe5, 0x80, 0x00

NoteEvent_CopyVoiceParamsLoop:
	ld xiy, MSP_Default_SoundReserved_0x30
	ld xix, xwa
	ldw bc, 0x10
	ldirw
	lda xwa, (xwa + 32)
	cp xwa, xde
	jr ule, NoteEvent_CopyVoiceParamsLoop
	ldda32 xwa, 3186
	st_dri3b W, 0xe1, 0x40, 0x0c
	ld xde, xwa
	st_dri3b W, 0xe1, 0xe0, 0x06
	ld (xsp + 12), xwa

NoteEvent_CopyExtParamsOuter:
	ld xwa, xde
	st_dri3b C, 0xe9, 0x80, 0x00

NoteEvent_CopyExtParamsInner:
	ld xiy, MSP_Default_SoundReserved_0x50
	ld xix, xwa
	ldw bc, 0x10
	ldirw
	lda xwa, (xwa + 32)
	cp xwa, xhl
	jr ule, NoteEvent_CopyExtParamsInner
	st_dri3b B, 0xe9, 0xa0, 0x00
	cp xde, (xsp + 12)
	jr ule, NoteEvent_CopyExtParamsOuter
	st_dri3b W, 0xfd, 0x10, 0x01
	ld (xsp + 4), xwa
	lda xbc, (xwa + 4)
	ld (xsp + 8), xbc
	lda xiz, (xwa + 6)
	lda xbc, (xwa + 8)
	ld (xsp + 12), xbc
	lda xhl, (xwa + 10)
	ldda32 xwa, 3186
	lda xwa, (xwa + 96)
	lds de, 4

NoteEvent_WriteRegOffsets_Loop:
	ld ix, de
	add ix, 0xfffc
	ld xbc, (xsp + 4)
	ld (xbc), ix
	ld ix, de
	add ix, 0xfffd
	ld xbc, (xsp + 8)
	ld (xbc), ix
	ld bc, de
	add bc, 0xfffe
	ld (xiz), bc
	ld ix, de
	add ix, 0xffff
	ld xbc, (xsp + 12)
	ld (xbc), ix
	ld (xhl), de
	st_dri3b E, 0xfd, 0x10, 0x01
	ld xix, xwa
	ldw bc, 0x30
	ldirw
	inc 5, de
	lda xwa, (xwa + 96)
	cp de, 0x95
	jr ule, NoteEvent_WriteRegOffsets_Loop
	lds de, 0
	ld xwa, 0x1400

NoteEvent_CopySlotData_Loop:
	cp de, 0x96
	jr c, NoteEvent_CopySlotData_Body
	ld (xsp + 16), 0x0

NoteEvent_CopySlotData_Body:
	ld xix, xwa
	addda32 xix, 3186
	lda xiy, (xsp + 16)
	ldw bc, 0x80
	ldirw
	inc 1, de
	add xwa, 0x100
	cp de, 0x153
	jr ule, NoteEvent_CopySlotData_Loop
	pop xiz
	st_dri3b L, 0xfd, 0x6c, 0x01
	ret

Flash_InitExtMemAddrs:
	lda_24 xwa, 0x300000
	stda32 3190, xwa
	ld xbc, xwa
	add xbc, 0x19800
	stda32 3194, xbc
	ld xbc, xwa
	add xbc, 0x30000
	stda32 3198, xbc
	ld xbc, xwa
	add xbc, 0x49800
	stda32 3202, xbc
	ld xbc, xwa
	add xbc, 0x60000
	stda32 3206, xbc
	ld xbc, xwa
	add xbc, 0x79800
	stda32 3210, xbc
	ld xbc, xwa
	add xbc, 0x90000
	stda32 3214, xbc
	ld xbc, xwa
	add xbc, 0xb0000
	stda32 3218, xbc
	lda_24 xwa, 0x094800
	stda32 3182, xwa
	lda_24 xwa, 0x069800
	stda32 3186, xwa
	stda32 3222, xwa
	ret

Flash_InitBytecodeBlock:
	lda	xsp, (xsp-12)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+10), c
	ld	(xsp+12), a
	ld	(xsp+2), 0
	ld	(xsp+8), 0
	calr	65397
	ld	a, (xsp+12)
	extz	wa
	.byte 0x8f
	incf
	push	xsp
	ldwio	127, 349
	calr	5349
	ld	a, (xsp+10)
	extz	wa
	calr	5538
	ld	a, (xsp+10)
	extz	wa
	calr	1567
	ld	(xsp+4), l
	ld	a, (xsp+4)
	extz	wa
	calr	1569
	call	AccPatch_CountSlotsAlt
	ld	a, (xsp+10)
	extz	wa
	lda_24	xbc, MSP_Default_GroupIndexPad
	.byte 0xc3
	reti
	.byte 0xe4, 0xe0
	ldb	a, 191
	.byte 0x06
	ld	xbc, 0x200c72e1
	stda32	0x39ae, xwa
	.byte 0xc7
	swi	3
	.byte 0xa8
	ld	c, (xsp+6)
	extz	bc
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	muls	wa, 3
	ld	de, wa
	add	de, bc
	lda_24	xwa, MSP_Default_ChannelMap
	.byte 0xc3
	reti
	.byte 0xe0, 0xe8
	pop_f
	.byte 0xac
	push	xbc
	call	AccPatch_InitFromSlotIndex
	.byte 0xc7
	swi	3
	jr	lt, -57
	swi	3
	div	l, 103
	.byte 0xd5
	ldda32	xwa, 3182
	stda32	0x39ae, xwa
	ldda32	xwa, 3186
	stda32	0x39b2, xwa
	.byte 0xf1
	lda	xiy, (xwa)
	.byte 0xb0, 0xc7
	swi	3
	.byte 0xa8
	ld	e, (xsp+12)
	extz	de
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	muls	wa, 3
	ld	bc, wa
	add	wa, de
	lda_24	xde, MSP_Default_ChannelMap
	.byte 0xc3
	reti
	or	xwa, xwa
	pop_f
	add	(xix+57), xsp
	.byte 0x06
	ldb	a, 216
	ccf
	add	bc, wa
	.byte 0xc3
	reti
	or	xix, xwa
	pop_f
	.byte 0xad
	push	xbc
	call	DualVoice_ParamLoadDone
	ldda8	a, 0x35b0
	extz	wa
	bit	0, wa
	jr	z, 6
	ld	(xsp+8), 1
	jr	9
	.byte 0xc7
	swi	3
	jr	lt, -57
	swi	3
	div	l, 103
	.byte 0xb6
	call	AccPatch_CountSlots_Wrapper
	.byte 0x8f
	ldio	63, 0
	jrl	nz, 128
	ldada	xwa, 1748
	.byte 0x90
	push	xsp
	swi	7
	swi	7
	jr	nz, 42
	.byte 0x98
	push_sr
	push	xsp
	swi	7
	swi	7
	jr	nz, 35
	calr	1748
	ld	a, (xsp+4)
	extz	wa
	calr	1449
	ldada	xwa, 1850
	.byte 0x90
	push	xsp
	swi	7
	swi	7
	jr	nz, 8
	.byte 0x98
	push_sr
	push	xsp
	swi	7
	swi	7
	jrl	z, 341
	calr	5909
	jrl	335
	ld	a, (xsp+10)
	extz	wa
	calr	6003
	ld	wa, hl
	ld	c, (xsp+10)
	extz	bc
	cps	wa, 0
	jr	nz, 42
	ld	wa, bc
	calr	1912
	ld	a, (xsp+6)
	extz	wa
	calr	2346
	calr	1681
	ld	a, (xsp+4)
	extz	wa
	calr	1382
	ld	a, (xsp+10)
	extz	wa
	calr	2721
	calr	2966
	call	TmFlash_CopyToExtMem
	jrl	274
	calr	3531
	calr	3957
	calr	4600
	calr	4730
	jrl	305
	ld	(xsp+2), 1
	jrl	273
	calr	5000
	ld	a, (xsp+10)
	extz	wa
	calr	5189
	ldda32	xix, 3186
	ldda32	xiy, 3182
	ldw	bc, 0xb400
	.byte 0x95
	scf
	ld	a, (xsp+12)
	extz	wa
	lda_24	xbc, MSP_Default_GroupIndexPad
	.byte 0xc3
	reti
	.byte 0xe4, 0xe0
	ldb	a, 191
	.byte 0x06
	ld	xbc, 0x200c72e1
	stda32	0x39ae, xwa
	.byte 0xc7
	swi	3
	.byte 0xa8
	ld	c, (xsp+10)
	extz	bc
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	muls	wa, 3
	ld	de, wa
	add	de, bc
	lda_24	xwa, MSP_Default_ChannelMap
	.byte 0xc3
	reti
	.byte 0xe0, 0xe8
	pop_f
	.byte 0xac
	push	xbc
	call	AccPatch_InitFromSlotIndex
	.byte 0xc7
	swi	3
	jr	lt, -57
	swi	3
	div	l, 103
	.byte 0xd5
	ld	a, (xsp+12)
	extz	wa
	calr	320
	stda32	0x39ae, xhl
	ldda32	xwa, 3186
	stda32	0x39b2, xwa
	.byte 0xf1
	lda	xiy, (xwa)
	.byte 0xb0, 0xc7
	swi	3
	.byte 0xa8
	ld	e, (xsp+6)
	extz	de
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	muls	wa, 3
	ld	bc, wa
	add	wa, de
	lda_24	xde, MSP_Default_ChannelMap
	.byte 0xc3
	reti
	or	xwa, xwa
	pop_f
	add	(xix+57), xsp
	ldwio	33, 4824
	add	bc, wa
	.byte 0xc3
	reti
	or	xix, xwa
	pop_f
	.byte 0xad
	push	xbc
	call	DualVoice_ParamLoadDone
	ldda8	a, 0x35b0
	extz	wa
	bit	0, wa
	jr	z, 24
	ld	(xsp+8), 1
	ldda32	xwa, 0x39b2
	stda32	0x39ae, xwa
	.byte 0xc1, 0xad
	push	xbc
	pop_f
	.byte 0xac
	push	xbc
	call	AccPatch_InitFromSlotIndex
	jr	9
	.byte 0xc7
	swi	3
	jr	lt, -57
	swi	3
	div	l, 103
	add	(xix), xsp
	ldio	63, 0
	jrl	nz, -229
	ldada	xwa, 1748
	.byte 0x90
	push	xsp
	swi	7
	swi	7
	jr	nz, 55
	.byte 0x98
	push_sr
	push	xsp
	swi	7
	swi	7
	jr	nz, 48
	ldda32	xix, 3182
	ldda32	xiy, 3186
	ldw	bc, 0xb400
	.byte 0x95
	scf
	.byte 0x8f
	push_sr
	push	xsp
	push_sr
	jr	nz, 15
	.byte 0x8f
	incf
	pop_f
	jr	12
	.byte 0x8f
	ldwio	25, 3178
	.byte 0x8f, 0x06
	pop_f
	jr	nov, 12
	call	AccPatch_CountSlots_Wrapper
	ld	l, (xsp+2)
	.byte 0xd7
	swi	2
	halt
	lda	xsp, (xsp+12)
	ret
	ld	a, (xsp+10)
	extz	wa
	calr	1754
	calr	4032
	ld	(xsp+2), 2
	.byte 0x8f
	incf
	pop_f
	jr	12
	.byte 0x8f
	ldwio	25, 3178
	.byte 0x8f, 0x06
	pop_f
	jr	nov, 12
	jr	-67
	dec	2, xsp
	ld	(xsp), a
	calr	64710
	ldda8	l, 3176
	ldda8	c, 3178
	ldda8	e, 3180
	.byte 0x87
	push	xsp
	push_sr
	jr	z, 26
	.byte 0x87
	push	xsp
	nop
	jr	nz, 21
	ld	a, l
	extz	wa
	extz	bc
	extz	de
	cp	l, 10
	jr	nc, 5
	calr	5818
	jr	3
	calr	6231
	ldb	l, 0
	inc	2, xsp
	ret
	dec	2, xsp
	ld	(xsp), a
	calr	64655
	ldda8	a, 3176
	ldda8	c, 3178
	ldda8	e, 3180
	.byte 0x87
	push	xsp
	push_sr
	jr	z, 14
	.byte 0x87
	push	xsp
	nop
	jr	nz, 9
	extz	wa
	extz	bc
	extz	de
	calr	6188
	call	AccPatch_CountSlots_Wrapper
	ldb	l, 0
	inc	2, xsp
	ret
	jrl	-1298

; PartGrid column dispatch (7-entry, table 0xe1611a)
PartGrid_ColumnDispatch:
	ldda32 xhl, 3182
	ldda32 xbc, 3186
	cp a, 0x1e
	jr nc, PartGrid_CopyHLtoBC
	cp a, 0xa
	ret c
	sub a, 0xa
	extz wa
	div a, 0x3
	extz wa
	cps wa, 0
	jr mi, PartGrid_CopyHLtoBC
	cps wa, 6
	jr gt, PartGrid_CopyHLtoBC
	add wa, wa
	lda_24 xix, MSP_Default_GroupOffsetA
	ld_sriw3 WA, 0x07, 0xf0, 0xe0
	lda_24 xix, PartGrid_ColumnJumpTable
	jp_dri 8, 0x07, 0xf0, 0xe0

PartGrid_ColumnJumpTable:
	ldda32	xhl, 3190
	jr	38
	ldda32	xhl, 3194
	jr	32
	ldda32	xhl, 3198
	jr	26
	ldda32	xhl, 3202
	jr	20
	ldda32	xhl, 3206
	jr	14
	ldda32	xhl, 3210
	jr	8
	ldda32	xhl, 3214
	jr	t, 0x02

PartGrid_CopyHLtoBC:
	ld xhl, xbc
	ret

Util_FrameSetup10:
	lda xsp, (xsp - 10)
	ld (xsp + 4), e
	ld (xsp + 6), c
	ld (xsp + 8), a
	ld a, (xsp + 8)
	extz wa
	calr PartGrid_ColumnDispatch
	ld (xsp), xhl
	cp (xsp + 8), 0x1e
	jr c, FrameSetup_AdjustGE1E
	submi8 (xsp + 8), 0x1e
	jr FrameSetup_ComputeGridIndex

FrameSetup_AdjustGE1E:
	cp (xsp + 8), 0xa
	jr c, FrameSetup_ComputeGridIndex
	submi8 (xsp + 8), 0xa
	ld a, (xsp + 8)
	extz wa
	div a, 0x3
	ld (xsp + 8), w

FrameSetup_ComputeGridIndex:
	ld c, (xsp + 8)
	extz bc
	ld a, (xsp + 6)
	extz wa
	muls wa, 0x3
	add wa, bc
	lda_24 xbc, MSP_Default_ChannelMap
	ld_srib3 A, 0x07, 0xe4, 0xe0
	ld e, (xsp + 4)
	cp (xsp + 4), 0x4
	jr z, FrameSetup_SpecialCase4
	extz wa
	muls wa, 0x60
	ld bc, wa
	add bc, 0x60
	ld xwa, (xsp)
	exts xbc
	add xbc, xwa
	cps e, 3
	jr z, FrameSetup_RowOffset3
	cps e, 2
	jr z, FrameSetup_RowOffset2
	cps e, 1
	jr z, FrameSetup_RowOffset1
	cps e, 0
	jr nz, FrameSetup_PackResult
	ld l, (xbc + 24)
	ld xwa, 0x19
	jr PartGrid_ByteOffsetLoop

FrameSetup_RowOffset1:
	ld l, (xbc + 32)
	ld xwa, 0x21
	jr PartGrid_ByteOffsetLoop

FrameSetup_RowOffset2:
	ld l, (xbc + 40)
	ld xwa, 0x29
	jr PartGrid_ByteOffsetLoop

FrameSetup_RowOffset3:
	ld l, (xbc + 48)
	ld xwa, 0x31

PartGrid_ByteOffsetLoop:
	add xbc, xwa
	ld a, (xbc)
	jr FrameSetup_PackResult

FrameSetup_SpecialCase4:
	extz wa
	muls wa, 0x60
	ld bc, wa
	add bc, 0x60
	ld xwa, (xsp)
	st_dri3b W, 0x07, 0xe0, 0xe4
	ld l, (xwa + 56)
	ld a, (xwa + 57)

FrameSetup_PackResult:
	ld c, l
	extz bc
	extz wa
	sll wa, 8
	or wa, bc
	ld hl, wa
	lda xsp, (xsp + 10)
	ret

PartGrid_OperationsBlock:
	lda	xsp, (xsp-14)
	ld	(xsp+8), e
	ld	(xsp+10), c
	ld	(xsp+12), a
	ld	a, (xsp+12)
	extz	wa
	calr	65203
	ld	(xsp+4), xhl
	cp	(xsp+12), 30
	jr	c, 6
	.byte 0x8f
	incf
	push	xde
	.byte 0x1e
	jr	21
	cp	(xsp+12), 10
	jr	c, 15
	.byte 0x8f
	incf
	push	xde
	.byte 0x0a
	ld	a, (xsp+12)
	extz	wa
	div	a, 3
	ld	(xsp+12), w
	ld	c, (xsp+12)
	extz	bc
	ld	a, (xsp+10)
	extz	wa
	muls	wa, 3
	add	wa, bc
	lda_24	xbc, MSP_Default_ChannelMap
	ld_rrb	a, xbc, wa
	ld	(xsp+2), a
	ld	bc, (xsp+18)
	ld	de, bc
	ldb	d, 0
	srl	bc, 8
	ld	(xsp), c
	ld	a, (xsp+2)
	extz	wa
	muls	wa, 96
	ld	bc, wa
	add	bc, 96
	ld	xwa, (xsp+4)
	exts	xbc
	add	xbc, xwa
	cp	(xsp+8), 4
	jr	z, 64
	cp	(xsp+8), 3
	jr	z, 48
	cp	(xsp+8), 2
	jr	z, 32
	cp	(xsp+8), 1
	jr	z, 16
	cp	(xsp+8), 0
	jr	nz, 54
	ld	(xbc+24), e
	ld	xwa, 25
	jr	38
	.byte 0xb9
	.asciz " E@!"
	nop
	nop
	jr	28
	.byte 0xb9
	.asciz "(E@)"
	nop
	nop
	jr	18
	ld	(xbc+48), e
	ld	xwa, 49
	jr	8
	ld	(xbc+56), e
	ld	xwa, 57
	add	xbc, xwa
	ld	a, (xsp)
	ld	(xbc), a
	lda	xsp, (xsp+14)
	retd	2

; PartGrid column dispatch end
PartGrid_ColumnDispatch_End:
	lds wa, 0
	jr PartGrid_ColumnDispatch_Default

; PartGrid column dispatch default case
PartGrid_ColumnDispatch_Default:
	dec 2, xsp
	push xiz
	ld (xsp + 4), a
	ldi_werp 0xfa, 0

PartGrid_DefaultLoop_Outer:
	ldto_werp WA, 0xfa
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 5
	add xbc, 0x60
	addda32 xbc, 3186
	ld wa, (xbc)
	ld c, (xsp + 4)
	extz bc
	calr Pack12BitValueWithBank
	ld wa, hl
	ldto_werp BC, 0xfa
	extz xbc
	ld xde, xbc
	add xde, xde
	add xde, xbc
	sll xde, 5
	add xde, 0x60
	addda32 xde, 3186
	ld (xde), wa
	lds iz, 2

PartGrid_DefaultLoop_Inner:
	ld bc, iz
	extz xbc
	add xbc, xbc
	ldto_werp WA, 0xfa
	extz xwa
	ld xde, xwa
	add xde, xde
	add xde, xwa
	sll xde, 5
	add xde, xbc
	addda32 xde, 3186
	ld wa, (xde + 96)
	ld c, (xsp + 4)
	extz bc
	calr Pack12BitValueWithBank
	ld wa, hl
	ld de, iz
	extz xde
	add xde, xde
	ldto_werp BC, 0xfa
	extz xbc
	ld xhl, xbc
	add xhl, xhl
	add xhl, xbc
	sll xhl, 5
	add xhl, xde
	addda32 xhl, 3186
	ld (xhl + 96), wa
	inc 1, iz
	cps iz, 5
	jr ule, PartGrid_DefaultLoop_Inner
	inc1_werp 0xfa
	cp_erpw 0xfa, 0x1d, 0x00
	jrl ule, PartGrid_DefaultLoop_Outer
	ldi_werp 0xfa, 0

; NoteEventBuffer CopyToSlot dispatch (7-entry, table 0xe16128)
NoteEvent_CopyToSlot:
	ldto_werp WA, 0xfa
	extz xwa
	sll xwa, 8
	add xwa, 0x1400
	addda32 xwa, 3186
	ld wa, (xwa + 1)
	ld c, (xsp + 4)
	extz bc
	calr Pack12BitValueWithBank
	ld wa, hl
	ldto_werp BC, 0xfa
	extz xbc
	sll xbc, 8
	add xbc, 0x1400
	ld xde, xbc
	addda32 xde, 3186
	ld (xde + 1), wa
	addda32 xbc, 3186
	ld wa, (xbc + 3)
	ld c, (xsp + 4)
	extz bc
	calr Pack12BitValueWithBank
	ld wa, hl
	ldto_werp BC, 0xfa
	extz xbc
	sll xbc, 8
	add xbc, 0x1400
	addda32 xbc, 3186
	ld (xbc + 3), wa
	inc1_werp 0xfa
	cp_erpw 0xfa, 0x53, 0x01
	jr ule, NoteEvent_CopyToSlot
	pop xiz
	inc 2, xsp
	ret

Pack12BitValueWithBank:
	ld hl, wa
	cp hl, 0xffff
	ret z
	and hl, 0xfff
	extz bc
	sll bc, 12
	or hl, bc
	ret

; NoteEventBuffer Store dispatch (7-entry, table 0xe16136)
NoteEvent_Store:
	extz wa
	lda_24 xbc, MSP_Default_ChannelMap_0x1E
	ld_srib3 L, 0x07, 0xe4, 0xe0
	ret

NoteEventBuffer_CopyToSlot:
	ld c, a
	ldda32 xwa, 3186
	extz bc
	dec 1, bc
	cps bc, 0
	jr lt, NoteEvent_CopyCommon
	cps bc, 6
	jr gt, NoteEvent_CopyCommon
	add bc, bc
	lda_24 xix, MSP_Default_GroupOffsetB
	ld_sriw3 BC, 0x07, 0xf0, 0xe4
	lda_24 xix, NOTE_EVENT_DISPATCH_1
	jp_dri 8, 0x07, 0xf0, 0xe4
; Note event buffer copy dispatch - 7 cases (BC 0-6)
; Selects destination buffer pointer based on case, then copies 46080 bytes
; Offset table at 0xe16128
NOTE_EVENT_DISPATCH_1:
	ldda32 xbc, 3190	; Case 0: Load dest pointer
	jr NOTE_EVENT_COPY_COMMON
	ldda32 xbc, 3194	; Case 1: Load dest pointer
	jr NOTE_EVENT_COPY_COMMON
	ldda32 xbc, 3198	; Case 2: Load dest pointer
	jr NOTE_EVENT_COPY_COMMON
	ldda32 xbc, 3202	; Case 3: Load dest pointer
	jr NOTE_EVENT_COPY_COMMON
	ldda32 xbc, 3206	; Case 4: Load dest pointer
	jr NOTE_EVENT_COPY_COMMON
	ldda32 xbc, 3210	; Case 5: Load dest pointer
	jr NOTE_EVENT_COPY_COMMON
	ldda32 xbc, 3214	; Case 6: Load dest pointer (falls through)
NOTE_EVENT_COPY_COMMON:	; F1717D - Common handler
	ld xiy, xbc	; XIY = destination pointer
	ld xix, xwa	; XIX = source pointer
	ldw bc, 0xb400	; BC = 0xb400 byte count
	ldirw	; Block copy words

; NoteEventBuffer copy common handler
NoteEvent_CopyCommon:
	jrl PartGrid_ColumnDispatch_End

NoteEventBuffer_Store:
	lda xsp, (xsp - 10)
	ld (xsp + 8), a
	ld a, (xsp + 8)
	extz wa
	calr PartGrid_ColumnDispatch_Default
	ldda32 xwa, 3186
	ld (xsp), xwa
	ld a, (xsp + 8)
	extz wa
	dec 1, wa
	cps wa, 0
	jrl lt, NoteEvent_StoreCommon
	cps wa, 6
	jrl gt, NoteEvent_StoreCommon
	add wa, wa
	lda_24 xix, MSP_Default_VarSize
	ld_sriw3 WA, 0x07, 0xf0, 0xe0
	lda_24 xix, NOTE_EVENT_DISPATCH_2
	jp_dri 8, 0x07, 0xf0, 0xe0
; Note event dispatch table 2
; 7 cases (WA 0-6), offset table at 0xe16136
NOTE_EVENT_DISPATCH_2:
	ldda32 xwa, 3190
	ld (xsp + 4), xwa
	jrl Flash_WriteSectorWithMirrorCopy
NOTE_EVENT_DISPATCH_2b:
	ldda32 xwa, 3194
	ld (xsp + 4), xwa

Flash_SectorWriteExecute:
	ld xwa, (xsp)
	st_dri3b A, 0xe1, 0x00, 0x68
	ld xwa, (xsp + 4)
	st_dri3b B, 0xe1, 0x00, 0x68
	lds wa, 1
	call Flash_EraseSectorAndWrite
	ld xiy, (xsp + 4)
	sub xiy, 0x9800
	ld xwa, (xsp)
	st_dri3b B, 0xe1, 0x00, 0x68
	ld xix, xde
	ldw bc, 0x8000
	ldirw
	ld xbc, (xsp)

Flash_CopyMirrorLoop:
	ld xhl, xbc
	add xhl, 0x10000
	ld_spib A, 0xe4
	ld (xhl), a
	cp xbc, xde
	jr c, Flash_CopyMirrorLoop
	ld xwa, (xsp)
	st_dri3b A, 0xe1, 0x00, 0x68
	ld xde, (xsp + 4)
	sub xde, 0x9800
	lds wa, 1
	jr Flash_EraseAndWriteFinal
	ldda32 xwa, 3198
	ld (xsp + 4), xwa
	jr Flash_WriteSectorWithMirrorCopy
	ldda32 xwa, 3202
	ld (xsp + 4), xwa
	jr Flash_SectorWriteExecute
	ldda32 xwa, 3206
	ld (xsp + 4), xwa
	jr Flash_WriteSectorWithMirrorCopy
	ldda32 xwa, 3210
	ld (xsp + 4), xwa
	jr Flash_SectorWriteExecute
	ldda32 xwa, 3214
	ld (xsp + 4), xwa
	jr Flash_WriteSectorWithMirrorCopy

; NoteEventBuffer store common handler
NoteEvent_StoreCommon:
	cps a, 0
	jrl nz, Flash_SectorWriteExecute

Flash_WriteSectorWithMirrorCopy:
	lds wa, 1
	ld xbc, (xsp)
	ld xde, (xsp + 4)
	call Flash_EraseSectorAndWrite
	ld xiy, (xsp + 4)
	add xiy, 0x10000
	ld xwa, (xsp)
	ld xix, xwa
	ldw bc, 0x8000
	ldirw
	ld xwa, (xsp)
	add xwa, 0x10000
	ld xbc, xwa
	st_dri3b B, 0xe1, 0x00, 0x68

Flash_CopyReverseMirrorLoop:
	ld xhl, xbc
	add xhl, 0xffff0000
	ld_spib A, 0xe4
	ld (xhl), a
	cp xbc, xde
	jr c, Flash_CopyReverseMirrorLoop
	ld xde, (xsp + 4)
	add xde, 0x10000
	lds wa, 1
	ld xbc, (xsp)

Flash_EraseAndWriteFinal:
	call Flash_EraseSectorAndWrite
	lda xsp, (xsp + 10)
	ret

Flash_StoreBaseAndInitAccPatch:
	ldda32 xwa, 3186
	stda32 0x39ae, xwa
	jp AccPatch_InitSlotChain_Wrap
Flash_ExtendedOpsBlock:
	push	xiz
	extz	de
	lda_24	xix, MSP_Default_ChannelMap
	.byte 0xf3
	reti
	.byte 0xf0, 0xe8
	ldw	hl, 37
	cp	a, 10
	jr	nc, 74
	ld	c, (xhl)
	extz	wa
	.byte 0xc3
	reti
	.byte 0xf0, 0xe0
	ldb	l, 220
	add	(xwa-53), xbc
	exts	wa
	muls	wa, 96
	ld	iy, wa
	add	iy, ix
	ldda32	xwa, 3186
	.byte 0xf3
	reti
	.byte 0xe0, 0xf4
	ldw	iz, 0x89cf
	exts	wa
	muls	wa, 96
	ld	iy, wa
	add	iy, ix
	ldda32	xwa, 3182
	.byte 0xf3
	reti
	.byte 0xe0, 0xf4, 0x30
	ld	a, (xwa+160)
	.byte 0xf3
	swi	1
	.byte 0xa0
	nop
	ld	xbc, 0x61dc61cd
	cp	e, 16
	jr	c, -61
	jr	72
	extz	bc
	.byte 0xc3
	reti
	.byte 0xf0, 0xe4
	ldb	c, 131
	ldb	l, 220
	add	(xwa-53), xbc
	exts	wa
	muls	wa, 96
	ld	iy, wa
	add	iy, ix
	ldda32	xwa, 3182
	.byte 0xf3
	reti
	.byte 0xe0, 0xf4
	ldw	iz, 0x89cf
	exts	wa
	muls	wa, 96
	ld	iy, wa
	add	iy, ix
	ldda32	xwa, 3186
	.byte 0xf3
	reti
	.byte 0xe0, 0xf4, 0x30
	ld	a, (xwa+160)
	ld	(xiz+160), a
	inc	1, e
	inc	1, ix
	cp	e, 16
	jr	c, -61
	pop	xiz
	ret
	ldda32	xbc, 3182
	lda	xhl, (xbc+16)
	add	e, 32
	extz	de
	add	de, 16
	ldda32	xbc, 3186
	.byte 0xf3
	reti
	.byte 0xe4, 0xe8
	ldw	bc, 0xcfc9
	ldwio	111, 0x8305
	ldb	a, 177
	ld	xbc, 0xb321810e
	ld	xbc, 0x2e6aef0e
	ld	(xsp+2), a
	calr	3601
	ldada	xix, 1748
	.byte 0x94
	push	xsp
	swi	7
	swi	7
	jr	z, 53
	ldb	l, 0
	ldda32	xbc, 3218
	ld	a, l
	extz	wa
	add	wa, 80
	.byte 0xc3
	reti
	.byte 0xe4, 0xe0
	ldb	a, 201
	inc	6, wa
	halt
	.byte 0x8f
	push_sr
	.byte 0xf1
	jr	nz, 19
	ldada	xbc, 1952
	ld	wa, (xix)
	ld	(xbc), wa
	extz	hl
	or	hl, 1280
	ld	(xbc+2), hl
	jr	6
	inc	1, l
	cps	l, 4
	jr	c, -47
	ldb	h, 0
	ldb	l, 0
	.byte 0xc7
	lds32	xde, 0
	.byte 0xc7
	ld	xbc, xde
	extz	wa
	add	wa, wa
	inc	2, wa
	.byte 0xf3
	reti
	.byte 0xf0, 0xe0
	ldw	bc, 0x3f91
	swi	7
	swi	7
	jr	z, 93
	cp	l, 40
	jr	nc, 79
	ld	e, l
	extz	de
	add	de, 16
	ldda32	xwa, 3218
	.byte 0xc3
	reti
	.byte 0xe0, 0xe8
	ldb	a, 201
	inc	6, wa
	halt
	.byte 0x8f
	push_sr
	.byte 0xf1
	jr	nz, 46
	ld	e, h
	extz	de
	sla	de, 2
	ld	iz, de
	inc	4, iz
	ldada	xiy, 1952
	ld	wa, (xbc)
	.byte 0xf3
	reti
	.byte 0xf4
	swi	0
	.byte 0x50
	inc	6, de
	ld	a, l
	set	7, a
	extz	wa
	or	wa, 1280
	.byte 0xf3
	reti
	.byte 0xf4, 0xe8, 0x50
	inc	1, h
	inc	1, l
	jr	7
	inc	1, l
	cp	l, 40
	jr	c, -79
	.byte 0xc7
	inc	1, xde
	.byte 0xc7
	cp	xde, 0x4e8f6732
	inc	2, xsp
	ret
	dec	6, xsp
	ld	(xsp+4), a
	calr	3406
	ldada	xwa, 1748
	.byte 0x90
	push	xsp
	swi	7
	swi	7
	jr	z, 13
	ldada	xbc, 1952
	ld	wa, (xwa)
	ld	(xbc), wa
	.byte 0xb9
	push_sr
	push_sr
	nop
	.byte 0x06
	ld	a, (xsp+4)
	extz	wa
	calr	3950
	ld	(xsp+2), 0
	ld	(xsp), 0
	ld	a, (xsp)
	extz	wa
	add	wa, wa
	inc	2, wa
	ldada	xbc, 1748
	.byte 0xd3
	reti
	.byte 0xe4, 0xe0
	ldb	a, 217
	.byte 0xcf
	swi	7
	swi	7
	jrl	z, 173
	ldb	l, 0
	ldb	h, 39
	sub	h, l
	ld	a, h
	extz	wa
	add	wa, wa
	inc	2, wa
	ldada	xix, 3074
	.byte 0xf3
	reti
	.byte 0xf0, 0xe0
	ldw	de, 8338
	.byte 0xc7
	ld32_24	xbc, 0x28f99
	extz	wa
	.byte 0xc7
	ld32_24	xiz, 0x6effcf
	sla	wa, 2
	ld	iy, wa
	inc	4, iy
	ldada	xix, 1952
	.byte 0xf3
	reti
	.byte 0xf0, 0xf4, 0x51
	ld	bc, wa
	inc	6, bc
	set	7, h
	ld	l, h
	extz	hl
	.byte 0xf3
	reti
	.byte 0xf0, 0xe4, 0x53, 0xb2
	push_sr
	push_sr
	nop
	jr	76
	inc	1, l
	cp	l, 40
	jr	c, -82
	ldb	l, 0
	ld	iy, wa
	ldb	h, 39
	sub	h, l
	ld	a, h
	extz	wa
	add	wa, wa
	inc	2, wa
	.byte 0xf3
	reti
	.byte 0xf0, 0xe0
	ldw	de, 8338
	.byte 0xc7, 0xe2, 0x99, 0xc7, 0xe2
	dec	6, bc
	pushw	hl
	ld	wa, iy
	sla	wa, 2
	ld	iy, wa
	inc	4, iy
	ldada	xix, 1952
	.byte 0xf3
	reti
	.byte 0xf0, 0xf4, 0x51
	ld	bc, wa
	inc	6, bc
	set	7, h
	ld	l, h
	extz	hl
	.byte 0xf3
	reti
	.byte 0xf0, 0xe4, 0x53, 0xb2
	push_sr
	push_sr
	nop
	incm8	1, (xsp+2)
	jr	7
	inc	1, l
	cp	l, 40
	jr	c, -77
	.byte 0x87
	jr	lt, 0x87
	.ascii "?2w;ÿï"
	jr	z, 14
	dec	2, xsp
	push	xiz
	ld	(xsp+4), a
	.byte 0xd1, 0xa0
	reti
	push	xsp
	swi	7
	swi	7
	jr	z, 69
	.byte 0xc7
	swi	1
	.byte 0xa8
	ld	a, (xsp+4)
	add	a, 30
	.byte 0xc7
	swi	2
	cp	(xbc-57), bc
	cp	(xbc-57), c
	cp	(xbc-57), de
	.byte 0x89
	extz	wa
	.byte 0xc7
	swi	3
	.byte 0x8b
	extz	bc
	lds	de, 0
	calr	63721
	ldada	xwa, 1952
	.byte 0x90, 0xf3
	jr	nz, 19
	ld	hl, (xwa+2)
	.byte 0xc7
	swi	2
	.byte 0x89
	extz	wa
	.byte 0xc7
	swi	3
	.byte 0x8b
	extz	bc
	pushw	hl
	lds	de, 0
	calr	63904
	.byte 0xc7
	swi	1
	jr	lt, -57
	swi	1
	div	l, 103
	.byte 0xbe, 0xc7
	swi	0
	cp	(xwa-57), xwa
	.byte 0x8b
	extz	bc
	sla	bc, 2
	ldada	xwa, 1956
	.byte 0xd3
	reti
	.byte 0xe0, 0xe4
	push	xsp
	swi	7
	swi	7
	jrl	z, 282
	.byte 0xc7
	swi	1
	.byte 0xa8
	ld	a, (xsp+4)
	add	a, 30
	.byte 0xc7
	swi	2
	cp	(xbc-57), bc
	cp	(xbc-57), c
	cp	(xbc-57), de
	.byte 0x89
	extz	wa
	.byte 0xc7
	swi	3
	.byte 0x8b
	extz	bc
	lds	de, 1
	calr	63627
	.byte 0xc7
	swi	0
	.byte 0x89
	extz	wa
	sla	wa, 2
	ld	de, wa
	inc	4, de
	ldada	xbc, 1952
	.byte 0xd3
	reti
	.byte 0xe4
	cp	xhl, xwa
	jr	nz, 23
	inc	6, wa
	.byte 0xd3
	reti
	.byte 0xe4, 0xe0
	ldb	c, 199
	swi	2
	.byte 0x89
	extz	wa
	.byte 0xc7
	swi	3
	.byte 0x8b
	extz	bc
	pushw	hl
	lds	de, 1
	calr	63791
	.byte 0xc7
	swi	2
	.byte 0x89
	extz	wa
	.byte 0xc7
	swi	3
	.byte 0x8b
	extz	bc
	lds	de, 2
	calr	63566
	.byte 0xc7
	swi	0
	.byte 0x89
	extz	wa
	sla	wa, 2
	ld	de, wa
	inc	4, de
	ldada	xbc, 1952
	.byte 0xd3
	reti
	.byte 0xe4
	cp	xhl, xwa
	jr	nz, 23
	inc	6, wa
	.byte 0xd3
	reti
	.byte 0xe4, 0xe0
	ldb	c, 199
	swi	2
	.byte 0x89
	extz	wa
	.byte 0xc7
	swi	3
	.byte 0x8b
	extz	bc
	pushw	hl
	lds	de, 2
	calr	63730
	.byte 0xc7
	swi	2
	.byte 0x89
	extz	wa
	.byte 0xc7
	swi	3
	.byte 0x8b
	extz	bc
	lds	de, 3
	calr	63505
	.byte 0xc7
	swi	0
	.byte 0x89
	extz	wa
	sla	wa, 2
	ld	de, wa
	inc	4, de
	ldada	xbc, 1952
	.byte 0xd3
	reti
	.byte 0xe4
	cp	xhl, xwa
	jr	nz, 23
	inc	6, wa
	.byte 0xd3
	reti
	.byte 0xe4, 0xe0
	ldb	c, 199
	swi	2
	.byte 0x89
	extz	wa
	.byte 0xc7
	swi	3
	.byte 0x8b
	extz	bc
	pushw	hl
	lds	de, 3
	calr	63669
	.byte 0xc7
	swi	2
	.byte 0x89
	extz	wa
	.byte 0xc7
	swi	3
	.byte 0x8b
	extz	bc
	lds	de, 4
	calr	63444
	.byte 0xc7
	swi	0
	.byte 0x89
	extz	wa
	sla	wa, 2
	ld	de, wa
	inc	4, de
	ldada	xbc, 1952
	.byte 0xd3
	reti
	.byte 0xe4
	cp	xhl, xwa
	jr	nz, 23
	inc	6, wa
	.byte 0xd3
	reti
	.byte 0xe4, 0xe0
	ldb	c, 199
	swi	2
	.byte 0x89
	extz	wa
	.byte 0xc7
	swi	3
	.byte 0x8b
	extz	bc
	pushw	hl
	lds	de, 4
	calr	63608
	.byte 0xc7
	swi	1
	jr	lt, -57
	swi	1
	div	l, 119
	.byte 0xf3
	swi	6
	.byte 0xc7
	swi	0
	jr	lt, -57
	swi	0
	.byte 0xcf
	ldw	de, 0xd077
	swi	6
	pop	xiz
	inc	2, xsp
	ret
	ldda32	xix, 3222
	ldda32	xiy, 3218
	ldw	bc, 0x8000
	.byte 0x95
	scf
	ldada	xhl, 1952
	ld	bc, (xhl+2)
	cp	bc, 0xffff
	jr	z, 69
	and	bc, 127
	ld	w, c
	ld	e, w
	extz	de
	add	de, 80
	ldda32	xbc, 3222
	.byte 0xf3
	reti
	.byte 0xe4, 0xe8
	ld	xbc, 0x4c66dbc8
	inc	1, w
	cps	w, 3
	jr	ugt, 70
	ld	e, w
	extz	de
	ld	ix, de
	add	ix, 80
	ldda32	xbc, 3222
	.byte 0xf3
	reti
	.byte 0xe4, 0xf0
	ldw	bc, 0xf981
	jr	nz, 3
	ld	(xbc), 0
	inc	1, w
	inc	1, de
	cps	w, 3
	jr	ule, -30
	jr	34
	ldb	w, 0
	lds	de, 0
	ld	ix, de
	add	ix, 80
	ldda32	xbc, 3222
	.byte 0xf3
	reti
	.byte 0xe4, 0xf0
	ldw	bc, 0xf981
	jr	nz, 3
	ld	(xbc), 0
	inc	1, w
	inc	1, de
	cps	w, 4
	jr	c, -30
	ldb	w, 0
	.byte 0xc7
	addm32_24	0xe2c7a8, xhl
	extz	bc
	sla	bc, 2
	inc	6, bc
	.byte 0xd3
	reti
	or	xix, xix
	ldb	a, 217
	.byte 0xcf
	swi	7
	swi	7
	jr	z, 34
	and	bc, 127
	ld	w, c
	ld	e, w
	extz	de
	add	de, 16
	ldda32	xbc, 3222
	.byte 0xf3
	reti
	.byte 0xe4, 0xe8
	ld	xbc, 0xe2c761c8
	jr	lt, -57
	.byte 0xe2, 0xcf
	ldw	de, 0xc967
	cp	w, 40
	jr	z, 40
	cp	w, 39
	jr	ugt, 35
	ld	e, w
	extz	de
	ld	hl, de
	add	hl, 16
	ldda32	xbc, 3222
	.byte 0xf3
	reti
	.byte 0xe4, 0xec
	ldw	bc, 0xf981
	jr	nz, 3
	ld	(xbc), 0
	inc	1, w
	inc	1, de
	cp	w, 39
	jr	ule, -31
	ldda32	xbc, 3222
	ldda32	xde, 3218
	lds	wa, 1
	jp	Flash_EraseSectorAndWrite
	lda	xsp, (xsp-12)
	push	xiz
	ldda32	xix, 3222
	ldda32	xiy, 3218
	ldw	bc, 0x8000
	.byte 0x95
	scf
	ldada	xwa, 1952
	.byte 0x90
	push	xsp
	swi	7
	swi	7
	jr	z, 105
	ld	hl, (xwa)
	ldb	h, 0
	ld	wa, (xwa+2)
	ldb	w, 0
	ld	(xsp+4), a
	ld	c, l
	extz	bc
	lda	xde, (xsp+12)
	lda	xwa, (xsp+10)
	push	xwa
	lds	wa, 2
	call	TmFlash_WriteRoutine
	ld	xiz, (xsp+12)
	ld	wa, (xsp+10)
	ld	(xsp+8), wa
	cps	hl, 0
	jr	nz, 63
	ld	c, (xsp+4)
	extz	bc
	lda	xde, (xsp+12)
	lda	xwa, (xsp+10)
	push	xwa
	lds	wa, 3
	call	TmFlash_WriteRoutine
	ld	xix, (xsp+12)
	sub	xix, 0x346800
	cps	hl, 0
	jr	nz, 32
	lds	hl, 0
	.byte 0x9f
	ldio	63, 0
	nop
	jr	ule, 23
	lds32	xbc, 0
	ld	xde, xbc
	add	xde, xix
	ld	xwa, xbc
	add	xwa, xiz
	ld	a, (xwa)
	ld	(xde), a
	inc	1, hl
	inc	1, xbc
	.byte 0x9f
	ldio	243, 103
	.byte 0xeb
	ld	(xsp+6), 0
	ld	c, (xsp+6)
	extz	bc
	sla	bc, 2
	ld	wa, bc
	inc	4, wa
	ldada	xde, 1952
	.byte 0xd3
	reti
	or	xwa, xwa
	ldb	w, 216
	.byte 0xcf
	swi	7
	swi	7
	jr	z, 125
	ldb	w, 0
	ld	l, a
	inc	6, bc
	.byte 0xd3
	reti
	or	xix, xwa
	ldb	w, 32
	nop
	ld	(xsp+4), a
	res	7, l
	.byte 0xbf, 0x04, 0xb7
	ld	c, l
	extz	bc
	lda	xde, (xsp+12)
	lda	xwa, (xsp+10)
	push	xwa
	lds	wa, 0
	call	TmFlash_WriteRoutine
	ld	xiz, (xsp+12)
	ld	wa, (xsp+10)
	ld	(xsp+8), wa
	cps	hl, 0
	jr	nz, 63
	ld	c, (xsp+4)
	extz	bc
	lda	xde, (xsp+12)
	lda	xwa, (xsp+10)
	push	xwa
	lds	wa, 1
	call	TmFlash_WriteRoutine
	ld	xix, (xsp+12)
	sub	xix, 0x346800
	cps	hl, 0
	jr	nz, 32
	lds	hl, 0
	.byte 0x9f
	ldio	63, 0
	nop
	jr	ule, 23
	lds32	xbc, 0
	ld	xde, xbc
	add	xde, xix
	ld	xwa, xbc
	add	xwa, xiz
	ld	a, (xwa)
	ld	(xde), a
	inc	1, hl
	inc	1, xbc
	.byte 0x9f
	ldio	243, 103
	ld	xsp, xhl
	.byte 0x06
	jr	lt, -113
	.byte 0x06
	push	xsp
	ldw	de, 0x6877
	swi	7
	ldda32	xbc, 3222
	ldda32	xde, 3218
	lds	wa, 1
	call	Flash_EraseSectorAndWrite
	pop	xiz
	lda	xsp, (xsp+12)
	ret
	lda	xsp, (xsp-12)
	push	xiz
	ldada	xwa, 1952
	.byte 0x90
	push	xsp
	swi	7
	swi	7
	jr	z, 99
	ld	hl, (xwa)
	ldb	h, 0
	ld	wa, (xwa+2)
	ldb	w, 0
	ld	(xsp+4), a
	ld	c, l
	extz	bc
	lda	xde, (xsp+12)
	lda	xwa, (xsp+10)
	push	xwa
	lds	wa, 3
	call	TmFlash_WriteRoutine
	ld	xiz, (xsp+12)
	ld	wa, (xsp+10)
	ld	(xsp+8), wa
	cps	hl, 0
	jr	nz, 57
	ld	c, (xsp+4)
	extz	bc
	lda	xde, (xsp+12)
	lda	xwa, (xsp+10)
	push	xwa
	lds	wa, 2
	call	TmFlash_WriteRoutine
	ld	xix, (xsp+12)
	cps	hl, 0
	jr	nz, 32
	lds	hl, 0
	.byte 0x9f
	ldio	63, 0
	nop
	jr	ule, 23
	lds32	xbc, 0
	ld	xde, xbc
	add	xde, xix
	ld	xwa, xbc
	add	xwa, xiz
	ld	a, (xwa)
	ld	(xde), a
	inc	1, hl
	inc	1, xbc
	.byte 0x9f
	ldio	243, 103
	.byte 0xeb
	ld	(xsp+6), 0
	ld	c, (xsp+6)
	extz	bc
	sla	bc, 2
	ld	wa, bc
	inc	4, wa
	ldada	xde, 1952
	.byte 0xd3
	reti
	or	xwa, xwa
	ldb	w, 216
	.byte 0xcf
	swi	7
	swi	7
	jr	z, 119
	ldb	w, 0
	ld	l, a
	inc	6, bc
	.byte 0xd3
	reti
	or	xix, xwa
	ldb	w, 32
	nop
	ld	(xsp+4), a
	res	7, l
	.byte 0xbf, 0x04, 0xb7
	ld	c, l
	extz	bc
	lda	xde, (xsp+12)
	lda	xwa, (xsp+10)
	push	xwa
	lds	wa, 1
	call	TmFlash_WriteRoutine
	ld	xiz, (xsp+12)
	ld	wa, (xsp+10)
	ld	(xsp+8), wa
	cps	hl, 0
	jr	nz, 57
	ld	c, (xsp+4)
	extz	bc
	lda	xde, (xsp+12)
	lda	xwa, (xsp+10)
	push	xwa
	lds	wa, 0
	call	TmFlash_WriteRoutine
	ld	xix, (xsp+12)
	cps	hl, 0
	jr	nz, 32
	lds	hl, 0
	.byte 0x9f
	ldio	63, 0
	nop
	jr	ule, 23
	lds32	xbc, 0
	ld	xde, xbc
	add	xde, xix
	ld	xwa, xbc
	add	xwa, xiz
	ld	a, (xwa)
	ld	(xde), a
	inc	1, hl
	inc	1, xbc
	.byte 0x9f
	ldio	243, 103
	ld	xsp, xhl
	.byte 0x06
	jr	lt, -113
	.byte 0x06
	.ascii "?2wnÿ^¿"
	incf
	.byte 0x37
	ret
	dec	8, xsp
	push	xiz
	ld	(xsp+10), c
	ld	iz, wa
	calr	1940
	calr	1977
	calr	2169
	ld	wa, iz
	and	wa, 0xff00
	jr	z, 73
	ldb	d, 0
	ldb	b, 0
	ldb	c, 0
	ldda32	xhl, 3218
	lds	ix, 0
	ld	wa, ix
	add	wa, 80
	.byte 0xc3
	reti
	or	xwa, xix
	ldb	w, 202
	.byte 0xf0
	jr	ule, 4
	ld	b, w
	ld	d, c
	inc	1, c
	inc	1, ix
	cps	c, 4
	jr	c, -27
	ldada	xhl, 1952
	ldda16	wa, 1748
	ld	(xhl), wa
	ld	a, d
	extz	wa
	or	wa, 1280
	ld	(xhl+2), wa
	ldada	xde, 2156
	ld	(xde), wa
	ld	c, b
	extz	bc
	ld	(xde+2), bc
	ld	wa, iz
	and	wa, 255
	jrl	z, 318
	ldb	e, 0
	ldb	c, 0
	ld	(xsp+6), 0
	ld	(xsp+8), 0
	ld	(xsp+4), 0
	ld	a, (xsp+4)
	extz	wa
	add	wa, wa
	inc	2, wa
	ldada	xhl, 1748
	.byte 0xf3
	reti
	or	xwa, xix
	ldw	hl, 0x3f93
	swi	7
	swi	7
	jrl	z, 277
	.byte 0x8f
	ldio	63, 0
	jr	nz, 100
	cp	c, 40
	jr	nc, 82
	ld	a, c
	extz	wa
	ld	ix, wa
	add	ix, 16
	ldda32	xwa, 3218
	.byte 0xc3
	reti
	.byte 0xe0, 0xf0
	ldb	w, 200
	inc	6, wa
	halt
	.byte 0x8f
	ldwio	240, 0x2f6e
	.byte 0xc7, 0xf0, 0x9d
	extz	ix
	sla	ix, 2
	ld	iz, ix
	inc	4, iz
	ldada	xiy, 1952
	ld	wa, (xhl)
	.byte 0xf3
	reti
	.byte 0xf4
	swi	0
	.byte 0x50
	inc	6, ix
	ld	a, c
	set	7, a
	extz	wa
	or	wa, 1280
	.byte 0xf3
	reti
	.byte 0xf4, 0xf0, 0x50
	inc	1, e
	inc	1, c
	jr	7
	inc	1, c
	cp	c, 40
	jr	c, -82
	cp	c, 40
	jrl	nz, 168
	ld	(xsp+8), 1
	jrl	161
	ldb	d, 0
	ldb	b, 0
	ldb	c, 0
	ld	a, c
	extz	wa
	ld	iy, wa
	add	iy, iy
	inc	2, iy
	ldada	xix, 2972
	.byte 0xd3
	reti
	.byte 0xf0, 0xf4
	push	xsp
	.byte 0x01
	nop
	jr	z, 28
	ld	iy, wa
	add	iy, 16
	ldda32	xwa, 3218
	.byte 0xc3
	reti
	.byte 0xe0, 0xf4
	ldb	w, 202
	.byte 0xf0
	jr	ule, 9
	.byte 0x8f
	ldwio	240, 1126
	ld	b, w
	ld	d, c
	inc	1, c
	.byte 0xc7, 0xf4, 0x9d
	extz	iy
	cp	c, 40
	jr	c, -63
	sla	iy, 2
	.byte 0xd7, 0xe2, 0x9d, 0xd7, 0xe2
	jr	ov, -15
	.byte 0xa0
	reti
	ldw	iz, 8339
	.byte 0xf3
	reti
	swi	0
	.byte 0xe2, 0x50
	inc	6, iy
	ld	l, d
	set	7, l
	extz	hl
	or	hl, 1280
	.byte 0xf3
	reti
	swi	0
	.byte 0xf4, 0x53
	ld	a, (xsp+6)
	extz	wa
	sla	wa, 2
	ld	iz, wa
	inc	4, iz
	ldada	xiy, 2156
	.byte 0xf3
	reti
	.byte 0xf4
	swi	0
	.byte 0x53
	ld	hl, wa
	inc	6, hl
	ld	a, b
	extz	wa
	.byte 0xf3
	reti
	.byte 0xf4, 0xec, 0x50
	ld	a, d
	extz	wa
	add	wa, wa
	inc	2, wa
	.byte 0xf3
	reti
	.byte 0xf0, 0xe0
	push_sr
	.byte 0x01
	nop
	incm8	1, (xsp+6)
	inc	1, e
	incm8	1, (xsp+4)
	.byte 0x8f, 0x04
	push	xsp
	ldw	de, 0xd277
	swi	6
	pop	xiz
	inc	8, xsp
	ret
	push	xiz
	ldada	xbc, 0x3a4f
	ld	xwa, xbc
	lda	xbc, (xbc+29)
	.byte 0xf5, 0xe0
	nop
	ldb	w, 233
	.byte 0xf0
	jr	c, -8
	.byte 0xc7
	swi	3
	.byte 0xa8
	ldada	xwa, 2156
	.byte 0x90
	push	xsp
	swi	7
	swi	7
	jr	z, 63
	ld	wa, (xwa)
	ldb	w, 0
	.byte 0xc7
	swi	1
	.byte 0x99
	extz	wa
	calr	256
	.byte 0xc7
	swi	0
	cp	(xsp-57), bc
	.byte 0x89
	extz	wa
	calr	298
	ldada	xbc, 0x3a4f
	ld	(xbc), 35
	ld	(xbc+1), l
	.byte 0xc7
	swi	0
	.byte 0x89
	ld	(xbc+2), a
	ld	(xbc+3), 40
	ld	(xbc+4), 68
	ld	(xbc+5), 114
	ld	(xbc+6), 109
	ld	(xbc+7), 41
	.byte 0xc7
	swi	3
	pop_sr
	push	199
	swi	2
	cp	(xwa-57), xde
	.byte 0x89
	extz	wa
	sla	wa, 2
	ld	de, wa
	inc	4, de
	ldada	xbc, 2156
	.byte 0xd3
	reti
	.byte 0xe4, 0xe8
	push	xsp
	swi	7
	swi	7
	jrl	z, 174
	inc	6, wa
	.byte 0xd3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 199
	swi	1
	sub	(xbc-39), wa
	.byte 0xc7
	swi	2
	inc	6, wa
	push	199
	swi	1
	.byte 0x89
	cp	a, l
	jr	z, 2
	lds	bc, 1
	.byte 0xc7
	swi	2
	cps	wa, 0
	jrl	z, -7975
	jr	z, 126
	.byte 0xc7
	swi	1
	and	(xbc-55), b
	ldwio	216, 7698
	.byte 0x82
	nop
	.byte 0xc7
	swi	0
	cp	(xsp-57), bc
	and	(xbc-55), b
	ldwio	216, 7698
	.byte 0xa9
	nop
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	ldada	xbc, 0x3a4f
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 35
	.byte 0xc7
	swi	3
	incm8	1, (xbc-55)
	extz	wa
	extz	xwa
	add	xwa, xbc
	ld	(xwa), l
	.byte 0xc7
	swi	3
	incm8	2, (xbc-55)
	extz	wa
	ld	de, wa
	extz	xde
	add	xde, xbc
	.byte 0xc7
	swi	0
	.byte 0x89
	ld	(xde), a
	.byte 0xc7
	swi	3
	jr	ov, -57
	swi	3
	.byte 0xcf, 0x1a
	jr	ule, 45
	.byte 0xc7
	swi	3
	jr	nov, -57
	swi	3
	.byte 0x89
	extz	wa
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 46
	.byte 0xc7
	swi	3
	incm8	1, (xbc-55)
	extz	wa
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 46
	.byte 0xc7
	swi	3
	incm8	2, (xbc-55)
	extz	wa
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 46
	jr	13
	.byte 0xc7
	swi	1
	cp	(xsp-57), b
	jr	lt, -57
	swi	2
	.byte 0xcf
	ldw	de, 0x3877
	swi	7
	pop	xiz
	ret
	cp	a, 10
	jr	nc, 7
	add	a, 48
	ld	l, a
	jr	40
	cp	a, 20
	jr	nc, 7
	add	a, 38
	ld	l, a
	jr	28
	cp	a, 30
	jr	nc, 7
	add	a, 28
	ld	l, a
	jr	16
	cp	a, 40
	jr	nc, 7
	add	a, 18
	ld	l, a
	jr	4
	inc	8, a
	ld	l, a
	ret
	cp	a, 10
	jr	nc, 4
	ldb	l, 48
	jr	27
	cp	a, 20
	jr	nc, 4
	ldb	l, 49
	jr	18
	cp	a, 30
	jr	nc, 4
	ldb	l, 50
	jr	9
	ldb	l, 52
	cp	a, 40
	ret	nc
	ldb	l, 51
	ret
	push	xiz
	ldada	xde, 0x3a4f
	ld	xwa, xde
	lda	xbc, (xde+29)
	.byte 0xf5, 0xe0
	nop
	ldb	w, 233
	.byte 0xf0
	jr	c, -8
	.byte 0xc7
	swi	0
	.byte 0xa8, 0xd1, 0xa2
	reti
	push	xsp
	swi	7
	swi	7
	jr	z, 35
	ld	(xde), 85
	ld	(xde+1), 115
	ld	(xde+2), 101
	ld	(xde+3), 114
	ld	(xde+4), 68
	ld	(xde+5), 114
	ld	(xde+6), 117
	ld	(xde+7), 109
	.byte 0xc7
	swi	0
	pop_sr
	push	199
	swi	1
	cp	(xwa-57), xbc
	.byte 0x89
	extz	wa
	sla	wa, 2
	ldada	xbc, 1958
	.byte 0xd3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 216
	.byte 0xcf
	swi	7
	swi	7
	jrl	z, 164
	res	7, a
	.byte 0xc7
	swi	2
	sub	(xbc-39), wa
	.byte 0xc7
	swi	1
	inc	6, wa
	push	199
	swi	2
	.byte 0x89
	cp	a, e
	jr	z, 2
	lds	bc, 1
	.byte 0xc7
	swi	1
	cps	wa, 0
	jrl	z, -7975
	jr	z, 120
	.byte 0xc7
	swi	2
	.byte 0x89
	extz	wa
	calr	65316
	.byte 0xc7
	swi	3
	cp	(xsp-57), de
	.byte 0x89
	extz	wa
	calr	65358
	.byte 0xc7
	swi	0
	.byte 0x89
	extz	wa
	ldada	xbc, 0x3a4f
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 35
	.byte 0xc7
	swi	0
	incm8	1, (xbc-55)
	extz	wa
	extz	xwa
	add	xwa, xbc
	ld	(xwa), l
	.byte 0xc7
	swi	0
	incm8	2, (xbc-55)
	extz	wa
	ld	de, wa
	extz	xde
	add	xde, xbc
	.byte 0xc7
	swi	3
	.byte 0x89
	ld	(xde), a
	.byte 0xc7
	swi	0
	jr	ov, -57
	swi	0
	.byte 0xcf, 0x1a
	jr	ule, 45
	.byte 0xc7
	swi	0
	jr	nov, -57
	swi	0
	.byte 0x89
	extz	wa
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 46
	.byte 0xc7
	swi	0
	incm8	1, (xbc-55)
	extz	wa
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 46
	.byte 0xc7
	swi	0
	incm8	2, (xbc-55)
	extz	wa
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 46
	jr	13
	.byte 0xc7
	swi	2
	cp	(xiy-57), a
	jr	lt, -57
	swi	1
	.byte 0xcf
	ldw	de, 0x4477
	swi	7
	pop	xiz
	ret
	calr	953
	ldada	xhl, 2156
	.byte 0x93
	push	xsp
	swi	7
	swi	7
	jr	z, 19
	ldada	xbc, 2360
	ld	wa, (xhl+2)
	ld	(xbc), wa
	ld	wa, (xhl)
	ld	(xbc+2), wa
	.byte 0xb9, 0x04
	push_sr
	nop
	nop
	.byte 0xc7
	lds32	xde, 0
	.byte 0xc7
	addm32_24	0xe2c7a8, xiy
	extz	de
	sla	de, 2
	ld	wa, de
	inc	4, wa
	.byte 0xf3
	reti
	or	xwa, xix
	ldw	bc, 0x3f91
	swi	7
	swi	7
	ret	z
	.byte 0xc7
	ld	xbc, xde
	extz	wa
	add	wa, wa
	ld	iy, wa
	inc	6, iy
	ldada	xix, 2360
	inc	6, de
	.byte 0xd3
	reti
	.byte 0xec, 0xe8
	ldb	w, 243
	reti
	.byte 0xf0, 0xf4, 0x50
	ld	de, (xbc)
	.byte 0xc7
	ld	xbc, xde
	extz	wa
	sla	wa, 2
	ld	bc, wa
	add	bc, 106
	.byte 0xf3
	reti
	.byte 0xf0, 0xe4, 0x52
	add	wa, 108
	.byte 0xf3
	reti
	.byte 0xf0, 0xe0
	push_sr
	nop
	nop
	.byte 0xc7
	inc	1, xde
	.byte 0xc7, 0xe2
	jr	lt, -57
	sub32_24	xde, 0x6732cf
	ret
	calr	881
	ldada	xbc, 1748
	.byte 0x91
	push	xsp
	swi	7
	swi	7
	jr	z, 14
	ldada	xde, 2666
	ld	wa, (xbc)
	ld	(xde+2), wa
	.byte 0xba, 0x04
	push_sr
	nop
	nop
	ldb	h, 0
	ldb	l, 0
	ld	a, l
	extz	wa
	add	wa, wa
	inc	2, wa
	exts	xwa
	add	xwa, xbc
	.byte 0x90
	push	xsp
	swi	7
	swi	7
	ret	z
	ld	iy, (xwa)
	ld	a, h
	extz	wa
	sla	wa, 2
	ld	ix, wa
	add	ix, 106
	ldada	xde, 2666
	.byte 0xf3
	reti
	cp	xwa, xwa
	.byte 0x55
	add	wa, 108
	.byte 0xf3
	reti
	or	xwa, xwa
	push_sr
	nop
	nop
	inc	1, h
	inc	1, l
	cp	l, 50
	jr	c, -62
	ret
	ldda32	xix, 3222
	ldda32	xiy, 3218
	ldw	bc, 0x8000
	.byte 0x95
	scf
	ldda32	xix, 3222
	ld	xiy, MSP_Default_Sequencer
	ldw	bc, 8
	.byte 0x95
	scf
	ldda32	xwa, 3222
	ld	xiy, MSP_Default_SeqReserved
	lda	xix, (xwa+16)
	ldw	bc, 32
	.byte 0x95
	scf
	ldda32	xwa, 3222
	ld	xiy, MSP_Default_SeqReserved_0x40
	lda	xix, (xwa+80)
	ldw	bc, 8
	.byte 0x95
	scf
	ldda32	xbc, 3222
	ldda32	xde, 3218
	lds	wa, 1
	jp	Flash_EraseSectorAndWrite
	ldb	l, 0
	ldda32	xde, 3218
	ldb	b, 0
	cps	a, 0
	jr	nz, 34
	lds	wa, 0
	ld	ix, wa
	add	ix, 16
	.byte 0xc3
	reti
	cp	xwa, xwa
	ldb	h, 206
	inc	6, wa
	.byte 0x04
	cp	h, c
	jr	nz, 2
	inc	1, l
	inc	1, b
	inc	1, wa
	cp	b, 40
	jr	c, -30
	jr	31
	lds	wa, 0
	ld	ix, wa
	add	ix, 80
	.byte 0xc3
	reti
	cp	xwa, xwa
	ldb	h, 206
	inc	6, wa
	.byte 0x04
	cp	h, c
	jr	nz, 2
	inc	1, l
	inc	1, b
	inc	1, wa
	cps	b, 4
	jr	c, -29
	ret

VoiceParam_ComputeOffset:
	ld e, a
	cp e, 0x28
	jr nc, VoiceParam_SubtractBase
	ld xhl, 0x10
	jr VoiceParam_AddOffset

VoiceParam_SubtractBase:
	sub e, 0x28
	ld xhl, 0x50

VoiceParam_AddOffset:
	extz de
	add hl, de
	ldda32 xwa, 3222
	lda_dri3 XHL, 0x07, 0xe0, 0xec
	ret

DualVoice_ScanAllColumns:
	dec 2, xsp
	push_werp 0xfa
	ld (xsp + 2), a
	calr SlotTable_InitBank1748
	ldi_berp 0xfb, 0

DualVoice_ScanColumnLoop:
	ld a, (xsp + 2)
	extz wa
	ldto_berp C, 0xfb
	extz bc
	lds de, 0
	calr Util_FrameSetup10
	ld wa, hl
	ld bc, wa
	and bc, 0x700
	cp bc, 0x600
	jr z, DualVoice_StoreBankMatch
	cp bc, 0x500
	jr nz, DualVoice_ScanRow1

DualVoice_StoreBankMatch:
	stda16 1748, xwa

DualVoice_ScanRow1:
	ld a, (xsp + 2)
	extz wa
	ldto_berp C, 0xfb
	extz bc
	lds de, 1
	calr Util_FrameSetup10
	ld wa, hl
	ld bc, wa
	and bc, 0xff
	cp bc, 0x80
	call_24 nc, SlotTable_Insert1748
	ld a, (xsp + 2)
	extz wa
	ldto_berp C, 0xfb
	extz bc
	lds de, 2
	calr Util_FrameSetup10
	ld wa, hl
	ld bc, wa
	and bc, 0xff
	cp bc, 0x80
	call_24 nc, SlotTable_Insert1748
	ld a, (xsp + 2)
	extz wa
	ldto_berp C, 0xfb
	extz bc
	lds de, 3
	calr Util_FrameSetup10
	ld wa, hl
	ld bc, wa
	and bc, 0xff
	cp bc, 0x80
	call_24 nc, SlotTable_Insert1748
	ld a, (xsp + 2)
	extz wa
	ldto_berp C, 0xfb
	extz bc
	lds de, 4
	calr Util_FrameSetup10
	ld wa, hl
	ld bc, wa
	and bc, 0xff
	cp bc, 0x80
	call_24 nc, SlotTable_Insert1748
	inc1_berp 0xfb
	cp_erpb 0xfb, 0x0a
	jrl c, DualVoice_ScanColumnLoop
	pop_werp 0xfa
	inc 2, xsp
	ret

DualVoice_ScanAllColumnsAlt:
	dec 2, xsp
	push_werp 0xfa
	ld (xsp + 2), a
	calr SlotTable_InitBank1850
	ldi_berp 0xfb, 0

DualVoice_ScanColumnLoopAlt:
	ld a, (xsp + 2)
	extz wa
	ldto_berp C, 0xfb
	extz bc
	lds de, 0
	calr Util_FrameSetup10
	ld wa, hl
	ld bc, wa
	and bc, 0x700
	cp bc, 0x600
	jr z, DualVoice_StoreBankMatchAlt
	cp bc, 0x500
	jr nz, DualVoice_ScanRow1Alt

DualVoice_StoreBankMatchAlt:
	stda16 1850, xwa

DualVoice_ScanRow1Alt:
	ld a, (xsp + 2)
	extz wa
	ldto_berp C, 0xfb
	extz bc
	lds de, 1
	calr Util_FrameSetup10
	ld wa, hl
	ld bc, wa
	and bc, 0xff
	cp bc, 0x80
	call_24 nc, SlotTable_Insert1850
	ld a, (xsp + 2)
	extz wa
	ldto_berp C, 0xfb
	extz bc
	lds de, 2
	calr Util_FrameSetup10
	ld wa, hl
	ld bc, wa
	and bc, 0xff
	cp bc, 0x80
	call_24 nc, SlotTable_Insert1850
	ld a, (xsp + 2)
	extz wa
	ldto_berp C, 0xfb
	extz bc
	lds de, 3
	calr Util_FrameSetup10
	ld wa, hl
	ld bc, wa
	and bc, 0xff
	cp bc, 0x80
	call_24 nc, SlotTable_Insert1850
	ld a, (xsp + 2)
	extz wa
	ldto_berp C, 0xfb
	extz bc
	lds de, 4
	calr Util_FrameSetup10
	ld wa, hl
	ld bc, wa
	and bc, 0xff
	cp bc, 0x80
	call_24 nc, SlotTable_Insert1850
	inc1_berp 0xfb
	cp_erpb 0xfb, 0x0a
	jrl c, DualVoice_ScanColumnLoopAlt
	pop_werp 0xfa
	inc 2, xsp
	ret

SlotTable_InitBank1748:
	ldada xbc, 1748
	ldw (xbc), 0xffff
	ldb l, 0x0
	lds wa, 0

SlotTable_InitBank1748_Loop:
	ld de, wa
	inc 2, de
	stiw_dri 0x07, 0xe4, 0xe8, 0xff, 0xff
	inc 1, l
	inc 2, wa
	cp l, 0x32
	jr c, SlotTable_InitBank1748_Loop
	ret

SlotTable_InitBank1850:
	ldada xbc, 1850
	ldw (xbc), 0xffff
	ldb l, 0x0
	lds wa, 0

SlotTable_InitBank1850_Loop:
	ld de, wa
	inc 2, de
	stiw_dri 0x07, 0xe4, 0xe8, 0xff, 0xff
	inc 1, l
	inc 2, wa
	cp l, 0x32
	jr c, SlotTable_InitBank1850_Loop
	ret

SlotTable_ExtendedOpsBlock:
	ldada	xde, 1952
	.byte 0xb2
	push_sr
	swi	7
	swi	7
	.byte 0xba
	push_sr
	push_sr
	swi	7
	swi	7
	lda	xbc, (xde+6)
	ld	xwa, xbc
	inc	4, xde
	.byte 0xf3, 0xe5, 0xc8
	nop
	ldw	bc, 0xeaf5
	push_sr
	swi	7
	swi	7
	.byte 0xf5, 0xe2
	push_sr
	swi	7
	swi	7
	cp	xwa, xbc
	jr	c, -14
	ret
	ldada	xde, 2156
	.byte 0xb2
	push_sr
	swi	7
	swi	7
	.byte 0xba
	push_sr
	push_sr
	swi	7
	swi	7
	lda	xbc, (xde+6)
	ld	xwa, xbc
	inc	4, xde
	.byte 0xf3, 0xe5, 0xc8
	nop
	ldw	bc, 0xeaf5
	push_sr
	swi	7
	swi	7
	.byte 0xf5, 0xe2
	push_sr
	swi	7
	swi	7
	cp	xwa, xbc
	jr	c, -14
	ret
	ldada	xix, 2360
	.byte 0xb4
	push_sr
	swi	7
	swi	7
	.byte 0xbc
	push_sr
	push_sr
	swi	7
	swi	7
	.byte 0xbc, 0x04
	push_sr
	swi	7
	swi	7
	lda	xbc, (xix+108)
	ld	xwa, xbc
	lda	xde, (xix+106)
	lds	hl, 0
	.byte 0xf3, 0xe5, 0xc8
	nop
	ldw	bc, 0x8ddb
	inc	6, iy
	.byte 0xf3
	reti
	.byte 0xf0, 0xf4
	push_sr
	swi	7
	swi	7
	.byte 0xf5, 0xea
	push_sr
	swi	7
	swi	7
	.byte 0xf5, 0xe2
	push_sr
	swi	7
	swi	7
	inc	2, hl
	cp	xwa, xbc
	jr	c, -27
	ret
	ldada	xix, 2666
	.byte 0xb4
	push_sr
	swi	7
	swi	7
	.byte 0xbc
	push_sr
	push_sr
	swi	7
	swi	7
	.byte 0xbc, 0x04
	push_sr
	swi	7
	swi	7
	lda	xbc, (xix+108)
	ld	xwa, xbc
	lda	xde, (xix+106)
	lds	hl, 0
	lda	xbc, (xbc+200)
	ld	iy, hl
	inc	6, iy
	.byte 0xf3
	reti
	.byte 0xf0, 0xf4
	push_sr
	swi	7
	swi	7
	.byte 0xf5, 0xea
	push_sr
	swi	7
	swi	7
	.byte 0xf5, 0xe2
	push_sr
	swi	7
	swi	7
	inc	2, hl
	cp	xwa, xbc
	jr	c, -27
	ret
	ldada	xbc, 3074
	.byte 0xb1
	push_sr
	swi	7
	swi	7
	ldb	l, 0
	lds	wa, 0
	ld	de, wa
	inc	2, de
	.byte 0xf3
	reti
	.byte 0xe4, 0xe8
	push_sr
	swi	7
	swi	7
	inc	1, l
	inc	2, wa
	cp	l, 50
	jr	c, -20
	ret
	ldada	xbc, 2972
	.byte 0xb1
	push_sr
	swi	7
	swi	7
	ldb	l, 0
	lds	wa, 0
	ld	de, wa
	inc	2, de
	.byte 0xf3
	reti
	.byte 0xe4, 0xe8
	push_sr
	swi	7
	swi	7
	inc	1, l
	inc	2, wa
	cp	l, 50
	jr	c, -20
	ret

SlotTable_Insert1748:
	ldi_berp 0xe2, 0
	ldada xhl, 1748

SlotTable_Insert1748_Loop:
	ldto_berp C, 0xe2
	extz bc
	add bc, bc
	inc 2, bc
	st_dri3b B, 0x07, 0xec, 0xe4
	ld bc, (xde)
	cp bc, wa
	ret z
	cp bc, 0xffff
	jr nz, SlotTable_Insert1748_Next
	ld (xde), wa
	ret

SlotTable_Insert1748_Next:
	inc1_berp 0xe2
	cp_erpb 0xe2, 0x32
	jr c, SlotTable_Insert1748_Loop
	ret

SlotTable_Insert1850:
	ldi_berp 0xe2, 0
	ldada xhl, 1850

SlotTable_Insert1850_Loop:
	ldto_berp C, 0xe2
	extz bc
	add bc, bc
	inc 2, bc
	st_dri3b B, 0x07, 0xec, 0xe4
	ld bc, (xde)
	cp bc, wa
	ret z
	cp bc, 0xffff
	jr nz, SlotTable_Insert1850_Next
	ld (xde), wa
	ret

SlotTable_Insert1850_Next:
	inc1_berp 0xe2
	cp_erpb 0xe2, 0x32
	jr c, SlotTable_Insert1850_Loop
	ret

Flash_WriteBackSlotTable:
	push_werp 0xfa
	ldda32 xix, 3222
	ldda32 xiy, 3218
	ldw bc, 0x8000
	ldirw
	ldada xwa, 1850
	cpw (xwa), 0xffff
	jr z, Flash_WriteBackSlot_StartLoop
	ld wa, (xwa)
	ldb w, 0x0
	add a, 0x28
	extz wa
	lds bc, 0
	calr VoiceParam_ComputeOffset

Flash_WriteBackSlot_StartLoop:
	ldi_berp 0xfb, 0

Flash_WriteBackSlot_Loop:
	ldto_berp A, 0xfb
	extz wa
	add wa, wa
	inc 2, wa
	ldada xbc, 1850
	ld_sriw3 WA, 0x07, 0xe4, 0xe0
	cp wa, 0xffff
	jr z, Flash_WriteBackSlot_Erase
	and wa, 0x7f
	extz wa
	lds bc, 0
	calr VoiceParam_ComputeOffset
	inc1_berp 0xfb
	cp_erpb 0xfb, 0x32
	jr c, Flash_WriteBackSlot_Loop

Flash_WriteBackSlot_Erase:
	ldda32 xbc, 3222
	ldda32 xde, 3218
	lds wa, 1
	call Flash_EraseSectorAndWrite
	pop_werp 0xfa
	ret

Flash_SlotUpdateOpsBlock:
	dec	6, xsp
	ld	(xsp+4), a
	ldw	(xsp), 0
	ldw	(xsp+2), 0
	.byte 0xd1, 0xd4, 0x06
	push	xsp
	swi	7
	swi	7
	jr	z, 18
	ld	c, (xsp+4)
	extz	bc
	lds	wa, 1
	calr	64465
	cps	l, 0
	jr	nz, 4
	.byte 0xb7
	push_sr
	.byte 0x01
	nop
	.byte 0xd1, 0xd6, 0x06
	push	xsp
	swi	7
	swi	7
	jr	z, 51
	ld	c, (xsp+4)
	extz	bc
	lds	wa, 0
	calr	64439
	ldb	e, 0
	ldada	xbc, 1748
	ld	a, e
	extz	wa
	add	wa, wa
	inc	2, wa
	.byte 0xd3
	reti
	.byte 0xe4, 0xe0
	push	xsp
	swi	7
	swi	7
	jr	z, 7
	inc	1, e
	cp	e, 50
	jr	c, -24
	cp	l, e
	jr	nc, 7
	sub	l, e
	extz	hl
	ld	(xsp+2), hl
	ld	hl, (xsp)
	sll	hl, 8
	.byte 0x9f
	push_sr
	or	(xhl), l
	jr	z, 14
	dec	4, xsp
	ld	(xsp+2), a
	calr	65155
	ldb	a, 30
	ld	(xsp), 31
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	nz, 2
	ldb	a, 32
	.byte 0x8f
	push_sr
	push	xsp
	.byte 0x01
	jr	nz, 3
	ld	(xsp), 32
	extz	wa
	calr	10
	ld	a, (xsp)
	extz	wa
	calr	3
	inc	4, xsp
	ret
	dec	2, xsp
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+2), a
	.byte 0xc7
	swi	3
	.byte 0xa8
	ld	a, (xsp+2)
	extz	wa
	.byte 0xc7
	swi	3
	.byte 0x8b
	extz	bc
	lds	de, 0
	calr	59954
	.byte 0xc7
	swi	2
	.byte 0xa9
	ld	a, (xsp+2)
	extz	wa
	.byte 0xc7
	swi	3
	.byte 0x8b
	extz	bc
	.byte 0xc7
	swi	2
	.byte 0x8d
	extz	de
	calr	59933
	ldb	h, 0
	ld	a, l
	res	7, a
	cp	l, 128
	jr	c, 17
	extz	wa
	add	wa, wa
	inc	2, wa
	ldada	xbc, 3074
	.byte 0xf3
	reti
	.byte 0xe4, 0xe0
	push_sr
	.byte 0x01
	nop
	.byte 0xc7
	swi	2
	jr	lt, -57
	swi	2
	inc	3, ix
	and	l, a
	swi	3
	jr	lt, -57
	swi	3
	div	l, 103
	cp	(xiz-41), xde
	halt
	inc	2, xsp
	ret
	dec	8, xsp
	ld	(xsp+6), c
	extz	de
	ld	wa, de
	calr	61637
	calr	60972
	ld	a, (xsp+6)
	extz	wa
	calr	60568
	ld	(xsp+4), l
	ld	a, (xsp+4)
	extz	wa
	calr	60662
	ld	a, (xsp+6)
	extz	wa
	calr	62001
	calr	62246
	call	TmFlash_CopyToExtMem
	ldada	xwa, 2360
	.byte 0x98
	push_sr
	push	xsp
	swi	7
	swi	7
	jr	z, 67
	ld	wa, (xwa)
	ld	(xsp), a
	extz	wa
	calr	60522
	ld	(xsp+4), l
	ld	a, (xsp+4)
	extz	wa
	calr	60524
	calr	64734
	ldada	xbc, 1952
	ldda16	wa, 2362
	ld	(xbc), wa
	.byte 0xb9
	push_sr
	push_sr
	nop
	nop
	ld	a, (xsp)
	extz	wa
	lda_24	xbc, MSP_Default_GroupIndexPad
	.byte 0xc3
	reti
	.byte 0xe4, 0xe0
	ldb	e, 218
	ccf
	ld	wa, de
	calr	61530
	ld	a, (xsp+4)
	extz	wa
	calr	60569
	.byte 0xd1, 0xa2
	push	63
	swi	7
	swi	7
	jrl	z, 128
	ld	(xsp+2), 0
	ld	a, (xsp+2)
	extz	wa
	ld	de, wa
	sla	de, 2
	add	de, 106
	ldada	xbc, 2360
	.byte 0xd3
	reti
	.byte 0xe4, 0xe8
	push	xsp
	swi	7
	swi	7
	jr	z, 97
	add	wa, wa
	inc	6, wa
	.byte 0xd3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 183
	ld	xbc, 0xf81e12d8
	.byte 0xeb
	ld	(xsp+4), l
	ld	a, (xsp+4)
	extz	wa
	calr	60410
	calr	64620
	ldada	xbc, 1952
	ld	e, (xsp+2)
	extz	de
	sla	de, 2
	ldada	xwa, 2466
	.byte 0xd3
	reti
	.byte 0xe0, 0xe8
	ldb	w, 185
	.byte 0x04, 0x50, 0xb9
	ei	2
	nop
	nop
	ld	a, (xsp)
	extz	wa
	lda_24	xbc, MSP_Default_GroupIndexPad
	.byte 0xc3
	reti
	.byte 0xe4, 0xe0
	ldb	e, 218
	ccf
	ld	wa, de
	calr	61402
	ld	a, (xsp+4)
	extz	wa
	calr	60441
	incm8	1, (xsp+2)
	.byte 0x8f
	push_sr
	push	xsp
	ldw	de, 0x8467
	inc	8, xsp
	ret
	dec	4, xsp
	ld	(xsp), e
	ld	(xsp+2), c
	calr	64540
	ldada	xhl, 2666
	ld	wa, (xhl+2)
	cp	wa, 0xffff
	jr	z, 12
	ldada	xbc, 1952
	ld	(xbc), wa
	ld	wa, (xhl+4)
	ld	(xbc+2), wa
	.byte 0xc7
	addm32_24	0xe2c7a8, xhl
	extz	bc
	sla	bc, 2
	ld	wa, bc
	add	wa, 106
	.byte 0xd3
	reti
	or	xwa, xix
	ldb	w, 216
	.byte 0xcf
	swi	7
	swi	7
	jr	z, 40
	ld	ix, bc
	inc	4, ix
	ldada	xde, 1952
	.byte 0xf3
	reti
	cp	xwa, xwa
	.byte 0x50
	ld	ix, bc
	inc	6, ix
	add	bc, 108
	.byte 0xd3
	reti
	or	xix, xix
	ldb	w, 243
	reti
	cp	xwa, xwa
	.byte 0x50, 0xc7, 0xe2
	jr	lt, -57
	.byte 0xe2, 0xcf
	ldw	de, 0xbf67
	ld	a, (xsp)
	extz	wa
	calr	61272
	calr	60607
	ld	a, (xsp+2)
	extz	wa
	calr	60203
	extz	hl
	ld	wa, hl
	calr	60301
	ldada	xwa, 1850
	.byte 0x90
	push	xsp
	swi	7
	swi	7
	jr	nz, 7
	.byte 0x98
	push_sr
	push	xsp
	swi	7
	swi	7
	jr	z, 3
	calr	64762
	inc	4, xsp
	ret
	extz	de
	ld	wa, de
	calr	61224
	ldda32	xix, 3182
	ldda32	xiy, 3186
	ldw	bc, 0xb400
	.byte 0x95
	scf
	calr	62157
	jp	TmFlash_BulkTransferToSubCPU
	dec	2, xsp
	ld	(xsp), e
	calr	64365
	ldada	xhl, 2666
	ld	wa, (xhl+2)
	cp	wa, 0xffff
	jr	z, 12
	ldada	xbc, 1952
	ld	(xbc), wa
	ld	wa, (xhl+4)
	ld	(xbc+2), wa
	.byte 0xc7
	addm32_24	0xe2c7a8, xhl
	extz	bc
	sla	bc, 2
	ld	wa, bc
	add	wa, 106
	.byte 0xd3
	reti
	or	xwa, xix
	ldb	w, 216
	.byte 0xcf
	swi	7
	swi	7
	jr	z, 40
	ld	ix, bc
	inc	4, ix
	ldada	xde, 1952
	.byte 0xf3
	reti
	cp	xwa, xwa
	.byte 0x50
	ld	ix, bc
	inc	6, ix
	add	bc, 108
	.byte 0xd3
	reti
	or	xix, xix
	ldb	w, 243
	reti
	cp	xwa, xwa
	.byte 0x50, 0xc7, 0xe2
	jr	lt, -57
	.byte 0xe2, 0xcf
	ldw	de, 0xbf67
	ld	a, (xsp)
	extz	wa
	calr	61097
	ldda32	xix, 3182
	ldda32	xiy, 3186
	ldw	bc, 0xb400
	.byte 0x95
	scf
	inc	2, xsp
	ret
	.byte 0xf3
	swi	5
	nop
	swi	4
	.byte 0x37
	pushw	iz
	calr	58277
	lda	xwa, (xsp+2)
	ld	xbc, 1024
	call	FileIO_ReadBlock
	call	FileIO_ReturnError
	ld	iz, hl
	cps	iz, 0
	jrl	lt, 284
	lda	xwa, (xsp+2)
	.byte 0x80
	push	xsp
	popw	wa
	jrl	nz, 279
	.byte 0x88, 0x01
	push	xsp
	nop
	jrl	nz, 272
	.byte 0x88
	push_sr
	push	xsp
	popw	hl
	jrl	nz, 265
	calr	57916
	ldda32	xwa, 3186
	ld	xbc, (xsp+70)
	call	FileIO_ReadBlock
	call	FileIO_ReturnError
	ld	iz, hl
	cps	iz, 0
	jrl	lt, 236
	lds	wa, 1
	calr	60043
	calr	57886
	ldda32	xwa, 3186
	ld	xbc, (xsp+74)
	call	FileIO_ReadBlock
	call	FileIO_ReturnError
	ld	iz, hl
	cps	iz, 0
	jrl	lt, 206
	lds	wa, 2
	calr	60013
	calr	57856
	ldda32	xwa, 3186
	ld	xbc, (xsp+78)
	call	FileIO_ReadBlock
	call	FileIO_ReturnError
	ld	iz, hl
	cps	iz, 0
	jrl	lt, 176
	lds	wa, 3
	calr	59983
	calr	57826
	ldda32	xwa, 3186
	ld	xbc, (xsp+82)
	call	FileIO_ReadBlock
	call	FileIO_ReturnError
	ld	iz, hl
	cps	iz, 0
	jrl	lt, 146
	lds	wa, 4
	calr	59953
	calr	57796
	ldda32	xwa, 3186
	ld	xbc, (xsp+86)
	call	FileIO_ReadBlock
	call	FileIO_ReturnError
	ld	iz, hl
	cps	iz, 0
	jr	lt, 117
	lds	wa, 5
	calr	59924
	calr	57767
	ldda32	xwa, 3186
	ld	xbc, (xsp+90)
	call	FileIO_ReadBlock
	call	FileIO_ReturnError
	ld	iz, hl
	cps	iz, 0
	jr	lt, 88
	lds	wa, 6
	calr	59895
	calr	57738
	ldda32	xwa, 3186
	ld	xbc, (xsp+94)
	call	FileIO_ReadBlock
	call	FileIO_ReturnError
	ld	iz, hl
	cps	iz, 0
	jr	lt, 59
	lds	wa, 7
	calr	59866
	ldda32	xix, 3222
	ldda32	xiy, 3218
	ldw	bc, 0x8000
	.byte 0x95
	scf
	ldda32	xwa, 3222
	ld	xbc, 0xf400
	call	FileIO_ReadBlock
	call	FileIO_ReturnError
	ld	iz, hl
	cps	iz, 0
	jr	lt, 18
	ldda32	xbc, 3222
	ldda32	xde, 3218
	lds	wa, 1
	call	Flash_EraseSectorAndWrite
	call	TmFlash_CopyToExtMem
	ld	hl, iz
	jr	3
	ldw	hl, 0xff9a
	popw	iz
	.byte 0xf3
	swi	5
	nop
	.byte 0x04, 0x37
	ret
	.byte 0xf3
	swi	5
	.byte 0xf4
	swi	3
	.byte 0x37
	push	xiz
	calr	57947
	ld	xiy, MSP_Default_Accompaniment
	lda	xix, (xsp+16)
	ldw	bc, 512
	.byte 0x95
	scf
	ldda32	xbc, 3190
	lds32	xhl, 0
	ld	l, (xbc+46)
	ld	a, (xbc+47)
	lds32	xix, 0
	.byte 0xc7, 0xf0, 0x99
	lda	xbc, (xsp+16)
	lda	xwa, (xbc+68)
	ld	(xsp+12), xwa
	sll	xix, 8
	add	xix, xhl
	sll	xix, 4
	ld	xwa, (xsp+12)
	ld	(xwa), xix
	ldda32	xde, 3194
	lds32	xhl, 0
	ld	l, (xde+46)
	ld	a, (xde+47)
	lds32	xix, 0
	.byte 0xc7, 0xf0, 0x99
	lda	xwa, (xbc+72)
	ld	(xsp+8), xwa
	sll	xix, 8
	add	xix, xhl
	sll	xix, 4
	ld	xwa, (xsp+8)
	ld	(xwa), xix
	ldda32	xde, 3198
	lds32	xhl, 0
	ld	l, (xde+46)
	ld	a, (xde+47)
	lds32	xix, 0
	.byte 0xc7, 0xf0, 0x99
	lda	xwa, (xbc+76)
	ld	(xsp+4), xwa
	sll	xix, 8
	add	xix, xhl
	sll	xix, 4
	ld	xwa, (xsp+4)
	ld	(xwa), xix
	ldda32	xde, 3202
	lds32	xhl, 0
	ld	l, (xde+46)
	ld	a, (xde+47)
	lds32	xix, 0
	.byte 0xc7, 0xf0, 0x99
	lda	xde, (xbc+80)
	sll	xix, 8
	add	xix, xhl
	sll	xix, 4
	ld	(xde), xix
	ldda32	xix, 3206
	lds32	xhl, 0
	ld	l, (xix+46)
	ld	a, (xix+47)
	lds32	xix, 0
	.byte 0xc7, 0xf0, 0x99
	lda	xiy, (xbc+84)
	sll	xix, 8
	add	xix, xhl
	sll	xix, 4
	ld	(xiy), xix
	ldda32	xix, 3210
	lds32	xhl, 0
	ld	l, (xix+46)
	ld	a, (xix+47)
	lds32	xix, 0
	.byte 0xc7, 0xf0, 0x99
	lda	xiz, (xbc+88)
	sll	xix, 8
	add	xix, xhl
	sll	xix, 4
	ld	(xiz), xix
	ldda32	xix, 3214
	lds32	xhl, 0
	ld	l, (xix+46)
	ld	a, (xix+47)
	lds32	xix, 0
	.byte 0xc7, 0xf0
	or	(xbc-20), iz
	ldio	235, 132
	ld	xhl, xix
	sll	xhl, 4
	ld	(xbc+92), xhl
	ld	xwa, (xsp+12)
	ld	xix, (xwa)
	.byte 0xa9
	ld	xwa, 0x2008af84
	ld	xwa, (xwa)
	add	xwa, xix
	ld	xix, (xsp+4)
	ld	xix, (xix)
	add	xix, xwa
	ld	xwa, (xde)
	add	xwa, xix
	ld	xde, (xiy)
	add	xde, xwa
	ld	xwa, (xiz)
	add	xwa, xde
	add	xhl, xwa
	ld	xwa, (xbc+96)
	add	xwa, xhl
	ld	(xbc+28), xwa
	ld	xiz, xwa
	call	FileIO_GetDiskFreeSpace
	cp	xhl, xiz
	jr	ge, 6
	ldw	hl, 0xff9b
	jrl	321
	lda	xwa, (xsp+16)
	ld	xbc, 1024
	call	FileIO_WriteByte_Impl
	call	FileIO_ReturnError
	cps	hl, 0
	jrl	lt, 296
	lds	wa, 1
	calr	59367
	ldda32	xwa, 3186
	lds32	xde, 0
	ld	e, (xwa+46)
	lds32	xbc, 0
	ld	c, (xwa+47)
	sla	xbc, 8
	add	xbc, xde
	sla	xbc, 4
	call	FileIO_WriteByte_Impl
	call	FileIO_ReturnError
	cps	hl, 0
	jrl	lt, 256
	lds	wa, 2
	calr	59327
	ldda32	xwa, 3186
	lds32	xde, 0
	ld	e, (xwa+46)
	lds32	xbc, 0
	ld	c, (xwa+47)
	sla	xbc, 8
	add	xbc, xde
	sla	xbc, 4
	call	FileIO_WriteByte_Impl
	call	FileIO_ReturnError
	cps	hl, 0
	jrl	lt, 216
	lds	wa, 3
	calr	59287
	ldda32	xwa, 3186
	lds32	xde, 0
	ld	e, (xwa+46)
	lds32	xbc, 0
	ld	c, (xwa+47)
	sla	xbc, 8
	add	xbc, xde
	sla	xbc, 4
	call	FileIO_WriteByte_Impl
	call	FileIO_ReturnError
	cps	hl, 0
	jrl	lt, 176
	lds	wa, 4
	calr	59247
	ldda32	xwa, 3186
	lds32	xde, 0
	ld	e, (xwa+46)
	lds32	xbc, 0
	ld	c, (xwa+47)
	sla	xbc, 8
	add	xbc, xde
	sla	xbc, 4
	call	FileIO_WriteByte_Impl
	call	FileIO_ReturnError
	cps	hl, 0
	jrl	lt, 136
	lds	wa, 5
	calr	59207
	ldda32	xhl, 3186
	lds32	xde, 0
	ld	e, (xhl+46)
	lds32	xbc, 0
	ld	c, (xhl+47)
	sla	xbc, 8
	add	xbc, xde
	sla	xbc, 4
	ld	xwa, xhl
	call	FileIO_WriteByte_Impl
	call	FileIO_ReturnError
	cps	hl, 0
	jr	lt, 95
	lds	wa, 6
	calr	59166
	ldda32	xhl, 3186
	lds32	xde, 0
	ld	e, (xhl+46)
	lds32	xbc, 0
	ld	c, (xhl+47)
	sla	xbc, 8
	add	xbc, xde
	sla	xbc, 4
	ld	xwa, xhl
	call	FileIO_WriteByte_Impl
	call	FileIO_ReturnError
	cps	hl, 0
	jr	lt, 54
	lds	wa, 7
	calr	59125
	ldda32	xhl, 3186
	lds32	xde, 0
	ld	e, (xhl+46)
	lds32	xbc, 0
	ld	c, (xhl+47)
	sla	xbc, 8
	add	xbc, xde
	sla	xbc, 4
	ld	xwa, xhl
	call	FileIO_WriteByte_Impl
	call	FileIO_ReturnError
	cps	hl, 0
	jr	lt, 13
	ldda32	xwa, 3218
	ld	xbc, 0xf400
	call	FileIO_WriteByte_Impl
	call	FileIO_ReturnError
	pop	xiz
	.byte 0xf3
	swi	5
	incf
	.byte 0x04, 0x37
	ret

; Floppy disk load and store note events via dispatch
FloppyDisk_LoadNoteEvents:
	st_dri3b L, 0xfd, 0xf8, 0xfb
	pushw iz
	st_dri3l XBC, 0xfd, 0x02, 0x04
	st_dri3l XWA, 0xfd, 0x06, 0x04
	calr Flash_InitExtMemAddrs
	lda xwa, (xsp + 2)
	ld_sril XIX, (xsp + 0x0406)
	ld xbc, 0x400
	call (xix)
	ld_sril XHL, (xsp + 0x0402)
	call (xhl)
	ld iz, hl
	cps iz, 0
	jrl lt, FloppyCtrl_LoadIzAndContinue
	lda xwa, (xsp + 2)
	cp (xwa), 0x48
	jrl nz, Floppy_SetHLFF9A_RetZero
	cp (xwa + 1), 0x0
	jrl nz, Floppy_SetHLFF9A_RetZero
	cp (xwa + 2), 0x4b
	jrl nz, Floppy_SetHLFF9A_RetZero
	calr NoteEvent_LoadSoundGenParams
	ldda32 xwa, 3186
	ld xbc, (xsp + 70)
	ld_sril XIX, (xsp + 0x0406)
	call (xix)
	ld_sril XHL, (xsp + 0x0402)
	call (xhl)
	ld iz, hl
	cps iz, 0
	jrl lt, FloppyCtrl_LoadIzAndContinue
	lds wa, 1
	calr NoteEventBuffer_Store
	calr NoteEvent_LoadSoundGenParams
	ldda32 xwa, 3186
	ld xbc, (xsp + 74)
	ld_sril XIX, (xsp + 0x0406)
	call (xix)
	ld_sril XHL, (xsp + 0x0402)
	call (xhl)
	ld iz, hl
	cps iz, 0
	jrl lt, FloppyCtrl_LoadIzAndContinue
	lds wa, 2
	calr NoteEventBuffer_Store
	calr NoteEvent_LoadSoundGenParams
	ldda32 xwa, 3186
	ld xbc, (xsp + 78)
	ld_sril XIX, (xsp + 0x0406)
	call (xix)
	ld_sril XHL, (xsp + 0x0402)
	call (xhl)
	ld iz, hl
	cps iz, 0
	jrl lt, FloppyCtrl_LoadIzAndContinue
	lds wa, 3
	calr NoteEventBuffer_Store
	calr NoteEvent_LoadSoundGenParams
	ldda32 xwa, 3186
	ld xbc, (xsp + 82)
	ld_sril XIX, (xsp + 0x0406)
	call (xix)
	ld_sril XHL, (xsp + 0x0402)
	call (xhl)
	ld iz, hl
	cps iz, 0
	jrl lt, FloppyCtrl_LoadIzAndContinue
	lds wa, 4
	calr NoteEventBuffer_Store
	calr NoteEvent_LoadSoundGenParams
	ldda32 xwa, 3186
	ld xbc, (xsp + 86)
	ld_sril XIX, (xsp + 0x0406)
	call (xix)
	ld_sril XHL, (xsp + 0x0402)
	call (xhl)
	ld iz, hl
	cps iz, 0
	jrl lt, FloppyCtrl_LoadIzAndContinue
	lds wa, 5
	calr NoteEventBuffer_Store
	calr NoteEvent_LoadSoundGenParams
	ldda32 xwa, 3186
	ld xbc, (xsp + 90)
	ld_sril XIX, (xsp + 0x0406)
	call (xix)
	ld_sril XHL, (xsp + 0x0402)
	call (xhl)
	ld iz, hl
	cps iz, 0
	jr lt, FloppyCtrl_LoadIzAndContinue
	lds wa, 6
	calr NoteEventBuffer_Store
	calr NoteEvent_LoadSoundGenParams
	ldda32 xwa, 3186
	ld xbc, (xsp + 94)
	ld_sril XIX, (xsp + 0x0406)
	call (xix)
	ld_sril XHL, (xsp + 0x0402)
	call (xhl)
	ld iz, hl
	cps iz, 0
	jr lt, FloppyCtrl_LoadIzAndContinue
	lds wa, 7
	calr NoteEventBuffer_Store
	ldda32 xix, 3222
	ldda32 xiy, 3218
	ldw bc, 0x8000
	ldirw
	ldda32 xwa, 3222
	ld_sril XIX, (xsp + 0x0406)
	ld xbc, 0xf400
	call (xix)
	ld_sril XHL, (xsp + 0x0402)
	call (xhl)
	ld iz, hl
	cps iz, 0
	jr lt, FloppyCtrl_LoadIzAndContinue
	ldda32 xbc, 3222
	ldda32 xde, 3218
	lds wa, 1
	call Flash_EraseSectorAndWrite
	call TmFlash_CopyToExtMem

FloppyCtrl_LoadIzAndContinue:
	ld hl, iz
	jr FloppyCtrl_PopIzStoreHL

Floppy_SetHLFF9A_RetZero:
	ldw hl, 0xff9a

FloppyCtrl_PopIzStoreHL:
	popw iz
	st_dri3b L, 0xfd, 0x08, 0x04
	ret

; Floppy disk compute tone parameters and validate
FloppyDisk_ComputeToneParams:
	st_dri3b L, 0xfd, 0xe8, 0xfb
	push xiz
	st_dri3l XDE, 0xfd, 0x10, 0x04
	st_dri3l XBC, 0xfd, 0x14, 0x04
	st_dri3l XWA, 0xfd, 0x18, 0x04
	calr Flash_InitExtMemAddrs
	ld xiy, MSP_Default_Signature3
	lda xix, (xsp + 16)
	ldw bc, 0x200
	ldirw
	ldda32 xbc, 3190
	lds32 xhl, 0
	ld l, (xbc + 46)
	ld a, (xbc + 47)
	lds32 xix, 0
	ldfr_berp A, 0xf0
	lda xbc, (xsp + 16)
	lda xwa, (xbc + 68)
	ld (xsp + 12), xwa
	sll xix, 8
	add xix, xhl
	sll xix, 4
	ld xwa, (xsp + 12)
	ld (xwa), xix
	ldda32 xde, 3194
	lds32 xhl, 0
	ld l, (xde + 46)
	ld a, (xde + 47)
	lds32 xix, 0
	ldfr_berp A, 0xf0
	lda xwa, (xbc + 72)
	ld (xsp + 8), xwa
	sll xix, 8
	add xix, xhl
	sll xix, 4
	ld xwa, (xsp + 8)
	ld (xwa), xix
	ldda32 xde, 3198
	lds32 xhl, 0
	ld l, (xde + 46)
	ld a, (xde + 47)
	lds32 xix, 0
	ldfr_berp A, 0xf0
	lda xwa, (xbc + 76)
	ld (xsp + 4), xwa
	sll xix, 8
	add xix, xhl
	sll xix, 4
	ld xwa, (xsp + 4)
	ld (xwa), xix
	ldda32 xde, 3202
	lds32 xhl, 0
	ld l, (xde + 46)
	ld a, (xde + 47)
	lds32 xix, 0
	ldfr_berp A, 0xf0
	lda xde, (xbc + 80)
	sll xix, 8
	add xix, xhl
	sll xix, 4
	ld (xde), xix
	ldda32 xix, 3206
	lds32 xhl, 0
	ld l, (xix + 46)
	ld a, (xix + 47)
	lds32 xix, 0
	ldfr_berp A, 0xf0
	lda xiy, (xbc + 84)
	sll xix, 8
	add xix, xhl
	sll xix, 4
	ld (xiy), xix
	ldda32 xix, 3210
	lds32 xhl, 0
	ld l, (xix + 46)
	ld a, (xix + 47)
	lds32 xix, 0
	ldfr_berp A, 0xf0
	lda xiz, (xbc + 88)
	sll xix, 8
	add xix, xhl
	sll xix, 4
	ld (xiz), xix
	ldda32 xix, 3214
	lds32 xhl, 0
	ld l, (xix + 46)
	ld a, (xix + 47)
	lds32 xix, 0
	ldfr_berp A, 0xf0
	sll xix, 8
	add xix, xhl
	ld xhl, xix
	sll xhl, 4
	ld (xbc + 92), xhl
	ld xwa, (xsp + 12)
	ld xix, (xwa)
	add xix, (xbc + 64)
	ld xwa, (xsp + 8)
	ld xwa, (xwa)
	add xwa, xix
	ld xix, (xsp + 4)
	ld xix, (xix)
	add xix, xwa
	ld xwa, (xde)
	add xwa, xix
	ld xde, (xiy)
	add xde, xwa
	ld xwa, (xiz)
	add xwa, xde
	add xhl, xwa
	ld xwa, (xbc + 96)
	add xwa, xhl
	ld (xbc + 28), xwa
	ld xiz, xwa
	ld_sril XIX, (xsp + 0x0418)
	call (xix)
	cp xhl, xiz
	jr ge, FloppyDisk_CopyNoteBuffers
	ldw hl, 0xff9b
	jrl FloppyCtrl_PopIzStoreRet

; Floppy disk copy note buffers to slots and write tone data
FloppyDisk_CopyNoteBuffers:
	lda xwa, (xsp + 16)
	ld_sril XIX, (xsp + 0x0414)
	ld xbc, 0x400
	call (xix)
	ld_sril XIX, (xsp + 0x0410)
	call (xix)
	cps hl, 0
	jrl lt, FloppyCtrl_PopIzStoreRet
	lds wa, 1
	calr NoteEventBuffer_CopyToSlot
	ldda32 xwa, 3186
	lds32 xde, 0
	ld e, (xwa + 46)
	lds32 xbc, 0
	ld c, (xwa + 47)
	sla xbc, 8
	add xbc, xde
	sla xbc, 4
	ld_sril XIX, (xsp + 0x0414)
	call (xix)
	ld_sril XIX, (xsp + 0x0410)
	call (xix)
	cps hl, 0
	jrl lt, FloppyCtrl_PopIzStoreRet
	lds wa, 2
	calr NoteEventBuffer_CopyToSlot
	ldda32 xwa, 3186
	lds32 xde, 0
	ld e, (xwa + 46)
	lds32 xbc, 0
	ld c, (xwa + 47)
	sla xbc, 8
	add xbc, xde
	sla xbc, 4
	ld_sril XIX, (xsp + 0x0414)
	call (xix)
	ld_sril XIX, (xsp + 0x0410)
	call (xix)
	cps hl, 0
	jrl lt, FloppyCtrl_PopIzStoreRet
	lds wa, 3
	calr NoteEventBuffer_CopyToSlot
	ldda32 xwa, 3186
	lds32 xde, 0
	ld e, (xwa + 46)
	lds32 xbc, 0
	ld c, (xwa + 47)
	sla xbc, 8
	add xbc, xde
	sla xbc, 4
	ld_sril XIX, (xsp + 0x0414)
	call (xix)
	ld_sril XIX, (xsp + 0x0410)
	call (xix)
	cps hl, 0
	jrl lt, FloppyCtrl_PopIzStoreRet
	lds wa, 4
	calr NoteEventBuffer_CopyToSlot
	ldda32 xwa, 3186
	lds32 xde, 0
	ld e, (xwa + 46)
	lds32 xbc, 0
	ld c, (xwa + 47)
	sla xbc, 8
	add xbc, xde
	sla xbc, 4
	ld_sril XIX, (xsp + 0x0414)
	call (xix)
	ld_sril XIX, (xsp + 0x0410)
	call (xix)
	cps hl, 0
	jrl lt, FloppyCtrl_PopIzStoreRet
	lds wa, 5
	calr NoteEventBuffer_CopyToSlot
	ldda32 xhl, 3186
	lds32 xde, 0
	ld e, (xhl + 46)
	lds32 xbc, 0
	ld c, (xhl + 47)
	sla xbc, 8
	add xbc, xde
	sla xbc, 4
	ld_sril XIX, (xsp + 0x0414)
	ld xwa, xhl
	call (xix)
	ld_sril XIX, (xsp + 0x0410)
	call (xix)
	cps hl, 0
	jr lt, FloppyCtrl_PopIzStoreRet
	lds wa, 6
	calr NoteEventBuffer_CopyToSlot
	ldda32 xhl, 3186
	lds32 xde, 0
	ld e, (xhl + 46)
	lds32 xbc, 0
	ld c, (xhl + 47)
	sla xbc, 8
	add xbc, xde
	sla xbc, 4
	ld_sril XIX, (xsp + 0x0414)
	ld xwa, xhl
	call (xix)
	ld_sril XIX, (xsp + 0x0410)
	call (xix)
	cps hl, 0
	jr lt, FloppyCtrl_PopIzStoreRet
	lds wa, 7
	calr NoteEventBuffer_CopyToSlot
	ldda32 xhl, 3186
	lds32 xde, 0
	ld e, (xhl + 46)
	lds32 xbc, 0
	ld c, (xhl + 47)
	sla xbc, 8
	add xbc, xde
	sla xbc, 4
	ld_sril XIX, (xsp + 0x0414)
	ld xwa, xhl
	call (xix)
	ld_sril XIX, (xsp + 0x0410)
	call (xix)
	cps hl, 0
	jr lt, FloppyCtrl_PopIzStoreRet
	ldda32 xwa, 3218
	ld_sril XIX, (xsp + 0x0414)
	ld xbc, 0xf400
	call (xix)
	ld_sril XIX, (xsp + 0x0410)
	call (xix)

FloppyCtrl_PopIzStoreRet:
	pop xiz
	st_dri3b L, 0xfd, 0x18, 0x04
	ret

ToneParam_ExtendedOpsBlock:
	pushw	iz
	call	cmp_ld_mae
	lda_24	xwa, 0x94800
	ld	xde, xwa
	lda_24	xbc, 0xab000
	sub	xbc, xde
	call	FileIO_ReadBlock
	call	FileIO_ReturnError
	ld	iz, hl
	cps	iz, 0
	jr	nz, 5
	calr	20
	ld	iz, hl
	ld	wa, iz
	cp	iz, 0xff95
	jr	nz, 2
	lds	wa, 0
	call	cmp_ld_ato
	ld	hl, iz
	popw	iz
	ret
	pushw	iz
	lds	iz, 0
	calr	56145
	ldda32	xde, 3182
	ld	a, (xde)
	.byte 0xc7, 0xee, 0x99
	lda	xwa, (xde+1)
	ld	h, (xwa)
	lda	xbc, (xde+2)
	ld	l, (xbc)
	.byte 0xc7
	cp	xiz, 0xce096e47
	dec	6, wa
	halt
	cp	l, 75
	jr	z, 16
	.byte 0xc7
	cp	xiz, 0xce1d6e4c
	muls8rr	c, l
	jr	nz, 24
	cp	l, 69
	jr	nz, 19
	ld	(xde), 72
	ld	(xwa), 0
	ld	(xbc), 75
	.byte 0x8a
	rcf
	push	xsp
	nop
	jr	nz, 98
	lds	wa, 0
	jr	80
	.byte 0xc7
	cp	xiz, 0xce096e46
	dec	6, wa
	halt
	cp	l, 75
	jr	z, 48
	.byte 0xc7
	cp	xiz, 0xce0a6e46
	.byte 0xcf
	ldb	w, 110
	halt
	cp	l, 75
	jr	z, 32
	.byte 0xc7
	cp	xiz, 0xce0a6e4c
	muls8rr	c, l
	jr	nz, 5
	cp	l, 65
	jr	z, 16
	.byte 0xc7
	cp	xiz, 0xce226e4c
	muls8rr	c, l
	jr	nz, 29
	cp	l, 66
	jr	nz, 24
	calr	35
	ld	iz, hl
	ldda32	xwa, 3186
	.byte 0x88
	rcf
	push	xsp
	nop
	jr	nz, 16
	ld	wa, iz
	calr	624
	ld	iz, hl
	jr	7
	call	AccDemo_InitDone
	ldw	iz, 0xff9a
	calr	534
	ld	hl, iz
	popw	iz
	ret
	dec	6, xsp
	.byte 0xbf, 0x04
	push_sr
	nop
	nop
	ldda32	xhl, 3182
	ldda32	xde, 3186
	ld	a, (xhl+16)
	ld	(xde+16), a
	lda	xiy, (xhl+96)
	lda	xix, (xde+96)
	ldw	bc, 975
	.byte 0x95
	scf
	.byte 0x85
	rcf
	lda	xiy, (xhl+2048)
	.byte 0xf3, 0xe9
	nop
	push_a
	ldw	ix, 0xff31
	jrl	c, 4501
	.byte 0x85
	rcf
	call	cmp_ld_mae
	ldda32	xwa, 3186
	stda32	0x39ae, xwa
	ldda32	xwa, 3182
	stda32	0x39b2, xwa
	lds32	xwa, 0
	ld	(xsp), xwa
	ld	xwa, (xsp)
	stda8	0x39ac, a
	stda8	0x39ad, a
	calr	387
	cps	hl, 0
	jr	z, 3
	ld	(xsp+4), hl
	lds32	xwa, 1
	add	(xsp), xwa
	ld	xwa, (xsp)
	cp	xwa, 11
	jr	ule, -34
	stdi8	0x39ac, 12
	stdi8	0x39ad, 12
	calr	353
	cps	hl, 0
	jr	z, 3
	ld	(xsp+4), hl
	stdi8	0x39ac, 13
	stdi8	0x39ad, 14
	calr	333
	cps	hl, 0
	jr	z, 3
	ld	(xsp+4), hl
	stdi8	0x39ac, 14
	stdi8	0x39ad, 15
	calr	313
	cps	hl, 0
	jr	z, 3
	ld	(xsp+4), hl
	stdi8	0x39ac, 15
	stdi8	0x39ad, 16
	calr	293
	cps	hl, 0
	jr	z, 3
	ld	(xsp+4), hl
	stdi8	0x39ac, 16
	stdi8	0x39ad, 24
	calr	273
	cps	hl, 0
	jr	z, 3
	ld	(xsp+4), hl
	stdi8	0x39ac, 17
	stdi8	0x39ad, 26
	calr	253
	cps	hl, 0
	jr	z, 3
	ld	(xsp+4), hl
	stdi8	0x39ac, 18
	stdi8	0x39ad, 27
	calr	233
	cps	hl, 0
	jr	z, 3
	ld	(xsp+4), hl
	stdi8	0x39ac, 19
	stdi8	0x39ad, 28
	calr	213
	cps	hl, 0
	jr	z, 3
	ld	(xsp+4), hl
	stdi8	0x39ac, 12
	stdi8	0x39ad, 18
	calr	193
	cps	hl, 0
	jr	z, 3
	ld	(xsp+4), hl
	stdi8	0x39ac, 13
	stdi8	0x39ad, 20
	calr	173
	cps	hl, 0
	jr	z, 3
	ld	(xsp+4), hl
	stdi8	0x39ac, 14
	stdi8	0x39ad, 21
	calr	153
	cps	hl, 0
	jr	z, 3
	ld	(xsp+4), hl
	stdi8	0x39ac, 15
	stdi8	0x39ad, 22
	calr	133
	cps	hl, 0
	jr	z, 3
	ld	(xsp+4), hl
	stdi8	0x39ac, 12
	stdi8	0x39ad, 13
	calr	113
	cps	hl, 0
	jr	z, 3
	ld	(xsp+4), hl
	stdi8	0x39ac, 15
	stdi8	0x39ad, 17
	calr	93
	cps	hl, 0
	jr	z, 3
	ld	(xsp+4), hl
	stdi8	0x39ac, 16
	stdi8	0x39ad, 25
	calr	73
	cps	hl, 0
	jr	z, 3
	ld	(xsp+4), hl
	stdi8	0x39ac, 19
	stdi8	0x39ad, 29
	calr	53
	cps	hl, 0
	jr	z, 3
	ld	(xsp+4), hl
	stdi8	0x39ac, 12
	stdi8	0x39ad, 19
	calr	33
	cps	hl, 0
	jr	z, 3
	ld	(xsp+4), hl
	stdi8	0x39ac, 15
	stdi8	0x39ad, 23
	calr	13
	cps	hl, 0
	jr	z, 3
	ld	(xsp+4), hl
	ld	hl, (xsp+4)
	inc	6, xsp
	ret
	pushw	iz
	lds	iz, 0
	.byte 0xf1
	lda	xiy, (xwa)
	.byte 0xb0
	call	DualVoice_ParamLoadDone
	ldda8	a, 0x35b0
	extz	wa
	bit	0, wa
	jr	z, 29
	ldda32	xwa, 0x39b2
	stda32	0x39ae, xwa
	.byte 0xc1, 0xad
	push	xbc
	pop_f
	.byte 0xac
	push	xbc
	call	AccPatch_InitFromSlotIndex
	ldda32	xwa, 3186
	stda32	0x39ae, xwa
	ldw	iz, 0xff95
	ld	hl, iz
	popw	iz
	ret
	ldb	l, 0
	lds	de, 0
	ld	wa, de
	add	wa, 96
	ldda32	xbc, 3182
	.byte 0xf3
	reti
	.byte 0xe4, 0xe0
	ldw	bc, 8889
	nop
	ld	xwa, 0x6ee189d8
	incf
	ldb	w, 243
	reti
	.byte 0xe0, 0xe4
	ldw	wa, 0x2ab8
	nop
	incf
	ldda32	xwa, 3182
	.byte 0xf3
	reti
	.byte 0xe0, 0xe4
	ldw	wa, 0x32b8
	nop
	jrl	ov, 0x6ee1
	incf
	ldb	w, 243
	reti
	.byte 0xe0, 0xe4
	ldw	wa, 0x3ab8
	nop
	ld	xwa, 0xc8da61cf
	jr	f, 0
	cp	l, 30
	jr	c, -71
	ret
	push	xiz
	ld	hl, wa
	ldda8	c, 0x34ed
	.byte 0xc7
	swi	3
	or	(xhl-63), iz
	ldw	ix, 0xc723
	swi	2
	.byte 0x9b
	ldda8	c, 0x34ef
	.byte 0xc7
	swi	1
	decm	6, (xhl-31)
	incf
	ldb	a, 137
	jrl	f, -4839
	ldw	ix, 0x6ee1
	incf
	ldb	a, 137
	jrl	lt, -4583
	ldw	ix, 0xeff1
	ldw	ix, 1024
	stdi8	0x34d6, 12
	ld	wa, hl
	calr	322
	stdi8	0x34ef, 5
	stdi8	0x34d6, 13
	ld	wa, hl
	calr	307
	stdi8	0x34ef, 6
	stdi8	0x34d6, 16
	ld	wa, hl
	calr	292
	stdi8	0x34ef, 7
	stdi8	0x34d6, 17
	ld	wa, hl
	calr	277
	stdi8	0x34ef, 10
	stdi8	0x34d6, 14
	ld	wa, hl
	calr	262
	stdi8	0x34ef, 11
	stdi8	0x34d6, 15
	ld	wa, hl
	calr	247
	ldda32	xbc, 3182
	.byte 0xc3, 0xe5, 0xf0, 0x01
	pop_f
	.byte 0xed
	ldw	ix, 0x6ee1
	incf
	ldb	a, 195
	.byte 0xe5, 0xf1, 0x01
	pop_f
	.byte 0xee
	ldw	ix, 0xeff1
	ldw	ix, 1024
	stdi8	0x34d6, 18
	ld	wa, hl
	calr	210
	stdi8	0x34ef, 5
	stdi8	0x34d6, 19
	ld	wa, hl
	calr	195
	stdi8	0x34ef, 6
	stdi8	0x34d6, 22
	ld	wa, hl
	calr	180
	stdi8	0x34ef, 7
	stdi8	0x34d6, 23
	ld	wa, hl
	calr	165
	stdi8	0x34ef, 10
	stdi8	0x34d6, 20
	ld	wa, hl
	calr	150
	stdi8	0x34ef, 11
	stdi8	0x34d6, 21
	ld	wa, hl
	calr	135
	ldda32	xbc, 3182
	.byte 0xc3, 0xe5
	jrl	f, 6403
	.byte 0xed
	ldw	ix, 0x6ee1
	incf
	ldb	a, 195
	.byte 0xe5
	jrl	lt, 6403
	.byte 0xee
	ldw	ix, 0xeff1
	ldw	ix, 1024
	stdi8	0x34d6, 24
	ld	wa, hl
	calr	98
	stdi8	0x34ef, 5
	stdi8	0x34d6, 25
	ld	wa, hl
	calr	83
	stdi8	0x34ef, 6
	stdi8	0x34d6, 28
	ld	wa, hl
	calr	68
	stdi8	0x34ef, 7
	stdi8	0x34d6, 29
	ld	wa, hl
	calr	53
	stdi8	0x34ef, 10
	stdi8	0x34d6, 26
	ld	wa, hl
	calr	38
	stdi8	0x34ef, 11
	stdi8	0x34d6, 27
	ld	wa, hl
	calr	23
	.byte 0xc7
	swi	3
	or	(xhl-15), e
	ldw	ix, 0xc743
	swi	2
	or	(xhl-15), h
	ldw	ix, 0xc743
	swi	1
	or	(xhl-15), l
	ldw	ix, 0x5e43
	ret
	pushw	iz
	ld	iz, wa
	.byte 0xf1, 0xd1
	ldw	ix, 7608
	popw	bc
	ldw	bc, 0xc1f6
	lda	xiy, (xwa)
	ldb	a, 216
	ccf
	bit	0, wa
	jr	z, 3
	ldw	iz, 0xff95
	ld	hl, iz
	popw	iz
	ret

DualVoice_LoadAndScan:
	lda xsp, (xsp - 12)
	push xiz
	ld xiz, xde
	ld (xsp + 12), c
	ld (xsp + 14), a
	ld (xsp + 4), 0x0
	ld (xsp + 10), 0x0
	calr Flash_InitExtMemAddrs
	stda32 3182, xiz
	cp (xsp + 14), 0xa
	jrl nc, DualVoice_LoadDoneRetVal
	ld a, (xsp + 14)
	extz wa
	calr DualVoice_ScanAllColumns
	ld a, (xsp + 12)
	extz wa
	calr DualVoice_ScanAllColumnsAlt
	ld a, (xsp + 12)
	extz wa
	calr NoteEvent_Store
	ld (xsp + 6), l
	ld a, (xsp + 6)
	extz wa
	calr NoteEventBuffer_CopyToSlot
	call AccPatch_CountSlotsAlt
	ld a, (xsp + 12)
	extz wa
	lda_24 xbc, MSP_Default_GroupIndexPad
	ld_srib3 A, 0x07, 0xe4, 0xe0
	ld (xsp + 8), a
	ldda32 xwa, 3186
	stda32 0x39ae, xwa
	ldi_berp 0xfb, 0

DualVoice_AccPatchLoop:
	ld c, (xsp + 8)
	extz bc
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x3
	ld de, wa
	add de, bc
	lda_24 xwa, MSP_Default_ChannelMap
	ldmm_srib 0x07, 0xe0, 0xe8, 0xac, 0x39
	call AccPatch_InitFromSlotIndex
	inc1_berp 0xfb
	cp_erpb 0xfb, 0x0a
	jr c, DualVoice_AccPatchLoop
	ldda32 xwa, 3182
	stda32 0x39ae, xwa
	ldda32 xwa, 3186
	stda32 0x39b2, xwa
	resda 0, 0x35b0
	ldi_berp 0xfb, 0

DualVoice_ParamCompareLoop:
	ld e, (xsp + 14)
	extz de
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x3
	ld bc, wa
	add wa, de
	lda_24 xde, MSP_Default_ChannelMap
	ldmm_srib 0x07, 0xe8, 0xe0, 0xac, 0x39
	ld a, (xsp + 8)
	extz wa
	add bc, wa
	ldmm_srib 0x07, 0xe8, 0xe4, 0xad, 0x39
	call DualVoice_ParamLoadDone
	ldda8 a, 0x35b0
	extz wa
	bit 0, wa
	jr z, DualVoice_LoopCheckNext
	ld (xsp + 10), 0x1

DualVoice_SetLoadFlag:
	ld (xsp + 4), 0x1

DualVoice_LoadDoneRetVal:
	ld l, (xsp + 4)
	pop xiz
	lda xsp, (xsp + 12)
	ret

DualVoice_LoopCheckNext:
	inc1_berp 0xfb
	cp_erpb 0xfb, 0x0a
	jr c, DualVoice_ParamCompareLoop
	cp (xsp + 10), 0x0
	jr nz, DualVoice_SetLoadFlag
	calr Flash_StoreBaseAndInitAccPatch
	ld a, (xsp + 6)
	extz wa
	calr NoteEventBuffer_Store
	ldada xwa, 1850
	cpw (xwa), 0xffff
	jr nz, DualVoice_WriteBackSlots
	cpw (xwa + 2), 0xffff
	jr z, DualVoice_LoadDoneRetVal

DualVoice_WriteBackSlots:
	calr Flash_WriteBackSlotTable
	jr DualVoice_LoadDoneRetVal
	pushw iz
	call msp_ld_mae
	lda_24 xwa, 0x1e8800
	ld xde, xwa
	lda_24 xbc, 0x1ec400
	sub xbc, xde
	call FileIO_ReadBlock
	call FileIO_ReturnError
	ld iz, hl
	calr FileHdr_ValidateSignature
	ld wa, iz
	call msp_ld_ato
	ld hl, iz
	popw iz
	ret

FileHdr_ValidateSignature:
	calr FileHdr_InitBasePointer
	ldda32 xwa, 3226
	ld l, (xwa)
	ld e, (xwa + 1)
	ld c, (xwa + 2)
	cp l, 0x47
	jr nz, FileHdr_CheckLKE
	cps e, 0
	jr nz, FileHdr_CheckLKE
	cp c, 0x4b
	jr z, FileHdr_SignatureMatch

FileHdr_CheckLKE:
	cp l, 0x4c
	jr nz, FileHdr_CheckMKB
	cp e, 0x4b
	jr nz, FileHdr_CheckMKB
	cp c, 0x45
	jr z, FileHdr_SignatureMatch

FileHdr_CheckMKB:
	cp l, 0x4d
	ret nz
	cp e, 0x4b
	ret nz
	cp c, 0x42
	ret nz

FileHdr_SignatureMatch:
	st_dri3b W, 0xe1, 0xff, 0x27
	ld xbc, xwa
	st_dri3b B, 0xe1, 0x01, 0xd9

FileHdr_CopyDataLoop:
	ld a, (xbc)
	lda_dri3 XBC, 0xe5, 0x00, 0x02
	dec 1, xbc
	cp xbc, xde
	jr nc, FileHdr_CopyDataLoop
	calr ToneData_SetupCopyPointers
	ret

FileHdr_InitBasePointer:
	lda_24 xwa, 0x1e8800
	stda32 3226, xwa
	ret

ToneData_SetupCopyPointers:
	ldda32 xbc, 3226
	st_dri3b A, 0xe5, 0x00, 0x01
	ld xwa, xbc
	st_dri3b A, 0xe5, 0x00, 0x02

ToneData_ZeroFillLoop:
	stib_dpi 0xe0, 0x00
	cp xwa, xbc
	jr c, ToneData_ZeroFillLoop

	lda_24 xwa, Composer_SettingsBlock
	ld xbc, xwa
	ldda32 xde, 3226
	lda xhl, (xwa + 6)

ToneData_CopyBlock1_Loop:
	ld_spib A, 0xe4
	lda_dpi XBC, 0xe8
	cp xbc, xhl
	jr c, ToneData_CopyBlock1_Loop
	lda_24 xhl, Composer_SettingsBlock_0x60
	ld xbc, xhl
	ldda32 xwa, 3226
	lda xde, (xwa + 16)
	lda xhl, (xhl + 16)

ToneData_CopyBlock2_Loop:
	ld_spib A, 0xe4
	lda_dpi XBC, 0xe8
	cp xbc, xhl
	jr c, ToneData_CopyBlock2_Loop
	lda_24 xhl, MSP_Default_PartBankMap
	ld xbc, xhl
	ldda32 xwa, 3226
	st_dri3b B, 0xe1, 0x00, 0x02
	lda xhl, (xhl + 64)

ToneData_CopyBlock3_Loop:
	ld_spib A, 0xe4
	lda_dpi XBC, 0xe8
	cp xbc, xhl
	jr c, ToneData_CopyBlock3_Loop
	lda_24 xhl, Composer_SettingsBlock_0x80
	ld xbc, xhl
	ldda32 xwa, 3226
	st_dri3b B, 0xe1, 0x40, 0x02
	lda xhl, (xhl + 64)

ToneData_CopyBlock4_Loop:
	ld_spib A, 0xe4
	lda_dpi XBC, 0xe8
	cp xbc, xhl
	jr c, ToneData_CopyBlock4_Loop
	lda_24 xhl, Composer_SettingsBlock_0xC0
	ld xbc, xhl
	ldda32 xwa, 3226
	st_dri3b B, 0xe1, 0x80, 0x02
	lda xhl, (xhl + 64)

ToneData_CopyBlock5_Loop:
	ld_spib A, 0xe4
	lda_dpi XBC, 0xe8
	cp xbc, xhl
	jr c, ToneData_CopyBlock5_Loop
	ldda32 xwa, 3226
	lda xbc, (xwa + 32)
	lds32 xde, 0

ToneData_ScanRegionLoop:
	cp (xbc), 0x0
	jr nz, ToneData_AdvanceRegion
	lda_24 xiy, Composer_SettingsBlock_0x70
	ld xhl, xiy
	ldda32 xwa, 3226
	lda xwa, (xwa + 32)
	ld xix, xde
	add xix, xwa
	lda xiy, (xiy + 16)

ToneData_CopyRegion_Inner:
	ld_spib A, 0xec
	lda_dpi XBC, 0xf0
	cp xhl, xiy
	jr c, ToneData_CopyRegion_Inner

ToneData_AdvanceRegion:
	add xde, 0x10
	lda xbc, (xbc + 16)
	cp xde, 0xc0
	jr c, ToneData_ScanRegionLoop
	ret

InitializeSuna:
	lda xsp, (xsp - 14)

	RegObjTable 0x1600004, 0xfa44e2, 0xe17322, 0xe16c86, 0x164
	RegObjTable 0x160000c, 0xfa58fb, 0xe17328, 0xe17324, 0x1c4
	RegObjTable 0x160000d, 0xfa5948, 0xe176d2, 0xe1732a, 0x1e4
	RegObjTabl 0x1600002, 0xfa496c, 0x49, 0xe16284, 0x124
	RegObjTabl 0x1600002, 0xfa496c, 0x49, 0xe163ac, 0x424
	RegObjTabl 0x1600001, 0xfa48a9, 0x1, 0xe176d4, 0x104
	RegObjTabl 0x1600001, 0xfa48a9, 0x1, 0xe176dc, 0x404
	RegObjTabl 0x1600003, 0xfa4a18, 0x24, 0xe1ca6e, 0x144
	RegObjTabl 0x1600003, 0xfa4a18, 0x24, 0xe1cb02, 0x444
	RegObjTabl 0x1600010, 0xfa5995, 0x3, 0xe1b4e2, 0x10
	RegObjTabl 0x160000f, 0xfa62cb, 0x3, 0xe1bafa, 0x310
	RegObjTabl 0x1600010, 0xfa5995, 0x8, 0xe1b4f2, 0x11
	RegObjTabl 0x160000f, 0xfa62cb, 0x8, 0xe1bb22, 0x311
	RegObjTabl 0x1600010, 0xfa5995, 0x7, 0xe1b516, 0x12
	RegObjTabl 0x160000f, 0xfa62cb, 0x7, 0xe1bb80, 0x312
	RegObjTabl 0x1600010, 0xfa5995, 0x4, 0xe1b536, 0x13
	RegObjTabl 0x160000f, 0xfa62cb, 0x4, 0xe1bbce, 0x313
	RegObjTabl 0x1600010, 0xfa5995, 0x4, 0xe1b54a, 0x14
	RegObjTabl 0x160000f, 0xfa62cb, 0x4, 0xe1bbfc, 0x314
	RegObjTabl 0x1600010, 0xfa5995, 0x8, 0xe1b55e, 0x15
	RegObjTabl 0x160000f, 0xfa62cb, 0x8, 0xe1bc2a, 0x315
	RegObjTabl 0x1600010, 0xfa5995, 0x7, 0xe1b582, 0x16
	RegObjTabl 0x160000f, 0xfa62cb, 0x7, 0xe1bc7c, 0x316
	RegObjTabl 0x1600010, 0xfa5995, 0x12, 0xe1b5a2, 0xb0
	RegObjTabl 0x160000f, 0xfa62cb, 0x12, 0xe1bcbc, 0x3b0
	RegObjTabl 0x1600010, 0xfa5995, 0xc, 0xe1b5ee, 0xb1
	RegObjTabl 0x160000f, 0xfa62cb, 0xc, 0xe1bd3a, 0x3b1
	RegObjTabl 0x1600010, 0xfa5995, 0x16, 0xe1b622, 0xb2
	RegObjTabl 0x160000f, 0xfa62cb, 0x16, 0xe1bd94, 0x3b2
	RegObjTabl 0x1600010, 0xfa5995, 0x5, 0xe1b67e, 0xb3
	RegObjTabl 0x160000f, 0xfa62cb, 0x5, 0xe1be54, 0x3b3
	RegObjTabl 0x1600010, 0xfa5995, 0x12, 0xe1b696, 0xb4
	RegObjTabl 0x160000f, 0xfa62cb, 0x12, 0xe1be9a, 0x3b4
	RegObjTabl 0x1600010, 0xfa5995, 0x1f, 0xe1b6e2, 0xb5
	RegObjTabl 0x160000f, 0xfa62cb, 0x1f, 0xe1bf7a, 0x3b5
	RegObjTabl 0x1600010, 0xfa5995, 0x1, 0xe1b762, 0xb6
	RegObjTabl 0x160000f, 0xfa62cb, 0x1, 0xe1c076, 0x3b6
	RegObjTabl 0x1600010, 0xfa5995, 0x6, 0xe1b76a, 0xb7
	RegObjTabl 0x160000f, 0xfa62cb, 0x6, 0xe1c082, 0x3b7
	RegObjTabl 0x1600010, 0xfa5995, 0x21, 0xe1b786, 0xb8
	RegObjTabl 0x160000f, 0xfa62cb, 0x21, 0xe1c0e0, 0x3b8
	RegObjTabl 0x1600010, 0xfa5995, 0x25, 0xe1b80e, 0xb9
	RegObjTabl 0x160000f, 0xfa62cb, 0x25, 0xe1c1fa, 0x3b9
	RegObjTabl 0x1600010, 0xfa5995, 0xe, 0xe1b8a6, 0xba
	RegObjTabl 0x160000f, 0xfa62cb, 0xe, 0xe1c318, 0x3ba
	RegObjTabl 0x1600010, 0xfa5995, 0x4, 0xe1b8e2, 0xbb
	RegObjTabl 0x160000f, 0xfa62cb, 0x4, 0xe1c392, 0x3bb
	RegObjTabl 0x1600010, 0xfa5995, 0xb, 0xe1b8f6, 0xbd
	RegObjTabl 0x160000f, 0xfa62cb, 0xb, 0xe1c3bc, 0x3bd
	RegObjTabl 0x1600010, 0xfa5995, 0x21, 0xe1b926, 0xbe
	RegObjTabl 0x160000f, 0xfa62cb, 0x21, 0xe1c410, 0x3be
	RegObjTabl 0x1600010, 0xfa5995, 0x1b, 0xe1b9ae, 0xc8
	RegObjTabl 0x160000f, 0xfa62cb, 0x1b, 0xe1c560, 0x3c8
	RegObjTabl 0x1600010, 0xfa5995, 0x10, 0xe1ba1e, 0xc9
	RegObjTabl 0x160000f, 0xfa62cb, 0x10, 0xe1c6dc, 0x3c9
	RegObjTabl 0x1600010, 0xfa5995, 0x6, 0xe1ba62, 0xca
	RegObjTabl 0x160000f, 0xfa62cb, 0x6, 0xe1c798, 0x3ca
	RegObjTabl 0x1600010, 0xfa5995, 0x4, 0xe1ba7e, 0xcb
	RegObjTabl 0x160000f, 0xfa62cb, 0x4, 0xe1c7ce, 0x3cb
	RegObjTabl 0x1600010, 0xfa5995, 0x9, 0xe1ba92, 0xcc
	RegObjTabl 0x160000f, 0xfa62cb, 0x9, 0xe1c7fa, 0x3cc
	RegObjTabl 0x1600010, 0xfa5995, 0x8, 0xe1baba, 0xdc
	RegObjTabl 0x160000f, 0xfa62cb, 0x8, 0xe1c85e, 0x3dc
	RegObjTabl 0x1600010, 0xfa5995, 0x6, 0xe1bade, 0xed
	RegObjTabl 0x160000f, 0xfa62cb, 0x6, 0xe1c8b6, 0x3ed

	RegMode 0x4, 0xe1, 0xc8fa, 0xe, 0x1440000, 0x1a000b0
	RegMode 0x4, 0xe1, 0xc902, 0xf, 0x1200000, 0x1a000ca
	RegMode 0x4, 0xe1, 0xc90a, 0x10, 0x1200000, 0x1a000c9
	RegMode 0x4, 0xe1, 0xc916, 0x11, 0x1440016, 0x1a000dc

	RegTitle 0x4, 0xe1, 0xc922, 0x10, 0x144001c, 0x100000
	RegTitle 0x4, 0xe1, 0xc932, 0x11, 0x144001e, 0x110000
	RegTitle 0x4, 0xe1, 0xc942, 0x12, 0x144001f, 0x120000
	RegTitle 0x4, 0xe1, 0xc952, 0x13, 0x1440022, 0x130000
	RegTitle 0x4, 0xe1, 0xc962, 0x14, 0x144001d, 0x140000
	RegTitle 0x4, 0xe1, 0xc970, 0x15, 0x1440020, 0x150000
	RegTitle 0x4, 0xe1, 0xc97e, 0x16, 0x1440021, 0x160000
	RegTitle 0x4, 0xe1, 0xc98e, 0xb0, 0x1440005, 0xb00000
	RegTitle 0x4, 0xe1, 0xc998, 0xb1, 0x1440003, 0xb10000
	RegTitle 0x4, 0xe1, 0xc9a2, 0xb2, 0x1440004, 0xb20000
	RegTitle 0x4, 0xe1, 0xc9ae, 0xb3, 0x1200000, 0xb30000
	RegTitle 0x4, 0xe1, 0xc9b8, 0xb4, 0x1440001, 0xb40000
	RegTitle 0x4, 0xe1, 0xc9c2, 0xb5, 0x1440002, 0xb50000
	RegTitle 0x4, 0xe1, 0xc9cc, 0xb6, 0x1440019, 0xb60000
	RegTitle 0x4, 0xe1, 0xc9d6, 0xb7, 0x1200000, 0xb70000
	RegTitle 0x4, 0xe1, 0xc9e0, 0xb8, 0x1440006, 0xb80000
	RegTitle 0x4, 0xe1, 0xc9ea, 0xb9, 0x1440008, 0xb90000
	RegTitle 0x4, 0xe1, 0xc9f6, 0xba, 0x1440007, 0xba0000
	RegTitle 0x4, 0xe1, 0xca00, 0xbb, 0x1200000, 0xbb0000
	RegTitle 0x4, 0xe1, 0xca0a, 0xbd, 0x1200000, 0xbd0000
	RegTitle 0x4, 0xe1, 0xca14, 0xbe, 0x1440009, 0xbe0000
	RegTitle 0x4, 0xe1, 0xca20, 0xc8, 0x1440011, 0xc80000
	RegTitle 0x4, 0xe1, 0xca2c, 0xc9, 0x1440015, 0xc90000
	RegTitle 0x4, 0xe1, 0xca36, 0xca, 0x1440012, 0xca0000
	RegTitle 0x4, 0xe1, 0xca42, 0xcb, 0x1440013, 0xcb0000
	RegTitle 0x4, 0xe1, 0xca4e, 0xcc, 0x1200000, 0xcc0000
	RegTitle 0x4, 0xe1, 0xca5a, 0xdc, 0x1440017, 0xdc0000
	RegTitle 0x4, 0xe1, 0xca64, 0xed, 0x1200000, 0xed0000

	lda xsp, (xsp + 14)
	ret

CmpBndRngFunc:
	push xiz
	ld xiz, xwa
	cp xbc, 0x1e0003f
	jr z, CmpBndRng_ReturnOne
	cp xbc, 0x1e0003e
	jr z, CmpBndRng_ReturnOne
	cp xbc, 0x1e00041
	jr z, CmpBndRng_ReturnThree
	cp xbc, 0x1e00040
	jr z, CmpBndRng_ReturnSizeConst
	cp xbc, 0x1e00042
	jr z, CmpBndRng_BoundCase
	lds32 xhl, 0
	jr CmpBndRng_PopIzRet

CmpBndRng_BoundCase:
	ld bc, (xde + 4)
	ld xwa, (xde + 8)
	cps bc, 0
	jr lt, CmpBndRng_DefaultString
	cp bc, 0xc
	jr gt, CmpBndRng_DefaultString
	sla bc, 2
	lda_24 xde, 0x03d992
	ld_sril3 XBC, 0x07, 0xe8, 0xe4
	push xbc
	jr CmpBndRng_CallStrcpy

CmpBndRng_DefaultString:
	pushw 0xe1
	pushw 0xce12

CmpBndRng_CallStrcpy:
	push xwa
	call Strcpy
	inc 8, xsp
	ld xhl, xiz
	jr CmpBndRng_PopIzRet

CmpBndRng_ReturnSizeConst:
	ld xhl, 0x28403
	jr CmpBndRng_PopIzRet

CmpBndRng_ReturnThree:
	lds32 xhl, 3
	jr CmpBndRng_PopIzRet

CmpBndRng_ReturnOne:
	lds32 xhl, 1

CmpBndRng_PopIzRet:
	pop xiz
	ret
CmpBndRng_End:

AcCmpMdBoxProc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xwa
	cp xbc, 0x1e0004d
	jrl z, CmpSetP1_TtlDispatch
	cp xbc, 0x1c0001d
	jr z, AcCmpMdBox_HandleLswUpdate
	cp xbc, 0x1c0000c
	jr z, AcCmpMdBox_InheritAndRefresh
	cp xbc, 0x1c0000b
	jr z, AcCmpMdBox_InheritAndRefresh
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	jrl CmpSetP1_TtlDispatch_End

AcCmpMdBox_InheritAndRefresh:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld xwa, 0x94810
	lds bc, 1
	call MainRamGet
	jr GridBoxProc_Return

AcCmpMdBox_HandleLswUpdate:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld xix, (xsp + 4)
	ld xbc, (xix)
	lda_24 xwa, 0x094810
	lda xde, (xhl + 46)
	cp xwa, xbc
	jr nz, GridBoxProc_Return
	ld l, (xhl + 50)
	extz hl
	extz xhl
	ld xbc, (xde)
	cp xhl, (xix + 14)
	jr nz, AcCmpMdBox_SetValueZero
	ldw (xbc), 0x1
	jr AcCmpMdBox_SendChangeEvent

AcCmpMdBox_SetValueZero:
	ldw (xbc), 0x0

AcCmpMdBox_SendChangeEvent:
	ld xwa, (xde)
	ld de, (xwa)
	exts xde
	ld xwa, xiz
	ld xbc, 0x1c0000e
	call SendEvent
	jr GridBoxProc_Return

; CmpSetP1 title dispatch
CmpSetP1_TtlDispatch:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 4)
	cp xwa, 0x1
	jr nz, GridBoxProc_Return
	ld xwa, xiz
	call GetViewInstance
	ld a, (xhl + 50)
	st8_24 0x094810, a

GridBoxProc_Return:
	lds32 xhl, 0

; CmpSetP1 title dispatch end
CmpSetP1_TtlDispatch_End:
	pop xiz
	inc 4, xsp
	ret
; CmpSetP1 title dispatch default
CmpSetP1_TtlDispatch_Default:
AcCmpSetGridBoxProc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 12), xde
	ld (xsp + 16), xbc
	ld xiz, xwa
	ld xbc, (xsp + 16)
	cp xbc, 0x1e0008d
	jrl z, CmpSetP1_GridCheck_Case3
	ld xwa, (xsp + 16)
	cp xwa, 0x1e0008b
	jrl z, CmpSetP1_GridCheck_Case1
	cp xwa, 0x1e0008a
	jrl z, CmpSetP1_GridCheckDispatch
	cp xwa, 0x1c00001
	jr z, CmpSetP1_DialGrid
	sub xbc, 0x1c00017
	cp xbc, 0x0
	jrl lt, CmpSetP1_GridCheck_Case4
	cp xbc, 0x6
	jrl gt, CmpSetP1_GridCheck_Case4
	add xbc, xbc
	add xbc, NoteStepDisplayData_0x5C
	ld bc, (xbc)
	lda_24 xix, CmpSetP1_DialGrid
	jp_dri 8, 0x07, 0xf0, 0xe4

; CmpSetP1 dial grid dispatch (7-entry, table 0xe1ce3a)
CmpSetP1_DialGrid:
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, xiz
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld (xsp + 4), xhl
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldi_werp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1c00017
	call SetDialUp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldi_werp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1c00018
	call SetDialDown
	lds wa, 1
	jrl CmpSetP1_SetDialEnable
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, CmpSetP1_SendAndApplyFunc
	ld xwa, xiz
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld wa, hl
	add wa, wa
	lda_24 xbc, NoteStepDisplayData_0x38
	ld_sriw3 WA, 0x07, 0xe4, 0xe0
	sub hl, wa
	extz xhl
	add xhl, 0xffff0000
	ld xwa, xiz
	ld xbc, 0x1c0000e
	ld xde, xhl
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl CmpSetP1_ReturnZeroJmp

CmpSetP1_SendAndApplyFunc:
	ld xwa, xiz
	ld xbc, 0x1e00091
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jrl z, CmpSetP1_ReturnZeroJmp
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call ApFuncCall
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	ld xwa, xiz
	ld xbc, 0x1c00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1c00018
	ld xde, (xsp + 12)
	call SetDialDown
	lds wa, 1
	jrl CmpSetP1_SetDialEnable
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, CmpSetP1_DialDownSendApply
	ld xwa, xiz
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld wa, hl
	add wa, wa
	lda_24 xbc, NoteStepDisplayData_0x4A
	ld_sriw3 WA, 0x07, 0xe4, 0xe0
	add wa, hl
	ld de, wa
	extz xde
	add xde, 0xffff0000
	ld xwa, xiz
	ld xbc, 0x1c0000e
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl CmpSetP1_ReturnZeroJmp

CmpSetP1_DialDownSendApply:
	ld xwa, xiz
	ld xbc, 0x1e00091
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, CmpSetP1_ReturnZeroJmp
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call ApFuncCall
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	ld xwa, xiz
	ld xbc, 0x1c00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1c00018
	ld xde, (xsp + 12)
	call SetDialDown
	lds wa, 1

CmpSetP1_SetDialEnable:
	call SetDialEnable
	jr CmpSetP1_ReturnZeroJmp

; CmpSetP1 grid check dispatch
CmpSetP1_GridCheckDispatch:
	ld xwa, xiz
	ld xiz, 0x3e
	jr CmpSetP1_GridCheck_Case2

; CmpSetP1 grid check case 1
CmpSetP1_GridCheck_Case1:
	ld xwa, xiz
	ld xiz, 0x42

; CmpSetP1 grid check case 2
CmpSetP1_GridCheck_Case2:
	call GetViewInstance
	add xhl, xiz
	ld xwa, (xhl)
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	jr CmpSetP1_ReturnZeroJmp

; CmpSetP1 grid check case 3
CmpSetP1_GridCheck_Case3:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call ApFuncCall

CmpSetP1_ReturnZeroJmp:
	lds32 xhl, 0
	jr CmpSetP1_GridCheck_Case5

; CmpSetP1 grid check case 4
CmpSetP1_GridCheck_Case4:
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc

; CmpSetP1 grid check case 5
CmpSetP1_GridCheck_Case5:
	pop xiz
	lda xsp, (xsp + 16)
	ret

CmpSetP1GridCheck:
	lda xsp, (xsp - 28)
	ld xwa, xbc
	cp xbc, 0x1e0008d
	jrl z, CmpSetP1_GridCheck_Return
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, Widget_PostEvtReturnZero
	cp xwa, 0x6
	jrl gt, Widget_PostEvtReturnZero
	add xwa, xwa
	add xwa, StrTimeSig_1_2_0x20
	ld wa, (xwa)
	lda_24 xix, CmpSetP1_GridCheck_EventEnc
	jp_dri 8, 0x07, 0xf0, 0xe0

; CmpSetP1 grid check event encoding dispatch
CmpSetP1_GridCheck_EventEnc:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 0x1e0008f
	lds32	xde, 0
	call	SendEvent
	ld	xde, xhl
	lda	xwa, (xsp+20)
	ld	xbc, xde
	srl	xbc, 0
	ld	qbc, 0
	ld	(xwa), bc
	ld	(xwa+2), de
	ld	wa, (xwa)
	cps	wa, 1
	jrl	nz, 328
	exts	xde
	ld	xwa, 0x144000d
	ld	xbc, 0x1e4000e
	jr	54
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 0x1e0008f
	lds32	xde, 0
	call	SendEvent
	ld	xde, xhl
	lda	xwa, (xsp+20)
	ld	xbc, xde
	srl	xbc, 0
	ld	qbc, 0
	ld	(xwa), bc
	ld	(xwa+2), de
	ld	wa, (xwa)
	cps	wa, 1
	jrl	nz, 272
	exts	xde
	ld	xwa, 0x144000d
	ld	xbc, 0x1e4000f
	call	MainFuncCall
	jrl	253

; CmpSetP1 grid check return
CmpSetP1_GridCheck_Return:
	lda xbc, (xsp + 20)
	ld xwa, xde
	srl xwa, 0
	ldi_werp 0xe2, 0
	ld (xbc), wa
	lda xwa, (xbc + 2)
	ld (xwa), de
	lda xde, (xsp)
	ld (xbc + 4), xde
	ld wa, (xwa)
	lda_24 xhl, 0x03da06
	dec 1, wa
	cps wa, 0
	jrl lt, WidgetHandler_PostEventAndReturnZero
	cps wa, 7
	jrl gt, WidgetHandler_PostEventAndReturnZero
	add wa, wa
	lda_24 xix, StrTimeSig_1_2_0x10
	ld_sriw3 WA, 0x07, 0xf0, 0xe0
	lda_24 xix, UI_COMPONENT_DISPATCH
	jp_dri 8, 0x07, 0xf0, 0xe0
; UI component dispatch table - handles cases 0-7 for grid/focus handling
; Offset table at 0xe1cef0 selects which handler to run based on WA value
UI_COMPONENT_DISPATCH:
	ldda8 a, 0x34d7	; Load byte from UI state
	inc 1, a	; Increment by 1
	extz wa	; Zero-extend A to WA
	pushw wa	; Push WA as parameter
	pushw 0xe1	; Push parameter
	pushw 0xcee4	; Push parameter
	push xde	; Push XDE
	call Sprintf_Locked	; Call handler function
	lda xsp, (xsp + 10)	; Clean up stack (10 bytes)
	jrl WidgetHandler_PostEventAndReturnZero	; Jump to end
UI_COMPONENT_DISPATCH_CASE1:
	ldda8 a, 0x34ce	; Load byte from UI state
	srl a, 7	; Shift right logical by 7
	extz wa	; Zero-extend A to WA
	sla wa, 2	; Shift left by 2 (multiply by 4)
	lda_24 xbc, 0x03d9f6                  ; Load table address
	ld_sril3 XWA, 0x07, 0xe4, 0xe0	; Load entry from table
	push xwa	; Push parameter
	ldda8 a, 0x34d8	; Load byte from UI state
	extz wa	; Zero-extend A to WA
	sla wa, 2	; Shift left by 2 (multiply by 4)
	lda_24 xbc, 0x03da0e                  ; Load table address
	ld_sril3 XWA, 0x07, 0xe4, 0xe0	; Load entry from table
	push xwa	; Push parameter
	pushw 0xe1	; Push parameter
	pushw 0xcee8	; Push parameter
	push xde	; Push XDE
	call Sprintf_Locked	; Call handler function
	lda xsp, (xsp + 16)	; Clean up stack (16 bytes)
	jr WidgetHandler_PostEventAndReturnZero	; Jump to end
UI_COMPONENT_DISPATCH_CASE2:
	ldda8 c, 0x34e9	; Load byte from UI state
	ld xwa, 0x3d9c6	; Load table address
	jr UI_COMPONENT_DISPATCH_CASE2_COMMON	; Jump to common code
UI_COMPONENT_DISPATCH_CASE3:
	ldda8 a, 0x34ea	; Load byte from UI state
	srl a, 4	; Shift right logical by 4
	and a, 0x1	; Mask to get bit 4
	ld c, a	; Copy to C
	ld xwa, 0x3d9fe	; Load table address
UI_COMPONENT_DISPATCH_CASE2_COMMON:
	extz bc	; Zero-extend C to BC
	sla bc, 2	; Shift left by 2 (multiply by 4)
	ld_sril3 XWA, 0x07, 0xe0, 0xe4	; Load entry from table
	push xwa	; Push parameter
	jr UI_COMPONENT_DISPATCH_PUSH_CALL	; Jump to push and call
UI_COMPONENT_DISPATCH_CASE4:
	lds wa, 6	; Load 6
	jr UI_COMPONENT_DISPATCH_CASE5_COMMON	; Jump to common code
UI_COMPONENT_DISPATCH_CASE5:
	lds wa, 5	; Load 5
UI_COMPONENT_DISPATCH_CASE5_COMMON:
	ldda8 c, 0x34ea	; Load byte from UI state
	and a, 0xf	; Mask lower nibble
	jr z, UI_COMPONENT_DISPATCH_CASE5_SKIP	; Skip shift if zero
	srla c	; Shift A right by C
UI_COMPONENT_DISPATCH_CASE5_SKIP:
	and c, 0x1	; Mask C to get bit 0
	extz bc	; Zero-extend C to BC
	sla bc, 2	; Shift left by 2 (multiply by 4)
	ld_sril3 XWA, 0x07, 0xec, 0xe4	; Load entry from table
	push xwa	; Push parameter
UI_COMPONENT_DISPATCH_PUSH_CALL:
	push xde	; Push XDE
	call Sprintf_Locked	; Call handler function
	inc 8, xsp	; Increment stack pointer

WidgetHandler_PostEventAndReturnZero:
	cpw (xsp + 22), 0x4
	jr z, Widget_PostEvtReturnZero
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 20)
	ld xbc, 0x1e0008c
	call SendEvent

Widget_PostEvtReturnZero:
	lds32 xhl, 0
	lda xsp, (xsp + 28)
	ret

CmpSetGridCheck:
	lda xsp, (xsp - 18)
	push xiz
	ld xwa, xbc
	cp xbc, 0x1e0008d
	jrl z, CmpSet_GridCheck_Dispatch
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, GridCheck_ReturnZero
	cp xwa, 0x6
	jrl gt, GridCheck_ReturnZero
	add xwa, xwa
	add xwa, StrPanLeft64_0xA
	ld wa, (xwa)
	lda_24 xix, GridCheck_Handler0
	jp_dri 8, 0x07, 0xf0, 0xe0

; =============================================================================
; GridCheck_Handler0 - Grid/Check widget handler for cases 0 and 2
; Called via jump table when event code is 0x1c00017 + (0 or 2)
; Queries UI object state and sends appropriate event (0x01e40008 or 0x01e4000a)
; =============================================================================
GridCheck_Handler0:
	call GetFocusObject	; Get UI object
	ld xwa, xhl	; Save result in XWA
	ld xbc, 0x1e0008f	; Event code for query
	lds32 xde, 0	; Parameter = 0
	call SendEvent	; Query object state
	ld xde, xhl	; Result in XDE
	lda xwa, (xsp + 14)	; Get local var pointer
	ld xbc, xde	; Copy result to XBC
	srl xbc, 0	; SRL 0, XBC (clear carry)
	ldi_werp 0xe6, 0	; LD QBC, 0 (clear high bits)
	ld (xwa), bc	; Store low word
	ld (xwa + 2), de	; Store high word
	ld wa, (xwa)	; Load state value
	exts xde	; Sign extend DE
	cps wa, 2	; Check if state == 2
	jr z, GridCheck_Handler0_State2
	cps wa, 1	; Check if state == 1
	jrl nz, GridCheck_ReturnZero	; If neither, exit
	ld xwa, 0x144000d	; Widget ID
	ld xbc, 0x1e40008	; Event: grid check state 1 (case 0)
	jr GridCheck_SendEvent
GridCheck_Handler0_State2:
	ld xwa, 0x144000d	; Widget ID
	ld xbc, 0x1e4000a	; Event: grid check state 2 (case 0)
	jr GridCheck_SendEvent

; =============================================================================
; GridCheck_Handler1 - Grid/Check widget handler for cases 1 and 3
; Called via jump table when event code is 0x1c00017 + (1 or 3)
; Queries UI object state and sends appropriate event (0x01e40009 or 0x01e4000b)
; =============================================================================
GridCheck_Handler1:
	call GetFocusObject	; Get UI object
	ld xwa, xhl	; Save result in XWA
	ld xbc, 0x1e0008f	; Event code for query
	lds32 xde, 0	; Parameter = 0
	call SendEvent	; Query object state
	ld xde, xhl	; Result in XDE
	lda xwa, (xsp + 14)	; Get local var pointer
	ld xbc, xde	; Copy result to XBC
	srl xbc, 0	; SRL 0, XBC (clear carry)
	ldi_werp 0xe6, 0	; LD QBC, 0 (clear high bits)
	ld (xwa), bc	; Store low word
	ld (xwa + 2), de	; Store high word
	ld wa, (xwa)	; Load state value
	exts xde	; Sign extend DE
	cps wa, 2	; Check if state == 2
	jr z, GridCheck_Handler1_State2
	cps wa, 1	; Check if state == 1
	jr nz, GridCheck_ReturnZero	; If neither, exit
	ld xwa, 0x144000d	; Widget ID
	ld xbc, 0x1e40009	; Event: grid check state 1 (case 1)
	jr GridCheck_SendEvent
GridCheck_Handler1_State2:
	ld xwa, 0x144000d	; Widget ID
	ld xbc, 0x1e4000b	; Event: grid check state 2 (case 1)
	; Fall through to GridCheck_SendEvent

; =============================================================================
; GridCheck_SendEvent - Common epilogue for grid/check handlers
; Sends the event in XBC with widget ID in XWA
; =============================================================================
GridCheck_SendEvent:
	call MainFuncCall	; Send event
	jr GridCheck_ReturnZero	; Return to caller

; CmpSet grid check dispatch (7-entry, table 0xe1d40e)
CmpSet_GridCheck_Dispatch:
	lda xbc, (xsp + 14)
	ld xwa, xde
	srl xwa, 0
	ldi_werp 0xe2, 0
	ld (xbc), wa
	lda xwa, (xbc + 2)
	ld (xwa), de
	lda xde, (xsp + 4)
	ld (xbc + 4), xde
	ld de, (xbc)
	ld bc, (xwa)
	exts xbc
	cps de, 2
	jr z, GridCheck_SetMode1
	cps de, 1
	jr nz, GridCheck_GetFocusAndSend
	lds wa, 0
	ld xiz, 0x3da4e
	jr GridCheck_LookupAndSend

GridCheck_SetMode1:
	lds wa, 1
	ld xiz, 0x3d9c6

GridCheck_LookupAndSend:
	calr GridCheck_LookupSndParam
	extz hl
	sla hl, 2
	ld_sril3 XWA, 0x07, 0xf8, 0xec
	push xwa
	lda xwa, (xsp + 8)
	push xwa
	call Sprintf_Locked
	inc 8, xsp

GridCheck_GetFocusAndSend:
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 14)
	ld xbc, 0x1e0008c
	call SendEvent

GridCheck_ReturnZero:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 18)
	ret

GridCheck_LookupSndParam:
	ldda8 e, 0x34d6
	extz de
	sla de, 2
	lda_24 xhl, RhythmTiming_OffsetTable
	ld xix, 0x94860
	add_sril_rm XIX, 0x07, 0xec, 0xe8
	sll xbc, 3
	add xbc, 0x10
	add xbc, xix
	cps a, 0
	jr nz, GridCheck_ClampParamAlt
	ld l, (xbc + 2)
	cp l, 0x7f
	ret ule
	ldb l, 0x7f
	jr GridCheck_ClampDone

GridCheck_ClampParamAlt:
	ld l, (xbc + 5)
	cp l, 0xb
	ret ule
	ldb l, 0xb

GridCheck_ClampDone:
	ret

CmpSetPageFunc:
	cp xbc, 0x1c0000c
	jr z, CmpSetPage_ReturnZero
	cp xbc, 0x1c0000b
	jr z, CmpSetPage_ReturnZero
	cp xbc, 0x1c00002
	jr z, CmpSetPage_ReturnZero
	cp xbc, 0x1c00001
	jr nz, CmpSetPage_ReturnZero
	or xde, xde
	jr nz, CmpSetPage_ReturnZero
	ld xwa, 0xb40002
	ld xbc, 0x1e0007f
	lds32 xde, 1
	call SendEvent
	ld xwa, 0xb4000e
	ld xbc, 0x1e0008e
	ld xde, 0xffff0002
	call SendEvent

CmpSetPage_ReturnZero:
	lds32 xhl, 0
	ret
AcApcToggle_End:

AcApcToggleProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld xiz, xbc
	ld (xsp + 12), xwa
	cp xiz, 0x1c0001c
	jrl z, AcApcToggle_HandleLswMsg
	cp xiz, 0x1c00001
	jr z, AcApcToggle_HandleOpen
	cp xiz, 0x1c00007
	jr z, AcApcToggle_HandleClose
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	jr AcApcToggle_CallInherited

AcApcToggle_HandleClose:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 12)
	ld xbc, 0x1e00053
	ld xde, (xsp + 8)
	call SendEvent
	cps hl, 0
	jr z, AcApcToggle_Fallthrough
	ld xwa, (xsp + 12)
	ld xbc, 0x1e0006c
	lds32 xde, 0
	call SendEvent
	ld xbc, (xsp + 4)
	ld xwa, (xbc + 34)
	ld de, (xwa)
	exts xde
	ld xwa, (xbc + 40)
	ld xbc, 0x1e0003b
	call ApFuncCall
	jrl EventHandler_Return

AcApcToggle_Fallthrough:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)

AcApcToggle_CallInherited:
	call InheritedProc
	jrl AcApcToggle_PopReturn

AcApcToggle_HandleOpen:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xiz, xhl
	ld xbc, (xiz + 44)
	cp xbc, 0x1
	jr z, AcApcToggle_SetParam83
	or xbc, xbc
	jr nz, AcApcToggle_ReadSndParam
	ld xwa, 0x28081
	jr AcApcToggle_ReadSndParam

AcApcToggle_SetParam83:
	ld xwa, 0x28083

AcApcToggle_ReadSndParam:
	call SndParam_LookupReadOnly
	lda xbc, (xiz + 34)
	ld xwa, (xbc)
	cps hl, 0
	jr nz, AcApcToggle_SetOne
	ldw (xwa), 0x0
	jr AcApcToggle_SendUpdate

AcApcToggle_SetOne:
	ldw (xwa), 0x1

AcApcToggle_SendUpdate:
	ld xwa, (xbc)
	ld de, (xwa)
	exts xde
	ld xwa, (xsp + 12)
	ld xbc, 0x1c0000f
	jrl AcApcToggle_SendEvent

AcApcToggle_HandleLswMsg:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xwa, (xsp + 8)
	ld xbc, (xwa)
	lda xwa, (xhl + 44)
	cp xbc, 0x28083
	jr z, AcApcToggle_Check83Match
	cp xbc, 0x28081
	jr nz, EventHandler_Return
	ld xwa, (xwa)
	or xwa, xwa
	jr nz, EventHandler_Return
	ld xwa, 0x28081
	call SndParam_LookupReadOnly
	ld xwa, (xsp + 8)
	cpw (xwa + 4), 0x1
	jr nz, AcApcToggle_SendZero
	ld xwa, (xsp + 12)
	ld xbc, 0x1c0000f
	lds32 xde, 1
	jr AcApcToggle_SendEvent

AcApcToggle_SendZero:
	ld xwa, (xsp + 12)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jr AcApcToggle_SendEvent

AcApcToggle_Check83Match:
	ld xwa, (xwa)
	cp xwa, 0x1
	jr nz, EventHandler_Return
	ld xwa, (xsp + 8)
	cpw (xwa + 4), 0x1
	jr nz, AcApcToggle_Send83Zero
	ld xwa, (xsp + 12)
	ld xbc, 0x1c0000f
	lds32 xde, 1
	jr AcApcToggle_SendEvent

AcApcToggle_Send83Zero:
	ld xwa, (xsp + 12)
	ld xbc, 0x1c0000f
	lds32 xde, 0

AcApcToggle_SendEvent:
	call SendEvent

EventHandler_Return:
	lds32 xhl, 0

AcApcToggle_PopReturn:
	pop xiz
	lda xsp, (xsp + 12)
	ret

ApcOnOffFunc:
	cp xbc, 0x1e0003b
	jr nz, ApcOnOff_ReturnZero
	ld xwa, 0x28081
	lds bc, 1
	lds de, 4
	call MainLswPut

ApcOnOff_ReturnZero:
	lds32 xhl, 0
	ret

ApcOnBasFunc:
	cp xbc, 0x1e0003b
	jr nz, ApcOnBas_ReturnZero
	ld xwa, 0x28083
	lds bc, 1
	lds de, 4
	call MainLswPut

ApcOnBas_ReturnZero:
	lds32 xhl, 0
	ret
ApcOnBas_End:

AcApcMdBoxProc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xwa
	cp xbc, 0x1e0004d
	jrl z, AcApcMdBox_HandleTitleDisp
	cp xbc, 0x1c0001c
	jr z, AcApcMdBox_HandleLswUpdate
	cp xbc, 0x1c0000c
	jr z, AcApcMdBox_GetLswValue
	cp xbc, 0x1c0000b
	jr z, AcApcMdBox_GetLswValue
	cp xbc, 0x1c00002
	jr z, AcApcMdBox_ResetFilter
	cp xbc, 0x1c00001
	jrl nz, AcApcMdBox_DefaultInherited
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld xwa, xiz
	ld xbc, 0x28080
	call SetLswFilter
	lds wa, 0
	jrl AcApcMdBox_SetDialEnable

AcApcMdBox_ResetFilter:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld xwa, xiz
	ld xbc, 0x28080
	call ResetLswFilter
	jrl AcS2cMem_ReturnZeroJmp

AcApcMdBox_GetLswValue:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld xwa, 0x28080
	call MainLswGet
	jrl AcS2cMem_ReturnZeroJmp

AcApcMdBox_HandleLswUpdate:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld xiy, (xsp + 4)
	ld xwa, (xiy)
	cp xwa, 0x28080
	jr nz, AcS2cMem_ReturnZeroJmp
	ld a, (xhl + 50)
	ldfr_berp A, 0xf0
	extz ix
	lda xde, (xhl + 46)
	ld xbc, (xde)
	cp ix, (xiy + 4)
	jr nz, AcApcMdBox_SetValueZero
	ldw (xbc), 0x1
	jr AcApcMdBox_SendChangeEvent

AcApcMdBox_SetValueZero:
	ldw (xbc), 0x0

AcApcMdBox_SendChangeEvent:
	ld xwa, (xde)
	ld de, (xwa)
	exts xde
	ld xwa, xiz
	ld xbc, 0x1c0000e
	call SendEvent
	jr AcS2cMem_ReturnZeroJmp

AcApcMdBox_HandleTitleDisp:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 4)
	cp xwa, 0x1
	jr nz, AcS2cMem_ReturnZeroJmp
	ld xwa, xiz
	call GetViewInstance
	ld a, (xhl + 50)
	ldfr_berp A, 0xf8
	extz iz
	ld xwa, 0x28080
	call SndParam_LookupReadOnly
	cp hl, iz
	jr z, AcS2cMem_ReturnZeroJmp
	ld xwa, 0x28080
	ld bc, iz
	lds de, 4
	call MainLswPut
	lds wa, 0

AcApcMdBox_SetDialEnable:
	call SetDialEnable

AcS2cMem_ReturnZeroJmp:
	lds32 xhl, 0
	jr AcApcMdBox_PopReturn

AcApcMdBox_DefaultInherited:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc

AcApcMdBox_PopReturn:
	pop xiz
	inc 4, xsp
	ret
AcApcMdBox_End:

AcS2cMemNoBoxProc:
	st_dri3b L, 0xfd, 0x00, 0xff
	push xiz
	ld xiz, xwa
	cp xbc, 0x1c0000c
	jr z, S2cMemNoBox_HandleScroll
	cp xbc, 0x1c0000b
	jr z, S2cMemNoBox_HandleScroll
	cp xbc, 0x1c00002
	jr z, S2cMemNoBox_HandleClose
	cp xbc, 0x1c00001
	jr z, S2cMemNoBox_HandleOpen
	ld xwa, xiz
	call InheritedProc
	jr S2cMemNoBox_PopReturn

S2cMemNoBox_HandleOpen:
	ld xwa, xiz
	jr S2cMemNoBox_CallInherited

S2cMemNoBox_HandleClose:
	ld xwa, xiz

S2cMemNoBox_CallInherited:
	call InheritedProc
	jr S2cMemNoBox_ReturnZero

S2cMemNoBox_HandleScroll:
	ld xwa, xiz
	call InheritedProc
	ldda8 a, 0x398f
	extz wa
	sla wa, 2
	lda_24 xbc, StrPanLeft64_0x18
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	lda xwa, (xsp + 8)
	push xwa
	call Sprintf_Locked
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1c0000f
	call SendEvent

S2cMemNoBox_ReturnZero:
	lds32 xhl, 0

S2cMemNoBox_PopReturn:
	pop xiz
	st_dri3b L, 0xfd, 0x00, 0x01
	ret
S2cMemNoBox_End:

PsS2cFmeasBoxProc:
	st_dri3b L, 0xfd, 0xfc, 0xfe
	push xiz
	st_dri3l XWA, 0xfd, 0x04, 0x01
	cp xbc, 0x1c0000c
	jr z, PsS2cFmeas_HandleScroll
	cp xbc, 0x1c0000b
	jr z, PsS2cFmeas_HandleScroll
	ld_sril XWA, (xsp + 0x0104)
	call InheritedProc
	jr PsS2cFmeas_PopReturn

PsS2cFmeas_HandleScroll:
	ld_sril XWA, (xsp + 0x0104)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0104)
	call GetViewInstance
	ld xiz, xhl
	push_sd16w 0x8a, 0x39
	pushw 0xe1
	pushw 0xd584
	lda xwa, (xsp + 10)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	lda xbc, (xiz + 22)
	lda xwa, (xiz + 32)
	cpdi8 0x3a77, 0
	jr nz, PsS2cFmeas_SetActive
	ldw (xwa), 0x0
	ldw (xbc), 0xff
	jr PsS2cFmeas_SendUpdateEvents

PsS2cFmeas_SetActive:
	ldw (xwa), 0xff
	ldw (xbc), 0xf5

PsS2cFmeas_SendUpdateEvents:
	ld_sril XWA, (xsp + 0x0104)
	ld xbc, 0x1c0000d
	lds32 xde, 0
	call SendEvent
	lda xde, (xsp + 4)
	ld_sril XWA, (xsp + 0x0104)
	ld xbc, 0x1c0000f
	call SendEvent
	lds32 xhl, 0

PsS2cFmeas_PopReturn:
	pop xiz
	st_dri3b L, 0xfd, 0x04, 0x01
	ret
PsS2cFmeas_End:

PsS2cLmeasBoxProc:
	st_dri3b L, 0xfd, 0xfc, 0xfe
	push xiz
	st_dri3l XWA, 0xfd, 0x04, 0x01
	cp xbc, 0x1c0000c
	jr z, PsS2cLmeas_HandleScroll
	cp xbc, 0x1c0000b
	jr z, PsS2cLmeas_HandleScroll
	ld_sril XWA, (xsp + 0x0104)
	call InheritedProc
	jr PsS2cLmeas_PopReturn

PsS2cLmeas_HandleScroll:
	ld_sril XWA, (xsp + 0x0104)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0104)
	call GetViewInstance
	ld xiz, xhl
	push_sd16w 0x8c, 0x39
	pushw 0xe1
	pushw 0xd588
	lda xwa, (xsp + 10)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	lda xbc, (xiz + 22)
	lda xwa, (xiz + 32)
	cpdi8 0x3a77, 1
	jr nz, PsS2cLmeas_SetActive
	ldw (xwa), 0x0
	ldw (xbc), 0xff
	jr PsS2cLmeas_SendUpdateEvents

PsS2cLmeas_SetActive:
	ldw (xwa), 0xff
	ldw (xbc), 0xf5

PsS2cLmeas_SendUpdateEvents:
	ld_sril XWA, (xsp + 0x0104)
	ld xbc, 0x1c0000d
	lds32 xde, 0
	call SendEvent
	lda xde, (xsp + 4)
	ld_sril XWA, (xsp + 0x0104)
	ld xbc, 0x1c0000f
	call SendEvent
	lds32 xhl, 0

PsS2cLmeas_PopReturn:
	pop xiz
	st_dri3b L, 0xfd, 0x04, 0x01
	ret
PsS2cLmeas_End:

PsSeqSongNoBoxProc:
	st_dri3b L, 0xfd, 0x00, 0xff
	push xiz
	ld xiz, xwa
	cp xbc, 0x1c0000c
	jr z, PsSeqSongNo_HandleScroll
	cp xbc, 0x1c0000b
	jr z, PsSeqSongNo_HandleScroll
	ld xwa, xiz
	call InheritedProc
	jr PsSeqSongNo_PopReturn

PsSeqSongNo_HandleScroll:
	ld xwa, xiz
	call InheritedProc
	ld8_24 a, 0x00ffe3
	inc 1, a
	extz wa
	pushw wa
	pushw 0xe1
	pushw 0xd58c
	lda xwa, (xsp + 10)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1c0000f
	call SendEvent
	lds32 xhl, 0

PsSeqSongNo_PopReturn:
	pop xiz
	st_dri3b L, 0xfd, 0x00, 0x01
	ret
PsSeqSongNo_End:

PsS2cTransBoxProc:
	st_dri3b L, 0xfd, 0xfc, 0xfe
	push xiz
	st_dri3l XWA, 0xfd, 0x04, 0x01
	cp xbc, 0x1c0000c
	jr z, PsS2cTrans_HandleScroll
	cp xbc, 0x1c0000b
	jr z, PsS2cTrans_HandleScroll
	ld_sril XWA, (xsp + 0x0104)
	call InheritedProc
	jr SndArg_GridBnk_Case2

PsS2cTrans_HandleScroll:
	ld_sril XWA, (xsp + 0x0104)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0104)
	call GetViewInstance
	ld xiz, xhl
	ldda8 a, 0x398e
	extz wa
	sla wa, 2
	lda_24 xbc, PtrTbl_TransposeStrs
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	lda xwa, (xsp + 8)
	push xwa
	call Sprintf_Locked
	inc 8, xsp
	lda xwa, (xiz + 22)
	lda xbc, (xiz + 32)
	cpdi8 0x3a77, 2
	jr nz, SndArg_GridBnk_Case0
	ldw (xbc), 0x0
	ldw (xwa), 0xff
	jr SndArg_GridBnk_Case1

; SndArgGridBnk case 0
SndArg_GridBnk_Case0:
	ldw (xbc), 0xff
	ldw (xwa), 0xf5

; SndArgGridBnk case 1
SndArg_GridBnk_Case1:
	ld_sril XWA, (xsp + 0x0104)
	ld xbc, 0x1c0000d
	lds32 xde, 0
	call SendEvent
	lda xde, (xsp + 4)
	ld_sril XWA, (xsp + 0x0104)
	ld xbc, 0x1c0000f
	call SendEvent
	lds32 xhl, 0

; SndArgGridBnk case 2
SndArg_GridBnk_Case2:
	pop xiz
	st_dri3b L, 0xfd, 0x04, 0x01
	ret
; SndArgGridBnk case 3
SndArg_GridBnk_Case3:
S2cGridBoxProc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 12), xde
	ld xiz, xbc
	ld (xsp + 16), xwa
	ld xwa, xiz
	cp xiz, 0x1e40031
	jrl z, FdcFormat_GridCheck_Case3
	cp xiz, 0x1e0008d
	jrl z, FdcFormat_GridCheck_Case2
	cp xiz, 0x1e0008b
	jrl z, FdcFormat_GridCheck_Case1
	cp xiz, 0x1e0008a
	jrl z, FdcFormat_GridCheck
	cp xiz, 0x1c00001
	jr z, FdcFormat_DialGrid
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, FdcFormat_GridCheck_Case4
	cp xwa, 0x6
	jrl gt, FdcFormat_GridCheck_Case4
	add xwa, xwa
	add xwa, StrTranspose_Minus25_0x4
	ld wa, (xwa)
	lda_24 xix, FdcFormat_DialGrid
	jp_dri 8, 0x07, 0xf0, 0xe0

; FdcFormat dial grid dispatch (7-entry, table 0xe1d728)
FdcFormat_DialGrid:
	ld xwa, (xsp + 16)
	ld xbc, xiz
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld (xsp + 8), xhl
	cpdi8 0x3a77, 3
	jrl nz, FdcFormat_ReturnZeroJmp
	ld xwa, (xsp + 16)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld (xsp + 4), xhl
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldi_werp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00017
	call SetDialUp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldi_werp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00018
	call SetDialDown
	lds wa, 1
	jrl S2cGrid_SetDialEnable
	ld xwa, (xsp + 16)
	ld xbc, xiz
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, (xsp + 16)
	ld xbc, 0x1e00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, S2cGrid_DialDownSendApply
	ld xwa, (xsp + 16)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	dec 1, hl
	extz xhl
	add xhl, 0xffff0000
	ld xwa, (xsp + 16)
	ld xbc, 0x1c0000e
	ld xde, xhl
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00019
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl FdcFormat_ReturnZeroJmp

S2cGrid_DialDownSendApply:
	ld xwa, (xsp + 16)
	ld xbc, 0x1e00091
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jrl z, FdcFormat_ReturnZeroJmp
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, xiz
	ld xde, (xsp + 12)
	call ApFuncCall
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00019
	ld xde, (xsp + 12)
	call SetAutoInc
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00018
	ld xde, (xsp + 12)
	call SetDialDown
	lds wa, 1
	jrl S2cGrid_SetDialEnable
	ld xwa, (xsp + 16)
	ld xbc, xiz
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, (xsp + 16)
	ld xbc, 0x1e00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, S2cGrid_DialUpSendApply
	ld xwa, (xsp + 16)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	inc 1, hl
	extz xhl
	add xhl, 0xffff0000
	ld xwa, (xsp + 16)
	ld xbc, 0x1c0000e
	ld xde, xhl
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, 0x1c0001a
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl FdcFormat_ReturnZeroJmp

S2cGrid_DialUpSendApply:
	ld xwa, (xsp + 16)
	ld xbc, 0x1e00091
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jrl z, FdcFormat_ReturnZeroJmp
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, xiz
	ld xde, (xsp + 12)
	call ApFuncCall
	ld xwa, (xsp + 16)
	ld xbc, 0x1c0001a
	ld xde, (xsp + 12)
	call SetAutoInc
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00018
	ld xde, (xsp + 12)
	call SetDialDown
	lds wa, 1

S2cGrid_SetDialEnable:
	call SetDialEnable
	jr FdcFormat_ReturnZeroJmp

; FdcFormat grid check dispatch
FdcFormat_GridCheck:
	ld xwa, (xsp + 16)
	ld xiz, 0x3e
	jr S2cGrid_GetViewAndCopy

; FdcFormat grid check case 1
FdcFormat_GridCheck_Case1:
	ld xwa, (xsp + 16)
	ld xiz, 0x42

S2cGrid_GetViewAndCopy:
	call GetViewInstance
	add xhl, xiz
	ld xwa, (xhl)
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	jr FdcFormat_ReturnZeroJmp

; FdcFormat grid check case 2
FdcFormat_GridCheck_Case2:
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, xiz
	ld xde, (xsp + 12)
	call ApFuncCall
	jr FdcFormat_ReturnZeroJmp

; FdcFormat grid check case 3
FdcFormat_GridCheck_Case3:
	call GetFocusObject
	ld xwa, xhl
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld (xsp + 12), xhl
	ld xwa, (xsp + 16)
	ld xbc, 0x1e0008d
	ld xde, (xsp + 12)
	call SendEvent

FdcFormat_ReturnZeroJmp:
	lds32 xhl, 0
	jr FdcFormat_GridCheck_Case5

; FdcFormat grid check case 4
FdcFormat_GridCheck_Case4:
	ld xwa, (xsp + 16)
	ld xbc, xiz
	ld xde, (xsp + 12)
	call InheritedProc

; FdcFormat grid check case 5
FdcFormat_GridCheck_Case5:
	pop xiz
	lda xsp, (xsp + 16)
	ret

