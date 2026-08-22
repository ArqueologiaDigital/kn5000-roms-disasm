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
	.long RESET_HANDLER
	.long Empty_Handler
	.long Empty_Handler
	.long Empty_Handler
	.long Empty_Handler
	.long Empty_Handler
	.long Empty_Handler
	.long Empty_Handler
	.long NMI_HANDLER
	.long Watchdog_Reset_Handler
	.long INT0_HANDLER
	.long INT4_HANDLER
	.long INT5_HANDLER
	.long Empty_Handler
	.long Empty_Handler
	.long Empty_Handler
	.long Empty_Handler
	.long Empty_Handler
	.long INTA_HANDLER
	.long Empty_Handler
	.long Empty_Handler
	.long INTT1_HANDLER
	.long INTT2_HANDLER
	.long INTT3_HANDLER
	.long INTTR4_HANDLER
	.long Empty_Handler
	.long Empty_Handler
	.long Empty_Handler
	.long Empty_Handler
	.long Empty_Handler
	.long Empty_Handler
	.long Empty_Handler
	.long SndParam_Widget1_AppendType2 + 43
	.long SndParam_WidgetNotifyType1 + 15
	.long INTRX1_HANDLER
	.long INTTX1_HANDLER
	.long Empty_Handler
	.long INTTC0_HANDLER
	.long Empty_Handler
	.long INTTC2_HANDLER
	.long INTTC3_HANDLER
	.long Empty_Handler
	.long Empty_Handler
	.long Empty_Handler
	.long Empty_Handler
	.long 0xffffffff
	.long 0xffffffff
	.long 0xffffffff
	.long 0xffffffff
	.long 0xffffffff
	.long 0xffffffff
	.long 0xffffffff
	.long 0xffffffff
	.long 0xffffffff
	.long 0xffffffff
	.long 0xffffffff
	.long 0xffffffff
	.long 0xffffffff
FIRMWARE_VERSION:
	.byte FW_VERSION_BYTE

; RESERVED:
	.fill 23, 1, 0xff
