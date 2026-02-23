; =============================================================================
; gui_constants.asm - GUI/Display Constants for Main CPU
; =============================================================================
; This file contains all GUI and display-related constants and RAM addresses
; specific to the Main CPU ROM.
;
; Contents:
;   - Display state variables (dirty flags, enable flags)
;   - Offscreen buffer addresses
;   - Screen dimensions and layout constants
;
; Note: VGA hardware constants are in ../shared/vga_constants.asm
; =============================================================================

; =============================================================================
; Display State Variables (in RAM at 0x2xxxxx)
; =============================================================================
; These variables track the display update state for the dirty region system.
; The firmware uses a bitmap of dirty flags to minimize screen updates.

DISPLAY_DIRTY_FLAGS		EQU  0205E4h	; Bitmap of dirty display regions
DISPLAY_ENABLE_FLAG		EQU  0205E6h	; Display update enable flag
DISPLAY_CACHED_VAL1		EQU  0205E8h	; Cached value for comparison
DISPLAY_CACHED_VAL2		EQU  0205EAh	; Cached value for comparison
DISPLAY_CACHED_VAL3		EQU  0205ECh	; Cached value for comparison

; =============================================================================
; Offscreen Video Buffers (in RAM)
; =============================================================================
; The KN5000 uses multiple offscreen buffers for double-buffering and
; compositing. These are blitted to VIDEO_RAM_BASE (0x1A0000) for display.
;
; Screen resolution: 320x240 @ 8bpp = 76,800 bytes per buffer
; Buffer layout:
;   OFFSCREEN_BUFFER_1: 0x043C00 - Primary offscreen buffer
;   OFFSCREEN_BUFFER_2: 0x056800 - Secondary buffer (scrolling/animation)
;   OFFSCREEN_BUFFER_3: 0x05FE00 - Tertiary buffer (compositing)
;   OFFSCREEN_BUFFER_4: 0x069400 - Quaternary buffer (sprites/overlays)

OFFSCREEN_BUFFER_1		EQU 043C00h	; Primary offscreen buffer
OFFSCREEN_BUFFER_2		EQU 056800h	; Secondary buffer
OFFSCREEN_BUFFER_3		EQU 05FE00h	; Tertiary buffer
OFFSCREEN_BUFFER_4		EQU 069400h	; Quaternary buffer

; =============================================================================
; Screen Layout Constants
; =============================================================================
; Display dimensions and common values

SCREEN_WIDTH			EQU 320		; Pixels
SCREEN_HEIGHT			EQU 240		; Pixels
SCREEN_BPP			EQU 8		; Bits per pixel
SCREEN_SIZE_BYTES		EQU SCREEN_WIDTH * SCREEN_HEIGHT	; 76800
SCREEN_SIZE_WORDS		EQU SCREEN_SIZE_BYTES / 2		; 38400

; End of GUI constants
