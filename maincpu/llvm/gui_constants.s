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

.equ DISPLAY_DIRTY_FLAGS, 0x205E4	; Bitmap of dirty display regions
.equ DISPLAY_ENABLE_FLAG, 0x205E6	; Display update enable flag
.equ DISPLAY_CACHED_VAL1, 0x205E8	; Cached value for comparison
.equ DISPLAY_CACHED_VAL2, 0x205EA	; Cached value for comparison
.equ DISPLAY_CACHED_VAL3, 0x205EC	; Cached value for comparison

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

.equ OFFSCREEN_BUFFER_1, 0x43C00	; Primary offscreen buffer
.equ OFFSCREEN_BUFFER_2, 0x56800	; Secondary buffer
.equ OFFSCREEN_BUFFER_3, 0x5FE00	; Tertiary buffer
.equ OFFSCREEN_BUFFER_4, 0x69400	; Quaternary buffer

; =============================================================================
; Screen Layout Constants
; =============================================================================
; Display dimensions and common values

.equ SCREEN_WIDTH, 320	; Pixels
.equ SCREEN_HEIGHT, 240	; Pixels
.equ SCREEN_BPP, 8	; Bits per pixel
.equ SCREEN_SIZE_BYTES, SCREEN_WIDTH * SCREEN_HEIGHT	; 76800
.equ SCREEN_SIZE_WORDS, SCREEN_SIZE_BYTES / 2	; 38400

; End of GUI constants
