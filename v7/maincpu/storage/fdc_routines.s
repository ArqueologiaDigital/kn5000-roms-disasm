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
	ldb_da l, (0x110008)
	ret

FDC_Read_Data:
	ldb_da l, (0x11000a)
	ret

; --- FDC_Send_Command: Write command byte to FDC data register ---
; Stores accumulator A to FDC data port (0x110008),
; waits for FDC ready via status register polling,
; then returns. Uses (R+d16) addressing for FDC port access.
FDC_Send_Command:
	.incbin "includes/generated/v7_transplant_FDC_Send_Command.bin"
FDC_Write_Data:
	stb_da (0x11000a), a
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
	.incbin "includes/generated/v7_transplant_FDC_WaitReady.bin"
FDC_COMMAND_DISPATCHER:
	.incbin "includes/generated/v7_transplant_FDC_COMMAND_DISPATCHER.bin"
FDC_CMD_HANDLER_BASE:
	.incbin "includes/generated/v7_transplant_FDC_CMD_HANDLER_BASE.bin"
FDC_ReturnZero:
	ldb l, 0x0
	ret

FDC_ErrorInvalidDrive:
	calr FDC_Validate_Drive_Head

FDC_CheckDriveCount:
	.incbin "includes/generated/v7_transplant_FDC_CheckDriveCount.bin"
FDC_ValidateCommand:
	.incbin "includes/generated/v7_transplant_FDC_ValidateCommand.bin"
FDC_NoOpReturn:
	ldb l, 0x0
	ret

FDC_Command5Handler:
	.incbin "includes/generated/v7_transplant_FDC_Command5Handler.bin"
FDC_ValidateTrack:
	.incbin "includes/generated/v7_transplant_FDC_ValidateTrack.bin"
FDC_HandleCmd2:
	.incbin "includes/generated/v7_transplant_FDC_HandleCmd2.bin"
FDC_CheckSectorCount:
	.incbin "includes/generated/v7_transplant_FDC_CheckSectorCount.bin"
FDC_CheckSectorNum:
	.incbin "includes/generated/v7_transplant_FDC_CheckSectorNum.bin"
FDC_CheckFormatType:
	.incbin "includes/generated/v7_transplant_FDC_CheckFormatType.bin"
FDC_FormatType3:
	.incbin "includes/generated/v7_transplant_FDC_FormatType3.bin"
FDC_FormatType4:
	.incbin "includes/generated/v7_transplant_FDC_FormatType4.bin"
FDC_Format4Check:
	.incbin "includes/generated/v7_transplant_FDC_Format4Check.bin"
FDC_FormatDefault:
	.incbin "includes/generated/v7_transplant_FDC_FormatDefault.bin"
FDC_ErrorInvalid:
	ldw wa, 0xfe
	jrl FDC_Set_Status

FDC_ValidExecute:
	.incbin "includes/generated/v7_transplant_FDC_ValidExecute.bin"
FDC_SetupFormatParams:
	.incbin "includes/generated/v7_transplant_FDC_SetupFormatParams.bin"
FDC_FormatHD:
	.incbin "includes/generated/v7_transplant_FDC_FormatHD.bin"
FDC_FormatDD:
	.incbin "includes/generated/v7_transplant_FDC_FormatDD.bin"
FDC_Format1440K:
	.incbin "includes/generated/v7_transplant_FDC_Format1440K.bin"
FDC_FormatUnknown:
	ldw wa, 0xfe
	calr FDC_Set_Status

FDC_InitStateVars:
	.incbin "includes/generated/v7_transplant_FDC_InitStateVars.bin"
FDC_CheckHead:
	.incbin "includes/generated/v7_transplant_FDC_CheckHead.bin"
FDC_Command5_Epilogue:
	ret

FDC_Validate_Drive_Head:
	.incbin "includes/generated/v7_transplant_FDC_Validate_Drive_Head.bin"
FDC_NOP_Delay:
	dec 2, xsp
	ld (xsp), a
	ld a, (xsp)
	decm8 1, (xsp)
	cps a, 0
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
	cps a, 0
	jr nz, FDC_NOP_Delay_Loop

FDC_NOP_Delay_Exit:
	inc 2, xsp
	ret


FDC_Pulse_PH0:
	set_dd8 0, 0x44
	ldw wa, 0xa
	calr FDC_NOP_Delay
	res_dd8 0, 0x44
	ret


FDC_Init_Sequence_1:
	jr	0


FDC_Port_Reset_Or_Noop:
	ret


FDC_Setup_DMA_Mode:
	.incbin "includes/generated/v7_transplant_FDC_Setup_DMA_Mode.bin"
FDC_Setup_DMA_Write_Mode:
	jr FDC_Setup_DMA_Ack_Dest

FDC_Setup_DMA_Read_Mode:
	calr FDC_Setup_DMA_Src_Ack

FDC_DMA_Setup_Exit:
	ret

FDC_Setup_DMA_Ack_Dest:
	.incbin "includes/generated/v7_transplant_FDC_Setup_DMA_Ack_Dest.bin"
FDC_Setup_DMA_Src_Ack:
	.incbin "includes/generated/v7_transplant_FDC_Setup_DMA_Src_Ack.bin"
FDC_Wait_Ready_Timeout:
	push xiz
	ldw_d16 xiz, (1033)
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
	ldw_d16 xwa, (1033)
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
	lds wa, 2
	calr FDC_Set_Status

FDC_WaitReady_Complete:
	pop xiz
	ret


FDC_Wait_Status_Timeout:
	push xiz
	ldw_d16 xiz, (1033)
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
	ldw_d16 xwa, (1033)
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
	lds wa, 2
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
	.incbin "includes/generated/v7_transplant_FDC_ResultPhase_Read.bin"
FDC_Exception_Status_Decoder:
	.incbin "includes/generated/v7_transplant_FDC_Exception_Status_Decoder.bin"
FDC_StatusDecode_DriveNotReady:
	.incbin "includes/generated/v7_transplant_FDC_StatusDecode_DriveNotReady.bin"
FDC_StatusDecode_InvalidCommand:
	ldb l, 0x0
	ret

FDC_StatusDecode_AbnormalTerm:
	bit 3, c
	jr z, FDC_StatusDecode_Overrun
	ldb l, 0x31
	ret

FDC_StatusDecode_Overrun:
	bit 4, c
	jr z, FDC_StatusDecode_CheckST2
	ldb l, 0x32
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
	ldb l, 0x8
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
	.incbin "includes/generated/v7_transplant_FDC_HardwareSetup.bin"
FDC_Set_Status:
	.incbin "includes/generated/v7_transplant_FDC_Set_Status.bin"
FDC_SetStatus_MissingAddrMark:
	nop
	jr FDC_SetStatus_Return

FDC_SetStatus_DataFieldErr:
	nop
	jr FDC_SetStatus_Return

FDC_SetStatus_AlreadySet:
	nop

FDC_SetStatus_Return:
	.incbin "includes/generated/v7_transplant_FDC_SetStatus_Return.bin"
FDC_ClearStatus_InitTimer:
	.incbin "includes/generated/v7_transplant_FDC_ClearStatus_InitTimer.bin"
SOME_DELAY:
	srl wa, 1
	ldw_d16 xde, (1033)
	lds hl, 0
	cp hl, 0xffff
	ret nc

SOME_DELAY_Loop:
	ldw_d16 xbc, (1033)
	sub bc, de
	cp bc, wa
	ret ugt
	inc 1, hl
	cp hl, 0xffff
	jr c, SOME_DELAY_Loop
	ret


FDC_InitSequence_Short:
	ldw	wa, 40
	jr	-39

FDC_InitSequence_Full:
	.incbin "includes/generated/v7_transplant_FDC_InitSequence_Full.bin"
FDC_SeekRecalibrate:
	.incbin "includes/generated/v7_transplant_FDC_SeekRecalibrate.bin"
FDC_CMD_EXEC:
	.incbin "includes/generated/v7_transplant_FDC_CMD_EXEC.bin"
FDC_MODE_CONFIG:
	.incbin "includes/generated/v7_transplant_FDC_MODE_CONFIG.bin"
FDC_MC_EXIT:
	.incbin "includes/generated/v7_transplant_FDC_MC_EXIT.bin"
FDC_STATUS_COPY:
	.incbin "includes/generated/v7_transplant_FDC_STATUS_COPY.bin"
FDC_INTERRUPT_HANDLER:
	.incbin "includes/generated/v7_transplant_FDC_INTERRUPT_HANDLER.bin"
FDC_CommandEntry:
	.incbin "includes/generated/v7_transplant_FDC_CommandEntry.bin"
FDC_CommandEntry_EnableIRQ:
	.incbin "includes/generated/v7_transplant_FDC_CommandEntry_EnableIRQ.bin"
FDC_CommandEntry_CopyParams:
	.incbin "includes/generated/v7_transplant_FDC_CommandEntry_CopyParams.bin"
FDC_HANDLER_DISPATCH_BASE:
	calr FDC_InitSequence_Full
	jr FDC_Handler_ExitStatus

FDC_HANDLER_01:
	calr FDC_CMD_ENABLE
	calr FDC_SeekRecalibrate
	jr FDC_Handler_ExitStatus

FDC_HANDLER_02:
	calr FDC_CMD_ENABLE
	calr FDC_STATUS_HANDLER
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
	.incbin "includes/generated/v7_transplant_FDC_Handler_ExitStatus.bin"
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
	.incbin "includes/generated/v7_transplant_FDC_ByteTransfer_PIO.bin"
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
	stdi8 (265), 8
	reti


INT4_HANDLER:	; F97E50	"FDCINT"
	push xiz
	push xiy
	push xix
	push xhl
	push xde
	push xbc
	push xwa
	lds iz, 0

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
	ldb l, 0x0
	cp l, 0x80
	jr z, INT4_SendSpecifyCmd

INT4_WaitNonDMAMode:
	calr FDC_Read_Status
	and l, 0xf0
	cp l, 0x80
	jr nz, INT4_WaitNonDMAMode

INT4_SendSpecifyCmd:
	ldw wa, 0x8
	calr FDC_Write_Data

INT4_StoreResultBase:
	.incbin "includes/generated/v7_transplant_INT4_StoreResultBase.bin"
INT4_ReadResultLoop:
	calr FDC_Wait_Status_Timeout
	calr FDC_Read_Data
	lda_dpi XSP, 0xf8

INT4_WaitResultReady:
	.incbin "includes/generated/v7_transplant_INT4_WaitResultReady.bin"
INT4_ExitRestore:
	.incbin "includes/generated/v7_transplant_INT4_ExitRestore.bin"
Reset_Floppy_Disk_Controller:
	.incbin "includes/generated/v7_transplant_Reset_Floppy_Disk_Controller.bin"
FDC_Reset_SetDD_SectorCount:
	.incbin "includes/generated/v7_transplant_FDC_Reset_SetDD_SectorCount.bin"
FDC_Reset_BuildParams:
	.incbin "includes/generated/v7_transplant_FDC_Reset_BuildParams.bin"
Check_for_Floppy_Disk_Change:
	bit_dd8 6, 0x34
	jr z, Detected_Floppy_Disk_Change
	ldb l, 0x0
	ret

Detected_Floppy_Disk_Change:
	ldb l, 0x1
	ret

; End of FDC routines
