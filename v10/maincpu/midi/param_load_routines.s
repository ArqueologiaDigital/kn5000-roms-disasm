; =============================================================================
; Parameter Loading & Audio Flag Routines
; =============================================================================
;
; ParaLoadOpt parameter loading options, audio flag processing,
; and event posting routines. Bridges SysEx processing to the
; UI control panel.
; =============================================================================


ParaLoadOpt_AudioFlagCheck:
	dec 6, xsp
	ld (xsp), e
	ld (xsp + 2), c
	ld (xsp + 4), a
	ldda8 a, 48438
	bit 0, a
	jr z, ParaLoadOpt_CaseA
	res 0, a
	stda8 48438, a
	ld xwa, 0x570006
	ld xbc, 0x1c00001
	lds32 xde, 0
	call ApPostEvent

; ParaLoadOpt case A
ParaLoadOpt_CaseA:
	ld8_24 a, 0x02475c
	cp a, (xsp + 2)
	jr z, ParaLoadOpt_CaseB
	ld a, (xsp + 2)
	st8_24 0x02475c, a
	ld xwa, 0x570010
	ld xbc, 0x1e000a7
	lds32 xde, 0
	call ApPostEvent

; ParaLoadOpt case B
ParaLoadOpt_CaseB:
	ld8_24 a, 0x02475e
	cp a, (xsp)
	jr z, ParaLoadOpt_CaseC
	ld a, (xsp)
	st8_24 0x02475e, a
	ld xwa, 0x570010
	ld xbc, 0x1e000a7
	lds32 xde, 0
	call ApPostEvent

; ParaLoadOpt case C
ParaLoadOpt_CaseC:
	ld8_24 a, 0x02475a
	cp a, (xsp + 4)
	jrl z, MidiFunc_SendEvtReturnAlt
	ld a, (xsp + 4)
	st8_24 0x02475a, a
	ld a, (xsp + 4)
	extz wa
	cps wa, 0
	jrl mi, MidiFunc_SendEvtReturnAlt
	cp wa, 0xc
	jrl gt, MidiFunc_SendEvtReturnAlt
	add wa, wa
	lda_24 xix, 0xe7fe3a
	ld_sriw3 WA, 0x07, 0xf0, 0xe0
	lda_24 xix, ParaLoadOpt_DispatchTable_A
	jp_dri 8, 0x07, 0xf0, 0xe0

ParaLoadOpt_DispatchTable_A:
	sti8_24	149344, 0
	sti8_24	149346, 0
	sti8_24	149348, 0
	sti8_24	149350, 0
	sti8_24	149352, 0
	ld	xwa, 5701642
	ld	xbc, 29360139
	lds32	xde, 0
	jrl	201
	sti8_24	149344, 1
	ld	xwa, 5701642
	ld	xbc, 29360139
	lds32	xde, 0
	jrl	180
	sti8_24	149344, 3
	ld	xwa, 5701642
	ld	xbc, 29360139
	lds32	xde, 0
	jrl	159
	sti8_24	149346, 1
	ld	xwa, 5701642
	ld	xbc, 29360139
	lds32	xde, 0
	jrl	138
	sti8_24	149346, 3
	ld	xwa, 5701642
	ld	xbc, 29360139
	lds32	xde, 0
	jr	118
	sti8_24	149348, 1
	ld	xwa, 5701642
	ld	xbc, 29360139
	lds32	xde, 0
	jr	98
	sti8_24	149348, 3
	ld	xwa, 5701642
	ld	xbc, 29360139
	lds32	xde, 0
	jr	78
	sti8_24	149350, 1
	ld	xwa, 5701642
	ld	xbc, 29360139
	lds32	xde, 0
	jr	58
	sti8_24	149350, 3
	ld	xwa, 5701642
	ld	xbc, 29360139
	lds32	xde, 0
	jr	38
	sti8_24	149352, 1
	ld	xwa, 5701642
	ld	xbc, 29360139
	lds32	xde, 0
	jr	18
	sti8_24	149352, 3
	ld	xwa, 5701642
	ld	xbc, 29360139
	lds32	xde, 0
	call	ApPostEvent

MidiFunc_SendEvtReturnAlt:
	inc 6, xsp
	ret

ParaLoadOpt_AudioFlagCheck_B:
	dec 6, xsp
	ld (xsp), e
	ld (xsp + 2), c
	ld (xsp + 4), a
	ldda8 a, 48438
	bit 1, a
	jr z, ParaLoadOpt_CaseD
	res 1, a
	stda8 48438, a
	ld xwa, 0x570011
	ld xbc, 0x1c00001
	lds32 xde, 0
	call ApPostEvent

; ParaLoadOpt case D
ParaLoadOpt_CaseD:
	ldda8 a, 48400
	bit 7, a
	jr z, ParaLoadOpt_CaseE
	res 7, a
	stda8 48400, a
	ld a, (xsp + 2)
	st8_24 0x02475c, a
	ld xwa, 0x57001b
	ld xbc, 0x1e000a7
	lds32 xde, 0
	call ApPostEvent

; ParaLoadOpt case E
ParaLoadOpt_CaseE:
	ldda8 a, 48404
	bit 7, a
	jr z, ParaLoadOpt_CaseF
	res 7, a
	stda8 48404, a
	ld a, (xsp)
	st8_24 0x02475e, a
	ld xwa, 0x57001b
	ld xbc, 0x1e000a7
	lds32 xde, 0
	call ApPostEvent

; ParaLoadOpt case F
ParaLoadOpt_CaseF:
	ldda8 a, 48396
	bit 7, a
	jrl z, MidiFunc_SendEventReturn
	res 7, a
	stda8 48396, a
	ld a, (xsp + 4)
	extz wa
	cps wa, 0
	jrl mi, MidiFunc_SendEventReturn
	cp wa, 0xc
	jrl gt, MidiFunc_SendEventReturn
	add wa, wa
	lda_24 xix, 0xe7fe54
	ld_sriw3 WA, 0x07, 0xf0, 0xe0
	lda_24 xix, ParaLoadOpt_DispatchTable_B
	jp_dri 8, 0x07, 0xf0, 0xe0

ParaLoadOpt_DispatchTable_B:
	sti8_24	149344, 0
	sti8_24	149346, 0
	sti8_24	149348, 0
	sti8_24	149350, 0
	sti8_24	149352, 0
	ld	xwa, 5701653
	ld	xbc, 29360139
	lds32	xde, 0
	jrl	201
	sti8_24	149344, 2
	ld	xwa, 5701653
	ld	xbc, 29360139
	lds32	xde, 0
	jrl	180
	sti8_24	149344, 3
	ld	xwa, 5701653
	ld	xbc, 29360139
	lds32	xde, 0
	jrl	159
	sti8_24	149346, 2
	ld	xwa, 5701653
	ld	xbc, 29360139
	lds32	xde, 0
	jrl	138
	sti8_24	149346, 3
	ld	xwa, 5701653
	ld	xbc, 29360139
	lds32	xde, 0
	jr	118
	sti8_24	149348, 2
	ld	xwa, 5701653
	ld	xbc, 29360139
	lds32	xde, 0
	jr	98
	sti8_24	149348, 3
	ld	xwa, 5701653
	ld	xbc, 29360139
	lds32	xde, 0
	jr	78
	sti8_24	149350, 2
	ld	xwa, 5701653
	ld	xbc, 29360139
	lds32	xde, 0
	jr	58
	sti8_24	149350, 3
	ld	xwa, 5701653
	ld	xbc, 29360139
	lds32	xde, 0
	jr	38
	sti8_24	149352, 2
	ld	xwa, 5701653
	ld	xbc, 29360139
	lds32	xde, 0
	jr	18
	sti8_24	149352, 3
	ld	xwa, 5701653
	ld	xbc, 29360139
	lds32	xde, 0
	call	ApPostEvent

MidiFunc_SendEventReturn:
	inc 6, xsp
	ret

ParaLoadOpt_PostDualEvent:
	ld	xwa, 5701638
	ld	xbc, 29360130
	lds32	xde, 0
	call	ApPostEvent
	ld	xwa, 5701649
	ld	xbc, 29360130
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
	add xbc, 0xe7fe92
	ld bc, (xbc)
	lda_24 xix, ParaLoadOpt_GridHandler
	jp_dri 8, 0x07, 0xf0, 0xe4

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
	ldi_werp 0xe2, 0
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
	ldi_werp 0xe2, 0
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
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, (xsp + 12)
	or xwa, xwa
	jrl nz, AccFunc_ReturnZeroJmp
	lds wa, 7
	call PanelDisplay_DispatchByMode
	cps hl, 0
	jrl z, AccFunc_ReturnZeroJmp
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 1
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call PostEvent
	stdi8 32578, 72
	ld xwa, 0xffffffff
	ld xbc, 0x1c00016
	ld xde, 0x1a000ee
	call PostEvent
	ld xwa, 0x1430003
	ld xbc, 0x1e30006
	ld xde, (xsp + 12)
	call MainFuncCall
	jrl AccFunc_ReturnZeroJmp
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, ParaLoadOpt_GridDelegateProc
	ld xwa, xiz
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld wa, hl
	add wa, wa
	lda_24 xbc, 0xe7fe6e
	ld_sriw3 WA, 0x07, 0xe4, 0xe0
	sub hl, wa
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
	jrl AccFunc_ReturnZeroJmp

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
	lda_24 xbc, 0xe7fe80
	ld_sriw3 WA, 0x07, 0xe4, 0xe0
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
	call GetViewInstance
	add xhl, xiz
	ld xwa, (xhl)
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	jr AccFunc_ReturnZeroJmp
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	jr ParaLoadOpt_CallApFunc

; ParaLoadOpt grid check case 2
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
	ld xiy, 0xe7ff02
	lda xix, (xsp + 28)
	ldw bc, 0x8
	ldirw
	ld xiy, 0xe7ed44
	lda xix, (xsp + 20)
	lds bc, 4
	ldirw
	ld (xsp + 16), xde
	lda_24 xwa, 0xe7feca
	ld (xsp + 4), xwa
	lda xbc, (xsp + 28)
	lda xiy, (xsp + 20)
	lda_24 xwa, 0xe7feb6
	ld (xsp + 8), xwa
	lda_24 xiz, 0x0340f6
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
	add xde, 0xe7ff12
	ld de, (xde)
	lda_24 xix, ParaLoadOpt_GridDispatch
	jp_dri 8, 0x07, 0xf0, 0xe8
; ParaLoadOptGridCheck dispatch
ParaLoadOpt_GridDispatch:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 31457423
	lds32	xde, 0
	call	SendEvent
	lda	xwa, (xsp+20)
	ld	xbc, xhl
	srl	xbc, 0
	.byte 0xd7, 0xe6, 0xa8
	ld	(xwa), bc
	ld	(xwa+2), hl
	cpw	(xwa), 1
	jrl	nz, 801
	cp	hl, 8
	jr	z, 106
	cps	hl, 7
	jr	z, 71
	cps	hl, 3
	jr	z, 36
	cps	hl, 2
	jrl	nz, 782
	ld	xiy, 15204000
	lda	xix, (xsp+44)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+44)
	lda_24	xbc, 213238
	ld	(xwa), xbc
	lds32	xbc, 1
	ld	(xwa+6), xbc
	jrl	303
	ld	xiy, 15204000
	lda	xix, (xsp+44)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+44)
	lda_24	xbc, 213239
	ld	(xwa), xbc
	lds32	xbc, 1
	ld	(xwa+6), xbc
	jrl	272
	ld	xiy, 15204000
	lda	xix, (xsp+44)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+44)
	lda_24	xbc, 213240
	ld	(xwa), xbc
	lds32	xbc, 3
	ld	(xwa+6), xbc
	jrl	241
	ld	xiy, 15204000
	lda	xix, (xsp+44)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+44)
	lda_24	xbc, 213241
	ld	(xwa), xbc
	lds32	xbc, 3
	ld	(xwa+6), xbc
	jrl	210
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 31457423
	lds32	xde, 0
	call	SendEvent
	lda	xwa, (xsp+20)
	ld	xbc, xhl
	srl	xbc, 0
	.byte 0xd7, 0xe6, 0xa8
	ld	(xwa), bc
	ld	(xwa+2), hl
	cpw	(xwa), 1
	jrl	nz, 618
	cp	hl, 8
	jrl	z, 127
	cps	hl, 7
	jr	z, 85
	cps	hl, 3
	jr	z, 43
	cps	hl, 2
	jrl	nz, 598
	ld	xiy, 15204000
	lda	xix, (xsp+44)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+44)
	lda_24	xbc, 213238
	ld	(xwa), xbc
	lds32	xbc, 1
	ld	(xwa+6), xbc
	ld	xbc, 4294967295
	ld	(xwa+14), xbc
	jr	112
	ld	xiy, 15204000
	lda	xix, (xsp+44)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+44)
	lda_24	xbc, 213239
	ld	(xwa), xbc
	lds32	xbc, 1
	ld	(xwa+6), xbc
	ld	xbc, 4294967295
	.byte 0xb8
	ret
	.ascii "ahJE"
	.long UserMemory_ConfirmData
	lda	xix, (xsp+44)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+44)
	lda_24	xbc, 213240
	ld	(xwa), xbc
	lds32	xbc, 3
	ld	(xwa+6), xbc
	ld	xbc, 4294967295
	.byte 0xb8
	ret
	.ascii "ah$E"
	cp	(xwa), xiz
	.byte 0xe7
	nop
	lda	xix, (xsp+44)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+44)
	lda_24	xbc, 213241
	ld	(xwa), xbc
	lds32	xbc, 3
	ld	(xwa+6), xbc
	ld	xbc, 4294967295
	ld	(xwa+14), xbc
	call	MainRamAdd
	jrl	441
	ld	xix, xhl
	ldw	(xiy), 1
	ld	(xsp+16), xbc
	ld	xde, (xsp+12)
	ld	(xde), xbc
	ld	xbc, xiz
	lda	xde, (xhl+14)
	.byte 0xa3, 0xf6
	jr	nz, 44
	ldw	(xwa), 2
	ld	xwa, (xde)
	sll	xwa, 2
	ld	xbc, (xsp+8)
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xsp+20)
	push	xwa
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+20)
	ld	xbc, 31457420
	jrl	370
	lda	xhl, (xbc+1)
	.byte 0xa4, 0xf3
	jr	nz, 44
	ldw	(xwa), 3
	ld	xwa, (xde)
	sll	xwa, 2
	ld	xbc, (xsp+8)
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xsp+20)
	push	xwa
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+20)
	ld	xbc, 31457420
	jrl	319
	lda	xhl, (xbc+2)
	.byte 0xa4, 0xf3
	jr	nz, 44
	ldw	(xwa), 7
	ld	xwa, (xde)
	sll	xwa, 2
	ld	xbc, (xsp+4)
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xsp+20)
	push	xwa
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+20)
	ld	xbc, 31457420
	jrl	268
	inc	3, xbc
	.byte 0xa4, 0xf1
	jrl	nz, 265
	.byte 0xb0
	push_sr
	ldio	0, 162
	ldb	w, 232
	.byte 0xee
	push_sr
	ld	xbc, (xsp+4)
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xsp+20)
	push	xwa
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+20)
	ld	xbc, 31457420
	jrl	217

; Voice UI misc handler
VoiceUI_MiscHandler:
	ld xde, xhl
	srl xde, 0
	ldi_werp 0xea, 0
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
