HDAE5000_UI_Config:	; 0x29BFE0
	; UI configuration strings
	.asciz "adraw"
	.asciz "auto_inc"
	.byte 0x00
	.asciz "dial"
	.byte 0x00
	.asciz "sel_num"
	.asciz "row"
	.asciz "column"
	.byte 0x00
	.asciz "str_adr"
	.asciz "main_func"
	.asciz "fontcolor"
	.asciz "font"
	.zero 3
	.asciz "fontcolor"
	.asciz "color"
	.zero 6
	.asciz "func"
	.zero 15
	.asciz "infocolor"
	.asciz "infofont"
	.byte 0x00
	.asciz "reversecolor"
	.byte 0x00
	.asciz "fontcolor"
	.asciz "font"
	.byte 0x00
	.asciz "pEnable"
	.zero 2
	.asciz "sel_pos"
	.asciz "sel_num"
	.asciz "dial"
	.byte 0x00

HDAE5000_RECORD_TABLE:	; 0x29C0AA
	; Record/entry data table
; LREC: 0x29C0AA (6356 bytes)

	neg	bc
	pushw wa                                ; push WA
	nop                                     ; nop
	.byte 0x11                             ; scf
	nop                                     ; nop
	jr f, .LREC_c0b3                       ; [60 01] jr F,0x29c0b3
	push xix
.LREC_c0b3:
	nop                                     ; nop
	ldb	w, 0x00
	jrl	le, 0x29d9
	nop                                     ; nop
	jr	z, 0xd9
	pushw bc                                ; push BC
	nop                                     ; nop
	pop xde                                 ; pop XDE
	ld	hl, (xsp)
	nop                                     ; nop
	pushw de                                ; push DE
	.byte 0x12                             ; ccf
	pushw wa                                ; push WA
	nop                                     ; nop
	ld	xiz, 0x1a016000
	nop                                     ; nop
	.byte 0x04                             ; max
	nop                                     ; nop
	pop xix                                 ; pop XIX
	orcf_a_16 bc		; orcf A,BC
	nop                                     ; nop
	pop xwa                                 ; pop XWA
	orcf_a_16 bc		; orcf A,BC
	nop                                     ; nop
	ld	c, (xde-105)
	nop                                     ; nop
	ld_s	(xbc+4), w
	nop                                     ; nop
	ldw	ix, 0x6000
	.byte 0x01                             ; normal
	pushw de                                ; push DE
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	popw ix                                 ; pop IX
	orcf_a_16 bc		; orcf A,BC
	nop                                     ; nop
	popw de                                 ; pop DE
	orcf_a_16 bc		; orcf A,BC
	nop                                     ; nop
	.byte 0x96, 0x97                       ; adc SP,(XIZ)
	ldb	c, 0x00
	.byte 0x11                             ; scf
	.byte 0x14                             ; push A
	pushw wa                                ; push WA
	nop                                     ; nop
	ldw	iy, 0x6000
	.byte 0x01                             ; normal
	ldb	d, 0x00
	nop                                     ; nop
	nop                                     ; nop
	push xwa
	orcf_a_16 bc		; orcf A,BC
	nop                                     ; nop
	ldw	iz, 0x29d9
	nop                                     ; nop
	ld	hl, (xde-105)
	nop                                     ; nop
	ld	h, (xbc)
	pushw wa                                ; push WA
	nop                                     ; nop
	ldb	l, 0x00
	jr	f, 0x01
	.byte 0x1a, 0x00, 0x04                 ; jp 0x0400
	nop                                     ; nop
	pushw de                                ; push DE
	orcf_a_16 bc		; orcf A,BC
	nop                                     ; nop
	pushw wa                                ; push WA
	orcf_a_16 bc		; orcf A,BC
	nop                                     ; nop
	ld	hl, (xiz-105)
	nop                                     ; nop
	ld_s	(xwa+39), xwa
	nop                                     ; nop
	call 0x016000
	ldw	iz, 0x0000
	nop                                     ; nop
	.byte 0x1c, 0xd9, 0x29                 ; call 0x29d9
	nop                                     ; nop
	.byte 0x1a, 0xd9, 0x29                 ; jp 0x29d9
	nop                                     ; nop
	adc	xsp, (xiz)
	ldb	c, 0x00
	jr c, .LREC_c141                       ; [67 05] jr C,0x29c141
	pushw wa                                ; push WA
	nop                                     ; nop
	ldw	ix, 0x6000
.LREC_c141:
	.byte 0x01                             ; normal
	pushw de                                ; push DE
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ret

	orcf_a_16 bc		; orcf A,BC
	nop                                     ; nop
	.byte 0x0c                             ; incf
	orcf_a_16 bc		; orcf A,BC
	nop                                     ; nop
	ld	xhl, (xde-105)
	nop                                     ; nop
	ld	xiy, 0x34002806
	nop                                     ; nop
	jr f, .LREC_c15b                       ; [60 01] jr F,0x29c15b
	pushw de                                ; push DE
.LREC_c15b:
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	orcf_a_16 bc		; orcf A,BC
	nop                                     ; nop
	.byte 0xfe                             ; swi 6
	orcf_a_16 wa		; orcf A,WA
	nop                                     ; nop
	ld	xhl, (xiz-105)
	nop                                     ; nop
	push xix
	.byte 0x04                             ; max
	pushw wa                                ; push WA
	nop                                     ; nop
	ldb	e, 0x00
	jr	f, 0x01
	ldb	d, 0x00
	nop                                     ; nop
	nop                                     ; nop
	.byte 0xf0, 0xd8, 0x29                 ; orcf A,(0xd8)
	nop                                     ; nop
	cps	xiz, 0
	pushw bc                                ; push BC
	nop                                     ; nop
	xorcfn_ri xde, 7		; xorcf 7,(XDE)
	ldb	c, 0x00
	ldb	c, 0x07
	pushw wa                                ; push WA
	nop                                     ; nop
	jr gt, .LREC_c188                      ; [6a 00] jr GT,0x29c188
.LREC_c188:
	jr	f, 0x01
	ldb	b, 0x00
	nop                                     ; nop
	nop                                     ; nop
	or	xwa, (0x0029d8)
	orcf_a_16 wa		; orcf A,WA
	nop                                     ; nop
	xorcfn_ri xiz, 7		; xorcf 7,(XIZ)
	ldb	c, 0x00
	.byte 0x54                             ; db
	andcfa_ri xiy		; andcf A,(XIY)
	nop                                     ; nop
	jr z, .LREC_c1a0                       ; [66 00] jr Z,0x29c1a0
.LREC_c1a0:
	jr f, .LREC_c1a3                       ; [60 01] jr F,0x29c1a3
	pushw de                                ; push DE
.LREC_c1a3:
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	.byte 0xd0, 0xd8, 0x29                 ; db
	nop                                     ; nop
	cps	h, 0
	pushw bc                                ; push BC
	nop                                     ; nop
	lda_rid8 xde, 0x97, xhl		; lda HL,XDE+0x97
	nop                                     ; nop
	ldio	205, 40
	nop                                     ; nop
	.byte 0x11                             ; scf
	nop                                     ; nop
	jr f, .LREC_c1bb                       ; [60 01] jr F,0x29c1bb
	pushw iz                                ; push IZ
.LREC_c1bb:
	nop                                     ; nop
	.byte 0x12                             ; ccf
	nop                                     ; nop
	.byte 0xc4, 0xd8, 0x29                 ; db
	nop                                     ; nop
	orcfa_rid8 xix, 0xd8		; orcf A,(XIX+0xd8)
	nop                                     ; nop
	lda_rid8 xiz, 0x97, xhl		; lda HL,XIZ+0x97
	nop                                     ; nop
	jp 0x0028e6                             ; jp 0x0028e6
	ldb	l, 0x00
	jr	f, 0x01
	ldb	w, 0x00
	ldwio	0, 55470
	pushw bc                                ; push BC
	nop                                     ; nop
	ld_s	(xde-40), xbc
	nop                                     ; nop
	.byte 0xda, 0x97                       ; adc SP,DE
	ldb	c, 0x00
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xsp, 0x46006e6e
	ld	xix, 0x656c6946
	.byte 0x53                             ; db
	jr	mi, 0x6c
	jr	mi, 0x63
	jrl	ov, 0x0000
.LREC_d8bc:
	jr	pl, 0x63
	pop xiz                                 ; pop XIZ
	pop xiz                                 ; pop XIZ
	jr	ule, 0x5e
	nop                                     ; nop
	nop                                     ; nop
	popw ix                                 ; pop IX
	jrl	ge, 0x6972
	jr	ule, 0x42
	jr nc, .LREC_d944                      ; [6f 78] jr NC,0x29d944
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xbc, 0x6e614c63
	jr c, .LREC_d94c                       ; [67 75] jr C,0x29d94c
	jr lt, .LREC_d940                      ; [61 67] jr LT,0x29d940
	jr	mi, 0x54
	jr	mi, 0x78
	jrl	ov, 0x0031
	nop                                     ; nop
	nop                                     ; nop
	popw bc                                 ; pop BC
	jrl	z, 0x6353
	jrl	le, 0x6565
	jr nz, .LREC_d93d                      ; [6e 52] jr NZ,0x29d93d
	ldw	de, 0x0000
	nop                                     ; nop
	nop                                     ; nop
	ld	xbc, 0x6e695763
	jr	ov, 0x6f
	jrl	c, 0x6150
	jr c, .LREC_d961                       ; [67 65] jr C,0x29d961
	ldw	bc, 0x0000
	nop                                     ; nop
	.byte 0x54                             ; db
	jrl	ov, 0x536c
	jr	ule, 0x72
	jr	mi, 0x65
	jr nz, .LREC_d95c                      ; [6e 52] jr NZ,0x29d95c
	ldw	hl, 0x0000
	nop                                     ; nop
	.byte 0x54                             ; db
	jrl	ov, 0x536c
	jr	ule, 0x72
	jr	mi, 0x65
	jr nz, .LREC_d96a                      ; [6e 52] jr NZ,0x29d96a
	ldw	de, 0x0000
	nop                                     ; nop
.LREC_d91c:
	popw wa                                 ; pop WA
	ld	xix, 0x6c746954
	jr	mi, 0x4d
	jr	mi, 0x6e
	jrl	mi, 0x6a00
	nop                                     ; nop
	popw bc                                 ; pop BC
	jrl	z, 0x6448
	jr	ov, 0x4e
	jr	lt, 0x6d
	jr	ge, 0x6e
	jr c, .LREC_d936                       ; [67 00] jr C,0x29d936
.LREC_d936:
	nop                                     ; nop
	nop                                     ; nop
	ld	xbc, 0x64644863
.LREC_d93d:
	popw iz                                 ; pop IZ
	jr	lt, 0x6d
.LREC_d940:
	jr	ge, 0x6e
	jr	c, 0x57
.LREC_d944:
	jr	ge, 0x6e
	jr	ov, 0x6f
	jrl c, .LREC_d94b                      ; [77 00 00] jrl C,0x29d94b
.LREC_d94b:
	nop                                     ; nop
.LREC_d94c:
	.byte 0x54                             ; db
	jrl	ov, 0x536c
	jr	ule, 0x72
	jr	mi, 0x65
	jr	nz, 0x52
	nop                                     ; nop
	nop                                     ; nop
	pop xiz                                 ; pop XIZ
	pop xiz                                 ; pop XIZ
	nop                                     ; nop
	nop                                     ; nop
.LREC_d95c:
	ld	xix, 0x6d654d62
.LREC_d961:
	jr	nc, 0x43
	jr	nov, 0x00
.LREC_d965:
	nop                                     ; nop
.LREC_d966:
	jr	ule, 0x5e
	jr	ugt, 0x73
.LREC_d96a:
	ld	xbc, 0x47476e41
	jr	pl, 0x41
.LREC_d971:
	nop                                     ; nop
	.byte 0x53                             ; db
	jr	mi, 0x6c
	jr	mi, 0x63
	jrl	ov, 0x694c
	jrl	ule, 0x0074
	nop                                     ; nop


HDAE5000_RECORD_COUNT:	; 0x29D97E
	; Record count data
	.byte 0x0d
	.byte 0x00
	.asciz "EV_DrawFDText"
	.asciz "EV_InitFDFileSelect"
	.asciz "EV_Scrollline"
	.asciz "EV_Drawsyllable"
	.asciz "EV_Alldraw"
	.byte 0x00
	.asciz "EV_Initlyrics"
	.asciz "EV_SETPOSITION"
	.byte 0x00
	.asciz "EV_BEATMESSAGE"
	.byte 0x00
	.asciz "EV_TICKS"
	.byte 0x00
	.asciz "EV_INITLYRICPARAM"
	.asciz "EV_TimerBack"
	.byte 0x00
	.asciz "EV_AfterLoad"
	.byte 0x00
	.asciz "EV_SeqStop"
	.byte 0x00
	.asciz "MT_FdSaveLyric"
	.byte 0x00
	.asciz "MT_FdLoadLyric"
	.byte 0x00
	.asciz "MT_FdInfo"
	.asciz "MT_FdFreshUp"
	.byte 0x00
	.asciz "MT_SelectDelFile"
	.byte 0x00
	.asciz "MT_SelectDEL"
	.byte 0x00
	.asciz "MT_LOOP"
	.asciz "MT_SetStrAdr"
	.byte 0x00
	.asciz "MT_SelectAll"
	.byte 0x00
	.asciz "MT_SelectSAVE"
	.asciz "MT_SelectOK2"
	.byte 0x00
	.asciz "MT_SelectOK"
	.asciz "MT_AckSelNum"
	.byte 0x00
	.asciz "MT_ReqSelNum"
	.byte 0x00
	.asciz "MT_SetSelNum"
	.byte 0x00
	.asciz "MT_ChangeSelNum"
	.asciz "MT_UnderFlow"
	.byte 0x00
	.asciz "MT_OverFlow"
	.zero 2
	.asciz "FDFileSelectProc"
	.byte 0x00
	.asciz "LyricBoxProc"
	.byte 0x00
	.asciz "AcLanguageText1Proc"
	.asciz "IvScreenR2Proc"
	.byte 0x00
	.asciz "AcWindowPage1Proc"
	.asciz "TtlScreenR3Proc"
	.asciz "TtlScreenR2Proc"
	.asciz "HDTitleMenuProc"
	.asciz "IvHddNamingProc"
	.asciz "AcHddNamingWindowProc"
	.asciz "TtlScreenRProc"
	.byte 0x00
	.asciz "DbMemoClProc"
	.byte 0x00
	.asciz "SelectListProc"
	.byte 0x00
	.byte 0x02
	.byte 0x00

HDAE5000_UI_Descriptors:	; 0x29DC14
	; UI page descriptors and config
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x01
	.byte 0x00
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 3
	.asciz "`"
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xe2, 0x98  ; "â"
	.asciz "#"
	.ascii "<"
	.byte 0xdc  ; "Ü"
	.asciz ")"
	.byte 0x83  ; ""
	.byte 0x00
	.zero 2
	.asciz "HD-AE5000"
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x02
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "H"
	.byte 0x9c  ; ""
	.byte 0x00
	.asciz "a"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0xe6, 0x98  ; "æ"
	.asciz "#"
	.ascii "|"
	.byte 0xdc  ; "Ü"
	.asciz ")"
	.byte 0x13
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0x08
	.zero 3
	.asciz "SETUP & TOOLS  "
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.zero 2
	.byte 0x03
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xa3  ; "£"
	.byte 0x00
	.asciz "r"
	.ascii "7"
	.byte 0x01
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x0a
	.byte 0x00
	.byte 0xe8, 0x98  ; "è"
	.asciz "#"
	.byte 0xc2, 0xdc  ; "ÂÜ"
	.asciz ")"
	.byte 0x8f  ; ""
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0xae  ; "®"
	.byte 0x00
	.zero 4
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x02
	.byte 0x00
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xaa  ; "ª"
	.byte 0x00
	.asciz "r"
	.byte 0x19, 0x01
	.byte 0x91  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x06
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.zero 2
	.byte 0x05
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x0b
	.byte 0x00
	.byte 0xea, 0x98  ; "ê"
	.asciz "#"
	.ascii "$"
	.byte 0xdd  ; "Ý"
	.asciz ")"
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0xaf  ; "¯"
	.byte 0x00
	.zero 4
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x04
	.byte 0x00
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xaa  ; "ª"
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xbb  ; "»"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x07
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.zero 2
	.byte 0x07
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "r"
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x8a  ; ""
	.byte 0x00
	.byte 0xec, 0x98  ; "ì"
	.asciz "#"
	xor	(xiz), e
	.asciz ")"
	.byte 0xff
	.fill 3, 1, 0xff
	.asciz "s"
	.zero 4
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x06
	.byte 0x00
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "$"
	.asciz "r"
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x91  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x03
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.zero 2
	.byte 0x09
	.byte 0x00
	.byte 0x0a
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0xee, 0x98  ; "î"
	.asciz "#"
	cps	xwa, 5
	.asciz ")"
	.byte 0x85  ; ""
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.asciz "!"
	.zero 4
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x08
	.byte 0x00
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "$"
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0xbb  ; "»"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x04
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.zero 2
	.ascii "j"
	.byte 0x01
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x0b
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xbc  ; "¼"
	.byte 0x00
	.byte 0x35
	.byte 0x01
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0xf0, 0x98  ; "ð"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0xf4, 0x98  ; "ô"
	.asciz "#"
	.zero 4
	.byte 0xf6, 0x98  ; "ö"
	.asciz "#"
	.zero 2
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x0c
	.byte 0x00
	.byte 0x0a
	.byte 0x00
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x16
	.byte 0x00
	pushw de
	.byte 0x01
	.asciz ")"
	.ascii "`"
	.byte 0x01
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x0d
	.byte 0x00
	.byte 0x0b
	.byte 0x00
	.byte 0x18
	.byte 0x00
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	.byte 0x00
	.byte 0x0c
	.byte 0x00
	popw de
	.byte 0x01
	.asciz "i"
	.ascii "`"
	.byte 0x01
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x0e
	.byte 0x00
	.byte 0x0c
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "]"
	.byte 0x01
	.byte 0x00
	.asciz "w"
	.byte 0x1b
	.byte 0x00
	.asciz "'"
	.ascii "*"
	.byte 0x01
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.zero 2
	.byte 0x0f
	.byte 0x00
	.byte 0x11
	.byte 0x00
	.byte 0x0d
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xa3  ; "£"
	.byte 0x00
	.asciz "H"
	.ascii "7"
	.byte 0x01
	.asciz "a"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0xf8, 0x98  ; "ø"
	.asciz "#"
	.byte 0xd4, 0xde  ; "ÔÞ"
	.asciz ")"
	.asciz "\""
	.byte 0x7f
	.byte 0x00
	.byte 0xad  ; "­"
	.byte 0x00
	.zero 4
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x0e
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.fill 4, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xaa  ; "ª"
	.byte 0x00
	.asciz "H"
	.byte 0x19, 0x01
	.asciz "g"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x05
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x0f
	.byte 0x00
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xaa  ; "ª"
	.byte 0x00
	.asciz "H"
	.byte 0x19, 0x01
	.asciz "g"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x05
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x12
	.byte 0x00
	.byte 0x0e
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.asciz "7"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xfa, 0x98  ; "ú"
	.asciz "#"
	.ascii "`"
	.byte 0xdf  ; "ß"
	.asciz ")"
	.byte 0xf0  ; "ð"
	.byte 0x02, 0x7f
	.byte 0x00
	.asciz "<"
	.zero 4
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.zero 2
	.fill 4, 1, 0xff
	.byte 0x11
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xaa  ; "ª"
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0xe5  ; "å"
	.byte 0x00
	.asciz "="
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x8a, 0xdf  ; "ß"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00

HDAE5000_UI_Page_Titles:	; 0x29DF8A
	; UI page title strings
	.asciz "LYRICS WINDOW"
	.byte 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x14
	.byte 0x00
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x7f
	.byte 0x00
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xfc, 0x98  ; "ü"
	.asciz "#"
	.byte 0xc2, 0xdf  ; "Âß"
	.asciz ")"
	.byte 0x08
	.zero 3
	.asciz " SETUP & TOOLS "
	.asciz "I"
	.ascii "`"
	.byte 0x01, 0x13
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x15
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.zero 3
	.byte 0x7f
	.byte 0x00
	.asciz "("
	.ascii "`"
	.byte 0x01, 0x13
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x16
	.byte 0x00
	.byte 0x14
	.byte 0x00
	.byte 0x18
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.asciz ">"
	.asciz "="
	.byte 0x02
	.byte 0x00
	.asciz "z"
	.byte 0x7f
	.byte 0x00
	.asciz "("
	.ascii "`"
	.byte 0x01, 0x13
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x17
	.byte 0x00
	.byte 0x15
	.byte 0x00
	.byte 0x18
	.zero 3
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.asciz ">"
	.byte 0x01
	.byte 0x00
	.asciz "n"
	.byte 0x7f
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x13
	.byte 0x00
	.fill 4, 1, 0xff
	.byte 0x16
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x3b
	.byte 0x01, 0x17
	.byte 0x00
	.byte 0xf3  ; "ó"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x00
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x19
	.byte 0x00
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x7f
	.byte 0x00
	.byte 0xa0  ; " "
	.byte 0x01, 0x02
	.byte 0x99  ; ""
	.asciz "#"
	.ascii "r"
	.byte 0xe0  ; "à"
	.asciz ")"
	.zero 6
	.asciz "I"
	.ascii "`"
	.byte 0x01, 0x18
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x1a
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.asciz "\""
	.byte 0x7f
	.byte 0x00
	.asciz "("
	.ascii "`"
	.byte 0x01, 0x18
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x1b
	.byte 0x00
	.byte 0x19
	.byte 0x00
	.byte 0x18
	.zero 3
	.asciz " "
	.byte 0x1f
	.byte 0x00
	.asciz "?"
	.byte 0x01
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.asciz "("
	.ascii "`"
	.byte 0x01, 0x18
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x1c
	.byte 0x00
	.byte 0x1a
	.byte 0x00
	.byte 0x18
	.zero 3
	.asciz "@"
	.byte 0x1f
	.byte 0x00
	.asciz "_"
	.byte 0x02
	.byte 0x00
	.byte 0x10, 0x01, 0x7f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x18
	.byte 0x00
	.byte 0x1d
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.asciz "$"
	.ascii "7"
	.byte 0x01
	.asciz "="
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x08
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x1c
	.byte 0x00
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0e, 0x01
	.asciz "("
	.ascii "1"
	.byte 0x01
	.asciz ":"
	.byte 0x0e
	.byte 0xe1  ; "á"
	.asciz ")"
	.zero 6
	.asciz "LOAD"
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01, 0x18
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x1f
	.byte 0x00
	.byte 0x1c
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.asciz "("
	.ascii "9"
	.byte 0x01
	.asciz "O"
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "0"
	.ascii "`"
	.byte 0x01, 0x18
	.byte 0x00
	.fill 2, 1, 0xff
	.asciz " "
	.byte 0x1e
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x36
	.byte 0x01
	.asciz "M"
	.ascii "?"
	.byte 0x01
	.asciz "]"
	.ascii "V"
	.byte 0xe1  ; "á"
	.asciz ")"
	.zero 4
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x09
	.zero 3
	.ascii " "
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "~80"
	.asciz ")"
	.ascii "`"
	.byte 0x01, 0x18
	.byte 0x00
	.fill 2, 1, 0xff
	.asciz "!"
	.byte 0x1f
	.byte 0x00
	.byte 0x18
	.zero 3
	.asciz "`"
	.byte 0x1f
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0x0d
	.byte 0x00
	popw de
	.byte 0x01, 0x08
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x18
	.byte 0x00
	.fill 4, 1, 0xff
	.asciz " "
	.byte 0x08
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x3b
	.byte 0x01, 0x17
	.byte 0x00
	.byte 0xf3  ; "ó"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x06
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "#"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01, 0x08
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0xc2, 0xe1  ; "Âá"
	.asciz ")"
	.byte 0xad  ; "­"
	.byte 0x00
	.zero 2
	.asciz "HD DIR SELECT"
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.byte 0xff
	.asciz "$"
	.byte 0xff
	.byte 0xff
	.byte 0x08
	.byte 0x00
	.asciz "T"
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 10
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.asciz ")"
	.ascii "`"
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.byte 0xff
	.asciz "%"
	.asciz "#"
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x01
	.byte 0x00
	popw de
	.byte 0x01
	.zero 2
	.ascii "j"
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.byte 0xff
	.asciz "&"
	.asciz "$"
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "#"
	.byte 0x07, 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.zero 2
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	popw de
	.byte 0x01, 0x0c
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x02
	.byte 0x00
	.byte 0x0c
	.byte 0x00
	.byte 0x10
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x12
	.byte 0x99  ; ""
	.asciz "#"
	.zero 2
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.byte 0xff
	.asciz "'"
	.asciz "%"
	.byte 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0x3e
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.ascii "|"
	.byte 0xe2  ; "â"
	.asciz ")"
	.asciz "97-120"
	.byte 0x00
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.byte 0xff
	.asciz "("
	.asciz "&"
	.byte 0x08
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.asciz "&"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 7
	.byte 0xb0, 0xe2  ; "°â"
	.asciz ")"
	.asciz "01-24"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.byte 0xff
	.asciz ")"
	.asciz "'"
	.byte 0x08
	.byte 0x00
	.asciz "+"
	.byte 0xde  ; "Þ"
	.byte 0x00
	.asciz "P"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.byte 0xe2, 0xe2  ; "ââ"
	.asciz ")"
	.asciz "25-48"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.byte 0xff
	.asciz "*"
	.asciz "("
	.byte 0x08
	.byte 0x00
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.byte 0x14
	.byte 0xe3  ; "ã"
	.asciz ")"
	.asciz "49-72"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.byte 0xff
	.asciz "+"
	.asciz ")"
	.byte 0x08
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0x15, 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.ascii "F"
	.byte 0xe3  ; "ã"
	.asciz ")"
	.asciz "73-96"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.byte 0xff
	.asciz ","
	.asciz "*"
	.byte 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.asciz "$"
	.ascii "7"
	.byte 0x01
	.asciz "="
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x08
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.asciz ","
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0f, 0x01
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x32
	.byte 0x01
	.byte 0xdc  ; "Ü"
	.byte 0x00
	or	hl, (xix)
	.asciz ")"
	.zero 6
	.asciz "EDIT"
	.byte 0x00
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.byte 0xff
	.asciz "/"
	.asciz ","
	.byte 0x18
	.byte 0x00
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	.zero 3
	.byte 0x7f
	.byte 0x00
	.asciz "0"
	.ascii "`"
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.byte 0xff
	.asciz "0"
	.asciz "."
	.byte 0x08
	.byte 0x00
	.byte 0x36
	.byte 0x01
	.asciz "M"
	.ascii "?"
	.byte 0x01
	.asciz "_"
	or	hl, ix
	.asciz ")"
	.zero 4
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x09
	.zero 3
	.ascii " "
	.byte 0x01, 0x06
	.byte 0x00
	.asciz "~80"
	.asciz "."
	.ascii "`"
	.byte 0x01
	.asciz "\""
	.byte 0xff
	.fill 3, 1, 0xff
	.asciz "/"
	.byte 0x08
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.asciz "("
	.ascii "9"
	.byte 0x01
	.asciz "O"
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "2"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01, 0x14
	.byte 0x99  ; ""
	.asciz "#"
	.ascii "$"
	.byte 0xe4  ; "ä"
	.asciz ")"
	.byte 0x83  ; ""
	.byte 0x00
	.zero 2
	.asciz " DIRECTORY SELECT   "
	.byte 0x00
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.asciz "1"
	.asciz "3"
	.asciz "4"
	.byte 0xff
	.byte 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0a, 0x01
	.asciz "&"
	.ascii "7"
	.byte 0x01
	.asciz "="
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x08
	.byte 0x00
	.byte 0x18
	.byte 0x99  ; ""
	.asciz "#"
	.ascii "p"
	.byte 0xe4  ; "ä"
	.asciz ")"
	.byte 0x18
	.byte 0x00
	.byte 0x7f
	.zero 7
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.asciz "2"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x16, 0x01
	.asciz "*"
	.ascii ")"
	.byte 0x01
	.asciz "<"
	or	ix, (xde)
	.asciz ")"
	.zero 6
	.asciz "OK"
	.byte 0x00
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.asciz "1"
	.byte 0xff
	.byte 0xff
	.asciz "5"
	.asciz "2"
	.byte 0x08
	.byte 0x00
	.asciz "T"
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 9
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.asciz "1"
	.byte 0xff
	.byte 0xff
	.asciz "6"
	.asciz "4"
	.byte 0x08
	.byte 0x00
	.asciz ","
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.asciz "K"
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x0f
	.byte 0x00
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.asciz "1"
	.asciz "7"
	.asciz "8"
	.asciz "5"
	.byte 0x08
	.byte 0x00
	.byte 0x0a, 0x01
	.asciz "M"
	.ascii "1"
	.byte 0x01
	.asciz "l"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x09
	.byte 0x00
	.byte 0x1a
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x1e
	.byte 0xe5  ; "å"
	.asciz ")"
	.byte 0x18
	.byte 0x00
	.byte 0x7f
	.zero 7
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.asciz "6"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x16, 0x01
	.asciz "*"
	.ascii ")"
	.byte 0x01
	.asciz "<"
	.ascii "@"
	.byte 0xe5  ; "å"
	.asciz ")"
	.zero 6
	.asciz "OK"
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.asciz "1"
	.byte 0xff
	.byte 0xff
	.asciz "9"
	.asciz "6"
	.byte 0x08
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.asciz ","
	.ascii "9"
	.byte 0x01
	.asciz "S"
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.asciz "1"
	.byte 0xff
	.fill 3, 1, 0xff
	.asciz "8"
	.byte 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz ";"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x7f
	.byte 0x00
	.byte 0xa0  ; " "
	.byte 0x01, 0x1c
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0xb0, 0xe5  ; "°å"
	.asciz ")"
	.byte 0x83  ; ""
	.byte 0x00
	.zero 2
	.asciz " FD FILE SELECT   "
	.byte 0x00
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.asciz ":"
	.asciz "<"
	.asciz "="
	.byte 0xff
	.byte 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0a, 0x01
	.asciz "&"
	.ascii "7"
	.byte 0x01
	.asciz "="
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x08
	.byte 0x00
	.ascii " "
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0xfa, 0xe5  ; "úå"
	.asciz ")"
	.byte 0x18
	.byte 0x00
	.byte 0x7f
	.zero 7
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.asciz ";"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0e, 0x01
	.asciz ")"
	.ascii "1"
	.byte 0x01
	.asciz ";"
	.byte 0x1c
	.byte 0xe6  ; "æ"
	.asciz ")"
	.zero 6
	.asciz "COPY"
	.byte 0x00
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.asciz ":"
	.byte 0xff
	.byte 0xff
	.asciz ">"
	.asciz ";"
	.byte 0x08
	.byte 0x00
	.asciz "T"
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 9
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.asciz ":"
	.byte 0xff
	.byte 0xff
	.asciz "?"
	.asciz "="
	.byte 0x08
	.byte 0x00
	.asciz ","
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.asciz "K"
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x0f
	.byte 0x00
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.asciz ":"
	.byte 0xff
	.byte 0xff
	.asciz "@"
	.asciz ">"
	.byte 0x08
	.byte 0x00
	.byte 0x0a, 0x01
	.asciz "M"
	.ascii "1"
	.byte 0x01
	.asciz "l"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x09
	.byte 0x00
	.byte 0x22
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0xaa, 0xe6  ; "ªæ"
	.asciz ")"
	.byte 0x18
	.byte 0x00
	.byte 0x7f
	.zero 7
	.asciz "."
	.ascii "`"
	.byte 0x01
	.asciz ":"
	.byte 0xff
	.byte 0xff
	.asciz "A"
	.asciz "?"
	.byte 0x08
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.asciz ","
	.ascii "9"
	.byte 0x01
	.asciz "S"
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.asciz ":"
	.byte 0xff
	.byte 0xff
	.asciz "B"
	.asciz "@"
	.byte 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.asciz ":"
	.asciz "C"
	.asciz "D"
	.asciz "A"
	.byte 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x04
	.zero 9
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.asciz "B"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xfe  ; "þ"
	.byte 0x00
	.byte 0xdd  ; "Ý"
	.byte 0x00
	.byte 0x31
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x38
	.byte 0xe7  ; "ç"
	.asciz ")"
	.zero 6
	.asciz "SELECT"
	.zero 3
	.ascii "j"
	.byte 0x01
	.asciz ":"
	.byte 0xff
	.fill 3, 1, 0xff
	.asciz "B"
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz "4"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xcf  ; "Ï"
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0x01
	.zero 5
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0x24
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x02
	.byte 0x00
	.byte 0x0a
	.byte 0x00
	pushw wa
	.byte 0x99  ; ""
	.asciz "#"
	.zero 4
	.ascii "*"
	.byte 0x99  ; ""
	.asciz "#"
	.zero 2
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "F"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	pushw ix
	.byte 0x99  ; ""
	.asciz "#"
	or	xsp, (xiz)
	.asciz ")"
	.byte 0x83  ; ""
	.byte 0x00
	.zero 2
	.asciz "HARDWARE TEST"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.asciz "E"
	.asciz "G"
	.asciz "H"
	.byte 0xff
	.byte 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.zero 3
	.byte 0x7f
	.byte 0x00
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.asciz "F"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.zero 3
	.ascii "*"
	.byte 0x01
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.asciz "E"
	.byte 0xff
	.byte 0xff
	.asciz "I"
	.asciz "F"
	.byte 0x18
	.byte 0x00
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	.zero 3
	.byte 0x7f
	.byte 0x00
	.asciz "&"
	.ascii "`"
	.byte 0x01
	.asciz "E"
	.byte 0xff
	.byte 0xff
	.asciz "J"
	.asciz "H"
	.byte 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xdb  ; "Û"
	.byte 0x00
	.zero 4
	.ascii "."
	.byte 0xe8  ; "è"
	.asciz ")"
	.ascii "*"
	.byte 0xe8  ; "è"
	.asciz ")"
	.ascii "0"
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x0c
	.byte 0x00
	.asciz "RUN"
	.asciz "STOP"
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.asciz "E"
	.byte 0xff
	.byte 0xff
	.asciz "K"
	.asciz "I"
	.byte 0x08
	.zero 3
	.asciz " "
	.byte 0xe6  ; "æ"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.zero 2
	.byte 0xff
	.byte 0x00
	.asciz "&"
	.ascii "`"
	.byte 0x01
	.asciz "E"
	.byte 0xff
	.byte 0xff
	.asciz "L"
	.asciz "J"
	.byte 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.asciz "L"
	.ascii "7"
	.byte 0x01
	.asciz "]"
	.zero 4
	.ascii "|"
	.byte 0xe8  ; "è"
	.asciz ")"
	.ascii "v"
	.byte 0xe8  ; "è"
	.asciz ")"
	.ascii "2"
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x09
	.byte 0x00
	.asciz "PPORT"
	.asciz "PPORT"
	.asciz "&"
	.ascii "`"
	.byte 0x01
	.asciz "E"
	.byte 0xff
	.byte 0xff
	.asciz "M"
	.asciz "K"
	.byte 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb1  ; "±"
	.byte 0x00
	.zero 4
	.byte 0xae, 0xe8  ; "®è"
	.asciz ")"
	.byte 0xaa, 0xe8  ; "ªè"
	.asciz ")"
	.ascii "4"
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x0b
	.byte 0x00
	.asciz "FD"
	.byte 0x00
	.asciz "FD"
	.byte 0x00
	.asciz "&"
	.ascii "`"
	.byte 0x01
	.asciz "E"
	.byte 0xff
	.fill 3, 1, 0xff
	.asciz "L"
	.byte 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.asciz "v"
	.ascii "7"
	.byte 0x01
	.byte 0x87  ; ""
	.byte 0x00
	.zero 4
	.byte 0xde, 0xe8  ; "Þè"
	.asciz ")"
	.byte 0xda, 0xe8  ; "Úè"
	.asciz ")"
	.ascii "6"
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x0a
	.byte 0x00
	.asciz "HDD"
	.asciz "HDD"
	.byte 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "O"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x7f
	.byte 0x00
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x38
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x0c
	.byte 0xe9  ; "é"
	.asciz ")"
	.byte 0xad  ; "­"
	.byte 0x00
	.zero 2
	.asciz "EDIT FILE NAME"
	.byte 0x00
	.asciz ")"
	.ascii "`"
	.byte 0x01
	.asciz "N"
	.byte 0xff
	.byte 0xff
	.asciz "P"
	.byte 0xff
	.byte 0xff
	.byte 0x18
	.byte 0x00
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	.byte 0x00
	.byte 0x03
	.byte 0x00
	popw de
	.byte 0x01
	.asciz " "
	.ascii "`"
	.byte 0x01
	.asciz "N"
	.byte 0xff
	.byte 0xff
	.asciz "Q"
	.asciz "O"
	.byte 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb1  ; "±"
	.byte 0x00
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x0b
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x01
	.byte 0x00
	pushw de
	.byte 0x01
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.asciz "N"
	.byte 0xff
	.byte 0xff
	.asciz "R"
	.asciz "P"
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x18
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.asciz " "
	.ascii "`"
	.byte 0x01
	.asciz "N"
	.asciz "S"
	.asciz "T"
	.asciz "Q"
	.byte 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.asciz "v"
	.ascii "7"
	.byte 0x01
	.byte 0x87  ; ""
	.byte 0x00
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x0a
	.zero 3
	.byte 0x01
	.byte 0x00
	pushw de
	.byte 0x01
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.asciz "R"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1a, 0x01
	.asciz "w"
	.ascii "5"
	.byte 0x01
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0xc8, 0xe9  ; "Èé"
	.asciz ")"
	.zero 6
	.asciz "OPT"
	.byte 0x04
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.asciz "N"
	.byte 0xff
	.byte 0xff
	.asciz "U"
	.asciz "R"
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x01
	.byte 0x00
	pushw de
	.byte 0x01
	.asciz " "
	.ascii "`"
	.byte 0x01
	.asciz "N"
	.asciz "V"
	.byte 0xff
	.byte 0xff
	.asciz "T"
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "v"
	.asciz "&"
	.byte 0x87  ; ""
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x8a  ; ""
	.byte 0x00
	.zero 2
	.byte 0x01
	.byte 0x00
	pushw de
	.byte 0x01
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.asciz "U"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.asciz "w"
	.asciz "$"
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0x32
	.byte 0xea  ; "ê"
	.asciz ")"
	.zero 4
	.byte 0xf9  ; "ù"
	.byte 0x00
	.asciz "LST"
	.asciz "K"
	.ascii "`"
	.byte 0x01
	.fill 8, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz "`"
	.byte 0x0b, 0x01
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.zero 2
	.ascii "<"
	.byte 0x99  ; ""
	.asciz "#"
	.ascii "@"
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "Y"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x7f
	.byte 0x00
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x44
	.byte 0x99  ; ""
	.asciz "#"
	or	(xix), b
	.asciz ")"
	.byte 0xad  ; "­"
	.byte 0x00
	.zero 2
	.asciz "EDIT DIRECTORY NAME"
	.asciz "M"
	.ascii "`"
	.byte 0x01
	.asciz "X"
	.byte 0xff
	.byte 0xff
	.asciz "Z"
	.byte 0xff
	.byte 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x02
	.byte 0x00
	pushw de
	.byte 0x01
	.asciz " "
	.ascii "`"
	.byte 0x01
	.asciz "X"
	.byte 0xff
	.byte 0xff
	.asciz "["
	.asciz "Y"
	.byte 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb1  ; "±"
	.byte 0x00
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x0b
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x02
	.byte 0x00
	pushw de
	.byte 0x01
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.asciz "X"
	.byte 0xff
	.byte 0xff
	.asciz "\\"
	.asciz "Z"
	.byte 0x18
	.zero 3
	.asciz " "
	.byte 0x1f
	.byte 0x00
	.asciz "?"
	.asciz "\""
	.byte 0x7f
	.byte 0x00
	.asciz " "
	.ascii "`"
	.byte 0x01
	.asciz "X"
	.asciz "]"
	.byte 0xff
	.byte 0xff
	.asciz "["
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "v"
	.asciz "&"
	.byte 0x87  ; ""
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x8a  ; ""
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	pushw de
	.byte 0x01
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.asciz "\\"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.asciz "w"
	.asciz "$"
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0x44
	.byte 0xeb  ; "ë"
	.asciz ")"
	.zero 4
	.byte 0xf9  ; "ù"
	.byte 0x00
	.asciz "LST"
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "_"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "<"
	.asciz "T"
	.byte 0x03, 0x01
	.byte 0x83  ; ""
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.zero 2
	.ascii "H"
	.byte 0x99  ; ""
	.asciz "#"
	.ascii "L"
	.byte 0x99  ; ""
	.asciz "#"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.asciz "^"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "n"
	.asciz "b"
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.asciz "t"
	.byte 0x8c, 0xeb  ; "ë"
	.asciz ")"
	.zero 6
	.asciz "PLEASE WAIT!"
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "a"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x50
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0xc4, 0xeb  ; "Äë"
	.asciz ")"
	.byte 0x83  ; ""
	.byte 0x00
	.zero 2
	.asciz "HD UTILITY"
	.byte 0x00
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.asciz "`"
	.byte 0xff
	.byte 0xff
	.asciz "b"
	.byte 0xff
	.byte 0xff
	.byte 0x18
	.byte 0x00
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	.byte 0x00
	.byte 0x13
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.asciz "`"
	.byte 0xff
	.byte 0xff
	.asciz "c"
	.asciz "a"
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x03
	.byte 0x00
	pushw de
	.byte 0x01
	.asciz "F"
	.ascii "`"
	.byte 0x01
	.asciz "`"
	.byte 0xff
	.byte 0xff
	.asciz "d"
	.asciz "b"
	.byte 0x08
	.zero 3
	.asciz " "
	.byte 0xaa  ; "ª"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.asciz "="
	.ascii "`"
	.byte 0x01
	.asciz "`"
	.byte 0xff
	.byte 0xff
	.asciz "e"
	.asciz "c"
	.byte 0x08
	.byte 0x00
	.byte 0xa3  ; "£"
	.byte 0x00
	.asciz "H"
	.ascii "7"
	.byte 0x01
	.asciz "a"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x09
	.byte 0x00
	.byte 0x54
	.byte 0x99  ; ""
	.asciz "#"
	.ascii "L"
	.byte 0xec  ; "ì"
	.asciz ")"
	.byte 0x83  ; ""
	.byte 0x00
	.zero 2
	.asciz "FORMAT"
	.byte 0x00
	.asciz "="
	.ascii "`"
	.byte 0x01
	.asciz "`"
	.byte 0xff
	.fill 3, 1, 0xff
	.asciz "d"
	.byte 0x08
	.byte 0x00
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x0b
	.byte 0x00
	.byte 0x56
	.byte 0x99  ; ""
	.asciz "#"
	or	(xiz), d
	.asciz ")"
	.byte 0x83  ; ""
	.byte 0x00
	.zero 2
	.asciz "READ ID"
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "g"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	pop xwa
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0xb8, 0xec  ; "¸ì"
	.asciz ")"
	.zero 4
	.asciz "   PC DATA LINK"
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.asciz "f"
	.byte 0xff
	.byte 0xff
	.asciz "h"
	.byte 0xff
	.byte 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x04
	.byte 0x00
	pushw de
	.byte 0x01
	.zero 2
	.ascii "j"
	.byte 0x01
	.asciz "f"
	.byte 0xff
	.byte 0xff
	.asciz "i"
	.asciz "g"
	.byte 0x08
	.byte 0x00
	.byte 0x14
	.byte 0x00
	.asciz "T"
	.ascii "+"
	.byte 0x01
	.byte 0x83  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	pop xix
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x60
	.byte 0x99  ; ""
	.asciz "#"
	.zero 4
	.ascii "b"
	.byte 0x99  ; ""
	.asciz "#"
	.zero 2
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.asciz "f"
	.asciz "j"
	.asciz "k"
	.asciz "h"
	.byte 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.asciz "i"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xfe  ; "þ"
	.byte 0x00
	.byte 0xdb  ; "Û"
	.byte 0x00
	.byte 0x31
	.byte 0x01
	.byte 0xed  ; "í"
	.byte 0x00
	.ascii "h"
	.byte 0xed  ; "í"
	.asciz ")"
	.zero 6
	.asciz "CANCEL"
	.byte 0x00
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.asciz "f"
	.asciz "l"
	.asciz "m"
	.asciz "i"
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 10
	.byte 0x01
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.asciz "k"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x12
	.byte 0x00
	.byte 0xdb  ; "Û"
	.byte 0x00
	.asciz "="
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0xba, 0xed  ; "ºí"
	.asciz ")"
	.zero 6
	.asciz "START"
	.asciz "i"
	.ascii "`"
	.byte 0x01
	.asciz "f"
	.byte 0xff
	.fill 3, 1, 0xff
	.asciz "k"
	.byte 0x08
	.byte 0x00
	.asciz "L"
	.byte 0x01
	.byte 0x00
	.asciz "f"
	.byte 0x1b
	.byte 0x00
	.asciz "'"
	.ascii "*"
	.byte 0x01
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "o"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "@"
	.asciz "Z"
	.byte 0x1a, 0x01
	.byte 0xbd  ; "½"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 4
	.ascii "d"
	.byte 0x99  ; ""
	.asciz "#"
	.ascii "h"
	.byte 0x99  ; ""
	.asciz "#"
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.asciz "n"
	.asciz "p"
	.asciz "q"
	.byte 0xff
	.byte 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x0b
	.byte 0x00
	.ascii "l"
	.byte 0x99  ; ""
	.asciz "#"
	.ascii "4"
	.byte 0xee  ; "î"
	.asciz ")"
	.asciz "f"
	.byte 0x7f
	.byte 0x00
	.byte 0x83  ; ""
	.byte 0x00
	.zero 2
	.asciz "PC DATA LINK"
	.byte 0x00
	.asciz "i"
	.ascii "`"
	.byte 0x01
	.asciz "o"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1b, 0x01
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0x35
	.byte 0x01
	.byte 0xb5  ; "µ"
	.byte 0x00
	.asciz "'"
	.ascii "*"
	.byte 0x01
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.asciz "n"
	.byte 0xff
	.byte 0xff
	.asciz "r"
	.asciz "o"
	.byte 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 10
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.asciz "n"
	.asciz "s"
	.asciz "t"
	.asciz "q"
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "H"
	.byte 0xa3  ; "£"
	.byte 0x00
	.asciz "a"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 4
	.byte 0xc0, 0xee  ; "Àî"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.ascii "n"
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x11
	.byte 0x00
	pushw de
	.byte 0x01
	.ascii "p"
	.byte 0x99  ; ""
	.asciz "#"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.asciz "r"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "H"
	.byte 0x80  ; ""
	.byte 0x00
	.asciz "g"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x08
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.asciz "n"
	.byte 0xff
	.byte 0xff
	.asciz "u"
	.asciz "r"
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 4
	.ascii "&"
	.byte 0xef  ; "ï"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.ascii "t"
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x13
	.byte 0x00
	pushw de
	.byte 0x01
	.ascii "v"
	.byte 0x99  ; ""
	.asciz "#"
	.asciz "QUICK LD MODE:"
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.asciz "n"
	.byte 0xff
	.byte 0xff
	.asciz "v"
	.asciz "t"
	.byte 0x08
	.byte 0x00
	.byte 0xa3  ; "£"
	.byte 0x00
	.asciz "H"
	.ascii "7"
	.byte 0x01
	.asciz "a"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 4
	.ascii "p"
	.byte 0xef  ; "ï"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.ascii "z"
	.byte 0x99  ; ""
	.asciz "#"
	.byte 0x15
	.byte 0x00
	pushw de
	.byte 0x01
	.byte 0x7c
	.byte 0x99  ; ""
	.asciz "#"
	.asciz "JUMP AFTER LD.:"
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.asciz "n"
	.asciz "w"
	.asciz "x"
	.asciz "u"
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "r"
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 4
	.byte 0xba, 0xef  ; "ºï"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x8a  ; ""
	.byte 0x00
	.byte 0x01
	.byte 0x00
	adc	(xwa), a
	.asciz "#"
	.byte 0x12
	.byte 0x00
	pushw de
	.byte 0x01
	adc	(xde), a
	.asciz "#"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.asciz "v"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "r"
	.byte 0x80  ; ""
	.byte 0x00
	.byte 0x91  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x09
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.asciz "n"
	.byte 0xff
	.byte 0xff
	.asciz "y"
	.asciz "v"
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0xdf  ; "ß"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 4
	.ascii " "
	.byte 0xf0  ; "ð"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x8c  ; ""
	.byte 0x00
	.byte 0x01
	.byte 0x00
	adc	(xiz), a
	.asciz "#"
	.byte 0x14
	.byte 0x00
	pushw de
	.byte 0x01
	.byte 0x88, 0x99  ; ""
	.asciz "#"
	.asciz "LD BY NUM. M.:"
	.byte 0x00
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.asciz "n"
	.byte 0xff
	.fill 3, 1, 0xff
	.asciz "x"
	.byte 0x08
	.byte 0x00
	.byte 0xa3  ; "£"
	.byte 0x00
	.asciz "r"
	.ascii "7"
	.byte 0x01
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x0a
	.byte 0x00
	.byte 0x8c, 0x99  ; ""
	.asciz "#"
	.ascii "f"
	.byte 0xf0  ; "ð"
	.asciz ")"
	.byte 0x0c, 0x03, 0x7f
	.byte 0x00
	.asciz "<"
	.zero 2
	.asciz "LYRICS OPTIONS"
	.byte 0x00
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "{"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "<"
	.asciz "T"
	.byte 0x03, 0x01
	.byte 0x83  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 4
	.byte 0x8e, 0x99  ; ""
	.asciz "#"
	adc	(xde), bc
	.asciz "#"
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.asciz "z"
	.asciz "|"
	.asciz "}"
	.byte 0xff
	.byte 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0xdf  ; "ß"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x8c  ; ""
	.byte 0x00
	adc	(xiz), bc
	.asciz "#"
	.byte 0xd0, 0xf0  ; "Ðð"
	.asciz ")"
	.byte 0xff
	.fill 3, 1, 0xff
	.zero 6
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.asciz "{"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0x81  ; ""
	.byte 0x00
	.byte 0xe5  ; "å"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x0b
	.zero 9
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.asciz "z"
	.asciz "~"
	.byte 0x7f
	.byte 0x00
	.asciz "{"
	.byte 0x08
	.byte 0x00
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xdf  ; "ß"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x0c
	.byte 0x00
	.byte 0x98, 0x99  ; ""
	.asciz "#"
	.ascii "2"
	.byte 0xf1  ; "ñ"
	.asciz ")"
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x01
	.zero 3
	.asciz "HD-AE INFOS  "
	.asciz "i"
	.ascii "`"
	.byte 0x01
	.asciz "}"
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1b, 0x01
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0x35
	.byte 0x01
	.byte 0xdf  ; "ß"
	.byte 0x00
	.asciz "'"
	.ascii "*"
	.byte 0x01
	.asciz ")"
	.ascii "`"
	.byte 0x01
	.asciz "z"
	.byte 0xff
	.byte 0xff
	.byte 0x80  ; ""
	.byte 0x00
	.asciz "}"
	.byte 0x18
	.zero 3
	.asciz "@"
	.byte 0x1f
	.byte 0x00
	.asciz "_"
	.byte 0x04
	.byte 0x00
	popw de
	.byte 0x01
	.asciz "! HD FORMAT !"
	.asciz "i"
	.ascii "`"
	.byte 0x01
	.byte 0x80  ; ""
	.byte 0x00
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1b, 0x01
	.asciz "G"
	.ascii "5"
	.byte 0x01
	.asciz "a"
	.asciz "'"
	.ascii "*"
	.byte 0x01
	.asciz "A"
	.ascii "`"
	.byte 0x01
	.asciz "z"
	.byte 0x83  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x80  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x0b
	.byte 0x00
	.byte 0x9c, 0x99  ; ""
	.asciz "#"
	.byte 0xd2, 0xf1  ; "Òñ"
	.asciz ")"
	.byte 0x81  ; ""
	.byte 0x02, 0x7f
	.byte 0x00
	.byte 0x01
	.zero 5
	.asciz "i"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x84  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1b, 0x01
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0x35
	.byte 0x01
	.byte 0xb5  ; "µ"
	.byte 0x00
	.asciz "'"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x83  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xa9  ; "©"
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x25
	.byte 0x01
	.byte 0xbb  ; "»"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x0a
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x86  ; ""
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x9e, 0x99  ; ""
	.asciz "#"
	.ascii "B"
	.byte 0xf2  ; "ò"
	.asciz ")"
	.asciz "!"
	.zero 2
	.asciz "OUTPUT SETTING"
	.byte 0x00
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0x85  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x87  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.zero 3
	.byte 0x7f
	.byte 0x00
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.byte 0x85  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x88  ; ""
	.byte 0x00
	.byte 0x86  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 10
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x85  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0x87  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x0c
	.byte 0x00
	.asciz "H"
	.ascii "7"
	.byte 0x01
	.asciz "a"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 4
	.byte 0xd0, 0xf2  ; "Ðò"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0x01
	.byte 0x00
	adc	(xde), xbc
	.asciz "#"
	.byte 0x05
	.byte 0x00
	pushw de
	.byte 0x01
	adc	(xix), xbc
	.asciz "#"
	.zero 2
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x85  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x8a  ; ""
	.byte 0x00
	.byte 0x88  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x0c
	.byte 0x00
	.asciz "r"
	.ascii "7"
	.byte 0x01
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 4
	.byte 0x0c
	.byte 0xf3  ; "ó"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x8a  ; ""
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xa8, 0x99  ; "¨"
	.asciz "#"
	.asciz "<"
	.ascii "*"
	.byte 0x01
	.byte 0xaa, 0x99  ; "ª"
	.asciz "#"
	.zero 2
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x85  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x0c
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 4
	.ascii "H"
	.byte 0xf3  ; "ó"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xae, 0x99  ; "®"
	.asciz "#"
	.asciz "="
	.ascii "*"
	.byte 0x01
	ldcfm	1, (xwa)
	.asciz "#"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x85  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x8c  ; ""
	.byte 0x00
	.byte 0x8a  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x0c
	.byte 0x00
	.asciz "H"
	.byte 0xc9  ; "É"
	.byte 0x00
	.asciz "g"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x0d
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x85  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x8d  ; ""
	.byte 0x00
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x0c
	.byte 0x00
	.asciz "r"
	.byte 0x07, 0x01
	.byte 0x91  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x0e
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x85  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x8e  ; ""
	.byte 0x00
	.byte 0x8c  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x0c
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x07, 0x01
	.byte 0xbb  ; "»"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x0f
	.zero 5
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x85  ; ""
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x8d  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0xb8  ; "¸"
	.byte 0x00
	.byte 0xe6  ; "æ"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x10
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0xf1  ; "ñ"
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x90  ; ""
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	ldcfm	1, (xix)
	.asciz "#"
	.byte 0x1c
	.byte 0xf4  ; "ô"
	.asciz ")"
	.byte 0xae  ; "®"
	.byte 0x00
	.zero 2
	.asciz "LOAD BY NUMBER"
	.byte 0x00
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0x8f  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x91  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.zero 3
	.byte 0x7f
	.byte 0x00
	.asciz "("
	.ascii "`"
	.byte 0x01
	.byte 0x8f  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x92  ; ""
	.byte 0x00
	.byte 0x90  ; ""
	.byte 0x00
	.byte 0x18
	.zero 3
	.asciz " "
	.byte 0x1f
	.byte 0x00
	.asciz "?"
	.byte 0x01
	.byte 0x00
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.asciz "("
	.ascii "`"
	.byte 0x01
	.byte 0x8f  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x93  ; ""
	.byte 0x00
	.byte 0x91  ; ""
	.byte 0x00
	.byte 0x18
	.byte 0x00
	.asciz " "
	.asciz " "
	.asciz "?"
	.asciz "?"
	.byte 0x02
	.byte 0x00
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x8f  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x94  ; ""
	.byte 0x00
	.byte 0x92  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x3b
	.byte 0x01, 0x17
	.byte 0x00
	.byte 0xf3  ; "ó"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xb8, 0x99  ; "¸"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0x8f  ; ""
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x93  ; ""
	.byte 0x00
	.byte 0x18
	.byte 0x00
	.asciz "@"
	.asciz " "
	.asciz "_"
	.asciz "?"
	.asciz ")"
	.ascii "*"
	.byte 0x01
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x96  ; ""
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "<"
	.asciz "T"
	.byte 0x03, 0x01
	.byte 0x83  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 4
	.byte 0xba, 0x99  ; "º"
	.asciz "#"
	.byte 0xbe, 0x99  ; "¾"
	.asciz "#"
	.byte 0x1c
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0x97  ; ""
	.byte 0x00
	.byte 0x98  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x07, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x0c
	.byte 0x00
	.byte 0xc2, 0x99  ; "Â"
	.asciz "#"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x96  ; ""
	.byte 0x00
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0x34
	.byte 0x01
	.byte 0xde  ; "Þ"
	.byte 0x00
	pushw de
	.byte 0xf5  ; "õ"
	.asciz ")"
	.zero 6
	.asciz "CLEAR"
	.zero 2
	.ascii "j"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x99  ; ""
	.byte 0x00
	.byte 0x96  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.asciz "["
	.ascii "?"
	.byte 0x01
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0xc4, 0x99  ; "Ä"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0xc8, 0x99  ; "È"
	.asciz "#"
	.zero 4
	.byte 0xca, 0x99  ; "Ê"
	.asciz "#"
	.zero 2
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0x9a  ; ""
	.byte 0x00
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0x98  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.asciz "$"
	.ascii "7"
	.byte 0x01
	.asciz "="
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x08
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x99  ; ""
	.byte 0x00
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0e, 0x01
	.asciz ")"
	.ascii "1"
	.byte 0x01
	.asciz ";"
	.byte 0xb4, 0xf5  ; "´õ"
	.asciz ")"
	.zero 6
	.asciz "LOAD"
	.byte 0x00
	.asciz "0"
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x99  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x36
	.byte 0x01
	.asciz "M"
	.ascii "?"
	.byte 0x01
	.asciz "]"
	.byte 0xe2, 0xf5  ; "âõ"
	.asciz ")"
	.zero 4
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x09
	.zero 3
	.ascii " "
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "~80"
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x9d  ; ""
	.byte 0x00
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.asciz "("
	.ascii "9"
	.byte 0x01
	.asciz "O"
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0x9e  ; ""
	.byte 0x00
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xae  ; "®"
	.byte 0x00
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	pushw wa
	.byte 0xf6  ; "ö"
	.asciz ")"
	.zero 6
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.zero 3
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x9d  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x9f  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.asciz "\""
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x50
	.byte 0xf6  ; "ö"
	.asciz ")"
	.zero 8
	.asciz "0"
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x9d  ; ""
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x9e  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xb3  ; "³"
	.byte 0x00
	.asciz "\""
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.ascii "x"
	.byte 0xf6  ; "ö"
	.asciz ")"
	.zero 8
	.asciz "1"
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xa1  ; "¡"
	.byte 0x00
	.byte 0x9d  ; ""
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "0"
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.asciz "J"
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	cp	xiz, (xwa)
	.asciz ")"
	.zero 8
	.asciz "2"
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xa2  ; "¢"
	.byte 0x00
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "0"
	.byte 0xb3  ; "³"
	.byte 0x00
	.asciz "J"
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	cp	h, w
	.asciz ")"
	.zero 8
	.asciz "3"
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0xa1  ; "¡"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "X"
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.asciz "r"
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xf0, 0xf6  ; "ðö"
	.asciz ")"
	.zero 8
	.asciz "4"
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0xa2  ; "¢"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "X"
	.byte 0xb3  ; "³"
	.byte 0x00
	.asciz "r"
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x18
	.byte 0xf7  ; "÷"
	.asciz ")"
	.zero 8
	.asciz "5"
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xa5  ; "¥"
	.byte 0x00
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x80  ; ""
	.byte 0x00
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x9a  ; ""
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x40
	.byte 0xf7  ; "÷"
	.asciz ")"
	.zero 8
	.asciz "6"
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xa6  ; "¦"
	.byte 0x00
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x80  ; ""
	.byte 0x00
	.byte 0xb3  ; "³"
	.byte 0x00
	.byte 0x9a  ; ""
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.ascii "h"
	.byte 0xf7  ; "÷"
	.asciz ")"
	.zero 8
	.asciz "7"
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xa7  ; "§"
	.byte 0x00
	.byte 0xa5  ; "¥"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xa8  ; "¨"
	.byte 0x00
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0xc2  ; "Â"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x90, 0xf7  ; "÷"
	.asciz ")"
	.zero 8
	.asciz "8"
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xa8  ; "¨"
	.byte 0x00
	.byte 0xa6  ; "¦"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xa8  ; "¨"
	.byte 0x00
	.byte 0xb3  ; "³"
	.byte 0x00
	.byte 0xc2  ; "Â"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xb8, 0xf7  ; "¸÷"
	.asciz ")"
	.zero 8
	.asciz "9"
	.zero 2
	.ascii "j"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xa9  ; "©"
	.byte 0x00
	.byte 0xa7  ; "§"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.asciz "-"
	.asciz "#"
	.asciz "B"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "d"
	.zero 4
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0xcc, 0x99  ; "Ì"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xd0, 0x99  ; "Ð"
	.asciz "#"
	.zero 4
	.byte 0xd2, 0x99  ; "Ò"
	.asciz "#"
	.zero 4
	.ascii "j"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xaa  ; "ª"
	.byte 0x00
	.byte 0xa8  ; "¨"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "\""
	.asciz "-"
	.byte 0xf9  ; "ù"
	.byte 0x00
	.asciz "B"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "d"
	.zero 4
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0xd4, 0x99  ; "Ô"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xd8, 0x99  ; "Ø"
	.asciz "#"
	.zero 4
	.byte 0xda, 0x99  ; "Ú"
	.asciz "#"
	.zero 4
	.ascii "j"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xab  ; "«"
	.byte 0x00
	.byte 0xa9  ; "©"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.asciz "D"
	.asciz "#"
	.asciz "Y"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "d"
	.zero 4
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0xdc, 0x99  ; "Ü"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xe0, 0x99  ; "à"
	.asciz "#"
	.zero 4
	.byte 0xe2, 0x99  ; "â"
	.asciz "#"
	.zero 4
	.ascii "j"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xac  ; "¬"
	.byte 0x00
	.byte 0xaa  ; "ª"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "\""
	.asciz "D"
	.byte 0xf9  ; "ù"
	.byte 0x00
	.asciz "Y"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "d"
	.zero 4
	.byte 0xf2  ; "ò"
	.byte 0x00
	.zero 2
	.ascii "@"
	.byte 0x01
	.byte 0xe4, 0x99  ; "ä"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xe8, 0x99  ; "è"
	.asciz "#"
	.zero 4
	.byte 0xea, 0x99  ; "ê"
	.asciz "#"
	.zero 2
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xad  ; "­"
	.byte 0x00
	.byte 0xab  ; "«"
	.byte 0x00
	.byte 0x18
	.zero 3
	.asciz "`"
	.byte 0x1f
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.asciz "("
	.ascii "*"
	.byte 0x01
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xae  ; "®"
	.byte 0x00
	.byte 0xac  ; "¬"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xdd  ; "Ý"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x05
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0xad  ; "­"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.asciz "t"
	.byte 0xd3  ; "Ó"
	.byte 0x00
	.byte 0xa9  ; "©"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x15
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0xf1  ; "ñ"
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xb0  ; "°"
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "h"
	.byte 0x1f
	.byte 0x00
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 4
	.byte 0xec, 0x99  ; "ì"
	.asciz "#"
	.byte 0xf0, 0x99  ; "ð"
	.asciz "#"
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xb1  ; "±"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz "/"
	.byte 0x07, 0x01
	.asciz "H"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.ascii "v"
	.byte 0xf9  ; "ù"
	.asciz ")"
	.byte 0x05
	.zero 3
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0xf4, 0x99  ; "ô"
	.asciz "#"
	.asciz "*"
	.ascii "*"
	.byte 0x01
	.byte 0xf6, 0x99  ; "ö"
	.asciz "#"
	.zero 2
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xb2  ; "²"
	.byte 0x00
	.byte 0xb0  ; "°"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "0"
	.asciz "L"
	.byte 0x03, 0x01
	.asciz "["
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x01
	.byte 0x00
	.byte 0xb2, 0xf9  ; "²ù"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0xfa, 0x99  ; "ú"
	.asciz "#"
	.asciz "+"
	.ascii "*"
	.byte 0x01
	.byte 0xfc, 0x99  ; "ü"
	.asciz "#"

HDAE5000_Panel_Save_UI:	; 0x29F9B2
	; Panel memory save/load UI strings
	.asciz "CURRENT PANEL          "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xb3  ; "³"
	.byte 0x00
	.byte 0xb4  ; "´"
	.byte 0x00
	.byte 0xb1  ; "±"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "0"
	.asciz "["
	.byte 0x03, 0x01
	.asciz "j"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0xfa  ; "ú"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 4
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz ","
	.ascii "*"
	.byte 0x01, 0x02
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "PANEL MEMORY           "
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xb2  ; "²"
	.byte 0x00
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz "J"
	.asciz "("
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xb2  ; "²"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "0"
	.asciz "j"
	.byte 0x03, 0x01
	.asciz "y"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x03
	.byte 0x00
	.ascii "p"
	.byte 0xfa  ; "ú"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x06
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "-"
	.ascii "*"
	.byte 0x01, 0x08
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "SEQUENCER              "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xb6  ; "¶"
	.byte 0x00
	.byte 0xb4  ; "´"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "0"
	.asciz "y"
	.byte 0x03, 0x01
	.byte 0x88  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x04
	.byte 0x00
	.byte 0xc2, 0xfa  ; "Âú"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x0c
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "."
	.ascii "*"
	.byte 0x01, 0x0e
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "COMPOSER               "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xb7  ; "·"
	.byte 0x00
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "0"
	.byte 0x88  ; ""
	.byte 0x00
	.byte 0x03, 0x01
	.byte 0x97  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x05
	.byte 0x00
	.byte 0x14
	.byte 0xfb  ; "û"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x12
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "/"
	.ascii "*"
	.byte 0x01, 0x14
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "SOUND MEMORY           "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xb8  ; "¸"
	.byte 0x00
	.byte 0xb6  ; "¶"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "0"
	.byte 0x97  ; ""
	.byte 0x00
	.byte 0x03, 0x01
	.byte 0xa6  ; "¦"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x06
	.byte 0x00
	.ascii "f"
	.byte 0xfb  ; "û"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x18
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "0"
	.ascii "*"
	.byte 0x01, 0x1a
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "MSP                    "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xb9  ; "¹"
	.byte 0x00
	.byte 0xb7  ; "·"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "0"
	.byte 0xa6  ; "¦"
	.byte 0x00
	.byte 0x03, 0x01
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x07
	.byte 0x00
	.byte 0xb8, 0xfb  ; "¸û"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x1e
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "1"
	.ascii "*"
	.byte 0x01
	.ascii " "
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "RHYTHM CUSTOM          "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xba  ; "º"
	.byte 0x00
	.byte 0xb8  ; "¸"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "0"
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0x03, 0x01
	.byte 0xc4  ; "Ä"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x08
	.byte 0x00
	.byte 0x0a
	.byte 0xfc  ; "ü"
	.asciz ")"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii "$"
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "2"
	.ascii "*"
	.byte 0x01
	.byte 0x26
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "USER MIDI SETTINGS     "
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xbb  ; "»"
	.byte 0x00
	.byte 0xb9  ; "¹"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz "J"
	.byte 0x07, 0x01
	.asciz "J"
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xbc  ; "¼"
	.byte 0x00
	.byte 0xba  ; "º"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x07, 0x01
	.asciz "J"
	.byte 0x07, 0x01
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xbd  ; "½"
	.byte 0x00
	.byte 0xbb  ; "»"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "("
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0x07, 0x01
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xbe  ; "¾"
	.byte 0x00
	.byte 0xbc  ; "¼"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "#"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 11
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xbf  ; "¿"
	.byte 0x00
	.byte 0xbd  ; "½"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz ","
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xbe  ; "¾"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "T"
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "s"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x02
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xbf  ; "¿"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "|"
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x04
	.zero 9
	.byte 0x03
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xc2  ; "Â"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x05
	.zero 9
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x13, 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x07
	.zero 9
	.byte 0x06
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xc4  ; "Ä"
	.byte 0x00
	.byte 0xc2  ; "Â"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x1c, 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x08
	.zero 9
	.byte 0x07
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x06
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xc4  ; "Ä"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xd0, 0xfd  ; "Ðý"
	.asciz ")"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "PNL"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "*"
	.byte 0xca  ; "Ê"
	.byte 0x00
	.asciz "K"
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xf4, 0xfd  ; "ôý"
	.asciz ")"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "P.MEM"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xc8  ; "È"
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "X"
	.byte 0xca  ; "Ê"
	.byte 0x00
	.asciz "m"
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x1a
	.byte 0xfe  ; "þ"
	.asciz ")"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "SEQ"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "~"
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x99  ; ""
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x3e
	.byte 0xfe  ; "þ"
	.asciz ")"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "COMP"
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0xc8  ; "È"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xa2  ; "¢"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.ascii "d"
	.byte 0xfe  ; "þ"
	.asciz ")"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "SOUND"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0xe6  ; "æ"
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x8a, 0xfe  ; "þ"
	.asciz ")"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "MSP"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x16, 0x01
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xae, 0xfe  ; "®þ"
	.asciz ")"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "CUSTOM"
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xcd  ; "Í"
	.byte 0x00
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x1e, 0x01
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xd6, 0xfe  ; "Öþ"
	.asciz ")"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "MIDI"
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xce  ; "Î"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xd7  ; "×"
	.byte 0x00
	.asciz "J"
	.byte 0xd7  ; "×"
	.byte 0x00
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xcf  ; "Ï"
	.byte 0x00
	.byte 0xd0  ; "Ð"
	.byte 0x00
	.byte 0xcd  ; "Í"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.asciz "$"
	.ascii "7"
	.byte 0x01
	.asciz "="
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x08
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xce  ; "Î"
	.byte 0x00
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0e, 0x01
	.asciz ")"
	.ascii "1"
	.byte 0x01
	.asciz ";"
	.ascii ">"
	.byte 0xff
	.asciz ")"
	.zero 6
	.asciz "LOAD"
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0xce  ; "Î"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.asciz "("
	.ascii "9"
	.byte 0x01
	.asciz "O"
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "0"
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0xd0  ; "Ð"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x36
	.byte 0x01
	.asciz "M"
	.ascii "?"
	.byte 0x01
	.asciz "]"
	.byte 0x86  ; ""
	.byte 0xff
	.asciz ")"
	.zero 4
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x09
	.zero 3
	.ascii " "
	.byte 0x01
	.fill 2, 1, 0xff
	.asciz "~80"
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd3  ; "Ó"
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	pushw de
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0xb4  ; "´"
	.byte 0xff
	.asciz ")"
	.asciz "s"
	.zero 2
	.asciz "COPY TECH TO HD"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.zero 3
	.byte 0x7f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xd5  ; "Õ"
	.byte 0x00
	.byte 0xd3  ; "Ó"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xd6  ; "Ö"
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz ","
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x0f
	.byte 0x00
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xd7  ; "×"
	.byte 0x00
	.byte 0xd5  ; "Õ"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "T"
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 10
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.zero 3
	.ascii "j"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xd6  ; "Ö"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz ":"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xd6  ; "Ö"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.zero 8
	.byte 0x0a
	.byte 0x00
	popw de
	.byte 0x01
	pushw iz
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x02
	.byte 0x00
	.byte 0x0a
	.byte 0x00
	.byte 0x32
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x34
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xd9  ; "Ù"
	.byte 0x00
	.byte 0xd7  ; "×"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xd7  ; "×"
	.byte 0x00
	.asciz "<"
	.byte 0xd7  ; "×"
	.byte 0x00
	.byte 0xd3  ; "Ó"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xda  ; "Ú"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "v"
	.asciz "<"
	.asciz "v"
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xda  ; "Ú"
	.byte 0x00
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x10, 0x01
	.asciz "#"
	.ascii "3"
	.byte 0x01
	.asciz "5"
	.byte 0xe8  ; "è"
	.byte 0x00
	.asciz "*"
	.zero 6
	.asciz "* TO"
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0b, 0x01
	.byte 0xcf  ; "Ï"
	.byte 0x00
	.byte 0x32
	.byte 0x01
	.byte 0xd9  ; "Ù"
	.byte 0x00
	.byte 0x0e, 0x01
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "SELECT"
	.zero 3
	.ascii "j"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xdf  ; "ß"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x8e  ; ""
	.byte 0x00
	.asciz "&"
	.byte 0xeb  ; "ë"
	.byte 0x00
	.asciz "5"
	.byte 0x07
	.zero 3
	.asciz "d"
	.zero 4
	.byte 0xf2  ; "ò"
	.byte 0x00
	.zero 2
	.ascii "@"
	.byte 0x01
	.byte 0x36
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x3a
	.byte 0x9a  ; ""
	.asciz "#"
	.zero 4
	.ascii "<"
	.byte 0x9a  ; ""
	.asciz "#"
	.zero 2
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xe0  ; "à"
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz "$"
	.byte 0xef  ; "ï"
	.byte 0x00
	.asciz "7"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.ascii "x"
	.byte 0x01
	.asciz "*"
	.zero 6
	.byte 0x01
	.byte 0x00
	.asciz "StringBox"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xe0  ; "à"
	.byte 0x00
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x08, 0x01
	.byte 0xa5  ; "¥"
	.byte 0x00
	.byte 0x35
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xa2  ; "¢"
	.byte 0x01
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "SEL ALL"
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xe3  ; "ã"
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x3e
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0xd4  ; "Ô"
	.byte 0x01
	.asciz "*"
	.asciz "s"
	.zero 2
	.asciz "HD DIR SELECT"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xe4  ; "ä"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xe5  ; "å"
	.byte 0x00
	.byte 0xe6  ; "æ"
	.byte 0x00
	.byte 0xe3  ; "ã"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x0d, 0x01, 0x1e
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.asciz "7"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x08
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xe4  ; "ä"
	.byte 0x00
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x10, 0x01
	.asciz "#"
	.ascii "3"
	.byte 0x01
	.asciz "5"
	.ascii "D"
	.byte 0x02
	.asciz "*"
	.zero 6
	.asciz "COPY"
	.zero 3
	.ascii "j"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xe7  ; "ç"
	.byte 0x00
	.byte 0xe4  ; "ä"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "#"
	.byte 0x07, 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.zero 2
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.byte 0x0b
	.byte 0x00
	popw de
	.byte 0x01
	.byte 0x42
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x02
	.byte 0x00
	.byte 0x0c
	.byte 0x00
	.byte 0x46
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	popw wa
	.byte 0x9a  ; ""
	.asciz "#"
	.zero 2
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xe8  ; "è"
	.byte 0x00
	.byte 0xe6  ; "æ"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.asciz "&"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 7
	.byte 0xb2  ; "²"
	.byte 0x02
	.asciz "*"
	.asciz "01-24"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xe9  ; "é"
	.byte 0x00
	.byte 0xe7  ; "ç"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "+"
	.byte 0xde  ; "Þ"
	.byte 0x00
	.asciz "P"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.byte 0xe4  ; "ä"
	.byte 0x02
	.asciz "*"
	.asciz "25-48"
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xea  ; "ê"
	.byte 0x00
	.byte 0xe8  ; "è"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "T"
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 10
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xe9  ; "é"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.ascii "@"
	.byte 0x03
	.asciz "*"
	.asciz "49-72"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0xea  ; "ê"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0x15, 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.ascii "r"
	.byte 0x03
	.asciz "*"
	.asciz "73-96"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0x3e
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.byte 0xa4  ; "¤"
	.byte 0x03
	.asciz "*"
	.asciz "97-120"
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x0d, 0x01
	.byte 0xc2  ; "Â"
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xdb  ; "Û"
	.byte 0x00
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x04
	.zero 9
	.byte 0x0c
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x11, 0x01
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0x34
	.byte 0x01
	.byte 0xd9  ; "Ù"
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x03
	.asciz "*"
	.zero 6
	.asciz "EDIT"
	.byte 0x00
	.asciz ")"
	.ascii "`"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x18
	.byte 0x00
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	.byte 0x00
	.byte 0x0b
	.byte 0x00
	popw de
	.byte 0x01, 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xf1  ; "ñ"
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	popw de
	.byte 0x9a  ; ""
	.asciz "#"
	.ascii ">"
	.byte 0x04
	.asciz "*"
	.byte 0xaf  ; "¯"
	.byte 0x00
	.zero 2
	.asciz " F.L.S. SELECT"
	.byte 0x00
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.zero 3
	.byte 0x7f
	.byte 0x00
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xf3  ; "ó"
	.byte 0x00
	.byte 0xf1  ; "ñ"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.asciz "&"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 7
	.byte 0x94  ; ""
	.byte 0x04
	.asciz "*"
	.asciz "01-24"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "+"
	.byte 0xde  ; "Þ"
	.byte 0x00
	.asciz "P"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.byte 0xc6  ; "Æ"
	.byte 0x04
	.asciz "*"
	.asciz "25-48"
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xf3  ; "ó"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "T"
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 10
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xf6  ; "ö"
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.ascii "\""
	.byte 0x05
	.asciz "*"
	.asciz "49-72"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xf7  ; "÷"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0x15, 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.ascii "T"
	.byte 0x05
	.asciz "*"
	.asciz "73-96"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xf8  ; "ø"
	.byte 0x00
	.byte 0xf6  ; "ö"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0x3e
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.byte 0x86  ; ""
	.byte 0x05
	.asciz "*"
	.asciz "97-120"
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.asciz "#"
	.ascii "7"
	.byte 0x01
	.asciz "<"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x08
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xff
	.fill 5, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0e, 0x01
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x31
	.byte 0x01
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xd6  ; "Ö"
	.byte 0x05
	.asciz "*"
	.zero 6
	.asciz "EDIT"
	.zero 3
	.ascii "j"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xfc  ; "ü"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.asciz "\""
	.byte 0xff
	.byte 0x00
	.byte 0xd9  ; "Ù"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.zero 2
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.byte 0x05
	.byte 0x00
	popw de
	.byte 0x01
	popw iz
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x02
	.byte 0x00
	.byte 0x0c
	.byte 0x00
	.byte 0x52
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x54
	.byte 0x9a  ; ""
	.asciz "#"
	.zero 2
	.asciz ")"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xfd  ; "ý"
	.byte 0x00
	.byte 0xfb  ; "û"
	.byte 0x00
	.byte 0x18
	.byte 0x00
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	.byte 0x00
	.byte 0x05
	.byte 0x00
	popw de
	.byte 0x01
	.asciz "0"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xfe  ; "þ"
	.byte 0x00
	.byte 0xfc  ; "ü"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x36
	.byte 0x01
	.asciz "M"
	.ascii "A"
	.byte 0x01
	.asciz "_"
	.ascii "Z"
	.byte 0x06
	.asciz "*"
	.zero 4
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x09
	.zero 3
	.ascii " "
	.byte 0x01, 0x06
	.byte 0x00
	.asciz "~80"
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xff
	.fill 3, 1, 0xff
	.byte 0xfd  ; "ý"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.asciz "("
	.ascii "9"
	.byte 0x01
	.asciz "O"
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x00
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "<"
	.asciz "P"
	.byte 0xeb  ; "ë"
	.byte 0x00
	.asciz "{"
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.zero 2
	.ascii "V"
	.byte 0x9a  ; ""
	.asciz "#"
	.ascii "Z"
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0e, 0x01
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0x31
	.byte 0x01
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0xbc  ; "¼"
	.byte 0x06
	.asciz "*"
	.zero 6
	.asciz "SAVE"
	.zero 3
	.ascii "j"
	.byte 0x01
	.byte 0xff
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x03, 0x01
	.byte 0x00
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.asciz "_"
	.ascii "@"
	.byte 0x01
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	pop xiz
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.ascii "b"
	.byte 0x9a  ; ""
	.asciz "#"
	.zero 4
	.ascii "d"
	.byte 0x9a  ; ""
	.asciz "#"
	.zero 4
	.ascii "j"
	.byte 0x01
	.byte 0xff
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x04, 0x01, 0x02, 0x01, 0x08
	.byte 0x00
	.asciz ","
	.asciz "4"
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xd7  ; "×"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.zero 2
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.byte 0x02
	.byte 0x00
	popw de
	.byte 0x01
	.ascii "f"
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.ascii "j"
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.ascii "l"
	.byte 0x9a  ; ""
	.asciz "#"
	.zero 4
	.ascii "j"
	.byte 0x01
	.byte 0xff
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x05, 0x01, 0x03, 0x01, 0x08
	.byte 0x00
	.asciz ","
	.asciz "#"
	.byte 0xeb  ; "ë"
	.byte 0x00
	.asciz "2"
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.ascii "n"
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.ascii "r"
	.byte 0x9a  ; ""
	.asciz "#"
	.zero 4
	.ascii "t"
	.byte 0x9a  ; ""
	.asciz "#"
	.zero 2
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xff
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x06, 0x01, 0x04, 0x01, 0x08
	.byte 0x00
	.asciz ","
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.asciz "K"
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x0f
	.byte 0x00
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.byte 0xff
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x07, 0x01, 0x05, 0x01, 0x08
	.byte 0x00
	.asciz "T"
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 10
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xff
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x08, 0x01, 0x06, 0x01, 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.asciz "-"
	.ascii "`"
	.byte 0x01
	.byte 0xff
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x09, 0x01, 0x07, 0x01, 0x08
	.byte 0x00
	.asciz ","
	.zero 2
	.asciz "G"
	.byte 0x1b
	.byte 0x00
	.byte 0xad  ; "­"
	.byte 0x00
	.zero 2
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xff
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x0a, 0x01, 0x08, 0x01, 0x08
	.byte 0x00
	.asciz "N"
	.byte 0x06
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0x18
	.byte 0x00
	pushw de
	.byte 0x08
	.asciz "*"
	.byte 0x04
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "HD FILE SELECT"
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x0a, 0x01
	.fill 2, 1, 0xff
	.byte 0x0c, 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0b
	.byte 0x00
	.asciz "!"
	.asciz " "
	.asciz "+"
	.ascii "Z"
	.byte 0x08
	.asciz "*"
	.byte 0x03
	.zero 5
	.asciz "DEL"
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x0a, 0x01
	.fill 4, 1, 0xff
	pushw 0x0801
	.byte 0x00
	.byte 0x0b
	.byte 0x00
	.asciz "+"
	.asciz " "
	.asciz "5"
	.ascii "~"
	.byte 0x08
	.asciz "*"
	.byte 0x03
	.zero 5
	.asciz "DIR"
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x0d, 0x01
	.fill 2, 1, 0xff
	.byte 0x0f, 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0a
	.byte 0x00
	.asciz "u"
	.byte 0x1f
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0xa2  ; "¢"
	.byte 0x08
	.asciz "*"
	.byte 0x03
	.zero 5
	.asciz "DEL"
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x0d, 0x01
	.fill 4, 1, 0xff
	.byte 0x0e, 0x01, 0x08
	.byte 0x00
	.byte 0x0a
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.asciz "%"
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x08
	.asciz "*"
	.byte 0x03
	.zero 5
	.asciz "FILE"
	.byte 0x00
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x11, 0x01
	.fill 4, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "F"
	.asciz "P"
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.zero 2
	.ascii "v"
	.byte 0x9a  ; ""
	.asciz "#"
	.ascii "z"
	.byte 0x9a  ; ""
	.asciz "#"
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x12, 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "N"
	.byte 0x06
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0x18
	.byte 0x00
	.byte 0x10, 0x09
	.asciz "*"
	.byte 0x04
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "HD LOAD OPTION"
	.byte 0x00
	.asciz "-"
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x13, 0x01, 0x11, 0x01, 0x08
	.byte 0x00
	.asciz ","
	.zero 2
	.asciz "G"
	.byte 0x1b
	.byte 0x00
	.byte 0xad  ; "­"
	.byte 0x00
	.zero 2
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x14, 0x01, 0x12, 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.asciz "4"
	.byte 0x03, 0x01
	.asciz "C"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x01
	.byte 0x00
	.ascii "t"
	.byte 0x09
	.asciz "*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii "~"
	.byte 0x9a  ; ""
	.asciz "#"
	.byte 0x08
	.byte 0x00
	pushw de
	.byte 0x01
	adc	(xwa), b
	.asciz "#"
	.asciz "CURRENT PANEL          "
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x15, 0x01, 0x13, 0x01, 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "#"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 11
	.byte 0x03
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x16, 0x01, 0x14, 0x01, 0x08
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x09
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "PNL"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x17, 0x01, 0x15, 0x01, 0x08
	.byte 0x00
	.asciz ","
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x18, 0x01, 0x16, 0x01, 0x08
	.byte 0x00
	.asciz "T"
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "s"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x02
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x19, 0x01, 0x17, 0x01, 0x08
	.byte 0x00
	.asciz "|"
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x04
	.zero 9
	.byte 0x03
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x1a, 0x01, 0x18, 0x01, 0x08
	.byte 0x00
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x05
	.zero 9
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x1b, 0x01, 0x19, 0x01, 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x06
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x1c, 0x01, 0x1a, 0x01, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x13, 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x07
	.zero 9
	.byte 0x06
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x1d, 0x01, 0x1b, 0x01, 0x08
	.byte 0x00
	.byte 0x1c, 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x08
	.zero 9
	.byte 0x07
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x1e, 0x01, 0x1c, 0x01, 0x08
	.byte 0x00
	.asciz "*"
	.byte 0xca  ; "Ê"
	.byte 0x00
	.asciz "K"
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x10, 0x0b
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "P.MEM"
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.byte 0x1f, 0x01, 0x1d, 0x01, 0x08
	.byte 0x00
	.asciz "X"
	.byte 0xca  ; "Ê"
	.byte 0x00
	.asciz "m"
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x36
	.byte 0x0b
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "SEQ"
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii " "
	.byte 0x01, 0x1e, 0x01, 0x08
	.byte 0x00
	.asciz "~"
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x99  ; ""
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	pop xde
	.byte 0x0b
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "COMP"
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "!"
	.byte 0x01, 0x1f, 0x01, 0x08
	.byte 0x00
	.byte 0xa2  ; "¢"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x80  ; ""
	.byte 0x0b
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "SOUND"
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "\""
	.byte 0x01
	.ascii " "
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0xe6  ; "æ"
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xa6  ; "¦"
	.byte 0x0b
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "MSP"
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "#"
	.byte 0x01
	.byte 0x21
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x16, 0x01
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x0b
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "CUSTOM"
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "$"
	.byte 0x01
	.byte 0x22
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x1e, 0x01
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xf2  ; "ò"
	.byte 0x0b
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "MIDI"
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "%"
	.byte 0x01
	.byte 0x23
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.asciz "T"
	.byte 0x03, 0x01
	.asciz "c"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x03
	.byte 0x00
	.byte 0x32
	.byte 0x0c
	.asciz "*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	adc	(xix), b
	.asciz "#"
	.byte 0x0a
	.byte 0x00
	pushw de
	.byte 0x01
	adc	(xiz), b
	.asciz "#"
	.asciz "SEQUENCER              "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "&"
	.byte 0x01
	.byte 0x24
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.asciz "d"
	.byte 0x03, 0x01
	.asciz "s"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x04
	.byte 0x00
	.byte 0x84  ; ""
	.byte 0x0c
	.asciz "*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x8a, 0x9a  ; ""
	.asciz "#"
	.byte 0x0b
	.byte 0x00
	pushw de
	.byte 0x01
	.byte 0x8c, 0x9a  ; ""
	.asciz "#"
	.asciz "COMPOSER               "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "'"
	.byte 0x01
	.byte 0x25
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.asciz "t"
	.byte 0x03, 0x01
	.byte 0x83  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x05
	.byte 0x00
	.byte 0xd6  ; "Ö"
	.byte 0x0c
	.asciz "*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	adc	(xwa), de
	.asciz "#"
	.byte 0x0c
	.byte 0x00
	pushw de
	.byte 0x01
	adc	(xde), de
	.asciz "#"
	.asciz "SOUND MEMORY           "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "("
	.byte 0x01
	.byte 0x26
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.byte 0x84  ; ""
	.byte 0x00
	.byte 0x03, 0x01
	.byte 0x93  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x06
	.byte 0x00
	pushw wa
	.byte 0x0d
	.asciz "*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	adc	(xiz), de
	.asciz "#"
	.byte 0x0d
	.byte 0x00
	pushw de
	.byte 0x01
	.byte 0x98, 0x9a  ; ""
	.asciz "#"
	.asciz "MSP                    "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii ")"
	.byte 0x01
	.byte 0x27
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.byte 0x94  ; ""
	.byte 0x00
	.byte 0x03, 0x01
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x07
	.byte 0x00
	.ascii "z"
	.byte 0x0d
	.asciz "*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x9c, 0x9a  ; ""
	.asciz "#"
	.byte 0x0e
	.byte 0x00
	pushw de
	.byte 0x01
	.byte 0x9e, 0x9a  ; ""
	.asciz "#"
	.asciz "RHYTHM CUSTOM          "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "*"
	.byte 0x01
	pushw wa
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.byte 0xb4  ; "´"
	.byte 0x00
	.byte 0x03, 0x01
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x09
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x0d
	.asciz "*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	adc	(xde), xde
	.asciz "#"
	.byte 0x10
	.byte 0x00
	pushw de
	.byte 0x01
	adc	(xix), xde
	.asciz "#"
	.asciz "TECHNICS LYRICS        "
	.asciz "."
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "+"
	.byte 0x01
	pushw bc
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "*"
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0x07, 0x01
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii ","
	.byte 0x01
	pushw de
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "*"
	.byte 0x18
	.byte 0x00
	.byte 0x07, 0x01
	.asciz "1"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x38
	.byte 0x0e
	.asciz "*"
	.byte 0x05
	.zero 3
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0xa8, 0x9a  ; "¨"
	.asciz "#"
	.byte 0x07
	.byte 0x00
	pushw de
	.byte 0x01
	.byte 0xaa, 0x9a  ; "ª"
	.asciz "#"
	.zero 2
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "-"
	.byte 0x01
	pushw hl
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.asciz "D"
	.byte 0x03, 0x01
	.asciz "S"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.ascii "t"
	.byte 0x0e
	.asciz "*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0xae, 0x9a  ; "®"
	.asciz "#"
	.byte 0x09
	.byte 0x00
	pushw de
	.byte 0x01
	ldcfm	2, (xwa)
	.asciz "#"
	.asciz "PANEL MEMORY           "
	.asciz "."
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "."
	.byte 0x01
	pushw ix
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x07, 0x01
	.asciz "2"
	.byte 0x07, 0x01
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "0"
	.byte 0x01
	pushw iz
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x94  ; ""
	.byte 0x00
	.asciz "'"
	.byte 0x9e  ; ""
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x0e
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "LYRIC"
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "1"
	.byte 0x01
	.byte 0x2f
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x03, 0x01
	.byte 0xb3  ; "³"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x08
	.byte 0x00
	.byte 0x06, 0x0f
	.asciz "*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	ldcfm	2, (xix)
	.asciz "#"
	.byte 0x0f
	.byte 0x00
	pushw de
	.byte 0x01
	ldcfm	2, (xiz)
	.asciz "#"
	.asciz "USER MIDI SETTINGS     "
	.asciz "."
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "2"
	.byte 0x01
	.byte 0x30
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xd5  ; "Õ"
	.byte 0x00
	.asciz "2"
	.byte 0xd5  ; "Õ"
	.byte 0x00
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 2, 1, 0xff
	.ascii "3"
	.byte 0x01
	.byte 0x31
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "*"
	.asciz "2"
	.asciz "*"
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01, 0x10, 0x01
	.fill 4, 1, 0xff
	.ascii "2"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "*"
	.asciz "2"
	.byte 0x07, 0x01
	.asciz "2"
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "5"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xba, 0x9a  ; "º"
	.asciz "#"
	.byte 0x96  ; ""
	.byte 0x0f
	.asciz "*"
	.byte 0xaf  ; "¯"
	.byte 0x00
	.zero 2
	.asciz "EDIT FLS NAME"
	.asciz "M"
	.ascii "`"
	.byte 0x01
	.byte 0x34
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "6"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x17
	.byte 0x00
	pushw de
	.byte 0x01
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0x34
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "7"
	.byte 0x01
	.byte 0x35
	.byte 0x01, 0x18
	.byte 0x00
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.asciz " "
	.ascii "`"
	.byte 0x01
	.byte 0x34
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "8"
	.byte 0x01
	.byte 0x36
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb1  ; "±"
	.byte 0x00
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x0b
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x17
	.byte 0x00
	pushw de
	.byte 0x01
	.asciz " "
	.ascii "`"
	.byte 0x01
	.byte 0x34
	.byte 0x01
	.byte 0x39
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "7"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "v"
	.asciz "&"
	.byte 0x87  ; ""
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x8a  ; ""
	.byte 0x00
	.zero 2
	.byte 0x17
	.byte 0x00
	pushw de
	.byte 0x01
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x38
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.asciz "w"
	.asciz "$"
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0x50
	.byte 0x10
	.asciz "*"
	.zero 4
	.byte 0xf9  ; "ù"
	.byte 0x00
	.asciz "LST"
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii ";"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xbe, 0x9a  ; "¾"
	.asciz "#"
	.ascii "~"
	.byte 0x10
	.asciz "*"
	.byte 0xaf  ; "¯"
	.byte 0x00
	.zero 2
	.asciz "F.L.S. FILE LOAD"
	.byte 0x00
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0x3a
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "<"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x3a
	.byte 0x01
	.byte 0x3d
	.byte 0x01
	.byte 0x3e
	.byte 0x01
	.byte 0x3b
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x0a, 0x01
	.asciz " "
	.ascii "7"
	.byte 0x01
	.asciz "7"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x08
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x3c
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0e, 0x01
	.asciz "$"
	.ascii "1"
	.byte 0x01
	.asciz "6"
	.byte 0xf2  ; "ò"
	.byte 0x10
	.asciz "*"
	.zero 6
	.asciz "LOAD"
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x3e
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0e, 0x01
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x31
	.byte 0x01
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x18, 0x11
	.asciz "*"
	.zero 6
	.asciz "EDIT"
	.byte 0x00
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.byte 0x3a
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "A"
	.byte 0x01
	.byte 0x3e
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "T"
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 10
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x3a
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "B"
	.byte 0x01
	.byte 0x40
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.asciz "K"
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x0f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x3a
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "C"
	.byte 0x01
	.byte 0x41
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x10
	.zero 3
	.ascii "j"
	.byte 0x01
	.byte 0x3a
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "D"
	.byte 0x01
	.byte 0x42
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.asciz "P"
	.ascii "?"
	.byte 0x01
	.byte 0xbf  ; "¿"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0xc2, 0x9a  ; "Â"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0xc6, 0x9a  ; "Æ"
	.asciz "#"
	.zero 4
	.byte 0xc8, 0x9a  ; "È"
	.asciz "#"
	.zero 4
	.ascii "j"
	.byte 0x01
	.byte 0x3a
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "E"
	.byte 0x01
	.byte 0x43
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.asciz ":"
	.ascii "?"
	.byte 0x01
	.asciz "K"
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0x0a
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0xca, 0x9a  ; "Ê"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xce, 0x9a  ; "Î"
	.asciz "#"
	.zero 4
	.byte 0xd0, 0x9a  ; "Ð"
	.asciz "#"
	.zero 4
	.ascii "j"
	.byte 0x01
	.byte 0x3a
	.byte 0x01
	.byte 0x46
	.byte 0x01
	popw wa
	.byte 0x01
	.byte 0x44
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz " "
	.byte 0xc5  ; "Å"
	.byte 0x00
	.asciz "1"
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0xd2, 0x9a  ; "Ò"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xd6, 0x9a  ; "Ö"
	.asciz "#"
	.zero 4
	.byte 0xd8, 0x9a  ; "Ø"
	.asciz "#"
	.zero 2
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x45
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "G"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xc5  ; "Å"
	.byte 0x00
	.asciz " "
	.byte 0xd6  ; "Ö"
	.byte 0x00
	.asciz "1"
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.ascii "r"
	.byte 0x12
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.asciz "AS"
	.byte 0x00
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x45
	.byte 0x01
	.fill 4, 1, 0xff
	.ascii "F"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xd6  ; "Ö"
	.byte 0x00
	.asciz " "
	.byte 0xe8  ; "è"
	.byte 0x00
	.asciz "1"
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x12
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.asciz "AL"
	.zero 3
	.ascii "j"
	.byte 0x01
	.byte 0x3a
	.byte 0x01
	popw bc
	.byte 0x01
	popw hl
	.byte 0x01
	.byte 0x45
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "4"
	.byte 0xe8  ; "è"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.zero 2
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.byte 0x06
	.byte 0x00
	popw de
	.byte 0x01
	.byte 0xda, 0x9a  ; "Ú"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.byte 0xde, 0x9a  ; "Þ"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xe0, 0x9a  ; "à"
	.asciz "#"
	.zero 2
	.asciz "."
	.ascii "`"
	.byte 0x01
	popw wa
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "J"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xc5  ; "Å"
	.byte 0x00
	.asciz "4"
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	popw wa
	.byte 0x01
	.fill 4, 1, 0xff
	.ascii "I"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xd6  ; "Ö"
	.byte 0x00
	.asciz "4"
	.byte 0xd6  ; "Ö"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0x3a
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "L"
	.byte 0x01
	popw wa
	.byte 0x01, 0x18
	.byte 0x00
	.ascii " "
	.byte 0x01
	.zero 2
	.ascii "?"
	.byte 0x01, 0x1f
	.byte 0x00
	.asciz "3"
	.ascii "*"
	.byte 0x01
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.byte 0x3a
	.byte 0x01
	popw iy
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "K"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.fill 2, 1, 0xff
	.zero 8
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	popw ix
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x02, 0x01
	.byte 0xdd  ; "Ý"
	.byte 0x00
	pushw iy
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.ascii "t"
	.byte 0x13
	.asciz "*"
	.zero 4
	.byte 0xf9  ; "ù"
	.byte 0x00
	.asciz "PANIC"
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "O"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xe2, 0x9a  ; "â"
	.asciz "#"
	.byte 0xa4  ; "¤"
	.byte 0x13
	.asciz "*"
	.byte 0xaf  ; "¯"
	.byte 0x00
	.zero 2
	.asciz "F.L.S. DIR SELECT"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	popw iz
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "P"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x3a
	.byte 0x01, 0x7f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	popw iz
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "Q"
	.byte 0x01
	.byte 0x4f
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x0d, 0x01, 0x1e
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.asciz "7"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x08
	.byte 0x00
	.byte 0x06
	.zero 3
	.ascii "j"
	.byte 0x01
	popw iz
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "R"
	.byte 0x01
	.byte 0x50
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "#"
	.byte 0x07, 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.zero 2
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.byte 0x08
	.byte 0x00
	popw de
	.byte 0x01
	.byte 0xe6, 0x9a  ; "æ"
	.asciz "#"
	.byte 0x02
	.byte 0x00
	.byte 0x0c
	.byte 0x00
	.byte 0xea, 0x9a  ; "ê"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xec, 0x9a  ; "ì"
	.asciz "#"
	.zero 2
	.asciz ">"
	.ascii "`"
	.byte 0x01
	popw iz
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "S"
	.byte 0x01
	.byte 0x51
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.asciz "&"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 7
	.ascii "`"
	.byte 0x14
	.asciz "*"
	.asciz "01-24"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	popw iz
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "T"
	.byte 0x01
	.byte 0x52
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "+"
	.byte 0xde  ; "Þ"
	.byte 0x00
	.asciz "P"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.byte 0x92  ; ""
	.byte 0x14
	.asciz "*"
	.asciz "25-48"
	.asciz "\""
	.ascii "`"
	.byte 0x01
	popw iz
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "U"
	.byte 0x01
	.byte 0x53
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "T"
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 10
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.asciz ">"
	.ascii "`"
	.byte 0x01
	popw iz
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "V"
	.byte 0x01
	.byte 0x54
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.byte 0xee  ; "î"
	.byte 0x14
	.asciz "*"
	.asciz "49-72"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	popw iz
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "W"
	.byte 0x01
	.byte 0x55
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0x15, 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.ascii " "
	.byte 0x15
	.asciz "*"
	.asciz "73-96"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	popw iz
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "X"
	.byte 0x01
	.byte 0x56
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0x3e
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.ascii "R"
	.byte 0x15
	.asciz "*"
	.asciz "97-120"
	.byte 0x00
	.asciz ")"
	.ascii "`"
	.byte 0x01
	popw iz
	.byte 0x01
	.fill 4, 1, 0xff
	.ascii "W"
	.byte 0x01, 0x18
	.byte 0x00
	.byte 0x1c
	.zero 3
	.asciz ";"
	.byte 0x1f
	.byte 0x00
	.byte 0x08
	.byte 0x00
	popw de
	.byte 0x01, 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "Z"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xee, 0x9a  ; "î"
	.asciz "#"
	.byte 0x9e  ; ""
	.byte 0x15
	.asciz "*"
	.byte 0xaf  ; "¯"
	.byte 0x00
	.zero 2
	.asciz "F.L.S. FILE SELECT"
	.byte 0x00
	.asciz "I"
	.ascii "`"
	.byte 0x01
	pop xbc
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "["
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	popw iz
	.byte 0x01, 0x7f
	.zero 3
	.ascii "j"
	.byte 0x01
	pop xbc
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "\\"
	.byte 0x01
	pop xde
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.asciz " "
	.byte 0xeb  ; "ë"
	.byte 0x00
	.asciz "/"
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0xf2, 0x9a  ; "ò"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xf6, 0x9a  ; "ö"
	.asciz "#"
	.zero 4
	.byte 0xf8, 0x9a  ; "ø"
	.asciz "#"
	.zero 4
	.ascii "j"
	.byte 0x01
	pop xbc
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "]"
	.byte 0x01
	pop xhl
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.asciz "0"
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xd7  ; "×"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.zero 2
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.byte 0x09
	.byte 0x00
	popw de
	.byte 0x01
	.byte 0xfa, 0x9a  ; "ú"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.byte 0xfe, 0x9a  ; "þ"
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.zero 2
	.byte 0x9b  ; ""
	.asciz "#"
	.zero 2
	.asciz "\""
	.ascii "`"
	.byte 0x01
	pop xbc
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "^"
	.byte 0x01
	pop xix
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "T"
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 10
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	pop xbc
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "_"
	.byte 0x01
	pop xiy
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.asciz "K"
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x0f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	pop xbc
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "`"
	.byte 0x01
	pop xiz
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x10
	.zero 3
	.ascii "j"
	.byte 0x01
	pop xbc
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "a"
	.byte 0x01
	pop xsp
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.asciz "D"
	.ascii "?"
	.byte 0x01
	.byte 0xbb  ; "»"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01, 0x02
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0x06
	.byte 0x9b  ; ""
	.asciz "#"
	.zero 4
	.byte 0x08
	.byte 0x9b  ; ""
	.asciz "#"
	.zero 2
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	pop xbc
	.byte 0x01
	.ascii "b"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "`"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x02, 0x01, 0x1e
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.asciz "7"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x08
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.ascii "a"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x03, 0x01
	.asciz "#"
	.ascii "6"
	.byte 0x01
	.asciz "5"
	.ascii "B"
	.byte 0x17
	.asciz "*"
	.zero 6
	.asciz "SELECT"
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "d"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01, 0x0a
	.byte 0x9b  ; ""
	.asciz "#"
	.ascii "t"
	.byte 0x17
	.asciz "*"
	.byte 0xaf  ; "¯"
	.byte 0x00
	.zero 2
	.asciz "F.L.S. EDIT"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "e"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x3a
	.byte 0x01, 0x7f
	.byte 0x00
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "f"
	.byte 0x01
	.ascii "d"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "T"
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 10
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.zero 3
	.ascii "j"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.ascii "g"
	.byte 0x01
	.ascii "i"
	.byte 0x01
	.ascii "e"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz " "
	.byte 0xc5  ; "Å"
	.byte 0x00
	.asciz "1"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "d"
	.byte 0x03
	.zero 7
	.ascii "@"
	.byte 0x01, 0x0e
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x12
	.byte 0x9b  ; ""
	.asciz "#"
	.zero 4
	.byte 0x14
	.byte 0x9b  ; ""
	.asciz "#"
	.zero 2
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.ascii "f"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "h"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.asciz " "
	.byte 0xd6  ; "Ö"
	.byte 0x00
	.asciz "1"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x26
	.byte 0x18
	.asciz "*"
	.byte 0x03
	.zero 7
	.asciz "AS"
	.byte 0x00
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.ascii "f"
	.byte 0x01
	.fill 4, 1, 0xff
	.ascii "g"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xd7  ; "×"
	.byte 0x00
	.asciz " "
	.byte 0xe8  ; "è"
	.byte 0x00
	.asciz "1"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x50
	.byte 0x18
	.asciz "*"
	.byte 0x03
	.zero 7
	.asciz "AL"
	.zero 3
	.ascii "j"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.ascii "j"
	.byte 0x01
	.ascii "l"
	.byte 0x01
	.ascii "f"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "4"
	.byte 0xe8  ; "è"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.zero 2
	.byte 0x03
	.zero 5
	.byte 0x07
	.byte 0x00
	popw de
	.byte 0x01, 0x16
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.byte 0x1a
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x1c
	.byte 0x9b  ; ""
	.asciz "#"
	.zero 2
	.asciz "."
	.ascii "`"
	.byte 0x01
	.ascii "i"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "k"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xd6  ; "Ö"
	.byte 0x00
	.asciz "4"
	.byte 0xd6  ; "Ö"
	.byte 0x00
	.byte 0xd7  ; "×"
	.byte 0x00
	.zero 2
	.byte 0x01
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.ascii "i"
	.byte 0x01
	.fill 4, 1, 0xff
	.ascii "j"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xc5  ; "Å"
	.byte 0x00
	.asciz "4"
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0xd7  ; "×"
	.byte 0x00
	.zero 2
	.byte 0x01
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.ascii "m"
	.byte 0x01
	.ascii "n"
	.byte 0x01
	.ascii "i"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.asciz "7"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x08
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.ascii "l"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x01, 0x01
	.asciz "#"
	.ascii "4"
	.byte 0x01
	.asciz "5"
	.byte 0x0c, 0x19
	.asciz "*"
	.zero 6
	.asciz "SEARCH"
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.ascii "o"
	.byte 0x01
	.ascii "q"
	.byte 0x01
	.ascii "l"
	.byte 0x01, 0x08
	.zero 2
	.byte 0x01
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x36
	.byte 0x01
	.byte 0xd9  ; "Ù"
	.byte 0x00
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x04
	.zero 9
	.byte 0x0c
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.ascii "n"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "p"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x0c, 0x01
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0x27
	.byte 0x01
	.byte 0xcd  ; "Í"
	.byte 0x00
	pop xix
	.byte 0x19
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "SAVE"
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.ascii "n"
	.byte 0x01
	.fill 4, 1, 0xff
	.ascii "o"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x0a, 0x01
	.byte 0xce  ; "Î"
	.byte 0x00
	.byte 0x31
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x82  ; ""
	.byte 0x19
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "F.L.S."
	.byte 0x00
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "r"
	.byte 0x01
	.ascii "n"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.asciz "#"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 7
	.byte 0xb6  ; "¶"
	.byte 0x19
	.asciz "*"
	.asciz "DEL1"
	.byte 0x00
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "s"
	.byte 0x01
	.ascii "q"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.byte 0xde  ; "Þ"
	.byte 0x00
	.asciz "L"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x01
	.zero 3
	.byte 0xe8  ; "è"
	.byte 0x19
	.asciz "*"
	.asciz "DEL2"
	.byte 0x00
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "t"
	.byte 0x01
	.ascii "r"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x05
	.zero 3
	.byte 0x1a, 0x1a
	.asciz "*"
	.asciz "INS"
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "u"
	.byte 0x01
	.ascii "s"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0x13, 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x06
	.zero 3
	.ascii "J"
	.byte 0x1a
	.asciz "*"
	.asciz "A.S."
	.byte 0x00
	.asciz ">"
	.ascii "`"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "v"
	.byte 0x01
	.ascii "t"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x1c, 0x01
	.byte 0xde  ; "Þ"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x07
	.zero 3
	.ascii "|"
	.byte 0x1a
	.asciz "*"
	.asciz "A.L."
	.zero 3
	.ascii "j"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "w"
	.byte 0x01
	.ascii "u"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.asciz ":"
	.ascii "?"
	.byte 0x01
	.asciz "K"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0xf2  ; "ò"
	.byte 0x00
	.zero 2
	.ascii "@"
	.byte 0x01, 0x1e
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x22
	.byte 0x9b  ; ""
	.asciz "#"
	.zero 4
	.ascii "$"
	.byte 0x9b  ; ""
	.asciz "#"
	.zero 4
	.ascii "j"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "x"
	.byte 0x01
	.ascii "v"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.asciz "N"
	.ascii "?"
	.byte 0x01
	.byte 0xbc  ; "¼"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0x26
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x09
	.byte 0x00
	pushw de
	.byte 0x9b  ; ""
	.asciz "#"
	.zero 4
	.ascii ","
	.byte 0x9b  ; ""
	.asciz "#"
	.zero 2
	.asciz ")"
	.ascii "`"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "y"
	.byte 0x01
	.ascii "w"
	.byte 0x01, 0x18
	.byte 0x00
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	.byte 0x00
	.byte 0x07
	.byte 0x00
	popw de
	.byte 0x01
	.asciz "."
	.ascii "`"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "z"
	.byte 0x01
	.ascii "x"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xd6  ; "Ö"
	.byte 0x00
	.asciz " "
	.byte 0xd6  ; "Ö"
	.byte 0x00
	.asciz "0"
	.zero 2
	.byte 0x01
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.ascii "c"
	.byte 0x01
	.fill 4, 1, 0xff
	.ascii "y"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xc5  ; "Å"
	.byte 0x00
	.asciz " "
	.byte 0xc5  ; "Å"
	.byte 0x00
	.asciz "0"
	.zero 2
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "|"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	pushw iz
	.byte 0x9b  ; ""
	.asciz "#"
	.ascii "r"
	.byte 0x1b
	.asciz "*"
	.asciz "s"
	.zero 2
	.asciz "EDIT DIRECTORY NAME"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0x7b
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "}"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.asciz "M"
	.ascii "`"
	.byte 0x01
	.byte 0x7b
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "~"
	.byte 0x01
	.byte 0x7c
	.byte 0x01, 0x18
	.zero 3
	.asciz " "
	.byte 0x1f
	.byte 0x00
	.asciz "?"
	.byte 0x19
	.byte 0x00
	pushw de
	.byte 0x01
	.asciz " "
	.ascii "`"
	.byte 0x01
	.byte 0x7b
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x7f, 0x01
	.byte 0x7d
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb1  ; "±"
	.byte 0x00
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x0b
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x19
	.byte 0x00
	pushw de
	.byte 0x01
	.asciz " "
	.ascii "`"
	.byte 0x01
	.byte 0x7b
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x80  ; ""
	.byte 0x01
	.byte 0x7e
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "v"
	.asciz "&"
	.byte 0x87  ; ""
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x8a  ; ""
	.byte 0x00
	.zero 2
	.byte 0x19
	.byte 0x00
	pushw de
	.byte 0x01
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x7b
	.byte 0x01
	.fill 4, 1, 0xff
	jrl	nc, 0x0801
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.asciz "w"
	.asciz "$"
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0x32
	.byte 0x1c
	.asciz "*"
	.zero 4
	.byte 0xf9  ; "ù"
	.byte 0x00
	.asciz "LST"
	.asciz "K"
	.ascii "`"
	.byte 0x01
	.fill 8, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "<"
	.asciz "T"
	.byte 0x03, 0x01
	.byte 0x83  ; ""
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.zero 2
	.ascii "2"
	.byte 0x9b  ; ""
	.asciz "#"
	.ascii "6"
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x83  ; ""
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x3a
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x84  ; ""
	.byte 0x1c
	.asciz "*"
	.byte 0xad  ; "­"
	.byte 0x00
	.zero 2
	.asciz "SAVE OPTION"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x84  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.asciz "N"
	.byte 0x7f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x85  ; ""
	.byte 0x01
	.byte 0x83  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "#"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 11
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x86  ; ""
	.byte 0x01
	.byte 0x84  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x87  ; ""
	.byte 0x01
	.byte 0x85  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "T"
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "s"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x02
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x88  ; ""
	.byte 0x01
	.byte 0x86  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "|"
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x04
	.zero 9
	.byte 0x03
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x89  ; ""
	.byte 0x01
	.byte 0x87  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x05
	.zero 9
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x8a  ; ""
	.byte 0x01
	.byte 0x88  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x06
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x8b  ; ""
	.byte 0x01
	.byte 0x89  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x13, 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x07
	.zero 9
	.byte 0x06
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x8c  ; ""
	.byte 0x01
	.byte 0x8a  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x1c, 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x08
	.zero 9
	.byte 0x07
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x8d  ; ""
	.byte 0x01
	.byte 0x8b  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x0a, 0x1e
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "PNL"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x8e  ; ""
	.byte 0x01
	.byte 0x8c  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "*"
	.byte 0xca  ; "Ê"
	.byte 0x00
	.asciz "K"
	.byte 0xd4  ; "Ô"
	.byte 0x00
	pushw iz
	.byte 0x1e
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "P.MEM"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x8f  ; ""
	.byte 0x01
	.byte 0x8d  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "X"
	.byte 0xca  ; "Ê"
	.byte 0x00
	.asciz "m"
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x54
	.byte 0x1e
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "SEQ"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x90  ; ""
	.byte 0x01
	.byte 0x8e  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "~"
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x99  ; ""
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.ascii "x"
	.byte 0x1e
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "COMP"
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x91  ; ""
	.byte 0x01
	.byte 0x8f  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xa2  ; "¢"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x9e  ; ""
	.byte 0x1e
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "SOUND"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x92  ; ""
	.byte 0x01
	.byte 0x90  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0xe6  ; "æ"
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xc4  ; "Ä"
	.byte 0x1e
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "MSP"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x93  ; ""
	.byte 0x01
	.byte 0x91  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x16, 0x01
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xe8  ; "è"
	.byte 0x1e
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "CUSTOM"
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x94  ; ""
	.byte 0x01
	.byte 0x92  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x1e, 0x01
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x10, 0x1f
	.asciz "*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "MIDI"
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x95  ; ""
	.byte 0x01
	.byte 0x93  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.asciz "j"
	.byte 0xff
	.byte 0x00
	.asciz "y"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x04
	.byte 0x00
	.byte 0x50
	.byte 0x1f
	.asciz "*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii ">"
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x0b
	.byte 0x00
	pushw de
	.byte 0x01
	.byte 0x40
	.byte 0x9b  ; ""
	.asciz "#"
	.asciz "COMPOSER               "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x96  ; ""
	.byte 0x01
	.byte 0x94  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "("
	.byte 0x1f
	.byte 0x00
	.byte 0x03, 0x01
	.asciz "8"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xa2  ; "¢"
	.byte 0x1f
	.asciz "*"
	.byte 0x05
	.zero 3
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii "D"
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x06
	.byte 0x00
	pushw de
	.byte 0x01
	.byte 0x46
	.byte 0x9b  ; ""
	.asciz "#"
	.zero 2
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x97  ; ""
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.asciz "="
	.byte 0xff
	.byte 0x00
	.asciz "L"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x01
	.byte 0x00
	.byte 0xde  ; "Þ"
	.byte 0x1f
	.asciz "*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii "J"
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x08
	.byte 0x00
	pushw de
	.byte 0x01
	popw ix
	.byte 0x9b  ; ""
	.asciz "#"
	.asciz "CURRENT PANEL          "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x98  ; ""
	.byte 0x01
	.byte 0x96  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.asciz "L"
	.byte 0xff
	.byte 0x00
	.asciz "["
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "0 *"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii "P"
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x09
	.byte 0x00
	pushw de
	.byte 0x01
	.byte 0x52
	.byte 0x9b  ; ""
	.asciz "#"
	.asciz "PANEL MEMORY           "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x99  ; ""
	.byte 0x01
	.byte 0x97  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.asciz "["
	.byte 0xff
	.byte 0x00
	.asciz "j"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x03
	.byte 0x00
	.byte 0x82  ; ""
	.asciz " *"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii "V"
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x0a
	.byte 0x00
	pushw de
	.byte 0x01
	pop xwa
	.byte 0x9b  ; ""
	.asciz "#"
	.asciz "SEQUENCER              "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x9a  ; ""
	.byte 0x01
	.byte 0x98  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.asciz "y"
	.byte 0xff
	.byte 0x00
	.byte 0x88  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x05
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.asciz " *"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii "\\"
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x0c
	.byte 0x00
	pushw de
	.byte 0x01
	pop xiz
	.byte 0x9b  ; ""
	.asciz "#"
	.asciz "SOUND MEMORY           "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x9b  ; ""
	.byte 0x01
	.byte 0x99  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.byte 0x88  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x97  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x06
	.byte 0x00
	.asciz "&!*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii "b"
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x0d
	.byte 0x00
	pushw de
	.byte 0x01
	.ascii "d"
	.byte 0x9b  ; ""
	.asciz "#"
	.asciz "MSP                    "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x9c  ; ""
	.byte 0x01
	.byte 0x9a  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.byte 0x97  ; ""
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0xa6  ; "¦"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x07
	.byte 0x00
	.asciz "x!*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii "h"
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x0e
	.byte 0x00
	pushw de
	.byte 0x01
	.ascii "j"
	.byte 0x9b  ; ""
	.asciz "#"
	.asciz "RHYTHM CUSTOM          "
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x9d  ; ""
	.byte 0x01
	.byte 0x9b  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.byte 0xa6  ; "¦"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x08
	.byte 0x00
	.byte 0xca  ; "Ê"
	.asciz "!*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii "n"
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x0f
	.byte 0x00
	pushw de
	.byte 0x01
	.ascii "p"
	.byte 0x9b  ; ""
	.asciz "#"
	.asciz "USER MIDI SETTINGS     "
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x9e  ; ""
	.byte 0x01
	.byte 0x9c  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "("
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0x03, 0x01
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x9f  ; ""
	.byte 0x01
	.byte 0x9d  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "("
	.asciz ":"
	.byte 0x03, 0x01
	.asciz ":"
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x9e  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x03, 0x01
	.asciz ":"
	.byte 0x03, 0x01
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xa1  ; "¡"
	.byte 0x01
	.byte 0x9f  ; ""
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "("
	.asciz ":"
	.asciz "("
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xa2  ; "¢"
	.byte 0x01
	.byte 0xa0  ; " "
	.byte 0x01, 0x18
	.byte 0x00
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	pushw de
	.byte 0x01, 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.byte 0xa3  ; "£"
	.byte 0x01
	.byte 0xa4  ; "¤"
	.byte 0x01
	.byte 0xa1  ; "¡"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x0d, 0x01, 0x1e
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.asciz "7"
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x08
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xa2  ; "¢"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x10, 0x01
	.asciz "#"
	.ascii "3"
	.byte 0x01
	.asciz "5"
	.byte 0xac  ; "¬"
	.asciz "\"*"
	.zero 6
	.asciz "SAVE"
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.byte 0xa5  ; "¥"
	.byte 0x01
	.byte 0xa6  ; "¦"
	.byte 0x01
	.byte 0xa2  ; "¢"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x07, 0x01
	.asciz "L"
	.ascii "7"
	.byte 0x01
	.asciz "]"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x09
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xa4  ; "¤"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.asciz "P"
	.ascii "6"
	.byte 0x01
	.asciz "Z"
	.byte 0xfa  ; "ú"
	.asciz "\"*"
	.byte 0x03
	.zero 5
	.asciz "PERFORM"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.byte 0xa7  ; "§"
	.byte 0x01
	.byte 0xa8  ; "¨"
	.byte 0x01
	.byte 0xa4  ; "¤"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x07, 0x01
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb1  ; "±"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x0b
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xa6  ; "¦"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x36
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x00
	.asciz "J#*"
	.byte 0x03
	.zero 5
	.asciz "ALL OFF"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.byte 0xa9  ; "©"
	.byte 0x01
	.byte 0xaa  ; "ª"
	.byte 0x01
	.byte 0xa6  ; "¦"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x07, 0x01
	.asciz "v"
	.ascii "7"
	.byte 0x01
	.byte 0x87  ; ""
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x0a
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xa8  ; "¨"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.asciz "z"
	.ascii "0"
	.byte 0x01
	.byte 0x84  ; ""
	.byte 0x00
	.byte 0x9a  ; ""
	.asciz "#*"
	.byte 0x03
	.zero 5
	.asciz "BACKUP"
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xab  ; "«"
	.byte 0x01
	.byte 0xa8  ; "¨"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0xc4  ; "Ä"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x09
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.asciz "#*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.ascii "t"
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x10
	.byte 0x00
	pushw de
	.byte 0x01
	.ascii "v"
	.byte 0x9b  ; ""
	.asciz "#"
	.asciz "TECHNICS LYRICS        "
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xac  ; "¬"
	.byte 0x01
	.byte 0xaa  ; "ª"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x9e  ; ""
	.byte 0x00
	.asciz "'"
	.byte 0xb3  ; "³"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x09
	.zero 9
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xad  ; "­"
	.byte 0x01
	.byte 0xab  ; "«"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x93  ; ""
	.byte 0x00
	.asciz "'"
	.byte 0x9d  ; ""
	.byte 0x00
	.asciz "<$*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "LYRIC"
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0x82  ; ""
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0xac  ; "¬"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.asciz ":"
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xaf  ; "¯"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz ","
	.asciz "l"
	.byte 0x13, 0x01
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.zero 2
	.ascii "z"
	.byte 0x9b  ; ""
	.asciz "#"
	.ascii "~"
	.byte 0x9b  ; ""
	.asciz "#"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.byte 0xb0  ; "°"
	.byte 0x01
	.byte 0xb1  ; "±"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "L"
	.asciz "&"
	.asciz "]"
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0x07
	.zero 9
	.byte 0x89  ; ""
	.byte 0x00
	.zero 2
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.asciz "M"
	.asciz "$"
	.asciz "_"
	.byte 0xc8  ; "È"
	.asciz "$*"
	.zero 6
	.asciz "DEL"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.byte 0xb2  ; "²"
	.byte 0x01
	.byte 0xb3  ; "³"
	.byte 0x01
	.byte 0xaf  ; "¯"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "\""
	.asciz "&"
	.asciz "3"
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0x06
	.zero 9
	.byte 0x88  ; ""
	.byte 0x00
	.zero 2
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xb1  ; "±"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.asciz "#"
	.asciz "$"
	.asciz "5"
	.byte 0x14
	.asciz "%*"
	.zero 6
	.asciz "INS"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.byte 0xb4  ; "´"
	.byte 0x01
	.byte 0xb5  ; "µ"
	.byte 0x01
	.byte 0xb1  ; "±"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.asciz "\""
	.ascii "7"
	.byte 0x01
	.asciz "3"
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0x09
	.zero 9
	.byte 0x08
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xb3  ; "³"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1a, 0x01
	.asciz "#"
	.ascii "5"
	.byte 0x01
	.asciz "5"
	.asciz "`%*"
	.zero 6
	.asciz "CLR"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.byte 0xb6  ; "¶"
	.byte 0x01
	.byte 0xb7  ; "·"
	.byte 0x01
	.byte 0xb3  ; "³"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.asciz "L"
	.ascii "7"
	.byte 0x01
	.asciz "]"
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0x08
	.zero 9
	.byte 0x09
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xb5  ; "µ"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1a, 0x01
	.asciz "M"
	.ascii "5"
	.byte 0x01
	.asciz "_"
	.byte 0xac  ; "¬"
	.asciz "%*"
	.zero 6
	.asciz "~8d ~8b"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xb8  ; "¸"
	.byte 0x01
	.byte 0xb5  ; "µ"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "#"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 11
	.byte 0x0f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xb9  ; "¹"
	.byte 0x01
	.byte 0xb7  ; "·"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xba  ; "º"
	.byte 0x01
	.byte 0xb8  ; "¸"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.asciz "I"
	.byte 0xdb  ; "Û"
	.byte 0x00
	.asciz "$&*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.asciz "POSITION"
	.byte 0x00
	.asciz "L"
	.ascii "`"
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xbb  ; "»"
	.byte 0x01
	.byte 0xb9  ; "¹"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.asciz "H"
	.byte 0x13, 0x01
	.asciz "g"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 4
	.byte 0xff
	.zero 3
	adc	(xde), c
	.asciz "#"
	.asciz "ABC"
	.asciz "ABC"
	.asciz "abc"
	.asciz "abc"
	.asciz "!#$"
	.asciz "!#$"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xbf  ; "¿"
	.byte 0x01
	.byte 0xbd  ; "½"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x0f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xc0  ; "À"
	.byte 0x01
	.byte 0xbe  ; "¾"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x13, 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x04
	.zero 9
	.byte 0x06
	.byte 0x00
	.byte 0x0e
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xc1  ; "Á"
	.byte 0x01
	.byte 0xbf  ; "¿"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x1c, 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x05
	.zero 9
	.byte 0x07
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.byte 0x12
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xae  ; "®"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0xc0  ; "À"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xd7  ; "×"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xc3  ; "Ã"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x8a, 0x9b  ; ""
	.asciz "#"
	.asciz "4'*"
	.byte 0xad  ; "­"
	.byte 0x00
	.zero 2
	.asciz "HD FILE DELETE"
	.byte 0x00
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xc4  ; "Ä"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x18
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xc5  ; "Å"
	.byte 0x01
	.byte 0xc3  ; "Ã"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.asciz "~'*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "PNL"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xc6  ; "Æ"
	.byte 0x01
	.byte 0xc4  ; "Ä"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "*"
	.byte 0xca  ; "Ê"
	.byte 0x00
	.asciz "K"
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xa2  ; "¢"
	.asciz "'*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "P.MEM"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xc7  ; "Ç"
	.byte 0x01
	.byte 0xc5  ; "Å"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "X"
	.byte 0xca  ; "Ê"
	.byte 0x00
	.asciz "m"
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xc8  ; "È"
	.asciz "'*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "SEQ"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xc8  ; "È"
	.byte 0x01
	.byte 0xc6  ; "Æ"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "~"
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x99  ; ""
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0xec  ; "ì"
	.asciz "'*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "COMP"
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xc9  ; "É"
	.byte 0x01
	.byte 0xc7  ; "Ç"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xa2  ; "¢"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x12
	.asciz "(*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "SOUND"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xca  ; "Ê"
	.byte 0x01
	.byte 0xc8  ; "È"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0xe6  ; "æ"
	.byte 0x00
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.asciz "8(*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "MSP"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xcb  ; "Ë"
	.byte 0x01
	.byte 0xc9  ; "É"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x16, 0x01
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.asciz "\\(*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "CUSTOM"
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xcc  ; "Ì"
	.byte 0x01
	.byte 0xca  ; "Ê"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x1e, 0x01
	.byte 0xca  ; "Ê"
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.byte 0x84  ; ""
	.asciz "(*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "MIDI"
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xcd  ; "Í"
	.byte 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "+"
	.asciz ";"
	.asciz "+"
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xce  ; "Î"
	.byte 0x01
	.byte 0xcc  ; "Ì"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "+"
	.asciz ":"
	.byte 0xfa  ; "ú"
	.byte 0x00
	.asciz ":"
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xcf  ; "Ï"
	.byte 0x01
	.byte 0xcd  ; "Í"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "+"
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xfa  ; "ú"
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd0  ; "Ð"
	.byte 0x01
	.byte 0xce  ; "Î"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.asciz ";"
	.byte 0x01, 0x01
	.asciz "J"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x01
	.byte 0x00
	.byte 0x12
	.asciz ")*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x8e, 0x9b  ; ""
	.asciz "#"
	.byte 0x1e
	.byte 0x00
	pushw de
	.byte 0x01
	adc	(xwa), hl
	.asciz "#"
	.asciz "CURRENT PANEL     "
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd1  ; "Ñ"
	.byte 0x01
	.byte 0xcf  ; "Ï"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.asciz "L"
	.byte 0x01, 0x01
	.asciz "["
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "`)*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	adc	(xix), hl
	.asciz "#"
	.byte 0x1f
	.byte 0x00
	pushw de
	.byte 0x01
	adc	(xiz), hl
	.asciz "#"
	.asciz "PANEL MEMORY      "
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd2  ; "Ò"
	.byte 0x01
	.byte 0xd0  ; "Ð"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.asciz "["
	.byte 0x01, 0x01
	.asciz "j"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x03
	.byte 0x00
	.byte 0xae  ; "®"
	.asciz ")*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0x9a, 0x9b  ; ""
	.asciz "#"
	.asciz " "
	.ascii "*"
	.byte 0x01
	.byte 0x9c, 0x9b  ; ""
	.asciz "#"
	.asciz "SEQUENCER         "
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd3  ; "Ó"
	.byte 0x01
	.byte 0xd1  ; "Ñ"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.asciz "j"
	.byte 0x01, 0x01
	.asciz "y"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x04
	.byte 0x00
	.byte 0xfc  ; "ü"
	.asciz ")*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	adc	(xwa), xhl
	.asciz "#"
	.asciz "!"
	.ascii "*"
	.byte 0x01
	adc	(xde), xhl
	.asciz "#"
	.asciz "COMPOSER          "
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd4  ; "Ô"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.asciz "y"
	.byte 0x01, 0x01
	.byte 0x88  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x05
	.byte 0x00
	.asciz "J**"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	adc	(xiz), xhl
	.asciz "#"
	.asciz "\""
	.ascii "*"
	.byte 0x01
	.byte 0xa8, 0x9b  ; "¨"
	.asciz "#"
	.asciz "SOUND MEMORY      "
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd5  ; "Õ"
	.byte 0x01
	.byte 0xd3  ; "Ó"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.byte 0x88  ; ""
	.byte 0x00
	.byte 0x01, 0x01
	.byte 0x97  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x06
	.byte 0x00
	.byte 0x98  ; ""
	.asciz "**"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0xac, 0x9b  ; "¬"
	.asciz "#"
	.asciz "#"
	.ascii "*"
	.byte 0x01
	.byte 0xae, 0x9b  ; "®"
	.asciz "#"
	.asciz "MSP               "
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd6  ; "Ö"
	.byte 0x01
	.byte 0xd4  ; "Ô"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.byte 0x97  ; ""
	.byte 0x00
	.byte 0x01, 0x01
	.byte 0xa6  ; "¦"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x07
	.byte 0x00
	.byte 0xe6  ; "æ"
	.asciz "**"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	ldcfm	3, (xde)
	.asciz "#"
	.asciz "$"
	.ascii "*"
	.byte 0x01
	ldcfm	3, (xix)
	.asciz "#"
	.asciz "RHYTHM CUSTOM     "
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd7  ; "×"
	.byte 0x01
	.byte 0xd5  ; "Õ"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.byte 0xa6  ; "¦"
	.byte 0x00
	.byte 0x01, 0x01
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x08
	.byte 0x00
	.asciz "4+*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0xb8, 0x9b  ; "¸"
	.asciz "#"
	.asciz "%"
	.ascii "*"
	.byte 0x01
	.byte 0xba, 0x9b  ; "º"
	.asciz "#"
	.asciz "USER MIDI SETTINGS"
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd8  ; "Ø"
	.byte 0x01
	.byte 0xd6  ; "Ö"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "#"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 11
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd9  ; "Ù"
	.byte 0x01
	.byte 0xd7  ; "×"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xda  ; "Ú"
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "T"
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "s"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x02
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xdb  ; "Û"
	.byte 0x01
	.byte 0xd9  ; "Ù"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "|"
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x04
	.zero 9
	.byte 0x03
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xdc  ; "Ü"
	.byte 0x01
	.byte 0xda  ; "Ú"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x05
	.zero 9
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xdd  ; "Ý"
	.byte 0x01
	.byte 0xdb  ; "Û"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x06
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xde  ; "Þ"
	.byte 0x01
	.byte 0xdc  ; "Ü"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x13, 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x07
	.zero 9
	.byte 0x06
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xdf  ; "ß"
	.byte 0x01
	.byte 0xdd  ; "Ý"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x1c, 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x08
	.zero 9
	.byte 0x07
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xe0  ; "à"
	.byte 0x01
	.byte 0xde  ; "Þ"
	.byte 0x01, 0x18
	.byte 0x00
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	.byte 0x00
	.byte 0x1c
	.byte 0x00
	pushw de
	.byte 0x01, 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.byte 0xe1  ; "á"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x01
	.byte 0xdf  ; "ß"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x0d, 0x01, 0x1e
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.asciz "7"
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x08
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xe0  ; "à"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x14, 0x01
	.asciz "#"
	.ascii "/"
	.byte 0x01
	.asciz "5"
	.byte 0xea  ; "ê"
	.asciz ",*"
	.zero 6
	.asciz "DEL"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.byte 0xe3  ; "ã"
	.byte 0x01
	.byte 0xe4  ; "ä"
	.byte 0x01
	.byte 0xe0  ; "à"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xfd  ; "ý"
	.byte 0x00
	.asciz "v"
	.ascii "7"
	.byte 0x01
	.byte 0x87  ; ""
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x0a
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xfd  ; "ý"
	.byte 0x00
	.asciz "w"
	.ascii "8"
	.byte 0x01
	.byte 0x89  ; ""
	.byte 0x00
	.asciz "6-*"
	.zero 6
	.asciz "ALL DEL"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.byte 0xe5  ; "å"
	.byte 0x01
	.byte 0xe6  ; "æ"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xfd  ; "ý"
	.byte 0x00
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb1  ; "±"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x0b
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xe4  ; "ä"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xfd  ; "ý"
	.byte 0x00
	.byte 0xa1  ; "¡"
	.byte 0x00
	.byte 0x38
	.byte 0x01
	.byte 0xb3  ; "³"
	.byte 0x00
	.byte 0x86  ; ""
	.asciz "-*"
	.zero 6
	.asciz "ALL OFF"
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xe7  ; "ç"
	.byte 0x01
	.byte 0xe4  ; "ä"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "*"
	.asciz " "
	.byte 0xfc  ; "ü"
	.byte 0x00
	.asciz "9"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0xc8  ; "È"
	.asciz "-*"
	.byte 0x05
	.zero 3
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xbe, 0x9b  ; "¾"
	.asciz "#"
	.byte 0x1d
	.byte 0x00
	pushw de
	.byte 0x01
	.byte 0xc0, 0x9b  ; "À"
	.asciz "#"
	.zero 2
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xe8  ; "è"
	.byte 0x01
	.byte 0xe6  ; "æ"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x9e  ; ""
	.byte 0x00
	.asciz "'"
	.byte 0xb3  ; "³"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x09
	.zero 9
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xe9  ; "é"
	.byte 0x01
	.byte 0xe7  ; "ç"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x93  ; ""
	.byte 0x00
	.asciz "'"
	.byte 0x9d  ; ""
	.byte 0x00
	.byte 0x12
	.asciz ".*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "LYRIC"
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xea  ; "ê"
	.byte 0x01
	.byte 0xe8  ; "è"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "0"
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0x01, 0x01
	.byte 0xc4  ; "Ä"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 2
	.byte 0x09
	.byte 0x00
	.asciz "R.*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.byte 0xff
	.zero 3
	.byte 0xc4, 0x9b  ; "Ä"
	.asciz "#"
	.asciz "&"
	.ascii "*"
	.byte 0x01
	.byte 0xc6, 0x9b  ; "Æ"
	.asciz "#"
	.asciz "TECHNICS LYRICS   "
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xeb  ; "ë"
	.byte 0x01
	.byte 0xe9  ; "é"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xcd  ; "Í"
	.byte 0x00
	.asciz ";"
	.byte 0xcd  ; "Í"
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0xea  ; "ê"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xfa  ; "ú"
	.byte 0x00
	.asciz ";"
	.byte 0xfa  ; "ú"
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "3"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xed  ; "í"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xca, 0x9b  ; "Ê"
	.asciz "#"
	.asciz "i"
	.ascii "`"
	.byte 0x01
	.byte 0xec  ; "ì"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1a, 0x01
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0x34
	.byte 0x01
	.byte 0xdf  ; "ß"
	.byte 0x00
	.asciz "'"
	.ascii "*"
	.byte 0x01, 0x09
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 8, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xce, 0x9b  ; "Î"
	.asciz "#"
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xf0  ; "ð"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xd2, 0x9b  ; "Ò"
	.asciz "#"
	.asciz "\"/*"
	.zero 6
	.asciz "?"
	.ascii "`"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x01
	.byte 0xf1  ; "ñ"
	.byte 0x01
	.byte 0xf2  ; "ò"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 10
	.byte 0x01
	.zero 3
	.asciz "R/*"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.asciz "K"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc8  ; "È"
	.byte 0x00
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x01
	.byte 0xf3  ; "ó"
	.byte 0x01
	.byte 0xf4  ; "ô"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0xac  ; "¬"
	.asciz "/*"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xf2  ; "ò"
	.byte 0x01
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xf8  ; "ø"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xf5  ; "õ"
	.byte 0x01
	.byte 0xf2  ; "ò"
	.byte 0x01, 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.asciz "4"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x01
	.byte 0xf6  ; "ö"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xf4  ; "ô"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "("
	.asciz "L"
	.byte 0x17, 0x01
	.byte 0xcd  ; "Í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x04
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xf5  ; "õ"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xf7  ; "÷"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz ","
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0x13, 0x01
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd3  ; "Ó"
	.byte 0x00
	.byte 0x07
	.zero 7
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xf5  ; "õ"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0xf6  ; "ö"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz ","
	.asciz "l"
	.byte 0x13, 0x01
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x01
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0x0a
	.zero 3
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xf9  ; "ù"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1a
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0x25
	.byte 0x01
	.asciz "Q"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.zero 2
	.byte 0xd6, 0x9b  ; "Ö"
	.asciz "#"
	.byte 0xda, 0x9b  ; "Ú"
	.asciz "#"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xf8  ; "ø"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xfa  ; "ú"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.asciz " "
	.ascii "!"
	.byte 0x01
	.asciz "2"
	.byte 0xb4  ; "´"
	.asciz "0*"
	.zero 6
	.asciz "DELETE DIRECTORY FROM HARD DISK:"
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xf8  ; "ø"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0xf9  ; "ù"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.asciz "6"
	.byte 0x11, 0x01
	.asciz "H"
	.byte 0xf6  ; "ö"
	.asciz "0*"
	.byte 0x02
	.zero 3
	.byte 0x0a
	.byte 0x00
	.asciz "PLEASE WAIT ..."
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xfc  ; "ü"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xde, 0x9b  ; "Þ"
	.asciz "#"
	.asciz "01*"
	.zero 6
	.asciz "?"
	.ascii "`"
	.byte 0x01
	.byte 0xfb  ; "û"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xfd  ; "ý"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 10
	.byte 0x01
	.zero 3
	.asciz "`1*"
	.zero 2
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0xfb  ; "û"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xfe  ; "þ"
	.byte 0x01
	.byte 0xfc  ; "ü"
	.byte 0x01, 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.asciz "5"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01
	.byte 0xfb  ; "û"
	.byte 0x01
	.fill 3, 1, 0xff
	.byte 0x01
	.byte 0xfd  ; "ý"
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0xaa  ; "ª"
	.asciz "1*"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xfb  ; "û"
	.byte 0x01
	.byte 0x00
	.byte 0x02, 0x02, 0x02
	.byte 0xfe  ; "þ"
	.byte 0x01, 0x08
	.byte 0x00
	.asciz "("
	.asciz "L"
	.byte 0x17, 0x01
	.byte 0xcd  ; "Í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x04
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xff
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x01, 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz ","
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0x13, 0x01
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd3  ; "Ó"
	.byte 0x00
	.byte 0x07
	.zero 7
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xff
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x00
	.byte 0x02, 0x08
	.byte 0x00
	.asciz ","
	.asciz "l"
	.byte 0x13, 0x01
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0x0a
	.zero 3
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xfb  ; "û"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x03, 0x02
	.byte 0xff
	.byte 0x01, 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.asciz "K"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc8  ; "È"
	.byte 0x00
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xfb  ; "û"
	.byte 0x01
	.fill 4, 1, 0xff
	.byte 0x02, 0x02, 0x08
	.byte 0x00
	.byte 0xf8  ; "ø"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x05, 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xe2, 0x9b  ; "â"
	.asciz "#"
	.byte 0xa8  ; "¨"
	.asciz "2*"
	.zero 6
	.asciz "R"
	.ascii "`"
	.byte 0x01, 0x04, 0x02
	.fill 2, 1, 0xff
	.byte 0x06, 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.asciz ";"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01, 0x04, 0x02, 0x07, 0x02, 0x08, 0x02, 0x05, 0x02, 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 10
	.byte 0x01
	.zero 3
	.byte 0xf2  ; "ò"
	.asciz "2*"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x06, 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.asciz "K"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc8  ; "È"
	.byte 0x00
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01, 0x04, 0x02, 0x09, 0x02, 0x0a, 0x02, 0x06, 0x02, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.asciz "L3*"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x08, 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xf8  ; "ø"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x04, 0x02, 0x0b, 0x02
	.fill 2, 1, 0xff
	.byte 0x08, 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "L"
	.byte 0x17, 0x01
	.byte 0xcd  ; "Í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x04
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x0a, 0x02
	.fill 2, 1, 0xff
	.byte 0x0c, 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz ","
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0x13, 0x01
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd3  ; "Ó"
	.byte 0x00
	.byte 0x07
	.zero 7
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x0a, 0x02
	.fill 4, 1, 0xff
	pushw 0x0802
	.byte 0x00
	.asciz ","
	.asciz "l"
	.byte 0x13, 0x01
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x1c
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0x0a
	.zero 3
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x0e, 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xe6, 0x9b  ; "æ"
	.asciz "#"
	.asciz " 4*"
	.zero 6
	.asciz "R"
	.ascii "`"
	.byte 0x01, 0x0d, 0x02
	.fill 2, 1, 0xff
	.byte 0x0f, 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.asciz ":"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01, 0x0d, 0x02, 0x10, 0x02, 0x11, 0x02, 0x0e, 0x02, 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 10
	.byte 0x01
	.zero 3
	.asciz "j4*"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x0f, 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.asciz "K"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc8  ; "È"
	.byte 0x00
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01, 0x0d, 0x02, 0x12, 0x02, 0x13, 0x02, 0x0f, 0x02, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0xc4  ; "Ä"
	.asciz "4*"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x11, 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xf8  ; "ø"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x0d, 0x02, 0x14, 0x02
	.fill 2, 1, 0xff
	.byte 0x11, 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz ","
	.byte 0x17, 0x01
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x05
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x13, 0x02
	.fill 2, 1, 0xff
	.byte 0x15, 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz ","
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x13, 0x01
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd3  ; "Ó"
	.byte 0x00
	.byte 0x07
	.zero 7
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x13, 0x02
	.fill 2, 1, 0xff
	.byte 0x16, 0x02, 0x14, 0x02, 0x08
	.byte 0x00
	.asciz ","
	.asciz "L"
	.byte 0x13, 0x01
	.asciz "{"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x1b
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0x0a
	.zero 3
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x13, 0x02
	.fill 4, 1, 0xff
	.byte 0x15, 0x02, 0x08
	.byte 0x00
	.asciz ","
	.asciz "|"
	.byte 0x13, 0x01
	.byte 0x9f  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "="
	.byte 0x07
	.zero 3
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x18, 0x02
	.fill 4, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1a
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0x25
	.byte 0x01
	.asciz "U"
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 2
	.byte 0xea, 0x9b  ; "ê"
	.asciz "#"
	.byte 0xee, 0x9b  ; "î"
	.asciz "#"
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x17, 0x02
	.fill 2, 1, 0xff
	.byte 0x19, 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz "\""
	.byte 0x17, 0x01
	.asciz "9"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "8"
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x17, 0x02
	.fill 4, 1, 0xff
	.byte 0x18, 0x02, 0x08
	.byte 0x00
	.asciz " "
	.asciz "8"
	.ascii "#"
	.byte 0x01
	.asciz "O"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "1"
	.byte 0x02
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.zero 2
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x1b, 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xf2, 0x9b  ; "ò"
	.asciz "#"
	.asciz ":6*"
	.zero 4
	.asciz "   HD FORMAT"
	.byte 0x00
	.asciz "6"
	.ascii "`"
	.byte 0x01, 0x1a, 0x02, 0x1c, 0x02
	.ascii " "
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "$"
	.asciz "&"
	.byte 0x1b, 0x01
	.byte 0xd5  ; "Õ"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.asciz "p6*"
	.byte 0x02
	.zero 7
	.byte 0x05
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x1b, 0x02
	.fill 2, 1, 0xff
	.byte 0x1d, 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "&"
	.asciz "F"
	.byte 0x19, 0x01
	.asciz "g"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x18
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0xf1  ; "ñ"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x1b, 0x02
	.fill 2, 1, 0xff
	.byte 0x1e, 0x02, 0x1c, 0x02, 0x08
	.byte 0x00
	.asciz "&"
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xd3  ; "Ó"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x1a
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0xf1  ; "ñ"
	.byte 0x00
	.zero 2
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x1b, 0x02
	.fill 2, 1, 0xff
	.byte 0x1f, 0x02, 0x1d, 0x02, 0x08
	.byte 0x00
	.asciz "&"
	.asciz "h"
	.byte 0x19, 0x01
	.byte 0xa7  ; "§"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x19
	.byte 0x00
	.byte 0x07
	.zero 7
	.byte 0x04
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x1b, 0x02
	.fill 4, 1, 0xff
	calr	0x0802
	.byte 0x00
	.asciz "&"
	.asciz "."
	.byte 0x19, 0x01
	.asciz "E"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "i"
	.ascii "`"
	.byte 0x01, 0x1a, 0x02
	.fill 2, 1, 0xff
	.ascii "!"
	.byte 0x02, 0x1b, 0x02, 0x08
	.byte 0x00
	.asciz "]"
	.byte 0x01
	.byte 0x00
	.asciz "w"
	.byte 0x1b
	.byte 0x00
	.asciz "'"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01, 0x1a, 0x02
	.fill 2, 1, 0xff
	.ascii "\""
	.byte 0x02
	.ascii " "
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.asciz "b7*"
	.asciz "CANCEL"
	.byte 0x00
	.asciz "R"
	.ascii "`"
	.byte 0x01, 0x1a, 0x02
	.fill 4, 1, 0xff
	.ascii "!"
	.byte 0x02, 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.asciz "6"
	.ascii "*"
	.byte 0x01
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "$"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1a
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0x25
	.byte 0x01
	.byte 0xd5  ; "Õ"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 2
	.byte 0xf6, 0x9b  ; "ö"
	.asciz "#"
	.byte 0xfa, 0x9b  ; "ú"
	.asciz "#"
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x23
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "%"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz " "
	.asciz "&"
	.byte 0x1f, 0x01
	.asciz "]"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "9"
	.zero 6
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x23
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "&"
	.byte 0x02
	.byte 0x24
	.byte 0x02, 0x08
	.byte 0x00
	.asciz " "
	.asciz "b"
	.byte 0x1f, 0x01
	.byte 0x99  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz ":"
	.zero 6
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x23
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "%"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz " "
	.byte 0x9a  ; ""
	.byte 0x00
	.byte 0x23
	.byte 0x01
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "1"
	.byte 0x02
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.zero 2
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "("
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0xfe, 0x9b  ; "þ"
	.asciz "#"
	.asciz "P8*"
	.zero 6
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0x27
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii ")"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x13
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.asciz "7"
	.ascii "`"
	.byte 0x01
	.byte 0x27
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "*"
	.byte 0x02
	pushw wa
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "d"
	.byte 0x0c
	.byte 0x00
	.byte 0xdb  ; "Û"
	.byte 0x00
	.asciz "3"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0x92  ; ""
	.asciz "8*"
	.byte 0x04
	.zero 3
	.byte 0xff
	.zero 3
	.asciz "HD-INFO"
	.zero 2
	.ascii "j"
	.byte 0x01
	.byte 0x27
	.byte 0x02
	pushw hl
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii ")"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.asciz "H"
	.ascii "<"
	.byte 0x01
	.byte 0xdd  ; "Ý"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 4
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01, 0x02
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x06
	.byte 0x9c  ; ""
	.asciz "#"
	.zero 4
	.byte 0x08
	.byte 0x9c  ; ""
	.asciz "#"
	.zero 2
	.asciz "."
	.ascii "`"
	.byte 0x01
	pushw de
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0x3c
	.byte 0x01
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "-"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01, 0x0a
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0x1a
	.asciz "9*"
	.byte 0x01
	.zero 3
	.asciz "DEBUG MEMO SCREEN"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	pushw ix
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "."
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.zero 3
	.byte 0x7f
	.byte 0x00
	.asciz "F"
	.ascii "`"
	.byte 0x01
	pushw ix
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "-"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x0a
	.byte 0x00
	.asciz "("
	.ascii "4"
	.byte 0x01
	.byte 0xe5  ; "å"
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "0"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01, 0x0e
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0x86  ; ""
	.asciz "9*"
	.zero 6
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0x2f
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "1"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.asciz "9"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x2f
	.byte 0x02
	.byte 0x32
	.byte 0x02
	.byte 0x35
	.byte 0x02
	.byte 0x30
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz ","
	.byte 0x17, 0x01
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x05
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x31
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "3"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz ","
	.byte 0x9e  ; ""
	.byte 0x00
	.byte 0x13, 0x01
	.byte 0xcf  ; "Ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd3  ; "Ó"
	.byte 0x00
	.byte 0x07
	.zero 7
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x31
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "4"
	.byte 0x02
	.byte 0x32
	.byte 0x02, 0x08
	.byte 0x00
	.asciz ","
	.asciz "L"
	.byte 0x13, 0x01
	.asciz "{"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x1b
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0x0a
	.zero 3
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x31
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "3"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz ","
	.asciz "|"
	.byte 0x13, 0x01
	.byte 0x9f  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "<"
	.byte 0x07
	.zero 3
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01
	.byte 0x2f
	.byte 0x02
	.byte 0x36
	.byte 0x02
	.byte 0x37
	.byte 0x02
	.byte 0x31
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 10
	.byte 0x01
	.zero 3
	.asciz "x:*"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x35
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.asciz "K"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc8  ; "È"
	.byte 0x00
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01
	.byte 0x2f
	.byte 0x02
	.byte 0x38
	.byte 0x02
	.byte 0x39
	.byte 0x02
	.byte 0x35
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 10
	.byte 0x01
	.zero 3
	.byte 0xd2  ; "Ò"
	.asciz ":*"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x37
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.asciz "K"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc8  ; "È"
	.byte 0x00
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01
	.byte 0x2f
	.byte 0x02
	.byte 0x3a
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "7"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.asciz ",;*"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x39
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xf8  ; "ø"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "<"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01, 0x12
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0x82  ; ""
	.asciz ";*"
	.zero 6
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0x3b
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "="
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x1a
	.byte 0x00
	pushw de
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01
	.byte 0x3b
	.byte 0x02
	.byte 0x3e
	.byte 0x02
	.byte 0x3f
	.byte 0x02
	.byte 0x3c
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.asciz "K"
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 10
	.byte 0x01
	.zero 3
	.byte 0xcc  ; "Ì"
	.asciz ";*"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x3d
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.asciz "K"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc8  ; "È"
	.byte 0x00
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01
	.byte 0x3b
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "@"
	.byte 0x02
	.byte 0x3d
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.asciz "&<*"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x3b
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "A"
	.byte 0x02
	.byte 0x3f
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xf8  ; "ø"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x3b
	.byte 0x02
	.byte 0x42
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "@"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "4"
	.byte 0x17, 0x01
	.byte 0xcd  ; "Í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x41
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "C"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz "\\"
	.byte 0x17, 0x01
	.byte 0x97  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "C"
	.byte 0x07
	.zero 3
	.byte 0x0a
	.zero 3
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x41
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "B"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xcd  ; "Í"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd3  ; "Ó"
	.byte 0x00
	.byte 0x07
	.zero 7
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "E"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01, 0x16
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0xfa  ; "ú"
	.asciz "<*"
	.byte 0xaf  ; "¯"
	.byte 0x00
	.zero 2
	.asciz "EDIT FLS NAME"
	.asciz "M"
	.ascii "`"
	.byte 0x01
	.byte 0x44
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "F"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x18
	.byte 0x00
	pushw de
	.byte 0x01
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0x44
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "G"
	.byte 0x02
	.byte 0x45
	.byte 0x02, 0x18
	.byte 0x00
	.asciz " "
	.zero 2
	.asciz "?"
	.byte 0x1f
	.byte 0x00
	.ascii "c"
	.byte 0x01, 0x7f
	.byte 0x00
	.asciz " "
	.ascii "`"
	.byte 0x01
	.byte 0x44
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "H"
	.byte 0x02
	.byte 0x46
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x19, 0x01
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x37
	.byte 0x01
	.byte 0xb1  ; "±"
	.byte 0x00
	.byte 0xf2  ; "ò"
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x0b
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x17
	.byte 0x00
	pushw de
	.byte 0x01
	.asciz " "
	.ascii "`"
	.byte 0x01
	.byte 0x44
	.byte 0x02
	popw bc
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "G"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "v"
	.asciz "&"
	.byte 0x87  ; ""
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x8a  ; ""
	.byte 0x00
	.zero 2
	.byte 0x17
	.byte 0x00
	pushw de
	.byte 0x01
	.asciz "+"
	.ascii "`"
	.byte 0x01
	popw wa
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.asciz "w"
	.asciz "$"
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0xb4  ; "´"
	.asciz "=*"
	.zero 4
	.byte 0xf9  ; "ù"
	.byte 0x00
	.asciz "LST"
	.byte 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "K"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01, 0x1a
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0xe2  ; "â"
	.asciz "=*"
	.zero 6
	.asciz "R"
	.ascii "`"
	.byte 0x01
	popw de
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "L"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.asciz "7"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01
	popw de
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "M"
	.byte 0x02
	popw hl
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.asciz ",>*"
	.zero 2
	.asciz "6"
	.ascii "`"
	.byte 0x01
	popw de
	.byte 0x02
	popw iz
	.byte 0x02
	.byte 0x50
	.byte 0x02
	popw ix
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "T"
	.byte 0x17, 0x01
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.asciz "V>*"
	.byte 0x02
	.zero 7
	.byte 0x03
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	popw iy
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "O"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "*"
	.asciz "x"
	.byte 0x1d, 0x01
	.byte 0x9d  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x1d
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	popw iy
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "N"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x1e
	.byte 0x00
	.byte 0x07
	.zero 7
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	popw de
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "Q"
	.byte 0x02
	popw iy
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "^"
	.byte 0x17, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	popw de
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "P"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xf8  ; "ø"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "S"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01, 0x1e
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "*?*"
	.zero 6
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0x52
	.byte 0x02
	.byte 0x54
	.byte 0x02
	.byte 0x55
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "$"
	.asciz "T"
	.byte 0x1b, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.asciz "T?*"
	.byte 0x02
	.zero 7
	.byte 0x03
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x53
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "&"
	.asciz "|"
	.byte 0x19, 0x01
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x1f
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x52
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "V"
	.byte 0x02
	.byte 0x53
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "'"
	.asciz "^"
	.byte 0x1a, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x52
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "U"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.zero 8
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "X"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x22
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0xfe  ; "þ"
	.asciz "?*"
	.zero 6
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0x57
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "Y"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "$"
	.asciz "T"
	.byte 0x1b, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.asciz "(@*"
	.byte 0x02
	.zero 7
	.byte 0x03
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x57
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "Z"
	.byte 0x02
	pop xwa
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "z"
	.byte 0x17, 0x01
	.byte 0xa1  ; "¡"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz " "
	.zero 4
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x57
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "["
	.byte 0x02
	pop xbc
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "'"
	.asciz "^"
	.byte 0x1a, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x57
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "Z"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.zero 8
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "]"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x26
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0xd2  ; "Ò"
	.asciz "@*"
	.zero 6
	.asciz "6"
	.ascii "`"
	.byte 0x01
	pop xix
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "^"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "$"
	.asciz "T"
	.byte 0x1b, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xfc  ; "ü"
	.asciz "@*"
	.byte 0x02
	.zero 7
	.byte 0x03
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	pop xix
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "_"
	.byte 0x02
	pop xiy
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "z"
	.byte 0x17, 0x01
	.byte 0xa1  ; "¡"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "!"
	.zero 4
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	pop xix
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "`"
	.byte 0x02
	pop xiz
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "'"
	.asciz "^"
	.byte 0x1a, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	pop xix
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "_"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.zero 8
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "b"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	pushw de
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0xa6  ; "¦"
	.asciz "A*"
	.zero 6
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.ascii "a"
	.byte 0x02
	.ascii "c"
	.byte 0x02
	.ascii "d"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "$"
	.asciz "T"
	.byte 0x1b, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xd0  ; "Ð"
	.asciz "A*"
	.byte 0x02
	.zero 7
	.byte 0x03
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.ascii "b"
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "\""
	.asciz "|"
	.byte 0x15, 0x01
	.byte 0xa1  ; "¡"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "\""
	.byte 0x07
	.zero 3
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.ascii "a"
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "e"
	.byte 0x02
	.ascii "b"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "'"
	.asciz "^"
	.byte 0x1a, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.ascii "a"
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "d"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.zero 8
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "g"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	pushw iz
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "zB*"
	.zero 6
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.ascii "f"
	.byte 0x02
	.ascii "h"
	.byte 0x02
	.ascii "i"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "$"
	.asciz "T"
	.byte 0x1b, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xa4  ; "¤"
	.asciz "B*"
	.byte 0x02
	.zero 7
	.byte 0x03
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.ascii "g"
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "&"
	.asciz "|"
	.byte 0x19, 0x01
	.byte 0xa1  ; "¡"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "#"
	.byte 0x07
	.zero 3
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.ascii "f"
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "j"
	.byte 0x02
	.ascii "g"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "'"
	.asciz "^"
	.byte 0x1a, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.ascii "f"
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "i"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.zero 8
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "l"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x32
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "NC*"
	.zero 6
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.ascii "k"
	.byte 0x02
	.ascii "m"
	.byte 0x02
	.ascii "n"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "$"
	.asciz "T"
	.byte 0x1b, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.asciz "xC*"
	.byte 0x02
	.zero 7
	.byte 0x03
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.ascii "l"
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "&"
	.asciz "x"
	.byte 0x19, 0x01
	.byte 0x9d  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "$"
	.byte 0x07
	.zero 3
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.ascii "k"
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "o"
	.byte 0x02
	.ascii "l"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "'"
	.asciz "^"
	.byte 0x1a, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.ascii "k"
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "n"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.zero 8
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "q"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x36
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "\"D*"
	.zero 6
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.ascii "p"
	.byte 0x02
	.ascii "r"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "$"
	.asciz "T"
	.byte 0x1b, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.asciz "LD*"
	.byte 0x02
	.zero 7
	.byte 0x03
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.ascii "q"
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "s"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "'"
	.asciz "^"
	.byte 0x1a, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.ascii "q"
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "t"
	.byte 0x02
	.ascii "r"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.zero 8
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.ascii "q"
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "s"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "&"
	.asciz "x"
	.byte 0x19, 0x01
	.byte 0x9d  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "%"
	.byte 0x07
	.zero 3
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "v"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x3a
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0xf6  ; "ö"
	.asciz "D*"
	.zero 6
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.ascii "u"
	.byte 0x02
	.ascii "w"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "$"
	.asciz "T"
	.byte 0x1b, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.asciz " E*"
	.byte 0x02
	.zero 7
	.byte 0x03
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.ascii "v"
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "x"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "("
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd4  ; "Ô"
	.byte 0x00
	.zero 8
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.ascii "v"
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "y"
	.byte 0x02
	.ascii "w"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "'"
	.asciz "^"
	.byte 0x1a, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.ascii "v"
	.byte 0x02
	.fill 4, 1, 0xff
	.ascii "x"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "&"
	.asciz "x"
	.byte 0x19, 0x01
	.byte 0x9d  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "&"
	.byte 0x07
	.zero 3
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.ascii "{"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x3e
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0xca  ; "Ê"
	.asciz "E*"
	.zero 6
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.ascii "z"
	.byte 0x02
	.fill 2, 1, 0xff
	.ascii "|"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.asciz "8"
	.ascii "*"
	.byte 0x01
	.asciz "?"
	.ascii "`"
	.byte 0x01
	.ascii "z"
	.byte 0x02
	.byte 0x7d
	.byte 0x02
	.byte 0x7e
	.byte 0x02
	.byte 0x7b
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x06
	.byte 0x00
	.byte 0x07
	.zero 3
	.byte 0x14
	.asciz "F*"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x7c
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xf8  ; "ø"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0x3b
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.ascii "z"
	.byte 0x02, 0x7f, 0x02
	.fill 2, 1, 0xff
	.ascii "|"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "T"
	.byte 0x17, 0x01
	.byte 0xa8  ; "¨"
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.asciz "hF*"
	.byte 0x02
	.zero 7
	.byte 0x02
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x7e
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x80  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz "^"
	.byte 0x17, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x7e
	.byte 0x02
	.fill 4, 1, 0xff
	jrl	nc, 0x0802
	.byte 0x00
	.asciz "("
	.asciz "z"
	.byte 0x17, 0x01
	.byte 0x9f  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "'"
	.byte 0x07
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x02
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x82  ; ""
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x42
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0xe8  ; "è"
	.asciz "F*"
	.byte 0x01
	.zero 3
	.asciz "            "
	.byte 0x00
	.asciz "i"
	.ascii "`"
	.byte 0x01
	.byte 0x81  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x83  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "L"
	.byte 0x01
	.byte 0x00
	.asciz "f"
	.byte 0x1b
	.byte 0x00
	.asciz "'"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0x81  ; ""
	.byte 0x02
	.byte 0x84  ; ""
	.byte 0x02
	.byte 0x88  ; ""
	.byte 0x02
	.byte 0x82  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x19
	.byte 0x00
	.asciz "D"
	.ascii "&"
	.byte 0x01
	.asciz "w"
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "8G*"
	.zero 6
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x83  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x85  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1d
	.byte 0x00
	.asciz "E"
	.asciz " "
	.asciz "O"
	.asciz "ZG*"
	.byte 0x03
	.zero 7
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x83  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x86  ; ""
	.byte 0x02
	.byte 0x84  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x1d
	.byte 0x00
	.asciz "T"
	.byte 0xe8  ; "è"
	.byte 0x00
	.asciz "f"
	.asciz "|G*"
	.zero 6

HDAE5000_Credits:	; 0x2A477C
	; Developer credits (Technosoft/KEY SOFT)
	.asciz "Technosoft, CH-Samstagern"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x83  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x87  ; ""
	.byte 0x02
	.byte 0x85  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x1d
	.byte 0x00
	.asciz "d"
	.byte 0xe8  ; "è"
	.byte 0x00
	.asciz "v"
	.byte 0xb6  ; "¶"
	.asciz "G*"
	.zero 6
	.asciz "Pointstyle, CH-Buttisholz"
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x83  ; ""
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x86  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.asciz "E"
	.byte 0x1e, 0x01
	.asciz "T"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x11
	.byte 0x00
	.byte 0x03
	.zero 5
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0x81  ; ""
	.byte 0x02
	.byte 0x89  ; ""
	.byte 0x02
	.byte 0x8d  ; ""
	.byte 0x02
	.byte 0x83  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x19
	.byte 0x00
	.asciz "x"
	.ascii "&"
	.byte 0x01
	.byte 0xb3  ; "³"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "\"H*"
	.zero 6
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x88  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x8a  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1d
	.byte 0x00
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0x08, 0x01
	.byte 0x9b  ; ""
	.byte 0x00
	.asciz "DH*"
	.zero 6
	.asciz "KEY SOFT SERVICE, CH-Schenkon"
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x88  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x8b  ; ""
	.byte 0x02
	.byte 0x89  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x1d
	.byte 0x00
	.byte 0x9a  ; ""
	.byte 0x00
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0xa4  ; "¤"
	.byte 0x00
	.byte 0x82  ; ""
	.asciz "H*"
	.byte 0x03
	.zero 5
	.asciz "Fax.  +41-41-922 03 15"
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x88  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x8c  ; ""
	.byte 0x02
	.byte 0x8a  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x1d
	.byte 0x00
	.byte 0xa5  ; "¥"
	.byte 0x00
	.byte 0xda  ; "Ú"
	.byte 0x00
	.byte 0xaf  ; "¯"
	.byte 0x00
	.byte 0xba  ; "º"
	.asciz "H*"
	.byte 0x03
	.zero 5
	.asciz "email:keysoftservice@bluewin.ch"
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x88  ; ""
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x8b  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.asciz "z"
	.byte 0x1e, 0x01
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x12
	.byte 0x00
	.byte 0x03
	.zero 5
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0x81  ; ""
	.byte 0x02
	.byte 0x8e  ; ""
	.byte 0x02
	.byte 0x8f  ; ""
	.byte 0x02
	.byte 0x88  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x19
	.byte 0x00
	.byte 0xb4  ; "´"
	.byte 0x00
	.byte 0x26
	.byte 0x01
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz ",I*"
	.zero 6
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x8d  ; ""
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0xb6  ; "¶"
	.byte 0x00
	.byte 0x26
	.byte 0x01
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x13
	.byte 0x00
	.byte 0x03
	.zero 5
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0x81  ; ""
	.byte 0x02
	.byte 0x90  ; ""
	.byte 0x02
	.byte 0x92  ; ""
	.byte 0x02
	.byte 0x8d  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x19
	.byte 0x00
	.byte 0xcd  ; "Í"
	.byte 0x00
	.byte 0x26
	.byte 0x01
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x80  ; ""
	.asciz "I*"
	.zero 6
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.zero 3
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0x8f  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x91  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1d
	.byte 0x00
	.byte 0xda  ; "Ú"
	.byte 0x00
	.byte 0x21
	.byte 0x01
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0xa2  ; "¢"
	.asciz "I*"
	.byte 0x05
	.zero 5
	.asciz "Mr. T.Hamaguchi and Mr. M.Kitajima"
	.byte 0x00
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x8f  ; ""
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x90  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0xce  ; "Î"
	.byte 0x00
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0xdd  ; "Ý"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x14
	.byte 0x00
	.byte 0x03
	.zero 5
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0x81  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x93  ; ""
	.byte 0x02
	.byte 0x8f  ; ""
	.byte 0x02, 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x13
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x81  ; ""
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x92  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "e"
	.zero 2
	.byte 0x18, 0x01, 0x1f
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x0a
	.byte 0x00
	.byte 0x09
	.zero 3
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x95  ; ""
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x1a
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.byte 0x25
	.byte 0x01
	.asciz "Y"
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.zero 2
	.ascii "F"
	.byte 0x9c  ; ""
	.asciz "#"
	.ascii "J"
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x94  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x96  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz "\""
	.byte 0x17, 0x01
	.asciz "9"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz ";"
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x94  ; ""
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x95  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.asciz " "
	.asciz ":"
	.ascii "#"
	.byte 0x01
	.asciz "Q"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "1"
	.byte 0x02
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.zero 2
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x09
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x98  ; ""
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	popw iz
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0x97  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x9a  ; ""
	.byte 0x02
	.byte 0x98  ; ""
	.byte 0x02, 0x18
	.zero 3
	.asciz " "
	.byte 0x1f
	.byte 0x00
	.asciz "?"
	.asciz ">"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0x97  ; ""
	.byte 0x02
	.byte 0x9b  ; ""
	.byte 0x02
	.byte 0x9c  ; ""
	.byte 0x02
	.byte 0x99  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "T"
	.byte 0x17, 0x01
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x10
	.asciz "K*"
	.byte 0x02
	.zero 7
	.byte 0x03
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x9a  ; ""
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz "x"
	.byte 0x17, 0x01
	.byte 0xbf  ; "¿"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz ")"
	.byte 0x07
	.zero 3
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x04
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x97  ; ""
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x9a  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "^"
	.byte 0x17, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x09
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x9e  ; ""
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x52
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0x9d  ; ""
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xa0  ; " "
	.byte 0x02
	.byte 0x9e  ; ""
	.byte 0x02, 0x18
	.zero 3
	.asciz "$"
	.byte 0x1f
	.byte 0x00
	.asciz "C"
	.asciz ">"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0x9d  ; ""
	.byte 0x02
	.byte 0xa1  ; "¡"
	.byte 0x02
	.byte 0xa2  ; "¢"
	.byte 0x02
	.byte 0x9f  ; ""
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "T"
	.byte 0x17, 0x01
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xca  ; "Ê"
	.asciz "K*"
	.byte 0x02
	.zero 7
	.byte 0x03
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xa0  ; " "
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz "^"
	.byte 0x17, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0x9d  ; ""
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0xa0  ; " "
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "x"
	.byte 0x17, 0x01
	.byte 0xbf  ; "¿"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz ")"
	.byte 0x07
	.zero 3
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x04
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x09
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xa4  ; "¤"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x56
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0xa3  ; "£"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xa5  ; "¥"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0xa3  ; "£"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xa6  ; "¦"
	.byte 0x02
	.byte 0xa4  ; "¤"
	.byte 0x02, 0x18
	.zero 3
	.asciz " "
	.byte 0x1f
	.byte 0x00
	.asciz "?"
	.asciz ">"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xa3  ; "£"
	.byte 0x02
	.byte 0xa7  ; "§"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xa5  ; "¥"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "T"
	.byte 0x17, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x9e  ; ""
	.asciz "L*"
	.zero 8
	.byte 0x05
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xa6  ; "¦"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xa8  ; "¨"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz "^"
	.byte 0x17, 0x01
	.asciz "u"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xa6  ; "¦"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0xa7  ; "§"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "|"
	.byte 0x17, 0x01
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "*"
	.byte 0x07
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.zero 2
	.byte 0x04
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x09
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xaa  ; "ª"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	pop xde
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0xa9  ; "©"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xab  ; "«"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0xa9  ; "©"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xac  ; "¬"
	.byte 0x02
	.byte 0xaa  ; "ª"
	.byte 0x02, 0x18
	.zero 3
	.asciz " "
	.byte 0x1f
	.byte 0x00
	.asciz "?"
	.asciz ">"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xa9  ; "©"
	.byte 0x02
	.byte 0xad  ; "­"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xab  ; "«"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "2"
	.byte 0x17, 0x01
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.asciz "rM*"
	.byte 0x02
	.zero 7
	.byte 0x04
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xac  ; "¬"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xae  ; "®"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz "8"
	.byte 0x17, 0x01
	.asciz "O"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xac  ; "¬"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xaf  ; "¯"
	.byte 0x02
	.byte 0xad  ; "­"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "R"
	.byte 0x17, 0x01
	.byte 0x99  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "+"
	.byte 0x07
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.zero 2
	.byte 0x04
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xac  ; "¬"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0xae  ; "®"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.byte 0x98  ; ""
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz ","
	.byte 0x07
	.zero 3
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x09
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xb1  ; "±"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	pop xiz
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0xb0  ; "°"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xb2  ; "²"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0xe2  ; "â"
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0xb0  ; "°"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xb3  ; "³"
	.byte 0x02
	.byte 0xb1  ; "±"
	.byte 0x02, 0x18
	.zero 3
	.asciz " "
	.byte 0x1f
	.byte 0x00
	.asciz "?"
	.asciz ">"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xb0  ; "°"
	.byte 0x02
	.byte 0xb4  ; "´"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xb2  ; "²"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "2"
	.byte 0x17, 0x01
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.asciz "pN*"
	.byte 0x02
	.zero 7
	.byte 0x04
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xb3  ; "³"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xb5  ; "µ"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "("
	.byte 0x8c  ; ""
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xcf  ; "Ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "."
	.zero 8
	.byte 0x04
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xb3  ; "³"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xb6  ; "¶"
	.byte 0x02
	.byte 0xb4  ; "´"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "8"
	.byte 0x17, 0x01
	.asciz "O"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xb3  ; "³"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0xb5  ; "µ"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "T"
	.byte 0x17, 0x01
	.byte 0x87  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "-"
	.byte 0x07
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.zero 2
	.byte 0x03
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x09
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xb8  ; "¸"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.ascii "b"
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0xb7  ; "·"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xb9  ; "¹"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.asciz "?"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xb7  ; "·"
	.byte 0x02
	.byte 0xba  ; "º"
	.byte 0x02
	.byte 0xbb  ; "»"
	.byte 0x02
	.byte 0xb8  ; "¸"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "T"
	.byte 0x17, 0x01
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.asciz "TO*"
	.byte 0x02
	.zero 7
	.byte 0x02
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xb9  ; "¹"
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz "x"
	.byte 0x17, 0x01
	.byte 0x9f  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "/"
	.byte 0x07
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xb7  ; "·"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0xb9  ; "¹"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "\\"
	.byte 0x17, 0x01
	.asciz "s"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x09
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xbd  ; "½"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.ascii "f"
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0xbc  ; "¼"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xbe  ; "¾"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.asciz "?"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xbc  ; "¼"
	.byte 0x02
	.byte 0xbf  ; "¿"
	.byte 0x02
	.byte 0xc0  ; "À"
	.byte 0x02
	.byte 0xbd  ; "½"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "T"
	.byte 0x17, 0x01
	.byte 0xa3  ; "£"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x0e
	.asciz "P*"
	.byte 0x02
	.zero 7
	.byte 0x02
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xbe  ; "¾"
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz "\\"
	.byte 0x17, 0x01
	.asciz "s"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd2  ; "Ò"
	.byte 0x00
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xbc  ; "¼"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0xbe  ; "¾"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz ","
	.asciz "x"
	.byte 0x11, 0x01
	.byte 0x9f  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "0"
	.byte 0x07
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x09
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xc2  ; "Â"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.ascii "j"
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xc1  ; "Á"
	.byte 0x02
	.byte 0xc3  ; "Ã"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "<"
	.asciz "T"
	.byte 0x03, 0x01
	.byte 0x83  ; ""
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.byte 0xae  ; "®"
	.asciz "P*"
	.byte 0x01
	.zero 7
	.byte 0x01
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xc2  ; "Â"
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "H"
	.asciz "b"
	.byte 0xf1  ; "ñ"
	.byte 0x00
	.asciz "y"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "1"
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x09
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xc5  ; "Å"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.ascii "n"
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0xc4  ; "Ä"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xc6  ; "Æ"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x1a, 0x02, 0x7f
	.byte 0x00
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0xc4  ; "Ä"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xc7  ; "Ç"
	.byte 0x02
	.byte 0xc5  ; "Å"
	.byte 0x02, 0x18
	.zero 3
	.asciz " "
	.byte 0x1f
	.byte 0x00
	.asciz "?"
	.asciz ">"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xc4  ; "Ä"
	.byte 0x02
	.byte 0xc8  ; "È"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xc6  ; "Æ"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz " "
	.asciz "N"
	.byte 0x1f, 0x01
	.byte 0xe3  ; "ã"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.asciz "XQ*"
	.byte 0x02
	.zero 7
	.byte 0x05
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xc7  ; "Ç"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xc9  ; "É"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "("
	.asciz "t"
	.byte 0x17, 0x01
	.byte 0x97  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "3"
	.zero 4
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xc7  ; "Ç"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xca  ; "Ê"
	.byte 0x02
	.byte 0xc8  ; "È"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.asciz "P"
	.ascii "!"
	.byte 0x01
	.asciz "s"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "2"
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xc7  ; "Ç"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0xc9  ; "É"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xe3  ; "ã"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "4"
	.byte 0x07
	.zero 7
	.byte 0x04
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x09
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xcc  ; "Ì"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.ascii "r"
	.byte 0x9c  ; ""
	.asciz "#"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xcd  ; "Í"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x1a, 0x02, 0x7f
	.byte 0x00
	.asciz "R"
	.ascii "`"
	.byte 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xce  ; "Î"
	.byte 0x02
	.byte 0xcc  ; "Ì"
	.byte 0x02, 0x18
	.zero 3
	.asciz " "
	.byte 0x1f
	.byte 0x00
	.asciz "?"
	.asciz ">"
	.ascii "*"
	.byte 0x01
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x02
	.byte 0xcf  ; "Ï"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xcd  ; "Í"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz " "
	.asciz "N"
	.byte 0x1f, 0x01
	.byte 0xe3  ; "ã"
	.byte 0x00
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.asciz "VR*"
	.byte 0x02
	.zero 7
	.byte 0x05
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xce  ; "Î"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xd0  ; "Ð"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "\""
	.asciz "P"
	.ascii "%"
	.byte 0x01
	.asciz "s"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "5"
	.byte 0x02
	.zero 7
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xce  ; "Î"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xd1  ; "Ñ"
	.byte 0x02
	.byte 0xcf  ; "Ï"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.asciz "t"
	.byte 0x17, 0x01
	.byte 0x97  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "6"
	.zero 4
	.byte 0xfb  ; "û"
	.byte 0x00
	.zero 2
	.byte 0x02
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xce  ; "Î"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0xd0  ; "Ð"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.byte 0x98  ; ""
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xdf  ; "ß"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "7"
	.byte 0x07
	.zero 7
	.byte 0x04
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd3  ; "Ó"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	.ascii "v"
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0x00
	.asciz "S*"
	.zero 6
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xd4  ; "Ô"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.asciz "\""
	.byte 0x7f
	.byte 0x00
	.asciz "("
	.ascii "`"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xd5  ; "Õ"
	.byte 0x02
	.byte 0xd3  ; "Ó"
	.byte 0x02, 0x18
	.zero 3
	.asciz " "
	.byte 0x1f
	.byte 0x00
	.asciz "?"
	.byte 0x01
	.byte 0x00
	.byte 0xd8  ; "Ø"
	.byte 0x02, 0x7f
	.byte 0x00
	.asciz "("
	.ascii "`"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xd6  ; "Ö"
	.byte 0x02
	.byte 0xd4  ; "Ô"
	.byte 0x02, 0x18
	.zero 3
	.asciz "@"
	.byte 0x1f
	.byte 0x00
	.asciz "_"
	.byte 0x02
	.byte 0x00
	.byte 0x10, 0x01, 0x7f
	.byte 0x00
	.asciz ")"
	.ascii "`"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xd7  ; "×"
	.byte 0x02
	.byte 0xd5  ; "Õ"
	.byte 0x02, 0x18
	.zero 3
	.asciz "`"
	.byte 0x1f
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0x0d
	.byte 0x00
	popw de
	.byte 0x01, 0x08
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xd2  ; "Ò"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0xd6  ; "Ö"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.byte 0x3b
	.byte 0x01, 0x17
	.byte 0x00
	.byte 0xf3  ; "ó"
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.ascii "z"
	.byte 0x9c  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xd9  ; "Ù"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x08
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 4
	.ascii "|"
	.byte 0x9c  ; ""
	.asciz "#"
	adc	(xwa), d
	.asciz "#"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xda  ; "Ú"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz ","
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.asciz "K"
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x02
	.zero 9
	.byte 0x01
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.asciz "\""
	.ascii "`"
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xdb  ; "Û"
	.byte 0x02
	.byte 0xd9  ; "Ù"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "T"
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xc3  ; "Ã"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.zero 8
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x03
	.zero 3
	.ascii "j"
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xdc  ; "Ü"
	.byte 0x02
	.byte 0xda  ; "Ú"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz ","
	.asciz "4"
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xd7  ; "×"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xff
	.byte 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	adc	(xix), d
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.byte 0x88, 0x9c  ; ""
	.asciz "#"
	.zero 4
	.byte 0x8a, 0x9c  ; ""
	.asciz "#"
	.zero 2
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xdd  ; "Ý"
	.byte 0x02
	.byte 0xdb  ; "Û"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xed  ; "í"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc9  ; "É"
	.byte 0x00
	.byte 0x01
	.zero 9
	.byte 0x05
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "-"
	.ascii "`"
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xde  ; "Þ"
	.byte 0x02
	.byte 0xdc  ; "Ü"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "*"
	.zero 2
	.asciz "E"
	.byte 0x1b
	.byte 0x00
	.byte 0xad  ; "­"
	.byte 0x00
	.zero 2
	.asciz "+"
	.ascii "`"
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xdf  ; "ß"
	.byte 0x02
	.byte 0xdd  ; "Ý"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "F"
	.byte 0x07
	.byte 0x00
	.byte 0xee  ; "î"
	.byte 0x00
	.byte 0x19
	.byte 0x00
	.byte 0xa6  ; "¦"
	.asciz "T*"
	.byte 0x04
	.zero 3
	.byte 0xff
	.byte 0x00
	.asciz "FILE SELECT A-Z"
	.byte 0x1f
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xe0  ; "à"
	.byte 0x02
	.byte 0xde  ; "Þ"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x09, 0x01
	.asciz "$"
	.ascii "7"
	.byte 0x01
	.asciz "="
	.byte 0x07
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x03
	.zero 9
	.byte 0x08
	.byte 0x00
	.byte 0x06
	.byte 0x00
	.asciz "0"
	.ascii "`"
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xe1  ; "á"
	.byte 0x02
	.byte 0xdf  ; "ß"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x36
	.byte 0x01
	.asciz "M"
	.ascii "?"
	.byte 0x01
	.asciz "_"
	.byte 0x06
	.asciz "U*"
	.zero 4
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x09
	.zero 3
	.ascii " "
	.byte 0x01, 0x06
	.byte 0x00
	.asciz "~80"
	.asciz "."
	.ascii "`"
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xe2  ; "â"
	.byte 0x02
	.byte 0xe0  ; "à"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x39
	.byte 0x01
	.asciz "("
	.ascii "9"
	.byte 0x01
	.asciz "O"
	.byte 0xf4  ; "ô"
	.byte 0x00
	.byte 0x01
	.zero 3
	.ascii "j"
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.byte 0xe3  ; "ã"
	.byte 0x02
	.byte 0xe5  ; "å"
	.byte 0x02
	.byte 0xe1  ; "á"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz ","
	.byte 0x1e
	.byte 0x00
	.byte 0xeb  ; "ë"
	.byte 0x00
	.asciz "/"
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "d"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.ascii "@"
	.byte 0x01
	.byte 0x8c, 0x9c  ; ""
	.asciz "#"
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	adc	(xwa), ix
	.asciz "#"
	.zero 4
	adc	(xde), ix
	.asciz "#"
	.zero 2
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xe2  ; "â"
	.byte 0x02
	.byte 0xe4  ; "ä"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "N"
	.asciz " "
	.byte 0xed  ; "í"
	.byte 0x00
	.asciz "/"
	.byte 0x08
	.zero 3
	.byte 0x88  ; ""
	.asciz "U*"
	.byte 0x03
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "Evergreens slow / 12"
	.byte 0x00
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xe3  ; "ã"
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz ","
	.asciz " "
	.byte 0x7f
	.byte 0x00
	.asciz "/"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xc6  ; "Æ"
	.asciz "U*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "LOC.:"
	.byte 0x10
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xe6  ; "æ"
	.byte 0x02
	.byte 0xe2  ; "â"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "<"
	.asciz "T"
	.byte 0x03, 0x01
	.byte 0x83  ; ""
	.byte 0x00
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xd8  ; "Ø"
	.byte 0x02
	.byte 0xe7  ; "ç"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xe5  ; "å"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.asciz "d"
	.ascii "?"
	.byte 0x01
	.byte 0xd7  ; "×"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x0a
	.asciz "V*"
	.zero 6
	.byte 0x01
	.byte 0x00
	.byte 0x03
	.zero 3
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xe6  ; "æ"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xe8  ; "è"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0xae  ; "®"
	.byte 0x00
	.byte 0x3f
	.byte 0x01
	.byte 0xbf  ; "¿"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "4V*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x01
	.byte 0x00

HDAE5000_Demo_Data:	; 0x2A5634
	; Demo song data and rhythm custom UI
	.asciz "RHYTHM CUSTOM"
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xe6  ; "æ"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xe9  ; "é"
	.byte 0x02
	.byte 0xe7  ; "ç"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0xba  ; "º"
	.byte 0x00
	.byte 0x3f
	.byte 0x01
	.byte 0xcb  ; "Ë"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "jV*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x01
	.byte 0x00
	.asciz "USER MIDI"
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xe6  ; "æ"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xea  ; "ê"
	.byte 0x02
	.byte 0xe8  ; "è"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0xc6  ; "Æ"
	.byte 0x00
	.byte 0x3f
	.byte 0x01
	.byte 0xd7  ; "×"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x9c  ; ""
	.asciz "V*"
	.byte 0x03
	.zero 3
	.byte 0x0d
	.zero 3
	.byte 0x01
	.byte 0x00
	.asciz "TECH LYRICS"
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xe6  ; "æ"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xeb  ; "ë"
	.byte 0x02
	.byte 0xe9  ; "é"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0xa2  ; "¢"
	.byte 0x00
	.byte 0x3f
	.byte 0x01
	.byte 0xb3  ; "³"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xd0  ; "Ð"
	.asciz "V*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x01
	.byte 0x00
	.asciz "MSP"
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xe6  ; "æ"
	.byte 0x02
	.byte 0xec  ; "ì"
	.byte 0x02
	.byte 0xed  ; "í"
	.byte 0x02
	.byte 0xea  ; "ê"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0x96  ; ""
	.byte 0x00
	.byte 0x3f
	.byte 0x01
	.byte 0xa7  ; "§"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xfc  ; "ü"
	.asciz "V*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x01
	.byte 0x00
	.asciz "SOUND MEMORY"
	.byte 0x00
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xeb  ; "ë"
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.byte 0x8a  ; ""
	.byte 0x00
	.byte 0x3f
	.byte 0x01
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "2W*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x01
	.byte 0x00
	.asciz "COMPOSER"
	.byte 0x00
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xe6  ; "æ"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xee  ; "î"
	.byte 0x02
	.byte 0xeb  ; "ë"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.asciz "~"
	.ascii "?"
	.byte 0x01
	.byte 0x8f  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "dW*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x01
	.byte 0x00
	.asciz "SEQUENCER"
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xe6  ; "æ"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xef  ; "ï"
	.byte 0x02
	.byte 0xed  ; "í"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.asciz "r"
	.ascii "?"
	.byte 0x01
	.byte 0x83  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0x96  ; ""
	.asciz "W*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x01
	.byte 0x00
	.asciz "PANEL MEMORY"
	.byte 0x00
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xe6  ; "æ"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0xee  ; "î"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xec  ; "ì"
	.byte 0x00
	.asciz "f"
	.ascii "?"
	.byte 0x01
	.asciz "w"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.byte 0xcc  ; "Ì"
	.asciz "W*"
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x01
	.byte 0x00
	.asciz "CURRENT PANEL"
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0xf1  ; "ñ"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	adc	(xix), ix
	.asciz "#"
	.byte 0x04
	.asciz "X*"
	.asciz "<"
	.zero 2
	.asciz "TECH LYRICS"
	.asciz "I"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xf2  ; "ò"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.zero 3
	.byte 0x7f
	.byte 0x00
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.byte 0xf3  ; "ó"
	.byte 0x02
	.byte 0xf4  ; "ô"
	.byte 0x02
	.byte 0xf1  ; "ñ"
	.byte 0x02, 0x08
	.zero 3
	.asciz "!"
	.ascii "?"
	.byte 0x01
	.asciz "8"
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.asciz "RX*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.zero 3
	.byte 0x12
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xf2  ; "ò"
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.asciz "\""
	.ascii "?"
	.byte 0x01
	.asciz "7"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x05
	.zero 3
	.byte 0xff
	.zero 3
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.byte 0xf5  ; "õ"
	.byte 0x02
	.byte 0xf6  ; "ö"
	.byte 0x02
	.byte 0xf2  ; "ò"
	.byte 0x02, 0x08
	.zero 3
	.asciz "8"
	.ascii "?"
	.byte 0x01
	.asciz "I"
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0xa0  ; " "
	.asciz "X*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.zero 3
	.byte 0x12
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xf4  ; "ô"
	.byte 0x02
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x03
	.byte 0x00
	.asciz "9"
	.ascii "?"
	.byte 0x01
	.asciz "G"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x12
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xf7  ; "÷"
	.byte 0x02
	.byte 0xf4  ; "ô"
	.byte 0x02, 0x08
	.zero 3
	.byte 0xe0  ; "à"
	.byte 0x00
	.asciz "'"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x12
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xf8  ; "ø"
	.byte 0x02
	.byte 0xf6  ; "ö"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "("
	.byte 0xe0  ; "à"
	.byte 0x00
	.asciz "O"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x12
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xf9  ; "ù"
	.byte 0x02
	.byte 0xf7  ; "÷"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "P"
	.byte 0xe0  ; "à"
	.byte 0x00
	.asciz "w"
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x12
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xfa  ; "ú"
	.byte 0x02
	.byte 0xf8  ; "ø"
	.byte 0x02, 0x08
	.byte 0x00
	.asciz "x"
	.byte 0xe0  ; "à"
	.byte 0x00
	.byte 0x9f  ; ""
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x12
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xfb  ; "û"
	.byte 0x02
	.byte 0xf9  ; "ù"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xa0  ; " "
	.byte 0x00
	.byte 0xe0  ; "à"
	.byte 0x00
	.byte 0xc7  ; "Ç"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x12
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xfc  ; "ü"
	.byte 0x02
	.byte 0xfa  ; "ú"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xc8  ; "È"
	.byte 0x00
	.byte 0xe0  ; "à"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x12
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xfd  ; "ý"
	.byte 0x02
	.byte 0xfb  ; "û"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x00
	.byte 0xe0  ; "à"
	.byte 0x00
	.byte 0x17, 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.byte 0x12
	.byte 0x00
	.byte 0x60
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.fill 2, 1, 0xff
	.byte 0xfe  ; "þ"
	.byte 0x02
	.byte 0xfc  ; "ü"
	.byte 0x02, 0x08
	.byte 0x00
	.byte 0x18, 0x01
	.byte 0xe0  ; "à"
	.byte 0x00
	.byte 0x3f
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.fill 2, 1, 0xff
	.byte 0x03
	.zero 3
	.byte 0xff
	.zero 3
	.asciz "6"
	.ascii "`"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.byte 0xff
	.byte 0x02, 0x03, 0x03
	.byte 0xfd  ; "ý"
	.byte 0x02, 0x08
	.zero 3
	.byte 0xd1  ; "Ñ"
	.byte 0x00
	.byte 0x3f
	.byte 0x01
	.byte 0xe0  ; "à"
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0xc0  ; "À"
	.byte 0x00
	.byte 0x0e
	.asciz "Z*"
	.zero 6
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.zero 3
	.byte 0x0b
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.byte 0xf0  ; "ð"
	.byte 0x02
	.fill 4, 1, 0xff
	.byte 0xfe  ; "þ"
	.byte 0x02, 0x08
	.zero 3
	.asciz "K"
	.ascii "?"
	.byte 0x01
	.byte 0xce  ; "Î"
	.byte 0x00
	.byte 0xff
	.byte 0x00
	.byte 0x05
	.byte 0x00
	.fill 2, 1, 0xff
	.byte 0x98, 0x9c  ; ""
	.asciz "#"
	.byte 0x07
	.zero 3
	.byte 0xfc  ; "ü"
	.byte 0x00
	.byte 0x0d
	.byte 0x00
	.byte 0x03
	.zero 3
	.byte 0xf9  ; "ù"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x05, 0x03
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.zero 6
	.byte 0xa0  ; " "
	.byte 0x01
	.byte 0x9a, 0x9c  ; ""
	.asciz "#"
	.asciz "hZ*"
	.asciz "'"
	.zero 2
	.asciz "LOAD LYRICS FROM FD"
	.asciz "I"
	.ascii "`"
	.byte 0x01, 0x04, 0x03
	.fill 2, 1, 0xff
	.byte 0x06, 0x03
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0xf0  ; "ð"
	.byte 0x02, 0x7f
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x04, 0x03
	.fill 2, 1, 0xff
	.byte 0x07, 0x03, 0x05, 0x03, 0x08
	.byte 0x00
	.byte 0x1c
	.byte 0x00
	.byte 0xe1  ; "á"
	.byte 0x00
	.asciz "7"
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xb6  ; "¶"
	.asciz "Z*"
	.byte 0x03
	.zero 5
	.asciz "Info"
	.byte 0x00
	.asciz "+"
	.ascii "`"
	.byte 0x01, 0x04, 0x03
	.fill 2, 1, 0xff
	.byte 0x08, 0x03, 0x06, 0x03, 0x08
	.byte 0x00
	.byte 0x06, 0x01
	.byte 0xe1  ; "á"
	.byte 0x00
	.byte 0x21
	.byte 0x01
	.byte 0xeb  ; "ë"
	.byte 0x00
	.byte 0xdc  ; "Ü"
	.asciz "Z*"
	.byte 0x03
	.zero 5
	.asciz "Load"
	.byte 0x00
	.byte 0x0c
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x04, 0x03
	.fill 4, 1, 0xff
	.byte 0x07, 0x03, 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.zero 3
	.byte 0x9e, 0x9c  ; ""
	.asciz "#"
	adc	(xwa), xix
	.asciz "#"
	.byte 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x0a, 0x03
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	adc	(xde), xix
	.asciz "#"
	.asciz ",[*"
	.zero 6
	.asciz "6"
	.ascii "`"
	.byte 0x01, 0x09, 0x03, 0x0b, 0x03
	.fill 4, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "<"
	.asciz "T"
	.byte 0x03, 0x01
	.byte 0x83  ; ""
	.byte 0x00
	.byte 0x09
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.asciz "V[*"
	.byte 0x01
	.zero 7
	.byte 0x01
	.zero 3
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x0a, 0x03
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.asciz "H"
	.asciz "b"
	.byte 0xf1  ; "ñ"
	.byte 0x00
	.asciz "y"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "1"
	.zero 8
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x06
	.byte 0x00
	.ascii "j"
	.byte 0x01
	.fill 2, 1, 0xff
	.byte 0x0d, 0x03
	.fill 4, 1, 0xff
	.byte 0x0a
	.zero 5
	.ascii "?"
	.byte 0x01
	.byte 0xef  ; "ï"
	.byte 0x00
	.byte 0xff
	.zero 5
	.byte 0xa0  ; " "
	.byte 0x01
	adc	(xiz), xix
	.asciz "#"
	.byte 0xac  ; "¬"
	.asciz "[*"
	.asciz "<"
	.zero 2
	.asciz "LYRICS OPTIONS"
	.byte 0x00
	.asciz "I"
	.ascii "`"
	.byte 0x01, 0x0c, 0x03
	.fill 2, 1, 0xff
	.byte 0x0e, 0x03
	.fill 2, 1, 0xff
	.byte 0x18
	.zero 5
	.byte 0x1f
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.byte 0x13
	.byte 0x00
	.byte 0x7f
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x0c, 0x03, 0x0f, 0x03, 0x10, 0x03, 0x0d, 0x03, 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "H"
	.byte 0xc5  ; "Å"
	.byte 0x00
	.asciz "a"
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 4
	.byte 0x10
	.asciz "\\*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0xaa, 0x9c  ; "ª"
	.asciz "#"
	.asciz "B"
	.ascii "*"
	.byte 0x01
	.byte 0xac, 0x9c  ; "¬"
	.asciz "#"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x0e, 0x03
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "H"
	.byte 0x8e  ; ""
	.byte 0x00
	.asciz "g"
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "@"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x0c, 0x03, 0x11, 0x03, 0x12, 0x03, 0x0e, 0x03, 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "r"
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 4
	.asciz "v\\*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x8a  ; ""
	.byte 0x00
	.byte 0x01
	.byte 0x00
	ldcfm	4, (xwa)
	.asciz "#"
	.asciz "C"
	.ascii "*"
	.byte 0x01
	ldcfm	4, (xde)
	.asciz "#"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x10, 0x03
	.fill 6, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.asciz "r"
	.byte 0x8e  ; ""
	.byte 0x00
	.byte 0x91  ; ""
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "A"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01, 0x1b
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x0c, 0x03
	.fill 2, 1, 0xff
	.byte 0x13, 0x03, 0x10, 0x03, 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0xc5  ; "Å"
	.byte 0x00
	.byte 0xb5  ; "µ"
	.byte 0x00
	.byte 0xf5  ; "õ"
	.byte 0x00
	.zero 4
	.byte 0xdc  ; "Ü"
	.asciz "\\*"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x04
	.byte 0x00
	.byte 0x8b  ; ""
	.byte 0x00
	.byte 0x01
	.byte 0x00
	ldcfm	4, (xiz)
	.asciz "#"
	.asciz "D"
	.ascii "*"
	.byte 0x01
	.byte 0xb8, 0x9c  ; "¸"
	.asciz "#"
	.zero 2
	.byte 0x0a
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x0c, 0x03
	.fill 4, 1, 0xff
	.byte 0x12, 0x03, 0x08
	.byte 0x00
	.byte 0x08
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x8e  ; ""
	.byte 0x00
	.byte 0xbb  ; "»"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.zero 2
	.asciz "B"
	.zero 4
	.byte 0xff
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.byte 0x01
	.byte 0x00
	.asciz "@"
	.ascii "*"
	.byte 0x01
	.asciz "5"
	.ascii "`"
	.byte 0x01
	.fill 8, 1, 0xff
	.byte 0x08
	.byte 0x00
	.byte 0x10
	.byte 0x00
	.asciz "p"
	.ascii "3"
	.byte 0x01
	.byte 0xdf  ; "ß"
	.byte 0x00
	.byte 0x07
	.byte 0x00
	.byte 0xc1  ; "Á"
	.byte 0x00
	.zero 2
	.byte 0xbc, 0x9c  ; "¼"
	.asciz "#"
	.byte 0xc0, 0x9c  ; "À"
	.asciz "#"

HDAE5000_GFX_DATA_1:	; 0x2A5D2C
	; Graphics data block 1
; LGD1: 0x2A5D2C (3160 bytes)

	.byte 0x12                             ; ccf
	orcf_a_16 ix		; orcf A,IX
	nop                                     ; nop
	ld	xiz, 0x8c0029dc
	orcf_a_16 ix		; orcf A,IX
	nop                                     ; nop
	.byte 0xc4, 0xdc, 0x29                 ; db
	nop                                     ; nop
.LGD1_5d3c:
	cps	xiz, 4
	pushw bc                                ; push BC
	nop                                     ; nop
	ldb	h, 0xdd
	pushw bc                                ; push BC
	nop                                     ; nop
	.byte 0x50                             ; db
	orcf_a_16 iy		; orcf A,IY
	nop                                     ; nop
	ld_s	(xwa-35), a
	nop                                     ; nop
	jp_cc_ri xde, 13		; jp P/PL,XDE
	pushw bc                                ; push BC
	nop                                     ; nop
	cps	xde, 5
	pushw bc                                ; push BC
	nop                                     ; nop
	.byte 0x14                             ; push A
.LGD1_5d55:
	orcf_a_16 iz		; orcf A,IZ
	nop                                     ; nop
	.byte 0x50                             ; db
	orcf_a_16 iz		; orcf A,IZ
	nop                                     ; nop
	jr gt, .LGD1_5d3c                      ; [6a de] jr GT,0x2a5d3c
	pushw bc                                ; push BC
	nop                                     ; nop
	xor	(xix), h
	pushw bc                                ; push BC
	nop                                     ; nop
	ld_s	(xiz-34), bc
	nop                                     ; nop
	.byte 0xd6                             ; db
	orcf_a_16 iz		; orcf A,IZ
	nop                                     ; nop
	nop                                     ; nop
	.byte 0xdf, 0x29                       ; orcf A,SP
	nop                                     ; nop
	pushw de                                ; push DE
	.byte 0xdf, 0x29                       ; orcf A,SP
	nop                                     ; nop
	jr le, .LGD1_5d55                      ; [62 df] jr LE,0x2a5d55
	pushw bc                                ; push BC
	nop                                     ; nop
	ld_s	(xwa-33), bc
	nop                                     ; nop
	ordm16_24	0x0029DF, ix
	.byte 0xdf, 0x29                       ; orcf A,SP
	nop                                     ; nop
	ldio	224, 41
	nop                                     ; nop
	ldb	d, 0xe0
	pushw bc                                ; push BC
	nop                                     ; nop
	popw wa                                 ; pop WA
	.byte 0xe0, 0x29, 0x00                 ; db
	jrl	ov, 0x29e0
	nop                                     ; nop
	ld_s	(xiz-32), a
	nop                                     ; nop
	ld_s	(xde-32), xbc
	nop                                     ; nop
	.byte 0xc6                             ; db
	.byte 0xe0, 0x29, 0x00                 ; db
	or	xwa, xiz
	pushw bc                                ; push BC
	nop                                     ; nop
	.byte 0x14                             ; push A
	.byte 0xe1, 0x29, 0x00, 0x2e           ; db
	.byte 0xe1, 0x29, 0x00, 0x5a           ; db
	.byte 0xe1, 0x29, 0x00, 0x74           ; db
	.byte 0xe1, 0x29, 0x00, 0x98           ; adc (0x0029),XWA
	.byte 0xe1, 0x29, 0x00, 0xd0           ; xor XWA,(0x0029)
	cpdm32	41, xde
	.byte 0xe1, 0x29, 0x00, 0x14           ; db
	or	xde, (0x500029)
	pushw bc                                ; push BC
	nop                                     ; nop
	or	b, (xix)
	pushw bc                                ; push BC
	nop                                     ; nop
	call_cc_ri xiz, 2		; call LE,XIZ
	pushw bc                                ; push BC
	nop                                     ; nop
	or	xde, xwa
	pushw bc                                ; push BC
	nop                                     ; nop
	.byte 0x1a, 0xe3, 0x29                 ; jp 0x29e3
	nop                                     ; nop
	popw ix                                 ; pop IX
	.byte 0xe3, 0x29, 0x00, 0xc4, 0x9c     ; adc (XDE2+0xc400),XIX
	ldb	c, 0x00
	jrl	ov, 0x29e3
	nop                                     ; nop
	ld_s	(xde-29), bc
	nop                                     ; nop
	call_cc_ri xix, 3		; call ULE,XIX
	pushw bc                                ; push BC
	nop                                     ; nop
	.byte 0xe0, 0xe3, 0x29                 ; db
	nop                                     ; nop
	.byte 0xfa                             ; swi 2
	.byte 0xe3, 0x29, 0x00, 0x3a, 0xe4     ; or XIX,(XDE2+0x3a00)
	pushw bc                                ; push BC
	nop                                     ; nop
	jrl	le, 0x29e4
	nop                                     ; nop
	or	ix, (xiz)
	pushw bc                                ; push BC
	nop                                     ; nop
	.byte 0xc0, 0xe4, 0x29                 ; db
	nop                                     ; nop
	or	xix, xwa
	pushw bc                                ; push BC
	nop                                     ; nop
	ldb	w, 0xe5
	pushw bc                                ; push BC
	nop                                     ; nop
	ld	xix, 0x5e0029e5
	.byte 0xe5, 0x29, 0x00                 ; db
	or	e, (xiz)
	pushw bc                                ; push BC
	nop                                     ; nop
	.byte 0xc4, 0xe5, 0x29                 ; db
	nop                                     ; nop
	.byte 0xfc                             ; swi 4
	.byte 0xe5, 0x29, 0x00                 ; db
	ldb	b, 0xe6
	pushw bc                                ; push BC
	nop                                     ; nop
	popw ix                                 ; pop IX
	.byte 0xe6                             ; db
	pushw bc                                ; push BC
	nop                                     ; nop
	jrl	ov, 0x29e6
	nop                                     ; nop
	ld_s	(xix-26), xbc
	nop                                     ; nop
	.byte 0xc6                             ; db
	.byte 0xe6                             ; db
	pushw bc                                ; push BC
	nop                                     ; nop
	or xiz, xiz                             ; or XIZ,XIZ
	pushw bc                                ; push BC
	nop                                     ; nop
	.byte 0x18                             ; push F
	.byte 0xe7, 0x29, 0x00                 ; db
	ld	xwa, 0x7c0029e7
	.byte 0xe7, 0x29, 0x00                 ; db
	call_cc_ri xix, 7		; call C,XIX
	pushw bc                                ; push BC
	nop                                     ; nop
	or l, h		; or L,H
	pushw bc                                ; push BC
	nop                                     ; nop
	or	xsp, xwa
	pushw bc                                ; push BC
	nop                                     ; nop
	.byte 0x02                             ; push SR
	.byte 0xe8, 0x29                       ; db
	nop                                     ; nop
	ldw	ix, 0x29e8
	nop                                     ; nop
	popw iz                                 ; pop IZ
	.byte 0xe8, 0x29                       ; db
.LGD1_5e5b:
	nop                                     ; nop
	or	(xde), w
	pushw bc                                ; push BC
	nop                                     ; nop
	call	(xde)
	pushw bc                                ; push BC
	nop                                     ; nop
	.byte 0xe2, 0xe8, 0x29, 0x00, 0x1c     ; db
	.byte 0xe9, 0x29                       ; db
	nop                                     ; nop
	ldw	iz, 0x29e9
	nop                                     ; nop
	jr le, .LGD1_5e5b                      ; [62 e9] jr LE,0x2a5e5b
	pushw bc                                ; push BC
	nop                                     ; nop
	jrl	nov, 0x29e9
	nop                                     ; nop
	ld_s	(xwa-23), xbc
	nop                                     ; nop
	.byte 0xcc, 0xe9, 0x29                 ; rrc 0x29,D
	nop                                     ; nop
	.byte 0xe6                             ; db
	.byte 0xe9, 0x29                       ; db
	nop                                     ; nop
	.byte 0x12                             ; ccf
	.byte 0xea, 0x29                       ; db
	nop                                     ; nop
	ldw	iz, 0x29ea
	nop                                     ; nop
	pop xde                                 ; pop XDE
	.byte 0xea, 0x29                       ; db
	nop                                     ; nop
	ld_s	(xwa-22), bc
	nop                                     ; nop
	call_cc_ri xde, 10		; call GT,XDE
	pushw bc                                ; push BC
	nop                                     ; nop
	.byte 0xde, 0xea, 0x29                 ; rl 0x29,IZ
	nop                                     ; nop
	.byte 0xf8                             ; swi 0
	.byte 0xea, 0x29                       ; db
	nop                                     ; nop
	ldb	d, 0xeb
	pushw bc                                ; push BC
	nop                                     ; nop
	popw wa                                 ; pop WA
	.byte 0xeb, 0x29                       ; db
	nop                                     ; nop
	jr	nov, 0xeb
	pushw bc                                ; push BC
	nop                                     ; nop
	ld_s	(xde-21), bc
	nop                                     ; nop
	.byte 0xd0, 0xeb, 0x29                 ; db
	nop                                     ; nop
	.byte 0xea, 0xeb, 0x29                 ; rr 0x29,XDE
	nop                                     ; nop
	.byte 0x04                             ; max
	.byte 0xec, 0x29                       ; db
	nop                                     ; nop
	.byte 0x1a, 0xec, 0x29                 ; jp 0x29ec
	nop                                     ; nop
	.byte 0x54                             ; db
	.byte 0xec, 0x29                       ; db
	nop                                     ; nop
	ld_s	(xiz-20), a
	nop                                     ; nop
	sla	w, 0x29
	nop                                     ; nop
	.byte 0xe2, 0xec, 0x29, 0x00, 0x1e     ; db
	.byte 0xed, 0x29                       ; db
	nop                                     ; nop
	popw wa                                 ; pop WA
	.byte 0xed, 0x29                       ; db
	nop                                     ; nop
	jrl	f, 0x29ed
	nop                                     ; nop
	ld_s	(xde-19), bc
	nop                                     ; nop
	.byte 0xc0, 0xed, 0x29                 ; db
	nop                                     ; nop
	sra	de, 0x29
	nop                                     ; nop
	.byte 0xfe                             ; swi 6
	.byte 0xed, 0x29                       ; db
	nop                                     ; nop
	ld	xde, 0x5c0029ee
	.byte 0xee, 0x29                       ; db
	nop                                     ; nop
	or	(xiz), h
	pushw bc                                ; push BC
	nop                                     ; nop
	ordm8_24	0x0029EE, d
	.byte 0xee, 0x29                       ; db
	nop                                     ; nop
	ldw	iz, 0x29ef
	nop                                     ; nop
	or8_mem_ri xwa, l		; or (XWA),L
	pushw bc                                ; push BC
	nop                                     ; nop
	orcfa_rid8 xix, 0xef		; orcf A,(XIX+0xef)
	nop                                     ; nop
	.byte 0xe6                             ; db
	.byte 0xef, 0x29                       ; db
	nop                                     ; nop
	ldw	wa, 0x29f0
	nop                                     ; nop
	jrl	z, 0x29f0
	nop                                     ; nop
	ld_s	(xde-16), bc
	nop                                     ; nop
	cpdm16_24	0x0029F0, ix
	.byte 0xf0, 0x29, 0x00, 0x40           ; ld (0x29),0x40
	.byte 0xf1, 0x29, 0x00, 0x5a           ; db
	.byte 0xf1, 0x29, 0x00, 0xec           ; call PO/NOV,0x0029
	.byte 0x9c, 0x23, 0x00                 ; db
	cp	a, (xde)
	pushw bc                                ; push BC
	nop                                     ; nop
	ld_s	(xix-15), bc
	nop                                     ; nop
	.byte 0xd4, 0xf1, 0x29                 ; db
	nop                                     ; nop
.LGD1_5f3c:
	cp	xbc, xiz
	pushw bc                                ; push BC
	nop                                     ; nop
	.byte 0x18                             ; push F
	.byte 0xf2, 0x29, 0x00, 0x52, 0xf2     ; db
	pushw bc                                ; push BC
	nop                                     ; nop
	jr	nov, 0xf2
	pushw bc                                ; push BC
	nop                                     ; nop
	cp	de, (xiz)
	pushw bc                                ; push BC
	nop                                     ; nop
	.byte 0xd2, 0xf2, 0x29, 0x00, 0x0e     ; db
	.byte 0xf3, 0x29, 0x00, 0x4a, 0xf3     ; db
	pushw bc                                ; push BC
	nop                                     ; nop
	jrl	ov, 0x29f3
	nop                                     ; nop
	ld_s	(xiz-13), bc
	nop                                     ; nop
	cp	c, w
	pushw bc                                ; push BC
	nop                                     ; nop
	.byte 0xf2, 0xf3, 0x29, 0x00, 0x2c     ; stcf A,(0x0029f3)
	.byte 0xf4, 0x29, 0x00, 0x46           ; ld (-XDE2),0x46
	.byte 0xf4, 0x29, 0x00, 0x62           ; ld (-XDE2),0x62
	.byte 0xf4, 0x29, 0x00, 0x7e           ; ld (-XDE2),0x7e
	.byte 0xf4, 0x29, 0x00, 0xa2           ; ld (-XDE2),0xa2
	.byte 0xf4, 0x29, 0x00, 0xbc           ; ld (-XDE2),0xbc
	.byte 0xf4, 0x29, 0x00, 0xe0           ; ld (-XDE2),0xe0
	.byte 0xf4, 0x29, 0x00, 0x0a           ; ld (-XDE2),0x0a
	stib_dpi 0x29, 0x30		; ld (XDE2+),0x30
	stib_dpi 0x29, 0x6c		; ld (XDE2+),0x6c
	stib_dpi 0x29, 0x94		; ld (XDE2+),0x94
	stib_dpi 0x29, 0xba		; ld (XDE2+),0xba
	stib_dpi 0x29, 0xe6		; ld (XDE2+),0xe6
	stib_dpi 0x29, 0x00		; ld (XDE2+),0x00
	.byte 0xf6                             ; db
	pushw bc                                ; push BC
	nop                                     ; nop
	pushw de                                ; push DE
	.byte 0xf6                             ; db
	pushw bc                                ; push BC
	nop                                     ; nop
	.byte 0x52                             ; db
	.byte 0xf6                             ; db
	pushw bc                                ; push BC
	nop                                     ; nop
	jrl	gt, 0x29f6
	nop                                     ; nop
	cp	xiz, (xde)
	pushw bc                                ; push BC
	nop                                     ; nop
	cp	h, b
	pushw bc                                ; push BC
	nop                                     ; nop
	.byte 0xf2, 0xf6, 0x29, 0x00, 0x1a     ; db
	.byte 0xf7                             ; ldx
	pushw bc                                ; push BC
	nop                                     ; nop
	ld	xde, 0x6a0029f7
	.byte 0xf7                             ; ldx
	pushw bc                                ; push BC
	nop                                     ; nop
	.byte 0x92, 0xf7                       ; cp SP,(XDE)
	pushw bc                                ; push BC
	nop                                     ; nop
	orcfa_rid8 xde, 0xf7		; orcf A,(XDE+0xf7)
	nop                                     ; nop
	.byte 0xf6                             ; db
	.byte 0xf7                             ; ldx
.LGD1_5fd2:
	pushw bc                                ; push BC
	nop                                     ; nop
	ldw	de, 0x29f8
	nop                                     ; nop
	jr nz, .LGD1_5fd2                      ; [6e f8] jr NZ,0x2a5fd2
	pushw bc                                ; push BC
	nop                                     ; nop
	ld_s	(xde-8), xbc
	nop                                     ; nop
	.byte 0xc4, 0xf8, 0x29                 ; db
	nop                                     ; nop
	.byte 0xee, 0xf8                       ; rlc A,XIZ
	pushw bc                                ; push BC
	nop                                     ; nop
	.byte 0x18                             ; push F
	.byte 0xf9                             ; swi 1
	pushw bc                                ; push BC
	nop                                     ; nop
	push xix
	.byte 0xf9                             ; swi 1
	pushw bc                                ; push BC
	nop                                     ; nop
	jrl	t, 0x29f9
	nop                                     ; nop
	.byte 0xca, 0xf9                       ; rrc A,B
	pushw bc                                ; push BC
	nop                                     ; nop
	.byte 0x1c, 0xfa, 0x29                 ; call 0x29fa
	nop                                     ; nop
	ldw	iz, 0x29fa
	nop                                     ; nop
	ld_s	(xwa-6), a
	nop                                     ; nop
	.byte 0xda, 0xfa                       ; rl A,DE
	pushw bc                                ; push BC
	nop                                     ; nop
	pushw ix                                ; push IX
	.byte 0xfb                             ; swi 3
	pushw bc                                ; push BC
	nop                                     ; nop
	jrl	nz, 0x29fb
	nop                                     ; nop
	.byte 0xd0, 0xfb, 0x29                 ; db
	nop                                     ; nop
	ldb	b, 0xfc
	pushw bc                                ; push BC
	nop                                     ; nop
	push xix
	.byte 0xfc                             ; swi 4
	pushw bc                                ; push BC
	nop                                     ; nop
	.byte 0x56                             ; db
	.byte 0xfc                             ; swi 4
	pushw bc                                ; push BC
	nop                                     ; nop
	jrl	f, 0x29fc
	nop                                     ; nop
	ld_s	(xwa-4), bc
	nop                                     ; nop
	.byte 0xc0, 0xfc, 0x29                 ; db
	nop                                     ; nop
	slaa	xwa
	pushw bc                                ; push BC
	nop                                     ; nop
	.byte 0x10                             ; rcf
	.byte 0xfd                             ; swi 5
	pushw bc                                ; push BC
	nop                                     ; nop
	push xwa
	.byte 0xfd                             ; swi 5
	pushw bc                                ; push BC
.LGD1_6037:
	nop                                     ; nop
	jr f, .LGD1_6037                       ; [60 fd] jr F,0x2a6037
	pushw bc                                ; push BC
	nop                                     ; nop
	ld_s	(xwa-3), a
	nop                                     ; nop
	ret_cc_ri xwa, 13		; ret P/PL

	pushw bc                                ; push BC
	nop                                     ; nop
	.byte 0xd4, 0xfd, 0x29                 ; db
	nop                                     ; nop
	.byte 0xfa                             ; swi 2
	.byte 0xfd                             ; swi 5
	pushw bc                                ; push BC
	nop                                     ; nop
	calr	0x29fe
	nop                                     ; nop
	ld	xix, 0x6a0029fe
	.byte 0xfe                             ; swi 6
	pushw bc                                ; push BC
	nop                                     ; nop
	ld_s	(xiz-2), a
	nop                                     ; nop
	ret_cc_ri xiz, 14		; ret NZ

	pushw bc                                ; push BC
	nop                                     ; nop
	slla	ix
	pushw bc                                ; push BC
	nop                                     ; nop
	.byte 0xf6                             ; db
	.byte 0xfe                             ; swi 6
	pushw bc                                ; push BC
	nop                                     ; nop
	calr	0x29ff
	nop                                     ; nop
	ld	xix, 0x5e0029ff
	.byte 0xff                             ; swi 7
	pushw bc                                ; push BC
	nop                                     ; nop
	ld_s	(xde-1), a
	nop                                     ; nop
	.byte 0xc4, 0xff, 0x29                 ; db
	nop                                     ; nop
	srla	iz
	pushw bc                                ; push BC
	nop                                     ; nop
	ei 0                                    ; ei 0x00
	pushw de                                ; push DE
	nop                                     ; nop
	pushw iz                                ; push IZ
	nop                                     ; nop
	pushw de                                ; push DE
	nop                                     ; nop
	pop xwa                                 ; pop XWA
	nop                                     ; nop
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x94, 0x00                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xae, 0x00, 0x2a                 ; db
	nop                                     ; nop
	ldb	b, 0x9d
	ldb	c, 0x00
	.byte 0xc8, 0x00                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	popw de                                 ; pop DE
	.byte 0x9d, 0x23, 0x00                 ; db
	.byte 0xee, 0x00                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x16                             ; ex F,F'
	.byte 0x01                             ; normal
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x52                             ; db
	.byte 0x01                             ; normal
	pushw de                                ; push DE
	nop                                     ; nop
	jrl	le, 0x239d
	nop                                     ; nop
	.byte 0x82, 0x01                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xde+1), xde
	nop                                     ; nop
	cp	(0x002a01), xix
	.byte 0x01                             ; normal
	pushw de                                ; push DE
	nop                                     ; nop
	ldb	d, 0x02
	pushw de                                ; push DE
	nop                                     ; nop
	popw de                                 ; pop DE
	.byte 0x02                             ; push SR
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x86, 0x02                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	xorcfa_rid8 xwa, 0x02		; xorcf A,(XWA+0x02)
	nop                                     ; nop
	.byte 0xea, 0x02                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x14                             ; push A
	.byte 0x03                             ; pop SR
	pushw de                                ; push DE
	nop                                     ; nop
	ld	xiz, 0x78002a03
	.byte 0x03                             ; pop SR
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xix+3), xde
	nop                                     ; nop
	.byte 0xd4, 0x03, 0x2a                 ; db
	nop                                     ; nop
	.byte 0xfa                             ; swi 2
	.byte 0x03                             ; pop SR
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x14                             ; push A
	.byte 0x04                             ; max
	pushw de                                ; push DE
	nop                                     ; nop
	popw iz                                 ; pop IZ
	.byte 0x04                             ; max
	pushw de                                ; push DE
	nop                                     ; nop
	jr	t, 0x04
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xde+4), de
	nop                                     ; nop
	push	d
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xf6                             ; db
	.byte 0x04                             ; max
	pushw de                                ; push DE
	nop                                     ; nop
	pushw wa                                ; push WA
	halt                                    ; halt
	pushw de                                ; push DE
	nop                                     ; nop
	pop xde                                 ; pop XDE
	halt                                    ; halt
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xiz+5), b
	nop                                     ; nop
	ld	hl, (xde-99)
	nop                                     ; nop
	.byte 0xb6, 0x05                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	pop	ix
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x18                             ; push F
	ei 0x2a		; ei 0x2a
	nop                                     ; nop
	ldw	de, 0x2a06
	nop                                     ; nop
	pop xiz                                 ; pop XIZ
	ei 0x2a		; ei 0x2a
	nop                                     ; nop
	jrl	t, 0x2a06
	nop                                     ; nop
	.byte 0xc2, 0x9d, 0x23, 0x00, 0x9c     ; adc (0x00239d),D
	ei 0x2a		; ei 0x2a
	nop                                     ; nop
	cpdm8_24	0x002A06, h
	ei 0x2a		; ei 0x2a
	nop                                     ; nop
	push xde
	.byte 0x07                             ; reti
	pushw de                                ; push DE
	nop                                     ; nop
	jrl	z, 0x2a07
	nop                                     ; nop
	ld_s	(xiz+7), de
	nop                                     ; nop
	neg	w
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xf0, 0x07, 0x2a                 ; xorcf A,(0x07)
	nop                                     ; nop
	ldwio	8, 42
	.byte 0xea, 0x9d                       ; ld XDE,XIY
	ldb	c, 0x00
	push xde
	ldio	42, 0
	pop xiz                                 ; pop XIZ
	ldio	42, 0
	.byte 0x12                             ; ccf
	.byte 0x9e, 0x23, 0x00                 ; db
	.byte 0x82, 0x08                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xa6, 0x08                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	mul	d, 0x2a
	nop                                     ; nop
	.byte 0xf0, 0x08, 0x2a                 ; xorcf A,(0x08)
	nop                                     ; nop
	ldb	w, 0x09
	pushw de                                ; push DE
	nop                                     ; nop
	push xde
	.byte 0x09, 0x2a                       ; push 0x2a
	nop                                     ; nop
	ld_s	(xix+9), b
	nop                                     ; nop
	.byte 0xb4, 0x09                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	muls	wa, 0x002a
	nop                                     ; nop
	ldwio	42, 10240
	ldwio	42, 20480
	ldwio	42, 30720
	ldwio	42, 40960
	ldwio	42, 51200
	ldwio	42, 61440
	ldwio	42, 5632
	pushw 0x002a
	push xde
	pushw 0x002a
	jr	f, 0x0b
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x86, 0x0b                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xde+11), xde
	nop                                     ; nop
	cpdm16_24	0x002A0B, wa
	pushw 0x002a
	popw de                                 ; pop DE
	.byte 0x0c                             ; incf
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xix+12), de
	nop                                     ; nop
	.byte 0xee, 0x0c, 0x2a, 0x00           ; link XIZ,0x002a
	ld	xwa, 0x92002a0d
	.byte 0x0d                             ; decf
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xe4, 0x0d, 0x2a                 ; db
	nop                                     ; nop
	.byte 0xfe                             ; swi 6
	.byte 0x0d                             ; decf
	pushw de                                ; push DE
	nop                                     ; nop
	push xde
	ret

	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xix+14), b
	nop                                     ; nop
	push xde
	.byte 0x9e, 0x23, 0x00                 ; db
	.byte 0xa6, 0x0e                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xcc, 0x0e                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	calr	0x2a0f
	nop                                     ; nop
	push xwa
	retd 0x002a		; retd 0x002a

	.byte 0x52                             ; db
	retd 0x002a		; retd 0x002a

	jr	nov, 0x0f
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xa4, 0x0f                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	xorcfa_rid8 xiz, 0x0f		; xorcf A,(XIZ+0x0f)
	nop                                     ; nop
	bs1b16 wa		; bs1b A,WA
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x04                             ; max
.LGD1_620d:
	.byte 0x10                             ; rcf
	pushw de                                ; push DE
	nop                                     ; nop
	ldw	wa, 0x2a10
	nop                                     ; nop
	.byte 0x54                             ; db
	.byte 0x10                             ; rcf
	pushw de                                ; push DE
	nop                                     ; nop
	ldiw_ri xwa		; ldiw
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xde+16), xde
	nop                                     ; nop
	incdi16_24	2, 0x002A10
	.byte 0x9e, 0x23, 0x00                 ; db
	.byte 0xf8                             ; swi 0
	.byte 0x10                             ; rcf
	pushw de                                ; push DE
	nop                                     ; nop
	calr	0x2a11
	nop                                     ; nop
	popw wa                                 ; pop WA
	.byte 0x11                             ; scf
	pushw de                                ; push DE
	nop                                     ; nop
	jrl	f, 0x2a11
	nop                                     ; nop
	ld_s	(xwa+17), de
	nop                                     ; nop
	.byte 0xd4, 0x11, 0x2a                 ; db
	nop                                     ; nop
	.byte 0x10                             ; rcf
	.byte 0x12                             ; ccf
	pushw de                                ; push DE
	nop                                     ; nop
	popw ix                                 ; pop IX
	.byte 0x12                             ; ccf
	pushw de                                ; push DE
	nop                                     ; nop
	jrl	z, 0x2a12
	nop                                     ; nop
	.byte 0xa0, 0x12                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	extz	ix
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xf6                             ; db
	.byte 0x12                             ; ccf
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x10                             ; rcf
	.byte 0x13                             ; zcf
	pushw de                                ; push DE
	nop                                     ; nop
	pushw de                                ; push DE
	.byte 0x13                             ; zcf
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x54                             ; db
	.byte 0x13                             ; zcf
	pushw de                                ; push DE
	nop                                     ; nop
	jrl	gt, 0x2a13
	nop                                     ; nop
	.byte 0xb6, 0x13                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xd0, 0x13, 0x2a                 ; db
	nop                                     ; nop
	.byte 0xf8                             ; swi 0
	.byte 0x13                             ; zcf
	pushw de                                ; push DE
	nop                                     ; nop
	ldw	ix, 0x2a14
	nop                                     ; nop
	jr z, .LGD1_628e                       ; [66 14] jr Z,0x2a628e
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xwa+20), de
	nop                                     ; nop
	cpda8_24	d, 0x002A14
	.byte 0x14                             ; push A
	pushw de                                ; push DE
	nop                                     ; nop
	ldb	h, 0x15
	pushw de                                ; push DE
	nop                                     ; nop
	pop xde                                 ; pop XDE
	.byte 0x15                             ; pop A
.LGD1_628e:
	pushw de                                ; push DE
	nop                                     ; nop
	jrl	ov, 0x2a15
	nop                                     ; nop
	.byte 0xb2, 0x15                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xcc, 0x15                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	ldio	22, 42
	nop                                     ; nop
	ld	xix, 0x6e002a16
	.byte 0x16                             ; ex F,F'
	pushw de                                ; push DE
	nop                                     ; nop
	cpdw_ri xiz		; cpdw
	pushw de                                ; push DE
	nop                                     ; nop
	xorcfa_rid8 xiz, 0x16		; xorcf A,(XIZ+0x16)
	nop                                     ; nop
	.byte 0xfa                             ; swi 2
	.byte 0x16                             ; ex F,F'
	pushw de                                ; push DE
	nop                                     ; nop
	ldb	b, 0x17
	pushw de                                ; push DE
	nop                                     ; nop
	popw de                                 ; pop DE
	.byte 0x17, 0x2a                       ; ldf 0x2a
	nop                                     ; nop
	cpdr_ri xwa		; cpdr
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xde+23), de
	nop                                     ; nop
	.byte 0xc4, 0x17, 0x2a                 ; db
	nop                                     ; nop
	nop                                     ; nop
	.byte 0x18                             ; push F
	pushw de                                ; push DE
	nop                                     ; nop
	pushw de                                ; push DE
	.byte 0x18                             ; push F
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x54                             ; db
	.byte 0x18                             ; push F
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x90, 0x18                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xde+24), xde
	nop                                     ; nop
	.byte 0xc4, 0x18, 0x2a                 ; db
	nop                                     ; nop
	.byte 0xec, 0x18                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x14                             ; push A
	.byte 0x19                             ; pop F
	pushw de                                ; push DE
	nop                                     ; nop
	push xix
	.byte 0x19                             ; pop F
	pushw de                                ; push DE
	nop                                     ; nop
	jr le, .LGD1_6307                      ; [62 19] jr LE,0x2a6307
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xde+25), b
	nop                                     ; nop
	xorcfa_rid8 xix, 0x19		; xorcf A,(XIX+0x19)
	nop                                     ; nop
	.byte 0xee, 0x19                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	calr	0x2a1a
	nop                                     ; nop
	.byte 0x50                             ; db
	.byte 0x1a, 0x2a, 0x00                 ; jp 0x002a
	.byte 0x82, 0x1a                       ; db
	pushw de                                ; push DE
.LGD1_6307:
	nop                                     ; nop
	xorcfa_rid8 xiz, 0x1a		; xorcf A,(XIZ+0x1a)
	nop                                     ; nop
	.byte 0xfa                             ; swi 2
	.byte 0x1a, 0x2a, 0x00                 ; jp 0x002a
	.byte 0x14                             ; push A
	jp 0x2e002a                             ; jp 0x2e002a
	jp 0x48002a                             ; jp 0x48002a
	jp 0x86002a                             ; jp 0x86002a
	jp 0xa0002a                             ; jp 0xa0002a
	jp 0xba002a                             ; jp 0xba002a
	jp 0xe6002a                             ; jp 0xe6002a
	jp 0x12002a                             ; jp 0x12002a
	.byte 0x1c, 0x2a, 0x00                 ; call 0x002a
	ldw	iz, 0x2a1c
	nop                                     ; nop
	pop xde                                 ; pop XDE
	.byte 0x1c, 0x2a, 0x00                 ; call 0x002a
	.byte 0x90, 0x1c                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xde+28), xde
	nop                                     ; nop
	cpdm16_24	0x002A1C, de
	.byte 0x1c, 0x2a, 0x00                 ; call 0x002a
	ldb	b, 0x1d
	pushw de                                ; push DE
	nop                                     ; nop
	popw de                                 ; pop DE
	call 0x72002a
	call 0x9a002a
	call 0xc2002a
	call 0xea002a
	call 0x0e002a
	calr	0x002a
	ldw	ix, 0x2a1e
	nop                                     ; nop
	pop xwa                                 ; pop XWA
	calr	0x002a
	jrl	nz, 0x2a1e
	nop                                     ; nop
	.byte 0xa4, 0x1e                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xc8, 0x1e                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xf0, 0x1e, 0x2a                 ; xorcf A,(0x1e)
	nop                                     ; nop
	.byte 0x16                             ; ex F,F'
	.byte 0x1f                             ; db
	pushw de                                ; push DE
	nop                                     ; nop
	jr	t, 0x1f
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xa4, 0x1f                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xf6                             ; db
	.byte 0x1f                             ; db
	pushw de                                ; push DE
	nop                                     ; nop
	popw wa                                 ; pop WA
	ldb	w, 0x2a
	nop                                     ; nop
	ld_s	(xde+32), de
	nop                                     ; nop
	.byte 0xec, 0x20                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	push xiz
	ldb	a, 0x2a
	nop                                     ; nop
	ld	bc, (xwa)
	pushw de                                ; push DE
	nop                                     ; nop
	cp	(0x002a21), xix
	ldb	a, 0x2a
	nop                                     ; nop
	.byte 0x16                             ; ex F,F'
	ldb	b, 0x2a
	nop                                     ; nop
	ldw	wa, 0x2a22
	nop                                     ; nop
	popw de                                 ; pop DE
	ldb	b, 0x2a
	nop                                     ; nop
	jr	ov, 0x22
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xix+34), b
	nop                                     ; nop
	lda_ri xde, xde		; lda DE,XDE
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xda, 0x22, 0x2a                 ; xorcf 0x2a,DE
	nop                                     ; nop
	.byte 0x02                             ; push SR
	ldb	c, 0x2a
	nop                                     ; nop
	pushw de                                ; push DE
	ldb	c, 0x2a
	nop                                     ; nop
	.byte 0x52                             ; db
	ldb	c, 0x2a
	nop                                     ; nop
	jrl	gt, 0x2a23
	nop                                     ; nop
	ld xhl, (xde)                           ; ld XHL,(XDE)
	pushw de                                ; push DE
	nop                                     ; nop
.LGD1_63d8:
	.byte 0xf4, 0x23, 0x2a                 ; xorcf A,(-r23L)
	nop                                     ; nop
	.byte 0x1c, 0x24, 0x2a                 ; call 0x2a24
	nop                                     ; nop
	ld	xde, 0x5c002a24
	ldb	d, 0x2a
	nop                                     ; nop
	ld	d, (xwa)
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xwa+36), xde
	nop                                     ; nop
	.byte 0xcc, 0x24, 0x2a                 ; stcf 0x2a,D
	nop                                     ; nop
	.byte 0xf4, 0x24, 0x2a                 ; xorcf A,(-XBC2)
	nop                                     ; nop
	.byte 0x18                             ; push F
	ldb	e, 0x2a
	nop                                     ; nop
	ld	xwa, 0x64002a25
	ldb	e, 0x2a
	nop                                     ; nop
	ld_s	(xix+37), b
	nop                                     ; nop
	lda_ri xix, xiy		; lda IY,XIX
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xdc, 0x25                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x04                             ; max
	ldb	h, 0x2a
	nop                                     ; nop
	pushw iz                                ; push IZ
	ldb	h, 0x2a
	nop                                     ; nop
	ld	c, (xde-98)
	nop                                     ; nop
	ldcfm	6, (xiz)
	ldb	c, 0x00
	.byte 0xe2, 0x9e, 0x23, 0x00, 0x6e     ; db
	ldb	h, 0x2a
	nop                                     ; nop
	ld	iz, (xiz)
	pushw de                                ; push DE
	nop                                     ; nop
	xorcfa_rid8 xiz, 0x26		; xorcf A,(XIZ+0x26)
	nop                                     ; nop
	.byte 0xe6                             ; db
	ldb	h, 0x2a
	nop                                     ; nop
	ldwio	39, 42
	ld	xix, 0x5e002a27
	ldb	l, 0x2a
	nop                                     ; nop
	ld8_src_ri xde, l		; ld L,(XDE)
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xwa+39), xde
	nop                                     ; nop
	.byte 0xcc, 0x27                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xf2, 0x27, 0x2a, 0x00, 0x18     ; db
	pushw wa                                ; push WA
	pushw de                                ; push DE
	nop                                     ; nop
	push xix
	pushw wa                                ; push WA
	pushw de                                ; push DE
	nop                                     ; nop
	jr	ov, 0x28
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xde+40), b
	nop                                     ; nop
	ld_s	(xix), xwa
	pushw de                                ; push DE
	nop                                     ; nop
	xorcfa_rid8 xiz, 0x28		; xorcf A,(XIZ+0x28)
	nop                                     ; nop
	andcf_a_16 wa		; andcf A,WA
	pushw de                                ; push DE
	nop                                     ; nop
	ldb	h, 0x29
	pushw de                                ; push DE
	nop                                     ; nop
	jrl	ov, 0x2a29
	nop                                     ; nop
	.byte 0xc2, 0x29, 0x2a, 0x00, 0x10     ; db
	pushw de                                ; push DE
	pushw de                                ; push DE
	nop                                     ; nop
	pop xiz                                 ; pop XIZ
	pushw de                                ; push DE
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xix+42), xde
	nop                                     ; nop
	.byte 0xfa                             ; swi 2
	pushw de                                ; push DE
	pushw de                                ; push DE
	nop                                     ; nop
	popw wa                                 ; pop WA
	pushw hl                                ; push HL
	pushw de                                ; push DE
	nop                                     ; nop
	jrl	f, 0x2a2b
	nop                                     ; nop
	ld_s	(xwa+43), de
	nop                                     ; nop
	.byte 0xc0, 0x2b, 0x2a                 ; db
	nop                                     ; nop
	.byte 0xe8, 0x2b                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x10                             ; rcf
	pushw ix                                ; push IX
	pushw de                                ; push DE
	nop                                     ; nop
	push xwa
	pushw ix                                ; push IX
	pushw de                                ; push DE
	nop                                     ; nop
	jr f, .LGD1_64d2                       ; [60 2c] jr F,0x2a64d2
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xwa+44), b
	nop                                     ; nop
	ld_s	(xde), xix
	pushw de                                ; push DE
	nop                                     ; nop
	stcf_a_8 b		; stcf A,B
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xee, 0x2c                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x16                             ; ex F,F'
	pushw iy                                ; push IY
	pushw de                                ; push DE
	nop                                     ; nop
	push xiz
	pushw iy                                ; push IY
	pushw de                                ; push DE
	nop                                     ; nop
	jr z, .LGD1_64ef                       ; [66 2d] jr Z,0x2a64ef
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xiz+45), b
	nop                                     ; nop
	.byte 0xca, 0x2d                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xf2, 0x2d, 0x2a, 0x00, 0x18     ; db
	pushw iz                                ; push IZ
.LGD1_64d2:
	pushw de                                ; push DE
	nop                                     ; nop
	jr	z, 0x2e
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xwa), h
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xde+46), de
	nop                                     ; nop
	xorcfa_rid8 xix, 0x2e		; xorcf A,(XIX+0x2e)
	nop                                     ; nop
	.byte 0xd6                             ; db
	pushw iz                                ; push IZ
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xf8                             ; swi 0
	pushw iz                                ; push IZ
	pushw de                                ; push DE
	nop                                     ; nop
	ldb	d, 0x2f
	pushw de                                ; push DE
.LGD1_64ef:
	nop                                     ; nop
	.byte 0x54                             ; db
	.byte 0x2f                             ; push SP
	pushw de                                ; push DE
	nop                                     ; nop
	jrl	nz, 0x2a2f
	nop                                     ; nop
	ld_s	(xiz+47), xde
	nop                                     ; nop
	.byte 0xd8, 0x2f, 0x2a                 ; ldc WA,unknown
	nop                                     ; nop
	.byte 0xf2, 0x2f, 0x2a, 0x00, 0x1c     ; db
	ldw	wa, 0x002a
	ld	xiz, 0x70002a30
	ldw	wa, 0x002a
	ex16_ri xix, wa		; ex (XIX),WA
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xd6                             ; db
	ldw	wa, 0x002a
	ei 0x31		; ei 0x31
	pushw de                                ; push DE
	nop                                     ; nop
	ldw	de, 0x2a31
	nop                                     ; nop
	jr	le, 0x31
	pushw de                                ; push DE
	nop                                     ; nop
	jrl	nov, 0x2a31
	nop                                     ; nop
	ld_s	(xix+49), xde
	nop                                     ; nop
	.byte 0xd6                             ; db
	ldw	bc, 0x002a
	nop                                     ; nop
	ldw	de, 0x002a
	pushw de                                ; push DE
	ldw	de, 0x002a
	.byte 0x54                             ; db
	ldw	de, 0x002a
	jrl	nz, 0x2a32
	nop                                     ; nop
	ld_s	(xde+50), xde
	nop                                     ; nop
	.byte 0xc4, 0x32, 0x2a                 ; db
	nop                                     ; nop
	.byte 0xf4, 0x32, 0x2a                 ; xorcf A,(-XWA3)
	nop                                     ; nop
	calr	0x2a33
	nop                                     ; nop
	popw iz                                 ; pop IZ
	ldw	hl, 0x002a
	jrl	t, 0x2a33
	nop                                     ; nop
	.byte 0xa2, 0x33                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xcc, 0x33, 0x2a                 ; bit 0x2a,D
	nop                                     ; nop
	.byte 0xf6                             ; db
	ldw	hl, 0x002a
	ldb	b, 0x34
	pushw de                                ; push DE
	nop                                     ; nop
	push xix
	ldw	ix, 0x002a
	jr	nov, 0x34
	pushw de                                ; push DE
	nop                                     ; nop
	ex16_ri xiz, ix		; ex (XIZ),IX
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xc6                             ; db
	ldw	ix, 0x002a
	.byte 0xf0, 0x34, 0x2a                 ; xorcf A,(0x34)
	nop                                     ; nop
	.byte 0x1a, 0x35, 0x2a                 ; jp 0x2a35
	nop                                     ; nop
	ld	xix, 0x6e002a35
	ldw	iy, 0x002a
	ld_s	(xwa+53), de
	nop                                     ; nop
	xorcfa_rid8 xix, 0x35		; xorcf A,(XIX+0x35)
	nop                                     ; nop
	.byte 0xe6                             ; db
	ldw	iy, 0x002a
	.byte 0x10                             ; rcf
	ldw	iz, 0x002a
	popw wa                                 ; pop WA
	ldw	iz, 0x002a
	jrl	le, 0x2a36
	nop                                     ; nop
	ld_s	(xix+54), de
	nop                                     ; nop
	.byte 0xc6                             ; db
	ldw	iz, 0x002a
	.byte 0xf0, 0x36, 0x2a                 ; xorcf A,(0x36)
	nop                                     ; nop
	.byte 0x1a, 0x37, 0x2a                 ; jp 0x2a37
	nop                                     ; nop
	ldw	ix, 0x2a37
	nop                                     ; nop
	jr	gt, 0x37
	pushw de                                ; push DE
	nop                                     ; nop
	ex8_ri xix, l		; ex (XIX),L
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xwa+55), xde
	nop                                     ; nop
	cpdm16_24	0x002A37, ix
	.byte 0x37, 0x2a, 0x00                 ; ld SP,0x002a
	ldb	h, 0x38
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x52                             ; db
	push xwa
	pushw de                                ; push DE
	nop                                     ; nop
	jr	nov, 0x38
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xde+56), de
	nop                                     ; nop
	.byte 0xd6                             ; db
	push xwa
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xf0, 0x38, 0x2a                 ; xorcf A,(0x38)
	nop                                     ; nop
	pushw ix                                ; push IX
	push xbc
	pushw de                                ; push DE
	nop                                     ; nop
	ld	xiz, 0x5c002a39
	push xbc
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xwa+57), b
	nop                                     ; nop
	.byte 0xa2, 0x39                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xcc, 0x39                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xf6                             ; db
	push xbc
	pushw de                                ; push DE
	nop                                     ; nop
	ldb	w, 0x3a
	pushw de                                ; push DE
	nop                                     ; nop
	popw de                                 ; pop DE
	push xde
	pushw de                                ; push DE
	nop                                     ; nop
	jrl	gt, 0x2a3a
	nop                                     ; nop
	.byte 0xa4, 0x3a                       ; db
.LGD1_660a:
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xd4, 0x3a, 0x2a                 ; db
	nop                                     ; nop
	.byte 0xfe                             ; swi 6
	push xde
	pushw de                                ; push DE
	nop                                     ; nop
	pushw iz                                ; push IZ
	push xhl
	pushw de                                ; push DE
	nop                                     ; nop
	pop xwa                                 ; pop XWA
	push xhl
	pushw de                                ; push DE
	nop                                     ; nop
	sbc8_imm_ri xix, 0x2a		; sbc (XIX),0x2a
	nop                                     ; nop
	ld_s	(xiz+59), de
	nop                                     ; nop
	.byte 0xce, 0x3b                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xf8                             ; swi 0
	push xhl
	pushw de                                ; push DE
	nop                                     ; nop
	pushw wa                                ; push WA
	push xix
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x52                             ; db
	push xix
	pushw de                                ; push DE
	nop                                     ; nop
	jrl	nov, 0x2a3c
	nop                                     ; nop
	.byte 0xa6, 0x3c                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xd0, 0x3c, 0x2a                 ; db
	nop                                     ; nop
	ldio	61, 42
	nop                                     ; nop
	ldb	b, 0x3d
	pushw de                                ; push DE
	nop                                     ; nop
	push xix
	push xiy
	pushw de                                ; push DE
	nop                                     ; nop
	jr t, .LGD1_668b                       ; [68 3d] jr T,0x2a668b
	pushw de                                ; push DE
	nop                                     ; nop
	xor16_imm_ri xix, 0x2a, 0x00		; xor (XIX),0x002a
	xorcfa_rid8 xwa, 0x3d		; xorcf A,(XWA+0x3d)
	nop                                     ; nop
	.byte 0xe4, 0x3d, 0x2a                 ; db
	nop                                     ; nop
	.byte 0xfe                             ; swi 6
	push xiy
	pushw de                                ; push DE
	nop                                     ; nop
	pushw iz                                ; push IZ
	push xiz
	pushw de                                ; push DE
	nop                                     ; nop
	pop xwa                                 ; pop XWA
	push xiz
	pushw de                                ; push DE
	nop                                     ; nop
	or8_imm_ri xde, 0x2a		; or (XDE),0x2a
	nop                                     ; nop
	ld_s	(xix+62), xde
	nop                                     ; nop
	.byte 0xd6                             ; db
	push xiz
	pushw de                                ; push DE
	nop                                     ; nop
	nop                                     ; nop
	.byte 0x3f                             ; push XSP
	pushw de                                ; push DE
	nop                                     ; nop
	pushw ix                                ; push IX
	.byte 0x3f                             ; push XSP
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x56                             ; db
	.byte 0x3f                             ; push XSP
	pushw de                                ; push DE
	nop                                     ; nop
	cp	(xwa), 0x2a
	nop                                     ; nop
	ld_s	(xde+63), xde
	nop                                     ; nop
	.byte 0xd4, 0x3f, 0x2a                 ; db
.LGD1_668b:
	nop                                     ; nop
	nop                                     ; nop
	ld	xwa, 0x402a002a
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x54                             ; db
	ld	xwa, 0x407e002a
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xwa+64), xde
	nop                                     ; nop
	.byte 0xd4, 0x40, 0x2a                 ; db
	nop                                     ; nop
	.byte 0xfe                             ; swi 6
	ld	xwa, 0x4128002a
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x52                             ; db
	ld	xbc, 0x417c002a
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xwa+65), xde
	nop                                     ; nop
	cpdm16_24	0x002A41, ix
	ld	xbc, 0x4226002a
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x50                             ; db
	ld	xde, 0x427c002a
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xa6, 0x42                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xd0, 0x42, 0x2a                 ; db
	nop                                     ; nop
	.byte 0xfa                             ; swi 2
	ld	xde, 0x4324002a
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x50                             ; db
	ld	xhl, 0x437a002a
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xa4, 0x43                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	mul8rr c, h		; mul BC,H
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xf8                             ; swi 0
	ld	xhl, 0x4424002a
	pushw de                                ; push DE
	nop                                     ; nop
	popw iz                                 ; pop IZ
	ld	xix, 0x4478002a
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xa2, 0x44                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	mul8rr d, d		; mul ??,D
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xf8                             ; swi 0
	ld	xix, 0x4522002a
	pushw de                                ; push DE
	nop                                     ; nop
	popw ix                                 ; pop IX
	ld	xiy, 0x4576002a
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xa0, 0x45                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	mul8rr e, d		; mul DE,D
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xe6                             ; db
	ld	xiy, 0x4616002a
	pushw de                                ; push DE
	nop                                     ; nop
	ld	xwa, 0x6a002a46
	ld	xiz, 0x4694002a
	pushw de                                ; push DE
	nop                                     ; nop
	xorcfa_rid8 xiz, 0x46		; xorcf A,(XIZ+0x46)
	nop                                     ; nop
	.byte 0xf6                             ; db
	ld	xiz, 0x4710002a
	pushw de                                ; push DE
	nop                                     ; nop
	push xde
	ld	xsp, 0x475c002a
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x96, 0x47                       ; mul XSP,(XIZ)
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xd0, 0x47, 0x2a                 ; db
	nop                                     ; nop
	.byte 0xfa                             ; swi 2
	ld	xsp, 0x4824002a
	pushw de                                ; push DE
	nop                                     ; nop
	jr le, .LGD1_679e                      ; [62 48] jr LE,0x2a679e
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xde+72), de
	nop                                     ; nop
	muls	xwa, xde
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x04                             ; max
	popw bc                                 ; pop BC
	pushw de                                ; push DE
	nop                                     ; nop
	pushw iz                                ; push IZ
	popw bc                                 ; pop BC
	pushw de                                ; push DE
	nop                                     ; nop
	pop xwa                                 ; pop XWA
	popw bc                                 ; pop BC
	pushw de                                ; push DE
	nop                                     ; nop
	muls8_ri xde, a		; muls WA,(XDE)
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xc6                             ; db
	popw bc                                 ; pop BC
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xf0, 0x49, 0x2a                 ; xorcf A,(0x49)
	nop                                     ; nop
	ldwio	74, 42
	ldw	ix, 0x2a4a
	nop                                     ; nop
	pop xwa                                 ; pop XWA
	popw de                                 ; pop DE
	pushw de                                ; push DE
	nop                                     ; nop
	muls8_ri xde, b		; muls ??,(XDE)
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xix+74), xde
	nop                                     ; nop
	ret

	.byte 0x9f, 0x23, 0x00                 ; db
	muls8rr b, h		; muls ??,H
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xe8, 0x4a                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x12                             ; ccf
	popw hl                                 ; pop HL
	pushw de                                ; push DE
	nop                                     ; nop
	push xix
	popw hl                                 ; pop HL
.LGD1_679e:
	pushw de                                ; push DE
	nop                                     ; nop
	jr	z, 0x4b
	pushw de                                ; push DE
	nop                                     ; nop
	pushw wa                                ; push WA
	.byte 0x9f, 0x23, 0x00                 ; db
	ld_s	(xwa+75), b
	nop                                     ; nop
	.byte 0xa2, 0x4b                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	muls8rr c, d		; muls BC,D
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xf6                             ; db
	popw hl                                 ; pop HL
	pushw de                                ; push DE
	nop                                     ; nop
	ldb	w, 0x4c
	pushw de                                ; push DE
	nop                                     ; nop
	ld	xde, 0x5c002a4c
	popw ix                                 ; pop IX
	pushw de                                ; push DE
	nop                                     ; nop
	jrl	z, 0x2a4c
	nop                                     ; nop
	.byte 0xa0, 0x4c                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	muls8rr d, b		; muls ??,B
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xf4, 0x4c, 0x2a                 ; xorcf A,(-r4CL)
	nop                                     ; nop
	.byte 0x16                             ; ex F,F'
	popw iy                                 ; pop IY
	pushw de                                ; push DE
	nop                                     ; nop
	ldw	wa, 0x2a4d
	nop                                     ; nop
	popw de                                 ; pop DE
	popw iy                                 ; pop IY
	pushw de                                ; push DE
	nop                                     ; nop
	jrl	ov, 0x2a4d
	nop                                     ; nop
	ld_s	(xiz+77), de
	nop                                     ; nop
	muls8rr e, w		; muls DE,W
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xf2, 0x4d, 0x2a, 0x00, 0x14, 0x4e, 0x2a ; ld (0x002a4d),(0x2a4e)
	nop                                     ; nop
	pushw iz                                ; push IZ
	popw iz                                 ; pop IZ
	pushw de                                ; push DE
	nop                                     ; nop
	popw wa                                 ; pop WA
	popw iz                                 ; pop IZ
	pushw de                                ; push DE
	nop                                     ; nop
	jrl	le, 0x2a4e
	nop                                     ; nop
	ld_s	(xix+78), de
	nop                                     ; nop
	.byte 0xc6                             ; db
	popw iz                                 ; pop IZ
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xf0, 0x4e, 0x2a                 ; xorcf A,(0x4e)
	nop                                     ; nop
	.byte 0x12                             ; ccf
	.byte 0x4f                             ; pop SP
	pushw de                                ; push DE
	nop                                     ; nop
	pushw ix                                ; push IX
	.byte 0x4f                             ; pop SP
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x56                             ; db
	.byte 0x4f                             ; pop SP
	pushw de                                ; push DE
	nop                                     ; nop
	muls8_ri xwa, l		; muls HL,(XWA)
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xde+79), xde
	nop                                     ; nop
	muls8rr l, d		; muls HL,D
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xe6                             ; db
	.byte 0x4f                             ; pop SP
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x10                             ; rcf
	.byte 0x50                             ; db
	pushw de                                ; push DE
	nop                                     ; nop
	push xde
	.byte 0x50                             ; db
	pushw de                                ; push DE
	nop                                     ; nop
	jr	ov, 0x50
	pushw de                                ; push DE
	nop                                     ; nop
	div8_ri xiz, w		; div ??,(XIZ)
	pushw de                                ; push DE
	nop                                     ; nop
	ld (xwa), wa                            ; ld (XWA),WA
	pushw de                                ; push DE
	nop                                     ; nop
	div	xwa, xde
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xfc                             ; swi 4
	.byte 0x50                             ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x16                             ; ex F,F'
	.byte 0x51                             ; db
	pushw de                                ; push DE
	nop                                     ; nop
	ldw	wa, 0x2a51
	nop                                     ; nop
	pop xde                                 ; pop XDE
	.byte 0x51                             ; db
	pushw de                                ; push DE
	nop                                     ; nop
	div8_ri xix, a		; div WA,(XIX)
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xiz+81), xde
	nop                                     ; nop
	div	xbc, xwa
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xfa                             ; swi 2
	.byte 0x51                             ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x14                             ; push A
	.byte 0x52                             ; db
	pushw de                                ; push DE
	nop                                     ; nop
	pushw iz                                ; push IZ
	.byte 0x52                             ; db
	pushw de                                ; push DE
	nop                                     ; nop
	pop xwa                                 ; pop XWA
	.byte 0x52                             ; db
	pushw de                                ; push DE
	nop                                     ; nop
	div8_ri xde, b		; div ??,(XDE)
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xix+82), xde
	nop                                     ; nop
	.byte 0xd6                             ; db
	.byte 0x52                             ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x02                             ; push SR
	.byte 0x53                             ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x1c, 0x53, 0x2a                 ; call 0x2a53
	nop                                     ; nop
	push xwa
	.byte 0x53                             ; db
.LGD1_6882:
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x54                             ; db
	.byte 0x53                             ; db
	pushw de                                ; push DE
	nop                                     ; nop
	jr	nz, 0x53
	pushw de                                ; push DE
	nop                                     ; nop
	div16_ri xde, hl		; div XHL,(XDE)
	pushw de                                ; push DE
	nop                                     ; nop
	ld (xiz), hl                            ; ld (XIZ),HL
	pushw de                                ; push DE
	nop                                     ; nop
	div	xhl, xiz
	pushw de                                ; push DE
	nop                                     ; nop
	ldio	84, 42
	nop                                     ; nop
	ld	xix, 0x6c002a54
	.byte 0x54                             ; db
	pushw de                                ; push DE
	nop                                     ; nop
	div8_ri xiz, d		; div ??,(XIZ)
	pushw de                                ; push DE
	nop                                     ; nop
	ld	(xiz), ix
	pushw de                                ; push DE
	nop                                     ; nop
	div	xix, xiz
	pushw de                                ; push DE
	nop                                     ; nop
	ldwio	85, 42
	ldb	d, 0x55
	pushw de                                ; push DE
	nop                                     ; nop
	jr f, .LGD1_690f                       ; [60 55] jr F,0x2a690f
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xiz+85), de
	nop                                     ; nop
	div8rr e, d		; div DE,D
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xe2, 0x55, 0x2a, 0x00, 0x0c     ; db
	.byte 0x56                             ; db
	pushw de                                ; push DE
	nop                                     ; nop
	ld	xde, 0x74002a56
	.byte 0x56                             ; db
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xwa+86), xde
	nop                                     ; nop
	.byte 0xd4, 0x56, 0x2a                 ; db
	nop                                     ; nop
	ldwio	87, 42
	push xix
	.byte 0x57                             ; db
	pushw de                                ; push DE
	nop                                     ; nop
	jr nz, .LGD1_693d                      ; [6e 57] jr NZ,0x2a693d
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xa4, 0x57                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	div	xsp, xde
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x10                             ; rcf
	pop xwa                                 ; pop XWA
	pushw de                                ; push DE
	nop                                     ; nop
	pushw de                                ; push DE
	pop xwa                                 ; pop XWA
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x54                             ; db
	pop xwa                                 ; pop XWA
	pushw de                                ; push DE
	nop                                     ; nop
	jrl	t, 0x2a58
	nop                                     ; nop
	.byte 0xa2, 0x58                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xc6                             ; db
	pop xwa                                 ; pop XWA
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xea, 0x58                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	ret

	pop xbc                                 ; pop XBC
	pushw de                                ; push DE
.LGD1_690f:
	nop                                     ; nop
	ldw	de, 0x2a59
	nop                                     ; nop
	.byte 0x56                             ; db
	pop xbc                                 ; pop XBC
	pushw de                                ; push DE
	nop                                     ; nop
	jrl	gt, 0x2a59
	nop                                     ; nop
	ld_s	(xiz+89), de
	nop                                     ; nop
	orda8_24	h, 0x002A59
	pop xbc                                 ; pop XBC
	pushw de                                ; push DE
	nop                                     ; nop
	ld	xde, 0x6600239f
	.byte 0x9f, 0x23, 0x00                 ; db
	ld	c, (xde-97)
	nop                                     ; nop
	ld	xhl, (xiz-97)
	nop                                     ; nop
	.byte 0x10                             ; rcf
	pop xde                                 ; pop XDE
	pushw de                                ; push DE
	nop                                     ; nop
	push xiz
.LGD1_693d:
	pop xde                                 ; pop XDE
	pushw de                                ; push DE
	nop                                     ; nop
	jrl	nov, 0x2a5a
	nop                                     ; nop
	divs16_ri xiz, de		; divs XDE,(XIZ)
	pushw de                                ; push DE
	nop                                     ; nop
	xorcfa_rid8 xix, 0x5a		; xorcf A,(XIX+0x5a)
	nop                                     ; nop
	.byte 0xe2, 0x5a, 0x2a, 0x00, 0x02     ; db
	pop xhl                                 ; pop XHL
	pushw de                                ; push DE
	nop                                     ; nop
	pushw iz                                ; push IZ
	pop xhl                                 ; pop XHL
	pushw de                                ; push DE
	nop                                     ; nop
	pop xwa                                 ; pop XWA
	pop xhl                                 ; pop XHL
	pushw de                                ; push DE
	nop                                     ; nop
	divs8_ri xde, c		; divs BC,(XDE)
	pushw de                                ; push DE
	nop                                     ; nop
	xorcfa_rid8 xix, 0x5b		; xorcf A,(XIX+0x5b)
	nop                                     ; nop
	.byte 0xd6                             ; db
	pop xhl                                 ; pop XHL
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x12                             ; ccf
	pop xix                                 ; pop XIX
	pushw de                                ; push DE
	nop                                     ; nop
	push xix
	pop xix                                 ; pop XIX
	pushw de                                ; push DE
	nop                                     ; nop
	jrl	t, 0x2a5c
	nop                                     ; nop
	.byte 0xa2, 0x5c                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	divs	xix, xiz
	pushw de                                ; push DE
	nop                                     ; nop
	ldio	93, 42
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop


HDAE5000_GFX_DATA_2:	; 0x2A6984
	; Graphics data block 2
; LGD2: 0x2A6984 (6934 bytes)

	add	ix, (xde)
	pushw de                                ; push DE
	nop                                     ; nop
	add	ix, (xwa)
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xiz-124), b
	nop                                     ; nop
	ld_s	(xix-124), b
	nop                                     ; nop
	ld_s	(xde-124), b
	nop                                     ; nop
	ld_s	(xwa-124), b
	nop                                     ; nop
	add	d, (xiz)
	pushw de                                ; push DE
	nop                                     ; nop
	add	d, (xix)
	pushw de                                ; push DE
	nop                                     ; nop
	add	d, (xde)
	pushw de                                ; push DE
	nop                                     ; nop
	add	d, (xwa)
	pushw de                                ; push DE
	nop                                     ; nop
	jrl	le, 0x2a84
	nop                                     ; nop
	jrl	f, 0x2a84
	nop                                     ; nop
	jr	nz, 0x84
	pushw de                                ; push DE
	nop                                     ; nop
	jr	nov, 0x84
	pushw de                                ; push DE
	nop                                     ; nop
	jr	gt, 0x84
	pushw de                                ; push DE
	nop                                     ; nop
	jr	t, 0x84
	pushw de                                ; push DE
	nop                                     ; nop
	jr	z, 0x84
	pushw de                                ; push DE
	nop                                     ; nop
	jr	ov, 0x84
	pushw de                                ; push DE
	nop                                     ; nop
	jr	le, 0x84
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x54                             ; db
	ld_s	(xix), b
	nop                                     ; nop
	.byte 0x52                             ; db
	ld_s	(xix), b
	nop                                     ; nop
	.byte 0x50                             ; db
	ld_s	(xix), b
	nop                                     ; nop
	popw iz                                 ; pop IZ
	ld_s	(xix), b
	nop                                     ; nop
	popw ix                                 ; pop IX
	ld_s	(xix), b
	nop                                     ; nop
	ld	xwa, 0x3e002a84
	ld_s	(xix), b
	nop                                     ; nop
	ldw	wa, 0x2a84
	nop                                     ; nop
	ldb	w, 0x84
	pushw de                                ; push DE
	nop                                     ; nop
	calr	0x2a84
	nop                                     ; nop
	.byte 0x1c, 0x84, 0x2a                 ; call 0x2a84
	nop                                     ; nop
	.byte 0x1a, 0x84, 0x2a                 ; jp 0x2a84
	nop                                     ; nop
	.byte 0x18                             ; push F
	ld_s	(xix), b
	nop                                     ; nop
	.byte 0x16                             ; ex F,F'
	ld_s	(xix), b
	nop                                     ; nop
	.byte 0x14                             ; push A
	ld_s	(xix), b
	nop                                     ; nop
	ldio	132, 42
	nop                                     ; nop
	ei 0x84		; ei 0x84
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x04                             ; max
	ld_s	(xix), b
	nop                                     ; nop
	.byte 0xfc                             ; swi 4
	ld_s	(xhl), b
	nop                                     ; nop
	.byte 0xfa                             ; swi 2
	ld_s	(xhl), b
	nop                                     ; nop
	.byte 0xf8                             ; swi 0
	ld_s	(xhl), b
	nop                                     ; nop
	.byte 0xf6                             ; db
	ld_s	(xhl), b
	nop                                     ; nop
	.byte 0xf4, 0x83, 0x2a                 ; xorcf A,(-r83L)
	nop                                     ; nop
	.byte 0xf2, 0x83, 0x2a, 0x00, 0xf0     ; db
	ld_s	(xhl), b
	nop                                     ; nop
	add	hl, ix
	pushw de                                ; push DE
	nop                                     ; nop
	add	hl, de
	pushw de                                ; push DE
	nop                                     ; nop
	add	hl, wa
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xd6                             ; db
	ld_s	(xhl), b
	nop                                     ; nop
	.byte 0xd4, 0x83, 0x2a                 ; db
	nop                                     ; nop
	add	c, w
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xc6                             ; db
	ld_s	(xhl), b
	nop                                     ; nop
	.byte 0xc4, 0x83, 0x2a                 ; db
	nop                                     ; nop
	andda8_24	w, 0x002A83
	ld_s	(xhl), b
	nop                                     ; nop
	xorcfa_rid8 xiz, 0x83		; xorcf A,(XIZ+0x83)
	nop                                     ; nop
	xorcfa_rid8 xix, 0x83		; xorcf A,(XIX+0x83)
	nop                                     ; nop
	xorcfa_rid8 xde, 0x83		; xorcf A,(XDE+0x83)
	nop                                     ; nop
	xorcfa_rid8 xwa, 0x83		; xorcf A,(XWA+0x83)
	nop                                     ; nop
	ld_s	(xwa-125), xde
	nop                                     ; nop
	add	xhl, (xiz)
	pushw de                                ; push DE
	nop                                     ; nop
	add	xhl, (xix)
	pushw de                                ; push DE
	nop                                     ; nop
	add	xhl, (xde)
	pushw de                                ; push DE
	nop                                     ; nop
	add	xhl, (xwa)
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xiz-125), de
	nop                                     ; nop
	ld_s	(xix-125), de
	nop                                     ; nop
	ld_s	(xde-125), de
	nop                                     ; nop
	ld_s	(xwa-125), de
	nop                                     ; nop
	add	hl, (xiz)
	pushw de                                ; push DE
	nop                                     ; nop
	add	hl, (xix)
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xde-125), b
	nop                                     ; nop
	ld_s	(xwa-125), b
	nop                                     ; nop
	add	c, (xiz)
	pushw de                                ; push DE
	nop                                     ; nop
	add	c, (xix)
	pushw de                                ; push DE
	nop                                     ; nop
	jrl	gt, 0x2a83
	nop                                     ; nop
	jrl	t, 0x2a83
	nop                                     ; nop
	jr	nz, 0x83
	pushw de                                ; push DE
	nop                                     ; nop
	jr	t, 0x83
	pushw de                                ; push DE
	nop                                     ; nop
	jr	f, 0x83
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x50                             ; db
	ld_s	(xhl), b
	nop                                     ; nop
	popw iz                                 ; pop IZ
	ld_s	(xhl), b
	nop                                     ; nop
	popw ix                                 ; pop IX
	ld_s	(xhl), b
	nop                                     ; nop
	popw de                                 ; pop DE
	ld_s	(xhl), b
	nop                                     ; nop
	popw wa                                 ; pop WA
	ld_s	(xhl), b
	nop                                     ; nop
	ld	xiz, 0x44002a83
	ld_s	(xhl), b
	nop                                     ; nop
	ld	xde, 0x40002a83
	ld_s	(xhl), b
	nop                                     ; nop
	ldw	de, 0x2a83
	nop                                     ; nop
	ldb	b, 0x83
	pushw de                                ; push DE
	nop                                     ; nop
	ldb	w, 0x83
	pushw de                                ; push DE
	nop                                     ; nop
	calr	0x2a83
	nop                                     ; nop
	.byte 0x1c, 0x83, 0x2a                 ; call 0x2a83
	nop                                     ; nop
	.byte 0x1a, 0x83, 0x2a                 ; jp 0x2a83
	nop                                     ; nop
	.byte 0x18                             ; push F
	ld_s	(xhl), b
	nop                                     ; nop
	ldwio	131, 42
	ldio	131, 42
	nop                                     ; nop
	nop                                     ; nop
	ld_s	(xhl), b
	nop                                     ; nop
	.byte 0xfe                             ; swi 6
	ld_s	(xde), b
	nop                                     ; nop
	.byte 0xfc                             ; swi 4
	ld_s	(xde), b
	nop                                     ; nop
	.byte 0xfa                             ; swi 2
	ld_s	(xde), b
	nop                                     ; nop
	.byte 0xf8                             ; swi 0
	ld_s	(xde), b
	nop                                     ; nop
	.byte 0xf6                             ; db
	ld_s	(xde), b
	nop                                     ; nop
.LGD2_6b1c:
	add	xde, xwa
	pushw de                                ; push DE
	nop                                     ; nop
.LGD2_6b20:
	.byte 0xe6                             ; db
	ld_s	(xde), b
	nop                                     ; nop
.LGD2_6b24:
	add	de, ix
	pushw de                                ; push DE
	nop                                     ; nop
.LGD2_6b28:
	add	de, de
	pushw de                                ; push DE
	nop                                     ; nop
.LGD2_6b2c:
	add	de, wa
	pushw de                                ; push DE
	nop                                     ; nop
.LGD2_6b30:
	.byte 0xd6                             ; db
	ld_s	(xde), b
	nop                                     ; nop
.LGD2_6b34:
	.byte 0xd4, 0x82, 0x2a                 ; db
	nop                                     ; nop
	andda16_24	de, 0x002A82
	ld_s	(xde), b
	nop                                     ; nop
	.byte 0xc0, 0x82, 0x2a                 ; db
	nop                                     ; nop
	xorcfa_rid8 xiz, 0x82		; xorcf A,(XIZ+0x82)
	nop                                     ; nop
	xorcfa_rid8 xix, 0x82		; xorcf A,(XIX+0x82)
	nop                                     ; nop
	xorcfa_rid8 xde, 0x82		; xorcf A,(XDE+0x82)
	nop                                     ; nop
	xorcfa_rid8 xwa, 0x82		; xorcf A,(XWA+0x82)
	nop                                     ; nop
	andcfn_ri xiz, 2		; andcf 2,(XIZ)
	pushw de                                ; push DE
	nop                                     ; nop
	andcfn_ri xix, 2		; andcf 2,(XIX)
	pushw de                                ; push DE
	nop                                     ; nop
	andcfn_ri xde, 2		; andcf 2,(XDE)
	pushw de                                ; push DE
	nop                                     ; nop
	andcfn_ri xwa, 2		; andcf 2,(XWA)
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xiz-126), xde
	nop                                     ; nop
	ld_s	(xix-126), xde
	nop                                     ; nop
	ld_s	(xix-126), de
	nop                                     ; nop
	ld_s	(xde-126), de
	nop                                     ; nop
	ld_s	(xwa-126), de
	nop                                     ; nop
	add	de, (xiz)
	pushw de                                ; push DE
	nop                                     ; nop
	add	de, (xix)
	pushw de                                ; push DE
	nop                                     ; nop
	add	de, (xde)
	pushw de                                ; push DE
	nop                                     ; nop
	add	b, (xix)
	pushw de                                ; push DE
	nop                                     ; nop
	add	b, (xde)
	pushw de                                ; push DE
	nop                                     ; nop
	add	b, (xwa)
	pushw de                                ; push DE
	nop                                     ; nop
	jrl	nz, 0x2a82
	nop                                     ; nop
	jrl	nov, 0x2a82
	nop                                     ; nop
	jr	nov, 0x82
	pushw de                                ; push DE
	nop                                     ; nop
	jr gt, .LGD2_6b20                      ; [6a 82] jr GT,0x2a6b20
	pushw de                                ; push DE
	nop                                     ; nop
	jr t, .LGD2_6b24                       ; [68 82] jr T,0x2a6b24
	pushw de                                ; push DE
	nop                                     ; nop
	jr z, .LGD2_6b28                       ; [66 82] jr Z,0x2a6b28
	pushw de                                ; push DE
	nop                                     ; nop
	jr	ov, 0x82
	pushw de                                ; push DE
	nop                                     ; nop
	jr le, .LGD2_6b30                      ; [62 82] jr LE,0x2a6b30
	pushw de                                ; push DE
	nop                                     ; nop
	jr f, .LGD2_6b34                       ; [60 82] jr F,0x2a6b34
	pushw de                                ; push DE
	nop                                     ; nop
	pop xiz                                 ; pop XIZ
	ld_s	(xde), b
	nop                                     ; nop
	pop xix                                 ; pop XIX
	ld_s	(xde), b
	nop                                     ; nop
	pop xde                                 ; pop XDE
	ld_s	(xde), b
	nop                                     ; nop
	popw iz                                 ; pop IZ
	ld_s	(xde), b
	nop                                     ; nop
	popw ix                                 ; pop IX
	ld_s	(xde), b
	nop                                     ; nop
	popw de                                 ; pop DE
	ld_s	(xde), b
	nop                                     ; nop
	popw wa                                 ; pop WA
	ld_s	(xde), b
	nop                                     ; nop
	ld	xiz, 0x44002a82
	ld_s	(xde), b
	nop                                     ; nop
	push xix
	ld_s	(xde), b
	nop                                     ; nop
	push xde
	ld_s	(xde), b
	nop                                     ; nop
	push xwa
	ld_s	(xde), b
	nop                                     ; nop
	pushw ix                                ; push IX
	ld_s	(xde), b
	nop                                     ; nop
	pushw de                                ; push DE
	ld_s	(xde), b
	nop                                     ; nop
	pushw wa                                ; push WA
	ld_s	(xde), b
	nop                                     ; nop
	ldb	h, 0x82
	pushw de                                ; push DE
	nop                                     ; nop
	ldb	d, 0x82
	pushw de                                ; push DE
	nop                                     ; nop
	ldb	b, 0x82
	pushw de                                ; push DE
	nop                                     ; nop
	ldb	w, 0x82
	pushw de                                ; push DE
	nop                                     ; nop
	calr	0x2a82
	nop                                     ; nop
	.byte 0x1c, 0x82, 0x2a                 ; call 0x2a82
	nop                                     ; nop
	.byte 0x1a, 0x82, 0x2a                 ; jp 0x2a82
	nop                                     ; nop
	.byte 0x18                             ; push F
	ld_s	(xde), b
	nop                                     ; nop
	.byte 0x16                             ; ex F,F'
	ld_s	(xde), b
	nop                                     ; nop
	.byte 0x14                             ; push A
	ld_s	(xde), b
	nop                                     ; nop
	.byte 0x12                             ; ccf
	ld_s	(xde), b
	nop                                     ; nop
	.byte 0x10                             ; rcf
	ld_s	(xde), b
	nop                                     ; nop
	ret

	ld_s	(xde), b
	nop                                     ; nop
	nop                                     ; nop
	ld_s	(xde), b
	nop                                     ; nop
	.byte 0xf0, 0x81, 0x2a                 ; xorcf A,(0x81)
	nop                                     ; nop
	.byte 0xe0, 0x81, 0x2a                 ; db
	nop                                     ; nop
	add	a, h
	pushw de                                ; push DE
	nop                                     ; nop
	add	a, d
	pushw de                                ; push DE
	nop                                     ; nop
	add	a, b
	pushw de                                ; push DE
	nop                                     ; nop
	add	a, w
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xc0, 0x81, 0x2a                 ; db
	nop                                     ; nop
	xorcfa_rid8 xiz, 0x81		; xorcf A,(XIZ+0x81)
	nop                                     ; nop
	xorcfa_rid8 xix, 0x81		; xorcf A,(XIX+0x81)
	nop                                     ; nop
	xorcfa_rid8 xde, 0x81		; xorcf A,(XDE+0x81)
	nop                                     ; nop
	xorcfa_rid8 xwa, 0x81		; xorcf A,(XWA+0x81)
	nop                                     ; nop
	andcfn_ri xiz, 1		; andcf 1,(XIZ)
	pushw de                                ; push DE
	nop                                     ; nop
	andcfn_ri xix, 1		; andcf 1,(XIX)
	pushw de                                ; push DE
	nop                                     ; nop
	andcfn_ri xde, 1		; andcf 1,(XDE)
	pushw de                                ; push DE
.LGD2_6c5f:
	nop                                     ; nop
	andcfn_ri xwa, 1		; andcf 1,(XWA)
	pushw de                                ; push DE
.LGD2_6c63:
	nop                                     ; nop
	ld_s	(xiz-127), xde
	nop                                     ; nop
	ld_s	(xix-127), xde
	nop                                     ; nop
	ld_s	(xde-127), xde
	nop                                     ; nop
	ld_s	(xwa-127), xde
	nop                                     ; nop
	add	xbc, (xiz)
	pushw de                                ; push DE
	nop                                     ; nop
	add	xbc, (xix)
	pushw de                                ; push DE
	nop                                     ; nop
	add	xbc, (xde)
	pushw de                                ; push DE
	nop                                     ; nop
	add	xbc, (xwa)
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xiz-127), de
	nop                                     ; nop
	ld_s	(xix-127), de
	nop                                     ; nop
	ld_s	(xde-127), de
	nop                                     ; nop
	ld_s	(xwa-127), de
	nop                                     ; nop
	add	bc, (xiz)
	pushw de                                ; push DE
	nop                                     ; nop
	add	bc, (xix)
	pushw de                                ; push DE
	nop                                     ; nop
	add	bc, (xde)
	pushw de                                ; push DE
	nop                                     ; nop
	add	bc, (xwa)
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xiz-127), b
	nop                                     ; nop
	ld_s	(xix-127), b
	nop                                     ; nop
	ld_s	(xde-127), b
	nop                                     ; nop
	ld_s	(xwa-127), b
	nop                                     ; nop
	add	a, (xiz)
	pushw de                                ; push DE
	nop                                     ; nop
	add	a, (xix)
	pushw de                                ; push DE
	nop                                     ; nop
	add	a, (xde)
	pushw de                                ; push DE
	nop                                     ; nop
	add	a, (xwa)
	pushw de                                ; push DE
	nop                                     ; nop
	jrl	nz, 0x2a81
	nop                                     ; nop
	jrl	nov, 0x2a81
	nop                                     ; nop
	jrl	z, 0x2a81
	nop                                     ; nop
	jrl	ov, 0x2a81
	nop                                     ; nop
	jrl	le, 0x2a81
	nop                                     ; nop
	jrl	f, 0x2a81
	nop                                     ; nop
	jr nz, .LGD2_6c5f                      ; [6e 81] jr NZ,0x2a6c5f
	pushw de                                ; push DE
	nop                                     ; nop
	jr le, .LGD2_6c63                      ; [62 81] jr LE,0x2a6c63
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x56                             ; db
	ld_s	(xbc), b
	nop                                     ; nop
	popw de                                 ; pop DE
	ld_s	(xbc), b
	nop                                     ; nop
	push xix
	ld_s	(xbc), b
	nop                                     ; nop
	push xde
	ld_s	(xbc), b
	nop                                     ; nop
	pushw ix                                ; push IX
	ld_s	(xbc), b
	nop                                     ; nop
	pushw de                                ; push DE
	ld_s	(xbc), b
	nop                                     ; nop
	.byte 0x1a, 0x81, 0x2a                 ; jp 0x2a81
	nop                                     ; nop
	.byte 0x18                             ; push F
	ld_s	(xbc), b
	nop                                     ; nop
	ldio	129, 42
	nop                                     ; nop
	ei 0x81		; ei 0x81
.LGD2_6d0a:
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xf8                             ; swi 0
	ld_s	(xwa), b
	nop                                     ; nop
	.byte 0xf6                             ; db
	ld_s	(xwa), b
	nop                                     ; nop
	.byte 0xf4, 0x80, 0x2a                 ; xorcf A,(-r80L)
	nop                                     ; nop
	call_24	ov, 0x002A80
	ld_s	(xwa), b
	nop                                     ; nop
	or	xwa, (0x002a80)
	ld_s	(xwa), b
	nop                                     ; nop
	add	wa, iz
	pushw de                                ; push DE
	nop                                     ; nop
	add	wa, ix
	pushw de                                ; push DE
	nop                                     ; nop
	add	wa, de
	pushw de                                ; push DE
	nop                                     ; nop
	add	wa, wa
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xd6                             ; db
	ld_s	(xwa), b
	nop                                     ; nop
	.byte 0xd4, 0x80, 0x2a                 ; db
	nop                                     ; nop
	andda16_24	iz, 0x002A80
	ld_s	(xwa), b
	nop                                     ; nop
	.byte 0xc4, 0x80, 0x2a                 ; db
	nop                                     ; nop
	andda8_24	w, 0x002A80
	ld_s	(xwa), b
	nop                                     ; nop
	xorcfa_rid8 xiz, 0x80		; xorcf A,(XIZ+0x80)
	nop                                     ; nop
	xorcfa_rid8 xix, 0x80		; xorcf A,(XIX+0x80)
	nop                                     ; nop
	xorcfa_rid8 xde, 0x80		; xorcf A,(XDE+0x80)
	nop                                     ; nop
	xorcfa_rid8 xwa, 0x80		; xorcf A,(XWA+0x80)
	nop                                     ; nop
	andcfn_ri xwa, 0		; andcf 0,(XWA)
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xix-128), de
	nop                                     ; nop
	ld_s	(xde-128), de
	nop                                     ; nop
	add	wa, (xde)
	pushw de                                ; push DE
	nop                                     ; nop
	add	wa, (xwa)
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xiz-128), b
	nop                                     ; nop
	ld_s	(xix-128), b
	nop                                     ; nop
	jrl	nov, 0x2a80
	nop                                     ; nop
	jr	z, 0x80
	pushw de                                ; push DE
	nop                                     ; nop
	jr	ov, 0x80
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x54                             ; db
	ld_s	(xwa), b
	nop                                     ; nop
	ld	xiz, 0x34002a80
	ld_s	(xwa), b
	nop                                     ; nop
	ldw	de, 0x2a80
	nop                                     ; nop
	ldw	wa, 0x2a80
	nop                                     ; nop
	pushw iz                                ; push IZ
	ld_s	(xwa), b
	nop                                     ; nop
	pushw ix                                ; push IX
	ld_s	(xwa), b
	nop                                     ; nop
	pushw de                                ; push DE
	ld_s	(xwa), b
	nop                                     ; nop
	.byte 0x16                             ; ex F,F'
	ld_s	(xwa), b
	nop                                     ; nop
	.byte 0x14                             ; push A
	ld_s	(xwa), b
	nop                                     ; nop
	.byte 0x12                             ; ccf
	ld_s	(xwa), b
	nop                                     ; nop
	.byte 0xfa                             ; swi 2
	jrl	nc, 0x002a
	.byte 0xf8                             ; swi 0
	jrl	nc, 0x002a
	.byte 0xf6                             ; db
	jrl	nc, 0x002a
	.byte 0xe6                             ; db
	jrl	nc, 0x002a
	.byte 0xe4, 0x7f, 0x2a                 ; db
	nop                                     ; nop
	or	xwa, (0x002a7f)
	jrl nc, .LGD2_6dfe                     ; [7f 2a 00] jrl NC,0x2a6dfe
	scc16	nc, iz
	pushw de                                ; push DE
	nop                                     ; nop
	scc16	nc, ix
	pushw de                                ; push DE
	nop                                     ; nop
	scc16	nc, de
	pushw de                                ; push DE
	nop                                     ; nop
	scc16	nc, wa
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xd6                             ; db
	jrl	nc, 0x002a
	.byte 0xd4, 0x7f, 0x2a                 ; db
	nop                                     ; nop
	xorda16_24	wa, 0x002A7F
	jrl	nc, 0x002a
	scc8	nc, h
	pushw de                                ; push DE
	nop                                     ; nop
	scc8	nc, d
	pushw de                                ; push DE
	nop                                     ; nop
	scc8	nc, b
.LGD2_6dfe:
	pushw de                                ; push DE
	nop                                     ; nop
	scc8	nc, w
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xc6                             ; db
	jrl nc, .LGD2_6e32                     ; [7f 2a 00] jrl NC,0x2a6e32
	.byte 0xc4, 0x7f, 0x2a                 ; db
	nop                                     ; nop
	andda8_24	w, 0x002A7F
	jrl	nc, 0x002a
	xorcfa_rid8 xiz, 0x7f		; xorcf A,(XIZ+0x7f)
	nop                                     ; nop
	xorcfa_rid8 xix, 0x7f		; xorcf A,(XIX+0x7f)
	nop                                     ; nop
	xorcfa_rid8 xde, 0x7f		; xorcf A,(XDE+0x7f)
	nop                                     ; nop
	xorcfa_rid8 xwa, 0x7f		; xorcf A,(XWA+0x7f)
	nop                                     ; nop
	.byte 0xb6, 0x7f                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xb4, 0x7f                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xb2, 0x7f                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xb0, 0x7f                       ; db
.LGD2_6e32:
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xiz+127), xde
	nop                                     ; nop
	ld_s	(xix+127), xde
	nop                                     ; nop
	ld_s	(xde+127), xde
	nop                                     ; nop
	ld_s	(xwa+127), xde
	nop                                     ; nop
	.byte 0xa6, 0x7f                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xa4, 0x7f                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xa2, 0x7f                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xa0, 0x7f                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	srlw_ri xwa		; srlw (XWA)
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xiz+127), b
	nop                                     ; nop
	ld_s	(xix+127), b
	nop                                     ; nop
	ld_s	(xde+127), b
	nop                                     ; nop
	ld_s	(xwa+127), b
	nop                                     ; nop
	srl_ri xiz		; srl (XIZ)
	pushw de                                ; push DE
	nop                                     ; nop
	jrl	t, 0x2a7f
	nop                                     ; nop
	jrl	z, 0x2a7f
	nop                                     ; nop
	jrl	ov, 0x2a7f
	nop                                     ; nop
	jrl	le, 0x2a7f
	nop                                     ; nop
	pop xix                                 ; pop XIX
	jrl	nc, 0x002a
	pop xde                                 ; pop XDE
	jrl	nc, 0x002a
	pop xwa                                 ; pop XWA
	jrl	nc, 0x002a
	.byte 0x56                             ; db
	jrl	nc, 0x002a
	.byte 0x54                             ; db
	jrl	nc, 0x002a
	popw wa                                 ; pop WA
	jrl nc, .LGD2_6ebe                     ; [7f 2a 00] jrl NC,0x2a6ebe
	push xix
	jrl nc, .LGD2_6ec2                     ; [7f 2a 00] jrl NC,0x2a6ec2
	pushw iz                                ; push IZ
	jrl	nc, 0x002a
	pushw ix                                ; push IX
	jrl nc, .LGD2_6eca                     ; [7f 2a 00] jrl NC,0x2a6eca
	pushw de                                ; push DE
	jrl nc, .LGD2_6ece                     ; [7f 2a 00] jrl NC,0x2a6ece
	.byte 0x1c, 0x7f, 0x2a                 ; call 0x2a7f
	nop                                     ; nop
	.byte 0x0c                             ; incf
	jrl	nc, 0x002a
	.byte 0xfc                             ; swi 4
	jrl	nz, 0x002a
	.byte 0xfa                             ; swi 2
	jrl	nz, 0x002a
	.byte 0xf8                             ; swi 0
	jrl nz, .LGD2_6ee2                     ; [7e 2a 00] jrl NZ,0x2a6ee2
	.byte 0xf6                             ; db
	jrl nz, .LGD2_6ee6                     ; [7e 2a 00] jrl NZ,0x2a6ee6
	.byte 0xea, 0x7e                       ; db
.LGD2_6ebe:
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xe8, 0x7e                       ; db
.LGD2_6ec2:
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xe6                             ; db
	jrl	nz, 0x002a
	scc16	nz, de
.LGD2_6eca:
	pushw de                                ; push DE
	nop                                     ; nop
	scc16	nz, wa
.LGD2_6ece:
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xd6                             ; db
	jrl	nz, 0x002a
	.byte 0xd4, 0x7e, 0x2a                 ; db
	nop                                     ; nop
	xorda16_24	wa, 0x002A7E
	jrl	nz, 0x002a
	scc8	nz, h
.LGD2_6ee2:
	pushw de                                ; push DE
	nop                                     ; nop
	scc8	nz, d
.LGD2_6ee6:
	pushw de                                ; push DE
	nop                                     ; nop
	xorcfa_rid8 xiz, 0x7e		; xorcf A,(XIZ+0x7e)
	nop                                     ; nop
	xorcfa_rid8 xix, 0x7e		; xorcf A,(XIX+0x7e)
	nop                                     ; nop
	ld_s	(xwa+126), xde
	nop                                     ; nop
	sllw_ri xde		; sllw (XDE)
	pushw de                                ; push DE
	nop                                     ; nop
	sllw_ri xwa		; sllw (XWA)
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xiz+126), b
	nop                                     ; nop
	ld_s	(xix+126), b
	nop                                     ; nop
	jrl	t, 0x2a7e
	nop                                     ; nop
	jrl	z, 0x2a7e
	nop                                     ; nop
	jrl	ov, 0x2a7e
	nop                                     ; nop
	jr gt, .LGD2_6f90                      ; [6a 7e] jr GT,0x2a6f90
	pushw de                                ; push DE
	nop                                     ; nop
	jr t, .LGD2_6f94                       ; [68 7e] jr T,0x2a6f94
	pushw de                                ; push DE
	nop                                     ; nop
	jr z, .LGD2_6f98                       ; [66 7e] jr Z,0x2a6f98
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x54                             ; db
	jrl	nz, 0x002a
	.byte 0x52                             ; db
	jrl	nz, 0x002a
	.byte 0x50                             ; db
	jrl	nz, 0x002a
	push xiz
	jrl	nz, 0x002a
	pushw iz                                ; push IZ
	jrl	nz, 0x002a
	calr	0x2a7e
	nop                                     ; nop
	.byte 0x1c, 0x7e, 0x2a                 ; call 0x2a7e
	nop                                     ; nop
	.byte 0x1a, 0x7e, 0x2a                 ; jp 0x2a7e
	nop                                     ; nop
	.byte 0x18                             ; push F
	jrl	nz, 0x002a
	.byte 0x16                             ; ex F,F'
	jrl	nz, 0x002a
	.byte 0x14                             ; push A
	jrl nz, .LGD2_6f72                     ; [7e 2a 00] jrl NZ,0x2a6f72
	.byte 0x12                             ; ccf
	jrl nz, .LGD2_6f76                     ; [7e 2a 00] jrl NZ,0x2a6f76
	.byte 0x10                             ; rcf
	jrl nz, .LGD2_6f7a                     ; [7e 2a 00] jrl NZ,0x2a6f7a
	ret

	jrl nz, .LGD2_6f7e                     ; [7e 2a 00] jrl NZ,0x2a6f7e
	.byte 0x0c                             ; incf
	jrl	nz, 0x002a
	ldwio	126, 42
	.byte 0xf8                             ; swi 0
	jrl	pl, 0x002a
	.byte 0xe6                             ; db
	jrl	pl, 0x002a
	.byte 0xe4, 0x7d, 0x2a                 ; db
	nop                                     ; nop
	or	xwa, (0x002a7d)
	jrl	pl, 0x002a
	scc8	pl, h
.LGD2_6f72:
	pushw de                                ; push DE
	nop                                     ; nop
	scc8	pl, d
.LGD2_6f76:
	pushw de                                ; push DE
	nop                                     ; nop
	scc8	pl, b
.LGD2_6f7a:
	pushw de                                ; push DE
	nop                                     ; nop
	scc8	pl, w
.LGD2_6f7e:
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xc6                             ; db
	jrl	pl, 0x002a
	.byte 0xc4, 0x7d, 0x2a                 ; db
	nop                                     ; nop
	sbcda8_24	b, 0x002A7D
	jrl	pl, 0x002a
.LGD2_6f90:
	.byte 0xb0, 0x7d                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
.LGD2_6f94:
	ld_s	(xiz+125), xde
	nop                                     ; nop
.LGD2_6f98:
	ld_s	(xix+125), xde
	nop                                     ; nop
	ld_s	(xde+125), xde
	nop                                     ; nop
	ld_s	(xwa+125), xde
	nop                                     ; nop
	.byte 0xa6, 0x7d                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xa4, 0x7d                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xa2, 0x7d                       ; db
.LGD2_6fae:
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xa0, 0x7d                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xiz+125), de
	nop                                     ; nop
	ld_s	(xix+125), de
	nop                                     ; nop
	ld_s	(xde+125), de
	nop                                     ; nop
	ld_s	(xwa+125), de
	nop                                     ; nop
	sraw_ri xiz		; sraw (XIZ)
	pushw de                                ; push DE
	nop                                     ; nop
	sraw_ri xix		; sraw (XIX)
	pushw de                                ; push DE
	nop                                     ; nop
	sraw_ri xde		; sraw (XDE)
	pushw de                                ; push DE
	nop                                     ; nop
	sraw_ri xwa		; sraw (XWA)
	pushw de                                ; push DE
	nop                                     ; nop
	sra_ri xde		; sra (XDE)
	pushw de                                ; push DE
	nop                                     ; nop
	sra_ri xwa		; sra (XWA)
	pushw de                                ; push DE
	nop                                     ; nop
	jrl	le, 0x2a7d
	nop                                     ; nop
	jr	ov, 0x7d
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x56                             ; db
	jrl	pl, 0x002a
	popw de                                 ; pop DE
	jrl	pl, 0x002a
	push xix
	jrl	pl, 0x002a
	pushw iz                                ; push IZ
	jrl	pl, 0x002a
	ldb	b, 0x7d
	pushw de                                ; push DE
	nop                                     ; nop
	ldb	w, 0x7d
	pushw de                                ; push DE
	nop                                     ; nop
	calr	0x2a7d
	nop                                     ; nop
	.byte 0x1c, 0x7d, 0x2a                 ; call 0x2a7d
	nop                                     ; nop
	.byte 0x1a, 0x7d, 0x2a                 ; jp 0x2a7d
	nop                                     ; nop
	.byte 0x18                             ; push F
	jrl	pl, 0x002a
	.byte 0x16                             ; ex F,F'
	jrl	pl, 0x002a
	.byte 0x14                             ; push A
	jrl	pl, 0x002a
	.byte 0x12                             ; ccf
	jrl	pl, 0x002a
	.byte 0x10                             ; rcf
	jrl	pl, 0x002a
	ret

	jrl	pl, 0x002a
	.byte 0x0c                             ; incf
	jrl	pl, 0x002a
	ldwio	125, 42
	ldio	125, 42
	nop                                     ; nop
	.byte 0xfa                             ; swi 2
	jrl	nov, 0x002a
	.byte 0xf8                             ; swi 0
	jrl	nov, 0x002a
	.byte 0xf6                             ; db
	jrl	nov, 0x002a
	.byte 0xf4, 0x7c, 0x2a                 ; xorcf A,(-r7CL)
	nop                                     ; nop
	.byte 0xe4, 0x7c, 0x2a                 ; db
	nop                                     ; nop
	or	xwa, (0x002a7c)
	jrl	nov, 0x002a
	scc16	nov, iz
.LGD2_704a:
	pushw de                                ; push DE
	nop                                     ; nop
	scc16	nov, ix
.LGD2_704e:
	pushw de                                ; push DE
	nop                                     ; nop
	scc16	nov, de
	pushw de                                ; push DE
	nop                                     ; nop
	scc16	nov, wa
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xd6                             ; db
	jrl	nov, 0x002a
	.byte 0xd4, 0x7c, 0x2a                 ; db
.LGD2_705f:
	nop                                     ; nop
	xorda16_24	wa, 0x002A7C
	jrl	nov, 0x002a
	scc8	nov, h
	pushw de                                ; push DE
	nop                                     ; nop
	xorcfa_rid8 xde, 0x7c		; xorcf A,(XDE+0x7c)
	nop                                     ; nop
	ld_s	(xix+124), xde
	nop                                     ; nop
	ld_s	(xiz+124), de
	nop                                     ; nop
	ld_s	(xiz+124), b
	nop                                     ; nop
	ld_s	(xix+124), b
	nop                                     ; nop
	ld_s	(xde+124), b
	nop                                     ; nop
	ld_s	(xwa+124), b
	nop                                     ; nop
	jrl	t, 0x2a7c
	nop                                     ; nop
	jr t, .LGD2_710a                       ; [68 7c] jr T,0x2a710a
	pushw de                                ; push DE
	nop                                     ; nop
	jr z, .LGD2_710e                       ; [66 7c] jr Z,0x2a710e
.LGD2_7092:
	pushw de                                ; push DE
	nop                                     ; nop
	jr	ov, 0x7c
	pushw de                                ; push DE
	nop                                     ; nop
	jr le, .LGD2_7116                      ; [62 7c] jr LE,0x2a7116
	pushw de                                ; push DE
	nop                                     ; nop
	jr	f, 0x7c
	pushw de                                ; push DE
	nop                                     ; nop
	pop xiz                                 ; pop XIZ
	jrl	nov, 0x002a
	pop xix                                 ; pop XIX
	jrl	nov, 0x002a
	pop xde                                 ; pop XDE
	jrl	nov, 0x002a
	pop xwa                                 ; pop XWA
	jrl	nov, 0x002a
	.byte 0x56                             ; db
	jrl	nov, 0x002a
	.byte 0x54                             ; db
	jrl	nov, 0x002a
	.byte 0x52                             ; db
	jrl	nov, 0x002a
	.byte 0x50                             ; db
	jrl	nov, 0x002a
	ld	xde, 0x34002a7c
	jrl	nov, 0x002a
	ldb	h, 0x7c
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x18                             ; push F
	jrl	nov, 0x002a
	.byte 0x0c                             ; incf
	jrl	nov, 0x002a
	.byte 0xfe                             ; swi 6
	jrl	ugt, 0x002a
	.byte 0xf0, 0x7b, 0x2a                 ; xorcf A,(0x7b)
	nop                                     ; nop
	.byte 0xe4, 0x7b, 0x2a                 ; db
	nop                                     ; nop
	or	xwa, (0x002a7b)
	jrl ugt, .LGD2_7112                    ; [7b 2a 00] jrl UGT,0x2a7112
	scc16	ugt, iz
.LGD2_70ea:
	pushw de                                ; push DE
	nop                                     ; nop
	scc16	ugt, ix
	pushw de                                ; push DE
	nop                                     ; nop
	scc16	ugt, de
.LGD2_70f2:
	pushw de                                ; push DE
	nop                                     ; nop
	scc16	ugt, wa
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xd6                             ; db
	jrl	ugt, 0x002a
	.byte 0xd4, 0x7b, 0x2a                 ; db
	nop                                     ; nop
	xorda16_24	wa, 0x002A7B
	jrl	ugt, 0x002a
	scc8	ugt, h
.LGD2_710a:
	pushw de                                ; push DE
	nop                                     ; nop
	scc8	ugt, d
.LGD2_710e:
	pushw de                                ; push DE
	nop                                     ; nop
	scc8	ugt, b
.LGD2_7112:
	pushw de                                ; push DE
	nop                                     ; nop
	scc8	ugt, w
.LGD2_7116:
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xc6                             ; db
	jrl	ugt, 0x002a
	.byte 0xc4, 0x7b, 0x2a                 ; db
	nop                                     ; nop
	andda8_24	w, 0x002A7B
	jrl ugt, .LGD2_7152                    ; [7b 2a 00] jrl UGT,0x2a7152
	.byte 0xb2, 0x7b                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xb0, 0x7b                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xiz+123), xde
	nop                                     ; nop
	ld_s	(xix+123), de
	nop                                     ; nop
	rrw_ri xwa		; rrw (XWA)
	pushw de                                ; push DE
	nop                                     ; nop
	rr_ri xix		; rr (XIX)
	pushw de                                ; push DE
	nop                                     ; nop
	jrl	z, 0x2a7b
	nop                                     ; nop
	jrl	ov, 0x2a7b
	nop                                     ; nop
	jrl	le, 0x2a7b
	nop                                     ; nop
	jrl	f, 0x2a7b
	nop                                     ; nop
	jr nz, .LGD2_71cd                      ; [6e 7b] jr NZ,0x2a71cd
.LGD2_7152:
	pushw de                                ; push DE
	nop                                     ; nop
	jr	nov, 0x7b
	pushw de                                ; push DE
	nop                                     ; nop
	jr gt, .LGD2_71d5                      ; [6a 7b] jr GT,0x2a71d5
	pushw de                                ; push DE
	nop                                     ; nop
	jr	t, 0x7b
	pushw de                                ; push DE
	nop                                     ; nop
	jr	z, 0x7b
	pushw de                                ; push DE
	nop                                     ; nop
	pop xwa                                 ; pop XWA
	jrl	ugt, 0x002a
	.byte 0x56                             ; db
	jrl ugt, .LGD2_7196                    ; [7b 2a 00] jrl UGT,0x2a7196
	.byte 0x54                             ; db
	jrl ugt, .LGD2_719a                    ; [7b 2a 00] jrl UGT,0x2a719a
	ld	xix, 0x42002a7b
	jrl	ugt, 0x002a
	ld	xwa, 0x3e002a7b
	jrl	ugt, 0x002a
	push xix
	jrl	ugt, 0x002a
	push xde
	jrl	ugt, 0x002a
	push xwa
	jrl	ugt, 0x002a
	ldw	iz, 0x2a7b
	nop                                     ; nop
	ldw	ix, 0x2a7b
	nop                                     ; nop
	ldb	d, 0x7b
.LGD2_7196:
	pushw de                                ; push DE
	nop                                     ; nop
	ldb	b, 0x7b
.LGD2_719a:
	pushw de                                ; push DE
	nop                                     ; nop
	ldb	w, 0x7b
	pushw de                                ; push DE
	nop                                     ; nop
	calr	0x2a7b
	nop                                     ; nop
	.byte 0x1c, 0x7b, 0x2a                 ; call 0x2a7b
	nop                                     ; nop
	.byte 0x1a, 0x7b, 0x2a                 ; jp 0x2a7b
	nop                                     ; nop
	.byte 0x18                             ; push F
	jrl	ugt, 0x002a
	.byte 0x16                             ; ex F,F'
	jrl	ugt, 0x002a
	.byte 0x14                             ; push A
	jrl	ugt, 0x002a
	.byte 0x04                             ; max
	jrl	ugt, 0x002a
	.byte 0x02                             ; push SR
	jrl	ugt, 0x002a
	nop                                     ; nop
	jrl	ugt, 0x002a
	.byte 0xfe                             ; swi 6
	jrl gt, .LGD2_71f2                     ; [7a 2a 00] jrl GT,0x2a71f2
	.byte 0xfc                             ; swi 4
	jrl gt, .LGD2_71f6                     ; [7a 2a 00] jrl GT,0x2a71f6
	.byte 0xfa                             ; swi 2
.LGD2_71cd:
	jrl gt, .LGD2_71fa                     ; [7a 2a 00] jrl GT,0x2a71fa
	.byte 0xf8                             ; swi 0
.LGD2_71d1:
	jrl gt, .LGD2_71fe                     ; [7a 2a 00] jrl GT,0x2a71fe
	.byte 0xf6                             ; db
.LGD2_71d5:
	jrl	gt, 0x002a
	.byte 0xf4, 0x7a, 0x2a                 ; xorcf A,(-r7AL)
	nop                                     ; nop
	call_24	ov, 0x002A7A
	jrl	gt, 0x002a
	or	xwa, (0x002a7a)
	jrl gt, .LGD2_7216                     ; [7a 2a 00] jrl GT,0x2a7216
	.byte 0xd0, 0x7a, 0x2a                 ; db
	nop                                     ; nop
	scc8	gt, h
.LGD2_71f2:
	pushw de                                ; push DE
	nop                                     ; nop
	scc8	gt, d
.LGD2_71f6:
	pushw de                                ; push DE
	nop                                     ; nop
	scc8	gt, b
.LGD2_71fa:
	pushw de                                ; push DE
	nop                                     ; nop
	scc8	gt, w
.LGD2_71fe:
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xc6                             ; db
	jrl	gt, 0x002a
	.byte 0xc4, 0x7a, 0x2a                 ; db
	nop                                     ; nop
	sbcda8_24	b, 0x002A7A
	jrl gt, .LGD2_723a                     ; [7a 2a 00] jrl GT,0x2a723a
	.byte 0xa2, 0x7a                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xa0, 0x7a                       ; db
.LGD2_7216:
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xiz+122), de
	nop                                     ; nop
	ld_s	(xix+122), de
	nop                                     ; nop
	ld_s	(xiz+122), b
	nop                                     ; nop
	ld_s	(xix+122), b
	nop                                     ; nop
	ld_s	(xde+122), b
	nop                                     ; nop
	jrl	nov, 0x2a7a
	nop                                     ; nop
	jrl	gt, 0x2a7a
	nop                                     ; nop
	jr gt, .LGD2_72b0                      ; [6a 7a] jr GT,0x2a72b0
	pushw de                                ; push DE
	nop                                     ; nop
	jr t, .LGD2_72b4                       ; [68 7a] jr T,0x2a72b4
.LGD2_723a:
	pushw de                                ; push DE
	nop                                     ; nop
	jr z, .LGD2_72b8                       ; [66 7a] jr Z,0x2a72b8
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x56                             ; db
	jrl	gt, 0x002a
	.byte 0x54                             ; db
	jrl	gt, 0x002a
	.byte 0x52                             ; db
	jrl	gt, 0x002a
	.byte 0x50                             ; db
	jrl	gt, 0x002a
	popw iz                                 ; pop IZ
	jrl	gt, 0x002a
	popw ix                                 ; pop IX
	jrl	gt, 0x002a
	popw de                                 ; pop DE
	jrl gt, .LGD2_7286                     ; [7a 2a 00] jrl GT,0x2a7286
	popw wa                                 ; pop WA
	jrl gt, .LGD2_728a                     ; [7a 2a 00] jrl GT,0x2a728a
	ld	xiz, 0x44002a7a
	jrl gt, .LGD2_7292                     ; [7a 2a 00] jrl GT,0x2a7292
	ld	xde, 0x40002a7a
	jrl	gt, 0x002a
	ldw	wa, 0x2a7a
	nop                                     ; nop
	pushw iz                                ; push IZ
	jrl	gt, 0x002a
	pushw ix                                ; push IX
	jrl	gt, 0x002a
	pushw de                                ; push DE
	jrl gt, .LGD2_72aa                     ; [7a 2a 00] jrl GT,0x2a72aa
	pushw wa                                ; push WA
	jrl	gt, 0x002a
	ldb	h, 0x7a
.LGD2_7286:
	pushw de                                ; push DE
	nop                                     ; nop
	ldb	d, 0x7a
.LGD2_728a:
	pushw de                                ; push DE
	nop                                     ; nop
	ldb	b, 0x7a
	pushw de                                ; push DE
	nop                                     ; nop
	ldb	w, 0x7a
.LGD2_7292:
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x10                             ; rcf
	jrl gt, .LGD2_72c2                     ; [7a 2a 00] jrl GT,0x2a72c2
	ret

	jrl gt, .LGD2_72c6                     ; [7a 2a 00] jrl GT,0x2a72c6
	.byte 0x0c                             ; incf
	jrl gt, .LGD2_72ca                     ; [7a 2a 00] jrl GT,0x2a72ca
	ldwio	122, 42
	ldio	122, 42
	nop                                     ; nop
	ei 0x7a		; ei 0x7a
.LGD2_72aa:
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xf8                             ; swi 0
	jrl	ge, 0x002a
.LGD2_72b0:
	.byte 0xf6                             ; db
	jrl	ge, 0x002a
.LGD2_72b4:
	.byte 0xf4, 0x79, 0x2a                 ; xorcf A,(-r79L)
	nop                                     ; nop
.LGD2_72b8:
	.byte 0xf2, 0x79, 0x2a, 0x00, 0xf0     ; db
	jrl	ge, 0x002a
	.byte 0xee, 0x79                       ; db
.LGD2_72c2:
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xec, 0x79                       ; db
.LGD2_72c6:
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xea, 0x79                       ; db
.LGD2_72ca:
	pushw de                                ; push DE
	nop                                     ; nop
	scc16	ge, de
	pushw de                                ; push DE
	nop                                     ; nop
	scc16	ge, wa
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xd6                             ; db
	jrl	ge, 0x002a
	.byte 0xd4, 0x79, 0x2a                 ; db
	nop                                     ; nop
	andda16_24	iz, 0x002A79
	jrl	ge, 0x002a
	.byte 0xc4, 0x79, 0x2a                 ; db
	nop                                     ; nop
	andda8_24	w, 0x002A79
	jrl ge, .LGD2_731a                     ; [79 2a 00] jrl GE,0x2a731a
	xorcfa_rid8 xiz, 0x79		; xorcf A,(XIZ+0x79)
	nop                                     ; nop
	.byte 0xb0, 0x79                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xiz+121), xde
	nop                                     ; nop
	ld_s	(xix+121), xde
	nop                                     ; nop
	ld_s	(xde+121), xde
	nop                                     ; nop
	ld_s	(xwa+121), xde
	nop                                     ; nop
	ld_s	(xix+121), de
	nop                                     ; nop
	ld_s	(xde+121), de
	nop                                     ; nop
	ld_s	(xwa+121), de
	nop                                     ; nop
	rrcw_ri xiz		; rrcw (XIZ)
	pushw de                                ; push DE
	nop                                     ; nop
	rrcw_ri xix		; rrcw (XIX)
.LGD2_731a:
	pushw de                                ; push DE
	nop                                     ; nop
	rrc_ri xix		; rrc (XIX)
	pushw de                                ; push DE
	nop                                     ; nop
	rrc_ri xde		; rrc (XDE)
	pushw de                                ; push DE
	nop                                     ; nop
	rrc_ri xwa		; rrc (XWA)
	pushw de                                ; push DE
	nop                                     ; nop
	jrl	nz, 0x2a79
	nop                                     ; nop
	jrl	nov, 0x2a79
	nop                                     ; nop
	jr	nov, 0x79
	pushw de                                ; push DE
	nop                                     ; nop
	jr	gt, 0x79
	pushw de                                ; push DE
	nop                                     ; nop
	jr	t, 0x79
	pushw de                                ; push DE
	nop                                     ; nop
	jr	z, 0x79
	pushw de                                ; push DE
	nop                                     ; nop
	jr	ov, 0x79
	pushw de                                ; push DE
	nop                                     ; nop
	pop xwa                                 ; pop XWA
	jrl	ge, 0x002a
	.byte 0x56                             ; db
	jrl	ge, 0x002a
	.byte 0x54                             ; db
	jrl ge, .LGD2_737a                     ; [79 2a 00] jrl GE,0x2a737a
	.byte 0x52                             ; db
	jrl ge, .LGD2_737e                     ; [79 2a 00] jrl GE,0x2a737e
	.byte 0x50                             ; db
	jrl ge, .LGD2_7382                     ; [79 2a 00] jrl GE,0x2a7382
	ld	xix, 0x42002a79
	jrl	ge, 0x002a
	ld	xwa, 0x3e002a79
	jrl	ge, 0x002a
	push xix
	jrl	ge, 0x002a
	pushw ix                                ; push IX
	jrl	ge, 0x002a
	pushw de                                ; push DE
	jrl	ge, 0x002a
	pushw wa                                ; push WA
	jrl	ge, 0x002a
	ldb	h, 0x79
.LGD2_737a:
	pushw de                                ; push DE
	nop                                     ; nop
	ldb	d, 0x79
.LGD2_737e:
	pushw de                                ; push DE
	nop                                     ; nop
	ldb	b, 0x79
.LGD2_7382:
	pushw de                                ; push DE
	nop                                     ; nop
	ldb	w, 0x79
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x14                             ; push A
	jrl	ge, 0x002a
	.byte 0x12                             ; ccf
	jrl	ge, 0x002a
	.byte 0x10                             ; rcf
	jrl	ge, 0x002a
	ret

	jrl	ge, 0x002a
	.byte 0x0c                             ; incf
	jrl	ge, 0x002a
	ldwio	121, 42
	ldio	121, 42
	nop                                     ; nop
	ei 0x79		; ei 0x79
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x04                             ; max
	jrl ge, .LGD2_73d6                     ; [79 2a 00] jrl GE,0x2a73d6
	.byte 0x02                             ; push SR
	jrl ge, .LGD2_73da                     ; [79 2a 00] jrl GE,0x2a73da
	nop                                     ; nop
	jrl ge, .LGD2_73de                     ; [79 2a 00] jrl GE,0x2a73de
	.byte 0xfe                             ; swi 6
	jrl	t, 0x002a
	.byte 0xfc                             ; swi 4
	jrl	t, 0x002a
	.byte 0xfa                             ; swi 2
	jrl	t, 0x002a
	.byte 0xf8                             ; swi 0
	jrl t, .LGD2_73ee                      ; [78 2a 00] jrl T,0x2a73ee
	.byte 0xf6                             ; db
	jrl	t, 0x002a
	.byte 0xf4, 0x78, 0x2a                 ; xorcf A,(-r78L)
	nop                                     ; nop
	.byte 0xf2, 0x78, 0x2a, 0x00, 0xf0     ; db
	jrl t, .LGD2_73fe                      ; [78 2a 00] jrl T,0x2a73fe
	scc16	t, iz
.LGD2_73d6:
	pushw de                                ; push DE
	nop                                     ; nop
	scc16	t, ix
.LGD2_73da:
	pushw de                                ; push DE
	nop                                     ; nop
	scc16	t, de
.LGD2_73de:
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xd0, 0x78, 0x2a                 ; db
	nop                                     ; nop
	sbcda8_24	b, 0x002A78
	jrl t, .LGD2_7416                      ; [78 2a 00] jrl T,0x2a7416
	.byte 0xb0, 0x78                       ; db
.LGD2_73ee:
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xiz+120), xde
	nop                                     ; nop
	ld_s	(xix+120), xde
	nop                                     ; nop
	.byte 0xa2, 0x78                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	rlcw_ri xix		; rlcw (XIX)
.LGD2_73fe:
	pushw de                                ; push DE
	nop                                     ; nop
	rlc_ri xix		; rlc (XIX)
	pushw de                                ; push DE
	nop                                     ; nop
	rlc_ri xde		; rlc (XDE)
	pushw de                                ; push DE
	nop                                     ; nop
	rlc_ri xwa		; rlc (XWA)
	pushw de                                ; push DE
	nop                                     ; nop
	jrl	nz, 0x2a78
	nop                                     ; nop
	jr	nz, 0x78
	pushw de                                ; push DE
	nop                                     ; nop
	jr	nov, 0x78
.LGD2_7416:
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x56                             ; db
	jrl	t, 0x002a
	.byte 0x54                             ; db
	jrl	t, 0x002a
	.byte 0x52                             ; db
	jrl	t, 0x002a
	.byte 0x50                             ; db
	jrl	t, 0x002a
	ld	xwa, 0x3e002a78
	jrl t, .LGD2_745a                      ; [78 2a 00] jrl T,0x2a745a
	pushw wa                                ; push WA
	jrl t, .LGD2_745e                      ; [78 2a 00] jrl T,0x2a745e
	ldb	h, 0x78
	pushw de                                ; push DE
	nop                                     ; nop
	ldb	d, 0x78
	pushw de                                ; push DE
	nop                                     ; nop
	ldb	b, 0x78
	pushw de                                ; push DE
	nop                                     ; nop
	ldb	w, 0x78
	pushw de                                ; push DE
	nop                                     ; nop
	ret

	jrl	t, 0x002a
	.byte 0x0c                             ; incf
	jrl t, .LGD2_7476                      ; [78 2a 00] jrl T,0x2a7476
	.byte 0xf4, 0x77, 0x2a                 ; xorcf A,(-r77L)
	nop                                     ; nop
	.byte 0xf2, 0x77, 0x2a, 0x00, 0xf0     ; db
	jrl	c, 0x002a
	.byte 0xee, 0x77                       ; db
.LGD2_745a:
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xec, 0x77                       ; db
.LGD2_745e:
	pushw de                                ; push DE
	nop                                     ; nop
	scc16 c, iz		; scc C,IZ
	pushw de                                ; push DE
	nop                                     ; nop
	scc8 c, b		; scc C,B
	pushw de                                ; push DE
	nop                                     ; nop
	scc8 c, w		; scc C,W
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xc6                             ; db
	jrl	c, 0x002a
	.byte 0xc4, 0x77, 0x2a                 ; db
	nop                                     ; nop
	.byte 0xb4, 0x77                       ; db
.LGD2_7476:
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xiz+119), de
	nop                                     ; nop
	ld_s	(xix+119), de
	nop                                     ; nop
	ld_s	(xde+119), de
	nop                                     ; nop
	ld_s	(xwa+119), de
	nop                                     ; nop
	ld_s	(xiz+119), b
	nop                                     ; nop
	ld_s	(xix+119), b
	nop                                     ; nop
	ld_s	(xde+119), b
	nop                                     ; nop
	jrl	nov, 0x2a77
	nop                                     ; nop
	jrl	gt, 0x2a77
	nop                                     ; nop
	jr	z, 0x77
	pushw de                                ; push DE
	nop                                     ; nop
	jr	ov, 0x77
	pushw de                                ; push DE
	nop                                     ; nop
	jr	le, 0x77
	pushw de                                ; push DE
	nop                                     ; nop
	jr	f, 0x77
	pushw de                                ; push DE
	nop                                     ; nop
	pop xiz                                 ; pop XIZ
	jrl	c, 0x002a
	popw iz                                 ; pop IZ
	jrl	c, 0x002a
	popw ix                                 ; pop IX
	jrl	c, 0x002a
	ldw	iz, 0x2a77
	nop                                     ; nop
	ldw	ix, 0x2a77
	nop                                     ; nop
	ldw	de, 0x2a77
	nop                                     ; nop
	ldw	wa, 0x2a77
	nop                                     ; nop
	pushw iz                                ; push IZ
	jrl	c, 0x002a
	calr	0x2a77
	nop                                     ; nop
	.byte 0x1c, 0x77, 0x2a                 ; call 0x2a77
	nop                                     ; nop
	.byte 0x1a, 0x77, 0x2a                 ; jp 0x2a77
	nop                                     ; nop
	.byte 0x18                             ; push F
	jrl	c, 0x002a
	.byte 0x16                             ; ex F,F'
	jrl	c, 0x002a
	.byte 0x14                             ; push A
	jrl	c, 0x002a
	ei 0x77		; ei 0x77
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x04                             ; max
	jrl c, .LGD2_7516                      ; [77 2a 00] jrl C,0x2a7516
	.byte 0x02                             ; push SR
	jrl c, .LGD2_751a                      ; [77 2a 00] jrl C,0x2a751a
	nop                                     ; nop
	jrl c, .LGD2_751e                      ; [77 2a 00] jrl C,0x2a751e
	.byte 0xfe                             ; swi 6
	jrl z, .LGD2_7522                      ; [76 2a 00] jrl Z,0x2a7522
	.byte 0xfc                             ; swi 4
	jrl	z, 0x002a
	.byte 0xfa                             ; swi 2
	jrl	z, 0x002a
	.byte 0xf8                             ; swi 0
	jrl	z, 0x002a
	.byte 0xf6                             ; db
	jrl	z, 0x002a
	.byte 0xf4, 0x76, 0x2a                 ; xorcf A,(-r76L)
	nop                                     ; nop
	.byte 0xf2, 0x76, 0x2a, 0x00, 0xf0     ; db
	jrl z, .LGD2_753e                      ; [76 2a 00] jrl Z,0x2a753e
	.byte 0xee, 0x76                       ; db
.LGD2_7516:
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xec, 0x76                       ; db
.LGD2_751a:
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xea, 0x76                       ; db
.LGD2_751e:
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xe8, 0x76                       ; db
.LGD2_7522:
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xe6                             ; db
	jrl	z, 0x002a
	.byte 0xe4, 0x76, 0x2a                 ; db
	nop                                     ; nop
	or	xwa, (0x002a76)
	jrl	z, 0x002a
	scc16 z, iz		; scc Z,IZ
	pushw de                                ; push DE
	nop                                     ; nop
	scc16 z, ix		; scc Z,IX
	pushw de                                ; push DE
	nop                                     ; nop
	scc16 z, de		; scc Z,DE
.LGD2_753e:
	pushw de                                ; push DE
	nop                                     ; nop
	scc16 z, wa		; scc Z,WA
	pushw de                                ; push DE
	nop                                     ; nop
	scc8 z, d		; scc Z,D
	pushw de                                ; push DE
	nop                                     ; nop
	scc8 z, b		; scc Z,B
	pushw de                                ; push DE
	nop                                     ; nop
	scc8 z, w		; scc Z,W
	pushw de                                ; push DE
	nop                                     ; nop
	xorcfa_rid8 xiz, 0x76		; xorcf A,(XIZ+0x76)
	nop                                     ; nop
	xorcfa_rid8 xix, 0x76		; xorcf A,(XIX+0x76)
	nop                                     ; nop
	.byte 0xb2, 0x76                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xwa+118), xde
	nop                                     ; nop
	ld_s	(xiz+118), de
	nop                                     ; nop
	.byte 0x94, 0x76                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	ld_s	(xde+118), b
	nop                                     ; nop
	.byte 0x80, 0x76                       ; db
	pushw de                                ; push DE
	nop                                     ; nop
	jrl	z, 0x2a76
	nop                                     ; nop
	jr	nov, 0x76
	pushw de                                ; push DE
	nop                                     ; nop
	jr le, .LGD2_75f0                      ; [62 76] jr LE,0x2a75f0
	pushw de                                ; push DE
	nop                                     ; nop
	jr f, .LGD2_75f4                       ; [60 76] jr F,0x2a75f4
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x52                             ; db
	jrl	z, 0x002a
	ld	xix, 0x34002a76
	jrl	z, 0x002a
	ldb	d, 0x76
	pushw de                                ; push DE
	nop                                     ; nop
	ldb	b, 0x76
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0x16                             ; ex F,F'
	jrl z, .LGD2_75c2                      ; [76 2a 00] jrl Z,0x2a75c2
	.byte 0x14                             ; push A
	jrl z, .LGD2_75c6                      ; [76 2a 00] jrl Z,0x2a75c6
	.byte 0x12                             ; ccf
	jrl z, .LGD2_75ca                      ; [76 2a 00] jrl Z,0x2a75ca
	.byte 0x10                             ; rcf
	jrl z, .LGD2_75ce                      ; [76 2a 00] jrl Z,0x2a75ce
	ret

	jrl	z, 0x002a
	.byte 0x04                             ; max
	jrl z, .LGD2_75d6                      ; [76 2a 00] jrl Z,0x2a75d6
	.byte 0x02                             ; push SR
	jrl z, .LGD2_75da                      ; [76 2a 00] jrl Z,0x2a75da
	nop                                     ; nop
	jrl z, .LGD2_75de                      ; [76 2a 00] jrl Z,0x2a75de
	.byte 0xf4, 0x75, 0x2a                 ; xorcf A,(-r75L)
	nop                                     ; nop
	.byte 0xf2, 0x75, 0x2a, 0x00, 0xf0     ; db
	jrl	mi, 0x002a
	.byte 0xee, 0x75                       ; db
.LGD2_75c2:
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xec, 0x75                       ; db
.LGD2_75c6:
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xea, 0x75                       ; db
.LGD2_75ca:
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xe8, 0x75                       ; db
.LGD2_75ce:
	pushw de                                ; push DE
	nop                                     ; nop
	.byte 0xe6                             ; db
	jrl	mi, 0x002a
	scc16 mi, iz		; scc M/MI,IZ
.LGD2_75d6:
	pushw de                                ; push DE
	nop                                     ; nop
	scc16 mi, ix		; scc M/MI,IX
.LGD2_75da:
	pushw de                                ; push DE
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
.LGD2_75de:
	.byte 0x57                             ; db
	jrl	le, 0x7469
	jr	mi, 0x49
	jr nz, .LGD2_75e6                      ; [6e 00] jr NZ,0x2a75e6
.LGD2_75e6:
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
.LGD2_75ea:
	nop                                     ; nop
	nop                                     ; nop
.LGD2_75ec:
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
.LGD2_75f0:
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
.LGD2_75f4:
	popw ix                                 ; pop IX
	jrl	ge, 0x5372
	jr	mi, 0x74
	jrl	ov, 0x6e69
	jr	c, 0x73
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xiz, 0x4c505f44
	ld	xiy, 0x00455341
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	popw ix                                 ; pop IX
	jr	nc, 0x61
	jr	ov, 0x4c
	jrl	ge, 0x6972
	jr	ule, 0x46
	ld	xix, 0x54000000
	jr ge, .LGD2_7694                      ; [69 6d] jr GE,0x2a7694
	jr	mi, 0x53
	jr	ge, 0x67
	popw bc                                 ; pop BC
	jr	nz, 0x4c
	jrl	ge, 0x6972
	jr ule, .LGD2_7633                     ; [63 00] jr ULE,0x2a7633
.LGD2_7633:
	nop                                     ; nop
	popw iy                                 ; pop IY
	jr	mi, 0x61
	jrl	ule, 0x7275
	jr	mi, 0x69
	jr nz, .LGD2_768a                      ; [6e 4c] jr NZ,0x2a768a
	jrl	ge, 0x6972
	jr ule, .LGD2_7643                     ; [63 00] jr ULE,0x2a7643
.LGD2_7643:
	nop                                     ; nop
	.byte 0x54                             ; db
	jr	mi, 0x6d
	jrl	f, 0x696f
	jr	nz, 0x4c
	jrl	ge, 0x6972
	jr ule, .LGD2_7651                     ; [63 00] jr ULE,0x2a7651
.LGD2_7651:
	nop                                     ; nop
	ld	xhl, 0x64726f68
	jr ge, .LGD2_76c7                      ; [69 6e] jr GE,0x2a76c7
	popw ix                                 ; pop IX
	jrl	ge, 0x6972
	jr ule, .LGD2_765f                     ; [63 00] jr ULE,0x2a765f
.LGD2_765f:
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	jr le, .LGD2_76d3                      ; [62 6f] jr LE,0x2a76d3
	jrl	ov, 0x6f74
.LGD2_7667:
	jr	pl, 0x30
	push xwa
	nop                                     ; nop
	nop                                     ; nop
	jr le, .LGD2_76dd                      ; [62 6f] jr LE,0x2a76dd
.LGD2_766e:
	jrl	ov, 0x6f74
	jr	pl, 0x30
	.byte 0x37, 0x00, 0x00                 ; ld SP,0x0000
	jr le, .LGD2_76e7                      ; [62 6f] jr LE,0x2a76e7
	jrl	ov, 0x6f74
	jr	pl, 0x30
	ldw	iz, 0x0000
	jr le, .LGD2_76f1                      ; [62 6f] jr LE,0x2a76f1
	jrl	ov, 0x6f74
	jr	pl, 0x30
	ldw	iy, 0x0000
.LGD2_768a:
	jr le, .LGD2_76fb                      ; [62 6f] jr LE,0x2a76fb
	jrl	ov, 0x6f74
	jr	pl, 0x30
	ldw	ix, 0x0000
.LGD2_7694:
	jr le, .LGD2_7705                      ; [62 6f] jr LE,0x2a7705
	jrl	ov, 0x6f74
.LGD2_7699:
	jr	pl, 0x30
	ldw	hl, 0x0000
	jr	le, 0x6f
	jrl	ov, 0x6f74
.LGD2_76a3:
	jr	pl, 0x30
.LGD2_76a5:
	ldw	de, 0x0000
	jr le, .LGD2_7719                      ; [62 6f] jr LE,0x2a7719
	jrl	ov, 0x6f74
.LGD2_76ad:
	jr	pl, 0x30
	ldw	bc, 0x0000
	ld	xhl, 0x75646e6f
.LGD2_76b7:
	jr	ule, 0x74
	jr	nc, 0x72
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	.byte 0x53                             ; db
	jr nc, .LGD2_772f                      ; [6f 6e] jr NC,0x2a772f
.LGD2_76c1:
	jr c, .LGD2_7717                       ; [67 54] jr C,0x2a7717
	jr	ge, 0x74
	jr	nov, 0x65
.LGD2_76c7:
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
.LGD2_76cb:
	nop                                     ; nop
	.byte 0x54                             ; db
	jr	mi, 0x63
	jr t, .LGD2_7730                       ; [68 5f] jr T,0x2a7730
	jr	nov, 0x79
.LGD2_76d3:
	jrl	le, 0x6369
	jrl ule, .LGD2_76d9                    ; [73 00 00] jrl ULE,0x2a76d9
.LGD2_76d9:
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
.LGD2_76dd:
	nop                                     ; nop
	nop                                     ; nop
.LGD2_76df:
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
.LGD2_76e7:
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
.LGD2_76f1:
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
.LGD2_76fb:
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
.LGD2_7705:
	nop                                     ; nop
	ld	xiz, 0x5f454c49
	popw ix                                 ; pop IX
	.byte 0x4f                             ; pop SP
	ld	xbc, 0x5f415f44
	pop xde                                 ; pop XDE
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
.LGD2_7717:
	nop                                     ; nop
	nop                                     ; nop
.LGD2_7719:
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	.byte 0x53                             ; db
	ld	xiy, 0x5443454c
	pop xsp                                 ; pop XSP
	ld	xiz, 0x5f454c49
	ld	xbc, 0x00005a5f
.LGD2_772f:
	nop                                     ; nop
.LGD2_7730:
	nop                                     ; nop
	nop                                     ; nop
.LGD2_7732:
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xbc, 0x4e494147
	pop xsp                                 ; pop XSP
	popw wa                                 ; pop WA
	ld	xix, 0x524f465f
	popw iy                                 ; pop IY
	ld	xbc, 0x41435f54
	.byte 0x54                             ; db
	ld	xhl, 0x00000048
	ld	xbc, 0x4e494147
	pop xsp                                 ; pop XSP
	popw wa                                 ; pop WA
	ld	xix, 0x524f465f
	popw iy                                 ; pop IY
	ld	xbc, 0x00000054
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xiy, 0x485f5252
	ld	xix, 0x524f465f
	popw iy                                 ; pop IY
	ld	xbc, 0x41435f54
	.byte 0x54                             ; db
	ld	xhl, 0x00000048
	ld	xiy, 0x485f5252
	ld	xix, 0x524f465f
	popw iy                                 ; pop IY
	ld	xbc, 0x00000054
	nop                                     ; nop
	nop                                     ; nop
	popw wa                                 ; pop WA
	ld	xix, 0x454c505f
	ld	xbc, 0x00004553
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xiz, 0x5f454c49
	.byte 0x4f                             ; pop SP
	.byte 0x55                             ; db
	.byte 0x54                             ; db
	pop xsp                                 ; pop XSP
	.byte 0x52                             ; db
	ld	xbc, 0x5f45474e
	ld	xhl, 0x48435441
	nop                                     ; nop
	nop                                     ; nop
	ld	xiz, 0x5f454c49
	.byte 0x4f                             ; pop SP
	.byte 0x55                             ; db
	.byte 0x54                             ; db
	pop xsp                                 ; pop XSP
	.byte 0x52                             ; db
	ld	xbc, 0x0045474e
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xix, 0x4f5f5249
	.byte 0x55                             ; db
	.byte 0x54                             ; db
	pop xsp                                 ; pop XSP
	.byte 0x52                             ; db
	ld	xbc, 0x5f45474e
	ld	xhl, 0x48435441
	nop                                     ; nop
	ld	xix, 0x4f5f5249
	.byte 0x55                             ; db
	.byte 0x54                             ; db
	pop xsp                                 ; pop XSP
	.byte 0x52                             ; db
	ld	xbc, 0x0045474e
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xbc, 0x4e455454
	pop xsp                                 ; pop XSP
	ld	xhl, 0x4e555f50
	popw iz                                 ; pop IZ
	ld	xbc, 0x5f44454d
	ld	xhl, 0x48435441
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xbc, 0x4e455454
	pop xsp                                 ; pop XSP
	ld	xhl, 0x4e555f50
	popw iz                                 ; pop IZ
	ld	xbc, 0x0044454d
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xbc, 0x4e455454
	pop xsp                                 ; pop XSP
	ld	xiz, 0x5f4c4c55
	ld	xix, 0x435f5249
	ld	xbc, 0x00484354
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xbc, 0x4e455454
	pop xsp                                 ; pop XSP
	ld	xiz, 0x5f4c4c55
	ld	xix, 0x00005249
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xiy, 0x4e5f5252
	.byte 0x4f                             ; pop SP
	pop xsp                                 ; pop XSP
	popw wa                                 ; pop WA
	popw hl                                 ; pop HL
	pop xsp                                 ; pop XSP
	ld	xix, 0x5f415441
	ld	xhl, 0x48435441
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xiy, 0x4e5f5252
	.byte 0x4f                             ; pop SP
	pop xsp                                 ; pop XSP
	popw wa                                 ; pop WA
	popw hl                                 ; pop HL
	pop xsp                                 ; pop XSP
	ld	xix, 0x00415441
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xiy, 0x4c5f5252
	.byte 0x4f                             ; pop SP
	ld	xbc, 0x41435f44
	.byte 0x54                             ; db
	ld	xhl, 0x45000048
	.byte 0x52                             ; db
	.byte 0x52                             ; db
	pop xsp                                 ; pop XSP
	popw ix                                 ; pop IX
	.byte 0x4f                             ; pop SP
	ld	xbc, 0x58455f44
	popw bc                                 ; pop BC
	.byte 0x54                             ; db
	nop                                     ; nop
	ld	xiy, 0x4c5f5252
	.byte 0x4f                             ; pop SP
	ld	xbc, 0x00000044
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xiy, 0x535f5252
	ld	xbc, 0x435f4556
	ld	xbc, 0x00484354
	nop                                     ; nop
	ld	xiy, 0x535f5252
	ld	xbc, 0x455f4556
	pop xwa                                 ; pop XWA
	popw bc                                 ; pop BC
	.byte 0x54                             ; db
	nop                                     ; nop
	ld	xiy, 0x535f5252
	ld	xbc, 0x00004556
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	.byte 0x57                             ; db
	ld	xbc, 0x545f5449
	.byte 0x52                             ; db
	ldw	wa, 0x525f
	ld	xiy, 0x45564f43
	.byte 0x52                             ; db
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xbc, 0x54554f42
	pop xsp                                 ; pop XSP
	popw wa                                 ; pop WA
	ld	xiy, 0x0000504c
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xbc, 0x4e455454
	pop xsp                                 ; pop XSP
	ld	xhl, 0x5f444650
	popw iy                                 ; pop IY
	ld	xbc, 0x00004b52
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xiy, 0x485f5252
	ld	xix, 0x4253465f
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xiy, 0x485f5252
	ld	xix, 0x5441465f
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xiy, 0x485f5252
	ld	xix, 0x4152545f
	ld	xhl, 0x00305f4b
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xiy, 0x485f5252
	ld	xix, 0x5f44495f
	.byte 0x52                             ; db
	ld	xiy, 0x00004441
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xiy, 0x485f5252
	ld	xix, 0x4145525f
	ld	xix, 0x00000000
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xiy, 0x485f5252
	ld	xix, 0x5345525f
	ld	xiy, 0x00000054
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xiy, 0x485f5252
	ld	xix, 0x4152535f
	popw iy                                 ; pop IY
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xiy, 0x485f5252
	ld	xix, 0x544f4e5f
	pop xsp                                 ; pop XSP
	ld	xiz, 0x0000544d
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xbc, 0x4e455454
	pop xsp                                 ; pop XSP
	ld	xhl, 0x5f444850
	.byte 0x57                             ; db
	.byte 0x52                             ; db
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	popw wa                                 ; pop WA
	ld	xix, 0x4c465f44
	.byte 0x53                             ; db
	pop xsp                                 ; pop XSP
	popw iz                                 ; pop IZ
	ld	xbc, 0x474e494d
	ldw	de, 0x0000
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xbc, 0x4e455454
	pop xsp                                 ; pop XSP
	.byte 0x4f                             ; pop SP
	.byte 0x56                             ; db
	ld	xiy, 0x49465f52
	popw ix                                 ; pop IX
	ld	xiy, 0x00000000
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xbc, 0x4e455454
	pop xsp                                 ; pop XSP
	ld	xix, 0x465f4c45
	popw ix                                 ; pop IX
	.byte 0x53                             ; db
	ldw	bc, 0x0000
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xix, 0x4d5f4742
	ld	xiy, 0x535f4f4d
	ld	xhl, 0x4e454552
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	popw wa                                 ; pop WA
	ld	xix, 0x464e495f
	.byte 0x4f                             ; pop SP
	pop xsp                                 ; pop XSP
	popw ix                                 ; pop IX
	popw bc                                 ; pop BC
	.byte 0x53                             ; db
	.byte 0x54                             ; db
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	.byte 0x53                             ; db
	ld	xiy, 0x5f505554
	popw wa                                 ; pop WA
	ld	xix, 0x4f464e49
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	.byte 0x57                             ; db
	ld	xbc, 0x485f5449
	ld	xix, 0x524f465f
	popw iy                                 ; pop IY
	ld	xbc, 0x48000054
	ld	xix, 0x524f465f
	popw iy                                 ; pop IY
	ld	xbc, 0x41435f54
	.byte 0x54                             ; db
	ld	xhl, 0x00000048
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xbc, 0x4e455454
	pop xsp                                 ; pop XSP
	popw wa                                 ; pop WA
	ld	xix, 0x524f465f
	popw iy                                 ; pop IY
	ld	xbc, 0x00000054
	nop                                     ; nop
	nop                                     ; nop
	.byte 0x57                             ; db
	ld	xbc, 0x445f5449
	ld	xiy, 0x49465f4c
	popw ix                                 ; pop IX
	ld	xiy, 0x00000000
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xbc, 0x4e455454
	pop xsp                                 ; pop XSP
	ld	xix, 0x465f4c45
	popw ix                                 ; pop IX
	.byte 0x53                             ; db
	ldw	de, 0x0000
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xbc, 0x4e455454
	pop xsp                                 ; pop XSP
	.byte 0x4f                             ; pop SP
	.byte 0x56                             ; db
	ld	xiy, 0x4c465f52
	.byte 0x53                             ; db
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xbc, 0x4e455454
	pop xsp                                 ; pop XSP
	ld	xix, 0x465f4c45
	popw bc                                 ; pop BC
	popw ix                                 ; pop IX
	ld	xiy, 0x00000000
	nop                                     ; nop
	nop                                     ; nop
	.byte 0x57                             ; db
	ld	xbc, 0x445f5449
	ld	xiy, 0x49445f4c
	.byte 0x52                             ; db
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xbc, 0x4e455454
	pop xsp                                 ; pop XSP
	ld	xix, 0x445f4c45
	popw bc                                 ; pop BC
	.byte 0x52                             ; db
	nop                                     ; nop
	popw bc                                 ; pop BC
	.byte 0x56                             ; db
	pop xsp                                 ; pop XSP
	popw wa                                 ; pop WA
	ld	xix, 0x4e454d44
	.byte 0x55                             ; db
	nop                                     ; nop
	nop                                     ; nop
	popw wa                                 ; pop WA
	ld	xix, 0x4e454d5f
	.byte 0x55                             ; db
	pop xsp                                 ; pop XSP
	ld	xde, 0x4800504d
	ld	xix, 0x43495f44
	.byte 0x4f                             ; pop SP
	popw iz                                 ; pop IZ
	pop xsp                                 ; pop XSP
	ld	xix, 0x4c505349
	ld	xbc, 0x00000059
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xix, 0x455f4c45
	ld	xix, 0x545f5449
	popw ix                                 ; pop IX
	pop xwa                                 ; pop XWA
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xix, 0x455f4c45
	ld	xix, 0x4d5f5449
	ld	xix, 0x4c454400
	pop xsp                                 ; pop XSP
	ld	xiy, 0x5f544944
	.byte 0x52                             ; db
	ld	xhl, 0x4400004d
	ld	xiy, 0x44455f4c
	popw bc                                 ; pop BC
	.byte 0x54                             ; db
	pop xsp                                 ; pop XSP
	popw iy                                 ; pop IY
	.byte 0x53                             ; db
	.byte 0x50                             ; db
	nop                                     ; nop
	nop                                     ; nop
	ld	xix, 0x455f4c45
	ld	xix, 0x545f5449
	popw iy                                 ; pop IY
	nop                                     ; nop
	ld	xix, 0x455f4c45
	ld	xix, 0x435f5449
	popw iy                                 ; pop IY
	.byte 0x50                             ; db
	nop                                     ; nop
	nop                                     ; nop
	ld	xix, 0x455f4c45
	ld	xix, 0x535f5449
	.byte 0x51                             ; db
	.byte 0x54                             ; db
	nop                                     ; nop
	nop                                     ; nop
	ld	xix, 0x455f4c45
	ld	xix, 0x505f5449
	popw iy                                 ; pop IY
	.byte 0x54                             ; db
	nop                                     ; nop
	nop                                     ; nop
	ld	xix, 0x455f4c45
	ld	xix, 0x4c5f5449
	.byte 0x53                             ; db
	.byte 0x57                             ; db
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xiz, 0x5f454c49
	ld	xix, 0x535f4c45
	ld	xhl, 0x4e454552
	nop                                     ; nop
	popw wa                                 ; pop WA
	jr	ov, 0x64
	popw iz                                 ; pop IZ
	jr	lt, 0x6d
	jr ge, .LGD2_7cee                      ; [69 6e] jr GE,0x2a7cee
	jr c, .LGD2_7cce                       ; [67 4c] jr C,0x2a7cce
	jr	lt, 0x62
	jr	mi, 0x6c
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	popw wa                                 ; pop WA
	jr	ov, 0x64
	popw iz                                 ; pop IZ
	jr lt, .LGD2_7d01                      ; [61 6d] jr LT,0x2a7d01
	jr ge, .LGD2_7d04                      ; [69 6e] jr GE,0x2a7d04
	jr	c, 0x53
	jrl	ge, 0x626d
	jr nc, .LGD2_7d09                      ; [6f 6c] jr NC,0x2a7d09
	nop                                     ; nop
	popw wa                                 ; pop WA
	jr	ov, 0x64
	popw iz                                 ; pop IZ
	jr lt, .LGD2_7d11                      ; [61 6d] jr LT,0x2a7d11
	jr ge, .LGD2_7d14                      ; [69 6e] jr GE,0x2a7d14
	jr c, .LGD2_7d09                       ; [67 61] jr C,0x2a7d09
	jr le, .LGD2_7d0d                      ; [62 63] jr LE,0x2a7d0d
	nop                                     ; nop
	nop                                     ; nop
	popw wa                                 ; pop WA
	jr	ov, 0x64
	popw iz                                 ; pop IZ
	jr lt, .LGD2_7d1f                      ; [61 6d] jr LT,0x2a7d1f
	jr ge, .LGD2_7d22                      ; [69 6e] jr GE,0x2a7d22
	jr c, .LGD2_7cf7                       ; [67 41] jr C,0x2a7cf7
	ld	xde, 0x48000043
	jr	ov, 0x64
	popw iz                                 ; pop IZ
	jr	lt, 0x6d
	jr	ge, 0x6e
	jr c, .LGD2_7d07                       ; [67 43] jr C,0x2a7d07
	jrl	mi, 0x7372
	jr	nc, 0x72
	ld	xde, 0x0000786f
.LGD2_7cce:
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
.LGD2_7cdf:
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	popw wa                                 ; pop WA
	jr	ov, 0x64
	popw iz                                 ; pop IZ
	jr lt, .LGD2_7d57                      ; [61 6d] jr LT,0x2a7d57
	jr	ge, 0x6e
	jr c, .LGD2_7d45                       ; [67 57] jr C,0x2a7d45
.LGD2_7cee:
	jr ge, .LGD2_7d5e                      ; [69 6e] jr GE,0x2a7d5e
	jr	ov, 0x6f
.LGD2_7cf2:
	jrl c, .LGD2_7cf5                      ; [77 00 00] jrl C,0x2a7cf5
.LGD2_7cf5:
	nop                                     ; nop
	nop                                     ; nop
.LGD2_7cf7:
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	.byte 0x52                             ; db
	ld	xbc, 0x44455f4d
	popw bc                                 ; pop BC
.LGD2_7d01:
	.byte 0x54                             ; db
	pop xsp                                 ; pop XSP
	.byte 0x54                             ; db
.LGD2_7d04:
	popw ix                                 ; pop IX
.LGD2_7d05:
	pop xwa                                 ; pop XWA
	nop                                     ; nop
.LGD2_7d07:
	nop                                     ; nop
	nop                                     ; nop
.LGD2_7d09:
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
.LGD2_7d0d:
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
.LGD2_7d11:
	nop                                     ; nop
	nop                                     ; nop
.LGD2_7d13:
	nop                                     ; nop
.LGD2_7d14:
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
.LGD2_7d1f:
	nop                                     ; nop
	nop                                     ; nop
.LGD2_7d21:
	nop                                     ; nop
.LGD2_7d22:
	.byte 0x52                             ; db
	ld	xbc, 0x44455f4d
	popw bc                                 ; pop BC
	.byte 0x54                             ; db
	pop xsp                                 ; pop XSP
	popw iy                                 ; pop IY
	ld	xix, 0x4d415200
	pop xsp                                 ; pop XSP
	ld	xiy, 0x5f544944
	.byte 0x52                             ; db
	ld	xhl, 0x5200004d
	ld	xbc, 0x44455f4d
	popw bc                                 ; pop BC
	.byte 0x54                             ; db
	pop xsp                                 ; pop XSP
.LGD2_7d45:
	popw iy                                 ; pop IY
	.byte 0x53                             ; db
	.byte 0x50                             ; db
	nop                                     ; nop
	nop                                     ; nop
	.byte 0x52                             ; db
.LGD2_7d4b:
	ld	xbc, 0x44455f4d
	popw bc                                 ; pop BC
	.byte 0x54                             ; db
	pop xsp                                 ; pop XSP
	.byte 0x54                             ; db
	popw iy                                 ; pop IY
	nop                                     ; nop
	.byte 0x52                             ; db
.LGD2_7d57:
	ld	xbc, 0x44455f4d
	popw bc                                 ; pop BC
	.byte 0x54                             ; db
.LGD2_7d5e:
	pop xsp                                 ; pop XSP
	.byte 0x53                             ; db
	.byte 0x51                             ; db
.LGD2_7d61:
	.byte 0x54                             ; db
	nop                                     ; nop
	nop                                     ; nop
	.byte 0x52                             ; db
	ld	xbc, 0x44455f4d
	popw bc                                 ; pop BC
	.byte 0x54                             ; db
	pop xsp                                 ; pop XSP
	.byte 0x50                             ; db
	popw iy                                 ; pop IY
	.byte 0x54                             ; db
	nop                                     ; nop
	nop                                     ; nop
	.byte 0x52                             ; db
	ld	xbc, 0x44455f4d
	popw bc                                 ; pop BC
	.byte 0x54                             ; db
	pop xsp                                 ; pop XSP
	popw ix                                 ; pop IX
	.byte 0x53                             ; db
	.byte 0x57                             ; db
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	.byte 0x52                             ; db
	ld	xbc, 0x44455f4d
	popw bc                                 ; pop BC
	.byte 0x54                             ; db
	pop xsp                                 ; pop XSP
	ld	xhl, 0x0000504d
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	.byte 0x53                             ; db
	ld	xbc, 0x4f5f4556
	.byte 0x50                             ; db
	.byte 0x54                             ; db
	pop xsp                                 ; pop XSP
	.byte 0x53                             ; db
	ld	xhl, 0x4e454552
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xhl, 0x44465f50
	pop xsp                                 ; pop XSP
	ld	xix, 0x4e5f5249
	ld	xbc, 0x474e494d
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xiz, 0x455f534c
	ld	xix, 0x4f5f5449
	.byte 0x50                             ; db
	.byte 0x54                             ; db
	pop xsp                                 ; pop XSP
	ld	xde, 0x0000584f
	ld	xiz, 0x455f534c
	ld	xix, 0x4c5f5449
	.byte 0x4f                             ; pop SP
	ld	xhl, 0x584f425f
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xiz, 0x455f534c
	ld	xix, 0x4c5f5449
	popw bc                                 ; pop BC
	popw iz                                 ; pop IZ
	ld	xiy, 0x46000031
	popw ix                                 ; pop IX
	.byte 0x53                             ; db
	pop xsp                                 ; pop XSP
	ld	xiy, 0x5f544944
	popw ix                                 ; pop IX
	popw bc                                 ; pop BC
	popw iz                                 ; pop IZ
	ld	xiy, 0x46000032
	popw ix                                 ; pop IX
	.byte 0x53                             ; db
	pop xsp                                 ; pop XSP
	ld	xiy, 0x5f544944
	popw ix                                 ; pop IX
	popw bc                                 ; pop BC
	.byte 0x53                             ; db
	.byte 0x54                             ; db
	pop xsp                                 ; pop XSP
	ld	xde, 0x0000584f
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xiz, 0x455f534c
	ld	xix, 0x4e5f5449
	ld	xbc, 0x425f454d
	.byte 0x4f                             ; pop SP
	pop xwa                                 ; pop XWA
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xiz, 0x455f534c
	ld	xix, 0x00005449
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xiz, 0x465f534c
	popw bc                                 ; pop BC
	popw ix                                 ; pop IX
	ld	xiy, 0x4c45535f
	pop xsp                                 ; pop XSP
	.byte 0x4f                             ; pop SP
	.byte 0x50                             ; db
	.byte 0x54                             ; db
	ld	xde, 0x0000584f
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xiz, 0x465f534c
	popw bc                                 ; pop BC
	popw ix                                 ; pop IX
	ld	xiy, 0x4c45535f
	pop xsp                                 ; pop XSP
	popw ix                                 ; pop IX
	popw bc                                 ; pop BC
	.byte 0x53                             ; db
	.byte 0x54                             ; db
	ld	xde, 0x0000584f
	ld	xiz, 0x465f534c
	popw bc                                 ; pop BC
	popw ix                                 ; pop IX
	ld	xiy, 0x4c45535f
	pop xsp                                 ; pop XSP
	ld	xix, 0x4f425249
	pop xwa                                 ; pop XWA
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xiz, 0x465f534c
	popw bc                                 ; pop BC
	popw ix                                 ; pop IX
	ld	xiy, 0x4c45535f
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xiz, 0x445f534c
	popw bc                                 ; pop BC
	.byte 0x52                             ; db
	pop xsp                                 ; pop XSP
	ld	xde, 0x0000584f
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xiz, 0x445f534c
	popw bc                                 ; pop BC
	.byte 0x52                             ; db
	pop xsp                                 ; pop XSP
	.byte 0x53                             ; db
	ld	xiy, 0x0000004c
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xiz, 0x4c5f534c
	.byte 0x4f                             ; pop SP
	ld	xbc, 0x494c5f44
	popw iz                                 ; pop IZ
	ld	xiy, 0x46000032
	popw ix                                 ; pop IX
	.byte 0x53                             ; db
	pop xsp                                 ; pop XSP
	popw ix                                 ; pop IX
	.byte 0x4f                             ; pop SP
	ld	xbc, 0x494c5f44
	popw iz                                 ; pop IZ
	ld	xiy, 0x46000031
	popw ix                                 ; pop IX
	.byte 0x53                             ; db
	pop xsp                                 ; pop XSP
	ld	xiz, 0x5f454c49
	ld	xde, 0x0000584f
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xiz, 0x4e5f534c
	ld	xbc, 0x425f454d
	.byte 0x4f                             ; pop SP
	pop xwa                                 ; pop XWA
	nop                                     ; nop
	nop                                     ; nop
	ld	xiz, 0x4c5f534c
	.byte 0x4f                             ; pop SP
	ld	xhl, 0x584f425f
	nop                                     ; nop
	ld	xiz, 0x4f5f534c
	.byte 0x50                             ; db
	.byte 0x54                             ; db
	pop xsp                                 ; pop XSP
	ld	xde, 0x0000584f
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xiz, 0x465f534c
	popw bc                                 ; pop BC
	popw ix                                 ; pop IX
	ld	xiy, 0x414f4c5f
	ld	xix, 0x5f57535f
	ld	xiy, 0x00544944
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xiz, 0x465f534c
	popw bc                                 ; pop BC
	popw ix                                 ; pop IX
	ld	xiy, 0x414f4c5f
	ld	xix, 0x00000000
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	popw wa                                 ; pop WA
	ld	xix, 0x4c465f44
	.byte 0x53                             ; db
	pop xsp                                 ; pop XSP
	popw iz                                 ; pop IZ
	ld	xbc, 0x474e494d
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	popw wa                                 ; pop WA
	ld	xix, 0x4c49465f
	ld	xiy, 0x414f4c5f
	ld	xix, 0x0032505f
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	popw wa                                 ; pop WA
	ld	xix, 0x4c49465f
	ld	xiy, 0x414f4c5f
	ld	xix, 0x5f57535f
	ld	xix, 0x49464c45
	popw ix                                 ; pop IX
	ld	xiy, 0x00000000
	nop                                     ; nop
	popw wa                                 ; pop WA
	ld	xix, 0x4c49465f
	ld	xiy, 0x414f4c5f
	ld	xix, 0x5f57535f
	ld	xix, 0x00004c45
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xiz, 0x5f454c49
	popw ix                                 ; pop IX
	.byte 0x4f                             ; pop SP
	ld	xbc, 0x49445f44
	.byte 0x52                             ; db
	ld	xde, 0x0000584f
	popw wa                                 ; pop WA
	ld	xix, 0x4c49465f
	ld	xiy, 0x53494c5f
	.byte 0x54                             ; db
	nop                                     ; nop
	nop                                     ; nop
	popw wa                                 ; pop WA
	ld	xix, 0x4c49465f
	ld	xiy, 0x54504f5f
	popw bc                                 ; pop BC
	.byte 0x4f                             ; pop SP
	popw iz                                 ; pop IZ
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	popw wa                                 ; pop WA
	ld	xix, 0x4c49465f
	ld	xiy, 0x414f4c5f
	ld	xix, 0x5f57535f
	.byte 0x53                             ; db
	ld	xbc, 0x00004556
	popw wa                                 ; pop WA
	ld	xix, 0x4c49465f
	ld	xiy, 0x414f4c5f
	ld	xix, 0x0031505f
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	.byte 0x53                             ; db
	ld	xiy, 0x4c465f4c
	.byte 0x53                             ; db
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xiz, 0x535f534c
	ld	xiy, 0x5443454c
	pop xsp                                 ; pop XSP
	.byte 0x53                             ; db
	.byte 0x57                             ; db
	pop xsp                                 ; pop XSP
	ld	xiy, 0x00544944
	nop                                     ; nop
	ld	xiz, 0x535f534c
	ld	xiy, 0x0000004c
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xiz, 0x535f534c
	ld	xiy, 0x5443454c
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xhl, 0x44465f50
	pop xsp                                 ; pop XSP
	ld	xix, 0x4f425249
	pop xwa                                 ; pop XWA
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xhl, 0x44465f50
	pop xsp                                 ; pop XSP
	ld	xix, 0x45535249
	popw ix                                 ; pop IX
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xhl, 0x44465f50
	pop xsp                                 ; pop XSP
	popw wa                                 ; pop WA
	ld	xix, 0x534c4c41
	ld	xiy, 0x0000004c
	nop                                     ; nop
	ld	xhl, 0x44465f50
	pop xsp                                 ; pop XSP
	.byte 0x56                             ; db
	.byte 0x4f                             ; pop SP
	popw ix                                 ; pop IX
	popw ix                                 ; pop IX
	ld	xbc, 0x004c4542
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xhl, 0x44465f50
	pop xsp                                 ; pop XSP
	popw wa                                 ; pop WA
	ld	xix, 0x45535753
	popw ix                                 ; pop IX
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xhl, 0x44465f50
	pop xsp                                 ; pop XSP
	popw wa                                 ; pop WA
	ld	xix, 0x4f545753
	nop                                     ; nop
	nop                                     ; nop
	ld	xhl, 0x44465f50
	pop xsp                                 ; pop XSP
	popw ix                                 ; pop IX
	popw bc                                 ; pop BC
	popw iz                                 ; pop IZ
	ld	xiy, 0x50430031
	pop xsp                                 ; pop XSP
	ld	xiz, 0x494c5f44
	popw iz                                 ; pop IZ
	ld	xiy, 0x50430032
	pop xsp                                 ; pop XSP
	ld	xiz, 0x494c5f44
	.byte 0x53                             ; db
	.byte 0x54                             ; db
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xhl, 0x44465f50
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	popw ix                                 ; pop IX
	ld	xde, 0x32505f4e
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	popw ix                                 ; pop IX
	ld	xde, 0x49465f4e
	popw ix                                 ; pop IX
	ld	xiy, 0x454d414e
	pop xsp                                 ; pop XSP
	ld	xde, 0x0000584f
	popw ix                                 ; pop IX
	ld	xde, 0x49465f4e
	popw ix                                 ; pop IX
	ld	xiy, 0x425f4f4e
	.byte 0x4f                             ; pop SP
	pop xwa                                 ; pop XWA
	nop                                     ; nop
	nop                                     ; nop
	popw ix                                 ; pop IX
	ld	xde, 0x49445f4e
	.byte 0x52                             ; db
	popw iz                                 ; pop IZ
	ld	xbc, 0x425f454d
	.byte 0x4f                             ; pop SP
	pop xwa                                 ; pop XWA
	nop                                     ; nop
	popw ix                                 ; pop IX
	ld	xde, 0x49445f4e
	.byte 0x52                             ; db
	popw iz                                 ; pop IZ
	.byte 0x4f                             ; pop SP
	pop xsp                                 ; pop XSP
	ld	xde, 0x0000584f
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	popw ix                                 ; pop IX
	ld	xde, 0x504f5f4e
	.byte 0x54                             ; db
	popw bc                                 ; pop BC
	.byte 0x4f                             ; pop SP
	popw iz                                 ; pop IZ
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	popw ix                                 ; pop IX
	ld	xde, 0x31505f4e
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	popw ix                                 ; pop IX
	.byte 0x4f                             ; pop SP
	ld	xbc, 0x59425f44
	pop xsp                                 ; pop XSP
	popw iz                                 ; pop IZ
	.byte 0x55                             ; db
	popw iy                                 ; pop IY
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	.byte 0x4f                             ; pop SP
	.byte 0x55                             ; db
	.byte 0x54                             ; db
	.byte 0x50                             ; db
	.byte 0x55                             ; db
	.byte 0x54                             ; db
	pop xsp                                 ; pop XSP
	.byte 0x53                             ; db
	ld	xiy, 0x4e495454
	ld	xsp, 0x00000000
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	.byte 0x53                             ; db
	.byte 0x57                             ; db
	pop xsp                                 ; pop XSP
	popw wa                                 ; pop WA
	ld	xix, 0x524f465f
	popw iy                                 ; pop IY
	ld	xbc, 0x00000054
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	.byte 0x53                             ; db
	ld	xiy, 0x5f505554
	.byte 0x54                             ; db
	.byte 0x4f                             ; pop SP
	.byte 0x4f                             ; pop SP
	popw ix                                 ; pop IX
	.byte 0x53                             ; db
	pop xsp                                 ; pop XSP
	.byte 0x50                             ; db
	ldw	de, 0x0000
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	.byte 0x53                             ; db
	ld	xiy, 0x5f505554
	.byte 0x54                             ; db
	.byte 0x4f                             ; pop SP
	.byte 0x4f                             ; pop SP
	popw ix                                 ; pop IX
	.byte 0x53                             ; db
	pop xsp                                 ; pop XSP
	.byte 0x50                             ; db
	ldw	bc, 0x0000
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	.byte 0x50                             ; db
	.byte 0x50                             ; db
	pop xsp                                 ; pop XSP
	.byte 0x53                             ; db
	.byte 0x54                             ; db
	ld	xbc, 0x00535554
	nop                                     ; nop
	nop                                     ; nop
	.byte 0x50                             ; db
	ld	xhl, 0x5441445f
	ld	xbc, 0x4e494c5f
	popw hl                                 ; pop HL
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	popw wa                                 ; pop WA
	ld	xix, 0x4954555f
	popw ix                                 ; pop IX
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	popw wa                                 ; pop WA
	ld	xix, 0x454c505f
	ld	xbc, 0x575f4553
	popw bc                                 ; pop BC
	popw iz                                 ; pop IZ
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	popw wa                                 ; pop WA
	ld	xix, 0x49445f44
	.byte 0x52                             ; db
	pop xsp                                 ; pop XSP
	popw iz                                 ; pop IZ
	ld	xbc, 0x474e494d
	nop                                     ; nop
	nop                                     ; nop
	popw wa                                 ; pop WA
	ld	xix, 0x4c49465f
	ld	xiy, 0x4d414e5f
	ld	xiy, 0x00000000
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	popw wa                                 ; pop WA
	ld	xix, 0x49465f44
	popw ix                                 ; pop IX
	ld	xiy, 0x4d414e5f
	popw bc                                 ; pop BC
	popw iz                                 ; pop IZ
	ld	xsp, 0x44444800
	pop xsp                                 ; pop XSP
	.byte 0x53                             ; db
	.byte 0x57                             ; db
	nop                                     ; nop
	nop                                     ; nop
	ld	xiz, 0x57535f44
	nop                                     ; nop
	.byte 0x50                             ; db
	.byte 0x50                             ; db
	.byte 0x4f                             ; pop SP
	.byte 0x52                             ; db
	.byte 0x54                             ; db
	pop xsp                                 ; pop XSP
	.byte 0x53                             ; db
	.byte 0x57                             ; db
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	.byte 0x52                             ; db
	.byte 0x55                             ; db
	popw iz                                 ; pop IZ
	pop xsp                                 ; pop XSP
	.byte 0x53                             ; db
	.byte 0x54                             ; db
	.byte 0x4f                             ; pop SP
	.byte 0x50                             ; db
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	popw wa                                 ; pop WA
	ld	xbc, 0x545f4452
	ld	xiy, 0x00005453
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	ld	xiz, 0x49465f44
	popw ix                                 ; pop IX
	ld	xiy, 0x4c45535f
	ld	xiy, 0x00005443
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	.byte 0x53                             ; db
	ld	xiy, 0x5443454c
	pop xsp                                 ; pop XSP
	ld	xix, 0x00325249
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	.byte 0x53                             ; db
	ld	xiy, 0x5443454c
	pop xsp                                 ; pop XSP
	ld	xix, 0x535f5249
	.byte 0x57                             ; db
	pop xsp                                 ; pop XSP
	ld	xiy, 0x00544944
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	.byte 0x53                             ; db
	ld	xiy, 0x49445f4c
	.byte 0x52                             ; db
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	.byte 0x53                             ; db
	ld	xiy, 0x5443454c
	pop xsp                                 ; pop XSP
	ld	xix, 0x00005249
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	popw wa                                 ; pop WA
	ld	xix, 0x414f4c5f
	ld	xix, 0x54504f5f
	popw bc                                 ; pop BC
	.byte 0x4f                             ; pop SP
	popw iz                                 ; pop IZ
	nop                                     ; nop
	nop                                     ; nop
	popw wa                                 ; pop WA
	ld	xix, 0x4c49465f
	ld	xiy, 0x414f4c5f
	ld	xix, 0x00000000
	.byte 0x53                             ; db
	ld	xiy, 0x5443454c
	pop xsp                                 ; pop XSP
	ld	xiz, 0x00454c49
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	.byte 0x53                             ; db
	ld	xiy, 0x53505554
	pop xsp                                 ; pop XSP
	.byte 0x54                             ; db
	.byte 0x4f                             ; pop SP
	.byte 0x4f                             ; pop SP
	popw ix                                 ; pop IX
	.byte 0x53                             ; db
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	popw wa                                 ; pop WA
	ld	xbc, 0x445f4452
	popw bc                                 ; pop BC
	.byte 0x53                             ; db
	popw hl                                 ; pop HL
	pop xsp                                 ; pop XSP
	.byte 0x4f                             ; pop SP
	.byte 0x50                             ; db
	.byte 0x54                             ; db
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	nop                                     ; nop
	popw wa                                 ; pop WA
	ld	xix, 0x4e454d44
	.byte 0x55                             ; db
	nop                                     ; nop


HDAE5000_GFX_INIT_PARAMS:	; 0x2A849A
	; Graphics initialization parameters
	.incbin "includes/code_29af2d_2fffff.bin", 54637, 72972

HDAE5000_Font_Data:	; 0x2BA1A6
	; Font bitmap data (large block)
	.incbin "includes/code_29af2d_2fffff.bin", 127609, 162524

HDAE5000_Config_Strings:	; 0x2E1C82
	; Configuration and version strings
	.asciz "V2.06i"
	.zero 3
	.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
	.zero 23
	.ascii "   "
	.byte 0x09
	.zero 2
	.ascii "                "
	.byte 0x09
	.byte 0x00
	.ascii "   "
	.byte 0x09
	.zero 2
	.ascii "                          "
	.byte 0x09
	.byte 0x00
	.ascii "            "
	.byte 0x09
	.byte 0x00
	.ascii "01:        "
	.byte 0x09
	.ascii "02:        "
	.byte 0x09
	.ascii "03:        "
	.byte 0x09
	.ascii "04:        "
	.byte 0x09
	.ascii "05:        "
	.byte 0x09
	.ascii "06:        "
	.byte 0x09
	.ascii "07:        "
	.byte 0x09
	.ascii "08:        "
	.byte 0x09
	.ascii "09:        "
	.byte 0x09
	.ascii "10:        "
	.byte 0x09
	.ascii "11:        "
	.byte 0x09
	.ascii "12:        "
	.byte 0x09
	.ascii "13:        "
	.byte 0x09
	.ascii "14:        "
	.byte 0x09
	.ascii "15:        "
	.byte 0x09
	.ascii "16:        "
	.byte 0x09
	.ascii "17:        "
	.byte 0x09
	.ascii "18:        "
	.byte 0x09
	.ascii "19:        "
	.byte 0x09
	.ascii "20:        "
	.byte 0x09
	.zero 2
	.ascii "STATUS:                        "
	.byte 0x09
	.zero 14
	.ascii "("
	.byte 0x1e
	.asciz "."
	.ascii "$"
	.byte 0x1e
	.asciz "."
	.ascii " "
	.byte 0x1e
	.asciz "."
	.asciz "DEL"
	.asciz "OFF"
	.asciz "---"
	.asciz "050354"
	.byte 0x00
	.asciz "965768"
	.byte 0x00
	popw wa
	.byte 0x1e
	.asciz "."
	.ascii "D"
	.byte 0x1e
	.asciz "."
	.asciz "ON "
	.asciz "OFF"
	.ascii "P"
	.byte 0x1e
	.asciz "."
	.ascii "01:SelectList"
	.byte 0x09
	.byte 0x30, 0x32
	.byte 0x09
	.byte 0x30, 0x33
	.byte 0x09
	.byte 0x30, 0x34
	.byte 0x09
	.byte 0x30, 0x35
	.byte 0x09
	.byte 0x30, 0x36
	.byte 0x09
	.byte 0x30, 0x37
	.byte 0x09
	.byte 0x30, 0x38
	.byte 0x09
	.byte 0x30, 0x39
	.byte 0x09
	.byte 0x31, 0x30
	.byte 0x09
	.byte 0x31, 0x31
	.byte 0x09
	.byte 0x31, 0x32
	.byte 0x09
	.byte 0x31, 0x33
	.byte 0x09
	.byte 0x31, 0x34
	.byte 0x09
	.byte 0x31, 0x35
	.byte 0x09
	.byte 0x31, 0x36
	.byte 0x09
	.byte 0x31, 0x37
	.byte 0x09
	.byte 0x31, 0x38
	.byte 0x09
	.byte 0x31, 0x39
	.byte 0x09
	.byte 0x32, 0x30
	.byte 0x09
	.byte 0x32, 0x31
	.byte 0x09
	.byte 0x32, 0x32
	.byte 0x09
	.byte 0x32, 0x33
	.byte 0x09
	.byte 0x32, 0x34
	.byte 0x09
	.byte 0x32, 0x35
	.byte 0x09
	.byte 0x32, 0x36
	.byte 0x09
	.byte 0x32, 0x37
	.byte 0x09
	.byte 0x32, 0x38
	.byte 0x09
	.byte 0x32, 0x39
	.byte 0x09
	.asciz "30"
	.byte 0x00
	.asciz "Debug Time!"
	.byte 0xea  ; "ê"
	.byte 0x1e
	.asciz "."
	.byte 0xdc  ; "Ü"
	.byte 0x1e
	.asciz "."
	.byte 0xce  ; "Î"
	.byte 0x1e
	.asciz "."
	.asciz " !#$%&?.... "
	.byte 0x00
	.asciz "abc...123..."
	.byte 0x00
	.asciz "ABC...123..."
	.byte 0x00
	.byte 0xe2  ; "â"
	.byte 0x1f
	.asciz "."
	.byte 0xe0  ; "à"
	.byte 0x1f
	.asciz "."
	.byte 0xde  ; "Þ"
	.byte 0x1f
	.asciz "."
	.byte 0xdc  ; "Ü"
	.byte 0x1f
	.asciz "."
	.byte 0xda  ; "Ú"
	.byte 0x1f
	.asciz "."
	.byte 0xd8  ; "Ø"
	.byte 0x1f
	.asciz "."
	.byte 0xd6  ; "Ö"
	.byte 0x1f
	.asciz "."
	.byte 0xd4  ; "Ô"
	.byte 0x1f
	.asciz "."
	.byte 0xd2  ; "Ò"
	.byte 0x1f
	.asciz "."
	.byte 0xd0  ; "Ð"
	.byte 0x1f
	.asciz "."
	.byte 0xce  ; "Î"
	.byte 0x1f
	.asciz "."
	.byte 0xcc  ; "Ì"
	.byte 0x1f
	.asciz "."
	.byte 0xca  ; "Ê"
	.byte 0x1f
	.asciz "."
	.byte 0xc8  ; "È"
	.byte 0x1f
	.asciz "."
	.byte 0xc6  ; "Æ"
	.byte 0x1f
	.asciz "."
	.byte 0xc4  ; "Ä"
	.byte 0x1f
	.asciz "."
	.byte 0xc2  ; "Â"
	.byte 0x1f
	.asciz "."
	.byte 0xc0  ; "À"
	.byte 0x1f
	.asciz "."
	.byte 0xbe  ; "¾"
	.byte 0x1f
	.asciz "."
	.byte 0xbc  ; "¼"
	.byte 0x1f
	.asciz "."
	.byte 0xba  ; "º"
	.byte 0x1f
	.asciz "."
	.byte 0xb8  ; "¸"
	.byte 0x1f
	.asciz "."
	.byte 0xb6  ; "¶"
	.byte 0x1f
	.asciz "."
	.byte 0xb4  ; "´"
	.byte 0x1f
	.asciz "."
	.byte 0xb2  ; "²"
	.byte 0x1f
	.asciz "."
	.byte 0xb0  ; "°"
	.byte 0x1f
	.asciz "."
	.byte 0xae  ; "®"
	.byte 0x1f
	.asciz "."
	.byte 0xac  ; "¬"
	.byte 0x1f
	.asciz "."
	.byte 0xaa  ; "ª"
	.byte 0x1f
	.asciz "."
	.byte 0xa8  ; "¨"
	.byte 0x1f
	.asciz "."
	.byte 0xa6  ; "¦"
	.byte 0x1f
	.asciz "."
	.byte 0xa4  ; "¤"
	.byte 0x1f
	.asciz "."
	.byte 0xa2  ; "¢"
	.byte 0x1f
	.asciz "."
	.byte 0xa0  ; " "
	.byte 0x1f
	.asciz "."
	.byte 0x9e  ; ""
	.byte 0x1f
	.asciz "."
	.byte 0x9c  ; ""
	.byte 0x1f
	.asciz "."
	.byte 0x9a  ; ""
	.byte 0x1f
	.asciz "."
	.byte 0x96  ; ""
	.byte 0x1f
	.asciz "."
	.byte 0x94  ; ""
	.byte 0x1f
	.asciz "."
	.zero 2
	.asciz "SPC"
	.asciz "9"
	.asciz "8"
	.asciz "7"
	.asciz "6"
	.asciz "5"
	.asciz "4"
	.asciz "3"
	.asciz "2"
	.asciz "1"
	.asciz "0"
	.asciz "_"
	.asciz "Z"
	.asciz "Y"
	.asciz "X"
	.asciz "W"
	.asciz "V"
	.asciz "U"
	.asciz "T"
	.asciz "S"
	.asciz "R"
	.asciz "Q"
	.asciz "P"
	.asciz "O"
	.asciz "N"
	.asciz "M"
	.asciz "L"
	.asciz "K"
	.asciz "J"
	.asciz "I"
	.asciz "H"
	.asciz "G"
	.asciz "F"
	.asciz "E"
	.asciz "D"
	.asciz "C"
	.asciz "B"
	.asciz "A"
	.byte 0xce  ; "Î"
	.asciz " ."
	.byte 0xcc  ; "Ì"
	.asciz " ."
	.byte 0xca  ; "Ê"
	.asciz " ."
	.byte 0xc8  ; "È"
	.asciz " ."
	.byte 0xc6  ; "Æ"
	.asciz " ."
	.byte 0xc4  ; "Ä"
	.asciz " ."
	.byte 0xc2  ; "Â"
	.asciz " ."
	.byte 0xc0  ; "À"
	.asciz " ."
	.byte 0xbe  ; "¾"
	.asciz " ."
	.byte 0xbc  ; "¼"
	.asciz " ."
	.byte 0xba  ; "º"
	.asciz " ."
	.byte 0xb8  ; "¸"
	.asciz " ."
	.byte 0xb6  ; "¶"
	.asciz " ."
	.byte 0xb4  ; "´"
	.asciz " ."
	.byte 0xb2  ; "²"
	.asciz " ."
	.byte 0xb0  ; "°"
	.asciz " ."
	.byte 0xae  ; "®"
	.asciz " ."
	.byte 0xac  ; "¬"
	.asciz " ."
	.byte 0xaa  ; "ª"
	.asciz " ."
	.byte 0xa8  ; "¨"
	.asciz " ."
	.byte 0xa6  ; "¦"
	.asciz " ."
	.byte 0xa4  ; "¤"
	.asciz " ."
	.byte 0xa2  ; "¢"
	.asciz " ."
	.byte 0xa0  ; " "
	.asciz " ."
	.byte 0x9e  ; ""
	.asciz " ."
	.byte 0x9c  ; ""
	.asciz " ."
	.byte 0x9a  ; ""
	.asciz " ."
	.byte 0x98  ; ""
	.asciz " ."
	.byte 0x96  ; ""
	.asciz " ."
	.byte 0x94  ; ""
	.asciz " ."
	.byte 0x92  ; ""
	.asciz " ."
	.byte 0x90  ; ""
	.asciz " ."
	.byte 0x8e  ; ""
	.asciz " ."
	.byte 0x8c  ; ""
	.asciz " ."
	.byte 0x8a  ; ""
	.asciz " ."
	.byte 0x88  ; ""
	.asciz " ."
	.byte 0x86  ; ""
	.asciz " ."
	.byte 0x82  ; ""
	.asciz " ."
	.byte 0x80  ; ""
	.asciz " ."
	.zero 2
	.asciz "SPC"
	.asciz "9"
	.asciz "8"
	.asciz "7"
	.asciz "6"
	.asciz "5"
	.asciz "4"
	.asciz "3"
	.asciz "2"
	.asciz "1"
	.asciz "0"
	.asciz "_"
	.asciz "z"
	.asciz "y"
	.asciz "x"
	.asciz "w"
	.asciz "v"
	.asciz "u"
	.asciz "t"
	.asciz "s"
	.asciz "r"
	.asciz "q"
	.asciz "p"
	.asciz "o"
	.asciz "n"
	.asciz "m"
	.asciz "l"
	.asciz "k"
	.asciz "j"
	.asciz "i"
	.asciz "h"
	.asciz "g"
	.asciz "f"
	.asciz "e"
	.asciz "d"
	.asciz "c"
	.asciz "b"
	.asciz "a"
	.byte 0xa0  ; " "
	.asciz "!."
	.byte 0x9e  ; ""
	.asciz "!."
	.byte 0x9c  ; ""
	.asciz "!."
	.byte 0x9a  ; ""
	.asciz "!."
	.byte 0x98  ; ""
	.asciz "!."
	.byte 0x96  ; ""
	.asciz "!."
	.byte 0x92  ; ""
	.asciz "!."
	.byte 0x8e  ; ""
	.asciz "!."
	.byte 0x8c  ; ""
	.asciz "!."
	.byte 0x8a  ; ""
	.asciz "!."
	.byte 0x86  ; ""
	.asciz "!."
	.byte 0x82  ; ""
	.asciz "!."
	.byte 0x80  ; ""
	.asciz "!."
	.asciz "~!."
	.asciz "|!."
	.asciz "z!."
	.asciz "x!."
	.asciz "v!."
	.asciz "t!."
	.asciz "r!."
	.asciz "p!."
	.asciz "n!."
	.asciz "j!."
	.asciz "f!."
	.asciz "d!."
	.asciz "b!."
	.asciz "`!."
	.asciz "^!."
	.asciz "\\!."
	.asciz "Z!."
	.asciz "X!."
	.asciz "V!."
	.asciz "T!."
	.zero 2
	.asciz "}"
	.asciz "{"
	.asciz "]"
	.asciz "["
	.asciz ">"
	.asciz "<"
	.asciz ")"
	.asciz "("
	.asciz "~8d"
	.asciz "~8b"
	.asciz "="
	.asciz "/"
	.asciz "*"
	.asciz "-"
	.asciz "+"
	.asciz ";"
	.asciz ":"
	.asciz "."
	.asciz ","
	.asciz "`"
	.asciz "~27"
	.asciz "~22"
	.asciz "|"
	.asciz "^"
	.asciz "~5c"
	.asciz "~40"
	.asciz "?"
	.asciz "&"
	.asciz "%"
	.asciz "$"
	.asciz "#"
	.asciz "!"
	.byte 0xf8  ; "ø"
	.byte 0x1e
	.asciz "."
	.byte 0xe4  ; "ä"
	.byte 0x1f
	.asciz "."
	.byte 0xd0  ; "Ð"
	.asciz " ."
	.asciz "%"
	.asciz "%"
	.byte 0x1f
	.byte 0x00
	.asciz "$"
	.asciz "$"
	.byte 0x1f
	.byte 0x00
	.byte 0xc4  ; "Ä"
	.asciz "!."
	.byte 0xc2  ; "Â"
	.asciz "!."
	.asciz "_"
	.asciz " "
	.zero 2
	.asciz "L"
	.byte 0x9d  ; ""
	.byte 0x00
	pop xhl
	.byte 0x01
	.byte 0xb7  ; "·"
	.byte 0x03
	.byte 0xb5  ; "µ"
	.byte 0x04
	.byte 0x44
	.byte 0x05
	.byte 0xd3  ; "Ó"
	.byte 0x05
	pop xhl
	.byte 0x07

HDAE5000_Test_Strings:	; 0x2E21D8
	; PPORT test and debug strings
	.asciz "Name"
	.byte 0x00
	.asciz "Test"
	.byte 0x00
	.asciz "PPORT TEST"
	.byte 0x00
	.asciz "HDD ID READ"
	.asciz "FD TEST"
	.asciz "OK"
	.byte 0x00
	.asciz "ERROR"
	.asciz "ERROR"
	.asciz "STOP TEST LOOP"
	.byte 0x00
	.asciz "START TEST LOOP"
	.asciz "=======> Port Test OK"
	.asciz "=======> Port Test Error"
	.byte 0x00
	.asciz "HD-TYPE : "
	.byte 0x00
	.asciz "Fre Capa: %3.1f [MB]"
	.zero 3
	.asciz "=======> HDD OK"
	.asciz "=======> HDD NG!"
	.zero 3
	.byte 0xc8  ; "È"
	.asciz "B%2.2d"
	.asciz "*.*"
	.asciz "CpHD"
	.byte 0x00
	.asciz "CpHD"
	.byte 0x00
	.ascii "WRITE PROTECTION   :ON     QUICK LOAD MODE:     1"
	.byte 0x09
	.ascii "WRITE CONFIRM      :OFF    JUMP AFTER LOAD:     2"
	.byte 0x09
	.ascii "LOAD BY NUMBER MODE:  1    FREE HDD SPACE :1251MB"
	.byte 0x09
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%s"
	.byte 0x00
	.asciz "  %d"
	.byte 0x00
	.asciz "     %d"
	.asciz "     %d"
	.asciz "%4ldMB"
	.byte 0x00
	.asciz "HDAE"
	.zero 3
	.byte 0x7f
	.byte 0x00
	.byte 0x52
	.byte 0x02, 0x7f
	.byte 0x00
	.byte 0x57
	.byte 0x02, 0x7f
	.byte 0x00
	pop xix
	.byte 0x02, 0x7f
	.byte 0x00
	.ascii "a"
	.byte 0x02, 0x7f
	.byte 0x00
	.ascii "f"
	.byte 0x02, 0x7f
	.byte 0x00
	.ascii "k"
	.byte 0x02, 0x7f
	.byte 0x00
	.ascii "p"
	.byte 0x02, 0x7f
	.byte 0x00
	.ascii "u"
	.byte 0x02, 0x7f
	.zero 3
	.byte 0xc0  ; "À"
	.byte 0x01
	.byte 0xc0  ; "À"
	.byte 0x01
	.byte 0xc0  ; "À"
	.byte 0x01
	.byte 0xa6  ; "¦"
	.byte 0x01
	.byte 0xc0  ; "À"
	.byte 0x01
	.byte 0x37
	.byte 0x01
	.byte 0xfe  ; "þ"
	.byte 0x00
	.ascii "   :                "
	.byte 0x09
	.byte 0x00
	.asciz "%3.3d"
	.ascii "CURRENT PANEL"
	.byte 0x09
	.ascii " PANEL MEMORY"
	.byte 0x09
	.ascii "  SEQUENCER  "
	.byte 0x09
	.ascii "  COMPOSER   "
	.byte 0x09
	.ascii " SOUND MEMORY"
	.byte 0x09
	.ascii "     MSP     "
	.byte 0x09
	.ascii "RHYTHM CUSTOM"
	.byte 0x09
	.ascii "  USER MIDI  "
	.byte 0x09
	.ascii "    LYRICS   "
	.byte 0x09
	.zero 2
	.ascii "             "
	.byte 0x09
	.ascii "             "
	.byte 0x09
	.ascii "             "
	.byte 0x09
	.ascii "             "
	.byte 0x09
	.ascii "             "
	.byte 0x09
	.ascii "             "
	.byte 0x09
	.ascii "             "
	.byte 0x09
	.ascii "             "
	.byte 0x09
	.ascii "             "
	.byte 0x09
	.zero 2
	.ascii "             "
	.byte 0x09
	.zero 2
	.byte 0x04, 0x01, 0x7f
	.byte 0x00
	pop xhl
	.byte 0x01, 0x7f
	.byte 0x00
	.byte 0x03, 0x01, 0x7f
	.byte 0x00
	pop xix
	.byte 0x01, 0x7f
	.byte 0x00
	.byte 0x02, 0x01, 0x7f
	.byte 0x00
	.byte 0x60
	.byte 0x01, 0x7f
	.byte 0x00

HDAE5000_Dir_Strings:	; 0x2E2500
	; Directory management strings
	.asciz "DIRECTORY "
	.byte 0x00
	.asciz "%2.2d"
	.asciz ":"
	.byte 0x09
	.byte 0x00
	.ascii ":                          "
	.byte 0x09
	.zero 2
	.asciz "%2.2d"
	.byte 0x15, 0x01
	.byte 0xd7  ; "×"
	.byte 0x00
	.byte 0x51
	.byte 0x01
	.byte 0x99  ; ""
	.byte 0x01
	.byte 0x99  ; ""
	.byte 0x01
	.byte 0x99  ; ""
	.byte 0x01
	.byte 0x99  ; ""
	.byte 0x01
	.byte 0x99  ; ""
	.byte 0x01
	.asciz " "
	.byte 0x99  ; ""
	.byte 0x01
	.byte 0x99  ; ""
	.byte 0x01
	.byte 0x99  ; ""
	.byte 0x01
	.byte 0xb7  ; "·"
	.byte 0x00
	.byte 0x83  ; ""
	.byte 0x00
	.asciz "DELD"
	.byte 0x00
	.asciz "DELF"
	.byte 0x00
	.asciz "UTIL"
	.byte 0x00
	.asciz "---[ LSW File Info. ]---"
	.byte 0x00
	.asciz "adr  : "
	.asciz "size : "
	.asciz "---[ SDA File Info. ]---"
	.byte 0x00
	.asciz "adr  : "
	.asciz "size : "
	.asciz "---[ PMT File Info. ]---"
	.byte 0x00
	.asciz "adr  : "
	.asciz "size : "
	.asciz "---[ SQF File Info. ]---"
	.byte 0x00
	.asciz "adr  : "
	.asciz "size : "
	.asciz "---[ SEQ File Info. ]---"
	.byte 0x00
	.asciz "adr  : "
	.asciz "size : "
	.asciz "---[ CMP File Info. ]---"
	.byte 0x00
	.asciz "adr  : "
	.asciz "size : "
	.asciz "---[ TM File Info. ]---"
	.asciz "adr  : "
	.asciz "size : "
	.asciz "---[ MSP File Info. ]---"
	.byte 0x00
	.asciz "adr  : "
	.asciz "size : "
	.asciz "---[ RCM File Info. ]---"
	.byte 0x00
	.asciz "adr  : "
	.asciz "size : "
	.asciz "---[ MD File Info. ]---"
	.asciz "adr  : "
	.asciz "size : "
	.asciz "PCLK"
	.byte 0x00
	.asciz "PORT IS ACTIVE"
	.byte 0x00
	.asciz "              "
	.byte 0x00
	.byte 0xb0  ; "°"
	.byte 0x00
	.byte 0x9b  ; ""
	.byte 0x00
	.byte 0xb0  ; "°"
	.byte 0x00
	.byte 0x9d  ; ""
	.byte 0x00
	.asciz "v'."
	.asciz "f'."
	.asciz "V'."
	.asciz "F'."
	.asciz "BASS/DRUMS MONO"
	.asciz "BASS+DRUMS MIX "
	.asciz "   DRUMS L/R   "
	.asciz "      OFF      "
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "i"
	.asciz "i"
	.asciz "i"
	.asciz "-"
	.asciz "1"
	.asciz "5"
	.asciz "<"
	.zero 2
	.asciz "B(."
	.asciz "<(."
	.asciz "6(."
	.asciz "0(."
	.asciz "*(."
	.asciz "$(."
	.byte 0x1e
	.asciz "(."
	.byte 0x18
	.asciz "(."
	.byte 0x12
	.asciz "(."
	.byte 0x0c
	.asciz "(."
	.byte 0x06
	.asciz "(."
	.byte 0x00
	.asciz "(."
	.byte 0xfa  ; "ú"
	.asciz "'."
	.byte 0xf4  ; "ô"
	.asciz "'."
	.byte 0xee  ; "î"
	.asciz "'."
	.byte 0xe8  ; "è"
	.asciz "'."
	.byte 0xe2  ; "â"
	.asciz "'."
	.asciz " 16 "
	.byte 0x00
	.asciz " 15 "
	.byte 0x00
	.asciz " 14 "
	.byte 0x00
	.asciz " 13 "
	.byte 0x00
	.asciz " 12 "
	.byte 0x00
	.asciz " 11 "
	.byte 0x00
	.asciz " 10 "
	.byte 0x00
	.asciz "  9 "
	.byte 0x00
	.asciz "  8 "
	.byte 0x00
	.asciz "  7 "
	.byte 0x00
	.asciz "  6 "
	.byte 0x00
	.asciz "  5 "
	.byte 0x00
	.asciz "  4 "
	.byte 0x00
	.asciz "  3 "
	.byte 0x00
	.asciz "  2 "
	.byte 0x00
	.asciz "  1 "
	.byte 0x00
	.asciz "NONE"
	.byte 0x00
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "l"
	.asciz "l"
	.asciz "l"
	.asciz "-"
	.asciz "4"
	.asciz "8"
	.asciz "?"
	.zero 2
	.byte 0x04
	.asciz ")."
	.byte 0xfe  ; "þ"
	.asciz "(."
	.byte 0xf8  ; "ø"
	.asciz "(."
	.byte 0xf2  ; "ò"
	.asciz "(."
	.byte 0xec  ; "ì"
	.asciz "(."
	.byte 0xe6  ; "æ"
	.asciz "(."
	.byte 0xe0  ; "à"
	.asciz "(."
	.byte 0xda  ; "Ú"
	.asciz "(."
	.byte 0xd4  ; "Ô"
	.asciz "(."
	.byte 0xce  ; "Î"
	.asciz "(."
	.byte 0xc8  ; "È"
	.asciz "(."
	.byte 0xc2  ; "Â"
	.asciz "(."
	.byte 0xbc  ; "¼"
	.asciz "(."
	.byte 0xb6  ; "¶"
	.asciz "(."
	.byte 0xb0  ; "°"
	.asciz "(."
	.byte 0xaa  ; "ª"
	.asciz "(."
	.byte 0xa4  ; "¤"
	.asciz "(."
	.asciz " 16 "
	.byte 0x00
	.asciz " 15 "
	.byte 0x00
	.asciz " 14 "
	.byte 0x00
	.asciz " 13 "
	.byte 0x00
	.asciz " 12 "
	.byte 0x00
	.asciz " 11 "
	.byte 0x00
	.asciz " 10 "
	.byte 0x00
	.asciz "  9 "
	.byte 0x00
	.asciz "  8 "
	.byte 0x00
	.asciz "  7 "
	.byte 0x00
	.asciz "  6 "
	.byte 0x00
	.asciz "  5 "
	.byte 0x00
	.asciz "  4 "
	.byte 0x00
	.asciz "  3 "
	.byte 0x00
	.asciz "  2 "
	.byte 0x00
	.asciz "  1 "
	.byte 0x00
	.asciz "NONE"
	.byte 0x00
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "l"
	.asciz "l"
	.asciz "l"
	.asciz "-"
	.asciz "4"
	.asciz "8"
	.asciz "?"
	.zero 2
	.asciz "6)."
	.asciz "2)."
	.asciz ".)."
	.asciz "YES"
	.asciz "NO "
	.asciz "---"
	.asciz "%s"
	.byte 0x00
	.byte 0x1b
	.byte 0x00
	.byte 0x1f
	.byte 0x00
	.asciz "B"
	.asciz "B"
	.asciz "B"
	.asciz "#"
	.asciz "'"
	.asciz "+"
	.asciz "2"
	.zero 2
	.asciz "SVOP"
	.byte 0x00
	.asciz "%s"
	.byte 0x00
	.asciz "'"
	.asciz "+"
	.asciz "F"
	.asciz "F"
	.asciz "F"
	.asciz "/"
	.asciz "3"
	.asciz "7"
	.asciz ">"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "x"
	.asciz "x"
	.asciz "x"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "x"
	.asciz "x"
	.asciz "x"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "x"
	.asciz "x"
	.asciz "x"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "x"
	.asciz "x"
	.asciz "x"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "x"
	.asciz "x"
	.asciz "x"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "x"
	.asciz "x"
	.asciz "x"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "x"
	.asciz "x"
	.asciz "x"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "x"
	.asciz "x"
	.asciz "x"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "0"
	.asciz "4"
	.byte 0xa2  ; "¢"
	.byte 0x00
	.byte 0xa2  ; "¢"
	.byte 0x00
	.byte 0xa2  ; "¢"
	.byte 0x00
	.asciz "8"
	.asciz "F"
	.asciz "s"
	.asciz "z"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz "%"
	.asciz "J"
	.asciz "J"
	.asciz "J"
	.asciz ")"
	.asciz "-"
	.asciz "1"
	.asciz "8"
	.zero 2
	.asciz "%1d"
	.byte 0x19
	.byte 0x00
	.byte 0x19
	.byte 0x00
	.asciz "4"
	.asciz "4"
	.asciz "4"
	.byte 0x1d
	.byte 0x00
	.asciz "!"
	.asciz "%"
	.asciz ","
	.zero 2
	.asciz "%1d"
	.byte 0xb0  ; "°"
	.asciz "*."
	.byte 0xa8  ; "¨"
	.asciz "*."
	.byte 0xa0  ; " "
	.asciz "*."
	.byte 0x98  ; ""
	.asciz "*."
	.byte 0x90  ; ""
	.asciz "*."
	.asciz " YELLOW"
	.asciz " BLACK "
	.asciz " BLUE  "
	.asciz " GREEN "
	.asciz " RED   "
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "D"
	.asciz "D"
	.asciz "D"
	.asciz "-"
	.asciz "1"
	.asciz "5"
	.asciz "<"
	.zero 2
	.byte 0x04
	.asciz "+."
	.byte 0xfc  ; "ü"
	.asciz "*."
	.byte 0xf4  ; "ô"
	.asciz "*."
	.byte 0xec  ; "ì"
	.asciz "*."
	.byte 0xe4  ; "ä"
	.asciz "*."
	.asciz " YELLOW"
	.asciz " BLACK "
	.asciz " BLUE  "
	.asciz " GREEN "
	.asciz " RED   "
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "D"
	.asciz "D"
	.asciz "D"
	.asciz "-"
	.asciz "1"
	.asciz "5"
	.asciz "<"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz "%"
	.asciz "@"
	.asciz "@"
	.asciz "@"
	.asciz ")"
	.asciz "-"
	.asciz "1"
	.asciz "8"
	.zero 2
	.asciz "%1d"
	.byte 0x19
	.byte 0x00
	.byte 0x19
	.byte 0x00
	.asciz "4"
	.asciz "4"
	.asciz "4"
	.byte 0x1d
	.byte 0x00
	.asciz "!"
	.asciz "%"
	.asciz ","
	.zero 2
	.asciz "%1d"
	.byte 0x19
	.byte 0x00
	.byte 0x19
	.byte 0x00
	.asciz "4"
	.asciz "4"
	.asciz "4"
	.byte 0x1d
	.byte 0x00
	.asciz "!"
	.asciz "%"
	.asciz ","
	.zero 2
	.asciz "%1d"
	.byte 0x19
	.byte 0x00
	.byte 0x19
	.byte 0x00
	.asciz "4"
	.asciz "4"
	.asciz "4"
	.byte 0x1d
	.byte 0x00
	.asciz "!"
	.asciz "%"
	.asciz ","
	.zero 2
	.ascii "HD-TYPE             :                 "
	.byte 0x09
	.ascii "TRACKS              :                 "
	.byte 0x09
	.ascii "HEADS               :                 "
	.byte 0x09
	.ascii "SECTORS PER TRACK   :                 "
	.byte 0x09
	.ascii "TOTAL HD       (MB) :                 "
	.byte 0x09
	.ascii "USED BY SYSTEM (MB) :                 "
	.byte 0x09
	.ascii "FREE FOR USE   (MB) :                 "
	.byte 0x09
	.ascii "SOFTWARE RELEASE    :                 "
	.byte 0x09
	.zero 2
	.asciz "%6.1f"
	.asciz "%6.1f"
	.asciz "%6.1f"
	.zero 2
	.byte 0xc8  ; "È"
	.asciz "B"
	.byte 0x00
	.byte 0xc8  ; "È"
	.asciz "B"
	.byte 0x00
	.byte 0xc8  ; "È"
	.asciz "BFMT!"
	.zero 3
	.byte 0x13
	.byte 0x00
	.asciz "&"
	.asciz "9"
	.asciz "L"
	.byte 0x90  ; ""
	.byte 0x00
	.asciz "a"
	.asciz "a"
	.zero 2
	.byte 0x03
	.byte 0x00
	.byte 0x1e
	.byte 0x00
	.asciz "9"
	.asciz "N"
	.asciz "i"
	.asciz "LBNS"
	.byte 0x00
	.asciz "4"
	.asciz "N"
	.asciz "h"
	.byte 0x82  ; ""
	.byte 0x00
	.byte 0x9c  ; ""
	.byte 0x00
	.byte 0x0f
	.byte 0x00
	.byte 0x0f
	.byte 0x00
	.byte 0x0f
	.byte 0x00
	.byte 0xb6  ; "¶"
	.byte 0x00
	.byte 0xb6  ; "¶"
	.byte 0x00
	.byte 0xb6  ; "¶"
	.byte 0x00
	.byte 0xb6  ; "¶"
	.byte 0x00
	.zero 2
	.asciz "LBN!"
	.byte 0x00
	.asciz "%1.1d"
	.asciz "%2.2d"
	.asciz "%3.3d"
	.asciz " %1.1d"
	.byte 0x00
	.asciz " %2.2d"
	.zero 3
	.asciz "U"
	.byte 0x89  ; ""
	.byte 0x00
	.byte 0xbd  ; "½"
	.byte 0x00
	.byte 0x14, 0x01
	popw bc
	.byte 0x01
	.byte 0xbb  ; "»"
	.byte 0x01
	.asciz "                          "
	.byte 0x00
	.asciz "%s"
	.byte 0x00
	.asciz "B"
	.asciz "F"
	.asciz "a"
	.asciz "a"
	.asciz "a"
	.asciz "J"
	.asciz "N"
	.asciz "R"
	.asciz "Y"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "A"
	.asciz "F"
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.asciz "K"
	.asciz "f"
	.byte 0x81  ; ""
	.byte 0x00
	.byte 0x88  ; ""
	.byte 0x00
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "A"
	.asciz "F"
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.asciz "K"
	.asciz "f"
	.byte 0x81  ; ""
	.byte 0x00
	.byte 0x88  ; ""
	.byte 0x00
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "A"
	.asciz "F"
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.asciz "K"
	.asciz "f"
	.byte 0x81  ; ""
	.byte 0x00
	.byte 0x88  ; ""
	.byte 0x00
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "A"
	.asciz "F"
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.asciz "K"
	.asciz "f"
	.byte 0x81  ; ""
	.byte 0x00
	.byte 0x88  ; ""
	.byte 0x00
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "A"
	.asciz "F"
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.asciz "K"
	.asciz "f"
	.byte 0x81  ; ""
	.byte 0x00
	.byte 0x88  ; ""
	.byte 0x00
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "A"
	.asciz "F"
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.asciz "K"
	.asciz "f"
	.byte 0x81  ; ""
	.byte 0x00
	.byte 0x88  ; ""
	.byte 0x00
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "A"
	.asciz "F"
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.asciz "K"
	.asciz "f"
	.byte 0x81  ; ""
	.byte 0x00
	.byte 0x88  ; ""
	.byte 0x00
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "A"
	.asciz "F"
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.asciz "K"
	.asciz "f"
	.byte 0x81  ; ""
	.byte 0x00
	.byte 0x88  ; ""
	.byte 0x00
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "A"
	.asciz "F"
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.byte 0xcc  ; "Ì"
	.byte 0x00
	.asciz "K"
	.asciz "f"
	.byte 0x81  ; ""
	.byte 0x00
	.byte 0x88  ; ""
	.byte 0x00
	.zero 2
	.ascii "   :                "
	.byte 0x09
	.byte 0x00

HDAE5000_Char_Tables:	; 0x2E2E76
	; Character set tables
	.asciz "%3.3d"
	.ascii "E"
	.byte 0x01, 0x7f
	.byte 0x00
	.ascii "f"
	.byte 0x01, 0x7f
	.byte 0x00
	popw wa
	.byte 0x01, 0x7f
	.byte 0x00
	.ascii "i"
	.byte 0x01, 0x7f
	.byte 0x00
	.byte 0x44
	.byte 0x01, 0x7f
	.byte 0x00
	.ascii "v"
	.byte 0x01, 0x7f
	.byte 0x00
	.byte 0x43
	.byte 0x01, 0x7f
	.byte 0x00
	.ascii "w"
	.byte 0x01, 0x7f
	.byte 0x00
	popw bc
	.byte 0x01, 0x7f
	.byte 0x00
	.ascii "k"
	.byte 0x01, 0x7f
	.byte 0x00
	popw de
	.byte 0x01, 0x7f
	.byte 0x00
	.ascii "j"
	.byte 0x01, 0x7f
	.byte 0x00
	.asciz "FLS NAME "
	.asciz "%2.2d"
	.asciz ":"
	.byte 0x09
	.byte 0x00
	.ascii ":                                 "
	.byte 0x09
	.byte 0x00
	.asciz "%2.2d"
	.ascii " LOC. %3.3d/%2.2d"
	.byte 0x09
	.zero 2
	.ascii " LOC. 000/00"
	.byte 0x09
	.byte 0x00
	.asciz "FLS!"
	.byte 0x00
	.asciz "DEL1"
	.byte 0x00
	.asciz "DEL2"
	.byte 0x00
	.asciz "OVWR"
	.byte 0x00
	.asciz "%2.2d"
	.asciz ".LSW"
	.byte 0x00
	.asciz ".PMT"
	.byte 0x00
	.asciz ".SQT"
	.byte 0x00
	.asciz ".CMP"
	.byte 0x00
	.asciz ".TM"
	.asciz ".MSP"
	.byte 0x00
	.asciz ".RCM"
	.byte 0x00
	.asciz ".MD"
	.asciz ".TLX"
	.byte 0x00
	.asciz "WrCn"
	.byte 0x00
	.asciz "DEL!"
	.byte 0x00
	.asciz "%s"
	.byte 0x00
	.asciz "'"
	.asciz "+"
	.asciz "F"
	.asciz "F"
	.asciz "F"
	.asciz "/"
	.asciz "3"
	.asciz "7"
	.asciz ">"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "`"
	.asciz "`"
	.asciz "`"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "`"
	.asciz "`"
	.asciz "`"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "`"
	.asciz "`"
	.asciz "`"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "`"
	.asciz "`"
	.asciz "`"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "`"
	.asciz "`"
	.asciz "`"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "`"
	.asciz "`"
	.asciz "`"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "`"
	.asciz "`"
	.asciz "`"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "`"
	.asciz "`"
	.asciz "`"
	.asciz "-"
	.asciz ";"
	.asciz "I"
	.asciz "P"
	.zero 2
	.asciz "%s"
	.byte 0x00
	.asciz "%"
	.asciz ")"
	.asciz "l"
	.asciz "l"
	.asciz "l"
	.asciz "-"
	.asciz ";"
	.asciz "U"
	.asciz "\\"
	.zero 2
	.asciz "TimB"
	.byte 0x00
	.asciz "TLBN"
	.zero 5
	.byte 0x01, 0x01, 0x01
	.byte 0x00
	.byte 0x02, 0x02, 0x02
	.byte 0x00
	.byte 0x03, 0x03, 0x03
	.byte 0x00
	.byte 0x04, 0x04, 0x04
	.byte 0x00
	.byte 0x05, 0x05, 0x05
	.byte 0x00
	.byte 0x06, 0x06, 0x06
	.byte 0x00
	.byte 0x07, 0x07, 0x07
	.byte 0x00
	.byte 0x08, 0x08, 0x08
	.byte 0x00
	.byte 0x09, 0x09, 0x09
	.byte 0x00
	.byte 0x0a, 0x0a, 0x0a
	.byte 0x00
	.byte 0x0b, 0x0b, 0x0b
	.byte 0x00
	.byte 0x0c, 0x0c, 0x0c
	.byte 0x00
	.byte 0x0d, 0x0d, 0x0d
	.byte 0x00
	.byte 0x0e, 0x0e, 0x0e
	.byte 0x00
	.byte 0x0f, 0x0f, 0x0f
	.byte 0x00
	.byte 0x10, 0x10, 0x10
	.byte 0x00
	.byte 0x11, 0x11, 0x11
	.byte 0x00
	.byte 0x12, 0x12, 0x12
	.byte 0x00
	.byte 0x13, 0x13, 0x13
	.byte 0x00
	.byte 0x14, 0x14, 0x14
	.byte 0x00
	.byte 0x15, 0x15, 0x15
	.byte 0x00
	.byte 0x16, 0x16, 0x16
	.byte 0x00
	.byte 0x17, 0x17, 0x17
	.byte 0x00
	.byte 0x18, 0x18, 0x18
	.byte 0x00
	.byte 0x19, 0x19, 0x19
	.byte 0x00
	.byte 0x1a, 0x1a, 0x1a
	.byte 0x00
	.byte 0x1b, 0x1b, 0x1b
	.byte 0x00
	.byte 0x1c, 0x1c, 0x1c
	.byte 0x00
	.byte 0x1d, 0x1d, 0x1d
	.byte 0x00
	calr	0x1e1e
	.byte 0x00
	.byte 0x1f, 0x1f, 0x1f
	.byte 0x00
	.asciz "   "
	.asciz "!!!"
	.asciz "\"\"\""
	.asciz "###"
	.asciz "$$$"
	.asciz "%%%"
	.asciz "&&&"
	.asciz "'''"
	.asciz "((("
	.asciz ")))"
	.asciz "***"
	.asciz "+++"
	.asciz ",,,"
	.asciz "---"
	.asciz "..."
	.asciz "///"
	.asciz "000"
	.asciz "111"
	.asciz "222"
	.asciz "333"
	.asciz "444"
	.asciz "555"
	.asciz "666"
	.asciz "777"
	.asciz "888"
	.asciz "999"
	.asciz ":::"
	.asciz ";;;"
	.asciz "<<<"
	.asciz "==="
	.asciz ">>>"
	.asciz "???"
	.asciz "@@@"
	.asciz "AAA"
	.asciz "BBB"
	.asciz "CCC"
	.asciz "DDD"
	.asciz "EEE"
	.asciz "FFF"
	.asciz "GGG"
	.asciz "HHH"
	.asciz "III"
	.asciz "JJJ"
	.asciz "KKK"
	.asciz "LLL"
	.asciz "MMM"
	.asciz "NNN"
	.asciz "OOO"
	.asciz "PPP"
	.asciz "QQQ"
	.asciz "RRR"
	.asciz "SSS"
	.asciz "TTT"
	.asciz "UUU"
	.asciz "VVV"
	.asciz "WWW"
	.asciz "XXX"
	.asciz "YYY"
	.asciz "ZZZ"
	.asciz "[[["
	.asciz "\\\\\\"
	.asciz "]]]"
	.asciz "^^^"
	.asciz "___"
	.asciz "```"
	.asciz "aaa"
	.asciz "bbb"
	.asciz "ccc"
	.asciz "ddd"
	.asciz "eee"
	.asciz "fff"
	.asciz "ggg"
	.asciz "hhh"
	.asciz "iii"
	.asciz "jjj"
	.asciz "kkk"
	.asciz "lll"
	.asciz "mmm"
	.asciz "nnn"
	.asciz "ooo"
	.asciz "ppp"
	.asciz "qqq"
	.asciz "rrr"
	.asciz "sss"
	.asciz "ttt"
	.asciz "uuu"
	.asciz "vvv"
	.asciz "www"
	.asciz "xxx"
	.asciz "yyy"
	.asciz "zzz"
	.asciz "{{{"
	.asciz "|||"
	.asciz "}}}"
	.asciz "~~~"
	jrl	nc, 0x7f7f
	.byte 0x00
	.byte 0x80, 0x80, 0x80  ; ""
	.byte 0x00
	.byte 0x81, 0x81, 0x81  ; ""
	.byte 0x00
	.byte 0x82, 0x82, 0x82  ; ""
	.byte 0x00
	.byte 0x83, 0x83, 0x83  ; ""
	.byte 0x00
	.byte 0x84, 0x84, 0x84  ; ""
	.byte 0x00
	.byte 0x85, 0x85, 0x85  ; ""
	.byte 0x00
	.byte 0x86, 0x86, 0x86  ; ""
	.byte 0x00
	.byte 0x87, 0x87, 0x87  ; ""
	.byte 0x00
	add	(xwa-120), w
	.byte 0x00
	add	(xbc-119), a
	.byte 0x00
	add	(xde-118), b
	.byte 0x00
	add	(xhl-117), c
	.byte 0x00
	add	(xix-116), d
	.byte 0x00
	add	(xiy-115), e
	.byte 0x00
	add	(xiz-114), h
	.byte 0x00
	.byte 0x8f, 0x8f, 0x8f  ; ""
	.byte 0x00
	.byte 0x90, 0x90, 0x90  ; ""
	.byte 0x00
	.byte 0x91, 0x91, 0x91  ; ""
	.byte 0x00
	.byte 0x92, 0x92, 0x92  ; ""
	.byte 0x00
	.byte 0x93, 0x93, 0x93  ; ""
	.byte 0x00
	.byte 0x94, 0x94, 0x94  ; ""
	.byte 0x00
	.byte 0x95, 0x95, 0x95  ; ""
	.byte 0x00
	.byte 0x96, 0x96, 0x96  ; ""
	.byte 0x00
	.byte 0x97, 0x97, 0x97  ; ""
	.byte 0x00
	adc	(xwa-104), wa
	.byte 0x00
	adc	(xbc-103), bc
	.byte 0x00
	adc	(xde-102), de
	.byte 0x00
	adc	(xhl-101), hl
	.byte 0x00
	adc	(xix-100), ix
	.byte 0x00
	adc	(xiy-99), iy
	.byte 0x00
	adc	(xiz-98), iz
	.byte 0x00
	.byte 0x9f, 0x9f, 0x9f  ; ""
	.byte 0x00
	.byte 0xa0, 0xa0, 0xa0  ; "   "
	.byte 0x00
	.byte 0xa1, 0xa1, 0xa1  ; "¡¡¡"
	.byte 0x00
	.byte 0xa2, 0xa2, 0xa2  ; "¢¢¢"
	.byte 0x00
	.byte 0xa3, 0xa3, 0xa3  ; "£££"
	.byte 0x00
	.byte 0xa4, 0xa4, 0xa4  ; "¤¤¤"
	.byte 0x00
	.byte 0xa5, 0xa5, 0xa5  ; "¥¥¥"
	.byte 0x00
	.byte 0xa6, 0xa6, 0xa6  ; "¦¦¦"
	.byte 0x00
	.byte 0xa7, 0xa7, 0xa7  ; "§§§"
	.byte 0x00
	sub	(xwa-88), xwa
	.byte 0x00
	sub	(xbc-87), xbc
	.byte 0x00
	sub	(xde-86), xde
	.byte 0x00
	sub	(xhl-85), xhl
	.byte 0x00
	sub	(xix-84), xix
	.byte 0x00
	sub	(xiy-83), xiy
	.byte 0x00
	sub	(xiz-82), xiz
	.byte 0x00
	sub	(xsp-81), xsp
	.byte 0x00
	.byte 0xb0, 0xb0, 0xb0  ; "°°°"
	.byte 0x00
	.byte 0xb1, 0xb1, 0xb1  ; "±±±"
	.byte 0x00
	.byte 0xb2, 0xb2, 0xb2  ; "²²²"
	.byte 0x00
	.byte 0xb3, 0xb3, 0xb3  ; "³³³"
	.byte 0x00
	.byte 0xb4, 0xb4, 0xb4  ; "´´´"
	.byte 0x00
	.byte 0xb5, 0xb5, 0xb5  ; "µµµ"
	.byte 0x00
	.byte 0xb6, 0xb6, 0xb6  ; "¶¶¶"
	.byte 0x00
	.byte 0xb7, 0xb7, 0xb7  ; "···"
	.byte 0x00
	setm	0, (xwa-72)
	.byte 0x00
	setm	1, (xbc-71)
	.byte 0x00
	setm	2, (xde-70)
	.byte 0x00
	setm	3, (xhl-69)
	.byte 0x00
	setm	4, (xix-68)
	.byte 0x00
	setm	5, (xiy-67)
	.byte 0x00
	setm	6, (xiz-66)
	.byte 0x00
	setm	7, (xsp-65)
	.byte 0x00
	.byte 0xc0, 0xc0, 0xc0  ; "ÀÀÀ"
	.byte 0x00
	.byte 0xc1, 0xc1, 0xc1  ; "ÁÁÁ"
	.byte 0x00
	.byte 0xc2, 0xc2, 0xc2  ; "ÂÂÂ"
	.byte 0x00
	.byte 0xc3, 0xc3, 0xc3  ; "ÃÃÃ"
	.byte 0x00
	.byte 0xc4, 0xc4, 0xc4  ; "ÄÄÄ"
	.byte 0x00
	.byte 0xc5, 0xc5, 0xc5  ; "ÅÅÅ"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6  ; "ÆÆÆ"
	.byte 0x00
	.byte 0xc7, 0xc7, 0xc7  ; "ÇÇÇ"
	.byte 0x00
	add	w, 0xc8
	.byte 0x00
	adc	a, 0xc9
	.byte 0x00
	sub	b, 0xca
	.byte 0x00
	sbc	c, 0xcb
	.byte 0x00
	and	d, 0xcc
	.byte 0x00
	xor	e, 0xcd
	.byte 0x00
	or	h, 0xce
	.byte 0x00
	cp l, 0xcf		; "ÏÏÏ"
	.byte 0x00
	.byte 0xd0, 0xd0, 0xd0  ; "ÐÐÐ"
	.byte 0x00
	.byte 0xd1, 0xd1, 0xd1  ; "ÑÑÑ"
	.byte 0x00
	.byte 0xd2, 0xd2, 0xd2  ; "ÒÒÒ"
	.byte 0x00
	.byte 0xd3, 0xd3, 0xd3  ; "ÓÓÓ"
	.byte 0x00
	.byte 0xd4, 0xd4, 0xd4  ; "ÔÔÔ"
	.byte 0x00
	.byte 0xd5, 0xd5, 0xd5  ; "ÕÕÕ"
	.byte 0x00
	.byte 0xd6, 0xd6, 0xd6  ; "ÖÖÖ"
	.byte 0x00
	.byte 0xd7, 0xd7, 0xd7  ; "×××"
	.byte 0x00
	.byte 0xd8, 0xd8, 0xd8  ; "ØØØ"
	.byte 0x00
	.byte 0xd9, 0xd9, 0xd9  ; "ÙÙÙ"
	.byte 0x00
	.byte 0xda, 0xda, 0xda  ; "ÚÚÚ"
	.byte 0x00
	.byte 0xdb, 0xdb, 0xdb  ; "ÛÛÛ"
	.byte 0x00
	.byte 0xdc, 0xdc, 0xdc  ; "ÜÜÜ"
	.byte 0x00
	.byte 0xdd, 0xdd, 0xdd  ; "ÝÝÝ"
	.byte 0x00
	.byte 0xde, 0xde, 0xde  ; "ÞÞÞ"
	.byte 0x00
	.byte 0xdf, 0xdf, 0xdf  ; "ßßß"
	.byte 0x00
	.byte 0xe0, 0xe0, 0xe0  ; "ààà"
	.byte 0x00
	.byte 0xe1, 0xe1, 0xe1  ; "ááá"
	.byte 0x00
	.byte 0xe2, 0xe2, 0xe2  ; "âââ"
	.byte 0x00
	.byte 0xe3, 0xe3, 0xe3  ; "ããã"
	.byte 0x00
	.byte 0xe4, 0xe4, 0xe4  ; "äää"
	.byte 0x00
	.byte 0xe5, 0xe5, 0xe5  ; "ååå"
	.byte 0x00
	.byte 0xe6, 0xe6, 0xe6  ; "æææ"
	.byte 0x00
	.byte 0xe7, 0xe7, 0xe7  ; "ççç"
	.byte 0x00
	.byte 0xe8, 0xe8, 0xe8  ; "èèè"
	.byte 0x00
	.byte 0xe9, 0xe9, 0xe9  ; "ééé"
	.byte 0x00
	.byte 0xea, 0xea, 0xea  ; "êêê"
	.byte 0x00
	.byte 0xeb, 0xeb, 0xeb  ; "ëëë"
	.byte 0x00
	sla	xix, 0xec
	.byte 0x00
	sra	xiy, 0xed
	.byte 0x00
	sll	xiz, 0xee
	.byte 0x00
	srl	xsp, 0xef
	.byte 0x00
	.byte 0xf0, 0xf0, 0xf0  ; "ððð"
	.byte 0x00
	.byte 0xf1, 0xf1, 0xf1  ; "ñññ"
	.byte 0x00
	.byte 0xf2, 0xf2, 0xf2  ; "òòò"
	.byte 0x00
	.byte 0xf3, 0xf3, 0xf3  ; "óóó"
	.byte 0x00
	.byte 0xf4, 0xf4, 0xf4  ; "ôôô"
	.byte 0x00
	.byte 0xf5, 0xf5, 0xf5  ; "õõõ"
	.byte 0x00
	.byte 0xf6, 0xf6, 0xf6  ; "ööö"
	.byte 0x00
	.byte 0xf7, 0xf7, 0xf7  ; "÷÷÷"
	.byte 0x00
	.byte 0xf8, 0xf8, 0xf8  ; "øøø"
	.byte 0x00
	.byte 0xf9, 0xf9, 0xf9  ; "ùùù"
	.byte 0x00
	.byte 0xfa, 0xfa, 0xfa  ; "úúú"
	.byte 0x00
	.byte 0xfb, 0xfb, 0xfb  ; "ûûû"
	.byte 0x00
	.byte 0xfc, 0xfc, 0xfc  ; "üüü"
	.byte 0x00
	.byte 0xfd, 0xfd, 0xfd  ; "ýýý"
	.byte 0x00
	.byte 0xfe, 0xfe, 0xfe  ; "þþþ"
	.byte 0x00
	.byte 0xff
	.fill 2, 1, 0xff
	.zero 44

HDAE5000_Path_Strings:	; 0x2E348F
	; File path and config strings
	.asciz ")BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB)"
	.asciz "BZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZB"
	.asciz "BZ{{{{"
	.zero 2
	.asciz "{{"
	.zero 4
	.asciz "{{"
	.zero 2
	.asciz "{{{"
	.zero 3
	.asciz "{{{"
	.zero 3
	.asciz "{{{{ZB"
	.ascii "BZ"
	sub	(xix-83), iy
	.byte 0x00
	.byte 0xf7, 0xf7, 0xf7  ; "÷÷÷"
	.byte 0x00
	cp	xsp, (xiy-9)
	.byte 0x00
	.byte 0xf7, 0xf7, 0xad  ; "÷÷­"
	.byte 0x00
	.byte 0xf7, 0xf7, 0xf7  ; "÷÷÷"
	.byte 0x00
	.byte 0xad, 0xad  ; "­­"
	.byte 0x00
	.byte 0xf7, 0xf7, 0xf7  ; "÷÷÷"
	.byte 0x00
	.byte 0xad, 0xad  ; "­­"
	.byte 0x00
	.byte 0xf7, 0xf7, 0xf7, 0xad, 0xad, 0xad  ; "÷÷÷­­­"
	.asciz "{kB"
	.ascii "BZ{"
	.byte 0xc6, 0xc6  ; "ÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6, 0xf7, 0xc6, 0xc6, 0xc6  ; "ÆÆÆ÷ÆÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6  ; "ÆÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6  ; "ÆÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6  ; "ÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6  ; "ÆÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6  ; "ÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6, 0xc6, 0xc6, 0xb5  ; "ÆÆÆÆÆµ"
	.asciz "{ZB"
	.ascii "BZ{"
	.byte 0xde, 0xde, 0xf7  ; "ÞÞ÷"
	.byte 0x00
	.zero 2
	.byte 0xde, 0xde, 0xde, 0xde  ; "ÞÞÞÞ"
	.byte 0x00
	.byte 0xde, 0xde, 0xde  ; "ÞÞÞ"
	.byte 0x00
	.byte 0xde, 0xde, 0xde  ; "ÞÞÞ"
	.byte 0x00
	cps	iz, 6
	.byte 0x00
	.byte 0xde, 0xde, 0xde  ; "ÞÞÞ"
	.byte 0x00
	cps	iz, 6
	.byte 0x00
	.zero 2
	.byte 0xde, 0xde, 0xde, 0xc6  ; "ÞÞÞÆ"
	.asciz "{ZB"
	.ascii "BZ{"
	.byte 0xef, 0xef, 0xef, 0xf7, 0xf7, 0xf7  ; "ïïï÷÷÷"
	.byte 0x00
	srl	xsp, 0xef
	.byte 0x00
	srl	xsp, 0xef
	.byte 0x00
	srl	xsp, 0xef
	.byte 0x00
	.byte 0xef, 0xef  ; "ïï"
	.byte 0x00
	.zero 3
	.byte 0xf7, 0xef, 0xef  ; "÷ïï"
	.byte 0x00
	.byte 0xf7, 0xf7, 0xef, 0xef, 0xef, 0xc6  ; "÷÷ïïïÆ"
	.asciz "{ZB"
	.ascii ")Z{"
	.byte 0xd6, 0xd6, 0xd6, 0xd6, 0xd6, 0xd6  ; "ÖÖÖÖÖÖ"
	.byte 0x00
	.byte 0xd6, 0xd6, 0xd6  ; "ÖÖÖ"
	.byte 0x00
	.byte 0xd6, 0xd6, 0xd6  ; "ÖÖÖ"
	.byte 0x00
	.byte 0xd6, 0xd6, 0xd6  ; "ÖÖÖ"
	.byte 0x00
	.byte 0xd6, 0xd6  ; "ÖÖ"
	.byte 0x00
	.byte 0xf7  ; "÷"
	.byte 0x00
	.byte 0xf7, 0xd6, 0xd6, 0xd6  ; "÷ÖÖÖ"
	.byte 0x00
	.byte 0xd6, 0xd6, 0xd6, 0xd6, 0xd6, 0xc6  ; "ÖÖÖÖÖÆ"
	.asciz "{k)"
	.ascii "BZk"
	.byte 0xc6, 0xc6  ; "ÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6  ; "ÆÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6  ; "ÆÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6  ; "ÆÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6  ; "ÆÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6  ; "ÆÆ"
	.byte 0x00
	.byte 0xc6, 0xf7  ; "Æ÷"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6  ; "ÆÆÆ"
	.byte 0x00
	.byte 0xc6, 0xc6, 0xc6, 0xc6, 0xc6, 0xb5  ; "ÆÆÆÆÆµ"
	.asciz "{Z)"
	.ascii ")Z{"
	cp	xsp, (xiy-83)
	.byte 0x00
	.zero 2
	.byte 0xf7, 0xad, 0xad, 0xad  ; "÷­­­"
	.byte 0x00
	.byte 0xad, 0xad, 0xad, 0xf7  ; "­­­÷"
	.byte 0x00
	.zero 2
	.byte 0xf7, 0xad, 0xad  ; "÷­­"
	.byte 0x00
	cp	xsp, (xiy-83)
	.byte 0x00
	.byte 0xad, 0xad  ; "­­"
	.byte 0x00
	.zero 3
	sub	(xiy-83), xiy
	.asciz "{Z)"
	.ascii ")Z{"
	.byte 0x9c, 0x9c, 0x9c, 0xf7, 0xf7, 0xf7, 0x9c, 0x9c, 0x9c, 0x9c, 0xf7, 0x9c, 0x9c, 0x9c, 0x9c, 0xf7, 0xf7, 0xf7, 0x9c, 0x9c, 0x9c, 0xf7, 0x9c, 0x9c, 0x9c, 0xf7, 0x9c, 0x9c, 0xf7, 0xf7, 0xf7, 0xf7, 0x9c, 0x9c, 0x8c  ; "÷÷÷÷÷÷÷÷÷÷÷÷÷"
	.asciz "{Z)"

HDAE5000_UI_Icons:	; 0x2E365D
	; UI icon/pattern data with language IDs
	.asciz ")Bkk{{{kk{k{{kkk{{kkk{{kkkk{{kk{kkkkkkkB)"
	.asciz ")B)B))))))B)B)B))))B)BB)BB)B)))B)B)BB)))B"
	.zero 41
	.asciz "AcLanguage1"
	.asciz "LANENG00"
	.byte 0x00
	.asciz "LANDEU00"
	.byte 0x00
	.asciz "LANFRA00"
	.byte 0x00

HDAE5000_Multilingual_Messages:	; 0x2E3704
	; Trilingual UI messages (EN/DE/FR)
	.asciz "Would you really delete the selected directory?"
	.asciz "Moechten Sie das angewaehlte Verzeichnis wirklich loeschen?"
	.ascii "Voulez-vous effacer ce r"
	.byte 0xe9  ; "é"
	.asciz "pertoir?"
	.asciz "Would you really delete the selected title?"
	.asciz "Moechten Sie den angewaehlten Titel wirklich loeschen?"
	.byte 0x00
	.asciz "Voulez-vous effacer ce titre?"
	.asciz "COPY FD TO HARD DISK"
	.byte 0x00
	.asciz "COPY FD TO HARD DISK"
	.byte 0x00
	.asciz "COPY FD TO HARD DISK"
	.byte 0x00
	.asciz "OUTPUT SETTING"
	.byte 0x00
	.asciz "OUTPUT SETTING"
	.byte 0x00
	.asciz "OUTPUT SETTING"
	.byte 0x00
	.asciz "SELECT BY   NAME    "
	.byte 0x00
	.asciz "SELECT BY   NAME    "
	.byte 0x00
	.asciz "SELECT BY   NAME    "
	.byte 0x00
	.asciz "LOAD BY     NUMBER"
	.byte 0x00
	.asciz "LOAD BY     NUMBER"
	.byte 0x00
	.asciz "LOAD BY     NUMBER"
	.byte 0x00
	.asciz "SELECT FILE LOAD SCRIPT"
	.asciz "SELECT FILE LOAD SCRIPT"
	.asciz "SELECT FILE LOAD SCRIPT"
	.asciz "WRITE PROTECT: "
	.asciz "WRITE PROTECT: "
	.asciz "WRITE PROTECT: "
	.asciz "WRITE CONFIRM: "
	.asciz "WRITE CONFIRM: "
	.asciz "WRITE CONFIRM: "
	.asciz "ABOUT & HELP "
	.asciz "ABOUT & HELP "
	.asciz "ABOUT & HELP "
	.asciz "SAVE SETUP"
	.byte 0x00
	.asciz "SAVE SETUP"
	.byte 0x00
	.asciz "SAVE SETUP"
	.byte 0x00
	.asciz "OUTPUT SETTING"
	.byte 0x00
	.asciz "OUTPUT SETTING"
	.byte 0x00
	.asciz "OUTPUT SETTING"
	.byte 0x00
	.asciz "SEPARATE OUTPUT MODE:"
	.asciz "SEPARATE OUTPUT MODE:"
	.asciz "SEPARATE OUTPUT MODE:"
	.asciz "PART SELECT FOR SEQ.DRUMS OUT:"
	.byte 0x00
	.asciz "PART SELECT FOR SEQ.DRUMS OUT:"
	.byte 0x00
	.asciz "PART SELECT FOR SEQ.DRUMS OUT:"
	.byte 0x00
	.asciz "PART SELECT FOR SEQ.BASS  OUT:"
	.byte 0x00
	.asciz "PART SELECT FOR SEQ.BASS  OUT:"
	.byte 0x00
	.asciz "PART SELECT FOR SEQ.BASS  OUT:"
	.byte 0x00
	.asciz "! The separate outputs cannot be controlled by the internal volume control."
	.asciz "! Die separaten Ausgaenge werden nicht durch Volumen am Keyboard kontrolliert."
	.byte 0x00
	.ascii "! Les sortie s"
	.byte 0xe9  ; "é"
	.ascii "par"
	.byte 0xe9  ; "é"
	.ascii "es ne peuvent pas "
	.byte 0xea  ; "ê"
	.ascii "tre control"
	.byte 0xe9  ; "é"
	.asciz "es par les volume du calvier."
	.asciz "Hardware and software developement:"
	.asciz "Hardware und Software Entwicklung:"
	.byte 0x00
	.asciz "Hardware et Software developement:"
	.byte 0x00
	.asciz "Conception, marketing, sales and service:"
	.asciz "Konzeption, Marketing, Verkauf und Service:"
	.asciz "Conception, Marketing, Vente et Service:"
	.byte 0x00
	.asciz "All rigths reserved by the called companies"
	.asciz "Alle Rechte bei den obengenannten Firmen"
	.byte 0x00
	.asciz "All rigths reserved by the called companies"
	.asciz "Special thanks to:"
	.byte 0x00
	.asciz "Spezieller Dank an:"
	.asciz "Special thanks to:"
	.byte 0x00
	.asciz "Press 3 digits for directory and 2 digits for the file."
	.asciz "Geben Sie 3 Ziffern fuer das Verzeichnis und 2 Ziffern fuer den Titel ein."
	.byte 0x00
	.ascii "Introduisez 3 chiffres pour le r"
	.byte 0xe9  ; "é"
	.asciz "pertoir at 2 chiffres pour le titre."
	.asciz "Do you really want to overwrite this FLS entry?"
	.asciz "Wollen Sie den bestehenden FLS Eintrag wirklich ueberschreiben?"
	.ascii "Voulez-vous vraiment "
	.byte 0xe9  ; "é"
	.asciz "crire par dessus le FLS?"
	.byte 0x00
	.asciz "Do you really want to delete this FLS entry?"
	.byte 0x00
	.asciz "Wollen Sie den bestehenden FLS Eintrag wirklich loeschen?"
	.asciz "Voulez-vous vraiment effacer ce FLS?"
	.byte 0x00
	.asciz "HD FORMAT will erase all files at once."
	.asciz "HD FORMAT loescht alle Daten auf der Festplatte."
	.byte 0x00
	.ascii "HD-FORMAT effacera toutes les donn"
	.byte 0xe9  ; "é"
	.asciz "es de votre disque dur."
	.byte 0x00
	.asciz "Therefore you need a 6-digit key code. Please refer your owners manual chapter SETUP & TOOLS."
	.asciz "Geben Sie auf dieser Seite den 6-stelligen Code ein. Schauen Sie in der Anleitung unter SETUP & TOOLS nach."
	.ascii "Indroduisez le code "
	.byte 0xe0  ; "à"
	.ascii " 6 chiffres et r"
	.byte 0xe9  ; "é"
	.ascii "f"
	.byte 0xe9  ; "é"
	.ascii "rez-vous "
	.byte 0xe0  ; "à"
	.asciz " votre manuel dans (SETUP & TOOLS)."
	.asciz "After your code input all data will be deleted irrevocable!"
	.asciz "Nach der Codeeingabe werden alle Daten unwiderruflich geloescht!"
	.byte 0x00
	.ascii "Apr"
	.byte 0xe8  ; "è"
	.ascii "s l'introduction du code, toutes les donn"
	.byte 0xe9  ; "é"
	.ascii "es seront effac"
	.byte 0xe9  ; "é"
	.asciz "es."
	.asciz "You are going to delete a FLS entry. Are you sure?"
	.byte 0x00
	.asciz "Sie haben einen FLS Eintrag zum Loeschen markiert. Sind Sie sicher?"
	.asciz "Vous avez marquer un FLS connection pour effacer. Vous ait sure?"
	.byte 0x00
	.asciz "You are going to overwrite a FLS entry. Are you sure?"
	.asciz "Sie ueberschreiben eine bestehenden FLS Eintrag. Sind Sie sicher?"
	.asciz "Voulez-vous vraiment transcrire ce FLS enregistration?"
	.byte 0x00
	.asciz "The hard disk is write protected!"
	.ascii "Die Festplatte ist schreibgesch"
	.byte 0xfc  ; "ü"
	.asciz "tzt!"
	.byte 0x00
	.ascii "Le disque dur est prot"
	.byte 0xe9  ; "é"
	.ascii "ger contre l'"
	.byte 0xe9  ; "é"
	.asciz "ctriture!"
	.byte 0x00
	.asciz "Please set the write protect mode to OFF."
	.asciz "Schalten Sie WRITE PROTECT im SETUP & TOOLS auf OFF."
	.byte 0x00
	.ascii "Pour "
	.byte 0xe9  ; "é"
	.asciz "crire mettez la protection sur OFF."
	.asciz "The hard disk is not formatted!"
	.asciz "Die Festplatte ist nicht formatiert!"
	.byte 0x00
	.ascii "Le disque dur n'est pas format"
	.byte 0xe9  ; "é"
	.asciz "."
	.byte 0x00
	.asciz "Hard disk SRAM error."
	.asciz "Im HD-AE5000 SRAM ist ein Fehler aufgetreten."
	.asciz "Il y a un problem avec le SRAM de HD-AE5000."
	.byte 0x00
	.asciz "Hard disk reset error."
	.byte 0x00
	.asciz "Die Festplatte konnte nicht initialisiert werden."
	.asciz "Votre disque dur n'est pas reconnu."
	.asciz "Hard disk read error."
	.asciz "Beim Lesen der Festplatte ist ein Fehler aufgetreten."
	.ascii "Il y a un probl"
	.byte 0xe9  ; "é"
	.asciz "me de leture du disque."
	.asciz "Hard disk ID read error."
	.byte 0x00
	.asciz "Die ID der Festplatte konnte nicht gelesen werden."
	.byte 0x00
	.ascii "L'ID du disque dur n'a pas pu "
	.byte 0xea  ; "ê"
	.asciz "tre lue."
	.asciz "Hard disk track 0 error."
	.byte 0x00
	.asciz "Track O der Festplatte konnte nicht gelesen werden."
	.ascii "La piste 0 du disque dur n'a pas pu "
	.byte 0xea  ; "ê"
	.asciz "tre lue."
	.asciz "Hard disk FAT read error."
	.asciz "Die FAT der Festplatte konnte nicht gelesen werden."
	.ascii "Le FAT du disque dur n'a pas pu "
	.byte 0xea  ; "ê"
	.asciz "tre lue."
	.asciz "Hard disk FSB read error."
	.asciz "Der FSB der Festplatte konnte nicht gelesen werden."
	.ascii "Le FSB du disque dur n'a pas pu "
	.byte 0xea  ; "ê"
	.asciz "tre lue."
	.asciz "There are no files marked for copy to HD!"
	.asciz "Es wurden keine Titel zum Kopieren gefunden."
	.byte 0x00
	.ascii "Aucun titre n'a "
	.byte 0xe9  ; "é"
	.ascii "t"
	.byte 0xe9  ; "é"
	.ascii " marqu"
	.byte 0xe9  ; "é"
	.asciz " pour faire des copies."
	.asciz "Please make a safety backup of your data and call your service center."
	.byte 0x00
	.asciz "Sichern Sie alle Ihre Daten auf Diskette oder den PC und rufen Sie Ihre Service-Stelle an."
	.byte 0x00
	.ascii "Sauvez vos donn"
	.byte 0xe9  ; "é"
	.asciz "e sur disquette ou l'ordinateur et contactez votre service assistance."
	.byte 0x00
	.asciz "Please make a safety backup of your data and call your service center."
	.byte 0x00
	.asciz "Sichern Sie alle Ihre Daten auf Diskette oder den PC und rufen Sie Ihre Service-Stelle an."
	.byte 0x00
	.ascii "Sauvez vos donn"
	.byte 0xe9  ; "é"
	.asciz "e sur disquette ou l'ordinateur et contactez votre service assistance."
	.byte 0x00
	.asciz "The data on the disk you would like to copy to HD has no KN5000 format or some data are corrupted."
	.byte 0x00
	.asciz "Die Daten auf der Diskette die Sie kopieren moechten, haben keine KN5000 ID oder sind fehlerhaft."
	.ascii "Les donn"
	.byte 0xe9  ; "é"
	.ascii "es que vous voulez charger ne sont pas du KN5000 format ou ont des d"
	.byte 0xe9  ; "é"
	.asciz "faults."
	.asciz "The number or marked songs cannot fit in the free space of the selected directory."
	.byte 0x00
	.asciz "Im gewuenschten Verzeichnis sind nicht genuegend freie Plaetze fuer die Anzahl markierter Titel."
	.byte 0x00
	.ascii "Le r"
	.byte 0xe9  ; "é"
	.ascii "pertoir est satur"
	.byte 0xe9  ; "é"
	.ascii ", il n'y "
	.byte 0xe0  ; "à"
	.asciz " plus de place pour d'autres titre."
	.byte 0x00
	.asciz "Reduce the number of selected songs or find a free directory."
	.asciz "Reduzieren Sie die Zahl der Titel oder waehlen Sie ein anderes Verzeichnis."
	.ascii "Changer de r"
	.byte 0xe9  ; "é"
	.asciz "pertoire ou supprimez des titres."
	.byte 0x00
	.asciz "You cannot copy files/songs to an unnamed directory."
	.byte 0x00
	.asciz "Kopieren Sie keine Titel in ein nicht beschriftetes Verzeichnis."
	.byte 0x00
	.ascii "Vous ne pouvez pas copier des titres dans un r"
	.byte 0xe9  ; "é"
	.ascii "pertoire pas pr"
	.byte 0xe9  ; "é"
	.ascii "par"
	.byte 0xe9  ; "é"
	.asciz "."
	.byte 0x00
	.asciz "Please use a named directory or create the new directory with EDIT first."
	.asciz "Waehlen Sie ein bereits beschriftetes Verzeichnis oder benennen Sie es zuvor mit EDIT."
	.byte 0x00
	.asciz "Nommez-le d'abord par example avec EDIT."
	.byte 0x00
	.asciz "The DIR number is out of range."
	.asciz "Sie haben eine ungueltige Verzeichnis Nummer eingegeben."
	.byte 0x00
	.ascii "Le r"
	.byte 0xe9  ; "é"
	.asciz "pertoire choisi n'existe pas."
	.byte 0x00
	.asciz "The file number is out of range."
	.byte 0x00
	.asciz "Die eingegebene Nummer existiert nicht."
	.asciz "Le titre choisi n'existe pas."
	.asciz "Please wait ..."
	.asciz "Bitte warten ..."
	.byte 0x00
	.asciz "Attendre S.V.P."
	.asciz "!FORMAT ERROR!"
	.byte 0x00
	.asciz "!FORMAT FEHLER!"
	.asciz "!FORMAT ERREUR!"
	.asciz "The automatic HD format was not successful!"
	.asciz "Die Formatierung war nicht erfolgreich!"
	.asciz "Le formatage du disque dur n'a pas pu se faire correctement!"
	.byte 0x00
	.asciz "Please try once more, refer your owners manual or ask your dealer/service center."
	.asciz "Versuchen Sie es nochmals, schauen Sie in der Anleitung nach oder rufen Sie Ihre Service-Stelle an."
	.ascii "R"
	.byte 0xe9  ; "é"
	.ascii "p"
	.byte 0xe9  ; "é"
	.ascii "tez l'operation en vous r"
	.byte 0xe9  ; "é"
	.ascii "f"
	.byte 0xe9  ; "é"
	.ascii "rent au manuel ou en cas d'"
	.byte 0xe9  ; "é"
	.asciz "chec, contactez votre service assistance."
	.asciz "Input error!"
	.byte 0x00
	.asciz "Eingabe-Fehler!"
	.asciz "Erreur d'operation!"
	.asciz "The key code input was wrong!"
	.asciz "Die Nummerneingabe war falsch!"
	.byte 0x00
	.asciz "Le cocde n'est pas correct!"
	.asciz "Please try once more, refer your owners manual or ask your dealer/service center."
	.asciz "Versuchen Sie es nochmals, schauen Sie in der Anleitung nach oder rufen Sie Ihre Service-Stelle an."
	.ascii "Veuillez r"
	.byte 0xe9  ; "é"
	.ascii "p"
	.byte 0xe9  ; "é"
	.ascii "ter l'ex"
	.byte 0xe9  ; "é"
	.ascii "cution et vous r"
	.byte 0xe9  ; "é"
	.ascii "f"
	.byte 0xe9  ; "é"
	.asciz "rez au manuel ou contactez votre service assistance."
	.asciz "Delete file from hard disk:"
	.asciz "Loesche Titel von Festplatte:"
	.asciz "Effacer titre du disque dur:"
	.byte 0x00
	.asciz "The hard disk will now be formatted. This procedure can take about 2-3 minutes."
	.asciz "Die Festplatte wird nun neu formatiert. Dieser Vorgang dauert ca. 2-3 Minuten."
	.byte 0x00
	.asciz "The hard disk will now be formatted. This procedure can take about 2-3 minutes."
	.asciz "We recommend to turn ON and OFF again the power after the complete format."
	.byte 0x00
	.asciz "Wir empfehlen, nach der Formatierung das Keyboard aus und wieder einzuschalten."
	.asciz "We recommend to turn ON and OFF again the power after the complete format."
	.byte 0x00
	.asciz "Track O will be recovered:"
	.byte 0x00
	.asciz "Track 0 wird kontrolliert:"
	.byte 0x00
	.asciz "Track O will be recovered:"
	.byte 0x00
	.asciz "The FLS entry remains free."
	.asciz "Der FLS Eintrag bleibt frei."
	.byte 0x00
	.asciz "Ce FLS registartion reste libre."
	.byte 0x00
	.asciz "All following entries will be moved."
	.byte 0x00
	.asciz "Alle nachfolgenden Eintraege werden nachgeschoben."
	.byte 0x00
	.ascii "Tous les registartion suivant seront d"
	.byte 0xe9  ; "é"
	.asciz "placer."
	.byte 0x00
	.asciz "Evaluation 01-01-99"
	.asciz "Test-Version 01-01-99"
	.ascii "Version d'"
	.byte 0xe9  ; "é"
	.asciz "valuation"
	.byte 0x00
	.asciz "LYRICS LOAD MODE"
	.byte 0x00
	.asciz "LYRICS LOAD MODE"
	.byte 0x00
	.asciz "LYRICS LOAD MODE"
	.byte 0x00
	.asciz "COLOR ACTIV"
	.asciz "AKTIVE FARBE"
	.byte 0x00
	.asciz "COLOUR ACTIVE"
	.asciz "COLOR PASSIV"
	.byte 0x00
	.asciz "PASSIVE FARBE"
	.asciz "COLOUR PASSIVE"
	.byte 0x00
	.asciz "You are going to overwrite an existing entry. Are you sure?"
	.asciz "Sie ueberschreiben einen bestehenden Eintrag. Sind Sie sicher?"
	.byte 0x00
	.asciz "Vous etes en train de modifier un titre existant. Etes-vous sur?"
	.byte 0x00
	.asciz "YES"
	.asciz "JA"
	.byte 0x00
	.asciz "OUI"
	.asciz "NO"
	.byte 0x00
	.asciz "NEIN"
	.byte 0x00
	.asciz "NON"
	.asciz "OK"
	.byte 0x00
	.asciz "OK"
	.byte 0x00
	.asciz "OK"
	.byte 0x00
	.asciz "CANCEL"
	.byte 0x00
	.asciz "Abbruch"
	.asciz "CANCEL"
	.byte 0x00
	.asciz "Operation error!"
	.byte 0x00
	.asciz "Bedienungsfehler!"
	.asciz "Error d'operation!"
	.byte 0x00
	.asciz "!SAVE ERROR!"
	.byte 0x00
	.asciz "!SAVE-FEHLER!"
	.asciz "!SAVE ERREUR!"
	.asciz "!LOAD ERROR!"
	.byte 0x00
	.asciz "!LOAD-FEHLER!"
	.asciz "!LOAD ERREUR!"
	.asciz "!SYSTEM ERROR!"
	.byte 0x00
	.asciz "!SYSTEM-FEHLER!"
	.asciz "!SYSTEM ERREUR!"
	.asciz "!ATTENTION!"
	.asciz "!ACHTUNG!"
	.asciz "!ATTENTION!"
	.asciz "Press YES for confirmation, NO to abort."
	.byte 0x00
	.asciz "Bestaetigen Sie den Vorgang mit JA oder druecken Sie die NEIN Taste."
	.byte 0x00
	.asciz "Pressez OUI pour confirmer ou NON pour annuler."
	.asciz "Please call your dealer or service center."
	.byte 0x00
	.asciz "Bitte rufen Sie Ihre Service-Stelle an."
	.asciz "Contactez votre service assistance."
	.asciz "No Message"
	.zero 3
	.asciz "I"
	.byte 0x92  ; ""
	.byte 0x00
	.byte 0xdb  ; "Û"
	.byte 0x00
	.byte 0x24
	.byte 0x01
	.ascii "m"
	.byte 0x01
	.byte 0xb6  ; "¶"
	.byte 0x01
	.byte 0xff
	.byte 0x01
	popw wa
	.byte 0x02
	.byte 0x91  ; ""
	.byte 0x02
	.byte 0xda  ; "Ú"
	.byte 0x02
	.byte 0x23
	.byte 0x03
	.ascii "l"
	.byte 0x03
	.byte 0xb5  ; "µ"
	.byte 0x03
	.byte 0xfe  ; "þ"
	.byte 0x03
	.byte 0x47
	.byte 0x04
	.byte 0x90  ; ""
	.byte 0x04
	.byte 0xd9  ; "Ù"
	.byte 0x04
	.byte 0x22
	.byte 0x05
	.ascii "k"
	.byte 0x05
	.byte 0xb4  ; "´"
	.byte 0x05
	.byte 0xfd  ; "ý"
	.byte 0x05
	.byte 0x46
	.byte 0x06
	.byte 0x8f  ; ""
	.byte 0x06
	.byte 0xd8  ; "Ø"
	.byte 0x06
	.byte 0x21
	.byte 0x07
	.ascii "j"
	.byte 0x07
	.byte 0xb3  ; "³"
	.byte 0x07
	.byte 0xfc  ; "ü"
	.byte 0x07
	.byte 0x45
	.byte 0x08
	.byte 0x8e  ; ""
	.byte 0x08
	.byte 0xd7  ; "×"
	.byte 0x08
	.ascii " "
	.byte 0x09
	.ascii "i"
	.byte 0x09
	.byte 0xb2  ; "²"
	.byte 0x09
	.byte 0xfb  ; "û"
	.byte 0x09
	.byte 0x44
	.byte 0x0a
	.byte 0x8d  ; ""
	.byte 0x0a
	.byte 0xd6  ; "Ö"
	.byte 0x0a, 0x1f, 0x0b
	.ascii "h"
	.byte 0x0b
	.byte 0xb1  ; "±"
	.byte 0x0b
	.byte 0xfa  ; "ú"
	.byte 0x0b
	.byte 0x43
	.byte 0x0c
	.byte 0x8c  ; ""
	.byte 0x0c
	.byte 0xd5  ; "Õ"
	.byte 0x0c, 0x1e, 0x0d
	.ascii "g"
	.byte 0x0d
	.byte 0xb0  ; "°"
	.byte 0x0d
	.byte 0xf9  ; "ù"
	.byte 0x0d
	.byte 0x42
	.byte 0x0e
	.byte 0x8b  ; ""
	.byte 0x0e
	.byte 0xd4  ; "Ô"
	.byte 0x0e, 0x1d, 0x0f
	.ascii "f"
	.byte 0x0f
	.byte 0xaf  ; "¯"
	.byte 0x0f
	.byte 0xf8  ; "ø"
	.byte 0x0f
	.byte 0x41
	.byte 0x10
	.byte 0x8a  ; ""
	.byte 0x10
	.byte 0xd3  ; "Ó"
	.byte 0x10, 0x1c, 0x11
	.ascii "e"
	.byte 0x11
	.byte 0xf1  ; "ñ"
	.byte 0x15
	.byte 0xae  ; "®"
	.byte 0x11
	.byte 0xf7  ; "÷"
	.byte 0x11
	.byte 0x40
	.byte 0x12
	.byte 0x89  ; ""
	.byte 0x12
	.byte 0xd2  ; "Ò"
	.byte 0x12, 0x1b, 0x13
	.ascii "d"
	.byte 0x13
	.byte 0xad  ; "­"
	.byte 0x13
	.byte 0xf1  ; "ñ"
	.byte 0x15
	.byte 0xf1  ; "ñ"
	.byte 0x15
	.byte 0xf6  ; "ö"
	.byte 0x13
	.byte 0x3f
	.byte 0x14
	.byte 0x88  ; ""
	.byte 0x14
	.byte 0xd1  ; "Ñ"
	.byte 0x14, 0x1a, 0x15
	.ascii "c"
	.byte 0x15
	.byte 0xaa  ; "ª"
	.byte 0x15

HDAE5000_Lang_Codes:	; 0x2E5B80
	; Language code strings and file types
	.asciz "                                        "
	.byte 0x00
	.asciz "Reset"
	.asciz "Load"
	.byte 0x00
	.asciz "%03i - %i "
	.zero 3
	.asciz "}"
	.asciz "}"
	.asciz "}"
	.asciz "}"
	.asciz "}"
	.asciz "}"
	.asciz "D"
	.byte 0xaa  ; "ª"
	.byte 0x00
	.byte 0xb0  ; "°"
	.byte 0x06, 0x10, 0x07
	.byte 0xa2  ; "¢"
	.byte 0x05
	pushw bc
	.byte 0x02
	.byte 0xc5  ; "Å"
	.byte 0x02
	.byte 0x3b
	.byte 0x05
	.asciz "rb"
	.byte 0x00
	.asciz "TESTTEST.TLX"
	.byte 0x00
	.asciz "Fault : No Lyrics loaded or corrupt Data - Code %i %i %i     "
	.asciz " %i/%i "
	.asciz "Chord : %s               "
	.asciz "Info :                            "
	.byte 0x00
	.asciz "No Copyright Info"
	.asciz "No Song Title"
	.asciz " %i/%i "
	.zero 4
	.asciz "TLhd"
	.byte 0x00
	.asciz "TLtr"
	.zero 3
	.asciz "                           "
	.asciz "                           "
	.asciz "mid"
	.asciz "   "
	.asciz "                                                 "
	.asciz "%s %s"
	.asciz "%s %s"
	.asciz ".TLX"
	.byte 0x00
	.asciz "rb"
	.zero 3
	.byte 0x03, 0x03, 0x03, 0x03, 0x02, 0x02
	.zero 2
	.byte 0x01, 0x01, 0x01, 0x01, 0x02, 0x02
	.byte 0xe9  ; "é"
	.byte 0x01
	.byte 0x95  ; ""
	.byte 0x00
	.byte 0x1e, 0x01
	.zero 2
	.asciz " ->"
	.asciz "*.*"
	.asciz ".TTX"
	.byte 0x00
	.asciz "rb"
	.byte 0x00
	.asciz ".MID"
	.byte 0x00
	.asciz "rb"
	.byte 0x00
	.asciz "XLT."
	.byte 0x00
	.byte 0xbc  ; "¼"
	.asciz "]."
	.byte 0xb2  ; "²"
	.asciz "]."
	.byte 0xa8  ; "¨"
	.asciz "]."
	.byte 0x9e  ; ""
	.asciz "]."
	.byte 0x94  ; ""
	.asciz "]."
	.byte 0x8a  ; ""
	.asciz "]."
	.asciz "LANENG006"
	.asciz "LANENG005"
	.asciz "LANENG004"
	.asciz "LANFRA003"
	.asciz "LANDEU002"
	.asciz "LANENG001"
	.asciz "XAP"
	.asciz "rb"
	.byte 0x00

HDAE5000_Palette_Data:	; 0x2E5DCE
	; VGA palette data (256 entries)
	.incbin "includes/code_29af2d_2fffff.bin", 306849, 77824

HDAE5000_Display_Params:	; 0x2F8DCE
	; Display configuration parameters
	.asciz "HD-AE5000"
	.zero 8
	.asciz "                "
	.byte 0x00
	.asciz "                "
	.byte 0x00
	.asciz "                          "
	.byte 0x00
	.byte 0x98, 0x8e
	.asciz "/"
	.byte 0x04
	.byte 0x00
	.byte 0x02
	.byte 0x00
	add	(xix), iz
	.asciz "/"
	.zero 2
	.byte 0x02
	.byte 0x00
	add	(xwa), iz
	.asciz "/"
	.byte 0x05
	.byte 0x00
	.byte 0x02
	.byte 0x00
	.byte 0x8c, 0x8e
	.asciz "/"
	.zero 2
	.byte 0x03
	.byte 0x00
	.ascii "z"
	.byte 0x8e
	.asciz "/"
	.zero 2
	.byte 0x10
	.byte 0x00
	.ascii "v"
	.byte 0x8e
	.asciz "/"
	.zero 2
	.byte 0x03
	.byte 0x00
	.ascii "r"
	.byte 0x8e
	.asciz "/"
	.zero 2
	.byte 0x03
	.byte 0x00
	.ascii "n"
	.byte 0x8e
	.asciz "/"
	.zero 2
	.byte 0x02
	.byte 0x00
	.ascii "h"
	.byte 0x8e
	.asciz "/"
	.zero 2
	.byte 0x04
	.byte 0x00
	.asciz "TLhd"
	.byte 0x00
	.asciz "HK"
	.byte 0x00
	.asciz "H"
	.asciz "K"
	.asciz "H"
	.asciz "K"
	.asciz "KN5000 SOUND RAM"
	.byte 0x00
	.asciz "H"
	.asciz "K"
	.byte 0x01, 0x08
	.zero 2
	.asciz "HK"
	.byte 0x00
	.asciz "HK"
	.byte 0x00
	.asciz ".SEQ"
	.byte 0x00
	.asciz ".SQF"
	.byte 0x00
	.asciz ".LSW"
	.byte 0x00
	.asciz "rb"
	.byte 0x00
	.asciz ".PMT"
	.byte 0x00
	.asciz "rb"
	.byte 0x00
	.asciz ".SQT"
	.byte 0x00
	.asciz "rb"
	.byte 0x00
	.asciz ".CMP"
	.byte 0x00
	.asciz "rb"
	.byte 0x00
	.asciz ".TM"
	.asciz "rb"
	.byte 0x00
	.asciz ".MSP"
	.byte 0x00
	.asciz "rb"
	.byte 0x00
	.asciz ".RCM"
	.byte 0x00
	.asciz "rb"
	.byte 0x00
	.asciz ".MD"
	.asciz "rb"
	.byte 0x00
	.asciz ".TLX"
	.byte 0x00
	.asciz "rb"
	.byte 0x00
	.asciz ".TTX"
	.byte 0x00
	.asciz "rb"
	.byte 0x00
	.asciz ".LSW"
	.byte 0x00
	.asciz "rb"
	.byte 0x00
	.asciz ".PMT"
	.byte 0x00
	.asciz "rb"
	.byte 0x00
	.asciz ".SQT"
	.byte 0x00
	.asciz "rb"
	.byte 0x00
	.asciz ".CMP"
	.byte 0x00
	.asciz "rb"
	.byte 0x00
	.asciz ".TM"
	.asciz "rb"
	.byte 0x00
	.asciz ".MSP"
	.byte 0x00
	.asciz "rb"
	.byte 0x00
	.asciz ".RCM"
	.byte 0x00
	.asciz "rb"
	.byte 0x00
	.asciz ".MD"
	.asciz "rb"
	.byte 0x00
	.asciz ".TLX"
	.byte 0x00
	.asciz "rb"
	.byte 0x00
	.asciz "---[ GetInfoBlockPointer ]---"
	.asciz "ppib adr = %lx"
	.byte 0x00
	.asciz " "
	.asciz "---[ TurnHdMotorOff ]---"
	.byte 0x00
	.asciz " "
	.asciz "---[ SendInfosAboutHd ]---"
	.byte 0x00
	.asciz "hddname : "
	.byte 0x00
	.asciz "hddtrck : %d"
	.byte 0x00
	.asciz "hddhead : %d"
	.byte 0x00
	.asciz "hddsctr : %d"
	.byte 0x00
	.asciz "hddscby : %d"
	.byte 0x00
	.asciz " "
	.asciz "---[ SendInfosAboutDirBlock ]---"
	.byte 0x00
	.asciz "FGB ptr : %lx"
	.asciz "FGB wid : %d"
	.byte 0x00
	.asciz "FGB num : %d"
	.byte 0x00
	.asciz " "
	.asciz "---[ SendInfosAboutFileSystemBlock ]---"
	.asciz "FEB ptr : %lx"
	.asciz "FEB wid : %d"
	.byte 0x00
	.asciz "FEB num : %d"
	.byte 0x00
	.asciz " "
	.asciz "---[ SendInfosAboutFlsBlock ]---"
	.byte 0x00
	.asciz "FLS ptr : %lx"
	.asciz "FLS wid : %d"
	.byte 0x00
	.asciz "FLS num : %d"
	.byte 0x00
	.asciz "FLS ent : %d"
	.byte 0x00
	.asciz " "
	.asciz "---[ ReadDirBlockFromHd ]---"
	.byte 0x00
	.asciz " "
	.asciz "---[ ReadFileBlockFromHd ]---"
	.asciz " "
	.asciz "---[ ReadFlsBlockFromHd ]---"
	.byte 0x00
	.asciz " "
	.asciz "---[ WriteDirBlockToHd ]---"
	.asciz " "
	.asciz "---[ WriteFileSystemBlockToHd ]---"
	.byte 0x00
	.asciz " "
	.asciz "---[ WriteFlsBlockToHd ]---"
	.asciz " "
	.asciz "---[ SendInfosAboutSong ]--- "
	.asciz "dirname : %s"
	.byte 0x00
	.asciz "sngname : %s"
	.byte 0x00
	.asciz " "
	.asciz "---[ LoadSongFromHdToMemory ]---"
	.byte 0x00
	.asciz " "
	.asciz "---[ SaveSongInMemoryToHd ]---"
	.byte 0x00
	.asciz " "
	.asciz "---[ InitWholeSongInMemory ]---"
	.asciz " "
	.asciz "---[ FormatHd ]---"
	.byte 0x00
	.asciz " "
	.asciz "---[ SendPointerToFreeBufferSpace ]---"
	.byte 0x00
	.asciz "work adr : %lx"
	.byte 0x00
	.asciz " "
	.asciz "---[ PreWholeSongInMemory ]---"
	.byte 0x00
	.asciz " "
	.asciz "---[ WriteOpenHD ]--- "
	.byte 0x00
	.asciz "SUFFIX : %d"
	.asciz "---[ WriteCloseHD ]--- "
	.asciz "---[ WriteFileHD ]--- "
	.byte 0x00
	.asciz "---[ ReadOpenHD ]--- "
	.asciz "---[ ReadFileHD ]--- "
	.ascii "         (((((                  H"
	.byte 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x84
	.byte 0x84, 0x84, 0x84, 0x84, 0x84, 0x84, 0x84, 0x84, 0x84, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10
	.byte 0x81, 0x81, 0x81, 0x81, 0x81, 0x81, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
	.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10
	.byte 0x82, 0x82, 0x82, 0x82, 0x82, 0x82, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02
	.byte 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x10, 0x10, 0x10, 0x10
	.asciz " "
	.zero 129
	.byte 0x0d, 0x01, 0x8a, 0x06, 0x8a, 0x06, 0x8a, 0x06, 0xe1, 0x06, 0x0d, 0x01, 0xe1, 0x06, 0xe1, 0x06
	.byte 0xe1, 0x06, 0xe1, 0x06
	.ascii "f"
	.byte 0x06, 0x1a, 0x05, 0xaf, 0x03, 0xe1, 0x06, 0xe1, 0x06
	.asciz "i"
	.byte 0xe1, 0x06, 0xb9, 0x02, 0xe1, 0x06, 0xe1, 0x06, 0xb2, 0x03
	.asciz "0123456789abcdef"
	.byte 0x00
	.asciz "0123456789ABCDEF"
	.byte 0x00

HDAE5000_Init_Data:	; 0x2F94B2
	; Data copied to 0x23952A (0xC82 bytes)
	.incbin "includes/code_29af2d_2fffff.bin", 386437, 27470

; ============================================================================
; END OF ROM (0x300000)
; ============================================================================

end:

; Labels emitted as .set (exact addresses from ORG/name)
