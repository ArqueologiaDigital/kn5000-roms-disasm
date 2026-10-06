; =============================================================================
; fdc_routines.asm - Floppy Disk Controller Routines
; =============================================================================
; This file contains all FDC (Floppy Disk Controller) routines for the KN5000.
;
; The KN5000 uses a standard PC-compatible FDC for its 3.5" floppy drive.
; These routines handle:
;   - Low-level FDC register access (read/write status, data)
;   - DMA setup for disk transfers
;   - Command dispatching and execution
;   - Format parameter configuration
;   - Drive detection and status
;
; Address range: 0xf96d54 - 0xf98009
;
; Dependencies:
;   - fdc_constants.asm must be included before this file
;   - Requires FDC_MAP__BASE_ADDR and FDC__DMA_ACKNOWLEDGE
; =============================================================================

FDC_Read_Status:
	ld l, (0x110008:24)
	ret

; FDC_ReadDataRegister: Reads the uPD72068 data register (0x11000A) into L: result-phase bytes and status bytes.
;   Basis: callers + body -- the result-phase readers (FDC_ResultPhase_Read, FDC_SendAuxCmdReadResult,
;   FDC_INTERRUPT_HANDLER, INT4_ReadResultLoop, FDC_CONFIG_VERIFY) call it after waiting for RQM.
FDC_ReadDataRegister:
	ld l, (0x11000a:24)
	ret

; --- FDC_Send_Command: Write command byte to FDC data register ---
; Stores accumulator A to FDC data port (0x110008),
; waits for FDC ready via status register polling,
; then returns. Uses (R+d16) addressing for FDC port access.
FDC_Send_Command:
	ld	(0x110008:24), a
	ret
FDC_WaitReady_Helper:
	ldmm8	0x8b20, 0x8b22
	ld	(0x8b22:16), a
	ret

; FDC_WriteDataRegister: Writes A to the uPD72068 data register (0x11000A): command and parameter bytes. Basis:
;   callers + body -- FDC_SendCommandByte, FDC_SendParameterByte, INT4_SendSpecifyCmd and FDC_CONFIG_VERIFY call it.
FDC_WriteDataRegister:
	ld (0x11000a:24), a
	ret

; --- FDC_WaitReady: Wait for FDC ready with timeout and DMA transfer ---
; Two-phase wait loop (masks 0x1f and 0x90) checking FDC status register.
; Uses prevbank (D7 FA) for timeout flag management.
; Contains 7-entry command dispatch (commands 0-5 + default):
;   Each entry: stdi8 35436, N; calr <handler>; stdi16 35362, 0
; Handles DMA channel setup, result status checking, and retry logic.
; Timeout limit: 500 timer ticks (checked against timer at address 1033).
; Uses (R+d16) addressing extensively for FDC port and state variable access.
FDC_WaitReady:
	push	xiz
	ld	iz, (SYSTEM_TIMESTAMP:16)
	ldw qiz, 128
	cpw	qiz, 128
	jr	nz, FDC_WaitReady_Skip3
FDC_WaitReady_Loop:
	calr	FDC_Read_Status
	and	l, 31
	ld	a, l
	extz	wa
	cp	wa, 0:i3
	jr	nz, FDC_WaitReady_Skip
	ld qiz, 0
FDC_WaitReady_Skip:
	ld	wa, (SYSTEM_TIMESTAMP:16)
	sub	wa, iz
	cp	wa, 500
	jr	ule, FDC_WaitReady_Skip2
	ldw qiz, 65535
FDC_WaitReady_Skip2:
	cpw	qiz, 128
	jr	z, FDC_WaitReady_Loop
FDC_WaitReady_Skip3:
	cp qiz, 0
	jr z, FDC_WaitReady_Epilogue
	ld	wa, 1:i3
	calr	FDC_Set_Status
FDC_WaitReady_Epilogue:
	pop	xiz
	ret
; FDC_WaitParamByteReady: Waits until the uPD72068 main status register (0x110008) shows RQM|CB (mask 0x90 = 0x90: a
;   command is in progress and the FDC requests the next byte); after 500 ticks of SYSTEM_TIMESTAMP it gives up and
;   records status 1 (FDC_Set_Status). Basis: callers + body + twin -- FDC_SendParameterByte calls it before writing
;   each parameter byte to the data register; the bootloader twin is FDC_WaitComplete (table_data, header 'Wait for
;   the FDC parameter phase'), called by the bootloader's FDC_SendParameterByte.
FDC_WaitParamByteReady:
	push	xiz
	ld	iz, (SYSTEM_TIMESTAMP:16)
	ldw qiz, 128
	cpw	qiz, 128
	jr	nz, FDC_WaitParamByteReady_Skip6
FDC_WaitParamByteReady_Loop2:
	calr	FDC_Read_Status
	and	l, 144
	cp	l, 144
	jr	nz, FDC_WaitParamByteReady_Skip4
	ld qiz, 0
FDC_WaitParamByteReady_Skip4:
	ld	wa, (SYSTEM_TIMESTAMP:16)
	sub	wa, iz
	cp	wa, 500
	jr	ule, FDC_WaitParamByteReady_Skip5
	ldw qiz, 65535
FDC_WaitParamByteReady_Skip5:
	cpw	qiz, 128
	jr	z, FDC_WaitParamByteReady_Loop2
FDC_WaitParamByteReady_Skip6:
	cp qiz, 0
	jr z, FDC_WaitParamByteReady_Epilogue2
	ld	wa, 1:i3
	calr	FDC_Set_Status
FDC_WaitParamByteReady_Epilogue2:
	pop	xiz
	ret
FDC_INIT:
	ldw	wa, 54
	calr	FDC_Send_Command
	ld	wa, 2:i3
	calr	SOME_DELAY
	ld	(0x8b04:16), 255
	ret
FDC_CONFIG_VERIFY:
	push	xiz
	calr	FDC_ClearStatus_InitTimer
	calr	FDC_DRIVE_DETECT
	cp	hl, 0xffff
	jr	z, FDC_CONFIG_VERIFY_Skip
	calr	FDC_DRIVE_STATUS
	cp	hl, 0xffff
	jr	z, FDC_CONFIG_VERIFY_Skip
	ld	(0x8b04:16), 255
FDC_CONFIG_VERIFY_Skip:
	cp	(0x8a20:16), 255
	jrl	z, FDC_WaitReady_Epilogue3
	ld	(0x8a20:16), 255
	ldw	wa, 54
	calr	FDC_Send_Command
	ld	wa, 2:i3
	calr	SOME_DELAY
	calr	FDC_DRIVE_DETECT
	cp	hl, 0xffff
	jr	z, FDC_CONFIG_VERIFY_Skip2
	calr	FDC_DRIVE_STATUS
	cp	hl, 0xffff
	jr	z, FDC_CONFIG_VERIFY_Skip2
	calr	FDC_ClearStatus_InitTimer
	calr	FDC_CMD_DISPATCH_SUB
	cp	(FDC_ERROR_CODE:16), 0
	jr	z, FDC_CONFIG_VERIFY_Loop3
	ld	(0x8a20:16), 0
	jrl	FDC_WaitReady_Epilogue3
FDC_CONFIG_VERIFY_Loop3:
	calr	FDC_Read_Status
	bit	7, l
	jr	z, FDC_CONFIG_VERIFY_Loop3
	calr	FDC_Read_Status
	bit	6, l
	jr	nz, FDC_CONFIG_VERIFY_Skip8
	ld	l, 0:opc
	cp	l, 128
	jr	z, FDC_CONFIG_VERIFY_Skip7
FDC_CONFIG_VERIFY_Loop4:
	calr	FDC_Read_Status
	and	l, 240
	cp	l, 128
	jr	nz, FDC_CONFIG_VERIFY_Loop4
FDC_CONFIG_VERIFY_Skip7:
	ldw	wa, 8
	calr	FDC_WriteDataRegister
FDC_CONFIG_VERIFY_Skip8:
	lda	xiz, (0x8a60:16)
	inc	1, xiz
FDC_CONFIG_VERIFY_Loop5:
	calr	FDC_Wait_Ready_Timeout
	calr	FDC_ReadDataRegister
	ld (xiz+), l
FDC_CONFIG_VERIFY_Loop6:
	calr FDC_Read_Status
	bit 7, l
	jr z, FDC_CONFIG_VERIFY_Loop6
	calr	FDC_Read_Status
	bit	6, l
	jr	nz, FDC_CONFIG_VERIFY_Loop5
	calr	FDC_Exception_Status_Decoder
	cp	(0x8a61:16), 128
	jr	nz, FDC_CONFIG_VERIFY_Loop3
FDC_CONFIG_VERIFY_Skip2:
	ld	wa, 3:i3
	calr	FDC_CMD_SEND
	cp	(FDC_ERROR_CODE:16), 0
	jr	z, FDC_CONFIG_VERIFY_Skip9
	ld	(0x8a20:16), 0
	jrl	FDC_WaitReady_Epilogue3
FDC_CONFIG_VERIFY_Skip9:
	ldw	wa, 79
	calr	FDC_CMD_SEND
	cp	(FDC_ERROR_CODE:16), 0
	jr	z, FDC_CONFIG_VERIFY_Skip10
	ld	(0x8a20:16), 0
	jrl	FDC_WaitReady_Epilogue3
FDC_CONFIG_VERIFY_Skip10:
	ld	a, (0x8a6e:16)
	and	a, 15
	extz	wa
	cp	wa, 0:i3
	jrl	mi, FDC_WaitReady_Skip11
	cp	wa, 5:i3
	jrl	gt, FDC_WaitReady_Skip11
	add	wa, wa
	lda	xix, (FDC_WaitReady_CaseTable:24)
	ld	wa, (xix+wa)
	lda xix, (FDC_CONFIG_VERIFY_On720KMedia:24)
	jp	t, (xix+wa)
; FDC_CONFIG_VERIFY_On720KMedia: Media-type 0 case of FDC_CONFIG_VERIFY's switch on the low nibble of 0x8A6E: stores
;   drive mode 0 in 0x8A6C, rate/mode bits 0 and FDC_WaitReady_Helper(2) -- the 9 x 512 B, 80-track 720 KB (2DD)
;   setting; codes 4 and 5 and the default run the same body with their own code. Basis: callers + body.
FDC_CONFIG_VERIFY_On720KMedia:
	ld (35436:16), 0
	ldw	(0x8a22:16), 0
	ldib_erp 251, 0
	ld wa, 2:i3
	calr	FDC_WaitReady_Helper
	jr	FDC_WaitReady_Join
FDC_CONFIG_VERIFY_Case1:
	ld	(0x8a6c:16), 0
	ldw	(0x8a22:16), 0
	ldi_erpb 251, 192
	ld	wa, 2:i3
	calr	FDC_WaitReady_Helper
	jr	FDC_WaitReady_Join
FDC_CONFIG_VERIFY_On1024ByteSectorMedia:
	ld	(0x8a6c:16), 2
	ldw	(0x8a22:16), 0
	ldi_erpb 251, 64
	ld wa, 0:i3
	calr FDC_WaitReady_Helper
	jr	FDC_WaitReady_Join
FDC_CONFIG_VERIFY_On1440KMedia:
	ld	(0x8a6c:16), 3
	ldw	(0x8a22:16), 0
	ldi_erpb 251, 64
	ld wa, 0:i3
	calr FDC_WaitReady_Helper
	jr	FDC_WaitReady_Join
FDC_CONFIG_VERIFY_Case4:
	ld	(0x8a6c:16), 4
	ldw	(0x8a22:16), 0
	ldib_erp 251, 0
	ld wa, 2:i3
	calr	FDC_WaitReady_Helper
	jr	FDC_WaitReady_Join
FDC_CONFIG_VERIFY_Case5:
	ld	(0x8a6c:16), 5
	ldw	(0x8a22:16), 0
	ldib_erp 251, 0
	ld wa, 2:i3
	calr	FDC_WaitReady_Helper
	jr	FDC_WaitReady_Join
FDC_WaitReady_Skip11:
	ld	(0x8a6c:16), 0
	ldw	(0x8a22:16), 0
	ldib_erp 251, 0
	ld wa, 2:i3
	calr	FDC_WaitReady_Helper
FDC_WaitReady_Join:
	ldto_berp a, 251
	or a, 11
	extz wa
	calr	FDC_CMD_SEND
	cp	(FDC_ERROR_CODE:16), 0
	jr	z, FDC_WaitReady_Skip12
	ld	(0x8a20:16), 0
	jr	FDC_WaitReady_Epilogue3
FDC_WaitReady_Skip12:
	calr	FDC_CMD_ENABLE
	cp	(FDC_ERROR_CODE:16), 0
	jr	z, FDC_WaitReady_Skip13
	ld	(0x8a20:16), 0
	jr	FDC_WaitReady_Epilogue3
FDC_WaitReady_Skip13:
	calr	FDC_CmdRecalibrate
	ld	(0x8a20:16), 0
FDC_WaitReady_Epilogue3:
	pop	xiz
	ret
FDC_CMD_DISPATCH_SUB:
	ldw	wa, 54
	calr	FDC_Send_Command
	ld	wa, 2:i3
	calr	SOME_DELAY
	calr	FDC_Read_Status
	cp	l, 255
	jr	nz, FDC_CMD_DISPATCH_SUB_Skip14
	ldw	wa, 252
	calr	FDC_Set_Status
FDC_CMD_DISPATCH_SUB_Skip14:
	ld	hl, 0:i3
	ret

; FDC command dispatcher
; Reads command from (8A40h), dispatches to 12 handlers (0-0xb)
; Uses offset table at 0xea98b2
FDC_COMMAND_DISPATCHER:
	ld (0x8a2a:16), 0
	ld wa, (FDC_COMMAND_INDEX:16)
	cp wa, 0xb
	jr ugt, FDC_CheckDriveCount
	add wa, wa
	lda xix, (FDC_COMMAND_DISPATCHER_CaseTable:24)
	ld	wa, (xix+wa)
	lda xix, (FDC_CMD_HANDLER_BASE:24)
	jp	t, (xix+wa)
; FDC command handler base - entry point for command 0
FDC_CMD_HANDLER_BASE:
	calr FDC_SetupFormatParams
	ld l, (FDC_ERROR_CODE:16)
	ret

FDC_ReturnZero:
	ld l, 0x0:opc
	ret

FDC_ErrorInvalidDrive:
	calr FDC_Validate_Drive_Head

FDC_CheckDriveCount:
	ld wa, (0x8a42:16)
	ld (0x8a2a:16), a
	cp (0x8a2a:16), 1
	jr ule, FDC_ValidateCommand
	ldw wa, 0xfe
	jrl FDC_Set_Status

FDC_ValidateCommand:
	ld wa, (FDC_COMMAND_INDEX:16)
	cp wa, 4:i3
	jr z, FDC_ValidateTrack
	cp wa, 3:i3
	jr z, FDC_ValidateTrack
	cp wa, 2:i3
	jr z, FDC_ValidateTrack
	cp wa, 5:i3
	jr z, FDC_Command5Handler
	cp wa, 0xb
	jr z, FDC_NoOpReturn
	cp wa, 1:i3
	jr nz, FDC_ValidateTrack

FDC_NoOpReturn:
	ld l, 0x0:opc
	ret

FDC_Command5Handler:
	calr FDC_Command5_Epilogue
	ld l, (FDC_ERROR_CODE:16)
	ret

FDC_ValidateTrack:
	ld wa, (0x8a46:16)
	ld (0x8a2b:16), a
	ld (FDC_TARGET_TRACK:16), a
	extz wa
	cp wa, (0x8b08:16)
	jr c, FDC_HandleCmd2
	ldw wa, 0xfe
	jrl FDC_Set_Status

FDC_HandleCmd2:
	cpw (FDC_COMMAND_INDEX:16), 2
	jr nz, FDC_CheckSectorCount
	calr FDC_CheckHead
	ld l, (FDC_ERROR_CODE:16)
	ret

FDC_CheckSectorCount:
	cpw (0x8a4a:16), 0
	jr nz, FDC_CheckSectorNum
	ldw wa, 0xfe
	jrl FDC_Set_Status

FDC_CheckSectorNum:
	ld wa, (0x8a48:16)
	ld (0x8a2d:16), a
	cp (0x8a2d:16), 0
	jr nz, FDC_CheckFormatType
	ldw wa, 0xfe
	jrl FDC_Set_Status

FDC_CheckFormatType:
	ld a, (0x8a6c:16)
	cp a, 0:i3
	jr z, FDC_FormatDefault
	cp a, 5:i3
	jr z, FDC_FormatDefault
	cp a, 4:i3
	jr z, FDC_FormatType4
	cp a, 3:i3
	jr z, FDC_FormatType3
	cp a, 2:i3
	jr nz, FDC_ErrorInvalid
	cp (0x8a2d:16), 8
	jr ule, FDC_ValidExecute
	ldw wa, 0xfe
	jrl FDC_Set_Status

FDC_FormatType3:
	cp (0x8a2d:16), 18
	jr ule, FDC_ValidExecute
	ldw wa, 0xfe
	jrl FDC_Set_Status

FDC_FormatType4:
	cp (0x8a2d:16), 255
	jr nz, FDC_Format4Check
	calr FDC_CheckHead
	ld l, (FDC_ERROR_CODE:16)
	ret

FDC_Format4Check:
	cp (0x8a2d:16), 9
	jr ule, FDC_ValidExecute
	ldw wa, 0xfe
	jrl FDC_Set_Status

FDC_FormatDefault:
	cp (0x8a2d:16), 9
	jr ule, FDC_ValidExecute
	ldw wa, 0xfe
	jrl FDC_Set_Status

FDC_ErrorInvalid:
	ldw wa, 0xfe
	jrl FDC_Set_Status

FDC_ValidExecute:
	calr FDC_CheckHead
	ld l, (FDC_ERROR_CODE:16)
	ret

FDC_SetupFormatParams:
	ld wa, (0x8a46:16)
	ld (0x8a6e:16), a
	and a, 0xf
	cp a, 3:i3
	jrl z, FDC_Format1440K
	cp a, 2:i3
	jr z, FDC_FormatDD
	cp a, 5:i3
	jr z, FDC_FormatHD
	cp a, 4:i3
	jr z, FDC_FormatHD
	cp a, 0:i3
	jrl nz, FDC_FormatUnknown

FDC_FormatHD:
	ld (0x8a2e:16), 2
	ld (0x8a35:16), 1
	ld (0x8a2f:16), 9
	ld (0x8a32:16), 9
	ld (0x8a30:16), 27
	ld (0x8a33:16), 84
	ldw (0x8b06:16), 79
	ldw (0x8b08:16), 80
	ldw (0x8b0a:16), 9
	ldw (0x8b0c:16), 10
	jr FDC_InitStateVars

FDC_FormatDD:
	ld (0x8a2e:16), 3
	ld (0x8a35:16), 1
	ld (0x8a2f:16), 8
	ld (0x8a32:16), 8
	ld (0x8a30:16), 83
	ld (0x8a33:16), 116
	ldw (0x8b06:16), 76
	ldw (0x8b08:16), 77
	ldw (0x8b0a:16), 8
	ldw (0x8b0c:16), 9
	jr FDC_InitStateVars

FDC_Format1440K:
	ld (0x8a2e:16), 2
	ld (0x8a35:16), 1
	ld (0x8a2f:16), 18
	ld (0x8a32:16), 18
	ld (0x8a30:16), 27
	ld (0x8a33:16), 108
	ldw (0x8b06:16), 79
	ldw (0x8b08:16), 80
	ldw (0x8b0a:16), 18
	ldw (0x8b0c:16), 19
	jr FDC_InitStateVars

FDC_FormatUnknown:
	ldw wa, 0xfe
	calr FDC_Set_Status

FDC_InitStateVars:
	ld a, (0x8a6e:16)
	srl a, 4
	and a, 0xf
	ld (0x8a37:16), a
	ld (0x8a31:16), 255
	ld (0x8a34:16), 0
	ld (0x8a38:16), 15
	ld (0x8a39:16), 1
	ld (0x8a3c:16), 0
	ld (0x8a3b:16), 0
	ld (0x8a3d:16), 0
	ld (0x8a3e:16), 0
	ld (0x8a3f:16), 0
	ld (0x8a3a:16), 0
	ret

FDC_CheckHead:
	ld wa, (0x8a44:16)
	ld (0x8a2c:16), a
	ld (0x8a29:16), a
	cp (0x8a29:16), 0
	ret z
	cp (0x8a29:16), 1
	ret z
	ldw wa, 0xfe
	calr FDC_Set_Status
	ret

FDC_Command5_Epilogue:
	ret

FDC_Validate_Drive_Head:
	cpw (0x8a44:16), 0
	ret z
	cpw (0x8a44:16), 1
	ret z
	ldw wa, 0xfe
	calr FDC_Set_Status
	ret


FDC_NOP_Delay:
	dec 2, xsp
	ld (xsp), a
	ld a, (xsp)
	decm8 1, (xsp)
	cp a, 0:i3
	jr z, FDC_NOP_Delay_Exit

FDC_NOP_Delay_Loop:
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	ld a, (xsp)
	decm8 1, (xsp)
	cp a, 0:i3
	jr nz, FDC_NOP_Delay_Loop

FDC_NOP_Delay_Exit:
	inc 2, xsp
	ret


FDC_Pulse_PH0:
	set	0, (PH:8)
	ldw wa, 0xa
	calr FDC_NOP_Delay
	res	0, (PH:8)
	ret


FDC_Init_Sequence_1:
	jr	FDC_Port_Reset_Or_Noop


FDC_Port_Reset_Or_Noop:
	ret


FDC_Setup_DMA_Mode:
	ld bc, (FDC_SECTOR_COUNT:16)
	ldc_cr16 bc, 0x4c
	ld a, (0x8a28:16)
	cp a, 0x4d
	jr z, FDC_Setup_DMA_Read_Mode
	cp a, 0xc9
	jr z, FDC_Setup_DMA_Read_Mode
	cp a, 0xc5
	jr z, FDC_Setup_DMA_Read_Mode
	cp a, 0xdd
	jr z, FDC_Setup_DMA_Write_Mode
	cp a, 0xd9
	jr z, FDC_Setup_DMA_Write_Mode
	cp a, 0xd1
	jr z, FDC_Setup_DMA_Write_Mode
	cp a, 0x4a
	jr z, FDC_Setup_DMA_Write_Mode
	cp a, 0x42
	jr z, FDC_Setup_DMA_Write_Mode
	cp a, 0xcc
	jr z, FDC_Setup_DMA_Write_Mode
	cp a, 0xc6
	ret nz

FDC_Setup_DMA_Write_Mode:
	jr FDC_Setup_DMA_Ack_Dest

FDC_Setup_DMA_Read_Mode:
	calr FDC_Setup_DMA_Src_Ack

FDC_DMA_Setup_Exit:
	ret

FDC_Setup_DMA_Ack_Dest:
	ld xhl, 0x120000
	ldc_cr32 xhl, 0x0c
	ld xhl, (0x8a4c:16)
	ldc_cr32 xhl, 0x2c
	ld a, 0x0:opc
	ldc_cr8 a, 0x4e
	jr FDC_Port_Reset_Or_Noop

FDC_Setup_DMA_Src_Ack:
	ld xhl, (0x8a4c:16)
	ldc_cr32 xhl, 0x0c
	ld xhl, 0x120000
	ldc_cr32 xhl, 0x2c
	ld a, 0x8:opc
	ldc_cr8 a, 0x4e
	jr FDC_Port_Reset_Or_Noop
FDC_MC_EXIT_Code_Helper:
	ld bc, (FDC_SECTOR_COUNT:16)
	ldc_cr16 bc, 0x4c
	ret

FDC_Wait_Ready_Timeout:
	push xiz
	ld iz, (SYSTEM_TIMESTAMP:16)
	ldi_erpw 0xfa, 0x80, 0x00
	cp_erpw 0xfa, 0x80, 0x00
	jr nz, FDC_WaitReady_TimedOut

FDC_WaitReady_StatusLoop:
	calr FDC_Read_Status
	res 4, l
	ld a, l
	cp a, 0x80
	jr z, FDC_WaitReady_TimeoutCheck
	cp a, 0xc0
	jr nz, FDC_WaitReady_TimeoutCheck
	ldiw_erp 0xfa, 0

FDC_WaitReady_TimeoutCheck:
	ld wa, (SYSTEM_TIMESTAMP:16)
	sub wa, iz
	cp wa, 0x1f4
	jr ule, FDC_WaitReady_LoopContinue
	ldi_erpw 0xfa, 0xff, 0xff

FDC_WaitReady_LoopContinue:
	cp_erpw 0xfa, 0x80, 0x00
	jr z, FDC_WaitReady_StatusLoop

FDC_WaitReady_TimedOut:
	cpiw_erp 0xfa, 0
	jr z, FDC_WaitReady_Complete
	ld wa, 2:i3
	calr FDC_Set_Status

FDC_WaitReady_Complete:
	pop xiz
	ret


FDC_Wait_Status_Timeout:
	push xiz
	ld iz, (SYSTEM_TIMESTAMP:16)
	ldi_erpw 0xfa, 0x80, 0x00
	cp_erpw 0xfa, 0x80, 0x00
	jr nz, FDC_WaitStatus_TimedOut

FDC_WaitStatus_StatusLoop:
	calr FDC_Read_Status
	and l, 0xe0
	cp l, 0x80
	jr z, FDC_WaitStatus_CheckTimeout
	cp l, 0xc0
	jr nz, FDC_WaitStatus_CheckTimeout
	ldiw_erp 0xfa, 0

FDC_WaitStatus_CheckTimeout:
	ld wa, (SYSTEM_TIMESTAMP:16)
	sub wa, iz
	cp wa, 0x1f4
	jr ule, FDC_WaitStatus_TimeoutCheck
	ldi_erpw 0xfa, 0xff, 0xff

FDC_WaitStatus_TimeoutCheck:
	cp_erpw 0xfa, 0x80, 0x00
	jr z, FDC_WaitStatus_StatusLoop

FDC_WaitStatus_TimedOut:
	cpiw_erp 0xfa, 0
	jr z, FDC_WaitStatus_Complete
	ld wa, 2:i3
	calr FDC_Set_Status

FDC_WaitStatus_Complete:
	pop xiz
	ret


; --- FDC_ResultPhase_Read: Read FDC result phase data into buffer ---
; Reads FDC status register in a loop, checking top 2 bits:
;   0xc0 = command complete, 0x80 = data ready for transfer.
; When data ready, reads byte from FDC and stores to buffer at 35424[index].
; Includes timeout checking against timer at address 1033.
; Contains 6 parameter-passing wrapper stubs at the end, each:
;   dec 2,xsp / ld (xsp),a / calr <func> / ld a,(xsp) / extz wa /
;   calr <store> / inc 2,xsp / ret
; Uses (R+d16) and dec/inc xsp addressing (not in LLVM).
FDC_ResultPhase_Read:
	dec	2, xsp
	push	xiz
	ldw	(xsp+0x4), (SYSTEM_TIMESTAMP)
	ldw qiz, 128
	cpw qiz, 128
	jr	nz, FDC_ResultPhase_Read_Skip2
FDC_ResultPhase_Read_Loop:
	calr	FDC_Read_Status
	res	4, l
	ld	a, l
	cp	a, 192
	jr	z, FDC_ResultPhase_Read_Skip
	cp	a, 128
	jr	nz, FDC_ResultPhase_Read_Join
	ld qiz, 0
	jr FDC_ResultPhase_Read_Join
FDC_ResultPhase_Read_Skip:
	ld	iz, 1:i3
	ld qiz, 0
	cp qiz, 0
	jr nz, FDC_ResultPhase_Read_Join
FDC_ResultPhase_Read_Loop2:
	calr	FDC_ReadDataRegister
	lda	xwa, (0x8a60:16)
	ld	bc, iz
	extz	xbc
	add	xbc, xwa
	ld	(xbc), l
	calr	FDC_Read_Status
	inc	1, iz
	cp qiz, 0
	jr z, FDC_ResultPhase_Read_Loop2
FDC_ResultPhase_Read_Join:
	ld	wa, (SYSTEM_TIMESTAMP:16)
	sub	wa, (xsp+0x4)
	cp	wa, 0x1f4
	jr	ule, FDC_ResultPhase_Read_Skip3
	ldw qiz, 65535
FDC_ResultPhase_Read_Skip3:
	cpw qiz, 128
	jr	z, FDC_ResultPhase_Read_Loop
FDC_ResultPhase_Read_Skip2:
	cp qiz, 0
	jr z, FDC_ResultPhase_Read_Epilogue3
	ld	wa, 3:i3
	calr	FDC_Set_Status
FDC_ResultPhase_Read_Epilogue3:
	pop	xiz
	inc	2, xsp
	ret
; FDC_SendCommandByte: Drains any pending result phase (FDC_ResultPhase_Read) and writes A to the uPD72068 data
;   register 0x11000A -- the first byte of a uPD765-style command. Basis: callers + body + twin -- FDC_CMD_SEND sends
;   every non-auxiliary opcode through it before the parameter bytes; bootloader twin FDC_SendCommandByte.
FDC_SendCommandByte:
	dec	2, xsp
	ld	(xsp), a
	calr	FDC_ResultPhase_Read
	ld	a, (xsp)
	extz	wa
	calr	FDC_WriteDataRegister
	inc	2, xsp
	ret
; FDC_SendParameterByte: Waits (500-tick timeout, status 1) until the main status register shows RQM|CB (0x90) and
;   writes A to the data register 0x11000A -- one command parameter byte. Basis: callers + body + twin -- FDC_CMD_SEND
;   sends the unit/head byte through it and the SPECIFY / SEEK / FORMAT / READ-WRITE parameter senders call it once
;   per byte; bootloader twin FDC_SendParameterByte.
FDC_SendParameterByte:
	dec	2, xsp
	ld	(xsp), a
	calr	FDC_WaitParamByteReady
	ld	a, (xsp)
	extz	wa
	calr	FDC_WriteDataRegister
	inc	2, xsp
	ret
; FDC_WriteAuxCmdByte: Drains any pending result phase (FDC_ResultPhase_Read), then writes A to the uPD72068 auxiliary
;   command register 0x110008 (through FDC_Send_Command). Basis: callers + body + twin -- FDC_SendAuxCmd and
;   FDC_SendAuxCmdReadResult call it after their error check; the bootloader twin with the same body is
;   FDC_WriteAuxCmdByte.
FDC_WriteAuxCmdByte:
	dec	2, xsp
	ld	(xsp), a
	calr	FDC_ResultPhase_Read
	ld	a, (xsp)
	extz	wa
	calr	FDC_Send_Command
	inc	2, xsp
	ret
; FDC_SendAuxCmd: Checked auxiliary-command send: drains the result phase and, if no FDC error is pending, writes A to
;   the auxiliary command register 0x110008 through FDC_WriteAuxCmdByte. Basis: callers + body + twin --
;   FDC_CMD_SEND routes the aux opcodes 0x35, 0x36 and 0x47 here (no result byte); bootloader twin FDC_SendAuxCmd.
FDC_SendAuxCmd:
	dec	2, xsp
	ld	(xsp), a
	calr	FDC_ResultPhase_Read
	cp	(FDC_ERROR_CODE:16), 0
	jr	nz, FDC_SendAuxCmd_Epilogue
	ld	a, (xsp)
	extz	wa
	calr	FDC_WriteAuxCmdByte
FDC_SendAuxCmd_Epilogue:
	inc	2, xsp
	ret
; FDC_SendAuxCmdReadResult: Auxiliary command with a one-byte reply: drains the result phase, and if no error is
;   pending writes A to the aux register 0x110008, waits for the FDC to offer a byte (FDC_Wait_Ready_Timeout, status 2
;   on timeout) and stores the byte read from 0x11000A in 0x8A61. Basis: callers + body + twin -- FDC_CMD_SEND routes
;   the aux opcodes 0x33, 0x34, 0x4F/0x5F (select format), xB (control internal mode) and xE (enable motors) here;
;   bootloader twin FDC_SendAuxCmdReadResult (byte to 0x0C8F).
FDC_SendAuxCmdReadResult:
	dec	2, xsp
	ld	(xsp), a
	calr	FDC_ResultPhase_Read
	cp	(FDC_ERROR_CODE:16), 0
	jr	nz, FDC_SendAuxCmdReadResult_Epilogue2
	ld	a, (xsp)
	extz	wa
	calr	FDC_WriteAuxCmdByte
	calr	FDC_Wait_Ready_Timeout
	calr	FDC_ReadDataRegister
	ld	(0x8a61:16), l
FDC_SendAuxCmdReadResult_Epilogue2:
	inc	2, xsp
	ret

FDC_Exception_Status_Decoder:
	lda xde, (0x8a60:16)
	ld c, (xde + 1)
	ld a, c
	and a, 0xc0
	cp a, 0x40
	jr z, FDC_StatusDecode_AbnormalTerm
	cp a, 0x80
	jr z, FDC_StatusDecode_InvalidCommand
	cp a, 0xc0
	jr z, FDC_StatusDecode_DriveNotReady
	cp a, 0:i3
	jr nz, FDC_StatusDecode_UnknownIC
	ld l, 0x0:opc
	ret

FDC_StatusDecode_DriveNotReady:
	ld (0x8b00:16), 255
	ld l, 0x0:opc
	ret

FDC_StatusDecode_InvalidCommand:
	ld l, 0x0:opc
	ret

FDC_StatusDecode_AbnormalTerm:
	bit 3, c
	jr z, FDC_StatusDecode_Overrun
	ld l, 0x31:opc
	ret

FDC_StatusDecode_Overrun:
	bit 4, c
	jr z, FDC_StatusDecode_CheckST2
	ld l, 0x32:opc
	ret

FDC_StatusDecode_CheckST2:
	ld c, (xde + 2)
	bit 0, c
	jr z, FDC_StatusDecode_BadCylinder
	ldw wa, 0x35
	jrl FDC_Set_Status

FDC_StatusDecode_BadCylinder:
	bit 1, c
	jr z, FDC_StatusDecode_WrongCylinder
	ldw wa, 0x2f
	jrl FDC_Set_Status

FDC_StatusDecode_WrongCylinder:
	bit 2, c
	jr z, FDC_StatusDecode_ScanEqual
	ldw wa, 0x33
	jrl FDC_Set_Status

FDC_StatusDecode_ScanEqual:
	bit 4, c
	jr z, FDC_StatusDecode_DataFieldError
	ldw wa, 0x34
	jrl FDC_Set_Status

FDC_StatusDecode_DataFieldError:
	bit 5, c
	jr z, FDC_StatusDecode_ControlMark
	ldw wa, 0x36
	jrl FDC_Set_Status

FDC_StatusDecode_ControlMark:
	bit 7, c
	jr z, FDC_StatusDecode_DefaultError
	ldw wa, 0x37
	jrl FDC_Set_Status

FDC_StatusDecode_DefaultError:
	ldw wa, 0x8
	jrl FDC_Set_Status

FDC_StatusDecode_UnknownIC:
	ld l, 0x8:opc
	ret


;==================== (guessed) start of floppy routines =======================


; --- FDC_HardwareSetup: Configure FDC I/O ports and validate parameters ---
; Section 1: I/O register initialization (3x ldio/mask/set/store sequences)
;   for FDC-related I/O port configuration.
; Section 2: Format type validation - cascading cp/jr checks against
;   format codes (0x33, 0x34, 0x35, 0x36, 0x47, 0x4f, etc.).
; Section 3: Format parameter loading - sector size, head count,
;   track count from memory locations 35369-35386.
; Section 4: DMA parameter validation - checks that sector count,
;   byte count, buffer pointers are non-zero before proceeding.
; Returns: HL=0xffff on failure, 0 on success.
; Uses ldio, (R+d16) addressing. 460 bytes.
FDC_HardwareSetup:
	ld	(INTCLR:8), 11:io
	lda	xbc, (INTE45:8)
	ld a, (xbc)
	and	a, 248
	set	2, a
	ld	(xbc), a
	ld	(INTCLR:8), 40:io
	lda	xbc, (INTETC23:8)
	ld a, (xbc)
	and	a, 143
	or	a, 80
	ld	(xbc), a
	ld	(INTCLR:8), 12:io
	lda	xbc, (INTE45:8)
	ld a, (xbc)
	and	a, 143
	or	a, 96
	ld	(xbc), a
	ret
FDC_CMD_SEND:
	dec	2, xsp
	ld	(xsp), a
	calr	FDC_WaitReady
	cp	(FDC_ERROR_CODE:16), 0
	jrl	nz, FDC_CMD_SEND_Epilogue
	ld	a, (xsp)
	ld	(0x8a28:16), a
	calr	FDC_ValidateOpcode
	cp	l, 0:i3
	jrl	nz, FDC_CMD_SEND_Epilogue
	ld	a, (xsp)
	cp	a, 51
	jr	z, FDC_CMD_SEND_Skip2
	cp	a, 52
	jr	z, FDC_CMD_SEND_Skip2
	cp	a, 54
	jr	z, FDC_CMD_SEND_Skip
	cp	a, 53
	jr	z, FDC_CMD_SEND_Skip
	cp	a, 71
	jr	nz, FDC_CMD_SEND_Skip3
FDC_CMD_SEND_Skip:
	ld	a, (xsp)
	extz	wa
	calr	FDC_SendAuxCmd
	jrl	FDC_CMD_SEND_Epilogue
FDC_CMD_SEND_Skip2:
	ld	a, (xsp)
	extz	wa
	calr	FDC_SendAuxCmdReadResult
	jrl	FDC_CMD_SEND_Epilogue
FDC_CMD_SEND_Skip3:
	ld	a, (xsp)
	res	4, a
	cp	a, 79
	jr	nz, FDC_CMD_SEND_Skip4
	ld	a, (xsp)
	extz	wa
	calr	FDC_SendAuxCmdReadResult
	jrl	FDC_CMD_SEND_Epilogue
FDC_CMD_SEND_Skip4:
	ld	a, (xsp)
	and	a, 15
	cp	a, 14
	jr	z, FDC_CMD_SEND_Skip5
	ld	a, (xsp)
	and	a, 15
	cp	a, 11
	jr	nz, FDC_CMD_SEND_Skip6
FDC_CMD_SEND_Skip5:
	ld	a, (xsp)
	extz	wa
	calr	FDC_SendAuxCmdReadResult
	jr	FDC_CMD_SEND_Epilogue
FDC_CMD_SEND_Skip6:
	ld	a, (xsp)
	extz	wa
	calr	FDC_SendCommandByte
	cp	(FDC_ERROR_CODE:16), 0
	jr	nz, FDC_CMD_SEND_Epilogue
	cp	(xsp), 8
	jr	z, FDC_CMD_SEND_Epilogue
	cp	(xsp), 3
	jr	nz, FDC_CMD_SEND_Skip7
	calr	FDC_SendParams_Specify
	jr	FDC_CMD_SEND_Epilogue
FDC_CMD_SEND_Skip7:
	ld	a, (0x8a29:16)
	and	a, 1
	sll	a, 2
	ld	e, a
	ld	a, (0x8a2a:16)
	and	a, 3
	ld	c, a
	ld	a, e
	or	a, c
	ld	a, e
	set	0, a
	extz	wa
	calr	FDC_SendParameterByte
	ld	a, (xsp)
	cp	a, 15
	jr	z, FDC_CMD_SEND_Skip10
	cp	a, 77
	jr	z, FDC_CMD_SEND_Skip9
	cp	a, 7:i3
	jr	z, FDC_CMD_SEND_Skip8
	cp	a, 4:i3
	jr	z, FDC_CMD_SEND_Skip8
	cp	a, 74
	jr	nz, FDC_CMD_SEND_Skip11
FDC_CMD_SEND_Skip8:
	jr	FDC_CMD_SEND_Epilogue
FDC_CMD_SEND_Skip9:
	calr	FDC_SendParams_Format
	jr	FDC_CMD_SEND_Epilogue
FDC_CMD_SEND_Skip10:
	calr	FDC_SendParam_SeekTrack
	jr	FDC_CMD_SEND_Epilogue
FDC_CMD_SEND_Skip11:
	calr	FDC_SendParams_ReadWrite
FDC_CMD_SEND_Epilogue:
	inc	2, xsp
	ret
; FDC_ValidateOpcode: Checks the opcode in 0x8A28: L = 0 for the aux opcodes 0x4F/0x33/0x34/0x47/0x35 and for opcodes
;   whose low 5 bits are 0x02-0x0F, 0x11, 0x19, 0x1D or 0x1E (0x10 excluded); L = 1 otherwise. Basis: callers + body +
;   twin -- FDC_CMD_SEND stores the opcode, calls it and returns at once when L != 0; bootloader twin
;   FDC_ValidateOpcode.
FDC_ValidateOpcode:
	ld	a, (0x8a28:16)
	cp	a, 79
	jr	z, FDC_ValidateOpcode_Skip12
	cp	a, 51
	jr	z, FDC_ValidateOpcode_Skip12
	cp	a, 52
	jr	z, FDC_ValidateOpcode_Skip12
	cp	a, 71
	jr	z, FDC_ValidateOpcode_Skip12
	cp	a, 53
	jr	nz, FDC_ValidateOpcode_Skip13
FDC_ValidateOpcode_Skip12:
	ld	l, 0:opc
	ret
FDC_ValidateOpcode_Skip13:
	ld	a, (0x8a28:16)
	and	a, 31
	cp	a, 30
	jr	z, FDC_ValidateOpcode_Skip14
	cp	a, 29
	jr	z, FDC_ValidateOpcode_Skip14
	cp	a, 25
	jr	z, FDC_ValidateOpcode_Skip14
	cp	a, 16
	jr	z, FDC_ValidateOpcode_Skip15
	cp	a, 17
	jr	z, FDC_ValidateOpcode_Skip14
	cp	a, 15
	jr	ugt, FDC_ValidateOpcode_Skip15
	cp	a, 2:i3
	jr	c, FDC_ValidateOpcode_Skip15
FDC_ValidateOpcode_Skip14:
	ld	l, 0:opc
	ret
FDC_ValidateOpcode_Skip15:
	ld	l, 1:opc
	ret
FDC_HardwareSetup_Join:
	ld	a, (0x8a35:16)
	and	a, 3
	extz	wa
	jrl	FDC_SendParameterByte
; FDC_SendParams_Specify: Sends the two SPECIFY parameter bytes: SRT<<4 | HUT (0x8A37, 0x8A38 & 0x0F) and HLT<<1 | ND
;   (0x8A39, 0x8A3A & 1), each through FDC_SendParameterByte. Basis: callers + body + twin -- FDC_CMD_SEND calls it
;   for opcode 3 (SPECIFY) right after the command byte; bootloader twin FDC_SendParams_Specify.
FDC_SendParams_Specify:
	ld	a, (0x8a37:16)
	sll	a, 4
	ld	e, a
	ld	a, (0x8a38:16)
	and	a, 15
	ld	c, a
	ld	a, e
	or	a, c
	extz	wa
	calr	FDC_SendParameterByte
	ld	a, (0x8a39:16)
	sll	a, 1
	ld	e, a
	ld	a, (0x8a3a:16)
	and	a, 1
	ld	c, a
	ld	a, e
	or	a, c
	extz	wa
	jrl	FDC_SendParameterByte
; FDC_SendParams_Format: Sends the FORMAT TRACK parameters N (0x8A2E & 7), SC (0x8A32), GPL (0x8A33) and filler D
;   (0x8A34) through FDC_SendParameterByte. Basis: callers + body + twin -- FDC_CMD_SEND calls it for opcode 0x4D
;   (FORMAT TRACK) after the unit/head byte; FDC_MODE_CONFIG fills 0x8A2E/0x8A33/0x8A34 (N, gap 80/108/116, fill
;   0xE5); bootloader twin FDC_SendParams_Format.
FDC_SendParams_Format:
	ld	a, (0x8a2e:16)
	and	a, 7
	extz	wa
	calr	FDC_SendParameterByte
	ld	a, (0x8a32:16)
	extz	wa
	calr	FDC_SendParameterByte
	ld	a, (0x8a33:16)
	extz	wa
	calr	FDC_SendParameterByte
	ld	a, (0x8a34:16)
	extz	wa
	jrl	FDC_SendParameterByte
; FDC_SendParam_SeekTrack: Sends the SEEK target track NCN (FDC_TARGET_TRACK, 0x8A36) through FDC_SendParameterByte.
;   Basis: callers + body + twin -- FDC_CMD_SEND calls it for opcode 0x0F (SEEK) after the unit/head byte, as issued
;   by FDC_CmdSeek; bootloader twin FDC_SendParam_SeekTrack.
FDC_SendParam_SeekTrack:
	ld	a, (FDC_TARGET_TRACK:16)
	extz	wa
	jrl	FDC_SendParameterByte
; FDC_SendParams_ReadWrite: Sends the data-command parameters C (0x8A2B), H (0x8A2C & 1), R (0x8A2D), N (0x8A2E & 7),
;   EOT (0x8A2F), GPL (0x8A30), then DTL (0x8A31) -- or STP ((0x8A35) & 3) for the scan opcodes 0xD1/0xD9/0xDD --
;   through FDC_SendParameterByte. Basis: callers + body + twin -- FDC_CMD_SEND calls it for every opcode not handled
;   earlier (READ/WRITE DATA 0xC6/0xC5 among them); bootloader twin FDC_SendParams_ReadWrite.
FDC_SendParams_ReadWrite:
	ld	a, (0x8a2b:16)
	extz	wa
	calr	FDC_SendParameterByte
	ld	a, (0x8a2c:16)
	and	a, 1
	extz	wa
	calr	FDC_SendParameterByte
	ld	a, (0x8a2d:16)
	extz	wa
	calr	FDC_SendParameterByte
	ld	a, (0x8a2e:16)
	and	a, 7
	extz	wa
	calr	FDC_SendParameterByte
	ld	a, (0x8a2f:16)
	extz	wa
	calr	FDC_SendParameterByte
	ld	a, (0x8a30:16)
	extz	wa
	calr	FDC_SendParameterByte
	ld	a, (0x8a28:16)
	cp	a, 221
	jr	z, FDC_SendParams_ReadWrite_Skip16
	cp	a, 217
	jr	z, FDC_SendParams_ReadWrite_Skip16
	cp	a, 209
	jr	nz, FDC_SendParams_ReadWrite_Skip17
FDC_SendParams_ReadWrite_Skip16:
	jrl	FDC_HardwareSetup_Join
FDC_SendParams_ReadWrite_Skip17:
	ld	a, (0x8a31:16)
	extz	wa
	calr	FDC_SendParameterByte
	ret
FDC_DETECT_CHECK:
	cpw	(0x8a46:16), 0
	jr	z, FDC_HardwareSetup_Entry
	ld	hl, 0:i3
	ret
FDC_HardwareSetup_Entry:
	cpw	(0x8a44:16), 0
	jr	z, FDC_HardwareSetup_Entry_Skip
	ld	hl, 0:i3
	ret
FDC_HardwareSetup_Entry_Skip:
	cpw	(FDC_COMMAND_INDEX:16), 3
	jr	z, FDC_HardwareSetup_Entry_Skip2
	ld	hl, 0:i3
	ret
FDC_HardwareSetup_Entry_Skip2:
	cpw	(0x8a4a:16), 1
	jr	z, FDC_HardwareSetup_Entry_Skip3
	ld	hl, 0:i3
	ret
FDC_HardwareSetup_Entry_Skip3:
	cpw	(0x8a10:16), 0xffff
	jr	z, FDC_HardwareSetup_Entry_Skip4
	ld	hl, 0:i3
	ret
FDC_HardwareSetup_Entry_Skip4:
	cpw	(0x8a48:16), 1
	jr	z, FDC_HardwareSetup_Entry_Skip5
	ld	hl, 0:i3
	ret
FDC_HardwareSetup_Entry_Skip5:
	ldw	hl, 0xffff
	ret
FDC_DRIVE_DETECT:
	cpw	(0x8a46:16), 0
	jr	z, FDC_DRIVE_DETECT_Skip
	ld	hl, 0:i3
	ret
FDC_DRIVE_DETECT_Skip:
	cpw	(0x8a44:16), 0
	jr	z, FDC_DRIVE_DETECT_Skip2
	ld	hl, 0:i3
	ret
FDC_DRIVE_DETECT_Skip2:
	cpw	(FDC_COMMAND_INDEX:16), 3
	jr	z, FDC_DRIVE_DETECT_Skip3
	ld	hl, 0:i3
	ret
FDC_DRIVE_DETECT_Skip3:
	cpw	(0x8a4a:16), 1
	jr	z, FDC_DRIVE_DETECT_Skip4
	ld	hl, 0:i3
	ret
FDC_DRIVE_DETECT_Skip4:
	cpw	(0x8a10:16), 0xffff
	jr	z, FDC_DRIVE_DETECT_Skip5
	ld	hl, 0:i3
	ret
FDC_DRIVE_DETECT_Skip5:
	cpw	(0x8a48:16), 2
	jr	z, FDC_DRIVE_DETECT_Skip6
	cpw	(0x8a48:16), 255
	jr	nz, FDC_DRIVE_DETECT_Skip7
FDC_DRIVE_DETECT_Skip6:
	ldw	hl, 0xffff
	ret
FDC_DRIVE_DETECT_Skip7:
	ld	hl, 0:i3
	ret
FDC_DRIVE_STATUS:
	cpw	(0x8a4a:16), 0xffff
	jr	z, FDC_DRIVE_STATUS_Skip8
	ld	hl, 0:i3
	ret
FDC_DRIVE_STATUS_Skip8:
	cpw	(FDC_COMMAND_INDEX:16), 0
	jr	z, FDC_DRIVE_STATUS_Skip9
	ld	hl, 0:i3
	ret
FDC_DRIVE_STATUS_Skip9:
	ldw	hl, 0xffff
	ret
FDC_PRE_OP_CHECK:
	ret

FDC_Set_Status:
	cp (FDC_ERROR_CODE:16), 0
	jr nz, FDC_SetStatus_AlreadySet
	ld (FDC_ERROR_CODE:16), a
	cp a, 0x36
	jr z, FDC_SetStatus_DataFieldErr
	cp a, 0x35
	jr z, FDC_SetStatus_MissingAddrMark
	cp a, 0x33
	jr nz, FDC_SetStatus_Return
	nop
	jr FDC_SetStatus_Return

FDC_SetStatus_MissingAddrMark:
	nop
	jr FDC_SetStatus_Return

FDC_SetStatus_DataFieldErr:
	nop
	jr FDC_SetStatus_Return

FDC_SetStatus_AlreadySet:
	nop

FDC_SetStatus_Return:
	ld l, (FDC_ERROR_CODE:16)
	ret


; --- FDC_ClearStatus_InitTimer: Clear FDC status and start timeout ---
; Clears FDC status byte (35364) to 0, initializes result buffer (35424)
; to 0xff, saves prevbank state, starts timer-based timeout loop.
; Polls with cps bc, 0 for completion signal.
; Uses prevbank (D7 FA) for timer state management.
FDC_ClearStatus_InitTimer:
	ld	(FDC_ERROR_CODE:16), 0
	ret
FDC_TIMING_DELAY:
	ld	(0x8a60:16), 255
	ret
FDC_POST_OP:
	push	xiz
	ldw	qiz, 0x1f4
	ldw_d16	iz, (SYSTEM_TIMESTAMP)
	ld	bc, 0:i3
FDC_POST_OP_Loop:
	cp	(0x8a60:16), 255
	jr	z, FDC_POST_OP_Skip
	ldw	bc, 0xffff
FDC_POST_OP_Skip:
	ld	wa, (SYSTEM_TIMESTAMP:16)
	sub	wa, iz
	cp wa, qiz
	jr	ule, FDC_POST_OP_Skip2
	ldw	wa, 9
	calr	FDC_Set_Status
	ldw	bc, 0xffff
FDC_POST_OP_Skip2:
	cp	bc, 0:i3
	jr	z, FDC_POST_OP_Loop
	pop	xiz
	ret


SOME_DELAY:
	srl wa, 1
	ld de, (SYSTEM_TIMESTAMP:16)
	ld hl, 0:i3
	cp hl, 0xffff
	ret nc

SOME_DELAY_Loop:
	ld bc, (SYSTEM_TIMESTAMP:16)
	sub bc, de
	cp bc, wa
	ret ugt
	inc 1, hl
	cp hl, 0xffff
	jr c, SOME_DELAY_Loop
	ret


FDC_InitSequence_Short:
	ldw	wa, 40
	jr	SOME_DELAY

FDC_InitSequence_Full:
	calr FDC_Init_Sequence_1
	calr FDC_Pulse_PH0
	ld (0x8a6a:16), 0
	ld (0x8b00:16), 0
	calr FDC_HardwareSetup
	calr FDC_INIT
	jrl FDC_CONFIG_VERIFY

; --- FDC_CmdRecalibrate (formerly FDC_SeekRecalibrate): recalibrate to track 0 ---
; Renamed to match its bootloader twin FDC_CmdRecalibrate (table_data/
; boot_fdc_driver.s): saves the caller's target track (0x8a36) in QIZH, seeks
; to track 5 first (head-load settling), then issues RECALIBRATE (0x07) and
; waits for the result; on failure invalidates the track cache (0x8b04).
; The raw block below also contains the SEEK command handler at 0xf97696,
; reached through the .set alias FDC_CmdSeek (renamed from the misnomer
; FDC_STATUS_HANDLER -- it reads and writes no status register).  Verified
; instruction-for-instruction against its bootloader twin FDC_CmdSeek in
; table_data/boot_fdc_driver.s: compare the target track (0x8a36) against
; the track cache (0x8b04) and return if equal, delay (WA=2), clear the
; result buffer, LD WA,0x000F (= FDC SEEK opcode 0x0F), issue the command,
; wait for the result, set the track cache to 0xFF on error, then settle
; (WA=0x10; the delay routine busy-waits WA/2 ticks).
; [INFERENCE] The neighbouring .set aliases FDC_TIMING_DELAY (0xf975dc) and
; FDC_POST_OP (0xf975e2) look like the same class of misnomer; they were
; not re-checked in this pass.
FDC_CmdRecalibrate:
	push	qiz
	ld	a, (FDC_TARGET_TRACK:16)
	ldfr_berp a, 251
	ld	(FDC_TARGET_TRACK:16), 5
	ld	(0x8b04:16), 255
	calr	FDC_CmdSeek
	ld	(0x8b04:16), 0
	calr	FDC_TIMING_DELAY
	ld	wa, 7:i3
	calr	FDC_CMD_SEND
	calr	FDC_POST_OP
	cp	(FDC_ERROR_CODE:16), 0
	jr	z, FDC_CmdRecalibrate_Skip
	ld	(0x8b04:16), 255
FDC_CmdRecalibrate_Skip:
	ldto_berp a, 251
	ld	(FDC_TARGET_TRACK:16), a
	ldw	wa, 16
	calr	SOME_DELAY
	pop qiz
	ret
FDC_CmdSeek:
	ld	a, (FDC_TARGET_TRACK:16)
	cp	a, (35588:16)
	ret	z
	ldmm8	0x8b04, FDC_TARGET_TRACK
	ld	wa, 2:i3
	calr	SOME_DELAY
	calr	FDC_TIMING_DELAY
	ldw	wa, 15
	calr	FDC_CMD_SEND
	calr	FDC_POST_OP
	cp	(FDC_ERROR_CODE:16), 0
	jr	z, FDC_CmdSeek_Skip
	ld	(0x8b04:16), 255
FDC_CmdSeek_Skip:
	ldw	wa, 16
	jrl	SOME_DELAY
; FDC_SubmitReadDataCmd: Issues MT|MF READ DATA (0xC6): stores the opcode in 0x8A28, arms DMA channel 3 for
;   I/O->memory (FDC_Setup_DMA_Mode), clears the result buffer (FDC_TIMING_DELAY), sends the command with FDC_CMD_SEND
;   and, if no error, waits for the result (FDC_POST_OP). Basis: callers + body + twin -- FDC_CMD_EXEC (read sectors,
;   FDC command 3) calls it per same-track burst; instruction twin of the bootloader's FDC_SubmitReadDataCmd.
FDC_SubmitReadDataCmd:
	ld	(0x8a28:16), 198
	calr	FDC_Setup_DMA_Mode
	calr	FDC_TIMING_DELAY
	ldw	wa, 198
	calr	FDC_CMD_SEND
	cp	(FDC_ERROR_CODE:16), 0
	ret	nz
	jrl	FDC_POST_OP
; --- FDC_CMD_EXEC: Main FDC command execution engine ---
; Two nearly identical halves: READ path (command type 1) and
; WRITE path (command type 8), set in state variable 35432.
; Each path:
;   1. Clears status, waits for FDC ready
;   2. Sets up DMA: clear byte counter (35356), compute sector size
;      (1024 or 512 based on format), configure DMA direction
;   3. Sector loop: decrement sector count, advance track/head,
;      check against max sectors (35596)
;   4. Accumulates transferred sector count at 35402
;   5. Error handling: sets error flag (35588=255) on failure
; Tail calls format-specific routines and status verification.
; Uses (R+d16) addressing for all FDC state variable access. 672 bytes.
FDC_CMD_EXEC:
	pushw	iz
	calr	FDC_DETECT_CHECK
	cp	hl, 0:i3
	jr	z, FDC_CMD_EXEC_Skip
	ld	(0x8a68:16), 1
	jrl	FDC_CE_DISPATCH
FDC_CMD_EXEC_Skip:
	calr	FDC_DRIVE_DETECT
	cp	hl, 0:i3
	jr	nz, FDC_CMD_EXEC_Skip2
	ld	(0x8a68:16), 8
	jrl	FDC_CE_DISPATCH
FDC_CMD_EXEC_Skip2:
	ld	(0x8a68:16), 1
	jrl	FDC_CE_DISPATCH
FDC_CMD_EXEC_Loop:
	ld	(FDC_ERROR_CODE:16), 0
	calr	FDC_CmdSeek
	cp	(FDC_ERROR_CODE:16), 0
	jr	z, FDC_CMD_EXEC_Skip3
	ld	a, (FDC_ERROR_CODE:16)
	ldfr_berp a, 248
	exts	iz
	calr	FDC_CONFIG_VERIFY
	ldto_berp	a, 248
	stb_d8	(FDC_ERROR_CODE), a
	jrl	FDC_CE_EXIT
FDC_CMD_EXEC_Skip3:
	ldw_d16	wa, (0x8a48)
	cp	wa, (0x8b0c:16)
	jr	ule, FDC_CMD_EXEC_Skip4
	ldw	(0x8a48:16), 1
FDC_CMD_EXEC_Skip4:
	ldmm16	0x8b10, 0x8a48
	ldw	(FDC_SECTOR_COUNT:16), 0
	cp	(0x8a6c:16), 2
	jr	nz, FDC_CMD_EXEC_Skip5
	ldw	(0x8a1e:16), 1024
	jr	FDC_CMD_EXEC_Join
FDC_CMD_EXEC_Skip5:
	ldw	(0x8a1e:16), 512
FDC_CMD_EXEC_Join:
	ldmm16	0x8b12, 0x8a4a
	ld	iz, 1:i3
FDC_CMD_EXEC_Join2:
	ld	wa, (0x8a1e:16)
	add	(FDC_SECTOR_COUNT:16), wa
	lda	xwa, (0x8a4a:16)
	decm	1, (xwa)
	ld	wa, (xwa)
	cp	wa, 0:i3
	jr	z, FDC_CMD_EXEC_Skip6
	lda	xwa, (0x8a48:16)
	incw	1, (xwa)
	ld	wa, (xwa)
	cp	wa, (0x8b0c:16)
	jr	ugt, FDC_CMD_EXEC_Skip6
	inc	1, iz
	jr	FDC_CMD_EXEC_Join2
FDC_CMD_EXEC_Skip6:
	ld	(0x8a4a:16), iz
	ldmm16	0x8a48, 0x8b10
	calr	FDC_SubmitReadDataCmd
	cp	(FDC_ERROR_CODE:16), 0
	jr	z, FDC_CMD_EXEC_Skip8
	cp	(FDC_ERROR_CODE:16), 9
	jr	nz, FDC_CMD_EXEC_Skip7
	calr	FDC_INIT
	jrl	FDC_CE_EXIT
FDC_CMD_EXEC_Skip7:
	calr	FDC_DRIVE_DETECT
	cp	hl, 0xffff
	jr	z, FDC_CMD_EXEC_Entry
	calr	FDC_CONFIG_VERIFY
	ld	(0x8b04:16), 255
	calr	FDC_CmdSeek
FDC_CMD_EXEC_Entry:
	ldmm16	0x8a4a, 0x8b12
	dec	1, (0x8a68:16)
	ldb_d8	a, (0x8a68)
	cp	a, 0:i3
	jr	nz, FDC_CE_DISPATCH
	ld	(FDC_ERROR_CODE:16), 16
	jr	FDC_CE_EXIT
FDC_CMD_EXEC_Skip8:
	ld	wa, (0x8b12:16)
	sub	wa, iz
	ld	(0x8a4a:16), wa
	cpw	(0x8a4a:16), 0
	jr	z, FDC_CE_DISPATCH
	lda	xbc, (0x8a4c:16)
	ld	wa, (FDC_SECTOR_COUNT:16)
	extz	xwa
	add	xwa, (xbc)
	ld	(xbc), xwa
	ldw	(0x8a48:16), 1
	ld	(0x8a2d:16), 1
	ld	a, (0x8a29:16)
	xor	a, 1
	ld	(0x8a29:16), a
	ld	(0x8a2c:16), a
	cp	(0x8a2c:16), 0
	jr	nz, FDC_CE_DISPATCH
	lda	xwa, (0x8a2b:16)
	incm8	1, (xwa)
	ld	a, (xwa)
	ld	(FDC_TARGET_TRACK:16), a
FDC_CE_DISPATCH:
	cpw	(0x8a4a:16), 0
	jrl	nz, FDC_CMD_EXEC_Loop
FDC_CE_EXIT:
	popw	iz
	ret
FDC_SECTOR_XFER:
	pushw	iz
	ld	(0x8a68:16), 8
	jrl	FDC_SECTOR_XFER_Join5
FDC_SECTOR_XFER_Loop2:
	ld	(FDC_ERROR_CODE:16), 0
	calr	FDC_CmdSeek
	cp	(FDC_ERROR_CODE:16), 0
	jr	z, FDC_SECTOR_XFER_Skip9
	ld	a, (FDC_ERROR_CODE:16)
	ldfr_berp a, 248
	exts	iz
	calr	FDC_CONFIG_VERIFY
	ldto_berp	a, 248
	stb_d8	(FDC_ERROR_CODE), a
	jrl	FDC_SECTOR_XFER_Epilogue2
FDC_SECTOR_XFER_Skip9:
	ldw_d16	wa, (0x8a48)
	cp	wa, (0x8b0c:16)
	jr	ule, FDC_SECTOR_XFER_Skip10
	ldw	(0x8a48:16), 1
FDC_SECTOR_XFER_Skip10:
	ldmm16	0x8b10, 0x8a48
	ldw	(FDC_SECTOR_COUNT:16), 0
	cp	(0x8a6c:16), 2
	jr	nz, FDC_SECTOR_XFER_Skip11
	ldw	(0x8a1e:16), 1024
	jr	FDC_SECTOR_XFER_Join3
FDC_SECTOR_XFER_Skip11:
	ldw	(0x8a1e:16), 512
FDC_SECTOR_XFER_Join3:
	ldmm16	0x8b12, 0x8a4a
	ld	iz, 1:i3
FDC_SECTOR_XFER_Join4:
	ld	wa, (0x8a1e:16)
	add	(FDC_SECTOR_COUNT:16), wa
	lda	xwa, (0x8a4a:16)
	decm	1, (xwa)
	ld	wa, (xwa)
	cp	wa, 0:i3
	jr	z, FDC_SECTOR_XFER_Skip12
	lda	xwa, (0x8a48:16)
	incw	1, (xwa)
	ld	wa, (xwa)
	cp	wa, (0x8b0c:16)
	jr	ugt, FDC_SECTOR_XFER_Skip12
	inc	1, iz
	jr	FDC_SECTOR_XFER_Join4
FDC_SECTOR_XFER_Skip12:
	ld	(0x8a4a:16), iz
	ldmm16	0x8a48, 0x8b10
	calr	FDC_SubmitWriteDataCmd
	cp	(FDC_ERROR_CODE:16), 0
	jr	z, FDC_SECTOR_XFER_Skip14
	cp	(FDC_ERROR_CODE:16), 9
	jr	nz, FDC_SECTOR_XFER_Skip13
	calr	FDC_INIT
	calr	FDC_CONFIG_VERIFY
	jrl	FDC_SECTOR_XFER_Epilogue2
FDC_SECTOR_XFER_Skip13:
	cp	(FDC_ERROR_CODE:16), 47
	jr	z, FDC_SECTOR_XFER_Epilogue2
	calr	FDC_CONFIG_VERIFY
	ld	(0x8b04:16), 255
	calr	FDC_CmdSeek
	ldmm16	0x8a4a, 0x8b12
	dec	1, (0x8a68:16)
	ldb_d8	a, (0x8a68)
	cp	a, 0:i3
	jr	nz, FDC_SECTOR_XFER_Join5
	ld	(FDC_ERROR_CODE:16), 32
	jr	FDC_SECTOR_XFER_Epilogue2
FDC_SECTOR_XFER_Skip14:
	ld	wa, (0x8b12:16)
	sub	wa, iz
	ld	(0x8a4a:16), wa
	cpw	(0x8a4a:16), 0
	jr	z, FDC_SECTOR_XFER_Join5
	lda	xbc, (0x8a4c:16)
	ld	wa, (FDC_SECTOR_COUNT:16)
	extz	xwa
	add	xwa, (xbc)
	ld	(xbc), xwa
	ldw	(0x8a48:16), 1
	ld	(0x8a2d:16), 1
	ld	a, (0x8a29:16)
	xor	a, 1
	ld	(0x8a29:16), a
	ld	(0x8a2c:16), a
	cp	(0x8a2c:16), 0
	jr	nz, FDC_SECTOR_XFER_Join5
	lda	xwa, (0x8a2b:16)
	incm8	1, (xwa)
	ld	a, (xwa)
	ld	(FDC_TARGET_TRACK:16), a
FDC_SECTOR_XFER_Join5:
	cpw	(0x8a4a:16), 0
	jrl	nz, FDC_SECTOR_XFER_Loop2
FDC_SECTOR_XFER_Epilogue2:
	popw	iz
	ret
; FDC_SubmitWriteDataCmd: Issues MT|MF WRITE DATA (0xC5): stores the opcode in 0x8A28, arms DMA channel 3 for
;   memory->I/O (FDC_Setup_DMA_Mode), clears the result buffer, sends the command with FDC_CMD_SEND and, if no error,
;   waits for the result (FDC_POST_OP). Basis: callers + body + twin -- FDC_SECTOR_XFER (write sectors, FDC command 4)
;   calls it per burst; instruction twin of the bootloader's FDC_SubmitWriteDataCmd.
FDC_SubmitWriteDataCmd:
	ld	(0x8a28:16), 197
	calr	FDC_Setup_DMA_Mode
	calr	FDC_TIMING_DELAY
	ldw	wa, 197
	calr	FDC_CMD_SEND
	cp	(FDC_ERROR_CODE:16), 0
	ret	nz
	jrl	FDC_POST_OP
; --- FDC_MODE_CONFIG: Configure FDC format parameters by disk type ---
; Reads format type from state variable 35436.
; Dispatch by type: 0=default, 2=MFM, 3/4/5 = other formats.
; Sets per-format parameters:
;   35374: sectors per track (2 or 3)
;   35379: bytes per sector code (80/108/116 = 128/256/512 bytes)
;   35382: head number, 35371: track number, 35380: gap length (0xe5)
;   35372: side number, 35369: drive number
; Then enters sector counting/validation loop.
; Uses (R+d16) addressing for all state variables. 184 bytes.
FDC_MODE_CONFIG:
	calr	FDC_PRE_OP_CHECK
	cp	(FDC_ERROR_CODE:16), 0
	jrl	nz, FDC_MC_EXIT
	calr	FDC_INTERRUPT_HANDLER
	cp	(FDC_ERROR_CODE:16), 0
	jrl	nz, FDC_MC_EXIT
	calr	FDC_CmdRecalibrate
	cp	(FDC_ERROR_CODE:16), 0
	jrl	nz, FDC_MC_EXIT
	ld	a, (0x8a6c:16)
	cp	a, 2:i3
	jr	z, FDC_MODE_CONFIG_Skip3
	cp	a, 3:i3
	jr	z, FDC_MODE_CONFIG_Skip2
	cp	a, 5:i3
	jr	z, FDC_MODE_CONFIG_Skip
	cp	a, 4:i3
	jr	z, FDC_MODE_CONFIG_Skip
	cp	a, 0:i3
	jr	nz, FDC_MODE_CONFIG_Join
FDC_MODE_CONFIG_Skip:
	ld	(0x8a2e:16), 2
	ld	(0x8a33:16), 80
	jr	FDC_MODE_CONFIG_Join
FDC_MODE_CONFIG_Skip2:
	ld	(0x8a2e:16), 2
	ld	(0x8a33:16), 108
	jr	FDC_MODE_CONFIG_Join
FDC_MODE_CONFIG_Skip3:
	ld	(0x8a2e:16), 3
	ld	(0x8a33:16), 116
FDC_MODE_CONFIG_Join:
	ld	(FDC_TARGET_TRACK:16), 0
	ld	(0x8a2b:16), 0
	ld	(0x8a34:16), 229
	ld	(0x8a2c:16), 0
	ld	(0x8a29:16), 0
	jr	FDC_MODE_CONFIG_Join2
FDC_MODE_CONFIG_Entry:
	ldmm8	0x8a12, FDC_TARGET_TRACK
	calr	FDC_MODE_CONFIG_Helper2
	cp	(FDC_ERROR_CODE:16), 0
	jr	nz, FDC_MC_EXIT
	ld	a, (0x8a29:16)
	xor	a, 1
	ld	(0x8a29:16), a
	ld	(0x8a2c:16), a
	cp	(0x8a2c:16), 0
	jr	nz, FDC_MODE_CONFIG_Join2
	lda	xwa, (0x8a2b:16)
	incm8	1, (xwa)
	ld	a, (xwa)
	ld	(FDC_TARGET_TRACK:16), a
	ld	(0x8a12:16), a
FDC_MODE_CONFIG_Join2:
	ld	a, (FDC_TARGET_TRACK:16)
	extz	wa
	cp wa, (35592:16)
	jr	ule, FDC_MODE_CONFIG_Entry
; --- FDC_MC_EXIT: FORMAT command execution and sector fill ---
; Calls cleanup, sets up FORMAT command (command byte 0x4d).
; Loads format buffer address from 35440, stores to DMA source (35404).
; Main loop fills format buffer with [track, head, sector, size] tuples:
;   For each sector: load index, compute buffer[index] address,
;   store track/head/sector/size bytes, increment byte count (35356).
; Handles odd sector counts separately.
; Tail: DMA transfer initiation and multi-sector retry logic.
; Uses (R+d16) addressing for buffer and state access. 536 bytes.
FDC_MC_EXIT:
	cp	(FDC_ERROR_CODE:16), 0
	call	nz, (FDC_CONFIG_VERIFY:24)
	calr	FDC_CmdRecalibrate
	ld	(0x8b04:16), 255
	ret
FDC_MODE_CONFIG_Helper2:
	calr	FDC_CmdSeek
	cp	(FDC_ERROR_CODE:16), 0
	jrl	nz, FDC_CONFIG_VERIFY
	calr	FDC_MC_EXIT_Code_Helper2
	ld	(0x8a28:16), 77
	lda	xwa, (0x8a70:16)
	ld	(0x8a4c:16), xwa
	calr	FDC_Setup_DMA_Mode
	calr	FDC_MC_EXIT_Code_Helper
	jrl	FDC_MC_EXIT_Code_Join2
FDC_MC_EXIT_Code_Helper2:
	ld	(0x8a2d:16), 1
	ldw	(FDC_SECTOR_COUNT:16), 0
	ld	ix, (0x8b0a:16)
	srl	ix, 1
	ld	e, 0:opc
	ld	iy, 0:i3
	cp	iy, ix
	jrl	nc, FDC_MC_EXIT_Code_Skip2
FDC_MC_EXIT_Code_Loop:
	ld	a, e
	inc	1, e
	extz	wa
	lda	xbc, (0x8a70:16)
	ld	hl, wa
	extz	xhl
	add	xhl, xbc
	ld	a, (0x8a2b:16)
	ld	(xhl), a
	incw	1, (FDC_SECTOR_COUNT:16)
	ld	a, e
	inc	1, e
	extz	wa
	lda	xbc, (0x8a70:16)
	ld	hl, wa
	extz	xhl
	add	xhl, xbc
	ld	a, (0x8a2c:16)
	ld	(xhl), a
	incw	1, (FDC_SECTOR_COUNT:16)
	ld	a, e
	inc	1, e
	extz	wa
	lda	xbc, (0x8a70:16)
	ld	hl, wa
	extz	xhl
	add	xhl, xbc
	ld	a, (0x8a2d:16)
	ld	(xhl), a
	incw	1, (FDC_SECTOR_COUNT:16)
	ld	a, e
	inc	1, e
	extz	wa
	lda	xbc, (0x8a70:16)
	ld	hl, wa
	extz	xhl
	add	xhl, xbc
	ld	a, (0x8a2e:16)
	ld	(xhl), a
	incw	1, (FDC_SECTOR_COUNT:16)
	ld	a, e
	inc	1, e
	extz	wa
	lda	xbc, (0x8a70:16)
	ld	hl, wa
	extz	xhl
	add	xhl, xbc
	ld	a, (0x8a2b:16)
	ld	(xhl), a
	incw	1, (FDC_SECTOR_COUNT:16)
	ld	a, e
	inc	1, e
	extz	wa
	lda	xbc, (0x8a70:16)
	ld	hl, wa
	extz	xhl
	add	xhl, xbc
	ld	a, (0x8a2c:16)
	ld	(xhl), a
	incw	1, (FDC_SECTOR_COUNT:16)
	cpw	(0x8a46:16), 0
	jr	nz, FDC_MC_EXIT_Code_Skip
	inc	1, (0x8a2d:16)
	ld	a, e
	inc	1, e
	extz	wa
	lda	xbc, (0x8a70:16)
	ld	hl, wa
	extz	xhl
	add	xhl, xbc
	ld	a, (0x8a2d:16)
	ld	(xhl), a
	jr	FDC_MC_EXIT_Code_Join
FDC_MC_EXIT_Code_Skip:
	ld	wa, (0x8b0a:16)
	srl	wa, 1
	add	a, (0x8a2d:16)
	ld	l, a
	ld	a, e
	inc	1, e
	extz	wa
	lda	xbc, (0x8a70:16)
	extz	xwa
	add	xwa, xbc
	ld	(xwa), l
FDC_MC_EXIT_Code_Join:
	incw	1, (FDC_SECTOR_COUNT:16)
	ld	a, e
	inc	1, e
	extz	wa
	lda	xbc, (0x8a70:16)
	ld	hl, wa
	extz	xhl
	add	xhl, xbc
	ld	a, (0x8a2e:16)
	ld	(xhl), a
	incw	1, (FDC_SECTOR_COUNT:16)
	inc	1, (0x8a2d:16)
	inc	1, iy
	cp	iy, ix
	jrl	c, FDC_MC_EXIT_Code_Loop
FDC_MC_EXIT_Code_Skip2:
	ld	wa, (0x8b0a:16)
	bit	0, wa
	ret	z
	ld	a, e
	inc	1, e
	extz	wa
	lda	xbc, (0x8a70:16)
	ld	hl, wa
	extz	xhl
	add	xhl, xbc
	ld	a, (0x8a2b:16)
	ld	(xhl), a
	incw	1, (FDC_SECTOR_COUNT:16)
	ld	a, e
	inc	1, e
	extz	wa
	lda	xbc, (0x8a70:16)
	ld	hl, wa
	extz	xhl
	add	xhl, xbc
	ld	a, (0x8a2c:16)
	ld	(xhl), a
	incw	1, (FDC_SECTOR_COUNT:16)
	ld	a, e
	inc	1, e
	extz	wa
	lda	xbc, (0x8a70:16)
	ld	hl, wa
	extz	xhl
	add	xhl, xbc
	ld	wa, (0x8b0a:16)
	ld	(xhl), a
	incw	1, (FDC_SECTOR_COUNT:16)
	ld	a, e
	inc	1, e
	extz	wa
	lda	xbc, (0x8a70:16)
	ld	de, wa
	extz	xde
	add	xde, xbc
	ld	a, (0x8a2e:16)
	ld	(xde), a
	incw	1, (FDC_SECTOR_COUNT:16)
	ret
FDC_MC_EXIT_Code_Join2:
	ld	(0x8a28:16), 77
	calr	FDC_Setup_DMA_Mode
	calr	FDC_TIMING_DELAY
	ldw	wa, 77
	calr	FDC_CMD_SEND
	cp	(FDC_ERROR_CODE:16), 0
	ret	nz
	jrl	FDC_POST_OP
FDC_CMD_ENABLE:
	pushw	iz
	set	3, (PA:8)
	ldw	wa, 254
	calr	FDC_CMD_SEND
	cp	(FDC_ERROR_CODE:16), 0
	jr	z, FDC_MC_EXIT_Code_Skip3
	ldw	wa, 49
	calr	FDC_Set_Status
	jr	FDC_MC_EXIT_Code_Epilogue
FDC_MC_EXIT_Code_Skip3:
	ld	iz, 1:i3
	cp	iz, 0:i3
	jr	z, FDC_MC_EXIT_Code_Epilogue
	ldw	wa, 10
	calr	SOME_DELAY
	djnz16	iz, -9
FDC_MC_EXIT_Code_Epilogue:
	popw	iz
	ret
FDC_CMD_DISABLE:
	res	3, (PA:8)
	ldw wa, 14
	jrl	FDC_CMD_SEND
; --- FDC_STATUS_COPY: Copy FDC status and validate drive count ---
; Copies status from source to destination via (R+d16) load/store.
; Validates drive count (35396): 0 or 1 are valid, else error 0xfe.
; Three exit paths with disk-changed flag (35434) management:
;   Set flag (35434=255) or clear flag (35434=0).
FDC_STATUS_COPY:
	ldmm8	FDC_ERROR_CODE, 0x8a26
	ret
FDC_OUTPUT_CTRL:
	ld	wa, (0x8a44:16)
	cp	wa, 1:i3
	jr	z, FDC_OUTPUT_CTRL_Skip2
	cp	wa, 0:i3
	jr	nz, FDC_OUTPUT_CTRL_Skip
	jr	FDC_OUTPUT_CTRL_Join
FDC_OUTPUT_CTRL_Skip:
	ldw	wa, 254
	calr	FDC_Set_Status
	ret
FDC_OUTPUT_CTRL_Skip2:
	ld	(0x8a6a:16), 255
	ret
FDC_OUTPUT_CTRL_Join:
	ld	(0x8a6a:16), 0
	ret
; --- FDC_INTERRUPT_HANDLER: FDC interrupt service routine ---
; Enables interrupts via prevbank (D7 FA 04 = ei 4).
; Checks FDC status register, reads result data.
; Tests status bits to determine result type:
;   bit 7 -> status 0x32 (overrun), bit 5 -> status 0x31 (no data),
;   bit 6 -> status 0x2f (bad cylinder).
; Disables interrupts (D7 FA 05 = di 4) before return.
FDC_INTERRUPT_HANDLER:
	push	qiz
	cp	(FDC_ERROR_CODE:16), 0
	jr	nz, FDC_INTERRUPT_HANDLER_Code_Epilogue
	ld	wa, 4:i3
	calr	FDC_CMD_SEND
	cp	(FDC_ERROR_CODE:16), 0
	jr	nz, FDC_INTERRUPT_HANDLER_Code_Epilogue
	calr	FDC_Wait_Ready_Timeout
	cp	(FDC_ERROR_CODE:16), 0
	jr	nz, FDC_INTERRUPT_HANDLER_Code_Epilogue
	calr	FDC_ReadDataRegister
	ldfr_berp l, 251
	bit_erpb 251, 7
	jr z, FDC_INTERRUPT_HANDLER_Code_Skip
	ldw	wa, 50
	calr	FDC_Set_Status
FDC_INTERRUPT_HANDLER_Code_Skip:
	bit_erpb 251, 5
	jr nz, FDC_INTERRUPT_HANDLER_Code_Skip2
	ldw	wa, 49
	calr	FDC_Set_Status
FDC_INTERRUPT_HANDLER_Code_Skip2:
	bit_erpb 251, 6
	jr z, FDC_INTERRUPT_HANDLER_Code_Epilogue
	ldw	wa, 47
	calr	FDC_Set_Status
FDC_INTERRUPT_HANDLER_Code_Epilogue:
	pop qiz
	ret

FDC_CommandEntry:
	push xiz
	ld xiz, (xsp + 8)
	cpw (xiz), 0x0
	jr nz, FDC_CommandEntry_EnableIRQ
	ld (0x8a16:16), 0

FDC_CommandEntry_EnableIRQ:
	ei 6
	cp (0x8a16:16), 165
	jr nz, FDC_CommandEntry_CopyParams
	ei 0
	ldw wa, 0xfb
	calr FDC_Set_Status
	extz hl
	jrl FDC_Handler_Return

FDC_CommandEntry_CopyParams:
	ld (0x8a16:16), 165
	ei 0
	ld wa, (xiz)
	ld (FDC_COMMAND_INDEX:16), wa
	ld wa, (xiz + 2)
	ld (0x8a42:16), wa
	ld wa, (xiz + 4)
	ld (0x8a44:16), wa
	ld wa, (xiz + 6)
	ld (0x8a46:16), wa
	ld wa, (xiz + 8)
	ld (0x8a48:16), wa
	ld wa, (xiz + 10)
	ld (0x8a4a:16), wa
	ld xwa, (xiz + 12)
	ld (0x8a4c:16), xwa
	ld wa, (xiz)
	ld (0x8a50:16), wa
	ld wa, (xiz + 2)
	ld (0x8a52:16), wa
	ld wa, (xiz + 4)
	ld (0x8a54:16), wa
	ld wa, (xiz + 6)
	ld (0x8a56:16), wa
	ld wa, (xiz + 8)
	ld (0x8a58:16), wa
	ld wa, (xiz + 10)
	ld (0x8a5a:16), wa
	ld xwa, (xiz + 12)
	ld (0x8a5c:16), xwa
	ld (0x8a20:16), 0
	ldmm8 0x8a26, FDC_ERROR_CODE
	ld (FDC_ERROR_CODE:16), 0
	calr FDC_COMMAND_DISPATCHER
	cp l, 0:i3
	jr	nz, FDC_Handler_ExitStatus
	ld wa, (FDC_COMMAND_INDEX:16)
	cp wa, 0xb
	jr	ugt, FDC_Handler_InvalidCommand
	add wa, wa
	lda xix, (FDC_CommandEntry_CopyParams_CaseTable:24)
	ld	wa, (xix+wa)
	lda xix, (FDC_HANDLER_DISPATCH_BASE:24)
	jp	t, (xix+wa)


; =============================================================================
; FDC (Floppy Disk Controller) Handler Routines - Label Definitions
; These labels point to routines in raw byte sections
; Full disassembly documentation saved to docs/fdc_disassembly.md
; =============================================================================

; FDC routine labels (code is in raw byte sections)
	; (EQU->inline label) FDC_INIT = 0xf96bbf
	; (EQU->inline label) FDC_CONFIG_VERIFY = 0xf96bd0
	; (EQU->inline label) FDC_CMD_DISPATCH_SUB = 0xf96d95
	; (EQU->inline label) FDC_CmdSeek = 0xf97696	; cmd 2: issues SEEK (0x0F)
	; (EQU->inline label) FDC_CMD_EXEC = 0xf976e4
	; (EQU->inline label) FDC_SECTOR_XFER = 0xf97835
	; (EQU->inline label) FDC_MODE_CONFIG = 0xf97984
	; (EQU->inline label) FDC_CMD_ENABLE = 0xf97c21
	; (EQU->inline label) FDC_CMD_DISABLE = 0xf97c4b
	; (EQU->inline label) FDC_STATUS_COPY = 0xf97c54
	; (EQU->inline label) FDC_OUTPUT_CTRL = 0xf97c5b
	; (EQU->inline label) FDC_INTERRUPT_HANDLER = 0xf97c7c

; Forward references to helper routines in raw byte sections
	; (EQU->inline label) FDC_DRIVE_DETECT = 0xf97544
	; (EQU->inline label) FDC_DRIVE_STATUS = 0xf97592
	; (EQU->inline label) FDC_PRE_OP_CHECK = 0xf975ac
	; (EQU->inline label) FDC_TIMING_DELAY = 0xf975dc
	; (EQU->inline label) FDC_POST_OP = 0xf975e2
	; (EQU->inline label) FDC_CMD_SEND = 0xf972f9
	; (EQU->inline label) FDC_DETECT_CHECK = 0xf974fe

; Jump targets within FDC routines
	; (EQU->inline label) FDC_CE_DISPATCH = 0xf9782a
	; (EQU->inline label) FDC_CE_EXIT = 0xf97833
	; (EQU->inline label) FDC_SECTOR_XFER_Join5 = 0xf9795e
	; (EQU->inline label) FDC_SECTOR_XFER_Epilogue2 = 0xf97967
	; (EQU->inline label) FDC_MC_EXIT = 0xf97a3c


	.org 0xf97d8d - 0xe00000, 0xff
FDC_HANDLER_DISPATCH_BASE:
	calr FDC_InitSequence_Full
	jr FDC_Handler_ExitStatus

FDC_HANDLER_01:
	calr FDC_CMD_ENABLE
	calr FDC_CmdRecalibrate
	jr FDC_Handler_ExitStatus

FDC_HANDLER_02:
	calr FDC_CMD_ENABLE
	calr FDC_CmdSeek
	jr FDC_Handler_ExitStatus

FDC_HANDLER_03:
	calr FDC_CMD_ENABLE
	calr FDC_CMD_EXEC
	jr FDC_Handler_ExitStatus

FDC_HANDLER_04:
	calr FDC_CMD_ENABLE
	calr FDC_SECTOR_XFER
	jr FDC_Handler_ExitStatus

FDC_HANDLER_05:
	calr FDC_CMD_ENABLE
	calr FDC_MODE_CONFIG
	jr FDC_Handler_ExitStatus

FDC_HANDLER_06:
	calr FDC_CMD_ENABLE
	jr FDC_Handler_ExitStatus

FDC_HANDLER_07:
	calr FDC_CMD_DISABLE
	jr FDC_Handler_ExitStatus

FDC_HANDLER_08:
	calr FDC_STATUS_COPY
	jr FDC_Handler_ExitStatus

FDC_HANDLER_09:
	calr FDC_OUTPUT_CTRL
	jr FDC_Handler_ExitStatus

FDC_HANDLER_10:
	calr FDC_CMD_DISPATCH_SUB
	jr FDC_Handler_ExitStatus

FDC_HANDLER_11:
	calr FDC_CMD_ENABLE
	calr FDC_INTERRUPT_HANDLER
	jr FDC_Handler_ExitStatus

FDC_Handler_InvalidCommand:
	ldw wa, 0xff
	calr FDC_Set_Status

FDC_Handler_ExitStatus:
	ld (0x8a16:16), 90
	ld l, (FDC_ERROR_CODE:16)
	exts hl

FDC_Handler_Return:
	pop xiz
	ret


; --- FDC_ByteTransfer_PIO: Byte-at-a-time PIO data transfer ---
; Checks if byte count (35356) is zero; returns immediately if so.
; Dispatches by command type (35392):
;   Command 3 (READ):  read from I/O port 0x120000 -> buffer at 35406
;   Command 4 (WRITE): read from buffer at 35406 -> I/O port 0x120000
; Increments buffer pointer (35406) after each byte.
; Falls through to transfer completion handlers.
FDC_ByteTransfer_PIO:
	cpw	(FDC_SECTOR_COUNT:16), 0
	ret	z
	ld	wa, (FDC_COMMAND_INDEX:16)
	cp	wa, 4:i3
	jr	z, FDC_ByteTransfer_PIO_Skip
	cp	wa, 3:i3
	ret	nz
	ld	c, (0x120000:24)
	ld	xhl, (0x8a4e:16)
	ld	(xhl), c
	inc	1, xhl
	ld	(0x8a4e:16), xhl
FDC_ByteTransfer_PIO_Join:
	subw	(FDC_SECTOR_COUNT:16), 1
	ret	nz
	calr	FDC_Pulse_PH0
	calr	FDC_Port_Reset_Or_Noop
	ret
FDC_ByteTransfer_PIO_Skip:
	ld	xhl, (0x8a4e:16)
	ld	c, (xhl)
	ld	(0x120000:24), c
	inc	1, xhl
	ld	(0x8a4e:16), xhl
	jr	FDC_ByteTransfer_PIO_Join

INTTC3_HANDLER:
	push xiz
	push xiy
	push xix
	push xhl
	push xde
	push xbc
	push xwa
	calr FDC_Pulse_PH0
	calr FDC_Port_Reset_Or_Noop
	pop xwa
	pop xbc
	pop xde
	pop xhl
	pop xix
	pop xiy
	pop xiz
	reti


INT5_HANDLER:	; F97E4A	"FDCIRQ"
	ld (265:16), 8
	reti


INT4_HANDLER:	; F97E50	"FDCINT"
	push xiz
	push xiy
	push xix
	push xhl
	push xde
	push xbc
	push xwa
	ld iz, 0:i3

INT4_PollStatusLoop:
	ld wa, iz
	inc 1, iz
	cp wa, 0x64
	jr gt, INT4_ExitRestore
	calr FDC_Read_Status
	bit 7, l
	jr z, INT4_PollStatusLoop

INT4_WaitDataReady:
	calr FDC_Read_Status
	bit 7, l
	jr z, INT4_WaitDataReady
	calr FDC_Read_Status
	bit 6, l
	jr nz, INT4_StoreResultBase
	ld l, 0x0:opc
	cp l, 0x80
	jr z, INT4_SendSpecifyCmd

INT4_WaitNonDMAMode:
	calr FDC_Read_Status
	and l, 0xf0
	cp l, 0x80
	jr nz, INT4_WaitNonDMAMode

INT4_SendSpecifyCmd:
	ldw wa, 0x8
	calr FDC_WriteDataRegister

INT4_StoreResultBase:
	lda xiz, (0x8a60:16)
	inc 1, xiz

INT4_ReadResultLoop:
	calr FDC_Wait_Status_Timeout
	calr FDC_ReadDataRegister
	ld (xiz+), l

INT4_WaitResultReady:
	calr FDC_Read_Status
	bit 7, l
	jr z, INT4_WaitResultReady
	calr FDC_Read_Status
	bit 6, l
	jr nz, INT4_ReadResultLoop
	calr FDC_Exception_Status_Decoder
	cp (0x8a61:16), 128
	jr nz, INT4_WaitDataReady

INT4_ExitRestore:
	ld (0x8a60:16), 0
	pop xwa
	pop xbc
	pop xde
	pop xhl
	pop xix
	pop xiy
	pop xiz
	reti


Reset_Floppy_Disk_Controller:
; I am not entirely sure yet, but it looks like FDC initialization code...

	; reset FDC by toggling Port D bit 0
	set	0, (PD:8)
	ldw wa, 0xa
	calr SOME_DELAY
	res	0, (PD:8)
	ldw wa, 0xa
	jrl SOME_DELAY

	; then do a lot of other stuff I still don't undertsand:

; FDTest_ProbeDiskFormat: Main-CPU twin of the bootloader's FDC_ProbeDiskFormat (table_data/boot_disk_probe.s): sets
;   PHFC = 0x1E, returns when Port D bit 6 is set (no disk), else submits through FDC_CommandEntry the request block
;   at 0x8B24 (command, drive, head, track, sector, count, buffer 0x8B34): command 0 (initialize, track field 224; the
;   211 arm is dead, A = 0) and four single-sector reads (command 3, sector 1) at tracks 0, 78, 10 and 40, then waits
;   200 (SOME_DELAY) and counts the pass in 0xE3DA. Basis: callers + body -- the FDD test title's entry 0
;   (TitleFunc_LifecycleTable) prints 'TBIOS Test' and calls it; same request sequence as the documented boot twin.
FDTest_ProbeDiskFormat:
	ld (PHFC:8), 0x1e:io
	bit	6, (PD:8)	; Port D bit 6: "FD.I/O signal"
	ret nz
	ld a, 0x0:opc
	ldw (0x8b24:16), 0
	ldw (0x8b26:16), 0
	ldw (0x8b28:16), 0
	cp a, 0:i3
	jr nz, FDC_Reset_SetDD_SectorCount
	ldw (0x8b2a:16), 224
	jr FDC_Reset_BuildParams

FDC_Reset_SetDD_SectorCount:
	ldw (0x8b2a:16), 211

FDC_Reset_BuildParams:
	ldw (0x8b2c:16), 0
	ldw (0x8b2e:16), 0
	ld xwa, 0:i3
	ld (0x8b30:16), xwa
	lda xwa, (0x8b24:16)
	push xwa
	calr FDC_CommandEntry
	ldw (0x8b24:16), 3
	ldw (0x8b26:16), 0
	ldw (0x8b28:16), 0
	ldw (0x8b2a:16), 0
	ldw (0x8b2c:16), 1
	ldw (0x8b2e:16), 1
	lda xwa, (0x8b34:16)
	ld (0x8b30:16), xwa
	lda xwa, (0x8b24:16)
	push xwa
	calr FDC_CommandEntry
	ldw (0x8b24:16), 3
	ldw (0x8b26:16), 0
	ldw (0x8b28:16), 0
	ldw (0x8b2a:16), 78
	ldw (0x8b2c:16), 1
	ldw (0x8b2e:16), 1
	lda xwa, (0x8b34:16)
	ld (0x8b30:16), xwa
	lda xwa, (0x8b24:16)
	push xwa
	calr FDC_CommandEntry
	ldw (0x8b24:16), 3
	ldw (0x8b26:16), 0
	ldw (0x8b28:16), 0
	ldw (0x8b2a:16), 10
	ldw (0x8b2c:16), 1
	ldw (0x8b2e:16), 1
	lda xwa, (0x8b34:16)
	ld (0x8b30:16), xwa
	lda xwa, (0x8b24:16)
	push xwa
	calr FDC_CommandEntry
	ldw (0x8b24:16), 3
	ldw (0x8b26:16), 0
	ldw (0x8b28:16), 0
	ldw (0x8b2a:16), 40
	ldw (0x8b2c:16), 1
	ldw (0x8b2e:16), 1
	lda xwa, (0x8b34:16)
	ld (0x8b30:16), xwa
	lda xwa, (0x8b24:16)
	push xwa
	calr FDC_CommandEntry
	lda xsp, (xsp + 20)
	ldw wa, 0xc8
	calr SOME_DELAY
	incw 1, (0xe3da:16)
	ret

Check_for_Floppy_Disk_Change:
	bit	6, (PD:8)
	jr z, Detected_Floppy_Disk_Change
	ld l, 0x0:opc
	ret

Detected_Floppy_Disk_Change:
	ld l, 0x1:opc
	ret

; End of FDC routines
