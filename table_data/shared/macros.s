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

; desc_entry - one {width16, height16, pointer32} drawing-descriptor entry,
; the record format shared by BitmapDescriptorTable, FrameDescriptorTable
; and IconTable (all consumed index*8 by DrawBitmap/DrawFrameSP/DrawIcons)
.macro desc_entry width, height, pixels
	.short \width, \height
	.long \pixels
.endm
