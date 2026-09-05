; =============================================================================
; Audio Control Engine
; =============================================================================
;
; MIDI stream processing, control panel LED management, voice/tone
; parameter control, and sound preset dispatch. This is the main
; bridge between the UI layer and the SubCPU audio engine.
; =============================================================================

	ld a, e
	and a, 0xf
	jr z, FileIO_ShiftD
	srla d

FileIO_ShiftD:
	ld a, e
	and a, 0xf
	jr z, FileIO_CallbackHandler
	srla l

; File I/O callback handler
FileIO_CallbackHandler:
	cp l, 0:i3
	jr z, FileIO_AdvancePointer
	ld a, (xiz + 1)
	ld (xbc + 1), a
	ld (xbc + 2), d
	ld (xbc + 3), l
	ld xhl, (xiz + 4)
	ld xwa, xbc
	call (xhl)

FileIO_AdvancePointer:
	inc 8, xiz

FileIO_MainLoop:
	lda xbc, (0x8e7c:16)
	ld a, (xiz)
	ld (xbc), a
	cp a, 0xff
	jr nz, FileIO_ProcessMaskAndShift
	pop xiz
	ret

FileIO_BytecodeData:
	.byte 0x80, 0x3f, 0xff
	ret	z
	ld	c, (36494:16)
	cp	c, 15
	jr	ugt, 31
	ld	e, c
	inc	1, c
	ld	(36494:16), c
	ld	c, e
	extz	bc
	sll	bc, 2
	lda	xde, (49209:16)
	ld	ix, bc
	extz	xix
	add	xix, xde
	ld	xiy, xwa
	.byte 0x95, 0x10, 0x95, 0x10
	ld	(xwa), 255
	ret
	push	xiz
	ld	xiz, xwa
	cp	(36148:16), 19
	jr	z, 17
	ld	xwa, xiz
	calr	2716
	ld	xwa, xiz
	calr	-69
	inc	4, xiz
	ld	xwa, xiz
	calr	-76
	pop	xiz
	ret
	push	xiz
	ld	xiz, xwa
	cp	(36148:16), 19
	jr	z, 30
	ld	xwa, 192
	call	16569399
	cp	hl, 1:i3
	jr	z, 17
	ld	xwa, xiz
	calr	2674
	ld	xwa, xiz
	calr	-111
	inc	4, xiz
	ld	xwa, xiz
	calr	-118
	pop	xiz
	ret
	push	xiz
	ld	xiz, xwa
	ld	a, (36148:16)
	cp	a, 14
	jr	z, 18
	cp	a, 19
	jr	z, 13
	ld	xwa, 192
	call	16569399
	cp	hl, 1:i3
	jr	nz, 2
	jr	17
	ld	xwa, xiz
	calr	2623
	ld	xwa, xiz
	calr	-162
	inc	4, xiz
	ld	xwa, xiz
	calr	-169
	pop	xiz
	ret
	push	xiz
	ld	xiz, xwa
	ld	xwa, xiz
	calr	-179
	inc	4, xiz
	ld	xwa, xiz
	calr	-186
	pop	xiz
	ret
	push	xiz
	ld	xiz, xwa
	lda	xbc, (xiz+2)
	ld	a, (xbc)
	cp	a, 0:i3
	jr	nz, 21
	ld	(xbc), 0
	ld	(xiz+3), 255
	ld	xwa, xiz
	calr	119
	.byte 0x86, 0x3f, 0xff
	jr	nz, 100
	ld	xwa, xiz
	jr	105
	ldb	w, 0
	extz	xwa
	call	16546867
	lda	xde, (xiz+2)
	ld	(xde), l
	ld	a, (36496:16)
	extz	hl
	cp	a, 21
	jr	z, 58
	cp	a, 16
	jr	z, 46
	cp	a, 15
	jr	z, 34
	cp	a, 10
	jr	z, 22
	cp	a, 3:i3
	jr	z, 11
	cp	a, 1:i3
	.ascii "n=@.í"
	nop
	jr	33
	ld	xwa, 15572272
	jr	26
	ld	xwa, 15572274
	jr	19
	ld	xwa, 15572276
	jr	12
	ld	xwa, 15572278
	jr	5
	ld	xwa, 15572280
	ld_rrb	a, xwa, hl
	ld	(xde), a
	jr	-114
	ld	xwa, xiz
	calr	-322
	inc	4, xiz
	ld	xwa, xiz
	calr	-329
	pop	xiz
	ret
	push	xiz
	ld	xiz, xwa
	cp	(36148:16), 19
	jr	nz, 15
	ld	a, (xiz+2)
	cp	a, 19
	jr	z, 7
	cp	a, 0:i3
	jr	z, 3
	ld	(xiz), 255
	ld	xwa, 192
	call	16569399
	cp	hl, 1:i3
	jr	nz, 31
	ld	a, (xiz+2)
	cp	a, 15
	jr	z, 20
	cp	a, 17
	jr	z, 15
	cp	a, 19
	jr	z, 10
	cp	a, 9
	jr	z, 5
	cp	a, 14
	jr	nz, 3
	ld	(xiz), 255
	call	16695162
	and	hl, 7
	jr	z, 9
	.byte 0x8e, 0x02, 0x3f, 0x07
	jr	nz, 3
	ld	(xiz), 255
	lda	xwa, (xiz+2)
	.byte 0x80, 0x3f, 0x09
	jr	nz, 12
	cp	(9980:16), 1
	jr	nz, 5
	ld	(xwa), 8
	jr	5
	.byte 0x80, 0x3f, 0x08
	jr	nz, 9
	.byte 0xf1, 0x6a, 0x26, 0xc8
	jr	z, 3
	ld	(xwa), 10
	cpw	(10408:16), 0
	jr	z, 17
	ld	a, (xwa)
	cp	a, 19
	jr	z, 5
	cp	a, 20
	jr	nz, 5
	ld	(xiz), 255
	jr	4
	.byte 0xf1, 0x6a, 0x26, 0xb0
	pop	xiz
	ret
	push	xiz
	ld	xiz, xwa
	lda	xbc, (xiz+2)
	ld	a, (xbc)
	cp	a, 0:i3
	jr	z, 122
	ld	a, (36148:16)
	cp	a, 19
	jr	z, 113
	.byte 0xf1, 0x21, 0x04, 0xca
	jr	nz, 81
	ld	a, (10405:16)
	xor	a, 1
	ld	(10405:16), a
	ld	c, (36148:16)
	cp	c, 13
	jr	ugt, 36
	cp	c, 8
	jr	c, 31
	ld	xwa, xiz
	calr 64995
	ld (xiz), 169
	ld	(xiz+1), 32
	ld	(xiz+2), 10
	ld	(xiz+3), 255
	ld	xwa, xiz
	calr	-561
	inc	4, xiz
	ld	xwa, xiz
	jr	48
	bit	0, a
	jr	nz, -36
	cp	c, 14
	jr	z, -41
	call	16004700
	ld	xwa, xiz
	calr	-586
	inc	4, xiz
	ld	xwa, xiz
	jr	23
	ld	(xiz), 169
	ld	(xiz+1), 32
	ld	(xbc), 10
	ld	(xiz+3), 255
	ld	xwa, xiz
	calr	-611
	inc	4, xiz
	ld	xwa, xiz
	calr	-618
	pop	xiz
	ret
	push	xiz
	ld	xiz, xwa
	ld	a, (xiz+1)
	cp	a, 14
	jr	nz, 7
	cp	(36148:16), 19
	jr	z, 53
	extz	wa
	call	16546851
	lda	xbc, (xiz+2)
	.byte 0x81, 0x3f, 0x00
	jr	z, 6
	.byte 0xe1, 0x84, 0x8e, 0xeb
	jr	11
	ld	xwa, xhl
	cpl	wa
	cpl	qwa
	.byte 0xe1, 0x84, 0x8e, 0xc8
	ld	xwa, (36488:16)
	and	xwa, xhl
	jr	z, 2
	.byte 0xb1, 0xb9
	ld	xwa, xiz
	calr	-684
	inc	4, xiz
	ld	xwa, xiz
	calr	-691
	pop	xiz
	ret
	push	xiz
	ld	xiz, xwa
	ld	a, (xiz+1)
	cp	a, 14
	jr	nz, 7
	cp	(36148:16), 19
	jr	z, 53
	extz	wa
	call	16546851
	lda	xbc, (xiz+2)
	.byte 0x81, 0x3f, 0x00
	jr	z, 6
	.byte 0xe1, 0x88, 0x8e, 0xeb
	jr	11
	ld	xwa, xhl
	cpl	wa
	cpl	qwa
	.byte 0xe1, 0x88, 0x8e, 0xc8
	ld	xwa, (36484:16)
	and	xwa, xhl
	jr	z, 2
	.byte 0xb1, 0xb8
	ld	xwa, xiz
	calr	-757
	inc	4, xiz
	ld	xwa, xiz
	calr	-764
	pop	xiz
	ret
	push	xiz
	ld	xiz, xwa
	cp	(36148:16), 19
	jr	nz, 7
	ld	(xiz), 168
	ld	(xiz+1), 1
	ld	xwa, xiz
	calr	-788
	inc	4, xiz
	ld	xwa, xiz
	calr	-795
	pop	xiz
	ret
	push	xiz
	ld	xiz, xwa
	ld	a, (36148:16)
	cp	a, 16
	jr	z, 17
	cp	a, 19
	jr	z, 12
	ld	xwa, xiz
	calr	-819
	inc	4, xiz
	ld	xwa, xiz
	calr	-826
	pop	xiz
	ret
	dec	4, xsp
	push	qiz
	ld	(xsp+2), xwa
	ld	xwa, (xsp+2)
	ld	c, (xwa+2)
	cp	c, 0:i3
	jrl	z, 265
	ld	a, (36148:16)
	cp	a, 14
	jr	z, 12
	cp	a, 3:i3
	jr	z, 5
	cp	a, 19
	jr	nz, 14
	jrl	244
	ld	a, (14235:24)
	and	a, 31
	jrl	z, 233
	ldb	b, 0
	extz	xbc
	ld	xwa, xbc
	call	16546867
	ld	xwa, (xsp+2)
	lda	xde, (xwa+2)
	ld	(xde), l
	ld	a, (36496:16)
	extz	hl
	cp	a, 20
	jr	z, 38
	cp	a, 13
	jr	z, 26
	cp	a, 12
	jrl	nz, 193
	ld	xwa, 15572284
	ld_rrb	a, xwa, hl
	ld	(xde), a
	cp	a, 17
	jr	ule, 17
	jrl	173
	ld	xwa, 15572292
	jr	-22
	ld	xwa, 15572300
	jr	-29
	extz	wa
	call	16704679
	cp	l, 255
	jrl	z, 147
	call	16356446
	ldb_erp	l, 251
	ld	xwa, (xsp+2)
	inc	2, xwa
	cpib_erp	251, 2
	jr	ule, 5
	.byte 0x80, 0x3f, 0x0c
	jr	z, 125
	cp_erpb	251, 15
	jr	z, 6
	cp_erpb	251, 20
	jr	nz, 5
	.byte 0x80, 0x3f, 0x0f
	jr	nz, 108
	cp_erpb	251, 16
	jr	c, 15
	cp_erpb	251, 19
	jr	ugt, 9
	ld	xwa, (xsp+2)
	.byte 0x88, 0x02, 0x3f, 0x0f
	jr	z, 87
	ld	xwa, 192
	call	16569399
	cp	hl, 1:i3
	jr	nz, 29
	ld	xwa, (xsp+2)
	ld	a, (xwa+2)
	cp	a, 17
	jr	z, 5
	cp	a, 16
	jr	nz, 2
	jr	56
	cp_erpb	251, 14
	jr	ugt, 5
	cp	a, 15
	jr	z, 45
	ld	xwa, (xsp+2)
	calr	1707
	ld	xbc, (xsp+2)
	ld	a, (xbc)
	extz	wa
	ld	c, (xbc+2)
	extz	bc
	call	16555329
	ld	xwa, (xsp+2)
	ld	(xwa+3), l
	ld	xwa, (xsp+2)
	calr	-1101
	lds32	xwa, 4
	add	(xsp+2), xwa
	ld	xwa, (xsp+2)
	calr	-1112
	pop	qiz
	inc	4, xsp
	ret
	push	xiz
	ld	xiz, xwa
	ld	c, (xiz+2)
	cp	c, 0:i3
	jrl	z, 153
	ld	a, (36148:16)
	cp	a, 19
	jrl	z, 143
	.byte 0xf1, 0xd3, 0x33, 0xc8
	jrl	nz, 136
	cp	a, 14
	jr	nz, 27
	ld	a, (36150:16)
	cp	a, 184
	jr	z, 18
	cp	a, 180
	jr	nz, 117
	.byte 0xf1, 0xd3, 0x34, 0xc8
	jr	nz, 111
	cp	(13526:16), 12
	jr	nc, 104
	ldb	b, 0
	extz	xbc
	ld	xwa, xbc
	call	16546867
	lda	xde, (xiz+2)
	ld	(xde), l
	ld	a, (36496:16)
	extz	hl
	cp	a, 6:i3
	jr	z, 36
	cp	a, 1:i3
	jr	z, 25
	cp	a, 0:i3
	jr	nz, 71
	ld	xwa, 15572302
	ld_rrb	a, xwa, hl
	ld	(xde), a
	ld	c, a
	cp	c, 15
	jr	ule, 16
	jr	50
	ld	xwa, 15572310
	jr	-23
	ld	xwa, 15572312
	jr	-30
	cp	(36150:16), 184
	jr	nz, 5
	cp	c, 14
	jr	z, 24
	extz	bc
	ldw	wa, 72
	call	16555329
	ld	(xiz+3), l
	ld	xwa, xiz
	calr	-1275
	inc	4, xiz
	ld	xwa, xiz
	calr	-1282
	pop	xiz
	ret
	dec	2, xsp
	push	xiz
	ld	xiz, xwa
	ld	a, (36148:16)
	cp	a, 16
	jr	z, 24
	cp	a, 15
	jr	z, 19
	cp	a, 14
	jr	z, 14
	cp	a, 17
	jr	z, 9
	cp	a, 3:i3
	jr	z, 5
	cp	a, 19
	jr	nz, 2
	jr	78
	ld	a, (36152:16)
	cp	a, 211
	jr	z, 18
	cp	a, 210
	jr	z, 13
	ld	xwa, 192
	call	16569399
	cp	hl, 1:i3
	jr	nz, 2
	jr	49
	.byte 0x8e, 0x02, 0x3f, 0x00
	jr	z, 36
	call	16474137
	sll	l, 3
	ld	(xsp+4), l
	lds32	xwa, 0
	ld	a, (xiz+2)
	call	16546867
	inc	1, l
	.byte 0x8f, 0x04, 0x87
	ld	(xiz+2), l
	ld	(xiz+3), 127
	ld	xwa, xiz
	calr	-1395
	inc	4, xiz
	ld	xwa, xiz
	calr	-1402
	pop	xiz
	inc	2, xsp
	ret
	push	xiz
	ld	xiz, xwa
	.byte 0x8e, 0x02, 0x3f, 0x00
	jr	z, 76
	ld	a, (36148:16)
	cp	a, 16
	jr	z, 24
	cp	a, 15
	jr	z, 19
	cp	a, 14
	jr	z, 14
	cp	a, 17
	jr	z, 9
	cp	a, 3:i3
	jr	z, 5
	cp	a, 19
	jr	nz, 2
	jr	41
	ld	a, (36152:16)
	cp	a, 211
	jr	z, 18
	cp	a, 210
	jr	z, 13
	ld	xwa, 192
	call	16569399
	cp	hl, 1:i3
	jr	nz, 2
	jr	12
	ld	xwa, xiz
	calr	-1484
	inc	4, xiz
	ld	xwa, xiz
	calr	-1491
	pop	xiz
	ret
	push	xiz
	ld	xiz, xwa
	cp	(36148:16), 19
	jr	z, 12
	ld	xwa, xiz
	calr	-1508
	inc	4, xiz
	ld	xwa, xiz
	calr	-1515
	pop	xiz
	ret
	push	xiz
	ld	xiz, xwa
	cp	(36148:16), 19
	jr	z, 47
	ld	xwa, xiz
	calr	-1532
	ld	(xiz), 168
	ld	(xiz+1), 5
	lda	xbc, (xiz+2)
	lda	xde, (xiz+3)
	ld	a, (xde)
	.byte 0x81, 0xc1
	jr	z, 5
	ld	(xbc), 64
	jr	3
	ld	(xbc), 0
	ld	(xde), 64
	ld	xwa, xiz
	calr	-1567
	inc	4, xiz
	ld	xwa, xiz
	calr	-1574
	pop	xiz
	ret
	push	xiz
	ld	xiz, xwa
	.byte 0x8e, 0x02, 0x3f, 0x00
	jr	z, 75
	cp	(36148:16), 19
	jr	z, 68
	ld	xwa, 192
	call	16569399
	cp	hl, 1:i3
	jr	z, 55
	ld	xwa, xiz
	calr	-1610
	.byte 0xf1, 0x1e, 0x04, 0xca
	jr	z, 13
	ld	xwa, 163968
	call	16569399
	cp	hl, 0:i3
	jr	nz, 24
	ld	(xiz), 72
	ld	(xiz+1), 3
	ld	a, (65480:24)
	ld	(xiz+2), a
	ld	(xiz+3), 7
	ld	xwa, xiz
	calr	-1653
	inc	4, xiz
	ld	xwa, xiz
	calr	-1660
	pop	xiz
	ret
	push	xiz
	ld	xiz, xwa
	ld	a, (xiz+2)
	cp	a, 0:i3
	jr	z, 86
	ld	c, (36148:16)
	cp	c, 16
	jr	z, 26
	cp	c, 15
	jr	z, 21
	cp	c, 14
	jr	z, 16
	cp	c, 3:i3
	jr	z, 12
	cp	c, 19
	jr	z, 7
	cp	(36150:16), 81
	jr	nz, 2
	jr	49
	.byte 0xf1, 0xe2, 0x26, 0xc8
	jr	nz, 43
	ldb	w, 0
	extz	xwa
	call	16546867
	extz	hl
	lda	xbc, (15572320:24)
	ld_rrb	a, xbc, hl
	ld	(xiz+2), a
	ld	(36154:16), a
	ld	(xiz+3), 255
	ld	xwa, xiz
	calr	-1751
	inc	4, xiz
	ld	xwa, xiz
	calr	-1758
	pop	xiz
	ret
	push	xiz
	ld	xiz, xwa
	ld	a, (36148:16)
	cp	a, 16
	jr	z, 31
	cp	a, 15
	jr	z, 26
	cp	a, 14
	jr	z, 21
	cp	a, 3:i3
	jr	z, 17
	cp	a, 19
	jr	z, 12
	ld	xwa, xiz
	calr	-1796
	inc	4, xiz
	ld	xwa, xiz
	calr	-1803
	pop	xiz
	ret
	push	xiz
	ld	xiz, xwa
	cp	(36148:16), 19
	jr	z, 30
	calr	978
	.byte 0x83, 0x3f, 0x0f
	jr	z, 22
	.byte 0x83, 0x3f, 0x0c
	jr	z, 17
	ld	xwa, xiz
	calr	947
	ld	xwa, xiz
	calr	-1838
	inc	4, xiz
	ld	xwa, xiz
	calr	-1845
	pop	xiz
	ret
	push	xiz
	ld	xiz, xwa
	ld	a, (36148:16)
	cp	a, 17
	jr	z, 19
	cp	a, 14
	jr	z, 14
	cp	a, 19
	jr	z, 9
	ld	a, (36154:16)
	cp	a, 15
	jr	ule, 2
	jr	96
	lda	xbc, (xiz+2)
	ld	a, (xbc)
	cp	a, 0:i3
	jr	z, 59
	.byte 0xf1, 0x92, 0x8e, 0xbd
	ld	a, (36154:16)
	extz	wa
	ldw	bc, 93
	call	16569591
	and	hl, 127
	lda	xde, (xiz+3)
	lda	xbc, (xiz+2)
	cp	hl, 0:i3
	jr	z, 5
	ld	(xbc), 0
	jr	18
	ld	a, (36154:16)
	extz	wa
	lda	xhl, (37261:16)
	extz	xwa
	add	xwa, xhl
	ld	a, (xwa)
	ld	(xbc), a
	ld	(xde), 127
	jr	11
	.byte 0xf1, 0x92, 0x8e, 0xb5
	ld	(xbc), 0
	ld	(xiz+3), 0
	ld	xwa, xiz
	calr	816
	ld	xwa, xiz
	calr	-1969
	inc	4, xiz
	ld	xwa, xiz
	calr	-1976
	pop	xiz
	ret
	push	xiz
	ld	xiz, xwa
	ld	a, (36148:16)
	cp	a, 17
	jr	z, 17
	cp	a, 19
	jr	z, 12
	ld	xwa, xiz
	calr	-2000
	inc	4, xiz
	ld	xwa, xiz
	calr	-2007
	pop	xiz
	ret
	push	xiz
	ld	xiz, xwa
	.byte 0xf1, 0xcd, 0x34, 0xcb
	jr	nz, 45
	ld	a, (36148:16)
	cp	a, 17
	jr	z, 13
	cp	a, 19
	jr	z, 8
	calr	761
	.byte 0x83, 0x3f, 0x0f
	jr	nz, 2
	jr	21
	.byte 0xf1, 0xf9, 0x90, 0xb1
	ld	xwa, xiz
	calr	729
	ld	xwa, xiz
	calr	-2056
	inc	4, xiz
	ld	xwa, xiz
	calr	-2063
	pop	xiz
	ret
	push	xiz
	ld	xiz, xwa
	cp	(36148:16), 19
	jr	z, 35
	ld	xwa, 192
	call	16569399
	cp	hl, 1:i3
	jr	z, 22
	.byte 0x8e, 0x02, 0x3f, 0x00
	jr	z, 4
	.byte 0xf1, 0x52, 0x8d, 0xbb
	ld	xwa, xiz
	calr	-2103
	inc	4, xiz
	ld	xwa, xiz
	calr	-2110
	pop	xiz
	ret
	dec	4, xsp
	push	qiz
	ld	(xsp+2), xwa
	cp	(36148:16), 19
	jrl	z, 136
	ld	xwa, 192
	call	16569399
	cp	hl, 1:i3
	jr	z, 123
	ld	xwa, (xsp+2)
	ld	a, (xwa+3)
	extz	wa
	extz	xwa
	call	16546867
	ldb_erp	l, 251
	ld	xwa, 165888
	call	16569399
	stb_erp	c, 251
	extz	bc
	ld	wa, bc
	sla	wa, 2
	cp	hl, 18
	jr	z, 35
	cp	hl, 17
	jr	nz, 58
	lda	xde, (15572348:24)
	ld_rrb	c, xde, bc
	lda	xde, (15572324:24)
	lda_rr	xde, xde, wa
	ld	xwa, (xsp+2)
	ld	xhl, (xde)
	call	(xhl)
	jr	35
	lda	xde, (15572378:24)
	ld_rrb	c, xde, bc
	lda	xde, (15572354:24)
	lda_rr	xde, xde, wa
	ld	xwa, (xsp+2)
	ld	xhl, (xde)
	call	(xhl)
	jr	6
	ld	xwa, (xsp+2)
	calr	-2253
	lds32	xwa, 4
	add	(xsp+2), xwa
	ld	xwa, (xsp+2)
	calr	-2264
	pop	qiz
	inc	4, xsp
	ret
	lda	xsp, (xsp-10)
	push	qiz
	ld	(xsp+8), xwa
	ld	xwa, (xsp+8)
	ld	a, (xwa+2)
	ldb_erp	a, 251
	cpib_erp	251, 0
	jrl	z, 164
	ld	a, (36148:16)
	cp	a, 14
	jr	z, 95
	cp	a, 19
	jr	z, 90
	lds32	xwa, 0
	stb_erp	a, 251
	call	16546867
	ldb_erp	l, 251
	ld	(xsp+4), 72
	ld	xwa, 163840
	call	16569399
	ld	(xsp+5), l
	ld	xwa, 163841
	call	16569399
	lda	xwa, (xsp+2)
	ld	(xwa+4), l
	call	16554837
	lda	xhl, (xsp+2)
	ld	xwa, (xsp+8)
	lda	xbc, (xwa+2)
	lda	xde, (xwa+3)
	.byte 0x83, 0x3f, 0x0e
	jr	nc, 28
	stb_erp	a, 251
	extz	wa
	lda	xhl, (15572384:24)
	ld_rrb	a, xhl, wa
	ld	(xbc), a
	ld	(xde), 48
	.byte 0xf1, 0x52, 0x8d, 0xbb
	jr	43
	jr	58
	ld	xwa, (xsp+8)
	ld	(xwa+1), 0
	ld	a, (xhl)
	ld	(xbc), a
	ld	a, (xhl+1)
	srl	a, 2
	sll	a, 2
	addb_erp	a, 251
	ld	l, a
	ld	(xde), l
	ld	a, (xbc)
	extz	wa
	lda	xbc, (65426:16)
	extz	xwa
	add	xwa, xbc
	ld	(xwa), l
	ld	xwa, (xsp+8)
	calr	-2447
	lds32	xwa, 4
	add	(xsp+8), xwa
	ld	xwa, (xsp+8)
	calr	-2458
	pop	qiz
	lda	xsp, (xsp+10)
	ret
	push	xiz
	ld	xiz, xwa
	cp	(36148:16), 19
	jr	z, 18
	ld	xwa, 10374
	call	16569399
	extz	hl
	ld	xwa, xiz
	ld	bc, hl
	calr	393
	pop	xiz
	ret
	push	xiz
	ld	xiz, xwa
	cp	(36148:16), 19
	jr	z, 18
	ld	xwa, 10376
	call	16569399
	extz	hl
	ld	xwa, xiz
	ld	bc, hl
	calr	363
	pop	xiz
	ret
	push	xiz
	ld	xiz, xwa
	cp	(36148:16), 19
	jr	z, 18
	ld	xwa, 10378
	call	16569399
	extz	hl
	ld	xwa, xiz
	ld	bc, hl
	calr	333
	pop	xiz
	ret
	push	xiz
	ld	xiz, xwa
	cp	(36148:16), 19
	jr	z, 18
	ld	xwa, 10380
	call	16569399
	extz	hl
	ld	xwa, xiz
	ld	bc, hl
	calr	303
	pop	xiz
	ret
	push	xiz
	ld	xiz, xwa
	cp	(36148:16), 19
	jr	z, 18
	ld	xwa, 10382
	call	16569399
	extz	hl
	ld	xwa, xiz
	ld	bc, hl
	calr	273
	pop	xiz
	ret
	push	xiz
	ld	xiz, xwa
	cp	(36148:16), 19
	jr	z, 18
	ld	xwa, 10384
	call	16569399
	extz	hl
	ld	xwa, xiz
	ld	bc, hl
	calr	243
	pop	xiz
	ret
	cp	(36148:16), 19
	ret	z
	lda	xhl, (xwa+2)
	lda	xix, (xwa+3)
	ld	e, (xhl)
	cp	e, 255
	jr	nz, 8
	ld	(xhl), 127
	ld	(xix), 127
	jr	15
	ld	c, e
	and	c, 1
	sll	c, 6
	ld	(xhl), c
	srl	e, 1
	ld	(xix), e
	jrl	-2691
	push	xiz
	ld	xiz, xwa
	ld	xwa, 10368
	call	16569399
	cp	hl, 183
	jr	z, 10
	cp	hl, 182
	jr	nz, 23
	ld	xwa, xiz
	jr	16
	cp	(36148:16), 19
	jr	z, 12
	ld	(xiz), 179
	ld	(xiz+1), 0
	ld	xwa, xiz
	calr	-2738
	pop	xiz
	ret
	cp	(36148:16), 19
	ret	z
	jrl	-2750
	push	xiz
	ld	xiz, xwa
	cp	(36148:16), 19
	jr	z, 18
	ld	xwa, 260
	call	16569399
	cp	hl, 0:i3
	jr	z, 5
	ld	xwa, xiz
	calr	-2778
	pop	xiz
	ret
	.byte 0x80, 0x3f, 0x00
	ret	nz
	.byte 0x88, 0x01, 0x3f, 0x03
	ret	z
	.byte 0xb0, 0x14, 0x3a, 0x8d
	ret
	dec	6, xsp
	ld	a, (36154:16)
	extz	wa
	lds	bc, 0
	call	16569591
	ld	(xsp+3), l
	ld	a, (36154:16)
	extz	wa
	ldw	bc, 32
	call	16569591
	lda	xwa, (xsp)
	ld	(xwa+4), l
	.byte 0xb8, 0x02, 0x14, 0x3a, 0x8d
	call	16554837
	lda	xhl, (xsp)
	inc	6, xsp
	ret
	dec	6, xsp
	ld	xwa, 163840
	call	16569399
	ld	(xsp+3), l
	ld	xwa, 163841
	call	16569399
	lda	xwa, (xsp)
	ld	(xwa+4), l
	ld	(xwa+2), 72
	call	16554837
	lda	xhl, (xsp)
	inc	6, xsp
	ret
	extz	bc
	lda	xde, (15572388:24)
	ld_rrb	e, xde, bc
	cp	e, 22
	ret	ugt
	extz	de
	sla	de, 2
	lda	xhl, (15572644:24)
	exts	xde
	add	xde, xhl
	ld	xhl, (xde)
	call	(xhl)
	ret
	dec	4, xsp
	push	xiz
	ld	xiz, xwa
	cp	(36148:16), 17
	jr	z, 108
	.byte 0xf1, 0xcd, 0x34, 0xcb
	jr	nz, 102
	.byte 0xf1, 0xf9, 0x90, 0xb9
	ld	a, (xiz+3)
	.byte 0x8e, 0x02, 0xc1
	ld	(xsp+4), 0
	cp	a, 0:i3
	jr	z, 4
	ld	(xsp+4), 8
	ldw	(xsp+6), 0
	lda	xbc, (37115:16)
	ld	wa, (xsp+6)
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	cp	a, 255
	jr	z, 57
	extz	wa
	ldw	bc, 1537
	call	16569591
	cp	hl, 1:i3
	jr	nz, 34
	lda	xwa, (37115:16)
	ld	bc, (xsp+6)
	extz	xbc
	add	xbc, xwa
	ld	a, (xbc)
	ld	(xiz), a
	ld	(xiz+1), 4
	ld	a, (xsp+4)
	ld	(xiz+2), a
	ld	(xiz+3), 8
	ld	xwa, xiz
	calr	-3032
	incw	1, (xsp+6)
	.byte 0x9f, 0x06, 0x3f, 0x10, 0x00
	jr	c, -75
	pop	xiz
	inc	4, xsp
	ret
	.byte 0xf1, 0xf9, 0x90, 0xb9
	ld	(xwa), 72
	ld	(xwa+1), 5
	lda	xde, (xwa+2)
	lda	xhl, (xwa+3)
	ld	c, (xhl)
	.byte 0x82, 0xc3
	jr	z, 5
	ld	(xde), 1
	jr	3
	ld	(xde), 0
	ld	(xhl), 1
	jrl	-3083
	push	xiz
	ld	xiz, xwa
	ld	a, (36148:16)
	cp	a, 16
	jr	z, 24
	cp	a, 15
	jr	z, 19
	cp	a, 14
	jr	z, 14
	cp	a, 17
	jr	z, 9
	cp	a, 3:i3
	jr	z, 5
	cp	a, 19
	jr	nz, 2
	jr	67
	ld	xwa, 192
	call	16569399
	cp	hl, 1:i3
	jr	z, 54
	ld	a, (xiz+3)
	.byte 0x8e, 0x02, 0xc1
	jr	z, 46
	.byte 0xf1, 0xf9, 0x90, 0xb9
	ld	(xiz), 152
	ld	(xiz+1), 1
	ld	xwa, 768
	call	16569399
	lda	xwa, (xiz+2)
	cp	l, 80
	jr	c, 5
	ld	(xwa), 1
	jr	4
	inc	1, l
	ld	(xwa), l
	ld	(xiz+3), 127
	ld	xwa, xiz
	calr	-3188
	pop	xiz
	ret
	push	xiz
	ld	xiz, xwa
	ld	a, (36148:16)
	cp	a, 16
	jr	z, 24
	cp	a, 15
	jr	z, 19
	cp	a, 14
	jr	z, 14
	cp	a, 17
	jr	z, 9
	cp	a, 3:i3
	jr	z, 5
	cp	a, 19
	jr	nz, 2
	jr	66
	ld	xwa, 192
	call	16569399
	cp	hl, 1:i3
	jr	z, 53
	ld	a, (xiz+3)
	.byte 0x8e, 0x02, 0xc1
	jr	z, 45
	.byte 0xf1, 0xf9, 0x90, 0xb9
	ld	(xiz), 152
	ld	(xiz+1), 1
	ld	xwa, 768
	call	16569399
	lda	xwa, (xiz+2)
	cp	l, 1:i3
	jr	ugt, 5
	ld	(xwa), 80
	jr	4
	dec	1, l
	ld	(xwa), l
	ld	(xiz+3), 127
	ld	xwa, xiz
	calr	-3294
	pop	xiz
	ret
ExtDev_SndParam_Block48_Var40:
	set	1, (0x90f9:16)
	ld	(xwa), 72
	ld	(xwa+1), 5
	lda	xde, (xwa+2)
	lda	xhl, (xwa+3)
	ld	c, (xhl)
	and	c, (xde)
	jr	z, 5
	ld	(xde), 64
	jr	3
	ld	(xde), 0
	ld	(xhl), 64
	jrl	-3333
ExtDev_SndParam_Block48_Var80:
	set	1, (0x90f9:16)
	ld	(xwa), 72
	ld	(xwa+1), 5
	lda	xde, (xwa+2)
	lda	xhl, (xwa+3)
	ld	c, (xhl)
	and	c, (xde)
	jr	z, 5
	ld	(xde), 128
	jr	3
	ld	(xde), 0
	ld	(xhl), 128
	jrl	-3370
ExtDev_SndParam_Block48_Var04:
	set	1, (0x90f9:16)
	ld	(xwa), 72
	ld	(xwa+1), 5
	lda	xde, (xwa+2)
	lda	xhl, (xwa+3)
	ld	c, (xhl)
	and	c, (xde)
	jr	z, 5
	ld	(xde), 4
	jr	3
	ld	(xde), 0
	ld	(xhl), 4
	jrl	-3407
ExtDev_SndParam_Block48_Var04_B:
	set	1, (0x90f9:16)
	ld	(xwa), 72
	ld	(xwa+1), 6
	lda	xde, (xwa+2)
	lda	xhl, (xwa+3)
	ld	c, (xhl)
	and	c, (xde)
	jr	z, 5
	ld	(xde), 4
	jr	3
	ld	(xde), 0
	ld	(xhl), 4
	jrl	-3444
ExtDev_SndParam_Write98_Block:
	push	xiz
	ld	xiz, xwa
	ld	a, (0x8d3a:16)
	extz	wa
	ldw	bc, 1539
	call	SndParam_LookupViaEncode
	cp	hl, 1:i3
	jr	nz, 39
	.byte 0xf1
	swi	1
	.byte 0x90
	ld	(xbc-74), 152
	ld	(xiz+1), 2
	lda	xbc, (xiz+2)
	lda	xde, (xiz+3)
	ld	a, (xde)
	.byte 0x81, 0xc1
	jr	z, 5
	ld	(xbc), 128
	jr	3
	ld	(xbc), 0
	ld	(xde), 128
	ld	xwa, xiz
	calr	62033
	pop	xiz
	ret
ExtDev_SndParam_Block98_Var40:
	set	1, (0x90f9:16)
	ld	(xwa), 152
	ld	(xwa+1), 2
	lda	xde, (xwa+2)
	lda	xhl, (xwa+3)
	ld	c, (xhl)
	and	c, (xde)
	jr	z, 5
	ld	(xde), 64
	jr	3
	ld	(xde), 0
	ld	(xhl), 64
	jrl	-3542
ExtDev_SndParam_BlockA9_Var02:
	.byte 0xc1
	ldw	iz, 0x3f8d
	.byte 0x87
	ret	nz
	.byte 0xf1
	swi	1
	.byte 0x90
	ld	(xbc-80), 169
	ld	(xwa+1), 10
	lda	xde, (xwa+2)
	lda	xhl, (xwa+3)
	ld	c, (xhl)
	.byte 0x82, 0xc3
	jr	z, 5
	ld	(xde), 2
	jr	3
	ld	(xde), 0
	ld	(xhl), 2
	calr	61950
	ret
ExtDev_SndParam_Block98_Var80:
	set	1, (0x90f9:16)
	ld	(xwa), 152
	ld	(xwa+1), 11
	lda	xde, (xwa+2)
	lda	xhl, (xwa+3)
	ld	c, (xhl)
	and	c, (xde)
	jr	z, 5
	ld	(xde), 128
	jr	3
	ld	(xde), 0
	ld	(xhl), 128
	jrl	-3624
ExtDev_SndParam_Block98_Var40_B:
	set	1, (0x90f9:16)
	ld	(xwa), 152
	ld	(xwa+1), 11
	lda	xde, (xwa+2)
	lda	xhl, (xwa+3)
	ld	c, (xhl)
	and	c, (xde)
	jr	z, 5
	ld	(xde), 64
	jr	3
	ld	(xde), 0
	ld	(xhl), 64
	jrl	-3661
ExtDev_SndParam_ConfigAndWrite:
	push	xiz
	ld	xiz, xwa
	ld	a, (xiz+3)
	.byte 0x8e
	push	sr
	cp a, (16486:16)
	swi	1
	.byte 0x90, 0xb9, 0xb6
	push_a
	push	xde
	.byte 0x8d
	ld	(xiz+1), 5
	ld	a, (0x8d3a:16)
	extz	wa
	ldw	bc, 93
	call	SndParam_LookupViaEncode
	lda	xbc, (xiz+2)
	cp	hl, 0:i3
	jr	nz, 20
	ld	a, (0x8d3a:16)
	extz	wa
	lda	xde, (0x918d:16)
	extz	xwa
	add	xwa, xde
	ld	a, (xwa)
	ld	(xbc), a
	jr	3
	ld	(xbc), 0
	ld	(xiz+3), 127
	ld	xwa, xiz
	calr	61800
	pop	xiz
	ret
ExtDev_SndParam_Block14_Dual:
	lda	xhl, (xwa+2)
	lda	xix, (xwa+3)
	ld	e, (xhl)
	ld	c, (xix)
	and	c, e
	ret	z
	.byte 0xf1
	swi	1
	.byte 0x90, 0xb9, 0xb0
	push_a
	push	xde
	.byte 0x8d
	ld	(xwa+1), 4
	ld	(xhl), 64
	ld	(xix), 64
	calr	61763
	ret
ExtDev_SndParam_Write48_Block:
	push	xiz
	ld	xiz, xwa
	ld	xwa, 192
	call	SndParam_LookupReadOnly
	cp	hl, 0:i3
	jr	nz, 39
	.byte 0xf1
	swi	1
	.byte 0x90
	ld	(xbc-74), 72
	ld	(xiz+1), 4
	lda	xbc, (xiz+2)
	lda	xde, (xiz+3)
	ld	a, (xde)
	.byte 0x81, 0xc1
	jr	z, 5
	ld	(xbc), 64
	jr	3
	ld	(xbc), 0
	ld	(xde), 64
	ld	xwa, xiz
	calr	61707
	pop	xiz
	ret
ExtDev_SndParam_Block48_Var02:
	cp	(0x8d34:16), 16
	ret	z
	set	1, (0x90f9:16)
	ld	(xwa), 72
	ld	(xwa+1), 5
	lda	xde, (xwa+2)
	lda	xhl, (xwa+3)
	ld	c, (xhl)
	and	c, (xde)
	jr	z, 5
	ld	(xde), 2
	jr	3
	ld	(xde), 0
	ld	(xhl), 2
	jrl	-3875
ExtDev_SndParam_Block70_Var04:
	set	1, (0x90f9:16)
	ld	(xwa), 112
	ld	(xwa+1), 0
	lda	xde, (xwa+2)
	lda	xhl, (xwa+3)
	ld	c, (xhl)
	and	c, (xde)
	jr	z, 5
	ld	(xde), 4
	jr	3
	ld	(xde), 0
	ld	(xhl), 4
	jrl	-3912
ExtDev_SndParam_DispatchAndWriteA8:
	push	xiz
	ld	xiz, xwa
	ld	a, (0x8d34:16)
	cp	a, 16
	jr	z, 24
	cp	a, 15
	jr	z, 19
	cp	a, 14
	jr	z, 14
	cp	a, 17
	jr	z, 9
	cp	a, 3:i3
	jr	z, 5
	cp	a, 19
	jr	nz, 2
	jr	49
	ld	xwa, 192
	call	SndParam_LookupReadOnly
	cp	hl, 1:i3
	jr	z, 36
	.byte 0xf1
	swi	1
	.byte 0x90
	ld	(xbc-74), 168
	ld	(xiz+1), 4
	lda	xde, (xiz+2)
	lda	xhl, (xiz+3)
	ld	c, (xde)
	ld	a, (xhl)
	and	a, c
	jr	z, 11
	ld	(xde), 2
	ld	(xhl), 2
	ld	xwa, xiz
	calr	61537
	pop	xiz
	ret
ExtDev_SndParam_DispatchAndWriteA8_Alt:
	push	xiz
	ld	xiz, xwa
	ld	a, (0x8d34:16)
	cp	a, 16
	jr	z, 24
	cp	a, 15
	jr	z, 19
	cp	a, 14
	jr	z, 14
	cp	a, 17
	jr	z, 9
	cp	a, 3:i3
	jr	z, 5
	cp	a, 19
	jr	nz, 2
	jr	49
	ld	xwa, 192
	call	SndParam_LookupReadOnly
	cp	hl, 1:i3
	jr	z, 36
	.byte 0xf1
	swi	1
	.byte 0x90
	ld	(xbc-74), 168
	ld	(xiz+1), 4
	lda	xde, (xiz+2)
	lda	xhl, (xiz+3)
	ld	c, (xde)
	ld	a, (xhl)
	and	a, c
	jr	z, 11
	ld	(xde), 1
	ld	(xhl), 1
	ld	xwa, xiz
	calr	61448
	pop	xiz
	ret
ExtDev_SndParam_MultiReg_Iterate:
	set	1, (0x90f9:16)
	lda	xix, (xwa+2)
	ld	l, (xwa+3)
	ld	d, (xix)
	ld	e, l
	and	e, d
	extz	bc
	cp	e, 0:i3
	jrl	nz, -1030
	or	d, l
	ld	(xix), d
	jrl	-930
ExtDev_SndParam_DispatchComplex:
	dec	2, xsp
	push	xiz
	ld	(xsp+4), c
	ld	xiz, xwa
	ld	a, (0x8d34:16)
	cp	a, 16
	jr	z, 24
	cp	a, 15
	jr	z, 19
	cp	a, 14
	jr	z, 14
	cp	a, 17
	jr	z, 9
	cp	a, 3:i3
	jr	z, 5
	cp	a, 19
	jr	nz, 2
	jr	59
	ld	xwa, 192
	call	SndParam_LookupReadOnly
	cp	hl, 1:i3
	jr	z, 46
	ld	a, (xiz+3)
	.byte 0x8e
	push	sr
	cp a, (9830:16)
	swi	1
	.byte 0x90
	ld	(xbc-74), 152
	ld	(xiz+1), 1
	call	BitMapOut_PrepareRender_CheckBit1
	sll	l, 3
	ld	w, (xsp+4)
	sub	w, 191
	add	w, l
	ld	(xiz+2), w
	ld	(xiz+3), 127
	ld	xwa, xiz
	calr	61314
	pop	xiz
	inc	2, xsp
	ret
	push	xiz
	ld	xiz, xwa
	ld	a, (xiz+2)
	cp	a, 0:i3
	jr	z, 59
	ldb	w, 0
	extz	xwa
	call	Util_FindLowestSetBit
	lda	xbc, (xiz+2)
	ld	(xbc), l
	ld	a, (0x8e90:16)
	extz	wa
	sla	wa, 2
	lda	xde, (SoundParam_EncoderMappingData_0x286:24)
	ld_rrl xde, xde, wa
	or xde, xde
	jr	z, 23
	extz	hl
	ld_rrb a, xde, hl
	ld	(xbc), a
	cp	a, 255
	jr	z, 9
	ld	(xiz+3), 255
	ld	xwa, xiz
	calr	61241
	pop	xiz
	ret

VoiceEntry_FindMasterVolume:
	lda xde, (0xc039:16)
	lds32 xbc, 0
	lds wa, 0
	jr VoiceEntry_CheckTerminator

VoiceEntry_CheckMatch:
	cp (xde), 0x98
	jr nz, VoiceEntryLoop_Continue
	cp (xde + 1), 0x1
	jr nz, VoiceEntryLoop_Continue
	cp (xde + 3), 0x7f
	jr nz, VoiceEntryLoop_Continue
	or xbc, xbc
	jr z, VoiceEntry_SaveMatch
	ld (xbc + 3), 0x0

VoiceEntry_SaveMatch:
	ld xbc, xde

VoiceEntryLoop_Continue:
	inc 1, wa
	inc 4, xde
	cp wa, 0xf
	ret nc

VoiceEntry_CheckTerminator:
	cp (xde), 0xff
	jr nz, VoiceEntry_CheckMatch
	ret

Audio_CopyStateFromROM:
	calr MidiCC_ResetState
	lda xbc, (SoundParam_EncoderMappingData_0x302:24)
	ld xwa, xbc
	lda xde, (0x8eb6:16)
	lda xhl, (xbc + 12)

AudioCopy_TransferLoop:
	ld xiy, xwa
	ld xix, xde
	ldiw
	ldiw
	inc 4, xwa
	inc 4, xde
	cp xwa, xhl
	jr c, AudioCopy_TransferLoop
	ret

Audio_NullHandler_A:
	ret

Audio_NullHandler_B:
	ret

Audio_NullHandler_C:
	ret

Encoder_TimingAndOutput:
	inc 1, (0x8ec6:16)
	ld wa, (0x8ec8:16)
	cp wa, 0:i3
	jr z, Encoder_CheckTimerDelta
	dec 1, wa
	ld (0x8ec8:16), wa

Encoder_CheckTimerDelta:
	ld wa, (1033:16)
	sub wa, (0x8ec2:16)
	cp wa, 0x10
	jr c, Encoder_CheckBitAndProcess
	ld (0x8ec6:16), 0
	jr Encoder_ProcessUpdate

Encoder_CheckBitAndProcess:
	bit 0, (0x8ec6:16)
	jr nz, Encoder_IncrementAndDispatch

Encoder_ProcessUpdate:
	calr Audio_PeriodicUpdate

Encoder_IncrementAndDispatch:
	call Audio_IncrementUpdateCounter
	push	sr
	ei 6
	call MidiOut_SerializeAndSend
	pop	sr
	jp CompIface_ProcessInput

Audio_PeriodicUpdate:
	ldmm16 0x8ec2, 1033
	cp (0x8d36:16), 247
	ret z
	calr Audio_ProcessVoiceQueue
	calr MIDI_ProcessVoiceAssignment
	calr MIDI_ProcessControlChange
	ret

Audio_ProcessVoiceQueue:
	push xiz
	lda xiz, (0x8eb2:16)
	cp (0x8ec4:16), 7
	jr nc, VoiceQueue_Done

VoiceQueue_ParseNextEntry:
	ld xwa, xiz
	calr MIDI_ParseThreeByteParams
	cp l, 0xff
	jr z, VoiceQueue_Done
	ld xwa, xiz
	calr Voice_SetupFromData
	cp (0x8ec4:16), 7
	jr c, VoiceQueue_ParseNextEntry

VoiceQueue_Done:
	pop xiz
	ret

MIDI_ParseThreeByteParams:
	dec 2, xsp
	push xiz
	ld xiz, xwa
	ld (xsp + 4), 0xff
	call Seq_DataHandler
	cp hl, 0xffff
	jr z, MidiParseThreeByte_Done
	extz hl
	ld wa, hl
	calr MidiCC_LookupHandler
	ld (xiz), l
	call Seq_DataHandler
	cp hl, 0xffff
	jr z, MidiParseThreeByte_Done
	ld (xiz + 1), l
	call Seq_DataHandler
	cp hl, 0xffff
	jr z, MidiParseThreeByte_Done
	ld (xiz + 2), l
	ld (xsp + 4), 0x0

MidiParseThreeByte_Done:
	ld l, (xsp + 4)
	pop xiz
	inc 2, xsp
	ret

MIDI_ProcessVoiceAssignment:
	ld_sd8b A, 0x40
	and a, 0xc
	srl a, 2
	ld c, a
	ld xwa, 0x8eb6
	calr MIDI_WriteParamByte
	ld_sd8b A, 0x40
	and a, 0xf0
	srl a, 4
	cp a, 0xf
	jr nz, MIDI_ValidateParam
	ldw (0x8ec8:16), 500
	jr MIDI_WriteSecondByte

MIDI_ValidateParam:
	cpw (0x8ec8:16), 0
	jr nz, MIDI_WriteSecondByte
	lda xwa, (0x8eba:16)
	ld_sd8b C, 0x40
	and c, 0xf0
	srl c, 4
	calr MIDI_WriteParamByte

MIDI_WriteSecondByte:
	lda xwa, (0x8ebe:16)
	ldcf_dd8 6, 0x34
	scc8 c, c
	jr MIDI_WriteParamByte

MIDI_WriteParamByte:
	lda xsp, (xsp - 10)
	push xiz
	lda xhl, (xwa + 1)
	cp (xwa), 0x1d
	jr nz, MIDI_ChannelSetup_Skip
	ld e, c
	and e, 0xf
	cp e, 0xf
	jr nz, MIDI_ChannelSetup_Skip
	xor c, 0xf
	ld (xhl), c
	jr MIDI_ChannelSetup_Store

MIDI_ChannelSetup_Skip:
	ld (xhl), c

MIDI_ChannelSetup_Store:
	cp (0x8ec4:16), 7
	jr nc, VoiceData_Setup_Ret
	lda xbc, (xwa + 1)
	ld (xsp + 8), xbc
	ld b, (xbc)
	cp b, 0:i3
	jr nz, MIDI_ChannelSetup_Init
	cp (xwa + 3), 0x0
	jr z, VoiceData_Setup_Ret

MIDI_ChannelSetup_Init:
	lda xiz, (0x8eb2:16)
	ld (xsp + 4), xiz
	lda xiy, (xwa + 3)
	ld e, (xiy)
	ld (xsp + 12), e
	lda xix, (xwa + 2)
	ld l, (xix)
	ld d, l
	xor d, b
	and d, e
	and l, b
	or l, d
	ld (xiy), l
	ld xbc, (xsp + 8)
	ld c, (xbc)
	ld (xix), c
	cp l, e
	jr z, VoiceData_Setup_Ret
	ld a, (xwa)
	ld (xiz), a
	ld (xiz + 1), l
	ld a, (xsp + 12)
	xor a, l
	ld (xiz + 2), a
	ld xwa, (xsp + 4)
	calr Voice_SetupFromData

VoiceData_Setup_Ret:
	pop xiz
	lda xsp, (xsp + 10)
	ret

MIDI_ProcessControlChange:
	push xiz
	lda xiz, (0x8eb2:16)
	cp (0x8ec4:16), 7
	jr nc, MidiCC_ProcessParam
	lda xbc, (0x8f10:16)
	lda xwa, (xbc + 1)
	bitm 7, (xwa)
	jr z, MidiCC_ProcessParam
	resm 7, (xwa)
	ld (xiz), 0x1a
	ld a, (xbc)
	ld (xiz + 1), a
	ld (xiz + 2), 0x7f
	ld xwa, xiz
	calr Voice_SetupFromData

MidiCC_ProcessParam:
	cp (0x8ec4:16), 7
	jr nc, MidiCC_SkipEntry
	lda xbc, (0x8f16:16)
	lda xwa, (xbc + 1)
	bitm 7, (xwa)
	jr z, MidiCC_SkipEntry
	resm 7, (xwa)
	ld (xiz), 0x1b
	ld a, (xbc)
	ld (xiz + 1), a
	ld (xiz + 2), 0x7f
	ld xwa, xiz
	calr Voice_SetupFromData

MidiCC_SkipEntry:
	pop xiz
	ret

MidiCC_LookupHandler:
	ld c, a
	and c, 0x1f
	and a, 0xc0
	srl a, 1
	or a, c
	extz wa
	lda xbc, (EffectMode_DispatchTable_0x10:24)
	ldb_sri L, 0x07, 0xe4, 0xe0
	ret

Voice_SetupFromData:
	push xiz
	ld xiz, xwa
	ld c, (0x8ec4:16)
	ld a, c
	extz wa
	muls wa, 0x3
	lda xde, (0x8e94:16)
	exts xwa
	add xwa, xde
	cp (0x8d36:16), 251
	jrl nz, MidiCC_ReturnClean
	cp (xiz), 0x3
	jr nz, MidiCC_ValidateRange
	cp (xiz + 2), 0x1
	jr nz, MidiCC_ValidateRange
	ld c, (0x8d80:16)
	res 0, c
	ld (0x8d80:16), c
	ld a, (xiz + 2)
	and a, 0x1
	and a, (xiz + 1)
	bit 0, a
	jr z, MidiCC_Return
	set 0, c
	ld (0x8d80:16), c
	jr MIDI_PopIzRet

MidiCC_ValidateRange:
	cp (xiz), 0x19
	jr nz, MidiCC_StoreAndDispatch
	ld a, (xiz + 2)
	and a, 0x1
	and a, (xiz + 1)
	bit 0, a
	jr z, MidiCC_Return
	ldw wa, 0x10
	call MIDI_SendSysExCmd
	jr MIDI_PopIzRet

MidiCC_StoreAndDispatch:
	cp (xiz), 0x15
	jr ugt, MidiCC_Finalize
	ld a, (xiz + 2)
	and a, (xiz + 1)
	jr z, MidiCC_CheckOverflow
	ldw wa, 0x10
	call MIDI_SendSysExCmd

MidiCC_CheckOverflow:
	ld xwa, xiz
	call EffectMode_MidiSetLEDs
	jr MIDI_PopIzRet

MidiCC_Finalize:
	inc 1, c
	ld (0x8ec4:16), c
	ld xiy, xiz
	ld xix, xwa
	ldi85
	ldiw
	ld a, (0x8ec4:16)
	extz wa
	muls wa, 0x3
	stib_ind 0x07, 0xe8, 0xe0, 0xff

MidiCC_Return:
	jr MIDI_PopIzRet

MidiCC_ReturnClean:
	inc 1, c
	ld (0x8ec4:16), c
	ld xiy, xiz
	ld xix, xwa
	ldi85
	ldiw
	ld a, (0x8ec4:16)
	extz wa
	muls wa, 0x3
	stib_ind 0x07, 0xe8, 0xe0, 0xff
	call SeqStep_TimerDispatchC

MIDI_PopIzRet:
	pop xiz
	ret

MidiCC_SyncForceResync:
	lda xhl, (0x8e94:16)
	ret

MidiCC_ResetState:
	ld (0x8e94:16), 255
	ld (0x8ec4:16), 0
	ret

	.include "midi/midi_encoder_routines.s"

MidiParam_ForceResync:
	ld (297:16), 131
	ld (296:16), 7
	lds wa, 0
	calr MidiChannel_GetParamByIndex
	ld a, l
	lds bc, 2
	call CPanel_EncoderDispatch
	ld a, (0x8ee4:16)
	cpl a
	ld (0x8ee4:16), a
	lds wa, 0
	calr MidiChannel_GetParamByIndex
	ld a, l
	lds bc, 2
	call CPanel_EncoderDispatch
	lda xwa, (0x8f10:16)
	ld (xwa), l
	setm 7, (xwa + 1)
	lds wa, 1
	calr MidiChannel_GetParamByIndex
	ld a, l
	lds bc, 5
	call CPanel_EncoderDispatch
	ld a, (0x8ef4:16)
	cpl a
	ld (0x8ef4:16), a
	lds wa, 1
	calr MidiChannel_GetParamByIndex
	ld a, l
	lds bc, 5
	call CPanel_EncoderDispatch
	lda xwa, (0x8f16:16)
	ld (xwa), l
	setm 7, (xwa + 1)
	ret

MidiChannel_GetParamByIndex:
	cp a, 3:i3
	jr z, MidiChannel_GetParam3
	cp a, 2:i3
	jr z, MidiChannel_GetParam2
	cp a, 1:i3
	jr z, MidiChannel_GetParam1
	cp a, 0:i3
	jr nz, MidiChannel_GetParamReturn
	lda xbc, (288:16)
	jr MidiChannel_GetParamReturn

MidiChannel_GetParam1:
	lda xbc, (290:16)
	jr MidiChannel_GetParamReturn

MidiChannel_GetParam2:
	lda xbc, (292:16)
	jr MidiChannel_GetParamReturn

MidiChannel_GetParam3:
	lda xbc, (294:16)

MidiChannel_GetParamReturn:
	ld l, (xbc + 1)
	ret

MidiParam_ProcessDeltas:
	ld xwa, 0x8f10
	calr MidiParam_ProcessChannel0
	ld xwa, 0x8f16
	jr MidiParam_ProcessChannel1

MidiParam_ProcessChannel0:
	dec 4, xsp
	pushw_erp 0xfa
	ld (xsp + 2), xwa
	lds wa, 0
	calr MidiChannel_GetParamByIndex
	ldb_erp L, 0xfb
	stb_erp A, 0xfb
	extz wa
	ld c, (0x8efc:16)
	extz bc
	ld xde, 0x8f04
	calr MIDI_ComputeParamDelta
	lda xwa, (0x8f04:16)
	bitm 3, (xwa)
	jr z, MidiParam_Ch0_Done
	resm 3, (xwa)
	stb_erp A, 0xfb
	ld (0x8efc:16), a
	stb_erp A, 0xfb
	extz wa
	lds bc, 2
	call CPanel_EncoderDispatch
	cp hl, 0xffff
	jr z, MidiParam_Ch0_Done
	ld xwa, (xsp + 2)
	ld (xwa), l
	setm 7, (xwa + 1)

MidiParam_Ch0_Done:
	popw_erp 0xfa
	inc 4, xsp
	ret

MidiParam_ProcessChannel1:
	dec 4, xsp
	pushw_erp 0xfa
	ld (xsp + 2), xwa
	lds wa, 1
	calr MidiChannel_GetParamByIndex
	ldb_erp L, 0xfb
	stb_erp A, 0xfb
	extz wa
	ld c, (0x8efe:16)
	extz bc
	ld xde, 0x8f06
	calr MIDI_ComputeParamDelta
	lda xwa, (0x8f06:16)
	bitm 3, (xwa)
	jr z, MidiParam_Ch1_Done
	resm 3, (xwa)
	stb_erp A, 0xfb
	ld (0x8efe:16), a
	stb_erp A, 0xfb
	extz wa
	lds bc, 5
	call CPanel_EncoderDispatch
	cp hl, 0xffff
	jr z, MidiParam_Ch1_Done
	ld xwa, (xsp + 2)
	ld (xwa), l
	setm 7, (xwa + 1)

MidiParam_Ch1_Done:
	popw_erp 0xfa
	inc 4, xsp
	ret

MIDI_ComputeParamDelta:
	dec 8, xsp
	ld (xsp), xde
	ld (xsp + 4), c
	ld (xsp + 6), a
	ld c, (xsp + 4)
	extz bc
	ld a, (xsp + 6)
	extz wa
	sub wa, bc
	pushw wa
	call Math_AbsInt16
	inc 2, xsp
	cp hl, 2:i3
	jr le, MidiParam_DeltaTooSmall
	ld c, (xsp + 4)
	extz bc
	ld a, (xsp + 6)
	extz wa
	sub wa, bc
	pushw wa
	call Math_AbsInt16
	inc 2, xsp
	cp hl, 6:i3
	jr le, MidiParam_DeltaMedium
	ld xwa, (xsp)
	ld a, (xwa)
	and a, 0x3
	xor a, 0x3
	jr z, MidiParam_DeltaConfirmed
	ld xbc, (xsp)
	ld a, (xbc)
	and a, 0x3
	inc 1, a
	and a, 0x3
	andmi8 (xbc), 0xfc
	or (xbc), a
	jr MidiParam_DeltaClearActive

MidiParam_DeltaMedium:
	ld xwa, (xsp)
	bitm 2, (xwa)
	jr z, MidiParam_DeltaStartDebounce

MidiParam_DeltaConfirmed:
	ld xwa, (xsp)
	andmi8 (xwa), 0xfc
	resm 2, (xwa)
	setm 3, (xwa)
	jr MidiParam_DeltaDone

MidiParam_DeltaStartDebounce:
	ld xwa, (xsp)
	setm 2, (xwa)
	jr MidiParam_DeltaDone

MidiParam_DeltaTooSmall:
	ld xwa, (xsp)
	andmi8 (xwa), 0xfc

MidiParam_DeltaClearActive:
	ld xwa, (xsp)
	resm 2, (xwa)

MidiParam_DeltaDone:
	inc 8, xsp
	ret

Audio_UpdateLEDsAndChannels:
	calr Audio_InitChannelTimers
	orw (0x8f42:16), 2
	ret

MIDI_ProcessChangedChannels:
	cp (0x8d36:16), 251
	ret z
	calr Audio_CheckAndFlagChanges
	ld wa, (0x8f3c:16)
	cpl wa
	and wa, (0x8f3a:16)
	jr z, MidiChanged_ProcessGroup2
	ld xbc, ENCODER_LUT_MODWHEEL_0x3C6
	calr DispatchBitmaskHandlers
	ldw (0x8f3a:16), 0

MidiChanged_ProcessGroup2:
	ld wa, (0x8f40:16)
	cpl wa
	and wa, (0x8f3e:16)
	jr z, MidiChanged_ProcessGroup3
	ld xbc, ENCODER_LUT_MODWHEEL_0x3FC
	calr DispatchBitmaskHandlers
	ldw (0x8f3e:16), 0

MidiChanged_ProcessGroup3:
	ld wa, (0x8f44:16)
	cpl wa
	and wa, (0x8f42:16)
	jr z, MidiChanged_ProcessGroup4
	ld xbc, ENCODER_LUT_MODWHEEL_0x43E
	calr DispatchBitmaskHandlers
	ldw (0x8f42:16), 0

MidiChanged_ProcessGroup4:
	ld wa, (0x8f48:16)
	cpl wa
	and wa, (0x8f46:16)
	ret z
	ld xbc, ENCODER_LUT_MODWHEEL_0x48C
	calr DispatchBitmaskHandlers
	ldw (0x8f46:16), 0
	ret

MidiChannel_DispatchChanged:
	cp (0x8d36:16), 251
	ret z
	ld wa, (0x8f3c:16)
	cp wa, 0:i3
	jr z, MidiDispatch_CheckGroup2
	ld xbc, ENCODER_LUT_MODWHEEL_0x49E
	calr DispatchBitmaskHandlers

MidiDispatch_CheckGroup2:
	ld wa, (0x8f40:16)
	cp wa, 0:i3
	jr z, MidiDispatch_CheckGroup3
	ld xbc, ENCODER_LUT_MODWHEEL_0x4A4
	calr DispatchBitmaskHandlers

MidiDispatch_CheckGroup3:
	ld wa, (0x8f44:16)
	cp wa, 0:i3
	jr z, MidiDispatch_CheckGroup4
	ld xbc, ENCODER_LUT_MODWHEEL_0x4BC
	calr DispatchBitmaskHandlers

MidiDispatch_CheckGroup4:
	ld wa, (0x8f48:16)
	cp wa, 0:i3
	jr z, MidiDispatch_UpdateLEDs
	ld xbc, ENCODER_LUT_MODWHEEL_0x4D4
	calr DispatchBitmaskHandlers

MidiDispatch_UpdateLEDs:
	jrl CtrlPanel_UpdateLEDState

Audio_InitChannelTimers:
	ld (0x8f4c:16), 5
	ld (0x8f4e:16), 5
	ld (0x8f50:16), 5
	ld (0x8f52:16), 5
	ld (0x8f54:16), 5
	ld (0x8f56:16), 5
	ret

Audio_IncrementUpdateCounter:
	inc 1, (0x8f4a:16)
	ret

Audio_CheckAndFlagChanges:
	call GetDialEnableState
	cp l, (0x8f5e:16)
	jr z, AudioChange_CheckSelectionState
	orw (0x8f42:16), 64
	ld (0x8f5e:16), l

AudioChange_CheckSelectionState:
	call CtrlPanel_GetSelectionState
	cp l, (0x8f60:16)
	ret z
	cp l, 2:i3
	jr nz, AudioChange_UpdatePreviousSelect
	orw (0x8f44:16), 4

AudioChange_UpdatePreviousSelect:
	cp (0x8f60:16), 2
	jr nz, AudioChange_SetChannelFlag
	andw (0x8f44:16), 0xfffb

AudioChange_SetChannelFlag:
	orw (0x8f42:16), 4
	ld (0x8f60:16), l
	ret

DispatchBitmaskHandlers:
	dec 2, xsp
	push xiz
	ld xiz, xbc
	ld (xsp + 4), wa
	cpw (xiz), 0xffff
	jr z, BitmaskDispatch_Return

; Bitmask dispatch loop handler
BitmaskDispatch_LoopHandler:
	ld wa, (xsp + 4)
	and wa, (xiz)
	jr z, BitmaskDispatch_NextEntry
	ld xhl, (xiz + 2)
	call (xhl)

BitmaskDispatch_NextEntry:
	inc 6, xiz
	cpw (xiz), 0xffff
	jr nz, BitmaskDispatch_LoopHandler

BitmaskDispatch_Return:
	pop xiz
	inc 2, xsp
	ret


; This routine seems to set the LEDs of the control panel
; I'm not sure yet if this is initialization, or if it
; also serves to update the LEDs later on.
CtrlPanel_UpdateLEDState:
	dec 8, xsp
	pushw_erp 0xfa
	lda xwa, (0x8f18:16)
	ld (xsp + 2), xwa
	lda xwa, (0x8f28:16)
	ld (xsp + 6), xwa
	cp (0x8d36:16), 247
	jr z, LEDUpdate_Cleanup
	ldib_erp 0xfb, 0

LEDUpdate_ProcessChannel:
	stb_erp A, 0xfb
	extz wa
	ld xbc, (xsp + 2)
	ldb_sri C, 0x07, 0xe4, 0xe0
	ldb_erp C, 0xfa
	ld xbc, (xsp + 6)
	ldb_sri C, 0x07, 0xe4, 0xe0
	cpb_erp C, 0xfa
	jr z, LEDUpdate_NextChannel
	stb_erp C, 0xfa
	extz bc
	calr Set_LEDs
	stb_erp E, 0xfb
	extz de
	ld xwa, (xsp + 6)
	stb_erp C, 0xfa
	stb_dri C, 0x07, 0xe0, 0xe8

LEDUpdate_NextChannel:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0f
	jr c, LEDUpdate_ProcessChannel

LEDUpdate_Cleanup:
	popw_erp 0xfa
	inc 8, xsp
	ret


Set_LEDs:
	; Input: WA: row of LEDs
	;         C: LED pattern
	ld e, a
	cp e, 0xf
	ret ugt
	lda xwa, (0x8f38:16)
	extz de
	lda xhl, (Protocol_values_for_LED_rows:24)
	ldb_sri E, 0x07, 0xec, 0xe8
	ld (xwa), e
	ld (xwa + 1), c
	calr LED_WriteToPanel
	ret

	.include "ui/led_panel_write.s"


SndParam_SetResBit0_Via028100:
	; --- Routine 1: call FCD437(0x028100), set/res bit 0 at (xwa) (29 bytes) ---
	push xiz
	lda	xiz, (0x8f18:16)
	ld xwa, 0x00028100
	call SndParam_LookupReadOnly
	lda	xwa, (xiz+4)
	cp	hl, 1:i3
	jr nz, SndParam028100_ResBit0
	setm	0, (xwa)
	jr t, SndParam028100_Done
SndParam028100_ResBit0:
	.byte 0xb0, 0xb0				; res 0, (xwa)  [not in LLVM]
SndParam028100_Done:
	pop xiz
	ret
SndParam_SetResBit1_ViaRegs0100_0101:
	; --- Routine 2: 2x FCD437, set/res bit 1 at (xiz+4) (41 bytes) ---
	push xiz
	lda	xiz, (0x8f18:16)
	ld xwa, 0x00028100
	call SndParam_LookupReadOnly
	cp	hl, 2:i3
	jr z, SndParam028101_SetBit1
	ld xwa, 0x00028101
	call SndParam_LookupReadOnly
	cp	hl, 1:i3
	jr nz, SndParam028101_ResBit1
SndParam028101_SetBit1:
	setm	1, (xiz+4)
	jr t, SndParam028101_Done
SndParam028101_ResBit1:
	.byte 0xbe, 0x04, 0xb1				; res 1, (xiz+4)  [not in LLVM]
SndParam028101_Done:
	pop xiz
	ret
SndParam_SetResBit2_ViaRegs0101_0102:
	; --- Routine 3: 2x FCD437, set/res bit 2 at (xiz+4) (41 bytes) ---
	push xiz
	lda	xiz, (0x8f18:16)
	ld xwa, 0x00028101
	call SndParam_LookupReadOnly
	cp	hl, 2:i3
	jr z, SndParam028102_SetBit2
	ld xwa, 0x00028102
	call SndParam_LookupReadOnly
	cp	hl, 1:i3
	jr nz, SndParam028102_ResBit2
SndParam028102_SetBit2:
	setm	2, (xiz+4)
	jr t, SndParam028102_Done
SndParam028102_ResBit2:
	.byte 0xbe, 0x04, 0xb2				; res 2, (xiz+4)  [not in LLVM]
SndParam028102_Done:
	pop xiz
	ret


SndParam_SetResBit3_ViaRegs0101_0102:
	; --- Routine 1: 2x FCD437, set/res bit 3 at (xiz+4) (41 bytes) ---
	push xiz
	lda	xiz, (0x8f18:16)
	ld xwa, 0x00028101
	call SndParam_LookupReadOnly
	cp	hl, 3:i3
	jr z, SndParam028102_SetBit3
	ld xwa, 0x00028102
	call SndParam_LookupReadOnly
	cp	hl, 2:i3
	jr nz, SndParam028102_ResBit3
SndParam028102_SetBit3:
	setm	3, (xiz+4)
	jr t, SndParam028102_Done2
SndParam028102_ResBit3:
	.byte 0xbe, 0x04, 0xb3				; res 3, (xiz+4)  [not in LLVM]
SndParam028102_Done2:
	pop xiz
	ret
SndParam_SetResBit3_Via4002:
	; --- Routine 2: FCD437(0x4002), set/res bit 3 at (xwa) via xiz+6 (29 bytes) ---
	push xiz
	lda	xiz, (0x8f18:16)
	ld xwa, 0x00004002
	call SndParam_LookupReadOnly
	lda	xwa, (xiz+6)
	cp	hl, 0:i3
	jr z, SndParam4002_ResBit3
	setm	3, (xwa)
	jr t, SndParam4002_Done
SndParam4002_ResBit3:
	.byte 0xb0, 0xb3				; res 3, (xwa)  [not in LLVM]
SndParam4002_Done:
	pop xiz
	ret
SndParam_SetResBit4_Via4004:
	; --- Routine 3: FCD437(0x4004), set/res bit 4 at (xwa) via xiz+6 (29 bytes) ---
	push xiz
	lda	xiz, (0x8f18:16)
	ld xwa, 0x00004004
	call SndParam_LookupReadOnly
	lda	xwa, (xiz+6)
	cp	hl, 0:i3
	jr z, SndParam4004_ResBit4
	setm	4, (xwa)
	jr t, SndParam4004_Done
SndParam4004_ResBit4:
	.byte 0xb0, 0xb4				; res 4, (xwa)  [not in LLVM]
SndParam4004_Done:
	pop xiz
	ret


SndParam_TableLookup_Via4100:
	; --- Routine 1: FCD437(0x4100), table lookup at 0xeda626, nibble merge (39 bytes) ---
	push xiz
	lda	xiz, (0x8f18:16)
	ld xwa, 0x00004100
	call SndParam_LookupReadOnly
	lda xwa, (Protocol_values_for_LED_rows_0x10:24)
	ld_rrb	a, xwa, hl
	and a, 0x07
	sla	a, 4
	andmi8	(xiz+10), 143
	or	(xiz+10), a
	pop xiz
	ret
SndParam_SetResBit1_ViaPartCC5E:
	; --- Routine 2: F9945E+FCD4F7(0x5e), set/res bit 1 at (xwa) via xiz+6 (37 bytes) ---
	push xiz
	lda	xiz, (0x8f18:16)
	call GetCurrentPartSelect
	extz	hl
	ld	wa, hl
	ldw bc, 0x005e
	call SndParam_LookupViaEncode
	lda	xwa, (xiz+6)
	cp hl, 0x007f
	jr nz, SndParamCC5E_ResBit1
	setm	1, (xwa)
	jr t, SndParamCC5E_Done
SndParamCC5E_ResBit1:
	.byte 0xb0, 0xb1				; res 1, (xwa)  [not in LLVM]
SndParamCC5E_Done:
	pop xiz
	ret


SndParam_SetResBit2_ViaPartCC5D:
	; --- Routine 1: 2x F9945E+FCD4F7(0x5d), set/res bit 2 at (xiz+6) (55 bytes) ---
	push xiz
	lda	xiz, (0x8f18:16)
	call GetCurrentPartSelect
	extz	hl
	ld	wa, hl
	ldw bc, 0x005d
	call SndParam_LookupViaEncode
	cp	hl, 0:i3
	jr z, SndParamCC5D_ResBit2
	call GetCurrentPartSelect
	extz	hl
	ld	wa, hl
	ldw bc, 0x005d
	call SndParam_LookupViaEncode
	cp hl, 0xffff
	jr nz, SndParamCC5D_SetBit2
SndParamCC5D_ResBit2:
	resm	2, (xiz+6)
	jr t, SndParamCC5D_Done
SndParamCC5D_SetBit2:
	.byte 0xbe, 0x06, 0xba				; set 2, (xiz+6)  [not in LLVM]
SndParamCC5D_Done:
	pop xiz
	ret
SndParam_SetResBit0_ViaPartCC40:
	; --- Routine 2: F9945E+FCD4F7(0x40), cp 0x7f, set/res bit 0 at (xwa) (37 bytes) ---
	push xiz
	lda	xiz, (0x8f18:16)
	call GetCurrentPartSelect
	extz	hl
	ld	wa, hl
	ldw bc, 0x0040
	call SndParam_LookupViaEncode
	lda	xwa, (xiz+6)
	cp hl, 0x007f
	jr nz, SndParamCC40_ResBit0
	setm	0, (xwa)
	jr t, SndParamCC40_Done
SndParamCC40_ResBit0:
	.byte 0xb0, 0xb0				; res 0, (xwa)  [not in LLVM]
SndParamCC40_Done:
	pop xiz
	ret
SndParam_GuardedNibbleSet_ViaReg0103:
	; --- Routine 3: complex bit checks, and (xiz+0x0e), set 0 in A (59 bytes) ---
	push xiz
	lda	xiz, (0x8f18:16)
	bit	2, (1054:16)
	jr nz, MidiCtrl_PopIzRet
	ld xwa, 0x00028103
	call SndParam_LookupReadOnly
	cp	hl, 0:i3
	jr nz, MidiCtrl_PopIzRet
	andmi8	(xiz+14), 240
	bit	2, (1057:16)
	jr z, MidiCtrl_PopIzRet
	lds32	xwa, 1
	call SndParam_LookupReadOnly
	cp	hl, 1:i3
	jr nz, MidiCtrl_PopIzRet
	lda	xbc, (xiz+14)
	ld a, (xbc)
	and a, 0xf0
	set 0, a
	ld (xbc), a
MidiCtrl_PopIzRet:
	pop xiz
	ret
SndParam_SetResBit0_Via028103:
	; --- Routine 4: FCD437(0x028103), set/res bit 0 at (xwa) via xiz+0x0d (29 bytes) ---
	push xiz
	lda	xiz, (0x8f18:16)
	ld xwa, 0x00028103
	call SndParam_LookupReadOnly
	lda	xwa, (xiz+13)
	cp	hl, 1:i3
	jr nz, SndParam028103_ResBit0
	setm	0, (xwa)
	jr t, SndParam028103_Done
SndParam028103_ResBit0:
	.byte 0xb0, 0xb0				; res 0, (xwa)  [not in LLVM]
SndParam028103_Done:
	pop xiz
	ret
SndParam_SetResBit5_Via028080:
	; --- Routine 5: FCD437(0x028080), set/res bit 5 at (xwa) via xiz+3 (29 bytes) ---
	push xiz
	lda	xiz, (0x8f18:16)
	ld xwa, 0x00028080
	call SndParam_LookupReadOnly
	lda	xwa, (xiz+3)
	cp	hl, 0:i3
	jr nz, SndParam028080_SetBit5
	resm	5, (xwa)
	jr t, SndParam028080_Done
SndParam028080_SetBit5:
	.byte 0xb0, 0xbd				; set 5, (xwa)  [not in LLVM]
SndParam028080_Done:
	pop xiz
	ret


SndParam_VoiceEntryLookup_ViaReg8000:
	; --- Routine 1: stack frame, 3x FCD437 lookup, nibble merge (91 bytes) ---
	dec 6, xsp
	push xiz
	lda	xiz, (0x8f18:16)
	ld (xsp+6), 0x48
	ld xwa, 0x00028000
	call SndParam_LookupReadOnly
	ld (xsp+7), l
	ld xwa, 0x00028001
	call SndParam_LookupReadOnly
	lda	xwa, (xsp+4)
	ld (xwa+4), l
	call SndParam_ResolveVoiceEntry
	lda	xwa, (xsp+4)
	cp (xwa), 0x0e
	jr nc, SndParam028000_GetBankBit
	ld xwa, 0x00028002
	call SndParam_LookupReadOnly
	extz	hl
	ld	wa, hl
	jr t, SndParam028000_LookupAndMerge
SndParam028000_GetBankBit:
	ld a, (xwa+1)
	and a, 0x03
	extz wa
SndParam028000_LookupAndMerge:
	call CtrlPanel_LookupIndicatorEntry
	and l, 0x0f
	andmi8	(xiz+3), 240
	or (xiz+3), l
	pop xiz
	inc 6, xsp
	ret
SndParam_SetResBit7_Via4200:
	; --- Routine 2: FCD437(0x4200), set/res bit 7 at (xwa) via xiz+0x0a (29 bytes) ---
	push xiz
	lda	xiz, (0x8f18:16)
	ld xwa, 0x00004200
	call SndParam_LookupReadOnly
	lda	xwa, (xiz+10)
	cp	hl, 1:i3
	jr nz, SndParam4200_ResBit7
	setm	7, (xwa)
	jr t, SndParam4200_Done
SndParam4200_ResBit7:
	.byte 0xb0, 0xb7				; res 7, (xwa)  [not in LLVM]
SndParam4200_Done:
	pop xiz
	ret
SndParam_MaskShiftMerge_8F58:
	; --- Routine 3: read (0x8f58), mask+shift, merge into (0x8f1c) (20 bytes) ---
	ld	a, (0x8f58:16)
	and a, 0x07
	sla	a, 4
	and	(0x8f1c:16), 143
	or	(0x8f1c:16), a
	ret
SndParam_DecrLookup_Via0300:
	; --- Routine 4: FCD437(0x300), decrement+mask+lookup via FC7C23 (40 bytes) ---
	push xiz
	lda	xiz, (0x8f18:16)
	ld xwa, 0x00000300
	call SndParam_LookupReadOnly
	cp	hl, 0:i3
	jr nz, SndParam0300_DecrAndMask
	ldb l, 0x00
	jr t, SndParam0300_StoreLookup
SndParam0300_DecrAndMask:
	dec 1, l
	and l, 0x07
	extz	hl
	ld	wa, hl
	call CtrlPanel_LookupIndicatorEntry
SndParam0300_StoreLookup:
	ld (xiz+9), l
	pop xiz
	ret


SndParam_SetResBit4_Via0400:
	; --- Routine 1: call FCD437, set/res bit 4 based on HL (29 bytes) ---
	push xiz
	lda	xiz, (0x8f18:16)
	ld xwa, 0x00000400
	call SndParam_LookupReadOnly
	lda	xwa, (xiz+3)
	cp	hl, 1:i3
	jr nz, SndParam0400_ResBit4
	setm	4, (xwa)
	jr t, SndParam0400_Done
SndParam0400_ResBit4:
	.byte 0xb0, 0xb4				; res 4, (xwa)  [not in LLVM]
SndParam0400_Done:
	pop xiz
	ret
SndParam_SetResBit7_ViaSelection:
	; --- Routine 2: call F99439, 3-way cp HL, set/res bit 7 (29 bytes) ---
	push xiz
	lda	xiz, (0x8f18:16)
	call CtrlPanel_GetSelectionState
	cp	hl, 2:i3
	jr z, CtrlPanel_SetResBit7_Ret
	cp	hl, 1:i3
	jr z, SndParamSelect_SetBit7
	cp	hl, 0:i3
	jr nz, CtrlPanel_SetResBit7_Ret
	resm	7, (xiz)
	jr t, CtrlPanel_SetResBit7_Ret
SndParamSelect_SetBit7:
	.byte 0xb6, 0xbf				; set 7, (xiz)  [not in LLVM]
CtrlPanel_SetResBit7_Ret:
	pop xiz
	ret
SndParam_SetResBit7_ViaF9A541:
	; --- Routine 3: call F9A541, set/res bit 7 based on HL (24 bytes) ---
	push xiz
	lda	xiz, (0x8f18:16)
	call GetDialEnableState
	lda	xwa, (xiz+4)
	cp	hl, 0:i3
	jr z, SndParamF9A541_ResBit7
	setm	7, (xwa)
	jr t, SndParamF9A541_Done
SndParamF9A541_ResBit7:
	.byte 0xb0, 0xb7				; res 7, (xwa)  [not in LLVM]
SndParamF9A541_Done:
	pop xiz
	ret


ExtData_VoiceParam_DispatchBytecode:
	push	xiz
	lda	xiz, (0x8f18:16)
	lda	xbc, (xiz+2)
	.byte 0xb1, 0xb7, 0xb6, 0xb1, 0xb6, 0xb2, 0xb6, 0xb4
	lda	xhl, (xiz+10)
	.byte 0xb3, 0xb3
	lda	xde, (xiz+6)
	.byte 0xb2, 0xb6, 0xb2, 0xb7
	lda	xiy, (xiz+11)
	.byte 0xb5, 0xb0, 0xb5, 0xb1, 0xb5, 0xb2, 0xb5, 0xb3
	ld	a, (0x8d34:16)
	extz	wa
	dec	2, wa
	cp	wa, 0:i3
	jr	lt, 88
	cp	wa, 16
	jr	gt, 82
	add	wa, wa
	lda	xix, (Protocol_values_for_LED_rows_0x16:24)
	.byte 0xd3
	reti
	.byte 0xf0, 0xe0
	ldb	w, 242
	jr	117
	swi	4
	ldw	ix, 2035
	.byte 0xf0, 0xe0
	sbc	bc, wa
	.byte 0xbf
	jr	56
	ldb	a, 1
	jr	49
	ldb	a, 2
	jr	45
	.byte 0xb2, 0xbf
	jr	44
	ld	xwa, xde
	.byte 0xb2, 0xbf, 0xc1
	swi	4
	ldb	h, 63
	normal
	jr	nz, 33
	.byte 0xb0, 0xbe
	jr	29
	.byte 0xb2, 0xbe
	jr	25
	.byte 0xb5, 0xb8
	jr	21
	.byte 0xb5, 0xba
	jr	17
	.byte 0xb5, 0xb9
	jr	13
	.byte 0xb5, 0xbb
	jr	9
	.byte 0xb3, 0xbb
	jr	5
	ldb	a, 4
	scf
	.byte 0xb6
	pushw	ix
	pop	xiz
	ret
	lda	xwa, (0x8f18:16)
	.byte 0xc1, 0x90
	ldw	hl, 63
	jr	z, 3
	.byte 0xb0, 0xbb
	ret
	.byte 0xb0, 0xb3
	ret
	lda	xwa, (0x8f1e:16)
	.byte 0xb0, 0xb5, 0xf1, 0xa5
	pushw	wa
	sbc	w, w
	.byte 0xf6
	ld	c, (0x8d34:16)
	cp	c, 13
	ret	z
	cp	c, 12
	ret	z
	cp	c, 11
	ret	z
	cp	c, 9
	ret	z
	cp	c, 8
	ret	z
	.byte 0xb0, 0xbd
	ret
	lda	xsp, (xsp-10)
	push	xiz
	lda	xwa, (0x8f18:16)
	ld	(xsp+4), xwa
	ld	(xwa+7), 0
	ld	xwa, (xsp+4)
	ld	(xwa+8), 0
	.byte 0x88
	incf
	push	xix
	swi	4
	call	GetCurrentPartSelect
	extz	hl
	ld	wa, hl
	lds	bc, 0
	call	SndParam_LookupViaEncode
	ld	(xsp+11), l
	call	GetCurrentPartSelect
	extz	hl
	ld	wa, hl
	ldw	bc, 32
	call	SndParam_LookupViaEncode
	ld	(xsp+12), l
	call	GetCurrentPartSelect
	lda	xwa, (xsp+8)
	ld	(xwa+2), l
	call	SndParam_ResolveVoiceEntry
	lda	xwa, (xsp+8)
	.byte 0x80
	push	xsp
	reti
	jr	ugt, 8
	ld	a, (xwa)
	extz	wa
	lds32	xiz, 7
	jr	16
	.byte 0x80
	push	xsp
	retd	6251
	ld	a, (xwa)
	dec	8, a
	extz	wa
	ld	xiz, 8
	call	CtrlPanel_LookupIndicatorEntry
	ld	xwa, (xsp+4)
	add	xwa, xiz
	ld	(xwa), l
	jr	38
	.byte 0x80
	push	xsp
	scf
	jr	ugt, 26
	ld	a, (xwa)
	sub	a, 16
	extz	wa
	call	CtrlPanel_LookupIndicatorEntry
	ld	xwa, (xsp+4)
	and	l, 3
	.byte 0x88
	incf
	push	xix
	swi	4
	or	(xwa+12), l
	jr	7
	ld	xwa, (xsp+4)
	ld	(xwa+7), 1
	pop	xiz
	lda	xsp, (xsp+10)
	ret
	dec	6, xsp
	push	xiz
	lda	xiz, (0x8f18:16)
	.byte 0xb6, 0xb0
	ld	(xiz+1), 0
	.byte 0x8e
	push	sr
	push	xix
	.byte 0x80
	ld	xwa, 0x028000
	call	SndParam_LookupReadOnly
	ld	(xsp+7), l
	ld	xwa, 0x028001
	call	SndParam_LookupReadOnly
	lda	xwa, (xsp+4)
	ld	(xwa+4), l
	ld	(xwa+2), 72
	call	SndParam_ResolveVoiceEntry
	lda	xwa, (xsp+4)
	.byte 0x80
	push	xsp
	.byte 0x06
	jr	ugt, 20
	ld	a, (xwa)
	extz	wa
	call	CtrlPanel_LookupIndicatorEntry
	res	7, l
	.byte 0x8e
	push	sr
	push	xix
	add	(xwa), h
	push	sr
	dec	8, xsp
	pushw	de
	.byte 0x80
	push	xsp
	ret
	jr	ugt, 15
	ld	a, (xwa)
	dec	7, a
	extz	wa
	call	CtrlPanel_LookupIndicatorEntry
	ld	(xiz+1), l
	jr	22
	.byte 0x80
	push	xsp
	retd	1134
	.byte 0xb6, 0xb8
	jr	13
	lda	xbc, (xiz+2)
	ld	a, (xbc)
	and	a, 128
	set	0, a
	ld	(xbc), a
	pop	xiz
	inc	6, xsp
	ret
	push	xiz
	lda	xiz, (0x8f18:16)
	call	GetCurrentPartSelect
	lda	xbc, (xiz+10)
	ld	a, (xbc)
	cp	l, 2:i3
	jr	z, 28
	cp	l, 1:i3
	jr	z, 14
	cp	l, 0:i3
	jr	nz, 30
	and	a, 248
	set	2, a
	ld	(xbc), a
	jr	23
	and	a, 248
	set	1, a
	ld	(xbc), a
	jr	13
	and	a, 248
	set	0, a
	ld	(xbc), a
	jr	3
	.byte 0x81
	push	xix
	swi	0
	pop	xiz
	ret
	push	xiz
	lda	xiz, (0x8f18:16)
	ld	xwa, 0x40c0
	call	SndParam_LookupReadOnly
	cp	hl, 1:i3
	jr	nz, 4
	.byte 0xb6, 0xbd
	jr	2
	.byte 0xb6, 0xb5
	pop	xiz
	ret
CtrlPanel_SetResBit6_ViaLookup:
	; --- Sub 1: set/res bit 6 of (XIZ) via FCD437 lookup (26 bytes) ---
	push xiz
	lda	xiz, (0x8f18:16)
	ld xwa, 0x000040c1
	call SndParam_LookupReadOnly
	cp	hl, 1:i3
	jr nz, CtrlPanel_ResBit6
	setm	6, (xiz)
	jr t, CtrlPanel_Bit6Done
CtrlPanel_ResBit6:
	.byte 0xb6, 0xb6				; res 6, (xiz)  [not in LLVM]
CtrlPanel_Bit6Done:
	pop xiz
	ret
CtrlPanel_MultiWayBitManip_ViaE0:
	; --- Sub 2: multi-way HL compare, and/set bits at (XBC+0x0d) (74 bytes) ---
	push xiz
	lda	xiz, (0x8f18:16)
	ld xwa, 0x000040e0
	call SndParam_LookupReadOnly
	lda	xbc, (xiz+13)
	ld a, (xbc)
	cp hl, 0x0058
	jr z, CtrlPanel_SetBit2
	cp hl, 0x004c
	jr z, CtrlPanel_SetBit2
	cp hl, 0x0040
	jr z, CtrlPanel_ClearBits1_2
	cp hl, 0x0034
	jr z, CtrlPanel_SetBit1
	cp hl, 0x0028
	jr nz, CtrlPanel_BitManip_Ret
CtrlPanel_SetBit1:
	and a, 0xf9
	set 1, a
	ld (xbc), a
	jr t, CtrlPanel_BitManip_Ret
CtrlPanel_ClearBits1_2:
	andmi8	(xbc), 249
	jr t, CtrlPanel_BitManip_Ret
CtrlPanel_SetBit2:
	and a, 0xf9
	set 2, a
	ld (xbc), a
CtrlPanel_BitManip_Ret:
	pop xiz
	ret
CtrlPanel_SyncBit0_From8F5C:
	; --- Sub 3: set/res bit 0 at (0x8f1d) based on bit 0 of (0x8f5c) (16 bytes) ---
	lda	xwa, (0x8f1d:16)
	bit	0, (0x8f5c:16)
	jr z, CtrlPanel_ResBit0_8F5C
	setm	0, (xwa)
	ret
CtrlPanel_ResBit0_8F5C:
	resm	0, (xwa)
	ret
CtrlPanel_SetBit3_OnStyleD0D3:
	; --- Sub 4: conditionally set bit 3 at (0x8f25) based on (0x8d38) (33 bytes) ---
	lda	xwa, (0x8f25:16)
	resm	3, (xwa)
	ld	c, (0x8d38:16)
	cp c, 0xd3
	jr z, CtrlPanel_SetBit3
	cp c, 0xd2
	jr z, CtrlPanel_SetBit3
	cp c, 0xd1
	jr z, CtrlPanel_SetBit3
	cp c, 0xd0
	ret nz
CtrlPanel_SetBit3:
	setm	3, (xwa)
	ret
CtrlPanel_SetResBit0_ViaLookup4:
	; --- Sub 5: set/res bit 0 at (XIZ+4) via FC7C23 + (0x8f54) lookup (34 bytes) ---
	push xiz
	lda	xiz, (0x8f18:16)
	ld	a, (0x8f54:16)
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	and	l, (0x8f4a:16)
	lda	xwa, (xiz+4)
	cp	l, 0:i3
	jr z, CtrlPanelLookup4_ResBit0
	setm	0, (xwa)
	jr t, CtrlPanelLookup4_Done
CtrlPanelLookup4_ResBit0:
	.byte 0xb0, 0xb0				; res 0, (xwa)  [not in LLVM]
CtrlPanelLookup4_Done:
	pop xiz
	ret
CtrlPanel_SetResBit1_ViaLookup56:
	; --- Sub 6: set/res bit 1 at (XIZ+4) via FC7C23 + (0x8f56) lookup (34 bytes) ---
	push xiz
	lda	xiz, (0x8f18:16)
	ld	a, (0x8f56:16)
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	and	l, (0x8f4a:16)
	lda	xwa, (xiz+4)
	cp	l, 0:i3
	jr z, CtrlPanelLookup56_ResBit1
	setm	1, (xwa)
	jr t, CtrlPanelLookup56_Done
CtrlPanelLookup56_ResBit1:
	.byte 0xb0, 0xb1				; res 1, (xwa)  [not in LLVM]
CtrlPanelLookup56_Done:
	pop xiz
	ret
CtrlPanel_SetResBit2_ViaLookup50:
	; --- Sub 7: set/res bit 2 at (XIZ+4) via FC7C23 + (0x8f50) lookup (34 bytes) ---
	push xiz
	lda	xiz, (0x8f18:16)
	ld	a, (0x8f50:16)
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	and	l, (0x8f4a:16)
	lda	xwa, (xiz+4)
	cp	l, 0:i3
	jr z, CtrlPanelLookup50_ResBit2
	setm	2, (xwa)
	jr t, CtrlPanelLookup50_Done
CtrlPanelLookup50_ResBit2:
	.byte 0xb0, 0xb2				; res 2, (xwa)  [not in LLVM]
CtrlPanelLookup50_Done:
	pop xiz
	ret
CtrlPanel_SetResBit3_ViaLookup52:
	; --- Sub 8: set/res bit 3 at (XIZ+4) via FC7C23 + (0x8f52) lookup (34 bytes) ---
	push xiz
	lda	xiz, (0x8f18:16)
	ld	a, (0x8f52:16)
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	and	l, (0x8f4a:16)
	lda	xwa, (xiz+4)
	cp	l, 0:i3
	jr z, CtrlPanelLookup52_ResBit3
	setm	3, (xwa)
	jr t, CtrlPanelLookup52_Done
CtrlPanelLookup52_ResBit3:
	.byte 0xb0, 0xb3				; res 3, (xwa)  [not in LLVM]
CtrlPanelLookup52_Done:
	pop xiz
	ret
CtrlPanel_GuardedNibbleSet_8F4E:
	; --- Sub 9: guarded nibble set/res at (XIZ+0x0e) via (0x8f4e) lookup (76 bytes) ---
	push xiz
	lda	xiz, (0x8f18:16)
	bit	2, (1054:16)
	jr nz, CtrlPanel_BitOp_Cleanup
	ld xwa, 0x00028103
	call SndParam_LookupReadOnly
	cp	hl, 0:i3
	jr z, CtrlPanelGuard_PassedCheck
	cp	(0x8d34:16), 19
	jr z, CtrlPanelGuard_PassedCheck
	cp	(0x7f0b:16), 0
	jr z, CtrlPanel_BitOp_Cleanup
CtrlPanelGuard_PassedCheck:
	ld	a, (0x8f4e:16)
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	and	l, (0x8f4a:16)
	lda	xwa, (xiz+14)
	cp	l, 0:i3
	jr z, CtrlPanelGuard_ClearNibble
	ld c, (xwa)
	and c, 0xf0
	set 0, c
	ld (xwa), c
	jr t, CtrlPanel_BitOp_Cleanup
CtrlPanelGuard_ClearNibble:
	.byte 0x80
	push	xix
	.byte 0xf0
CtrlPanel_BitOp_Cleanup:
	pop xiz
	ret
CtrlPanel_SetResBit0_ViaLookup4C:
	; --- Sub 10: set/res bit 0 at (XIZ+0x0d) via FC7C23 + (0x8f4c) lookup (34 bytes) ---
	push xiz
	lda	xiz, (0x8f18:16)
	ld	a, (0x8f4c:16)
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	and	l, (0x8f4a:16)
	lda	xwa, (xiz+13)
	cp	l, 0:i3
	jr z, CtrlPanelLookup4C_ResBit0
	setm	0, (xwa)
	jr t, CtrlPanelLookup4C_Done
CtrlPanelLookup4C_ResBit0:
	.byte 0xb0, 0xb0				; res 0, (xwa)  [not in LLVM]
CtrlPanelLookup4C_Done:
	pop xiz
	ret
CtrlPanel_SetResBit7_ViaLookup4C:
	; --- Sub 11: set/res bit 7 of (XIZ) via FC7C23 + (0x8f4c) lookup (29 bytes) ---
	push xiz
	lda	xiz, (0x8f18:16)
	ld	a, (0x8f4c:16)
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	and	l, (0x8f4a:16)
	jr z, CtrlPanelBit7_Res
	setm	7, (xiz)
	jr t, CtrlPanelBit7_Done
CtrlPanelBit7_Res:
	.byte 0xb6, 0xb7				; res 7, (xiz)  [not in LLVM]
CtrlPanelBit7_Done:
	pop xiz
	ret
CtrlPanel_SetResBit5_ViaLookup4C:
	; --- Sub 12: set/res bit 5 of (XIZ) via FC7C23 + (0x8f4c) lookup (29 bytes) ---
	push xiz
	lda	xiz, (0x8f18:16)
	ld	a, (0x8f4c:16)
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	and	l, (0x8f4a:16)
	jr z, CtrlPanelBit5_Res
	setm	5, (xiz)
	jr t, CtrlPanelBit5_Done
CtrlPanelBit5_Res:
	.byte 0xb6, 0xb5				; res 5, (xiz)  [not in LLVM]
CtrlPanelBit5_Done:
	pop xiz
	ret
CtrlPanel_SetResBit6_ViaLookup4C:
	; --- Sub 13: set/res bit 6 of (XIZ) via FC7C23 + (0x8f4c) lookup (29 bytes) ---
	push xiz
	lda	xiz, (0x8f18:16)
	ld	a, (0x8f4c:16)
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	and	l, (0x8f4a:16)
	jr z, CtrlPanelBit6_Res
	setm	6, (xiz)
	jr t, CtrlPanelBit6_Done
CtrlPanelBit6_Res:
	.byte 0xb6, 0xb6				; res 6, (xiz)  [not in LLVM]
CtrlPanelBit6_Done:
	pop xiz
	ret


; ============================================================================
; CtrlPanel_SetIndicatorBit - Set a control panel LED indicator bit
; ============================================================================
; Input:  A = key code (upper nibble=group, lower nibble=bit index)
; Output: ORs bitmask into panel LED register (36666/36670/36674/36678)
; Looks up bitmask from table at 0xeda66c.
; ============================================================================
CtrlPanel_SetIndicatorBit:
	pushw_erp 0xfa
	ld c, a
	and c, 0xf0
	ldb_erp C, 0xfb
	and a, 0xf
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	cp_erpb 0xfb, 0x60
	jr z, CtrlPanel_SetIndicator_Group4
	cp_erpb 0xfb, 0x40
	jr z, CtrlPanel_SetIndicator_Group3
	cp_erpb 0xfb, 0x20
	jr z, CtrlPanel_SetIndicator_Group2
	cpib_erp 0xfb, 0
	jr nz, CtrlPanel_PopRetFA
	or (0x8f3a:16), hl
	jr CtrlPanel_PopRetFA

CtrlPanel_SetIndicator_Group2:
	or (0x8f3e:16), hl
	jr CtrlPanel_PopRetFA

CtrlPanel_SetIndicator_Group3:
	or (0x8f42:16), hl
	jr CtrlPanel_PopRetFA

CtrlPanel_SetIndicator_Group4:
	or (0x8f46:16), hl

CtrlPanel_PopRetFA:
	popw_erp 0xfa
	ret

CtrlPanel_IndicatorDispatch:
	pushw_erp 0xfa
	ld c, a
	and c, 0xf0
	ldb_erp C, 0xfb
	and a, 0xf
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	cp_erpb 0xfb, 0x60
	jr z, CtrlPanel_DispIndicator_Group4
	cp_erpb 0xfb, 0x40
	jr z, CtrlPanel_DispIndicator_Group3
	cp_erpb 0xfb, 0x20
	jr z, CtrlPanel_DispIndicator_Group2
	cpib_erp 0xfb, 0
	jr nz, CtrlPanel_PopRetFA2
	or (0x8f3c:16), hl
	jr CtrlPanel_PopRetFA2

CtrlPanel_DispIndicator_Group2:
	or (0x8f40:16), hl
	jr CtrlPanel_PopRetFA2

CtrlPanel_DispIndicator_Group3:
	or (0x8f44:16), hl
	jr CtrlPanel_PopRetFA2

CtrlPanel_DispIndicator_Group4:
	or (0x8f48:16), hl

CtrlPanel_PopRetFA2:
	popw_erp 0xfa
	ret

CtrlPanel_SetIndicatorLED:
	pushw_erp 0xfa
	ld c, a
	and c, 0xf0
	ldb_erp C, 0xfb
	and a, 0xf
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	ld wa, hl
	cpl wa
	cp_erpb 0xfb, 0x40
	jr z, CtrlPanel_SetLED_Group3
	cp_erpb 0xfb, 0x20
	jr z, CtrlPanel_SetLED_Group2
	cpib_erp 0xfb, 0
	jr nz, MidiChOutState_Return
	and (0x8f3c:16), wa
	or (0x8f3a:16), hl
	jr MidiChOutState_Return

CtrlPanel_SetLED_Group2:
	and (0x8f40:16), wa
	or (0x8f3e:16), hl
	jr MidiChOutState_Return

CtrlPanel_SetLED_Group3:
	and (0x8f44:16), wa
	or (0x8f42:16), hl

MidiChOutState_Return:
	popw_erp 0xfa
	ret

MidiChannel_ProcessOutputState:
	push xiz
	lda xiz, (0x8f18:16)
	calr MidiChOut_DetectChanges
	lda xde, (xiz + 14)
	ld c, (0x8e76:16)
	bit 2, (1054:16)
	jr nz, MidiChOut_CheckHWState
	ld a, c
	bit 1, c
	jr z, MidiChannel_CleanupRet
	res 1, a
	ld (0x8e76:16), a
	jr MidiChOut_ClearLowNibble

MidiChOut_CheckHWState:
	ld l, (1046:16)
	ld a, (1045:16)
	and a, 0x60
	jr nz, MidiChOut_CheckBit1Clear
	set 1, (0x8e76:16)
	ld a, (1075:16)
	cp a, 6:i3
	jr z, MidiChOut_Mode6or3_Mask7
	cp a, 3:i3
	jr nz, MidiChOut_OtherMode_Mask3

MidiChOut_Mode6or3_Mask7:
	and l, 0x7
	ld xwa, Protocol_values_for_LED_rows_0x38
	jr MidiChOut_TableLookup

MidiChOut_OtherMode_Mask3:
	and l, 0x3
	ld xwa, Protocol_values_for_LED_rows_0x3E

MidiChOut_TableLookup:
	extz hl
	ldb_sri A, 0x07, 0xe0, 0xec
	and a, 0xf
	andmi8 (xde), 0xf0
	or (xde), a
	jr MidiChannel_CleanupRet

MidiChOut_CheckBit1Clear:
	ld a, c
	bit 1, c
	jr z, MidiChannel_CleanupRet
	res 1, a
	ld (0x8e76:16), a

MidiChOut_ClearLowNibble:
	andmi8 (xde), 0xf0

MidiChannel_CleanupRet:
	pop xiz
	ret

MidiChOut_DetectChanges:
	bit 2, (1054:16)
	ret nz
	ld a, (1056:16)
	xor a, (0x347b:16)
	bit 2, a
	ret z
	orw (0x8f3e:16), 4
	ldmm8 0x347b, 1056
	ret

MidiChannel_ScanPending:
	push xiz
	lda xiz, (0x8f18:16)
	ld wa, (0x8f40:16)
	bit 2, wa
	jr nz, MidiScan_PopIzRet
	ld a, (0x8f4a:16)
	and a, 0x3
	jr nz, MidiScan_PopIzRet
	bit 2, (1054:16)
	jr nz, MidiScan_PopIzRet
	bit 2, (0x28a7:16)
	jr nz, MidiScan_AltPathCheck
	ld xwa, 0x28103
	call SndParam_LookupReadOnly
	lda xbc, (xiz + 14)
	cp hl, 1:i3
	jr nz, MidiScan_CheckBit2InAddr1057
	ld wa, (1039:16)
	bit 6, wa
	jr nz, MidiScan_ClearAndReturn
	ld a, (xbc)
	and a, 0xf0
	set 0, a
	ld (xbc), a
	jr MidiScan_PopIzRet

MidiScan_CheckBit2InAddr1057:
	bit 2, (1057:16)
	jr nz, MidiScan_PopIzRet

MidiScan_ClearAndReturn:
	andmi8 (xbc), 0xf0
	jr MidiScan_PopIzRet

MidiScan_AltPathCheck:
	bit 2, (1057:16)
	jr nz, MidiScan_PopIzRet
	andmi8 (xiz + 14), 0xf0

MidiScan_PopIzRet:
	pop xiz
	ret

; ============================================================================
; UIState_UpdateControlBits - Update UI state control bit flags
; ============================================================================
; Input:  Control parameters from caller
; Output: Updated control bit state
; Modifies the UI state control flags that govern which UI elements are
; active and which input modes are enabled.
; ============================================================================
UIState_UpdateControlBits:
	ld	a, (0xc07d:16)
	cp	a, 5:i3
	jr	z, 22
	cp	a, 4:i3
	jr	z, 11
	cp	a, 0:i3
	ret	nz
	.byte 0xd1
	push	xde
	decm8	1, (xsp+62)
	nop
	ret
	.byte 0xd1
	push	xde
	.byte 0x8f
	push	xiz
	pushw	wa
	nop
	ret
	.byte 0xd1
	push	xde
	.byte 0x8f
	push	xiz
	.byte 0x40
	nop
	ret
UIState_SwitchOnDisplayMode:
	; --- Switch on A = (0xc07d): or bits into (0x8f3a)/(0x8f42) (53 bytes) ---
	ld	a, (0xc07d:16)
	cp	a, 4:i3
	jr z, UIState_Mode4
	cp	a, 3:i3
	jr z, UIState_Mode3
	cp	a, 1:i3
	jr z, UIState_Mode0or1
	cp	a, 0:i3
	jr z, UIState_Mode0or1
	cp a, 0x10
	ret nz
	orw	(0x8f3a:16), 107
	ret
UIState_Mode0or1:
	orw	(0x8f3a:16), 111
	ret
UIState_Mode3:
	orw	(0x8f42:16), 512
	ret
UIState_Mode4:
	orw	(0x8f42:16), 0x8000
	ret


UIState_ProcessExtendedMode:
	ld	a, (0xc07d:16)
	extz	wa
	cp	wa, 0:i3
	ret	mi
	cp	wa, 7:i3
	ret	gt
	add	wa, wa
	lda	xix, (Protocol_values_for_LED_rows_0x46:24)
	ld_rrw wa, xix, wa
	lda xix, (16546693:24)
	.byte 0xf3
	reti
	.byte 0xf0, 0xe0
	xor	bc, wa
	push	xiz
	.byte 0x8f
	push	xiz
	pop	sr
	push	sr
	ret
	.byte 0xd1
	push	xiz
	cp	(xsp+62), d
	nop
	ret
	ld	xwa, 0x028080
	call	SndParam_LookupReadOnly
	cp	l, 0:i3
	jr	z, 5
	ld	(0xffc8:24), l
	.byte 0xd1
	push	xiz
	.byte 0x8f
	push	xiz
	nop
	normal
	ret
	.byte 0xd1
	ld	xde, 0x103e8f
	ret
	.byte 0xd1
	push	xiz
	.byte 0x8f
	push	xiz
	nop
	push	sr
	ret
UIStateEvt_NullHandler:
	ret
UIState_SwitchForMidiFlags:
	; --- Switch on A = (0xc07d): or bits into (0x8f42) (51 bytes) ---
	ld	a, (0xc07d:16)
	cp a, 0x14
	jr z, UIState_MidiMode14
	cp	a, 4:i3
	jr z, UIState_MidiMode4
	cp a, 0x3f
	jr z, UIState_MidiMode3F
	cp	a, 6:i3
	ret nz
UIState_MidiMode6:
	orw	(0x8f42:16), 1024
	ret
UIState_MidiMode3F:
	orw	(0x8f42:16), 2048
	ret
UIState_MidiMode4:
	orw	(0x8f42:16), 2
	ret
UIState_MidiMode14:
	orw	(0x8f42:16), 4096
	ret
UIState_NullReturn:
	ret


UIState_ProcessAltMode:
	ld	a, (0xc07d:16)
	cp	a, 11
	jr	z, 22
	cp	a, 3:i3
	jr	z, 11
	cp	a, 1:i3
	ret	nz
	.byte 0xd1
	ld	xde, 0x033e8f
	ret
	.byte 0xd1
	ld	xde, 0x083e8f
	ret
	.byte 0xd1
	ld	xde, 0x60003e8f
	ret
UIState_ProcessSimpleMode:
	ld	a, (0xc07d:16)
	cp	a, 1:i3
	ret	nz
	.byte 0xd1
	push	xde
	.byte 0x8f
	push	xiz
	.byte 0x90
	nop
	ret

CtrlPanel_LookupIndicatorEntry:
	extz wa
	sla wa, 2
	lda xbc, (Protocol_values_for_LED_rows_0x56:24)
	ld_sril3 XHL, 0x07, 0xe4, 0xe0
	ret

Util_FindLowestSetBit:
	lds hl, 0
	or xwa, xwa
	ret z
	bit 0, wa
	ret nz

FindBit_ShiftLoop:
	srl xwa, 1
	inc 1, hl
	bit 0, wa
	jr z, FindBit_ShiftLoop
	ret

Audio_InitAllDefaults:
	ld (0xc039:16), 255
	ld (0xbd3c:16), 255
	ldw (0x90de:16), 0
	ldw (0x90e0:16), 0
	ld (0xbf39:16), 255
	ldw (0x90e2:16), 0
	ldw (0x9133:16), 0
	ld (0x90fb:16), 255
	ld (0x91ad:16), 255
	ld (0x91b5:16), 255
	ld (0x91d2:16), 255
	ld (0x90f8:16), 127
	ld (0x8f63:16), 255
	lda xwa, (SoundProgram_DispatchTable_0x400:24)
	ld (0x90f2:16), xwa
	lda xwa, (SoundProgram_DispatchTable_0x800:24)
	ld (0x9182:16), xwa
	lda xbc, (0x918d:16)
	ld xwa, xbc
	lda xbc, (xbc + 31)

AudioInit_FillLoop:
	stib_dsp 0xe0, 0x50
	cp xwa, xbc
	jr ule, AudioInit_FillLoop
	call ToneGen_FlashVerify
	jp DSPCfg_Param_CaseB

Audio_ResetAfterPayloadError:
	call SubCPU_Payload_GetErrorFlag
	cp hl, 0xffff
	jr nz, Audio_ReinitToneGen
	cp (0x8d36:16), 65
	jr nz, Audio_ReinitDisplay
	ld xwa, 0xc0
	call SndParam_LookupReadOnly
	cp hl, 1:i3
	jr nz, Audio_ReinitDisplay
	ld xwa, 0xc0
	lds bc, 0
	lds de, 1
	call SoundParam_NotifyChange
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz
	pop xix
	pop xhl
	pop xde

Audio_ReinitDisplay:
	calr Display_SetupAndPrepareRender
	calr Display_CopyAndRenderBitmaps
	call MainTitle_SetBootFlag

Audio_ReinitToneGen:
	push xde
	push xhl
	push xix
	push xiz
	call ToneGen_ApplyMaskTable
	call ToneGen_Config_InitAndChannels
	call ToneGen_InitAllChannelEntries_Skip
	call ToneGen_DSPCfg_Initialize
	pop xiz
	pop xix
	pop xhl
	pop xde
	calr MidiMsg_ParseChannelStream
	calr Audio_InitAllChannelParams
	call SeqTimer_UpdateTempoReg
	calr Audio_FillParamBuffer
	jp CompIface_SetMax

Audio_FillParamBuffer:
	lda xbc, (0x918d:16)
	ld xwa, xbc
	lda xbc, (xbc + 31)

AudioFill_Loop:
	stib_dsp 0xe0, 0x50
	cp xwa, xbc
	jr ule, AudioFill_Loop
	ret

Audio_JumpTrampoline:
	jr	t, 0x82

Audio_ReinitToneGenAndOutput:
	push xde
	push xhl
	push xix
	push xiz
	call ToneGen_ApplyMaskTable
	call ToneGen_Config_InitAndChannels
	call ToneGen_InitAllChannelEntries_Skip
	call ToneGen_DSPCfg_Initialize
	pop xiz
	pop xix
	pop xhl
	pop xde
	calr MidiMsg_ParseChannelStream
	cp (0xfd32:16), 182
	jr z, Audio_UpdateTempoAndReturn
	pushw 0x7f
	ldw wa, 0xb0
	lds bc, 1
	ldw de, 0x7f
	calr MIDI_WriteCommandToBuffer
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitOutputBank
	pop xiz
	pop xix
	pop xhl
	pop xde

Audio_UpdateTempoAndReturn:
	call SeqTimer_UpdateTempoReg
	jp CompIface_SetMax

Audio_FullReinitWithPreset:
	lda xwa, (SoundProgram_DispatchTable_0x400:24)
	ld (0x90f2:16), xwa
	lda xwa, (SoundProgram_DispatchTable_0x800:24)
	ld (0x9182:16), xwa
	call Sys_CheckPowerStableFlag
	cp hl, 0:i3
	jr nz, Audio_CheckAndReinitReverb
	ld xwa, 0xc0
	lds bc, 0
	lds de, 1
	call SoundParam_NotifyChange
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz
	pop xix
	pop xhl
	pop xde

Audio_CheckAndReinitReverb:
	ld xwa, 0x2880
	call SndParam_LookupReadOnly
	cp hl, 0xb7
	ret nz
	ld xwa, 0x4001
	ldw bc, 0x7f
	lds de, 2
	call SoundParam_NotifyChange
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitOutputBank
	pop xiz
	pop xix
	pop xhl
	pop xde
	ret

VoiceData_InitAndCopyParams:
	dec 2, xsp
	push xiz
	ld (xsp + 4), wa
	cpw (xsp + 4), 0x50
	jrl nc, VoiceData_InitDone
	pushw 0x3c0
	pushw 0x0
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	sll xbc, 4
	sub xbc, xwa
	sll xbc, 6
	ld xwa, 0x1ed400
	add xwa, xbc
	push xwa
	call Memset
	inc 8, xsp
	ld iz, (xsp + 4)
	extz xiz
	ld xwa, xiz
	ld xbc, 0x2a2
	call Math_MultiplyAccumulate
	add xhl, 0x99eca0
	ld xwa, xiz
	sll xwa, 4
	sub xwa, xiz
	sll xwa, 6
	lda xiz, (0x1ed400:24)
	add xiz, xwa
	pushw 0x7c
	push xhl
	push xiz
	call Mem_Copy
	lda xwa, (Naka_ToshiParam_Table_0x8C:24)
	add xwa, 0x7c
	lda xiz, (xiz + 124)
	pushw 0x11e
	push xwa
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 20)
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x2a2
	call Math_MultiplyAccumulate
	add xhl, 0x99eca0
	add xhl, 0x7c
	lda_dri XWA, 0xf9, 0x1e, 0x01
	pushw 0x226
	push xhl
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)

VoiceData_InitDone:
	pop xiz
	inc 2, xsp
	ret

VoiceData_ExtendedParamSetup:
	cp	wa, 10
	ret	nc
	sll	wa, 4
	extz	xwa
	ld	xde, xwa
	add	xde, 0x99ec00
	lda	xbc, (0x1ed360:24)
	add	xbc, xwa
	pushw	16
	push	xde
	push	xbc
	call	Mem_Copy
	lda	xsp, (xsp+10)
	ret
	calr	753
	call	ToneGen_Config_InitAllEntries
	call	Voice_InitAllChannelEntries
	call	ToneGen_DSPCfg_ResetAll
	calr	651
	call	MainTitle_SetBootFlag
	jrl	-415
	dec	8, xsp
	pushw	iz
	lda	xwa, (Naka_ToshiParam_Table_0x8C:24)
	ld	(xsp+2), xwa
	lda	xwa, (0xf9a0:16)
	ld	(xsp+6), xwa
	lds	iz, 0
	ld	wa, iz
	extz	xwa
	ld	xbc, 26
	call	Math_MultiplyAccumulate
	add	xhl, 20
	ld	xbc, xhl
	.byte 0xaf
	push	sr
	add	(xbc), a
	normal
	ldb	a, 216
	ccf
	pushw	wa
	lda	xwa, (xbc+2)
	push	xwa
	.byte 0xaf
	incf
	.byte 0x83
	lda	xwa, (xhl+2)
	push	xwa
	call	Mem_Copy
	lda	xsp, (xsp+10)
	ld	wa, iz
	extz	xwa
	ld	xbc, 26
	call	Math_MultiplyAccumulate
	add	xhl, 20
	.byte 0xaf, 0x06
	or	(xhl), c
	and	(xwa+30), c
	pop	sr
	inc	1, iz
	cp	iz, 24
	jr	c, -83
	call	Voice_InitAllChannelEntries
	popw	iz
	inc	8, xsp
	ret
	lda	xsp, (xsp-10)
	.byte 0xd7
	swi	2
	.byte 0x04
	lda	xwa, (Naka_ToshiParam_Table_0x8C:24)
	ld	(xsp+4), xwa
	lda	xwa, (0xf9a0:16)
	ld	(xsp+8), xwa
	ld	(xsp+2), 0
	ld	a, (xsp+2)
	extz	wa
	muls	wa, 26
	ld	ix, wa
	add	ix, 20
	ld	xwa, (xsp+8)
	lda_rr xhl, xwa, ix
	lda xde, (xhl+14)
	ld c, (xde)
	and	c, 248
	ld	(xde), c
	ld	xwa, (xsp+4)
	lda_rr xwa, xwa, ix
	ld a, (xwa+14)
	and a, 7
	or	c, a
	ld	(xde), c
	ld	a, (xhl)
	extz	wa
	ld	e, c
	extz	de
	pushw	7
	ldw	bc, 12
	calr	1032
	pushw	9
	ld	a, (xsp+4)
	extz	wa
	muls	wa, 26
	ld	bc, wa
	add	bc, 20
	ld	xwa, (xsp+6)
	.byte 0xf3
	reti
	.byte 0xe0, 0xe4
	ldw	wa, 4024
	ldw	wa, 0xaf38
	ret
	ldb	w, 243
	reti
	.byte 0xe0, 0xe4
	ldw	wa, 4024
	.byte 0x30, 0x38, 0x1d  ; bytecode param 0x1d38
	addr24 Mem_Copy  ; Mem_Copy
	lda	xsp, (xsp+10)
	ldi_erpb 251, 13
	ld	a, (xsp+2)
	extz	wa
	muls	wa, 26
	ld	hl, wa
	ld	bc, hl
	add	bc, 20
	ld	xde, (xsp+8)
	ld_rrb a, xde, bc
	extz wa
	stb_erp c, 251
	extz	bc
	add	hl, bc
	lda_rr xde, xde, hl
	ld	e, (xde+22)
	extz	de
	pushw	255
	calr	929
	inc1b_erp 251
	cp_erpb 251, 21
	jr	ule, -59
	incm8	1, (xsp+2)
	.byte 0x8f
	push	sr
	push	xsp
	push_f
	jrl	c, -190
	.byte 0xf2, 0xc0
	swi	7
	nop
	.byte 0xb9
	pushw	14
	ld	xwa, (xsp+6)
	lda	xwa, (xwa+944)
	push	xwa
	ld	xwa, (xsp+14)
	lda	xwa, (xwa+944)
	push	xwa
	call	Mem_Copy
	lda	xsp, (xsp+10)
	ld	(xsp+2), 0
	ld	c, (xsp+2)
	extz	bc
	ld	de, bc
	add	de, 944
	ld	xwa, (xsp+8)
	ld_rrb e, xwa, de
	extz de
	pushw	255
	ldw	wa, 128
	calr	843
	incm8	1, (xsp+2)
	.byte 0x8f
	push	sr
	push	xsp
	ret
	jr	c, -39
	ld	xwa, (xsp+8)
	.byte 0xf3, 0xe1
	decf
	.byte 0x04
	ldw	bc, 8577
	bit	2, a
	jr	z, 20
	res	2, a
	ld	(xbc), a
	ld	e, a
	extz	de
	pushw	4
	ldw	wa, 145
	lds	bc, 3
	calr	799
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SwbtWr_ReinitOutputBank
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	(xsp+2), 0
	lda	xwa, (Naka_ToshiParam_Table_0x8C:24)
	ld	(xsp+4), xwa
	lds32	xwa, 0
	ld	a, (xsp+2)
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	ld	xwa, 0x1ed400
	add	xwa, xbc
	ld	(xsp+8), xwa
	ldib_erp 251, 0
	stb_erp a, 251
	extz	wa
	muls	wa, 26
	ld	hl, wa
	add	hl, 20
	ld	xwa, (xsp+8)
	lda_rr xix, xwa, hl
	lda xde, (xix+14)
	ld c, (xde)
	and	c, 248
	ld	(xde), c
	ld	xwa, (xsp+4)
	exts	xhl
	add	xhl, xwa
	ld	a, (xhl+14)
	and	a, 7
	or	c, a
	ld	(xde), c
	pushw	9
	lda	xwa, (xhl+15)
	push	xwa
	lda	xwa, (xix+15)
	push	xwa
	call	Mem_Copy
	lda	xsp, (xsp+10)
	inc1b_erp 251
	cp_erpb 251, 24
	jr	c, -77
	pushw	14
	ld	xwa, (xsp+6)
	.byte 0xf3, 0xe1, 0xb0
	pop	sr
	ldw	wa, 0xaf38
	ret
	ldb	w, 243
	.byte 0xe1, 0xb0
	pop	sr
	.byte 0x30, 0x38, 0x1d  ; bytecode param 0x1d38
	addr24 Mem_Copy  ; Mem_Copy
	lda	xsp, (xsp+10)
	incm8	1, (xsp+2)
	.byte 0x8f
	push	sr
	push	xsp
	.byte 0x50
	jrl	c, -151
	pop qiz
	lda	xsp, (xsp+10)
	ret
	calr	117
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	ToneGen_Config_InitAndChannels
	call	ToneGen_InitAllChannelEntries_Skip
	call	ToneGen_DSPCfg_Initialize
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	calr	7
	calr	173
	jp	SeqTimer_UpdateTempoReg

MidiMsg_ParseChannelStream:
	push xiz
	lda xiz, (0xf9a0:16)
	jr MidiMsg_LoopAndFlush

MidiMsg_CheckTerminator:
	cp (xiz), 0xff
	jr nz, MidiMsg_CheckMsgType
	inc 2, xiz
	jr MidiMsg_LoopAndFlush

MidiMsg_CheckMsgType:
	cp (xiz), 0x1f
	jr ule, MidiMsg_WriteMultiByte
	cp (xiz), 0x48
	jr nz, MidiMsg_CheckControlChange

MidiMsg_WriteMultiByte:
	ld xwa, xiz
	calr MIDI_WriteMultiByteWithHeader
	jr MidiChannelMsg_WriteOutput

MidiMsg_CheckControlChange:
	cp (xiz), 0xc0
	jr c, MidiMsg_WriteDefaultMsg
	cp (xiz), 0xdf
	jr ule, MidiChannelMsg_WriteOutput

MidiMsg_WriteDefaultMsg:
	cp (xiz), 0x49
	jr z, MidiChannelMsg_WriteOutput
	ld xwa, xiz
	calr MIDI_WriteMultiByteNoHeader

MidiChannelMsg_WriteOutput:
	ld a, (xiz + 1)
	inc 2, a
	extz wa
	lda_dri XIZ, 0x07, 0xf8, 0xe0

MidiMsg_LoopAndFlush:
	cp xiz, 0xffbe
	jr c, MidiMsg_CheckTerminator
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitOutputBank
	pop xiz
	pop xix
	pop xhl
	pop xde
	pop xiz
	ret

Display_SetupAndPrepareRender:
	pushw 0x20
	pushw 0xed
	pushw 0xb3dc
	pushw 0x0
	pushw 0xf980
	call Mem_Copy
	pushw 0x620
	pushw 0xed
	pushw 0xb3fc
	pushw 0x0
	pushw 0xf9a0
	call Mem_Copy
	lda xsp, (xsp + 20)
	res 0, (0xffc2:24)
	set 1, (0xffc0:24)
	call Get_Region_Code
	cp l, 2:i3
	jr nz, Display_SetRegionNon2
	ld (0x00ffc8:24), 0x01
	jr Display_RegionDone

Display_SetRegionNon2:
	ld (0x00ffc8:24), 0x02

Display_RegionDone:
	lds wa, 0
	call BitMapOut_PrepareRender_CheckBit2
	jrl Audio_FillParamBuffer

Display_CopyAndRenderBitmaps:
	pushw iz
	pushw 0x10
	pushw 0xed
	pushw 0xba1c
	pushw 0x1e
	pushw 0xd350
	call Mem_Copy
	pushw 0xa0
	ld xwa, 0x99ec00
	push xwa
	pushw 0x1e
	pushw 0xd360
	call Mem_Copy
	lda xsp, (xsp + 20)
	lds iz, 0

DisplayRender_Loop:
	ld wa, iz
	calr VoiceData_InitAndCopyParams
	inc 1, iz
	cp iz, 0x50
	jr c, DisplayRender_Loop
	calr Display_ProcessBitmapTable
	popw iz
	ret

Display_ProcessBitmapTable:
	dec 2, xsp
	push xiz
	ldw (xsp + 4), 0x0

BitmapTable_ProcessEntry:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	add xbc, xbc
	lda xwa, (SoundProgram_DispatchTable_0x892:24)
	add xwa, xbc
	ld a, (xwa)
	calr VoiceData_LookupPtrByIndex
	ld xiz, xhl
	sub xiz, 0xf9a0
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	add xbc, xbc
	ld xwa, SoundProgram_DispatchTable_0x890
	add xwa, xbc
	lda xbc, (0x1ed400:24)
	lda xde, (xwa + 3)
	lda xhl, (xwa + 4)
	lda xix, (xwa + 5)
	cpw (xwa), 0x50
	jr nz, BitmapTable_CheckOffset
	lds iy, 0
	ld e, (xde)
	ld d, (xix)
	ld l, (xhl)
	add xbc, xiz
	ld xix, xbc

BitmapTable_RenderLine:
	ld a, e
	extz wa
	lda_dri XBC, 0x07, 0xf0, 0xe0
	ld a, d
	cpl a
	and (xbc), a
	or (xbc), l
	inc 1, iy
	add xix, 0x3c0
	cp iy, 0x50
	jr c, BitmapTable_RenderLine
	jr BitmapTable_NextEntry

BitmapTable_CheckOffset:
	cpw (xwa), 0x50
	jr ge, BitmapTable_NextEntry
	ld wa, (xwa)
	exts xwa
	ld xiy, xwa
	sll xiy, 4
	sub xiy, xwa
	sll xiy, 6
	add xbc, xiy
	ld xiy, xbc
	add xiy, xiz
	ld c, (xde)
	extz bc
	ld a, (xix)
	cpl a
	and_srib_mr A, 0x07, 0xf4, 0xe4
	ld c, (xde)
	extz bc
	ld a, (xhl)
	or_srib_mr A, 0x07, 0xf4, 0xe4

BitmapTable_NextEntry:
	incw 1, (xsp + 4)
	cpw (xsp + 4), 0x1
	jrl c, BitmapTable_ProcessEntry
	pop xiz
	inc 2, xsp
	ret

MIDI_WriteMultiByteWithHeader:
	dec 6, xsp
	push xiz
	ld xiz, xwa
	ldb_spi A, 0xf8
	ld (xsp + 4), a
	ldb_spi A, 0xf8
	ld (xsp + 6), a
	ld a, (xsp + 4)
	extz wa
	ld e, (xiz + 1)
	extz de
	pushw 0xff
	lds bc, 1
	calr MIDI_WriteCommandToBuffer
	ld a, (xsp + 4)
	extz wa
	ld e, (xiz)
	extz de
	pushw 0xff
	lds bc, 0
	calr MIDI_WriteCommandToBuffer
	decm8 2, (xsp + 6)
	ld (xsp + 8), 0x2
	inc 2, xiz
	cp (xsp + 6), 0x0
	jr z, MidiMultiByte_Done

MidiMultiByte_WriteLoop:
	ld a, (xsp + 4)
	extz wa
	ld c, (xsp + 8)
	extz bc
	ld e, (xiz)
	extz de
	pushw 0xff
	calr MIDI_WriteCommandToBuffer
	decm8 1, (xsp + 6)
	incm8 1, (xsp + 8)
	inc 1, xiz
	cp (xsp + 6), 0x0
	jr nz, MidiMultiByte_WriteLoop

MidiMultiByte_Done:
	pop xiz
	inc 6, xsp
	ret

MIDI_WriteMultiByteNoHeader:
	dec 6, xsp
	push xiz
	ld xiz, xwa
	ldb_spi A, 0xf8
	ld (xsp + 4), a
	ldb_spi A, 0xf8
	ld (xsp + 6), a
	ld (xsp + 8), 0x0
	cp (xsp + 6), 0x0
	jr z, MidiNoHeader_Done

MidiNoHeader_WriteLoop:
	ld a, (xsp + 4)
	extz wa
	ld c, (xsp + 8)
	extz bc
	ld e, (xiz)
	extz de
	pushw 0xff
	calr MIDI_WriteCommandToBuffer
	decm8 1, (xsp + 6)
	incm8 1, (xsp + 8)
	inc 1, xiz
	cp (xsp + 6), 0x0
	jr nz, MidiNoHeader_WriteLoop

MidiNoHeader_Done:
	pop xiz
	inc 6, xsp
	ret

MIDI_WriteCommandToBuffer:
	ld hl, (0x90de:16)
	ld ix, hl
	inc 1, hl
	ld (0x90de:16), hl
	lda xhl, (0xbd3c:16)
	extz xix
	add xix, xhl
	ld (xix), a
	ld wa, (0x90de:16)
	ld ix, wa
	inc 1, wa
	ld (0x90de:16), wa
	ld wa, ix
	extz xwa
	add xwa, xhl
	ld (xwa), c
	ld wa, (0x90de:16)
	ld bc, wa
	inc 1, wa
	ld (0x90de:16), wa
	extz xbc
	add xbc, xhl
	ld (xbc), e
	ld wa, (0x90de:16)
	ld bc, wa
	inc 1, wa
	ld (0x90de:16), wa
	extz xbc
	add xbc, xhl
	ld a, (xsp + 4)
	ld (xbc), a
	ld wa, (0x90de:16)
	extz xwa
	add xwa, xhl
	ld (xwa), 0xff
	cpw (0x90de:16), 508
	jr c, MidiWrite_ReturnDiscard
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitOutputBank
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw (0x90de:16), 0

MidiWrite_ReturnDiscard:
	retd 0x2

Audio_InitAllChannelParams:
	pushw_erp 0xfa
	ldib_erp 0xfb, 0

AudioParamInit_Loop:
	stb_erp A, 0xfb
	extz wa
	calr Audio_InitSingleChannelParams
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0f
	jr ule, AudioParamInit_Loop
	popw_erp 0xfa
	ret

Audio_InitSingleChannelParams:
	dec 2, xsp
	ld (xsp), a
	ld (0x9127:16), 177
	mrib4 0x87, 0x19, 0x28, 0x91
	ld (0x9129:16), 0
	ld (0x912a:16), 64
	calr SwbtWr_WriteParamBlock
	ld (0x9127:16), 178
	mrib4 0x87, 0x19, 0x28, 0x91
	ld (0x9129:16), 0
	ld (0x912a:16), 127
	calr SwbtWr_WriteParamBlock
	ld (0x9127:16), 179
	mrib4 0x87, 0x19, 0x28, 0x91
	ld (0x9129:16), 127
	ld (0x912a:16), 127
	calr SwbtWr_WriteParamBlock
	mrib4 0x87, 0x19, 0x7e, 0x91
	ld (0x917f:16), 4
	ld (0x9180:16), 0
	ld (0x9181:16), 8
	call MIDI_WriteVoiceParamFromBuffer
	mrib4 0x87, 0x19, 0x27, 0x91
	ld (0x9128:16), 4
	ld (0x9129:16), 0
	ld (0x912a:16), 8
	calr SwbtWr_WriteParamBlock
	inc 2, xsp
	ret

Audio_MainPeriodicUpdate:
	cp (0xc039:16), 255
	ret z
	res 0, (0x9165:16)
	lda xwa, (SoundProgram_DispatchTable_0x400:24)
	ld (0x90f2:16), xwa
	calr Audio_SyncBufferPositions
	push xde
	push xhl
	push xix
	push xiz
	call MidiStream_ProcessEventBuffer
	call MidiStream_ProcessSeqBuffer
	call MIDI_SelectTempoExpressionSource
	call MidiStream_ProcessTempoRingBuf
	call MidiStream_ProcessRxBuffer
	call MidiPkt_ProcessEventQueue
	pop xiz
	pop xix
	pop xhl
	pop xde
	res 1, (0x90f9:16)
	ret

Audio_SyncBufferPositions:
	ldw (0x9133:16), 0
	ldmm16 0x90e0, 0x90de
	jr FileIO_ProcessRemainingOps

; File I/O operation dispatch
FileIO_OperationDispatch:
	calr SndParam_FetchSequencerParams
	ld a, (0x9127:16)
	extz wa
	sla wa, 2
	lda xbc, (SoundProgram_DispatchTable:24)
	ld_sril3 XHL, 0x07, 0xe4, 0xe0
	call (xhl)
	cpw (0x90de:16), 508
	jr c, FileIO_ProcessRemainingOps
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw (0x90e0:16), 0

FileIO_ProcessRemainingOps:
	lda xbc, (0xc039:16)
	ld wa, (0x9133:16)
	extz xwa
	add xwa, xbc
	cp (xwa), 0xff
	jr nz, FileIO_OperationDispatch
	lda xbc, (0xbd3c:16)
	ld wa, (0x90de:16)
	extz xwa
	add xwa, xbc
	ld (xwa), 0xff
	ld (0x90f8:16), 127
	ret

ExtData_ToneParam_DispatchHandler:
	calr	4351
	ld	a, (0x912f:16)
	cp	a, 22
	jr	z, 63
	extz	wa
	cp	wa, 0:i3
	ret	mi
	cp	wa, 11
	ret	gt
	add	wa, wa
	lda	xix, (SoundProgram_DispatchTable_0x896:24)
	ld_rrw wa, xix, wa
	lda xix, (16549232:24)
	jp_rr 8, xix, wa
	jr 31
	jrl	179
	jrl	191
	jrl	372
	jrl	378
	jrl	390
	jrl	396
	jrl	402
	jrl	408
	jrl	414
	calr	420
	ret
	dec	6, xsp
	lda	xwa, (xsp)
	.byte 0xb0
	push_a
	ldw	wa, 0xb891
	normal
	push_a
	ldw	bc, 0xb891
	push	sr
	push_a
	ldb	l, 145
	call	SndParam_ApplyProgramChange
	ld	a, (0x9127:16)
	extz	wa
	calr	6212
	cp	xhl, 0xffffffff
	jr	z, 109
	lda	xde, (xsp)
	.byte 0x82
	push	xsp
	incf
	jr	nz, 25
	ld	a, (xhl)
	.byte 0x8a
	pop	sr
	.byte 0xf1
	jr	nz, 18
	ld	a, (xhl+1)
	res	7, a
	.byte 0x8a, 0x04, 0xf1
	jr	nz, 7
	.byte 0xc1
	ldw	ix, 0x3f8d
	decf
	jr	nz, 77
	ld	a, (xde+3)
	lda_dpi xbc, 236
	ld c, (xhl)
	and c, 128
	ld	(xhl), c
	inc	4, xde
	ld	a, (xde)
	or	c, a
	ld	(xhl), c
	ld	(0x9128:16), 1
	.byte 0x82
	pop_f
	pushw	bc
	.byte 0x91
	ld	(0x912a:16), 127
	calr	4197
	ld	(0x9128:16), 0
	.byte 0x8f
	pop	sr
	pop_f
	pushw	bc
	.byte 0x91
	ld	(0x912a:16), 255
	calr	4179
	ld	a, (0x9127:16)
	extz	wa
	lda	xde, (xsp)
	ld	c, (xde+3)
	extz	bc
	ld	e, (xde+4)
	extz	de
	calr	5727
	inc	6, xsp
	ret
	ldw	wa, 128
	calr	4420
	ldw	wa, 127
	calr	4414
	jrl	4140
	dec	6, xsp
	ld	a, (0x9127:16)
	extz	wa
	calr	6066
	cp	xhl, 0xffffffff
	jrl	z, 161
	lda	xwa, (xsp)
	.byte 0xb8
	push	sr
	push_a
	ldb	l, 145
	ld	c, (xhl)
	ld	(xwa+3), c
	ld	c, (xhl+1)
	res	7, c
	ld	(xwa+4), c
	call	SndParam_FetchOscTableEntry
	lda	xwa, (xsp)
	.byte 0x80
	push	xsp
	retd	2670
	.byte 0xc1
	ldw	wa, 0x3c91
	.byte 0xb7, 0xc1
	ldw	bc, 0x3c91
	.byte 0xb7, 0x80
	push	xsp
	incf
	jr	nz, 8
	.byte 0xf1
	ldw	wa, 0xb691
	.byte 0xf1
	ldw	bc, 0xb691
	.byte 0xf1
	swi	1
	and	(xwa), bc
	jr	z, 11
	ldw	wa, 8
	calr	4682
	ldw	wa, 96
	jr	3
	ldw	wa, 104
	calr	4137
	ld	c, (0x9131:16)
	ld	a, c
	and	a, 7
	cp	a, 7:i3
	jr	nz, 7
	lds	wa, 7
	calr	4295
	jr	60
	and	c, 3
	jr	z, 55
	ld	a, (0x9130:16)
	cp	a, 2:i3
	jr	nz, 21
	ld	(0x9153:16), 1
	ld	(0x9154:16), 8
	ld	(0x9155:16), 7
	lds	wa, 2
	lds	bc, 7
	jr	23
	cp	a, 1:i3
	jr	nz, 22
	ld	(0x9153:16), 255
	ld	(0x9154:16), 255
	ld	(0x9155:16), 0
	lds	wa, 1
	lds	bc, 7
	calr	4482
	calr	3959
	inc	6, xsp
	ret
	ldw	wa, 127
	calr	4221
	jrl	3947
	ldw	wa, 127
	calr	4212
	ldw	wa, 128
	calr	4030
	jrl	3932
	ldw	wa, 127
	calr	4197
	jrl	3923
	ldw	wa, 127
	calr	4188
	jrl	3914
	ldw	wa, 127
	calr	4179
	jrl	3905
	ldw	wa, 255
	calr	4170
	jrl	3896
	ldw	wa, 127
	calr	4161
	jrl	3887
	lds	wa, 1
	calr	3977
	jrl	3879
FileIO_AllocBuffer:
	ret
ExtData_ToneParam_CheckMode:
	calr	3844
	ld	a, (0x912f:16)
	cp	a, 1:i3
	jr	z, 6
	cp	a, 0:i3
	ret	nz
	jr	4
	calr	10
	ret
	ldw	wa, 128
	calr	4122
	jrl	3848
	ldw	wa, 128
	calr	4113
	ldw	wa, 127
	calr	4107
	jrl	3833
ExtData_ToneParam_AltDispatch:
	calr	3799
	ld	a, (0x912f:16)
	extz	wa
	cp	wa, 0:i3
	ret	mi
	cp	wa, 8
	ret	gt
	add	wa, wa
	lda	xix, (SoundProgram_DispatchTable_0x8AE:24)
	ld_rrw wa, xix, wa
	lda xix, (16549779:24)
	jp_rr 8, xix, wa
	jr 8
	jr 15
	jr	28
	calr	40
	ret
	ldw	wa, 255
	calr	4047
	jrl	3773
	ldw	wa, 15
	calr	4038
	ldw	wa, 240
	calr	4032
	jrl	3758
	ldw	wa, 15
	calr	4023
	ldw	wa, 240
	calr	4017
	jrl	3743
	ldw	wa, 15
	calr	4008
	ldw	wa, 48
	calr	3826
	jrl	3728
ExtData_ToneParam_AltEntry:
	ret
ExtData_ToneParam_AltBody:
	calr	3693
	ld	a, (0x912f:16)
	extz	wa
	cp	wa, 0:i3
	ret	mi
	cp	wa, 8
	ret	gt
	add	wa, wa
	lda	xix, (SoundProgram_DispatchTable_0x8C0:24)
	ld_rrw wa, xix, wa
	lda xix, (16549885:24)
	jp_rr 8, xix, wa
	jr 15
	jr 112
	jrl	143
	jrl	149
	jrl	161
	calr	167
	ret
	lda	xwa, (0x90ea:16)
	.byte 0xb0
	push_a
	ldw	wa, 0xb891
	normal
	push_a
	ldw	bc, 0xb891
	push	sr
	push_a
	ldb	l, 145
	call	Rhythm_LookupTempoVelocity_Wrap
	ld	a, (0x9127:16)
	extz	wa
	calr	5575
	cp	xhl, 0xffffffff
	ret	z
	lda	xde, (0x90ee:16)
	ldb_spi a, 232
	lda_dpi xbc, 236
	ld c, (xhl)
	and c, 128
	ld	(xhl), c
	ld	a, (xde)
	or	c, a
	ld	(xhl), c
	ld	(0x9128:16), 1
	.byte 0x82
	pop_f
	pushw	bc
	.byte 0x91
	ld	(0x912a:16), 127
	calr	3590
	ld	(0x9128:16), 0
	.byte 0xc1
	adc	xwa, xiz
	pop_f
	pushw	bc
	.byte 0x91
	ld	(0x912a:16), 255
	calr	3571
	ret
	lds	wa, 7
	calr	4004
	ldw	wa, 8
	calr	3654
	ld	a, (0x912a:16)
	and	a, 7
	jr	z, 8
	call	ToneGen_DispatchByMode
	.byte 0xf1
	swi	1
	.byte 0x90, 0xb8
	calr	3539
	jrl	516
	ldw	wa, 80
	calr	3625
	jrl	3527
	.byte 0xc1
	ldw	wa, 6545
	pushw	bc
	.byte 0x91, 0xc1
	ldw	bc, 6545
	pushw	de
	.byte 0x91
	jrl	3512
	ldw	wa, 48
	calr	3777
	jrl	3503
	push	xiz
	lda	xiz, (0xfc5a:16)
	lda	xbc, (xiz+8)
	lda	xhl, (xiz+9)
	ld	e, (0x9130:16)
	cp	(xbc), e
	jr	nz, 8
	ld	a, (xhl)
	cp a, (37169:16)
	jr	z, 40
	ld	(xbc), e
	.byte 0xb3
	push_a
	ldw	bc, 0x8191
	pop_f
	pushw	bc
	.byte 0x91
	ld	(0x912a:16), 255
	calr	3458
	ld	(0x9128:16), 9
	.byte 0x8e
	push	25
	pushw	bc
	.byte 0x91
	ld	(0x912a:16), 1
	calr	3440
	call	SeqTimer_UpdateTempoReg
	pop	xiz
	ret
ExtData_ToneParam_MultiChannel:
	calr	3400
	ld	a, (0x912f:16)
	cp	a, 16
	jr	z, 20
	cp	a, 4:i3
	jr	z, 20
	cp	a, 3:i3
	jrl	z, 577
	cp	a, 1:i3
	jr	z, 4
	cp	a, 0:i3
	ret	nz
	jrl	129
	calr	620
	ret
	ld	c, (0x9131:16)
	ld	a, c
	and	a, 255
	cp	a, 255
	jr	nz, 6
	ldw	wa, 255
	jrl	3649
	and	c, 3
	ret	z
	ld	c, (0x9130:16)
	and	c, 3
	lda	xwa, (0xfc6a:16)
	cp	c, 3:i3
	jr	z, 59
	cp	c, 1:i3
	jr	z, 29
	cp	c, 2:i3
	jr	nz, 73
	ld	(0x9153:16), 12
	ld	(0x9154:16), 89
	ld	(0x9155:16), 88
	lds	wa, 2
	ldw	bc, 255
	calr	3847
	jr	48
	ld	xbc, xwa
	ld	a, (xwa)
	ld	e, a
	cp	a, 40
	jr	ule, 3
	sub	e, 12
	cp	e, a
	ret	z
	ld	(xbc), e
	ld	(0x9129:16), e
	jr	17
	ld	xbc, xwa
	ld	a, (xwa)
	cp	a, 64
	ret	z
	ld	(xbc), 64
	ld	(0x9129:16), 64
	ld	(0x912a:16), 255
	calr	3274
	ret
	lda	xbc, (0xfc66:16)
	ld	e, (xbc+1)
	extz	de
	sll	de, 8
	ld	a, (xbc)
	extz	wa
	add	wa, de
	ld	(0x9163:16), wa
	ld	a, (0xfc5d:16)
	and	a, 7
	cp	a, 2:i3
	jr	z, 32
	cp	a, 0:i3
	jr	z, 28
	cp	a, 3:i3
	jr	z, 9
	cp	a, 1:i3
	ret	nz
	.byte 0xb9
	pop	sr
	dec	6, w
	retd	0x2fc1
	.byte 0x91
	push	xsp
	normal
	jr	nz, 8
	.byte 0xf1
	ldw	wa, 0xb191
	.byte 0xf1
	ldw	bc, 0xb191
	.byte 0xc1
	pushw	sp
	.byte 0x91
	push	xsp
	normal
	jr	nz, 29
	lds	wa, 2
	calr	3291
	.byte 0xf1
	pushw	de
	and	(xbc), bc
	jr	nz, 1
	ret
	.byte 0xf1
	swi	1
	.byte 0x90
	lda	xwa, (xwa-15)
	.byte 0x91, 0xb1, 0xf1
	ldw	bc, 0xb191
	ld	(0x912a:16), 0
	calr	7
	call	ToneGen_DispatchByMode
	jrl	142
	ld	c, (0x9131:16)
	cp	c, 0:i3
	ret	z
	lda	xix, (0x915f:16)
	lda	xhl, (0x9161:16)
	ld	e, (0x912f:16)
	extz	de
	ld	a, (0x9130:16)
	and	a, c
	.byte 0xc3
	reti
	.byte 0xf0, 0xe8
	and	xbc, xbc
	pushw	sp
	ld	hl, (xbc)
	extz	bc
	ld	a, (0x9131:16)
	cpl	a
	.byte 0xc3
	reti
	or	xix, xix
	and	a, a
	pushw	sp
	ld	hl, (xbc)
	extz	bc
	ld	a, (0x9130:16)
	and	a, (0x9131:16)
	.byte 0xc3
	reti
	or	xix, xix
	add	xhl, xbc
	ldb	c, 203
	dec	6, wa
	ret
	.byte 0x8b, 0x01
	push	xsp
	nop
	jr	nz, 8
	ld	(xix), 0
	ld	(xix+1), 0
	ret
	ld	a, (xix)
	and	a, 3
	jr	nz, 5
	bit	1, c
	ret	z
	lda	xde, (0xfc66:16)
	extz	wa
	lda	xbc, (SoundProgram_DispatchTable_0x8D2:24)
	.byte 0xc3
	reti
	.byte 0xe4, 0xe0
	ldb	c, 178
	ld	xhl, 0xc921018a
	.byte 0xee
	ldio	216, 18
	extz	bc
	add	bc, wa
	cp bc, (37219:16)
	ret	z
	.byte 0xf1
	swi	1
	.byte 0x90, 0xb8
	ret

MIDI_WriteResetSequence:
	ld a, (0x90f9:16)
	bit 0, a
	ret z
	ld wa, (0x90de:16)
	ld de, wa
	inc 1, wa
	ld (0x90de:16), wa
	lda xbc, (0xbd3c:16)
	extz xde
	add xde, xbc
	ld (xde), 0x90
	ld wa, (0x90de:16)
	ld de, wa
	inc 1, wa
	ld (0x90de:16), wa
	extz xde
	add xde, xbc
	ld (xde), 0x0
	ld wa, (0x90de:16)
	ld hl, wa
	inc 1, wa
	ld (0x90de:16), wa
	extz xhl
	add xhl, xbc
	lda xde, (0xfc66:16)
	ld a, (xde)
	ld (xhl), a
	ld wa, (0x90de:16)
	ld hl, wa
	inc 1, wa
	ld (0x90de:16), wa
	extz xhl
	add xhl, xbc
	ld (xhl), 0x1f
	ld wa, (0x90de:16)
	ld hl, wa
	inc 1, wa
	ld (0x90de:16), wa
	extz xhl
	add xhl, xbc
	ld (xhl), 0x90
	ld wa, (0x90de:16)
	ld hl, wa
	inc 1, wa
	ld (0x90de:16), wa
	extz xhl
	add xhl, xbc
	ld (xhl), 0x1
	ld wa, (0x90de:16)
	ld hl, wa
	inc 1, wa
	ld (0x90de:16), wa
	extz xhl
	add xhl, xbc
	ld a, (xde + 1)
	ld (xhl), a
	ld wa, (0x90de:16)
	ld de, wa
	inc 1, wa
	ld (0x90de:16), wa
	extz xde
	add xde, xbc
	ld (xde), 0x1f
	ld a, (0x90f9:16)
	res 0, a
	ld (0x90f9:16), a
	ret

ExtData_Voice_UpdateFlags:
	lds	wa, 2
	calr	2926
	lds	wa, 1
	calr	3097
	calr	2823
	lda	xbc, (0xfc66:16)
	.byte 0xb9
	pop	sr
	sbc	w, w
	swi	6
	ld	a, (0xfc5d:16)
	and	a, 7
	cp	a, 1:i3
	ret	nz
	inc	1, xbc
	ld	a, (xbc)
	bit	1, a
	ret	z
	.byte 0xf1
	swi	1
	.byte 0x90, 0xb8
	ld	a, (xbc)
	res	1, a
	ld	(xbc), a
	calr	65296
	ret
	.byte 0xc1
	ldw	wa, 6545
	pushw	bc
	.byte 0x91, 0xc1
	ldw	bc, 6545
	pushw	de
	.byte 0x91
	jrl	2764
ExtData_Voice_CheckMode:
	calr	2730
	ld	a, (0x912f:16)
	cp	a, 1:i3
	ret	nz
	calr	1
	ret
	ldw	wa, 192
	calr	2838
	jrl	2740
ExtData_Voice_RetEntry:
	ret
ExtData_Voice_MixedHandler:
	calr	2705
	ld	a, (0x912f:16)
	cp	a, 2:i3
	jr	z, 6
	cp	a, 0:i3
	ret	nz
	jr	4
	calr	90
	ret
	lds	wa, 4
	calr	2808
	calr	2710
	ld	(0x9153:16), 1
	ld	(0x9154:16), 4
	ld	(0x9155:16), 0
	lds	wa, 1
	lds	bc, 3
	calr	3208
	calr	2685
	.byte 0xc1
	and	e, w
	push	xsp
	swi	7
	ret	nz
	ld	a, (0x9130:16)
	and	a, (0x9131:16)
	bit	0, a
	jr	z, 23
	ld	a, (0xfd02:16)
	and	a, 3
	extz	wa
	lda	xbc, (SoundProgram_DispatchTable_0x8D6:24)
	.byte 0xc3
	reti
	.byte 0xe4, 0xe0
	pop_f
	pop	xwa
	.byte 0x8f
	jr	5
	ld	(0x8f58:16), 0
	ldw	wa, 69
	call	CtrlPanel_SetIndicatorBit
	ret
	ld	c, (0x9131:16)
	ld	a, c
	and	a, 255
	cp	a, 255
	jr	nz, 8
	ldw	wa, 255
	calr	2880
	jr	96
	.byte 0xf1, 0xe2, 0xe3
	dec	6, a
	pop	xde
	and	c, 3
	jr	z, 85
	ld	a, (0x9130:16)
	and	a, 3
	cp	a, 1:i3
	jr	z, 26
	cp	a, 2:i3
	jr	nz, 47
	ld	(0x9153:16), 1
	ld	(0x9154:16), 12
	ld	(0x9155:16), 11
	lds	wa, 2
	ldw	bc, 255
	jr	20
	ld	(0x9153:16), 255
	ld	(0x9154:16), 255
	ld	(0x9155:16), 0
	lds	wa, 1
	ldw	bc, 255
	calr	3056
	jr	23
	lda	xbc, (0xfd04:16)
	ld	a, (xbc)
	cp	a, 5:i3
	ret	z
	ld	(xbc), 5
	ld	(0x9129:16), 5
	ld	(0x912a:16), 255
	.byte 0xc1
	pushw	bc
	.byte 0x91
	push	xsp
	halt
	jr	nz, 5
	ld	(0x8d3c:16), 24
	jrl	2496
ExtData_Voice_CheckMode3:
	calr	2462
	ld	a, (0x912f:16)
	cp	a, 3:i3
	ret	nz
	calr	63863
	ret
ExtData_Voice_RetEntry2:
	ret
ExtData_Voice_FullHandler:
	calr	2446
	ld	a, (0x912f:16)
	cp	a, 11
	jr	z, 19
	cp	a, 2:i3
	jr	z, 58
	cp	a, 4:i3
	jrl	z, -1696
	cp	a, 3:i3
	jr	z, 30
	cp	a, 1:i3
	ret	nz
	jr	4
	calr	59
	ret
	ldw	wa, 128
	calr	3068
	.byte 0xc1
	ldw	de, 0x3c91
	.byte 0x80
	ldw	wa, 127
	calr	2612
	jrl	2425
	ld	a, (0x9130:16)
	and	a, (0x9131:16)
	ret	z
	lds	wa, 1
	calr	2505
	calr	2407
	ret
	.byte 0xf1
	swi	1
	.byte 0x90
	lda	xwa, (xbc)
	ld	xwa, 0x0bd11e00
	ldw	wa, 128
	calr	3019
	jrl	2387
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	a, (0xfda1:16)
	and	a, 192
	ldb_erp a, 251
	ldw	wa, 128
	calr	2463
	ldw	wa, 64
	calr	2457
	lda	xde, (0xfda1:16)
	ld	c, (xde)
	ld	a, c
	and	a, 192
	cp	a, 192
	jr	nz, 16
	.byte 0xf1
	pushw	de
	.byte 0x91
	inc	6, l
	halt
	res	6, c
	jr	3
	res	7, c
	ld	(xde), c
	.byte 0x82
	pop_f
	pushw	bc
	ld	hl, (xbc)
	nop
	ld	(0x912a:16), 0
	ld	l, (xde)
	and	l, 128
	stb_erp a, 251
	and a, 128
	cp a, l
	jr	z, 7
	set	7, c
	ld	(0x912a:16), c
	ld	c, (xde)
	and	c, 64
	.byte 0xc7
	swi	3
	and	(xbc-55), d
	ld	xwa, 0x0466f1cb
	.byte 0xf1
	pushw	de
	.byte 0x91, 0xbe
	calr	2275
	pop qiz
	ret
ExtData_Voice_CopyAndJump:
	.byte 0xc1
	ldw	wa, 6545
	pushw	bc
	.byte 0x91, 0xc1
	ldw	bc, 6545
	pushw	de
	.byte 0x91
	jrl	2256
ExtData_Voice_CompareAndDispatch:
	ld	a, (0x912f:16)
	cp	a, 0:i3
	jr	z, 7
	cp	a, 1:i3
	ret	nz
	jrl	140
	calr	1
	ret
	ld	a, (0x8ee6:16)
	set	7, a
	ld	(0x8ee2:16), a
	calr	3135
	ld	(0x917e:16), 176
	ld	(0x917f:16), 0
	.byte 0xc1
	ldw	wa, 6545
	.byte 0x80, 0x91, 0xc1
	ldw	bc, 6545
	.byte 0x81, 0x91
	jp	MIDI_LoadParamsAndDispatchCC

MidiChannel_ResetAndConfigure:
	res 7, (0x28ae:16)
	ld a, (0x8ee4:16)
	set 7, a
	ld (0x8ee0:16), a
	bit 7, (0x8ee4:16)
	ret z
	calr Audio_FlushPendingBankSelects
	ld (0x9127:16), 176
	ld (0x9128:16), 1
	ld a, (0x8ee4:16)
	res 7, a
	ld (0x9129:16), a
	ld (0x912a:16), 127
	ld e, (0x9129:16)
	extz de
	pushw 0x7f
	ldw wa, 0xb0
	lds bc, 1
	call AddswbWr
	ldmm8 0x917e, 0x9127
	ldmm8 0x917f, 0x9128
	ldmm8 0x9180, 0x9129
	ld (0x9181:16), 127
	call MIDI_LoadParamsAndDispatchCC
	ret

MidiCh_ConfigVoiceAndParts:
	ld	a, (0x8ee0:16)
	res	7, a
	ld	(0x8ee0:16), a
	ld	c, (0x8ee4:16)
	cp	c, a
	ret	z
	ld	a, (0x28ae:16)
	bit	7, a
	jr	z, 37
	ld	(9828:16), c
	ld	e, (0x28ae:16)
	ld	l, e
	res	7, l
	cp	l, c
	jr	ule, 6
	sub	l, c
	ld	c, l
	jr	2
	sub	c, l
	cp	c, 16
	jr	c, 17
	res	7, e
	ld	(0x28ae:16), e
	.byte 0xc1, 0xe4, 0x8e
	pop_f
	.byte 0xe0, 0x8e, 0xf1, 0xe4, 0x8e, 0xbf, 0xf1, 0xe4
	.byte 0x8e
	sbc	w, l
	.byte 0xf6
	calr	2929
	ld	(0x9127:16), 176
	ld	(0x9128:16), 1
	ld	a, (0x8ee4:16)
	res	7, a
	ld	(0x9129:16), a
	ld	(0x912a:16), 127
	calr	1988
	.byte 0xc1
	ldb	l, 145
	pop_f
	jrl	nz, -15983
	pushw	wa
	.byte 0x91
	pop_f
	jrl	nc, -15983
	ldw	wa, 6545
	.byte 0x80, 0x91, 0xc1
	ldw	bc, 6545
	.byte 0x81, 0x91
	call	MIDI_LoadParamsAndDispatchCC
	ret
MidiCh_IterateVolume_Forward:
	pushw	iz
	ld	a, (0x9131:16)
	res	7, a
	cp	a, 0:i3
	jr	z, 114
	lds	iz, 0
	lda	xde, (0x90fb:16)
	ld	bc, iz
	extz	xbc
	add	xbc, xde
	ld	a, (xbc)
	cp	a, 255
	jr	z, 95
	cp	a, 2:i3
	jr	nz, 6
	.byte 0x8a, 0x01
	push	xsp
	swi	7
	jr	nz, 77
	.byte 0xc1
	ldb	l, 145
	pop_f
	jrl	nz, -32367
	pop_f
	jrl	nc, -15983
	ldw	wa, 6545
	.byte 0x80, 0x91, 0xc1
	ldw	bc, 6545
	.byte 0x81, 0x91
	call	MIDI_LoadParamsAndDispatchCC
	lda	xwa, (0x90fb:16)
	ld	bc, iz
	extz	xbc
	add	xbc, xwa
	ld	a, (xbc)
	extz	wa
	calr	3812
	.byte 0xbb
	decf
	dec	6, e
	call	0x90fbf1
	ldw	wa, 0x89de
	extz	xbc
	add	xbc, xwa
	.byte 0x81
	pop_f
	pushw	wa
	.byte 0x91, 0xc1
	ldw	wa, 6545
	pushw	bc
	.byte 0x91, 0xc1
	ldw	bc, 6545
	pushw	de
	.byte 0x91
	calr	1841
	inc	1, iz
	cp	iz, 32
	jr	c, -112
	popw	iz
	ret
MidiCh_IterateVolume_Reverse:
	pushw	iz
	lds	iz, 0
	lda	xde, (0x90fb:16)
	ld	bc, iz
	extz	xbc
	add	xbc, xde
	ld	a, (xbc)
	cp	a, 255
	jr	z, 95
	cp	a, 2:i3
	jr	nz, 6
	.byte 0x8a, 0x01
	push	xsp
	swi	7
	jr	nz, 77
	.byte 0xc1
	ldb	l, 145
	pop_f
	jrl	nz, -32367
	pop_f
	jrl	nc, -15983
	ldw	wa, 6545
	.byte 0x80, 0x91, 0xc1
	ldw	bc, 6545
	.byte 0x81, 0x91
	call	MIDI_LoadParamsAndDispatchCC
	lda	xwa, (0x90fb:16)
	ld	bc, iz
	extz	xbc
	add	xbc, xwa
	ld	a, (xbc)
	extz	wa
	calr	3695
	.byte 0xbb
	decf
	dec	6, e
	call	0x90fbf1
	ldw	wa, 0x89de
	extz	xbc
	add	xbc, xwa
	.byte 0x81
	pop_f
	pushw	wa
	.byte 0x91, 0xc1
	ldw	wa, 6545
	pushw	bc
	.byte 0x91, 0xc1
	ldw	bc, 6545
	pushw	de
	.byte 0x91
	calr	1761
	inc	1, iz
	cp	iz, 32
	jr	c, -112
	popw	iz
	ret
MidiCh_IteratePan_Forward:
	pushw	iz
	ld	a, (0x9131:16)
	res	7, a
	cp	a, 0:i3
	jrl	z, 135
	lds	iz, 0
	lda	xbc, (0x90fb:16)
	ld	wa, iz
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	cp	a, 255
	jr	z, 116
	cp	a, 2:i3
	jr	nz, 6
	.byte 0x89, 0x01
	push	xsp
	swi	7
	jr	nz, 97
	extz	wa
	calr	3604
	.byte 0xbb
	incf
	inc	6, d
	.byte 0x57, 0xc1
	ldb	l, 145
	pop_f
	jrl	nz, -3695
	swi	3
	.byte 0x90
	ldw	wa, 0x89de
	extz	xbc
	add	xbc, xwa
	.byte 0x81
	pop_f
	jrl	nc, -15983
	ldw	wa, 6545
	.byte 0x80, 0x91, 0xc1
	ldw	bc, 6545
	.byte 0x81, 0x91
	call	MIDI_LoadParamsAndDispatchCC
	lda	xwa, (0x90fb:16)
	ld	bc, iz
	extz	xbc
	add	xbc, xwa
	ld	a, (xbc)
	extz	wa
	calr	3546
	.byte 0xbb
	decf
	dec	6, e
	call	0x90fbf1
	ldw	wa, 0x89de
	extz	xbc
	add	xbc, xwa
	.byte 0x81
	pop_f
	pushw	wa
	.byte 0x91, 0xc1
	ldw	wa, 6545
	pushw	bc
	.byte 0x91, 0xc1
	ldw	bc, 6545
	pushw	de
	.byte 0x91
	calr	1575
	inc	1, iz
	cp	iz, 32
	jrl	c, -133
	popw	iz
	ret
MidiCh_IterateExpression:
	dec	2, xsp
	push	xiz
	ld	a, (0x9131:16)
	res	7, a
	cp	a, 0:i3
	jr	z, 125
	.byte 0xbf, 0x04
	push	sr
	nop
	nop
	lda	xbc, (0x90fb:16)
	ld	wa, (xsp+4)
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	cp	a, 255
	jr	z, 102
	extz	wa
	calr	3459
	ld	xiz, xhl
	cp	xiz, 0xffffffff
	jr	z, 77
	.byte 0xbe, 0x04
	inc	6, e
	popw	wa
	.byte 0xc1
	ldb	l, 145
	pop_f
	jrl	nz, -3695
	swi	3
	.byte 0x90
	ldw	wa, 1183
	ldb	a, 233
	ccf
	add	xbc, xwa
	.byte 0x81
	pop_f
	jrl	nc, -15983
	ldw	wa, 6545
	.byte 0x80, 0x91, 0xc1
	ldw	bc, 6545
	.byte 0x81, 0x91
	call	MIDI_LoadParamsAndDispatchCC
	.byte 0xbe
	decf
	dec	6, e
	calr	64497
	.byte 0x90
	ldw	wa, 1183
	ldb	a, 233
	ccf
	add	xbc, xwa
	.byte 0x81
	pop_f
	pushw	wa
	.byte 0x91, 0xc1
	ldw	wa, 6545
	pushw	bc
	.byte 0x91, 0xc1
	ldw	bc, 6545
	pushw	de
	.byte 0x91
	calr	1435
	incw	1, (xsp+4)
	.byte 0x9f, 0x04
	push	xsp
	ldb	w, 0
	jr	c, -120
	pop	xiz
	inc	2, xsp
	ret

CtrlPanel_RefreshIndicatorState:
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	ld xbc, 0x8f62
	calr CtrlPanel_CompareAndUpdateIndicators
	ld xwa, xiz
	calr CtrlPanel_BuildIndicatorBitmask
	ld xwa, xhl
	calr Part_BitmaskToIndexList
	ld xiy, xiz
	ld xix, 0x8f62
	ldw bc, 0xb3
	ldirw
	pop xiz
	ret

CtrlPanel_CompareAndUpdateIndicators:
	lda_dri XSP, 0xfd, 0x8e, 0xfe
	push xiz
	stl_dri XBC, 0xfd, 0x6e, 0x01
	stl_dri XWA, 0xfd, 0x72, 0x01
	ld XWA, (xsp + 0x0172)
	calr CtrlPanel_BuildIndicatorBitmask
	ld (xsp + 4), xhl
	ld XWA, (xsp + 0x016e)
	calr CtrlPanel_BuildIndicatorBitmask
	ld xiz, xhl
	ld xwa, (xsp + 4)
	xor xwa, xiz
	and xwa, xiz
	calr Part_BitmaskToIndexList
	ld XWA, (xsp + 0x016e)
	ld c, (xwa + 1)
	extz bc
	ldw wa, 0x80
	calr Audio_IteratePartsWithExpression
	ld XWA, (xsp + 0x016e)
	ld c, (xwa + 1)
	extz bc
	lds wa, 0
	calr Audio_IteratePartsWithVolume
	ld XWA, (xsp + 0x016e)
	ld c, (xwa + 1)
	extz bc
	lds wa, 0
	calr Audio_IteratePartsWithPan
	ld XWA, (xsp + 0x016e)
	ld c, (xwa + 1)
	cp c, 0xff
	jr z, CtrlPanelRefresh_ProcessRemoved
	extz bc
	ldw wa, 0x7f
	calr MIDI_DispatchVoiceParamCC

CtrlPanelRefresh_ProcessRemoved:
	ld xwa, (xsp + 4)
	xor xwa, xiz
	and xwa, (xsp + 4)
	calr Part_BitmaskToIndexList
	ld a, (0x8ee8:16)
	extz wa
	ld XBC, (xsp + 0x0172)
	ld c, (xbc + 1)
	extz bc
	calr Audio_IteratePartsWithExpression
	ld a, (0x8eea:16)
	res 7, a
	extz wa
	ld XBC, (xsp + 0x0172)
	ld c, (xbc + 1)
	extz bc
	calr Audio_IteratePartsWithVolume
	ld a, (0x8ef4:16)
	extz wa
	ld XBC, (xsp + 0x0172)
	ld c, (xbc + 1)
	extz bc
	calr Audio_IteratePartsWithPan
	ld XWA, (xsp + 0x0172)
	lda xbc, (xwa + 1)
	ld XWA, (xsp + 0x016e)
	cp (xwa + 1), 0xff
	jr nz, CtrlPanelRefresh_DispatchVoiceCC
	cp (xbc), 0xff
	jr nz, CtrlPanelRefresh_CheckMigration

CtrlPanelRefresh_DispatchVoiceCC:
	ld a, (0x8ee4:16)
	res 7, a
	extz wa
	ld c, (xbc)
	extz bc
	calr MIDI_DispatchVoiceParamCC

CtrlPanelRefresh_CheckMigration:
	ld XBC, (xsp + 0x016e)
	cp (xbc + 1), 0xff
	jr nz, CtrlPanelRefresh_Done
	ld XWA, (xsp + 0x0172)
	cp (xwa + 1), 0xff
	jr z, CtrlPanelRefresh_Done
	ld xiy, xbc
	lda xix, (xsp + 8)
	ldw bc, 0xb3
	ldirw
	lda xwa, (xsp + 8)
	ormi8 (xwa), 0x7
	calr CtrlPanel_BuildIndicatorBitmask
	ld xiz, xhl
	ld xwa, (xsp + 4)
	xor xwa, xiz
	and xwa, xiz
	calr Part_BitmaskToIndexList
	ld XWA, (xsp + 0x0172)
	ld c, (xwa + 1)
	extz bc
	ldw wa, 0x7f
	calr MIDI_DispatchVoiceParamCC
	ld xwa, (xsp + 4)
	xor xwa, xiz
	and xwa, (xsp + 4)
	calr Part_BitmaskToIndexList
	ld a, (0x8ee4:16)
	res 7, a
	extz wa
	ld XBC, (xsp + 0x0172)
	ld c, (xbc + 1)
	extz bc
	calr MIDI_DispatchVoiceParamCC

CtrlPanelRefresh_Done:
	pop xiz
	lda_dri XSP, 0xfd, 0x72, 0x01
	ret

CtrlPanel_BuildIndicatorBitmask:
	push xiz
	lds32 xiz, 0
	lda xde, (SoundProgram_DispatchTable_0x8DA:24)
	ld c, (xwa + 1)
	cp c, 0xff
	jr nz, IndBitmask_LookupByChannel
	ld c, (xwa)
	lds32 xiz, 0
	ldb_erp C, 0xf8
	and xiz, 0x7
	ldb_sri0 A, (xwa + 0x00be)
	cp a, 0xff
	jr z, IndBitmask_ReturnResult
	extz wa
	ldb_sri A, 0x07, 0xe8, 0xe0
	jr IndBitmask_ApplyResult

IndBitmask_LookupByChannel:
	extz bc
	ldb_sri A, 0x07, 0xe8, 0xe4

IndBitmask_ApplyResult:
	call CtrlPanel_LookupIndicatorEntry
	or xiz, xhl

IndBitmask_ReturnResult:
	ld xhl, xiz
	pop xiz
	ret

Part_BitmaskToIndexList:
	lds iy, 0
	lda xde, (0x90fb:16)
	ld (xde), 0xff
	lds hl, 0

BitmaskToIndex_ScanLoop:
	or xwa, xwa
	jr z, BitmaskToIndex_Terminate
	bit 0, wa
	jr z, BitmaskToIndex_ShiftAndAdvance
	ld bc, iy
	inc 1, iy
	ld ix, bc
	extz xix
	add xix, xde
	ld c, l
	ld (xix), c

BitmaskToIndex_ShiftAndAdvance:
	srl xwa, 1
	inc 1, hl
	cp hl, 0x20
	jr c, BitmaskToIndex_ScanLoop

BitmaskToIndex_Terminate:
	ld wa, iy
	extz xwa
	add xwa, xde
	ld (xwa), 0xff
	ret

Audio_IteratePartsWithVolume:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), c
	ld (xsp + 4), a
	lds iz, 0

VolumeIter_NextPart:
	lda xwa, (0x90fb:16)
	ld bc, iz
	extz xbc
	add xbc, xwa
	ld a, (xbc)
	cp a, 0xff
	jr z, VolumeIter_Done
	cp a, 2:i3
	jr nz, VolumeIter_ApplyParam
	cp (xsp + 2), 0x2
	jr nz, VolumeIter_AdvancePart

VolumeIter_ApplyParam:
	ld (0x917e:16), 178
	mrib4 0x81, 0x19, 0x7f, 0x91
	mrdb5 0x8f, 0x04, 0x19, 0x80, 0x91
	ld (0x9181:16), 127
	call MIDI_LoadParamsAndDispatchCC
	lda xwa, (0x90fb:16)
	ld bc, iz
	extz xbc
	add xbc, xwa
	ld a, (xbc)
	extz wa
	calr VoiceData_LookupPtrByIndex
	bitm 5, (xhl + 13)
	jr nz, VolumeIter_AdvancePart
	ld a, (0x917e:16)
	extz wa
	ld c, (0x917f:16)
	extz bc
	ld e, (0x9180:16)
	extz de
	ld l, (0x9181:16)
	extz hl
	pushw hl
	call AddswbWr

VolumeIter_AdvancePart:
	inc 1, iz
	cp iz, 0x20
	jr c, VolumeIter_NextPart

VolumeIter_Done:
	popw iz
	inc 4, xsp
	ret

Audio_IteratePartsWithExpression:
	dec 2, xsp
	push xiz
	ld (xsp + 4), c
	ld c, a
	sll c, 6
	and c, 0x40
	ldb_erp C, 0xfa
	srl a, 1
	ldb_erp A, 0xfb
	res_erpb 0xfb, 0x07
	stb_erp C, 0xfb
	extz bc
	sll bc, 8
	stb_erp A, 0xfa
	extz wa
	add wa, bc
	cp wa, 0x7f40
	jr c, ExprIter_Start
	ldi_erpb 0xfb, 0x7f
	ldi_erpb 0xfa, 0x7f

ExprIter_Start:
	lds iz, 0

ExprIter_NextPart:
	lda xwa, (0x90fb:16)
	ld bc, iz
	extz xbc
	add xbc, xwa
	ld a, (xbc)
	cp a, 0xff
	jr z, ExprIter_Done
	cp a, 2:i3
	jr nz, ExprIter_ApplyParam
	cp (xsp + 4), 0x2
	jr nz, ExprIter_AdvancePart

ExprIter_ApplyParam:
	ld (0x917e:16), 177
	mrib4 0x81, 0x19, 0x7f, 0x91
	stb_erp A, 0xfa
	ld (0x9180:16), a
	stb_erp A, 0xfb
	ld (0x9181:16), a
	call MIDI_LoadParamsAndDispatchCC
	lda xwa, (0x90fb:16)
	ld bc, iz
	extz xbc
	add xbc, xwa
	ld a, (xbc)
	extz wa
	calr VoiceData_LookupPtrByIndex
	bitm 5, (xhl + 13)
	jr nz, ExprIter_AdvancePart
	ld a, (0x917e:16)
	extz wa
	ld c, (0x917f:16)
	extz bc
	ld e, (0x9180:16)
	extz de
	ld l, (0x9181:16)
	extz hl
	pushw hl
	call AddswbWr

ExprIter_AdvancePart:
	inc 1, iz
	cp iz, 0x20
	jr c, ExprIter_NextPart

ExprIter_Done:
	pop xiz
	inc 2, xsp
	ret

Audio_IteratePartsWithPan:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), c
	ld (xsp + 4), a
	lds iz, 0

PanIter_NextPart:
	lda xbc, (0x90fb:16)
	ld wa, iz
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, 0xff
	jr z, PanIter_Done
	cp a, 2:i3
	jr nz, PanIter_ApplyParam
	cp (xsp + 2), 0x2
	jr nz, MidiLoadParams_ContinueLoop

PanIter_ApplyParam:
	extz wa
	calr VoiceData_LookupPtrByIndex
	bitm 4, (xhl + 12)
	jr z, MidiLoadParams_ContinueLoop
	ld (0x917e:16), 180
	lda xwa, (0x90fb:16)
	ld bc, iz
	extz xbc
	add xbc, xwa
	mrib4 0x81, 0x19, 0x7f, 0x91
	mrdb5 0x8f, 0x04, 0x19, 0x80, 0x91
	ld (0x9181:16), 255
	call MIDI_LoadParamsAndDispatchCC
	lda xwa, (0x90fb:16)
	ld bc, iz
	extz xbc
	add xbc, xwa
	ld a, (xbc)
	extz wa
	calr VoiceData_LookupPtrByIndex
	bitm 5, (xhl + 13)
	jr nz, MidiLoadParams_ContinueLoop
	ld a, (0x917e:16)
	extz wa
	ld c, (0x917f:16)
	extz bc
	ld e, (0x9180:16)
	extz de
	ld l, (0x9181:16)
	extz hl
	pushw hl
	call AddswbWr

MidiLoadParams_ContinueLoop:
	inc 1, iz
	cp iz, 0x20
	jrl c, PanIter_NextPart

PanIter_Done:
	popw iz
	inc 4, xsp
	ret

MIDI_DispatchVoiceParamCC:
	dec 2, xsp
	pushw iz
	ld (xsp + 2), a
	cp (0xfd32:16), 183
	jr nz, VoiceParamCC_Done
	lds iz, 0

VoiceParamCC_NextPart:
	lda xbc, (0x90fb:16)
	ld wa, iz
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, 0xff
	jr z, VoiceParamCC_Done
	extz wa
	calr VoiceData_LookupPtrByIndex
	bitm 5, (xhl + 4)
	jr z, VoiceParamCC_AdvancePart
	ld (0x917e:16), 179
	lda xwa, (0x90fb:16)
	ld bc, iz
	extz xbc
	add xbc, xwa
	mrib4 0x81, 0x19, 0x7f, 0x91
	mrdb5 0x8f, 0x02, 0x19, 0x80, 0x91
	ld (0x9181:16), 127
	call MIDI_LoadParamsAndDispatchCC
	lda xwa, (0x90fb:16)
	ld bc, iz
	extz xbc
	add xbc, xwa
	ld a, (xbc)
	extz wa
	calr VoiceData_LookupPtrByIndex
	bitm 5, (xhl + 13)
	jr nz, VoiceParamCC_AdvancePart
	ld a, (0x917e:16)
	extz wa
	ld c, (0x917f:16)
	extz bc
	ld e, (0x9180:16)
	extz de
	ld l, (0x9181:16)
	extz hl
	pushw hl
	call AddswbWr

VoiceParamCC_AdvancePart:
	inc 1, iz
	cp iz, 0x20
	jr c, VoiceParamCC_NextPart

VoiceParamCC_Done:
	popw iz
	inc 2, xsp
	ret

UIState_CheckAndRenderBitmap:
	pushw	iz
	.byte 0xc1
	jrl	pl, 16320
	push	sr
	jr	nz, 67
	ld	a, (0xc07f:16)
	and	a, 255
	jr	z, 58
	ld	a, (0xc07e:16)
	and	a, 255
	cp	a, 183
	jr	z, 32
	cp	a, 182
	jr	nz, 41
	lds	iz, 0
	pushw	3
	ld	wa, iz
	ldw	bc, 11
	ldw	de, 127
	call	SndParam_NotifyAndReturn
	inc	1, iz
	cp	iz, 15
	jr	ule, -23
	jr	14
	ld	xwa, 0x4001
	ldw	bc, 127
	lds	de, 3
	call	SoundParam_NotifyChange
	popw	iz
	ret
UIState_RenderBitmapData:
	.byte 0xc1
	jrl	pl, 16320
	halt
	jr	nz, 38
	ld	a, (0xc07f:16)
	res	7, a
	cp	a, 0:i3
	jr	z, 27
	ld	c, (0xc07e:16)
	res	7, c
	cp	c, 0:i3
	jr	z, 16
	ld	a, (0xc080:16)
	extz	wa
	lda	xde, (0x918d:16)
	extz	xwa
	add	xwa, xde
	ld	(xwa), c
	.byte 0xc1
	jrl	pl, 16320
	incf
	jr	nz, 30
	.byte 0xf1
	jrl	nc, -13120
	jr	z, 24
	.byte 0xf1
	jrl	nz, -13120
	jr	nz, 18
	ld	a, (0xc080:16)
	extz	wa
	pushw	3
	ldw	bc, 434
	lds	de, 0
	call	SndParam_NotifyAndReturn
	.byte 0xc1
	jrl	pl, 16320
	max
	ret	nz
	.byte 0xf1
	jrl	nc, -12864
	ret	z
	.byte 0xf1
	jrl	nz, -12864
	ret	nz
	ld	a, (0xc080:16)
	extz	wa
	pushw	3
	ldw	bc, 11
	ldw	de, 127
	call	SndParam_NotifyAndReturn
	ret
ToshiCmd_DefaultHandler_Ret:
	ret

SndParam_FetchSequencerParams:
	ld wa, (0x9133:16)
	ld bc, wa
	inc 1, wa
	ld (0x9133:16), wa
	lda xwa, (0xc039:16)
	extz xbc
	add xbc, xwa
	mrib4 0x81, 0x19, 0x27, 0x91
	ld a, (0x9127:16)
	extz wa
	calr VoiceData_LookupPtrByIndex
	ld (0x912b:16), xhl
	ld wa, (0x9133:16)
	ld de, wa
	inc 1, wa
	ld (0x9133:16), wa
	lda xbc, (0xc039:16)
	extz xde
	add xde, xbc
	ld a, (xde)
	ld (0x9128:16), a
	ld (0x912f:16), a
	ld wa, (0x9133:16)
	ld de, wa
	inc 1, wa
	ld (0x9133:16), wa
	extz xde
	add xde, xbc
	mrib4 0x82, 0x19, 0x30, 0x91
	ld (0x9129:16), 0
	ld wa, (0x9133:16)
	ld de, wa
	inc 1, wa
	ld (0x9133:16), wa
	extz xde
	add xde, xbc
	mrib4 0x82, 0x19, 0x31, 0x91
	ld (0x912a:16), 0
	ret

SndParam_WriteLookupAndStore:
	ld	a, (0x9127:16)
	extz	wa
	calr	1959
	cp	xhl, 0xffffffff
	ret	z
	ld	a, (0x912f:16)
	extz	wa
	.byte 0xc3
	reti
	or	xwa, xix
	pop_f
	ldw	de, 3729

SwbtWr_FlushAndAppendParams:
	cp (0x912a:16), 0
	ret z
	cpw (0x90de:16), 508
	jr c, SwbtWr_FlushDone
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw (0x90de:16), 0

SwbtWr_FlushDone:
	calr SwbtWr_AppendFixedParamBlock
	ret

SwbtWr_CheckBufferOverflow:
	cpw	(0x90de:16), 508
	jr	c, 18
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SwbtWr_ReinitBothBanks
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ldw	(0x90de:16), 0
	jrl	1770

SwbtWr_WriteParamBlock:
	cpw (0x90de:16), 508
	jr c, SwbtWr_WriteParamBlock_Body
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitOutputBank
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw (0x90de:16), 0

SwbtWr_WriteParamBlock_Body:
	jrl SwbtWr_AppendFixedParamBlock
	dec 2, xsp
	ld (xsp), a
	ld c, (0x9131:16)
	ld a, c
	and a, (xsp)
	jr z, Voice_Update_Return
	ld a, (0x9130:16)
	and a, c
	jr z, Voice_Update_Return
	ld a, (0x9127:16)
	extz wa
	calr VoiceData_LookupPtrByIndex
	cp xhl, 0xffffffff
	jr z, Voice_Update_Return
	ld a, (0x912f:16)
	extz wa
	lda_dri XHL, 0x07, 0xec, 0xe0
	ld a, (0x9130:16)
	and a, (0x9131:16)
	xor (xhl), a
	ld c, (0x9132:16)
	cp (xhl), c
	jr z, Voice_Update_Return
	ld a, (xhl)
	xor a, c
	and a, (xsp)
	or (0x912a:16), a
	mrib4 0x83, 0x19, 0x32, 0x91
	mrib4 0x83, 0x19, 0x29, 0x91

Voice_Update_Return:
	inc 2, xsp
	ret

VoiceParam_CompareAndUpdate:
	dec	2, xsp
	ld	(xsp), a
	ld	a, (0x9131:16)
	.byte 0x87
	and	a, (0x4866:16)
	ldw	wa, 8593
	.byte 0x87
	and	a, (0x4066:16)
	ldb	l, 145
	ldb	a, 216
	ccf
	calr	1724
	cp	xhl, 0xffffffff
	jr	z, 47
	ld	a, (0x912f:16)
	extz	wa
	lda_rr xhl, xhl, wa
	ld a, (xsp)
	cpl	a
	.byte 0x83, 0xc1
	or	a, (0x9130:16)
	ld	c, a
	ld	a, (0x9132:16)
	cp	c, a
	jr	z, 16
	ld	(xhl), c
	ld	(0x9132:16), c
	ld	(0x9129:16), c
	ld	a, (xsp)
	or	(0x912a:16), a
	inc	2, xsp
	ret
	dec	2, xsp
	ld	(xsp), a
	ld	a, (0x9131:16)
	.byte 0x87
	and	a, (0x4066:16)
	ldb	l, 145
	ldb	a, 216
	ccf
	calr	1645
	cp	xhl, 0xffffffff
	jr	z, 47
	ld	a, (0x912f:16)
	extz	wa
	lda_rr xhl, xhl, wa
	ld a, (xsp)
	cpl	a
	.byte 0x83, 0xc1
	or	a, (0x9130:16)
	ld	c, a
	ld	a, (0x9132:16)
	cp	c, a
	jr	z, 16
	ld	(xhl), c
	ld	(0x9132:16), c
	ld	(0x9129:16), c
	ld	a, (xsp)
	or	(0x912a:16), a
	inc	2, xsp
	ret
	dec	2, xsp
	ld	(xsp), a
	ld	a, (0x9131:16)
	.byte 0x87
	and	a, (0x4a66:16)
	ldw	wa, 8593
	.byte 0x87
	and	a, (0x4266:16)
	ldb	l, 145
	ldb	a, 216
	ccf
	calr	1558
	cp	xhl, 0xffffffff
	jr	z, 49
	ld	a, (0x912f:16)
	extz	wa
	lda_rr xhl, xhl, wa
	ld c, (xsp)
	cpl	c
	ld	e, c
	.byte 0x83, 0xc5
	or	e, (0x9130:16)
	ld	a, (0x9132:16)
	cp	e, a
	jr	nz, 2
	and	e, c
	ld	(xhl), e
	ld	(0x9132:16), e
	ld	(0x9129:16), e
	ld	a, (xsp)
	or	(0x912a:16), a
	inc	2, xsp
	ret
	dec	2, xsp
	ld	(xsp), a
	ld	a, (0x9131:16)
	.byte 0x87
	and	a, (0x4266:16)
	ldb	l, 145
	ldb	a, 216
	ccf
	calr	1477
	cp	xhl, 0xffffffff
	jr	z, 49
	ld	a, (0x912f:16)
	extz	wa
	lda_rr xhl, xhl, wa
	ld c, (xsp)
	cpl	c
	ld	e, c
	.byte 0x83, 0xc5
	or	e, (0x9130:16)
	ld	a, (0x9132:16)
	cp	e, a
	jr	nz, 2
	and	e, c
	ld	(xhl), e
	ld	(0x9132:16), e
	ld	(0x9129:16), e
	ld	a, (xsp)
	or	(0x912a:16), a
	inc	2, xsp
	ret
	dec	2, xsp
	ld	(xsp), c
	ld	c, (0x9131:16)
	and	c, a
	jr	z, 94
	ld	c, (0x9130:16)
	and	c, a
	jr	z, 86
	ld	a, (0x9127:16)
	extz	wa
	calr	1388
	cp	xhl, 0xffffffff
	jr	z, 69
	ld	a, (0x912f:16)
	extz	wa
	lda_rr xhl, xhl, wa
	ld e, (xhl)
	.byte 0x87, 0xc5
	ld	c, (0x9153:16)
	ld	a, e
	add	a, c
	cp	a, (37204:16)
	jr	nc, 4
	add	e, c
	jr	4
	ld	e, (0x9155:16)
	ld	a, (xsp)
	cpl	a
	.byte 0x83
	and	a, (0xe5c9:16)
	ldw	de, 8593
	cp	e, a
	jr	z, 16
	ld	(xhl), e
	ld	(0x9132:16), e
	ld	(0x9129:16), e
	ld	a, (xsp)
	or	(0x912a:16), a
	inc	2, xsp
	ret
	dec	2, xsp
	ld	(xsp), a
	ld	a, (0x9131:16)
	.byte 0x87
	and	a, (0x3c66:16)
	ldb	l, 145
	ldb	a, 216
	ccf
	calr	1287
	cp	xhl, 0xffffffff
	jr	z, 43
	ld	a, (0x912f:16)
	extz	wa
	lda_rr xhl, xhl, wa
	ld a, (xsp)
	cpl	a
	.byte 0x83
	and	a, (0x8bc9:16)
	ldw	wa, 8593
	.byte 0x87, 0xc1
	or	a, c
	ld	(xhl), a
	ld	(0x9132:16), a
	ld	(0x9129:16), a
	ld	a, (xsp)
	or	(0x912a:16), a
	inc	2, xsp
	ret

ToneGen_ApplyVoiceParams:
	dec 6, xsp
	ld (xsp), e
	ld (xsp + 2), c
	ld (xsp + 4), a
	cp (xsp + 10), 0x0
	jr z, ToneGen_DispatchStartVoice
	ld a, (xsp + 4)
	extz wa
	calr VoiceData_LookupPtrByIndex
	cp xhl, 0xffffffff
	jr z, ToneGen_DispatchStartVoice
	ld a, (xsp + 2)
	extz wa
	lda_dri XHL, 0x07, 0xec, 0xe0
	ld c, (xhl)
	ld (0x9132:16), c
	ld e, (xsp)
	and e, (xsp + 10)
	ld a, (xsp + 10)
	cpl a
	and a, c
	or a, e
	ld e, a
	xor a, c
	and a, (xsp + 10)
	jr z, ToneGen_DispatchStartVoice
	ld (xhl), e
	mrdb5 0x8f, 0x04, 0x19, 0x27, 0x91
	mrdb5 0x8f, 0x02, 0x19, 0x28, 0x91
	ld (0x9129:16), e
	ld (0x912a:16), a

ToneGen_DispatchStartVoice:
	inc 6, xsp
	retd 0x2
	dec 6, xsp
	pushw_erp 0xfa
	cp (0xc07d:16), 3
	jr nz, ToneGen_Dispatch_Return
	bit 0, (0xc07f:16)
	jr z, ToneGen_Dispatch_Return
	ldw wa, 0x90
	calr VoiceData_LookupPtrByIndex
	ld (xsp + 2), xhl
	ld xbc, (xsp + 2)
	ld a, (xbc)
	ldb_erp A, 0xfb
	ld a, (xbc + 1)
	ld (xsp + 6), a
	call ToneGen_DispatchByMode
	stb_erp C, 0xfb
	ld xwa, (xsp + 2)
	xor c, (xwa)
	and c, 0x3
	jr z, ToneGen_Dispatch_Return
	ld c, (xsp + 6)
	xor c, (xwa + 1)
	bit 1, c
	jr z, ToneGen_Dispatch_Return
	ld e, (xwa)
	extz de
	pushw 0x1f
	ldw wa, 0x90
	lds bc, 0
	call AddswbWr
	ld xwa, (xsp + 2)
	ld e, (xwa + 1)
	extz de
	pushw 0x1f
	ldw wa, 0x90
	lds bc, 1
	call AddswbWr

ToneGen_Dispatch_Return:
	popw_erp 0xfa
	inc 6, xsp
	ret

SwbtWr_NullRet:
	ret

Audio_FlushPendingBankSelects:
	ld a, (0x8ee2:16)
	bit 7, a
	jr z, BankFlush_CheckChannel1
	res 7, a
	ld (0x8ee2:16), a
	ld (0x9127:16), 176
	ld (0x9128:16), 0
	ld (0x9129:16), a
	ld (0x912a:16), 127
	calr SwbtWr_FlushAndAppendParams

BankFlush_CheckChannel1:
	ld a, (0x8ee0:16)
	bit 7, a
	ret z
	res 7, a
	ld (0x8ee0:16), a
	ld (0x9127:16), 176
	ld (0x9128:16), 1
	ld (0x9129:16), a
	ld (0x912a:16), 127
	calr SwbtWr_FlushAndAppendParams
	ret

UIWidget_MidiStreamControl:
	.byte 0xc1
	jrl	pl, 16320
	nop
	ret	nz
	ld	a, (0xc07f:16)
	and	a, 3
	.byte 0xf2
	jr	nov, -102
	swi	4
	cp	xbc, xiz
	jrl	nc, -13632
	ret	z
	.byte 0xf1
	jrl	nz, -13632
	ret	nz
	.byte 0xf1
	swi	1
	.byte 0x90, 0xbc
	call	SeqTimer_UpdateTempoReg
	.byte 0xf1
	swi	1
	.byte 0x90, 0xb4
	ret
	lds	wa, 0
	lda	xbc, (0x93d2:16)
	stib_dsp 228, 0
	stib_dsp 228, 0
	inc	1, wa
	cp	wa, 32
	jr	c, -16
	lds	wa, 0
	lda	xbc, (0x9412:16)
	stib_dsp 228, 0
	inc	1, wa
	cp	wa, 32
	jr	c, -12
	ret

SndParam_ApplyAndFetch:
	dec 6, xsp
	lda xwa, (xsp)
	lda xde, (0x90ea:16)
	ld c, (xde)
	ld (xwa), c
	ld c, (xde + 1)
	ld (xwa + 1), c
	ld c, (xde + 2)
	ld (xwa + 2), c
	cp c, 0x1f
	jr ugt, SndParam_CheckRhythm
	call SndParam_ApplyProgramChange
	lda xde, (0x90ee:16)
	lda xbc, (xsp)
	ld a, (xbc + 3)
	ld (xde), a
	ld a, (xbc + 4)
	ld (xde + 1), a
	jr SndParam_ApplyDone

SndParam_CheckRhythm:
	cp c, 0x48
	call z, (Rhythm_LookupTempoVelocity_Wrap:24)

SndParam_ApplyDone:
	inc 6, xsp
	ret

SndParam_ApplyFromPointer:
	push	xiz
	ld	xiz, xwa
	lda	xde, (xiz+2)
	ld	a, (xde)
	cp	a, 31
	jr	ugt, 8
	ld	xwa, xiz
	call	SndParam_ApplyProgramChange
	jr	43
	cp	a, 72
	jr	nz, 38
	lda	xbc, (0x90ea:16)
	ld	a, (xiz)
	ld	(xbc), a
	ld	a, (xiz+1)
	ld	(xbc+1), a
	ld	a, (xde)
	ld	(xbc+2), a
	call	Rhythm_LookupTempoVelocity_Wrap
	lda	xbc, (0x90ee:16)
	ld	a, (xbc)
	ld	(xiz+3), a
	ld	a, (xbc+1)
	ld	(xiz+4), a
	pop xiz
	ret

SndParam_FetchAndStore:
	dec 6, xsp
	lda xwa, (xsp)
	lda xde, (0x90ea:16)
	ld c, (xde)
	ld (xwa + 3), c
	ld c, (xde + 1)
	ld (xwa + 4), c
	ld c, (xde + 2)
	ld (xwa + 2), c
	cp c, 0x1f
	jr ugt, SndParam_FetchCheckRhythm
	call SndParam_FetchOscTableEntry
	lda xde, (0x90ee:16)
	lda xbc, (xsp)
	ld a, (xbc)
	ld (xde), a
	ld a, (xbc + 1)
	ld (xde + 1), a
	jr SndParam_FetchDone

SndParam_FetchCheckRhythm:
	cp c, 0x48
	call z, (Rhythm_DispatchNote_Finalize:24)

SndParam_FetchDone:
	inc 6, xsp
	ret

SndParam_ResolveVoiceEntry:
	push xiz
	ld xiz, xwa
	lda xde, (xiz + 2)
	ld a, (xde)
	cp a, 0x1f
	jr ugt, SndParamResolve_CheckRhythm
	ld xwa, xiz
	call SndParam_FetchOscTableEntry
	jr SndParamResolve_Done

SndParamResolve_CheckRhythm:
	cp a, 0x48
	jr nz, SndParamResolve_Done
	lda xbc, (0x90ea:16)
	ld a, (xiz + 3)
	ld (xbc), a
	ld a, (xiz + 4)
	ld (xbc + 1), a
	ld a, (xde)
	ld (xbc + 2), a
	call Rhythm_DispatchNote_Finalize
	lda xbc, (0x90ee:16)
	ld a, (xbc)
	ld (xiz), a
	ld a, (xbc + 1)
	ld (xiz + 1), a

SndParamResolve_Done:
	pop xiz
	ret

SndBuf_WriteParamEntries:
	dec	6, xsp
	lda	xwa, (xsp)
	lda	xde, (0x90ea:16)
	ld	c, (xde)
	ld	(xwa), c
	ld	c, (xde+1)
	ld	(xwa+1), c
	ld	c, (xde+2)
	ld	(xwa+2), c
	ld	c, (xde+3)
	ld	(xwa+5), c
	call	SndParam_CheckAndApplyMode
	lda	xde, (0x90ee:16)
	lda	xbc, (xsp)
	ld	a, (xbc+3)
	ld	(xde), a
	ld	a, (xbc+4)
	ld	(xde+1), a
	inc	6, xsp
	ret
	dec	6, xsp
	lda	xwa, (xsp)
	lda	xde, (0x90ea:16)
	ld	c, (xde)
	ld	(xwa+3), c
	ld	c, (xde+1)
	ld	(xwa+4), c
	ld	c, (xde+2)
	ld	(xwa+5), c
	call	SndParam_ComputeVoiceIndex
	lda	xde, (0x90ee:16)
	lda	xbc, (xsp)
	ld	a, (xbc)
	ld	(xde), a
	ld	a, (xbc+1)
	ld	(xde+1), a
	ld	a, (xbc+2)
	ld	(xde+2), a
	inc	6, xsp
	ret
	dec	6, xsp
	ld	a, (0x90f7:16)
	lda	xbc, (0x916f:16)
	lda	xde, (xbc+1)
	cp	a, 31
	jr	ugt, 48
	lda	xwa, (xsp)
	ld	c, (xbc)
	ld	(xwa+3), c
	ld	c, (xde)
	ld	(xwa+4), c
	.byte 0xb8
	push	sr
	push_a
	ldx
	.byte 0x90
	call	ApplyProgramChangeAs_LoadReg2_0xA
	lda	xbc, (0x90ee:16)
	lda	xwa, (xsp)
	ld	l, (xwa)
	ld	(xbc), l
	lda	xde, (0x916b:16)
	ld	(xde), l
	ld	a, (xwa+1)
	ld	(xbc+1), a
	ld	(xde+1), a
	jr	36
	cp	a, 72
	jr	nz, 31
	lda	xhl, (0x90ea:16)
	ld	a, (xbc)
	ld	(xhl), a
	ld	a, (xde)
	ld	(xhl+1), a
	.byte 0xbb
	push	sr
	push_a
	ldx
	.byte 0x90
	nop
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	Rhythm_DispatchNote_Finalize
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	lda	xde, (0x9173:16)
	lda	xbc, (0x90ee:16)
	ld	a, (xbc)
	ld	(xde), a
	ld	a, (xbc+1)
	ld	(xde+1), a
	ld	a, (xbc+3)
	ld	(xde+2), a
	inc	6, xsp
	ret

SndParam_UpdateVoiceEntry:
	dec 8, xsp
	pushw_erp 0xfa
	ld (xsp + 4), e
	ld (xsp + 6), c
	ld (xsp + 8), a
	cp (xsp + 8), 0x1f
	jr ugt, SndParamUpdate_Done
	ld a, (xsp + 6)
	extz wa
	ld c, (xsp + 4)
	extz bc
	call ApplyProgramChangeAs_Prologue
	ldib_erp 0xfb, 0
	cp l, 0:i3
	jr z, SndParamUpdate_SetResBit6
	ldi_erpb 0xfb, 0x40

SndParamUpdate_SetResBit6:
	ld (xsp + 2), 0x40
	ld c, (xsp + 4)
	extz bc
	sll bc, 8
	ld a, (xsp + 6)
	extz wa
	add wa, bc
	call MIDI_ParamValidate_CheckBit2
	cp hl, 0:i3
	jr z, SndParamUpdate_DispatchWrite
	ldib_erp 0xfb, 0
	setm 3, (xsp + 2)

SndParamUpdate_DispatchWrite:
	ld a, (xsp + 8)
	extz wa
	stb_erp E, 0xfb
	extz de
	ld c, (xsp + 2)
	extz bc
	pushw bc
	lds bc, 4
	calr ToneGen_ApplyVoiceParams
	ld a, (0x912a:16)
	and a, 0x48
	call nz, (SwbtWr_FlushAndAppendParams:24)

SndParamUpdate_Done:
	popw_erp 0xfa
	inc 8, xsp
	ret

MIDI_DistributeParamToChannels:
	dec 8, xsp
	ld (xsp + 2), e
	ld (xsp + 4), c
	ld (xsp + 6), a
	cp (xsp + 6), 0x1f
	jr ugt, MidiDistribute_CheckRhythm
	call ApplyProgramChangeAs_DoLookupRe
	ld (xsp), l

MidiDistribute_LookupAndWrite:
	ld a, (xsp + 6)
	extz wa
	calr VoiceData_LookupPtrByChannel
	cp xhl, 0xffffffff
	jr z, MidiDistribute_Fallthrough
	ld c, (xsp + 4)
	cp c, (xsp)
	jr ugt, MidiDistribute_Fallthrough
	extz bc
	ld a, (xsp + 2)
	stb_dri A, 0x07, 0xec, 0xe4

MidiDistribute_Fallthrough:
	jr MidiDistribute_Done

MidiDistribute_CheckRhythm:
	cp (xsp + 6), 0x48
	jr nz, MidiDistribute_Done
	ld (xsp), 0xf
	jr MidiDistribute_LookupAndWrite

MidiDistribute_Done:
	inc 8, xsp
	ret

VoiceData_DistributeToChannels:
	dec	8, xsp
	ld	(xsp+4), c
	ld	(xsp+6), a
	ld	(xsp+2), 0
	.byte 0x8f, 0x06
	push	xsp
	.byte 0x1f
	jr	ugt, 44
	call	ApplyProgramChangeAs_DoLookupRe
	ld	(xsp), l
	ld	a, (xsp+6)
	extz	wa
	calr	163
	cp	xhl, 0xffffffff
	jr	z, 17
	ld	a, (xsp+4)
	.byte 0x87, 0xf1
	jr	ugt, 10
	extz	wa
	ld_rrb a, xhl, wa
	ld (xsp+2), a
	ld l, (xsp+2)
	jr 13
	.byte 0x8f, 0x06
	push	xsp
	popw	wa
	jr	nz, 5
	ld	(xsp), 15
	jr	-49
	ldb	l, 0
	inc	8, xsp
	ret

SwbtWr_AppendFixedParamBlock:
	ld wa, (0x90de:16)
	ld de, wa
	inc 1, wa
	ld (0x90de:16), wa
	lda xbc, (0xbd3c:16)
	extz xde
	add xde, xbc
	ldmi16 (xde), 0x9127
	ld wa, (0x90de:16)
	ld de, wa
	inc 1, wa
	ld (0x90de:16), wa
	extz xde
	add xde, xbc
	ldmi16 (xde), 0x9128
	ld wa, (0x90de:16)
	ld de, wa
	inc 1, wa
	ld (0x90de:16), wa
	extz xde
	add xde, xbc
	ldmi16 (xde), 0x9129
	ld wa, (0x90de:16)
	ld de, wa
	inc 1, wa
	ld (0x90de:16), wa
	extz xde
	add xde, xbc
	ldmi16 (xde), 0x912a
	ld wa, (0x90de:16)
	extz xwa
	add xwa, xbc
	ld (xwa), 0xff
	ld (0x912a:16), 0
	ret

VoiceData_LookupPtrByIndex:
	extz wa
	sla wa, 2
	lda xbc, (SoundProgram_DispatchTable_0x400:24)
	ld_sril3 XHL, 0x07, 0xe4, 0xe0
	ret

VoiceData_LookupPtrByChannel:
	cp a, 0x1f
	jr ugt, VoiceLookup_CheckRhythm
	extz wa
	sla wa, 2
	lda xbc, (SoundProgram_DispatchTable_0x800:24)
	ld_sril3 XHL, 0x07, 0xe4, 0xe0
	ret

VoiceLookup_CheckRhythm:
	cp a, 0x48
	jr nz, VoiceLookup_ReturnInvalid
	lda xhl, (0xff92:16)
	ret

VoiceLookup_ReturnInvalid:
	ld xhl, 0xffffffff
	ret

VoiceChannels_InitPanFromPreset:
	push xiz
	ld iz, (0xf290:16)
	ldiw_erp 0xfa, 0

VoicePanInit_Loop:
	lda xwa, (0x90ce:16)
	stw_erp BC, 0xfa
	extz xbc
	add xbc, xwa
	ld (xbc), 0x10
	bit 0, iz
	jr z, ToneGen_IncrementAndExit
	lda xwa, (0xf1a0:16)
	stw_erp BC, 0xfa
	extz xbc
	add xbc, xwa
	ld a, (xbc)
	extz wa
	lda xbc, (SoundProgram_DispatchTable_0x8F4:24)
	ldb_sri A, 0x07, 0xe4, 0xe0
	calr VoiceData_LookupPtrByIndex
	cp xhl, 0xffffffff
	jr z, ToneGen_IncrementAndExit
	ld c, (xhl + 13)
	ld a, c
	and a, 0xc0
	jr nz, ToneGen_IncrementAndExit
	lda xwa, (0x90ce:16)
	stw_erp DE, 0xfa
	extz xde
	add xde, xwa
	and c, 0xf
	ld (xde), c

ToneGen_IncrementAndExit:
	srl iz, 1
	inc1w_erp 0xfa
	cp_erpw 0xfa, 0x10, 0x00
	jr c, VoicePanInit_Loop
	pop xiz
	ret

; =============================================================================
; SoundPreset_FindMatch -- Find matching preset in ROM tables
; =============================================================================
; Compares current params against all presets to find active one.
; Args: a = type (0/1/2), bc = search params
; Returns: hl = matched index, or 0xffff if no match
SoundPreset_FindMatch:
	cp a, 2:i3
	jrl z, SoundPreset_FindMatch_Combined
	cp a, 1:i3
	jr z, EQPreset_FindMatch
	cp a, 0:i3
	jr z, SoundPreset_FindMatch_Reverb
	ldw hl, 0xffff
	ret

SoundPreset_FindMatch_Reverb:
	pushw iz
	lds iz, 0

ReverbPreset_SearchLoop:
	pushw 0x18
	pushw 0x0
	pushw 0xfc8e
	ld wa, iz
	extz xwa
	sll xwa, 2
	ld xbc, SoundProgram_DispatchTable_0x908
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	call Mem_Compare
	add xsp, 0xa
	cp hl, 0:i3
	jr nz, ReverbPreset_NextEntry
	ld hl, iz
	jr ReverbPreset_SearchDone

ReverbPreset_NextEntry:
	inc 1, iz
	cp iz, 0xa
	jr c, ReverbPreset_SearchLoop
	ldw hl, 0xffff

ReverbPreset_SearchDone:
	popw iz
	ret

EQPreset_FindMatch:
	pushw iz
	lds iz, 0

EQPreset_SearchLoop:
	pushw 0x18
	pushw 0x0
	pushw 0xfca8
	ld wa, iz
	extz xwa
	sll xwa, 2
	ld xbc, Naka_ToshiParam_Table_0x24
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	call Mem_Compare
	add xsp, 0xa
	cp hl, 0:i3
	jr nz, EQPreset_NextEntry
	ld hl, iz
	jr EQPreset_SearchDone

EQPreset_NextEntry:
	inc 1, iz
	cp iz, 0x9
	jr c, EQPreset_SearchLoop
	ldw hl, 0xffff

EQPreset_SearchDone:
	popw iz
	ret

SoundPreset_FindMatch_Combined:
	pushw iz
	lds iz, 0

CombinedPreset_SearchLoop:
	pushw 0x18
	pushw 0x0
	pushw 0xfc8e
	ld wa, iz
	extz xwa
	sll xwa, 2
	ld xbc, Naka_ToshiParam_Table_0x48
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	call Mem_Compare
	add xsp, 0xa
	cp hl, 0:i3
	jr nz, CombinedPreset_NextEntry
	pushw 0x18
	pushw 0x0
	pushw 0xfca8
	ld wa, iz
	extz xwa
	sll xwa, 2
	ld xbc, Naka_ToshiParam_Table_0x48
	add xbc, xwa
	ld xwa, (xbc)
	lda xwa, (xwa + 24)
	push xwa
	call Mem_Compare
	add xsp, 0xa
	cp hl, 0:i3
	jr nz, CombinedPreset_NextEntry
	ld hl, iz
	jr SoundPreset_ReturnResult

CombinedPreset_NextEntry:
	inc 1, iz
	cp iz, 0x9
	jr c, CombinedPreset_SearchLoop
	ldw hl, 0xffff

SoundPreset_ReturnResult:
	popw iz
	ret

; =============================================================================
; SoundPreset_Dispatch -- Route preset load by type (reverb/EQ/combined)
; =============================================================================
; Dispatches to the appropriate preset loader based on the type parameter:
;   type 0 -> ReverbPreset_Load (reverb-only, 24 bytes via cmd 0x63)
;   type 1 -> EQPreset_Load (EQ-only, 24 bytes via cmd 0x64)
;   type 2 -> CombinedPreset_Load (reverb+EQ, 48 bytes)
; Args: a = preset type (0/1/2), bc = preset index
; Called from: MainRevEqPresetLoad
SoundPreset_Dispatch:
	ld e, a
	extz bc
	cp e, 2:i3
	jr z, SoundPreset_Dispatch_Combined
	cp e, 1:i3
	jr z, SoundPreset_Dispatch_EQ
	cp e, 0:i3
	ret nz
	ld wa, bc
	jr ReverbPreset_Load

SoundPreset_Dispatch_EQ:
	ld wa, bc
	jr EQPreset_Load

SoundPreset_Dispatch_Combined:
	ld wa, bc
	calr CombinedPreset_Load
	ret

; =============================================================================
; ReverbPreset_Load -- Load and send a reverb preset to the Sub CPU
; =============================================================================
; Reads 24-byte reverb preset from ROM table at 0xedb36c, copies to 0xfc8e,
; then sends all 24 bytes via cmd 0x63 to the Sub CPU DSP ring buffer.
; Preset: B0=algo_id, B1=REV_TIME, B3=PRE_DLY, B4=HI_DAMP, B5=ER_LVL, B22=99
; Args: wa = preset index (0-9)
ReverbPreset_Load:
	pushw iz
	extz wa
	sla wa, 2
	lda xbc, (SoundProgram_DispatchTable_0x908:24)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	pushw 0x18
	push xwa
	pushw 0x0
	pushw 0xfc8e
	call Mem_Copy
	lda xsp, (xsp + 10)
	lds iz, 0

ReverbPreset_SendLoop:
	stb_erp C, 0xf8
	extz bc
	lda xwa, (0xfc8e:16)
	ld de, iz
	extz xde
	add xde, xwa
	ld e, (xde)
	extz de
	pushw 0xff
	ldw wa, 0x63
	call AssswbWr
	inc 1, iz
	cp iz, 0x18
	jr c, ReverbPreset_SendLoop
	ld xwa, 0x4002
	ldw bc, 0x7f
	lds de, 1
	call SoundParam_NotifyChange
	popw iz
	ret

; =============================================================================
; EQPreset_Load -- Load and send an EQ preset to the Sub CPU
; =============================================================================
; Reads 24-byte EQ preset from ROM table at 0xedb394, copies to 0xfca8,
; sends via cmd 0x64. EQ uses algo 0x4f with 4 big-endian 16-bit frequencies.
; Args: wa = preset index (0-8)
EQPreset_Load:
	pushw iz
	extz wa
	sla wa, 2
	lda xbc, (Naka_ToshiParam_Table_0x24:24)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	pushw 0x18
	push xwa
	pushw 0x0
	pushw 0xfca8
	call Mem_Copy
	lda xsp, (xsp + 10)
	lds iz, 0

EQPreset_SendLoop:
	stb_erp C, 0xf8
	extz bc
	lda xwa, (0xfca8:16)
	ld de, iz
	extz xde
	add xde, xwa
	ld e, (xde)
	extz de
	pushw 0xff
	ldw wa, 0x64
	call AssswbWr
	inc 1, iz
	cp iz, 0x18
	jr c, EQPreset_SendLoop
	ld xwa, 0x4006
	lds bc, 1
	lds de, 1
	call SoundParam_NotifyChange
	popw iz
	ret

; =============================================================================
; CombinedPreset_Load -- Load combined reverb+EQ preset (48 bytes)
; =============================================================================
; Reads 48 bytes (24 reverb + 24 EQ) from ROM table at 0xedb3b8.
; Sends reverb with cmd 0x63, EQ (at offset +24) with cmd 0x64.
; Args: wa = preset index (0-8)
CombinedPreset_Load:
	dec 4, xsp
	pushw iz
	extz wa
	sla wa, 2
	lda xbc, (Naka_ToshiParam_Table_0x48:24)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld (xsp + 2), xwa
	pushw 0x18
	ld xwa, (xsp + 4)
	push xwa
	pushw 0x0
	pushw 0xfc8e
	call Mem_Copy
	lda xsp, (xsp + 10)
	lds iz, 0

CombinedPreset_SendReverbLoop:
	stb_erp C, 0xf8
	extz bc
	lda xwa, (0xfc8e:16)
	ld de, iz
	extz xde
	add xde, xwa
	ld e, (xde)
	extz de
	pushw 0xff
	ldw wa, 0x63
	call AssswbWr
	inc 1, iz
	cp iz, 0x18
	jr c, CombinedPreset_SendReverbLoop
	pushw 0x18
	ld xwa, (xsp + 4)
	lda xwa, (xwa + 24)
	push xwa
	pushw 0x0
	pushw 0xfca8
	call Mem_Copy
	lda xsp, (xsp + 10)
	lds iz, 0

CombinedPreset_SendEQLoop:
	stb_erp C, 0xf8
	extz bc
	lda xwa, (0xfca8:16)
	ld de, iz
	extz xde
	add xde, xwa
	ld e, (xde)
	extz de
	pushw 0xff
	ldw wa, 0x64
	call AssswbWr
	inc 1, iz
	cp iz, 0x18
	jr c, CombinedPreset_SendEQLoop
	ld xwa, 0x4002
	ldw bc, 0x7f
	lds de, 1
	call SoundParam_NotifyChange
	ld xwa, 0x4006
	lds bc, 1
	lds de, 1
	call SoundParam_NotifyChange
	popw iz
	inc 4, xsp
	ret

MIDI_MapCCToIndex:
	cp	a, 102
	jr	z, 36
	cp	a, 101
	jr	z, 28
	cp	a, 100
	jr	z, 20
	cp	a, 99
	jr	z, 12
	cp	a, 97
	jr	z, 4
	ldw	hl, 0xffff
	ret
	lds	hl, 0
	ret
	lds	hl, 1
	ret
	lds	hl, 4
	ret
	lds	hl, 2
	ret
	lds	hl, 3
	ret
	cp	a, 4:i3
	jr	z, 36
	cp	a, 3:i3
	jr	z, 28
	cp	a, 2:i3
	jr	z, 20
	cp	a, 1:i3
	jr	z, 12
	cp	a, 0:i3
	jr	z, 4
	ldw	hl, 0xffff
	ret
	ldw	hl, 97
	ret
	ldw	hl, 99
	ret
	ldw	hl, 101
	ret
	ldw	hl, 102
	ret
	ldw	hl, 100
	ret

SwbtWr_WriteVoiceParam_PreserveRegs:
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	call SwbtWr_FlushAndAppendParams
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	ret

AudioCtrl_PreserveRegs_PopEpilogue:	.ascii "89:;<=>"
	.byte 0x1d
	cp	(xwa-106), d
	pop	xiz
	pop	xiy
	pop	xix
	pop	xhl
	pop	xde
	pop	xbc
	pop	xwa
	ret

SwbtWr_WriteParamBlockSafe:
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	call SwbtWr_WriteParamBlock
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	ret

SndParam_ApplyProgramChange_Safe:
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	ld (0x90ea:16), hl
	ld a, (0x90f6:16)
	ld (0x90ec:16), a
	call SndParam_ApplyAndFetch
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	ld hl, (0x90ee:16)
	ret

PartCtrl_WriteProgramChange:
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	ld (0x90ea:16), hl
	ld a, (0x90f7:16)
	ld (0x90ec:16), a
	call SndParam_FetchAndStore
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	ld hl, (0x90ee:16)
	ret

SndParam_UpdateVoiceEntry_Safe:
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	ld a, c
	extz wa
	ld c, e
	extz bc
	ld e, d
	extz de
	call SndParam_UpdateVoiceEntry
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	ret

MIDI_LoadParamsAndDispatchCC:
	ld bc, (0x917e:16)
	ld de, (0x9180:16)
	call MIDI_ClearGuardAndDispatchCC
	ret

MIDI_ClearGuardAndDispatchCC:
	ld (0x90e5:16), 0

MIDI_DispatchCC_Guarded:
	bit 0, (0xb7e7:16)
	jr nz, MidiGuarded_Return
	bit 4, (0xfd50:16)
	jr nz, MidiGuarded_Return
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	call MIDI_DispatchCC
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa

MidiGuarded_Return:
	ret

MIDI_WriteVoiceParamCC:
	push xix
	pushw wa
	push xhl
	cp d, 0:i3
	jr z, MidiWriteVoice_Done
	xor h, h
	ld l, c
	sla hl, 2
	ld xix, (0x90f2:16)
	ld_sril3 XIX, 0x07, 0xf0, 0xec
	cp xix, 0x9166
	jr z, MidiWriteVoice_Done
	xor h, h
	ld l, b
	ldb_sri A, 0x07, 0xf0, 0xec
	ld w, d
	xor w, 0xff
	and a, w
	and e, d
	or e, a
	stb_dri E, 0x07, 0xf0, 0xec
	ld (0x9127:16), bc
	ld (0x9129:16), de

MidiWriteVoice_Done:
	pop xhl
	popw wa
	pop xix
	ret

MIDI_WriteVoiceParamFromBuffer:
	ld c, (0x917e:16)
	ld b, (0x917f:16)
	ld e, (0x9180:16)
	ld d, (0x9181:16)

MIDI_WriteVoiceParamDirect:
	push xix
	pushw wa
	pushw hl
	cp d, 0:i3
	jr z, MidiWriteDirect_Done
	xor h, h
	ld l, c
	sla hl, 2
	ld xix, (0x90f2:16)
	ld_sril3 XIX, 0x07, 0xf0, 0xec
	cp xix, 0x9166
	jr z, MidiWriteDirect_Done
	xor h, h
	ld l, b
	ldb_sri A, 0x07, 0xf0, 0xec
	ld w, d
	xor w, 0xff
	and a, w
	and e, d
	or e, a
	stb_dri E, 0x07, 0xf0, 0xec
	ld (0x9127:16), bc
	ld (0x9129:16), de

MidiWriteDirect_Done:
	popw hl
	popw wa
	pop xix
	ret

MIDI_SetupChannelParams:
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	ld a, c
	extz wa
	ld c, l
	extz bc
	ld e, h
	extz de
	call MIDI_DistributeParamToChannels
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	ret

Audio_WriteBankSelectParams:
	pushw de
	bit 7, (0x8ee2:16)
	jr z, BankSelect_CheckChannel1
	and (0x8ee2:16), 127
	ldw (0x9127:16), 176
	ld e, (0x8ee2:16)
	ldb d, 0x7f
	ld (0x9129:16), de
	calr SwbtWr_WriteVoiceParam_PreserveRegs

BankSelect_CheckChannel1:
	bit 7, (0x8ee0:16)
	jr z, BankSelect_Done
	and (0x8ee0:16), 127
	ldw (0x9127:16), 432
	ld e, (0x8ee0:16)
	ldb d, 0x7f
	ld (0x9129:16), de
	calr SwbtWr_WriteVoiceParam_PreserveRegs

BankSelect_Done:
	popw de
	ret

SeqTimer_UpdateTempoReg:
	bit 2, (0xfd50:16)
	jr nz, SeqTimer_Return
	push xiz
	push xwa
	push xbc
	push xde
	push xhl
	ld xde, 0xfc5a
	ld wa, (xde + 8)
	and wa, 0x1ff
	cp wa, 0x28
	jr c, SeqTimer_ClampToDefault
	cp wa, 0x12c
	jr ule, SeqTimer_ComputeRegValue

SeqTimer_ClampToDefault:
	andmi16 (xde + 8), 0xfe00
	ldw wa, 0x78
	ld (xde + 8), a

SeqTimer_ComputeRegValue:
	ld (0xbd3a:16), wa
	ldw de, 0x40
	mul xwa, xde
	ld xde, 0x4c4b400
	call Boot_ReadFDCStatus
	cp l, 4:i3
	jr nz, SeqTimer_AdjustForMode4
	ld xde, 0x3938700

SeqTimer_AdjustForMode4:
	div xde, xwa
	ld xbc, xde
	srl xbc, 0
	srl wa, 1
	cp bc, wa
	jr c, SeqTimer_RoundUp
	inc 1, de

SeqTimer_RoundUp:
	ld (146:16), de; LD (TREG5L), DE
	bit 4, (0xfd50:16)
	jr nz, SeqTimer_ClearFlag
	bit 4, (0x90f9:16)
	jr nz, SeqTimer_ClearFlag
	call SeqData_DispatchLoop_Done

SeqTimer_ClearFlag:
	and (0x90f9:16), 239
	pop xhl
	pop xde
	pop xbc
	pop xwa
	pop xiz

SeqTimer_Return:
	ret

ToneGen_DispatchByMode:
	pushw wa
	pushw hl
	push xix
	ld wa, (0xfc66:16)
	and wa, 0x203
	cp a, 0:i3
	jr nz, RegBitManip_Dispatch
	ldb a, 0x1

; Register bit manipulation dispatch
; Index: DRAM[64605] & 0x7 (0-7), entries: 8
; 32-bit function pointers, call (xhl)
RegBitManip_Dispatch:
	extz xhl
	xor h, h
	ld l, (0xfc5d:16)
	and l, 0x7
	sla hl, 2
	ld xix, RegisterBit_Manipulate_Table
	ld_sril3 XIX, 0x07, 0xf0, 0xec
	jp (xix)
RegisterBit_Manipulate_Table:
	.long RegBitManip_Handler_0
	.long RegBitManip_Handler_1
	.long RegBitManip_Handler_0
	.long RegBitManip_Handler_3
	.long RegBitManip_Handler_4
	.long RegBitManip_Handler_4
	.long RegBitManip_Handler_4
	.long RegBitManip_Handler_4
RegBitManip_Handler_1:
	bit	0, (0xfc69:16)
	jr	nz, 3
RegBitManip_Handler_3:
	and	w, 0xfd
RegBitManip_Handler_0:
	pushw	wa
	and	wa, 515
	popw	wa
	jr	nz, 2
	lds	wa, 1
RegBitManip_Handler_4:
	ld	(0xfc66:16), wa
	pop	xix
	popw	hl
	popw	wa
	ret
	push	xwa
	push	xbc
	push	xde
	push	xhl
	push	xix
	push	xiy
	push	xiz
	call	SndBuf_WriteParamEntries_0x36
	pop	xiz
	pop	xiy
	pop	xix
	pop	xhl
	pop	xde
	pop	xbc
	pop	xwa
	ret
	push	xbc
	push	xde
	push	xhl
	push	xix
	push	xiy
	push	xiz
	push	xwa
	call	CharMap_ActivePreamb_Prologue2
	pop	xwa
	ld	a, l
	pop	xiz
	pop	xiy
	pop	xix
	pop	xhl
	pop	xde
	pop	xbc
	ret
	push	xwa
	push	xbc
	push	xde
	push	xhl
	push	xix
	push	xiy
	push	xiz
	call	SndBuf_WriteParamEntries
	pop	xiz
	pop	xiy
	pop	xix
	pop	xhl
	pop	xde
	pop	xbc
	pop	xwa
	ret
	.byte 0xf1
	jr	nc, -111
	.ascii "S89:;<=>"
	call	SndBuf_WriteParamEntries_0x6C
	pop	xiz
	pop	xiy
	pop	xix
	pop	xhl
	pop	xde
	pop	xbc
	pop	xwa
	ld	hl, (0x9173:16)
	ld	w, (0x9175:16)
	ret

MIDI_ParamValidate_CheckBit2:
	xor hl, hl
	bit 2, (0xfdad:16)
	jr nz, MidiParamValid_CheckW78
	cp a, 0xf0
	jr nc, MidiParamValid_SetInvalid
	jr MidiParamValid_Return

MidiParamValid_CheckW78:
	cp w, 0x78
	jr nz, MidiParamValid_Return

MidiParamValid_SetInvalid:
	inc 1, hl

MidiParamValid_Return:
	ret

MidiStream_ProcessEventBuffer:
	push xiz
	ld a, (0x379b:16)
	and a, 0xf
	jrl z, MidiStream_Return
	calr MidiStream_InitFromLookup
	ei 6
	or (1113:16), 1
	ld a, (1045:16)
	ld (0x91c9:16), a
	ei 0
	ld xix, 0xbd3c
	extz xwa
	ld wa, (0x90e0:16)
	add xix, xwa
	ld (0x91c1:16), xix

MidiStream_NextEvent:
	ld xix, (0x91c1:16)
	ld_spiw WA, 0xf1
	cp a, 0xff
	jr z, MidiStream_BufferDone
	ld (0x91bd:16), wa
	ld_spiw WA, 0xf1
	ld (0x91c1:16), xix
	ld (0x91bf:16), wa
	ld bc, (0x91bd:16)
	ld de, (0x91bf:16)
	ld xix, 0x91d2

MidiStream_ScanForMatch:
	ld_spiw WA, 0xf1
	cp a, 0xff
	jr z, MidiStream_NextEvent
	cp wa, bc
	jr z, MidiStream_FoundMatch
	inc 2, xix
	jr MidiStream_ScanForMatch

MidiStream_FoundMatch:
	ld_spiw WA, 0xf1
	cp c, 0xb1
	jr z, MidiStream_ProcessorDispatch
	and d, a
	jr z, MidiStream_ScanForMatch

; MIDI stream processor dispatch A
; Index: w & 0x7 (0-7), entries: 8
; 32-bit function pointers, call (xhl)
MidiStream_ProcessorDispatch:
	and w, 0x7
	sll w, 2
	ld xix, MidiStream_Processor_Table
	ld_sril3 XIX, 0x03, 0xf0, 0xe1
	call (xix)
	jr MidiStream_NextEvent

MidiStream_BufferDone:
	call TempoRingBuf_Consume
	res 0, (1113:16)

MidiStream_Return:
	pop xiz
	ret


MidiStream_Processor_Table:
	.long MidiStream_ProcessHandler_0
	.long MidiStream_ProcessHandler_1
	.long MidiStream_ProcessHandler_2
	.long MidiStream_ProcessHandler_3
	.long MidiStream_ProcessHandler_4
	.long MidiStream_ProcessHandler_5
	.long MidiStream_ProcessHandler_5
	.long MidiStream_ProcessHandler_5
MidiStream_ProcessHandler_5:
	ret

MidiStream_InitFromLookup:
	ld (0x91d2:16), 255
	extz hl
	ld l, (0x379b:16)
	and l, 0xf
	sll hl, 2
	ld xiy, VoiceMode_ParamConfigTables_0xAB8
	ld_sril3 XIY, 0x07, 0xf4, 0xec
	cp xiy, 0xffffffff
	jr z, MidiStreamInit_Done
	ld xix, 0x91d2

MidiStreamInit_CopyLoop:
	ld_spiw WA, 0xf5
	stw_dpi WA, 0xf1
	ld_spiw WA, 0xf5
	stw_dpi WA, 0xf1
	cp a, 0xff
	jr nz, MidiStreamInit_CopyLoop

MidiStreamInit_Done:
	ret

MidiStream_ProcessHandler_0:
	ld	xix, 0x91ad
	ldb	a, 209
	ld	w, (0x91c9:16)
	stw_dpi	wa, 241
	ld	a, (0x91bf:16)
	ldb	w, 255
	ld	(xix), wa
	ld	(0x91ca:16), 3
	calr	1517
	ret
MidiStream_ProcessHandler_1:
	ld	xix, 0x91ad
	ldb	a, 210
	ld	w, (0x91c9:16)
	stw_dpi	wa, 241
	ld	a, (0x91c0:16)
	ldb	w, 255
	ld	(xix), wa
	ld	(0x91ca:16), 3
	calr	1486
	ret
MidiStream_ProcessHandler_2:
	ld	xix, 0x91ad
	ldb	a, 211
	ld	w, (0x91c9:16)
	stw_dpi	wa, 241
	ld	a, (0x91bf:16)
	ldb	w, 255
	ld	(xix), wa
	ld	(0x91ca:16), 3
	calr	1455
	ret
MidiStream_ProcessHandler_3:
	ld	xix, 0x91ad
	ldb	a, 212
	ld	w, (0x91c9:16)
	.byte 0xf5
	ld	(8528:16), 241
	.byte 0xbf
	and	(xbc), hl
	jr	z, 2
	ldb	a, 127
	ldb	w, 255
	ld	(xix), wa
	ld	(0x91ca:16), 3
	calr	1418
	ret
MidiStream_ProcessHandler_4:
	ld	xix, 0x91ad
	ldb	a, 213
	ld	w, (0x91c9:16)
	stw_dpi	wa, 241
	ld	a, (0x91bf:16)
	ldb	w, 255
	ld	(xix), wa
	ld	(0x91ca:16), 3
	calr	1387
	ret

MidiStream_ProcessSeqBuffer:
	push xiz
	cp (0x8d36:16), 201
	jrl nz, MidiSeqBuf_Return
	cp (0x7f0b:16), 0
	jrl z, MidiSeqBuf_Return
	ei 6
	set 0, (1113:16)
	ld a, (1130:16)
	ld (0x91c9:16), a
	ei 0
	ld xix, 0xbd3c
	extz xwa
	ld wa, (0x90e0:16)
	add xix, xwa
	ld (0x91c1:16), xix

MidiSeqBuf_NextEvent:
	ld xix, (0x91c1:16)
	ld_spiw WA, 0xf1
	cp a, 0xff
	jr z, MidiSeqBuf_Done
	ld (0x91bd:16), wa
	ld_spiw WA, 0xf1
	ld (0x91c1:16), xix
	ld (0x91bf:16), wa
	calr MidiSeqBuf_InitFromTable
	ld bc, (0x91bd:16)
	ld d, (0x91c0:16)
	ld xix, 0x91d2

MidiSeqBuf_ScanForMatch:
	ld_spiw WA, 0xf1
	cp a, 0xff
	jr z, MidiSeqBuf_NextEvent
	cp wa, bc
	jr z, MidiSeqBuf_FoundMatch
	inc 2, xix
	jr MidiSeqBuf_ScanForMatch

MidiSeqBuf_FoundMatch:
	ld_spiw WA, 0xf1
	cp c, 0xb1
	jr z, MidiStream_ProcessorDispatchB
	and d, a
	jr z, MidiSeqBuf_ScanForMatch

; MIDI stream processor dispatch B
; Index: w & 0x7 (0-7), entries: 8
; 32-bit function pointers, call (xhl)
MidiStream_ProcessorDispatchB:
	ld (0x91c7:16), 0
	and w, 0x7
	sll w, 2
	ld xix, MidiSeqBuf_ProcessorTable_0x1
	ld_sril3 XIX, 0x03, 0xf0, 0xe1
	call (xix)
	ld (0x91d2:16), 255
	jr MidiSeqBuf_NextEvent

MidiSeqBuf_Done:
	call TempoRingBuf_Consume
	res 0, (1113:16)

MidiSeqBuf_Return:
	pop xiz
	ret

MidiSeqBuf_ProcessorTable:
	.byte 0xff, 0x24, 0xa9, 0xfc, 0x00, 0x76, 0xa9, 0xfc
	.byte 0x00, 0xc8, 0xa9, 0xfc, 0x00, 0xf3, 0xa9, 0xfc
	.byte 0x00, 0x18, 0xaa, 0xfc, 0x00, 0xb7, 0xa6, 0xfc
	.byte 0x00, 0xb7, 0xa6, 0xfc, 0x00, 0xb7, 0xa6, 0xfc
	.byte 0x00, 0x0e

MidiSeqBuf_InitFromTable:
	ld (0x91d2:16), 255
	ld xiy, VoiceMode_ParamConfigTables
	ld xix, 0x91d2

MidiSeqBufInit_CopyLoop:
	ld_spiw WA, 0xf5
	stw_dpi WA, 0xf1
	cp a, 0xff
	jr z, MidiSeqBufInit_Done
	ld_spiw WA, 0xf5
	stw_dpi WA, 0xf1
	jr MidiSeqBufInit_CopyLoop

MidiSeqBufInit_Done:
	ret

Tempo_ProcessExpressionChange:
	pushw wa
	calr MIDI_SelectTempoExpressionSource
	cpw (0x91c5:16), 0
	jr z, TempoExpr_Done
	xor l, l
	ld xix, 0xf1a0

TempoExpr_FindActivePart:
	cpib_sri 0x03, 0xf0, 0xec, 0x0f
	jr z, TempoExpr_StorePartIndex
	inc 1, l
	cp l, 0x10
	jr c, TempoExpr_FindActivePart

TempoExpr_StorePartIndex:
	ld (0x91c7:16), l
	ei 6
	set 0, (1113:16)
	ld a, (1051:16)
	ld (0x91c9:16), a
	ei 0
	ld xix, 0x91ad
	ldb a, 0xc0
	ld w, (0x91c9:16)
	stw_dpi WA, 0xf1
	stiw_dsp 0xf1, 0x17, 0x00
	ld wa, (xsp)
	bit 7, a
	jr z, TempoExpr_CheckHighBitW
	res 7, a
	set 0, (0x91ad:16)

TempoExpr_CheckHighBitW:
	bit 7, w
	jr z, TempoExpr_WriteAndProcess
	res 7, w
	set 1, (0x91ad:16)

TempoExpr_WriteAndProcess:
	stw_dpi WA, 0xf1
	ld a, (0x91c7:16)
	ldb w, 0xff
	stw_dpi WA, 0xf1
	ld (0x91ca:16), 7
	calr TempoRingBuf_ProcessEntry
	call TempoRingBuf_Consume
	res 0, (1113:16)

TempoExpr_Done:
	inc 2, xsp
	ret

Audio_ProcessAllMidiStreams:
	ldw (0x90e0:16), 0
	calr MidiStream_ProcessEventBuffer
	calr MidiStream_ProcessSeqBuffer
	calr Mod_SelectExpressionSource
	calr MidiStream_ProcessTempoRingBuf
	ret

MIDI_SelectTempoExpressionSource:
	push xiz
	xor wa, wa
	ld e, (0x8d34:16)
	cp e, 0xb
	jr z, TempoSrc_CheckAutoPlay
	cp e, 0xd
	jr z, TempoSrc_DirectTempoMode
	ld d, (0x8d36:16)
	cp d, 0x87
	jr z, Tempo_Expression_Bypass
	cp d, 0x88
	jr z, Tempo_Expression_Bypass
	and (0x90f9:16), 243
	jr Tempo_ExpressionStore

TempoSrc_CheckAutoPlay:
	bit 2, (1057:16)
	jr z, Tempo_ExpressionStore
	ld wa, (0x28a8:16)
	set 2, (0x90f9:16)
	jr Tempo_ExpressionStore

Tempo_Expression_Bypass:
	bit 0, (0x28c5:16)
	jr z, Tempo_ExpressionStore
	ld wa, (0x28aa:16)
	jr Tempo_ExpressionStore

TempoSrc_DirectTempoMode:
	ld wa, (3407:16)
	set 3, (0x90f9:16)

Tempo_ExpressionStore:
	ld (0x91c5:16), wa
	pop xiz
	ret

Mod_SelectExpressionSource:
	xor wa, wa
	ld e, (0x8d34:16)
	cp e, 0xb
	jr z, ModExpr_CheckAutoPlay
	cp e, 0xd
	jr z, ModExpr_DirectMode
	ld d, (0x8d36:16)
	cp d, 0x87
	jr z, Tempo_Expression_Bypass
	cp d, 0x88
	jr z, Tempo_Expression_Bypass
	and (0x90f9:16), 243
	jr Mod_ExpressionStore

ModExpr_CheckAutoPlay:
	cpw (0x28a8:16), 0
	jr z, Mod_ExpressionStore
	ld wa, (0x28a8:16)
	set 2, (0x90f9:16)
	jr Mod_ExpressionStore
	bit 0, (0x28c5:16)
	jr z, Mod_ExpressionStore
	ld wa, (0x28aa:16)
	jr Mod_ExpressionStore

ModExpr_DirectMode:
	ld wa, (3407:16)
	set 3, (0x90f9:16)

Mod_ExpressionStore:
	ld (0x91c5:16), wa
	ret

MidiStream_ProcessTempoRingBuf:
	push xiz
	cpw (0x91c5:16), 0
	jrl z, TempoRing_Return
	ei 6
	set 0, (1113:16)
	ld a, (1051:16)
	ld (0x91c9:16), a
	ei 0
	ld xix, 0xbd3c
	extz xwa
	ld wa, (0x90e0:16)
	add xix, xwa
	ld (0x91c1:16), xix

TempoRing_NextEvent:
	ld xix, (0x91c1:16)
	ld_spiw WA, 0xf1
	cp a, 0xff
	jr z, TempoRing_Done
	ld (0x91bd:16), wa
	ld_spiw WA, 0xf1
	ld (0x91c1:16), xix
	ld (0x91bf:16), wa
	calr TempoRing_ValidateState
	ld (0x91c7:16), 0

TempoRing_InitAndScan:
	calr TempoRing_InitPartStream
	ld bc, (0x91bd:16)
	ld d, (0x91c0:16)
	ld xix, 0x91d2

TempoRing_ScanForMatch:
	ld_spiw WA, 0xf1
	cp a, 0xff
	jr z, TempoRing_UpdateAndContinue
	cp wa, bc
	jr z, TempoRing_FoundMatch
	inc 2, xix
	jr TempoRing_ScanForMatch

TempoRing_FoundMatch:
	ld_spiw WA, 0xf1
	cp c, 0xb1
	jr z, MidiStream_ProcessorDispatchC
	and d, a
	jr z, TempoRing_ScanForMatch

; MIDI stream processor dispatch C
; Index: w & 0xf (0-15), entries: 16
; 32-bit function pointers, call (xhl)
MidiStream_ProcessorDispatchC:
	and w, 0xf
	sll w, 2
	ld xix, TempoRing_ProcessorTable_0x1
	ld_sril3 XIX, 0x03, 0xf0, 0xe1
	call (xix)

TempoRing_UpdateAndContinue:
	ld (0x91d2:16), 255
	inc 1, (0x91c7:16)
	cp (0x91c7:16), 15
	jr ule, TempoRing_InitAndScan
	jr TempoRing_NextEvent

TempoRing_Done:
	call TempoRingBuf_Consume
	res 0, (1113:16)

TempoRing_Return:
	pop xiz
	ret

TempoRing_ProcessorTable:
	.byte 0xff, 0x24, 0xa9, 0xfc, 0x00, 0x76, 0xa9, 0xfc
	.byte 0x00, 0x69, 0xaa, 0xfc, 0x00, 0xc8, 0xa9, 0xfc
	.byte 0x00, 0xf3, 0xa9, 0xfc, 0x00, 0x18, 0xaa, 0xfc
	.byte 0x00, 0x3d, 0xaa, 0xfc, 0x00, 0xf9, 0xa8, 0xfc
	.byte 0x00, 0xf9, 0xa8, 0xfc, 0x00, 0xf9, 0xa8, 0xfc
	.byte 0x00, 0xf9, 0xa8, 0xfc, 0x00, 0xf9, 0xa8, 0xfc
	.byte 0x00, 0xf9, 0xa8, 0xfc, 0x00, 0xf9, 0xa8, 0xfc
	.byte 0x00, 0xf9, 0xa8, 0xfc, 0x00, 0xf9, 0xa8, 0xfc
	.byte 0x00, 0x0e

TempoRing_ValidateState:
	ld xix, (0x91c1:16)
	cp xix, 0xbd40
	jr z, MIDI_ParamValidation_ReturnNoOp
	ld bc, (0x91bd:16)
	cp c, 0x1f
	jr ugt, MIDI_ParamValidation_ReturnNoOp
	cp b, 4:i3
	jr nz, MIDI_ParamValidation_ReturnNoOp
	cp c, (xix - 8)
	jr nz, MIDI_ParamValidation_ReturnNoOp
	cp (xix - 7), 0x0
	jr nz, MIDI_ParamValidation_ReturnNoOp
	and (0x91c0:16), 183

MIDI_ParamValidation_ReturnNoOp:
	ret

TempoCC_TransmitBytecodeBlock:
	ld	xix, 0x91ad
	ldb	a, 192
	ld	w, (0x91c9:16)
	stw_dpi	wa, 241
	ld	wa, (0x91bd:16)
	stw_dpi	wa, 241
	ld	xiy, (0x90f2:16)
	extz	wa
	sll	wa, 2
	ld_rrl xiy, xiy, wa
	ld wa, (xiy)
	bit 7, a
	jr z, 7
	res	7, a
	.byte 0xf1, 0xad, 0x91
	lda	xhl, (xwa-56)
	reti
	jr	z, 7
	res	7, w
	.byte 0xf1, 0xad, 0x91, 0xb9, 0xf5, 0xf1, 0x50
	ld	a, (0x91c7:16)
	ldb	w, 255
	stw_dpi	wa, 241
	ld	(0x91ca:16), 7
	calr	490
	ret
	ld	xix, 0x91ad
	ldb	a, 176
	ld	w, (0x91c9:16)
	stw_dpi	wa, 241
	ld	wa, (0x91bd:16)
	bit	7, a
	jr	z, 7
	res	7, a
	.byte 0xf1, 0xad, 0x91, 0xba, 0xf5, 0xf1, 0x50
	ld	wa, (0x91bf:16)
	bit	7, a
	jr	z, 7
	res	7, a
	.byte 0xf1, 0xad, 0x91
	lda	xhl, (xwa-56)
	reti
	jr	z, 7
	res	7, w
	.byte 0xf1, 0xad, 0x91, 0xb9, 0xf5, 0xf1, 0x50
	ld	a, (0x91c7:16)
	ldb	w, 255
	stw_dpi	wa, 241
	ld	(0x91ca:16), 7
	calr	408
	ret
	ld	xix, 0x91ad
	ldb	a, 210
	ld	w, (0x91c9:16)
	stw_dpi	wa, 241
	ld	wa, (0x91bf:16)
	and	wa, 0x7f7f
	stw_dpi	wa, 241
	ld	a, (0x91c7:16)
	ldb	w, 255
	stw_dpi	wa, 241
	ld	(0x91ca:16), 37
	calr	365
	ret
	ld	xix, 0x91ad
	ldb	a, 209
	ld	w, (0x91c9:16)
	stw_dpi	wa, 241
	ld	a, (0x91bf:16)
	ld	w, (0x91c7:16)
	stw_dpi wa, 241
	ld (xix), 255
	ld	(0x91ca:16), 20
	calr	328
	ret
	ld	xix, 0x91ad
	ldb	a, 211
	ld	w, (0x91c9:16)
	stw_dpi	wa, 241
	ld	a, (0x91bf:16)
	ld	w, (0x91c7:16)
	stw_dpi wa, 241
	ld (xix), 255
	ld	(0x91ca:16), 4
	calr	291
	ret
	.byte 0xf2
	inc	6, (0xc800ff:24)
	ldb	d, 68
	.byte 0xad, 0x91
	nop
	nop
	ldb	a, 208
	ld	w, (0x91c9:16)
	stw_dpi	wa, 241
	ld	a, (0x91bf:16)
	ld	w, (0x91c7:16)
	stw_dpi wa, 241
	ld (xix), 255
	ld	(0x91ca:16), 4
	calr	247
	ret
	ld	xix, 0x91ad
	ldb	a, 128
	ld	w, (0x91c9:16)
	.byte 0xf5
	ld	(0xd150:16), xde
	swi	4
	ldb	w, 216
	.byte 0xcc
	swi	7
	.byte 0x01
	sll	w, 1
	bit	7, a
	jr	z, 3
	set	0, w
	res	7, a
	stw_dpi wa, 241
	ld (xix), 255
	ld	(0x91ca:16), 4
	calr	196
	ret

MIDI_TransmitTempoCC:
	ld (0x91bd:16), bc
	ld (0x91bf:16), de
	calr MIDI_SelectTempoExpressionSource
	cpw (0x91c5:16), 0
	jr z, TempoCC_Return
	ei 6
	set 0, (1113:16)
	ld a, (1051:16)
	ld (0x91c9:16), a
	ei 0
	ld xix, 0x91ad
	ldb a, 0xb0
	ld w, (0x91c9:16)
	stw_dpi WA, 0xf1
	ld wa, (0x91bd:16)
	stw_dpi WA, 0xf1
	ld wa, (0x91bf:16)
	bit 7, a
	jr z, TempoCC_CheckHighBitW
	res 7, a
	set 0, (0x91ad:16)

TempoCC_CheckHighBitW:
	bit 7, w
	jr z, TempoCC_WriteAndProcess
	res 7, w
	set 1, (0x91ad:16)

TempoCC_WriteAndProcess:
	stw_dpi WA, 0xf1
	ldw wa, 0xff7f
	ld (xix), wa
	ld (0x91ca:16), 135
	calr TempoRingBuf_ProcessEntry
	call TempoRingBuf_Consume
	res 0, (1113:16)

TempoCC_Return:
	ret

TempoRing_InitPartStream:
	ld (0x91d2:16), 255
	ld c, (0x91c7:16)
	ldb_erp A, 0x3c
	ldw_erp DE, 0x3e
	ld de, (0x91c5:16)
	ld a, c
	scf
	xorcf_a_16 de
	stw_erp DE, 0x3e
	stb_erp A, 0x3c
	jr c, TempoPartStream_Done
	extz hl
	ld l, (0x91c7:16)
	ld xix, 0xf1a0
	ldb_sri L, 0x07, 0xf0, 0xec
	sll hl, 2
	ld xix, VoiceMode_ParamConfigTables_0x68
	ld_sril3 XIY, 0x07, 0xf0, 0xec
	ld xix, 0x91d2

TempoPartStream_CopyLoop:
	ld_spiw WA, 0xf5
	stw_dpi WA, 0xf1
	cp a, 0xff
	jr z, TempoPartStream_Done
	ld_spiw WA, 0xf5
	stw_dpi WA, 0xf1
	jr TempoPartStream_CopyLoop

TempoPartStream_Done:
	ret

TempoRingBuf_ProcessEntry:
	cp (0x91ad:16), 255
	jr z, TempoRingBuf_EntryDone
	ld xix, 0x91ad
	push xix
	extz wa
	ld a, (0x91ca:16)
	and a, 0x7
	pushw wa
	ei 6
	call TempoRingBuf_WriteBytes
	inc 6, xsp
	ei 0
	cp (0x90f8:16), 255
	jr nz, TempoRingBuf_ClearEntryType
	call AudioCtrl_SaveAllRegs
	call SeqPlay_CheckAndStartPlayback
	call AudioCtrl_RestoreAllRegs
	jr TempoRingBuf_ClearEntryType

TempoRingBuf_ClearEntryType:
	ld (0x91ca:16), 0

TempoRingBuf_EntryDone:
	ret

Audio_ProcessPartExpressions:
	push xiz
	calr MIDI_SelectTempoExpressionSource
	cpw (0x91c5:16), 0
	jrl z, PartExpr_Done
	ei 6
	set 0, (1113:16)
	ld a, (1051:16)
	ld (0x91c9:16), a
	ei 0
	xor c, c

PartExpr_ProcessNextBit:
	ld wa, (0x91c5:16)
	srl wa, 1
	ld (0x91c5:16), wa
	jr nc, PartExpr_AdvanceBit
	ld l, c
	ld xix, 0xf1a0
	ldb_sri A, 0x03, 0xf0, 0xec
	cp a, 0:i3
	jr z, PartExpr_WriteToBuffer
	cp a, 2:i3
	jr z, PartExpr_WriteToBuffer
	cp a, 1:i3
	jr nz, PartExpr_AdvanceBit

PartExpr_WriteToBuffer:
	ld xix, 0x91ad
	ldb a, 0xb2
	ld w, (0x91c9:16)
	stw_dpi WA, 0xf1
	ldb a, 0x9a
	bit 7, a
	jr z, PartExpr_AddPartIndex
	set 2, (0x91ad:16)
	res 7, a

PartExpr_AddPartIndex:
	ld w, c
	add w, 0x4
	stw_dpi WA, 0xf1
	ld a, (0xc5a8:16)
	bit 7, a
	jr z, PartExpr_ReadCurrentValue
	set 0, (0x91ad:16)
	res 7, a

PartExpr_ReadCurrentValue:
	ldb w, 0x7f
	stw_dpi WA, 0xf1
	ld a, c
	ldb w, 0xff
	stw_dpi WA, 0xf1
	ld (0x91ca:16), 7
	pushw bc
	calr TempoRingBuf_ProcessEntry
	popw bc

PartExpr_AdvanceBit:
	inc 1, c
	cp c, 0x10
	jr c, PartExpr_ProcessNextBit
	call TempoRingBuf_Consume
	res 0, (1113:16)

PartExpr_Done:
	pop xiz
	ret

Part_ReinitAllActive:
	push xiz
	ld (0x91c8:16), 0

PartReinit_ProcessNextPart:
	ld c, (0x91c8:16)
	ldb_erp A, 0x3c
	ldw_erp DE, 0x3e
	ld de, (0xf19e:16)
	ld a, c
	scf
	xorcf_a_16 de
	stw_erp DE, 0x3e
	stb_erp A, 0x3c
	jr c, PartReinit_AdvancePart
	extz hl
	ld l, c
	ld xix, 0xf1a0
	ldb_sri A, 0x07, 0xf0, 0xec
	ld (0x91cd:16), a
	calr PartReinit_SendD0Command
	calr PartReinit_SendB0Command
	calr PartReinit_SendD2Command
	calr PartReinit_SendD1Command
	calr PartReinit_SendD0Command
	calr PartReinit_CheckSpecialPart15

PartReinit_AdvancePart:
	inc 1, (0x91c8:16)
	cp (0x91c8:16), 16
	jr c, PartReinit_ProcessNextPart
	calr PendingParam_ScanAllTables
	call SwbtWr_ReinitOutputBank
	pop xiz
	ret

PartReinit_SendD2Command:
	ld xix, 0x91b5
	ldw wa, 0xd2
	stw_dpi WA, 0xf1
	xor a, a
	ldb w, 0x40
	stw_dpi WA, 0xf1
	ld a, (0x91c8:16)
	ldb w, 0xff
	ld (xix), wa
	calr VoiceParam_DispatchByMode
	ret

PartReinit_SendD1Command:
	ld xix, 0x91b5
	ldw wa, 0xd1
	stw_dpi WA, 0xf1
	ldb a, 0x0
	ld w, (0x91c8:16)
	stw_dpi WA, 0xf1
	ld (xix), 0xff
	calr VoiceParam_DispatchByMode
	ret

PartReinit_SendD0Command:
	ld xix, 0x91b5
	ldw wa, 0xd0
	stw_dpi WA, 0xf1
	ldb a, 0x0
	ld w, (0x91c8:16)
	stw_dpi WA, 0xf1
	ld (xix), 0xff
	calr VoiceParam_DispatchByMode
	ret

PartReinit_SendB0Command:
	ld xix, 0x91b5
	ldw wa, 0xb0
	stw_dpi WA, 0xf1
	extz hl
	ld l, (0x91c8:16)
	ld xiy, 0xf1a0
	ldb_sri L, 0x07, 0xf4, 0xec
	ld xiy, VoiceMode_ParamConfigTables_0x24
	ldb_sri A, 0x07, 0xf4, 0xec
	ldb w, 0x4
	stw_dpi WA, 0xf1
	ldw wa, 0x800
	stw_dpi WA, 0xf1
	ld a, (0x91c8:16)
	ldb w, 0xff
	ld (xix), wa
	calr VoiceMode_ParamHandler_3
	ret

PartReinit_CheckSpecialPart15:
	cp (0x91cd:16), 15
	jr nz, PartReinit_SpecialDone
	ldw bc, 0x298
	ldw de, 0x8000
	call MIDI_WriteVoiceParamDirect
	call SwbtWr_WriteVoiceParam_PreserveRegs

PartReinit_SpecialDone:
	ret

Audio_ReinitAndProcessEvents:
	calr Audio_SyncAndProcessSequencer
	calr PendingParam_ScanAllTables
	call MidiPkt_ProcessEventQueue
	ret

Audio_SyncAndProcessSequencer:
	ld wa, (0x90de:16)
	ld (0x90e0:16), wa
	call SeqBuf_SaveReadPos

AudioSeq_CheckEventPending:
	ld xix, 0x1e549
	ld hl, (xix - 10)
	cp hl, (xix - 6)
	jr z, AudioSeq_FlushAndTerminate
	ld xiy, 0x91b5

AudioSeq_ReadNextEvent:
	pushw hl
	call SeqBuf_ReadAlternate
	lda_dpi XSP, 0xf4
	popw hl
	ld hl, (xix - 10)
	cp hl, (xix - 6)
	jr z, VoiceMode_ParamDispatch
	ldb_sri A, 0x07, 0xf0, 0xec
	bit 7, a
	jr z, AudioSeq_ReadNextEvent

; Voice mode parameter dispatch
; Index: DRAM[37301] bits [6:4] (0-7), entries: 8
; 32-bit function pointers, call (xhl)
VoiceMode_ParamDispatch:
	ld (xiy), 0xff
	ld a, (0x91b6:16)
	ld (0x90f8:16), a
	extz hl
	ld l, (0x91b5:16)
	and l, 0x70
	srl hl, 2
	ld xiy, VoiceMode_ParamDispatch_Table
	ld_sril3 XIY, 0x07, 0xf4, 0xec
	call (xiy)
	jr AudioSeq_CheckEventPending

VoiceMode_ParamDispatch_Sentinel:
	swi	7


VoiceMode_ParamDispatch_Table:
	.long VoiceMode_ParamHandler_0
	.long VoiceMode_ParamHandler_1
	.long VoiceMode_ParamHandler_1
	.long VoiceMode_ParamHandler_3
	.long VoiceMode_ParamHandler_4
	.long VoiceParam_DispatchByMode
	.long VoiceMode_ParamHandler_1
	.long VoiceMode_ParamHandler_1

VoiceMode_ParamHandler_1:
	ret

AudioSeq_FlushAndTerminate:
	ld xix, 0xbd3c
	ld hl, (0x90de:16)
	stib_ind 0x07, 0xf0, 0xec, 0xff
	ret

VoiceMode_ParamHandler_4:
	calr VoiceMode_CheckPendingFlags
	cp (0x91b5:16), 255
	jrl z, MidiCtrl_NullRet
	ld xix, 0x91b7
	ld_spiw BC, 0xf1
	ld_spiw DE, 0xf1
	ld a, (xix)
	ld (0x91c8:16), a
	extz hl
	ld l, c
	sll hl, 2
	ld xix, (0x90f2:16)
	ld_sril3 XIX, 0x07, 0xf0, 0xec
	cp xix, 0xffffffff
	jrl z, MidiCtrl_NullRet
	ld (0x915b:16), bc
	ld (0x915d:16), de
	ld (0x90f7:16), c
	ld hl, de
	call PartCtrl_WriteProgramChange
	ld (0x91cf:16), hl
	call PartCtrl_CheckBitmaskBit
	jr nc, VoiceMode4_CheckPart0
	cp (0x915b:16), 23
	jr nz, VoiceMode4_SetupChannelAndWrite
	ld hl, de
	call AccompSeq_ManualMidiEntry2
	ret

VoiceMode4_SetupChannelAndWrite:
	call MIDI_SetupChannelParams
	andmi8 (xix + 1), 0x80
	ld a, (0x915e:16)
	or (xix + 1), a
	ld a, (0x915d:16)
	ld (xix), a
	ld a, (0x915b:16)
	ldb w, 0x1
	ld (0x9127:16), wa
	ld a, (0x915e:16)
	ldb w, 0x7f
	ld (0x9129:16), wa
	call SwbtWr_WriteVoiceParam_PreserveRegs
	ld a, (0x915b:16)
	ldb w, 0x0
	ld (0x9127:16), wa
	ld a, (0x915d:16)
	ldb w, 0xff
	ld (0x9129:16), wa
	call SwbtWr_WriteVoiceParam_PreserveRegs
	ld bc, (0x915b:16)
	ld de, (0x915d:16)
	call SndParam_UpdateVoiceEntry_Safe

VoiceMode4_CheckPart0:
	cp (0x915b:16), 0
	jr nz, MidiCtrl_DispatchHandler
	bit 3, (0xfd50:16)
	jrl nz, MidiCtrl_NullRet

; MIDI controller dispatch handler
MidiCtrl_DispatchHandler:
	xor h, h
	ld l, (0x91c8:16)
	ld xix, 0xf1a0
	ldb_sri A, 0x07, 0xf0, 0xec
	cp a, 0xd
	jrl z, MidiCtrl_NullRet
	cp a, 0xe
	jrl z, MidiCtrl_NullRet
	cp a, 0xf
	jrl z, MidiCtrl_NullRet
	cp a, 0x10
	jrl z, MidiCtrl_NullRet
	ld xix, 0x90ce
	ldb_sri A, 0x07, 0xf0, 0xec
	cp a, 0x10
	jrl z, MidiCtrl_NullRet
	set 7, a
	ld (0x90e5:16), a
	extz hl
	ld l, (0xfd50:16)
	and l, 0x3
	sll hl, 2
	ld xix, MidiCtrl_ModeDispatch_Table
	ld_sril3 XIX, 0x07, 0xf0, 0xec
	jp (xix)
MidiCtrl_ModeDispatch_Table:
	swi	1
	.byte 0xae, 0xfc, 0x00
	ldw	bc, 64687
	nop
	.byte 0xd1, 0xaf, 0xfc, 0x00
	jrl	-849
	nop
	ldb	c, 129
	ld	b, (37211:16)
	ld	e, (37328:16)
	xor	d, d
	call	16556547
	xor	h, h
	ld	l, (37320:16)
	ld	xix, 37070
	ld_rrb	a, xix, hl
	set	7, a
	ld	(37093:16), a
	ld	bc, (37211:16)
	ld	e, (37327:16)
	ldb	d, 255
	call	16556547
	jrl	160
	ld	b, (37211:16)
	ldb	c, 129
	xor	d, d
	.byte 0xf1, 0x5d, 0x91, 0xcf
	jr	z, 2
	ldb	d, 1
	ld	e, (37214:16)
	sll	e, 4
	call	16556547
	extz	hl
	ld	l, (37320:16)
	ld	xix, 37070
	ld_rrb	a, xix, hl
	set	7, a
	ld	(37093:16), a
	ld	c, (37211:16)
	ldb	b, 0
	ld	e, (37213:16)
	res	7, e
	ldb	d, 255
	call	16556547
	jr	89
	ld	wa, (37213:16)
	ld	(37098:16), wa
	ld	a, (37211:16)
	ld	(37100:16), a
	call	16557046
	pushw	wa
	pushw	hl
	ld	wa, (37213:16)
	call	16557136
	or	hl, hl
	popw	hl
	popw	wa
	jr	nz, 14
	ld	b, (37211:16)
	ldb	c, 129
	ld	de, (37102:16)
	call	16556547
	extz	hl
	ld	l, (37320:16)
	ld	xix, 37070
	ld_rrb	a, xix, hl
	set	7, a
	ld	(37093:16), a
	ld	c, (37211:16)
	xor	b, b
	ld	e, (37104:16)
	ldb	d, 255
	call	16556547

MidiCtrl_NullRet:
	ret

VoiceMode_CheckPendingFlags:
	ld xix, 0x91b5
	bitm 0, (xix)
	jr z, VoiceMode_CheckFlag1
	setm 7, (xix + 4)

VoiceMode_CheckFlag1:
	bitm 1, (xix)
	jr z, VoiceMode_CheckPart15Validate
	setm 7, (xix + 5)

VoiceMode_CheckPart15Validate:
	cp (xix + 2), 0xf
	jr nz, VoiceMode_FlagCheckDone
	pushw wa
	pushw hl
	ld a, (xix + 4)
	ld w, (xix + 5)
	call MIDI_ParamValidate_CheckBit2
	or hl, hl
	popw hl
	popw wa
	jr nz, VoiceMode_FlagCheckDone
	ld (xix), 0xff

VoiceMode_FlagCheckDone:
	ret

VoiceMode_ParamHandler_3:
	calr VoiceMode3_InitChannelMatch
	cp (0x91b5:16), 255
	jr z, VoiceMode3_Done
	extz hl
	ld l, (0x91d1:16)
	and l, 0xf
	sll hl, 2
	ld xix, VoiceMode3_DispatchTable_0x1
	ld_sril3 XIX, 0x07, 0xf0, 0xec
	call (xix)

VoiceMode3_Done:
	ret

VoiceMode3_DispatchTable:
	swi	7
	jr	mi, -80
	swi	4
	nop
	pushw	de
	.byte 0xb2, 0xfc
	nop
	.byte 0x82, 0xb2
	swi	4
	nop
	.byte 0xd6, 0xb2, 0xfc
	nop
	ldb	h, 179
	swi	4
	nop
	cp	(xhl-79), d
	nop
	.byte 0xf2, 0xb0, 0xfc, 0x00, 0xc3, 0xad, 0xfc, 0x00, 0xc3, 0xad, 0xfc, 0x00, 0xc3, 0xad, 0xfc, 0x00, 0xc3, 0xad, 0xfc, 0x00, 0xc3, 0xad, 0xfc, 0x00, 0xc3, 0xad, 0xfc, 0x00, 0xc3, 0xad, 0xfc, 0x00, 0xc3, 0xad, 0xfc, 0x00, 0xc3, 0xad, 0xfc, 0x00
	call	16562576
	jr	nc, 69
	ld	a, (37306:16)
	and	a, 7
	jr	z, 41
	ld	bc, (37303:16)
	extz	hl
	ld	l, (37320:16)
	ld	xix, 61856
	ld_rrb	a, xix, hl
	cp	a, 14
	jr	nz, 2
	ldb	b, 4
	ld	e, (37305:16)
	ldb	d, 7
	call	16556578
	call	16556371
	ld	bc, (37303:16)
	ld	de, (37305:16)
	and	d, 248
	call	16556662
	call	16556371
	ld	a, (37306:16)
	and	a, 7
	jr	z, 56
	extz	hl
	ld	l, (37307:16)
	ld	xix, 61856
	.byte 0xc3, 0x07, 0xf0, 0xec, 0x3f, 0x0f
	jr	nz, 37
	ld	xix, 37070
	ld_rrb	a, xix, hl
	cp	a, 16
	jr	z, 22
	set	7, a
	ld	(37093:16), a
	ld	bc, (37303:16)
	ld	de, (37305:16)
	and	d, 7
	call	16556547
	ret
	call	16562576
	jr	nc, 81
	ld	bc, (37303:16)
	ld	de, (37305:16)
	extz	hl
	ld	l, c
	sll	hl, 2
	ld	xix, (37106:16)
	ld_rrl	xix, xix, hl
	cp	xix, 4294967295
	jr	z, 114
	extz	hl
	ld	l, b
	ld_rrb	a, xix, hl
	ld	w, d
	xor	w, 255
	and	a, w
	and	e, d
	or	e, a
	st_rrb	e, xix, hl
	ld	(37159:16), bc
	ld	(37161:16), de
	call	16556371
	cpw	(37303:16), 920
	jr	nz, 4
	.byte 0xf1, 0x52, 0x8d, 0xbb
	extz	hl
	ld	l, (37320:16)
	ld	xix, 61856
	ld_rrb	a, xix, hl
	cp	a, 15
	jr	z, 44
	cp	a, 14
	jr	z, 39
	cp	a, 13
	jr	z, 34
	ld	xix, 37070
	ld_rrb	a, xix, hl
	cp	a, 16
	jr	z, 19
	set	7, a
	ld	(37093:16), a
	ld	bc, (37303:16)
	ld	de, (37305:16)
	call	16556547
	ret
	ld	bc, (37303:16)
	ld	de, (37305:16)
	bit	7, d
	jr	nz, 71
	extz	hl
	ld	l, (37320:16)
	ld	xix, 61856
	.byte 0xc3, 0x07, 0xf0, 0xec, 0x3f, 0x0f
	jr	z, 52
	set	7, e
	ld	xix, 38066
	st_rrb	e, xix, hl
	ret

MidiPartCC_WriteAndDispatch:
	extz hl
	ld l, (0x91c8:16)
	ld xix, 0xf1a0
	ldb_sri L, 0x07, 0xf0, 0xec
	ld xix, VoiceMode_ParamConfigTables_0x24
	ldb_sri C, 0x07, 0xf0, 0xec
	ldb b, 0x3
	ld (0x915b:16), bc
	ldb d, 0x7f
	ld (0x915d:16), de
	call PartCtrl_CheckBitmaskBit
	jr nc, MidiPartCC_CheckAndGuard
	call MIDI_WriteVoiceParamCC
	call SwbtWr_WriteVoiceParam_PreserveRegs

MidiPartCC_CheckAndGuard:
	extz hl
	ld l, (0x91c8:16)
	ld xix, 0xf1a0
	ldb_sri A, 0x07, 0xf0, 0xec
	cp a, 0xe
	jr z, MIDI_PartCC_DispatchExit
	cp a, 0xd
	jr z, MIDI_PartCC_DispatchExit
	ld xix, 0x90ce
	ldb_sri A, 0x07, 0xf0, 0xec
	cp a, 0x10
	jr z, MIDI_PartCC_DispatchExit
	set 7, a
	ld (0x90e5:16), a
	ld bc, (0x915b:16)
	ld de, (0x915d:16)
	call MIDI_DispatchCC_Guarded

MIDI_PartCC_DispatchExit:
	ret

MidiVoice_DataBlockHandler:
	ld	xiy, 0x91b7
	ld	(0x90e4:16), 0
	call	PartCtrl_CheckBitmaskBit
	jr	nc, 18
	.byte 0xc1, 0xe4, 0x90
	push	xiz
	ldb	w, 149
	ldb	w, 241
	ldb	l, 145
	.byte 0x50
	ld	wa, (xiy+2)
	ld	(0x9129:16), wa
	extz	hl
	ld	l, (0x91c8:16)
	ld	xix, 0x90ce
	ld_rrb a, xix, hl
	cp a, 16
	jr	z, 28
	.byte 0xf1, 0x50
	swi	5
	dec	6, d
	ex_ff
	or	(0x90e4:16), a
	.byte 0xc1, 0xe4, 0x90
	push	xiz
	ld_sd8b	w, 149
	ld	(0x9127:16), wa
	ld	wa, (xiy+2)
	ld	(0x9129:16), wa
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ret
	extz	hl
	ld	l, (0x91c8:16)
	ld	xix, 0xf1a0
	.byte 0xc3
	reti
	.byte 0xf0, 0xec
	push	xsp
	retd	0x406e
	call	PartCtrl_CheckBitmaskBit
	jr	nc, 17
	ldw	bc, 664
	ld	e, (0x91b9:16)
	ldb	d, 128
	call	MIDI_WriteVoiceParamDirect
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	extz	hl
	ld	l, (0x91c8:16)
	ld	xix, 0x90ce
	ld_rrb a, xix, hl
	cp a, 16
	jr	z, 20
	set	7, a
	ld	(0x90e5:16), a
	ldw	bc, 664
	ld	e, (0x91b9:16)
	ldb	d, 128
	call	MIDI_DispatchCC_Guarded
	ret
	call	PartCtrl_CheckBitmaskBit
	jr	nc, 33
	ldb	a, 0
	ld	(0x9644:16), a
	ld	wa, (0x91b7:16)
	ld	(0x9644:16), wa
	ldw	wa, 0x7f00
	ld	(0x9646:16), wa
	call	MidiStream_DispatchData_0xEE
	ld	a, (0x91b6:16)
	ld	(0x90f8:16), a
	extz	hl
	ld	l, (0x91c8:16)
	ld	xix, 0x90ce
	ld_rrb a, xix, hl
	cp a, 16
	jr	z, 19
	set	7, a
	ld	(0x90e5:16), a
	ld	bc, (0x91b7:16)
	ld	de, (0x91b9:16)
	call	MIDI_DispatchCC_Guarded
	ret
	call	PartCtrl_CheckBitmaskBit
	jr	nc, 20
	ld	wa, (0x91b7:16)
	ld	(0x9127:16), wa
	ld	wa, (0x91b9:16)
	ld	(0x9129:16), wa
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	extz	hl
	ld	l, (0x91c8:16)
	ld	xix, 0x90ce
	ld_rrb a, xix, hl
	cp a, 16
	jr	z, 19
	set	7, a
	ld	(0x90e5:16), a
	ld	bc, (0x91b7:16)
	ld	de, (0x91b9:16)
	call	MIDI_DispatchCC_Guarded
	ret

VoiceMode3_InitChannelMatch:
	ld a, (0x91bb:16)
	ld (0x91c8:16), a
	calr VoiceMode3_BuildChannelTable
	cp (0x91d2:16), 255
	jr z, VoiceMode3_NoMatch
	ld xix, 0x91b7
	ld bc, (xix)
	ld de, (xix + 2)
	ld a, (xix - 2)
	bit 2, a
	jr z, VoiceMode3_CheckBit0
	set 7, c

VoiceMode3_CheckBit0:
	bit 0, a
	jr z, VoiceMode3_CheckBit1
	set 7, e

VoiceMode3_CheckBit1:
	bit 1, a
	jr z, VoiceMode3_StoreAndScan
	set 7, d

VoiceMode3_StoreAndScan:
	ld (xix), bc
	ld (xix + 2), de
	ld xiy, 0x91d2

VoiceMode3_ScanLoop:
	ld_spiw WA, 0xf5
	cp a, 0xff
	jr z, VoiceMode3_NoMatch
	cp wa, bc
	jr z, VoiceMode3_FoundMatch
	inc 2, xiy
	jr VoiceMode3_ScanLoop

VoiceMode3_FoundMatch:
	ld_spiw WA, 0xf5
	and d, a
	ld (xix + 2), de
	jr nz, VoiceMode3_StoreSubMode

VoiceMode3_NoMatch:
	ld (0x91b5:16), 255
	jr VoiceMode3_ScanDone

VoiceMode3_StoreSubMode:
	ld (0x91d1:16), w

VoiceMode3_ScanDone:
	ret

VoiceMode3_BuildChannelTable:
	ld (0x91d2:16), 255
	extz hl
	ld l, (0x91c8:16)
	ld xix, 0xf1a0
	ldb_sri L, 0x07, 0xf0, 0xec
	sll hl, 2
	ld xix, VoiceMode_ParamConfigTables_0x5C4
	ld_sril3 XIY, 0x07, 0xf0, 0xec
	ld xix, 0x91d2

VoiceMode3_CopyTableEntry:
	ld_spiw WA, 0xf5
	stw_dpi WA, 0xf1
	cp a, 0xff
	jr z, VoiceMode3_TableCopyDone
	ld_spiw WA, 0xf5
	stw_dpi WA, 0xf1
	jr VoiceMode3_CopyTableEntry

VoiceMode3_TableCopyDone:
	ret

VoiceMode_ParamHandler_0:
	cp (0x91b5:16), 128
	jr nz, VoiceMode0_Done
	ld a, (0x91b9:16)
	ld (0x91c8:16), a
	call PartCtrl_CheckBitmaskBit
	jr nc, VoiceMode0_Done
	ld wa, (0x91b7:16)
	srl w, 1
	jr nc, VoiceMode0_UpdateTempoAndWrite
	set 7, a

VoiceMode0_UpdateTempoAndWrite:
	ld xix, (0xfc62:16)
	and w, 0x1
	andmi16 (xix), 0xfe00
	or (xix), wa
	ldb w, 0xff
	call SeqTimer_UpdateTempoReg
	ld (0x9129:16), wa
	ldw (0x9127:16), 2120
	call SwbtWr_WriteVoiceParam_PreserveRegs

VoiceMode0_Done:
	ret

VoiceParam_DispatchByMode:
	calr MidiVoiceNote_Dispatch
	cp (0x91b5:16), 255
	jr z, VoiceParam_DispatchDone
	ld a, (0x91b5:16)
	and a, 0x3
	sll a, 2
	ld xix, VoiceParam_ModeDispatch_Table
	ld_sril3 XIX, 0x03, 0xf0, 0xe0
	call (xix)

VoiceParam_DispatchDone:
	ret

VoiceParam_ModeDispatch_Table:
	.byte 0x7f, 0xb4, 0xfc, 0x00, 0x09, 0xb5, 0xfc, 0x00
	.byte 0x93, 0xb5, 0xfc, 0x00, 0x26, 0xb6, 0xfc, 0x00

VoiceParam_StoreExpression:
	extz hl
	ld l, (0x91c8:16)
	ld xix, 0x94d2
	ld a, (0x91b7:16)
	set 7, a
	stb_dri A, 0x07, 0xf0, 0xec
	ret

VoiceParam_WriteExpression:
	ldb c, 0xb4
	ld xix, 0xf1a0
	ld l, (0x91c8:16)
	ldb_sri L, 0x03, 0xf0, 0xec
	ld xix, VoiceMode_ParamConfigTables_0x24
	ldb_sri B, 0x03, 0xf0, 0xec
	ld (0x915b:16), bc
	ldb d, 0x7f
	ld (0x915d:16), de
	call PartCtrl_CheckBitmaskBit
	jr nc, VoiceParam_ExprCheckGuard
	ld wa, (0x915b:16)
	ld (0x9127:16), wa
	ld wa, (0x915d:16)
	ld (0x9129:16), wa
	call SwbtWr_WriteVoiceParam_PreserveRegs

VoiceParam_ExprCheckGuard:
	ld l, (0x91c8:16)
	ld xix, 0xf1a0
	cpib_sri 0x03, 0xf0, 0xec, 0x0f
	jr z, VoiceParam_ExprDone
	ld xix, 0x90ce
	ldb_sri A, 0x03, 0xf0, 0xec
	cp a, 0x10
	jr z, VoiceParam_ExprDone
	set 7, a
	ld (0x90e5:16), a
	ld bc, (0x915b:16)
	ld de, (0x915d:16)
	call MIDI_DispatchCC_Guarded

VoiceParam_ExprDone:
	ret

VoiceParam_StoreVolume:
	extz hl
	ld l, (0x91c8:16)
	ld xix, 0x9452
	ld a, (0x91b7:16)
	set 7, a
	stb_dri A, 0x07, 0xf0, 0xec
	ret

VoiceParam_WriteVolume:
	ldb c, 0xb2
	ld xix, 0xf1a0
	ld l, (0x91c8:16)
	ldb_sri L, 0x03, 0xf0, 0xec
	ld xix, VoiceMode_ParamConfigTables_0x24
	ldb_sri B, 0x03, 0xf0, 0xec
	ld (0x915b:16), bc
	ldb d, 0x7f
	ld (0x915d:16), de
	call PartCtrl_CheckBitmaskBit
	jr nc, VoiceParam_VolCheckGuard
	ld wa, (0x915b:16)
	ld (0x9127:16), wa
	ld wa, (0x915d:16)
	ld (0x9129:16), wa
	call SwbtWr_WriteVoiceParam_PreserveRegs

VoiceParam_VolCheckGuard:
	ld l, (0x91c8:16)
	ld xix, 0xf1a0
	cpib_sri 0x03, 0xf0, 0xec, 0x0f
	jr z, VoiceParam_VolDone
	ld xix, 0x90ce
	ldb_sri A, 0x03, 0xf0, 0xec
	cp a, 0x10
	jr z, VoiceParam_VolDone
	set 7, a
	ld (0x90e5:16), a
	ld bc, (0x915b:16)
	ld de, (0x915d:16)
	call MIDI_DispatchCC_Guarded

VoiceParam_VolDone:
	ret

VoiceParam_StorePan:
	extz hl
	ld l, (0x91c8:16)
	sll l, 1
	ld xix, 0x9472
	ld wa, (0x91b7:16)
	and wa, 0x7f7f
	set 7, a
	stw_dri WA, 0x07, 0xf0, 0xec
	ret

VoiceParam_WritePan:
	ldb c, 0xb1
	ld xix, 0xf1a0
	ld l, (0x91c8:16)
	ldb_sri L, 0x03, 0xf0, 0xec
	ld xix, VoiceMode_ParamConfigTables_0x24
	ldb_sri B, 0x03, 0xf0, 0xec
	ld (0x915b:16), bc
	and de, 0x7f7f
	ld (0x915d:16), de
	call PartCtrl_CheckBitmaskBit
	jr nc, VoiceParam_PanCheckGuard
	ld wa, (0x915b:16)
	ld (0x9127:16), wa
	ld wa, (0x915d:16)
	ld (0x9129:16), wa
	call SwbtWr_WriteParamBlockSafe

VoiceParam_PanCheckGuard:
	ld l, (0x91c8:16)
	ld xix, 0xf1a0
	cpib_sri 0x03, 0xf0, 0xec, 0x0f
	jr z, VoiceParam_PanDone
	ld xix, 0x90ce
	ldb_sri A, 0x03, 0xf0, 0xec
	cp a, 0x10
	jr z, VoiceParam_PanDone
	set 7, a
	ld (0x90e5:16), a
	ld bc, (0x915b:16)
	ld de, (0x915d:16)
	call MIDI_DispatchCC_Guarded

VoiceParam_PanDone:
	ret

VoiceNote_StoreBankSelect:

	ld e, (0x91b7:16)
	extz hl
	ld l, (0x91c8:16)
	bit 7, (0x28ad:16)

	; LD SP, (XBC)
	; BIT 7, (28ADh)

	jr nz, VoiceNote_WriteBankAndCC
	set 7, e
	ld xix, 0x9432
	stb_dri E, 0x07, 0xf0, 0xec
	ret

VoiceNote_WriteBankAndCC:
	ldw bc, 0x1b0
	extz hl
	ld l, (0x91c8:16)
	ld xix, 0xf1a0
	ldb_sri A, 0x07, 0xf0, 0xec
	cp a, 0xf
	jr z, VoiceNote_SetupCCParams
	ldb c, 0xb3
	ld xix, VoiceMode_ParamConfigTables_0x24
	ldb_sri B, 0x03, 0xf0, 0xe0

VoiceNote_SetupCCParams:
	ld (0x915b:16), bc
	ldb d, 0x7f
	ld (0x915d:16), de
	call PartCtrl_CheckBitmaskBit
	jr nc, MIDI_VoiceNote_CtrlExit
	cp (0x915b:16), 176
	jr z, VoiceNote_CheckBankSelect
	ld wa, (0x915b:16)
	ld (0x9127:16), wa
	ld wa, (0x915d:16)
	ld (0x9129:16), wa
	call SwbtWr_WriteVoiceParam_PreserveRegs
	jr MIDI_VoiceNote_CtrlExit

VoiceNote_CheckBankSelect:
	bit 7, (0x28ad:16)
	jr nz, VoiceNote_ApplyBankSelect
	bit 7, (0x28ae:16)
	jr z, VoiceNote_CtrlDone

VoiceNote_ApplyBankSelect:
	ld a, (0x915d:16)
	set 7, a
	ld (0x8ee0:16), a
	call Audio_WriteBankSelectParams
	bit 7, (0x28ad:16)
	jr z, MIDI_VoiceNote_CtrlExit
	res 7, (0x28ad:16)

MIDI_VoiceNote_CtrlExit:
	extz hl
	ld l, (0x91c8:16)
	ld xix, 0x90ce
	ldb_sri A, 0x07, 0xf0, 0xec
	cp a, 0x10
	jr z, VoiceNote_CtrlDone
	set 7, a
	ld (0x90e5:16), a
	ld bc, (0x915b:16)
	ld de, (0x915d:16)
	call MIDI_DispatchCC_Guarded

VoiceNote_CtrlDone:
	ret

; MIDI voice note dispatch
MidiVoiceNote_Dispatch:
	ld l, (0x91b5:16)
	and l, 0x3
	sll l, 2
	ld xix, MidiVoiceNote_Dispatch_Table
	ld_sril3 XIX, 0x03, 0xf0, 0xec
	jp (xix)
MidiVoiceNote_Dispatch_Table:
	.byte 0x09, 0xb7, 0xfc, 0x00, 0x19, 0xb7, 0xfc, 0x00
	.byte 0x29, 0xb7, 0xfc, 0x00, 0x39, 0xb7, 0xfc, 0x00

MidiVoiceNote_LookupMode0:
	ld xiy, VoiceMode_ParamConfigTables_0x47
	ld xbc, 0xf
	ld l, (0x91b8:16)
	jr MidiPart_FindChannelInTable

MidiVoiceNote_LookupMode1:
	ld xiy, VoiceMode_ParamConfigTables_0x38
	ld xbc, 0xf
	ld l, (0x91b8:16)
	jr MidiPart_FindChannelInTable

MidiVoiceNote_LookupMode2:
	ld xiy, VoiceMode_ParamConfigTables_0x38
	ld xbc, 0xf
	ld l, (0x91b9:16)
	jr MidiPart_FindChannelInTable

MidiVoiceNote_LookupMode3:
	ld xiy, VoiceMode_ParamConfigTables_0x56
	ld xbc, 0x11
	ld l, (0x91b8:16)

MidiPart_FindChannelInTable:
	cp xbc, 0x0
	jr z, MidiPart_NoChannelFound
	ld (0x91c8:16), l
	ld xix, 0xf1a0
	ldb_sri W, 0x07, 0xf0, 0xec
	ld (0x91cd:16), w

MidiPart_ScanNextEntry:
	ldb_spi A, 0xf4
	cp a, w
	jr z, MidiPart_ScanDone
	djnz xbc, MidiPart_ScanNextEntry

MidiPart_NoChannelFound:
	ld (0x91b5:16), 255

MidiPart_ScanDone:
	ret

MidiNote_RhythmPartDispatch:
	cp bc, 0x48
	jrl nz, MidiNoteVel_Handler_2
	ld (0x915b:16), bc
	ld (0x915d:16), de
	ld (0x91c8:16), a
	ld (0x90f7:16), c
	ld hl, de
	call PartCtrl_WriteProgramChange
	ld (0x91cf:16), hl
	call PartCtrl_CheckBitmaskBit
	jr nc, MidiPart_ChannelDispatch
	ld xix, 0xfc5a
	call MIDI_SetupChannelParams
	ld wa, (0x915d:16)
	ld (xix), a
	andmi8 (xix + 1), 0x80
	or (xix + 1), w
	pushw hl
	ld a, (0x915e:16)
	ldb w, 0x7f
	ldw de, 0x148
	call SwbtWr_QueuePostEvent
	ld a, (0x915d:16)
	ldb w, 0xff
	ldw de, 0x48
	call SwbtWr_QueuePostEvent
	popw hl

; MIDI part channel dispatch
MidiPart_ChannelDispatch:
	extz hl
	ld l, (0x91c8:16)
	ld xix, 0xf1a0
	cpib_sri 0x07, 0xf0, 0xec, 0x10
	jrl nz, MidiNoteVel_Handler_2
	ld xix, 0x90ce
	ldb_sri A, 0x07, 0xf0, 0xec
	cp a, 0x10
	jrl nz, MidiNoteVel_Handler_2
	set 7, a
	ld (0x90e5:16), a
	xor h, h
	ld l, (0xfd50:16)
	and l, 0x3
	sll hl, 2
	ld xix, MidiNote_VelocityHandler_Table
	ld_sril3 XIX, 0x07, 0xf0, 0xec
	jp (xix)


MidiNote_VelocityHandler_Table:
	.long MidiNoteVel_Handler_0
	.long MidiNoteVel_Handler_1
	.long MidiNoteVel_Handler_2
	.long MidiNoteVel_Handler_2

MidiNoteVel_Handler_0:
	ldw	bc, 5249
	xor	de, de
	bit	7, (0x91cf:16)
	jr	z, 2
	inc	1, e
	call	MIDI_DispatchCC_Guarded
	xor	h, h
	ld	l, (0x91c8:16)
	ld	xix, 0x90ce
	ld_rrb	a, xix, hl
	set	7, a
	ld	(0x90e5:16), a
	ldw	bc, 20
	ld	e, (0x91cf:16)
	res	7, e
	ldb	d, 255
	call	MIDI_DispatchCC_Guarded
	jr	t, 0x3f

MidiNoteVel_Handler_1:
	ldw	bc, 5249
	xor	d, d
	bit	7, (0x915d:16)
	jr	z, 2
	ldb	d, 1
	ld	e, (0x915e:16)
	sll	e, 4
	call	MIDI_DispatchCC_Guarded
	extz	hl
	ld	l, (0x91c8:16)
	ld	xix, 0x90ce
	ld_rrb	a, xix, hl
	set	7, a
	ld	(0x90e5:16), a
	ldw	bc, 20
	ld	e, (0x915d:16)
	res	7, e
	ldb	d, 255
	call	MIDI_DispatchCC_Guarded

MidiNoteVel_Handler_2:
	ret

SeqVoice_UpdateTempoParam:
	cp bc, 0x748
	jr nz, SeqVoice_TempoDone
	ld (0x91c8:16), a
	call PartCtrl_CheckBitmaskBit
	jr nc, SeqVoice_TempoDone
	and d, 0x30
	call MIDI_WriteVoiceParamCC
	ld de, (0x9127:16)
	ld wa, (0x9129:16)
	ld (0x912a:16), 0
	call SwbtWr_QueuePostEvent
	set 3, (0x8d52:16)

SeqVoice_TempoDone:
	ret

PendingParam_ScanAllTables:
	ld xiy, 0x94d2
	ldw bc, 0x10

PendingExpr_ScanEntry:
	bitm 7, (xiy)
	jr z, PendingExpr_NextEntry
	resm 7, (xiy)
	ld e, (xiy)
	ld xhl, xiy
	sub xhl, 0x94d2
	ld (0x91c8:16), l
	pushw bc
	push xiy
	calr VoiceParam_WriteExpression
	pop xiy
	popw bc

PendingExpr_NextEntry:
	inc 1, xiy
	djnz xbc, PendingExpr_ScanEntry
	ld xiy, 0x9452
	ldw bc, 0x10

PendingVol_ScanEntry:
	bitm 7, (xiy)
	jr z, PendingVol_NextEntry
	resm 7, (xiy)
	ld e, (xiy)
	ld xhl, xiy
	sub xhl, 0x9452
	ld (0x91c8:16), l
	pushw bc
	push xiy
	calr VoiceParam_WriteVolume
	pop xiy
	popw bc

PendingVol_NextEntry:
	inc 1, xiy
	djnz xbc, PendingVol_ScanEntry
	ld xiy, 0x9472
	ldw bc, 0x10

PendingPan_ScanEntry:
	bitm 7, (xiy)
	jr z, PendingPan_NextEntry
	resm 7, (xiy)
	ld de, (xiy)
	ld xhl, xiy
	sub xhl, 0x9472
	srl l, 1
	ld (0x91c8:16), l
	pushw bc
	push xiy
	calr VoiceParam_WritePan
	pop xiy
	popw bc

PendingPan_NextEntry:
	inc 2, xiy
	djnz xbc, PendingPan_ScanEntry
	ld xiy, 0x9432
	ldw bc, 0x10

PendingBank_ScanEntry:
	bitm 7, (xiy)
	jr z, PendingBank_NextEntry
	resm 7, (xiy)
	ld e, (xiy)
	ld xhl, xiy
	sub xhl, 0x9432
	ld (0x91c8:16), l
	pushw bc
	push xiy
	calr VoiceNote_WriteBankAndCC
	pop xiy
	popw bc

PendingBank_NextEntry:
	inc 1, xiy
	djnz xbc, PendingBank_ScanEntry
	ld xiy, 0x94b2
	ldw bc, 0x10

PendingPartCC_ScanEntry:
	bitm 7, (xiy)
	jr z, PendingPartCC_NextEntry
	resm 7, (xiy)
	ld e, (xiy)
	ld hl, iy
	sub xhl, 0x94b2
	ld (0x91c8:16), l
	pushw bc
	push xiy
	calr MidiPartCC_WriteAndDispatch
	pop xiy
	popw bc

PendingPartCC_NextEntry:
	inc 1, xiy
	djnz xbc, PendingPartCC_ScanEntry
	ret

PartCtrl_CheckBitmaskBit:
	pushw wa
	pushw bc
	ld wa, (0xf1d0:16)
	ld c, (0x91c8:16)
	inc 1, c

PartCtrl_ShiftBitmask:
	srl wa, 1
	djnz8 c, PartCtrl_ShiftBitmask
	popw bc
	popw wa
	ret

AudioCtrl_SaveAllRegs:
	ld (0x9137:16), xwa
	ld (0x913b:16), xbc
	ld (0x913f:16), xde
	ld (0x9143:16), xhl
	ld (0x9147:16), xix
	ld (0x914b:16), xiy
	ld (0x914f:16), xiz
	ret

AudioCtrl_RestoreAllRegs:
	ld xwa, (0x9137:16)
	ld xbc, (0x913b:16)
	ld xde, (0x913f:16)
	ld xhl, (0x9143:16)
	ld xix, (0x9147:16)
	ld xiy, (0x914b:16)
	ld xiz, (0x914f:16)
	ret

VoiceMode_ParamConfigTables:
	.byte 0xb1, 0x17, 0x7f, 0x02, 0xb2, 0x17, 0x7f, 0x03
	.byte 0xb3, 0x17, 0x7f, 0x04, 0xb0, 0x01, 0x7f, 0x04
	.byte 0x17, 0x00, 0xff, 0x00, 0x17, 0x04, 0x48, 0x01
	.byte 0x17, 0x08, 0x7f, 0x01, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0x00, 0x02, 0x01, 0x07
	.byte 0x08, 0x09, 0x0a, 0x0b, 0x04, 0x05, 0x06, 0x03
	.byte 0x0f, 0x15, 0x15, 0x00, 0x00, 0x0c, 0x0d, 0x0e
	.byte 0x00, 0x02, 0x01, 0x08, 0x09, 0x0a, 0x0b, 0x03
	.byte 0x04, 0x05, 0x06, 0x07, 0x11, 0x12, 0x13, 0x00
	.byte 0x02, 0x01, 0x08, 0x09, 0x0a, 0x0b, 0x03, 0x04
	.byte 0x05, 0x06, 0x07, 0x11, 0x12, 0x13, 0x00, 0x02
	.byte 0x01, 0x08, 0x09, 0x0a, 0x0b, 0x03, 0x04, 0x05
	.byte 0x06, 0x07, 0x11, 0x12, 0x13, 0x0c, 0x0f, 0xff
	.byte 0x97, 0xba, 0xfc, 0x00, 0x47, 0xbb, 0xfc, 0x00
	.byte 0xef, 0xba, 0xfc, 0x00, 0xaf, 0xbc, 0xfc, 0x00
	.byte 0xf3, 0xbc, 0xfc, 0x00, 0x37, 0xbd, 0xfc, 0x00
	.byte 0x7b, 0xbd, 0xfc, 0x00, 0xbf, 0xbd, 0xfc, 0x00
	.byte 0xe3, 0xbb, 0xfc, 0x00, 0x27, 0xbc, 0xfc, 0x00
	.byte 0x6b, 0xbc, 0xfc, 0x00, 0x9f, 0xbb, 0xfc, 0x00
	.byte 0xcf, 0xbe, 0xfc, 0x00, 0xf7, 0xbe, 0xfc, 0x00
	.byte 0xff, 0xbe, 0xfc, 0x00, 0x37, 0xbf, 0xfc, 0x00
	.byte 0x23, 0xbf, 0xfc, 0x00, 0x03, 0xbe, 0xfc, 0x00
	.byte 0x47, 0xbe, 0xfc, 0x00, 0x8b, 0xbe, 0xfc, 0x00
	.byte 0xb4, 0x00, 0x7f, 0x06, 0xb1, 0x00, 0x7f, 0x03
	.byte 0xb2, 0x00, 0x7f, 0x04, 0xb3, 0x00, 0x7f, 0x05
	.byte 0x00, 0x00, 0xff, 0x00, 0x00, 0x03, 0xff, 0x01
	.byte 0x00, 0x04, 0x48, 0x01, 0x00, 0x05, 0x7f, 0x01
	.byte 0x00, 0x07, 0x7f, 0x01, 0x00, 0x08, 0x7f, 0x01
	.byte 0x00, 0x0b, 0x7f, 0x01, 0x00, 0x0a, 0xff, 0x01
	.byte 0x00, 0x09, 0x7f, 0x01, 0x44, 0x03, 0xff, 0x01
	.byte 0x44, 0x04, 0xff, 0x01, 0x44, 0x05, 0xff, 0x01
	.byte 0x44, 0x06, 0xff, 0x01, 0x44, 0x07, 0x3f, 0x01
	.byte 0xad, 0x00, 0x7f, 0x01, 0xae, 0x00, 0x7f, 0x01
	.fill 8, 1, 0xff
	.byte 0xb4, 0x01, 0x7f, 0x06, 0xb1, 0x01, 0x7f, 0x03
	.byte 0xb2, 0x01, 0x7f, 0x04, 0xb3, 0x01, 0x7f, 0x05
	.byte 0x01, 0x00, 0xff, 0x00, 0x01, 0x03, 0xff, 0x01
	.byte 0x01, 0x04, 0x48, 0x01, 0x01, 0x05, 0x7f, 0x01
	.byte 0x01, 0x07, 0x7f, 0x01, 0x01, 0x08, 0x7f, 0x01
	.byte 0x01, 0x0b, 0x7f, 0x01, 0x01, 0x0a, 0xff, 0x01
	.byte 0x01, 0x09, 0x7f, 0x01, 0x45, 0x03, 0xff, 0x01
	.byte 0x45, 0x04, 0xff, 0x01, 0x45, 0x05, 0xff, 0x01
	.byte 0x45, 0x06, 0xff, 0x01, 0x45, 0x07, 0x3f, 0x01
	.byte 0xad, 0x01, 0x7f, 0x01, 0xae, 0x01, 0x7f, 0x01
	.fill 8, 1, 0xff
	.byte 0xb4, 0x02, 0x7f, 0x06, 0xb1, 0x02, 0x7f, 0x03
	.byte 0xb2, 0x02, 0x7f, 0x04, 0xb3, 0x02, 0x7f, 0x05
	.byte 0x02, 0x00, 0xff, 0x00, 0x02, 0x03, 0xff, 0x01
	.byte 0x02, 0x04, 0x48, 0x01, 0x02, 0x05, 0x7f, 0x01
	.byte 0x02, 0x07, 0x7f, 0x01, 0x02, 0x08, 0x7f, 0x01
	.byte 0x02, 0x0b, 0x7f, 0x01, 0x02, 0x0a, 0xff, 0x01
	.byte 0x02, 0x09, 0x7f, 0x01, 0x46, 0x03, 0xff, 0x01
	.byte 0x46, 0x04, 0xff, 0x01, 0x46, 0x05, 0xff, 0x01
	.byte 0x46, 0x06, 0xff, 0x01, 0x46, 0x07, 0x3f, 0x01
	.byte 0xad, 0x02, 0x7f, 0x01, 0xae, 0x02, 0x7f, 0x01
	.fill 8, 1, 0xff
	.byte 0xb4, 0x03, 0x7f, 0x06, 0xb1, 0x03, 0x7f, 0x03
	.byte 0xb2, 0x03, 0x7f, 0x04, 0xb3, 0x03, 0x7f, 0x05
	.byte 0x03, 0x00, 0xff, 0x00, 0x03, 0x03, 0xff, 0x01
	.byte 0x03, 0x04, 0x48, 0x01, 0x03, 0x05, 0x7f, 0x01
	.byte 0x03, 0x07, 0x7f, 0x01, 0x03, 0x08, 0x7f, 0x01
	.byte 0x03, 0x0b, 0x7f, 0x01, 0x03, 0x0a, 0xff, 0x01
	.byte 0x03, 0x09, 0x7f, 0x01, 0xad, 0x03, 0x7f, 0x01
	.byte 0xae, 0x03, 0x7f, 0x01, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xb4, 0x04, 0x7f, 0x06
	.byte 0xb1, 0x04, 0x7f, 0x03, 0xb2, 0x04, 0x7f, 0x04
	.byte 0xb3, 0x04, 0x7f, 0x05, 0x04, 0x00, 0xff, 0x00
	.byte 0x04, 0x03, 0xff, 0x01, 0x04, 0x04, 0x48, 0x01
	.byte 0x04, 0x05, 0x7f, 0x01, 0x04, 0x07, 0x7f, 0x01
	.byte 0x04, 0x08, 0x7f, 0x01, 0x04, 0x0b, 0x7f, 0x01
	.byte 0x04, 0x0a, 0xff, 0x01, 0x04, 0x09, 0x7f, 0x01
	.byte 0xad, 0x04, 0x7f, 0x01, 0xae, 0x04, 0x7f, 0x01
	.fill 8, 1, 0xff
	.byte 0xb4, 0x05, 0x7f, 0x06, 0xb1, 0x05, 0x7f, 0x03
	.byte 0xb2, 0x05, 0x7f, 0x04, 0xb3, 0x05, 0x7f, 0x05
	.byte 0x05, 0x00, 0xff, 0x00, 0x05, 0x03, 0xff, 0x01
	.byte 0x05, 0x04, 0x48, 0x01, 0x05, 0x05, 0x7f, 0x01
	.byte 0x05, 0x07, 0x7f, 0x01, 0x05, 0x08, 0x7f, 0x01
	.byte 0x05, 0x0b, 0x7f, 0x01, 0x05, 0x0a, 0xff, 0x01
	.byte 0x05, 0x09, 0x7f, 0x01, 0xad, 0x05, 0x7f, 0x01
	.byte 0xae, 0x05, 0x7f, 0x01, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xb4, 0x06, 0x7f, 0x06
	.byte 0xb1, 0x06, 0x7f, 0x03, 0xb2, 0x06, 0x7f, 0x04
	.byte 0xb3, 0x06, 0x7f, 0x05, 0x06, 0x00, 0xff, 0x00
	.byte 0x06, 0x03, 0xff, 0x01, 0x06, 0x04, 0x48, 0x01
	.byte 0x06, 0x05, 0x7f, 0x01, 0x06, 0x07, 0x7f, 0x01
	.byte 0x06, 0x08, 0x7f, 0x01, 0x06, 0x0b, 0x7f, 0x01
	.byte 0x06, 0x0a, 0xff, 0x01, 0x06, 0x09, 0x7f, 0x01
	.byte 0xad, 0x06, 0x7f, 0x01, 0xae, 0x06, 0x7f, 0x01
	.fill 8, 1, 0xff
	.byte 0xb4, 0x07, 0x7f, 0x06, 0xb1, 0x07, 0x7f, 0x03
	.byte 0xb2, 0x07, 0x7f, 0x04, 0xb3, 0x07, 0x7f, 0x05
	.byte 0x07, 0x00, 0xff, 0x00, 0x07, 0x03, 0xff, 0x01
	.byte 0x07, 0x04, 0x48, 0x01, 0x07, 0x05, 0x7f, 0x01
	.byte 0x07, 0x07, 0x7f, 0x01, 0x07, 0x08, 0x7f, 0x01
	.byte 0x07, 0x0b, 0x7f, 0x01, 0x07, 0x0a, 0xff, 0x01
	.byte 0x07, 0x09, 0x7f, 0x01, 0xad, 0x07, 0x7f, 0x01
	.byte 0xae, 0x07, 0x7f, 0x01, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xb4, 0x08, 0x7f, 0x06
	.byte 0xb1, 0x08, 0x7f, 0x03, 0xb2, 0x08, 0x7f, 0x04
	.byte 0xb3, 0x08, 0x7f, 0x05, 0x08, 0x00, 0xff, 0x00
	.byte 0x08, 0x03, 0xff, 0x01, 0x08, 0x04, 0x48, 0x01
	.byte 0x08, 0x05, 0x7f, 0x01, 0x08, 0x07, 0x7f, 0x01
	.byte 0x08, 0x08, 0x7f, 0x01, 0x08, 0x0b, 0x7f, 0x01
	.byte 0x08, 0x0a, 0xff, 0x01, 0x08, 0x09, 0x7f, 0x01
	.byte 0xad, 0x08, 0x7f, 0x01, 0xae, 0x08, 0x7f, 0x01
	.fill 8, 1, 0xff
	.byte 0xb4, 0x09, 0x7f, 0x06, 0xb1, 0x09, 0x7f, 0x03
	.byte 0xb2, 0x09, 0x7f, 0x04, 0xb3, 0x09, 0x7f, 0x05
	.byte 0x09, 0x00, 0xff, 0x00, 0x09, 0x03, 0xff, 0x01
	.byte 0x09, 0x04, 0x48, 0x01, 0x09, 0x05, 0x7f, 0x01
	.byte 0x09, 0x07, 0x7f, 0x01, 0x09, 0x08, 0x7f, 0x01
	.byte 0x09, 0x0b, 0x7f, 0x01, 0x09, 0x0a, 0xff, 0x01
	.byte 0x09, 0x09, 0x7f, 0x01, 0xad, 0x09, 0x7f, 0x01
	.byte 0xae, 0x09, 0x7f, 0x01, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xb4, 0x0a, 0x7f, 0x06
	.byte 0xb1, 0x0a, 0x7f, 0x03, 0xb2, 0x0a, 0x7f, 0x04
	.byte 0xb3, 0x0a, 0x7f, 0x05, 0x0a, 0x00, 0xff, 0x00
	.byte 0x0a, 0x03, 0xff, 0x01, 0x0a, 0x04, 0x48, 0x01
	.byte 0x0a, 0x05, 0x7f, 0x01, 0x0a, 0x07, 0x7f, 0x01
	.byte 0x0a, 0x08, 0x7f, 0x01, 0x0a, 0x0b, 0x7f, 0x01
	.byte 0x0a, 0x0a, 0xff, 0x01, 0x0a, 0x09, 0x7f, 0x01
	.byte 0xad, 0x0a, 0x7f, 0x01, 0xae, 0x0a, 0x7f, 0x01
	.fill 8, 1, 0xff
	.byte 0xb4, 0x0b, 0x7f, 0x06, 0xb1, 0x0b, 0x7f, 0x03
	.byte 0xb2, 0x0b, 0x7f, 0x04, 0xb3, 0x0b, 0x7f, 0x05
	.byte 0x0b, 0x00, 0xff, 0x00, 0x0b, 0x03, 0xff, 0x01
	.byte 0x0b, 0x04, 0x48, 0x01, 0x0b, 0x05, 0x7f, 0x01
	.byte 0x0b, 0x07, 0x7f, 0x01, 0x0b, 0x08, 0x7f, 0x01
	.byte 0x0b, 0x0b, 0x7f, 0x01, 0x0b, 0x0a, 0xff, 0x01
	.byte 0x0b, 0x09, 0x7f, 0x01, 0xad, 0x0b, 0x7f, 0x01
	.byte 0xae, 0x0b, 0x7f, 0x01, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xb4, 0x0c, 0x7f, 0x06
	.byte 0xb1, 0x0c, 0x7f, 0x03, 0xb2, 0x0c, 0x7f, 0x04
	.byte 0xb3, 0x0c, 0x7f, 0x05, 0x0c, 0x00, 0xff, 0x00
	.byte 0x0c, 0x03, 0xff, 0x01, 0x0c, 0x04, 0x48, 0x01
	.byte 0x0c, 0x05, 0x7f, 0x01, 0x0c, 0x07, 0x7f, 0x01
	.byte 0x0c, 0x08, 0x7f, 0x01, 0x0c, 0x0b, 0x7f, 0x01
	.byte 0x0c, 0x0a, 0xff, 0x01, 0x0c, 0x09, 0x7f, 0x01
	.byte 0xad, 0x0c, 0x7f, 0x01, 0xae, 0x0c, 0x7f, 0x01
	.fill 8, 1, 0xff
	.byte 0xb4, 0x0d, 0x7f, 0x06, 0xb1, 0x0d, 0x7f, 0x03
	.byte 0xb2, 0x0d, 0x7f, 0x04, 0xb3, 0x0d, 0x7f, 0x05
	.byte 0x0d, 0x00, 0xff, 0x00, 0x0d, 0x03, 0xff, 0x01
	.byte 0x0d, 0x04, 0x48, 0x01, 0x0d, 0x05, 0x7f, 0x01
	.byte 0x0d, 0x07, 0x7f, 0x01, 0x0d, 0x08, 0x7f, 0x01
	.byte 0x0d, 0x0b, 0x7f, 0x01, 0x0d, 0x0a, 0xff, 0x01
	.byte 0x0d, 0x09, 0x7f, 0x01, 0xad, 0x0d, 0x7f, 0x01
	.byte 0xae, 0x0d, 0x7f, 0x01, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xb4, 0x0e, 0x7f, 0x06
	.byte 0xb1, 0x0e, 0x7f, 0x03, 0xb2, 0x0e, 0x7f, 0x04
	.byte 0xb3, 0x0e, 0x7f, 0x05, 0x0e, 0x00, 0xff, 0x00
	.byte 0x0e, 0x03, 0xff, 0x01, 0x0e, 0x04, 0x48, 0x01
	.byte 0x0e, 0x05, 0x7f, 0x01, 0x0e, 0x07, 0x7f, 0x01
	.byte 0x0e, 0x08, 0x7f, 0x01, 0x0e, 0x0b, 0x7f, 0x01
	.byte 0x0e, 0x0a, 0xff, 0x01, 0x0e, 0x09, 0x7f, 0x01
	.byte 0xad, 0x0e, 0x7f, 0x01, 0xae, 0x0e, 0x7f, 0x01
	.fill 8, 1, 0xff
	.byte 0xb3, 0x0f, 0x7f, 0x05, 0x0f, 0x00, 0xff, 0x00
	.byte 0x0f, 0x03, 0xff, 0x01, 0x0f, 0x04, 0x48, 0x01
	.byte 0x0f, 0x05, 0x7f, 0x01, 0x0f, 0x07, 0x7f, 0x01
	.byte 0xad, 0x0f, 0x7f, 0x01, 0xae, 0x0f, 0x7f, 0x01
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0x48, 0x03, 0x0f, 0x01, 0x90, 0x03, 0x02, 0x01
	.byte 0x10, 0x03, 0xff, 0x01, 0x11, 0x03, 0xff, 0x01
	.byte 0x12, 0x03, 0xff, 0x01, 0x13, 0x03, 0xff, 0x01
	.byte 0x14, 0x03, 0xff, 0x01, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0x48, 0x00, 0xff, 0x00
	.byte 0x48, 0x08, 0xff, 0x02, 0x48, 0x07, 0x30, 0x01
	.fill 8, 1, 0xff
	.byte 0x48, 0x03, 0x0f, 0x01, 0x48, 0x04, 0x50, 0x01
	.byte 0x48, 0x00, 0xff, 0x00, 0x48, 0x07, 0x30, 0x01
	.byte 0x48, 0x08, 0xff, 0x02, 0x90, 0x00, 0x1f, 0x01
	.byte 0x90, 0x01, 0x1f, 0x01, 0x90, 0x03, 0x02, 0x01
	.byte 0x60, 0x01, 0xc0, 0x01, 0x70, 0x00, 0x07, 0x01
	.byte 0x70, 0x02, 0xff, 0x01, 0x98, 0x0b, 0xc0, 0x01
	.byte 0x98, 0x01, 0x7f, 0x01, 0x98, 0x02, 0x80, 0x01
	.byte 0x98, 0x03, 0x01, 0x01, 0xb0, 0x01, 0x7f, 0x05
	.byte 0x10, 0x03, 0xff, 0x01, 0x11, 0x03, 0xff, 0x01
	.byte 0x12, 0x03, 0xff, 0x01, 0x13, 0x03, 0xff, 0x01
	.byte 0x14, 0x03, 0xff, 0x01, 0x72, 0x03, 0xff, 0x01
	.byte 0x72, 0x07, 0x7f, 0x06, 0xff, 0xff, 0xff, 0xff
	.fill 8, 1, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xf3, 0xbf, 0xfc, 0x00
	.byte 0xfb, 0xc0, 0xfc, 0x00, 0x77, 0xc0, 0xfc, 0x00
	.byte 0x3f, 0xc2, 0xfc, 0x00, 0x6f, 0xc2, 0xfc, 0x00
	.byte 0x9f, 0xc2, 0xfc, 0x00, 0xcf, 0xc2, 0xfc, 0x00
	.byte 0xff, 0xc2, 0xfc, 0x00, 0xaf, 0xc1, 0xfc, 0x00
	.byte 0xdf, 0xc1, 0xfc, 0x00, 0x0f, 0xc2, 0xfc, 0x00
	.byte 0x7f, 0xc1, 0xfc, 0x00, 0xbf, 0xc3, 0xfc, 0x00
	.byte 0xdf, 0xc3, 0xfc, 0x00, 0xef, 0xc3, 0xfc, 0x00
	.byte 0x2f, 0xc4, 0xfc, 0x00, 0x1b, 0xc4, 0xfc, 0x00
	.byte 0x2f, 0xc3, 0xfc, 0x00, 0x5f, 0xc3, 0xfc, 0x00
	.byte 0x8f, 0xc3, 0xfc, 0x00, 0x00, 0x03, 0xff, 0x05
	.byte 0x00, 0x04, 0x48, 0x06, 0x00, 0x05, 0x7f, 0x06
	.byte 0x00, 0x07, 0x7f, 0x06, 0x00, 0x08, 0x7f, 0x06
	.byte 0x00, 0x0b, 0x7f, 0x06, 0x00, 0x0a, 0xff, 0x06
	.byte 0x00, 0x09, 0x7f, 0x06, 0x44, 0x03, 0xff, 0x06
	.byte 0x44, 0x04, 0xff, 0x06, 0x44, 0x05, 0xff, 0x06
	.byte 0x44, 0x06, 0xff, 0x06, 0x44, 0x07, 0x3f, 0x06
	.byte 0xad, 0x00, 0x7f, 0x03, 0xae, 0x00, 0x7f, 0x04
	.byte 0x9a, 0x04, 0xff, 0x06, 0x9a, 0x05, 0xff, 0x06
	.byte 0x9a, 0x06, 0xff, 0x06, 0x9a, 0x07, 0xff, 0x06
	.byte 0x9a, 0x08, 0xff, 0x06, 0x9a, 0x09, 0xff, 0x06
	.byte 0x9a, 0x0a, 0xff, 0x06, 0x9a, 0x0b, 0xff, 0x06
	.byte 0x9a, 0x0c, 0xff, 0x06, 0x9a, 0x0d, 0xff, 0x06
	.byte 0x9a, 0x0e, 0xff, 0x06, 0x9a, 0x0f, 0xff, 0x06
	.byte 0x9a, 0x10, 0xff, 0x06, 0x9a, 0x11, 0xff, 0x06
	.byte 0x9a, 0x12, 0xff, 0x06, 0x9a, 0x13, 0xff, 0x06
	.fill 8, 1, 0xff
	.byte 0x01, 0x03, 0xff, 0x05, 0x01, 0x04, 0x48, 0x06
	.byte 0x01, 0x05, 0x7f, 0x06, 0x01, 0x07, 0x7f, 0x06
	.byte 0x01, 0x08, 0x7f, 0x06, 0x01, 0x0b, 0x7f, 0x06
	.byte 0x01, 0x0a, 0xff, 0x06, 0x01, 0x09, 0x7f, 0x06
	.byte 0x45, 0x03, 0xff, 0x06, 0x45, 0x04, 0xff, 0x06
	.byte 0x45, 0x05, 0xff, 0x06, 0x45, 0x06, 0xff, 0x06
	.byte 0x45, 0x07, 0x3f, 0x06, 0xad, 0x01, 0x7f, 0x03
	.byte 0xae, 0x01, 0x7f, 0x04, 0x9a, 0x04, 0xff, 0x06
	.byte 0x9a, 0x05, 0xff, 0x06, 0x9a, 0x06, 0xff, 0x06
	.byte 0x9a, 0x07, 0xff, 0x06, 0x9a, 0x08, 0xff, 0x06
	.byte 0x9a, 0x09, 0xff, 0x06, 0x9a, 0x0a, 0xff, 0x06
	.byte 0x9a, 0x0b, 0xff, 0x06, 0x9a, 0x0c, 0xff, 0x06
	.byte 0x9a, 0x0d, 0xff, 0x06, 0x9a, 0x0e, 0xff, 0x06
	.byte 0x9a, 0x0f, 0xff, 0x06, 0x9a, 0x10, 0xff, 0x06
	.byte 0x9a, 0x11, 0xff, 0x06, 0x9a, 0x12, 0xff, 0x06
	.byte 0x9a, 0x13, 0xff, 0x06, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0x02, 0x03, 0xff, 0x05
	.byte 0x02, 0x04, 0x48, 0x06, 0x02, 0x05, 0x7f, 0x06
	.byte 0x02, 0x07, 0x7f, 0x06, 0x02, 0x08, 0x7f, 0x06
	.byte 0x02, 0x0b, 0x7f, 0x06, 0x02, 0x0a, 0xff, 0x06
	.byte 0x02, 0x09, 0x7f, 0x06, 0x46, 0x03, 0xff, 0x06
	.byte 0x46, 0x04, 0xff, 0x06, 0x46, 0x05, 0xff, 0x06
	.byte 0x46, 0x06, 0xff, 0x06, 0x46, 0x07, 0x3f, 0x06
	.byte 0xad, 0x02, 0x7f, 0x03, 0xae, 0x02, 0x7f, 0x04
	.byte 0x9a, 0x04, 0xff, 0x06, 0x9a, 0x05, 0xff, 0x06
	.byte 0x9a, 0x06, 0xff, 0x06, 0x9a, 0x07, 0xff, 0x06
	.byte 0x9a, 0x08, 0xff, 0x06, 0x9a, 0x09, 0xff, 0x06
	.byte 0x9a, 0x0a, 0xff, 0x06, 0x9a, 0x0b, 0xff, 0x06
	.byte 0x9a, 0x0c, 0xff, 0x06, 0x9a, 0x0d, 0xff, 0x06
	.byte 0x9a, 0x0e, 0xff, 0x06, 0x9a, 0x0f, 0xff, 0x06
	.byte 0x9a, 0x10, 0xff, 0x06, 0x9a, 0x11, 0xff, 0x06
	.byte 0x9a, 0x12, 0xff, 0x06, 0x9a, 0x13, 0xff, 0x06
	.fill 8, 1, 0xff
	.byte 0x03, 0x03, 0xff, 0x05, 0x03, 0x04, 0x48, 0x06
	.byte 0x03, 0x05, 0x7f, 0x06, 0x03, 0x07, 0x7f, 0x06
	.byte 0x03, 0x08, 0x7f, 0x06, 0x03, 0x0b, 0x7f, 0x06
	.byte 0x03, 0x0a, 0xff, 0x06, 0x03, 0x09, 0x7f, 0x06
	.byte 0xad, 0x03, 0x7f, 0x03, 0xae, 0x03, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x04, 0x03, 0xff, 0x05, 0x04, 0x04, 0x48, 0x06
	.byte 0x04, 0x05, 0x7f, 0x06, 0x04, 0x07, 0x7f, 0x06
	.byte 0x04, 0x08, 0x7f, 0x06, 0x04, 0x0b, 0x7f, 0x06
	.byte 0x04, 0x0a, 0xff, 0x06, 0x04, 0x09, 0x7f, 0x06
	.byte 0xad, 0x04, 0x7f, 0x03, 0xae, 0x04, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x05, 0x03, 0xff, 0x05, 0x05, 0x04, 0x48, 0x06
	.byte 0x05, 0x05, 0x7f, 0x06, 0x05, 0x07, 0x7f, 0x06
	.byte 0x05, 0x08, 0x7f, 0x06, 0x05, 0x0b, 0x7f, 0x06
	.byte 0x05, 0x0a, 0xff, 0x06, 0x05, 0x09, 0x7f, 0x06
	.byte 0xad, 0x05, 0x7f, 0x03, 0xae, 0x05, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x06, 0x03, 0xff, 0x05, 0x06, 0x04, 0x48, 0x06
	.byte 0x06, 0x05, 0x7f, 0x06, 0x06, 0x07, 0x7f, 0x06
	.byte 0x06, 0x08, 0x7f, 0x06, 0x06, 0x0b, 0x7f, 0x06
	.byte 0x06, 0x0a, 0xff, 0x06, 0x06, 0x09, 0x7f, 0x06
	.byte 0xad, 0x06, 0x7f, 0x03, 0xae, 0x06, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x07, 0x03, 0xff, 0x05, 0x07, 0x04, 0x48, 0x06
	.byte 0x07, 0x05, 0x7f, 0x06, 0x07, 0x07, 0x7f, 0x06
	.byte 0x07, 0x08, 0x7f, 0x06, 0x07, 0x0b, 0x7f, 0x06
	.byte 0x07, 0x0a, 0xff, 0x06, 0x07, 0x09, 0x7f, 0x06
	.byte 0xad, 0x07, 0x7f, 0x03, 0xae, 0x07, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x08, 0x03, 0xff, 0x05, 0x08, 0x04, 0x48, 0x06
	.byte 0x08, 0x05, 0x7f, 0x06, 0x08, 0x07, 0x7f, 0x06
	.byte 0x08, 0x08, 0x7f, 0x06, 0x08, 0x0b, 0x7f, 0x06
	.byte 0x08, 0x0a, 0xff, 0x06, 0x08, 0x09, 0x7f, 0x06
	.byte 0xad, 0x08, 0x7f, 0x03, 0xae, 0x08, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x09, 0x03, 0xff, 0x05, 0x09, 0x04, 0x48, 0x06
	.byte 0x09, 0x05, 0x7f, 0x06, 0x09, 0x07, 0x7f, 0x06
	.byte 0x09, 0x08, 0x7f, 0x06, 0x09, 0x0b, 0x7f, 0x06
	.byte 0x09, 0x0a, 0xff, 0x06, 0x09, 0x09, 0x7f, 0x06
	.byte 0xad, 0x09, 0x7f, 0x03, 0xae, 0x09, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x0a, 0x03, 0xff, 0x05, 0x0a, 0x04, 0x48, 0x06
	.byte 0x0a, 0x05, 0x7f, 0x06, 0x0a, 0x07, 0x7f, 0x06
	.byte 0x0a, 0x08, 0x7f, 0x06, 0x0a, 0x0b, 0x7f, 0x06
	.byte 0x0a, 0x0a, 0xff, 0x06, 0x0a, 0x09, 0x7f, 0x06
	.byte 0xad, 0x0a, 0x7f, 0x03, 0xae, 0x0a, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x0b, 0x03, 0xff, 0x05, 0x0b, 0x04, 0x48, 0x06
	.byte 0x0b, 0x05, 0x7f, 0x06, 0x0b, 0x07, 0x7f, 0x06
	.byte 0x0b, 0x08, 0x7f, 0x06, 0x0b, 0x0b, 0x7f, 0x06
	.byte 0x0b, 0x0a, 0xff, 0x06, 0x0b, 0x09, 0x7f, 0x06
	.byte 0xad, 0x0b, 0x7f, 0x03, 0xae, 0x0b, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x0c, 0x03, 0xff, 0x05, 0x0c, 0x04, 0x48, 0x06
	.byte 0x0c, 0x05, 0x7f, 0x06, 0x0c, 0x07, 0x7f, 0x06
	.byte 0x0c, 0x08, 0x7f, 0x06, 0x0c, 0x0b, 0x7f, 0x06
	.byte 0x0c, 0x0a, 0xff, 0x06, 0x0c, 0x09, 0x7f, 0x06
	.byte 0xad, 0x0c, 0x7f, 0x03, 0xae, 0x0c, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x0d, 0x03, 0xff, 0x05, 0x0d, 0x04, 0x48, 0x06
	.byte 0x0d, 0x05, 0x7f, 0x06, 0x0d, 0x07, 0x7f, 0x06
	.byte 0x0d, 0x08, 0x7f, 0x06, 0x0d, 0x0b, 0x7f, 0x06
	.byte 0x0d, 0x0a, 0xff, 0x06, 0x0d, 0x09, 0x7f, 0x06
	.byte 0xad, 0x0d, 0x7f, 0x03, 0xae, 0x0d, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x0e, 0x03, 0xff, 0x05, 0x0e, 0x04, 0x48, 0x06
	.byte 0x0e, 0x05, 0x7f, 0x06, 0x0e, 0x07, 0x7f, 0x06
	.byte 0x0e, 0x08, 0x7f, 0x06, 0x0e, 0x0b, 0x7f, 0x06
	.byte 0x0e, 0x0a, 0xff, 0x06, 0x0e, 0x09, 0x7f, 0x06
	.byte 0xad, 0x0e, 0x7f, 0x03, 0xae, 0x0e, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x0f, 0x03, 0xff, 0x05, 0x0f, 0x04, 0x48, 0x06
	.byte 0x0f, 0x05, 0x7f, 0x06, 0x0f, 0x07, 0x7f, 0x06
	.byte 0xad, 0x0f, 0x7f, 0x03, 0xae, 0x0f, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x48, 0x05, 0xfc, 0x01, 0x48, 0x06, 0xfc, 0x01
	.fill 8, 1, 0xff
	.byte 0x48, 0x05, 0xfc, 0x01, 0x48, 0x06, 0xfc, 0x01
	.byte 0x48, 0x03, 0x0f, 0x00, 0x90, 0x03, 0x02, 0x06
	.byte 0x10, 0x03, 0xff, 0x06, 0x11, 0x03, 0xff, 0x06
	.byte 0x12, 0x03, 0xff, 0x06, 0x13, 0x03, 0xff, 0x06
	.byte 0x14, 0x03, 0xff, 0x06, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0x48, 0x05, 0xfc, 0x01
	.byte 0x48, 0x06, 0xfc, 0x01, 0x48, 0x07, 0x30, 0x06
	.fill 8, 1, 0xff
	.byte 0x48, 0x05, 0xfc, 0x01, 0x48, 0x06, 0xfc, 0x01
	.byte 0x48, 0x03, 0x0f, 0x00, 0x48, 0x04, 0x50, 0x06
	.byte 0x48, 0x07, 0x30, 0x06, 0x90, 0x00, 0x1f, 0x06
	.byte 0x90, 0x01, 0x1f, 0x06, 0x90, 0x03, 0x02, 0x06
	.byte 0x60, 0x01, 0xc0, 0x06, 0x70, 0x00, 0x07, 0x06
	.byte 0x70, 0x02, 0xff, 0x06, 0x98, 0x0b, 0xc0, 0x06
	.byte 0x98, 0x01, 0x7f, 0x06, 0x98, 0x02, 0x80, 0x06
	.byte 0x98, 0x03, 0x01, 0x06, 0x10, 0x03, 0xff, 0x06
	.byte 0x11, 0x03, 0xff, 0x06, 0x12, 0x03, 0xff, 0x06
	.byte 0x13, 0x03, 0xff, 0x06, 0x14, 0x03, 0xff, 0x06
	.byte 0x72, 0x03, 0xff, 0x06, 0x72, 0x07, 0x7f, 0x06
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xd7, 0xc4, 0xfc, 0x00
	.byte 0xf3, 0xc4, 0xfc, 0x00, 0xff, 0xff, 0xff, 0xff
	.byte 0x0f, 0xc5, 0xfc, 0x00, 0xff, 0xff, 0xff, 0xff
	.fill 8, 1, 0xff
	.byte 0x2b, 0xc5, 0xfc, 0x00, 0xff, 0xff, 0xff, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xb1, 0x10, 0x7f, 0x01, 0xb2, 0x10, 0x7f, 0x00
	.byte 0xb3, 0x10, 0x7f, 0x02, 0x10, 0x04, 0x08, 0x03
	.byte 0x10, 0x08, 0x7f, 0x04, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xb1, 0x11, 0x7f, 0x01
	.byte 0xb2, 0x11, 0x7f, 0x00, 0xb3, 0x11, 0x7f, 0x02
	.byte 0x11, 0x04, 0x08, 0x03, 0x11, 0x08, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0xb1, 0x12, 0x7f, 0x01, 0xb2, 0x12, 0x7f, 0x00
	.byte 0xb3, 0x12, 0x7f, 0x02, 0x12, 0x04, 0x08, 0x03
	.byte 0x12, 0x08, 0x7f, 0x04, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xb1, 0x13, 0x7f, 0x01
	.byte 0xb2, 0x13, 0x7f, 0x00, 0xb3, 0x13, 0x7f, 0x02
	.byte 0x13, 0x04, 0x08, 0x03, 0x13, 0x08, 0x7f, 0x04
	.fill 8, 1, 0xff
	ld	(0x90f8:16), 255
	ld	a, (0xfda1:16)
	and	a, 63
	ld	w, e
	and	w, 192
	or	a, w
	ld	(0xfda1:16), a
	ld	e, a
	ld	(0x9127:16), bc
	ld	(0x9129:16), de
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ret
	ld	(0x90f8:16), 255
	ld	(0x9127:16), bc
	ld	(0x9129:16), de
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ret
	calr	1434
	ret

MidiStream_ApplyPendingParams:
	cp (0x8d34:16), 14
	jr z, MidiStream_ApplyDone
	ld (0x90f8:16), 255
	and d, 0x7
	jr z, MidiStream_ApplyDone
	call MIDI_WriteVoiceParamCC
	ld a, (0x912a:16)
	and a, 0x7
	jr z, MidiStream_CallFilterAndAudio
	call ToneGen_DispatchByMode
	or (0x90f9:16), 1

MidiStream_CallFilterAndAudio:
	call SwbtWr_WriteVoiceParam_PreserveRegs
	call MIDI_WriteResetSequence

MidiStream_ApplyDone:
	ret

MidiStream_DispatchData:
	calr	1382
	ret
	ld	(0x90f8:16), 255
	call	MIDI_WriteVoiceParamDirect
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ret
	calr	1364
	ret
	cp	bc, 176
	jr	z, 20
	cp	c, 31
	jr	ugt, 28
	set	7, e
	ld	xix, 0x94b2
	st_rr8b e, xix, c
	jr 13
	ld (37112:16), 255
	ld	(0x8ee2:16), e
	call	Audio_WriteBankSelectParams
	ret
	calr	1320
	ret
	cp	c, 176
	jr	nz, 9
	set	7, e
	ld	(0x94f2:16), e
	jr	18
	cp	b, 31
	jr	ugt, 13
	set	7, e
	ld	xix, 0x9432
	st_rr8b e, xix, b
	ret
	calr 1283
	ret
	cp	b, 31
	jr	ugt, -10
	set	7, e
	ld	xix, 0x9472
	sll	b, 1
	st_rr8w de, xix, b
	ret
	calr	1257
	ret
	cp	b, 31
	jr	ugt, -36
	set	7, e
	ld	xix, 0x9452
	.byte 0xf3
	pop	sr
	.byte 0xf0, 0xe5
	ld	xiy, 0x04d21e0e
	ret
	ld	(0x90f8:16), 255
	ld	bc, (0x9644:16)
	ld	de, (0x9646:16)
	call	MIDI_WriteVoiceParamCC
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ret
	calr	1208
	ret
	ld	(0x90f8:16), 255
	ld	wa, (0x9644:16)
	ld	(0x9127:16), wa
	ld	wa, (0x9646:16)
	ld	(0x9129:16), wa
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ret
	calr	1178
	ret
	ld	(0x90f8:16), 255
	ld	wa, (0x9644:16)
	ld	(0x9127:16), wa
	ld	wa, (0x9646:16)
	ld	(0x9129:16), wa
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ret
	calr	1148
	ret
	ld	bc, (0x9644:16)
	ld	de, (0x9646:16)
	ld	(0x90f8:16), 255
	ld	(0x9127:16), bc
	ld	(0x9129:16), de
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ldb	e, 177
	ld	d, (0x9645:16)
	ldw	wa, 0x4000
	call	SwbtWr_QueuePostEvent
	ldb	e, 180
	ld	d, (0x9645:16)
	ldw	wa, 0x7f00
	call	SwbtWr_QueuePostEvent
	ldb	e, 178
	ld	d, (0x9645:16)
	ldw	wa, 0x7f00
	call	SwbtWr_QueuePostEvent
	ldb	e, 179
	ld	d, (0x9645:16)
	ldw	wa, 0x7f7f
	call	SwbtWr_QueuePostEvent
	ld	c, (0x9645:16)
	ldb	b, 4
	ldw	de, 2048
	call	MIDI_WriteVoiceParamDirect
	ld	de, (0x9127:16)
	ld	wa, (0x9129:16)
	call	SwbtWr_QueuePostEvent
	ld	(0x912a:16), 0
	xor	h, h
	ld	l, (0x9645:16)
	sla	hl, 1
	ld	xix, 0x9674
	.byte 0xf3
	reti
	stiw_d8 236, 127, 127
	ret
	calr	1015
	ret
	ld	bc, (0x9644:16)
	ld	de, (0x9646:16)
	ld	(0x90f8:16), 255
	ld	(0x9127:16), bc
	ld	(0x9129:16), de
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ret
	calr	985
	ret
	ld	(0x90f8:16), 255
	ld	bc, (0x9644:16)
	ld	de, (0x9646:16)
	call	MIDI_WriteVoiceParamCC
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ret
	calr	959
	ret

MidiStream_LoadAllPresets:
	ld xiy, 0x9432
	ldb w, 0xb3
	calr MidiStream_LoadVoicePreset
	calr MidiStream_LoadBankSelect
	ld xiy, 0x9452
	ldb w, 0xb2
	calr MidiStream_LoadVoicePreset
	calr MidiStream_LoadMultiPartPreset
	calr MidiStream_LoadPedalPreset
	ret

MidiStream_LoadVoicePreset:
	xor hl, hl

MidiStream_LoadVoiceLoop:
	ldb_sri A, 0x07, 0xf4, 0xec
	bit 7, a
	jr z, MidiStream_LoadVoiceNext
	res 7, a
	stb_dri A, 0x07, 0xf4, 0xec
	ld (0x90f8:16), 255
	ld (0x9127:16), w
	ld (0x9128:16), l
	ld (0x9129:16), a
	ld (0x912a:16), 127
	call SwbtWr_WriteVoiceParam_PreserveRegs

MidiStream_LoadVoiceNext:
	inc 1, hl
	cp l, 0x1f
	jr ule, MidiStream_LoadVoiceLoop
	ret

MidiStream_LoadBankSelect:
	ld xiy, 0x94f2
	ld a, (xiy)
	bit 7, a
	jr z, MidiStream_LoadBankDone
	res 7, a
	ld (xiy), a
	ld (0x8ee0:16), a
	call Audio_WriteBankSelectParams
	ld (0x90f8:16), 255
	ld (0x9127:16), 176
	ld (0x9128:16), 1
	ld (0x9129:16), a
	ld (0x912a:16), 127
	call SwbtWr_WriteVoiceParam_PreserveRegs

MidiStream_LoadBankDone:
	ret

MidiStream_LoadMultiPartPreset:
	ld xiy, 0x9472
	xor hl, hl
	xor bc, bc

MidiStream_LoadMultiLoop:
	ldw_sri WA, 0x07, 0xf4, 0xec
	bit 7, a
	jr z, MidiStream_LoadMultiNext
	res 7, a
	stw_dri WA, 0x07, 0xf4, 0xec
	ld (0x90f8:16), 255
	ldb c, 0xb1
	ld (0x9127:16), bc
	ld (0x9129:16), wa
	call SwbtWr_WriteParamBlockSafe

MidiStream_LoadMultiNext:
	inc 1, b
	inc 2, hl
	cp b, 0x1f
	jr ule, MidiStream_LoadMultiLoop
	ret

MidiStream_LoadPedalPreset:
	ld xiy, 0x94b2
	xor hl, hl

MidiStream_LoadPedalLoop:
	ldb_sri A, 0x07, 0xf4, 0xec
	bit 7, a
	jr z, MidiStream_LoadPedalNext
	res 7, a
	stb_dri A, 0x07, 0xf4, 0xec
	ld (0x90f8:16), 255
	ld c, l
	ldb b, 0x3
	ld e, a
	ldb d, 0x7f
	call MIDI_WriteVoiceParamCC
	call SwbtWr_WriteVoiceParam_PreserveRegs

MidiStream_LoadPedalNext:
	inc 1, hl
	cp l, 0x1f
	jr ule, MidiStream_LoadPedalLoop
	ret

MidiStream_ProcessRxBuffer:
	bit 0, (0xb7e7:16)
	jr nz, MidiStream_ProcessDone
	bit 4, (0xfd50:16)
	jr nz, MidiStream_ProcessDone
	ldw (0x9133:16), 0

MidiStream_DispatchLoop:
	ld xix, 0xc039
	ld hl, (0x9133:16)
	ldb_sri A, 0x07, 0xf0, 0xec
	cp a, 0xff
	jr z, MidiStream_ProcessDone
	cp a, 0xbf
	jr ugt, MidiStream_AdvanceRxPtr
	extz wa
	sll wa, 2
	ld xiy, MidiStream_HandleRunningStatus_0x98
	ld_sril3 XIY, 0x07, 0xf4, 0xe0
	cp xiy, 0xffffffff
	jr z, MidiStream_AdvanceRxPtr
	ldw_sri BC, 0x07, 0xf0, 0xec
	inc 2, hl
	ld (0x915b:16), bc
	ldw_sri DE, 0x07, 0xf0, 0xec
	ld (0x915d:16), de
	call (xiy)

MidiStream_AdvanceRxPtr:
	inc 4, (0x9133:16)
	jr MidiStream_DispatchLoop

MidiStream_ProcessDone:
	ret

MidiStream_StatusPrecheck:
	extz	hl
	ld	l, b
	cp	l, 11
	jr	ugt, 63
	sll	hl, 2
	ld	xix, MidiStream_StatusJumpTable
	ld_rrl	xix, xix, hl
	jp	(xix)


MidiStream_StatusJumpTable:
	.long MidiStream_HandleRunningStatus
	.long MidiStream_HandleNoteCC
	.long MidiStream_HandleNoteCC
	.long MidiStream_HandlePgmChange
	.long MidiStream_HandleChanPressure
	.long MidiStream_HandleSysMsg
	.long MidiStream_HandleSysMsg
	.long MidiStream_HandleSysMsg
	.long MidiStream_HandleSysMsg
	.long MidiStream_HandleSysMsg
	.long MidiStream_HandleSysMsg
	.long MidiStream_HandleSysMsg
MidiStream_HandleNoteCC:
	ret
	; --- Indexed dispatch: table lookup, conditional call paths (76 bytes) ---
	cp c, 0x48
	jr z, MidiStream_HandleNoteCC_Ret
	extz	hl
	ld l, c
	sll	hl, 2
	ld	xix, (0x90f2:16)
	ld_rrl	xix, xix, hl
	ld wa, (xix)
	ld	(0x90ea:16), wa
	pushw wa
	ld	(0x90ec:16), c
	call RegBitManip_Handler_4_0x8
	popw wa
	pushw hl
	call MIDI_ParamValidate_CheckBit2
	or	hl, hl
	popw hl
	jr nz, MidiStream_PostNoteCC
	ld b, c
	ldb c, 0x81
	ld	de, (0x90ee:16)
	call MIDI_ClearGuardAndDispatchCC
MidiStream_PostNoteCC:
	ld	c, (0x915b:16)
	xor b, b
	ld	e, (0x90f0:16)
	ldb d, 0xff
	call MIDI_ClearGuardAndDispatchCC
MidiStream_HandleNoteCC_Ret:
	ret


MidiStream_HandlePgmChange:
	ld	a, d
	and	a, 127
	jr	z, 32
	extz	hl
	ld	l, c
	sll	hl, 2
	ld	xix, (0x90f2:16)
	ld_rrl xix, xix, hl
	ld l, b
	ld_rr8b e, xix, l
	and e, 127
	ldb	d, 127
	call	MIDI_ClearGuardAndDispatchCC
	ret
MidiStream_HandleChanPressure:
	and	de, 0x4848
	and	e, d
	bit	3, d
	jr	z, 9
	.byte 0xf1
	swi	1
	and	(xwa), bc
	jr	z, 3
	or	e, 8
	ld	a, e
	and	e, 72
	jr	z, 30
	extz	hl
	ld	l, c
	sll	hl, 2
	ld	xix, (0x90f2:16)
	ld_rrl xix, xix, hl
	ld l, b
	ld_rr8b e, xix, l
	and d, 72
	call	MIDI_ClearGuardAndDispatchCC
	ret
MidiStream_HandleSysMsg:
	cp	d, 0:i3
	jr	z, 27
	extz	hl
	ld	l, c
	sll	hl, 2
	ld	xix, (0x90f2:16)
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 202
	.byte 0x8f, 0xc3
	pop	sr
	.byte 0xf0, 0xec
	ldb	e, 29
	swi	6
	cp	(xbc), xix
	ret
	extz	hl
	ld	l, b
	cp	l, 3:i3
	jr	ugt, 31
	sll	hl, 2
	ld	xix, MidiStream_SysExJumpTable
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 180
	.byte 0xd8


MidiStream_SysExJumpTable:
	.long MidiStream_HandleRunningStatus
	.long MidiStream_SysExNop
	.long MidiStream_SysExNop
	.long MidiStream_SysExData
MidiStream_SysExNop:
	ret
MidiStream_SysExData:
	.byte 0xc1
	ldw	ix, 0x3f8d
	ret
	jr	z, 18
	and	d, 7
	jr	z, 13
	ld	e, (0xfc5d:16)
	and	e, 7
	ldb	d, 7
	call	MIDI_ClearGuardAndDispatchCC
	ret
	extz	hl
	ld	l, b
	cp	l, 1:i3
	jr	ugt, 23
	sll	hl, 2
	ld	xix, MidiStream_CtrlJumpTable
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 180
	.byte 0xd8
MidiStream_CtrlJumpTable:
	.long MidiStream_CtrlNop
	.long MidiStream_CtrlData
MidiStream_CtrlNop:
	ret
MidiStream_CtrlData:
	bit	7, d
	jr	z, 18
	bit	7, e
	jr	z, 13
	ld	e, (0xfc6f:16)
	and	e, 128
	ldb	d, 128
	call	MIDI_ClearGuardAndDispatchCC
	ret
	extz	hl
	ld	l, b
	cp	l, 11
	jr	ugt, 63
	sll	hl, 2
	ld	xix, MidiStream_CmdJumpTable
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 180
	.byte 0xd8
MidiStream_CmdJumpTable:
	.long MidiStream_CmdNop
	.long MidiStream_CmdPedalNotify
	.long MidiStream_CmdNop
	.long MidiStream_CmdNop
	.long MidiStream_CmdNop
	.long MidiStream_CmdNop
	.long MidiStream_CmdNop
	.long MidiStream_CmdNop
	.long MidiStream_CmdNop
	.long MidiStream_CmdNop
	.long MidiStream_CmdNop
	.long MidiStream_CmdMaskedNotify
MidiStream_CmdNop:
	ret
MidiStream_CmdMaskedNotify:
	; --- Routine 1: D/E bit masking, call FCA1FE (23 bytes) ---
	and d, 0xc0
	jr z, MidiStream_CmdMaskedDone
	and e, d
	jr z, MidiStream_CmdMaskedDone
	ld	e, (0xfda1:16)
	and e, 0xc0
	ldb d, 0xc0
	call MIDI_ClearGuardAndDispatchCC
MidiStream_CmdMaskedDone:
	ret
MidiStream_CmdPedalNotify:
	; --- Routine 2: conditional E/D setup, dec E, call FCA1FE (36 bytes) ---
	cp	(0x8d34:16), 14
	jr z, MidiStream_CmdPedalDone
	bit	3, (0xfd50:16)
	jr z, MidiStream_CmdPedalDone
	and e, 0x7f
	jr z, MidiStream_CmdPedalDone
	lds	bc, 0
	ld	e, (0xfd97:16)
	and e, 0x7f
	dec 1, e
	ldb d, 0x7f
	call MIDI_ClearGuardAndDispatchCC
MidiStream_CmdPedalDone:
	ret


MidiStream_HandlePartSelect:
	cp a, 0x48
	jr z, MidiStream_PartSelectDone
	and w, 0xf
	or w, 0x80
	pushw wa
	ld wa, (xsp)
	ld (0x90e5:16), w
	ld c, a
	ldb b, 0x4
	ldw de, 0x800
	call MIDI_DispatchCC_Guarded
	ld wa, (xsp)
	ld (0x90e5:16), w
	ldb c, 0xb1
	ld b, a
	ldw de, 0x4000
	call MIDI_DispatchCC_Guarded
	ld wa, (xsp)
	ld (0x90e5:16), w
	ldb c, 0xb2
	ld b, a
	ldw de, 0x7f00
	call MIDI_DispatchCC_Guarded
	ld wa, (xsp)
	ld (0x90e5:16), w
	ldb c, 0xb4
	ld b, a
	ldw de, 0x7f00
	call MIDI_DispatchCC_Guarded
	inc 2, xsp

MidiStream_PartSelectDone:
	ret

MidiStream_ExtendedDispatch:
	ret
	.byte 0xc1
	ld	xix, 0x6e143f96
	reti
	ld	(0x9644:16), 72
	ldb	c, 72
	.byte 0xc1
	ldw	ix, 0x3f8d
	ret
	jr	z, 7
	.byte 0xc1
	ldw	ix, 0x3f8d
	scf
	jr	nz, 5
	cp	c, 72
	jr	z, 49
	ld	(0x90f8:16), 255
	cp	c, 0:i3
	jr	nz, 45
	.byte 0xf1, 0x50
	swi	5
	inc	6, c
	ldb	l, 193
	ldw	ix, 0x3f8d
	ret
	jr	z, 27
	.byte 0xc1
	ldw	ix, 0x3f8d
	scf
	jr	z, 20
	cp	e, 80
	jr	nc, 15
	inc	1, e
	ldw	bc, 408
	ldb	d, 127
	call	MIDI_WriteVoiceParamCC
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ret
	calr	65449
	ret
	ld	l, (0xfd50:16)
	and	l, 3
	sla	l, 2
	ld	xix, MidiStream_ExtendedDispatch_0x73
	ld_rr8l xix, xix, l
	call (xix)
	ret
	calr	65422
	ret
	cp	(xsp-53), ix
	nop
	ccf
	.byte 0xcc
	swi	4
	nop
	cp	(xde-53), d
	nop
	pop	xiz
	.byte 0xcc
	swi	4
	nop
	ld	bc, (0x9644:16)
	ld	de, (0x9646:16)
	ld	(0x90f6:16), c
	xor	h, h
	ld	l, c
	sll	hl, 2
	ld	xix, (0x90f2:16)
	ld_rrl xix, xix, hl
	cp xix, 4294967295
	jr	z, 78
	ldb	a, 17
	cp	c, 72
	jr	nz, 2
	ldb	a, 15
	cp	e, a
	jr	ugt, 65
	cp	c, 72
	jr	nz, 10
	ld	l, e
	call	AccVoice_GetChannelCount_Direct
	ld	a, l
	jr	10
	ld	a, e
	pushw	bc
	ld	b, c
	call	RegBitManip_Handler_4_0x1B
	popw	bc
	extz	hl
	ld	l, c
	cp	c, 72
	jr	nz, 2
	ldb	l, 20
	ld	xiy, 0x9412
	ld_rrb h, xiy, hl
	cp h, a
	jr	ugt, 15
	ld	l, e
	call	SndParam_ApplyProgramChange_Safe
	ld	b, h
	ld	e, l
	ldb	d, 255
	calr	162
	ret
	ld	bc, (0x9644:16)
	ld	de, (0x9646:16)
	ld	(0x90f7:16), c
	extz	hl
	ld	l, c
	sll	hl, 2
	ld	xix, (0x90f2:16)
	ld_rrl xix, xix, hl
	cp xix, 4294967295
	jr	z, 39
	extz	hl
	ld	l, c
	cp	c, 72
	jr	nz, 2
	ldb	l, 20
	ld	xiy, 0x9412
	ld_rrb d, xiy, hl
	bit 7, d
	jr z, 6
	res	7, d
	set	7, e
	ld	b, d
	ldb	d, 255
	calr	86
	ret
	ld	bc, (0x9644:16)
	cp	c, 72
	jr	z, 75
	ld	de, (0x9646:16)
	extz	hl
	ld	l, c
	sll	hl, 2
	ld	xix, (0x90f2:16)
	ld_rrl xix, xix, hl
	cp xix, 4294967295
	jr	z, 47
	extz	hl
	ld	l, c
	ld	d, c
	sll	hl, 1
	ld	xiy, 0x93d2
	ld_rrw wa, xiy, hl
	ld (37098:16), wa
	ld	(0x90ec:16), de
	call	RegBitManip_Handler_4_0x30
	ld	de, (0x90ee:16)
	ld	c, (0x9644:16)
	ld	b, d
	ldb	d, 255
	call	MidiStream_ExtendedDispatch_0x197
	ret
	push	xix
	pushw	hl
	pushw	bc
	pushw	de
	.byte 0xf1
	swi	2
	.byte 0x90, 0xb8
	calr	105
	.byte 0xf1
	swi	2
	and	(xwa), bc
	jr	nz, 94
	ld	(0x90f7:16), c
	xor	h, h
	ld	l, c
	sll	hl, 2
	ld	xix, (0x90f2:16)
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 180
	ld	xiy, 0x803c018c
	or	(xix+1), b
	ld	h, b
	ld	l, e
	call	PartCtrl_WriteProgramChange
	call	MIDI_SetupChannelParams
	ld	a, c
	ldb	w, 1
	ld	(0x9127:16), wa
	ld	a, b
	ldb	w, 127
	ld	(0x9129:16), wa
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ld	a, c
	ldb	w, 0
	ld	(0x9127:16), wa
	ld	a, e
	ldb	w, 255
	ld	(0x9129:16), wa
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	cp	c, 72
	jr	z, 8
	ld	d, b
	ldb	b, 0
	call	SndParam_UpdateVoiceEntry_Safe
	popw	de
	popw	bc
	popw	hl
	pop	xix
	ret
	push	xix
	pushw	hl
	pushw	bc
	pushw	de
	.byte 0xc1
	swi	2
	.byte 0x90
	push	xix
	swi	5
	.byte 0xf1
	swi	2
	and	(xwa), wa
	jr	z, 38
	.byte 0xc1
	swi	2
	.byte 0x90
	push	xix
	swi	6
	ld	(0x90f7:16), c
	ld	l, e
	ld	h, b
	ld	xix, RegBitManip_Handler_4_0x43
	ld	e, (0xfd50:16)
	and	e, 3
	cp	e, 1:i3
	jr	z, 5
	ld	xix, PartCtrl_WriteProgramChange
	call	(xix)
	ld	e, l
	cp	c, 15
	jr	z, 43
	cp	c, 20
	jr	z, 38
	cp	c, 16
	jr	z, 25
	cp	c, 17
	jr	z, 20
	cp	c, 18
	jr	z, 15
	cp	c, 19
	jr	z, 10
	cp	c, 21
	jr	z, 5
	cp	c, 22
	jr	nz, 34
	call	MidiStream_ExtendedDispatch_0x28F
	jr	c, 24
	jr	11
	call	MidiStream_ExtendedDispatch_0x28F
	jr	nc, 16
	cp	c, 15
	jr	z, 15
	push_a
	ld	a, (0x379b:16)
	and	a, 31
	pop_a
	jr	nz, 4
	.byte 0xf1
	swi	2
	sbc	(xwa), bc
	popw	de
	popw	bc
	popw	hl
	pop	xix
	ret
	cp	e, 15
	jr	nz, 2
	scf
	ret
	rcf
	ret
	.byte 0xc1
	ld	xix, 0x6e483f96
	decf
	ld	(0x9644:16), 20
	.byte 0xc1
	ldw	ix, 0x3f8d
	ret
	jrl	z, 156
	ld	bc, (0x9644:16)
	ld	de, (0x9646:16)
	ld	xix, 0x93d2
	ld	xiz, 0x9412
	extz	hl
	ld	l, c
	sll	hl, 1
	cp	e, 255
	jr	z, 10
	res	7, e
	st_rrb e, xix, hl
	jr 12
	res 7, d
	inc	1, xix
	st_rrb d, xix, hl
	dec 1, xix
	ld_rrw wa, xix, hl
	and wa, 32639
	st_rrw wa, xix, hl
	srl	hl, 1
	ld	b, (0xfd50:16)
	and	b, 3
	sll	b, 2
	ld	xiy, MidiStream_ExtendedDispatch_0x307
	ld_rr8l xiy, xiy, b
	jp (xiy)
	ldw	hl, 0xfcce
	nop
	ldw	iy, 0xfcce
	nop
	ldw	hl, 0xfcce
	nop
	pop	xix
	.byte 0xce
	swi	4
	nop
	jr	42
	bit	0, w
	jr	z, 26
	srl	a, 4
	and	a, 15
	cp	c, 20
	jr	z, 10
	cp	a, 2:i3
	jr	c, 6
	cp	a, 6:i3
	jr	nc, 2
	xor	a, a
	set	7, a
	jr	11
	srl	a, 4
	and	a, 15
	jr	3
	srl	wa, 8
	st_rrb a, xiz, hl
	ret
	calr 64692
	ret
MidiStream_HandleRunningStatus:
	.byte 0xf1, 0x50
	swi	5
	inc	6, c
	.byte 0x04
	cp	c, 0:i3
	jr	z, 22
	ld	l, (0xfd50:16)
	and	l, 3
	sll	hl, 2
	ld	xix, MidiStream_HandleRunningStatus_0x21
	.byte 0xe3
	pop	sr
	.byte 0xf0, 0xec
	ldb	d, 180
	.byte 0xd8
	ret
	cp	(xde-50), ix
	nop
	.byte 0xb8, 0xce
	swi	4
	nop
	cp	(xbc-50), d
	nop
	swi	5
	.byte 0xc8
	swi	4
	nop
	cp	c, 72
	jr	nz, 2
	ldb	c, 20
	pushw	bc
	pushw	de
	ld	e, d
	xor	d, d
	ld	b, c
	ldb	c, 129
	call	MIDI_ClearGuardAndDispatchCC
	popw	de
	popw	bc
	ldb	d, 255
	call	MIDI_ClearGuardAndDispatchCC
	ret
	cp	c, 72
	jr	nz, 2
	ldb	c, 20
	extz	hl
	ld	l, (0x915b:16)
	sll	hl, 2
	ld	xix, (0x90f2:16)
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	d, 236
	.byte 0xcf
	swi	7
	swi	7
	swi	7
	swi	7
	jr	z, 38
	ld	e, (xix)
	pushw	bc
	pushw	de
	xor	d, d
	bit	7, e
	jr	z, 2
	ldb	d, 1
	ld	e, (xix+1)
	sll	e, 4
	ld	b, c
	ldb	c, 129
	call	MIDI_ClearGuardAndDispatchCC
	popw	de
	popw	bc
	res	7, e
	ldb	d, 255
	call	MIDI_ClearGuardAndDispatchCC
	ret
	swi	7
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	.byte 0xb4, 0xc8
	swi	4
	nop
	swi	7
	swi	7
	swi	7
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
