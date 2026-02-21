; =============================================================================
; vga_io.asm - VGA Register I/O Routines (Shared)
; =============================================================================
; This file contains VGA register read/write routines that are byte-identical
; between the Main CPU ROM (maincpu) and Table Data ROM (table_data).
;
; In maincpu: Located at 0xEF5141-0xEF515F (30 bytes)
; In table_data: Located at 0x9FCDFC-0x9FCE1D (34 bytes)
;
; Requirements:
;   - Must define VGA_IO_BASE before including this file
;     (both ROMs use 0x170000)
;
; =============================================================================

; -----------------------------------------------------------------------------
; Write_VGA_Register - Write byte to VGA I/O port
;
; Entry: WA = port offset (e.g., 0x3C4 for sequencer address)
;        C = value to write
; Exit:  None
; Notes: Includes 256-iteration delay loop before write for bus timing
; -----------------------------------------------------------------------------
Write_VGA_Register:
	; (no addr) LD DE, 0	; Initialize delay counter

	.delay:
	; (no addr) INC 1, DE	; Increment counter
	; (no addr) CP DE, 0100h	; Compare to 256
	; (no addr) JR C, .delay	; Loop until DE >= 256

	; (no addr) EXTZ XWA	; Zero-extend WA to XWA
	; (no addr) LD XDE, VGA_IO_BASE	; Load VGA I/O base address
	; (no addr) ADD XDE, XWA	; Add port offset
	; (no addr) LD (XDE), C	; Write value to port
	; (no addr) RET

; -----------------------------------------------------------------------------
; Read_VGA_Register - Read byte from VGA I/O port
;
; Entry: WA = port offset
; Exit:  L = value read
; -----------------------------------------------------------------------------
Read_VGA_Register:
	; (no addr) EXTZ XWA	; Zero-extend WA to XWA
	; (no addr) LD XBC, VGA_IO_BASE	; Load VGA I/O base address
	; (no addr) ADD XBC, XWA	; Add port offset
	; (no addr) LD L, (XBC)	; Read value from port
	; (no addr) RET

; End of shared VGA I/O routines
