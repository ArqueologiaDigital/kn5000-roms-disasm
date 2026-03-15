; ToneGen_ParamTable: Tone generator parameter table
; Total: 1389 bytes
; Source: e0e407_e0e973.bin
; Format: Raw data (structure not yet fully decoded)

	.byte 0xf0, 0x00, 0xc3, 0xc5, 0xf0, 0x00
	pushw	de
	.byte 0xc6, 0xf0, 0x00, 0x4a
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	.byte 0xc2, 0xc6, 0xf0, 0x00, 0x4a
	jr	ugt, -16
	nop
	nop
	nop
	nop
	nop
	.byte 0xbf, 0xc7, 0xf0
	nop
	ldf	200
	.byte 0xf0, 0x00, 0x8b
	cp	w, w
	nop
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	add	xiz, 3379429616
	.byte 0xf0, 0x00, 0xd6
	cp	w, a
	nop
	ld	xiy, 1308684490
	cp	w, b
	nop
	pop	xiz
	cp	w, b
	nop
	jr	nz, -54
	.byte 0xf0, 0x00, 0x7e
	cp	w, b
	nop
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	.byte 0x9a, 0xca, 0xf0
	nop
	.byte 0x8e, 0xca, 0xf0
	nop
	nop
	nop
	nop
	nop
	popw	de
	jr	ugt, -16
	nop
	.byte 0xac, 0xca, 0xf0
	nop
	popw	de
	jr	ugt, -16
	nop
	.byte 0xad, 0xcb, 0xf0
	nop
	popw	de
	jr	ugt, -16
	nop
	ccf
	cp	w, d
	nop
	and	d, 240
	nop
	popw	de
	jr	ugt, -16
	nop
	ex_ff
	cp	w, e
	nop
	.byte 0x1f
	cp	w, e
	nop
	.byte 0x2f
	cp	w, e
	nop
	push	xsp
	cp	w, e
	nop
	.byte 0x4f
	cp	w, e
	nop
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	jr	pl, -51
	.byte 0xf0, 0x00, 0x5f
	cp	w, e
	nop
	nop
	nop
	nop
	nop
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	and	(xbc), e
	.byte 0xf0, 0x00, 0xeb
	cp	w, e
	nop
	jr	z, -50
	.byte 0xf0, 0x00, 0xe1
	cp	w, h
	nop
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	popw	hl
	cp	w, l
	nop
	.byte 0x54
	cp	w, l
	nop
	jr	po, 16777167
	.byte 0xf0, 0x00, 0x8b
	cp	w, l
	nop
	and	(xhl), xsp
	.byte 0xf0, 0x00, 0x4a
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	.byte 0xbb, 0xcf, 0xf0
	nop
	popw	de
	jr	ugt, -16
	nop
	nop
	nop
	nop
	nop
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	cp	l, 240
	nop
	ld	xwa, 3204509904
	.byte 0xd0, 0xf0, 0x00
	push	xiz
	.byte 0xd1, 0xf0, 0x00, 0x4a
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	.byte 0xaf, 0xd1, 0xf0
	nop
	.byte 0xb8, 0xd1, 0xf0
	nop
	.byte 0xd7, 0xd1, 0xf0
	nop
	xor	xbc, xsp
	.byte 0xf0, 0x00, 0x07
	decdi16_24	3, 4849904
	.byte 0xf0, 0x00, 0x4a
	jr	ugt, -16
	nop
	.byte 0x1f
	decdi16_24	3, 4849904
	.byte 0xf0, 0x00, 0x00, 0x00
	nop
	nop
	popw	de
	jr	ugt, -16
	nop
	xor	de, (xsp)
	.byte 0xf0, 0x00, 0x1c, 0xd3, 0xf0, 0x00
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	xor	hl, (xde)
	.byte 0xf0, 0x00, 0x4a
	jr	ugt, -16
	nop
	ldw	hl, 61650
	nop
	pushw	ix
	.byte 0xd6, 0xf0, 0x00, 0x35, 0xd6, 0xf0, 0x00, 0x4d, 0xd6, 0xf0, 0x00, 0x65, 0xd6, 0xf0, 0x00, 0x91, 0xd6, 0xf0, 0x00, 0x4a
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	.byte 0xe6, 0xd6, 0xf0, 0x00, 0xbd, 0xd6, 0xf0, 0x00, 0x00, 0x00
	nop
	nop
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	scf
	cp	wa, wa
	nop
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	ret
	cp	wa, de
	nop
	ldb	b, 218
	.byte 0xf0, 0x00, 0x5c
	cp	wa, de
	nop
	xor	(xiz), de
	.byte 0xf0, 0x00, 0xd0
	cp	wa, de
	nop
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	pushw 61659
	nop
	popw	de
	jr	ugt, -16
	nop
	nop
	nop
	nop
	nop
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	.byte 0x8e, 0xe0, 0xf0
	nop
	popw	de
	jr	ugt, -16
	nop
	.byte 0xc3, 0xe0, 0xf0
	nop
	ldw	iz, 61665
	nop
	.byte 0xa9, 0xe1, 0xf0
	nop
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	.byte 0xb7, 0xe1, 0xf0, 0x00, 0x4a
	jr	ugt, -16
	nop
	nop
	nop
	nop
	nop
	or	a, c
	.byte 0xf0, 0x00, 0xce, 0xe1, 0xf0, 0x00, 0xd1, 0xe1, 0xf0, 0x00, 0xd4, 0xe1, 0xf0, 0x00, 0xd7, 0xe1, 0xf0, 0x00, 0xda, 0xe1, 0xf0, 0x00, 0xdd, 0xe1, 0xf0, 0x00, 0xee
	cpda32	xbc, 240
	.byte 0xe1, 0xf0, 0x00, 0x57, 0xe2, 0xf0, 0x00, 0x4a, 0x6b, 0xf0, 0x00, 0x4a
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	pop	xiz
	.byte 0xe2, 0xf0, 0x00, 0x4a, 0x6b, 0xf0, 0x00, 0x00, 0x00
	nop
	nop
	pop_f
	cp	wa, hl
	nop
	xor	(xwa), xhl
	.byte 0xf0, 0x00, 0x35
	cp	wa, ix
	nop
	.byte 0xe0, 0xdc, 0xf0
	nop
	jrl	ule, -3875
	nop
	nop
	cp	wa, iz
	nop
	jr	pe, 16777182
	.byte 0xf0, 0x00, 0xd3
	cp	wa, iz
	nop
	popw	de
	jr	ugt, -16
	nop
	push	xhl
	.byte 0xdf, 0xf0
	nop
	normal
	.byte 0xe0, 0xf0, 0x00
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	or	w, (xwa)
	.byte 0xf0, 0x00, 0x4a
	jr	ugt, -16
	nop
	nop
	nop
	nop
	nop
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	.byte 0xe4, 0xe8, 0xf0
	nop
	swi	0
	cp	xwa, xwa
	nop
	popw	de
	jr	ugt, -16
	nop
	incf
	cp	xwa, xbc
	nop
	popw	de
	jr	ugt, -16
	nop
	popw	de
	jr	ugt, -16
	nop
	ldb	w, 233
	.byte 0xf0, 0x00, 0x4a
	jr	ugt, -16
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	pushw	bc
	nop
	pushw	bc
	nop
	ldw	bc, 10496
	nop
	push	xbc
	nop
	ld	xiy, 687876352
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	pushw	bc
	nop
	nop
	nop
	pushw	bc
	nop
	ldw	bc, 0
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	pushw	bc
	nop
	pushw	bc
	nop
	jr	le, -95
	.byte 0xf0, 0x00, 0xa5
	cp	xwa, (xiz)
	nop
	sbc	hl, iy
	.byte 0xf0, 0x00, 0x54, 0xb5, 0xf0
	nop
	ldw	wa, 61622
	nop
	retd	0xf0b7
	nop
	sbc	xsp, xiz
	.byte 0xf0, 0x00, 0x86
	cp	xwa, (xsp)
	nop
	.byte 0x9b, 0xa8, 0xf0
	nop
	ldw	bc, 61609
	nop
	lds	hl, 1
	.byte 0xf0, 0x00, 0xe3, 0xaa, 0xf0, 0x00
	ldw	hl, 61612
	nop
	.byte 0xd4, 0xac, 0xf0
	nop
	.byte 0xd0, 0xad, 0xf0
	nop
	jrl	ugt, -3922
	nop
	.byte 0x4f
	ret	f
	nop
	.byte 0x8b, 0xb1, 0xf0
	nop
	sbc	xbc, (xiz)
	.byte 0xf0, 0x00, 0xbd, 0xb1, 0xf0
	nop
	.byte 0xd4, 0xb1, 0xf0
	nop
	.byte 0xe7, 0xb1, 0xf0
	nop
	.byte 0xf6, 0xb1, 0xf0
	nop
	sbc	de, (xsp)
	.byte 0xf0, 0x00, 0x2d, 0xb3, 0xf0
	nop
	.byte 0xd7, 0xb3, 0xf0
	nop
	.byte 0xd8, 0xba, 0xf0, 0x00, 0x81, 0xae, 0xf0, 0x00
	pushw 61616
	nop
	jrl	pl, -3909
	nop
	.byte 0xc4, 0xb9, 0xf0
	nop
	.byte 0xbe, 0xba, 0xf0
	nop
	swi	7
	cp	xbc, (xsp+103)
	nop
	.byte 0xc0, 0x67, 0xf1
	nop
	.byte 0xd1, 0x67, 0xf1, 0x00
	cpda32_24	xhl, 61799
	jr	c, -15
	nop
	max
	jr	-15
	nop
	pop_a
	jr	-15
	nop
	ldb	h, 104
	.byte 0xf1, 0x00, 0x37, 0x68, 0xf1, 0x00, 0x48, 0x68, 0xf1, 0x00, 0x59, 0x68, 0xf1, 0x00, 0x6a, 0x68, 0xf1, 0x00, 0x7b, 0x68, 0xf1, 0x00, 0x8c, 0x68, 0xf1, 0x00, 0x9d, 0x68, 0xf1, 0x00, 0xae, 0x68, 0xf1, 0x00, 0xbf, 0x68, 0xf1, 0x00, 0xd0, 0x68
	stdi8	0, 0
	nop
	ldw	iz, 57577
	nop
	pushw	wa
	or	xwa, xbc
	nop
	jp16	57577
	nop
	incf
	or	xwa, xbc
	nop
	swi	6
	or	xwa, xwa
	nop
	.byte 0xf0, 0xe8, 0xe0
	nop
	.byte 0xe2, 0xe8, 0xe0, 0x00, 0xd4
	or	xwa, xwa
	nop
	.byte 0xc6
	or	xwa, xwa
	nop
	.byte 0xb8, 0xe8, 0xe0
	nop
	.byte 0xaa, 0xe8, 0xe0
	nop
	.byte 0x9c, 0xe8, 0xe0
	nop
	.byte 0x8e, 0xe8, 0xe0
	nop
	or	(xwa), w
	.byte 0xe0, 0x00, 0x72
	or	xwa, xwa
	nop
	jr	pe, 16777192
	.byte 0xe0, 0x00, 0x56
	or	xwa, xwa
	nop
	popw	wa
	or	xwa, xwa
	nop
	ld	xiz, 57576
	swi	7
	ld	xiz, 1851870324
	jr	c, 84
	jr	mi, 120
	jrl	pe, 14129
	nop
	swi	7
	ld	xiz, 1851870324
	jr	c, 84
	jr	mi, 120
	jrl	pe, 13873
	nop
	swi	7
	ld	xiz, 1851870324
	jr	c, 84
	jr	mi, 120
	jrl	pe, 13617
	nop
	swi	7
	ld	xiz, 1851870324
	jr	c, 84
	jr	mi, 120
	jrl	pe, 13361
	nop
	swi	7
	ld	xiz, 1851870324
	jr	c, 84
	jr	mi, 120
	jrl	pe, 13105
	nop
	swi	7
	ld	xiz, 1851870324
	jr	c, 84
	jr	mi, 120
	jrl	pe, 12849
	nop
	swi	7
	ld	xiz, 1851870324
	jr	c, 84
	jr	mi, 120
	jrl	pe, 12593
	nop
	swi	7
	ld	xiz, 1851870324
	jr	c, 84
	jr	mi, 120
	jrl	pe, 12337
	nop
	swi	7
	ld	xiz, 1851870324
	jr	c, 84
	jr	mi, 120
	jrl	pe, 14640
	nop
	swi	7
	ld	xiz, 1851870324
	jr	c, 84
	jr	mi, 120
	jrl	pe, 14384
	nop
	swi	7
	ld	xiz, 1851870324
	jr	c, 84
	jr	mi, 120
	jrl	pe, 14128
	nop
	swi	7
	ld	xiz, 1851870324
	jr	c, 84
	jr	mi, 120
	jrl	pe, 13872
	nop
	swi	7
	ld	xiz, 1851870324
	jr	c, 84
	jr	mi, 120
	jrl	pe, 13616
	nop
	swi	7
	ld	xiz, 1851870324
	jr	c, 84
	jr	mi, 120
	jrl	pe, 13360
	nop
	swi	7
	ld	xiz, 1851870324
	jr	c, 84
	jr	mi, 120
	jrl	pe, 13104
	nop
	swi	7
	ld	xiz, 1851870324
	jr	c, 84
	jr	mi, 120
	jrl	pe, 12848
	nop
	swi	7
	ld	xiz, 1851870324
	jr	c, 84
	jr	mi, 120
	jrl	pe, 12592
	.byte 0x53
	nop
	ld	xiz, 1851870324
	jr	c, 84
	jr	mi, 120
	jrl	pe, 12592
	nop
	swi	7
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	jrl	le, -7959
	nop
	nop
	swi	7
