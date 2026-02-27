; =============================================================================
; boot_call_init_handlers.asm - Init Handler Dispatch (Shared)
; =============================================================================
; This file contains the Boot_CallInitHandlers routine that is structurally
; identical between maincpu and table_data, with minor encoding differences.
;
; In maincpu: Located at 0xEF086F-0xEF08A3 (53 bytes)
; In table_data: Located at 0x9FB70A-0x9FB73F (54 bytes)
;
; Differences handled by conditional assembly:
;   1. Init flag comparison width:
;      - maincpu: CP (0xFFFEEE), 0xFF (byte comparison)
;      - table_data: CP (0xFFFEEE), 0xFFFF (word comparison)
;   2. Indirect call helper address:
;      - maincpu: 0xEF183D
;      - table_data: 0xFFFA75
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
; If (0xFFFEEE) == 0xFF (maincpu) or 0xFFFF (table_data), calls up to 4 init
; handlers from a table at 0xFFFEF0. Each table entry is a 32-bit address.
;
; Table at 0xFFFEF0:
;   [0] = Handler 0 address (32-bit)
;   [1] = Handler 1 address (32-bit)
;   [2] = Handler 2 address (32-bit)
;   [3] = Handler 3 address (32-bit)
;
; Entry: None
; Exit: All handlers called if init flag was set
; -----------------------------------------------------------------------------
Boot_CallInitHandlers:
	push_werp 0xFA	; d7 fa 04

	; Compare init flag - encoding differs between ROMs
	; IF INIT_FLAG_COMPARE_WORD (evaluated to false)
	; ELSE
	; maincpu: CP (0xFFFEEE), 0xFF (6 bytes)
	.byte 0xc2, 0xee, 0xfe, 0xff, 0x3f, 0xff
	; ENDIF

	jr nz, Boot_CallInitHandlers__done	; 6e xx (offset computed by assembler)

	; LD QIZH, 0
	.byte 0xc7, 0xfb, 0xa8

Boot_CallInitHandlers__handler_loop:
	; LD A, QIZH
	.byte 0xc7, 0xfb, 0x89
	; EXTZ WA
	extz	wa
	; LD C, QIZH
	.byte 0xc7, 0xfb, 0x8b
	; EXTZ BC
	extz	bc
	; SLA 2, BC (multiply by 4 for 32-bit table entries)
	.byte 0xd9, 0xec, 0x02
	; LDA XDE, 0xFFFEF0 (init handler table)
	.byte 0xf2, 0xf0, 0xfe, 0xff, 0x32
	; LD XBC, (XDE+BC) - load handler address from table
	.byte 0xe3, 0x07, 0xe8, 0xe4, 0x21

	; Call indirect call helper (address differs between ROMs)
	call 0xEF183D

	; INC 1, QIZH
	.byte 0xc7, 0xfb, 0x61
	; CP QIZH, 4
	.byte 0xc7, 0xfb, 0xdc

	jr c, Boot_CallInitHandlers__handler_loop	; 67 xx (offset computed by assembler)

Boot_CallInitHandlers__done:
	pop_werp 0xFA	; d7 fa 05
	ret	; 0e

; End of shared Boot_CallInitHandlers
