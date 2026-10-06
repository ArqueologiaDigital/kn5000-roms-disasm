; =============================================================================
; sysex_routines.asm - MIDI System Exclusive (SysEx) Routines
; =============================================================================
; This file contains all MIDI System Exclusive message handling routines
; for the KN5000 Main CPU.
;
; System Exclusive messages are used for:
;   - Bulk data dumps (panel memory, sound memory, composer, sequences, MSP)
;   - Parameter transfers between devices
;   - Manufacturer-specific commands
;
; Routines included:
;   ExcSendFunc    - Main SysEx send handler
;   MainExcSend    - SysEx send dispatch
;   ExcDotFunc     - DOT (Data Object Transfer) handler
;   ExcPmemFunc    - Panel Memory SysEx handler
;   ExcSmemFunc    - Sound Memory SysEx handler
;   ExcCompFunc    - Composer SysEx handler
;   ExcSeqFunc     - Sequence SysEx handler
;   ExcMspFunc     - MSP (Music Style Programmer) SysEx handler
;
; Each Exc*Func handles SysEx messages for a specific data type:
;   - PMEM: Panel Memory settings (PM1-PM8)
;   - SMEM: Sound Memory banks
;   - COMP: Composer/arranger data
;   - SEQ:  Sequencer song data
;   - MSP:  Music Style Programmer data
;
; =============================================================================

ExcSendFunc:
	ld xhl, xde
	cp xbc, EVT_SW_IN
	jr nz, ExcSendFunc_InvalidParam_Exit
	ld xwa, 0x570003
	ld xbc, EVT_GET_SELECTED
	ld xde, 0:i3
	call SendEvent
	exts xhl
	ld xwa, NAKA_MAINFUNC_MainExcSend
	ld xbc, EVT_EXC_SEND
	ld xde, xhl
	call MainFuncCall

ExcSendFunc_InvalidParam_Exit:
	ld xhl, 0:i3
	ret

MainExcSend:
	cp xbc, EVT_EXC_SEND
	jr nz, MainExcSend_UnexpectedMessageType_Exit
	cp xde, 0x6
	jr c, MainExcSend_ClampIndexToRange
	ld xde, 0:i3

MainExcSend_ClampIndexToRange:
	ld xwa, MainExcSend_ClampIndexToRange_Table
	add xwa, xde
	ld a, (xwa)
	call SysEx_InitiateSend

MainExcSend_UnexpectedMessageType_Exit:
	ld xhl, 0:i3
	ret

ExcDotFunc:
	sub xbc, EVT_GET_LARGE_STEP
	cp xbc, 0x0
	jr lt, ExcDotFunc_InvalidIndex_Exit
	cp xbc, 0x9
	jr gt, ExcDotFunc_InvalidIndex_Exit
	add xbc, xbc
	add xbc, ExcDotFunc_CaseTable
	ld bc, (xbc)
	lda xix, (ExcDotFunc_HandlerJumpTable:24)
	jp	t, (xix+bc)
ExcDotFunc_HandlerJumpTable:
	ld	xix, (xde+18)
	ld	xbc, (xde+14)
	ld	l, c
	ld	de, 0:i3
	ld	c, (149340:24)
	extz	bc
	cp	bc, 0:i3
	jr	ule, ExcDotFunc_Skip2
ExcDotFunc_Loop:
	cp	l, 0:i3
	jr	z, ExcDotFunc_Skip
	ld	(xix+), 157
	dec	1, l
	jr	ExcDotFunc_Join
ExcDotFunc_Skip:
	ld	(xix+), 46
ExcDotFunc_Join:
	inc	1, de
	cp	de, bc
	jr	c, ExcDotFunc_Loop
ExcDotFunc_Skip2:
	ld	(xix), 0
	ld	xhl, xwa
	ret
ExcDotFunc_OnGetLargeStep:	; cases 31457342, 31457343, 31457350
	ld	xhl, 1:i3
	ret
ExcDotFunc_OnGetMax:
	ld	xhl, 32
	ret

ExcDotFunc_InvalidIndex_Exit:
	ld xhl, 0:i3
	ret

ExcDotFunc_HandlerJumpTable_Ext:
	lda	xhl, (149342:24)
	ret

ExcPmemFunc:
	push xiz
	ld xiz, xwa
	sub xbc, EVT_GET_LARGE_STEP
	cp xbc, 0x0
	jr lt, ExcPmemFunc_InvalidIndex_Exit
	cp xbc, 0x9
	jr gt, ExcPmemFunc_InvalidIndex_Exit
	add xbc, xbc
	add xbc, ExcPmemFunc_CaseTable
	ld bc, (xbc)
	lda xix, (ExcPmemFunc_HandlerJumpTable:24)
	jp	t, (xix+bc)
ExcPmemFunc_HandlerJumpTable:
	ld	xwa, (xde+14)
	sll	xwa, 2
	ld	xbc, FileTransfer_Status_Table
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xde+18)
	push	xwa
	call	Strcpy
	inc	8, xsp
	ld	xhl, xiz
	jr	ExcPmemFunc_Return
ExcPmemFunc_OnGetLargeStep:	; cases 31457342, 31457343, 31457350
	ld	xhl, 1:i3
	jr	ExcPmemFunc_Return
ExcPmemFunc_OnGetMax:
	ld	xhl, 3:i3
	jr	ExcPmemFunc_Return

ExcPmemFunc_InvalidIndex_Exit:
	ld xhl, 0:i3
	jr ExcPmemFunc_Return
ExcPmemFunc_OnGetRamAddress:
	lda xhl, (0x024760:24)

ExcPmemFunc_Return:
	pop xiz
	ret

ExcSmemFunc:
	push xiz
	ld xiz, xwa
	sub xbc, EVT_GET_LARGE_STEP
	cp xbc, 0x0
	jr lt, ExcSmemFunc_InvalidIndex_Exit
	cp xbc, 0x9
	jr gt, ExcSmemFunc_InvalidIndex_Exit
	add xbc, xbc
	add xbc, ExcSmemFunc_CaseTable
	ld bc, (xbc)
	lda xix, (ExcSmemFunc_HandlerJumpTable:24)
	jp	t, (xix+bc)
ExcSmemFunc_HandlerJumpTable:
	ld	xwa, (xde+14)
	sll	xwa, 2
	ld	xbc, FileTransfer_Status_Table
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xde+18)
	push	xwa
	call	Strcpy
	inc	8, xsp
	ld	xhl, xiz
	jr	ExcSmemFunc_Return
ExcSmemFunc_OnGetLargeStep:	; cases 31457342, 31457343, 31457350
	ld	xhl, 1:i3
	jr	ExcSmemFunc_Return
ExcSmemFunc_OnGetMax:
	ld	xhl, 3:i3
	jr	ExcSmemFunc_Return

ExcSmemFunc_InvalidIndex_Exit:
	ld xhl, 0:i3
	jr ExcSmemFunc_Return
ExcSmemFunc_OnGetRamAddress:
	lda xhl, (0x024762:24)

ExcSmemFunc_Return:
	pop xiz
	ret

ExcCompFunc:
	push xiz
	ld xiz, xwa
	sub xbc, EVT_GET_LARGE_STEP
	cp xbc, 0x0
	jr lt, ExcCompFunc_InvalidIndex_Exit
	cp xbc, 0x9
	jr gt, ExcCompFunc_InvalidIndex_Exit
	add xbc, xbc
	add xbc, ExcCompFunc_CaseTable
	ld bc, (xbc)
	lda xix, (ExcCompFunc_HandlerJumpTable:24)
	jp	t, (xix+bc)
ExcCompFunc_HandlerJumpTable:
	ld	xwa, (xde+14)
	sll	xwa, 2
	ld	xbc, FileTransfer_Status_Table
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xde+18)
	push	xwa
	call	Strcpy
	inc	8, xsp
	ld	xhl, xiz
	jr	ExcCompFunc_Return
ExcCompFunc_OnGetLargeStep:	; cases 31457342, 31457343, 31457350
	ld	xhl, 1:i3
	jr	ExcCompFunc_Return
ExcCompFunc_OnGetMax:
	ld	xhl, 3:i3
	jr	ExcCompFunc_Return

ExcCompFunc_InvalidIndex_Exit:
	ld xhl, 0:i3
	jr ExcCompFunc_Return
ExcCompFunc_OnGetRamAddress:
	lda xhl, (0x024764:24)

ExcCompFunc_Return:
	pop xiz
	ret

ExcSeqFunc:
	push xiz
	ld xiz, xwa
	sub xbc, EVT_GET_LARGE_STEP
	cp xbc, 0x0
	jr lt, ExcSeqFunc_InvalidIndex_Exit
	cp xbc, 0x9
	jr gt, ExcSeqFunc_InvalidIndex_Exit
	add xbc, xbc
	add xbc, ExcSeqFunc_CaseTable
	ld bc, (xbc)
	lda xix, (ExcSeqFunc_HandlerJumpTable:24)
	jp	t, (xix+bc)
ExcSeqFunc_HandlerJumpTable:
	ld	xwa, (xde+14)
	sll	xwa, 2
	ld	xbc, FileTransfer_Status_Table
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xde+18)
	push	xwa
	call	Strcpy
	inc	8, xsp
	ld	xhl, xiz
	jr	ExcSeqFunc_Return
ExcSeqFunc_OnGetLargeStep:	; cases 31457342, 31457343, 31457350
	ld	xhl, 1:i3
	jr	ExcSeqFunc_Return
ExcSeqFunc_OnGetMax:
	ld	xhl, 3:i3
	jr	ExcSeqFunc_Return

ExcSeqFunc_InvalidIndex_Exit:
	ld xhl, 0:i3
	jr ExcSeqFunc_Return
ExcSeqFunc_OnGetRamAddress:
	lda xhl, (0x024766:24)

ExcSeqFunc_Return:
	pop xiz
	ret

ExcMspFunc:
	push xiz
	ld xiz, xwa
	sub xbc, EVT_GET_LARGE_STEP
	cp xbc, 0x0
	jr lt, ExcMspFunc_InvalidIndex_Exit
	cp xbc, 0x9
	jr gt, ExcMspFunc_InvalidIndex_Exit
	add xbc, xbc
	add xbc, ExcMspFunc_CaseTable
	ld bc, (xbc)
	lda xix, (ExcMspFunc_HandlerJumpTable:24)
	jp	t, (xix+bc)
ExcMspFunc_HandlerJumpTable:
	ld	xwa, (xde+14)
	sll	xwa, 2
	ld	xbc, FileTransfer_Status_Table
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xde+18)
	push	xwa
	call	Strcpy
	inc	8, xsp
	ld	xhl, xiz
	jr	ExcMspFunc_Return
ExcMspFunc_OnGetLargeStep:	; cases 31457342, 31457343, 31457350
	ld	xhl, 1:i3
	jr	ExcMspFunc_Return
ExcMspFunc_OnGetMax:
	ld	xhl, 3:i3
	jr	ExcMspFunc_Return

ExcMspFunc_InvalidIndex_Exit:
	ld xhl, 0:i3
	jr ExcMspFunc_Return
ExcMspFunc_OnGetRamAddress:
	lda xhl, (0x024768:24)

ExcMspFunc_Return:
	pop xiz
	ret

; End of SysEx routines
