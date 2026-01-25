; KN5000 Sub CPU Boot ROM Disassembly
; Original ROM: kn5000_subcpu_boot.ic30 (128KB)
; Target CPU: TMP94C241F (TLCS-900/H2)
;
; This is the boot ROM for the sub CPU (tone generator controller).
; It initializes hardware, copies interrupt vectors to RAM, and
; jumps to the payload entry point at 0x0400.
;
; Memory Map:
;   0x0000-0x00FF  - Special Function Registers (SFR)
;   0x0100-0x01FF  - Extended SFR / Memory Controller
;   0x0400+        - Payload loaded by main CPU via MicroDMA
;   0xFE0000-0xFFFFFF - This boot ROM (128KB, but mostly 0xFF)
;
; Actual code starts at 0xFF8000 (file offset 0x18000)

	cpu	96c141		; Actual CPU is TMP94C241F
	page	0
	maxmode	on
	include	"../tmp94c241.inc"

; ==============================================================================
; Constants
; ==============================================================================

PAYLOAD_ENTRY		EQU	0400h	; Entry point of loaded payload
STACK_INIT		EQU	05A2h	; Initial stack pointer

; SFR addresses (directly addressable 0x00-0xFF)
P0FC			EQU	07h	; Port 0 Function Control
P1FC			EQU	0Bh	; Port 1 Function Control
P2FC			EQU	0Fh	; Port 2 Function Control
P7			EQU	1Ch	; Port 7 Data
P7CR			EQU	1Eh	; Port 7 Control
P7FC			EQU	1Fh	; Port 7 Function Control
P8			EQU	20h	; Port 8 Data
P8CR			EQU	22h	; Port 8 Control
P8FC			EQU	23h	; Port 8 Function Control
PA			EQU	28h	; Port A Data
PAFC			EQU	2Bh	; Port A Function Control
PB			EQU	2Ch	; Port B Data
PBFC			EQU	2Fh	; Port B Function Control
INTTC01			EQU	30h	; Interrupt control (Timer 0/1)

; Extended SFR (0x0100+)
REG_0110		EQU	0110h
REG_0111		EQU	0111h
REG_010A		EQU	010Ah

; ==============================================================================
; ROM starts with 96KB of 0xFF (erased flash)
; Actual data begins at 0xFF8000 (file offset 0x18000)
; ==============================================================================

	org	0FE0000h

	; Fill first 96KB with 0xFF
	rept	98304
	db	0FFh
	endm

; ==============================================================================
; Data Tables (0xFF8000 - 0xFF8289)
; These appear to be lookup tables, not code
; ==============================================================================

	org	0FF8000h

DATA_TABLE_8000:
	; TODO: Analyze and document these data tables
	; For now, include as binary
	binclude	"subcpu_boot_data_8000.bin"

; ==============================================================================
; Boot Entry Point (0xFF8290)
; Called from reset vector area
; ==============================================================================

	org	0FF8290h

BOOT_INIT:
	; Initialize extended registers
	ld	(REG_0110), 00h
	ld	(REG_0111), 0B1h
	ld	(REG_010A), 04h

	; Initialize port function control registers
	ld	(P0FC), 0FFh
	ld	(P1FC), 0FFh
	ld	(P2FC), 0FFh
	ld	(P7), 0FFh
	ld	(P7FC), 07h
	ld	(P7CR), 78h
	ld	(P8), 3Bh
	ld	(P8FC), 3Fh
	ld	(P8CR), 0FFh
	ld	(PA), 0FFh
	ld	(PAFC), 08h
	ld	(PB), 0FFh
	ld	(PBFC), 1Fh

	; Continue with more initialization...
	; TODO: Complete the initialization sequence

	; Set up stack pointer
	lda	XWA, STACK_INIT
	ld	XSP, XWA

	; Copy interrupt vectors to RAM
	call	COPY_VECTORS

	; Enable interrupts
	ei	0

	; Call initialization routines
	call	INIT_ROUTINE_1		; 0xFF8956
	call	INIT_ROUTINE_2		; 0xFF85AE
	call	INIT_ROUTINE_3		; 0xFF84A8

MAIN_LOOP:
	; Check some flag and call payload
	res	6, (04FEh)
	bit	6, (04FEh)
	jr	Z, .skip_payload
	ei	6
	call	PAYLOAD_ENTRY		; Jump to payload at 0x0400
.skip_payload:
	; ... main loop continues
	jr	MAIN_LOOP

; ==============================================================================
; COPY_VECTORS - Copy interrupt vector table to RAM at 0x0400
; ==============================================================================

COPY_VECTORS:
	ld	XDE, 00000400h		; Destination: 0x0400 (payload area)
	ld	XHL, 0FF8F6Ch		; Source: Vector data in ROM
	ld	XBC, 0000000E1h		; Count: 0xE1 bytes
	or	XBC, XBC
	jr	Z, .done
	ldir				; Block copy
.done:
	ret

; ==============================================================================
; Placeholder for other routines
; ==============================================================================

INIT_ROUTINE_1:		; 0xFF8956
	; TODO: Disassemble
	ret

INIT_ROUTINE_2:		; 0xFF85AE
	; TODO: Disassemble
	ret

INIT_ROUTINE_3:		; 0xFF84A8
	; TODO: Disassemble
	ret

; ==============================================================================
; Data area for vector copy source
; ==============================================================================

	org	0FF8F6Ch

VECTOR_DATA:
	; This data gets copied to 0x0400 at boot
	; TODO: Extract and include

; ==============================================================================
; Interrupt Vector Table (0xFFFF00 - 0xFFFFFF)
; These point to handlers in the loaded payload at 0x04xx
; ==============================================================================

	org	0FFFF00h

VECTOR_TABLE:
	; Interrupt vectors - 4 bytes each, pointing to 0x04xx handlers
	dd	0000FEE0h	; Vector 0 - points to ROM code at 0xFEE0
	dd	00000405h	; Vector 1 - INT_HANDLER_01 in payload
	dd	0000040Ah	; Vector 2 - INT_HANDLER_02 in payload
	dd	0000040Fh	; Vector 3
	dd	00000414h	; Vector 4
	dd	00000419h	; Vector 5
	dd	0000041Eh	; Vector 6
	dd	00000423h	; Vector 7
	dd	000004DCh	; Vector 8
	dd	00000428h	; Vector 9
	dd	0000042Dh	; Vector 10
	dd	00000432h	; Vector 11
	dd	00000437h	; Vector 12
	dd	0000043Ch	; Vector 13
	dd	00000441h	; Vector 14
	dd	00000446h	; Vector 15
	; ... more vectors ...

	org	0FFFFF0h

RESET_VECTORS:
	; Reset vector area - repeated pattern
	; These bytes: 41 B1 62 1B (repeated 4 times)
	; Meaning still being analyzed
	db	41h, 0B1h, 62h, 1Bh
	db	41h, 0B1h, 62h, 1Bh
	db	41h, 0B1h, 62h, 1Bh
	db	41h, 0B1h, 62h, 1Bh

	end
