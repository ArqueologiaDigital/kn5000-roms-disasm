; =============================================================================
; vga_io.asm - VGA Register I/O Routines (Shared)
; =============================================================================
; This file contains VGA register read/write routines that are byte-identical
; between the Main CPU ROM (maincpu) and Table Data ROM (table_data).
;
; In maincpu: Located at 0xef5141-0xef515f (30 bytes)
; In table_data: Located at 0x9fcdfc-0x9fce1d (34 bytes)
;
; Requirements:
;   - Must define VGA_IO_BASE before including this file
;     (both ROMs use 0x170000)
;
; =============================================================================

; -----------------------------------------------------------------------------
; Write_VGA_Register - Write byte to VGA I/O port
;
; Entry: WA = port offset (e.g., 0x3c4 for sequencer address)
;        C = value to write
; Exit:  None
; Notes: Includes 256-iteration delay loop before write for bus timing
; -----------------------------------------------------------------------------
Write_VGA_Register:
	lds de, 0	; Initialize delay counter

Write_VGA_Register__delay:
	inc 1, de	; Increment counter
	cp de, 0x100	; Compare to 256
	jr c, Write_VGA_Register__delay	; Loop until DE >= 256

	extz xwa	; Zero-extend WA to XWA
	ld xde, 0x170000	; Load VGA I/O base address
	add xde, xwa	; Add port offset
	ld (xde), c	; Write value to port
	ret

; -----------------------------------------------------------------------------
; Read_VGA_Register - Read byte from VGA I/O port
;
; Entry: WA = port offset
; Exit:  L = value read
; -----------------------------------------------------------------------------
Read_VGA_Register:
	extz xwa	; Zero-extend WA to XWA
	ld xbc, 0x170000	; Load VGA I/O base address
	add xbc, xwa	; Add port offset
	ld l, (xbc)	; Read value from port
	ret

; End of shared VGA I/O routines
