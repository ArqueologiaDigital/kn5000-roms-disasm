; =============================================================================
; ROM End Structure - Interrupt Vector Table & Firmware Version
; =============================================================================
; Located at the end of the 2MB Program ROM (FFFFF0-FFFFFF area)
; Contains:
;   - System timestamp pointers (4 x .long)
;   - TMP94C241C interrupt vector table (42 vectors)
;   - Firmware version byte (0x0a = v10)
;   - Reserved padding

System_TimestampPointers:
	.long 0x409
	.long 0x409
	.long 0x409
	.long 0x409
InterruptVectorTable:


; TMP94C241C Interrupt Vector Table:
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

	.long INTRX0_HANDLER
	.long INTTX0_HANDLER
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

; RESERVED:
	.fill 52, 1, 0xff

FIRMWARE_VERSION:
	.byte 0x0a

; RESERVED:
	.fill 23, 1, 0xff
