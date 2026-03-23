; =============================================================================
; Scoop Editor & Display Parameter Data (1.2K lines)
; =============================================================================
;
; Sound editor display data, performance mode parameter
; bytecode, Scoop oscilloscope editor configuration tables,
; and display dirty-region data.
; =============================================================================



Scoop_SoundEditorData:
	jp	15776446
	jp	15777036
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	call	15783834
	lds	wa, 1
	call	AudioLock_GetCount
	cps	hl, 0
	jr	z, 8
	lds	wa, 3
	call	TaskSched_YieldToQueue
	jr	-18
	lds32	xwa, 0
	ld	xbc, 29360135
	jp	DeleteEvent
	jp	15777037
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	15758131
	cp	hl, 65535
	jr	z, 25
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda_24	xde, 14736566
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	15758131
	cp	hl, 65535
	jr	z, 25
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda_24	xde, 14736638
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	15758131
	cp	hl, 65535
	jr	z, 25
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda_24	xde, 14736710
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	15758131
	cp	hl, 65535
	jr	z, 25
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda_24	xde, 14736782
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	15758131
	cp	hl, 65535
	jr	z, 25
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda_24	xde, 14736854
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	inc	4, xsp
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+18), a
	lda	xwa, (xsp+14)
	call	SeMenu_LoadObjEntries
	lda	xwa, (xsp+16)
	call	SeMenu_ValidatePartNumber
	ld	a, (xsp+16)
	ld	(xsp), a
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xsp+12)
	call	15758524
	lda	xhl, (xsp+2)
	lda	xwa, (xhl+6)
	lda	xbc, (xhl+7)
	lda	xde, (xhl+8)
	lda	xhl, (xhl+9)
	.byte 0x8f
	ret
	push	xsp
	nop
	jr	nz, 16
	ld	(xwa), 127
	ld	(xbc), 0
	ld	(xde), 127
	ld	(xhl), 0
	ldb	a, 23
	jr	34
	ld	(xwa), 255
	ld	(xbc), 0
	ld	(xde), 50
	ld	(xhl), 206
	ld	a, (xsp+16)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	inc	6, xwa
	ld	(xsp+16), 0
	ld	c, (xsp)
	extz	bc
	ld	e, (xsp+16)
	extz	de
	extz	wa
	pushw	wa
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 43
	call	15757111
	.byte 0x8f
	ret
	push	xsp
	nop
	jr	nz, 18
	cps	l, 1
	jr	nz, 14
	ld	a, (xsp+16)
	extz	wa
	ld	c, (xsp+5)
	extz	bc
	call	SeMenu_StoreParamByte
	lds	wa, 3
	call	15758489
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-18)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+18), a
	lda	xwa, (xsp+14)
	call	SeMenu_LoadObjEntries
	lda	xwa, (xsp+16)
	call	SeMenu_ValidatePartNumber
	.byte 0x8f
	ret
	push	xsp
	nop
	jr	nz, 10
	ld	a, (xsp+16)
	inc	4, a
	.byte 0xc7
	swi	3
	.byte 0x99
	jr	8
	ld	a, (xsp+16)
	inc	2, a
	.byte 0xc7
	swi	3
	cp	(xbc-57), hl
	.byte 0x89
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xsp+12)
	call	15758524
	lda	xhl, (xsp+2)
	lda	xwa, (xhl+6)
	lda	xbc, (xhl+7)
	lda	xde, (xhl+8)
	lda	xhl, (xhl+9)
	.byte 0x8f
	ret
	push	xsp
	nop
	jr	nz, 16
	ld	(xwa), 255
	ld	(xbc), 0
	ld	(xde), 50
	ld	(xhl), 206
	ldb	a, 24
	jr	34
	ld	(xwa), 7
	ld	(xbc), 5
	ld	(xde), 6
	ld	(xhl), 0
	ld	a, (xsp+16)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	inc	7, xwa
	ld	(xsp+16), 0
	.byte 0xc7
	swi	3
	.byte 0x8b
	extz	bc
	ld	e, (xsp+16)
	extz	de
	extz	wa
	pushw	wa
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 43
	call	15757111
	lds	wa, 4
	call	15758489
	.byte 0xd7
	swi	2
	halt
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-18)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+18), a
	lda	xwa, (xsp+14)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	ret
	push	xsp
	.byte 0x01
	jr	z, 85
	lda	xwa, (xsp+16)
	call	SeMenu_ValidatePartNumber
	ld	a, (xsp+16)
	inc	8, a
	.byte 0xc7
	swi	3
	.byte 0x99
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+2)
	ld	(xbc+6), 7
	ld	(xbc+7), 5
	ld	(xbc+8), 6
	ld	(xbc+9), 0
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758524
	.byte 0xc7
	swi	3
	.byte 0x8b
	extz	bc
	ld	e, (xsp+16)
	extz	de
	pushw	25
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 43
	call	15757111
	lds	wa, 5
	call	15758489
	.byte 0xd7
	swi	2
	halt
	lda	xsp, (xsp+18)
	ret
	cps	a, 0
	.byte 0xf2, 0x01
	jr	pl, -16
	.byte 0xde
	ldw	wa, 45
	lds	bc, 0
	jp	SeMenu_SendEvent
	cps	a, 0
	ret	z
	ldw	wa, 43
	lds	bc, 1
	lds	de, 1
	call	15765037
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	nz, 16
	.byte 0x87
	push	xsp
	.byte 0x01
	jr	z, 22
	ldw	wa, 47
	lds	bc, 0
	call	SeMenu_SendEvent
	jr	11
	ldw	wa, 43
	lds	bc, 2
	lds	de, 1
	call	15765037
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x87
	push	xsp
	.byte 0x01
	jr	z, 17
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	z, 11
	ldw	wa, 43
	lds	bc, 3
	lds	de, 1
	call	15765037
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x87
	push	xsp
	.byte 0x01
	jr	z, 17
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	z, 11
	ldw	wa, 43
	lds	bc, 4
	lds	de, 1
	call	15765037
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x87
	push	xsp
	.byte 0x01
	jr	z, 15
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	nz, 9
	ldw	wa, 44
	lds	bc, 0
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lds	wa, 0
	call	SeMenu_SetupMenuDisplay
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	nz, 21
	.byte 0x87
	push	xsp
	nop
	jr	nz, 7
	ldw	wa, 32
	lds	bc, 0
	jr	5
	ldw	wa, 61
	lds	bc, 0
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	lda	xsp, (xsp-18)
	ld	(xsp+16), a
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	lds	wa, 3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758524
	ld	e, (xsp+14)
	extz	de
	pushw	29
	.byte 0xbf
	push_sr
	.asciz "080,"
	lds	bc, 3
	call	15757111
	cps	l, 1
	jr	nz, 29
	lda	xbc, (xsp+12)
	lds	wa, 3
	call	SeMenu_LoadPartParam
	ld	c, (xsp+12)
	extz	bc
	ldw	wa, 10
	call	SeMenu_StorePartParam
	lds	wa, 0
	lds	bc, 0
	call	15764042
	lds	wa, 3
	call	15758489
	lda	xsp, (xsp+18)
	ret
	dec	8, xsp
	ld	(xsp+6), a
	lda	xbc, (xsp+2)
	lds	wa, 0
	call	SeMenu_LoadPartParam
	ld	a, (xsp+6)
	extz	wa
	ld	c, (xsp+2)
	dec	1, c
	extz	bc
	pushw	bc
	lds	bc, 1
	lds	de, 0
	call	15767527
	cps	l, 1
	jr	nz, 52
	lda	xwa, (xsp+4)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	lds	wa, 1
	call	SeMenu_LoadPartParam
	ld	a, (xsp+4)
	extz	wa
	lda	xde, (xsp)
	pushw	127
	ldw	bc, 27
	call	SeMenu_RegisterElement_Extended
	pushw	1
	pushw	44
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	lds	wa, 0
	lds	bc, 0
	call	15764042
	lds	wa, 4
	call	15758489
	inc	8, xsp
	ret
	lda	xsp, (xsp-10)
	ld	(xsp+8), a
	lda	xbc, (xsp+4)
	lds	wa, 1
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+2)
	lds	wa, 2
	call	SeMenu_LoadPartParam
	ld	a, (xsp+8)
	extz	wa
	ld	e, (xsp+4)
	inc	1, e
	extz	de
	ld	c, (xsp+2)
	dec	1, c
	extz	bc
	pushw	bc
	lds	bc, 0
	call	15767527
	cps	l, 1
	jr	nz, 52
	lda	xwa, (xsp+6)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	lds	wa, 0
	call	SeMenu_LoadPartParam
	ld	a, (xsp+6)
	extz	wa
	lda	xde, (xsp)
	pushw	127
	ldw	bc, 26
	call	SeMenu_RegisterElement_Extended
	pushw	0
	pushw	44
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	lds	wa, 0
	lds	bc, 0
	call	15764042
	lds	wa, 5
	call	15758489
	lda	xsp, (xsp+10)
	ret
	dec	8, xsp
	ld	(xsp+6), a
	lda	xbc, (xsp+2)
	lds	wa, 0
	call	SeMenu_LoadPartParam
	ld	a, (xsp+6)
	extz	wa
	ld	e, (xsp+2)
	inc	1, e
	extz	de
	pushw	127
	lds	bc, 2
	call	15767527
	cps	l, 1
	jr	nz, 52
	lda	xwa, (xsp+4)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	lds	wa, 2
	call	SeMenu_LoadPartParam
	ld	a, (xsp+4)
	extz	wa
	lda	xde, (xsp)
	pushw	127
	ldw	bc, 28
	call	SeMenu_RegisterElement_Extended
	pushw	2
	pushw	44
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	lds	wa, 0
	lds	bc, 0
	call	15764042
	lds	wa, 6
	call	15758489
	inc	8, xsp
	ret
	cps	a, 0
	.byte 0xf2, 0x01
	jr	pl, -16
	.byte 0xde
	ldw	wa, 45
	lds	bc, 0
	jp	SeMenu_SendEvent
	cps	a, 0
	ret	z
	lds	wa, 1
	call	15757230
	cps	l, 0
	ret	z
	ldw	wa, 44
	lds	bc, 1
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	jr	nz, 7
	ldw	wa, 47
	lds	bc, 0
	jr	15
	lds	wa, 2
	call	15757230
	cps	l, 0
	ret	z
	ldw	wa, 44
	lds	bc, 1
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	ret	z
	lds	wa, 3
	call	15757230
	cps	l, 0
	ret	z
	ldw	wa, 44
	lds	bc, 1
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	ret	z
	lds	wa, 4
	call	15757230
	cps	l, 0
	ret	z
	ldw	wa, 44
	lds	bc, 1
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	ret	z
	ldw	wa, 43
	lds	bc, 0
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	ret	nz
	lds	wa, 0
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	lds	bc, 0
	call	SeMenu_SendEvent
	ret
	lda	xsp, (xsp-18)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+18), a
	lda	xwa, (xsp+16)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+14)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	ret
	push	xsp
	nop
	scc8	nz, a
	.byte 0xc7
	swi	3
	.byte 0x99
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+2)
	ld	(xbc+6), 127
	ld	(xbc+7), 0
	ld	(xbc+8), 100
	ld	(xbc+9), 0
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758524
	.byte 0x8f
	ret
	push	xsp
	nop
	jr	nz, 4
	ldb	a, 39
	jr	22
	ld	a, (xsp+16)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	inc	8, xwa
	ld	(xsp+16), 0
	.byte 0xc7
	swi	3
	.byte 0x8b
	extz	bc
	ld	e, (xsp+16)
	extz	de
	extz	wa
	pushw	wa
	.byte 0xbf, 0x04
	.asciz "080-"
	call	15757111
	call	15761621
	lds	wa, 1
	call	15758489
	.byte 0xd7
	swi	2
	halt
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-18)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+18), a
	lda	xwa, (xsp+16)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+14)
	call	SeMenu_LoadObjEntries
	lda	xhl, (xsp+2)
	lda	xwa, (xhl+6)
	lda	xbc, (xhl+7)
	lda	xde, (xhl+8)
	lda	xhl, (xhl+9)
	.byte 0xc7
	swi	3
	.byte 0xaa, 0x8f
	ret
	push	xsp
	nop
	jr	nz, 3
	.byte 0xc7
	swi	3
	.byte 0xa9
	ld	(xwa), 127
	ld	(xbc), 0
	ld	(xde), 100
	ld	(xhl), 0
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xsp+12)
	call	15758524
	.byte 0x8f
	ret
	push	xsp
	nop
	jr	nz, 4
	ldb	a, 40
	jr	23
	ld	a, (xsp+16)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+9)
	ld	(xsp+16), 0
	.byte 0xc7
	swi	3
	.byte 0x8b
	extz	bc
	ld	e, (xsp+16)
	extz	de
	extz	wa
	pushw	wa
	.byte 0xbf, 0x04
	.asciz "080-"
	call	15757111
	call	15761621
	lds	wa, 2
	call	15758489
	.byte 0xd7
	swi	2
	halt
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-18)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+18), a
	lda	xwa, (xsp+16)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+14)
	call	SeMenu_LoadObjEntries
	lda	xhl, (xsp+2)
	lda	xwa, (xhl+6)
	lda	xbc, (xhl+7)
	lda	xde, (xhl+8)
	lda	xhl, (xhl+9)
	.byte 0xc7
	swi	3
	.byte 0xab, 0x8f
	ret
	push	xsp
	nop
	jr	nz, 3
	.byte 0xc7
	swi	3
	.byte 0xaa
	ld	(xwa), 127
	ld	(xbc), 0
	ld	(xde), 100
	ld	(xhl), 0
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xsp+12)
	call	15758524
	.byte 0x8f
	ret
	push	xsp
	nop
	jr	nz, 4
	ldb	a, 41
	jr	23
	ld	a, (xsp+16)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+10)
	ld	(xsp+16), 0
	.byte 0xc7
	swi	3
	.byte 0x8b
	extz	bc
	ld	e, (xsp+16)
	extz	de
	extz	wa
	pushw	wa
	.byte 0xbf, 0x04
	.asciz "080-"
	call	15757111
	call	15761621
	lds	wa, 3
	call	15758489
	.byte 0xd7
	swi	2
	halt
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-18)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+18), a
	lda	xwa, (xsp+16)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+14)
	call	SeMenu_LoadObjEntries
	lda	xhl, (xsp+2)
	lda	xwa, (xhl+6)
	lda	xbc, (xhl+7)
	lda	xde, (xhl+8)
	lda	xhl, (xhl+9)
	.byte 0xc7
	swi	3
	.byte 0xac, 0x8f
	ret
	push	xsp
	nop
	jr	nz, 3
	.byte 0xc7
	swi	3
	.byte 0xab
	ld	(xwa), 127
	ld	(xbc), 0
	ld	(xde), 100
	ld	(xhl), 0
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xsp+12)
	call	15758524
	.byte 0x8f
	ret
	push	xsp
	nop
	jr	nz, 4
	ldb	a, 42
	jr	23
	ld	a, (xsp+16)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+11)
	ld	(xsp+16), 0
	.byte 0xc7
	swi	3
	.byte 0x8b
	extz	bc
	ld	e, (xsp+16)
	extz	de
	extz	wa
	pushw	wa
	.byte 0xbf, 0x04
	.asciz "080-"
	call	15757111
	call	15761621
	lds	wa, 4
	call	15758489
	.byte 0xd7
	swi	2
	halt
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-20)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+20), a
	lda	xwa, (xsp+18)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+16)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	rcf
	push	xsp
	nop
	jr	nz, 20
	.byte 0xc7
	swi	3
	.byte 0xac
	lda	xwa, (xsp+2)
	ld	(xwa+6), 127
	ld	(xwa+7), 0
	ld	(xwa+8), 100
	jr	32
	lda	xbc, (xsp+14)
	lds	wa, 0
	call	SeMenu_LoadPartParam
	.byte 0xbf
	ret
	inc	6, e
	jrl	lt, -1081
	.byte 0xad
	lda	xwa, (xsp+2)
	ld	(xwa+6), 127
	ld	(xwa+7), 0
	ld	(xwa+8), 100
	ld	(xwa+9), 0
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	ld	a, (xsp+20)
	extz	wa
	lda	xbc, (xsp+12)
	call	15758524
	.byte 0x8f
	rcf
	push	xsp
	nop
	jr	nz, 4
	ldb	a, 43
	jr	23
	ld	a, (xsp+18)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+12)
	ld	(xsp+18), 0
	.byte 0xc7
	swi	3
	.byte 0x8b
	extz	bc
	ld	e, (xsp+18)
	extz	de
	extz	wa
	pushw	wa
	.byte 0xbf, 0x04
	.asciz "080-"
	call	15757111
	call	15761621
	lds	wa, 5
	call	15758489
	.byte 0xd7
	swi	2
	halt
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-20)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+20), a
	lda	xwa, (xsp+18)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+16)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	rcf
	push	xsp
	nop
	jr	nz, 20
	.byte 0xc7
	swi	3
	.byte 0xad
	lda	xwa, (xsp+2)
	ld	(xwa+6), 127
	ld	(xwa+7), 0
	ld	(xwa+8), 100
	jr	32
	lda	xbc, (xsp+14)
	lds	wa, 0
	call	SeMenu_LoadPartParam
	.byte 0xbf
	ret
	inc	6, e
	jrl	lt, -1081
	.byte 0xae
	lda	xwa, (xsp+2)
	ld	(xwa+6), 127
	ld	(xwa+7), 0
	ld	(xwa+8), 100
	ld	(xwa+9), 0
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	ld	a, (xsp+20)
	extz	wa
	lda	xbc, (xsp+12)
	call	15758524
	.byte 0x8f
	rcf
	push	xsp
	nop
	jr	nz, 4
	ldb	a, 44
	jr	23
	ld	a, (xsp+18)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+13)
	ld	(xsp+18), 0
	.byte 0xc7
	swi	3
	.byte 0x8b
	extz	bc
	ld	e, (xsp+18)
	extz	de
	extz	wa
	pushw	wa
	.byte 0xbf, 0x04
	.asciz "080-"
	call	15757111
	call	15761621
	lds	wa, 6
	call	15758489
	.byte 0xd7
	swi	2
	halt
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-18)
	ld	(xsp+16), a
	lda	xwa, (xsp+12)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	incf
	push	xsp
	.byte 0x01
	jr	z, 76
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	lds	wa, 6
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 127
	ld	(xbc+7), 0
	ld	(xbc+8), 100
	ld	(xbc+9), 0
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758524
	ld	e, (xsp+14)
	extz	de
	pushw	45
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 45
	lds	bc, 6
	call	15757111
	call	15761621
	lds	wa, 7
	call	15758489
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-18)
	ld	(xsp+16), a
	lda	xwa, (xsp+12)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	incf
	push	xsp
	nop
	jr	z, 89
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	lds	wa, 7
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758524
	ld	a, (xsp+14)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+14)
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 45
	lds	bc, 7
	lds	de, 0
	call	15757111
	ldw	wa, 8
	call	15758489
	lda	xsp, (xsp+18)
	ret
	cps	a, 0
	ret	z
	call	15756545
	ret
	cps	a, 0
	jr	nz, 7
	ldw	wa, 43
	lds	bc, 0
	jr	15
	lds	wa, 1
	call	15757230
	cps	l, 0
	ret	z
	ldw	wa, 45
	lds	bc, 1
	call	SeMenu_SendEvent
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	nz, 12
	.byte 0x87
	push	xsp
	nop
	jr	nz, 26
	ldw	wa, 47
	lds	bc, 0
	jr	15
	lds	wa, 2
	call	15757230
	cps	l, 0
	jr	z, 9
	ldw	wa, 45
	lds	bc, 1
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x87
	push	xsp
	.byte 0x01
	jr	z, 25
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	z, 19
	lds	wa, 3
	call	15757230
	cps	l, 0
	jr	z, 9
	ldw	wa, 45
	lds	bc, 1
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp+2)
	call	SeMenu_LoadObjEntries
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	z, 85
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	nz, 21
	lds	wa, 4
	call	15757230
	cps	l, 0
	jr	z, 69
	ldw	wa, 45
	lds	bc, 1
	call	SeMenu_SendEvent
	jr	58
	lda	xbc, (xsp)
	lds	wa, 0
	call	SeMenu_LoadPartParam
	.byte 0xb7
	inc	6, e
	.byte 0x04, 0xb7, 0xb5
	jr	2
	.byte 0xb7, 0xbd
	ld	c, (xsp)
	extz	bc
	lds	wa, 0
	call	SeMenu_StorePartParam
	pushw	0
	pushw	45
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	lda	xde, (xsp)
	pushw	32
	lds	wa, 0
	ldw	bc, 13
	call	SeMenu_SetupDisplayObject_Alt1
	call	15761621
	inc	6, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x87
	push	xsp
	.byte 0x01
	jr	z, 15
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	nz, 9
	ldw	wa, 46
	lds	bc, 0
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lds	wa, 0
	call	SeMenu_SetupMenuDisplay
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	nz, 21
	.byte 0x87
	push	xsp
	nop
	jr	nz, 7
	ldw	wa, 32
	lds	bc, 0
	jr	5
	ldw	wa, 61
	lds	bc, 0
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	lda	xsp, (xsp-18)
	ld	(xsp+16), a
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	lds	wa, 5
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758524
	ld	e, (xsp+14)
	extz	de
	pushw	51
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 46
	lds	bc, 5
	call	15757111
	lda	xbc, (xsp+12)
	lds	wa, 5
	call	SeMenu_LoadPartParam
	ld	c, (xsp+12)
	extz	bc
	ldw	wa, 10
	call	SeMenu_StorePartParam
	lds	wa, 2
	lds	bc, 0
	call	15764042
	lda	xbc, (xsp+12)
	ldw	wa, 9
	call	SeMenu_LoadPartParam
	.byte 0x8f
	incf
	push	xsp
	nop
	jr	z, 21
	ldw	wa, 9
	lds	bc, 0
	call	SeMenu_StorePartParam
	pushw	9
	pushw	46
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	lds	wa, 1
	call	15758489
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-18)
	ld	(xsp+16), a
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	lds	wa, 6
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758524
	ld	e, (xsp+14)
	extz	de
	pushw	52
	.byte 0xbf
	push_sr
	.asciz "080."
	lds	bc, 6
	call	15757111
	lda	xbc, (xsp+12)
	lds	wa, 6
	call	SeMenu_LoadPartParam
	ld	c, (xsp+12)
	extz	bc
	ldw	wa, 10
	call	SeMenu_StorePartParam
	lds	wa, 2
	lds	bc, 0
	call	15764042
	lda	xbc, (xsp+12)
	ldw	wa, 9
	call	SeMenu_LoadPartParam
	.byte 0x8f
	incf
	push	xsp
	.byte 0x01
	jr	z, 21
	ldw	wa, 9
	lds	bc, 1
	call	SeMenu_StorePartParam
	pushw	9
	pushw	46
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	lds	wa, 2
	call	15758489
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-18)
	ld	(xsp+16), a
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	lds	wa, 7
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758524
	ld	e, (xsp+14)
	extz	de
	pushw	53
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 46
	lds	bc, 7
	call	15757111
	lda	xbc, (xsp+12)
	lds	wa, 7
	call	SeMenu_LoadPartParam
	ld	c, (xsp+12)
	extz	bc
	ldw	wa, 10
	call	SeMenu_StorePartParam
	lds	wa, 2
	lds	bc, 0
	call	15764042
	lda	xbc, (xsp+12)
	ldw	wa, 9
	call	SeMenu_LoadPartParam
	.byte 0x8f
	incf
	push	xsp
	push_sr
	jr	z, 21
	ldw	wa, 9
	lds	bc, 2
	call	SeMenu_StorePartParam
	pushw	9
	pushw	46
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	lds	wa, 3
	call	15758489
	lda	xsp, (xsp+18)
	ret
	dec	8, xsp
	ld	(xsp+6), a
	lda	xbc, (xsp+2)
	lds	wa, 2
	call	SeMenu_LoadPartParam
	ld	a, (xsp+6)
	extz	wa
	ld	c, (xsp+2)
	dec	1, c
	extz	bc
	pushw	bc
	lds	bc, 3
	lds	de, 0
	call	15767527
	cps	l, 1
	jr	nz, 52
	lda	xwa, (xsp+4)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	lds	wa, 3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+4)
	extz	wa
	lda	xde, (xsp)
	pushw	127
	ldw	bc, 49
	call	SeMenu_RegisterElement_Extended
	pushw	3
	pushw	46
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	lds	wa, 2
	lds	bc, 0
	call	15764042
	lds	wa, 4
	call	15758489
	inc	8, xsp
	ret
	lda	xsp, (xsp-10)
	ld	(xsp+8), a
	lda	xbc, (xsp+2)
	lds	wa, 4
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+4)
	lds	wa, 3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+8)
	extz	wa
	ld	e, (xsp+4)
	inc	1, e
	extz	de
	ld	c, (xsp+2)
	dec	1, c
	extz	bc
	pushw	bc
	lds	bc, 2
	call	15767527
	cps	l, 1
	jr	nz, 52
	lda	xwa, (xsp+6)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	lds	wa, 2
	call	SeMenu_LoadPartParam
	ld	a, (xsp+6)
	extz	wa
	lda	xde, (xsp)
	pushw	127
	ldw	bc, 48
	call	SeMenu_RegisterElement_Extended
	pushw	2
	pushw	46
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	lds	wa, 2
	lds	bc, 0
	call	15764042
	lds	wa, 5
	call	15758489
	lda	xsp, (xsp+10)
	ret
	dec	8, xsp
	ld	(xsp+6), a
	lda	xbc, (xsp+2)
	lds	wa, 2
	call	SeMenu_LoadPartParam
	ld	a, (xsp+6)
	extz	wa
	ld	e, (xsp+2)
	inc	1, e
	extz	de
	pushw	127
	lds	bc, 4
	call	15767527
	cps	l, 1
	jr	nz, 52
	lda	xwa, (xsp+4)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	lds	wa, 4
	call	SeMenu_LoadPartParam
	ld	a, (xsp+4)
	extz	wa
	lda	xde, (xsp)
	pushw	127
	ldw	bc, 50
	call	SeMenu_RegisterElement_Extended
	pushw	4
	pushw	46
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	lds	wa, 2
	lds	bc, 0
	call	15764042
	lds	wa, 6
	call	15758489
	inc	8, xsp
	ret
	lda	xsp, (xsp-16)
	ld	(xsp+14), a
	lda	xwa, (xsp+12)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	lds	wa, 0
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+14)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758524
	ld	e, (xsp+12)
	extz	de
	pushw	46
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 46
	lds	bc, 0
	call	15757111
	lds	wa, 7
	call	15758489
	lda	xsp, (xsp+16)
	ret
	lda	xsp, (xsp-16)
	ld	(xsp+14), a
	lda	xwa, (xsp+12)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	lds	wa, 1
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+14)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758524
	ld	e, (xsp+12)
	extz	de
	pushw	47
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 46
	lds	bc, 1
	call	15757111
	ldw	wa, 8
	call	15758489
	lda	xsp, (xsp+16)
	ret
	cps	a, 0
	ret	z
	call	15756545
	ret
	cps	a, 0
	jr	nz, 7
	ldw	wa, 43
	lds	bc, 0
	jr	15
	lds	wa, 1
	call	15757230
	cps	l, 0
	ret	z
	ldw	wa, 46
	lds	bc, 1
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	jr	nz, 7
	ldw	wa, 47
	lds	bc, 0
	jr	15
	lds	wa, 2
	call	15757230
	cps	l, 0
	ret	z
	ldw	wa, 46
	lds	bc, 1
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	ret	z
	lds	wa, 3
	call	15757230
	cps	l, 0
	ret	z
	ldw	wa, 46
	lds	bc, 1
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	ret	z
	lds	wa, 4
	call	15757230
	cps	l, 0
	ret	z
	ldw	wa, 46
	lds	bc, 1
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	ret	z
	ldw	wa, 45
	lds	bc, 0
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	ret	nz
	lds	wa, 0
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	lds	bc, 0
	call	SeMenu_SendEvent
	ret
	extz	wa
	lds	bc, 0
	jp	SeMenu_ApplyPartEdit_Data2
	extz	wa
	lds	bc, 0
	jp	15759013
	extz	wa
	lds	bc, 0
	jp	15759138
	extz	wa
	lds	bc, 0
	jp	15759263
	extz	wa
	lds	bc, 0
	jp	15759388
	extz	wa
	lds	bc, 0
	jp	15759511
	extz	wa
	lds	bc, 0
	jp	15759614
	cps	a, 0
	.byte 0xf2, 0x01
	jr	pl, -16
	.byte 0xde
	ldw	wa, 45
	lds	bc, 0
	jp	SeMenu_SendEvent
	cps	a, 0
	jr	nz, 9
	ldw	wa, 43
	lds	bc, 0
	jp	SeMenu_SendEvent
	lds	wa, 0
	lds	bc, 1
	jp	15757276
	cps	a, 0
	ret	z
	lds	wa, 0
	lds	bc, 2
	call	15757276
	ret
	cps	a, 0
	ret	z
	lds	wa, 0
	lds	bc, 3
	call	15757276
	ret
	cps	a, 0
	ret	z
	lds	wa, 0
	lds	bc, 4
	call	15757276
	ret
	cps	a, 0
	ret	nz
	lds	wa, 0
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	lds	bc, 0
	call	SeMenu_SendEvent
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	15758131
	cp	hl, 65535
	jr	z, 25
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda_24	xde, 14736926
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	15758131
	cp	hl, 65535
	jr	z, 25
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda_24	xde, 14736998
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	15758131
	cp	hl, 65535
	jr	z, 25
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda_24	xde, 14737070
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	15758131
	cp	hl, 65535
	jr	z, 25
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda_24	xde, 14737142
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	15758131
	cp	hl, 65535
	jr	z, 25
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda_24	xde, 14737214
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	15758131
	cp	hl, 65535
	jr	z, 25
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda_24	xde, 14737286
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	15758131
	cp	hl, 65535
	jr	z, 25
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda_24	xde, 14737358
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	15758131
	cp	hl, 65535
	jr	z, 25
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda_24	xde, 14737430
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	15758131
	cp	hl, 65535
	jr	z, 25
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda_24	xde, 14737502
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	15758131
	cp	hl, 65535
	jr	z, 25
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda_24	xde, 14737574
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	inc	4, xsp
	ret
	extz	wa
	lds	bc, 1
	ldw	de, 48
	calr	8
	lds	wa, 0
	lds	bc, 0
	jp	15765121
	lda	xsp, (xsp-22)
	ld	(xsp+16), e
	ld	(xsp+18), c
	ld	(xsp+20), a
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+12)
	call	SeMenu_LoadObjEntries
	lda	xbc, (xsp)
	lds	wa, 2
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 127
	ld	(xbc+9), 0
	ld	a, (xsp+20)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758524
	.byte 0x8f
	incf
	push	xsp
	nop
	jr	nz, 4
	ldb	c, 77
	jr	25
	ld	a, (xsp+14)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+17)
	ld	c, a
	ld	(xsp+14), 0
	ld	a, (xsp+16)
	extz	wa
	ld	e, (xsp+14)
	extz	de
	extz	bc
	pushw	bc
	lda	xbc, (xsp+2)
	push	xbc
	lds	bc, 2
	call	15757111
	ld	a, (xsp+18)
	extz	wa
	call	15758489
	lda	xsp, (xsp+22)
	ret
	extz	wa
	lds	bc, 2
	ldw	de, 48
	calr	8
	lds	wa, 0
	lds	bc, 0
	jp	15765121
	lda	xsp, (xsp-22)
	ld	(xsp+16), e
	ld	(xsp+18), c
	ld	(xsp+20), a
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+12)
	call	SeMenu_LoadObjEntries
	lda	xbc, (xsp)
	lds	wa, 3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 127
	ld	(xbc+7), 0
	ld	(xbc+8), 5
	ld	(xbc+9), 0
	ld	a, (xsp+20)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758524
	.byte 0x8f
	incf
	push	xsp
	nop
	jr	nz, 4
	ldb	c, 78
	jr	25
	ld	a, (xsp+14)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+18)
	ld	c, a
	ld	(xsp+14), 0
	ld	a, (xsp+16)
	extz	wa
	ld	e, (xsp+14)
	extz	de
	extz	bc
	pushw	bc
	lda	xbc, (xsp+2)
	push	xbc
	lds	bc, 3
	call	15757111
	ld	a, (xsp+18)
	extz	wa
	call	15758489
	lda	xsp, (xsp+22)
	ret
	extz	wa
	lds	bc, 3
	ldw	de, 48
	jr	0
	lda	xsp, (xsp-22)
	ld	(xsp+16), e
	ld	(xsp+18), c
	ld	(xsp+20), a
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+12)
	call	SeMenu_LoadObjEntries
	lda	xbc, (xsp)
	lds	wa, 1
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 63
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 0
	ld	a, (xsp+20)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758524
	.byte 0x8f
	incf
	push	xsp
	nop
	jr	nz, 4
	ldb	c, 55
	jr	25
	ld	a, (xsp+14)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+16)
	ld	c, a
	ld	(xsp+14), 0
	ld	a, (xsp+16)
	extz	wa
	ld	e, (xsp+14)
	extz	de
	extz	bc
	pushw	bc
	lda	xbc, (xsp+2)
	push	xbc
	lds	bc, 1
	call	15757111
	ld	a, (xsp+18)
	extz	wa
	call	15758489
	lda	xsp, (xsp+22)
	ret
	extz	wa
	lds	bc, 4
	ldw	de, 48
	jr	0
	lda	xsp, (xsp-22)
	ld	(xsp+16), e
	ld	(xsp+18), c
	ld	(xsp+20), a
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+12)
	call	SeMenu_LoadObjEntries
	lda	xbc, (xsp)
	lds	wa, 0
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 7
	ld	(xbc+7), 5
	ld	(xbc+8), 6
	ld	(xbc+9), 0
	ld	a, (xsp+20)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758524
	.byte 0x8f
	incf
	push	xsp
	nop
	jr	nz, 4
	ldb	c, 54
	jr	25
	ld	a, (xsp+14)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+15)
	ld	c, a
	ld	(xsp+14), 0
	ld	a, (xsp+16)
	extz	wa
	ld	e, (xsp+14)
	extz	de
	extz	bc
	pushw	bc
	lda	xbc, (xsp+2)
	push	xbc
	lds	bc, 0
	call	15757111
	ld	a, (xsp+18)
	extz	wa
	call	15758489
	lda	xsp, (xsp+22)
	ret
	lda	xsp, (xsp-18)
	ld	(xsp+16), a
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+12)
	call	SeMenu_LoadObjEntries
	lda	xbc, (xsp)
	lds	wa, 5
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 1
	ld	(xbc+7), 7
	ld	(xbc+8), 1
	ld	(xbc+9), 0
	ld	e, (xsp+16)
	res	7, e
	lda	xwa, (xbc+10)
	cps	e, 0
	jr	nz, 5
	ld	(xwa), 1
	jr	3
	ld	(xwa), 255
	.byte 0x8f
	incf
	push	xsp
	nop
	jr	nz, 4
	ldb	a, 80
	jr	23
	ld	a, (xsp+14)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+20)
	ld	(xsp+14), 0
	ld	e, (xsp+14)
	extz	de
	extz	wa
	pushw	wa
	push	xbc
	ldw	wa, 48
	lds	bc, 5
	call	15757111
	cps	l, 1
	.byte 0xf2
	pushw	bc
	.byte 0x90, 0xf0, 0xe6
	lds	wa, 6
	call	15758489
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-18)
	ld	(xsp+16), a
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+12)
	call	SeMenu_LoadObjEntries
	lda	xbc, (xsp)
	lds	wa, 4
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 127
	ld	(xbc+7), 0
	ld	(xbc+8), 127
	ld	(xbc+9), 0
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758524
	.byte 0x8f
	incf
	push	xsp
	nop
	jr	nz, 4
	ldb	a, 79
	jr	23
	ld	a, (xsp+14)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+19)
	ld	(xsp+14), 0
	ld	e, (xsp+14)
	extz	de
	extz	wa
	pushw	wa
	.byte 0xbf
	push_sr
	.asciz "0800"
	lds	bc, 4
	call	15757111
	cps	l, 1
	.byte 0xf2
	pushw	bc
	.byte 0x90, 0xf0, 0xe6
	lds	wa, 7
	call	15758489
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-18)
	ld	(xsp+16), a
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+12)
	call	SeMenu_LoadObjEntries
	lda	xbc, (xsp)
	lds	wa, 5
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 127
	ld	(xbc+7), 0
	ld	(xbc+8), 13
	ld	(xbc+9), 0
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758524
	.byte 0x8f
	incf
	push	xsp
	nop
	jr	nz, 4
	ldb	a, 80
	jr	23
	ld	a, (xsp+14)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+20)
	ld	(xsp+14), 0
	ld	e, (xsp+14)
	extz	de
	extz	wa
	pushw	wa
	.byte 0xbf
	push_sr
	.asciz "0800"
	lds	bc, 5
	call	15757111
	cps	l, 1
	.byte 0xf2
	pushw	bc
	.byte 0x90, 0xf0, 0xe6
	ldw	wa, 8
	call	15758489
	lda	xsp, (xsp+18)
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	nz, 16
	.byte 0x87
	push	xsp
	nop
	jr	nz, 15
	ldw	wa, 55
	lds	bc, 0
	call	SeMenu_SendEvent
	jr	4
	call	15756545
	inc	4, xsp
	ret
	cps	a, 0
	ret	z
	lds	wa, 1
	call	15757230
	cps	l, 0
	ret	z
	ldw	wa, 48
	lds	bc, 0
	call	SeMenu_SendEvent
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	nz, 12
	.byte 0x87
	push	xsp
	nop
	jr	nz, 26
	ldw	wa, 57
	lds	bc, 0
	jr	15
	lds	wa, 2
	call	15757230
	cps	l, 0
	jr	z, 9
	ldw	wa, 48
	lds	bc, 0
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	nz, 32
	lda	xbc, (xsp+2)
	lds	wa, 0
	call	SeMenu_LoadPartParam
	.byte 0x8f
	push_sr
	push	xix
	swi	0
	.byte 0xbf
	push_sr
	.byte 0xb9
	ld	a, (xsp+2)
	extz	wa
	call	15756578
	ldw	wa, 48
	lds	bc, 0
	jr	20
	.byte 0x87
	push	xsp
	.byte 0x01
	jr	z, 19
	lds	wa, 3
	call	15757230
	cps	l, 0
	jr	z, 9
	ldw	wa, 48
	lds	bc, 0
	call	SeMenu_SendEvent
	inc	6, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	z, 24
	.byte 0x87
	push	xsp
	.byte 0x01
	jr	z, 19
	lds	wa, 4
	call	15757230
	cps	l, 0
	jr	z, 9
	ldw	wa, 48
	lds	bc, 0
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x87
	push	xsp
	.byte 0x01
	jr	z, 15
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	nz, 9
	ldw	wa, 54
	lds	bc, 0
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lds	wa, 0
	call	SeMenu_SetupMenuDisplay
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	nz, 21
	.byte 0x87
	push	xsp
	nop
	jr	nz, 7
	ldw	wa, 32
	lds	bc, 0
	jr	5
	ldw	wa, 61
	lds	bc, 0
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	extz	wa
	lds	bc, 1
	ldw	de, 49
	calr	64240
	lds	wa, 1
	lds	bc, 0
	jp	15765121
	extz	wa
	lds	bc, 2
	ldw	de, 49
	calr	64375
	lds	wa, 1
	lds	bc, 0
	jp	15765121
	extz	wa
	lds	bc, 3
	ldw	de, 49
	jrl	-1035
	extz	wa
	lds	bc, 4
	ldw	de, 49
	jrl	-901
	extz	wa
	jrl	-771
	extz	wa
	jrl	-641
	extz	wa
	jrl	-517
	extz	wa
	jrl	-392
	extz	wa
	jrl	-357
	extz	wa
	jrl	-338
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	nz, 33
	lda	xbc, (xsp+2)
	lds	wa, 0
	call	SeMenu_LoadPartParam
	.byte 0x8f
	push_sr
	push	xix
	swi	0
	.byte 0x8f
	push_sr
	push	xiz
	pop_sr
	ld	a, (xsp+2)
	extz	wa
	call	15756578
	ldw	wa, 48
	lds	bc, 0
	jr	20
	.byte 0x87
	push	xsp
	nop
	jr	nz, 19
	lds	wa, 3
	call	15757230
	cps	l, 0
	jr	z, 9
	ldw	wa, 48
	lds	bc, 0
	call	SeMenu_SendEvent
	inc	6, xsp
	ret
	extz	wa
	jrl	-293
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	nz, 14
	.byte 0x87
	push	xsp
	nop
	jr	nz, 9
	ldw	wa, 54
	lds	bc, 0
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lds	wa, 0
	call	SeMenu_SetupMenuDisplay
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	nz, 21
	.byte 0x87
	push	xsp
	nop
	jr	nz, 7
	ldw	wa, 32
	lds	bc, 0
	jr	5
	ldw	wa, 61
	lds	bc, 0
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	extz	wa
	lds	bc, 3
	ldw	de, 50
	calr	63991
	lds	wa, 0
	lds	bc, 1
	jp	15765121
	extz	wa
	lds	bc, 4
	ldw	de, 50
	calr	64126
	lds	wa, 0
	lds	bc, 1
	jp	15765121
	extz	wa
	lds	bc, 5
	ldw	de, 50
	jrl	-1284
	extz	wa
	lds	bc, 6
	ldw	de, 50
	jrl	-1150
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	nz, 16
	.byte 0x87
	push	xsp
	nop
	jr	nz, 15
	ldw	wa, 55
	lds	bc, 0
	call	SeMenu_SendEvent
	jr	4
	call	15756545
	inc	4, xsp
	ret
	cps	a, 0
	ret	z
	lds	wa, 1
	call	15757230
	cps	l, 0
	ret	z
	ldw	wa, 48
	lds	bc, 0
	call	SeMenu_SendEvent
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	nz, 12
	.byte 0x87
	push	xsp
	nop
	jr	nz, 26
	ldw	wa, 57
	lds	bc, 0
	jr	15
	lds	wa, 2
	call	15757230
	cps	l, 0
	jr	z, 9
	ldw	wa, 48
	lds	bc, 0
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	nz, 32
	lda	xbc, (xsp+2)
	lds	wa, 0
	call	SeMenu_LoadPartParam
	.byte 0x8f
	push_sr
	push	xix
	swi	0
	.byte 0xbf
	push_sr
	.byte 0xba
	ld	a, (xsp+2)
	extz	wa
	call	15756578
	ldw	wa, 48
	lds	bc, 0
	jr	20
	.byte 0x87
	push	xsp
	.byte 0x01
	jr	z, 19
	lds	wa, 3
	call	15757230
	cps	l, 0
	jr	z, 9
	ldw	wa, 48
	lds	bc, 0
	call	SeMenu_SendEvent
	inc	6, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x87
	push	xsp
	.byte 0x01
	jr	z, 25
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	z, 19
	lds	wa, 4
	call	15757230
	cps	l, 0
	jr	z, 9
	ldw	wa, 48
	lds	bc, 0
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x87
	push	xsp
	.byte 0x01
	jr	z, 15
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	nz, 9
	ldw	wa, 54
	lds	bc, 0
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lds	wa, 0
	call	SeMenu_SetupMenuDisplay
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	nz, 21
	.byte 0x87
	push	xsp
	nop
	jr	nz, 7
	ldw	wa, 32
	lds	bc, 0
	jr	5
	ldw	wa, 61
	lds	bc, 0
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	extz	wa
	lds	bc, 3
	ldw	de, 51
	calr	63619
	lds	wa, 1
	lds	bc, 1
	jp	15765121
	extz	wa
	lds	bc, 4
	ldw	de, 51
	calr	63754
	lds	wa, 1
	lds	bc, 1
	jp	15765121
	extz	wa
	lds	bc, 5
	ldw	de, 51
	jrl	-1656
	extz	wa
	lds	bc, 6
	ldw	de, 51
	jrl	-1522
	extz	wa
	jrl	-377
	extz	wa
	jrl	-342
	extz	wa
	jrl	-323
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	nz, 33
	lda	xbc, (xsp+2)
	lds	wa, 0
	call	SeMenu_LoadPartParam
	.byte 0x8f
	push_sr
	push	xix
	swi	0
	.byte 0x8f
	push_sr
	push	xiz
	halt
	ld	a, (xsp+2)
	extz	wa
	call	15756578
	ldw	wa, 48
	lds	bc, 0
	jr	20
	.byte 0x87
	push	xsp
	.byte 0x01
	jr	z, 19
	lds	wa, 3
	call	15757230
	cps	l, 0
	jr	z, 9
	ldw	wa, 48
	lds	bc, 0
	call	SeMenu_SendEvent
	inc	6, xsp
	ret
	extz	wa
	jrl	-278
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x87
	push	xsp
	.byte 0x01
	jr	z, 15
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	nz, 9
	ldw	wa, 54
	lds	bc, 0
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lds	wa, 0
	call	SeMenu_SetupMenuDisplay
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	nz, 21
	.byte 0x87
	push	xsp
	nop
	jr	nz, 7
	ldw	wa, 32
	lds	bc, 0
	jr	5
	ldw	wa, 61
	lds	bc, 0
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+18), a
	lda	xwa, (xsp+16)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+12)
	call	SeMenu_LoadObjEntries
	lda	xbc, (xsp+14)
	lds	wa, 4
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	lds	wa, 2
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	a, (xsp+14)
	dec	1, a
	ld	(xbc+8), a
	ld	(xbc+9), 0
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758524
	.byte 0x8f
	incf
	push	xsp
	nop
	jr	nz, 4
	ldb	a, 77
	jr	23
	ld	a, (xsp+16)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+17)
	ld	(xsp+16), 0
	ld	e, (xsp+16)
	extz	de
	extz	wa
	pushw	wa
	.byte 0xbf
	push_sr
	.asciz "0804"
	lds	bc, 2
	call	15757111
	call	15765785
	lds	wa, 2
	call	15758489
	lda	xsp, (xsp+20)
	ret
	extz	wa
	lds	bc, 3
	ldw	de, 52
	calr	63399
	jp	15765785
	lda	xsp, (xsp-20)
	ld	(xsp+18), a
	lda	xwa, (xsp+16)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+12)
	call	SeMenu_LoadObjEntries
	lda	xbc, (xsp+14)
	lds	wa, 2
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	lds	wa, 4
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 127
	ld	a, (xsp+14)
	inc	1, a
	ld	(xbc+9), a
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758524
	lda	xbc, (xsp)
	.byte 0x8f
	incf
	push	xsp
	nop
	jr	nz, 16
	ld	e, (xsp+16)
	extz	de
	pushw	79
	push	xbc
	ldw	wa, 52
	lds	bc, 4
	jr	30
	ld	a, (xsp+16)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+19)
	extz	wa
	pushw	wa
	push	xbc
	ldw	wa, 52
	lds	bc, 4
	lds	de, 0
	call	15757111
	call	15765785
	lds	wa, 4
	call	15758489
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-18)
	ld	(xsp+16), a
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	lda	xwa, (xsp+12)
	call	SeMenu_LoadObjEntries
	lda	xbc, (xsp)
	lds	wa, 5
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 15
	ld	(xbc+7), 0
	ld	(xbc+8), 5
	ld	(xbc+9), 0
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758524
	lda	xbc, (xsp)
	.byte 0x8f
	incf
	push	xsp
	nop
	jr	nz, 16
	ld	e, (xsp+14)
	extz	de
	pushw	80
	push	xbc
	ldw	wa, 52
	lds	bc, 5
	jr	30
	ld	a, (xsp+14)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+20)
	extz	wa
	.asciz "(904"
	lds	bc, 5
	lds	de, 0
	call	15757111
	call	15765785
	lds	wa, 5
	call	15758489
	lda	xsp, (xsp+18)
	ret
	extz	wa
	lds	bc, 6
	ldw	de, 52
	jrl	-2280
	extz	wa
	lds	bc, 7
	ldw	de, 52
	jrl	-2146
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	nz, 16
	.byte 0x87
	push	xsp
	nop
	jr	nz, 15
	ldw	wa, 55
	lds	bc, 0
	call	SeMenu_SendEvent
	jr	4
	call	15756545
	inc	4, xsp
	ret
	cps	a, 0
	ret	z
	lds	wa, 1
	call	15757230
	cps	l, 0
	ret	z
	ldw	wa, 48
	lds	bc, 0
	call	SeMenu_SendEvent
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	nz, 12
	.byte 0x87
	push	xsp
	nop
	jr	nz, 26
	ldw	wa, 57
	lds	bc, 0
	jr	15
	lds	wa, 2
	call	15757230
	cps	l, 0
	jr	z, 9
	ldw	wa, 48
	lds	bc, 0
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	nz, 29
	lda	xbc, (xsp+2)
	lds	wa, 0
	call	SeMenu_LoadPartParam
	.byte 0x8f
	push_sr
	push	xix
	swi	0
	ld	a, (xsp+2)
	extz	wa
	call	15756578
	ldw	wa, 48
	lds	bc, 0
	jr	20
	.byte 0x87
	push	xsp
	.byte 0x01
	jr	z, 19
	lds	wa, 3
	call	15757230
	cps	l, 0
	jr	z, 9
	ldw	wa, 48
	lds	bc, 0
	call	SeMenu_SendEvent
	inc	6, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x87
	push	xsp
	.byte 0x01
	jr	z, 25
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	z, 19
	lds	wa, 4
	call	15757230
	cps	l, 0
	jr	z, 9
	ldw	wa, 48
	lds	bc, 0
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x87
	push	xsp
	.byte 0x01
	jr	z, 15
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	nz, 9
	ldw	wa, 54
	lds	bc, 0
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lds	wa, 0
	call	SeMenu_SetupMenuDisplay
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	nz, 21
	.byte 0x87
	push	xsp
	nop
	jr	nz, 7
	ldw	wa, 32
	lds	bc, 0
	jr	5
	ldw	wa, 61
	lds	bc, 0
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	nz, 16
	.byte 0x87
	push	xsp
	nop
	jr	nz, 15
	ldw	wa, 55
	lds	bc, 0
	call	SeMenu_SendEvent
	jr	4
	call	15756545
	inc	4, xsp
	ret
	cps	a, 0
	ret	z
	lds	wa, 1
	call	15757230
	cps	l, 0
	ret	z
	ldw	wa, 48
	lds	bc, 0
	call	SeMenu_SendEvent
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	nz, 12
	.byte 0x87
	push	xsp
	nop
	jr	nz, 26
	ldw	wa, 57
	lds	bc, 0
	jr	15
	lds	wa, 2
	call	15757230
	cps	l, 0
	jr	z, 9
	ldw	wa, 48
	lds	bc, 0
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	nz, 32
	lda	xbc, (xsp+2)
	lds	wa, 0
	call	SeMenu_LoadPartParam
	.byte 0x8f
	push_sr
	push	xix
	swi	0
	.byte 0xbf
	push_sr
	.byte 0xb8
	ld	a, (xsp+2)
	extz	wa
	call	15756578
	ldw	wa, 48
	lds	bc, 0
	jr	20
	.byte 0x87
	push	xsp
	.byte 0x01
	jr	z, 19
	lds	wa, 3
	call	15757230
	cps	l, 0
	jr	z, 9
	ldw	wa, 48
	lds	bc, 0
	call	SeMenu_SendEvent
	inc	6, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x87
	push	xsp
	.byte 0x01
	jr	z, 25
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	z, 19
	lds	wa, 4
	call	15757230
	cps	l, 0
	jr	z, 9
	ldw	wa, 48
	lds	bc, 0
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x87
	push	xsp
	.byte 0x01
	jr	z, 15
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	nz, 9
	ldw	wa, 54
	lds	bc, 0
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lds	wa, 0
	call	SeMenu_SetupMenuDisplay
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push_sr
	push	xsp
	nop
	jr	nz, 21
	.byte 0x87
	push	xsp
	nop
	jr	nz, 7
	ldw	wa, 32
	lds	bc, 0
	jr	5
	ldw	wa, 61
	lds	bc, 0
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	lda	xsp, (xsp-18)
	ld	(xsp+16), a
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	lds	wa, 3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758524
	ld	e, (xsp+14)
	extz	de
	pushw	60
	.byte 0xbf
	push_sr
	.asciz "0806"
	lds	bc, 3
	call	15757111
	cps	l, 1
	jr	nz, 29
	lda	xbc, (xsp+12)
	lds	wa, 3
	call	SeMenu_LoadPartParam
	ld	c, (xsp+12)
	extz	bc
	ldw	wa, 10
	call	SeMenu_StorePartParam
	lds	wa, 0
	lds	bc, 0
	call	15764042
	lds	wa, 3
	call	15758489
	lda	xsp, (xsp+18)
	ret
	dec	8, xsp
	ld	(xsp+6), a
	lda	xbc, (xsp+2)
	lds	wa, 0
	call	SeMenu_LoadPartParam
	ld	a, (xsp+6)
	extz	wa
	ld	c, (xsp+2)
	dec	1, c
	extz	bc
	pushw	bc
	lds	bc, 1
	lds	de, 0
	call	15767527
	cps	l, 1
	jr	nz, 52
	lda	xwa, (xsp+4)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	lds	wa, 1
	call	SeMenu_LoadPartParam
	ld	a, (xsp+4)
	extz	wa
	lda	xde, (xsp)
	pushw	127
	ldw	bc, 58
	call	SeMenu_RegisterElement_Extended
	pushw	1
	pushw	54
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	lds	wa, 0
	lds	bc, 0
	call	15764042
	lds	wa, 4
	call	15758489
	inc	8, xsp
	ret
	lda	xsp, (xsp-10)
	ld	(xsp+8), a
	lda	xbc, (xsp+4)
	lds	wa, 1
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+2)
	lds	wa, 2
	call	SeMenu_LoadPartParam
	ld	a, (xsp+8)
	extz	wa
	ld	e, (xsp+4)
	inc	1, e
	extz	de
	ld	c, (xsp+2)
	dec	1, c
	extz	bc
	pushw	bc
	lds	bc, 0
	call	15767527
	cps	l, 1
	jr	nz, 52
	lda	xwa, (xsp+6)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	lds	wa, 0
	call	SeMenu_LoadPartParam
	ld	a, (xsp+6)
	extz	wa
	lda	xde, (xsp)
	pushw	127
	ldw	bc, 57
	call	SeMenu_RegisterElement_Extended
	pushw	0
	pushw	54
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	lds	wa, 0
	lds	bc, 0
	call	15764042
	lds	wa, 5
	call	15758489
	lda	xsp, (xsp+10)
	ret
	dec	8, xsp
	ld	(xsp+6), a
	lda	xbc, (xsp+2)
	lds	wa, 0
	call	SeMenu_LoadPartParam
	ld	a, (xsp+6)
	extz	wa
	ld	e, (xsp+2)
	inc	1, e
	extz	de
	pushw	127
	lds	bc, 2
	call	15767527
	cps	l, 1
	jr	nz, 52
	lda	xwa, (xsp+4)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	lds	wa, 2
	call	SeMenu_LoadPartParam
	ld	a, (xsp+4)
	extz	wa
	lda	xde, (xsp)
	pushw	127
	ldw	bc, 59
	call	SeMenu_RegisterElement_Extended
	pushw	2
	pushw	54
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	lds	wa, 0
	lds	bc, 0
	call	15764042
	lds	wa, 6
	call	15758489
	inc	8, xsp
	ret
	cps	a, 0
	.byte 0xf2, 0x01
	jr	pl, -16
	.byte 0xde
	ldw	wa, 55
	lds	bc, 0
	jp	SeMenu_SendEvent
	cps	a, 0
	ret	z
	lds	wa, 1
	call	15757230
	cps	l, 0
	ret	z
	ldw	wa, 54
	lds	bc, 1
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	jr	nz, 7
	ldw	wa, 57
	lds	bc, 0
	jr	15
	lds	wa, 2
	call	15757230
	cps	l, 0
	ret	z
	ldw	wa, 54
	lds	bc, 1
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	ret	z
	lds	wa, 3
	call	15757230
	cps	l, 0
	ret	z
	ldw	wa, 54
	lds	bc, 1
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	ret	z
	lds	wa, 4
	call	15757230
	cps	l, 0
	ret	z
	ldw	wa, 54
	lds	bc, 1
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	ret	z
	ldw	wa, 48
	lds	bc, 0
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	ret	nz
	lds	wa, 0
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	lds	bc, 0
	call	SeMenu_SendEvent
	ret
	extz	wa
	ldw	bc, 63
	lds	de, 0
	jp	15759774
	extz	wa
	ldw	bc, 64
	lds	de, 0
	jp	15759874
	extz	wa
	ldw	bc, 62
	ldw	de, 65
	jp	15759974
	extz	wa
	ldw	bc, 66
	lds	de, 0
	jp	15760132
	extz	wa
	ldw	bc, 70
	ldw	de, 67
	jp	15760232
	extz	wa
	ldw	bc, 68
	lds	de, 0
	jp	15760392
	extz	wa
	ldw	bc, 61
	ldw	de, 69
	jp	15760494
	cps	a, 0
	ret	z
	call	15756545
	ret
	cps	a, 0
	jr	nz, 7
	ldw	wa, 48
	lds	bc, 0
	jr	15
	lds	wa, 1
	call	15757230
	cps	l, 0
	ret	z
	ldw	wa, 55
	lds	bc, 1
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	jr	nz, 7
	ldw	wa, 57
	lds	bc, 0
	jr	15
	lds	wa, 2
	call	15757230
	cps	l, 0
	ret	z
	ldw	wa, 55
	lds	bc, 1
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	jr	nz, 6
	lds	wa, 0
	jp	15759718
	lds	wa, 3
	call	15757230
	cps	l, 0
	ret	z
	ldw	wa, 55
	lds	bc, 1
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	jr	nz, 6
	lds	wa, 1
	jp	15759718
	lds	wa, 4
	call	15757230
	cps	l, 0
	ret	z
	ldw	wa, 55
	lds	bc, 1
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	ret	nz
	ldw	wa, 56
	lds	bc, 0
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	ret	nz
	lds	wa, 0
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	lds	bc, 0
	call	SeMenu_SendEvent
	ret
	extz	wa
	ldw	bc, 74
	jp	15760654
	extz	wa
	ldw	bc, 75
	jp	15760798
	extz	wa
	ldw	bc, 76
	jp	15760942
	extz	wa
	ldw	bc, 73
	jp	15761086
	extz	wa
	ldw	bc, 71
	jp	15761165
	extz	wa
	ldw	bc, 72
	jp	15761248
	cps	a, 0
	ret	z
	call	15756545
	ret
	cps	a, 0
	jr	nz, 7
	ldw	wa, 48
	lds	bc, 0
	jr	15
	lds	wa, 1
	call	15757230
	cps	l, 0
	ret	z
	ldw	wa, 56
	lds	bc, 1
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	jr	nz, 7
	ldw	wa, 57
	lds	bc, 0
	jr	15
	lds	wa, 2
	call	15757230
	cps	l, 0
	ret	z
	ldw	wa, 56
	lds	bc, 1
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	ret	z
	lds	wa, 3
	call	15757230
	cps	l, 0
	ret	z
	ldw	wa, 56
	lds	bc, 1
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	ret	z
	lds	wa, 4
	call	15757230
	cps	l, 0
	ret	z
	ldw	wa, 56
	lds	bc, 1
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	ret	z
	ldw	wa, 55
	lds	bc, 0
	call	SeMenu_SendEvent
	ret
	cps	a, 0
	ret	nz
	lds	wa, 0
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	lds	bc, 0
	call	SeMenu_SendEvent
	ret
	extz	wa
	lds	bc, 2
	jp	SeMenu_ApplyPartEdit_Data2
	extz	wa
	lds	bc, 2
	jp	15759013
	extz	wa
	lds	bc, 2
	jp	15759138
	extz	wa
	lds	bc, 2
	jp	15759263
	extz	wa
	lds	bc, 2
	jp	15759388
	extz	wa
	lds	bc, 2
	jp	15759511
	extz	wa
	lds	bc, 2
	jp	15759614
	cps	a, 0
	.byte 0xf2, 0x01
	jr	pl, -16
	.byte 0xde
	ldw	wa, 55
	lds	bc, 0
	jp	SeMenu_SendEvent
	cps	a, 0
	jr	nz, 9
	ldw	wa, 48
	lds	bc, 0
	jp	SeMenu_SendEvent
	lds	wa, 2
	lds	bc, 1
	jp	15757276
	cps	a, 0
	ret	z
	lds	wa, 2
	lds	bc, 2
	call	15757276
	ret
	cps	a, 0
	ret	z
	lds	wa, 2
	lds	bc, 3
	call	15757276
	ret
	cps	a, 0
	ret	z
	lds	wa, 2
	lds	bc, 4
	call	15757276
	ret
	cps	a, 0
	ret	nz
	lds	wa, 0
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	lds	bc, 0
	call	SeMenu_SendEvent
	ret


; --- Sound Editor ---
