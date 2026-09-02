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
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xFCD01C-0xFCD02C (16 B), unreached CODE-territory, was disassembled as 14 plausible-but-dead instruction lines; per=100% dist=5 near MidiStream_HandleRunningStatus_0x98+283
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xcb, 0xc9, 0xfc, 0x00, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff
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
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xFCD15C-0xFCD16C (16 B), unreached CODE-territory, was disassembled as 12 plausible-but-dead instruction lines; per=100% dist=5 near MidiStream_HandleRunningStatus_0x98+603
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0x45, 0xca, 0xfc, 0x00, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff
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
