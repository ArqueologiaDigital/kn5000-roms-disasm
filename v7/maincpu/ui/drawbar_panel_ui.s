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
	ld xiy, NakaData_ModeConfig1_0x4
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
	.incbin "includes/generated/v7_transplant_AcSendEditSw_EventD.bin"
AcSendEditSw_DrawAlt:
	lds32 xbc, 0
	push xbc
	pushw 0x0
	pushw 0xf7
	ld xbc, UserMemory_FormatStrings_0xD6

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
	ld xiy, NakaData_ModeConfig2_0x2C
	lda xix, (xsp + 12)
	lds bc, 5
	ldirw
	ld xiy, MidiPart_PageStr_1of3_0xA
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
	add xwa, NakaInst_GM_0x50
	ld wa, (xwa)
	lda_24 xix, (ComSetGridCheck_JumpTable)
	jp_ind 8, 0x07, 0xf0, 0xe0

ComSetGridCheck_JumpTable:
	.incbin "includes/generated/v7_transplant_ComSetGridCheck_JumpTable.bin"
ComSetGrid_EventHandler:
	lda xde, (xsp + 4)
	ld xwa, (xsp + 22)
	srl xwa, 0
	ldiw_erp 0xe2, 0
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
	lda_24 xbc, (NakaData_ModeConfig2_0x8)
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
	.incbin "includes/generated/v7_transplant_ComSetGridCheck_ParamDisplay.bin"
ComSetGrid_CopyStrAndDispatch:
	.incbin "includes/generated/v7_transplant_ComSetGrid_CopyStrAndDispatch.bin"
ComSetGrid_CheckC0Param:
	.incbin "includes/generated/v7_transplant_ComSetGrid_CheckC0Param.bin"
ComSetGrid_LookupByColumn:
	.incbin "includes/generated/v7_transplant_ComSetGrid_LookupByColumn.bin"
ComSetGrid_ParamStr1:
	ld xwa, NakaInst_GM_0x32
	jr UI_DisplayStringAndDispatchEvent

ComSetGrid_ParamStr3:
	ld xwa, NakaInst_GM_0x3C
	jr UI_DisplayStringAndDispatchEvent

ComSetGrid_ParamStrDefault:
	ld xwa, NakaInst_GM_0x46

UI_DisplayStringAndDispatchEvent:
	.incbin "includes/generated/v7_transplant_UI_DisplayStringAndDispatchEvent.bin"
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
	add xbc, NakaInst_GM_0x5E
	ld bc, (xbc)
	lda_24 xix, (AcPmemOutL_Init)
	jp_ind 8, 0x07, 0xf0, 0xe4

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
	.incbin "includes/generated/v7_transplant_AcPmemOutL_CopyText.bin"
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
	add xbc, NakaInst_GM_0x6C
	ld bc, (xbc)
	lda_24 xix, (AcPmemOutR_Init)
	jp_ind 8, 0x07, 0xf0, 0xe4

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
	.incbin "includes/generated/v7_transplant_AcPmemOutR_CopyText.bin"
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
	ld xiy, NakaInst_2d_d_0x7
	lda xix, (xsp + 44)
	ldw bc, 0x8
	ldirw
	ld xiy, MidiPart_PageStr_1of3_0xA
	lda xix, (xsp + 36)
	lds bc, 4
	ldirw
	ld xix, xde
	lda_24 xwa, (NakaInst_NEXT_E800E8_0x2)
	ld (xsp + 8), xwa
	lda xbc, (xsp + 36)
	lda_24 xwa, (0x1ed400)
	ld (xsp + 24), xwa
	lda_d16 xwa, (0xf9a0)
	ld (xsp + 20), xwa
	lda_d16 xwa, (0xfd2c)
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
	add xwa, NakaInst_ON_E80168_0x5E
	ld wa, (xwa)
	lda_24 xix, (PmemOutLGridCheck_JumpTable)
	jp_ind 8, 0x07, 0xf0, 0xe0

PmemOutLGridCheck_JumpTable:
	.incbin "includes/generated/v7_transplant_PmemOutLGridCheck_JumpTable.bin"
PmemOutL_GridCheck:
	.incbin "includes/generated/v7_transplant_PmemOutL_GridCheck.bin"
PmemOutL_BitCheckDisplay:
	lds32 xwa, 0
	ldb_da a, (0x024772)
	ld xbc, xwa
	sll xbc, 4
	sub xbc, xwa
	sll xbc, 6
	ld xwa, (xsp + 24)
	add xwa, xbc
	add xwa, (xsp + 32)
	bitm 1, (xwa)
	jr z, PmemOutL_LoadOffStr
	ld xwa, NakaInst_ON_E80168_0x52
	jr PmemOutL_StrCopyAndDispatch

PmemOutL_LoadOffStr:
	ld xwa, NakaInst_ON_E80168_0x58

PmemOutL_StrCopyAndDispatch:
	.incbin "includes/generated/v7_transplant_PmemOutL_StrCopyAndDispatch.bin"
PmemOutL_ColumnParamDisplay:
	.incbin "includes/generated/v7_transplant_PmemOutL_ColumnParamDisplay.bin"
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
	ld xiy, NakaInst_ON_E80168_0x82
	lda xix, (xsp + 40)
	ldw bc, 0x8
	ldirw
	ld xiy, MidiPart_PageStr_1of3_0xA
	lda xix, (xsp + 32)
	lds bc, 4
	ldirw
	ld xhl, xde
	lda xbc, (xsp + 32)
	lda_d16 xwa, (0xf9b6)
	ld (xsp + 20), xwa
	lda_24 xwa, (0x1ed400)
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
	add xhl, NakaInst_ON_E80168_0x10A
	ld hl, (xhl)
	lda_24 xix, (TtMdCtlMsg_EventDispatch)
	jp_ind 8, 0x07, 0xf0, 0xec
; TtMdCtlMsg event dispatch (7-entry, table 0xe80272)

; -----------------------------------------------------------------------------
; Section: Control Message Dispatch
; -----------------------------------------------------------------------------
; MIDI control message event dispatch, grid box
; event handling, and message routing.
; -----------------------------------------------------------------------------

TtMdCtlMsg_EventDispatch:
	.incbin "includes/generated/v7_transplant_TtMdCtlMsg_EventDispatch.bin"
CtlMsgGrid_EventHandler:
	.incbin "includes/generated/v7_transplant_CtlMsgGrid_EventHandler.bin"
CtlMsg_SendAudioCommand:
	.incbin "includes/generated/v7_transplant_CtlMsg_SendAudioCommand.bin"
CtlMsg_GetFocusAndDispatch:
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 32)
	ld xbc, 0x1e0008c
	jrl CtlMsg_SendEventReturn

CtlMsg_ReadOffsetAndSend:
	.incbin "includes/generated/v7_transplant_CtlMsg_ReadOffsetAndSend.bin"
CtlMsg_ComputeAndCheck:
	.incbin "includes/generated/v7_transplant_CtlMsg_ComputeAndCheck.bin"
CtlMsg_SendParamValue:
	.incbin "includes/generated/v7_transplant_CtlMsg_SendParamValue.bin"
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
	stib_da (0x024776), 0x00
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
	ld xiy, NakaInst_ON_E80168_0x11A
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
	add xbc, NakaInst_ON_E80168_0x210
	ld bc, (xbc)
	lda_24 xix, (AcCtlMsgGrid_Init)
	jp_ind 8, 0x07, 0xf0, 0xe4

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
	ldb_da a, (0x024776)
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
	ldiw_erp 0xe2, 0
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
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 32)
	ld xbc, 0x1c00018
	call SetDialDown
	lds wa, 1
	jrl AcCtlMsgGrid_ScrollCommit

AcCtlMsgGrid_Show:
	.incbin "includes/generated/v7_transplant_AcCtlMsgGrid_Show.bin"
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
	stb_da (0x024776), a
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
	stb_da (0x024776), a
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
	stb_da (0x024776), a
	ld xwa, (xsp + 32)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 74)
	lda_24 xbc, (NakaInst_ON_E80168_0x118)
	ld wa, (xwa)
	ldb_sri A, 0x07, 0xe4, 0xe0
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
	lda_24 xhl, (NakaInst_ON_E80168_0x118)
	ld wa, (xbc)
	ldb_sri A, 0x07, 0xec, 0xe0
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
	stb_da (0x024776), a
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
	ld xwa, NakaInst_ON_E80168_0x12A
	jr AcCtlMsgGrid_GetRowText_Push

AcCtlMsgGrid_GetRowText_Page1:
	ld xwa, NakaInst_ON_E80168_0x1A6

AcCtlMsgGrid_GetRowText_Push:
	push xwa

AcCtlMsgGrid_GetRowText_Strcpy:
	.incbin "includes/generated/v7_transplant_AcCtlMsgGrid_GetRowText_Strcpy.bin"
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
	ld xiy, NakaInst_ON_E80168_0x266
	lda xix, (xsp + 20)
	lds bc, 5
	ldirw
	ld xiy, MidiPart_PageStr_1of3_0xA
	lda xix, (xsp + 12)
	lds bc, 4
	ldirw
	ld xix, xde
	lda xhl, (xsp + 12)
	lda_24 xwa, (NakaInst_ON_E80168_0x21E)
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
	add xwa, NakaInst_ON_E80168_0x288
	ld wa, (xwa)
	lda_24 xix, (CtlMsgGridCheck_JumpTable)
	jp_ind 8, 0x07, 0xf0, 0xe0

CtlMsgGridCheck_JumpTable:
	.incbin "includes/generated/v7_transplant_CtlMsgGridCheck_JumpTable.bin"
MidiSetup_TtlDispatch:
	.incbin "includes/generated/v7_transplant_MidiSetup_TtlDispatch.bin"
MidiSetup_CopyStrAndDispatch:
	.incbin "includes/generated/v7_transplant_MidiSetup_CopyStrAndDispatch.bin"
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
	stib_da (0x024778), 0x00
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
	ld xiy, NakaInst_ON_E80168_0x2DE
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
	add xbc, NakaInst_ON_E80168_0x3AA
	ld bc, (xbc)
	lda_24 xix, (MidiSetup_TtlCase3)
	jp_ind 8, 0x07, 0xf0, 0xe4

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
	ldb_da a, (0x024778)
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
	ldiw_erp 0xe2, 0
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
	ldiw_erp 0xe2, 0
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
	.incbin "includes/generated/v7_transplant_MidiSetup_TtlCase4.bin"
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
	stb_da (0x024778), a
	ld xwa, (xsp + 32)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 32)
	ld xbc, 0x1e0008e
	ld xde, 0xffff0002
	call SendEvent
	ldb_da a, (0x024778)
	extz wa
	muls wa, 0xa
	lda_24 xbc, (NakaInst_ON_E80168_0x298)
	lds32 xde, 0
	ldb_sri E, 0x07, 0xe4, 0xe0
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
	stb_da (0x024778), a
	ld xwa, (xsp + 32)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 32)
	ld xbc, 0x1e0008e
	ld xde, 0xffff0002
	call SendEvent
	ldb_da a, (0x024778)
	extz wa
	muls wa, 0xa
	lda_24 xbc, (NakaInst_ON_E80168_0x298)
	lds32 xde, 0
	ldb_sri E, 0x07, 0xe4, 0xe0
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
	stb_da (0x024778), a
	ld xwa, (xsp + 32)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 74)
	lda_24 xbc, (NakaInst_ON_E80168_0x2DA)
	ld wa, (xwa)
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	ld de, wa
	extz xde
	add xde, 0xffff0000
	ld xwa, (xsp + 32)
	ld xbc, 0x1e0008e
	call SendEvent
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 74)
	lda_24 xbc, (NakaInst_ON_E80168_0x2DA)
	ld wa, (xwa)
	ldb_sri C, 0x07, 0xe4, 0xe0
	extz bc
	ldb_da a, (0x024778)
	extz wa
	muls wa, 0xa
	add wa, bc
	lda_24 xbc, (NakaInst_ON_E80168_0x296)
	lds32 xde, 0
	ldb_sri E, 0x07, 0xe4, 0xe0
	ld xwa, 0x1400002
	ld xbc, 0x1e000a0
	call MainFuncCall
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	jrl MidiPartAutoIncReturn

MidiPart_Part2ColumnNav:
	cpib_da (0x024778), 0x02
	jr nz, MidiPart_GenericColumnNav
	ld wa, iz
	add wa, wa
	lda_24 xbc, (NakaInst_ON_E80168_0x2B4)
	ldw_sri WA, 0x07, 0xe4, 0xe0
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
	lda_24 xbc, (NakaInst_ON_E80168_0x2B4)
	ldw_sri WA, 0x07, 0xe4, 0xe0
	ld bc, iz
	sub bc, wa
	ldb_da a, (0x024778)
	extz wa
	muls wa, 0xa
	add wa, bc
	lda_24 xbc, (NakaInst_ON_E80168_0x296)
	lds32 xde, 0
	ldb_sri E, 0x07, 0xe4, 0xe0
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
	ldb_da a, (0x024778)
	extz wa
	muls wa, 0xa
	add wa, bc
	lda_24 xbc, (NakaInst_ON_E80168_0x296)
	lds32 xde, 0
	ldb_sri E, 0x07, 0xe4, 0xe0
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
	stb_da (0x024778), a
	ld xwa, (xsp + 32)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 32)
	ld xbc, 0x1e0008e
	ld xde, 0xffff0002
	call SendEvent
	ldb_da a, (0x024778)
	extz wa
	muls wa, 0xa
	lda_24 xbc, (NakaInst_ON_E80168_0x298)
	lds32 xde, 0
	ldb_sri E, 0x07, 0xe4, 0xe0
	ld xwa, 0x1400002
	ld xbc, 0x1e000a0
	call MainFuncCall
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	jrl MidiPartAutoIncReturn

MidiPart_Part2ColumnNavUp:
	cpib_da (0x024778), 0x02
	jr nz, MidiPart_GenericColumnNavUp
	ld wa, iz
	add wa, wa
	lda_24 xbc, (NakaInst_ON_E80168_0x2C6)
	ldw_sri WA, 0x07, 0xe4, 0xe0
	add wa, iz
	ld de, wa
	extz xde
	add xde, 0xffff0000
	ld xwa, (xsp + 32)
	ld xbc, 0x1c0000e
	call SendEvent
	ld wa, iz
	add wa, wa
	lda_24 xbc, (NakaInst_ON_E80168_0x2C6)
	ldw_sri BC, 0x07, 0xe4, 0xe0
	add bc, iz
	ldb_da a, (0x024778)
	extz wa
	muls wa, 0xa
	add wa, bc
	lda_24 xbc, (NakaInst_ON_E80168_0x296)
	lds32 xde, 0
	ldb_sri E, 0x07, 0xe4, 0xe0
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
	ldb_da a, (0x024778)
	extz wa
	muls wa, 0xa
	add wa, bc
	lda_24 xbc, (NakaInst_ON_E80168_0x296)
	lds32 xde, 0
	ldb_sri E, 0x07, 0xe4, 0xe0
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
	ld xwa, NakaInst_ON_E80168_0x2EE
	jr MidiSetup_PushGridStr

MidiSetup_GridStr1:
	ld xwa, NakaInst_ON_E80168_0x32A
	jr MidiSetup_PushGridStr

MidiSetup_GridStr2:
	ld xwa, NakaInst_ON_E80168_0x36C

MidiSetup_PushGridStr:
	push xwa

MidiSetup_CopyStrAndReturn:
	.incbin "includes/generated/v7_transplant_MidiSetup_CopyStrAndReturn.bin"
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
	ld xiy, Transpose_String_Plus2_0x12
	lda xix, (xsp + 24)
	lds bc, 5
	ldirw
	ld xiy, MidiPart_PageStr_1of3_0xA
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
	add xwa, Transpose_String_Plus2_0x5E
	ld wa, (xwa)
	lda_24 xix, (MidiPartGridCheck_JumpTable)
	jp_ind 8, 0x07, 0xf0, 0xe0

MidiPartGridCheck_JumpTable:
	.incbin "includes/generated/v7_transplant_MidiPartGridCheck_JumpTable.bin"
MidiSetup_EventHandler:
	.incbin "includes/generated/v7_transplant_MidiSetup_EventHandler.bin"
MidiPart_AudioCmdDisplay:
	.incbin "includes/generated/v7_transplant_MidiPart_AudioCmdDisplay.bin"
MidiPart_GridDispatchEvent:
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 16)
	ld xbc, 0x1e0008c
	jrl MidiPart_SendEventReturn

MidiPart_LookupColumnParam:
	.incbin "includes/generated/v7_transplant_MidiPart_LookupColumnParam.bin"
MidiPart_LookupFromTable:
	.incbin "includes/generated/v7_transplant_MidiPart_LookupFromTable.bin"
MidiPart_CopyParamStr:
	.incbin "includes/generated/v7_transplant_MidiPart_CopyParamStr.bin"
MidiPart_SendEventReturn:
	call SendEvent

MidiSetup_ReturnZero:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 38)
	ret

MidiPart_DataBlock:
	.incbin "includes/generated/v7_transplant_MidiPart_DataBlock.bin"
InitializeMurai:
	.incbin "includes/generated/v7_transplant_InitializeMurai.bin"
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
	lda_24 xhl, (Bitmap_Accita16)
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
	lda_24 xhl, (Bitmap_Accger16)
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
	lda_24 xhl, (Bitmap_SomeArrows)
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
	cp	xbc, 0x1e000a3
	jr	z, 31
	cp	xbc, 0x1e000a2
	jr	z, 17
	cp	xbc, 0x1e000a1
	jr	z, 3
	lds32	xhl, 0
	ret
	lda_24	xhl, (BitmapBound_DrawbarSlider1_Start)
	ret
	ld	xhl, 22
	ret
	ld	xhl, 222
	ret
	cp	xbc, 0x1e000a3
	jr	z, 31
	cp	xbc, 0x1e000a2
	jr	z, 17
	cp	xbc, 0x1e000a1
	jr	z, 3
	lds32	xhl, 0
	ret
	lda_24	xhl, (BitmapBound_DrawbarSlider2_Start)
	ret
	ld	xhl, 22
	ret
	ld	xhl, 222
	ret
	cp	xbc, 0x1e000a3
	jr	z, 31
	cp	xbc, 0x1e000a2
	jr	z, 17
	cp	xbc, 0x1e000a1
	jr	z, 3
	lds32	xhl, 0
	ret
	lda_24	xhl, (BitmapBound_DrawbarSlider3_Start)
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
	lda_24 xhl, (Bitmap_Technics_Logo)
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
	lda_24 xhl, (Bitmap_KN5000_Logo)
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
	.incbin "includes/generated/v7_transplant_SndParam_ResolveOscEntry.bin"
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
	.incbin "includes/generated/v7_transplant_AcSndEMenu_CheckModified.bin"
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
	lda_24 xde, (0x03e91c)
	ld_sril3 XBC, 0x07, 0xe8, 0xe4
	push xbc
	jr LswLeftHold_CopyAndReturn

LswLeftHold_DefaultStr:
	pushw 0xe9
	pushw 0x52a6

LswLeftHold_CopyAndReturn:
	.incbin "includes/generated/v7_transplant_LswLeftHold_CopyAndReturn.bin"
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
	add xwa, Str_PartName_Right1_0x10
	ld wa, (xwa)
	lda_24 xix, (IvSdpart_Init)
	jp_ind 8, 0x07, 0xf0, 0xe0

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
	stiw_da (0x03e99c), 0x0008
	stiw_da (0x03e99e), 0x0000
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001b
	ld xde, 0x8
	call SendEvent

IvSdpart_Init_LoadDescriptor:
	ldw_da xwa, (0x03e99c)
	sla wa, 2
	lda_24 xbc, (MixerPartTable_Start_0x108)
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
	cpw_da (0x3e99e), 18
	jr ge, IvSdpart_ShowHide_UpdateUI
	call GetPartSelect
	ld xwa, MixerPartTable_Start_0x12C
	ld bc, hl
	calr SdpartLookupPartId
	ld de, hl
	cp de, 0xffff
	jr z, IvSdpart_ShowHide_UpdateUI
	stw_da (0x03e99e), xde

IvSdpart_ShowHide_UpdateUI:
	calr SdpartUpdatePartUI
	ldw_da xwa, (0x03e99e)
	sla wa, 2
	lda_24 xbc, (0x03e924)
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
	ldw_da xwa, (0x03e99c)
	cp wa, 0x8
	jr z, IvSdpart_OK_ExitToMenu
	sla wa, 2
	lda_24 xbc, (MixerPartTable_Start_0x108)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld xbc, 0x1c00002
	lds32 xde, 5
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001b
	ld xde, 0x8
	call SendEvent
	stiw_da (0x03e99c), 0x0008
	ldl_da xwa, (MixerPartTable_Start_0x128)
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
	ldiw_erp 0xe2, 0
	cp wa, 0x8
	jrl nz, IvSdpart_ReturnHandled
	ld xwa, (xsp + 4)
	ld iz, wa
	ldw_da xwa, (0x03e99c)
	cp iz, wa
	jrl z, IvSdpart_ReturnHandled
	cp iz, 0xffff
	jrl z, IvSdpart_ReturnHandled
	sla wa, 2
	lda_24 xbc, (MixerPartTable_Start_0x108)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld xbc, 0x1c00002
	lds32 xde, 5
	call SendEvent
	stw_da (0x03e99c), xiz
	ld wa, iz
	sla wa, 2
	lda_24 xbc, (MixerPartTable_Start_0x108)
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
	ldw_da xwa, (0x03e99e)
	ld bc, wa
	add bc, hl
	jrl lt, IvSdpart_ReturnHandled
	cp bc, 0x17
	jrl gt, IvSdpart_ReturnHandled
	add wa, hl
	stw_da (0x03e99e), xwa
	calr SdpartUpdatePartUI
	ldw_da xwa, (0x03e99e)
	sla wa, 2
	lda_24 xbc, (0x03e924)
	ld_sril3 XDE, 0x07, 0xe4, 0xe0
	ld xwa, 0x3000b
	ld xbc, 0x1c0000f
	call SendEvent
	ldw_da xwa, (0x03e99e)
	sla wa, 1
	lda_24 xbc, (MixerPartTable_Start_0x12C)
	ldw_sri DE, 0x07, 0xe4, 0xe0
	exts xde
	ld xwa, 0x1400002
	ld xbc, 0x1e000a0
	call MainFuncCall
	ldw_da xwa, (0x03e99c)
	sla wa, 2
	lda_24 xbc, (MixerPartTable_Start_0x108)
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
	cpw_da (0x3e99e), 18
	jrl ge, IvSdpart_ReturnHandled
	call GetPartSelect
	ld xwa, MixerPartTable_Start_0x12C
	ld bc, hl
	calr SdpartLookupPartId
	ld de, hl
	cp de, 0xffff
	jrl z, IvSdpart_ReturnHandled
	cpdm16_24 (0x3e99e), xde
	jrl z, IvSdpart_ReturnHandled
	stw_da (0x03e99e), xde
	calr SdpartUpdatePartUI
	ldw_da xwa, (0x03e99e)
	sla wa, 2
	lda_24 xbc, (0x03e924)
	ld_sril3 XDE, 0x07, 0xe4, 0xe0
	ld xwa, 0x3000b
	ld xbc, 0x1c0000f
	call SendEvent
	ldw_da xwa, (0x03e99c)
	sla wa, 2
	lda_24 xbc, (MixerPartTable_Start_0x108)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld xbc, 0x1c0000b
	lds32 xde, 0
	jrl IvSdpart_DispatchEvent
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ldw_da xwa, (0x03e99e)
	sla wa, 1
	lda_24 xbc, (MixerPartTable_Start_0x12C)
	ldw_sri DE, 0x07, 0xe4, 0xe0
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
	ldw_da xwa, (0x03e99e)
	sla wa, 1
	lda_24 xbc, (MixerPartTable_Start_0x12C)
	ldw_sri BC, 0x07, 0xe4, 0xe0
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
	.incbin "includes/generated/v7_transplant_IvSdpart_GetText.bin"
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
	ldw_da xde, (0x03e99e)
	exts xde
	ld xwa, (xiz + 50)
	ld xbc, 0x1e10000
	call ApFuncCall
	ld (xsp + 22), hl
	ldw_da xde, (0x03e99e)
	exts xde
	ld xwa, (xiz + 50)
	ld xbc, 0x1e10001
	call ApFuncCall
	ld (xsp + 20), hl
	ld bc, (xsp + 20)
	extz xbc
	ldw_da xwa, (0x03e99e)
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
	ldw_da xde, (0x03e99e)
	exts xde
	ld xwa, (xiz + 50)
	ld xbc, 0x1e10002
	call ApFuncCall
	or xhl, xhl
	jrl z, AcLswPartEdit_ReturnHandled
	ldw_da xde, (0x03e99e)
	exts xde
	ld xwa, (xiz + 50)
	ld xbc, 0x1e10000
	call ApFuncCall
	ld (xsp + 22), hl
	ld xwa, (xsp + 24)
	ld (xsp + 4), wa
	ldw_da xde, (0x03e99e)
	exts xde
	ld xwa, (xiz + 50)
	ld xbc, 0x1e00041
	call ApFuncCall
	ld (xsp + 6), hl
	ld bc, (xsp + 22)
	lda xwa, (xiz + 50)
	cp bc, 0xffff
	jr z, AcLswPartEdit_SetValue_Unbounded
	ldw_da xde, (0x03e99e)
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
	ldw_da xde, (0x03e99e)
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
	ldw_da xde, (0x03e99e)
	exts xde
	ld xwa, (xiz + 50)
	ld xbc, 0x1e10002
	call ApFuncCall
	or xhl, xhl
	jrl z, AcLswPartEdit_ReturnHandled
	ldw_da xde, (0x03e99e)
	exts xde
	ld xwa, (xiz + 50)
	ld xbc, 0x1e10000
	call ApFuncCall
	ld (xsp + 22), hl
	ld xwa, (xsp + 24)
	ld (xsp + 4), wa
	ldw_da xde, (0x03e99e)
	exts xde
	ld xwa, (xiz + 50)
	ld xbc, 0x1e00041
	call ApFuncCall
	ld (xsp + 6), hl
	ld bc, (xsp + 22)
	ldw_da xde, (0x03e99e)
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
	.incbin "includes/generated/v7_transplant_AcLswPartEdit_ShowHide.bin"
AcLswPartEdit_ShowHide_Unbounded:
	.incbin "includes/generated/v7_transplant_AcLswPartEdit_ShowHide_Unbounded.bin"
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
	.incbin "includes/generated/v7_transplant_AcLswPartEdit_Match.bin"
AcLswPartEdit_Match_Unbounded:
	ldw_da xde, (0x03e99e)
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
	ldw_da xde, (0x03e99e)
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
	ldw_da xde, (0x03e99e)
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
	ldw_da xde, (0x03e99e)
	exts xde
	ld xwa, (xhl + 50)
	ld xbc, 0x1e0003e
	call ApFuncCall
	cpl hl
	cplw_erp 0xee
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
	ldw_da xde, (0x03e99e)
	exts xde
	ld xwa, (xhl + 50)
	ld xbc, 0x1e0003f
	call ApFuncCall
	cpl hl
	cplw_erp 0xee
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
	ldw_da xde, (0x03e99e)
	exts xde
	ld xwa, (xiz + 50)
	ld xbc, 0x1e000b8
	call ApFuncCall
	or xhl, xhl
	jr z, AcLswPartEdit_ReturnHandled
	ldw_da xde, (0x03e99e)
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
	ldw_da xde, (0x03e99e)
	exts xde
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e10000
	call ApFuncCall
	ld (xsp + 28), hl
	ldw_da xde, (0x03e99e)
	exts xde
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e10001
	call ApFuncCall
	ld (xsp + 26), hl
	ld bc, (xsp + 26)
	extz xbc
	ldw_da xwa, (0x03e99e)
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
	ldw_da xde, (0x03e99e)
	exts xde
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e10000
	call ApFuncCall
	ld (xsp + 28), hl
	ldw_da xde, (0x03e99e)
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
	ldw_da xde, (0x03e99e)
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
	ldw_da xde, (0x03e99e)
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
	ldw_da xde, (0x03e99e)
	exts xde
	ld xbc, 0x1e10001
	call ApFuncCall
	ld (xsp + 26), hl
	pushm (xsp + 6)
	ld wa, (xsp + 30)
	ld bc, (xsp + 28)
	ld de, (xsp + 6)
	call MainLswPartPut
	ldw_da xde, (0x03e99e)
	exts xde
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 54)
	ld xbc, 0x1e10001
	call ApFuncCall
	ld (xsp + 26), hl
	ldw_da xde, (0x03e99e)
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
	ldw_da xde, (0x03e99e)
	exts xde
	ld xbc, 0x1e10001
	call ApFuncCall
	ld xiz, xhl
	ld xwa, xiz
	ld bc, (xsp + 4)
	ld de, (xsp + 6)
	call MainLswPut
	ldw_da xde, (0x03e99e)
	exts xde
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 54)
	ld xbc, 0x1e10001
	call ApFuncCall
	ld xiz, xhl
	ldw_da xde, (0x03e99e)
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
	ldw_da xde, (0x03e99e)
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
	ldw_da xde, (0x03e99e)
	exts xde
	ld xwa, (xhl)
	ld xbc, 0x1e10001
	call ApFuncCall
	ld (xsp + 26), hl
	ld xwa, (xsp + 30)
	ld (xsp + 4), wa
	ldw_da xde, (0x03e99e)
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
	ldw_da xde, (0x03e99e)
	exts xde
	ld xbc, 0x1e10001
	call ApFuncCall
	ld (xsp + 26), hl
	ldw_da xde, (0x03e99e)
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
	ldw_da xde, (0x03e99e)
	exts xde
	cpw (xbc), 0x80
	jr ge, AudioCtrl_DualPartResolve
	ld xwa, (xhl)
	ld xbc, 0x1e10001
	call ApFuncCall
	ld xiz, xhl
	ld xwa, (xsp + 30)
	ld (xsp + 4), wa
	ldw_da xde, (0x03e99e)
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
	ldw_da xde, (0x03e99e)
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
	.incbin "includes/generated/v7_transplant_AudioCtrl_InitPartSelection.bin"
AudioCtrl_UnboundedPartSel:
	.incbin "includes/generated/v7_transplant_AudioCtrl_UnboundedPartSel.bin"
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
	.incbin "includes/generated/v7_transplant_AudioCtrl_MidiMatchHandler.bin"
AudioCtrl_StoreValue:
	ld wa, (xde)
	ld (xbc), wa

AudioCtrl_ConfirmAndReturn:
	ld xwa, (xsp + 38)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jrl AudioCtrl_SendEventThenReturn

AudioCtrl_CheckSecondPart:
	ldw_da xde, (0x03e99e)
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
	ldw_da xde, (0x03e99e)
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
	ldw_da xde, (0x03e99e)
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
	ldw_da xde, (0x03e99e)
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
	ldw_da xde, (0x03e99e)
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
	ldw_da xde, (0x03e99e)
	exts xde
	ld xwa, (xhl + 50)
	ld xbc, 0x1e0003e
	call ApFuncCall
	cpl hl
	cplw_erp 0xee
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
	ldw_da xde, (0x03e99e)
	exts xde
	ld xwa, (xhl + 50)
	ld xbc, 0x1e0003f
	call ApFuncCall
	cpl hl
	cplw_erp 0xee
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
	.incbin "includes/generated/v7_transplant_AcLswPartPan_ShowHide.bin"
AcLswPartPan_ShowHide_Unbounded:
	.incbin "includes/generated/v7_transplant_AcLswPartPan_ShowHide_Unbounded.bin"
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
	.incbin "includes/generated/v7_transplant_AcLswPartPan_Confirm.bin"
AcLswPartPan_Match:
	.incbin "includes/generated/v7_transplant_AcLswPartPan_Match.bin"
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
	ldw_da xbc, (0x03e99e)
	ld wa, bc
	sla wa, 2
	lda_24 xde, (MixerPartTable_Start_0x8)
	ld_sril3 XWA, 0x07, 0xe8, 0xe0
	bit_erpw 0xe2, 0x0f
	jr z, SdpartUpdatePartUI_Confirm
	add bc, bc
	lda_24 xwa, (MixerPartTable_Start_0x12C)
	ldw_sri DE, 0x07, 0xe0, 0xe4
	exts xde
	ld xwa, 0x1400004
	ld xbc, 0x1e0005e
	jp FuncCall

SdpartUpdatePartUI_Confirm:
	ld xwa, 0x3000a
	ld xbc, 0x1c0000f
	ld xde, Str_PartName_Right1_0x24
	jp SendEvent

LswSound:
	.incbin "includes/generated/v7_transplant_LswSound.bin"
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
	ld xwa, MixerPartTable_Start_0x12C
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
	.incbin "includes/generated/v7_transplant_LswVolume.bin"
LswVolume_OverflowStr:
	ld xwa, Str_PartName_Right1_0x4C
	jr LswVolume_CopyStr

LswVolume_InactiveStr:
	ld xwa, Str_PartName_Right1_0x52

LswVolume_CopyStr:
	.incbin "includes/generated/v7_transplant_LswVolume_CopyStr.bin"
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
	ld xwa, MixerPartTable_Start_0x12C
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
	.incbin "includes/generated/v7_transplant_LswMute.bin"
LswMute_OverflowStr:
	ld xwa, Str_PartName_Right1_0x5C
	jr LswMute_CopyStr

LswMute_InactiveStr:
	ld xwa, Str_PartName_Right1_0x62

LswMute_CopyStr:
	.incbin "includes/generated/v7_transplant_LswMute_CopyStr.bin"
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
	ld xwa, MixerPartTable_Start_0x12C
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
	lda_24 xix, (MixerPartTable_Start_0x8)
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
	ldiw_erp 0xe2, 0
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
	ld xwa, Str_PartName_Right1_0x68
	jr LswPan_CopyStr

LswPan_FormatOffset:
	cp wa, 0x40
	jr ge, LswPan_FormatRight
	ldw de, 0x40
	sub de, wa
	pushw de
	ld xwa, Str_PartName_Right1_0x6C
	jr LswPan_SendCommand

LswPan_FormatRight:
	sub wa, 0x40
	pushw wa
	ld xwa, Str_PartName_Right1_0x72

LswPan_SendCommand:
	.incbin "includes/generated/v7_transplant_LswPan_SendCommand.bin"
LswPan_InactiveStr:
	ld xwa, Str_PartName_Right1_0x78

LswPan_CopyStr:
	.incbin "includes/generated/v7_transplant_LswPan_CopyStr.bin"
LswPan_ReturnThis:
	ld xhl, xiz
	jr AudioCtrl_PopIzRet6

LswPan_GetPartId:
	add xde, xde
	ld xwa, MixerPartTable_Start_0x12C
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
	.incbin "includes/generated/v7_transplant_LswReverb.bin"
LswReverb_InactiveStr:
	.incbin "includes/generated/v7_transplant_LswReverb_InactiveStr.bin"
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
	ld xwa, MixerPartTable_Start_0x12C
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
	.incbin "includes/generated/v7_transplant_LswDSPEffect.bin"
LswDSPEff_InactiveStr:
	.incbin "includes/generated/v7_transplant_LswDSPEff_InactiveStr.bin"
LswDSPEff_ReturnThis:
	ld xhl, xiz
	jr LswDSPEffect_PopIzRet

LswDSPEff_GetPartId:
	add xde, xde
	ld xwa, MixerPartTable_Start_0x12C
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
	lda_24 xhl, (MixerPartTable_Start_0x8)
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
	ldiw_erp 0xe2, 0
	extz xwa
	sll xwa, 2
	add xhl, xwa
	ld xbc, (xde + 8)
	ld xwa, (xhl)
	bit 3, wa
	jr z, LswDigEff_InactiveStr
	cpw (xde + 4), 0x0
	jr z, LswDigEff_StrOff
	ld xwa, Str_PartName_Right1_0x8C
	jr LswDigEff_CopyStr

LswDigEff_StrOff:
	ld xwa, Str_PartName_Right1_0x90
	jr LswDigEff_CopyStr

LswDigEff_InactiveStr:
	ld xwa, Str_PartName_Right1_0x94

LswDigEff_CopyStr:
	.incbin "includes/generated/v7_transplant_LswDigEff_CopyStr.bin"
LswDigEff_GetPartId:
	add xde, xde
	ld xwa, MixerPartTable_Start_0x12C
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
	lda_24 xhl, (MixerPartTable_Start_0x8)
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
	ldiw_erp 0xe2, 0
	extz xwa
	sll xwa, 2
	add xhl, xwa
	ld xbc, (xde + 8)
	ld xwa, (xhl)
	bit 11, wa
	jr z, LswSust_InactiveStr
	cpw (xde + 4), 0x0
	jr z, LswSust_StrOff
	ld xwa, Str_PartName_Right1_0x98
	jr LswSust_CopyStr

LswSust_StrOff:
	ld xwa, Str_PartName_Right1_0x9C
	jr LswSust_CopyStr

LswSust_InactiveStr:
	ld xwa, Str_PartName_Right1_0xA0

LswSust_CopyStr:
	.incbin "includes/generated/v7_transplant_LswSust_CopyStr.bin"
LswSust_GetPartId:
	add xde, xde
	ld xwa, MixerPartTable_Start_0x12C
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
	.incbin "includes/generated/v7_transplant_LswSustainLength.bin"
LswSustLen_InactiveStr:
	.incbin "includes/generated/v7_transplant_LswSustLen_InactiveStr.bin"
LswSustLen_ReturnThis:
	ld xhl, xiz
	jr LswSustainLength_PopIzRet

LswSustLen_GetPartId:
	add xde, xde
	ld xwa, MixerPartTable_Start_0x12C
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
	.incbin "includes/generated/v7_transplant_LswKeyShift.bin"
LswKeyShift_ZeroStr:
	ld xwa, Str_PartName_Right1_0xB2
	jr LswKeyShift_CopyStr

LswKeyShift_InactiveStr:
	ld xwa, Str_PartName_Right1_0xB6

LswKeyShift_CopyStr:
	.incbin "includes/generated/v7_transplant_LswKeyShift_CopyStr.bin"
LswKeyShift_ReturnThis:
	ld xhl, xiz
	jr AudioCtrl_PopIzRet5

LswKeyShift_GetPartId:
	add xde, xde
	ld xwa, MixerPartTable_Start_0x12C
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
	.incbin "includes/generated/v7_transplant_LswTuning.bin"
LswTuning_ZeroStr:
	ld xwa, Str_PartName_Right1_0xC0
	jr LswTuning_CopyStr

LswTuning_InactiveStr:
	ld xwa, Str_PartName_Right1_0xC6

LswTuning_CopyStr:
	.incbin "includes/generated/v7_transplant_LswTuning_CopyStr.bin"
LswTuning_ReturnThis:
	ld xhl, xiz
	jr AudioCtrl_PopIzRet4

LswTuning_GetPartId:
	add xde, xde
	ld xwa, MixerPartTable_Start_0x12C
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
	.incbin "includes/generated/v7_transplant_LswBendRange.bin"
LswBendRng_InactiveStr:
	.incbin "includes/generated/v7_transplant_LswBendRng_InactiveStr.bin"
LswBendRng_ReturnThis:
	ld xhl, xiz
	jr LswBendRange_PopIzRet

LswBendRng_GetPartId:
	add xde, xde
	ld xwa, MixerPartTable_Start_0x12C
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
	lda_24 xhl, (MixerPartTable_Start_0x8)
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
	ldiw_erp 0xe2, 0
	extz xwa
	sll xwa, 2
	add xhl, xwa
	ld xbc, (xde + 8)
	ld xwa, (xhl)
	bit 6, wa
	jr z, LswGlide_InactiveStr
	cpw (xde + 4), 0x0
	jr z, LswGlide_StrOff
	ld xwa, Str_PartName_Right1_0xD4
	jr LswGlide_CopyStr

LswGlide_StrOff:
	ld xwa, Str_PartName_Right1_0xD8
	jr LswGlide_CopyStr

LswGlide_InactiveStr:
	ld xwa, Str_PartName_Right1_0xDC

LswGlide_CopyStr:
	.incbin "includes/generated/v7_transplant_LswGlide_CopyStr.bin"
LswGlide_GetPartId:
	add xde, xde
	ld xwa, MixerPartTable_Start_0x12C
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
	lda_24 xhl, (MixerPartTable_Start_0x8)
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
	ldiw_erp 0xe2, 0
	extz xwa
	sll xwa, 2
	add xhl, xwa
	ld xbc, (xde + 8)
	ld xwa, (xhl)
	bit 5, wa
	jr z, LswSustPedal_InactiveStr
	cpw (xde + 4), 0x0
	jr z, LswSustPedal_StrOff
	ld xwa, Str_PartName_Right1_0xE0
	jr LswSustPedal_CopyStr

LswSustPedal_StrOff:
	ld xwa, Str_PartName_Right1_0xE4
	jr LswSustPedal_CopyStr

LswSustPedal_InactiveStr:
	ld xwa, Str_PartName_Right1_0xE8

LswSustPedal_CopyStr:
	.incbin "includes/generated/v7_transplant_LswSustPedal_CopyStr.bin"
LswSustPedal_GetPartId:
	add xde, xde
	ld xwa, MixerPartTable_Start_0x12C
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
	lda_24 xhl, (MixerPartTable_Start_0x8)
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
	ldiw_erp 0xe2, 0
	extz xwa
	sll xwa, 2
	add xhl, xwa
	ld xbc, (xde + 8)
	ld xwa, (xhl)
	bit 4, wa
	jr z, LswKeyScale_InactiveStr
	cpw (xde + 4), 0x0
	jr z, LswKeyScale_StrOff
	ld xwa, Str_PartName_Right1_0xEC
	jr LswKeyScale_CopyStr

LswKeyScale_StrOff:
	ld xwa, Str_PartName_Right1_0xF0
	jr LswKeyScale_CopyStr

LswKeyScale_InactiveStr:
	ld xwa, Str_PartName_Right1_0xF4

LswKeyScale_CopyStr:
	.incbin "includes/generated/v7_transplant_LswKeyScale_CopyStr.bin"
LswKeyScale_GetPartId:
	add xde, xde
	ld xwa, MixerPartTable_Start_0x12C
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
	lda_24 xhl, (MixerPartTable_Start_0x8)
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
	ldiw_erp 0xe2, 0
	extz xwa
	sll xwa, 2
	add xhl, xwa
	ld xbc, (xde + 8)
	ld xwa, (xhl)
	bit 2, wa
	jr z, LswAfterTouch_InactiveStr
	cpw (xde + 4), 0x0
	jr z, LswAfterTouch_StrOff
	ld xwa, Str_PartName_Right1_0xF8
	jr LswAfterTouch_CopyStr

LswAfterTouch_StrOff:
	ld xwa, Str_PartName_Right1_0xFC
	jr LswAfterTouch_CopyStr

LswAfterTouch_InactiveStr:
	ld xwa, Str_PartName_Right1_0x100

LswAfterTouch_CopyStr:
	.incbin "includes/generated/v7_transplant_LswAfterTouch_CopyStr.bin"
LswAfterTouch_GetPartId:
	add xde, xde
	ld xwa, MixerPartTable_Start_0x12C
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
	lda_24 xhl, (MixerPartTable_Start_0x8)
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
	ldiw_erp 0xe2, 0
	extz xwa
	sll xwa, 2
	add xhl, xwa
	ld xbc, (xde + 8)
	ld xwa, (xhl)
	bit_erpw 0xe2, 0x00
	jr z, LswPartExp_StrOff
	cpw (xde + 4), 0x0
	jr z, LswPartExp_StrDisabled
	ld xwa, Str_PartName_Right1_0x104
	jr LswPartExp_StrCopyReturn

LswPartExp_StrDisabled:
	ld xwa, Str_PartName_Right1_0x108
	jr LswPartExp_StrCopyReturn

LswPartExp_StrOff:
	ld xwa, Str_PartName_Right1_0x10C

LswPartExp_StrCopyReturn:
	.incbin "includes/generated/v7_transplant_LswPartExp_StrCopyReturn.bin"
LswPartExp_PartIdLookup:
	add xde, xde
	ld xwa, MixerPartTable_Start_0x12C
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
	lda_24 xhl, (MixerPartTable_Start_0x8)
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
	ldiw_erp 0xe2, 0
	extz xwa
	sll xwa, 2
	add xhl, xwa
	ld xbc, (xde + 8)
	ld xwa, (xhl)
	bit 0, wa
	jr z, LswLocal_StrOff
	cpw (xde + 4), 0x0
	jr z, LswLocal_StrDisabled
	ld xwa, Str_PartName_Right1_0x110
	jr LswLocal_StrCopyReturn

LswLocal_StrDisabled:
	ld xwa, Str_PartName_Right1_0x114
	jr LswLocal_StrCopyReturn

LswLocal_StrOff:
	ld xwa, Str_PartName_Right1_0x118

LswLocal_StrCopyReturn:
	.incbin "includes/generated/v7_transplant_LswLocal_StrCopyReturn.bin"
LswLocal_PartIdLookup:
	add xde, xde
	ld xwa, MixerPartTable_Start_0x12C
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
	.incbin "includes/generated/v7_transplant_LswMidiChannel.bin"
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
	.incbin "includes/generated/v7_transplant_LswMidi_StrCopyReturn.bin"
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
	.incbin "includes/generated/v7_transplant_IvMesageProc.bin"
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
	ldw_da xwa, (0x02478c)
	muls wa, 0xe
	lda_24 xbc, (NakaInst_Por_favor_seleccione_el_Panel_Memory_al_que_desea_0x118)
	cpiw_sri 0x07, 0xe4, 0xe0, 0x05, 0x00
	call_24 nz, DrawWall
	ld xwa, xiz
	ld xbc, 0x1c0000f
	lds32 xde, 0

IvMessage_SendEvent:
	call SendEvent
	jr IvMessageStrcpyReturn

IvMessage_SelectionChange:
	stw_da (0x02478c), xwa
	muls wa, 0xe
	lda_24 xbc, (NakaInst_Por_favor_seleccione_el_Panel_Memory_al_que_desea_0x118)
	ldw_sri WA, 0x07, 0xe4, 0xe0
	sla wa, 2
	lda_24 xbc, (NakaInst_Por_favor_seleccione_el_Panel_Memory_al_que_desea_0x586)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld xbc, 0x1e000b5
	ld xde, 0x1e000b6
	call SendEvent
	jr IvMessage_Epilogue

IvMessage_GetText:
	.incbin "includes/generated/v7_transplant_IvMessage_GetText.bin"
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
	stiw_da (0x02477a), 0x0000
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
	incdi16_24 1, (0x2477a)
	jrl LanguageStringcpyReturn

PleaseWait_GetText:
	.incbin "includes/generated/v7_transplant_PleaseWait_GetText.bin"
PleaseWait_DotFillLoop:
	ld xwa, (xsp + 8)
	stib_ind 0x07, 0xe0, 0xec, 0x2e
	inc 1, hl
	cp hl, de
	jr lt, PleaseWait_DotFillLoop

PleaseWait_BuildScrollStr:
	ld xiy, (xsp + 8)
	stib_ind 0x07, 0xf4, 0xec, 0x00
	ld ix, de
	add ix, ix
	ldw_da xwa, (0x02477a)
	exts xwa
	divs xwa, xix
	stw_erp HL, 0xe2
	ldb_da a, (0x0340e4)
	extz wa
	lda_24 xbc, (NakaInst_Por_favor_seleccione_el_Panel_Memory_al_que_desea_0x5A2)
	sla wa, 2
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	cp hl, de
	jr ge, PleaseWait_OverflowPath
	sub de, hl
	pushw de
	stb_dri W, 0x07, 0xe0, 0xec
	push xwa
	push xiy
	jr PleaseWait_Strncpy

PleaseWait_OverflowPath:
	ld bc, hl
	sub bc, de
	pushw bc
	push xwa
	ld xwa, (xsp + 10)
	stb_dri A, 0x07, 0xe0, 0xf0
	exts xhl
	sub xbc, xhl
	push xbc

PleaseWait_Strncpy:
	.incbin "includes/generated/v7_transplant_PleaseWait_Strncpy.bin"
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
	ldb_da a, (0x0340e4)
	bit 7, de
	jr z, CheckLang_Increment
	ld c, a
	cps a, 0
	jr z, CheckLang_SkipLang4
	dec 1, c
	stb_da (0x0340e4), c

CheckLang_SkipLang4:
	ldb_da a, (0x0340e4)
	cps a, 4
	jr nz, LanguageSelectEventReturn
	dec 1, a
	stb_da (0x0340e4), a
	jr LanguageSelectEventReturn

CheckLang_Increment:
	ld c, a
	cps a, 5
	jr nc, CheckLang_SkipLang4Up
	inc 1, c
	stb_da (0x0340e4), c

CheckLang_SkipLang4Up:
	ldb_da a, (0x0340e4)
	cps a, 4
	jr nz, LanguageSelectEventReturn
	inc 1, a
	stb_da (0x0340e4), a

LanguageSelectEventReturn:
	ld xwa, 0xffffffff
	ld xbc, 0x1c0000a
	lds32 xde, 0
	call SendEvent
	jr CheckLang_ReturnZero

CheckLang_GetTextStr:
	.incbin "includes/generated/v7_transplant_CheckLang_GetTextStr.bin"
CheckLang_ReturnZero:
	lds32 xhl, 0
	ret

CheckLang_ReturnAddress:
	lda_24 xhl, (0x0340e4)
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
	ldw_da xwa, (0x02478c)
	muls wa, 0xe
	lda_24 xbc, (NakaInst_Por_favor_seleccione_el_Panel_Memory_al_que_desea_0x118)
	ldw_sri WA, 0x07, 0xe4, 0xe0
	sla wa, 2
	lda_24 xbc, (NakaInst_Por_favor_seleccione_el_Panel_Memory_al_que_desea_0x586)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld xbc, 0x1c00002
	lds32 xde, 0
	call SendEvent
	ldw_da xwa, (0x02478c)
	bit 7, iz
	jr z, CheckMsg_IncrementCheck
	ld bc, wa
	cps wa, 0
	jr le, LanguageCheckReturn
	dec 1, bc
	stw_da (0x02478c), xbc
	jr LanguageCheckReturn

CheckMsg_IncrementCheck:
	ld bc, wa
	muls wa, 0xe
	add wa, 0xe
	lda_24 xde, (NakaInst_Por_favor_seleccione_el_Panel_Memory_al_que_desea_0x122)
	ld_sril3 XWA, 0x07, 0xe8, 0xe0
	or xwa, xwa
	jr z, LanguageCheckReturn
	inc 1, bc
	stw_da (0x02478c), xbc

LanguageCheckReturn:
	ldw_da xwa, (0x02478c)
	muls wa, 0xe
	lda_24 xbc, (NakaInst_Por_favor_seleccione_el_Panel_Memory_al_que_desea_0x118)
	ldw_sri WA, 0x07, 0xe4, 0xe0
	sla wa, 2
	lda_24 xbc, (NakaInst_Por_favor_seleccione_el_Panel_Memory_al_que_desea_0x586)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld xbc, 0x1c00001
	lds32 xde, 0
	call SendEvent
	jr CheckMsg_ReturnZero

CheckMsg_AudioCommand:
	.incbin "includes/generated/v7_transplant_CheckMsg_AudioCommand.bin"
CheckMsg_ReturnZero:
	lds32 xhl, 0
	jr CheckMsg_Epilogue

CheckMsg_ReturnAddress:
	lda_24 xhl, (0x02478c)
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
	ldw_da xwa, (0x02478c)
	cp wa, 0x1a
	jr z, MsgText_CheckLanguage
	muls wa, 0xe
	lda_24 xbc, (NakaInst_Por_favor_seleccione_el_Panel_Memory_al_que_desea_0x122)
	ld_sril3 XHL, 0x07, 0xe4, 0xe0
	ret

MsgText_CheckLanguage:
	ldb_d8 a, (3298)
	cps a, 3
	jr z, MsgText_Lang3
	cps a, 2
	jr z, MsgText_Lang2
	cps a, 1
	jr z, MsgText_Lang1
	lda_24 xhl, (Str_DiskErr20_Italian_0x5DE)
	ret

MsgText_Lang1:
	ld xhl, StrTable_DiskErr24_Chord
	jr MsgText_Return

MsgText_Lang2:
	ld xhl, Str_Err24Chord_English_0x4E
	jr MsgText_Return

MsgText_Lang3:
	ld xhl, Str_Err24Ctrl_Italian_0x170

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
	.incbin "includes/generated/v7_transplant_MsgHeader_BuildHeader.bin"
MsgHeader_BuildLoop:
	.incbin "includes/generated/v7_transplant_MsgHeader_BuildLoop.bin"
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
	stiw_da (0x02477c), 0xffff
	stiw_da (0x024780), 0xffff
	call GetPartSelect
	stw_da (0x02477e), xhl
	ld wa, hl
	calr SndParam_ResolveOscEntry
	ld xde, xhl
	ld xwa, (xsp + 4)
	ld xbc, 0x1c00023
	call SendEvent
	call GetModeNow
	cp xhl, 0x1800013
	jr nz, IvAccordion_ShowHide_UpdatePart
	cpw_da (0x24782), 0
	jr z, IvAccordion_ShowHide_NoBellows
	ld xwa, WidgetName_PtrBlock_A_0x1
	ld xbc, 0x1c00002
	lds32 xde, 5
	call SendEvent
	stiw_da (0x02477c), 0x0001
	stiw_da (0x024780), 0x0001
	ld xwa, WidgetName_PtrBlock_A_0xF
	ld xbc, 0x1c00001
	lds32 xde, 5
	jr IvAccordion_ShowHide_Toggle

IvAccordion_ShowHide_NoBellows:
	ld xwa, WidgetName_PtrBlock_A_0xF
	ld xbc, 0x1c00002
	lds32 xde, 5
	call SendEvent
	stiw_da (0x02477c), 0x0000
	stiw_da (0x024780), 0x0000
	ld xwa, WidgetName_PtrBlock_A_0x1
	ld xbc, 0x1c00001
	lds32 xde, 5

IvAccordion_ShowHide_Toggle:
	call SendEvent
	ldw_da xwa, (0x024782)
	cpl wa
	stw_da (0x024782), xwa

IvAccordion_ShowHide_UpdatePart:
	ldw_da xwa, (0x02477e)
	sla wa, 2
	lda_24 xbc, (0x03e9a0)
	ld_sril3 XDE, 0x07, 0xe4, 0xe0
	ld xwa, WidgetName_InitPtrTable_0x15
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
	cpw_da (0x24780), 0
	jr nz, IvAccordion_Scroll_SetOff
	stiw_da (0x024780), 0x0001
	ld xwa, WidgetName_PtrBlock_A_0x1
	ld xbc, 0x1c00002
	lds32 xde, 5
	call SendEvent
	ld xwa, WidgetName_PtrBlock_A_0xF
	ld xbc, 0x1c00001
	lds32 xde, 5
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001b
	lds32 xde, 1
	call PostEvent
	cpw_da (0x2477c), 1
	jrl nz, IvAccordion_ReturnHandled
	ldw_da xwa, (0x02477e)
	calr SndParam_ResolveOscEntry
	ld xde, xhl
	ld xwa, (xsp + 4)
	ld xbc, 0x1c00023
	jrl IvAccordion_DispatchEvent

IvAccordion_Scroll_SetOff:
	stiw_da (0x024780), 0x0000
	ld xwa, WidgetName_PtrBlock_A_0xF
	ld xbc, 0x1c00002
	lds32 xde, 5
	call SendEvent
	ld xwa, WidgetName_PtrBlock_A_0x1
	ld xbc, 0x1c00001
	lds32 xde, 5
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001b
	lds32 xde, 1
	call PostEvent
	cpw_da (0x2477c), 0
	jrl nz, IvAccordion_ReturnHandled
	ldw_da xwa, (0x02477e)
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
	ldiw_erp 0xe2, 0
	cps wa, 1
	jrl nz, IvAccordion_ReturnHandled
	ldw_da xbc, (0x02477e)
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
	ldw_da xbc, (0x02477e)
	cp bc, wa
	jrl nz, IvAccordion_ReturnHandled
	ld xwa, xiz
	srl xwa, 0
	ldiw_erp 0xe2, 0
	ld bc, wa
	srl bc, 8
	ldb b, 0x0
	cp c, 0xd
	jrl nz, IvAccordion_Update_NonNote
	cp a, 0xa
	jr nc, IvAccordion_Update_BellowsOn
	cpw_da (0x2477c), 0
	jr z, IvAccordion_Update_SendPartParam
	ld xwa, WidgetName_PtrBlock_A_0xF
	ld xbc, 0x1c00002
	lds32 xde, 5
	call SendEvent
	stiw_da (0x02477c), 0x0000
	stiw_da (0x024780), 0x0000
	ld xwa, WidgetName_PtrBlock_A_0x1
	ld xbc, 0x1c00001
	lds32 xde, 5
	jr IvAccordion_Update_CommitToggle

IvAccordion_Update_BellowsOn:
	cpw_da (0x2477c), 1
	jr z, IvAccordion_Update_SendPartParam
	ld xwa, WidgetName_PtrBlock_A_0x1
	ld xbc, 0x1c00002
	lds32 xde, 5
	call SendEvent
	stiw_da (0x02477c), 0x0001
	stiw_da (0x024780), 0x0001
	ld xwa, WidgetName_PtrBlock_A_0xF
	ld xbc, 0x1c00001
	lds32 xde, 5

IvAccordion_Update_CommitToggle:
	call SendEvent

IvAccordion_Update_SendPartParam:
	ld xwa, xiz
	srl xwa, 0
	ldiw_erp 0xe2, 0
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
	ldw_da xwa, (0x02477e)
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
	stw_da (0x02477e), xhl
	sla hl, 2
	lda_24 xwa, (0x03e9a0)
	ld_sril3 XDE, 0x07, 0xe0, 0xec
	ld xwa, WidgetName_InitPtrTable_0x15
	ld xbc, 0x1c0000f
	call SendEvent
	ldw_da xwa, (0x02477e)
	calr SndParam_ResolveOscEntry
	ld xde, xhl
	ld xwa, (xsp + 4)
	ld xbc, 0x1c00023

IvAccordion_DispatchEvent:
	call SendEvent
	jr IvAccordion_ReturnHandled

IvAccordion_GetText:
	.incbin "includes/generated/v7_transplant_IvAccordion_GetText.bin"
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
	ldiw_erp 0xe2, 0
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
	.incbin "includes/generated/v7_transplant_AccordionX_GetText.bin"
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
	.incbin "includes/generated/v7_transplant_Sdtecd_InitCase3.bin"
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
	.incbin "includes/generated/v7_transplant_Sdtecd_GetText.bin"
Sdtecd_ReturnZero:
	lds32 xhl, 0

Sdtecd_Epilogue:
	pop xiz
	inc 8, xsp
	ret

IvSdtecd1Proc:
	.incbin "includes/generated/v7_transplant_IvSdtecd1Proc.bin"
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
	.incbin "includes/generated/v7_transplant_Sdtecd1_ScrollDown_Lookup.bin"
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
	.incbin "includes/generated/v7_transplant_Sdtecd1_ScrollUp_Lookup.bin"
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
	lda_24 xbc, (NakaInst_RIGHT_1_E9D9B0_0x1C)
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
	.incbin "includes/generated/v7_transplant_Sdtecd1_GetText.bin"
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
	lda_24 xde, (Naka_TechniChord1_Screens)
	ld_sril3 XBC, 0x07, 0xe8, 0xe4
	push xbc
	jr LswOrch_StrCopyReturn

LswOrch_StrDefault:
	pushw 0xe9
	pushw 0xdb16

LswOrch_StrCopyReturn:
	.incbin "includes/generated/v7_transplant_LswOrch_StrCopyReturn.bin"
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
	stb_dri L, 0xfd, 0xec, 0xfe
	push xiz
	stl_dri XDE, 0xfd, 0x10, 0x01
	stl_dri XWA, 0xfd, 0x14, 0x01
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
	stb_dri A, 0xfd, 0x08, 0x01
	ld_sril XWA, (xsp + 0x0114)
	call GetClientBox
	stb_dri W, 0xfd, 0x08, 0x01
	stb_dri A, 0xfd, 0x04, 0x01
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
	.incbin "includes/generated/v7_transplant_PsLabel_CopyDataStr.bin"
PsLabel_DrawReverse:
	stb_dri C, 0xfd, 0x08, 0x01
	stb_dri A, 0xfd, 0x04, 0x01
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
	cpl_sri_rm XWA, 0xfd, 0x10, 0x01
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
	cpl_sri_rm XWA, 0xfd, 0x10, 0x01
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
	cpl_sri_rm XWA, 0xfd, 0x10, 0x01
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
	.incbin "includes/generated/v7_transplant_PsLabel_GetText.bin"
LswMaster_ReturnZeroJmp:
	lds32 xhl, 0
	jr PsLabel_Epilogue

PsLabel_ForwardToBase:
	ld_sril XWA, (xsp + 0x0114)
	ld_sril XDE, (xsp + 0x0110)
	call InheritedProc

PsLabel_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0x14, 0x01
	ret

LswMasterTuning:
	lda xsp, (xsp - 14)
	pushw iz
	ld (xsp + 8), xde
	ld xde, xbc
	ld (xsp + 12), xwa
	ld xiy, NakaInst_RIGHT_1_E9DB0C_0x64
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
	lda_24 xde, (NakaInst_RIGHT_1_E9DB0C_0x14)
	ld xwa, (xsp + 8)
	ld bc, (xwa + 4)

LswTuning_SearchLoop:
	.incbin "includes/generated/v7_transplant_LswTuning_SearchLoop.bin"
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
	.incbin "includes/generated/v7_transplant_StringOp_CopyCall.bin"
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
	stiw_da (0x02478e), 0x0000

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
	ldw_da xwa, (0x02478e)
	sla wa, 2
	lda_24 xbc, (NakaInst_RIGHT_1_E9DB0C_0x70)
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
	ldw_da xwa, (0x02478e)
	cp wa, 0xb
	jr ge, Sdscltyp2_SetAutoIncDown
	inc 1, wa
	stw_da (0x02478e), xwa
	ld xwa, 0x50011
	ld xbc, 0x1e00051
	lds32 xde, 0
	call SendEvent
	ld xde, xhl
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001b
	call SendEvent
	ldw_da xwa, (0x02478e)
	sla wa, 2
	lda_24 xbc, (NakaInst_RIGHT_1_E9DB0C_0x70)
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
	ldw_da xwa, (0x02478e)
	cps wa, 0
	jr le, Sdscltyp2_SetAutoIncUp
	dec 1, wa
	stw_da (0x02478e), xwa
	ld xwa, 0x50011
	ld xbc, 0x1e00051
	lds32 xde, 0
	call SendEvent
	ld xde, xhl
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001b
	call SendEvent
	ldw_da xwa, (0x02478e)
	sla wa, 2
	lda_24 xbc, (NakaInst_RIGHT_1_E9DB0C_0x70)
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
	.incbin "includes/generated/v7_transplant_Sdscltyp2_GetText.bin"
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
	ld xwa, NakaInst_RIGHT_1_E9DB0C_0xAA
	calr SdpartLookupPartId
	ld xbc, (xiz + 8)
	cp hl, 0xffff
	jr z, LswScaleType_StrDefault
	sla hl, 2
	lda_24 xwa, (Naka_Scale2_Screens)
	ld_sril3 XWA, 0x07, 0xe0, 0xec
	push xwa
	jr LswScaleType_StrCopyReturn

LswScaleType_StrDefault:
	pushw 0xe9
	pushw 0xdd08

LswScaleType_StrCopyReturn:
	.incbin "includes/generated/v7_transplant_LswScaleType_StrCopyReturn.bin"
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
	.incbin "includes/generated/v7_transplant_LswScalingShift.bin"
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
	.incbin "includes/generated/v7_transplant_LswScalingShift2.bin"
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
	.incbin "includes/generated/v7_transplant_LswScalingMode.bin"
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
	.incbin "includes/generated/v7_transplant_LswScalingKeyX.bin"
LswScaleKeyX_StrZero:
	.incbin "includes/generated/v7_transplant_LswScaleKeyX_StrZero.bin"
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
	ld xde, NakaInst_RIGHT_1_E9DB0C_0x70
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
	ld xbc, NakaInst_RIGHT_1_E9DB0C_0x70
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
	.incbin "includes/generated/v7_transplant_Softver_ShowHide.bin"
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
	.incbin "includes/generated/v7_transplant_Softver_GetText.bin"
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
	.incbin "includes/generated/v7_transplant_MPver_ShowHide.bin"
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
	.incbin "includes/generated/v7_transplant_MPver_GetText.bin"
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
	ld xwa, Bitmap_DigitD_0x8DA
	cps l, 2
	jr nz, AcWelcomScreen_Init_StoreData
	ld xwa, Bitmap_DigitD_0x22

AcWelcomScreen_Init_StoreData:
	stl_da (0x024786), xwa
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
	ld xwa, Bitmap_DigitD_0x11CE
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
	stiw_da (0x024784), 0x0001
	ldl_da xbc, (0x024786)
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
	ldw_da xbc, (0x024784)
	exts xbc
	ld xwa, xbc
	add xwa, xwa
	add xwa, xbc
	sll xwa, 2
	ldl_da xbc, (0x024786)
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
	lda_24 xix, (Bitmap_DigitD_0x11D6)
	ldw_sri HL, 0x07, 0xf0, 0xec
	lda_24 xix, (AcWelcomScreen_RenderBytecode)
	jp_ind 8, 0x07, 0xf0, 0xec
AcWelcomScreen_RenderBytecode:
	ld	xwa, 0xffffffff
	ld	xbc, 0x1e000b3
	lds32	xde, 0
	jrl	987
	ld	iz, (xbc+10)
	cps	iz, 2
	jrl	ge, 873
	ld	bc, iz
	muls	bc, 12
	lda_24	xwa, (0x3ea0c)
	.byte 0xf3
	reti
	.byte 0xe0, 0xe4
	ldw	wa, 2712
	push	xsp
	swi	7
	swi	7
	jr	z, 26
	cp	iz, 0xffff
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
	ldw_da	wa, (0x24784)
	exts	xwa
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	sll	xbc, 2
	addda32_24	xbc, (0x24786)
	lda	xiy, (xbc+4)
	lda	xix, (xsp+12)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	lda	xwa, (xsp+12)
	ldw	bc, 30
	call	ClipBlit_Replace
	cp	iz, 0xffff
	jrl	z, 776
	muls	iz, 12
	lda_24	xwa, (0x3ea0c)
	ldw_da	bc, (0x24784)
	exts	xbc
	ld	xiy, xbc
	add	xiy, xiy
	add	xiy, xbc
	sll	xiy, 2
	addda32_24	xiy, (0x24786)
	.byte 0xf3
	reti
	.byte 0xe0
	swi	0
	ldw	ix, 0xaed9
	.byte 0x95
	scf
	jrl	734
	ld	xwa, (xsp+20)
	ld	xbc, 0x1c0000c
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
	ld	xbc, NakaInst_TOTAL_0x34
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
	ld	xbc, Bitmap_DigitL_0x44
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
	ld	xbc, Bitmap_DigitD
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
	ld	xbc, Bitmap_DigitL_0x22
	ldw	de, 16
	call	DrawBitmapSP2
	jrl	510
	lda_24	xhl, (0x3ea24)
	.byte 0x9b
	ldwio	63, 0xffff
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
	ldw_da	bc, (0x24784)
	exts	xbc
	ld	xde, xbc
	add	xde, xde
	add	xde, xbc
	sll	xde, 2
	ldl_da	xbc, (0x24786)
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
	ldw_da	wa, (0x24784)
	exts	xwa
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	sll	xbc, 2
	addda32_24	xbc, (0x24786)
	lda	xiy, (xbc+4)
	lda	xix, (xsp+12)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	lda	xwa, (xsp+12)
	pushw	17
	ldw_da	bc, (0x24784)
	exts	xbc
	ld	xde, xbc
	add	xde, xde
	add	xde, xbc
	sll	xde, 2
	addda32_24	xde, (0x24786)
	.byte 0x9a
	ldwio	4, 0xf70b
	nop
	ld	xbc, NakaInst_TOTAL_0x34
	ldw	de, 16
	call	DrawBitmapSP2
	lda	xwa, (xsp+12)
	.byte 0x90
	push	xwa
	rcf
	nop
	pushw	17
	ldw_da	bc, (0x24784)
	exts	xbc
	ld	xde, xbc
	add	xde, xde
	add	xde, xbc
	sll	xde, 2
	addda32_24	xde, (0x24786)
	.byte 0x9a
	ldwio	4, 0xf70b
	nop
	ld	xbc, Bitmap_DigitL_0x44
	ldw	de, 16
	call	DrawBitmapSP2
	lda	xwa, (xsp+12)
	.byte 0x90
	push	xwa
	rcf
	nop
	pushw	17
	ldw_da	bc, (0x24784)
	exts	xbc
	ld	xde, xbc
	add	xde, xde
	add	xde, xbc
	sll	xde, 2
	addda32_24	xde, (0x24786)
	.byte 0x9a
	ldwio	4, 0xf70b
	nop
	ld	xbc, Bitmap_DigitL
	ldw	de, 16
	call	DrawBitmapSP2
	lda	xwa, (xsp+12)
	.byte 0x90
	push	xwa
	rcf
	nop
	pushw	17
	ldw_da	bc, (0x24784)
	exts	xbc
	ld	xde, xbc
	add	xde, xde
	add	xde, xbc
	sll	xde, 2
	addda32_24	xde, (0x24786)
	.byte 0x9a
	ldwio	4, 0xf70b
	nop
	ld	xbc, Bitmap_DigitL_0x44
	ldw	de, 16
	call	DrawBitmapSP2
	ldw_da	wa, (0x24784)
	exts	xwa
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	sll	xbc, 2
	ldl_da	xwa, (0x24786)
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
	ldw_da	bc, (0x24784)
	exts	xbc
	ld	xde, xbc
	add	xde, xde
	add	xde, xbc
	sll	xde, 2
	ldl_da	xbc, (0x24786)
	add	xde, xbc
	.byte 0x9a
	ldwio	4, 0xf70b
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
	ldw_da	bc, (0x24784)
	exts	xbc
	ld	xde, xbc
	add	xde, xde
	add	xde, xbc
	sll	xde, 2
	addda32_24	xde, (0x24786)
	.byte 0x9a
	ldwio	4, 0xf70b
	nop
	ld	xbc, Bitmap_DigitR
	ldw	de, 16
	call	DrawBitmapSP2
	ldw_da	wa, (0x24784)
	exts	xwa
	ld	xiy, xwa
	add	xiy, xiy
	add	xiy, xwa
	sll	xiy, 2
	addda32_24	xiy, (0x24786)
	ld	xix, 0x3ea24
	lds	bc, 6
	.byte 0x95
	scf
	jr	36
	ld	xwa, 0x120000b
	ld	xbc, 0x1e000ac
	lds32	xde, 0
	call	ApFuncCall
	call	CaptureLcd
	ld	xwa, 0x120000b
	ld	xbc, 0x1e000ad
	lds32	xde, 0
	call	ApFuncCall

AcWelcomScreen_Select_NextStep:
	ldw_da xwa, (0x024784)
	inc 1, wa
	stw_da (0x024784), xwa
	exts xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 2
	addda32_24 xbc, (0x24786)
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
	.incbin "includes/generated/v7_transplant_AcWelcomScreen_SubCpuError.bin"
AcWelcomScreen_SubCpuLoaded:
	.incbin "includes/generated/v7_transplant_AcWelcomScreen_SubCpuLoaded.bin"
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
	add xbc, TrackName4_Tr1_0x2E
	ld bc, (xbc)
	lda_24 xix, (PsMixer_ControlHandler)
	jp_ind 8, 0x07, 0xf0, 0xe4

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
	stw_da (0x02478a), xhl

AudioCtrl_InitCounters:
	stiw_da (0x024794), 0x0000
	stiw_da (0x024790), 0x0000
	stiw_da (0x024796), 0x0000
	stiw_da (0x024792), 0x0000
	ldw (xsp + 10), 0x0

AudioCtrl_ScanLoop:
	ld wa, (xsp + 10)
	calr Util_SignExtendAndDouble
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	cpw (xwa + 6), 0x1
	jr nz, AudioCtrl_ScanNext
	ld wa, (xsp + 10)
	stw_da (0x024792), xwa
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
	ldw_da xde, (0x02478a)
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
	ldw_da xbc, (0x024792)
	extz xbc
	ldw_da xwa, (0x024790)
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 90)
	ld xbc, 0x1c00017
	call SetDialUp
	ldw_da xbc, (0x024792)
	extz xbc
	ldw_da xwa, (0x024790)
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
	ldw_da xwa, (0x024796)
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
	lda_24 xbc, (Bitmap_DigitD_0x11F0)
	stb_dri C, 0x07, 0xe4, 0xe0
	ld xwa, (xsp + 90)
	ld xbc, 0x1c0000d
	ld xhl, (xhl)
	call (xhl)
	ld de, (xsp + 8)
	lda_24 xbc, (Bitmap_DigitD_0x11F0)
	extz xde
	ld xwa, (xsp + 4)
	ld wa, (xwa + 2)
	sla wa, 2
	stb_dri C, 0x07, 0xe4, 0xe0
	ldw_da xwa, (0x024792)
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
	ldw_da xiz, (0x024794)
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
	lda_24 xbc, (Bitmap_DigitD_0x11F0)
	stb_dri C, 0x07, 0xe4, 0xe0
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
	ldw_da xwa, (0x024790)
	calr PsMixer_ReadWordArrayEntry
	ldw_erp HL, 0xfa
	stw_erp WA, 0xfa
	add wa, wa
	lda_24 xbc, (MixerPartTable_Start_0x12C)
	ldw_sri DE, 0x07, 0xe4, 0xe0
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
	stw_da (0x024796), xwa
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
	stw_da (0x024792), xwa
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
	ldw_da xwa, (0x024794)
	sla wa, 3
	add iz, wa
	cpda16_24 xiz, (0x24790)
	jrl z, PsMixer_Case5_DialSetup
	ld wa, iz
	calr PsMixer_ReadWordArrayEntry
	extz xhl
	add xhl, xhl
	ld xbc, MixerPartTable_Start_0x12C
	add xbc, xhl
	ld de, (xbc)
	exts xde
	ld xwa, 0x1400002
	ld xbc, 0x1e000a0
	call MainFuncCall
	ldw_da xbc, (0x024792)
	extz xbc
	ld wa, iz
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 90)
	ld xbc, 0x1c00017
	call SetDialUp
	ldw_da xbc, (0x024792)
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
	stw_da (0x024790), xiz
	ld xwa, (xsp + 90)
	ld xbc, 0x1e000a7
	lds32 xde, 0
	call SendEvent
	ldw_da xwa, (0x024790)
	calr PsMixer_ReadWordArrayEntry
	extz xhl
	add xhl, xhl
	ld xbc, MixerPartTable_Start_0x12C
	add xbc, xhl
	ld de, (xbc)
	exts xde
	ld xwa, 0x1400004
	ld xbc, 0x1e0005e
	call FuncCall
	jr PsMixer_Case5_SetAutoInc

PsMixer_Case5_DialSetup:
	ld wa, iz
	ldw_da xbc, (0x024792)
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
	ldw_da xwa, (0x024796)
	muls wa, 0x5
	ld (xsp + 8), iz
	submi16 (xsp + 8), 0x88
	add (xsp + 8), wa
	ld wa, (xsp + 8)
	cpda16_24 xwa, (0x24792)
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
	lda_24 xbc, (Bitmap_DigitD_0x11F0)
	stb_dri C, 0x07, 0xe4, 0xe0
	ld xwa, (xsp + 90)
	ld xbc, 0x1c0000e
	ld xhl, (xhl)
	call (xhl)
	ldw_da xwa, (0x024792)
	calr Util_SignExtendAndDouble
	ld (xsp + 4), xhl
	ldw_da xde, (0x024792)
	extz xde
	ld xwa, (xsp + 4)
	ld wa, (xwa + 2)
	sla wa, 2
	lda_24 xbc, (Bitmap_DigitD_0x11F0)
	stb_dri C, 0x07, 0xe4, 0xe0
	ld xwa, (xsp + 90)
	ld xbc, 0x1c0000e
	ld xhl, (xhl)
	call (xhl)
	ld wa, (xsp + 8)
	stw_da (0x024792), xwa
	ld bc, (xsp + 8)
	extz xbc
	ldw_da xwa, (0x024790)
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 90)
	ld xbc, 0x1c00017
	call SetDialUp
	ldw_da xbc, (0x024792)
	extz xbc
	ldw_da xwa, (0x024790)
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
	.incbin "includes/generated/v7_transplant_AudioCtrl_PageHandler.bin"
AudioCtrl_PageAdvance:
	ldw_da xwa, (0x024790)
	exts xwa
	divs wa, 0x8
	stw_erp WA, 0xe2
	stw_da (0x024790), xwa
	stiw_da (0x024794), 0x0000
	ldw_da xwa, (0x024790)
	calr PsMixer_ReadWordArrayEntry
	ldw_erp HL, 0xfa

AudioCtrl_SetupPartDisplay:
	stw_erp WA, 0xfa
	add wa, wa
	lda_24 xbc, (MixerPartTable_Start_0x12C)
	ldw_sri DE, 0x07, 0xe4, 0xe0
	exts xde
	ld xwa, 0x1400002
	ld xbc, 0x1e000a0
	call MainFuncCall
	stw_erp WA, 0xfa
	add wa, wa
	lda_24 xbc, (MixerPartTable_Start_0x12C)
	ldw_sri DE, 0x07, 0xe4, 0xe0
	exts xde
	ld xwa, 0x1400004
	ld xbc, 0x1e0005e
	call FuncCall
	ldw_da xbc, (0x024792)
	extz xbc
	ldw_da xwa, (0x024790)
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 90)
	ld xbc, 0x1c00017
	call SetDialUp
	ldw_da xbc, (0x024792)
	extz xbc
	ldw_da xwa, (0x024790)
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
	ldw_da xwa, (0x024794)
	sla wa, 3
	add iz, wa
	ld wa, iz
	ldw_da xbc, (0x024792)
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
	ldw_da xwa, (0x024794)
	sla wa, 3
	add iz, wa
	ldw_da xbc, (0x024792)
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
	.incbin "includes/generated/v7_transplant_PsMixer_ControlCase8.bin"
PsMixer_MidiScanOuterLoop:
	ld wa, (xsp + 8)
	calr Util_SignExtendAndDouble
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld wa, (xwa)
	sla wa, 2
	lda_24 xbc, (MixerPartTable_Start_0x80)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld (xsp + 14), xwa
	ldw_da xiz, (0x024794)
	sla iz, 3
	ldw (xsp + 12), 0x0

; PsMixer array read handler
PsMixer_ArrayReadHandler:
	ld wa, iz
	calr PsMixer_ReadWordArrayEntry
	ldw_erp HL, 0xfa
	stw_erp DE, 0xfa
	exts xde
	ld xwa, (xsp + 14)
	ld xbc, 0x1e10000
	call ApFuncCall
	cp hl, (xsp + 68)
	jrl nz, AudioCtrl_MixerLoopNext
	stw_erp DE, 0xfa
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
	lda_24 xbc, (Bitmap_DigitD_0x11F0)
	stb_dri C, 0x07, 0xe4, 0xe0
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
	lda_24 xbc, (Bitmap_DigitD_0x11F0)
	stb_dri C, 0x07, 0xe4, 0xe0
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
	lda_24 xbc, (Bitmap_DigitD_0x11F0)
	stb_dri C, 0x07, 0xe4, 0xe0
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
	lda_24 xbc, (MixerPartTable_Start_0x80)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld (xsp + 14), xwa
	ldw_da xiz, (0x024794)
	sla iz, 3
	ldw (xsp + 12), 0x0

; AudioCtrl array read handler
AudioCtrl_ArrayReadHandler:
	ld wa, iz
	calr PsMixer_ReadWordArrayEntry
	ldw_erp HL, 0xfa
	stw_erp DE, 0xfa
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
	lda_24 xbc, (Bitmap_DigitD_0x11F0)
	stb_dri C, 0x07, 0xe4, 0xe0
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
	lda_24 xbc, (Bitmap_DigitD_0x11F0)
	stb_dri C, 0x07, 0xe4, 0xe0
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
	lda_24 xbc, (Bitmap_DigitD_0x11F0)
	stb_dri C, 0x07, 0xe4, 0xe0
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
	ldw_da xwa, (0x024790)
	calr PsMixer_ReadWordArrayEntry
	extz xhl
	add xhl, xhl
	ld xbc, MixerPartTable_Start_0x12C
	add xbc, xhl
	cpw (xbc), 0x10
	jrl ge, AudioCtrl_ReturnZero
	call GetPartSelect
	ld xwa, MixerPartTable_Start_0x12C
	ld bc, hl
	calr SdpartLookupPartId
	ldw_erp HL, 0xfa
	cp_erpw 0xfa, 0xff, 0xff
	jrl z, AudioCtrl_ReturnZero
	ldw_da xwa, (0x024790)
	calr PsMixer_ReadWordArrayEntry
	stw_erp WA, 0xfa
	cp wa, hl
	jr nz, PsMixer_VolSel_SearchGrid
	ldw_da xiz, (0x024790)
	jr PsMixer_VolumeSelect_Continue

PsMixer_VolSel_SearchGrid:
	ldw_da xiz, (0x024794)
	sla iz, 3
	ldw (xsp + 10), 0x0

PsMixer_VolSel_SearchLoop:
	ld wa, iz
	calr PsMixer_ReadWordArrayEntry
	stw_erp WA, 0xfa
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
	stw_erp WA, 0xfa
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
	ldw_da xwa, (0x024790)
	cp wa, iz
	jrl z, AudioCtrl_ReturnZero
	stw_da (0x024790), xiz
	ld wa, iz
	exts xwa
	divs wa, 0x8
	stw_da (0x024794), xwa
	stw_erp WA, 0xfa
	add wa, wa
	lda_24 xbc, (MixerPartTable_Start_0x12C)
	ldw_sri DE, 0x07, 0xe4, 0xe0
	exts xde
	ld xwa, 0x1400004
	ld xbc, 0x1e0005e
	call FuncCall
	ldw_da xbc, (0x024792)
	extz xbc
	ldw_da xwa, (0x024790)
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 90)
	ld xbc, 0x1c00017
	call SetDialUp
	ldw_da xbc, (0x024792)
	extz xbc
	ldw_da xwa, (0x024790)
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
	.incbin "includes/generated/v7_transplant_PsMixer_SendEventAndForward.bin"
PsMixer_EventFwd_Setup:
	ldw_da xwa, (0x024796)
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
	lda_24 xbc, (MixerPartTable_Start_0x80)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld (xsp + 14), xwa
	cp xwa, 0x1210027
	jr nz, PsMixer_EventFwd_Next
	ld wa, (xde + 2)
	sla wa, 2
	lda_24 xbc, (Bitmap_DigitD_0x11F0)
	stb_dri C, 0x07, 0xe4, 0xe0
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
	.incbin "includes/generated/v7_transplant_PsMixer_ControlCommon.bin"
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
	ld xwa, TrackName4_Tr1_0x42
	calr Util_StorePartArrayBase
	ld xwa, MidiParamStr2_Sound_0x8
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
	ld xiy, MidiParam_MixerCfgData_0x2
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
	ld xwa, MidiParamStr2_Sound_0x48
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
	addda32_24 xhl, (0x3ea30)
	ret

Util_StorePartArrayBase:
	stl_da (0x03ea30), xwa
	ret

PsMixer_ReadWordArrayEntry:
	exts xwa
	add xwa, xwa
	addda32_24 xwa, (0x3ea34)
	ld hl, (xwa)
	ret

Util_StoreGridArrayBase:
	stl_da (0x03ea34), xwa
	ret

AudioCtrl_DataBlock:
	.incbin "includes/generated/v7_transplant_AudioCtrl_DataBlock.bin"
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
	stiw_da (0x024798), 0x0000
	call GetPartSelect
	stw_da (0x02479a), xhl
	stiw_da (0x03e99e), 0x0000
	call GetModeNow
	cp xhl, 0x1800003
	jr z, IvDrawbar_Init_CheckDualMode
	ld xwa, (xsp + 8)
	ld xbc, 0x1e10008
	lds32 xde, 0
	jr IvDrawbar_Init_DispatchLoadVals

IvDrawbar_Init_CheckDualMode:
	ldb_da a, (0x0205f2)
	bit 0, a
	jr z, IvDrawbar_Init_SetupMode
	res 0, a
	stb_da (0x0205f2), a
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
	ld xwa, Presentation_TagStrTable_0x1E
	ld xbc, 0x1c00002
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ldw_da xde, (0x024798)
	inc 1, de
	exts xde
	ld xwa, 0xffffffff
	ld xbc, 0x1c00035
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call SendEvent
	ld xwa, Presentation_TagStrTable_0x16
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
	ld xwa, Presentation_TagStrTable_0x16
	ld xbc, 0x1c00002
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ldw_da xde, (0x024798)
	inc 1, de
	exts xde
	ld xwa, 0xffffffff
	ld xbc, 0x1c00035
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call SendEvent
	ld xwa, Presentation_TagStrTable_0x1E
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
	stw_da (0x02479a), xhl
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
	.incbin "includes/generated/v7_transplant_IvDrawbar_LoadVals.bin"
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
	cpw_da (0x247c2), 0
	jr z, IvDrawbar_DrawbarUpdate_UpperOff
	ld xwa, Presentation_RootEntry_0x3
	ld xbc, 0x1e0003b
	lds32 xde, 1
	call SendEvent
	ld xwa, Presentation_RootEntry_0x4
	ld xbc, 0x1c0000d
	lds32 xde, 0
	jrl IvDrawbar_DispatchEvent

IvDrawbar_DrawbarUpdate_UpperOff:
	ld xwa, Presentation_RootEntry_0x3
	ld xbc, 0x1e0003b
	lds32 xde, 0
	call SendEvent
	ld xwa, Presentation_RootEntry_0x5
	ld xbc, 0x1c0000d
	lds32 xde, 0
	jrl IvDrawbar_DispatchEvent

IvDrawbar_DrawbarUpdate_Lower:
	ldw_da xde, (0x0247c4)
	exts xde
	ld xwa, Presentation_RootEntry_0x2
	ld xbc, 0x1e0003b
	jrl IvDrawbar_DispatchEvent

IvDrawbar_OK:
	ld xwa, (xsp + 4)
	cp xwa, 0xf
	jr nz, IvDrawbar_OK_Forward
	cpw_da (0x24798), 0
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
	stiw_da (0x024798), 0x0000
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
	cpw_da (0x24798), 0
	scc16 z, wa
	stw_da (0x024798), xwa
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
	ldw_da xwa, (0x02479a)
	pushw 0x4
	ldw bc, 0x2c1
	lds de, 1
	jr IvDrawbar_Release_WriteValue

IvDrawbar_Release_Upper_DualMode:
	cpw_da (0x247c2), 0
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
	ldw_da xwa, (0x02479a)
	pushw 0x4
	ldw bc, 0x2c0
	lds de, 1

IvDrawbar_Release_WriteValue:
	call MainLswPartPut
	jrl IvDrawbar_ReturnHandled

IvDrawbar_Release_Lower_DualMode:
	cpw_da (0x247c4), 0
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
	ldw_da xbc, (0x02479a)
	cp bc, wa
	jrl nz, IvDrawbar_ReturnHandled
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldiw_erp 0xe2, 0
	ld bc, wa
	srl bc, 8
	ldb b, 0x0
	cp c, 0xc
	jr nz, IvDrawbar_Update_GenericParam
	extz wa
	stw_da (0x02479c), xwa
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
	ldw_da xbc, (0x02479a)
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
	stw_da (0x0247c2), xbc
	ld xwa, (xsp + 8)
	ld xbc, 0x1e000a7
	lds32 xde, 2
	jr IvDrawbar_Match_DispatchEvent

IvDrawbar_Match_CheckLower:
	add xde, 0x82c0
	cp xde, (xhl)
	jr nz, IvDrawbar_Match_Forward
	stw_da (0x0247c4), xbc
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
	stw_da (0x02479a), xhl
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
	.incbin "includes/generated/v7_transplant_IvDrawbar_GetText.bin"
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
	ldiw_erp 0xe6, 0
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
	ldiw_erp 0xe2, 0
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
	.incbin "includes/generated/v7_transplant_DrawCombo_GetText.bin"
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
	.incbin "includes/generated/v7_transplant_LswPercDecay.bin"
LswPercDecay_PartIdLookup:
	add xde, xde
	ld xwa, MixerPartTable_Start_0x12C
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
	stw_da (0x0247c6), xde
	jr LswPercDecay_Return

Lsw_PercDecay_DialScroll:
	ld xwa, xbc
	lds bc, 1
	lds de, 1
	calr SdpartScrollDelta
	ld bc, hl
	ldw_da xwa, (0x0247c6)
	calr SdpartClampSignedScrollDelta
	cpda16_24 xhl, (0x247c6)
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
	.incbin "includes/generated/v7_transplant_LswPercLevel.bin"
LswPercLevel_PartIdLookup:
	add xde, xde
	ld xwa, MixerPartTable_Start_0x12C
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
	stw_da (0x0247c8), xde
	jr LswPercLevel_Return

Lsw_PercLevel_DialScroll:
	ld xwa, xbc
	lds bc, 1
	lds de, 1
	calr SdpartScrollDelta
	ld bc, hl
	ldw_da xwa, (0x0247c8)
	calr SdpartClampSignedScrollDelta
	cpda16_24 xhl, (0x247c8)
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
	.incbin "includes/generated/v7_transplant_LswDrawAttack.bin"
LswDrawAttack_PartIdLookup:
	add xde, xde
	ld xwa, MixerPartTable_Start_0x12C
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
	stw_da (0x0247cc), xde
	jr LswDrawAttack_Return

Lsw_DrawAttack_DialScroll:
	ld xwa, xbc
	lds bc, 1
	lds de, 1
	calr SdpartScrollDelta
	ld bc, hl
	ldw_da xwa, (0x0247cc)
	calr SdpartClampSignedScrollDelta
	cpda16_24 xhl, (0x247cc)
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
	.incbin "includes/generated/v7_transplant_LswDrawRelease.bin"
LswDrawRelease_PartIdLookup:
	add xde, xde
	ld xwa, MixerPartTable_Start_0x12C
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
	stw_da (0x0247ca), xde
	jr LswDrawRelease_Return

Lsw_DrawRelease_DialScroll:
	ld xwa, xbc
	lds bc, 1
	lds de, 1
	calr SdpartScrollDelta
	ld bc, hl
	ldw_da xwa, (0x0247ca)
	calr SdpartClampSignedScrollDelta
	cpda16_24 xhl, (0x247ca)
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
	stw_da (0x02479a), xhl
	ld xwa, (xsp + 12)
	ld xbc, 0x1e10008
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	ldw_da xde, (0x024798)
	exts xde
	ld xwa, Presentation_TagStrTable_0x4
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
	.incbin "includes/generated/v7_transplant_IvDrawbar1_LoadVals_Loop.bin"
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
	ldw_erp HL, 0xfa
	cpiw_erp 0xfa, 7
	jr le, IvDrawbar1_OK_CheckSixteen
	cp_erpw 0xfa, 0x10, 0x00
	jrl nz, IvDrawbar1_OK_Forward

IvDrawbar1_OK_CheckSixteen:
	cp_erpw 0xfa, 0x10, 0x00
	jr nz, IvDrawbar1_OK_ComputeNewValue
	ldi_erpw 0xfa, 0x08, 0x00

IvDrawbar1_OK_ComputeNewValue:
	stw_erp BC, 0xfa
	add bc, bc
	lda_24 xwa, (0x0247b0)
	ldw_sri IZ, 0x07, 0xe0, 0xe4
	ld xwa, (xsp + 4)
	bit 7, wa
	jr z, IvDrawbar1_OK_ScrollDown
	inc 1, iz
	cp iz, 0x8
	jrl gt, IvDrawbar1_ReturnHandled
	call GetModeNow
	cp xhl, 0x1800003
	jr z, IvDrawbar1_OK_ScrollUp_DualMode
	ldw_da xwa, (0x02479a)
	stw_erp BC, 0xfa
	add bc, bc
	lda_24 xde, (MidiParam_MixerCfgData_0x78)
	ldw_sri BC, 0x07, 0xe8, 0xe4
	pushw 0x4
	ld de, iz
	call MainLswPartPut
	jr IvDrawbar1_OK_ScrollRelease

IvDrawbar1_OK_ScrollUp_DualMode:
	stw_erp BC, 0xfa
	add bc, bc
	lda_24 xwa, (0x0247b0)
	ldw_sri WA, 0x07, 0xe0, 0xe4
	cp wa, 0x8
	jr ge, IvDrawbar1_OK_ScrollRelease
	inc 1, wa
	ld bc, wa
	extz xbc
	stw_erp WA, 0xfa
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
	stw_erp BC, 0xfa
	add bc, bc
	cp xhl, 0x1800003
	jr z, IvDrawbar1_OK_ScrollDown_DualMode
	ldw_da xwa, (0x02479a)
	lda_24 xde, (MidiParam_MixerCfgData_0x78)
	ldw_sri BC, 0x07, 0xe8, 0xe4
	pushw 0x4
	ld de, iz
	call MainLswPartPut
	jr IvDrawbar1_OK_ScrollDown_Release

IvDrawbar1_OK_ScrollDown_DualMode:
	lda_24 xwa, (0x0247b0)
	ldw_sri WA, 0x07, 0xe0, 0xe4
	cps wa, 0
	jr le, IvDrawbar1_OK_ScrollDown_Release
	dec 1, wa
	ld bc, wa
	extz xbc
	stw_erp WA, 0xfa
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
	ldw_da xde, (0x02479a)
	exts xde
	sll xde, 10
	ld xbc, xde
	add xbc, 0x8280
	ld xwa, (xsp + 4)
	lda xhl, (xwa + 4)
	cp xbc, (xwa)
	jr nz, IvDrawbar1_Match_Ch1
	ld wa, (xhl)
	stw_da (0x0247b0), xwa
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
	stw_da (0x0247b2), xwa
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
	stw_da (0x0247b4), xwa
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
	stw_da (0x0247b6), xwa
	ld xwa, (xsp + 12)
	ld xbc, 0x1e000a7
	lds32 xde, 3
	jrl IvDrawbar1_Match_DispatchUpdate

IvDrawbar1_Match_Ch4:
	ld xwa, xde
	add xwa, 0x8284
	lda_24 xbc, (0x0247b0)
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
	stw_da (0x02479a), xhl
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
	.incbin "includes/generated/v7_transplant_IvDrawbar1_GetText.bin"
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
	stw_da (0x02479a), xhl
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ldw_da xde, (0x024798)
	exts xde
	ld xwa, Presentation_TagStrTable_0x4
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
	.incbin "includes/generated/v7_transplant_IvDrawbar2_LoadValsHandler.bin"
IvDrawbar2_LoadMode3:
	ld xwa, 0x1410001
	ld xbc, 0x1e10008
	lds32 xde, 0
	jrl IvDrawbar2_MainFuncCallShared

IvDrawbar2_MatchHandler:
	ld xhl, (xsp + 4)
	ldw_da xbc, (0x02479a)
	exts xbc
	sll xbc, 10
	ld xix, xbc
	add xix, 0x82cc
	ld xwa, (xsp + 4)
	lda xde, (xwa + 4)
	cp xix, (xwa)
	jr nz, IvDrawbar2_MatchCheck2CB
	ld wa, (xde)
	stw_da (0x0247c6), xwa
	jr IvDrawbar_ForwardUnhandled

IvDrawbar2_MatchCheck2CB:
	ld xwa, xbc
	add xwa, 0x82cb
	cp xwa, (xhl)
	jr nz, IvDrawbar2_MatchCheck294
	ld wa, (xde)
	stw_da (0x0247c8), xwa
	jr IvDrawbar_ForwardUnhandled

IvDrawbar2_MatchCheck294:
	ld xix, xbc
	add xix, 0x8294
	ld wa, (xde)
	cp xix, (xhl)
	jr nz, IvDrawbar2_MatchCheck293
	stw_da (0x0247cc), xwa
	jr IvDrawbar_ForwardUnhandled

IvDrawbar2_MatchCheck293:
	add xbc, 0x8293
	cp xbc, (xhl)
	jr nz, IvDrawbar_ForwardUnhandled
	stw_da (0x0247ca), xwa

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
	ldw_da xbc, (0x02479a)
	extz xbc
	cpw_da (0x2479c), 0
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
	.incbin "includes/generated/v7_transplant_IvDrawbar2_GetText.bin"
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
	.incbin "includes/generated/v7_transplant_DrawbarNorm_Update.bin"
DrawbarNorm_UpdateCase4:
	ldw_da xwa, (0x02479a)
	sla wa, 2
	lda_24 xbc, (0x03e9a0)
	ld_sril3 XDE, 0x07, 0xe4, 0xe0
	ld xwa, Presentation_TagStrTable_0x17
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
	stw_da (0x02479a), xhl
	ld xwa, (xsp + 8)
	ld xbc, 0x1e000a7
	lds32 xde, 4

IvDrawbarNorm_SendEvent:
	call SendEvent
	jr IvDrawbarNorm_ReturnZeroJmp

DrawbarNorm_GetText:
	.incbin "includes/generated/v7_transplant_DrawbarNorm_GetText.bin"
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
	.incbin "includes/generated/v7_transplant_DrawbarSndE_GetText.bin"
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
	lda_24 xix, (KeyShiftStr_Zero_0x28)
	ldw_sri HL, 0x07, 0xf0, 0xec
	ld (xwa), hl
	ldw (xwa + 2), 0x72
	sla de, 2
	lda_24 xhl, (0x03ec28)
	ld_sril3 XDE, 0x07, 0xec, 0xe8
	sla bc, 2
	lda_24 xhl, (KeyShiftStr_Zero_0x3A)
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
	.incbin "includes/generated/v7_transplant_MemDraw_ParamLoopBody.bin"
MemDraw_UpdateItem:
	ld xwa, (xsp + 2)
	srl xwa, 0
	ldiw_erp 0xe2, 0
	ld xbc, (xsp + 2)
	calr DemoMenu_BuildItemWorkspace
	ld xwa, (xsp + 2)
	srl xwa, 0
	ldiw_erp 0xe2, 0
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
	.incbin "includes/generated/v7_transplant_DemoMenu_BuildItemWorkspace.bin"
DemoMenu_WorkspaceFunc:
	ld wa, (xsp + 6)
	sub wa, 0x9
	cps wa, 0
	jr c, DemoMenu_BuildItemWorkspace_Post
	cps wa, 5
	jr ugt, DemoMenu_BuildItemWorkspace_Post
	add wa, wa
	lda_24 xix, (KeyShiftStr_Zero_0x5E)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	lda_24 xix, (DemoMenu_WorkspaceDispatch)
	jp_ind 8, 0x07, 0xf0, 0xe0

; DemoMenu workspace dispatch (6-entry, table 0xe9f984)
DemoMenu_WorkspaceDispatch:
	stw_da	(0x247e0), iz
	jr	42
	stw_da	(0x247e2), iz
	jr	35
	stw_da	(0x247e4), iz
	jr	19
	stw_da	(0x247e6), iz
	jr	12
	stw_da	(0x247e8), iz
	jr	5
	stw_da	(0x247ea), iz
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
	lda_24 xix, (KeyShiftStr_Zero_0x6A)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	lda_24 xix, (DemoDesc_DispatchTable)
	jp_ind 8, 0x07, 0xf0, 0xe0

DemoDesc_DispatchTable:
	ldw_da	hl, (0x247e0)
	ret
	ldw_da	hl, (0x247e2)
	ret
	ldw_da	hl, (0x247e4)
	ret
	ldw_da	hl, (0x247e6)
	ret
	ldw_da	hl, (0x247e8)
	ret
	ldw_da	hl, (0x247ea)
	ret

; DemoMenu descriptor return
DemoMenu_DescriptorReturn:
	lds hl, 0
	ret

DemoDesc_BuildCompactParams:
	ldw_da xbc, (0x0247e6)
	sla bc, 4
	addda16_24 xbc, (0x247e4)
	ld (xwa), c
	ldw_da xbc, (0x0247ea)
	sla bc, 4
	addda16_24 xbc, (0x247e8)
	ld (xwa + 1), c
	lda_24 xbc, (0x0247ce)
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
	ldw_da xde, (0x0247e2)
	sla de, 4
	add de, (xbc + 16)
	ldw_da xbc, (0x0247e0)
	sla bc, 5
	add bc, de
	ld (xwa + 6), c
	ret

DemoDesc_DataByte:
	ret

PsVariBoxProc:
	stb_dri L, 0xfd, 0xe8, 0xfe
	push xiz
	stl_dri XDE, 0xfd, 0x14, 0x01
	ld xiz, xbc
	stl_dri XWA, 0xfd, 0x18, 0x01
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
	cpl_sri_rm XBC, 0xfd, 0x14, 0x01
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
	stb_dri A, 0xfd, 0x08, 0x01
	ld_sril XWA, (xsp + 0x0118)
	call GetBox
	stb_dri W, 0xfd, 0x08, 0x01
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
	stb_dri A, 0xfd, 0x08, 0x01
	ld_sril XWA, (xsp + 0x0118)
	call GetClientBox
	stb_dri W, 0xfd, 0x08, 0x01
	stb_dri A, 0xfd, 0x10, 0x01
	call GetBoxCenter
	lda xde, (xsp + 8)
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, 0x1e0003a
	call SendEvent
	ld xwa, (xsp + 4)
	ld xiz, (xwa + 38)
	stb_dri A, 0xfd, 0x10, 0x01
	stb_dri B, 0xfd, 0x08, 0x01
	lda xhl, (xsp + 8)
	lda xiy, (xwa + 28)
	ld a, (xwa + 34)
	ldb_erp A, 0xf0
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
	.incbin "includes/generated/v7_transplant_PsVari_GetText.bin"
PsVari_OK:
	ld_sril XWA, (xsp + 0x0118)
	call GetViewInstance
	ld wa, (xhl + 36)
	extz xwa
	cpl_sri_rm XWA, 0xfd, 0x14, 0x01
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
	cpl_sri_rm XWA, 0xfd, 0x14, 0x01
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
	cpl_sri_rm XWA, 0xfd, 0x14, 0x01
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
	stb_dri L, 0xfd, 0x18, 0x01
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
	ld xwa, Pad_NakaExternal_Block1
	ld xbc, 0x1c00001
	lds32 xde, 5
	jr FdemoScreen_SendStart

FdemoScreen_StartPanel2:
	ld xwa, Pad_AfterNakaData_ExternalBase
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
	.incbin "includes/generated/v7_transplant_Demofeat1_GetText.bin"
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
	ld xwa, Bitmap_Dredt0d_0x9A8
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
	.incbin "includes/generated/v7_transplant_Demofeat2_GetText.bin"
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
	stb_d8 (0x28a4), a
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
	ld xwa, Bitmap_Dredt0d_0x9AA
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
	.incbin "includes/generated/v7_transplant_PresBox_GetText.bin"
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
	add xbc, KeyShiftStr_Zero_0x8C
	ld bc, (xbc)
	lda_24 xix, (AcPresCtrl_EventDispatch)
	jp_ind 8, 0x07, 0xf0, 0xe4
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
	ld xwa, NakaData_ExternalBase
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
	stiw_da (0x0340fc), 0x0000
	stiw_da (0x0340fa), 0x0000
	stiw_da (0x0340fe), 0x0000
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
