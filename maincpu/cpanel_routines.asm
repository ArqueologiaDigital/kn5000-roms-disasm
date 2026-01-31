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

CPanel_ScanButtons:		; FC3EE5
	PUSH XIX
	PUSH XIZ
	PUSH XHL
	PUSH XDE
	CALL CPanel_ReadAllButtons
	POP XDE
	POP XHL
	POP XIZ
	POP XIX
	CALR CPanel_CheckSpecialCombos
	RET


CPanel_InitHardware:
	LD XHL, CPANEL_RX_EVENT_QUEUE
	LDW (XHL - 4), 0000h
	LDW (XHL - 8), 0000h
	LDW (XHL - 2), 0080h

	LD XHL, CPANEL_LED_EVENT_QUEUE
	LDW (XHL - 4), 0000h
	LDW (XHL - 8), 0000h
	LDW (XHL - 2), 0080h

	LD_A 003h ; PF2=SCK0 Disabled, PF0=TxD0 and PF1=RXD0 (MIDI)
	AND A, 0afh ; PF6=SCK1 Disabled, PF4=TxD1 and PF5=RXD1 (Control Panel)
	LD (PFFC_VALUE), A
	LD (PFFC), A
	LD_A 015h
	AND A, 08fh
	LD (PFCR_VALUE), A
	LD (PFCR), A
	AND (PF), 0bfh ; PF bit 6, (SCLK1 | /CTS1) = 0
	LD_A 000h
	LD (PEFC), A
	LD_A 046h
	LD (PECR), A
	LD (SC1MOD), 000h ; serial clk: TO2 trigger
	                  ; serial transfer mode: I/O  transfer mode
	                  ; wake-up function: disable
	                  ; receive control: receive disable
	                  ; handshake function control: CTS disable
	LD (BR1CR), 014h ; Internal Clock T2 (16/fc)
	                 ; Divide by 4
	                 ; fc = 16MHz, so fc/16/4 = 250kHz
	LD (SC1CR), 001h ; Parity: odd
	                 ; Parity addition: disable
	                 ; clear all errors
	                 ; Data transmit/receive at SCLK1 rising edge
	                 ; I/O interface input clock: SCLK1 pin input
	LD (INTEAB), 007h
	LD (INTCLR), 012h ; INTA Pin
	LD (INTES1), 0ffh
	LD (INTCLR), 022h ; INTRX1: Serial receive 1
	LD (INTCLR), 023h ; INTTX1: Serial send 1
	OR (TAMOD), 010h
	AND (TAMOD), 0f7h
	LD (CPANEL_UNUSED_1), 07dh  ; This looks pointless...

	OR (CPANEL_TX_RX_FLAGS), 040h ; CP_Flags_A.6 = 1
	LD (CPANEL_PACKET_BYTE_COUNT), 000h
	AND (CPANEL_TX_RX_FLAGS), 0fch ; CP_Flags_A.10 = 00
	LDW (CPANEL_LED_READ_PTR), 0000h
	LDW (CPANEL_LED_WRITE_PTR), 0000h
	LDW (CPANEL_RX_READ_PTR), 0000h
	LDW (CPANEL_RX_WRITE_PTR), 0000h

	CALR DELAY_6_TICKS

	LD_A 01fh
	LD_W 0dah
	CALR CPanel_SendCommand
	CALR DELAY_3000_LOOPS

	LDW (CPANEL_LED_READ_PTR), 0000h
	CALR DELAY_3000_LOOPS

	CALR CPanel_SendInitSequence
	RET


; CPanel_SendInitSequence - Send initialization command sequence to control panel MCUs
; Commands sent: 0x1F 0x1A, 0x1D 0x00, 0xDD 0x03, 0x1E 0x80
CPanel_SendInitSequence:
	LD_A 01fh
	LD_W 01ah
	CALR CPanel_SendCommand
	CALR DELAY_3000_LOOPS

	LDW (CPANEL_LED_READ_PTR), 0000h
	CALR DELAY_3000_LOOPS

	LD_A 01dh
	LD_W 0
	CALR CPanel_SendCommand
	CALR DELAY_3000_LOOPS

	LDW (CPANEL_LED_READ_PTR), 0000h
	CALR DELAY_3000_LOOPS
	CALR DELAY_3000_LOOPS

	LD_A 0ddh
	LD_W 03h
	CALR CPanel_SendCommand
	CALR DELAY_3000_LOOPS

	LDW (CPANEL_LED_READ_PTR), 0000h
	CALR DELAY_3000_LOOPS
	CALR DELAY_3000_LOOPS

	LD_A 01eh
	LD_W 080h
	CALR CPanel_SendCommand
	CALR DELAY_3000_LOOPS
	CALR DELAY_3000_LOOPS
	CALR DELAY_3000_LOOPS

	EI 006h
	LD (INTES1), 0ffh
	LD (INTCLR), 022h ; INTRX1: Serial receive 1
	LD (INTCLR), 023h ; INTTX1: Serial send 1
	AND (SC1MOD), 0dfh  ; RXE (bit 5) = 0: receive disable
	LD (INTCLR), 012h ; INTA Pin
	LD (INTEAB), 005h
	LDW (CPANEL_RX_READ_PTR), 0000h
	LDW (CPANEL_RX_WRITE_PTR), 0000h
	OR (CPANEL_PROTOCOL_FLAGS), 001h		; CP_Flags_B.0 = 1
	EI 000h
	RET


CPanel_InitLEDBuffer:
	LD (CPANEL_LED_TX_BUFFER), WA
	AND (PFFC_VALUE), 0bfh
	LD A,(PFFC_VALUE)
	LD (PFFC), A
	LD (0ebh), 0ffh
	LD (0f8h), 022h
	LD (0f8h), 023h
	LD (0e3h), 007h
	LD (0f8h), 012h
	AND (03ch), 0bfh
	OR (PFCR_VALUE), 040h
	LD A,(PFCR_VALUE)
	LD (PFCR), A
	CALR DELAY_300_LOOPS
	CALR DELAY_300_LOOPS
	AND (PFCR_VALUE), 0bfh
	LD A,(PFCR_VALUE)
	LD (PFCR), A
	CALR DELAY_300_LOOPS
	CALR DELAY_300_LOOPS
	OR (PFFC_VALUE), 050h
	LD A, (PFFC_VALUE)
	LD (PFFC), A
	OR (PFCR_VALUE), 050h
	LD A, (PFCR_VALUE)
	LD (PFCR), A
	AND (SC1CR), 0feh
	LD (0ebh), 0ffh
	LD (0f8h), 022h
	LD (0f8h), 023h
	LD XIY, CPANEL_LED_TX_BUFFER
	ADD IY, (CPANEL_LED_READ_PTR)
	LD A, (XIY)
	INCW 1, (CPANEL_LED_READ_PTR)
	LD (SC1BUF), A
	CALR DELAY_300_LOOPS
	CALR DELAY_300_LOOPS
	LD XIY, CPANEL_LED_TX_BUFFER
	ADD IY, (CPANEL_LED_READ_PTR)
	LD A, (XIY)
	INCW 1, (CPANEL_LED_READ_PTR)
	LD (SC1BUF), A
	CALR DELAY_300_LOOPS
	CALR DELAY_300_LOOPS
	OR (SC1CR), 001h
	AND (SC1CR), 0fdh
	AND (PFCR_VALUE), 0afh
	LD A, (PFCR_VALUE)
	LD (PFCR), A
	AND (PFFC_VALUE), 0afh
	LD A, (PFFC_VALUE)
	LD (PFFC), A
	RET



; Below are routines that loop N times, where
; N = 2, 6, 10, 300, 1500 or 3000
; These are likely pauses
; But these values are also suspiciously similar to proportions
; between typical baudrates, but this is just a hunch for now...

LABEL_FC0DE:
	LD WA, 2

LABEL_FC40E0:
	DEC 1, WA
	CP WA, 0
	JR Z, LABEL_FC40E8
	JR T, LABEL_FC40E0

LABEL_FC40E8:
	ret


Delay_6_Loops:
	LD WA, 6

LABEL_FC40EB:
	DEC 1, WA
	CP WA, 0
	JR Z, LABEL_FC40F3
	JR T, LABEL_FC40EB

LABEL_FC40F3:
	RET


DELAY_10_LOOPS:			; FC40F4
	LD WA, 000ah

LABEL_FC40F7:
	DEC 1, WA
	CP WA, 0
	JR Z, LABEL_FC40FF
	JR T, LABEL_FC40F7

LABEL_FC40FF:
	RET


DELAY_300_LOOPS:		; FC4100
	LD WA, 012ch

LABEL_FC4103:
	DEC 1, WA
	CP WA, 0
	JR Z, LABEL_FC410B
	JR T, LABEL_FC4103

LABEL_FC410B:
	RET


DELAY_1500_LOOPS:		; FC410C
	LD WA, 05dch

LABEL_FC410F:
	DEC 1, WA
	CP WA, 0
	JR Z, LABEL_FC4117
	JR T, LABEL_FC410F

LABEL_FC4117:
	RET


DELAY_3000_LOOPS:		; FC4118
	LD WA, 0bb8h

LABEL_FC411B:
	DEC 1, WA
	CP WA, 0
	JR Z, LABEL_FC4123
	JR T, LABEL_FC411B

LABEL_FC4123:
	RET


LABEL_FC4124:
	db 0D1h, 009h, 004h, 020h, 0F1h, 09Bh, 08Dh, 050h
	db 0D1h, 009h, 004h, 020h, 0D1h, 09Bh, 08Dh, 0A0h
	db 0D8h, 0DAh, 061h, 0F4h, 00Eh


DELAY_6_TICKS:
	LD WA, (SYSTEM_TIMESTAMP)
	LD (TIMESTAMP_FOR_DELAY), WA

LABEL_FC4141:
	LD WA, (SYSTEM_TIMESTAMP)
	SUB WA, (TIMESTAMP_FOR_DELAY)
	CP WA, 6
	JR LT, LABEL_FC4141
	RET


DELAY_51_TICKS:
	LD WA, (SYSTEM_TIMESTAMP)
	LD (TIMESTAMP_FOR_DELAY), WA

LABEL_FC4156:
	LD WA, (SYSTEM_TIMESTAMP)
	SUB WA, (TIMESTAMP_FOR_DELAY)
	CP WA, 0033h
	JR LT, LABEL_FC4156
	RET

; ???? R        L
; ???? 25 (001 00101): 01 | e2 (111 00010): 04
; ???? 20 (001 00000): 10 | e2 (111 00010): 11

CPanel_CheckSpecialCombos:
	CP (STATE_OF_CPANEL_BUTTONS_LEFT + 4), 06ch   ;  CPL_SEG4 = 0110 1100 = AUTO PLAY CHORD + SPLIT POINT + VARIATION 4 + VARIATION 3 => display sw internal build numbers
	JR NZ, CPanel_SpecialCombo_FirmwareVersion
	LD HL, 3  ; SOFT VERSION SCREEN
	JR T, LABEL_FC4193

CPanel_SpecialCombo_FirmwareVersion:
	CP (STATE_OF_CPANEL_BUTTONS_RIGHT + 1), 070h   ; CPR_SEG1 = 0111 0000 = GM SPECIAL + ACCORDION REGISTER + DIGITAL DRAWBAR => display fw version on screen & LEDs
	JR NZ, CPanel_SpecialCombo_SoftVersion
	LD HL, 2
	JR T, LABEL_FC4193

CPanel_SpecialCombo_SoftVersion:
	CP (STATE_OF_CPANEL_BUTTONS_LEFT + 6), 038h   ; CPL_SEG6 = 0011 1000 = SHOWTIME & TRAD DANCE + PARTY TIME + MARCH & WALTZ => ?
	JR NZ, CPanel_SpecialCombo_BuildInfo
	LD HL, 1
	JR T, LABEL_FC4193

CPanel_SpecialCombo_BuildInfo:
	CP (STATE_OF_CPANEL_BUTTONS_RIGHT + 6), 00fh   ; CPR_SEG6 = 0000 1111 = 4 panel memory buttons (PM 4 + PM 3 + PM 2 + PM 1) => fw update
	JR NZ, CPanel_SpecialCombo_FirmwareUpdate
	LD HL, 4
	JR T, LABEL_FC4193

CPanel_SpecialCombo_FirmwareUpdate:
	LD HL, 0

LABEL_FC4193:
	RET


CPanel_PanelDetection:
	LD (CPANEL_PANEL_DETECT_FLAGS), 000h
	CALR CPanel_WaitTXReady
	EI 006h
	LDW (CPANEL_RX_READ_PTR), 0000h
	LDW (CPANEL_RX_WRITE_PTR), 0000h
	OR (CPANEL_PROTOCOL_FLAGS), 001h		; CP_Flags_B.0 = 1
	EI 000h
	LD_A 020h	; my guess: 20 = 001 00000 where 001 = left-panel mcu
	LD_W 0
	CALR CPanel_SendCommand
	CALR DELAY_6_TICKS
	CPW (CPANEL_RX_WRITE_PTR), 0000h
	JR Z, LABEL_FC41C8
	OR (CPANEL_PANEL_DETECT_FLAGS), 001h  ; my guess: CP_Flags_C.0
					  ; = Got response from left-panel MCU 

LABEL_FC41C8:
	CALR CPanel_WaitTXReady
	EI 006h
	LDW (CPANEL_RX_READ_PTR), 0000h
	LDW (CPANEL_RX_WRITE_PTR), 0000h
	OR (CPANEL_PROTOCOL_FLAGS), 001h		; CP_Flags_B.0 = 1
	EI 000h
	LD_A 0e0h	; my guess: E0 = 111 00000 where 111 = right-panel mcu
	LD_W 0
	CALR CPanel_SendCommand
	CALR DELAY_6_TICKS
	CPW (CPANEL_RX_WRITE_PTR), 0000h
	JR Z, LABEL_FC41F7
	OR (CPANEL_PANEL_DETECT_FLAGS), 008h ; my guess: CP_Flags_C.4
					 ; = Got response from right-panel MCU

LABEL_FC41F7:
	LD A, (CPANEL_PANEL_DETECT_FLAGS)
	RET


CPanel_ReadAllButtons:
	LD XHL, CPANEL_RX_EVENT_QUEUE
	LDW (XHL - 4), 0000h
	LDW (XHL - 8), 0000h
	LDW (XHL - 2), 0080h

	EI 006h
	LD WA, (CPANEL_RX_READ_PTR)
	LD (CPANEL_RX_WRITE_PTR), WA
	OR (CPANEL_PROTOCOL_FLAGS), 001h		; CP_Flags_B.0 = 1
	EI 000h

	CALL CPanel_WaitTXReady
	LD_A 025h
	LD_W 01h
	CALL CPanel_SendCommand
	CALR DELAY_6_TICKS
	CALR DELAY_6_TICKS
	CALR DELAY_6_TICKS

	CALR CPanel_WaitTXReady
	LD_A 0e2h
	LD_W 04h
	CALR CPanel_SendCommand
	CALR DELAY_6_TICKS
	CALR DELAY_6_TICKS

	CALR CPanel_WaitTXReady
	LD_A 020h
	LD_W 010h
	CALR CPanel_SendCommand
	CALR DELAY_6_TICKS
	CALR DELAY_6_TICKS

	CALR CPanel_WaitTXReady
	LD_A 0e2h
	LD_W 011h
	CALR CPanel_SendCommand
	CALR DELAY_6_TICKS
	CALR DELAY_6_TICKS

	CALR CPanel_RX_Process
	RET


CPanel_PollStartup:
	LD XHL, CPANEL_RX_EVENT_QUEUE
	LDW (XHL - 4), 0000h
	LDW (XHL - 8), 0000h
	LDW (XHL - 2), 0080h
	EI 006h
	LDW (CPANEL_RX_READ_PTR), 0000h
	LDW (CPANEL_RX_WRITE_PTR), 0000h
	OR (CPANEL_PROTOCOL_FLAGS), 001h		; CP_Flags_B.0 = 1
	EI 000h

CPanel_ButtonPollLoop:
	CALR CPanel_WaitTXReady
	LD_A 020h
	LD_W 0bh
	CALR CPanel_SendCommand
	CALR DELAY_6_TICKS
	CALR CPanel_RX_Process

	LD A, (STATE_OF_CPANEL_BUTTONS + 11)  ; Byte 11 is in gap between CPR (0-10) and CPL (16-26), possibly status/mode
	LD_W 0dh                               ; Default encoder check mode
	BIT 7, A                               ; Test bit 7 of status byte
	JR NZ, CPanel_EncoderCheck
	LD_W 0eh                               ; Alternate mode if bit 7 set
	BIT 6, A                               ; Test bit 6 of status byte
	JR NZ, CPanel_EncoderCheck
	LD_W 0ch                               ; Third mode if bit 6 set

CPanel_EncoderCheck:
	CP (8E6Ah), W
	LD (8E6Ah), W
	JR NZ, CPanel_ButtonPollLoop
	LD (8E6Ah), W
	LD XHL, CPANEL_RX_EVENT_QUEUE
	LDW (XHL - 4), 0000h
	LDW (XHL - 8), 0000h
	LDW (XHL - 2), 0080h
	EI 006h
	LDW (CPANEL_LED_READ_PTR), 0000h
	LDW (CPANEL_LED_WRITE_PTR), 0000h
	LDW (CPANEL_RX_READ_PTR), 0000h
	LDW (CPANEL_RX_WRITE_PTR), 0000h
	OR (CPANEL_PROTOCOL_FLAGS), 001h		; CP_Flags_B.0 = 1
	EI 000h
	RET


CPanel_InitButtonState: ; do that
	LD XHL, CPANEL_RX_EVENT_QUEUE
	LDW (XHL - 4), 0000h
	LDW (XHL - 8), 0000h
	LDW (XHL - 2), 0080h

	EI 006h
	LD (CPANEL_RX_READ_PTR), 000h
	LD (CPANEL_RX_WRITE_PTR), 000h
	OR (CPANEL_PROTOCOL_FLAGS), 001h		; CP_Flags_B.0 = 1
	EI 000h

	CALR CPanel_WaitTXReady
	LD_A 02bh
	LD_W 0
	CALR CPanel_SendCommand
	CALR DELAY_6_TICKS
	CALR DELAY_6_TICKS
	CALR DELAY_6_TICKS
	CALR CPanel_RX_ProcessWithFlag

	CALR CPanel_WaitTXReady
	LD_A 0ebh
	LD_W 0
	CALR CPanel_SendCommand
	CALR DELAY_6_TICKS
	CALR DELAY_6_TICKS
	CALR DELAY_6_TICKS
	CALR CPanel_RX_ProcessWithFlag

	CALR CPanel_WaitTXReady
	LD_A 020h
	LD_W 010h
	CALR CPanel_SendCommand
	CALR DELAY_6_TICKS
	CALR DELAY_6_TICKS
	CALR CPanel_RX_ProcessWithFlag

	CALR CPanel_WaitTXReady
	LD_A 0e3h
	LD_W 010h
	CALR CPanel_SendCommand
	CALR DELAY_6_TICKS
	CALR DELAY_6_TICKS
	CALR CPanel_RX_ProcessWithFlag
	RET


CPanel_WaitTXReady:
	LD (CPANEL_COUNTER_DOWN_FROM_200), 0c8h ; =200

CPanel_WaitTXReady_Poll:
	EI 006h
	BIT 6, (PF)		; PF.6 = state of SCLK1 pin == 1, (resting at pull-up)
	JR Z, CPanel_WaitTXReady_Timeout
	BIT 5, (PE)		; PE.5 = state of INTA pin == 0
	JR NZ, CPanel_WaitTXReady_Timeout
	BIT 1, (CPANEL_TX_RX_FLAGS)
	JR NZ, CPanel_WaitTXReady_Timeout
	BIT 0, (CPANEL_TX_RX_FLAGS)
	JR NZ, CPanel_WaitTXReady_Timeout
	JR T, CPanel_WaitTXReady_BufferCheck

CPanel_WaitTXReady_Timeout:
	DEC 1, (CPANEL_COUNTER_DOWN_FROM_200)
	CP (CPANEL_COUNTER_DOWN_FROM_200), 000h
	JR Z, LABEL_FC43B0
	EI 000h
	CALR DELAY_1500_LOOPS
	JR T, CPanel_WaitTXReady_Poll

CPanel_WaitTXReady_BufferCheck:
	; Only reaches here when CP_Flags_A.10 == 00, and I think only CPanel_SM_Idle sets that value...

	LD WA, (CPANEL_LED_WRITE_PTR)
	CP WA, (CPANEL_LED_READ_PTR)
	JR NZ, CPanel_WaitTXReady_Timeout

LABEL_FC43B0:
	EI 006h
	LD (INTCLR), 022h ; INTRX1: Serial receive 1
	LD (INTCLR), 023h ; INTTX1: Serial send 1
	LD (INTES1), 0ddh
	AND (SC1MOD), 0dfh  ; RXE (bit 5) = 0: receive disable
	OR (CPANEL_PROTOCOL_FLAGS), 080h	; CP_Flags_B.7 = 1
	EI 000h
	RET


CPanel_SendCommand:
	EI 006h
	LDW (CPANEL_LED_READ_PTR), 0000h
	LDW (CPANEL_LED_WRITE_PTR), 0000h
	LD (CPANEL_LED_TX_BUFFER), WA
	ADDW (CPANEL_LED_WRITE_PTR), 0002h
	OR (CPANEL_TX_RX_FLAGS), 002h
	AND (CPANEL_TX_RX_FLAGS), 0feh	; CP_Flags_A.10 = 2
	LD (CPANEL_STATE_MACHINE_INDEX), 004h		; ROUTINE_1
	LD (BR1CR), 028h ; Internal Clock T8 (64/fc)
	                 ; Divide by 8
	                 ; fc = 16MHz, so fc/64/8 = 31250
	AND (PFFC_VALUE), 0bfh ; disable CPanel serial ckl
	LD A, (PFFC_VALUE)
	LD (PFFC), A
	AND (PF), 0bfh 		; PF bit 6: SCLK1 = 0
	OR (PFCR_VALUE), 040h
	LD A, (PFCR_VALUE)
	LD (PFCR), A
	LD (INTEAB), 007h
	LD (INTCLR), 012h ; INTA Pin
	AND (SC1MOD), 0dfh  ; RXE (bit 5) = 0: CPanel receive disable
	AND (SC1CR), 0feh  ; IOC (bit 0) = 0: I/O interface input clock select = Baud rate generator 
	LD (INTCLR), 023h ; INTTX1: Serial send 1
	LD (INTES1), 0dfh
	LD (INTCLR), 022h ; INTRX1: Serial receive 1
	LD (SC1BUF), A
	EI 000h
	NOP
	RET


INTA_HANDLER:					; fc442b
	LD (CPANEL_COUNTER_UP_TO_20), 000h
	PUSH XWA
	CP (CPANEL_PACKET_BYTE_COUNT), 000h
	JR NZ, LABEL_FC4462

	AND (PFCR_VALUE), 09fh
	LD A, (PFCR_VALUE)
	LD (PFCR), A
	OR (SC1CR), 001h	; IOC (bit 0) = 1: Set I/O interface input clock select to SCLK1 pin
	AND (SC1CR), 0fdh	; SCLKS (bit 1) = 0: Data transmit/receive at SCLK1 rising edge.
	LD (INTEAB), 005h
	LD (INTES1), 00dh
	OR (SC1MOD), 020h  ; parity addition: enable
	LD (CPANEL_STATE_MACHINE_INDEX), 020h;		ROUTINE_7
	OR (CPANEL_TX_RX_FLAGS), 001h ; CP_Flags_A.0 = 1
	JR T, INTA_HANDLER_END

LABEL_FC4462:
	CPW (CPANEL_RX_WRITE_PTR), 0000h
	JR NZ, LABEL_FC4470

	LDW (CPANEL_RX_WRITE_PTR), 005ch

LABEL_FC4470:
	DECW 1, (CPANEL_RX_WRITE_PTR)
	OR (CPANEL_PROTOCOL_FLAGS), 040h	; CP_Flags_B.6 = 1  ; UNUSED
	AND (CPANEL_TX_RX_FLAGS), 0fdh	; CP_Flags_A.1 = 0

INTA_HANDLER_END:      ; FC447E
	POP XWA
	LD (INTCLR), 012h ; INTA Pin
	LD (INTCLR), 022h ; INTRX1: Serial receive 1
	LD (INTCLR), 023h ; INTTX1: Serial send 1
	RETI


CPANEL_STATE_MACHINE_TABLE:		; FC4489
	dd CPanel_SM_Idle ;(offsets: 000h)  ; IDLE
	dd CPanel_SM_StartTX ;(         004h)  
	dd CPanel_SM_SendByte1 ;(         008h)
	dd CPanel_SM_TXDelay1 ;(         00ch)
	dd CPanel_SM_SendByteN ;(         010h)
	dd CPanel_SM_TXDelay2 ;(         014h)
	dd CPanel_SM_TXComplete ;(         018h)
	dd CPanel_SM_Idle ;(         01ch)  
	dd CPanel_SM_RXByte1 ;(         020h)  ; READ_BUTTONS_STATE_1
	dd CPanel_SM_RXByteN ;(         024h)  ; READ_BUTTONS_STATE_2
	dd CPanel_SM_Idle ;(         028h)  ; UNREACHABLE_STATE (?)


INTTX1_HANDLER:   ; FC44B5
	PUSH XWA
	PUSH XHL
	PUSH XIY
	LD L, (CPANEL_STATE_MACHINE_INDEX)
	XOR H, H
	EXTZ XHL
	ADD XHL, CPANEL_STATE_MACHINE_TABLE
	LD XHL, (XHL)
	JP T, XHL


MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES:		; FC44CA
	POP XIY
	POP XHL
	POP XWA
	LD (INTCLR), 012h ; INTA Pin
	LD (INTCLR), 022h ; INTRX1: Serial receive 1
	LD (INTCLR), 023h ; INTTX1: Serial send 1
	RETI


INTRX1_HANDLER:   ; FC44D7
	PUSH XWA
	PUSH XHL
	PUSH XIY
	LD L, (CPANEL_STATE_MACHINE_INDEX)
	XOR H, H
	EXTZ XHL
	ADD XHL, CPANEL_STATE_MACHINE_TABLE
	LD XHL, (XHL)
	JP T, XHL

LEAST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES:			; FC44EC
	POP XIY
	POP XHL
	POP XWA
	LD (INTCLR), 012h ; INTA Pin
	LD (INTCLR), 022h ; INTRX1: Serial receive 1
	LD (INTCLR), 023h ; INTTX1: Serial send 1
	RETI


CPanel_SM_StartTX:        ; FC44F9	; Start transmitting command to set LEDs on the control panel... (?)
	AND (PFCR_VALUE), 0bfh
	LD A, (PFCR_VALUE)
	LD (PFCR), A
	LD (BR1CR), 024h ; Internal Clock T8 (64/fc)
	                 ; Divide by 4
	                 ; fc = 16MHz, so fc/64/4 = 62500
	LD (INTEAB), 007h ; INTTRA(TREGA): M=7
	LD (INTES1), 0d0h ; INTTX1: M=5
	AND (SC1CR), 0feh
	LD (SC1BUF), A
	INC 4, (CPANEL_STATE_MACHINE_INDEX) ; next = ROUTINE_2
	MUL_A 001h
	MUL_A 001h
	BIT 6, (PF)		; PF.6 = state of SCLK1 pin
	JR NZ, MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES


						; If we receive a SCLK1 LOW, does it mean CPANEL is trying to spreak and we revert to IDLE state (ROUTINE_0) ?
	LD (CPANEL_PACKET_BYTE_COUNT), 000h
	LD (CPANEL_STATE_MACHINE_INDEX), 000h ; ROUTINE_0
	OR (CPANEL_PROTOCOL_FLAGS), 002h	; CP_Flags_B.1 = 1  ; UNUSED
	LD (INTEAB), 005h
	LD (INTES1), 0ffh
	LD (BR1CR), 024h ; Internal Clock T8 (64/fc)
	                 ; Divide by 4
	                 ; fc = 16MHz, so fc/64/4 = 62500
	AND (CPANEL_TX_RX_FLAGS), 0fdh ; CP_Flags_A.1 = 0
	JRL T, MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES


CPanel_SM_TXDelay1:       ; FC4544
	CALR DELAY_10_LOOPS
	AND (PFCR_VALUE), 0afh
	LD A, (PFCR_VALUE)
	LD (PFCR), A
	AND (PFFC_VALUE), 0afh ; disable CPanel serial clk and TX pin.
	LD A, (PFFC_VALUE)
	LD (PFFC), A
	LD (BR1CR), 024h ; Internal Clock T8 (64/fc)
	                 ; Divide by 4
	                 ; fc = 16MHz, so fc/64/4 = 62500
	LD (INTES1), 0d0h ; INTTX1: M=5
	AND (SC1CR), 0feh
	LD (SC1BUF), A
	INC 4, (CPANEL_STATE_MACHINE_INDEX) ; next routine
	JRL T, MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES


CPanel_SM_TXDelay2:       ; FC4573
	CALR DELAY_10_LOOPS
	AND (PFCR_VALUE), 0afh
	LD A, (PFCR_VALUE)
	LD (PFCR), A
	AND (PFFC_VALUE), 0afh ; disable CPanel serial clk and TX pin.
	LD A, (PFFC_VALUE)
	LD (PFFC), A
	LD (BR1CR), 024h ; Internal Clock T8 (64/fc)
	                 ; Divide by 4
	                 ; fc = 16MHz, so fc/64/4 = 62500
	LD (SC1BUF), A
	LD (INTEAB), 005h
	LD (INTES1), 0d0h ; INTTX1: M=5
	AND (SC1CR), 0feh
	LD (SC1BUF), A
	INC 4, (CPANEL_STATE_MACHINE_INDEX) ; next routine
	JRL T, MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES


CPanel_SM_SendByte1:      ; FC45A8
	LD (BR1CR), 014h ; Internal Clock T2 (16/fc)
	                 ; Divide by 4
	                 ; fc = 16MHz, so fc/16/4 = 250kHz
	OR (PFFC_VALUE), 050h ; Enable CPanel serial clk and TX pin.
	LD A, (PFFC_VALUE)
	LD (PFFC), A
	OR (PFCR_VALUE), 050h
	LD A, (PFCR_VALUE)
	LD (PFCR), A
	AND (SC1CR), 0feh
	LD (INTEAB), 005h
	LD (INTES1), 0d0h ; INTTX1: M=5
	LD XIY, CPANEL_LED_TX_BUFFER
	ADD IY, (CPANEL_LED_READ_PTR)
	LD A, (XIY)
	LD (SC1BUF), A
	INCW 1, (CPANEL_LED_READ_PTR)
	CPW (CPANEL_LED_READ_PTR), 003ch
	JR C, LABEL_FC45ED
	LDW (CPANEL_LED_READ_PTR), 0000h

LABEL_FC45ED:
	LD (CPANEL_PACKET_BYTE_COUNT), 002h
	LD A, (XIY)
	AND A, 03fh
	CP A, 030h
	JR C, LABEL_FC4606
	AND A, 00fh
	ADD A, 003h
	LD (CPANEL_PACKET_BYTE_COUNT), A

LABEL_FC4606:
	INC 4, (CPANEL_STATE_MACHINE_INDEX) ; next = ROUTINE_3
	JRL T, MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES


CPanel_SM_SendByteN:       ; FC460D
	LD (BR1CR), 014h ; Internal Clock T2 (16/fc)
	                 ; Divide by 4
	                 ; fc = 16MHz, so fc/16/4 = 250kHz
	OR (PFFC_VALUE), 050h ; Enable CPanel serial clk and TX pin.
	LD A, (PFFC_VALUE)
	LD (PFFC), A
	OR (PFCR_VALUE), 050h
	LD A, (PFCR_VALUE)
	LD (PFCR), A
	AND (SC1CR), 0feh
	LD (INTEAB), 005h
	LD (INTES1), 0d0h ; INTTX1: M=5
	LD XIY, CPANEL_LED_TX_BUFFER
	ADD IY, (CPANEL_LED_READ_PTR)
	LD A, (XIY)
	LD (SC1BUF), A
	INCW 1, (CPANEL_LED_READ_PTR)
	CPW (CPANEL_LED_READ_PTR), 003ch
	JR C, LABEL_FC4652
	LDW (CPANEL_LED_READ_PTR), 0000h

LABEL_FC4652:
	DEC 1, (CPANEL_PACKET_BYTE_COUNT)
	CP (CPANEL_PACKET_BYTE_COUNT), 001h
	JR Z, LABEL_FC466B
	CP (CPANEL_PACKET_BYTE_COUNT), 000h
	JR Z, LABEL_FC466B
	DEC 4, (CPANEL_STATE_MACHINE_INDEX) ; previous routine
	JRL T, MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES

LABEL_FC466B:
	INC 4, (CPANEL_STATE_MACHINE_INDEX) ; next routine
	JRL T, MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES


CPanel_SM_TXComplete:       ; FC4672
	LD (CPANEL_PACKET_BYTE_COUNT), 000h
	LD (CPANEL_STATE_MACHINE_INDEX), 000h ; ROUTINE_0
	LD WA, (CPANEL_LED_WRITE_PTR)
	SUB WA, (CPANEL_LED_READ_PTR)
	CP WA, 2
	JR C, LABEL_FC46C1
	LD (CPANEL_STATE_MACHINE_INDEX), 004h ; ROUTINE_1
	AND (PFFC_VALUE), 0bfh  ; disable CPanel serial clk
	LD A, (PFFC_VALUE)
	LD (PFFC), A
	AND (PF), 0bfh ; PF bit 6, (SCLK1 | /CTS1) = 0
	OR (PFCR_VALUE), 040h
	LD A, (PFCR_VALUE)
	LD (PFCR), A
	LD (BR1CR), 028h ; Internal Clock T8 (64/fc)
	                 ; Divide by 8
	                 ; fc = 16MHz, so fc/64/8 = 31250
	LD (INTEAB), 007h
	AND (SC1CR), 0feh
	LD (INTES1), 0d0h ; INTTX1: M=5
	LD (SC1BUF), A
	OR (CPANEL_TX_RX_FLAGS), 002h ; CP_Flags_A.1 = 1 
	JRL T, MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES

LABEL_FC46C1:
	AND (PFCR_VALUE), 0bfh
	LD A, (PFCR_VALUE)
	LD (PFCR), A
	AND (PFFC_VALUE), 0bfh ; disable CPanel serial clk
	LD A, (PFFC_VALUE)
	LD (PFFC), A
	LD (INTEAB), 005h
	LD (INTES1), 0ffh ; INTTX1: M=7 | INTRX1: M=7 (meaning: disable int.req.)
	LD (BR1CR), 024h ; Internal Clock T8 (64/fc)
	                 ; Divide by 4
	                 ; fc = 16MHz, so fc/64/4 = 62500
	AND (CPANEL_TX_RX_FLAGS), 0fdh ; CP_Flags_A.1 = 0
	JRL T, MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES


CPanel_SM_RXByte1:        ; FC46EA
	AND (PFCR_VALUE), 09fh
	LD A, (PFCR_VALUE)
	LD (PFCR), A
	OR (SC1CR), 001h
	AND (SC1CR), 0fdh
	LD (INTEAB), 005h
	LD (INTES1), 00dh
	LD A, (SC1BUF)
	LD XIY, CPANEL_RX_RING_BUFFER
	ADD IY, (CPANEL_RX_WRITE_PTR)
	LD (XIY), A
	LD HL, (CPANEL_RX_WRITE_PTR)
	SUB HL, (CPANEL_RX_READ_PTR)
	JR NC, LABEL_FC4722
	NEG HL
	LD IY, HL
	JR T, LABEL_FC4727

LABEL_FC4722:
	LD IY, 005ch
	SUB IY, HL

LABEL_FC4727:
	CP IY, 3
	JR NC, LABEL_FC4732
	OR (CPANEL_PROTOCOL_FLAGS), 001h	; CP_Flags_B.0 = 1
	JR T, LABEL_FC4749

LABEL_FC4732:
	AND (CPANEL_PROTOCOL_FLAGS), 0feh	; CP_Flags_B.0 = 0
	INCW 1, (CPANEL_RX_WRITE_PTR)
	CPW (CPANEL_RX_WRITE_PTR), 005ch
	JR C, LABEL_FC4749
	LDW (CPANEL_RX_WRITE_PTR), 0000h

LABEL_FC4749:
	LD (CPANEL_PACKET_BYTE_COUNT), 002h
	AND A, 03fh
	CP A, 030h
	JR C, LABEL_FC4760
	AND A, 00fh
	ADD A, 003h
	LD (CPANEL_PACKET_BYTE_COUNT), A

LABEL_FC4760:
	INC 4, (CPANEL_STATE_MACHINE_INDEX) ; next routine
	JRL T, LEAST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES


CPanel_SM_RXByteN:       ; FC4767
	LD A, (SC1BUF)
	LD XIY, CPANEL_RX_RING_BUFFER
	ADD IY, (CPANEL_RX_WRITE_PTR)
	LD (XIY), A
	BIT 0, (CPANEL_PROTOCOL_FLAGS)			; CP_Flags_B.0	
	JR NZ, LABEL_FC478D
	INCW 1, (CPANEL_RX_WRITE_PTR)
	CPW (CPANEL_RX_WRITE_PTR), 005ch
	JR C, LABEL_FC478D
	LDW (CPANEL_RX_WRITE_PTR), 0000h

LABEL_FC478D:
	DEC 1, (CPANEL_PACKET_BYTE_COUNT)
	CP (CPANEL_PACKET_BYTE_COUNT), 001h
	JR NZ, LABEL_FC47CC
	LD (CPANEL_PACKET_BYTE_COUNT), 000h
	AND (CPANEL_TX_RX_FLAGS), 0feh ; CP_Flags_A.0 = 0
	LD (CPANEL_STATE_MACHINE_INDEX), 000h ; ROUTINE_0
	AND (PFCR_VALUE), 09fh
	LD A, (PFCR_VALUE)
	LD (PFCR), A
	AND (PFFC_VALUE), 0bfh ; disable CPanel serial clk
	LD A, (PFFC_VALUE)
	LD (PFFC), A
	LD (INTEAB), 005h
	LD (INTES1), 00dh
	AND (SC1MOD), 0dfh  ; RXE (bit 5) = 0: receive disable
	JRL T, LEAST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES

LABEL_FC47CC:
	AND (PFCR_VALUE), 09fh
	LD A, (PFCR_VALUE)
	LD (PFCR), A
	OR (SC1CR), 001h
	AND (SC1CR), 0fdh
	LD (INTEAB), 005h
	LD (INTES1), 00dh
	JRL T, LEAST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES


CPanel_SM_Idle:       ; FC47E9		; CPANEL_SERIAL_IDLE_STATE (?)
	OR (CPANEL_PROTOCOL_FLAGS), 080h	; CP_Flags_B.7 = 1
	JRL T, LEAST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES

	AND (CPANEL_TX_RX_FLAGS), 0fch 	; CP_Flags_A.0 = 0
						; CP_Flags_A.1 = 0
	OR (CPANEL_PROTOCOL_FLAGS), 004h	; CP_Flags_B.2 = 1  : UNUSED
	LD (INTCLR), 023h ; INTTX1: Serial send 1
	AND (SC1MOD), 0dfh  ; RXE (bit 5) = 0: receive disable
	LD (INTES1), 00fh
	LD (INTCLR), 022h ; INTRX1: Serial receive 1
	LD (INTEAB), 007h
	LD (INTCLR), 012h ; INTA Pin
	RETI


CPanel_InterruptPoll_MainLoop:
	INC 1, (CPANEL_COUNTER_UP_TO_42)
	CP (CPANEL_COUNTER_UP_TO_42), 02ah     ; =42 ;-)
	JR ULE, LABEL_FC485B
	EI 006h
	LD WA, (CPANEL_LED_WRITE_PTR)
	SUB WA, (CPANEL_LED_READ_PTR)
	JR NC, LABEL_FC482C
	NEG WA
	LD HL, WA
	JR T, LABEL_FC4831

LABEL_FC482C:
	LD HL, 003ch
	SUB HL, WA

LABEL_FC4831:
	CP HL, 3
	JR C, LABEL_FC485B
	LD (CPANEL_COUNTER_UP_TO_42), 000h
	LD_W 0e0h
	LD_A 013h
	LD IY, (CPANEL_LED_WRITE_PTR)
	LD XDE, CPANEL_LED_TX_BUFFER
	LD (XDE + IY), W
	CALR CPanel_IncLEDPtr
	LD (XDE + IY), A
	CALR CPanel_IncLEDPtr
	LD (CPANEL_LED_WRITE_PTR), IY


; 0 => 0 do_this
; 1 => 2 do_this
; 2 => 3 do_this
; 3 => 0 do_that

LABEL_FC485B:
	EI 000h
	LD A, (CPANEL_TX_RX_FLAGS)
	AND A, 0c0h
	CP A, 0					; if (CP_Flags_A.76 == 0) {
	JR Z, LABEL_FC4877			; 	goto LABEL_FC4877; ; do this
						; }


	ADD (CPANEL_TX_RX_FLAGS), 040h
	CP A, 0c0h
	JR NZ, LABEL_FC4877 	; if (CP_Flags_A.76++ == 3) {

	CALR CPanel_InitButtonState ; do that

	JR T, LABEL_FC487A
				; } else {

LABEL_FC4877:
	CALR CPanel_UpdateLEDs 		; do this
				; }
LABEL_FC487A:
	EI 006h
	BIT 6, (PF)		; PF.6 = state of SCLK1 pin
	JR Z, LABEL_FC48EB
	BIT 5, (PE)		; PE.5 = state of INTA pin
	JR NZ, LABEL_FC48EB
	BIT 1, (CPANEL_TX_RX_FLAGS)
	JR NZ, LABEL_FC48EB
	BIT 0, (CPANEL_TX_RX_FLAGS)
	JR NZ, LABEL_FC48EB

	; Only reaches here when (CPANEL_TX_RX_FLAGS), CP_Flags_A.10 == 00:
	LD WA, (CPANEL_LED_WRITE_PTR)
	SUB WA, (CPANEL_LED_READ_PTR)
	JR NC, LABEL_FC48A4
	NEG WA
	EX A, W
	LD_A 03ch
	SUB A, W

LABEL_FC48A4:
	CP A, 2
	JR C, LABEL_FC48E8
	OR (CPANEL_TX_RX_FLAGS), 002h		; CP_Flags_A.1 = 1
	LD (CPANEL_STATE_MACHINE_INDEX), 004h; ROUTINE_1
	AND (PFFC_VALUE), 0bfh ; disable CPanel serial clk
	LD A, (PFFC_VALUE)
	LD (PFFC), A
	AND (PF), 0bfh ; PF bit 6, (SCLK1 | /CTS1) = 0
	OR (PFCR_VALUE), 040h
	LD A, (PFCR_VALUE)
	LD (PFCR), A
	LD (BR1CR), 028h ; Internal Clock T8 (64/fc)
	                 ; Divide by 8
	                 ; fc = 16MHz, so fc/64/8 = 31250
	AND (SC1MOD), 0dfh  ; RXE (bit 5) = 0: CPanel receive disable
	AND (SC1CR), 0feh
	LD (INTEAB), 007h
	LD (INTCLR), 012h ; INTA Pin
	LD (INTCLR), 023h ; INTTX1: Serial send 1 
	LD (INTES1), 0d0h
	LD (SC1BUF), A

LABEL_FC48E8:
	EI 000h
	RET


LABEL_FC48EB:
	INC 1, (CPANEL_COUNTER_UP_TO_20)
	CP (CPANEL_COUNTER_UP_TO_20), 014h
	JR ULE, LABEL_FC48E8

	EI 006h
	LD (INTCLR), 022h ; INTRX1: Serial receive 1
	LD (INTCLR), 023h ; INTTX1: Serial send 1
	LD (INTES1), 0ddh
	LD (INTCLR), 012h ; INTA Pin
	LD (INTEAB), 005h
	OR (CPANEL_PROTOCOL_FLAGS), 080h	; CP_Flags_B.7 = 1
	JR T, LABEL_FC48E8




CPanel_RX_ProcessWithFlag:
	OR (CPANEL_TX_RX_FLAGS), 004h ; CP_Flags_A.2 = 1  ; UNUSED?
	JR T, CPanel_RX_DispatchLoop

CPanel_RX_Process:
	AND (CPANEL_TX_RX_FLAGS), 0fbh ; CP_Flags_A.2 = 0  ; UNUSED?

CPanel_RX_DispatchLoop:
	LD XDE, CPANEL_RX_RING_BUFFER
	LD IY, (CPANEL_RX_READ_PTR)
	LD XIZ, CPANEL_RX_EVENT_QUEUE
	LD IX, (XIZ - 4)

CPanel_RX_ParseNext:
	CPW (XIZ - 2), 0004h
	JRL C, CPanel_RX_Done

	LD WA, (CPANEL_RX_WRITE_PTR)
	SUB WA, (CPANEL_RX_READ_PTR)
	JR NC, CPanel_RX_PacketSizeCheck
	NEG WA
	EX A, W
	LD_A 05ch
	SUB A, W

CPanel_RX_PacketSizeCheck:
	CP A, 2
	JRL C, CPanel_RX_Done

	LD L, (XDE + IY)
	AND L, 038h
	SRL 1, L
	XOR H, H
	EXTZ XHL
	ADD XHL, CPanel_RX_PacketHandlers
	LD XHL, (XHL)
	JP T, XHL

CPanel_RX_PacketHandlers_Padding:
	db 0FFh, 0FFh

CPanel_RX_PacketHandlers:
	dd CPanel_RX_ButtonPacket
	dd CPanel_RX_ButtonPacket
	dd CPanel_RX_EncoderPacket
	dd CPanel_RX_SyncPacket
	dd CPanel_RX_SyncPacket
	dd CPanel_RX_SyncPacket
	dd CPanel_RX_MultiBytePacket
	dd CPanel_RX_MultiBytePacket

CPanel_RX_ButtonPacket:
	LD W, (XDE + IY)
	CALR CPanel_IncRXPtr
	LD (XIZ + IX), W
	CALR CPanel_IncEventPtr
	LD (CPANEL_RX_PACKET_BYTE_1), W

	LD A, (XDE + IY)
	CALR CPanel_IncRXPtr
	LD (XIZ + IX), A
	CALR CPanel_IncEventPtr
	LD (CPANEL_RX_PACKET_BYTE_2), A

	AND W, 04fh
	LD XHL, STATE_OF_CPANEL_BUTTONS
	BIT 006h, W
	JR Z, LABEL_FC49BD
	SUB W, 030h

LABEL_FC49BD:
	ADD L, W
	JR NC, LABEL_FC49C3
	INC 1, H

LABEL_FC49C3:
	EX (XHL), A
	XOR A, (XHL)

	LD (XIZ + IX), A
	CALR CPanel_IncEventPtr

	LD (CPANEL_LAST_EVENT_VALUE), A
	LD (XIZ - 4), IX
	DECW 3, (XIZ - 2)
	LD (CPANEL_RX_READ_PTR), IY
	JRL T, CPanel_RX_ParseNext

CPanel_RX_EncoderPacket:
	LD W, (XDE + IY)
	CALR CPanel_IncRXPtr
	LD (XIZ + IX), W
	CALR CPanel_IncEventPtr
	LD (CPANEL_RX_PACKET_BYTE_1), W
	LD A, (XDE + IY)
	CALR CPanel_IncRXPtr
	LD (CPANEL_RX_PACKET_BYTE_2), A
	LD C, W
	CALR LABEL_FC4A36
	CP HL, 0ffffh
	JR NZ, LABEL_FC4A14
	CALR CPanel_DecEventPtr
	LD (CPANEL_RX_READ_PTR), IY
	JR T, LABEL_FC4A33

LABEL_FC4A14:
	LD (XIZ + IX), L
	CALR CPanel_IncEventPtr
	LD (CPANEL_LAST_EVENT_VALUE), L
	LD (XIZ + IX), 0ffh
	CALR CPanel_IncEventPtr
	LD (XIZ - 4), IX
	DECW 3, (XIZ - 2)
	LD (CPANEL_RX_READ_PTR), IY

LABEL_FC4A33:
	JRL T, CPanel_RX_ParseNext

LABEL_FC4A36:
	PUSH XDE
	PUSH XIZ
	PUSH XIX
	CALR CPanel_EncoderDispatch
	POP XIX
	POP XIZ
	POP XDE
	RET

CPanel_RX_MultiBytePacket:
	LD W, A
	LD A, (XDE + IY)
	LD C, A
	AND A, 00fh
	INC 1, A
	LD B, A
	ADD A, 002h
	CP W, A
	JRL C, CPanel_RX_Done

	CALR CPanel_IncRXPtr
	LD A, (XDE + IY)
	CALR CPanel_IncRXPtr
	AND A, 01fh
	AND C, 0c0h
	OR C, A
	LD W, C
	BIT 004h, W
	JR NZ, LABEL_FC4A8B
	AND C, 040h
	BIT 006h, C
	JR Z, LABEL_FC4A7D
	SUB C, 030h

LABEL_FC4A7D:
	OR A, C
	LD L, A
	EXTZ HL
	EXTZ XHL
	ADD XHL, STATE_OF_CPANEL_BUTTONS

LABEL_FC4A8B:
	LD (XIZ + IX), W
	CALR CPanel_IncEventPtr
	LD A, (XDE + IY)
	CALR CPanel_IncRXPtr
	BIT 004h, W
	JR Z, LABEL_FC4AC5
	PUSH BC
	LD C, W
	PUSH HL
	PUSH WA
	CALR LABEL_FC4A36
	POP WA
	CP HL, 0ffffh
	LD (CPANEL_LAST_EVENT_VALUE), L
	POP HL
	POP BC
	JR NZ, LABEL_FC4AC1
	JR T, LABEL_FC4AB7

LABEL_FC4AB7:
	CALR CPanel_DecEventPtr
	LD (CPANEL_RX_READ_PTR), IY
	JRL T, LABEL_FC4B04

LABEL_FC4AC1:
	LD A, (CPANEL_LAST_EVENT_VALUE)

c:
	LD (XIZ + IX), A
	CALR CPanel_IncEventPtr
	BIT 004h, W
	JR NZ, LABEL_FC4AEA
	EX (XHL), A
	XOR A, (XHL)
	INC 1, HL
	BIT 4, (CPANEL_TX_RX_FLAGS)	; This is never set ?!
	JR Z, LABEL_FC4AEC
	CP A, 0
	JR NZ, LABEL_FC4AEC
					; if CP_Flags_A.4 != 0 && A == 0:
	CALR CPanel_DecEventPtr
	CALR CPanel_DecEventPtr
	JR T, LABEL_FC4B00

LABEL_FC4AEA:
	LD_A 0ffh

					; else:
LABEL_FC4AEC:
	LD (XIZ + IX), A
	CALR CPanel_IncEventPtr
	LD (XIZ - 4), IX
	DECW 1, (XIZ - 2)
	DECW 1, (XIZ - 2)
	DECW 1, (XIZ - 2)

LABEL_FC4B00:
	LD (CPANEL_RX_READ_PTR), IY

LABEL_FC4B04:
	INC 1, W
	DEC 1, B
	CP B, 0
	JRL NZ, LABEL_FC4A8B
	JRL T, CPanel_RX_ParseNext

CPanel_RX_SyncPacket:
	LD A, (XDE + IY)
	CALR CPanel_IncRXPtr
	LD A, (XDE + IY)
	CALR CPanel_IncRXPtr
	LD (CPANEL_RX_READ_PTR), IY
	OR (CPANEL_PROTOCOL_FLAGS), 008h	; CP_Flags_B.3 = 1  ; UNUSED
	JRL T, CPanel_RX_ParseNext

CPanel_RX_Done ; FC4B2C
	RET


CPanel_UpdateLEDs: 		; do this
	LD IY, (CPANEL_LED_WRITE_PTR)
	LD XDE, CPANEL_LED_TX_BUFFER
	LD XIZ, CPANEL_LED_EVENT_QUEUE
	LD IX, (XIZ - 8)
	LD WA, (XIZ - 4)
	CP WA, (XIZ - 8)
	JR NZ, LABEL_FC4B4E
	CPW (XIZ - 2), 0000h
	JRL NZ, LABEL_FC4C07

LABEL_FC4B4E:
	LD WA, (CPANEL_LED_WRITE_PTR)
	SUB WA, (CPANEL_LED_READ_PTR)
	JR NC, LABEL_FC4B5E
	NEG WA
	LD HL, WA
	JR T, LABEL_FC4B63

LABEL_FC4B5E:
	LD HL, 003ch
	SUB HL, WA

LABEL_FC4B63:
	CP HL, 3
	JRL C, LABEL_FC4C07
	LD A, (XIZ + IX)
	AND A, 030h
	SRL 2, A
	LD L, A
	XOR H, H
	EXTZ XHL
	ADD XHL, CPanel_LED_PacketHandlers
	LD XHL, (XHL)
	JP T, XHL

CPanel_LED_PacketHandlers_Padding:
	db 0FFh, 0FFh


CPanel_LED_PacketHandlers:
	dd LABEL_FC4B95
	dd LABEL_FC4B95
	dd LABEL_FC4B95
	dd LABEL_FC4BC5


LABEL_FC4B95:
	db 0C3h, 007h, 0F8h, 0F0h, 021h, 01Eh, 097h, 000h
	db 0F3h, 007h, 0E8h, 0F4h, 041h, 01Eh
	db 06Eh, 000h, 0C3h, 007h, 0F8h, 0F0h, 020h, 01Eh
	db 087h, 000h, 0F3h, 007h, 0E8h, 0F4h, 040h, 01Eh
	db 05Eh, 000h, 0BEh, 0F8h, 054h, 09Eh, 0FEh, 061h
	db 09Eh, 0FEh, 061h, 0F1h, 0FFh, 08Dh, 055h, 078h
	db 079h, 0FFh

LABEL_FC4BC5:	
	db 0C3h, 007h, 0F8h, 0F0h, 021h, 01Eh
	db 067h, 000h, 0C9h, 08Bh, 0C9h, 0CCh, 00Fh, 0C9h
	db 0C8h, 002h, 0C9h, 08Ah, 0CBh, 089h, 0F3h, 007h
	db 0E8h, 0F4h, 041h, 01Eh, 032h, 000h, 09Eh, 0FEh
	db 061h, 0C3h, 007h, 0F8h, 0F0h, 021h, 01Eh, 048h
	db 000h, 0F3h, 007h, 0E8h, 0F4h, 041h, 01Eh, 01Fh
	db 000h, 0BEh, 0F8h, 054h, 09Eh, 0FEh, 061h, 0F1h
	db 0FFh, 08Dh, 055h, 0CAh, 069h, 0CAh, 0D8h, 06Eh
	db 0E0h, 078h, 037h, 0FFh

LABEL_FC4C07:
	RET


CPanel_IncRXPtr: 		; FC4C08
	INC 1, IY
	CP IY, 005ch
	JR C, LABEL_FC4C12
	LD IY, 0

LABEL_FC4C12:
	RET


CPanel_IncLEDPtr:		; FC4C13
	INC 1, IY
	CP IY, 003ch
	JR C, LABEL_FC4C1D
	LD IY, 0

LABEL_FC4C1D:
	RET


CPanel_IncEventPtr:		; FC4C1E
	INC 1, IX
	CP IX, 0080h
	JR C, LABEL_FC4C28
	LD IX, 0

LABEL_FC4C28:
	RET


CPanel_DecEventPtr: ; FC4C29
	CP IX, 0
	JR NZ, LABEL_FC4C31
	LD IX, 007fh
	RET

LABEL_FC4C31:
	DEC 1, IX
	RET

; End of control panel routines
