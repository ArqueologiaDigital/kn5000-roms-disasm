; =============================================================================
; vga_init.asm - VGA Hardware Initialization (Shared)
; =============================================================================
; This file contains VGA initialization code that is nearly byte-identical
; between the Main CPU ROM (maincpu) and Table Data ROM (table_data).
;
; In maincpu: Located at 0xEF5163-0xEF5AFD (2458 bytes)
; In table_data: Located at 0x9FCE1E-0x9FD7BB (2462 bytes)
;
; This code initializes:
;   - VGA sequencer extended registers
;   - VGA enable and misc output
;   - Standard sequencer registers
;   - Graphics controller registers
;   - CRTC timing registers
;   - Attribute controller (EGA palette)
;   - DAC palette (9 colors: black, white, RGB, CMY, dark blue)
;   - Calls back to extended init
;   - Sets up parameters for video buffer initialization
;
; Requirements:
;   - Must define Write_VGA_Register before including this file
;   - Must define Read_VGA_Register before including this file
;   - Must define VGA I/O port constants (VGA_ENABLE, VGA_SEQ_ADDR, etc.)
;   - Must define VIDEO_RAM_BASE and OFFSCREEN_BUFFER_1
;
; After including this file, each ROM must provide:
;   - CALL to memory fill routine (fills offscreen buffer)
;   - CALL to memory copy routine (blits to video RAM)
;   - Final VGA_SEQUENCER to turn screen on
; =============================================================================

; === VGA Macros ===
; These macros generate CALR instructions to Write_VGA_Register

VGA_WRITE MACRO regnum,value
	LDW WA, regnum
	LDW BC, value
	CALR Write_VGA_Register
	ENDM

VGA_SEQUENCER MACRO field,value
	VGA_WRITE VGA_SEQ_ADDR, field
	VGA_WRITE VGA_SEQ_DATA, value
	ENDM

VGA_GFX_CONTROLLER MACRO field,value
	VGA_WRITE VGA_GC_ADDR, field
	VGA_WRITE VGA_GC_DATA, value
	ENDM

VGA_COLOR_CRTC MACRO field,value
	VGA_WRITE VGA_CRTC_ADDR, field
	VGA_WRITE VGA_CRTC_DATA, value
	ENDM

VGA_ATTRIBUTE MACRO field,value
	VGA_WRITE VGA_ATTR_ADDR, field
	VGA_WRITE VGA_ATTR_ADDR, value
	ENDM

; This macro is used at the end - uses JRL for a tail-call optimization
RET_VGA_WRITE MACRO regnum,value
	LDW WA, regnum
	LDW BC, value
	JRL T, Write_VGA_Register
	ENDM

RET_VGA_SEQUENCER MACRO field,value
	VGA_WRITE VGA_SEQ_ADDR, field
	RET_VGA_WRITE VGA_SEQ_DATA, value
	ENDM


; =============================================================================
; VGA_Extended_Init - Extended VGA Sequencer Configuration
; =============================================================================
; Configures MN89304-specific extended sequencer registers.
; This routine is called from the main VGA setup and returns via
; RET_VGA_SEQUENCER which performs a tail-call back to Write_VGA_Register.
;
; In maincpu: VGA_Extended_Init (0xEF5163)
; In table_data: VGA_Init entry point (0x9FCE1E)
;
; Label names use maincpu convention. Table_data can define aliases if needed.
; =============================================================================
VGA_Extended_Init:
	VGA_SEQUENCER 06h, 001h

	VGA_SEQUENCER 09h, 004h
	VGA_SEQUENCER 0ah, 010h
	VGA_SEQUENCER 0bh, 013h
	VGA_SEQUENCER 0ch, 005h

	VGA_SEQUENCER 09h, 006h
	VGA_SEQUENCER 0ah, 015h
	VGA_SEQUENCER 0bh, 064h
	VGA_SEQUENCER 0ch, 007h

	VGA_SEQUENCER 09h, 000h
	VGA_SEQUENCER 0ah, 01ch
	VGA_SEQUENCER 0bh, 011h
	VGA_SEQUENCER 0ch, 003h

	VGA_SEQUENCER 09h, 002h
	VGA_SEQUENCER 0ah, 005h
	VGA_SEQUENCER 0bh, 011h
	VGA_SEQUENCER 0ch, 003h

	VGA_SEQUENCER 09h, 008h
	VGA_SEQUENCER 0ah, 092h
	VGA_SEQUENCER 0bh, 013h
	VGA_SEQUENCER 0ch, 008h

	VGA_SEQUENCER 09h, 00ah
	VGA_SEQUENCER 0ah, 001h
	VGA_SEQUENCER 0bh, 014h
	VGA_SEQUENCER 0ch, 006h

	VGA_SEQUENCER 09h, 00dh
	VGA_SEQUENCER 0ah, 001h

	VGA_SEQUENCER 09h, 00ch
	VGA_SEQUENCER 0ah, 000h
	VGA_SEQUENCER 0bh, 072h
	VGA_SEQUENCER 0ch, 009h

	VGA_SEQUENCER 09h, 00fh
	VGA_SEQUENCER 0ah, 011h

	VGA_SEQUENCER 09h, 00eh
	VGA_SEQUENCER 0ah, 000h
	VGA_SEQUENCER 0bh, 013h
	VGA_SEQUENCER 0ch, 008h

	VGA_SEQUENCER 09h, 011h
	VGA_SEQUENCER 0ah, 0ffh

	VGA_SEQUENCER 09h, 010h
	VGA_SEQUENCER 0ah, 0feh
	VGA_SEQUENCER 0bh, 073h
	VGA_SEQUENCER 0ch, 00fh

	VGA_SEQUENCER 09h, 001h
	VGA_SEQUENCER 0ch, 074h

	VGA_SEQUENCER 09h, 003h
	VGA_SEQUENCER 0ch, 009h

	VGA_SEQUENCER 09h, 005h
	VGA_SEQUENCER 0ch, 02bh

	VGA_SEQUENCER 09h, 007h
	VGA_SEQUENCER 0ch, 068h

	VGA_SEQUENCER 09h, 009h
	VGA_SEQUENCER 0ch, 005h

	VGA_SEQUENCER 09h, 00bh
	VGA_SEQUENCER 0ch, 001h

	VGA_SEQUENCER 09h, 00dh
	VGA_SEQUENCER 0ch, 00ch

	VGA_SEQUENCER 09h, 00fh
	VGA_SEQUENCER 0ch, 03ah

	VGA_SEQUENCER 09h, 011h
	VGA_SEQUENCER 0ch, 00dh

	RET_VGA_SEQUENCER 06h, 000h


; =============================================================================
; VGA_Setup - Main VGA Initialization
; =============================================================================
; Complete VGA hardware initialization:
;   1. Enable VGA and set misc output
;   2. Configure sequencer (clocking, map mask, memory mode)
;   3. Configure graphics controller
;   4. Configure CRTC timing
;   5. Set attribute controller (EGA palette)
;   6. Set DAC palette (9 basic colors)
;   7. Call extended init
;   8. Prepare registers for video buffer initialization
;
; After this code, the caller must:
;   - CALL a memory fill routine to clear the offscreen buffer
;   - CALL a memory copy routine to blit to video RAM
;   - Set VGA_SEQUENCER 01h, 001h to turn the screen on
; =============================================================================
VGA_Setup:
	VGA_WRITE VGA_ENABLE, 001h		; Global enable
	VGA_WRITE VGA_MISC_OUTPUT, 0e3h		; 25 MHz dot clock, 60 Hz scanning

	VGA_SEQUENCER 00h, 000h			; Reset
	VGA_SEQUENCER 01h, 021h			; Clocking Mode (screen off)
	VGA_SEQUENCER 00h, 003h			; Reset
	VGA_SEQUENCER 02h, 00fh			; Map Mask (all 4 planes)
	VGA_SEQUENCER 03h, 000h			; Character Map Select
	VGA_SEQUENCER 04h, 006h			; Memory Mode

	VGA_GFX_CONTROLLER GC_ENABLE_SET_RESET, 000h
	VGA_GFX_CONTROLLER GC_DATA_ROTATE, 000h
	VGA_GFX_CONTROLLER GC_READ_MAP_SELECT, 000h
	VGA_GFX_CONTROLLER GC_GRAPHICS_MODE, 000h
	VGA_GFX_CONTROLLER GC_MISC_GRAPHICS, 001h
	VGA_GFX_CONTROLLER GC_BIT_MASK, 0ffh

	VGA_COLOR_CRTC CRTC_VERT_RETRACE_END, 000h	; Unlock protected regs
	VGA_COLOR_CRTC CRTC_OVERFLOW, 010h
	VGA_COLOR_CRTC CRTC_PRESET_ROW_SCAN, 000h
	VGA_COLOR_CRTC CRTC_MAX_SCAN_LINE, 040h
	VGA_COLOR_CRTC CRTC_START_ADDR_HIGH, 000h
	VGA_COLOR_CRTC CRTC_START_ADDR_LOW, 000h
	VGA_COLOR_CRTC CRTC_VERT_DISP_END, 0efh
	VGA_COLOR_CRTC CRTC_OFFSET, 014h
	VGA_COLOR_CRTC CRTC_UNDERLINE_LOC, 000h
	VGA_COLOR_CRTC CRTC_MODE_CONTROL, 0e3h
	VGA_COLOR_CRTC CRTC_LINE_COMPARE, 0ffh

	; Read VGA_INPUT_STATUS - reuses BC=0FFh from previous write
	LDW WA, VGA_INPUT_STATUS
	CALR Read_VGA_Register

	; EGA default palette (16 entries)
	VGA_ATTRIBUTE 00h, 000h
	VGA_ATTRIBUTE 01h, 001h
	VGA_ATTRIBUTE 02h, 002h
	VGA_ATTRIBUTE 03h, 003h
	VGA_ATTRIBUTE 04h, 004h
	VGA_ATTRIBUTE 05h, 005h
	VGA_ATTRIBUTE 06h, 014h
	VGA_ATTRIBUTE 07h, 007h
	VGA_ATTRIBUTE 08h, 038h
	VGA_ATTRIBUTE 09h, 039h
	VGA_ATTRIBUTE 0ah, 03ah
	VGA_ATTRIBUTE 0bh, 03bh
	VGA_ATTRIBUTE 0ch, 03ch
	VGA_ATTRIBUTE 0dh, 03dh
	VGA_ATTRIBUTE 0eh, 03eh
	VGA_ATTRIBUTE 0fh, 03fh
	VGA_ATTRIBUTE ATTR_MODE_CONTROL, 001h
	VGA_ATTRIBUTE ATTR_OVERSCAN_COLOR, 000h
	VGA_ATTRIBUTE ATTR_COLOR_PLANE_ENABLE, 00fh
	VGA_ATTRIBUTE ATTR_HORIZ_PIXEL_PAN, 000h
	VGA_ATTRIBUTE 34h, 000h		; ATTR_COLOR_SELECT + Palette Address Source

	VGA_SEQUENCER 06h, 001h

	VGA_COLOR_CRTC CRTC_HORIZ_TOTAL, 065h
	VGA_COLOR_CRTC CRTC_HORIZ_DISP_END, 027h
	VGA_COLOR_CRTC CRTC_START_HORIZ_RETRACE, 028h
	VGA_COLOR_CRTC CRTC_END_HORIZ_RETRACE, 029h
	VGA_COLOR_CRTC CRTC_VERT_TOTAL, 0f3h
	VGA_COLOR_CRTC CRTC_OVERFLOW, 000h
	VGA_COLOR_CRTC CRTC_MAX_SCAN_LINE, 000h
	VGA_COLOR_CRTC CRTC_VERT_RETRACE_START, 0f2h
	VGA_COLOR_CRTC CRTC_VERT_RETRACE_END, 003h
	VGA_COLOR_CRTC CRTC_START_VERT_BLANK, 0efh
	VGA_COLOR_CRTC CRTC_END_VERT_BLANK, 0f3h

	VGA_SEQUENCER 08h, 001h
	VGA_SEQUENCER 0dh, 003h
	VGA_SEQUENCER 0fh, 000h

	VGA_COLOR_CRTC 19h, 000h		; MN89304-specific
	VGA_COLOR_CRTC 1ah, 010h		; MN89304-specific

	VGA_SEQUENCER 07h, 020h			; Horiz char counter reset
	VGA_SEQUENCER 06h, 000h

	VGA_COLOR_CRTC CRTC_VERT_RETRACE_END, 080h	; Lock protected regs 0-7

	VGA_WRITE 3c6h, 0ffh			; DAC mask

	; === DAC Palette Setup ===
	VGA_WRITE 3c8h, 0			; Start at palette index 0

	; Color 0: Black (0, 0, 0)
	LD WA, 3c9h
	LDW BC, 0
	CALR Write_VGA_Register
	LD WA, 3c9h
	LDW BC, 0
	CALR Write_VGA_Register
	LD WA, 3c9h
	LDW BC, 0
	CALR Write_VGA_Register

	; Color 1: White (F, F, F)
	LD WA, 3c9h
	LDW BC, 0fh
	CALR Write_VGA_Register
	LD WA, 3c9h
	LDW BC, 0fh
	CALR Write_VGA_Register
	LD WA, 3c9h
	LDW BC, 0fh
	CALR Write_VGA_Register

	; Color 2: Red (F, 0, 0)
	LD WA, 3c9h
	LDW BC, 0fh
	CALR Write_VGA_Register
	LD WA, 3c9h
	LDW BC, 0
	CALR Write_VGA_Register
	LD WA, 3c9h
	LDW BC, 0
	CALR Write_VGA_Register

	; Color 3: Green (0, F, 0)
	LD WA, 3c9h
	LDW BC, 0
	CALR Write_VGA_Register
	LD WA, 3c9h
	LDW BC, 0fh
	CALR Write_VGA_Register
	LD WA, 3c9h
	LDW BC, 0
	CALR Write_VGA_Register

	; Color 4: Blue (0, 0, F)
	LD WA, 3c9h
	LDW BC, 0
	CALR Write_VGA_Register
	LD WA, 3c9h
	LDW BC, 0
	CALR Write_VGA_Register
	LD WA, 3c9h
	LDW BC, 0fh
	CALR Write_VGA_Register

	; Color 5: Cyan (0, F, F)
	LD WA, 3c9h
	LDW BC, 0
	CALR Write_VGA_Register
	LD WA, 3c9h
	LDW BC, 0fh
	CALR Write_VGA_Register
	LD WA, 3c9h
	LDW BC, 0fh
	CALR Write_VGA_Register

	; Color 6: Yellow (F, F, 0)
	LD WA, 3c9h
	LDW BC, 0fh
	CALR Write_VGA_Register
	LD WA, 3c9h
	LDW BC, 0fh
	CALR Write_VGA_Register
	LD WA, 3c9h
	LDW BC, 0
	CALR Write_VGA_Register

	; Color 7: Magenta (F, 0, F)
	LD WA, 3c9h
	LDW BC, 0fh
	CALR Write_VGA_Register
	LD WA, 3c9h
	LDW BC, 0
	CALR Write_VGA_Register
	LD WA, 3c9h
	LDW BC, 0fh
	CALR Write_VGA_Register

	; Color 8: Dark Blue (0, 0, 4)
	LD WA, 3c9h
	LDW BC, 0
	CALR Write_VGA_Register
	LD WA, 3c9h
	LDW BC, 0
	CALR Write_VGA_Register
	LD WA, 3c9h
	LDW BC, 4
	CALR Write_VGA_Register

	; Call extended sequencer init
	CALR VGA_Extended_Init

	; Set up parameters for video buffer initialization
	; These are loaded here; caller provides the actual CALL to fill/copy routines
	LD XWA, OFFSCREEN_BUFFER_1
	LD BC, 0808h				; Fill pattern
	LD DE, 320 * 240 / 2			; Size in words (38400 = 0x9600)

	; === End of shared VGA init code ===
	; Each ROM must now:
	;   1. CALL its memory fill routine (fills XWA with DE words of BC pattern)
	;   2. LDA XWA, VIDEO_RAM_BASE
	;   3. LD XBC, OFFSCREEN_BUFFER_1
	;   4. LD DE, 320 * 240 / 2
	;   5. CALL its memory copy routine
	;   6. RET_VGA_SEQUENCER 01h, 001h  (turn screen on)
