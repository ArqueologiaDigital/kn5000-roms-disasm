; =============================================================================
; Common Assembly Macros
; =============================================================================

; aligned_string - Null-terminated string with 16-bit alignment padding
; Emits the string with null terminator, then pads with 0xFF if needed
; to align the next item to an even address.
.macro aligned_string str:vararg
	.asciz \str
	.p2align 1, 0xff
.endm
