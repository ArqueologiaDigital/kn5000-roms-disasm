; =============================================================================
; ROM End Structure - Interrupt Vector Table & Firmware Version
; =============================================================================
; Located at the end of the 2MB Program ROM (FFFFF0-FFFFFF area)
; Contains:
;   - System timestamp pointers (4 x .long)
;   - TMP94C241C interrupt vector table (42 vectors)
;   - Firmware version byte
;   - Reserved padding

	.set FW_VERSION_BYTE, 0x07

System_TimestampPointers:
	.long 0x409
	.long 0x409
	.long 0x409
	.long 0x409
InterruptVectorTable:
	.incbin "includes/generated/v7_transplant_InterruptVectorTable.bin"
FIRMWARE_VERSION:
	.byte FW_VERSION_BYTE

; RESERVED:
	.fill 23, 1, 0xff
