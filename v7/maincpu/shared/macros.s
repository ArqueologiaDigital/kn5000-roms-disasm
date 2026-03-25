; =============================================================================
; Common Assembly Macros
; =============================================================================

; aligned_string - Null-terminated string with 16-bit alignment padding
; Emits the string with null terminator, then pads with 0xff if needed
; to align the next item to an even address.
.macro aligned_string str:vararg
	.asciz \str
	.p2align 1, 0xff
.endm

; =============================================================================
; NAKA UI Widget System
; =============================================================================

; Widget type bytes (used in the 4-byte header: type, 0x00, 0x60, 0x01)
; Named types -- semantics confirmed from context:
.equ NAKA_TYPE_DIAGLIST,  0x16  ; Diagnostic list item (3 instances, FD test only)
.equ NAKA_TYPE_PANEL,     0x1e  ; Panel/dialog (31 instances)
.equ NAKA_TYPE_LABEL,     0x2b  ; Label/button with text (765 instances)
.equ NAKA_TYPE_VALUE,     0x2e  ; Value display (148 instances)
.equ NAKA_TYPE_OPTION,    0x2f  ; Option/choice (18 instances)
.equ NAKA_TYPE_SLIDER,    0x30  ; Slider/range (16 instances)
.equ NAKA_TYPE_GROUP,     0x31  ; Composite group (120 instances)
.equ NAKA_TYPE_CONTAINER, 0x34  ; Container/frame (196 instances)
.equ NAKA_TYPE_LIST,      0x66  ; List/selector (110 instances)
.equ NAKA_TYPE_BITMAP,    0x6c  ; Bitmap/image (6 instances)
.equ NAKA_TYPE_MENU_ITEM, 0x1d  ; Menu item with title (97 instances)

; Numeric types -- semantics unknown, named by hex value:
.equ NAKA_TYPE_0x00, 0x00  ; (22 instances)
.equ NAKA_TYPE_0x01, 0x01  ; (2 instances)
.equ NAKA_TYPE_0x10, 0x10  ; (28 instances)
.equ NAKA_TYPE_0x11, 0x11  ; (76 instances)
.equ NAKA_TYPE_0x12, 0x12  ; (67 instances)
.equ NAKA_TYPE_0x13, 0x13  ; (3 instances)
.equ NAKA_TYPE_0x14, 0x14  ; (16 instances)
.equ NAKA_TYPE_0x15, 0x15  ; (68 instances)
.equ NAKA_TYPE_0x18, 0x18  ; (1 instance)
.equ NAKA_TYPE_0x1A, 0x1a  ; (21 instances)
.equ NAKA_TYPE_0x1B, 0x1b  ; (20 instances)
.equ NAKA_TYPE_0x1C, 0x1c  ; (6 instances)
.equ NAKA_TYPE_0x1F, 0x1f  ; (163 instances)
.equ NAKA_TYPE_0x20, 0x20  ; (87 instances)
.equ NAKA_TYPE_0x21, 0x21  ; (4 instances)
.equ NAKA_TYPE_0x22, 0x22  ; (137 instances)
.equ NAKA_TYPE_0x23, 0x23  ; (8 instances)
.equ NAKA_TYPE_0x24, 0x24  ; (4 instances)
.equ NAKA_TYPE_0x25, 0x25  ; (14 instances)
.equ NAKA_TYPE_0x26, 0x26  ; (7 instances)
.equ NAKA_TYPE_0x27, 0x27  ; (39 instances)
.equ NAKA_TYPE_0x28, 0x28  ; (50 instances)
.equ NAKA_TYPE_0x29, 0x29  ; (39 instances)
.equ NAKA_TYPE_0x2A, 0x2a  ; (3 instances)
.equ NAKA_TYPE_0x2C, 0x2c  ; (11 instances)
.equ NAKA_TYPE_0x2D, 0x2d  ; (9 instances)
.equ NAKA_TYPE_0x32, 0x32  ; (2 instances)
.equ NAKA_TYPE_0x33, 0x33  ; (28 instances)
.equ NAKA_TYPE_0x35, 0x35  ; (131 instances)
.equ NAKA_TYPE_0x36, 0x36  ; (5 instances)
.equ NAKA_TYPE_0x37, 0x37  ; (9 instances)
.equ NAKA_TYPE_0x3A, 0x3a  ; (1 instance)
.equ NAKA_TYPE_0x3B, 0x3b  ; (1 instance)
.equ NAKA_TYPE_0x3C, 0x3c  ; (11 instances)
.equ NAKA_TYPE_0x3D, 0x3d  ; (41 instances)
.equ NAKA_TYPE_0x3E, 0x3e  ; (74 instances)
.equ NAKA_TYPE_0x3F, 0x3f  ; (10 instances)
.equ NAKA_TYPE_0x40, 0x40  ; (4 instances)
.equ NAKA_TYPE_0x41, 0x41  ; (18 instances)
.equ NAKA_TYPE_0x42, 0x42  ; (1 instance)
.equ NAKA_TYPE_0x43, 0x43  ; (2 instances)
.equ NAKA_TYPE_0x44, 0x44  ; (14 instances)
.equ NAKA_TYPE_0x45, 0x45  ; (10 instances)
.equ NAKA_TYPE_0x46, 0x46  ; (1 instance)
.equ NAKA_TYPE_0x47, 0x47  ; (26 instances)
.equ NAKA_TYPE_0x48, 0x48  ; (18 instances)
.equ NAKA_TYPE_0x49, 0x49  ; (23 instances)
.equ NAKA_TYPE_0x4A, 0x4a  ; (6 instances)
.equ NAKA_TYPE_0x4B, 0x4b  ; (1 instance)
.equ NAKA_TYPE_0x4C, 0x4c  ; (1 instance)
.equ NAKA_TYPE_0x4D, 0x4d  ; (13 instances)
.equ NAKA_TYPE_0x4E, 0x4e  ; (11 instances)
.equ NAKA_TYPE_0x4F, 0x4f  ; (8 instances)
.equ NAKA_TYPE_0x50, 0x50  ; (1 instance)
.equ NAKA_TYPE_0x51, 0x51  ; (36 instances)
.equ NAKA_TYPE_0x52, 0x52  ; (7 instances)
.equ NAKA_TYPE_0x53, 0x53  ; (1 instance)
.equ NAKA_TYPE_0x54, 0x54  ; (27 instances)
.equ NAKA_TYPE_0x55, 0x55  ; (9 instances)
.equ NAKA_TYPE_0x56, 0x56  ; (3 instances)
.equ NAKA_TYPE_0x57, 0x57  ; (1 instance)
.equ NAKA_TYPE_0x58, 0x58  ; (6 instances)
.equ NAKA_TYPE_0x59, 0x59  ; (32 instances)
.equ NAKA_TYPE_0x5A, 0x5a  ; (2 instances)
.equ NAKA_TYPE_0x5B, 0x5b  ; (9 instances)
.equ NAKA_TYPE_0x5C, 0x5c  ; (2 instances)
.equ NAKA_TYPE_0x5D, 0x5d  ; (1 instance)
.equ NAKA_TYPE_0x5E, 0x5e  ; (6 instances)
.equ NAKA_TYPE_0x5F, 0x5f  ; (1 instance)
.equ NAKA_TYPE_0x60, 0x60  ; (1 instance)
.equ NAKA_TYPE_0x61, 0x61  ; (1 instance)
.equ NAKA_TYPE_0x62, 0x62  ; (5 instances)
.equ NAKA_TYPE_0x63, 0x63  ; (10 instances)
.equ NAKA_TYPE_0x64, 0x64  ; (34 instances)
.equ NAKA_TYPE_0x65, 0x65  ; (2 instances)
.equ NAKA_TYPE_0x67, 0x67  ; (5 instances)
.equ NAKA_TYPE_0x68, 0x68  ; (3 instances)
.equ NAKA_TYPE_0x69, 0x69  ; (9 instances)
.equ NAKA_TYPE_0x6A, 0x6a  ; (2 instances)
.equ NAKA_TYPE_0x6B, 0x6b  ; (3 instances)
.equ NAKA_TYPE_0xEC, 0xec  ; (1 instance)
.equ NAKA_TYPE_0xED, 0xed  ; (1 instance)
.equ NAKA_TYPE_0xFC, 0xfc  ; (2 instances)

; Common constants
.equ NAKA_HEADER_HI,  0x0160  ; Fixed upper 16 bits of header
.equ NAKA_INDEX_NONE, 0xffff  ; Unused index slot

; naka_header - Emit the 4-byte NAKA widget header
; Usage: naka_header NAKA_TYPE_LABEL
.macro naka_header type
	.byte \type, 0x00, 0x60, 0x01
.endm

; addr24 - Emit a 24-bit little-endian address from a .set constant
; Usage: addr24 SymbolName
; Used for embedded addresses in bytecode/data tables where the
; assembler cannot emit 3-byte relocations for positional labels.
.macro addr24 sym
	.reloc ., R_TLCS900_24, \sym
	.space 3
.endm
