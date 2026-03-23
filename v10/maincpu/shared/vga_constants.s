; =============================================================================
; vga_constants.asm - VGA Register Definitions (Shared)
; =============================================================================
; This file contains VGA hardware register definitions used by both
; the Main CPU ROM and Table Data ROM for display initialization.
;
; The KN5000 uses an MN89304 LCD controller with VGA-compatible registers.
; I/O ports are memory-mapped at VGA_IO_BASE (0x170000).
; Video RAM is at VIDEO_RAM_BASE (0x1a0000), 320x240 @ 8bpp.
; =============================================================================

; === Base Addresses ===
.equ VGA_IO_BASE, 0x170000	; LCD controller I/O base
.equ VIDEO_RAM_BASE, 0x1a0000	; 4Mbit VRAM

; === VGA I/O Ports ===
.equ VGA_ATTR_ADDR, 0x3c0	; Attribute Controller Address/Data
.equ VGA_MISC_OUTPUT, 0x3c2	; Miscellaneous Output Register (write)
.equ VGA_ENABLE, 0x3c3	; VGA Enable
.equ VGA_SEQ_ADDR, 0x3c4	; Sequencer Address
.equ VGA_SEQ_DATA, 0x3c5	; Sequencer Data
.equ VGA_DAC_MASK, 0x3c6	; DAC Mask
.equ VGA_DAC_ADDR_WRITE, 0x3c8	; DAC Write Address
.equ VGA_DAC_DATA, 0x3c9	; DAC Data (R, G, B sequentially)
.equ VGA_GC_ADDR, 0x3ce	; Graphics Controller Address
.equ VGA_GC_DATA, 0x3cf	; Graphics Controller Data
.equ VGA_CRTC_ADDR, 0x3d4	; CRTC Address
.equ VGA_CRTC_DATA, 0x3d5	; CRTC Data
.equ VGA_INPUT_STATUS, 0x3da	; Input Status 1

; === CRTC Register Indices ===
.equ CRTC_HORIZ_TOTAL, 0x0	; Horizontal Total
.equ CRTC_HORIZ_DISP_END, 0x1	; Horizontal Display End
.equ CRTC_START_HORIZ_BLANK, 0x2	; Start Horizontal Blanking
.equ CRTC_END_HORIZ_BLANK, 0x3	; End Horizontal Blanking
.equ CRTC_START_HORIZ_RETRACE, 0x4	; Start Horizontal Retrace
.equ CRTC_END_HORIZ_RETRACE, 0x5	; End Horizontal Retrace
.equ CRTC_VERT_TOTAL, 0x6	; Vertical Total
.equ CRTC_OVERFLOW, 0x7	; Overflow
.equ CRTC_PRESET_ROW_SCAN, 0x8	; Preset Row Scan
.equ CRTC_MAX_SCAN_LINE, 0x9	; Maximum Scan Line
.equ CRTC_CURSOR_START, 0xa	; Cursor Start
.equ CRTC_CURSOR_END, 0xb	; Cursor End
.equ CRTC_START_ADDR_HIGH, 0xc	; Start Address High
.equ CRTC_START_ADDR_LOW, 0xd	; Start Address Low
.equ CRTC_CURSOR_LOC_HIGH, 0xe	; Cursor Location High
.equ CRTC_CURSOR_LOC_LOW, 0xf	; Cursor Location Low
.equ CRTC_VERT_RETRACE_START, 0x10	; Vertical Retrace Start
.equ CRTC_VERT_RETRACE_END, 0x11	; Vertical Retrace End (+ Protect bit 7)
.equ CRTC_VERT_DISP_END, 0x12	; Vertical Display End
.equ CRTC_OFFSET, 0x13	; Offset (logical line width / 2)
.equ CRTC_UNDERLINE_LOC, 0x14	; Underline Location
.equ CRTC_START_VERT_BLANK, 0x15	; Start Vertical Blanking
.equ CRTC_END_VERT_BLANK, 0x16	; End Vertical Blanking
.equ CRTC_MODE_CONTROL, 0x17	; Mode Control
.equ CRTC_LINE_COMPARE, 0x18	; Line Compare

; === Graphics Controller Register Indices ===
.equ GC_SET_RESET, 0x0	; Set/Reset
.equ GC_ENABLE_SET_RESET, 0x1	; Enable Set/Reset
.equ GC_COLOR_COMPARE, 0x2	; Color Compare
.equ GC_DATA_ROTATE, 0x3	; Data Rotate
.equ GC_READ_MAP_SELECT, 0x4	; Read Map Select
.equ GC_GRAPHICS_MODE, 0x5	; Graphics Mode
.equ GC_MISC_GRAPHICS, 0x6	; Miscellaneous Graphics
.equ GC_COLOR_DONT_CARE, 0x7	; Color Don't Care
.equ GC_BIT_MASK, 0x8	; Bit Mask

; === Attribute Controller Register Indices ===
.equ ATTR_MODE_CONTROL, 0x10	; Mode Control
.equ ATTR_OVERSCAN_COLOR, 0x11	; Overscan Color
.equ ATTR_COLOR_PLANE_ENABLE, 0x12	; Color Plane Enable
.equ ATTR_HORIZ_PIXEL_PAN, 0x13	; Horizontal Pixel Panning
.equ ATTR_COLOR_SELECT, 0x14	; Color Select
