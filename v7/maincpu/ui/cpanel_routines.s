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
	.byte 0x43, 0xad, 0x00, 0x02, 0x00, 0xbb, 0xfc, 0x02
	.byte 0x00, 0x00, 0xbb, 0xf8, 0x02, 0x00, 0x00, 0xbb
	.byte 0xfe, 0x02, 0x80, 0x00, 0x43, 0x37, 0x01, 0x02
	.byte 0x00, 0xbb, 0xfc, 0x02, 0x00, 0x00, 0xbb, 0xf8
	.byte 0x02, 0x00, 0x00, 0xbb, 0xfe, 0x02, 0x80, 0x00
	.byte 0x21, 0x03, 0xc9, 0xcc, 0xaf, 0xf1, 0xf3, 0x8c
	.byte 0x41, 0xf0, 0x3f, 0x41, 0x21, 0x15, 0xc9, 0xcc
	.byte 0x8f, 0xf1, 0xf2, 0x8c, 0x41, 0xf0, 0x3e, 0x41
	.byte 0xc0, 0x3c, 0x3c, 0xbf, 0x21, 0x00, 0xf0, 0x3b
	.byte 0x41, 0x21, 0x46, 0xf0, 0x3a, 0x41, 0x08, 0xd6
	.byte 0x00, 0x08, 0xd7, 0x14, 0x08, 0xd5, 0x01, 0x08
	.byte 0xe3, 0x07, 0x08, 0xf8, 0x12, 0x08, 0xeb, 0xff
	.byte 0x08, 0xf8, 0x22, 0x08, 0xf8, 0x23, 0xc0, 0xc8
	.byte 0x3e, 0x10, 0xc0, 0xc8, 0x3c, 0xf7, 0xf1, 0xf5
	.byte 0x8c, 0x00, 0x7d, 0xc1, 0xf0, 0x8c, 0x3e, 0x40
	.byte 0xf1, 0xef, 0x8c, 0x00, 0x00, 0xc1, 0xf0, 0x8c
	.byte 0x3c, 0xfc, 0xf1, 0x61, 0x8d, 0x02, 0x00, 0x00
	.byte 0xf1, 0x63, 0x8d, 0x02, 0x00, 0x00, 0xf1, 0x01
	.byte 0x8d, 0x02, 0x00, 0x00, 0xf1, 0x03, 0x8d, 0x02
	.byte 0x00, 0x00, 0x1e, 0xa7, 0x01, 0x21, 0x1f, 0x20
	.byte 0xda, 0x1e, 0x2e, 0x04, 0x1e, 0x7c, 0x01, 0xf1
	.byte 0x61, 0x8d, 0x02, 0x00, 0x00, 0x1e, 0x73, 0x01
	.byte 0x1e, 0x01, 0x00, 0x0e
CPanel_SendInitSequence:
	ld a, 31:opc
	ld w, 26:opc
	calr CPanel_SendCommand
	calr DELAY_3000_LOOPS
	stdi16 (36193), 0
	calr DELAY_3000_LOOPS
	ld a, 29:opc
	ld w, 0:opc
	calr CPanel_SendCommand
	calr DELAY_3000_LOOPS
	stdi16 (36193), 0
	calr DELAY_3000_LOOPS
	calr DELAY_3000_LOOPS
	ld a, 221:opc
	ld w, 3:opc
	calr CPanel_SendCommand
	calr DELAY_3000_LOOPS
	stdi16 (36193), 0
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
	and_sd8b_im 214, 223
	ld (248:8), 18:io
	ld (227:8), 5:io
	stdi16 (36097), 0
	stdi16 (36099), 0
	ordi8 (36086), 1
	di
	ret
CPanel_InitLEDBuffer:
	stda16 (36197), wa
	anddi8 (36083), 191
	ldb_d8 a, (36083)
	st_dd8b a, 63
	ld (235:8), 255:io
	ld (248:8), 34:io
	ld (248:8), 35:io
	ld (227:8), 7:io
	ld (248:8), 18:io
	and_sd8b_im 60, 191
	ordi8 (36082), 64
	ldb_d8 a, (36082)
	st_dd8b a, 62
	calr DELAY_300_LOOPS
	calr DELAY_300_LOOPS
	anddi8 (36082), 191
	ldb_d8 a, (36082)
	st_dd8b a, 62
	calr DELAY_300_LOOPS
	calr DELAY_300_LOOPS
	ordi8 (36083), 80
	ldb_d8 a, (36083)
	st_dd8b a, 63
	ordi8 (36082), 80
	ldb_d8 a, (36082)
	st_dd8b a, 62
	and_sd8b_im 213, 254
	ld (235:8), 255:io
	ld (248:8), 34:io
	ld (248:8), 35:io
	ld xiy, 36197
	addda16 xiy, (36193)
	ld a, (xiy)
	incdi16 1, (36193)
	st_dd8b a, 212
	calr DELAY_300_LOOPS
	calr DELAY_300_LOOPS
	ld xiy, 36197
	addda16 xiy, (36193)
	ld a, (xiy)
	incdi16 1, (36193)
	st_dd8b a, 212
	calr DELAY_300_LOOPS
	calr DELAY_300_LOOPS
	or_sd8b_im 213, 1
	and_sd8b_im 213, 253
	anddi8 (36082), 175
	ldb_d8 a, (36082)
	st_dd8b a, 62
	anddi8 (36083), 175
	ldb_d8 a, (36083)
	st_dd8b a, 63
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
	ld	wa, (1033:16)
	ld	(36095:16), wa
DELAY_2_TICKS__loop:
	ldw_d16 wa, (1033)
	subda16 xwa, (36095)
	cp wa, 2:i3
	jr lt, DELAY_2_TICKS__loop
	ret
DELAY_6_TICKS:
	ld	wa, (1033:16)
	ld	(36095:16), wa
Delay6T_Loop:
	ldw_d16 wa, (1033)
	subda16 xwa, (36095)
	cp wa, 6:i3
	jr lt, Delay6T_Loop
	ret
DELAY_51_TICKS:
	ld	wa, (1033:16)
	ld	(36095:16), wa
Delay51T_Loop:
	ldw_d16 wa, (1033)
	subda16 xwa, (36095)
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
	ld (0x8cf7:16), 0x00
	calr CPanel_WaitTXReady
	ei 0x06
	ldw (0x8d01:16), 0x0000
	ldw (0x8d03:16), 0x0000
	or (0x8cf6:16), 0x01
	ei 0x00
	ld A, 0x20:opc
	ld W, 0x00:opc
	calr CPanel_SendCommand
	calr DELAY_6_TICKS
	cpw (0x8d03:16), 0x0000
	jr z, .Lc_fc39fd
	or (0x8cf7:16), 0x01
PanelDet_ProbeRight:
.Lc_fc39fd:
	calr CPanel_WaitTXReady
	ei 0x06
	ldw (0x8d01:16), 0x0000
	ldw (0x8d03:16), 0x0000
	or (0x8cf6:16), 0x01
	ei 0x00
	ld A, 0xe0:opc
	ld W, 0x00:opc
	calr CPanel_SendCommand
	calr DELAY_6_TICKS
	cpw (0x8d03:16), 0x0000
	jr z, PanelDet_Return
	or (0x8cf7:16), 0x08
PanelDet_Return:
	ld	a, (36087:16)
	ret
CPanel_ReadAllButtons:
	.byte 0x43, 0xad, 0x00, 0x02, 0x00, 0xbb, 0xfc, 0x02
	.byte 0x00, 0x00, 0xbb, 0xf8, 0x02, 0x00, 0x00, 0xbb
	.byte 0xfe, 0x02, 0x80, 0x00, 0x06, 0x06, 0xd1, 0x01
	.byte 0x8d, 0x20, 0xf1, 0x03, 0x8d, 0x50, 0xc1, 0xf6
	.byte 0x8c, 0x3e, 0x01, 0x06, 0x00, 0x1d, 0xaa, 0x3b
	.byte 0xfc, 0x21, 0x25, 0x20, 0x01, 0x1d, 0xfc, 0x3b
	.byte 0xfc, 0x1e, 0x09, 0xff, 0x1e, 0x06, 0xff, 0x1e
	.byte 0x03, 0xff, 0x1e, 0x3c, 0x01, 0x21, 0xe2, 0x20
	.byte 0x04, 0x1e, 0x87, 0x01, 0x1e, 0xf6, 0xfe, 0x1e
	.byte 0xf3, 0xfe, 0x1e, 0x2c, 0x01, 0x21, 0x20, 0x20
	.byte 0x10, 0x1e, 0x77, 0x01, 0x1e, 0xe6, 0xfe, 0x1e
	.byte 0xe3, 0xfe, 0x1e, 0x1c, 0x01, 0x21, 0xe2, 0x20
	.byte 0x11, 0x1e, 0x67, 0x01, 0x1e, 0xd6, 0xfe, 0x1e
	.byte 0xd3, 0xfe, 0x1e, 0xac, 0x06, 0x0e
CPanel_PollStartup:
	ld xhl, 0x200ad

	ldw (xhl - 4), 0x0

	ldw (xhl - 8), 0x0

	ldw (xhl - 2), 0x80

	ei 6

	stdi16 (36097), 0	; stdi16 (0x8d9d), 0 (v7 patched)

	stdi16 (36099), 0	; stdi16 (0x8d9f), 0 (v7 patched)

	ordi8 (36086), 1	; ordi8 0x8d92, 1	; CP_Flags_B.0 = 1 (v7 patched)

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
	.byte 0xc1, 0xce, 0x8d, 0xf8, 0xf1, 0xce, 0x8d, 0x40
	.byte 0x6e, 0xd2, 0xf1, 0xce, 0x8d, 0x40, 0x43, 0xad
	.byte 0x00, 0x02, 0x00, 0xbb, 0xfc, 0x02, 0x00, 0x00
	.byte 0xbb, 0xf8, 0x02, 0x00, 0x00, 0xbb, 0xfe, 0x02
	.byte 0x80, 0x00, 0x06, 0x06, 0xf1, 0x61, 0x8d, 0x02
	.byte 0x00, 0x00, 0xf1, 0x63, 0x8d, 0x02, 0x00, 0x00
	.byte 0xf1, 0x01, 0x8d, 0x02, 0x00, 0x00, 0xf1, 0x03
	.byte 0x8d, 0x02, 0x00, 0x00, 0xc1, 0xf6, 0x8c, 0x3e
	.byte 0x01, 0x06, 0x00, 0x0e
CPanel_InitButtonState:
	.byte 0x43, 0xad, 0x00, 0x02, 0x00, 0xbb, 0xfc, 0x02
	.byte 0x00, 0x00, 0xbb, 0xf8, 0x02, 0x00, 0x00, 0xbb
	.byte 0xfe, 0x02, 0x80, 0x00, 0x06, 0x06, 0xf1, 0x01
	.byte 0x8d, 0x00, 0x00, 0xf1, 0x03, 0x8d, 0x00, 0x00
	.byte 0xc1, 0xf6, 0x8c, 0x3e, 0x01, 0x06, 0x00, 0x1e
	.byte 0x50, 0x00, 0x21, 0x2b, 0x20, 0x00, 0x1e, 0x9b
	.byte 0x00, 0x1e, 0x0a, 0xfe, 0x1e, 0x07, 0xfe, 0x1e
	.byte 0x04, 0xfe, 0x1e, 0xd6, 0x05, 0x1e, 0x3a, 0x00
	.byte 0x21, 0xeb, 0x20, 0x00, 0x1e, 0x85, 0x00, 0x1e
	.byte 0xf4, 0xfd, 0x1e, 0xf1, 0xfd, 0x1e, 0xee, 0xfd
	.byte 0x1e, 0xc0, 0x05, 0x1e, 0x24, 0x00, 0x21, 0x20
	.byte 0x20, 0x10, 0x1e, 0x6f, 0x00, 0x1e, 0xde, 0xfd
	.byte 0x1e, 0xdb, 0xfd, 0x1e, 0xad, 0x05, 0x1e, 0x11
	.byte 0x00, 0x21, 0xe3, 0x20, 0x10, 0x1e, 0x5c, 0x00
	.byte 0x1e, 0xcb, 0xfd, 0x1e, 0xc8, 0xfd, 0x1e, 0x9a
	.byte 0x05, 0x0e
CPanel_WaitTXReady:
	ld	(36091:16), 200
CPanel_WaitTXReady_Poll:
	ei 6
	bit_dd8 6, 60
	jr z, CPanel_WaitTXReady_Timeout
	bit_dd8 5, 56
	jr nz, CPanel_WaitTXReady_Timeout
	bitda 1, (36080)
	jr nz, CPanel_WaitTXReady_Timeout
	bitda 0, (36080)
	jr nz, CPanel_WaitTXReady_Timeout
	jr CPanel_WaitTXReady_BufferCheck
CPanel_WaitTXReady_Timeout:
	decdi8 1, (36091)
	cpdi8 (36091), 0
	jr z, WaitTX_ConfigAndReturn
	di
	calr DELAY_1500_LOOPS
	jr CPanel_WaitTXReady_Poll
CPanel_WaitTXReady_BufferCheck:
	ldw_d16 wa, (36195)
	cpda16 xwa, (36193)
	jr nz, CPanel_WaitTXReady_Timeout
WaitTX_ConfigAndReturn:
	ei 6

	ld (0xf8:8), 0x22:io	; INTRX1: Serial receive 1

	ld (0xf8:8), 0x23:io	; INTTX1: Serial send 1

	ld (0xeb:8), 0xdd:io

	and_sd8b_im 0xd6, 0xdf	; RXE (bit 5) = 0: receive disable

	ordi8 (36086), 128	; ordi8 0x8d92, 128	; CP_Flags_B.7 = 1 (v7 patched)

	ei 0

	ret





CPanel_SendCommand:
	ei 0x06
	ldw (0x8d61:16), 0x0000
	ldw (0x8d63:16), 0x0000
	ld (0x8d65:16), wa
	addw (0x8d63:16), 0x0002
	or (0x8cf0:16), 0x02
	and (0x8cf0:16), 0xfe
	ld (0x8cee:16), 0x04
	ld (215:8), 40:io
	anddi8 (36083), 191
	ldb_d8 a, (36083)
	st_dd8b a, 63
	and_sd8b_im 60, 191
	ordi8 (36082), 64
	ldb_d8 a, (36082)
	st_dd8b a, 62
	ld (227:8), 7:io
	ld (248:8), 18:io
	and_sd8b_im 214, 223
	and_sd8b_im 213, 254
	ld (248:8), 35:io
	ld (235:8), 223:io
	ld (248:8), 34:io
	st_dd8b a, 212
	di
	nop
	ret
INTA_HANDLER:
	stdi8 (36092), 0
	push xwa
	cpdi8 (36079), 0
	jr nz, INTA_HandleCountdown
	anddi8 (36082), 159
	ldb_d8 a, (36082)
	st_dd8b a, 62
	or_sd8b_im 213, 1
	and_sd8b_im 213, 253
	ld (227:8), 5:io
	ld (235:8), 13:io
	or_sd8b_im 214, 32
	stdi8 (36078), 32
	ordi8 (36080), 1
	jr 28
INTA_HandleCountdown:
	cpdi16 (36099), 0
	jr nz, 6
	stdi16 (36099), 92
INTA_DecrementRXCount:
	decdi16 1, (36099)	; decdi16 1, 0x8d9f (v7 patched)

	ordi8 (36086), 64	; ordi8 0x8d92, 64	; CP_Flags_B.6 = 1  ; UNUSED (v7 patched)

	anddi8 (36080), 253	; anddi8 (0x8d8c), 253; CP_Flags_A.1 = 0 (v7 patched)



INTA_HANDLER_END:
	pop xwa
	ld (0xf8:8), 0x12:io	; INTA Pin
	ld (0xf8:8), 0x22:io	; INTRX1: Serial receive 1
	ld (0xf8:8), 0x23:io	; INTTX1: Serial send 1
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
	push	xwa
	push	xhl
	push	xiy
	ld	l, (36078:16)
	xor	h, h
	extz	xhl
	add	xhl, 16530622
	ld	xhl, (xhl)
	jp	(xhl)
MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES:
	pop xiy
	pop xhl
	pop xwa
	ld (0xf8:8), 0x12:io	; INTA Pin
	ld (0xf8:8), 0x22:io	; INTRX1: Serial receive 1
	ld (0xf8:8), 0x23:io	; INTTX1: Serial send 1
	reti


INTRX1_HANDLER:
	push	xwa
	push	xhl
	push	xiy
	ld	l, (36078:16)
	xor	h, h
	extz	xhl
	add	xhl, 16530622
	ld	xhl, (xhl)
	jp	(xhl)
LEAST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES:
	pop xiy
	pop xhl
	pop xwa
	ld (0xf8:8), 0x12:io	; INTA Pin
	ld (0xf8:8), 0x22:io	; INTRX1: Serial receive 1
	ld (0xf8:8), 0x23:io	; INTTX1: Serial send 1
	reti


CPanel_SM_StartTX:
	anddi8 (36082), 191
	ldb_d8 a, (36082)
	st_dd8b a, 62
	ld (215:8), 36:io
	ld (227:8), 7:io
	ld (235:8), 208:io
	and_sd8b_im 213, 254
	st_dd8b a, 212
	incdi8 4, (36078)
	mul a, 1
	mul a, 1
	bit_dd8 6, 60
	jr nz, MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES
	stdi8 (36079), 0
	stdi8 (36078), 0
	ordi8 (36086), 2
	ld (227:8), 5:io
	ld (235:8), 255:io
	ld (215:8), 36:io
	anddi8 (36080), 253
	jrl MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES
CPanel_SM_TXDelay1:
	calr DELAY_10_LOOPS
	anddi8 (36082), 175
	ldb_d8 a, (36082)
	st_dd8b a, 62
	anddi8 (36083), 175
	ldb_d8 a, (36083)
	st_dd8b a, 63
	ld (215:8), 36:io
	ld (235:8), 208:io
	and_sd8b_im 213, 254
	st_dd8b a, 212
	incdi8 4, (36078)
	jrl MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES
CPanel_SM_TXDelay2:
	calr DELAY_10_LOOPS
	anddi8 (36082), 175
	ldb_d8 a, (36082)
	st_dd8b a, 62
	anddi8 (36083), 175
	ldb_d8 a, (36083)
	st_dd8b a, 63
	ld (215:8), 36:io
	st_dd8b a, 212
	ld (227:8), 5:io
	ld (235:8), 208:io
	and_sd8b_im 213, 254
	st_dd8b a, 212
	incdi8 4, (36078)
	jrl MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES
CPanel_SM_SendByte1:
	ld (215:8), 20:io
	ordi8 (36083), 80
	ldb_d8 a, (36083)
	st_dd8b a, 63
	ordi8 (36082), 80
	ldb_d8 a, (36082)
	st_dd8b a, 62
	and_sd8b_im 213, 254
	ld (227:8), 5:io
	ld (235:8), 208:io
	ld xiy, 36197
	addda16 xiy, (36193)
	ld a, (xiy)
	st_dd8b a, 212
	incdi16 1, (36193)
	cpdi16 (36193), 60
	jr c, SendByte1_InspectByte
	stdi16 (36193), 0
SendByte1_InspectByte:
	ld	(36079:16), 2
	ld	a, (xiy)
	and	a, 63
	cp	a, 48
	jr	c, SendByte1_AdvanceState
	and	a, 15
	add	a, 3
	ld	(36079:16), a
SendByte1_AdvanceState:
	inc	4, (36078:16)
	jrl	MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES
CPanel_SM_SendByteN:
	ld (215:8), 20:io
	ordi8 (36083), 80
	ldb_d8 a, (36083)
	st_dd8b a, 63
	ordi8 (36082), 80
	ldb_d8 a, (36082)
	st_dd8b a, 62
	and_sd8b_im 213, 254
	ld (227:8), 5:io
	ld (235:8), 208:io
	ld xiy, 36197
	addda16 xiy, (36193)
	ld a, (xiy)
	st_dd8b a, 212
	incdi16 1, (36193)
	cpdi16 (36193), 60
	jr c, SendByteN_CheckDone
	stdi16 (36193), 0
SendByteN_CheckDone:
	decdi8 1, (36079)
	cpdi8 (36079), 1
	jr z, SendByteN_AdvanceState
	cpdi8 (36079), 0
	jr z, SendByteN_AdvanceState
	decdi8 4, (36078)
	jrl MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES
SendByteN_AdvanceState:
	inc	4, (36078:16)
	jrl	MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES
CPanel_SM_TXComplete:
	stdi8 (36079), 0
	stdi8 (36078), 0
	ldw_d16 wa, (36195)
	subda16 xwa, (36193)
	cp wa, 2:i3
	jr c, TXComplete_BufferEmpty
	stdi8 (36078), 4
	anddi8 (36083), 191
	ldb_d8 a, (36083)
	st_dd8b a, 63
	and_sd8b_im 60, 191
	ordi8 (36082), 64
	ldb_d8 a, (36082)
	st_dd8b a, 62
	ld (215:8), 40:io
	ld (227:8), 7:io
	and_sd8b_im 213, 254
	ld (235:8), 208:io
	st_dd8b a, 212
	ordi8 (36080), 2
	jrl MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES
TXComplete_BufferEmpty:
	anddi8 (36082), 191	; anddi8 (0x8d8e), 191 (v7 patched)

	ldb_d8 a, (36082)	; ldb_d8 a, (0x8d8e) (v7 patched)

	st_dd8b A, 0x3e

	anddi8 (36083), 191	; anddi8 (0x8d8f), 191; disable CPanel serial clk (v7 patched)

	ldb_d8 a, (36083)	; ldb_d8 a, (0x8d8f) (v7 patched)

	st_dd8b A, 0x3f

	ld (0xe3:8), 0x05:io

	ld (0xeb:8), 0xff:io	; INTTX1: M=7 | INTRX1: M=7 (meaning: disable int.req.)

	ld (0xd7:8), 0x24:io	; Internal Clock T8 (64/fc)

	                 ; Divide by 4

	                 ; fc = 16MHz, so fc/64/4 = 62500

	anddi8 (36080), 253	; anddi8 (0x8d8c), 253; CP_Flags_A.1 = 0 (v7 patched)

	jrl MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES	; jrl MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES (v7 displacement)





CPanel_SM_RXByte1:
	anddi8 (36082), 159
	ldb_d8 a, (36082)
	st_dd8b a, 62
	or_sd8b_im 213, 1
	and_sd8b_im 213, 253
	ld (227:8), 5:io
	ld (235:8), 13:io
	ld_sd8b a, 212
	ld xiy, 36101
	addda16 xiy, (36099)
	ld (xiy), a
	ldw_d16 hl, (36099)
	subda16 xhl, (36097)
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
	ordi8 (36086), 1
	jr RXByte1_InspectByte
RXByte1_AdvanceWritePtr:
	anddi8 (36086), 254
	incdi16 1, (36099)
	cpdi16 (36099), 92
	jr c, RXByte1_InspectByte
	stdi16 (36099), 0
RXByte1_InspectByte:
	ld	(36079:16), 2
	and	a, 63
	cp	a, 48
	jr	c, RXByte1_AdvanceState
	and	a, 15
	add	a, 3
	ld	(36079:16), a
RXByte1_AdvanceState:
	inc	4, (36078:16)
	jrl	LEAST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES
CPanel_SM_RXByteN:
	ld_sd8b a, 212
	ld xiy, 36101
	addda16 xiy, (36099)
	ld (xiy), a
	bitda 0, (36086)
	jr nz, RXByteN_CheckDone
	incdi16 1, (36099)
	cpdi16 (36099), 92
	jr c, RXByteN_CheckDone
	stdi16 (36099), 0
RXByteN_CheckDone:
	decdi8 1, (36079)
	cpdi8 (36079), 1
	jr nz, RXByteN_ContinueRX
	stdi8 (36079), 0
	anddi8 (36080), 254
	stdi8 (36078), 0
	anddi8 (36082), 159
	ldb_d8 a, (36082)
	st_dd8b a, 62
	anddi8 (36083), 191
	ldb_d8 a, (36083)
	st_dd8b a, 63
	ld (227:8), 5:io
	ld (235:8), 13:io
	and_sd8b_im 214, 223
	jrl LEAST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES
RXByteN_ContinueRX:
	anddi8 (36082), 159	; anddi8 (0x8d8e), 159 (v7 patched)

	ldb_d8 a, (36082)	; ldb_d8 a, (0x8d8e) (v7 patched)

	st_dd8b A, 0x3e

	or_sd8b_im 0xd5, 0x01

	and_sd8b_im 0xd5, 0xfd

	ld (0xe3:8), 0x05:io

	ld (0xeb:8), 0x0d:io

	jrl -765	; jrl LEAST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES (v7 displacement)





CPanel_SM_Idle:
	ordi8 (36086), 128	; ordi8 0x8d92, 128	; CP_Flags_B.7 = 1 (v7 patched)

	jrl -773	; jrl LEAST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES (v7 displacement)



	anddi8 (36080), 252	; anddi8 (0x8d8c), 252; CP_Flags_A.0 = 0 (v7 patched)

						; CP_Flags_A.1 = 0

	ordi8 (36086), 4	; ordi8 0x8d92, 4	; CP_Flags_B.2 = 1  : UNUSED (v7 patched)

	ld (0xf8:8), 0x23:io	; INTTX1: Serial send 1

	and_sd8b_im 0xd6, 0xdf	; RXE (bit 5) = 0: receive disable

	ld (0xeb:8), 0x0f:io

	ld (0xf8:8), 0x22:io	; INTRX1: Serial receive 1

	ld (0xe3:8), 0x07:io

	ld (0xf8:8), 0x12:io	; INTA Pin

	reti





CPanel_InterruptPoll_MainLoop:
	inc 1, (0x8cfe:16)
	cp (0x8cfe:16), 0x2a
	jr ule, PollLoop_DispatchWork
	ei 0x06
	ld wa, (0x8d63:16)
	subda16 xwa, (36193)
	jr nc, 6
	neg wa
	ld hl, wa
	jr 5
PollLoop_TXForwardDist:
	ldw hl, 0x3c
	sub hl, wa

PollLoop_TXCheckThreshold:
	cp	hl, 3:i3
	jr	c, PollLoop_DispatchWork	; -> 0xFC4090
	ld	(36094:16), 0
	ld	w, 224:opc
	ld	a, 19:opc
	ld	iy, (36195:16)
	ld	xde, 36197
	st_rrb	w, xde, iy
	calr	CPanel_IncLEDPtr
	st_rrb	a, xde, iy
	calr	CPanel_IncLEDPtr
	ld	(36195:16), iy
PollLoop_DispatchWork:
	di
	ldb_d8 a, (36080)
	and a, 192
	cp a, 0:i3
	jr z, PollLoop_DoLEDUpdate
	adddi8 (36080), 64
	cp a, 192
	jr nz, PollLoop_DoLEDUpdate
	calr CPanel_InitButtonState
	jr PollLoop_CheckTXReady
PollLoop_DoLEDUpdate:
	calr CPanel_UpdateLEDs	; do this
				; }
PollLoop_CheckTXReady:
	ei 6
	bit_dd8 6, 60
	jr z, PollLoop_BusyRetry
	bit_dd8 5, 56
	jr nz, PollLoop_BusyRetry
	bitda 1, (36080)
	jr nz, PollLoop_BusyRetry
	bitda 0, (36080)
	jr nz, PollLoop_BusyRetry
	ldw_d16 wa, (36195)
	subda16 xwa, (36193)
	jr nc, PollLoop_StartTX
	neg wa
	ex8 a, w
	ld a, 60:opc
	sub a, w
PollLoop_StartTX:
	cp a, 2:i3
	jr c, PollLoop_Return
	ordi8 (36080), 2
	stdi8 (36078), 4
	anddi8 (36083), 191
	ldb_d8 a, (36083)
	st_dd8b a, 63
	and_sd8b_im 60, 191
	ordi8 (36082), 64
	ldb_d8 a, (36082)
	st_dd8b a, 62
	ld (215:8), 40:io
	and_sd8b_im 214, 223
	and_sd8b_im 213, 254
	ld (227:8), 7:io
	ld (248:8), 18:io
	ld (248:8), 35:io
	ld (235:8), 208:io
	st_dd8b a, 212
PollLoop_Return:
	ei 0
	ret


PollLoop_BusyRetry:
	incdi8 1, (36092)
	cpdi8 (36092), 20
	jr ule, PollLoop_Return
	ei 6
	ld (248:8), 34:io
	ld (248:8), 35:io
	ld (235:8), 221:io
	ld (248:8), 18:io
	ld (227:8), 5:io
	ordi8 (36086), 128
	jr PollLoop_Return
CPanel_RX_ProcessWithFlag:
	or (0x8cf0:16), 0x04
	jr t, CPanel_RX_DispatchLoop
CPanel_RX_Process:
	and (0x8cf0:16), 0xfb



CPanel_RX_DispatchLoop:
	ld	xde, 36101
	ld	iy, (36097:16)
	ld	xiz, 131245
	ld	ix, (xiz-4)
CPanel_RX_ParseNext:
	cpw (xiz-2), 4
	jrl c, CPanel_RX_Done
	ldw_d16 wa, (36099)
	subda16 xwa, (36097)
	jr nc, CPanel_RX_PacketSizeCheck
	neg wa
	ex8 a, w
	ld a, 92:opc
	sub a, w
CPanel_RX_PacketSizeCheck:
	cp a, 2:i3
	jrl c, CPanel_RX_Done

	ldb_sri L, 0x07, 0xe8, 0xf4
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
	ld_rrb	w, xde, iy
	calr	CPanel_IncRXPtr
	st_rrb	w, xiz, ix
	calr	CPanel_IncEventPtr
	ld	(36088:16), w
	ld_rrb	a, xde, iy
	calr	CPanel_IncRXPtr
	st_rrb	a, xiz, ix
	calr	CPanel_IncEventPtr
	ld	(36089:16), a
	and	w, 79
	ld	xhl, 36270
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
	st_rrb a, xiz, ix
	calr CPanel_IncEventPtr
	stb_d8 (36090), a
	ld (xiz-4), ix
	decm 3, (xiz-2)
	stda16 (36097), iy
	jrl CPanel_RX_ParseNext
CPanel_RX_EncoderPacket:
	ld_rrb	w, xde, iy
	calr	CPanel_IncRXPtr
	st_rrb	w, xiz, ix
	calr	CPanel_IncEventPtr
	ld	(36088:16), w
	ld_rrb	a, xde, iy
	calr	CPanel_IncRXPtr
	ld	(36089:16), a
	ld	c, w
	calr	EncPkt_DispatchThunk
	cp	hl, 65535
	jr	nz, EncPkt_WriteEvent	; -> 0xFC4249
	calr	CPanel_DecEventPtr
	ld	(36097:16), iy
	jr	EncPkt_ParseNext	; -> 0xFC4268
EncPkt_WriteEvent:
	.byte 0xf3, 0x07, 0xf8, 0xf0, 0x47, 0x1e, 0x02, 0x02
	.byte 0xf1, 0xfa, 0x8c, 0x47, 0xf3, 0x07, 0xf8, 0xf0
	.byte 0x00, 0xff, 0x1e, 0xf5, 0x01, 0xbe, 0xfc, 0x54
	.byte 0x9e, 0xfe, 0x6b, 0xf1, 0x01, 0x8d, 0x55
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
	ldb_sri A, 0x07, 0xe8, 0xf4
	ld c, a
	and a, 0xf
	inc 1, a
	ld b, a
	add a, 0x2
	cp w, a
	jrl c, CPanel_RX_Done

	calr CPanel_IncRXPtr
	ldb_sri A, 0x07, 0xe8, 0xf4
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
	stb_dri w, 0x07, 0xf8, 0xf0
	calr CPanel_IncEventPtr
	ldb_dri a, 0x07, 0xe8, 0xf4
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
	ld (0x8cfa:16), l
	popw hl
	popw bc
	jr nz, MBytePkt_EncWriteResult
	jr t, MBytePkt_EncNoEvent
MBytePkt_EncNoEvent:
	calr	CPanel_DecEventPtr
	ld	(36097:16), iy
	jrl	MBytePkt_LoopTail
MBytePkt_EncWriteResult:
	ld	a, (36090:16)
MBytePkt_WriteEventByte:

c:
	st_rrb a, xiz, ix
	calr CPanel_IncEventPtr
	bit 4, w
	jr nz, MBytePkt_EncFFMarker
	ex (xhl), a
	xor a, (xhl)
	inc 1, hl
	bitda 4, (36080)
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
	stb_dri A, 0x07, 0xf8, 0xf0
	calr CPanel_IncEventPtr
	ld (xiz - 4), ix
	decm 1, (xiz - 2)
	decm 1, (xiz - 2)
	decm 1, (xiz - 2)

MBytePkt_CommitRXPtr:
	ld	(36097:16), iy
MBytePkt_LoopTail:
	inc 1, w
	dec 1, b
	cp b, 0:i3
	jrl nz, MBytePkt_LoopBody
	jrl CPanel_RX_ParseNext

CPanel_RX_SyncPacket:
	ldb_sri A, 0x07, 0xe8, 0xf4

	calr	CPanel_IncRXPtr

	ldb_sri A, 0x07, 0xe8, 0xf4

	calr CPanel_IncRXPtr	; calr CPanel_IncRXPtr (v7 displacement)

	stda16 (36097), iy	; stda16 (0x8d9d), xiy (v7 patched)

	ordi8 (36086), 8	; ordi8 0x8d92, 8	; CP_Flags_B.3 = 1  ; UNUSED (v7 patched)

	jrl CPanel_RX_ParseNext	; jrl CPanel_RX_ParseNext (v7 displacement)



CPanel_RX_Done:
	ret


CPanel_UpdateLEDs:
	ld	iy, (36195:16)
	ld	xde, 36197
	ld	xiz, 131383
	ld	ix, (xiz-8)
CPanel_UpdateLEDs__check_next:
	ld wa, (xiz - 4)
	cp wa, (xiz - 8)
	jr nz, LEDs_CheckTXSpace
	cpw (xiz - 2), 0x0
	jrl nz, LEDs_Return

LEDs_CheckTXSpace:
	ld	wa, (36195:16)
	sub	wa, (36193:16)
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
	ldb_sri A, 0x07, 0xf8, 0xf0
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
	ldb_sri A, 0x07, 0xf8, 0xf0	; A = event queue byte 1 at (XIZ + IX)

	calr 151

	stb_dri A, 0x07, 0xe8, 0xf4	; LED buffer op at (XDE + IY)

	calr CPanel_IncLEDPtr

	ldb_sri W, 0x07, 0xf8, 0xf0	; W = event queue byte 2 at (XIZ + IX)

	calr ToneGen_IncrementWrap128

	stb_dri W, 0x07, 0xe8, 0xf4	; LED buffer op at (XDE + IY)

	calr CPanel_IncLEDPtr

	ld_dst16_rid8 XIZ, -8, IX	; LD (XIZ-8), IX -- store updated event read ptr

	incw 1, (xiz - 2)		; increment pending LED byte count

	incw 1, (xiz - 2)		; increment pending LED byte count (+2 total)

	stda16 (36195), iy	; stda16 (0x8dff), iy; store LED write ptr to CPANEL_LED_WRITE_PTR (v7 patched)

	jrl CPanel_UpdateLEDs__check_next	; jrl CPanel_UpdateLEDs__check_next	; check for more events (v7 displacement)



CPanel_LED_HandlePacketN:	; FC4BC5 -- LED handler for packet type 3
	; Transfers variable-length data from LED event queue to LED TX buffer.
	; Event byte 1 encodes: upper bits = row/command, lower nibble = data count.
	; Total bytes transferred = (byte1 & 0x0f) + 2 (including the header bytes).
	ldb_sri A, 0x07, 0xf8, 0xf0	; A = event queue byte 1 at (XIZ + IX)
	calr ToneGen_IncrementWrap128		; process byte + increment event read ptr
	ld c, a				; C = save event byte 1
	and a, 0x0f			; A = lower nibble (data byte count)
	add a, 2			; A = total byte count (nibble + 2)
	ld b, a				; B = loop counter
	ld a, c				; A = restore event byte 1
	stb_dri A, 0x07, 0xe8, 0xf4	; LED buffer op at (XDE + IY)
	calr CPanel_IncLEDPtr		; increment LED write ptr (IY)
	incw 1, (xiz - 2)		; increment pending LED byte count

CPanel_LED_HandlePacketN__loop:
	ld_rrb	a, xiz, ix
	calr	ToneGen_IncrementWrap128
	st_rrb	a, xde, iy
	calr	CPanel_IncLEDPtr
	ld	(xiz-8), ix
	incw	1, (xiz-2)
	ld	(36195:16), iy
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
