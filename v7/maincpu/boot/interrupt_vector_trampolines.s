; =============================================================================
; Interrupt Vector Trampolines - TMP94C241 hardware interrupt entry points
; =============================================================================
; Each 8-byte slot corresponds to a hardware interrupt vector.
; Unused slots are filled with 0xff or contain SWI 7 (trap handler).
; A few slots contain stub code (adc, ld xiy, decf) for specific interrupts.

	.incbin "includes/romslices/v7_block_interrupt_vector_trampolines_head.bin"
	dec 6,XSP
	push XIZ
	ldw (XSP+0x04), 0xffff
	ld XIZ,XWA
	lds32 xwa, 0
	ld (XSP+0x06),XWA
	ld XHL,XIZ
	and XHL,0x000000ff
	ld XWA,XHL
	sll XWA, 0x09
	add XWA,XHL
	ld XHL,XIZ
	srl XHL, 0x08
	and XHL,0x000000ff
	add XHL,XWA
	ld XWA,XHL
	sll XWA, 0x09
	add XWA,XHL
	ld XHL,XIZ
	srl XHL, 0x00
	and XHL,0x0000001f
	add XHL,XWA
	ld XWA,XHL
	ld XBC,0x000007ff
	call 0xff0435
	ld IX,HL
	jr t, .Lc_fccce0
.Lc_fcccb4:
	lds bc, 0
	cp XIZ,XDE
	jr z, .Lc_fcccbf
	ldw BC, 0xffff
	jr t, .Lc_fccccb
.Lc_fcccbf:
	cp BC,0xffff
	jr z, .Lc_fccccb
	ld XWA,(XWA+0x04)
	ld (XSP+0x06),XWA
.Lc_fccccb:
	inc 1,HL
	cp HL,0x07ff
	jr ugt, .Lc_fcccf8
	ld WA,IX
	inc 3,WA
	extz XWA
	div WA,0x07ff
	ld IX,QWA
.Lc_fccce0:
	ld BC,IX
	extz XBC
	sll XBC, 0x03
	ld XWA,0x00034100
	add XWA,XBC
	ld XDE,(XWA)
	cp XDE,0x00ffffff
	jr nz, .Lc_fcccb4
.Lc_fcccf8:
	ld XWA,(XSP+0x06)
	or XWA,XWA
	jr z, .Lc_fccd1f
	ld A,(XWA+0x0c)
	cps a, 7
	jr nc, .Lc_fccd1f
	extz WA
	sla WA, 0x02
	lda_24 xbc, (Naka_MainDispatch_Table_0xDC0)
	lda_dri xbc, 0x07, 0xe4, 0xe0
	ld XWA,(XSP+0x06)
	ld XHL,(XBC)
	call (XHL)
	ld (XSP+0x04),HL
.Lc_fccd1f:
	ld HL,(XSP+0x04)
	pop XIZ
	inc 6,XSP
	ret
	.incbin "includes/romslices/v7_block_interrupt_vector_trampolines_tail.bin"
