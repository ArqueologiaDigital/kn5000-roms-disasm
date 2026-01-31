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
	LD L, (FDC_MAP__BASE_ADDR + 08h)
	RET

FDC_Read_Data:
	LD L, (FDC_MAP__BASE_ADDR + 0Ah)
	RET

FDC_Send_Command:
	db 0F2h, 008h, 000h, 011h, 041h, 00Eh, 0C1h, 022h
	db 08Bh, 019h, 020h, 08Bh, 0F1h, 022h, 08Bh, 041h
	db 00Eh

FDC_Write_Data:
	LD (FDC_MAP__BASE_ADDR + 0Ah), A
	RET

FDC_WaitReady:
	db 03Eh, 0D1h, 009h, 004h, 026h, 0D7h, 0FAh, 003h
	db 080h, 000h, 0D7h, 0FAh, 0CFh, 080h, 000h, 06Eh
	db 029h, 01Eh, 0C9h, 0FFh, 0CFh, 0CCh, 01Fh, 0CFh
	db 089h, 0D8h, 012h, 0D8h, 0D8h, 06Eh, 003h, 0D7h
	db 0FAh, 0A8h, 0D1h, 009h, 004h, 020h, 0DEh, 0A0h
	db 0D8h, 0CFh, 0F4h, 001h, 063h, 005h, 0D7h, 0FAh
	db 003h, 0FFh, 0FFh, 0D7h, 0FAh, 0CFh, 080h, 000h
	db 066h, 0D7h, 0D7h, 0FAh, 0D8h, 066h, 005h, 0D8h
	db 0A9h, 01Eh, 033h, 00Ah, 05Eh, 00Eh, 03Eh, 0D1h
	db 009h, 004h, 026h, 0D7h, 0FAh, 003h, 080h, 000h
	db 0D7h, 0FAh, 0CFh, 080h, 000h, 06Eh, 026h, 01Eh
	db 083h, 0FFh, 0CFh, 0CCh, 090h, 0CFh, 0CFh, 090h
	db 06Eh, 003h, 0D7h, 0FAh, 0A8h, 0D1h, 009h, 004h
	db 020h, 0DEh, 0A0h, 0D8h, 0CFh, 0F4h, 001h, 063h
	db 005h, 0D7h, 0FAh, 003h, 0FFh, 0FFh, 0D7h, 0FAh
	db 0CFh, 080h, 000h, 066h, 0DAh, 0D7h, 0FAh, 0D8h
	db 066h, 005h, 0D8h, 0A9h, 01Eh, 0F0h, 009h, 05Eh
	db 00Eh, 030h, 036h, 000h, 01Eh, 05Ah, 0FFh, 0D8h
	db 0AAh, 01Eh, 048h, 00Ah, 0F1h, 004h, 08Bh, 000h
	db 0FFh, 00Eh, 03Eh, 01Eh, 002h, 00Ah, 01Eh, 06Dh
	db 009h, 0DBh, 0CFh, 0FFh, 0FFh, 066h, 00Eh, 01Eh
	db 0B2h, 009h, 0DBh, 0CFh, 0FFh, 0FFh, 066h, 005h
	db 0F1h, 004h, 08Bh, 000h, 0FFh, 0C1h, 020h, 08Ah
	db 03Fh, 0FFh, 076h, 0A0h, 001h, 0F1h, 020h, 08Ah
	db 000h, 0FFh, 030h, 036h, 000h, 01Eh, 021h, 0FFh
	db 0D8h, 0AAh, 01Eh, 00Fh, 00Ah, 01Eh, 03Eh, 009h
	db 0DBh, 0CFh, 0FFh, 0FFh, 066h, 06Fh, 01Eh, 083h
	db 009h, 0DBh, 0CFh, 0FFh, 0FFh, 066h, 066h, 01Eh
	db 0BEh, 009h, 01Eh, 07Ah, 001h, 0C1h, 024h, 08Ah
	db 03Fh, 000h, 066h, 008h, 0F1h, 020h, 08Ah, 000h
	db 000h, 078h, 069h, 001h, 01Eh, 0E6h, 0FEh, 0CFh
	db 033h, 007h, 066h, 0F8h, 01Eh, 0DEh, 0FEh, 0CFh
	db 033h, 006h, 06Eh, 018h, 027h, 000h, 0CFh, 0CFh
	db 080h, 066h, 00Bh, 01Eh, 0CFh, 0FEh, 0CFh, 0CCh
	db 0F0h, 0CFh, 0CFh, 080h, 06Eh, 0F5h, 030h, 008h
	db 000h, 01Eh, 0DEh, 0FEh, 0F1h, 060h, 08Ah, 036h
	db 0EEh, 061h, 01Eh, 06Eh, 004h, 01Eh, 0BBh, 0FEh
	db 0F5h, 0F8h, 047h, 01Eh, 0AFh, 0FEh, 0CFh, 033h
	db 007h, 066h, 0F8h, 01Eh, 0A7h, 0FEh, 0CFh, 033h
	db 006h, 06Eh, 0E7h, 01Eh, 0C9h, 005h, 0C1h, 061h
	db 08Ah, 03Fh, 080h, 06Eh, 0AFh, 0D8h, 0ABh, 01Eh
	db 079h, 006h, 0C1h, 024h, 08Ah, 03Fh, 000h, 066h
	db 008h, 0F1h, 020h, 08Ah, 000h, 000h, 078h, 004h
	db 001h, 030h, 04Fh, 000h, 01Eh, 064h, 006h, 0C1h
	db 024h, 08Ah, 03Fh, 000h, 066h, 008h, 0F1h, 020h
	db 08Ah, 000h, 000h, 078h, 0EFh, 000h, 0C1h, 06Eh
	db 08Ah, 021h, 0C9h, 0CCh, 00Fh, 0D8h, 012h, 0D8h
	db 0D8h, 075h, 09Ch, 000h, 0D8h, 0DDh, 07Ah, 097h
	db 000h, 0D8h, 080h, 0F2h, 0A6h, 098h, 0EAh, 034h
	db 0D3h, 007h, 0F0h, 0E0h, 020h, 0F2h, 0CDh, 06Ch
	db 0F9h, 034h, 0F3h, 007h, 0F0h, 0E0h, 0D8h, 0F1h
	db 06Ch, 08Ah, 000h, 000h, 0F1h, 022h, 08Ah, 002h
	db 000h, 000h, 0C7h, 0FBh, 0A8h, 0D8h, 0AAh, 01Eh
	db 045h, 0FEh, 068h, 07Fh, 0F1h, 06Ch, 08Ah, 000h
	db 000h, 0F1h, 022h, 08Ah, 002h, 000h, 000h, 0C7h
	db 0FBh, 003h, 0C0h, 0D8h, 0AAh, 01Eh, 02Fh, 0FEh
	db 068h, 069h, 0F1h, 06Ch, 08Ah, 000h, 002h, 0F1h
	db 022h, 08Ah, 002h, 000h, 000h, 0C7h, 0FBh, 003h
	db 040h, 0D8h, 0A8h, 01Eh, 019h, 0FEh, 068h, 053h
	db 0F1h, 06Ch, 08Ah, 000h, 003h, 0F1h, 022h, 08Ah
	db 002h, 000h, 000h, 0C7h, 0FBh, 003h, 040h, 0D8h
	db 0A8h, 01Eh, 003h, 0FEh, 068h, 03Dh, 0F1h, 06Ch
	db 08Ah, 000h, 004h, 0F1h, 022h, 08Ah, 002h, 000h
	db 000h, 0C7h, 0FBh, 0A8h, 0D8h, 0AAh, 01Eh, 0EEh
	db 0FDh, 068h, 028h, 0F1h, 06Ch, 08Ah, 000h, 005h
	db 0F1h, 022h, 08Ah, 002h, 000h, 000h, 0C7h, 0FBh
	db 0A8h, 0D8h, 0AAh, 01Eh, 0D9h, 0FDh, 068h, 013h
	db 0F1h, 06Ch, 08Ah, 000h, 000h, 0F1h, 022h, 08Ah
	db 002h, 000h, 000h, 0C7h, 0FBh, 0A8h, 0D8h, 0AAh
	db 01Eh, 0C4h, 0FDh, 0C7h, 0FBh, 089h, 0C9h, 0CEh
	db 00Bh, 0D8h, 012h, 01Eh, 08Dh, 005h, 0C1h, 024h
	db 08Ah, 03Fh, 000h, 066h, 007h, 0F1h, 020h, 08Ah
	db 000h, 000h, 068h, 019h, 01Eh, 0A4h, 00Eh, 0C1h
	db 024h, 08Ah, 03Fh, 000h, 066h, 007h, 0F1h, 020h
	db 08Ah, 000h, 000h, 068h, 008h, 01Eh, 0C4h, 008h
	db 0F1h, 020h, 08Ah, 000h, 000h, 05Eh, 00Eh, 030h
	db 036h, 000h, 01Eh, 084h, 0FDh, 0D8h, 0AAh, 01Eh
	db 072h, 008h, 01Eh, 070h, 0FDh, 0CFh, 0CFh, 0FFh
	db 06Eh, 006h, 030h, 0FCh, 000h, 01Eh, 0FFh, 007h
	db 0DBh, 0A8h, 00Eh

; FDC command dispatcher
; Reads command from (8A40h), dispatches to 12 handlers (0-0xB)
; Uses offset table at 0xEA98B2
FDC_COMMAND_DISPATCHER:			; F96DB1
	LD (8A2Ah), 000h
	LD WA, (8A40h)
	CP WA, 000bh
	JR UGT, FDC_CheckDriveCount
	ADD WA, WA
	LDA XIX, 0EA98B2h
	LD WA, (XIX + WA)
	LDA XIX, FDC_CMD_HANDLER_BASE
	JP T, XIX + WA
; FDC command handler base - entry point for command 0
FDC_CMD_HANDLER_BASE:			; F96DD6
	CALR FDC_SetupFormatParams
	LD L, (8A24h)
	RET

FDC_ReturnZero:
	LD_L 000h
	RET

FDC_ErrorInvalidDrive:
	CALR FDC_Validate_Drive_Head

FDC_CheckDriveCount:
	LD WA, (8A42h)
	LD (8A2Ah), A
	CP (8A2Ah), 001h
	JR ULE, FDC_ValidateCommand
	LD WA, 00feh
	JRL T, FDC_Set_Status

FDC_ValidateCommand:
	LD WA, (8A40h)
	CP WA, 4
	JR Z, FDC_ValidateTrack
	CP WA, 3
	JR Z, FDC_ValidateTrack
	CP WA, 2
	JR Z, FDC_ValidateTrack
	CP WA, 5
	JR Z, FDC_Command5Handler
	CP WA, 000bh
	JR Z, FDC_NoOpReturn
	CP WA, 1
	JR NZ, FDC_ValidateTrack

FDC_NoOpReturn:
	LD_L 000h
	RET

FDC_Command5Handler:
	CALR FDC_Command5_Epilogue
	LD L, (8A24h)
	RET

FDC_ValidateTrack:
	LD WA, (8A46h)
	LD (8A2Bh), A
	LD (8A36h), A
	EXTZ WA
	CP WA, (8B08h)
	JR C, FDC_HandleCmd2
	LD WA, 00feh
	JRL T, FDC_Set_Status

FDC_HandleCmd2:
	CPW (8A40h), 0002h
	JR NZ, FDC_CheckSectorCount
	CALR FDC_CheckHead
	LD L, (8A24h)
	RET

FDC_CheckSectorCount:
	CPW (8A4Ah), 0000h
	JR NZ, FDC_CheckSectorNum
	LD WA, 00feh
	JRL T, FDC_Set_Status

FDC_CheckSectorNum:
	LD WA, (8A48h)
	LD (8A2Dh), A
	CP (8A2Dh), 000h
	JR NZ, FDC_CheckFormatType
	LD WA, 00feh
	JRL T, FDC_Set_Status

FDC_CheckFormatType:
	LD A, (8A6Ch)
	CP A, 0
	JR Z, FDC_FormatDefault
	CP A, 5
	JR Z, FDC_FormatDefault
	CP A, 4
	JR Z, FDC_FormatType4
	CP A, 3
	JR Z, FDC_FormatType3
	CP A, 2
	JR NZ, FDC_ErrorInvalid
	CP (8A2Dh), 008h
	JR ULE, FDC_ValidExecute
	LD WA, 00feh
	JRL T, FDC_Set_Status

FDC_FormatType3:
	CP (8A2Dh), 012h
	JR ULE, FDC_ValidExecute
	LD WA, 00feh
	JRL T, FDC_Set_Status

FDC_FormatType4:
	CP (8A2Dh), 0ffh
	JR NZ, FDC_Format4Check
	CALR FDC_CheckHead
	LD L, (8A24h)
	RET

FDC_Format4Check:
	CP (8A2Dh), 009h
	JR ULE, FDC_ValidExecute
	LD WA, 00feh
	JRL T, FDC_Set_Status

FDC_FormatDefault:
	CP (8A2Dh), 009h
	JR ULE, FDC_ValidExecute
	LD WA, 00feh
	JRL T, FDC_Set_Status

FDC_ErrorInvalid:
	LD WA, 00feh
	JRL T, FDC_Set_Status

FDC_ValidExecute:
	CALR FDC_CheckHead
	LD L, (8A24h)
	RET

FDC_SetupFormatParams:
	LD WA, (8A46h)
	LD (8A6Eh), A
	AND A, 00fh
	CP A, 3
	JRL Z, FDC_Format1440K
	CP A, 2
	JR Z, FDC_FormatDD
	CP A, 5
	JR Z, FDC_FormatHD
	CP A, 4
	JR Z, FDC_FormatHD
	CP A, 0
	JRL NZ, FDC_FormatUnknown

FDC_FormatHD:
	LD (8A2Eh), 002h
	LD (8A35h), 001h
	LD (8A2Fh), 009h
	LD (8A32h), 009h
	LD (8A30h), 01bh
	LD (8A33h), 054h
	LDW (8B06h), 004fh
	LDW (8B08h), 0050h
	LDW (8B0Ah), 0009h
	LDW (8B0Ch), 000ah
	JR T, FDC_InitStateVars

FDC_FormatDD:
	LD (8A2Eh), 003h
	LD (8A35h), 001h
	LD (8A2Fh), 008h
	LD (8A32h), 008h
	LD (8A30h), 053h
	LD (8A33h), 074h
	LDW (8B06h), 004ch
	LDW (8B08h), 004dh
	LDW (8B0Ah), 0008h
	LDW (8B0Ch), 0009h
	JR T, FDC_InitStateVars

FDC_Format1440K:
	LD (8A2Eh), 002h
	LD (8A35h), 001h
	LD (8A2Fh), 012h
	LD (8A32h), 012h
	LD (8A30h), 01bh
	LD (8A33h), 06ch
	LDW (8B06h), 004fh
	LDW (8B08h), 0050h
	LDW (8B0Ah), 0012h
	LDW (8B0Ch), 0013h
	JR T, FDC_InitStateVars

FDC_FormatUnknown:
	LD WA, 00feh
	CALR FDC_Set_Status

FDC_InitStateVars:
	LD A, (8A6Eh)
	SRL 4, A
	AND A, 00fh
	LD (8A37h), A
	LD (8A31h), 0ffh
	LD (8A34h), 000h
	LD (8A38h), 00fh
	LD (8A39h), 001h
	LD (8A3Ch), 000h
	LD (8A3Bh), 000h
	LD (8A3Dh), 000h
	LD (8A3Eh), 000h
	LD (8A3Fh), 000h
	LD (8A3Ah), 000h
	RET

FDC_CheckHead:
	LD WA, (8A44h)
	LD (8A2Ch), A
	LD (8A29h), A
	CP (8A29h), 000h
	RET Z
	CP (8A29h), 001h
	RET Z
	LD WA, 00feh
	CALR FDC_Set_Status
	RET

FDC_Command5_Epilogue:
	RET

FDC_Validate_Drive_Head:
	CPW (8A44h), 0000h
	RET Z
	CPW (8A44h), 0001h
	RET Z
	LD WA, 00feh
	CALR FDC_Set_Status
	RET


FDC_NOP_Delay:
	DEC 2, XSP
	LD (XSP), A
	LD A, (XSP)
	DEC 1, (XSP)
	CP A, 0
	JR Z, FDC_NOP_Delay_Exit

FDC_NOP_Delay_Loop:
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	LD A, (XSP)
	DEC 1, (XSP)
	CP A, 0
	JR NZ, FDC_NOP_Delay_Loop

FDC_NOP_Delay_Exit:
	INC 2, XSP
	RET


FDC_Pulse_PH0:
	SET 0, (PH)
	LD WA, 000ah
	CALR FDC_NOP_Delay
	RES 0, (PH)
	RET


FDC_Init_Sequence_1:
	db 068h, 000h


FDC_Port_Reset_Or_Noop:
	RET


FDC_Setup_DMA_Mode:
	LD BC, (8a1ch)
	LDC_DMAM3_BC
	LD A, (8a28h)
	CP A, 04dh
	JR Z, FDC_Setup_DMA_Read_Mode
	CP A, 0c9h
	JR Z, FDC_Setup_DMA_Read_Mode
	CP A, 0c5h
	JR Z, FDC_Setup_DMA_Read_Mode
	CP A, 0ddh
	JR Z, FDC_Setup_DMA_Write_Mode
	CP A, 0d9h
	JR Z, FDC_Setup_DMA_Write_Mode
	CP A, 0d1h
	JR Z, FDC_Setup_DMA_Write_Mode
	CP A, 04ah
	JR Z, FDC_Setup_DMA_Write_Mode
	CP A, 042h
	JR Z, FDC_Setup_DMA_Write_Mode
	CP A, 0cch
	JR Z, FDC_Setup_DMA_Write_Mode
	CP A, 0c6h
	RET NZ

FDC_Setup_DMA_Write_Mode:
	JR T, FDC_Setup_DMA_Ack_Dest

FDC_Setup_DMA_Read_Mode:
	CALR FDC_Setup_DMA_Src_Ack

FDC_DMA_Setup_Exit:
	RET

FDC_Setup_DMA_Ack_Dest:
	LD XHL, FDC__DMA_ACKNOWLEDGE
	LDC_DMAS3_XHL
	LD XHL, (08a4ch)
	LDC_DMAD3_XHL
	LD_A 0
	LDC_DMAC3_A
	JR T, FDC_Port_Reset_Or_Noop

FDC_Setup_DMA_Src_Ack:
	LD XHL, (08a4ch)
	LDC_DMAS3_XHL
	LD XHL, FDC__DMA_ACKNOWLEDGE
	LDC_DMAD3_XHL
	LD_A 8
	LDC_DMAC3_A
	JR T, FDC_Port_Reset_Or_Noop
	LD BC, (08a1ch)
	LDC_DMAM3_BC
	RET

FDC_Wait_Ready_Timeout:
	PUSH XIZ
	LD IZ, (SYSTEM_TIMESTAMP)
	LD QIZ, 0080h
	CP QIZ, 0080h
	JR NZ, LABEL_F97107

FDC_WaitReady_StatusLoop:
	CALR FDC_Read_Status
	RES 4, L
	LD A, L
	CP A, 080h
	JR Z, FDC_WaitReady_TimeoutCheck
	CP A, 0c0h
	JR NZ, FDC_WaitReady_TimeoutCheck
	LD QIZ, 0

FDC_WaitReady_TimeoutCheck:
	LD WA, (SYSTEM_TIMESTAMP)
	SUB WA, IZ
	CP WA, 01f4h
	JR ULE, FDC_WaitReady_LoopContinue
	LD QIZ, 0ffffh

FDC_WaitReady_LoopContinue:
	CP QIZ, 0080h
	JR Z, FDC_WaitReady_StatusLoop

LABEL_F97107:
	CP QIZ, 0
	JR Z, FDC_WaitReady_Complete
	LD WA,2
	CALR FDC_Set_Status

FDC_WaitReady_Complete:
	POP XIZ
	RET


FDC_Wait_Status_Timeout:
	PUSH XIZ
	LD IZ, (SYSTEM_TIMESTAMP)
	LD QIZ, 0080h
	CP QIZ, 0080h
	JR NZ, LABEL_F9714F

FDC_WaitStatus_StatusLoop:
	CALR FDC_Read_Status
	AND L, 0e0h
	CP L, 080h
	JR Z, LABEL_F97137
	CP L, 0c0h
	JR NZ, LABEL_F97137
	LD QIZ, 0

LABEL_F97137:
	LD WA, (SYSTEM_TIMESTAMP)
	SUB WA, IZ
	CP WA, 01f4h
	JR ULE, FDC_WaitStatus_TimeoutCheck
	LD QIZ, 0ffffh

FDC_WaitStatus_TimeoutCheck:
	CP QIZ, 0080h
	JR Z, FDC_WaitStatus_StatusLoop

LABEL_F9714F:
	CP QIZ, 0
	JR Z, LABEL_F97159
	LD WA, 2
	CALR FDC_Set_Status

LABEL_F97159:
	POP XIZ
	RET


LABEL_F9715B:
	db 0EFh, 06Ah, 03Eh, 0BFh, 004h, 016h, 009h, 004h
	db 0D7h, 0FAh, 003h, 080h, 000h, 0D7h, 0FAh, 0CFh
	db 080h, 000h, 06Eh, 053h, 01Eh, 0A1h, 0F9h, 0CFh
	db 030h, 004h, 0CFh, 089h, 0C9h, 0CFh, 0C0h, 066h
	db 00Ah, 0C9h, 0CFh, 080h, 06Eh, 028h, 0D7h, 0FAh
	db 0A8h, 068h, 023h, 0DEh, 0A9h, 0D7h, 0FAh, 0A8h
	db 0D7h, 0FAh, 0D8h, 06Eh, 019h, 01Eh, 086h, 0F9h
	db 0F1h, 060h, 08Ah, 030h, 0DEh, 089h, 0E9h, 012h
	db 0E8h, 081h, 0B1h, 047h, 01Eh, 071h, 0F9h, 0DEh
	db 061h, 0D7h, 0FAh, 0D8h, 066h, 0E7h, 0D1h, 009h
	db 004h, 020h, 09Fh, 004h, 0A0h, 0D8h, 0CFh, 0F4h
	db 001h, 063h, 005h, 0D7h, 0FAh, 003h, 0FFh, 0FFh
	db 0D7h, 0FAh, 0CFh, 080h, 000h, 066h, 0ADh, 0D7h
	db 0FAh, 0D8h, 066h, 005h, 0D8h, 0ABh, 01Eh, 0E1h
	db 003h, 05Eh, 0EFh, 062h, 00Eh, 0EFh, 06Ah, 0B7h
	db 041h, 01Eh, 084h, 0FFh, 087h, 021h, 0D8h, 012h
	db 01Eh, 052h, 0F9h, 0EFh, 062h, 00Eh, 0EFh, 06Ah
	db 0B7h, 041h, 01Eh, 094h, 0F9h, 087h, 021h, 0D8h
	db 012h, 01Eh, 041h, 0F9h, 0EFh, 062h, 00Eh, 0EFh
	db 06Ah, 0B7h, 041h, 01Eh, 062h, 0FFh, 087h, 021h
	db 0D8h, 012h, 01Eh, 01Fh, 0F9h, 0EFh, 062h, 00Eh
	db 0EFh, 06Ah, 0B7h, 041h, 01Eh, 051h, 0FFh, 0C1h
	db 024h, 08Ah, 03Fh, 000h, 06Eh, 007h, 087h, 021h
	db 0D8h, 012h, 01Eh, 0DAh, 0FFh, 0EFh, 062h, 00Eh
	db 0EFh, 06Ah, 0B7h, 041h, 01Eh, 039h, 0FFh, 0C1h
	db 024h, 08Ah, 03Fh, 000h, 06Eh, 011h, 087h, 021h
	db 0D8h, 012h, 01Eh, 0C2h, 0FFh, 01Eh, 096h, 0FEh
	db 01Eh, 0E3h, 0F8h, 0F1h, 061h, 08Ah, 047h, 0EFh
	db 062h, 00Eh

FDC_Exception_Status_Decoder:
	LDA XDE, 8A60h
	LD C, (XDE + 001h)
	LD A, C
	AND A, 0c0h
	CP A, 040h
	JR Z, LABEL_F9726A
	CP A, 080h
	JR Z, LABEL_F97267
	CP A, 0c0h
	JR Z, LABEL_F9725F
	CP A, 0
	JR NZ, LABEL_F972C5
	LD_L 000h
	RET

LABEL_F9725F:
	LD (8B00h), 0ffh
	LD_L 000h
	RET

LABEL_F97267:
	LD_L 000h
	RET

LABEL_F9726A:
	BIT 003h, C
	JR Z, LABEL_F97272
	LD_L 031h
	RET

LABEL_F97272:
	BIT 004h, C
	JR Z, LABEL_F9727A
	LD_L 032h
	RET

LABEL_F9727A:
	LD C, (XDE + 002h)
	BIT 000h, C
	JR Z, LABEL_F97288
	LD WA, 0035h
	JRL T, FDC_Set_Status

LABEL_F97288:
	BIT 001h, C
	JR Z, LABEL_F97293
	LD WA, 002fh
	JRL T, FDC_Set_Status

LABEL_F97293:
	BIT 002h, C
	JR Z, LABEL_F9729E
	LD WA, 0033h
	JRL T, FDC_Set_Status

LABEL_F9729E:
	BIT 004h, C
	JR Z, LABEL_F972A9
	LD WA, 0034h
	JRL T, FDC_Set_Status

LABEL_F972A9:
	BIT 005h, C
	JR Z, LABEL_F972B4
	LD WA, 0036h
	JRL T, FDC_Set_Status

LABEL_F972B4:
	BIT 007h, C
	JR Z, LABEL_F972BF
	LD WA, 0037h
	JRL T, FDC_Set_Status

LABEL_F972BF:
	LD WA, 0008h
	JRL T, FDC_Set_Status

LABEL_F972C5:
	LD_L 008h
	RET


;==================== (guessed) start of floppy routines =======================


LABEL_F972C8:
	db 008h, 0F8h, 00Bh, 0F0h, 0E0h, 031h, 081h, 021h
	db 0C9h, 0CCh, 0F8h, 0C9h, 031h, 002h, 0B1h, 041h
	db 008h, 0F8h, 028h, 0F0h, 0EDh, 031h, 081h, 021h
	db 0C9h, 0CCh, 08Fh, 0C9h, 0CEh, 050h, 0B1h, 041h
	db 008h, 0F8h, 00Ch, 0F0h, 0E0h, 031h, 081h, 021h
	db 0C9h, 0CCh, 08Fh, 0C9h, 0CEh, 060h, 0B1h, 041h
	db 00Eh, 0EFh, 06Ah, 0B7h, 041h, 01Eh, 036h, 0F8h
	db 0C1h, 024h, 08Ah, 03Fh, 000h, 07Eh, 0D6h, 000h
	db 087h, 021h, 0F1h, 028h, 08Ah, 041h, 01Eh, 0D0h
	db 000h, 0CFh, 0D8h, 07Eh, 0C8h, 000h, 087h, 021h
	db 0C9h, 0CFh, 033h, 066h, 01Eh, 0C9h, 0CFh, 034h
	db 066h, 019h, 0C9h, 0CFh, 036h, 066h, 00Ah, 0C9h
	db 0CFh, 035h, 066h, 005h, 0C9h, 0CFh, 047h, 06Eh
	db 014h, 087h, 021h, 0D8h, 012h, 01Eh, 0CBh, 0FEh
	db 078h, 0A3h, 000h, 087h, 021h, 0D8h, 012h, 01Eh
	db 0D9h, 0FEh, 078h, 099h, 000h, 087h, 021h, 0C9h
	db 030h, 004h, 0C9h, 0CFh, 04Fh, 06Eh, 00Ah, 087h
	db 021h, 0D8h, 012h, 01Eh, 0C5h, 0FEh, 078h, 085h
	db 000h, 087h, 021h, 0C9h, 0CCh, 00Fh, 0C9h, 0CFh
	db 00Eh, 066h, 00Ah, 087h, 021h, 0C9h, 0CCh, 00Fh
	db 0C9h, 0CFh, 00Bh, 06Eh, 009h, 087h, 021h, 0D8h
	db 012h, 01Eh, 0A7h, 0FEh, 068h, 068h, 087h, 021h
	db 0D8h, 012h, 01Eh, 053h, 0FEh, 0C1h, 024h, 08Ah
	db 03Fh, 000h, 06Eh, 05Ah, 087h, 03Fh, 008h, 066h
	db 055h, 087h, 03Fh, 003h, 06Eh, 005h, 01Eh, 0ABh
	db 000h, 068h, 04Bh, 0C1h, 029h, 08Ah, 021h, 0C9h
	db 0CCh, 001h, 0C9h, 0EEh, 002h, 0C9h, 08Dh, 0C1h
	db 02Ah, 08Ah, 021h, 0C9h, 0CCh, 003h, 0C9h, 08Bh
	db 0CDh, 089h, 0CBh, 0E1h, 0CDh, 089h, 0C9h, 031h
	db 000h, 0D8h, 012h, 01Eh, 02Bh, 0FEh, 087h, 021h
	db 0C9h, 0CFh, 00Fh, 066h, 019h, 0C9h, 0CFh, 04Dh
	db 066h, 00Fh, 0C9h, 0DFh, 066h, 009h, 0C9h, 0DCh
	db 066h, 005h, 0C9h, 0CFh, 04Ah, 06Eh, 00Ch, 068h
	db 00Dh, 01Eh, 09Eh, 000h, 068h, 008h, 01Eh, 0C0h
	db 000h, 068h, 003h, 01Eh, 0C4h, 000h, 0EFh, 062h
	db 00Eh, 0C1h, 028h, 08Ah, 021h, 0C9h, 0CFh, 04Fh
	db 066h, 014h, 0C9h, 0CFh, 033h, 066h, 00Fh, 0C9h
	db 0CFh, 034h, 066h, 00Ah, 0C9h, 0CFh, 047h, 066h
	db 005h, 0C9h, 0CFh, 035h, 06Eh, 003h, 027h, 000h
	db 00Eh, 0C1h, 028h, 08Ah, 021h, 0C9h, 0CCh, 01Fh
	db 0C9h, 0CFh, 01Eh, 066h, 01Dh, 0C9h, 0CFh, 01Dh
	db 066h, 018h, 0C9h, 0CFh, 019h, 066h, 013h, 0C9h
	db 0CFh, 010h, 066h, 011h, 0C9h, 0CFh, 011h, 066h
	db 009h, 0C9h, 0CFh, 00Fh, 06Bh, 007h, 0C9h, 0DAh
	db 067h, 003h, 027h, 000h, 00Eh, 027h, 001h, 00Eh
	db 0C1h, 035h, 08Ah, 021h, 0C9h, 0CCh, 003h, 0D8h
	db 012h, 078h, 0A5h, 0FDh, 0C1h, 037h, 08Ah, 021h
	db 0C9h, 0EEh, 004h, 0C9h, 08Dh, 0C1h, 038h, 08Ah
	db 021h, 0C9h, 0CCh, 00Fh, 0C9h, 08Bh, 0CDh, 089h
	db 0CBh, 0E1h, 0D8h, 012h, 01Eh, 08Ah, 0FDh, 0C1h
	db 039h, 08Ah, 021h, 0C9h, 0EEh, 001h, 0C9h, 08Dh
	db 0C1h, 03Ah, 08Ah, 021h, 0C9h, 0CCh, 001h, 0C9h
	db 08Bh, 0CDh, 089h, 0CBh, 0E1h, 0D8h, 012h, 078h
	db 06Fh, 0FDh, 0C1h, 02Eh, 08Ah, 021h, 0C9h, 0CCh
	db 007h, 0D8h, 012h, 01Eh, 063h, 0FDh, 0C1h, 032h
	db 08Ah, 021h, 0D8h, 012h, 01Eh, 05Ah, 0FDh, 0C1h
	db 033h, 08Ah, 021h, 0D8h, 012h, 01Eh, 051h, 0FDh
	db 0C1h, 034h, 08Ah, 021h, 0D8h, 012h, 078h, 048h
	db 0FDh, 0C1h, 036h, 08Ah, 021h, 0D8h, 012h, 078h
	db 03Fh, 0FDh, 0C1h, 02Bh, 08Ah, 021h, 0D8h, 012h
	db 01Eh, 036h, 0FDh, 0C1h, 02Ch, 08Ah, 021h, 0C9h
	db 0CCh, 001h, 0D8h, 012h, 01Eh, 02Ah, 0FDh, 0C1h
	db 02Dh, 08Ah, 021h, 0D8h, 012h, 01Eh, 021h, 0FDh
	db 0C1h, 02Eh, 08Ah, 021h, 0C9h, 0CCh, 007h, 0D8h
	db 012h, 01Eh, 015h, 0FDh, 0C1h, 02Fh, 08Ah, 021h
	db 0D8h, 012h, 01Eh, 00Ch, 0FDh, 0C1h, 030h, 08Ah
	db 021h, 0D8h, 012h, 01Eh, 003h, 0FDh, 0C1h, 028h
	db 08Ah, 021h, 0C9h, 0CFh, 0DDh, 066h, 00Ah, 0C9h
	db 0CFh, 0D9h, 066h, 005h, 0C9h, 0CFh, 0D1h, 06Eh
	db 003h, 078h, 03Ch, 0FFh, 0C1h, 031h, 08Ah, 021h
	db 0D8h, 012h, 01Eh, 0E4h, 0FCh, 00Eh, 0D1h, 046h
	db 08Ah, 03Fh, 000h, 000h, 066h, 003h, 0DBh, 0A8h
	db 00Eh, 0D1h, 044h, 08Ah, 03Fh, 000h, 000h, 066h
	db 003h, 0DBh, 0A8h, 00Eh, 0D1h, 040h, 08Ah, 03Fh
	db 003h, 000h, 066h, 003h, 0DBh, 0A8h, 00Eh, 0D1h
	db 04Ah, 08Ah, 03Fh, 001h, 000h, 066h, 003h, 0DBh
	db 0A8h, 00Eh, 0D1h, 010h, 08Ah, 03Fh, 0FFh, 0FFh
	db 066h, 003h, 0DBh, 0A8h, 00Eh, 0D1h, 048h, 08Ah
	db 03Fh, 001h, 000h, 066h, 003h, 0DBh, 0A8h, 00Eh
	db 033h, 0FFh, 0FFh, 00Eh, 0D1h, 046h, 08Ah, 03Fh
	db 000h, 000h, 066h, 003h, 0DBh, 0A8h, 00Eh, 0D1h
	db 044h, 08Ah, 03Fh, 000h, 000h, 066h, 003h, 0DBh
	db 0A8h, 00Eh, 0D1h, 040h, 08Ah, 03Fh, 003h, 000h
	db 066h, 003h, 0DBh, 0A8h, 00Eh, 0D1h, 04Ah, 08Ah
	db 03Fh, 001h, 000h, 066h, 003h, 0DBh, 0A8h, 00Eh
	db 0D1h, 010h, 08Ah, 03Fh, 0FFh, 0FFh, 066h, 003h
	db 0DBh, 0A8h, 00Eh, 0D1h, 048h, 08Ah, 03Fh, 002h
	db 000h, 066h, 008h, 0D1h, 048h, 08Ah, 03Fh, 0FFh
	db 000h, 06Eh, 004h, 033h, 0FFh, 0FFh, 00Eh, 0DBh
	db 0A8h, 00Eh, 0D1h, 04Ah, 08Ah, 03Fh, 0FFh, 0FFh
	db 066h, 003h, 0DBh, 0A8h, 00Eh, 0D1h, 040h, 08Ah
	db 03Fh, 000h, 000h, 066h, 003h, 0DBh, 0A8h, 00Eh
	db 033h, 0FFh, 0FFh, 00Eh, 00Eh

FDC_Set_Status:
	CP (8A24h), 000h
	JR NZ, LABEL_F975D0
	LD (8A24h), A
	CP A, 036h
	JR Z, LABEL_F975CD
	CP A, 035h
	JR Z, LABEL_F975CA
	CP A, 033h
	JR NZ, LABEL_F975D1
	NOP
	JR T, LABEL_F975D1

LABEL_F975CA:
	NOP
	JR T, LABEL_F975D1

LABEL_F975CD:
	NOP
	JR T, LABEL_F975D1

LABEL_F975D0:
	NOP

LABEL_F975D1:
	LD L, (8A24h)
	RET


LABEL_F975D6:
	db 0F1h, 024h, 08Ah, 000h, 000h, 00Eh, 0F1h, 060h
	db 08Ah, 000h, 0FFh, 00Eh, 03Eh, 0D7h, 0FAh, 003h
	db 0F4h, 001h, 0D1h, 009h, 004h, 026h, 0D9h, 0A8h
	db 0C1h, 060h, 08Ah, 03Fh, 0FFh, 066h, 003h, 031h
	db 0FFh, 0FFh, 0D1h, 009h, 004h, 020h, 0DEh, 0A0h
	db 0D7h, 0FAh, 0F0h, 063h, 009h, 030h, 009h, 000h
	db 01Eh, 0A4h, 0FFh, 031h, 0FFh, 0FFh, 0D9h, 0D8h
	db 066h, 0DEh, 05Eh, 00Eh


SOME_DELAY:			; F97612
	SRL 1, WA
	LD DE, (SYSTEM_TIMESTAMP)
	LD HL, 0
	CP HL, 0ffffh
	RET NC

LABEL_F97621:
	LD BC, (SYSTEM_TIMESTAMP)
	SUB BC, DE
	CP BC, WA
	RET UGT
	INC 1, HL
	CP HL, 0ffffh
	JR C, LABEL_F97621
	RET


LABEL_F97634:
	db 030h, 028h, 000h, 068h, 0D9h

LABEL_F97639:
	CALR FDC_Init_Sequence_1
	CALR FDC_Pulse_PH0
	LD (8a6ah), 0
	LD (8b00h), 0
	CALR LABEL_F972C8
	CALR FDC_INIT
	JRL T, FDC_CONFIG_VERIFY

LABEL_F97652:
	db 0D7h, 0FAh
	db 004h, 0C1h, 036h, 08Ah, 021h, 0C7h, 0FBh, 099h
	db 0F1h, 036h, 08Ah, 000h, 005h, 0F1h, 004h, 08Bh
	db 000h, 0FFh, 01Eh, 02Dh, 000h, 0F1h, 004h, 08Bh
	db 000h, 000h, 01Eh, 06Bh, 0FFh, 0D8h, 0AFh, 01Eh
	db 083h, 0FCh, 01Eh, 069h, 0FFh, 0C1h, 024h, 08Ah
	db 03Fh, 000h, 066h, 005h, 0F1h, 004h, 08Bh, 000h
	db 0FFh, 0C7h, 0FBh, 089h, 0F1h, 036h, 08Ah, 041h
	db 030h, 010h, 000h, 01Eh, 080h, 0FFh, 0D7h, 0FAh
	db 005h, 00Eh, 0C1h, 036h, 08Ah, 021h, 0C1h, 004h
	db 08Bh, 0F1h, 0B0h, 0F6h, 0C1h, 036h, 08Ah, 019h
	db 004h, 08Bh, 0D8h, 0AAh, 01Eh, 067h, 0FFh, 01Eh
	db 02Eh, 0FFh, 030h, 00Fh, 000h, 01Eh, 045h, 0FCh
	db 01Eh, 02Bh, 0FFh, 0C1h, 024h, 08Ah, 03Fh, 000h
	db 066h, 005h, 0F1h, 004h, 08Bh, 000h, 0FFh, 030h
	db 010h, 000h, 078h, 049h, 0FFh, 0F1h, 028h, 08Ah
	db 000h, 0C6h, 01Eh, 081h, 0F9h, 01Eh, 008h, 0FFh
	db 030h, 0C6h, 000h, 01Eh, 01Fh, 0FCh, 0C1h, 024h
	db 08Ah, 03Fh, 000h, 0B0h, 0FEh, 078h, 0FEh, 0FEh
	db 02Eh, 01Eh, 016h, 0FEh, 0DBh, 0D8h, 066h, 008h
	db 0F1h, 068h, 08Ah, 000h, 001h, 078h, 036h, 001h
	db 01Eh, 04Dh, 0FEh, 0DBh, 0D8h, 06Eh, 008h, 0F1h
	db 068h, 08Ah, 000h, 008h, 078h, 027h, 001h, 0F1h
	db 068h, 08Ah, 000h, 001h, 078h, 01Fh, 001h, 0F1h
	db 024h, 08Ah, 000h, 000h, 01Eh, 083h, 0FFh, 0C1h
	db 024h, 08Ah, 03Fh, 000h, 066h, 016h, 0C1h, 024h
	db 08Ah, 021h, 0C7h, 0F8h, 099h, 0DEh, 013h, 01Eh
	db 0AAh, 0F4h, 0C7h, 0F8h, 089h, 0F1h, 024h, 08Ah
	db 041h, 078h, 003h, 001h, 0D1h, 048h, 08Ah, 020h
	db 0D1h, 00Ch, 08Bh, 0F0h, 063h, 006h, 0F1h, 048h
	db 08Ah, 002h, 001h, 000h, 0D1h, 048h, 08Ah, 019h
	db 010h, 08Bh, 0F1h, 01Ch, 08Ah, 002h, 000h, 000h
	db 0C1h, 06Ch, 08Ah, 03Fh, 002h, 06Eh, 008h, 0F1h
	db 01Eh, 08Ah, 002h, 000h, 004h, 068h, 006h, 0F1h
	db 01Eh, 08Ah, 002h, 000h, 002h, 0D1h, 04Ah, 08Ah
	db 019h, 012h, 08Bh, 0DEh, 0A9h, 0D1h, 01Eh, 08Ah
	db 020h, 0D1h, 01Ch, 08Ah, 088h, 0F1h, 04Ah, 08Ah
	db 030h, 090h, 069h, 090h, 020h, 0D8h, 0D8h, 066h
	db 012h, 0F1h, 048h, 08Ah, 030h, 090h, 061h, 090h
	db 020h, 0D1h, 00Ch, 08Bh, 0F0h, 06Bh, 004h, 0DEh
	db 061h, 068h, 0DAh, 0F1h, 04Ah, 08Ah, 056h, 0D1h
	db 010h, 08Bh, 019h, 048h, 08Ah, 01Eh, 02Dh, 0FFh
	db 0C1h, 024h, 08Ah, 03Fh, 000h, 066h, 03Ah, 0C1h
	db 024h, 08Ah, 03Fh, 009h, 06Eh, 006h, 01Eh, 012h
	db 0F4h, 078h, 083h, 000h, 01Eh, 091h, 0FDh, 0DBh
	db 0CFh, 0FFh, 0FFh, 066h, 00Bh, 01Eh, 014h, 0F4h
	db 0F1h, 004h, 08Bh, 000h, 0FFh, 01Eh, 0D2h, 0FEh
	db 0D1h, 012h, 08Bh, 019h, 04Ah, 08Ah, 0C1h, 068h
	db 08Ah, 069h, 0C1h, 068h, 08Ah, 021h, 0C9h, 0D8h
	db 06Eh, 054h, 0F1h, 024h, 08Ah, 000h, 010h, 068h
	db 056h, 0D1h, 012h, 08Bh, 020h, 0DEh, 0A0h, 0F1h
	db 04Ah, 08Ah, 050h, 0D1h, 04Ah, 08Ah, 03Fh, 000h
	db 000h, 066h, 03Bh, 0F1h, 04Ch, 08Ah, 031h, 0D1h
	db 01Ch, 08Ah, 020h, 0E8h, 012h, 0A1h, 080h, 0B1h
	db 060h, 0F1h, 048h, 08Ah, 002h, 001h, 000h, 0F1h
	db 02Dh, 08Ah, 000h, 001h, 0C1h, 029h, 08Ah, 021h
	db 0C9h, 0CDh, 001h, 0F1h, 029h, 08Ah, 041h, 0F1h
	db 02Ch, 08Ah, 041h, 0C1h, 02Ch, 08Ah, 03Fh, 000h
	db 06Eh, 00Ch, 0F1h, 02Bh, 08Ah, 030h, 080h, 061h
	db 080h, 021h, 0F1h, 036h, 08Ah, 041h, 0D1h, 04Ah
	db 08Ah, 03Fh, 000h, 000h, 07Eh, 0D8h, 0FEh, 04Eh
	db 00Eh, 02Eh, 0F1h, 068h, 08Ah, 000h, 008h, 078h
	db 020h, 001h, 0F1h, 024h, 08Ah, 000h, 000h, 01Eh
	db 050h, 0FEh, 0C1h, 024h, 08Ah, 03Fh, 000h, 066h
	db 016h, 0C1h, 024h, 08Ah, 021h, 0C7h, 0F8h, 099h
	db 0DEh, 013h, 01Eh, 077h, 0F3h, 0C7h, 0F8h, 089h
	db 0F1h, 024h, 08Ah, 041h, 078h, 004h, 001h, 0D1h
	db 048h, 08Ah, 020h, 0D1h, 00Ch, 08Bh, 0F0h, 063h
	db 006h, 0F1h, 048h, 08Ah, 002h, 001h, 000h, 0D1h
	db 048h, 08Ah, 019h, 010h, 08Bh, 0F1h, 01Ch, 08Ah
	db 002h, 000h, 000h, 0C1h, 06Ch, 08Ah, 03Fh, 002h
	db 06Eh, 008h, 0F1h, 01Eh, 08Ah, 002h, 000h, 004h
	db 068h, 006h, 0F1h, 01Eh, 08Ah, 002h, 000h, 002h
	db 0D1h, 04Ah, 08Ah, 019h, 012h, 08Bh, 0DEh, 0A9h
	db 0D1h, 01Eh, 08Ah, 020h, 0D1h, 01Ch, 08Ah, 088h
	db 0F1h, 04Ah, 08Ah, 030h, 090h, 069h, 090h, 020h
	db 0D8h, 0D8h, 066h, 012h, 0F1h, 048h, 08Ah, 030h
	db 090h, 061h, 090h, 020h, 0D1h, 00Ch, 08Bh, 0F0h
	db 06Bh, 004h, 0DEh, 061h, 068h, 0DAh, 0F1h, 04Ah
	db 08Ah, 056h, 0D1h, 010h, 08Bh, 019h, 048h, 08Ah
	db 01Eh, 09Ah, 000h, 0C1h, 024h, 08Ah, 03Fh, 000h
	db 066h, 03Bh, 0C1h, 024h, 08Ah, 03Fh, 009h, 06Eh
	db 009h, 01Eh, 0DFh, 0F2h, 01Eh, 0EDh, 0F2h, 078h
	db 081h, 000h, 0C1h, 024h, 08Ah, 03Fh, 02Fh, 066h
	db 07Ah, 01Eh, 0E0h, 0F2h, 0F1h, 004h, 08Bh, 000h
	db 0FFh, 01Eh, 09Eh, 0FDh, 0D1h, 012h, 08Bh, 019h
	db 04Ah, 08Ah, 0C1h, 068h, 08Ah, 069h, 0C1h, 068h
	db 08Ah, 021h, 0C9h, 0D8h, 06Eh, 054h, 0F1h, 024h
	db 08Ah, 000h, 020h, 068h, 056h, 0D1h, 012h, 08Bh
	db 020h, 0DEh, 0A0h, 0F1h, 04Ah, 08Ah, 050h, 0D1h
	db 04Ah, 08Ah, 03Fh, 000h, 000h, 066h, 03Bh, 0F1h
	db 04Ch, 08Ah, 031h, 0D1h, 01Ch, 08Ah, 020h, 0E8h
	db 012h, 0A1h, 080h, 0B1h, 060h, 0F1h, 048h, 08Ah
	db 002h, 001h, 000h, 0F1h, 02Dh, 08Ah, 000h, 001h
	db 0C1h, 029h, 08Ah, 021h, 0C9h, 0CDh, 001h, 0F1h
	db 029h, 08Ah, 041h, 0F1h, 02Ch, 08Ah, 041h, 0C1h
	db 02Ch, 08Ah, 03Fh, 000h, 06Eh, 00Ch, 0F1h, 02Bh
	db 08Ah, 030h, 080h, 061h, 080h, 021h, 0F1h, 036h
	db 08Ah, 041h, 0D1h, 04Ah, 08Ah, 03Fh, 000h, 000h
	db 07Eh, 0D7h, 0FEh, 04Eh, 00Eh, 0F1h, 028h, 08Ah
	db 000h, 0C5h, 01Eh, 0E1h, 0F6h, 01Eh, 068h, 0FCh
	db 030h, 0C5h, 000h, 01Eh, 07Fh, 0F9h, 0C1h, 024h
	db 08Ah, 03Fh, 000h, 0B0h, 0FEh, 078h, 05Eh, 0FCh
	db 01Eh, 025h, 0FCh, 0C1h, 024h, 08Ah, 03Fh, 000h
	db 07Eh, 0ADh, 000h, 01Eh, 0EAh, 002h, 0C1h, 024h
	db 08Ah, 03Fh, 000h, 07Eh, 0A2h, 000h, 01Eh, 0B5h
	db 0FCh, 0C1h, 024h, 08Ah, 03Fh, 000h, 07Eh, 097h
	db 000h, 0C1h, 06Ch, 08Ah, 021h, 0C9h, 0DAh, 066h
	db 028h, 0C9h, 0DBh, 066h, 018h, 0C9h, 0DDh, 066h
	db 008h, 0C9h, 0DCh, 066h, 004h, 0C9h, 0D8h, 06Eh
	db 022h, 0F1h, 02Eh, 08Ah, 000h, 002h, 0F1h, 033h
	db 08Ah, 000h, 050h, 068h, 016h, 0F1h, 02Eh, 08Ah
	db 000h, 002h, 0F1h, 033h, 08Ah, 000h, 06Ch, 068h
	db 00Ah, 0F1h, 02Eh, 08Ah, 000h, 003h, 0F1h, 033h
	db 08Ah, 000h, 074h, 0F1h, 036h, 08Ah, 000h, 000h
	db 0F1h, 02Bh, 08Ah, 000h, 000h, 0F1h, 034h, 08Ah
	db 000h, 0E5h, 0F1h, 02Ch, 08Ah, 000h, 000h, 0F1h
	db 029h, 08Ah, 000h, 000h, 068h, 036h, 0C1h, 036h
	db 08Ah, 019h, 012h, 08Ah, 01Eh, 04Ch, 000h, 0C1h
	db 024h, 08Ah, 03Fh, 000h, 06Eh, 032h, 0C1h, 029h
	db 08Ah, 021h, 0C9h, 0CDh, 001h, 0F1h, 029h, 08Ah
	db 041h, 0F1h, 02Ch, 08Ah, 041h, 0C1h, 02Ch, 08Ah
	db 03Fh, 000h, 06Eh, 010h, 0F1h, 02Bh, 08Ah, 030h
	db 080h, 061h, 080h, 021h, 0F1h, 036h, 08Ah, 041h
	db 0F1h, 012h, 08Ah, 041h, 0C1h, 036h, 08Ah, 021h
	db 0D8h, 012h, 0D1h, 008h, 08Bh, 0F0h, 063h, 0BEh
	db 0C1h, 024h, 08Ah, 03Fh, 000h, 0F2h, 0D0h, 06Bh
	db 0F9h, 0EEh, 01Eh, 009h, 0FCh, 0F1h, 004h, 08Bh
	db 000h, 0FFh, 00Eh, 01Eh, 044h, 0FCh, 0C1h, 024h
	db 08Ah, 03Fh, 000h, 07Eh, 076h, 0F1h, 01Eh, 016h
	db 000h, 0F1h, 028h, 08Ah, 000h, 04Dh, 0F1h, 070h
	db 08Ah, 030h, 0F1h, 04Ch, 08Ah, 060h, 01Eh, 0E5h
	db 0F5h, 01Eh, 051h, 0F6h, 078h, 093h, 001h, 0F1h
	db 02Dh, 08Ah, 000h, 001h, 0F1h, 01Ch, 08Ah, 002h
	db 000h, 000h, 0D1h, 00Ah, 08Bh, 024h, 0DCh, 0EFh
	db 001h, 025h, 000h, 0DDh, 0A8h, 0DCh, 0F5h, 07Fh
	db 006h, 001h, 0CDh, 089h, 0CDh, 061h, 0D8h, 012h
	db 0F1h, 070h, 08Ah, 031h, 0D8h, 08Bh, 0EBh, 012h
	db 0E9h, 083h, 0C1h, 02Bh, 08Ah, 021h, 0B3h, 041h
	db 0D1h, 01Ch, 08Ah, 061h, 0CDh, 089h, 0CDh, 061h
	db 0D8h, 012h, 0F1h, 070h, 08Ah, 031h, 0D8h, 08Bh
	db 0EBh, 012h, 0E9h, 083h, 0C1h, 02Ch, 08Ah, 021h
	db 0B3h, 041h, 0D1h, 01Ch, 08Ah, 061h, 0CDh, 089h
	db 0CDh, 061h, 0D8h, 012h, 0F1h, 070h, 08Ah, 031h
	db 0D8h, 08Bh, 0EBh, 012h, 0E9h, 083h, 0C1h, 02Dh
	db 08Ah, 021h, 0B3h, 041h, 0D1h, 01Ch, 08Ah, 061h
	db 0CDh, 089h, 0CDh, 061h, 0D8h, 012h, 0F1h, 070h
	db 08Ah, 031h, 0D8h, 08Bh, 0EBh, 012h, 0E9h, 083h
	db 0C1h, 02Eh, 08Ah, 021h, 0B3h, 041h, 0D1h, 01Ch
	db 08Ah, 061h, 0CDh, 089h, 0CDh, 061h, 0D8h, 012h
	db 0F1h, 070h, 08Ah, 031h, 0D8h, 08Bh, 0EBh, 012h
	db 0E9h, 083h, 0C1h, 02Bh, 08Ah, 021h, 0B3h, 041h
	db 0D1h, 01Ch, 08Ah, 061h, 0CDh, 089h, 0CDh, 061h
	db 0D8h, 012h, 0F1h, 070h, 08Ah, 031h, 0D8h, 08Bh
	db 0EBh, 012h, 0E9h, 083h, 0C1h, 02Ch, 08Ah, 021h
	db 0B3h, 041h, 0D1h, 01Ch, 08Ah, 061h, 0D1h, 046h
	db 08Ah, 03Fh, 000h, 000h, 06Eh, 01Ch, 0C1h, 02Dh
	db 08Ah, 061h, 0CDh, 089h, 0CDh, 061h, 0D8h, 012h
	db 0F1h, 070h, 08Ah, 031h, 0D8h, 08Bh, 0EBh, 012h
	db 0E9h, 083h, 0C1h, 02Dh, 08Ah, 021h, 0B3h, 041h
	db 068h, 01Dh, 0D1h, 00Ah, 08Bh, 020h, 0D8h, 0EFh
	db 001h, 0C1h, 02Dh, 08Ah, 081h, 0C9h, 08Fh, 0CDh
	db 089h, 0CDh, 061h, 0D8h, 012h, 0F1h, 070h, 08Ah
	db 031h, 0E8h, 012h, 0E9h, 080h, 0B0h, 047h, 0D1h
	db 01Ch, 08Ah, 061h, 0CDh, 089h, 0CDh, 061h, 0D8h
	db 012h, 0F1h, 070h, 08Ah, 031h, 0D8h, 08Bh, 0EBh
	db 012h, 0E9h, 083h, 0C1h, 02Eh, 08Ah, 021h, 0B3h
	db 041h, 0D1h, 01Ch, 08Ah, 061h, 0C1h, 02Dh, 08Ah
	db 061h, 0DDh, 061h, 0DCh, 0F5h, 077h, 0FAh, 0FEh
	db 0D1h, 00Ah, 08Bh, 020h, 0D8h, 033h, 000h, 0B0h
	db 0F6h, 0CDh, 089h, 0CDh, 061h, 0D8h, 012h, 0F1h
	db 070h, 08Ah, 031h, 0D8h, 08Bh, 0EBh, 012h, 0E9h
	db 083h, 0C1h, 02Bh, 08Ah, 021h, 0B3h, 041h, 0D1h
	db 01Ch, 08Ah, 061h, 0CDh, 089h, 0CDh, 061h, 0D8h
	db 012h, 0F1h, 070h, 08Ah, 031h, 0D8h, 08Bh, 0EBh
	db 012h, 0E9h, 083h, 0C1h, 02Ch, 08Ah, 021h, 0B3h
	db 041h, 0D1h, 01Ch, 08Ah, 061h, 0CDh, 089h, 0CDh
	db 061h, 0D8h, 012h, 0F1h, 070h, 08Ah, 031h, 0D8h
	db 08Bh, 0EBh, 012h, 0E9h, 083h, 0D1h, 00Ah, 08Bh
	db 020h, 0B3h, 041h, 0D1h, 01Ch, 08Ah, 061h, 0CDh
	db 089h, 0CDh, 061h, 0D8h, 012h, 0F1h, 070h, 08Ah
	db 031h, 0D8h, 08Ah, 0EAh, 012h, 0E9h, 082h, 0C1h
	db 02Eh, 08Ah, 021h, 0B2h, 041h, 0D1h, 01Ch, 08Ah
	db 061h, 00Eh, 0F1h, 028h, 08Ah, 000h, 04Dh, 01Eh
	db 044h, 0F4h, 01Eh, 0CBh, 0F9h, 030h, 04Dh, 000h
	db 01Eh, 0E2h, 0F6h, 0C1h, 024h, 08Ah, 03Fh, 000h
	db 0B0h, 0FEh, 078h, 0C1h, 0F9h, 02Eh, 0F0h, 028h
	db 0BBh, 030h, 0FEh, 000h, 01Eh, 0CEh, 0F6h, 0C1h
	db 024h, 08Ah, 03Fh, 000h, 066h, 008h, 030h, 031h
	db 000h, 01Eh, 075h, 0F9h, 068h, 00Fh, 0DEh, 0A9h
	db 0DEh, 0D8h, 066h, 009h, 030h, 00Ah, 000h, 01Eh
	db 0CCh, 0F9h, 0DEh, 01Ch, 0F7h, 04Eh, 00Eh, 0F0h
	db 028h, 0B3h, 030h, 00Eh, 000h, 078h, 0A5h, 0F6h
	db 0C1h, 026h, 08Ah, 019h, 024h, 08Ah, 00Eh, 0D1h
	db 044h, 08Ah, 020h, 0D8h, 0D9h, 066h, 00Dh, 0D8h
	db 0D8h, 06Eh, 002h, 068h, 00Dh, 030h, 0FEh, 000h
	db 01Eh, 03Eh, 0F9h, 00Eh, 0F1h, 06Ah, 08Ah, 000h
	db 0FFh, 00Eh, 0F1h, 06Ah, 08Ah, 000h, 000h, 00Eh
	db 0D7h, 0FAh, 004h, 0C1h, 024h, 08Ah, 03Fh, 000h
	db 06Eh, 040h, 0D8h, 0ACh, 01Eh, 06Eh, 0F6h, 0C1h
	db 024h, 08Ah, 03Fh, 000h, 06Eh, 034h, 01Eh, 034h
	db 0F4h, 0C1h, 024h, 08Ah, 03Fh, 000h, 06Eh, 02Ah
	db 01Eh, 07Ah, 0EEh, 0C7h, 0FBh, 09Fh, 0C7h, 0FBh
	db 033h, 007h, 066h, 006h, 030h, 032h, 000h, 01Eh
	db 0FFh, 0F8h, 0C7h, 0FBh, 033h, 005h, 06Eh, 006h
	db 030h, 031h, 000h, 01Eh, 0F3h, 0F8h, 0C7h, 0FBh
	db 033h, 006h, 066h, 006h, 030h, 02Fh, 000h, 01Eh
	db 0E7h, 0F8h, 0D7h, 0FAh, 005h, 00Eh

LABEL_F97CCA:
	PUSH XIZ
	LD XIZ, (XSP + 008h)
	CPW (XIZ), 0000h
	JR NZ, LABEL_F97CD9
	LD (8A16h), 000h

LABEL_F97CD9:
	EI 006h
	CP (8A16h), 0a5h
	JR NZ, LABEL_F97CEF
	EI 000h
	LD WA, 00fbh
	CALR FDC_Set_Status
	EXTZ HL
	JRL T, LABEL_F97DEC

LABEL_F97CEF:
	LD (8A16h), 0a5h
	EI 000h
	LD WA, (XIZ)
	LD (8A40h), WA
	LD WA, (XIZ + 002h)
	LD (8A42h), WA
	LD WA, (XIZ + 004h)
	LD (8A44h), WA
	LD WA, (XIZ + 006h)
	LD (8A46h), WA
	LD WA, (XIZ + 008h)
	LD (8A48h), WA
	LD WA, (XIZ + 00ah)
	LD (8A4Ah), WA
	LD XWA, (XIZ + 00ch)
	LD (8A4Ch), XWA
	LD WA, (XIZ)
	LD (8A50h), WA
	LD WA, (XIZ + 002h)
	LD (8A52h), WA
	LD WA, (XIZ + 004h)
	LD (8A54h), WA
	LD WA, (XIZ + 006h)
	LD (8A56h), WA
	LD WA, (XIZ + 008h)
	LD (8A58h), WA
	LD WA, (XIZ + 00ah)
	LD (8A5Ah), WA
	LD XWA, (XIZ + 00ch)
	LD (8A5Ch), XWA
	LD (8A20h), 000h
	LD_8_8 08A26h, 08A24h
	LD (8A24h), 000h
	CALR FDC_COMMAND_DISPATCHER
	CP L, 0
	db 06Eh, 074h  ; JR NZ, LABEL_F97DE1 (original encoding)
	LD WA, (8A40h)
	CP WA, 000bh
	db 06Bh, 064h  ; JR UGT, LABEL_F97DDB (original encoding)
	ADD WA, WA
	LDA XIX, FDC_HANDLER_OFFSETS
	LD WA, (XIX + WA)
	LDA XIX, FDC_HANDLER_DISPATCH_BASE
	JP T, XIX + WA


; =============================================================================
; FDC (Floppy Disk Controller) Handler Routines - Label Definitions
; These labels point to routines in raw byte sections
; Full disassembly documentation saved to docs/fdc_disassembly.md
; =============================================================================

; FDC routine labels (code is in raw byte sections)
FDC_INIT		equ	0F96BBFh	; Basic FDC initialization
FDC_CONFIG_VERIFY	equ	0F96BD0h	; Configuration/status verification
FDC_CMD_DISPATCH_SUB	equ	0F96D95h	; Command handler subroutine
FDC_STATUS_HANDLER	equ	0F97696h	; Status/interrupt handler
FDC_CMD_EXEC		equ	0F976E4h	; Command execution handler
FDC_SECTOR_XFER		equ	0F97835h	; Sector/data transfer handler
FDC_MODE_CONFIG		equ	0F97984h	; Mode configuration (Handler 5)
FDC_CMD_ENABLE		equ	0F97C21h	; Command enable setup
FDC_CMD_DISABLE		equ	0F97C4Bh	; Command disable
FDC_STATUS_COPY		equ	0F97C54h	; Copy cached status
FDC_OUTPUT_CTRL		equ	0F97C5Bh	; Output control
FDC_INTERRUPT_HANDLER	equ	0F97C7Ch	; Main interrupt handler

; Forward references to helper routines in raw byte sections
FDC_DRIVE_DETECT	equ	0F97544h	; FDC drive detection routine
FDC_DRIVE_STATUS	equ	0F97592h	; FDC drive status routine
FDC_PRE_OP_CHECK	equ	0F975ACh	; FDC pre-operation check
FDC_TIMING_DELAY	equ	0F975DCh	; FDC timing/delay routine
FDC_POST_OP	equ	0F975E2h	; FDC post-operation routine
FDC_CMD_SEND	equ	0F972F9h	; FDC command send routine
FDC_DETECT_CHECK	equ	0F974FEh	; FDC detection check routine

; Jump targets within FDC routines
FDC_CE_DISPATCH	equ	0F9782Ah
FDC_CE_EXIT	equ	0F97833h
FDC_SX_MAIN	equ	0F9795Eh
FDC_SX_EXIT	equ	0F97967h
FDC_MC_EXIT	equ	0F97A3Ch


	ORG 0F97D8Dh
FDC_HANDLER_DISPATCH_BASE:
	CALR LABEL_F97639
	JR T, LABEL_F97DE1

FDC_HANDLER_01:
	CALR FDC_CMD_ENABLE
	CALR LABEL_F97652
	JR T, LABEL_F97DE1

FDC_HANDLER_02:
	CALR FDC_CMD_ENABLE
	CALR FDC_STATUS_HANDLER
	JR T, LABEL_F97DE1

FDC_HANDLER_03:
	CALR FDC_CMD_ENABLE
	CALR FDC_CMD_EXEC
	JR T, LABEL_F97DE1

FDC_HANDLER_04:
	CALR FDC_CMD_ENABLE
	CALR FDC_SECTOR_XFER
	JR T, LABEL_F97DE1

FDC_HANDLER_05:
	CALR FDC_CMD_ENABLE
	CALR FDC_MODE_CONFIG
	JR T, LABEL_F97DE1

FDC_HANDLER_06:
	CALR FDC_CMD_ENABLE
	JR T, LABEL_F97DE1

FDC_HANDLER_07:
	CALR FDC_CMD_DISABLE
	JR T, LABEL_F97DE1

FDC_HANDLER_08:
	CALR FDC_STATUS_COPY
	JR T, LABEL_F97DE1

FDC_HANDLER_09:
	CALR FDC_OUTPUT_CTRL
	JR T, LABEL_F97DE1

FDC_HANDLER_10:
	CALR FDC_CMD_DISPATCH_SUB
	JR T, LABEL_F97DE1

FDC_HANDLER_11:
	CALR FDC_CMD_ENABLE
	CALR FDC_INTERRUPT_HANDLER
	JR T, LABEL_F97DE1

LABEL_F97DDB:
	LD WA, 00ffh
	CALR FDC_Set_Status

LABEL_F97DE1:
	LD (8A16h), 05ah
	LD L, (8A24h)
	EXTS HL

LABEL_F97DEC:
	POP XIZ
	RET


LABEL_F97DEE:
	db 0D1h, 01Ch, 08Ah, 03Fh, 000h, 000h, 0B0h, 0F6h
	db 0D1h, 040h, 08Ah, 020h, 0D8h, 0DCh, 066h, 024h
	db 0D8h, 0DBh, 0B0h, 0FEh, 0C2h, 000h, 000h, 012h
	db 023h, 0E1h, 04Eh, 08Ah, 023h, 0B3h, 043h, 0EBh
	db 061h, 0F1h, 04Eh, 08Ah, 063h, 0D1h, 01Ch, 08Ah
	db 03Ah, 001h, 000h, 0B0h, 0FEh, 01Eh, 024h, 0F2h
	db 01Eh, 030h, 0F2h, 00Eh, 0E1h, 04Eh, 08Ah, 023h
	db 083h, 023h, 0F2h, 000h, 000h, 012h, 043h, 0EBh
	db 061h, 0F1h, 04Eh, 08Ah, 063h, 068h, 0DEh

INTTC3_HANDLER:			; F97E35
	PUSH XIZ
	PUSH XIY
	PUSH XIX
	PUSH XHL
	PUSH XDE
	PUSH XBC
	PUSH XWA
	CALR FDC_Pulse_PH0
	CALR FDC_Port_Reset_Or_Noop
	POP XWA
	POP XBC
	POP XDE
	POP XHL
	POP XIX
	POP XIY
	POP XIZ
	RETI


INT5_HANDLER:			; F97E4A	"FDCIRQ"
	LD (DMAR), 008h
	RETI


INT4_HANDLER:			; F97E50	"FDCINT"
	PUSH XIZ
	PUSH XIY
	PUSH XIX
	PUSH XHL
	PUSH XDE
	PUSH XBC
	PUSH XWA
	LD IZ, 0

LABEL_F97E59:
	LD WA, IZ
	INC 1, IZ
	CP WA, 0064h
	JR GT, LABEL_F97EBC
	CALR FDC_Read_Status
	BIT 7, L
	JR Z, LABEL_F97E59

LABEL_F97E6B:
	CALR FDC_Read_Status
	BIT 7, L
	JR Z, LABEL_F97E6B
	CALR FDC_Read_Status
	BIT 6, L
	JR NZ, LABEL_F97E93
	LD_L 0
	CP L, 80h
	JR Z, LABEL_F97E8D

LABEL_F97E82:
	CALR FDC_Read_Status
	AND L, 0f0h
	CP L, 80h
	JR NZ, LABEL_F97E82

LABEL_F97E8D:
	LD WA, 0008h
	CALR FDC_Write_Data

LABEL_F97E93:
	LDA XIZ, 8A60h
	INC 1, XIZ

LABEL_F97E99:
	CALR FDC_Wait_Status_Timeout
	CALR FDC_Read_Data
	LD (XIZ+), L

LABEL_F97EA2:
	CALR FDC_Read_Status
	BIT 7, L
	JR Z, LABEL_F97EA2
	CALR FDC_Read_Status
	BIT 6, L
	JR NZ, LABEL_F97E99
	CALR FDC_Exception_Status_Decoder
	CP (8A61h), 80h
	JR NZ, LABEL_F97E6B

LABEL_F97EBC:
	LD (8A60h), 0
	POP XWA
	POP XBC
	POP XDE
	POP XHL
	POP XIX
	POP XIY
	POP XIZ
	RETI


Reset_Floppy_Disk_Controller:		; F97EC9
; I am not entirely sure yet, but it looks like FDC initialization code...

	; reset FDC by toggling Port D bit 0
	SET 0, (PD)
	LD WA, 000ah
	CALR SOME_DELAY
	RES 0, (PD)
	LD WA, 000ah
	JRL T, SOME_DELAY

	; then do a lot of other stuff I still don't undertsand:

	LD (PHFC), 01eh
	BIT 6, (PD)	; Port D bit 6: "FD.I/O signal"
	RET NZ
	LD_A 0
	LDW (8B24h), 0000h
	LDW (8B26h), 0000h
	LDW (8B28h), 0000h
	CP A, 0
	JR NZ, LABEL_F97F03
	LDW (8B2Ah), 00e0h
	JR T, LABEL_F97F09

LABEL_F97F03:
	LDW (8B2Ah), 00d3h

LABEL_F97F09:
	LDW (8B2Ch), 0000h
	LDW (8B2Eh), 0000h
	LD XWA, 0
	LD (8B30h), XWA
	LDA XWA, 8B24h
	PUSH XWA
	CALR LABEL_F97CCA
	LDW (8B24h), 0003h
	LDW (8B26h), 0000h
	LDW (8B28h), 0000h
	LDW (8B2Ah), 0000h
	LDW (8B2Ch), 0001h
	LDW (8B2Eh), 0001h
	LDA XWA, 8B34h
	LD (8B30h), XWA
	LDA XWA, 8B24h
	PUSH XWA
	CALR LABEL_F97CCA
	LDW (8B24h), 0003h
	LDW (8B26h), 0000h
	LDW (8B28h), 0000h
	LDW (8B2Ah), 004eh
	LDW (8B2Ch), 0001h
	LDW (8B2Eh), 0001h
	LDA XWA, 8B34h
	LD (8B30h), XWA
	LDA XWA, 8B24h
	PUSH XWA
	CALR LABEL_F97CCA
	LDW (8B24h), 0003h
	LDW (8B26h), 0000h
	LDW (8B28h), 0000h
	LDW (8B2Ah), 000ah
	LDW (8B2Ch), 0001h
	LDW (8B2Eh), 0001h
	LDA XWA, 8B34h
	LD (8B30h), XWA
	LDA XWA, 8B24h
	PUSH XWA
	CALR LABEL_F97CCA
	LDW (8B24h), 0003h
	LDW (8B26h), 0000h
	LDW (8B28h), 0000h
	LDW (8B2Ah), 0028h
	LDW (8B2Ch), 0001h
	LDW (8B2Eh), 0001h
	LDA XWA, 8B34h
	LD (8B30h), XWA
	LDA XWA, 8B24h
	PUSH XWA
	CALR LABEL_F97CCA
	LDA XSP, XSP + 014h
	LD WA, 00c8h
	CALR SOME_DELAY
	INCW 1, (0E3DAh)
	RET

Check_for_Floppy_Disk_Change:		; F98001
	BIT 6, (PD)
	JR Z, Detected_Floppy_Disk_Change
	LD_L 000h
	RET

Detected_Floppy_Disk_Change:		; F98009
	LD_L 001h
	RET

; End of FDC routines
