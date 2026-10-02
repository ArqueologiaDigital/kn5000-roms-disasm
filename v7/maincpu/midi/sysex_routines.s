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
	ld	xwa, 15203716
	add	xwa, xde
	ld	a, (xwa)
	call	16614621
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
	add xbc, NakaInst_DIRECT_E7FCE4_0xA6
	ld bc, (xbc)
	lda xix, (ExcDotFunc_HandlerJumpTable:24)
	jp_ind 8, 0x07, 0xf0, 0xe4
ExcDotFunc_HandlerJumpTable:
	ld	xix, (xde+18)
	ld	xbc, (xde+14)
	ld	l, c
	ld	de, 0:i3
	ld	c, (149340:24)
	extz	bc
	cp	bc, 0:i3
	jr	ule, ExcDotFunc_Skip2	; -> 0xF762BD
ExcDotFunc_Loop:
	cp	l, 0:i3
	jr	z, ExcDotFunc_Skip	; -> 0xF762B3
	ld	(xix+), 157
	dec	1, l
	jr	ExcDotFunc_Join	; -> 0xF762B7
ExcDotFunc_Skip:
	ld	(xix+), 46
ExcDotFunc_Join:
	inc	1, de
	cp	de, bc
	jr	c, ExcDotFunc_Loop	; -> 0xF762A7
ExcDotFunc_Skip2:
	ld	(xix), 0
	ld	xhl, xwa
	ret
	ld	xhl, 1:i3
	ret
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
	add xbc, FileTransfer_BlankStatus_0xA
	ld bc, (xbc)
	lda xix, (ExcPmemFunc_HandlerJumpTable:24)
	jp_ind 8, 0x07, 0xf0, 0xe4
ExcPmemFunc_HandlerJumpTable:
	ld	xwa, (xde+14)
	sll	xwa, 2
	ld	xbc, 15203742
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xde+18)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, xiz
	jr	ExcPmemFunc_Return
	ld	xhl, 1:i3
	jr	ExcPmemFunc_Return
	ld	xhl, 3:i3
	jr	ExcPmemFunc_Return
ExcPmemFunc_InvalidIndex_Exit:
	ld xhl, 0:i3
	jr ExcPmemFunc_Return
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
	add xbc, FileTransfer_BlankStatus_0x1E
	ld bc, (xbc)
	lda xix, (ExcSmemFunc_HandlerJumpTable:24)
	jp_ind 8, 0x07, 0xf0, 0xe4
ExcSmemFunc_HandlerJumpTable:
	ld	xwa, (xde+14)
	sll	xwa, 2
	ld	xbc, 15203742
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xde+18)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, xiz
	jr	ExcSmemFunc_Return
	ld	xhl, 1:i3
	jr	ExcSmemFunc_Return
	ld	xhl, 3:i3
	jr	ExcSmemFunc_Return
ExcSmemFunc_InvalidIndex_Exit:
	ld xhl, 0:i3
	jr ExcSmemFunc_Return
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
	add xbc, FileTransfer_BlankStatus_0x32
	ld bc, (xbc)
	lda xix, (ExcCompFunc_HandlerJumpTable:24)
	jp_ind 8, 0x07, 0xf0, 0xe4
ExcCompFunc_HandlerJumpTable:
	ld	xwa, (xde+14)
	sll	xwa, 2
	ld	xbc, 15203742
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xde+18)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, xiz
	jr	ExcCompFunc_Return
	ld	xhl, 1:i3
	jr	ExcCompFunc_Return
	ld	xhl, 3:i3
	jr	ExcCompFunc_Return
ExcCompFunc_InvalidIndex_Exit:
	ld xhl, 0:i3
	jr ExcCompFunc_Return
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
	add xbc, FileTransfer_BlankStatus_0x46
	ld bc, (xbc)
	lda xix, (ExcSeqFunc_HandlerJumpTable:24)
	jp_ind 8, 0x07, 0xf0, 0xe4
ExcSeqFunc_HandlerJumpTable:
	ld	xwa, (xde+14)
	sll	xwa, 2
	ld	xbc, 15203742
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xde+18)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, xiz
	jr	ExcSeqFunc_Return
	ld	xhl, 1:i3
	jr	ExcSeqFunc_Return
	ld	xhl, 3:i3
	jr	ExcSeqFunc_Return
ExcSeqFunc_InvalidIndex_Exit:
	ld xhl, 0:i3
	jr ExcSeqFunc_Return
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
	add xbc, FileTransfer_BlankStatus_0x5A
	ld bc, (xbc)
	lda xix, (ExcMspFunc_HandlerJumpTable:24)
	jp_ind 8, 0x07, 0xf0, 0xe4
ExcMspFunc_HandlerJumpTable:
	ld	xwa, (xde+14)
	sll	xwa, 2
	ld	xbc, 15203742
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xde+18)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, xiz
	jr	ExcMspFunc_Return
	ld	xhl, 1:i3
	jr	ExcMspFunc_Return
	ld	xhl, 3:i3
	jr	ExcMspFunc_Return
ExcMspFunc_InvalidIndex_Exit:
	ld xhl, 0:i3
	jr ExcMspFunc_Return
	lda xhl, (0x024768:24)

ExcMspFunc_Return:
	pop xiz
	ret

; End of SysEx routines
