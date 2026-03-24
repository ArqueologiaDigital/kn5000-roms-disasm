; =============================================================================
; boot_call_init_handlers.asm - Init Handler Dispatch (Shared)
; =============================================================================
; This file contains the Boot_CallInitHandlers routine that is structurally
; identical between maincpu and table_data, with minor encoding differences.
;
; In maincpu: Located at 0xef086f-0xef08a3 (53 bytes)
; In table_data: Located at 0x9fb70a-0x9fb73f (54 bytes)
;
; Differences handled by conditional assembly:
;   1. Init flag comparison width:
;      - maincpu: CP (0xfffeee), 0xff (byte comparison)
;      - table_data: CP (0xfffeee), 0xffff (word comparison)
;   2. Indirect call helper address:
;      - maincpu: 0xef183d
;      - table_data: 0xfffa75
;
; Required definitions before including this file:
;   INIT_FLAG_COMPARE_WORD  - Set to 1 for word comparison (table_data)
;                             Set to 0 for byte comparison (maincpu)
;   INDIRECT_CALL_HELPER    - Address of indirect call routine
;
; =============================================================================

; -----------------------------------------------------------------------------
; Boot_CallInitHandlers - Call initialization handlers from table
;
; If (0xfffeee) == 0xff (maincpu) or 0xffff (table_data), calls up to 4 init
; handlers from a table at 0xfffef0. Each table entry is a 32-bit address.
;
; Table at 0xfffef0:
;   [0] = Handler 0 address (32-bit)
;   [1] = Handler 1 address (32-bit)
;   [2] = Handler 2 address (32-bit)
;   [3] = Handler 3 address (32-bit)
;
; Entry: None
; Exit: All handlers called if init flag was set
; -----------------------------------------------------------------------------
Boot_CallInitHandlers:
	push_werp 0xfa	; d7 fa 04

	; Compare init flag - encoding differs between ROMs
	; IF INIT_FLAG_COMPARE_WORD (evaluated to false)
	; ELSE
	; maincpu: CP (0xfffeee), 0xff (6 bytes)
	cpi8_24	0xFFFEEE, 255
	; ENDIF

	jr nz, Boot_CallInitHandlers__done	; 6e xx (offset computed by assembler)

	; LD QIZH, 0
	ldi_berp 0xfb, 0

Boot_CallInitHandlers__handler_loop:
	; LD A, QIZH
	ldto_berp a, 0xfb
	; EXTZ WA
	extz	wa
	; LD C, QIZH
	ldto_berp c, 0xfb
	; EXTZ BC
	extz	bc
	; SLA 2, BC (multiply by 4 for 32-bit table entries)
	sla	bc, 2
	; LDA XDE, 0xfffef0 (init handler table)
	lda_24	xde, 0xFFFEF0
	; LD XBC, (XDE+BC) - load handler address from table
	ld_sril3 xbc, 0x07, 0xe8, 0xe4

	; Call indirect call helper (address differs between ROMs)
	call INDIRECT_CALL_HELPER

	; INC 1, QIZH
	inc_berp 0xfb, 1
	; CP QIZH, 4
	cpi_berp 0xfb, 4

	jr c, Boot_CallInitHandlers__handler_loop	; 67 xx (offset computed by assembler)

Boot_CallInitHandlers__done:
	pop_werp 0xfa	; d7 fa 05
	ret	; 0e

; End of shared Boot_CallInitHandlers
