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
	cp xbc, 0x1C00007
	jr nz, ExcSendFunc_InvalidParam_Exit
	ld xwa, 0x570003
	ld xbc, 0x1E00090
	lds32 xde, 0
	call SendEvent
	exts xhl
	ld xwa, 0x1430001
	ld xbc, 0x1E30001
	ld xde, xhl
	call MainFuncCall

ExcSendFunc_InvalidParam_Exit:
	lds32 xhl, 0
	ret

MainExcSend:
	cp xbc, 0x1E30001
	jr nz, MainExcSend_UnexpectedMessageType_Exit
	cp xde, 0x6
	jr c, MainExcSend_ClampIndexToRange
	lds32 xde, 0

MainExcSend_ClampIndexToRange:
	ld xwa, 0xE7FD84
	add xwa, xde
	ld a, (xwa)
	call SysEx_InitiateSend

MainExcSend_UnexpectedMessageType_Exit:
	lds32 xhl, 0
	ret

ExcDotFunc:
	sub xbc, 0x1E0003E
	cp xbc, 0x0
	jr lt, ExcDotFunc_InvalidIndex_Exit
	cp xbc, 0x9
	jr gt, ExcDotFunc_InvalidIndex_Exit
	add xbc, xbc
	add xbc, 0xE7FD8A
	ld bc, (xbc)
	lda_24 xix, 0xf76696
	jp_dri 8, 0x07, 0xF0, 0xE4
ExcDotFunc_HandlerJumpTable:
	ld	xix, (xde+18)
	ld	xbc, (xde+14)
	ld	l, c
	lds	de, 0
	ld8_24	c, 149340
	extz	bc
	cps	bc, 0
	jr	ule, 22
	cps	l, 0
	jr	z, 8
	stib_dpi	240, 157
	dec	1, l
	jr	4
	stib_dpi	240, 46
	inc	1, de
	cp	de, bc
	jr	c, -22
	ld	(xix), 0
	ld	xhl, xwa
	ret
	lds32	xhl, 1
	ret
	ld	xhl, 32
	ret

ExcDotFunc_InvalidIndex_Exit:
	lds32 xhl, 0
	ret

ExcDotFunc_HandlerJumpTable_Ext:
	lda_24	xhl, 149342
	ret

ExcPmemFunc:
	push xiz
	ld xiz, xwa
	sub xbc, 0x1E0003E
	cp xbc, 0x0
	jr lt, ExcPmemFunc_InvalidIndex_Exit
	cp xbc, 0x9
	jr gt, ExcPmemFunc_InvalidIndex_Exit
	add xbc, xbc
	add xbc, 0xE7FDD6
	ld bc, (xbc)
	lda_24 xix, 0xf76706
	jp_dri 8, 0x07, 0xF0, 0xE4
ExcPmemFunc_HandlerJumpTable:
	ld	xwa, (xde+14)
	sll	xwa, 2
	ld	xbc, 15203742
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xde+18)
	push	xwa
	call	16715597
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
	sub xbc, 0x1E0003E
	cp xbc, 0x0
	jr lt, ExcSmemFunc_InvalidIndex_Exit
	cp xbc, 0x9
	jr gt, ExcSmemFunc_InvalidIndex_Exit
	add xbc, xbc
	add xbc, 0xE7FDEA
	ld bc, (xbc)
	lda_24 xix, 0xf76764
	jp_dri 8, 0x07, 0xF0, 0xE4
ExcSmemFunc_HandlerJumpTable:
	ld	xwa, (xde+14)
	sll	xwa, 2
	ld	xbc, 15203742
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xde+18)
	push	xwa
	call	16715597
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
	sub xbc, 0x1E0003E
	cp xbc, 0x0
	jr lt, ExcCompFunc_InvalidIndex_Exit
	cp xbc, 0x9
	jr gt, ExcCompFunc_InvalidIndex_Exit
	add xbc, xbc
	add xbc, 0xE7FDFE
	ld bc, (xbc)
	lda_24 xix, 0xf767c2
	jp_dri 8, 0x07, 0xF0, 0xE4
ExcCompFunc_HandlerJumpTable:
	ld	xwa, (xde+14)
	sll	xwa, 2
	ld	xbc, 15203742
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xde+18)
	push	xwa
	call	16715597
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
	sub xbc, 0x1E0003E
	cp xbc, 0x0
	jr lt, ExcSeqFunc_InvalidIndex_Exit
	cp xbc, 0x9
	jr gt, ExcSeqFunc_InvalidIndex_Exit
	add xbc, xbc
	add xbc, 0xE7FE12
	ld bc, (xbc)
	lda_24 xix, 0xf76820
	jp_dri 8, 0x07, 0xF0, 0xE4
ExcSeqFunc_HandlerJumpTable:
	ld	xwa, (xde+14)
	sll	xwa, 2
	ld	xbc, 15203742
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xde+18)
	push	xwa
	call	16715597
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
	sub xbc, 0x1E0003E
	cp xbc, 0x0
	jr lt, ExcMspFunc_InvalidIndex_Exit
	cp xbc, 0x9
	jr gt, ExcMspFunc_InvalidIndex_Exit
	add xbc, xbc
	add xbc, 0xE7FE26
	ld bc, (xbc)
	lda_24 xix, 0xf7687e
	jp_dri 8, 0x07, 0xF0, 0xE4
ExcMspFunc_HandlerJumpTable:
	ld	xwa, (xde+14)
	sll	xwa, 2
	ld	xbc, 15203742
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xde+18)
	push	xwa
	call	16715597
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
