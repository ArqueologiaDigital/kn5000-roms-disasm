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
	cp xbc, 0x1c00007
	jr nz, ExcSendFunc_InvalidParam_Exit
	ld xwa, 0x570003
	ld xbc, 0x1e00090
	lds32 xde, 0
	call SendEvent
	exts xhl
	ld xwa, 0x1430001
	ld xbc, 0x1e30001
	ld xde, xhl
	call MainFuncCall

ExcSendFunc_InvalidParam_Exit:
	lds32 xhl, 0
	ret

MainExcSend:
	cp xbc, 0x1e30001
	jr nz, MainExcSend_UnexpectedMessageType_Exit
	cp xde, 0x6
	jr c, MainExcSend_ClampIndexToRange
	lds32 xde, 0

MainExcSend_ClampIndexToRange:
	ld xwa, NakaInst_DIRECT_E7FCE4_0xA0
	add xwa, xde
	ld a, (xwa)
	call SysEx_InitiateSend

MainExcSend_UnexpectedMessageType_Exit:
	lds32 xhl, 0
	ret

ExcDotFunc:
	sub xbc, 0x1e0003e
	cp xbc, 0x0
	jr lt, ExcDotFunc_InvalidIndex_Exit
	cp xbc, 0x9
	jr gt, ExcDotFunc_InvalidIndex_Exit
	add xbc, xbc
	add xbc, NakaInst_DIRECT_E7FCE4_0xA6
	ld bc, (xbc)
	lda_24 xix, ExcDotFunc_HandlerJumpTable
	jp_ind 8, 0x07, 0xf0, 0xe4
ExcDotFunc_HandlerJumpTable:
	.byte 0xaa, 0x12, 0x24, 0xaa, 0x0e, 0x21, 0xcb, 0x8f
	.byte 0xda, 0xa8, 0xc2, 0x5c, 0x47, 0x02, 0x23, 0xd9
	.byte 0x12, 0xd9, 0xd8, 0x63, 0x16, 0xcf, 0xd8, 0x66
	.byte 0x08, 0xf5, 0xf0, 0x00, 0x9d, 0xcf, 0x69, 0x68
	.byte 0x04, 0xf5, 0xf0, 0x00, 0x2e, 0xda, 0x61, 0xd9
	.byte 0xf2, 0x67, 0xea, 0xb4, 0x00, 0x00, 0xe8, 0x8b
	.byte 0x0e, 0xeb, 0xa9, 0x0e, 0x43, 0x20, 0x00, 0x00
	.byte 0x00, 0x0e

ExcDotFunc_InvalidIndex_Exit:
	lds32 xhl, 0
	ret

ExcDotFunc_HandlerJumpTable_Ext:
	.byte 0xf2, 0x5e, 0x47, 0x02, 0x33, 0x0e

ExcPmemFunc:
	push xiz
	ld xiz, xwa
	sub xbc, 0x1e0003e
	cp xbc, 0x0
	jr lt, ExcPmemFunc_InvalidIndex_Exit
	cp xbc, 0x9
	jr gt, ExcPmemFunc_InvalidIndex_Exit
	add xbc, xbc
	add xbc, FileTransfer_BlankStatus_0xA
	ld bc, (xbc)
	lda_24 xix, ExcPmemFunc_HandlerJumpTable
	jp_ind 8, 0x07, 0xf0, 0xe4
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
	jr	17
	lds32	xhl, 1
	jr	13
	lds32	xhl, 3
	jr	9

ExcPmemFunc_InvalidIndex_Exit:
	lds32 xhl, 0
	jr ExcPmemFunc_Return
	lda_24 xhl, 0x024760

ExcPmemFunc_Return:
	pop xiz
	ret

ExcSmemFunc:
	push xiz
	ld xiz, xwa
	sub xbc, 0x1e0003e
	cp xbc, 0x0
	jr lt, ExcSmemFunc_InvalidIndex_Exit
	cp xbc, 0x9
	jr gt, ExcSmemFunc_InvalidIndex_Exit
	add xbc, xbc
	add xbc, FileTransfer_BlankStatus_0x1E
	ld bc, (xbc)
	lda_24 xix, ExcSmemFunc_HandlerJumpTable
	jp_ind 8, 0x07, 0xf0, 0xe4
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
	jr	17
	lds32	xhl, 1
	jr	13
	lds32	xhl, 3
	jr	9

ExcSmemFunc_InvalidIndex_Exit:
	lds32 xhl, 0
	jr ExcSmemFunc_Return
	lda_24 xhl, 0x024762

ExcSmemFunc_Return:
	pop xiz
	ret

ExcCompFunc:
	push xiz
	ld xiz, xwa
	sub xbc, 0x1e0003e
	cp xbc, 0x0
	jr lt, ExcCompFunc_InvalidIndex_Exit
	cp xbc, 0x9
	jr gt, ExcCompFunc_InvalidIndex_Exit
	add xbc, xbc
	add xbc, FileTransfer_BlankStatus_0x32
	ld bc, (xbc)
	lda_24 xix, ExcCompFunc_HandlerJumpTable
	jp_ind 8, 0x07, 0xf0, 0xe4
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
	jr	17
	lds32	xhl, 1
	jr	13
	lds32	xhl, 3
	jr	9

ExcCompFunc_InvalidIndex_Exit:
	lds32 xhl, 0
	jr ExcCompFunc_Return
	lda_24 xhl, 0x024764

ExcCompFunc_Return:
	pop xiz
	ret

ExcSeqFunc:
	push xiz
	ld xiz, xwa
	sub xbc, 0x1e0003e
	cp xbc, 0x0
	jr lt, ExcSeqFunc_InvalidIndex_Exit
	cp xbc, 0x9
	jr gt, ExcSeqFunc_InvalidIndex_Exit
	add xbc, xbc
	add xbc, FileTransfer_BlankStatus_0x46
	ld bc, (xbc)
	lda_24 xix, ExcSeqFunc_HandlerJumpTable
	jp_ind 8, 0x07, 0xf0, 0xe4
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
	jr	17
	lds32	xhl, 1
	jr	13
	lds32	xhl, 3
	jr	9

ExcSeqFunc_InvalidIndex_Exit:
	lds32 xhl, 0
	jr ExcSeqFunc_Return
	lda_24 xhl, 0x024766

ExcSeqFunc_Return:
	pop xiz
	ret

ExcMspFunc:
	push xiz
	ld xiz, xwa
	sub xbc, 0x1e0003e
	cp xbc, 0x0
	jr lt, ExcMspFunc_InvalidIndex_Exit
	cp xbc, 0x9
	jr gt, ExcMspFunc_InvalidIndex_Exit
	add xbc, xbc
	add xbc, FileTransfer_BlankStatus_0x5A
	ld bc, (xbc)
	lda_24 xix, ExcMspFunc_HandlerJumpTable
	jp_ind 8, 0x07, 0xf0, 0xe4
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
	jr	17
	lds32	xhl, 1
	jr	13
	lds32	xhl, 3
	jr	9

ExcMspFunc_InvalidIndex_Exit:
	lds32 xhl, 0
	jr ExcMspFunc_Return
	lda_24 xhl, 0x024768

ExcMspFunc_Return:
	pop xiz
	ret

; End of SysEx routines
