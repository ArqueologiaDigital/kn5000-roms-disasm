; =============================================================================
; vga_constants.asm - VGA Register Definitions (Shared)
; =============================================================================
; This file contains VGA hardware register definitions used by both
; the Main CPU ROM and Table Data ROM for display initialization.
;
; The KN5000 uses an MN89304 LCD controller with VGA-compatible registers.
; I/O ports are memory-mapped at VGA_IO_BASE (0x170000).
; Video RAM is at VIDEO_RAM_BASE (0x1A0000), 320x240 @ 8bpp.
; =============================================================================

; === Base Addresses ===
VGA_IO_BASE		EQU 170000h	; LCD controller I/O base
VIDEO_RAM_BASE		EQU 1A0000h	; 4Mbit VRAM

; === VGA I/O Ports ===
VGA_ATTR_ADDR		EQU 3C0h	; Attribute Controller Address/Data
VGA_MISC_OUTPUT		EQU 3C2h	; Miscellaneous Output Register (write)
VGA_ENABLE		EQU 3C3h	; VGA Enable
VGA_SEQ_ADDR		EQU 3C4h	; Sequencer Address
VGA_SEQ_DATA		EQU 3C5h	; Sequencer Data
VGA_DAC_MASK		EQU 3C6h	; DAC Mask
VGA_DAC_ADDR_WRITE	EQU 3C8h	; DAC Write Address
VGA_DAC_DATA		EQU 3C9h	; DAC Data (R, G, B sequentially)
VGA_GC_ADDR		EQU 3CEh	; Graphics Controller Address
VGA_GC_DATA		EQU 3CFh	; Graphics Controller Data
VGA_CRTC_ADDR		EQU 3D4h	; CRTC Address
VGA_CRTC_DATA		EQU 3D5h	; CRTC Data
VGA_INPUT_STATUS	EQU 3DAh	; Input Status 1

; === CRTC Register Indices ===
CRTC_HORIZ_TOTAL	EQU 00h		; Horizontal Total
CRTC_HORIZ_DISP_END	EQU 01h		; Horizontal Display End
CRTC_START_HORIZ_BLANK	EQU 02h		; Start Horizontal Blanking
CRTC_END_HORIZ_BLANK	EQU 03h		; End Horizontal Blanking
CRTC_START_HORIZ_RETRACE EQU 04h	; Start Horizontal Retrace
CRTC_END_HORIZ_RETRACE	EQU 05h		; End Horizontal Retrace
CRTC_VERT_TOTAL		EQU 06h		; Vertical Total
CRTC_OVERFLOW		EQU 07h		; Overflow
CRTC_PRESET_ROW_SCAN	EQU 08h		; Preset Row Scan
CRTC_MAX_SCAN_LINE	EQU 09h		; Maximum Scan Line
CRTC_CURSOR_START	EQU 0Ah		; Cursor Start
CRTC_CURSOR_END		EQU 0Bh		; Cursor End
CRTC_START_ADDR_HIGH	EQU 0Ch		; Start Address High
CRTC_START_ADDR_LOW	EQU 0Dh		; Start Address Low
CRTC_CURSOR_LOC_HIGH	EQU 0Eh		; Cursor Location High
CRTC_CURSOR_LOC_LOW	EQU 0Fh		; Cursor Location Low
CRTC_VERT_RETRACE_START	EQU 10h		; Vertical Retrace Start
CRTC_VERT_RETRACE_END	EQU 11h		; Vertical Retrace End (+ Protect bit 7)
CRTC_VERT_DISP_END	EQU 12h		; Vertical Display End
CRTC_OFFSET		EQU 13h		; Offset (logical line width / 2)
CRTC_UNDERLINE_LOC	EQU 14h		; Underline Location
CRTC_START_VERT_BLANK	EQU 15h		; Start Vertical Blanking
CRTC_END_VERT_BLANK	EQU 16h		; End Vertical Blanking
CRTC_MODE_CONTROL	EQU 17h		; Mode Control
CRTC_LINE_COMPARE	EQU 18h		; Line Compare

; === Graphics Controller Register Indices ===
GC_SET_RESET		EQU 00h		; Set/Reset
GC_ENABLE_SET_RESET	EQU 01h		; Enable Set/Reset
GC_COLOR_COMPARE	EQU 02h		; Color Compare
GC_DATA_ROTATE		EQU 03h		; Data Rotate
GC_READ_MAP_SELECT	EQU 04h		; Read Map Select
GC_GRAPHICS_MODE	EQU 05h		; Graphics Mode
GC_MISC_GRAPHICS	EQU 06h		; Miscellaneous Graphics
GC_COLOR_DONT_CARE	EQU 07h		; Color Don't Care
GC_BIT_MASK		EQU 08h		; Bit Mask

; === Attribute Controller Register Indices ===
ATTR_MODE_CONTROL	EQU 10h		; Mode Control
ATTR_OVERSCAN_COLOR	EQU 11h		; Overscan Color
ATTR_COLOR_PLANE_ENABLE	EQU 12h		; Color Plane Enable
ATTR_HORIZ_PIXEL_PAN	EQU 13h		; Horizontal Pixel Panning
ATTR_COLOR_SELECT	EQU 14h		; Color Select
