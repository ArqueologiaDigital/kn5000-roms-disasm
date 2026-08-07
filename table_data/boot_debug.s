; =============================================================================
; Boot-time debug output group - DISABLED IN SHIPPED FIRMWARE
; ROM 0x9FFE80-0x9FFEDF (boot-time alias 0xFFFE80-0xFFFEDF; labels are at
; ROM addresses, see the alias note in boot_clib.s).
;
; Four small character-output helpers layered on Debug_SendChar. In the
; shipped ROM the store inside Debug_SendChar has been NOP-patched out, so
; the whole group runs to completion without emitting anything. No caller
; survives in this ROM either - the group is development leftovers.
; =============================================================================

; -----------------------------------------------------------------------------
; Debug_OutputChar - emit one character (A) via Debug_SendChar
; Boot addr 0xFFFE80. Callers: none in this ROM.
; -----------------------------------------------------------------------------
Debug_OutputChar:
	push xiz
	calr Debug_SendChar
	pop xiz
	ret

; -----------------------------------------------------------------------------
; Debug_OutputHexByte - emit A as two ASCII hex digits, high nibble first
; Boot addr 0xFFFE86. Callers: none in this ROM.
; -----------------------------------------------------------------------------
Debug_OutputHexByte:
	push xiz
	ld w, a			; keep the original byte in W
	srl a, 4
	calr Debug_NibbleToHex
	pushw wa
	calr Debug_SendChar
	popw wa
	ld a, w
	and a, 0x0f
	calr Debug_NibbleToHex
	calr Debug_SendChar
	pop xiz
	ret

; -----------------------------------------------------------------------------
; Debug_OutputString - emit a NUL-terminated string
; Boot addr 0xFFFEA1.
; Inputs:  XWA = string pointer.
; Callers: none in this ROM.
; -----------------------------------------------------------------------------
Debug_OutputString:
	push xiz
	ld xix, xwa
Debug_OutputString__next:
	ldb_spi a, 0xF0		; ld A, (XIX+)
	cps a, 0
	jr z, Debug_OutputString__done
	push xix
	calr Debug_SendChar
	pop xix
	jr t, Debug_OutputString__next
Debug_OutputString__done:
	pop xiz
	ret

; -----------------------------------------------------------------------------
; Debug_NibbleToHex - convert the low nibble in A to an ASCII hex digit
; Boot addr 0xFFFEB4. 0-9 -> '0'-'9' (+0x30), 10-15 -> 'a'-'f' (+0x57).
; Callers: Debug_OutputHexByte.
; -----------------------------------------------------------------------------
Debug_NibbleToHex:
	cp a, 0x0a
	jr nc, Debug_NibbleToHex__alpha
	add a, 0x30
	ret
Debug_NibbleToHex__alpha:
	add a, 0x57
	ret

; -----------------------------------------------------------------------------
; Debug_SendChar - NOP-PATCHED STUB: emits nothing
; Boot addr 0xFFFEC1.
; Loads the debug-port address 0xFE00 into IZ, then thirteen NOPs where the
; store (and any ready-wait) used to be, then returns. The output
; instruction(s) were patched out of the shipped firmware, functionally
; disabling the entire debug group above while keeping all offsets intact.
; -----------------------------------------------------------------------------
Debug_SendChar:
	ldw iz, 0xfe00		; debug port address - never written (see above)
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
	ret

; 0xFF padding up to RESET_HANDLER at ROM 0x9FFEE0
	.fill 14, 1, 0xff
