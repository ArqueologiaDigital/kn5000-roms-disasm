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

.macro VGA_WRITE regnum, value
	.if \regnum <= 7
	lds wa, \regnum
	.else
	ldw wa, \regnum
	.endif
	.if \value <= 7
	lds bc, \value
	.else
	ldw bc, \value
	.endif
	calr Write_VGA_Register
.endm





.macro VGA_SEQUENCER field, value
	VGA_WRITE 0x3C4, \field
	VGA_WRITE 0x3C5, \value
.endm




.macro VGA_GFX_CONTROLLER field, value
	VGA_WRITE 0x3CE, \field
	VGA_WRITE 0x3CF, \value
.endm




.macro VGA_COLOR_CRTC field, value
	VGA_WRITE 0x3D4, \field
	VGA_WRITE 0x3D5, \value
.endm




.macro VGA_ATTRIBUTE field, value
	VGA_WRITE 0x3C0, \field
	VGA_WRITE 0x3C0, \value
.endm




; This macro is used at the end - uses JRL for a tail-call optimization
.macro RET_VGA_WRITE regnum, value
	.if \regnum <= 7
	lds wa, \regnum
	.else
	ldw wa, \regnum
	.endif
	.if \value <= 7
	lds bc, \value
	.else
	ldw bc, \value
	.endif
	jrl t, Write_VGA_Register
.endm





.macro RET_VGA_SEQUENCER field, value
	VGA_WRITE 0x3C4, \field
	RET_VGA_WRITE 0x3C5, \value
.endm





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
	VGA_SEQUENCER 0x6, 0x1

	VGA_SEQUENCER 0x9, 0x4
	VGA_SEQUENCER 0xa, 0x10
	VGA_SEQUENCER 0xb, 0x13
	VGA_SEQUENCER 0xc, 0x5

	VGA_SEQUENCER 0x9, 0x6
	VGA_SEQUENCER 0xa, 0x15
	VGA_SEQUENCER 0xb, 0x64
	VGA_SEQUENCER 0xc, 0x7

	VGA_SEQUENCER 0x9, 0x0
	VGA_SEQUENCER 0xa, 0x1c
	VGA_SEQUENCER 0xb, 0x11
	VGA_SEQUENCER 0xc, 0x3

	VGA_SEQUENCER 0x9, 0x2
	VGA_SEQUENCER 0xa, 0x5
	VGA_SEQUENCER 0xb, 0x11
	VGA_SEQUENCER 0xc, 0x3

	VGA_SEQUENCER 0x9, 0x8
	VGA_SEQUENCER 0xa, 0x92
	VGA_SEQUENCER 0xb, 0x13
	VGA_SEQUENCER 0xc, 0x8

	VGA_SEQUENCER 0x9, 0xa
	VGA_SEQUENCER 0xa, 0x1
	VGA_SEQUENCER 0xb, 0x14
	VGA_SEQUENCER 0xc, 0x6

	VGA_SEQUENCER 0x9, 0xd
	VGA_SEQUENCER 0xa, 0x1

	VGA_SEQUENCER 0x9, 0xc
	VGA_SEQUENCER 0xa, 0x0
	VGA_SEQUENCER 0xb, 0x72
	VGA_SEQUENCER 0xc, 0x9

	VGA_SEQUENCER 0x9, 0xf
	VGA_SEQUENCER 0xa, 0x11

	VGA_SEQUENCER 0x9, 0xe
	VGA_SEQUENCER 0xa, 0x0
	VGA_SEQUENCER 0xb, 0x13
	VGA_SEQUENCER 0xc, 0x8

	VGA_SEQUENCER 0x9, 0x11
	VGA_SEQUENCER 0xa, 0xff

	VGA_SEQUENCER 0x9, 0x10
	VGA_SEQUENCER 0xa, 0xfe
	VGA_SEQUENCER 0xb, 0x73
	VGA_SEQUENCER 0xc, 0xf

	VGA_SEQUENCER 0x9, 0x1
	VGA_SEQUENCER 0xc, 0x74

	VGA_SEQUENCER 0x9, 0x3
	VGA_SEQUENCER 0xc, 0x9

	VGA_SEQUENCER 0x9, 0x5
	VGA_SEQUENCER 0xc, 0x2b

	VGA_SEQUENCER 0x9, 0x7
	VGA_SEQUENCER 0xc, 0x68

	VGA_SEQUENCER 0x9, 0x9
	VGA_SEQUENCER 0xc, 0x5

	VGA_SEQUENCER 0x9, 0xb
	VGA_SEQUENCER 0xc, 0x1

	VGA_SEQUENCER 0x9, 0xd
	VGA_SEQUENCER 0xc, 0xc

	VGA_SEQUENCER 0x9, 0xf
	VGA_SEQUENCER 0xc, 0x3a

	VGA_SEQUENCER 0x9, 0x11
	VGA_SEQUENCER 0xc, 0xd

	RET_VGA_SEQUENCER 0x6, 0x0


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
	VGA_WRITE VGA_ENABLE, 0x1	; Global enable
	VGA_WRITE VGA_MISC_OUTPUT, 0xe3	; 25 MHz dot clock, 60 Hz scanning

	VGA_SEQUENCER 0x0, 0x0	; Reset
	VGA_SEQUENCER 0x1, 0x21	; Clocking Mode (screen off)
	VGA_SEQUENCER 0x0, 0x3	; Reset
	VGA_SEQUENCER 0x2, 0xf	; Map Mask (all 4 planes)
	VGA_SEQUENCER 0x3, 0x0	; Character Map Select
	VGA_SEQUENCER 0x4, 0x6	; Memory Mode

	VGA_GFX_CONTROLLER GC_ENABLE_SET_RESET, 0x0
	VGA_GFX_CONTROLLER GC_DATA_ROTATE, 0x0
	VGA_GFX_CONTROLLER GC_READ_MAP_SELECT, 0x0
	VGA_GFX_CONTROLLER GC_GRAPHICS_MODE, 0x0
	VGA_GFX_CONTROLLER GC_MISC_GRAPHICS, 0x1
	VGA_GFX_CONTROLLER GC_BIT_MASK, 0xff

	VGA_COLOR_CRTC CRTC_VERT_RETRACE_END, 0x0	; Unlock protected regs
	VGA_COLOR_CRTC CRTC_OVERFLOW, 0x10
	VGA_COLOR_CRTC CRTC_PRESET_ROW_SCAN, 0x0
	VGA_COLOR_CRTC CRTC_MAX_SCAN_LINE, 0x40
	VGA_COLOR_CRTC CRTC_START_ADDR_HIGH, 0x0
	VGA_COLOR_CRTC CRTC_START_ADDR_LOW, 0x0
	VGA_COLOR_CRTC CRTC_VERT_DISP_END, 0xef
	VGA_COLOR_CRTC CRTC_OFFSET, 0x14
	VGA_COLOR_CRTC CRTC_UNDERLINE_LOC, 0x0
	VGA_COLOR_CRTC CRTC_MODE_CONTROL, 0xe3
	VGA_COLOR_CRTC CRTC_LINE_COMPARE, 0xff

	; Read VGA_INPUT_STATUS - reuses BC=0FFh from previous write
	ldw wa, 0x3DA
	calr Read_VGA_Register

	; EGA default palette (16 entries)
	VGA_ATTRIBUTE 0x0, 0x0
	VGA_ATTRIBUTE 0x1, 0x1
	VGA_ATTRIBUTE 0x2, 0x2
	VGA_ATTRIBUTE 0x3, 0x3
	VGA_ATTRIBUTE 0x4, 0x4
	VGA_ATTRIBUTE 0x5, 0x5
	VGA_ATTRIBUTE 0x6, 0x14
	VGA_ATTRIBUTE 0x7, 0x7
	VGA_ATTRIBUTE 0x8, 0x38
	VGA_ATTRIBUTE 0x9, 0x39
	VGA_ATTRIBUTE 0xa, 0x3a
	VGA_ATTRIBUTE 0xb, 0x3b
	VGA_ATTRIBUTE 0xc, 0x3c
	VGA_ATTRIBUTE 0xd, 0x3d
	VGA_ATTRIBUTE 0xe, 0x3e
	VGA_ATTRIBUTE 0xf, 0x3f
	VGA_ATTRIBUTE ATTR_MODE_CONTROL, 0x1
	VGA_ATTRIBUTE ATTR_OVERSCAN_COLOR, 0x0
	VGA_ATTRIBUTE ATTR_COLOR_PLANE_ENABLE, 0xf
	VGA_ATTRIBUTE ATTR_HORIZ_PIXEL_PAN, 0x0
	VGA_ATTRIBUTE 0x34, 0x0	; ATTR_COLOR_SELECT + Palette Address Source

	VGA_SEQUENCER 0x6, 0x1

	VGA_COLOR_CRTC CRTC_HORIZ_TOTAL, 0x65
	VGA_COLOR_CRTC CRTC_HORIZ_DISP_END, 0x27
	VGA_COLOR_CRTC CRTC_START_HORIZ_RETRACE, 0x28
	VGA_COLOR_CRTC CRTC_END_HORIZ_RETRACE, 0x29
	VGA_COLOR_CRTC CRTC_VERT_TOTAL, 0xf3
	VGA_COLOR_CRTC CRTC_OVERFLOW, 0x0
	VGA_COLOR_CRTC CRTC_MAX_SCAN_LINE, 0x0
	VGA_COLOR_CRTC CRTC_VERT_RETRACE_START, 0xf2
	VGA_COLOR_CRTC CRTC_VERT_RETRACE_END, 0x3
	VGA_COLOR_CRTC CRTC_START_VERT_BLANK, 0xef
	VGA_COLOR_CRTC CRTC_END_VERT_BLANK, 0xf3

	VGA_SEQUENCER 0x8, 0x1
	VGA_SEQUENCER 0xd, 0x3
	VGA_SEQUENCER 0xf, 0x0

	VGA_COLOR_CRTC 0x19, 0x0	; MN89304-specific
	VGA_COLOR_CRTC 0x1a, 0x10	; MN89304-specific

	VGA_SEQUENCER 0x7, 0x20	; Horiz char counter reset
	VGA_SEQUENCER 0x6, 0x0

	VGA_COLOR_CRTC CRTC_VERT_RETRACE_END, 0x80	; Lock protected regs 0-7

	VGA_WRITE 0x3c6, 0xff	; DAC mask

	; === DAC Palette Setup ===
	VGA_WRITE 0x3c8, 0	; Start at palette index 0

	; Color 0: Black (0, 0, 0)
	ldw wa, 0x3C9
	lds bc, 0
	calr Write_VGA_Register
	ldw wa, 0x3C9
	lds bc, 0
	calr Write_VGA_Register
	ldw wa, 0x3C9
	lds bc, 0
	calr Write_VGA_Register

	; Color 1: White (F, F, F)
	ldw wa, 0x3C9
	ldw bc, 0xF
	calr Write_VGA_Register
	ldw wa, 0x3C9
	ldw bc, 0xF
	calr Write_VGA_Register
	ldw wa, 0x3C9
	ldw bc, 0xF
	calr Write_VGA_Register

	; Color 2: Red (F, 0, 0)
	ldw wa, 0x3C9
	ldw bc, 0xF
	calr Write_VGA_Register
	ldw wa, 0x3C9
	lds bc, 0
	calr Write_VGA_Register
	ldw wa, 0x3C9
	lds bc, 0
	calr Write_VGA_Register

	; Color 3: Green (0, F, 0)
	ldw wa, 0x3C9
	lds bc, 0
	calr Write_VGA_Register
	ldw wa, 0x3C9
	ldw bc, 0xF
	calr Write_VGA_Register
	ldw wa, 0x3C9
	lds bc, 0
	calr Write_VGA_Register

	; Color 4: Blue (0, 0, F)
	ldw wa, 0x3C9
	lds bc, 0
	calr Write_VGA_Register
	ldw wa, 0x3C9
	lds bc, 0
	calr Write_VGA_Register
	ldw wa, 0x3C9
	ldw bc, 0xF
	calr Write_VGA_Register

	; Color 5: Cyan (0, F, F)
	ldw wa, 0x3C9
	lds bc, 0
	calr Write_VGA_Register
	ldw wa, 0x3C9
	ldw bc, 0xF
	calr Write_VGA_Register
	ldw wa, 0x3C9
	ldw bc, 0xF
	calr Write_VGA_Register

	; Color 6: Yellow (F, F, 0)
	ldw wa, 0x3C9
	ldw bc, 0xF
	calr Write_VGA_Register
	ldw wa, 0x3C9
	ldw bc, 0xF
	calr Write_VGA_Register
	ldw wa, 0x3C9
	lds bc, 0
	calr Write_VGA_Register

	; Color 7: Magenta (F, 0, F)
	ldw wa, 0x3C9
	ldw bc, 0xF
	calr Write_VGA_Register
	ldw wa, 0x3C9
	lds bc, 0
	calr Write_VGA_Register
	ldw wa, 0x3C9
	ldw bc, 0xF
	calr Write_VGA_Register

	; Color 8: Dark Blue (0, 0, 4)
	ldw wa, 0x3C9
	lds bc, 0
	calr Write_VGA_Register
	ldw wa, 0x3C9
	lds bc, 0
	calr Write_VGA_Register
	ldw wa, 0x3C9
	lds bc, 4
	calr Write_VGA_Register

	; Call extended sequencer init
	calr VGA_Extended_Init

	; Set up parameters for video buffer initialization
	; These are loaded here; caller provides the actual CALL to fill/copy routines
	ld xwa, 0x43C00
	ldw bc, 0x808	; Fill pattern
	ldw de, 0x9600	; Size in words (38400 = 0x9600)

	; === End of shared VGA init code ===
	; Each ROM must now:
	;   1. CALL its memory fill routine (fills XWA with DE words of BC pattern)
	;   2. LDA XWA, VIDEO_RAM_BASE
	;   3. LD XBC, OFFSCREEN_BUFFER_1
	;   4. LD DE, 320 * 240 / 2
	;   5. CALL its memory copy routine
	;   6. RET_VGA_SEQUENCER 01h, 001h  (turn screen on)
