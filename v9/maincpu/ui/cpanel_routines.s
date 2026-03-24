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

CPanel_ScanButtons:
	push xix
	push xiz
	push xhl
	push xde
	call CPanel_ReadAllButtons
	pop xde
	pop xhl
	pop xiz
	pop xix
	calr CPanel_CheckSpecialCombos
	ret


CPanel_InitHardware:
	ld xhl, 0x200ad
	ldw (xhl - 4), 0x0
	ldw (xhl - 8), 0x0
	ldw (xhl - 2), 0x80

	ld xhl, 0x20137
	ldw (xhl - 4), 0x0
	ldw (xhl - 8), 0x0
	ldw (xhl - 2), 0x80

	ldb a, 0x3	; PF2=SCK0 Disabled, PF0=TxD0 and PF1=RXD0 (MIDI)
	and a, 0xaf	; PF6=SCK1 Disabled, PF4=TxD1 and PF5=RXD1 (Control Panel)
	stda8 0x8D8F, a
	st_dd8b A, 0x3f
	ldb a, 0x15
	and a, 0x8f
	stda8 0x8D8E, a
	st_dd8b A, 0x3e
	and_sd8b_im 0x3c, 0xbf	; PF bit 6, (SCLK1 | /CTS1) = 0
	ldb a, 0x0
	st_dd8b A, 0x3b
	ldb a, 0x46
	st_dd8b A, 0x3a
	ldio 0xd6, 0x00	; serial clk: TO2 trigger
	                  ; serial transfer mode: I/O  transfer mode
	                  ; wake-up function: disable
	                  ; receive control: receive disable
	                  ; handshake function control: CTS disable
	ldio 0xd7, 0x14	; Internal Clock T2 (16/fc)
	                 ; Divide by 4
	                 ; fc = 16MHz, so fc/16/4 = 250kHz
	ldio 0xd5, 0x01	; Parity: odd
	                 ; Parity addition: disable
	                 ; clear all errors
	                 ; Data transmit/receive at SCLK1 rising edge
	                 ; I/O interface input clock: SCLK1 pin input
	ldio 0xe3, 0x07
	ldio 0xf8, 0x12	; INTA Pin
	ldio 0xeb, 0xff
	ldio 0xf8, 0x22	; INTRX1: Serial receive 1
	ldio 0xf8, 0x23	; INTTX1: Serial send 1
	or_sd8b_im 0xc8, 0x10
	and_sd8b_im 0xc8, 0xf7
	stdi8 0x8D91, 125	; This looks pointless...

	ordi8 0x8D8C, 64	; CP_Flags_A.6 = 1
	stdi8 0x8D8B, 0
	anddi8 0x8D8C, 252	; CP_Flags_A.10 = 00
	stdi16 0x8DFD, 0
	stdi16 0x8DFF, 0
	stdi16 0x8D9D, 0
	stdi16 0x8D9F, 0

	calr DELAY_6_TICKS

	ldb a, 0x1f
	ldb w, 0xda
	calr CPanel_SendCommand
	calr DELAY_3000_LOOPS

	stdi16 0x8DFD, 0
	calr DELAY_3000_LOOPS

	calr CPanel_SendInitSequence
	ret


; CPanel_SendInitSequence - Send initialization command sequence to control panel MCUs
; Commands sent: 0x1f 0x1a, 0x1d 0x00, 0xdd 0x03, 0x1e 0x80
CPanel_SendInitSequence:
	ldb a, 0x1f
	ldb w, 0x1a
	calr CPanel_SendCommand
	calr DELAY_3000_LOOPS

	stdi16 0x8DFD, 0
	calr DELAY_3000_LOOPS

	ldb a, 0x1d
	ldb w, 0x0
	calr CPanel_SendCommand
	calr DELAY_3000_LOOPS

	stdi16 0x8DFD, 0
	calr DELAY_3000_LOOPS
	calr DELAY_3000_LOOPS

	ldb a, 0xdd
	ldb w, 0x3
	calr CPanel_SendCommand
	calr DELAY_3000_LOOPS

	stdi16 0x8DFD, 0
	calr DELAY_3000_LOOPS
	calr DELAY_3000_LOOPS

	ldb a, 0x1e
	ldb w, 0x80
	calr CPanel_SendCommand
	calr DELAY_3000_LOOPS
	calr DELAY_3000_LOOPS
	calr DELAY_3000_LOOPS

	ei 6
	ldio 0xeb, 0xff
	ldio 0xf8, 0x22	; INTRX1: Serial receive 1
	ldio 0xf8, 0x23	; INTTX1: Serial send 1
	and_sd8b_im 0xd6, 0xdf	; RXE (bit 5) = 0: receive disable
	ldio 0xf8, 0x12	; INTA Pin
	ldio 0xe3, 0x05
	stdi16 0x8D9D, 0
	stdi16 0x8D9F, 0
	ordi8 0x8D92, 1	; CP_Flags_B.0 = 1
	ei 0
	ret


CPanel_InitLEDBuffer:
	stda16 0x8E01, xwa
	anddi8 0x8D8F, 191
	ldda8 a, 0x8D8F
	st_dd8b A, 0x3f
	ldio 0xeb, 0xff
	ldio 0xf8, 0x22
	ldio 0xf8, 0x23
	ldio 0xe3, 0x07
	ldio 0xf8, 0x12
	and_sd8b_im 0x3c, 0xbf
	ordi8 0x8D8E, 64
	ldda8 a, 0x8D8E
	st_dd8b A, 0x3e
	calr DELAY_300_LOOPS
	calr DELAY_300_LOOPS
	anddi8 0x8D8E, 191
	ldda8 a, 0x8D8E
	st_dd8b A, 0x3e
	calr DELAY_300_LOOPS
	calr DELAY_300_LOOPS
	ordi8 0x8D8F, 80
	ldda8 a, 0x8D8F
	st_dd8b A, 0x3f
	ordi8 0x8D8E, 80
	ldda8 a, 0x8D8E
	st_dd8b A, 0x3e
	and_sd8b_im 0xd5, 0xfe
	ldio 0xeb, 0xff
	ldio 0xf8, 0x22
	ldio 0xf8, 0x23
	ld xiy, 0x8e01
	addda16 xiy, 0x8DFD
	ld a, (xiy)
	incdi16 1, 0x8DFD
	st_dd8b A, 0xd4
	calr DELAY_300_LOOPS
	calr DELAY_300_LOOPS
	ld xiy, 0x8e01
	addda16 xiy, 0x8DFD
	ld a, (xiy)
	incdi16 1, 0x8DFD
	st_dd8b A, 0xd4
	calr DELAY_300_LOOPS
	calr DELAY_300_LOOPS
	or_sd8b_im 0xd5, 0x01
	and_sd8b_im 0xd5, 0xfd
	anddi8 0x8D8E, 175
	ldda8 a, 0x8D8E
	st_dd8b A, 0x3e
	anddi8 0x8D8F, 175
	ldda8 a, 0x8D8F
	st_dd8b A, 0x3f
	ret



; Below are routines that loop N times, where
; N = 2, 6, 10, 300, 1500 or 3000
; These are likely pauses
; But these values are also suspiciously similar to proportions
; between typical baudrates, but this is just a hunch for now...

DELAY_2_LOOPS:
	lds wa, 2

Delay2L_Loop:
	dec 1, wa
	cps wa, 0
	jr z, Delay2L_Done
	jr Delay2L_Loop

Delay2L_Done:
	ret


DELAY_6_LOOPS:
	lds wa, 6

Delay6L_Loop:
	dec 1, wa
	cps wa, 0
	jr z, Delay6L_Done
	jr Delay6L_Loop

Delay6L_Done:
	ret


DELAY_10_LOOPS:
	ldw wa, 0xa

Delay10L_Loop:
	dec 1, wa
	cps wa, 0
	jr z, Delay10L_Done
	jr Delay10L_Loop

Delay10L_Done:
	ret


DELAY_300_LOOPS:
	ldw wa, 0x12c

Delay300L_Loop:
	dec 1, wa
	cps wa, 0
	jr z, Delay300L_Done
	jr Delay300L_Loop

Delay300L_Done:
	ret


DELAY_1500_LOOPS:
	ldw wa, 0x5dc

Delay1500L_Loop:
	dec 1, wa
	cps wa, 0
	jr z, Delay1500L_Done
	jr Delay1500L_Loop

Delay1500L_Done:
	ret


DELAY_3000_LOOPS:
	ldw wa, 0xbb8

Delay3000L_Loop:
	dec 1, wa
	cps wa, 0
	jr z, Delay3000L_Done
	jr Delay3000L_Loop

Delay3000L_Done:
	ret


DELAY_2_TICKS:	; FC4124 - Wait for 2 system timer ticks
	ldda16 xwa, 1033
	stda16 0x8D9B, xwa

DELAY_2_TICKS__loop:
	ldda16 xwa, 1033
	subda16 xwa, 0x8D9B
	cps wa, 2
	jr lt, DELAY_2_TICKS__loop
	ret


DELAY_6_TICKS:
	ldda16 xwa, 1033
	stda16 0x8D9B, xwa

Delay6T_Loop:
	ldda16 xwa, 1033
	subda16 xwa, 0x8D9B
	cps wa, 6
	jr lt, Delay6T_Loop
	ret


DELAY_51_TICKS:
	ldda16 xwa, 1033
	stda16 0x8D9B, xwa

Delay51T_Loop:
	ldda16 xwa, 1033
	subda16 xwa, 0x8D9B
	cp wa, 0x33
	jr lt, Delay51T_Loop
	ret

; ???? R        L
; ???? 25 (001 00101): 01 | e2 (111 00010): 04
; ???? 20 (001 00000): 10 | e2 (111 00010): 11

; =============================================================================
; CPanel_CheckSpecialCombos - Detect special button combos held at power-on
; =============================================================================
; Called during boot by CPanel_ScanButtons. Checks four specific button
; combinations on the control panel and returns a combo code in HL:
;   0 = No special combo (normal boot)
;   1 = Factory Reset / Initial Setting (service manual p I-3)
;   2 = "ALL INITIAL SETTING!" screen + firmware version on LEDs
;   3 = Software version / internal build numbers screen
;   4 = Flash Memory Update mode (requires floppy + first-boot condition)
;
; See: docs/test-modes.md for full documentation
; =============================================================================
CPanel_CheckSpecialCombos:
	cpdi8 0x8E5E, 108	; CPL_SEG4 == 0x6c (0110 1100)?
				; = AUTO PLAY CHORD + SPLIT POINT + VARIATION 4 + VARIATION 3
	jr nz, CPanel_Combo_CheckAllInitSetting
	lds hl, 3		; Combo 3: Software version / build numbers screen
	jr CPanel_CheckSpecialCombos_Return

CPanel_Combo_CheckAllInitSetting:
	cpdi8 0x8E4B, 112	; CPR_SEG1 == 0x70 (0111 0000)?
				; = GM SPECIAL + ACCORDION REGISTER + DIGITAL DRAWBAR
	jr nz, CPanel_Combo_CheckFactoryReset
	lds hl, 2		; Combo 2: "ALL INITIAL SETTING!" + LED version display
	jr CPanel_CheckSpecialCombos_Return

CPanel_Combo_CheckFactoryReset:
	cpdi8 0x8E60, 56		; CPL_SEG6 == 0x38 (0011 1000)?
				; = SHOWTIME & TRAD DANCE + PARTY TIME + MARCH & WALTZ
				; (three leftmost RHYTHM GROUP buttons)
	jr nz, CPanel_Combo_CheckFlashUpdate
	lds hl, 1		; Combo 1: Factory Reset (Initial Setting)
	jr CPanel_CheckSpecialCombos_Return

CPanel_Combo_CheckFlashUpdate:
	cpdi8 0x8E50, 15		; CPR_SEG6 == 0x0f (0000 1111)?
				; = PM 1 + PM 2 + PM 3 + PM 4 (all 4 Panel Memory buttons)
	jr nz, CPanel_Combo_NormalBoot
	lds hl, 4		; Combo 4: Flash Memory Update
	jr CPanel_CheckSpecialCombos_Return

CPanel_Combo_NormalBoot:
	lds hl, 0		; No combo: normal boot

CPanel_CheckSpecialCombos_Return:
	ret


CPanel_PanelDetection:
	stdi8 0x8D93, 0
	calr CPanel_WaitTXReady
	ei 6
	stdi16 0x8D9D, 0
	stdi16 0x8D9F, 0
	ordi8 0x8D92, 1	; CP_Flags_B.0 = 1
	ei 0
	ldb a, 0x20	; my guess: 20 = 001 00000 where 001 = left-panel mcu
	ldb w, 0x0
	calr CPanel_SendCommand
	calr DELAY_6_TICKS
	cpdi16 0x8D9F, 0
	jr z, PanelDet_ProbeRight
	ordi8 0x8D93, 1	; my guess: CP_Flags_C.0
					  ; = Got response from left-panel MCU

PanelDet_ProbeRight:
	calr CPanel_WaitTXReady
	ei 6
	stdi16 0x8D9D, 0
	stdi16 0x8D9F, 0
	ordi8 0x8D92, 1	; CP_Flags_B.0 = 1
	ei 0
	ldb a, 0xe0	; my guess: E0 = 111 00000 where 111 = right-panel mcu
	ldb w, 0x0
	calr CPanel_SendCommand
	calr DELAY_6_TICKS
	cpdi16 0x8D9F, 0
	jr z, PanelDet_Return
	ordi8 0x8D93, 8	; my guess: CP_Flags_C.4
					 ; = Got response from right-panel MCU

PanelDet_Return:
	ldda8 a, 0x8D93
	ret


CPanel_ReadAllButtons:
	ld xhl, 0x200ad
	ldw (xhl - 4), 0x0
	ldw (xhl - 8), 0x0
	ldw (xhl - 2), 0x80

	ei 6
	ldda16 xwa, 0x8D9D
	stda16 0x8D9F, xwa
	ordi8 0x8D92, 1	; CP_Flags_B.0 = 1
	ei 0

	call CPanel_WaitTXReady
	ldb a, 0x25
	ldb w, 0x1
	call CPanel_SendCommand
	calr DELAY_6_TICKS
	calr DELAY_6_TICKS
	calr DELAY_6_TICKS

	calr CPanel_WaitTXReady
	ldb a, 0xe2
	ldb w, 0x4
	calr CPanel_SendCommand
	calr DELAY_6_TICKS
	calr DELAY_6_TICKS

	calr CPanel_WaitTXReady
	ldb a, 0x20
	ldb w, 0x10
	calr CPanel_SendCommand
	calr DELAY_6_TICKS
	calr DELAY_6_TICKS

	calr CPanel_WaitTXReady
	ldb a, 0xe2
	ldb w, 0x11
	calr CPanel_SendCommand
	calr DELAY_6_TICKS
	calr DELAY_6_TICKS

	calr CPanel_RX_Process
	ret


CPanel_PollStartup:
	ld xhl, 0x200ad
	ldw (xhl - 4), 0x0
	ldw (xhl - 8), 0x0
	ldw (xhl - 2), 0x80
	ei 6
	stdi16 0x8D9D, 0
	stdi16 0x8D9F, 0
	ordi8 0x8D92, 1	; CP_Flags_B.0 = 1
	ei 0

CPanel_ButtonPollLoop:
	calr CPanel_WaitTXReady
	ldb a, 0x20
	ldb w, 0xb
	calr CPanel_SendCommand
	calr DELAY_6_TICKS
	calr CPanel_RX_Process

	ldda8 a, 0x8E55	; Byte 11 is in gap between CPR (0-10) and CPL (16-26), possibly status/mode
	ldb w, 0xd	; Default encoder check mode
	bit 7, a	; Test bit 7 of status byte
	jr nz, CPanel_EncoderCheck
	ldb w, 0xe	; Alternate mode if bit 7 set
	bit 6, a	; Test bit 6 of status byte
	jr nz, CPanel_EncoderCheck
	ldb w, 0xc	; Third mode if bit 6 set

CPanel_EncoderCheck:
	cpdm8 0x8E6A, w
	stda8 0x8E6A, w
	jr nz, CPanel_ButtonPollLoop
	stda8 0x8E6A, w
	ld xhl, 0x200ad
	ldw (xhl - 4), 0x0
	ldw (xhl - 8), 0x0
	ldw (xhl - 2), 0x80
	ei 6
	stdi16 0x8DFD, 0
	stdi16 0x8DFF, 0
	stdi16 0x8D9D, 0
	stdi16 0x8D9F, 0
	ordi8 0x8D92, 1	; CP_Flags_B.0 = 1
	ei 0
	ret


CPanel_InitButtonState:	; do that
	ld xhl, 0x200ad
	ldw (xhl - 4), 0x0
	ldw (xhl - 8), 0x0
	ldw (xhl - 2), 0x80

	ei 6
	stdi8 0x8D9D, 0
	stdi8 0x8D9F, 0
	ordi8 0x8D92, 1	; CP_Flags_B.0 = 1
	ei 0

	calr CPanel_WaitTXReady
	ldb a, 0x2b
	ldb w, 0x0
	calr CPanel_SendCommand
	calr DELAY_6_TICKS
	calr DELAY_6_TICKS
	calr DELAY_6_TICKS
	calr CPanel_RX_ProcessWithFlag

	calr CPanel_WaitTXReady
	ldb a, 0xeb
	ldb w, 0x0
	calr CPanel_SendCommand
	calr DELAY_6_TICKS
	calr DELAY_6_TICKS
	calr DELAY_6_TICKS
	calr CPanel_RX_ProcessWithFlag

	calr CPanel_WaitTXReady
	ldb a, 0x20
	ldb w, 0x10
	calr CPanel_SendCommand
	calr DELAY_6_TICKS
	calr DELAY_6_TICKS
	calr CPanel_RX_ProcessWithFlag

	calr CPanel_WaitTXReady
	ldb a, 0xe3
	ldb w, 0x10
	calr CPanel_SendCommand
	calr DELAY_6_TICKS
	calr DELAY_6_TICKS
	calr CPanel_RX_ProcessWithFlag
	ret


CPanel_WaitTXReady:
	stdi8 0x8D97, 200	; =200

CPanel_WaitTXReady_Poll:
	ei 6
	bit_dd8 6, 0x3c	; PF.6 = state of SCLK1 pin == 1, (resting at pull-up)
	jr z, CPanel_WaitTXReady_Timeout
	bit_dd8 5, 0x38	; PE.5 = state of INTA pin == 0
	jr nz, CPanel_WaitTXReady_Timeout
	bitda 1, 0x8D8C
	jr nz, CPanel_WaitTXReady_Timeout
	bitda 0, 0x8D8C
	jr nz, CPanel_WaitTXReady_Timeout
	jr CPanel_WaitTXReady_BufferCheck

CPanel_WaitTXReady_Timeout:
	decdi8 1, 0x8D97
	cpdi8 0x8D97, 0
	jr z, WaitTX_ConfigAndReturn
	ei 0
	calr DELAY_1500_LOOPS
	jr CPanel_WaitTXReady_Poll

CPanel_WaitTXReady_BufferCheck:
	; Only reaches here when CP_Flags_A.10 == 00, and I think only CPanel_SM_Idle sets that value...

	ldda16 xwa, 0x8DFF
	cpda16 xwa, 0x8DFD
	jr nz, CPanel_WaitTXReady_Timeout

WaitTX_ConfigAndReturn:
	ei 6
	ldio 0xf8, 0x22	; INTRX1: Serial receive 1
	ldio 0xf8, 0x23	; INTTX1: Serial send 1
	ldio 0xeb, 0xdd
	and_sd8b_im 0xd6, 0xdf	; RXE (bit 5) = 0: receive disable
	ordi8 0x8D92, 128	; CP_Flags_B.7 = 1
	ei 0
	ret


CPanel_SendCommand:
	ei 6
	stdi16 0x8DFD, 0
	stdi16 0x8DFF, 0
	stda16 0x8E01, xwa
	adddi16 0x8DFF, 2
	ordi8 0x8D8C, 2
	anddi8 0x8D8C, 254	; CP_Flags_A.10 = 2
	stdi8 0x8D8A, 4	; ROUTINE_1
	ldio 0xd7, 0x28	; Internal Clock T8 (64/fc)
	                 ; Divide by 8
	                 ; fc = 16MHz, so fc/64/8 = 31250
	anddi8 0x8D8F, 191	; disable CPanel serial ckl
	ldda8 a, 0x8D8F
	st_dd8b A, 0x3f
	and_sd8b_im 0x3c, 0xbf	; PF bit 6: SCLK1 = 0
	ordi8 0x8D8E, 64
	ldda8 a, 0x8D8E
	st_dd8b A, 0x3e
	ldio 0xe3, 0x07
	ldio 0xf8, 0x12	; INTA Pin
	and_sd8b_im 0xd6, 0xdf	; RXE (bit 5) = 0: CPanel receive disable
	and_sd8b_im 0xd5, 0xfe	; IOC (bit 0) = 0: I/O interface input clock select = Baud rate generator
	ldio 0xf8, 0x23	; INTTX1: Serial send 1
	ldio 0xeb, 0xdf
	ldio 0xf8, 0x22	; INTRX1: Serial receive 1
	st_dd8b A, 0xd4
	ei 0
	nop
	ret


INTA_HANDLER:
	stdi8 0x8D98, 0
	push xwa
	cpdi8 0x8D8B, 0
	jr nz, INTA_HandleCountdown

	anddi8 0x8D8E, 159
	ldda8 a, 0x8D8E
	st_dd8b A, 0x3e
	or_sd8b_im 0xd5, 0x01	; IOC (bit 0) = 1: Set I/O interface input clock select to SCLK1 pin
	and_sd8b_im 0xd5, 0xfd	; SCLKS (bit 1) = 0: Data transmit/receive at SCLK1 rising edge.
	ldio 0xe3, 0x05
	ldio 0xeb, 0x0d
	or_sd8b_im 0xd6, 0x20	; parity addition: enable
	stdi8 0x8D8A, 32	;		ROUTINE_7
	ordi8 0x8D8C, 1	; CP_Flags_A.0 = 1
	jr INTA_HANDLER_END

INTA_HandleCountdown:
	cpdi16 0x8D9F, 0
	jr nz, INTA_DecrementRXCount

	stdi16 0x8D9F, 92

INTA_DecrementRXCount:
	decdi16 1, 0x8D9F
	ordi8 0x8D92, 64	; CP_Flags_B.6 = 1  ; UNUSED
	anddi8 0x8D8C, 253	; CP_Flags_A.1 = 0

INTA_HANDLER_END:
	pop xwa
	ldio 0xf8, 0x12	; INTA Pin
	ldio 0xf8, 0x22	; INTRX1: Serial receive 1
	ldio 0xf8, 0x23	; INTTX1: Serial send 1
	reti


CPANEL_STATE_MACHINE_TABLE:
	.long CPanel_SM_Idle
	.long CPanel_SM_StartTX
	.long CPanel_SM_SendByte1
	.long CPanel_SM_TXDelay1
	.long CPanel_SM_SendByteN
	.long CPanel_SM_TXDelay2
	.long CPanel_SM_TXComplete
	.long CPanel_SM_Idle
	.long CPanel_SM_RXByte1
	.long CPanel_SM_RXByteN
	.long CPanel_SM_Idle


INTTX1_HANDLER:
	push xwa
	push xhl
	push xiy
	ldda8 l, 0x8D8A
	xor h, h
	extz xhl
	add xhl, CPANEL_STATE_MACHINE_TABLE
	ld xhl, (xhl)
	jp (xhl)


MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES:
	pop xiy
	pop xhl
	pop xwa
	ldio 0xf8, 0x12	; INTA Pin
	ldio 0xf8, 0x22	; INTRX1: Serial receive 1
	ldio 0xf8, 0x23	; INTTX1: Serial send 1
	reti


INTRX1_HANDLER:
	push xwa
	push xhl
	push xiy
	ldda8 l, 0x8D8A
	xor h, h
	extz xhl
	add xhl, CPANEL_STATE_MACHINE_TABLE
	ld xhl, (xhl)
	jp (xhl)

LEAST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES:
	pop xiy
	pop xhl
	pop xwa
	ldio 0xf8, 0x12	; INTA Pin
	ldio 0xf8, 0x22	; INTRX1: Serial receive 1
	ldio 0xf8, 0x23	; INTTX1: Serial send 1
	reti


CPanel_SM_StartTX:	; FC44F9	; Start transmitting command to set LEDs on the control panel... (?)
	anddi8 0x8D8E, 191
	ldda8 a, 0x8D8E
	st_dd8b A, 0x3e
	ldio 0xd7, 0x24	; Internal Clock T8 (64/fc)
	                 ; Divide by 4
	                 ; fc = 16MHz, so fc/64/4 = 62500
	ldio 0xe3, 0x07	; INTTRA(TREGA): M=7
	ldio 0xeb, 0xd0	; INTTX1: M=5
	and_sd8b_im 0xd5, 0xfe
	st_dd8b A, 0xd4
	incdi8 4, 0x8D8A	; next = ROUTINE_2
	mul a, 0x1
	mul a, 0x1
	bit_dd8 6, 0x3c	; PF.6 = state of SCLK1 pin
	jr nz, MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES


						; If we receive a SCLK1 LOW, does it mean CPANEL is trying to spreak and we revert to IDLE state (ROUTINE_0) ?
	stdi8 0x8D8B, 0
	stdi8 0x8D8A, 0	; ROUTINE_0
	ordi8 0x8D92, 2	; CP_Flags_B.1 = 1  ; UNUSED
	ldio 0xe3, 0x05
	ldio 0xeb, 0xff
	ldio 0xd7, 0x24	; Internal Clock T8 (64/fc)
	                 ; Divide by 4
	                 ; fc = 16MHz, so fc/64/4 = 62500
	anddi8 0x8D8C, 253	; CP_Flags_A.1 = 0
	jrl MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES


CPanel_SM_TXDelay1:
	calr DELAY_10_LOOPS
	anddi8 0x8D8E, 175
	ldda8 a, 0x8D8E
	st_dd8b A, 0x3e
	anddi8 0x8D8F, 175	; disable CPanel serial clk and TX pin.
	ldda8 a, 0x8D8F
	st_dd8b A, 0x3f
	ldio 0xd7, 0x24	; Internal Clock T8 (64/fc)
	                 ; Divide by 4
	                 ; fc = 16MHz, so fc/64/4 = 62500
	ldio 0xeb, 0xd0	; INTTX1: M=5
	and_sd8b_im 0xd5, 0xfe
	st_dd8b A, 0xd4
	incdi8 4, 0x8D8A	; next routine
	jrl MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES


CPanel_SM_TXDelay2:
	calr DELAY_10_LOOPS
	anddi8 0x8D8E, 175
	ldda8 a, 0x8D8E
	st_dd8b A, 0x3e
	anddi8 0x8D8F, 175	; disable CPanel serial clk and TX pin.
	ldda8 a, 0x8D8F
	st_dd8b A, 0x3f
	ldio 0xd7, 0x24	; Internal Clock T8 (64/fc)
	                 ; Divide by 4
	                 ; fc = 16MHz, so fc/64/4 = 62500
	st_dd8b A, 0xd4
	ldio 0xe3, 0x05
	ldio 0xeb, 0xd0	; INTTX1: M=5
	and_sd8b_im 0xd5, 0xfe
	st_dd8b A, 0xd4
	incdi8 4, 0x8D8A	; next routine
	jrl MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES


CPanel_SM_SendByte1:
	ldio 0xd7, 0x14	; Internal Clock T2 (16/fc)
	                 ; Divide by 4
	                 ; fc = 16MHz, so fc/16/4 = 250kHz
	ordi8 0x8D8F, 80	; Enable CPanel serial clk and TX pin.
	ldda8 a, 0x8D8F
	st_dd8b A, 0x3f
	ordi8 0x8D8E, 80
	ldda8 a, 0x8D8E
	st_dd8b A, 0x3e
	and_sd8b_im 0xd5, 0xfe
	ldio 0xe3, 0x05
	ldio 0xeb, 0xd0	; INTTX1: M=5
	ld xiy, 0x8e01
	addda16 xiy, 0x8DFD
	ld a, (xiy)
	st_dd8b A, 0xd4
	incdi16 1, 0x8DFD
	cpdi16 0x8DFD, 60
	jr c, SendByte1_InspectByte
	stdi16 0x8DFD, 0

SendByte1_InspectByte:
	stdi8 0x8D8B, 2
	ld a, (xiy)
	and a, 0x3f
	cp a, 0x30
	jr c, SendByte1_AdvanceState
	and a, 0xf
	add a, 0x3
	stda8 0x8D8B, a

SendByte1_AdvanceState:
	incdi8 4, 0x8D8A	; next = ROUTINE_3
	jrl MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES


CPanel_SM_SendByteN:
	ldio 0xd7, 0x14	; Internal Clock T2 (16/fc)
	                 ; Divide by 4
	                 ; fc = 16MHz, so fc/16/4 = 250kHz
	ordi8 0x8D8F, 80	; Enable CPanel serial clk and TX pin.
	ldda8 a, 0x8D8F
	st_dd8b A, 0x3f
	ordi8 0x8D8E, 80
	ldda8 a, 0x8D8E
	st_dd8b A, 0x3e
	and_sd8b_im 0xd5, 0xfe
	ldio 0xe3, 0x05
	ldio 0xeb, 0xd0	; INTTX1: M=5
	ld xiy, 0x8e01
	addda16 xiy, 0x8DFD
	ld a, (xiy)
	st_dd8b A, 0xd4
	incdi16 1, 0x8DFD
	cpdi16 0x8DFD, 60
	jr c, SendByteN_CheckDone
	stdi16 0x8DFD, 0

SendByteN_CheckDone:
	decdi8 1, 0x8D8B
	cpdi8 0x8D8B, 1
	jr z, SendByteN_AdvanceState
	cpdi8 0x8D8B, 0
	jr z, SendByteN_AdvanceState
	decdi8 4, 0x8D8A	; previous routine
	jrl MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES

SendByteN_AdvanceState:
	incdi8 4, 0x8D8A	; next routine
	jrl MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES


CPanel_SM_TXComplete:
	stdi8 0x8D8B, 0
	stdi8 0x8D8A, 0	; ROUTINE_0
	ldda16 xwa, 0x8DFF
	subda16 xwa, 0x8DFD
	cps wa, 2
	jr c, TXComplete_BufferEmpty
	stdi8 0x8D8A, 4	; ROUTINE_1
	anddi8 0x8D8F, 191	; disable CPanel serial clk
	ldda8 a, 0x8D8F
	st_dd8b A, 0x3f
	and_sd8b_im 0x3c, 0xbf	; PF bit 6, (SCLK1 | /CTS1) = 0
	ordi8 0x8D8E, 64
	ldda8 a, 0x8D8E
	st_dd8b A, 0x3e
	ldio 0xd7, 0x28	; Internal Clock T8 (64/fc)
	                 ; Divide by 8
	                 ; fc = 16MHz, so fc/64/8 = 31250
	ldio 0xe3, 0x07
	and_sd8b_im 0xd5, 0xfe
	ldio 0xeb, 0xd0	; INTTX1: M=5
	st_dd8b A, 0xd4
	ordi8 0x8D8C, 2	; CP_Flags_A.1 = 1
	jrl MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES

TXComplete_BufferEmpty:
	anddi8 0x8D8E, 191
	ldda8 a, 0x8D8E
	st_dd8b A, 0x3e
	anddi8 0x8D8F, 191	; disable CPanel serial clk
	ldda8 a, 0x8D8F
	st_dd8b A, 0x3f
	ldio 0xe3, 0x05
	ldio 0xeb, 0xff	; INTTX1: M=7 | INTRX1: M=7 (meaning: disable int.req.)
	ldio 0xd7, 0x24	; Internal Clock T8 (64/fc)
	                 ; Divide by 4
	                 ; fc = 16MHz, so fc/64/4 = 62500
	anddi8 0x8D8C, 253	; CP_Flags_A.1 = 0
	jrl MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES


CPanel_SM_RXByte1:
	anddi8 0x8D8E, 159
	ldda8 a, 0x8D8E
	st_dd8b A, 0x3e
	or_sd8b_im 0xd5, 0x01
	and_sd8b_im 0xd5, 0xfd
	ldio 0xe3, 0x05
	ldio 0xeb, 0x0d
	ld_sd8b A, 0xd4
	ld xiy, 0x8da1
	addda16 xiy, 0x8D9F
	ld (xiy), a
	ldda16 xhl, 0x8D9F
	subda16 xhl, 0x8D9D
	jr nc, RXByte1_ForwardDist
	neg hl
	ld iy, hl
	jr RXByte1_CheckThreshold

RXByte1_ForwardDist:
	ldw iy, 0x5c
	sub iy, hl

RXByte1_CheckThreshold:
	cps iy, 3
	jr nc, RXByte1_AdvanceWritePtr
	ordi8 0x8D92, 1	; CP_Flags_B.0 = 1
	jr RXByte1_InspectByte

RXByte1_AdvanceWritePtr:
	anddi8 0x8D92, 254	; CP_Flags_B.0 = 0
	incdi16 1, 0x8D9F
	cpdi16 0x8D9F, 92
	jr c, RXByte1_InspectByte
	stdi16 0x8D9F, 0

RXByte1_InspectByte:
	stdi8 0x8D8B, 2
	and a, 0x3f
	cp a, 0x30
	jr c, RXByte1_AdvanceState
	and a, 0xf
	add a, 0x3
	stda8 0x8D8B, a

RXByte1_AdvanceState:
	incdi8 4, 0x8D8A	; next routine
	jrl LEAST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES


CPanel_SM_RXByteN:
	ld_sd8b A, 0xd4
	ld xiy, 0x8da1
	addda16 xiy, 0x8D9F
	ld (xiy), a
	bitda 0, 0x8D92	; CP_Flags_B.0
	jr nz, RXByteN_CheckDone
	incdi16 1, 0x8D9F
	cpdi16 0x8D9F, 92
	jr c, RXByteN_CheckDone
	stdi16 0x8D9F, 0

RXByteN_CheckDone:
	decdi8 1, 0x8D8B
	cpdi8 0x8D8B, 1
	jr nz, RXByteN_ContinueRX
	stdi8 0x8D8B, 0
	anddi8 0x8D8C, 254	; CP_Flags_A.0 = 0
	stdi8 0x8D8A, 0	; ROUTINE_0
	anddi8 0x8D8E, 159
	ldda8 a, 0x8D8E
	st_dd8b A, 0x3e
	anddi8 0x8D8F, 191	; disable CPanel serial clk
	ldda8 a, 0x8D8F
	st_dd8b A, 0x3f
	ldio 0xe3, 0x05
	ldio 0xeb, 0x0d
	and_sd8b_im 0xd6, 0xdf	; RXE (bit 5) = 0: receive disable
	jrl LEAST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES

RXByteN_ContinueRX:
	anddi8 0x8D8E, 159
	ldda8 a, 0x8D8E
	st_dd8b A, 0x3e
	or_sd8b_im 0xd5, 0x01
	and_sd8b_im 0xd5, 0xfd
	ldio 0xe3, 0x05
	ldio 0xeb, 0x0d
	jrl LEAST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES


CPanel_SM_Idle:	; FC47E9		; CPANEL_SERIAL_IDLE_STATE (?)
	ordi8 0x8D92, 128	; CP_Flags_B.7 = 1
	jrl LEAST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES

	anddi8 0x8D8C, 252	; CP_Flags_A.0 = 0
						; CP_Flags_A.1 = 0
	ordi8 0x8D92, 4	; CP_Flags_B.2 = 1  : UNUSED
	ldio 0xf8, 0x23	; INTTX1: Serial send 1
	and_sd8b_im 0xd6, 0xdf	; RXE (bit 5) = 0: receive disable
	ldio 0xeb, 0x0f
	ldio 0xf8, 0x22	; INTRX1: Serial receive 1
	ldio 0xe3, 0x07
	ldio 0xf8, 0x12	; INTA Pin
	reti


CPanel_InterruptPoll_MainLoop:
	incdi8 1, 0x8D9A
	cpdi8 0x8D9A, 42	; =42 ;-)
	jr ule, PollLoop_DispatchWork
	ei 6
	ldda16 xwa, 0x8DFF
	subda16 xwa, 0x8DFD
	jr nc, PollLoop_TXForwardDist
	neg wa
	ld hl, wa
	jr PollLoop_TXCheckThreshold

PollLoop_TXForwardDist:
	ldw hl, 0x3c
	sub hl, wa

PollLoop_TXCheckThreshold:
	cps hl, 3
	jr c, PollLoop_DispatchWork
	stdi8 0x8D9A, 0
	ldb w, 0xe0
	ldb a, 0x13
	ldda16 xiy, 0x8DFF
	ld xde, 0x8e01
	lda_dri3 XWA, 0x07, 0xe8, 0xf4
	calr CPanel_IncLEDPtr
	lda_dri3 XBC, 0x07, 0xe8, 0xf4
	calr CPanel_IncLEDPtr
	stda16 0x8DFF, xiy


; 0 => 0 do_this
; 1 => 2 do_this
; 2 => 3 do_this
; 3 => 0 do_that

PollLoop_DispatchWork:
	ei 0
	ldda8 a, 0x8D8C
	and a, 0xc0
	cps a, 0	; if (CP_Flags_A.76 == 0) {
	jr z, PollLoop_DoLEDUpdate	; 	goto PollLoop_DoLEDUpdate; ; do this
						; }


	adddi8 0x8D8C, 64
	cp a, 0xc0
	jr nz, PollLoop_DoLEDUpdate	; if (CP_Flags_A.76++ == 3) {

	calr CPanel_InitButtonState	; do that

	jr PollLoop_CheckTXReady
				; } else {

PollLoop_DoLEDUpdate:
	calr CPanel_UpdateLEDs	; do this
				; }
PollLoop_CheckTXReady:
	ei 6
	bit_dd8 6, 0x3c	; PF.6 = state of SCLK1 pin
	jr z, PollLoop_BusyRetry
	bit_dd8 5, 0x38	; PE.5 = state of INTA pin
	jr nz, PollLoop_BusyRetry
	bitda 1, 0x8D8C
	jr nz, PollLoop_BusyRetry
	bitda 0, 0x8D8C
	jr nz, PollLoop_BusyRetry

	; Only reaches here when (CPANEL_TX_RX_FLAGS), CP_Flags_A.10 == 00:
	ldda16 xwa, 0x8DFF
	subda16 xwa, 0x8DFD
	jr nc, PollLoop_StartTX
	neg wa
	ex8 a, w
	ldb a, 0x3c
	sub a, w

PollLoop_StartTX:
	cps a, 2
	jr c, PollLoop_Return
	ordi8 0x8D8C, 2	; CP_Flags_A.1 = 1
	stdi8 0x8D8A, 4	; ROUTINE_1
	anddi8 0x8D8F, 191	; disable CPanel serial clk
	ldda8 a, 0x8D8F
	st_dd8b A, 0x3f
	and_sd8b_im 0x3c, 0xbf	; PF bit 6, (SCLK1 | /CTS1) = 0
	ordi8 0x8D8E, 64
	ldda8 a, 0x8D8E
	st_dd8b A, 0x3e
	ldio 0xd7, 0x28	; Internal Clock T8 (64/fc)
	                 ; Divide by 8
	                 ; fc = 16MHz, so fc/64/8 = 31250
	and_sd8b_im 0xd6, 0xdf	; RXE (bit 5) = 0: CPanel receive disable
	and_sd8b_im 0xd5, 0xfe
	ldio 0xe3, 0x07
	ldio 0xf8, 0x12	; INTA Pin
	ldio 0xf8, 0x23	; INTTX1: Serial send 1
	ldio 0xeb, 0xd0
	st_dd8b A, 0xd4

PollLoop_Return:
	ei 0
	ret


PollLoop_BusyRetry:
	incdi8 1, 0x8D98
	cpdi8 0x8D98, 20
	jr ule, PollLoop_Return

	ei 6
	ldio 0xf8, 0x22	; INTRX1: Serial receive 1
	ldio 0xf8, 0x23	; INTTX1: Serial send 1
	ldio 0xeb, 0xdd
	ldio 0xf8, 0x12	; INTA Pin
	ldio 0xe3, 0x05
	ordi8 0x8D92, 128	; CP_Flags_B.7 = 1
	jr PollLoop_Return




CPanel_RX_ProcessWithFlag:
	ordi8 0x8D8C, 4	; CP_Flags_A.2 = 1  ; UNUSED?
	jr CPanel_RX_DispatchLoop

CPanel_RX_Process:
	anddi8 0x8D8C, 251	; CP_Flags_A.2 = 0  ; UNUSED?

CPanel_RX_DispatchLoop:
	ld xde, 0x8da1
	ldda16 xiy, 0x8D9D
	ld xiz, 0x200ad
	ld ix, (xiz - 4)

CPanel_RX_ParseNext:
	cpw (xiz - 2), 0x4
	jrl c, CPanel_RX_Done

	ldda16 xwa, 0x8D9F
	subda16 xwa, 0x8D9D
	jr nc, CPanel_RX_PacketSizeCheck
	neg wa
	ex8 a, w
	ldb a, 0x5c
	sub a, w

CPanel_RX_PacketSizeCheck:
	cps a, 2
	jrl c, CPanel_RX_Done

	ld_srib3 L, 0x07, 0xe8, 0xf4
	and l, 0x38
	srl l, 1
	xor h, h
	extz xhl
	add xhl, CPanel_RX_PacketHandlers
	ld xhl, (xhl)
	jp (xhl)

CPanel_RX_PacketHandlers_Padding:
	.byte 0xff, 0xff

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
	ld_srib3 W, 0x07, 0xe8, 0xf4
	calr CPanel_IncRXPtr
	lda_dri3 XWA, 0x07, 0xf8, 0xf0
	calr CPanel_IncEventPtr
	stda8 0x8D94, w

	ld_srib3 A, 0x07, 0xe8, 0xf4
	calr CPanel_IncRXPtr
	lda_dri3 XBC, 0x07, 0xf8, 0xf0
	calr CPanel_IncEventPtr
	stda8 0x8D95, a

	and w, 0x4f
	ld xhl, 0x8e4a
	bit 6, w
	jr z, BtnPkt_AddOffset
	sub w, 0x30

BtnPkt_AddOffset:
	add l, w
	jr nc, BtnPkt_XORLookup
	inc 1, h

BtnPkt_XORLookup:
	mrib2 0x83, 0x31
	xor a, (xhl)

	lda_dri3 XBC, 0x07, 0xf8, 0xf0
	calr CPanel_IncEventPtr

	stda8 0x8D96, a
	ld (xiz - 4), ix
	decm 3, (xiz - 2)
	stda16 0x8D9D, xiy
	jrl CPanel_RX_ParseNext

CPanel_RX_EncoderPacket:
	ld_srib3 W, 0x07, 0xe8, 0xf4
	calr CPanel_IncRXPtr
	lda_dri3 XWA, 0x07, 0xf8, 0xf0
	calr CPanel_IncEventPtr
	stda8 0x8D94, w
	ld_srib3 A, 0x07, 0xe8, 0xf4
	calr CPanel_IncRXPtr
	stda8 0x8D95, a
	ld c, w
	calr EncPkt_DispatchThunk
	cp hl, 0xffff
	jr nz, EncPkt_WriteEvent
	calr CPanel_DecEventPtr
	stda16 0x8D9D, xiy
	jr EncPkt_ParseNext

EncPkt_WriteEvent:
	lda_dri3 XSP, 0x07, 0xf8, 0xf0
	calr CPanel_IncEventPtr
	stda8 0x8D96, l
	stib_dri 0x07, 0xf8, 0xf0, 0xff
	calr CPanel_IncEventPtr
	ld (xiz - 4), ix
	decm 3, (xiz - 2)
	stda16 0x8D9D, xiy

EncPkt_ParseNext:
	jrl CPanel_RX_ParseNext

EncPkt_DispatchThunk:
	push xde
	push xiz
	push xix
	calr CPanel_EncoderDispatch
	pop xix
	pop xiz
	pop xde
	ret

CPanel_RX_MultiBytePacket:
	ld w, a
	ld_srib3 A, 0x07, 0xe8, 0xf4
	ld c, a
	and a, 0xf
	inc 1, a
	ld b, a
	add a, 0x2
	cp w, a
	jrl c, CPanel_RX_Done

	calr CPanel_IncRXPtr
	ld_srib3 A, 0x07, 0xe8, 0xf4
	calr CPanel_IncRXPtr
	and a, 0x1f
	and c, 0xc0
	or c, a
	ld w, c
	bit 4, w
	jr nz, MBytePkt_LoopBody
	and c, 0x40
	bit 6, c
	jr z, MBytePkt_AdjustAddr
	sub c, 0x30

MBytePkt_AdjustAddr:
	or a, c
	ld l, a
	extz hl
	extz xhl
	add xhl, 0x8e4a

MBytePkt_LoopBody:
	lda_dri3 XWA, 0x07, 0xf8, 0xf0
	calr CPanel_IncEventPtr
	ld_srib3 A, 0x07, 0xe8, 0xf4
	calr CPanel_IncRXPtr
	bit 4, w
	jr z, MBytePkt_WriteEventByte
	pushw bc
	ld c, w
	pushw hl
	pushw wa
	calr EncPkt_DispatchThunk
	popw wa
	cp hl, 0xffff
	stda8 0x8D96, l
	popw hl
	popw bc
	jr nz, MBytePkt_EncWriteResult
	jr MBytePkt_EncNoEvent

MBytePkt_EncNoEvent:
	calr CPanel_DecEventPtr
	stda16 0x8D9D, xiy
	jrl MBytePkt_LoopTail

MBytePkt_EncWriteResult:
	ldda8 a, 0x8D96
MBytePkt_WriteEventByte:

c:
	lda_dri3 XBC, 0x07, 0xf8, 0xf0
	calr CPanel_IncEventPtr
	bit 4, w
	jr nz, MBytePkt_EncFFMarker
	mrib2 0x83, 0x31
	xor a, (xhl)
	inc 1, hl
	bitda 4, 0x8D8C	; This is never set ?!
	jr z, MBytePkt_CommitAndContinue
	cps a, 0
	jr nz, MBytePkt_CommitAndContinue
					; if CP_Flags_A.4 != 0 && A == 0:
	calr CPanel_DecEventPtr
	calr CPanel_DecEventPtr
	jr MBytePkt_CommitRXPtr

MBytePkt_EncFFMarker:
	ldb a, 0xff

					; else:
MBytePkt_CommitAndContinue:
	lda_dri3 XBC, 0x07, 0xf8, 0xf0
	calr CPanel_IncEventPtr
	ld (xiz - 4), ix
	decm 1, (xiz - 2)
	decm 1, (xiz - 2)
	decm 1, (xiz - 2)

MBytePkt_CommitRXPtr:
	stda16 0x8D9D, xiy

MBytePkt_LoopTail:
	inc 1, w
	dec 1, b
	cps b, 0
	jrl nz, MBytePkt_LoopBody
	jrl CPanel_RX_ParseNext

CPanel_RX_SyncPacket:
	ld_srib3 A, 0x07, 0xe8, 0xf4
	calr CPanel_IncRXPtr
	ld_srib3 A, 0x07, 0xe8, 0xf4
	calr CPanel_IncRXPtr
	stda16 0x8D9D, xiy
	ordi8 0x8D92, 8	; CP_Flags_B.3 = 1  ; UNUSED
	jrl CPanel_RX_ParseNext

CPanel_RX_Done:
	ret


CPanel_UpdateLEDs:	; do this
	ldda16 xiy, 0x8DFF
	ld xde, 0x8e01
	ld xiz, 0x20137
	ld ix, (xiz - 8)

CPanel_UpdateLEDs__check_next:
	ld wa, (xiz - 4)
	cp wa, (xiz - 8)
	jr nz, LEDs_CheckTXSpace
	cpw (xiz - 2), 0x0
	jrl nz, LEDs_Return

LEDs_CheckTXSpace:
	ldda16 xwa, 0x8DFF
	subda16 xwa, 0x8DFD
	jr nc, LEDs_TXForwardDist
	neg wa
	ld hl, wa
	jr LEDs_TXCheckThreshold

LEDs_TXForwardDist:
	ldw hl, 0x3c
	sub hl, wa

LEDs_TXCheckThreshold:
	cps hl, 3
	jrl c, LEDs_Return
	ld_srib3 A, 0x07, 0xf8, 0xf0
	and a, 0x30
	srl a, 2
	ld l, a
	xor h, h
	extz xhl
	add xhl, CPanel_LED_PacketHandlers
	ld xhl, (xhl)
	jp (xhl)

CPanel_LED_PacketHandlers_Padding:
	.byte 0xff, 0xff


CPanel_LED_PacketHandlers:
	.long CPanel_LED_HandlePacket2
	.long CPanel_LED_HandlePacket2
	.long CPanel_LED_HandlePacket2
	.long CPanel_LED_HandlePacketN


CPanel_LED_HandlePacket2:	; FC4B95 -- LED handler for packet types 0, 1, 2
	; Transfers 2 bytes from LED event queue to LED TX buffer.
	; Event byte 1 = row select, event byte 2 = LED pattern.
	ld_srib3 A, 0x07, 0xf8, 0xf0	; A = event queue byte 1 at (XIZ + IX)
	calr ToneGen_IncrementWrap128		; process byte + increment event read ptr
	lda_dri3 XBC, 0x07, 0xe8, 0xf4	; LED buffer op at (XDE + IY)
	calr CPanel_IncLEDPtr		; increment LED write ptr (IY)
	ld_srib3 W, 0x07, 0xf8, 0xf0	; W = event queue byte 2 at (XIZ + IX)
	calr ToneGen_IncrementWrap128		; process byte + increment event read ptr
	lda_dri3 XWA, 0x07, 0xe8, 0xf4	; LED buffer op at (XDE + IY)
	calr CPanel_IncLEDPtr		; increment LED write ptr (IY)
	ld_dst16_rid8 XIZ, -8, IX	; LD (XIZ-8), IX -- store updated event read ptr
	incm 1, (xiz - 2)		; increment pending LED byte count
	incm 1, (xiz - 2)		; increment pending LED byte count (+2 total)
	stda16 0x8DFF, iy		; store LED write ptr to CPANEL_LED_WRITE_PTR
	jrl CPanel_UpdateLEDs__check_next	; check for more events

CPanel_LED_HandlePacketN:	; FC4BC5 -- LED handler for packet type 3
	; Transfers variable-length data from LED event queue to LED TX buffer.
	; Event byte 1 encodes: upper bits = row/command, lower nibble = data count.
	; Total bytes transferred = (byte1 & 0x0f) + 2 (including the header bytes).
	ld_srib3 A, 0x07, 0xf8, 0xf0	; A = event queue byte 1 at (XIZ + IX)
	calr ToneGen_IncrementWrap128		; process byte + increment event read ptr
	ld c, a				; C = save event byte 1
	and a, 0x0f			; A = lower nibble (data byte count)
	add a, 2			; A = total byte count (nibble + 2)
	ld b, a				; B = loop counter
	ld a, c				; A = restore event byte 1
	lda_dri3 XBC, 0x07, 0xe8, 0xf4	; LED buffer op at (XDE + IY)
	calr CPanel_IncLEDPtr		; increment LED write ptr (IY)
	incm 1, (xiz - 2)		; increment pending LED byte count

CPanel_LED_HandlePacketN__loop:	; FC4BE4 -- loop: transfer remaining bytes
	ld_srib3 A, 0x07, 0xf8, 0xf0	; A = next event queue byte at (XIZ + IX)
	calr ToneGen_IncrementWrap128		; process byte + increment event read ptr
	lda_dri3 XBC, 0x07, 0xe8, 0xf4	; LED buffer op at (XDE + IY)
	calr CPanel_IncLEDPtr		; increment LED write ptr (IY)
	ld_dst16_rid8 XIZ, -8, IX	; LD (XIZ-8), IX -- store updated event read ptr
	incm 1, (xiz - 2)		; increment pending LED byte count
	stda16 0x8DFF, iy		; store LED write ptr to CPANEL_LED_WRITE_PTR
	dec 1, b			; decrement loop counter
	cps b, 0			; check if counter reached zero
	jr nz, CPanel_LED_HandlePacketN__loop	; continue loop if bytes remain
	jrl CPanel_UpdateLEDs__check_next	; done, check for more events

LEDs_Return:
	ret


CPanel_IncRXPtr:
	inc 1, iy
	cp iy, 0x5c
	jr c, IncRX_NoWrap
	lds iy, 0

IncRX_NoWrap:
	ret


CPanel_IncLEDPtr:
	inc 1, iy
	cp iy, 0x3c
	jr c, IncLED_NoWrap
	lds iy, 0

IncLED_NoWrap:
	ret


CPanel_IncEventPtr:
	inc 1, ix
	cp ix, 0x80
	jr c, IncEvt_NoWrap
	lds ix, 0

IncEvt_NoWrap:
	ret


CPanel_DecEventPtr:
	cps ix, 0
	jr nz, DecEvt_NoWrap
	ldw ix, 0x7f
	ret

DecEvt_NoWrap:
	dec 1, ix
	ret

; End of control panel routines
