; =============================================================================
; Parameter Loading & Audio Flag Routines
; =============================================================================
;
; ParaLoadOpt parameter loading options, audio flag processing,
; and event posting routines. Bridges SysEx processing to the
; UI control panel.
; =============================================================================


ParaLoadOpt_AudioFlagCheck:
	dec	6, xsp
	ld	(xsp), e
	ld	(xsp+2), c
	ld	(xsp+4), a
	ld	a, (48282:16)
	bit	0, a
	jr	z, ParaLoadOpt_CaseA
	res	0, a
	ld	(48282:16), a
	ld	xwa, 5701638
	ld	xbc, 29360129
	ld	xde, 0:i3
	call	ApPostEvent
ParaLoadOpt_CaseA:
	ld a, (0x02475c:24)
	cp a, (xsp + 2)
	jr z, ParaLoadOpt_CaseB
	ld a, (xsp + 2)
	ld (0x02475c:24), a
	ld xwa, 0x570010
	ld xbc, 0x1e000a7
	ld xde, 0:i3
	call ApPostEvent

; ParaLoadOpt case B
ParaLoadOpt_CaseB:
	ld a, (0x02475e:24)
	cp a, (xsp)
	jr z, ParaLoadOpt_CaseC
	ld a, (xsp)
	ld (0x02475e:24), a
	ld xwa, 0x570010
	ld xbc, 0x1e000a7
	ld xde, 0:i3
	call ApPostEvent

; ParaLoadOpt case C
ParaLoadOpt_CaseC:
	ld a, (0x02475a:24)
	cp a, (xsp + 4)
	jrl z, MidiFunc_SendEvtReturnAlt
	ld a, (xsp + 4)
	ld (0x02475a:24), a
	ld a, (xsp + 4)
	extz wa
	cp wa, 0:i3
	jrl mi, MidiFunc_SendEvtReturnAlt
	cp wa, 0xc
	jrl gt, MidiFunc_SendEvtReturnAlt
	add wa, wa
	lda xix, (FileTransfer_BlankStatus_0x6E:24)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	lda xix, (ParaLoadOpt_DispatchTable_A:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

ParaLoadOpt_DispatchTable_A:
	ld	(0x024760:24), 0
	ld	(0x024762:24), 0
	ld	(0x024764:24), 0
	ld	(0x024766:24), 0
	ld	(0x024768:24), 0
	ld	xwa, 0x57000a
	ld	xbc, 0x01c0000b
	ld	xde, 0:i3
	jrl	ParaLoadOpt_DispatchTable_A_Join
	ld	(0x024760:24), 1
	ld	xwa, 0x57000a
	ld	xbc, 0x01c0000b
	ld	xde, 0:i3
	jrl	ParaLoadOpt_DispatchTable_A_Join
	ld	(0x024760:24), 3
	ld	xwa, 0x57000a
	ld	xbc, 0x01c0000b
	ld	xde, 0:i3
	jrl	ParaLoadOpt_DispatchTable_A_Join
	ld	(0x024762:24), 1
	ld	xwa, 0x57000a
	ld	xbc, 0x01c0000b
	ld	xde, 0:i3
	jrl	ParaLoadOpt_DispatchTable_A_Join
	ld	(0x024762:24), 3
	ld	xwa, 0x57000a
	ld	xbc, 0x01c0000b
	ld	xde, 0:i3
	jr	ParaLoadOpt_DispatchTable_A_Join
	ld	(0x024764:24), 1
	ld	xwa, 0x57000a
	ld	xbc, 0x01c0000b
	ld	xde, 0:i3
	jr	ParaLoadOpt_DispatchTable_A_Join
	ld	(0x024764:24), 3
	ld	xwa, 0x57000a
	ld	xbc, 0x01c0000b
	ld	xde, 0:i3
	jr	ParaLoadOpt_DispatchTable_A_Join
	ld	(0x024766:24), 1
	ld	xwa, 0x57000a
	ld	xbc, 0x01c0000b
	ld	xde, 0:i3
	jr	ParaLoadOpt_DispatchTable_A_Join
	ld	(0x024766:24), 3
	ld	xwa, 0x57000a
	ld	xbc, 0x01c0000b
	ld	xde, 0:i3
	jr	ParaLoadOpt_DispatchTable_A_Join
	ld	(0x024768:24), 1
	ld	xwa, 0x57000a
	ld	xbc, 0x01c0000b
	ld	xde, 0:i3
	jr	ParaLoadOpt_DispatchTable_A_Join
	ld	(0x024768:24), 3
	ld	xwa, 0x57000a
	ld	xbc, 0x01c0000b
	ld	xde, 0:i3
ParaLoadOpt_DispatchTable_A_Join:
	call	ApPostEvent

MidiFunc_SendEvtReturnAlt:
	inc 6, xsp
	ret

ParaLoadOpt_AudioFlagCheck_B:
	dec	6, xsp
	ld	(xsp), e
	ld	(xsp+2), c
	ld	(xsp+4), a
	ld	a, (48282:16)
	bit	1, a
	jr	z, ParaLoadOpt_CaseD
	res	1, a
	ld	(48282:16), a
	ld	xwa, 5701649
	ld	xbc, 29360129
	ld	xde, 0:i3
	call	ApPostEvent
ParaLoadOpt_CaseD:
	ld	a, (48244:16)
	bit	7, a
	jr	z, ParaLoadOpt_CaseE
	res	7, a
	ld	(48244:16), a
	ld	a, (xsp+2)
	ld	(149340:24), a
	ld	xwa, 5701659
	ld	xbc, 31457447
	ld	xde, 0:i3
	call	ApPostEvent
ParaLoadOpt_CaseE:
	ld	a, (48248:16)
	bit	7, a
	jr	z, ParaLoadOpt_CaseF
	res	7, a
	ld	(48248:16), a
	ld	a, (xsp)
	ld	(149342:24), a
	ld	xwa, 5701659
	ld	xbc, 31457447
	ld	xde, 0:i3
	call	ApPostEvent
ParaLoadOpt_CaseF:
	ld	a, (48240:16)
	bit	7, a
	jrl	z, MidiFunc_SendEventReturn	; -> 0xF767F9
	res	7, a
	ld	(48240:16), a
	ld	a, (xsp+4)
	extz	wa
	cp	wa, 0:i3
	jrl	mi, MidiFunc_SendEventReturn	; -> 0xF767F9
	cp	wa, 12
	jrl	gt, MidiFunc_SendEventReturn	; -> 0xF767F9
	add	wa, wa
	lda	xix, (15203924:24)
	ld_rrw	wa, xix, wa
	lda	xix, (16213759:24)
	jp_rr	8, xix, wa
ParaLoadOpt_DispatchTable_B:
	ld	(0x024760:24), 0
	ld	(0x024762:24), 0
	ld	(0x024764:24), 0
	ld	(0x024766:24), 0
	ld	(0x024768:24), 0
	ld	xwa, 0x570015
	ld	xbc, 0x01c0000b
	ld	xde, 0:i3
	jrl	ParaLoadOpt_DispatchTable_B_Join
	ld	(0x024760:24), 2
	ld	xwa, 0x570015
	ld	xbc, 0x01c0000b
	ld	xde, 0:i3
	jrl	ParaLoadOpt_DispatchTable_B_Join
	ld	(0x024760:24), 3
	ld	xwa, 0x570015
	ld	xbc, 0x01c0000b
	ld	xde, 0:i3
	jrl	ParaLoadOpt_DispatchTable_B_Join
	ld	(0x024762:24), 2
	ld	xwa, 0x570015
	ld	xbc, 0x01c0000b
	ld	xde, 0:i3
	jrl	ParaLoadOpt_DispatchTable_B_Join
	ld	(0x024762:24), 3
	ld	xwa, 0x570015
	ld	xbc, 0x01c0000b
	ld	xde, 0:i3
	jr	ParaLoadOpt_DispatchTable_B_Join
	ld	(0x024764:24), 2
	ld	xwa, 0x570015
	ld	xbc, 0x01c0000b
	ld	xde, 0:i3
	jr	ParaLoadOpt_DispatchTable_B_Join
	ld	(0x024764:24), 3
	ld	xwa, 0x570015
	ld	xbc, 0x01c0000b
	ld	xde, 0:i3
	jr	ParaLoadOpt_DispatchTable_B_Join
	ld	(0x024766:24), 2
	ld	xwa, 0x570015
	ld	xbc, 0x01c0000b
	ld	xde, 0:i3
	jr	ParaLoadOpt_DispatchTable_B_Join
	ld	(0x024766:24), 3
	ld	xwa, 0x570015
	ld	xbc, 0x01c0000b
	ld	xde, 0:i3
	jr	ParaLoadOpt_DispatchTable_B_Join
	ld	(0x024768:24), 2
	ld	xwa, 0x570015
	ld	xbc, 0x01c0000b
	ld	xde, 0:i3
	jr	ParaLoadOpt_DispatchTable_B_Join
	ld	(0x024768:24), 3
	ld	xwa, 0x570015
	ld	xbc, 0x01c0000b
	ld	xde, 0:i3
ParaLoadOpt_DispatchTable_B_Join:
	call	ApPostEvent

MidiFunc_SendEventReturn:
	inc 6, xsp
	ret

ParaLoadOpt_PostDualEvent:
	ld	xwa, 0x570006
	ld	xbc, 0x01c00002
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, 0x570011
	ld	xbc, 0x01c00002
	ld	xde, 0:i3
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
	ld xhl, 0:i3
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
	lda xix, (ParaLoadOpt_GridHandler:24)
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
	ld xde, 0:i3
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
	ld wa, 1:i3
	jrl ParaLoadOpt_SetDialAndReturn

; ParaLoadOpt grid return
ParaLoadOpt_GridReturn:
	ld XWA,XIZ
	ld XBC,(XSP+0x10)
	ld XDE,(XSP+0x0c)
	call InheritedProc
	ld XWA,(XSP+0x0c)
	or XWA,XWA
	jrl nz, AccFunc_ReturnZeroJmp
	ld wa, 7:i3
	call PanelDisplay_DispatchByMode
	cp hl, 0:i3
	jrl z, AccFunc_ReturnZeroJmp
	ld XWA,0xffffffff
	ld XBC,0x01e0009e
	ld xde, 1:i3
	call SendEvent
	ld XWA,0xffffffff
	ld XBC,0x01e0009e
	ld xde, 0:i3
	call PostEvent
	ld (0x7ea6:16), 0x48
	ld XWA,0xffffffff
	ld XBC,0x01c00016
	ld XDE,0x01a000ee
	call PostEvent
	ld XWA,0x01430003
	ld XBC,0x01e30006
	ld XDE,(XSP+0x0c)
	call MainFuncCall
	jrl t, AccFunc_ReturnZeroJmp
	ld XWA,XIZ
	ld XBC,(XSP+0x10)
	ld XDE,(XSP+0x0c)
	call InheritedProc
	ld XWA,XIZ
	ld XBC,0x01e00050
	ld XDE,(XSP+0x0c)
	call SendEvent
	or XHL,XHL
	jr z, ParaLoadOpt_GridDelegateProc
	ld XWA,XIZ
	ld XBC,0x01e0008f
	ld xde, 0:i3
	call SendEvent
	ld WA,HL
	add WA,WA
	lda xbc, (FileTransfer_BlankStatus_0xA2:24)
	ldw_dri wa, 0x07, 0xe4, 0xe0
	sub HL,WA
	extz XHL
	add XHL,0xffff0000
	ld XWA,XIZ
	ld XBC,0x01c0000e
	ld XDE,XHL
	call SendEvent
	ld XWA,XIZ
	ld XBC,(XSP+0x10)
	ld XDE,(XSP+0x0c)
	call SetAutoInc
	jrl t, AccFunc_ReturnZeroJmp
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
	ld wa, 1:i3
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
	ld xde, 0:i3
	call SendEvent
	ld wa, hl
	add wa, wa
	lda xbc, (FileTransfer_BlankStatus_0xB4:24)
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
	ld wa, 1:i3

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
	call	GetViewInstance
	add	xhl, xiz
	ld	xwa, (xhl)
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	AccFunc_ReturnZeroJmp
	ld	xwa, xiz
	call	GetViewInstance
	ld	xwa, (xhl+70)
	ld	xbc, (xsp+16)
	ld	xde, (xsp+12)
	jr	ParaLoadOpt_CallApFunc
ParaLoadOpt_GridCheck2:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)

ParaLoadOpt_CallApFunc:
	call ApFuncCall

AccFunc_ReturnZeroJmp:
	ld xhl, 0:i3
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
	ld bc, 4:i3
	ldirw
	ld (xsp + 16), xde
	lda xwa, (UserMemory_Config_Table:24)
	ld (xsp + 4), xwa
	lda xbc, (xsp + 28)
	lda xiy, (xsp + 20)
	lda xwa, (UserMemory_ConfirmData_0x16:24)
	ld (xsp + 8), xwa
	lda xiz, (0x0340f6:24)
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
	lda xix, (ParaLoadOpt_GridDispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe8
ParaLoadOpt_GridDispatch:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 31457423
	ld	xde, 0:i3
	call	SendEvent
	lda	xwa, (xsp+20)
	ld	xbc, xhl
	srl	xbc, 0
	ld	qbc, 0
	ld	(xwa), bc
	ld	(xwa+2), hl
	.byte 0x90, 0x3f, 0x01, 0x00
	jrl	nz, ParaLoadOpt_ReturnZero
	cp	hl, 8
	jr	z, ParaLoadOpt_GridDispatch_Skip3
	cp	hl, 7:i3
	jr	z, ParaLoadOpt_GridDispatch_Skip2
	cp	hl, 3:i3
	jr	z, ParaLoadOpt_GridDispatch_Skip
	cp	hl, 2:i3
	jrl	nz, ParaLoadOpt_ReturnZero
	ld	xiy, 15204000
	lda	xix, (xsp+44)
	ldw	bc, 11
	.byte 0x95, 0x11
	lda	xwa, (xsp+44)
	lda	xbc, (213238:24)
	ld	(xwa), xbc
	ld	xbc, 1:i3
	ld	(xwa+6), xbc
	jrl	ParaLoadOpt_GridDispatch_Join
ParaLoadOpt_GridDispatch_Skip:
	ld	xiy, 15204000
	lda	xix, (xsp+44)
	ldw	bc, 11
	.byte 0x95, 0x11
	lda	xwa, (xsp+44)
	lda	xbc, (213239:24)
	ld	(xwa), xbc
	ld	xbc, 1:i3
	ld	(xwa+6), xbc
	jrl	ParaLoadOpt_GridDispatch_Join
ParaLoadOpt_GridDispatch_Skip2:
	ld	xiy, 15204000
	lda	xix, (xsp+44)
	ldw	bc, 11
	.byte 0x95, 0x11
	lda	xwa, (xsp+44)
	lda	xbc, (213240:24)
	ld	(xwa), xbc
	ld	xbc, 3:i3
	ld	(xwa+6), xbc
	jrl	ParaLoadOpt_GridDispatch_Join
ParaLoadOpt_GridDispatch_Skip3:
	ld	xiy, 15204000
	lda	xix, (xsp+44)
	ldw	bc, 11
	.byte 0x95, 0x11
	lda	xwa, (xsp+44)
	lda	xbc, (213241:24)
	ld	(xwa), xbc
	ld	xbc, 3:i3
	ld	(xwa+6), xbc
	jrl	ParaLoadOpt_GridDispatch_Join
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 31457423
	ld	xde, 0:i3
	call	SendEvent
	lda	xwa, (xsp+20)
	ld	xbc, xhl
	srl	xbc, 0
	ld	qbc, 0
	ld	(xwa), bc
	ld	(xwa+2), hl
	.byte 0x90, 0x3f, 0x01, 0x00
	jrl	nz, ParaLoadOpt_ReturnZero
	cp	hl, 8
	jrl	z, ParaLoadOpt_GridDispatch_Skip6
	cp	hl, 7:i3
	jr	z, ParaLoadOpt_GridDispatch_Skip5
	cp	hl, 3:i3
	jr	z, ParaLoadOpt_GridDispatch_Skip4
	cp	hl, 2:i3
	jrl	nz, ParaLoadOpt_ReturnZero
	ld	xiy, 15204000
	lda	xix, (xsp+44)
	ldw	bc, 11
	.byte 0x95, 0x11
	lda	xwa, (xsp+44)
	lda	xbc, (213238:24)
	ld	(xwa), xbc
	ld	xbc, 1:i3
	ld	(xwa+6), xbc
	ld	xbc, 4294967295
	ld	(xwa+14), xbc
	jr	ParaLoadOpt_GridDispatch_Join
ParaLoadOpt_GridDispatch_Skip4:
	ld	xiy, 15204000
	lda	xix, (xsp+44)
	ldw	bc, 11
	.byte 0x95, 0x11
	lda	xwa, (xsp+44)
	lda	xbc, (213239:24)
	ld	(xwa), xbc
	ld	xbc, 1:i3
	ld	(xwa+6), xbc
	ld	xbc, 4294967295
	ld	(xwa+14), xbc
	jr	ParaLoadOpt_GridDispatch_Join
ParaLoadOpt_GridDispatch_Skip5:
	ld	xiy, 15204000
	lda	xix, (xsp+44)
	ldw	bc, 11
	.byte 0x95, 0x11
	lda	xwa, (xsp+44)
	lda	xbc, (213240:24)
	ld	(xwa), xbc
	ld	xbc, 3:i3
	ld	(xwa+6), xbc
	ld	xbc, 4294967295
	ld	(xwa+14), xbc
	jr	ParaLoadOpt_GridDispatch_Join
ParaLoadOpt_GridDispatch_Skip6:
	ld	xiy, 15204000
	lda	xix, (xsp+44)
	ldw	bc, 11
	.byte 0x95, 0x11
	lda	xwa, (xsp+44)
	lda	xbc, (213241:24)
	ld	(xwa), xbc
	ld	xbc, 3:i3
	ld	(xwa+6), xbc
	ld	xbc, 4294967295
	ld	(xwa+14), xbc
ParaLoadOpt_GridDispatch_Join:
	call	MainRamAdd
	jrl	ParaLoadOpt_ReturnZero
	ld	xix, xhl
	ldw	(xiy), 1
	ld	(xsp+16), xbc
	ld	xde, (xsp+12)
	ld	(xde), xbc
	ld	xbc, xiz
	lda	xde, (xhl+14)
	.byte 0xa3, 0xf6
	jr	nz, ParaLoadOpt_GridDispatch_Skip7
	ldw	(xwa), 2
	ld	xwa, (xde)
	sll	xwa, 2
	ld	xbc, (xsp+8)
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xsp+20)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+20)
	ld	xbc, 31457420
	jrl	ParaLoadOptSendEvtReturn
ParaLoadOpt_GridDispatch_Skip7:
	lda	xhl, (xbc+1)
	.byte 0xa4, 0xf3
	jr	nz, ParaLoadOpt_GridDispatch_Skip8
	ldw	(xwa), 3
	ld	xwa, (xde)
	sll	xwa, 2
	ld	xbc, (xsp+8)
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xsp+20)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+20)
	ld	xbc, 31457420
	jrl	ParaLoadOptSendEvtReturn
ParaLoadOpt_GridDispatch_Skip8:
	lda	xhl, (xbc+2)
	.byte 0xa4, 0xf3
	jr	nz, ParaLoadOpt_GridDispatch_Skip9
	ldw	(xwa), 7
	ld	xwa, (xde)
	sll	xwa, 2
	ld	xbc, (xsp+4)
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xsp+20)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+20)
	ld	xbc, 31457420
	jrl	ParaLoadOptSendEvtReturn
ParaLoadOpt_GridDispatch_Skip9:
	inc	3, xbc
	.byte 0xa4, 0xf1
	jrl	nz, ParaLoadOpt_ReturnZero
	ldw	(xwa), 8
	ld	xwa, (xde)
	sll	xwa, 2
	ld	xbc, (xsp+4)
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xsp+20)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+20)
	ld	xbc, 31457420
	jrl	ParaLoadOptSendEvtReturn
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
	cp wa, 7:i3
	jr z, ParaLoadOpt_BuildFromIZ2
	ld xbc, (xsp + 8)
	cp wa, 3:i3
	jr z, ParaLoadOpt_BuildFromIZ1
	cp wa, 2:i3
	jrl nz, ParaLoadOpt_ReturnZero
	ld a, (xiz)
	extz wa
	sla wa, 2
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	ld xwa, (xsp + 20)
	push xwa

; --- UI Control Panel, Sound Navigation & Voice Control ---
