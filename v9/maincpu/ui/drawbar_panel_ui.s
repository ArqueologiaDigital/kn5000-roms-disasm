; =============================================================================
; Drawbar & Panel UI (15K lines)
; =============================================================================
;
; Drawbar organ slider UI, DSP effect controls, the presentation
; system, and the demo menu. Handles the real-time parameter
; display for the drawbar interface.
; =============================================================================



AcSendEditSwProc:
	lda xsp, (xsp - 22)
	push xiz
	ld (xsp + 14), xde
	ld (xsp + 18), xbc
	ld (xsp + 22), xwa
	ld xiy, 0xe8000c
	lda xix, (xsp + 4)
	lds bc, 5
	ldirw
	ld xwa, (xsp + 18)
	cp xwa, 0x1c00009
	jrl z, AcSendEditSw_Event9
	cp xwa, 0x1c00008
	jr z, AcSendEditSw_Event8
	cp xwa, 0x1c0000d
	jr z, AcSendEditSw_EventD
	ld xwa, (xsp + 22)
	ld xbc, (xsp + 18)
	ld xde, (xsp + 14)
	jrl AcSendEditSw_CallInherited

AcSendEditSw_EventD:
	ld xwa, (xsp + 22)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 48)
	ld wa, (xwa)
	ld (xiz + 24), wa
	ld xwa, (xsp + 22)
	ld xbc, (xsp + 18)
	ld xde, (xsp + 14)
	call InheritedProc
	ld xwa, (xiz + 44)
	push xwa
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	ld xbc, (xiz + 48)
	lda xde, (xsp + 4)
	lda_24 xwa, 0xe7fffc
	cpw (xbc), 0xc1
	jr nz, AcSendEditSw_DrawAlt
	lds32 xbc, 0
	push xbc
	pushw 0x0
	pushw 0xf7
	ld xbc, 0xe80008
	jr AcSendEditSw_DrawString

AcSendEditSw_DrawAlt:
	lds32 xbc, 0
	push xbc
	pushw 0x0
	pushw 0xf7
	ld xbc, 0xe80004

AcSendEditSw_DrawString:
	call DrawStringCentered
	jrl AcSendEditSw_ReturnZero

AcSendEditSw_Event8:
	ld xwa, (xsp + 22)
	ld xbc, (xsp + 18)
	ld xde, (xsp + 14)
	call InheritedProc
	ld xwa, (xsp + 22)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 14)
	cp xwa, 0xb
	jr nz, AcSendEditSw_FwdInherited
	ld xwa, (xiz + 40)
	ld xbc, (xsp + 18)
	ld xde, (xsp + 14)
	call ApFuncCall
	ld xwa, (xiz + 48)
	ldw (xwa), 0xc3
	ld xwa, (xsp + 22)
	ld xbc, 0x1c0000d
	lds32 xde, 0
	jr AcSendEditSw_SendEvent

AcSendEditSw_FwdInherited:
	ld xwa, (xsp + 22)
	ld xbc, (xsp + 18)
	ld xde, (xsp + 14)
	jr AcSendEditSw_CallInherited

AcSendEditSw_Event9:
	ld xwa, (xsp + 22)
	ld xbc, (xsp + 18)
	ld xde, (xsp + 14)
	call InheritedProc
	ld xwa, (xsp + 22)
	call GetViewInstance
	ld xwa, (xsp + 14)
	cp xwa, 0xb
	jr nz, AcSendEditSw_FwdInherited2
	ld xwa, (xhl + 48)
	ldw (xwa), 0xc1
	ld xwa, (xsp + 22)
	ld xbc, 0x1c0000d
	lds32 xde, 0

AcSendEditSw_SendEvent:
	call SendEvent

AcSendEditSw_ReturnZero:
	lds32 xhl, 0
	jr AcSendEditSw_Epilogue

AcSendEditSw_FwdInherited2:
	ld xwa, (xsp + 22)
	ld xbc, (xsp + 18)
	ld xde, (xsp + 14)

AcSendEditSw_CallInherited:
	call InheritedProc

AcSendEditSw_Epilogue:
	pop xiz
	lda xsp, (xsp + 22)
	ret

TtComSet:
	cp xbc, 0x1c0000c
	jr z, TtComSet_ReturnZero
	cp xbc, 0x1c0000b
	jr z, TtComSet_ReturnZero
	cp xbc, 0x1c00002
	jr z, TtComSet_ReturnZero
	cp xbc, 0x1c00001
	jr nz, TtComSet_ReturnZero
	or xde, xde
	jr nz, TtComSet_ReturnZero
	ld xwa, 0x540001
	call GetViewInstance
	ld xwa, (xhl + 42)
	ldw (xwa), 0x0
	ld xwa, (xhl + 46)
	ldw (xwa), 0x1

TtComSet_ReturnZero:
	lds32 xhl, 0
	ret

ComSetGridCheck:
	lda xsp, (xsp - 22)
	push xiz
	ld (xsp + 22), xde
	ld xde, xbc
	ld xiy, 0xe8003a
	lda xix, (xsp + 12)
	lds bc, 5
	ldirw
	ld xiy, 0xe7ed44
	lda xix, (xsp + 4)
	lds bc, 4
	ldirw
	ld xwa, xde
	cp xde, 0x1e0008d
	jrl z, ComSetGrid_EventHandler
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, UI_ReturnZero
	cp xwa, 0x6
	jrl gt, UI_ReturnZero
	add xwa, xwa
	add xwa, 0xe800c0
	ld wa, (xwa)
	lda_24 xix, ComSetGridCheck_JumpTable
	jp_dri 8, 0x07, 0xf0, 0xe0

ComSetGridCheck_JumpTable:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 31457423
	lds32	xde, 0
	call	SendEvent
	ld	(xsp+22), xhl
	lda	xbc, (xsp+4)
	ld	xwa, (xsp+22)
	srl	xwa, 0
	ld	qwa, 0
	ld	(xbc), wa
	ld	xwa, (xsp+22)
	ld	(xbc+2), wa
	cpw	(xbc), 1
	jrl	nz, 737
	ld	xwa, 192
	call	SndParam_LookupReadOnly
	cps	hl, 1
	jr	nz, 34
	ld	wa, (xsp+6)
	sla	wa, 2
	lda_24	xbc, 15204374
	ld_rrl	xwa, xbc, wa
	cp	xwa, 8705
	jrl	z, 699
	cp	xwa, 8709
	jrl	z, 690
	ld	bc, (xsp+6)
	sla	bc, 2
	lda_24	xwa, 15204374
	ld_rrl	xwa, xwa, bc
	lds	bc, 1
	lds	de, 2
	jr	115
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 31457423
	lds32	xde, 0
	call	SendEvent
	ld	(xsp+22), xhl
	lda	xbc, (xsp+4)
	ld	xwa, (xsp+22)
	srl	xwa, 0
	ld	qwa, 0
	ld	(xbc), wa
	ld	xwa, (xsp+22)
	ld	(xbc+2), wa
	cpw	(xbc), 1
	jrl	nz, 621
	ld	xwa, 192
	call	SndParam_LookupReadOnly
	cps	hl, 1
	jr	nz, 34
	ld	wa, (xsp+6)
	sla	wa, 2
	lda_24	xbc, 15204374
	ld_rrl	xwa, xbc, wa
	cp	xwa, 8705
	jrl	z, 583
	cp	xwa, 8709
	jrl	z, 574
	ld	bc, (xsp+6)
	sla	bc, 2
	lda_24	xwa, 15204374
	ld_rrl	xwa, xwa, bc
	ldw	bc, 65535
	lds	de, 2
	call	MainLswAdd
	jrl	546
	lda	xhl, (xsp+4)
	ldw	(xhl), 1
	lda	xde, (xhl+2)
	ldw	(xde), 0
	lda_24	xix, 15204374
	ld	xiz, (xsp+22)
	jr	18
	ld	iy, bc
	sla	iy, 2
	ld	xwa, (xiz)
	.byte 0xe3, 0x07, 0xf0, 0xf4, 0xf0
	jr	z, 12
	inc	1, bc
	ld	(xde), bc
	ld	bc, (xde)
	cp	bc, 9
	jr	lt, -26
	lda	xde, (xsp+12)
	ld	(xhl+4), xde
	ld	xwa, (xsp+22)
	ld	xwa, (xwa)
	cp	xwa, 8709
	jr	z, 110
	cp	xwa, 8705
	jr	z, 102
	cp	xwa, 8832
	jr	z, 49
	cp	xwa, 8858
	jr	z, 41
	cp	xwa, 172032
	jr	z, 33
	cp	xwa, 172033
	jr	z, 25
	cp	xwa, 8834
	jr	z, 17
	cp	xwa, 8706
	jr	z, 9
	cp	xwa, 8707
	jrl	nz, 412
	ld	xbc, 15204426
	ld	xwa, (xsp+22)
	cpw	(xwa+4), 0
	jr	z, 5
	ld	xbc, 15204420
	push	xbc
	push	xde
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	363
	ld	xwa, 192
	call	SndParam_LookupReadOnly
	cps	hl, 1
	jr	nz, 7
	ld	xwa, 15204432
	jr	44
	ld	xwa, (xsp+22)
	ld	wa, (xwa+4)
	cps	wa, 3
	jr	z, 22
	cps	wa, 1
	jr	z, 11
	cps	wa, 0
	jr	nz, 21
	.byte 0x40
	.long NakaInst_NORMAL
	jr	19
	ld	xwa, 15204452
	jr	12
	ld	xwa, 15204462
	jr	5
	ld	xwa, 15204472
	push	xwa
	lda	xwa, (xsp+16)
	push	xwa
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457420
	jrl	271

; ComSetGridCheck event handler dispatch
ComSetGrid_EventHandler:
	lda xde, (xsp + 4)
	ld xwa, (xsp + 22)
	srl xwa, 0
	ldi_werp 0xe2, 0
	ld (xde), wa
	lda xbc, (xde + 2)
	ld xwa, (xsp + 22)
	ld (xbc), wa
	lda xwa, (xsp + 12)
	ld (xde + 4), xwa
	cpw (xde), 0x1
	jrl nz, UI_ReturnZero
	ld wa, (xbc)
	sla wa, 2
	lda_24 xbc, 0xe80016
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	cp xwa, 0x2205
	jr z, ComSetGrid_CheckC0Param
	cp xwa, 0x2201
	jr z, ComSetGrid_CheckC0Param
	cp xwa, 0x2280
	jr z, ComSetGridCheck_ParamDisplay
	cp xwa, 0x229a
	jr z, ComSetGridCheck_ParamDisplay
	cp xwa, 0x2a000
	jr z, ComSetGridCheck_ParamDisplay
	cp xwa, 0x2a001
	jr z, ComSetGridCheck_ParamDisplay
	cp xwa, 0x2282
	jr z, ComSetGridCheck_ParamDisplay
	cp xwa, 0x2202
	jr z, ComSetGridCheck_ParamDisplay
	cp xwa, 0x2203
	jrl nz, UI_ReturnZero

ComSetGridCheck_ParamDisplay:
	call SndParam_LookupReadOnly
	lda xbc, (xsp + 12)
	ld xwa, 0xe80088
	cps hl, 0
	jr z, ComSetGrid_CopyStrAndDispatch
	ld xwa, 0xe80082

ComSetGrid_CopyStrAndDispatch:
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, 0x1e0008c
	jr ComSetGrid_SendEventReturn

ComSetGrid_CheckC0Param:
	ld xwa, 0xc0
	call SndParam_LookupReadOnly
	cps hl, 1
	jr nz, ComSetGrid_LookupByColumn
	ld xwa, 0xe8008e
	jr UI_DisplayStringAndDispatchEvent

ComSetGrid_LookupByColumn:
	ld bc, (xsp + 6)
	sla bc, 2
	lda_24 xwa, 0xe80016
	ld_sril3 XWA, 0x07, 0xe0, 0xe4
	call SndParam_LookupReadOnly
	cps hl, 3
	jr z, ComSetGrid_ParamStr3
	cps hl, 1
	jr z, ComSetGrid_ParamStr1
	cps hl, 0
	jr nz, ComSetGrid_ParamStrDefault
	ld xwa, 0xe80098
	jr UI_DisplayStringAndDispatchEvent

ComSetGrid_ParamStr1:
	ld xwa, 0xe800a2
	jr UI_DisplayStringAndDispatchEvent

ComSetGrid_ParamStr3:
	ld xwa, 0xe800ac
	jr UI_DisplayStringAndDispatchEvent

ComSetGrid_ParamStrDefault:
	ld xwa, 0xe800b6

UI_DisplayStringAndDispatchEvent:
	push xwa
	lda xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, 0x1e0008c

ComSetGrid_SendEventReturn:
	call SendEvent

UI_ReturnZero:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 22)
	ret


; -----------------------------------------------------------------------------
; Section: Accompaniment Parameter Output
; -----------------------------------------------------------------------------
; Left/right parameter output grid boxes, cell
; initialization, scroll, and navigation.
; -----------------------------------------------------------------------------

TtMdPmemOut:
	cp xbc, 0x1c0000c
	jr z, TtMdPmemOut_ReturnZero
	cp xbc, 0x1c0000b
	jr z, TtMdPmemOut_ReturnZero
	cp xbc, 0x1c00002
	jr z, TtMdPmemOut_ReturnZero
	cp xbc, 0x1c00001
	jr nz, TtMdPmemOut_ReturnZero
	or xde, xde
	jr nz, TtMdPmemOut_ReturnZero
	ld xwa, 0x5b0008
	call GetViewInstance
	ld xwa, (xhl + 42)
	ldw (xwa), 0x0
	ld xwa, (xhl + 46)
	ldw (xwa), 0x1
	ld xwa, 0x5b0009
	call GetViewInstance
	ld xwa, (xhl + 42)
	ldw (xwa), 0xffff

TtMdPmemOut_ReturnZero:
	lds32 xhl, 0
	ret

AcPmemOutLGridBoxProc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 8), xde
	ld (xsp + 12), xbc
	ld (xsp + 16), xwa
	ld xbc, (xsp + 12)
	cp xbc, 0x1e0008d
	jrl z, AcPmemOutL_CellSelect
	ld xwa, (xsp + 12)
	cp xwa, 0x1e0008b
	jrl z, AcPmemOutL_GetRowText
	cp xwa, 0x1e0008a
	jrl z, AcPmemOutL_GetColText
	cp xwa, 0x1c00001
	jr z, AcPmemOutL_Init
	sub xbc, 0x1c00017
	cp xbc, 0x0
	jrl lt, AcPmemOutL_ForwardToBase
	cp xbc, 0x6
	jrl gt, AcPmemOutL_ForwardToBase
	add xbc, xbc
	add xbc, 0xe800ce
	ld bc, (xbc)
	lda_24 xix, AcPmemOutL_Init
	jp_dri 8, 0x07, 0xf0, 0xe4

AcPmemOutL_Init:
	ld xwa, (xsp + 16)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld xiz, xhl
	ld wa, iz
	cps wa, 3
	jr z, AcPmemOutL_Init_Cell3
	cps wa, 1
	jr z, AcPmemOutL_Init_Cell01
	cps wa, 0
	jrl nz, AcPmemOutL_Init_ForwardBase

AcPmemOutL_Init_Cell01:
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld wa, (xwa + 26)
	ld de, iz
	add de, wa
	extz xde
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00017
	call SetDialUp
	ld xwa, (xsp + 4)
	ld wa, (xwa + 26)
	ld de, iz
	add de, wa
	extz xde
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00018
	call SetDialDown
	lds wa, 1
	jr AcPmemOutL_Init_ScrollCommit

AcPmemOutL_Init_Cell3:
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld wa, (xwa + 26)
	ld bc, iz
	add bc, wa
	inc 1, bc
	ld de, bc
	extz xde
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00017
	call SetDialUp
	ld xwa, (xsp + 4)
	ld wa, (xwa + 26)
	ld bc, iz
	add bc, wa
	inc 1, bc
	ld de, bc
	extz xde
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00018
	call SetDialDown
	lds wa, 1

AcPmemOutL_Init_ScrollCommit:
	call SetDialEnable

AcPmemOutL_Init_ForwardBase:
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	jrl AcPmemOutL_CallBase
	ld xwa, (xsp + 8)
	cps wa, 3
	jrl z, AcPmemOutL_AutoIncDown_Cell3
	cps wa, 2
	jrl z, AcPmemOutL_AutoIncUp_Cell2
	cps wa, 1
	jrl nz, AcPmemOutL_ReloadAndForward
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00017
	ld xde, (xsp + 8)
	call SetDialUp
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00018
	ld xde, (xsp + 8)
	call SetDialDown
	lds wa, 1
	call SetDialEnable
	ld xwa, (xsp + 16)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld xiz, xhl
	cps iz, 0
	jr z, AcPmemOutL_AutoIncUp_Cell0_FwdParent
	ld xwa, (xsp + 16)
	ld xbc, 0x1e0008e
	ld xde, 0x10000
	call SendEvent
	ld xwa, 0x5b0009
	call GetViewInstance
	lda xwa, (xhl + 42)
	ld xbc, (xwa)
	cpw (xbc), 0xffff
	jrl z, AcPmemOutL_ReloadAndForward
	ld xwa, (xwa)
	ldw (xwa), 0xffff
	ld xwa, 0x5b0009
	ld xbc, 0x1c0000d
	lds32 xde, 0
	jrl AcPmemOutL_DispatchEvent

AcPmemOutL_AutoIncUp_Cell0_FwdParent:
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	jrl AcPmemOutL_ForwardToParent

AcPmemOutL_AutoIncUp_Cell2:
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00017
	ld xde, (xsp + 8)
	call SetDialUp
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00018
	ld xde, (xsp + 8)
	call SetDialDown
	lds wa, 1
	call SetDialEnable
	ld xwa, (xsp + 16)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld xiz, xhl
	cps iz, 1
	jr z, AcPmemOutL_AutoIncUp_Cell2_FwdParent
	ld xwa, (xsp + 16)
	ld xbc, 0x1e0008e
	ld xde, 0x10001
	call SendEvent
	ld xwa, 0x5b0009
	call GetViewInstance
	lda xwa, (xhl + 42)
	ld xbc, (xwa)
	cpw (xbc), 0xffff
	jrl z, AcPmemOutL_ReloadAndForward
	ld xwa, (xwa)
	ldw (xwa), 0xffff
	ld xwa, 0x5b0009
	ld xbc, 0x1c0000d
	lds32 xde, 0
	jrl AcPmemOutL_DispatchEvent

AcPmemOutL_AutoIncUp_Cell2_FwdParent:
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	jrl AcPmemOutL_ForwardToParent

AcPmemOutL_AutoIncDown_Cell3:
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00017
	ld xde, (xsp + 8)
	call SetDialUp
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00018
	ld xde, (xsp + 8)
	call SetDialDown
	lds wa, 1
	call SetDialEnable
	ld xwa, (xsp + 16)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld xiz, xhl
	cps iz, 3
	jr z, AcPmemOutL_AutoIncDown_Cell3_FwdParent
	ld xwa, (xsp + 16)
	ld xbc, 0x1e0008e
	ld xde, 0x10003
	call SendEvent
	ld xwa, 0x5b0009
	call GetViewInstance
	lda xwa, (xhl + 42)
	ld xbc, (xwa)
	cpw (xbc), 0xffff
	jr z, AcPmemOutL_ReloadAndForward
	ld xwa, (xwa)
	ldw (xwa), 0xffff
	ld xwa, 0x5b0009
	ld xbc, 0x1c0000d
	lds32 xde, 0

AcPmemOutL_DispatchEvent:
	call SendEvent
	jr AcPmemOutL_ReloadAndForward

AcPmemOutL_AutoIncDown_Cell3_FwdParent:
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)

AcPmemOutL_ForwardToParent:
	call ApFuncCall

AcPmemOutL_ReloadAndForward:
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)

AcPmemOutL_CallBase:
	call InheritedProc
	jr AcPmemOutL_ReturnHandled

AcPmemOutL_GetColText:
	ld xwa, (xsp + 16)
	ld xiz, 0x3e
	jr AcPmemOutL_CopyText

AcPmemOutL_GetRowText:
	ld xwa, (xsp + 16)
	ld xiz, 0x42

AcPmemOutL_CopyText:
	call GetViewInstance
	add xhl, xiz
	ld xwa, (xhl)
	push xwa
	ld xwa, (xsp + 12)
	push xwa
	call Strcpy
	inc 8, xsp
	jr AcPmemOutL_ReturnHandled
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	jr AcPmemOutL_CellSelect_Forward

AcPmemOutL_CellSelect:
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)

AcPmemOutL_CellSelect_Forward:
	call ApFuncCall

AcPmemOutL_ReturnHandled:
	lds32 xhl, 0
	jr AcPmemOutL_Return

AcPmemOutL_ForwardToBase:
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call InheritedProc

AcPmemOutL_Return:
	pop xiz
	lda xsp, (xsp + 16)
	ret

AcPmemOutRGridBoxProc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 8), xde
	ld (xsp + 12), xbc
	ld (xsp + 16), xwa
	ld xbc, (xsp + 12)
	cp xbc, 0x1e0008d
	jrl z, AcPmemOutR_CellSelect
	ld xwa, (xsp + 12)
	cp xwa, 0x1e0008b
	jrl z, AcPmemOutR_GetRowText
	cp xwa, 0x1e0008a
	jrl z, AcPmemOutR_GetColText
	cp xwa, 0x1c00001
	jr z, AcPmemOutR_Init
	sub xbc, 0x1c00017
	cp xbc, 0x0
	jrl lt, AcPmemOutR_ForwardToBase
	cp xbc, 0x6
	jrl gt, AcPmemOutR_ForwardToBase
	add xbc, xbc
	add xbc, 0xe800dc
	ld bc, (xbc)
	lda_24 xix, AcPmemOutR_Init
	jp_dri 8, 0x07, 0xf0, 0xe4

AcPmemOutR_Init:
	ld xwa, (xsp + 16)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld xiz, xhl
	ld wa, iz
	cps wa, 7
	jr z, AcPmemOutR_Init_Cell567
	cps wa, 6
	jr z, AcPmemOutR_Init_Cell567
	cps wa, 5
	jr nz, AcPmemOutR_Init_ForwardBase

AcPmemOutR_Init_Cell567:
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld wa, (xwa + 26)
	ld de, iz
	add de, wa
	extz xde
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00017
	call SetDialUp
	ld xwa, (xsp + 4)
	ld wa, (xwa + 26)
	ld de, iz
	add de, wa
	extz xde
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00018
	call SetDialDown
	lds wa, 1
	call SetDialEnable

AcPmemOutR_Init_ForwardBase:
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	jrl AcPmemOutR_CallBase
	ld xwa, (xsp + 8)
	cps wa, 7
	jrl z, AcPmemOutR_AutoIncDown_Cell7
	cps wa, 6
	jrl z, AcPmemOutR_AutoIncUp_Cell6
	cps wa, 5
	jrl nz, AcPmemOutR_ReloadAndForward
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00017
	ld xde, (xsp + 8)
	call SetDialUp
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00018
	ld xde, (xsp + 8)
	call SetDialDown
	lds wa, 1
	call SetDialEnable
	ld xwa, (xsp + 16)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld xiz, xhl
	cps iz, 0
	jr z, AcPmemOutR_AutoIncUp_Cell5_FwdParent
	ld xwa, (xsp + 16)
	ld xbc, 0x1e0008e
	ld xde, 0x10000
	call SendEvent
	ld xwa, 0x5b0008
	call GetViewInstance
	lda xwa, (xhl + 42)
	ld xbc, (xwa)
	cpw (xbc), 0xffff
	jrl z, AcPmemOutR_ReloadAndForward
	ld xwa, (xwa)
	ldw (xwa), 0xffff
	ld xwa, 0x5b0008
	ld xbc, 0x1c0000d
	lds32 xde, 0
	jrl AcPmemOutR_DispatchEvent

AcPmemOutR_AutoIncUp_Cell5_FwdParent:
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	jrl AcPmemOutR_ForwardToParent

AcPmemOutR_AutoIncUp_Cell6:
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00017
	ld xde, (xsp + 8)
	call SetDialUp
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00018
	ld xde, (xsp + 8)
	call SetDialDown
	lds wa, 1
	call SetDialEnable
	ld xwa, (xsp + 16)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld xiz, xhl
	cps iz, 1
	jr z, AcPmemOutR_AutoIncUp_Cell6_FwdParent
	ld xwa, (xsp + 16)
	ld xbc, 0x1e0008e
	ld xde, 0x10001
	call SendEvent
	ld xwa, 0x5b0008
	call GetViewInstance
	lda xwa, (xhl + 42)
	ld xbc, (xwa)
	cpw (xbc), 0xffff
	jrl z, AcPmemOutR_ReloadAndForward
	ld xwa, (xwa)
	ldw (xwa), 0xffff
	ld xwa, 0x5b0008
	ld xbc, 0x1c0000d
	lds32 xde, 0
	jrl AcPmemOutR_DispatchEvent

AcPmemOutR_AutoIncUp_Cell6_FwdParent:
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	jrl AcPmemOutR_ForwardToParent

AcPmemOutR_AutoIncDown_Cell7:
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00017
	ld xde, (xsp + 8)
	call SetDialUp
	ld xwa, (xsp + 16)
	ld xbc, 0x1c00018
	ld xde, (xsp + 8)
	call SetDialDown
	lds wa, 1
	call SetDialEnable
	ld xwa, (xsp + 16)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld xiz, xhl
	cps iz, 2
	jr z, AcPmemOutR_AutoIncDown_Cell7_FwdParent
	ld xwa, (xsp + 16)
	ld xbc, 0x1e0008e
	ld xde, 0x10002
	call SendEvent
	ld xwa, 0x5b0008
	call GetViewInstance
	lda xwa, (xhl + 42)
	ld xbc, (xwa)
	cpw (xbc), 0xffff
	jr z, AcPmemOutR_ReloadAndForward
	ld xwa, (xwa)
	ldw (xwa), 0xffff
	ld xwa, 0x5b0008
	ld xbc, 0x1c0000d
	lds32 xde, 0

AcPmemOutR_DispatchEvent:
	call SendEvent
	jr AcPmemOutR_ReloadAndForward

AcPmemOutR_AutoIncDown_Cell7_FwdParent:
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)

AcPmemOutR_ForwardToParent:
	call ApFuncCall

AcPmemOutR_ReloadAndForward:
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)

AcPmemOutR_CallBase:
	call InheritedProc
	jr AcPmemOutR_ReturnHandled

AcPmemOutR_GetColText:
	ld xwa, (xsp + 16)
	ld xiz, 0x3e
	jr AcPmemOutR_CopyText

AcPmemOutR_GetRowText:
	ld xwa, (xsp + 16)
	ld xiz, 0x42

AcPmemOutR_CopyText:
	call GetViewInstance
	add xhl, xiz
	ld xwa, (xhl)
	push xwa
	ld xwa, (xsp + 12)
	push xwa
	call Strcpy
	inc 8, xsp
	jr AcPmemOutR_ReturnHandled
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	jr AcPmemOutR_CellSelect_Forward

AcPmemOutR_CellSelect:
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)

AcPmemOutR_CellSelect_Forward:
	call ApFuncCall

AcPmemOutR_ReturnHandled:
	lds32 xhl, 0
	jr AcPmemOutR_Return

AcPmemOutR_ForwardToBase:
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call InheritedProc

AcPmemOutR_Return:
	pop xiz
	lda xsp, (xsp + 16)
	ret


; -----------------------------------------------------------------------------
; Section: Parameter Output Grid Checks
; -----------------------------------------------------------------------------
; Grid validation, checking, and event handling
; for left/right parameter output panels.
; -----------------------------------------------------------------------------

PmemOutLGridCheck:
	lda xsp, (xsp - 78)
	push xiz
	ld xhl, xde
	ld xde, xbc
	ld xiy, 0xe80124
	lda xix, (xsp + 44)
	ldw bc, 0x8
	ldirw
	ld xiy, 0xe7ed44
	lda xix, (xsp + 36)
	lds bc, 4
	ldirw
	ld xix, xde
	lda_24 xwa, 0xe800ea
	ld (xsp + 8), xwa
	lda xbc, (xsp + 36)
	lda_24 xwa, 0x1ed400
	ld (xsp + 24), xwa
	ldada xwa, 63904
	ld (xsp + 20), xwa
	ldada xwa, 64812
	sub xwa, (xsp + 20)
	ld xiz, xwa
	lda xiy, (xbc + 2)
	lda xwa, (xbc + 4)
	ld (xsp + 28), xwa
	ld (xsp + 32), xiz
	cp xde, 0x1e0008d
	jrl z, PmemOutL_GridCheck
	ld xwa, xix
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, PmemOutGrid_ReturnZero
	cp xwa, 0x6
	jrl gt, PmemOutGrid_ReturnZero
	add xwa, xwa
	add xwa, 0xe801c6
	ld wa, (xwa)
	lda_24 xix, PmemOutLGridCheck_JumpTable
	jp_dri 8, 0x07, 0xf0, 0xe0

PmemOutLGridCheck_JumpTable:
	.byte 0x1d, 0xd0, 0x44, 0xfa, 0xeb, 0x88, 0x41, 0x8f
	.byte 0x00, 0xe0, 0x01, 0xea, 0xa8, 0x1d, 0x60, 0x96
	.byte 0xfa, 0xbf, 0x24, 0x30, 0xeb, 0x89, 0xe9, 0xef
	.byte 0x00, 0xd7, 0xe6, 0xa8, 0xb0, 0x51, 0xb8, 0x02
	.byte 0x53, 0x90, 0x3f, 0x01, 0x00, 0x7e, 0xa4, 0x07
	.byte 0xdb, 0xdb, 0x66, 0x7c, 0xdb, 0xd9, 0x66, 0x27
	.byte 0xdb, 0xd8, 0x7e, 0x97, 0x07, 0x45, 0x0e, 0x01
	.byte 0xe8, 0x00, 0xbf, 0x3c, 0x34, 0x31, 0x0b, 0x00
	.byte 0x95, 0x11, 0xbf, 0x3c, 0x30, 0xf2, 0x72, 0x47
	.byte 0x02, 0x31, 0xb0, 0x61, 0x41, 0x4f, 0x00, 0x00
	.byte 0x00, 0xb8, 0x06, 0x61, 0x78, 0x48, 0x01, 0x45
	.long NakaData_PartFlags
	.byte 0xbf, 0x3c, 0x34, 0x31
	.byte 0x0b, 0x00, 0x95, 0x11, 0xf1, 0x2c, 0xfd, 0x32
	.byte 0xea, 0xca, 0xa0, 0xf9, 0x00, 0x00, 0xe8, 0xa8
	.byte 0xc2, 0x72, 0x47, 0x02, 0x21, 0xe8, 0x89, 0xe9
	.byte 0xee, 0x04, 0xe8, 0xa1, 0xe9, 0xee, 0x06, 0xf2
	.byte 0x00, 0xd4, 0x1e, 0x30, 0xe9, 0x80, 0xe8, 0x89
	.byte 0xea, 0x81, 0xbf, 0x3c, 0x30, 0xb0, 0x61, 0x41
	.byte 0xff, 0x00, 0x00, 0x00, 0xb8, 0x06, 0x61, 0xa0
	.byte 0x21, 0x81, 0x23, 0xcb, 0x31, 0x01, 0x22, 0x00
	.byte 0xe9, 0x12, 0xb8, 0x0e, 0x61, 0x78, 0xcc, 0x00
	.byte 0x45, 0x0e, 0x01, 0xe8, 0x00, 0xbf, 0x3c, 0x34
	.byte 0x31, 0x0b, 0x00, 0x95, 0x11, 0xbf, 0x3c, 0x30
	.byte 0xf2, 0x74, 0x47, 0x02, 0x31, 0xb0, 0x61, 0xe9
	.byte 0xaa, 0xb8, 0x06, 0x61, 0x78, 0xd8, 0x00, 0x1d
	.byte 0xd0, 0x44, 0xfa, 0xeb, 0x88, 0x41, 0x8f, 0x00
	.byte 0xe0, 0x01, 0xea, 0xa8, 0x1d, 0x60, 0x96, 0xfa
	.byte 0xbf, 0x24, 0x30, 0xeb, 0x89, 0xe9, 0xef, 0x00
	.byte 0xd7, 0xe6, 0xa8, 0xb0, 0x51, 0xb8, 0x02, 0x53
	.byte 0x90, 0x3f, 0x01, 0x00, 0x7e, 0xdd, 0x06, 0xdb
	.byte 0xdb, 0x76, 0x87, 0x00, 0xdb, 0xd9, 0x66, 0x2e
	.byte 0xdb, 0xd8, 0x7e, 0xcf, 0x06, 0x45, 0x0e, 0x01
	.byte 0xe8, 0x00, 0xbf, 0x3c, 0x34, 0x31, 0x0b, 0x00
	.byte 0x95, 0x11, 0xbf, 0x3c, 0x30, 0xf2, 0x72, 0x47
	.byte 0x02, 0x31, 0xb0, 0x61, 0x41, 0x4f, 0x00, 0x00
	.byte 0x00, 0xb8, 0x06, 0x61, 0x41, 0xff, 0xff, 0xff
	.byte 0xff, 0xb8, 0x0e
	.ascii "ahyE"
	ret
	.byte 0x01, 0xe8, 0x00, 0xbf, 0x3c, 0x34, 0x31, 0x0b
	.byte 0x00, 0x95, 0x11, 0xf1, 0x2c, 0xfd, 0x32, 0xea
	.byte 0xca, 0xa0, 0xf9, 0x00, 0x00, 0xe8, 0xa8, 0xc2
	.byte 0x72, 0x47, 0x02, 0x21, 0xe8, 0x89, 0xe9, 0xee
	.byte 0x04, 0xe8, 0xa1, 0xe9, 0xee, 0x06, 0xf2, 0x00
	.byte 0xd4, 0x1e, 0x30, 0xe9, 0x80, 0xe8, 0x89, 0xea
	.byte 0x81, 0xbf, 0x3c, 0x30, 0xb0, 0x61, 0x41, 0xff
	.byte 0x00, 0x00, 0x00, 0xb8, 0x06, 0x61, 0xa0, 0x21
	.byte 0x81, 0x23, 0xcb, 0x30, 0x01, 0x22, 0x00, 0xe9
	.byte 0x12, 0xb8, 0x0e, 0x61, 0x1d, 0x47, 0xfe, 0xf9
	.byte 0x78, 0x51, 0x06, 0x45, 0x0e, 0x01, 0xe8, 0x00
	.byte 0xbf, 0x3c, 0x34, 0x31, 0x0b, 0x00, 0x95, 0x11
	.byte 0xbf, 0x3c, 0x30, 0xf2, 0x74, 0x47, 0x02, 0x31
	.byte 0xb0, 0x61, 0xe9, 0xaa, 0xb8, 0x06, 0x61, 0x41
	.byte 0xff, 0xff, 0xff, 0xff, 0xb8, 0x0e, 0x61, 0x1d
	.byte 0x8a, 0xfe, 0xf9, 0x78, 0x26, 0x06, 0xbf, 0x04
	.byte 0x63, 0xb1, 0x02, 0x01, 0x00, 0xbf, 0x2c, 0x30
	.byte 0xbf, 0x0c, 0x60, 0xaf, 0x1c, 0x20, 0xaf, 0x0c
	.byte 0x23, 0xb0, 0x63, 0xf2, 0x72, 0x47, 0x02, 0x31
	.byte 0xbf, 0x10, 0x65, 0xaf, 0x04, 0x22, 0xba, 0x0e
	.byte 0x30, 0xbf, 0x1c, 0x60, 0xa2, 0xf1, 0x7e, 0x12
	.byte 0x02, 0xaf, 0x10, 0x20, 0xb0, 0x02, 0x00, 0x00
	.byte 0xaf, 0x1c, 0x20, 0xa0, 0x22, 0xea, 0x88, 0xe8
	.byte 0x89, 0xe9, 0xed, 0x0f, 0xe9, 0xed, 0x00, 0xe9
	.byte 0xcc, 0x07, 0x00, 0x00, 0x00, 0xe8, 0x81, 0xe9
	.byte 0xcc, 0xf8, 0xff, 0xff, 0xff, 0xe9, 0xa0, 0xe8
	.byte 0x61, 0x28, 0xea, 0x89, 0xe9, 0xed, 0x0f, 0xe9
	.byte 0xed, 0x00, 0xe9, 0xcc, 0x07, 0x00, 0x00, 0x00
	.byte 0xea, 0x81, 0xe9, 0xed, 0x03, 0xe9, 0x61, 0x29
	.byte 0x0b, 0xe8, 0x00, 0x0b, 0x34, 0x01, 0x3b, 0x1d
	.byte 0x64, 0x0a, 0xff, 0xbf, 0x0c, 0x37, 0x1d, 0xd0
	.byte 0x44, 0xfa, 0xeb, 0x88, 0xbf, 0x24, 0x32, 0x41
	.byte 0x8c, 0x00, 0xe0, 0x01, 0x1d, 0x60, 0x96, 0xfa
	.byte 0xf1, 0x2c, 0xfd, 0x32, 0xea, 0xca, 0xa0, 0xf9
	.byte 0x00, 0x00, 0xe8, 0xa8, 0xc2, 0x72, 0x47, 0x02
	.byte 0x21, 0xe8, 0x89, 0xe9, 0xee, 0x04, 0xe8, 0xa1
	.byte 0xe9, 0xee, 0x06, 0xf2, 0x00, 0xd4, 0x1e, 0x30
	.byte 0xe9, 0x80, 0xea, 0x80, 0xb0, 0xc9, 0x66, 0x07
	.byte 0x40, 0x3e, 0x01, 0xe8, 0x00, 0x68, 0x05, 0x40
	.long NakaInst_OFF_E80144
	.byte 0x38, 0xbf, 0x30, 0x30
	.byte 0x38, 0x1d, 0x3f, 0x0f, 0xff, 0xef, 0x60, 0xbf
	.byte 0x26, 0x02, 0x01, 0x00, 0x1d, 0xd0, 0x44, 0xfa
	.byte 0xeb, 0x88, 0xbf, 0x24, 0x32, 0x41, 0x8c, 0x00
	.byte 0xe0, 0x01, 0x1d, 0x60, 0x96, 0xfa, 0xbf, 0x26
	.byte 0x02, 0x00, 0x00, 0xf1, 0xc4, 0xf9, 0x30, 0xe8
	.byte 0xca, 0xa0, 0xf9, 0x00, 0x00, 0xbf, 0x20, 0x60
	.byte 0xe8, 0xa8, 0xc2, 0x74, 0x47, 0x02, 0x21, 0x41
	.byte 0x1a, 0x00, 0x00, 0x00, 0x1d, 0x4e, 0x0a, 0xff
	.byte 0xe8, 0xa8, 0xc2, 0x72, 0x47, 0x02, 0x21, 0xe8
	.byte 0x89, 0xe9, 0xee, 0x04, 0xe8, 0xa1, 0xe9, 0xee
	.byte 0x06, 0xf2, 0x00, 0xd4, 0x1e, 0x30, 0xe9, 0x80
	.byte 0xeb, 0x80, 0xaf, 0x20, 0x80, 0xb0, 0xcf, 0x66
	.long Str_ol
	.byte 0x0b, 0x4a, 0x01, 0xbf
	.byte 0x30, 0x30, 0x38, 0x1d, 0x3f, 0x0f, 0xff, 0xef
	.byte 0x60, 0x68, 0x16, 0x80, 0x21, 0xd8, 0x12, 0x28
	.byte 0x0b, 0xe8, 0x00, 0x0b, 0x50, 0x01, 0xbf, 0x32
	.byte 0x30, 0x38, 0x1d, 0x64, 0x0a, 0xff, 0xbf, 0x0a
	.byte 0x37, 0xbf, 0x24, 0x32, 0x40, 0x09, 0x00, 0x5b
	.byte 0x00, 0x41, 0x8c, 0x00, 0xe0, 0x01, 0x1d, 0x60
	.byte 0x96, 0xfa, 0xbf, 0x26, 0x02, 0x01, 0x00, 0xf1
	.byte 0xc5, 0xf9, 0x30, 0xe8, 0xca, 0xa0, 0xf9, 0x00
	.byte 0x00, 0xbf, 0x20, 0x60, 0xe8, 0xa8, 0xc2, 0x74
	.byte 0x47, 0x02, 0x21, 0x41, 0x1a, 0x00, 0x00, 0x00
	.byte 0x1d, 0x4e, 0x0a, 0xff, 0xe8, 0xa8, 0xc2, 0x72
	.byte 0x47, 0x02, 0x21, 0xe8, 0x89, 0xe9, 0xee, 0x04
	.byte 0xe8, 0xa1, 0xe9, 0xee, 0x06, 0xf2, 0x00, 0xd4
	.byte 0x1e, 0x30, 0xe9, 0x80, 0xeb, 0x80, 0xaf, 0x20
	.byte 0x80, 0x80, 0x21, 0xd8, 0x12, 0x28, 0x0b, 0xe8
	.byte 0x00, 0x0b, 0x56, 0x01, 0xbf, 0x32, 0x30, 0x38
	.byte 0x1d, 0x64, 0x0a, 0xff, 0xbf, 0x0a, 0x37, 0xbf
	.byte 0x24, 0x32, 0x40, 0x09, 0x00, 0x5b, 0x00, 0x41
	.byte 0x8c, 0x00, 0xe0, 0x01, 0x1d, 0x60, 0x96, 0xfa
	.byte 0xbf, 0x26, 0x02, 0x02, 0x00, 0xf1, 0xc7, 0xf9
	.byte 0x30, 0xe8, 0xca, 0xa0, 0xf9, 0x00, 0x00, 0xbf
	.byte 0x20, 0x60, 0xe8, 0xa8, 0xc2, 0x74, 0x47, 0x02
	.byte 0x21, 0x41, 0x1a, 0x00, 0x00, 0x00, 0x1d, 0x4e
	.byte 0x0a, 0xff, 0xe8, 0xa8, 0xc2, 0x72, 0x47, 0x02
	.byte 0x21, 0xe8, 0x89, 0xe9, 0xee, 0x04, 0xe8, 0xa1
	.byte 0xe9, 0xee, 0x06, 0xf2, 0x00, 0xd4, 0x1e, 0x30
	.byte 0xe9, 0x80, 0xeb, 0x80, 0xaf, 0x20, 0x80, 0xb0
	.byte 0xcf, 0x66, 0x12, 0x0b, 0xe8, 0x00, 0x0b, 0x5c
	.byte 0x01, 0xbf, 0x30, 0x30, 0x38, 0x1d, 0x3f, 0x0f
	.byte 0xff, 0xef, 0x60, 0x68, 0x16, 0x80, 0x21, 0xd8
	.byte 0x12, 0x28, 0x0b, 0xe8, 0x00, 0x0b, 0x62, 0x01
	.byte 0xbf, 0x32, 0x30, 0x38, 0x1d, 0x64, 0x0a, 0xff
	.byte 0xbf, 0x0a, 0x37, 0xbf, 0x24, 0x32, 0x40, 0x09
	.byte 0x00, 0x5b, 0x00, 0x41, 0x8c, 0x00, 0xe0, 0x01
	.byte 0x78, 0xe5, 0x03, 0xaf, 0x14, 0x20, 0xbf, 0x14
	.byte 0x60, 0xe8, 0xa8, 0xc2, 0x72, 0x47, 0x02, 0x21
	.byte 0xe8, 0x89, 0xe9, 0xee, 0x04, 0xe8, 0xa1, 0xe9
	.byte 0xee, 0x06, 0xaf, 0x18, 0x20, 0xe9, 0x80, 0xbf
	.byte 0x18, 0x60, 0xe8, 0x89, 0xaf, 0x20, 0x81, 0xaf
	.byte 0x04, 0x20, 0xa0, 0xf9, 0x6e, 0x39, 0xaf, 0x10
	.byte 0x20, 0xb0, 0x02, 0x01, 0x00, 0xaf, 0x1c, 0x20
	.byte 0xa0, 0x20, 0xd8, 0x33, 0x01, 0x66, 0x07, 0x40
	.long NakaInst_ON_E80168
	.byte 0x68, 0x05, 0x40, 0x6e
	.byte 0x01, 0xe8, 0x00, 0x38, 0xaf, 0x10, 0x20, 0x38
	.byte 0x1d, 0x3f, 0x0f, 0xff, 0xef, 0x60, 0x1d, 0xd0
	.byte 0x44, 0xfa, 0xeb, 0x88, 0xbf, 0x24, 0x32, 0x41
	.byte 0x8c, 0x00, 0xe0, 0x01, 0x78, 0x81, 0x03, 0xf2
	.byte 0x74, 0x47, 0x02, 0x31, 0xaf, 0x04, 0x20, 0xa0
	.byte 0xf1, 0x7e, 0x8d, 0x01, 0xaf, 0x10, 0x20, 0xb0
	.byte 0x02, 0x03, 0x00, 0xaf, 0x1c, 0x20, 0xa0, 0x20
	.byte 0xe8, 0xee, 0x02, 0xaf, 0x08, 0x21, 0xe8, 0x81
	.byte 0xa1, 0x20, 0x38, 0xaf, 0x10, 0x20, 0x38, 0x1d
	.byte 0x3f, 0x0f, 0xff, 0xef, 0x60, 0x1d, 0xd0, 0x44
	.byte 0xfa, 0xeb, 0x88, 0xbf, 0x24, 0x32, 0x41, 0x8c
	.byte 0x00, 0xe0, 0x01, 0x1d, 0x60, 0x96, 0xfa, 0xbf
	.byte 0x26, 0x02, 0x00, 0x00, 0xf1, 0xc4, 0xf9, 0x30
	.byte 0xe8, 0xca, 0xa0, 0xf9, 0x00, 0x00, 0xbf, 0x20
	.byte 0x60, 0xe8, 0xa8, 0xc2, 0x74, 0x47, 0x02, 0x21
	.byte 0x41, 0x1a, 0x00, 0x00, 0x00, 0x1d, 0x4e, 0x0a
	.byte 0xff, 0xe8, 0xa8, 0xc2, 0x72, 0x47, 0x02, 0x21
	.byte 0xe8, 0x89, 0xe9, 0xee, 0x04, 0xe8, 0xa1, 0xe9
	.byte 0xee, 0x06, 0xf2, 0x00, 0xd4, 0x1e, 0x30, 0xe9
	.byte 0x80, 0xeb, 0x80, 0xaf, 0x20, 0x80, 0xbf, 0x2c
	.byte 0x31, 0xb0, 0xcf, 0x66, 0x0f, 0x0b, 0xe8, 0x00
	.byte 0x0b, 0x74, 0x01, 0x39, 0x1d, 0x3f, 0x0f, 0xff
	.byte 0xef, 0x60, 0x68, 0x13, 0x80, 0x21, 0xd8, 0x12
	.long AudioStream_Property_Table
	.byte 0x0b, 0x7a, 0x01, 0x39
	.byte 0x1d, 0x64, 0x0a, 0xff, 0xbf, 0x0a, 0x37, 0xbf
	.byte 0x24, 0x32, 0x40, 0x09, 0x00, 0x5b, 0x00, 0x41
	.byte 0x8c, 0x00, 0xe0, 0x01, 0x1d, 0x60, 0x96, 0xfa
	.byte 0xbf, 0x26, 0x02, 0x01, 0x00, 0xf1, 0xc5, 0xf9
	.byte 0x30, 0xe8, 0xca, 0xa0, 0xf9, 0x00, 0x00, 0xbf
	.byte 0x20, 0x60, 0xe8, 0xa8, 0xc2, 0x74, 0x47, 0x02
	.byte 0x21, 0x41, 0x1a, 0x00, 0x00, 0x00, 0x1d, 0x4e
	.byte 0x0a, 0xff, 0xe8, 0xa8, 0xc2, 0x72, 0x47, 0x02
	.byte 0x21, 0xe8, 0x89, 0xe9, 0xee, 0x04, 0xe8, 0xa1
	.byte 0xe9, 0xee, 0x06, 0xf2, 0x00, 0xd4, 0x1e, 0x30
	.byte 0xe9, 0x80, 0xeb, 0x80, 0xaf, 0x20, 0x80, 0x80
	.byte 0x21, 0xd8, 0x12, 0x28, 0x0b, 0xe8, 0x00, 0x0b
	.byte 0x80, 0x01, 0xbf, 0x32, 0x30, 0x38, 0x1d, 0x64
	.byte 0x0a, 0xff, 0xbf, 0x0a, 0x37, 0xbf, 0x24, 0x32
	.byte 0x40, 0x09, 0x00, 0x5b, 0x00, 0x41, 0x8c, 0x00
	.byte 0xe0, 0x01, 0x1d, 0x60, 0x96, 0xfa, 0xbf, 0x26
	.byte 0x02, 0x02, 0x00, 0xf1, 0xc7, 0xf9, 0x30, 0xe8
	.byte 0xca, 0xa0, 0xf9, 0x00, 0x00, 0xbf, 0x20, 0x60
	.byte 0xe8, 0xa8, 0xc2, 0x74, 0x47, 0x02, 0x21, 0x41
	.byte 0x1a, 0x00, 0x00, 0x00, 0x1d, 0x4e, 0x0a, 0xff
	.byte 0xe8, 0xa8, 0xc2, 0x72, 0x47, 0x02, 0x21, 0xe8
	.byte 0x89, 0xe9, 0xee, 0x04, 0xe8, 0xa1, 0xe9, 0xee
	.byte 0x06, 0xf2, 0x00, 0xd4, 0x1e, 0x30, 0xe9, 0x80
	.byte 0xeb, 0x80, 0xaf, 0x20, 0x80, 0xb0, 0xcf, 0x66
	.long Str_ol
	.byte 0x0b, 0x86, 0x01, 0xbf
	.byte 0x30, 0x30, 0x38, 0x1d, 0x3f, 0x0f, 0xff, 0xef
	.byte 0x60, 0x68, 0x16, 0x80, 0x21, 0xd8, 0x12, 0x28
	.byte 0x0b, 0xe8, 0x00, 0x0b, 0x8c, 0x01, 0xbf, 0x32
	.byte 0x30, 0x38, 0x1d, 0x64, 0x0a, 0xff, 0xbf, 0x0a
	.byte 0x37, 0xbf, 0x24, 0x32, 0x40, 0x09, 0x00, 0x5b
	.byte 0x00, 0x41, 0x8c, 0x00, 0xe0, 0x01, 0x78, 0xe7
	.byte 0x01, 0xf1, 0xb6, 0xf9, 0x30, 0xbf, 0x20, 0x60
	.byte 0xb8, 0x0e, 0x30, 0xaf, 0x14, 0xa0, 0xbf, 0x08
	.byte 0x60, 0xe8, 0xa8, 0xc2, 0x74, 0x47, 0x02, 0x21
	.byte 0x41, 0x1a, 0x00, 0x00, 0x00, 0x1d, 0x4e, 0x0a
	.byte 0xff, 0xaf, 0x18, 0x21, 0xeb, 0x81, 0xe9, 0x8a
	.byte 0xaf, 0x08, 0x82, 0xaf, 0x04, 0x20, 0xa0, 0xfa
	.byte 0x6e, 0x45, 0xaf, 0x10, 0x20, 0xb0, 0x02, 0x00
	.byte 0x00, 0xaf, 0x1c, 0x20, 0xa0, 0x20, 0xd8, 0x33
	.byte 0x07, 0x66, 0x12, 0x0b, 0xe8, 0x00, 0x0b, 0x92
	.byte 0x01, 0xaf, 0x10, 0x20, 0x38, 0x1d, 0x3f, 0x0f
	.byte 0xff, 0xef, 0x60, 0x68, 0x12, 0x38, 0x0b, 0xe8
	.byte 0x00, 0x0b, 0x98, 0x01, 0xaf, 0x14, 0x20, 0x38
	.byte 0x1d, 0x64, 0x0a, 0xff, 0xbf, 0x0c, 0x37, 0xbf
	.byte 0x24, 0x32, 0x40, 0x09, 0x00, 0x5b, 0x00, 0x41
	.byte 0x8c, 0x00, 0xe0, 0x01, 0x78, 0x71, 0x01, 0xaf
	.byte 0x20, 0x20, 0xb8, 0x0f, 0x30, 0xaf, 0x14, 0xa0
	.byte 0xe9, 0x8a, 0xe8, 0x82, 0xaf, 0x04, 0x20, 0xa0
	.byte 0xfa, 0x6e, 0x2e, 0xaf, 0x10, 0x20, 0xb0, 0x02
	.byte 0x01, 0x00, 0xaf, 0x1c, 0x20, 0xa0, 0x20, 0x38
	.byte 0x0b, 0xe8, 0x00, 0x0b, 0x9e, 0x01, 0xaf, 0x14
	.byte 0x20, 0x38, 0x1d, 0x64, 0x0a, 0xff, 0xbf, 0x0c
	.byte 0x37, 0xbf, 0x24, 0x32, 0x40, 0x09, 0x00, 0x5b
	.byte 0x00, 0x41, 0x8c, 0x00, 0xe0, 0x01, 0x78, 0x2f
	.byte 0x01, 0xaf, 0x20, 0x20, 0xb8, 0x11, 0x30, 0xaf
	.byte 0x14, 0xa0, 0xe8, 0x81, 0xaf, 0x04, 0x20, 0xa0
	.byte 0xf9, 0x7e, 0x20, 0x01, 0xaf, 0x10, 0x20, 0xb0
	.byte 0x02, 0x02, 0x00, 0xaf, 0x1c, 0x20, 0xa0, 0x20
	.byte 0xd8, 0x33, 0x07, 0x66, 0x12, 0x0b, 0xe8, 0x00
	.byte 0x0b, 0xa4, 0x01, 0xaf, 0x10, 0x20, 0x38, 0x1d
	.byte 0x3f, 0x0f, 0xff, 0xef, 0x60, 0x68, 0x12, 0x38
	.byte 0x0b, 0xe8, 0x00, 0x0b, 0xaa, 0x01, 0xaf, 0x14
	.byte 0x20, 0x38, 0x1d, 0x64, 0x0a, 0xff, 0xbf, 0x0c
	.byte 0x37, 0xbf, 0x24, 0x32, 0x40, 0x09, 0x00, 0x5b
	.byte 0x00, 0x41, 0x8c, 0x00, 0xe0, 0x01, 0x78, 0xd7
	nop

; PmemOutLGridCheck dispatch
PmemOutL_GridCheck:
	ld xwa, xhl
	srl xwa, 0
	ldi_werp 0xe2, 0
	ld (xbc), wa
	ld xix, xiy
	ld (xiy), hl
	lda xwa, (xsp + 44)
	ld (xsp + 20), xwa
	ld xwa, (xsp + 28)
	ld xde, (xsp + 20)
	ld (xwa), xde
	cpw (xbc), 0x1
	jrl nz, PmemOutGrid_ReturnZero
	ld wa, (xix)
	cps wa, 3
	jrl z, PmemOutL_ColumnParamDisplay
	cps wa, 1
	jr z, PmemOutL_BitCheckDisplay
	cps wa, 0
	jrl nz, PmemOutGrid_ReturnZero
	ld8_24 c, 0x024772
	ld a, c
	and a, 0x7
	inc 1, a
	extz wa
	pushw wa
	srl c, 3
	inc 1, c
	extz bc
	pushw bc
	pushw 0xe8
	pushw 0x1b0
	push xde
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 36)
	ld xbc, 0x1e0008c
	jr PmemOutL_GridCheck_Return

PmemOutL_BitCheckDisplay:
	lds32 xwa, 0
	ld8_24 a, 0x024772
	ld xbc, xwa
	sll xbc, 4
	sub xbc, xwa
	sll xbc, 6
	ld xwa, (xsp + 24)
	add xwa, xbc
	add xwa, (xsp + 32)
	bitm 1, (xwa)
	jr z, PmemOutL_LoadOffStr
	ld xwa, 0xe801ba
	jr PmemOutL_StrCopyAndDispatch

PmemOutL_LoadOffStr:
	ld xwa, 0xe801c0

PmemOutL_StrCopyAndDispatch:
	push xwa
	ld xwa, (xsp + 24)
	push xwa
	call Strcpy
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 36)
	ld xbc, 0x1e0008c
	jr PmemOutL_GridCheck_Return

PmemOutL_ColumnParamDisplay:
	ld8_24 c, 0x024774
	extz bc
	sla bc, 2
	ld xwa, (xsp + 8)
	ld_sril3 XWA, 0x07, 0xe0, 0xe4
	push xwa
	ld xwa, (xsp + 24)
	push xwa
	call Strcpy
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 36)
	ld xbc, 0x1e0008c

; PmemOutLGridCheck return
PmemOutL_GridCheck_Return:
	call SendEvent

PmemOutGrid_ReturnZero:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 78)
	ret

PmemOutRGridCheck:
	lda xsp, (xsp - 74)
	push xiz
	ld xiz, xde
	ld xde, xbc
	ld xiy, 0xe801ea
	lda xix, (xsp + 40)
	ldw bc, 0x8
	ldirw
	ld xiy, 0xe7ed44
	lda xix, (xsp + 32)
	lds bc, 4
	ldirw
	ld xhl, xde
	lda xbc, (xsp + 32)
	ldada xwa, 63926
	ld (xsp + 20), xwa
	lda_24 xwa, 0x1ed400
	ld (xsp + 16), xwa
	ld xwa, (xsp + 20)
	lda xwa, (xwa + 14)
	ld (xsp + 28), xwa
	lda xiy, (xbc + 2)
	lda xwa, (xbc + 4)
	ld (xsp + 24), xwa
	cp xde, 0x1e0008d
	jrl z, CtlMsgGrid_EventHandler
	sub xhl, 0x1c00017
	cp xhl, 0x0
	jrl lt, TtMdCtlMsg_ReturnZero2
	cp xhl, 0x6
	jrl gt, TtMdCtlMsg_ReturnZero2
	add xhl, xhl
	add xhl, 0xe80272
	ld hl, (xhl)
	lda_24 xix, TtMdCtlMsg_EventDispatch
	jp_dri 8, 0x07, 0xf0, 0xec
; TtMdCtlMsg event dispatch (7-entry, table 0xe80272)

; -----------------------------------------------------------------------------
; Section: Control Message Dispatch
; -----------------------------------------------------------------------------
; MIDI control message event dispatch, grid box
; event handling, and message routing.
; -----------------------------------------------------------------------------

TtMdCtlMsg_EventDispatch:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 31457423
	lds32	xde, 0
	call	SendEvent
	ld	xiz, xhl
	lda	xwa, (xsp+32)
	ld	xbc, xiz
	srl	xbc, 0
	.byte 0xd7, 0xe6, 0xa8
	ld	(xwa), bc
	ld	bc, iz
	ld	(xwa+2), bc
	.byte 0x90
	push	xsp
	.byte 0x01
	nop
	jrl	nz, 2053
	cps	bc, 2
	jrl	z, 205
	cps	bc, 1
	jr	z, 112
	cps	bc, 0
	jrl	nz, 2039
	ld	xiy, 15204820
	lda	xix, (xsp+56)
	ldw	bc, 11
	.byte 0x95
	scf
	ldada	xwa, 63940
	sub	xwa, 63904
	ld	(xsp+28), xwa
	lds32	xwa, 0
	ld8_24	a, 149364
	ld	xbc, 26
	call	Math_MultiplyAccumulate
	lds32	xwa, 0
	ld8_24	a, 149362
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda_24	xwa, 2020352
	add	xwa, xbc
	add	xwa, xhl
	ld	xbc, xwa
	.byte 0xaf, 0x1c, 0x81
	lda	xwa, (xsp+56)
	ld	(xwa), xbc
	ld	xbc, 127
	ld	(xwa+6), xbc
	ld	xbc, (xwa)
	.byte 0xb1
	inc	6, l
	incf
	lds32	xbc, 0
	ld	(xwa+14), xbc
	call	MainRamPut
	jrl	1935
	jrl	598
	ld	xiy, 15204820
	lda	xix, (xsp+56)
	ldw	bc, 11
	.byte 0x95
	scf
	ldada	xwa, 63941
	sub	xwa, 63904
	ld	(xsp+28), xwa
	lds32	xwa, 0
	ld8_24	a, 149364
	ld	xbc, 26
	call	Math_MultiplyAccumulate
	lds32	xwa, 0
	ld8_24	a, 149362
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda_24	xwa, 2020352
	add	xwa, xbc
	add	xwa, xhl
	ld	xbc, xwa
	.byte 0xaf, 0x1c, 0x81
	lda	xwa, (xsp+56)
	ld	(xwa), xbc
	ld	xbc, 255
	ld	(xwa+6), xbc
	jrl	509
	ld	xiy, 15204820
	lda	xix, (xsp+56)
	ldw	bc, 11
	.byte 0x95
	scf
	ldada	xwa, 63943
	sub	xwa, 63904
	ld	(xsp+28), xwa
	lds32	xwa, 0
	ld8_24	a, 149364
	ld	xbc, 26
	call	Math_MultiplyAccumulate
	lds32	xwa, 0
	ld8_24	a, 149362
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda_24	xwa, 2020352
	add	xwa, xbc
	add	xwa, xhl
	ld	xbc, xwa
	.byte 0xaf, 0x1c, 0x81
	lda	xwa, (xsp+56)
	ld	(xwa), xbc
	ld	xbc, 127
	ld	(xwa+6), xbc
	ld	xbc, (xwa)
	.byte 0xb1
	inc	6, l
	incf
	lds32	xbc, 0
	ld	(xwa+14), xbc
	call	MainRamPut
	jrl	1739
	jrl	402
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 31457423
	lds32	xde, 0
	call	SendEvent
	ld	xiz, xhl
	lda	xwa, (xsp+32)
	.byte 0xee
	.long OscScope_FinalizeRender
	.byte 0xd7, 0xe6, 0xa8
	ld	(xwa), bc
	ld	bc, iz
	ld	(xwa+2), bc
	.byte 0x90
	push	xsp
	.byte 0x01
	nop
	jrl	nz, 1692
	cps	bc, 2
	jrl	z, 229
	cps	bc, 1
	jrl	z, 128
	cps	bc, 0
	jrl	nz, 1677
	ld	xiy, 15204820
	lda	xix, (xsp+56)
	ldw	bc, 11
	.byte 0x95
	scf
	ldada	xwa, 63940
	sub	xwa, 63904
	ld	(xsp+28), xwa
	lds32	xwa, 0
	ld8_24	a, 149364
	ld	xbc, 26
	call	Math_MultiplyAccumulate
	lds32	xwa, 0
	ld8_24	a, 149362
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda_24	xwa, 2020352
	add	xwa, xbc
	add	xwa, xhl
	ld	xbc, xwa
	.byte 0xaf, 0x1c, 0x81
	lda	xwa, (xsp+56)
	ld	(xwa), xbc
	ld	xbc, 127
	ld	(xwa+6), xbc
	ld	xbc, (xwa)
	.byte 0xb1
	scc8	nz, l
	ldw	wa, 40966
	ldb	a, 184
	ret
	ldw	de, 16257
	nop
	jr	nz, 10
	ld	xbc, 128
	ld	(xde), xbc
	jrl	216
	ld	xbc, 4294967295
	ld	(xde), xbc
	jrl	220
	.byte 0x45
	.long NakaInst_ON_E80168_0x6C
	lda	xix, (xsp+56)
	ldw	bc, 11
	.byte 0x95
	scf
	ldada	xwa, 63941
	sub	xwa, 63904
	ld	(xsp+28), xwa
	lds32	xwa, 0
	ld8_24	a, 149364
	ld	xbc, 26
	call	Math_MultiplyAccumulate
	lds32	xwa, 0
	ld8_24	a, 149362
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda_24	xwa, 2020352
	add	xwa, xbc
	add	xwa, xhl
	ld	xbc, xwa
	.byte 0xaf, 0x1c, 0x81
	lda	xwa, (xsp+56)
	ld	(xwa), xbc
	ld	xbc, 255
	ld	(xwa+6), xbc
	ld	xbc, 4294967295
	.byte 0xb8
	ret
	.ascii "ah|E"
	.long NakaInst_ON_E80168_0x6C
	lda	xix, (xsp+56)
	ldw	bc, 11
	.byte 0x95
	scf
	ldada	xwa, 63943
	sub	xwa, 63904
	ld	(xsp+28), xwa
	lds32	xwa, 0
	ld8_24	a, 149364
	ld	xbc, 26
	call	Math_MultiplyAccumulate
	lds32	xwa, 0
	ld8_24	a, 149362
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda_24	xwa, 2020352
	add	xwa, xbc
	add	xwa, xhl
	ld	xbc, xwa
	.byte 0xaf, 0x1c, 0x81
	lda	xwa, (xsp+56)
	ld	(xwa), xbc
	ld	xbc, 127
	ld	(xwa+6), xbc
	ld	xbc, (xwa)
	.byte 0xb1
	scc8	nz, l
	.byte 0x55
	halt
	ld	xbc, (xwa)
	lda	xde, (xwa+14)
	.byte 0x81
	push	xsp
	nop
	jr	nz, 14
	ld	xbc, 128
	ld	(xde), xbc
	call	MainRamPut
	jrl	1341
	ld	xbc, 4294967295
	ld	(xde), xbc
	call	MainRamAdd
	jrl	1327
	ld	(xsp+4), xiz
	.byte 0xb1
	push_sr
	.byte 0x01
	nop
	lda	xbc, (xsp+40)
	ld	(xsp+12), xbc
	ld	xwa, (xsp+24)
	ld	(xwa), xbc
	lda_24	xwa, 149362
	ld	(xsp+24), xiy
	ldada	xbc, 63904
	.byte 0xa6, 0xf0
	jrl	nz, 345
	ld	xwa, (xsp+24)
	.byte 0xb0
	push_sr
	nop
	nop
	ld	xwa, (xsp+28)
	sub	xwa, xbc
	ld	xiz, xwa
	lds32	xwa, 0
	ld8_24	a, 149364
	ld	xbc, 26
	call	Math_MultiplyAccumulate
	lds32	xwa, 0
	ld8_24	a, 149362
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	ld	xwa, (xsp+16)
	add	xwa, xbc
	add	xwa, xhl
	add	xwa, xiz
	.byte 0xb0
	inc	6, l
	.long Str_ol
	pushw	506
	ld	xwa, (xsp+16)
	push	xwa
	call	Strcpy
	inc	8, xsp
	jr	22
	ld	a, (xwa)
	extz	wa
	pushw	wa
	pushw	232
	pushw	512
	ld	xwa, (xsp+18)
	push	xwa
	call	Audio_SendCommand
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+32)
	ld	xbc, 31457420
	call	SendEvent
	.byte 0xbf
	ldb	b, 2
	.byte 0x01
	nop
	ldada	xwa, 63941
	sub	xwa, 63904
	ld	(xsp+28), xwa
	lds32	xwa, 0
	ld8_24	a, 149364
	ld	xbc, 26
	call	Math_MultiplyAccumulate
	lds32	xwa, 0
	ld8_24	a, 149362
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda_24	xwa, 2020352
	add	xwa, xbc
	add	xwa, xhl
	.byte 0xaf, 0x1c, 0x80
	ld	a, (xwa)
	extz	wa
	pushw	wa
	pushw	232
	pushw	518
	lda	xwa, (xsp+46)
	push	xwa
	call	Audio_SendCommand
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+32)
	ld	xbc, 31457420
	call	SendEvent
	.byte 0xbf
	ldb	b, 2
	push_sr
	nop
	ldada	xwa, 63943
	sub	xwa, 63904
	ld	(xsp+28), xwa
	lds32	xwa, 0
	ld8_24	a, 149364
	ld	xbc, 26
	call	Math_MultiplyAccumulate
	lds32	xwa, 0
	ld8_24	a, 149362
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda_24	xwa, 2020352
	add	xwa, xbc
	add	xwa, xhl
	.byte 0xaf, 0x1c, 0x80, 0xb0
	inc	6, l
	ccf
	pushw	232
	pushw	524
	lda	xwa, (xsp+44)
	push	xwa
	call	Strcpy
	inc	8, xsp
	jr	22
	ld	a, (xwa)
	extz	wa
	pushw	wa
	pushw	232
	pushw	530
	lda	xwa, (xsp+46)
	push	xwa
	call	Audio_SendCommand
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+32)
	ld	xbc, 31457420
	jrl	943
	lda_24	xde, 149364
	ld	xwa, (xsp+28)
	sub	xwa, xbc
	ld	(xsp+28), xwa
	.byte 0xa6, 0xf2
	jrl	nz, 336
	ld	xwa, (xsp+24)
	.byte 0xb0
	push_sr
	nop
	nop
	lds32	xwa, 0
	ld8_24	a, 149364
	ld	xbc, 26
	call	Math_MultiplyAccumulate
	lds32	xwa, 0
	ld8_24	a, 149362
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	ld	xwa, (xsp+16)
	add	xwa, xbc
	add	xwa, xhl
	.byte 0xaf, 0x1c, 0x80, 0xb0
	inc	6, l
	ccf
	pushw	232
	pushw	536
	ld	xwa, (xsp+16)
	push	xwa
	call	Strcpy
	inc	8, xsp
	jr	22
	ld	a, (xwa)
	extz	wa
	pushw	wa
	pushw	232
	pushw	542
	ld	xwa, (xsp+18)
	push	xwa
	call	Audio_SendCommand
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+32)
	ld	xbc, 31457420
	call	SendEvent
	.byte 0xbf
	ldb	b, 2
	.byte 0x01
	nop
	ldada	xwa, 63941
	sub	xwa, 63904
	ld	(xsp+28), xwa
	lds32	xwa, 0
	ld8_24	a, 149364
	ld	xbc, 26
	call	Math_MultiplyAccumulate
	lds32	xwa, 0
	ld8_24	a, 149362
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda_24	xwa, 2020352
	add	xwa, xbc
	add	xwa, xhl
	.byte 0xaf, 0x1c, 0x80
	ld	a, (xwa)
	extz	wa
	pushw	wa
	pushw	232
	pushw	548
	lda	xwa, (xsp+46)
	push	xwa
	call	Audio_SendCommand
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+32)
	ld	xbc, 31457420
	call	SendEvent
	.byte 0xbf
	ldb	b, 2
	push_sr
	nop
	ldada	xwa, 63943
	sub	xwa, 63904
	ld	(xsp+28), xwa
	lds32	xwa, 0
	ld8_24	a, 149364
	ld	xbc, 26
	call	Math_MultiplyAccumulate
	lds32	xwa, 0
	ld8_24	a, 149362
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda_24	xwa, 2020352
	add	xwa, xbc
	add	xwa, xhl
	.byte 0xaf, 0x1c, 0x80
	lda	xbc, (xsp+40)
	.byte 0xb0
	inc	6, l
	retd	59403
	nop
	pushw	554
	push	xbc
	call	Strcpy
	inc	8, xsp
	jr	19
	ld	a, (xwa)
	extz	wa
	.long AudioStream_Property_Table
	pushw	560
	push	xbc
	call	Audio_SendCommand
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+32)
	ld	xbc, 31457420
	jrl	589
	ld	(xsp+8), xbc
	ld	xwa, (xsp+20)
	ld	(xsp+20), xwa
	lds32	xwa, 0
	ld8_24	a, 149364
	ld	xbc, 26
	call	Math_MultiplyAccumulate
	lds32	xbc, 0
	ld8_24	c, 149362
	ld	xwa, xbc
	sll	xwa, 4
	sub	xwa, xbc
	sll	xwa, 6
	ld	xbc, (xsp+16)
	add	xbc, xwa
	add	xbc, xhl
	ld	xwa, xbc
	.byte 0xaf, 0x1c, 0x80
	cp	(xiz), xwa
	jr	nz, 68
	ld	xwa, (xsp+24)
	.byte 0xb0
	push_sr
	nop
	nop
	ld	xwa, (xiz+14)
	bit	7, wa
	.byte 0x66
	.long Str_ol
	pushw	566
	ld	xwa, (xsp+16)
	push	xwa
	call	Strcpy
	inc	8, xsp
	jr	18
	push	xwa
	pushw	232
	pushw	572
	ld	xwa, (xsp+20)
	push	xwa
	call	Audio_SendCommand
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+32)
	ld	xbc, 31457420
	jrl	463
	ld	xwa, (xsp+20)
	lda	xwa, (xwa+15)
	.byte 0xaf
	ldio	160, 233
	.byte 0x8b
	add	xhl, xwa
	ld	xwa, (xsp+4)
	lda	xde, (xwa+14)
	cp	(xwa), xhl
	jr	nz, 44
	ld	xwa, (xsp+24)
	.byte 0xb0
	push_sr
	.byte 0x01
	nop
	ld	xwa, (xde)
	push	xwa
	pushw	232
	pushw	578
	ld	xwa, (xsp+20)
	push	xwa
	call	Audio_SendCommand
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+32)
	ld	xbc, 31457420
	jrl	396
	ld	xwa, (xsp+20)
	lda	xwa, (xwa+17)
	.byte 0xaf
	ldio	160, 232
	sub	(xbc), l
	.byte 0x04
	ldb	w, 160
	swi	1
	jrl	nz, 381
	ld	xwa, (xsp+24)
	.byte 0xb0
	push_sr
	push_sr
	nop
	ld	xwa, (xde)
	bit	7, wa
	jr	z, 18
	pushw	232
	pushw	584
	ld	xwa, (xsp+16)
	push	xwa
	call	Strcpy
	inc	8, xsp
	jr	18
	push	xwa
	pushw	232
	pushw	590
	ld	xwa, (xsp+20)
	push	xwa
	call	Audio_SendCommand
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+32)
	ld	xbc, 31457420
	jrl	310

; CtlMsgGridCheck event handler dispatch
CtlMsgGrid_EventHandler:
	ld xwa, xiz
	srl xwa, 0
	ldi_werp 0xe2, 0
	ld (xbc), wa
	ld xhl, xiy
	ld wa, iz
	ld (xiy), wa
	lda xde, (xsp + 40)
	ld (xsp + 12), xde
	ld xwa, (xsp + 24)
	ld (xwa), xde
	cpw (xbc), 0x1
	jrl nz, TtMdCtlMsg_ReturnZero2
	ld iz, (xhl)
	lds32 xwa, 0
	ld8_24 a, 0x024774
	ld xbc, 0x1a
	call Math_MultiplyAccumulate
	cps iz, 2
	jrl z, CtlMsg_ComputeAndCheck
	lds32 xbc, 0
	ld8_24 c, 0x024772
	ld xwa, xbc
	sll xwa, 4
	sub xwa, xbc
	sll xwa, 6
	ld xbc, (xsp + 16)
	add xbc, xwa
	add xbc, xhl
	cps iz, 1
	jr z, CtlMsg_ReadOffsetAndSend
	cps iz, 0
	jrl nz, TtMdCtlMsg_ReturnZero2
	ld xwa, (xsp + 28)
	sub xwa, 0xf9a0
	add xbc, xwa
	bitm 7, (xbc)
	jr z, CtlMsg_SendAudioCommand
	pushw 0xe8
	pushw 0x254
	ld xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	jr CtlMsg_GetFocusAndDispatch

CtlMsg_SendAudioCommand:
	ld a, (xbc)
	extz wa
	pushw wa
	pushw 0xe8
	pushw 0x25a
	ld xwa, (xsp + 18)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)

CtlMsg_GetFocusAndDispatch:
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 32)
	ld xbc, 0x1e0008c
	jrl CtlMsg_SendEventReturn

CtlMsg_ReadOffsetAndSend:
	ld xwa, (xsp + 20)
	lda xwa, (xwa + 15)
	sub xwa, 0xf9a0
	add xbc, xwa
	ld a, (xbc)
	extz wa
	pushw wa
	pushw 0xe8
	pushw 0x260
	ld xwa, (xsp + 18)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 32)
	ld xbc, 0x1e0008c
	jr CtlMsg_SendEventReturn

CtlMsg_ComputeAndCheck:
	ld xwa, (xsp + 20)
	lda xbc, (xwa + 17)
	sub xbc, 0xf9a0
	lds32 xwa, 0
	ld8_24 a, 0x024772
	ld xde, xwa
	sll xde, 4
	sub xde, xwa
	sll xde, 6
	ld xwa, (xsp + 16)
	add xwa, xde
	add xwa, xhl
	add xwa, xbc
	bitm 7, (xwa)
	jr z, CtlMsg_SendParamValue
	pushw 0xe8
	pushw 0x266
	ld xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	jr CtlMsg_DispatchFocusEvent

CtlMsg_SendParamValue:
	ld a, (xwa)
	extz wa
	pushw wa
	pushw 0xe8
	pushw 0x26c
	ld xwa, (xsp + 18)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)

CtlMsg_DispatchFocusEvent:
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 32)
	ld xbc, 0x1e0008c

CtlMsg_SendEventReturn:
	call SendEvent

TtMdCtlMsg_ReturnZero2:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 74)
	ret

TtMdCtlMsg:
	cp xbc, 0x1c0000c
	jr z, TtMdCtlMsg_ReturnZero
	cp xbc, 0x1c0000b
	jr z, TtMdCtlMsg_ReturnZero
	cp xbc, 0x1c00002
	jr z, TtMdCtlMsg_ReturnZero
	cp xbc, 0x1c00001
	jr nz, TtMdCtlMsg_ReturnZero
	or xde, xde
	jr nz, TtMdCtlMsg_ReturnZero
	sti8_24 0x024776, 0x00
	ld xwa, 0x520002
	call GetViewInstance
	ld xwa, (xhl + 42)
	ldw (xwa), 0x2
	ld xwa, (xhl + 46)
	ldw (xwa), 0x1

TtMdCtlMsg_ReturnZero:
	lds32 xhl, 0
	ret

AcCtlMsgGridBoxProc:
	lda xsp, (xsp - 32)
	push xiz
	ld (xsp + 24), xde
	ld (xsp + 28), xbc
	ld (xsp + 32), xwa
	ld xiy, 0xe80282
	lda xix, (xsp + 8)
	ldw bc, 0x8
	ldirw
	ld xbc, (xsp + 28)
	cp xbc, 0x1e0008d
	jrl z, AcCtlMsgGrid_CellSelect
	ld xwa, (xsp + 28)
	cp xwa, 0x1e0008b
	jrl z, AcCtlMsgGrid_GetRowText
	cp xwa, 0x1e0008a
	jrl z, AcCtlMsgGrid_GetColText
	cp xwa, 0x1c00007
	jrl z, AcCtlMsgGrid_OK
	cp xwa, 0x1c0000b
	jrl z, AcCtlMsgGrid_Show
	cp xwa, 0x1c00001
	jr z, AcCtlMsgGrid_Init
	sub xbc, 0x1c00017
	cp xbc, 0x0
	jrl lt, AcCtlMsgGrid_ForwardToBase
	cp xbc, 0x6
	jrl gt, AcCtlMsgGrid_ForwardToBase
	add xbc, xbc
	add xbc, 0xe80378
	ld bc, (xbc)
	lda_24 xix, AcCtlMsgGrid_Init
	jp_dri 8, 0x07, 0xf0, 0xe4

AcCtlMsgGrid_Init:
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	call InheritedProc
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xbc, (xwa + 74)
	ld8_24 a, 0x024776
	extz wa
	ld (xbc), wa
	ld xwa, (xsp + 32)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld xiz, xhl
	ld xwa, (xsp + 4)
	ld bc, (xwa + 26)
	ld xwa, xiz
	srl xwa, 0
	ldi_werp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 32)
	ld xbc, 0x1c00017
	call SetDialUp
	ld xwa, (xsp + 4)
	ld bc, (xwa + 26)
	ld xwa, xiz
	srl xwa, 0
	ldi_werp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 32)
	ld xbc, 0x1c00018
	call SetDialDown
	lds wa, 1
	jrl AcCtlMsgGrid_ScrollCommit

AcCtlMsgGrid_Show:
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	call InheritedProc
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, 0xe7ecf2
	ldw bc, 0xc1
	ldw de, 0xf3
	call DrawDesignBox
	ld xwa, (xiz + 74)
	ld wa, (xwa)
	sla wa, 2
	lda_24 xbc, 0xe7ecfe
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xde, (xsp + 8)
	lds32 xwa, 0
	push xwa
	pushw 0x0
	pushw 0xf7
	ld xwa, 0xe7ecf2
	ld xbc, 0xe7ecfa
	call DrawStringCentered
	jrl AcCtlMsgGrid_ReturnHandled

AcCtlMsgGrid_OK:
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	call InheritedProc
	ld xwa, (xsp + 32)
	call GetViewInstance
	lda xbc, (xhl + 74)
	ld xwa, (xsp + 24)
	cp xwa, 0x90
	jr z, AcCtlMsgGrid_OK_Down
	cp xwa, 0x10
	jrl nz, AcCtlMsgGrid_ReturnHandled
	ld xde, xbc
	ld xbc, (xbc)
	ld wa, (xbc)
	inc 1, wa
	ld (xbc), wa
	cps wa, 1
	jr le, AcCtlMsgGrid_OK_Up_Store
	ld xwa, (xde)
	ldw (xwa), 0x0

AcCtlMsgGrid_OK_Up_Store:
	ld xwa, (xde)
	ld wa, (xwa)
	st8_24 0x024776, a
	ld xwa, (xsp + 32)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 32)
	ld xbc, 0x1e0008e
	ld xde, 0xffff0002
	jr AcCtlMsgGrid_OK_DispatchScroll

AcCtlMsgGrid_OK_Down:
	ld xde, xbc
	ld xbc, (xbc)
	ld wa, (xbc)
	dec 1, wa
	ld (xbc), wa
	cps wa, 0
	jr ge, AcCtlMsgGrid_OK_Down_Store
	ld xwa, (xde)
	ldw (xwa), 0x1

AcCtlMsgGrid_OK_Down_Store:
	ld xwa, (xde)
	ld wa, (xwa)
	st8_24 0x024776, a
	ld xwa, (xsp + 32)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 32)
	ld xbc, 0x1e0008e
	ld xde, 0xffff0002

AcCtlMsgGrid_OK_DispatchScroll:
	call SendEvent
	jrl AcCtlMsgGrid_ReturnHandled
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	call InheritedProc
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 32)
	ld xbc, 0x1e00050
	ld xde, (xsp + 24)
	call SendEvent
	or xhl, xhl
	jrl z, AcCtlMsgGrid_ScrollUp_AutoScroll
	ld xwa, (xsp + 32)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld ix, hl
	cps ix, 2
	jr nz, AcCtlMsgGrid_ScrollUp_CellNav
	ld xwa, (xsp + 4)
	lda xbc, (xwa + 74)
	ld xde, (xbc)
	ld wa, (xde)
	dec 1, wa
	ld (xde), wa
	cps wa, 0
	jr ge, AcCtlMsgGrid_ScrollUp_PageDec
	ld xwa, (xbc)
	ldw (xwa), 0x1

AcCtlMsgGrid_ScrollUp_PageDec:
	ld xwa, (xbc)
	ld wa, (xwa)
	st8_24 0x024776, a
	ld xwa, (xsp + 32)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 74)
	lda_24 xbc, 0xe80280
	ld wa, (xwa)
	ld_srib3 A, 0x07, 0xe4, 0xe0
	extz wa
	ld de, wa
	extz xde
	add xde, 0xffff0000
	ld xwa, (xsp + 32)
	ld xbc, 0x1e0008e
	call SendEvent
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	jrl AcCtlMsgGrid_ScrollRelease

AcCtlMsgGrid_ScrollUp_CellNav:
	ld wa, ix
	dec 1, wa
	ld de, wa
	extz xde
	add xde, 0xffff0000
	ld xwa, (xsp + 32)
	ld xbc, 0x1c0000e
	call SendEvent
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	jrl AcCtlMsgGrid_ScrollRelease

AcCtlMsgGrid_ScrollUp_AutoScroll:
	ld xwa, (xsp + 32)
	ld xbc, 0x1e00091
	ld xde, (xsp + 24)
	call SendEvent
	or xhl, xhl
	jrl z, AcCtlMsgGrid_ReturnHandled
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 70)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	call ApFuncCall
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	call SetAutoInc
	ld xwa, (xsp + 32)
	ld xbc, 0x1c00017
	ld xde, (xsp + 24)
	call SetDialUp
	ld xwa, (xsp + 32)
	ld xbc, 0x1c00018
	ld xde, (xsp + 24)
	call SetDialDown
	lds wa, 1
	jrl AcCtlMsgGrid_ScrollCommit
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	call InheritedProc
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 32)
	ld xbc, 0x1e00050
	ld xde, (xsp + 24)
	call SendEvent
	or xhl, xhl
	jrl z, AcCtlMsgGrid_ScrollDown_AutoScroll
	ld xwa, (xsp + 32)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld ix, hl
	ld xwa, (xsp + 4)
	lda xde, (xwa + 74)
	ld xbc, (xde)
	lda_24 xhl, 0xe80280
	ld wa, (xbc)
	ld_srib3 A, 0x07, 0xec, 0xe0
	extz wa
	cp wa, ix
	jr nz, AcCtlMsgGrid_ScrollDown_CellNav
	ld wa, (xbc)
	inc 1, wa
	ld (xbc), wa
	cps wa, 1
	jr le, AcCtlMsgGrid_ScrollDown_PageInc
	ld xwa, (xde)
	ldw (xwa), 0x0

AcCtlMsgGrid_ScrollDown_PageInc:
	ld xwa, (xde)
	ld wa, (xwa)
	st8_24 0x024776, a
	ld xwa, (xsp + 32)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 32)
	ld xbc, 0x1e0008e
	ld xde, 0xffff0002
	call SendEvent
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	jr AcCtlMsgGrid_ScrollRelease

AcCtlMsgGrid_ScrollDown_CellNav:
	ld wa, ix
	inc 1, wa
	ld de, wa
	extz xde
	add xde, 0xffff0000
	ld xwa, (xsp + 32)
	ld xbc, 0x1c0000e
	call SendEvent
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)

AcCtlMsgGrid_ScrollRelease:
	call SetAutoInc
	jrl AcCtlMsgGrid_ReturnHandled

AcCtlMsgGrid_ScrollDown_AutoScroll:
	ld xwa, (xsp + 32)
	ld xbc, 0x1e00091
	ld xde, (xsp + 24)
	call SendEvent
	or xhl, xhl
	jrl z, AcCtlMsgGrid_ReturnHandled
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 70)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	call ApFuncCall
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	call SetAutoInc
	ld xwa, (xsp + 32)
	ld xbc, 0x1c00017
	ld xde, (xsp + 24)
	call SetDialUp
	ld xwa, (xsp + 32)
	ld xbc, 0x1c00018
	ld xde, (xsp + 24)
	call SetDialDown
	lds wa, 1

AcCtlMsgGrid_ScrollCommit:
	call SetDialEnable
	jr AcCtlMsgGrid_ReturnHandled

AcCtlMsgGrid_GetColText:
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld xwa, (xhl + 62)
	push xwa
	jr AcCtlMsgGrid_GetRowText_Strcpy

AcCtlMsgGrid_GetRowText:
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld xwa, (xhl + 74)
	ld wa, (xwa)
	cps wa, 1
	jr z, AcCtlMsgGrid_GetRowText_Page1
	cps wa, 0
	jr nz, AcCtlMsgGrid_ReturnHandled
	ld xwa, 0xe80292
	jr AcCtlMsgGrid_GetRowText_Push

AcCtlMsgGrid_GetRowText_Page1:
	ld xwa, 0xe8030e

AcCtlMsgGrid_GetRowText_Push:
	push xwa

AcCtlMsgGrid_GetRowText_Strcpy:
	ld xwa, (xsp + 28)
	push xwa
	call Strcpy
	inc 8, xsp
	jr AcCtlMsgGrid_ReturnHandled
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	jr AcCtlMsgGrid_ForwardToParent

AcCtlMsgGrid_CellSelect:
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)

AcCtlMsgGrid_ForwardToParent:
	call ApFuncCall

AcCtlMsgGrid_ReturnHandled:
	lds32 xhl, 0
	jr AcCtlMsgGrid_Return

AcCtlMsgGrid_ForwardToBase:
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	call InheritedProc

AcCtlMsgGrid_Return:
	pop xiz
	lda xsp, (xsp + 32)
	ret

CtlMsgGridCheck:
	lda xsp, (xsp - 30)
	push xiz
	ld (xsp + 30), xde
	ld xde, xbc
	ld xiy, 0xe803ce
	lda xix, (xsp + 20)
	lds bc, 5
	ldirw
	ld xiy, 0xe7ed44
	lda xix, (xsp + 12)
	lds bc, 4
	ldirw
	ld xix, xde
	lda xhl, (xsp + 12)
	lda_24 xwa, 0xe80386
	ld (xsp + 8), xwa
	lda xbc, (xhl + 2)
	cp xde, 0x1e0008d
	jrl z, MidiSetup_TtlDispatch
	ld xwa, xix
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, CtlMsgGrid_ReturnZero
	cp xwa, 0x6
	jrl gt, CtlMsgGrid_ReturnZero
	add xwa, xwa
	add xwa, 0xe803f0
	ld wa, (xwa)
	lda_24 xix, CtlMsgGridCheck_JumpTable
	jp_dri 8, 0x07, 0xf0, 0xe0

CtlMsgGridCheck_JumpTable:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 31457423
	lds32	xde, 0
	call	SendEvent
	ld	(xsp+30), xhl
	lda	xbc, (xsp+12)
	ld	xwa, (xsp+30)
	srl	xwa, 0
	ld	qwa, 0
	ld	(xbc), wa
	ld	xwa, (xsp+30)
	ld	(xbc+2), wa
	cpw	(xbc), 1
	jrl	nz, 357
	ld	bc, wa
	sla	bc, 2
	ld8_24	a, 149366
	extz	wa
	muls	wa, 36
	ld	de, wa
	add	de, bc
	lda_24	xwa, 15205254
	ld_rrl	xwa, xwa, de
	lds	bc, 1
	lds	de, 2
	jr	82
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 31457423
	lds32	xde, 0
	call	SendEvent
	ld	(xsp+30), xhl
	lda	xbc, (xsp+12)
	ld	xwa, (xsp+30)
	srl	xwa, 0
	ld	qwa, 0
	ld	(xbc), wa
	ld	xwa, (xsp+30)
	ld	(xbc+2), wa
	cpw	(xbc), 1
	jrl	nz, 274
	ld	bc, wa
	sla	bc, 2
	ld8_24	a, 149366
	extz	wa
	muls	wa, 36
	ld	de, wa
	add	de, bc
	lda_24	xwa, 15205254
	ld_rrl	xwa, xwa, de
	ldw	bc, 65535
	lds	de, 2
	.byte 0x1d, 0x42, 0xf9
	.long Bitmap_AccompBitmapSpacer
	ld	(xsp+4), xhl
	ldw	(xhl), 1
	ld	xde, xbc
	ldw	(xbc), 0
	ld8_24	a, 149366
	extz	wa
	muls	wa, 36
	ld	ix, wa
	ld	xhl, (xsp+8)
	ld	xiz, (xsp+30)
	jr	75
	ld	wa, bc
	sla	wa, 2
	ld	iy, ix
	add	iy, wa
	ld	xwa, (xiz)
	.byte 0xe3, 0x07, 0xec, 0xf4, 0xf0
	jr	nz, 53
	lda	xde, (xsp+20)
	ld	xwa, (xsp+4)
	ld	(xwa+4), xde
	ld	xbc, 15205342
	ld	xwa, (xsp+30)
	cpw	(xwa+4), 0
	jr	z, 5
	ld	xbc, 15205336
	push	xbc
	push	xde
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, 31457420
	jr	123
	inc	1, bc
	ld	(xde), bc
	ld	bc, (xde)
	cp	bc, 9
	jr	lt, -83
	jr	113

; MidiSetup title dispatch
MidiSetup_TtlDispatch:
	ld xwa, (xsp + 30)
	srl xwa, 0
	ldi_werp 0xe2, 0
	ld (xhl), wa
	ld xde, xbc
	ld xwa, (xsp + 30)
	ld (xbc), wa
	lda xwa, (xsp + 20)
	ld (xhl + 4), xwa
	cpw (xhl), 0x1
	jr nz, CtlMsgGrid_ReturnZero
	ld de, (xde)
	sla de, 2
	ld8_24 a, 0x024776
	extz wa
	muls wa, 0x24
	ld bc, wa
	add bc, de
	ld xwa, (xsp + 8)
	ld_sril3 XWA, 0x07, 0xe0, 0xe4
	cp xwa, 0xffffffff
	jr z, CtlMsgGrid_ReturnZero
	call SndParam_LookupReadOnly
	lda xbc, (xsp + 20)
	ld xwa, 0xe803ea
	cps hl, 0
	jr z, MidiSetup_CopyStrAndDispatch
	ld xwa, 0xe803e4

MidiSetup_CopyStrAndDispatch:
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 12)
	ld xbc, 0x1e0008c
	call SendEvent

CtlMsgGrid_ReturnZero:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 30)
	ret

TtMdPart:
	cp xbc, 0x1c0000c
	jr z, TtMdPart_ReturnZero
	cp xbc, 0x1c0000b
	jr z, TtMdPart_ReturnZero
	cp xbc, 0x1c00002
	jr z, MidiSetup_TtlCase1
	cp xbc, 0x1c00001
	jr nz, TtMdPart_ReturnZero
	or xde, xde
	jr nz, TtMdPart_ReturnZero
	sti8_24 0x024778, 0x00
	ld xwa, 0x510001
	call GetViewInstance
	ld xwa, (xhl + 42)
	ldw (xwa), 0x2
	ld xwa, (xhl + 46)
	ldw (xwa), 0x1
	ld xwa, 0x1400002
	ld xbc, 0x1e000a0
	lds32 xde, 0
	jr MidiSetup_TtlCase2

; MidiSetup title case 1
MidiSetup_TtlCase1:
	or xde, xde
	jr nz, TtMdPart_ReturnZero
	ld xwa, 0x1400002
	ld xbc, 0x1e000a0
	ld xde, 0x3f

; MidiSetup title case 2
MidiSetup_TtlCase2:
	call MainFuncCall

TtMdPart_ReturnZero:
	lds32 xhl, 0
	ret

AcMidiPartGridBoxProc:
	lda xsp, (xsp - 32)
	push xiz
	ld (xsp + 24), xde
	ld (xsp + 28), xbc
	ld (xsp + 32), xwa
	ld xiy, 0xe80446
	lda xix, (xsp + 8)
	ldw bc, 0x8
	ldirw
	ld xbc, (xsp + 28)
	cp xbc, 0x1e0008d
	jrl z, MidiSetup_GridBoxCase2
	ld xwa, (xsp + 28)
	cp xwa, 0x1e0008b
	jrl z, MidiSetup_GridBoxCase1
	cp xwa, 0x1e0008a
	jrl z, MidiSetup_GridBoxDispatch
	cp xwa, 0x1c00007
	jrl z, MidiSetup_TtlCase5
	cp xwa, 0x1c0000b
	jrl z, MidiSetup_TtlCase4
	cp xwa, 0x1c00001
	jr z, MidiSetup_TtlCase3
	sub xbc, 0x1c00017
	cp xbc, 0x0
	jrl lt, MidiSetup_GridBoxCase4
	cp xbc, 0x6
	jrl gt, MidiSetup_GridBoxCase4
	add xbc, xbc
	add xbc, 0xe80512
	ld bc, (xbc)
	lda_24 xix, MidiSetup_TtlCase3
	jp_dri 8, 0x07, 0xf0, 0xe4

; MidiSetup title case 3
MidiSetup_TtlCase3:
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	call InheritedProc
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xbc, (xwa + 74)
	ld8_24 a, 0x024778
	extz wa
	ld (xbc), wa
	ld xwa, (xsp + 32)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld xiz, xhl
	ld xwa, (xsp + 4)
	ld bc, (xwa + 26)
	ld xwa, xiz
	srl xwa, 0
	ldi_werp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 32)
	ld xbc, 0x1c00017
	call SetDialUp
	ld xwa, (xsp + 4)
	ld bc, (xwa + 26)
	ld xwa, xiz
	srl xwa, 0
	ldi_werp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 32)
	ld xbc, 0x1c00018
	call SetDialDown
	lds wa, 1
	jrl MidiPart_SetDialEnable

; MidiSetup title case 4
MidiSetup_TtlCase4:
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	call InheritedProc
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, 0xe7ecf2
	ldw bc, 0xc1
	ldw de, 0xf3
	call DrawDesignBox
	ld xwa, (xiz + 74)
	ld wa, (xwa)
	sla wa, 2
	lda_24 xbc, 0xe7ed1a
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	lda xwa, (xsp + 12)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xde, (xsp + 8)
	lds32 xwa, 0
	push xwa
	pushw 0x0
	pushw 0xf7
	ld xwa, 0xe7ecf2
	ld xbc, 0xe7ecfa
	call DrawStringCentered
	jrl MidiPart_ReturnZeroJmp

; MidiSetup title case 5
MidiSetup_TtlCase5:
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	call InheritedProc
	ld xwa, (xsp + 32)
	call GetViewInstance
	lda xbc, (xhl + 74)
	ld xwa, (xsp + 24)
	cp xwa, 0x90
	jr z, MidiPart_DecrementPart
	cp xwa, 0x10
	jrl nz, MidiPart_ReturnZeroJmp
	ld xde, xbc
	ld xbc, (xbc)
	ld wa, (xbc)
	inc 1, wa
	ld (xbc), wa
	cps wa, 2
	jr le, MidiPart_StorePartIndex
	ld xwa, (xde)
	ldw (xwa), 0x0

MidiPart_StorePartIndex:
	ld xwa, (xde)
	ld wa, (xwa)
	st8_24 0x024778, a
	ld xwa, (xsp + 32)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 32)
	ld xbc, 0x1e0008e
	ld xde, 0xffff0002
	call SendEvent
	ld8_24 a, 0x024778
	extz wa
	muls wa, 0xa
	lda_24 xbc, 0xe80400
	lds32 xde, 0
	ld_srib3 E, 0x07, 0xe4, 0xe0
	ld xwa, 0x1400002
	ld xbc, 0x1e000a0
	jr MidiPart_CallMainFunc

MidiPart_DecrementPart:
	ld xde, xbc
	ld xbc, (xbc)
	ld wa, (xbc)
	dec 1, wa
	ld (xbc), wa
	cps wa, 0
	jr ge, MidiPart_StoreAndNotify
	ld xwa, (xde)
	ldw (xwa), 0x2

MidiPart_StoreAndNotify:
	ld xwa, (xde)
	ld wa, (xwa)
	st8_24 0x024778, a
	ld xwa, (xsp + 32)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 32)
	ld xbc, 0x1e0008e
	ld xde, 0xffff0002
	call SendEvent
	ld8_24 a, 0x024778
	extz wa
	muls wa, 0xa
	lda_24 xbc, 0xe80400
	lds32 xde, 0
	ld_srib3 E, 0x07, 0xe4, 0xe0
	ld xwa, 0x1400002
	ld xbc, 0x1e000a0

MidiPart_CallMainFunc:
	call MainFuncCall
	jrl MidiPart_ReturnZeroJmp
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	call InheritedProc
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 32)
	ld xbc, 0x1e00050
	ld xde, (xsp + 24)
	call SendEvent
	or xhl, xhl
	jrl z, MidiPart_SendShowQuery
	ld xwa, (xsp + 32)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld iz, hl
	cps iz, 2
	jrl nz, MidiPart_Part2ColumnNav
	ld xwa, (xsp + 4)
	lda xbc, (xwa + 74)
	ld xde, (xbc)
	ld wa, (xde)
	dec 1, wa
	ld (xde), wa
	cps wa, 0
	jr ge, MidiPart_AutoDec_StorePart
	ld xwa, (xbc)
	ldw (xwa), 0x2

MidiPart_AutoDec_StorePart:
	ld xwa, (xbc)
	ld wa, (xwa)
	st8_24 0x024778, a
	ld xwa, (xsp + 32)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 74)
	lda_24 xbc, 0xe80442
	ld wa, (xwa)
	ld_srib3 A, 0x07, 0xe4, 0xe0
	extz wa
	ld de, wa
	extz xde
	add xde, 0xffff0000
	ld xwa, (xsp + 32)
	ld xbc, 0x1e0008e
	call SendEvent
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 74)
	lda_24 xbc, 0xe80442
	ld wa, (xwa)
	ld_srib3 C, 0x07, 0xe4, 0xe0
	extz bc
	ld8_24 a, 0x024778
	extz wa
	muls wa, 0xa
	add wa, bc
	lda_24 xbc, 0xe803fe
	lds32 xde, 0
	ld_srib3 E, 0x07, 0xe4, 0xe0
	ld xwa, 0x1400002
	ld xbc, 0x1e000a0
	call MainFuncCall
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	jrl MidiPartAutoIncReturn

MidiPart_Part2ColumnNav:
	cpi8_24 0x024778, 0x02
	jr nz, MidiPart_GenericColumnNav
	ld wa, iz
	add wa, wa
	lda_24 xbc, 0xe8041c
	ld_sriw3 WA, 0x07, 0xe4, 0xe0
	ld bc, iz
	sub bc, wa
	ld de, bc
	extz xde
	add xde, 0xffff0000
	ld xwa, (xsp + 32)
	ld xbc, 0x1c0000e
	call SendEvent
	ld wa, iz
	add wa, wa
	lda_24 xbc, 0xe8041c
	ld_sriw3 WA, 0x07, 0xe4, 0xe0
	ld bc, iz
	sub bc, wa
	ld8_24 a, 0x024778
	extz wa
	muls wa, 0xa
	add wa, bc
	lda_24 xbc, 0xe803fe
	lds32 xde, 0
	ld_srib3 E, 0x07, 0xe4, 0xe0
	ld xwa, 0x1400002
	ld xbc, 0x1e000a0
	jr MidiPart_CallMainFuncSetAuto

MidiPart_GenericColumnNav:
	ld wa, iz
	dec 1, wa
	ld de, wa
	extz xde
	add xde, 0xffff0000
	ld xwa, (xsp + 32)
	ld xbc, 0x1c0000e
	call SendEvent
	ld bc, iz
	dec 1, bc
	ld8_24 a, 0x024778
	extz wa
	muls wa, 0xa
	add wa, bc
	lda_24 xbc, 0xe803fe
	lds32 xde, 0
	ld_srib3 E, 0x07, 0xe4, 0xe0
	ld xwa, 0x1400002
	ld xbc, 0x1e000a0

MidiPart_CallMainFuncSetAuto:
	call MainFuncCall
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	jrl MidiPartAutoIncReturn

MidiPart_SendShowQuery:
	ld xwa, (xsp + 32)
	ld xbc, 0x1e00091
	ld xde, (xsp + 24)
	call SendEvent
	or xhl, xhl
	jr z, MidiPart_InitGridBox
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 70)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	call ApFuncCall
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	call SetAutoInc
	ld xwa, (xsp + 32)
	ld xbc, 0x1c00017
	ld xde, (xsp + 24)
	call SetDialUp
	ld xwa, (xsp + 32)
	ld xbc, 0x1c00018
	ld xde, (xsp + 24)
	call SetDialDown
	lds wa, 1
	jrl MidiPart_SetDialEnable

MidiPart_InitGridBox:
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	call InheritedProc
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 32)
	ld xbc, 0x1e00050
	ld xde, (xsp + 24)
	call SendEvent
	or xhl, xhl
	jrl z, MidiPart_SendShowQueryUp
	ld xwa, (xsp + 32)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld iz, hl
	cp iz, 0x9
	jr nz, MidiPart_Part2ColumnNavUp
	ld xwa, (xsp + 4)
	lda xbc, (xwa + 74)
	ld xde, (xbc)
	ld wa, (xde)
	inc 1, wa
	ld (xde), wa
	cps wa, 2
	jr le, MidiPart_AutoInc_StorePart
	ld xwa, (xbc)
	ldw (xwa), 0x0

MidiPart_AutoInc_StorePart:
	ld xwa, (xbc)
	ld wa, (xwa)
	st8_24 0x024778, a
	ld xwa, (xsp + 32)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 32)
	ld xbc, 0x1e0008e
	ld xde, 0xffff0002
	call SendEvent
	ld8_24 a, 0x024778
	extz wa
	muls wa, 0xa
	lda_24 xbc, 0xe80400
	lds32 xde, 0
	ld_srib3 E, 0x07, 0xe4, 0xe0
	ld xwa, 0x1400002
	ld xbc, 0x1e000a0
	call MainFuncCall
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	jrl MidiPartAutoIncReturn

MidiPart_Part2ColumnNavUp:
	cpi8_24 0x024778, 0x02
	jr nz, MidiPart_GenericColumnNavUp
	ld wa, iz
	add wa, wa
	lda_24 xbc, 0xe8042e
	ld_sriw3 WA, 0x07, 0xe4, 0xe0
	add wa, iz
	ld de, wa
	extz xde
	add xde, 0xffff0000
	ld xwa, (xsp + 32)
	ld xbc, 0x1c0000e
	call SendEvent
	ld wa, iz
	add wa, wa
	lda_24 xbc, 0xe8042e
	ld_sriw3 BC, 0x07, 0xe4, 0xe0
	add bc, iz
	ld8_24 a, 0x024778
	extz wa
	muls wa, 0xa
	add wa, bc
	lda_24 xbc, 0xe803fe
	lds32 xde, 0
	ld_srib3 E, 0x07, 0xe4, 0xe0
	ld xwa, 0x1400002
	ld xbc, 0x1e000a0
	jr MidiPart_CallMainFuncAutoUp

MidiPart_GenericColumnNavUp:
	ld wa, iz
	inc 1, wa
	ld de, wa
	extz xde
	add xde, 0xffff0000
	ld xwa, (xsp + 32)
	ld xbc, 0x1c0000e
	call SendEvent
	ld bc, iz
	inc 1, bc
	ld8_24 a, 0x024778
	extz wa
	muls wa, 0xa
	add wa, bc
	lda_24 xbc, 0xe803fe
	lds32 xde, 0
	ld_srib3 E, 0x07, 0xe4, 0xe0
	ld xwa, 0x1400002
	ld xbc, 0x1e000a0

MidiPart_CallMainFuncAutoUp:
	call MainFuncCall
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)

MidiPartAutoIncReturn:
	call SetAutoInc
	jrl MidiPart_ReturnZeroJmp

MidiPart_SendShowQueryUp:
	ld xwa, (xsp + 32)
	ld xbc, 0x1e00091
	ld xde, (xsp + 24)
	call SendEvent
	or xhl, xhl
	jr z, MidiSetup_GridBoxDispatch
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 70)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	call ApFuncCall
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	call SetAutoInc
	ld xwa, (xsp + 32)
	ld xbc, 0x1c00017
	ld xde, (xsp + 24)
	call SetDialUp
	ld xwa, (xsp + 32)
	ld xbc, 0x1c00018
	ld xde, (xsp + 24)
	call SetDialDown
	lds wa, 1

MidiPart_SetDialEnable:
	call SetDialEnable
	jr MidiPart_ReturnZeroJmp

; MidiSetup grid box dispatch
MidiSetup_GridBoxDispatch:
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld xwa, (xhl + 62)
	push xwa
	jr MidiSetup_CopyStrAndReturn

; MidiSetup grid box case 1
MidiSetup_GridBoxCase1:
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld xwa, (xhl + 74)
	ld wa, (xwa)
	cps wa, 2
	jr z, MidiSetup_GridStr2
	cps wa, 1
	jr z, MidiSetup_GridStr1
	cps wa, 0
	jr nz, MidiPart_ReturnZeroJmp
	ld xwa, 0xe80456
	jr MidiSetup_PushGridStr

MidiSetup_GridStr1:
	ld xwa, 0xe80492
	jr MidiSetup_PushGridStr

MidiSetup_GridStr2:
	ld xwa, 0xe804d4

MidiSetup_PushGridStr:
	push xwa

MidiSetup_CopyStrAndReturn:
	ld xwa, (xsp + 28)
	push xwa
	call Strcpy
	inc 8, xsp
	jr MidiPart_ReturnZeroJmp
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	jr MidiSetup_GridBoxCase3

; MidiSetup grid box case 2
MidiSetup_GridBoxCase2:
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)

; MidiSetup grid box case 3
MidiSetup_GridBoxCase3:
	call ApFuncCall

MidiPart_ReturnZeroJmp:
	lds32 xhl, 0
	jr MidiSetup_GridBoxCase5

; MidiSetup grid box case 4
MidiSetup_GridBoxCase4:
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	call InheritedProc

; MidiSetup grid box case 5
MidiSetup_GridBoxCase5:
	pop xiz
	lda xsp, (xsp + 32)
	ret

MidiPartGridCheck:
	lda xsp, (xsp - 38)
	push xiz
	ld (xsp + 34), xde
	ld (xsp + 38), xbc
	ld xiy, 0xe806b0
	lda xix, (xsp + 24)
	lds bc, 5
	ldirw
	ld xiy, 0xe7ed44
	lda xix, (xsp + 16)
	lds bc, 4
	ldirw
	ld xix, (xsp + 38)
	lda xhl, (xsp + 24)
	lda xiy, (xsp + 16)
	lda xbc, (xiy + 2)
	lda xde, (xiy + 4)
	ld xwa, (xsp + 38)
	cp xwa, 0x1e0008d
	jrl z, MidiSetup_EventHandler
	ld xwa, xix
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, MidiSetup_ReturnZero
	cp xwa, 0x6
	jrl gt, MidiSetup_ReturnZero
	add xwa, xwa
	add xwa, 0xe806fc
	ld wa, (xwa)
	lda_24 xix, MidiPartGridCheck_JumpTable
	jp_dri 8, 0x07, 0xf0, 0xe0

MidiPartGridCheck_JumpTable:
	.byte 0x1d, 0xd0, 0x44, 0xfa, 0xeb, 0x88, 0x41, 0x8f
	.byte 0x00, 0xe0, 0x01, 0xea, 0xa8, 0x1d, 0x60, 0x96
	.byte 0xfa, 0xbf, 0x22, 0x63, 0xbf, 0x10, 0x31, 0xaf
	.byte 0x22, 0x20, 0xe8, 0xef, 0x00, 0xd7, 0xe2, 0xa8
	.byte 0xb1, 0x50, 0xaf, 0x22, 0x20, 0xb9, 0x02, 0x50
	.byte 0xd8, 0x09, 0x0c, 0x00, 0xd8, 0x8a, 0xda, 0xca
	.byte 0x18, 0x00, 0xc2, 0x78, 0x47, 0x02, 0x21, 0xd8
	.byte 0x12, 0xd8, 0x09, 0x60, 0x00, 0xd8, 0x8b, 0xda
	.byte 0x83, 0x91, 0x20, 0xd8, 0xec, 0x02, 0xd8, 0x6c
	.byte 0xd8, 0x8a, 0xdb, 0x82, 0xf2, 0x20, 0x05, 0xe8
	.byte 0x30, 0xe3, 0x07, 0xe0, 0xe8, 0x20, 0xbf, 0x0c
	.byte 0x60, 0x91, 0x20, 0xd8, 0xdb, 0x66, 0x7b, 0xd8
	.byte 0xda, 0x66, 0x55, 0xd8, 0xd9, 0x7e, 0x06, 0x04
	.byte 0xaf, 0x0c, 0x20, 0xe8, 0x61, 0x1d, 0x37, 0xd4
	.byte 0xfc, 0xdb, 0xd8, 0x6e, 0x24, 0xaf, 0x0c, 0x20
	.byte 0xe8, 0x61, 0xd9, 0xa9, 0xda, 0xaa, 0x1d, 0x8a
	.byte 0xf8, 0xf9, 0xaf, 0x0c, 0x20, 0xe8, 0x62, 0xd9
	.byte 0xa9, 0xda, 0xaa, 0x1d, 0x8a, 0xf8, 0xf9, 0xaf
	.byte 0x0c, 0x20, 0xd9, 0xa8, 0xda, 0xaa, 0x78, 0x30
	.byte 0x01, 0xaf, 0x26, 0x20, 0xe8, 0xcf, 0x19, 0x00
	.byte 0xc0, 0x01, 0x6e, 0x0a, 0xaf, 0x0c, 0x20, 0xd9
	.byte 0xac, 0xda, 0xaa, 0x78, 0xec, 0x00, 0xaf, 0x0c
	.byte 0x20, 0xd9, 0xa9, 0xda, 0xaa, 0x78, 0xe2, 0x00
	.byte 0xaf, 0x0c, 0x20, 0x1d, 0x37, 0xd4, 0xfc, 0xdb
	.byte 0x88, 0xd8, 0x80, 0xf2, 0x40, 0x06, 0xe8, 0x31
	.byte 0xd3, 0x07, 0xe4, 0xe0, 0x21, 0xdb, 0xf1, 0x76
	.byte 0x9c, 0x03, 0xaf, 0x0c, 0x20, 0xda, 0xaa, 0x78
	.byte 0xef, 0x00, 0xaf, 0x0c, 0x20, 0xd9, 0xa9, 0xda
	.long NakaInst_MidiPresetConfig
	.byte 0x1d, 0xd0, 0x44, 0xfa
	.byte 0xeb, 0x88, 0x41, 0x8f, 0x00, 0xe0, 0x01, 0xea
	.byte 0xa8, 0x1d, 0x60, 0x96, 0xfa, 0xbf, 0x22, 0x63
	.byte 0xbf, 0x10, 0x31, 0xaf, 0x22, 0x20, 0xe8, 0xef
	.byte 0x00, 0xd7, 0xe2, 0xa8, 0xb1, 0x50, 0xaf, 0x22
	.byte 0x20, 0xb9, 0x02, 0x50, 0xd8, 0x09, 0x0c, 0x00
	.byte 0xd8, 0x8a, 0xda, 0xca, 0x18, 0x00, 0xc2, 0x78
	.byte 0x47, 0x02, 0x21, 0xd8, 0x12, 0xd8, 0x09, 0x60
	.byte 0x00, 0xd8, 0x8b, 0xda, 0x83, 0x91, 0x20, 0xd8
	.byte 0xec, 0x02, 0xd8, 0x6c, 0xd8, 0x8a, 0xdb, 0x82
	.byte 0xf2, 0x20, 0x05, 0xe8, 0x30, 0xe3, 0x07, 0xe0
	.byte 0xe8, 0x20, 0xbf, 0x0c, 0x60, 0x91, 0x20, 0xd8
	.byte 0xdb, 0x66, 0x7f, 0xd8, 0xda, 0x66, 0x5a, 0xd8
	.byte 0xd9, 0x7e, 0x22, 0x03, 0xaf, 0x0c, 0x20, 0xe8
	.byte 0x61, 0x1d, 0x37, 0xd4, 0xfc, 0xdb, 0xd9, 0x7e
	.byte 0x14, 0x03, 0xaf, 0x0c, 0x20, 0x1d, 0x37, 0xd4
	.byte 0xfc, 0xdb, 0xd8, 0x6e, 0x18, 0xaf, 0x0c, 0x20
	.byte 0xe8, 0x61, 0xd9, 0xa8, 0xda, 0xaa, 0x1d, 0x8a
	.byte 0xf8, 0xf9, 0xaf, 0x0c, 0x20, 0xe8, 0x62, 0xd9
	.byte 0xa8, 0xda, 0xaa, 0x68, 0x4c, 0xaf, 0x26, 0x20
	.byte 0xe8, 0xcf, 0x1a, 0x00, 0xc0, 0x01, 0x6e, 0x0a
	.byte 0xaf, 0x0c, 0x20, 0x31, 0xfc, 0xff, 0xda, 0xaa
	.byte 0x68, 0x08, 0xaf, 0x0c, 0x20, 0x31, 0xff, 0xff
	.byte 0xda, 0xaa, 0x1d, 0x42, 0xf9, 0xf9, 0x78, 0xcd
	.byte 0x02, 0xaf, 0x0c, 0x20, 0x1d, 0x37, 0xd4, 0xfc
	.byte 0xdb, 0x88, 0xd8, 0x80, 0xf2, 0x50, 0x06, 0xe8
	.byte 0x31, 0xd3, 0x07, 0xe4, 0xe0, 0x21, 0xdb, 0xf1
	.byte 0x76, 0xb3, 0x02, 0xaf, 0x0c, 0x20, 0xda, 0xaa
	.byte 0x68, 0x07, 0xaf, 0x0c, 0x20, 0xd9, 0xa8, 0xda
	.byte 0xaa, 0x1d, 0x8a, 0xf8, 0xf9, 0x78, 0x9e, 0x02
	.byte 0xaf, 0x22, 0x24, 0xbf, 0x04, 0x65, 0xbf, 0x08
	.byte 0x63, 0xb2, 0x63, 0xbf, 0x0c, 0x61, 0xb1, 0x02
	.byte 0x02, 0x00, 0x78, 0x58, 0x01, 0xd9, 0x8a, 0xda
	.byte 0x09, 0x0c, 0x00, 0xda, 0xca, 0x18, 0x00, 0xc2
	.byte 0x78, 0x47, 0x02, 0x21, 0xd8, 0x12, 0xd8, 0x09
	.byte 0x60, 0x00, 0xd8, 0x8d, 0xda, 0x85, 0xf2, 0x20
	.byte 0x05, 0xe8, 0x33, 0xe3, 0x07, 0xec, 0xf4, 0x26
	.byte 0xaf, 0x22, 0x22, 0xa2, 0xfe, 0x6e, 0x50, 0xaf
	.byte 0x04, 0x20, 0xb0, 0x02, 0x01, 0x00, 0xa2, 0x20
	.byte 0xe8, 0x61, 0x1d, 0x37, 0xd4, 0xfc, 0xdb, 0xd8
	.byte 0x6e, 0x12, 0x0b, 0xe8, 0x00, 0x0b, 0xba, 0x06
	.byte 0xbf, 0x1c, 0x30, 0x38, 0x1d, 0x3f, 0x0f, 0xff
	.byte 0xef, 0x60, 0x68, 0x1a, 0xaf, 0x22, 0x20, 0x98
	.byte 0x04, 0x20, 0xd8, 0x61, 0x28, 0x0b, 0xe8, 0x00
	.byte 0x0b, 0xc0, 0x06, 0xbf, 0x1e, 0x30, 0x38, 0x1d
	.byte 0x64, 0x0a, 0xff, 0xbf, 0x0a, 0x37, 0x1d, 0xd0
	.byte 0x44, 0xfa, 0xeb, 0x88, 0xbf, 0x10, 0x32, 0x41
	.byte 0x8c, 0x00, 0xe0, 0x01, 0x78, 0x0b, 0x02, 0xa4
	.byte 0x20, 0xe8, 0x69, 0xbc, 0x04, 0x32, 0xee, 0xf0
	.byte 0x6e, 0x4f, 0xaf, 0x04, 0x20, 0xb0, 0x02, 0x01
	.byte 0x00, 0x92, 0x3f, 0x00, 0x00, 0x6e, 0x12, 0x0b
	.byte 0xe8, 0x00, 0x0b, 0xc8, 0x06, 0xaf, 0x0c, 0x20
	.byte 0x38, 0x1d, 0x3f, 0x0f, 0xff, 0xef, 0x60, 0x68
	.byte 0x1f, 0xaf, 0x22, 0x20, 0xa0, 0x20, 0xe8, 0x69
	.byte 0x1d, 0x37, 0xd4, 0xfc, 0xdb, 0x61, 0x2b, 0x0b
	.byte 0xe8, 0x00, 0x0b, 0xce, 0x06, 0xbf, 0x1e, 0x30
	.byte 0x38, 0x1d, 0x64, 0x0a, 0xff, 0xbf, 0x0a, 0x37
	.byte 0x1d, 0xd0, 0x44, 0xfa, 0xeb, 0x88, 0xbf, 0x10
	.byte 0x32, 0x41, 0x8c, 0x00, 0xe0, 0x01, 0x78, 0xb1
	.byte 0x01, 0xdd, 0x8e, 0xde, 0x64, 0xa4, 0x20, 0xe3
	.byte 0x07, 0xec, 0xf8, 0xf0, 0x6e, 0x32, 0xaf, 0x04
	.byte 0x20, 0xb0, 0x02, 0x02, 0x00, 0x92, 0x20, 0xd8
	.byte 0xec, 0x02, 0xf2, 0x60, 0x06, 0xe8, 0x31, 0xe3
	.byte 0x07, 0xe4, 0xe0, 0x20, 0x38, 0xaf, 0x0c, 0x20
	.byte 0x38, 0x1d, 0x3f, 0x0f, 0xff, 0xef, 0x60, 0x1d
	.byte 0xd0, 0x44, 0xfa, 0xeb, 0x88, 0xbf, 0x10, 0x32
	.byte 0x41, 0x8c, 0x00, 0xe0, 0x01, 0x78, 0x72, 0x01
	.byte 0xdd, 0x60, 0xa4, 0x20, 0xe3, 0x07, 0xec, 0xf4
	.byte 0xf0, 0x6e, 0x33, 0xaf, 0x04, 0x20, 0xb0, 0x02
	.byte 0x03, 0x00, 0x40, 0xdc, 0x06, 0xe8, 0x00, 0x92
	.byte 0x3f, 0x00, 0x00, 0x66, 0x05, 0x40, 0xd6, 0x06
	.byte 0xe8, 0x00, 0x38, 0xaf, 0x0c, 0x20, 0x38, 0x1d
	.byte 0x3f, 0x0f, 0xff, 0xef, 0x60, 0x1d, 0xd0, 0x44
	.byte 0xfa, 0xeb, 0x88, 0xbf, 0x10, 0x32, 0x41, 0x8c
	.byte 0x00, 0xe0, 0x01, 0x78, 0x34, 0x01, 0xd9, 0x61
	.byte 0xaf, 0x0c, 0x20, 0xb0, 0x51, 0xaf, 0x0c, 0x20
	.byte 0x90, 0x21, 0xd9, 0xcf, 0x0a, 0x00, 0x71, 0x9c
	.byte 0xfe, 0x78, 0x22, 0x01

; MidiSetup event handler dispatch (6-entry, table 0xe806fc)
MidiSetup_EventHandler:
	ld xwa, (xsp + 34)
	srl xwa, 0
	ldi_werp 0xe2, 0
	ld (xiy), wa
	ld xwa, (xsp + 34)
	ld (xbc), wa
	ld (xde), xhl
	ld de, (xiy)
	ld bc, (xbc)
	muls bc, 0xc
	sub bc, 0x18
	ld8_24 a, 0x024778
	extz wa
	muls wa, 0x60
	add wa, bc
	cps de, 3
	jrl z, MidiPart_LookupFromTable
	lda_24 xbc, 0xe80520
	cps de, 2
	jr z, MidiPart_LookupColumnParam
	cps de, 1
	jrl nz, MidiSetup_ReturnZero
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld (xsp + 12), xwa
	cp xwa, 0xffffffff
	jrl z, MidiSetup_ReturnZero
	ld xwa, (xsp + 12)
	inc 1, xwa
	call SndParam_LookupReadOnly
	cps hl, 0
	jr nz, MidiPart_AudioCmdDisplay
	pushw 0xe8
	pushw 0x6e2
	lda xwa, (xsp + 28)
	push xwa
	call Strcpy
	inc 8, xsp
	jr MidiPart_GridDispatchEvent

MidiPart_AudioCmdDisplay:
	ld xwa, (xsp + 12)
	call SndParam_LookupReadOnly
	inc 1, hl
	pushw hl
	pushw 0xe8
	pushw 0x6e8
	lda xwa, (xsp + 30)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)

MidiPart_GridDispatchEvent:
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 16)
	ld xbc, 0x1e0008c
	jrl MidiPart_SendEventReturn

MidiPart_LookupColumnParam:
	inc 4, wa
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld (xsp + 12), xwa
	cp xwa, 0xffffffff
	jr z, MidiSetup_ReturnZero
	ld xwa, (xsp + 12)
	call SndParam_LookupReadOnly
	sla hl, 2
	lda_24 xwa, 0xe80660
	ld_sril3 XWA, 0x07, 0xe0, 0xec
	push xwa
	lda xwa, (xsp + 28)
	push xwa
	call Strcpy
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 16)
	ld xbc, 0x1e0008c
	jr MidiPart_SendEventReturn

MidiPart_LookupFromTable:
	lda_24 xbc, 0xe80528
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld (xsp + 12), xwa
	cp xwa, 0xffffffff
	jr z, MidiSetup_ReturnZero
	ld xwa, (xsp + 12)
	call SndParam_LookupReadOnly
	ld xwa, 0xe806f6
	cps hl, 0
	jr z, MidiPart_CopyParamStr
	ld xwa, 0xe806f0

MidiPart_CopyParamStr:
	push xwa
	lda xwa, (xsp + 28)
	push xwa
	call Strcpy
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 16)
	ld xbc, 0x1e0008c

MidiPart_SendEventReturn:
	call SendEvent

MidiSetup_ReturnZero:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 38)
	ret

MidiPart_DataBlock:
	.byte 0xc1, 0x80, 0xc0
	push	xsp
	cp	(xwa-80), xiz
	.byte 0xc1
	jrl	pl, 16320
	halt
	ret	nz
	ldda8	c, 49279
	bit	6, c
	ret	z
	ldda8	a, 49278
	and	a, c
	ret	z
	.byte 0xc1
	push	xwa
	.byte 0x8d
	push	xsp
	retd	63152
	ldw	wa, 15
	call	SoundCtrl_SendCommand
	ret

InitializeMurai:
	lda xsp, (xsp - 14)

	RegObjTable 0x1600004, 0xfa44e2, 0xe812e2, 0xe80cf6, 0x161
	RegObjTable 0x160000c, 0xfa58fb, 0xe813a4, 0xe812e4, 0x1c1
	RegObjTable 0x160000d, 0xfa5948, 0xe814f2, 0xe813a6, 0x1e1
	RegObjTabl 0x1600002, 0xfa496c, 0x2c, 0xe8070a, 0x121
	RegObjTabl 0x1600002, 0xfa496c, 0x2c, 0xe807be, 0x421
	RegObjTabl 0x1600001, 0xfa48a9, 0x25, 0xe814f4, 0x101
	RegObjTabl 0x1600001, 0xfa48a9, 0x25, 0xe8158c, 0x401
	RegObjTabl 0x1600003, 0xfa4a18, 0x2, 0xe86638, 0x141
	RegObjTabl 0x1600003, 0xfa4a18, 0x2, 0xe86644, 0x441
	RegObjTabl 0x1600010, 0xfa5995, 0x14, 0xe85470, 0x2
	RegObjTabl 0x160000f, 0xfa62cb, 0x14, 0xe859f4, 0x302
	RegObjTabl 0x1600010, 0xfa5995, 0x54, 0xe854c4, 0x3
	RegObjTabl 0x160000f, 0xfa62cb, 0x54, 0xe85a8e, 0x303
	RegObjTabl 0x1600010, 0xfa5995, 0x4, 0xe85618, 0x4
	RegObjTabl 0x160000f, 0xfa62cb, 0x4, 0xe85cf0, 0x304
	RegObjTabl 0x1600010, 0xfa5995, 0x36, 0xe8562c, 0x5
	RegObjTabl 0x160000f, 0xfa62cb, 0x36, 0xe85d14, 0x305
	RegObjTabl 0x1600010, 0xfa5995, 0x3, 0xe85708, 0x7
	RegObjTabl 0x160000f, 0xfa62cb, 0x3, 0xe85f0a, 0x307
	RegObjTabl 0x1600010, 0xfa5995, 0x4, 0xe85718, 0x8
	RegObjTabl 0x160000f, 0xfa62cb, 0x4, 0xe85f2a, 0x308
	RegObjTabl 0x1600010, 0xfa5995, 0x1d, 0xe8572c, 0xd
	RegObjTabl 0x160000f, 0xfa62cb, 0x1d, 0xe85f4e, 0x30d
	RegObjTabl 0x1600010, 0xfa5995, 0x4, 0xe857a4, 0xa5
	RegObjTabl 0x160000f, 0xfa62cb, 0x4, 0xe8608e, 0x3a5
	RegObjTabl 0x1600010, 0xfa5995, 0xf, 0xe857b8, 0xe4
	RegObjTabl 0x160000f, 0xfa62cb, 0xf, 0xe860b2, 0x3e4
	RegObjTabl 0x1600010, 0xfa5995, 0x2c, 0xe857f8, 0xea
	RegObjTabl 0x160000f, 0xfa62cb, 0x2c, 0xe8617e, 0x3ea
	RegObjTabl 0x1600010, 0xfa5995, 0x25, 0xe858ac, 0xeb
	RegObjTabl 0x160000f, 0xfa62cb, 0x25, 0xe862f2, 0x3eb
	RegObjTabl 0x1600010, 0xfa5995, 0x18, 0xe85944, 0xee
	RegObjTabl 0x160000f, 0xfa62cb, 0x18, 0xe863fe, 0x3ee
	RegObjTabl 0x1600010, 0xfa5995, 0xb, 0xe859a8, 0xef
	RegObjTabl 0x160000f, 0xfa62cb, 0xb, 0xe864d0, 0x3ef
	RegObjTabl 0x1600010, 0xfa5995, 0x6, 0xe859d8, 0xf0
	RegObjTabl 0x160000f, 0xfa62cb, 0x6, 0xe86534, 0x3f0

	RegMode 0x1, 0xe8, 0x658a, 0x2, 0x1200000, 0x1a00002

	RegTitle 0x1, 0xe8, 0x6594, 0x2, 0x1200000, 0x20000
	RegTitle 0x1, 0xe8, 0x659e, 0x3, 0x1200000, 0x30000
	RegTitle 0x1, 0xe8, 0x65a8, 0x4, 0x1200000, 0x40000
	RegTitle 0x1, 0xe8, 0x65b4, 0x5, 0x1200000, 0x50000
	RegTitle 0x1, 0xe8, 0x65c0, 0x7, 0x1200000, 0x70000
	RegTitle 0x1, 0xe8, 0x65cc, 0x8, 0x1200000, 0x80000
	RegTitle 0x1, 0xe8, 0x65d8, 0xd, 0x1200000, 0xd0000
	RegTitle 0x1, 0xe8, 0x65e2, 0xa5, 0x1200000, 0xa50000
	RegTitle 0x1, 0xe8, 0x65ee, 0xe4, 0x1200000, 0xe40000
	RegTitle 0x1, 0xe8, 0x65fe, 0xea, 0x1200000, 0xea0000
	RegTitle 0x1, 0xe8, 0x660a, 0xeb, 0x1200000, 0xeb0000
	RegTitle 0x1, 0xe8, 0x6618, 0xee, 0x1200000, 0xee0000
	RegTitle 0x1, 0xe8, 0x6622, 0xef, 0x1200000, 0xef0000
	RegTitle 0x1, 0xe8, 0x662c, 0xf0, 0x1200000, 0xf00000

	lda xsp, (xsp + 14)
	ret

BitmapAccita16:
	cp xbc, 0x1e000a3
	jr z, BitmapAccita16_Height
	cp xbc, 0x1e000a2
	jr z, BitmapAccita16_Width
	cp xbc, 0x1e000a1
	jr z, BitmapAccita16_DataPtr
	lds32 xhl, 0
	ret

BitmapAccita16_DataPtr:
	lda_24 xhl, 0xe86676
	ret

BitmapAccita16_Width:
	ld xhl, 0x78
	ret

BitmapAccita16_Height:
	ld xhl, 0x5f
	ret

BitmapAccger16:
	cp xbc, 0x1e000a3
	jr z, BitmapAccger16_Height
	cp xbc, 0x1e000a2
	jr z, BitmapAccger16_Width
	cp xbc, 0x1e000a1
	jr z, BitmapAccger16_DataPtr
	lds32 xhl, 0
	ret

BitmapAccger16_DataPtr:
	lda_24 xhl, 0xe892fe
	ret

BitmapAccger16_Width:
	ld xhl, 0x78
	ret

BitmapAccger16_Height:
	ld xhl, 0x5f
	ret

BitmapDrawsw:
	cp xbc, 0x1e000a3
	jr z, BitmapDrawsw_Height
	cp xbc, 0x1e000a2
	jr z, BitmapDrawsw_Width
	cp xbc, 0x1e000a1
	jr z, BitmapDrawsw_DataPtr
	lds32 xhl, 0
	ret

BitmapDrawsw_DataPtr:
	lda_24 xhl, 0xe8bf86
	ret

BitmapDrawsw_Width:
	ld xhl, 0x126
	ret

BitmapDrawsw_Height:
	lds32 xhl, 6
	ret

; --- Bitmap_QueryProperties: Return dimensions/data for 3 bitmap resources ---
; Three identical query handlers. Each checks XBC for property ID:
;   0x1e000a1 -> return data pointer (lda_24 xhl, addr)
;   0x1e000a2 -> return width  (XHL = 22)
;   0x1e000a3 -> return height (XHL = 222)
;   other     -> return 0 (not handled)
; The three copies reference different bitmap data addresses:
;   0xe8e66a, 0xe8f97e, 0xe90c92 (in Table Data ROM).
Bitmap_QueryProperties3x:
	cp	xbc, 31457443
	jr	z, 31
	cp	xbc, 31457442
	jr	z, 17
	cp	xbc, 31457441
	jr	z, 3
	lds32	xhl, 0
	ret
	lda_24	xhl, 15255146
	ret
	ld	xhl, 22
	ret
	ld	xhl, 222
	ret
	cp	xbc, 31457443
	jr	z, 31
	cp	xbc, 31457442
	jr	z, 17
	cp	xbc, 31457441
	jr	z, 3
	lds32	xhl, 0
	ret
	lda_24	xhl, 15260030
	ret
	ld	xhl, 22
	ret
	ld	xhl, 222
	ret
	cp	xbc, 31457443
	jr	z, 31
	cp	xbc, 31457442
	jr	z, 17
	cp	xbc, 31457441
	jr	z, 3
	lds32	xhl, 0
	ret
	lda_24	xhl, 15264914
	ret
	ld	xhl, 22
	ret
	ld	xhl, 222
	ret


BitmapTechnics:
	cp xbc, 0x1e000a3
	jr z, BitmapTechnics_Height
	cp xbc, 0x1e000a2
	jr z, BitmapTechnics_Width
	cp xbc, 0x1e000a1
	jr z, BitmapTechnics_DataPtr
	lds32 xhl, 0
	ret

BitmapTechnics_DataPtr:
	lda_24 xhl, 0xe8ffa6
	ret

BitmapTechnics_Width:
	ld xhl, 0x138
	ret

BitmapTechnics_Height:
	ld xhl, 0x2d
	ret


BitmapKn5000:
	cp xbc, 0x1e000a3
	jr z, BitmapKn5000_Height
	cp xbc, 0x1e000a2
	jr z, BitmapKn5000_Width
	cp xbc, 0x1e000a1
	jr z, BitmapKn5000_DataPtr
	lds32 xhl, 0
	ret

BitmapKn5000_DataPtr:
	lda_24 xhl, 0xe9367e
	ret

BitmapKn5000_Width:
	ld xhl, 0xc7
	ret

BitmapKn5000_Height:
	ld xhl, 0x24
	ret

BitmapKn5000_Tail:
	ret

SndParam_ResolveOscEntry:
	dec 6, xsp
	pushw iz
	ld iz, wa
	ld wa, iz
	lds bc, 0
	call SndParam_LookupViaEncode
	ld (xsp + 5), l
	ld wa, iz
	ldw bc, 0x20
	call SndParam_LookupViaEncode
	lda xwa, (xsp + 2)
	ld (xwa + 4), l
	ldto_berp C, 0xf8
	ld (xwa + 2), c
	call SndParam_FetchOscTableEntry
	lda xbc, (xsp + 2)
	ld e, (xbc + 1)
	extz de
	ld a, (xbc)
	extz wa
	sll wa, 8
	add wa, de
	ld bc, wa
	extz xbc
	sll xbc, 0
	ld hl, iz
	extz xhl
	add xhl, xbc
	popw iz
	inc 6, xsp
	ret

TtSdmenu:
	push xiz
	cp xbc, 0x1c0000c
	jr z, TtSdmenu_ReturnZero
	cp xbc, 0x1c0000b
	jr z, TtSdmenu_ReturnZero
	cp xbc, 0x1c00002
	jr z, TtSdmenu_ReturnZero
	cp xbc, 0x1c00001
	jr nz, TtSdmenu_ReturnZero
	or xde, xde
	jr nz, TtSdmenu_ReturnZero
	call GetModeOld
	ld xiz, xhl
	call GetModeNow
	cp xhl, xiz
	jr z, TtSdmenu_ReturnZero
	ld xwa, 0x20001
	ld xbc, 0x1e0007f
	lds32 xde, 1
	call SendEvent

TtSdmenu_ReturnZero:
	lds32 xhl, 0
	pop xiz
	ret

AcSndEMenuProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld xiz, xwa
	ld xwa, (xsp + 8)
	cp xwa, 0x1c00007
	jr z, AcSndEMenu_CheckModified
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	jr AcSndEMenu_CallInherited

AcSndEMenu_CheckModified:
	ld xwa, xiz
	ld xbc, 0x1e00053
	ld xde, (xsp + 4)
	call SendEvent
	cps hl, 0
	jr z, AcSndEMenu_ForwardInherited
	ld xwa, 0xc0
	call SndParam_LookupReadOnly
	cps hl, 0
	jr z, AcSndEMenu_ForwardInherited
	lds32 xhl, 0
	jr AcSndEMenu_Epilogue

AcSndEMenu_ForwardInherited:
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)

AcSndEMenu_CallInherited:
	call InheritedProc

AcSndEMenu_Epilogue:
	pop xiz
	inc 8, xsp
	ret

LswLeftHold:
	push xiz
	ld xiz, xwa
	cp xbc, 0x1e0003f
	jr z, IvSdpart_TtlCase2
	cp xbc, 0x1e0003e
	jr z, IvSdpart_TtlCase2
	cp xbc, 0x1e00041
	jr z, IvSdpart_TtlCase1
	cp xbc, 0x1e00040
	jr z, IvSdpart_TtlCase0
	cp xbc, 0x1e00042
	jr z, LswLeftHold_Case42
	lds32 xhl, 0
	jr LswLeftHold_PopIzRet

LswLeftHold_Case42:
	ld bc, (xde + 4)
	ld xwa, (xde + 8)
	cps bc, 0
	jr lt, LswLeftHold_DefaultStr
	cps bc, 1
	jr gt, LswLeftHold_DefaultStr
	sla bc, 2
	lda_24 xde, 0x03e91c
	ld_sril3 XBC, 0x07, 0xe8, 0xe4
	push xbc
	jr LswLeftHold_CopyAndReturn

LswLeftHold_DefaultStr:
	pushw 0xe9
	pushw 0x52a6

LswLeftHold_CopyAndReturn:
	push xwa
	call Strcpy
	inc 8, xsp
	ld xhl, xiz
	jr LswLeftHold_PopIzRet

; IvSdpartProc title case 0
IvSdpart_TtlCase0:
	ld xhl, 0x28082
	jr LswLeftHold_PopIzRet

; IvSdpartProc title case 1
IvSdpart_TtlCase1:
	lds32 xhl, 4
	jr LswLeftHold_PopIzRet

; IvSdpartProc title case 2
IvSdpart_TtlCase2:
	lds32 xhl, 1

LswLeftHold_PopIzRet:
	pop xiz
	ret

IvSdpartProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	ld xwa, xiz
	cp xiz, 0x1e0003a
	jrl z, IvSdpart_GetText
	cp xiz, 0x1c0000d
	jrl z, IvSdpart_Paint
	cp xiz, 0x1c0002f
	jrl z, IvSdpart_Refresh
	cp xiz, 0x1c00029
	jrl z, IvSdpart_PageSelect
	cp xiz, 0x1c00007
	jrl z, IvSdpart_OK
	cp xiz, 0x1c0000c
	jrl z, IvSdpart_ShowHide
	cp xiz, 0x1c0000b
	jrl z, IvSdpart_ShowHide
	cp xiz, 0x1c00002
	jrl z, IvSdpart_Close
	cp xiz, 0x1c00001
	jr z, IvSdpart_Init
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, IvSdpart_ForwardToBase
	cp xwa, 0x9
	jrl gt, IvSdpart_ForwardToBase
	add xwa, xwa
	add xwa, 0xe95550
	ld wa, (xwa)
	lda_24 xix, IvSdpart_Init
	jp_dri 8, 0x07, 0xf0, 0xe0

IvSdpart_Init:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 4)
	cp xwa, 0x5
	jr z, IvSdpart_Init_ResetPart
	or xwa, xwa
	jr nz, IvSdpart_Init_LoadDescriptor

IvSdpart_Init_ResetPart:
	sti16_24 0x03e99c, 0x0008
	sti16_24 0x03e99e, 0x0000
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001b
	ld xde, 0x8
	call SendEvent

IvSdpart_Init_LoadDescriptor:
	ld16_24 xwa, 0x03e99c
	sla wa, 2
	lda_24 xbc, 0xe953aa
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld xbc, 0x1c00001
	lds32 xde, 0
	jrl IvSdpart_DispatchEvent

IvSdpart_Close:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 4)
	cp xwa, 0x5
	jr z, IvSdpart_Close_SetUndo
	or xwa, xwa
	jrl nz, IvSdpart_ReturnHandled

IvSdpart_Close_SetUndo:
	ld xwa, 0x1400002
	ld xbc, 0x1e000a0
	ld xde, 0x3f
	call MainFuncCall
	jrl IvSdpart_ReturnHandled

IvSdpart_ShowHide:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	cpdi16_24 256414, 18
	jr ge, IvSdpart_ShowHide_UpdateUI
	call GetPartSelect
	ld xwa, 0xe953ce
	ld bc, hl
	calr SdpartLookupPartId
	ld de, hl
	cp de, 0xffff
	jr z, IvSdpart_ShowHide_UpdateUI
	st16_24 0x03e99e, xde

IvSdpart_ShowHide_UpdateUI:
	calr SdpartUpdatePartUI
	ld16_24 xwa, 0x03e99e
	sla wa, 2
	lda_24 xbc, 0x03e924
	ld_sril3 XDE, 0x07, 0xe4, 0xe0
	ld xwa, 0x3000b
	ld xbc, 0x1c0000f
	jrl IvSdpart_DispatchEvent

IvSdpart_OK:
	ld xwa, (xsp + 4)
	cp xwa, 0xf
	jr nz, IvSdpart_OK_Forward
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e0007a
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr nz, IvSdpart_OK_Forward
	ld16_24 xwa, 0x03e99c
	cp wa, 0x8
	jr z, IvSdpart_OK_ExitToMenu
	sla wa, 2
	lda_24 xbc, 0xe953aa
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld xbc, 0x1c00002
	lds32 xde, 5
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001b
	ld xde, 0x8
	call SendEvent
	sti16_24 0x03e99c, 0x0008
	ld32_24 xwa, 0xe953ca
	ld xbc, 0x1c00001
	lds32 xde, 5
	jrl IvSdpart_DispatchEvent

IvSdpart_OK_ExitToMenu:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00015
	ld xde, 0x1a00002
	jrl IvSdpart_DispatchEvent

IvSdpart_OK_Forward:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	jrl IvSdpart_CallBase

IvSdpart_PageSelect:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldi_werp 0xe2, 0
	cp wa, 0x8
	jrl nz, IvSdpart_ReturnHandled
	ld xwa, (xsp + 4)
	ld iz, wa
	ld16_24 xwa, 0x03e99c
	cp iz, wa
	jrl z, IvSdpart_ReturnHandled
	cp iz, 0xffff
	jrl z, IvSdpart_ReturnHandled
	sla wa, 2
	lda_24 xbc, 0xe953aa
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld xbc, 0x1c00002
	lds32 xde, 5
	call SendEvent
	st16_24 0x03e99c, xiz
	ld wa, iz
	sla wa, 2
	lda_24 xbc, 0xe953aa
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld xbc, 0x1c00001
	lds32 xde, 5
	call SendEvent
	call SetAutoIncDefault
	jrl IvSdpart_ReturnHandled
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 4)
	cp xwa, 0x9
	jrl nz, IvSdpart_ReturnHandled
	ld xwa, xiz
	lds bc, 1
	lds de, 1
	calr SdpartScrollDelta
	cps hl, 0
	jrl z, IvSdpart_ReturnHandled
	ld16_24 xwa, 0x03e99e
	ld bc, wa
	add bc, hl
	jrl lt, IvSdpart_ReturnHandled
	cp bc, 0x17
	jrl gt, IvSdpart_ReturnHandled
	add wa, hl
	st16_24 0x03e99e, xwa
	calr SdpartUpdatePartUI
	ld16_24 xwa, 0x03e99e
	sla wa, 2
	lda_24 xbc, 0x03e924
	ld_sril3 XDE, 0x07, 0xe4, 0xe0
	ld xwa, 0x3000b
	ld xbc, 0x1c0000f
	call SendEvent
	ld16_24 xwa, 0x03e99e
	sla wa, 1
	lda_24 xbc, 0xe953ce
	ld_sriw3 DE, 0x07, 0xe4, 0xe0
	exts xde
	ld xwa, 0x1400002
	ld xbc, 0x1e000a0
	call MainFuncCall
	ld16_24 xwa, 0x03e99c
	sla wa, 2
	lda_24 xbc, 0xe953aa
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call SetAutoInc
	jrl IvSdpart_ReturnHandled

IvSdpart_Refresh:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	cpdi16_24 256414, 18
	jrl ge, IvSdpart_ReturnHandled
	call GetPartSelect
	ld xwa, 0xe953ce
	ld bc, hl
	calr SdpartLookupPartId
	ld de, hl
	cp de, 0xffff
	jrl z, IvSdpart_ReturnHandled
	cpdm16_24 256414, xde
	jrl z, IvSdpart_ReturnHandled
	st16_24 0x03e99e, xde
	calr SdpartUpdatePartUI
	ld16_24 xwa, 0x03e99e
	sla wa, 2
	lda_24 xbc, 0x03e924
	ld_sril3 XDE, 0x07, 0xe4, 0xe0
	ld xwa, 0x3000b
	ld xbc, 0x1c0000f
	call SendEvent
	ld16_24 xwa, 0x03e99c
	sla wa, 2
	lda_24 xbc, 0xe953aa
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld xbc, 0x1c0000b
	lds32 xde, 0
	jrl IvSdpart_DispatchEvent
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld16_24 xwa, 0x03e99e
	sla wa, 1
	lda_24 xbc, 0xe953ce
	ld_sriw3 DE, 0x07, 0xe4, 0xe0
	exts xde
	ld xbc, xde
	sll xbc, 10
	ld xhl, xbc
	add xhl, 0x8000
	ld xwa, (xsp + 4)
	cp xhl, (xwa)
	jr z, IvSdpart_Match_HitTest
	add xbc, 0x8020
	cp xbc, (xwa)
	jr nz, IvSdpart_ReturnHandled

IvSdpart_Match_HitTest:
	ld xwa, 0x1400004
	ld xbc, 0x1e0005e
	call FuncCall
	jr IvSdpart_ReturnHandled
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld16_24 xwa, 0x03e99e
	sla wa, 1
	lda_24 xbc, 0xe953ce
	ld_sriw3 BC, 0x07, 0xe4, 0xe0
	ld xwa, (xsp + 4)
	cp bc, (xwa)
	jr nz, IvSdpart_ReturnHandled
	ld xde, (xwa + 2)
	ld xwa, 0x3000a
	ld xbc, 0x1c0000f
	jr IvSdpart_DispatchEvent

IvSdpart_Paint:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 8)
	ld xbc, 0x1c0000f
	lds32 xde, 0

IvSdpart_DispatchEvent:
	call SendEvent
	jr IvSdpart_ReturnHandled

IvSdpart_GetText:
	pushw 0xe9
	pushw 0x554a
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp

IvSdpart_ReturnHandled:
	lds32 xhl, 0
	jr IvSdpart_Return

IvSdpart_ForwardToBase:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)

IvSdpart_CallBase:
	call InheritedProc

IvSdpart_Return:
	pop xiz
	inc 8, xsp
	ret

AcLswPartEditBoxProc:
	lda xsp, (xsp - 28)
	push xiz
	ld (xsp + 24), xde
	ld xiz, xbc
	ld (xsp + 28), xwa
	cp xiz, 0x1c00031
	jrl z, AcLswPartEdit_Snap
	cp xiz, 0x1c00018
	jrl z, AcLswPartEdit_ScrollDown
	cp xiz, 0x1c0001a
	jrl z, AcLswPartEdit_AutoIncDown
	cp xiz, 0x1c00017
	jrl z, AcLswPartEdit_ScrollUp
	cp xiz, 0x1c00019
	jrl z, AcLswPartEdit_AutoIncUp
	cp xiz, 0x1c0001c
	jrl z, AcLswPartEdit_Match
	cp xiz, 0x1c0000d
	jrl z, AcLswPartEdit_Paint
	cp xiz, 0x1c0000c
	jrl z, AcLswPartEdit_ShowHide
	cp xiz, 0x1c0000b
	jrl z, AcLswPartEdit_ShowHide
	cp xiz, 0x1e0003d
	jrl z, AcLswPartEdit_AddDelta
	cp xiz, 0x1e0003b
	jr z, AcLswPartEdit_SetValue
	cp xiz, 0x1e0003a
	jrl nz, AcLswPartEdit_ForwardToBase
	ld xwa, (xsp + 28)
	call GetViewInstance
	ld xiz, xhl
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xiz + 50)
	ld xbc, 0x1e10000
	call ApFuncCall
	ld (xsp + 22), hl
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xiz + 50)
	ld xbc, 0x1e10001
	call ApFuncCall
	ld (xsp + 20), hl
	ld bc, (xsp + 20)
	extz xbc
	ld16_24 xwa, 0x03e99e
	extz xwa
	sll xwa, 0
	add xwa, xbc
	lda xde, (xsp + 8)
	ld (xde), xwa
	ld xwa, (xiz + 54)
	ld wa, (xwa)
	ld (xde + 4), wa
	ld xwa, (xsp + 24)
	ld (xde + 8), xwa
	ld xwa, (xiz + 50)
	ld xbc, 0x1e00042
	call ApFuncCall
	jrl AcLswPartEdit_ReturnHandled

AcLswPartEdit_SetValue:
	ld xwa, (xsp + 28)
	call GetViewInstance
	ld xiz, xhl
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xiz + 50)
	ld xbc, 0x1e10002
	call ApFuncCall
	or xhl, xhl
	jrl z, AcLswPartEdit_ReturnHandled
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xiz + 50)
	ld xbc, 0x1e10000
	call ApFuncCall
	ld (xsp + 22), hl
	ld xwa, (xsp + 24)
	ld (xsp + 4), wa
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xiz + 50)
	ld xbc, 0x1e00041
	call ApFuncCall
	ld (xsp + 6), hl
	ld bc, (xsp + 22)
	lda xwa, (xiz + 50)
	cp bc, 0xffff
	jr z, AcLswPartEdit_SetValue_Unbounded
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xwa)
	ld xbc, 0x1e10001
	call ApFuncCall
	ld (xsp + 20), hl
	pushm (xsp + 6)
	ld wa, (xsp + 24)
	ld bc, (xsp + 22)
	ld de, (xsp + 6)
	call MainLswPartPut
	jrl AcLswPartEdit_ReturnHandled

AcLswPartEdit_SetValue_Unbounded:
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xwa)
	ld xbc, 0x1e10001
	call ApFuncCall
	ld xwa, xhl
	ld bc, (xsp + 4)
	ld de, (xsp + 6)
	call MainLswPut
	jrl AcLswPartEdit_ReturnHandled

AcLswPartEdit_AddDelta:
	ld xwa, (xsp + 28)
	call GetViewInstance
	ld xiz, xhl
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xiz + 50)
	ld xbc, 0x1e10002
	call ApFuncCall
	or xhl, xhl
	jrl z, AcLswPartEdit_ReturnHandled
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xiz + 50)
	ld xbc, 0x1e10000
	call ApFuncCall
	ld (xsp + 22), hl
	ld xwa, (xsp + 24)
	ld (xsp + 4), wa
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xiz + 50)
	ld xbc, 0x1e00041
	call ApFuncCall
	ld (xsp + 6), hl
	ld bc, (xsp + 22)
	ld16_24 xde, 0x03e99e
	exts xde
	lda xwa, (xiz + 50)
	cp bc, 0xffff
	jr z, AcLswPartEdit_AddDelta_Unbounded
	ld xwa, (xwa)
	ld xbc, 0x1e10001
	call ApFuncCall
	ld (xsp + 20), hl
	pushm (xsp + 6)
	ld wa, (xsp + 24)
	ld bc, (xsp + 22)
	ld de, (xsp + 6)
	call MainLswPartAdd
	jrl AcLswPartEdit_ReturnHandled

AcLswPartEdit_AddDelta_Unbounded:
	ld xwa, (xwa)
	ld xbc, 0x1e10001
	call ApFuncCall
	ld xwa, xhl
	ld bc, (xsp + 4)
	ld de, (xsp + 6)
	call MainLswAdd
	jrl AcLswPartEdit_ReturnHandled

AcLswPartEdit_ShowHide:
	ld xwa, (xsp + 28)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e10000
	call ApFuncCall
	ld (xsp + 22), hl
	ld bc, (xsp + 22)
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xsp + 4)
	lda xwa, (xwa + 50)
	cp bc, 0xffff
	jr z, AcLswPartEdit_ShowHide_Unbounded
	ld xwa, (xwa)
	ld xbc, 0x1e10001
	call ApFuncCall
	ld (xsp + 20), hl
	ld wa, (xsp + 22)
	ld bc, (xsp + 20)
	call SndParam_LookupViaEncode
	jr AcLswPartEdit_ShowHide_StoreAndForward

AcLswPartEdit_ShowHide_Unbounded:
	ld xwa, (xwa)
	ld xbc, 0x1e10001
	call ApFuncCall
	ld xwa, xhl
	call SndParam_LookupReadOnly

AcLswPartEdit_ShowHide_StoreAndForward:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 54)
	ld (xwa), hl
	ld xwa, (xsp + 28)
	ld xbc, xiz
	ld xde, (xsp + 24)
	call InheritedProc
	jrl AcLswPartEdit_ReturnHandled

AcLswPartEdit_Paint:
	ld xwa, (xsp + 28)
	ld xbc, xiz
	ld xde, (xsp + 24)
	call InheritedProc
	ld xwa, (xsp + 28)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jrl AcLswPartEdit_DispatchEvent

AcLswPartEdit_Match:
	ld xwa, (xsp + 28)
	ld xbc, xiz
	ld xde, (xsp + 24)
	call InheritedProc
	ld xwa, (xsp + 28)
	call GetViewInstance
	ld xiz, xhl
	ld (xsp + 4), xiz
	lda xbc, (xsp + 22)
	lda xde, (xsp + 20)
	ld xwa, (xsp + 24)
	call SndParam_DecodeMidiAddr
	ld xwa, (xiz + 50)
	cp hl, 0xffff
	jr z, AcLswPartEdit_Match_Unbounded
	ld16_24 xde, 0x03e99e
	exts xde
	ld xbc, 0x1e10000
	call ApFuncCall
	ld wa, (xsp + 22)
	extz xwa
	cp xwa, xhl
	jrl nz, AcLswPartEdit_ReturnHandled
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xiz + 50)
	ld xbc, 0x1e10001
	call ApFuncCall
	ld wa, (xsp + 20)
	extz xwa
	cp xwa, xhl
	jrl nz, AcLswPartEdit_ReturnHandled
	lda xde, (xiz + 54)
	ld xbc, (xde)
	ld xwa, (xsp + 24)
	ld wa, (xwa + 4)
	ld (xbc), wa
	ld xwa, (xde)
	ld de, (xwa)
	exts xde
	ld xwa, (xiz + 50)
	ld xbc, 0x1e00083
	call ApFuncCall
	ld xwa, (xsp + 28)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jrl AcLswPartEdit_DispatchEvent

AcLswPartEdit_Match_Unbounded:
	ld16_24 xde, 0x03e99e
	exts xde
	ld xbc, 0x1e10001
	call ApFuncCall
	ld xwa, (xsp + 24)
	cp (xwa), xhl
	jrl nz, AcLswPartEdit_ReturnHandled
	lda xde, (xiz + 54)
	ld xbc, (xde)
	ld wa, (xwa + 4)
	ld (xbc), wa
	ld xwa, (xde)
	ld de, (xwa)
	exts xde
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00083
	call ApFuncCall
	ld xwa, (xsp + 28)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jrl AcLswPartEdit_DispatchEvent

AcLswPartEdit_AutoIncUp:
	ld xwa, (xsp + 28)
	ld xbc, xiz
	ld xde, (xsp + 24)
	call InheritedProc
	ld xwa, (xsp + 28)
	ld xbc, 0x1e0003c
	ld xde, (xsp + 24)
	call SendEvent
	or xhl, xhl
	jrl z, AcLswPartEdit_ReturnHandled
	ld xwa, (xsp + 28)
	call GetViewInstance
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xhl + 50)
	ld xbc, 0x1e0003e
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 28)
	ld xbc, 0x1e0003d
	jrl AcLswPartEdit_DispatchEvent

AcLswPartEdit_ScrollUp:
	ld xwa, (xsp + 28)
	ld xbc, xiz
	ld xde, (xsp + 24)
	call InheritedProc
	ld xwa, (xsp + 28)
	ld xbc, 0x1e0003c
	ld xde, (xsp + 24)
	call SendEvent
	or xhl, xhl
	jrl z, AcLswPartEdit_ReturnHandled
	ld xwa, (xsp + 28)
	call GetViewInstance
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xhl + 50)
	ld xbc, 0x1e0003f
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 28)
	ld xbc, 0x1e0003d
	jrl AcLswPartEdit_DispatchEvent

AcLswPartEdit_AutoIncDown:
	ld xwa, (xsp + 28)
	ld xbc, xiz
	ld xde, (xsp + 24)
	call InheritedProc
	ld xwa, (xsp + 28)
	ld xbc, 0x1e0003c
	ld xde, (xsp + 24)
	call SendEvent
	or xhl, xhl
	jrl z, AcLswPartEdit_ReturnHandled
	ld xwa, (xsp + 28)
	call GetViewInstance
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xhl + 50)
	ld xbc, 0x1e0003e
	call ApFuncCall
	cpl hl
	cpl_werp 0xee
	inc 1, xhl
	ld xwa, (xsp + 28)
	ld xbc, 0x1e0003d
	ld xde, xhl
	jrl AcLswPartEdit_DispatchEvent

AcLswPartEdit_ScrollDown:
	ld xwa, (xsp + 28)
	ld xbc, xiz
	ld xde, (xsp + 24)
	call InheritedProc
	ld xwa, (xsp + 28)
	ld xbc, 0x1e0003c
	ld xde, (xsp + 24)
	call SendEvent
	or xhl, xhl
	jrl z, AcLswPartEdit_ReturnHandled
	ld xwa, (xsp + 28)
	call GetViewInstance
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xhl + 50)
	ld xbc, 0x1e0003f
	call ApFuncCall
	cpl hl
	cpl_werp 0xee
	inc 1, xhl
	ld xwa, (xsp + 28)
	ld xbc, 0x1e0003d
	ld xde, xhl
	jr AcLswPartEdit_DispatchEvent

AcLswPartEdit_Snap:
	ld xwa, (xsp + 28)
	ld xbc, xiz
	ld xde, (xsp + 24)
	call InheritedProc
	ld xwa, (xsp + 28)
	ld xbc, 0x1e0003c
	ld xde, (xsp + 24)
	call SendEvent
	or xhl, xhl
	jr z, AcLswPartEdit_ReturnHandled
	ld xwa, (xsp + 28)
	call GetViewInstance
	ld xiz, xhl
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xiz + 50)
	ld xbc, 0x1e000b8
	call ApFuncCall
	or xhl, xhl
	jr z, AcLswPartEdit_ReturnHandled
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xiz + 50)
	ld xbc, 0x1e000b9
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 28)
	ld xbc, 0x1e0003b

AcLswPartEdit_DispatchEvent:
	call SendEvent

AcLswPartEdit_ReturnHandled:
	lds32 xhl, 0
	jr AcLswPartEdit_Return

AcLswPartEdit_ForwardToBase:
	ld xwa, (xsp + 28)
	ld xbc, xiz
	ld xde, (xsp + 24)
	call InheritedProc

AcLswPartEdit_Return:
	pop xiz
	lda xsp, (xsp + 28)
	ret

AcVolPartEditBoxProc:
	lda xsp, (xsp - 38)
	push xiz
	ld (xsp + 30), xde
	ld (xsp + 34), xbc
	ld (xsp + 38), xwa
	ld xwa, (xsp + 34)
	cp xwa, 0x1c00031
	jrl z, AudioCtrl_GetToggleState
	cp xwa, 0x1c00018
	jrl z, AudioCtrl_GetNegMax
	cp xwa, 0x1c0001a
	jrl z, AudioCtrl_GetNegMin
	cp xwa, 0x1c00017
	jrl z, AudioCtrl_GetMaxLimit
	cp xwa, 0x1c00019
	jrl z, AudioCtrl_GetMinLimit
	cp xwa, 0x1c0001c
	jrl z, AudioCtrl_MidiMatchHandler
	cp xwa, 0x1c0000d
	jrl z, AudioCtrl_InheritAndConfirm
	cp xwa, 0x1c0000c
	jrl z, AudioCtrl_InitPartSelection
	cp xwa, 0x1c0000b
	jrl z, AudioCtrl_InitPartSelection
	cp xwa, 0x1e0003d
	jrl z, AudioCtrl_DualPartNavigate
	cp xwa, 0x1e0003b
	jr z, AudioCtrl_InitPartPanDisplay
	cp xwa, 0x1e0003a
	jrl nz, AudioCtrl_ForwardInherited
	ld xwa, (xsp + 38)
	call GetViewInstance
	ld (xsp + 10), xhl
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e10000
	call ApFuncCall
	ld (xsp + 28), hl
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e10001
	call ApFuncCall
	ld (xsp + 26), hl
	ld bc, (xsp + 26)
	extz xbc
	ld16_24 xwa, 0x03e99e
	extz xwa
	sll xwa, 0
	add xwa, xbc
	lda xde, (xsp + 14)
	ld (xde), xwa
	ld xbc, (xsp + 10)
	ld xwa, (xbc + 58)
	ld wa, (xwa)
	ld (xde + 4), wa
	ld xwa, (xsp + 30)
	ld (xde + 8), xwa
	ld xwa, (xbc + 50)
	ld xbc, 0x1e00042
	call ApFuncCall
	jrl AudioCtrl_ReturnZeroEpilogue

AudioCtrl_InitPartPanDisplay:
	ld xwa, (xsp + 38)
	call GetViewInstance
	ld (xsp + 8), xhl
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e10000
	call ApFuncCall
	ld (xsp + 28), hl
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00041
	call ApFuncCall
	ld (xsp + 6), hl
	ld de, (xsp + 28)
	ld xhl, (xsp + 30)
	ld (xsp + 12), hl
	ld xwa, (xsp + 8)
	lda xbc, (xwa + 50)
	cp xhl, 0x80
	jr nc, AudioCtrl_HighPartOffset
	cp de, 0xffff
	jr z, AudioCtrl_UnboundedPart
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xbc)
	ld xbc, 0x1e10001
	call ApFuncCall
	ld (xsp + 26), hl
	pushm (xsp + 6)
	ld wa, (xsp + 30)
	ld bc, (xsp + 28)
	ld de, (xsp + 14)
	jrl AudioCtrl_CallMainLswPartPut

AudioCtrl_UnboundedPart:
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xbc)
	ld xbc, 0x1e10001
	call ApFuncCall
	ld xiz, xhl
	ld xwa, xiz
	ld bc, (xsp + 12)
	ld de, (xsp + 6)
	jrl AudioCtrl_CallMainLswPut

AudioCtrl_HighPartOffset:
	ld wa, (xsp + 12)
	sub wa, 0x80
	ld (xsp + 4), wa
	ld xwa, (xbc)
	cp de, 0xffff
	jr z, AudioCtrl_HighPartUnbounded
	ld16_24 xde, 0x03e99e
	exts xde
	ld xbc, 0x1e10001
	call ApFuncCall
	ld (xsp + 26), hl
	pushm (xsp + 6)
	ld wa, (xsp + 30)
	ld bc, (xsp + 28)
	ld de, (xsp + 6)
	call MainLswPartPut
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 54)
	ld xbc, 0x1e10001
	call ApFuncCall
	ld (xsp + 26), hl
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 54)
	ld xbc, 0x1e00041
	call ApFuncCall
	ld (xsp + 6), hl
	pushm (xsp + 6)
	ld wa, (xsp + 30)
	ld bc, (xsp + 28)
	lds de, 1

AudioCtrl_CallMainLswPartPut:
	call MainLswPartPut
	jrl AudioCtrl_ReturnZeroEpilogue

AudioCtrl_HighPartUnbounded:
	ld16_24 xde, 0x03e99e
	exts xde
	ld xbc, 0x1e10001
	call ApFuncCall
	ld xiz, xhl
	ld xwa, xiz
	ld bc, (xsp + 4)
	ld de, (xsp + 6)
	call MainLswPut
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 54)
	ld xbc, 0x1e10001
	call ApFuncCall
	ld xiz, xhl
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 54)
	ld xbc, 0x1e00041
	call ApFuncCall
	ld (xsp + 6), hl
	ld xwa, xiz
	lds bc, 1
	ld de, (xsp + 6)
	jrl AudioCtrl_CallMainLswPut

AudioCtrl_DualPartNavigate:
	ld xwa, (xsp + 38)
	call GetViewInstance
	ld (xsp + 10), xhl
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e10000
	call ApFuncCall
	ld (xsp + 28), hl
	ld de, (xsp + 28)
	ld xbc, (xsp + 10)
	ld xwa, (xbc + 54)
	lda xhl, (xbc + 50)
	lda xbc, (xbc + 58)
	cp de, 0xffff
	jrl z, AudioCtrl_DualPartUnbounded
	ld xbc, (xbc)
	cpw (xbc), 0x80
	jr ge, AudioCtrl_DualPartHighOffset
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xhl)
	ld xbc, 0x1e10001
	call ApFuncCall
	ld (xsp + 26), hl
	ld xwa, (xsp + 30)
	ld (xsp + 4), wa
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00041
	call ApFuncCall
	ld (xsp + 6), hl
	pushm (xsp + 6)
	ld wa, (xsp + 30)
	ld bc, (xsp + 28)
	ld de, (xsp + 6)
	call MainLswPartAdd
	jrl AudioCtrl_ReturnZeroEpilogue

AudioCtrl_DualPartHighOffset:
	ld16_24 xde, 0x03e99e
	exts xde
	ld xbc, 0x1e10001
	call ApFuncCall
	ld (xsp + 26), hl
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 54)
	ld xbc, 0x1e00041
	call ApFuncCall
	ld (xsp + 6), hl
	pushm (xsp + 6)
	ld wa, (xsp + 30)
	ld bc, (xsp + 28)
	lds de, 0
	call MainLswPartPut
	jrl AudioCtrl_ReturnZeroEpilogue

AudioCtrl_DualPartUnbounded:
	ld xbc, (xbc)
	ld16_24 xde, 0x03e99e
	exts xde
	cpw (xbc), 0x80
	jr ge, AudioCtrl_DualPartResolve
	ld xwa, (xhl)
	ld xbc, 0x1e10001
	call ApFuncCall
	ld xiz, xhl
	ld xwa, (xsp + 30)
	ld (xsp + 4), wa
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00041
	call ApFuncCall
	ld (xsp + 6), hl
	ld xwa, xiz
	ld bc, (xsp + 4)
	ld de, (xsp + 6)
	call MainLswAdd
	jrl AudioCtrl_ReturnZeroEpilogue

AudioCtrl_DualPartResolve:
	ld xbc, 0x1e10001
	call ApFuncCall
	ld xiz, xhl
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 54)
	ld xbc, 0x1e00041
	call ApFuncCall
	ld (xsp + 6), hl
	ld xwa, xiz
	lds bc, 0
	ld de, (xsp + 6)

AudioCtrl_CallMainLswPut:
	call MainLswPut
	jrl AudioCtrl_ReturnZeroEpilogue

AudioCtrl_InitPartSelection:
	ld xwa, (xsp + 38)
	call GetViewInstance
	ld (xsp + 10), xhl
	ld xwa, (xsp + 10)
	ld (xsp + 6), xwa
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xwa + 50)
	ld xbc, 0x1e10000
	call ApFuncCall
	ld (xsp + 28), hl
	ld bc, (xsp + 28)
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xsp + 10)
	lda xwa, (xwa + 50)
	cp bc, 0xffff
	jr z, AudioCtrl_UnboundedPartSel
	ld xwa, (xwa)
	ld xbc, 0x1e10001
	call ApFuncCall
	ld (xsp + 26), hl
	ld wa, (xsp + 28)
	ld bc, (xsp + 26)
	call SndParam_LookupViaEncode
	ld xbc, (xsp + 10)
	ld xwa, (xbc + 58)
	ld (xwa), hl
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xbc + 54)
	ld xbc, 0x1e10001
	call ApFuncCall
	ld (xsp + 26), hl
	ld wa, (xsp + 28)
	ld bc, (xsp + 26)
	call SndParam_LookupViaEncode
	jr AudioCtrl_MergeAndForward

AudioCtrl_UnboundedPartSel:
	ld xwa, (xwa)
	ld xbc, 0x1e10001
	call ApFuncCall
	ld xiz, xhl
	ld xwa, xiz
	call SndParam_LookupReadOnly
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 58)
	ld (xwa), hl
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 54)
	ld xbc, 0x1e10001
	call ApFuncCall
	ld xiz, xhl
	ld xwa, xiz
	call SndParam_LookupReadOnly

AudioCtrl_MergeAndForward:
	sla hl, 7
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 58)
	add (xwa), hl
	ld xwa, (xsp + 38)
	ld xbc, (xsp + 34)
	ld xde, (xsp + 30)
	call InheritedProc
	jrl AudioCtrl_ReturnZeroEpilogue

AudioCtrl_InheritAndConfirm:
	ld xwa, (xsp + 38)
	ld xbc, (xsp + 34)
	ld xde, (xsp + 30)
	call InheritedProc
	ld xwa, (xsp + 38)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jrl AudioCtrl_SendEventThenReturn

AudioCtrl_MidiMatchHandler:
	ld xwa, (xsp + 38)
	ld xbc, (xsp + 34)
	ld xde, (xsp + 30)
	call InheritedProc
	ld xwa, (xsp + 38)
	call GetViewInstance
	ld (xsp + 10), xhl
	lda xbc, (xsp + 28)
	lda xde, (xsp + 26)
	ld xwa, (xsp + 30)
	call SndParam_DecodeMidiAddr
	ld xwa, (xsp + 10)
	lda xwa, (xwa + 50)
	cp hl, 0xffff
	jrl z, AudioCtrl_UnboundedMatch
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xwa)
	ld xbc, 0x1e10000
	call ApFuncCall
	ld wa, (xsp + 28)
	extz xwa
	cp xwa, xhl
	jrl nz, AudioCtrl_ReturnZeroEpilogue
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e10001
	call ApFuncCall
	cp hl, (xsp + 26)
	jr nz, AudioCtrl_CheckSecondPart
	ld xwa, (xsp + 10)
	ld xbc, (xwa + 58)
	ld xwa, (xsp + 30)
	lda xde, (xwa + 4)
	ld wa, (xbc)
	bit 7, wa
	jr z, AudioCtrl_StoreValue
	ld wa, (xde)
	add wa, 0x80
	ld (xbc), wa
	jr AudioCtrl_ConfirmAndReturn

AudioCtrl_StoreValue:
	ld wa, (xde)
	ld (xbc), wa

AudioCtrl_ConfirmAndReturn:
	ld xwa, (xsp + 38)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jrl AudioCtrl_SendEventThenReturn

AudioCtrl_CheckSecondPart:
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 54)
	ld xbc, 0x1e10001
	call ApFuncCall
	cp hl, (xsp + 26)
	jrl nz, AudioCtrl_ReturnZeroEpilogue
	ld xwa, (xsp + 30)
	cpw (xwa + 4), 0x0
	jr z, AudioCtrl_ClearHighBit
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 58)
	ormi16 (xwa), 0x80
	jr AudioCtrl_ConfirmAndReturn2

AudioCtrl_ClearHighBit:
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 58)
	andmi16 (xwa), 0xff7f

AudioCtrl_ConfirmAndReturn2:
	ld xwa, (xsp + 38)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jrl AudioCtrl_SendEventThenReturn

AudioCtrl_UnboundedMatch:
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xwa)
	ld xbc, 0x1e10001
	call ApFuncCall
	ld xbc, (xsp + 30)
	cp (xbc), xhl
	jr nz, AudioCtrl_CheckSecondUnbounded
	ld xwa, (xsp + 10)
	ld xde, (xwa + 58)
	inc 4, xbc
	ld wa, (xde)
	bit 7, wa
	jr z, AudioCtrl_StoreUnbounded
	ld wa, (xbc)
	add wa, 0x80
	ld (xde), wa
	jr AudioCtrl_ConfirmAndReturn3

AudioCtrl_StoreUnbounded:
	ld wa, (xbc)
	ld (xde), wa

AudioCtrl_ConfirmAndReturn3:
	ld xwa, (xsp + 38)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jrl AudioCtrl_SendEventThenReturn

AudioCtrl_CheckSecondUnbounded:
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 54)
	ld xbc, 0x1e10001
	call ApFuncCall
	ld xde, (xsp + 30)
	cp (xde), xhl
	jrl nz, AudioCtrl_ReturnZeroEpilogue
	ld xwa, (xsp + 10)
	lda xbc, (xwa + 58)
	cpw (xde + 4), 0x0
	jr z, AudioCtrl_ClearHighBitUnbd
	ld xwa, (xbc)
	ormi16 (xwa), 0x80
	jr AudioCtrl_ConfirmAndReturn4

AudioCtrl_ClearHighBitUnbd:
	ld xwa, (xbc)
	andmi16 (xwa), 0xff7f

AudioCtrl_ConfirmAndReturn4:
	ld xwa, (xsp + 38)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jrl AudioCtrl_SendEventThenReturn

AudioCtrl_GetMinLimit:
	ld xwa, (xsp + 38)
	ld xbc, (xsp + 34)
	ld xde, (xsp + 30)
	call InheritedProc
	ld xwa, (xsp + 38)
	ld xbc, 0x1e0003c
	ld xde, (xsp + 30)
	call SendEvent
	or xhl, xhl
	jrl z, AudioCtrl_ReturnZeroEpilogue
	ld xwa, (xsp + 38)
	call GetViewInstance
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xhl + 50)
	ld xbc, 0x1e0003e
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 38)
	ld xbc, 0x1e0003d
	jrl AudioCtrl_SendEventThenReturn

AudioCtrl_GetMaxLimit:
	ld xwa, (xsp + 38)
	ld xbc, (xsp + 34)
	ld xde, (xsp + 30)
	call InheritedProc
	ld xwa, (xsp + 38)
	ld xbc, 0x1e0003c
	ld xde, (xsp + 30)
	call SendEvent
	or xhl, xhl
	jrl z, AudioCtrl_ReturnZeroEpilogue
	ld xwa, (xsp + 38)
	call GetViewInstance
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xhl + 50)
	ld xbc, 0x1e0003f
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 38)
	ld xbc, 0x1e0003d
	jrl AudioCtrl_SendEventThenReturn

AudioCtrl_GetNegMin:
	ld xwa, (xsp + 38)
	ld xbc, (xsp + 34)
	ld xde, (xsp + 30)
	call InheritedProc
	ld xwa, (xsp + 38)
	ld xbc, 0x1e0003c
	ld xde, (xsp + 30)
	call SendEvent
	or xhl, xhl
	jrl z, AudioCtrl_ReturnZeroEpilogue
	ld xwa, (xsp + 38)
	call GetViewInstance
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xhl + 50)
	ld xbc, 0x1e0003e
	call ApFuncCall
	cpl hl
	cpl_werp 0xee
	inc 1, xhl
	ld xwa, (xsp + 38)
	ld xbc, 0x1e0003d
	ld xde, xhl
	jrl AudioCtrl_SendEventThenReturn

AudioCtrl_GetNegMax:
	ld xwa, (xsp + 38)
	ld xbc, (xsp + 34)
	ld xde, (xsp + 30)
	call InheritedProc
	ld xwa, (xsp + 38)
	ld xbc, 0x1e0003c
	ld xde, (xsp + 30)
	call SendEvent
	or xhl, xhl
	jr z, AudioCtrl_ReturnZeroEpilogue
	ld xwa, (xsp + 38)
	call GetViewInstance
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xhl + 50)
	ld xbc, 0x1e0003f
	call ApFuncCall
	cpl hl
	cpl_werp 0xee
	inc 1, xhl
	ld xwa, (xsp + 38)
	ld xbc, 0x1e0003d
	ld xde, xhl
	jr AudioCtrl_SendEventThenReturn

AudioCtrl_GetToggleState:
	ld xwa, (xsp + 38)
	ld xbc, (xsp + 34)
	ld xde, (xsp + 30)
	call InheritedProc
	ld xwa, (xsp + 38)
	ld xbc, 0x1e0003c
	ld xde, (xsp + 30)
	call SendEvent
	or xhl, xhl
	jr z, AudioCtrl_ReturnZeroEpilogue
	ld xwa, (xsp + 38)
	call GetViewInstance
	ld xwa, (xhl + 58)
	ld de, (xwa)
	set 7, de
	exts xde
	ld xwa, (xsp + 38)
	ld xbc, 0x1e0003b

AudioCtrl_SendEventThenReturn:
	call SendEvent

AudioCtrl_ReturnZeroEpilogue:
	lds32 xhl, 0
	jr AudioCtrl_Epilogue

AudioCtrl_ForwardInherited:
	ld xwa, (xsp + 38)
	ld xbc, (xsp + 34)
	ld xde, (xsp + 30)
	call InheritedProc

AudioCtrl_Epilogue:
	pop xiz
	lda xsp, (xsp + 38)
	ret

AcLswPartPanProc:
	lda xsp, (xsp - 36)
	push xiz
	ld (xsp + 32), xde
	ld xiz, xbc
	ld (xsp + 36), xwa
	cp xiz, 0x1c0001c
	jrl z, AcLswPartPan_Match
	cp xiz, 0x1c0000f
	jrl z, AcLswPartPan_Confirm
	cp xiz, 0x1c0000d
	jrl z, AcLswPartPan_Paint
	cp xiz, 0x1c0000c
	jr z, AcLswPartPan_ShowHide
	cp xiz, 0x1c0000b
	jr z, AcLswPartPan_ShowHide
	ld xwa, (xsp + 36)
	ld xbc, xiz
	ld xde, (xsp + 32)
	call InheritedProc
	jrl AcLswPartPan_Return

AcLswPartPan_ShowHide:
	ld xwa, (xsp + 36)
	call GetViewInstance
	ld (xsp + 8), xhl
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 28)
	ld xbc, 0x1e10000
	call ApFuncCall
	ld (xsp + 30), hl
	ld bc, (xsp + 30)
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xsp + 8)
	lda xwa, (xwa + 28)
	cp bc, 0xffff
	jr z, AcLswPartPan_ShowHide_Unbounded
	ld xwa, (xwa)
	ld xbc, 0x1e10001
	call ApFuncCall
	ld (xsp + 28), hl
	ld wa, (xsp + 30)
	ld bc, (xsp + 28)
	call SndParam_LookupViaEncode
	jr AcLswPartPan_ShowHide_StoreAndForward

AcLswPartPan_ShowHide_Unbounded:
	ld xwa, (xwa)
	ld xbc, 0x1e10001
	call ApFuncCall
	ld xwa, xhl
	call SndParam_LookupReadOnly

AcLswPartPan_ShowHide_StoreAndForward:
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 32)
	ld (xwa), hl
	ld xwa, (xsp + 36)
	ld xbc, xiz
	ld xde, (xsp + 32)
	call InheritedProc
	jrl AcLswPartPan_ReturnHandled

AcLswPartPan_Paint:
	ld xwa, (xsp + 36)
	ld xbc, xiz
	ld xde, (xsp + 32)
	call InheritedProc
	ld xwa, (xsp + 36)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jrl AcLswPartPan_DispatchEvent

AcLswPartPan_Confirm:
	ld xwa, (xsp + 36)
	call GetViewInstance
	ld (xsp + 4), xhl
	lda xbc, (xsp + 20)
	ld xwa, (xsp + 36)
	call GetClientBox
	lda xwa, (xsp + 20)
	ld xbc, (xsp + 4)
	ld bc, (xbc + 22)
	call DrawBox
	lda xwa, (xsp + 16)
	lda xhl, (xsp + 20)
	ld bc, (xhl)
	inc 4, bc
	ld (xwa), bc
	lda xbc, (xsp + 12)
	ld de, (xhl + 4)
	dec 4, de
	ld (xbc), de
	inc 6, xhl
	ld de, (xhl)
	dec 4, de
	ld (xwa + 2), de
	ld de, (xhl)
	dec 4, de
	ld (xbc + 2), de
	lds de, 0
	call DrawLine
	lda xde, (xsp + 20)
	ld bc, (xde + 6)
	ld wa, bc
	sub wa, (xde + 2)
	exts xwa
	divs wa, 0x2
	sub bc, wa
	lda xwa, (xsp + 16)
	ld (xwa + 2), bc
	lda xbc, (xsp + 12)
	ld de, (xde)
	inc 4, de
	ld (xbc), de
	ld (xwa), de
	lds de, 0
	call DrawLine
	lda xbc, (xsp + 12)
	ld de, (xsp + 24)
	dec 4, de
	ld (xbc), de
	lda xwa, (xsp + 16)
	ld (xwa), de
	lds de, 0
	call DrawLine
	lda xbc, (xsp + 20)
	ld wa, (xbc + 4)
	sub wa, (xbc)
	exts xwa
	divs wa, 0x2
	ld de, (xbc)
	add de, wa
	lda xbc, (xsp + 12)
	ld (xbc), de
	lda xwa, (xsp + 16)
	ld (xwa), de
	lds de, 0
	call DrawLine
	lda xbc, (xsp + 20)
	ld wa, (xbc + 4)
	sub wa, (xbc)
	exts xwa
	divs wa, 0x4
	ld de, (xbc)
	add de, wa
	lda xbc, (xsp + 12)
	ld (xbc), de
	lda xwa, (xsp + 16)
	ld (xwa), de
	lds de, 0
	call DrawLine
	lda xwa, (xsp + 20)
	ld bc, (xwa + 4)
	ld de, bc
	sub de, (xwa)
	exts xde
	divs de, 0x4
	ld wa, de
	ld de, bc
	sub de, wa
	lda xbc, (xsp + 12)
	ld (xbc), de
	lda xwa, (xsp + 16)
	ld (xwa), de
	lds de, 0
	call DrawLine
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, 0x1e10002
	call ApFuncCall
	or xhl, xhl
	jrl z, AcLswPartPan_ReturnHandled
	lda xiz, (xsp + 20)
	lda xwa, (xiz + 4)
	ld (xsp + 8), xwa
	ld wa, (xwa)
	sub wa, (xiz)
	dec 6, wa
	ld bc, wa
	exts xbc
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 32)
	ld wa, (xwa)
	exts xwa
	sla xwa, 12
	call Math_MultiplyAccumulate
	ld xwa, xhl
	sra xwa, 15
	sra xwa, 0
	and xwa, 0x7f
	add xwa, xhl
	sra xwa, 7
	ld xbc, xwa
	sra xbc, 15
	sra xbc, 0
	and xbc, 0xfff
	add xbc, xwa
	sra xbc, 12
	incm 2, (xiz + 2)
	add bc, (xiz)
	inc 2, bc
	ld (xiz), bc
	inc 4, bc
	ld xwa, (xsp + 8)
	ld (xwa), bc
	decm 2, (xiz + 6)
	ld xwa, xiz
	ldw bc, 0xc1
	ldw de, 0xa
	call DrawDesignBox
	jrl AcLswPartPan_ReturnHandled

AcLswPartPan_Match:
	ld xwa, (xsp + 36)
	ld xbc, xiz
	ld xde, (xsp + 32)
	call InheritedProc
	ld xwa, (xsp + 36)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 32)
	ld (xsp + 8), xwa
	lda xbc, (xsp + 30)
	lda xde, (xsp + 28)
	ld xwa, (xsp + 32)
	call SndParam_DecodeMidiAddr
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xiz + 28)
	cp hl, 0xffff
	jr z, AcLswPartPan_Match_Unbounded
	ld xbc, 0x1e10000
	call ApFuncCall
	ld wa, (xsp + 30)
	extz xwa
	cp xwa, xhl
	jr nz, AcLswPartPan_ReturnHandled
	ld16_24 xde, 0x03e99e
	exts xde
	ld xwa, (xiz + 28)
	ld xbc, 0x1e10001
	call ApFuncCall
	ld wa, (xsp + 28)
	extz xwa
	cp xwa, xhl
	jr nz, AcLswPartPan_ReturnHandled
	ld xbc, (xiz + 32)
	ld xwa, (xsp + 32)
	ld wa, (xwa + 4)
	ld (xbc), wa
	ld xwa, (xsp + 36)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jr AcLswPartPan_DispatchEvent

AcLswPartPan_Match_Unbounded:
	ld xbc, 0x1e10001
	call ApFuncCall
	ld xwa, (xsp + 32)
	cp (xwa), xhl
	jr nz, AcLswPartPan_ReturnHandled
	ld xbc, (xiz + 32)
	ld xwa, (xsp + 8)
	ld wa, (xwa + 4)
	ld (xbc), wa
	ld xwa, (xsp + 36)
	ld xbc, 0x1c0000f
	lds32 xde, 0

AcLswPartPan_DispatchEvent:
	call SendEvent

AcLswPartPan_ReturnHandled:
	lds32 xhl, 0

AcLswPartPan_Return:
	pop xiz
	lda xsp, (xsp + 36)
	ret

SdpartLookupPartId:
	lds hl, 0
	cpw (xwa), 0xffff
	jr z, SdpartLookupPartId_CheckEnd

SdpartLookupPartId_Loop:
	cp (xwa), bc
	jr z, SdpartLookupPartId_CheckEnd
	inc 2, xwa
	inc 1, hl
	cpw (xwa), 0xffff
	jr nz, SdpartLookupPartId_Loop

SdpartLookupPartId_CheckEnd:
	cpw (xwa), 0xffff
	ret nz
	ldw hl, 0xffff
	ret

SdpartScrollDelta:
	ld hl, bc
	cp xwa, 0x1c00018
	jr z, SdpartScrollDelta_Negate
	cp xwa, 0x1c0001a
	jr z, SdpartScrollDelta_Down
	cp xwa, 0x1c00017
	jr z, SdpartScrollDelta_Up
	cp xwa, 0x1c00019
	jr nz, SdpartScrollDelta_Zero
	ret

SdpartScrollDelta_Up:
	ld hl, de
	ret

SdpartScrollDelta_Down:
	ld de, hl

SdpartScrollDelta_Negate:
	mul de, 0xffff
	ld hl, de
	ret

SdpartScrollDelta_Zero:
	lds hl, 0
	ret

SdpartUpdatePartUI:
	ld16_24 xbc, 0x03e99e
	ld wa, bc
	sla wa, 2
	lda_24 xde, 0xe952aa
	ld_sril3 XWA, 0x07, 0xe8, 0xe0
	bit_erpw 0xe2, 0x0f
	jr z, SdpartUpdatePartUI_Confirm
	add bc, bc
	lda_24 xwa, 0xe953ce
	ld_sriw3 DE, 0x07, 0xe0, 0xe4
	exts xde
	ld xwa, 0x1400004
	ld xbc, 0x1e0005e
	jp FuncCall

SdpartUpdatePartUI_Confirm:
	ld xwa, 0x3000a
	ld xbc, 0x1c0000f
	ld xde, 0xe95564
	jp SendEvent

LswSound:
	push xiz
	ld xiz, xwa
	lda_24 xhl, 0xe952aa
	cp xbc, 0x1e00083
	jrl z, LswSound_ReturnZero
	ld xix, xde
	sll xix, 2
	ld xwa, xhl
	add xwa, xix
	cp xbc, 0x1e10002
	jrl z, LswSound_GetSignedToggle
	cp xbc, 0x1e0003f
	jr z, LswSound_GetToggle
	cp xbc, 0x1e0003e
	jr z, LswSound_CheckActive
	cp xbc, 0x1e00041
	jr z, LswSound_StepReturn
	cp xbc, 0x1e10001
	jrl z, LswSound_ReturnZero
	cp xbc, 0x1e10000
	jr z, LswSound_GetPartId
	cp xbc, 0x1e00042
	jr nz, LswSound_ReturnZero
	ld xwa, (xde)
	srl xwa, 0
	ldi_werp 0xe2, 0
	extz xwa
	sll xwa, 2
	add xhl, xwa
	ld xwa, (xhl)
	bit_erpw 0xe2, 0x0f
	jr nz, LswSound_ReturnThis
	pushw 0xe9
	pushw 0x5576
	ld xwa, (xde + 8)
	push xwa
	call Strcpy
	inc 8, xsp

LswSound_ReturnThis:
	ld xhl, xiz
	jr LswSound_PopIzRet

LswSound_GetPartId:
	ld xwa, (xwa)
	bit_erpw 0xe2, 0x0e
	jr z, LswSound_LookupPartOffset
	ld xhl, 0xffffffff
	jr LswSound_PopIzRet

LswSound_LookupPartOffset:
	add xde, xde
	ld xwa, 0xe953ce
	add xwa, xde
	ld hl, (xwa)
	exts xhl
	jr LswSound_PopIzRet

LswSound_CheckActive:
	ld xwa, (xwa)
	bit_erpw 0xe2, 0x0f
	jr z, LswSound_ReturnZero

LswSound_StepReturn:
	lds32 xhl, 4
	jr LswSound_PopIzRet

LswSound_GetToggle:
	ld xwa, (xwa)
	and xwa, 0x80000000
	or xwa, xwa
	scc16 nz, hl
	extz xhl
	jr LswSound_PopIzRet

LswSound_GetSignedToggle:
	ld xwa, (xwa)
	and xwa, 0x80000000
	or xwa, xwa
	scc16 nz, hl
	exts xhl
	jr LswSound_PopIzRet

LswSound_ReturnZero:
	lds32 xhl, 0

LswSound_PopIzRet:
	pop xiz
	ret

LswVolume:
	push xiz
	ld xiz, xwa
	lda_24 xhl, 0xe952aa
	cp xbc, 0x1e00083
	jrl z, AudioCtrlMuteZeroReturn
	ld xix, xde
	sll xix, 2
	ld xwa, xhl
	add xwa, xix
	cp xbc, 0x1e10002
	jrl z, LswVolume_GetSignedToggle
	cp xbc, 0x1e0003f
	jrl z, LswVolume_GetToggle
	cp xbc, 0x1e0003e
	jrl z, LswVolume_CheckEnabled
	cp xbc, 0x1e00041
	jrl z, LswVolume_StepSize
	cp xbc, 0x1e10001
	jr z, LswVolume_GetSubParam
	cp xbc, 0x1e10000
	jr z, LswVolume_GetPartId
	cp xbc, 0x1e00042
	jrl nz, AudioCtrlMuteZeroReturn
	ld xwa, (xde)
	srl xwa, 0
	ldi_werp 0xe2, 0
	extz xwa
	sll xwa, 2
	add xhl, xwa
	ld xbc, (xde + 8)
	ld xwa, (xhl)
	bit 15, wa
	jr z, LswVolume_InactiveStr
	ld wa, (xde + 4)
	cp wa, 0x80
	jr ge, LswVolume_OverflowStr
	pushw wa
	pushw 0xe9
	pushw 0x5588
	push xbc
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	jr LswVolume_ReturnThis

LswVolume_OverflowStr:
	ld xwa, 0xe9558c
	jr LswVolume_CopyStr

LswVolume_InactiveStr:
	ld xwa, 0xe95592

LswVolume_CopyStr:
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp

LswVolume_ReturnThis:
	ld xhl, xiz
	jr AudioCtrl_PopIzRet3

LswVolume_GetPartId:
	ld xwa, (xwa)
	bit_erpw 0xe2, 0x0e
	jr z, LswVolume_LookupPartOffset
	ld xhl, 0xffffffff
	jr AudioCtrl_PopIzRet3

LswVolume_LookupPartOffset:
	add xde, xde
	ld xwa, 0xe953ce
	add xwa, xde
	ld hl, (xwa)
	exts xhl
	jr AudioCtrl_PopIzRet3

LswVolume_GetSubParam:
	cp xde, 0x17
	jr nz, LswVolume_DefaultSubParam
	ld xhl, 0x28801
	jr AudioCtrl_PopIzRet3

LswVolume_DefaultSubParam:
	lds32 xhl, 7
	jr AudioCtrl_PopIzRet3

LswVolume_StepSize:
	cp xde, 0x18
	jr nz, LswVolume_StepReturn
	lds32 xhl, 3
	jr AudioCtrl_PopIzRet3

LswVolume_CheckEnabled:
	ld xwa, (xwa)
	bit 15, wa
	jr z, AudioCtrlMuteZeroReturn

LswVolume_StepReturn:
	lds32 xhl, 4
	jr AudioCtrl_PopIzRet3

LswVolume_GetToggle:
	ld xwa, (xwa)
	and xwa, 0x8000
	or xwa, xwa
	scc16 nz, hl
	extz xhl
	jr AudioCtrl_PopIzRet3

LswVolume_GetSignedToggle:
	ld xwa, (xwa)
	and xwa, 0x8000
	or xwa, xwa
	scc16 nz, hl
	exts xhl
	jr AudioCtrl_PopIzRet3

AudioCtrlMuteZeroReturn:
	lds32 xhl, 0

AudioCtrl_PopIzRet3:
	pop xiz
	ret

LswMute:
	push xiz
	ld xiz, xwa
	lda_24 xhl, 0xe952aa
	cp xbc, 0x1e00083
	jrl z, AudioCtrlMutePitchReturn
	ld xix, xde
	sll xix, 2
	ld xwa, xhl
	add xwa, xix
	cp xbc, 0x1e10002
	jrl z, LswMute_GetSignedToggle
	cp xbc, 0x1e0003f
	jrl z, LswMute_GetToggle
	cp xbc, 0x1e0003e
	jrl z, LswMute_CheckEnabled
	cp xbc, 0x1e00041
	jrl z, LswMute_StepSize
	cp xbc, 0x1e10001
	jr z, LswMute_GetSubParam
	cp xbc, 0x1e10000
	jr z, LswMute_GetPartId
	cp xbc, 0x1e00042
	jrl nz, AudioCtrlMutePitchReturn
	ld xwa, (xde)
	srl xwa, 0
	ldi_werp 0xe2, 0
	extz xwa
	sll xwa, 2
	add xhl, xwa
	ld xbc, (xde + 8)
	ld xwa, (xhl)
	bit 15, wa
	jr z, LswMute_InactiveStr
	ld wa, (xde + 4)
	cp wa, 0x80
	jr ge, LswMute_OverflowStr
	pushw wa
	pushw 0xe9
	pushw 0x5598
	push xbc
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	jr LswMute_ReturnThis

LswMute_OverflowStr:
	ld xwa, 0xe9559c
	jr LswMute_CopyStr

LswMute_InactiveStr:
	ld xwa, 0xe955a2

LswMute_CopyStr:
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp

LswMute_ReturnThis:
	ld xhl, xiz
	jr AudioCtrl_PopIzRet2

LswMute_GetPartId:
	ld xwa, (xwa)
	bit_erpw 0xe2, 0x0e
	jr z, LswMute_LookupPartOffset
	ld xhl, 0xffffffff
	jr AudioCtrl_PopIzRet2

LswMute_LookupPartOffset:
	add xde, xde
	ld xwa, 0xe953ce
	add xwa, xde
	ld hl, (xwa)
	exts xhl
	jr AudioCtrl_PopIzRet2

LswMute_GetSubParam:
	cp xde, 0x17
	jr nz, LswMute_DefaultSubParam
	ld xhl, 0x2880b
	jr AudioCtrl_PopIzRet2

LswMute_DefaultSubParam:
	ld xhl, 0x8
	jr AudioCtrl_PopIzRet2

LswMute_StepSize:
	lds32 xhl, 3
	jr AudioCtrl_PopIzRet2

LswMute_CheckEnabled:
	ld xwa, (xwa)
	bit 15, wa
	jr z, AudioCtrlMutePitchReturn
	lds32 xhl, 4
	jr AudioCtrl_PopIzRet2

LswMute_GetToggle:
	ld xwa, (xwa)
	and xwa, 0x8000
	or xwa, xwa
	scc16 nz, hl
	extz xhl
	jr AudioCtrl_PopIzRet2

LswMute_GetSignedToggle:
	ld xwa, (xwa)
	and xwa, 0x8000
	or xwa, xwa
	scc16 nz, hl
	exts xhl
	jr AudioCtrl_PopIzRet2

AudioCtrlMutePitchReturn:
	lds32 xhl, 0

AudioCtrl_PopIzRet2:
	pop xiz
	ret

LswPan:
	push xiz
	ld xiz, xwa
	lda_24 xix, 0xe952aa
	cp xbc, 0x1e000b9
	jrl z, LswPan_ReturnCenter
	cp xbc, 0x1e000b8
	jrl z, LswPan_ReturnOne
	cp xbc, 0x1e00083
	jrl z, AudioCtrlTremoloZeroReturn
	ld xhl, xde
	sll xhl, 2
	ld xwa, xix
	add xwa, xhl
	ld xwa, (xwa)
	ld xhl, xwa
	and xhl, 0x4000
	cp xbc, 0x1e10002
	jrl z, LswPan_GetSignedToggle
	cp xbc, 0x1e0003f
	jrl z, LswPan_GetToggle
	cp xbc, 0x1e0003e
	jrl z, LswPan_CheckEnabled
	cp xbc, 0x1e00041
	jrl z, LswPan_StepReturn
	cp xbc, 0x1e10001
	jrl z, LswPan_GetSubParam
	cp xbc, 0x1e10000
	jr z, LswPan_GetPartId
	cp xbc, 0x1e00042
	jrl nz, AudioCtrlTremoloZeroReturn
	ld xwa, (xde)
	srl xwa, 0
	ldi_werp 0xe2, 0
	extz xwa
	sll xwa, 2
	add xix, xwa
	ld xbc, (xde + 8)
	ld xwa, (xix)
	bit 14, wa
	jr z, LswPan_InactiveStr
	ld wa, (xde + 4)
	cp wa, 0x40
	jr nz, LswPan_FormatOffset
	ld xwa, 0xe955a8
	jr LswPan_CopyStr

LswPan_FormatOffset:
	cp wa, 0x40
	jr ge, LswPan_FormatRight
	ldw de, 0x40
	sub de, wa
	pushw de
	ld xwa, 0xe955ac
	jr LswPan_SendCommand

LswPan_FormatRight:
	sub wa, 0x40
	pushw wa
	ld xwa, 0xe955b2

LswPan_SendCommand:
	push xwa
	push xbc
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	jr LswPan_ReturnThis

LswPan_InactiveStr:
	ld xwa, 0xe955b8

LswPan_CopyStr:
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp

LswPan_ReturnThis:
	ld xhl, xiz
	jr AudioCtrl_PopIzRet6

LswPan_GetPartId:
	add xde, xde
	ld xwa, 0xe953ce
	add xwa, xde
	ld hl, (xwa)
	exts xhl
	jr AudioCtrl_PopIzRet6

LswPan_GetSubParam:
	ld xhl, 0xa
	jr AudioCtrl_PopIzRet6

LswPan_CheckEnabled:
	bit 14, wa
	jr z, AudioCtrlTremoloZeroReturn

LswPan_StepReturn:
	lds32 xhl, 4
	jr AudioCtrl_PopIzRet6

LswPan_GetToggle:
	or xhl, xhl
	scc16 nz, hl
	extz xhl
	jr AudioCtrl_PopIzRet6

LswPan_GetSignedToggle:
	or xhl, xhl
	scc16 nz, hl
	exts xhl
	jr AudioCtrl_PopIzRet6

AudioCtrlTremoloZeroReturn:
	lds32 xhl, 0
	jr AudioCtrl_PopIzRet6

LswPan_ReturnOne:
	lds32 xhl, 1
	jr AudioCtrl_PopIzRet6

LswPan_ReturnCenter:
	ld xhl, 0x40

AudioCtrl_PopIzRet6:
	pop xiz
	ret

LswReverb:
	push xiz
	ld xiz, xwa
	lda_24 xhl, 0xe952aa
	cp xbc, 0x1e00083
	jrl z, AudioCtrlVibratoZeroReturn
	ld xix, xde
	sll xix, 2
	ld xwa, xhl
	add xwa, xix
	cp xbc, 0x1e10002
	jrl z, LswReverb_GetSignedToggle
	cp xbc, 0x1e0003f
	jrl z, LswReverb_GetToggle
	cp xbc, 0x1e0003e
	jrl z, LswReverb_CheckEnabled
	cp xbc, 0x1e00041
	jrl z, LswReverb_StepSize
	cp xbc, 0x1e10001
	jr z, LswReverb_GetSubParam
	cp xbc, 0x1e10000
	jr z, LswReverb_GetPartId
	cp xbc, 0x1e00042
	jrl nz, AudioCtrlVibratoZeroReturn
	ld xwa, (xde)
	srl xwa, 0
	ldi_werp 0xe2, 0
	extz xwa
	sll xwa, 2
	add xhl, xwa
	ld xbc, (xde + 8)
	ld xwa, (xhl)
	bit 13, wa
	jr z, LswReverb_InactiveStr
	pushm (xde + 4)
	pushw 0xe9
	pushw 0x55bc
	push xbc
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	jr LswReverb_ReturnThis

LswReverb_InactiveStr:
	pushw 0xe9
	pushw 0x55c0
	push xbc
	call Strcpy
	inc 8, xsp

LswReverb_ReturnThis:
	ld xhl, xiz
	jr AudioCtrl_PopIzRet1

LswReverb_GetPartId:
	ld xwa, (xwa)
	bit_erpw 0xe2, 0x0e
	jr z, LswReverb_LookupPartOffset
	ld xhl, 0xffffffff
	jr AudioCtrl_PopIzRet1

LswReverb_LookupPartOffset:
	add xde, xde
	ld xwa, 0xe953ce
	add xwa, xde
	ld hl, (xwa)
	exts xhl
	jr AudioCtrl_PopIzRet1

LswReverb_GetSubParam:
	cp xde, 0x17
	jr nz, LswReverb_DefaultSubParam
	ld xhl, 0x28802
	jr AudioCtrl_PopIzRet1

LswReverb_DefaultSubParam:
	ld xhl, 0x5b
	jr AudioCtrl_PopIzRet1

LswReverb_StepSize:
	cp xde, 0x17
	jr nz, LswReverb_StepReturn
	lds32 xhl, 3
	jr AudioCtrl_PopIzRet1

LswReverb_CheckEnabled:
	ld xwa, (xwa)
	bit 13, wa
	jr z, AudioCtrlVibratoZeroReturn

LswReverb_StepReturn:
	lds32 xhl, 4
	jr AudioCtrl_PopIzRet1

LswReverb_GetToggle:
	ld xwa, (xwa)
	and xwa, 0x2000
	or xwa, xwa
	scc16 nz, hl
	extz xhl
	jr AudioCtrl_PopIzRet1

LswReverb_GetSignedToggle:
	ld xwa, (xwa)
	and xwa, 0x2000
	or xwa, xwa
	scc16 nz, hl
	exts xhl
	jr AudioCtrl_PopIzRet1

AudioCtrlVibratoZeroReturn:
	lds32 xhl, 0

AudioCtrl_PopIzRet1:
	pop xiz
	ret

LswDSPEffect:
	push xiz
	ld xiz, xwa
	lda_24 xhl, 0xe952aa
	cp xbc, 0x1e00083
	jrl z, LswDSPEffZeroReturn
	ld xix, xde
	sll xix, 2
	ld xwa, xhl
	add xwa, xix
	cp xbc, 0x1e10002
	jrl z, LswDSPEff_GetSignedToggle
	cp xbc, 0x1e0003f
	jrl z, LswDSPEff_GetToggle
	cp xbc, 0x1e0003e
	jr z, LswDSPEff_CheckEnabled
	cp xbc, 0x1e00041
	jr z, LswDSPEff_StepReturn
	cp xbc, 0x1e10001
	jr z, LswDSPEff_GetSubParam
	cp xbc, 0x1e10000
	jr z, LswDSPEff_GetPartId
	cp xbc, 0x1e00042
	jr nz, LswDSPEffZeroReturn
	ld xwa, (xde)
	srl xwa, 0
	ldi_werp 0xe2, 0
	extz xwa
	sll xwa, 2
	add xhl, xwa
	ld xbc, (xde + 8)
	ld xwa, (xhl)
	bit 12, wa
	jr z, LswDSPEff_InactiveStr
	pushm (xde + 4)
	pushw 0xe9
	pushw 0x55c4
	push xbc
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	jr LswDSPEff_ReturnThis

LswDSPEff_InactiveStr:
	pushw 0xe9
	pushw 0x55c8
	push xbc
	call Strcpy
	inc 8, xsp

LswDSPEff_ReturnThis:
	ld xhl, xiz
	jr LswDSPEffect_PopIzRet

LswDSPEff_GetPartId:
	add xde, xde
	ld xwa, 0xe953ce
	add xwa, xde
	ld hl, (xwa)
	exts xhl
	jr LswDSPEffect_PopIzRet

LswDSPEff_GetSubParam:
	ld xhl, 0x5d
	jr LswDSPEffect_PopIzRet

LswDSPEff_CheckEnabled:
	ld xwa, (xwa)
	bit 12, wa
	jr z, LswDSPEffZeroReturn

LswDSPEff_StepReturn:
	lds32 xhl, 4
	jr LswDSPEffect_PopIzRet

LswDSPEff_GetToggle:
	ld xwa, (xwa)
	and xwa, 0x1000
	or xwa, xwa
	scc16 nz, hl
	extz xhl
	jr LswDSPEffect_PopIzRet

LswDSPEff_GetSignedToggle:
	ld xwa, (xwa)
	and xwa, 0x1000
	or xwa, xwa
	scc16 nz, hl
	exts xhl
	jr LswDSPEffect_PopIzRet

LswDSPEffZeroReturn:
	lds32 xhl, 0

LswDSPEffect_PopIzRet:
	pop xiz
	ret

LswDigitalEffect:
	push xiz
	ld xiz, xwa
	lda_24 xhl, 0xe952aa
	cp xbc, 0x1e00083
	jrl z, LswDigitalEffZeroReturn
	ld xix, xde
	sll xix, 2
	ld xwa, xhl
	add xwa, xix
	cp xbc, 0x1e10002
	jrl z, LswDigEff_GetSignedToggle
	cp xbc, 0x1e0003f
	jrl z, LswDigEff_GetToggle
	cp xbc, 0x1e0003e
	jr z, LswDigEff_CheckEnabled
	cp xbc, 0x1e00041
	jr z, LswDigEff_StepReturn
	cp xbc, 0x1e10001
	jr z, LswDigEff_GetSubParam
	cp xbc, 0x1e10000
	jr z, LswDigEff_GetPartId
	cp xbc, 0x1e00042
	jrl nz, LswDigitalEffZeroReturn
	ld xwa, (xde)
	srl xwa, 0
	ldi_werp 0xe2, 0
	extz xwa
	sll xwa, 2
	add xhl, xwa
	ld xbc, (xde + 8)
	ld xwa, (xhl)
	bit 3, wa
	jr z, LswDigEff_InactiveStr
	cpw (xde + 4), 0x0
	jr z, LswDigEff_StrOff
	ld xwa, 0xe955cc
	jr LswDigEff_CopyStr

LswDigEff_StrOff:
	ld xwa, 0xe955d0
	jr LswDigEff_CopyStr

LswDigEff_InactiveStr:
	ld xwa, 0xe955d4

LswDigEff_CopyStr:
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp
	ld xhl, xiz
	jr LswDigitalEffect_PopIzRet

LswDigEff_GetPartId:
	add xde, xde
	ld xwa, 0xe953ce
	add xwa, xde
	ld hl, (xwa)
	exts xhl
	jr LswDigitalEffect_PopIzRet

LswDigEff_GetSubParam:
	ld xhl, 0x5e
	jr LswDigitalEffect_PopIzRet

LswDigEff_CheckEnabled:
	ld xwa, (xwa)
	bit 3, wa
	jr z, LswDigitalEffZeroReturn

LswDigEff_StepReturn:
	lds32 xhl, 4
	jr LswDigitalEffect_PopIzRet

LswDigEff_GetToggle:
	ld xwa, (xwa)
	and xwa, 0x8
	or xwa, xwa
	scc16 nz, hl
	extz xhl
	jr LswDigitalEffect_PopIzRet

LswDigEff_GetSignedToggle:
	ld xwa, (xwa)
	and xwa, 0x8
	or xwa, xwa
	scc16 nz, hl
	exts xhl
	jr LswDigitalEffect_PopIzRet

LswDigitalEffZeroReturn:
	lds32 xhl, 0

LswDigitalEffect_PopIzRet:
	pop xiz
	ret

LswSustain:
	push xiz
	ld xiz, xwa
	lda_24 xhl, 0xe952aa
	cp xbc, 0x1e00083
	jrl z, LswSustainZeroReturn2
	ld xix, xde
	sll xix, 2
	ld xwa, xhl
	add xwa, xix
	cp xbc, 0x1e10002
	jrl z, LswSust_GetSignedToggle
	cp xbc, 0x1e0003f
	jrl z, LswSust_GetToggle
	cp xbc, 0x1e0003e
	jr z, LswSust_CheckEnabled
	cp xbc, 0x1e00041
	jr z, LswSust_StepReturn
	cp xbc, 0x1e10001
	jr z, LswSust_GetSubParam
	cp xbc, 0x1e10000
	jr z, LswSust_GetPartId
	cp xbc, 0x1e00042
	jrl nz, LswSustainZeroReturn2
	ld xwa, (xde)
	srl xwa, 0
	ldi_werp 0xe2, 0
	extz xwa
	sll xwa, 2
	add xhl, xwa
	ld xbc, (xde + 8)
	ld xwa, (xhl)
	bit 11, wa
	jr z, LswSust_InactiveStr
	cpw (xde + 4), 0x0
	jr z, LswSust_StrOff
	ld xwa, 0xe955d8
	jr LswSust_CopyStr

LswSust_StrOff:
	ld xwa, 0xe955dc
	jr LswSust_CopyStr

LswSust_InactiveStr:
	ld xwa, 0xe955e0

LswSust_CopyStr:
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp
	ld xhl, xiz
	jr LswSustain_PopIzRet2

LswSust_GetPartId:
	add xde, xde
	ld xwa, 0xe953ce
	add xwa, xde
	ld hl, (xwa)
	exts xhl
	jr LswSustain_PopIzRet2

LswSust_GetSubParam:
	ld xhl, 0x40
	jr LswSustain_PopIzRet2

LswSust_CheckEnabled:
	ld xwa, (xwa)
	bit 11, wa
	jr z, LswSustainZeroReturn2

LswSust_StepReturn:
	lds32 xhl, 4
	jr LswSustain_PopIzRet2

LswSust_GetToggle:
	ld xwa, (xwa)
	and xwa, 0x800
	or xwa, xwa
	scc16 nz, hl
	extz xhl
	jr LswSustain_PopIzRet2

LswSust_GetSignedToggle:
	ld xwa, (xwa)
	and xwa, 0x800
	or xwa, xwa
	scc16 nz, hl
	exts xhl
	jr LswSustain_PopIzRet2

LswSustainZeroReturn2:
	lds32 xhl, 0

LswSustain_PopIzRet2:
	pop xiz
	ret

LswSustainLength:
	push xiz
	ld xiz, xwa
	lda_24 xhl, 0xe952aa
	cp xbc, 0x1e00083
	jrl z, LswSustainLenZeroReturn
	ld xix, xde
	sll xix, 2
	ld xwa, xhl
	add xwa, xix
	cp xbc, 0x1e10002
	jrl z, LswSustLen_GetSignedToggle
	cp xbc, 0x1e0003f
	jrl z, LswSustLen_GetToggle
	cp xbc, 0x1e0003e
	jr z, LswSustLen_CheckEnabled
	cp xbc, 0x1e00041
	jr z, LswSustLen_StepReturn
	cp xbc, 0x1e10001
	jr z, LswSustLen_GetSubParam
	cp xbc, 0x1e10000
	jr z, LswSustLen_GetPartId
	cp xbc, 0x1e00042
	jrl nz, LswSustainLenZeroReturn
	ld xwa, (xde)
	srl xwa, 0
	ldi_werp 0xe2, 0
	extz xwa
	sll xwa, 2
	add xhl, xwa
	ld xbc, (xde + 8)
	ld xwa, (xhl)
	bit 10, wa
	jr z, LswSustLen_InactiveStr
	ld wa, (xde + 4)
	inc 1, wa
	pushw wa
	pushw 0xe9
	pushw 0x55e4
	push xbc
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	jr LswSustLen_ReturnThis

LswSustLen_InactiveStr:
	pushw 0xe9
	pushw 0x55e8
	push xbc
	call Strcpy
	inc 8, xsp

LswSustLen_ReturnThis:
	ld xhl, xiz
	jr LswSustainLength_PopIzRet

LswSustLen_GetPartId:
	add xde, xde
	ld xwa, 0xe953ce
	add xwa, xde
	ld hl, (xwa)
	exts xhl
	jr LswSustainLength_PopIzRet

LswSustLen_GetSubParam:
	ld xhl, 0x600
	jr LswSustainLength_PopIzRet

LswSustLen_CheckEnabled:
	ld xwa, (xwa)
	bit 10, wa
	jr z, LswSustainLenZeroReturn

LswSustLen_StepReturn:
	lds32 xhl, 4
	jr LswSustainLength_PopIzRet

LswSustLen_GetToggle:
	ld xwa, (xwa)
	and xwa, 0x400
	or xwa, xwa
	scc16 nz, hl
	extz xhl
	jr LswSustainLength_PopIzRet

LswSustLen_GetSignedToggle:
	ld xwa, (xwa)
	and xwa, 0x400
	or xwa, xwa
	scc16 nz, hl
	exts xhl
	jr LswSustainLength_PopIzRet

LswSustainLenZeroReturn:
	lds32 xhl, 0

LswSustainLength_PopIzRet:
	pop xiz
	ret

LswKeyShift:
	push xiz
	ld xiz, xwa
	lda_24 xhl, 0xe952aa
	cp xbc, 0x1e000b9
	jrl z, LswKeyShift_ReturnCenter
	cp xbc, 0x1e000b8
	jrl z, LswKeyShift_ReturnOne
	cp xbc, 0x1e00083
	jrl z, AudioCtrlChorusZeroReturn
	ld xix, xde
	sll xix, 2
	ld xwa, xhl
	add xwa, xix
	cp xbc, 0x1e10002
	jrl z, LswKeyShift_GetSignedToggle
	cp xbc, 0x1e0003f
	jrl z, LswKeyShift_GetToggle
	cp xbc, 0x1e0003e
	jrl z, LswKeyShift_CheckEnabled
	cp xbc, 0x1e00041
	jrl z, LswKeyShift_StepReturn
	cp xbc, 0x1e10001
	jr z, LswKeyShift_GetSubParam
	cp xbc, 0x1e10000
	jr z, LswKeyShift_GetPartId
	cp xbc, 0x1e00042
	jrl nz, AudioCtrlChorusZeroReturn
	ld xwa, (xde)
	srl xwa, 0
	ldi_werp 0xe2, 0
	extz xwa
	sll xwa, 2
	add xhl, xwa
	ld xbc, (xde + 8)
	ld xwa, (xhl)
	bit 9, wa
	jr z, LswKeyShift_InactiveStr
	ld wa, (xde + 4)
	sub wa, 0x40
	jr z, LswKeyShift_ZeroStr
	pushw wa
	pushw 0xe9
	pushw 0x55ec
	push xbc
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	jr LswKeyShift_ReturnThis

LswKeyShift_ZeroStr:
	ld xwa, 0xe955f2
	jr LswKeyShift_CopyStr

LswKeyShift_InactiveStr:
	ld xwa, 0xe955f6

LswKeyShift_CopyStr:
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp

LswKeyShift_ReturnThis:
	ld xhl, xiz
	jr AudioCtrl_PopIzRet5

LswKeyShift_GetPartId:
	add xde, xde
	ld xwa, 0xe953ce
	add xwa, xde
	ld hl, (xwa)
	exts xhl
	jr AudioCtrl_PopIzRet5

LswKeyShift_GetSubParam:
	ld xhl, 0x82
	jr AudioCtrl_PopIzRet5

LswKeyShift_CheckEnabled:
	ld xwa, (xwa)
	bit 9, wa
	jr z, AudioCtrlChorusZeroReturn

LswKeyShift_StepReturn:
	lds32 xhl, 4
	jr AudioCtrl_PopIzRet5

LswKeyShift_GetToggle:
	ld xwa, (xwa)
	and xwa, 0x200
	or xwa, xwa
	scc16 nz, hl
	extz xhl
	jr AudioCtrl_PopIzRet5

LswKeyShift_GetSignedToggle:
	ld xwa, (xwa)
	and xwa, 0x200
	or xwa, xwa
	scc16 nz, hl
	exts xhl
	jr AudioCtrl_PopIzRet5

AudioCtrlChorusZeroReturn:
	lds32 xhl, 0
	jr AudioCtrl_PopIzRet5

LswKeyShift_ReturnOne:
	lds32 xhl, 1
	jr AudioCtrl_PopIzRet5

LswKeyShift_ReturnCenter:
	ld xhl, 0x40

AudioCtrl_PopIzRet5:
	pop xiz
	ret

LswTuning:
	push xiz
	ld xiz, xwa
	lda_24 xhl, 0xe952aa
	cp xbc, 0x1e000b9
	jrl z, LswTuning_ReturnCenter
	cp xbc, 0x1e000b8
	jrl z, LswTuning_ReturnOne
	cp xbc, 0x1e00083
	jrl z, AudioCtrlReverbZeroReturn
	ld xix, xde
	sll xix, 2
	ld xwa, xhl
	add xwa, xix
	cp xbc, 0x1e10002
	jrl z, LswTuning_GetSignedToggle
	cp xbc, 0x1e0003f
	jrl z, LswTuning_GetToggle
	cp xbc, 0x1e0003e
	jrl z, LswTuning_CheckEnabled
	cp xbc, 0x1e00041
	jrl z, LswTuning_StepReturn
	cp xbc, 0x1e10001
	jr z, LswTuning_GetSubParam
	cp xbc, 0x1e10000
	jr z, LswTuning_GetPartId
	cp xbc, 0x1e00042
	jrl nz, AudioCtrlReverbZeroReturn
	ld xwa, (xde)
	srl xwa, 0
	ldi_werp 0xe2, 0
	extz xwa
	sll xwa, 2
	add xhl, xwa
	ld xbc, (xde + 8)
	ld xwa, (xhl)
	bit 8, wa
	jr z, LswTuning_InactiveStr
	ld wa, (xde + 4)
	sub wa, 0x80
	jr z, LswTuning_ZeroStr
	pushw wa
	pushw 0xe9
	pushw 0x55fa
	push xbc
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	jr LswTuning_ReturnThis

LswTuning_ZeroStr:
	ld xwa, 0xe95600
	jr LswTuning_CopyStr

LswTuning_InactiveStr:
	ld xwa, 0xe95606

LswTuning_CopyStr:
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp

LswTuning_ReturnThis:
	ld xhl, xiz
	jr AudioCtrl_PopIzRet4

LswTuning_GetPartId:
	add xde, xde
	ld xwa, 0xe953ce
	add xwa, xde
	ld hl, (xwa)
	exts xhl
	jr AudioCtrl_PopIzRet4

LswTuning_GetSubParam:
	ld xhl, 0x81
	jr AudioCtrl_PopIzRet4

LswTuning_CheckEnabled:
	ld xwa, (xwa)
	bit 8, wa
	jr z, AudioCtrlReverbZeroReturn

LswTuning_StepReturn:
	lds32 xhl, 4
	jr AudioCtrl_PopIzRet4

LswTuning_GetToggle:
	ld xwa, (xwa)
	and xwa, 0x100
	or xwa, xwa
	scc16 nz, hl
	extz xhl
	jr AudioCtrl_PopIzRet4

LswTuning_GetSignedToggle:
	ld xwa, (xwa)
	and xwa, 0x100
	or xwa, xwa
	scc16 nz, hl
	exts xhl
	jr AudioCtrl_PopIzRet4

AudioCtrlReverbZeroReturn:
	lds32 xhl, 0
	jr AudioCtrl_PopIzRet4

LswTuning_ReturnOne:
	lds32 xhl, 1
	jr AudioCtrl_PopIzRet4

LswTuning_ReturnCenter:
	ld xhl, 0x80

AudioCtrl_PopIzRet4:
	pop xiz
	ret

LswBendRange:
	push xiz
	ld xiz, xwa
	lda_24 xhl, 0xe952aa
	cp xbc, 0x1e00083
	jrl z, LswBendRangeZeroReturn
	ld xix, xde
	sll xix, 2
	ld xwa, xhl
	add xwa, xix
	cp xbc, 0x1e10002
	jrl z, LswBendRng_GetSignedToggle
	cp xbc, 0x1e0003f
	jrl z, LswBendRng_GetToggle
	cp xbc, 0x1e0003e
	jr z, LswBendRng_CheckEnabled
	cp xbc, 0x1e00041
	jr z, LswBendRng_StepReturn
	cp xbc, 0x1e10001
	jr z, LswBendRng_GetSubParam
	cp xbc, 0x1e10000
	jr z, LswBendRng_GetPartId
	cp xbc, 0x1e00042
	jr nz, LswBendRangeZeroReturn
	ld xwa, (xde)
	srl xwa, 0
	ldi_werp 0xe2, 0
	extz xwa
	sll xwa, 2
	add xhl, xwa
	ld xbc, (xde + 8)
	ld xwa, (xhl)
	bit 7, wa
	jr z, LswBendRng_InactiveStr
	pushm (xde + 4)
	pushw 0xe9
	pushw 0x560c
	push xbc
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	jr LswBendRng_ReturnThis

LswBendRng_InactiveStr:
	pushw 0xe9
	pushw 0x5610
	push xbc
	call Strcpy
	inc 8, xsp

LswBendRng_ReturnThis:
	ld xhl, xiz
	jr LswBendRange_PopIzRet

LswBendRng_GetPartId:
	add xde, xde
	ld xwa, 0xe953ce
	add xwa, xde
	ld hl, (xwa)
	exts xhl
	jr LswBendRange_PopIzRet

LswBendRng_GetSubParam:
	ld xhl, 0x80
	jr LswBendRange_PopIzRet

LswBendRng_CheckEnabled:
	ld xwa, (xwa)
	bit 7, wa
	jr z, LswBendRangeZeroReturn

LswBendRng_StepReturn:
	lds32 xhl, 4
	jr LswBendRange_PopIzRet

LswBendRng_GetToggle:
	ld xwa, (xwa)
	and xwa, 0x80
	or xwa, xwa
	scc16 nz, hl
	extz xhl
	jr LswBendRange_PopIzRet

LswBendRng_GetSignedToggle:
	ld xwa, (xwa)
	and xwa, 0x80
	or xwa, xwa
	scc16 nz, hl
	exts xhl
	jr LswBendRange_PopIzRet

LswBendRangeZeroReturn:
	lds32 xhl, 0

LswBendRange_PopIzRet:
	pop xiz
	ret

LswGlidePedal:
	push xiz
	ld xiz, xwa
	lda_24 xhl, 0xe952aa
	cp xbc, 0x1e00083
	jrl z, LswGlideZeroReturn
	ld xix, xde
	sll xix, 2
	ld xwa, xhl
	add xwa, xix
	cp xbc, 0x1e10002
	jrl z, LswGlide_GetSignedToggle
	cp xbc, 0x1e0003f
	jrl z, LswGlide_GetToggle
	cp xbc, 0x1e0003e
	jr z, LswGlide_CheckEnabled
	cp xbc, 0x1e00041
	jr z, LswGlide_StepSize
	cp xbc, 0x1e10001
	jr z, LswGlide_GetSubParam
	cp xbc, 0x1e10000
	jr z, LswGlide_GetPartId
	cp xbc, 0x1e00042
	jrl nz, LswGlideZeroReturn
	ld xwa, (xde)
	srl xwa, 0
	ldi_werp 0xe2, 0
	extz xwa
	sll xwa, 2
	add xhl, xwa
	ld xbc, (xde + 8)
	ld xwa, (xhl)
	bit 6, wa
	jr z, LswGlide_InactiveStr
	cpw (xde + 4), 0x0
	jr z, LswGlide_StrOff
	ld xwa, 0xe95614
	jr LswGlide_CopyStr

LswGlide_StrOff:
	ld xwa, 0xe95618
	jr LswGlide_CopyStr

LswGlide_InactiveStr:
	ld xwa, 0xe9561c

LswGlide_CopyStr:
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp
	ld xhl, xiz
	jr LswGlide_PopIzRet

LswGlide_GetPartId:
	add xde, xde
	ld xwa, 0xe953ce
	add xwa, xde
	ld hl, (xwa)
	exts xhl
	jr LswGlide_PopIzRet

LswGlide_GetSubParam:
	ld xhl, 0x603
	jr LswGlide_PopIzRet

LswGlide_StepSize:
	lds32 xhl, 3
	jr LswGlide_PopIzRet

LswGlide_CheckEnabled:
	ld xwa, (xwa)
	bit 6, wa
	jr z, LswGlideZeroReturn
	lds32 xhl, 4
	jr LswGlide_PopIzRet

LswGlide_GetToggle:
	ld xwa, (xwa)
	and xwa, 0x40
	or xwa, xwa
	scc16 nz, hl
	extz xhl
	jr LswGlide_PopIzRet

LswGlide_GetSignedToggle:
	ld xwa, (xwa)
	and xwa, 0x40
	or xwa, xwa
	scc16 nz, hl
	exts xhl
	jr LswGlide_PopIzRet

LswGlideZeroReturn:
	lds32 xhl, 0

LswGlide_PopIzRet:
	pop xiz
	ret

LswSustainPedal:
	push xiz
	ld xiz, xwa
	lda_24 xhl, 0xe952aa
	cp xbc, 0x1e00083
	jrl z, LswSustainZeroReturn
	ld xix, xde
	sll xix, 2
	ld xwa, xhl
	add xwa, xix
	cp xbc, 0x1e10002
	jrl z, LswSustPedal_GetSignedToggle
	cp xbc, 0x1e0003f
	jrl z, LswSustPedal_GetToggle
	cp xbc, 0x1e0003e
	jr z, LswSustPedal_CheckEnabled
	cp xbc, 0x1e00041
	jr z, LswSustPedal_StepSize
	cp xbc, 0x1e10001
	jr z, LswSustPedal_GetSubParam
	cp xbc, 0x1e10000
	jr z, LswSustPedal_GetPartId
	cp xbc, 0x1e00042
	jrl nz, LswSustainZeroReturn
	ld xwa, (xde)
	srl xwa, 0
	ldi_werp 0xe2, 0
	extz xwa
	sll xwa, 2
	add xhl, xwa
	ld xbc, (xde + 8)
	ld xwa, (xhl)
	bit 5, wa
	jr z, LswSustPedal_InactiveStr
	cpw (xde + 4), 0x0
	jr z, LswSustPedal_StrOff
	ld xwa, 0xe95620
	jr LswSustPedal_CopyStr

LswSustPedal_StrOff:
	ld xwa, 0xe95624
	jr LswSustPedal_CopyStr

LswSustPedal_InactiveStr:
	ld xwa, 0xe95628

LswSustPedal_CopyStr:
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp
	ld xhl, xiz
	jr LswSustain_PopIzRet

LswSustPedal_GetPartId:
	add xde, xde
	ld xwa, 0xe953ce
	add xwa, xde
	ld hl, (xwa)
	exts xhl
	jr LswSustain_PopIzRet

LswSustPedal_GetSubParam:
	ld xhl, 0x601
	jr LswSustain_PopIzRet

LswSustPedal_StepSize:
	lds32 xhl, 3
	jr LswSustain_PopIzRet

LswSustPedal_CheckEnabled:
	ld xwa, (xwa)
	bit 5, wa
	jr z, LswSustainZeroReturn
	lds32 xhl, 4
	jr LswSustain_PopIzRet

LswSustPedal_GetToggle:
	ld xwa, (xwa)
	and xwa, 0x20
	or xwa, xwa
	scc16 nz, hl
	extz xhl
	jr LswSustain_PopIzRet

LswSustPedal_GetSignedToggle:
	ld xwa, (xwa)
	and xwa, 0x20
	or xwa, xwa
	scc16 nz, hl
	exts xhl
	jr LswSustain_PopIzRet

LswSustainZeroReturn:
	lds32 xhl, 0

LswSustain_PopIzRet:
	pop xiz
	ret

LswKeyScaling:
	push xiz
	ld xiz, xwa
	lda_24 xhl, 0xe952aa
	cp xbc, 0x1e00083
	jrl z, LswKeyScaleZeroReturn
	ld xix, xde
	sll xix, 2
	ld xwa, xhl
	add xwa, xix
	cp xbc, 0x1e10002
	jrl z, LswKeyScale_GetSignedToggle
	cp xbc, 0x1e0003f
	jrl z, LswKeyScale_GetToggle
	cp xbc, 0x1e0003e
	jr z, LswKeyScale_CheckEnabled
	cp xbc, 0x1e00041
	jr z, LswKeyScale_StepSize
	cp xbc, 0x1e10001
	jr z, LswKeyScale_GetSubParam
	cp xbc, 0x1e10000
	jr z, LswKeyScale_GetPartId
	cp xbc, 0x1e00042
	jrl nz, LswKeyScaleZeroReturn
	ld xwa, (xde)
	srl xwa, 0
	ldi_werp 0xe2, 0
	extz xwa
	sll xwa, 2
	add xhl, xwa
	ld xbc, (xde + 8)
	ld xwa, (xhl)
	bit 4, wa
	jr z, LswKeyScale_InactiveStr
	cpw (xde + 4), 0x0
	jr z, LswKeyScale_StrOff
	ld xwa, 0xe9562c
	jr LswKeyScale_CopyStr

LswKeyScale_StrOff:
	ld xwa, 0xe95630
	jr LswKeyScale_CopyStr

LswKeyScale_InactiveStr:
	ld xwa, 0xe95634

LswKeyScale_CopyStr:
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp
	ld xhl, xiz
	jr LswKeyScale_PopIzRet

LswKeyScale_GetPartId:
	add xde, xde
	ld xwa, 0xe953ce
	add xwa, xde
	ld hl, (xwa)
	exts xhl
	jr LswKeyScale_PopIzRet

LswKeyScale_GetSubParam:
	ld xhl, 0x602
	jr LswKeyScale_PopIzRet

LswKeyScale_StepSize:
	lds32 xhl, 3
	jr LswKeyScale_PopIzRet

LswKeyScale_CheckEnabled:
	ld xwa, (xwa)
	bit 4, wa
	jr z, LswKeyScaleZeroReturn
	lds32 xhl, 4
	jr LswKeyScale_PopIzRet

LswKeyScale_GetToggle:
	ld xwa, (xwa)
	and xwa, 0x10
	or xwa, xwa
	scc16 nz, hl
	extz xhl
	jr LswKeyScale_PopIzRet

LswKeyScale_GetSignedToggle:
	ld xwa, (xwa)
	and xwa, 0x10
	or xwa, xwa
	scc16 nz, hl
	exts xhl
	jr LswKeyScale_PopIzRet

LswKeyScaleZeroReturn:
	lds32 xhl, 0

LswKeyScale_PopIzRet:
	pop xiz
	ret

LswAfterTouch:
	push xiz
	ld xiz, xwa
	lda_24 xhl, 0xe952aa
	cp xbc, 0x1e00083
	jrl z, LswAfterTouchZeroReturn
	ld xix, xde
	sll xix, 2
	ld xwa, xhl
	add xwa, xix
	cp xbc, 0x1e10002
	jrl z, LswAfterTouch_GetSignedToggle
	cp xbc, 0x1e0003f
	jrl z, LswAfterTouch_GetToggle
	cp xbc, 0x1e0003e
	jr z, LswAfterTouch_CheckEnabled
	cp xbc, 0x1e00041
	jr z, LswAfterTouch_StepSize
	cp xbc, 0x1e10001
	jr z, LswAfterTouch_GetSubParam
	cp xbc, 0x1e10000
	jr z, LswAfterTouch_GetPartId
	cp xbc, 0x1e00042
	jrl nz, LswAfterTouchZeroReturn
	ld xwa, (xde)
	srl xwa, 0
	ldi_werp 0xe2, 0
	extz xwa
	sll xwa, 2
	add xhl, xwa
	ld xbc, (xde + 8)
	ld xwa, (xhl)
	bit 2, wa
	jr z, LswAfterTouch_InactiveStr
	cpw (xde + 4), 0x0
	jr z, LswAfterTouch_StrOff
	ld xwa, 0xe95638
	jr LswAfterTouch_CopyStr

LswAfterTouch_StrOff:
	ld xwa, 0xe9563c
	jr LswAfterTouch_CopyStr

LswAfterTouch_InactiveStr:
	ld xwa, 0xe95640

LswAfterTouch_CopyStr:
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp
	ld xhl, xiz
	jr LswAfterTouch_PopIzRet

LswAfterTouch_GetPartId:
	add xde, xde
	ld xwa, 0xe953ce
	add xwa, xde
	ld hl, (xwa)
	exts xhl
	jr LswAfterTouch_PopIzRet

LswAfterTouch_GetSubParam:
	ld xhl, 0x606
	jr LswAfterTouch_PopIzRet

LswAfterTouch_StepSize:
	lds32 xhl, 3
	jr LswAfterTouch_PopIzRet

LswAfterTouch_CheckEnabled:
	ld xwa, (xwa)
	bit 2, wa
	jr z, LswAfterTouchZeroReturn
	lds32 xhl, 4
	jr LswAfterTouch_PopIzRet

LswAfterTouch_GetToggle:
	ld xwa, (xwa)
	and xwa, 0x4
	or xwa, xwa
	scc16 nz, hl
	extz xhl
	jr LswAfterTouch_PopIzRet

LswAfterTouch_GetSignedToggle:
	ld xwa, (xwa)
	and xwa, 0x4
	or xwa, xwa
	scc16 nz, hl
	exts xhl
	jr LswAfterTouch_PopIzRet

LswAfterTouchZeroReturn:
	lds32 xhl, 0

LswAfterTouch_PopIzRet:
	pop xiz
	ret

LswPartExp:
	push xiz
	ld xiz, xwa
	lda_24 xhl, 0xe952aa
	cp xbc, 0x1e00083
	jrl z, LswPartExpZeroReturn
	ld xix, xde
	sll xix, 2
	ld xwa, xhl
	add xwa, xix
	cp xbc, 0x1e10002
	jrl z, LswPartExp_SignedToggle
	cp xbc, 0x1e0003f
	jrl z, LswPartExp_ToggleState
	cp xbc, 0x1e0003e
	jr z, LswPartExp_EnabledCheck
	cp xbc, 0x1e00041
	jr z, LswPartExp_StepSize
	cp xbc, 0x1e10001
	jr z, LswPartExp_SubParam
	cp xbc, 0x1e10000
	jr z, LswPartExp_PartIdLookup
	cp xbc, 0x1e00042
	jrl nz, LswPartExpZeroReturn
	ld xwa, (xde)
	srl xwa, 0
	ldi_werp 0xe2, 0
	extz xwa
	sll xwa, 2
	add xhl, xwa
	ld xbc, (xde + 8)
	ld xwa, (xhl)
	bit_erpw 0xe2, 0x00
	jr z, LswPartExp_StrOff
	cpw (xde + 4), 0x0
	jr z, LswPartExp_StrDisabled
	ld xwa, 0xe95644
	jr LswPartExp_StrCopyReturn

LswPartExp_StrDisabled:
	ld xwa, 0xe95648
	jr LswPartExp_StrCopyReturn

LswPartExp_StrOff:
	ld xwa, 0xe9564c

LswPartExp_StrCopyReturn:
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp
	ld xhl, xiz
	jr LswPartExp_PopIzRet

LswPartExp_PartIdLookup:
	add xde, xde
	ld xwa, 0xe953ce
	add xwa, xde
	ld hl, (xwa)
	exts xhl
	jr LswPartExp_PopIzRet

LswPartExp_SubParam:
	ld xhl, 0x604
	jr LswPartExp_PopIzRet

LswPartExp_StepSize:
	lds32 xhl, 3
	jr LswPartExp_PopIzRet

LswPartExp_EnabledCheck:
	ld xwa, (xwa)
	bit_erpw 0xe2, 0x00
	jr z, LswPartExpZeroReturn
	lds32 xhl, 4
	jr LswPartExp_PopIzRet

LswPartExp_ToggleState:
	ld xwa, (xwa)
	and xwa, 0x10000
	or xwa, xwa
	scc16 nz, hl
	extz xhl
	jr LswPartExp_PopIzRet

LswPartExp_SignedToggle:
	ld xwa, (xwa)
	and xwa, 0x10000
	or xwa, xwa
	scc16 nz, hl
	exts xhl
	jr LswPartExp_PopIzRet

LswPartExpZeroReturn:
	lds32 xhl, 0

LswPartExp_PopIzRet:
	pop xiz
	ret

LswLocalControl:
	push xiz
	ld xiz, xwa
	lda_24 xhl, 0xe952aa
	cp xbc, 0x1e00083
	jrl z, LswLocalControlZeroReturn
	ld xix, xde
	sll xix, 2
	ld xwa, xhl
	add xwa, xix
	cp xbc, 0x1e10002
	jrl z, LswLocal_SignedToggle
	cp xbc, 0x1e0003f
	jrl z, LswLocal_ToggleState
	cp xbc, 0x1e0003e
	jr z, LswLocal_EnabledCheck
	cp xbc, 0x1e00041
	jr z, LswLocal_StepSize
	cp xbc, 0x1e10001
	jr z, LswLocal_SubParam
	cp xbc, 0x1e10000
	jr z, LswLocal_PartIdLookup
	cp xbc, 0x1e00042
	jr nz, LswLocalControlZeroReturn
	ld xwa, (xde)
	srl xwa, 0
	ldi_werp 0xe2, 0
	extz xwa
	sll xwa, 2
	add xhl, xwa
	ld xbc, (xde + 8)
	ld xwa, (xhl)
	bit 0, wa
	jr z, LswLocal_StrOff
	cpw (xde + 4), 0x0
	jr z, LswLocal_StrDisabled
	ld xwa, 0xe95650
	jr LswLocal_StrCopyReturn

LswLocal_StrDisabled:
	ld xwa, 0xe95654
	jr LswLocal_StrCopyReturn

LswLocal_StrOff:
	ld xwa, 0xe95658

LswLocal_StrCopyReturn:
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp
	ld xhl, xiz
	jr LswLocalControl_PopIzRet

LswLocal_PartIdLookup:
	add xde, xde
	ld xwa, 0xe953ce
	add xwa, xde
	ld hl, (xwa)
	exts xhl
	jr LswLocalControl_PopIzRet

LswLocal_SubParam:
	ld xhl, 0x400
	jr LswLocalControl_PopIzRet

LswLocal_StepSize:
	lds32 xhl, 3
	jr LswLocalControl_PopIzRet

LswLocal_EnabledCheck:
	ld xwa, (xwa)
	bit 0, wa
	jr nz, LswLocal_ReturnMinusOne

LswLocalControlZeroReturn:
	lds32 xhl, 0
	jr LswLocalControl_PopIzRet

LswLocal_ToggleState:
	ld xwa, (xwa)
	bit 0, wa
	jr z, LswLocalControlZeroReturn

LswLocal_ReturnMinusOne:
	ld xhl, 0xffffffff
	jr LswLocalControl_PopIzRet

LswLocal_SignedToggle:
	ld xwa, (xwa)
	and xwa, 0x1
	or xwa, xwa
	scc16 nz, hl
	exts xhl

LswLocalControl_PopIzRet:
	pop xiz
	ret

LswMidiChannel:
	dec 4, xsp
	push xiz
	ld xiz, xde
	ld (xsp + 4), xwa
	lda_24 xde, 0xe953ce
	lda_24 xhl, 0xe952aa
	cp xbc, 0x1e00083
	jrl z, LswLocalZeroReturn
	ld xix, xiz
	sll xix, 2
	ld xwa, xhl
	add xwa, xix
	cp xbc, 0x1e10002
	jrl z, LswMidi_SignedToggle
	cp xbc, 0x1e0003f
	jrl z, LswMidi_ToggleState
	cp xbc, 0x1e0003e
	jrl z, LswMidi_EnabledCheck
	cp xbc, 0x1e00041
	jrl z, LswMidi_StepSize
	cp xbc, 0x1e10001
	jrl z, LswMidi_SubParam
	cp xbc, 0x1e10000
	jr z, LswMidi_PartIdLookup
	cp xbc, 0x1e00042
	jrl nz, LswLocalZeroReturn
	ld xwa, (xiz)
	srl xwa, 0
	ldi_werp 0xe2, 0
	extz xwa
	sll xwa, 2
	add xhl, xwa
	ld xwa, (xhl)
	bit 1, wa
	jr z, LswMidi_StrOff
	ld xwa, (xiz)
	srl xwa, 0
	ldi_werp 0xe2, 0
	extz xwa
	add xwa, xwa
	add xde, xwa
	ld wa, (xde)
	ldw bc, 0x402
	call SndParam_LookupViaEncode
	ld xbc, (xiz + 8)
	cps hl, 0
	jr z, LswMidi_StrChannelAlt
	ld wa, (xiz + 4)
	inc 1, wa
	pushw wa
	pushw 0xe9
	pushw 0x565c
	push xbc
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	jr LswMidi_LoadReturnValue

LswMidi_StrChannelAlt:
	pushw 0xe9
	pushw 0x5662
	push xbc
	jr LswMidi_StrCopyReturn

LswMidi_StrOff:
	pushw 0xe9
	pushw 0x5668
	ld xwa, (xiz + 8)
	push xwa

LswMidi_StrCopyReturn:
	call Strcpy
	inc 8, xsp

LswMidi_LoadReturnValue:
	ld xhl, (xsp + 4)
	jr LswLocal_PopIzSkip4Ret

LswMidi_PartIdLookup:
	ld xwa, xiz
	add xwa, xwa
	add xde, xwa
	ld hl, (xde)
	exts xhl
	jr LswLocal_PopIzSkip4Ret

LswMidi_SubParam:
	ld xhl, 0x401
	jr LswLocal_PopIzSkip4Ret

LswMidi_StepSize:
	lds32 xhl, 3
	jr LswLocal_PopIzSkip4Ret

LswMidi_EnabledCheck:
	ld xwa, (xwa)
	bit 1, wa
	jr z, LswLocalZeroReturn
	lds32 xhl, 4
	jr LswLocal_PopIzSkip4Ret

LswMidi_ToggleState:
	ld xwa, (xwa)
	and xwa, 0x2
	or xwa, xwa
	scc16 nz, hl
	extz xhl
	jr LswLocal_PopIzSkip4Ret

LswMidi_SignedToggle:
	ld xwa, (xwa)
	and xwa, 0x2
	or xwa, xwa
	scc16 nz, hl
	exts xhl
	jr LswLocal_PopIzSkip4Ret

LswLocalZeroReturn:
	lds32 xhl, 0

LswLocal_PopIzSkip4Ret:
	pop xiz
	inc 4, xsp
	ret

IvMesageProc:
	push xiz
	ld xiz, xwa
	cp xbc, 0x1e0003a
	jrl z, IvMessage_GetText
	ldda8 a, 32578
	extz wa
	cp xbc, 0x1e000b6
	jrl z, IvMessage_SelectionChange
	cp xbc, 0x1c0000d
	jrl z, IvMessage_Paint
	cp xbc, 0x1c0000c
	jr z, IvMessage_ShowHide
	cp xbc, 0x1c0000b
	jr z, IvMessage_ShowHide
	cp xbc, 0x1c00002
	jr z, IvMessage_Close
	cp xbc, 0x1c00001
	jrl nz, IvMessage_ForwardToBase
	st16_24 0x02478c, xwa
	ld xwa, xiz
	call InheritedProc
	ld16_24 xwa, 0x02478c
	muls wa, 0xe
	lda_24 xbc, 0xe9d340
	ld_sriw3 WA, 0x07, 0xe4, 0xe0
	sla wa, 2
	lda_24 xbc, 0xe9d7ae
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld xbc, 0x1c00001
	lds32 xde, 0
	call SendEvent
	ld16_24 xwa, 0x02478c
	muls wa, 0xe
	lda_24 xbc, 0xe9d340
	cp_sriw_im 0x07, 0xe4, 0xe0, 0x05, 0x00
	jrl nz, IvMessageStrcpyReturn
	ld xwa, 0xffffffff
	ld xbc, 0x1e000b3
	lds32 xde, 1
	jr IvMessage_SendEvent

IvMessage_Close:
	ld xwa, xiz
	jr IvMessage_CallInherited

IvMessage_ShowHide:
	ld xwa, xiz

IvMessage_CallInherited:
	call InheritedProc
	jr IvMessageStrcpyReturn

IvMessage_Paint:
	ld xwa, xiz
	call InheritedProc
	ld16_24 xwa, 0x02478c
	muls wa, 0xe
	lda_24 xbc, 0xe9d340
	cp_sriw_im 0x07, 0xe4, 0xe0, 0x05, 0x00
	call_24 nz, 0xfabb73
	ld xwa, xiz
	ld xbc, 0x1c0000f
	lds32 xde, 0

IvMessage_SendEvent:
	call SendEvent
	jr IvMessageStrcpyReturn

IvMessage_SelectionChange:
	st16_24 0x02478c, xwa
	muls wa, 0xe
	lda_24 xbc, 0xe9d340
	ld_sriw3 WA, 0x07, 0xe4, 0xe0
	sla wa, 2
	lda_24 xbc, 0xe9d7ae
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld xbc, 0x1e000b5
	ld xde, 0x1e000b6
	call SendEvent
	jr IvMessage_Epilogue

IvMessage_GetText:
	pushw 0xe9
	pushw 0xd7c6
	push xde
	call Strcpy
	inc 8, xsp

IvMessageStrcpyReturn:
	lds32 xhl, 0
	jr IvMessage_Epilogue

IvMessage_ForwardToBase:
	ld xwa, xiz
	call InheritedProc

IvMessage_Epilogue:
	pop xiz
	ret

AcPleaseWaitProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld xiz, xbc
	ld (xsp + 12), xwa
	cp xiz, 0x1e0003a
	jrl z, PleaseWait_GetText
	cp xiz, 0x1c0000f
	jr z, PleaseWait_Confirm
	cp xiz, 0x1c0000d
	jr z, PleaseWait_Paint
	cp xiz, 0x1c00002
	jr z, PleaseWait_Close
	cp xiz, 0x1c00001
	jr z, PleaseWait_Init
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	jrl PleaseWait_Epilogue

PleaseWait_Init:
	sti16_24 0x02477a, 0x0000
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	jr PleaseWait_InheritedReturn

PleaseWait_Close:
	ld xwa, 0x1c0000f
	push xwa
	lds32 xwa, 0
	push xwa
	ld xwa, 0x14
	ld xbc, (xsp + 20)
	ld xde, (xsp + 20)
	call KillApTimer
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)

PleaseWait_InheritedReturn:
	call InheritedProc
	jrl LanguageStringcpyReturn

PleaseWait_Paint:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 12)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	jrl LanguageStringcpyReturn

PleaseWait_Confirm:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, 0x1c0000f
	push xwa
	lds32 xwa, 0
	push xwa
	ld xwa, 0x14
	ld xbc, (xsp + 20)
	ld xde, (xsp + 20)
	call SetApTimer
	incdi16_24 1, 149370
	jrl LanguageStringcpyReturn

PleaseWait_GetText:
	ld xwa, (xsp + 8)
	ld (xsp + 4), xwa
	ld8_24 a, 0x0340e4
	extz wa
	sla wa, 2
	lda_24 xbc, 0xe9d7ca
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	call Strlen
	inc 4, xsp
	ld de, hl
	lds hl, 0
	cps de, 0
	jr le, PleaseWait_BuildScrollStr

PleaseWait_DotFillLoop:
	ld xwa, (xsp + 8)
	stib_dri 0x07, 0xe0, 0xec, 0x2e
	inc 1, hl
	cp hl, de
	jr lt, PleaseWait_DotFillLoop

PleaseWait_BuildScrollStr:
	ld xiy, (xsp + 8)
	stib_dri 0x07, 0xf4, 0xec, 0x00
	ld ix, de
	add ix, ix
	ld16_24 xwa, 0x02477a
	exts xwa
	divs xwa, xix
	ldto_werp HL, 0xe2
	ld8_24 a, 0x0340e4
	extz wa
	lda_24 xbc, 0xe9d7ca
	sla wa, 2
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	cp hl, de
	jr ge, PleaseWait_OverflowPath
	sub de, hl
	pushw de
	st_dri3b W, 0x07, 0xe0, 0xec
	push xwa
	push xiy
	jr PleaseWait_Strncpy

PleaseWait_OverflowPath:
	ld bc, hl
	sub bc, de
	pushw bc
	push xwa
	ld xwa, (xsp + 10)
	st_dri3b A, 0x07, 0xe0, 0xf0
	exts xhl
	sub xbc, xhl
	push xbc

PleaseWait_Strncpy:
	call Strncpy
	lda xsp, (xsp + 10)

LanguageStringcpyReturn:
	lds32 xhl, 0

PleaseWait_Epilogue:
	pop xiz
	lda xsp, (xsp + 12)
	ret

CheckLanguage:
	cp xbc, 0x1e00046
	jrl z, CheckLang_ReturnOne
	cp xbc, 0x1e00045
	jrl z, CheckLang_ReturnAddress
	cp xbc, 0x1e00047
	jr z, CheckLang_GetTextStr
	cp xbc, 0x1c00007
	jr nz, CheckLang_ReturnZero
	ld8_24 a, 0x0340e4
	bit 7, de
	jr z, CheckLang_Increment
	ld c, a
	cps a, 0
	jr z, CheckLang_SkipLang4
	dec 1, c
	st8_24 0x0340e4, c

CheckLang_SkipLang4:
	ld8_24 a, 0x0340e4
	cps a, 4
	jr nz, LanguageSelectEventReturn
	dec 1, a
	st8_24 0x0340e4, a
	jr LanguageSelectEventReturn

CheckLang_Increment:
	ld c, a
	cps a, 5
	jr nc, CheckLang_SkipLang4Up
	inc 1, c
	st8_24 0x0340e4, c

CheckLang_SkipLang4Up:
	ld8_24 a, 0x0340e4
	cps a, 4
	jr nz, LanguageSelectEventReturn
	inc 1, a
	st8_24 0x0340e4, a

LanguageSelectEventReturn:
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	call SendEvent
	jr CheckLang_ReturnZero

CheckLang_GetTextStr:
	ld8_24 a, 0x0340e4
	extz wa
	sla wa, 2
	lda_24 xbc, 0xe9d846
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	ld xwa, (xde + 18)
	push xwa
	call Strcpy
	inc 8, xsp

CheckLang_ReturnZero:
	lds32 xhl, 0
	ret

CheckLang_ReturnAddress:
	lda_24 xhl, 0x0340e4
	ret

CheckLang_ReturnOne:
	lds32 xhl, 1
	ret

CheckMessage:
	push xiz
	ld xiz, xde
	cp xbc, 0x1e00046
	jrl z, CheckMsg_ReturnTwo
	cp xbc, 0x1e00045
	jrl z, CheckMsg_ReturnAddress
	cp xbc, 0x1e00047
	jrl z, CheckMsg_AudioCommand
	cp xbc, 0x1c00007
	jrl nz, CheckMsg_ReturnZero
	ld16_24 xwa, 0x02478c
	muls wa, 0xe
	lda_24 xbc, 0xe9d340
	ld_sriw3 WA, 0x07, 0xe4, 0xe0
	sla wa, 2
	lda_24 xbc, 0xe9d7ae
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld xbc, 0x1c00002
	lds32 xde, 0
	call SendEvent
	ld16_24 xwa, 0x02478c
	bit 7, iz
	jr z, CheckMsg_IncrementCheck
	ld bc, wa
	cps wa, 0
	jr le, LanguageCheckReturn
	dec 1, bc
	st16_24 0x02478c, xbc
	jr LanguageCheckReturn

CheckMsg_IncrementCheck:
	ld bc, wa
	muls wa, 0xe
	add wa, 0xe
	lda_24 xde, 0xe9d34a
	ld_sril3 XWA, 0x07, 0xe8, 0xe0
	or xwa, xwa
	jr z, LanguageCheckReturn
	inc 1, bc
	st16_24 0x02478c, xbc

LanguageCheckReturn:
	ld16_24 xwa, 0x02478c
	muls wa, 0xe
	lda_24 xbc, 0xe9d340
	ld_sriw3 WA, 0x07, 0xe4, 0xe0
	sla wa, 2
	lda_24 xbc, 0xe9d7ae
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld xbc, 0x1c00001
	lds32 xde, 0
	call SendEvent
	jr CheckMsg_ReturnZero

CheckMsg_AudioCommand:
	push_sd24w 0x8c, 0x47, 0x02
	pushw 0xe9
	pushw 0xd892
	ld xwa, (xiz + 18)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)

CheckMsg_ReturnZero:
	lds32 xhl, 0
	jr CheckMsg_Epilogue

CheckMsg_ReturnAddress:
	lda_24 xhl, 0x02478c
	jr CheckMsg_Epilogue

CheckMsg_ReturnTwo:
	lds32 xhl, 2

CheckMsg_Epilogue:
	pop xiz
	ret

MessageText:
	cp xbc, 0x1e0009f
	jr z, MsgText_LookupMessage
	lds32 xhl, 0
	ret

MsgText_LookupMessage:
	ld16_24 xwa, 0x02478c
	cp wa, 0x1a
	jr z, MsgText_CheckLanguage
	muls wa, 0xe
	lda_24 xbc, 0xe9d34a
	ld_sril3 XHL, 0x07, 0xe4, 0xe0
	ret

MsgText_CheckLanguage:
	ldda8 a, 3298
	cps a, 3
	jr z, MsgText_Lang3
	cps a, 2
	jr z, MsgText_Lang2
	cps a, 1
	jr z, MsgText_Lang1
	lda_24 xhl, 0xe97fec
	ret

MsgText_Lang1:
	ld xhl, 0xe981b8
	jr MsgText_Return

MsgText_Lang2:
	ld xhl, 0xe98382
	jr MsgText_Return

MsgText_Lang3:
	ld xhl, 0xe9855c

MsgText_Return:
	ret

MessageHeader:
	dec 6, xsp
	push xiz
	cp xbc, 0x1e0009f
	jr z, MsgHeader_BuildHeader
	lds32 xhl, 0
	jrl MsgHeader_Epilogue

MsgHeader_BuildHeader:
	ld16_24 xbc, 0x02478c
	muls bc, 0xe
	lda_24 xwa, 0xe9d340
	st_dri3b W, 0x07, 0xe0, 0xe4
	cpw (xwa), 0x3
	jrl nz, MsgHeader_SingleEntry
	pushw 0x18
	call Malloc
	inc 2, xsp
	ld (xsp + 4), xhl
	ld xwa, 0xffffffff
	ld xbc, 0x1e00023
	ld xde, (xsp + 4)
	call PostEvent
	ldw (xsp + 8), 0x0

MsgHeader_BuildLoop:
	ld16_24 xbc, 0x02478c
	muls bc, 0xe
	lda_24 xwa, 0xe9d346
	ld de, (xsp + 8)
	extz xde
	sll xde, 2
	add_sril_rm XDE, 0x07, 0xe0, 0xe4
	ld xwa, (xde)
	push xwa
	call Strlen
	inc 6, hl
	pushw hl
	call Malloc
	ld xiz, xhl
	ld16_24 xbc, 0x02478c
	muls bc, 0xe
	lda_24 xwa, 0xe9d340
	st_dri3b W, 0x07, 0xe0, 0xe4
	pushm (xwa + 4)
	ld bc, (xsp + 16)
	extz xbc
	sll xbc, 2
	add xbc, (xwa + 6)
	ld xwa, (xbc)
	push xwa
	pushw 0xe9
	pushw 0xd8a2
	push xiz
	call Audio_SendCommand
	lda xsp, (xsp + 20)
	ld xwa, 0xffffffff
	ld xbc, 0x1e00023
	ld xde, xiz
	call PostEvent
	ld wa, (xsp + 8)
	extz xwa
	sll xwa, 2
	add xwa, (xsp + 4)
	ld (xwa), xiz
	incm 1, (xsp + 8)
	cpw (xsp + 8), 0x5
	jrl ule, MsgHeader_BuildLoop
	ld xhl, (xsp + 4)
	jr MsgHeader_Epilogue

MsgHeader_SingleEntry:
	ld xhl, (xwa + 6)

MsgHeader_Epilogue:
	pop xiz
	inc 6, xsp
	ret

IvAccordionProc:
	dec 4, xsp
	push xiz
	ld xiz, xde
	ld (xsp + 4), xwa
	cp xbc, 0x1e0003a
	jrl z, IvAccordion_GetText
	cp xbc, 0x1c0002f
	jrl z, IvAccordion_Refresh
	cp xbc, 0x1c0001c
	jrl z, IvAccordion_Match
	cp xbc, 0x1c00023
	jrl z, IvAccordion_Update
	cp xbc, 0x1c00029
	jrl z, IvAccordion_PageSelect
	cp xbc, 0x1c10000
	jrl z, IvAccordion_PageSelect
	cp xbc, 0x1c00018
	jrl z, IvAccordion_Scroll
	cp xbc, 0x1c00017
	jrl z, IvAccordion_Scroll
	cp xbc, 0x1c0000d
	jrl z, IvAccordion_Paint
	cp xbc, 0x1c0000c
	jr z, IvAccordion_ShowHide
	cp xbc, 0x1c0000b
	jr z, IvAccordion_ShowHide
	cp xbc, 0x1c00002
	jr z, IvAccordion_Close
	cp xbc, 0x1c00001
	jrl nz, IvAccordion_ForwardToBase
	ld xwa, (xsp + 4)
	ld xde, xiz
	call InheritedProc
	call GetModeNow
	cp xhl, 0x1800001
	jrl nz, IvAccordion_ReturnHandled
	ld xwa, 0xffffffff
	ld xbc, 0x1e000b3
	lds32 xde, 1
	jrl IvAccordion_DispatchEvent

IvAccordion_Close:
	ld xwa, (xsp + 4)
	ld xde, xiz
	call InheritedProc
	jrl IvAccordion_ReturnHandled

IvAccordion_ShowHide:
	ld xwa, (xsp + 4)
	ld xde, xiz
	call InheritedProc
	sti16_24 0x02477c, 0xffff
	sti16_24 0x024780, 0xffff
	call GetPartSelect
	st16_24 0x02477e, xhl
	ld wa, hl
	calr SndParam_ResolveOscEntry
	ld xde, xhl
	ld xwa, (xsp + 4)
	ld xbc, 0x1c00023
	call SendEvent
	call GetModeNow
	cp xhl, 0x1800013
	jr nz, IvAccordion_ShowHide_UpdatePart
	cpdi16_24 149378, 0
	jr z, IvAccordion_ShowHide_NoBellows
	ld xwa, 0xeb0009
	ld xbc, 0x1c00002
	lds32 xde, 5
	call SendEvent
	sti16_24 0x02477c, 0x0001
	sti16_24 0x024780, 0x0001
	ld xwa, 0xeb0017
	ld xbc, 0x1c00001
	lds32 xde, 5
	jr IvAccordion_ShowHide_Toggle

IvAccordion_ShowHide_NoBellows:
	ld xwa, 0xeb0017
	ld xbc, 0x1c00002
	lds32 xde, 5
	call SendEvent
	sti16_24 0x02477c, 0x0000
	sti16_24 0x024780, 0x0000
	ld xwa, 0xeb0009
	ld xbc, 0x1c00001
	lds32 xde, 5

IvAccordion_ShowHide_Toggle:
	call SendEvent
	ld16_24 xwa, 0x024782
	cpl wa
	st16_24 0x024782, xwa

IvAccordion_ShowHide_UpdatePart:
	ld16_24 xwa, 0x02477e
	sla wa, 2
	lda_24 xbc, 0x03e9a0
	ld_sril3 XDE, 0x07, 0xe4, 0xe0
	ld xwa, 0xeb0007
	ld xbc, 0x1c0000f
	jrl IvAccordion_DispatchEvent

IvAccordion_Paint:
	ld xwa, (xsp + 4)
	ld xde, xiz
	call InheritedProc
	ld xwa, (xsp + 4)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jrl IvAccordion_DispatchEvent

IvAccordion_Scroll:
	ld xwa, (xsp + 4)
	ld xde, xiz
	call InheritedProc
	cp xiz, 0x1
	jrl z, IvAccordion_ReturnHandled
	or xiz, xiz
	jrl nz, IvAccordion_ReturnHandled
	cpdi16_24 149376, 0
	jr nz, IvAccordion_Scroll_SetOff
	sti16_24 0x024780, 0x0001
	ld xwa, 0xeb0009
	ld xbc, 0x1c00002
	lds32 xde, 5
	call SendEvent
	ld xwa, 0xeb0017
	ld xbc, 0x1c00001
	lds32 xde, 5
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001b
	lds32 xde, 1
	call PostEvent
	cpdi16_24 149372, 1
	jrl nz, IvAccordion_ReturnHandled
	ld16_24 xwa, 0x02477e
	calr SndParam_ResolveOscEntry
	ld xde, xhl
	ld xwa, (xsp + 4)
	ld xbc, 0x1c00023
	jrl IvAccordion_DispatchEvent

IvAccordion_Scroll_SetOff:
	sti16_24 0x024780, 0x0000
	ld xwa, 0xeb0017
	ld xbc, 0x1c00002
	lds32 xde, 5
	call SendEvent
	ld xwa, 0xeb0009
	ld xbc, 0x1c00001
	lds32 xde, 5
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001b
	lds32 xde, 1
	call PostEvent
	cpdi16_24 149372, 0
	jrl nz, IvAccordion_ReturnHandled
	ld16_24 xwa, 0x02477e
	calr SndParam_ResolveOscEntry
	ld xde, xhl
	ld xwa, (xsp + 4)
	ld xbc, 0x1c00023
	jrl IvAccordion_DispatchEvent

IvAccordion_PageSelect:
	ld xwa, (xsp + 4)
	ld xde, xiz
	call InheritedProc
	ld xwa, xiz
	srl xwa, 0
	ldi_werp 0xe2, 0
	cps wa, 1
	jrl nz, IvAccordion_ReturnHandled
	ld16_24 xbc, 0x02477e
	extz xbc
	ld wa, iz
	extz wa
	add wa, 0xd00
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld xwa, 0x1400004
	ld xbc, 0x1e000a8
	call MainFuncCall
	jrl IvAccordion_ReturnHandled

IvAccordion_Update:
	ld xwa, (xsp + 4)
	ld xde, xiz
	call InheritedProc
	ld wa, iz
	ld16_24 xbc, 0x02477e
	cp bc, wa
	jrl nz, IvAccordion_ReturnHandled
	ld xwa, xiz
	srl xwa, 0
	ldi_werp 0xe2, 0
	ld bc, wa
	srl bc, 8
	ldb b, 0x0
	cp c, 0xd
	jrl nz, IvAccordion_Update_NonNote
	cp a, 0xa
	jr nc, IvAccordion_Update_BellowsOn
	cpdi16_24 149372, 0
	jr z, IvAccordion_Update_SendPartParam
	ld xwa, 0xeb0017
	ld xbc, 0x1c00002
	lds32 xde, 5
	call SendEvent
	sti16_24 0x02477c, 0x0000
	sti16_24 0x024780, 0x0000
	ld xwa, 0xeb0009
	ld xbc, 0x1c00001
	lds32 xde, 5
	jr IvAccordion_Update_CommitToggle

IvAccordion_Update_BellowsOn:
	cpdi16_24 149372, 1
	jr z, IvAccordion_Update_SendPartParam
	ld xwa, 0xeb0009
	ld xbc, 0x1c00002
	lds32 xde, 5
	call SendEvent
	sti16_24 0x02477c, 0x0001
	sti16_24 0x024780, 0x0001
	ld xwa, 0xeb0017
	ld xbc, 0x1c00001
	lds32 xde, 5

IvAccordion_Update_CommitToggle:
	call SendEvent

IvAccordion_Update_SendPartParam:
	ld xwa, xiz
	srl xwa, 0
	ldi_werp 0xe2, 0
	extz wa
	ld de, wa
	extz xde
	add xde, 0x10000
	ld xwa, 0xffffffff
	ld xbc, 0x1c0002a
	jr IvAccordion_Update_Dispatch

IvAccordion_Update_NonNote:
	ld xwa, 0xffffffff
	ld xbc, 0x1e00079
	lds32 xde, 0

IvAccordion_Update_Dispatch:
	call PostEvent
	jrl IvAccordion_ReturnHandled

IvAccordion_Match:
	ld xwa, (xsp + 4)
	ld xde, xiz
	call InheritedProc
	ld16_24 xwa, 0x02477e
	ld bc, wa
	exts xbc
	sll xbc, 10
	ld xde, xbc
	add xde, 0x8000
	cp xde, (xiz)
	jr z, IvAccordion_Match_Found
	add xbc, 0x8020
	cp xbc, (xiz)
	jr nz, IvAccordion_ReturnHandled

IvAccordion_Match_Found:
	calr SndParam_ResolveOscEntry
	ld xde, xhl
	ld xwa, (xsp + 4)
	ld xbc, 0x1c00023
	jr IvAccordion_DispatchEvent

IvAccordion_Refresh:
	ld xwa, (xsp + 4)
	ld xde, xiz
	call InheritedProc
	call GetPartSelect
	st16_24 0x02477e, xhl
	sla hl, 2
	lda_24 xwa, 0x03e9a0
	ld_sril3 XDE, 0x07, 0xe0, 0xec
	ld xwa, 0xeb0007
	ld xbc, 0x1c0000f
	call SendEvent
	ld16_24 xwa, 0x02477e
	calr SndParam_ResolveOscEntry
	ld xde, xhl
	ld xwa, (xsp + 4)
	ld xbc, 0x1c00023

IvAccordion_DispatchEvent:
	call SendEvent
	jr IvAccordion_ReturnHandled

IvAccordion_GetText:
	pushw 0xe9
	pushw 0xd9ba
	push xiz
	call Strcpy
	inc 8, xsp

IvAccordion_ReturnHandled:
	lds32 xhl, 0
	jr IvAccordion_Return

IvAccordion_ForwardToBase:
	ld xwa, (xsp + 4)
	ld xde, xiz
	call InheritedProc

IvAccordion_Return:
	pop xiz
	inc 4, xsp
	ret

IvAccordionXProc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xwa
	cp xbc, 0x1e0003a
	jr z, AccordionX_GetText
	cp xbc, 0x1c0000d
	jr z, AccordionX_Paint
	cp xbc, 0x1c00029
	jr z, AccordionX_PageSelect
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	jr AccordionX_Epilogue

AccordionX_PageSelect:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldi_werp 0xe2, 0
	cps wa, 1
	jr nz, StringCopyReturn
	ld xwa, 0xffffffff
	ld xbc, 0x1c10000
	ld xde, (xsp + 4)
	call PostEvent
	jr StringCopyReturn

AccordionX_Paint:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	jr StringCopyReturn

AccordionX_GetText:
	pushw 0xe9
	pushw 0xd9c0
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp

StringCopyReturn:
	lds32 xhl, 0

AccordionX_Epilogue:
	pop xiz
	inc 4, xsp
	ret

AcAccordionTabProc:
	lda xsp, (xsp - 12)
	push xiz
	ld xiz, xwa
	cp xbc, 0x1c0000f
	jr z, AccTab_Confirm
	ld xwa, xiz
	call InheritedProc
	jrl AccTab_Epilogue

AccTab_Confirm:
	ld xwa, xiz
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld xiz, xhl
	lda xbc, (xiz + 14)
	lda xde, (xsp + 8)
	ldw wa, 0xc9
	call GetClientBox2
	lda xwa, (xsp + 8)
	lda xhl, (xwa + 6)
	ld de, (xwa + 2)
	ld bc, (xhl)
	sub bc, de
	exts xbc
	divs bc, 0x3
	add de, bc
	ld (xhl), de
	lda xbc, (xsp + 4)
	call GetBoxCenter
	ld xwa, (xiz + 34)
	lda xbc, (xsp + 4)
	lda xhl, (xiz + 22)
	ld xde, (xiz + 44)
	cpw (xwa), 0x0
	jr z, AccTab_DrawInactive
	lda xwa, (xsp + 8)
	ld xhl, (xhl)
	push xhl
	pushw 0xff
	pushw 0xf7
	jr AccTab_DrawCentered

AccTab_DrawInactive:
	lda xwa, (xsp + 8)
	ld xhl, (xhl)
	push xhl
	pushw 0x0
	pushw 0xf7

AccTab_DrawCentered:
	call DrawStringCentered
	lda xwa, (xsp + 8)
	ld bc, (xwa + 6)
	dec 1, bc
	ld (xwa + 2), bc
	lds bc, 0
	call DrawBox
	lda xbc, (xiz + 14)
	lda xde, (xsp + 8)
	ldw wa, 0xc9
	call GetClientBox2
	lda xwa, (xsp + 8)
	lda xhl, (xwa + 2)
	ld de, (xwa + 6)
	ld bc, (xhl)
	ld ix, de
	sub ix, bc
	ld bc, ix
	exts xbc
	divs bc, 0x3
	sub de, bc
	ld (xhl), de
	lda xbc, (xsp + 4)
	call GetBoxCenter
	ld xix, (xiz + 34)
	ld xde, (xiz + 48)
	lda xwa, (xsp + 8)
	lda xbc, (xsp + 4)
	lda xhl, (xiz + 22)
	cpw (xix), 0x0
	jr z, AccTab_DrawSecondInactive
	ld xhl, (xhl)
	push xhl
	pushw 0xff
	pushw 0xf7
	jr AccTab_DrawSecondCentered

AccTab_DrawSecondInactive:
	ld xhl, (xhl)
	push xhl
	pushw 0x0
	pushw 0xf7

AccTab_DrawSecondCentered:
	call DrawStringCentered
	lda xwa, (xsp + 8)
	ld bc, (xwa + 2)
	inc 1, bc
	ld (xwa + 6), bc
	lds bc, 0
	call DrawBox
	lds32 xhl, 0

AccTab_Epilogue:
	pop xiz
	lda xsp, (xsp + 12)
	ret

IvSdtecdProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1e0003a
	jrl z, Sdtecd_GetText
	cp xiz, 0x1c0000d
	jr z, Sdtecd_Paint
	cp xiz, 0x1c00001
	jr z, Sdtecd_Init
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	jrl Sdtecd_Epilogue

Sdtecd_Init:
	ld xwa, (xsp + 4)
	cp xwa, 0x4
	jr z, Voice_InheritedProcCall
	cp xwa, 0x3
	jr z, Sdtecd_InitCase3
	or xwa, xwa
	jr nz, Voice_InheritedProcCall
	ld xwa, 0xd0001
	ld xbc, 0x1e0007f
	lds32 xde, 1
	call SendEvent
	jr Voice_InheritedProcCall

Sdtecd_InitCase3:
	ld xwa, 0xd0001
	ld xbc, 0x1e0007f
	lds32 xde, 1
	call SendEvent
	ld xwa, 0x4200
	call SndParam_LookupReadOnly
	cps hl, 0
	jr nz, Voice_InheritedProcCall
	ld xwa, 0x4200
	lds bc, 1
	lds de, 3
	call MainLswPut

Voice_InheritedProcCall:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	jr Sdtecd_ReturnZero

Sdtecd_Paint:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 8)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	jr Sdtecd_ReturnZero

Sdtecd_GetText:
	pushw 0xe9
	pushw 0xd9c6
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp

Sdtecd_ReturnZero:
	lds32 xhl, 0

Sdtecd_Epilogue:
	pop xiz
	inc 8, xsp
	ret

IvSdtecd1Proc:
	dec 4, xsp
	push xiz
	ld xiz, xde
	ld (xsp + 4), xwa
	cp xbc, 0x1e0003a
	jrl z, Sdtecd1_GetText
	cp xbc, 0x1c0000d
	jrl z, Sdtecd1_Paint
	cp xbc, 0x1c0001c
	jrl z, Sdtecd1_Match
	cp xbc, 0x1c0001a
	jrl z, Sdtecd1_ScrollUp
	cp xbc, 0x1c00018
	jrl z, Sdtecd1_ScrollUp
	cp xbc, 0x1c00019
	jr z, Sdtecd1_ScrollDown
	cp xbc, 0x1c00017
	jr z, Sdtecd1_ScrollDown
	cp xbc, 0x1c0000b
	jrl nz, Sdtecd1_ForwardToBase
	ld xwa, (xsp + 4)
	ld xde, xiz
	call InheritedProc
	ld xwa, 0x4202
	call SndParam_LookupReadOnly
	sla hl, 2
	lda_24 xwa, 0xe9d9cc
	ld_sril3 XWA, 0x07, 0xe0, 0xec
	ld xbc, 0x1e00087
	lds32 xde, 1
	call SendEvent
	ld xwa, (xsp + 4)
	ld xbc, 0x1c00018
	lds32 xde, 1
	call SetDialUp
	ld xwa, (xsp + 4)
	ld xbc, 0x1c00017
	lds32 xde, 1
	call SetDialDown
	lds wa, 1
	call SetDialEnable
	jrl IvSdtecd1_ReturnDefault

Sdtecd1_ScrollDown:
	ld xwa, (xsp + 4)
	ld xde, xiz
	call InheritedProc
	or xiz, xiz
	jr z, Sdtecd1_ScrollDown_Lookup
	cp xiz, 0x1
	jrl nz, IvSdtecd1_ReturnDefault
	ld xwa, 0x4202
	ldw bc, 0xffff
	lds de, 3
	call MainLswAdd
	ld xwa, (xsp + 4)
	ld xbc, 0x1c00019
	ld xde, xiz
	call SetAutoInc
	ld xwa, (xsp + 4)
	ld xbc, 0x1c00018
	lds32 xde, 1
	call SetDialUp
	ld xwa, (xsp + 4)
	ld xbc, 0x1c00017
	lds32 xde, 1
	call SetDialDown
	lds wa, 1
	call SetDialEnable
	jrl IvSdtecd1_ReturnDefault

Sdtecd1_ScrollDown_Lookup:
	ld xwa, 0x4202
	call SndParam_LookupReadOnly
	ld bc, hl
	ld xwa, 0xe9da04
	calr SdpartLookupPartId
	ld wa, hl
	inc 7, wa
	cp wa, 0xd
	jrl gt, IvSdtecd1_ReturnDefault
	inc 7, hl
	add hl, hl
	lda_24 xwa, 0xe9da04
	ld_sriw3 BC, 0x07, 0xe0, 0xec
	ld xwa, 0x4202
	lds de, 3
	jrl Sdtecd1_PutAndReturn

Sdtecd1_ScrollUp:
	ld xwa, (xsp + 4)
	ld xde, xiz
	call InheritedProc
	or xiz, xiz
	jr z, Sdtecd1_ScrollUp_Lookup
	cp xiz, 0x1
	jrl nz, IvSdtecd1_ReturnDefault
	ld xwa, 0x4202
	lds bc, 1
	lds de, 3
	call MainLswAdd
	ld xwa, (xsp + 4)
	ld xbc, 0x1c0001a
	ld xde, xiz
	call SetAutoInc
	ld xwa, (xsp + 4)
	ld xbc, 0x1c00018
	lds32 xde, 1
	call SetDialUp
	ld xwa, (xsp + 4)
	ld xbc, 0x1c00017
	lds32 xde, 1
	call SetDialDown
	lds wa, 1
	call SetDialEnable
	jrl IvSdtecd1_ReturnDefault

Sdtecd1_ScrollUp_Lookup:
	ld xwa, 0x4202
	call SndParam_LookupReadOnly
	ld bc, hl
	ld xwa, 0xe9da04
	calr SdpartLookupPartId
	ld wa, hl
	sub wa, 0x7
	jr lt, IvSdtecd1_ReturnDefault
	dec 7, hl
	add hl, hl
	lda_24 xwa, 0xe9da04
	ld_sriw3 BC, 0x07, 0xe0, 0xec
	ld xwa, 0x4202
	lds de, 3

Sdtecd1_PutAndReturn:
	call MainLswPut
	jr IvSdtecd1_ReturnDefault

Sdtecd1_Match:
	ld xwa, (xsp + 4)
	ld xde, xiz
	call InheritedProc
	ld xwa, (xiz)
	cp xwa, 0x4202
	jr nz, IvSdtecd1_ReturnDefault
	ld wa, (xiz + 4)
	sla wa, 2
	lda_24 xbc, 0xe9d9cc
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld xbc, 0x1e00087
	lds32 xde, 1
	jr Sdtecd1_SendEventReturn

Sdtecd1_Paint:
	ld xwa, (xsp + 4)
	ld xde, xiz
	call InheritedProc
	ld xwa, (xsp + 4)
	ld xbc, 0x1c0000f
	lds32 xde, 0

Sdtecd1_SendEventReturn:
	call SendEvent
	jr IvSdtecd1_ReturnDefault

Sdtecd1_GetText:
	pushw 0xe9
	pushw 0xda22
	push xiz
	call Strcpy
	inc 8, xsp

IvSdtecd1_ReturnDefault:
	lds32 xhl, 0
	jr Sdtecd1_Epilogue

Sdtecd1_ForwardToBase:
	ld xwa, (xsp + 4)
	ld xde, xiz
	call InheritedProc

Sdtecd1_Epilogue:
	pop xiz
	inc 4, xsp
	ret

LswOrchestrator:
	push xiz
	ld xiz, xwa
	cp xbc, 0x1e00083
	jr z, LswOrch_ReturnZero
	cp xbc, 0x1e0003f
	jr z, LswOrch_ReturnOne
	cp xbc, 0x1e0003e
	jr z, LswOrch_ReturnOne
	cp xbc, 0x1e00041
	jr z, LswOrch_StepSize
	cp xbc, 0x1e00040
	jr z, LswOrch_SubParam
	cp xbc, 0x1e00042
	jr nz, LswOrch_ReturnZero
	ld bc, (xde + 4)
	ld xwa, (xde + 8)
	cp bc, 0xff
	jr z, LswOrch_StrDefault
	sla bc, 2
	lda_24 xde, 0xe9da28
	ld_sril3 XBC, 0x07, 0xe8, 0xe4
	push xbc
	jr LswOrch_StrCopyReturn

LswOrch_StrDefault:
	pushw 0xe9
	pushw 0xdb16

LswOrch_StrCopyReturn:
	push xwa
	call Strcpy
	inc 8, xsp
	ld xhl, xiz
	jr LswOrchestra_PopIzRet

LswOrch_SubParam:
	ld xhl, 0x4201
	jr LswOrchestra_PopIzRet

LswOrch_StepSize:
	lds32 xhl, 3
	jr LswOrchestra_PopIzRet

LswOrch_ReturnOne:
	lds32 xhl, 1
	jr LswOrchestra_PopIzRet

LswOrch_ReturnZero:
	lds32 xhl, 0

LswOrchestra_PopIzRet:
	pop xiz
	ret

PsLabelBoxProc:
	st_dri3b L, 0xfd, 0xec, 0xfe
	push xiz
	st_dri3l XDE, 0xfd, 0x10, 0x01
	st_dri3l XWA, 0xfd, 0x14, 0x01
	cp xbc, 0x1e0003a
	jrl z, PsLabel_GetText
	cp xbc, 0x1e00087
	jrl z, PsLabel_HandleWidget2
	cp xbc, 0x1e0004d
	jrl z, PsLabel_HandleWidget1
	cp xbc, 0x1c0001b
	jrl z, PsLabel_Notify
	cp xbc, 0x1c0000e
	jrl z, PsLabel_Select
	cp xbc, 0x1c0000f
	jr z, PsLabel_Confirm
	cp xbc, 0x1c0000d
	jrl nz, PsLabel_ForwardToBase
	ld_sril XWA, (xsp + 0x0114)
	ld_sril XDE, (xsp + 0x0110)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0114)
	ld xbc, 0x1c0000e
	lds32 xde, 0
	call SendEvent
	ld_sril XWA, (xsp + 0x0114)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jrl PsLabelBox_SendEvent_Continue

PsLabel_Confirm:
	st_dri3b A, 0xfd, 0x08, 0x01
	ld_sril XWA, (xsp + 0x0114)
	call GetClientBox
	st_dri3b W, 0xfd, 0x08, 0x01
	st_dri3b A, 0xfd, 0x04, 0x01
	call GetBoxCenter
	ld_sril XWA, (xsp + 0x0114)
	call GetViewInstance
	ld xiz, xhl
	lda xde, (xsp + 4)
	ld_sril XWA, (xsp + 0x0110)
	or xwa, xwa
	jr nz, PsLabel_CopyDataStr
	ld_sril XWA, (xsp + 0x0114)
	ld xbc, 0x1e0003a
	call SendEvent
	cp (xsp + 4), 0x0
	jr nz, PsLabel_DrawReverse
	jrl LswMaster_ReturnZeroJmp

PsLabel_CopyDataStr:
	ld_sril XWA, (xsp + 0x0110)
	push xwa
	push xde
	call Strcpy
	inc 8, xsp

PsLabel_DrawReverse:
	st_dri3b C, 0xfd, 0x08, 0x01
	st_dri3b A, 0xfd, 0x04, 0x01
	lda xde, (xsp + 4)
	ld xwa, (xiz + 32)
	push xwa
	pushm (xiz + 36)
	pushm (xiz + 22)
	ld a, (xiz + 38)
	extz wa
	pushw wa
	ld xwa, (xiz + 44)
	pushm (xwa)
	ld xwa, xhl
	call DrawStringReverse
	jrl LswMaster_ReturnZeroJmp

PsLabel_Select:
	ld_sril XWA, (xsp + 0x0114)
	call GetViewInstance
	ld xwa, (xhl + 40)
	ld de, (xwa)
	exts xde
	ld_sril XWA, (xsp + 0x0114)
	ld xbc, 0x1e0004e
	jrl PsLabelBox_SendEvent_Continue

PsLabel_Notify:
	ld_sril XWA, (xsp + 0x0114)
	ld_sril XDE, (xsp + 0x0110)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0114)
	call GetViewInstance
	ld xiz, xhl
	ld wa, (xiz + 26)
	exts xwa
	cp_sril_rm XWA, 0xfd, 0x10, 0x01
	jrl nz, LswMaster_ReturnZeroJmp
	ld xwa, (xiz + 40)
	cpw (xwa), 0x0
	jr z, PsLabel_CheckSecondWidget
	ld_sril XWA, (xsp + 0x0114)
	ld xbc, 0x1e0004d
	lds32 xde, 0
	call SendEvent

PsLabel_CheckSecondWidget:
	ld xwa, (xiz + 44)
	cpw (xwa), 0x0
	jrl z, LswMaster_ReturnZeroJmp
	ld_sril XWA, (xsp + 0x0114)
	ld xbc, 0x1e00087
	lds32 xde, 0
	jrl PsLabelBox_SendEvent_Continue

PsLabel_HandleWidget1:
	ld_sril XWA, (xsp + 0x0114)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 40)
	ld wa, (xwa)
	exts xwa
	cp_sril_rm XWA, 0xfd, 0x10, 0x01
	jrl z, LswMaster_ReturnZeroJmp
	ld_sril XWA, (xsp + 0x0110)
	cps wa, 1
	jr nz, PsLabel_StoreWidget1
	ld de, (xiz + 26)
	exts xde
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001b
	call SendEvent

PsLabel_StoreWidget1:
	ld xbc, (xiz + 40)
	ld_sril XWA, (xsp + 0x0110)
	ld (xbc), wa
	ld_sril XWA, (xsp + 0x0114)
	ld xbc, 0x1c0000e
	lds32 xde, 0
	jr PsLabelBox_SendEvent_Continue

PsLabel_HandleWidget2:
	ld_sril XWA, (xsp + 0x0114)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 44)
	ld wa, (xwa)
	exts xwa
	cp_sril_rm XWA, 0xfd, 0x10, 0x01
	jr z, LswMaster_ReturnZeroJmp
	ld_sril XWA, (xsp + 0x0110)
	cps wa, 1
	jr nz, PsLabel_StoreWidget2
	ld de, (xiz + 26)
	exts xde
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001b
	call SendEvent

PsLabel_StoreWidget2:
	ld xbc, (xiz + 44)
	ld_sril XWA, (xsp + 0x0110)
	ld (xbc), wa
	ld_sril XWA, (xsp + 0x0114)
	ld xbc, 0x1c0000f
	lds32 xde, 0

PsLabelBox_SendEvent_Continue:
	call SendEvent
	jr LswMaster_ReturnZeroJmp

PsLabel_GetText:
	ld_sril XWA, (xsp + 0x0114)
	call GetViewInstance
	ld xwa, (xhl + 28)
	push xwa
	ld_sril XWA, (xsp + 0x0114)
	push xwa
	call Strcpy
	inc 8, xsp

LswMaster_ReturnZeroJmp:
	lds32 xhl, 0
	jr PsLabel_Epilogue

PsLabel_ForwardToBase:
	ld_sril XWA, (xsp + 0x0114)
	ld_sril XDE, (xsp + 0x0110)
	call InheritedProc

PsLabel_Epilogue:
	pop xiz
	st_dri3b L, 0xfd, 0x14, 0x01
	ret

LswMasterTuning:
	lda xsp, (xsp - 14)
	pushw iz
	ld (xsp + 8), xde
	ld xde, xbc
	ld (xsp + 12), xwa
	ld xiy, 0xe9db70
	lda xix, (xsp + 2)
	lds bc, 3
	ldirw
	cp xde, 0x1e000b9
	jrl z, StringOp_ReturnZero
	cp xde, 0x1e000b8
	jrl z, StringOp_ReturnOne
	cp xde, 0x1e00083
	jrl z, StringOp_ReturnZero
	cp xde, 0x1e0003f
	jrl z, StringOp_ReturnOne
	cp xde, 0x1e0003e
	jrl z, StringOp_ReturnOne
	cp xde, 0x1e00041
	jrl z, LswTuning_StepSize
	cp xde, 0x1e00040
	jrl z, StringOp_ReturnZero
	cp xde, 0x1e00042
	jrl nz, StringOp_ReturnZero
	lds iz, 1
	lda_24 xde, 0xe9db20
	ld xwa, (xsp + 8)
	ld bc, (xwa + 4)

LswTuning_SearchLoop:
	ld wa, iz
	extz xwa
	ld xhl, xde
	add xhl, xwa
	ld a, (xhl)
	extz wa
	cp wa, bc
	jr nz, LswTuning_SearchNext
	ld wa, iz
	extz xwa
	div wa, 0x3
	add wa, 0x1b
	pushw wa
	pushw 0xe9
	pushw 0xdb76
	lda xwa, (xsp + 8)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	ld wa, iz
	extz xwa
	div wa, 0x3
	ldto_werp BC, 0xe2
	lda xwa, (xsp + 6)
	cps bc, 2
	jr z, LswTuning_Octave6
	cps bc, 1
	jr z, LswTuning_Octave3
	cps bc, 0
	jr nz, StringOp_CopyCall
	ld (xwa), 0x30
	jr StringOp_CopyCall

LswTuning_Octave3:
	ld (xwa), 0x33
	jr StringOp_CopyCall

LswTuning_Octave6:
	ld (xwa), 0x36
	jr StringOp_CopyCall

LswTuning_SearchNext:
	inc 1, iz
	cp iz, 0x4e
	jr ule, LswTuning_SearchLoop

StringOp_CopyCall:
	lda xwa, (xsp + 2)
	push xwa
	ld xwa, (xsp + 12)
	ld xwa, (xwa + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	ld xhl, (xsp + 12)
	jr StringOp_ReturnPoint

LswTuning_StepSize:
	lds32 xhl, 3
	jr StringOp_ReturnPoint

StringOp_ReturnOne:
	lds32 xhl, 1
	jr StringOp_ReturnPoint

StringOp_ReturnZero:
	lds32 xhl, 0

StringOp_ReturnPoint:
	popw iz
	lda xsp, (xsp + 14)
	ret

TtSdscltyp:
	cp xbc, 0x1c0000c
	jr z, TtSdscltyp_ReturnZero
	cp xbc, 0x1c0000b
	jr z, TtSdscltyp_ReturnZero
	cp xbc, 0x1c00002
	jr z, TtSdscltyp_ReturnZero
	cp xbc, 0x1c00001
	jr nz, TtSdscltyp_ReturnZero
	or xde, xde
	jr nz, TtSdscltyp_ReturnZero
	ld xwa, 0x50001
	ld xbc, 0x1e0007f
	lds32 xde, 1
	call SendEvent
	ld xwa, 0x50007
	ld xbc, 0x1e00051
	lds32 xde, 0
	call SendEvent
	ld xde, xhl
	ld xwa, 0x50005
	ld xbc, 0x1c0001b
	call SendEvent
	ld xwa, 0x50007
	ld xbc, 0x1e0004d
	lds32 xde, 1
	call SendEvent
	sti16_24 0x02478e, 0x0000

TtSdscltyp_ReturnZero:
	lds32 xhl, 0
	ret

IvSdscltyp2Proc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1e0003a
	jrl z, Sdscltyp2_GetText
	cp xiz, 0x1c0000d
	jrl z, Sdscltyp2_Paint
	cp xiz, 0x1c0001a
	jrl z, Sdscltyp2_ScrollUp
	cp xiz, 0x1c00018
	jrl z, Sdscltyp2_ScrollUp
	cp xiz, 0x1c00019
	jr z, Sdscltyp2_ScrollDown
	cp xiz, 0x1c00017
	jr z, Sdscltyp2_ScrollDown
	cp xiz, 0x1c00001
	jrl nz, Sdscltyp2_ForwardToBase
	ld xwa, 0x50011
	ld xbc, 0x1e00051
	lds32 xde, 0
	call SendEvent
	ld xde, xhl
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001b
	call SendEvent
	ld16_24 xwa, 0x02478e
	sla wa, 2
	lda_24 xbc, 0xe9db7c
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld xbc, 0x1e0004d
	lds32 xde, 1
	call SendEvent
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	jrl IvSdscltyp2_ReturnZeroJmp

Sdscltyp2_ScrollDown:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 4)
	or xwa, xwa
	jrl nz, IvSdscltyp2_ReturnZeroJmp
	ld16_24 xwa, 0x02478e
	cp wa, 0xb
	jr ge, Sdscltyp2_SetAutoIncDown
	inc 1, wa
	st16_24 0x02478e, xwa
	ld xwa, 0x50011
	ld xbc, 0x1e00051
	lds32 xde, 0
	call SendEvent
	ld xde, xhl
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001b
	call SendEvent
	ld16_24 xwa, 0x02478e
	sla wa, 2
	lda_24 xbc, 0xe9db7c
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld xbc, 0x1e0004d
	lds32 xde, 1
	call SendEvent

Sdscltyp2_SetAutoIncDown:
	ld xwa, (xsp + 8)
	ld xbc, 0x1c00019
	ld xde, (xsp + 4)
	jr Sdscltyp2_SetAutoInc

Sdscltyp2_ScrollUp:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 4)
	or xwa, xwa
	jrl nz, IvSdscltyp2_ReturnZeroJmp
	ld16_24 xwa, 0x02478e
	cps wa, 0
	jr le, Sdscltyp2_SetAutoIncUp
	dec 1, wa
	st16_24 0x02478e, xwa
	ld xwa, 0x50011
	ld xbc, 0x1e00051
	lds32 xde, 0
	call SendEvent
	ld xde, xhl
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001b
	call SendEvent
	ld16_24 xwa, 0x02478e
	sla wa, 2
	lda_24 xbc, 0xe9db7c
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld xbc, 0x1e0004d
	lds32 xde, 1
	call SendEvent

Sdscltyp2_SetAutoIncUp:
	ld xwa, (xsp + 8)
	ld xbc, 0x1c0001a
	ld xde, (xsp + 4)

Sdscltyp2_SetAutoInc:
	call SetAutoInc
	jr IvSdscltyp2_ReturnZeroJmp

Sdscltyp2_Paint:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 8)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	jr IvSdscltyp2_ReturnZeroJmp

Sdscltyp2_GetText:
	pushw 0xe9
	pushw 0xdbb0
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp

IvSdscltyp2_ReturnZeroJmp:
	lds32 xhl, 0
	jr Sdscltyp2_Epilogue

Sdscltyp2_ForwardToBase:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc

Sdscltyp2_Epilogue:
	pop xiz
	inc 8, xsp
	ret

LswScalingType:
	dec 4, xsp
	push xiz
	ld xiz, xde
	ld (xsp + 4), xwa
	cp xbc, 0x1e00083
	jr z, LswScaleType_ReturnZero
	cp xbc, 0x1e0003f
	jr z, LswScaleType_ReturnOne
	cp xbc, 0x1e0003e
	jr z, LswScaleType_ReturnOne
	cp xbc, 0x1e00041
	jr z, LswScaleType_StepSize
	cp xbc, 0x1e00040
	jr z, LswScaleType_SubParam
	cp xbc, 0x1e00042
	jr nz, LswScaleType_ReturnZero
	ld bc, (xiz + 4)
	ld xwa, 0xe9dbb6
	calr SdpartLookupPartId
	ld xbc, (xiz + 8)
	cp hl, 0xffff
	jr z, LswScaleType_StrDefault
	sla hl, 2
	lda_24 xwa, 0xe9dbd6
	ld_sril3 XWA, 0x07, 0xe0, 0xec
	push xwa
	jr LswScaleType_StrCopyReturn

LswScaleType_StrDefault:
	pushw 0xe9
	pushw 0xdd08

LswScaleType_StrCopyReturn:
	push xbc
	call Strcpy
	inc 8, xsp
	ld xhl, (xsp + 4)
	jr LswScaleType_PopIzSkip4Ret

LswScaleType_SubParam:
	ld xhl, 0x4281
	jr LswScaleType_PopIzSkip4Ret

LswScaleType_StepSize:
	lds32 xhl, 3
	jr LswScaleType_PopIzSkip4Ret

LswScaleType_ReturnOne:
	lds32 xhl, 1
	jr LswScaleType_PopIzSkip4Ret

LswScaleType_ReturnZero:
	lds32 xhl, 0

LswScaleType_PopIzSkip4Ret:
	pop xiz
	inc 4, xsp
	ret

LswScalingShift:
	push xiz
	ld xiz, xwa
	cp xbc, 0x1e00083
	jr z, LswScaleShift_ReturnZero
	cp xbc, 0x1e0003f
	jr z, LswScaleShift_ReturnOne
	cp xbc, 0x1e0003e
	jr z, LswScaleShift_ReturnOne
	cp xbc, 0x1e00041
	jr z, LswScaleShift_StepSize
	cp xbc, 0x1e00040
	jr z, LswScaleShift_SubParam
	cp xbc, 0x1e00042
	jr nz, LswScaleShift_ReturnZero
	ld wa, (xde + 4)
	sla wa, 2
	lda_24 xbc, 0xe9dd16
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	ld xwa, (xde + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	ld xhl, xiz
	jr LswScaleSharp_PopIzRet

LswScaleShift_SubParam:
	ld xhl, 0x4282
	jr LswScaleSharp_PopIzRet

LswScaleShift_StepSize:
	lds32 xhl, 3
	jr LswScaleSharp_PopIzRet

LswScaleShift_ReturnOne:
	lds32 xhl, 1
	jr LswScaleSharp_PopIzRet

LswScaleShift_ReturnZero:
	lds32 xhl, 0

LswScaleSharp_PopIzRet:
	pop xiz
	ret

LswScalingShift2:
	push xiz
	ld xiz, xwa
	cp xbc, 0x1e00083
	jr z, LswScaleShift2_ReturnZero
	cp xbc, 0x1e0003f
	jr z, LswScaleShift2_ReturnOne
	cp xbc, 0x1e0003e
	jr z, LswScaleShift2_ReturnOne
	cp xbc, 0x1e00041
	jr z, LswScaleShift2_StepSize
	cp xbc, 0x1e00040
	jr z, LswScaleShift2_SubParam
	cp xbc, 0x1e00042
	jr nz, LswScaleShift2_ReturnZero
	ld wa, (xde + 4)
	sla wa, 2
	lda_24 xbc, 0xe9dd76
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	ld xwa, (xde + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	ld xhl, xiz
	jr LswScaleSharp_PopIzRet2

LswScaleShift2_SubParam:
	ld xhl, 0x4282
	jr LswScaleSharp_PopIzRet2

LswScaleShift2_StepSize:
	lds32 xhl, 3
	jr LswScaleSharp_PopIzRet2

LswScaleShift2_ReturnOne:
	lds32 xhl, 1
	jr LswScaleSharp_PopIzRet2

LswScaleShift2_ReturnZero:
	lds32 xhl, 0

LswScaleSharp_PopIzRet2:
	pop xiz
	ret

LswScalingMode:
	push xiz
	ld xiz, xwa
	cp xbc, 0x1e00083
	jr z, LswScaleMode_ReturnZero
	cp xbc, 0x1e0003f
	jr z, LswScaleMode_ReturnOne
	cp xbc, 0x1e0003e
	jr z, LswScaleMode_ReturnOne
	cp xbc, 0x1e00041
	jr z, LswScaleMode_StepSize
	cp xbc, 0x1e00040
	jr z, LswScaleMode_SubParam
	cp xbc, 0x1e00042
	jr nz, LswScaleMode_ReturnZero
	ld wa, (xde + 4)
	sla wa, 2
	lda_24 xbc, 0xe9de1e
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	ld xwa, (xde + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	ld xhl, xiz
	jr LswScaleMode_PopIzRet

LswScaleMode_SubParam:
	ld xhl, 0x4280
	jr LswScaleMode_PopIzRet

LswScaleMode_StepSize:
	lds32 xhl, 3
	jr LswScaleMode_PopIzRet

LswScaleMode_ReturnOne:
	lds32 xhl, 1
	jr LswScaleMode_PopIzRet

LswScaleMode_ReturnZero:
	lds32 xhl, 0

LswScaleMode_PopIzRet:
	pop xiz
	ret

LswScalingKeyX:
	dec 4, xsp
	push xiz
	ld xiz, xde
	ld (xsp + 4), xwa
	cp xbc, 0x1e000b9
	jrl z, LswScaleKeyX_ReturnRange
	cp xbc, 0x1e000b8
	jrl z, LswScaleKeyX_ReturnOne
	cp xbc, 0x1e00083
	jrl z, LswScaleKeyX_ReturnZero
	cp xbc, 0x1e0003f
	jrl z, LswScaleKeyX_ReturnOne
	cp xbc, 0x1e0003e
	jrl z, LswScaleKeyX_ReturnFour
	cp xbc, 0x1e00041
	jrl z, LswScaleKeyX_StepSize
	cp xbc, 0x1e00040
	jr z, LswScaleKeyX_FindFocus
	cp xbc, 0x1e00042
	jrl nz, LswScaleKeyX_ReturnZero
	ld hl, (xiz + 4)
	exts xhl
	ld xwa, xhl
	ld xbc, 0xc9
	call Math_MultiplyAccumulate
	add xhl, 0x7f
	sra xhl, 8
	sub xhl, 0x64
	ld xwa, (xiz + 8)
	or xhl, xhl
	jr z, LswScaleKeyX_StrZero
	push xhl
	pushw 0xe9
	pushw 0xde32
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	jr LswScaleKeyX_LoadReturn

LswScaleKeyX_StrZero:
	pushw 0xe9
	pushw 0xde38
	push xwa
	call Strcpy
	inc 8, xsp

LswScaleKeyX_LoadReturn:
	ld xhl, (xsp + 4)
	jr LswEnd_PopIzSkip4Ret

LswScaleKeyX_FindFocus:
	lds iz, 0
	jr LswScaleKeyX_LoopCheck

LswScaleKeyX_LoopBody:
	call GetFocusObject
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	ld xde, 0xe9db7c
	add xde, xbc
	cp (xde), xhl
	jr nz, LswScaleKeyX_LoopNext
	add xwa, 0x4283
	ld xhl, xwa
	jr LswEnd_PopIzSkip4Ret

LswScaleKeyX_LoopNext:
	inc 1, iz

LswScaleKeyX_LoopCheck:
	ld wa, iz
	extz xwa
	sll xwa, 2
	ld xbc, 0xe9db7c
	add xbc, xwa
	ld xwa, (xbc)
	cp xwa, 0xffffffff
	jr nz, LswScaleKeyX_LoopBody

LswScaleKeyX_ReturnZero:
	lds32 xhl, 0
	jr LswEnd_PopIzSkip4Ret

LswScaleKeyX_StepSize:
	lds32 xhl, 3
	jr LswEnd_PopIzSkip4Ret

LswScaleKeyX_ReturnFour:
	lds32 xhl, 4
	jr LswEnd_PopIzSkip4Ret

LswScaleKeyX_ReturnOne:
	lds32 xhl, 1
	jr LswEnd_PopIzSkip4Ret

LswScaleKeyX_ReturnRange:
	ld xhl, 0x80

LswEnd_PopIzSkip4Ret:
	pop xiz
	inc 4, xsp
	ret

IvSoftverProc:
	lda xsp, (xsp - 10)
	push xiz
	ld xiz, xwa
	cp xbc, 0x1e0003a
	jrl z, Softver_GetText
	cp xbc, 0x1c0000d
	jrl z, Softver_Paint
	cp xbc, 0x1c0000c
	jr z, Softver_ShowHide
	cp xbc, 0x1c0000b
	jr z, Softver_ShowHide
	ld xwa, xiz
	call InheritedProc
	jrl Softver_Epilogue

Softver_ShowHide:
	ld xwa, xiz
	call InheritedProc
	push_sd24w 0x30, 0x79, 0xeb
	pushw 0xe9
	pushw 0xde3e
	lda xwa, (xsp + 10)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	lda xde, (xsp + 4)
	ld xwa, 0xf00001
	ld xbc, 0x1c0000f
	call SendEvent
	call Boot_ParseTableDataTimestamp
	pushw hl
	pushw 0xe9
	pushw 0xde42
	lda xwa, (xsp + 10)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	lda xde, (xsp + 4)
	ld xwa, 0xf00002
	ld xbc, 0x1c0000f
	call SendEvent
	call Boot_GetSystemPointer
	pushw hl
	pushw 0xe9
	pushw 0xde46
	lda xwa, (xsp + 10)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	lda xde, (xsp + 4)
	ld xwa, 0xf00003
	ld xbc, 0x1c0000f
	call SendEvent
	call Boot_ParseSubCPUTimestamp
	pushw hl
	pushw 0xe9
	pushw 0xde4a
	lda xwa, (xsp + 10)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	lda xde, (xsp + 4)
	ld xwa, 0xf00004
	ld xbc, 0x1c0000f
	jr Softver_SendEvent

Softver_Paint:
	ld xwa, xiz
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1c0000f
	lds32 xde, 0

Softver_SendEvent:
	call SendEvent
	jr Softver_ReturnZero

Softver_GetText:
	pushw 0xe9
	pushw 0xde4e
	push xde
	call Strcpy
	inc 8, xsp

Softver_ReturnZero:
	lds32 xhl, 0

Softver_Epilogue:
	pop xiz
	lda xsp, (xsp + 10)
	ret

IvMPverProc:
	lda xsp, (xsp - 10)
	push xiz
	ld xiz, xwa
	cp xbc, 0x1e0003a
	jr z, MPver_GetText
	cp xbc, 0x1c0000d
	jr z, MPver_Paint
	cp xbc, 0x1c0000c
	jr z, MPver_ShowHide
	cp xbc, 0x1c0000b
	jr z, MPver_ShowHide
	ld xwa, xiz
	call InheritedProc
	jr MPver_Epilogue

MPver_ShowHide:
	ld xwa, xiz
	call InheritedProc
	call Get_Firmware_Version
	extz hl
	pushw hl
	pushw 0xe9
	pushw 0xde54
	lda xwa, (xsp + 10)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	lda xde, (xsp + 4)
	ld xwa, 0xef000a
	ld xbc, 0x1c0000f
	jr MPver_SendEvent

MPver_Paint:
	ld xwa, xiz
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1c0000f
	lds32 xde, 0

MPver_SendEvent:
	call SendEvent
	jr MPver_ReturnZero

MPver_GetText:
	pushw 0xe9
	pushw 0xde5c
	push xde
	call Strcpy
	inc 8, xsp

MPver_ReturnZero:
	lds32 xhl, 0

MPver_Epilogue:
	pop xiz
	lda xsp, (xsp + 10)
	ret

AcWelcomScreenProc:
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 16), xde
	ld xiz, xbc
	ld (xsp + 20), xwa
	cp xiz, 0x1c0000d
	jrl z, AcWelcomScreen_Paint
	cp xiz, 0x1c10009
	jrl z, AcWelcomScreen_SubCpuLoaded
	cp xiz, 0x1c10004
	jrl z, AcWelcomScreen_SubCpuError
	cp xiz, 0x1c0000e
	jrl z, AcWelcomScreen_Select
	cp xiz, 0x1c0000c
	jrl z, AcWelcomScreen_ShowHide
	cp xiz, 0x1c0000b
	jrl z, AcWelcomScreen_ShowHide
	cp xiz, 0x1c0000a
	jrl z, AcWelcomScreen_Activate
	cp xiz, 0x1c00002
	jr z, AcWelcomScreen_Close
	cp xiz, 0x1c00001
	jrl nz, AcWelcomScreen_ForwardToBase
	lds wa, 1
	call ChangePalette
	call Get_Region_Code
	ld xwa, 0xe9e806
	cps l, 2
	jr nz, AcWelcomScreen_Init_StoreData
	ld xwa, 0xe9df4e

AcWelcomScreen_Init_StoreData:
	st32_24 0x024786, xwa
	ld xwa, (xsp + 20)
	ld xbc, xiz
	ld xde, (xsp + 16)
	call InheritedProc
	call Boot_GetButtonComboCode
	cps l, 2
	jr nz, AcWelcomScreen_Init_CheckSubCpu
	ld xwa, 0xffffffff
	ld xbc, 0x1c10009
	lds32 xde, 0
	jr AcWelcomScreen_Init_DispatchTimer

AcWelcomScreen_Init_CheckSubCpu:
	call SubCPU_Payload_GetErrorFlag
	cps hl, 0
	jr ge, AcWelcomScreen_Init_SwitchMode
	ld xwa, 0xffffffff
	ld xbc, 0x1c10004
	lds32 xde, 0

AcWelcomScreen_Init_DispatchTimer:
	call PostEvent
	jrl AcWelcomScreen_ReturnHandled

AcWelcomScreen_Init_SwitchMode:
	ld xwa, 0xffffffff
	ld xbc, 0x1e000b3
	lds32 xde, 1
	jrl AcWelcomScreen_DispatchEvent

AcWelcomScreen_Close:
	ld xwa, 0x1c0000e
	push xwa
	lds32 xwa, 0
	push xwa
	lds32 xwa, 1
	ld xbc, (xsp + 28)
	ld xde, (xsp + 28)
	call KillApTimer
	ld xwa, (xsp + 20)
	ld xbc, xiz
	ld xde, (xsp + 16)
	call InheritedProc
	lds wa, 2
	call ChangePalette
	jrl AcWelcomScreen_ReturnHandled

AcWelcomScreen_Activate:
	call CheckNotDrawFlag
	cps hl, 0
	jr z, AcWelcomScreen_Activate_Setup
	call LcdOff
	ld xwa, 0xe9f0fa
	lds bc, 0
	call DrawBox
	lds wa, 1
	call SetNeedUpdate
	call UpdateScreen
	lds wa, 0
	call SetNeedUpdate
	call LcdOn

AcWelcomScreen_Activate_Setup:
	ld xwa, (xsp + 20)
	ld xbc, xiz
	ld xde, (xsp + 16)
	call InheritedProc
	call CheckNotDrawFlag
	cps hl, 0
	jrl z, AcWelcomScreen_ReturnHandled
	call PaletteBankRotate
	sti16_24 0x024784, 0x0001
	ld32_24 xbc, 0x024786
	ld xwa, 0x1c0000e
	push xwa
	lds32 xwa, 0
	push xwa
	ld xwa, (xbc + 12)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 28)
	jrl AcWelcomScreen_Select_StartTimer

AcWelcomScreen_ShowHide:
	ld xwa, (xsp + 20)
	ld xbc, xiz
	ld xde, (xsp + 16)
	jrl AcWelcomScreen_CallBase

AcWelcomScreen_Select:
	ld16_24 xbc, 0x024784
	exts xbc
	ld xwa, xbc
	add xwa, xwa
	add xwa, xbc
	sll xwa, 2
	ld32_24 xbc, 0x024786
	add xwa, xbc
	ld xbc, xwa
	ld hl, (xwa + 8)
	lda xiy, (xwa + 4)
	lda xde, (xwa + 10)
	cps hl, 0
	jrl mi, AcWelcomScreen_Select_NextStep
	cp hl, 0xc
	jrl gt, AcWelcomScreen_Select_NextStep
	add hl, hl
	lda_24 xix, 0xe9f102
	ld_sriw3 HL, 0x07, 0xf0, 0xec
	lda_24 xix, AcWelcomScreen_RenderBytecode
	jp_dri 8, 0x07, 0xf0, 0xec
AcWelcomScreen_RenderBytecode:
	ld	xwa, 4294967295
	ld	xbc, 31457459
	lds32	xde, 0
	jrl	987
	ld	iz, (xbc+10)
	cps	iz, 2
	jrl	ge, 873
	ld	bc, iz
	muls	bc, 12
	lda_24	xwa, 256524
	.byte 0xf3
	reti
	.byte 0xe0, 0xe4
	ldw	wa, 2712
	push	xsp
	swi	7
	swi	7
	jr	z, 26
	cp	iz, 65535
	jr	z, 20
	lda	xiy, (xwa+4)
	lda	xix, (xsp+12)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	lda	xwa, (xsp+12)
	ldw	bc, 30
	call	ClipBlit_Direct
	ld16_24	wa, 149380
	exts	xwa
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	sll	xbc, 2
	addda32_24	xbc, 149382
	lda	xiy, (xbc+4)
	lda	xix, (xsp+12)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	lda	xwa, (xsp+12)
	ldw	bc, 30
	call	ClipBlit_Replace
	cp	iz, 65535
	jrl	z, 776
	muls	iz, 12
	lda_24	xwa, 256524
	ld16_24	bc, 149380
	exts	xbc
	ld	xiy, xbc
	add	xiy, xiy
	add	xiy, xbc
	sll	xiy, 2
	addda32_24	xiy, 149382
	.byte 0xf3
	reti
	.byte 0xe0
	swi	0
	ldw	ix, 44761
	.byte 0x95
	scf
	jrl	734
	ld	xwa, (xsp+20)
	ld	xbc, 29360140
	lds32	xde, 0
	call	SendEvent
	jrl	717
	lda	xix, (xsp+12)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	lda	xwa, (xsp+12)
	pushw	17
	.byte 0x92, 0x04
	pushw	247
	ld	xbc, 15326816
	ldw	de, 16
	jrl	171
	lda	xix, (xsp+12)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	lda	xwa, (xsp+12)
	pushw	17
	.byte 0x92, 0x04
	pushw	247
	ld	xbc, 15326952
	ldw	de, 16
	jrl	142
	lda	xix, (xsp+12)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	lda	xwa, (xsp+12)
	pushw	17
	.byte 0x92, 0x04
	pushw	247
	.byte 0x41
	.long Bitmap_DigitL
	ldw	de, 16
	jr	114
	lda	xix, (xsp+12)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	lda	xwa, (xsp+12)
	pushw	17
	.byte 0x92, 0x04
	pushw	247
	ld	xbc, 15327020
	ldw	de, 16
	jr	86
	lda	xix, (xsp+12)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	lda	xwa, (xsp+12)
	pushw	17
	.byte 0x92, 0x04
	pushw	247
	.byte 0x41
	.long Bitmap_DigitR
	ldw	de, 16
	jr	58
	lda	xiy, (xbc+4)
	lda	xix, (xsp+12)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	lda	xwa, (xsp+12)
	pushw	17
	pushw	255
	pushw	247
	.byte 0x41
	.long Bitmap_Digit1
	ldw	de, 16
	call	DrawBitmapSP2
	lda	xwa, (xsp+12)
	.byte 0x90
	push	xwa
	rcf
	nop
	pushw	17
	pushw	255
	pushw	247
	ld	xbc, 15326918
	ldw	de, 16
	call	DrawBitmapSP2
	jrl	510
	lda_24	xhl, 256548
	.byte 0x9b
	ldwio	63, 65535
	jr	z, 77
	lda	xwa, (xsp+4)
	lda	xde, (xwa+2)
	ld	bc, (xhl+6)
	ld	(xde), bc
	ld	bc, (xhl+4)
	ld	(xwa), bc
	lda	xhl, (xwa+4)
	ld	bc, (xwa)
	add	bc, 80
	ld	(xhl), bc
	ld	bc, (xde)
	add	bc, 17
	ld	(xwa+6), bc
	ld16_24	bc, 149380
	exts	xbc
	ld	xde, xbc
	add	xde, xde
	add	xde, xbc
	sll	xde, 2
	ld32_24	xbc, 149382
	add	xde, xbc
	.byte 0x9a
	ldio	63, 12
	nop
	jr	nz, 4
	.byte 0x93
	push	xwa
	rcf
	nop
	ldw	bc, 245
	call	DrawBox
	ld16_24	wa, 149380
	exts	xwa
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	sll	xbc, 2
	addda32_24	xbc, 149382
	lda	xiy, (xbc+4)
	lda	xix, (xsp+12)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	lda	xwa, (xsp+12)
	pushw	17
	ld16_24	bc, 149380
	exts	xbc
	ld	xde, xbc
	add	xde, xde
	add	xde, xbc
	sll	xde, 2
	addda32_24	xde, 149382
	.byte 0x9a
	ldwio	4, 63243
	nop
	ld	xbc, 15326816
	ldw	de, 16
	call	DrawBitmapSP2
	lda	xwa, (xsp+12)
	.byte 0x90
	push	xwa
	rcf
	nop
	pushw	17
	ld16_24	bc, 149380
	exts	xbc
	ld	xde, xbc
	add	xde, xde
	add	xde, xbc
	sll	xde, 2
	addda32_24	xde, 149382
	.byte 0x9a
	ldwio	4, 63243
	nop
	ld	xbc, 15326952
	ldw	de, 16
	call	DrawBitmapSP2
	lda	xwa, (xsp+12)
	.byte 0x90
	push	xwa
	rcf
	nop
	pushw	17
	ld16_24	bc, 149380
	exts	xbc
	ld	xde, xbc
	add	xde, xde
	add	xde, xbc
	sll	xde, 2
	addda32_24	xde, 149382
	.byte 0x9a
	ldwio	4, 63243
	nop
	ld	xbc, 15326884
	ldw	de, 16
	call	DrawBitmapSP2
	lda	xwa, (xsp+12)
	.byte 0x90
	push	xwa
	rcf
	nop
	pushw	17
	ld16_24	bc, 149380
	exts	xbc
	ld	xde, xbc
	add	xde, xde
	add	xde, xbc
	sll	xde, 2
	addda32_24	xde, 149382
	.byte 0x9a
	ldwio	4, 63243
	nop
	ld	xbc, 15326952
	ldw	de, 16
	call	DrawBitmapSP2
	ld16_24	wa, 149380
	exts	xwa
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	sll	xbc, 2
	ld32_24	xwa, 149382
	add	xbc, xwa
	.byte 0x99
	ldio	63, 12
	nop
	jr	nz, 51
	lda	xwa, (xsp+12)
	.byte 0x90
	push	xwa
	rcf
	nop
	pushw	17
	ld16_24	bc, 149380
	exts	xbc
	ld	xde, xbc
	add	xde, xde
	add	xde, xbc
	sll	xde, 2
	ld32_24	xbc, 149382
	add	xde, xbc
	.byte 0x9a
	ldwio	4, 63243
	nop
	.byte 0x41
	.long Bitmap_DigitD
	ldw	de, 16
	call	DrawBitmapSP2
	lda	xwa, (xsp+12)
	.byte 0x90
	push	xwa
	rcf
	nop
	pushw	17
	ld16_24	bc, 149380
	exts	xbc
	ld	xde, xbc
	add	xde, xde
	add	xde, xbc
	sll	xde, 2
	addda32_24	xde, 149382
	.byte 0x9a
	ldwio	4, 63243
	nop
	ld	xbc, 15326986
	ldw	de, 16
	call	DrawBitmapSP2
	ld16_24	wa, 149380
	exts	xwa
	ld	xiy, xwa
	add	xiy, xiy
	add	xiy, xwa
	sll	xiy, 2
	addda32_24	xiy, 149382
	ld	xix, 256548
	lds	bc, 6
	.byte 0x95
	scf
	jr	36
	ld	xwa, 18874379
	ld	xbc, 31457452
	lds32	xde, 0
	call	ApFuncCall
	call	CaptureLcd
	ld	xwa, 18874379
	ld	xbc, 31457453
	lds32	xde, 0
	call	ApFuncCall

AcWelcomScreen_Select_NextStep:
	ld16_24 xwa, 0x024784
	inc 1, wa
	st16_24 0x024784, xwa
	exts xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 2
	addda32_24 xbc, 149382
	ld xwa, (xbc)
	or xwa, xwa
	jrl z, AcWelcomScreen_Select
	ld xbc, 0x1c0000e
	push xbc
	lds32 xbc, 0
	push xbc
	ld xbc, (xsp + 28)
	ld xde, (xsp + 28)

AcWelcomScreen_Select_StartTimer:
	call SetApTimer
	jr AcWelcomScreen_ReturnHandled

AcWelcomScreen_SubCpuError:
	ld xwa, (xsp + 20)
	ld xbc, xiz
	ld xde, (xsp + 16)
	call InheritedProc
	ld xwa, 0xef0004
	ld xbc, 0x1c00001
	lds32 xde, 3
	jr AcWelcomScreen_DispatchEvent

AcWelcomScreen_SubCpuLoaded:
	ld xwa, (xsp + 20)
	ld xbc, xiz
	ld xde, (xsp + 16)
	call InheritedProc
	ld xwa, 0xef0007
	ld xbc, 0x1c00001
	lds32 xde, 3

AcWelcomScreen_DispatchEvent:
	call SendEvent
	jr AcWelcomScreen_ReturnHandled

AcWelcomScreen_Paint:
	ld xwa, (xsp + 20)
	ld xbc, xiz
	ld xde, (xsp + 16)

AcWelcomScreen_CallBase:
	call InheritedProc

AcWelcomScreen_ReturnHandled:
	lds32 xhl, 0
	jr AcWelcomScreen_Return

AcWelcomScreen_ForwardToBase:
	ld xwa, (xsp + 20)
	ld xbc, xiz
	ld xde, (xsp + 16)
	call InheritedProc

AcWelcomScreen_Return:
	pop xiz
	lda xsp, (xsp + 20)
	ret

PsMixerControlProc:
	lda xsp, (xsp - 90)
	push xiz
	ld (xsp + 82), xde
	ld (xsp + 86), xbc
	ld (xsp + 90), xwa
	ld xbc, (xsp + 86)
	cp xbc, 0x1e0003a
	jrl z, PsMixer_ControlCommon
	ld xwa, (xsp + 86)
	cp xwa, 0x1c0002f
	jrl z, PsMixer_ControlCase9
	cp xwa, 0x1c00031
	jrl z, PsMixer_ControlCase8
	cp xwa, 0x1c00030
	jrl z, PsMixer_ControlCase7
	cp xwa, 0x1c00027
	jrl z, PsMixer_ControlCase6
	cp xwa, 0x1c00007
	jrl z, PsMixer_ControlCase5
	cp xwa, 0x1e000a7
	jrl z, PsMixer_ControlCase4
	cp xwa, 0x1c0000d
	jrl z, PsMixer_ControlCase3
	cp xwa, 0x1c0000c
	jrl z, PsMixer_ControlCase2
	cp xwa, 0x1c0000b
	jrl z, PsMixer_ControlCase2
	cp xwa, 0x1c00002
	jrl z, PsMixer_ControlCase1
	cp xwa, 0x1c00001
	jr z, PsMixer_ControlHandler
	sub xbc, 0x1c00017
	cp xbc, 0x0
	jrl lt, PsMixer_ControlReturn
	cp xbc, 0x9
	jrl gt, PsMixer_ControlReturn
	add xbc, xbc
	add xbc, 0xe9f5a8
	ld bc, (xbc)
	lda_24 xix, PsMixer_ControlHandler
	jp_dri 8, 0x07, 0xf0, 0xe4

; PsMixerControlProc control handler dispatch (10-entry)
PsMixer_ControlHandler:
	ld xwa, (xsp + 82)
	cp xwa, 0x4
	jr z, AudioCtrl_SendB3Event
	cp xwa, 0x5
	jr z, AudioCtrl_InitCounters
	or xwa, xwa
	jr z, AudioCtrl_InitCounters
	cp xwa, 0x3
	jr nz, AudioCtrl_MainFuncCallPt
	ld xwa, 0xffffffff
	ld xbc, 0x1e000b3
	lds32 xde, 1
	call SendEvent
	call GetPartSelect
	st16_24 0x02478a, xhl

AudioCtrl_InitCounters:
	sti16_24 0x024794, 0x0000
	sti16_24 0x024790, 0x0000
	sti16_24 0x024796, 0x0000
	sti16_24 0x024792, 0x0000
	ldw (xsp + 10), 0x0

AudioCtrl_ScanLoop:
	ld wa, (xsp + 10)
	calr Util_SignExtendAndDouble
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	cpw (xwa + 6), 0x1
	jr nz, AudioCtrl_ScanNext
	ld wa, (xsp + 10)
	st16_24 0x024792, xwa
	jr AudioCtrl_MainFuncCallPt

AudioCtrl_ScanNext:
	incm 1, (xsp + 10)
	cpw (xsp + 10), 0x5
	jr c, AudioCtrl_ScanLoop
	jr AudioCtrl_MainFuncCallPt

AudioCtrl_SendB3Event:
	ld xwa, 0xffffffff
	ld xbc, 0x1e000b3
	lds32 xde, 1
	call SendEvent

AudioCtrl_MainFuncCallPt:
	ld xwa, 0x1400001
	ld xbc, 0x1e000ab
	lds32 xde, 1
	call MainFuncCall
	ld xwa, (xsp + 90)
	ld xbc, (xsp + 86)
	ld xde, (xsp + 82)
	call InheritedProc
	jrl AudioCtrl_ReturnZero

; PsMixer control case 1
PsMixer_ControlCase1:
	ld xwa, (xsp + 90)
	ld xbc, (xsp + 86)
	ld xde, (xsp + 82)
	call InheritedProc
	ld xwa, (xsp + 82)
	cp xwa, 0x4
	jr z, PsMixer_Case1_PartSelect
	cp xwa, 0x3
	jr z, PsMixer_Case1_ReturnAB
	cp xwa, 0x5
	jr z, PsMixer_Case1_SetupA0
	or xwa, xwa
	jr nz, PsMixer_Case1_ReturnAB

PsMixer_Case1_SetupA0:
	ld xwa, 0x1400002
	ld xbc, 0x1e000a0
	ld xde, 0x3f
	jr PsMixer_Case1_MainFuncCall

PsMixer_Case1_PartSelect:
	ld16_24 xde, 0x02478a
	extz xde
	ld xwa, 0x1400002
	ld xbc, 0x1e000a0

PsMixer_Case1_MainFuncCall:
	call MainFuncCall

PsMixer_Case1_ReturnAB:
	ld xwa, 0x1400001
	ld xbc, 0x1e000ab
	lds32 xde, 0
	call MainFuncCall
	jrl AudioCtrl_ReturnZero

; PsMixer control case 2
PsMixer_ControlCase2:
	ld xwa, (xsp + 90)
	ld xbc, (xsp + 86)
	ld xde, (xsp + 82)
	call InheritedProc
	ld16_24 xbc, 0x024792
	extz xbc
	ld16_24 xwa, 0x024790
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 90)
	ld xbc, 0x1c00017
	call SetDialUp
	ld16_24 xbc, 0x024792
	extz xbc
	ld16_24 xwa, 0x024790
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 90)
	ld xbc, 0x1c00018
	call SetDialDown
	lds wa, 1
	call SetDialEnable
	call GetPartSelect
	extz xhl
	ld xwa, 0xffffffff
	ld xbc, 0x1c0002f
	ld xde, xhl
	jrl PsMixer_SendEventAndForward

; PsMixer control case 3
PsMixer_ControlCase3:
	ld xwa, (xsp + 90)
	ld xbc, (xsp + 86)
	ld xde, (xsp + 82)
	call InheritedProc
	ld xwa, (xsp + 90)
	ld xbc, 0x1e000a7
	lds32 xde, 0
	jrl PsMixer_SendEventAndForward

; PsMixer control case 4
PsMixer_ControlCase4:
	ld16_24 xwa, 0x024796
	muls wa, 0x5
	ld (xsp + 8), wa
	ldw (xsp + 10), 0x0

; PsMixer control dispatch helper
PsMixer_ControlHelper:
	ld wa, (xsp + 8)
	calr Util_SignExtendAndDouble
	ld (xsp + 4), xhl
	ld de, (xsp + 8)
	extz xde
	ld xwa, (xsp + 4)
	ld wa, (xwa + 2)
	sla wa, 2
	lda_24 xbc, 0xe9f11c
	st_dri3b C, 0x07, 0xe4, 0xe0
	ld xwa, (xsp + 90)
	ld xbc, 0x1c0000d
	ld xhl, (xhl)
	call (xhl)
	ld de, (xsp + 8)
	lda_24 xbc, 0xe9f11c
	extz xde
	ld xwa, (xsp + 4)
	ld wa, (xwa + 2)
	sla wa, 2
	st_dri3b C, 0x07, 0xe4, 0xe0
	ld16_24 xwa, 0x024792
	cp wa, (xsp + 8)
	jr nz, PsMixer_EventCallback
	add xde, 0x10000
	ld xwa, (xsp + 90)
	ld xbc, 0x1c0000e
	ld xhl, (xhl)
	call (xhl)
	jr PsMixer_GridSetup

; PsMixer event callback dispatch
PsMixer_EventCallback:
	ld xwa, (xsp + 90)
	ld xbc, 0x1c0000e
	ld xhl, (xhl)
	call (xhl)

PsMixer_GridSetup:
	ld16_24 xiz, 0x024794
	sla iz, 3
	ldw (xsp + 12), 0x0

; PsMixer grid loop handler
PsMixer_GridLoop:
	ld bc, (xsp + 8)
	extz xbc
	ld wa, iz
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 4)
	ld wa, (xwa + 2)
	sla wa, 2
	lda_24 xbc, 0xe9f11c
	st_dri3b C, 0x07, 0xe4, 0xe0
	ld xwa, (xsp + 90)
	ld xbc, 0x1c0000f
	ld xhl, (xhl)
	call (xhl)
	inc 1, iz
	incm 1, (xsp + 12)
	cpw (xsp + 12), 0x8
	jr c, PsMixer_GridLoop
	incm 1, (xsp + 8)
	incm 1, (xsp + 10)
	cpw (xsp + 10), 0x5
	jrl c, PsMixer_ControlHelper
	ld16_24 xwa, 0x024790
	calr PsMixer_ReadWordArrayEntry
	ldfr_werp HL, 0xfa
	ldto_werp WA, 0xfa
	add wa, wa
	lda_24 xbc, 0xe953ce
	ld_sriw3 DE, 0x07, 0xe4, 0xe0
	exts xde
	ld xwa, 0x1400004
	ld xbc, 0x1e0005e
	call FuncCall
	jrl AudioCtrl_ReturnZero
	ld xwa, (xsp + 90)
	ld xbc, (xsp + 86)
	ld xde, (xsp + 82)
	call InheritedProc
	ld xwa, (xsp + 82)
	dec 1, wa
	st16_24 0x024796, xwa
	muls wa, 0x5
	ld (xsp + 8), wa
	ldw (xsp + 10), 0x0

PsMixer_FindActiveLoop:
	ld wa, (xsp + 8)
	calr Util_SignExtendAndDouble
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	cpw (xwa + 6), 0x1
	jr nz, PsMixer_FindActiveNext
	ld wa, (xsp + 8)
	st16_24 0x024792, xwa
	jr PsMixer_ShowEventAndForward

PsMixer_FindActiveNext:
	incm 1, (xsp + 8)
	incm 1, (xsp + 10)
	cpw (xsp + 10), 0x5
	jr c, PsMixer_FindActiveLoop

PsMixer_ShowEventAndForward:
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000b
	lds32 xde, 0
	jrl PsMixer_SendEventAndForward

; PsMixer control case 5
PsMixer_ControlCase5:
	ld xwa, 0x2600024
	ld xbc, 0x1e00029
	ld xde, (xsp + 82)
	call SendEvent
	ld iz, hl
	cps iz, 7
	jrl gt, AudioCtrl_DispatchHandler
	ld16_24 xwa, 0x024794
	sla wa, 3
	add iz, wa
	cpda16_24 xiz, 149392
	jrl z, PsMixer_Case5_DialSetup
	ld wa, iz
	calr PsMixer_ReadWordArrayEntry
	extz xhl
	add xhl, xhl
	ld xbc, 0xe953ce
	add xbc, xhl
	ld de, (xbc)
	exts xde
	ld xwa, 0x1400002
	ld xbc, 0x1e000a0
	call MainFuncCall
	ld16_24 xbc, 0x024792
	extz xbc
	ld wa, iz
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 90)
	ld xbc, 0x1c00017
	call SetDialUp
	ld16_24 xbc, 0x024792
	extz xbc
	ld wa, iz
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 90)
	ld xbc, 0x1c00018
	call SetDialDown
	lds wa, 1
	call SetDialEnable
	st16_24 0x024790, xiz
	ld xwa, (xsp + 90)
	ld xbc, 0x1e000a7
	lds32 xde, 0
	call SendEvent
	ld16_24 xwa, 0x024790
	calr PsMixer_ReadWordArrayEntry
	extz xhl
	add xhl, xhl
	ld xbc, 0xe953ce
	add xbc, xhl
	ld de, (xbc)
	exts xde
	ld xwa, 0x1400004
	ld xbc, 0x1e0005e
	call FuncCall
	jr PsMixer_Case5_SetAutoInc

PsMixer_Case5_DialSetup:
	ld wa, iz
	ld16_24 xbc, 0x024792
	extz xbc
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 82)
	bit 7, wa
	jr z, PsMixer_Case5_DialUp
	ld xwa, (xsp + 90)
	ld xbc, 0x1c00018
	jr PsMixer_Case5_SendEvent

PsMixer_Case5_DialUp:
	ld xwa, (xsp + 90)
	ld xbc, 0x1c00017

PsMixer_Case5_SendEvent:
	call SendEvent

PsMixer_Case5_SetAutoInc:
	ld xwa, (xsp + 90)
	ld xbc, 0x1c00027
	ld xde, (xsp + 82)
	call SetAutoInc
	jrl AudioCtrl_ReturnToCallerExit

; Audio controller dispatch handler
AudioCtrl_DispatchHandler:
	cp iz, 0x88
	jrl lt, AudioCtrl_PageHandler
	cp iz, 0x8c
	jrl gt, AudioCtrl_PageHandler
	ld16_24 xwa, 0x024796
	muls wa, 0x5
	ld (xsp + 8), iz
	submi16 (xsp + 8), 0x88
	add (xsp + 8), wa
	ld wa, (xsp + 8)
	cpda16_24 xwa, 149394
	jrl z, AudioCtrl_ReturnToCallerExit
	ld wa, (xsp + 8)
	calr Util_SignExtendAndDouble
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	cpw (xwa), 0x20
	jrl z, AudioCtrl_ReturnToCallerExit
	ld de, (xsp + 8)
	extz xde
	add xde, 0x10000
	ld wa, (xwa + 2)
	sla wa, 2
	lda_24 xbc, 0xe9f11c
	st_dri3b C, 0x07, 0xe4, 0xe0
	ld xwa, (xsp + 90)
	ld xbc, 0x1c0000e
	ld xhl, (xhl)
	call (xhl)
	ld16_24 xwa, 0x024792
	calr Util_SignExtendAndDouble
	ld (xsp + 4), xhl
	ld16_24 xde, 0x024792
	extz xde
	ld xwa, (xsp + 4)
	ld wa, (xwa + 2)
	sla wa, 2
	lda_24 xbc, 0xe9f11c
	st_dri3b C, 0x07, 0xe4, 0xe0
	ld xwa, (xsp + 90)
	ld xbc, 0x1c0000e
	ld xhl, (xhl)
	call (xhl)
	ld wa, (xsp + 8)
	st16_24 0x024792, xwa
	ld bc, (xsp + 8)
	extz xbc
	ld16_24 xwa, 0x024790
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 90)
	ld xbc, 0x1c00017
	call SetDialUp
	ld16_24 xbc, 0x024792
	extz xbc
	ld16_24 xwa, 0x024790
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 90)
	ld xbc, 0x1c00018
	call SetDialDown
	lds wa, 1
	call SetDialEnable
	ld xwa, (xsp + 90)
	ld xbc, 0x1e000a7
	lds32 xde, 0
	jrl PsMixer_SendEventAndForward

AudioCtrl_PageHandler:
	ld xwa, (xsp + 82)
	cp xwa, 0x8f
	jrl nz, AudioCtrl_CheckEventF
	incdi16_24 8, 149392
	incdi16_24 1, 149396
	ld16_24 xwa, 0x024790
	calr PsMixer_ReadWordArrayEntry
	ldfr_werp HL, 0xfa
	cp_erpw 0xfa, 0xff, 0x00
	jr z, AudioCtrl_PageAdvance
	ld xwa, 0xc0
	call SndParam_LookupReadOnly
	cps hl, 1
	scc16 z, bc
	cpdi16_24 149396, 2
	scc16 z, wa
	and wa, bc
	jr z, AudioCtrl_SetupPartDisplay

AudioCtrl_PageAdvance:
	ld16_24 xwa, 0x024790
	exts xwa
	divs wa, 0x8
	ldto_werp WA, 0xe2
	st16_24 0x024790, xwa
	sti16_24 0x024794, 0x0000
	ld16_24 xwa, 0x024790
	calr PsMixer_ReadWordArrayEntry
	ldfr_werp HL, 0xfa

AudioCtrl_SetupPartDisplay:
	ldto_werp WA, 0xfa
	add wa, wa
	lda_24 xbc, 0xe953ce
	ld_sriw3 DE, 0x07, 0xe4, 0xe0
	exts xde
	ld xwa, 0x1400002
	ld xbc, 0x1e000a0
	call MainFuncCall
	ldto_werp WA, 0xfa
	add wa, wa
	lda_24 xbc, 0xe953ce
	ld_sriw3 DE, 0x07, 0xe4, 0xe0
	exts xde
	ld xwa, 0x1400004
	ld xbc, 0x1e0005e
	call FuncCall
	ld16_24 xbc, 0x024792
	extz xbc
	ld16_24 xwa, 0x024790
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 90)
	ld xbc, 0x1c00017
	call SetDialUp
	ld16_24 xbc, 0x024792
	extz xbc
	ld16_24 xwa, 0x024790
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 90)
	ld xbc, 0x1c00018
	call SetDialDown
	lds wa, 1
	call SetDialEnable
	ld xwa, (xsp + 90)
	ld xbc, 0x1c0000d
	lds32 xde, 0
	jrl PsMixer_SendEventAndForward

AudioCtrl_CheckEventF:
	ld xwa, (xsp + 82)
AudioCtrl_HandleEventF:
	cp xwa, 0xf
	jrl nz, AudioCtrl_ReturnToCallerExit
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e0007a
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr nz, AudioCtrl_QueryTitle
	call GetModeNow
	cp xhl, 0x1800007
	jr z, AudioCtrl_PostMode7
	cp xhl, 0x1800002
	jr nz, AudioCtrl_ReturnToCallerExit
	ld xwa, 0xffffffff
	ld xbc, 0x1c00015
	ld xde, 0x1a00002
	call PostEvent
	ld xwa, (xsp + 90)
	ld xbc, (xsp + 86)
	ld xde, (xsp + 82)
	jrl AudioCtrl_ProcessParamsAndReturn

AudioCtrl_PostMode7:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00015
	ld xde, 0x1a000d6
	call PostEvent
	ld xwa, (xsp + 90)
	ld xbc, (xsp + 86)
	ld xde, (xsp + 82)
	jrl AudioCtrl_ProcessParamsAndReturn

AudioCtrl_QueryTitle:
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e00079
	lds32 xde, 0
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e0009a
	lds32 xde, 0
	call SendEvent

AudioCtrl_ReturnToCallerExit:
	ld xwa, (xsp + 90)
	ld xbc, (xsp + 86)
	ld xde, (xsp + 82)
	jrl AudioCtrl_ProcessParamsAndReturn

; PsMixer control case 6
PsMixer_ControlCase6:
	ld xwa, 0x2600024
	ld xbc, 0x1e00029
	ld xde, (xsp + 82)
	call SendEvent
	ld iz, hl
	cps iz, 7
	jr gt, PsMixer_Case6_Forward
	ld16_24 xwa, 0x024794
	sla wa, 3
	add iz, wa
	ld wa, iz
	ld16_24 xbc, 0x024792
	extz xbc
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 82)
	bit 7, wa
	jr z, PsMixer_Case6_ScrollDown
	ld xwa, (xsp + 90)
	ld xbc, 0x1c0001a
	jr PsMixer_Case6_SendScroll

PsMixer_Case6_ScrollDown:
	ld xwa, (xsp + 90)
	ld xbc, 0x1c00019

PsMixer_Case6_SendScroll:
	call SendEvent
	ld xwa, (xsp + 90)
	ld xbc, 0x1c00027
	ld xde, (xsp + 82)
	call SetAutoInc
	jrl AudioCtrl_ReturnZero

PsMixer_Case6_Forward:
	ld xwa, (xsp + 90)
	ld xbc, (xsp + 86)
	ld xde, (xsp + 82)
	jrl AudioCtrl_ProcessParamsAndReturn

; PsMixer control case 7
PsMixer_ControlCase7:
	ld xwa, 0x2600024
	ld xbc, 0x1e00029
	ld xde, (xsp + 82)
	call SendEvent
	ld iz, hl
	cps iz, 7
	jr gt, PsMixer_Case7_Forward
	ld xwa, 0xffffffff
	ld xbc, 0x1c00009
	ld xde, (xsp + 82)
	call SendEvent
	ld xde, (xsp + 82)
	set 7, de
	ld xwa, 0xffffffff
	ld xbc, 0x1c00009
	call SendEvent
	ld16_24 xwa, 0x024794
	sla wa, 3
	add iz, wa
	ld16_24 xbc, 0x024792
	extz xbc
	ld wa, iz
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 90)
	ld xbc, 0x1c00031
	jrl PsMixer_SendEventAndForward

PsMixer_Case7_Forward:
	ld xwa, (xsp + 90)
	ld xbc, (xsp + 86)
	ld xde, (xsp + 82)
	jrl AudioCtrl_ProcessParamsAndReturn

; PsMixer control case 8
PsMixer_ControlCase8:
	ld xwa, (xsp + 90)
	ld xbc, (xsp + 86)
	ld xde, (xsp + 82)
	call InheritedProc
	ld xwa, (xsp + 82)
	ld (xsp + 8), wa
	ld wa, (xsp + 8)
	calr Util_SignExtendAndDouble
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld wa, (xwa + 2)
	sla wa, 2
	lda_24 xbc, 0xe9f11c
	st_dri3b C, 0x07, 0xe4, 0xe0
	ld xwa, (xsp + 90)
	ld xbc, (xsp + 86)
	ld xde, (xsp + 82)
	ld xhl, (xhl)
	call (xhl)
	jrl AudioCtrl_ReturnZero
	ld xwa, (xsp + 90)
	ld xbc, (xsp + 86)
	ld xde, (xsp + 82)
	call InheritedProc
	ld xwa, (xsp + 82)
	ld xiy, xwa
	lda xix, (xsp + 70)
	lds bc, 6
	ldirw
	lda xwa, (xsp + 70)
	lda xbc, (xsp + 68)
	lda xde, (xsp + 66)
	call SndParam_DecodeMidiAddr
	ld16_24 xwa, 0x024796
	muls wa, 0x5
	ld (xsp + 8), wa
	ldw (xsp + 10), 0x0
	cp hl, 0xffff
	jrl z, PsMixer_UnmatchedPartScan

PsMixer_MidiScanOuterLoop:
	ld wa, (xsp + 8)
	calr Util_SignExtendAndDouble
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld wa, (xwa)
	sla wa, 2
	lda_24 xbc, 0xe95322
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld (xsp + 14), xwa
	ld16_24 xiz, 0x024794
	sla iz, 3
	ldw (xsp + 12), 0x0

; PsMixer array read handler
PsMixer_ArrayReadHandler:
	ld wa, iz
	calr PsMixer_ReadWordArrayEntry
	ldfr_werp HL, 0xfa
	ldto_werp DE, 0xfa
	exts xde
	ld xwa, (xsp + 14)
	ld xbc, 0x1e10000
	call ApFuncCall
	cp hl, (xsp + 68)
	jrl nz, AudioCtrl_MixerLoopNext
	ldto_werp DE, 0xfa
	exts xde
	ld xwa, (xsp + 14)
	ld xbc, 0x1e10001
	call ApFuncCall
	cp hl, (xsp + 66)
	jr nz, AudioCtrl_MixerDispatch
	ld de, (xsp + 74)
	exts xde
	ld xwa, (xsp + 14)
	ld xbc, 0x1e00083
	call ApFuncCall
	ld bc, (xsp + 8)
	extz xbc
	ld wa, iz
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 4)
	ld wa, (xwa + 2)
	sla wa, 2
	lda_24 xbc, 0xe9f11c
	st_dri3b C, 0x07, 0xe4, 0xe0
	ld xwa, (xsp + 90)
	ld xbc, 0x1c0000f
	ld xhl, (xhl)
	call (xhl)
	jr AudioCtrl_MixerLoopNext

; AudioCtrl mixer dispatch handler
AudioCtrl_MixerDispatch:
	ld de, (xsp + 66)
	extz xde
	ld xwa, (xsp + 4)
	ld wa, (xwa + 2)
	sla wa, 2
	lda_24 xbc, 0xe9f11c
	st_dri3b C, 0x07, 0xe4, 0xe0
	ld xwa, (xsp + 90)
	ld xbc, (xsp + 86)
	ld xix, (xhl)
	call (xix)
	or xhl, xhl
	jr z, AudioCtrl_MixerLoopNext
	ld bc, (xsp + 8)
	extz xbc
	ld wa, iz
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 4)
	ld wa, (xwa + 2)
	sla wa, 2
	lda_24 xbc, 0xe9f11c
	st_dri3b C, 0x07, 0xe4, 0xe0
	ld xwa, (xsp + 90)
	ld xbc, 0x1c0000f
	ld xhl, (xhl)
	call (xhl)

AudioCtrl_MixerLoopNext:
	inc 1, iz
	incm 1, (xsp + 12)
	cpw (xsp + 12), 0x8
	jrl c, PsMixer_ArrayReadHandler
	incm 1, (xsp + 8)
	incm 1, (xsp + 10)
	cpw (xsp + 10), 0x5
	jrl c, PsMixer_MidiScanOuterLoop
	jrl AudioCtrl_ReturnZero

PsMixer_UnmatchedPartScan:
	ld wa, (xsp + 8)
	calr Util_SignExtendAndDouble
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld wa, (xwa)
	sla wa, 2
	lda_24 xbc, 0xe95322
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld (xsp + 14), xwa
	ld16_24 xiz, 0x024794
	sla iz, 3
	ldw (xsp + 12), 0x0

; AudioCtrl array read handler
AudioCtrl_ArrayReadHandler:
	ld wa, iz
	calr PsMixer_ReadWordArrayEntry
	ldfr_werp HL, 0xfa
	ldto_werp DE, 0xfa
	exts xde
	ld xwa, (xsp + 14)
	ld xbc, 0x1e10001
	call ApFuncCall
	lda xwa, (xsp + 70)
	cp (xwa), xhl
	jr nz, AudioCtrl_DispatchCallback
	ld de, (xwa + 4)
	exts xde
	ld xwa, (xsp + 14)
	ld xbc, 0x1e00083
	call ApFuncCall
	ld bc, (xsp + 8)
	extz xbc
	ld wa, iz
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 4)
	ld wa, (xwa + 2)
	sla wa, 2
	lda_24 xbc, 0xe9f11c
	st_dri3b C, 0x07, 0xe4, 0xe0
	ld xwa, (xsp + 90)
	ld xbc, 0x1c0000f
	ld xhl, (xhl)
	call (xhl)
	jr PsMixer_ScanArrayNext

; AudioCtrl dispatch callback
AudioCtrl_DispatchCallback:
	ld xde, (xwa)
	ld xwa, (xsp + 4)
	ld wa, (xwa + 2)
	sla wa, 2
	lda_24 xbc, 0xe9f11c
	st_dri3b C, 0x07, 0xe4, 0xe0
	ld xwa, (xsp + 90)
	ld xbc, (xsp + 86)
	ld xix, (xhl)
	call (xix)
	or xhl, xhl
	jr z, PsMixer_ScanArrayNext
	ld bc, (xsp + 8)
	extz xbc
	ld wa, iz
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 4)
	ld wa, (xwa + 2)
	sla wa, 2
	lda_24 xbc, 0xe9f11c
	st_dri3b C, 0x07, 0xe4, 0xe0
	ld xwa, (xsp + 90)
	ld xbc, 0x1c0000f
	ld xhl, (xhl)
	call (xhl)

PsMixer_ScanArrayNext:
	inc 1, iz
	incm 1, (xsp + 12)
	cpw (xsp + 12), 0x8
	jrl c, AudioCtrl_ArrayReadHandler
	incm 1, (xsp + 8)
	incm 1, (xsp + 10)
	cpw (xsp + 10), 0x5
	jrl c, PsMixer_UnmatchedPartScan
	jrl AudioCtrl_ReturnZero

; PsMixer control case 9
PsMixer_ControlCase9:
	ld xwa, (xsp + 90)
	ld xbc, (xsp + 86)
	ld xde, (xsp + 82)
	call InheritedProc
	ld16_24 xwa, 0x024790
	calr PsMixer_ReadWordArrayEntry
	extz xhl
	add xhl, xhl
	ld xbc, 0xe953ce
	add xbc, xhl
	cpw (xbc), 0x10
	jrl ge, AudioCtrl_ReturnZero
	call GetPartSelect
	ld xwa, 0xe953ce
	ld bc, hl
	calr SdpartLookupPartId
	ldfr_werp HL, 0xfa
	cp_erpw 0xfa, 0xff, 0xff
	jrl z, AudioCtrl_ReturnZero
	ld16_24 xwa, 0x024790
	calr PsMixer_ReadWordArrayEntry
	ldto_werp WA, 0xfa
	cp wa, hl
	jr nz, PsMixer_VolSel_SearchGrid
	ld16_24 xiz, 0x024790
	jr PsMixer_VolumeSelect_Continue

PsMixer_VolSel_SearchGrid:
	ld16_24 xiz, 0x024794
	sla iz, 3
	ldw (xsp + 10), 0x0

PsMixer_VolSel_SearchLoop:
	ld wa, iz
	calr PsMixer_ReadWordArrayEntry
	ldto_werp WA, 0xfa
	cp wa, hl
	jr z, PsMixer_VolSel_CheckFound
	inc 1, iz
	incm 1, (xsp + 10)
	cpw (xsp + 10), 0x8
	jr c, PsMixer_VolSel_SearchLoop

PsMixer_VolSel_CheckFound:
	cpw (xsp + 10), 0x8
	jr nz, PsMixer_VolumeSelect_Continue
	lds iz, 0
	lds wa, 0
	calr PsMixer_ReadWordArrayEntry
	cp hl, 0xff
	jr z, PsMixer_VolumeSelect_Continue

PsMixer_VolSel_SearchFallback:
	ld wa, iz
	calr PsMixer_ReadWordArrayEntry
	ldto_werp WA, 0xfa
	cp wa, hl
	jr z, PsMixer_VolumeSelect_Continue
	inc 1, iz
	ld wa, iz
	calr PsMixer_ReadWordArrayEntry
	cp hl, 0xff
	jr nz, PsMixer_VolSel_SearchFallback

PsMixer_VolumeSelect_Continue:
	ld wa, iz
	calr PsMixer_ReadWordArrayEntry
	cp hl, 0xff
	jrl z, AudioCtrl_ReturnZero
	ld16_24 xwa, 0x024790
	cp wa, iz
	jrl z, AudioCtrl_ReturnZero
	st16_24 0x024790, xiz
	ld wa, iz
	exts xwa
	divs wa, 0x8
	st16_24 0x024794, xwa
	ldto_werp WA, 0xfa
	add wa, wa
	lda_24 xbc, 0xe953ce
	ld_sriw3 DE, 0x07, 0xe4, 0xe0
	exts xde
	ld xwa, 0x1400004
	ld xbc, 0x1e0005e
	call FuncCall
	ld16_24 xbc, 0x024792
	extz xbc
	ld16_24 xwa, 0x024790
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 90)
	ld xbc, 0x1c00017
	call SetDialUp
	ld16_24 xbc, 0x024792
	extz xbc
	ld16_24 xwa, 0x024790
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 90)
	ld xbc, 0x1c00018
	call SetDialDown
	lds wa, 1
	call SetDialEnable
	ld xwa, (xsp + 90)
	ld xbc, 0x1e000a7
	lds32 xde, 0

PsMixer_SendEventAndForward:
	call SendEvent
	jrl AudioCtrl_ReturnZero
	ld xwa, (xsp + 90)
	ld xbc, (xsp + 86)
	ld xde, (xsp + 82)
	call InheritedProc
	ld16_24 xwa, 0x024790
	calr PsMixer_ReadWordArrayEntry
	ldfr_werp HL, 0xfa
	ldto_werp WA, 0xfa
	add wa, wa
	lda_24 xbc, 0xe953ce
	ld_sriw3 BC, 0x07, 0xe4, 0xe0
	ld xwa, (xsp + 82)
	cp bc, (xwa)
	jr nz, PsMixer_EventFwd_Setup
	ld xwa, (xwa + 2)
	push xwa
	ldto_werp WA, 0xfa
	sla wa, 2
	lda_24 xbc, 0x03ea38
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	pushw 0xe9
	pushw 0xf580
	lda xwa, (xsp + 30)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 16)
	lda xde, (xsp + 18)
	ld xwa, (xsp + 90)
	ld xbc, 0x1c0000f
	call SendEvent

PsMixer_EventFwd_Setup:
	ld16_24 xwa, 0x024796
	muls wa, 0x5
	ld (xsp + 8), wa
	ldw (xsp + 10), 0x0

; PsMixer event forward helper
PsMixer_EventForwardHelper:
	ld wa, (xsp + 8)
	calr Util_SignExtendAndDouble
	ld (xsp + 4), xhl
	ld xde, (xsp + 4)
	ld wa, (xde)
	sla wa, 2
	lda_24 xbc, 0xe95322
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld (xsp + 14), xwa
	cp xwa, 0x1210027
	jr nz, PsMixer_EventFwd_Next
	ld wa, (xde + 2)
	sla wa, 2
	lda_24 xbc, 0xe9f11c
	st_dri3b C, 0x07, 0xe4, 0xe0
	ld xwa, (xsp + 90)
	ld xbc, (xsp + 86)
	ld xde, (xsp + 82)
	ld xhl, (xhl)
	call (xhl)
	jr AudioCtrl_ReturnZero

PsMixer_EventFwd_Next:
	incm 1, (xsp + 8)
	incm 1, (xsp + 10)
	cpw (xsp + 10), 0x5
	jr c, PsMixer_EventForwardHelper
	jr AudioCtrl_ReturnZero

; PsMixer control common handler
PsMixer_ControlCommon:
	pushw 0xe9
	pushw 0xf58e
	ld xwa, (xsp + 86)
	push xwa
	call Strcpy
	inc 8, xsp

AudioCtrl_ReturnZero:
	lds32 xhl, 0
	jr AudioCtrl_MixerEpilogue

; PsMixer control return
PsMixer_ControlReturn:
	ld xwa, (xsp + 90)
	ld xbc, (xsp + 86)
	ld xde, (xsp + 82)

AudioCtrl_ProcessParamsAndReturn:
	call InheritedProc

AudioCtrl_MixerEpilogue:
	pop xiz
	lda xsp, (xsp + 90)
	ret

AcPartMixerProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld xiz, xwa
	ld xwa, (xsp + 8)
	cp xwa, 0x1c00001
	jr z, PartMixer_Init
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	jr PartMixer_Epilogue

PartMixer_Init:
	ld xwa, 0xe9f5bc
	calr Util_StorePartArrayBase
	ld xwa, 0xe9f6c0
	calr Util_StoreGridArrayBase
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	lds32 xhl, 0

PartMixer_Epilogue:
	pop xiz
	inc 8, xsp
	ret

AcTrackMixerProc:
	lda xsp, (xsp - 52)
	pushw iz
	ld (xsp + 42), xde
	ld (xsp + 46), xbc
	ld (xsp + 50), xwa
	ld xiy, 0xe9f804
	lda xix, (xsp + 2)
	ldw bc, 0x14
	ldirw
	ld xwa, (xsp + 46)
	cp xwa, 0x1c0002d
	jr z, TrackMixer_UpdateHandler
	cp xwa, 0x1c0000c
	jr z, TrackMixer_ShowHide
	cp xwa, 0x1c0000b
	jr z, TrackMixer_ShowHide
	cp xwa, 0x1c00001
	jr z, TrackMixer_Init
	ld xwa, (xsp + 50)
	ld xbc, (xsp + 46)
	ld xde, (xsp + 42)
	call InheritedProc
	jrl TrackMixer_Epilogue

TrackMixer_Init:
	ld xwa, 0xe9f700
	calr Util_StorePartArrayBase
	ld xwa, 0x3ebe8
	calr Util_StoreGridArrayBase
	lds iz, 0

TrackMixer_InitPartLoop:
	ld de, iz
	exts xde
	ld xwa, 0x140000a
	ld xbc, 0x1e00092
	call MainFuncCall
	inc 1, iz
	cp iz, 0xf
	jr le, TrackMixer_InitPartLoop
	ld xwa, (xsp + 50)
	ld xbc, (xsp + 46)
	ld xde, (xsp + 42)
	jr TrackMixer_CallInherited

TrackMixer_ShowHide:
	ld xwa, (xsp + 50)
	ld xbc, (xsp + 46)
	ld xde, (xsp + 42)

TrackMixer_CallInherited:
	call InheritedProc
	jr TrackMixer_ReturnZero

TrackMixer_UpdateHandler:
	ld xwa, (xsp + 50)
	ld xbc, (xsp + 46)
	ld xde, (xsp + 42)
	call InheritedProc
	ld xwa, (xsp + 42)
	srl xwa, 0
	and xwa, 0xfff
	ld de, wa
	ld xwa, (xsp + 42)
	and xwa, 0xff
	extz xwa
	add xwa, xwa
	lda xbc, (xsp + 2)
	add xbc, xwa
	ld wa, de
	extz xwa
	add xwa, xwa
	ld xhl, 0x3ebe8
	add xhl, xwa
	ld wa, (xbc)
	ld (xhl), wa
	cp de, 0xf
	jr nz, TrackMixer_ReturnZero
	ld xwa, (xsp + 50)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call SendEvent

TrackMixer_ReturnZero:
	lds32 xhl, 0

TrackMixer_Epilogue:
	popw iz
	lda xsp, (xsp + 52)
	ret

AcResetPageProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld xiz, xwa
	ld xwa, (xsp + 8)
	cp xwa, 0x1c00001
	jr z, ResetPage_Init
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	jr ResetPage_Epilogue

ResetPage_Init:
	ld xwa, (xsp + 4)
	cp xwa, 0x3
	jr z, ResetPage_SendViewEvent
	or xwa, xwa
	jr nz, ResetPage_CallInherited

ResetPage_SendViewEvent:
	ld xwa, xiz
	ld xbc, 0x1e0007f
	lds32 xde, 1
	call SendEvent

ResetPage_CallInherited:
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	lds32 xhl, 0

ResetPage_Epilogue:
	pop xiz
	inc 8, xsp
	ret

Util_SignExtendAndDouble:
	exts xwa
	ld xhl, xwa
	add xhl, xhl
	add xhl, xwa
	sll xhl, 2
	addda32_24 xhl, 256560
	ret

Util_StorePartArrayBase:
	st32_24 0x03ea30, xwa
	ret

PsMixer_ReadWordArrayEntry:
	exts xwa
	add xwa, xwa
	addda32_24 xwa, 256564
	ld hl, (xwa)
	ret

Util_StoreGridArrayBase:
	st32_24 0x03ea34, xwa
	ret

AudioCtrl_DataBlock:
	lda	xsp, (xsp-22)
	push	xiz
	ld	(xsp+24), bc
	ld	xiz, xwa
	lda	xbc, (xsp+6)
	lda	xde, (xsp+4)
	ldw	wa, 52
	call	GetFrameSPSize
	ld	xiy, xiz
	lda	xix, (xsp+16)
	lds	bc, 4
	.byte 0x95
	scf
	lda	xwa, (xsp+16)
	ld	bc, (xsp+4)
	dec	2, bc
	add	(xwa+2), bc
	ldw	bc, 193
	ld	de, (xsp+24)
	call	DrawDesignBox
	lda	xde, (xsp+12)
	.byte 0xb2
	push_sr
	pushw	iy
	nop
	lda	xbc, (xsp+16)
	ld	wa, (xbc+2)
	inc	2, wa
	ld	(xde+2), wa
	lda	xde, (xsp+8)
	.byte 0xb2
	push_sr
	pushw	iy
	nop
	ld	wa, (xbc+6)
	dec	2, wa
	ld	(xde+2), wa
	lds	iz, 0
	lda	xwa, (xsp+12)
	lda	xbc, (xsp+8)
	ldw	de, 248
	call	DrawLine
	lda	xwa, (xsp+12)
	incm	1, (xwa)
	lda	xbc, (xsp+8)
	incm	1, (xbc)
	ldw	de, 255
	call	DrawLine
	.byte 0x9f
	incf
	push	xwa
	ldb	e, 0
	.byte 0x9f
	ldio	56, 37
	nop
	inc	1, iz
	cps	iz, 7
	jr	lt, -46
	pop	xiz
	lda	xsp, (xsp+22)
	ret
	lda	xsp, (xsp-14)
	push	xiz
	ld	(xsp+16), bc
	ld	xiz, xwa
	lda	xbc, (xsp+6)
	lda	xde, (xsp+4)
	ldw	wa, 52
	call	GetFrameSPSize
	ld	xiy, xiz
	lda	xix, (xsp+8)
	lds	bc, 4
	.byte 0x95
	scf
	lda	xwa, (xsp+8)
	ld	bc, (xsp+4)
	dec	2, bc
	add	(xwa+2), bc
	ldw	bc, 193
	ld	de, (xsp+16)
	call	DrawDesignBox
	pop	xiz
	lda	xsp, (xsp+14)
	ret
	lda	xsp, (xsp-22)
	push	xiz
	ld	(xsp+20), xde
	ld	(xsp+24), bc
	ld	xiz, xwa
	lda	xbc, (xsp+6)
	lda	xde, (xsp+4)
	ldw	wa, 52
	call	GetFrameSPSize
	lda	xwa, (xsp+8)
	ld	bc, (xiz)
	ld	(xwa), bc
	ld	bc, (xiz+2)
	ld	(xwa+2), bc
	.byte 0x9f
	push_f
	push	xsp
	nop
	nop
	jr	z, 8
	ldw	bc, 52
	ldw	de, 242
	jr	6
	ldw	bc, 52
	ldw	de, 8
	call	DrawFrameSP
	ld	xiy, xiz
	lda	xix, (xsp+12)
	lds	bc, 4
	.byte 0x95
	scf
	lda	xwa, (xsp+12)
	ld	bc, (xiz)
	.byte 0x9f, 0x06, 0x81
	ld	(xwa+4), bc
	ld	bc, (xiz+2)
	.byte 0x9f, 0x04, 0x81
	ld	(xwa+6), bc
	lda	xbc, (xsp+8)
	call	GetBoxCenter
	lda	xwa, (xsp+12)
	lda	xbc, (xsp+8)
	lds32	xde, 3
	push	xde
	pushw	255
	pushw	247
	ld	xde, (xsp+28)
	call	DrawStringCentered
	pop	xiz
	lda	xsp, (xsp+22)
	ret
	dec	8, xsp
	push	xiz
	ld	xiz, xwa
	ld	wa, bc
	exts	xwa
	divs	wa, 5
	.byte 0xd7, 0xe2, 0x88
	ld	(xsp+6), wa
	ld	wa, bc
	exts	xwa
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	sll	xbc, 2
	addda32_24	xbc, 256560
	ld	wa, (xbc+4)
	ld	(xsp+4), wa
	ldw	wa, 136
	.byte 0x9f, 0x06, 0x80
	lda	xbc, (xsp+8)
	call	GetEditSwPoint
	lda	xde, (xiz+2)
	lda	xbc, (xsp+10)
	ld	wa, (xbc)
	sub	wa, 9
	.byte 0x9f, 0x06, 0xa0
	ld	(xde), wa
	.byte 0xb6
	push_sr
	ldio	0, 190
	.byte 0x04
	push_sr
	.byte 0x37, 0x01
	lda	xhl, (xiz+6)
	ld	wa, (xbc)
	add	wa, 31
	.byte 0x9f, 0x06, 0xa0
	ld	(xhl), wa
	ld	wa, (xsp+4)
	add	(xde), wa
	add	(xhl), wa
	pop	xiz
	inc	8, xsp
	ret
	lda	xsp, (xsp-22)
	push	xiz
	ld	(xsp+20), de
	ld	(xsp+22), xbc
	ld	xiz, xwa
	lda	xbc, (xsp+6)
	lda	xde, (xsp+4)
	ldw	wa, 52
	call	GetFrameSPSize
	ld	xiy, xiz
	lda	xix, (xsp+12)
	lds	bc, 4
	.byte 0x95
	scf
	ld	wa, (xsp+4)
	dec	2, wa
	add	(xsp+14), wa
	ld	wa, (xsp+20)
	exts	xwa
	divs	wa, 8
	.byte 0xd7, 0xe2
	add	(xiz-34), w
	lda	xbc, (xsp+8)
	call	GetEditSwPoint
	lda	xwa, (xsp+12)
	ld	xbc, (xsp+22)
	call	GetBoxCenter
	ld	wa, iz
	add	wa, wa
	dec	8, wa
	ld	bc, (xsp+8)
	sub	bc, wa
	dec	2, bc
	ld	xwa, (xsp+22)
	ld	(xwa), bc
	pop	xiz
	lda	xsp, (xsp+22)
	ret
	lda	xsp, (xsp-18)
	push	xiz
	ld	(xsp+16), de
	ld	(xsp+18), xbc
	ld	xiz, xwa
	lda	xbc, (xsp+6)
	lda	xde, (xsp+4)
	ldw	wa, 52
	call	GetFrameSPSize
	ld	xiy, xiz
	lda	xix, (xsp+8)
	lds	bc, 4
	.byte 0x95
	scf
	lda	xde, (xsp+8)
	lda	xbc, (xde+2)
	ld	wa, (xsp+4)
	dec	2, wa
	add	(xbc), wa
	ld	wa, (xsp+16)
	exts	xwa
	divs	wa, 8
	.byte 0xd7
	ld32_24	xwa, 301707
	.byte 0x92
	xor	(xwa), xwa
	.byte 0x8c
	exts	xix
	divs	ix, 4
	ld	wa, hl
	exts	xwa
	divs	wa, 4
	add	wa, wa
	inc	1, wa
	muls	xwa, xix
	ld	ix, (xde)
	add	ix, wa
	inc	2, ix
	ld	xiy, (xsp+18)
	ld	(xiy), ix
	ld	bc, (xbc)
	ld	wa, (xde+6)
	sub	wa, bc
	exts	xwa
	divs	wa, 8
	ld	de, wa
	exts	xhl
	divs	hl, 4
	.byte 0xd7
	ld	xwa, xiz
	add	wa, wa
	inc	1, wa
	muls	xwa, xde
	add	bc, wa
	inc	2, bc
	ld	(xiy+2), bc
	pop	xiz
	lda	xsp, (xsp+18)
	ret
	lds32	xhl, 0
	ret
	lda	xsp, (xsp-28)
	push	xiz
	ld	(xsp+28), xbc
	ld	wa, de
	srl	xde, 0
	ld	(xsp+12), wa
	.byte 0xd7
	lds32	xde, 0
	ld	(xsp+14), de
	ld	xwa, (xsp+28)
	cp	xwa, 29360154
	jrl	z, 184
	cp	xwa, 29360152
	jrl	z, 175
	cp	xwa, 29360153
	jrl	z, 166
	cp	xwa, 29360151
	jrl	z, 157
	cp	xwa, 29360143
	jr	z, 43
	cp	xwa, 29360142
	jrl	z, 333
	cp	xwa, 29360141
	jrl	nz, 324
	lda	xwa, (xsp+20)
	ld	bc, (xsp+12)
	calr	65096
	lda	xwa, (xsp+20)
	.byte 0x98
	push_sr
	push	xwa
	ldwio	0, 45017
	calr	64762
	jrl	299
	ld	wa, (xsp+14)
	calr	64735
	ld	(xsp+4), hl
	lda	xwa, (xsp+20)
	ld	bc, (xsp+12)
	calr	65062
	lda	xwa, (xsp+20)
	.byte 0x98
	push_sr
	push	xwa
	ldwio	0, 4287
	ldw	bc, 3743
	ldb	b, 30
	cp	(xwa), h
	lda	xbc, (xsp+16)
	lda_24	xwa, 256688
	ld	de, (xsp+4)
	sla	de, 2
	.byte 0xe3
	reti
	.byte 0xe0, 0xe8
	ldb	b, 191
	push_a
	ldw	wa, 3743
	ldb	c, 210
	.byte 0x90
	ld	xsp, 292483842
	lds32	xhl, 3
	push	xhl
	pushw	255
	pushw	242
	pushw	0
	pushw	0
	jr	15
	lds32	xhl, 3
	push	xhl
	pushw	255
	pushw	8
	pushw	0
	pushw	0
	call	DrawStringReverse
	jrl	193
	ld	wa, (xsp+12)
	calr	64606
	ld	xiz, xhl
	ld	wa, (xsp+14)
	calr	64621
	ld	(xsp+4), hl
	ld	wa, (xiz)
	sla	wa, 2
	lda_24	xbc, 15291170
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 191
	incf
	jr	f, -97
	.byte 0x04
	ldb	b, 234
	zcf
	ld	xwa, (xsp+12)
	ld	xbc, 31457342
	call	ApFuncCall
	ld	(xsp+10), hl
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, 31457343
	call	ApFuncCall
	ld	xwa, (xsp+28)
	ld	bc, (xsp+10)
	ld	de, hl
	calr	48774
	ld	(xsp+10), hl
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, 31522816
	call	ApFuncCall
	ld	(xsp+6), hl
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, 31457345
	call	ApFuncCall
	ld	(xsp+8), hl
	ld	wa, (xsp+6)
	ld	de, (xsp+4)
	exts	xde
	cp	wa, 65535
	jr	z, 29
	ld	xwa, (xsp+12)
	ld	xbc, 31522817
	call	ApFuncCall
	.byte 0x9f
	ldio	4, 159
	ldio	32, 219
	.byte 0x89
	ld	de, (xsp+12)
	call	MainLswPartAdd
	jr	24
	ld	xwa, (xsp+12)
	ld	xbc, 31522817
	call	ApFuncCall
	ld	xwa, xhl
	ld	bc, (xsp+10)
	ld	de, (xsp+8)
	call	MainLswAdd
	lds32	xhl, 0
	pop	xiz
	lda	xsp, (xsp+28)
	ret
	lda	xsp, (xsp-28)
	push	xiz
	ld	(xsp+28), xbc
	ld	wa, de
	srl	xde, 0
	ld	(xsp+12), wa
	.byte 0xd7
	lds32	xde, 0
	ld	(xsp+14), de
	ld	xwa, (xsp+28)
	cp	xwa, 29360154
	jrl	z, 223
	cp	xwa, 29360152
	jrl	z, 214
	cp	xwa, 29360153
	jrl	z, 205
	cp	xwa, 29360151
	jrl	z, 196
	cp	xwa, 29360143
	jr	z, 41
	cp	xwa, 29360142
	jrl	z, 372
	cp	xwa, 29360141
	jrl	nz, 363
	lda	xwa, (xsp+20)
	ld	bc, (xsp+12)
	calr	64679
	lda	xwa, (xsp+20)
	incm	7, (xwa+2)
	lds	bc, 7
	calr	64347
	jrl	340
	ld	wa, (xsp+14)
	calr	64320
	ld	(xsp+4), hl
	lda	xwa, (xsp+20)
	ld	bc, (xsp+12)
	calr	64647
	lda	xwa, (xsp+20)
	incm	7, (xwa+2)
	lda	xbc, (xsp+16)
	ld	de, (xsp+14)
	calr	64739
	lda	xbc, (xsp+16)
	decm	6, (xbc+2)
	lda	xwa, (xsp+20)
	ld	de, (xsp+4)
	sla	de, 2
	lda_24	xhl, 256688
	.byte 0xe3
	reti
	.byte 0xec, 0xe8
	ldb	b, 235
	.byte 0xab
	push	xhl
	pushw	0
	pushw	247
	call	DrawStringCentered
	lda	xbc, (xsp+16)
	.byte 0x99
	push_sr
	push	xwa
	ldwio	0, 35058
	.byte 0xeb
	pop_sr
	ldw	wa, 3743
	ldb	b, 218
	.byte 0xec
	push_sr
	.byte 0xe3
	reti
	.byte 0xe0, 0xe8
	ldb	b, 191
	push_a
	ldw	wa, 3743
	ldb	c, 210
	.byte 0x90
	ld	xsp, 292483842
	lds32	xhl, 3
	push	xhl
	pushw	255
	pushw	242
	pushw	0
	pushw	0
	jr	15
	lds32	xhl, 3
	push	xhl
	pushw	255
	pushw	8
	pushw	0
	pushw	0
	call	DrawStringReverse
	jrl	193
	ld	wa, (xsp+12)
	calr	64150
	ld	xiz, xhl
	ld	wa, (xsp+14)
	calr	64165
	ld	(xsp+4), hl
	ld	wa, (xiz)
	sla	wa, 2
	lda_24	xbc, 15291170
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 191
	incf
	jr	f, -97
	.byte 0x04
	ldb	b, 234
	zcf
	ld	xwa, (xsp+12)
	ld	xbc, 31457342
	call	ApFuncCall
	ld	(xsp+10), hl
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, 31457343
	call	ApFuncCall
	ld	xwa, (xsp+28)
	ld	bc, (xsp+10)
	ld	de, hl
	calr	48318
	ld	(xsp+10), hl
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, 31522816
	call	ApFuncCall
	ld	(xsp+6), hl
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, 31457345
	call	ApFuncCall
	ld	(xsp+8), hl
	ld	wa, (xsp+6)
	ld	de, (xsp+4)
	exts	xde
	cp	wa, 65535
	jr	z, 29
	ld	xwa, (xsp+12)
	ld	xbc, 31522817
	call	ApFuncCall
	.byte 0x9f
	ldio	4, 159
	ldio	32, 219
	.byte 0x89
	ld	de, (xsp+12)
	call	MainLswPartAdd
	jr	24
	ld	xwa, (xsp+12)
	ld	xbc, 31522817
	call	ApFuncCall
	ld	xwa, xhl
	ld	bc, (xsp+10)
	ld	de, (xsp+8)
	call	MainLswAdd
	lds32	xhl, 0
	pop	xiz
	lda	xsp, (xsp+28)
	ret
	lda	xsp, (xsp-76)
	pushw	iz
	ld	(xsp+70), xde
	ld	(xsp+74), xbc
	ld	xwa, (xsp+70)
	ld	(xsp+10), wa
	ld	xwa, (xsp+70)
	srl	xwa, 0
	.byte 0xd7
	subdm32_24	9033896, xsp
	popw	de
	ldb	w, 232
	set	0, l
	.byte 0xc0, 0x01
	jrl	z, 724
	ld	(xsp+12), bc
	cp	xwa, 29360154
	jrl	z, 503
	cp	xwa, 29360152
	jrl	z, 494
	cp	xwa, 29360153
	jrl	z, 485
	cp	xwa, 29360151
	jrl	z, 476
	cp	xwa, 29360143
	jr	z, 99
	cp	xwa, 29360142
	jr	z, 49
	cp	xwa, 29360141
	jrl	nz, 856
	lda	xwa, (xsp+62)
	ld	bc, (xsp+10)
	calr	64206
	lda	xwa, (xsp+62)
	lds	bc, 7
	calr	63877
	ld	wa, (xsp+10)
	exts	xwa
	divs	wa, 5
	.byte 0xd7
	addm32_24	13162632, xwa
	nop
	call	DrawEditSw
	jrl	816
	ld	wa, (xsp+10)
	calr	63807
	ld	(xsp+6), xhl
	lda	xwa, (xsp+62)
	ld	bc, (xsp+10)
	calr	64157
	lda	xwa, (xsp+62)
	ld	xbc, (xsp+70)
	srl	xbc, 0
	.byte 0xd7, 0xe6, 0xa8
	ld	xde, (xsp+6)
	ld	xde, (xde+8)
	calr	64010
	jrl	774
	ld	wa, (xsp+10)
	calr	63765
	ld	(xsp+6), xhl
	ld	wa, (xsp+12)
	calr	63779
	ld	(xsp+4), hl
	ld	xwa, (xsp+6)
	ld	wa, (xwa)
	sla	wa, 2
	lda_24	xbc, 15291170
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 191
	.byte 0x06
	jr	f, -65
	push	xiz
	ldw	wa, 2719
	ldb	a, 30
	.byte 0x55
	swi	2
	lda	xwa, (xsp+62)
	lda	xbc, (xsp+58)
	ld	de, (xsp+12)
	calr	64180
	.byte 0x9f
	push	xix
	push	xde
	push	0
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+6)
	ld	xbc, 31522816
	call	ApFuncCall
	ld	(xsp+2), hl
	ld	wa, (xsp+2)
	ld	de, (xsp+4)
	exts	xde
	cp	wa, 65535
	jr	z, 28
	ld	xwa, (xsp+6)
	ld	xbc, 31522817
	call	ApFuncCall
	ld	iz, hl
	ld	wa, (xsp+2)
	ld	bc, iz
	call	SndParam_LookupViaEncode
	ld	(xsp+50), hl
	jr	21
	ld	xwa, (xsp+6)
	ld	xbc, 31522817
	call	ApFuncCall
	ld	xwa, xhl
	call	SndParam_LookupReadOnly
	ld	(xsp+50), hl
	ld	bc, iz
	extz	xbc
	ld	wa, (xsp+4)
	.byte 0xe8
	.long Pad_AfterNaka_DrawbarOrgan_Screens
	add	xwa, xbc
	lda	xde, (xsp+46)
	ld	(xde), xwa
	lda	xwa, (xsp+14)
	ld	(xde+8), xwa
	ld	xwa, (xsp+6)
	ld	xbc, 31457346
	call	ApFuncCall
	lda	xwa, (xsp+62)
	lda	xde, (xsp+14)
	lda	xbc, (xsp+58)
	ld	hl, (xsp+10)
	.byte 0xd2, 0x92
	ld	xsp, 460256002
	ld	hl, (xsp+12)
	.byte 0xd2, 0x90
	ld	xsp, 292483842
	lds32	xhl, 3
	push	xhl
	pushw	0
	pushw	7
	pushw	0
	pushw	1
	jr	15
	lds32	xhl, 3
	push	xhl
	pushw	0
	pushw	7
	pushw	0
	pushw	0
	call	DrawStringReverse
	lda	xwa, (xsp+62)
	lda	xbc, (xsp+58)
	ld	de, (xsp+12)
	calr	63978
	lda	xwa, (xsp+58)
	decm	8, (xwa)
	decm	3, (xwa+2)
	lds32	xbc, 4
	call	DrawBitmap
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+6)
	ld	xbc, 31522818
	call	ApFuncCall
	lda_24	xbc, 15333420
	or	xhl, xhl
	jr	z, 41
	lda	xhl, (xsp+58)
	lda	xde, (xsp+50)
	ld	wa, (xde)
	sra	wa, 3
	sla	wa, 2
	.byte 0xd3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 147
	ld	w, (xwa-110)
	sra	wa, 3
	sla	wa, 2
	exts	xwa
	add	xwa, xbc
	ld	wa, (xwa+2)
	add	(xhl+2), wa
	jr	14
	lda	xde, (xsp+58)
	ld	wa, (xbc+32)
	add	(xde), wa
	ld	wa, (xbc+34)
	add	(xde+2), wa
	lda	xwa, (xsp+58)
	lds32	xbc, 5
	call	DrawBitmap
	jrl	405
	ld	wa, (xsp+10)
	calr	63396
	ld	(xsp+6), xhl
	ld	wa, (xsp+12)
	calr	63410
	ld	(xsp+4), hl
	ld	xwa, (xsp+6)
	ld	wa, (xwa)
	sla	wa, 2
	lda_24	xbc, 15291170
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 191
	.byte 0x06
	jr	f, -97
	.byte 0x04
	ldb	b, 234
	zcf
	ld	xwa, (xsp+6)
	ld	xbc, 31457342
	call	ApFuncCall
	ld	(xsp+12), hl
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+6)
	ld	xbc, 31457343
	call	ApFuncCall
	ld	xwa, (xsp+74)
	ld	bc, (xsp+12)
	ld	de, hl
	calr	47560
	ld	(xsp+12), hl
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+6)
	ld	xbc, 31522816
	call	ApFuncCall
	ld	(xsp+2), hl
	ld	wa, (xsp+12)
	ld	(xsp+10), wa
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+6)
	ld	xbc, 31457345
	call	ApFuncCall
	ld	(xsp+12), hl
	ld	wa, (xsp+2)
	ld	de, (xsp+4)
	exts	xde
	cp	wa, 65535
	jr	z, 32
	ld	xwa, (xsp+6)
	ld	xbc, 31522817
	call	ApFuncCall
	ld	iz, hl
	.byte 0x9f
	incf
	.byte 0x04
	ld	wa, (xsp+4)
	ld	bc, iz
	ld	de, (xsp+12)
	call	MainLswPartAdd
	jrl	223
	ld	xwa, (xsp+6)
	ld	xbc, 31522817
	call	ApFuncCall
	ld	xwa, xhl
	ld	bc, (xsp+10)
	ld	de, (xsp+12)
	call	MainLswAdd
	jrl	196
	ld	iz, bc
	ld	wa, (xsp+10)
	calr	63185
	ld	(xsp+6), xhl
	ld	wa, iz
	calr	63200
	ld	(xsp+4), hl
	ld	xwa, (xsp+6)
	ld	wa, (xwa)
	sla	wa, 2
	lda_24	xbc, 15291170
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 191
	.byte 0x06
	jr	f, -97
	.byte 0x04
	ldb	b, 234
	zcf
	ld	xwa, (xsp+6)
	ld	xbc, 31457464
	call	ApFuncCall
	or	xhl, xhl
	jrl	z, 134
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+6)
	ld	xbc, 31522816
	call	ApFuncCall
	ld	(xsp+2), hl
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+6)
	ld	xbc, 31457345
	call	ApFuncCall
	ld	(xsp+12), hl
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+6)
	ld	xbc, 31457465
	call	ApFuncCall
	ld	(xsp+10), hl
	ld	wa, (xsp+2)
	cp	wa, 65535
	jr	z, 36
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+6)
	ld	xbc, 31522817
	call	ApFuncCall
	ld	iz, hl
	.byte 0x9f
	incf
	.byte 0x04
	ld	wa, (xsp+4)
	ld	bc, iz
	ld	de, (xsp+12)
	call	MainLswPartPut
	jr	29
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+6)
	ld	xbc, 31522817
	call	ApFuncCall
	ld	xwa, xhl
	ld	bc, (xsp+10)
	ld	de, (xsp+12)
	call	MainLswPut
	lds32	xhl, 0
	popw	iz
	lda	xsp, (xsp+76)
	ret
	lda	xsp, (xsp-76)
	push	xiz
	ld	(xsp+72), xde
	ld	(xsp+76), xbc
	ld	xwa, (xsp+72)
	.byte 0xaf
	popw	wa
	.long OscScope_RenderBlock
	ld	(xsp+12), wa
	.byte 0xd7, 0xe6, 0xa8
	ld	(xsp+14), bc
	ld	xwa, (xsp+76)
	cp	xwa, 29360177
	jrl	z, 589
	cp	xwa, 29360154
	jrl	z, 379
	cp	xwa, 29360152
	jrl	z, 370
	cp	xwa, 29360153
	jrl	z, 361
	cp	xwa, 29360151
	jrl	z, 352
	cp	xwa, 29360143
	jr	z, 95
	cp	xwa, 29360142
	jr	z, 49
	cp	xwa, 29360141
	jrl	nz, 714
	lda	xwa, (xsp+64)
	ld	bc, (xsp+12)
	calr	63242
	lda	xwa, (xsp+64)
	lds	bc, 7
	calr	62913
	ld	wa, (xsp+12)
	exts	xwa
	divs	wa, 5
	.byte 0xd7
	addm32_24	13162632, xwa
	nop
	call	DrawEditSw
	jrl	674
	ld	wa, (xsp+12)
	calr	62843
	ld	xiz, xhl
	lda	xwa, (xsp+64)
	ld	bc, (xsp+12)
	calr	63194
	lda	xwa, (xsp+64)
	ld	xbc, (xsp+72)
	srl	xbc, 0
	.byte 0xd7, 0xe6, 0xa8
	ld	xde, (xiz+8)
	calr	63050
	jrl	636
	ld	wa, (xsp+12)
	calr	62805
	ld	xiz, xhl
	ld	wa, (xsp+14)
	calr	62820
	ld	(xsp+6), hl
	ld	wa, (xiz)
	sla	wa, 2
	lda_24	xbc, 15291170
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 191
	ldio	96, 191
	ld	xwa, 554475312
	calr	63129
	lda	xwa, (xsp+64)
	lda	xbc, (xsp+60)
	ld	de, (xsp+14)
	calr	63224
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+8)
	ld	xbc, 31522816
	call	ApFuncCall
	ld	(xsp+4), hl
	ld	wa, (xsp+4)
	cp	wa, 65535
	jr	z, 33
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+8)
	ld	xbc, 31522817
	call	ApFuncCall
	ld	iz, hl
	ld	wa, (xsp+4)
	ld	bc, iz
	call	SndParam_LookupViaEncode
	ld	(xsp+52), hl
	jr	26
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+8)
	ld	xbc, 31522817
	call	ApFuncCall
	ld	xwa, xhl
	call	SndParam_LookupReadOnly
	ld	(xsp+52), hl
	ld	bc, iz
	extz	xbc
	ld	wa, (xsp+6)
	extz	xwa
	sll	xwa, 0
	add	xwa, xbc
	lda	xde, (xsp+48)
	ld	(xde), xwa
	lda	xwa, (xsp+16)
	ld	(xde+8), xwa
	ld	xwa, (xsp+8)
	ld	xbc, 31457346
	call	ApFuncCall
	lda	xwa, (xsp+64)
	lda	xbc, (xsp+60)
	lda	xde, (xsp+16)
	ld	hl, (xsp+12)
	.byte 0xd2, 0x92
	ld	xsp, 460256002
	ld	hl, (xsp+14)
	.byte 0xd2, 0x90
	ld	xsp, 292483842
	lds32	xhl, 3
	push	xhl
	pushw	0
	pushw	7
	pushw	0
	pushw	1
	jr	15
	lds32	xhl, 3
	push	xhl
	pushw	0
	pushw	7
	pushw	0
	pushw	0
	call	DrawStringReverse
	jrl	387
	ld	wa, (xsp+12)
	calr	62556
	ld	xiz, xhl
	ld	wa, (xsp+14)
	calr	62571
	ld	(xsp+6), hl
	ld	wa, (xiz)
	sla	wa, 2
	lda_24	xbc, 15291170
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 191
	ldio	96, 159
	.byte 0x06
	ldb	b, 234
	zcf
	ld	xwa, (xsp+8)
	ld	xbc, 31457342
	call	ApFuncCall
	ld	(xsp+14), hl
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+8)
	ld	xbc, 31457343
	call	ApFuncCall
	ld	xwa, (xsp+76)
	ld	bc, (xsp+14)
	ld	de, hl
	calr	46724
	ld	iz, hl
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+8)
	ld	xbc, 31522816
	call	ApFuncCall
	ld	(xsp+4), hl
	ld	(xsp+12), iz
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+8)
	ld	xbc, 31457345
	call	ApFuncCall
	ld	(xsp+14), hl
	ld	wa, (xsp+4)
	ld	de, (xsp+6)
	exts	xde
	cp	wa, 65535
	jr	z, 32
	ld	xwa, (xsp+8)
	ld	xbc, 31522817
	call	ApFuncCall
	ld	iz, hl
	.byte 0x9f
	ret
	.byte 0x04
	ld	wa, (xsp+6)
	ld	bc, iz
	ld	de, (xsp+14)
	call	MainLswPartAdd
	jrl	213
	ld	xwa, (xsp+8)
	ld	xbc, 31522817
	call	ApFuncCall
	ld	xwa, xhl
	ld	bc, (xsp+12)
	ld	de, (xsp+14)
	call	MainLswAdd
	jrl	186
	ld	wa, (xsp+12)
	calr	62355
	ld	xiz, xhl
	ld	wa, (xsp+14)
	calr	62370
	ld	(xsp+6), hl
	ld	wa, (xiz)
	sla	wa, 2
	lda_24	xbc, 15291170
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 191
	ldio	96, 159
	.byte 0x06
	ldb	b, 234
	zcf
	ld	xwa, (xsp+8)
	ld	xbc, 31457464
	call	ApFuncCall
	or	xhl, xhl
	jrl	z, 129
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+8)
	ld	xbc, 31522816
	call	ApFuncCall
	ld	(xsp+4), hl
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+8)
	ld	xbc, 31457345
	call	ApFuncCall
	ld	(xsp+14), hl
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+8)
	ld	xbc, 31457465
	call	ApFuncCall
	ld	(xsp+12), hl
	ld	wa, (xsp+4)
	ld	de, (xsp+6)
	exts	xde
	cp	wa, 65535
	jr	z, 31
	ld	xwa, (xsp+8)
	ld	xbc, 31522817
	call	ApFuncCall
	ld	iz, hl
	.byte 0x9f
	ret
	.byte 0x04
	ld	wa, (xsp+6)
	ld	bc, iz
	ld	de, (xsp+14)
	call	MainLswPartPut
	jr	24
	ld	xwa, (xsp+8)
	ld	xbc, 31522817
	call	ApFuncCall
	ld	xwa, xhl
	ld	bc, (xsp+12)
	ld	de, (xsp+14)
	call	MainLswPut
	lds32	xhl, 0
	pop	xiz
	lda	xsp, (xsp+76)
	ret
	lda	xsp, (xsp-78)
	push	xiz
	ld	(xsp+74), xde
	ld	(xsp+78), xbc
	ld	xwa, (xsp+74)
	ld	xbc, (xsp+74)
	srl	xbc, 0
	ld	(xsp+10), wa
	.byte 0xd7, 0xe6, 0xa8
	ld	(xsp+12), bc
	ld	xwa, (xsp+78)
	cp	xwa, 29360154
	jrl	z, 444
	cp	xwa, 29360152
	jrl	z, 435
	cp	xwa, 29360153
	jrl	z, 426
	cp	xwa, 29360151
	jrl	z, 417
	cp	xwa, 29360143
	jr	z, 95
	cp	xwa, 29360142
	jr	z, 49
	cp	xwa, 29360141
	jrl	nz, 584
	lda	xwa, (xsp+66)
	ld	bc, (xsp+10)
	calr	62429
	lda	xwa, (xsp+66)
	lds	bc, 7
	calr	62100
	ld	wa, (xsp+10)
	exts	xwa
	divs	wa, 5
	.byte 0xd7
	addm32_24	13162632, xwa
	nop
	call	DrawEditSw
	jrl	544
	ld	wa, (xsp+10)
	calr	62030
	ld	xiz, xhl
	lda	xwa, (xsp+66)
	ld	bc, (xsp+10)
	calr	62381
	lda	xwa, (xsp+66)
	ld	xbc, (xsp+74)
	srl	xbc, 0
	.byte 0xd7, 0xe6, 0xa8
	ld	xde, (xiz+8)
	calr	62237
	jrl	506
	ld	wa, (xsp+10)
	calr	61992
	ld	xiz, xhl
	ld	wa, (xsp+12)
	calr	62007
	ld	(xsp+4), hl
	ld	wa, (xiz)
	sla	wa, 2
	lda_24	xbc, 15291170
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 191
	.byte 0x06
	jr	f, -65
	ld	xde, 554344240
	calr	62316
	lda	xwa, (xsp+66)
	lda	xbc, (xsp+62)
	ld	de, (xsp+12)
	calr	62411
	lda	xiy, (xsp+62)
	lda	xix, (xsp+58)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	.byte 0x9f
	ld	xwa, 3204450618
	push	xde
	ldw	wa, 28560
	decm	1, (xwa+2)
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+6)
	ld	xbc, 31522816
	call	ApFuncCall
	ld	iz, hl
	ld	wa, iz
	ld	de, (xsp+4)
	exts	xde
	cp	wa, 65535
	jr	z, 29
	ld	xwa, (xsp+6)
	ld	xbc, 31522817
	call	ApFuncCall
	.byte 0xd7
	swi	2
	add	(xhl-34), wa
	.byte 0xd7
	swi	2
	.byte 0x89
	call	SndParam_LookupViaEncode
	ld	(xsp+50), hl
	jr	21
	ld	xwa, (xsp+6)
	ld	xbc, 31522817
	call	ApFuncCall
	ld	xwa, xhl
	call	SndParam_LookupReadOnly
	ld	(xsp+50), hl
	.byte 0xd7
	swi	2
	.byte 0x89
	extz	xbc
	ld	wa, (xsp+4)
	extz	xwa
	sll	xwa, 0
	add	xwa, xbc
	lda	xde, (xsp+46)
	ld	(xde), xwa
	lda	xwa, (xsp+14)
	ld	(xde+8), xwa
	ld	xwa, (xsp+6)
	ld	xbc, 31457346
	call	ApFuncCall
	lda	xwa, (xsp+66)
	lda	xbc, (xsp+62)
	lda	xde, (xsp+14)
	ld	hl, (xsp+10)
	.byte 0xd2, 0x92
	ld	xsp, 460256002
	ld	hl, (xsp+12)
	.byte 0xd2, 0x90
	ld	xsp, 292483842
	lds32	xhl, 3
	push	xhl
	pushw	0
	pushw	7
	pushw	0
	pushw	1
	jr	15
	lds32	xhl, 3
	push	xhl
	pushw	0
	pushw	7
	pushw	0
	pushw	0
	call	DrawStringReverse
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+6)
	ld	xbc, 31522818
	call	ApFuncCall
	lda	xwa, (xsp+58)
	or	xhl, xhl
	jr	z, 7
	.byte 0x9f
	ldw	de, 63
	nop
	jr	nz, 7
	ld	xbc, 30
	jr	5
	ld	xbc, 29
	call	DrawBitmap
	jrl	192
	ld	wa, (xsp+10)
	calr	61678
	ld	xiz, xhl
	ld	wa, (xsp+12)
	calr	61693
	ld	(xsp+4), hl
	ld	wa, (xiz)
	sla	wa, 2
	lda_24	xbc, 15291170
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 191
	.byte 0x06
	jr	f, -97
	.byte 0x04
	ldb	b, 234
	zcf
	ld	xwa, (xsp+6)
	ld	xbc, 31457342
	call	ApFuncCall
	ld	iz, hl
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+6)
	ld	xbc, 31457343
	call	ApFuncCall
	ld	xwa, (xsp+78)
	ld	bc, iz
	ld	de, hl
	calr	45848
	ld	(xsp+12), hl
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+6)
	ld	xbc, 31522816
	call	ApFuncCall
	ld	iz, hl
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+6)
	ld	xbc, 31457345
	call	ApFuncCall
	ld	(xsp+10), hl
	ld	wa, iz
	ld	de, (xsp+4)
	exts	xde
	cp	wa, 65535
	jr	z, 32
	ld	xwa, (xsp+6)
	ld	xbc, 31522817
	call	ApFuncCall
	.byte 0xd7
	swi	2
	.byte 0x9b, 0x9f
	ldwio	4, 35038
	.byte 0xd7
	swi	2
	.byte 0x89
	ld	de, (xsp+14)
	call	MainLswPartAdd
	jr	24
	ld	xwa, (xsp+6)
	ld	xbc, 31522817
	call	ApFuncCall
	ld	xwa, xhl
	ld	bc, (xsp+12)
	ld	de, (xsp+10)
	call	MainLswAdd
	lds32	xhl, 0
	pop	xiz
	lda	xsp, (xsp+78)
	ret
	lda	xsp, (xsp-76)
	push	xiz
	ld	(xsp+72), xde
	ld	(xsp+76), xbc
	ld	xwa, (xsp+72)
	ld	xbc, (xsp+72)
	srl	xbc, 0
	ld	(xsp+12), wa
	.byte 0xd7, 0xe6, 0xa8
	ld	(xsp+14), bc
	ld	xwa, (xsp+76)
	cp	xwa, 29360154
	jrl	z, 471
	cp	xwa, 29360152
	jrl	z, 462
	cp	xwa, 29360153
	jrl	z, 453
	cp	xwa, 29360151
	jrl	z, 444
	cp	xwa, 29360143
	jr	z, 100
	cp	xwa, 29360142
	jr	z, 54
	cp	xwa, 29360141
	jrl	nz, 611
	lda	xwa, (xsp+64)
	ld	bc, (xsp+12)
	calr	61746
	lda	xwa, (xsp+64)
	.byte 0x98, 0x06
	push	xwa
	ldb	w, 0
	lds	bc, 7
	calr	61412
	ld	wa, (xsp+12)
	exts	xwa
	divs	wa, 5
	.byte 0xd7
	addm32_24	13162632, xwa
	nop
	call	DrawEditSw
	jrl	566
	ld	wa, (xsp+12)
	calr	61342
	ld	xiz, xhl
	lda	xwa, (xsp+64)
	ld	bc, (xsp+12)
	calr	61693
	lda	xwa, (xsp+64)
	ld	xbc, (xsp+72)
	srl	xbc, 0
	.byte 0xd7, 0xe6, 0xa8
	ld	xde, (xiz+8)
	calr	61549
	jrl	528
	ld	wa, (xsp+12)
	calr	61304
	ld	xiz, xhl
	ld	wa, (xsp+14)
	calr	61319
	ld	(xsp+6), hl
	ld	wa, (xiz)
	sla	wa, 2
	lda_24	xbc, 15291170
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 191
	ldio	96, 191
	ld	xwa, 554475312
	calr	61628
	lda	xwa, (xsp+64)
	lda	xbc, (xsp+60)
	ld	de, (xsp+14)
	calr	61723
	.byte 0x9f
	push	xiz
	push	xde
	push	0
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+8)
	ld	xbc, 31522818
	call	ApFuncCall
	or	xhl, xhl
	jr	z, 78
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+8)
	ld	xbc, 31522816
	call	ApFuncCall
	ld	iz, hl
	ld	wa, iz
	ld	de, (xsp+6)
	exts	xde
	cp	wa, 65535
	jr	z, 26
	ld	xwa, (xsp+8)
	ld	xbc, 31522817
	call	ApFuncCall
	ld	(xsp+4), hl
	ld	wa, iz
	ld	bc, (xsp+4)
	call	SndParam_LookupViaEncode
	jr	22
	ld	xwa, (xsp+8)
	ld	xbc, 31522817
	call	ApFuncCall
	ld	xwa, xhl
	call	SndParam_LookupReadOnly
	jr	2
	lds	hl, 0
	ld	(xsp+52), hl
	ld	bc, (xsp+4)
	extz	xbc
	ld	wa, (xsp+6)
	extz	xwa
	sll	xwa, 0
	add	xwa, xbc
	lda	xde, (xsp+48)
	ld	(xde), xwa
	lda	xwa, (xsp+16)
	ld	(xde+8), xwa
	ld	xwa, (xsp+8)
	ld	xbc, 31457346
	call	ApFuncCall
	lda	xde, (xsp+16)
	lda	xwa, (xsp+64)
	lda	xbc, (xsp+60)
	ld	hl, (xsp+12)
	.byte 0xd2, 0x92
	ld	xsp, 460256002
	ld	hl, (xsp+14)
	.byte 0xd2, 0x90
	ld	xsp, 292483842
	lds32	xhl, 3
	push	xhl
	pushw	0
	pushw	7
	pushw	0
	pushw	1
	jr	15
	lds32	xhl, 3
	push	xhl
	pushw	0
	pushw	7
	pushw	0
	pushw	0
	call	DrawStringReverse
	lda	xwa, (xsp+64)
	.byte 0x98, 0x06
	push	xwa
	ldb	w, 0
	lda	xbc, (xsp+60)
	ld	de, (xsp+14)
	calr	61494
	lda	xwa, (xsp+60)
	.byte 0x90
	push	xde
	incf
	nop
	.byte 0x98
	push_sr
	push	xde
	zcf
	nop
	lds32	xbc, 2
	call	DrawBitmap
	ldw	wa, 128
	.byte 0x9f
	ldw	ix, 55456
	push	36
	nop
	exts	xwa
	divs	wa, 128
	ld	bc, wa
	lda	xwa, (xsp+60)
	add	(xwa+2), bc
	lds32	xbc, 3
	call	DrawBitmap
	jrl	192
	ld	wa, (xsp+12)
	calr	60968
	ld	xiz, xhl
	ld	wa, (xsp+14)
	calr	60983
	ld	(xsp+6), hl
	ld	wa, (xiz)
	sla	wa, 2
	lda_24	xbc, 15291170
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 191
	ldio	96, 159
	.byte 0x06
	ldb	b, 234
	zcf
	ld	xwa, (xsp+8)
	ld	xbc, 31457342
	call	ApFuncCall
	ld	iz, hl
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+8)
	ld	xbc, 31457343
	call	ApFuncCall
	ld	xwa, (xsp+76)
	ld	bc, iz
	ld	de, hl
	calr	45138
	ld	(xsp+14), hl
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+8)
	ld	xbc, 31522816
	call	ApFuncCall
	ld	iz, hl
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+8)
	ld	xbc, 31457345
	call	ApFuncCall
	ld	(xsp+12), hl
	ld	wa, iz
	ld	de, (xsp+6)
	exts	xde
	cp	wa, 65535
	jr	z, 32
	ld	xwa, (xsp+8)
	ld	xbc, 31522817
	call	ApFuncCall
	ld	(xsp+4), hl
	.byte 0x9f
	incf
	.byte 0x04
	ld	wa, iz
	ld	bc, (xsp+6)
	ld	de, (xsp+16)
	call	MainLswPartAdd
	jr	24
	ld	xwa, (xsp+8)
	ld	xbc, 31522817
	call	ApFuncCall
	ld	xwa, xhl
	ld	bc, (xsp+14)
	ld	de, (xsp+12)
	call	MainLswAdd
	lds32	xhl, 0
	pop	xiz
	lda	xsp, (xsp+76)
	ret
	lda	xsp, (xsp-34)
	push	xiz
	ld	(xsp+30), xde
	ld	(xsp+34), xbc
	ld	xde, (xsp+34)
	cp	xde, 29360156
	jrl	z, 824
	.byte 0xaf, 0x1e
	.long OscScope_RenderBlock
	.byte 0xd7, 0xe6
	and	(xwa-22), xsp
	ldw	bc, 49152
	.byte 0x01
	jrl	z, 675
	cp	xde, 29360154
	jrl	z, 286
	cp	xde, 29360152
	jrl	z, 277
	cp	xde, 29360153
	jrl	z, 268
	cp	xde, 29360151
	jrl	z, 259
	cp	xde, 29360143
	jrl	nz, 793
	ld	xbc, (xsp+34)
	ld	xde, (xsp+30)
	calr	64732
	ld	xwa, (xsp+30)
	ld	(xsp+8), wa
	ld	xwa, (xsp+30)
	srl	xwa, 0
	.byte 0xd7, 0xe2, 0xa8
	ld	(xsp+10), wa
	ld	wa, (xsp+10)
	calr	60680
	ld	(xsp+6), hl
	ld32_24	xwa, 15291302
	ld	(xsp+12), xwa
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, 31522818
	call	ApFuncCall
	or	xhl, xhl
	jrl	z, 179
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, 31522816
	call	ApFuncCall
	ld	(xsp+4), hl
	ld	wa, (xsp+4)
	cp	wa, 65535
	jr	z, 35
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, 31522817
	call	ApFuncCall
	ld	(xsp+14), hl
	ld	wa, (xsp+4)
	ld	bc, (xsp+14)
	call	SndParam_LookupViaEncode
	ld	(xsp+16), hl
	jr	28
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, 31522817
	call	ApFuncCall
	ld	xiz, xhl
	ld	xwa, xiz
	call	SndParam_LookupReadOnly
	ld	(xsp+16), hl
	.byte 0x9f
	rcf
	push	xsp
	nop
	nop
	jr	z, 80
	lda	xwa, (xsp+22)
	ld	bc, (xsp+8)
	calr	60878
	lda	xwa, (xsp+22)
	lda	xbc, (xsp+18)
	ld	de, (xsp+10)
	calr	60973
	lda	xbc, (xsp+18)
	incm	1, (xbc)
	.byte 0x99
	push_sr
	push	xwa
	ccf
	nop
	lda	xwa, (xsp+22)
	ld	de, (xbc)
	sub	de, 12
	ld	(xwa), de
	ld	de, (xbc)
	add	de, 12
	ld	(xwa+4), de
	.byte 0x98, 0x06
	push	xwa
	ccf
	nop
	lds32	xde, 3
	push	xde
	pushw	251
	pushw	0
	pushw	0
	pushw	1
	ld	xde, 15333484
	call	DrawStringReverse
	lds32	xhl, 0
	jrl	552
	ld	xwa, (xsp+30)
	ld	(xsp+8), wa
	ld	wa, bc
	calr	60452
	ld	(xsp+6), hl
	ld32_24	xwa, 15291302
	ld	(xsp+12), xwa
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, 31522816
	call	ApFuncCall
	ld	(xsp+4), hl
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, 31457345
	call	ApFuncCall
	ld	(xsp+10), hl
	ld	wa, (xsp+4)
	cp	wa, 65535
	jr	z, 57
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, 31522817
	call	ApFuncCall
	ld	(xsp+14), hl
	ld	wa, (xsp+4)
	ld	bc, (xsp+14)
	call	SndParam_LookupViaEncode
	ld	(xsp+16), hl
	.byte 0x9f
	rcf
	push	xsp
	nop
	nop
	jr	z, 63
	.byte 0x9f
	ldwio	4, 1695
	ldb	w, 159
	rcf
	ldb	a, 218
	xor	(xwa+29), xiy
	swi	0
	swi	1
	jr	46
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, 31522817
	call	ApFuncCall
	ld	xiz, xhl
	ld	xwa, xiz
	call	SndParam_LookupReadOnly
	ld	(xsp+16), hl
	.byte 0x9f
	rcf
	push	xsp
	nop
	nop
	jr	z, 11
	ld	xwa, xiz
	lds	bc, 0
	ld	de, (xsp+10)
	call	MainLswPut
	.byte 0x9f
	rcf
	push	xsp
	nop
	nop
	jrl	nz, -187
	ld	wa, (xsp+8)
	calr	60252
	ld	wa, (xhl)
	sla	wa, 2
	lda_24	xbc, 15291170
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 191
	incf
	jr	f, -97
	.byte 0x06
	ldb	b, 234
	zcf
	ld	xwa, (xsp+12)
	ld	xbc, 31457342
	call	ApFuncCall
	ld	(xsp+16), hl
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, 31457343
	call	ApFuncCall
	ld	xwa, (xsp+34)
	ld	bc, (xsp+16)
	ld	de, hl
	calr	44431
	ld	(xsp+16), hl
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, 31522816
	call	ApFuncCall
	ld	(xsp+4), hl
	ld	wa, (xsp+16)
	ld	(xsp+8), wa
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, 31457345
	call	ApFuncCall
	ld	(xsp+10), hl
	ld	wa, (xsp+4)
	ld	de, (xsp+6)
	exts	xde
	cp	wa, 65535
	jr	z, 34
	ld	xwa, (xsp+12)
	ld	xbc, 31522817
	call	ApFuncCall
	ld	(xsp+14), hl
	.byte 0x9f
	ldwio	4, 1695
	ldb	w, 159
	rcf
	ldb	a, 159
	ldwio	34, 38173
	swi	1
	swi	1
	jrl	-356
	ld	xwa, (xsp+12)
	ld	xbc, 31522817
	call	ApFuncCall
	ld	xiz, xhl
	ld	xwa, xiz
	ld	bc, (xsp+16)
	ld	de, (xsp+10)
	call	MainLswAdd
	jrl	-385
	ld	wa, bc
	calr	60078
	ld	(xsp+6), hl
	ld32_24	xwa, 15291302
	ld	(xsp+12), xwa
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, 31522816
	call	ApFuncCall
	ld	(xsp+4), hl
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, 31457345
	call	ApFuncCall
	ld	(xsp+10), hl
	ld	wa, (xsp+4)
	ld	de, (xsp+6)
	exts	xde
	cp	wa, 65535
	jr	z, 33
	ld	xwa, (xsp+12)
	ld	xbc, 31522817
	call	ApFuncCall
	ld	(xsp+14), hl
	.byte 0x9f
	ldwio	4, 1695
	ldb	w, 159
	rcf
	ldb	a, 218
	xor	(xbc+29), xiy
	swi	0
	swi	1
	jrl	-488
	ld	xwa, (xsp+12)
	ld	xbc, 31522817
	call	ApFuncCall
	ld	xiz, xhl
	ld	xwa, xiz
	lds	bc, 1
	ld	de, (xsp+10)
	call	MainLswPut
	jrl	-516
	ld	xwa, (xsp+30)
	cp	xwa, 8
	jr	z, 17
	cp	xwa, 165899
	jr	z, 9
	cp	xwa, 59400
	jrl	nz, -544
	lds32	xhl, 1
	jr	9
	ld	xbc, (xsp+34)
	ld	xde, (xsp+30)
	calr	63939
	pop	xiz
	lda	xsp, (xsp+34)
	ret
	lda	xsp, (xsp-94)
	push	xiz
	ld	(xsp+90), xde
	ld	(xsp+94), xbc
	ld	xwa, (xsp+90)
	ld	xbc, (xsp+90)
	srl	xbc, 0
	ld	(xsp+18), wa
	.byte 0xd7, 0xe6, 0xa8
	ld	(xsp+20), bc
	ld	xwa, (xsp+94)
	cp	xwa, 29360154
	jrl	z, 670
	cp	xwa, 29360152
	jrl	z, 661
	cp	xwa, 29360153
	jrl	z, 652
	cp	xwa, 29360151
	jrl	z, 643
	cp	xwa, 29360160
	jrl	z, 354
	cp	xwa, 29360143
	jrl	z, 305
	cp	xwa, 29360142
	jrl	z, 253
	cp	xwa, 29360141
	jrl	nz, 738
	lda	xwa, (xsp+82)
	ld	bc, (xsp+18)
	calr	60133
	lda	xwa, (xsp+82)
	.byte 0x98
	push_sr
	push	xde
	ex_ff
	nop
	lds	bc, 7
	calr	59937
	ld	wa, (xsp+18)
	exts	xwa
	divs	wa, 5
	.byte 0xd7
	addm32_24	13162632, xwa
	nop
	call	DrawEditSw
	lda	xbc, (xsp+68)
	.byte 0xbf
	.asciz "B204"
	call	GetFrameSPSize
	lda	xhl, (xsp+82)
	ld	wa, (xhl+4)
	.byte 0x93
	or	(xwa), xwa
	zcf
	divs	wa, 2
	ld	bc, (xhl)
	add	bc, wa
	lda	xwa, (xsp+74)
	ld	(xwa), bc
	ld	bc, (xsp+66)
	dec	2, bc
	.byte 0x9b
	push_sr
	xor	(xbc), a
	jr	le, -72
	push_sr
	.byte 0x51
	lda	xbc, (xsp+70)
	ld	de, (xwa)
	ld	(xbc), de
	ld	de, (xhl+6)
	dec	2, de
	ld	(xbc+2), de
	ldw	de, 248
	call	DrawLine
	lda	xwa, (xsp+74)
	incm	1, (xwa)
	lda	xbc, (xsp+70)
	incm	1, (xbc)
	ldw	de, 255
	call	DrawLine
	ld16_24	wa, 149396
	ld	(xsp+12), wa
	sla	wa, 3
	ld	(xsp+12), wa
	.byte 0xbf
	ccf
	push_sr
	nop
	nop
	lda	xwa, (xsp+82)
	lda	xbc, (xsp+78)
	ld	de, (xsp+12)
	calr	60184
	.byte 0x9f
	popw	iz
	push	xde
	ldw	ix, 40704
	incf
	ldb	w, 30
	.byte 0xef, 0xe8
	ld	(xsp+8), hl
	sla	hl, 2
	lda_24	xwa, 256568
	.byte 0xe3
	reti
	.byte 0xe0, 0xec
	ldb	w, 56
	pushw	233
	pushw	63602
	lda	xwa, (xsp+30)
	push	xwa
	call	Audio_SendCommand
	lda	xsp, (xsp+12)
	lda	xwa, (xsp+82)
	lda	xbc, (xsp+78)
	lda	xde, (xsp+22)
	lds32	xhl, 3
	push	xhl
	pushw	0
	pushw	247
	call	DrawStringCentered
	incm	1, (xsp+12)
	incm	1, (xsp+18)
	.byte 0x9f
	ccf
	push	xsp
	ldio	0, 97
	.byte 0xa4
	jrl	494
	ld	wa, (xsp+18)
	calr	59530
	ld	xiz, xhl
	lda	xwa, (xsp+82)
	ld	bc, (xsp+18)
	calr	59881
	lda	xwa, (xsp+82)
	.byte 0x98
	push_sr
	push	xde
	ex_ff
	nop
	ld	xbc, (xsp+90)
	srl	xbc, 0
	.byte 0xd7, 0xe6, 0xa8
	ld	xde, (xiz+8)
	calr	59732
	jrl	451
	ld	wa, (xsp+20)
	calr	59510
	ld	(xsp+8), hl
	add	hl, hl
	lda_24	xwa, 15291342
	.byte 0xd3
	reti
	.byte 0xe0, 0xec
	ldb	b, 234
	zcf
	ld	xwa, 20971524
	ld	xbc, 31457374
	call	FuncCall
	jrl	411
	ld	xwa, (xsp+90)
	ld	(xsp+4), xwa
	ld16_24	wa, 149398
	muls	wa, 5
	ld	(xsp+10), wa
	.byte 0xbf
	ccf
	push_sr
	nop
	nop
	ld	wa, (xsp+10)
	calr	59424
	ld	xiz, xhl
	ld	wa, (xiz)
	sla	wa, 2
	lda_24	xbc, 15291170
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 191
	ret
	jr	f, -24
	.byte 0xcf
	ldb	l, 0
	ldb	a, 1
	jrl	nz, 205
	ld16_24	wa, 149396
	ld	(xsp+12), wa
	sla	wa, 3
	ld	(xsp+12), wa
	.byte 0xbf
	push_a
	push_sr
	nop
	nop
	ld	wa, (xsp+12)
	calr	59393
	ld	(xsp+8), hl
	ld	xwa, (xsp+4)
	ld	bc, (xwa)
	ld	xwa, 15291342
	calr	43567
	.byte 0x9f
	ldio	243, 126
	.byte 0x90
	nop
	lda	xwa, (xsp+82)
	ld	bc, (xsp+10)
	calr	59701
	lda	xwa, (xsp+82)
	.byte 0x98
	push_sr
	push	xde
	ex_ff
	nop
	lda	xbc, (xsp+78)
	ld	de, (xsp+12)
	calr	59887
	.byte 0x9f
	popw	iz
	push	xwa
	push_a
	nop
	lda	xwa, (xsp+54)
	ld	bc, (xsp+8)
	extz	xbc
	sll	xbc, 0
	ld	(xwa), xbc
	lda	xbc, (xsp+22)
	ld	(xwa+8), xbc
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+2)
	push	xwa
	push	xbc
	call	Strcpy
	inc	8, xsp
	lda	xde, (xsp+54)
	ld	xwa, (xsp+14)
	ld	xbc, 31457346
	call	ApFuncCall
	lda	xbc, (xsp+78)
	lda	xwa, (xsp+82)
	lda	xde, (xsp+22)
	ld	hl, (xsp+10)
	.byte 0xd2, 0x92
	ld	xsp, 460256002
	ld	hl, (xsp+12)
	.byte 0xd2, 0x90
	ld	xsp, 292483842
	lds32	xhl, 3
	push	xhl
	pushw	0
	pushw	7
	pushw	0
	pushw	1
	jr	15
	lds32	xhl, 3
	push	xhl
	pushw	0
	pushw	7
	pushw	0
	pushw	0
	call	DrawStringReverse
	incm	1, (xsp+12)
	incm	1, (xsp+20)
	.byte 0x9f
	push_a
	push	xsp
	ldio	0, 113
	ld	xiz, 1628086271
	incm	1, (xsp+18)
	.byte 0x9f
	ccf
	push	xsp
	halt
	nop
	jrl	lt, -254
	jrl	131
	ld	wa, (xsp+18)
	calr	59167
	ld	xiz, xhl
	ld	wa, (xsp+20)
	calr	59182
	ld	(xsp+8), hl
	ld	wa, (xiz)
	sla	wa, 2
	lda_24	xbc, 15291170
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 191
	ret
	jr	f, -97
	ldio	34, 234
	zcf
	ld	xwa, (xsp+14)
	ld	xbc, 31457342
	call	ApFuncCall
	ld	(xsp+20), hl
	ld	de, (xsp+8)
	exts	xde
	ld	xwa, (xsp+14)
	ld	xbc, 31457343
	call	ApFuncCall
	ld	xwa, (xsp+94)
	ld	bc, (xsp+20)
	ld	de, hl
	calr	43335
	ld	(xsp+20), hl
	ld	de, (xsp+8)
	exts	xde
	ld	xwa, (xsp+14)
	ld	xbc, 31522816
	call	ApFuncCall
	extz	xhl
	ld	wa, (xsp+20)
	extz	xwa
	sll	xwa, 0
	ld	xde, xwa
	add	xde, xhl
	ld	xwa, 20971524
	ld	xbc, 31457449
	call	MainFuncCall
	lds32	xhl, 0
	pop	xiz
	lda	xsp, (xsp+94)
	ret
	lda	xsp, (xsp-56)
	push	xiz
	cp	xbc, 29360141
	jr	z, 6
	calr	64673
	jrl	226
	ld	iz, de
	lda	xwa, (xsp+52)
	ld	bc, iz
	calr	59369
	lda	xwa, (xsp+52)
	.byte 0x98
	push_sr
	push	xde
	ex_ff
	nop
	lds	bc, 7
	calr	59173
	ld	wa, iz
	exts	xwa
	divs	wa, 5
	.byte 0xd7
	addm32_24	13162632, xwa
	nop
	call	DrawEditSw
	lda	xbc, (xsp+38)
	lda	xde, (xsp+36)
	ldw	wa, 52
	call	GetFrameSPSize
	lda	xhl, (xsp+52)
	ld	wa, (xhl+4)
	.byte 0x93
	or	(xwa), xwa
	zcf
	divs	wa, 2
	ld	bc, (xhl)
	add	bc, wa
	lda	xwa, (xsp+44)
	ld	(xwa), bc
	ld	bc, (xsp+36)
	dec	2, bc
	.byte 0x9b
	push_sr
	xor	(xbc), a
	jr	le, -72
	push_sr
	.byte 0x51
	lda	xbc, (xsp+40)
	ld	de, (xwa)
	ld	(xbc), de
	ld	de, (xhl+6)
	dec	2, de
	ld	(xbc+2), de
	ldw	de, 248
	call	DrawLine
	lda	xwa, (xsp+44)
	incm	1, (xwa)
	lda	xbc, (xsp+40)
	incm	1, (xbc)
	ldw	de, 255
	call	DrawLine
	ld16_24	iz, 149396
	sla	iz, 3
	.byte 0xd7
	swi	2
	.byte 0xa8
	lda	xwa, (xsp+52)
	lda	xbc, (xsp+48)
	ld	de, iz
	calr	59430
	.byte 0x9f
	ldw	wa, 13370
	nop
	ld	wa, iz
	sla	wa, 2
	lda_24	xbc, 256808
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 56
	pushw	233
	pushw	63606
	lda	xwa, (xsp+12)
	push	xwa
	call	Audio_SendCommand
	lda	xsp, (xsp+12)
	lda	xwa, (xsp+52)
	lda	xbc, (xsp+48)
	lda	xde, (xsp+4)
	lds32	xhl, 3
	push	xhl
	pushw	0
	pushw	247
	call	DrawStringCentered
	inc	1, iz
	.byte 0xd7
	swi	2
	jr	lt, -41
	swi	2
	mul	l, 0
	jr	lt, -83
	lds32	xhl, 0
	pop	xiz
	lda	xsp, (xsp+56)
	ret
	lda	xsp, (xsp-18)
	pushw	iz
	ld	(xsp+16), xbc
	ld	xbc, (xsp+16)
	cp	xbc, 29360156
	jrl	z, 379
	cp	xbc, 29360154
	jr	z, 33
	cp	xbc, 29360152
	jr	z, 25
	cp	xbc, 29360153
	jr	z, 17
	cp	xbc, 29360151
	jr	z, 9
	ld	xbc, (xsp+16)
	calr	61275
	jrl	356
	ld	wa, de
	srl	xde, 0
	.byte 0xd7
	lds32	xde, 0
	ld	iz, de
	calr	58713
	ld	(xsp+12), xhl
	ld	wa, iz
	calr	58728
	ld	(xsp+8), hl
	ld	xwa, (xsp+12)
	ld	wa, (xwa)
	sla	wa, 2
	lda_24	xbc, 15291170
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 191
	ldwio	96, 2207
	ldb	b, 234
	zcf
	ld	xwa, (xsp+10)
	ld	xbc, 31457342
	call	ApFuncCall
	ld	(xsp+14), hl
	ld	de, (xsp+8)
	exts	xde
	ld	xwa, (xsp+10)
	ld	xbc, 31457343
	call	ApFuncCall
	ld	xwa, (xsp+16)
	ld	bc, (xsp+14)
	ld	de, hl
	calr	42878
	ld	(xsp+14), hl
	ld	de, (xsp+8)
	exts	xde
	ld	xwa, (xsp+10)
	ld	xbc, 31522816
	call	ApFuncCall
	ld	(xsp+2), hl
	ld	wa, (xsp+14)
	ld	(xsp+4), wa
	ld	de, (xsp+8)
	exts	xde
	ld	xwa, (xsp+10)
	ld	xbc, 31457345
	call	ApFuncCall
	ld	(xsp+6), hl
	ld	de, (xsp+8)
	exts	xde
	ld	xwa, (xsp+10)
	ld	xbc, 31522817
	call	ApFuncCall
	ld	(xsp+12), hl
	ld	wa, (xsp+2)
	cp	wa, 65535
	jrl	z, 144
	.byte 0x9f
	ret
	push	xsp
	nop
	nop
	jrl	z, 140
	ld	xwa, (xsp+16)
	cp	xwa, 29360154
	jr	z, 81
	cp	xwa, 29360152
	jr	z, 73
	cp	xwa, 29360153
	jr	z, 8
	cp	xwa, 29360151
	jr	nz, 105
	ld	wa, (xsp+2)
	ldw	bc, 1026
	call	SndParam_LookupViaEncode
	cps	hl, 0
	jr	nz, 91
	.byte 0x9f
	ei	4
	ld	wa, (xsp+4)
	ldw	bc, 1026
	lds	de, 1
	call	MainLswPartPut
	.byte 0x9f
	ei	4
	ld	wa, (xsp+4)
	ldw	bc, 1027
	lds	de, 1
	call	MainLswPartPut
	.byte 0x9f
	ei	4
	ld	wa, (xsp+4)
	ld	bc, (xsp+14)
	lds	de, 0
	jr	40
	ld	wa, (xsp+2)
	ldw	bc, 1025
	call	SndParam_LookupViaEncode
	cps	hl, 0
	jr	nz, 34
	.byte 0x9f
	ei	4
	ld	wa, (xsp+4)
	ldw	bc, 1026
	lds	de, 0
	call	MainLswPartPut
	.byte 0x9f
	ei	4
	ld	wa, (xsp+4)
	ldw	bc, 1027
	lds	de, 0
	call	MainLswPartPut
	lds32	xhl, 0
	jr	36
	.byte 0x9f
	ei	4
	ld	wa, (xsp+4)
	ld	bc, (xsp+14)
	ld	de, (xsp+6)
	call	MainLswPartAdd
	jr	-22
	cp	xde, 1026
	jr	z, 8
	cp	xde, 1027
	jr	nz, -38
	lds32	xhl, 1
	popw	iz
	lda	xsp, (xsp+18)
	ret
	ret
	ret
	ret
	ret

IvDrawbarProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1e0003a
	jrl z, IvDrawbar_GetText
	cp xiz, 0x1c0002f
	jrl z, IvDrawbar_Refresh
	cp xiz, 0x1c0001c
	jrl z, IvDrawbar_Match
	cp xiz, 0x1c00023
	jrl z, IvDrawbar_Update
	cp xiz, 0x1c0001b
	jrl z, IvDrawbar_Release
	cp xiz, 0x1c00007
	jrl z, IvDrawbar_OK
	cp xiz, 0x1e000a7
	jrl z, IvDrawbar_DrawbarUpdate
	cp xiz, 0x1e10008
	jrl z, IvDrawbar_LoadVals
	cp xiz, 0x1c0000d
	jrl z, IvDrawbar_Paint
	cp xiz, 0x1c0000c
	jrl z, IvDrawbar_ShowHide
	cp xiz, 0x1c0000b
	jrl z, IvDrawbar_ShowHide
	cp xiz, 0x1c00002
	jrl z, IvDrawbar_Close
	cp xiz, 0x1c00001
	jrl nz, IvDrawbar_ForwardToBase
	ld xwa, (xsp + 4)
	cp xwa, 0x3
	jr z, IvDrawbar_Init_Part03
	or xwa, xwa
	jr nz, IvDrawbar_Init_SetupMode

IvDrawbar_Init_Part03:
	sti16_24 0x024798, 0x0000
	call GetPartSelect
	st16_24 0x02479a, xhl
	sti16_24 0x03e99e, 0x0000
	call GetModeNow
	cp xhl, 0x1800003
	jr z, IvDrawbar_Init_CheckDualMode
	ld xwa, (xsp + 8)
	ld xbc, 0x1e10008
	lds32 xde, 0
	jr IvDrawbar_Init_DispatchLoadVals

IvDrawbar_Init_CheckDualMode:
	ld8_24 a, 0x0205f2
	bit 0, a
	jr z, IvDrawbar_Init_SetupMode
	res 0, a
	st8_24 0x0205f2, a
	ld xwa, (xsp + 8)
	ld xbc, 0x1e10008
	lds32 xde, 0

IvDrawbar_Init_DispatchLoadVals:
	call SendEvent

IvDrawbar_Init_SetupMode:
	call GetModeNow
	cp xhl, 0x1800003
	jrl z, IvDrawbar_Init_ModernMode
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 1
	call SendEvent
	ld xwa, 0xea0026
	ld xbc, 0x1c00002
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld16_24 xde, 0x024798
	inc 1, de
	exts xde
	ld xwa, 0xffffffff
	ld xbc, 0x1c00035
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call SendEvent
	ld xwa, 0xea001e
	ld xbc, 0x1c00001
	lds32 xde, 0
	call SendEvent
	call GetModeNow
	cp xhl, 0x1800001
	jrl nz, IvDrawbar_ReturnHandled
	ld xwa, 0xffffffff
	ld xbc, 0x1e000b3
	lds32 xde, 1
	jrl IvDrawbar_DispatchEvent

IvDrawbar_Init_ModernMode:
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 1
	call SendEvent
	ld xwa, 0xea001e
	ld xbc, 0x1c00002
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld16_24 xde, 0x024798
	inc 1, de
	exts xde
	ld xwa, 0xffffffff
	ld xbc, 0x1c00035
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call SendEvent
	ld xwa, 0xea0026
	ld xbc, 0x1c00001
	lds32 xde, 0
	jrl IvDrawbar_DispatchEvent

IvDrawbar_Close:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	jrl IvDrawbar_CallBase

IvDrawbar_ShowHide:
	call GetPartSelect
	st16_24 0x02479a, xhl
	ld wa, hl
	calr SndParam_ResolveOscEntry
	ld xde, xhl
	ld xwa, (xsp + 8)
	ld xbc, 0x1c00023
	call SendEvent
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 8)
	ld xbc, 0x1e000a7
	lds32 xde, 1
	call SendEvent
	ld xwa, (xsp + 8)
	ld xbc, 0x1e000a7
	lds32 xde, 2
	call SendEvent
	ld xwa, (xsp + 8)
	ld xbc, 0x1e000a7
	lds32 xde, 3
	jrl IvDrawbar_DispatchEvent

IvDrawbar_Paint:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 8)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jrl IvDrawbar_DispatchEvent

IvDrawbar_LoadVals:
	call GetModeNow
	cp xhl, 0x1800003
	jr z, IvDrawbar_LoadVals_DualMode
	ld16_24 xwa, 0x02479a
	ldw bc, 0x2c1
	call SndParam_LookupViaEncode
	st16_24 0x0247c2, xhl
	ld16_24 xwa, 0x02479a
	ldw bc, 0x2c0
	call SndParam_LookupViaEncode
	st16_24 0x0247c4, xhl
	jrl IvDrawbar_ReturnHandled

IvDrawbar_LoadVals_DualMode:
	ld xwa, 0x1410001
	ld xbc, 0x1e10009
	lds32 xde, 0
	jrl IvDrawbar_Release_SendParam

IvDrawbar_DrawbarUpdate:
	ld xwa, (xsp + 4)
	cp xwa, 0x3
	jr z, IvDrawbar_DrawbarUpdate_Lower
	cp xwa, 0x2
	jrl nz, IvDrawbar_ReturnHandled
	cpdi16_24 149442, 0
	jr z, IvDrawbar_DrawbarUpdate_UpperOff
	ld xwa, 0xea0003
	ld xbc, 0x1e0003b
	lds32 xde, 1
	call SendEvent
	ld xwa, 0xea0004
	ld xbc, 0x1c0000d
	lds32 xde, 0
	jrl IvDrawbar_DispatchEvent

IvDrawbar_DrawbarUpdate_UpperOff:
	ld xwa, 0xea0003
	ld xbc, 0x1e0003b
	lds32 xde, 0
	call SendEvent
	ld xwa, 0xea0005
	ld xbc, 0x1c0000d
	lds32 xde, 0
	jrl IvDrawbar_DispatchEvent

IvDrawbar_DrawbarUpdate_Lower:
	ld16_24 xde, 0x0247c4
	exts xde
	ld xwa, 0xea0002
	ld xbc, 0x1e0003b
	jrl IvDrawbar_DispatchEvent

IvDrawbar_OK:
	ld xwa, (xsp + 4)
	cp xwa, 0xf
	jr nz, IvDrawbar_OK_Forward
	cpdi16_24 149400, 0
	jr nz, IvDrawbar_OK_PageChange
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e0007a
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr nz, IvDrawbar_OK_Locked
	ld xwa, 0xffffffff
	ld xbc, 0x1c00014
	ld xde, 0x1800002
	jr IvDrawbar_OK_Dispatch

IvDrawbar_OK_Locked:
	ld xwa, 0xffffffff
	ld xbc, 0x1e00079
	lds32 xde, 0

IvDrawbar_OK_Dispatch:
	call SendEvent
	jrl IvDrawbar_ReturnHandled

IvDrawbar_OK_PageChange:
	sti16_24 0x024798, 0x0000
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001e
	lds32 xde, 1
	call SendEvent
	ld xwa, (xsp + 8)
	ld xbc, 0x1e000a7
	lds32 xde, 1
	jrl IvDrawbar_Update_Dispatch

IvDrawbar_OK_Forward:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	jrl IvDrawbar_ForwardCallBase

IvDrawbar_Release:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 4)
	cp xwa, 0x3
	jr z, IvDrawbar_Release_Lower
	cp xwa, 0x2
	jr z, IvDrawbar_Release_Upper
	cp xwa, 0x1
	jrl nz, IvDrawbar_ReturnHandled
	cpdi16_24 149400, 0
	scc16 z, wa
	st16_24 0x024798, xwa
	inc 1, wa
	ld de, wa
	exts xde
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001e
	call SendEvent
	ld xwa, (xsp + 8)
	ld xbc, 0x1e000a7
	lds32 xde, 1
	call PostEvent
	jrl IvDrawbar_ReturnHandled

IvDrawbar_Release_Upper:
	call GetModeNow
	cp xhl, 0x1800003
	jr z, IvDrawbar_Release_Upper_DualMode
	ld16_24 xwa, 0x02479a
	pushw 0x4
	ldw bc, 0x2c1
	lds de, 1
	jr IvDrawbar_Release_WriteValue

IvDrawbar_Release_Upper_DualMode:
	cpdi16_24 149442, 0
	scc16 z, de
	extz xde
	add xde, 0x90000
	ld xwa, 0x1410001
	ld xbc, 0x1e1000a
	jr IvDrawbar_Release_SendParam

IvDrawbar_Release_Lower:
	call GetModeNow
	cp xhl, 0x1800003
	jr z, IvDrawbar_Release_Lower_DualMode
	ld16_24 xwa, 0x02479a
	pushw 0x4
	ldw bc, 0x2c0
	lds de, 1

IvDrawbar_Release_WriteValue:
	call MainLswPartPut
	jrl IvDrawbar_ReturnHandled

IvDrawbar_Release_Lower_DualMode:
	cpdi16_24 149444, 0
	scc16 z, de
	extz xde
	add xde, 0xa0000
	ld xwa, 0x1410001
	ld xbc, 0x1e1000a

IvDrawbar_Release_SendParam:
	call MainFuncCall
	jrl IvDrawbar_ReturnHandled

IvDrawbar_Update:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	call GetModeNow
	cp xhl, 0x1800003
	jrl z, IvDrawbar_ReturnHandled
	ld xwa, (xsp + 4)
	ld16_24 xbc, 0x02479a
	cp bc, wa
	jrl nz, IvDrawbar_ReturnHandled
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldi_werp 0xe2, 0
	ld bc, wa
	srl bc, 8
	ldb b, 0x0
	cp c, 0xc
	jr nz, IvDrawbar_Update_GenericParam
	extz wa
	st16_24 0x02479c, xwa
	jrl IvDrawbar_ReturnHandled

IvDrawbar_Update_GenericParam:
	ld xwa, 0xffffffff
	ld xbc, 0x1e00079
	lds32 xde, 0

IvDrawbar_Update_Dispatch:
	call PostEvent
	jrl IvDrawbar_ReturnHandled

IvDrawbar_Match:
	ld xhl, (xsp + 4)
	ld16_24 xbc, 0x02479a
	ld de, bc
	exts xde
	sll xde, 10
	ld xix, xde
	add xix, 0x8000
	ld xwa, (xsp + 4)
	cp xix, (xwa)
	jr z, IvDrawbar_Match_Drawbar
	ld xix, xde
	add xix, 0x8020
	cp xix, (xwa)
	jr nz, IvDrawbar_Match_CheckUpper

IvDrawbar_Match_Drawbar:
	ld wa, bc
	calr SndParam_ResolveOscEntry
	ld xde, xhl
	ld xwa, (xsp + 8)
	ld xbc, 0x1c00023
	jr IvDrawbar_Match_DispatchEvent

IvDrawbar_Match_CheckUpper:
	ld xix, xde
	add xix, 0x82c1
	ld bc, (xhl + 4)
	ld xwa, (xsp + 4)
	cp xix, (xwa)
	jr nz, IvDrawbar_Match_CheckLower
	st16_24 0x0247c2, xbc
	ld xwa, (xsp + 8)
	ld xbc, 0x1e000a7
	lds32 xde, 2
	jr IvDrawbar_Match_DispatchEvent

IvDrawbar_Match_CheckLower:
	add xde, 0x82c0
	cp xde, (xhl)
	jr nz, IvDrawbar_Match_Forward
	st16_24 0x0247c4, xbc
	ld xwa, (xsp + 8)
	ld xbc, 0x1e000a7
	lds32 xde, 3

IvDrawbar_Match_DispatchEvent:
	call SendEvent

IvDrawbar_Match_Forward:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)

IvDrawbar_CallBase:
	call InheritedProc
	jr IvDrawbar_ReturnHandled

IvDrawbar_Refresh:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	call GetPartSelect
	st16_24 0x02479a, xhl
	ld wa, hl
	calr SndParam_ResolveOscEntry
	ld xde, xhl
	ld xwa, (xsp + 8)
	ld xbc, 0x1c00023
	call SendEvent
	ld xwa, (xsp + 8)
	ld xbc, 0x1e10008
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 8)
	ld xbc, 0x1e000a7
	lds32 xde, 2
	call SendEvent
	ld xwa, (xsp + 8)
	ld xbc, 0x1e000a7
	lds32 xde, 3

IvDrawbar_DispatchEvent:
	call SendEvent
	jr IvDrawbar_ReturnHandled

IvDrawbar_GetText:
	pushw 0xe9
	pushw 0xf92a
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp

IvDrawbar_ReturnHandled:
	lds32 xhl, 0
	jr IvDrawbar_Return

IvDrawbar_ForwardToBase:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)

IvDrawbar_ForwardCallBase:
	call InheritedProc

IvDrawbar_Return:
	pop xiz
	inc 8, xsp
	ret

AcDrawSettingProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld (xsp + 12), xbc
	ld xiz, xwa
	ld xwa, (xsp + 12)
	cp xwa, 0x1e00050
	jr z, DrawCombo_CompareMatch
	cp xwa, 0x1e00051
	jr z, DrawCombo_GetWidgetValue
	cp xwa, 0x1c00007
	jr z, DrawCombo_CheckVisible
	ld xwa, xiz
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	jr DrawCombo_CallInherited

DrawCombo_CheckVisible:
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, xiz
	call GetVisible
	cps hl, 0
	jr z, DrawCombo_ForwardToBase
	ld xwa, xiz
	ld xbc, 0x1e00053
	ld xde, (xsp + 8)
	call SendEvent
	cps hl, 0
	jr z, DrawCombo_ForwardToBase
	ld xwa, (xsp + 4)
	ld de, (xwa + 40)
	cp de, 0xffff
	jr z, DrawCombo_ReturnZero
	exts xde
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001b
	call SendEvent

DrawCombo_ReturnZero:
	lds32 xhl, 0
	jr AcDrawComboBox_CheckDone

DrawCombo_ForwardToBase:
	ld xwa, xiz
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)

DrawCombo_CallInherited:
	call InheritedProc
	jr AcDrawComboBox_CheckDone

DrawCombo_GetWidgetValue:
	ld xwa, xiz
	call GetViewInstance
	ld hl, (xhl + 40)
	exts xhl
	jr AcDrawComboBox_CheckDone

DrawCombo_CompareMatch:
	ld xwa, xiz
	call GetViewInstance
	ld wa, (xhl + 40)
	exts xwa
	cp xwa, (xsp + 8)
	scc16 z, hl
	extz xhl

AcDrawComboBox_CheckDone:
	pop xiz
	lda xsp, (xsp + 12)
	ret

AcDrawbarNameProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld xiz, xbc
	ld (xsp + 12), xwa
	cp xiz, 0x1c00020
	jrl z, AcDrawbarName_Notify
	cp xiz, 0x1c10008
	jrl z, AcDrawbarName_DrawbarInit
	cp xiz, 0x1c0002f
	jrl z, AcDrawbarName_Refresh
	cp xiz, 0x1c0001c
	jrl z, AcDrawbarName_Match
	cp xiz, 0x1c00007
	jrl z, AcDrawbarName_OK
	cp xiz, 0x1c0000d
	jr z, AcDrawbarName_Paint
	cp xiz, 0x1c0000c
	jr z, AcDrawbarName_ShowHide
	cp xiz, 0x1c0000b
	jr z, AcDrawbarName_ShowHide
	cp xiz, 0x1c00002
	jr z, AcDrawbarName_Close
	cp xiz, 0x1c00001
	jrl nz, AcDrawbarName_ForwardToBase
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	jr AcDrawbarName_Init_Forward

AcDrawbarName_Close:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)

AcDrawbarName_Init_Forward:
	call InheritedProc
	jrl AcDrawbarName_ReturnHandled

AcDrawbarName_ShowHide:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 12)
	call GetViewInstance
	lda xwa, (xhl + 36)
	cpw (xwa), 0xff
	jr z, AcDrawbarName_ShowHide_NoInstr
	ld de, (xwa)
	extz xde
	ld xwa, 0x1410001
	ld xbc, 0x1e1000e
	jrl AcDrawbarName_SendDrawbarNameSet

AcDrawbarName_ShowHide_NoInstr:
	call GetPartSelect
	extz xhl
	ld xwa, 0x1410001
	ld xbc, 0x1e1000e
	ld xde, xhl
	jrl AcDrawbarName_SendDrawbarNameSet

AcDrawbarName_Paint:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	call GetModeNow
	cp xhl, 0x1800003
	jrl z, AcDrawbarName_ReturnHandled
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xiz, xhl
	lda xbc, (xsp + 4)
	ld wa, (xiz + 38)
	call GetEditSwPoint
	cpw (xsp + 6), 0xef
	jrl z, AcDrawbarName_ReturnHandled
	ld wa, (xiz + 38)
	call DrawEditSw
	jrl AcDrawbarName_ReturnHandled

AcDrawbarName_OK:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld wa, (xhl + 38)
	extz xwa
	cp xwa, (xsp + 8)
	jr nz, AcDrawbarName_OK_Forward
	ld de, (xhl + 26)
	cp de, 0xffff
	jrl z, AcDrawbarName_ReturnHandled
	exts xde
	ld xwa, (xsp + 8)
	bit 7, wa
	jr z, AcDrawbarName_OK_ScrollUp
	ld xwa, 0xffffffff
	ld xbc, 0x1c00018
	jrl AcDrawbarName_DispatchEvent

AcDrawbarName_OK_ScrollUp:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00017
	jrl AcDrawbarName_DispatchEvent

AcDrawbarName_OK_Forward:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	jrl AcDrawbarName_CallBase

AcDrawbarName_Match:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 12)
	call GetViewInstance
	lda xwa, (xhl + 36)
	cpw (xwa), 0xff
	jr z, AcDrawbarName_Match_NoInstr
	ld de, (xwa)
	extz xde
	ld xbc, xde
	sll xbc, 10
	ld xhl, xbc
	add xhl, 0x8000
	ld xwa, (xsp + 8)
	cp xhl, (xwa)
	jr z, AcDrawbarName_Match_SendName
	add xbc, 0x8020
	cp xbc, (xwa)
	jrl nz, AcDrawbarName_ReturnHandled

AcDrawbarName_Match_SendName:
	ld xwa, 0x1410001
	ld xbc, 0x1e1000e
	jr AcDrawbarName_SendDrawbarNameSet

AcDrawbarName_Match_NoInstr:
	call GetPartSelect
	extz xhl
	sll xhl, 10
	add xhl, 0x8000
	ld xwa, (xsp + 8)
	cp (xwa), xhl
	jr z, AcDrawbarName_Match_NoInstr_Send
	call GetPartSelect
	extz xhl
	sll xhl, 10
	add xhl, 0x8020
	ld xwa, (xsp + 8)
	cp (xwa), xhl
	jrl nz, AcDrawbarName_ReturnHandled

AcDrawbarName_Match_NoInstr_Send:
	call GetPartSelect
	extz xhl
	ld xwa, 0x1410001
	ld xbc, 0x1e1000e
	ld xde, xhl
	jr AcDrawbarName_SendDrawbarNameSet

AcDrawbarName_Refresh:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 12)
	call GetViewInstance
	cpw (xhl + 36), 0xff
	jrl nz, AcDrawbarName_ReturnHandled
	call GetPartSelect
	extz xhl
	ld xwa, 0x1410001
	ld xbc, 0x1e1000e
	ld xde, xhl

AcDrawbarName_SendDrawbarNameSet:
	call MainFuncCall
	jrl AcDrawbarName_ReturnHandled

AcDrawbarName_DrawbarInit:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 12)
	call GetViewInstance
	lda xwa, (xhl + 36)
	cpw (xwa), 0xff
	jr z, AcDrawbarName_DrawbarInit_NoInstr
	ld xbc, (xsp + 8)
	srl xbc, 0
	ldi_werp 0xe6, 0
	ld de, (xwa)
	cp bc, de
	jrl nz, AcDrawbarName_ReturnHandled
	ld xwa, (xsp + 8)
	cps wa, 1
	jrl nz, AcDrawbarName_ReturnHandled
	extz xde
	ld xwa, 0x1400004
	ld xbc, 0x1e0005e
	jr AcDrawbarName_DrawbarInit_OpenEditor

AcDrawbarName_DrawbarInit_NoInstr:
	call GetPartSelect
	ld xwa, (xsp + 8)
	srl xwa, 0
	ldi_werp 0xe2, 0
	cp wa, hl
	jr nz, AcDrawbarName_ReturnHandled
	ld xwa, (xsp + 8)
	cps wa, 1
	jr nz, AcDrawbarName_ReturnHandled
	call GetPartSelect
	extz xhl
	ld xwa, 0x1400004
	ld xbc, 0x1e0005e
	ld xde, xhl

AcDrawbarName_DrawbarInit_OpenEditor:
	call FuncCall
	jr AcDrawbarName_ReturnHandled

AcDrawbarName_Notify:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 12)
	call GetViewInstance
	lda xbc, (xhl + 36)
	cpw (xbc), 0xff
	jr z, AcDrawbarName_Notify_NoInstr
	ld xde, (xsp + 8)
	ld wa, (xde)
	cp wa, (xbc)
	jr nz, AcDrawbarName_ReturnHandled
	ld xde, (xde + 2)
	ld xwa, (xsp + 12)
	ld xbc, 0x1c0000f
	jr AcDrawbarName_DispatchEvent

AcDrawbarName_Notify_NoInstr:
	call GetPartSelect
	ld xwa, (xsp + 8)
	cp (xwa), hl
	jr nz, AcDrawbarName_ReturnHandled
	ld xde, (xwa + 2)
	ld xwa, (xsp + 12)
	ld xbc, 0x1c0000f

AcDrawbarName_DispatchEvent:
	call SendEvent

AcDrawbarName_ReturnHandled:
	lds32 xhl, 0
	jr AcDrawbarName_Return

AcDrawbarName_ForwardToBase:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)

AcDrawbarName_CallBase:
	call InheritedProc

AcDrawbarName_Return:
	pop xiz
	lda xsp, (xsp + 12)
	ret

IvPageOverWriteProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld (xsp + 12), xwa
	ld xwa, (xsp + 8)
	cp xwa, 0x1c0001e
	jrl z, DrawCombo_CloseWidget
	cp xwa, 0x1c00035
	jr z, DrawCombo_InitWidget
	cp xwa, 0x1e0003a
	jr z, DrawCombo_GetText
	cp xwa, 0x1c0000d
	jr z, DrawCombo_Paint
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	jrl DrawCombo_Epilogue

DrawCombo_Paint:
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 12)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jrl DrawCombo_SendEvent

DrawCombo_GetText:
	pushw 0xe9
	pushw 0xf930
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	jrl AcDrawComboBox_Return

DrawCombo_InitWidget:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 24)
	ld xbc, 0x1e00094
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr z, DrawCombo_InitForward
	ld xwa, (xiz + 24)
	ld xbc, 0x1c00002
	lds32 xde, 0
	call SendEvent

DrawCombo_InitForward:
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	ld wa, (xiz + 22)
	exts xwa
	cp xwa, (xsp + 4)
	jr nz, AcDrawComboBox_Return
	ld xwa, (xiz + 24)
	ld xbc, 0x1c00001
	lds32 xde, 0
	jr DrawCombo_SendEvent

DrawCombo_CloseWidget:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 24)
	ld xbc, 0x1e00094
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr z, DrawCombo_CloseForward
	ld xwa, (xiz + 24)
	ld xbc, 0x1c00002
	lds32 xde, 5
	call SendEvent

DrawCombo_CloseForward:
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	ld wa, (xiz + 22)
	exts xwa
	cp xwa, (xsp + 4)
	jr nz, AcDrawComboBox_Return
	ld xwa, (xiz + 24)
	ld xbc, 0x1c00001
	lds32 xde, 5

DrawCombo_SendEvent:
	call SendEvent

AcDrawComboBox_Return:
	lds32 xhl, 0

DrawCombo_Epilogue:
	pop xiz
	lda xsp, (xsp + 12)
	ret

AcDrawEditBoxProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	call GetModeNow
	cp xhl, 0x1800003
	jr z, EditBox_CheckDialEvent
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	jrl EditBox_CallInherited2

EditBox_CheckDialEvent:
	cp xiz, 0x1c00018
	jr z, AcEditBox_DialApplyEvent
	cp xiz, 0x1c0001a
	jr z, AcEditBox_DialApplyEvent
	cp xiz, 0x1c00017
	jr z, AcEditBox_DialApplyEvent
	cp xiz, 0x1c00019
	jr z, AcEditBox_DialApplyEvent
	cp xiz, 0x1c0000c
	jr z, EditBox_ShowHide
	cp xiz, 0x1c0000b
	jr nz, EditBox_ForwardToBase

EditBox_ShowHide:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	jr EditBox_CallInherited

AcEditBox_DialApplyEvent:
	ld xwa, (xsp + 8)
	ld xbc, 0x1e0003c
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, EditBox_DialForward
	ld xwa, (xsp + 8)
	call GetViewInstance
	ld xwa, (xhl + 50)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call ApFuncCall
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call SetAutoInc
	jr EditBox_ReturnZero

EditBox_DialForward:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)

EditBox_CallInherited:
	call InheritedProc

EditBox_ReturnZero:
	lds32 xhl, 0
	jr EditBox_Epilogue

EditBox_ForwardToBase:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)

EditBox_CallInherited2:
	call InheritedProc

EditBox_Epilogue:
	pop xiz
	inc 8, xsp
	ret

LswPercDecay:
	push xiz
	ld xiz, xwa
	cp xbc, 0x1c00018
	jrl z, Lsw_PercDecay_DialScroll
	cp xbc, 0x1c0001a
	jrl z, Lsw_PercDecay_DialScroll
	cp xbc, 0x1c00017
	jrl z, Lsw_PercDecay_DialScroll
	cp xbc, 0x1c00019
	jrl z, Lsw_PercDecay_DialScroll
	cp xbc, 0x1e00083
	jr z, LswPercDecay_StoreDE
	cp xbc, 0x1e0003f
	jr z, LswPercDecay_ReturnOne
	cp xbc, 0x1e0003e
	jr z, LswPercDecay_ReturnOne
	cp xbc, 0x1e00041
	jr z, LswPercDecay_StepSize
	cp xbc, 0x1e10001
	jr z, LswPercDecay_SubParam
	cp xbc, 0x1e10002
	jr z, LswPercDecay_ReturnOne
	cp xbc, 0x1e10000
	jr z, LswPercDecay_PartIdLookup
	cp xbc, 0x1e00042
	jr nz, LswPercDecay_Return
	ld wa, (xde + 4)
	sla wa, 2
	lda_24 xbc, 0xe9f8aa
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	ld xwa, (xde + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	ld xhl, xiz
	jr LswPercDecay_PopIzRet

LswPercDecay_PartIdLookup:
	add xde, xde
	ld xwa, 0xe953ce
	add xwa, xde
	ld hl, (xwa)
	exts xhl
	jr LswPercDecay_PopIzRet

LswPercDecay_ReturnOne:
	lds32 xhl, 1
	jr LswPercDecay_PopIzRet

LswPercDecay_SubParam:
	ld xhl, 0x2cc
	jr LswPercDecay_PopIzRet

LswPercDecay_StepSize:
	lds32 xhl, 3
	jr LswPercDecay_PopIzRet

LswPercDecay_StoreDE:
	st16_24 0x0247c6, xde
	jr LswPercDecay_Return

Lsw_PercDecay_DialScroll:
	ld xwa, xbc
	lds bc, 1
	lds de, 1
	calr SdpartScrollDelta
	ld bc, hl
	ld16_24 xwa, 0x0247c6
	calr SdpartClampSignedScrollDelta
	cpda16_24 xhl, 149446
	jr z, LswPercDecay_Return
	extz xhl
	add xhl, 0xb0000
	ld xwa, 0x1410001
	ld xbc, 0x1e1000a
	ld xde, xhl
	call MainFuncCall

LswPercDecay_Return:
	lds32 xhl, 0

LswPercDecay_PopIzRet:
	pop xiz
	ret

SdpartClampSignedScrollDelta:
	ld hl, wa
	cps wa, 7
	jr le, SdpartClamp_CheckUpper
	sub wa, 0x10

SdpartClamp_CheckUpper:
	cps wa, 5
	jr gt, SdpartClamp_ReturnZero
	cp wa, 0xfffb
	jr ge, SdpartClamp_Apply

SdpartClamp_ReturnZero:
	lds hl, 0
	ret

SdpartClamp_Apply:
	add wa, bc
	cps wa, 5
	ret gt
	cp wa, 0xfffb
	ret lt
	cps wa, 0
	jr ge, SdpartClamp_StoreResult
	add wa, 0x10

SdpartClamp_StoreResult:
	ld hl, wa
	ret

LswPercLevel:
	push xiz
	ld xiz, xwa
	cp xbc, 0x1c00018
	jrl z, Lsw_PercLevel_DialScroll
	cp xbc, 0x1c0001a
	jrl z, Lsw_PercLevel_DialScroll
	cp xbc, 0x1c00017
	jrl z, Lsw_PercLevel_DialScroll
	cp xbc, 0x1c00019
	jrl z, Lsw_PercLevel_DialScroll
	cp xbc, 0x1e00083
	jr z, LswPercLevel_StoreDE
	cp xbc, 0x1e0003f
	jr z, LswPercLevel_ReturnOne
	cp xbc, 0x1e0003e
	jr z, LswPercLevel_ReturnOne
	cp xbc, 0x1e00041
	jr z, LswPercLevel_StepSize
	cp xbc, 0x1e10001
	jr z, LswPercLevel_SubParam
	cp xbc, 0x1e10002
	jr z, LswPercLevel_ReturnOne
	cp xbc, 0x1e10000
	jr z, LswPercLevel_PartIdLookup
	cp xbc, 0x1e00042
	jr nz, LswPercLevel_Return
	ld wa, (xde + 4)
	sla wa, 2
	lda_24 xbc, 0xe9f8aa
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	ld xwa, (xde + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	ld xhl, xiz
	jr LswPercLevel_PopIzRet

LswPercLevel_PartIdLookup:
	add xde, xde
	ld xwa, 0xe953ce
	add xwa, xde
	ld hl, (xwa)
	exts xhl
	jr LswPercLevel_PopIzRet

LswPercLevel_ReturnOne:
	lds32 xhl, 1
	jr LswPercLevel_PopIzRet

LswPercLevel_SubParam:
	ld xhl, 0x2cb
	jr LswPercLevel_PopIzRet

LswPercLevel_StepSize:
	lds32 xhl, 3
	jr LswPercLevel_PopIzRet

LswPercLevel_StoreDE:
	st16_24 0x0247c8, xde
	jr LswPercLevel_Return

Lsw_PercLevel_DialScroll:
	ld xwa, xbc
	lds bc, 1
	lds de, 1
	calr SdpartScrollDelta
	ld bc, hl
	ld16_24 xwa, 0x0247c8
	calr SdpartClampSignedScrollDelta
	cpda16_24 xhl, 149448
	jr z, LswPercLevel_Return
	extz xhl
	add xhl, 0xc0000
	ld xwa, 0x1410001
	ld xbc, 0x1e1000a
	ld xde, xhl
	call MainFuncCall

LswPercLevel_Return:
	lds32 xhl, 0

LswPercLevel_PopIzRet:
	pop xiz
	ret

LswDrawAttack:
	push xiz
	ld xiz, xwa
	cp xbc, 0x1c00018
	jrl z, Lsw_DrawAttack_DialScroll
	cp xbc, 0x1c0001a
	jrl z, Lsw_DrawAttack_DialScroll
	cp xbc, 0x1c00017
	jrl z, Lsw_DrawAttack_DialScroll
	cp xbc, 0x1c00019
	jrl z, Lsw_DrawAttack_DialScroll
	cp xbc, 0x1e00083
	jr z, LswDrawAttack_StoreDE
	cp xbc, 0x1e0003f
	jr z, LswDrawAttack_ReturnOne
	cp xbc, 0x1e0003e
	jr z, LswDrawAttack_ReturnOne
	cp xbc, 0x1e00041
	jr z, LswDrawAttack_StepSize
	cp xbc, 0x1e10001
	jr z, LswDrawAttack_SubParam
	cp xbc, 0x1e10002
	jr z, LswDrawAttack_ReturnOne
	cp xbc, 0x1e10000
	jr z, LswDrawAttack_PartIdLookup
	cp xbc, 0x1e00042
	jr nz, LswDrawAttack_Return
	ld wa, (xde + 4)
	sla wa, 2
	lda_24 xbc, 0xe9f8aa
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	ld xwa, (xde + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	ld xhl, xiz
	jr LswDrawAttack_PopIzRet

LswDrawAttack_PartIdLookup:
	add xde, xde
	ld xwa, 0xe953ce
	add xwa, xde
	ld hl, (xwa)
	exts xhl
	jr LswDrawAttack_PopIzRet

LswDrawAttack_ReturnOne:
	lds32 xhl, 1
	jr LswDrawAttack_PopIzRet

LswDrawAttack_SubParam:
	ld xhl, 0x294
	jr LswDrawAttack_PopIzRet

LswDrawAttack_StepSize:
	lds32 xhl, 3
	jr LswDrawAttack_PopIzRet

LswDrawAttack_StoreDE:
	st16_24 0x0247cc, xde
	jr LswDrawAttack_Return

Lsw_DrawAttack_DialScroll:
	ld xwa, xbc
	lds bc, 1
	lds de, 1
	calr SdpartScrollDelta
	ld bc, hl
	ld16_24 xwa, 0x0247cc
	calr SdpartClampSignedScrollDelta
	cpda16_24 xhl, 149452
	jr z, LswDrawAttack_Return
	extz xhl
	add xhl, 0xe0000
	ld xwa, 0x1410001
	ld xbc, 0x1e1000a
	ld xde, xhl
	call MainFuncCall

LswDrawAttack_Return:
	lds32 xhl, 0

LswDrawAttack_PopIzRet:
	pop xiz
	ret

LswDrawRelease:
	push xiz
	ld xiz, xwa
	cp xbc, 0x1c00018
	jrl z, Lsw_DrawRelease_DialScroll
	cp xbc, 0x1c0001a
	jrl z, Lsw_DrawRelease_DialScroll
	cp xbc, 0x1c00017
	jrl z, Lsw_DrawRelease_DialScroll
	cp xbc, 0x1c00019
	jrl z, Lsw_DrawRelease_DialScroll
	cp xbc, 0x1e00083
	jr z, LswDrawRelease_StoreDE
	cp xbc, 0x1e0003f
	jr z, LswDrawRelease_ReturnOne
	cp xbc, 0x1e0003e
	jr z, LswDrawRelease_ReturnOne
	cp xbc, 0x1e00041
	jr z, LswDrawRelease_StepSize
	cp xbc, 0x1e10001
	jr z, LswDrawRelease_SubParam
	cp xbc, 0x1e10002
	jr z, LswDrawRelease_ReturnOne
	cp xbc, 0x1e10000
	jr z, LswDrawRelease_PartIdLookup
	cp xbc, 0x1e00042
	jr nz, LswDrawRelease_Return
	ld wa, (xde + 4)
	sla wa, 2
	lda_24 xbc, 0xe9f8aa
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	ld xwa, (xde + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	ld xhl, xiz
	jr LswDrawRelease_PopIzRet

LswDrawRelease_PartIdLookup:
	add xde, xde
	ld xwa, 0xe953ce
	add xwa, xde
	ld hl, (xwa)
	exts xhl
	jr LswDrawRelease_PopIzRet

LswDrawRelease_ReturnOne:
	lds32 xhl, 1
	jr LswDrawRelease_PopIzRet

LswDrawRelease_SubParam:
	ld xhl, 0x293
	jr LswDrawRelease_PopIzRet

LswDrawRelease_StepSize:
	lds32 xhl, 3
	jr LswDrawRelease_PopIzRet

LswDrawRelease_StoreDE:
	st16_24 0x0247ca, xde
	jr LswDrawRelease_Return

Lsw_DrawRelease_DialScroll:
	ld xwa, xbc
	lds bc, 1
	lds de, 1
	calr SdpartScrollDelta
	ld bc, hl
	ld16_24 xwa, 0x0247ca
	calr SdpartClampSignedScrollDelta
	cpda16_24 xhl, 149450
	jr z, LswDrawRelease_Return
	extz xhl
	add xhl, 0xd0000
	ld xwa, 0x1410001
	ld xbc, 0x1e1000a
	ld xde, xhl
	call MainFuncCall

LswDrawRelease_Return:
	lds32 xhl, 0

LswDrawRelease_PopIzRet:
	pop xiz
	ret

IvDrawbar1Proc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld (xsp + 12), xwa
	ld xwa, (xsp + 8)
	cp xwa, 0x1e0003a
	jrl z, IvDrawbar1_GetText
	cp xwa, 0x1c0002f
	jrl z, IvDrawbar1_Refresh
	cp xwa, 0x1c0001c
	jrl z, IvDrawbar1_Match
	cp xwa, 0x1c00007
	jrl z, IvDrawbar1_OK
	cp xwa, 0x1e000a7
	jrl z, IvDrawbar1_DrawbarUpdate
	cp xwa, 0x1e10008
	jrl z, IvDrawbar1_LoadVals
	cp xwa, 0x1c0000d
	jrl z, IvDrawbar1_Paint
	cp xwa, 0x1c0000c
	jr z, IvDrawbar1_ShowHide
	cp xwa, 0x1c0000b
	jr z, IvDrawbar1_ShowHide
	cp xwa, 0x1c00002
	jr z, IvDrawbar1_Close
	cp xwa, 0x1c00001
	jrl nz, IvDrawbar1_ForwardToBase
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	jrl IvDrawbar1_CallBase

IvDrawbar1_Close:
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	jrl IvDrawbar1_CallBase

IvDrawbar1_ShowHide:
	call GetPartSelect
	st16_24 0x02479a, xhl
	ld xwa, (xsp + 12)
	ld xbc, 0x1e10008
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	ld16_24 xde, 0x024798
	exts xde
	ld xwa, 0xea000c
	ld xbc, 0x1e0003b
	call SendEvent
	ld xwa, (xsp + 12)
	ld xbc, 0x1e000a7
	ld xde, 0xffffffff
	jrl IvDrawbar1_DispatchEvent

IvDrawbar1_Paint:
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 12)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jrl IvDrawbar1_DispatchEvent

IvDrawbar1_LoadVals:
	call GetModeNow
	cp xhl, 0x1800003
	jr z, IvDrawbar1_LoadVals_DualMode
	lds iz, 0

IvDrawbar1_LoadVals_Loop:
	ld16_24 xwa, 0x02479a
	ld bc, iz
	extz xbc
	add xbc, xbc
	ld xde, 0xe9f87a
	add xde, xbc
	ld bc, (xde)
	call SndParam_LookupViaEncode
	ld wa, iz
	extz xwa
	add xwa, xwa
	ld xbc, 0x247b0
	add xbc, xwa
	ld (xbc), hl
	inc 1, iz
	cp iz, 0x8
	jr ule, IvDrawbar1_LoadVals_Loop
	jrl IvDrawbar1_ReturnHandled

IvDrawbar1_LoadVals_DualMode:
	ld xwa, 0x1410001
	ld xbc, 0x1e10008
	lds32 xde, 0
	call MainFuncCall
	jrl IvDrawbar1_ReturnHandled

IvDrawbar1_DrawbarUpdate:
	ld xwa, (xsp + 4)
	cp xwa, 0x8
	jr ule, IvDrawbar1_DrawbarUpdate_OneSlider
	lds iz, 0

IvDrawbar1_DrawbarUpdate_AllSliders:
	ld de, iz
	extz xde
	ld xwa, (xsp + 12)
	ld xbc, 0x1e000a7
	call SendEvent
	inc 1, iz
	cp iz, 0x8
	jr ule, IvDrawbar1_DrawbarUpdate_AllSliders
	jrl IvDrawbar1_ReturnHandled

IvDrawbar1_DrawbarUpdate_OneSlider:
	ld xbc, (xsp + 4)
	add xbc, xbc
	ld xde, 0x2479e
	add xde, xbc
	ld xwa, 0x247b0
	add xwa, xbc
	ld wa, (xwa)
	ld bc, (xde)
	cp wa, bc
	jr z, IvDrawbar1_DrawbarUpdate_Render
	cp bc, wa
	jr le, IvDrawbar1_DrawbarUpdate_Inc
	dec 1, bc
	jr IvDrawbar1_DrawbarUpdate_Store

IvDrawbar1_DrawbarUpdate_Inc:
	inc 1, bc

IvDrawbar1_DrawbarUpdate_Store:
	ld (xde), bc

IvDrawbar1_DrawbarUpdate_Render:
	ld xwa, (xsp + 4)
	ld bc, (xde)
	calr DrawbarBitmapHelper
	lds wa, 1
	call SetNeedUpdate
	call UpdateScreen
	lds wa, 0
	call SetNeedUpdate
	ld xwa, (xsp + 4)
	add xwa, xwa
	ld xde, 0x2479e
	add xde, xwa
	ld xbc, 0x247b0
	add xbc, xwa
	ld wa, (xbc)
	cp wa, (xde)
	jrl z, IvDrawbar1_ReturnHandled
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call ApDeliveryEvent
	jrl IvDrawbar1_ReturnHandled

IvDrawbar1_OK:
	ld xwa, 0x2600024
	ld xbc, 0x1e00029
	ld xde, (xsp + 4)
	call SendEvent
	ldfr_werp HL, 0xfa
	cpi_werp 0xfa, 7
	jr le, IvDrawbar1_OK_CheckSixteen
	cp_erpw 0xfa, 0x10, 0x00
	jrl nz, IvDrawbar1_OK_Forward

IvDrawbar1_OK_CheckSixteen:
	cp_erpw 0xfa, 0x10, 0x00
	jr nz, IvDrawbar1_OK_ComputeNewValue
	ldi_erpw 0xfa, 0x08, 0x00

IvDrawbar1_OK_ComputeNewValue:
	ldto_werp BC, 0xfa
	add bc, bc
	lda_24 xwa, 0x0247b0
	ld_sriw3 IZ, 0x07, 0xe0, 0xe4
	ld xwa, (xsp + 4)
	bit 7, wa
	jr z, IvDrawbar1_OK_ScrollDown
	inc 1, iz
	cp iz, 0x8
	jrl gt, IvDrawbar1_ReturnHandled
	call GetModeNow
	cp xhl, 0x1800003
	jr z, IvDrawbar1_OK_ScrollUp_DualMode
	ld16_24 xwa, 0x02479a
	ldto_werp BC, 0xfa
	add bc, bc
	lda_24 xde, 0xe9f87a
	ld_sriw3 BC, 0x07, 0xe8, 0xe4
	pushw 0x4
	ld de, iz
	call MainLswPartPut
	jr IvDrawbar1_OK_ScrollRelease

IvDrawbar1_OK_ScrollUp_DualMode:
	ldto_werp BC, 0xfa
	add bc, bc
	lda_24 xwa, 0x0247b0
	ld_sriw3 WA, 0x07, 0xe0, 0xe4
	cp wa, 0x8
	jr ge, IvDrawbar1_OK_ScrollRelease
	inc 1, wa
	ld bc, wa
	extz xbc
	ldto_werp WA, 0xfa
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld xwa, 0x1410001
	ld xbc, 0x1e1000a
	call MainFuncCall

IvDrawbar1_OK_ScrollRelease:
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	jr IvDrawbar1_OK_ScrollCommit

IvDrawbar1_OK_ScrollDown:
	sub iz, 0x1
	jrl lt, IvDrawbar1_ReturnHandled
	call GetModeNow
	ldto_werp BC, 0xfa
	add bc, bc
	cp xhl, 0x1800003
	jr z, IvDrawbar1_OK_ScrollDown_DualMode
	ld16_24 xwa, 0x02479a
	lda_24 xde, 0xe9f87a
	ld_sriw3 BC, 0x07, 0xe8, 0xe4
	pushw 0x4
	ld de, iz
	call MainLswPartPut
	jr IvDrawbar1_OK_ScrollDown_Release

IvDrawbar1_OK_ScrollDown_DualMode:
	lda_24 xwa, 0x0247b0
	ld_sriw3 WA, 0x07, 0xe0, 0xe4
	cps wa, 0
	jr le, IvDrawbar1_OK_ScrollDown_Release
	dec 1, wa
	ld bc, wa
	extz xbc
	ldto_werp WA, 0xfa
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld xwa, 0x1410001
	ld xbc, 0x1e1000a
	call MainFuncCall

IvDrawbar1_OK_ScrollDown_Release:
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)

IvDrawbar1_OK_ScrollCommit:
	call SetAutoInc
	jrl IvDrawbar1_ReturnHandled

IvDrawbar1_OK_Forward:
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	jrl IvDrawbar1_ForwardCallBase

IvDrawbar1_Match:
	ld xix, (xsp + 4)
	ld16_24 xde, 0x02479a
	exts xde
	sll xde, 10
	ld xbc, xde
	add xbc, 0x8280
	ld xwa, (xsp + 4)
	lda xhl, (xwa + 4)
	cp xbc, (xwa)
	jr nz, IvDrawbar1_Match_Ch1
	ld wa, (xhl)
	st16_24 0x0247b0, xwa
	ld xwa, (xsp + 12)
	ld xbc, 0x1e000a7
	lds32 xde, 0
	jrl IvDrawbar1_Match_DispatchUpdate

IvDrawbar1_Match_Ch1:
	ld xwa, xde
	add xwa, 0x8282
	cp xwa, (xix)
	jr nz, IvDrawbar1_Match_Ch2
	ld wa, (xhl)
	st16_24 0x0247b2, xwa
	ld xwa, (xsp + 12)
	ld xbc, 0x1e000a7
	lds32 xde, 1
	jrl IvDrawbar1_Match_DispatchUpdate

IvDrawbar1_Match_Ch2:
	ld xwa, xde
	add xwa, 0x8281
	cp xwa, (xix)
	jr nz, IvDrawbar1_Match_Ch3
	ld wa, (xhl)
	st16_24 0x0247b4, xwa
	ld xwa, (xsp + 12)
	ld xbc, 0x1e000a7
	lds32 xde, 2
	jrl IvDrawbar1_Match_DispatchUpdate

IvDrawbar1_Match_Ch3:
	ld xwa, xde
	add xwa, 0x8283
	cp xwa, (xix)
	jr nz, IvDrawbar1_Match_Ch4
	ld wa, (xhl)
	st16_24 0x0247b6, xwa
	ld xwa, (xsp + 12)
	ld xbc, 0x1e000a7
	lds32 xde, 3
	jrl IvDrawbar1_Match_DispatchUpdate

IvDrawbar1_Match_Ch4:
	ld xwa, xde
	add xwa, 0x8284
	lda_24 xbc, 0x0247b0
	cp xwa, (xix)
	jr nz, IvDrawbar1_Match_Ch5
	ld wa, (xhl)
	ld (xbc + 8), wa
	ld xwa, (xsp + 12)
	ld xbc, 0x1e000a7
	lds32 xde, 4
	jr IvDrawbar1_Match_DispatchUpdate

IvDrawbar1_Match_Ch5:
	ld xwa, xde
	add xwa, 0x8285
	cp xwa, (xix)
	jr nz, IvDrawbar1_Match_Ch6
	ld wa, (xhl)
	ld (xbc + 10), wa
	ld xwa, (xsp + 12)
	ld xbc, 0x1e000a7
	lds32 xde, 5
	jr IvDrawbar1_Match_DispatchUpdate

IvDrawbar1_Match_Ch6:
	ld xwa, xde
	add xwa, 0x8286
	cp xwa, (xix)
	jr nz, IvDrawbar1_Match_Ch7
	ld wa, (xhl)
	ld (xbc + 12), wa
	ld xwa, (xsp + 12)
	ld xbc, 0x1e000a7
	lds32 xde, 6
	jr IvDrawbar1_Match_DispatchUpdate

IvDrawbar1_Match_Ch7:
	ld xiy, xde
	add xiy, 0x8287
	ld wa, (xhl)
	cp xiy, (xix)
	jr nz, IvDrawbar1_Match_Ch8
	ld (xbc + 14), wa
	ld xwa, (xsp + 12)
	ld xbc, 0x1e000a7
	lds32 xde, 7
	jr IvDrawbar1_Match_DispatchUpdate

IvDrawbar1_Match_Ch8:
	add xde, 0x8288
	cp xde, (xix)
	jr nz, IvDrawbar1_Match_Forward
	ld (xbc + 16), wa
	ld xwa, (xsp + 12)
	ld xbc, 0x1e000a7
	ld xde, 0x8

IvDrawbar1_Match_DispatchUpdate:
	call SendEvent

IvDrawbar1_Match_Forward:
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)

IvDrawbar1_CallBase:
	call InheritedProc
	jr IvDrawbar1_ReturnHandled

IvDrawbar1_Refresh:
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	call GetPartSelect
	st16_24 0x02479a, xhl
	ld xwa, (xsp + 12)
	ld xbc, 0x1e10008
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 12)
	ld xbc, 0x1e000a7
	ld xde, 0xffffffff

IvDrawbar1_DispatchEvent:
	call SendEvent
	jr IvDrawbar1_ReturnHandled

IvDrawbar1_GetText:
	pushw 0xe9
	pushw 0xf936
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp

IvDrawbar1_ReturnHandled:
	lds32 xhl, 0
	jr IvDrawbar1_Return

IvDrawbar1_ForwardToBase:
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)

IvDrawbar1_ForwardCallBase:
	call InheritedProc

IvDrawbar1_Return:
	pop xiz
	lda xsp, (xsp + 12)
	ret

IvDrawbar2Proc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1e0003a
	jrl z, IvDrawbar2_GetText
	cp xiz, 0x1c00018
	jrl z, IvDrawbar2_OKHandler
	cp xiz, 0x1c00017
	jrl z, IvDrawbar2_OKHandler
	cp xiz, 0x1c0001c
	jrl z, IvDrawbar2_MatchHandler
	cp xiz, 0x1e10008
	jr z, IvDrawbar2_LoadValsHandler
	cp xiz, 0x1c0000d
	jr z, IvDrawbar2_PaintHandler
	cp xiz, 0x1c0000c
	jr z, IvDrawbar2_ShowHideHandler
	cp xiz, 0x1c0000b
	jr z, IvDrawbar2_ShowHideHandler
	cp xiz, 0x1c00001
	jrl nz, IvDrawbar2_ForwardToBase
	ld xwa, (xsp + 8)
	ld xbc, 0x1e10008
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	jrl IvDrawbar2_CallInherited

IvDrawbar2_ShowHideHandler:
	call GetPartSelect
	st16_24 0x02479a, xhl
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld16_24 xde, 0x024798
	exts xde
	ld xwa, 0xea000c
	ld xbc, 0x1e0003b
	jr IvDrawbar2_SendEventShared

IvDrawbar2_PaintHandler:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 8)
	ld xbc, 0x1c0000f
	lds32 xde, 0

IvDrawbar2_SendEventShared:
	call SendEvent
	jrl IvDrawbar_ReturnZeroJmp

IvDrawbar2_LoadValsHandler:
	call GetModeNow
	cp xhl, 0x1800003
	jr z, IvDrawbar2_LoadMode3
	ld16_24 xwa, 0x02479a
	ldw bc, 0x2cc
	call SndParam_LookupViaEncode
	st16_24 0x0247c6, xhl
	ld16_24 xwa, 0x02479a
	ldw bc, 0x2cb
	call SndParam_LookupViaEncode
	st16_24 0x0247c8, xhl
	ld16_24 xwa, 0x02479a
	ldw bc, 0x293
	call SndParam_LookupViaEncode
	st16_24 0x0247ca, xhl
	ld16_24 xwa, 0x02479a
	ldw bc, 0x294
	call SndParam_LookupViaEncode
	st16_24 0x0247cc, xhl
	jrl IvDrawbar_ReturnZeroJmp

IvDrawbar2_LoadMode3:
	ld xwa, 0x1410001
	ld xbc, 0x1e10008
	lds32 xde, 0
	jrl IvDrawbar2_MainFuncCallShared

IvDrawbar2_MatchHandler:
	ld xhl, (xsp + 4)
	ld16_24 xbc, 0x02479a
	exts xbc
	sll xbc, 10
	ld xix, xbc
	add xix, 0x82cc
	ld xwa, (xsp + 4)
	lda xde, (xwa + 4)
	cp xix, (xwa)
	jr nz, IvDrawbar2_MatchCheck2CB
	ld wa, (xde)
	st16_24 0x0247c6, xwa
	jr IvDrawbar_ForwardUnhandled

IvDrawbar2_MatchCheck2CB:
	ld xwa, xbc
	add xwa, 0x82cb
	cp xwa, (xhl)
	jr nz, IvDrawbar2_MatchCheck294
	ld wa, (xde)
	st16_24 0x0247c8, xwa
	jr IvDrawbar_ForwardUnhandled

IvDrawbar2_MatchCheck294:
	ld xix, xbc
	add xix, 0x8294
	ld wa, (xde)
	cp xix, (xhl)
	jr nz, IvDrawbar2_MatchCheck293
	st16_24 0x0247cc, xwa
	jr IvDrawbar_ForwardUnhandled

IvDrawbar2_MatchCheck293:
	add xbc, 0x8293
	cp xbc, (xhl)
	jr nz, IvDrawbar_ForwardUnhandled
	st16_24 0x0247ca, xwa

IvDrawbar_ForwardUnhandled:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)

IvDrawbar2_CallInherited:
	call InheritedProc
	jr IvDrawbar_ReturnZeroJmp

IvDrawbar2_OKHandler:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 4)
	cp xwa, 0x1
	jr nz, IvDrawbar_ReturnZeroJmp
	call GetModeNow
	cp xhl, 0x1800003
	jr z, IvDrawbar_ReturnZeroJmp
	ld16_24 xbc, 0x02479a
	extz xbc
	cpdi16_24 149404, 0
	scc16 z, wa
	extz wa
	add wa, 0xc00
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld xwa, 0x1400004
	ld xbc, 0x1e000a8

IvDrawbar2_MainFuncCallShared:
	call MainFuncCall
	jr IvDrawbar_ReturnZeroJmp

IvDrawbar2_GetText:
	pushw 0xe9
	pushw 0xf93c
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp

IvDrawbar_ReturnZeroJmp:
	lds32 xhl, 0
	jr IvDrawbar2_Epilogue

IvDrawbar2_ForwardToBase:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc

IvDrawbar2_Epilogue:
	pop xiz
	inc 8, xsp
	ret

IvDrawbarNormProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1e0003a
	jrl z, DrawbarNorm_GetText
	cp xiz, 0x1c0002f
	jrl z, DrawbarNorm_Refresh
	cp xiz, 0x1c0001c
	jrl z, DrawbarNorm_Match
	cp xiz, 0x1c0001b
	jrl z, DrawbarNorm_Notify
	cp xiz, 0x1e000a7
	jr z, DrawbarNorm_Update
	cp xiz, 0x1c0000d
	jr z, DrawbarNorm_Paint
	cp xiz, 0x1c0000c
	jr z, DrawbarNorm_ShowHide
	cp xiz, 0x1c0000b
	jrl nz, DrawbarNorm_ForwardToBase

DrawbarNorm_ShowHide:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 8)
	ld xbc, 0x1e000a7
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 8)
	ld xbc, 0x1e000a7
	lds32 xde, 4
	jrl IvDrawbarNorm_SendEvent

DrawbarNorm_Paint:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 8)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jrl IvDrawbarNorm_SendEvent

DrawbarNorm_Update:
	ld xwa, (xsp + 4)
	cp xwa, 0x4
	jr z, DrawbarNorm_UpdateCase4
	or xwa, xwa
	jrl nz, IvDrawbarNorm_ReturnZeroJmp
	ld xwa, 0x4003
	call SndParam_LookupReadOnly
	exts xhl
	ld xwa, 0xea0020
	ld xbc, 0x1e0003b
	ld xde, xhl
	jrl IvDrawbarNorm_SendEvent

DrawbarNorm_UpdateCase4:
	ld16_24 xwa, 0x02479a
	sla wa, 2
	lda_24 xbc, 0x03e9a0
	ld_sril3 XDE, 0x07, 0xe4, 0xe0
	ld xwa, 0xea001f
	ld xbc, 0x1c0000f
	jr IvDrawbarNorm_SendEvent

DrawbarNorm_Notify:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr nz, IvDrawbarNorm_ReturnZeroJmp
	ld xwa, 0x4003
	lds bc, 1
	lds de, 4
	call MainLswPut
	jr IvDrawbarNorm_ReturnZeroJmp

DrawbarNorm_Match:
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	cp xwa, 0x4003
	jr nz, DrawbarNorm_MatchForward
	ld xwa, (xsp + 8)
	ld xbc, 0x1e000a7
	lds32 xde, 0
	call SendEvent

DrawbarNorm_MatchForward:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	jr IvDrawbarNorm_ReturnZeroJmp

DrawbarNorm_Refresh:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	call GetPartSelect
	st16_24 0x02479a, xhl
	ld xwa, (xsp + 8)
	ld xbc, 0x1e000a7
	lds32 xde, 4

IvDrawbarNorm_SendEvent:
	call SendEvent
	jr IvDrawbarNorm_ReturnZeroJmp

DrawbarNorm_GetText:
	pushw 0xe9
	pushw 0xf942
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp

IvDrawbarNorm_ReturnZeroJmp:
	lds32 xhl, 0
	jr DrawbarNorm_Epilogue

DrawbarNorm_ForwardToBase:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc

DrawbarNorm_Epilogue:
	pop xiz
	inc 8, xsp
	ret

IvDrawbarSndEProc:
	push xiz
	ld xiz, xwa
	cp xbc, 0x1e0003a
	jr z, DrawbarSndE_GetText
	cp xbc, 0x1c0000d
	jr z, DrawbarSndE_Paint
	ld xwa, xiz
	call InheritedProc
	jr DrawbarSndE_Epilogue

DrawbarSndE_Paint:
	ld xwa, xiz
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	jr DrawbarSndE_ReturnZero

DrawbarSndE_GetText:
	pushw 0xe9
	pushw 0xf948
	push xde
	call Strcpy
	inc 8, xsp

DrawbarSndE_ReturnZero:
	lds32 xhl, 0

DrawbarSndE_Epilogue:
	pop xiz
	ret

DrawbarBitmapHelper:
	dec 4, xsp
	ld de, wa
	lda xwa, (xsp)
	ld hl, de
	add hl, hl
	lda_24 xix, 0xe9f94e
	ld_sriw3 HL, 0x07, 0xf0, 0xec
	ld (xwa), hl
	ldw (xwa + 2), 0x72
	sla de, 2
	lda_24 xhl, 0x03ec28
	ld_sril3 XDE, 0x07, 0xec, 0xe8
	sla bc, 2
	lda_24 xhl, 0xe9f960
	ld_sril3 XBC, 0x07, 0xec, 0xe4
	add xbc, xbc
	add xde, xbc
	pushw 0x75
	ld xbc, xde
	ldw de, 0x16
	call DrawBitmapSPFast
	inc 4, xsp
	ret

MainMemDrawControl:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xde
	cp xbc, 0x1e1000e
	jrl z, MemDraw_CheckVoiceState
	cp xbc, 0x1e10008
	jrl z, MemDraw_RestoreAll
	cp xbc, 0x1e1000a
	jr z, MemDraw_UpdateItem
	cp xbc, 0x1e10009
	jrl nz, DemoMenu_ReturnZero
	call GetPartSelect
	extz hl
	ld wa, hl
	call FDemoText_ProbeVoiceType
	cp l, 0xc
	jr z, MemDraw_InitParamLoop
	call GetPartSelect
	extz hl
	ld wa, hl
	call FDemoText_SendResetMessage
	ldw wa, 0xd
	lds bc, 0
	calr DemoMenu_BuildItemWorkspace
	ldw wa, 0xe
	lds bc, 0
	calr DemoMenu_BuildItemWorkspace
	ldw wa, 0xb
	lds bc, 0
	calr DemoMenu_BuildItemWorkspace
	ldw wa, 0xc
	lds bc, 0
	calr DemoMenu_BuildItemWorkspace
	jrl DemoMenu_ReturnZero

MemDraw_InitParamLoop:
	lds iz, 0

MemDraw_ParamLoopBody:
	ld wa, iz
	extz xwa
	add xwa, xwa
	ld xbc, 0xe9f88c
	add xbc, xwa
	ld wa, (xbc)
	extz xwa
	call SndParam_LookupReadOnly
	ld bc, hl
	ld wa, iz
	calr DemoMenu_BuildItemWorkspace
	inc 1, iz
	cp iz, 0xe
	jr ule, MemDraw_ParamLoopBody
	jr DemoMenu_ReturnZero

MemDraw_UpdateItem:
	ld xwa, (xsp + 2)
	srl xwa, 0
	ldi_werp 0xe2, 0
	ld xbc, (xsp + 2)
	calr DemoMenu_BuildItemWorkspace
	ld xwa, (xsp + 2)
	srl xwa, 0
	ldi_werp 0xe2, 0
	cp wa, 0x8
	jr ule, MemDraw_SendExtVoice
	call GetPartSelect
	extz hl
	ld wa, hl
	call FDemoText_SendExtParamsAlt
	jr DemoMenu_ReturnZero

MemDraw_SendExtVoice:
	call GetPartSelect
	extz hl
	ld wa, hl
	call FDemoText_SendExtVoiceParams
	jr DemoMenu_ReturnZero

MemDraw_RestoreAll:
	lds iz, 0

MemDraw_RestoreLoop:
	ld wa, iz
	calr DemoMenu_WorkspaceReturn
	ld bc, hl
	ld wa, iz
	calr DemoMenu_BuildItemWorkspace
	inc 1, iz
	cp iz, 0xe
	jr ule, MemDraw_RestoreLoop
	jr DemoMenu_ReturnZero

MemDraw_CheckVoiceState:
	ld xwa, (xsp + 2)
	extz wa
	call FDemoText_CheckVoiceState
	extz hl
	extz xhl
	ld xwa, (xsp + 2)
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xhl
	ld xwa, 0xffffffff
	ld xbc, 0x1c10008
	call ApPostEvent

DemoMenu_ReturnZero:
	lds32 xhl, 0
	popw iz
	inc 4, xsp
	ret

; =============================================================================
; DemoMenu_BuildItemWorkspace (0xf83cea)
; =============================================================================
; Allocates a 12-byte workspace for one demo menu item and posts it as an
; event 0x1c0001c parameter.
;
; Called in a loop for each of the ~15 demo menu items (iz = item index,
; wa = item type selector).  Each call:
;   1. Allocates a 12-byte workspace block from the firmware heap (FF0E80).
;   2. Reads the current "part select" index from DRAM address 0x8d3a via
;      GetPartSelect(), let R = that byte.
;   3. Computes workspace[0] = table[0xE9F88C + iz*2] + R*1024.
;      The table values are all in the 0x82xx--0x82cc range; this formula
;      CANNOT produce 0xb80a for any R.
;   4. Posts event 0x1c0001c (queued via PostEventWithParam/FA9D58) to
;      target 0xffffffff, with the workspace pointer as the event parameter.
;   5. Also posts event 0x1e00023 with the same workspace.
;
; NOTE: This queued-event path is DISTINCT from GroupBoxProc_StartSSFPresentation
; (0xf9a273), which sends 0x1c0001c via the direct SendEvent (FA9660) with a
; workspace byte-pattern of 0x0000b80a that passes AcPresentationControlProc's
; type-tag check. The path here (queued, wrong tag) never starts SSF playback.
; =============================================================================
DemoMenu_BuildItemWorkspace:
	dec 6, xsp
	pushw iz
	ld iz, bc
	ld (xsp + 6), wa
	pushw 0xc
	call Malloc
	inc 2, xsp
	ld (xsp + 2), xhl
	call GetPartSelect
	ld wa, hl
	extz xwa
	sll xwa, 10
	ld de, (xsp + 6)
	extz xde
	add xde, xde
	ld xbc, 0xe9f88c
	add xbc, xde
	ld hl, (xbc)
	extz xhl
	add xhl, xwa
	ld xwa, (xsp + 2)
	ld (xwa), xhl
	ld (xwa + 4), iz
	cpw (xsp + 6), 0x8
	jr ugt, DemoMenu_WorkspaceFunc
	ld xwa, 0x247ce
	add xwa, xde
	ld (xwa), iz
	jr DemoMenu_BuildItemWorkspace_Post

; DemoMenu workspace function
DemoMenu_WorkspaceFunc:
	ld wa, (xsp + 6)
	sub wa, 0x9
	cps wa, 0
	jr c, DemoMenu_BuildItemWorkspace_Post
	cps wa, 5
	jr ugt, DemoMenu_BuildItemWorkspace_Post
	add wa, wa
	lda_24 xix, 0xe9f984
	ld_sriw3 WA, 0x07, 0xf0, 0xe0
	lda_24 xix, DemoMenu_WorkspaceDispatch
	jp_dri 8, 0x07, 0xf0, 0xe0

; DemoMenu workspace dispatch (6-entry, table 0xe9f984)
DemoMenu_WorkspaceDispatch:
	st16_24	149472, iz
	jr	42
	st16_24	149474, iz
	jr	35
	st16_24	149476, iz
	jr	19
	st16_24	149478, iz
	jr	12
	st16_24	149480, iz
	jr	5
	st16_24	149482, iz
	ld	bc, (xbc)
	extz	xbc
	ld	xwa, (xsp+2)
	ld	(xwa), xbc

; Exit path for DemoMenu_BuildItemWorkspace: posts queued events 0x1c0001c
; and 0x1e00023 with the allocated workspace pointer, then returns.
DemoMenu_BuildItemWorkspace_Post:
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001c
	ld xde, (xsp + 2)
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e00023
	ld xde, (xsp + 2)
	call ApPostEvent
	popw iz
	inc 6, xsp
	ret

; DemoMenu workspace return
DemoMenu_WorkspaceReturn:
	cp wa, 0x8
	jr ugt, DemoMenu_DescriptorFunc
	extz xwa
	add xwa, xwa
	ld xbc, 0x247ce
	add xbc, xwa
	ld hl, (xbc)
	ret

; DemoMenu descriptor function
DemoMenu_DescriptorFunc:
	sub wa, 0x9
	cps wa, 0
	jr c, DemoMenu_DescriptorReturn
	cps wa, 5
	jr ugt, DemoMenu_DescriptorReturn
	add wa, wa
	lda_24 xix, 0xe9f990
	ld_sriw3 WA, 0x07, 0xf0, 0xe0
	lda_24 xix, DemoDesc_DispatchTable
	jp_dri 8, 0x07, 0xf0, 0xe0

DemoDesc_DispatchTable:
	ld16_24	hl, 149472
	ret
	ld16_24	hl, 149474
	ret
	ld16_24	hl, 149476
	ret
	ld16_24	hl, 149478
	ret
	ld16_24	hl, 149480
	ret
	ld16_24	hl, 149482
	ret

; DemoMenu descriptor return
DemoMenu_DescriptorReturn:
	lds hl, 0
	ret

DemoDesc_BuildCompactParams:
	ld16_24 xbc, 0x0247e6
	sla bc, 4
	addda16_24 xbc, 149476
	ld (xwa), c
	ld16_24 xbc, 0x0247ea
	sla bc, 4
	addda16_24 xbc, 149480
	ld (xwa + 1), c
	lda_24 xbc, 0x0247ce
	ld de, (xbc + 4)
	sla de, 4
	add de, (xbc)
	ld (xwa + 2), e
	ld de, (xbc + 6)
	sla de, 4
	add de, (xbc + 2)
	ld (xwa + 3), e
	ld de, (xbc + 10)
	sla de, 4
	add de, (xbc + 8)
	ld (xwa + 4), e
	ld de, (xbc + 14)
	sla de, 4
	add de, (xbc + 12)
	ld (xwa + 5), e
	ld16_24 xde, 0x0247e2
	sla de, 4
	add de, (xbc + 16)
	ld16_24 xbc, 0x0247e0
	sla bc, 5
	add bc, de
	ld (xwa + 6), c
	ret

DemoDesc_DataByte:
	ret

PsVariBoxProc:
	st_dri3b L, 0xfd, 0xe8, 0xfe
	push xiz
	st_dri3l XDE, 0xfd, 0x14, 0x01
	ld xiz, xbc
	st_dri3l XWA, 0xfd, 0x18, 0x01
	cp xiz, 0x1e0003c
	jrl z, PsVari_CheckDirty
	cp xiz, 0x1c0001b
	jrl z, PsVari_Notify
	cp xiz, 0x1c00007
	jrl z, PsVari_OK
	cp xiz, 0x1e0003a
	jrl z, PsVari_GetText
	cp xiz, 0x1c0000f
	jrl z, PsVari_Confirm
	cp xiz, 0x1c0000d
	jr z, PsVari_Paint
	cp xiz, 0x1e0004d
	jrl nz, PsVari_ForwardToBase
	ld_sril XWA, (xsp + 0x0118)
	call GetViewInstance
	lda xwa, (xhl + 38)
	ld xbc, (xwa)
	ld bc, (xbc)
	exts xbc
	cp_sril_rm XBC, 0xfd, 0x14, 0x01
	jrl z, AudioView_ReturnZeroJmp
	ld xbc, (xwa)
	ld_sril XWA, (xsp + 0x0114)
	ld (xbc), wa
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, 0x1c0000d
	lds32 xde, 0
	jrl AudioView_SendEventCall

PsVari_Paint:
	ld_sril XWA, (xsp + 0x0118)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 38)
	cpw (xwa), 0x0
	jr z, PsVari_PaintEmpty
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0114)
	call InheritedProc
	jr PsVari_DrawEditSw

PsVari_PaintEmpty:
	st_dri3b A, 0xfd, 0x08, 0x01
	ld_sril XWA, (xsp + 0x0118)
	call GetBox
	st_dri3b W, 0xfd, 0x08, 0x01
	ldw bc, 0xf5
	call DrawBox

PsVari_DrawEditSw:
	ld xwa, (xsp + 4)
	ld wa, (xwa + 36)
	call DrawEditSw
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jrl AudioView_SendEventCall

PsVari_Confirm:
	ld_sril XWA, (xsp + 0x0118)
	call GetViewInstance
	ld (xsp + 4), xhl
	st_dri3b A, 0xfd, 0x08, 0x01
	ld_sril XWA, (xsp + 0x0118)
	call GetClientBox
	st_dri3b W, 0xfd, 0x08, 0x01
	st_dri3b A, 0xfd, 0x10, 0x01
	call GetBoxCenter
	lda xde, (xsp + 8)
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, 0x1e0003a
	call SendEvent
	ld xwa, (xsp + 4)
	ld xiz, (xwa + 38)
	st_dri3b A, 0xfd, 0x10, 0x01
	st_dri3b B, 0xfd, 0x08, 0x01
	lda xhl, (xsp + 8)
	lda xiy, (xwa + 28)
	ld a, (xwa + 34)
	ldfr_berp A, 0xf0
	extz ix
	cpw (xiz), 0x0
	jr z, PsVari_DrawInactive
	ld xwa, (xiy)
	push xwa
	ld xwa, (xsp + 8)
	pushm (xwa + 32)
	pushw 0xf7
	pushw ix
	ld xwa, xde
	ld xde, xhl
	jr PsVari_DrawStringCall

PsVari_DrawInactive:
	ld xwa, (xiy)
	push xwa
	pushw 0xff
	pushw 0xf7
	pushw ix
	ld xwa, xde
	ld xde, xhl

PsVari_DrawStringCall:
	call DrawStringAlignment

AudioView_ReturnZeroJmp:
	lds32 xhl, 0
	jrl PsVari_Epilogue

PsVari_GetText:
	ld_sril XWA, (xsp + 0x0118)
	call GetViewInstance
	pushm (xhl + 36)
	pushw 0xe9
	pushw 0xf99c
	ld_sril XWA, (xsp + 0x011a)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	jr AudioView_ReturnZeroJmp

PsVari_OK:
	ld_sril XWA, (xsp + 0x0118)
	call GetViewInstance
	ld wa, (xhl + 36)
	extz xwa
	cp_sril_rm XWA, 0xfd, 0x14, 0x01
	jr nz, PsVari_OKForward
	ld de, (xhl + 26)
	cp de, 0xffff
	jr z, PsVari_OKForward
	exts xde
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001b
	call SendEvent
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, 0x1e0004d
	lds32 xde, 1
	jr AudioView_SendEventCall

PsVari_OKForward:
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0114)
	jr PsVari_CallInherited

PsVari_Notify:
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0114)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0118)
	call GetViewInstance
	ld wa, (xhl + 26)
	exts xwa
	cp_sril_rm XWA, 0xfd, 0x14, 0x01
	jrl nz, AudioView_ReturnZeroJmp
	ld xwa, (xhl + 38)
	cpw (xwa), 0x0
	jrl z, AudioView_ReturnZeroJmp
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, 0x1e0004d
	lds32 xde, 0

AudioView_SendEventCall:
	call SendEvent
	jrl AudioView_ReturnZeroJmp

PsVari_CheckDirty:
	ld_sril XWA, (xsp + 0x0118)
	call GetViewInstance
	ld wa, (xhl + 26)
	exts xwa
	cp_sril_rm XWA, 0xfd, 0x14, 0x01
	jrl nz, AudioView_ReturnZeroJmp
	ld xwa, (xhl + 38)
	cpw (xwa), 0x1
	jrl nz, AudioView_ReturnZeroJmp
	lds32 xhl, 1
	jr PsVari_Epilogue

PsVari_ForwardToBase:
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0114)

PsVari_CallInherited:
	call InheritedProc

PsVari_Epilogue:
	pop xiz
	st_dri3b L, 0xfd, 0x18, 0x01
	ret


VwUserBitmapSpProc:
	lda xsp, (xsp - 10)
	push xiz
	cp xbc, 0x1c0000d
	jr z, UserBitmapSp_Paint
	call InheritedProc
	jr UserBitmapSp_Epilogue

UserBitmapSp_Paint:
	call GetViewInstance
	ld xiz, xhl
	lda xbc, (xsp + 10)
	ld wa, (xiz + 14)
	ld (xbc), wa
	ld wa, (xiz + 16)
	ld (xbc + 2), wa
	ld xwa, (xiz + 22)
	ld xbc, 0x1e000a1
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 6), xhl
	ld xwa, (xsp + 6)
	or xwa, xwa
	jr z, UserBitmapSp_DrawEmpty
	ld xwa, (xiz + 22)
	ld xbc, 0x1e000a2
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 4), hl
	ld xwa, (xiz + 22)
	ld xbc, 0x1e000a3
	lds32 xde, 0
	call ApFuncCall
	lda xwa, (xsp + 10)
	pushw hl
	ld xbc, (xsp + 8)
	ld de, (xsp + 6)
	call DrawBitmapSP
	jr UserBitmapSp_ReturnZero

UserBitmapSp_DrawEmpty:
	lda xwa, (xsp + 10)
	lds32 xbc, 0
	call DrawBitmap

UserBitmapSp_ReturnZero:
	lds32 xhl, 0

UserBitmapSp_Epilogue:
	pop xiz
	lda xsp, (xsp + 10)
	ret

AcFdemoScreenProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1c00001
	jr z, FdemoScreen_Init
	ld xwa, 0x1210028
	ld xbc, xiz
	ld xde, (xsp + 4)
	call ApFuncCall
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	jr FdemoScreen_Epilogue

FdemoScreen_Init:
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr nz, FdemoScreen_InitForward
	ld xwa, 0x120000b
	ld xbc, 0x1e000ac
	lds32 xde, 0
	call ApFuncCall
	call FDemo_IndicatorSetup
	ld xwa, 0x120000b
	ld xbc, 0x1e000ad
	lds32 xde, 0
	call ApFuncCall

FdemoScreen_InitForward:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr nz, FdemoScreen_ReturnZero
	ld xwa, 0x1210028
	ld xbc, 0x1e1000b
	lds32 xde, 0
	call ApFuncCall
	or xhl, xhl
	jr z, FdemoScreen_StartPanel2
	ld xwa, 0xe40005
	ld xbc, 0x1c00001
	lds32 xde, 5
	jr FdemoScreen_SendStart

FdemoScreen_StartPanel2:
	ld xwa, 0xe40002
	ld xbc, 0x1c00001
	lds32 xde, 5

FdemoScreen_SendStart:
	call SendEvent

FdemoScreen_ReturnZero:
	lds32 xhl, 0

FdemoScreen_Epilogue:
	pop xiz
	inc 8, xsp
	ret

IvDemofeature1Proc:
	push xiz
	ld xiz, xwa
	cp xbc, 0x1e0003a
	jr z, Demofeat1_GetText
	cp xbc, 0x1c0000d
	jr z, Demofeat1_Paint
	ld xwa, xiz
	call InheritedProc
	jr Demofeat1_Epilogue

Demofeat1_Paint:
	ld xwa, xiz
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	jr Demofeat1_ReturnZero

Demofeat1_GetText:
	pushw 0xe9
	pushw 0xf9a6
	push xde
	call Strcpy
	inc 8, xsp

Demofeat1_ReturnZero:
	lds32 xhl, 0

Demofeat1_Epilogue:
	pop xiz
	ret

IvDemofeature2Proc:
	push xiz
	ld xiz, xwa
	cp xbc, 0x1e0003a
	jr z, Demofeat2_GetText
	cp xbc, 0x1c0000d
	jr z, Demofeat2_Paint
	cp xbc, 0x1c0000c
	jr z, Demofeat2_ShowHide
	cp xbc, 0x1c0000b
	jr z, Demofeat2_ShowHide
	cp xbc, 0x1c00001
	jr z, Demofeat2_Init
	ld xwa, xiz
	call InheritedProc
	jr Demofeat2_Epilogue

Demofeat2_Init:
	ld xwa, xiz
	call InheritedProc
	jr Demofeat2_ReturnZero

Demofeat2_ShowHide:
	ld xwa, xiz
	call InheritedProc
	ld xwa, 0x1210028
	ld xbc, 0x1e0003a
	lds32 xde, 0
	call ApFuncCall
	ld xde, xhl
	ld xwa, 0xe40008
	ld xbc, 0x1c0000f
	jr Demofeat2_SendEvent

Demofeat2_Paint:
	ld xwa, xiz
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1c0000f
	lds32 xde, 0

Demofeat2_SendEvent:
	call SendEvent
	jr Demofeat2_ReturnZero

Demofeat2_GetText:
	pushw 0xe9
	pushw 0xf9ac
	push xde
	call Strcpy
	inc 8, xsp

Demofeat2_ReturnZero:
	lds32 xhl, 0

Demofeat2_Epilogue:
	pop xiz
	ret

AcPresentationBoxProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld xiz, xbc
	ld (xsp + 12), xwa
	cp xiz, 0x1e0003c
	jrl z, AcPresCtrl_Case0
	cp xiz, 0x1e0003a
	jrl z, PresBox_GetText
	cp xiz, 0x1c0001b
	jrl z, PresBox_Notify
	cp xiz, 0x1c10006
	jrl z, PresBox_TimerTick
	cp xiz, 0x1c10005
	jrl z, PresBox_TimerExpired
	cp xiz, 0x1c00007
	jrl z, PresBox_OK
	cp xiz, 0x1e0004d
	jrl z, PresBox_HandleWidget
	cp xiz, 0x1c0000e
	jr z, PresBox_Select
	cp xiz, 0x1c0000d
	jr z, PresBox_Paint
	cp xiz, 0x1c00001
	jrl nz, AcPresCtrl_Case1
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xwa, (xhl + 42)
	ldw (xwa), 0x0
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc

AudioCtrl_ReturnZeroJmp:
	lds32 xhl, 0
	jrl AcPresCtrl_Case3

PresBox_Paint:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld wa, (xhl + 40)
	call DrawEditSw
	ld xwa, (xsp + 12)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 12)
	ld xbc, 0x1c0000e
	lds32 xde, 0
	jrl AcAudio_SendEvent_Continue

PresBox_Select:
	ld xwa, (xsp + 12)
	call GetViewInstance
	cpw (xhl + 40), 0xff
	jr z, AudioCtrl_ReturnZeroJmp
	ld xwa, (xhl + 42)
	ld de, (xwa)
	exts xde
	ld xwa, (xsp + 12)
	ld xbc, 0x1e0004e
	jrl AcAudio_SendEvent_Continue

PresBox_HandleWidget:
	ld xwa, (xsp + 12)
	call GetViewInstance
	lda xwa, (xhl + 42)
	ld xbc, (xwa)
	ld bc, (xbc)
	exts xbc
	cp xbc, (xsp + 8)
	jr z, AudioCtrl_ReturnZeroJmp
	ld xbc, (xwa)
	ld xwa, (xsp + 8)
	ld (xbc), wa
	ld xwa, (xsp + 12)
	ld xbc, 0x1c0000e
	lds32 xde, 0
	jrl AcAudio_SendEvent_Continue

PresBox_OK:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld wa, (xwa + 40)
	extz xwa
	cp xwa, (xsp + 8)
	jr nz, PresBox_OKForward
	ld xwa, 0x120000b
	ld xbc, 0x1e000ac
	lds32 xde, 0
	call ApFuncCall
	ld xwa, (xsp + 4)
	ld wa, (xwa + 46)
	stda8 10404, a
	call Demo_SelectEntry_ProcessSongList
	ld xwa, 0x120000b
	ld xbc, 0x1e000ad
	lds32 xde, 0
	call ApFuncCall
	jrl AudioCtrl_ReturnZeroJmp

PresBox_OKForward:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	jrl AcPresCtrl_Case2

PresBox_TimerExpired:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld wa, (xhl + 46)
	exts xwa
	cp xwa, (xsp + 8)
	jrl nz, AudioCtrl_ReturnZeroJmp
	ld de, (xhl + 26)
	exts xde
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001b
	call SendEvent
	ld xwa, (xsp + 12)
	ld xbc, 0x1e0004d
	lds32 xde, 1
	call SendEvent
	ld xwa, 0xe4000a
	ld xbc, 0x1c00001
	lds32 xde, 5
	call PostEvent
	jrl AudioCtrl_ReturnZeroJmp

PresBox_TimerTick:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld wa, (xhl + 46)
	exts xwa
	cp xwa, (xsp + 8)
	jrl nz, AudioCtrl_ReturnZeroJmp
	ld de, (xhl + 26)
	exts xde
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001b
	jr AcAudio_SendEvent_Continue

PresBox_Notify:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld wa, (xhl + 26)
	exts xwa
	cp xwa, (xsp + 8)
	jrl nz, AudioCtrl_ReturnZeroJmp
	ld xwa, (xhl + 42)
	cpw (xwa), 0x0
	jrl z, AudioCtrl_ReturnZeroJmp
	ld xwa, (xsp + 12)
	ld xbc, 0x1e0004d
	lds32 xde, 0

AcAudio_SendEvent_Continue:
	call SendEvent
	jrl AudioCtrl_ReturnZeroJmp

PresBox_GetText:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xwa, (xhl + 36)
	push xwa
	ld xwa, (xsp + 12)
	push xwa
	call Strcpy
	inc 8, xsp
	jrl AudioCtrl_ReturnZeroJmp

; AcPresCtrl event case 0
AcPresCtrl_Case0:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld wa, (xhl + 26)
	exts xwa
	cp xwa, (xsp + 8)
	jrl nz, AudioCtrl_ReturnZeroJmp
	ld xwa, (xhl + 42)
	cpw (xwa), 0x1
	jrl nz, AudioCtrl_ReturnZeroJmp
	lds32 xhl, 1
	jr AcPresCtrl_Case3

; AcPresCtrl event case 1
AcPresCtrl_Case1:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)

; AcPresCtrl event case 2
AcPresCtrl_Case2:
	call InheritedProc

; AcPresCtrl event case 3
AcPresCtrl_Case3:
	pop xiz
	lda xsp, (xsp + 12)
	ret

AcPresentationControlProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld xiz, xwa
	ld xbc, (xsp + 8)
	cp xbc, 0x1c0001c
	jrl z, AcPresentCtrl_CheckSSFStart
	ld xwa, (xsp + 8)
	cp xwa, 0x1c10006
	jrl z, AcPresCtrl_Case5
	cp xwa, 0x1c10005
	jrl z, AcPresCtrl_Case4
	sub xbc, 0x1c00002
	cp xbc, 0x0
	jrl lt, AcPresCtrl_DefaultCase
	cp xbc, 0xa
	jrl gt, AcPresCtrl_DefaultCase
	add xbc, xbc
	add xbc, 0xe9f9b2
	ld bc, (xbc)
	lda_24 xix, AcPresCtrl_EventDispatch
	jp_dri 8, 0x07, 0xf0, 0xe4
; AcPresentationControlProc event dispatch (11-entry, table 0xe9f9b2)
AcPresCtrl_EventDispatch:
	; --- AcPresentationControlProc jump table handler body ---
	; Handles events 0x1c00002-0x1c0000c via jump table at 0xe9f9b2.
	; Dispatches presentation control events: start, register handlers,
	; broadcast state changes.
	ld xwa, xiz				; workspace
	ld xbc, (xsp + 8)			; event code
	ld xde, (xsp + 4)			; event param
	call InheritedProc				; forward event to handler
	call GetModeNow				; additional processing
	cp xhl, 0x01800013			; check return code
	jrl z, AcPresent_ReturnZeroJmp			; matched -- exit
	lds	wa, 2
	jr AcPresCtrl_ChangePalette				; skip to call FAF2C7
	ld xwa, 0x02600024			; workspace for SendEvent
	ld xbc, 0x01e00029			; presentation control event
	ld xde, (xsp + 4)			; event param
	call SendEvent				; SendEvent (direct)
	cp hl, 0x000f				; check result count
	jrl nz, AcPresent_ReturnZeroJmp			; exit if not 0x0f
	ld xwa, 0x0120000b			; register event handler workspace
	ld xbc, 0x01e000ac			; register event code AC
	lds32	xde, 0
	call ApFuncCall				; register event handler
	call Demo_SelectionEntryHandler				; additional presentation setup
	ld xwa, 0x0120000b
	ld xbc, 0x01e000ad			; register event code AD
	lds32	xde, 0
	call ApFuncCall				; register event handler
	ld xwa, 0xffffffff			; broadcast target
	ld xbc, 0x01c00015			; presentation state event
	ld xde, 0x01a000e0			; event param
	call PostEvent				; dispatch event
	lds	wa, 2
AcPresCtrl_ChangePalette:
	call ChangePalette				; presentation helper
	jrl AcPresent_ReturnZeroJmp			; exit


; AcPresCtrl event case 4
AcPresCtrl_Case4:
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, 0x1210028
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call ApFuncCall
	jrl AcPresent_ReturnZeroJmp

; AcPresCtrl event case 5
AcPresCtrl_Case5:
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, 0x1210028
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call ApFuncCall
	lds wa, 2
	call ChangePalette
	ld xwa, 0xe40000
	ld xbc, 0x1c00001
	lds32 xde, 0
	jr AcPresCtrl_SendEventReturn

; Handler for event 0x1c0001c within AcPresentationControlProc.
; Checks the workspace type-tag: *(XDE) must equal 0x0000b80a for SSF to start.
; If the check passes, sends event 0x1c00006 to begin SSF presentation parsing.
; If it fails (wrong type-tag), the SSF system never starts and no demo images appear.
;
; MAME investigation (Feb 2026): this check ALWAYS fails because the workspace
; value 0x0000b80a is only produced by GroupBoxProc_StartSSFPresentation (FA9660
; direct path), which is not reached during Feature Demo navigation in MAME.
; The events that DO arrive here come from DemoMenu_BuildItemWorkspace (queued via
; FA9D58), whose workspace values are in the 0x82xx-range and never equal 0xb80a.
AcPresentCtrl_CheckSSFStart:
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	ld xbc, (xsp + 4)
	ld xwa, (xbc)
	cp xwa, 0xb80a
	jr nz, AcPresent_ReturnZeroJmp
	ld de, (xbc + 4)
	exts xde
	ld xwa, xiz
	ld xbc, 0x1c00006

AcPresCtrl_SendEventReturn:
	call SendEvent
	jr AcPresent_ReturnZeroJmp
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	sti16_24 0x0340fc, 0x0000
	sti16_24 0x0340fa, 0x0000
	sti16_24 0x0340fe, 0x0000
	ld xwa, 0x1210028
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call ApFuncCall
	ldw wa, 0x8
	call Audio_DispatchCommand

AcPresent_ReturnZeroJmp:
	lds32 xhl, 0
	jr AcPresCtrl_Epilogue

; AcPresCtrl default case
AcPresCtrl_DefaultCase:
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc

AcPresCtrl_Epilogue:
	pop xiz
	inc 8, xsp
	ret

Seq_DispatchEventType5:
	ld de, wa
	exts xde
	ld xwa, 0xffffffff
	ld xbc, 0x1c10005
	jp ApPostEvent

Seq_DispatchEventType6:
	ld de, wa
	exts xde
	ld xwa, 0xffffffff
	ld xbc, 0x1c10006
	jp ApPostEvent

Seq_StartMainControl:
	ld xwa, 0x1410000
	ld xbc, 0x1e1000c
	lds32 xde, 0
	jp MainPreControl

Seq_StartMainControlAlt:
	ld xwa, 0x1410000
	ld xbc, 0x1e1000d
	lds32 xde, 0
	jp MainPreControl

Seq_IsMelodyActive:
	ld xwa, 0x1410000
	ld xbc, 0x1e1000b
	lds32 xde, 0
	jp MainPreControl

	.include "demo/fdemotext_routines.s"
