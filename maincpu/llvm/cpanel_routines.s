; =============================================================================
; cpanel_routines.asm - Control Panel Communication Routines
; =============================================================================
; This file contains all control panel communication routines for the KN5000
; Main CPU. The control panel consists of two MCUs (left and right panels)
; that communicate with the main CPU via serial protocol.
;
; Routines included:
;   Initialization:
;     CPanel_InitHardware       - Initialize serial port and buffers
;     CPanel_SendInitSequence   - Send initialization sequence to panels
;     CPanel_InitLEDBuffer      - Initialize LED TX buffer
;     CPanel_InitButtonState    - Initialize button state arrays
;
;   Button Handling:
;     CPanel_ScanButtons        - Main button scan entry point
;     CPanel_ReadAllButtons     - Read button states from both panels
;     CPanel_CheckSpecialCombos - Check for special button combinations
;     CPanel_PollStartup        - Poll buttons during startup
;     CPanel_ButtonPollLoop     - Button polling loop
;     CPanel_EncoderCheck       - Check encoder state
;
;   Serial Communication:
;     CPanel_WaitTXReady        - Wait for TX ready
;     CPanel_SendCommand        - Send command to panel
;
;   State Machine:
;     CPANEL_STATE_MACHINE_TABLE - State machine jump table
;     CPanel_SM_StartTX         - Start TX state
;     CPanel_SM_TXDelay1/2      - TX delay states
;     CPanel_SM_SendByte1/N     - Send byte states
;     CPanel_SM_TXComplete      - TX complete state
;     CPanel_SM_RXByte1/N       - Receive byte states
;     CPanel_SM_Idle            - Idle state
;
;   Packet Processing:
;     CPanel_RX_ProcessWithFlag - Process RX with flag
;     CPanel_RX_Process         - Main RX processing
;     CPanel_RX_ParseNext       - Parse next packet
;     CPanel_RX_PacketHandlers  - Packet type dispatch table
;     CPanel_RX_ButtonPacket    - Handle button packets
;     CPanel_RX_EncoderPacket   - Handle encoder packets
;     CPanel_RX_MultiBytePacket - Handle multi-byte packets
;     CPanel_RX_SyncPacket      - Handle sync packets
;
;   LED Control:
;     CPanel_UpdateLEDs         - Update LED states
;     CPanel_LED_PacketHandlers - LED packet dispatch table
;
;   Buffer Management:
;     CPanel_IncRXPtr           - Increment RX buffer pointer
;     CPanel_IncLEDPtr          - Increment LED buffer pointer
;     CPanel_IncEventPtr        - Increment event queue pointer
;     CPanel_DecEventPtr        - Decrement event queue pointer
;
; Required includes before this file:
;   - cpanel_constants.asm (or equivalent EQU definitions)
;
; =============================================================================

CPanel_ScanButtons:	; FC3EE5
	push XIX
	push XIZ
	push XHL
	push XDE
	call CPanel_ReadAllButtons
	pop XDE
	pop XHL
	pop XIZ
	pop XIX
	CALR CPanel_CheckSpecialCombos
	ret


CPanel_InitHardware:
	ld XHL, CPANEL_RX_EVENT_QUEUE
	ldw (XHL - 4), 0x0
	ldw (XHL - 8), 0x0
	ldw (XHL - 2), 0x80

	ld XHL, CPANEL_LED_EVENT_QUEUE
	ldw (XHL - 4), 0x0
	ldw (XHL - 8), 0x0
	ldw (XHL - 2), 0x80

	LD_A 0x3	; PF2=SCK0 Disabled, PF0=TxD0 and PF1=RXD0 (MIDI)
	and A, 0xaf	; PF6=SCK1 Disabled, PF4=TxD1 and PF5=RXD1 (Control Panel)
	ld (PFFC_VALUE), A
	ld (PFFC), A
	LD_A 0x15
	and A, 0x8f
	ld (PFCR_VALUE), A
	ld (PFCR), A
	and (PF), 0xbf	; PF bit 6, (SCLK1 | /CTS1) = 0
	LD_A 0x0
	ld (PEFC), A
	LD_A 0x46
	ld (PECR), A
	ld (SC1MOD), 0x0	; serial clk: TO2 trigger
	                  ; serial transfer mode: I/O  transfer mode
	                  ; wake-up function: disable
	                  ; receive control: receive disable
	                  ; handshake function control: CTS disable
	ld (BR1CR), 0x14	; Internal Clock T2 (16/fc)
	                 ; Divide by 4
	                 ; fc = 16MHz, so fc/16/4 = 250kHz
	ld (SC1CR), 0x1	; Parity: odd
	                 ; Parity addition: disable
	                 ; clear all errors
	                 ; Data transmit/receive at SCLK1 rising edge
	                 ; I/O interface input clock: SCLK1 pin input
	ld (INTEAB), 0x7
	ld (INTCLR), 0x12	; INTA Pin
	ld (INTES1), 0xff
	ld (INTCLR), 0x22	; INTRX1: Serial receive 1
	ld (INTCLR), 0x23	; INTTX1: Serial send 1
	or (TAMOD), 0x10
	and (TAMOD), 0xf7
	ld (CPANEL_UNUSED_1), 0x7d	; This looks pointless...

	or (CPANEL_TX_RX_FLAGS), 0x40	; CP_Flags_A.6 = 1
	ld (CPANEL_PACKET_BYTE_COUNT), 0x0
	and (CPANEL_TX_RX_FLAGS), 0xfc	; CP_Flags_A.10 = 00
	ldw (CPANEL_LED_READ_PTR), 0x0
	ldw (CPANEL_LED_WRITE_PTR), 0x0
	ldw (CPANEL_RX_READ_PTR), 0x0
	ldw (CPANEL_RX_WRITE_PTR), 0x0

	CALR DELAY_6_TICKS

	LD_A 0x1f
	LD_W 0xda
	CALR CPanel_SendCommand
	CALR DELAY_3000_LOOPS

	ldw (CPANEL_LED_READ_PTR), 0x0
	CALR DELAY_3000_LOOPS

	CALR CPanel_SendInitSequence
	ret


; CPanel_SendInitSequence - Send initialization command sequence to control panel MCUs
; Commands sent: 0x1F 0x1A, 0x1D 0x00, 0xDD 0x03, 0x1E 0x80
CPanel_SendInitSequence:
	LD_A 0x1f
	LD_W 0x1a
	CALR CPanel_SendCommand
	CALR DELAY_3000_LOOPS

	ldw (CPANEL_LED_READ_PTR), 0x0
	CALR DELAY_3000_LOOPS

	LD_A 0x1d
	LD_W 0
	CALR CPanel_SendCommand
	CALR DELAY_3000_LOOPS

	ldw (CPANEL_LED_READ_PTR), 0x0
	CALR DELAY_3000_LOOPS
	CALR DELAY_3000_LOOPS

	LD_A 0xdd
	LD_W 0x3
	CALR CPanel_SendCommand
	CALR DELAY_3000_LOOPS

	ldw (CPANEL_LED_READ_PTR), 0x0
	CALR DELAY_3000_LOOPS
	CALR DELAY_3000_LOOPS

	LD_A 0x1e
	LD_W 0x80
	CALR CPanel_SendCommand
	CALR DELAY_3000_LOOPS
	CALR DELAY_3000_LOOPS
	CALR DELAY_3000_LOOPS

	ei 0x6
	ld (INTES1), 0xff
	ld (INTCLR), 0x22	; INTRX1: Serial receive 1
	ld (INTCLR), 0x23	; INTTX1: Serial send 1
	and (SC1MOD), 0xdf	; RXE (bit 5) = 0: receive disable
	ld (INTCLR), 0x12	; INTA Pin
	ld (INTEAB), 0x5
	ldw (CPANEL_RX_READ_PTR), 0x0
	ldw (CPANEL_RX_WRITE_PTR), 0x0
	or (CPANEL_PROTOCOL_FLAGS), 0x1	; CP_Flags_B.0 = 1
	ei 0x0
	ret


CPanel_InitLEDBuffer:
	ld (CPANEL_LED_TX_BUFFER), WA
	and (PFFC_VALUE), 0xbf
	ld A, (PFFC_VALUE)
	ld (PFFC), A
	ld (0xeb), 0xff
	ld (0xf8), 0x22
	ld (0xf8), 0x23
	ld (0xe3), 0x7
	ld (0xf8), 0x12
	and (0x3c), 0xbf
	or (PFCR_VALUE), 0x40
	ld A, (PFCR_VALUE)
	ld (PFCR), A
	CALR DELAY_300_LOOPS
	CALR DELAY_300_LOOPS
	and (PFCR_VALUE), 0xbf
	ld A, (PFCR_VALUE)
	ld (PFCR), A
	CALR DELAY_300_LOOPS
	CALR DELAY_300_LOOPS
	or (PFFC_VALUE), 0x50
	ld A, (PFFC_VALUE)
	ld (PFFC), A
	or (PFCR_VALUE), 0x50
	ld A, (PFCR_VALUE)
	ld (PFCR), A
	and (SC1CR), 0xfe
	ld (0xeb), 0xff
	ld (0xf8), 0x22
	ld (0xf8), 0x23
	ld XIY, CPANEL_LED_TX_BUFFER
	add IY, (CPANEL_LED_READ_PTR)
	ld A, (XIY)
	INCW 1, (CPANEL_LED_READ_PTR)
	ld (SC1BUF), A
	CALR DELAY_300_LOOPS
	CALR DELAY_300_LOOPS
	ld XIY, CPANEL_LED_TX_BUFFER
	add IY, (CPANEL_LED_READ_PTR)
	ld A, (XIY)
	INCW 1, (CPANEL_LED_READ_PTR)
	ld (SC1BUF), A
	CALR DELAY_300_LOOPS
	CALR DELAY_300_LOOPS
	or (SC1CR), 0x1
	and (SC1CR), 0xfd
	and (PFCR_VALUE), 0xaf
	ld A, (PFCR_VALUE)
	ld (PFCR), A
	and (PFFC_VALUE), 0xaf
	ld A, (PFFC_VALUE)
	ld (PFFC), A
	ret



; Below are routines that loop N times, where
; N = 2, 6, 10, 300, 1500 or 3000
; These are likely pauses
; But these values are also suspiciously similar to proportions
; between typical baudrates, but this is just a hunch for now...

LABEL_FC0DE:
	ld WA, 2

LABEL_FC40E0:
	dec 1, WA
	cp WA, 0
	jr Z, LABEL_FC40E8
	jr LABEL_FC40E0

LABEL_FC40E8:
	ret


Delay_6_Loops:
	ld WA, 6

LABEL_FC40EB:
	dec 1, WA
	cp WA, 0
	jr Z, LABEL_FC40F3
	jr LABEL_FC40EB

LABEL_FC40F3:
	ret


DELAY_10_LOOPS:	; FC40F4
	ld WA, 0xa

LABEL_FC40F7:
	dec 1, WA
	cp WA, 0
	jr Z, LABEL_FC40FF
	jr LABEL_FC40F7

LABEL_FC40FF:
	ret


DELAY_300_LOOPS:	; FC4100
	ld WA, 0x12c

LABEL_FC4103:
	dec 1, WA
	cp WA, 0
	jr Z, LABEL_FC410B
	jr LABEL_FC4103

LABEL_FC410B:
	ret


DELAY_1500_LOOPS:	; FC410C
	ld WA, 0x5dc

LABEL_FC410F:
	dec 1, WA
	cp WA, 0
	jr Z, LABEL_FC4117
	jr LABEL_FC410F

LABEL_FC4117:
	ret


DELAY_3000_LOOPS:	; FC4118
	ld WA, 0xbb8

LABEL_FC411B:
	dec 1, WA
	cp WA, 0
	jr Z, LABEL_FC4123
	jr LABEL_FC411B

LABEL_FC4123:
	ret


LABEL_FC4124:
	.byte 0xD1, 0x9, 0x4, 0x20, 0xF1, 0x9B, 0x8D, 0x50
	.byte 0xD1, 0x9, 0x4, 0x20, 0xD1, 0x9B, 0x8D, 0xA0
	.byte 0xD8, 0xDA, 0x61, 0xF4, 0xE


DELAY_6_TICKS:
	ld WA, (SYSTEM_TIMESTAMP)
	ld (TIMESTAMP_FOR_DELAY), WA

LABEL_FC4141:
	ld WA, (SYSTEM_TIMESTAMP)
	sub WA, (TIMESTAMP_FOR_DELAY)
	cp WA, 6
	jr LT, LABEL_FC4141
	ret


DELAY_51_TICKS:
	ld WA, (SYSTEM_TIMESTAMP)
	ld (TIMESTAMP_FOR_DELAY), WA

LABEL_FC4156:
	ld WA, (SYSTEM_TIMESTAMP)
	sub WA, (TIMESTAMP_FOR_DELAY)
	cp WA, 0x33
	jr LT, LABEL_FC4156
	ret

; ???? R        L
; ???? 25 (001 00101): 01 | e2 (111 00010): 04
; ???? 20 (001 00000): 10 | e2 (111 00010): 11

CPanel_CheckSpecialCombos:
	cp (STATE_OF_CPANEL_BUTTONS_LEFT + 4), 0x6c	;  CPL_SEG4 = 0110 1100 = AUTO PLAY CHORD + SPLIT POINT + VARIATION 4 + VARIATION 3 => display sw internal build numbers
	jr NZ, CPanel_SpecialCombo_FirmwareVersion
	ld HL, 3	; SOFT VERSION SCREEN
	jr LABEL_FC4193

CPanel_SpecialCombo_FirmwareVersion:
	cp (STATE_OF_CPANEL_BUTTONS_RIGHT + 1), 0x70	; CPR_SEG1 = 0111 0000 = GM SPECIAL + ACCORDION REGISTER + DIGITAL DRAWBAR => display fw version on screen & LEDs
	jr NZ, CPanel_SpecialCombo_SoftVersion
	ld HL, 2
	jr LABEL_FC4193

CPanel_SpecialCombo_SoftVersion:
	cp (STATE_OF_CPANEL_BUTTONS_LEFT + 6), 0x38	; CPL_SEG6 = 0011 1000 = SHOWTIME & TRAD DANCE + PARTY TIME + MARCH & WALTZ => ?
	jr NZ, CPanel_SpecialCombo_BuildInfo
	ld HL, 1
	jr LABEL_FC4193

CPanel_SpecialCombo_BuildInfo:
	cp (STATE_OF_CPANEL_BUTTONS_RIGHT + 6), 0xf	; CPR_SEG6 = 0000 1111 = 4 panel memory buttons (PM 4 + PM 3 + PM 2 + PM 1) => fw update
	jr NZ, CPanel_SpecialCombo_FirmwareUpdate
	ld HL, 4
	jr LABEL_FC4193

CPanel_SpecialCombo_FirmwareUpdate:
	ld HL, 0

LABEL_FC4193:
	ret


CPanel_PanelDetection:
	ld (CPANEL_PANEL_DETECT_FLAGS), 0x0
	CALR CPanel_WaitTXReady
	ei 0x6
	ldw (CPANEL_RX_READ_PTR), 0x0
	ldw (CPANEL_RX_WRITE_PTR), 0x0
	or (CPANEL_PROTOCOL_FLAGS), 0x1	; CP_Flags_B.0 = 1
	ei 0x0
	LD_A 0x20	; my guess: 20 = 001 00000 where 001 = left-panel mcu
	LD_W 0
	CALR CPanel_SendCommand
	CALR DELAY_6_TICKS
	cpw (CPANEL_RX_WRITE_PTR), 0x0
	jr Z, LABEL_FC41C8
	or (CPANEL_PANEL_DETECT_FLAGS), 0x1	; my guess: CP_Flags_C.0
					  ; = Got response from left-panel MCU

LABEL_FC41C8:
	CALR CPanel_WaitTXReady
	ei 0x6
	ldw (CPANEL_RX_READ_PTR), 0x0
	ldw (CPANEL_RX_WRITE_PTR), 0x0
	or (CPANEL_PROTOCOL_FLAGS), 0x1	; CP_Flags_B.0 = 1
	ei 0x0
	LD_A 0xe0	; my guess: E0 = 111 00000 where 111 = right-panel mcu
	LD_W 0
	CALR CPanel_SendCommand
	CALR DELAY_6_TICKS
	cpw (CPANEL_RX_WRITE_PTR), 0x0
	jr Z, LABEL_FC41F7
	or (CPANEL_PANEL_DETECT_FLAGS), 0x8	; my guess: CP_Flags_C.4
					 ; = Got response from right-panel MCU

LABEL_FC41F7:
	ld A, (CPANEL_PANEL_DETECT_FLAGS)
	ret


CPanel_ReadAllButtons:
	ld XHL, CPANEL_RX_EVENT_QUEUE
	ldw (XHL - 4), 0x0
	ldw (XHL - 8), 0x0
	ldw (XHL - 2), 0x80

	ei 0x6
	ld WA, (CPANEL_RX_READ_PTR)
	ld (CPANEL_RX_WRITE_PTR), WA
	or (CPANEL_PROTOCOL_FLAGS), 0x1	; CP_Flags_B.0 = 1
	ei 0x0

	call CPanel_WaitTXReady
	LD_A 0x25
	LD_W 0x1
	call CPanel_SendCommand
	CALR DELAY_6_TICKS
	CALR DELAY_6_TICKS
	CALR DELAY_6_TICKS

	CALR CPanel_WaitTXReady
	LD_A 0xe2
	LD_W 0x4
	CALR CPanel_SendCommand
	CALR DELAY_6_TICKS
	CALR DELAY_6_TICKS

	CALR CPanel_WaitTXReady
	LD_A 0x20
	LD_W 0x10
	CALR CPanel_SendCommand
	CALR DELAY_6_TICKS
	CALR DELAY_6_TICKS

	CALR CPanel_WaitTXReady
	LD_A 0xe2
	LD_W 0x11
	CALR CPanel_SendCommand
	CALR DELAY_6_TICKS
	CALR DELAY_6_TICKS

	CALR CPanel_RX_Process
	ret


CPanel_PollStartup:
	ld XHL, CPANEL_RX_EVENT_QUEUE
	ldw (XHL - 4), 0x0
	ldw (XHL - 8), 0x0
	ldw (XHL - 2), 0x80
	ei 0x6
	ldw (CPANEL_RX_READ_PTR), 0x0
	ldw (CPANEL_RX_WRITE_PTR), 0x0
	or (CPANEL_PROTOCOL_FLAGS), 0x1	; CP_Flags_B.0 = 1
	ei 0x0

CPanel_ButtonPollLoop:
	CALR CPanel_WaitTXReady
	LD_A 0x20
	LD_W 0xb
	CALR CPanel_SendCommand
	CALR DELAY_6_TICKS
	CALR CPanel_RX_Process

	ld A, (STATE_OF_CPANEL_BUTTONS + 11)	; Byte 11 is in gap between CPR (0-10) and CPL (16-26), possibly status/mode
	LD_W 0xd	; Default encoder check mode
	bit 7, A	; Test bit 7 of status byte
	jr NZ, CPanel_EncoderCheck
	LD_W 0xe	; Alternate mode if bit 7 set
	bit 6, A	; Test bit 6 of status byte
	jr NZ, CPanel_EncoderCheck
	LD_W 0xc	; Third mode if bit 6 set

CPanel_EncoderCheck:
	cp (0x8E6A), W
	ld (0x8E6A), W
	jr NZ, CPanel_ButtonPollLoop
	ld (0x8E6A), W
	ld XHL, CPANEL_RX_EVENT_QUEUE
	ldw (XHL - 4), 0x0
	ldw (XHL - 8), 0x0
	ldw (XHL - 2), 0x80
	ei 0x6
	ldw (CPANEL_LED_READ_PTR), 0x0
	ldw (CPANEL_LED_WRITE_PTR), 0x0
	ldw (CPANEL_RX_READ_PTR), 0x0
	ldw (CPANEL_RX_WRITE_PTR), 0x0
	or (CPANEL_PROTOCOL_FLAGS), 0x1	; CP_Flags_B.0 = 1
	ei 0x0
	ret


CPanel_InitButtonState:	; do that
	ld XHL, CPANEL_RX_EVENT_QUEUE
	ldw (XHL - 4), 0x0
	ldw (XHL - 8), 0x0
	ldw (XHL - 2), 0x80

	ei 0x6
	ld (CPANEL_RX_READ_PTR), 0x0
	ld (CPANEL_RX_WRITE_PTR), 0x0
	or (CPANEL_PROTOCOL_FLAGS), 0x1	; CP_Flags_B.0 = 1
	ei 0x0

	CALR CPanel_WaitTXReady
	LD_A 0x2b
	LD_W 0
	CALR CPanel_SendCommand
	CALR DELAY_6_TICKS
	CALR DELAY_6_TICKS
	CALR DELAY_6_TICKS
	CALR CPanel_RX_ProcessWithFlag

	CALR CPanel_WaitTXReady
	LD_A 0xeb
	LD_W 0
	CALR CPanel_SendCommand
	CALR DELAY_6_TICKS
	CALR DELAY_6_TICKS
	CALR DELAY_6_TICKS
	CALR CPanel_RX_ProcessWithFlag

	CALR CPanel_WaitTXReady
	LD_A 0x20
	LD_W 0x10
	CALR CPanel_SendCommand
	CALR DELAY_6_TICKS
	CALR DELAY_6_TICKS
	CALR CPanel_RX_ProcessWithFlag

	CALR CPanel_WaitTXReady
	LD_A 0xe3
	LD_W 0x10
	CALR CPanel_SendCommand
	CALR DELAY_6_TICKS
	CALR DELAY_6_TICKS
	CALR CPanel_RX_ProcessWithFlag
	ret


CPanel_WaitTXReady:
	ld (CPANEL_COUNTER_DOWN_FROM_200), 0xc8	; =200

CPanel_WaitTXReady_Poll:
	ei 0x6
	bit 6, (PF)	; PF.6 = state of SCLK1 pin == 1, (resting at pull-up)
	jr Z, CPanel_WaitTXReady_Timeout
	bit 5, (PE)	; PE.5 = state of INTA pin == 0
	jr NZ, CPanel_WaitTXReady_Timeout
	bit 1, (CPANEL_TX_RX_FLAGS)
	jr NZ, CPanel_WaitTXReady_Timeout
	bit 0, (CPANEL_TX_RX_FLAGS)
	jr NZ, CPanel_WaitTXReady_Timeout
	jr CPanel_WaitTXReady_BufferCheck

CPanel_WaitTXReady_Timeout:
	dec 1, (CPANEL_COUNTER_DOWN_FROM_200)
	cp (CPANEL_COUNTER_DOWN_FROM_200), 0x0
	jr Z, LABEL_FC43B0
	ei 0x0
	CALR DELAY_1500_LOOPS
	jr CPanel_WaitTXReady_Poll

CPanel_WaitTXReady_BufferCheck:
	; Only reaches here when CP_Flags_A.10 == 00, and I think only CPanel_SM_Idle sets that value...

	ld WA, (CPANEL_LED_WRITE_PTR)
	cp WA, (CPANEL_LED_READ_PTR)
	jr NZ, CPanel_WaitTXReady_Timeout

LABEL_FC43B0:
	ei 0x6
	ld (INTCLR), 0x22	; INTRX1: Serial receive 1
	ld (INTCLR), 0x23	; INTTX1: Serial send 1
	ld (INTES1), 0xdd
	and (SC1MOD), 0xdf	; RXE (bit 5) = 0: receive disable
	or (CPANEL_PROTOCOL_FLAGS), 0x80	; CP_Flags_B.7 = 1
	ei 0x0
	ret


CPanel_SendCommand:
	ei 0x6
	ldw (CPANEL_LED_READ_PTR), 0x0
	ldw (CPANEL_LED_WRITE_PTR), 0x0
	ld (CPANEL_LED_TX_BUFFER), WA
	addw (CPANEL_LED_WRITE_PTR), 0x2
	or (CPANEL_TX_RX_FLAGS), 0x2
	and (CPANEL_TX_RX_FLAGS), 0xfe	; CP_Flags_A.10 = 2
	ld (CPANEL_STATE_MACHINE_INDEX), 0x4	; ROUTINE_1
	ld (BR1CR), 0x28	; Internal Clock T8 (64/fc)
	                 ; Divide by 8
	                 ; fc = 16MHz, so fc/64/8 = 31250
	and (PFFC_VALUE), 0xbf	; disable CPanel serial ckl
	ld A, (PFFC_VALUE)
	ld (PFFC), A
	and (PF), 0xbf	; PF bit 6: SCLK1 = 0
	or (PFCR_VALUE), 0x40
	ld A, (PFCR_VALUE)
	ld (PFCR), A
	ld (INTEAB), 0x7
	ld (INTCLR), 0x12	; INTA Pin
	and (SC1MOD), 0xdf	; RXE (bit 5) = 0: CPanel receive disable
	and (SC1CR), 0xfe	; IOC (bit 0) = 0: I/O interface input clock select = Baud rate generator
	ld (INTCLR), 0x23	; INTTX1: Serial send 1
	ld (INTES1), 0xdf
	ld (INTCLR), 0x22	; INTRX1: Serial receive 1
	ld (SC1BUF), A
	ei 0x0
	nop
	ret


INTA_HANDLER:	; fc442b
	ld (CPANEL_COUNTER_UP_TO_20), 0x0
	push XWA
	cp (CPANEL_PACKET_BYTE_COUNT), 0x0
	jr NZ, LABEL_FC4462

	and (PFCR_VALUE), 0x9f
	ld A, (PFCR_VALUE)
	ld (PFCR), A
	or (SC1CR), 0x1	; IOC (bit 0) = 1: Set I/O interface input clock select to SCLK1 pin
	and (SC1CR), 0xfd	; SCLKS (bit 1) = 0: Data transmit/receive at SCLK1 rising edge.
	ld (INTEAB), 0x5
	ld (INTES1), 0xd
	or (SC1MOD), 0x20	; parity addition: enable
	ld (CPANEL_STATE_MACHINE_INDEX), 0x20	;		ROUTINE_7
	or (CPANEL_TX_RX_FLAGS), 0x1	; CP_Flags_A.0 = 1
	jr INTA_HANDLER_END

LABEL_FC4462:
	cpw (CPANEL_RX_WRITE_PTR), 0x0
	jr NZ, LABEL_FC4470

	ldw (CPANEL_RX_WRITE_PTR), 0x5c

LABEL_FC4470:
	DECW 1, (CPANEL_RX_WRITE_PTR)
	or (CPANEL_PROTOCOL_FLAGS), 0x40	; CP_Flags_B.6 = 1  ; UNUSED
	and (CPANEL_TX_RX_FLAGS), 0xfd	; CP_Flags_A.1 = 0

INTA_HANDLER_END:	; FC447E
	pop XWA
	ld (INTCLR), 0x12	; INTA Pin
	ld (INTCLR), 0x22	; INTRX1: Serial receive 1
	ld (INTCLR), 0x23	; INTTX1: Serial send 1
	reti


CPANEL_STATE_MACHINE_TABLE:	; FC4489
	.long CPanel_SM_Idle	;(offsets: 000h)  ; IDLE
	.long CPanel_SM_StartTX	;(         004h)
	.long CPanel_SM_SendByte1	;(         008h)
	.long CPanel_SM_TXDelay1	;(         00ch)
	.long CPanel_SM_SendByteN	;(         010h)
	.long CPanel_SM_TXDelay2	;(         014h)
	.long CPanel_SM_TXComplete	;(         018h)
	.long CPanel_SM_Idle	;(         01ch)
	.long CPanel_SM_RXByte1	;(         020h)  ; READ_BUTTONS_STATE_1
	.long CPanel_SM_RXByteN	;(         024h)  ; READ_BUTTONS_STATE_2
	.long CPanel_SM_Idle	;(         028h)  ; UNREACHABLE_STATE (?)


INTTX1_HANDLER:	; FC44B5
	push XWA
	push XHL
	push XIY
	ld L, (CPANEL_STATE_MACHINE_INDEX)
	xor H, H
	extz XHL
	add XHL, CPANEL_STATE_MACHINE_TABLE
	ld XHL, (XHL)
	jp XHL


MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES:	; FC44CA
	pop XIY
	pop XHL
	pop XWA
	ld (INTCLR), 0x12	; INTA Pin
	ld (INTCLR), 0x22	; INTRX1: Serial receive 1
	ld (INTCLR), 0x23	; INTTX1: Serial send 1
	reti


INTRX1_HANDLER:	; FC44D7
	push XWA
	push XHL
	push XIY
	ld L, (CPANEL_STATE_MACHINE_INDEX)
	xor H, H
	extz XHL
	add XHL, CPANEL_STATE_MACHINE_TABLE
	ld XHL, (XHL)
	jp XHL

LEAST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES:	; FC44EC
	pop XIY
	pop XHL
	pop XWA
	ld (INTCLR), 0x12	; INTA Pin
	ld (INTCLR), 0x22	; INTRX1: Serial receive 1
	ld (INTCLR), 0x23	; INTTX1: Serial send 1
	reti


CPanel_SM_StartTX:	; FC44F9	; Start transmitting command to set LEDs on the control panel... (?)
	and (PFCR_VALUE), 0xbf
	ld A, (PFCR_VALUE)
	ld (PFCR), A
	ld (BR1CR), 0x24	; Internal Clock T8 (64/fc)
	                 ; Divide by 4
	                 ; fc = 16MHz, so fc/64/4 = 62500
	ld (INTEAB), 0x7	; INTTRA(TREGA): M=7
	ld (INTES1), 0xd0	; INTTX1: M=5
	and (SC1CR), 0xfe
	ld (SC1BUF), A
	inc 4, (CPANEL_STATE_MACHINE_INDEX)	; next = ROUTINE_2
	MUL_A 0x1
	MUL_A 0x1
	bit 6, (PF)	; PF.6 = state of SCLK1 pin
	jr NZ, MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES


						; If we receive a SCLK1 LOW, does it mean CPANEL is trying to spreak and we revert to IDLE state (ROUTINE_0) ?
	ld (CPANEL_PACKET_BYTE_COUNT), 0x0
	ld (CPANEL_STATE_MACHINE_INDEX), 0x0	; ROUTINE_0
	or (CPANEL_PROTOCOL_FLAGS), 0x2	; CP_Flags_B.1 = 1  ; UNUSED
	ld (INTEAB), 0x5
	ld (INTES1), 0xff
	ld (BR1CR), 0x24	; Internal Clock T8 (64/fc)
	                 ; Divide by 4
	                 ; fc = 16MHz, so fc/64/4 = 62500
	and (CPANEL_TX_RX_FLAGS), 0xfd	; CP_Flags_A.1 = 0
	jrl MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES


CPanel_SM_TXDelay1:	; FC4544
	CALR DELAY_10_LOOPS
	and (PFCR_VALUE), 0xaf
	ld A, (PFCR_VALUE)
	ld (PFCR), A
	and (PFFC_VALUE), 0xaf	; disable CPanel serial clk and TX pin.
	ld A, (PFFC_VALUE)
	ld (PFFC), A
	ld (BR1CR), 0x24	; Internal Clock T8 (64/fc)
	                 ; Divide by 4
	                 ; fc = 16MHz, so fc/64/4 = 62500
	ld (INTES1), 0xd0	; INTTX1: M=5
	and (SC1CR), 0xfe
	ld (SC1BUF), A
	inc 4, (CPANEL_STATE_MACHINE_INDEX)	; next routine
	jrl MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES


CPanel_SM_TXDelay2:	; FC4573
	CALR DELAY_10_LOOPS
	and (PFCR_VALUE), 0xaf
	ld A, (PFCR_VALUE)
	ld (PFCR), A
	and (PFFC_VALUE), 0xaf	; disable CPanel serial clk and TX pin.
	ld A, (PFFC_VALUE)
	ld (PFFC), A
	ld (BR1CR), 0x24	; Internal Clock T8 (64/fc)
	                 ; Divide by 4
	                 ; fc = 16MHz, so fc/64/4 = 62500
	ld (SC1BUF), A
	ld (INTEAB), 0x5
	ld (INTES1), 0xd0	; INTTX1: M=5
	and (SC1CR), 0xfe
	ld (SC1BUF), A
	inc 4, (CPANEL_STATE_MACHINE_INDEX)	; next routine
	jrl MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES


CPanel_SM_SendByte1:	; FC45A8
	ld (BR1CR), 0x14	; Internal Clock T2 (16/fc)
	                 ; Divide by 4
	                 ; fc = 16MHz, so fc/16/4 = 250kHz
	or (PFFC_VALUE), 0x50	; Enable CPanel serial clk and TX pin.
	ld A, (PFFC_VALUE)
	ld (PFFC), A
	or (PFCR_VALUE), 0x50
	ld A, (PFCR_VALUE)
	ld (PFCR), A
	and (SC1CR), 0xfe
	ld (INTEAB), 0x5
	ld (INTES1), 0xd0	; INTTX1: M=5
	ld XIY, CPANEL_LED_TX_BUFFER
	add IY, (CPANEL_LED_READ_PTR)
	ld A, (XIY)
	ld (SC1BUF), A
	INCW 1, (CPANEL_LED_READ_PTR)
	cpw (CPANEL_LED_READ_PTR), 0x3c
	jr C, LABEL_FC45ED
	ldw (CPANEL_LED_READ_PTR), 0x0

LABEL_FC45ED:
	ld (CPANEL_PACKET_BYTE_COUNT), 0x2
	ld A, (XIY)
	and A, 0x3f
	cp A, 0x30
	jr C, LABEL_FC4606
	and A, 0xf
	add A, 0x3
	ld (CPANEL_PACKET_BYTE_COUNT), A

LABEL_FC4606:
	inc 4, (CPANEL_STATE_MACHINE_INDEX)	; next = ROUTINE_3
	jrl MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES


CPanel_SM_SendByteN:	; FC460D
	ld (BR1CR), 0x14	; Internal Clock T2 (16/fc)
	                 ; Divide by 4
	                 ; fc = 16MHz, so fc/16/4 = 250kHz
	or (PFFC_VALUE), 0x50	; Enable CPanel serial clk and TX pin.
	ld A, (PFFC_VALUE)
	ld (PFFC), A
	or (PFCR_VALUE), 0x50
	ld A, (PFCR_VALUE)
	ld (PFCR), A
	and (SC1CR), 0xfe
	ld (INTEAB), 0x5
	ld (INTES1), 0xd0	; INTTX1: M=5
	ld XIY, CPANEL_LED_TX_BUFFER
	add IY, (CPANEL_LED_READ_PTR)
	ld A, (XIY)
	ld (SC1BUF), A
	INCW 1, (CPANEL_LED_READ_PTR)
	cpw (CPANEL_LED_READ_PTR), 0x3c
	jr C, LABEL_FC4652
	ldw (CPANEL_LED_READ_PTR), 0x0

LABEL_FC4652:
	dec 1, (CPANEL_PACKET_BYTE_COUNT)
	cp (CPANEL_PACKET_BYTE_COUNT), 0x1
	jr Z, LABEL_FC466B
	cp (CPANEL_PACKET_BYTE_COUNT), 0x0
	jr Z, LABEL_FC466B
	dec 4, (CPANEL_STATE_MACHINE_INDEX)	; previous routine
	jrl MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES

LABEL_FC466B:
	inc 4, (CPANEL_STATE_MACHINE_INDEX)	; next routine
	jrl MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES


CPanel_SM_TXComplete:	; FC4672
	ld (CPANEL_PACKET_BYTE_COUNT), 0x0
	ld (CPANEL_STATE_MACHINE_INDEX), 0x0	; ROUTINE_0
	ld WA, (CPANEL_LED_WRITE_PTR)
	sub WA, (CPANEL_LED_READ_PTR)
	cp WA, 2
	jr C, LABEL_FC46C1
	ld (CPANEL_STATE_MACHINE_INDEX), 0x4	; ROUTINE_1
	and (PFFC_VALUE), 0xbf	; disable CPanel serial clk
	ld A, (PFFC_VALUE)
	ld (PFFC), A
	and (PF), 0xbf	; PF bit 6, (SCLK1 | /CTS1) = 0
	or (PFCR_VALUE), 0x40
	ld A, (PFCR_VALUE)
	ld (PFCR), A
	ld (BR1CR), 0x28	; Internal Clock T8 (64/fc)
	                 ; Divide by 8
	                 ; fc = 16MHz, so fc/64/8 = 31250
	ld (INTEAB), 0x7
	and (SC1CR), 0xfe
	ld (INTES1), 0xd0	; INTTX1: M=5
	ld (SC1BUF), A
	or (CPANEL_TX_RX_FLAGS), 0x2	; CP_Flags_A.1 = 1
	jrl MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES

LABEL_FC46C1:
	and (PFCR_VALUE), 0xbf
	ld A, (PFCR_VALUE)
	ld (PFCR), A
	and (PFFC_VALUE), 0xbf	; disable CPanel serial clk
	ld A, (PFFC_VALUE)
	ld (PFFC), A
	ld (INTEAB), 0x5
	ld (INTES1), 0xff	; INTTX1: M=7 | INTRX1: M=7 (meaning: disable int.req.)
	ld (BR1CR), 0x24	; Internal Clock T8 (64/fc)
	                 ; Divide by 4
	                 ; fc = 16MHz, so fc/64/4 = 62500
	and (CPANEL_TX_RX_FLAGS), 0xfd	; CP_Flags_A.1 = 0
	jrl MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES


CPanel_SM_RXByte1:	; FC46EA
	and (PFCR_VALUE), 0x9f
	ld A, (PFCR_VALUE)
	ld (PFCR), A
	or (SC1CR), 0x1
	and (SC1CR), 0xfd
	ld (INTEAB), 0x5
	ld (INTES1), 0xd
	ld A, (SC1BUF)
	ld XIY, CPANEL_RX_RING_BUFFER
	add IY, (CPANEL_RX_WRITE_PTR)
	ld (XIY), A
	ld HL, (CPANEL_RX_WRITE_PTR)
	sub HL, (CPANEL_RX_READ_PTR)
	jr NC, LABEL_FC4722
	neg HL
	ld IY, HL
	jr LABEL_FC4727

LABEL_FC4722:
	ld IY, 0x5c
	sub IY, HL

LABEL_FC4727:
	cp IY, 3
	jr NC, LABEL_FC4732
	or (CPANEL_PROTOCOL_FLAGS), 0x1	; CP_Flags_B.0 = 1
	jr LABEL_FC4749

LABEL_FC4732:
	and (CPANEL_PROTOCOL_FLAGS), 0xfe	; CP_Flags_B.0 = 0
	INCW 1, (CPANEL_RX_WRITE_PTR)
	cpw (CPANEL_RX_WRITE_PTR), 0x5c
	jr C, LABEL_FC4749
	ldw (CPANEL_RX_WRITE_PTR), 0x0

LABEL_FC4749:
	ld (CPANEL_PACKET_BYTE_COUNT), 0x2
	and A, 0x3f
	cp A, 0x30
	jr C, LABEL_FC4760
	and A, 0xf
	add A, 0x3
	ld (CPANEL_PACKET_BYTE_COUNT), A

LABEL_FC4760:
	inc 4, (CPANEL_STATE_MACHINE_INDEX)	; next routine
	jrl LEAST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES


CPanel_SM_RXByteN:	; FC4767
	ld A, (SC1BUF)
	ld XIY, CPANEL_RX_RING_BUFFER
	add IY, (CPANEL_RX_WRITE_PTR)
	ld (XIY), A
	bit 0, (CPANEL_PROTOCOL_FLAGS)	; CP_Flags_B.0
	jr NZ, LABEL_FC478D
	INCW 1, (CPANEL_RX_WRITE_PTR)
	cpw (CPANEL_RX_WRITE_PTR), 0x5c
	jr C, LABEL_FC478D
	ldw (CPANEL_RX_WRITE_PTR), 0x0

LABEL_FC478D:
	dec 1, (CPANEL_PACKET_BYTE_COUNT)
	cp (CPANEL_PACKET_BYTE_COUNT), 0x1
	jr NZ, LABEL_FC47CC
	ld (CPANEL_PACKET_BYTE_COUNT), 0x0
	and (CPANEL_TX_RX_FLAGS), 0xfe	; CP_Flags_A.0 = 0
	ld (CPANEL_STATE_MACHINE_INDEX), 0x0	; ROUTINE_0
	and (PFCR_VALUE), 0x9f
	ld A, (PFCR_VALUE)
	ld (PFCR), A
	and (PFFC_VALUE), 0xbf	; disable CPanel serial clk
	ld A, (PFFC_VALUE)
	ld (PFFC), A
	ld (INTEAB), 0x5
	ld (INTES1), 0xd
	and (SC1MOD), 0xdf	; RXE (bit 5) = 0: receive disable
	jrl LEAST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES

LABEL_FC47CC:
	and (PFCR_VALUE), 0x9f
	ld A, (PFCR_VALUE)
	ld (PFCR), A
	or (SC1CR), 0x1
	and (SC1CR), 0xfd
	ld (INTEAB), 0x5
	ld (INTES1), 0xd
	jrl LEAST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES


CPanel_SM_Idle:	; FC47E9		; CPANEL_SERIAL_IDLE_STATE (?)
	or (CPANEL_PROTOCOL_FLAGS), 0x80	; CP_Flags_B.7 = 1
	jrl LEAST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES

	and (CPANEL_TX_RX_FLAGS), 0xfc	; CP_Flags_A.0 = 0
						; CP_Flags_A.1 = 0
	or (CPANEL_PROTOCOL_FLAGS), 0x4	; CP_Flags_B.2 = 1  : UNUSED
	ld (INTCLR), 0x23	; INTTX1: Serial send 1
	and (SC1MOD), 0xdf	; RXE (bit 5) = 0: receive disable
	ld (INTES1), 0xf
	ld (INTCLR), 0x22	; INTRX1: Serial receive 1
	ld (INTEAB), 0x7
	ld (INTCLR), 0x12	; INTA Pin
	reti


CPanel_InterruptPoll_MainLoop:
	inc 1, (CPANEL_COUNTER_UP_TO_42)
	cp (CPANEL_COUNTER_UP_TO_42), 0x2a	; =42 ;-)
	jr ULE, LABEL_FC485B
	ei 0x6
	ld WA, (CPANEL_LED_WRITE_PTR)
	sub WA, (CPANEL_LED_READ_PTR)
	jr NC, LABEL_FC482C
	neg WA
	ld HL, WA
	jr LABEL_FC4831

LABEL_FC482C:
	ld HL, 0x3c
	sub HL, WA

LABEL_FC4831:
	cp HL, 3
	jr C, LABEL_FC485B
	ld (CPANEL_COUNTER_UP_TO_42), 0x0
	LD_W 0xe0
	LD_A 0x13
	ld IY, (CPANEL_LED_WRITE_PTR)
	ld XDE, CPANEL_LED_TX_BUFFER
	ld (XDE + IY), W
	CALR CPanel_IncLEDPtr
	ld (XDE + IY), A
	CALR CPanel_IncLEDPtr
	ld (CPANEL_LED_WRITE_PTR), IY


; 0 => 0 do_this
; 1 => 2 do_this
; 2 => 3 do_this
; 3 => 0 do_that

LABEL_FC485B:
	ei 0x0
	ld A, (CPANEL_TX_RX_FLAGS)
	and A, 0xc0
	cp A, 0	; if (CP_Flags_A.76 == 0) {
	jr Z, LABEL_FC4877	; 	goto LABEL_FC4877; ; do this
						; }


	add (CPANEL_TX_RX_FLAGS), 0x40
	cp A, 0xc0
	jr NZ, LABEL_FC4877	; if (CP_Flags_A.76++ == 3) {

	CALR CPanel_InitButtonState	; do that

	jr LABEL_FC487A
				; } else {

LABEL_FC4877:
	CALR CPanel_UpdateLEDs	; do this
				; }
LABEL_FC487A:
	ei 0x6
	bit 6, (PF)	; PF.6 = state of SCLK1 pin
	jr Z, LABEL_FC48EB
	bit 5, (PE)	; PE.5 = state of INTA pin
	jr NZ, LABEL_FC48EB
	bit 1, (CPANEL_TX_RX_FLAGS)
	jr NZ, LABEL_FC48EB
	bit 0, (CPANEL_TX_RX_FLAGS)
	jr NZ, LABEL_FC48EB

	; Only reaches here when (CPANEL_TX_RX_FLAGS), CP_Flags_A.10 == 00:
	ld WA, (CPANEL_LED_WRITE_PTR)
	sub WA, (CPANEL_LED_READ_PTR)
	jr NC, LABEL_FC48A4
	neg WA
	ex A, W
	LD_A 0x3c
	sub A, W

LABEL_FC48A4:
	cp A, 2
	jr C, LABEL_FC48E8
	or (CPANEL_TX_RX_FLAGS), 0x2	; CP_Flags_A.1 = 1
	ld (CPANEL_STATE_MACHINE_INDEX), 0x4	; ROUTINE_1
	and (PFFC_VALUE), 0xbf	; disable CPanel serial clk
	ld A, (PFFC_VALUE)
	ld (PFFC), A
	and (PF), 0xbf	; PF bit 6, (SCLK1 | /CTS1) = 0
	or (PFCR_VALUE), 0x40
	ld A, (PFCR_VALUE)
	ld (PFCR), A
	ld (BR1CR), 0x28	; Internal Clock T8 (64/fc)
	                 ; Divide by 8
	                 ; fc = 16MHz, so fc/64/8 = 31250
	and (SC1MOD), 0xdf	; RXE (bit 5) = 0: CPanel receive disable
	and (SC1CR), 0xfe
	ld (INTEAB), 0x7
	ld (INTCLR), 0x12	; INTA Pin
	ld (INTCLR), 0x23	; INTTX1: Serial send 1
	ld (INTES1), 0xd0
	ld (SC1BUF), A

LABEL_FC48E8:
	ei 0x0
	ret


LABEL_FC48EB:
	inc 1, (CPANEL_COUNTER_UP_TO_20)
	cp (CPANEL_COUNTER_UP_TO_20), 0x14
	jr ULE, LABEL_FC48E8

	ei 0x6
	ld (INTCLR), 0x22	; INTRX1: Serial receive 1
	ld (INTCLR), 0x23	; INTTX1: Serial send 1
	ld (INTES1), 0xdd
	ld (INTCLR), 0x12	; INTA Pin
	ld (INTEAB), 0x5
	or (CPANEL_PROTOCOL_FLAGS), 0x80	; CP_Flags_B.7 = 1
	jr LABEL_FC48E8




CPanel_RX_ProcessWithFlag:
	or (CPANEL_TX_RX_FLAGS), 0x4	; CP_Flags_A.2 = 1  ; UNUSED?
	jr CPanel_RX_DispatchLoop

CPanel_RX_Process:
	and (CPANEL_TX_RX_FLAGS), 0xfb	; CP_Flags_A.2 = 0  ; UNUSED?

CPanel_RX_DispatchLoop:
	ld XDE, CPANEL_RX_RING_BUFFER
	ld IY, (CPANEL_RX_READ_PTR)
	ld XIZ, CPANEL_RX_EVENT_QUEUE
	ld IX, (XIZ - 4)

CPanel_RX_ParseNext:
	cpw (XIZ - 2), 0x4
	jrl C, CPanel_RX_Done

	ld WA, (CPANEL_RX_WRITE_PTR)
	sub WA, (CPANEL_RX_READ_PTR)
	jr NC, CPanel_RX_PacketSizeCheck
	neg WA
	ex A, W
	LD_A 0x5c
	sub A, W

CPanel_RX_PacketSizeCheck:
	cp A, 2
	jrl C, CPanel_RX_Done

	ld L, (XDE + IY)
	and L, 0x38
	srl L, 1
	xor H, H
	extz XHL
	add XHL, CPanel_RX_PacketHandlers
	ld XHL, (XHL)
	jp XHL

CPanel_RX_PacketHandlers_Padding:
	.byte 0xFF, 0xFF

CPanel_RX_PacketHandlers:
	.long CPanel_RX_ButtonPacket
	.long CPanel_RX_ButtonPacket
	.long CPanel_RX_EncoderPacket
	.long CPanel_RX_SyncPacket
	.long CPanel_RX_SyncPacket
	.long CPanel_RX_SyncPacket
	.long CPanel_RX_MultiBytePacket
	.long CPanel_RX_MultiBytePacket

CPanel_RX_ButtonPacket:
	ld W, (XDE + IY)
	CALR CPanel_IncRXPtr
	ld (XIZ + IX), W
	CALR CPanel_IncEventPtr
	ld (CPANEL_RX_PACKET_BYTE_1), W

	ld A, (XDE + IY)
	CALR CPanel_IncRXPtr
	ld (XIZ + IX), A
	CALR CPanel_IncEventPtr
	ld (CPANEL_RX_PACKET_BYTE_2), A

	and W, 0x4f
	ld XHL, STATE_OF_CPANEL_BUTTONS
	bit 0x6, W
	jr Z, LABEL_FC49BD
	sub W, 0x30

LABEL_FC49BD:
	add L, W
	jr NC, LABEL_FC49C3
	inc 1, H

LABEL_FC49C3:
	ex (XHL), A
	xor A, (XHL)

	ld (XIZ + IX), A
	CALR CPanel_IncEventPtr

	ld (CPANEL_LAST_EVENT_VALUE), A
	ld (XIZ - 4), IX
	DECW 3, (XIZ - 2)
	ld (CPANEL_RX_READ_PTR), IY
	jrl CPanel_RX_ParseNext

CPanel_RX_EncoderPacket:
	ld W, (XDE + IY)
	CALR CPanel_IncRXPtr
	ld (XIZ + IX), W
	CALR CPanel_IncEventPtr
	ld (CPANEL_RX_PACKET_BYTE_1), W
	ld A, (XDE + IY)
	CALR CPanel_IncRXPtr
	ld (CPANEL_RX_PACKET_BYTE_2), A
	ld C, W
	CALR LABEL_FC4A36
	cp HL, 0xffff
	jr NZ, LABEL_FC4A14
	CALR CPanel_DecEventPtr
	ld (CPANEL_RX_READ_PTR), IY
	jr LABEL_FC4A33

LABEL_FC4A14:
	ld (XIZ + IX), L
	CALR CPanel_IncEventPtr
	ld (CPANEL_LAST_EVENT_VALUE), L
	ld (XIZ + IX), 0xff
	CALR CPanel_IncEventPtr
	ld (XIZ - 4), IX
	DECW 3, (XIZ - 2)
	ld (CPANEL_RX_READ_PTR), IY

LABEL_FC4A33:
	jrl CPanel_RX_ParseNext

LABEL_FC4A36:
	push XDE
	push XIZ
	push XIX
	CALR CPanel_EncoderDispatch
	pop XIX
	pop XIZ
	pop XDE
	ret

CPanel_RX_MultiBytePacket:
	ld W, A
	ld A, (XDE + IY)
	ld C, A
	and A, 0xf
	inc 1, A
	ld B, A
	add A, 0x2
	cp W, A
	jrl C, CPanel_RX_Done

	CALR CPanel_IncRXPtr
	ld A, (XDE + IY)
	CALR CPanel_IncRXPtr
	and A, 0x1f
	and C, 0xc0
	or C, A
	ld W, C
	bit 0x4, W
	jr NZ, LABEL_FC4A8B
	and C, 0x40
	bit 0x6, C
	jr Z, LABEL_FC4A7D
	sub C, 0x30

LABEL_FC4A7D:
	or A, C
	ld L, A
	extz HL
	extz XHL
	add XHL, STATE_OF_CPANEL_BUTTONS

LABEL_FC4A8B:
	ld (XIZ + IX), W
	CALR CPanel_IncEventPtr
	ld A, (XDE + IY)
	CALR CPanel_IncRXPtr
	bit 0x4, W
	jr Z, LABEL_FC4AC5
	push BC
	ld C, W
	push HL
	push WA
	CALR LABEL_FC4A36
	pop WA
	cp HL, 0xffff
	ld (CPANEL_LAST_EVENT_VALUE), L
	pop HL
	pop BC
	jr NZ, LABEL_FC4AC1
	jr LABEL_FC4AB7

LABEL_FC4AB7:
	CALR CPanel_DecEventPtr
	ld (CPANEL_RX_READ_PTR), IY
	jrl LABEL_FC4B04

LABEL_FC4AC1:
	ld A, (CPANEL_LAST_EVENT_VALUE)

c:
	ld (XIZ + IX), A
	CALR CPanel_IncEventPtr
	bit 0x4, W
	jr NZ, LABEL_FC4AEA
	ex (XHL), A
	xor A, (XHL)
	inc 1, HL
	bit 4, (CPANEL_TX_RX_FLAGS)	; This is never set ?!
	jr Z, LABEL_FC4AEC
	cp A, 0
	jr NZ, LABEL_FC4AEC
					; if CP_Flags_A.4 != 0 && A == 0:
	CALR CPanel_DecEventPtr
	CALR CPanel_DecEventPtr
	jr LABEL_FC4B00

LABEL_FC4AEA:
	LD_A 0xff

					; else:
LABEL_FC4AEC:
	ld (XIZ + IX), A
	CALR CPanel_IncEventPtr
	ld (XIZ - 4), IX
	DECW 1, (XIZ - 2)
	DECW 1, (XIZ - 2)
	DECW 1, (XIZ - 2)

LABEL_FC4B00:
	ld (CPANEL_RX_READ_PTR), IY

LABEL_FC4B04:
	inc 1, W
	dec 1, B
	cp B, 0
	jrl NZ, LABEL_FC4A8B
	jrl CPanel_RX_ParseNext

CPanel_RX_SyncPacket:
	ld A, (XDE + IY)
	CALR CPanel_IncRXPtr
	ld A, (XDE + IY)
	CALR CPanel_IncRXPtr
	ld (CPANEL_RX_READ_PTR), IY
	or (CPANEL_PROTOCOL_FLAGS), 0x8	; CP_Flags_B.3 = 1  ; UNUSED
	jrl CPanel_RX_ParseNext

	CPanel_RX_Done	; FC4B2C
	ret


CPanel_UpdateLEDs:	; do this
	ld IY, (CPANEL_LED_WRITE_PTR)
	ld XDE, CPANEL_LED_TX_BUFFER
	ld XIZ, CPANEL_LED_EVENT_QUEUE
	ld IX, (XIZ - 8)
	ld WA, (XIZ - 4)
	cp WA, (XIZ - 8)
	jr NZ, LABEL_FC4B4E
	cpw (XIZ - 2), 0x0
	jrl NZ, LABEL_FC4C07

LABEL_FC4B4E:
	ld WA, (CPANEL_LED_WRITE_PTR)
	sub WA, (CPANEL_LED_READ_PTR)
	jr NC, LABEL_FC4B5E
	neg WA
	ld HL, WA
	jr LABEL_FC4B63

LABEL_FC4B5E:
	ld HL, 0x3c
	sub HL, WA

LABEL_FC4B63:
	cp HL, 3
	jrl C, LABEL_FC4C07
	ld A, (XIZ + IX)
	and A, 0x30
	srl A, 2
	ld L, A
	xor H, H
	extz XHL
	add XHL, CPanel_LED_PacketHandlers
	ld XHL, (XHL)
	jp XHL

CPanel_LED_PacketHandlers_Padding:
	.byte 0xFF, 0xFF


CPanel_LED_PacketHandlers:
	.long LABEL_FC4B95
	.long LABEL_FC4B95
	.long LABEL_FC4B95
	.long LABEL_FC4BC5


LABEL_FC4B95:
	.byte 0xC3, 0x7, 0xF8, 0xF0, 0x21, 0x1E, 0x97, 0x0
	.byte 0xF3, 0x7, 0xE8, 0xF4, 0x41, 0x1E
	.byte 0x6E, 0x0, 0xC3, 0x7, 0xF8, 0xF0, 0x20, 0x1E
	.byte 0x87, 0x0, 0xF3, 0x7, 0xE8, 0xF4, 0x40, 0x1E
	.byte 0x5E, 0x0, 0xBE, 0xF8, 0x54, 0x9E, 0xFE, 0x61
	.byte 0x9E, 0xFE, 0x61, 0xF1, 0xFF, 0x8D, 0x55, 0x78
	.byte 0x79, 0xFF

LABEL_FC4BC5:
	.byte 0xC3, 0x7, 0xF8, 0xF0, 0x21, 0x1E
	.byte 0x67, 0x0, 0xC9, 0x8B, 0xC9, 0xCC, 0xF, 0xC9
	.byte 0xC8, 0x2, 0xC9, 0x8A, 0xCB, 0x89, 0xF3, 0x7
	.byte 0xE8, 0xF4, 0x41, 0x1E, 0x32, 0x0, 0x9E, 0xFE
	.byte 0x61, 0xC3, 0x7, 0xF8, 0xF0, 0x21, 0x1E, 0x48
	.byte 0x0, 0xF3, 0x7, 0xE8, 0xF4, 0x41, 0x1E, 0x1F
	.byte 0x0, 0xBE, 0xF8, 0x54, 0x9E, 0xFE, 0x61, 0xF1
	.byte 0xFF, 0x8D, 0x55, 0xCA, 0x69, 0xCA, 0xD8, 0x6E
	.byte 0xE0, 0x78, 0x37, 0xFF

LABEL_FC4C07:
	ret


CPanel_IncRXPtr:	; FC4C08
	inc 1, IY
	cp IY, 0x5c
	jr C, LABEL_FC4C12
	ld IY, 0

LABEL_FC4C12:
	ret


CPanel_IncLEDPtr:	; FC4C13
	inc 1, IY
	cp IY, 0x3c
	jr C, LABEL_FC4C1D
	ld IY, 0

LABEL_FC4C1D:
	ret


CPanel_IncEventPtr:	; FC4C1E
	inc 1, IX
	cp IX, 0x80
	jr C, LABEL_FC4C28
	ld IX, 0

LABEL_FC4C28:
	ret


CPanel_DecEventPtr:	; FC4C29
	cp IX, 0
	jr NZ, LABEL_FC4C31
	ld IX, 0x7f
	ret

LABEL_FC4C31:
	dec 1, IX
	ret

; End of control panel routines
