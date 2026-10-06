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
	ld	xbc, EVT_SHOW
	ld	xde, 0:i3
	call	ApPostEvent
ParaLoadOpt_CaseA:
	ld a, (0x02475c:24)
	cp a, (xsp + 2)
	jr z, ParaLoadOpt_CaseB
	ld a, (xsp + 2)
	ld (0x02475c:24), a
	ld xwa, 0x570010
	ld xbc, EVT_REFRESH_PARA_DRAW
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
	ld xbc, EVT_REFRESH_PARA_DRAW
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
	lda xix, (ParaLoadOpt_AudioFlagCheck_CaseTable:24)
	ld	wa, (xix+wa)
	lda xix, (ParaLoadOpt_DispatchTable_A:24)
	jp	t, (xix+wa)

ParaLoadOpt_DispatchTable_A:
	ld	(0x024760:24), 0
	ld	(0x024762:24), 0
	ld	(0x024764:24), 0
	ld	(0x024766:24), 0
	ld	(0x024768:24), 0
	ld	xwa, 0x57000a
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	jrl	ParaLoadOpt_DispatchTable_A_Join
ParaLoadOpt_AudioFlagCheck_Case1:
	ld	(0x024760:24), 1
	ld	xwa, 0x57000a
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	jrl	ParaLoadOpt_DispatchTable_A_Join
ParaLoadOpt_AudioFlagCheck_Case2:
	ld	(0x024760:24), 3
	ld	xwa, 0x57000a
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	jrl	ParaLoadOpt_DispatchTable_A_Join
ParaLoadOpt_AudioFlagCheck_Case3:
	ld	(0x024762:24), 1
	ld	xwa, 0x57000a
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	jrl	ParaLoadOpt_DispatchTable_A_Join
ParaLoadOpt_AudioFlagCheck_Case4:
	ld	(0x024762:24), 3
	ld	xwa, 0x57000a
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	jr	ParaLoadOpt_DispatchTable_A_Join
ParaLoadOpt_AudioFlagCheck_Case5:
	ld	(0x024764:24), 1
	ld	xwa, 0x57000a
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	jr	ParaLoadOpt_DispatchTable_A_Join
ParaLoadOpt_AudioFlagCheck_Case6:
	ld	(0x024764:24), 3
	ld	xwa, 0x57000a
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	jr	ParaLoadOpt_DispatchTable_A_Join
ParaLoadOpt_AudioFlagCheck_Case7:
	ld	(0x024766:24), 1
	ld	xwa, 0x57000a
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	jr	ParaLoadOpt_DispatchTable_A_Join
ParaLoadOpt_AudioFlagCheck_Case8:
	ld	(0x024766:24), 3
	ld	xwa, 0x57000a
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	jr	ParaLoadOpt_DispatchTable_A_Join
ParaLoadOpt_AudioFlagCheck_Case11:
	ld	(0x024768:24), 1
	ld	xwa, 0x57000a
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	jr	ParaLoadOpt_DispatchTable_A_Join
ParaLoadOpt_AudioFlagCheck_Case12:
	ld	(0x024768:24), 3
	ld	xwa, 0x57000a
	ld	xbc, EVT_PAINT
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
	ld	xbc, EVT_SHOW
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
	ld	xbc, EVT_REFRESH_PARA_DRAW
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
	ld	xbc, EVT_REFRESH_PARA_DRAW
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
	lda	xix, (ParaLoadOpt_AudioFlagCheck_B_CaseTable:24)
	ld	wa, (xix+wa)
	lda	xix, (ParaLoadOpt_DispatchTable_B:24)
	jp	t, (xix+wa)
ParaLoadOpt_DispatchTable_B:
	ld	(0x024760:24), 0
	ld	(0x024762:24), 0
	ld	(0x024764:24), 0
	ld	(0x024766:24), 0
	ld	(0x024768:24), 0
	ld	xwa, 0x570015
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	jrl	ParaLoadOpt_DispatchTable_B_Join
ParaLoadOpt_AudioFlagCheck_B_Case1:
	ld	(0x024760:24), 2
	ld	xwa, 0x570015
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	jrl	ParaLoadOpt_DispatchTable_B_Join
ParaLoadOpt_AudioFlagCheck_B_Case2:
	ld	(0x024760:24), 3
	ld	xwa, 0x570015
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	jrl	ParaLoadOpt_DispatchTable_B_Join
ParaLoadOpt_AudioFlagCheck_B_Case3:
	ld	(0x024762:24), 2
	ld	xwa, 0x570015
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	jrl	ParaLoadOpt_DispatchTable_B_Join
ParaLoadOpt_AudioFlagCheck_B_Case4:
	ld	(0x024762:24), 3
	ld	xwa, 0x570015
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	jr	ParaLoadOpt_DispatchTable_B_Join
ParaLoadOpt_AudioFlagCheck_B_Case5:
	ld	(0x024764:24), 2
	ld	xwa, 0x570015
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	jr	ParaLoadOpt_DispatchTable_B_Join
ParaLoadOpt_AudioFlagCheck_B_Case6:
	ld	(0x024764:24), 3
	ld	xwa, 0x570015
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	jr	ParaLoadOpt_DispatchTable_B_Join
ParaLoadOpt_AudioFlagCheck_B_Case7:
	ld	(0x024766:24), 2
	ld	xwa, 0x570015
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	jr	ParaLoadOpt_DispatchTable_B_Join
ParaLoadOpt_AudioFlagCheck_B_Case8:
	ld	(0x024766:24), 3
	ld	xwa, 0x570015
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	jr	ParaLoadOpt_DispatchTable_B_Join
ParaLoadOpt_AudioFlagCheck_B_Case11:
	ld	(0x024768:24), 2
	ld	xwa, 0x570015
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	jr	ParaLoadOpt_DispatchTable_B_Join
ParaLoadOpt_AudioFlagCheck_B_Case12:
	ld	(0x024768:24), 3
	ld	xwa, 0x570015
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
ParaLoadOpt_DispatchTable_B_Join:
	call	ApPostEvent

MidiFunc_SendEventReturn:
	inc 6, xsp
	ret

ParaLoadOpt_PostDualEvent:
	ld	xwa, 0x570006
	ld	xbc, EVT_HIDE
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, 0x570011
	ld	xbc, EVT_HIDE
	ld	xde, 0:i3
	jp	ApPostEvent

TtMdParaLoad:
	cp xbc, EVT_REPAINT
	jr z, TtMdParaLoad_ReturnZero
	cp xbc, EVT_PAINT
	jr z, TtMdParaLoad_ReturnZero
	cp xbc, EVT_HIDE
	jr z, TtMdParaLoad_ReturnZero
	cp xbc, EVT_SHOW
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
	cp xbc, EVT_REQUEST_GRID_DRAW
	jrl z, ParaLoadOpt_GridCheck2
	ld xwa, (xsp + 16)
	cp xwa, EVT_GET_FIXED_ROW_STR
	jrl z, ParaLoadOpt_GridCheck1
	cp xwa, EVT_GET_FIXED_COL_STR
	jrl z, ParaLoadOpt_GridCheck0
	cp xwa, EVT_HIDE
	jrl z, ParaLoadOpt_GridReturn
	cp xwa, EVT_SHOW
	jr z, ParaLoadOpt_GridHandler
	sub xbc, EVT_INDEXSW_UP
	cp xbc, 0x0
	jrl lt, ParaLoadOpt_GridCheck3
	cp xbc, 0x6
	jrl gt, ParaLoadOpt_GridCheck3
	add xbc, xbc
	add xbc, AcParaLoadOptGridBoxProc_CaseTable
	ld bc, (xbc)
	lda xix, (ParaLoadOpt_GridHandler:24)
	jp	t, (xix+bc)

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
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld (xsp + 4), xhl
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 16
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, EVT_INDEXSW_UP
	call SetDialUp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 16
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, EVT_INDEXSW_DOWN
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
	ld XBC,EVT_SET_NOT_DRAW_FLAG
	ld xde, 1:i3
	call SendEvent
	ld XWA,0xffffffff
	ld XBC,EVT_SET_NOT_DRAW_FLAG
	ld xde, 0:i3
	call PostEvent
	ld (GLOBAL_ERROR_CODE:16), 0x48
	ld XWA,0xffffffff
	ld XBC,EVT_INTERRUPT_TITLE
	ld XDE,TITLE_MESAGE
	call PostEvent
	ld XWA,NAKA_MAINFUNC_MainFlashFunc
	ld XBC,EVT_EAST_FLASH_LOAD
	ld XDE,(XSP+0x0c)
	call MainFuncCall
	jrl t, AccFunc_ReturnZeroJmp
AcParaLoadOptGridBoxProc_OnIndexswUp:	; cases 29360151, 29360153
	ld XWA,XIZ
	ld XBC,(XSP+0x10)
	ld XDE,(XSP+0x0c)
	call InheritedProc
	ld XWA,XIZ
	ld XBC,EVT_CHECK_INDEX
	ld XDE,(XSP+0x0c)
	call SendEvent
	or XHL,XHL
	jr z, ParaLoadOpt_GridDelegateProc
	ld XWA,XIZ
	ld XBC,EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld WA,HL
	add WA,WA
	lda xbc, (ParaLoadOpt_GridReturn_Table:24)
	ld	wa, (xbc+wa)
	sub HL,WA
	extz XHL
	add XHL,0xffff0000
	ld XWA,XIZ
	ld XBC,EVT_SELE_DRAW
	ld XDE,XHL
	call SendEvent
	ld XWA,XIZ
	ld XBC,(XSP+0x10)
	ld XDE,(XSP+0x0c)
	call SetAutoInc
	jrl t, AccFunc_ReturnZeroJmp
ParaLoadOpt_GridDelegateProc:
	ld xwa, xiz
	ld xbc, EVT_CHECK_GRID_INDEX
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
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 12)
	call SetDialDown
	ld wa, 1:i3
	jrl ParaLoadOpt_SetDialAndReturn
AcParaLoadOptGridBoxProc_OnIndexswDown:	; cases 29360152, 29360154
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_CHECK_INDEX
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, ParaLoadOpt_GridDelegateProc_B
	ld xwa, xiz
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld wa, hl
	add wa, wa
	lda xbc, (ParaLoadOpt_GridDelegateProc_Table:24)
	ld	wa, (xbc+wa)
	add wa, hl
	ld de, wa
	extz xde
	add xde, 0xffff0000
	ld xwa, xiz
	ld xbc, EVT_SELE_DRAW
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl AccFunc_ReturnZeroJmp

ParaLoadOpt_GridDelegateProc_B:
	ld xwa, xiz
	ld xbc, EVT_CHECK_GRID_INDEX
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
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, EVT_INDEXSW_DOWN
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
AcParaLoadOptGridBoxProc_OnLswData:	; cases 29360156, 29360157
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
	ld xiy, ParaLoadOptGridCheck_LocalInit
	lda xix, (xsp + 28)
	ldw bc, 0x8
	ldirw
	ld xiy, ComSetGridCheck_LocalInit
	lda xix, (xsp + 20)
	ld bc, 4:i3
	ldirw
	ld (xsp + 16), xde
	lda xwa, (UserMemory_Config_Table:24)
	ld (xsp + 4), xwa
	lda xbc, (xsp + 28)
	lda xiy, (xsp + 20)
	lda xwa, (ParaLoadOptGridCheck_PtrTable:24)
	ld (xsp + 8), xwa
	lda xiz, (0x0340f6:24)
	lda xwa, (xiy + 2)
	lda xix, (xiy + 4)
	ld (xsp + 12), xix
	cp xde, EVT_REQUEST_GRID_DRAW
	jrl z, VoiceUI_MiscHandler
	ld xde, (xsp + 16)
	sub xde, EVT_INDEXSW_UP
	cp xde, 0x0
	jrl lt, ParaLoadOpt_ReturnZero
	cp xde, 0x6
	jrl gt, ParaLoadOpt_ReturnZero
	add xde, xde
	add xde, ParaLoadOptGridCheck_CaseTable
	ld de, (xde)
	lda xix, (ParaLoadOpt_GridDispatch:24)
	jp	t, (xix+de)
ParaLoadOpt_GridDispatch:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	lda	xwa, (xsp+20)
	ld	xbc, xhl
	srl	xbc, 16
	ld	qbc, 0
	ld	(xwa), bc
	ld	(xwa+2), hl
	cpw	(xwa), 1
	jrl	nz, ParaLoadOpt_ReturnZero
	cp	hl, 8
	jr	z, ParaLoadOpt_GridDispatch_Skip3
	cp	hl, 7:i3
	jr	z, ParaLoadOpt_GridDispatch_Skip2
	cp	hl, 3:i3
	jr	z, ParaLoadOpt_GridDispatch_Skip
	cp	hl, 2:i3
	jrl	nz, ParaLoadOpt_ReturnZero
	ld	xiy, UserMemory_ConfirmData
	lda	xix, (xsp+44)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+44)
	lda	xbc, (0x340f6:24)
	ld	(xwa), xbc
	ld	xbc, 1:i3
	ld	(xwa+6), xbc
	jrl	ParaLoadOpt_GridDispatch_Join
ParaLoadOpt_GridDispatch_Skip:
	ld	xiy, UserMemory_ConfirmData
	lda	xix, (xsp+44)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+44)
	lda	xbc, (0x340f7:24)
	ld	(xwa), xbc
	ld	xbc, 1:i3
	ld	(xwa+6), xbc
	jrl	ParaLoadOpt_GridDispatch_Join
ParaLoadOpt_GridDispatch_Skip2:
	ld	xiy, UserMemory_ConfirmData
	lda	xix, (xsp+44)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+44)
	lda	xbc, (0x340f8:24)
	ld	(xwa), xbc
	ld	xbc, 3:i3
	ld	(xwa+6), xbc
	jrl	ParaLoadOpt_GridDispatch_Join
ParaLoadOpt_GridDispatch_Skip3:
	ld	xiy, UserMemory_ConfirmData
	lda	xix, (xsp+44)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+44)
	lda	xbc, (0x340f9:24)
	ld	(xwa), xbc
	ld	xbc, 3:i3
	ld	(xwa+6), xbc
	jrl	ParaLoadOpt_GridDispatch_Join
ParaLoadOptGridCheck_OnIndexswDown:	; cases 29360152, 29360154
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	lda	xwa, (xsp+20)
	ld	xbc, xhl
	srl	xbc, 16
	ld	qbc, 0
	ld	(xwa), bc
	ld	(xwa+2), hl
	cpw	(xwa), 1
	jrl	nz, ParaLoadOpt_ReturnZero
	cp	hl, 8
	jrl	z, ParaLoadOpt_GridDispatch_Skip6
	cp	hl, 7:i3
	jr	z, ParaLoadOpt_GridDispatch_Skip5
	cp	hl, 3:i3
	jr	z, ParaLoadOpt_GridDispatch_Skip4
	cp	hl, 2:i3
	jrl	nz, ParaLoadOpt_ReturnZero
	ld	xiy, UserMemory_ConfirmData
	lda	xix, (xsp+44)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+44)
	lda	xbc, (0x340f6:24)
	ld	(xwa), xbc
	ld	xbc, 1:i3
	ld	(xwa+6), xbc
	ld	xbc, 0xffffffff
	ld	(xwa+14), xbc
	jr	ParaLoadOpt_GridDispatch_Join
ParaLoadOpt_GridDispatch_Skip4:
	ld	xiy, UserMemory_ConfirmData
	lda	xix, (xsp+44)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+44)
	lda	xbc, (0x340f7:24)
	ld	(xwa), xbc
	ld	xbc, 1:i3
	ld	(xwa+6), xbc
	ld	xbc, 0xffffffff
	ld	(xwa+14), xbc
	jr	ParaLoadOpt_GridDispatch_Join
ParaLoadOpt_GridDispatch_Skip5:
	ld	xiy, UserMemory_ConfirmData
	lda	xix, (xsp+44)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+44)
	lda	xbc, (0x340f8:24)
	ld	(xwa), xbc
	ld	xbc, 3:i3
	ld	(xwa+6), xbc
	ld	xbc, 0xffffffff
	ld	(xwa+14), xbc
	jr	ParaLoadOpt_GridDispatch_Join
ParaLoadOpt_GridDispatch_Skip6:
	ld	xiy, UserMemory_ConfirmData
	lda	xix, (xsp+44)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+44)
	lda	xbc, (0x340f9:24)
	ld	(xwa), xbc
	ld	xbc, 3:i3
	ld	(xwa+6), xbc
	ld	xbc, 0xffffffff
	ld	(xwa+14), xbc
ParaLoadOpt_GridDispatch_Join:
	call	MainRamAdd
	jrl	ParaLoadOpt_ReturnZero
ParaLoadOptGridCheck_OnRamData:
	ld	xix, xhl
	ldw	(xiy), 1
	ld	(xsp+16), xbc
	ld	xde, (xsp+12)
	ld	(xde), xbc
	ld	xbc, xiz
	lda	xde, (xhl+14)
	cp	xiz, (xhl)
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
	ld	xbc, EVT_GRID_DRAW
	jrl	ParaLoadOptSendEvtReturn
ParaLoadOpt_GridDispatch_Skip7:
	lda	xhl, (xbc+1)
	cp	xhl, (xix)
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
	ld	xbc, EVT_GRID_DRAW
	jrl	ParaLoadOptSendEvtReturn
ParaLoadOpt_GridDispatch_Skip8:
	lda	xhl, (xbc+2)
	cp	xhl, (xix)
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
	ld	xbc, EVT_GRID_DRAW
	jrl	ParaLoadOptSendEvtReturn
ParaLoadOpt_GridDispatch_Skip9:
	inc	3, xbc
	cp	xbc, (xix)
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
	ld	xbc, EVT_GRID_DRAW
	jrl	ParaLoadOptSendEvtReturn
VoiceUI_MiscHandler:
	ld xde, xhl
	srl xde, 16
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
	ld	xwa, (xbc+wa)
	push xwa
	ld xwa, (xsp + 20)
	push xwa

; --- UI Control Panel, Sound Navigation & Voice Control ---
