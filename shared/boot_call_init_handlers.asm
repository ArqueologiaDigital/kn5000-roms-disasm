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
	PUSH	QIZ				; d7 fa 04

	; Compare init flag - encoding differs between ROMs
	IF INIT_FLAG_COMPARE_WORD
	; table_data: CP (0xFFFEEE), 0xFFFF (7 bytes)
	db	0D2h, 0EEh, 0FEh, 0FFh, 03Fh, 0FFh, 0FFh
	ELSE
	; maincpu: CP (0xFFFEEE), 0xFF (6 bytes)
	db	0C2h, 0EEh, 0FEh, 0FFh, 03Fh, 0FFh
	ENDIF

	JR	NZ, .done			; 6e xx (offset computed by assembler)

	; LD QIZH, 0
	db	0C7h, 0FBh, 0A8h

.handler_loop:
	; LD A, QIZH
	db	0C7h, 0FBh, 089h
	; EXTZ WA
	db	0D8h, 012h
	; LD C, QIZH
	db	0C7h, 0FBh, 08Bh
	; EXTZ BC
	db	0D9h, 012h
	; SLA 2, BC (multiply by 4 for 32-bit table entries)
	db	0D9h, 0ECh, 002h
	; LDA XDE, 0xFFFEF0 (init handler table)
	db	0F2h, 0F0h, 0FEh, 0FFh, 032h
	; LD XBC, (XDE+BC) - load handler address from table
	db	0E3h, 007h, 0E8h, 0E4h, 021h

	; Call indirect call helper (address differs between ROMs)
	CALL	INDIRECT_CALL_HELPER

	; INC 1, QIZH
	db	0C7h, 0FBh, 061h
	; CP QIZH, 4
	db	0C7h, 0FBh, 0DCh

	JR	C, .handler_loop		; 67 xx (offset computed by assembler)

.done:
	POP	QIZ				; d7 fa 05
	RET					; 0e

; End of shared Boot_CallInitHandlers
