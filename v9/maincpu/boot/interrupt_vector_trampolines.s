; =============================================================================
; Interrupt Vector Trampolines - TMP94C241 hardware interrupt entry points
; =============================================================================
; Each 8-byte slot corresponds to a hardware interrupt vector.
; Unused slots are filled with 0xff or contain SWI 7 (trap handler).
; A few slots contain stub code (adc, ld xiy, decf) for specific interrupts.

	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	adc	c, 252
	nop
	swi	7
	swi	7
	swi	7
	swi	7
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
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	decf
	.byte 0xca, 0xfc
	nop
	swi	7
	swi	7
	swi	7
	swi	7
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
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	ld	xiy, 4278254794
	swi	7
	swi	7
	swi	7
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
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 5, 1, 0xff
