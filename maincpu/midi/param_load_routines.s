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
	ld xbc, 0x1C00001
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
	ld xbc, 0x1E000A7
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
	ld xbc, 0x1E000A7
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
	cp wa, 0xC
	jrl gt, MidiFunc_SendEvtReturnAlt
	add wa, wa
	lda_24 xix, 0xe7fe3a
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xf76955
	jp_dri 8, 0x07, 0xF0, 0xE0

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
	call	16424280

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
	ld xbc, 0x1C00001
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
	ld xwa, 0x57001B
	ld xbc, 0x1E000A7
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
	ld xwa, 0x57001B
	ld xbc, 0x1E000A7
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
	cp wa, 0xC
	jrl gt, MidiFunc_SendEventReturn
	add wa, wa
	lda_24 xix, 0xe7fe54
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xf76b03
	jp_dri 8, 0x07, 0xF0, 0xE0

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
	call	16424280

MidiFunc_SendEventReturn:
	inc 6, xsp
	ret

ParaLoadOpt_PostDualEvent:
	ld	xwa, 5701638
	ld	xbc, 29360130
	lds32	xde, 0
	call	16424280
	ld	xwa, 5701649
	ld	xbc, 29360130
	lds32	xde, 0
	jp	16424280

TtMdParaLoad:
	cp xbc, 0x1C0000C
	jr z, TtMdParaLoad_ReturnZero
	cp xbc, 0x1C0000B
	jr z, TtMdParaLoad_ReturnZero
	cp xbc, 0x1C00002
	jr z, TtMdParaLoad_ReturnZero
	cp xbc, 0x1C00001
	jr nz, TtMdParaLoad_ReturnZero
	or xde, xde
	jr nz, TtMdParaLoad_ReturnZero
	ld xwa, 0x5C0001
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
	cp xbc, 0x1E0008D
	jrl z, ParaLoadOpt_GridCheck2
	ld xwa, (xsp + 16)
	cp xwa, 0x1E0008B
	jrl z, ParaLoadOpt_GridCheck1
	cp xwa, 0x1E0008A
	jrl z, ParaLoadOpt_GridCheck0
	cp xwa, 0x1C00002
	jrl z, ParaLoadOpt_GridReturn
	cp xwa, 0x1C00001
	jr z, ParaLoadOpt_GridHandler
	sub xbc, 0x1C00017
	cp xbc, 0x0
	jrl lt, ParaLoadOpt_GridCheck3
	cp xbc, 0x6
	jrl gt, ParaLoadOpt_GridCheck3
	add xbc, xbc
	add xbc, 0xE7FE92
	ld bc, (xbc)
	lda_24 xix, 0xf76cc8
	jp_dri 8, 0x07, 0xF0, 0xE4

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
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	ld (xsp + 4), xhl
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldi_werp 0xE2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1C00017
	call SetDialUp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldi_werp 0xE2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1C00018
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
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call SendEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call PostEvent
	stdi8 32578, 72
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	ld xde, 0x1A000EE
	call PostEvent
	ld xwa, 0x1430003
	ld xbc, 0x1E30006
	ld xde, (xsp + 12)
	call MainFuncCall
	jrl AccFunc_ReturnZeroJmp
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1E00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, ParaLoadOpt_GridDelegateProc
	ld xwa, xiz
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	ld wa, hl
	add wa, wa
	lda_24 xbc, 0xe7fe6e
	ld_sriw3 WA, 0x07, 0xE4, 0xE0
	sub hl, wa
	extz xhl
	add xhl, 0xFFFF0000
	ld xwa, xiz
	ld xbc, 0x1C0000E
	ld xde, xhl
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl AccFunc_ReturnZeroJmp

ParaLoadOpt_GridDelegateProc:
	ld xwa, xiz
	ld xbc, 0x1E00091
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
	ld xbc, 0x1C00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1C00018
	ld xde, (xsp + 12)
	call SetDialDown
	lds wa, 1
	jrl ParaLoadOpt_SetDialAndReturn
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1E00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, ParaLoadOpt_GridDelegateProc_B
	ld xwa, xiz
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	ld wa, hl
	add wa, wa
	lda_24 xbc, 0xe7fe80
	ld_sriw3 WA, 0x07, 0xE4, 0xE0
	add wa, hl
	ld de, wa
	extz xde
	add xde, 0xFFFF0000
	ld xwa, xiz
	ld xbc, 0x1C0000E
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl AccFunc_ReturnZeroJmp

ParaLoadOpt_GridDelegateProc_B:
	ld xwa, xiz
	ld xbc, 0x1E00091
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
	ld xbc, 0x1C00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1C00018
	ld xde, (xsp + 12)
	call SetDialDown
	lds wa, 1

ParaLoadOpt_SetDialAndReturn:
	call SetDialEnable
	jr AccFunc_ReturnZeroJmp

; ParaLoadOpt grid check case 0
ParaLoadOpt_GridCheck0:
	ld xwa, xiz
	ld xiz, 0x3E
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
	ld xiy, 0xE7FF02
	lda xix, (xsp + 28)
	ldw bc, 0x8
	ldirw
	ld xiy, 0xE7ED44
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
	cp xde, 0x1E0008D
	jrl z, VoiceUI_MiscHandler
	ld xde, (xsp + 16)
	sub xde, 0x1C00017
	cp xde, 0x0
	jrl lt, ParaLoadOpt_ReturnZero
	cp xde, 0x6
	jrl gt, ParaLoadOpt_ReturnZero
	add xde, xde
	add xde, 0xE7FF12
	ld de, (xde)
	lda_24 xix, 0xf76fe2
	jp_dri 8, 0x07, 0xF0, 0xE8
; ParaLoadOptGridCheck dispatch
ParaLoadOpt_GridDispatch:
	.byte 0x1d, 0xd0, 0x44, 0xfa, 0xeb, 0x88, 0x41, 0x8f
	.byte 0x00, 0xe0, 0x01, 0xea, 0xa8, 0x1d, 0x60, 0x96
	.byte 0xfa, 0xbf, 0x14, 0x30, 0xeb, 0x89, 0xe9, 0xef
	.byte 0x00, 0xd7, 0xe6, 0xa8, 0xb0, 0x51, 0xb8, 0x02
	.byte 0x53, 0x90, 0x3f, 0x01, 0x00, 0x7e, 0x21, 0x03
	.byte 0xdb, 0xcf, 0x08, 0x00, 0x66, 0x6a, 0xdb, 0xdf
	.byte 0x66, 0x47, 0xdb, 0xdb, 0x66, 0x24, 0xdb, 0xda
	.byte 0x7e, 0x0e, 0x03, 0x45, 0xa0, 0xfe, 0xe7, 0x00
	.byte 0xbf, 0x2c, 0x34, 0x31, 0x0b, 0x00, 0x95, 0x11
	.byte 0xbf, 0x2c, 0x30, 0xf2, 0xf6, 0x40, 0x03, 0x31
	.byte 0xb0, 0x61, 0xe9, 0xa9, 0xb8, 0x06, 0x61, 0x78
	.byte 0x2f, 0x01, 0x45, 0xa0, 0xfe, 0xe7, 0x00, 0xbf
	.byte 0x2c, 0x34, 0x31, 0x0b, 0x00, 0x95, 0x11, 0xbf
	.byte 0x2c, 0x30, 0xf2, 0xf7, 0x40, 0x03, 0x31, 0xb0
	.byte 0x61, 0xe9, 0xa9, 0xb8, 0x06, 0x61, 0x78, 0x10
	.byte 0x01, 0x45, 0xa0, 0xfe, 0xe7, 0x00, 0xbf, 0x2c
	.byte 0x34, 0x31, 0x0b, 0x00, 0x95, 0x11, 0xbf, 0x2c
	.byte 0x30, 0xf2, 0xf8, 0x40, 0x03, 0x31, 0xb0, 0x61
	.byte 0xe9, 0xab, 0xb8, 0x06, 0x61, 0x78, 0xf1, 0x00
	.byte 0x45, 0xa0, 0xfe, 0xe7, 0x00, 0xbf, 0x2c, 0x34
	.byte 0x31, 0x0b, 0x00, 0x95, 0x11, 0xbf, 0x2c, 0x30
	.byte 0xf2, 0xf9, 0x40, 0x03, 0x31, 0xb0, 0x61, 0xe9
	.byte 0xab, 0xb8, 0x06, 0x61, 0x78, 0xd2, 0x00, 0x1d
	.byte 0xd0, 0x44, 0xfa, 0xeb, 0x88, 0x41, 0x8f, 0x00
	.byte 0xe0, 0x01, 0xea, 0xa8, 0x1d, 0x60, 0x96, 0xfa
	.byte 0xbf, 0x14, 0x30, 0xeb, 0x89, 0xe9, 0xef, 0x00
	.byte 0xd7, 0xe6, 0xa8, 0xb0, 0x51, 0xb8, 0x02, 0x53
	.byte 0x90, 0x3f, 0x01, 0x00, 0x7e, 0x6a, 0x02, 0xdb
	.byte 0xcf, 0x08, 0x00, 0x76, 0x7f, 0x00, 0xdb, 0xdf
	.byte 0x66, 0x55, 0xdb, 0xdb, 0x66, 0x2b, 0xdb, 0xda
	.byte 0x7e, 0x56, 0x02, 0x45, 0xa0, 0xfe, 0xe7, 0x00
	.byte 0xbf, 0x2c, 0x34, 0x31, 0x0b, 0x00, 0x95, 0x11
	.byte 0xbf, 0x2c, 0x30, 0xf2, 0xf6, 0x40, 0x03, 0x31
	.byte 0xb0, 0x61, 0xe9, 0xa9, 0xb8, 0x06, 0x61, 0x41
	.byte 0xff, 0xff, 0xff, 0xff, 0xb8, 0x0e, 0x61, 0x68
	.byte 0x70, 0x45, 0xa0, 0xfe, 0xe7, 0x00, 0xbf, 0x2c
	.byte 0x34, 0x31, 0x0b, 0x00, 0x95, 0x11, 0xbf, 0x2c
	.byte 0x30, 0xf2, 0xf7, 0x40, 0x03, 0x31, 0xb0, 0x61
	.byte 0xe9, 0xa9, 0xb8, 0x06, 0x61, 0x41, 0xff, 0xff
	.byte 0xff, 0xff, 0xb8, 0x0e
	.ascii "ahJE"
	.long UserMemory_ConfirmData
	.byte 0xbf, 0x2c, 0x34, 0x31
	.byte 0x0b, 0x00, 0x95, 0x11, 0xbf, 0x2c, 0x30, 0xf2
	.byte 0xf8, 0x40, 0x03, 0x31, 0xb0, 0x61, 0xe9, 0xab
	.byte 0xb8, 0x06, 0x61, 0x41, 0xff, 0xff, 0xff, 0xff
	.byte 0xb8, 0x0e
	.ascii "ah$E"
	cp	(xwa), xiz
	.byte 0xe7, 0x00, 0xbf, 0x2c, 0x34, 0x31, 0x0b, 0x00
	.byte 0x95, 0x11, 0xbf, 0x2c, 0x30, 0xf2, 0xf9, 0x40
	.byte 0x03, 0x31, 0xb0, 0x61, 0xe9, 0xab, 0xb8, 0x06
	.byte 0x61, 0x41, 0xff, 0xff, 0xff, 0xff, 0xb8, 0x0e
	.byte 0x61, 0x1d, 0x8a, 0xfe, 0xf9, 0x78, 0xb9, 0x01
	.byte 0xeb, 0x8c, 0xb5, 0x02, 0x01, 0x00, 0xbf, 0x10
	.byte 0x61, 0xaf, 0x0c, 0x22, 0xb2, 0x61, 0xee, 0x89
	.byte 0xbb, 0x0e, 0x32, 0xa3, 0xf6, 0x6e, 0x2c, 0xb0
	.byte 0x02, 0x02, 0x00, 0xa2, 0x20, 0xe8, 0xee, 0x02
	.byte 0xaf, 0x08, 0x21, 0xe8, 0x81, 0xa1, 0x20, 0x38
	.byte 0xaf, 0x14, 0x20, 0x38, 0x1d, 0x4d, 0x0f, 0xff
	.byte 0xef, 0x60, 0x1d, 0xd0, 0x44, 0xfa, 0xeb, 0x88
	.byte 0xbf, 0x14, 0x32, 0x41, 0x8c, 0x00, 0xe0, 0x01
	.byte 0x78, 0x72, 0x01, 0xb9, 0x01, 0x33, 0xa4, 0xf3
	.byte 0x6e, 0x2c, 0xb0, 0x02, 0x03, 0x00, 0xa2, 0x20
	.byte 0xe8, 0xee, 0x02, 0xaf, 0x08, 0x21, 0xe8, 0x81
	.byte 0xa1, 0x20, 0x38, 0xaf, 0x14, 0x20, 0x38, 0x1d
	.byte 0x4d, 0x0f, 0xff, 0xef, 0x60, 0x1d, 0xd0, 0x44
	.byte 0xfa, 0xeb, 0x88, 0xbf, 0x14, 0x32, 0x41, 0x8c
	.byte 0x00, 0xe0, 0x01, 0x78, 0x3f, 0x01, 0xb9, 0x02
	.byte 0x33, 0xa4, 0xf3, 0x6e, 0x2c, 0xb0, 0x02, 0x07
	.byte 0x00, 0xa2, 0x20, 0xe8, 0xee, 0x02, 0xaf, 0x04
	.byte 0x21, 0xe8, 0x81, 0xa1, 0x20, 0x38, 0xaf, 0x14
	.byte 0x20, 0x38, 0x1d, 0x4d, 0x0f, 0xff, 0xef, 0x60
	.byte 0x1d, 0xd0, 0x44, 0xfa, 0xeb, 0x88, 0xbf, 0x14
	.byte 0x32, 0x41, 0x8c, 0x00, 0xe0, 0x01, 0x78, 0x0c
	.byte 0x01, 0xe9, 0x63, 0xa4, 0xf1, 0x7e, 0x09, 0x01
	.byte 0xb0, 0x02, 0x08, 0x00, 0xa2, 0x20, 0xe8, 0xee
	.byte 0x02, 0xaf, 0x04, 0x21, 0xe8, 0x81, 0xa1, 0x20
	.byte 0x38, 0xaf, 0x14, 0x20, 0x38, 0x1d, 0x4d, 0x0f
	.byte 0xff, 0xef, 0x60, 0x1d, 0xd0, 0x44, 0xfa, 0xeb
	.byte 0x88, 0xbf, 0x14, 0x32, 0x41, 0x8c, 0x00, 0xe0
	.byte 0x01, 0x78, 0xd9, 0x00

; Voice UI misc handler
VoiceUI_MiscHandler:
	ld xde, xhl
	srl xde, 0
	ldi_werp 0xEA, 0
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
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	push xwa
	ld xwa, (xsp + 20)
	push xwa

; --- UI Control Panel, Sound Navigation & Voice Control ---
