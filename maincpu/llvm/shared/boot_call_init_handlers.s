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
	; (no addr) PUSH QIZ	; d7 fa 04

	; Compare init flag - encoding differs between ROMs
	; IF INIT_FLAG_COMPARE_WORD (evaluated to false for maincpu)
	; ELSE
	; maincpu: CP (0xFFFEEE), 0xFF (6 bytes)
	.byte 0xC2, 0xEE, 0xFE, 0xFF, 0x3F, 0xFF
	; ENDIF

	; (no addr) JR NZ, .done	; 6e xx (offset computed by assembler)

	; LD QIZH, 0
	.byte 0xC7, 0xFB, 0xA8

	.handler_loop:
	; LD A, QIZH
	.byte 0xC7, 0xFB, 0x89
	; EXTZ WA
	.byte 0xD8, 0x12
	; LD C, QIZH
	.byte 0xC7, 0xFB, 0x8B
	; EXTZ BC
	.byte 0xD9, 0x12
	; SLA 2, BC (multiply by 4 for 32-bit table entries)
	.byte 0xD9, 0xEC, 0x2
	; LDA XDE, 0xFFFEF0 (init handler table)
	.byte 0xF2, 0xF0, 0xFE, 0xFF, 0x32
	; LD XBC, (XDE+BC) - load handler address from table
	.byte 0xE3, 0x7, 0xE8, 0xE4, 0x21

	; Call indirect call helper (address differs between ROMs)
	; (no addr) CALL INDIRECT_CALL_HELPER

	; INC 1, QIZH
	.byte 0xC7, 0xFB, 0x61
	; CP QIZH, 4
	.byte 0xC7, 0xFB, 0xDC

	; (no addr) JR C, .handler_loop	; 67 xx (offset computed by assembler)

	.done:
	; (no addr) POP QIZ	; d7 fa 05
	; (no addr) RET	; 0e

; End of shared Boot_CallInitHandlers
