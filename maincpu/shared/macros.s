; =============================================================================
; Common Assembly Macros
; =============================================================================

; aligned_string - Null-terminated string with 16-bit alignment padding
; Emits the string with null terminator, then pads with 0xFF if needed
; to align the next item to an even address.
.macro aligned_string str:vararg
	.asciz \str
	.p2align 1, 0xff
.endm

; =============================================================================
; NAKA UI Widget System
; =============================================================================

; Widget type bytes (used in the 4-byte header: type, 0x00, 0x60, 0x01)
.equ NAKA_TYPE_PANEL,     0x1e  ; Panel/dialog (31 instances)
.equ NAKA_TYPE_LABEL,     0x2b  ; Label/button with text (765 instances)
.equ NAKA_TYPE_VALUE,     0x2e  ; Value display (148 instances)
.equ NAKA_TYPE_OPTION,    0x2f  ; Option/choice (18 instances)
.equ NAKA_TYPE_SLIDER,    0x30  ; Slider/range (16 instances)
.equ NAKA_TYPE_GROUP,     0x31  ; Composite group (120 instances)
.equ NAKA_TYPE_CONTAINER, 0x34  ; Container/frame (196 instances)
.equ NAKA_TYPE_LIST,      0x66  ; List/selector (110 instances)
.equ NAKA_TYPE_BITMAP,    0x6c  ; Bitmap/image (6 instances)

; Common constants
.equ NAKA_HEADER_HI,  0x0160  ; Fixed upper 16 bits of header
.equ NAKA_INDEX_NONE, 0xFFFF  ; Unused index slot

; naka_header - Emit the 4-byte NAKA widget header
; Usage: naka_header NAKA_TYPE_LABEL
.macro naka_header type
	.byte \type, 0x00, 0x60, 0x01
.endm
