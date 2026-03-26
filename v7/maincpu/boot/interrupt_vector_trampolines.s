; =============================================================================
; Interrupt Vector Trampolines - TMP94C241 hardware interrupt entry points
; =============================================================================
; Each 8-byte slot corresponds to a hardware interrupt vector.
; Unused slots are filled with 0xff or contain SWI 7 (trap handler).
; A few slots contain stub code (adc, ld xiy, decf) for specific interrupts.

	.incbin "includes/generated/v7_block_interrupt_vector_trampolines.bin"
