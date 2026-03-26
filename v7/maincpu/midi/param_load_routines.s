; =============================================================================
; Parameter Loading & Audio Flag Routines
; =============================================================================
;
; ParaLoadOpt parameter loading options, audio flag processing,
; and event posting routines. Bridges SysEx processing to the
; UI control panel.
; =============================================================================


ParaLoadOpt_AudioFlagCheck:
	.incbin "includes/generated/v7_transplant_ParaLoadOpt_AudioFlagCheck.bin"
ParaLoadOpt_CaseA:
	ldb_da a, (0x02475c)
	cp a, (xsp + 2)
	jr z, ParaLoadOpt_CaseB
	ld a, (xsp + 2)
	stb_da (0x02475c), a
	ld xwa, 0x570010
	ld xbc, 0x1e000a7
	lds32 xde, 0
	call ApPostEvent

; ParaLoadOpt case B
ParaLoadOpt_CaseB:
	ldb_da a, (0x02475e)
	cp a, (xsp)
	jr z, ParaLoadOpt_CaseC
	ld a, (xsp)
	stb_da (0x02475e), a
	ld xwa, 0x570010
	ld xbc, 0x1e000a7
	lds32 xde, 0
	call ApPostEvent

; ParaLoadOpt case C
ParaLoadOpt_CaseC:
	ldb_da a, (0x02475a)
	cp a, (xsp + 4)
	jrl z, MidiFunc_SendEvtReturnAlt
	ld a, (xsp + 4)
	stb_da (0x02475a), a
	ld a, (xsp + 4)
	extz wa
	cps wa, 0
	jrl mi, MidiFunc_SendEvtReturnAlt
	cp wa, 0xc
	jrl gt, MidiFunc_SendEvtReturnAlt
	add wa, wa
	lda_24 xix, (FileTransfer_BlankStatus_0x6E)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	lda_24 xix, (ParaLoadOpt_DispatchTable_A)
	jp_ind 8, 0x07, 0xf0, 0xe0

ParaLoadOpt_DispatchTable_A:
	stib_da	(0x024760), 0
	stib_da	(0x024762), 0
	stib_da	(0x024764), 0
	stib_da	(0x024766), 0
	stib_da	(0x024768), 0
	ld	xwa, 0x57000a
	ld	xbc, 0x01c0000b
	lds32	xde, 0
	jrl	201
	stib_da	(0x024760), 1
	ld	xwa, 0x57000a
	ld	xbc, 0x01c0000b
	lds32	xde, 0
	jrl	180
	stib_da	(0x024760), 3
	ld	xwa, 0x57000a
	ld	xbc, 0x01c0000b
	lds32	xde, 0
	jrl	159
	stib_da	(0x024762), 1
	ld	xwa, 0x57000a
	ld	xbc, 0x01c0000b
	lds32	xde, 0
	jrl	138
	stib_da	(0x024762), 3
	ld	xwa, 0x57000a
	ld	xbc, 0x01c0000b
	lds32	xde, 0
	jr	118
	stib_da	(0x024764), 1
	ld	xwa, 0x57000a
	ld	xbc, 0x01c0000b
	lds32	xde, 0
	jr	98
	stib_da	(0x024764), 3
	ld	xwa, 0x57000a
	ld	xbc, 0x01c0000b
	lds32	xde, 0
	jr	78
	stib_da	(0x024766), 1
	ld	xwa, 0x57000a
	ld	xbc, 0x01c0000b
	lds32	xde, 0
	jr	58
	stib_da	(0x024766), 3
	ld	xwa, 0x57000a
	ld	xbc, 0x01c0000b
	lds32	xde, 0
	jr	38
	stib_da	(0x024768), 1
	ld	xwa, 0x57000a
	ld	xbc, 0x01c0000b
	lds32	xde, 0
	jr	18
	stib_da	(0x024768), 3
	ld	xwa, 0x57000a
	ld	xbc, 0x01c0000b
	lds32	xde, 0
	call	ApPostEvent

MidiFunc_SendEvtReturnAlt:
	inc 6, xsp
	ret

ParaLoadOpt_AudioFlagCheck_B:
	.incbin "includes/generated/v7_transplant_ParaLoadOpt_AudioFlagCheck_B.bin"
ParaLoadOpt_CaseD:
	.incbin "includes/generated/v7_transplant_ParaLoadOpt_CaseD.bin"
ParaLoadOpt_CaseE:
	.incbin "includes/generated/v7_transplant_ParaLoadOpt_CaseE.bin"
ParaLoadOpt_CaseF:
	.incbin "includes/generated/v7_transplant_ParaLoadOpt_CaseF.bin"
ParaLoadOpt_DispatchTable_B:
	stib_da	(0x024760), 0
	stib_da	(0x024762), 0
	stib_da	(0x024764), 0
	stib_da	(0x024766), 0
	stib_da	(0x024768), 0
	ld	xwa, 0x570015
	ld	xbc, 0x01c0000b
	lds32	xde, 0
	jrl	201
	stib_da	(0x024760), 2
	ld	xwa, 0x570015
	ld	xbc, 0x01c0000b
	lds32	xde, 0
	jrl	180
	stib_da	(0x024760), 3
	ld	xwa, 0x570015
	ld	xbc, 0x01c0000b
	lds32	xde, 0
	jrl	159
	stib_da	(0x024762), 2
	ld	xwa, 0x570015
	ld	xbc, 0x01c0000b
	lds32	xde, 0
	jrl	138
	stib_da	(0x024762), 3
	ld	xwa, 0x570015
	ld	xbc, 0x01c0000b
	lds32	xde, 0
	jr	118
	stib_da	(0x024764), 2
	ld	xwa, 0x570015
	ld	xbc, 0x01c0000b
	lds32	xde, 0
	jr	98
	stib_da	(0x024764), 3
	ld	xwa, 0x570015
	ld	xbc, 0x01c0000b
	lds32	xde, 0
	jr	78
	stib_da	(0x024766), 2
	ld	xwa, 0x570015
	ld	xbc, 0x01c0000b
	lds32	xde, 0
	jr	58
	stib_da	(0x024766), 3
	ld	xwa, 0x570015
	ld	xbc, 0x01c0000b
	lds32	xde, 0
	jr	38
	stib_da	(0x024768), 2
	ld	xwa, 0x570015
	ld	xbc, 0x01c0000b
	lds32	xde, 0
	jr	18
	stib_da	(0x024768), 3
	ld	xwa, 0x570015
	ld	xbc, 0x01c0000b
	lds32	xde, 0
	call	ApPostEvent

MidiFunc_SendEventReturn:
	inc 6, xsp
	ret

ParaLoadOpt_PostDualEvent:
	ld	xwa, 0x570006
	ld	xbc, 0x01c00002
	lds32	xde, 0
	call	ApPostEvent
	ld	xwa, 0x570011
	ld	xbc, 0x01c00002
	lds32	xde, 0
	jp	ApPostEvent

TtMdParaLoad:
	cp xbc, 0x1c0000c
	jr z, TtMdParaLoad_ReturnZero
	cp xbc, 0x1c0000b
	jr z, TtMdParaLoad_ReturnZero
	cp xbc, 0x1c00002
	jr z, TtMdParaLoad_ReturnZero
	cp xbc, 0x1c00001
	jr nz, TtMdParaLoad_ReturnZero
	or xde, xde
	jr nz, TtMdParaLoad_ReturnZero
	ld xwa, 0x5c0001
	call GetViewInstance
	ld xwa, (xhl + 42)
	ldw (xwa), 0x2
	ld xwa, (xhl + 46)
	ldw (xwa), 0x1

TtMdParaLoad_ReturnZero:
	lds32 xhl, 0
	ret

AcParaLoadOptGridBoxProc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 12), xde
	ld (xsp + 16), xbc
	ld xiz, xwa
	ld xbc, (xsp + 16)
	cp xbc, 0x1e0008d
	jrl z, ParaLoadOpt_GridCheck2
	ld xwa, (xsp + 16)
	cp xwa, 0x1e0008b
	jrl z, ParaLoadOpt_GridCheck1
	cp xwa, 0x1e0008a
	jrl z, ParaLoadOpt_GridCheck0
	cp xwa, 0x1c00002
	jrl z, ParaLoadOpt_GridReturn
	cp xwa, 0x1c00001
	jr z, ParaLoadOpt_GridHandler
	sub xbc, 0x1c00017
	cp xbc, 0x0
	jrl lt, ParaLoadOpt_GridCheck3
	cp xbc, 0x6
	jrl gt, ParaLoadOpt_GridCheck3
	add xbc, xbc
	add xbc, FileTransfer_BlankStatus_0xC6
	ld bc, (xbc)
	lda_24 xix, (ParaLoadOpt_GridHandler)
	jp_ind 8, 0x07, 0xf0, 0xe4

; ParaLoadOpt grid handler
ParaLoadOpt_GridHandler:
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
	jrl ParaLoadOpt_SetDialAndReturn

; ParaLoadOpt grid return
ParaLoadOpt_GridReturn:
	.incbin "includes/generated/v7_transplant_ParaLoadOpt_GridReturn.bin"
ParaLoadOpt_GridDelegateProc:
	ld xwa, xiz
	ld xbc, 0x1e00091
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jrl z, AccFunc_ReturnZeroJmp
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
	jrl ParaLoadOpt_SetDialAndReturn
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, ParaLoadOpt_GridDelegateProc_B
	ld xwa, xiz
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld wa, hl
	add wa, wa
	lda_24 xbc, (FileTransfer_BlankStatus_0xB4)
	ldw_sri WA, 0x07, 0xe4, 0xe0
	add wa, hl
	ld de, wa
	extz xde
	add xde, 0xffff0000
	ld xwa, xiz
	ld xbc, 0x1c0000e
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl AccFunc_ReturnZeroJmp

ParaLoadOpt_GridDelegateProc_B:
	ld xwa, xiz
	ld xbc, 0x1e00091
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jrl z, AccFunc_ReturnZeroJmp
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

ParaLoadOpt_SetDialAndReturn:
	call SetDialEnable
	jr AccFunc_ReturnZeroJmp

; ParaLoadOpt grid check case 0
ParaLoadOpt_GridCheck0:
	ld xwa, xiz
	ld xiz, 0x3e
	jr ParaLoadOpt_GetViewAndCopy

; ParaLoadOpt grid check case 1
ParaLoadOpt_GridCheck1:
	ld xwa, xiz
	ld xiz, 0x42

ParaLoadOpt_GetViewAndCopy:
	.incbin "includes/generated/v7_transplant_ParaLoadOpt_GetViewAndCopy.bin"
ParaLoadOpt_GridCheck2:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)

ParaLoadOpt_CallApFunc:
	call ApFuncCall

AccFunc_ReturnZeroJmp:
	lds32 xhl, 0
	jr ParaLoadOpt_GridCheck4

; ParaLoadOpt grid check case 3
ParaLoadOpt_GridCheck3:
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc

; ParaLoadOpt grid check case 4
ParaLoadOpt_GridCheck4:
	pop xiz
	lda xsp, (xsp + 16)
	ret

ParaLoadOptGridCheck:
	lda xsp, (xsp - 62)
	push xiz
	ld xhl, xde
	ld xde, xbc
	ld xiy, NakaInst_INITIAL_0xA
	lda xix, (xsp + 28)
	ldw bc, 0x8
	ldirw
	ld xiy, MidiPart_PageStr_1of3_0xA
	lda xix, (xsp + 20)
	lds bc, 4
	ldirw
	ld (xsp + 16), xde
	lda_24 xwa, (UserMemory_Config_Table)
	ld (xsp + 4), xwa
	lda xbc, (xsp + 28)
	lda xiy, (xsp + 20)
	lda_24 xwa, (UserMemory_ConfirmData_0x16)
	ld (xsp + 8), xwa
	lda_24 xiz, (0x0340f6)
	lda xwa, (xiy + 2)
	lda xix, (xiy + 4)
	ld (xsp + 12), xix
	cp xde, 0x1e0008d
	jrl z, VoiceUI_MiscHandler
	ld xde, (xsp + 16)
	sub xde, 0x1c00017
	cp xde, 0x0
	jrl lt, ParaLoadOpt_ReturnZero
	cp xde, 0x6
	jrl gt, ParaLoadOpt_ReturnZero
	add xde, xde
	add xde, NakaInst_INITIAL_0x1A
	ld de, (xde)
	lda_24 xix, (ParaLoadOpt_GridDispatch)
	jp_ind 8, 0x07, 0xf0, 0xe8
; ParaLoadOptGridCheck dispatch
ParaLoadOpt_GridDispatch:
	.incbin "includes/generated/v7_transplant_ParaLoadOpt_GridDispatch.bin"
VoiceUI_MiscHandler:
	ld xde, xhl
	srl xde, 0
	ldiw_erp 0xea, 0
	ld (xiy), de
	ld xde, xwa
	ld (xwa), hl
	ld (xsp + 16), xbc
	ld xwa, (xsp + 12)
	ld (xwa), xbc
	cpw (xiy), 0x1
	jrl nz, ParaLoadOpt_ReturnZero
	ld wa, (xde)
	cp wa, 0x8
	jrl z, ParaLoadOpt_BuildFromIZ3
	cps wa, 7
	jr z, ParaLoadOpt_BuildFromIZ2
	ld xbc, (xsp + 8)
	cps wa, 3
	jr z, ParaLoadOpt_BuildFromIZ1
	cps wa, 2
	jrl nz, ParaLoadOpt_ReturnZero
	ld a, (xiz)
	extz wa
	sla wa, 2
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	ld xwa, (xsp + 20)
	push xwa

; --- UI Control Panel, Sound Navigation & Voice Control ---
