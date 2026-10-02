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
	ld xiy, AcSendEditSwProc_LocalInit
	lda xix, (xsp + 4)
	ld bc, 5:i3
	ldirw
	ld xwa, (xsp + 18)
	cp xwa, EVT_SW_OFF
	jrl z, AcSendEditSw_Event9
	cp xwa, EVT_SW_ON
	jr z, AcSendEditSw_Event8
	cp xwa, EVT_DRAW
	jr z, AcSendEditSw_EventD
	ld xwa, (xsp + 22)
	ld xbc, (xsp + 18)
	ld xde, (xsp + 14)
	jrl AcSendEditSw_CallInherited
AcSendEditSw_EventD:
	ld	xwa, (xsp+22)
	call	GetViewInstance
	ld	xiz, xhl
	ld	xwa, (xiz+48)
	ld	wa, (xwa)
	ld	(xiz+24), wa
	ld	xwa, (xsp+22)
	ld	xbc, (xsp+18)
	ld	xde, (xsp+14)
	call	InheritedProc
	ld	xwa, (xiz+44)
	push	xwa
	lda	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	xbc, (xiz+48)
	lda	xde, (xsp+4)
	lda	xwa, (AcSendEditSw_EventD_Table:24)
	cpw	(xbc), 193
	jr	nz, AcSendEditSw_DrawAlt
	ld	xbc, 0:i3
	push	xbc
	pushw 0
	pushw 247
	ld	xbc, NakaData_ModeConfig1
	jr	AcSendEditSw_DrawString
AcSendEditSw_DrawAlt:
	ld xbc, 0:i3
	push xbc
	pushw 0x0
	pushw 0xf7
	ld xbc, AcSendEditSw_DrawAlt_Table

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
	ld xbc, EVT_DRAW
	ld xde, 0:i3
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
	ld xbc, EVT_DRAW
	ld xde, 0:i3

AcSendEditSw_SendEvent:
	call SendEvent

AcSendEditSw_ReturnZero:
	ld xhl, 0:i3
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
	cp xbc, EVT_REPAINT
	jr z, TtComSet_ReturnZero
	cp xbc, EVT_PAINT
	jr z, TtComSet_ReturnZero
	cp xbc, EVT_HIDE
	jr z, TtComSet_ReturnZero
	cp xbc, EVT_SHOW
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
	ld xhl, 0:i3
	ret

ComSetGridCheck:
	lda xsp, (xsp - 22)
	push xiz
	ld (xsp + 22), xde
	ld xde, xbc
	ld xiy, ComSetGridCheck_LocalInit_2
	lda xix, (xsp + 12)
	ld bc, 5:i3
	ldirw
	ld xiy, ComSetGridCheck_LocalInit
	lda xix, (xsp + 4)
	ld bc, 4:i3
	ldirw
	ld xwa, xde
	cp xde, EVT_REQUEST_GRID_DRAW
	jrl z, ComSetGrid_EventHandler
	sub xwa, EVT_INDEXSW_UP
	cp xwa, 0x0
	jrl lt, UI_ReturnZero
	cp xwa, 0x6
	jrl gt, UI_ReturnZero
	add xwa, xwa
	add xwa, ComSetGridCheck_CaseTable
	ld wa, (xwa)
	lda xix, (ComSetGridCheck_Evt1C00017:24)
; Computed jump: target = ComSetGridCheck_Evt1C00017 + ComSetGridCheck_CaseTable[i], ComSetGridCheck_CaseTable = 16-bit offsets (7 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1c00017:
;   0x1c00017 -> ComSetGridCheck_Evt1C00017
;   0x1c00018 -> ComSetGridCheck_Evt1C00018
;   0x1c00019 -> ComSetGridCheck_Evt1C00017
;   0x1c0001a -> ComSetGridCheck_Evt1C00018
;   0x1c0001b -> UI_ReturnZero
;   0x1c0001c -> ComSetGridCheck_Evt1C0001C
;   0x1c0001d -> ComSetGridCheck_Evt1C0001C
	jp	t, (xix+wa)
ComSetGridCheck_Evt1C00017:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	ld	(xsp+22), xhl
	lda	xbc, (xsp+4)
	ld	xwa, (xsp+22)
	srl	xwa, 16
	ld	qwa, 0
	ld	(xbc), wa
	ld	xwa, (xsp+22)
	ld	(xbc+2), wa
	cpw	(xbc), 1
	jrl	nz, UI_ReturnZero
	ld	xwa, 192
	call	AcApcToggleProc_Helper
	cp	hl, 1:i3
	jr	nz, ComSetGridCheck_JumpTable_Skip
	ld	wa, (xsp+6)
	sla	wa, 2
	lda	xbc, (ComSetGridCheck_JumpTable_Table:24)
	ld_rrl	xwa, xbc, wa
	cp	xwa, 8705
	jrl	z, UI_ReturnZero
	cp	xwa, 8709
	jrl	z, UI_ReturnZero
ComSetGridCheck_JumpTable_Skip:
	ld	bc, (xsp+6)
	sla	bc, 2
	lda	xwa, (ComSetGridCheck_JumpTable_Table:24)
	ld_rrl	xwa, xwa, bc
	ld	bc, 1:i3
	ld	de, 2:i3
	jr	ComSetGridCheck_JumpTable_Join
ComSetGridCheck_Evt1C00018:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	ld	(xsp+22), xhl
	lda	xbc, (xsp+4)
	ld	xwa, (xsp+22)
	srl	xwa, 16
	ld	qwa, 0
	ld	(xbc), wa
	ld	xwa, (xsp+22)
	ld	(xbc+2), wa
	cpw	(xbc), 1
	jrl	nz, UI_ReturnZero
	ld	xwa, 192
	call	AcApcToggleProc_Helper
	cp	hl, 1:i3
	jr	nz, ComSetGridCheck_JumpTable_Skip2
	ld	wa, (xsp+6)
	sla	wa, 2
	lda	xbc, (ComSetGridCheck_JumpTable_Table:24)
	ld_rrl	xwa, xbc, wa
	cp	xwa, 8705
	jrl	z, UI_ReturnZero
	cp	xwa, 8709
	jrl	z, UI_ReturnZero
ComSetGridCheck_JumpTable_Skip2:
	ld	bc, (xsp+6)
	sla	bc, 2
	lda	xwa, (ComSetGridCheck_JumpTable_Table:24)
	ld_rrl	xwa, xwa, bc
	ldw	bc, 65535
	ld	de, 2:i3
ComSetGridCheck_JumpTable_Join:
	call	MainLswAdd
	jrl	UI_ReturnZero
ComSetGridCheck_Evt1C0001C:
	lda	xhl, (xsp+4)
	ldw	(xhl), 1
	lda	xde, (xhl+2)
	ldw	(xde), 0
	lda	xix, (ComSetGridCheck_JumpTable_Table:24)
	ld	xiz, (xsp+22)
	jr	ComSetGridCheck_JumpTable_Join2
ComSetGridCheck_JumpTable_Loop:
	ld	iy, bc
	sla	iy, 2
	ld	xwa, (xiz)
	cp	xwa, (xix+iy)	; cp xwa, (xix+iy)
	jr	z, ComSetGridCheck_JumpTable_Skip3
	inc	1, bc
	ld	(xde), bc
ComSetGridCheck_JumpTable_Join2:
	ld	bc, (xde)
	cp	bc, 9
	jr	lt, ComSetGridCheck_JumpTable_Loop
ComSetGridCheck_JumpTable_Skip3:
	lda	xde, (xsp+12)
	ld	(xhl+4), xde
	ld	xwa, (xsp+22)
	ld	xwa, (xwa)
	cp	xwa, 8709
	jr	z, ComSetGridCheck_JumpTable_Skip6
	cp	xwa, 8705
	jr	z, ComSetGridCheck_JumpTable_Skip6
	cp	xwa, 8832
	jr	z, ComSetGridCheck_JumpTable_Skip4
	cp	xwa, 8858
	jr	z, ComSetGridCheck_JumpTable_Skip4
	cp	xwa, 172032
	jr	z, ComSetGridCheck_JumpTable_Skip4
	cp	xwa, 172033
	jr	z, ComSetGridCheck_JumpTable_Skip4
	cp	xwa, 8834
	jr	z, ComSetGridCheck_JumpTable_Skip4
	cp	xwa, 8706
	jr	z, ComSetGridCheck_JumpTable_Skip4
	cp	xwa, 8707
	jrl	nz, UI_ReturnZero
ComSetGridCheck_JumpTable_Skip4:
	ld	xbc, ComSetGridCheck_JumpTable_Str
	ld	xwa, (xsp+22)
	cpw	(xwa+4), 0
	jr	z, ComSetGridCheck_JumpTable_Skip5
	ld	xbc, ComSetGridCheck_JumpTable_Table_2
ComSetGridCheck_JumpTable_Skip5:
	push	xbc
	push	xde
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, EVT_GRID_DRAW
	jrl	ComSetGrid_SendEventReturn
ComSetGridCheck_JumpTable_Skip6:
	ld	xwa, 192
	call	AcApcToggleProc_Helper
	cp	hl, 1:i3
	jr	nz, ComSetGridCheck_JumpTable_Skip7
	ld	xwa, ComSetGridCheck_JumpTable_Str_2
	jr	ComSetGridCheck_JumpTable_Join3
ComSetGridCheck_JumpTable_Skip7:
	ld	xwa, (xsp+22)
	ld	wa, (xwa+4)
	cp	wa, 3:i3
	jr	z, ComSetGridCheck_JumpTable_Skip9
	cp	wa, 1:i3
	jr	z, ComSetGridCheck_JumpTable_Skip8
	cp	wa, 0:i3
	jr	nz, ComSetGridCheck_JumpTable_Skip10
	ld	xwa, NakaInst_NORMAL
	jr	ComSetGridCheck_JumpTable_Join3
ComSetGridCheck_JumpTable_Skip8:
	ld	xwa, ComSetGridCheck_JumpTable_Str_3
	jr	ComSetGridCheck_JumpTable_Join3
ComSetGridCheck_JumpTable_Skip9:
	ld	xwa, ComSetGridCheck_JumpTable_Table_3
	jr	ComSetGridCheck_JumpTable_Join3
ComSetGridCheck_JumpTable_Skip10:
	ld	xwa, ComSetGridCheck_JumpTable_Str_4
ComSetGridCheck_JumpTable_Join3:
	push	xwa
	lda	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, EVT_GRID_DRAW
	jrl	ComSetGrid_SendEventReturn
ComSetGrid_EventHandler:
	lda xde, (xsp + 4)
	ld xwa, (xsp + 22)
	srl xwa, 16
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
	lda xbc, (ComSetGridCheck_JumpTable_Table:24)
	ld	xwa, (xbc+wa)
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
	call	AcApcToggleProc_Helper
	lda	xbc, (xsp+12)
	ld	xwa, ComSetGridCheck_ParamDisplay_Str_2
	cp	hl, 0:i3
	jr	z, ComSetGrid_CopyStrAndDispatch
	ld	xwa, ComSetGridCheck_ParamDisplay_Str
ComSetGrid_CopyStrAndDispatch:
	push	xwa
	push	xbc
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, EVT_GRID_DRAW
	jr	ComSetGrid_SendEventReturn
ComSetGrid_CheckC0Param:
	ld	xwa, 192
	call	AcApcToggleProc_Helper
	cp	hl, 1:i3
	jr	nz, ComSetGrid_LookupByColumn
	ld	xwa, ComSetGrid_CopyStrAndDispatch_Str
	jr	UI_DisplayStringAndDispatchEvent
ComSetGrid_LookupByColumn:
	ld	bc, (xsp+6)
	sla	bc, 2
	lda	xwa, (ComSetGridCheck_JumpTable_Table:24)
	ld_rrl	xwa, xwa, bc
	call	AcApcToggleProc_Helper
	cp	hl, 3:i3
	jr	z, ComSetGrid_ParamStr3
	cp	hl, 1:i3
	jr	z, ComSetGrid_ParamStr1
	cp	hl, 0:i3
	jr	nz, ComSetGrid_ParamStrDefault
	ld	xwa, ComSetGrid_LookupByColumn_Str
	jr	UI_DisplayStringAndDispatchEvent
ComSetGrid_ParamStr1:
	ld xwa, ComSetGrid_ParamStr1_Str
	jr UI_DisplayStringAndDispatchEvent

ComSetGrid_ParamStr3:
	ld xwa, ComSetGrid_ParamStr3_Str
	jr UI_DisplayStringAndDispatchEvent

ComSetGrid_ParamStrDefault:
	ld xwa, ComSetGrid_ParamStrDefault_Str

UI_DisplayStringAndDispatchEvent:
	push	xwa
	lda	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, EVT_GRID_DRAW
ComSetGrid_SendEventReturn:
	call SendEvent

UI_ReturnZero:
	ld xhl, 0:i3
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
	cp xbc, EVT_REPAINT
	jr z, TtMdPmemOut_ReturnZero
	cp xbc, EVT_PAINT
	jr z, TtMdPmemOut_ReturnZero
	cp xbc, EVT_HIDE
	jr z, TtMdPmemOut_ReturnZero
	cp xbc, EVT_SHOW
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
	ld xhl, 0:i3
	ret

AcPmemOutLGridBoxProc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 8), xde
	ld (xsp + 12), xbc
	ld (xsp + 16), xwa
	ld xbc, (xsp + 12)
	cp xbc, EVT_REQUEST_GRID_DRAW
	jrl z, AcPmemOutL_CellSelect
	ld xwa, (xsp + 12)
	cp xwa, EVT_GET_FIXED_ROW_STR
	jrl z, AcPmemOutL_GetRowText
	cp xwa, EVT_GET_FIXED_COL_STR
	jrl z, AcPmemOutL_GetColText
	cp xwa, EVT_SHOW
	jr z, AcPmemOutL_Init
	sub xbc, EVT_INDEXSW_UP
	cp xbc, 0x0
	jrl lt, AcPmemOutL_ForwardToBase
	cp xbc, 0x6
	jrl gt, AcPmemOutL_ForwardToBase
	add xbc, xbc
	add xbc, NakaInst_GM_0x5E
	ld bc, (xbc)
	lda xix, (AcPmemOutL_Init:24)
; Computed jump: target = AcPmemOutL_Init + NakaInst_GM_0x5E[i], NakaInst_GM_0x5E = 16-bit offsets (7 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1c00017:
;   0x1c00017 -> AcPmemOutLGridBoxProc_Evt1C00017
;   0x1c00018 -> AcPmemOutLGridBoxProc_Evt1C00017
;   0x1c00019 -> AcPmemOutLGridBoxProc_Evt1C00017
;   0x1c0001a -> AcPmemOutLGridBoxProc_Evt1C00017
;   0x1c0001b -> AcPmemOutL_ForwardToBase
;   0x1c0001c -> AcPmemOutLGridBoxProc_Evt1C0001C
;   0x1c0001d -> AcPmemOutLGridBoxProc_Evt1C0001C
	jp	t, (xix+bc)

AcPmemOutL_Init:
	ld xwa, (xsp + 16)
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld xiz, xhl
	ld wa, iz
	cp wa, 3:i3
	jr z, AcPmemOutL_Init_Cell3
	cp wa, 1:i3
	jr z, AcPmemOutL_Init_Cell01
	cp wa, 0:i3
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
	ld xbc, EVT_INDEXSW_UP
	call SetDialUp
	ld xwa, (xsp + 4)
	ld wa, (xwa + 26)
	ld de, iz
	add de, wa
	extz xde
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_DOWN
	call SetDialDown
	ld wa, 1:i3
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
	ld xbc, EVT_INDEXSW_UP
	call SetDialUp
	ld xwa, (xsp + 4)
	ld wa, (xwa + 26)
	ld bc, iz
	add bc, wa
	inc 1, bc
	ld de, bc
	extz xde
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_DOWN
	call SetDialDown
	ld wa, 1:i3

AcPmemOutL_Init_ScrollCommit:
	call SetDialEnable

AcPmemOutL_Init_ForwardBase:
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	jrl AcPmemOutL_CallBase
AcPmemOutLGridBoxProc_Evt1C00017:
	ld xwa, (xsp + 8)
	cp wa, 3:i3
	jrl z, AcPmemOutL_AutoIncDown_Cell3
	cp wa, 2:i3
	jrl z, AcPmemOutL_AutoIncUp_Cell2
	cp wa, 1:i3
	jrl nz, AcPmemOutL_ReloadAndForward
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 8)
	call SetDialUp
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 8)
	call SetDialDown
	ld wa, 1:i3
	call SetDialEnable
	ld xwa, (xsp + 16)
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld xiz, xhl
	cp iz, 0:i3
	jr z, AcPmemOutL_AutoIncUp_Cell0_FwdParent
	ld xwa, (xsp + 16)
	ld xbc, EVT_SET_SELECTED_CEL
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
	ld xbc, EVT_DRAW
	ld xde, 0:i3
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
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 8)
	call SetDialUp
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 8)
	call SetDialDown
	ld wa, 1:i3
	call SetDialEnable
	ld xwa, (xsp + 16)
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld xiz, xhl
	cp iz, 1:i3
	jr z, AcPmemOutL_AutoIncUp_Cell2_FwdParent
	ld xwa, (xsp + 16)
	ld xbc, EVT_SET_SELECTED_CEL
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
	ld xbc, EVT_DRAW
	ld xde, 0:i3
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
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 8)
	call SetDialUp
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 8)
	call SetDialDown
	ld wa, 1:i3
	call SetDialEnable
	ld xwa, (xsp + 16)
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld xiz, xhl
	cp iz, 3:i3
	jr z, AcPmemOutL_AutoIncDown_Cell3_FwdParent
	ld xwa, (xsp + 16)
	ld xbc, EVT_SET_SELECTED_CEL
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
	ld xbc, EVT_DRAW
	ld xde, 0:i3

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
	call	GetViewInstance
	add	xhl, xiz
	ld	xwa, (xhl)
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	AcPmemOutL_ReturnHandled
AcPmemOutLGridBoxProc_Evt1C0001C:
	ld	xwa, (xsp+16)
	call	GetViewInstance
	ld	xwa, (xhl+70)
	ld	xbc, (xsp+12)
	ld	xde, (xsp+8)
	jr	AcPmemOutL_CellSelect_Forward
AcPmemOutL_CellSelect:
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)

AcPmemOutL_CellSelect_Forward:
	call ApFuncCall

AcPmemOutL_ReturnHandled:
	ld xhl, 0:i3
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
	cp xbc, EVT_REQUEST_GRID_DRAW
	jrl z, AcPmemOutR_CellSelect
	ld xwa, (xsp + 12)
	cp xwa, EVT_GET_FIXED_ROW_STR
	jrl z, AcPmemOutR_GetRowText
	cp xwa, EVT_GET_FIXED_COL_STR
	jrl z, AcPmemOutR_GetColText
	cp xwa, EVT_SHOW
	jr z, AcPmemOutR_Init
	sub xbc, EVT_INDEXSW_UP
	cp xbc, 0x0
	jrl lt, AcPmemOutR_ForwardToBase
	cp xbc, 0x6
	jrl gt, AcPmemOutR_ForwardToBase
	add xbc, xbc
	add xbc, AcPmemOutRGridBoxProc_CaseTable
	ld bc, (xbc)
	lda xix, (AcPmemOutR_Init:24)
; Computed jump: target = AcPmemOutR_Init + AcPmemOutRGridBoxProc_CaseTable[i], AcPmemOutRGridBoxProc_CaseTable = 16-bit offsets (7 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1c00017:
;   0x1c00017 -> AcPmemOutRGridBoxProc_Evt1C00017
;   0x1c00018 -> AcPmemOutRGridBoxProc_Evt1C00017
;   0x1c00019 -> AcPmemOutRGridBoxProc_Evt1C00017
;   0x1c0001a -> AcPmemOutRGridBoxProc_Evt1C00017
;   0x1c0001b -> AcPmemOutR_ForwardToBase
;   0x1c0001c -> AcPmemOutRGridBoxProc_Evt1C0001C
;   0x1c0001d -> AcPmemOutRGridBoxProc_Evt1C0001C
	jp	t, (xix+bc)

AcPmemOutR_Init:
	ld xwa, (xsp + 16)
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld xiz, xhl
	ld wa, iz
	cp wa, 7:i3
	jr z, AcPmemOutR_Init_Cell567
	cp wa, 6:i3
	jr z, AcPmemOutR_Init_Cell567
	cp wa, 5:i3
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
	ld xbc, EVT_INDEXSW_UP
	call SetDialUp
	ld xwa, (xsp + 4)
	ld wa, (xwa + 26)
	ld de, iz
	add de, wa
	extz xde
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_DOWN
	call SetDialDown
	ld wa, 1:i3
	call SetDialEnable

AcPmemOutR_Init_ForwardBase:
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	jrl AcPmemOutR_CallBase
AcPmemOutRGridBoxProc_Evt1C00017:
	ld xwa, (xsp + 8)
	cp wa, 7:i3
	jrl z, AcPmemOutR_AutoIncDown_Cell7
	cp wa, 6:i3
	jrl z, AcPmemOutR_AutoIncUp_Cell6
	cp wa, 5:i3
	jrl nz, AcPmemOutR_ReloadAndForward
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 8)
	call SetDialUp
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 8)
	call SetDialDown
	ld wa, 1:i3
	call SetDialEnable
	ld xwa, (xsp + 16)
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld xiz, xhl
	cp iz, 0:i3
	jr z, AcPmemOutR_AutoIncUp_Cell5_FwdParent
	ld xwa, (xsp + 16)
	ld xbc, EVT_SET_SELECTED_CEL
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
	ld xbc, EVT_DRAW
	ld xde, 0:i3
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
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 8)
	call SetDialUp
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 8)
	call SetDialDown
	ld wa, 1:i3
	call SetDialEnable
	ld xwa, (xsp + 16)
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld xiz, xhl
	cp iz, 1:i3
	jr z, AcPmemOutR_AutoIncUp_Cell6_FwdParent
	ld xwa, (xsp + 16)
	ld xbc, EVT_SET_SELECTED_CEL
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
	ld xbc, EVT_DRAW
	ld xde, 0:i3
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
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 8)
	call SetDialUp
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 8)
	call SetDialDown
	ld wa, 1:i3
	call SetDialEnable
	ld xwa, (xsp + 16)
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld xiz, xhl
	cp iz, 2:i3
	jr z, AcPmemOutR_AutoIncDown_Cell7_FwdParent
	ld xwa, (xsp + 16)
	ld xbc, EVT_SET_SELECTED_CEL
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
	ld xbc, EVT_DRAW
	ld xde, 0:i3

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
	call	GetViewInstance
	add	xhl, xiz
	ld	xwa, (xhl)
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	AcPmemOutR_ReturnHandled
AcPmemOutRGridBoxProc_Evt1C0001C:
	ld	xwa, (xsp+16)
	call	GetViewInstance
	ld	xwa, (xhl+70)
	ld	xbc, (xsp+12)
	ld	xde, (xsp+8)
	jr	AcPmemOutR_CellSelect_Forward
AcPmemOutR_CellSelect:
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)

AcPmemOutR_CellSelect_Forward:
	call ApFuncCall

AcPmemOutR_ReturnHandled:
	ld xhl, 0:i3
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
	ld xiy, PmemOutLGridCheck_LocalInit
	lda xix, (xsp + 44)
	ldw bc, 0x8
	ldirw
	ld xiy, ComSetGridCheck_LocalInit
	lda xix, (xsp + 36)
	ld bc, 4:i3
	ldirw
	ld xix, xde
	lda xwa, (PmemOutLGridCheck_PtrTable:24)
	ld (xsp + 8), xwa
	lda xbc, (xsp + 36)
	lda xwa, (0x1ed400:24)
	ld (xsp + 24), xwa
	lda xwa, (0xf9a0:16)
	ld (xsp + 20), xwa
	lda xwa, (0xfd2c:16)
	sub xwa, (xsp + 20)
	ld xiz, xwa
	lda xiy, (xbc + 2)
	lda xwa, (xbc + 4)
	ld (xsp + 28), xwa
	ld (xsp + 32), xiz
	cp xde, EVT_REQUEST_GRID_DRAW
	jrl z, PmemOutL_GridCheck
	ld xwa, xix
	sub xwa, EVT_INDEXSW_UP
	cp xwa, 0x0
	jrl lt, PmemOutGrid_ReturnZero
	cp xwa, 0x6
	jrl gt, PmemOutGrid_ReturnZero
	add xwa, xwa
	add xwa, PmemOutLGridCheck_CaseTable
	ld wa, (xwa)
	lda xix, (PmemOutLGridCheck_Evt1C00017:24)
; Computed jump: target = PmemOutLGridCheck_Evt1C00017 + PmemOutLGridCheck_CaseTable[i], PmemOutLGridCheck_CaseTable = 16-bit offsets (7 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1c00017:
;   0x1c00017 -> PmemOutLGridCheck_Evt1C00017
;   0x1c00018 -> PmemOutLGridCheck_Evt1C00018
;   0x1c00019 -> PmemOutLGridCheck_Evt1C00017
;   0x1c0001a -> PmemOutLGridCheck_Evt1C00018
;   0x1c0001b -> PmemOutGrid_ReturnZero
;   0x1c0001c -> PmemOutGrid_ReturnZero
;   0x1c0001d -> PmemOutLGridCheck_Evt1C0001D
	jp	t, (xix+wa)

PmemOutLGridCheck_Evt1C00017:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	lda	xwa, (xsp+36)
	ld	xbc, xhl
	srl	xbc, 16
	ld	qbc, 0
	ld	(xwa), bc
	ld	(xwa+2), hl
	cpw	(xwa), 1
	jrl	nz, PmemOutGrid_ReturnZero
	cp	hl, 3:i3
	jr	z, PmemOutLGridCheck_JumpTable_Skip2
	cp	hl, 1:i3
	jr	z, PmemOutLGridCheck_JumpTable_Skip
	cp	hl, 0:i3
	jrl	nz, PmemOutGrid_ReturnZero
	ld	xiy, NakaData_PartFlags
	lda	xix, (xsp+60)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+60)
	lda	xbc, (0x024772:24)
	ld	(xwa), xbc
	ld	xbc, 79
	ld	(xwa+6), xbc
	jrl	PmemOutLGridCheck_JumpTable_Join2
PmemOutLGridCheck_JumpTable_Skip:
	ld	xiy, NakaData_PartFlags
	lda	xix, (xsp+60)
	ldw	bc, 11
	ldirw
	lda	xde, (0xfd2c:16)
	sub	xde, 63904
	ld	xwa, 0:i3
	ld	a, (0x024772:24)
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda	xwa, (0x1ed400:24)
	add	xwa, xbc
	ld	xbc, xwa
	add	xbc, xde
	lda	xwa, (xsp+60)
	ld	(xwa), xbc
	ld	xbc, 255
	ld	(xwa+6), xbc
	ld	xbc, (xwa)
	ld	c, (xbc)
	set	1, c
	ld	b, 0:opc
	extz	xbc
	ld	(xwa+14), xbc
	jrl	PmemOutLGridCheck_JumpTable_Join
PmemOutLGridCheck_JumpTable_Skip2:
	ld	xiy, NakaData_PartFlags
	lda	xix, (xsp+60)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+60)
	lda	xbc, (0x024774:24)
	ld	(xwa), xbc
	ld	xbc, 2:i3
	ld	(xwa+6), xbc
	jrl	PmemOutLGridCheck_JumpTable_Join2
PmemOutLGridCheck_Evt1C00018:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	lda	xwa, (xsp+36)
	ld	xbc, xhl
	srl	xbc, 16
	ld	qbc, 0
	ld	(xwa), bc
	ld	(xwa+2), hl
	cpw	(xwa), 1
	jrl	nz, PmemOutGrid_ReturnZero
	cp	hl, 3:i3
	jrl	z, PmemOutLGridCheck_JumpTable_Skip4
	cp	hl, 1:i3
	jr	z, PmemOutLGridCheck_JumpTable_Skip3
	cp	hl, 0:i3
	jrl	nz, PmemOutGrid_ReturnZero
	ld	xiy, NakaData_PartFlags
	lda	xix, (xsp+60)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+60)
	lda	xbc, (0x024772:24)
	ld	(xwa), xbc
	ld	xbc, 79
	ld	(xwa+6), xbc
	ld	xbc, 0xffffffff
	ld	(xwa+14), xbc
	jr	PmemOutLGridCheck_JumpTable_Join2
PmemOutLGridCheck_JumpTable_Skip3:
	ld	xiy, NakaData_PartFlags
	lda	xix, (xsp+60)
	ldw	bc, 11
	ldirw
	lda	xde, (0xfd2c:16)
	sub	xde, 63904
	ld	xwa, 0:i3
	ld	a, (0x024772:24)
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda	xwa, (0x1ed400:24)
	add	xwa, xbc
	ld	xbc, xwa
	add	xbc, xde
	lda	xwa, (xsp+60)
	ld	(xwa), xbc
	ld	xbc, 255
	ld	(xwa+6), xbc
	ld	xbc, (xwa)
	ld	c, (xbc)
	res	1, c
	ld	b, 0:opc
	extz	xbc
	ld	(xwa+14), xbc
PmemOutLGridCheck_JumpTable_Join:
	call	MainRamPut
	jrl	PmemOutGrid_ReturnZero
PmemOutLGridCheck_JumpTable_Skip4:
	ld	xiy, NakaData_PartFlags
	lda	xix, (xsp+60)
	ldw	bc, 11
	ldirw
	lda	xwa, (xsp+60)
	lda	xbc, (0x024774:24)
	ld	(xwa), xbc
	ld	xbc, 2:i3
	ld	(xwa+6), xbc
	ld	xbc, 0xffffffff
	ld	(xwa+14), xbc
PmemOutLGridCheck_JumpTable_Join2:
	call	MainRamAdd
	jrl	PmemOutGrid_ReturnZero
PmemOutLGridCheck_Evt1C0001D:
	ld	(xsp+4), xhl
	ldw	(xbc), 1
	lda	xwa, (xsp+44)
	ld	(xsp+12), xwa
	ld	xwa, (xsp+28)
	ld	xhl, (xsp+12)
	ld	(xwa), xhl
	lda	xbc, (0x024772:24)
	ld	(xsp+16), xiy
	ld	xde, (xsp+4)
	lda	xwa, (xde+14)
	ld	(xsp+28), xwa
	cp	xbc, (xde)
	jrl	nz, PmemOutLGridCheck_JumpTable_Skip8
	ld	xwa, (xsp+16)
	ldw	(xwa), 0
	ld	xwa, (xsp+28)
	ld	xde, (xwa)
	ld	xwa, xde
	ld	xbc, xwa
	sra	xbc, 15
	sra	xbc, 16
	and	xbc, 7
	add	xbc, xwa
	and	xbc, 0xfffffff8
	sub	xwa, xbc
	inc	1, xwa
	pushw	wa
	ld	xbc, xde
	sra	xbc, 15
	sra	xbc, 16
	and	xbc, 7
	add	xbc, xde
	sra	xbc, 3
	inc	1, xbc
	pushw	bc
	pushw	PmemOutLGridCheck_LocalInit_Strings@hi16
	pushw	PmemOutLGridCheck_LocalInit_Strings@lo16
	push	xhl
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+36)
	ld	xbc, EVT_GRID_DRAW
	call	SendEvent
	lda	xde, (0xfd2c:16)
	sub	xde, 63904
	ld	xwa, 0:i3
	ld	a, (0x024772:24)
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda	xwa, (0x1ed400:24)
	add	xwa, xbc
	add	xwa, xde
	bit	1, (xwa)
	jr	z, PmemOutLGridCheck_JumpTable_Skip5
	ld	xwa, PmemOutLGrid_Str_ON
	jr	PmemOutLGridCheck_JumpTable_Join3
PmemOutLGridCheck_JumpTable_Skip5:
	ld	xwa, PmemOutLGrid_Str_OFF
PmemOutLGridCheck_JumpTable_Join3:
	push	xwa
	lda	xwa, (xsp+48)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ldw	(xsp+38), 1
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+36)
	ld	xbc, EVT_GRID_DRAW
	call	SendEvent
	ldw	(xsp+38), 0
	lda	xwa, (0xf9c4:16)
	sub	xwa, 63904
	ld	(xsp+32), xwa
	ld	xwa, 0:i3
	ld	a, (0x024774:24)
	ld	xbc, 26
	call	InitializeKubo_Helper
	ld	xwa, 0:i3
	ld	a, (0x024772:24)
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda	xwa, (0x1ed400:24)
	add	xwa, xbc
	add	xwa, xhl
	add	xwa, (xsp+32)
	bit	7, (xwa)
	jr	z, PmemOutLGridCheck_JumpTable_Skip6
	pushw	PmemOutLGridCheck_LocalInit_Strings_Tail@hi16
	pushw	PmemOutLGridCheck_LocalInit_Strings_Tail@lo16
	lda	xwa, (xsp+48)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	PmemOutLGridCheck_JumpTable_Join4
PmemOutLGridCheck_JumpTable_Skip6:
	ld	a, (xwa)
	extz	wa
	pushw	wa
	pushw	PmemOutLGridCheck_Evt1C0001D_Str_Fmt3d@hi16
	pushw	PmemOutLGridCheck_Evt1C0001D_Str_Fmt3d@lo16
	lda	xwa, (xsp+50)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
PmemOutLGridCheck_JumpTable_Join4:
	lda	xde, (xsp+36)
	ld	xwa, 0x5b0009
	ld	xbc, EVT_GRID_DRAW
	call	SendEvent
	ldw	(xsp+38), 1
	lda	xwa, (0xf9c5:16)
	sub	xwa, 63904
	ld	(xsp+32), xwa
	ld	xwa, 0:i3
	ld	a, (0x024774:24)
	ld	xbc, 26
	call	InitializeKubo_Helper
	ld	xwa, 0:i3
	ld	a, (0x024772:24)
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda	xwa, (0x1ed400:24)
	add	xwa, xbc
	add	xwa, xhl
	add	xwa, (xsp+32)
	ld	a, (xwa)
	extz	wa
	pushw	wa
	pushw	PmemOutLGridCheck_Evt1C0001D_Str_Fmt3d_2@hi16
	pushw	PmemOutLGridCheck_Evt1C0001D_Str_Fmt3d_2@lo16
	lda	xwa, (xsp+50)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	lda	xde, (xsp+36)
	ld	xwa, 0x5b0009
	ld	xbc, EVT_GRID_DRAW
	call	SendEvent
	ldw	(xsp+38), 2
	lda	xwa, (0xf9c7:16)
	sub	xwa, 63904
	ld	(xsp+32), xwa
	ld	xwa, 0:i3
	ld	a, (0x024774:24)
	ld	xbc, 26
	call	InitializeKubo_Helper
	ld	xwa, 0:i3
	ld	a, (0x024772:24)
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda	xwa, (0x1ed400:24)
	add	xwa, xbc
	add	xwa, xhl
	add	xwa, (xsp+32)
	bit	7, (xwa)
	jr	z, PmemOutLGridCheck_JumpTable_Skip7
	pushw	PmemOutLGridCheck_Evt1C0001D_Str_OFF@hi16
	pushw	PmemOutLGridCheck_Evt1C0001D_Str_OFF@lo16
	lda	xwa, (xsp+48)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	PmemOutLGridCheck_JumpTable_Join5
PmemOutLGridCheck_JumpTable_Skip7:
	ld	a, (xwa)
	extz	wa
	pushw	wa
	pushw	PmemOutLGridCheck_Evt1C0001D_Str_Fmt3d_3@hi16
	pushw	PmemOutLGridCheck_Evt1C0001D_Str_Fmt3d_3@lo16
	lda	xwa, (xsp+50)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
PmemOutLGridCheck_JumpTable_Join5:
	lda	xde, (xsp+36)
	ld	xwa, 0x5b0009
	ld	xbc, EVT_GRID_DRAW
	jrl	PmemOutL_GridCheck_Return
PmemOutLGridCheck_JumpTable_Skip8:
	ld	xwa, (xsp+20)
	ld	(xsp+20), xwa
	ld	xwa, 0:i3
	ld	a, (0x024772:24)
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	ld	xwa, (xsp+24)
	add	xwa, xbc
	ld	(xsp+24), xwa
	ld	xbc, xwa
	add	xbc, (xsp+32)
	ld	xwa, (xsp+4)
	cp	(xwa), xbc
	jr	nz, PmemOutLGridCheck_JumpTable_Skip10
	ld	xwa, (xsp+16)
	ldw	(xwa), 1
	ld	xwa, (xsp+28)
	ld	xwa, (xwa)
	bit	1, wa
	jr	z, PmemOutLGridCheck_JumpTable_Skip9
	ld	xwa, NakaInst_ON_E80168
	jr	PmemOutLGridCheck_JumpTable_Join6
PmemOutLGridCheck_JumpTable_Skip9:
	ld	xwa, 0xe8016e
PmemOutLGridCheck_JumpTable_Join6:
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+36)
	ld	xbc, EVT_GRID_DRAW
	jrl	PmemOutL_GridCheck_Return
PmemOutLGridCheck_JumpTable_Skip10:
	lda	xbc, (0x024774:24)
	ld	xwa, (xsp+4)
	cp	xbc, (xwa)
	jrl	nz, PmemOutLGridCheck_JumpTable_Skip13
	ld	xwa, (xsp+16)
	ldw	(xwa), 3
	ld	xwa, (xsp+28)
	ld	xwa, (xwa)
	sll	xwa, 2
	ld	xbc, (xsp+8)
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+36)
	ld	xbc, EVT_GRID_DRAW
	call	SendEvent
	ldw	(xsp+38), 0
	lda	xwa, (0xf9c4:16)
	sub	xwa, 63904
	ld	(xsp+32), xwa
	ld	xwa, 0:i3
	ld	a, (0x024774:24)
	ld	xbc, 26
	call	InitializeKubo_Helper
	ld	xwa, 0:i3
	ld	a, (0x024772:24)
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda	xwa, (0x1ed400:24)
	add	xwa, xbc
	add	xwa, xhl
	add	xwa, (xsp+32)
	lda	xbc, (xsp+44)
	bit	7, (xwa)
	jr	z, PmemOutLGridCheck_JumpTable_Skip11
	pushw	PmemOutLGridCheck_Evt1C0001D_Str_OFF_2@hi16
	pushw	PmemOutLGridCheck_Evt1C0001D_Str_OFF_2@lo16
	push	xbc
	call	Free_Compare2
	inc	8, xsp
	jr	PmemOutLGridCheck_JumpTable_Join7
PmemOutLGridCheck_JumpTable_Skip11:
	ld	a, (xwa)
	extz	wa
	pushw	wa
	pushw	PmemOutLGridCheck_Evt1C0001D_Str_Fmt3d_4@hi16
	pushw	PmemOutLGridCheck_Evt1C0001D_Str_Fmt3d_4@lo16
	push	xbc
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
PmemOutLGridCheck_JumpTable_Join7:
	lda	xde, (xsp+36)
	ld	xwa, 0x5b0009
	ld	xbc, EVT_GRID_DRAW
	call	SendEvent
	ldw	(xsp+38), 1
	lda	xwa, (0xf9c5:16)
	sub	xwa, 63904
	ld	(xsp+32), xwa
	ld	xwa, 0:i3
	ld	a, (0x024774:24)
	ld	xbc, 26
	call	InitializeKubo_Helper
	ld	xwa, 0:i3
	ld	a, (0x024772:24)
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda	xwa, (0x1ed400:24)
	add	xwa, xbc
	add	xwa, xhl
	add	xwa, (xsp+32)
	ld	a, (xwa)
	extz	wa
	pushw	wa
	pushw	PmemOutLGridCheck_Evt1C0001D_Str_Fmt3d_5@hi16
	pushw	PmemOutLGridCheck_Evt1C0001D_Str_Fmt3d_5@lo16
	lda	xwa, (xsp+50)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	lda	xde, (xsp+36)
	ld	xwa, 0x5b0009
	ld	xbc, EVT_GRID_DRAW
	call	SendEvent
	ldw	(xsp+38), 2
	lda	xwa, (0xf9c7:16)
	sub	xwa, 63904
	ld	(xsp+32), xwa
	ld	xwa, 0:i3
	ld	a, (0x024774:24)
	ld	xbc, 26
	call	InitializeKubo_Helper
	ld	xwa, 0:i3
	ld	a, (0x024772:24)
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda	xwa, (0x1ed400:24)
	add	xwa, xbc
	add	xwa, xhl
	add	xwa, (xsp+32)
	bit	7, (xwa)
	jr	z, PmemOutLGridCheck_JumpTable_Skip12
	pushw	PmemOutLGridCheck_Evt1C0001D_Str_OFF_3@hi16
	pushw	PmemOutLGridCheck_Evt1C0001D_Str_OFF_3@lo16
	lda	xwa, (xsp+48)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	PmemOutLGridCheck_JumpTable_Join8
PmemOutLGridCheck_JumpTable_Skip12:
	ld	a, (xwa)
	extz	wa
	pushw	wa
	pushw	PmemOutLGridCheck_Evt1C0001D_Str_Fmt3d_6@hi16
	pushw	PmemOutLGridCheck_Evt1C0001D_Str_Fmt3d_6@lo16
	lda	xwa, (xsp+50)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
PmemOutLGridCheck_JumpTable_Join8:
	lda	xde, (xsp+36)
	ld	xwa, 0x5b0009
	ld	xbc, EVT_GRID_DRAW
	jrl	PmemOutL_GridCheck_Return
PmemOutLGridCheck_JumpTable_Skip13:
	lda	xwa, (0xf9b6:16)
	ld	(xsp+32), xwa
	lda	xwa, (xwa+14)
	sub	xwa, (xsp+20)
	ld	(xsp+8), xwa
	ld	xwa, 0:i3
	ld	a, (0x024774:24)
	ld	xbc, 26
	call	InitializeKubo_Helper
	ld	xbc, (xsp+24)
	add	xbc, xhl
	ld	xde, xbc
	add	xde, (xsp+8)
	ld	xwa, (xsp+4)
	cp	(xwa), xde
	jr	nz, PmemOutLGridCheck_JumpTable_Skip15
	ld	xwa, (xsp+16)
	ldw	(xwa), 0
	ld	xwa, (xsp+28)
	ld	xwa, (xwa)
	bit	7, wa
	jr	z, PmemOutLGridCheck_JumpTable_Skip14
	pushw	PmemOutLGridCheck_Evt1C0001D_Str_OFF_4@hi16
	pushw	PmemOutLGridCheck_Evt1C0001D_Str_OFF_4@lo16
	ld	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	PmemOutLGridCheck_JumpTable_Join9
PmemOutLGridCheck_JumpTable_Skip14:
	push	xwa
	pushw	PmemOutLGridCheck_Evt1C0001D_Str_Fmt3d_7@hi16
	pushw	PmemOutLGridCheck_Evt1C0001D_Str_Fmt3d_7@lo16
	ld	xwa, (xsp+20)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+12)
PmemOutLGridCheck_JumpTable_Join9:
	lda	xde, (xsp+36)
	ld	xwa, 0x5b0009
	ld	xbc, EVT_GRID_DRAW
	jrl	PmemOutL_GridCheck_Return
PmemOutLGridCheck_JumpTable_Skip15:
	ld	xwa, (xsp+32)
	lda	xwa, (xwa+15)
	sub	xwa, (xsp+20)
	ld	xde, xbc
	add	xde, xwa
	ld	xwa, (xsp+4)
	cp	(xwa), xde
	jr	nz, PmemOutLGridCheck_JumpTable_Skip16
	ld	xwa, (xsp+16)
	ldw	(xwa), 1
	ld	xwa, (xsp+28)
	ld	xwa, (xwa)
	push	xwa
	pushw	PmemOutLGridCheck_Evt1C0001D_Str_Fmt3d_8@hi16
	pushw	PmemOutLGridCheck_Evt1C0001D_Str_Fmt3d_8@lo16
	ld	xwa, (xsp+20)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+12)
	lda	xde, (xsp+36)
	ld	xwa, 0x5b0009
	ld	xbc, EVT_GRID_DRAW
	jrl	PmemOutL_GridCheck_Return
PmemOutLGridCheck_JumpTable_Skip16:
	ld	xwa, (xsp+32)
	lda	xwa, (xwa+17)
	sub	xwa, (xsp+20)
	add	xbc, xwa
	ld	xwa, (xsp+4)
	cp	(xwa), xbc
	jrl	nz, PmemOutGrid_ReturnZero
	ld	xwa, (xsp+16)
	ldw	(xwa), 2
	ld	xwa, (xsp+28)
	ld	xwa, (xwa)
	bit	7, wa
	jr	z, PmemOutLGridCheck_JumpTable_Skip17
	pushw	PmemOutLGridCheck_Evt1C0001D_Str_OFF_5@hi16
	pushw	PmemOutLGridCheck_Evt1C0001D_Str_OFF_5@lo16
	ld	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	PmemOutLGridCheck_JumpTable_Join10
PmemOutLGridCheck_JumpTable_Skip17:
	push	xwa
	pushw	PmemOutLGridCheck_Evt1C0001D_Str_Fmt3d_9@hi16
	pushw	PmemOutLGridCheck_Evt1C0001D_Str_Fmt3d_9@lo16
	ld	xwa, (xsp+20)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+12)
PmemOutLGridCheck_JumpTable_Join10:
	lda	xde, (xsp+36)
	ld	xwa, 0x5b0009
	ld	xbc, EVT_GRID_DRAW
	jrl	PmemOutL_GridCheck_Return
PmemOutL_GridCheck:
	ld XWA,XHL
	srl XWA, 16
	ld QWA,0
	ld (XBC),WA
	ld XIX,XIY
	ld (XIY),HL
	lda xwa, (xsp + 0x2c)
	ld (XSP+0x14),XWA
	ld XWA,(XSP+0x1c)
	ld XDE,(XSP+0x14)
	ld (XWA),XDE
	cpw (XBC), 0x0001
	jrl nz, PmemOutGrid_ReturnZero
	ld WA,(XIX)
	cp wa, 3:i3
	jrl z, PmemOutL_ColumnParamDisplay
	cp wa, 1:i3
	jr z, PmemOutL_BitCheckDisplay
	cp wa, 0:i3
	jrl nz, PmemOutGrid_ReturnZero
	ld c, (0x024772:24)
	ld A,C
	and A,0x07
	inc 1,A
	extz WA
	pushw wa
	srl C, 0x03
	inc 1,C
	extz BC
	pushw bc
	pushw PmemOutL_GridCheck_Str_Fmt2d_Fmtd@hi16
	pushw PmemOutL_GridCheck_Str_Fmt2d_Fmtd@lo16
	push XDE
	call Scoop_EventLoop_12Entry_Helper
	lda xsp, (xsp + 0x0c)
	call GetFocusObject
	ld XWA,XHL
	lda xde, (xsp + 0x24)
	ld XBC,EVT_GRID_DRAW
	jr t, PmemOutL_GridCheck_Return
PmemOutL_BitCheckDisplay:
	ld xwa, 0:i3
	ld a, (0x024772:24)
	ld xbc, xwa
	sll xbc, 4
	sub xbc, xwa
	sll xbc, 6
	ld xwa, (xsp + 24)
	add xwa, xbc
	add xwa, (xsp + 32)
	bit	1, (xwa)
	jr z, PmemOutL_LoadOffStr
	ld xwa, PmemOutL_BitCheckDisplay_Str
	jr PmemOutL_StrCopyAndDispatch

PmemOutL_LoadOffStr:
	ld xwa, PmemOutL_LoadOffStr_Str

PmemOutL_StrCopyAndDispatch:
	push	xwa
	ld	xwa, (xsp+24)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+36)
	ld	xbc, EVT_GRID_DRAW
	jr	PmemOutL_GridCheck_Return
PmemOutL_ColumnParamDisplay:
	ld c, (0x024774:24)

	extz bc

	sla bc, 2

	ld xwa, (xsp + 8)

	ld	xwa, (xwa+bc)

	push xwa

	ld xwa, (xsp + 24)

	push xwa

	call	Free_Compare2

	inc 8, xsp

	call	GetFocusObject

	ld xwa, xhl

	lda xde, (xsp + 36)

	ld xbc, EVT_GRID_DRAW



; PmemOutLGridCheck return

PmemOutL_GridCheck_Return:
	call SendEvent

PmemOutGrid_ReturnZero:
	ld xhl, 0:i3
	pop xiz
	lda xsp, (xsp + 78)
	ret

PmemOutRGridCheck:
	lda xsp, (xsp - 74)
	push xiz
	ld xiz, xde
	ld xde, xbc
	ld xiy, PmemOutRGridCheck_LocalInit
	lda xix, (xsp + 40)
	ldw bc, 0x8
	ldirw
	ld xiy, ComSetGridCheck_LocalInit
	lda xix, (xsp + 32)
	ld bc, 4:i3
	ldirw
	ld xhl, xde
	lda xbc, (xsp + 32)
	lda xwa, (0xf9b6:16)
	ld (xsp + 20), xwa
	lda xwa, (0x1ed400:24)
	ld (xsp + 16), xwa
	ld xwa, (xsp + 20)
	lda xwa, (xwa + 14)
	ld (xsp + 28), xwa
	lda xiy, (xbc + 2)
	lda xwa, (xbc + 4)
	ld (xsp + 24), xwa
	cp xde, EVT_REQUEST_GRID_DRAW
	jrl z, CtlMsgGrid_EventHandler
	sub xhl, EVT_INDEXSW_UP
	cp xhl, 0x0
	jrl lt, TtMdCtlMsg_ReturnZero2
	cp xhl, 0x6
	jrl gt, TtMdCtlMsg_ReturnZero2
	add xhl, xhl
	add xhl, PmemOutRGridCheck_CaseTable
	ld hl, (xhl)
	lda xix, (TtMdCtlMsg_EventDispatch:24)
; Computed jump: target = TtMdCtlMsg_EventDispatch + PmemOutRGridCheck_CaseTable[i], PmemOutRGridCheck_CaseTable = 16-bit offsets (7 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1c00017:
;   0x1c00017 -> TtMdCtlMsg_EventDispatch
;   0x1c00018 -> PmemOutRGridCheck_Evt1C00018
;   0x1c00019 -> TtMdCtlMsg_EventDispatch
;   0x1c0001a -> PmemOutRGridCheck_Evt1C00018
;   0x1c0001b -> TtMdCtlMsg_ReturnZero2
;   0x1c0001c -> TtMdCtlMsg_ReturnZero2
;   0x1c0001d -> PmemOutRGridCheck_Evt1C0001D
	jp	t, (xix+hl)
TtMdCtlMsg_EventDispatch:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	ld	xiz, xhl
	lda	xwa, (xsp+32)
	ld	xbc, xiz
	srl	xbc, 16
	ld	qbc, 0
	ld	(xwa), bc
	ld	bc, iz
	ld	(xwa+2), bc
	cpw	(xwa), 1
	jrl	nz, TtMdCtlMsg_ReturnZero2
	cp	bc, 2:i3
	jrl	z, PmemOutLGridCheck_JumpTable_Code_Skip3
	cp	bc, 1:i3
	jr	z, PmemOutLGridCheck_JumpTable_Code_Skip2
	cp	bc, 0:i3
	jrl	nz, TtMdCtlMsg_ReturnZero2
	ld	xiy, PmemOutLGridCheck_CaseTable_Tail
	lda	xix, (xsp+56)
	ldw	bc, 11
	ldirw
	lda	xwa, (63940:16)
	sub	xwa, 63904
	ld	(xsp+28), xwa
	ld	xwa, 0:i3
	ld	a, (149364:24)
	ld	xbc, 26
	call	InitializeKubo_Helper
	ld	xwa, 0:i3
	ld	a, (149362:24)
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda	xwa, (2020352:24)
	add	xwa, xbc
	add	xwa, xhl
	ld	xbc, xwa
	add	xbc, (xsp+28)
	lda	xwa, (xsp+56)
	ld	(xwa), xbc
	ld	xbc, 127
	ld	(xwa+6), xbc
	ld	xbc, (xwa)
	bit	7, (xbc)
	jr	z, PmemOutLGridCheck_JumpTable_Code_Skip
	ld	xbc, 0:i3
	ld	(xwa+14), xbc
	call	MainRamPut
	jrl	TtMdCtlMsg_ReturnZero2
PmemOutLGridCheck_JumpTable_Code_Skip:
	jrl	PmemOutLGridCheck_JumpTable_Code_Join2
PmemOutLGridCheck_JumpTable_Code_Skip2:
	ld	xiy, PmemOutLGridCheck_CaseTable_Tail
	lda	xix, (xsp+56)
	ldw	bc, 11
	ldirw
	lda	xwa, (63941:16)
	sub	xwa, 63904
	ld	(xsp+28), xwa
	ld	xwa, 0:i3
	ld	a, (149364:24)
	ld	xbc, 26
	call	InitializeKubo_Helper
	ld	xwa, 0:i3
	ld	a, (149362:24)
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda	xwa, (2020352:24)
	add	xwa, xbc
	add	xwa, xhl
	ld	xbc, xwa
	add	xbc, (xsp+28)
	lda	xwa, (xsp+56)
	ld	(xwa), xbc
	ld	xbc, 255
	ld	(xwa+6), xbc
	jrl	PmemOutLGridCheck_JumpTable_Code_Join2
PmemOutLGridCheck_JumpTable_Code_Skip3:
	ld	xiy, PmemOutLGridCheck_CaseTable_Tail
	lda	xix, (xsp+56)
	ldw	bc, 11
	ldirw
	lda	xwa, (63943:16)
	sub	xwa, 63904
	ld	(xsp+28), xwa
	ld	xwa, 0:i3
	ld	a, (149364:24)
	ld	xbc, 26
	call	InitializeKubo_Helper
	ld	xwa, 0:i3
	ld	a, (149362:24)
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda	xwa, (2020352:24)
	add	xwa, xbc
	add	xwa, xhl
	ld	xbc, xwa
	add	xbc, (xsp+28)
	lda	xwa, (xsp+56)
	ld	(xwa), xbc
	ld	xbc, 127
	ld	(xwa+6), xbc
	ld	xbc, (xwa)
	bit	7, (xbc)
	jr	z, PmemOutLGridCheck_JumpTable_Code_Skip4
	ld	xbc, 0:i3
	ld	(xwa+14), xbc
	call	MainRamPut
	jrl	TtMdCtlMsg_ReturnZero2
PmemOutLGridCheck_JumpTable_Code_Skip4:
	jrl	PmemOutLGridCheck_JumpTable_Code_Join2
PmemOutRGridCheck_Evt1C00018:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	ld	xiz, xhl
	lda	xwa, (xsp+32)
	ld	xbc, xiz
	srl	xbc, 16
	ld	qbc, 0
	ld	(xwa), bc
	ld	bc, iz
	ld	(xwa+2), bc
	cpw	(xwa), 1
	jrl	nz, TtMdCtlMsg_ReturnZero2
	cp	bc, 2:i3
	jrl	z, PmemOutLGridCheck_JumpTable_Code_Skip7
	cp	bc, 1:i3
	jrl	z, PmemOutLGridCheck_JumpTable_Code_Skip6
	cp	bc, 0:i3
	jrl	nz, TtMdCtlMsg_ReturnZero2
	ld	xiy, PmemOutLGridCheck_CaseTable_Tail
	lda	xix, (xsp+56)
	ldw	bc, 11
	ldirw
	lda	xwa, (63940:16)
	sub	xwa, 63904
	ld	(xsp+28), xwa
	ld	xwa, 0:i3
	ld	a, (149364:24)
	ld	xbc, 26
	call	InitializeKubo_Helper
	ld	xwa, 0:i3
	ld	a, (149362:24)
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda	xwa, (2020352:24)
	add	xwa, xbc
	add	xwa, xhl
	ld	xbc, xwa
	add	xbc, (xsp+28)
	lda	xwa, (xsp+56)
	ld	(xwa), xbc
	ld	xbc, 127
	ld	(xwa+6), xbc
	ld	xbc, (xwa)
	bit	7, (xbc)
	jrl	nz, TtMdCtlMsg_ReturnZero2
	ld	xbc, (xwa)
	lda	xde, (xwa+14)
	cp	(xbc), 0
	jr	nz, PmemOutLGridCheck_JumpTable_Code_Skip5
	ld	xbc, 128
	ld	(xde), xbc
	jrl	PmemOutLGridCheck_JumpTable_Code_Join
PmemOutLGridCheck_JumpTable_Code_Skip5:
	ld	xbc, 4294967295
	ld	(xde), xbc
	jrl	PmemOutLGridCheck_JumpTable_Code_Join2
PmemOutLGridCheck_JumpTable_Code_Skip6:
	ld	xiy, PmemOutLGridCheck_CaseTable_Tail
	lda	xix, (xsp+56)
	ldw	bc, 11
	ldirw
	lda	xwa, (63941:16)
	sub	xwa, 63904
	ld	(xsp+28), xwa
	ld	xwa, 0:i3
	ld	a, (149364:24)
	ld	xbc, 26
	call	InitializeKubo_Helper
	ld	xwa, 0:i3
	ld	a, (149362:24)
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda	xwa, (2020352:24)
	add	xwa, xbc
	add	xwa, xhl
	ld	xbc, xwa
	add	xbc, (xsp+28)
	lda	xwa, (xsp+56)
	ld	(xwa), xbc
	ld	xbc, 255
	ld	(xwa+6), xbc
	ld	xbc, 4294967295
	ld	(xwa+14), xbc
	jr	PmemOutLGridCheck_JumpTable_Code_Join2
PmemOutLGridCheck_JumpTable_Code_Skip7:
	ld	xiy, PmemOutLGridCheck_CaseTable_Tail
	lda	xix, (xsp+56)
	ldw	bc, 11
	ldirw
	lda	xwa, (63943:16)
	sub	xwa, 63904
	ld	(xsp+28), xwa
	ld	xwa, 0:i3
	ld	a, (149364:24)
	ld	xbc, 26
	call	InitializeKubo_Helper
	ld	xwa, 0:i3
	ld	a, (149362:24)
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda	xwa, (2020352:24)
	add	xwa, xbc
	add	xwa, xhl
	ld	xbc, xwa
	add	xbc, (xsp+28)
	lda	xwa, (xsp+56)
	ld	(xwa), xbc
	ld	xbc, 127
	ld	(xwa+6), xbc
	ld	xbc, (xwa)
	bit	7, (xbc)
	jrl	nz, TtMdCtlMsg_ReturnZero2
	ld	xbc, (xwa)
	lda	xde, (xwa+14)
	cp	(xbc), 0
	jr	nz, PmemOutLGridCheck_JumpTable_Code_Skip8
	ld	xbc, 128
	ld	(xde), xbc
PmemOutLGridCheck_JumpTable_Code_Join:
	call	MainRamPut
	jrl	TtMdCtlMsg_ReturnZero2
PmemOutLGridCheck_JumpTable_Code_Skip8:
	ld	xbc, 4294967295
	ld	(xde), xbc
PmemOutLGridCheck_JumpTable_Code_Join2:
	call	MainRamAdd
	jrl	TtMdCtlMsg_ReturnZero2
PmemOutRGridCheck_Evt1C0001D:
	ld	(xsp+4), xiz
	ldw	(xbc), 1
	lda	xbc, (xsp+40)
	ld	(xsp+12), xbc
	ld	xwa, (xsp+24)
	ld	(xwa), xbc
	lda	xwa, (149362:24)
	ld	(xsp+24), xiy
	lda	xbc, (63904:16)
	cp	xwa, (xiz)
	jrl	nz, PmemOutLGridCheck_JumpTable_Code_Skip11
	ld	xwa, (xsp+24)
	ldw	(xwa), 0
	ld	xwa, (xsp+28)
	sub	xwa, xbc
	ld	xiz, xwa
	ld	xwa, 0:i3
	ld	a, (149364:24)
	ld	xbc, 26
	call	InitializeKubo_Helper
	ld	xwa, 0:i3
	ld	a, (149362:24)
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	ld	xwa, (xsp+16)
	add	xwa, xbc
	add	xwa, xhl
	add	xwa, xiz
	bit	7, (xwa)
	jr	z, PmemOutLGridCheck_JumpTable_Code_Skip9
	pushw	PmemOutRGridCheck_LocalInit_Strings@hi16
	pushw	PmemOutRGridCheck_LocalInit_Strings@lo16
	ld	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	PmemOutLGridCheck_JumpTable_Code_Join3
PmemOutLGridCheck_JumpTable_Code_Skip9:
	ld	a, (xwa)
	extz	wa
	pushw	wa
	pushw PmemOutRGridCheck_Evt1C0001D_Str_Fmt3d@hi16
	pushw PmemOutRGridCheck_Evt1C0001D_Str_Fmt3d@lo16
	ld	xwa, (xsp+18)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
PmemOutLGridCheck_JumpTable_Code_Join3:
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+32)
	ld	xbc, EVT_GRID_DRAW
	call	SendEvent
	ldw	(xsp+34), 1
	lda	xwa, (63941:16)
	sub	xwa, 63904
	ld	(xsp+28), xwa
	ld	xwa, 0:i3
	ld	a, (149364:24)
	ld	xbc, 26
	call	InitializeKubo_Helper
	ld	xwa, 0:i3
	ld	a, (149362:24)
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda	xwa, (2020352:24)
	add	xwa, xbc
	add	xwa, xhl
	add	xwa, (xsp+28)
	ld	a, (xwa)
	extz	wa
	pushw	wa
	pushw PmemOutRGridCheck_Evt1C0001D_Str_Fmt3d_2@hi16
	pushw PmemOutRGridCheck_Evt1C0001D_Str_Fmt3d_2@lo16
	lda	xwa, (xsp+46)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+32)
	ld	xbc, EVT_GRID_DRAW
	call	SendEvent
	ldw	(xsp+34), 2
	lda	xwa, (63943:16)
	sub	xwa, 63904
	ld	(xsp+28), xwa
	ld	xwa, 0:i3
	ld	a, (149364:24)
	ld	xbc, 26
	call	InitializeKubo_Helper
	ld	xwa, 0:i3
	ld	a, (149362:24)
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda	xwa, (2020352:24)
	add	xwa, xbc
	add	xwa, xhl
	add	xwa, (xsp+28)
	bit	7, (xwa)
	jr	z, PmemOutLGridCheck_JumpTable_Code_Skip10
	pushw PmemOutRGridCheck_Evt1C0001D_Str_OFF@hi16
	pushw PmemOutRGridCheck_Evt1C0001D_Str_OFF@lo16
	lda	xwa, (xsp+44)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	PmemOutLGridCheck_JumpTable_Code_Join4
PmemOutLGridCheck_JumpTable_Code_Skip10:
	ld	a, (xwa)
	extz	wa
	pushw	wa
	pushw PmemOutRGridCheck_Evt1C0001D_Str_Fmt3d_3@hi16
	pushw PmemOutRGridCheck_Evt1C0001D_Str_Fmt3d_3@lo16
	lda	xwa, (xsp+46)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
PmemOutLGridCheck_JumpTable_Code_Join4:
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+32)
	ld	xbc, EVT_GRID_DRAW
	jrl	CtlMsg_SendEventReturn
PmemOutLGridCheck_JumpTable_Code_Skip11:
	lda	xde, (149364:24)
	ld	xwa, (xsp+28)
	sub	xwa, xbc
	ld	(xsp+28), xwa
	cp	xde, (xiz)
	jrl	nz, PmemOutLGridCheck_JumpTable_Code_Skip14
	ld	xwa, (xsp+24)
	ldw	(xwa), 0
	ld	xwa, 0:i3
	ld	a, (149364:24)
	ld	xbc, 26
	call	InitializeKubo_Helper
	ld	xwa, 0:i3
	ld	a, (149362:24)
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	ld	xwa, (xsp+16)
	add	xwa, xbc
	add	xwa, xhl
	add	xwa, (xsp+28)
	bit	7, (xwa)
	jr	z, PmemOutLGridCheck_JumpTable_Code_Skip12
	pushw PmemOutRGridCheck_Evt1C0001D_Str_OFF_2@hi16
	pushw PmemOutRGridCheck_Evt1C0001D_Str_OFF_2@lo16
	ld	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	PmemOutLGridCheck_JumpTable_Code_Join5
PmemOutLGridCheck_JumpTable_Code_Skip12:
	ld	a, (xwa)
	extz	wa
	pushw	wa
	pushw PmemOutRGridCheck_Evt1C0001D_Str_Fmt3d_4@hi16
	pushw PmemOutRGridCheck_Evt1C0001D_Str_Fmt3d_4@lo16
	ld	xwa, (xsp+18)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
PmemOutLGridCheck_JumpTable_Code_Join5:
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+32)
	ld	xbc, EVT_GRID_DRAW
	call	SendEvent
	ldw	(xsp+34), 1
	lda	xwa, (63941:16)
	sub	xwa, 63904
	ld	(xsp+28), xwa
	ld	xwa, 0:i3
	ld	a, (149364:24)
	ld	xbc, 26
	call	InitializeKubo_Helper
	ld	xwa, 0:i3
	ld	a, (149362:24)
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda	xwa, (2020352:24)
	add	xwa, xbc
	add	xwa, xhl
	add	xwa, (xsp+28)
	ld	a, (xwa)
	extz	wa
	pushw	wa
	pushw PmemOutRGridCheck_Evt1C0001D_Str_Fmt3d_5@hi16
	pushw PmemOutRGridCheck_Evt1C0001D_Str_Fmt3d_5@lo16
	lda	xwa, (xsp+46)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+32)
	ld	xbc, EVT_GRID_DRAW
	call	SendEvent
	ldw	(xsp+34), 2
	lda	xwa, (63943:16)
	sub	xwa, 63904
	ld	(xsp+28), xwa
	ld	xwa, 0:i3
	ld	a, (149364:24)
	ld	xbc, 26
	call	InitializeKubo_Helper
	ld	xwa, 0:i3
	ld	a, (149362:24)
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda	xwa, (2020352:24)
	add	xwa, xbc
	add	xwa, xhl
	add	xwa, (xsp+28)
	lda	xbc, (xsp+40)
	bit	7, (xwa)
	jr	z, PmemOutLGridCheck_JumpTable_Code_Skip13
	pushw PmemOutRGridCheck_Evt1C0001D_Str_OFF_3@hi16
	pushw PmemOutRGridCheck_Evt1C0001D_Str_OFF_3@lo16
	push	xbc
	call	Free_Compare2
	inc	8, xsp
	jr	PmemOutLGridCheck_JumpTable_Code_Join6
PmemOutLGridCheck_JumpTable_Code_Skip13:
	ld	a, (xwa)
	extz	wa
	pushw	wa
	pushw PmemOutRGridCheck_Evt1C0001D_Str_Fmt3d_6@hi16
	pushw PmemOutRGridCheck_Evt1C0001D_Str_Fmt3d_6@lo16
	push	xbc
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
PmemOutLGridCheck_JumpTable_Code_Join6:
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+32)
	ld	xbc, EVT_GRID_DRAW
	jrl	CtlMsg_SendEventReturn
PmemOutLGridCheck_JumpTable_Code_Skip14:
	ld	(xsp+8), xbc
	ld	xwa, (xsp+20)
	ld	(xsp+20), xwa
	ld	xwa, 0:i3
	ld	a, (149364:24)
	ld	xbc, 26
	call	InitializeKubo_Helper
	ld	xbc, 0:i3
	ld	c, (149362:24)
	ld	xwa, xbc
	sll	xwa, 4
	sub	xwa, xbc
	sll	xwa, 6
	ld	xbc, (xsp+16)
	add	xbc, xwa
	add	xbc, xhl
	ld	xwa, xbc
	add	xwa, (xsp+28)
	cp	(xiz), xwa
	jr	nz, PmemOutLGridCheck_JumpTable_Code_Skip16
	ld	xwa, (xsp+24)
	ldw	(xwa), 0
	ld	xwa, (xiz+14)
	bit	7, wa
	jr	z, PmemOutLGridCheck_JumpTable_Code_Skip15
	pushw PmemOutRGridCheck_Evt1C0001D_Str_OFF_4@hi16
	pushw PmemOutRGridCheck_Evt1C0001D_Str_OFF_4@lo16
	ld	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	PmemOutLGridCheck_JumpTable_Code_Join7
PmemOutLGridCheck_JumpTable_Code_Skip15:
	push	xwa
	pushw PmemOutRGridCheck_Evt1C0001D_Str_Fmt3d_7@hi16
	pushw PmemOutRGridCheck_Evt1C0001D_Str_Fmt3d_7@lo16
	ld	xwa, (xsp+20)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+12)
PmemOutLGridCheck_JumpTable_Code_Join7:
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+32)
	ld	xbc, EVT_GRID_DRAW
	jrl	CtlMsg_SendEventReturn
PmemOutLGridCheck_JumpTable_Code_Skip16:
	ld	xwa, (xsp+20)
	lda	xwa, (xwa+15)
	sub	xwa, (xsp+8)
	ld	xhl, xbc
	add	xhl, xwa
	ld	xwa, (xsp+4)
	lda	xde, (xwa+14)
	cp	(xwa), xhl
	jr	nz, PmemOutLGridCheck_JumpTable_Code_Skip17
	ld	xwa, (xsp+24)
	ldw	(xwa), 1
	ld	xwa, (xde)
	push	xwa
	pushw PmemOutRGridCheck_Evt1C0001D_Str_Fmt3d_8@hi16
	pushw PmemOutRGridCheck_Evt1C0001D_Str_Fmt3d_8@lo16
	ld	xwa, (xsp+20)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+32)
	ld	xbc, EVT_GRID_DRAW
	jrl	CtlMsg_SendEventReturn
PmemOutLGridCheck_JumpTable_Code_Skip17:
	ld	xwa, (xsp+20)
	lda	xwa, (xwa+17)
	sub	xwa, (xsp+8)
	add	xbc, xwa
	ld	xwa, (xsp+4)
	cp	(xwa), xbc
	jrl	nz, TtMdCtlMsg_ReturnZero2
	ld	xwa, (xsp+24)
	ldw	(xwa), 2
	ld	xwa, (xde)
	bit	7, wa
	jr	z, PmemOutLGridCheck_JumpTable_Code_Skip18
	pushw PmemOutRGridCheck_Evt1C0001D_Str_OFF_5@hi16
	pushw PmemOutRGridCheck_Evt1C0001D_Str_OFF_5@lo16
	ld	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	PmemOutLGridCheck_JumpTable_Code_Join8
PmemOutLGridCheck_JumpTable_Code_Skip18:
	push	xwa
	pushw PmemOutRGridCheck_Evt1C0001D_Str_Fmt3d_9@hi16
	pushw PmemOutRGridCheck_Evt1C0001D_Str_Fmt3d_9@lo16
	ld	xwa, (xsp+20)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+12)
PmemOutLGridCheck_JumpTable_Code_Join8:
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+32)
	ld	xbc, EVT_GRID_DRAW
	jrl	CtlMsg_SendEventReturn
CtlMsgGrid_EventHandler:
	ld XWA,XIZ
	srl XWA, 16
	ld QWA,0
	ld (XBC),WA
	ld XHL,XIY
	ld WA,IZ
	ld (XIY),WA
	lda xde, (xsp + 0x28)
	ld (XSP+0x0c),XDE
	ld XWA,(XSP+0x18)
	ld (XWA),XDE
	cpw (XBC), 0x0001
	jrl nz, TtMdCtlMsg_ReturnZero2
	ld IZ,(XHL)
	ld xwa, 0:i3
	ld a, (0x024774:24)
	ld XBC,0x0000001a
	call InitializeKubo_Helper
	cp iz, 2:i3
	jrl z, CtlMsg_ComputeAndCheck
	ld xbc, 0:i3
	ld c, (0x024772:24)
	ld XWA,XBC
	sll XWA, 0x04
	sub XWA,XBC
	sll XWA, 0x06
	ld XBC,(XSP+0x10)
	add XBC,XWA
	add XBC,XHL
	cp iz, 1:i3
	jr z, CtlMsg_ReadOffsetAndSend
	cp iz, 0:i3
	jrl nz, TtMdCtlMsg_ReturnZero2
	ld XWA,(XSP+0x1c)
	sub XWA,0x0000f9a0
	add XBC,XWA
	bit 7,(XBC)
	jr z, CtlMsg_SendAudioCommand
	pushw CtlMsgGrid_EventHandler_Str_OFF@hi16
	pushw CtlMsgGrid_EventHandler_Str_OFF@lo16
	ld XWA,(XSP+0x10)
	push XWA
	call Free_Compare2
	inc 8,XSP
	jr t, CtlMsg_GetFocusAndDispatch
CtlMsg_SendAudioCommand:
	ld	a, (xbc)
	extz	wa
	pushw	wa
	pushw	CtlMsg_SendAudioCommand_Str_Fmt3d@hi16
	pushw	CtlMsg_SendAudioCommand_Str_Fmt3d@lo16
	ld	xwa, (xsp+18)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
CtlMsg_GetFocusAndDispatch:
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 32)
	ld xbc, EVT_GRID_DRAW
	jrl CtlMsg_SendEventReturn

CtlMsg_ReadOffsetAndSend:
	ld	xwa, (xsp+20)
	lda	xwa, (xwa+15)
	sub	xwa, 63904
	add	xbc, xwa
	ld	a, (xbc)
	extz	wa
	pushw	wa
	pushw	CtlMsg_ReadOffsetAndSend_Str_Fmt3d@hi16
	pushw	CtlMsg_ReadOffsetAndSend_Str_Fmt3d@lo16
	ld	xwa, (xsp+18)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+32)
	ld	xbc, EVT_GRID_DRAW
	jr	CtlMsg_SendEventReturn
CtlMsg_ComputeAndCheck:
	ld XWA,(XSP+0x14)
	lda xbc, (xwa + 0x11)
	sub XBC,0x0000f9a0
	ld xwa, 0:i3
	ld a, (0x024772:24)
	ld XDE,XWA
	sll XDE, 0x04
	sub XDE,XWA
	sll XDE, 0x06
	ld XWA,(XSP+0x10)
	add XWA,XDE
	add XWA,XHL
	add XWA,XBC
	bit 7,(XWA)
	jr z, CtlMsg_SendParamValue
	pushw CtlMsg_ComputeAndCheck_Str_OFF@hi16
	pushw CtlMsg_ComputeAndCheck_Str_OFF@lo16
	ld XWA,(XSP+0x10)
	push XWA
	call Free_Compare2
	inc 8,XSP
	jr t, CtlMsg_DispatchFocusEvent
CtlMsg_SendParamValue:
	ld	a, (xwa)
	extz	wa
	pushw	wa
	pushw	CtlMsg_SendParamValue_Str_Fmt3d@hi16
	pushw	CtlMsg_SendParamValue_Str_Fmt3d@lo16
	ld	xwa, (xsp+18)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
CtlMsg_DispatchFocusEvent:
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 32)
	ld xbc, EVT_GRID_DRAW

CtlMsg_SendEventReturn:
	call SendEvent

TtMdCtlMsg_ReturnZero2:
	ld xhl, 0:i3
	pop xiz
	lda xsp, (xsp + 74)
	ret

TtMdCtlMsg:
	cp xbc, EVT_REPAINT
	jr z, TtMdCtlMsg_ReturnZero
	cp xbc, EVT_PAINT
	jr z, TtMdCtlMsg_ReturnZero
	cp xbc, EVT_HIDE
	jr z, TtMdCtlMsg_ReturnZero
	cp xbc, EVT_SHOW
	jr nz, TtMdCtlMsg_ReturnZero
	or xde, xde
	jr nz, TtMdCtlMsg_ReturnZero
	ld (0x024776:24), 0x00
	ld xwa, 0x520002
	call GetViewInstance
	ld xwa, (xhl + 42)
	ldw (xwa), 0x2
	ld xwa, (xhl + 46)
	ldw (xwa), 0x1

TtMdCtlMsg_ReturnZero:
	ld xhl, 0:i3
	ret

AcCtlMsgGridBoxProc:
	lda xsp, (xsp - 32)
	push xiz
	ld (xsp + 24), xde
	ld (xsp + 28), xbc
	ld (xsp + 32), xwa
	ld xiy, AcCtlMsgGridBoxProc_LocalInit
	lda xix, (xsp + 8)
	ldw bc, 0x8
	ldirw
	ld xbc, (xsp + 28)
	cp xbc, EVT_REQUEST_GRID_DRAW
	jrl z, AcCtlMsgGrid_CellSelect
	ld xwa, (xsp + 28)
	cp xwa, EVT_GET_FIXED_ROW_STR
	jrl z, AcCtlMsgGrid_GetRowText
	cp xwa, EVT_GET_FIXED_COL_STR
	jrl z, AcCtlMsgGrid_GetColText
	cp xwa, EVT_SW_IN
	jrl z, AcCtlMsgGrid_OK
	cp xwa, EVT_PAINT
	jrl z, AcCtlMsgGrid_Show
	cp xwa, EVT_SHOW
	jr z, AcCtlMsgGrid_Init
	sub xbc, EVT_INDEXSW_UP
	cp xbc, 0x0
	jrl lt, AcCtlMsgGrid_ForwardToBase
	cp xbc, 0x6
	jrl gt, AcCtlMsgGrid_ForwardToBase
	add xbc, xbc
	add xbc, AcCtlMsgGridBoxProc_CaseTable
	ld bc, (xbc)
	lda xix, (AcCtlMsgGrid_Init:24)
; Computed jump: target = AcCtlMsgGrid_Init + AcCtlMsgGridBoxProc_CaseTable[i], AcCtlMsgGridBoxProc_CaseTable = 16-bit offsets (7 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1c00017:
;   0x1c00017 -> AcCtlMsgGridBoxProc_Evt1C00017
;   0x1c00018 -> AcCtlMsgGridBoxProc_Evt1C00018
;   0x1c00019 -> AcCtlMsgGridBoxProc_Evt1C00017
;   0x1c0001a -> AcCtlMsgGridBoxProc_Evt1C00018
;   0x1c0001b -> AcCtlMsgGrid_ForwardToBase
;   0x1c0001c -> AcCtlMsgGridBoxProc_Evt1C0001C
;   0x1c0001d -> AcCtlMsgGridBoxProc_Evt1C0001C
	jp	t, (xix+bc)

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
	ld a, (0x024776:24)
	extz wa
	ld (xbc), wa
	ld xwa, (xsp + 32)
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld xiz, xhl
	ld xwa, (xsp + 4)
	ld bc, (xwa + 26)
	ld xwa, xiz
	srl xwa, 16
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 32)
	ld xbc, EVT_INDEXSW_UP
	call SetDialUp
	ld xwa, (xsp + 4)
	ld bc, (xwa + 26)
	ld xwa, xiz
	srl xwa, 16
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 32)
	ld xbc, EVT_INDEXSW_DOWN
	call SetDialDown
	ld wa, 1:i3
	jrl AcCtlMsgGrid_ScrollCommit

AcCtlMsgGrid_Show:
	ld XWA,(XSP+0x20)
	ld XBC,(XSP+0x1c)
	ld XDE,(XSP+0x18)
	call InheritedProc
	ld XWA,(XSP+0x20)
	call GetViewInstance
	ld XIZ,XHL
	ld XWA,MidiPart_PageDisplay_Data
	ldw BC, 0x00c1
	ldw DE, 0x00f3
	call DrawDesignBox
	ld XWA,(XIZ+0x4a)
	ld WA,(XWA)
	sla WA, 0x02
	lda xbc, (AcCtlMsgGrid_Show_PtrTable:24)
	ld	xwa, (xbc+wa)
	push XWA
	lda xwa, (xsp + 0x0c)
	push XWA
	call Free_Compare2
	inc 8,XSP
	lda	xde, (xsp+8)
	ld	xwa, 0:i3
	push	xwa
	pushw	0
	pushw	247
	ld	xwa, MidiPart_PageDisplay_Data
	ld	xbc, AcCtlMsgGrid_Show_Table
	call	DrawStringCentered
	jrl	AcCtlMsgGrid_ReturnHandled
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
	cp wa, 1:i3
	jr le, AcCtlMsgGrid_OK_Up_Store
	ld xwa, (xde)
	ldw (xwa), 0x0

AcCtlMsgGrid_OK_Up_Store:
	ld xwa, (xde)
	ld wa, (xwa)
	ld (0x024776:24), a
	ld xwa, (xsp + 32)
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xsp + 32)
	ld xbc, EVT_SET_SELECTED_CEL
	ld xde, 0xffff0002
	jr AcCtlMsgGrid_OK_DispatchScroll

AcCtlMsgGrid_OK_Down:
	ld xde, xbc
	ld xbc, (xbc)
	ld wa, (xbc)
	dec 1, wa
	ld (xbc), wa
	cp wa, 0:i3
	jr ge, AcCtlMsgGrid_OK_Down_Store
	ld xwa, (xde)
	ldw (xwa), 0x1

AcCtlMsgGrid_OK_Down_Store:
	ld xwa, (xde)
	ld wa, (xwa)
	ld (0x024776:24), a
	ld xwa, (xsp + 32)
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xsp + 32)
	ld xbc, EVT_SET_SELECTED_CEL
	ld xde, 0xffff0002

AcCtlMsgGrid_OK_DispatchScroll:
	call SendEvent
	jrl AcCtlMsgGrid_ReturnHandled
AcCtlMsgGridBoxProc_Evt1C00017:
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	call InheritedProc
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 32)
	ld xbc, EVT_CHECK_INDEX
	ld xde, (xsp + 24)
	call SendEvent
	or xhl, xhl
	jrl z, AcCtlMsgGrid_ScrollUp_AutoScroll
	ld xwa, (xsp + 32)
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld ix, hl
	cp ix, 2:i3
	jr nz, AcCtlMsgGrid_ScrollUp_CellNav
	ld xwa, (xsp + 4)
	lda xbc, (xwa + 74)
	ld xde, (xbc)
	ld wa, (xde)
	dec 1, wa
	ld (xde), wa
	cp wa, 0:i3
	jr ge, AcCtlMsgGrid_ScrollUp_PageDec
	ld xwa, (xbc)
	ldw (xwa), 0x1

AcCtlMsgGrid_ScrollUp_PageDec:
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (0x024776:24), a
	ld xwa, (xsp + 32)
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 74)
	lda xbc, (AcCtlMsgGrid_ScrollUp_PageDec_Table:24)
	ld wa, (xwa)
	ld	a, (xbc+wa)
	extz wa
	ld de, wa
	extz xde
	add xde, 0xffff0000
	ld xwa, (xsp + 32)
	ld xbc, EVT_SET_SELECTED_CEL
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
	ld xbc, EVT_SELE_DRAW
	call SendEvent
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	jrl AcCtlMsgGrid_ScrollRelease

AcCtlMsgGrid_ScrollUp_AutoScroll:
	ld xwa, (xsp + 32)
	ld xbc, EVT_CHECK_GRID_INDEX
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
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 24)
	call SetDialUp
	ld xwa, (xsp + 32)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 24)
	call SetDialDown
	ld wa, 1:i3
	jrl AcCtlMsgGrid_ScrollCommit
AcCtlMsgGridBoxProc_Evt1C00018:
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	call InheritedProc
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 32)
	ld xbc, EVT_CHECK_INDEX
	ld xde, (xsp + 24)
	call SendEvent
	or xhl, xhl
	jrl z, AcCtlMsgGrid_ScrollDown_AutoScroll
	ld xwa, (xsp + 32)
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld ix, hl
	ld xwa, (xsp + 4)
	lda xde, (xwa + 74)
	ld xbc, (xde)
	lda xhl, (AcCtlMsgGrid_ScrollUp_PageDec_Table:24)
	ld wa, (xbc)
	ld	a, (xhl+wa)
	extz wa
	cp wa, ix
	jr nz, AcCtlMsgGrid_ScrollDown_CellNav
	ld wa, (xbc)
	inc 1, wa
	ld (xbc), wa
	cp wa, 1:i3
	jr le, AcCtlMsgGrid_ScrollDown_PageInc
	ld xwa, (xde)
	ldw (xwa), 0x0

AcCtlMsgGrid_ScrollDown_PageInc:
	ld xwa, (xde)
	ld wa, (xwa)
	ld (0x024776:24), a
	ld xwa, (xsp + 32)
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xsp + 32)
	ld xbc, EVT_SET_SELECTED_CEL
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
	ld xbc, EVT_SELE_DRAW
	call SendEvent
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)

AcCtlMsgGrid_ScrollRelease:
	call SetAutoInc
	jrl AcCtlMsgGrid_ReturnHandled

AcCtlMsgGrid_ScrollDown_AutoScroll:
	ld xwa, (xsp + 32)
	ld xbc, EVT_CHECK_GRID_INDEX
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
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 24)
	call SetDialUp
	ld xwa, (xsp + 32)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 24)
	call SetDialDown
	ld wa, 1:i3

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
	cp wa, 1:i3
	jr z, AcCtlMsgGrid_GetRowText_Page1
	cp wa, 0:i3
	jr nz, AcCtlMsgGrid_ReturnHandled
	ld xwa, AcCtlMsgGrid_GetRowText_Str
	jr AcCtlMsgGrid_GetRowText_Push

AcCtlMsgGrid_GetRowText_Page1:
	ld xwa, AcCtlMsgGrid_GetRowText_Page1_Str

AcCtlMsgGrid_GetRowText_Push:
	push xwa

AcCtlMsgGrid_GetRowText_Strcpy:
	ld	xwa, (xsp+28)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	AcCtlMsgGrid_ReturnHandled
AcCtlMsgGridBoxProc_Evt1C0001C:
	ld	xwa, (xsp+32)
	call	GetViewInstance
	ld	xwa, (xhl+70)
	ld	xbc, (xsp+28)
	ld	xde, (xsp+24)
	jr	AcCtlMsgGrid_ForwardToParent
AcCtlMsgGrid_CellSelect:
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)

AcCtlMsgGrid_ForwardToParent:
	call ApFuncCall

AcCtlMsgGrid_ReturnHandled:
	ld xhl, 0:i3
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
	ld xiy, CtlMsgGridCheck_LocalInit
	lda xix, (xsp + 20)
	ld bc, 5:i3
	ldirw
	ld xiy, ComSetGridCheck_LocalInit
	lda xix, (xsp + 12)
	ld bc, 4:i3
	ldirw
	ld xix, xde
	lda xhl, (xsp + 12)
	lda xwa, (CtlMsgGridCheck_Table:24)
	ld (xsp + 8), xwa
	lda xbc, (xhl + 2)
	cp xde, EVT_REQUEST_GRID_DRAW
	jrl z, MidiSetup_TtlDispatch
	ld xwa, xix
	sub xwa, EVT_INDEXSW_UP
	cp xwa, 0x0
	jrl lt, CtlMsgGrid_ReturnZero
	cp xwa, 0x6
	jrl gt, CtlMsgGrid_ReturnZero
	add xwa, xwa
	add xwa, CtlMsgGridCheck_CaseTable
	ld wa, (xwa)
	lda xix, (CtlMsgGridCheck_Evt1C00017:24)
; Computed jump: target = CtlMsgGridCheck_Evt1C00017 + CtlMsgGridCheck_CaseTable[i], CtlMsgGridCheck_CaseTable = 16-bit offsets (7 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1c00017:
;   0x1c00017 -> CtlMsgGridCheck_Evt1C00017
;   0x1c00018 -> CtlMsgGridCheck_Evt1C00018
;   0x1c00019 -> CtlMsgGridCheck_Evt1C00017
;   0x1c0001a -> CtlMsgGridCheck_Evt1C00018
;   0x1c0001b -> CtlMsgGrid_ReturnZero
;   0x1c0001c -> CtlMsgGridCheck_Evt1C0001C
;   0x1c0001d -> CtlMsgGrid_ReturnZero
	jp	t, (xix+wa)
CtlMsgGridCheck_Evt1C00017:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	ld	(xsp+30), xhl
	lda	xbc, (xsp+12)
	ld	xwa, (xsp+30)
	srl	xwa, 16
	ld	qwa, 0
	ld	(xbc), wa
	ld	xwa, (xsp+30)
	ld	(xbc+2), wa
	cpw	(xbc), 1
	jrl	nz, CtlMsgGrid_ReturnZero
	ld	bc, wa
	sla	bc, 2
	ld	a, (149366:24)
	extz	wa
	muls	wa, 36
	ld	de, wa
	add	de, bc
	lda	xwa, (CtlMsgGridCheck_Table:24)
	ld_rrl	xwa, xwa, de
	ld	bc, 1:i3
	ld	de, 2:i3
	jr	CtlMsgGridCheck_Join
CtlMsgGridCheck_Evt1C00018:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	ld	(xsp+30), xhl
	lda	xbc, (xsp+12)
	ld	xwa, (xsp+30)
	srl	xwa, 16
	ld	qwa, 0
	ld	(xbc), wa
	ld	xwa, (xsp+30)
	ld	(xbc+2), wa
	cpw	(xbc), 1
	jrl	nz, CtlMsgGrid_ReturnZero
	ld	bc, wa
	sla	bc, 2
	ld	a, (149366:24)
	extz	wa
	muls	wa, 36
	ld	de, wa
	add	de, bc
	lda	xwa, (CtlMsgGridCheck_Table:24)
	ld_rrl	xwa, xwa, de
	ldw	bc, 65535
	ld	de, 2:i3
CtlMsgGridCheck_Join:
	call	MainLswAdd
	jrl	CtlMsgGrid_ReturnZero
CtlMsgGridCheck_Evt1C0001C:
	ld	(xsp+4), xhl
	ldw	(xhl), 1
	ld	xde, xbc
	ldw	(xbc), 0
	ld	a, (149366:24)
	extz	wa
	muls	wa, 36
	ld	ix, wa
	ld	xhl, (xsp+8)
	ld	xiz, (xsp+30)
	jr	CtlMsgGridCheck_Join2
CtlMsgGridCheck_Loop:
	ld	wa, bc
	sla	wa, 2
	ld	iy, ix
	add	iy, wa
	ld	xwa, (xiz)
	cp	xwa, (xhl+iy)	; cp xwa, (xhl+iy)
	jr	nz, CtlMsgGridCheck_Skip2
	lda	xde, (xsp+20)
	ld	xwa, (xsp+4)
	ld	(xwa+4), xde
	ld	xbc, CtlMsgGridCheck_JumpTable_Str_2
	ld	xwa, (xsp+30)
	cpw	(xwa+4), 0
	jr	z, CtlMsgGridCheck_Skip
	ld	xbc, CtlMsgGridCheck_JumpTable_Str
CtlMsgGridCheck_Skip:
	push	xbc
	push	xde
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
	jr	CtlMsgGridCheck_Join3
CtlMsgGridCheck_Skip2:
	inc	1, bc
	ld	(xde), bc
CtlMsgGridCheck_Join2:
	ld	bc, (xde)
	cp	bc, 9
	jr	lt, CtlMsgGridCheck_Loop
	jr	CtlMsgGrid_ReturnZero
MidiSetup_TtlDispatch:
	ld XWA,(XSP+0x1e)
	srl XWA, 16
	ld QWA,0
	ld (XHL),WA
	ld XDE,XBC
	ld XWA,(XSP+0x1e)
	ld (XBC),WA
	lda xwa, (xsp + 0x14)
	ld (XHL+0x04),XWA
	cpw (XHL), 0x0001
	jr nz, CtlMsgGrid_ReturnZero
	ld DE,(XDE)
	sla DE, 0x02
	ld a, (0x024776:24)
	extz WA
	muls WA,0x0024
	ld BC,WA
	add BC,DE
	ld XWA,(XSP+0x08)
	ld	xwa, (xwa+bc)
	cp XWA,0xffffffff
	jr z, CtlMsgGrid_ReturnZero
	call AcApcToggleProc_Helper
	lda xbc, (xsp + 0x14)
	ld XWA,MidiSetup_TtlDispatch_Str_2
	cp hl, 0:i3
	jr z, MidiSetup_CopyStrAndDispatch
	ld XWA,MidiSetup_TtlDispatch_Str
MidiSetup_CopyStrAndDispatch:
	push	xwa
	push	xbc
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+12)
	ld	xbc, EVT_GRID_DRAW
CtlMsgGridCheck_Join3:
	call	SendEvent
CtlMsgGrid_ReturnZero:
	ld xhl, 0:i3
	pop xiz
	lda xsp, (xsp + 30)
	ret

TtMdPart:
	cp xbc, EVT_REPAINT
	jr z, TtMdPart_ReturnZero
	cp xbc, EVT_PAINT
	jr z, TtMdPart_ReturnZero
	cp xbc, EVT_HIDE
	jr z, MidiSetup_TtlCase1
	cp xbc, EVT_SHOW
	jr nz, TtMdPart_ReturnZero
	or xde, xde
	jr nz, TtMdPart_ReturnZero
	ld (0x024778:24), 0x00
	ld xwa, 0x510001
	call GetViewInstance
	ld xwa, (xhl + 42)
	ldw (xwa), 0x2
	ld xwa, (xhl + 46)
	ldw (xwa), 0x1
	ld xwa, NAKA_MAINFUNC_MainPmanControl
	ld xbc, EVT_PART_SELECT_PUT
	ld xde, 0:i3
	jr MidiSetup_TtlCase2

; MidiSetup title case 1
MidiSetup_TtlCase1:
	or xde, xde
	jr nz, TtMdPart_ReturnZero
	ld xwa, NAKA_MAINFUNC_MainPmanControl
	ld xbc, EVT_PART_SELECT_PUT
	ld xde, 0x3f

; MidiSetup title case 2
MidiSetup_TtlCase2:
	call MainFuncCall

TtMdPart_ReturnZero:
	ld xhl, 0:i3
	ret

AcMidiPartGridBoxProc:
	lda xsp, (xsp - 32)
	push xiz
	ld (xsp + 24), xde
	ld (xsp + 28), xbc
	ld (xsp + 32), xwa
	ld xiy, AcMidiPartGridBoxProc_LocalInit
	lda xix, (xsp + 8)
	ldw bc, 0x8
	ldirw
	ld xbc, (xsp + 28)
	cp xbc, EVT_REQUEST_GRID_DRAW
	jrl z, MidiSetup_GridBoxCase2
	ld xwa, (xsp + 28)
	cp xwa, EVT_GET_FIXED_ROW_STR
	jrl z, MidiSetup_GridBoxCase1
	cp xwa, EVT_GET_FIXED_COL_STR
	jrl z, MidiSetup_GridBoxDispatch
	cp xwa, EVT_SW_IN
	jrl z, MidiSetup_TtlCase5
	cp xwa, EVT_PAINT
	jrl z, MidiSetup_TtlCase4
	cp xwa, EVT_SHOW
	jr z, MidiSetup_TtlCase3
	sub xbc, EVT_INDEXSW_UP
	cp xbc, 0x0
	jrl lt, MidiSetup_GridBoxCase4
	cp xbc, 0x6
	jrl gt, MidiSetup_GridBoxCase4
	add xbc, xbc
	add xbc, AcMidiPartGridBoxProc_CaseTable
	ld bc, (xbc)
	lda xix, (MidiSetup_TtlCase3:24)
; Computed jump: target = MidiSetup_TtlCase3 + AcMidiPartGridBoxProc_CaseTable[i], AcMidiPartGridBoxProc_CaseTable = 16-bit offsets (7 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1c00017:
;   0x1c00017 -> AcMidiPartGridBoxProc_Evt1C00017
;   0x1c00018 -> MidiPart_InitGridBox
;   0x1c00019 -> AcMidiPartGridBoxProc_Evt1C00017
;   0x1c0001a -> MidiPart_InitGridBox
;   0x1c0001b -> MidiSetup_GridBoxCase4
;   0x1c0001c -> AcMidiPartGridBoxProc_Evt1C0001C
;   0x1c0001d -> MidiPart_ReturnZeroJmp
	jp	t, (xix+bc)

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
	ld a, (0x024778:24)
	extz wa
	ld (xbc), wa
	ld xwa, (xsp + 32)
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld xiz, xhl
	ld xwa, (xsp + 4)
	ld bc, (xwa + 26)
	ld xwa, xiz
	srl xwa, 16
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 32)
	ld xbc, EVT_INDEXSW_UP
	call SetDialUp
	ld xwa, (xsp + 4)
	ld bc, (xwa + 26)
	ld xwa, xiz
	srl xwa, 16
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 32)
	ld xbc, EVT_INDEXSW_DOWN
	call SetDialDown
	ld wa, 1:i3
	jrl MidiPart_SetDialEnable

; MidiSetup title case 4
MidiSetup_TtlCase4:
	ld XWA,(XSP+0x20)
	ld XBC,(XSP+0x1c)
	ld XDE,(XSP+0x18)
	call InheritedProc
	ld XWA,(XSP+0x20)
	call GetViewInstance
	ld XIZ,XHL
	ld XWA,MidiPart_PageDisplay_Data
	ldw BC, 0x00c1
	ldw DE, 0x00f3
	call DrawDesignBox
	ld XWA,(XIZ+0x4a)
	ld WA,(XWA)
	sla WA, 0x02
	lda xbc, (MidiSetup_TtlCase4_PtrTable:24)
	ld	xwa, (xbc+wa)
	push XWA
	lda xwa, (xsp + 0x0c)
	push XWA
	call Free_Compare2
	inc 8,XSP
	lda	xde, (xsp+8)
	ld	xwa, 0:i3
	push	xwa
	pushw	0
	pushw	247
	ld	xwa, MidiPart_PageDisplay_Data
	ld	xbc, AcCtlMsgGrid_Show_Table
	call	DrawStringCentered
	jrl	MidiPart_ReturnZeroJmp
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
	cp wa, 2:i3
	jr le, MidiPart_StorePartIndex
	ld xwa, (xde)
	ldw (xwa), 0x0

MidiPart_StorePartIndex:
	ld xwa, (xde)
	ld wa, (xwa)
	ld (0x024778:24), a
	ld xwa, (xsp + 32)
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xsp + 32)
	ld xbc, EVT_SET_SELECTED_CEL
	ld xde, 0xffff0002
	call SendEvent
	ld a, (0x024778:24)
	extz wa
	muls wa, 0xa
	lda xbc, (MidiSetup_TtlCase5_Table:24)
	ld xde, 0:i3
	ld	e, (xbc+wa)
	ld xwa, NAKA_MAINFUNC_MainPmanControl
	ld xbc, EVT_PART_SELECT_PUT
	jr MidiPart_CallMainFunc

MidiPart_DecrementPart:
	ld xde, xbc
	ld xbc, (xbc)
	ld wa, (xbc)
	dec 1, wa
	ld (xbc), wa
	cp wa, 0:i3
	jr ge, MidiPart_StoreAndNotify
	ld xwa, (xde)
	ldw (xwa), 0x2

MidiPart_StoreAndNotify:
	ld xwa, (xde)
	ld wa, (xwa)
	ld (0x024778:24), a
	ld xwa, (xsp + 32)
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xsp + 32)
	ld xbc, EVT_SET_SELECTED_CEL
	ld xde, 0xffff0002
	call SendEvent
	ld a, (0x024778:24)
	extz wa
	muls wa, 0xa
	lda xbc, (MidiSetup_TtlCase5_Table:24)
	ld xde, 0:i3
	ld	e, (xbc+wa)
	ld xwa, NAKA_MAINFUNC_MainPmanControl
	ld xbc, EVT_PART_SELECT_PUT

MidiPart_CallMainFunc:
	call MainFuncCall
	jrl MidiPart_ReturnZeroJmp
AcMidiPartGridBoxProc_Evt1C00017:
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	call InheritedProc
	ld xwa, (xsp + 32)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 32)
	ld xbc, EVT_CHECK_INDEX
	ld xde, (xsp + 24)
	call SendEvent
	or xhl, xhl
	jrl z, MidiPart_SendShowQuery
	ld xwa, (xsp + 32)
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld iz, hl
	cp iz, 2:i3
	jrl nz, MidiPart_Part2ColumnNav
	ld xwa, (xsp + 4)
	lda xbc, (xwa + 74)
	ld xde, (xbc)
	ld wa, (xde)
	dec 1, wa
	ld (xde), wa
	cp wa, 0:i3
	jr ge, MidiPart_AutoDec_StorePart
	ld xwa, (xbc)
	ldw (xwa), 0x2

MidiPart_AutoDec_StorePart:
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (0x024778:24), a
	ld xwa, (xsp + 32)
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 74)
	lda xbc, (MidiPart_CallMainFunc_Table:24)
	ld wa, (xwa)
	ld	a, (xbc+wa)
	extz wa
	ld de, wa
	extz xde
	add xde, 0xffff0000
	ld xwa, (xsp + 32)
	ld xbc, EVT_SET_SELECTED_CEL
	call SendEvent
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 74)
	lda xbc, (MidiPart_CallMainFunc_Table:24)
	ld wa, (xwa)
	ld	c, (xbc+wa)
	extz bc
	ld a, (0x024778:24)
	extz wa
	muls wa, 0xa
	add wa, bc
	lda xbc, (MidiPart_CallMainFunc_Str:24)
	ld xde, 0:i3
	ld	e, (xbc+wa)
	ld xwa, NAKA_MAINFUNC_MainPmanControl
	ld xbc, EVT_PART_SELECT_PUT
	call MainFuncCall
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	jrl MidiPartAutoIncReturn

MidiPart_Part2ColumnNav:
	cp (0x024778:24), 0x02
	jr nz, MidiPart_GenericColumnNav
	ld wa, iz
	add wa, wa
	lda xbc, (MidiPart_Part2ColumnNav_Table:24)
	ld	wa, (xbc+wa)
	ld bc, iz
	sub bc, wa
	ld de, bc
	extz xde
	add xde, 0xffff0000
	ld xwa, (xsp + 32)
	ld xbc, EVT_SELE_DRAW
	call SendEvent
	ld wa, iz
	add wa, wa
	lda xbc, (MidiPart_Part2ColumnNav_Table:24)
	ld	wa, (xbc+wa)
	ld bc, iz
	sub bc, wa
	ld a, (0x024778:24)
	extz wa
	muls wa, 0xa
	add wa, bc
	lda xbc, (MidiPart_CallMainFunc_Str:24)
	ld xde, 0:i3
	ld	e, (xbc+wa)
	ld xwa, NAKA_MAINFUNC_MainPmanControl
	ld xbc, EVT_PART_SELECT_PUT
	jr MidiPart_CallMainFuncSetAuto

MidiPart_GenericColumnNav:
	ld wa, iz
	dec 1, wa
	ld de, wa
	extz xde
	add xde, 0xffff0000
	ld xwa, (xsp + 32)
	ld xbc, EVT_SELE_DRAW
	call SendEvent
	ld bc, iz
	dec 1, bc
	ld a, (0x024778:24)
	extz wa
	muls wa, 0xa
	add wa, bc
	lda xbc, (MidiPart_CallMainFunc_Str:24)
	ld xde, 0:i3
	ld	e, (xbc+wa)
	ld xwa, NAKA_MAINFUNC_MainPmanControl
	ld xbc, EVT_PART_SELECT_PUT

MidiPart_CallMainFuncSetAuto:
	call MainFuncCall
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	jrl MidiPartAutoIncReturn

MidiPart_SendShowQuery:
	ld xwa, (xsp + 32)
	ld xbc, EVT_CHECK_GRID_INDEX
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
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 24)
	call SetDialUp
	ld xwa, (xsp + 32)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 24)
	call SetDialDown
	ld wa, 1:i3
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
	ld xbc, EVT_CHECK_INDEX
	ld xde, (xsp + 24)
	call SendEvent
	or xhl, xhl
	jrl z, MidiPart_SendShowQueryUp
	ld xwa, (xsp + 32)
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
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
	cp wa, 2:i3
	jr le, MidiPart_AutoInc_StorePart
	ld xwa, (xbc)
	ldw (xwa), 0x0

MidiPart_AutoInc_StorePart:
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (0x024778:24), a
	ld xwa, (xsp + 32)
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xsp + 32)
	ld xbc, EVT_SET_SELECTED_CEL
	ld xde, 0xffff0002
	call SendEvent
	ld a, (0x024778:24)
	extz wa
	muls wa, 0xa
	lda xbc, (MidiSetup_TtlCase5_Table:24)
	ld xde, 0:i3
	ld	e, (xbc+wa)
	ld xwa, NAKA_MAINFUNC_MainPmanControl
	ld xbc, EVT_PART_SELECT_PUT
	call MainFuncCall
	ld xwa, (xsp + 32)
	ld xbc, (xsp + 28)
	ld xde, (xsp + 24)
	jrl MidiPartAutoIncReturn

MidiPart_Part2ColumnNavUp:
	cp (0x024778:24), 0x02
	jr nz, MidiPart_GenericColumnNavUp
	ld wa, iz
	add wa, wa
	lda xbc, (MidiPart_Part2ColumnNavUp_Table:24)
	ld	wa, (xbc+wa)
	add wa, iz
	ld de, wa
	extz xde
	add xde, 0xffff0000
	ld xwa, (xsp + 32)
	ld xbc, EVT_SELE_DRAW
	call SendEvent
	ld wa, iz
	add wa, wa
	lda xbc, (MidiPart_Part2ColumnNavUp_Table:24)
	ld	bc, (xbc+wa)
	add bc, iz
	ld a, (0x024778:24)
	extz wa
	muls wa, 0xa
	add wa, bc
	lda xbc, (MidiPart_CallMainFunc_Str:24)
	ld xde, 0:i3
	ld	e, (xbc+wa)
	ld xwa, NAKA_MAINFUNC_MainPmanControl
	ld xbc, EVT_PART_SELECT_PUT
	jr MidiPart_CallMainFuncAutoUp

MidiPart_GenericColumnNavUp:
	ld wa, iz
	inc 1, wa
	ld de, wa
	extz xde
	add xde, 0xffff0000
	ld xwa, (xsp + 32)
	ld xbc, EVT_SELE_DRAW
	call SendEvent
	ld bc, iz
	inc 1, bc
	ld a, (0x024778:24)
	extz wa
	muls wa, 0xa
	add wa, bc
	lda xbc, (MidiPart_CallMainFunc_Str:24)
	ld xde, 0:i3
	ld	e, (xbc+wa)
	ld xwa, NAKA_MAINFUNC_MainPmanControl
	ld xbc, EVT_PART_SELECT_PUT

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
	ld xbc, EVT_CHECK_GRID_INDEX
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
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 24)
	call SetDialUp
	ld xwa, (xsp + 32)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 24)
	call SetDialDown
	ld wa, 1:i3

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
	cp wa, 2:i3
	jr z, MidiSetup_GridStr2
	cp wa, 1:i3
	jr z, MidiSetup_GridStr1
	cp wa, 0:i3
	jr nz, MidiPart_ReturnZeroJmp
	ld xwa, MidiSetup_GridBoxCase1_Str
	jr MidiSetup_PushGridStr

MidiSetup_GridStr1:
	ld xwa, MidiSetup_GridStr1_Str
	jr MidiSetup_PushGridStr

MidiSetup_GridStr2:
	ld xwa, MidiSetup_GridStr2_Str

MidiSetup_PushGridStr:
	push xwa

MidiSetup_CopyStrAndReturn:
	ld	xwa, (xsp+28)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	MidiPart_ReturnZeroJmp
AcMidiPartGridBoxProc_Evt1C0001C:
	ld	xwa, (xsp+32)
	call	GetViewInstance
	ld	xwa, (xhl+70)
	ld	xbc, (xsp+28)
	ld	xde, (xsp+24)
	jr	MidiSetup_GridBoxCase3
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
	ld xhl, 0:i3
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
	ld xiy, MidiPartGridCheck_LocalInit
	lda xix, (xsp + 24)
	ld bc, 5:i3
	ldirw
	ld xiy, ComSetGridCheck_LocalInit
	lda xix, (xsp + 16)
	ld bc, 4:i3
	ldirw
	ld xix, (xsp + 38)
	lda xhl, (xsp + 24)
	lda xiy, (xsp + 16)
	lda xbc, (xiy + 2)
	lda xde, (xiy + 4)
	ld xwa, (xsp + 38)
	cp xwa, EVT_REQUEST_GRID_DRAW
	jrl z, MidiSetup_EventHandler
	ld xwa, xix
	sub xwa, EVT_INDEXSW_UP
	cp xwa, 0x0
	jrl lt, MidiSetup_ReturnZero
	cp xwa, 0x6
	jrl gt, MidiSetup_ReturnZero
	add xwa, xwa
	add xwa, MidiPartGridCheck_CaseTable
	ld wa, (xwa)
	lda xix, (MidiPartGridCheck_Evt1C00017:24)
; Computed jump: target = MidiPartGridCheck_Evt1C00017 + MidiPartGridCheck_CaseTable[i], MidiPartGridCheck_CaseTable = 16-bit offsets (7 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1c00017:
;   0x1c00017 -> MidiPartGridCheck_Evt1C00017
;   0x1c00018 -> MidiPartGridCheck_Evt1C00018
;   0x1c00019 -> MidiPartGridCheck_Evt1C00017
;   0x1c0001a -> MidiPartGridCheck_Evt1C00018
;   0x1c0001b -> MidiSetup_ReturnZero
;   0x1c0001c -> MidiPartGridCheck_Evt1C0001C
;   0x1c0001d -> MidiSetup_ReturnZero
	jp	t, (xix+wa)

MidiPartGridCheck_Evt1C00017:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	ld	(xsp+34), xhl
	lda	xbc, (xsp+16)
	ld	xwa, (xsp+34)
	srl	xwa, 16
	ld	qwa, 0
	ld	(xbc), wa
	ld	xwa, (xsp+34)
	ld	(xbc+2), wa
	muls	wa, 12
	ld	de, wa
	sub	de, 24
	ld	a, (0x024778:24)
	extz	wa
	muls	wa, 96
	ld	hl, wa
	add	hl, de
	ld	wa, (xbc)
	sla	wa, 2
	dec	4, wa
	ld	de, wa
	add	de, hl
	lda	xwa, (MidiSetup_EventHandler_Table:24)
	ld_rrl	xwa, xwa, de	; ld xwa, (xwa+de)
	ld	(xsp+12), xwa
	ld	wa, (xbc)
	cp	wa, 3:i3
	jr	z, MidiPartGridCheck_Skip4
	cp	wa, 2:i3
	jr	z, MidiPartGridCheck_Skip3
	cp	wa, 1:i3
	jrl	nz, MidiSetup_ReturnZero
	ld	xwa, (xsp+12)
	inc	1, xwa
	call	AcApcToggleProc_Helper
	cp	hl, 0:i3
	jr	nz, MidiPartGridCheck_Skip
	ld	xwa, (xsp+12)
	inc	1, xwa
	ld	bc, 1:i3
	ld	de, 2:i3
	call	MainLswPut
	ld	xwa, (xsp+12)
	inc	2, xwa
	ld	bc, 1:i3
	ld	de, 2:i3
	call	MainLswPut
	ld	xwa, (xsp+12)
	ld	bc, 0:i3
	ld	de, 2:i3
	jrl	MidiPartGridCheck_Join2
MidiPartGridCheck_Skip:
	ld	xwa, (xsp+38)
	cp	xwa, EVT_INDEXSW_UP_AIC
	jr	nz, MidiPartGridCheck_Skip2
	ld	xwa, (xsp+12)
	ld	bc, 4:i3
	ld	de, 2:i3
	jrl	MidiPartGridCheck_Join
MidiPartGridCheck_Skip2:
	ld	xwa, (xsp+12)
	ld	bc, 1:i3
	ld	de, 2:i3
	jrl	MidiPartGridCheck_Join
MidiPartGridCheck_Skip3:
	ld	xwa, (xsp+12)
	call	AcApcToggleProc_Helper
	ld	wa, hl
	add	wa, wa
	lda	xbc, (0xe80640:24)
	ld_rrw	bc, xbc, wa	; ld bc, (xbc+wa)
	cp	bc, hl
	jrl	z, MidiSetup_ReturnZero
	ld	xwa, (xsp+12)
	ld	de, 2:i3
	jrl	MidiPartGridCheck_Join2
MidiPartGridCheck_Skip4:
	ld	xwa, (xsp+12)
	ld	bc, 1:i3
	ld	de, 2:i3
	jrl	MidiPartGridCheck_Join2
MidiPartGridCheck_Evt1C00018:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	ld	(xsp+34), xhl
	lda	xbc, (xsp+16)
	ld	xwa, (xsp+34)
	srl	xwa, 16
	ld	qwa, 0
	ld	(xbc), wa
	ld	xwa, (xsp+34)
	ld	(xbc+2), wa
	muls	wa, 12
	ld	de, wa
	sub	de, 24
	ld	a, (0x024778:24)
	extz	wa
	muls	wa, 96
	ld	hl, wa
	add	hl, de
	ld	wa, (xbc)
	sla	wa, 2
	dec	4, wa
	ld	de, wa
	add	de, hl
	lda	xwa, (MidiSetup_EventHandler_Table:24)
	ld_rrl	xwa, xwa, de	; ld xwa, (xwa+de)
	ld	(xsp+12), xwa
	ld	wa, (xbc)
	cp	wa, 3:i3
	jr	z, MidiPartGridCheck_Skip8
	cp	wa, 2:i3
	jr	z, MidiPartGridCheck_Skip7
	cp	wa, 1:i3
	jrl	nz, MidiSetup_ReturnZero
	ld	xwa, (xsp+12)
	inc	1, xwa
	call	AcApcToggleProc_Helper
	cp	hl, 1:i3
	jrl	nz, MidiSetup_ReturnZero
	ld	xwa, (xsp+12)
	call	AcApcToggleProc_Helper
	cp	hl, 0:i3
	jr	nz, MidiPartGridCheck_Skip5
	ld	xwa, (xsp+12)
	inc	1, xwa
	ld	bc, 0:i3
	ld	de, 2:i3
	call	MainLswPut
	ld	xwa, (xsp+12)
	inc	2, xwa
	ld	bc, 0:i3
	ld	de, 2:i3
	jr	MidiPartGridCheck_Join2
MidiPartGridCheck_Skip5:
	ld	xwa, (xsp+38)
	cp	xwa, EVT_INDEXSW_DOWN_AIC
	jr	nz, MidiPartGridCheck_Skip6
	ld	xwa, (xsp+12)
	ldw	bc, 65532
	ld	de, 2:i3
	jr	MidiPartGridCheck_Join
MidiPartGridCheck_Skip6:
	ld	xwa, (xsp+12)
	ldw	bc, 65535
	ld	de, 2:i3
MidiPartGridCheck_Join:
	call	MainLswAdd
	jrl	MidiSetup_ReturnZero
MidiPartGridCheck_Skip7:
	ld	xwa, (xsp+12)
	call	AcApcToggleProc_Helper
	ld	wa, hl
	add	wa, wa
	lda	xbc, (0xe80650:24)
	ld_rrw	bc, xbc, wa	; ld bc, (xbc+wa)
	cp	bc, hl
	jrl	z, MidiSetup_ReturnZero
	ld	xwa, (xsp+12)
	ld	de, 2:i3
	jr	MidiPartGridCheck_Join2
MidiPartGridCheck_Skip8:
	ld	xwa, (xsp+12)
	ld	bc, 0:i3
	ld	de, 2:i3
MidiPartGridCheck_Join2:
	call	MainLswPut
	jrl	MidiSetup_ReturnZero
MidiPartGridCheck_Evt1C0001C:
	ld	xix, (xsp+34)
	ld	(xsp+4), xiy
	ld	(xsp+8), xhl
	ld	(xde), xhl
	ld	(xsp+12), xbc
	ldw	(xbc), 2
	jrl	MidiPartGridCheck_Join5
MidiPartGridCheck_Loop:
	ld	de, bc
	muls	de, 12
	sub	de, 24
	ld	a, (0x024778:24)
	extz	wa
	muls	wa, 96
	ld	iy, wa
	add	iy, de
	lda	xhl, (MidiSetup_EventHandler_Table:24)
	ld_rrl	xiz, xhl, iy	; ld xiz, (xhl+iy)
	ld	xde, (xsp+34)
	cp	(xde), xiz
	jr	nz, MidiPartGridCheck_Skip10
	ld	xwa, (xsp+4)
	ldw	(xwa), 1
	ld	xwa, (xde)
	inc	1, xwa
	call	AcApcToggleProc_Helper
	cp	hl, 0:i3
	jr	nz, MidiPartGridCheck_Skip9
	pushw	MidiPartGridCheck_LocalInit_Strings@hi16
	pushw	MidiPartGridCheck_LocalInit_Strings@lo16
	lda	xwa, (xsp+28)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	MidiPartGridCheck_Join3
MidiPartGridCheck_Skip9:
	ld	xwa, (xsp+34)
	ld	wa, (xwa+4)
	inc	1, wa
	pushw	wa
	pushw	MidiPartGridCheck_Evt1C0001C_Str_Fmt2d@hi16
	pushw	MidiPartGridCheck_Evt1C0001C_Str_Fmt2d@lo16
	lda	xwa, (xsp+30)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
MidiPartGridCheck_Join3:
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+16)
	ld	xbc, EVT_GRID_DRAW
	jrl	MidiPart_SendEventReturn
MidiPartGridCheck_Skip10:
	ld	xwa, (xix)
	dec	1, xwa
	lda	xde, (xix+4)
	cp	xwa, xiz
	jr	nz, MidiPartGridCheck_Skip12
	ld	xwa, (xsp+4)
	ldw	(xwa), 1
	cpw	(xde), 0
	jr	nz, MidiPartGridCheck_Skip11
	pushw	MidiPartGridCheck_Evt1C0001C_Str_OFF@hi16
	pushw	MidiPartGridCheck_Evt1C0001C_Str_OFF@lo16
	ld	xwa, (xsp+12)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	MidiPartGridCheck_Join4
MidiPartGridCheck_Skip11:
	ld	xwa, (xsp+34)
	ld	xwa, (xwa)
	dec	1, xwa
	call	AcApcToggleProc_Helper
	inc	1, hl
	pushw	hl
	pushw	MidiPartGridCheck_Evt1C0001C_Str_Fmt2d_2@hi16
	pushw	MidiPartGridCheck_Evt1C0001C_Str_Fmt2d_2@lo16
	lda	xwa, (xsp+30)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
MidiPartGridCheck_Join4:
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+16)
	ld	xbc, EVT_GRID_DRAW
	jrl	MidiPart_SendEventReturn
MidiPartGridCheck_Skip12:
	ld	iz, iy
	inc	4, iz
	ld	xwa, (xix)
	cp	xwa, (xhl+iz)	; cp xwa, (xhl+iz)
	jr	nz, MidiPartGridCheck_Skip13
	ld	xwa, (xsp+4)
	ldw	(xwa), 2
	ld	wa, (xde)
	sla	wa, 2
	lda	xbc, (Transpose_ValueDisplay_Table:24)
	ld_rrl	xwa, xbc, wa	; ld xwa, (xbc+wa)
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+16)
	ld	xbc, EVT_GRID_DRAW
	jrl	MidiPart_SendEventReturn
MidiPartGridCheck_Skip13:
	inc	8, iy
	ld	xwa, (xix)
	cp	xwa, (xhl+iy)	; cp xwa, (xhl+iy)
	jr	nz, MidiPartGridCheck_Skip15
	ld	xwa, (xsp+4)
	ldw	(xwa), 3
	ld	xwa, 0xe806dc
	cpw	(xde), 0
	jr	z, MidiPartGridCheck_Skip14
	ld	xwa, 0xe806d6
MidiPartGridCheck_Skip14:
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+16)
	ld	xbc, EVT_GRID_DRAW
	jrl	MidiPart_SendEventReturn
MidiPartGridCheck_Skip15:
	inc	1, bc
	ld	xwa, (xsp+12)
	ld	(xwa), bc
MidiPartGridCheck_Join5:
	ld	xwa, (xsp+12)
	ld	bc, (xwa)
	cp	bc, 10
	jrl	lt, MidiPartGridCheck_Loop
	jrl	MidiSetup_ReturnZero
MidiSetup_EventHandler:
	ld XWA,(XSP+0x22)
	srl XWA, 16
	ld QWA,0
	ld (XIY),WA
	ld XWA,(XSP+0x22)
	ld (XBC),WA
	ld (XDE),XHL
	ld DE,(XIY)
	ld BC,(XBC)
	muls BC,0x000c
	sub BC,0x0018
	ld a, (0x024778:24)
	extz WA
	muls WA,0x0060
	add WA,BC
	cp de, 3:i3
	jrl z, MidiPart_LookupFromTable
	lda xbc, (MidiSetup_EventHandler_Table:24)
	cp de, 2:i3
	jr z, MidiPart_LookupColumnParam
	cp de, 1:i3
	jrl nz, MidiSetup_ReturnZero
	ld	xwa, (xbc+wa)
	ld (XSP+0x0c),XWA
	cp XWA,0xffffffff
	jrl z, MidiSetup_ReturnZero
	ld XWA,(XSP+0x0c)
	inc 1,XWA
	call AcApcToggleProc_Helper
	cp hl, 0:i3
	jr nz, MidiPart_AudioCmdDisplay
	pushw MidiSetup_EventHandler_Str_OFF@hi16
	pushw MidiSetup_EventHandler_Str_OFF@lo16
	lda xwa, (xsp + 0x1c)
	push XWA
	call Free_Compare2
	inc 8,XSP
	jr t, MidiPart_GridDispatchEvent
MidiPart_AudioCmdDisplay:
	ld	xwa, (xsp+12)
	call	AcApcToggleProc_Helper
	inc	1, hl
	pushw	hl
	pushw	MidiPart_AudioCmdDisplay_Str_Fmt2d@hi16
	pushw	MidiPart_AudioCmdDisplay_Str_Fmt2d@lo16
	lda	xwa, (xsp+30)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
MidiPart_GridDispatchEvent:
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 16)
	ld xbc, EVT_GRID_DRAW
	jrl MidiPart_SendEventReturn
MidiPart_LookupColumnParam:
	inc	4, wa
	ld_rrl	xwa, xbc, wa
	ld	(xsp+12), xwa
	cp	xwa, 4294967295
	jr	z, MidiSetup_ReturnZero
	ld	xwa, (xsp+12)
	call	AcApcToggleProc_Helper
	sla	hl, 2
	lda	xwa, (Transpose_ValueDisplay_Table:24)
	ld_rrl	xwa, xwa, hl
	push	xwa
	lda	xwa, (xsp+28)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+16)
	ld	xbc, EVT_GRID_DRAW
	jr	MidiPart_SendEventReturn
MidiPart_LookupFromTable:
	lda xbc, (MidiPart_LookupFromTable_Table:24)
	ld	xwa, (xbc+wa)
	ld (XSP+0x0c),XWA
	cp XWA,0xffffffff
	jr z, MidiSetup_ReturnZero
	ld XWA,(XSP+0x0c)
	call AcApcToggleProc_Helper
	ld XWA,MidiPart_LookupFromTable_Str_2
	cp hl, 0:i3
	jr z, MidiPart_CopyParamStr
	ld XWA,MidiPart_LookupFromTable_Str
MidiPart_CopyParamStr:
	push	xwa
	lda	xwa, (xsp+28)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+16)
	ld	xbc, EVT_GRID_DRAW
MidiPart_SendEventReturn:
	call SendEvent

MidiSetup_ReturnZero:
	ld xhl, 0:i3
	pop xiz
	lda xsp, (xsp + 38)
	ret

; =============================================================================
; MidiPart_DataBlock - a panel-event callback (CODE, despite the name)
;
; 7th entry of the callback list UIState_ConfigB_081 (ui_widgets/widget_dispatch.s).
; It reads 0xbfe4 and 0xbfe1-0xbfe3: in v7 these are the type and payload
; bytes of the current panel event, which v9/v10 keep at 0xc080 / 0xc07d-0xc07f
; (where SwbtWr_DispatchLoop stores them: ../technics-docs/data-wheel-
; investigation.md) -- the same routine, with every RAM variable here 0x9c
; lower in v7 (the UI state byte is 0x8c9c here, 0x8d38 in v10).  It acts only
; for type 0xa8 with payload 0xbfe1 == 5, bit 6 of 0xbfe3 set and
; (0xbfe2 & 0xbfe3) != 0: then, unless the UI state byte 0x8c9c is 0x0f, it
; calls SoundCtrl_SendCommand(15).  Which panel control that type/payload is
; has NOT been established.  The name is kept because widget_dispatch.s
; (another lane) refers to it; until 2026-09-25 these bytes were a verbatim
; romslice (includes/romslices/v7_transplant_MidiPart_DataBlock.bin).
; =============================================================================
MidiPart_DataBlock:
	cp	(0xbfe4:16), 0xa8
	ret	nz
	cp	(0xbfe1:16), 5
	ret	nz
	ld	c, (0xbfe3:16)
	bit	6, c
	ret	z
	ld	a, (0xbfe2:16)
	and	a, c
	ret	z
	cp	(0x8c9c:16), 0xf
	ret	z
	ldw	wa, 15
	call	SoundCtrl_SendCommand
	ret
InitializeMurai:
	lda xsp, (xsp - 0x0e)
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Class
	ld (XBC),XWA
	lda xwa, (ClassProc:24)
	ld (XBC+0x04),XWA
	ld wa, (0xe812e2:24)
	ld (XBC+0x08),WA
	lda xwa, (Murai_ClassTable_161:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0161
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResEvent
	ld (XBC),XWA
	lda xwa, (ResEventProc:24)
	ld (XBC+0x04),XWA
	ld wa, (0xe813a4:24)
	ld (XBC+0x08),WA
	lda xwa, (0xe812e4:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x01c1
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResMethod
	ld (XBC),XWA
	lda xwa, (ResMethodProc:24)
	ld (XBC+0x04),XWA
	ld wa, (0xe814f2:24)
	ld (XBC+0x08),WA
	lda xwa, (Naka_Event_Table3:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x01e1
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ApFunction
	ld (XBC),XWA
	lda xwa, (ApFunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x002c
	lda xwa, (Murai_ApFuncTable_121:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0121
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ApFunction
	ld (XBC),XWA
	lda xwa, (ApFunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x002c
	lda xwa, (Murai_ApFuncNameTable_421:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0421
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Function
	ld (XBC),XWA
	lda xwa, (FunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0025
	lda xwa, (0xe814f4:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0101
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Function
	ld (XBC),XWA
	lda xwa, (FunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0025
	lda xwa, (0xe8158c:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0401
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_MainFunction
	ld (XBC),XWA
	lda xwa, (MainFunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0002
	lda xwa, (0xe86638:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0141
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_MainFunction
	ld (XBC),XWA
	lda xwa, (MainFunctionProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0002
	lda xwa, (0xe86644:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0441
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0014
	lda xwa, (0xe85470:24)
	ld (XBC+0x0a),XWA
	ld wa, 2:i3
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0014
	lda xwa, (0xe859f4:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0302
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0054
	lda xwa, (0xe854c4:24)
	ld (XBC+0x0a),XWA
	ld wa, 3:i3
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0054
	lda xwa, (0xe85a8e:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0303
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0004
	lda xwa, (0xe85618:24)
	ld (XBC+0x0a),XWA
	ld wa, 4:i3
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0004
	lda xwa, (0xe85cf0:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0304
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0036
	lda xwa, (0xe8562c:24)
	ld (XBC+0x0a),XWA
	ld wa, 5:i3
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0036
	lda xwa, (0xe85d14:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0305
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0003
	lda xwa, (0xe85708:24)
	ld (XBC+0x0a),XWA
	ld wa, 7:i3
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0003
	lda xwa, (0xe85f0a:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0307
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0004
	lda xwa, (0xe85718:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0008
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0004
	lda xwa, (0xe85f2a:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x0308
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x001d
	lda xwa, (0xe8572c:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x000d
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x001d
	lda xwa, (NakaData_TechniChordStrings:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x030d
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0004
	lda xwa, (0xe857a4:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00a5
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0004
	lda xwa, (0xe8608e:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03a5
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x000f
	lda xwa, (0xe857b8:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00e4
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x000f
	lda xwa, (0xe860b2:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03e4
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x002c
	lda xwa, (0xe857f8:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00ea
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x002c
	lda xwa, (0xe8617e:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03ea
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0025
	lda xwa, (0xe858ac:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00eb
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0025
	lda xwa, (0xe862f2:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03eb
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0018
	lda xwa, (0xe85944:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00ee
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0018
	lda xwa, (0xe863fe:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03ee
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x000b
	lda xwa, (0xe859a8:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00ef
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x000b
	lda xwa, (StrTable_WelcomVersion:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03ef
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_Viewable
	ld (XBC),XWA
	lda xwa, (ViewableProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0006
	lda xwa, (0xe859d8:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x00f0
	call RegisterObjectTable
	lda XBC, (XSP)
	ld XWA,NAKA_CLASS_ResName
	ld (XBC),XWA
	lda xwa, (ResNameProc:24)
	ld (XBC+0x04),XWA
	ldw (XBC+0x08), 0x0006
	lda xwa, (0xe86534:24)
	ld (XBC+0x0a),XWA
	ldw WA, 0x03f0
	call RegisterObjectTable
	pushw 0x0001
	pushw InitializeMurai_Str_MD_SOUND@hi16
	pushw	InitializeMurai_Str_MD_SOUND@lo16
	ld	xwa, 2:i3
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, TITLE_SDMENU
	call	RegisterMode
	pushw	1
	pushw	InitializeMurai_Str_TT_SDMENU@hi16
	pushw	InitializeMurai_Str_TT_SDMENU@lo16
	ld	xwa, 2:i3
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 0x020000
	call	RegisterTitle
	pushw	1
	pushw	InitializeMurai_Str_TT_SDPART@hi16
	pushw	InitializeMurai_Str_TT_SDPART@lo16
	ld	xwa, 3:i3
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 0x030000
	call	RegisterTitle
	pushw	1
	pushw	InitializeMurai_Str_TT_SDMTUNE@hi16
	pushw	InitializeMurai_Str_TT_SDMTUNE@lo16
	ld	xwa, 4:i3
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 0x040000
	call	RegisterTitle
	pushw	1
	pushw	InitializeMurai_Str_TT_SDSCLTYP@hi16
	pushw	InitializeMurai_Str_TT_SDSCLTYP@lo16
	ld	xwa, 5:i3
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 0x050000
	call	RegisterTitle
	pushw	1
	pushw	InitializeMurai_Str_TT_SDLFTHLD@hi16
	pushw	InitializeMurai_Str_TT_SDLFTHLD@lo16
	ld	xwa, 7:i3
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 0x070000
	call	RegisterTitle
	pushw	1
	pushw	InitializeMurai_Str_TT_SDMIXER@hi16
	pushw	InitializeMurai_Str_TT_SDMIXER@lo16
	ld	xwa, 8
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 0x080000
	call	RegisterTitle
	pushw	1
	pushw	InitializeMurai_Str_TT_SDTECD@hi16
	pushw	InitializeMurai_Str_TT_SDTECD@lo16
	ld	xwa, 13
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 0x0d0000
	call	RegisterTitle
	pushw	1
	pushw	InitializeMurai_Str_TT_SQMIXER@hi16
	pushw	InitializeMurai_Str_TT_SQMIXER@lo16
	ld	xwa, 165
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 0xa50000
	call	RegisterTitle
	pushw	1
	pushw	InitializeMurai_Str_TT_DEMOFEATURE@hi16
	pushw	InitializeMurai_Str_TT_DEMOFEATURE@lo16
	ld	xwa, 228
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, NakaData_ExternalBase
	call	RegisterTitle
	pushw	1
	pushw	InitializeMurai_Str_TT_DRAWBAR@hi16
	pushw	InitializeMurai_Str_TT_DRAWBAR@lo16
	ld	xwa, 234
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, Presentation_RootEntry
	call	RegisterTitle
	pushw	1
	pushw	InitializeMurai_Str_TT_ACCORDION@hi16
	pushw	InitializeMurai_Str_TT_ACCORDION@lo16
	ld	xwa, 235
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 0xeb0000
	call	RegisterTitle
	pushw	1
	pushw	InitializeMurai_Str_TT_MESAGE@hi16
	pushw	InitializeMurai_Str_TT_MESAGE@lo16
	ld	xwa, 238
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 0xee0000
	call	RegisterTitle
	pushw	1
	pushw	InitializeMurai_Str_TT_WELCOM@hi16
	pushw	InitializeMurai_Str_TT_WELCOM@lo16
	ld	xwa, 239
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 0xef0000
	call	RegisterTitle
	pushw	1
	pushw	InitializeMurai_Str_TT_SOFTVER@hi16
	pushw	InitializeMurai_Str_TT_SOFTVER@lo16
	ld	xwa, 240
	ld	xbc, NAKA_APFUNC_DefaultFunction
	ld	xde, 0xf00000
	call	RegisterTitle
	lda	xsp, (xsp+14)
	ret
BitmapAccita16:
	cp xbc, EVT_GET_BITMAP_HEIGHT
	jr z, BitmapAccita16_Height
	cp xbc, EVT_GET_BITMAP_WIDTH
	jr z, BitmapAccita16_Width
	cp xbc, EVT_GET_BITMAP_DATA
	jr z, BitmapAccita16_DataPtr
	ld xhl, 0:i3
	ret

BitmapAccita16_DataPtr:
	lda xhl, (Bitmap_Accita16:24)
	ret

BitmapAccita16_Width:
	ld xhl, 0x78
	ret

BitmapAccita16_Height:
	ld xhl, 0x5f
	ret

BitmapAccger16:
	cp xbc, EVT_GET_BITMAP_HEIGHT
	jr z, BitmapAccger16_Height
	cp xbc, EVT_GET_BITMAP_WIDTH
	jr z, BitmapAccger16_Width
	cp xbc, EVT_GET_BITMAP_DATA
	jr z, BitmapAccger16_DataPtr
	ld xhl, 0:i3
	ret

BitmapAccger16_DataPtr:
	lda xhl, (Bitmap_Accger16:24)
	ret

BitmapAccger16_Width:
	ld xhl, 0x78
	ret

BitmapAccger16_Height:
	ld xhl, 0x5f
	ret

BitmapDrawsw:
	cp xbc, EVT_GET_BITMAP_HEIGHT
	jr z, BitmapDrawsw_Height
	cp xbc, EVT_GET_BITMAP_WIDTH
	jr z, BitmapDrawsw_Width
	cp xbc, EVT_GET_BITMAP_DATA
	jr z, BitmapDrawsw_DataPtr
	ld xhl, 0:i3
	ret

BitmapDrawsw_DataPtr:
	lda xhl, (Bitmap_SomeArrows:24)
	ret

BitmapDrawsw_Width:
	ld xhl, 0x126
	ret

BitmapDrawsw_Height:
	ld xhl, 6:i3
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
	cp	xbc, EVT_GET_BITMAP_HEIGHT
	jr	z, BitmapDrawsw_Skip3
	cp	xbc, EVT_GET_BITMAP_WIDTH
	jr	z, BitmapDrawsw_Skip2
	cp	xbc, EVT_GET_BITMAP_DATA
	jr	z, BitmapDrawsw_Skip
	ld	xhl, 0:i3
	ret
BitmapDrawsw_Skip:
	lda	xhl, (BitmapBound_DrawbarSlider1_Start:24)
	ret
BitmapDrawsw_Skip2:
	ld	xhl, 22
	ret
BitmapDrawsw_Skip3:
	ld	xhl, 222
	ret
	cp	xbc, EVT_GET_BITMAP_HEIGHT
	jr	z, BitmapDrawsw_Skip6
	cp	xbc, EVT_GET_BITMAP_WIDTH
	jr	z, BitmapDrawsw_Skip5
	cp	xbc, EVT_GET_BITMAP_DATA
	jr	z, BitmapDrawsw_Skip4
	ld	xhl, 0:i3
	ret
BitmapDrawsw_Skip4:
	lda	xhl, (BitmapBound_DrawbarSlider2_Start:24)
	ret
BitmapDrawsw_Skip5:
	ld	xhl, 22
	ret
BitmapDrawsw_Skip6:
	ld	xhl, 222
	ret
	cp	xbc, EVT_GET_BITMAP_HEIGHT
	jr	z, BitmapDrawsw_Skip9
	cp	xbc, EVT_GET_BITMAP_WIDTH
	jr	z, BitmapDrawsw_Skip8
	cp	xbc, EVT_GET_BITMAP_DATA
	jr	z, BitmapDrawsw_Skip7
	ld	xhl, 0:i3
	ret
BitmapDrawsw_Skip7:
	lda	xhl, (BitmapBound_DrawbarSlider3_Start:24)
	ret
BitmapDrawsw_Skip8:
	ld	xhl, 22
	ret
BitmapDrawsw_Skip9:
	ld	xhl, 222
	ret


BitmapTechnics:
	cp xbc, EVT_GET_BITMAP_HEIGHT
	jr z, BitmapTechnics_Height
	cp xbc, EVT_GET_BITMAP_WIDTH
	jr z, BitmapTechnics_Width
	cp xbc, EVT_GET_BITMAP_DATA
	jr z, BitmapTechnics_DataPtr
	ld xhl, 0:i3
	ret

BitmapTechnics_DataPtr:
	lda xhl, (Bitmap_Technics_Logo:24)
	ret

BitmapTechnics_Width:
	ld xhl, 0x138
	ret

BitmapTechnics_Height:
	ld xhl, 0x2d
	ret


BitmapKn5000:
	cp xbc, EVT_GET_BITMAP_HEIGHT
	jr z, BitmapKn5000_Height
	cp xbc, EVT_GET_BITMAP_WIDTH
	jr z, BitmapKn5000_Width
	cp xbc, EVT_GET_BITMAP_DATA
	jr z, BitmapKn5000_DataPtr
	ld xhl, 0:i3
	ret

BitmapKn5000_DataPtr:
	lda xhl, (Bitmap_KN5000_Logo:24)
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

	ld bc, 0:i3

	call DkMdlyPly_CheckState_Helper

	ld (xsp + 5), l

	ld wa, iz

	ldw bc, 0x20

	call DkMdlyPly_CheckState_Helper

	lda xwa, (xsp + 2)

	ld (xwa + 4), l

	ldto_berp C, 0xf8

	ld (xwa + 2), c

	call	SndParam_FetchOscTableEntry

	lda xbc, (xsp + 2)

	ld e, (xbc + 1)

	extz de

	ld a, (xbc)

	extz wa

	sll wa, 8

	add wa, de

	ld bc, wa

	extz xbc

	sll xbc, 16

	ld hl, iz

	extz xhl

	add xhl, xbc

	popw iz

	inc 6, xsp

	ret



TtSdmenu:
	push xiz
	cp xbc, EVT_REPAINT
	jr z, TtSdmenu_ReturnZero
	cp xbc, EVT_PAINT
	jr z, TtSdmenu_ReturnZero
	cp xbc, EVT_HIDE
	jr z, TtSdmenu_ReturnZero
	cp xbc, EVT_SHOW
	jr nz, TtSdmenu_ReturnZero
	or xde, xde
	jr nz, TtSdmenu_ReturnZero
	call GetModeOld
	ld xiz, xhl
	call GetModeNow
	cp xhl, xiz
	jr z, TtSdmenu_ReturnZero
	ld xwa, 0x20001
	ld xbc, EVT_SET_PAGE
	ld xde, 1:i3
	call SendEvent

TtSdmenu_ReturnZero:
	ld xhl, 0:i3
	pop xiz
	ret

AcSndEMenuProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld xiz, xwa
	ld xwa, (xsp + 8)
	cp xwa, EVT_SW_IN
	jr z, AcSndEMenu_CheckModified
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	jr AcSndEMenu_CallInherited

AcSndEMenu_CheckModified:
	ld	xwa, xiz
	ld	xbc, EVT_CHECK_EDIT_SW
	ld	xde, (xsp+4)
	call	SendEvent
	cp	hl, 0:i3
	jr	z, AcSndEMenu_ForwardInherited
	ld	xwa, 192
	call	AcApcToggleProc_Helper
	cp	hl, 0:i3
	jr	z, AcSndEMenu_ForwardInherited
	ld	xhl, 0:i3
	jr	AcSndEMenu_Epilogue
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
	cp xbc, EVT_GET_SMALL_STEP
	jr z, IvSdpart_TtlCase2
	cp xbc, EVT_GET_LARGE_STEP
	jr z, IvSdpart_TtlCase2
	cp xbc, EVT_GET_LSW_OUTPUT
	jr z, IvSdpart_TtlCase1
	cp xbc, EVT_GET_LSW_ADDRESS
	jr z, IvSdpart_TtlCase0
	cp xbc, EVT_GET_LSW_STRING
	jr z, LswLeftHold_Case42
	ld xhl, 0:i3
	jr LswLeftHold_PopIzRet

LswLeftHold_Case42:
	ld bc, (xde + 4)
	ld xwa, (xde + 8)
	cp bc, 0:i3
	jr lt, LswLeftHold_DefaultStr
	cp bc, 1:i3
	jr gt, LswLeftHold_DefaultStr
	sla bc, 2
	lda xde, (0x03e91c:24)
	ld	xbc, (xde+bc)
	push xbc
	jr LswLeftHold_CopyAndReturn

LswLeftHold_DefaultStr:
	pushw 0xe9
	pushw 0x52a6

LswLeftHold_CopyAndReturn:
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, xiz
	jr	LswLeftHold_PopIzRet
IvSdpart_TtlCase0:
	ld xhl, 0x28082
	jr LswLeftHold_PopIzRet

; IvSdpartProc title case 1
IvSdpart_TtlCase1:
	ld xhl, 4:i3
	jr LswLeftHold_PopIzRet

; IvSdpartProc title case 2
IvSdpart_TtlCase2:
	ld xhl, 1:i3

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
	cp xiz, EVT_GET_STRING
	jrl z, IvSdpart_GetText
	cp xiz, EVT_DRAW
	jrl z, IvSdpart_Paint
	cp xiz, EVT_PART_SELECT
	jrl z, IvSdpart_Refresh
	cp xiz, EVT_I_AM_SELECTED
	jrl z, IvSdpart_PageSelect
	cp xiz, EVT_SW_IN
	jrl z, IvSdpart_OK
	cp xiz, EVT_REPAINT
	jrl z, IvSdpart_ShowHide
	cp xiz, EVT_PAINT
	jrl z, IvSdpart_ShowHide
	cp xiz, EVT_HIDE
	jrl z, IvSdpart_Close
	cp xiz, EVT_SHOW
	jr z, IvSdpart_Init
	sub xwa, EVT_INDEXSW_UP
	cp xwa, 0x0
	jrl lt, IvSdpart_ForwardToBase
	cp xwa, 0x9
	jrl gt, IvSdpart_ForwardToBase
	add xwa, xwa
	add xwa, Str_PartName_Right1_0x10
	ld wa, (xwa)
	lda xix, (IvSdpart_Init:24)
; Computed jump: target = IvSdpart_Init + Str_PartName_Right1_0x10[i], Str_PartName_Right1_0x10 = 16-bit offsets (10 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1c00017:
;   0x1c00017 -> IvSdpartProc_Evt1C00017
;   0x1c00018 -> IvSdpartProc_Evt1C00017
;   0x1c00019 -> IvSdpartProc_Evt1C00017
;   0x1c0001a -> IvSdpartProc_Evt1C00017
;   0x1c0001b -> IvSdpart_ForwardToBase
;   0x1c0001c -> IvSdpartProc_Evt1C0001C
;   0x1c0001d -> IvSdpart_ForwardToBase
;   0x1c0001e -> IvSdpart_ForwardToBase
;   0x1c0001f -> IvSdpart_ForwardToBase
;   0x1c00020 -> IvSdpartProc_Evt1C00020
	jp	t, (xix+wa)

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
	ldw (0x03e99c:24), 0x0008
	ldw (0x03e99e:24), 0x0000
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEX_SELECT
	ld xde, 0x8
	call SendEvent

IvSdpart_Init_LoadDescriptor:
	ld wa, (0x03e99c:24)
	sla wa, 2
	lda xbc, (MixerPartTable_Start_0x108:24)
	ld	xwa, (xbc+wa)
	ld xbc, EVT_SHOW
	ld xde, 0:i3
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
	ld xwa, NAKA_MAINFUNC_MainPmanControl
	ld xbc, EVT_PART_SELECT_PUT
	ld xde, 0x3f
	call MainFuncCall
	jrl IvSdpart_ReturnHandled

IvSdpart_ShowHide:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	cpw (0x3e99e:24), 18
	jr ge, IvSdpart_ShowHide_UpdateUI
	call GetPartSelect
	ld xwa, MixerPartTable_Start_0x12C
	ld bc, hl
	calr SdpartLookupPartId
	ld de, hl
	cp de, 0xffff
	jr z, IvSdpart_ShowHide_UpdateUI
	ld (0x03e99e:24), de

IvSdpart_ShowHide_UpdateUI:
	calr SdpartUpdatePartUI
	ld wa, (0x03e99e:24)
	sla wa, 2
	lda xbc, (0x03e924:24)
	ld	xde, (xbc+wa)
	ld xwa, 0x3000b
	ld xbc, EVT_PARA_DRAW
	jrl IvSdpart_DispatchEvent

IvSdpart_OK:
	ld xwa, (xsp + 4)
	cp xwa, 0xf
	jr nz, IvSdpart_OK_Forward
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_IS_INTERRUPT
	ld xde, 0:i3
	call SendEvent
	or xhl, xhl
	jr nz, IvSdpart_OK_Forward
	ld wa, (0x03e99c:24)
	cp wa, 0x8
	jr z, IvSdpart_OK_ExitToMenu
	sla wa, 2
	lda xbc, (MixerPartTable_Start_0x108:24)
	ld	xwa, (xbc+wa)
	ld xbc, EVT_HIDE
	ld xde, 5:i3
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEX_SELECT
	ld xde, 0x8
	call SendEvent
	ldw (0x03e99c:24), 0x0008
	ld xwa, (MixerPartTable_Start_0x128:24)
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	jrl IvSdpart_DispatchEvent

IvSdpart_OK_ExitToMenu:
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_TITLE
	ld xde, TITLE_SDMENU
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
	srl xwa, 16
	ldiw_erp 0xe2, 0
	cp wa, 0x8
	jrl nz, IvSdpart_ReturnHandled
	ld xwa, (xsp + 4)
	ld iz, wa
	ld wa, (0x03e99c:24)
	cp iz, wa
	jrl z, IvSdpart_ReturnHandled
	cp iz, 0xffff
	jrl z, IvSdpart_ReturnHandled
	sla wa, 2
	lda xbc, (MixerPartTable_Start_0x108:24)
	ld	xwa, (xbc+wa)
	ld xbc, EVT_HIDE
	ld xde, 5:i3
	call SendEvent
	ld (0x03e99c:24), iz
	ld wa, iz
	sla wa, 2
	lda xbc, (MixerPartTable_Start_0x108:24)
	ld	xwa, (xbc+wa)
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	call SendEvent
	call SetAutoIncDefault
	jrl IvSdpart_ReturnHandled
IvSdpartProc_Evt1C00017:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 4)
	cp xwa, 0x9
	jrl nz, IvSdpart_ReturnHandled
	ld xwa, xiz
	ld bc, 1:i3
	ld de, 1:i3
	calr SdpartScrollDelta
	cp hl, 0:i3
	jrl z, IvSdpart_ReturnHandled
	ld wa, (0x03e99e:24)
	ld bc, wa
	add bc, hl
	jrl lt, IvSdpart_ReturnHandled
	cp bc, 0x17
	jrl gt, IvSdpart_ReturnHandled
	add wa, hl
	ld (0x03e99e:24), wa
	calr SdpartUpdatePartUI
	ld wa, (0x03e99e:24)
	sla wa, 2
	lda xbc, (0x03e924:24)
	ld	xde, (xbc+wa)
	ld xwa, 0x3000b
	ld xbc, EVT_PARA_DRAW
	call SendEvent
	ld wa, (0x03e99e:24)
	sla wa, 1
	lda xbc, (MixerPartTable_Start_0x12C:24)
	ld	de, (xbc+wa)
	exts xde
	ld xwa, NAKA_MAINFUNC_MainPmanControl
	ld xbc, EVT_PART_SELECT_PUT
	call MainFuncCall
	ld wa, (0x03e99c:24)
	sla wa, 2
	lda xbc, (MixerPartTable_Start_0x108:24)
	ld	xwa, (xbc+wa)
	ld xbc, EVT_PAINT
	ld xde, 0:i3
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
	cpw (0x3e99e:24), 18
	jrl ge, IvSdpart_ReturnHandled
	call GetPartSelect
	ld xwa, MixerPartTable_Start_0x12C
	ld bc, hl
	calr SdpartLookupPartId
	ld de, hl
	cp de, 0xffff
	jrl z, IvSdpart_ReturnHandled
	cp (0x3e99e:24), de
	jrl z, IvSdpart_ReturnHandled
	ld (0x03e99e:24), de
	calr SdpartUpdatePartUI
	ld wa, (0x03e99e:24)
	sla wa, 2
	lda xbc, (0x03e924:24)
	ld	xde, (xbc+wa)
	ld xwa, 0x3000b
	ld xbc, EVT_PARA_DRAW
	call SendEvent
	ld wa, (0x03e99c:24)
	sla wa, 2
	lda xbc, (MixerPartTable_Start_0x108:24)
	ld	xwa, (xbc+wa)
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	jrl IvSdpart_DispatchEvent
IvSdpartProc_Evt1C0001C:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld wa, (0x03e99e:24)
	sla wa, 1
	lda xbc, (MixerPartTable_Start_0x12C:24)
	ld	de, (xbc+wa)
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
	ld xwa, NAKA_MAINFUNC_MainGetSoundName
	ld xbc, EVT_GET_SOUND_NAME
	call FuncCall
	jr IvSdpart_ReturnHandled
IvSdpartProc_Evt1C00020:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld wa, (0x03e99e:24)
	sla wa, 1
	lda xbc, (MixerPartTable_Start_0x12C:24)
	ld	bc, (xbc+wa)
	ld xwa, (xsp + 4)
	cp bc, (xwa)
	jr nz, IvSdpart_ReturnHandled
	ld xde, (xwa + 2)
	ld xwa, 0x3000a
	ld xbc, EVT_PARA_DRAW
	jr IvSdpart_DispatchEvent

IvSdpart_Paint:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 8)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3

IvSdpart_DispatchEvent:
	call SendEvent
	jr IvSdpart_ReturnHandled

IvSdpart_GetText:
	pushw	233
	pushw	21834
	ld	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
IvSdpart_ReturnHandled:
	ld xhl, 0:i3
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
	cp xiz, EVT_INDEXSW_BOTH
	jrl z, AcLswPartEdit_Snap
	cp xiz, EVT_INDEXSW_DOWN
	jrl z, AcLswPartEdit_ScrollDown
	cp xiz, EVT_INDEXSW_DOWN_AIC
	jrl z, AcLswPartEdit_AutoIncDown
	cp xiz, EVT_INDEXSW_UP
	jrl z, AcLswPartEdit_ScrollUp
	cp xiz, EVT_INDEXSW_UP_AIC
	jrl z, AcLswPartEdit_AutoIncUp
	cp xiz, EVT_LSW_DATA
	jrl z, AcLswPartEdit_Match
	cp xiz, EVT_DRAW
	jrl z, AcLswPartEdit_Paint
	cp xiz, EVT_REPAINT
	jrl z, AcLswPartEdit_ShowHide
	cp xiz, EVT_PAINT
	jrl z, AcLswPartEdit_ShowHide
	cp xiz, EVT_CALC_PARAM
	jrl z, AcLswPartEdit_AddDelta
	cp xiz, EVT_SET_PARAM
	jr z, AcLswPartEdit_SetValue
	cp xiz, EVT_GET_STRING
	jrl nz, AcLswPartEdit_ForwardToBase
	ld xwa, (xsp + 28)
	call GetViewInstance
	ld xiz, xhl
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xiz + 50)
	ld xbc, EVT_GET_PART
	call ApFuncCall
	ld (xsp + 22), hl
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xiz + 50)
	ld xbc, EVT_GET_LSW_DATA_NO
	call ApFuncCall
	ld (xsp + 20), hl
	ld bc, (xsp + 20)
	extz xbc
	ld wa, (0x03e99e:24)
	extz xwa
	sll xwa, 16
	add xwa, xbc
	lda xde, (xsp + 8)
	ld (xde), xwa
	ld xwa, (xiz + 54)
	ld wa, (xwa)
	ld (xde + 4), wa
	ld xwa, (xsp + 24)
	ld (xde + 8), xwa
	ld xwa, (xiz + 50)
	ld xbc, EVT_GET_LSW_STRING
	call ApFuncCall
	jrl AcLswPartEdit_ReturnHandled

AcLswPartEdit_SetValue:
	ld xwa, (xsp + 28)
	call GetViewInstance
	ld xiz, xhl
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xiz + 50)
	ld xbc, EVT_CHECK_PART
	call ApFuncCall
	or xhl, xhl
	jrl z, AcLswPartEdit_ReturnHandled
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xiz + 50)
	ld xbc, EVT_GET_PART
	call ApFuncCall
	ld (xsp + 22), hl
	ld xwa, (xsp + 24)
	ld (xsp + 4), wa
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xiz + 50)
	ld xbc, EVT_GET_LSW_OUTPUT
	call ApFuncCall
	ld (xsp + 6), hl
	ld bc, (xsp + 22)
	lda xwa, (xiz + 50)
	cp bc, 0xffff
	jr z, AcLswPartEdit_SetValue_Unbounded
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xwa)
	ld xbc, EVT_GET_LSW_DATA_NO
	call ApFuncCall
	ld (xsp + 20), hl
	pushw	(xsp+6)
	ld wa, (xsp + 24)
	ld bc, (xsp + 22)
	ld de, (xsp + 6)
	call MainLswPartPut
	jrl AcLswPartEdit_ReturnHandled

AcLswPartEdit_SetValue_Unbounded:
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xwa)
	ld xbc, EVT_GET_LSW_DATA_NO
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
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xiz + 50)
	ld xbc, EVT_CHECK_PART
	call ApFuncCall
	or xhl, xhl
	jrl z, AcLswPartEdit_ReturnHandled
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xiz + 50)
	ld xbc, EVT_GET_PART
	call ApFuncCall
	ld (xsp + 22), hl
	ld xwa, (xsp + 24)
	ld (xsp + 4), wa
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xiz + 50)
	ld xbc, EVT_GET_LSW_OUTPUT
	call ApFuncCall
	ld (xsp + 6), hl
	ld bc, (xsp + 22)
	ld de, (0x03e99e:24)
	exts xde
	lda xwa, (xiz + 50)
	cp bc, 0xffff
	jr z, AcLswPartEdit_AddDelta_Unbounded
	ld xwa, (xwa)
	ld xbc, EVT_GET_LSW_DATA_NO
	call ApFuncCall
	ld (xsp + 20), hl
	pushw	(xsp+6)
	ld wa, (xsp + 24)
	ld bc, (xsp + 22)
	ld de, (xsp + 6)
	call MainLswPartAdd
	jrl AcLswPartEdit_ReturnHandled

AcLswPartEdit_AddDelta_Unbounded:
	ld xwa, (xwa)
	ld xbc, EVT_GET_LSW_DATA_NO
	call ApFuncCall
	ld xwa, xhl
	ld bc, (xsp + 4)
	ld de, (xsp + 6)
	call MainLswAdd
	jrl AcLswPartEdit_ReturnHandled

AcLswPartEdit_ShowHide:
	ld	xwa, (xsp+28)
	call	GetViewInstance
	ld	(xsp+4), xhl
	ld	de, (256414:24)
	exts	xde
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+50)
	ld	xbc, EVT_GET_PART
	call	ApFuncCall
	ld	(xsp+22), hl
	ld	bc, (xsp+22)
	ld	de, (256414:24)
	exts	xde
	ld	xwa, (xsp+4)
	lda	xwa, (xwa+50)
	cp	bc, 65535
	jr	z, AcLswPartEdit_ShowHide_Unbounded
	ld	xwa, (xwa)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	(xsp+20), hl
	ld	wa, (xsp+22)
	ld	bc, (xsp+20)
	call	DkMdlyPly_CheckState_Helper
	jr	AcLswPartEdit_ShowHide_StoreAndForward
AcLswPartEdit_ShowHide_Unbounded:
	ld	xwa, (xwa)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	xwa, xhl
	call	AcApcToggleProc_Helper
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
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl AcLswPartEdit_DispatchEvent

AcLswPartEdit_Match:
	ld	xwa, (xsp+28)
	ld	xbc, xiz
	ld	xde, (xsp+24)
	call	InheritedProc
	ld	xwa, (xsp+28)
	call	GetViewInstance
	ld	xiz, xhl
	ld	(xsp+4), xiz
	lda	xbc, (xsp+22)
	lda	xde, (xsp+20)
	ld	xwa, (xsp+24)
	call	SndParam_ResolveOscEntry_Helper
	ld	xwa, (xiz+50)
	cp	hl, 65535
	jr	z, AcLswPartEdit_Match_Unbounded
	ld	de, (256414:24)
	exts	xde
	ld	xbc, EVT_GET_PART
	call	ApFuncCall
	ld	wa, (xsp+22)
	extz	xwa
	cp	xwa, xhl
	jrl	nz, AcLswPartEdit_ReturnHandled
	ld	de, (256414:24)
	exts	xde
	ld	xwa, (xiz+50)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	wa, (xsp+20)
	extz	xwa
	cp	xwa, xhl
	jrl	nz, AcLswPartEdit_ReturnHandled
	lda	xde, (xiz+54)
	ld	xbc, (xde)
	ld	xwa, (xsp+24)
	ld	wa, (xwa+4)
	ld	(xbc), wa
	ld	xwa, (xde)
	ld	de, (xwa)
	exts	xde
	ld	xwa, (xiz+50)
	ld	xbc, EVT_LSW_DATA_REQ
	call	ApFuncCall
	ld	xwa, (xsp+28)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 0:i3
	jrl	AcLswPartEdit_DispatchEvent
AcLswPartEdit_Match_Unbounded:
	ld de, (0x03e99e:24)
	exts xde
	ld xbc, EVT_GET_LSW_DATA_NO
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
	ld xbc, EVT_LSW_DATA_REQ
	call ApFuncCall
	ld xwa, (xsp + 28)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl AcLswPartEdit_DispatchEvent

AcLswPartEdit_AutoIncUp:
	ld xwa, (xsp + 28)
	ld xbc, xiz
	ld xde, (xsp + 24)
	call InheritedProc
	ld xwa, (xsp + 28)
	ld xbc, EVT_CHECK_SELECTED
	ld xde, (xsp + 24)
	call SendEvent
	or xhl, xhl
	jrl z, AcLswPartEdit_ReturnHandled
	ld xwa, (xsp + 28)
	call GetViewInstance
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xhl + 50)
	ld xbc, EVT_GET_LARGE_STEP
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 28)
	ld xbc, EVT_CALC_PARAM
	jrl AcLswPartEdit_DispatchEvent

AcLswPartEdit_ScrollUp:
	ld xwa, (xsp + 28)
	ld xbc, xiz
	ld xde, (xsp + 24)
	call InheritedProc
	ld xwa, (xsp + 28)
	ld xbc, EVT_CHECK_SELECTED
	ld xde, (xsp + 24)
	call SendEvent
	or xhl, xhl
	jrl z, AcLswPartEdit_ReturnHandled
	ld xwa, (xsp + 28)
	call GetViewInstance
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xhl + 50)
	ld xbc, EVT_GET_SMALL_STEP
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 28)
	ld xbc, EVT_CALC_PARAM
	jrl AcLswPartEdit_DispatchEvent

AcLswPartEdit_AutoIncDown:
	ld xwa, (xsp + 28)
	ld xbc, xiz
	ld xde, (xsp + 24)
	call InheritedProc
	ld xwa, (xsp + 28)
	ld xbc, EVT_CHECK_SELECTED
	ld xde, (xsp + 24)
	call SendEvent
	or xhl, xhl
	jrl z, AcLswPartEdit_ReturnHandled
	ld xwa, (xsp + 28)
	call GetViewInstance
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xhl + 50)
	ld xbc, EVT_GET_LARGE_STEP
	call ApFuncCall
	cpl hl
	cplw_erp 0xee
	inc 1, xhl
	ld xwa, (xsp + 28)
	ld xbc, EVT_CALC_PARAM
	ld xde, xhl
	jrl AcLswPartEdit_DispatchEvent

AcLswPartEdit_ScrollDown:
	ld xwa, (xsp + 28)
	ld xbc, xiz
	ld xde, (xsp + 24)
	call InheritedProc
	ld xwa, (xsp + 28)
	ld xbc, EVT_CHECK_SELECTED
	ld xde, (xsp + 24)
	call SendEvent
	or xhl, xhl
	jrl z, AcLswPartEdit_ReturnHandled
	ld xwa, (xsp + 28)
	call GetViewInstance
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xhl + 50)
	ld xbc, EVT_GET_SMALL_STEP
	call ApFuncCall
	cpl hl
	cplw_erp 0xee
	inc 1, xhl
	ld xwa, (xsp + 28)
	ld xbc, EVT_CALC_PARAM
	ld xde, xhl
	jr AcLswPartEdit_DispatchEvent

AcLswPartEdit_Snap:
	ld xwa, (xsp + 28)
	ld xbc, xiz
	ld xde, (xsp + 24)
	call InheritedProc
	ld xwa, (xsp + 28)
	ld xbc, EVT_CHECK_SELECTED
	ld xde, (xsp + 24)
	call SendEvent
	or xhl, xhl
	jr z, AcLswPartEdit_ReturnHandled
	ld xwa, (xsp + 28)
	call GetViewInstance
	ld xiz, xhl
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xiz + 50)
	ld xbc, EVT_CHECK_INIT_DATA
	call ApFuncCall
	or xhl, xhl
	jr z, AcLswPartEdit_ReturnHandled
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xiz + 50)
	ld xbc, EVT_GET_INIT_DATA
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 28)
	ld xbc, EVT_SET_PARAM

AcLswPartEdit_DispatchEvent:
	call SendEvent

AcLswPartEdit_ReturnHandled:
	ld xhl, 0:i3
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
	cp xwa, EVT_INDEXSW_BOTH
	jrl z, AudioCtrl_GetToggleState
	cp xwa, EVT_INDEXSW_DOWN
	jrl z, AudioCtrl_GetNegMax
	cp xwa, EVT_INDEXSW_DOWN_AIC
	jrl z, AudioCtrl_GetNegMin
	cp xwa, EVT_INDEXSW_UP
	jrl z, AudioCtrl_GetMaxLimit
	cp xwa, EVT_INDEXSW_UP_AIC
	jrl z, AudioCtrl_GetMinLimit
	cp xwa, EVT_LSW_DATA
	jrl z, AudioCtrl_MidiMatchHandler
	cp xwa, EVT_DRAW
	jrl z, AudioCtrl_InheritAndConfirm
	cp xwa, EVT_REPAINT
	jrl z, AudioCtrl_InitPartSelection
	cp xwa, EVT_PAINT
	jrl z, AudioCtrl_InitPartSelection
	cp xwa, EVT_CALC_PARAM
	jrl z, AudioCtrl_DualPartNavigate
	cp xwa, EVT_SET_PARAM
	jr z, AudioCtrl_InitPartPanDisplay
	cp xwa, EVT_GET_STRING
	jrl nz, AudioCtrl_ForwardInherited
	ld xwa, (xsp + 38)
	call GetViewInstance
	ld (xsp + 10), xhl
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 50)
	ld xbc, EVT_GET_PART
	call ApFuncCall
	ld (xsp + 28), hl
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 50)
	ld xbc, EVT_GET_LSW_DATA_NO
	call ApFuncCall
	ld (xsp + 26), hl
	ld bc, (xsp + 26)
	extz xbc
	ld wa, (0x03e99e:24)
	extz xwa
	sll xwa, 16
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
	ld xbc, EVT_GET_LSW_STRING
	call ApFuncCall
	jrl AudioCtrl_ReturnZeroEpilogue

AudioCtrl_InitPartPanDisplay:
	ld xwa, (xsp + 38)
	call GetViewInstance
	ld (xsp + 8), xhl
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)
	ld xbc, EVT_GET_PART
	call ApFuncCall
	ld (xsp + 28), hl
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)
	ld xbc, EVT_GET_LSW_OUTPUT
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
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xbc)
	ld xbc, EVT_GET_LSW_DATA_NO
	call ApFuncCall
	ld (xsp + 26), hl
	pushw	(xsp+6)
	ld wa, (xsp + 30)
	ld bc, (xsp + 28)
	ld de, (xsp + 14)
	jrl AudioCtrl_CallMainLswPartPut

AudioCtrl_UnboundedPart:
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xbc)
	ld xbc, EVT_GET_LSW_DATA_NO
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
	ld de, (0x03e99e:24)
	exts xde
	ld xbc, EVT_GET_LSW_DATA_NO
	call ApFuncCall
	ld (xsp + 26), hl
	pushw	(xsp+6)
	ld wa, (xsp + 30)
	ld bc, (xsp + 28)
	ld de, (xsp + 6)
	call MainLswPartPut
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 54)
	ld xbc, EVT_GET_LSW_DATA_NO
	call ApFuncCall
	ld (xsp + 26), hl
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 54)
	ld xbc, EVT_GET_LSW_OUTPUT
	call ApFuncCall
	ld (xsp + 6), hl
	pushw	(xsp+6)
	ld wa, (xsp + 30)
	ld bc, (xsp + 28)
	ld de, 1:i3

AudioCtrl_CallMainLswPartPut:
	call MainLswPartPut
	jrl AudioCtrl_ReturnZeroEpilogue

AudioCtrl_HighPartUnbounded:
	ld de, (0x03e99e:24)
	exts xde
	ld xbc, EVT_GET_LSW_DATA_NO
	call ApFuncCall
	ld xiz, xhl
	ld xwa, xiz
	ld bc, (xsp + 4)
	ld de, (xsp + 6)
	call MainLswPut
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 54)
	ld xbc, EVT_GET_LSW_DATA_NO
	call ApFuncCall
	ld xiz, xhl
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 54)
	ld xbc, EVT_GET_LSW_OUTPUT
	call ApFuncCall
	ld (xsp + 6), hl
	ld xwa, xiz
	ld bc, 1:i3
	ld de, (xsp + 6)
	jrl AudioCtrl_CallMainLswPut

AudioCtrl_DualPartNavigate:
	ld xwa, (xsp + 38)
	call GetViewInstance
	ld (xsp + 10), xhl
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 50)
	ld xbc, EVT_GET_PART
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
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xhl)
	ld xbc, EVT_GET_LSW_DATA_NO
	call ApFuncCall
	ld (xsp + 26), hl
	ld xwa, (xsp + 30)
	ld (xsp + 4), wa
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 50)
	ld xbc, EVT_GET_LSW_OUTPUT
	call ApFuncCall
	ld (xsp + 6), hl
	pushw	(xsp+6)
	ld wa, (xsp + 30)
	ld bc, (xsp + 28)
	ld de, (xsp + 6)
	call MainLswPartAdd
	jrl AudioCtrl_ReturnZeroEpilogue

AudioCtrl_DualPartHighOffset:
	ld de, (0x03e99e:24)
	exts xde
	ld xbc, EVT_GET_LSW_DATA_NO
	call ApFuncCall
	ld (xsp + 26), hl
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 54)
	ld xbc, EVT_GET_LSW_OUTPUT
	call ApFuncCall
	ld (xsp + 6), hl
	pushw	(xsp+6)
	ld wa, (xsp + 30)
	ld bc, (xsp + 28)
	ld de, 0:i3
	call MainLswPartPut
	jrl AudioCtrl_ReturnZeroEpilogue

AudioCtrl_DualPartUnbounded:
	ld xbc, (xbc)
	ld de, (0x03e99e:24)
	exts xde
	cpw (xbc), 0x80
	jr ge, AudioCtrl_DualPartResolve
	ld xwa, (xhl)
	ld xbc, EVT_GET_LSW_DATA_NO
	call ApFuncCall
	ld xiz, xhl
	ld xwa, (xsp + 30)
	ld (xsp + 4), wa
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 50)
	ld xbc, EVT_GET_LSW_OUTPUT
	call ApFuncCall
	ld (xsp + 6), hl
	ld xwa, xiz
	ld bc, (xsp + 4)
	ld de, (xsp + 6)
	call MainLswAdd
	jrl AudioCtrl_ReturnZeroEpilogue

AudioCtrl_DualPartResolve:
	ld xbc, EVT_GET_LSW_DATA_NO
	call ApFuncCall
	ld xiz, xhl
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 54)
	ld xbc, EVT_GET_LSW_OUTPUT
	call ApFuncCall
	ld (xsp + 6), hl
	ld xwa, xiz
	ld bc, 0:i3
	ld de, (xsp + 6)

AudioCtrl_CallMainLswPut:
	call MainLswPut
	jrl AudioCtrl_ReturnZeroEpilogue

AudioCtrl_InitPartSelection:
	ld	xwa, (xsp+38)
	call	GetViewInstance
	ld	(xsp+10), xhl
	ld	xwa, (xsp+10)
	ld	(xsp+6), xwa
	ld	de, (256414:24)
	exts	xde
	ld	xwa, (xwa+50)
	ld	xbc, EVT_GET_PART
	call	ApFuncCall
	ld	(xsp+28), hl
	ld	bc, (xsp+28)
	ld	de, (256414:24)
	exts	xde
	ld	xwa, (xsp+10)
	lda	xwa, (xwa+50)
	cp	bc, 65535
	jr	z, AudioCtrl_UnboundedPartSel
	ld	xwa, (xwa)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	(xsp+26), hl
	ld	wa, (xsp+28)
	ld	bc, (xsp+26)
	call	DkMdlyPly_CheckState_Helper
	ld	xbc, (xsp+10)
	ld	xwa, (xbc+58)
	ld	(xwa), hl
	ld	de, (256414:24)
	exts	xde
	ld	xwa, (xbc+54)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	(xsp+26), hl
	ld	wa, (xsp+28)
	ld	bc, (xsp+26)
	call	DkMdlyPly_CheckState_Helper
	jr	AudioCtrl_MergeAndForward
AudioCtrl_UnboundedPartSel:
	ld	xwa, (xwa)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	xiz, xhl
	ld	xwa, xiz
	call	AcApcToggleProc_Helper
	ld	xwa, (xsp+10)
	ld	xwa, (xwa+58)
	ld	(xwa), hl
	ld	de, (256414:24)
	exts	xde
	ld	xwa, (xsp+6)
	ld	xwa, (xwa+54)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	xiz, xhl
	ld	xwa, xiz
	call	AcApcToggleProc_Helper
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
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl AudioCtrl_SendEventThenReturn

AudioCtrl_MidiMatchHandler:
	ld XWA,(XSP+0x26)
	ld XBC,(XSP+0x22)
	ld XDE,(XSP+0x1e)
	call InheritedProc
	ld XWA,(XSP+0x26)
	call GetViewInstance
	ld (XSP+0x0a),XHL
	lda xbc, (xsp + 0x1c)
	lda xde, (xsp + 0x1a)
	ld XWA,(XSP+0x1e)
	call SndParam_ResolveOscEntry_Helper
	ld XWA,(XSP+0x0a)
	lda xwa, (xwa + 0x32)
	cp HL,0xffff
	jrl z, AudioCtrl_UnboundedMatch
	ld de, (0x03e99e:24)
	exts XDE
	ld XWA,(XWA)
	ld XBC,EVT_GET_PART
	call ApFuncCall
	ld WA,(XSP+0x1c)
	extz XWA
	cp XWA,XHL
	jrl nz, AudioCtrl_ReturnZeroEpilogue
	ld de, (0x03e99e:24)
	exts XDE
	ld XWA,(XSP+0x0a)
	ld XWA,(XWA+0x32)
	ld XBC,EVT_GET_LSW_DATA_NO
	call ApFuncCall
	cp HL,(XSP+0x1a)
	jr nz, AudioCtrl_CheckSecondPart
	ld XWA,(XSP+0x0a)
	ld XBC,(XWA+0x3a)
	ld XWA,(XSP+0x1e)
	lda xde, (xwa + 0x04)
	ld WA,(XBC)
	bit 0x07,WA
	jr z, AudioCtrl_StoreValue
	ld WA,(XDE)
	add WA,0x0080
	ld (XBC),WA
	jr t, AudioCtrl_ConfirmAndReturn
AudioCtrl_StoreValue:
	ld wa, (xde)
	ld (xbc), wa

AudioCtrl_ConfirmAndReturn:
	ld xwa, (xsp + 38)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl AudioCtrl_SendEventThenReturn

AudioCtrl_CheckSecondPart:
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 54)
	ld xbc, EVT_GET_LSW_DATA_NO
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
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl AudioCtrl_SendEventThenReturn

AudioCtrl_UnboundedMatch:
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xwa)
	ld xbc, EVT_GET_LSW_DATA_NO
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
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl AudioCtrl_SendEventThenReturn

AudioCtrl_CheckSecondUnbounded:
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 54)
	ld xbc, EVT_GET_LSW_DATA_NO
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
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl AudioCtrl_SendEventThenReturn

AudioCtrl_GetMinLimit:
	ld xwa, (xsp + 38)
	ld xbc, (xsp + 34)
	ld xde, (xsp + 30)
	call InheritedProc
	ld xwa, (xsp + 38)
	ld xbc, EVT_CHECK_SELECTED
	ld xde, (xsp + 30)
	call SendEvent
	or xhl, xhl
	jrl z, AudioCtrl_ReturnZeroEpilogue
	ld xwa, (xsp + 38)
	call GetViewInstance
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xhl + 50)
	ld xbc, EVT_GET_LARGE_STEP
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 38)
	ld xbc, EVT_CALC_PARAM
	jrl AudioCtrl_SendEventThenReturn

AudioCtrl_GetMaxLimit:
	ld xwa, (xsp + 38)
	ld xbc, (xsp + 34)
	ld xde, (xsp + 30)
	call InheritedProc
	ld xwa, (xsp + 38)
	ld xbc, EVT_CHECK_SELECTED
	ld xde, (xsp + 30)
	call SendEvent
	or xhl, xhl
	jrl z, AudioCtrl_ReturnZeroEpilogue
	ld xwa, (xsp + 38)
	call GetViewInstance
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xhl + 50)
	ld xbc, EVT_GET_SMALL_STEP
	call ApFuncCall
	ld xde, xhl
	ld xwa, (xsp + 38)
	ld xbc, EVT_CALC_PARAM
	jrl AudioCtrl_SendEventThenReturn

AudioCtrl_GetNegMin:
	ld xwa, (xsp + 38)
	ld xbc, (xsp + 34)
	ld xde, (xsp + 30)
	call InheritedProc
	ld xwa, (xsp + 38)
	ld xbc, EVT_CHECK_SELECTED
	ld xde, (xsp + 30)
	call SendEvent
	or xhl, xhl
	jrl z, AudioCtrl_ReturnZeroEpilogue
	ld xwa, (xsp + 38)
	call GetViewInstance
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xhl + 50)
	ld xbc, EVT_GET_LARGE_STEP
	call ApFuncCall
	cpl hl
	cplw_erp 0xee
	inc 1, xhl
	ld xwa, (xsp + 38)
	ld xbc, EVT_CALC_PARAM
	ld xde, xhl
	jrl AudioCtrl_SendEventThenReturn

AudioCtrl_GetNegMax:
	ld xwa, (xsp + 38)
	ld xbc, (xsp + 34)
	ld xde, (xsp + 30)
	call InheritedProc
	ld xwa, (xsp + 38)
	ld xbc, EVT_CHECK_SELECTED
	ld xde, (xsp + 30)
	call SendEvent
	or xhl, xhl
	jr z, AudioCtrl_ReturnZeroEpilogue
	ld xwa, (xsp + 38)
	call GetViewInstance
	ld de, (0x03e99e:24)
	exts xde
	ld xwa, (xhl + 50)
	ld xbc, EVT_GET_SMALL_STEP
	call ApFuncCall
	cpl hl
	cplw_erp 0xee
	inc 1, xhl
	ld xwa, (xsp + 38)
	ld xbc, EVT_CALC_PARAM
	ld xde, xhl
	jr AudioCtrl_SendEventThenReturn

AudioCtrl_GetToggleState:
	ld xwa, (xsp + 38)
	ld xbc, (xsp + 34)
	ld xde, (xsp + 30)
	call InheritedProc
	ld xwa, (xsp + 38)
	ld xbc, EVT_CHECK_SELECTED
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
	ld xbc, EVT_SET_PARAM

AudioCtrl_SendEventThenReturn:
	call SendEvent

AudioCtrl_ReturnZeroEpilogue:
	ld xhl, 0:i3
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
	cp xiz, EVT_LSW_DATA
	jrl z, AcLswPartPan_Match
	cp xiz, EVT_PARA_DRAW
	jrl z, AcLswPartPan_Confirm
	cp xiz, EVT_DRAW
	jrl z, AcLswPartPan_Paint
	cp xiz, EVT_REPAINT
	jr z, AcLswPartPan_ShowHide
	cp xiz, EVT_PAINT
	jr z, AcLswPartPan_ShowHide
	ld xwa, (xsp + 36)
	ld xbc, xiz
	ld xde, (xsp + 32)
	call InheritedProc
	jrl AcLswPartPan_Return

AcLswPartPan_ShowHide:
	ld	xwa, (xsp+36)
	call	GetViewInstance
	ld	(xsp+8), xhl
	ld	de, (256414:24)
	exts	xde
	ld	xwa, (xsp+8)
	ld	xwa, (xwa+28)
	ld	xbc, EVT_GET_PART
	call	ApFuncCall
	ld	(xsp+30), hl
	ld	bc, (xsp+30)
	ld	de, (256414:24)
	exts	xde
	ld	xwa, (xsp+8)
	lda	xwa, (xwa+28)
	cp	bc, 65535
	jr	z, AcLswPartPan_ShowHide_Unbounded
	ld	xwa, (xwa)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	(xsp+28), hl
	ld	wa, (xsp+30)
	ld	bc, (xsp+28)
	call	DkMdlyPly_CheckState_Helper
	jr	AcLswPartPan_ShowHide_StoreAndForward
AcLswPartPan_ShowHide_Unbounded:
	ld	xwa, (xwa)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	xwa, xhl
	call	AcApcToggleProc_Helper
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
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl AcLswPartPan_DispatchEvent

AcLswPartPan_Confirm:
	ld XWA,(XSP+0x24)
	call GetViewInstance
	ld (XSP+0x04),XHL
	lda xbc, (xsp + 0x14)
	ld XWA,(XSP+0x24)
	call GetClientBox
	lda xwa, (xsp + 0x14)
	ld XBC,(XSP+0x04)
	ld BC,(XBC+0x16)
	call DrawBox
	lda xwa, (xsp + 0x10)
	lda xhl, (xsp + 0x14)
	ld BC,(XHL)
	inc 4,BC
	ld (XWA),BC
	lda xbc, (xsp + 0x0c)
	ld DE,(XHL+0x04)
	dec 4,DE
	ld (XBC),DE
	inc 6,XHL
	ld DE,(XHL)
	dec 4,DE
	ld (XWA+0x02),DE
	ld DE,(XHL)
	dec 4,DE
	ld (XBC+0x02),DE
	ld de, 0:i3
	call DrawLine
	lda xde, (xsp + 0x14)
	ld BC,(XDE+0x06)
	ld WA,BC
	sub WA,(XDE+0x02)
	exts XWA
	divs WA,0x0002
	sub BC,WA
	lda xwa, (xsp + 0x10)
	ld (XWA+0x02),BC
	lda xbc, (xsp + 0x0c)
	ld DE,(XDE)
	inc 4,DE
	ld (XBC),DE
	ld (XWA),DE
	ld de, 0:i3
	call DrawLine
	lda xbc, (xsp + 0x0c)
	ld DE,(XSP+0x18)
	dec 4,DE
	ld (XBC),DE
	lda xwa, (xsp + 0x10)
	ld (XWA),DE
	ld de, 0:i3
	call DrawLine
	lda xbc, (xsp + 0x14)
	ld WA,(XBC+0x04)
	sub WA,(XBC)
	exts XWA
	divs WA,0x0002
	ld DE,(XBC)
	add DE,WA
	lda xbc, (xsp + 0x0c)
	ld (XBC),DE
	lda xwa, (xsp + 0x10)
	ld (XWA),DE
	ld de, 0:i3
	call DrawLine
	lda xbc, (xsp + 0x14)
	ld WA,(XBC+0x04)
	sub WA,(XBC)
	exts XWA
	divs WA,0x0004
	ld DE,(XBC)
	add DE,WA
	lda xbc, (xsp + 0x0c)
	ld (XBC),DE
	lda xwa, (xsp + 0x10)
	ld (XWA),DE
	ld de, 0:i3
	call DrawLine
	lda xwa, (xsp + 0x14)
	ld BC,(XWA+0x04)
	ld DE,BC
	sub DE,(XWA)
	exts XDE
	divs DE,0x0004
	ld WA,DE
	ld DE,BC
	sub DE,WA
	lda xbc, (xsp + 0x0c)
	ld (XBC),DE
	lda xwa, (xsp + 0x10)
	ld (XWA),DE
	ld de, 0:i3
	call DrawLine
	ld de, (0x03e99e:24)
	exts XDE
	ld XWA,(XSP+0x04)
	ld XWA,(XWA+0x1c)
	ld XBC,EVT_CHECK_PART
	call ApFuncCall
	or XHL,XHL
	jrl z, AcLswPartPan_ReturnHandled
	lda xiz, (xsp + 0x14)
	lda xwa, (xiz + 0x04)
	ld (XSP+0x08),XWA
	ld WA,(XWA)
	sub WA,(XIZ)
	dec 6,WA
	ld BC,WA
	exts XBC
	ld XWA,(XSP+0x04)
	ld XWA,(XWA+0x20)
	ld WA,(XWA)
	exts XWA
	sla XWA, 0x0c
	call InitializeKubo_Helper
	ld XWA,XHL
	sra XWA, 0x0f
	sra XWA, 16
	and XWA,0x0000007f
	add XWA,XHL
	sra XWA, 0x07
	ld XBC,XWA
	sra XBC, 0x0f
	sra XBC, 16
	and XBC,0x00000fff
	add XBC,XWA
	sra	xbc, 12
	incw	2, (xiz+2)
	add	bc, (xiz)
	inc	2, bc
	ld	(xiz), bc
	inc	4, bc
	ld	xwa, (xsp+8)
	ld	(xwa), bc
	decw	2, (xiz+6)
	ld	xwa, xiz
	ldw	bc, 193
	ldw	de, 10
	call	DrawDesignBox
	jrl	AcLswPartPan_ReturnHandled
AcLswPartPan_Match:
	ld	xwa, (xsp+36)
	ld	xbc, xiz
	ld	xde, (xsp+32)
	call	InheritedProc
	ld	xwa, (xsp+36)
	call	GetViewInstance
	ld	xiz, xhl
	ld	xwa, (xsp+32)
	ld	(xsp+8), xwa
	lda	xbc, (xsp+30)
	lda	xde, (xsp+28)
	ld	xwa, (xsp+32)
	call	SndParam_ResolveOscEntry_Helper
	ld	de, (256414:24)
	exts	xde
	ld	xwa, (xiz+28)
	cp	hl, 65535
	jr	z, AcLswPartPan_Match_Unbounded
	ld	xbc, EVT_GET_PART
	call	ApFuncCall
	ld	wa, (xsp+30)
	extz	xwa
	cp	xwa, xhl
	jr	nz, AcLswPartPan_ReturnHandled
	ld	de, (256414:24)
	exts	xde
	ld	xwa, (xiz+28)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	wa, (xsp+28)
	extz	xwa
	cp	xwa, xhl
	jr	nz, AcLswPartPan_ReturnHandled
	ld	xbc, (xiz+32)
	ld	xwa, (xsp+32)
	ld	wa, (xwa+4)
	ld	(xbc), wa
	ld	xwa, (xsp+36)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 0:i3
	jr	AcLswPartPan_DispatchEvent
AcLswPartPan_Match_Unbounded:
	ld xbc, EVT_GET_LSW_DATA_NO
	call ApFuncCall
	ld xwa, (xsp + 32)
	cp (xwa), xhl
	jr nz, AcLswPartPan_ReturnHandled
	ld xbc, (xiz + 32)
	ld xwa, (xsp + 8)
	ld wa, (xwa + 4)
	ld (xbc), wa
	ld xwa, (xsp + 36)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3

AcLswPartPan_DispatchEvent:
	call SendEvent

AcLswPartPan_ReturnHandled:
	ld xhl, 0:i3

AcLswPartPan_Return:
	pop xiz
	lda xsp, (xsp + 36)
	ret

SdpartLookupPartId:
	ld hl, 0:i3
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
	cp xwa, EVT_INDEXSW_DOWN
	jr z, SdpartScrollDelta_Negate
	cp xwa, EVT_INDEXSW_DOWN_AIC
	jr z, SdpartScrollDelta_Down
	cp xwa, EVT_INDEXSW_UP
	jr z, SdpartScrollDelta_Up
	cp xwa, EVT_INDEXSW_UP_AIC
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
	ld hl, 0:i3
	ret

SdpartUpdatePartUI:
	ld bc, (0x03e99e:24)
	ld wa, bc
	sla wa, 2
	lda xde, (MixerPartTable_Start_0x8:24)
	ld	xwa, (xde+wa)
	bit_erpw 0xe2, 0x0f
	jr z, SdpartUpdatePartUI_Confirm
	add bc, bc
	lda xwa, (MixerPartTable_Start_0x12C:24)
	ld	de, (xwa+bc)
	exts xde
	ld xwa, NAKA_MAINFUNC_MainGetSoundName
	ld xbc, EVT_GET_SOUND_NAME
	jp FuncCall

SdpartUpdatePartUI_Confirm:
	ld xwa, 0x3000a
	ld xbc, EVT_PARA_DRAW
	ld xde, SdpartUpdatePartUI_Confirm_Str_Dash_Dash_Dash_Dash
	jp SendEvent

LswSound:
	push	xiz
	ld	xiz, xwa
	lda	xhl, (MixerPartTable_Start_0x8:24)
	cp	xbc, EVT_LSW_DATA_REQ
	jrl	z, LswSound_ReturnZero
	ld	xix, xde
	sll	xix, 2
	ld	xwa, xhl
	add	xwa, xix
	cp	xbc, EVT_CHECK_PART
	jrl	z, LswSound_GetSignedToggle
	cp	xbc, EVT_GET_SMALL_STEP
	jr	z, LswSound_GetToggle
	cp	xbc, EVT_GET_LARGE_STEP
	jr	z, LswSound_CheckActive
	cp	xbc, EVT_GET_LSW_OUTPUT
	jr	z, LswSound_StepReturn
	cp	xbc, EVT_GET_LSW_DATA_NO
	jrl	z, LswSound_ReturnZero
	cp	xbc, EVT_GET_PART
	jr	z, LswSound_GetPartId
	cp	xbc, EVT_GET_LSW_STRING
	jr	nz, LswSound_ReturnZero
	ld	xwa, (xde)
	srl	xwa, 16
	ld	qwa, 0
	extz	xwa
	sll	xwa, 2
	add	xhl, xwa
	ld	xwa, (xhl)
	bit	15, qwa
	jr	nz, LswSound_ReturnThis
	pushw	LswSound_Str_Dash_Dash_Dash_Dash@hi16
	pushw	LswSound_Str_Dash_Dash_Dash_Dash@lo16
	ld	xwa, (xde+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
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
	ld xhl, 4:i3
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
	ld xhl, 0:i3

LswSound_PopIzRet:
	pop xiz
	ret

LswVolume:
	push	xiz
	ld	xiz, xwa
	lda	xhl, (MixerPartTable_Start_0x8:24)
	cp	xbc, EVT_LSW_DATA_REQ
	jrl	z, AudioCtrlMuteZeroReturn
	ld	xix, xde
	sll	xix, 2
	ld	xwa, xhl
	add	xwa, xix
	cp	xbc, EVT_CHECK_PART
	jrl	z, LswVolume_GetSignedToggle
	cp	xbc, EVT_GET_SMALL_STEP
	jrl	z, LswVolume_GetToggle
	cp	xbc, EVT_GET_LARGE_STEP
	jrl	z, LswVolume_CheckEnabled
	cp	xbc, EVT_GET_LSW_OUTPUT
	jrl	z, LswVolume_StepSize
	cp	xbc, EVT_GET_LSW_DATA_NO
	jr	z, LswVolume_GetSubParam
	cp	xbc, EVT_GET_PART
	jr	z, LswVolume_GetPartId
	cp	xbc, EVT_GET_LSW_STRING
	jrl	nz, AudioCtrlMuteZeroReturn
	ld	xwa, (xde)
	srl	xwa, 16
	ld	qwa, 0
	extz	xwa
	sll	xwa, 2
	add	xhl, xwa
	ld	xbc, (xde+8)
	ld	xwa, (xhl)
	bit	15, wa
	jr	z, LswVolume_InactiveStr
	ld	wa, (xde+4)
	cp	wa, 128
	jr	ge, LswVolume_OverflowStr
	pushw	wa
	pushw	LswVolume_Str_Fmt4d@hi16
	pushw	LswVolume_Str_Fmt4d@lo16
	push	xbc
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	jr	LswVolume_ReturnThis
LswVolume_OverflowStr:
	ld xwa, LswVolume_OverflowStr_Str_MUTE
	jr LswVolume_CopyStr

LswVolume_InactiveStr:
	ld xwa, LswVolume_InactiveStr_Str_Dash_Dash

LswVolume_CopyStr:
	push	xwa
	push	xbc
	call	Free_Compare2
	inc	8, xsp
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
	ld xhl, 7:i3
	jr AudioCtrl_PopIzRet3

LswVolume_StepSize:
	cp xde, 0x18
	jr nz, LswVolume_StepReturn
	ld xhl, 3:i3
	jr AudioCtrl_PopIzRet3

LswVolume_CheckEnabled:
	ld xwa, (xwa)
	bit 15, wa
	jr z, AudioCtrlMuteZeroReturn

LswVolume_StepReturn:
	ld xhl, 4:i3
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
	ld xhl, 0:i3

AudioCtrl_PopIzRet3:
	pop xiz
	ret

LswMute:
	push	xiz
	ld	xiz, xwa
	lda	xhl, (MixerPartTable_Start_0x8:24)
	cp	xbc, EVT_LSW_DATA_REQ
	jrl	z, AudioCtrlMutePitchReturn
	ld	xix, xde
	sll	xix, 2
	ld	xwa, xhl
	add	xwa, xix
	cp	xbc, EVT_CHECK_PART
	jrl	z, LswMute_GetSignedToggle
	cp	xbc, EVT_GET_SMALL_STEP
	jrl	z, LswMute_GetToggle
	cp	xbc, EVT_GET_LARGE_STEP
	jrl	z, LswMute_CheckEnabled
	cp	xbc, EVT_GET_LSW_OUTPUT
	jrl	z, LswMute_StepSize
	cp	xbc, EVT_GET_LSW_DATA_NO
	jr	z, LswMute_GetSubParam
	cp	xbc, EVT_GET_PART
	jr	z, LswMute_GetPartId
	cp	xbc, EVT_GET_LSW_STRING
	jrl	nz, AudioCtrlMutePitchReturn
	ld	xwa, (xde)
	srl	xwa, 16
	ld	qwa, 0
	extz	xwa
	sll	xwa, 2
	add	xhl, xwa
	ld	xbc, (xde+8)
	ld	xwa, (xhl)
	bit	15, wa
	jr	z, LswMute_InactiveStr
	ld	wa, (xde+4)
	cp	wa, 128
	jr	ge, LswMute_OverflowStr
	pushw	wa
	pushw	LswMute_Str_Fmt4d@hi16
	pushw	LswMute_Str_Fmt4d@lo16
	push	xbc
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	jr	LswMute_ReturnThis
LswMute_OverflowStr:
	ld xwa, LswMute_OverflowStr_Str_MUTE
	jr LswMute_CopyStr

LswMute_InactiveStr:
	ld xwa, LswMute_InactiveStr_Str_Dash_Dash

LswMute_CopyStr:
	push	xwa
	push	xbc
	call	Free_Compare2
	inc	8, xsp
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
	ld xhl, 3:i3
	jr AudioCtrl_PopIzRet2

LswMute_CheckEnabled:
	ld xwa, (xwa)
	bit 15, wa
	jr z, AudioCtrlMutePitchReturn
	ld xhl, 4:i3
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
	ld xhl, 0:i3

AudioCtrl_PopIzRet2:
	pop xiz
	ret

LswPan:
	push xiz
	ld xiz, xwa
	lda xix, (MixerPartTable_Start_0x8:24)
	cp xbc, EVT_GET_INIT_DATA
	jrl z, LswPan_ReturnCenter
	cp xbc, EVT_CHECK_INIT_DATA
	jrl z, LswPan_ReturnOne
	cp xbc, EVT_LSW_DATA_REQ
	jrl z, AudioCtrlTremoloZeroReturn
	ld xhl, xde
	sll xhl, 2
	ld xwa, xix
	add xwa, xhl
	ld xwa, (xwa)
	ld xhl, xwa
	and xhl, 0x4000
	cp xbc, EVT_CHECK_PART
	jrl z, LswPan_GetSignedToggle
	cp xbc, EVT_GET_SMALL_STEP
	jrl z, LswPan_GetToggle
	cp xbc, EVT_GET_LARGE_STEP
	jrl z, LswPan_CheckEnabled
	cp xbc, EVT_GET_LSW_OUTPUT
	jrl z, LswPan_StepReturn
	cp xbc, EVT_GET_LSW_DATA_NO
	jrl z, LswPan_GetSubParam
	cp xbc, EVT_GET_PART
	jr z, LswPan_GetPartId
	cp xbc, EVT_GET_LSW_STRING
	jrl nz, AudioCtrlTremoloZeroReturn
	ld xwa, (xde)
	srl xwa, 16
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
	ld xwa, LswPan_Str_CTR
	jr LswPan_CopyStr

LswPan_FormatOffset:
	cp wa, 0x40
	jr ge, LswPan_FormatRight
	ldw de, 0x40
	sub de, wa
	pushw de
	ld xwa, LswPan_FormatOffset_Str_L_Fmt2d
	jr LswPan_SendCommand

LswPan_FormatRight:
	sub wa, 0x40
	pushw wa
	ld xwa, LswPan_FormatRight_Str_R_Fmt2d

LswPan_SendCommand:
	push	xwa
	push	xbc
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	jr	LswPan_ReturnThis
LswPan_InactiveStr:
	ld xwa, LswPan_InactiveStr_Str_Dash_Dash

LswPan_CopyStr:
	push	xwa
	push	xbc
	call	Free_Compare2
	inc	8, xsp
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
	ld xhl, 4:i3
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
	ld xhl, 0:i3
	jr AudioCtrl_PopIzRet6

LswPan_ReturnOne:
	ld xhl, 1:i3
	jr AudioCtrl_PopIzRet6

LswPan_ReturnCenter:
	ld xhl, 0x40

AudioCtrl_PopIzRet6:
	pop xiz
	ret

LswReverb:
	push	xiz
	ld	xiz, xwa
	lda	xhl, (MixerPartTable_Start_0x8:24)
	cp	xbc, EVT_LSW_DATA_REQ
	jrl	z, AudioCtrlVibratoZeroReturn
	ld	xix, xde
	sll	xix, 2
	ld	xwa, xhl
	add	xwa, xix
	cp	xbc, EVT_CHECK_PART
	jrl	z, LswReverb_GetSignedToggle
	cp	xbc, EVT_GET_SMALL_STEP
	jrl	z, LswReverb_GetToggle
	cp	xbc, EVT_GET_LARGE_STEP
	jrl	z, LswReverb_CheckEnabled
	cp	xbc, EVT_GET_LSW_OUTPUT
	jrl	z, LswReverb_StepSize
	cp	xbc, EVT_GET_LSW_DATA_NO
	jr	z, LswReverb_GetSubParam
	cp	xbc, EVT_GET_PART
	jr	z, LswReverb_GetPartId
	cp	xbc, EVT_GET_LSW_STRING
	jrl	nz, AudioCtrlVibratoZeroReturn
	ld	xwa, (xde)
	srl	xwa, 16
	ld	qwa, 0
	extz	xwa
	sll	xwa, 2
	add	xhl, xwa
	ld	xbc, (xde+8)
	ld	xwa, (xhl)
	bit	13, wa
	jr	z, LswReverb_InactiveStr
	pushw	(xde+4)
	pushw	LswReverb_Str_Fmt3d@hi16
	pushw	LswReverb_Str_Fmt3d@lo16
	push	xbc
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	jr	LswReverb_ReturnThis
LswReverb_InactiveStr:
	pushw	LswReverb_InactiveStr_Str_Dash_Dash@hi16
	pushw	LswReverb_InactiveStr_Str_Dash_Dash@lo16
	push	xbc
	call	Free_Compare2
	inc	8, xsp
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
	ld xhl, 3:i3
	jr AudioCtrl_PopIzRet1

LswReverb_CheckEnabled:
	ld xwa, (xwa)
	bit 13, wa
	jr z, AudioCtrlVibratoZeroReturn

LswReverb_StepReturn:
	ld xhl, 4:i3
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
	ld xhl, 0:i3

AudioCtrl_PopIzRet1:
	pop xiz
	ret

LswDSPEffect:
	push	xiz
	ld	xiz, xwa
	lda	xhl, (MixerPartTable_Start_0x8:24)
	cp	xbc, EVT_LSW_DATA_REQ
	jrl	z, LswDSPEffZeroReturn
	ld	xix, xde
	sll	xix, 2
	ld	xwa, xhl
	add	xwa, xix
	cp	xbc, EVT_CHECK_PART
	jrl	z, LswDSPEff_GetSignedToggle
	cp	xbc, EVT_GET_SMALL_STEP
	jrl	z, LswDSPEff_GetToggle
	cp	xbc, EVT_GET_LARGE_STEP
	jr	z, LswDSPEff_CheckEnabled
	cp	xbc, EVT_GET_LSW_OUTPUT
	jr	z, LswDSPEff_StepReturn
	cp	xbc, EVT_GET_LSW_DATA_NO
	jr	z, LswDSPEff_GetSubParam
	cp	xbc, EVT_GET_PART
	jr	z, LswDSPEff_GetPartId
	cp	xbc, EVT_GET_LSW_STRING
	jr	nz, LswDSPEffZeroReturn
	ld	xwa, (xde)
	srl	xwa, 16
	ld	qwa, 0
	extz	xwa
	sll	xwa, 2
	add	xhl, xwa
	ld	xbc, (xde+8)
	ld	xwa, (xhl)
	bit	12, wa
	jr	z, LswDSPEff_InactiveStr
	pushw	(xde+4)
	pushw	LswDSPEffect_Str_Fmt3d@hi16
	pushw	LswDSPEffect_Str_Fmt3d@lo16
	push	xbc
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	jr	LswDSPEff_ReturnThis
LswDSPEff_InactiveStr:
	pushw	LswDSPEff_InactiveStr_Str_Dash_Dash@hi16
	pushw	LswDSPEff_InactiveStr_Str_Dash_Dash@lo16
	push	xbc
	call	Free_Compare2
	inc	8, xsp
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
	ld xhl, 4:i3
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
	ld xhl, 0:i3

LswDSPEffect_PopIzRet:
	pop xiz
	ret

LswDigitalEffect:
	push xiz
	ld xiz, xwa
	lda xhl, (MixerPartTable_Start_0x8:24)
	cp xbc, EVT_LSW_DATA_REQ
	jrl z, LswDigitalEffZeroReturn
	ld xix, xde
	sll xix, 2
	ld xwa, xhl
	add xwa, xix
	cp xbc, EVT_CHECK_PART
	jrl z, LswDigEff_GetSignedToggle
	cp xbc, EVT_GET_SMALL_STEP
	jrl z, LswDigEff_GetToggle
	cp xbc, EVT_GET_LARGE_STEP
	jr z, LswDigEff_CheckEnabled
	cp xbc, EVT_GET_LSW_OUTPUT
	jr z, LswDigEff_StepReturn
	cp xbc, EVT_GET_LSW_DATA_NO
	jr z, LswDigEff_GetSubParam
	cp xbc, EVT_GET_PART
	jr z, LswDigEff_GetPartId
	cp xbc, EVT_GET_LSW_STRING
	jrl nz, LswDigitalEffZeroReturn
	ld xwa, (xde)
	srl xwa, 16
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
	ld xwa, LswDigitalEffect_Str_ON
	jr LswDigEff_CopyStr

LswDigEff_StrOff:
	ld xwa, LswDigEff_StrOff_Str_OFF
	jr LswDigEff_CopyStr

LswDigEff_InactiveStr:
	ld xwa, LswDigEff_InactiveStr_Str_Dash_Dash

LswDigEff_CopyStr:
	push	xwa
	push	xbc
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, xiz
	jr	LswDigitalEffect_PopIzRet
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
	ld xhl, 4:i3
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
	ld xhl, 0:i3

LswDigitalEffect_PopIzRet:
	pop xiz
	ret

LswSustain:
	push xiz
	ld xiz, xwa
	lda xhl, (MixerPartTable_Start_0x8:24)
	cp xbc, EVT_LSW_DATA_REQ
	jrl z, LswSustainZeroReturn2
	ld xix, xde
	sll xix, 2
	ld xwa, xhl
	add xwa, xix
	cp xbc, EVT_CHECK_PART
	jrl z, LswSust_GetSignedToggle
	cp xbc, EVT_GET_SMALL_STEP
	jrl z, LswSust_GetToggle
	cp xbc, EVT_GET_LARGE_STEP
	jr z, LswSust_CheckEnabled
	cp xbc, EVT_GET_LSW_OUTPUT
	jr z, LswSust_StepReturn
	cp xbc, EVT_GET_LSW_DATA_NO
	jr z, LswSust_GetSubParam
	cp xbc, EVT_GET_PART
	jr z, LswSust_GetPartId
	cp xbc, EVT_GET_LSW_STRING
	jrl nz, LswSustainZeroReturn2
	ld xwa, (xde)
	srl xwa, 16
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
	ld xwa, LswSustain_Str_ON
	jr LswSust_CopyStr

LswSust_StrOff:
	ld xwa, LswSust_StrOff_Str_OFF
	jr LswSust_CopyStr

LswSust_InactiveStr:
	ld xwa, LswSust_InactiveStr_Str_Dash_Dash

LswSust_CopyStr:
	push	xwa
	push	xbc
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, xiz
	jr	LswSustain_PopIzRet2
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
	ld xhl, 4:i3
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
	ld xhl, 0:i3

LswSustain_PopIzRet2:
	pop xiz
	ret

LswSustainLength:
	push	xiz
	ld	xiz, xwa
	lda	xhl, (MixerPartTable_Start_0x8:24)
	cp	xbc, EVT_LSW_DATA_REQ
	jrl	z, LswSustainLenZeroReturn
	ld	xix, xde
	sll	xix, 2
	ld	xwa, xhl
	add	xwa, xix
	cp	xbc, EVT_CHECK_PART
	jrl	z, LswSustLen_GetSignedToggle
	cp	xbc, EVT_GET_SMALL_STEP
	jrl	z, LswSustLen_GetToggle
	cp	xbc, EVT_GET_LARGE_STEP
	jr	z, LswSustLen_CheckEnabled
	cp	xbc, EVT_GET_LSW_OUTPUT
	jr	z, LswSustLen_StepReturn
	cp	xbc, EVT_GET_LSW_DATA_NO
	jr	z, LswSustLen_GetSubParam
	cp	xbc, EVT_GET_PART
	jr	z, LswSustLen_GetPartId
	cp	xbc, EVT_GET_LSW_STRING
	jrl	nz, LswSustainLenZeroReturn
	ld	xwa, (xde)
	srl	xwa, 16
	ld	qwa, 0
	extz	xwa
	sll	xwa, 2
	add	xhl, xwa
	ld	xbc, (xde+8)
	ld	xwa, (xhl)
	bit	10, wa
	jr	z, LswSustLen_InactiveStr
	ld	wa, (xde+4)
	inc	1, wa
	pushw	wa
	pushw	LswSustainLength_Str_Fmt2d@hi16
	pushw	LswSustainLength_Str_Fmt2d@lo16
	push	xbc
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	jr	LswSustLen_ReturnThis
LswSustLen_InactiveStr:
	pushw	LswSustLen_InactiveStr_Str_Dash_Dash@hi16
	pushw	LswSustLen_InactiveStr_Str_Dash_Dash@lo16
	push	xbc
	call	Free_Compare2
	inc	8, xsp
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
	ld xhl, 4:i3
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
	ld xhl, 0:i3

LswSustainLength_PopIzRet:
	pop xiz
	ret

LswKeyShift:
	push	xiz
	ld	xiz, xwa
	lda	xhl, (MixerPartTable_Start_0x8:24)
	cp	xbc, EVT_GET_INIT_DATA
	jrl	z, LswKeyShift_ReturnCenter
	cp	xbc, EVT_CHECK_INIT_DATA
	jrl	z, LswKeyShift_ReturnOne
	cp	xbc, EVT_LSW_DATA_REQ
	jrl	z, AudioCtrlChorusZeroReturn
	ld	xix, xde
	sll	xix, 2
	ld	xwa, xhl
	add	xwa, xix
	cp	xbc, EVT_CHECK_PART
	jrl	z, LswKeyShift_GetSignedToggle
	cp	xbc, EVT_GET_SMALL_STEP
	jrl	z, LswKeyShift_GetToggle
	cp	xbc, EVT_GET_LARGE_STEP
	jrl	z, LswKeyShift_CheckEnabled
	cp	xbc, EVT_GET_LSW_OUTPUT
	jrl	z, LswKeyShift_StepReturn
	cp	xbc, EVT_GET_LSW_DATA_NO
	jr	z, LswKeyShift_GetSubParam
	cp	xbc, EVT_GET_PART
	jr	z, LswKeyShift_GetPartId
	cp	xbc, EVT_GET_LSW_STRING
	jrl	nz, AudioCtrlChorusZeroReturn
	ld	xwa, (xde)
	srl	xwa, 16
	ld	qwa, 0
	extz	xwa
	sll	xwa, 2
	add	xhl, xwa
	ld	xbc, (xde+8)
	ld	xwa, (xhl)
	bit	9, wa
	jr	z, LswKeyShift_InactiveStr
	ld	wa, (xde+4)
	sub	wa, 64
	jr	z, LswKeyShift_ZeroStr
	pushw	wa
	pushw	LswKeyShift_Str_Fmt3d@hi16
	pushw	LswKeyShift_Str_Fmt3d@lo16
	push	xbc
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	jr	LswKeyShift_ReturnThis
LswKeyShift_ZeroStr:
	ld xwa, LswKeyShift_ZeroStr_Str_N0
	jr LswKeyShift_CopyStr

LswKeyShift_InactiveStr:
	ld xwa, LswKeyShift_InactiveStr_Str_Dash_Dash

LswKeyShift_CopyStr:
	push	xwa
	push	xbc
	call	Free_Compare2
	inc	8, xsp
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
	ld xhl, 4:i3
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
	ld xhl, 0:i3
	jr AudioCtrl_PopIzRet5

LswKeyShift_ReturnOne:
	ld xhl, 1:i3
	jr AudioCtrl_PopIzRet5

LswKeyShift_ReturnCenter:
	ld xhl, 0x40

AudioCtrl_PopIzRet5:
	pop xiz
	ret

LswTuning:
	push	xiz
	ld	xiz, xwa
	lda	xhl, (MixerPartTable_Start_0x8:24)
	cp	xbc, EVT_GET_INIT_DATA
	jrl	z, LswTuning_ReturnCenter
	cp	xbc, EVT_CHECK_INIT_DATA
	jrl	z, LswTuning_ReturnOne
	cp	xbc, EVT_LSW_DATA_REQ
	jrl	z, AudioCtrlReverbZeroReturn
	ld	xix, xde
	sll	xix, 2
	ld	xwa, xhl
	add	xwa, xix
	cp	xbc, EVT_CHECK_PART
	jrl	z, LswTuning_GetSignedToggle
	cp	xbc, EVT_GET_SMALL_STEP
	jrl	z, LswTuning_GetToggle
	cp	xbc, EVT_GET_LARGE_STEP
	jrl	z, LswTuning_CheckEnabled
	cp	xbc, EVT_GET_LSW_OUTPUT
	jrl	z, LswTuning_StepReturn
	cp	xbc, EVT_GET_LSW_DATA_NO
	jr	z, LswTuning_GetSubParam
	cp	xbc, EVT_GET_PART
	jr	z, LswTuning_GetPartId
	cp	xbc, EVT_GET_LSW_STRING
	jrl	nz, AudioCtrlReverbZeroReturn
	ld	xwa, (xde)
	srl	xwa, 16
	ld	qwa, 0
	extz	xwa
	sll	xwa, 2
	add	xhl, xwa
	ld	xbc, (xde+8)
	ld	xwa, (xhl)
	bit	8, wa
	jr	z, LswTuning_InactiveStr
	ld	wa, (xde+4)
	sub	wa, 128
	jr	z, LswTuning_ZeroStr
	pushw	wa
	pushw	LswTuning_Str_Fmt4d@hi16
	pushw	LswTuning_Str_Fmt4d@lo16
	push	xbc
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	jr	LswTuning_ReturnThis
LswTuning_ZeroStr:
	ld xwa, LswTuning_ZeroStr_Str_N0
	jr LswTuning_CopyStr

LswTuning_InactiveStr:
	ld xwa, LswTuning_InactiveStr_Str_Dash_Dash

LswTuning_CopyStr:
	push	xwa
	push	xbc
	call	Free_Compare2
	inc	8, xsp
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
	ld xhl, 4:i3
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
	ld xhl, 0:i3
	jr AudioCtrl_PopIzRet4

LswTuning_ReturnOne:
	ld xhl, 1:i3
	jr AudioCtrl_PopIzRet4

LswTuning_ReturnCenter:
	ld xhl, 0x80

AudioCtrl_PopIzRet4:
	pop xiz
	ret

LswBendRange:
	push	xiz
	ld	xiz, xwa
	lda	xhl, (MixerPartTable_Start_0x8:24)
	cp	xbc, EVT_LSW_DATA_REQ
	jrl	z, LswBendRangeZeroReturn
	ld	xix, xde
	sll	xix, 2
	ld	xwa, xhl
	add	xwa, xix
	cp	xbc, EVT_CHECK_PART
	jrl	z, LswBendRng_GetSignedToggle
	cp	xbc, EVT_GET_SMALL_STEP
	jrl	z, LswBendRng_GetToggle
	cp	xbc, EVT_GET_LARGE_STEP
	jr	z, LswBendRng_CheckEnabled
	cp	xbc, EVT_GET_LSW_OUTPUT
	jr	z, LswBendRng_StepReturn
	cp	xbc, EVT_GET_LSW_DATA_NO
	jr	z, LswBendRng_GetSubParam
	cp	xbc, EVT_GET_PART
	jr	z, LswBendRng_GetPartId
	cp	xbc, EVT_GET_LSW_STRING
	jr	nz, LswBendRangeZeroReturn
	ld	xwa, (xde)
	srl	xwa, 16
	ld	qwa, 0
	extz	xwa
	sll	xwa, 2
	add	xhl, xwa
	ld	xbc, (xde+8)
	ld	xwa, (xhl)
	bit	7, wa
	jr	z, LswBendRng_InactiveStr
	pushw	(xde+4)
	pushw	LswBendRange_Str_Fmt3d@hi16
	pushw	LswBendRange_Str_Fmt3d@lo16
	push	xbc
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	jr	LswBendRng_ReturnThis
LswBendRng_InactiveStr:
	pushw	LswBendRng_InactiveStr_Str_Dash_Dash@hi16
	pushw	LswBendRng_InactiveStr_Str_Dash_Dash@lo16
	push	xbc
	call	Free_Compare2
	inc	8, xsp
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
	ld xhl, 4:i3
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
	ld xhl, 0:i3

LswBendRange_PopIzRet:
	pop xiz
	ret

LswGlidePedal:
	push xiz
	ld xiz, xwa
	lda xhl, (MixerPartTable_Start_0x8:24)
	cp xbc, EVT_LSW_DATA_REQ
	jrl z, LswGlideZeroReturn
	ld xix, xde
	sll xix, 2
	ld xwa, xhl
	add xwa, xix
	cp xbc, EVT_CHECK_PART
	jrl z, LswGlide_GetSignedToggle
	cp xbc, EVT_GET_SMALL_STEP
	jrl z, LswGlide_GetToggle
	cp xbc, EVT_GET_LARGE_STEP
	jr z, LswGlide_CheckEnabled
	cp xbc, EVT_GET_LSW_OUTPUT
	jr z, LswGlide_StepSize
	cp xbc, EVT_GET_LSW_DATA_NO
	jr z, LswGlide_GetSubParam
	cp xbc, EVT_GET_PART
	jr z, LswGlide_GetPartId
	cp xbc, EVT_GET_LSW_STRING
	jrl nz, LswGlideZeroReturn
	ld xwa, (xde)
	srl xwa, 16
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
	ld xwa, LswGlidePedal_Str_ON
	jr LswGlide_CopyStr

LswGlide_StrOff:
	ld xwa, LswGlide_StrOff_Str_OFF
	jr LswGlide_CopyStr

LswGlide_InactiveStr:
	ld xwa, LswGlide_InactiveStr_Str_Dash_Dash

LswGlide_CopyStr:
	push	xwa
	push	xbc
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, xiz
	jr	LswGlide_PopIzRet
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
	ld xhl, 3:i3
	jr LswGlide_PopIzRet

LswGlide_CheckEnabled:
	ld xwa, (xwa)
	bit 6, wa
	jr z, LswGlideZeroReturn
	ld xhl, 4:i3
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
	ld xhl, 0:i3

LswGlide_PopIzRet:
	pop xiz
	ret

LswSustainPedal:
	push xiz
	ld xiz, xwa
	lda xhl, (MixerPartTable_Start_0x8:24)
	cp xbc, EVT_LSW_DATA_REQ
	jrl z, LswSustainZeroReturn
	ld xix, xde
	sll xix, 2
	ld xwa, xhl
	add xwa, xix
	cp xbc, EVT_CHECK_PART
	jrl z, LswSustPedal_GetSignedToggle
	cp xbc, EVT_GET_SMALL_STEP
	jrl z, LswSustPedal_GetToggle
	cp xbc, EVT_GET_LARGE_STEP
	jr z, LswSustPedal_CheckEnabled
	cp xbc, EVT_GET_LSW_OUTPUT
	jr z, LswSustPedal_StepSize
	cp xbc, EVT_GET_LSW_DATA_NO
	jr z, LswSustPedal_GetSubParam
	cp xbc, EVT_GET_PART
	jr z, LswSustPedal_GetPartId
	cp xbc, EVT_GET_LSW_STRING
	jrl nz, LswSustainZeroReturn
	ld xwa, (xde)
	srl xwa, 16
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
	ld xwa, LswSustainPedal_Str_ON
	jr LswSustPedal_CopyStr

LswSustPedal_StrOff:
	ld xwa, LswSustPedal_StrOff_Str_OFF
	jr LswSustPedal_CopyStr

LswSustPedal_InactiveStr:
	ld xwa, LswSustPedal_InactiveStr_Str_Dash_Dash

LswSustPedal_CopyStr:
	push	xwa
	push	xbc
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, xiz
	jr	LswSustain_PopIzRet
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
	ld xhl, 3:i3
	jr LswSustain_PopIzRet

LswSustPedal_CheckEnabled:
	ld xwa, (xwa)
	bit 5, wa
	jr z, LswSustainZeroReturn
	ld xhl, 4:i3
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
	ld xhl, 0:i3

LswSustain_PopIzRet:
	pop xiz
	ret

LswKeyScaling:
	push xiz
	ld xiz, xwa
	lda xhl, (MixerPartTable_Start_0x8:24)
	cp xbc, EVT_LSW_DATA_REQ
	jrl z, LswKeyScaleZeroReturn
	ld xix, xde
	sll xix, 2
	ld xwa, xhl
	add xwa, xix
	cp xbc, EVT_CHECK_PART
	jrl z, LswKeyScale_GetSignedToggle
	cp xbc, EVT_GET_SMALL_STEP
	jrl z, LswKeyScale_GetToggle
	cp xbc, EVT_GET_LARGE_STEP
	jr z, LswKeyScale_CheckEnabled
	cp xbc, EVT_GET_LSW_OUTPUT
	jr z, LswKeyScale_StepSize
	cp xbc, EVT_GET_LSW_DATA_NO
	jr z, LswKeyScale_GetSubParam
	cp xbc, EVT_GET_PART
	jr z, LswKeyScale_GetPartId
	cp xbc, EVT_GET_LSW_STRING
	jrl nz, LswKeyScaleZeroReturn
	ld xwa, (xde)
	srl xwa, 16
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
	ld xwa, LswKeyScaling_Str_ON
	jr LswKeyScale_CopyStr

LswKeyScale_StrOff:
	ld xwa, LswKeyScale_StrOff_Str_OFF
	jr LswKeyScale_CopyStr

LswKeyScale_InactiveStr:
	ld xwa, LswKeyScale_InactiveStr_Str_Dash_Dash

LswKeyScale_CopyStr:
	push	xwa
	push	xbc
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, xiz
	jr	LswKeyScale_PopIzRet
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
	ld xhl, 3:i3
	jr LswKeyScale_PopIzRet

LswKeyScale_CheckEnabled:
	ld xwa, (xwa)
	bit 4, wa
	jr z, LswKeyScaleZeroReturn
	ld xhl, 4:i3
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
	ld xhl, 0:i3

LswKeyScale_PopIzRet:
	pop xiz
	ret

LswAfterTouch:
	push xiz
	ld xiz, xwa
	lda xhl, (MixerPartTable_Start_0x8:24)
	cp xbc, EVT_LSW_DATA_REQ
	jrl z, LswAfterTouchZeroReturn
	ld xix, xde
	sll xix, 2
	ld xwa, xhl
	add xwa, xix
	cp xbc, EVT_CHECK_PART
	jrl z, LswAfterTouch_GetSignedToggle
	cp xbc, EVT_GET_SMALL_STEP
	jrl z, LswAfterTouch_GetToggle
	cp xbc, EVT_GET_LARGE_STEP
	jr z, LswAfterTouch_CheckEnabled
	cp xbc, EVT_GET_LSW_OUTPUT
	jr z, LswAfterTouch_StepSize
	cp xbc, EVT_GET_LSW_DATA_NO
	jr z, LswAfterTouch_GetSubParam
	cp xbc, EVT_GET_PART
	jr z, LswAfterTouch_GetPartId
	cp xbc, EVT_GET_LSW_STRING
	jrl nz, LswAfterTouchZeroReturn
	ld xwa, (xde)
	srl xwa, 16
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
	ld xwa, LswAfterTouch_Str_ON
	jr LswAfterTouch_CopyStr

LswAfterTouch_StrOff:
	ld xwa, LswAfterTouch_StrOff_Str_OFF
	jr LswAfterTouch_CopyStr

LswAfterTouch_InactiveStr:
	ld xwa, LswAfterTouch_InactiveStr_Str_Dash_Dash

LswAfterTouch_CopyStr:
	push	xwa
	push	xbc
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, xiz
	jr	LswAfterTouch_PopIzRet
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
	ld xhl, 3:i3
	jr LswAfterTouch_PopIzRet

LswAfterTouch_CheckEnabled:
	ld xwa, (xwa)
	bit 2, wa
	jr z, LswAfterTouchZeroReturn
	ld xhl, 4:i3
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
	ld xhl, 0:i3

LswAfterTouch_PopIzRet:
	pop xiz
	ret

LswPartExp:
	push xiz
	ld xiz, xwa
	lda xhl, (MixerPartTable_Start_0x8:24)
	cp xbc, EVT_LSW_DATA_REQ
	jrl z, LswPartExpZeroReturn
	ld xix, xde
	sll xix, 2
	ld xwa, xhl
	add xwa, xix
	cp xbc, EVT_CHECK_PART
	jrl z, LswPartExp_SignedToggle
	cp xbc, EVT_GET_SMALL_STEP
	jrl z, LswPartExp_ToggleState
	cp xbc, EVT_GET_LARGE_STEP
	jr z, LswPartExp_EnabledCheck
	cp xbc, EVT_GET_LSW_OUTPUT
	jr z, LswPartExp_StepSize
	cp xbc, EVT_GET_LSW_DATA_NO
	jr z, LswPartExp_SubParam
	cp xbc, EVT_GET_PART
	jr z, LswPartExp_PartIdLookup
	cp xbc, EVT_GET_LSW_STRING
	jrl nz, LswPartExpZeroReturn
	ld xwa, (xde)
	srl xwa, 16
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
	ld xwa, LswPartExp_Str_ON
	jr LswPartExp_StrCopyReturn

LswPartExp_StrDisabled:
	ld xwa, LswPartExp_StrDisabled_Str_OFF
	jr LswPartExp_StrCopyReturn

LswPartExp_StrOff:
	ld xwa, LswPartExp_StrOff_Str_Dash_Dash

LswPartExp_StrCopyReturn:
	push	xwa
	push	xbc
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, xiz
	jr	LswPartExp_PopIzRet
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
	ld xhl, 3:i3
	jr LswPartExp_PopIzRet

LswPartExp_EnabledCheck:
	ld xwa, (xwa)
	bit_erpw 0xe2, 0x00
	jr z, LswPartExpZeroReturn
	ld xhl, 4:i3
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
	ld xhl, 0:i3

LswPartExp_PopIzRet:
	pop xiz
	ret

LswLocalControl:
	push xiz
	ld xiz, xwa
	lda xhl, (MixerPartTable_Start_0x8:24)
	cp xbc, EVT_LSW_DATA_REQ
	jrl z, LswLocalControlZeroReturn
	ld xix, xde
	sll xix, 2
	ld xwa, xhl
	add xwa, xix
	cp xbc, EVT_CHECK_PART
	jrl z, LswLocal_SignedToggle
	cp xbc, EVT_GET_SMALL_STEP
	jrl z, LswLocal_ToggleState
	cp xbc, EVT_GET_LARGE_STEP
	jr z, LswLocal_EnabledCheck
	cp xbc, EVT_GET_LSW_OUTPUT
	jr z, LswLocal_StepSize
	cp xbc, EVT_GET_LSW_DATA_NO
	jr z, LswLocal_SubParam
	cp xbc, EVT_GET_PART
	jr z, LswLocal_PartIdLookup
	cp xbc, EVT_GET_LSW_STRING
	jr nz, LswLocalControlZeroReturn
	ld xwa, (xde)
	srl xwa, 16
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
	ld xwa, LswLocalControl_Str_ON
	jr LswLocal_StrCopyReturn

LswLocal_StrDisabled:
	ld xwa, LswLocal_StrDisabled_Str_OFF
	jr LswLocal_StrCopyReturn

LswLocal_StrOff:
	ld xwa, LswLocal_StrOff_Str_Dash_Dash

LswLocal_StrCopyReturn:
	push	xwa
	push	xbc
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, xiz
	jr	LswLocalControl_PopIzRet
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
	ld xhl, 3:i3
	jr LswLocalControl_PopIzRet

LswLocal_EnabledCheck:
	ld xwa, (xwa)
	bit 0, wa
	jr nz, LswLocal_ReturnMinusOne

LswLocalControlZeroReturn:
	ld xhl, 0:i3
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
	dec	4, xsp
	push	xiz
	ld	xiz, xde
	ld	(xsp+4), xwa
	lda	xde, (MixerPartTable_Start_0x12C:24)
	lda	xhl, (MixerPartTable_Start_0x8:24)
	cp	xbc, EVT_LSW_DATA_REQ
	jrl	z, LswLocalZeroReturn
	ld	xix, xiz
	sll	xix, 2
	ld	xwa, xhl
	add	xwa, xix
	cp	xbc, EVT_CHECK_PART
	jrl	z, LswMidi_SignedToggle
	cp	xbc, EVT_GET_SMALL_STEP
	jrl	z, LswMidi_ToggleState
	cp	xbc, EVT_GET_LARGE_STEP
	jrl	z, LswMidi_EnabledCheck
	cp	xbc, EVT_GET_LSW_OUTPUT
	jrl	z, LswMidi_StepSize
	cp	xbc, EVT_GET_LSW_DATA_NO
	jrl	z, LswMidi_SubParam
	cp	xbc, EVT_GET_PART
	jr	z, LswMidi_PartIdLookup
	cp	xbc, EVT_GET_LSW_STRING
	jrl	nz, LswLocalZeroReturn
	ld	xwa, (xiz)
	srl	xwa, 16
	ld	qwa, 0
	extz	xwa
	sll	xwa, 2
	add	xhl, xwa
	ld	xwa, (xhl)
	bit	1, wa
	jr	z, LswMidi_StrOff
	ld	xwa, (xiz)
	srl	xwa, 16
	ld	qwa, 0
	extz	xwa
	add	xwa, xwa
	add	xde, xwa
	ld	wa, (xde)
	ldw	bc, 1026
	call	DkMdlyPly_CheckState_Helper
	ld	xbc, (xiz+8)
	cp	hl, 0:i3
	jr	z, LswMidi_StrChannelAlt
	ld	wa, (xiz+4)
	inc	1, wa
	pushw	wa
	pushw	LswMidiChannel_Str_CH_Fmt2d@hi16
	pushw	LswMidiChannel_Str_CH_Fmt2d@lo16
	push	xbc
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	jr	LswMidi_LoadReturnValue
LswMidi_StrChannelAlt:
	pushw LswMidi_StrChannelAlt_Str_OFF@hi16
	pushw LswMidi_StrChannelAlt_Str_OFF@lo16
	push xbc
	jr LswMidi_StrCopyReturn

LswMidi_StrOff:
	pushw LswMidi_StrOff_Str_Dash_Dash@hi16
	pushw LswMidi_StrOff_Str_Dash_Dash@lo16
	ld xwa, (xiz + 8)
	push xwa

LswMidi_StrCopyReturn:
	call	Free_Compare2
	inc	8, xsp
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
	ld xhl, 3:i3
	jr LswLocal_PopIzSkip4Ret

LswMidi_EnabledCheck:
	ld xwa, (xwa)
	bit 1, wa
	jr z, LswLocalZeroReturn
	ld xhl, 4:i3
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
	ld xhl, 0:i3

LswLocal_PopIzSkip4Ret:
	pop xiz
	inc 4, xsp
	ret
IvMesageProc:
	push	xiz
	ld	xiz, xwa
	cp	xbc, EVT_GET_STRING
	jrl	z, IvMessage_GetText
	ld	a, (32422:16)
	extz	wa
	cp	xbc, EVT_INTERRUPT_OFF
	jrl	z, IvMessage_SelectionChange
	cp	xbc, EVT_DRAW
	jrl	z, IvMessage_Paint
	cp	xbc, EVT_REPAINT
	jr	z, IvMessage_ShowHide
	cp	xbc, EVT_PAINT
	jr	z, IvMessage_ShowHide
	cp	xbc, EVT_HIDE
	jr	z, IvMessage_Close
	cp	xbc, EVT_SHOW
	jrl	nz, IvMessage_ForwardToBase
	ld	(149388:24), wa
	ld	xwa, xiz
	call	InheritedProc
	ld	wa, (149388:24)
	muls	wa, 14
	lda	xbc, (NakaInst_Por_favor_seleccione_el_Panel_Memory_al_que_desea_0x118:24)
	ld_rrw	wa, xbc, wa
	sla	wa, 2
	lda	xbc, (IvMesageProc_PtrTable:24)
	ld_rrl	xwa, xbc, wa
	ld	xbc, EVT_SHOW
	ld	xde, 0:i3
	call	SendEvent
	ld	wa, (149388:24)
	muls	wa, 14
	lda	xbc, (NakaInst_Por_favor_seleccione_el_Panel_Memory_al_que_desea_0x118:24)
	cpw	(xbc+wa), 0x0005
	jrl	nz, IvMessageStrcpyReturn
	ld	xwa, 4294967295
	ld	xbc, EVT_SET_KEEP
	ld	xde, 1:i3
	jr	IvMessage_SendEvent
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
	ld wa, (0x02478c:24)
	muls wa, 0xe
	lda xbc, (NakaInst_Por_favor_seleccione_el_Panel_Memory_al_que_desea_0x118:24)
	cpw	(xbc+wa), 0x0005
	call nz, (DrawWall:24)
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3

IvMessage_SendEvent:
	call SendEvent
	jr IvMessageStrcpyReturn

IvMessage_SelectionChange:
	ld (0x02478c:24), wa
	muls wa, 0xe
	lda xbc, (NakaInst_Por_favor_seleccione_el_Panel_Memory_al_que_desea_0x118:24)
	ld	wa, (xbc+wa)
	sla wa, 2
	lda xbc, (IvMesageProc_PtrTable:24)
	ld	xwa, (xbc+wa)
	ld xbc, EVT_SEARCH_LINK
	ld xde, EVT_INTERRUPT_OFF
	call SendEvent
	jr IvMessage_Epilogue

IvMessage_GetText:
	pushw	233
	pushw	55238
	push	xde
	call	Free_Compare2
	inc	8, xsp
IvMessageStrcpyReturn:
	ld xhl, 0:i3
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
	cp xiz, EVT_GET_STRING
	jrl z, PleaseWait_GetText
	cp xiz, EVT_PARA_DRAW
	jr z, PleaseWait_Confirm
	cp xiz, EVT_DRAW
	jr z, PleaseWait_Paint
	cp xiz, EVT_HIDE
	jr z, PleaseWait_Close
	cp xiz, EVT_SHOW
	jr z, PleaseWait_Init
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	jrl PleaseWait_Epilogue

PleaseWait_Init:
	ldw (0x02477a:24), 0x0000
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	jr PleaseWait_InheritedReturn

PleaseWait_Close:
	ld xwa, EVT_PARA_DRAW
	push xwa
	ld xwa, 0:i3
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
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call SendEvent
	jrl LanguageStringcpyReturn

PleaseWait_Confirm:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, EVT_PARA_DRAW
	push xwa
	ld xwa, 0:i3
	push xwa
	ld xwa, 0x14
	ld xbc, (xsp + 20)
	ld xde, (xsp + 20)
	call SetApTimer
	incw 1, (0x2477a:24)
	jrl LanguageStringcpyReturn

PleaseWait_GetText:
	ld XWA,(XSP+0x08)
	ld (XSP+0x04),XWA
	ld a, (0x0340e4:24)
	extz WA
	sla WA, 0x02
	lda xbc, (PleaseWait_GetText_PtrTable:24)
	ld	xwa, (xbc+wa)
	push XWA
	call LyricsTrack_ReadAndParse_Helper2
	inc 4,XSP
	ld DE,HL
	ld hl, 0:i3
	cp de, 0:i3
	jr le, PleaseWait_BuildScrollStr
PleaseWait_DotFillLoop:
	ld xwa, (xsp + 8)
	ld	(xwa+hl), 0x2e
	inc 1, hl
	cp hl, de
	jr lt, PleaseWait_DotFillLoop

PleaseWait_BuildScrollStr:
	ld xiy, (xsp + 8)
	ld	(xiy+hl), 0x00
	ld ix, de
	add ix, ix
	ld wa, (0x02477a:24)
	exts xwa
	divs xwa, ix
	ldto_werp HL, 0xe2
	ld a, (0x0340e4:24)
	extz wa
	lda xbc, (PleaseWait_GetText_PtrTable:24)
	sla wa, 2
	ld	xwa, (xbc+wa)
	cp hl, de
	jr ge, PleaseWait_OverflowPath
	sub de, hl
	pushw de
	lda	xwa, (xwa+hl)
	push xwa
	push xiy
	jr PleaseWait_Strncpy

PleaseWait_OverflowPath:
	ld bc, hl
	sub bc, de
	pushw bc
	push xwa
	ld xwa, (xsp + 10)
	lda	xbc, (xwa+ix)
	exts xhl
	sub xbc, xhl
	push xbc

PleaseWait_Strncpy:
	call	CmpNamingCheck_Helper
	lda	xsp, (xsp+10)
LanguageStringcpyReturn:
	ld xhl, 0:i3

PleaseWait_Epilogue:
	pop xiz
	lda xsp, (xsp + 12)
	ret

CheckLanguage:
	cp xbc, EVT_GET_RAM_SIZE
	jrl z, CheckLang_ReturnOne
	cp xbc, EVT_GET_RAM_ADDRESS
	jrl z, CheckLang_ReturnAddress
	cp xbc, EVT_GET_RAM_STRING
	jr z, CheckLang_GetTextStr
	cp xbc, EVT_SW_IN
	jr nz, CheckLang_ReturnZero
	ld a, (0x0340e4:24)
	bit 7, de
	jr z, CheckLang_Increment
	ld c, a
	cp a, 0:i3
	jr z, CheckLang_SkipLang4
	dec 1, c
	ld (0x0340e4:24), c

CheckLang_SkipLang4:
	ld a, (0x0340e4:24)
	cp a, 4:i3
	jr nz, LanguageSelectEventReturn
	dec 1, a
	ld (0x0340e4:24), a
	jr LanguageSelectEventReturn

CheckLang_Increment:
	ld c, a
	cp a, 5:i3
	jr nc, CheckLang_SkipLang4Up
	inc 1, c
	ld (0x0340e4:24), c

CheckLang_SkipLang4Up:
	ld a, (0x0340e4:24)
	cp a, 4:i3
	jr nz, LanguageSelectEventReturn
	inc 1, a
	ld (0x0340e4:24), a

LanguageSelectEventReturn:
	ld xwa, 0xffffffff
	ld xbc, EVT_ALL_PAINT
	ld xde, 0:i3
	call SendEvent
	jr CheckLang_ReturnZero

CheckLang_GetTextStr:
	ld	a, (213220:24)
	extz	wa
	sla	wa, 2
	lda	xbc, (Str_PleaseWait_Multilingual:24)
	ld_rrl	xwa, xbc, wa
	push	xwa
	ld	xwa, (xde+18)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
CheckLang_ReturnZero:
	ld xhl, 0:i3
	ret

CheckLang_ReturnAddress:
	lda xhl, (0x0340e4:24)
	ret

CheckLang_ReturnOne:
	ld xhl, 1:i3
	ret

CheckMessage:
	push xiz
	ld xiz, xde
	cp xbc, EVT_GET_RAM_SIZE
	jrl z, CheckMsg_ReturnTwo
	cp xbc, EVT_GET_RAM_ADDRESS
	jrl z, CheckMsg_ReturnAddress
	cp xbc, EVT_GET_RAM_STRING
	jrl z, CheckMsg_AudioCommand
	cp xbc, EVT_SW_IN
	jrl nz, CheckMsg_ReturnZero
	ld wa, (0x02478c:24)
	muls wa, 0xe
	lda xbc, (NakaInst_Por_favor_seleccione_el_Panel_Memory_al_que_desea_0x118:24)
	ld	wa, (xbc+wa)
	sla wa, 2
	lda xbc, (IvMesageProc_PtrTable:24)
	ld	xwa, (xbc+wa)
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call SendEvent
	ld wa, (0x02478c:24)
	bit 7, iz
	jr z, CheckMsg_IncrementCheck
	ld bc, wa
	cp wa, 0:i3
	jr le, LanguageCheckReturn
	dec 1, bc
	ld (0x02478c:24), bc
	jr LanguageCheckReturn

CheckMsg_IncrementCheck:
	ld bc, wa
	muls wa, 0xe
	add wa, 0xe
	lda xde, (NakaInst_Por_favor_seleccione_el_Panel_Memory_al_que_desea_0x122:24)
	ld	xwa, (xde+wa)
	or xwa, xwa
	jr z, LanguageCheckReturn
	inc 1, bc
	ld (0x02478c:24), bc

LanguageCheckReturn:
	ld wa, (0x02478c:24)
	muls wa, 0xe
	lda xbc, (NakaInst_Por_favor_seleccione_el_Panel_Memory_al_que_desea_0x118:24)
	ld	wa, (xbc+wa)
	sla wa, 2
	lda xbc, (IvMesageProc_PtrTable:24)
	ld	xwa, (xbc+wa)
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	call SendEvent
	jr CheckMsg_ReturnZero

CheckMsg_AudioCommand:
	pushw_da 0x8c, 0x47, 0x02

	pushw 0xe9

	pushw 0xd892

	ld xwa, (xiz + 18)

	push xwa

	call	Scoop_EventLoop_12Entry_Helper

	lda xsp, (xsp + 10)



CheckMsg_ReturnZero:
	ld xhl, 0:i3
	jr CheckMsg_Epilogue

CheckMsg_ReturnAddress:
	lda xhl, (0x02478c:24)
	jr CheckMsg_Epilogue

CheckMsg_ReturnTwo:
	ld xhl, 2:i3

CheckMsg_Epilogue:
	pop xiz
	ret

MessageText:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr z, MsgText_LookupMessage
	ld xhl, 0:i3
	ret

MsgText_LookupMessage:
	ld wa, (0x02478c:24)
	cp wa, 0x1a
	jr z, MsgText_CheckLanguage
	muls wa, 0xe
	lda xbc, (NakaInst_Por_favor_seleccione_el_Panel_Memory_al_que_desea_0x122:24)
	ld	xhl, (xbc+wa)
	ret

MsgText_CheckLanguage:
	ld a, (3298:16)
	cp a, 3:i3
	jr z, MsgText_Lang3
	cp a, 2:i3
	jr z, MsgText_Lang2
	cp a, 1:i3
	jr z, MsgText_Lang1
	lda xhl, (MsgText_CheckLanguage_PtrTable:24)
	ret

MsgText_Lang1:
	ld xhl, StrTable_DiskErr24_Chord
	jr MsgText_Return

MsgText_Lang2:
	ld xhl, MsgText_Lang2_PtrTable
	jr MsgText_Return

MsgText_Lang3:
	ld xhl, MsgText_Lang3_PtrTable

MsgText_Return:
	ret

MessageHeader:
	dec 6, xsp
	push xiz
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr z, MsgHeader_BuildHeader
	ld xhl, 0:i3
	jrl	MsgHeader_Epilogue

MsgHeader_BuildHeader:
	ld	bc, (0x02478c:24)
	muls	bc, 14
	lda	xwa, (NakaInst_Por_favor_seleccione_el_Panel_Memory_al_que_desea_0x118:24)
	lda_rr	xwa, xwa, bc	; lda xwa, xwa+bc
	cpw	(xwa), 3
	jrl	nz, MsgHeader_SingleEntry
	pushw	24
	call	SLIDE_Decompress_4K_Init_Helper2
	inc	2, xsp
	ld	(xsp+4), xhl
	ld	xwa, 0xffffffff
	ld	xbc, EVT_AUTO_FREE
	ld	xde, (xsp+4)
	call	PostEvent
	ldw	(xsp+8), 0
MsgHeader_BuildLoop:
	ld	bc, (0x02478c:24)
	muls	bc, 14
	lda	xwa, (MsgHeader_BuildLoop_PtrTable:24)
	ld	de, (xsp+8)
	extz	xde
	sll	xde, 2
	add	xde, (xwa+bc)
	ld	xwa, (xde)
	push	xwa
	call	LyricsTrack_ReadAndParse_Helper2
	inc	6, hl
	pushw	hl
	call	SLIDE_Decompress_4K_Init_Helper2
	ld	xiz, xhl
	ld	bc, (0x02478c:24)
	muls	bc, 14
	lda	xwa, (NakaInst_Por_favor_seleccione_el_Panel_Memory_al_que_desea_0x118:24)
	lda_rr	xwa, xwa, bc	; lda xwa, xwa+bc
	pushw	(xwa+4)
	ld	bc, (xsp+16)
	extz	xbc
	sll	xbc, 2
	add	xbc, (xwa+6)
	ld	xwa, (xbc)
	push	xwa
	pushw	MsgHeader_BuildLoop_Str_Fmts_Fmt2d@hi16
	pushw	MsgHeader_BuildLoop_Str_Fmts_Fmt2d@lo16
	push	xiz
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+20)
	ld	xwa, 0xffffffff
	ld	xbc, EVT_AUTO_FREE
	ld	xde, xiz
	call	PostEvent
	ld	wa, (xsp+8)
	extz	xwa
	sll	xwa, 2
	add	xwa, (xsp+4)
	ld	(xwa), xiz
	incw	1, (xsp+8)
	cpw	(xsp+8), 5
	jrl	ule, MsgHeader_BuildLoop
	ld	xhl, (xsp+4)
	jr	MsgHeader_Epilogue
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
	cp xbc, EVT_GET_STRING
	jrl z, IvAccordion_GetText
	cp xbc, EVT_PART_SELECT
	jrl z, IvAccordion_Refresh
	cp xbc, EVT_LSW_DATA
	jrl z, IvAccordion_Match
	cp xbc, EVT_SOUND_SW_NO
	jrl z, IvAccordion_Update
	cp xbc, EVT_I_AM_SELECTED
	jrl z, IvAccordion_PageSelect
	cp xbc, EVT_ACCORDION_TAB
	jrl z, IvAccordion_PageSelect
	cp xbc, EVT_INDEXSW_DOWN
	jrl z, IvAccordion_Scroll
	cp xbc, EVT_INDEXSW_UP
	jrl z, IvAccordion_Scroll
	cp xbc, EVT_DRAW
	jrl z, IvAccordion_Paint
	cp xbc, EVT_REPAINT
	jr z, IvAccordion_ShowHide
	cp xbc, EVT_PAINT
	jr z, IvAccordion_ShowHide
	cp xbc, EVT_HIDE
	jr z, IvAccordion_Close
	cp xbc, EVT_SHOW
	jrl nz, IvAccordion_ForwardToBase
	ld xwa, (xsp + 4)
	ld xde, xiz
	call InheritedProc
	call GetModeNow
	cp xhl, NAKA_MODE_MD_NORMAL
	jrl nz, IvAccordion_ReturnHandled
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_KEEP
	ld xde, 1:i3
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
	ldw (0x02477c:24), 0xffff
	ldw (0x024780:24), 0xffff
	call GetPartSelect
	ld (0x02477e:24), hl
	ld wa, hl
	calr SndParam_ResolveOscEntry
	ld xde, xhl
	ld xwa, (xsp + 4)
	ld xbc, EVT_SOUND_SW_NO
	call SendEvent
	call GetModeNow
	cp xhl, NAKA_MODE_MD_DEMO
	jr nz, IvAccordion_ShowHide_UpdatePart
	cpw (0x24782:24), 0
	jr z, IvAccordion_ShowHide_NoBellows
	; object handle 0xeb0009 = class 0x0eb, instance 9 (SendEvent indexes its class table by bits 16-27; not an address -- was WidgetName_PtrBlock_A_0x1)
	ld xwa, WidgetName_PtrBlock_A_0x1
	ld xbc, EVT_HIDE
	ld xde, 5:i3
	call SendEvent
	ldw (0x02477c:24), 0x0001
	ldw (0x024780:24), 0x0001
	ld xwa, WidgetName_PtrBlock_A_0xF
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	jr IvAccordion_ShowHide_Toggle

IvAccordion_ShowHide_NoBellows:
	; object handle 0xeb0017 = class 0x0eb, instance 23 (SendEvent indexes its class table by bits 16-27; not an address -- was WidgetName_PtrBlock_A_0xF)
	ld xwa, WidgetName_PtrBlock_A_0xF
	ld xbc, EVT_HIDE
	ld xde, 5:i3
	call SendEvent
	ldw (0x02477c:24), 0x0000
	ldw (0x024780:24), 0x0000
	ld xwa, WidgetName_PtrBlock_A_0x1
	ld xbc, EVT_SHOW
	ld xde, 5:i3

IvAccordion_ShowHide_Toggle:
	call SendEvent
	ld wa, (0x024782:24)
	cpl wa
	ld (0x024782:24), wa

IvAccordion_ShowHide_UpdatePart:
	ld wa, (0x02477e:24)
	sla wa, 2
	lda xbc, (0x03e9a0:24)
	ld	xde, (xbc+wa)
	ld xwa, WidgetName_InitPtrTable_0x15
	ld xbc, EVT_PARA_DRAW
	jrl IvAccordion_DispatchEvent

IvAccordion_Paint:
	ld xwa, (xsp + 4)
	ld xde, xiz
	call InheritedProc
	ld xwa, (xsp + 4)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl IvAccordion_DispatchEvent

IvAccordion_Scroll:
	ld xwa, (xsp + 4)
	ld xde, xiz
	call InheritedProc
	cp xiz, 0x1
	jrl z, IvAccordion_ReturnHandled
	or xiz, xiz
	jrl nz, IvAccordion_ReturnHandled
	cpw (0x24780:24), 0
	jr nz, IvAccordion_Scroll_SetOff
	ldw (0x024780:24), 0x0001
	; object handle 0xeb0009 = class 0x0eb, instance 9 (SendEvent indexes its class table by bits 16-27; not an address -- was WidgetName_PtrBlock_A_0x1)
	ld xwa, WidgetName_PtrBlock_A_0x1
	ld xbc, EVT_HIDE
	ld xde, 5:i3
	call SendEvent
	; object handle 0xeb0017 = class 0x0eb, instance 23 (SendEvent indexes its class table by bits 16-27; not an address -- was WidgetName_PtrBlock_A_0xF)
	ld xwa, WidgetName_PtrBlock_A_0xF
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEX_SELECT
	ld xde, 1:i3
	call PostEvent
	cpw (0x2477c:24), 1
	jrl nz, IvAccordion_ReturnHandled
	ld wa, (0x02477e:24)
	calr SndParam_ResolveOscEntry
	ld xde, xhl
	ld xwa, (xsp + 4)
	ld xbc, EVT_SOUND_SW_NO
	jrl IvAccordion_DispatchEvent

IvAccordion_Scroll_SetOff:
	ldw (0x024780:24), 0x0000
	; object handle 0xeb0017 = class 0x0eb, instance 23 (SendEvent indexes its class table by bits 16-27; not an address -- was WidgetName_PtrBlock_A_0xF)
	ld xwa, WidgetName_PtrBlock_A_0xF
	ld xbc, EVT_HIDE
	ld xde, 5:i3
	call SendEvent
	; object handle 0xeb0009 = class 0x0eb, instance 9 (SendEvent indexes its class table by bits 16-27; not an address -- was WidgetName_PtrBlock_A_0x1)
	ld xwa, WidgetName_PtrBlock_A_0x1
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEX_SELECT
	ld xde, 1:i3
	call PostEvent
	cpw (0x2477c:24), 0
	jrl nz, IvAccordion_ReturnHandled
	ld wa, (0x02477e:24)
	calr SndParam_ResolveOscEntry
	ld xde, xhl
	ld xwa, (xsp + 4)
	ld xbc, EVT_SOUND_SW_NO
	jrl IvAccordion_DispatchEvent

IvAccordion_PageSelect:
	ld xwa, (xsp + 4)
	ld xde, xiz
	call InheritedProc
	ld xwa, xiz
	srl xwa, 16
	ldiw_erp 0xe2, 0
	cp wa, 1:i3
	jrl nz, IvAccordion_ReturnHandled
	ld bc, (0x02477e:24)
	extz xbc
	ld wa, iz
	extz wa
	add wa, 0xd00
	extz xwa
	sll xwa, 16
	ld xde, xwa
	add xde, xbc
	ld xwa, NAKA_MAINFUNC_MainGetSoundName
	ld xbc, EVT_SET_SOUND_SW_NO
	call MainFuncCall
	jrl IvAccordion_ReturnHandled

IvAccordion_Update:
	ld xwa, (xsp + 4)
	ld xde, xiz
	call InheritedProc
	ld wa, iz
	ld bc, (0x02477e:24)
	cp bc, wa
	jrl nz, IvAccordion_ReturnHandled
	ld xwa, xiz
	srl xwa, 16
	ldiw_erp 0xe2, 0
	ld bc, wa
	srl bc, 8
	ld b, 0x0:opc
	cp c, 0xd
	jrl nz, IvAccordion_Update_NonNote
	cp a, 0xa
	jr nc, IvAccordion_Update_BellowsOn
	cpw (0x2477c:24), 0
	jr z, IvAccordion_Update_SendPartParam
	; object handle 0xeb0017 = class 0x0eb, instance 23 (SendEvent indexes its class table by bits 16-27; not an address -- was WidgetName_PtrBlock_A_0xF)
	ld xwa, WidgetName_PtrBlock_A_0xF
	ld xbc, EVT_HIDE
	ld xde, 5:i3
	call SendEvent
	ldw (0x02477c:24), 0x0000
	ldw (0x024780:24), 0x0000
	ld xwa, WidgetName_PtrBlock_A_0x1
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	jr IvAccordion_Update_CommitToggle

IvAccordion_Update_BellowsOn:
	cpw (0x2477c:24), 1
	jr z, IvAccordion_Update_SendPartParam
	; object handle 0xeb0009 = class 0x0eb, instance 9 (SendEvent indexes its class table by bits 16-27; not an address -- was WidgetName_PtrBlock_A_0x1)
	ld xwa, WidgetName_PtrBlock_A_0x1
	ld xbc, EVT_HIDE
	ld xde, 5:i3
	call SendEvent
	ldw (0x02477c:24), 0x0001
	ldw (0x024780:24), 0x0001
	ld xwa, WidgetName_PtrBlock_A_0xF
	ld xbc, EVT_SHOW
	ld xde, 5:i3

IvAccordion_Update_CommitToggle:
	call SendEvent

IvAccordion_Update_SendPartParam:
	ld xwa, xiz
	srl xwa, 16
	ldiw_erp 0xe2, 0
	extz wa
	ld de, wa
	extz xde
	add xde, 0x10000
	ld xwa, 0xffffffff
	ld xbc, EVT_YOU_ARE_SELECTED
	jr IvAccordion_Update_Dispatch

IvAccordion_Update_NonNote:
	ld xwa, 0xffffffff
	ld xbc, EVT_INTERRUPT_EXIT
	ld xde, 0:i3

IvAccordion_Update_Dispatch:
	call PostEvent
	jrl IvAccordion_ReturnHandled

IvAccordion_Match:
	ld xwa, (xsp + 4)
	ld xde, xiz
	call InheritedProc
	ld wa, (0x02477e:24)
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
	ld xbc, EVT_SOUND_SW_NO
	jr IvAccordion_DispatchEvent

IvAccordion_Refresh:
	ld xwa, (xsp + 4)
	ld xde, xiz
	call InheritedProc
	call GetPartSelect
	ld (0x02477e:24), hl
	sla hl, 2
	lda xwa, (0x03e9a0:24)
	ld	xde, (xwa+hl)
	; object handle 0xeb0007 = class 0x0eb, instance 7 (SendEvent indexes its class table by bits 16-27; not an address -- was WidgetName_InitPtrTable_0x15)
	ld xwa, WidgetName_InitPtrTable_0x15
	ld xbc, EVT_PARA_DRAW
	call SendEvent
	ld wa, (0x02477e:24)
	calr SndParam_ResolveOscEntry
	ld xde, xhl
	ld xwa, (xsp + 4)
	ld xbc, EVT_SOUND_SW_NO

IvAccordion_DispatchEvent:
	call SendEvent
	jr IvAccordion_ReturnHandled

IvAccordion_GetText:
	pushw	IvAccordion_GetText_Str_Acdn@hi16
	pushw	IvAccordion_GetText_Str_Acdn@lo16
	push	xiz
	call	Free_Compare2
	inc	8, xsp
IvAccordion_ReturnHandled:
	ld xhl, 0:i3
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
	cp xbc, EVT_GET_STRING
	jr z, AccordionX_GetText
	cp xbc, EVT_DRAW
	jr z, AccordionX_Paint
	cp xbc, EVT_I_AM_SELECTED
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
	srl xwa, 16
	ldiw_erp 0xe2, 0
	cp wa, 1:i3
	jr nz, StringCopyReturn
	ld xwa, 0xffffffff
	ld xbc, EVT_ACCORDION_TAB
	ld xde, (xsp + 4)
	call PostEvent
	jr StringCopyReturn

AccordionX_Paint:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call SendEvent
	jr StringCopyReturn

AccordionX_GetText:
	pushw	AccordionX_GetText_Str_Acdn@hi16
	pushw	AccordionX_GetText_Str_Acdn@lo16
	ld	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
StringCopyReturn:
	ld xhl, 0:i3

AccordionX_Epilogue:
	pop xiz
	inc 4, xsp
	ret

AcAccordionTabProc:
	lda xsp, (xsp - 12)
	push xiz
	ld xiz, xwa
	cp xbc, EVT_PARA_DRAW
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
	ld bc, 0:i3
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
	ld bc, 0:i3
	call DrawBox
	ld xhl, 0:i3

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
	cp xiz, EVT_GET_STRING
	jrl z, Sdtecd_GetText
	cp xiz, EVT_DRAW
	jr z, Sdtecd_Paint
	cp xiz, EVT_SHOW
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
	ld xbc, EVT_SET_PAGE
	ld xde, 1:i3
	call SendEvent
	jr Voice_InheritedProcCall

Sdtecd_InitCase3:
	ld	xwa, 851969
	ld	xbc, EVT_SET_PAGE
	ld	xde, 1:i3
	call	SendEvent
	ld	xwa, 16896
	call	AcApcToggleProc_Helper
	cp	hl, 0:i3
	jr	nz, Voice_InheritedProcCall
	ld	xwa, 16896
	ld	bc, 1:i3
	ld	de, 3:i3
	call	MainLswPut
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
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call SendEvent
	jr Sdtecd_ReturnZero

Sdtecd_GetText:
	pushw	Sdtecd_GetText_Str_TeCd@hi16
	pushw	Sdtecd_GetText_Str_TeCd@lo16
	ld	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
Sdtecd_ReturnZero:
	ld xhl, 0:i3

Sdtecd_Epilogue:
	pop xiz
	inc 8, xsp
	ret

IvSdtecd1Proc:
	dec	4, xsp
	push	xiz
	ld	xiz, xde
	ld	(xsp+4), xwa
	cp	xbc, EVT_GET_STRING
	jrl	z, Sdtecd1_GetText	; -> 0xF7E698
	cp	xbc, EVT_DRAW
	jrl	z, Sdtecd1_Paint	; -> 0xF7E67F
	cp	xbc, EVT_LSW_DATA
	jrl	z, Sdtecd1_Match	; -> 0xF7E653
	cp	xbc, EVT_INDEXSW_DOWN_AIC
	jrl	z, Sdtecd1_ScrollUp	; -> 0xF7E5C7
	cp	xbc, EVT_INDEXSW_DOWN
	jrl	z, Sdtecd1_ScrollUp	; -> 0xF7E5C7
	cp	xbc, EVT_INDEXSW_UP_AIC
	jr	z, Sdtecd1_ScrollDown	; -> 0xF7E53A
	cp	xbc, EVT_INDEXSW_UP
	jr	z, Sdtecd1_ScrollDown	; -> 0xF7E53A
	cp	xbc, EVT_PAINT
	jrl	nz, Sdtecd1_ForwardToBase	; -> 0xF7E6A9
	ld	xwa, (xsp+4)
	ld	xde, xiz
	call	InheritedProc
	ld	xwa, 16898
	call	AcApcToggleProc_Helper
	sla	hl, 2
	lda	xwa, (NakaInst_RIGHT_1_E9D9B0_0x1C:24)
	ld_rrl	xwa, xwa, hl
	ld	xbc, EVT_SET_DIAL_FOCUS
	ld	xde, 1:i3
	call	SendEvent
	ld	xwa, (xsp+4)
	ld	xbc, EVT_INDEXSW_DOWN
	ld	xde, 1:i3
	call	SetDialUp
	ld	xwa, (xsp+4)
	ld	xbc, EVT_INDEXSW_UP
	ld	xde, 1:i3
	call	SetDialDown
	ld	wa, 1:i3
	call	SetDialEnable
	jrl	IvSdtecd1_ReturnDefault	; -> 0xF7E6A5
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
	ld de, 3:i3
	call MainLswAdd
	ld xwa, (xsp + 4)
	ld xbc, EVT_INDEXSW_UP_AIC
	ld xde, xiz
	call SetAutoInc
	ld xwa, (xsp + 4)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, 1:i3
	call SetDialUp
	ld xwa, (xsp + 4)
	ld xbc, EVT_INDEXSW_UP
	ld xde, 1:i3
	call SetDialDown
	ld wa, 1:i3
	call SetDialEnable
	jrl IvSdtecd1_ReturnDefault

Sdtecd1_ScrollDown_Lookup:
	ld	xwa, 16898
	call	AcApcToggleProc_Helper
	ld	bc, hl
	ld	xwa, NakaInst_RIGHT_1_E9D9B0_0x54
	calr	SdpartLookupPartId
	ld	wa, hl
	inc	7, wa
	cp	wa, 13
	jrl	gt, IvSdtecd1_ReturnDefault
	inc	7, hl
	add	hl, hl
	lda	xwa, (NakaInst_RIGHT_1_E9D9B0_0x54:24)
	ld_rrw	bc, xwa, hl
	ld	xwa, 16898
	ld	de, 3:i3
	jrl	Sdtecd1_PutAndReturn
Sdtecd1_ScrollUp:
	ld xwa, (xsp + 4)
	ld xde, xiz
	call InheritedProc
	or xiz, xiz
	jr z, Sdtecd1_ScrollUp_Lookup
	cp xiz, 0x1
	jrl nz, IvSdtecd1_ReturnDefault
	ld xwa, 0x4202
	ld bc, 1:i3
	ld de, 3:i3
	call MainLswAdd
	ld xwa, (xsp + 4)
	ld xbc, EVT_INDEXSW_DOWN_AIC
	ld xde, xiz
	call SetAutoInc
	ld xwa, (xsp + 4)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, 1:i3
	call SetDialUp
	ld xwa, (xsp + 4)
	ld xbc, EVT_INDEXSW_UP
	ld xde, 1:i3
	call SetDialDown
	ld wa, 1:i3
	call SetDialEnable
	jrl IvSdtecd1_ReturnDefault

Sdtecd1_ScrollUp_Lookup:
	ld	xwa, 16898
	call	AcApcToggleProc_Helper
	ld	bc, hl
	ld	xwa, NakaInst_RIGHT_1_E9D9B0_0x54
	calr	SdpartLookupPartId
	ld	wa, hl
	sub	wa, 7
	jr	lt, IvSdtecd1_ReturnDefault
	dec	7, hl
	add	hl, hl
	lda	xwa, (NakaInst_RIGHT_1_E9D9B0_0x54:24)
	ld_rrw	bc, xwa, hl
	ld	xwa, 16898
	ld	de, 3:i3
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
	lda xbc, (NakaInst_RIGHT_1_E9D9B0_0x1C:24)
	ld	xwa, (xbc+wa)
	ld xbc, EVT_SET_DIAL_FOCUS
	ld xde, 1:i3
	jr Sdtecd1_SendEventReturn

Sdtecd1_Paint:
	ld xwa, (xsp + 4)
	ld xde, xiz
	call InheritedProc
	ld xwa, (xsp + 4)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3

Sdtecd1_SendEventReturn:
	call SendEvent
	jr IvSdtecd1_ReturnDefault

Sdtecd1_GetText:
	pushw	233
	pushw	55842
	push	xiz
	call	Free_Compare2
	inc	8, xsp
IvSdtecd1_ReturnDefault:
	ld xhl, 0:i3
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
	cp xbc, EVT_LSW_DATA_REQ
	jr z, LswOrch_ReturnZero
	cp xbc, EVT_GET_SMALL_STEP
	jr z, LswOrch_ReturnOne
	cp xbc, EVT_GET_LARGE_STEP
	jr z, LswOrch_ReturnOne
	cp xbc, EVT_GET_LSW_OUTPUT
	jr z, LswOrch_StepSize
	cp xbc, EVT_GET_LSW_ADDRESS
	jr z, LswOrch_SubParam
	cp xbc, EVT_GET_LSW_STRING
	jr nz, LswOrch_ReturnZero
	ld bc, (xde + 4)
	ld xwa, (xde + 8)
	cp bc, 0xff
	jr z, LswOrch_StrDefault
	sla bc, 2
	lda xde, (Naka_TechniChord1_Screens:24)
	ld	xbc, (xde+bc)
	push xbc
	jr LswOrch_StrCopyReturn

LswOrch_StrDefault:
	pushw LswOrch_StrDefault_Str_CONDUCTOR@hi16
	pushw LswOrch_StrDefault_Str_CONDUCTOR@lo16

LswOrch_StrCopyReturn:
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, xiz
	jr	LswOrchestra_PopIzRet
LswOrch_SubParam:
	ld xhl, 0x4201
	jr LswOrchestra_PopIzRet

LswOrch_StepSize:
	ld xhl, 3:i3
	jr LswOrchestra_PopIzRet

LswOrch_ReturnOne:
	ld xhl, 1:i3
	jr LswOrchestra_PopIzRet

LswOrch_ReturnZero:
	ld xhl, 0:i3

LswOrchestra_PopIzRet:
	pop xiz
	ret

PsLabelBoxProc:
	lda xsp, (xsp-276)
	push xiz
	ld	(xsp+272), xde
	ld	(xsp+276), xwa
	cp xbc, EVT_GET_STRING
	jrl z, PsLabel_GetText
	cp xbc, EVT_SET_DIAL_FOCUS
	jrl z, PsLabel_HandleWidget2
	cp xbc, EVT_SET_SELECTED
	jrl z, PsLabel_HandleWidget1
	cp xbc, EVT_INDEX_SELECT
	jrl z, PsLabel_Notify
	cp xbc, EVT_SELE_DRAW
	jrl z, PsLabel_Select
	cp xbc, EVT_PARA_DRAW
	jr z, PsLabel_Confirm
	cp xbc, EVT_DRAW
	jrl nz, PsLabel_ForwardToBase
	ld XWA, (xsp + 0x0114)
	ld XDE, (xsp + 0x0110)
	call InheritedProc
	ld XWA, (xsp + 0x0114)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0114)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl PsLabelBox_SendEvent_Continue

PsLabel_Confirm:
	lda xbc, (xsp+264)
	ld XWA, (xsp + 0x0114)
	call GetClientBox
	lda xwa, (xsp+264)
	lda xbc, (xsp+260)
	call GetBoxCenter
	ld XWA, (xsp + 0x0114)
	call GetViewInstance
	ld xiz, xhl
	lda xde, (xsp + 4)
	ld XWA, (xsp + 0x0110)
	or xwa, xwa
	jr nz, PsLabel_CopyDataStr
	ld XWA, (xsp + 0x0114)
	ld xbc, EVT_GET_STRING
	call SendEvent
	cp (xsp + 4), 0x0
	jr nz, PsLabel_DrawReverse
	jrl LswMaster_ReturnZeroJmp

PsLabel_CopyDataStr:
	ld	xwa, (xsp+272)
	push	xwa
	push	xde
	call	Free_Compare2
	inc	8, xsp
PsLabel_DrawReverse:
	lda xhl, (xsp+264)
	lda xbc, (xsp+260)
	lda xde, (xsp + 4)
	ld xwa, (xiz + 32)
	push xwa
	pushw	(xiz+36)
	pushw	(xiz+22)
	ld a, (xiz + 38)
	extz wa
	pushw wa
	ld xwa, (xiz + 44)
	pushw	(xwa)
	ld xwa, xhl
	call DrawStringReverse
	jrl LswMaster_ReturnZeroJmp

PsLabel_Select:
	ld XWA, (xsp + 0x0114)
	call GetViewInstance
	ld xwa, (xhl + 40)
	ld de, (xwa)
	exts xde
	ld XWA, (xsp + 0x0114)
	ld xbc, EVT_DRAW_SELECTED
	jrl PsLabelBox_SendEvent_Continue

PsLabel_Notify:
	ld XWA, (xsp + 0x0114)
	ld XDE, (xsp + 0x0110)
	call InheritedProc
	ld XWA, (xsp + 0x0114)
	call GetViewInstance
	ld xiz, xhl
	ld wa, (xiz + 26)
	exts xwa
	cp	xwa, (xsp+272)
	jrl nz, LswMaster_ReturnZeroJmp
	ld xwa, (xiz + 40)
	cpw (xwa), 0x0
	jr z, PsLabel_CheckSecondWidget
	ld XWA, (xsp + 0x0114)
	ld xbc, EVT_SET_SELECTED
	ld xde, 0:i3
	call SendEvent

PsLabel_CheckSecondWidget:
	ld xwa, (xiz + 44)
	cpw (xwa), 0x0
	jrl z, LswMaster_ReturnZeroJmp
	ld XWA, (xsp + 0x0114)
	ld xbc, EVT_SET_DIAL_FOCUS
	ld xde, 0:i3
	jrl PsLabelBox_SendEvent_Continue

PsLabel_HandleWidget1:
	ld XWA, (xsp + 0x0114)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 40)
	ld wa, (xwa)
	exts xwa
	cp	xwa, (xsp+272)
	jrl z, LswMaster_ReturnZeroJmp
	ld XWA, (xsp + 0x0110)
	cp wa, 1:i3
	jr nz, PsLabel_StoreWidget1
	ld de, (xiz + 26)
	exts xde
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEX_SELECT
	call SendEvent

PsLabel_StoreWidget1:
	ld xbc, (xiz + 40)
	ld XWA, (xsp + 0x0110)
	ld (xbc), wa
	ld XWA, (xsp + 0x0114)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	jr PsLabelBox_SendEvent_Continue

PsLabel_HandleWidget2:
	ld XWA, (xsp + 0x0114)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 44)
	ld wa, (xwa)
	exts xwa
	cp	xwa, (xsp+272)
	jr z, LswMaster_ReturnZeroJmp
	ld XWA, (xsp + 0x0110)
	cp wa, 1:i3
	jr nz, PsLabel_StoreWidget2
	ld de, (xiz + 26)
	exts xde
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEX_SELECT
	call SendEvent

PsLabel_StoreWidget2:
	ld xbc, (xiz + 44)
	ld XWA, (xsp + 0x0110)
	ld (xbc), wa
	ld XWA, (xsp + 0x0114)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3

PsLabelBox_SendEvent_Continue:
	call SendEvent
	jr LswMaster_ReturnZeroJmp

PsLabel_GetText:
	ld	xwa, (xsp+276)
	call	GetViewInstance
	ld	xwa, (xhl+28)
	push	xwa
	ld	xwa, (xsp+276)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
LswMaster_ReturnZeroJmp:
	ld xhl, 0:i3
	jr PsLabel_Epilogue

PsLabel_ForwardToBase:
	ld XWA, (xsp + 0x0114)
	ld XDE, (xsp + 0x0110)
	call InheritedProc

PsLabel_Epilogue:
	pop xiz
	lda xsp, (xsp+276)
	ret

LswMasterTuning:
	lda xsp, (xsp - 14)
	pushw iz
	ld (xsp + 8), xde
	ld xde, xbc
	ld (xsp + 12), xwa
	ld xiy, LswMasterTuning_Str_N440_0
	lda xix, (xsp + 2)
	ld bc, 3:i3
	ldirw
	cp xde, EVT_GET_INIT_DATA
	jrl z, StringOp_ReturnZero
	cp xde, EVT_CHECK_INIT_DATA
	jrl z, StringOp_ReturnOne
	cp xde, EVT_LSW_DATA_REQ
	jrl z, StringOp_ReturnZero
	cp xde, EVT_GET_SMALL_STEP
	jrl z, StringOp_ReturnOne
	cp xde, EVT_GET_LARGE_STEP
	jrl z, StringOp_ReturnOne
	cp xde, EVT_GET_LSW_OUTPUT
	jrl z, LswTuning_StepSize
	cp xde, EVT_GET_LSW_ADDRESS
	jrl z, StringOp_ReturnZero
	cp xde, EVT_GET_LSW_STRING
	jrl nz, StringOp_ReturnZero
	ld iz, 1:i3
	lda xde, (NakaInst_RIGHT_1_E9DB0C_0x14:24)
	ld xwa, (xsp + 8)
	ld bc, (xwa + 4)

LswTuning_SearchLoop:
	ld	wa, iz
	extz	xwa
	ld	xhl, xde
	add	xhl, xwa
	ld	a, (xhl)
	extz	wa
	cp	wa, bc
	jr	nz, LswTuning_SearchNext
	ld	wa, iz
	extz	xwa
	div	wa, 3
	add	wa, 27
	pushw	wa
	pushw	LswTuning_SearchLoop_Str_N4_Fmtd_0@hi16
	pushw	LswTuning_SearchLoop_Str_N4_Fmtd_0@lo16
	lda	xwa, (xsp+8)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	ld	wa, iz
	extz	xwa
	div	wa, 3
	ld	bc, qwa
	lda	xwa, (xsp+6)
	cp	bc, 2:i3
	jr	z, LswTuning_Octave6
	cp	bc, 1:i3
	jr	z, LswTuning_Octave3
	cp	bc, 0:i3
	jr	nz, StringOp_CopyCall
	ld	(xwa), 48
	jr	StringOp_CopyCall
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
	lda	xwa, (xsp+2)
	push	xwa
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, (xsp+12)
	jr	StringOp_ReturnPoint
LswTuning_StepSize:
	ld xhl, 3:i3
	jr StringOp_ReturnPoint

StringOp_ReturnOne:
	ld xhl, 1:i3
	jr StringOp_ReturnPoint

StringOp_ReturnZero:
	ld xhl, 0:i3

StringOp_ReturnPoint:
	popw iz
	lda xsp, (xsp + 14)
	ret

TtSdscltyp:
	cp xbc, EVT_REPAINT
	jr z, TtSdscltyp_ReturnZero
	cp xbc, EVT_PAINT
	jr z, TtSdscltyp_ReturnZero
	cp xbc, EVT_HIDE
	jr z, TtSdscltyp_ReturnZero
	cp xbc, EVT_SHOW
	jr nz, TtSdscltyp_ReturnZero
	or xde, xde
	jr nz, TtSdscltyp_ReturnZero
	ld xwa, 0x50001
	ld xbc, EVT_SET_PAGE
	ld xde, 1:i3
	call SendEvent
	ld xwa, 0x50007
	ld xbc, EVT_GET_INDEX
	ld xde, 0:i3
	call SendEvent
	ld xde, xhl
	ld xwa, 0x50005
	ld xbc, EVT_INDEX_SELECT
	call SendEvent
	ld xwa, 0x50007
	ld xbc, EVT_SET_SELECTED
	ld xde, 1:i3
	call SendEvent
	ldw (0x02478e:24), 0x0000

TtSdscltyp_ReturnZero:
	ld xhl, 0:i3
	ret

IvSdscltyp2Proc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, EVT_GET_STRING
	jrl z, Sdscltyp2_GetText
	cp xiz, EVT_DRAW
	jrl z, Sdscltyp2_Paint
	cp xiz, EVT_INDEXSW_DOWN_AIC
	jrl z, Sdscltyp2_ScrollUp
	cp xiz, EVT_INDEXSW_DOWN
	jrl z, Sdscltyp2_ScrollUp
	cp xiz, EVT_INDEXSW_UP_AIC
	jr z, Sdscltyp2_ScrollDown
	cp xiz, EVT_INDEXSW_UP
	jr z, Sdscltyp2_ScrollDown
	cp xiz, EVT_SHOW
	jrl nz, Sdscltyp2_ForwardToBase
	ld xwa, 0x50011
	ld xbc, EVT_GET_INDEX
	ld xde, 0:i3
	call SendEvent
	ld xde, xhl
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEX_SELECT
	call SendEvent
	ld wa, (0x02478e:24)
	sla wa, 2
	lda xbc, (NakaInst_RIGHT_1_E9DB0C_0x70:24)
	ld	xwa, (xbc+wa)
	ld xbc, EVT_SET_SELECTED
	ld xde, 1:i3
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
	ld wa, (0x02478e:24)
	cp wa, 0xb
	jr ge, Sdscltyp2_SetAutoIncDown
	inc 1, wa
	ld (0x02478e:24), wa
	ld xwa, 0x50011
	ld xbc, EVT_GET_INDEX
	ld xde, 0:i3
	call SendEvent
	ld xde, xhl
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEX_SELECT
	call SendEvent
	ld wa, (0x02478e:24)
	sla wa, 2
	lda xbc, (NakaInst_RIGHT_1_E9DB0C_0x70:24)
	ld	xwa, (xbc+wa)
	ld xbc, EVT_SET_SELECTED
	ld xde, 1:i3
	call SendEvent

Sdscltyp2_SetAutoIncDown:
	ld xwa, (xsp + 8)
	ld xbc, EVT_INDEXSW_UP_AIC
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
	ld wa, (0x02478e:24)
	cp wa, 0:i3
	jr le, Sdscltyp2_SetAutoIncUp
	dec 1, wa
	ld (0x02478e:24), wa
	ld xwa, 0x50011
	ld xbc, EVT_GET_INDEX
	ld xde, 0:i3
	call SendEvent
	ld xde, xhl
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEX_SELECT
	call SendEvent
	ld wa, (0x02478e:24)
	sla wa, 2
	lda xbc, (NakaInst_RIGHT_1_E9DB0C_0x70:24)
	ld	xwa, (xbc+wa)
	ld xbc, EVT_SET_SELECTED
	ld xde, 1:i3
	call SendEvent

Sdscltyp2_SetAutoIncUp:
	ld xwa, (xsp + 8)
	ld xbc, EVT_INDEXSW_DOWN_AIC
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
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call SendEvent
	jr IvSdscltyp2_ReturnZeroJmp

Sdscltyp2_GetText:
	pushw	Sdscltyp2_GetText_Str_Scl2@hi16
	pushw	Sdscltyp2_GetText_Str_Scl2@lo16
	ld	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
IvSdscltyp2_ReturnZeroJmp:
	ld xhl, 0:i3
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
	cp xbc, EVT_LSW_DATA_REQ
	jr z, LswScaleType_ReturnZero
	cp xbc, EVT_GET_SMALL_STEP
	jr z, LswScaleType_ReturnOne
	cp xbc, EVT_GET_LARGE_STEP
	jr z, LswScaleType_ReturnOne
	cp xbc, EVT_GET_LSW_OUTPUT
	jr z, LswScaleType_StepSize
	cp xbc, EVT_GET_LSW_ADDRESS
	jr z, LswScaleType_SubParam
	cp xbc, EVT_GET_LSW_STRING
	jr nz, LswScaleType_ReturnZero
	ld bc, (xiz + 4)
	ld xwa, NakaInst_RIGHT_1_E9DB0C_0xAA
	calr SdpartLookupPartId
	ld xbc, (xiz + 8)
	cp hl, 0xffff
	jr z, LswScaleType_StrDefault
	sla hl, 2
	lda xwa, (Naka_Scale2_Screens:24)
	ld	xwa, (xwa+hl)
	push xwa
	jr LswScaleType_StrCopyReturn

LswScaleType_StrDefault:
	pushw LswScaleType_StrDefault_Str_NO_TYPE@hi16
	pushw LswScaleType_StrDefault_Str_NO_TYPE@lo16

LswScaleType_StrCopyReturn:
	push	xbc
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, (xsp+4)
	jr	LswScaleType_PopIzSkip4Ret
LswScaleType_SubParam:
	ld xhl, 0x4281
	jr LswScaleType_PopIzSkip4Ret

LswScaleType_StepSize:
	ld xhl, 3:i3
	jr LswScaleType_PopIzSkip4Ret

LswScaleType_ReturnOne:
	ld xhl, 1:i3
	jr LswScaleType_PopIzSkip4Ret

LswScaleType_ReturnZero:
	ld xhl, 0:i3

LswScaleType_PopIzSkip4Ret:
	pop xiz
	inc 4, xsp
	ret

LswScalingShift:
	push	xiz
	ld	xiz, xwa
	cp	xbc, EVT_LSW_DATA_REQ
	jr	z, LswScaleShift_ReturnZero	; -> 0xF7ED65
	cp	xbc, EVT_GET_SMALL_STEP
	jr	z, LswScaleShift_ReturnOne	; -> 0xF7ED61
	cp	xbc, EVT_GET_LARGE_STEP
	jr	z, LswScaleShift_ReturnOne	; -> 0xF7ED61
	cp	xbc, EVT_GET_LSW_OUTPUT
	jr	z, LswScaleShift_StepSize	; -> 0xF7ED5D
	cp	xbc, EVT_GET_LSW_ADDRESS
	jr	z, LswScaleShift_SubParam	; -> 0xF7ED56
	cp	xbc, EVT_GET_LSW_STRING
	jr	nz, LswScaleShift_ReturnZero	; -> 0xF7ED65
	ld	wa, (xde+4)
	sla	wa, 2
	lda	xbc, (Scale_Arabic2_NameTable:24)
	ld_rrl	xwa, xbc, wa
	push	xwa
	ld	xwa, (xde+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, xiz
	jr	LswScaleSharp_PopIzRet	; -> 0xF7ED67
LswScaleShift_SubParam:
	ld xhl, 0x4282
	jr LswScaleSharp_PopIzRet

LswScaleShift_StepSize:
	ld xhl, 3:i3
	jr LswScaleSharp_PopIzRet

LswScaleShift_ReturnOne:
	ld xhl, 1:i3
	jr LswScaleSharp_PopIzRet

LswScaleShift_ReturnZero:
	ld xhl, 0:i3

LswScaleSharp_PopIzRet:
	pop xiz
	ret

LswScalingShift2:
	push	xiz
	ld	xiz, xwa
	cp	xbc, EVT_LSW_DATA_REQ
	jr	z, LswScaleShift2_ReturnZero	; -> 0xF7EDCA
	cp	xbc, EVT_GET_SMALL_STEP
	jr	z, LswScaleShift2_ReturnOne	; -> 0xF7EDC6
	cp	xbc, EVT_GET_LARGE_STEP
	jr	z, LswScaleShift2_ReturnOne	; -> 0xF7EDC6
	cp	xbc, EVT_GET_LSW_OUTPUT
	jr	z, LswScaleShift2_StepSize	; -> 0xF7EDC2
	cp	xbc, EVT_GET_LSW_ADDRESS
	jr	z, LswScaleShift2_SubParam	; -> 0xF7EDBB
	cp	xbc, EVT_GET_LSW_STRING
	jr	nz, LswScaleShift2_ReturnZero	; -> 0xF7EDCA
	ld	wa, (xde+4)
	sla	wa, 2
	lda	xbc, (Scale_Names_Table:24)
	ld_rrl	xwa, xbc, wa
	push	xwa
	ld	xwa, (xde+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, xiz
	jr	LswScaleSharp_PopIzRet2	; -> 0xF7EDCC
LswScaleShift2_SubParam:
	ld xhl, 0x4282
	jr LswScaleSharp_PopIzRet2

LswScaleShift2_StepSize:
	ld xhl, 3:i3
	jr LswScaleSharp_PopIzRet2

LswScaleShift2_ReturnOne:
	ld xhl, 1:i3
	jr LswScaleSharp_PopIzRet2

LswScaleShift2_ReturnZero:
	ld xhl, 0:i3

LswScaleSharp_PopIzRet2:
	pop xiz
	ret

LswScalingMode:
	push	xiz
	ld	xiz, xwa
	cp	xbc, EVT_LSW_DATA_REQ
	jr	z, LswScaleMode_ReturnZero	; -> 0xF7EE2F
	cp	xbc, EVT_GET_SMALL_STEP
	jr	z, LswScaleMode_ReturnOne	; -> 0xF7EE2B
	cp	xbc, EVT_GET_LARGE_STEP
	jr	z, LswScaleMode_ReturnOne	; -> 0xF7EE2B
	cp	xbc, EVT_GET_LSW_OUTPUT
	jr	z, LswScaleMode_StepSize	; -> 0xF7EE27
	cp	xbc, EVT_GET_LSW_ADDRESS
	jr	z, LswScaleMode_SubParam	; -> 0xF7EE20
	cp	xbc, EVT_GET_LSW_STRING
	jr	nz, LswScaleMode_ReturnZero	; -> 0xF7EE2F
	ld	wa, (xde+4)
	sla	wa, 2
	lda	xbc, (LswScalingMode_PtrTable:24)
	ld_rrl	xwa, xbc, wa
	push	xwa
	ld	xwa, (xde+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, xiz
	jr	LswScaleMode_PopIzRet	; -> 0xF7EE31
LswScaleMode_SubParam:
	ld xhl, 0x4280
	jr LswScaleMode_PopIzRet

LswScaleMode_StepSize:
	ld xhl, 3:i3
	jr LswScaleMode_PopIzRet

LswScaleMode_ReturnOne:
	ld xhl, 1:i3
	jr LswScaleMode_PopIzRet

LswScaleMode_ReturnZero:
	ld xhl, 0:i3

LswScaleMode_PopIzRet:
	pop xiz
	ret

LswScalingKeyX:
	dec	4, xsp
	push	xiz
	ld	xiz, xde
	ld	(xsp+4), xwa
	cp	xbc, EVT_GET_INIT_DATA
	jrl	z, LswScaleKeyX_ReturnRange
	cp	xbc, EVT_CHECK_INIT_DATA
	jrl	z, LswScaleKeyX_ReturnOne
	cp	xbc, EVT_LSW_DATA_REQ
	jrl	z, LswScaleKeyX_ReturnZero
	cp	xbc, EVT_GET_SMALL_STEP
	jrl	z, LswScaleKeyX_ReturnOne
	cp	xbc, EVT_GET_LARGE_STEP
	jrl	z, LswScaleKeyX_ReturnFour
	cp	xbc, EVT_GET_LSW_OUTPUT
	jrl	z, LswScaleKeyX_StepSize
	cp	xbc, EVT_GET_LSW_ADDRESS
	jr	z, LswScaleKeyX_FindFocus
	cp	xbc, EVT_GET_LSW_STRING
	jrl	nz, LswScaleKeyX_ReturnZero
	ld	hl, (xiz+4)
	exts	xhl
	ld	xwa, xhl
	ld	xbc, 201
	call	InitializeKubo_Helper
	add	xhl, 127
	sra	xhl, 8
	sub	xhl, 100
	ld	xwa, (xiz+8)
	or	xhl, xhl
	jr	z, LswScaleKeyX_StrZero
	push	xhl
	pushw	LswScalingKeyX_Str_Fmt4d@hi16
	pushw	LswScalingKeyX_Str_Fmt4d@lo16
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+12)
	jr	LswScaleKeyX_LoadReturn
LswScaleKeyX_StrZero:
	pushw	LswScaleKeyX_StrZero_Str_N0@hi16
	pushw	LswScaleKeyX_StrZero_Str_N0@lo16
	push	xwa
	call	Free_Compare2
	inc	8, xsp
LswScaleKeyX_LoadReturn:
	ld xhl, (xsp + 4)
	jr LswEnd_PopIzSkip4Ret

LswScaleKeyX_FindFocus:
	ld iz, 0:i3
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
	ld xhl, 0:i3
	jr LswEnd_PopIzSkip4Ret

LswScaleKeyX_StepSize:
	ld xhl, 3:i3
	jr LswEnd_PopIzSkip4Ret

LswScaleKeyX_ReturnFour:
	ld xhl, 4:i3
	jr LswEnd_PopIzSkip4Ret

LswScaleKeyX_ReturnOne:
	ld xhl, 1:i3
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
	cp xbc, EVT_GET_STRING
	jrl z, Softver_GetText
	cp xbc, EVT_DRAW
	jrl z, Softver_Paint
	cp xbc, EVT_REPAINT
	jr z, Softver_ShowHide
	cp xbc, EVT_PAINT
	jr z, Softver_ShowHide
	ld xwa, xiz
	call InheritedProc
	jrl	Softver_Epilogue

Softver_ShowHide:
	ld	xwa, xiz
	call	InheritedProc
	pushw	(0xeb7930:24)
	pushw	Softver_ShowHide_Str_Fmt4d@hi16
	pushw	Softver_ShowHide_Str_Fmt4d@lo16
	lda	xwa, (xsp+10)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	lda	xde, (xsp+4)
	ld	xwa, 0xf00001
	ld	xbc, EVT_PARA_DRAW
	call	SendEvent
	call	Boot_ParseTableDataTimestamp
	pushw	hl
	pushw	Softver_ShowHide_Str_Fmt4d_2@hi16
	pushw	Softver_ShowHide_Str_Fmt4d_2@lo16
	lda	xwa, (xsp+10)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	lda	xde, (xsp+4)
	ld	xwa, ParamPopup_DynamicAccomp_Skip
	ld	xbc, EVT_PARA_DRAW
	call	SendEvent
	call	Boot_GetSystemPointer
	pushw	hl
	pushw	Softver_ShowHide_Str_Fmt4d_3@hi16
	pushw	Softver_ShowHide_Str_Fmt4d_3@lo16
	lda	xwa, (xsp+10)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	lda	xde, (xsp+4)
	ld	xwa, 0xf00003
	ld	xbc, EVT_PARA_DRAW
	call	SendEvent
	call	Boot_ParseSubCPUTimestamp
	pushw	hl
	pushw	Softver_ShowHide_Str_Fmt4d_4@hi16
	pushw	Softver_ShowHide_Str_Fmt4d_4@lo16
	lda	xwa, (xsp+10)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	lda	xde, (xsp+4)
	ld	xwa, 0xf00004
	ld	xbc, EVT_PARA_DRAW
	jr	Softver_SendEvent
Softver_Paint:
	ld xwa, xiz
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3

Softver_SendEvent:
	call SendEvent
	jr Softver_ReturnZero

Softver_GetText:
	pushw	Softver_GetText_Str_Soft@hi16
	pushw	Softver_GetText_Str_Soft@lo16
	push	xde
	call	Free_Compare2
	inc	8, xsp
Softver_ReturnZero:
	ld xhl, 0:i3

Softver_Epilogue:
	pop xiz
	lda xsp, (xsp + 10)
	ret

IvMPverProc:
	lda xsp, (xsp - 10)
	push xiz
	ld xiz, xwa
	cp xbc, EVT_GET_STRING
	jr z, MPver_GetText
	cp xbc, EVT_DRAW
	jr z, MPver_Paint
	cp xbc, EVT_REPAINT
	jr z, MPver_ShowHide
	cp xbc, EVT_PAINT
	jr z, MPver_ShowHide
	ld xwa, xiz
	call InheritedProc
	jr MPver_Epilogue

MPver_ShowHide:
	ld	xwa, xiz
	call	InheritedProc
	call	Get_Firmware_Version
	extz	hl
	pushw	hl
	pushw	MPver_ShowHide_Str_Ver_Fmt2X@hi16
	pushw	MPver_ShowHide_Str_Ver_Fmt2X@lo16
	lda	xwa, (xsp+10)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	lda	xde, (xsp+4)
	ld	xwa, 15663114
	ld	xbc, EVT_PARA_DRAW
	jr	MPver_SendEvent
MPver_Paint:
	ld xwa, xiz
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3

MPver_SendEvent:
	call SendEvent
	jr MPver_ReturnZero

MPver_GetText:
	pushw	MPver_GetText_Str_MPv@hi16
	pushw	MPver_GetText_Str_MPv@lo16
	push	xde
	call	Free_Compare2
	inc	8, xsp
MPver_ReturnZero:
	ld xhl, 0:i3

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
	cp xiz, EVT_DRAW
	jrl z, AcWelcomScreen_Paint
	cp xiz, EVT_MP_VERSION
	jrl z, AcWelcomScreen_SubCpuLoaded
	cp xiz, EVT_ALL_INITIAL
	jrl z, AcWelcomScreen_SubCpuError
	cp xiz, EVT_SELE_DRAW
	jrl z, AcWelcomScreen_Select
	cp xiz, EVT_REPAINT
	jrl z, AcWelcomScreen_ShowHide
	cp xiz, EVT_PAINT
	jrl z, AcWelcomScreen_ShowHide
	cp xiz, EVT_ALL_PAINT
	jrl z, AcWelcomScreen_Activate
	cp xiz, EVT_HIDE
	jr z, AcWelcomScreen_Close
	cp xiz, EVT_SHOW
	jrl nz, AcWelcomScreen_ForwardToBase
	ld wa, 1:i3
	call ChangePalette
	call Get_Region_Code
	ld xwa, Bitmap_DigitD_0x8DA
	cp l, 2:i3
	jr nz, AcWelcomScreen_Init_StoreData
	ld xwa, Bitmap_DigitD_0x22

AcWelcomScreen_Init_StoreData:
	ld (0x024786:24), xwa
	ld xwa, (xsp + 20)
	ld xbc, xiz
	ld xde, (xsp + 16)
	call InheritedProc
	call Boot_GetButtonComboCode
	cp l, 2:i3
	jr nz, AcWelcomScreen_Init_CheckSubCpu
	ld xwa, 0xffffffff
	ld xbc, EVT_MP_VERSION
	ld xde, 0:i3
	jr AcWelcomScreen_Init_DispatchTimer

AcWelcomScreen_Init_CheckSubCpu:
	call SubCPU_Payload_GetErrorFlag
	cp hl, 0:i3
	jr ge, AcWelcomScreen_Init_SwitchMode
	ld xwa, 0xffffffff
	ld xbc, EVT_ALL_INITIAL
	ld xde, 0:i3

AcWelcomScreen_Init_DispatchTimer:
	call PostEvent
	jrl AcWelcomScreen_ReturnHandled

AcWelcomScreen_Init_SwitchMode:
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_KEEP
	ld xde, 1:i3
	jrl AcWelcomScreen_DispatchEvent

AcWelcomScreen_Close:
	ld xwa, EVT_SELE_DRAW
	push xwa
	ld xwa, 0:i3
	push xwa
	ld xwa, 1:i3
	ld xbc, (xsp + 28)
	ld xde, (xsp + 28)
	call KillApTimer
	ld xwa, (xsp + 20)
	ld xbc, xiz
	ld xde, (xsp + 16)
	call InheritedProc
	ld wa, 2:i3
	call ChangePalette
	jrl AcWelcomScreen_ReturnHandled

AcWelcomScreen_Activate:
	call CheckNotDrawFlag
	cp hl, 0:i3
	jr z, AcWelcomScreen_Activate_Setup
	call LcdOff
	ld xwa, Bitmap_DigitD_0x11CE
	ld bc, 0:i3
	call DrawBox
	ld wa, 1:i3
	call SetNeedUpdate
	call UpdateScreen
	ld wa, 0:i3
	call SetNeedUpdate
	call LcdOn

AcWelcomScreen_Activate_Setup:
	ld xwa, (xsp + 20)
	ld xbc, xiz
	ld xde, (xsp + 16)
	call InheritedProc
	call CheckNotDrawFlag
	cp hl, 0:i3
	jrl z, AcWelcomScreen_ReturnHandled
	call PaletteBankRotate
	ldw (0x024784:24), 0x0001
	ld xbc, (0x024786:24)
	ld xwa, EVT_SELE_DRAW
	push xwa
	ld xwa, 0:i3
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
	ld bc, (0x024784:24)
	exts xbc
	ld xwa, xbc
	add xwa, xwa
	add xwa, xbc
	sll xwa, 2
	ld xbc, (0x024786:24)
	add xwa, xbc
	ld xbc, xwa
	ld hl, (xwa + 8)
	lda xiy, (xwa + 4)
	lda xde, (xwa + 10)
	cp hl, 0:i3
	jrl mi, AcWelcomScreen_Select_NextStep
	cp hl, 0xc
	jrl gt, AcWelcomScreen_Select_NextStep
	add hl, hl
	lda xix, (Bitmap_DigitD_0x11D6:24)
	ld	hl, (xix+hl)
	lda xix, (AcWelcomScreen_RenderBytecode:24)
	jp	t, (xix+hl)
AcWelcomScreen_RenderBytecode:
	ld	xwa, 0xffffffff
	ld	xbc, EVT_SET_KEEP
	ld	xde, 0:i3
	jrl	AcWelcomScreen_DispatchEvent
	ld	iz, (xbc+10)
	cp	iz, 2:i3
	jrl	ge, AcWelcomScreen_Select_NextStep
	ld	bc, iz
	muls	bc, 12
	lda	xwa, (0x03ea0c:24)
	lda_rr	xwa, xwa, bc	; lda xwa, xwa+bc
	cpw	(xwa+10), 65535
	jr	z, AcWelcomScreen_RenderBytecode_Skip
	cp	iz, 65535
	jr	z, AcWelcomScreen_RenderBytecode_Skip
	lda	xiy, (xwa+4)
	lda	xix, (xsp+12)
	ldiw
	ldiw
	lda	xwa, (xsp+12)
	ldw	bc, 30
	call	ClipBlit_Direct
AcWelcomScreen_RenderBytecode_Skip:
	ld	wa, (0x024784:24)
	exts	xwa
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	sll	xbc, 2
	add	xbc, (0x024786:24)
	lda	xiy, (xbc+4)
	lda	xix, (xsp+12)
	ldiw
	ldiw
	lda	xwa, (xsp+12)
	ldw	bc, 30
	call	ClipBlit_Replace
	cp	iz, 65535
	jrl	z, AcWelcomScreen_Select_NextStep
	muls	iz, 12
	lda	xwa, (0x03ea0c:24)
	ld	bc, (0x024784:24)
	exts	xbc
	ld	xiy, xbc
	add	xiy, xiy
	add	xiy, xbc
	sll	xiy, 2
	add	xiy, (0x024786:24)
	lda_rr	xix, xwa, iz	; lda xix, xwa+iz
	ld	bc, 6:i3
	ldirw
	jrl	AcWelcomScreen_Select_NextStep
	ld	xwa, (xsp+20)
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	SendEvent
	jrl	AcWelcomScreen_Select_NextStep
	lda	xix, (xsp+12)
	ldiw
	ldiw
	lda	xwa, (xsp+12)
	pushw	17
	pushw	(xde)
	pushw	247
	ld	xbc, NakaInst_TOTAL_0x34
	ldw	de, 16
	jrl	Softver_ShowHide_Code_Join
	lda	xix, (xsp+12)
	ldiw
	ldiw
	lda	xwa, (xsp+12)
	pushw	17
	pushw	(xde)
	pushw	247
	ld	xbc, Bitmap_DigitL_0x44
	ldw	de, 16
	jrl	Softver_ShowHide_Code_Join
	lda	xix, (xsp+12)
	ldiw
	ldiw
	lda	xwa, (xsp+12)
	pushw	17
	pushw	(xde)
	pushw	247
	ld	xbc, Bitmap_DigitL
	ldw	de, 16
	jr	Softver_ShowHide_Code_Join
	lda	xix, (xsp+12)
	ldiw
	ldiw
	lda	xwa, (xsp+12)
	pushw	17
	pushw	(xde)
	pushw	247
	ld	xbc, Bitmap_DigitD
	ldw	de, 16
	jr	Softver_ShowHide_Code_Join
	lda	xix, (xsp+12)
	ldiw
	ldiw
	lda	xwa, (xsp+12)
	pushw	17
	pushw	(xde)
	pushw	247
	ld	xbc, Bitmap_DigitR
	ldw	de, 16
	jr	Softver_ShowHide_Code_Join
	lda	xiy, (xbc+4)
	lda	xix, (xsp+12)
	ldiw
	ldiw
	lda	xwa, (xsp+12)
	pushw	17
	pushw	255
	pushw	247
	ld	xbc, Bitmap_Digit1
	ldw	de, 16
	call	DrawBitmapSP2
	lda	xwa, (xsp+12)
	addw	(xwa), 0x10
	pushw	17
	pushw	255
	pushw	247
	ld	xbc, Bitmap_DigitL_0x22
	ldw	de, 16
Softver_ShowHide_Code_Join:
	call	DrawBitmapSP2
	jrl	AcWelcomScreen_Select_NextStep
	lda	xhl, (0x03ea24:24)
	cpw	(xhl+10), 65535
	jr	z, Softver_ShowHide_Code_Skip2
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
	ld	bc, (0x24784:24)
	exts	xbc
	ld	xde, xbc
	add	xde, xde
	add	xde, xbc
	sll	xde, 2
	ld	xbc, (0x24786:24)
	add	xde, xbc
	cpw	(xde+8), 12
	jr	nz, Softver_ShowHide_Code_Skip
	addw	(xhl), 0x10
Softver_ShowHide_Code_Skip:
	ldw	bc, 245
	call	DrawBox
Softver_ShowHide_Code_Skip2:
	ld	wa, (0x024784:24)
	exts	xwa
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	sll	xbc, 2
	add	xbc, (0x024786:24)
	lda	xiy, (xbc+4)
	lda	xix, (xsp+12)
	ldiw
	ldiw
	lda	xwa, (xsp+12)
	pushw	17
	ld	bc, (0x024784:24)
	exts	xbc
	ld	xde, xbc
	add	xde, xde
	add	xde, xbc
	sll	xde, 2
	add	xde, (0x024786:24)
	pushw	(xde+10)
	pushw	247
	ld	xbc, NakaInst_TOTAL_0x34
	ldw	de, 16
	call	DrawBitmapSP2
	lda	xwa, (xsp+12)
	addw	(xwa), 0x10
	pushw	17
	ld	bc, (0x024784:24)
	exts	xbc
	ld	xde, xbc
	add	xde, xde
	add	xde, xbc
	sll	xde, 2
	add	xde, (0x024786:24)
	pushw	(xde+10)
	pushw	247
	ld	xbc, Bitmap_DigitL_0x44
	ldw	de, 16
	call	DrawBitmapSP2
	lda	xwa, (xsp+12)
	addw	(xwa), 0x10
	pushw	17
	ld	bc, (0x024784:24)
	exts	xbc
	ld	xde, xbc
	add	xde, xde
	add	xde, xbc
	sll	xde, 2
	add	xde, (0x024786:24)
	pushw	(xde+10)
	pushw	247
	ld	xbc, Bitmap_DigitL
	ldw	de, 16
	call	DrawBitmapSP2
	lda	xwa, (xsp+12)
	addw	(xwa), 0x10
	pushw	17
	ld	bc, (0x024784:24)
	exts	xbc
	ld	xde, xbc
	add	xde, xde
	add	xde, xbc
	sll	xde, 2
	add	xde, (0x024786:24)
	pushw	(xde+10)
	pushw	247
	ld	xbc, Bitmap_DigitL_0x44
	ldw	de, 16
	call	DrawBitmapSP2
	ld	wa, (0x024784:24)
	exts	xwa
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	sll	xbc, 2
	ld	xwa, (0x024786:24)
	add	xbc, xwa
	cpw	(xbc+8), 12
	jr	nz, Softver_ShowHide_Code_Skip3
	lda	xwa, (xsp+12)
	addw	(xwa), 0x10
	pushw	17
	ld	bc, (0x024784:24)
	exts	xbc
	ld	xde, xbc
	add	xde, xde
	add	xde, xbc
	sll	xde, 2
	ld	xbc, (0x024786:24)
	add	xde, xbc
	pushw	(xde+10)
	pushw	247
	ld	xbc, Bitmap_DigitD
	ldw	de, 16
	call	DrawBitmapSP2
Softver_ShowHide_Code_Skip3:
	lda	xwa, (xsp+12)
	addw	(xwa), 0x10
	pushw	17
	ld	bc, (0x024784:24)
	exts	xbc
	ld	xde, xbc
	add	xde, xde
	add	xde, xbc
	sll	xde, 2
	add	xde, (0x024786:24)
	pushw	(xde+10)
	pushw	247
	ld	xbc, Bitmap_DigitR
	ldw	de, 16
	call	DrawBitmapSP2
	ld	wa, (0x024784:24)
	exts	xwa
	ld	xiy, xwa
	add	xiy, xiy
	add	xiy, xwa
	sll	xiy, 2
	add	xiy, (0x024786:24)
	ld	xix, 0x03ea24
	ld	bc, 6:i3
	ldirw
	jr	AcWelcomScreen_Select_NextStep
	ld	xwa, NAKA_APFUNC_ApTaskControl
	ld	xbc, EVT_SLEEP_MAIN_TASK
	ld	xde, 0:i3
	call	ApFuncCall
	call	CaptureLcd
	ld	xwa, NAKA_APFUNC_ApTaskControl
	ld	xbc, EVT_WAKE_UP_MAIN_TASK
	ld	xde, 0:i3
	call	ApFuncCall

AcWelcomScreen_Select_NextStep:
	ld wa, (0x024784:24)
	inc 1, wa
	ld (0x024784:24), wa
	exts xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 2
	add xbc, (0x24786:24)
	ld xwa, (xbc)
	or xwa, xwa
	jrl z, AcWelcomScreen_Select
	ld xbc, EVT_SELE_DRAW
	push xbc
	ld xbc, 0:i3
	push xbc
	ld xbc, (xsp + 28)
	ld xde, (xsp + 28)

AcWelcomScreen_Select_StartTimer:
	call SetApTimer
	jr AcWelcomScreen_ReturnHandled

AcWelcomScreen_SubCpuError:
	ld	xwa, (xsp+20)
	ld	xbc, xiz
	ld	xde, (xsp+16)
	call	InheritedProc
	ld	xwa, 15663108
	ld	xbc, EVT_SHOW
	ld	xde, 3:i3
	jr	AcWelcomScreen_DispatchEvent
AcWelcomScreen_SubCpuLoaded:
	ld	xwa, (xsp+20)
	ld	xbc, xiz
	ld	xde, (xsp+16)
	call	InheritedProc
	ld	xwa, 15663111
	ld	xbc, EVT_SHOW
	ld	xde, 3:i3
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
	ld xhl, 0:i3
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
	cp xbc, EVT_GET_STRING
	jrl z, PsMixer_ControlCommon
	ld xwa, (xsp + 86)
	cp xwa, EVT_PART_SELECT
	jrl z, PsMixer_ControlCase9
	cp xwa, EVT_INDEXSW_BOTH
	jrl z, PsMixer_ControlCase8
	cp xwa, EVT_SW_BOTH
	jrl z, PsMixer_ControlCase7
	cp xwa, EVT_SW_IN_AIC
	jrl z, PsMixer_ControlCase6
	cp xwa, EVT_SW_IN
	jrl z, PsMixer_ControlCase5
	cp xwa, EVT_REFRESH_PARA_DRAW
	jrl z, PsMixer_ControlCase4
	cp xwa, EVT_DRAW
	jrl z, PsMixer_ControlCase3
	cp xwa, EVT_REPAINT
	jrl z, PsMixer_ControlCase2
	cp xwa, EVT_PAINT
	jrl z, PsMixer_ControlCase2
	cp xwa, EVT_HIDE
	jrl z, PsMixer_ControlCase1
	cp xwa, EVT_SHOW
	jr z, PsMixer_ControlHandler
	sub xbc, EVT_INDEXSW_UP
	cp xbc, 0x0
	jrl lt, PsMixer_ControlReturn
	cp xbc, 0x9
	jrl gt, PsMixer_ControlReturn
	add xbc, xbc
	add xbc, TrackName4_Tr1_0x2E
	ld bc, (xbc)
	lda xix, (PsMixer_ControlHandler:24)
; Computed jump: target = PsMixer_ControlHandler + TrackName4_Tr1_0x2E[i], TrackName4_Tr1_0x2E = 16-bit offsets (10 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1c00017:
;   0x1c00017 -> PsMixer_ControlCase8
;   0x1c00018 -> PsMixer_ControlCase8
;   0x1c00019 -> PsMixer_ControlCase8
;   0x1c0001a -> PsMixer_ControlCase8
;   0x1c0001b -> PsMixer_ControlReturn
;   0x1c0001c -> PsMixerControlProc_Evt1C0001C
;   0x1c0001d -> PsMixer_ControlReturn
;   0x1c0001e -> PsMixerControlProc_Evt1C0001E
;   0x1c0001f -> PsMixer_ControlReturn
;   0x1c00020 -> PsMixerControlProc_Evt1C00020
	jp	t, (xix+bc)

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
	ld xbc, EVT_SET_KEEP
	ld xde, 1:i3
	call SendEvent
	call GetPartSelect
	ld (0x02478a:24), hl

AudioCtrl_InitCounters:
	ldw (0x024794:24), 0x0000
	ldw (0x024790:24), 0x0000
	ldw (0x024796:24), 0x0000
	ldw (0x024792:24), 0x0000
	ldw (xsp + 10), 0x0

AudioCtrl_ScanLoop:
	ld wa, (xsp + 10)
	calr Util_SignExtendAndDouble
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	cpw (xwa + 6), 0x1
	jr nz, AudioCtrl_ScanNext
	ld wa, (xsp + 10)
	ld (0x024792:24), wa
	jr AudioCtrl_MainFuncCallPt

AudioCtrl_ScanNext:
	incw 1, (xsp + 10)
	cpw (xsp + 10), 0x5
	jr c, AudioCtrl_ScanLoop
	jr AudioCtrl_MainFuncCallPt

AudioCtrl_SendB3Event:
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_KEEP
	ld xde, 1:i3
	call SendEvent

AudioCtrl_MainFuncCallPt:
	ld xwa, NAKA_MAINFUNC_MainTitleControl
	ld xbc, EVT_OTHER_PART_LED
	ld xde, 1:i3
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
	ld xwa, NAKA_MAINFUNC_MainPmanControl
	ld xbc, EVT_PART_SELECT_PUT
	ld xde, 0x3f
	jr PsMixer_Case1_MainFuncCall

PsMixer_Case1_PartSelect:
	ld de, (0x02478a:24)
	extz xde
	ld xwa, NAKA_MAINFUNC_MainPmanControl
	ld xbc, EVT_PART_SELECT_PUT

PsMixer_Case1_MainFuncCall:
	call MainFuncCall

PsMixer_Case1_ReturnAB:
	ld xwa, NAKA_MAINFUNC_MainTitleControl
	ld xbc, EVT_OTHER_PART_LED
	ld xde, 0:i3
	call MainFuncCall
	jrl AudioCtrl_ReturnZero

; PsMixer control case 2
PsMixer_ControlCase2:
	ld xwa, (xsp + 90)
	ld xbc, (xsp + 86)
	ld xde, (xsp + 82)
	call InheritedProc
	ld bc, (0x024792:24)
	extz xbc
	ld wa, (0x024790:24)
	extz xwa
	sll xwa, 16
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 90)
	ld xbc, EVT_INDEXSW_UP
	call SetDialUp
	ld bc, (0x024792:24)
	extz xbc
	ld wa, (0x024790:24)
	extz xwa
	sll xwa, 16
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 90)
	ld xbc, EVT_INDEXSW_DOWN
	call SetDialDown
	ld wa, 1:i3
	call SetDialEnable
	call GetPartSelect
	extz xhl
	ld xwa, 0xffffffff
	ld xbc, EVT_PART_SELECT
	ld xde, xhl
	jrl PsMixer_SendEventAndForward

; PsMixer control case 3
PsMixer_ControlCase3:
	ld xwa, (xsp + 90)
	ld xbc, (xsp + 86)
	ld xde, (xsp + 82)
	call InheritedProc
	ld xwa, (xsp + 90)
	ld xbc, EVT_REFRESH_PARA_DRAW
	ld xde, 0:i3
	jrl PsMixer_SendEventAndForward

; PsMixer control case 4
PsMixer_ControlCase4:
	ld wa, (0x024796:24)
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
; PsMixer control-type procedure table Bitmap_DigitD_0x11F0 (v7 0xE9F11C, 11 x 32-bit, read from
;   the ROM by scripts/renaming/uiproc_psmixer_ctltypes.py), indexed by word +2 of the control's record:
;    0 -> PsMixer_CtlTypeProc0
;    1 -> PsMixer_CtlTypeProc1
;    2 -> PsMixer_CtlTypeProc2
;    3 -> PsMixer_CtlTypeProc3
;    4 -> PsMixer_CtlTypeProc4
;    5 -> PsMixer_CtlTypeProc5
;    6 -> PsMixer_CtlTypeProc6
;    7 -> PsMixer_CtlTypeProc7
;    8 -> PsMixer_CtlTypeProc8
;    9 -> PsMixer_CtlTypeProc9
;   10 -> PsMixer_CtlTypeProc10
	lda xbc, (Bitmap_DigitD_0x11F0:24)
	lda	xhl, (xbc+wa)
	ld xwa, (xsp + 90)
	ld xbc, EVT_DRAW
	ld xhl, (xhl)
	call (xhl)
	ld de, (xsp + 8)
	lda xbc, (Bitmap_DigitD_0x11F0:24)
	extz xde
	ld xwa, (xsp + 4)
	ld wa, (xwa + 2)
	sla wa, 2
	lda	xhl, (xbc+wa)
	ld wa, (0x024792:24)
	cp wa, (xsp + 8)
	jr nz, PsMixer_EventCallback
	add xde, 0x10000
	ld xwa, (xsp + 90)
	ld xbc, EVT_SELE_DRAW
	ld xhl, (xhl)
	call (xhl)
	jr PsMixer_GridSetup

; PsMixer event callback dispatch
PsMixer_EventCallback:
	ld xwa, (xsp + 90)
	ld xbc, EVT_SELE_DRAW
	ld xhl, (xhl)
	call (xhl)

PsMixer_GridSetup:
	ld iz, (0x024794:24)
	sla iz, 3
	ldw (xsp + 12), 0x0

; PsMixer grid loop handler
PsMixer_GridLoop:
	ld bc, (xsp + 8)
	extz xbc
	ld wa, iz
	extz xwa
	sll xwa, 16
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 4)
	ld wa, (xwa + 2)
	sla wa, 2
	lda xbc, (Bitmap_DigitD_0x11F0:24)
	lda	xhl, (xbc+wa)
	ld xwa, (xsp + 90)
	ld xbc, EVT_PARA_DRAW
	ld xhl, (xhl)
	call (xhl)
	inc 1, iz
	incw 1, (xsp + 12)
	cpw (xsp + 12), 0x8
	jr c, PsMixer_GridLoop
	incw 1, (xsp + 8)
	incw 1, (xsp + 10)
	cpw (xsp + 10), 0x5
	jrl c, PsMixer_ControlHelper
	ld wa, (0x024790:24)
	calr PsMixer_ReadWordArrayEntry
	ldfr_werp HL, 0xfa
	ldto_werp WA, 0xfa
	add wa, wa
	lda xbc, (MixerPartTable_Start_0x12C:24)
	ld	de, (xbc+wa)
	exts xde
	ld xwa, NAKA_MAINFUNC_MainGetSoundName
	ld xbc, EVT_GET_SOUND_NAME
	call FuncCall
	jrl AudioCtrl_ReturnZero
PsMixerControlProc_Evt1C0001E:
	ld xwa, (xsp + 90)
	ld xbc, (xsp + 86)
	ld xde, (xsp + 82)
	call InheritedProc
	ld xwa, (xsp + 82)
	dec 1, wa
	ld (0x024796:24), wa
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
	ld (0x024792:24), wa
	jr PsMixer_ShowEventAndForward

PsMixer_FindActiveNext:
	incw 1, (xsp + 8)
	incw 1, (xsp + 10)
	cpw (xsp + 10), 0x5
	jr c, PsMixer_FindActiveLoop

PsMixer_ShowEventAndForward:
	ld xwa, 0xffffffff
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	jrl PsMixer_SendEventAndForward

; PsMixer control case 5
PsMixer_ControlCase5:
	ld xwa, 0x2600024
	ld xbc, EVT_MAKE_EDIT_SW_ID
	ld xde, (xsp + 82)
	call SendEvent
	ld iz, hl
	cp iz, 7:i3
	jrl gt, AudioCtrl_DispatchHandler
	ld wa, (0x024794:24)
	sla wa, 3
	add iz, wa
	cp iz, (0x24790:24)
	jrl z, PsMixer_Case5_DialSetup
	ld wa, iz
	calr PsMixer_ReadWordArrayEntry
	extz xhl
	add xhl, xhl
	ld xbc, MixerPartTable_Start_0x12C
	add xbc, xhl
	ld de, (xbc)
	exts xde
	ld xwa, NAKA_MAINFUNC_MainPmanControl
	ld xbc, EVT_PART_SELECT_PUT
	call MainFuncCall
	ld bc, (0x024792:24)
	extz xbc
	ld wa, iz
	extz xwa
	sll xwa, 16
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 90)
	ld xbc, EVT_INDEXSW_UP
	call SetDialUp
	ld bc, (0x024792:24)
	extz xbc
	ld wa, iz
	extz xwa
	sll xwa, 16
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 90)
	ld xbc, EVT_INDEXSW_DOWN
	call SetDialDown
	ld wa, 1:i3
	call SetDialEnable
	ld (0x024790:24), iz
	ld xwa, (xsp + 90)
	ld xbc, EVT_REFRESH_PARA_DRAW
	ld xde, 0:i3
	call SendEvent
	ld wa, (0x024790:24)
	calr PsMixer_ReadWordArrayEntry
	extz xhl
	add xhl, xhl
	ld xbc, MixerPartTable_Start_0x12C
	add xbc, xhl
	ld de, (xbc)
	exts xde
	ld xwa, NAKA_MAINFUNC_MainGetSoundName
	ld xbc, EVT_GET_SOUND_NAME
	call FuncCall
	jr PsMixer_Case5_SetAutoInc

PsMixer_Case5_DialSetup:
	ld wa, iz
	ld bc, (0x024792:24)
	extz xbc
	extz xwa
	sll xwa, 16
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 82)
	bit 7, wa
	jr z, PsMixer_Case5_DialUp
	ld xwa, (xsp + 90)
	ld xbc, EVT_INDEXSW_DOWN
	jr PsMixer_Case5_SendEvent

PsMixer_Case5_DialUp:
	ld xwa, (xsp + 90)
	ld xbc, EVT_INDEXSW_UP

PsMixer_Case5_SendEvent:
	call SendEvent

PsMixer_Case5_SetAutoInc:
	ld xwa, (xsp + 90)
	ld xbc, EVT_SW_IN_AIC
	ld xde, (xsp + 82)
	call SetAutoInc
	jrl AudioCtrl_ReturnToCallerExit

; Audio controller dispatch handler
AudioCtrl_DispatchHandler:
	cp iz, 0x88
	jrl lt, AudioCtrl_PageHandler
	cp iz, 0x8c
	jrl gt, AudioCtrl_PageHandler
	ld wa, (0x024796:24)
	muls wa, 0x5
	ld (xsp + 8), iz
	submi16 (xsp + 8), 0x88
	add (xsp + 8), wa
	ld wa, (xsp + 8)
	cp wa, (0x24792:24)
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
	lda xbc, (Bitmap_DigitD_0x11F0:24)
	lda	xhl, (xbc+wa)
	ld xwa, (xsp + 90)
	ld xbc, EVT_SELE_DRAW
	ld xhl, (xhl)
	call (xhl)
	ld wa, (0x024792:24)
	calr Util_SignExtendAndDouble
	ld (xsp + 4), xhl
	ld de, (0x024792:24)
	extz xde
	ld xwa, (xsp + 4)
	ld wa, (xwa + 2)
	sla wa, 2
	lda xbc, (Bitmap_DigitD_0x11F0:24)
	lda	xhl, (xbc+wa)
	ld xwa, (xsp + 90)
	ld xbc, EVT_SELE_DRAW
	ld xhl, (xhl)
	call (xhl)
	ld wa, (xsp + 8)
	ld (0x024792:24), wa
	ld bc, (xsp + 8)
	extz xbc
	ld wa, (0x024790:24)
	extz xwa
	sll xwa, 16
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 90)
	ld xbc, EVT_INDEXSW_UP
	call SetDialUp
	ld bc, (0x024792:24)
	extz xbc
	ld wa, (0x024790:24)
	extz xwa
	sll xwa, 16
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 90)
	ld xbc, EVT_INDEXSW_DOWN
	call SetDialDown
	ld wa, 1:i3
	call SetDialEnable
	ld xwa, (xsp + 90)
	ld xbc, EVT_REFRESH_PARA_DRAW
	ld xde, 0:i3
	jrl PsMixer_SendEventAndForward

AudioCtrl_PageHandler:
	ld XWA,(XSP+0x52)
	cp XWA,0x0000008f
	jrl	nz, AudioCtrl_CheckEventF
	incw	8, (0x024790:24)
	incw	1, (0x024794:24)
	ld	wa, (0x024790:24)
	calr	PsMixer_ReadWordArrayEntry
	ld	qiz, hl
	cpw	qiz, 255
	jr	z, AudioCtrl_PageAdvance
	ld	xwa, 192
	call	AcApcToggleProc_Helper
	cp	hl, 1:i3
	scc	z, bc
	cpw	(0x024794:24), 2
	scc	z, wa
	and	wa, bc
	jr	z, AudioCtrl_SetupPartDisplay
AudioCtrl_PageAdvance:
	ld wa, (0x024790:24)
	exts xwa
	divs wa, 0x8
	ldto_werp WA, 0xe2
	ld (0x024790:24), wa
	ldw (0x024794:24), 0x0000
	ld wa, (0x024790:24)
	calr PsMixer_ReadWordArrayEntry
	ldfr_werp HL, 0xfa

AudioCtrl_SetupPartDisplay:
	ldto_werp WA, 0xfa
	add wa, wa
	lda xbc, (MixerPartTable_Start_0x12C:24)
	ld	de, (xbc+wa)
	exts xde
	ld xwa, NAKA_MAINFUNC_MainPmanControl
	ld xbc, EVT_PART_SELECT_PUT
	call MainFuncCall
	ldto_werp WA, 0xfa
	add wa, wa
	lda xbc, (MixerPartTable_Start_0x12C:24)
	ld	de, (xbc+wa)
	exts xde
	ld xwa, NAKA_MAINFUNC_MainGetSoundName
	ld xbc, EVT_GET_SOUND_NAME
	call FuncCall
	ld bc, (0x024792:24)
	extz xbc
	ld wa, (0x024790:24)
	extz xwa
	sll xwa, 16
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 90)
	ld xbc, EVT_INDEXSW_UP
	call SetDialUp
	ld bc, (0x024792:24)
	extz xbc
	ld wa, (0x024790:24)
	extz xwa
	sll xwa, 16
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 90)
	ld xbc, EVT_INDEXSW_DOWN
	call SetDialDown
	ld wa, 1:i3
	call SetDialEnable
	ld xwa, (xsp + 90)
	ld xbc, EVT_DRAW
	ld xde, 0:i3
	jrl PsMixer_SendEventAndForward

AudioCtrl_CheckEventF:
	ld xwa, (xsp + 82)
AudioCtrl_HandleEventF:
	cp xwa, 0xf
	jrl nz, AudioCtrl_ReturnToCallerExit
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_IS_INTERRUPT
	ld xde, 0:i3
	call SendEvent
	or xhl, xhl
	jr nz, AudioCtrl_QueryTitle
	call GetModeNow
	cp xhl, NAKA_MODE_MD_ENTERTAINER
	jr z, AudioCtrl_PostMode7
	cp xhl, NAKA_MODE_MD_SOUND
	jr nz, AudioCtrl_ReturnToCallerExit
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_TITLE
	ld xde, TITLE_SDMENU
	call PostEvent
	ld xwa, (xsp + 90)
	ld xbc, (xsp + 86)
	ld xde, (xsp + 82)
	jrl AudioCtrl_ProcessParamsAndReturn

AudioCtrl_PostMode7:
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_TITLE
	ld xde, TITLE_ETMENU
	call PostEvent
	ld xwa, (xsp + 90)
	ld xbc, (xsp + 86)
	ld xde, (xsp + 82)
	jrl AudioCtrl_ProcessParamsAndReturn

AudioCtrl_QueryTitle:
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_INTERRUPT_EXIT
	ld xde, 0:i3
	call SendEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_SET_HOLD
	ld xde, 0:i3
	call SendEvent

AudioCtrl_ReturnToCallerExit:
	ld xwa, (xsp + 90)
	ld xbc, (xsp + 86)
	ld xde, (xsp + 82)
	jrl AudioCtrl_ProcessParamsAndReturn

; PsMixer control case 6
PsMixer_ControlCase6:
	ld xwa, 0x2600024
	ld xbc, EVT_MAKE_EDIT_SW_ID
	ld xde, (xsp + 82)
	call SendEvent
	ld iz, hl
	cp iz, 7:i3
	jr gt, PsMixer_Case6_Forward
	ld wa, (0x024794:24)
	sla wa, 3
	add iz, wa
	ld wa, iz
	ld bc, (0x024792:24)
	extz xbc
	extz xwa
	sll xwa, 16
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 82)
	bit 7, wa
	jr z, PsMixer_Case6_ScrollDown
	ld xwa, (xsp + 90)
	ld xbc, EVT_INDEXSW_DOWN_AIC
	jr PsMixer_Case6_SendScroll

PsMixer_Case6_ScrollDown:
	ld xwa, (xsp + 90)
	ld xbc, EVT_INDEXSW_UP_AIC

PsMixer_Case6_SendScroll:
	call SendEvent
	ld xwa, (xsp + 90)
	ld xbc, EVT_SW_IN_AIC
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
	ld xbc, EVT_MAKE_EDIT_SW_ID
	ld xde, (xsp + 82)
	call SendEvent
	ld iz, hl
	cp iz, 7:i3
	jr gt, PsMixer_Case7_Forward
	ld xwa, 0xffffffff
	ld xbc, EVT_SW_OFF
	ld xde, (xsp + 82)
	call SendEvent
	ld xde, (xsp + 82)
	set 7, de
	ld xwa, 0xffffffff
	ld xbc, EVT_SW_OFF
	call SendEvent
	ld wa, (0x024794:24)
	sla wa, 3
	add iz, wa
	ld bc, (0x024792:24)
	extz xbc
	ld wa, iz
	extz xwa
	sll xwa, 16
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 90)
	ld xbc, EVT_INDEXSW_BOTH
	jrl PsMixer_SendEventAndForward

PsMixer_Case7_Forward:
	ld xwa, (xsp + 90)
	ld xbc, (xsp + 86)
	ld xde, (xsp + 82)
	jrl AudioCtrl_ProcessParamsAndReturn

; PsMixer control case 8
PsMixer_ControlCase8:
	ld XWA,(XSP+0x5a)
	ld XBC,(XSP+0x56)
	ld XDE,(XSP+0x52)
	call InheritedProc
	ld XWA,(XSP+0x52)
	ld (XSP+0x08),WA
	ld WA,(XSP+0x08)
	calr Util_SignExtendAndDouble
	ld (XSP+0x04),XHL
	ld XWA,(XSP+0x04)
	ld WA,(XWA+0x02)
	sla WA, 0x02
	lda	xbc, (Bitmap_DigitD_0x11F0:24)
	lda_rr	xhl, xbc, wa	; lda xhl, xbc+wa
	ld	xwa, (xsp+90)
	ld	xbc, (xsp+86)
	ld	xde, (xsp+82)
	ld	xhl, (xhl)
	call	(xhl)
	jrl	AudioCtrl_ReturnZero
PsMixerControlProc_Evt1C0001C:
	ld	xwa, (xsp+90)
	ld	xbc, (xsp+86)
	ld	xde, (xsp+82)
	call	InheritedProc
	ld	xwa, (xsp+82)
	ld	xiy, xwa
	lda	xix, (xsp+70)
	ld	bc, 6:i3
	ldirw
	lda	xwa, (xsp+70)
	lda	xbc, (xsp+68)
	lda	xde, (xsp+66)
	call	SndParam_ResolveOscEntry_Helper
	ld	wa, (0x024796:24)
	muls	wa, 5
	ld	(xsp+8), wa
	ldw	(xsp+10), 0
	cp	hl, 65535
	jrl	z, PsMixer_UnmatchedPartScan
PsMixer_MidiScanOuterLoop:
	ld wa, (xsp + 8)
	calr Util_SignExtendAndDouble
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld wa, (xwa)
	sla wa, 2
	lda xbc, (MixerPartTable_Start_0x80:24)
	ld	xwa, (xbc+wa)
	ld (xsp + 14), xwa
	ld iz, (0x024794:24)
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
	ld xbc, EVT_GET_PART
	call ApFuncCall
	cp hl, (xsp + 68)
	jrl nz, AudioCtrl_MixerLoopNext
	ldto_werp DE, 0xfa
	exts xde
	ld xwa, (xsp + 14)
	ld xbc, EVT_GET_LSW_DATA_NO
	call ApFuncCall
	cp hl, (xsp + 66)
	jr nz, AudioCtrl_MixerDispatch
	ld de, (xsp + 74)
	exts xde
	ld xwa, (xsp + 14)
	ld xbc, EVT_LSW_DATA_REQ
	call ApFuncCall
	ld bc, (xsp + 8)
	extz xbc
	ld wa, iz
	extz xwa
	sll xwa, 16
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 4)
	ld wa, (xwa + 2)
	sla wa, 2
	lda xbc, (Bitmap_DigitD_0x11F0:24)
	lda	xhl, (xbc+wa)
	ld xwa, (xsp + 90)
	ld xbc, EVT_PARA_DRAW
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
	lda xbc, (Bitmap_DigitD_0x11F0:24)
	lda	xhl, (xbc+wa)
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
	sll xwa, 16
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 4)
	ld wa, (xwa + 2)
	sla wa, 2
	lda xbc, (Bitmap_DigitD_0x11F0:24)
	lda	xhl, (xbc+wa)
	ld xwa, (xsp + 90)
	ld xbc, EVT_PARA_DRAW
	ld xhl, (xhl)
	call (xhl)

AudioCtrl_MixerLoopNext:
	inc 1, iz
	incw 1, (xsp + 12)
	cpw (xsp + 12), 0x8
	jrl c, PsMixer_ArrayReadHandler
	incw 1, (xsp + 8)
	incw 1, (xsp + 10)
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
	lda xbc, (MixerPartTable_Start_0x80:24)
	ld	xwa, (xbc+wa)
	ld (xsp + 14), xwa
	ld iz, (0x024794:24)
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
	ld xbc, EVT_GET_LSW_DATA_NO
	call ApFuncCall
	lda xwa, (xsp + 70)
	cp (xwa), xhl
	jr nz, AudioCtrl_DispatchCallback
	ld de, (xwa + 4)
	exts xde
	ld xwa, (xsp + 14)
	ld xbc, EVT_LSW_DATA_REQ
	call ApFuncCall
	ld bc, (xsp + 8)
	extz xbc
	ld wa, iz
	extz xwa
	sll xwa, 16
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 4)
	ld wa, (xwa + 2)
	sla wa, 2
	lda xbc, (Bitmap_DigitD_0x11F0:24)
	lda	xhl, (xbc+wa)
	ld xwa, (xsp + 90)
	ld xbc, EVT_PARA_DRAW
	ld xhl, (xhl)
	call (xhl)
	jr PsMixer_ScanArrayNext

; AudioCtrl dispatch callback
AudioCtrl_DispatchCallback:
	ld xde, (xwa)
	ld xwa, (xsp + 4)
	ld wa, (xwa + 2)
	sla wa, 2
	lda xbc, (Bitmap_DigitD_0x11F0:24)
	lda	xhl, (xbc+wa)
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
	sll xwa, 16
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 4)
	ld wa, (xwa + 2)
	sla wa, 2
	lda xbc, (Bitmap_DigitD_0x11F0:24)
	lda	xhl, (xbc+wa)
	ld xwa, (xsp + 90)
	ld xbc, EVT_PARA_DRAW
	ld xhl, (xhl)
	call (xhl)

PsMixer_ScanArrayNext:
	inc 1, iz
	incw 1, (xsp + 12)
	cpw (xsp + 12), 0x8
	jrl c, AudioCtrl_ArrayReadHandler
	incw 1, (xsp + 8)
	incw 1, (xsp + 10)
	cpw (xsp + 10), 0x5
	jrl c, PsMixer_UnmatchedPartScan
	jrl AudioCtrl_ReturnZero

; PsMixer control case 9
PsMixer_ControlCase9:
	ld xwa, (xsp + 90)
	ld xbc, (xsp + 86)
	ld xde, (xsp + 82)
	call InheritedProc
	ld wa, (0x024790:24)
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
	ldfr_werp HL, 0xfa
	cp_erpw 0xfa, 0xff, 0xff
	jrl z, AudioCtrl_ReturnZero
	ld wa, (0x024790:24)
	calr PsMixer_ReadWordArrayEntry
	ldto_werp WA, 0xfa
	cp wa, hl
	jr nz, PsMixer_VolSel_SearchGrid
	ld iz, (0x024790:24)
	jr PsMixer_VolumeSelect_Continue

PsMixer_VolSel_SearchGrid:
	ld iz, (0x024794:24)
	sla iz, 3
	ldw (xsp + 10), 0x0

PsMixer_VolSel_SearchLoop:
	ld wa, iz
	calr PsMixer_ReadWordArrayEntry
	ldto_werp WA, 0xfa
	cp wa, hl
	jr z, PsMixer_VolSel_CheckFound
	inc 1, iz
	incw 1, (xsp + 10)
	cpw (xsp + 10), 0x8
	jr c, PsMixer_VolSel_SearchLoop

PsMixer_VolSel_CheckFound:
	cpw (xsp + 10), 0x8
	jr nz, PsMixer_VolumeSelect_Continue
	ld iz, 0:i3
	ld wa, 0:i3
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
	ld wa, (0x024790:24)
	cp wa, iz
	jrl z, AudioCtrl_ReturnZero
	ld (0x024790:24), iz
	ld wa, iz
	exts xwa
	divs wa, 0x8
	ld (0x024794:24), wa
	ldto_werp WA, 0xfa
	add wa, wa
	lda xbc, (MixerPartTable_Start_0x12C:24)
	ld	de, (xbc+wa)
	exts xde
	ld xwa, NAKA_MAINFUNC_MainGetSoundName
	ld xbc, EVT_GET_SOUND_NAME
	call FuncCall
	ld bc, (0x024792:24)
	extz xbc
	ld wa, (0x024790:24)
	extz xwa
	sll xwa, 16
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 90)
	ld xbc, EVT_INDEXSW_UP
	call SetDialUp
	ld bc, (0x024792:24)
	extz xbc
	ld wa, (0x024790:24)
	extz xwa
	sll xwa, 16
	ld xde, xwa
	add xde, xbc
	ld xwa, (xsp + 90)
	ld xbc, EVT_INDEXSW_DOWN
	call SetDialDown
	ld wa, 1:i3
	call SetDialEnable
	ld xwa, (xsp + 90)
	ld xbc, EVT_REFRESH_PARA_DRAW
	ld xde, 0:i3

PsMixer_SendEventAndForward:
	call SendEvent
	jrl t, AudioCtrl_ReturnZero
PsMixerControlProc_Evt1C00020:
	ld XWA,(XSP+0x5a)
	ld XBC,(XSP+0x56)
	ld XDE,(XSP+0x52)
	call InheritedProc
	ld wa, (0x024790:24)
	calr PsMixer_ReadWordArrayEntry
	ld QIZ,HL
	ld WA,QIZ
	add WA,WA
	lda xbc, (MixerPartTable_Start_0x12C:24)
	ld	bc, (xbc+wa)
	ld XWA,(XSP+0x52)
	cp BC,(XWA)
	jr nz, PsMixer_EventFwd_Setup
	ld XWA,(XWA+0x02)
	push XWA
	ld WA,QIZ
	sla WA, 0x02
	lda xbc, (0x03ea38:24)
	ld	xwa, (xbc+wa)
	push XWA
	pushw PsMixerControlProc_Evt1C00020_Str_Fmts_SOUND_Fmts@hi16
	pushw PsMixerControlProc_Evt1C00020_Str_Fmts_SOUND_Fmts@lo16
	lda xwa, (xsp + 0x1e)
	push XWA
	call Scoop_EventLoop_12Entry_Helper
	lda xsp, (xsp + 0x10)
	lda xde, (xsp + 0x12)
	ld XWA,(XSP+0x5a)
	ld XBC,EVT_PARA_DRAW
	call SendEvent
PsMixer_EventFwd_Setup:
	ld wa, (0x024796:24)
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
	lda xbc, (MixerPartTable_Start_0x80:24)
	ld	xwa, (xbc+wa)
	ld (xsp + 14), xwa
	cp xwa, NAKA_APFUNC_LswSound
	jr nz, PsMixer_EventFwd_Next
	ld wa, (xde + 2)
	sla wa, 2
	lda xbc, (Bitmap_DigitD_0x11F0:24)
	lda	xhl, (xbc+wa)
	ld xwa, (xsp + 90)
	ld xbc, (xsp + 86)
	ld xde, (xsp + 82)
	ld xhl, (xhl)
	call (xhl)
	jr AudioCtrl_ReturnZero

PsMixer_EventFwd_Next:
	incw 1, (xsp + 8)
	incw 1, (xsp + 10)
	cpw (xsp + 10), 0x5
	jr c, PsMixer_EventForwardHelper
	jr AudioCtrl_ReturnZero

; PsMixer control common handler
PsMixer_ControlCommon:
	pushw	PsMixer_ControlCommon_Str_RIGHT_1_Sound_Name_xxxxx@hi16
	pushw	PsMixer_ControlCommon_Str_RIGHT_1_Sound_Name_xxxxx@lo16
	ld	xwa, (xsp+86)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
AudioCtrl_ReturnZero:
	ld xhl, 0:i3
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
	cp xwa, EVT_SHOW
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
	ld xhl, 0:i3

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
	cp xwa, EVT_TRSW_PART
	jr z, TrackMixer_UpdateHandler
	cp xwa, EVT_REPAINT
	jr z, TrackMixer_ShowHide
	cp xwa, EVT_PAINT
	jr z, TrackMixer_ShowHide
	cp xwa, EVT_SHOW
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
	ld iz, 0:i3

TrackMixer_InitPartLoop:
	ld de, iz
	exts xde
	ld xwa, NAKA_MAINFUNC_MainTrSwControl
	ld xbc, EVT_REQUEST_TRACK_SWITCH
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
	srl xwa, 16
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
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call SendEvent

TrackMixer_ReturnZero:
	ld xhl, 0:i3

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
	cp xwa, EVT_SHOW
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
	ld xbc, EVT_SET_PAGE
	ld xde, 1:i3
	call SendEvent

ResetPage_CallInherited:
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	ld xhl, 0:i3

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
	add xhl, (0x3ea30:24)
	ret

Util_StorePartArrayBase:
	ld (0x03ea30:24), xwa
	ret

PsMixer_ReadWordArrayEntry:
	exts xwa
	add xwa, xwa
	add xwa, (0x3ea34:24)
	ld hl, (xwa)
	ret

Util_StoreGridArrayBase:
	ld (0x03ea34:24), xwa
	ret


; -----------------------------------------------------------------------------
; PsMixer drawing helpers (the next ~0x2a0 bytes), shared by the
; PsMixer_CtlTypeProc<i> control procedures further down:
;
; PsMixer_DrawFrameBoxWithDividers(XWA = rect, BC = colour) -- the same box
; as PsMixer_DrawFrameBox, then seven vertical double lines (DrawLine colour
; 248 at x, colour 255 at x+1) at x = 45, 83, ... 273 (`addiw (xsp+12), 37`
; after the +1: a 38-pixel pitch), from y0+2 to y1-2 of the box: eight
; 38-pixel columns.
; Callers: the PsMixer_CtlTypeProc<i> routines below.
;
; PsMixer_DrawFrameBox(XWA = rect, BC = style/colour) -- GetFrameSPSize(52)
; gives the frame's text size; the rectangle is copied, its y0 moved down by
; that height - 2, and DrawDesignBox(rect, 193, BC) draws it.
;
; PsMixer_DrawCaptionFrame(XWA = rect, XDE = caption string, BC = selected
; flag) -- DrawFrameSP(style 52, colour 242 if BC != 0 else 8) at the rect's
; origin, then DrawStringCentered(caption, colours 247/255, 3) centred
; (GetBoxCenter) in a box the size GetFrameSPSize(52) reports.
;
; PsMixer_CalcRowBandRect(XWA = out rect, BC = control index) -- n = index
; mod 5 (`divs wa,5 / ld wa,qwa`); point = GetEditSwPoint(136 + n); out rect =
; x 8..311, y (point.y - 9 - n) .. (point.y + 31 - n), both y shifted by the
; word +4 of the control's 12-byte record at (0x03ea30) + index*12.
;
; PsMixer_CalcSwitchPointInFrame(XWA = frame rect, XBC = out point, DE =
; param) -- n = param mod 8; y = centre of the frame rect (after the same
; GetFrameSPSize(52) caption offset as PsMixer_DrawFrameBox, GetBoxCenter);
; x = GetEditSwPoint(n).x - (2n - 8) - 2.
;
; PsMixer_CalcGridCellPoint(XWA = frame rect, XBC = out point, DE = param) --
; n = param mod 8; inside the frame (caption offset as PsMixer_DrawFrameBox)
; cell width = width/4, cell height = height/8, and
; x = x0 + (2*(n div 4) + 1) * width/4 + 2, y = y0 + (2*(n mod 4) + 1) *
; height/8 + 2: the centre of cell n of a 2-column x 4-row grid.
; -----------------------------------------------------------------------------
; AudioCtrl_DataBlock: previous name of this label, kept only because it is still referenced by shared/positional_labels.s (owned by another lane)
AudioCtrl_DataBlock:
PsMixer_DrawFrameBoxWithDividers:
	; framing ported from v10's source for the same label (same span length, statement for statement); 2194 of 2536 slots byte-identical
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
	ld	bc, 4:i3
	ldirw	; v10 does not spell this byte either
	lda	xwa, (xsp+16)
	ld	bc, (xsp+4)
	dec	2, bc
	add	(xwa+2), bc
	ldw	bc, 193
	ld	de, (xsp+24)
	call	DrawDesignBox
	lda	xde, (xsp+12)
	ldw	(xde), 45
	lda	xbc, (xsp+16)
	ld	wa, (xbc+2)
	inc	2, wa
	ld	(xde+2), wa
	lda	xde, (xsp+8)
	ldw	(xde), 45
	ld	wa, (xbc+6)
	dec	2, wa
	ld	(xde+2), wa
	ld	iz, 0:i3
PsMixer_DrawFrameBoxWithDividers_Loop:
	lda	xwa, (xsp+12)
	lda	xbc, (xsp+8)
	ldw	de, 248
	call	DrawLine
	lda	xwa, (xsp+12)
	incw	1, (xwa)
	lda	xbc, (xsp+8)
	incw	1, (xbc)
	ldw	de, 255
	call	DrawLine
	addw	(xsp+12), 0x25	; v10 does not spell this byte either
	addw	(xsp+8), 0x25	; v10 does not spell this byte either
	inc	1, iz
	cp	iz, 7:i3
	jr	lt, PsMixer_DrawFrameBoxWithDividers_Loop
	pop	xiz
	lda	xsp, (xsp+22)
	ret
PsMixer_DrawFrameBox:
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
	ld	bc, 4:i3
	ldirw	; v10 does not spell this byte either
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
PsMixer_DrawCaptionFrame:
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
	cpw	(xsp+24), 0	; v10 does not spell this byte either
	jr	z, PsMixer_DrawCaptionFrame_Skip
	ldw	bc, 52
	ldw	de, 242
	jr	PsMixer_DrawCaptionFrame_Join
PsMixer_DrawCaptionFrame_Skip:
	ldw	bc, 52
	ldw	de, 8
PsMixer_DrawCaptionFrame_Join:
	call	DrawFrameSP
	ld	xiy, xiz
	lda	xix, (xsp+12)
	ld	bc, 4:i3
	ldirw	; v10 does not spell this byte either
	lda	xwa, (xsp+12)
	ld	bc, (xiz)
	add	bc, (xsp+6)
	ld	(xwa+4), bc
	ld	bc, (xiz+2)
	add	bc, (xsp+4)
	ld	(xwa+6), bc
	lda	xbc, (xsp+8)
	call	GetBoxCenter
	lda	xwa, (xsp+12)
	lda	xbc, (xsp+8)
	ld	xde, 3:i3
	push	xde
	pushw	255
	pushw	247
	ld	xde, (xsp+28)
	call	DrawStringCentered
	pop	xiz
	lda	xsp, (xsp+22)
	ret
PsMixer_CalcRowBandRect:
	dec	8, xsp
	push	xiz
	ld	xiz, xwa
	ld	wa, bc
	exts	xwa
	divs	wa, 5
	ld	wa, qwa
	ld	(xsp+6), wa
	ld	wa, bc
	exts	xwa
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	sll	xbc, 2
	add	xbc, (256560:24)
	ld	wa, (xbc+4)
	ld	(xsp+4), wa
	ldw	wa, 136
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	add	wa, (xsp+6)
	lda	xbc, (xsp+8)
	call	GetEditSwPoint
	lda	xde, (xiz+2)
	lda	xbc, (xsp+10)
	ld	wa, (xbc)
	sub	wa, 9
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	sub	wa, (xsp+6)
	ld	(xde), wa
	ldw	(xiz), 8	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	ldw	(xiz+4), 311
	lda	xhl, (xiz+6)
	ld	wa, (xbc)
	add	wa, 31
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	sub	wa, (xsp+6)
	ld	(xhl), wa
	ld	wa, (xsp+4)
	add	(xde), wa
	add	(xhl), wa
	pop	xiz
	inc	8, xsp
	ret
PsMixer_CalcSwitchPointInFrame:
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
	ld	bc, 4:i3
	ldirw	; v10 does not spell this byte either
	ld	wa, (xsp+4)
	dec	2, wa
	add	(xsp+14), wa
	ld	wa, (xsp+20)
	exts	xwa
	divs	wa, 8
	ld	iz, qwa
	ld	wa, iz
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
PsMixer_CalcGridCellPoint:
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
	ld	bc, 4:i3
	ldirw	; v10 does not spell this byte either
	lda	xde, (xsp+8)
	lda	xbc, (xde+2)
	ld	wa, (xsp+4)
	dec	2, wa
	add	(xbc), wa
	ld	wa, (xsp+16)
	exts	xwa
	divs	wa, 8
	ld	hl, qwa	; v10 does not spell this byte either
	ld	wa, (xde+4)
	sub	wa, (xde)	; v10 does not spell this byte either
	ld	ix, wa	; v10 does not spell this byte either
	exts	xix
	divs	ix, 4
	ld	wa, hl
	exts	xwa
	divs	wa, 4
	add	wa, wa
	inc	1, wa
	muls	xwa, ix
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
	ld	wa, qhl
	add	wa, wa
	inc	1, wa
	muls	xwa, de
	add	bc, wa
	inc	2, bc
	ld	(xiy+2), bc
	pop	xiz
	lda	xsp, (xsp+18)
	ret
PsMixer_CtlTypeProc0:
	ld	xhl, 0:i3
	ret
PsMixer_CtlTypeProc5:
	lda	xsp, (xsp-28)
	push	xiz
	ld	(xsp+28), xbc
	ld	wa, de
	srl	xde, 16
	ld	(xsp+12), wa
	ld	qde, 0
	ld	(xsp+14), de
	ld	xwa, (xsp+28)
	cp	xwa, EVT_INDEXSW_DOWN_AIC
	jrl	z, PsMixer_CtlTypeProc5_Skip3
	cp	xwa, EVT_INDEXSW_DOWN
	jrl	z, PsMixer_CtlTypeProc5_Skip3
	cp	xwa, EVT_INDEXSW_UP_AIC
	jrl	z, PsMixer_CtlTypeProc5_Skip3
	cp	xwa, EVT_INDEXSW_UP
	jrl	z, PsMixer_CtlTypeProc5_Skip3
	cp	xwa, EVT_PARA_DRAW
	jr	z, PsMixer_CtlTypeProc5_Skip
	cp	xwa, EVT_SELE_DRAW
	jrl	z, PsMixer_CtlTypeProc5_Join2
	cp	xwa, EVT_DRAW
	jrl	nz, PsMixer_CtlTypeProc5_Join2
	lda	xwa, (xsp+20)
	ld	bc, (xsp+12)
	calr	PsMixer_CalcRowBandRect
	lda	xwa, (xsp+20)
	addw	(xwa+2), 0xa	; v10 does not spell this byte either
	ld	bc, 7:i3
	calr	PsMixer_DrawFrameBoxWithDividers
	jrl	PsMixer_CtlTypeProc5_Join2
PsMixer_CtlTypeProc5_Skip:
	ld	wa, (xsp+14)
	calr	PsMixer_ReadWordArrayEntry
	ld	(xsp+4), hl
	lda	xwa, (xsp+20)
	ld	bc, (xsp+12)
	calr	PsMixer_CalcRowBandRect
	lda	xwa, (xsp+20)
	addw	(xwa+2), 0xa	; v10 does not spell this byte either
	lda	xbc, (xsp+16)
	ld	de, (xsp+14)
	calr	PsMixer_CalcSwitchPointInFrame
	lda	xbc, (xsp+16)
	lda	xwa, (256688:24)
	ld	de, (xsp+4)
	sla	de, 2
	ld_rrl	xde, xwa, de
	lda	xwa, (xsp+20)
	ld	hl, (xsp+14)
	cp	hl, (149392:24)
	jr	nz, PsMixer_CtlTypeProc5_Skip2
	ld	xhl, 3:i3
	push	xhl
	pushw	255
	pushw	242
	pushw	0
	pushw	0
	jr	PsMixer_CtlTypeProc5_Join
PsMixer_CtlTypeProc5_Skip2:
	ld	xhl, 3:i3
	push	xhl
	pushw	255
	pushw	8
	pushw	0
	pushw	0
PsMixer_CtlTypeProc5_Join:
	call	DrawStringReverse
	jrl	PsMixer_CtlTypeProc5_Join2
PsMixer_CtlTypeProc5_Skip3:
	ld	wa, (xsp+12)
	calr	Util_SignExtendAndDouble
	ld	xiz, xhl
	ld	wa, (xsp+14)
	calr	PsMixer_ReadWordArrayEntry
	ld	(xsp+4), hl
	ld	wa, (xiz)
	sla	wa, 2
	lda	xbc, (MixerPartTable_Start_0x80:24)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	ld_rrl	xwa, xbc, wa
	ld	(xsp+12), xwa
	ld	de, (xsp+4)	; v10 does not spell this byte either
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, EVT_GET_LARGE_STEP
	call	ApFuncCall
	ld	(xsp+10), hl
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, EVT_GET_SMALL_STEP
	call	ApFuncCall
	ld	xwa, (xsp+28)
	ld	bc, (xsp+10)
	ld	de, hl
	calr	SdpartScrollDelta
	ld	(xsp+10), hl
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, EVT_GET_PART
	call	ApFuncCall
	ld	(xsp+6), hl
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, EVT_GET_LSW_OUTPUT
	call	ApFuncCall
	ld	(xsp+8), hl
	ld	wa, (xsp+6)
	ld	de, (xsp+4)
	exts	xde
	cp	wa, 65535
	jr	z, PsMixer_CtlTypeProc5_Skip4
	ld	xwa, (xsp+12)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	pushw	(xsp+8)	; v10 does not spell this byte either
	ld	wa, (xsp+8)
	ld	bc, hl	; v10 does not spell this byte either
	ld	de, (xsp+12)
	call	MainLswPartAdd
	jr	PsMixer_CtlTypeProc5_Join2
PsMixer_CtlTypeProc5_Skip4:
	ld	xwa, (xsp+12)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	xwa, xhl
	ld	bc, (xsp+10)
	ld	de, (xsp+8)
	call	MainLswAdd
PsMixer_CtlTypeProc5_Join2:
	ld	xhl, 0:i3
	pop	xiz
	lda	xsp, (xsp+28)
	ret
PsMixer_CtlTypeProc6:
	lda	xsp, (xsp-28)
	push	xiz
	ld	(xsp+28), xbc
	ld	wa, de
	srl	xde, 16
	ld	(xsp+12), wa
	ld	qde, 0
	ld	(xsp+14), de
	ld	xwa, (xsp+28)
	cp	xwa, EVT_INDEXSW_DOWN_AIC
	jrl	z, PsMixer_CtlTypeProc6_Skip3
	cp	xwa, EVT_INDEXSW_DOWN
	jrl	z, PsMixer_CtlTypeProc6_Skip3
	cp	xwa, EVT_INDEXSW_UP_AIC
	jrl	z, PsMixer_CtlTypeProc6_Skip3
	cp	xwa, EVT_INDEXSW_UP
	jrl	z, PsMixer_CtlTypeProc6_Skip3
	cp	xwa, EVT_PARA_DRAW
	jr	z, PsMixer_CtlTypeProc6_Skip
	cp	xwa, EVT_SELE_DRAW
	jrl	z, PsMixer_CtlTypeProc6_Join2
	cp	xwa, EVT_DRAW
	jrl	nz, PsMixer_CtlTypeProc6_Join2
	lda	xwa, (xsp+20)
	ld	bc, (xsp+12)
	calr	PsMixer_CalcRowBandRect
	lda	xwa, (xsp+20)
	incw	7, (xwa+2)
	ld	bc, 7:i3
	calr	PsMixer_DrawFrameBoxWithDividers
	jrl	PsMixer_CtlTypeProc6_Join2
PsMixer_CtlTypeProc6_Skip:
	ld	wa, (xsp+14)
	calr	PsMixer_ReadWordArrayEntry
	ld	(xsp+4), hl
	lda	xwa, (xsp+20)
	ld	bc, (xsp+12)
	calr	PsMixer_CalcRowBandRect
	lda	xwa, (xsp+20)
	incw	7, (xwa+2)
	lda	xbc, (xsp+16)
	ld	de, (xsp+14)
	calr	PsMixer_CalcSwitchPointInFrame
	lda	xbc, (xsp+16)
	decw	6, (xbc+2)
	lda	xwa, (xsp+20)
	ld	de, (xsp+4)
	sla	de, 2
	lda	xhl, (256688:24)
	ld_rrl	xde, xhl, de
	ld	xhl, 3:i3
	push	xhl
	pushw	0
	pushw	247
	call	DrawStringCentered
	lda	xbc, (xsp+16)
	addw	(xbc+2), 0xa	; v10 does not spell this byte either
	lda	xwa, (0x03eb88:24)	; v10 does not spell this byte either
	ld	de, (xsp+14)
	sla	de, 2	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	ld_rrl	xde, xwa, de
	lda	xwa, (xsp+20)
	ld	hl, (xsp+14)
	cp	hl, (0x024790:24)	; v10 does not spell this byte either
	jr	nz, PsMixer_CtlTypeProc6_Skip2
	ld	xhl, 3:i3
	push	xhl
	pushw	255
	pushw	242
	pushw	0
	pushw	0
	jr	PsMixer_CtlTypeProc6_Join
PsMixer_CtlTypeProc6_Skip2:
	ld	xhl, 3:i3
	push	xhl
	pushw	255
	pushw	8
	pushw	0
	pushw	0
PsMixer_CtlTypeProc6_Join:
	call	DrawStringReverse
	jrl	PsMixer_CtlTypeProc6_Join2
PsMixer_CtlTypeProc6_Skip3:
	ld	wa, (xsp+12)
	calr	Util_SignExtendAndDouble
	ld	xiz, xhl
	ld	wa, (xsp+14)
	calr	PsMixer_ReadWordArrayEntry
	ld	(xsp+4), hl
	ld	wa, (xiz)
	sla	wa, 2
	lda	xbc, (MixerPartTable_Start_0x80:24)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	ld_rrl	xwa, xbc, wa
	ld	(xsp+12), xwa
	ld	de, (xsp+4)	; v10 does not spell this byte either
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, EVT_GET_LARGE_STEP
	call	ApFuncCall
	ld	(xsp+10), hl
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, EVT_GET_SMALL_STEP
	call	ApFuncCall
	ld	xwa, (xsp+28)
	ld	bc, (xsp+10)
	ld	de, hl
	calr	SdpartScrollDelta
	ld	(xsp+10), hl
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, EVT_GET_PART
	call	ApFuncCall
	ld	(xsp+6), hl
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, EVT_GET_LSW_OUTPUT
	call	ApFuncCall
	ld	(xsp+8), hl
	ld	wa, (xsp+6)
	ld	de, (xsp+4)
	exts	xde
	cp	wa, 65535
	jr	z, PsMixer_CtlTypeProc6_Skip4
	ld	xwa, (xsp+12)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	pushw	(xsp+8)	; v10 does not spell this byte either
	ld	wa, (xsp+8)
	ld	bc, hl	; v10 does not spell this byte either
	ld	de, (xsp+12)
	call	MainLswPartAdd
	jr	PsMixer_CtlTypeProc6_Join2
PsMixer_CtlTypeProc6_Skip4:
	ld	xwa, (xsp+12)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	xwa, xhl
	ld	bc, (xsp+10)
	ld	de, (xsp+8)
	call	MainLswAdd
PsMixer_CtlTypeProc6_Join2:
	ld	xhl, 0:i3
	pop	xiz
	lda	xsp, (xsp+28)
	ret
PsMixer_CtlTypeProc3:
	lda	xsp, (xsp-76)
	pushw	iz
	ld	(xsp+70), xde
	ld	(xsp+74), xbc
	ld	xwa, (xsp+70)
	ld	(xsp+10), wa
	ld	xwa, (xsp+70)
	srl	xwa, 16
	ld	qwa, 0	; v10 does not spell this byte either
	ld	bc, wa
	ld	xwa, (xsp+74)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	cp	xwa, EVT_INDEXSW_BOTH
	jrl	z, PsMixer_CtlTypeProc3_Skip8
	ld	(xsp+12), bc
	cp	xwa, EVT_INDEXSW_DOWN_AIC
	jrl	z, PsMixer_CtlTypeProc3_Skip6
	cp	xwa, EVT_INDEXSW_DOWN
	jrl	z, PsMixer_CtlTypeProc3_Skip6
	cp	xwa, EVT_INDEXSW_UP_AIC
	jrl	z, PsMixer_CtlTypeProc3_Skip6
	cp	xwa, EVT_INDEXSW_UP
	jrl	z, PsMixer_CtlTypeProc3_Skip6
	cp	xwa, EVT_PARA_DRAW
	jr	z, PsMixer_CtlTypeProc3_Skip2
	cp	xwa, EVT_SELE_DRAW
	jr	z, PsMixer_CtlTypeProc3_Skip
	cp	xwa, EVT_DRAW
	jrl	nz, PsMixer_CtlTypeProc3_Join4
	lda	xwa, (xsp+62)
	ld	bc, (xsp+10)
	calr	PsMixer_CalcRowBandRect
	lda	xwa, (xsp+62)
	ld	bc, 7:i3
	calr	PsMixer_DrawFrameBoxWithDividers
	ld	wa, (xsp+10)
	exts	xwa
	divs	wa, 5
	ld	wa, qwa
	add	wa, 136
	call	DrawEditSw
	jrl	PsMixer_CtlTypeProc3_Join4
PsMixer_CtlTypeProc3_Skip:
	ld	wa, (xsp+10)
	calr	Util_SignExtendAndDouble
	ld	(xsp+6), xhl
	lda	xwa, (xsp+62)
	ld	bc, (xsp+10)
	calr	PsMixer_CalcRowBandRect
	lda	xwa, (xsp+62)
	ld	xbc, (xsp+70)
	srl	xbc, 16
	ld	qbc, 0
	ld	xde, (xsp+6)
	ld	xde, (xde+8)
	calr	PsMixer_DrawCaptionFrame
	jrl	PsMixer_CtlTypeProc3_Join4
PsMixer_CtlTypeProc3_Skip2:
	ld	wa, (xsp+10)
	calr	Util_SignExtendAndDouble
	ld	(xsp+6), xhl
	ld	wa, (xsp+12)
	calr	PsMixer_ReadWordArrayEntry
	ld	(xsp+4), hl
	ld	xwa, (xsp+6)
	ld	wa, (xwa)
	sla	wa, 2
	lda	xbc, (MixerPartTable_Start_0x80:24)
	ld_rrl	xwa, xbc, wa
	ld	(xsp+6), xwa
	lda	xwa, (xsp+62)
	ld	bc, (xsp+10)
	calr	PsMixer_CalcRowBandRect
	lda	xwa, (xsp+62)
	lda	xbc, (xsp+58)
	ld	de, (xsp+12)
	calr	PsMixer_CalcSwitchPointInFrame
	subw	(xsp+60), 9	; v10 does not spell this byte either
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+6)
	ld	xbc, EVT_GET_PART
	call	ApFuncCall
	ld	(xsp+2), hl
	ld	wa, (xsp+2)
	ld	de, (xsp+4)
	exts	xde
	cp	wa, 65535
	jr	z, PsMixer_CtlTypeProc3_Skip3
	ld	xwa, (xsp+6)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	iz, hl
	ld	wa, (xsp+2)
	ld	bc, iz
	call	DkMdlyPly_CheckState_Helper
	ld	(xsp+50), hl
	jr	PsMixer_CtlTypeProc3_Join
PsMixer_CtlTypeProc3_Skip3:
	ld	xwa, (xsp+6)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	xwa, xhl
	call	AcApcToggleProc_Helper
	ld	(xsp+50), hl
PsMixer_CtlTypeProc3_Join:
	ld	bc, iz
	extz	xbc
	ld	wa, (xsp+4)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	extz	xwa
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	sll	xwa, 16
	add	xwa, xbc
	lda	xde, (xsp+46)
	ld	(xde), xwa
	lda	xwa, (xsp+14)
	ld	(xde+8), xwa
	ld	xwa, (xsp+6)
	ld	xbc, EVT_GET_LSW_STRING
	call	ApFuncCall
	lda	xwa, (xsp+62)
	lda	xde, (xsp+14)
	lda	xbc, (xsp+58)
	ld	hl, (xsp+10)
	cp	hl, (149394:24)
	jr	nz, PsMixer_CtlTypeProc3_Skip4
	ld	hl, (xsp+12)
	cp	hl, (149392:24)
	jr	nz, PsMixer_CtlTypeProc3_Skip4
	ld	xhl, 3:i3
	push	xhl
	pushw	0
	pushw	7
	pushw	0
	pushw	1
	jr	PsMixer_CtlTypeProc3_Join2
PsMixer_CtlTypeProc3_Skip4:
	ld	xhl, 3:i3
	push	xhl
	pushw	0
	pushw	7
	pushw	0
	pushw	0
PsMixer_CtlTypeProc3_Join2:
	call	DrawStringReverse
	lda	xwa, (xsp+62)
	lda	xbc, (xsp+58)
	ld	de, (xsp+12)
	calr	PsMixer_CalcSwitchPointInFrame
	lda	xwa, (xsp+58)
	decw	8, (xwa)
	decw	3, (xwa+2)
	ld	xbc, 4:i3
	call	DrawBitmap
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+6)
	ld	xbc, EVT_CHECK_PART
	call	ApFuncCall
	lda	xbc, (MidiParam_MixerCfgData_0x2A:24)
	or	xhl, xhl
	jr	z, PsMixer_CtlTypeProc3_Skip5
	lda	xhl, (xsp+58)
	lda	xde, (xsp+50)
	ld	wa, (xde)
	sra	wa, 3
	sla	wa, 2
	ld_rrw	wa, xbc, wa
	add	(xhl), wa
	ld	wa, (xde)
	sra	wa, 3
	sla	wa, 2
	exts	xwa
	add	xwa, xbc
	ld	wa, (xwa+2)
	add	(xhl+2), wa
	jr	PsMixer_CtlTypeProc3_Join3
PsMixer_CtlTypeProc3_Skip5:
	lda	xde, (xsp+58)
	ld	wa, (xbc+32)
	add	(xde), wa
	ld	wa, (xbc+34)
	add	(xde+2), wa
PsMixer_CtlTypeProc3_Join3:
	lda	xwa, (xsp+58)
	ld	xbc, 5:i3
	call	DrawBitmap
	jrl	PsMixer_CtlTypeProc3_Join4
PsMixer_CtlTypeProc3_Skip6:
	ld	wa, (xsp+10)
	calr	Util_SignExtendAndDouble
	ld	(xsp+6), xhl
	ld	wa, (xsp+12)
	calr	PsMixer_ReadWordArrayEntry
	ld	(xsp+4), hl
	ld	xwa, (xsp+6)
	ld	wa, (xwa)
	sla	wa, 2
	lda	xbc, (MixerPartTable_Start_0x80:24)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	ld_rrl	xwa, xbc, wa
	ld	(xsp+6), xwa	; v10 does not spell this byte either
	ld	de, (xsp+4)	; v10 does not spell this byte either
	exts	xde
	ld	xwa, (xsp+6)
	ld	xbc, EVT_GET_LARGE_STEP
	call	ApFuncCall
	ld	(xsp+12), hl
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+6)
	ld	xbc, EVT_GET_SMALL_STEP
	call	ApFuncCall
	ld	xwa, (xsp+74)
	ld	bc, (xsp+12)
	ld	de, hl
	calr	SdpartScrollDelta
	ld	(xsp+12), hl
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+6)
	ld	xbc, EVT_GET_PART
	call	ApFuncCall
	ld	(xsp+2), hl
	ld	wa, (xsp+12)
	ld	(xsp+10), wa
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+6)
	ld	xbc, EVT_GET_LSW_OUTPUT
	call	ApFuncCall
	ld	(xsp+12), hl
	ld	wa, (xsp+2)
	ld	de, (xsp+4)
	exts	xde
	cp	wa, 65535
	jr	z, PsMixer_CtlTypeProc3_Skip7
	ld	xwa, (xsp+6)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	iz, hl
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	pushw	(xsp+12)
	ld	wa, (xsp+4)
	ld	bc, iz
	ld	de, (xsp+12)
	call	MainLswPartAdd
	jrl	PsMixer_CtlTypeProc3_Join4
PsMixer_CtlTypeProc3_Skip7:
	ld	xwa, (xsp+6)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	xwa, xhl
	ld	bc, (xsp+10)
	ld	de, (xsp+12)
	call	MainLswAdd
	jrl	PsMixer_CtlTypeProc3_Join4
PsMixer_CtlTypeProc3_Skip8:
	ld	iz, bc
	ld	wa, (xsp+10)
	calr	Util_SignExtendAndDouble
	ld	(xsp+6), xhl
	ld	wa, iz
	calr	PsMixer_ReadWordArrayEntry
	ld	(xsp+4), hl
	ld	xwa, (xsp+6)
	ld	wa, (xwa)
	sla	wa, 2
	lda	xbc, (MixerPartTable_Start_0x80:24)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	ld_rrl	xwa, xbc, wa
	ld	(xsp+6), xwa	; v10 does not spell this byte either
	ld	de, (xsp+4)	; v10 does not spell this byte either
	exts	xde
	ld	xwa, (xsp+6)
	ld	xbc, EVT_CHECK_INIT_DATA
	call	ApFuncCall
	or	xhl, xhl
	jrl	z, PsMixer_CtlTypeProc3_Join4
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+6)
	ld	xbc, EVT_GET_PART
	call	ApFuncCall
	ld	(xsp+2), hl
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+6)
	ld	xbc, EVT_GET_LSW_OUTPUT
	call	ApFuncCall
	ld	(xsp+12), hl
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+6)
	ld	xbc, EVT_GET_INIT_DATA
	call	ApFuncCall
	ld	(xsp+10), hl
	ld	wa, (xsp+2)
	cp	wa, 65535
	jr	z, PsMixer_CtlTypeProc3_Skip9
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+6)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	iz, hl
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	pushw	(xsp+12)
	ld	wa, (xsp+4)
	ld	bc, iz
	ld	de, (xsp+12)
	call	MainLswPartPut
	jr	PsMixer_CtlTypeProc3_Join4
PsMixer_CtlTypeProc3_Skip9:
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+6)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	xwa, xhl
	ld	bc, (xsp+10)
	ld	de, (xsp+12)
	call	MainLswPut
PsMixer_CtlTypeProc3_Join4:
	ld	xhl, 0:i3
	popw	iz
	lda	xsp, (xsp+76)
	ret
PsMixer_CtlTypeProc7:
	lda	xsp, (xsp-76)
	push	xiz
	ld	(xsp+72), xde
	ld	(xsp+76), xbc
	ld	xwa, (xsp+72)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	ld	xbc, (xsp+72)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	srl	xbc, 16
	ld	(xsp+12), wa
	ld	qbc, 0
	ld	(xsp+14), bc
	ld	xwa, (xsp+76)
	cp	xwa, EVT_INDEXSW_BOTH
	jrl	z, PsMixer_CtlTypeProc7_Skip7
	cp	xwa, EVT_INDEXSW_DOWN_AIC
	jrl	z, PsMixer_CtlTypeProc7_Skip5
	cp	xwa, EVT_INDEXSW_DOWN
	jrl	z, PsMixer_CtlTypeProc7_Skip5
	cp	xwa, EVT_INDEXSW_UP_AIC
	jrl	z, PsMixer_CtlTypeProc7_Skip5
	cp	xwa, EVT_INDEXSW_UP
	jrl	z, PsMixer_CtlTypeProc7_Skip5
	cp	xwa, EVT_PARA_DRAW
	jr	z, PsMixer_CtlTypeProc7_Skip2
	cp	xwa, EVT_SELE_DRAW
	jr	z, PsMixer_CtlTypeProc7_Skip
	cp	xwa, EVT_DRAW
	jrl	nz, PsMixer_CtlTypeProc7_Join3
	lda	xwa, (xsp+64)
	ld	bc, (xsp+12)
	calr	PsMixer_CalcRowBandRect
	lda	xwa, (xsp+64)
	ld	bc, 7:i3
	calr	PsMixer_DrawFrameBoxWithDividers
	ld	wa, (xsp+12)
	exts	xwa
	divs	wa, 5
	ld	wa, qwa
	add	wa, 136
	call	DrawEditSw
	jrl	PsMixer_CtlTypeProc7_Join3
PsMixer_CtlTypeProc7_Skip:
	ld	wa, (xsp+12)
	calr	Util_SignExtendAndDouble
	ld	xiz, xhl
	lda	xwa, (xsp+64)
	ld	bc, (xsp+12)
	calr	PsMixer_CalcRowBandRect
	lda	xwa, (xsp+64)
	ld	xbc, (xsp+72)
	srl	xbc, 16
	ld	qbc, 0
	ld	xde, (xiz+8)
	calr	PsMixer_DrawCaptionFrame
	jrl	PsMixer_CtlTypeProc7_Join3
PsMixer_CtlTypeProc7_Skip2:
	ld	wa, (xsp+12)
	calr	Util_SignExtendAndDouble
	ld	xiz, xhl
	ld	wa, (xsp+14)
	calr	PsMixer_ReadWordArrayEntry
	ld	(xsp+6), hl
	ld	wa, (xiz)
	sla	wa, 2
	lda	xbc, (MixerPartTable_Start_0x80:24)
	ld_rrl	xwa, xbc, wa
	ld	(xsp+8), xwa
	lda	xwa, (xsp+64)
	ld	bc, (xsp+12)
	calr	PsMixer_CalcRowBandRect
	lda	xwa, (xsp+64)
	lda	xbc, (xsp+60)
	ld	de, (xsp+14)
	calr	PsMixer_CalcSwitchPointInFrame
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+8)
	ld	xbc, EVT_GET_PART
	call	ApFuncCall
	ld	(xsp+4), hl
	ld	wa, (xsp+4)
	cp	wa, 65535
	jr	z, PsMixer_CtlTypeProc7_Skip3
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+8)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	iz, hl
	ld	wa, (xsp+4)
	ld	bc, iz
	call	DkMdlyPly_CheckState_Helper
	ld	(xsp+52), hl
	jr	PsMixer_CtlTypeProc7_Join
PsMixer_CtlTypeProc7_Skip3:
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+8)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	xwa, xhl
	call	AcApcToggleProc_Helper
	ld	(xsp+52), hl
PsMixer_CtlTypeProc7_Join:
	ld	bc, iz
	extz	xbc
	ld	wa, (xsp+6)
	extz	xwa
	sll	xwa, 16
	add	xwa, xbc
	lda	xde, (xsp+48)
	ld	(xde), xwa
	lda	xwa, (xsp+16)
	ld	(xde+8), xwa
	ld	xwa, (xsp+8)
	ld	xbc, EVT_GET_LSW_STRING
	call	ApFuncCall
	lda	xwa, (xsp+64)
	lda	xbc, (xsp+60)
	lda	xde, (xsp+16)
	ld	hl, (xsp+12)
	cp	hl, (149394:24)
	jr	nz, PsMixer_CtlTypeProc7_Skip4
	ld	hl, (xsp+14)
	cp	hl, (149392:24)
	jr	nz, PsMixer_CtlTypeProc7_Skip4
	ld	xhl, 3:i3
	push	xhl
	pushw	0
	pushw	7
	pushw	0
	pushw	1
	jr	PsMixer_CtlTypeProc7_Join2
PsMixer_CtlTypeProc7_Skip4:
	ld	xhl, 3:i3
	push	xhl
	pushw	0
	pushw	7
	pushw	0
	pushw	0
PsMixer_CtlTypeProc7_Join2:
	call	DrawStringReverse
	jrl	PsMixer_CtlTypeProc7_Join3
PsMixer_CtlTypeProc7_Skip5:
	ld	wa, (xsp+12)
	calr	Util_SignExtendAndDouble
	ld	xiz, xhl
	ld	wa, (xsp+14)
	calr	PsMixer_ReadWordArrayEntry
	ld	(xsp+6), hl
	ld	wa, (xiz)
	sla	wa, 2
	lda	xbc, (MixerPartTable_Start_0x80:24)
	ld_rrl	xwa, xbc, wa
	ld	(xsp+8), xwa
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+8)
	ld	xbc, EVT_GET_LARGE_STEP
	call	ApFuncCall
	ld	(xsp+14), hl
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+8)
	ld	xbc, EVT_GET_SMALL_STEP
	call	ApFuncCall
	ld	xwa, (xsp+76)
	ld	bc, (xsp+14)
	ld	de, hl
	calr	SdpartScrollDelta
	ld	iz, hl
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+8)
	ld	xbc, EVT_GET_PART
	call	ApFuncCall
	ld	(xsp+4), hl
	ld	(xsp+12), iz
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+8)
	ld	xbc, EVT_GET_LSW_OUTPUT
	call	ApFuncCall
	ld	(xsp+14), hl
	ld	wa, (xsp+4)
	ld	de, (xsp+6)
	exts	xde
	cp	wa, 65535
	jr	z, PsMixer_CtlTypeProc7_Skip6
	ld	xwa, (xsp+8)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	iz, hl
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	pushw	(xsp+14)
	ld	wa, (xsp+6)
	ld	bc, iz
	ld	de, (xsp+14)
	call	MainLswPartAdd
	jrl	PsMixer_CtlTypeProc7_Join3
PsMixer_CtlTypeProc7_Skip6:
	ld	xwa, (xsp+8)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	xwa, xhl
	ld	bc, (xsp+12)
	ld	de, (xsp+14)
	call	MainLswAdd
	jrl	PsMixer_CtlTypeProc7_Join3
PsMixer_CtlTypeProc7_Skip7:
	ld	wa, (xsp+12)
	calr	Util_SignExtendAndDouble
	ld	xiz, xhl
	ld	wa, (xsp+14)
	calr	PsMixer_ReadWordArrayEntry
	ld	(xsp+6), hl
	ld	wa, (xiz)
	sla	wa, 2
	lda	xbc, (MixerPartTable_Start_0x80:24)
	ld_rrl	xwa, xbc, wa
	ld	(xsp+8), xwa
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+8)
	ld	xbc, EVT_CHECK_INIT_DATA
	call	ApFuncCall
	or	xhl, xhl
	jrl	z, PsMixer_CtlTypeProc7_Join3
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+8)
	ld	xbc, EVT_GET_PART
	call	ApFuncCall
	ld	(xsp+4), hl
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+8)
	ld	xbc, EVT_GET_LSW_OUTPUT
	call	ApFuncCall
	ld	(xsp+14), hl
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+8)
	ld	xbc, EVT_GET_INIT_DATA
	call	ApFuncCall
	ld	(xsp+12), hl
	ld	wa, (xsp+4)
	ld	de, (xsp+6)
	exts	xde
	cp	wa, 65535
	jr	z, PsMixer_CtlTypeProc7_Skip8
	ld	xwa, (xsp+8)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	iz, hl
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	pushw	(xsp+14)
	ld	wa, (xsp+6)
	ld	bc, iz
	ld	de, (xsp+14)
	call	MainLswPartPut
	jr	PsMixer_CtlTypeProc7_Join3
PsMixer_CtlTypeProc7_Skip8:
	ld	xwa, (xsp+8)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	xwa, xhl
	ld	bc, (xsp+12)
	ld	de, (xsp+14)
	call	MainLswPut
PsMixer_CtlTypeProc7_Join3:
	ld	xhl, 0:i3
	pop	xiz
	lda	xsp, (xsp+76)
	ret
PsMixer_CtlTypeProc4:
	lda	xsp, (xsp-78)
	push	xiz
	ld	(xsp+74), xde
	ld	(xsp+78), xbc
	ld	xwa, (xsp+74)
	ld	xbc, (xsp+74)
	srl	xbc, 16
	ld	(xsp+10), wa
	ld	qbc, 0
	ld	(xsp+12), bc
	ld	xwa, (xsp+78)
	cp	xwa, EVT_INDEXSW_DOWN_AIC
	jrl	z, PsMixer_CtlTypeProc4_Skip7
	cp	xwa, EVT_INDEXSW_DOWN
	jrl	z, PsMixer_CtlTypeProc4_Skip7
	cp	xwa, EVT_INDEXSW_UP_AIC
	jrl	z, PsMixer_CtlTypeProc4_Skip7
	cp	xwa, EVT_INDEXSW_UP
	jrl	z, PsMixer_CtlTypeProc4_Skip7
	cp	xwa, EVT_PARA_DRAW
	jr	z, PsMixer_CtlTypeProc4_Skip2
	cp	xwa, EVT_SELE_DRAW
	jr	z, PsMixer_CtlTypeProc4_Skip
	cp	xwa, EVT_DRAW
	jrl	nz, PsMixer_CtlTypeProc4_Join4
	lda	xwa, (xsp+66)
	ld	bc, (xsp+10)
	calr	PsMixer_CalcRowBandRect
	lda	xwa, (xsp+66)
	ld	bc, 7:i3
	calr	PsMixer_DrawFrameBoxWithDividers
	ld	wa, (xsp+10)
	exts	xwa
	divs	wa, 5
	ld	wa, qwa
	add	wa, 136
	call	DrawEditSw
	jrl	PsMixer_CtlTypeProc4_Join4
PsMixer_CtlTypeProc4_Skip:
	ld	wa, (xsp+10)
	calr	Util_SignExtendAndDouble
	ld	xiz, xhl
	lda	xwa, (xsp+66)
	ld	bc, (xsp+10)
	calr	PsMixer_CalcRowBandRect
	lda	xwa, (xsp+66)
	ld	xbc, (xsp+74)
	srl	xbc, 16
	ld	qbc, 0
	ld	xde, (xiz+8)
	calr	PsMixer_DrawCaptionFrame
	jrl	PsMixer_CtlTypeProc4_Join4
PsMixer_CtlTypeProc4_Skip2:
	ld	wa, (xsp+10)
	calr	Util_SignExtendAndDouble
	ld	xiz, xhl
	ld	wa, (xsp+12)
	calr	PsMixer_ReadWordArrayEntry
	ld	(xsp+4), hl
	ld	wa, (xiz)
	sla	wa, 2
	lda	xbc, (MixerPartTable_Start_0x80:24)
	ld_rrl	xwa, xbc, wa
	ld	(xsp+6), xwa
	lda	xwa, (xsp+66)
	ld	bc, (xsp+10)
	calr	PsMixer_CalcRowBandRect
	lda	xwa, (xsp+66)
	lda	xbc, (xsp+62)
	ld	de, (xsp+12)
	calr	PsMixer_CalcSwitchPointInFrame
	lda	xiy, (xsp+62)
	lda	xix, (xsp+58)
	ldiw	; v10 does not spell this byte either
	ldiw	; v10 does not spell this byte either
	subw	(xsp+64), 9	; v10 does not spell this byte either
	lda	xwa, (xsp+58)
	decw	7, (xwa)
	decw	1, (xwa+2)
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+6)
	ld	xbc, EVT_GET_PART
	call	ApFuncCall
	ld	iz, hl
	ld	wa, iz
	ld	de, (xsp+4)
	exts	xde
	cp	wa, 65535
	jr	z, PsMixer_CtlTypeProc4_Skip3
	ld	xwa, (xsp+6)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	qiz, hl
	ld	wa, iz
	ld	bc, qiz
	call	DkMdlyPly_CheckState_Helper
	ld	(xsp+50), hl
	jr	PsMixer_CtlTypeProc4_Join
PsMixer_CtlTypeProc4_Skip3:
	ld	xwa, (xsp+6)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	xwa, xhl
	call	AcApcToggleProc_Helper
	ld	(xsp+50), hl
PsMixer_CtlTypeProc4_Join:
	ld	bc, qiz
	extz	xbc
	ld	wa, (xsp+4)
	extz	xwa
	sll	xwa, 16
	add	xwa, xbc
	lda	xde, (xsp+46)
	ld	(xde), xwa
	lda	xwa, (xsp+14)
	ld	(xde+8), xwa
	ld	xwa, (xsp+6)
	ld	xbc, EVT_GET_LSW_STRING
	call	ApFuncCall
	lda	xwa, (xsp+66)
	lda	xbc, (xsp+62)
	lda	xde, (xsp+14)
	ld	hl, (xsp+10)
	cp	hl, (149394:24)
	jr	nz, PsMixer_CtlTypeProc4_Skip4
	ld	hl, (xsp+12)
	cp	hl, (149392:24)
	jr	nz, PsMixer_CtlTypeProc4_Skip4
	ld	xhl, 3:i3
	push	xhl
	pushw	0
	pushw	7
	pushw	0
	pushw	1
	jr	PsMixer_CtlTypeProc4_Join2
PsMixer_CtlTypeProc4_Skip4:
	ld	xhl, 3:i3
	push	xhl
	pushw	0
	pushw	7
	pushw	0
	pushw	0
PsMixer_CtlTypeProc4_Join2:
	call	DrawStringReverse
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+6)
	ld	xbc, EVT_CHECK_PART
	call	ApFuncCall
	lda	xwa, (xsp+58)
	or	xhl, xhl
	jr	z, PsMixer_CtlTypeProc4_Skip5
	cpw	(xsp+50), 0	; v10 does not spell this byte either
	jr	nz, PsMixer_CtlTypeProc4_Skip6
PsMixer_CtlTypeProc4_Skip5:
	ld	xbc, 30
	jr	PsMixer_CtlTypeProc4_Join3
PsMixer_CtlTypeProc4_Skip6:
	ld	xbc, 29
PsMixer_CtlTypeProc4_Join3:
	call	DrawBitmap
	jrl	PsMixer_CtlTypeProc4_Join4
PsMixer_CtlTypeProc4_Skip7:
	ld	wa, (xsp+10)
	calr	Util_SignExtendAndDouble
	ld	xiz, xhl
	ld	wa, (xsp+12)
	calr	PsMixer_ReadWordArrayEntry
	ld	(xsp+4), hl
	ld	wa, (xiz)
	sla	wa, 2
	lda	xbc, (MixerPartTable_Start_0x80:24)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	ld_rrl	xwa, xbc, wa
	ld	(xsp+6), xwa	; v10 does not spell this byte either
	ld	de, (xsp+4)	; v10 does not spell this byte either
	exts	xde
	ld	xwa, (xsp+6)
	ld	xbc, EVT_GET_LARGE_STEP
	call	ApFuncCall
	ld	iz, hl
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+6)
	ld	xbc, EVT_GET_SMALL_STEP
	call	ApFuncCall
	ld	xwa, (xsp+78)
	ld	bc, iz
	ld	de, hl
	calr	SdpartScrollDelta
	ld	(xsp+12), hl
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+6)
	ld	xbc, EVT_GET_PART
	call	ApFuncCall
	ld	iz, hl
	ld	de, (xsp+4)
	exts	xde
	ld	xwa, (xsp+6)
	ld	xbc, EVT_GET_LSW_OUTPUT
	call	ApFuncCall
	ld	(xsp+10), hl
	ld	wa, iz
	ld	de, (xsp+4)
	exts	xde
	cp	wa, 65535
	jr	z, PsMixer_CtlTypeProc4_Skip8
	ld	xwa, (xsp+6)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	ld	qiz, hl
	pushw	(xsp+10)	; v10 does not spell this byte either
	ld	wa, iz
	ld	bc, qiz
	ld	de, (xsp+14)
	call	MainLswPartAdd
	jr	PsMixer_CtlTypeProc4_Join4
PsMixer_CtlTypeProc4_Skip8:
	ld	xwa, (xsp+6)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	xwa, xhl
	ld	bc, (xsp+12)
	ld	de, (xsp+10)
	call	MainLswAdd
PsMixer_CtlTypeProc4_Join4:
	ld	xhl, 0:i3
	pop	xiz
	lda	xsp, (xsp+78)
	ret
PsMixer_CtlTypeProc9:
	lda	xsp, (xsp-76)
	push	xiz
	ld	(xsp+72), xde
	ld	(xsp+76), xbc
	ld	xwa, (xsp+72)
	ld	xbc, (xsp+72)
	srl	xbc, 16
	ld	(xsp+12), wa
	ld	qbc, 0
	ld	(xsp+14), bc
	ld	xwa, (xsp+76)
	cp	xwa, EVT_INDEXSW_DOWN_AIC
	jrl	z, PsMixer_CtlTypeProc9_Skip6
	cp	xwa, EVT_INDEXSW_DOWN
	jrl	z, PsMixer_CtlTypeProc9_Skip6
	cp	xwa, EVT_INDEXSW_UP_AIC
	jrl	z, PsMixer_CtlTypeProc9_Skip6
	cp	xwa, EVT_INDEXSW_UP
	jrl	z, PsMixer_CtlTypeProc9_Skip6
	cp	xwa, EVT_PARA_DRAW
	jr	z, PsMixer_CtlTypeProc9_Skip2
	cp	xwa, EVT_SELE_DRAW
	jr	z, PsMixer_CtlTypeProc9_Skip
	cp	xwa, EVT_DRAW
	jrl	nz, PsMixer_CtlTypeProc9_Join3
	lda	xwa, (xsp+64)
	ld	bc, (xsp+12)
	calr	PsMixer_CalcRowBandRect
	lda	xwa, (xsp+64)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	addw	(xwa+6), 0x20
	ld	bc, 7:i3
	calr	PsMixer_DrawFrameBoxWithDividers
	ld	wa, (xsp+12)
	exts	xwa
	divs	wa, 5
	ld	wa, qwa
	add	wa, 136
	call	DrawEditSw
	jrl	PsMixer_CtlTypeProc9_Join3
PsMixer_CtlTypeProc9_Skip:
	ld	wa, (xsp+12)
	calr	Util_SignExtendAndDouble
	ld	xiz, xhl
	lda	xwa, (xsp+64)
	ld	bc, (xsp+12)
	calr	PsMixer_CalcRowBandRect
	lda	xwa, (xsp+64)
	ld	xbc, (xsp+72)
	srl	xbc, 16
	ld	qbc, 0
	ld	xde, (xiz+8)
	calr	PsMixer_DrawCaptionFrame
	jrl	PsMixer_CtlTypeProc9_Join3
PsMixer_CtlTypeProc9_Skip2:
	ld	wa, (xsp+12)
	calr	Util_SignExtendAndDouble
	ld	xiz, xhl
	ld	wa, (xsp+14)
	calr	PsMixer_ReadWordArrayEntry
	ld	(xsp+6), hl
	ld	wa, (xiz)
	sla	wa, 2
	lda	xbc, (MixerPartTable_Start_0x80:24)
	ld_rrl	xwa, xbc, wa
	ld	(xsp+8), xwa
	lda	xwa, (xsp+64)
	ld	bc, (xsp+12)
	calr	PsMixer_CalcRowBandRect
	lda	xwa, (xsp+64)
	lda	xbc, (xsp+60)
	ld	de, (xsp+14)
	calr	PsMixer_CalcSwitchPointInFrame
	subw	(xsp+62), 9	; v10 does not spell this byte either
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+8)
	ld	xbc, EVT_CHECK_PART
	call	ApFuncCall
	or	xhl, xhl
	jr	z, PsMixer_CtlTypeProc9_Skip4
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+8)
	ld	xbc, EVT_GET_PART
	call	ApFuncCall
	ld	iz, hl
	ld	wa, iz
	ld	de, (xsp+6)
	exts	xde
	cp	wa, 65535
	jr	z, PsMixer_CtlTypeProc9_Skip3
	ld	xwa, (xsp+8)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	(xsp+4), hl
	ld	wa, iz
	ld	bc, (xsp+4)
	call	DkMdlyPly_CheckState_Helper
	jr	PsMixer_CtlTypeProc9_Join
PsMixer_CtlTypeProc9_Skip3:
	ld	xwa, (xsp+8)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	xwa, xhl
	call	AcApcToggleProc_Helper
	jr	PsMixer_CtlTypeProc9_Join
PsMixer_CtlTypeProc9_Skip4:
	ld	hl, 0:i3
PsMixer_CtlTypeProc9_Join:
	ld	(xsp+52), hl
	ld	bc, (xsp+4)
	extz	xbc
	ld	wa, (xsp+6)
	extz	xwa
	sll	xwa, 16
	add	xwa, xbc
	lda	xde, (xsp+48)
	ld	(xde), xwa
	lda	xwa, (xsp+16)
	ld	(xde+8), xwa
	ld	xwa, (xsp+8)
	ld	xbc, EVT_GET_LSW_STRING
	call	ApFuncCall
	lda	xde, (xsp+16)
	lda	xwa, (xsp+64)
	lda	xbc, (xsp+60)
	ld	hl, (xsp+12)
	cp	hl, (149394:24)
	jr	nz, PsMixer_CtlTypeProc9_Skip5
	ld	hl, (xsp+14)
	cp	hl, (149392:24)
	jr	nz, PsMixer_CtlTypeProc9_Skip5
	ld	xhl, 3:i3
	push	xhl
	pushw	0
	pushw	7
	pushw	0
	pushw	1
	jr	PsMixer_CtlTypeProc9_Join2
PsMixer_CtlTypeProc9_Skip5:
	ld	xhl, 3:i3
	push	xhl
	pushw	0
	pushw	7
	pushw	0
	pushw	0
PsMixer_CtlTypeProc9_Join2:
	call	DrawStringReverse
	lda	xwa, (xsp+64)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	addw	(xwa+6), 0x20
	lda	xbc, (xsp+60)
	ld	de, (xsp+14)
	calr	PsMixer_CalcSwitchPointInFrame
	lda	xwa, (xsp+60)
	subw	(xwa), 0xc	; v10 does not spell this byte either
	subw	(xwa+2), 0x13	; v10 does not spell this byte either
	ld	xbc, 2:i3
	call	DrawBitmap
	ldw	wa, 128
	sub	wa, (xsp+52)	; v10 does not spell this byte either
	muls	wa, 36
	exts	xwa
	divs	wa, 128
	ld	bc, wa
	lda	xwa, (xsp+60)
	add	(xwa+2), bc
	ld	xbc, 3:i3
	call	DrawBitmap
	jrl	PsMixer_CtlTypeProc9_Join3
PsMixer_CtlTypeProc9_Skip6:
	ld	wa, (xsp+12)
	calr	Util_SignExtendAndDouble
	ld	xiz, xhl
	ld	wa, (xsp+14)
	calr	PsMixer_ReadWordArrayEntry
	ld	(xsp+6), hl
	ld	wa, (xiz)
	sla	wa, 2
	lda	xbc, (MixerPartTable_Start_0x80:24)
	ld_rrl	xwa, xbc, wa
	ld	(xsp+8), xwa
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+8)
	ld	xbc, EVT_GET_LARGE_STEP
	call	ApFuncCall
	ld	iz, hl
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+8)
	ld	xbc, EVT_GET_SMALL_STEP
	call	ApFuncCall
	ld	xwa, (xsp+76)
	ld	bc, iz
	ld	de, hl
	calr	SdpartScrollDelta
	ld	(xsp+14), hl
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+8)
	ld	xbc, EVT_GET_PART
	call	ApFuncCall
	ld	iz, hl
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+8)
	ld	xbc, EVT_GET_LSW_OUTPUT
	call	ApFuncCall
	ld	(xsp+12), hl
	ld	wa, iz
	ld	de, (xsp+6)
	exts	xde
	cp	wa, 65535
	jr	z, PsMixer_CtlTypeProc9_Skip7
	ld	xwa, (xsp+8)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	(xsp+4), hl
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	pushw	(xsp+12)
	ld	wa, iz
	ld	bc, (xsp+6)
	ld	de, (xsp+16)
	call	MainLswPartAdd
	jr	PsMixer_CtlTypeProc9_Join3
PsMixer_CtlTypeProc9_Skip7:
	ld	xwa, (xsp+8)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	xwa, xhl
	ld	bc, (xsp+14)
	ld	de, (xsp+12)
	call	MainLswAdd
PsMixer_CtlTypeProc9_Join3:
	ld	xhl, 0:i3
	pop	xiz
	lda	xsp, (xsp+76)
	ret
PsMixer_CtlTypeProc2:
	lda	xsp, (xsp-34)
	push	xiz
	ld	(xsp+30), xde
	ld	(xsp+34), xbc
	ld	xde, (xsp+34)
	cp	xde, EVT_LSW_DATA
	jrl	z, PsMixer_CtlTypeProc2_Skip7
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	ld	xbc, (xsp+30)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	srl	xbc, 16
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	ld	qbc, 0
	cp	xde, EVT_INDEXSW_BOTH	; v10 does not spell this byte either
	jrl	z, PsMixer_CtlTypeProc2_Skip5
	cp	xde, EVT_INDEXSW_DOWN_AIC
	jrl	z, PsMixer_CtlTypeProc2_Skip2
	cp	xde, EVT_INDEXSW_DOWN
	jrl	z, PsMixer_CtlTypeProc2_Skip2
	cp	xde, EVT_INDEXSW_UP_AIC
	jrl	z, PsMixer_CtlTypeProc2_Skip2
	cp	xde, EVT_INDEXSW_UP
	jrl	z, PsMixer_CtlTypeProc2_Skip2
	cp	xde, EVT_PARA_DRAW
	jrl	nz, PsMixer_CtlTypeProc2_Skip9
	ld	xbc, (xsp+34)
	ld	xde, (xsp+30)
	calr	PsMixer_CtlTypeProc9
	ld	xwa, (xsp+30)
	ld	(xsp+8), wa
	ld	xwa, (xsp+30)
	srl	xwa, 16
	ld	qwa, 0
	ld	(xsp+10), wa
	ld	wa, (xsp+10)
	calr	PsMixer_ReadWordArrayEntry
	ld	(xsp+6), hl
	ld	xwa, (MixerPartTable_Start_0x104:24)
	ld	(xsp+12), xwa
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, EVT_CHECK_PART
	call	ApFuncCall
	or	xhl, xhl
	jrl	z, PsMixer_CtlTypeProc2_Loop
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, EVT_GET_PART
	call	ApFuncCall
	ld	(xsp+4), hl
	ld	wa, (xsp+4)
	cp	wa, 65535
	jr	z, PsMixer_CtlTypeProc2_Skip
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	(xsp+14), hl
	ld	wa, (xsp+4)
	ld	bc, (xsp+14)
	call	DkMdlyPly_CheckState_Helper
	ld	(xsp+16), hl
	jr	PsMixer_CtlTypeProc2_Entry
PsMixer_CtlTypeProc2_Skip:
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	xiz, xhl
	ld	xwa, xiz
	call	AcApcToggleProc_Helper
	ld	(xsp+16), hl
PsMixer_CtlTypeProc2_Entry:
	cpw	(xsp+16), 0	; v10 does not spell this byte either
	jr	z, PsMixer_CtlTypeProc2_Loop
	lda	xwa, (xsp+22)
	ld	bc, (xsp+8)
	calr	PsMixer_CalcRowBandRect
	lda	xwa, (xsp+22)
	lda	xbc, (xsp+18)
	ld	de, (xsp+10)
	calr	PsMixer_CalcSwitchPointInFrame
	lda	xbc, (xsp+18)
	incw	1, (xbc)
	addw	(xbc+2), 0x12	; v10 does not spell this byte either
	lda	xwa, (xsp+22)
	ld	de, (xbc)
	sub	de, 12
	ld	(xwa), de
	ld	de, (xbc)
	add	de, 12
	ld	(xwa+4), de
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	addw	(xwa+6), 0x12
	ld	xde, 3:i3
	push	xde
	pushw	251
	pushw	0
	pushw	0
	pushw	1
	ld	xde, MidiParam_MixerCfgData_0x6A
	call	DrawStringReverse
PsMixer_CtlTypeProc2_Loop:
	ld	xhl, 0:i3
	jrl	PsMixer_CtlTypeProc2_Epilogue
PsMixer_CtlTypeProc2_Skip2:
	ld	xwa, (xsp+30)
	ld	(xsp+8), wa
	ld	wa, bc
	calr	PsMixer_ReadWordArrayEntry
	ld	(xsp+6), hl
	ld	xwa, (MixerPartTable_Start_0x104:24)
	ld	(xsp+12), xwa
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, EVT_GET_PART
	call	ApFuncCall
	ld	(xsp+4), hl
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, EVT_GET_LSW_OUTPUT
	call	ApFuncCall
	ld	(xsp+10), hl
	ld	wa, (xsp+4)
	cp	wa, 65535
	jr	z, PsMixer_CtlTypeProc2_Skip3
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	(xsp+14), hl
	ld	wa, (xsp+4)
	ld	bc, (xsp+14)
	call	DkMdlyPly_CheckState_Helper
	ld	(xsp+16), hl
	cpw	(xsp+16), 0	; v10 does not spell this byte either
	jr	z, PsMixer_CtlTypeProc2_Join
	pushw	(xsp+10)	; v10 does not spell this byte either
	ld	wa, (xsp+6)
	ld	bc, (xsp+16)
	ld	de, 0:i3	; differs from v10 here and llvm-objdump cannot read it
	call	MainLswPartPut	; differs from v10 here and llvm-objdump cannot read it
	jr	PsMixer_CtlTypeProc2_Join
PsMixer_CtlTypeProc2_Skip3:
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	xiz, xhl
	ld	xwa, xiz
	call	AcApcToggleProc_Helper
	ld	(xsp+16), hl
	cpw	(xsp+16), 0	; v10 does not spell this byte either
	jr	z, PsMixer_CtlTypeProc2_Join
	ld	xwa, xiz
	ld	bc, 0:i3
	ld	de, (xsp+10)
	call	MainLswPut
PsMixer_CtlTypeProc2_Join:
	cpw	(xsp+16), 0	; v10 does not spell this byte either
	jrl	nz, PsMixer_CtlTypeProc2_Loop
	ld	wa, (xsp+8)
	calr	Util_SignExtendAndDouble
	ld	wa, (xhl)
	sla	wa, 2
	lda	xbc, (MixerPartTable_Start_0x80:24)
	ld_rrl	xwa, xbc, wa
	ld	(xsp+12), xwa
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, EVT_GET_LARGE_STEP
	call	ApFuncCall
	ld	(xsp+16), hl
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, EVT_GET_SMALL_STEP
	call	ApFuncCall
	ld	xwa, (xsp+34)
	ld	bc, (xsp+16)
	ld	de, hl
	calr	SdpartScrollDelta
	ld	(xsp+16), hl
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, EVT_GET_PART
	call	ApFuncCall
	ld	(xsp+4), hl
	ld	wa, (xsp+16)
	ld	(xsp+8), wa
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, EVT_GET_LSW_OUTPUT
	call	ApFuncCall
	ld	(xsp+10), hl
	ld	wa, (xsp+4)
	ld	de, (xsp+6)
	exts	xde
	cp	wa, 65535
	jr	z, PsMixer_CtlTypeProc2_Skip4
	ld	xwa, (xsp+12)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	(xsp+14), hl
	pushw	(xsp+10)	; v10 does not spell this byte either
	ld	wa, (xsp+6)
	ld	bc, (xsp+16)
	ld	de, (xsp+10)
	call	MainLswPartAdd	; differs from v10 here and llvm-objdump cannot read it
	jrl	PsMixer_CtlTypeProc2_Loop
PsMixer_CtlTypeProc2_Skip4:
	ld	xwa, (xsp+12)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	xiz, xhl
	ld	xwa, xiz
	ld	bc, (xsp+16)
	ld	de, (xsp+10)
	call	MainLswAdd
	jrl	PsMixer_CtlTypeProc2_Loop
PsMixer_CtlTypeProc2_Skip5:
	ld	wa, bc
	calr	PsMixer_ReadWordArrayEntry
	ld	(xsp+6), hl
	ld	xwa, (MixerPartTable_Start_0x104:24)
	ld	(xsp+12), xwa
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, EVT_GET_PART
	call	ApFuncCall
	ld	(xsp+4), hl
	ld	de, (xsp+6)
	exts	xde
	ld	xwa, (xsp+12)
	ld	xbc, EVT_GET_LSW_OUTPUT
	call	ApFuncCall
	ld	(xsp+10), hl
	ld	wa, (xsp+4)
	ld	de, (xsp+6)
	exts	xde
	cp	wa, 65535
	jr	z, PsMixer_CtlTypeProc2_Skip6
	ld	xwa, (xsp+12)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	(xsp+14), hl
	pushw	(xsp+10)	; v10 does not spell this byte either
	ld	wa, (xsp+6)
	ld	bc, (xsp+16)
	ld	de, 1:i3	; differs from v10 here and llvm-objdump cannot read it
	call	MainLswPartPut	; differs from v10 here and llvm-objdump cannot read it
	jrl	PsMixer_CtlTypeProc2_Loop
PsMixer_CtlTypeProc2_Skip6:
	ld	xwa, (xsp+12)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	xiz, xhl
	ld	xwa, xiz
	ld	bc, 1:i3
	ld	de, (xsp+10)
	call	MainLswPut
	jrl	PsMixer_CtlTypeProc2_Loop
PsMixer_CtlTypeProc2_Skip7:
	ld	xwa, (xsp+30)
	cp	xwa, 8
	jr	z, PsMixer_CtlTypeProc2_Skip8
	cp	xwa, 165899
	jr	z, PsMixer_CtlTypeProc2_Skip8
	cp	xwa, 59400
	jrl	nz, PsMixer_CtlTypeProc2_Loop
PsMixer_CtlTypeProc2_Skip8:
	ld	xhl, 1:i3
	jr	PsMixer_CtlTypeProc2_Epilogue
PsMixer_CtlTypeProc2_Skip9:
	ld	xbc, (xsp+34)
	ld	xde, (xsp+30)
	calr	PsMixer_CtlTypeProc9
PsMixer_CtlTypeProc2_Epilogue:
	pop	xiz
	lda	xsp, (xsp+34)
	ret
PsMixer_CtlTypeProc1:
	lda	xsp, (xsp-94)
	push	xiz
	ld	(xsp+90), xde
	ld	(xsp+94), xbc
	ld	xwa, (xsp+90)
	ld	xbc, (xsp+90)
	srl	xbc, 16
	ld	(xsp+18), wa
	ld	qbc, 0
	ld	(xsp+20), bc
	ld	xwa, (xsp+94)
	cp	xwa, EVT_INDEXSW_DOWN_AIC
	jrl	z, PsMixer_CtlTypeProc1_Skip7
	cp	xwa, EVT_INDEXSW_DOWN
	jrl	z, PsMixer_CtlTypeProc1_Skip7
	cp	xwa, EVT_INDEXSW_UP_AIC
	jrl	z, PsMixer_CtlTypeProc1_Skip7
	cp	xwa, EVT_INDEXSW_UP
	jrl	z, PsMixer_CtlTypeProc1_Skip7
	cp	xwa, EVT_SOUND_NAME
	jrl	z, PsMixer_CtlTypeProc1_Skip3
	cp	xwa, EVT_PARA_DRAW
	jrl	z, PsMixer_CtlTypeProc1_Skip2
	cp	xwa, EVT_SELE_DRAW
	jrl	z, PsMixer_CtlTypeProc1_Skip
	cp	xwa, EVT_DRAW
	jrl	nz, PsMixer_CtlTypeProc1_Join2
	lda	xwa, (xsp+82)
	ld	bc, (xsp+18)
	calr	PsMixer_CalcRowBandRect
	lda	xwa, (xsp+82)
	subw	(xwa+2), 0x16	; v10 does not spell this byte either
	ld	bc, 7:i3
	calr	PsMixer_DrawFrameBox
	ld	wa, (xsp+18)
	exts	xwa
	divs	wa, 5
	ld	wa, qwa
	add	wa, 136
	call	DrawEditSw
	lda	xbc, (xsp+68)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	lda	xde, (xsp+66)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	ldw	wa, 52
	call	GetFrameSPSize
	lda	xhl, (xsp+82)
	ld	wa, (xhl+4)
	sub	wa, (xhl)	; v10 does not spell this byte either
	exts	xwa
	divs	wa, 2
	ld	bc, (xhl)
	add	bc, wa
	lda	xwa, (xsp+74)
	ld	(xwa), bc
	ld	bc, (xsp+66)
	dec	2, bc
	add	bc, (xhl+2)	; v10 does not spell this byte either
	inc	2, bc
	ld	(xwa+2), bc	; v10 does not spell this byte either
	lda	xbc, (xsp+70)
	ld	de, (xwa)
	ld	(xbc), de
	ld	de, (xhl+6)
	dec	2, de
	ld	(xbc+2), de
	ldw	de, 248
	call	DrawLine
	lda	xwa, (xsp+74)
	incw	1, (xwa)
	lda	xbc, (xsp+70)
	incw	1, (xbc)
	ldw	de, 255
	call	DrawLine
	ld	wa, (149396:24)
	ld	(xsp+12), wa
	sla	wa, 3
	ld	(xsp+12), wa
	ldw	(xsp+18), 0
PsMixer_CtlTypeProc1_Loop:
	lda	xwa, (xsp+82)
	lda	xbc, (xsp+78)
	ld	de, (xsp+12)
	calr	PsMixer_CalcGridCellPoint
	subw	(xsp+78), 0x34	; v10 does not spell this byte either
	ld	wa, (xsp+12)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	calr	PsMixer_ReadWordArrayEntry
	ld	(xsp+8), hl
	sla	hl, 2
	lda	xwa, (0x03ea38:24)
	ld_rrl	xwa, xwa, hl	; ld xwa, (xwa+hl)
	push	xwa
	pushw	233
	pushw	63602
	lda	xwa, (xsp+30)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+12)
	lda	xwa, (xsp+82)
	lda	xbc, (xsp+78)
	lda	xde, (xsp+22)
	ld	xhl, 3:i3
	push	xhl
	pushw	0
	pushw	247
	call	DrawStringCentered
	incw	1, (xsp+12)
	incw	1, (xsp+18)
	cpw	(xsp+18), 8	; v10 does not spell this byte either
	jr	lt, PsMixer_CtlTypeProc1_Loop	; v10 does not spell this byte either
	jrl	PsMixer_CtlTypeProc1_Join2
PsMixer_CtlTypeProc1_Skip:
	ld	wa, (xsp+18)
	calr	Util_SignExtendAndDouble
	ld	xiz, xhl
	lda	xwa, (xsp+82)
	ld	bc, (xsp+18)
	calr	PsMixer_CalcRowBandRect
	lda	xwa, (xsp+82)
	subw	(xwa+2), 0x16	; v10 does not spell this byte either
	ld	xbc, (xsp+90)
	srl	xbc, 16
	ld	qbc, 0
	ld	xde, (xiz+8)
	calr	PsMixer_DrawCaptionFrame
	jrl	PsMixer_CtlTypeProc1_Join2
PsMixer_CtlTypeProc1_Skip2:
	ld	wa, (xsp+20)
	calr	PsMixer_ReadWordArrayEntry
	ld	(xsp+8), hl
	add	hl, hl
	lda	xwa, (MixerPartTable_Start_0x12C:24)
	ld_rrw	de, xwa, hl
	exts	xde
	ld	xwa, NAKA_MAINFUNC_MainGetSoundName
	ld	xbc, EVT_GET_SOUND_NAME
	call	FuncCall
	jrl	PsMixer_CtlTypeProc1_Join2
PsMixer_CtlTypeProc1_Skip3:
	ld	xwa, (xsp+90)
	ld	(xsp+4), xwa
	ld	wa, (149398:24)
	muls	wa, 5
	ld	(xsp+10), wa
	ldw	(xsp+18), 0
PsMixer_CtlTypeProc1_Loop2:
	ld	wa, (xsp+10)
	calr	Util_SignExtendAndDouble
	ld	xiz, xhl
	ld	wa, (xiz)
	sla	wa, 2
	lda	xbc, (MixerPartTable_Start_0x80:24)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	ld_rrl	xwa, xbc, wa
	ld	(xsp+14), xwa
	cp	xwa, NAKA_APFUNC_LswSound	; v10 does not spell this byte either
	jrl	nz, PsMixer_CtlTypeProc1_Skip6
	ld	wa, (0x024794:24)
	ld	(xsp+12), wa
	sla	wa, 3
	ld	(xsp+12), wa
	ldw	(xsp+20), 0
PsMixer_CtlTypeProc1_Loop3:
	ld	wa, (xsp+12)
	calr	PsMixer_ReadWordArrayEntry
	ld	(xsp+8), hl
	ld	xwa, (xsp+4)
	ld	bc, (xwa)
	ld	xwa, MixerPartTable_Start_0x12C
	calr	SdpartLookupPartId
	cp	hl, (xsp+8)	; v10 does not spell this byte either
	jrl	nz, PsMixer_CtlTypeProc1_Skip5	; v10 does not spell this byte either
	lda	xwa, (xsp+82)
	ld	bc, (xsp+10)
	calr	PsMixer_CalcRowBandRect
	lda	xwa, (xsp+82)
	subw	(xwa+2), 0x16	; v10 does not spell this byte either
	lda	xbc, (xsp+78)
	ld	de, (xsp+12)
	calr	PsMixer_CalcGridCellPoint
	addw	(xsp+78), 0x14	; v10 does not spell this byte either
	lda	xwa, (xsp+54)
	ld	bc, (xsp+8)
	extz	xbc
	sll	xbc, 16
	ld	(xwa), xbc
	lda	xbc, (xsp+22)
	ld	(xwa+8), xbc
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+2)
	push	xwa
	push	xbc
	call	Free_Compare2
	inc	8, xsp
	lda	xde, (xsp+54)
	ld	xwa, (xsp+14)
	ld	xbc, EVT_GET_LSW_STRING
	call	ApFuncCall
	lda	xbc, (xsp+78)
	lda	xwa, (xsp+82)
	lda	xde, (xsp+22)
	ld	hl, (xsp+10)
	cp	hl, (149394:24)
	jr	nz, PsMixer_CtlTypeProc1_Skip4
	ld	hl, (xsp+12)
	cp	hl, (149392:24)
	jr	nz, PsMixer_CtlTypeProc1_Skip4
	ld	xhl, 3:i3
	push	xhl
	pushw	0
	pushw	7
	pushw	0
	pushw	1
	jr	PsMixer_CtlTypeProc1_Join
PsMixer_CtlTypeProc1_Skip4:
	ld	xhl, 3:i3
	push	xhl
	pushw	0
	pushw	7
	pushw	0
	pushw	0
PsMixer_CtlTypeProc1_Join:
	call	DrawStringReverse
PsMixer_CtlTypeProc1_Skip5:
	incw	1, (xsp+12)
	incw	1, (xsp+20)
	cpw	(xsp+20), 8	; v10 does not spell this byte either
	jrl	lt, PsMixer_CtlTypeProc1_Loop3
PsMixer_CtlTypeProc1_Skip6:
	incw	1, (xsp+10)
	incw	1, (xsp+18)
	cpw	(xsp+18), 5	; v10 does not spell this byte either
	jrl	lt, PsMixer_CtlTypeProc1_Loop2
	jrl	PsMixer_CtlTypeProc1_Join2
PsMixer_CtlTypeProc1_Skip7:
	ld	wa, (xsp+18)
	calr	Util_SignExtendAndDouble
	ld	xiz, xhl
	ld	wa, (xsp+20)
	calr	PsMixer_ReadWordArrayEntry
	ld	(xsp+8), hl
	ld	wa, (xiz)
	sla	wa, 2
	lda	xbc, (MixerPartTable_Start_0x80:24)
	ld_rrl	xwa, xbc, wa
	ld	(xsp+14), xwa
	ld	de, (xsp+8)
	exts	xde
	ld	xwa, (xsp+14)
	ld	xbc, EVT_GET_LARGE_STEP
	call	ApFuncCall
	ld	(xsp+20), hl
	ld	de, (xsp+8)
	exts	xde
	ld	xwa, (xsp+14)
	ld	xbc, EVT_GET_SMALL_STEP
	call	ApFuncCall
	ld	xwa, (xsp+94)
	ld	bc, (xsp+20)
	ld	de, hl
	calr	SdpartScrollDelta
	ld	(xsp+20), hl
	ld	de, (xsp+8)
	exts	xde
	ld	xwa, (xsp+14)
	ld	xbc, EVT_GET_PART
	call	ApFuncCall
	extz	xhl
	ld	wa, (xsp+20)
	extz	xwa
	sll	xwa, 16
	ld	xde, xwa
	add	xde, xhl
	ld	xwa, NAKA_MAINFUNC_MainGetSoundName
	ld	xbc, EVT_ADD_SOUND_SW_NO
	call	MainFuncCall
PsMixer_CtlTypeProc1_Join2:
	ld	xhl, 0:i3
	pop	xiz
	lda	xsp, (xsp+94)
	ret
PsMixer_CtlTypeProc10:
	lda	xsp, (xsp-56)
	push	xiz
	cp	xbc, EVT_DRAW
	jr	z, PsMixer_CtlTypeProc10_Skip
	calr	PsMixer_CtlTypeProc1
	jrl	PsMixer_CtlTypeProc10_Epilogue
PsMixer_CtlTypeProc10_Skip:
	ld	iz, de
	lda	xwa, (xsp+52)
	ld	bc, iz
	calr	PsMixer_CalcRowBandRect
	lda	xwa, (xsp+52)
	subw	(xwa+2), 0x16	; v10 does not spell this byte either
	ld	bc, 7:i3
	calr	PsMixer_DrawFrameBox
	ld	wa, iz
	exts	xwa
	divs	wa, 5
	ld	wa, qwa
	add	wa, 136
	call	DrawEditSw
	lda	xbc, (xsp+38)
	lda	xde, (xsp+36)
	ldw	wa, 52
	call	GetFrameSPSize
	lda	xhl, (xsp+52)
	ld	wa, (xhl+4)
	sub	wa, (xhl)	; v10 does not spell this byte either
	exts	xwa
	divs	wa, 2
	ld	bc, (xhl)
	add	bc, wa
	lda	xwa, (xsp+44)
	ld	(xwa), bc
	ld	bc, (xsp+36)
	dec	2, bc
	add	bc, (xhl+2)	; v10 does not spell this byte either
	inc	2, bc
	ld	(xwa+2), bc	; v10 does not spell this byte either
	lda	xbc, (xsp+40)
	ld	de, (xwa)
	ld	(xbc), de
	ld	de, (xhl+6)
	dec	2, de
	ld	(xbc+2), de
	ldw	de, 248
	call	DrawLine
	lda	xwa, (xsp+44)
	incw	1, (xwa)
	lda	xbc, (xsp+40)
	incw	1, (xbc)
	ldw	de, 255
	call	DrawLine
	ld	iz, (0x024794:24)
	sla	iz, 3
	ld	qiz, 0
PsMixer_CtlTypeProc10_Loop:
	lda	xwa, (xsp+52)
	lda	xbc, (xsp+48)
	ld	de, iz
	calr	PsMixer_CalcGridCellPoint
	subw	(xsp+48), 0x34	; v10 does not spell this byte either
	ld	wa, iz
	sla	wa, 2
	lda	xbc, (256808:24)
	ld_rrl	xwa, xbc, wa
	push	xwa
	pushw	233
	pushw	63606
	lda	xwa, (xsp+12)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+12)
	lda	xwa, (xsp+52)
	lda	xbc, (xsp+48)
	lda	xde, (xsp+4)
	ld	xhl, 3:i3
	push	xhl
	pushw	0
	pushw	247
	call	DrawStringCentered
	inc	1, iz
	inc	1, qiz
	cpw	qiz, 8
	jr	lt, PsMixer_CtlTypeProc10_Loop
	ld	xhl, 0:i3
PsMixer_CtlTypeProc10_Epilogue:
	pop	xiz
	lda	xsp, (xsp+56)
	ret
PsMixer_CtlTypeProc8:
	lda	xsp, (xsp-18)
	pushw	iz
	ld	(xsp+16), xbc
	ld	xbc, (xsp+16)
	cp	xbc, EVT_LSW_DATA
	jrl	z, PsMixer_CtlTypeProc8_Skip4
	cp	xbc, EVT_INDEXSW_DOWN_AIC
	jr	z, PsMixer_CtlTypeProc8_Skip
	cp	xbc, EVT_INDEXSW_DOWN
	jr	z, PsMixer_CtlTypeProc8_Skip
	cp	xbc, EVT_INDEXSW_UP_AIC
	jr	z, PsMixer_CtlTypeProc8_Skip
	cp	xbc, EVT_INDEXSW_UP
	jr	z, PsMixer_CtlTypeProc8_Skip
	ld	xbc, (xsp+16)
	calr	PsMixer_CtlTypeProc7
	jrl	PsMixer_CtlTypeProc8_Epilogue
PsMixer_CtlTypeProc8_Skip:
	ld	wa, de
	srl	xde, 16
	ld	qde, 0
	ld	iz, de
	calr	Util_SignExtendAndDouble
	ld	(xsp+12), xhl
	ld	wa, iz
	calr	PsMixer_ReadWordArrayEntry
	ld	(xsp+8), hl
	ld	xwa, (xsp+12)
	ld	wa, (xwa)
	sla	wa, 2
	lda	xbc, (MixerPartTable_Start_0x80:24)
	ld_rrl	xwa, xbc, wa
	ld	(xsp+10), xwa
	ld	de, (xsp+8)
	exts	xde
	ld	xwa, (xsp+10)
	ld	xbc, EVT_GET_LARGE_STEP
	call	ApFuncCall
	ld	(xsp+14), hl
	ld	de, (xsp+8)
	exts	xde
	ld	xwa, (xsp+10)
	ld	xbc, EVT_GET_SMALL_STEP
	call	ApFuncCall
	ld	xwa, (xsp+16)
	ld	bc, (xsp+14)
	ld	de, hl
	calr	SdpartScrollDelta
	ld	(xsp+14), hl
	ld	de, (xsp+8)
	exts	xde
	ld	xwa, (xsp+10)
	ld	xbc, EVT_GET_PART
	call	ApFuncCall
	ld	(xsp+2), hl
	ld	wa, (xsp+14)
	ld	(xsp+4), wa
	ld	de, (xsp+8)
	exts	xde
	ld	xwa, (xsp+10)
	ld	xbc, EVT_GET_LSW_OUTPUT
	call	ApFuncCall
	ld	(xsp+6), hl
	ld	de, (xsp+8)
	exts	xde
	ld	xwa, (xsp+10)
	ld	xbc, EVT_GET_LSW_DATA_NO
	call	ApFuncCall
	ld	(xsp+12), hl
	ld	wa, (xsp+2)
	cp	wa, 65535
	jrl	z, PsMixer_CtlTypeProc8_Loop
	cpw	(xsp+14), 0	; v10 does not spell this byte either
	jrl	z, PsMixer_CtlTypeProc8_Entry
	ld	xwa, (xsp+16)
	cp	xwa, EVT_INDEXSW_DOWN_AIC
	jr	z, PsMixer_CtlTypeProc8_Skip3
	cp	xwa, EVT_INDEXSW_DOWN
	jr	z, PsMixer_CtlTypeProc8_Skip3
	cp	xwa, EVT_INDEXSW_UP_AIC
	jr	z, PsMixer_CtlTypeProc8_Skip2
	cp	xwa, EVT_INDEXSW_UP
	jr	nz, PsMixer_CtlTypeProc8_Entry
PsMixer_CtlTypeProc8_Skip2:
	ld	wa, (xsp+2)
	ldw	bc, 1026
	call	DkMdlyPly_CheckState_Helper
	cp	hl, 0:i3
	jr	nz, PsMixer_CtlTypeProc8_Entry
	pushw	(xsp+6)	; v10 does not spell this byte either
	ld	wa, (xsp+4)
	ldw	bc, 1026
	ld	de, 1:i3
	call	MainLswPartPut
	pushw	(xsp+6)	; v10 does not spell this byte either
	ld	wa, (xsp+4)
	ldw	bc, 1027
	ld	de, 1:i3
	call	MainLswPartPut
	pushw	(xsp+6)	; v10 does not spell this byte either
	ld	wa, (xsp+4)
	ld	bc, (xsp+14)
	ld	de, 0:i3
	jr	PsMixer_CtlTypeProc8_Join
PsMixer_CtlTypeProc8_Skip3:
	ld	wa, (xsp+2)
	ldw	bc, 1025
	call	DkMdlyPly_CheckState_Helper
	cp	hl, 0:i3
	jr	nz, PsMixer_CtlTypeProc8_Entry
	pushw	(xsp+6)	; v10 does not spell this byte either
	ld	wa, (xsp+4)
	ldw	bc, 1026
	ld	de, 0:i3
	call	MainLswPartPut
	pushw	(xsp+6)	; v10 does not spell this byte either
	ld	wa, (xsp+4)
	ldw	bc, 1027
	ld	de, 0:i3
PsMixer_CtlTypeProc8_Join:
	call	MainLswPartPut
PsMixer_CtlTypeProc8_Loop:
	ld	xhl, 0:i3
	jr	PsMixer_CtlTypeProc8_Epilogue
PsMixer_CtlTypeProc8_Entry:
	pushw	(xsp+6)	; v10 does not spell this byte either
	ld	wa, (xsp+4)
	ld	bc, (xsp+14)
	ld	de, (xsp+6)
	call	MainLswPartAdd
	jr	PsMixer_CtlTypeProc8_Loop
PsMixer_CtlTypeProc8_Skip4:
	cp	xde, 1026
	jr	z, PsMixer_CtlTypeProc8_Skip5
	cp	xde, 1027
	jr	nz, PsMixer_CtlTypeProc8_Loop
PsMixer_CtlTypeProc8_Skip5:
	ld	xhl, 1:i3
PsMixer_CtlTypeProc8_Epilogue:
	popw	iz
	lda	xsp, (xsp+18)
	ret
AudioCtrl_DataBlock_Return:
	ret
AudioCtrl_DataBlock_Return2:
	ret
PostTitle_Function_Helper:
	ret
AudioCtrl_DataBlock_Return3:
	ret
IvDrawbarProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, EVT_GET_STRING
	jrl z, IvDrawbar_GetText
	cp xiz, EVT_PART_SELECT
	jrl z, IvDrawbar_Refresh
	cp xiz, EVT_LSW_DATA
	jrl z, IvDrawbar_Match
	cp xiz, EVT_SOUND_SW_NO
	jrl z, IvDrawbar_Update
	cp xiz, EVT_INDEX_SELECT
	jrl z, IvDrawbar_Release
	cp xiz, EVT_SW_IN
	jrl z, IvDrawbar_OK
	cp xiz, EVT_REFRESH_PARA_DRAW
	jrl z, IvDrawbar_DrawbarUpdate
	cp xiz, EVT_REFRESH_PARAM
	jrl z, IvDrawbar_LoadVals
	cp xiz, EVT_DRAW
	jrl z, IvDrawbar_Paint
	cp xiz, EVT_REPAINT
	jrl z, IvDrawbar_ShowHide
	cp xiz, EVT_PAINT
	jrl z, IvDrawbar_ShowHide
	cp xiz, EVT_HIDE
	jrl z, IvDrawbar_Close
	cp xiz, EVT_SHOW
	jrl nz, IvDrawbar_ForwardToBase
	ld xwa, (xsp + 4)
	cp xwa, 0x3
	jr z, IvDrawbar_Init_Part03
	or xwa, xwa
	jr nz, IvDrawbar_Init_SetupMode

IvDrawbar_Init_Part03:
	ldw (0x024798:24), 0x0000
	call GetPartSelect
	ld (0x02479a:24), hl
	ldw (0x03e99e:24), 0x0000
	call GetModeNow
	cp xhl, NAKA_MODE_MD_SOUNDEDIT
	jr z, IvDrawbar_Init_CheckDualMode
	ld xwa, (xsp + 8)
	ld xbc, EVT_REFRESH_PARAM
	ld xde, 0:i3
	jr IvDrawbar_Init_DispatchLoadVals

IvDrawbar_Init_CheckDualMode:
	ld a, (0x0205f2:24)
	bit 0, a
	jr z, IvDrawbar_Init_SetupMode
	res 0, a
	ld (0x0205f2:24), a
	ld xwa, (xsp + 8)
	ld xbc, EVT_REFRESH_PARAM
	ld xde, 0:i3

IvDrawbar_Init_DispatchLoadVals:
	call SendEvent

IvDrawbar_Init_SetupMode:
	call GetModeNow
	cp xhl, NAKA_MODE_MD_SOUNDEDIT
	jrl z, IvDrawbar_Init_ModernMode
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 1:i3
	call SendEvent
	; object handle 0xea0026 = class 0x0ea, instance 38 (SendEvent indexes its class table by bits 16-27; not an address -- was IvDrawbar_Init_SetupMode_Str_Gt)
	ld xwa, IvDrawbar_Init_SetupMode_Str_Gt
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld de, (0x024798:24)
	inc 1, de
	exts xde
	ld xwa, 0xffffffff
	ld xbc, EVT_PAGE_INIT
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 0:i3
	call SendEvent
	; object handle 0xea001e = class 0x0ea, instance 30 (SendEvent indexes its class table by bits 16-27; not an address -- was IvDrawbar_Init_SetupMode_Str_ENTATION)
	ld xwa, IvDrawbar_Init_SetupMode_Str_ENTATION
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	call SendEvent
	call GetModeNow
	cp xhl, NAKA_MODE_MD_NORMAL
	jrl nz, IvDrawbar_ReturnHandled
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_KEEP
	ld xde, 1:i3
	jrl IvDrawbar_DispatchEvent

IvDrawbar_Init_ModernMode:
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 1:i3
	call SendEvent
	; object handle 0xea001e = class 0x0ea, instance 30 (SendEvent indexes its class table by bits 16-27; not an address -- was IvDrawbar_Init_SetupMode_Str_ENTATION)
	ld xwa, IvDrawbar_Init_SetupMode_Str_ENTATION
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld de, (0x024798:24)
	inc 1, de
	exts xde
	ld xwa, 0xffffffff
	ld xbc, EVT_PAGE_INIT
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 0:i3
	call SendEvent
	ld xwa, IvDrawbar_Init_SetupMode_Str_Gt
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	jrl IvDrawbar_DispatchEvent

IvDrawbar_Close:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	jrl IvDrawbar_CallBase

IvDrawbar_ShowHide:
	call GetPartSelect
	ld (0x02479a:24), hl
	ld wa, hl
	calr SndParam_ResolveOscEntry
	ld xde, xhl
	ld xwa, (xsp + 8)
	ld xbc, EVT_SOUND_SW_NO
	call SendEvent
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 8)
	ld xbc, EVT_REFRESH_PARA_DRAW
	ld xde, 1:i3
	call SendEvent
	ld xwa, (xsp + 8)
	ld xbc, EVT_REFRESH_PARA_DRAW
	ld xde, 2:i3
	call SendEvent
	ld xwa, (xsp + 8)
	ld xbc, EVT_REFRESH_PARA_DRAW
	ld xde, 3:i3
	jrl IvDrawbar_DispatchEvent

IvDrawbar_Paint:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 8)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl IvDrawbar_DispatchEvent

IvDrawbar_LoadVals:
	call	GetModeNow
	cp	xhl, NAKA_MODE_MD_SOUNDEDIT
	jr	z, IvDrawbar_LoadVals_DualMode
	ld	wa, (149402:24)
	ldw	bc, 705
	call	DkMdlyPly_CheckState_Helper
	ld	(149442:24), hl
	ld	wa, (149402:24)
	ldw	bc, 704
	call	DkMdlyPly_CheckState_Helper
	ld	(149444:24), hl
	jrl	IvDrawbar_ReturnHandled
IvDrawbar_LoadVals_DualMode:
	ld xwa, NAKA_MAINFUNC_MainMemDrawControl
	ld xbc, EVT_REQUEST_MEMORY_DRAWBAR
	ld xde, 0:i3
	jrl IvDrawbar_Release_SendParam

IvDrawbar_DrawbarUpdate:
	ld xwa, (xsp + 4)
	cp xwa, 0x3
	jr z, IvDrawbar_DrawbarUpdate_Lower
	cp xwa, 0x2
	jrl nz, IvDrawbar_ReturnHandled
	cpw (0x247c2:24), 0
	jr z, IvDrawbar_DrawbarUpdate_UpperOff
	; object handle 0xea0003 = class 0x0ea, instance 3 (SendEvent indexes its class table by bits 16-27; not an address -- was Presentation_RootEntry_0x3)
	ld xwa, Presentation_RootEntry_0x3
	ld xbc, EVT_SET_PARAM
	ld xde, 1:i3
	call SendEvent
	ld xwa, Presentation_RootEntry_0x4
	ld xbc, EVT_DRAW
	ld xde, 0:i3
	jrl IvDrawbar_DispatchEvent

IvDrawbar_DrawbarUpdate_UpperOff:
	; object handle 0xea0003 = class 0x0ea, instance 3 (SendEvent indexes its class table by bits 16-27; not an address -- was Presentation_RootEntry_0x3)
	ld xwa, Presentation_RootEntry_0x3
	ld xbc, EVT_SET_PARAM
	ld xde, 0:i3
	call SendEvent
	ld xwa, Presentation_RootEntry_0x5
	ld xbc, EVT_DRAW
	ld xde, 0:i3
	jrl IvDrawbar_DispatchEvent

IvDrawbar_DrawbarUpdate_Lower:
	ld de, (0x0247c4:24)
	exts xde
	ld xwa, Presentation_RootEntry_0x2
	ld xbc, EVT_SET_PARAM
	jrl IvDrawbar_DispatchEvent

IvDrawbar_OK:
	ld xwa, (xsp + 4)
	cp xwa, 0xf
	jr nz, IvDrawbar_OK_Forward
	cpw (0x24798:24), 0
	jr nz, IvDrawbar_OK_PageChange
	call GetTitleNow
	ld xwa, xhl
	ld xbc, EVT_IS_INTERRUPT
	ld xde, 0:i3
	call SendEvent
	or xhl, xhl
	jr nz, IvDrawbar_OK_Locked
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_MODE
	ld xde, NAKA_MODE_MD_SOUND
	jr IvDrawbar_OK_Dispatch

IvDrawbar_OK_Locked:
	ld xwa, 0xffffffff
	ld xbc, EVT_INTERRUPT_EXIT
	ld xde, 0:i3

IvDrawbar_OK_Dispatch:
	call SendEvent
	jrl IvDrawbar_ReturnHandled

IvDrawbar_OK_PageChange:
	ldw (0x024798:24), 0x0000
	ld xwa, 0xffffffff
	ld xbc, EVT_PAGE_CHANGE
	ld xde, 1:i3
	call SendEvent
	ld xwa, (xsp + 8)
	ld xbc, EVT_REFRESH_PARA_DRAW
	ld xde, 1:i3
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
	cpw (0x24798:24), 0
	scc16 z, wa
	ld (0x024798:24), wa
	inc 1, wa
	ld de, wa
	exts xde
	ld xwa, 0xffffffff
	ld xbc, EVT_PAGE_CHANGE
	call SendEvent
	ld xwa, (xsp + 8)
	ld xbc, EVT_REFRESH_PARA_DRAW
	ld xde, 1:i3
	call PostEvent
	jrl IvDrawbar_ReturnHandled

IvDrawbar_Release_Upper:
	call GetModeNow
	cp xhl, NAKA_MODE_MD_SOUNDEDIT
	jr z, IvDrawbar_Release_Upper_DualMode
	ld wa, (0x02479a:24)
	pushw 0x4
	ldw bc, 0x2c1
	ld de, 1:i3
	jr IvDrawbar_Release_WriteValue

IvDrawbar_Release_Upper_DualMode:
	cpw (0x247c2:24), 0
	scc16 z, de
	extz xde
	add xde, 0x90000
	ld xwa, NAKA_MAINFUNC_MainMemDrawControl
	ld xbc, EVT_SET_MEMORY_DRAWBAR
	jr IvDrawbar_Release_SendParam

IvDrawbar_Release_Lower:
	call GetModeNow
	cp xhl, NAKA_MODE_MD_SOUNDEDIT
	jr z, IvDrawbar_Release_Lower_DualMode
	ld wa, (0x02479a:24)
	pushw 0x4
	ldw bc, 0x2c0
	ld de, 1:i3

IvDrawbar_Release_WriteValue:
	call MainLswPartPut
	jrl IvDrawbar_ReturnHandled

IvDrawbar_Release_Lower_DualMode:
	cpw (0x247c4:24), 0
	scc16 z, de
	extz xde
	add xde, 0xa0000
	ld xwa, NAKA_MAINFUNC_MainMemDrawControl
	ld xbc, EVT_SET_MEMORY_DRAWBAR

IvDrawbar_Release_SendParam:
	call MainFuncCall
	jrl IvDrawbar_ReturnHandled

IvDrawbar_Update:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	call GetModeNow
	cp xhl, NAKA_MODE_MD_SOUNDEDIT
	jrl z, IvDrawbar_ReturnHandled
	ld xwa, (xsp + 4)
	ld bc, (0x02479a:24)
	cp bc, wa
	jrl nz, IvDrawbar_ReturnHandled
	ld xwa, (xsp + 4)
	srl xwa, 16
	ldiw_erp 0xe2, 0
	ld bc, wa
	srl bc, 8
	ld b, 0x0:opc
	cp c, 0xc
	jr nz, IvDrawbar_Update_GenericParam
	extz wa
	ld (0x02479c:24), wa
	jrl IvDrawbar_ReturnHandled

IvDrawbar_Update_GenericParam:
	ld xwa, 0xffffffff
	ld xbc, EVT_INTERRUPT_EXIT
	ld xde, 0:i3

IvDrawbar_Update_Dispatch:
	call PostEvent
	jrl IvDrawbar_ReturnHandled

IvDrawbar_Match:
	ld xhl, (xsp + 4)
	ld bc, (0x02479a:24)
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
	ld xbc, EVT_SOUND_SW_NO
	jr IvDrawbar_Match_DispatchEvent

IvDrawbar_Match_CheckUpper:
	ld xix, xde
	add xix, 0x82c1
	ld bc, (xhl + 4)
	ld xwa, (xsp + 4)
	cp xix, (xwa)
	jr nz, IvDrawbar_Match_CheckLower
	ld (0x0247c2:24), bc
	ld xwa, (xsp + 8)
	ld xbc, EVT_REFRESH_PARA_DRAW
	ld xde, 2:i3
	jr IvDrawbar_Match_DispatchEvent

IvDrawbar_Match_CheckLower:
	add xde, 0x82c0
	cp xde, (xhl)
	jr nz, IvDrawbar_Match_Forward
	ld (0x0247c4:24), bc
	ld xwa, (xsp + 8)
	ld xbc, EVT_REFRESH_PARA_DRAW
	ld xde, 3:i3

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
	ld (0x02479a:24), hl
	ld wa, hl
	calr SndParam_ResolveOscEntry
	ld xde, xhl
	ld xwa, (xsp + 8)
	ld xbc, EVT_SOUND_SW_NO
	call SendEvent
	ld xwa, (xsp + 8)
	ld xbc, EVT_REFRESH_PARAM
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xsp + 8)
	ld xbc, EVT_REFRESH_PARA_DRAW
	ld xde, 2:i3
	call SendEvent
	ld xwa, (xsp + 8)
	ld xbc, EVT_REFRESH_PARA_DRAW
	ld xde, 3:i3

IvDrawbar_DispatchEvent:
	call SendEvent
	jr IvDrawbar_ReturnHandled

IvDrawbar_GetText:
	pushw	IvDrawbar_GetText_Str_Draw@hi16
	pushw	IvDrawbar_GetText_Str_Draw@lo16
	ld	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
IvDrawbar_ReturnHandled:
	ld xhl, 0:i3
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
	cp xwa, EVT_CHECK_INDEX
	jr z, DrawCombo_CompareMatch
	cp xwa, EVT_GET_INDEX
	jr z, DrawCombo_GetWidgetValue
	cp xwa, EVT_SW_IN
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
	cp hl, 0:i3
	jr z, DrawCombo_ForwardToBase
	ld xwa, xiz
	ld xbc, EVT_CHECK_EDIT_SW
	ld xde, (xsp + 8)
	call SendEvent
	cp hl, 0:i3
	jr z, DrawCombo_ForwardToBase
	ld xwa, (xsp + 4)
	ld de, (xwa + 40)
	cp de, 0xffff
	jr z, DrawCombo_ReturnZero
	exts xde
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEX_SELECT
	call SendEvent

DrawCombo_ReturnZero:
	ld xhl, 0:i3
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
	cp xiz, EVT_SOUND_NAME
	jrl z, AcDrawbarName_Notify
	cp xiz, EVT_TONE_MODE
	jrl z, AcDrawbarName_DrawbarInit
	cp xiz, EVT_PART_SELECT
	jrl z, AcDrawbarName_Refresh
	cp xiz, EVT_LSW_DATA
	jrl z, AcDrawbarName_Match
	cp xiz, EVT_SW_IN
	jrl z, AcDrawbarName_OK
	cp xiz, EVT_DRAW
	jr z, AcDrawbarName_Paint
	cp xiz, EVT_REPAINT
	jr z, AcDrawbarName_ShowHide
	cp xiz, EVT_PAINT
	jr z, AcDrawbarName_ShowHide
	cp xiz, EVT_HIDE
	jr z, AcDrawbarName_Close
	cp xiz, EVT_SHOW
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
	ld xwa, NAKA_MAINFUNC_MainMemDrawControl
	ld xbc, EVT_GET_TONE_MODE
	jrl AcDrawbarName_SendDrawbarNameSet

AcDrawbarName_ShowHide_NoInstr:
	call GetPartSelect
	extz xhl
	ld xwa, NAKA_MAINFUNC_MainMemDrawControl
	ld xbc, EVT_GET_TONE_MODE
	ld xde, xhl
	jrl AcDrawbarName_SendDrawbarNameSet

AcDrawbarName_Paint:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	call GetModeNow
	cp xhl, NAKA_MODE_MD_SOUNDEDIT
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
	ld xbc, EVT_INDEXSW_DOWN
	jrl AcDrawbarName_DispatchEvent

AcDrawbarName_OK_ScrollUp:
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEXSW_UP
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
	ld xwa, NAKA_MAINFUNC_MainMemDrawControl
	ld xbc, EVT_GET_TONE_MODE
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
	ld xwa, NAKA_MAINFUNC_MainMemDrawControl
	ld xbc, EVT_GET_TONE_MODE
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
	ld xwa, NAKA_MAINFUNC_MainMemDrawControl
	ld xbc, EVT_GET_TONE_MODE
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
	srl xbc, 16
	ldiw_erp 0xe6, 0
	ld de, (xwa)
	cp bc, de
	jrl nz, AcDrawbarName_ReturnHandled
	ld xwa, (xsp + 8)
	cp wa, 1:i3
	jrl nz, AcDrawbarName_ReturnHandled
	extz xde
	ld xwa, NAKA_MAINFUNC_MainGetSoundName
	ld xbc, EVT_GET_SOUND_NAME
	jr AcDrawbarName_DrawbarInit_OpenEditor

AcDrawbarName_DrawbarInit_NoInstr:
	call GetPartSelect
	ld xwa, (xsp + 8)
	srl xwa, 16
	ldiw_erp 0xe2, 0
	cp wa, hl
	jr nz, AcDrawbarName_ReturnHandled
	ld xwa, (xsp + 8)
	cp wa, 1:i3
	jr nz, AcDrawbarName_ReturnHandled
	call GetPartSelect
	extz xhl
	ld xwa, NAKA_MAINFUNC_MainGetSoundName
	ld xbc, EVT_GET_SOUND_NAME
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
	ld xbc, EVT_PARA_DRAW
	jr AcDrawbarName_DispatchEvent

AcDrawbarName_Notify_NoInstr:
	call GetPartSelect
	ld xwa, (xsp + 8)
	cp (xwa), hl
	jr nz, AcDrawbarName_ReturnHandled
	ld xde, (xwa + 2)
	ld xwa, (xsp + 12)
	ld xbc, EVT_PARA_DRAW

AcDrawbarName_DispatchEvent:
	call SendEvent

AcDrawbarName_ReturnHandled:
	ld xhl, 0:i3
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
	cp xwa, EVT_PAGE_CHANGE
	jrl z, DrawCombo_CloseWidget
	cp xwa, EVT_PAGE_INIT
	jr z, DrawCombo_InitWidget
	cp xwa, EVT_GET_STRING
	jr z, DrawCombo_GetText
	cp xwa, EVT_DRAW
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
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl DrawCombo_SendEvent

DrawCombo_GetText:
	pushw	DrawCombo_GetText_Str_PAGE@hi16
	pushw	DrawCombo_GetText_Str_PAGE@lo16
	ld	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jrl	AcDrawComboBox_Return
DrawCombo_InitWidget:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 24)
	ld xbc, EVT_CHECK_SHOW_WINDOW
	ld xde, 0:i3
	call SendEvent
	or xhl, xhl
	jr z, DrawCombo_InitForward
	ld xwa, (xiz + 24)
	ld xbc, EVT_HIDE
	ld xde, 0:i3
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
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	jr DrawCombo_SendEvent

DrawCombo_CloseWidget:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 24)
	ld xbc, EVT_CHECK_SHOW_WINDOW
	ld xde, 0:i3
	call SendEvent
	or xhl, xhl
	jr z, DrawCombo_CloseForward
	ld xwa, (xiz + 24)
	ld xbc, EVT_HIDE
	ld xde, 5:i3
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
	ld xbc, EVT_SHOW
	ld xde, 5:i3

DrawCombo_SendEvent:
	call SendEvent

AcDrawComboBox_Return:
	ld xhl, 0:i3

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
	cp xhl, NAKA_MODE_MD_SOUNDEDIT
	jr z, EditBox_CheckDialEvent
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	jrl EditBox_CallInherited2

EditBox_CheckDialEvent:
	cp xiz, EVT_INDEXSW_DOWN
	jr z, AcEditBox_DialApplyEvent
	cp xiz, EVT_INDEXSW_DOWN_AIC
	jr z, AcEditBox_DialApplyEvent
	cp xiz, EVT_INDEXSW_UP
	jr z, AcEditBox_DialApplyEvent
	cp xiz, EVT_INDEXSW_UP_AIC
	jr z, AcEditBox_DialApplyEvent
	cp xiz, EVT_REPAINT
	jr z, EditBox_ShowHide
	cp xiz, EVT_PAINT
	jr nz, EditBox_ForwardToBase

EditBox_ShowHide:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	jr EditBox_CallInherited

AcEditBox_DialApplyEvent:
	ld xwa, (xsp + 8)
	ld xbc, EVT_CHECK_SELECTED
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
	ld xhl, 0:i3
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
	push	xiz
	ld	xiz, xwa
	cp	xbc, EVT_INDEXSW_DOWN
	jrl	z, Lsw_PercDecay_DialScroll	; -> 0xF82C44
	cp	xbc, EVT_INDEXSW_DOWN_AIC
	jrl	z, Lsw_PercDecay_DialScroll	; -> 0xF82C44
	cp	xbc, EVT_INDEXSW_UP
	jrl	z, Lsw_PercDecay_DialScroll	; -> 0xF82C44
	cp	xbc, EVT_INDEXSW_UP_AIC
	jrl	z, Lsw_PercDecay_DialScroll	; -> 0xF82C44
	cp	xbc, EVT_LSW_DATA_REQ
	jr	z, LswPercDecay_StoreDE	; -> 0xF82C3D
	cp	xbc, EVT_GET_SMALL_STEP
	jr	z, LswPercDecay_ReturnOne	; -> 0xF82C2E
	cp	xbc, EVT_GET_LARGE_STEP
	jr	z, LswPercDecay_ReturnOne	; -> 0xF82C2E
	cp	xbc, EVT_GET_LSW_OUTPUT
	jr	z, LswPercDecay_StepSize	; -> 0xF82C39
	cp	xbc, EVT_GET_LSW_DATA_NO
	jr	z, LswPercDecay_SubParam	; -> 0xF82C32
	cp	xbc, EVT_CHECK_PART
	jr	z, LswPercDecay_ReturnOne	; -> 0xF82C2E
	cp	xbc, EVT_GET_PART
	jr	z, LswPercDecay_PartIdLookup	; -> 0xF82C1F
	cp	xbc, EVT_GET_LSW_STRING
	jr	nz, LswPercDecay_Return	; -> 0xF82C76
	ld	wa, (xde+4)
	sla	wa, 2
	lda	xbc, (KeyShift_DisplayStrTable:24)
	ld_rrl	xwa, xbc, wa
	push	xwa
	ld	xwa, (xde+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, xiz
	jr	LswPercDecay_PopIzRet	; -> 0xF82C78
LswPercDecay_PartIdLookup:
	add xde, xde
	ld xwa, MixerPartTable_Start_0x12C
	add xwa, xde
	ld hl, (xwa)
	exts xhl
	jr LswPercDecay_PopIzRet

LswPercDecay_ReturnOne:
	ld xhl, 1:i3
	jr LswPercDecay_PopIzRet

LswPercDecay_SubParam:
	ld xhl, 0x2cc
	jr LswPercDecay_PopIzRet

LswPercDecay_StepSize:
	ld xhl, 3:i3
	jr LswPercDecay_PopIzRet

LswPercDecay_StoreDE:
	ld (0x0247c6:24), de
	jr LswPercDecay_Return

Lsw_PercDecay_DialScroll:
	ld xwa, xbc
	ld bc, 1:i3
	ld de, 1:i3
	calr SdpartScrollDelta
	ld bc, hl
	ld wa, (0x0247c6:24)
	calr SdpartClampSignedScrollDelta
	cp hl, (0x247c6:24)
	jr z, LswPercDecay_Return
	extz xhl
	add xhl, 0xb0000
	ld xwa, NAKA_MAINFUNC_MainMemDrawControl
	ld xbc, EVT_SET_MEMORY_DRAWBAR
	ld xde, xhl
	call MainFuncCall

LswPercDecay_Return:
	ld xhl, 0:i3

LswPercDecay_PopIzRet:
	pop xiz
	ret

SdpartClampSignedScrollDelta:
	ld hl, wa
	cp wa, 7:i3
	jr le, SdpartClamp_CheckUpper
	sub wa, 0x10

SdpartClamp_CheckUpper:
	cp wa, 5:i3
	jr gt, SdpartClamp_ReturnZero
	cp wa, 0xfffb
	jr ge, SdpartClamp_Apply

SdpartClamp_ReturnZero:
	ld hl, 0:i3
	ret

SdpartClamp_Apply:
	add wa, bc
	cp wa, 5:i3
	ret gt
	cp wa, 0xfffb
	ret lt
	cp wa, 0:i3
	jr ge, SdpartClamp_StoreResult
	add wa, 0x10

SdpartClamp_StoreResult:
	ld hl, wa
	ret

LswPercLevel:
	push	xiz
	ld	xiz, xwa
	cp	xbc, EVT_INDEXSW_DOWN
	jrl	z, Lsw_PercLevel_DialScroll	; -> 0xF82D53
	cp	xbc, EVT_INDEXSW_DOWN_AIC
	jrl	z, Lsw_PercLevel_DialScroll	; -> 0xF82D53
	cp	xbc, EVT_INDEXSW_UP
	jrl	z, Lsw_PercLevel_DialScroll	; -> 0xF82D53
	cp	xbc, EVT_INDEXSW_UP_AIC
	jrl	z, Lsw_PercLevel_DialScroll	; -> 0xF82D53
	cp	xbc, EVT_LSW_DATA_REQ
	jr	z, LswPercLevel_StoreDE	; -> 0xF82D4C
	cp	xbc, EVT_GET_SMALL_STEP
	jr	z, LswPercLevel_ReturnOne	; -> 0xF82D3D
	cp	xbc, EVT_GET_LARGE_STEP
	jr	z, LswPercLevel_ReturnOne	; -> 0xF82D3D
	cp	xbc, EVT_GET_LSW_OUTPUT
	jr	z, LswPercLevel_StepSize	; -> 0xF82D48
	cp	xbc, EVT_GET_LSW_DATA_NO
	jr	z, LswPercLevel_SubParam	; -> 0xF82D41
	cp	xbc, EVT_CHECK_PART
	jr	z, LswPercLevel_ReturnOne	; -> 0xF82D3D
	cp	xbc, EVT_GET_PART
	jr	z, LswPercLevel_PartIdLookup	; -> 0xF82D2E
	cp	xbc, EVT_GET_LSW_STRING
	jr	nz, LswPercLevel_Return	; -> 0xF82D85
	ld	wa, (xde+4)
	sla	wa, 2
	lda	xbc, (KeyShift_DisplayStrTable:24)
	ld_rrl	xwa, xbc, wa
	push	xwa
	ld	xwa, (xde+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, xiz
	jr	LswPercLevel_PopIzRet	; -> 0xF82D87
LswPercLevel_PartIdLookup:
	add xde, xde
	ld xwa, MixerPartTable_Start_0x12C
	add xwa, xde
	ld hl, (xwa)
	exts xhl
	jr LswPercLevel_PopIzRet

LswPercLevel_ReturnOne:
	ld xhl, 1:i3
	jr LswPercLevel_PopIzRet

LswPercLevel_SubParam:
	ld xhl, 0x2cb
	jr LswPercLevel_PopIzRet

LswPercLevel_StepSize:
	ld xhl, 3:i3
	jr LswPercLevel_PopIzRet

LswPercLevel_StoreDE:
	ld (0x0247c8:24), de
	jr LswPercLevel_Return

Lsw_PercLevel_DialScroll:
	ld xwa, xbc
	ld bc, 1:i3
	ld de, 1:i3
	calr SdpartScrollDelta
	ld bc, hl
	ld wa, (0x0247c8:24)
	calr SdpartClampSignedScrollDelta
	cp hl, (0x247c8:24)
	jr z, LswPercLevel_Return
	extz xhl
	add xhl, 0xc0000
	ld xwa, NAKA_MAINFUNC_MainMemDrawControl
	ld xbc, EVT_SET_MEMORY_DRAWBAR
	ld xde, xhl
	call MainFuncCall

LswPercLevel_Return:
	ld xhl, 0:i3

LswPercLevel_PopIzRet:
	pop xiz
	ret

LswDrawAttack:
	push	xiz
	ld	xiz, xwa
	cp	xbc, EVT_INDEXSW_DOWN
	jrl	z, Lsw_DrawAttack_DialScroll	; -> 0xF82E34
	cp	xbc, EVT_INDEXSW_DOWN_AIC
	jrl	z, Lsw_DrawAttack_DialScroll	; -> 0xF82E34
	cp	xbc, EVT_INDEXSW_UP
	jrl	z, Lsw_DrawAttack_DialScroll	; -> 0xF82E34
	cp	xbc, EVT_INDEXSW_UP_AIC
	jrl	z, Lsw_DrawAttack_DialScroll	; -> 0xF82E34
	cp	xbc, EVT_LSW_DATA_REQ
	jr	z, LswDrawAttack_StoreDE	; -> 0xF82E2D
	cp	xbc, EVT_GET_SMALL_STEP
	jr	z, LswDrawAttack_ReturnOne	; -> 0xF82E1E
	cp	xbc, EVT_GET_LARGE_STEP
	jr	z, LswDrawAttack_ReturnOne	; -> 0xF82E1E
	cp	xbc, EVT_GET_LSW_OUTPUT
	jr	z, LswDrawAttack_StepSize	; -> 0xF82E29
	cp	xbc, EVT_GET_LSW_DATA_NO
	jr	z, LswDrawAttack_SubParam	; -> 0xF82E22
	cp	xbc, EVT_CHECK_PART
	jr	z, LswDrawAttack_ReturnOne	; -> 0xF82E1E
	cp	xbc, EVT_GET_PART
	jr	z, LswDrawAttack_PartIdLookup	; -> 0xF82E0F
	cp	xbc, EVT_GET_LSW_STRING
	jr	nz, LswDrawAttack_Return	; -> 0xF82E66
	ld	wa, (xde+4)
	sla	wa, 2
	lda	xbc, (KeyShift_DisplayStrTable:24)
	ld_rrl	xwa, xbc, wa
	push	xwa
	ld	xwa, (xde+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, xiz
	jr	LswDrawAttack_PopIzRet	; -> 0xF82E68
LswDrawAttack_PartIdLookup:
	add xde, xde
	ld xwa, MixerPartTable_Start_0x12C
	add xwa, xde
	ld hl, (xwa)
	exts xhl
	jr LswDrawAttack_PopIzRet

LswDrawAttack_ReturnOne:
	ld xhl, 1:i3
	jr LswDrawAttack_PopIzRet

LswDrawAttack_SubParam:
	ld xhl, 0x294
	jr LswDrawAttack_PopIzRet

LswDrawAttack_StepSize:
	ld xhl, 3:i3
	jr LswDrawAttack_PopIzRet

LswDrawAttack_StoreDE:
	ld (0x0247cc:24), de
	jr LswDrawAttack_Return

Lsw_DrawAttack_DialScroll:
	ld xwa, xbc
	ld bc, 1:i3
	ld de, 1:i3
	calr SdpartScrollDelta
	ld bc, hl
	ld wa, (0x0247cc:24)
	calr SdpartClampSignedScrollDelta
	cp hl, (0x247cc:24)
	jr z, LswDrawAttack_Return
	extz xhl
	add xhl, 0xe0000
	ld xwa, NAKA_MAINFUNC_MainMemDrawControl
	ld xbc, EVT_SET_MEMORY_DRAWBAR
	ld xde, xhl
	call MainFuncCall

LswDrawAttack_Return:
	ld xhl, 0:i3

LswDrawAttack_PopIzRet:
	pop xiz
	ret

LswDrawRelease:
	push	xiz
	ld	xiz, xwa
	cp	xbc, EVT_INDEXSW_DOWN
	jrl	z, Lsw_DrawRelease_DialScroll	; -> 0xF82F15
	cp	xbc, EVT_INDEXSW_DOWN_AIC
	jrl	z, Lsw_DrawRelease_DialScroll	; -> 0xF82F15
	cp	xbc, EVT_INDEXSW_UP
	jrl	z, Lsw_DrawRelease_DialScroll	; -> 0xF82F15
	cp	xbc, EVT_INDEXSW_UP_AIC
	jrl	z, Lsw_DrawRelease_DialScroll	; -> 0xF82F15
	cp	xbc, EVT_LSW_DATA_REQ
	jr	z, LswDrawRelease_StoreDE	; -> 0xF82F0E
	cp	xbc, EVT_GET_SMALL_STEP
	jr	z, LswDrawRelease_ReturnOne	; -> 0xF82EFF
	cp	xbc, EVT_GET_LARGE_STEP
	jr	z, LswDrawRelease_ReturnOne	; -> 0xF82EFF
	cp	xbc, EVT_GET_LSW_OUTPUT
	jr	z, LswDrawRelease_StepSize	; -> 0xF82F0A
	cp	xbc, EVT_GET_LSW_DATA_NO
	jr	z, LswDrawRelease_SubParam	; -> 0xF82F03
	cp	xbc, EVT_CHECK_PART
	jr	z, LswDrawRelease_ReturnOne	; -> 0xF82EFF
	cp	xbc, EVT_GET_PART
	jr	z, LswDrawRelease_PartIdLookup	; -> 0xF82EF0
	cp	xbc, EVT_GET_LSW_STRING
	jr	nz, LswDrawRelease_Return	; -> 0xF82F47
	ld	wa, (xde+4)
	sla	wa, 2
	lda	xbc, (KeyShift_DisplayStrTable:24)
	ld_rrl	xwa, xbc, wa
	push	xwa
	ld	xwa, (xde+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, xiz
	jr	LswDrawRelease_PopIzRet	; -> 0xF82F49
LswDrawRelease_PartIdLookup:
	add xde, xde
	ld xwa, MixerPartTable_Start_0x12C
	add xwa, xde
	ld hl, (xwa)
	exts xhl
	jr LswDrawRelease_PopIzRet

LswDrawRelease_ReturnOne:
	ld xhl, 1:i3
	jr LswDrawRelease_PopIzRet

LswDrawRelease_SubParam:
	ld xhl, 0x293
	jr LswDrawRelease_PopIzRet

LswDrawRelease_StepSize:
	ld xhl, 3:i3
	jr LswDrawRelease_PopIzRet

LswDrawRelease_StoreDE:
	ld (0x0247ca:24), de
	jr LswDrawRelease_Return

Lsw_DrawRelease_DialScroll:
	ld xwa, xbc
	ld bc, 1:i3
	ld de, 1:i3
	calr SdpartScrollDelta
	ld bc, hl
	ld wa, (0x0247ca:24)
	calr SdpartClampSignedScrollDelta
	cp hl, (0x247ca:24)
	jr z, LswDrawRelease_Return
	extz xhl
	add xhl, 0xd0000
	ld xwa, NAKA_MAINFUNC_MainMemDrawControl
	ld xbc, EVT_SET_MEMORY_DRAWBAR
	ld xde, xhl
	call MainFuncCall

LswDrawRelease_Return:
	ld xhl, 0:i3

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
	cp xwa, EVT_GET_STRING
	jrl z, IvDrawbar1_GetText
	cp xwa, EVT_PART_SELECT
	jrl z, IvDrawbar1_Refresh
	cp xwa, EVT_LSW_DATA
	jrl z, IvDrawbar1_Match
	cp xwa, EVT_SW_IN
	jrl z, IvDrawbar1_OK
	cp xwa, EVT_REFRESH_PARA_DRAW
	jrl z, IvDrawbar1_DrawbarUpdate
	cp xwa, EVT_REFRESH_PARAM
	jrl z, IvDrawbar1_LoadVals
	cp xwa, EVT_DRAW
	jrl z, IvDrawbar1_Paint
	cp xwa, EVT_REPAINT
	jr z, IvDrawbar1_ShowHide
	cp xwa, EVT_PAINT
	jr z, IvDrawbar1_ShowHide
	cp xwa, EVT_HIDE
	jr z, IvDrawbar1_Close
	cp xwa, EVT_SHOW
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
	ld (0x02479a:24), hl
	ld xwa, (xsp + 12)
	ld xbc, EVT_REFRESH_PARAM
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	ld de, (0x024798:24)
	exts xde
	; object handle 0xea000c = class 0x0ea, instance 12 (SendEvent indexes its class table by bits 16-27; not an address -- was IvDrawbar1_ShowHide_Str_SENTATION)
	ld xwa, IvDrawbar1_ShowHide_Str_SENTATION
	ld xbc, EVT_SET_PARAM
	call SendEvent
	ld xwa, (xsp + 12)
	ld xbc, EVT_REFRESH_PARA_DRAW
	ld xde, 0xffffffff
	jrl IvDrawbar1_DispatchEvent

IvDrawbar1_Paint:
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 12)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl IvDrawbar1_DispatchEvent

IvDrawbar1_LoadVals:
	call GetModeNow
	cp xhl, NAKA_MODE_MD_SOUNDEDIT
	jr z, IvDrawbar1_LoadVals_DualMode
	ld iz, 0:i3

IvDrawbar1_LoadVals_Loop:
	ld	wa, (149402:24)
	ld	bc, iz
	extz	xbc
	add	xbc, xbc
	ld	xde, MidiParam_MixerCfgData_0x78
	add	xde, xbc
	ld	bc, (xde)
	call	DkMdlyPly_CheckState_Helper
	ld	wa, iz
	extz	xwa
	add	xwa, xwa
	ld	xbc, 149424
	add	xbc, xwa
	ld	(xbc), hl
	inc	1, iz
	cp	iz, 8
	jr	ule, IvDrawbar1_LoadVals_Loop
	jrl	IvDrawbar1_ReturnHandled
IvDrawbar1_LoadVals_DualMode:
	ld xwa, NAKA_MAINFUNC_MainMemDrawControl
	ld xbc, EVT_REFRESH_PARAM
	ld xde, 0:i3
	call MainFuncCall
	jrl IvDrawbar1_ReturnHandled

IvDrawbar1_DrawbarUpdate:
	ld xwa, (xsp + 4)
	cp xwa, 0x8
	jr ule, IvDrawbar1_DrawbarUpdate_OneSlider
	ld iz, 0:i3

IvDrawbar1_DrawbarUpdate_AllSliders:
	ld de, iz
	extz xde
	ld xwa, (xsp + 12)
	ld xbc, EVT_REFRESH_PARA_DRAW
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
	ld wa, 1:i3
	call SetNeedUpdate
	call UpdateScreen
	ld wa, 0:i3
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
	ld xbc, EVT_MAKE_EDIT_SW_ID
	ld xde, (xsp + 4)
	call SendEvent
	ldfr_werp HL, 0xfa
	cpiw_erp 0xfa, 7
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
	lda xwa, (0x0247b0:24)
	ld	iz, (xwa+bc)
	ld xwa, (xsp + 4)
	bit 7, wa
	jr z, IvDrawbar1_OK_ScrollDown
	inc 1, iz
	cp iz, 0x8
	jrl gt, IvDrawbar1_ReturnHandled
	call GetModeNow
	cp xhl, NAKA_MODE_MD_SOUNDEDIT
	jr z, IvDrawbar1_OK_ScrollUp_DualMode
	ld wa, (0x02479a:24)
	ldto_werp BC, 0xfa
	add bc, bc
	lda xde, (MidiParam_MixerCfgData_0x78:24)
	ld	bc, (xde+bc)
	pushw 0x4
	ld de, iz
	call MainLswPartPut
	jr IvDrawbar1_OK_ScrollRelease

IvDrawbar1_OK_ScrollUp_DualMode:
	ldto_werp BC, 0xfa
	add bc, bc
	lda xwa, (0x0247b0:24)
	ld	wa, (xwa+bc)
	cp wa, 0x8
	jr ge, IvDrawbar1_OK_ScrollRelease
	inc 1, wa
	ld bc, wa
	extz xbc
	ldto_werp WA, 0xfa
	extz xwa
	sll xwa, 16
	ld xde, xwa
	add xde, xbc
	ld xwa, NAKA_MAINFUNC_MainMemDrawControl
	ld xbc, EVT_SET_MEMORY_DRAWBAR
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
	cp xhl, NAKA_MODE_MD_SOUNDEDIT
	jr z, IvDrawbar1_OK_ScrollDown_DualMode
	ld wa, (0x02479a:24)
	lda xde, (MidiParam_MixerCfgData_0x78:24)
	ld	bc, (xde+bc)
	pushw 0x4
	ld de, iz
	call MainLswPartPut
	jr IvDrawbar1_OK_ScrollDown_Release

IvDrawbar1_OK_ScrollDown_DualMode:
	lda xwa, (0x0247b0:24)
	ld	wa, (xwa+bc)
	cp wa, 0:i3
	jr le, IvDrawbar1_OK_ScrollDown_Release
	dec 1, wa
	ld bc, wa
	extz xbc
	ldto_werp WA, 0xfa
	extz xwa
	sll xwa, 16
	ld xde, xwa
	add xde, xbc
	ld xwa, NAKA_MAINFUNC_MainMemDrawControl
	ld xbc, EVT_SET_MEMORY_DRAWBAR
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
	ld de, (0x02479a:24)
	exts xde
	sll xde, 10
	ld xbc, xde
	add xbc, 0x8280
	ld xwa, (xsp + 4)
	lda xhl, (xwa + 4)
	cp xbc, (xwa)
	jr nz, IvDrawbar1_Match_Ch1
	ld wa, (xhl)
	ld (0x0247b0:24), wa
	ld xwa, (xsp + 12)
	ld xbc, EVT_REFRESH_PARA_DRAW
	ld xde, 0:i3
	jrl IvDrawbar1_Match_DispatchUpdate

IvDrawbar1_Match_Ch1:
	ld xwa, xde
	add xwa, 0x8282
	cp xwa, (xix)
	jr nz, IvDrawbar1_Match_Ch2
	ld wa, (xhl)
	ld (0x0247b2:24), wa
	ld xwa, (xsp + 12)
	ld xbc, EVT_REFRESH_PARA_DRAW
	ld xde, 1:i3
	jrl IvDrawbar1_Match_DispatchUpdate

IvDrawbar1_Match_Ch2:
	ld xwa, xde
	add xwa, 0x8281
	cp xwa, (xix)
	jr nz, IvDrawbar1_Match_Ch3
	ld wa, (xhl)
	ld (0x0247b4:24), wa
	ld xwa, (xsp + 12)
	ld xbc, EVT_REFRESH_PARA_DRAW
	ld xde, 2:i3
	jrl IvDrawbar1_Match_DispatchUpdate

IvDrawbar1_Match_Ch3:
	ld xwa, xde
	add xwa, 0x8283
	cp xwa, (xix)
	jr nz, IvDrawbar1_Match_Ch4
	ld wa, (xhl)
	ld (0x0247b6:24), wa
	ld xwa, (xsp + 12)
	ld xbc, EVT_REFRESH_PARA_DRAW
	ld xde, 3:i3
	jrl IvDrawbar1_Match_DispatchUpdate

IvDrawbar1_Match_Ch4:
	ld xwa, xde
	add xwa, 0x8284
	lda xbc, (0x0247b0:24)
	cp xwa, (xix)
	jr nz, IvDrawbar1_Match_Ch5
	ld wa, (xhl)
	ld (xbc + 8), wa
	ld xwa, (xsp + 12)
	ld xbc, EVT_REFRESH_PARA_DRAW
	ld xde, 4:i3
	jr IvDrawbar1_Match_DispatchUpdate

IvDrawbar1_Match_Ch5:
	ld xwa, xde
	add xwa, 0x8285
	cp xwa, (xix)
	jr nz, IvDrawbar1_Match_Ch6
	ld wa, (xhl)
	ld (xbc + 10), wa
	ld xwa, (xsp + 12)
	ld xbc, EVT_REFRESH_PARA_DRAW
	ld xde, 5:i3
	jr IvDrawbar1_Match_DispatchUpdate

IvDrawbar1_Match_Ch6:
	ld xwa, xde
	add xwa, 0x8286
	cp xwa, (xix)
	jr nz, IvDrawbar1_Match_Ch7
	ld wa, (xhl)
	ld (xbc + 12), wa
	ld xwa, (xsp + 12)
	ld xbc, EVT_REFRESH_PARA_DRAW
	ld xde, 6:i3
	jr IvDrawbar1_Match_DispatchUpdate

IvDrawbar1_Match_Ch7:
	ld xiy, xde
	add xiy, 0x8287
	ld wa, (xhl)
	cp xiy, (xix)
	jr nz, IvDrawbar1_Match_Ch8
	ld (xbc + 14), wa
	ld xwa, (xsp + 12)
	ld xbc, EVT_REFRESH_PARA_DRAW
	ld xde, 7:i3
	jr IvDrawbar1_Match_DispatchUpdate

IvDrawbar1_Match_Ch8:
	add xde, 0x8288
	cp xde, (xix)
	jr nz, IvDrawbar1_Match_Forward
	ld (xbc + 16), wa
	ld xwa, (xsp + 12)
	ld xbc, EVT_REFRESH_PARA_DRAW
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
	ld (0x02479a:24), hl
	ld xwa, (xsp + 12)
	ld xbc, EVT_REFRESH_PARAM
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xsp + 12)
	ld xbc, EVT_REFRESH_PARA_DRAW
	ld xde, 0xffffffff

IvDrawbar1_DispatchEvent:
	call SendEvent
	jr IvDrawbar1_ReturnHandled

IvDrawbar1_GetText:
	pushw	IvDrawbar1_GetText_Str_Drw1@hi16
	pushw	IvDrawbar1_GetText_Str_Drw1@lo16
	ld	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
IvDrawbar1_ReturnHandled:
	ld xhl, 0:i3
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
	cp xiz, EVT_GET_STRING
	jrl z, IvDrawbar2_GetText
	cp xiz, EVT_INDEXSW_DOWN
	jrl z, IvDrawbar2_OKHandler
	cp xiz, EVT_INDEXSW_UP
	jrl z, IvDrawbar2_OKHandler
	cp xiz, EVT_LSW_DATA
	jrl z, IvDrawbar2_MatchHandler
	cp xiz, EVT_REFRESH_PARAM
	jr z, IvDrawbar2_LoadValsHandler
	cp xiz, EVT_DRAW
	jr z, IvDrawbar2_PaintHandler
	cp xiz, EVT_REPAINT
	jr z, IvDrawbar2_ShowHideHandler
	cp xiz, EVT_PAINT
	jr z, IvDrawbar2_ShowHideHandler
	cp xiz, EVT_SHOW
	jrl nz, IvDrawbar2_ForwardToBase
	ld xwa, (xsp + 8)
	ld xbc, EVT_REFRESH_PARAM
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	jrl IvDrawbar2_CallInherited

IvDrawbar2_ShowHideHandler:
	call GetPartSelect
	ld (0x02479a:24), hl
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld de, (0x024798:24)
	exts xde
	; object handle 0xea000c = class 0x0ea, instance 12 (SendEvent indexes its class table by bits 16-27; not an address -- was IvDrawbar1_ShowHide_Str_SENTATION)
	ld xwa, IvDrawbar1_ShowHide_Str_SENTATION
	ld xbc, EVT_SET_PARAM
	jr IvDrawbar2_SendEventShared

IvDrawbar2_PaintHandler:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 8)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3

IvDrawbar2_SendEventShared:
	call SendEvent
	jrl IvDrawbar_ReturnZeroJmp

IvDrawbar2_LoadValsHandler:
	call	GetModeNow
	cp	xhl, NAKA_MODE_MD_SOUNDEDIT
	jr	z, IvDrawbar2_LoadMode3
	ld	wa, (149402:24)
	ldw	bc, 716
	call	DkMdlyPly_CheckState_Helper
	ld	(149446:24), hl
	ld	wa, (149402:24)
	ldw	bc, 715
	call	DkMdlyPly_CheckState_Helper
	ld	(149448:24), hl
	ld	wa, (149402:24)
	ldw	bc, 659
	call	DkMdlyPly_CheckState_Helper
	ld	(149450:24), hl
	ld	wa, (149402:24)
	ldw	bc, 660
	call	DkMdlyPly_CheckState_Helper
	ld	(149452:24), hl
	jrl	IvDrawbar_ReturnZeroJmp
IvDrawbar2_LoadMode3:
	ld xwa, NAKA_MAINFUNC_MainMemDrawControl
	ld xbc, EVT_REFRESH_PARAM
	ld xde, 0:i3
	jrl IvDrawbar2_MainFuncCallShared

IvDrawbar2_MatchHandler:
	ld xhl, (xsp + 4)
	ld bc, (0x02479a:24)
	exts xbc
	sll xbc, 10
	ld xix, xbc
	add xix, 0x82cc
	ld xwa, (xsp + 4)
	lda xde, (xwa + 4)
	cp xix, (xwa)
	jr nz, IvDrawbar2_MatchCheck2CB
	ld wa, (xde)
	ld (0x0247c6:24), wa
	jr IvDrawbar_ForwardUnhandled

IvDrawbar2_MatchCheck2CB:
	ld xwa, xbc
	add xwa, 0x82cb
	cp xwa, (xhl)
	jr nz, IvDrawbar2_MatchCheck294
	ld wa, (xde)
	ld (0x0247c8:24), wa
	jr IvDrawbar_ForwardUnhandled

IvDrawbar2_MatchCheck294:
	ld xix, xbc
	add xix, 0x8294
	ld wa, (xde)
	cp xix, (xhl)
	jr nz, IvDrawbar2_MatchCheck293
	ld (0x0247cc:24), wa
	jr IvDrawbar_ForwardUnhandled

IvDrawbar2_MatchCheck293:
	add xbc, 0x8293
	cp xbc, (xhl)
	jr nz, IvDrawbar_ForwardUnhandled
	ld (0x0247ca:24), wa

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
	cp xhl, NAKA_MODE_MD_SOUNDEDIT
	jr z, IvDrawbar_ReturnZeroJmp
	ld bc, (0x02479a:24)
	extz xbc
	cpw (0x2479c:24), 0
	scc16 z, wa
	extz wa
	add wa, 0xc00
	extz xwa
	sll xwa, 16
	ld xde, xwa
	add xde, xbc
	ld xwa, NAKA_MAINFUNC_MainGetSoundName
	ld xbc, EVT_SET_SOUND_SW_NO

IvDrawbar2_MainFuncCallShared:
	call MainFuncCall
	jr IvDrawbar_ReturnZeroJmp

IvDrawbar2_GetText:
	pushw	IvDrawbar2_GetText_Str_Drw2@hi16
	pushw	IvDrawbar2_GetText_Str_Drw2@lo16
	ld	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
IvDrawbar_ReturnZeroJmp:
	ld xhl, 0:i3
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
	cp xiz, EVT_GET_STRING
	jrl z, DrawbarNorm_GetText
	cp xiz, EVT_PART_SELECT
	jrl z, DrawbarNorm_Refresh
	cp xiz, EVT_LSW_DATA
	jrl z, DrawbarNorm_Match
	cp xiz, EVT_INDEX_SELECT
	jrl z, DrawbarNorm_Notify
	cp xiz, EVT_REFRESH_PARA_DRAW
	jr z, DrawbarNorm_Update
	cp xiz, EVT_DRAW
	jr z, DrawbarNorm_Paint
	cp xiz, EVT_REPAINT
	jr z, DrawbarNorm_ShowHide
	cp xiz, EVT_PAINT
	jrl nz, DrawbarNorm_ForwardToBase

DrawbarNorm_ShowHide:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 8)
	ld xbc, EVT_REFRESH_PARA_DRAW
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xsp + 8)
	ld xbc, EVT_REFRESH_PARA_DRAW
	ld xde, 4:i3
	jrl IvDrawbarNorm_SendEvent

DrawbarNorm_Paint:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 8)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl IvDrawbarNorm_SendEvent

DrawbarNorm_Update:
	ld	xwa, (xsp+4)
	cp	xwa, 4
	jr	z, DrawbarNorm_UpdateCase4
	or	xwa, xwa
	jrl	nz, IvDrawbarNorm_ReturnZeroJmp
	ld	xwa, 16387
	call	AcApcToggleProc_Helper
	exts	xhl
	ld	xwa, Presentation_TagStrTable_0x18
	ld	xbc, EVT_SET_PARAM
	ld	xde, xhl
	jrl	IvDrawbarNorm_SendEvent
DrawbarNorm_UpdateCase4:
	ld wa, (0x02479a:24)
	sla wa, 2
	lda xbc, (0x03e9a0:24)
	ld	xde, (xbc+wa)
	; object handle 0xea001f = class 0x0ea, instance 31 (SendEvent indexes its class table by bits 16-27; not an address -- was Presentation_TagStrTable_0x17)
	ld xwa, Presentation_TagStrTable_0x17
	ld xbc, EVT_PARA_DRAW
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
	ld bc, 1:i3
	ld de, 4:i3
	call MainLswPut
	jr IvDrawbarNorm_ReturnZeroJmp

DrawbarNorm_Match:
	ld xwa, (xsp + 4)
	ld xwa, (xwa)
	cp xwa, 0x4003
	jr nz, DrawbarNorm_MatchForward
	ld xwa, (xsp + 8)
	ld xbc, EVT_REFRESH_PARA_DRAW
	ld xde, 0:i3
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
	ld (0x02479a:24), hl
	ld xwa, (xsp + 8)
	ld xbc, EVT_REFRESH_PARA_DRAW
	ld xde, 4:i3

IvDrawbarNorm_SendEvent:
	call SendEvent
	jr IvDrawbarNorm_ReturnZeroJmp

DrawbarNorm_GetText:
	pushw	DrawbarNorm_GetText_Str_DrwN@hi16
	pushw	DrawbarNorm_GetText_Str_DrwN@lo16
	ld	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
IvDrawbarNorm_ReturnZeroJmp:
	ld xhl, 0:i3
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
	cp xbc, EVT_GET_STRING
	jr z, DrawbarSndE_GetText
	cp xbc, EVT_DRAW
	jr z, DrawbarSndE_Paint
	ld xwa, xiz
	call InheritedProc
	jr DrawbarSndE_Epilogue

DrawbarSndE_Paint:
	ld xwa, xiz
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call SendEvent
	jr DrawbarSndE_ReturnZero

DrawbarSndE_GetText:
	pushw	DrawbarSndE_GetText_Str_DrwE@hi16
	pushw	DrawbarSndE_GetText_Str_DrwE@lo16
	push	xde
	call	Free_Compare2
	inc	8, xsp
DrawbarSndE_ReturnZero:
	ld xhl, 0:i3

DrawbarSndE_Epilogue:
	pop xiz
	ret

DrawbarBitmapHelper:
	dec 4, xsp
	ld de, wa
	lda xwa, (xsp)
	ld hl, de
	add hl, hl
	lda xix, (KeyShiftStr_Zero_0x28:24)
	ld	hl, (xix+hl)
	ld (xwa), hl
	ldw (xwa + 2), 0x72
	sla de, 2
	lda xhl, (0x03ec28:24)
	ld	xde, (xhl+de)
	sla bc, 2
	lda xhl, (KeyShiftStr_Zero_0x3A:24)
	ld	xbc, (xhl+bc)
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
	cp xbc, EVT_GET_TONE_MODE
	jrl z, MemDraw_CheckVoiceState
	cp xbc, EVT_REFRESH_PARAM
	jrl z, MemDraw_RestoreAll
	cp xbc, EVT_SET_MEMORY_DRAWBAR
	jr z, MemDraw_UpdateItem
	cp xbc, EVT_REQUEST_MEMORY_DRAWBAR
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
	ld bc, 0:i3
	calr DemoMenu_BuildItemWorkspace
	ldw wa, 0xe
	ld bc, 0:i3
	calr DemoMenu_BuildItemWorkspace
	ldw wa, 0xb
	ld bc, 0:i3
	calr DemoMenu_BuildItemWorkspace
	ldw wa, 0xc
	ld bc, 0:i3
	calr DemoMenu_BuildItemWorkspace
	jrl DemoMenu_ReturnZero

MemDraw_InitParamLoop:
	ld iz, 0:i3

MemDraw_ParamLoopBody:
	ld	wa, iz
	extz	xwa
	add	xwa, xwa
	ld	xbc, MidiParam_MixerCfgData_0x8A
	add	xbc, xwa
	ld	wa, (xbc)
	extz	xwa
	call	AcApcToggleProc_Helper
	ld	bc, hl
	ld	wa, iz
	calr	DemoMenu_BuildItemWorkspace
	inc	1, iz
	cp	iz, 14
	jr	ule, MemDraw_ParamLoopBody
	jr	DemoMenu_ReturnZero
MemDraw_UpdateItem:
	ld xwa, (xsp + 2)
	srl xwa, 16
	ldiw_erp 0xe2, 0
	ld xbc, (xsp + 2)
	calr DemoMenu_BuildItemWorkspace
	ld xwa, (xsp + 2)
	srl xwa, 16
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
	ld iz, 0:i3

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
	sll xwa, 16
	ld xde, xwa
	add xde, xhl
	ld xwa, 0xffffffff
	ld xbc, EVT_TONE_MODE
	call ApPostEvent

DemoMenu_ReturnZero:
	ld xhl, 0:i3
	popw iz
	inc 4, xsp
	ret

; =============================================================================
; DemoMenu_BuildItemWorkspace (0xf838e6)
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
	dec 6,XSP
	pushw iz
	ld IZ,BC
	ld (XSP+0x06),WA
	pushw 0x000c
	call SLIDE_Decompress_4K_Init_Helper2
	inc 2,XSP
	ld (XSP+0x02),XHL
	call GetPartSelect
	ld WA,HL
	extz XWA
	sll XWA, 0x0a
	ld DE,(XSP+0x06)
	extz XDE
	add XDE,XDE
	ld XBC,MidiParam_MixerCfgData_0x8A
	add XBC,XDE
	ld HL,(XBC)
	extz XHL
	add XHL,XWA
	ld XWA,(XSP+0x02)
	ld (XWA),XHL
	ld (XWA+0x04),IZ
	cpw (XSP+0x06), 0x0008
	jr ugt, DemoMenu_WorkspaceFunc
	ld XWA,0x000247ce
	add XWA,XDE
	ld (XWA),IZ
	jr t, DemoMenu_BuildItemWorkspace_Post
DemoMenu_WorkspaceFunc:
	ld wa, (xsp + 6)
	sub wa, 0x9
	cp wa, 0:i3
	jr c, DemoMenu_BuildItemWorkspace_Post
	cp wa, 5:i3
	jr ugt, DemoMenu_BuildItemWorkspace_Post
	add wa, wa
	lda xix, (KeyShiftStr_Zero_0x5E:24)
	ld	wa, (xix+wa)
	lda xix, (DemoMenu_WorkspaceDispatch:24)
	jp	t, (xix+wa)

; DemoMenu workspace dispatch (6-entry, table 0xe9f984)
DemoMenu_WorkspaceDispatch:
	ld	(0x247e0:24), iz
	jr	DemoMenu_BuildItemWorkspace_Post
	ld	(0x247e2:24), iz
	jr	DemoMenu_BuildItemWorkspace_Post
	ld	(0x247e4:24), iz
	jr	DemoMenu_BuildItemWorkspace_Join
	ld	(0x247e6:24), iz
	jr	DemoMenu_BuildItemWorkspace_Join
	ld	(0x247e8:24), iz
	jr	DemoMenu_BuildItemWorkspace_Join
	ld	(0x247ea:24), iz
DemoMenu_BuildItemWorkspace_Join:
	ld	bc, (xbc)
	extz	xbc
	ld	xwa, (xsp+2)
	ld	(xwa), xbc

; Exit path for DemoMenu_BuildItemWorkspace: posts queued events 0x1c0001c
; and 0x1e00023 with the allocated workspace pointer, then returns.
DemoMenu_BuildItemWorkspace_Post:
	ld xwa, 0xffffffff
	ld xbc, EVT_LSW_DATA
	ld xde, (xsp + 2)
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_AUTO_FREE
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
	cp wa, 0:i3
	jr c, DemoMenu_DescriptorReturn
	cp wa, 5:i3
	jr ugt, DemoMenu_DescriptorReturn
	add wa, wa
	lda xix, (KeyShiftStr_Zero_0x6A:24)
	ld	wa, (xix+wa)
	lda xix, (DemoDesc_DispatchTable:24)
	jp	t, (xix+wa)

DemoDesc_DispatchTable:
	ld	hl, (0x247e0:24)
	ret
	ld	hl, (0x247e2:24)
	ret
	ld	hl, (0x247e4:24)
	ret
	ld	hl, (0x247e6:24)
	ret
	ld	hl, (0x247e8:24)
	ret
	ld	hl, (0x247ea:24)
	ret

; DemoMenu descriptor return
DemoMenu_DescriptorReturn:
	ld hl, 0:i3
	ret

DemoDesc_BuildCompactParams:
	ld bc, (0x0247e6:24)
	sla bc, 4
	add bc, (0x247e4:24)
	ld (xwa), c
	ld bc, (0x0247ea:24)
	sla bc, 4
	add bc, (0x247e8:24)
	ld (xwa + 1), c
	lda xbc, (0x0247ce:24)
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
	ld de, (0x0247e2:24)
	sla de, 4
	add de, (xbc + 16)
	ld bc, (0x0247e0:24)
	sla bc, 5
	add bc, de
	ld (xwa + 6), c
	ret

DemoDesc_DataByte:
	ret

PsVariBoxProc:
	lda xsp, (xsp-280)
	push xiz
	ld	(xsp+276), xde
	ld xiz, xbc
	ld	(xsp+280), xwa
	cp xiz, EVT_CHECK_SELECTED
	jrl z, PsVari_CheckDirty
	cp xiz, EVT_INDEX_SELECT
	jrl z, PsVari_Notify
	cp xiz, EVT_SW_IN
	jrl z, PsVari_OK
	cp xiz, EVT_GET_STRING
	jrl z, PsVari_GetText
	cp xiz, EVT_PARA_DRAW
	jrl z, PsVari_Confirm
	cp xiz, EVT_DRAW
	jr z, PsVari_Paint
	cp xiz, EVT_SET_SELECTED
	jrl nz, PsVari_ForwardToBase
	ld XWA, (xsp + 0x0118)
	call GetViewInstance
	lda xwa, (xhl + 38)
	ld xbc, (xwa)
	ld bc, (xbc)
	exts xbc
	cp	xbc, (xsp+276)
	jrl z, AudioView_ReturnZeroJmp
	ld xbc, (xwa)
	ld XWA, (xsp + 0x0114)
	ld (xbc), wa
	ld XWA, (xsp + 0x0118)
	ld xbc, EVT_DRAW
	ld xde, 0:i3
	jrl AudioView_SendEventCall

PsVari_Paint:
	ld XWA, (xsp + 0x0118)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 38)
	cpw (xwa), 0x0
	jr z, PsVari_PaintEmpty
	ld XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld XDE, (xsp + 0x0114)
	call InheritedProc
	jr PsVari_DrawEditSw

PsVari_PaintEmpty:
	lda xbc, (xsp+264)
	ld XWA, (xsp + 0x0118)
	call GetBox
	lda xwa, (xsp+264)
	ldw bc, 0xf5
	call DrawBox

PsVari_DrawEditSw:
	ld xwa, (xsp + 4)
	ld wa, (xwa + 36)
	call DrawEditSw
	ld XWA, (xsp + 0x0118)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl AudioView_SendEventCall

PsVari_Confirm:
	ld XWA, (xsp + 0x0118)
	call GetViewInstance
	ld (xsp + 4), xhl
	lda xbc, (xsp+264)
	ld XWA, (xsp + 0x0118)
	call GetClientBox
	lda xwa, (xsp+264)
	lda xbc, (xsp+272)
	call GetBoxCenter
	lda xde, (xsp + 8)
	ld XWA, (xsp + 0x0118)
	ld xbc, EVT_GET_STRING
	call SendEvent
	ld xwa, (xsp + 4)
	ld xiz, (xwa + 38)
	lda xbc, (xsp+272)
	lda xde, (xsp+264)
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
	pushw	(xwa+32)
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
	ld xhl, 0:i3
	jrl PsVari_Epilogue

PsVari_GetText:
	ld XWA,(XSP+0x0118)
	call GetViewInstance
	pushm (xhl + 0x24)
	pushw PsVari_GetText_Str_EditSw_Fmtd@hi16
	pushw PsVari_GetText_Str_EditSw_Fmtd@lo16
	ld XWA,(XSP+0x011a)
	push XWA
	call Scoop_EventLoop_12Entry_Helper
	lda xsp, (xsp + 0x0a)
	jr t, AudioView_ReturnZeroJmp
PsVari_OK:
	ld XWA, (xsp + 0x0118)
	call GetViewInstance
	ld wa, (xhl + 36)
	extz xwa
	cp	xwa, (xsp+276)
	jr nz, PsVari_OKForward
	ld de, (xhl + 26)
	cp de, 0xffff
	jr z, PsVari_OKForward
	exts xde
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEX_SELECT
	call SendEvent
	ld XWA, (xsp + 0x0118)
	ld xbc, EVT_SET_SELECTED
	ld xde, 1:i3
	jr AudioView_SendEventCall

PsVari_OKForward:
	ld XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld XDE, (xsp + 0x0114)
	jr PsVari_CallInherited

PsVari_Notify:
	ld XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld XDE, (xsp + 0x0114)
	call InheritedProc
	ld XWA, (xsp + 0x0118)
	call GetViewInstance
	ld wa, (xhl + 26)
	exts xwa
	cp	xwa, (xsp+276)
	jrl nz, AudioView_ReturnZeroJmp
	ld xwa, (xhl + 38)
	cpw (xwa), 0x0
	jrl z, AudioView_ReturnZeroJmp
	ld XWA, (xsp + 0x0118)
	ld xbc, EVT_SET_SELECTED
	ld xde, 0:i3

AudioView_SendEventCall:
	call SendEvent
	jrl AudioView_ReturnZeroJmp

PsVari_CheckDirty:
	ld XWA, (xsp + 0x0118)
	call GetViewInstance
	ld wa, (xhl + 26)
	exts xwa
	cp	xwa, (xsp+276)
	jrl nz, AudioView_ReturnZeroJmp
	ld xwa, (xhl + 38)
	cpw (xwa), 0x1
	jrl nz, AudioView_ReturnZeroJmp
	ld xhl, 1:i3
	jr PsVari_Epilogue

PsVari_ForwardToBase:
	ld XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld XDE, (xsp + 0x0114)

PsVari_CallInherited:
	call InheritedProc

PsVari_Epilogue:
	pop xiz
	lda xsp, (xsp+280)
	ret


VwUserBitmapSpProc:
	lda xsp, (xsp - 10)
	push xiz
	cp xbc, EVT_DRAW
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
	ld xbc, EVT_GET_BITMAP_DATA
	ld xde, 0:i3
	call ApFuncCall
	ld (xsp + 6), xhl
	ld xwa, (xsp + 6)
	or xwa, xwa
	jr z, UserBitmapSp_DrawEmpty
	ld xwa, (xiz + 22)
	ld xbc, EVT_GET_BITMAP_WIDTH
	ld xde, 0:i3
	call ApFuncCall
	ld (xsp + 4), hl
	ld xwa, (xiz + 22)
	ld xbc, EVT_GET_BITMAP_HEIGHT
	ld xde, 0:i3
	call ApFuncCall
	lda xwa, (xsp + 10)
	pushw hl
	ld xbc, (xsp + 8)
	ld de, (xsp + 6)
	call DrawBitmapSP
	jr UserBitmapSp_ReturnZero

UserBitmapSp_DrawEmpty:
	lda xwa, (xsp + 10)
	ld xbc, 0:i3
	call DrawBitmap

UserBitmapSp_ReturnZero:
	ld xhl, 0:i3

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
	cp xiz, EVT_SHOW
	jr z, FdemoScreen_Init
	ld xwa, NAKA_APFUNC_ApPreControl
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
	ld xwa, NAKA_APFUNC_ApTaskControl
	ld xbc, EVT_SLEEP_MAIN_TASK
	ld xde, 0:i3
	call ApFuncCall
	call FDemo_IndicatorSetup
	ld xwa, NAKA_APFUNC_ApTaskControl
	ld xbc, EVT_WAKE_UP_MAIN_TASK
	ld xde, 0:i3
	call ApFuncCall

FdemoScreen_InitForward:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr nz, FdemoScreen_ReturnZero
	ld xwa, NAKA_APFUNC_ApPreControl
	ld xbc, EVT_EXIST_PRESENTATION
	ld xde, 0:i3
	call ApFuncCall
	or xhl, xhl
	jr z, FdemoScreen_StartPanel2
	ld xwa, Pad_NakaExternal_Block1
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	jr FdemoScreen_SendStart

FdemoScreen_StartPanel2:
	ld xwa, Pad_AfterNakaData_ExternalBase
	ld xbc, EVT_SHOW
	ld xde, 5:i3

FdemoScreen_SendStart:
	call SendEvent

FdemoScreen_ReturnZero:
	ld xhl, 0:i3

FdemoScreen_Epilogue:
	pop xiz
	inc 8, xsp
	ret

IvDemofeature1Proc:
	push xiz
	ld xiz, xwa
	cp xbc, EVT_GET_STRING
	jr z, Demofeat1_GetText
	cp xbc, EVT_DRAW
	jr z, Demofeat1_Paint
	ld xwa, xiz
	call InheritedProc
	jr Demofeat1_Epilogue

Demofeat1_Paint:
	ld xwa, xiz
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call SendEvent
	jr Demofeat1_ReturnZero

Demofeat1_GetText:
	pushw	Demofeat1_GetText_Str_Fdm1@hi16
	pushw	Demofeat1_GetText_Str_Fdm1@lo16
	push	xde
	call	Free_Compare2
	inc	8, xsp
Demofeat1_ReturnZero:
	ld xhl, 0:i3

Demofeat1_Epilogue:
	pop xiz
	ret

IvDemofeature2Proc:
	push xiz
	ld xiz, xwa
	cp xbc, EVT_GET_STRING
	jr z, Demofeat2_GetText
	cp xbc, EVT_DRAW
	jr z, Demofeat2_Paint
	cp xbc, EVT_REPAINT
	jr z, Demofeat2_ShowHide
	cp xbc, EVT_PAINT
	jr z, Demofeat2_ShowHide
	cp xbc, EVT_SHOW
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
	ld xwa, NAKA_APFUNC_ApPreControl
	ld xbc, EVT_GET_STRING
	ld xde, 0:i3
	call ApFuncCall
	ld xde, xhl
	; object handle 0xe40008 = class 0x0e4, instance 8 (SendEvent indexes its class table by bits 16-27; not an address -- was Bitmap_Dredt0d_0x9A8)
	ld xwa, Bitmap_Dredt0d_0x9A8
	ld xbc, EVT_PARA_DRAW
	jr Demofeat2_SendEvent

Demofeat2_Paint:
	ld xwa, xiz
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3

Demofeat2_SendEvent:
	call SendEvent
	jr Demofeat2_ReturnZero

Demofeat2_GetText:
	pushw	Demofeat2_GetText_Str_Fdm2@hi16
	pushw	Demofeat2_GetText_Str_Fdm2@lo16
	push	xde
	call	Free_Compare2
	inc	8, xsp
Demofeat2_ReturnZero:
	ld xhl, 0:i3

Demofeat2_Epilogue:
	pop xiz
	ret

AcPresentationBoxProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld xiz, xbc
	ld (xsp + 12), xwa
	cp xiz, EVT_CHECK_SELECTED
	jrl z, AcPresCtrl_Case0
	cp xiz, EVT_GET_STRING
	jrl z, PresBox_GetText
	cp xiz, EVT_INDEX_SELECT
	jrl z, PresBox_Notify
	cp xiz, EVT_END_SONG
	jrl z, PresBox_TimerTick
	cp xiz, EVT_START_SONG
	jrl z, PresBox_TimerExpired
	cp xiz, EVT_SW_IN
	jrl z, PresBox_OK
	cp xiz, EVT_SET_SELECTED
	jrl z, PresBox_HandleWidget
	cp xiz, EVT_SELE_DRAW
	jr z, PresBox_Select
	cp xiz, EVT_DRAW
	jr z, PresBox_Paint
	cp xiz, EVT_SHOW
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
	ld xhl, 0:i3
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
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xsp + 12)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
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
	ld xbc, EVT_DRAW_SELECTED
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
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
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
	ld xwa, NAKA_APFUNC_ApTaskControl
	ld xbc, EVT_SLEEP_MAIN_TASK
	ld xde, 0:i3
	call ApFuncCall
	ld xwa, (xsp + 4)
	ld wa, (xwa + 46)
	ld (0x28a4:16), a
	call Demo_SelectEntry_ProcessSongList
	ld xwa, NAKA_APFUNC_ApTaskControl
	ld xbc, EVT_WAKE_UP_MAIN_TASK
	ld xde, 0:i3
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
	ld xbc, EVT_INDEX_SELECT
	call SendEvent
	ld xwa, (xsp + 12)
	ld xbc, EVT_SET_SELECTED
	ld xde, 1:i3
	call SendEvent
	; object handle 0xe4000a = class 0x0e4, instance 10 (SendEvent indexes its class table by bits 16-27; not an address -- was Bitmap_Dredt0d_0x9AA)
	ld xwa, Bitmap_Dredt0d_0x9AA
	ld xbc, EVT_SHOW
	ld xde, 5:i3
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
	ld xbc, EVT_INDEX_SELECT
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
	ld xbc, EVT_SET_SELECTED
	ld xde, 0:i3

AcAudio_SendEvent_Continue:
	call SendEvent
	jrl AudioCtrl_ReturnZeroJmp

PresBox_GetText:
	ld	xwa, (xsp+12)
	call	GetViewInstance
	ld	xwa, (xhl+36)
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jrl	AudioCtrl_ReturnZeroJmp
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
	ld xhl, 1:i3
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
	cp xbc, EVT_LSW_DATA
	jrl z, AcPresentCtrl_CheckSSFStart
	ld xwa, (xsp + 8)
	cp xwa, EVT_END_SONG
	jrl z, AcPresCtrl_Case5
	cp xwa, EVT_START_SONG
	jrl z, AcPresCtrl_Case4
	sub xbc, EVT_HIDE
	cp xbc, 0x0
	jrl lt, AcPresCtrl_DefaultCase
	cp xbc, 0xa
	jrl gt, AcPresCtrl_DefaultCase
	add xbc, xbc
	add xbc, KeyShiftStr_Zero_0x8C
	ld bc, (xbc)
	lda xix, (AcPresCtrl_EventDispatch:24)
; Computed jump: target = AcPresCtrl_EventDispatch + KeyShiftStr_Zero_0x8C[i], KeyShiftStr_Zero_0x8C = 16-bit offsets (11 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1c00002:
;   0x1c00002 -> AcPresCtrl_EventDispatch
;   0x1c00003 -> AcPresCtrl_DefaultCase
;   0x1c00004 -> AcPresCtrl_DefaultCase
;   0x1c00005 -> AcPresCtrl_DefaultCase
;   0x1c00006 -> AcPresentationControlProc_Evt1C00006
;   0x1c00007 -> AcPresentationControlProc_Evt1C00007
;   0x1c00008 -> AcPresentationControlProc_Evt1C00007
;   0x1c00009 -> AcPresentationControlProc_Evt1C00007
;   0x1c0000a -> AcPresCtrl_DefaultCase
;   0x1c0000b -> AcPresent_ReturnZeroJmp
;   0x1c0000c -> AcPresent_ReturnZeroJmp
	jp	t, (xix+bc)
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
	cp xhl, NAKA_MODE_MD_DEMO			; check return code
	jrl z, AcPresent_ReturnZeroJmp			; matched -- exit
	ld	wa, 2:i3
	jr AcPresCtrl_ChangePalette				; skip to call FAF2C7
AcPresentationControlProc_Evt1C00007:
	ld xwa, 0x02600024			; workspace for SendEvent
	ld xbc, EVT_MAKE_EDIT_SW_ID			; presentation control event
	ld xde, (xsp + 4)			; event param
	call SendEvent				; SendEvent (direct)
	cp hl, 0x000f				; check result count
	jrl nz, AcPresent_ReturnZeroJmp			; exit if not 0x0f
	ld xwa, NAKA_APFUNC_ApTaskControl			; register event handler workspace
	ld xbc, EVT_SLEEP_MAIN_TASK			; register event code AC
	ld	xde, 0:i3
	call ApFuncCall				; register event handler
	call Demo_SelectionEntryHandler				; additional presentation setup
	ld xwa, NAKA_APFUNC_ApTaskControl
	ld xbc, EVT_WAKE_UP_MAIN_TASK			; register event code AD
	ld	xde, 0:i3
	call ApFuncCall				; register event handler
	ld xwa, 0xffffffff			; broadcast target
	ld xbc, EVT_CHANGE_TITLE			; presentation state event
	ld xde, TITLE_DEMOMENU			; event param
	call PostEvent				; dispatch event
	ld	wa, 2:i3
AcPresCtrl_ChangePalette:
	call ChangePalette				; presentation helper
	jrl AcPresent_ReturnZeroJmp			; exit


; AcPresCtrl event case 4
AcPresCtrl_Case4:
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, NAKA_APFUNC_ApPreControl
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
	ld xwa, NAKA_APFUNC_ApPreControl
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call ApFuncCall
	ld wa, 2:i3
	call ChangePalette
	; object handle 0xe40000 = class 0x0e4, instance 0 (SendEvent indexes its class table by bits 16-27; not an address -- was NakaData_ExternalBase)
	ld xwa, NakaData_ExternalBase
	ld xbc, EVT_SHOW
	ld xde, 0:i3
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
	ld xbc, EVT_ACTION

AcPresCtrl_SendEventReturn:
	call SendEvent
	jr AcPresent_ReturnZeroJmp
AcPresentationControlProc_Evt1C00006:
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	ldw (0x0340fc:24), 0x0000
	ldw (0x0340fa:24), 0x0000
	ldw (0x0340fe:24), 0x0000
	ld xwa, NAKA_APFUNC_ApPreControl
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call ApFuncCall
	ldw wa, 0x8
	call Audio_DispatchCommand

AcPresent_ReturnZeroJmp:
	ld xhl, 0:i3
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
	ld xbc, EVT_START_SONG
	jp ApPostEvent

Seq_DispatchEventType6:
	ld de, wa
	exts xde
	ld xwa, 0xffffffff
	ld xbc, EVT_END_SONG
	jp ApPostEvent

Seq_StartMainControl:
	ld xwa, NAKA_MAINFUNC_MainPreControl
	ld xbc, EVT_INIT_PRESENTATION
	ld xde, 0:i3
	jp MainPreControl

Seq_StartMainControlAlt:
	ld xwa, NAKA_MAINFUNC_MainPreControl
	ld xbc, EVT_EXIT_PRESENTATION
	ld xde, 0:i3
	jp MainPreControl

Seq_IsMelodyActive:
	ld xwa, NAKA_MAINFUNC_MainPreControl
	ld xbc, EVT_EXIST_PRESENTATION
	ld xde, 0:i3
	jp MainPreControl

	.include "demo/fdemotext_routines.s"
