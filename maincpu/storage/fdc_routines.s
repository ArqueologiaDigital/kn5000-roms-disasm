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
; Address range: 0xF96D54 - 0xF98009
;
; Dependencies:
;   - fdc_constants.asm must be included before this file
;   - Requires FDC_MAP__BASE_ADDR and FDC__DMA_ACKNOWLEDGE
; =============================================================================

FDC_Read_Status:
	ld8_24 l, 0x110008
	ret

FDC_Read_Data:
	ld8_24 l, 0x11000a
	ret

; --- FDC_Send_Command: Write command byte to FDC data register ---
; Stores accumulator A to FDC data port (0x110008),
; waits for FDC ready via status register polling,
; then returns. Uses (R+d16) addressing for FDC port access.
FDC_Send_Command:
	st8_24	1114120, a
	ret
	.byte 0xc1
	ldb	b, 139
	pop_f
	ldb	w, 139
	stda8	35618, a
	ret

FDC_Write_Data:
	st8_24 0x11000a, a
	ret

; --- FDC_WaitReady: Wait for FDC ready with timeout and DMA transfer ---
; Two-phase wait loop (masks 0x1F and 0x90) checking FDC status register.
; Uses prevbank (D7 FA) for timeout flag management.
; Contains 7-entry command dispatch (commands 0-5 + default):
;   Each entry: stdi8 35436, N; calr <handler>; stdi16 35362, 0
; Handles DMA channel setup, result status checking, and retry logic.
; Timeout limit: 500 timer ticks (checked against timer at address 1033).
; Uses (R+d16) addressing extensively for FDC port and state variable access.
FDC_WaitReady:
	push	xiz
	ldda16	iz, 1033
	.byte 0xd7
	swi	2
	pop_sr
	.byte 0x80
	nop
	.byte 0xd7
	swi	2
	add	w, l
	nop
	jr	nz, 41
	calr	65481
	and	l, 31
	ld	a, l
	extz	wa
	cps	wa, 0
	jr	nz, 3
	.byte 0xd7
	swi	2
	.byte 0xa8
	ldda16	wa, 1033
	sub	wa, iz
	cp	wa, 500
	jr	ule, 5
	.byte 0xd7
	swi	2
	pop_sr
	swi	7
	swi	7
	.byte 0xd7
	swi	2
	add	w, l
	nop
	jr	z, -41
	.byte 0xd7
	swi	2
	inc	6, wa
	halt
	lds	wa, 1
	calr	2611
	pop	xiz
	ret
	push	xiz
	ldda16	iz, 1033
	.byte 0xd7
	swi	2
	pop_sr
	.byte 0x80
	nop
	.byte 0xd7
	swi	2
	add	w, l
	nop
	jr	nz, 38
	calr	65411
	and	l, 144
	cp	l, 144
	jr	nz, 3
	.byte 0xd7
	swi	2
	.byte 0xa8
	ldda16	wa, 1033
	sub	wa, iz
	cp	wa, 500
	jr	ule, 5
	.byte 0xd7
	swi	2
	pop_sr
	swi	7
	swi	7
	.byte 0xd7
	swi	2
	add	w, l
	nop
	jr	z, -38
	.byte 0xd7
	swi	2
	inc	6, wa
	halt
	lds	wa, 1
	calr	2544
	pop	xiz
	ret
	ldw	wa, 54
	calr	65370
	lds	wa, 2
	calr	2632
	stdi8	35588, 255
	ret
	push	xiz
	calr	2562
	calr	2413
	cp	hl, 65535
	jr	z, 14
	calr	2482
	cp	hl, 65535
	jr	z, 5
	stdi8	35588, 255
	.byte 0xc1
	ldb	w, 138
	push	xsp
	swi	7
	jrl	z, 416
	stdi8	35360, 255
	ldw	wa, 54
	calr	65313
	lds	wa, 2
	calr	2575
	calr	2366
	cp	hl, 65535
	jr	z, 111
	calr	2435
	cp	hl, 65535
	jr	z, 102
	calr	2494
	calr	378
	.byte 0xc1
	ldb	d, 138
	push	xsp
	nop
	jr	z, 8
	stdi8	35360, 0
	jrl	361
	calr	65254
	bit	7, l
	jr	z, -8
	calr	65246
	bit	6, l
	jr	nz, 24
	ldb	l, 0
	cp	l, 128
	jr	z, 11
	calr	65231
	and	l, 240
	cp	l, 128
	jr	nz, -11
	ldw	wa, 8
	calr	65246
	ldada	xiz, 35424
	inc	1, xiz
	calr	1134
	calr	65211
	.byte 0xf5
	swi	0
	ld	xsp, 3489574686
	ldw	hl, 26119
	swi	0
	calr	65191
	bit	6, l
	jr	nz, -25
	calr	1481
	.byte 0xc1
	jr	lt, -118
	push	xsp
	decm8	6, (xwa)
	sub	(xsp-40), xhl
	calr	1657
	.byte 0xc1
	ldb	d, 138
	push	xsp
	nop
	jr	z, 8
	stdi8	35360, 0
	jrl	260
	ldw	wa, 79
	calr	1636
	.byte 0xc1
	ldb	d, 138
	push	xsp
	nop
	jr	z, 8
	stdi8	35360, 0
	jrl	239
	ldda8	a, 35438
	and	a, 15
	extz	wa
	cps	wa, 0
	jrl	mi, 156
	cps	wa, 5
	jrl	gt, 151
	add	wa, wa
	lda_24	xix, 15374502
	.byte 0xd3
	reti
	.byte 0xf0, 0xe0
	ldb	w, 242
	dec	4, e
	swi	1
	ldw	ix, 2035
	.byte 0xf0, 0xe0
	cp	bc, wa
	jr	nov, -118
	nop
	nop
	stdi16	35362, 0
	.byte 0xc7
	swi	3
	sub	(xwa-40), xde
	calr	65093
	jr	127
	stdi8	35436, 0
	stdi16	35362, 0
	.byte 0xc7
	swi	3
	pop_sr
	.byte 0xc0
	lds	wa, 2
	calr	65071
	jr	105
	stdi8	35436, 2
	stdi16	35362, 0
	.byte 0xc7
	swi	3
	pop_sr
	ld	xwa, 421439704
	swi	6
	jr	83
	stdi8	35436, 3
	stdi16	35362, 0
	.byte 0xc7
	swi	3
	pop_sr
	ld	xwa, 52340952
	swi	6
	jr	61
	stdi8	35436, 4
	stdi16	35362, 0
	.byte 0xc7
	swi	3
	sub	(xwa-40), xde
	calr	65006
	jr	40
	stdi8	35436, 5
	stdi16	35362, 0
	.byte 0xc7
	swi	3
	sub	(xwa-40), xde
	calr	64985
	jr	19
	stdi8	35436, 0
	stdi16	35362, 0
	.byte 0xc7
	swi	3
	sub	(xwa-40), xde
	calr	64964
	.byte 0xc7
	swi	3
	and	(xbc-55), h
	pushw	4824
	calr	1421
	.byte 0xc1
	ldb	d, 138
	push	xsp
	nop
	jr	z, 7
	stdi8	35360, 0
	jr	25
	calr	3748
	.byte 0xc1
	ldb	d, 138
	push	xsp
	nop
	jr	z, 7
	stdi8	35360, 0
	jr	8
	calr	2244
	stdi8	35360, 0
	pop	xiz
	ret
	ldw	wa, 54
	calr	64900
	lds	wa, 2
	calr	2162
	calr	64880
	cp	l, 255
	jr	nz, 6
	ldw	wa, 252
	calr	2047
	lds	hl, 0
	ret

; FDC command dispatcher
; Reads command from (8A40h), dispatches to 12 handlers (0-0xB)
; Uses offset table at 0xEA98B2
FDC_COMMAND_DISPATCHER:
	stdi8 35370, 0
	ldda16 xwa, 35392
	cp wa, 0xB
	jr ugt, FDC_CheckDriveCount
	add wa, wa
	lda_24 xix, 0xea98b2
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xf96dd6
	jp_dri 8, 0x07, 0xF0, 0xE0
; FDC command handler base - entry point for command 0
FDC_CMD_HANDLER_BASE:
	calr FDC_SetupFormatParams
	ldda8 l, 35364
	ret

FDC_ReturnZero:
	ldb l, 0x0
	ret

FDC_ErrorInvalidDrive:
	calr FDC_Validate_Drive_Head

FDC_CheckDriveCount:
	ldda16 xwa, 35394
	stda8 35370, a
	cpdi8 35370, 1
	jr ule, FDC_ValidateCommand
	ldw wa, 0xFE
	jrl FDC_Set_Status

FDC_ValidateCommand:
	ldda16 xwa, 35392
	cps wa, 4
	jr z, FDC_ValidateTrack
	cps wa, 3
	jr z, FDC_ValidateTrack
	cps wa, 2
	jr z, FDC_ValidateTrack
	cps wa, 5
	jr z, FDC_Command5Handler
	cp wa, 0xB
	jr z, FDC_NoOpReturn
	cps wa, 1
	jr nz, FDC_ValidateTrack

FDC_NoOpReturn:
	ldb l, 0x0
	ret

FDC_Command5Handler:
	calr FDC_Command5_Epilogue
	ldda8 l, 35364
	ret

FDC_ValidateTrack:
	ldda16 xwa, 35398
	stda8 35371, a
	stda8 35382, a
	extz wa
	cpda16 xwa, 35592
	jr c, FDC_HandleCmd2
	ldw wa, 0xFE
	jrl FDC_Set_Status

FDC_HandleCmd2:
	cpdi16 35392, 2
	jr nz, FDC_CheckSectorCount
	calr FDC_CheckHead
	ldda8 l, 35364
	ret

FDC_CheckSectorCount:
	cpdi16 35402, 0
	jr nz, FDC_CheckSectorNum
	ldw wa, 0xFE
	jrl FDC_Set_Status

FDC_CheckSectorNum:
	ldda16 xwa, 35400
	stda8 35373, a
	cpdi8 35373, 0
	jr nz, FDC_CheckFormatType
	ldw wa, 0xFE
	jrl FDC_Set_Status

FDC_CheckFormatType:
	ldda8 a, 35436
	cps a, 0
	jr z, FDC_FormatDefault
	cps a, 5
	jr z, FDC_FormatDefault
	cps a, 4
	jr z, FDC_FormatType4
	cps a, 3
	jr z, FDC_FormatType3
	cps a, 2
	jr nz, FDC_ErrorInvalid
	cpdi8 35373, 8
	jr ule, FDC_ValidExecute
	ldw wa, 0xFE
	jrl FDC_Set_Status

FDC_FormatType3:
	cpdi8 35373, 18
	jr ule, FDC_ValidExecute
	ldw wa, 0xFE
	jrl FDC_Set_Status

FDC_FormatType4:
	cpdi8 35373, 255
	jr nz, FDC_Format4Check
	calr FDC_CheckHead
	ldda8 l, 35364
	ret

FDC_Format4Check:
	cpdi8 35373, 9
	jr ule, FDC_ValidExecute
	ldw wa, 0xFE
	jrl FDC_Set_Status

FDC_FormatDefault:
	cpdi8 35373, 9
	jr ule, FDC_ValidExecute
	ldw wa, 0xFE
	jrl FDC_Set_Status

FDC_ErrorInvalid:
	ldw wa, 0xFE
	jrl FDC_Set_Status

FDC_ValidExecute:
	calr FDC_CheckHead
	ldda8 l, 35364
	ret

FDC_SetupFormatParams:
	ldda16 xwa, 35398
	stda8 35438, a
	and a, 0xF
	cps a, 3
	jrl z, FDC_Format1440K
	cps a, 2
	jr z, FDC_FormatDD
	cps a, 5
	jr z, FDC_FormatHD
	cps a, 4
	jr z, FDC_FormatHD
	cps a, 0
	jrl nz, FDC_FormatUnknown

FDC_FormatHD:
	stdi8 35374, 2
	stdi8 35381, 1
	stdi8 35375, 9
	stdi8 35378, 9
	stdi8 35376, 27
	stdi8 35379, 84
	stdi16 35590, 79
	stdi16 35592, 80
	stdi16 35594, 9
	stdi16 35596, 10
	jr FDC_InitStateVars

FDC_FormatDD:
	stdi8 35374, 3
	stdi8 35381, 1
	stdi8 35375, 8
	stdi8 35378, 8
	stdi8 35376, 83
	stdi8 35379, 116
	stdi16 35590, 76
	stdi16 35592, 77
	stdi16 35594, 8
	stdi16 35596, 9
	jr FDC_InitStateVars

FDC_Format1440K:
	stdi8 35374, 2
	stdi8 35381, 1
	stdi8 35375, 18
	stdi8 35378, 18
	stdi8 35376, 27
	stdi8 35379, 108
	stdi16 35590, 79
	stdi16 35592, 80
	stdi16 35594, 18
	stdi16 35596, 19
	jr FDC_InitStateVars

FDC_FormatUnknown:
	ldw wa, 0xFE
	calr FDC_Set_Status

FDC_InitStateVars:
	ldda8 a, 35438
	srl a, 4
	and a, 0xF
	stda8 35383, a
	stdi8 35377, 255
	stdi8 35380, 0
	stdi8 35384, 15
	stdi8 35385, 1
	stdi8 35388, 0
	stdi8 35387, 0
	stdi8 35389, 0
	stdi8 35390, 0
	stdi8 35391, 0
	stdi8 35386, 0
	ret

FDC_CheckHead:
	ldda16 xwa, 35396
	stda8 35372, a
	stda8 35369, a
	cpdi8 35369, 0
	ret z
	cpdi8 35369, 1
	ret z
	ldw wa, 0xFE
	calr FDC_Set_Status
	ret

FDC_Command5_Epilogue:
	ret

FDC_Validate_Drive_Head:
	cpdi16 35396, 0
	ret z
	cpdi16 35396, 1
	ret z
	ldw wa, 0xFE
	calr FDC_Set_Status
	ret


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
	ldw wa, 0xA
	calr FDC_NOP_Delay
	res_dd8 0, 0x44
	ret


FDC_Init_Sequence_1:
	jr	0


FDC_Port_Reset_Or_Noop:
	ret


FDC_Setup_DMA_Mode:
	ldda16 xbc, 35356
	ldc_cr16 bc, 0x4C
	ldda8 a, 35368
	cp a, 0x4D
	jr z, FDC_Setup_DMA_Read_Mode
	cp a, 0xC9
	jr z, FDC_Setup_DMA_Read_Mode
	cp a, 0xC5
	jr z, FDC_Setup_DMA_Read_Mode
	cp a, 0xDD
	jr z, FDC_Setup_DMA_Write_Mode
	cp a, 0xD9
	jr z, FDC_Setup_DMA_Write_Mode
	cp a, 0xD1
	jr z, FDC_Setup_DMA_Write_Mode
	cp a, 0x4A
	jr z, FDC_Setup_DMA_Write_Mode
	cp a, 0x42
	jr z, FDC_Setup_DMA_Write_Mode
	cp a, 0xCC
	jr z, FDC_Setup_DMA_Write_Mode
	cp a, 0xC6
	ret nz

FDC_Setup_DMA_Write_Mode:
	jr FDC_Setup_DMA_Ack_Dest

FDC_Setup_DMA_Read_Mode:
	calr FDC_Setup_DMA_Src_Ack

FDC_DMA_Setup_Exit:
	ret

FDC_Setup_DMA_Ack_Dest:
	ld xhl, 0x120000
	ldc_cr32 xhl, 0x0C
	ldda32 xhl, 35404
	ldc_cr32 xhl, 0x2C
	ldb a, 0x0
	ldc_cr8 a, 0x4E
	jr FDC_Port_Reset_Or_Noop

FDC_Setup_DMA_Src_Ack:
	ldda32 xhl, 35404
	ldc_cr32 xhl, 0x0C
	ld xhl, 0x120000
	ldc_cr32 xhl, 0x2C
	ldb a, 0x8
	ldc_cr8 a, 0x4E
	jr FDC_Port_Reset_Or_Noop
	ldda16 xbc, 35356
	ldc_cr16 bc, 0x4C
	ret

FDC_Wait_Ready_Timeout:
	push xiz
	ldda16 xiz, 1033
	ldi_erpw 0xFA, 0x80, 0x00
	cp_erpw 0xFA, 0x80, 0x00
	jr nz, FDC_WaitReady_TimedOut

FDC_WaitReady_StatusLoop:
	calr FDC_Read_Status
	res 4, l
	ld a, l
	cp a, 0x80
	jr z, FDC_WaitReady_TimeoutCheck
	cp a, 0xC0
	jr nz, FDC_WaitReady_TimeoutCheck
	ldi_werp 0xFA, 0

FDC_WaitReady_TimeoutCheck:
	ldda16 xwa, 1033
	sub wa, iz
	cp wa, 0x1F4
	jr ule, FDC_WaitReady_LoopContinue
	ldi_erpw 0xFA, 0xFF, 0xFF

FDC_WaitReady_LoopContinue:
	cp_erpw 0xFA, 0x80, 0x00
	jr z, FDC_WaitReady_StatusLoop

FDC_WaitReady_TimedOut:
	cpi_werp 0xFA, 0
	jr z, FDC_WaitReady_Complete
	lds wa, 2
	calr FDC_Set_Status

FDC_WaitReady_Complete:
	pop xiz
	ret


FDC_Wait_Status_Timeout:
	push xiz
	ldda16 xiz, 1033
	ldi_erpw 0xFA, 0x80, 0x00
	cp_erpw 0xFA, 0x80, 0x00
	jr nz, FDC_WaitStatus_TimedOut

FDC_WaitStatus_StatusLoop:
	calr FDC_Read_Status
	and l, 0xE0
	cp l, 0x80
	jr z, FDC_WaitStatus_CheckTimeout
	cp l, 0xC0
	jr nz, FDC_WaitStatus_CheckTimeout
	ldi_werp 0xFA, 0

FDC_WaitStatus_CheckTimeout:
	ldda16 xwa, 1033
	sub wa, iz
	cp wa, 0x1F4
	jr ule, FDC_WaitStatus_TimeoutCheck
	ldi_erpw 0xFA, 0xFF, 0xFF

FDC_WaitStatus_TimeoutCheck:
	cp_erpw 0xFA, 0x80, 0x00
	jr z, FDC_WaitStatus_StatusLoop

FDC_WaitStatus_TimedOut:
	cpi_werp 0xFA, 0
	jr z, FDC_WaitStatus_Complete
	lds wa, 2
	calr FDC_Set_Status

FDC_WaitStatus_Complete:
	pop xiz
	ret


; --- FDC_ResultPhase_Read: Read FDC result phase data into buffer ---
; Reads FDC status register in a loop, checking top 2 bits:
;   0xC0 = command complete, 0x80 = data ready for transfer.
; When data ready, reads byte from FDC and stores to buffer at 35424[index].
; Includes timeout checking against timer at address 1033.
; Contains 6 parameter-passing wrapper stubs at the end, each:
;   dec 2,xsp / ld (xsp),a / calr <func> / ld a,(xsp) / extz wa /
;   calr <store> / inc 2,xsp / ret
; Uses (R+d16) and dec/inc xsp addressing (not in LLVM).
FDC_ResultPhase_Read:
	dec	2, xsp
	push	xiz
	.byte 0xbf, 0x04
	ex_ff
	push	4
	.byte 0xd7
	swi	2
	pop_sr
	.byte 0x80
	nop
	.byte 0xd7
	swi	2
	add	w, l
	nop
	jr	nz, 83
	calr	63905
	res	4, l
	ld	a, l
	cp	a, 192
	jr	z, 10
	cp	a, 128
	jr	nz, 40
	.byte 0xd7
	swi	2
	ld	xhl, (xwa+104)
	lds	iz, 1
	.byte 0xd7
	swi	2
	cp	(xwa-41), xde
	dec	6, wa
	pop_f
	calr	63878
	ldada	xwa, 35424
	ld	bc, iz
	extz	xbc
	add	xbc, xwa
	ld	(xbc), l
	calr	63857
	inc	1, iz
	.byte 0xd7
	swi	2
	inc	6, wa
	.byte 0xe7
	ldda16	wa, 1033
	.byte 0x9f, 0x04
	xor	(xwa), xwa
	cp	d, l
	.byte 0x01
	jr	ule, 5
	.byte 0xd7
	swi	2
	pop_sr
	swi	7
	swi	7
	.byte 0xd7
	swi	2
	add	w, l
	nop
	jr	z, -83
	.byte 0xd7
	swi	2
	inc	6, wa
	halt
	lds	wa, 3
	calr	993
	pop	xiz
	inc	2, xsp
	ret
	dec	2, xsp
	ld	(xsp), a
	calr	65412
	ld	a, (xsp)
	extz	wa
	calr	63826
	inc	2, xsp
	ret
	dec	2, xsp
	ld	(xsp), a
	calr	63892
	ld	a, (xsp)
	extz	wa
	calr	63809
	inc	2, xsp
	ret
	dec	2, xsp
	ld	(xsp), a
	calr	65378
	ld	a, (xsp)
	extz	wa
	calr	63775
	inc	2, xsp
	ret
	dec	2, xsp
	ld	(xsp), a
	calr	65361
	.byte 0xc1
	ldb	d, 138
	push	xsp
	nop
	jr	nz, 7
	ld	a, (xsp)
	extz	wa
	calr	65498
	inc	2, xsp
	ret
	dec	2, xsp
	ld	(xsp), a
	calr	65337
	.byte 0xc1
	ldb	d, 138
	push	xsp
	nop
	jr	nz, 17
	ld	a, (xsp)
	extz	wa
	calr	65474
	calr	65174
	calr	63715
	stda8	35425, l
	inc	2, xsp
	ret

FDC_Exception_Status_Decoder:
	ldada xde, 35424
	ld c, (xde + 1)
	ld a, c
	and a, 0xC0
	cp a, 0x40
	jr z, FDC_StatusDecode_AbnormalTerm
	cp a, 0x80
	jr z, FDC_StatusDecode_InvalidCommand
	cp a, 0xC0
	jr z, FDC_StatusDecode_DriveNotReady
	cps a, 0
	jr nz, FDC_StatusDecode_UnknownIC
	ldb l, 0x0
	ret

FDC_StatusDecode_DriveNotReady:
	stdi8 35584, 255
	ldb l, 0x0
	ret

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
	ldw wa, 0x2F
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
;   format codes (0x33, 0x34, 0x35, 0x36, 0x47, 0x4F, etc.).
; Section 3: Format parameter loading - sector size, head count,
;   track count from memory locations 35369-35386.
; Section 4: DMA parameter validation - checks that sector count,
;   byte count, buffer pointers are non-zero before proceeding.
; Returns: HL=0xFFFF on failure, 0 on success.
; Uses ldio, (R+d16) addressing. 460 bytes.
FDC_HardwareSetup:
	ldio	248, 11
	.byte 0xf0, 0xe0
	ldw	bc, 8577
	and	a, 248
	set	2, a
	ld	(xbc), a
	ldio	248, 40
	.byte 0xf0, 0xed
	ldw	bc, 8577
	and	a, 143
	or	a, 80
	ld	(xbc), a
	ldio	248, 12
	.byte 0xf0, 0xe0
	ldw	bc, 8577
	and	a, 143
	or	a, 96
	ld	(xbc), a
	ret
	dec	2, xsp
	ld	(xsp), a
	calr	63542
	.byte 0xc1
	ldb	d, 138
	push	xsp
	nop
	jrl	nz, 214
	ld	a, (xsp)
	stda8	35368, a
	calr	208
	cps	l, 0
	jrl	nz, 200
	ld	a, (xsp)
	cp	a, 51
	jr	z, 30
	cp	a, 52
	jr	z, 25
	cp	a, 54
	jr	z, 10
	cp	a, 53
	jr	z, 5
	cp	a, 71
	jr	nz, 20
	ld	a, (xsp)
	extz	wa
	calr	65227
	jrl	163
	ld	a, (xsp)
	extz	wa
	calr	65241
	jrl	153
	ld	a, (xsp)
	res	4, a
	cp	a, 79
	jr	nz, 10
	ld	a, (xsp)
	extz	wa
	calr	65221
	jrl	133
	ld	a, (xsp)
	and	a, 15
	cp	a, 14
	jr	z, 10
	ld	a, (xsp)
	and	a, 15
	cp	a, 11
	jr	nz, 9
	ld	a, (xsp)
	extz	wa
	calr	65191
	jr	104
	ld	a, (xsp)
	extz	wa
	calr	65107
	.byte 0xc1
	ldb	d, 138
	push	xsp
	nop
	jr	nz, 90
	.byte 0x87
	push	xsp
	ldio	102, 85
	.byte 0x87
	push	xsp
	pop_sr
	jr	nz, 5
	calr	171
	jr	75
	ldda8	a, 35369
	and	a, 1
	sll	a, 2
	ld	e, a
	ldda8	a, 35370
	and	a, 3
	ld	c, a
	ld	a, e
	or	a, c
	ld	a, e
	set	0, a
	extz	wa
	calr	65067
	ld	a, (xsp)
	cp	a, 15
	jr	z, 25
	cp	a, 77
	jr	z, 15
	cps	a, 7
	jr	z, 9
	cps	a, 4
	jr	z, 5
	cp	a, 74
	jr	nz, 12
	jr	13
	calr	158
	jr	8
	calr	192
	jr	3
	calr	196
	inc	2, xsp
	ret
	ldda8	a, 35368
	cp	a, 79
	jr	z, 20
	cp	a, 51
	jr	z, 15
	cp	a, 52
	jr	z, 10
	cp	a, 71
	jr	z, 5
	cp	a, 53
	jr	nz, 3
	ldb	l, 0
	ret
	ldda8	a, 35368
	and	a, 31
	cp	a, 30
	jr	z, 29
	cp	a, 29
	jr	z, 24
	cp	a, 25
	jr	z, 19
	cp	a, 16
	jr	z, 17
	cp	a, 17
	jr	z, 9
	cp	a, 15
	jr	ugt, 7
	cps	a, 2
	jr	c, 3
	ldb	l, 0
	ret
	ldb	l, 1
	ret
	ldda8	a, 35381
	and	a, 3
	extz	wa
	jrl	-603
	ldda8	a, 35383
	sll	a, 4
	ld	e, a
	ldda8	a, 35384
	and	a, 15
	ld	c, a
	ld	a, e
	or	a, c
	extz	wa
	calr	64906
	ldda8	a, 35385
	sll	a, 1
	ld	e, a
	ldda8	a, 35386
	and	a, 1
	ld	c, a
	ld	a, e
	or	a, c
	extz	wa
	jrl	-657
	ldda8	a, 35374
	and	a, 7
	extz	wa
	calr	64867
	ldda8	a, 35378
	extz	wa
	calr	64858
	ldda8	a, 35379
	extz	wa
	calr	64849
	ldda8	a, 35380
	extz	wa
	jrl	-696
	ldda8	a, 35382
	extz	wa
	jrl	-705
	ldda8	a, 35371
	extz	wa
	calr	64822
	ldda8	a, 35372
	and	a, 1
	extz	wa
	calr	64810
	ldda8	a, 35373
	extz	wa
	calr	64801
	ldda8	a, 35374
	and	a, 7
	extz	wa
	calr	64789
	ldda8	a, 35375
	extz	wa
	calr	64780
	ldda8	a, 35376
	extz	wa
	calr	64771
	ldda8	a, 35368
	cp	a, 221
	jr	z, 10
	cp	a, 217
	jr	z, 5
	cp	a, 209
	jr	nz, 3
	jrl	-196
	ldda8	a, 35377
	extz	wa
	calr	64740
	ret
	.byte 0xd1
	ld	xiz, 16266
	jr	z, 3
	lds	hl, 0
	ret
	.byte 0xd1
	ld	xix, 16266
	jr	z, 3
	lds	hl, 0
	ret
	.byte 0xd1
	ld	xwa, 212874
	jr	z, 3
	lds	hl, 0
	ret
	.byte 0xd1
	popw	de
	.byte 0x8a
	push	xsp
	.byte 0x01
	nop
	jr	z, 3
	lds	hl, 0
	ret
	.byte 0xd1
	rcf
	cp	(xde+63), l
	swi	7
	jr	z, 3
	lds	hl, 0
	ret
	.byte 0xd1
	popw	wa
	.byte 0x8a
	push	xsp
	.byte 0x01
	nop
	jr	z, 3
	lds	hl, 0
	ret
	ldw	hl, 65535
	ret
	.byte 0xd1
	ld	xiz, 16266
	jr	z, 3
	lds	hl, 0
	ret
	.byte 0xd1
	ld	xix, 16266
	jr	z, 3
	lds	hl, 0
	ret
	.byte 0xd1
	ld	xwa, 212874
	jr	z, 3
	lds	hl, 0
	ret
	.byte 0xd1
	popw	de
	.byte 0x8a
	push	xsp
	.byte 0x01
	nop
	jr	z, 3
	lds	hl, 0
	ret
	.byte 0xd1
	rcf
	cp	(xde+63), l
	swi	7
	jr	z, 3
	lds	hl, 0
	ret
	.byte 0xd1
	popw	wa
	.byte 0x8a
	push	xsp
	push_sr
	nop
	jr	z, 8
	.byte 0xd1
	popw	wa
	cp	(xde+63), l
	nop
	jr	nz, 4
	ldw	hl, 65535
	ret
	lds	hl, 0
	ret
	.byte 0xd1
	popw	de
	cp	(xde+63), l
	swi	7
	jr	z, 3
	lds	hl, 0
	ret
	.byte 0xd1
	ld	xwa, 16266
	jr	z, 3
	lds	hl, 0
	ret
	ldw	hl, 65535
	ret
	ret

FDC_Set_Status:
	cpdi8 35364, 0
	jr nz, FDC_SetStatus_AlreadySet
	stda8 35364, a
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
	ldda8 l, 35364
	ret


; --- FDC_ClearStatus_InitTimer: Clear FDC status and start timeout ---
; Clears FDC status byte (35364) to 0, initializes result buffer (35424)
; to 0xFF, saves prevbank state, starts timer-based timeout loop.
; Polls with cps bc, 0 for completion signal.
; Uses prevbank (D7 FA) for timer state management.
FDC_ClearStatus_InitTimer:
	stdi8	35364, 0
	ret
	stdi8	35424, 255
	ret
	push	xiz
	.byte 0xd7
	swi	2
	pop_sr
	.byte 0xf4, 0x01
	ldda16	iz, 1033
	lds	bc, 0
	.byte 0xc1
	jr	f, -118
	push	xsp
	swi	7
	jr	z, 3
	ldw	bc, 65535
	ldda16	wa, 1033
	sub	wa, iz
	.byte 0xd7
	swi	2
	.byte 0xf0
	jr	ule, 9
	ldw	wa, 9
	calr	65444
	ldw	bc, 65535
	cps	bc, 0
	jr	z, -34
	pop	xiz
	ret


SOME_DELAY:
	srl wa, 1
	ldda16 xde, 1033
	lds hl, 0
	cp hl, 0xFFFF
	ret nc

SOME_DELAY_Loop:
	ldda16 xbc, 1033
	sub bc, de
	cp bc, wa
	ret ugt
	inc 1, hl
	cp hl, 0xFFFF
	jr c, SOME_DELAY_Loop
	ret


FDC_InitSequence_Short:
	ldw	wa, 40
	jr	-39

FDC_InitSequence_Full:
	calr FDC_Init_Sequence_1
	calr FDC_Pulse_PH0
	stdi8 35434, 0
	stdi8 35584, 0
	calr FDC_HardwareSetup
	calr FDC_INIT
	jrl FDC_CONFIG_VERIFY

; --- FDC_SeekRecalibrate: Seek/recalibrate FDC head position ---
; Saves current head number via prevbank register.
; Sets head = 5 (recalibrate parameter), sends FDC command,
; checks result status. If error, retries with seek command.
; Second section loads command byte 0xC6 (Read ID) for verification.
; Contains error checking and retry logic with FDC_Set_Status calls.
; Restores head number from prevbank on exit.
FDC_SeekRecalibrate:
	.byte 0xd7
	swi	2
	.byte 0x04
	ldda8	a, 35382
	.byte 0xc7
	swi	3
	.byte 0x99
	stdi8	35382, 5
	stdi8	35588, 255
	calr	45
	stdi8	35588, 0
	calr	65387
	lds	wa, 7
	calr	64643
	calr	65385
	.byte 0xc1
	ldb	d, 138
	push	xsp
	nop
	jr	z, 5
	stdi8	35588, 255
	.byte 0xc7
	swi	3
	.byte 0x89
	stda8	35382, a
	ldw	wa, 16
	calr	65408
	.byte 0xd7
	swi	2
	halt
	ret
	ldda8	a, 35382
	.byte 0xc1, 0x04, 0x8b, 0xf1
	ret	z
	.byte 0xc1
	ldw	iz, 6538
	.byte 0x04
	sub	(xhl-40), b
	calr	65383
	calr	65326
	ldw	wa, 15
	calr	64581
	calr	65323
	.byte 0xc1
	ldb	d, 138
	push	xsp
	nop
	jr	z, 5
	stdi8	35588, 255
	ldw	wa, 16
	jrl	-183
	stdi8	35368, 198
	calr	63873
	calr	65288
	ldw	wa, 198
	calr	64543
	.byte 0xc1
	ldb	d, 138
	push	xsp
	nop
	ret	nz
	jrl	-258
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
	calr	65046
	cps	hl, 0
	jr	z, 8
	stdi8	35432, 1
	jrl	310
	calr	65101
	cps	hl, 0
	jr	nz, 8
	stdi8	35432, 8
	jrl	295
	stdi8	35432, 1
	jrl	287
	stdi8	35364, 0
	calr	65411
	.byte 0xc1
	ldb	d, 138
	push	xsp
	nop
	jr	z, 22
	ldda8	a, 35364
	.byte 0xc7
	swi	0
	.byte 0x99
	exts	iz
	calr	62634
	.byte 0xc7
	swi	0
	ld	d, (xbc-15)
	.byte 0x8a
	ld	xbc, 3506504568
	popw	wa
	.byte 0x8a
	ldb	w, 209
	incf
	incm8	3, (xhl-16)
	.byte 0x06
	stdi16	35400, 1
	.byte 0xd1
	popw	wa
	.byte 0x8a
	pop_f
	rcf
	.byte 0x8b
	stdi16	35356, 0
	.byte 0xc1
	jr	nov, -118
	push	xsp
	push_sr
	jr	nz, 8
	stdi16	35358, 1024
	jr	6
	stdi16	35358, 512
	.byte 0xd1
	popw	de
	.byte 0x8a
	pop_f
	ccf
	sub	(xhl-34), a
	ldda16	wa, 35358
	.byte 0xd1, 0x1c, 0x8a, 0x88
	ldada	xwa, 35402
	decm	1, (xwa)
	ld	wa, (xwa)
	cps	wa, 0
	jr	z, 18
	ldada	xwa, 35400
	incm	1, (xwa)
	ld	wa, (xwa)
	.byte 0xd1
	incf
	decm8	3, (xhl-16)
	.byte 0x04
	inc	1, iz
	jr	-38
	stda16	35402, iz
	.byte 0xd1
	rcf
	.byte 0x8b
	pop_f
	popw	wa
	.byte 0x8a
	calr	65325
	.byte 0xc1
	ldb	d, 138
	push	xsp
	nop
	jr	z, 58
	.byte 0xc1
	ldb	d, 138
	push	xsp
	push	110
	.byte 0x06
	calr	62482
	jrl	131
	calr	64913
	cp	hl, 65535
	jr	z, 11
	calr	62484
	stdi8	35588, 255
	calr	65234
	.byte 0xd1
	ccf
	.byte 0x8b
	pop_f
	popw	de
	decm8	8, (xde-63)
	.byte 0x8a
	jr	ge, -63
	jr	-118
	ldb	a, 201
	dec	6, wa
	.byte 0x54
	stdi8	35364, 16
	jr	86
	ldda16	wa, 35602
	sub	wa, iz
	stda16	35402, wa
	.byte 0xd1
	popw	de
	.byte 0x8a
	push	xsp
	nop
	nop
	jr	z, 59
	ldada	xbc, 35404
	ldda16	wa, 35356
	extz	xwa
	.byte 0xa1, 0x80
	ld	(xbc), xwa
	stdi16	35400, 1
	stdi8	35373, 1
	ldda8	a, 35369
	xor	a, 1
	stda8	35369, a
	stda8	35372, a
	.byte 0xc1
	pushw	ix
	.byte 0x8a
	push	xsp
	nop
	jr	nz, 12
	ldada	xwa, 35371
	incm8	1, (xwa)
	ld	a, (xwa)
	stda8	35382, a
	.byte 0xd1
	popw	de
	.byte 0x8a
	push	xsp
	nop
	nop
	jrl	nz, -296
	popw	iz
	ret
	pushw	iz
	stdi8	35432, 8
	jrl	288
	stdi8	35364, 0
	calr	65104
	.byte 0xc1
	ldb	d, 138
	push	xsp
	nop
	jr	z, 22
	ldda8	a, 35364
	.byte 0xc7
	swi	0
	.byte 0x99
	exts	iz
	calr	62327
	.byte 0xc7
	swi	0
	ld	d, (xbc-15)
	.byte 0x8a
	ld	xbc, 3506504824
	popw	wa
	.byte 0x8a
	ldb	w, 209
	incf
	incm8	3, (xhl-16)
	.byte 0x06
	stdi16	35400, 1
	.byte 0xd1
	popw	wa
	.byte 0x8a
	pop_f
	rcf
	.byte 0x8b
	stdi16	35356, 0
	.byte 0xc1
	jr	nov, -118
	push	xsp
	push_sr
	jr	nz, 8
	stdi16	35358, 1024
	jr	6
	stdi16	35358, 512
	.byte 0xd1
	popw	de
	.byte 0x8a
	pop_f
	ccf
	sub	(xhl-34), a
	ldda16	wa, 35358
	.byte 0xd1, 0x1c, 0x8a, 0x88
	ldada	xwa, 35402
	decm	1, (xwa)
	ld	wa, (xwa)
	cps	wa, 0
	jr	z, 18
	ldada	xwa, 35400
	incm	1, (xwa)
	ld	wa, (xwa)
	.byte 0xd1
	incf
	decm8	3, (xhl-16)
	.byte 0x04
	inc	1, iz
	jr	-38
	stda16	35402, iz
	.byte 0xd1
	rcf
	.byte 0x8b
	pop_f
	popw	wa
	.byte 0x8a
	calr	154
	.byte 0xc1
	ldb	d, 138
	push	xsp
	nop
	jr	z, 59
	.byte 0xc1
	ldb	d, 138
	push	xsp
	push	110
	push	30
	.byte 0xdf, 0xf2
	calr	62189
	jrl	129
	.byte 0xc1
	ldb	d, 138
	push	xsp
	pushw	sp
	jr	z, 122
	calr	62176
	stdi8	35588, 255
	calr	64926
	.byte 0xd1
	ccf
	.byte 0x8b
	pop_f
	popw	de
	decm8	8, (xde-63)
	.byte 0x8a
	jr	ge, -63
	jr	-118
	ldb	a, 201
	dec	6, wa
	.byte 0x54
	stdi8	35364, 32
	jr	86
	ldda16	wa, 35602
	sub	wa, iz
	stda16	35402, wa
	.byte 0xd1
	popw	de
	.byte 0x8a
	push	xsp
	nop
	nop
	jr	z, 59
	ldada	xbc, 35404
	ldda16	wa, 35356
	extz	xwa
	.byte 0xa1, 0x80
	ld	(xbc), xwa
	stdi16	35400, 1
	stdi8	35373, 1
	ldda8	a, 35369
	xor	a, 1
	stda8	35369, a
	stda8	35372, a
	.byte 0xc1
	pushw	ix
	.byte 0x8a
	push	xsp
	nop
	jr	nz, 12
	ldada	xwa, 35371
	incm8	1, (xwa)
	ld	a, (xwa)
	stda8	35382, a
	.byte 0xd1
	popw	de
	.byte 0x8a
	push	xsp
	nop
	nop
	jrl	nz, -297
	popw	iz
	ret
	stdi8	35368, 197
	calr	63201
	calr	64616
	ldw	wa, 197
	calr	63871
	.byte 0xc1
	ldb	d, 138
	push	xsp
	nop
	ret	nz
	jrl	-930
; --- FDC_MODE_CONFIG: Configure FDC format parameters by disk type ---
; Reads format type from state variable 35436.
; Dispatch by type: 0=default, 2=MFM, 3/4/5 = other formats.
; Sets per-format parameters:
;   35374: sectors per track (2 or 3)
;   35379: bytes per sector code (80/108/116 = 128/256/512 bytes)
;   35382: head number, 35371: track number, 35380: gap length (0xE5)
;   35372: side number, 35369: drive number
; Then enters sector counting/validation loop.
; Uses (R+d16) addressing for all state variables. 184 bytes.
FDC_MODE_CONFIG:
	calr	-987
	cpdi8	35364, 0
	jrl	nz, 173
	calr	746
	cpdi8	35364, 0
	jrl	nz, 162
	calr	-843
	cpdi8	35364, 0
	jrl	nz, 151
	ldda8	a, 35436
	cps	a, 2
	jr	z, 40
	cps	a, 3
	jr	z, 24
	cps	a, 5
	jr	z, 8
	cps	a, 4
	jr	z, 4
	cps	a, 0
	jr	nz, 34
	stdi8	35374, 2
	stdi8	35379, 80
	jr	22
	stdi8	35374, 2
	stdi8	35379, 108
	jr	10
	stdi8	35374, 3
	stdi8	35379, 116
	stdi8	35382, 0
	stdi8	35371, 0
	stdi8	35380, 229
	stdi8	35372, 0
	stdi8	35369, 0
	jr	54
	.byte 0xc1
	ldw	iz, 6538
	ccf
	.byte 0x8a
	calr	76
	cpdi8	35364, 0
	jr	nz, 50
	ldda8	a, 35369
	xor	a, 1
	stda8	35369, a
	stda8	35372, a
	cpdi8	35372, 0
	jr	nz, 16
	ldada	xwa, 35371
	incm8	1, (xwa)
	ld	a, (xwa)
	stda8	35382, a
	stda8	35346, a
	ldda8	a, 35382
	extz	wa
	.byte 0xd1
	ldio	139, 240
	jr	ule, -66
; --- FDC_MC_EXIT: FORMAT command execution and sector fill ---
; Calls cleanup, sets up FORMAT command (command byte 0x4D).
; Loads format buffer address from 35440, stores to DMA source (35404).
; Main loop fills format buffer with [track, head, sector, size] tuples:
;   For each sector: load index, compute buffer[index] address,
;   store track/head/sector/size bytes, increment byte count (35356).
; Handles odd sector counts separately.
; Tail: DMA transfer initiation and multi-sector retry logic.
; Uses (R+d16) addressing for buffer and state access. 536 bytes.
FDC_MC_EXIT:
	.byte 0xc1
	ldb	d, 138
	push	xsp
	nop
	.byte 0xf2, 0xd0
	jr	ugt, -7
	.byte 0xee
	calr	64521
	stdi8	35588, 255
	ret
	calr	64580
	.byte 0xc1
	ldb	d, 138
	push	xsp
	nop
	jrl	nz, -3722
	calr	22
	stdi8	35368, 77
	ldada	xwa, 35440
	stda32	35404, xwa
	calr	62949
	calr	63057
	jrl	403
	stdi8	35373, 1
	stdi16	35356, 0
	ldda16	ix, 35594
	srl	ix, 1
	ldb	e, 0
	lds	iy, 0
	cp	iy, ix
	jrl	nc, 262
	ld	a, e
	inc	1, e
	extz	wa
	ldada	xbc, 35440
	ld	hl, wa
	extz	xhl
	add	xhl, xbc
	ldda8	a, 35371
	ld	(xhl), a
	incdi16	1, 35356
	ld	a, e
	inc	1, e
	extz	wa
	ldada	xbc, 35440
	ld	hl, wa
	extz	xhl
	add	xhl, xbc
	ldda8	a, 35372
	ld	(xhl), a
	incdi16	1, 35356
	ld	a, e
	inc	1, e
	extz	wa
	ldada	xbc, 35440
	ld	hl, wa
	extz	xhl
	add	xhl, xbc
	ldda8	a, 35373
	ld	(xhl), a
	incdi16	1, 35356
	ld	a, e
	inc	1, e
	extz	wa
	ldada	xbc, 35440
	ld	hl, wa
	extz	xhl
	add	xhl, xbc
	ldda8	a, 35374
	ld	(xhl), a
	incdi16	1, 35356
	ld	a, e
	inc	1, e
	extz	wa
	ldada	xbc, 35440
	ld	hl, wa
	extz	xhl
	add	xhl, xbc
	ldda8	a, 35371
	ld	(xhl), a
	incdi16	1, 35356
	ld	a, e
	inc	1, e
	extz	wa
	ldada	xbc, 35440
	ld	hl, wa
	extz	xhl
	add	xhl, xbc
	ldda8	a, 35372
	ld	(xhl), a
	incdi16	1, 35356
	.byte 0xd1
	ld	xiz, 16266
	jr	nz, 28
	incdi8	1, 35373
	ld	a, e
	inc	1, e
	extz	wa
	ldada	xbc, 35440
	ld	hl, wa
	extz	xhl
	add	xhl, xbc
	ldda8	a, 35373
	ld	(xhl), a
	jr	29
	ldda16	wa, 35594
	srl	wa, 1
	addda8	a, 35373
	ld	l, a
	ld	a, e
	inc	1, e
	extz	wa
	ldada	xbc, 35440
	extz	xwa
	add	xwa, xbc
	ld	(xwa), l
	incdi16	1, 35356
	ld	a, e
	inc	1, e
	extz	wa
	ldada	xbc, 35440
	ld	hl, wa
	extz	xhl
	add	xhl, xbc
	ldda8	a, 35374
	ld	(xhl), a
	incdi16	1, 35356
	incdi8	1, 35373
	inc	1, iy
	cp	iy, ix
	jrl	c, -262
	ldda16	wa, 35594
	bit	0, wa
	ret	z
	ld	a, e
	inc	1, e
	extz	wa
	ldada	xbc, 35440
	ld	hl, wa
	extz	xhl
	add	xhl, xbc
	ldda8	a, 35371
	ld	(xhl), a
	incdi16	1, 35356
	ld	a, e
	inc	1, e
	extz	wa
	ldada	xbc, 35440
	ld	hl, wa
	extz	xhl
	add	xhl, xbc
	ldda8	a, 35372
	ld	(xhl), a
	incdi16	1, 35356
	ld	a, e
	inc	1, e
	extz	wa
	ldada	xbc, 35440
	ld	hl, wa
	extz	xhl
	add	xhl, xbc
	ldda16	wa, 35594
	ld	(xhl), a
	incdi16	1, 35356
	ld	a, e
	inc	1, e
	extz	wa
	ldada	xbc, 35440
	ld	de, wa
	extz	xde
	add	xde, xbc
	ldda8	a, 35374
	ld	(xde), a
	incdi16	1, 35356
	ret
	stdi8	35368, 77
	calr	62532
	calr	63947
	ldw	wa, 77
	calr	63202
	.byte 0xc1
	ldb	d, 138
	push	xsp
	nop
	ret	nz
	jrl	-1599
	pushw	iz
	.byte 0xf0
	pushw	wa
	.byte 0xbb
	ldw	wa, 254
	calr	63182
	.byte 0xc1
	ldb	d, 138
	push	xsp
	nop
	jr	z, 8
	ldw	wa, 49
	calr	63861
	jr	15
	lds	iz, 1
	cps	iz, 0
	jr	z, 9
	ldw	wa, 10
	calr	63948
	djnz16	iz, -9
	popw	iz
	ret
	.byte 0xf0
	pushw	wa
	lda	xwa, (xhl)
	ret
	nop
	jrl	-2395
; --- FDC_STATUS_COPY: Copy FDC status and validate drive count ---
; Copies status from source to destination via (R+d16) load/store.
; Validates drive count (35396): 0 or 1 are valid, else error 0xFE.
; Three exit paths with disk-changed flag (35434) management:
;   Set flag (35434=255) or clear flag (35434=0).
FDC_STATUS_COPY:
	.byte 0xc1
	ldb	h, 138
	pop_f
	ldb	d, 138
	ret
	ldda16	wa, 35396
	cps	wa, 1
	jr	z, 13
	cps	wa, 0
	jr	nz, 2
	jr	13
	ldw	wa, 254
	calr	63806
	ret
	stdi8	35434, 255
	ret
	stdi8	35434, 0
	ret
; --- FDC_INTERRUPT_HANDLER: FDC interrupt service routine ---
; Enables interrupts via prevbank (D7 FA 04 = ei 4).
; Checks FDC status register, reads result data.
; Tests status bits to determine result type:
;   bit 7 -> status 0x32 (overrun), bit 5 -> status 0x31 (no data),
;   bit 6 -> status 0x2F (bad cylinder).
; Disables interrupts (D7 FA 05 = di 4) before return.
FDC_INTERRUPT_HANDLER:
	.byte 0xd7
	swi	2
	.byte 0x04, 0xc1
	ldb	d, 138
	push	xsp
	nop
	jr	nz, 64
	lds	wa, 4
	calr	63086
	.byte 0xc1
	ldb	d, 138
	push	xsp
	nop
	jr	nz, 52
	calr	62516
	.byte 0xc1
	ldb	d, 138
	push	xsp
	nop
	jr	nz, 42
	calr	61050
	.byte 0xc7
	swi	3
	cp	(xsp-57), hl
	ldw	hl, 26119
	.byte 0x06
	ldw	wa, 50
	calr	63743
	.byte 0xc7
	swi	3
	ldw	hl, 28165
	.byte 0x06
	ldw	wa, 49
	calr	63731
	.byte 0xc7
	swi	3
	ldw	hl, 26118
	.byte 0x06
	ldw	wa, 47
	calr	63719
	.byte 0xd7
	swi	2
	halt
	ret

FDC_CommandEntry:
	push xiz
	ld xiz, (xsp + 8)
	cpw (xiz), 0x0
	jr nz, FDC_CommandEntry_EnableIRQ
	stdi8 35350, 0

FDC_CommandEntry_EnableIRQ:
	ei 6
	cpdi8 35350, 165
	jr nz, FDC_CommandEntry_CopyParams
	ei 0
	ldw wa, 0xFB
	calr FDC_Set_Status
	extz hl
	jrl FDC_Handler_Return

FDC_CommandEntry_CopyParams:
	stdi8 35350, 165
	ei 0
	ld wa, (xiz)
	stda16 35392, xwa
	ld wa, (xiz + 2)
	stda16 35394, xwa
	ld wa, (xiz + 4)
	stda16 35396, xwa
	ld wa, (xiz + 6)
	stda16 35398, xwa
	ld wa, (xiz + 8)
	stda16 35400, xwa
	ld wa, (xiz + 10)
	stda16 35402, xwa
	ld xwa, (xiz + 12)
	stda32 35404, xwa
	ld wa, (xiz)
	stda16 35408, xwa
	ld wa, (xiz + 2)
	stda16 35410, xwa
	ld wa, (xiz + 4)
	stda16 35412, xwa
	ld wa, (xiz + 6)
	stda16 35414, xwa
	ld wa, (xiz + 8)
	stda16 35416, xwa
	ld wa, (xiz + 10)
	stda16 35418, xwa
	ld xwa, (xiz + 12)
	stda32 35420, xwa
	stdi8 35360, 0
	ldmm8 35366, 35364
	stdi8 35364, 0
	calr FDC_COMMAND_DISPATCHER
	cps l, 0
	jr	nz, 116
	ldda16 xwa, 35392
	cp wa, 0xB
	jr	ugt, 100
	add wa, wa
	lda_24 xix, 0xea98ca
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xf97d8d
	jp_dri 8, 0x07, 0xF0, 0xE0


; =============================================================================
; FDC (Floppy Disk Controller) Handler Routines - Label Definitions
; These labels point to routines in raw byte sections
; Full disassembly documentation saved to docs/fdc_disassembly.md
; =============================================================================

; FDC routine labels (code is in raw byte sections)
	; (EQU->inline label) FDC_INIT = 0xF96BBF
	; (EQU->inline label) FDC_CONFIG_VERIFY = 0xF96BD0
	; (EQU->inline label) FDC_CMD_DISPATCH_SUB = 0xF96D95
	; (EQU->inline label) FDC_STATUS_HANDLER = 0xF97696
	; (EQU->inline label) FDC_CMD_EXEC = 0xF976E4
	; (EQU->inline label) FDC_SECTOR_XFER = 0xF97835
	; (EQU->inline label) FDC_MODE_CONFIG = 0xF97984
	; (EQU->inline label) FDC_CMD_ENABLE = 0xF97C21
	; (EQU->inline label) FDC_CMD_DISABLE = 0xF97C4B
	; (EQU->inline label) FDC_STATUS_COPY = 0xF97C54
	; (EQU->inline label) FDC_OUTPUT_CTRL = 0xF97C5B
	; (EQU->inline label) FDC_INTERRUPT_HANDLER = 0xF97C7C

; Forward references to helper routines in raw byte sections
	; (EQU->inline label) FDC_DRIVE_DETECT = 0xF97544
	; (EQU->inline label) FDC_DRIVE_STATUS = 0xF97592
	; (EQU->inline label) FDC_PRE_OP_CHECK = 0xF975AC
	; (EQU->inline label) FDC_TIMING_DELAY = 0xF975DC
	; (EQU->inline label) FDC_POST_OP = 0xF975E2
	; (EQU->inline label) FDC_CMD_SEND = 0xF972F9
	; (EQU->inline label) FDC_DETECT_CHECK = 0xF974FE

; Jump targets within FDC routines
	; (EQU->inline label) FDC_CE_DISPATCH = 0xF9782A
	; (EQU->inline label) FDC_CE_EXIT = 0xF97833
	; (EQU->inline label) FDC_SX_MAIN = 0xF9795E
	; (EQU->inline label) FDC_SX_EXIT = 0xF97967
	; (EQU->inline label) FDC_MC_EXIT = 0xF97A3C


	.org 0xF97D8D - 0xE00000, 0xFF
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
	ldw wa, 0xFF
	calr FDC_Set_Status

FDC_Handler_ExitStatus:
	stdi8 35350, 90
	ldda8 l, 35364
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
	.byte 0xd1, 0x1c, 0x8a
	push	xsp
	nop
	nop
	ret	z
	ldda16	wa, 35392
	cps	wa, 4
	jr	z, 36
	cps	wa, 3
	ret	nz
	ld8_24	c, 1179648
	ldda32	xhl, 35406
	ld	(xhl), c
	inc	1, xhl
	stda32	35406, xhl
	.byte 0xd1, 0x1c, 0x8a
	push	xde
	.byte 0x01
	nop
	ret	nz
	calr	61988
	calr	62000
	ret
	ldda32	xhl, 35406
	ld	c, (xhl)
	st8_24	1179648, c
	inc	1, xhl
	stda32	35406, xhl
	jr	-34

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
	stdi8 265, 8
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
	and l, 0xF0
	cp l, 0x80
	jr nz, INT4_WaitNonDMAMode

INT4_SendSpecifyCmd:
	ldw wa, 0x8
	calr FDC_Write_Data

INT4_StoreResultBase:
	ldada xiz, 35424
	inc 1, xiz

INT4_ReadResultLoop:
	calr FDC_Wait_Status_Timeout
	calr FDC_Read_Data
	lda_dpi XSP, 0xF8

INT4_WaitResultReady:
	calr FDC_Read_Status
	bit 7, l
	jr z, INT4_WaitResultReady
	calr FDC_Read_Status
	bit 6, l
	jr nz, INT4_ReadResultLoop
	calr FDC_Exception_Status_Decoder
	cpdi8 35425, 128
	jr nz, INT4_WaitDataReady

INT4_ExitRestore:
	stdi8 35424, 0
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
	set_dd8 0, 0x34
	ldw wa, 0xA
	calr SOME_DELAY
	res_dd8 0, 0x34
	ldw wa, 0xA
	jrl SOME_DELAY

	; then do a lot of other stuff I still don't undertsand:

	ldio 0x47, 0x1E
	bit_dd8 6, 0x34	; Port D bit 6: "FD.I/O signal"
	ret nz
	ldb a, 0x0
	stdi16 35620, 0
	stdi16 35622, 0
	stdi16 35624, 0
	cps a, 0
	jr nz, FDC_Reset_SetDD_SectorCount
	stdi16 35626, 224
	jr FDC_Reset_BuildParams

FDC_Reset_SetDD_SectorCount:
	stdi16 35626, 211

FDC_Reset_BuildParams:
	stdi16 35628, 0
	stdi16 35630, 0
	lds32 xwa, 0
	stda32 35632, xwa
	ldada xwa, 35620
	push xwa
	calr FDC_CommandEntry
	stdi16 35620, 3
	stdi16 35622, 0
	stdi16 35624, 0
	stdi16 35626, 0
	stdi16 35628, 1
	stdi16 35630, 1
	ldada xwa, 35636
	stda32 35632, xwa
	ldada xwa, 35620
	push xwa
	calr FDC_CommandEntry
	stdi16 35620, 3
	stdi16 35622, 0
	stdi16 35624, 0
	stdi16 35626, 78
	stdi16 35628, 1
	stdi16 35630, 1
	ldada xwa, 35636
	stda32 35632, xwa
	ldada xwa, 35620
	push xwa
	calr FDC_CommandEntry
	stdi16 35620, 3
	stdi16 35622, 0
	stdi16 35624, 0
	stdi16 35626, 10
	stdi16 35628, 1
	stdi16 35630, 1
	ldada xwa, 35636
	stda32 35632, xwa
	ldada xwa, 35620
	push xwa
	calr FDC_CommandEntry
	stdi16 35620, 3
	stdi16 35622, 0
	stdi16 35624, 0
	stdi16 35626, 40
	stdi16 35628, 1
	stdi16 35630, 1
	ldada xwa, 35636
	stda32 35632, xwa
	ldada xwa, 35620
	push xwa
	calr FDC_CommandEntry
	lda xsp, (xsp + 20)
	ldw wa, 0xC8
	calr SOME_DELAY
	incdi16 1, 58330
	ret

Check_for_Floppy_Disk_Change:
	bit_dd8 6, 0x34
	jr z, Detected_Floppy_Disk_Change
	ldb l, 0x0
	ret

Detected_Floppy_Disk_Change:
	ldb l, 0x1
	ret

; End of FDC routines
