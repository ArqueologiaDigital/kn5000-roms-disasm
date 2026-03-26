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
	.incbin "includes/generated/v7_transplant_CPanel_InitHardware.bin"
CPanel_SendInitSequence:
	.incbin "includes/generated/v7_transplant_CPanel_SendInitSequence.bin"
CPanel_InitLEDBuffer:
	.incbin "includes/generated/v7_transplant_CPanel_InitLEDBuffer.bin"
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


DELAY_2_TICKS:
	.incbin "includes/generated/v7_transplant_DELAY_2_TICKS.bin"
DELAY_2_TICKS__loop:
	.incbin "includes/generated/v7_transplant_DELAY_2_TICKS__loop.bin"
DELAY_6_TICKS:
	.incbin "includes/generated/v7_transplant_DELAY_6_TICKS.bin"
Delay6T_Loop:
	.incbin "includes/generated/v7_transplant_Delay6T_Loop.bin"
DELAY_51_TICKS:
	.incbin "includes/generated/v7_transplant_DELAY_51_TICKS.bin"
Delay51T_Loop:
	.incbin "includes/generated/v7_transplant_Delay51T_Loop.bin"
CPanel_CheckSpecialCombos:
	.incbin "includes/generated/v7_transplant_CPanel_CheckSpecialCombos.bin"
CPanel_Combo_CheckAllInitSetting:
	.incbin "includes/generated/v7_transplant_CPanel_Combo_CheckAllInitSetting.bin"
CPanel_Combo_CheckFactoryReset:
	.incbin "includes/generated/v7_transplant_CPanel_Combo_CheckFactoryReset.bin"
CPanel_Combo_CheckFlashUpdate:
	.incbin "includes/generated/v7_transplant_CPanel_Combo_CheckFlashUpdate.bin"
CPanel_Combo_NormalBoot:
	lds hl, 0		; No combo: normal boot

CPanel_CheckSpecialCombos_Return:
	ret


CPanel_PanelDetection:
	.incbin "includes/generated/v7_transplant_CPanel_PanelDetection.bin"
PanelDet_ProbeRight:
	.incbin "includes/generated/v7_transplant_PanelDet_ProbeRight.bin"
PanelDet_Return:
	.incbin "includes/generated/v7_transplant_PanelDet_Return.bin"
CPanel_ReadAllButtons:
	.incbin "includes/generated/v7_transplant_CPanel_ReadAllButtons.bin"
CPanel_PollStartup:
	.incbin "includes/generated/v7_transplant_CPanel_PollStartup.bin"
CPanel_ButtonPollLoop:
	.incbin "includes/generated/v7_transplant_CPanel_ButtonPollLoop.bin"
CPanel_EncoderCheck:
	.incbin "includes/generated/v7_transplant_CPanel_EncoderCheck.bin"
CPanel_InitButtonState:
	.incbin "includes/generated/v7_transplant_CPanel_InitButtonState.bin"
CPanel_WaitTXReady:
	.incbin "includes/generated/v7_transplant_CPanel_WaitTXReady.bin"
CPanel_WaitTXReady_Poll:
	.incbin "includes/generated/v7_transplant_CPanel_WaitTXReady_Poll.bin"
CPanel_WaitTXReady_Timeout:
	.incbin "includes/generated/v7_transplant_CPanel_WaitTXReady_Timeout.bin"
CPanel_WaitTXReady_BufferCheck:
	.incbin "includes/generated/v7_transplant_CPanel_WaitTXReady_BufferCheck.bin"
WaitTX_ConfigAndReturn:
	.incbin "includes/generated/v7_transplant_WaitTX_ConfigAndReturn.bin"
CPanel_SendCommand:
	.incbin "includes/generated/v7_transplant_CPanel_SendCommand.bin"
INTA_HANDLER:
	.incbin "includes/generated/v7_transplant_INTA_HANDLER.bin"
INTA_HandleCountdown:
	.incbin "includes/generated/v7_transplant_INTA_HandleCountdown.bin"
INTA_DecrementRXCount:
	.incbin "includes/generated/v7_transplant_INTA_DecrementRXCount.bin"
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
	.incbin "includes/generated/v7_transplant_INTTX1_HANDLER.bin"
MOST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES:
	pop xiy
	pop xhl
	pop xwa
	ldio 0xf8, 0x12	; INTA Pin
	ldio 0xf8, 0x22	; INTRX1: Serial receive 1
	ldio 0xf8, 0x23	; INTTX1: Serial send 1
	reti


INTRX1_HANDLER:
	.incbin "includes/generated/v7_transplant_INTRX1_HANDLER.bin"
LEAST_COMMON_END_FOR_CPANEL_SERIAL_ROUTINES:
	pop xiy
	pop xhl
	pop xwa
	ldio 0xf8, 0x12	; INTA Pin
	ldio 0xf8, 0x22	; INTRX1: Serial receive 1
	ldio 0xf8, 0x23	; INTTX1: Serial send 1
	reti


CPanel_SM_StartTX:
	.incbin "includes/generated/v7_transplant_CPanel_SM_StartTX.bin"
CPanel_SM_TXDelay1:
	.incbin "includes/generated/v7_transplant_CPanel_SM_TXDelay1.bin"
CPanel_SM_TXDelay2:
	.incbin "includes/generated/v7_transplant_CPanel_SM_TXDelay2.bin"
CPanel_SM_SendByte1:
	.incbin "includes/generated/v7_transplant_CPanel_SM_SendByte1.bin"
SendByte1_InspectByte:
	.incbin "includes/generated/v7_transplant_SendByte1_InspectByte.bin"
SendByte1_AdvanceState:
	.incbin "includes/generated/v7_transplant_SendByte1_AdvanceState.bin"
CPanel_SM_SendByteN:
	.incbin "includes/generated/v7_transplant_CPanel_SM_SendByteN.bin"
SendByteN_CheckDone:
	.incbin "includes/generated/v7_transplant_SendByteN_CheckDone.bin"
SendByteN_AdvanceState:
	.incbin "includes/generated/v7_transplant_SendByteN_AdvanceState.bin"
CPanel_SM_TXComplete:
	.incbin "includes/generated/v7_transplant_CPanel_SM_TXComplete.bin"
TXComplete_BufferEmpty:
	.incbin "includes/generated/v7_transplant_TXComplete_BufferEmpty.bin"
CPanel_SM_RXByte1:
	.incbin "includes/generated/v7_transplant_CPanel_SM_RXByte1.bin"
RXByte1_ForwardDist:
	ldw iy, 0x5c
	sub iy, hl

RXByte1_CheckThreshold:
	.incbin "includes/generated/v7_transplant_RXByte1_CheckThreshold.bin"
RXByte1_AdvanceWritePtr:
	.incbin "includes/generated/v7_transplant_RXByte1_AdvanceWritePtr.bin"
RXByte1_InspectByte:
	.incbin "includes/generated/v7_transplant_RXByte1_InspectByte.bin"
RXByte1_AdvanceState:
	.incbin "includes/generated/v7_transplant_RXByte1_AdvanceState.bin"
CPanel_SM_RXByteN:
	.incbin "includes/generated/v7_transplant_CPanel_SM_RXByteN.bin"
RXByteN_CheckDone:
	.incbin "includes/generated/v7_transplant_RXByteN_CheckDone.bin"
RXByteN_ContinueRX:
	.incbin "includes/generated/v7_transplant_RXByteN_ContinueRX.bin"
CPanel_SM_Idle:
	.incbin "includes/generated/v7_transplant_CPanel_SM_Idle.bin"
CPanel_InterruptPoll_MainLoop:
	.incbin "includes/generated/v7_transplant_CPanel_InterruptPoll_MainLoop.bin"
PollLoop_TXForwardDist:
	ldw hl, 0x3c
	sub hl, wa

PollLoop_TXCheckThreshold:
	.incbin "includes/generated/v7_transplant_PollLoop_TXCheckThreshold.bin"
PollLoop_DispatchWork:
	.incbin "includes/generated/v7_transplant_PollLoop_DispatchWork.bin"
PollLoop_DoLEDUpdate:
	calr CPanel_UpdateLEDs	; do this
				; }
PollLoop_CheckTXReady:
	.incbin "includes/generated/v7_transplant_PollLoop_CheckTXReady.bin"
PollLoop_StartTX:
	.incbin "includes/generated/v7_transplant_PollLoop_StartTX.bin"
PollLoop_Return:
	ei 0
	ret


PollLoop_BusyRetry:
	.incbin "includes/generated/v7_transplant_PollLoop_BusyRetry.bin"
CPanel_RX_ProcessWithFlag:
	.incbin "includes/generated/v7_transplant_CPanel_RX_ProcessWithFlag.bin"
CPanel_RX_Process:
	.incbin "includes/generated/v7_transplant_CPanel_RX_Process.bin"
CPanel_RX_DispatchLoop:
	.incbin "includes/generated/v7_transplant_CPanel_RX_DispatchLoop.bin"
CPanel_RX_ParseNext:
	.incbin "includes/generated/v7_transplant_CPanel_RX_ParseNext.bin"
CPanel_RX_PacketSizeCheck:
	cps a, 2
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
	.incbin "includes/generated/v7_transplant_CPanel_RX_ButtonPacket.bin"
BtnPkt_AddOffset:
	add l, w
	jr nc, BtnPkt_XORLookup
	inc 1, h

BtnPkt_XORLookup:
	.incbin "includes/generated/v7_transplant_BtnPkt_XORLookup.bin"
CPanel_RX_EncoderPacket:
	.incbin "includes/generated/v7_transplant_CPanel_RX_EncoderPacket.bin"
EncPkt_WriteEvent:
	.incbin "includes/generated/v7_transplant_EncPkt_WriteEvent.bin"
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
	.incbin "includes/generated/v7_transplant_MBytePkt_AdjustAddr.bin"
MBytePkt_LoopBody:
	.incbin "includes/generated/v7_transplant_MBytePkt_LoopBody.bin"
MBytePkt_EncNoEvent:
	.incbin "includes/generated/v7_transplant_MBytePkt_EncNoEvent.bin"
MBytePkt_EncWriteResult:
	.incbin "includes/generated/v7_transplant_MBytePkt_EncWriteResult.bin"
MBytePkt_WriteEventByte:

c:
	.incbin "includes/generated/v7_transplant_c.bin"
MBytePkt_EncFFMarker:
	ldb a, 0xff

					; else:
MBytePkt_CommitAndContinue:
	lda_dri XBC, 0x07, 0xf8, 0xf0
	calr CPanel_IncEventPtr
	ld (xiz - 4), ix
	decm 1, (xiz - 2)
	decm 1, (xiz - 2)
	decm 1, (xiz - 2)

MBytePkt_CommitRXPtr:
	.incbin "includes/generated/v7_transplant_MBytePkt_CommitRXPtr.bin"
MBytePkt_LoopTail:
	inc 1, w
	dec 1, b
	cps b, 0
	jrl nz, MBytePkt_LoopBody
	jrl CPanel_RX_ParseNext

CPanel_RX_SyncPacket:
	.incbin "includes/generated/v7_transplant_CPanel_RX_SyncPacket.bin"
CPanel_RX_Done:
	ret


CPanel_UpdateLEDs:
	.incbin "includes/generated/v7_transplant_CPanel_UpdateLEDs.bin"
CPanel_UpdateLEDs__check_next:
	ld wa, (xiz - 4)
	cp wa, (xiz - 8)
	jr nz, LEDs_CheckTXSpace
	cpw (xiz - 2), 0x0
	jrl nz, LEDs_Return

LEDs_CheckTXSpace:
	.incbin "includes/generated/v7_transplant_LEDs_CheckTXSpace.bin"
LEDs_TXForwardDist:
	ldw hl, 0x3c
	sub hl, wa

LEDs_TXCheckThreshold:
	cps hl, 3
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
	.incbin "includes/generated/v7_transplant_CPanel_LED_HandlePacket2.bin"
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
	lda_dri XBC, 0x07, 0xe8, 0xf4	; LED buffer op at (XDE + IY)
	calr CPanel_IncLEDPtr		; increment LED write ptr (IY)
	incm 1, (xiz - 2)		; increment pending LED byte count

CPanel_LED_HandlePacketN__loop:
	.incbin "includes/generated/v7_transplant_CPanel_LED_HandlePacketN__loop.bin"
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
