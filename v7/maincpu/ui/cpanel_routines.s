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
	ld xhl, CPANEL_RX_EVENT_QUEUE
	ldw (xhl-4), 0
	ldw (xhl-8), 0
	ldw (xhl-2), 128
	ld xhl, CPANEL_LED_EVENT_QUEUE
	ldw (xhl-4), 0
	ldw (xhl-8), 0
	ldw (xhl-2), 128
	ld a, 3:opc
	and a, 175
	stb_d8 (PFFC_VALUE), a
	ld	(0x3f:8), a
	ld a, 21:opc
	and a, 143
	stb_d8 (PFCR_VALUE), a
	ld	(0x3e:8), a
	and	(0x3c:8), 0xbf
	ld a, 0:opc
	ld	(0x3b:8), a
	ld a, 70:opc
	ld	(0x3a:8), a
	ld (214:8), 0:io
	ld (215:8), 20:io
	ld (213:8), 1:io
	ld (227:8), 7:io
	ld (248:8), 18:io
	ld (235:8), 255:io
	ld (248:8), 34:io
	ld (248:8), 35:io
	or	(0xc8:8), 0x10
	and	(0xc8:8), 0xf7
	ld (CPANEL_UNUSED_1:16), 125
	or (CPANEL_TX_RX_FLAGS:16), 64
	ld (CPANEL_PACKET_BYTE_COUNT:16), 0
	and (CPANEL_TX_RX_FLAGS:16), 252
	ldw (CPANEL_LED_READ_PTR:16), 0
	ldw (CPANEL_LED_WRITE_PTR:16), 0
	ldw (CPANEL_RX_READ_PTR:16), 0
	ldw (CPANEL_RX_WRITE_PTR:16), 0
	calr DELAY_6_TICKS
	ld a, 31:opc
	ld w, 218:opc
	calr CPanel_SendCommand
	calr DELAY_3000_LOOPS
	ldw (CPANEL_LED_READ_PTR:16), 0
	calr DELAY_3000_LOOPS
	calr CPanel_SendInitSequence
	ret
CPanel_SendInitSequence:
	ld a, 31:opc
	ld w, 26:opc
	calr CPanel_SendCommand
	calr DELAY_3000_LOOPS
	ldw (CPANEL_LED_READ_PTR:16), 0
	calr DELAY_3000_LOOPS
	ld a, 29:opc
	ld w, 0:opc
	calr CPanel_SendCommand
	calr DELAY_3000_LOOPS
	ldw (CPANEL_LED_READ_PTR:16), 0
	calr DELAY_3000_LOOPS
	calr DELAY_3000_LOOPS
	ld a, 221:opc
	ld w, 3:opc
	calr CPanel_SendCommand
	calr DELAY_3000_LOOPS
	ldw (CPANEL_LED_READ_PTR:16), 0
	calr DELAY_3000_LOOPS
	calr DELAY_3000_LOOPS
	ld a, 30:opc
	ld w, 128:opc
	calr CPanel_SendCommand
	calr DELAY_3000_LOOPS
	calr DELAY_3000_LOOPS
	calr DELAY_3000_LOOPS
	ei 6
	ld (235:8), 255:io
	ld (248:8), 34:io
	ld (248:8), 35:io
	and	(0xd6:8), 0xdf
	ld (248:8), 18:io
	ld (227:8), 5:io
	ldw (CPANEL_RX_READ_PTR:16), 0
	ldw (CPANEL_RX_WRITE_PTR:16), 0
	or (CPANEL_PROTOCOL_FLAGS:16), 1
	ei	0
	ret
CPanel_InitLEDBuffer:
	ld (CPANEL_LED_TX_BUFFER:16), wa
	and (PFFC_VALUE:16), 191
	ldb_d8 a, (PFFC_VALUE)
	ld	(0x3f:8), a
	ld (235:8), 255:io
	ld (248:8), 34:io
	ld (248:8), 35:io
	ld (227:8), 7:io
	ld (248:8), 18:io
	and	(0x3c:8), 0xbf
	or (PFCR_VALUE:16), 64
	ldb_d8 a, (PFCR_VALUE)
	ld	(0x3e:8), a
	calr DELAY_300_LOOPS
	calr DELAY_300_LOOPS
	and (PFCR_VALUE:16), 191
	ldb_d8 a, (PFCR_VALUE)
	ld	(0x3e:8), a
	calr DELAY_300_LOOPS
	calr DELAY_300_LOOPS
	or (PFFC_VALUE:16), 80
	ldb_d8 a, (PFFC_VALUE)
	ld	(0x3f:8), a
	or (PFCR_VALUE:16), 80
	ldb_d8 a, (PFCR_VALUE)
	ld	(0x3e:8), a
	and	(0xd5:8), 0xfe
	ld (235:8), 255:io
	ld (248:8), 34:io
	ld (248:8), 35:io
	ld xiy, CPANEL_LED_TX_BUFFER
	add iy, (CPANEL_LED_READ_PTR:16)
	ld a, (xiy)
	incw 1, (CPANEL_LED_READ_PTR:16)
	ld	(0xd4:8), a
	calr DELAY_300_LOOPS
	calr DELAY_300_LOOPS
	ld xiy, CPANEL_LED_TX_BUFFER
	add iy, (CPANEL_LED_READ_PTR:16)
	ld a, (xiy)
	incw 1, (CPANEL_LED_READ_PTR:16)
	ld	(0xd4:8), a
	calr DELAY_300_LOOPS
	calr DELAY_300_LOOPS
	or	(0xd5:8), 0x01
	and	(0xd5:8), 0xfd
	and (PFCR_VALUE:16), 175
	ldb_d8 a, (PFCR_VALUE)
	ld	(0x3e:8), a
	and (PFFC_VALUE:16), 175
	ldb_d8 a, (PFFC_VALUE)
	ld	(0x3f:8), a
	ret
DELAY_2_LOOPS:
	ld wa, 2:i3

Delay2L_Loop:
	dec 1, wa
	cp wa, 0:i3
	jr z, Delay2L_Done
	jr Delay2L_Loop

Delay2L_Done:
	ret


DELAY_6_LOOPS:
	ld wa, 6:i3

Delay6L_Loop:
	dec 1, wa
	cp wa, 0:i3
	jr z, Delay6L_Done
	jr Delay6L_Loop

Delay6L_Done:
	ret


DELAY_10_LOOPS:
	ldw wa, 0xa

Delay10L_Loop:
	dec 1, wa
	cp wa, 0:i3
	jr z, Delay10L_Done
	jr Delay10L_Loop

Delay10L_Done:
	ret


DELAY_300_LOOPS:
	ldw wa, 0x12c

Delay300L_Loop:
	dec 1, wa
	cp wa, 0:i3
	jr z, Delay300L_Done
	jr Delay300L_Loop

Delay300L_Done:
	ret


DELAY_1500_LOOPS:
	ldw wa, 0x5dc

Delay1500L_Loop:
	dec 1, wa
	cp wa, 0:i3
	jr z, Delay1500L_Done
	jr Delay1500L_Loop

Delay1500L_Done:
	ret


DELAY_3000_LOOPS:
	ldw wa, 0xbb8

Delay3000L_Loop:
	dec 1, wa
	cp wa, 0:i3
	jr z, Delay3000L_Done
	jr Delay3000L_Loop

Delay3000L_Done:
	ret


DELAY_2_TICKS:
	ld	wa, (SYSTEM_TIMESTAMP:16)
	ld	(TIMESTAMP_FOR_DELAY:16), wa
DELAY_2_TICKS__loop:
	ldw_d16 wa, (SYSTEM_TIMESTAMP)
	sub wa, (TIMESTAMP_FOR_DELAY:16)
	cp wa, 2:i3
	jr lt, DELAY_2_TICKS__loop
	ret
DELAY_6_TICKS:
	ld	wa, (SYSTEM_TIMESTAMP:16)
	ld	(TIMESTAMP_FOR_DELAY:16), wa
Delay6T_Loop:
	ldw_d16 wa, (SYSTEM_TIMESTAMP)
	sub wa, (TIMESTAMP_FOR_DELAY:16)
	cp wa, 6:i3
	jr lt, Delay6T_Loop
	ret
DELAY_51_TICKS:
	ld	wa, (SYSTEM_TIMESTAMP:16)
	ld	(TIMESTAMP_FOR_DELAY:16), wa
Delay51T_Loop:
	ldw_d16 wa, (SYSTEM_TIMESTAMP)
	sub wa, (TIMESTAMP_FOR_DELAY:16)
	cp wa, 51
	jr lt, Delay51T_Loop
	ret
CPanel_CheckSpecialCombos:
	cp (0x8dc2:16), 0x6c
	jr nz, .Lc_fc39a5
	ld hl, 3:i3
	jr t, CPanel_CheckSpecialCombos_Return
CPanel_Combo_CheckAllInitSetting:
.Lc_fc39a5:
	cp (0x8daf:16), 0x70
	jr nz, .Lc_fc39b0
	ld hl, 2:i3
	jr t, CPanel_CheckSpecialCombos_Return
CPanel_Combo_CheckFactoryReset:
.Lc_fc39b0:
	cp (0x8dc4:16), 0x38
	jr nz, .Lc_fc39bb
	ld hl, 1:i3
	jr t, CPanel_CheckSpecialCombos_Return
CPanel_Combo_CheckFlashUpdate:
.Lc_fc39bb:
	cp (0x8db4:16), 0x0f
	jr nz, CPanel_Combo_NormalBoot
	ld hl, 4:i3
	jr t, CPanel_CheckSpecialCombos_Return
CPanel_Combo_NormalBoot:
	ld hl, 0:i3		; No combo: normal boot

CPanel_CheckSpecialCombos_Return:
	ret


CPanel_PanelDetection:
	ld (CPANEL_PANEL_DETECT_FLAGS:16), 0x00
	calr CPanel_WaitTXReady
	ei 0x06
	ldw (CPANEL_RX_READ_PTR:16), 0x0000
	ldw (CPANEL_RX_WRITE_PTR:16), 0x0000
	or (CPANEL_PROTOCOL_FLAGS:16), 0x01
	ei 0x00
	ld A, 0x20:opc
	ld W, 0x00:opc
	calr CPanel_SendCommand
	calr DELAY_6_TICKS
	cpw (CPANEL_RX_WRITE_PTR:16), 0x0000
	jr z, .Lc_fc39fd
	or (CPANEL_PANEL_DETECT_FLAGS:16), 0x01
PanelDet_ProbeRight:
.Lc_fc39fd:
	calr CPanel_WaitTXReady
	ei 0x06
	ldw (CPANEL_RX_READ_PTR:16), 0x0000
	ldw (CPANEL_RX_WRITE_PTR:16), 0x0000
	or (CPANEL_PROTOCOL_FLAGS:16), 0x01
	ei 0x00
	ld A, 0xe0:opc
	ld W, 0x00:opc
	calr CPanel_SendCommand
	calr DELAY_6_TICKS
	cpw (CPANEL_RX_WRITE_PTR:16), 0x0000
	jr z, PanelDet_Return
	or (CPANEL_PANEL_DETECT_FLAGS:16), 0x08
PanelDet_Return:
	ld	a, (CPANEL_PANEL_DETECT_FLAGS:16)
	ret
CPanel_ReadAllButtons:
	ld xhl, CPANEL_RX_EVENT_QUEUE
	ldw (xhl-4), 0
	ldw (xhl-8), 0
	ldw (xhl-2), 128
	ei 6
	ldw_d16 wa, (CPANEL_RX_READ_PTR)
	ld (CPANEL_RX_WRITE_PTR:16), wa
	or (CPANEL_PROTOCOL_FLAGS:16), 1
	ei	0
	call CPanel_WaitTXReady
	ld a, 37:opc
	ld w, 1:opc
	call CPanel_SendCommand
	calr DELAY_6_TICKS
	calr DELAY_6_TICKS
	calr DELAY_6_TICKS
	calr CPanel_WaitTXReady
	ld a, 226:opc
	ld w, 4:opc
	calr CPanel_SendCommand
	calr DELAY_6_TICKS
	calr DELAY_6_TICKS
	calr CPanel_WaitTXReady
	ld a, 32:opc
	ld w, 16:opc
	calr CPanel_SendCommand
	calr DELAY_6_TICKS
	calr DELAY_6_TICKS
	calr CPanel_WaitTXReady
	ld a, 226:opc
	ld w, 17:opc
	calr CPanel_SendCommand
	calr DELAY_6_TICKS
	calr DELAY_6_TICKS
	calr CPanel_RX_Process
	ret
CPanel_PollStartup:
	ld xhl, CPANEL_RX_EVENT_QUEUE

	ldw (xhl - 4), 0x0

	ldw (xhl - 8), 0x0

	ldw (xhl - 2), 0x80

	ei 6

	ldw	(CPANEL_RX_READ_PTR:16), 0	; stdi16 (0x8d9d), 0 (v7 patched)

	ldw	(CPANEL_RX_WRITE_PTR:16), 0	; stdi16 (0x8d9f), 0 (v7 patched)

	or	(CPANEL_PROTOCOL_FLAGS:16), 1	; ordi8 0x8d92, 1	; CP_Flags_B.0 = 1 (v7 patched)

	ei 0



CPanel_ButtonPollLoop:
	calr	CPanel_WaitTXReady
	ld	a, 32:opc
	ld	w, 11:opc
	calr	CPanel_SendCommand
	calr	DELAY_6_TICKS
	calr	CPanel_RX_Process
	ld	a, (36281:16)
	ld	w, 13:opc
	bit	7, a
	jr	nz, CPanel_EncoderCheck
	ld	w, 14:opc
	bit	6, a
	jr	nz, CPanel_EncoderCheck
	ld	w, 12:opc
CPanel_EncoderCheck:
	cp (36302:16), w
	stb_d8 (36302), w
	jr nz, CPanel_ButtonPollLoop
	stb_d8 (36302), w
	ld xhl, CPANEL_RX_EVENT_QUEUE
	ldw (xhl-4), 0
	ldw (xhl-8), 0
	ldw (xhl-2), 128
	ei 6
	ldw (CPANEL_LED_READ_PTR:16), 0
	ldw (CPANEL_LED_WRITE_PTR:16), 0
	ldw (CPANEL_RX_READ_PTR:16), 0
	ldw (CPANEL_RX_WRITE_PTR:16), 0
	or (CPANEL_PROTOCOL_FLAGS:16), 1
	ei	0
	ret
CPanel_InitButtonState:
	ld xhl, CPANEL_RX_EVENT_QUEUE
	ldw (xhl-4), 0
	ldw (xhl-8), 0
	ldw (xhl-2), 128
	ei 6
	ld (CPANEL_RX_READ_PTR:16), 0
	ld (CPANEL_RX_WRITE_PTR:16), 0
	or (CPANEL_PROTOCOL_FLAGS:16), 1
	ei	0
	calr CPanel_WaitTXReady
	ld a, 43:opc
	ld w, 0:opc
	calr CPanel_SendCommand
	calr DELAY_6_TICKS
	calr DELAY_6_TICKS
	calr DELAY_6_TICKS
	calr CPanel_RX_ProcessWithFlag
	calr CPanel_WaitTXReady
	ld a, 235:opc
	ld w, 0:opc
	calr CPanel_SendCommand
	calr DELAY_6_TICKS
	calr DELAY_6_TICKS
	calr DELAY_6_TICKS
	calr CPanel_RX_ProcessWithFlag
	calr CPanel_WaitTXReady
	ld a, 32:opc
	ld w, 16:opc
	calr CPanel_SendCommand
	calr DELAY_6_TICKS
	calr DELAY_6_TICKS
	calr CPanel_RX_ProcessWithFlag
	calr CPanel_WaitTXReady
	ld a, 227:opc
	ld w, 16:opc
	calr CPanel_SendCommand
	calr DELAY_6_TICKS
	calr DELAY_6_TICKS
	calr CPanel_RX_ProcessWithFlag
	ret
CPanel_WaitTXReady:
	ld	(CPANEL_COUNTER_DOWN_FROM_200:16), 200
CPanel_WaitTXReady_Poll:
	ei 6
	bit	6, (0x3c:8)
	jr z, CPanel_WaitTXReady_Timeout
	bit	5, (0x38:8)
	jr nz, CPanel_WaitTXReady_Timeout
	bit 1, (CPANEL_TX_RX_FLAGS:16)
	jr nz, CPanel_WaitTXReady_Timeout
	bit 0, (CPANEL_TX_RX_FLAGS:16)
	jr nz, CPanel_WaitTXReady_Timeout
	jr CPanel_WaitTXReady_BufferCheck
CPanel_WaitTXReady_Timeout:
	dec 1, (CPANEL_COUNTER_DOWN_FROM_200:16)
	cp (CPANEL_COUNTER_DOWN_FROM_200:16), 0
	jr z, WaitTX_ConfigAndReturn
	ei	0
	calr DELAY_1500_LOOPS
	jr CPanel_WaitTXReady_Poll
CPanel_WaitTXReady_BufferCheck:
	ldw_d16 wa, (CPANEL_LED_WRITE_PTR)
	cp wa, (CPANEL_LED_READ_PTR:16)
	jr nz, CPanel_WaitTXReady_Timeout
WaitTX_ConfigAndReturn:
	ei 6

	ld	(0xf8:8), 0x22:io	; INTRX1: Serial receive 1

	ld	(0xf8:8), 0x23:io	; INTTX1: Serial send 1

	ld (0xeb:8), 0xdd:io

	and	(0xd6:8), 0xdf	; RXE (bit 5) = 0: receive disable

	or	(CPANEL_PROTOCOL_FLAGS:16), 128	; ordi8 0x8d92, 128	; CP_Flags_B.7 = 1 (v7 patched)

	ei 0

	ret





CPanel_SendCommand:
	ei 0x06
	ldw (CPANEL_LED_READ_PTR:16), 0x0000
	ldw (CPANEL_LED_WRITE_PTR:16), 0x0000
	ld (CPANEL_LED_TX_BUFFER:16), wa
	addw (CPANEL_LED_WRITE_PTR:16), 0x0002
	or (CPANEL_TX_RX_FLAGS:16), 0x02
	and (CPANEL_TX_RX_FLAGS:16), 0xfe
	ld (CPANEL_STATE_MACHINE_INDEX:16), 0x04
	ld (215:8), 40:io
	and (PFFC_VALUE:16), 191
	ldb_d8 a, (PFFC_VALUE)
	ld	(0x3f:8), a
	and	(0x3c:8), 0xbf
	or (PFCR_VALUE:16), 64
	ldb_d8 a, (PFCR_VALUE)
	ld	(0x3e:8), a
	ld (227:8), 7:io
	ld (248:8), 18:io
	and	(0xd6:8), 0xdf
	and	(0xd5:8), 0xfe
	ld (248:8), 35:io
	ld (235:8), 223:io
	ld (248:8), 34:io
	ld	(0xd4:8), a
	ei	0
	nop
	ret
INTA_HANDLER:
	ld (CPANEL_COUNTER_UP_TO_20:16), 0
	push xwa
	cp (CPANEL_PACKET_BYTE_COUNT:16), 0
	jr nz, INTA_HandleCountdown
	and (PFCR_VALUE:16), 159
	ldb_d8 a, (PFCR_VALUE)
	ld	(0x3e:8), a
	or	(0xd5:8), 0x01
	and	(0xd5:8), 0xfd
	ld (227:8), 5:io
	ld (235:8), 13:io
	or	(0xd6:8), 0x20
	ld (CPANEL_STATE_MACHINE_INDEX:16), 32
	or (CPANEL_TX_RX_FLAGS:16), 1
	jr 28
INTA_HandleCountdown:
	cpw (CPANEL_RX_WRITE_PTR:16), 0
	jr nz, 6
	ldw (CPANEL_RX_WRITE_PTR:16), 92
INTA_DecrementRXCount:
	decw	1, (CPANEL_RX_WRITE_PTR:16)	; decdi16 1, 0x8d9f (v7 patched)

	or	(CPANEL_PROTOCOL_FLAGS:16), 64	; ordi8 0x8d92, 64	; CP_Flags_B.6 = 1  ; UNUSED (v7 patched)

	and	(CPANEL_TX_RX_FLAGS:16), 253	; anddi8 (0x8d8c), 253; CP_Flags_A.1 = 0 (v7 patched)



INTA_HANDLER_END:
	pop xwa
	ld	(0xf8:8), 0x12:io	; INTA Pin
	ld	(0xf8:8), 0x22:io	; INTRX1: Serial receive 1
	ld	(0xf8:8), 0x23:io	; INTTX1: Serial send 1
	reti


; 11 routine pointers, one per state of the control-panel serial link.  INTTX1_HANDLER and
; INTRX1_HANDLER both run `ld l,(0x8CEE); xor h,h; extz xhl; add xhl,<this>; ld xhl,(xhl);
; jp (xhl)`: the state byte at RAM 0x8CEE is the byte offset (0, 4, ... 40).
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
	push	xwa
	push	xhl
	push	xiy
	ld	l, (CPANEL_STATE_MACHINE_INDEX:16)
	xor	h, h
	extz	xhl
	add	xhl, CPANEL_STATE_MACHINE_TABLE
	ld	xhl, (xhl)
	jp	(xhl)
MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES:
	pop xiy
	pop xhl
	pop xwa
	ld	(0xf8:8), 0x12:io	; INTA Pin
	ld	(0xf8:8), 0x22:io	; INTRX1: Serial receive 1
	ld	(0xf8:8), 0x23:io	; INTTX1: Serial send 1
	reti


INTRX1_HANDLER:
	push	xwa
	push	xhl
	push	xiy
	ld	l, (CPANEL_STATE_MACHINE_INDEX:16)
	xor	h, h
	extz	xhl
	add	xhl, CPANEL_STATE_MACHINE_TABLE
	ld	xhl, (xhl)
	jp	(xhl)
LEAST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES:
	pop xiy
	pop xhl
	pop xwa
	ld	(0xf8:8), 0x12:io	; INTA Pin
	ld	(0xf8:8), 0x22:io	; INTRX1: Serial receive 1
	ld	(0xf8:8), 0x23:io	; INTTX1: Serial send 1
	reti


CPanel_SM_StartTX:
	and (PFCR_VALUE:16), 191
	ldb_d8 a, (PFCR_VALUE)
	ld	(0x3e:8), a
	ld (215:8), 36:io
	ld (227:8), 7:io
	ld (235:8), 208:io
	and	(0xd5:8), 0xfe
	ld	(0xd4:8), a
	inc 4, (CPANEL_STATE_MACHINE_INDEX:16)
	mul a, 1
	mul a, 1
	bit	6, (0x3c:8)
	jr nz, MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES
	ld (CPANEL_PACKET_BYTE_COUNT:16), 0
	ld (CPANEL_STATE_MACHINE_INDEX:16), 0
	or (CPANEL_PROTOCOL_FLAGS:16), 2
	ld (227:8), 5:io
	ld (235:8), 255:io
	ld (215:8), 36:io
	and (CPANEL_TX_RX_FLAGS:16), 253
	jrl MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES
CPanel_SM_TXDelay1:
	calr DELAY_10_LOOPS
	and (PFCR_VALUE:16), 175
	ldb_d8 a, (PFCR_VALUE)
	ld	(0x3e:8), a
	and (PFFC_VALUE:16), 175
	ldb_d8 a, (PFFC_VALUE)
	ld	(0x3f:8), a
	ld (215:8), 36:io
	ld (235:8), 208:io
	and	(0xd5:8), 0xfe
	ld	(0xd4:8), a
	inc 4, (CPANEL_STATE_MACHINE_INDEX:16)
	jrl MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES
CPanel_SM_TXDelay2:
	calr DELAY_10_LOOPS
	and (PFCR_VALUE:16), 175
	ldb_d8 a, (PFCR_VALUE)
	ld	(0x3e:8), a
	and (PFFC_VALUE:16), 175
	ldb_d8 a, (PFFC_VALUE)
	ld	(0x3f:8), a
	ld (215:8), 36:io
	ld	(0xd4:8), a
	ld (227:8), 5:io
	ld (235:8), 208:io
	and	(0xd5:8), 0xfe
	ld	(0xd4:8), a
	inc 4, (CPANEL_STATE_MACHINE_INDEX:16)
	jrl MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES
CPanel_SM_SendByte1:
	ld (215:8), 20:io
	or (PFFC_VALUE:16), 80
	ldb_d8 a, (PFFC_VALUE)
	ld	(0x3f:8), a
	or (PFCR_VALUE:16), 80
	ldb_d8 a, (PFCR_VALUE)
	ld	(0x3e:8), a
	and	(0xd5:8), 0xfe
	ld (227:8), 5:io
	ld (235:8), 208:io
	ld xiy, CPANEL_LED_TX_BUFFER
	add iy, (CPANEL_LED_READ_PTR:16)
	ld a, (xiy)
	ld	(0xd4:8), a
	incw 1, (CPANEL_LED_READ_PTR:16)
	cpw (CPANEL_LED_READ_PTR:16), 60
	jr c, SendByte1_InspectByte
	ldw (CPANEL_LED_READ_PTR:16), 0
SendByte1_InspectByte:
	ld	(CPANEL_PACKET_BYTE_COUNT:16), 2
	ld	a, (xiy)
	and	a, 63
	cp	a, 48
	jr	c, SendByte1_AdvanceState
	and	a, 15
	add	a, 3
	ld	(CPANEL_PACKET_BYTE_COUNT:16), a
SendByte1_AdvanceState:
	inc	4, (CPANEL_STATE_MACHINE_INDEX:16)
	jrl	MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES
CPanel_SM_SendByteN:
	ld (215:8), 20:io
	or (PFFC_VALUE:16), 80
	ldb_d8 a, (PFFC_VALUE)
	ld	(0x3f:8), a
	or (PFCR_VALUE:16), 80
	ldb_d8 a, (PFCR_VALUE)
	ld	(0x3e:8), a
	and	(0xd5:8), 0xfe
	ld (227:8), 5:io
	ld (235:8), 208:io
	ld xiy, CPANEL_LED_TX_BUFFER
	add iy, (CPANEL_LED_READ_PTR:16)
	ld a, (xiy)
	ld	(0xd4:8), a
	incw 1, (CPANEL_LED_READ_PTR:16)
	cpw (CPANEL_LED_READ_PTR:16), 60
	jr c, SendByteN_CheckDone
	ldw (CPANEL_LED_READ_PTR:16), 0
SendByteN_CheckDone:
	dec 1, (CPANEL_PACKET_BYTE_COUNT:16)
	cp (CPANEL_PACKET_BYTE_COUNT:16), 1
	jr z, SendByteN_AdvanceState
	cp (CPANEL_PACKET_BYTE_COUNT:16), 0
	jr z, SendByteN_AdvanceState
	dec 4, (CPANEL_STATE_MACHINE_INDEX:16)
	jrl MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES
SendByteN_AdvanceState:
	inc	4, (CPANEL_STATE_MACHINE_INDEX:16)
	jrl	MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES
CPanel_SM_TXComplete:
	ld (CPANEL_PACKET_BYTE_COUNT:16), 0
	ld (CPANEL_STATE_MACHINE_INDEX:16), 0
	ldw_d16 wa, (CPANEL_LED_WRITE_PTR)
	sub wa, (CPANEL_LED_READ_PTR:16)
	cp wa, 2:i3
	jr c, TXComplete_BufferEmpty
	ld (CPANEL_STATE_MACHINE_INDEX:16), 4
	and (PFFC_VALUE:16), 191
	ldb_d8 a, (PFFC_VALUE)
	ld	(0x3f:8), a
	and	(0x3c:8), 0xbf
	or (PFCR_VALUE:16), 64
	ldb_d8 a, (PFCR_VALUE)
	ld	(0x3e:8), a
	ld (215:8), 40:io
	ld (227:8), 7:io
	and	(0xd5:8), 0xfe
	ld (235:8), 208:io
	ld	(0xd4:8), a
	or (CPANEL_TX_RX_FLAGS:16), 2
	jrl MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES
TXComplete_BufferEmpty:
	and	(PFCR_VALUE:16), 191	; anddi8 (0x8d8e), 191 (v7 patched)

	ldb_d8	a, (PFCR_VALUE)	; ldb_d8 a, (0x8d8e) (v7 patched)

	ld	(0x3e:8), a

	and	(PFFC_VALUE:16), 191	; anddi8 (0x8d8f), 191; disable CPanel serial clk (v7 patched)

	ldb_d8	a, (PFFC_VALUE)	; ldb_d8 a, (0x8d8f) (v7 patched)

	ld	(0x3f:8), a

	ld (0xe3:8), 0x05:io

	ld	(0xeb:8), 0xff:io	; INTTX1: M=7 | INTRX1: M=7 (meaning: disable int.req.)

	ld	(0xd7:8), 0x24:io	; Internal Clock T8 (64/fc)

	                 ; Divide by 4

	                 ; fc = 16MHz, so fc/64/4 = 62500

	and	(CPANEL_TX_RX_FLAGS:16), 253	; anddi8 (0x8d8c), 253; CP_Flags_A.1 = 0 (v7 patched)

	jrl	MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES	; jrl MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES (v7 displacement)





CPanel_SM_RXByte1:
	and (PFCR_VALUE:16), 159
	ldb_d8 a, (PFCR_VALUE)
	ld	(0x3e:8), a
	or	(0xd5:8), 0x01
	and	(0xd5:8), 0xfd
	ld (227:8), 5:io
	ld (235:8), 13:io
	ld	a, (0xd4:8)
	ld xiy, CPANEL_RX_RING_BUFFER
	add iy, (CPANEL_RX_WRITE_PTR:16)
	ld (xiy), a
	ldw_d16 hl, (CPANEL_RX_WRITE_PTR)
	sub hl, (CPANEL_RX_READ_PTR:16)
	jr nc, RXByte1_ForwardDist
	neg hl
	ld iy, hl
	jr RXByte1_CheckThreshold
RXByte1_ForwardDist:
	ldw iy, 0x5c
	sub iy, hl

RXByte1_CheckThreshold:
	cp iy, 3:i3
	jr nc, RXByte1_AdvanceWritePtr
	or (CPANEL_PROTOCOL_FLAGS:16), 1
	jr RXByte1_InspectByte
RXByte1_AdvanceWritePtr:
	and (CPANEL_PROTOCOL_FLAGS:16), 254
	incw 1, (CPANEL_RX_WRITE_PTR:16)
	cpw (CPANEL_RX_WRITE_PTR:16), 92
	jr c, RXByte1_InspectByte
	ldw (CPANEL_RX_WRITE_PTR:16), 0
RXByte1_InspectByte:
	ld	(CPANEL_PACKET_BYTE_COUNT:16), 2
	and	a, 63
	cp	a, 48
	jr	c, RXByte1_AdvanceState
	and	a, 15
	add	a, 3
	ld	(CPANEL_PACKET_BYTE_COUNT:16), a
RXByte1_AdvanceState:
	inc	4, (CPANEL_STATE_MACHINE_INDEX:16)
	jrl	LEAST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES
CPanel_SM_RXByteN:
	ld	a, (0xd4:8)
	ld xiy, CPANEL_RX_RING_BUFFER
	add iy, (CPANEL_RX_WRITE_PTR:16)
	ld (xiy), a
	bit 0, (CPANEL_PROTOCOL_FLAGS:16)
	jr nz, RXByteN_CheckDone
	incw 1, (CPANEL_RX_WRITE_PTR:16)
	cpw (CPANEL_RX_WRITE_PTR:16), 92
	jr c, RXByteN_CheckDone
	ldw (CPANEL_RX_WRITE_PTR:16), 0
RXByteN_CheckDone:
	dec 1, (CPANEL_PACKET_BYTE_COUNT:16)
	cp (CPANEL_PACKET_BYTE_COUNT:16), 1
	jr nz, RXByteN_ContinueRX
	ld (CPANEL_PACKET_BYTE_COUNT:16), 0
	and (CPANEL_TX_RX_FLAGS:16), 254
	ld (CPANEL_STATE_MACHINE_INDEX:16), 0
	and (PFCR_VALUE:16), 159
	ldb_d8 a, (PFCR_VALUE)
	ld	(0x3e:8), a
	and (PFFC_VALUE:16), 191
	ldb_d8 a, (PFFC_VALUE)
	ld	(0x3f:8), a
	ld (227:8), 5:io
	ld (235:8), 13:io
	and	(0xd6:8), 0xdf
	jrl LEAST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES
RXByteN_ContinueRX:
	and	(PFCR_VALUE:16), 159	; anddi8 (0x8d8e), 159 (v7 patched)

	ldb_d8	a, (PFCR_VALUE)	; ldb_d8 a, (0x8d8e) (v7 patched)

	ld	(0x3e:8), a

	or	(0xd5:8), 0x01

	and	(0xd5:8), 0xfd

	ld (0xe3:8), 0x05:io

	ld (0xeb:8), 0x0d:io

	jrl	-765	; jrl LEAST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES (v7 displacement)





CPanel_SM_Idle:
	or	(CPANEL_PROTOCOL_FLAGS:16), 128	; ordi8 0x8d92, 128	; CP_Flags_B.7 = 1 (v7 patched)

	jrl	-773	; jrl LEAST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES (v7 displacement)



	and	(CPANEL_TX_RX_FLAGS:16), 252	; anddi8 (0x8d8c), 252; CP_Flags_A.0 = 0 (v7 patched)

						; CP_Flags_A.1 = 0

	or	(CPANEL_PROTOCOL_FLAGS:16), 4	; ordi8 0x8d92, 4	; CP_Flags_B.2 = 1  : UNUSED (v7 patched)

	ld	(0xf8:8), 0x23:io	; INTTX1: Serial send 1

	and	(0xd6:8), 0xdf	; RXE (bit 5) = 0: receive disable

	ld (0xeb:8), 0x0f:io

	ld	(0xf8:8), 0x22:io	; INTRX1: Serial receive 1

	ld (0xe3:8), 0x07:io

	ld	(0xf8:8), 0x12:io	; INTA Pin

	reti





CPanel_InterruptPoll_MainLoop:
	inc 1, (CPANEL_COUNTER_UP_TO_42:16)
	cp (CPANEL_COUNTER_UP_TO_42:16), 0x2a
	jr ule, PollLoop_DispatchWork
	ei 0x06
	ld wa, (CPANEL_LED_WRITE_PTR:16)
	sub wa, (CPANEL_LED_READ_PTR:16)
	jr nc, PollLoop_TXForwardDist
	neg wa
	ld hl, wa
	jr PollLoop_TXCheckThreshold
PollLoop_TXForwardDist:
	ldw hl, 0x3c
	sub hl, wa

PollLoop_TXCheckThreshold:
	cp	hl, 3:i3
	jr	c, PollLoop_DispatchWork	; -> 0xFC4090
	ld	(CPANEL_COUNTER_UP_TO_42:16), 0
	ld	w, 224:opc
	ld	a, 19:opc
	ld	iy, (CPANEL_LED_WRITE_PTR:16)
	ld	xde, 36197
	ld	(xde+iy), w
	calr	CPanel_IncLEDPtr
	ld	(xde+iy), a
	calr	CPanel_IncLEDPtr
	ld	(CPANEL_LED_WRITE_PTR:16), iy
PollLoop_DispatchWork:
	ei	0
	ldb_d8 a, (CPANEL_TX_RX_FLAGS)
	and a, 192
	cp a, 0:i3
	jr z, PollLoop_DoLEDUpdate
	add (CPANEL_TX_RX_FLAGS:16), 64
	cp a, 192
	jr nz, PollLoop_DoLEDUpdate
	calr CPanel_InitButtonState
	jr PollLoop_CheckTXReady
PollLoop_DoLEDUpdate:
	calr	CPanel_UpdateLEDs	; do this
				; }
PollLoop_CheckTXReady:
	ei 6
	bit	6, (0x3c:8)
	jr z, PollLoop_BusyRetry
	bit	5, (0x38:8)
	jr nz, PollLoop_BusyRetry
	bit 1, (CPANEL_TX_RX_FLAGS:16)
	jr nz, PollLoop_BusyRetry
	bit 0, (CPANEL_TX_RX_FLAGS:16)
	jr nz, PollLoop_BusyRetry
	ldw_d16 wa, (CPANEL_LED_WRITE_PTR)
	sub wa, (CPANEL_LED_READ_PTR:16)
	jr nc, PollLoop_StartTX
	neg wa
	ex8 a, w
	ld a, 60:opc
	sub a, w
PollLoop_StartTX:
	cp a, 2:i3
	jr c, PollLoop_Return
	or (CPANEL_TX_RX_FLAGS:16), 2
	ld (CPANEL_STATE_MACHINE_INDEX:16), 4
	and (PFFC_VALUE:16), 191
	ldb_d8 a, (PFFC_VALUE)
	ld	(0x3f:8), a
	and	(0x3c:8), 0xbf
	or (PFCR_VALUE:16), 64
	ldb_d8 a, (PFCR_VALUE)
	ld	(0x3e:8), a
	ld (215:8), 40:io
	and	(0xd6:8), 0xdf
	and	(0xd5:8), 0xfe
	ld (227:8), 7:io
	ld (248:8), 18:io
	ld (248:8), 35:io
	ld (235:8), 208:io
	ld	(0xd4:8), a
PollLoop_Return:
	ei 0
	ret


PollLoop_BusyRetry:
	inc 1, (CPANEL_COUNTER_UP_TO_20:16)
	cp (CPANEL_COUNTER_UP_TO_20:16), 20
	jr ule, PollLoop_Return
	ei 6
	ld (248:8), 34:io
	ld (248:8), 35:io
	ld (235:8), 221:io
	ld (248:8), 18:io
	ld (227:8), 5:io
	or (CPANEL_PROTOCOL_FLAGS:16), 128
	jr PollLoop_Return
CPanel_RX_ProcessWithFlag:
	or (CPANEL_TX_RX_FLAGS:16), 0x04
	jr t, CPanel_RX_DispatchLoop
CPanel_RX_Process:
	and (CPANEL_TX_RX_FLAGS:16), 0xfb



CPanel_RX_DispatchLoop:
	ld	xde, 36101
	ld	iy, (CPANEL_RX_READ_PTR:16)
	ld	xiz, CPANEL_RX_EVENT_QUEUE
	ld	ix, (xiz-4)
CPanel_RX_ParseNext:
	cpw (xiz-2), 4
	jrl c, CPanel_RX_Done
	ldw_d16 wa, (CPANEL_RX_WRITE_PTR)
	sub wa, (CPANEL_RX_READ_PTR:16)
	jr nc, CPanel_RX_PacketSizeCheck
	neg wa
	ex8 a, w
	ld a, 92:opc
	sub a, w
CPanel_RX_PacketSizeCheck:
	cp a, 2:i3
	jrl c, CPanel_RX_Done

	ld	l, (xde+iy)
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
	ld	w, (xde+iy)
	calr	CPanel_IncRXPtr
	ld	(xiz+ix), w
	calr	CPanel_IncEventPtr
	ld	(CPANEL_RX_PACKET_BYTE_1:16), w
	ld	a, (xde+iy)
	calr	CPanel_IncRXPtr
	ld	(xiz+ix), a
	calr	CPanel_IncEventPtr
	ld	(CPANEL_RX_PACKET_BYTE_2:16), a
	and	w, 79
	ld	xhl, STATE_OF_CPANEL_BUTTONS
	bit	6, w
	jr	z, BtnPkt_AddOffset	; -> 0xFC41F2
	sub	w, 48
BtnPkt_AddOffset:
	add l, w
	jr nc, BtnPkt_XORLookup
	inc 1, h

BtnPkt_XORLookup:
	ex (xhl), a
	xor a, (xhl)
	ld	(xiz+ix), a
	calr CPanel_IncEventPtr
	stb_d8 (CPANEL_LAST_EVENT_VALUE), a
	ld (xiz-4), ix
	decm 3, (xiz-2)
	ld (CPANEL_RX_READ_PTR:16), iy
	jrl CPanel_RX_ParseNext
CPanel_RX_EncoderPacket:
	ld	w, (xde+iy)
	calr	CPanel_IncRXPtr
	ld	(xiz+ix), w
	calr	CPanel_IncEventPtr
	ld	(CPANEL_RX_PACKET_BYTE_1:16), w
	ld	a, (xde+iy)
	calr	CPanel_IncRXPtr
	ld	(CPANEL_RX_PACKET_BYTE_2:16), a
	ld	c, w
	calr	EncPkt_DispatchThunk
	cp	hl, 65535
	jr	nz, EncPkt_WriteEvent	; -> 0xFC4249
	calr	CPanel_DecEventPtr
	ld	(CPANEL_RX_READ_PTR:16), iy
	jr	EncPkt_ParseNext	; -> 0xFC4268
EncPkt_WriteEvent:
	ld	(xiz+ix), l
	calr	CPanel_IncEventPtr
	ld	(CPANEL_LAST_EVENT_VALUE:16), l
	ld	(xiz+ix), 0xff
	calr	CPanel_IncEventPtr
	ld	(xiz-4), ix
	decw	3, (xiz-2)
	ld	(CPANEL_RX_READ_PTR:16), iy
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
	ld	a, (xde+iy)
	ld c, a
	and a, 0xf
	inc 1, a
	ld b, a
	add a, 0x2
	cp w, a
	jrl c, CPanel_RX_Done

	calr CPanel_IncRXPtr
	ld	a, (xde+iy)
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
	or	a, c
	ld	l, a
	extz	hl
	extz	xhl
	add	xhl, 36270
MBytePkt_LoopBody:
	ld	(xiz+ix), w
	calr CPanel_IncEventPtr
	ld	a, (xde+iy)
	calr CPanel_IncRXPtr
	bit 0x04,W
	jr z, MBytePkt_WriteEventByte
	pushw bc
	ld C,W
	pushw hl
	pushw wa
	calr EncPkt_DispatchThunk
	popw wa
	cp HL,0xffff
	ld (CPANEL_LAST_EVENT_VALUE:16), l
	popw hl
	popw bc
	jr nz, MBytePkt_EncWriteResult
	jr t, MBytePkt_EncNoEvent
MBytePkt_EncNoEvent:
	calr	CPanel_DecEventPtr
	ld	(CPANEL_RX_READ_PTR:16), iy
	jrl	MBytePkt_LoopTail
MBytePkt_EncWriteResult:
	ld	a, (CPANEL_LAST_EVENT_VALUE:16)
MBytePkt_WriteEventByte:

c:
	ld	(xiz+ix), a
	calr CPanel_IncEventPtr
	bit 4, w
	jr nz, MBytePkt_EncFFMarker
	ex (xhl), a
	xor a, (xhl)
	inc 1, hl
	bit 4, (CPANEL_TX_RX_FLAGS:16)
	jr z, MBytePkt_CommitAndContinue
	cp a, 0:i3
	jr nz, MBytePkt_CommitAndContinue
	calr CPanel_DecEventPtr
	calr CPanel_DecEventPtr
	jr MBytePkt_CommitRXPtr
MBytePkt_EncFFMarker:
	ld a, 0xff:opc

					; else:
MBytePkt_CommitAndContinue:
	ld	(xiz+ix), a
	calr CPanel_IncEventPtr
	ld (xiz - 4), ix
	decm 1, (xiz - 2)
	decm 1, (xiz - 2)
	decm 1, (xiz - 2)

MBytePkt_CommitRXPtr:
	ld	(CPANEL_RX_READ_PTR:16), iy
MBytePkt_LoopTail:
	inc 1, w
	dec 1, b
	cp b, 0:i3
	jrl nz, MBytePkt_LoopBody
	jrl CPanel_RX_ParseNext

CPanel_RX_SyncPacket:
	ld	a, (xde+iy)

	calr	CPanel_IncRXPtr

	ld	a, (xde+iy)

	calr	CPanel_IncRXPtr	; calr CPanel_IncRXPtr (v7 displacement)

	ld	(CPANEL_RX_READ_PTR:16), iy	; stda16 (0x8d9d), xiy (v7 patched)

	or	(CPANEL_PROTOCOL_FLAGS:16), 8	; ordi8 0x8d92, 8	; CP_Flags_B.3 = 1  ; UNUSED (v7 patched)

	jrl	CPanel_RX_ParseNext	; jrl CPanel_RX_ParseNext (v7 displacement)



CPanel_RX_Done:
	ret


CPanel_UpdateLEDs:
	ld	iy, (CPANEL_LED_WRITE_PTR:16)
	ld	xde, 36197
	ld	xiz, CPANEL_LED_EVENT_QUEUE
	ld	ix, (xiz-8)
CPanel_UpdateLEDs__check_next:
	ld wa, (xiz - 4)
	cp wa, (xiz - 8)
	jr nz, LEDs_CheckTXSpace
	cpw (xiz - 2), 0x0
	jrl nz, LEDs_Return

LEDs_CheckTXSpace:
	ld	wa, (CPANEL_LED_WRITE_PTR:16)
	sub	wa, (CPANEL_LED_READ_PTR:16)
	jr	nc, LEDs_TXForwardDist	; -> 0xFC4393
	neg	wa
	ld	hl, wa
	jr	LEDs_TXCheckThreshold	; -> 0xFC4398
LEDs_TXForwardDist:
	ldw hl, 0x3c
	sub hl, wa

LEDs_TXCheckThreshold:
	cp hl, 3:i3
	jrl c, LEDs_Return
	ld	a, (xiz+ix)
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


CPanel_LED_HandlePacket2:
	ld	a, (xiz+ix)	; A = event queue byte 1 at (XIZ + IX)

	calr 151

	ld	(xde+iy), a	; LED buffer op at (XDE + IY)

	calr CPanel_IncLEDPtr

	ld	w, (xiz+ix)	; W = event queue byte 2 at (XIZ + IX)

	calr ToneGen_IncrementWrap128

	ld	(xde+iy), w	; LED buffer op at (XDE + IY)

	calr CPanel_IncLEDPtr

	ld_dst16_rid8	XIZ, -8, IX	; LD (XIZ-8), IX -- store updated event read ptr

	incw 1, (xiz - 2)		; increment pending LED byte count

	incw 1, (xiz - 2)		; increment pending LED byte count (+2 total)

	ld	(CPANEL_LED_WRITE_PTR:16), iy	; stda16 (0x8dff), iy; store LED write ptr to CPANEL_LED_WRITE_PTR (v7 patched)

	jrl	CPanel_UpdateLEDs__check_next	; jrl CPanel_UpdateLEDs__check_next	; check for more events (v7 displacement)



CPanel_LED_HandlePacketN:	; FC4BC5 -- LED handler for packet type 3
	; Transfers variable-length data from LED event queue to LED TX buffer.
	; Event byte 1 encodes: upper bits = row/command, lower nibble = data count.
	; Total bytes transferred = (byte1 & 0x0f) + 2 (including the header bytes).
	ld	a, (xiz+ix)	; A = event queue byte 1 at (XIZ + IX)
	calr ToneGen_IncrementWrap128		; process byte + increment event read ptr
	ld c, a				; C = save event byte 1
	and a, 0x0f			; A = lower nibble (data byte count)
	add a, 2			; A = total byte count (nibble + 2)
	ld b, a				; B = loop counter
	ld a, c				; A = restore event byte 1
	ld	(xde+iy), a	; LED buffer op at (XDE + IY)
	calr CPanel_IncLEDPtr		; increment LED write ptr (IY)
	incw 1, (xiz - 2)		; increment pending LED byte count

CPanel_LED_HandlePacketN__loop:
	ld	a, (xiz+ix)
	calr	ToneGen_IncrementWrap128
	ld	(xde+iy), a
	calr	CPanel_IncLEDPtr
	ld	(xiz-8), ix
	incw	1, (xiz-2)
	ld	(CPANEL_LED_WRITE_PTR:16), iy
	dec	1, b
	cp	b, 0:i3
	jr	nz, CPanel_LED_HandlePacketN__loop
	jrl	CPanel_UpdateLEDs__check_next
LEDs_Return:
	ret


CPanel_IncRXPtr:
	inc 1, iy
	cp iy, 0x5c
	jr c, IncRX_NoWrap
	ld iy, 0:i3

IncRX_NoWrap:
	ret


CPanel_IncLEDPtr:
	inc 1, iy
	cp iy, 0x3c
	jr c, IncLED_NoWrap
	ld iy, 0:i3

IncLED_NoWrap:
	ret


CPanel_IncEventPtr:
	inc 1, ix
	cp ix, 0x80
	jr c, IncEvt_NoWrap
	ld ix, 0:i3

IncEvt_NoWrap:
	ret


CPanel_DecEventPtr:
	cp ix, 0:i3
	jr nz, DecEvt_NoWrap
	ldw ix, 0x7f
	ret

DecEvt_NoWrap:
	dec 1, ix
	ret

; End of control panel routines
