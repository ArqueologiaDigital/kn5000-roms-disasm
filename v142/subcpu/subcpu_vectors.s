	.text

	.include "shared/sfr_tmp94c241.s"

.equ INTER_CPU_COMM_LATCHES, 0x120000	; This is a pair of 8-bit latches used for
                                    ; bidirectional communication between
                                    ; maincpu and subcpu

; Shared with boot ROM (persists after payload load)
	; (EQU→inline label) PAYLOAD_LOADED_FLAG = 0x4FE

; Payload-specific state variables
	; (EQU→inline label) SERIAL_1_VAR_1034 = 0x1034
	; (EQU→inline label) SERIAL_1_VAR_1038 = 0x1038
	; (EQU→inline label) DMA_XFER_STATE = 0x10E8
	; (EQU→inline label) CMD_PROCESSING_STATE = 0x10EA
	; (EQU→inline label) BYTE_FROM_MAINCPU_LATCH = 0x10EC

	.org 0x400 - 0x400, 0xFF

INT_HANDLER_00:	; 0400
	jp RESET
	ret

INT_HANDLER_01:	; 0405
	jp EMPTY_HANDLER
	ret

INT_HANDLER_02:	; 040A
	jp EMPTY_HANDLER
	ret

INT_HANDLER_03:	; 040F
	jp EMPTY_HANDLER
	ret

INT_HANDLER_04:	; 0414
	jp EMPTY_HANDLER
	ret

INT_HANDLER_05:	; 0419
	jp EMPTY_HANDLER
	ret

INT_HANDLER_06:	; 041E
	jp EMPTY_HANDLER
	ret

INT_HANDLER_07:	; 0423
	jp EMPTY_HANDLER
	ret

INT_HANDLER_08:	; 0428: watchdog
	jp EMPTY_HANDLER_WITH_RESET
	ret

INT_HANDLER_09:	; 042D: Interrupt #0: Receive data from main-cpu via 8bit latch
	jp INT0_HANDLER
	ret

INT_HANDLER_0A:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_0B:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_0C:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_0D:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_0E:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_0F:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_10:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_11:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_12:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_13:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_14:
	jp Timer_AudioTick_Handler
	ret

INT_HANDLER_15:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_16:
	jp INT16_TaskSwitch_Handler
	ret

INT_HANDLER_17:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_18:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_19:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_1A:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_1B:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_1C:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_1D:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_1E:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_1F:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_20:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_21:
	jp INTRX1_HANDLER
	ret

INT_HANDLER_22:
	jp INTTX1_HANDLER
	ret

INT_HANDLER_23:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_24:
	jp MICRODMA_CH0_HANDLER	; Channel #0 completion
	ret

INT_HANDLER_25:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_26:
	jp MICRODMA_CH2_HANDLER	; Channel #2 completion (STOP AND CLEAR TIMER #2)
	ret

INT_HANDLER_27:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_28:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_29:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_2A:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_2B:
	jp EMPTY_HANDLER
	ret

INT_HANDLER_2C:
	jp MUTE_AND_HALT
	ret

