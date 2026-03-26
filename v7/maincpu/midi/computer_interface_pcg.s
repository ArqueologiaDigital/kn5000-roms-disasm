; =============================================================================
; computer_interface_pcg.asm - Computer Interface PCG Output
; =============================================================================
; This file contains PCG (Program Change) Output routines for the
; Computer Interface subsystem:
;   TtMdPcgOut            - PCG Output title handler
;   AcPcgOutGridBoxProc   - PCG Output grid box action processor
;   PcgOutGridCheck       - PCG Output grid validation
;   PcgOutSendFunc        - PCG Output send function handler
;   MainPcgOutSend        - Main PCG Output send dispatcher
;
; =============================================================================

TtMdPcgOut:
	cp xbc, 0x1c0000c
	jr z, TtMdPcgOut_Exit
	cp xbc, 0x1c0000b
	jr z, TtMdPcgOut_Exit
	cp xbc, 0x1c00002
	jr z, TtMdPcgOut_Exit
	cp xbc, 0x1c00001
	jr nz, TtMdPcgOut_Exit
	or xde, xde
	jr nz, TtMdPcgOut_Exit
	ld xwa, 0x590001
	call GetViewInstance
	ld xwa, (xhl + 42)
	ldw (xwa), 0x0
	ld xwa, (xhl + 46)
	ldw (xwa), 0x1

TtMdPcgOut_Exit:
	lds32 xhl, 0
	ret

AcPcgOutGridBoxProc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 12), xde
	ld (xsp + 16), xbc
	ld xiz, xwa
	ld xbc, (xsp + 16)
	cp xbc, 0x1e0008d
	jrl z, PcgOutGrid_DispatchDelegate
	ld xwa, (xsp + 16)
	cp xwa, 0x1e0008b
	jrl z, PcgOutGrid_CopyStrBank1
	cp xwa, 0x1e0008a
	jrl z, PcgOutGrid_CopyStrBank0
	cp xwa, 0x1c00001
	jr z, PcgOutGridBoxEventDispatch
	sub xbc, 0x1c00017
	cp xbc, 0x0
	jrl lt, PcgOutGrid_DefaultHandler
	cp xbc, 0x6
	jrl gt, PcgOutGrid_DefaultHandler
	add xbc, xbc
	add xbc, NakaInst_INITIAL_0x28
	ld bc, (xbc)
	lda_24 xix, (PcgOutGridBoxEventDispatch)
	jp_ind 8, 0x07, 0xf0, 0xe4

PcgOutGridBoxEventDispatch:
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, xiz
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld (xsp + 4), xhl
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1c00017
	call SetDialUp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1c00018
	call SetDialDown
	lds wa, 1
	jrl PcgOutGridDialConfirm
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, PcgOutGrid_CheckAltPrev
	ld xwa, xiz
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	dec 1, hl
	extz xhl
	add xhl, 0xffff0000
	ld xwa, xiz
	ld xbc, 0x1c0000e
	ld xde, xhl
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl PcgOutGrid_ReturnZero

PcgOutGrid_CheckAltPrev:
	ld xwa, xiz
	ld xbc, 0x1e00091
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jrl z, PcgOutGrid_ReturnZero
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call ApFuncCall
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	ld xwa, xiz
	ld xbc, 0x1c00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1c00018
	ld xde, (xsp + 12)
	call SetDialDown
	lds wa, 1
	jrl PcgOutGridDialConfirm
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, PcgOutGrid_CheckAltNext
	ld xwa, xiz
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	cps hl, 3
	jrl ge, PcgOutGrid_ReturnZero
	inc 1, hl
	extz xhl
	add xhl, 0xffff0000
	ld xwa, xiz
	ld xbc, 0x1c0000e
	ld xde, xhl
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl PcgOutGrid_ReturnZero

PcgOutGrid_CheckAltNext:
	ld xwa, xiz
	ld xbc, 0x1e00091
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jrl z, PcgOutGrid_ReturnZero
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call ApFuncCall
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	ld xwa, xiz
	ld xbc, 0x1c00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1c00018
	ld xde, (xsp + 12)
	call SetDialDown
	lds wa, 1

PcgOutGridDialConfirm:
	call SetDialEnable
	jr PcgOutGrid_ReturnZero

PcgOutGrid_CopyStrBank0:
	ld xwa, xiz
	ld xiz, 0x3e
	jr PcgOutGrid_CopyStrCommon

PcgOutGrid_CopyStrBank1:
	ld xwa, xiz
	ld xiz, 0x42

PcgOutGrid_CopyStrCommon:
	.incbin "includes/generated/v7_transplant_PcgOutGrid_CopyStrCommon.bin"
PcgOutGrid_DispatchDelegate:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)

PcgOutGrid_CallDelegate:
	call ApFuncCall

PcgOutGrid_ReturnZero:
	lds32 xhl, 0
	jr PcgOutGrid_Epilogue

PcgOutGrid_DefaultHandler:
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc

PcgOutGrid_Epilogue:
	pop xiz
	lda xsp, (xsp + 16)
	ret

PcgOutGridCheck:
	lda xsp, (xsp - 44)
	push xiz
	ld xiz, xde
	ld (xsp + 44), xbc
	ld xiy, UserMemory_FormatStrings_0x16
	lda xix, (xsp + 12)
	lds bc, 5
	ldirw
	ld xiy, MidiPart_PageStr_1of3_0xA
	lda xix, (xsp + 4)
	lds bc, 4
	ldirw
	ld xix, (xsp + 44)
	lda xiy, (xsp + 12)
	lda xhl, (xsp + 4)
	lda xbc, (xhl + 2)
	lda xde, (xhl + 4)
	ld xwa, (xsp + 44)
	cp xwa, 0x1e0008d
	jrl z, PcgOutCheckGridDataStructure
	ld xwa, xix
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, PcgOutGridCheckComplete
	cp xwa, 0x6
	jrl gt, PcgOutGridCheckComplete
	add xwa, xwa
	add xwa, UserMemory_FormatStrings_0xC0
	ld wa, (xwa)
	lda_24 xix, (PcgOutGridCheckJumpTable)
	jp_ind 8, 0x07, 0xf0, 0xe0

PcgOutGridCheckJumpTable:
	.incbin "includes/generated/v7_transplant_PcgOutGridCheckJumpTable.bin"
PcgOutCheckGridDataStructure:
	.incbin "includes/generated/v7_transplant_PcgOutCheckGridDataStructure.bin"
PcgOutCheck_SendPreset1:
	.incbin "includes/generated/v7_transplant_PcgOutCheck_SendPreset1.bin"
PcgOutCheck_SendPreset2:
	.incbin "includes/generated/v7_transplant_PcgOutCheck_SendPreset2.bin"
PcgOutCheck_SendPreset2Named:
	.incbin "includes/generated/v7_transplant_PcgOutCheck_SendPreset2Named.bin"
PcgOutCheck_SendPreset3:
	.incbin "includes/generated/v7_transplant_PcgOutCheck_SendPreset3.bin"
PcgOutCheck_SendPreset3Named:
	.incbin "includes/generated/v7_transplant_PcgOutCheck_SendPreset3Named.bin"
PcgOutCheck_SetFinalProp:
	call SendEvent

PcgOutGridCheckComplete:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 44)
	ret

PcgOutSendFunc:
	cp xbc, 0x1c00008
	jr nz, PcgOutSendFunc_Exit
	lda_24 xde, (0x024752)
	ldb_da a, (0x02476a)
	ld (xde), a
	ldb_da a, (0x02476c)
	ld (xde + 1), a
	lda xbc, (xde + 2)
	ldb_da l, (0x024770)
	cp l, 0xff
	jr nz, PcgOutSend_StoreBankIndex
	ldw (xbc), 0xffff
	jr PcgOutSend_TransmitMidi

PcgOutSend_StoreBankIndex:
	exts hl
	ldb_da a, (0x02476e)
	exts wa
	sla wa, 7
	add wa, hl
	ld (xbc), wa

PcgOutSend_TransmitMidi:
	ld xwa, 0x1430000
	ld xbc, 0x1e30000
	call MainFuncCall

PcgOutSendFunc_Exit:
	lds32 xhl, 0
	ret

MainPcgOutSend:
	.incbin "includes/generated/v7_transplant_MainPcgOutSend.bin"
MainPcgOutSend_Exit:
	lds32 xhl, 0
	ret

; End of Computer Interface PCG routines

