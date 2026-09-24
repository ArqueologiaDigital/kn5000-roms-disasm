; =============================================================================
; Sound Editor UI
; =============================================================================
;
; Sound editor user interface: patch/bank selection, parameter
; editing, drum kit editor. Includes flash/floppy integration
; for saving/loading sound patches.
; =============================================================================

InitializeSeMenuDefaults:
	ld wa, 0:i3
	call SeMenu_SetSoundBank
	ld wa, 0:i3
	call SeMenu_SetPatchBank
	call AccWrap_PlayModeDispatch
	ld wa, 1:i3
	call SeMenu_SetEditEnable
	ld wa, 1:i3
	call SeMenu_OrPartConfig
	ld wa, 0:i3
	call SeMenu_SetConfirmState
	jp SeMenu_ClearDisplayBuffer

UpdateSeMenuSelection:
	dec 2, xsp
	ld wa, 0:i3
	call SeMenu_SetSelectedRow
	ld wa, 0:i3
	call SeMenu_SetEditEnable
	lda xwa, (xsp)
	call SeMenu_LoadObjEntries
	cp (xsp), 0x2
	jr z, UpdSeSel_SkipMenuSetup
	ld wa, 0:i3
	call SeMenu_SetupMenuDisplay

UpdSeSel_SkipMenuSetup:
	ld wa, 0:i3
	call SeMenu_SetConfirmState
	call SeMenu_RefreshPartDisplay
	inc 2, xsp
	ret

UpdSeSel_ProcessStep:
	lda xsp, (xsp - 20)
	lda xwa, (xsp + 16)
	call SeMenu_ReadObjData
	cp (xsp + 16), 0x0
	jr nz, UpdSeSel_Step1_CheckEnabled
	ld wa, 1:i3
	call SeMenu_SetDisplayState
	pushw 0x20
	ld wa, 0:i3
	ldw bc, 0x10
	ld de, 1:i3
	call SeMenu_RegisterElement_Type1
	ld wa, 1:i3
	call SeMenu_SetCurrentStep
	jrl UpdSeSel_ProcessStep_End

UpdSeSel_Step1_CheckEnabled:
	cp (xsp + 16), 0x1
	jr nz, UpdSeSel_UpdateEntries
	ldw wa, 0x81
	call SeMenu_CheckObjEnabled
	cp hl, 0:i3
	jr nz, UpdSeSel_Step1_Disable
	ldw wa, 0x10
	call SeMenu_CheckObjValid
	cp hl, 0:i3
	jr z, UpdSeSel_Step1_FillTable

UpdSeSel_Step1_Disable:
	ldw wa, 0x10
	call SeMenu_SetCurrentStep
	ld wa, 0:i3
	jr UpdSeSel_Step1_SetDisplayState

UpdSeSel_Step1_FillTable:
	lda xwa, (xsp)
	call SeMenu_FillEntryTable
	lda xbc, (xsp)
	ld a, (xbc)
	and a, 0xc0
	ld (xbc), a
	cp a, 0x80
	jr nz, UpdSeSel_Step1_Flag40
	ld wa, 1:i3
	call SeMenu_SetMode
	ld wa, 2:i3
	jr UpdSeSel_Step1_SetStep

UpdSeSel_Step1_Flag40:
	cp a, 0x40
	jr nz, UpdSeSel_Step1_DefaultMode
	ld wa, 2:i3
	call SeMenu_SetMode
	ldw wa, 0xea
	ld bc, 0:i3
	call SeMenu_SendEvent
	ld wa, 0:i3
	call SeMenu_SetCurrentStep
	ld wa, 0:i3

UpdSeSel_Step1_SetDisplayState:
	call SeMenu_SetDisplayState
	jr UpdSeSel_ProcessStep_End

UpdSeSel_Step1_DefaultMode:
	ld wa, 0:i3
	call SeMenu_SetMode
	ld wa, 2:i3

UpdSeSel_Step1_SetStep:
	call SeMenu_SetCurrentStep

UpdSeSel_UpdateEntries:
	lda xwa, (xsp + 18)
	call SeMenu_LoadObjEntries
	cp (xsp + 18), 0x1
	jr nz, UpdSeSel_UpdateEntries_CallSimple
	calr UpdSeSel_DetailedUpdate
	jr UpdSeSel_ProcessStep_End

UpdSeSel_UpdateEntries_CallSimple:
	calr UpdSeSel_SimpleUpdate

UpdSeSel_ProcessStep_End:
	lda xsp, (xsp + 20)
	ret

UpdSeSel_SimpleUpdate:
	lda xsp, (xsp - 42)
	pushw_erp 0xfa
	lda xwa, (xsp + 42)
	call SeMenu_ReadObjData
	cp (xsp + 42), 0x2
	jr nz, UpdSeSel_SimpleUpdate_Step3
	pushw 0x20
	ld wa, 0:i3
	ldw bc, 0x11
	ld de, 1:i3
	call SeMenu_RegisterElement_Type1
	ld wa, 3:i3
	jrl UpdSeSel_SimpleUpdate_SetStepAndJump

UpdSeSel_SimpleUpdate_Step3:
	cp (xsp + 42), 0x3
	jr nz, UpdSeSel_SimpleUpdate_Step4
	lda xwa, (xsp + 6)
	call SeMenu_FillEntryTable
	ld a, (xsp + 6)
	extz wa
	call SeMenu_StorePartMask
	ldw wa, 0x20
	call SeMenu_SetDisplayValue
	ld wa, 4:i3
	jrl UpdSeSel_SimpleUpdate_SetStepAndJump

UpdSeSel_SimpleUpdate_Step4:
	cp (xsp + 42), 0x4
	jr nz, UpdSeSel_SimpleUpdate_Step5
	lda xwa, (xsp + 6)
	call SeMenu_FillObjTable
	ld c, (xsp + 7)
	extz bc
	ld wa, 0:i3
	call SeMenu_StoreEffectCoeff
	ld c, (xsp + 8)
	extz bc
	ld wa, 1:i3
	call SeMenu_StoreEffectCoeff
	ld c, (xsp + 9)
	extz bc
	ld wa, 2:i3
	call SeMenu_StoreEffectCoeff
	lda xde, (xsp + 2)
	ld wa, 0:i3
	ld bc, 1:i3
	call SeMenu_TransferPartValues
	ld c, (xsp + 2)
	extz bc
	pushw 0x20
	ld wa, 0:i3
	ld de, 4:i3
	call SeMenu_RegisterElement_Type1
	ld wa, 5:i3
	jr UpdSeSel_SimpleUpdate_SetStepAndJump

UpdSeSel_SimpleUpdate_Step5:
	lda xwa, (xsp + 6)
	cp (xsp + 42), 0x5
	jr nz, UpdSeSel_SimpleUpdate_Step6
	call SeMenu_FillEntryTable
	ld c, (xsp + 6)
	extz bc
	ld wa, 0:i3
	call SeMenu_StoreEffectParam
	ld c, (xsp + 7)
	extz bc
	ld wa, 1:i3
	call SeMenu_StoreEffectParam
	ld c, (xsp + 9)
	extz bc
	ld wa, 2:i3
	call SeMenu_StoreEffectParam
	ldw wa, 0x20
	call SeMenu_RegisterParamDisplay
	ld wa, 6:i3

UpdSeSel_SimpleUpdate_SetStepAndJump:
	call SeMenu_SetCurrentStep
	jrl UpdSeSel_SimpleUpdate_End

UpdSeSel_SimpleUpdate_Step6:
	cp (xsp + 42), 0x6
	jr nz, UpdSeSel_SimpleUpdate_Default
	call SeMenu_FillObjTable
	lda xbc, (xsp + 6)
	ld a, (xbc)
	and a, 0x1
	ld (xbc), a
	ld c, a
	extz bc
	ld wa, 1:i3
	call SeMenu_StorePartParam
	ldib_erp 0xfb, 1

UpdSeSel_SimpleUpdate_Step6_RegLoop:
	stb_erp A, 0xfb
	extz wa
	pushw 0x20
	ldw bc, 0x17
	ld de, 1:i3
	call SeMenu_RegisterElement_Type1
	inc1b_erp 0xfb
	cpib_erp 0xfb, 4
	jr ule, UpdSeSel_SimpleUpdate_Step6_RegLoop
	ld wa, 7:i3
	call SeMenu_SetCurrentStep
	call SeMenu_ResetSubIndex
	call SeMenu_AdvanceSubIndex
	jr UpdSeSel_SimpleUpdate_End

UpdSeSel_SimpleUpdate_Default:
	lda xwa, (xsp + 4)
	call SeMenu_ReadObjParam
	lda xwa, (xsp + 6)
	call SeMenu_FillEntryTable
	ld a, (xsp + 4)
	extz wa
	ld c, (xsp + 6)
	extz bc
	call SeMenu_StoreParamByte
	call SeMenu_AdvanceSubIndex
	cp l, 4:i3
	jr ule, UpdSeSel_SimpleUpdate_End
	pushw 0x20
	call SeMenu_ShowPopupDialog
	inc 2, xsp
	ld wa, 0:i3
	call SeMenu_SetCurrentStep
	call SeMenu_ResetSubIndex
	ld wa, 0:i3
	call SeMenu_SetDisplayState

UpdSeSel_SimpleUpdate_End:
	popw_erp 0xfa
	lda xsp, (xsp + 42)
	ret

UpdSeSel_DetailedUpdate:
	lda xsp, (xsp - 32)
	pushw_erp 0xfa
	lda xwa, (xsp + 32)
	call SeMenu_ReadObjData
	cp (xsp + 32), 0x3
	jr nz, UpdSeSel_DetailedUpdate_Step2
	lda xwa, (xsp + 6)
	call SeMenu_ValidatePartNumber
	ld c, (xsp + 6)
	extz bc
	ld wa, 0:i3
	call SeMenu_StorePartParam
	lda xwa, (xsp + 14)
	lda xbc, (xsp + 12)
	call SeMenu_SetupSoundBankPair
	cp (xsp + 12), 0xff
	jr nz, UpdSeSel_DetailedUpdate_Step3_Store
	ld wa, 0:i3
	call SeMenu_SetCurrentStep
	ldw wa, 0x10
	call SeMenu_SetCurrentStep
	ld wa, 0:i3
	jrl UpdSeSel_DetailedUpdate_SetDisplayState

UpdSeSel_DetailedUpdate_Step3_Store:
	ld c, (xsp + 14)
	extz bc
	ld wa, 1:i3
	call SeMenu_StorePartParam
	lda xwa, (xsp + 12)
	call SeMenu_SetupDisplayObject
	ld wa, 4:i3
	call SeMenu_SetCurrentStep
	ldw wa, 0x20
	ld bc, 1:i3
	jrl UpdSeSel_DetailedUpdate_SendEventAndEnd

UpdSeSel_DetailedUpdate_Step2:
	cp (xsp + 32), 0x2
	jrl nz, UpdSeSel_DetailedUpdate_Step4
	lda xwa, (xsp + 2)
	call SeMenu_LoadConfirmData
	cp (xsp + 2), 0x1
	jr nz, UpdSeSel_DetailedUpdate_Step2_CheckActive
	ld wa, 2:i3
	call SeMenu_ClearNotification
	ld wa, 0:i3
	call SeMenu_SetConfirmState
	jrl UpdSeSel_DetailedUpdate_End

UpdSeSel_DetailedUpdate_Step2_CheckActive:
	call SeMenu_ReturnZero
	cp l, 0:i3
	jr z, UpdSeSel_DetailedUpdate_Step2_ReadPatch
	ld wa, 1:i3
	call SeMenu_SetConfirmState
	ldw wa, 0x2d
	call SeMenu_TriggerNotification
	ld wa, 0:i3
	jrl UpdSeSel_DetailedUpdate_SetStepAndJump

UpdSeSel_DetailedUpdate_Step2_ReadPatch:
	lda xwa, (xsp + 4)
	call SeMenu_LoadPatchStatus
	cp (xsp + 4), 0x0
	jr nz, UpdSeSel_DetailedUpdate_Step2_SetStep3
	pushw 0x20
	ld wa, 0:i3
	ldw bc, 0x12
	ld de, 1:i3
	call SeMenu_RegisterElement_Type2
	ld wa, 1:i3
	call SeMenu_SetPatchBank
	jrl UpdSeSel_DetailedUpdate_End

UpdSeSel_DetailedUpdate_Step2_SetStep3:
	ld wa, 3:i3
	call SeMenu_SetCurrentStep
	ldw wa, 0x86
	call SeMenu_CheckObjEnabled
	cp hl, 0:i3
	jr nz, UpdSeSel_DetailedUpdate_Step2_Disable
	ldw wa, 0x12
	call SeMenu_CheckObjValid
	cp hl, 0:i3
	jr z, UpdSeSel_DetailedUpdate_Step2_FillTable

UpdSeSel_DetailedUpdate_Step2_Disable:
	ldw wa, 0x10
	call SeMenu_SetCurrentStep
	ld wa, 0:i3
	jrl UpdSeSel_DetailedUpdate_SetDisplayState

UpdSeSel_DetailedUpdate_Step2_FillTable:
	lda xwa, (xsp + 16)
	call SeMenu_FillEntryTable
	lda xbc, (xsp + 16)
	ld a, (xbc)
	and a, 0x30
	ld (xbc), a
	cp a, 0x10
	jr z, UpdSeSel_DetailedUpdate_Step2_ClearPatch
	pushw 0x20
	call SeMenu_ShowPopupDialog
	inc 2, xsp
	jrl UpdSeSel_DetailedUpdate_End

UpdSeSel_DetailedUpdate_Step2_ClearPatch:
	ld wa, 0:i3
	call SeMenu_SetPatchBank
	ldw wa, 0x20
	ld bc, 1:i3

UpdSeSel_DetailedUpdate_SendEventAndEnd:
	call SeMenu_SendEvent
	jrl UpdSeSel_DetailedUpdate_End

UpdSeSel_DetailedUpdate_Step4:
	cp (xsp + 32), 0x4
	jrl nz, UpdSeSel_DetailedUpdate_Step5
	call SeMenu_InitTrackInfo
	pushw 0x20
	ld wa, 0:i3
	ldw bc, 0xd
	ld de, 1:i3
	call SeMenu_RegisterElement_Type2
	ldib_erp 0xfb, 0

UpdSeSel_DetailedUpdate_Step4_RegLoop1:
	stb_erp A, 0xfb
	extz wa
	muls wa, 0x15
	extz xwa
	lda xwa, (xwa + 16)
	inc 5, xwa
	ld c, a
	pushw 0x20
	ld wa, 0:i3
	ld de, 1:i3
	call SeMenu_RegisterElement_Type2
	inc1b_erp 0xfb
	cpib_erp 0xfb, 2
	jr c, UpdSeSel_DetailedUpdate_Step4_RegLoop1
	ldib_erp 0xfb, 0

UpdSeSel_DetailedUpdate_Step4_RegLoop2:
	stb_erp A, 0xfb
	extz wa
	muls wa, 0x15
	extz xwa
	lda xwa, (xwa + 16)
	inc 3, xwa
	ld c, a
	pushw 0x20
	ld wa, 0:i3
	ld de, 1:i3
	call SeMenu_RegisterElement_Type2
	inc1b_erp 0xfb
	cpib_erp 0xfb, 2
	jr c, UpdSeSel_DetailedUpdate_Step4_RegLoop2
	ldib_erp 0xfb, 0

UpdSeSel_DetailedUpdate_Step4_RegLoop3:
	stb_erp A, 0xfb
	extz wa
	muls wa, 0x15
	extz xwa
	lda xwa, (xwa + 16)
	inc 4, xwa
	ld c, a
	pushw 0x20
	ld wa, 0:i3
	ld de, 1:i3
	call SeMenu_RegisterElement_Type2
	inc1b_erp 0xfb
	cpib_erp 0xfb, 2
	jr c, UpdSeSel_DetailedUpdate_Step4_RegLoop3
	ldib_erp 0xfb, 0

UpdSeSel_DetailedUpdate_Step4_RegLoop4:
	stb_erp A, 0xfb
	extz wa
	muls wa, 0x15
	extz xwa
	lda xwa, (xwa + 16)
	ld c, a
	pushw 0x20
	ld wa, 0:i3
	ld de, 1:i3
	call SeMenu_RegisterElement_Type2
	inc1b_erp 0xfb
	cpib_erp 0xfb, 2
	jr c, UpdSeSel_DetailedUpdate_Step4_RegLoop4
	pushw 0x20
	ld wa, 0:i3
	ldw bc, 0xf
	ld de, 1:i3
	call SeMenu_RegisterElement_Type2
	ld wa, 5:i3
	call SeMenu_SetCurrentStep
	call SeMenu_AdvanceSubIndex
	call SeMenu_AdvanceSubIndex
	jrl UpdSeSel_DetailedUpdate_End

UpdSeSel_DetailedUpdate_Step5:
	cp (xsp + 32), 0x5
	jr nz, UpdSeSel_DetailedUpdate_Step6
	lda xwa, (xsp + 8)
	call SeMenu_ReadObjParam
	lda xwa, (xsp + 16)
	call SeMenu_FillEntryTable
	ld a, (xsp + 8)
	extz wa
	ld c, (xsp + 16)
	extz bc
	call SeMenu_StorePartParam
	call SeMenu_AdvanceSubIndex
	cp l, 0xb
	jrl ule, UpdSeSel_DetailedUpdate_End
	lda xbc, (xsp + 10)
	ld wa, 2:i3
	call SeMenu_LoadPartParam
	ld a, (xsp + 10)
	extz wa
	call SeMenu_StorePartMask
	ld wa, 1:i3
	call SeMenu_ApplyPartEdit
	ld wa, 2:i3
	call SeMenu_ApplyPartEdit
	lda xbc, (xsp + 16)
	ld wa, 3:i3
	call SeMenu_LoadPartParam
	ld c, (xsp + 16)
	extz bc
	ld wa, 1:i3
	call SeMenu_StoreParamByte
	lda xbc, (xsp + 16)
	ld wa, 4:i3
	call SeMenu_LoadPartParam
	ld c, (xsp + 16)
	extz bc
	ld wa, 2:i3
	call SeMenu_StoreParamByte
	ld wa, 1:i3
	ldw bc, 0x20
	call SeMenu_InitDisplayField
	ld wa, 6:i3
	jr UpdSeSel_DetailedUpdate_SetStepAndJump

UpdSeSel_DetailedUpdate_Step6:
	cp (xsp + 32), 0x6
	jr nz, UpdSeSel_DetailedUpdate_Step7
	ld wa, 1:i3
	call SeMenu_ApplyFilter
	ld wa, 2:i3
	ldw bc, 0x20
	call SeMenu_InitDisplayField
	ld wa, 7:i3
	jr UpdSeSel_DetailedUpdate_SetStepAndJump

UpdSeSel_DetailedUpdate_Step7:
	cp (xsp + 32), 0x7
	jr nz, UpdSeSel_DetailedUpdate_Step8
	ld wa, 2:i3
	call SeMenu_ApplyFilter
	lda xwa, (xsp + 12)
	call SeMenu_LoadEditParam
	ld a, (xsp + 12)
	extz wa
	ldw bc, 0x20
	call SeMenu_RegisterValueDisplay
	ldw wa, 0x8
	jr UpdSeSel_DetailedUpdate_SetStepAndJump

UpdSeSel_DetailedUpdate_Step8:
	cp (xsp + 32), 0x8
	jr nz, UpdSeSel_DetailedUpdate_Step9
	call SeMenu_ApplySynthParam
	ld wa, 3:i3
	ldw bc, 0x20
	call SeMenu_InitDisplayColumn
	ldw wa, 0x9
	jr UpdSeSel_DetailedUpdate_SetStepAndJump

UpdSeSel_DetailedUpdate_Step9:
	cp (xsp + 32), 0x9
	jr nz, UpdSeSel_DetailedUpdate_StepA
	ld xwa, 3:i3
	call SeMenu_ProcessEffect
	ld wa, 2:i3
	ldw bc, 0x20
	call SeMenu_InitDisplayColumn
	ldw wa, 0xa

UpdSeSel_DetailedUpdate_SetStepAndJump:
	call SeMenu_SetCurrentStep
	jr UpdSeSel_DetailedUpdate_End

UpdSeSel_DetailedUpdate_StepA:
	cp (xsp + 32), 0xa
	jr nz, UpdSeSel_DetailedUpdate_End
	ld xwa, 2:i3
	call SeMenu_ProcessEffect
	pushw 0x20
	call SeMenu_ShowPopupDialog
	pushw 0x0
	pushw 0x20
	call SeMenu_ShowConfirmDialog
	inc 6, xsp
	ld wa, 0:i3
	call SeMenu_SetCurrentStep
	call SeMenu_ResetSubIndex
	ldw wa, 0x10
	call SeMenu_SetCurrentStep
	ld wa, 0:i3

UpdSeSel_DetailedUpdate_SetDisplayState:
	call SeMenu_SetDisplayState

UpdSeSel_DetailedUpdate_End:
	popw_erp 0xfa
	lda xsp, (xsp + 32)
	ret

UpdSeSel_ExtendedOps_Data:
	lda	xsp, (xsp-38)
	.byte 0xd7
	swi	2
	.byte 0x04
	lda	xwa, (xsp+38)
	call	SeMenu_ReadObjData
	ld	wa, 0:i3
	ld	bc, 1:i3
	call	SeMenu_StorePartParam
	.byte 0x8f
	ld	h, 63:opc
	nop
	jr	nz, 11
	ldw	wa, 33
	call	SeMenu_SetDisplayValue
	ld	wa, 1:i3
	jr	110
	.byte 0x8f
	ld	h, 63:opc
	normal
	jr	nz, 63
	lda	xwa, (xsp+2)
	call	SeMenu_FillObjTable
	ldib_erp 251, 1
	stb_erp a, 251
	extz	wa
	stb_erp e, 251
	dec 1, e
	extz	de
	lda	xbc, (xsp+2)
	ld_rrb c, xbc, de
	extz bc
	call	SeMenu_StorePartParam
	inc1b_erp 251
	cp_erpb 251, 8
	jr ule, -35
	pushw 33
	ld	wa, 0:i3
	ldw	bc, 41
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	ld	wa, 2:i3
	jr	41
	lda	xwa, (xsp+2)
	.byte 0x8f
	ld	h, 63:opc
	push	sr
	jr	nz, 38
	call	SeMenu_FillEntryTable
	ld	c, (xsp+2)
	extz	bc
	ldw	wa, 9
	call	SeMenu_StorePartParam
	pushw	33
	ld	wa, 0:i3
	ldw	bc, 93
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	ld	wa, 3:i3
	call	SeMenu_SetCurrentStep
	jr	64
	call	SeMenu_FillEntryTable
	ld	c, (xsp+2)
	extz	bc
	ldw	wa, 10
	call	SeMenu_StorePartParam
	lda	xbc, (xsp+2)
	ld	wa, 2:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+2)
	ld	a, (xbc)
	add	a, 11
	ld	(xbc), a
	ld	c, a
	extz	bc
	ld	wa, 2:i3
	call	SeMenu_StorePartParam
	pushw	33
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_ResetSubIndex
	pop qiz
	lda	xsp, (xsp+38)
	ret
	lda	xsp, (xsp-10)
	.byte 0xd7
	swi	2
	.byte 0x04
	lda	xwa, (xsp+10)
	call	SeMenu_ReadObjData
	.byte 0x8f
	ldw	(63:8), 0x6e00:io
	jrl	le, -1337
	cp	(xbc-57), xhl
	cp	(xwa-57), xde
	.byte 0x89
	extz	wa
	ld	c, 4:opc
	addb_erp c, 251
	pushw	39
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 251
	cpib_erp 251, 3
	jr c, -27
	inc1b_erp 250
	cpib_erp 250, 4
	jr ule, -38
	pushw 39
	ld	wa, 0:i3
	ldw	bc, 19
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	pushw	39
	ld	wa, 0:i3
	ldw	bc, 41
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	pushw	39
	ld	wa, 0:i3
	ldw	bc, 42
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	ld	wa, 1:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_AdvanceSubIndex
	lda	xwa, (xsp+4)
	call	SeMenu_ValidatePartNumber
	ld	c, (xsp+4)
	extz	bc
	ld	wa, 0:i3
	call	SeMenu_StorePartParam
	jrl	137
	lda	xwa, (xsp+2)
	call	SeMenu_ReadObjParam
	lda	xwa, (xsp+6)
	call	SeMenu_FillEntryTable
	ld	a, (xsp+2)
	extz	wa
	ld	c, (xsp+6)
	extz	bc
	call	SeMenu_StorePartParam
	call	SeMenu_AdvanceSubIndex
	cp	l, 15
	jr	ule, 100
	lda	xbc, (xsp+6)
	ldw	wa, 15
	call	SeMenu_LoadPartParam
	ld	c, (xsp+6)
	extz	bc
	ldw	wa, 16
	call	SeMenu_StorePartParam
	lda	xbc, (xsp+6)
	ldw	wa, 14
	call	SeMenu_LoadPartParam
	ld	c, (xsp+6)
	extz	bc
	ldw	wa, 15
	call	SeMenu_StorePartParam
	lda	xbc, (xsp+6)
	ldw	wa, 13
	call	SeMenu_LoadPartParam
	ld	c, (xsp+6)
	extz	bc
	ldw	wa, 14
	call	SeMenu_StorePartParam
	ldw	wa, 13
	ld	bc, 1:i3
	call	SeMenu_StorePartParam
	pushw	39
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	ld	wa, 1:i3
	call	SeMenu_SetupMenuDisplay
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_ResetSubIndex
	pop qiz
	lda	xsp, (xsp+10)
	ret
	lda	xsp, (xsp-10)
	.byte 0xd7
	swi	2
	.byte 0x04
	lda	xwa, (xsp+10)
	call	SeMenu_ReadObjData
	.byte 0x8f
	ldw	(63:8), 0x6e00:io
	push	xde
	lda	xwa, (xsp+2)
	call	SeMenu_ValidatePartNumber
	ldib_erp 251, 0
	ld	a, (xsp+2)
	extz	wa
	ld	c, 7:opc
	addb_erp c, 251
	pushw	40
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 251
	cp_erpb 251, 10
	jr c, -28
	ld	wa, 1:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_AdvanceSubIndex
	ld	wa, 0:i3
	ld	bc, 1:i3
	call	SeMenu_StorePartParam
	jr	66
	lda	xwa, (xsp+4)
	call	SeMenu_ReadObjParam
	lda	xwa, (xsp+6)
	call	SeMenu_FillEntryTable
	ld	a, (xsp+4)
	extz	wa
	ld	c, (xsp+6)
	extz	bc
	call	SeMenu_StorePartParam
	call	SeMenu_AdvanceSubIndex
	cp	l, 10
	jr	ule, 29
	pushw	40
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	call	SeMenu_ApplyPartEdit_Data2_0xDB3
	ld	wa, 1:i3
	call	SeMenu_SetupMenuDisplay
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_ResetSubIndex
	pop qiz
	lda	xsp, (xsp+10)
	ret
	lda	xsp, (xsp-10)
	.byte 0xd7
	swi	2
	.byte 0x04
	lda	xwa, (xsp+10)
	call	SeMenu_ReadObjData
	.byte 0x8f
	ldw	(63:8), 0x6e00:io
	pushw	iy
	lda	xwa, (xsp+2)
	call	SeMenu_ValidatePartNumber
	ldib_erp 251, 0
	ld	a, (xsp+2)
	extz	wa
	ld	c, 17:opc
	addb_erp c, 251
	pushw	41
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 251
	cpib_erp 251, 6
	jr c, -27
	ld	wa, 1:i3
	call	SeMenu_SetCurrentStep
	jr	99
	lda	xwa, (xsp+4)
	call	SeMenu_ReadObjParam
	lda	xwa, (xsp+6)
	call	SeMenu_FillEntryTable
	ld	a, (xsp+4)
	extz	wa
	ld	c, (xsp+6)
	extz	bc
	call	SeMenu_StorePartParam
	call	SeMenu_AdvanceSubIndex
	cp	l, 5:i3
	jr	ule, 63
	lda	xbc, (xsp+6)
	ld	wa, 3:i3
	call	SeMenu_LoadPartParam
	ld	c, (xsp+6)
	extz	bc
	ldw	wa, 10
	call	SeMenu_StorePartParam
	ldw	wa, 9
	ld	bc, 0:i3
	call	SeMenu_StorePartParam
	pushw	41
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	ld	wa, 2:i3
	ld	bc, 1:i3
	call	SeMenu_ApplyPartEdit_Data2_0x13DE
	ld	wa, 1:i3
	call	SeMenu_SetupMenuDisplay
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_ResetSubIndex
	pop qiz
	lda	xsp, (xsp+10)
	ret
	ldw	wa, 42
	jr	0
	lda	xsp, (xsp-14)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+14), a
	.byte 0x8f
	ret
	push	xsp
	pushw	de
	jrl	nz, 147
	ldib_erp 251, 1
	lda	xwa, (xsp+12)
	call	SeMenu_ReadObjData
	.byte 0x8f
	incf
	push	xsp
	nop
	jrl	nz, 154
	stb_erp a, 251
	extz	wa
	lda	xbc, (xsp+4)
	call	SeMenu_TransferPartValues_EndData
	stb_erp a, 251
	extz	wa
	ld	c, (xsp+4)
	extz	bc
	lda	xde, (xsp+2)
	call	SeMenu_TransferPartValues
	ldib_erp 250, 0
	ld	c, (xsp+2)
	addb_erp c, 250
	extz bc
	ld	a, (xsp+14)
	extz	wa
	pushw	wa
	ld	wa, 0:i3
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 250
	cpib_erp 250, 4
	jr c, -30
	stb_erp a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_TransferPartValues_AltLoop_0x9
	ldib_erp 250, 1
	stb_erp a, 250
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	ld	e, (xsp+14)
	extz	de
	pushw	de
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	.byte 0xc7
	swi	2
	jr	lt, -57
	swi	2
	inc	3, ix
	add	(0x1da9d8:24), xix
	jrl	lt, 7664
	.byte 0x97
	jrl	lt, -28688
	.byte 0x04
	ld	c, 217:opc
	ccf
	ld	wa, 0:i3
	call	SeMenu_StorePartParam
	jr	89
	.byte 0x8f
	ret
	push	xsp
	pushw	sp
	jr	nz, 6
	ldib_erp 251, 0
	jrl	-156
	.byte 0x8f
	ret
	.ascii "?9nG"
	ldib_erp 251, 2
	jrl	-168
	lda	xwa, (xsp+6)
	call	SeMenu_ReadObjParam
	lda	xwa, (xsp+8)
	call	SeMenu_FillEntryTable
	ld	a, (xsp+6)
	extz	wa
	ld	c, (xsp+8)
	extz	bc
	call	SeMenu_StorePartParam
	call	SeMenu_AdvanceSubIndex
	cp	l, 8
	jr	ule, 28
	ld	a, (xsp+14)
	extz	wa
	pushw	wa
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	ld	wa, 1:i3
	call	SeMenu_SetupMenuDisplay
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_ResetSubIndex
	pop qiz
	lda	xsp, (xsp+14)
	ret
	lda	xsp, (xsp-12)
	lda	xwa, (xsp+10)
	call	SeMenu_ReadObjData
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	ldw	(63:8), 0x6e00:io
	pushw	ix
	.byte 0x87
	push	xsp
	nop
	jr	nz, 5
	calr	197
	jr	3
	calr	240
	ld	wa, 1:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_AdvanceSubIndex
	lda	xwa, (xsp+4)
	call	SeMenu_ValidatePartNumber
	ld	c, (xsp+4)
	extz	bc
	ld	wa, 0:i3
	call	SeMenu_StorePartParam
	jrl	157
	lda	xwa, (xsp+2)
	call	SeMenu_ReadObjParam
	lda	xwa, (xsp+6)
	call	SeMenu_FillEntryTable
	ld	a, (xsp+2)
	extz	wa
	ld	c, (xsp+6)
	extz	bc
	call	SeMenu_StorePartParam
	.byte 0x87
	push	xsp
	nop
	jr	nz, 116
	call	SeMenu_AdvanceSubIndex
	cp	l, 12
	jr	ule, 115
	lda	xbc, (xsp+6)
	ld	wa, 1:i3
	call	SeMenu_LoadParamByte
	ld	c, (xsp+6)
	extz	bc
	ld	wa, 1:i3
	call	SeMenu_StorePartParam
	lda	xbc, (xsp+6)
	ld	wa, 2:i3
	call	SeMenu_LoadParamByte
	ld	c, (xsp+6)
	extz	bc
	ld	wa, 2:i3
	call	SeMenu_StorePartParam
	lda	xbc, (xsp+6)
	ld	wa, 3:i3
	call	SeMenu_LoadParamByte
	ld	c, (xsp+6)
	extz	bc
	ld	wa, 3:i3
	call	SeMenu_StorePartParam
	lda	xbc, (xsp+6)
	ld	wa, 4:i3
	call	SeMenu_LoadParamByte
	ld	c, (xsp+6)
	extz	bc
	ld	wa, 4:i3
	call	SeMenu_StorePartParam
	pushw	43
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	ld	wa, 1:i3
	call	SeMenu_SetupMenuDisplay
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_ResetSubIndex
	jr	8
	call	SeMenu_AdvanceSubIndex
	cp	l, 4:i3
	jr	ugt, -35
	lda	xsp, (xsp+12)
	ret
	.byte 0xd7
	swi	2
	.byte 0x04, 0xc7
	swi	2
	cp	(xwa-57), xhl
	cp	(xbc-57), xhl
	.byte 0x89
	extz	wa
	ld	c, 23:opc
	addb_erp c, 250
	pushw	43
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 251
	cpib_erp 251, 4
	jr ule, -27
	inc1b_erp 250
	cpib_erp 250, 3
	jr c, -38
	pop qiz
	ret
	.byte 0xd7
	swi	2
	.byte 0x04, 0xc7
	swi	2
	cp	(xwa-57), xhl
	cp	(xwa-57), xhl
	.byte 0x89
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	inc	6, xwa
	addb_erp a, 250
	ld c, a
	pushw	43
	ld	wa, 0:i3
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type2
	inc1b_erp 251
	cpib_erp 251, 2
	jr c, -40
	inc1b_erp 250
	cpib_erp 250, 2
	jr c, -51
	pop qiz
	ret
	lda	xsp, (xsp-10)
	.byte 0xd7
	swi	2
	.byte 0x04
	lda	xwa, (xsp+10)
	call	SeMenu_ReadObjData
	.byte 0x8f
	ldw	(63:8), 0x6e00:io
	pushw	iy
	lda	xwa, (xsp+2)
	call	SeMenu_ValidatePartNumber
	ldib_erp 251, 0
	ld	a, (xsp+2)
	extz	wa
	ld	c, 26:opc
	addb_erp c, 251
	pushw	44
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 251
	cpib_erp 251, 4
	jr c, -27
	ld	wa, 1:i3
	call	SeMenu_SetCurrentStep
	jr	90
	lda	xwa, (xsp+4)
	call	SeMenu_ReadObjParam
	lda	xwa, (xsp+6)
	call	SeMenu_FillEntryTable
	ld	a, (xsp+4)
	extz	wa
	ld	c, (xsp+6)
	extz	bc
	call	SeMenu_StorePartParam
	call	SeMenu_AdvanceSubIndex
	cp	l, 3:i3
	jr	ule, 54
	pushw	44
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	lda	xbc, (xsp+6)
	ld	wa, 3:i3
	call	SeMenu_LoadPartParam
	ld	c, (xsp+6)
	extz	bc
	ldw	wa, 10
	call	SeMenu_StorePartParam
	ld	wa, 0:i3
	ld	bc, 0:i3
	call	SeMenu_ApplyPartEdit_Data2_0x13DE
	ld	wa, 1:i3
	call	SeMenu_SetupMenuDisplay
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_ResetSubIndex
	pop qiz
	lda	xsp, (xsp+10)
	ret
	lda	xsp, (xsp-10)
	lda	xwa, (xsp+8)
	call	SeMenu_ReadObjData
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	ld	(63:8), 0:io
	jr	nz, 21
	.byte 0x87
	push	xsp
	nop
	jr	nz, 5
	calr	97
	jr	3
	calr	140
	ld	wa, 1:i3
	call	SeMenu_SetCurrentStep
	jr	80
	lda	xwa, (xsp+2)
	call	SeMenu_ReadObjParam
	lda	xwa, (xsp+4)
	call	SeMenu_FillEntryTable
	ld	a, (xsp+2)
	extz	wa
	ld	c, (xsp+4)
	extz	bc
	call	SeMenu_StorePartParam
	.byte 0x87
	push	xsp
	nop
	jr	nz, 10
	call	SeMenu_AdvanceSubIndex
	cp	l, 6:i3
	jr	ugt, 10
	jr	37
	call	SeMenu_AdvanceSubIndex
	cp	l, 7:i3
	jr	ule, 29
	pushw	45
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	call	SeMenu_ApplyPartEdit_Data2_0xA69
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	ld	wa, 1:i3
	call	SeMenu_SetupMenuDisplay
	call	SeMenu_ResetSubIndex
	lda	xsp, (xsp+10)
	ret
	dec	2, xsp
	.byte 0xd7
	swi	2
	.byte 0x04
	lda	xwa, (xsp+2)
	call	SeMenu_ValidatePartNumber
	ldib_erp 251, 0
	ld	a, (xsp+2)
	extz	wa
	ld	c, 39:opc
	addb_erp c, 251
	pushw	45
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 251
	cpib_erp 251, 7
	jr	c, -27
	pop qiz
	inc	2, xsp
	ret
	dec	2, xsp
	.byte 0xd7
	swi	2
	.byte 0x04
	lda	xwa, (xsp+2)
	call	SeMenu_ValidatePartNumber
	pushw	45
	ld	wa, 0:i3
	ldw	bc, 13
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type2
	ldib_erp 251, 0
	ld	a, (xsp+2)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	inc	8, xwa
	addb_erp a, 251
	ld c, a
	pushw	45
	ld	wa, 0:i3
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type2
	inc1b_erp 251
	cpib_erp 251, 7
	jr	c, -42
	pop qiz
	inc	2, xsp
	ret
	lda	xsp, (xsp-10)
	.byte 0xd7
	swi	2
	.byte 0x04
	lda	xwa, (xsp+10)
	call	SeMenu_ReadObjData
	.byte 0x8f
	ldw	(63:8), 0x6e00:io
	pushw	iz
	lda	xwa, (xsp+2)
	call	SeMenu_ValidatePartNumber
	ldib_erp 251, 0
	ld	a, (xsp+2)
	extz	wa
	ld	c, 46:opc
	addb_erp c, 251
	pushw	46
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 251
	cp_erpb 251, 8
	jr c, -28
	ld	wa, 1:i3
	call	SeMenu_SetCurrentStep
	jr	99
	lda	xwa, (xsp+4)
	call	SeMenu_ReadObjParam
	lda	xwa, (xsp+6)
	call	SeMenu_FillEntryTable
	ld	a, (xsp+4)
	extz	wa
	ld	c, (xsp+6)
	extz	bc
	call	SeMenu_StorePartParam
	call	SeMenu_AdvanceSubIndex
	cp	l, 7:i3
	jr	ule, 63
	lda	xbc, (xsp+6)
	ld	wa, 5:i3
	call	SeMenu_LoadPartParam
	ld	c, (xsp+6)
	extz	bc
	ldw	wa, 10
	call	SeMenu_StorePartParam
	ldw	wa, 9
	ld	bc, 0:i3
	call	SeMenu_StorePartParam
	pushw	46
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	ld	wa, 2:i3
	ld	bc, 0:i3
	call	SeMenu_ApplyPartEdit_Data2_0x13DE
	ld	wa, 1:i3
	call	SeMenu_SetupMenuDisplay
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_ResetSubIndex
	pop qiz
	lda	xsp, (xsp+10)
	ret
	ldw	wa, 47
	jrl	-1185
	lda	xsp, (xsp-10)
	lda	xwa, (xsp+8)
	call	SeMenu_ReadObjData
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	ld	(63:8), 0:io
	jr	nz, 21
	.byte 0x87
	push	xsp
	nop
	jr	nz, 5
	calr	116
	jr	3
	calr	235
	ld	wa, 1:i3
	call	SeMenu_SetCurrentStep
	jr	99
	lda	xwa, (xsp+2)
	call	SeMenu_ReadObjParam
	lda	xwa, (xsp+4)
	call	SeMenu_FillEntryTable
	ld	a, (xsp+2)
	extz	wa
	ld	c, (xsp+4)
	extz	bc
	call	SeMenu_StorePartParam
	call	SeMenu_AdvanceSubIndex
	cp	l, 8
	jr	ule, 62
	lda	xbc, (xsp+4)
	ld	wa, 7:i3
	call	SeMenu_LoadPartParam
	ld	c, (xsp+4)
	extz	bc
	ldw	wa, 11
	call	SeMenu_StorePartParam
	lda	xbc, (xsp+4)
	ldw	wa, 8
	call	SeMenu_LoadPartParam
	ld	c, (xsp+4)
	extz	bc
	ldw	wa, 12
	call	SeMenu_StorePartParam
	pushw	59
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_ResetSubIndex
	lda	xsp, (xsp+10)
	ret
	dec	4, xsp
	.byte 0xd7
	swi	2
	.byte 0x04, 0xc7
	swi	3
	cp	(xwa-57), xhl
	.byte 0x89
	mul	a, 3
	add	a, 24
	ld	c, a
	pushw	59
	ld	wa, 0:i3
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 251
	cpib_erp 251, 6
	jr c, -30
	lda	xwa, (xsp+4)
	call	SeMenu_TransferPartValues_EndData_0x8D
	ld	a, (xsp+4)
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_TransferPartValues_EndData_0xA3
	ld	c, (xsp+2)
	inc	2, c
	extz	bc
	pushw	59
	ld	wa, 0:i3
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	ld	c, (xsp+2)
	extz	bc
	pushw	59
	ld	wa, 0:i3
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	ld	c, (xsp+2)
	extz	bc
	ldw	wa, 13
	call	SeMenu_StorePartParam
	call	SeMenu_AdvanceSubIndex
	ld	c, (xsp+4)
	extz	bc
	ld	wa, 0:i3
	call	SeMenu_StorePartParam
	pop qiz
	inc	4, xsp
	ret
	dec	4, xsp
	.byte 0xd7
	swi	2
	.byte 0x04, 0xc7
	swi	3
	cp	(xwa-57), xhl
	.byte 0x89
	mul	a, 3
	add	a, 22
	ld	c, a
	pushw	59
	ld	wa, 3:i3
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type2
	inc1b_erp 251
	cpib_erp 251, 6
	jr c, -30
	lda	xwa, (xsp+4)
	call	SeMenu_TransferPartValues_EndData_0x8D
	ld	a, (xsp+4)
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_TransferPartValues_EndData_0xC0
	ld	c, (xsp+2)
	inc	2, c
	extz	bc
	pushw	59
	ld	wa, 3:i3
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type2
	ld	c, (xsp+2)
	extz	bc
	pushw	59
	ld	wa, 3:i3
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type2
	ld	c, (xsp+2)
	extz	bc
	ldw	wa, 13
	call	SeMenu_StorePartParam
	call	SeMenu_AdvanceSubIndex
	ld	c, (xsp+4)
	extz	bc
	ld	wa, 0:i3
	call	SeMenu_StorePartParam
	pop qiz
	inc	4, xsp
	ret
	dec	6, xsp
	lda	xwa, (xsp+4)
	call	SeMenu_ReadObjData
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	nz, 18
	pushw	60
	ld	wa, 0:i3
	ldw	bc, 16
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	ld	wa, 1:i3
	jr	28
	lda	xwa, (xsp)
	call	SeMenu_FillEntryTable
	ld c, (xsp+256)
	extz bc
	ld	wa, 0:i3
	call	SeMenu_StorePartParam
	pushw	60
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	inc	6, xsp
	ret
	lda	xsp, (xsp-10)
	lda	xwa, (xsp+8)
	call	SeMenu_ReadObjData
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	ld	(63:8), 0:io
	jr	nz, 21
	.byte 0x87
	push	xsp
	nop
	jr	nz, 5
	calr	144
	jr	3
	calr	217
	ld	wa, 1:i3
	call	SeMenu_SetCurrentStep
	jr	127
	lda	xwa, (xsp+2)
	call	SeMenu_ReadObjParam
	lda	xwa, (xsp+4)
	call	SeMenu_FillEntryTable
	ld	a, (xsp+2)
	extz	wa
	ld	c, (xsp+4)
	extz	bc
	call	SeMenu_StorePartParam
	call	SeMenu_AdvanceSubIndex
	cp	l, 5:i3
	jr	ule, 91
	lda	xbc, (xsp+4)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	.byte 0x8f, 0x04
	push	xix
	reti
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_ResetSubIndex
	lda	xbc, (xsp+4)
	ld	a, (xbc)
	cp	a, 1:i3
	jr	ule, 17
	cp	a, 5:i3
	jr	ugt, 13
	dec	1, a
	ld	(xbc), a
	add	a, 48
	extz	wa
	ld	bc, 0:i3
	jr	9
	cp	a, 0:i3
	jr	nz, 11
	ldw	wa, 53
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	jr	27
	pushw	48
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	ld	wa, 0:i3
	ld	bc, 0:i3
	call	SeMenu_ApplyPartEdit_Data2_0x1815
	call	SeMenu_ApplyPartEdit_Data2_0x19BD
	ld	wa, 1:i3
	call	SeMenu_SetupMenuDisplay
	lda	xsp, (xsp+10)
	ret
	dec	2, xsp
	.byte 0xd7
	swi	2
	.byte 0x04
	lda	xwa, (xsp+2)
	call	SeMenu_ValidatePartNumber
	ldib_erp 251, 0
	ld	a, (xsp+2)
	extz	wa
	ld	c, 54:opc
	addb_erp c, 251
	pushw	48
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 251
	cpib_erp 251, 2
	jr c, -27
	ldib_erp 251, 0
	ld	a, (xsp+2)
	extz	wa
	ld	c, 77:opc
	addb_erp c, 251
	pushw	48
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 251
	cpib_erp 251, 4
	jr c, -27
	pop qiz
	inc	2, xsp
	ret
	dec	2, xsp
	.byte 0xd7
	swi	2
	.byte 0x04
	lda	xwa, (xsp+2)
	call	SeMenu_ValidatePartNumber
	ldib_erp 251, 0
	ld	a, (xsp+2)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+15)
	addb_erp a, 251
	ld c, a
	pushw	48
	ld	wa, 0:i3
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type2
	inc1b_erp 251
	cpib_erp 251, 6
	jr c, -43
	pop qiz
	inc	2, xsp
	ret
	pushw	49
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	ld	wa, 1:i3
	ld	bc, 0:i3
	call	SeMenu_ApplyPartEdit_Data2_0x1815
	call	SeMenu_ApplyPartEdit_Data2_0x19BD
	ld	wa, 1:i3
	jp	SeMenu_SetupMenuDisplay
	pushw	50
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	ld	wa, 0:i3
	ld	bc, 1:i3
	call	SeMenu_ApplyPartEdit_Data2_0x1815
	ld	wa, 1:i3
	jp	SeMenu_SetupMenuDisplay
	pushw	51
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	ld	wa, 1:i3
	ld	bc, 1:i3
	call	SeMenu_ApplyPartEdit_Data2_0x1815
	ld	wa, 1:i3
	jp	SeMenu_SetupMenuDisplay
	pushw	52
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	call	SeMenu_ApplyPartEdit_Data2_0x1AAD
	ld	wa, 1:i3
	jp	SeMenu_SetupMenuDisplay
	pushw	53
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	ld	wa, 1:i3
	jp	SeMenu_SetupMenuDisplay
	lda	xsp, (xsp-10)
	.byte 0xd7
	swi	2
	.byte 0x04
	lda	xwa, (xsp+10)
	call	SeMenu_ReadObjData
	.byte 0x8f
	ldw	(63:8), 0x6e00:io
	pushw	iy
	lda	xwa, (xsp+2)
	call	SeMenu_ValidatePartNumber
	ldib_erp 251, 0
	ld	a, (xsp+2)
	extz	wa
	ld	c, 57:opc
	addb_erp c, 251
	pushw	54
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 251
	cpib_erp 251, 4
	jr c, -27
	ld	wa, 1:i3
	call	SeMenu_SetCurrentStep
	jr	90
	lda	xwa, (xsp+4)
	call	SeMenu_ReadObjParam
	lda	xwa, (xsp+6)
	call	SeMenu_FillEntryTable
	ld	a, (xsp+4)
	extz	wa
	ld	c, (xsp+6)
	extz	bc
	call	SeMenu_StorePartParam
	call	SeMenu_AdvanceSubIndex
	cp	l, 3:i3
	jr	ule, 54
	lda	xbc, (xsp+6)
	ld	wa, 3:i3
	call	SeMenu_LoadPartParam
	ld	c, (xsp+6)
	extz	bc
	ldw	wa, 10
	call	SeMenu_StorePartParam
	pushw	54
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	ld	wa, 0:i3
	ld	bc, 0:i3
	call	SeMenu_ApplyPartEdit_Data2_0x13DE
	ld	wa, 1:i3
	call	SeMenu_SetupMenuDisplay
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_ResetSubIndex
	pop qiz
	lda	xsp, (xsp+10)
	ret
	lda	xsp, (xsp-10)
	.byte 0xd7
	swi	2
	.byte 0x04
	lda	xwa, (xsp+10)
	call	SeMenu_ReadObjData
	.byte 0x8f
	ldw	(63:8), 0x6e00:io
	push	xde
	lda	xwa, (xsp+2)
	call	SeMenu_ValidatePartNumber
	ldib_erp 251, 0
	ld	a, (xsp+2)
	extz	wa
	ld	c, 61:opc
	addb_erp c, 251
	pushw	55
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 251
	cp_erpb 251, 10
	jr c, -28
	ld	wa, 1:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_AdvanceSubIndex
	ld	wa, 0:i3
	ld	bc, 1:i3
	call	SeMenu_StorePartParam
	jr	66
	lda	xwa, (xsp+4)
	call	SeMenu_ReadObjParam
	lda	xwa, (xsp+6)
	call	SeMenu_FillEntryTable
	ld	a, (xsp+4)
	extz	wa
	ld	c, (xsp+6)
	extz	bc
	call	SeMenu_StorePartParam
	call	SeMenu_AdvanceSubIndex
	cp	l, 10
	jr	ule, 29
	pushw	55
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	call	SeMenu_ApplyPartEdit_Data2_0xDB3
	ld	wa, 1:i3
	call	SeMenu_SetupMenuDisplay
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_ResetSubIndex
	pop qiz
	lda	xsp, (xsp+10)
	ret
	lda	xsp, (xsp-10)
	.byte 0xd7
	swi	2
	.byte 0x04
	lda	xwa, (xsp+10)
	call	SeMenu_ReadObjData
	.byte 0x8f
	ldw	(63:8), 0x6e00:io
	pushw	iy
	lda	xwa, (xsp+2)
	call	SeMenu_ValidatePartNumber
	ldib_erp 251, 0
	ld	a, (xsp+2)
	extz	wa
	ld	c, 71:opc
	addb_erp c, 251
	pushw	56
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 251
	cpib_erp 251, 6
	jr c, -27
	ld	wa, 1:i3
	call	SeMenu_SetCurrentStep
	jr	99
	lda	xwa, (xsp+4)
	call	SeMenu_ReadObjParam
	lda	xwa, (xsp+6)
	call	SeMenu_FillEntryTable
	ld	a, (xsp+4)
	extz	wa
	ld	c, (xsp+6)
	extz	bc
	call	SeMenu_StorePartParam
	call	SeMenu_AdvanceSubIndex
	cp	l, 5:i3
	jr	ule, 63
	lda	xbc, (xsp+6)
	ld	wa, 3:i3
	call	SeMenu_LoadPartParam
	ld	c, (xsp+6)
	extz	bc
	ldw	wa, 10
	call	SeMenu_StorePartParam
	ldw	wa, 9
	ld	bc, 0:i3
	call	SeMenu_StorePartParam
	pushw	56
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	ld	wa, 2:i3
	ld	bc, 1:i3
	call	SeMenu_ApplyPartEdit_Data2_0x13DE
	ld	wa, 1:i3
	call	SeMenu_SetupMenuDisplay
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_ResetSubIndex
	pop qiz
	lda	xsp, (xsp+10)
	ret
	ldw	wa, 57
	jrl	-2557

SeMenu_AltUpdate:
	lda xsp, (xsp - 38)
	pushw_erp 0xfa
	lda xwa, (xsp + 38)
	call SeMenu_ReadObjData
	cp (xsp + 38), 0x0
	jr nz, SeMenu_AltUpdate_Step1
	ldib_erp 0xfb, 1

SeMenu_AltUpdate_RegLoop:
	stb_erp A, 0xfb
	extz wa
	pushw 0x22
	ldw bc, 0x17
	ld de, 1:i3
	call SeMenu_RegisterElement_Type1
	stb_erp A, 0xfb
	extz wa
	pushw 0x22
	ld bc, 4:i3
	ld de, 1:i3
	call SeMenu_RegisterElement_Type1
	stb_erp A, 0xfb
	extz wa
	pushw 0x22
	ld bc, 5:i3
	ld de, 1:i3
	call SeMenu_RegisterElement_Type1
	inc1b_erp 0xfb
	cpib_erp 0xfb, 4
	jr ule, SeMenu_AltUpdate_RegLoop
	ld wa, 1:i3
	call SeMenu_SetCurrentStep
	call SeMenu_AdvanceSubIndex
	lda xwa, (xsp + 4)
	call SeMenu_ValidatePartNumber
	ld c, (xsp + 4)
	extz bc
	ld wa, 0:i3
	call SeMenu_StorePartParam
	call SeMenu_AdvanceSubIndex
	jrl SeMenu_AltUpdate_End

SeMenu_AltUpdate_Step1:
	lda xwa, (xsp + 2)
	cp (xsp + 38), 0x1
	jr nz, SeMenu_AltUpdate_Step2
	call SeMenu_ReadObjParam
	lda xwa, (xsp + 6)
	call SeMenu_FillEntryTable
	ld a, (xsp + 2)
	extz wa
	ld c, (xsp + 6)
	extz bc
	call SeMenu_StorePartParam
	call SeMenu_AdvanceSubIndex
	cp l, 0xd
	jrl ule, SeMenu_AltUpdate_End
	call SeMenu_ResetSubIndex
	call SeMenu_AdvanceSubIndex
	lda xwa, (xsp + 2)
	call SeMenu_ReadObjParam
	ld a, (xsp + 2)
	extz wa
	ldw bc, 0x22
	call SeMenu_InitDisplayField
	ld wa, 2:i3
	jr SeMenu_AltUpdate_SetStepAndJump

SeMenu_AltUpdate_Step2:
	cp (xsp + 38), 0x2
	jr nz, SeMenu_AltUpdate_Step3Plus
	call SeMenu_ReadObjParam
	ld a, (xsp + 2)
	extz wa
	call SeMenu_ApplyFilter
	call SeMenu_AdvanceSubIndex
	cp l, 4:i3
	jr ugt, SeMenu_AltUpdate_Step2_InitCol
	lda xwa, (xsp + 2)
	call SeMenu_ReadObjParam
	ld a, (xsp + 2)
	extz wa
	ldw bc, 0x22
	call SeMenu_InitDisplayField
	jrl SeMenu_AltUpdate_End

SeMenu_AltUpdate_Step2_InitCol:
	ld wa, 0:i3
	ldw bc, 0x22
	call SeMenu_InitDisplayColumn
	ld wa, 3:i3

SeMenu_AltUpdate_SetStepAndJump:
	call SeMenu_SetCurrentStep
	jr SeMenu_AltUpdate_End

SeMenu_AltUpdate_Step3Plus:
	ld xwa, 0:i3
	call SeMenu_ProcessEffect
	lda xbc, (xsp + 6)
	ld wa, 1:i3
	call SeMenu_LoadParamByte
	ld c, (xsp + 6)
	extz bc
	ld wa, 2:i3
	call SeMenu_StorePartParam
	lda xbc, (xsp + 6)
	ld wa, 2:i3
	call SeMenu_LoadParamByte
	ld c, (xsp + 6)
	extz bc
	ld wa, 5:i3
	call SeMenu_StorePartParam
	lda xbc, (xsp + 6)
	ld wa, 3:i3
	call SeMenu_LoadParamByte
	ld c, (xsp + 6)
	extz bc
	ldw wa, 0x8
	call SeMenu_StorePartParam
	lda xbc, (xsp + 6)
	ld wa, 4:i3
	call SeMenu_LoadParamByte
	ld c, (xsp + 6)
	extz bc
	ldw wa, 0xb
	call SeMenu_StorePartParam
	pushw 0x22
	call SeMenu_ShowPopupDialog
	inc 2, xsp
	ld wa, 1:i3
	call SeMenu_SetupMenuDisplay
	ld wa, 0:i3
	call SeMenu_SetCurrentStep
	call SeMenu_ResetSubIndex

SeMenu_AltUpdate_End:
	popw_erp 0xfa
	lda xsp, (xsp + 38)
	ret

SeMenu_AltUpdate_Data:
	lda	xsp, (xsp-10)
	.byte 0xd7
	swi	2
	.byte 0x04
	lda	xwa, (xsp+10)
	call	SeMenu_ReadObjData
	.byte 0x8f
	ldw	(63:8), 0x6e00:io
	jrl	f, 8971
	nop
	ld	wa, 0:i3
	ldw	bc, 18
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	ldib_erp 251, 1
	stb_erp a, 251
	extz	wa
	pushw	35
	ld	bc, 0:i3
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 251
	cpib_erp 251, 4
	jr ule, -24
	ldib_erp 251, 1
	stb_erp a, 251
	extz	wa
	pushw	35
	ld	bc, 1:i3
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 251
	cpib_erp 251, 4
	jr ule, -24
	pushw	35
	ld	wa, 0:i3
	ldw	bc, 92
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	ld	wa, 1:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_AdvanceSubIndex
	lda	xwa, (xsp+2)
	call	SeMenu_ValidatePartNumber
	ld	c, (xsp+2)
	extz	bc
	ld	wa, 0:i3
	call	SeMenu_StorePartParam
	jr	82
	lda	xwa, (xsp+4)
	call	SeMenu_ReadObjParam
	lda	xwa, (xsp+6)
	call	SeMenu_FillEntryTable
	ld	a, (xsp+4)
	extz	wa
	ld	c, (xsp+6)
	extz	bc
	call	SeMenu_StorePartParam
	call	SeMenu_AdvanceSubIndex
	cp	l, 10
	jr	ule, 45
	ldib_erp 251, 1
	stb_erp a, 251
	extz	wa
	call	SeMenu_ApplyPartEdit
	inc1b_erp 251
	cpib_erp 251, 4
	jr ule, -17
	pushw	35
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	ld	wa, 1:i3
	call	SeMenu_SetupMenuDisplay
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_ResetSubIndex
	pop qiz
	lda	xsp, (xsp+10)
	ret
	lda	xsp, (xsp-10)
	.byte 0xd7
	swi	2
	.byte 0x04
	lda	xwa, (xsp+10)
	call	SeMenu_ReadObjData
	.byte 0x8f
	ldw	(63:8), 0x6e00:io
	jr	mi, -65
	push	sr
	ldw	wa, 0x3a1d
	jr	gt, -16
	ldib_erp 250, 0
	ld	a, (xsp+2)
	extz	wa
	ld	c, 30:opc
	addb_erp c, 250
	pushw	36
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 250
	cpib_erp 250, 4
	jr c, -27
	ldib_erp 251, 1
	ldib_erp 250, 0
	stb_erp a, 251
	extz	wa
	ld	c, 30:opc
	addb_erp c, 250
	pushw	36
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	.byte 0xc7
	swi	2
	jr	lt, -57
	swi	2
	inc	7, ix
	.byte 0xe5, 0xc7
	swi	3
	jr	lt, -57
	swi	3
	inc	3, ix
	cp	de, 0:i3
	add	(xbc+29), xix
	jrl	lt, 7664
	.byte 0x97
	jrl	lt, -28688
	push	sr
	ld	c, 217:opc
	ccf
	ld	wa, 0:i3
	call	SeMenu_StorePartParam
	jr	96
	lda	xwa, (xsp+4)
	call	SeMenu_ReadObjParam
	lda	xwa, (xsp+6)
	call	SeMenu_FillEntryTable
	ld	a, (xsp+4)
	extz	wa
	ld	c, (xsp+6)
	extz	bc
	call	SeMenu_StorePartParam
	call	SeMenu_AdvanceSubIndex
	cp	l, 20
	jr	ule, 59
	pushw	36
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	ldib_erp 250, 1
	stb_erp c, 250
	extz	bc
	stb_erp a, 250
	sll a, 2
	inc	1, a
	ld	e, a
	extz	de
	ld	wa, 0:i3
	call	SeMenu_ApplyPartEdit_Data2_0x162C
	inc1b_erp 250
	cpib_erp 250, 4
	jr ule, -31
	ld	wa, 1:i3
	call	SeMenu_SetupMenuDisplay
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_ResetSubIndex
	pop qiz
	lda	xsp, (xsp+10)
	ret
	lda	xsp, (xsp-10)
	.byte 0xd7
	swi	2
	.byte 0x04
	lda	xwa, (xsp+10)
	call	SeMenu_ReadObjData
	.byte 0x8f
	ldw	(63:8), 0x6e00:io
	jr	mi, -65
	push	sr
	ldw	wa, 0x3a1d
	jr	gt, -16
	ldib_erp 250, 0
	ld	a, (xsp+2)
	extz	wa
	ld	c, 34:opc
	addb_erp c, 250
	pushw	37
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 250
	cpib_erp 250, 4
	jr c, -27
	ldib_erp 251, 1
	ldib_erp 250, 0
	stb_erp a, 251
	extz	wa
	ld	c, 34:opc
	addb_erp c, 250
	pushw	37
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	.byte 0xc7
	swi	2
	jr	lt, -57
	swi	2
	inc	7, ix
	.byte 0xe5, 0xc7
	swi	3
	jr	lt, -57
	swi	3
	inc	3, ix
	cp	de, 0:i3
	add	(xbc+29), xix
	jrl	lt, 7664
	.byte 0x97
	jrl	lt, -28688
	push	sr
	ld	c, 217:opc
	ccf
	ld	wa, 0:i3
	call	SeMenu_StorePartParam
	jr	96
	lda	xwa, (xsp+4)
	call	SeMenu_ReadObjParam
	lda	xwa, (xsp+6)
	call	SeMenu_FillEntryTable
	ld	a, (xsp+4)
	extz	wa
	ld	c, (xsp+6)
	extz	bc
	call	SeMenu_StorePartParam
	call	SeMenu_AdvanceSubIndex
	cp	l, 20
	jr	ule, 59
	pushw	37
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	ldib_erp 250, 1
	stb_erp c, 250
	extz	bc
	stb_erp a, 250
	sll a, 2
	inc	1, a
	ld	e, a
	extz	de
	ld	wa, 1:i3
	call	SeMenu_ApplyPartEdit_Data2_0x162C
	inc1b_erp 250
	cpib_erp 250, 4
	jr ule, -31
	ld	wa, 1:i3
	call	SeMenu_SetupMenuDisplay
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_ResetSubIndex
	pop qiz
	lda	xsp, (xsp+10)
	ret

SeMenu_ControllerUpdate:
	lda xsp, (xsp - 42)
	pushw_erp 0xfa
	lda xwa, (xsp + 2)
	call SeMenu_LoadObjEntries
	lda xwa, (xsp + 8)
	call SeMenu_ValidatePartNumber
	lda xwa, (xsp + 42)
	call SeMenu_ReadObjData
	cp (xsp + 42), 0x0
	jr nz, SeMenu_ControllerUpdate_StoreValue
	lda xwa, (xsp + 6)
	call SeMenu_InitObjEntry
	ldib_erp 0xfb, 0
	cp (xsp + 2), 0x0
	jr nz, SeMenu_ControllerUpdate_Step2

SeMenu_ControllerUpdate_Step1:
	ld a, (xsp + 6)
	extz wa
	ld c, 0x0:opc
	addb_erp C, 0xfb
	pushw 0x26
	ld de, 1:i3
	call SeMenu_RegisterElement_Type1
	inc1b_erp 0xfb
	cpib_erp 0xfb, 3
	jr c, SeMenu_ControllerUpdate_Step1
	jr SeMenu_ControllerUpdate_Step3

SeMenu_ControllerUpdate_Step2:
	ld a, (xsp + 8)
	extz wa
	ld c, 0x0:opc
	addb_erp C, 0xfb
	pushw 0x26
	ld de, 1:i3
	call SeMenu_RegisterElement_Type2
	inc1b_erp 0xfb
	cpib_erp 0xfb, 3
	jr c, SeMenu_ControllerUpdate_Step2

SeMenu_ControllerUpdate_Step3:
	ld wa, 1:i3
	call SeMenu_SetCurrentStep
	call SeMenu_AdvanceSubIndex
	ld wa, 0:i3
	ld bc, 1:i3
	call SeMenu_StorePartParam
	jrl SeMenu_ControllerData_End

SeMenu_ControllerUpdate_StoreValue:
	lda xwa, (xsp + 4)
	cp (xsp + 42), 0x1
	jr nz, SeMenu_ControllerUpdate_End
	call SeMenu_ReadObjParam
	lda xwa, (xsp + 10)
	call SeMenu_FillEntryTable
	ld a, (xsp + 4)
	extz wa
	ld c, (xsp + 10)
	extz bc
	call SeMenu_StorePartParam
	call SeMenu_AdvanceSubIndex
	cp l, 3:i3
	jrl ule, SeMenu_ControllerData_End
	call SeMenu_ResetSubIndex
	call SeMenu_AdvanceSubIndex
	lda xwa, (xsp + 4)
	call SeMenu_ReadObjParam
	ld a, (xsp + 8)
	extz wa
	ld c, (xsp + 4)
	extz bc
	ldw de, 0x26
	call SeMenu_InitDisplayField_Alt
	ld wa, 2:i3
	jr SeMenu_ControllerData_Offset3

SeMenu_ControllerUpdate_End:
	cp (xsp + 42), 0x2
	jr nz, SeMenu_ControllerData_Offset4
	call SeMenu_ReadObjParam
	ld a, (xsp + 4)
	extz wa
	call SeMenu_ApplySynthParam_Alt
	call SeMenu_AdvanceSubIndex
	cp l, 4:i3
	jr ugt, SeMenu_ControllerData
	lda xwa, (xsp + 4)
	call SeMenu_ReadObjParam
	ld a, (xsp + 8)
	extz wa
	ld c, (xsp + 4)
	extz bc
	ldw de, 0x26
	call SeMenu_InitDisplayField_Alt
	jr SeMenu_ControllerData_End

SeMenu_ControllerData:
	cp (xsp + 2), 0x0
	jr nz, SeMenu_ControllerData_Offset1
	ld wa, 1:i3
	ldw bc, 0x26
	jr SeMenu_ControllerData_Offset2

SeMenu_ControllerData_Offset1:
	ld wa, 4:i3
	ldw bc, 0x26

SeMenu_ControllerData_Offset2:
	call SeMenu_InitDisplayColumn
	ld wa, 3:i3

SeMenu_ControllerData_Offset3:
	call SeMenu_SetCurrentStep
	jr SeMenu_ControllerData_End

SeMenu_ControllerData_Offset4:
	cp (xsp + 2), 0x0
	jr nz, SeMenu_ControllerData_Offset5
	ld xwa, 1:i3
	jr SeMenu_ControllerData_Offset6

SeMenu_ControllerData_Offset5:
	ld xwa, 4:i3

SeMenu_ControllerData_Offset6:
	call SeMenu_ProcessEffect
	calr SeMenu_CopyWriteUpdate
	pushw 0x26
	call SeMenu_ShowPopupDialog
	inc 2, xsp
	ld wa, 1:i3
	call SeMenu_SetupMenuDisplay
	ld wa, 0:i3
	call SeMenu_SetCurrentStep
	call SeMenu_ResetSubIndex

SeMenu_ControllerData_End:
	popw_erp 0xfa
	lda xsp, (xsp + 42)
	ret

SeMenu_CopyWriteUpdate:
	dec 2, xsp
	lda xbc, (xsp)
	ld wa, 1:i3
	call SeMenu_LoadPartParam
	cp (xsp), 0x7f
	jr nz, SeMenu_CopyWriteUpdate_Step1
	ld wa, 4:i3
	ld bc, 0:i3
	call SeMenu_StorePartParam
	ld wa, 5:i3
	ld bc, 0:i3
	call SeMenu_StorePartParam
	ld wa, 6:i3
	ld bc, 0:i3
	jr SeMenu_CopyWriteUpdate_End

SeMenu_CopyWriteUpdate_Step1:
	ld c, (xsp)
	inc 1, c
	extz bc
	ld wa, 4:i3
	call SeMenu_StorePartParam
	lda xbc, (xsp)
	ld wa, 2:i3
	call SeMenu_LoadPartParam
	cp (xsp), 0x7f
	jr nz, SeMenu_CopyWriteUpdate_Step2
	ld wa, 5:i3
	ld bc, 0:i3
	call SeMenu_StorePartParam
	ld wa, 6:i3
	ld bc, 0:i3
	jr SeMenu_CopyWriteUpdate_End

SeMenu_CopyWriteUpdate_Step2:
	ld c, (xsp)
	inc 1, c
	extz bc
	ld wa, 5:i3
	call SeMenu_StorePartParam
	lda xbc, (xsp)
	ld wa, 3:i3
	call SeMenu_LoadPartParam
	cp (xsp), 0x7f
	jr nz, SeMenu_CopyWriteUpdate_Step3
	ld wa, 6:i3
	ld bc, 0:i3
	jr SeMenu_CopyWriteUpdate_End

SeMenu_CopyWriteUpdate_Step3:
	ld c, (xsp)
	inc 1, c
	extz bc
	ld wa, 6:i3
	call SeMenu_StorePartParam
	ld wa, 7:i3
	ldw bc, 0x7f

SeMenu_CopyWriteUpdate_End:
	call SeMenu_StorePartParam
	inc 2, xsp
	ret

SeMenu_CopyWriteUpdate_Data:
	lda	xsp, (xsp-24)
	.byte 0xd7
	swi	2
	.byte 0x04
	lda	xwa, (xsp+2)
	call	SeMenu_HandleMenuChange_Data
	.byte 0x8f
	push	sr
	push	xsp
	normal
	jr	nz, 15
	ld	wa, 2:i3
	call	SeMenu_ClearNotification
	ld	wa, 0:i3
	call	SeMenu_HandleMenuChange_Data_0x5
	jrl	209
	lda	xwa, (xsp+24)
	call	SeMenu_ReadObjData
	.byte 0x8f
	push_f
	push	xsp
	nop
	jr	nz, 23
	pushw	62
	ld	wa, 0:i3
	ld	bc, 0:i3
	ldw	de, 16
	call	SeMenu_RegisterElement_Type1
	ld	wa, 1:i3
	call	SeMenu_SetCurrentStep
	jrl	173
	lda	xwa, (xsp+6)
	call	SeMenu_FillEntryTable
	ldib_erp 251, 0
	stb_erp a, 251
	extz	wa
	lda	xbc, (xsp+6)
	lda_rr xbc, xbc, wa
	ld xwa, xbc
	call	FontGlyph_ByteData_0x11
	inc1b_erp 251
	cp_erpb 251, 16
	jr	c, -28
	lda	xbc, (xsp+6)
	ld	wa, 1:i3
	ldw	de, 16
	call	SeMenu_SetupPartDisplay
	lda	xwa, (xsp+4)
	call	SeMenu_SetupPartDisplay_End_0xE8
	lda	xde, (xsp+6)
	ld	a, (xsp+4)
	extz	wa
	extz	xwa
	div	wa, 20
	ld	(xde), a
	lda	xbc, (xde+1)
	ld	a, (xsp+4)
	extz	wa
	extz	xwa
	div	wa, 20
	ld wa, qwa
	ld (xbc), a
	incm8 1, (xde)
	incm8 1, (xbc)
	ld c, (xde)
	extz bc
	ld	wa, 0:i3
	call	SeMenu_StorePartParam
	ld	c, (xsp+7)
	extz	bc
	ld	wa, 1:i3
	call	SeMenu_StorePartParam
	pushw	62
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	ld	wa, 1:i3
	call	SeMenu_SetupPartDisplay_End_0x1DA
	ld	wa, 0:i3
	ldw	bc, 11
	ld	de, 0:i3
	call	SeMenu_SetupPartDisplay_End_0x1E0
	ld	wa, 1:i3
	ldw	bc, 12
	ld	de, 0:i3
	call	SeMenu_SetupPartDisplay_End_0x1E0
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	ldw	wa, 30
	ld	bc, 0:i3
	call	SeMenu_StorePartParam
	call	SeMenu_ResetSubIndex
	pop qiz
	lda	xsp, (xsp+24)
	ret
	dec	2, xsp
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	ld	a, 13:opc
	.byte 0x87
	push	xsp
	normal
	jr	z, 2
	ld	a, 16:opc
	extz	wa
	call	SeMenu_CopyWriteUpdate_Data_0x292E
	inc	2, xsp
	ret
	lda	xsp, (xsp-10)
	.byte 0xd7
	swi	2
	.byte 0x04
	lda	xwa, (xsp+10)
	call	SeMenu_ReadObjData
	.byte 0x8f
	ldw	(63:8), 0x6e00:io
	pushw	de
	ld	wa, 1:i3
	call	SeMenu_SetDisplayState
	ldib_erp 251, 0
	ld	c, 93:opc
	addb_erp c, 251
	pushw	58
	ld	wa, 0:i3
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 251
	cp_erpb 251, 9
	jr c, -25
	ld	wa, 1:i3
	call	SeMenu_SetCurrentStep
	jr	97
	lda	xwa, (xsp+4)
	call	SeMenu_ReadObjParam
	lda	xwa, (xsp+6)
	call	SeMenu_FillEntryTable
	ld	a, (xsp+4)
	extz	wa
	ld	c, (xsp+6)
	extz	bc
	call	SeMenu_StorePartParam
	call	SeMenu_AdvanceSubIndex
	cp	l, 8
	jr	ule, 60
	lda	xbc, (xsp+2)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+2)
	and	a, 15
	cp	a, 11
	jr	ule, 15
	.byte 0x8f
	push	sr
	push	xix
	stiw_d8 143, 35, 217
	ccf
	ld	wa, 0:i3
	call	SeMenu_StorePartParam
	pushw	58
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_ResetSubIndex
	ld	wa, 0:i3
	call	SeMenu_SetDisplayState
	pop qiz
	lda	xsp, (xsp+10)
	ret
	lda	xsp, (xsp-20)
	lda	xwa, (xsp+18)
	call	SeMenu_ReadObjData
	.byte 0x8f
	ccf
	push	xsp
	nop
	jr	nz, 18
	pushw	61
	ld	wa, 0:i3
	ld	bc, 0:i3
	ldw	de, 13
	call	SeMenu_RegisterElement_Type2
	ld	wa, 1:i3
	jr	47
	lda	xwa, (xsp)
	call	SeMenu_FillEntryTable
	lda	xbc, (xsp)
	ld	xwa, xbc
	lda	xde, (xbc+13)
	.byte 0x80
	push	xsp
	jrl	nc, 867
	ld	(xwa), 32
	inc	1, xwa
	cp	xwa, xde
	jr	c, -14
	ld	wa, 1:i3
	ldw	de, 13
	call	SeMenu_SetupPartDisplay
	pushw	61
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	lda	xsp, (xsp+20)
	ret
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
	ret
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
	ret
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
	ret
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
	ret
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
	ret
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
	ret
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
	ret
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
	ret
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
	ret
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
	ret
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
	ret
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
	ret
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
	ret
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
	ret
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
	ret
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
	ret
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
	ret
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
	ret
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
	ret
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
	ret
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
	ret
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
	ret
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
	ret
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
	ret
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
	ret
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
	ret
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
	ret
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
	ret
	ret
	ret
	ret
	ret
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
	ret
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
	ret
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeMenu_SetupPartDisplay_End_0x90
	cp	hl, 0xffff
	jr	z, 25
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (GUI_DisplayStructData_0x136F:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeMenu_SetupPartDisplay_End_0x90
	cp	hl, 0xffff
	jr	z, 25
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (GUI_DisplayStructData_0x13B7:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	inc	4, xsp
	ret
	extz	wa
	ld	bc, 2:i3
	jp	SeMenu_ApplyPartEdit_Data2_0x948
	extz	wa
	jp	SeMenu_ApplyPartEdit_Data2_0xA1D
	ld	c, a
	extz	bc
	ld	wa, 1:i3
	jp	SeMenu_ApplyPartEdit_Data2_0xA49
	ld	c, a
	extz	bc
	ld	wa, 2:i3
	jp	SeMenu_ApplyPartEdit_Data2_0xA49
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x87
	push	xsp
	normal
	jr	z, 11
	ld	c, (xsp+2)
	extz	bc
	ld	wa, 3:i3
	call	SeMenu_ApplyPartEdit_Data2_0xA49
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x87
	push	xsp
	normal
	jr	z, 11
	ld	c, (xsp+2)
	extz	bc
	ld	wa, 4:i3
	call	SeMenu_ApplyPartEdit_Data2_0xA49
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xbc, (xsp)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, 9
	.byte 0x87
	push	xsp
	push	sr
	jr	z, 24
	ld	wa, 2:i3
	jr	7
	.byte 0x87
	push	xsp
	normal
	jr	z, 15
	ld	wa, 1:i3
	call	SeMenu_TransferPartValues_EndData_0x9E
	ldw	wa, 59
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xbc, (xsp)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, 9
	.byte 0x87
	push	xsp
	.byte 0x06
	jr	z, 24
	ld	wa, 6:i3
	jr	7
	.byte 0x87
	push	xsp
	halt
	jr	z, 15
	ld	wa, 5:i3
	call	SeMenu_TransferPartValues_EndData_0x9E
	ldw	wa, 59
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x87
	push	xsp
	normal
	jr	z, 15
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, 9
	ldw	wa, 60
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, 21
	.byte 0x87
	push	xsp
	nop
	jr	nz, 7
	ldw	wa, 32
	ld	bc, 0:i3
	jr	5
	ldw	wa, 61
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	lda	xsp, (xsp-14)
	ld	(xsp+12), a
	lda	xbc, (xsp)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 1
	ld	(xbc+7), 4
	ld	(xbc+8), 1
	ld	(xbc+9), 0
	ld	a, (xsp+12)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	pushw	16
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 60
	ld	bc, 0:i3
	ld	de, 0:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	ld	wa, 3:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+14)
	ret
	lda	xsp, (xsp-14)
	ld	(xsp+12), a
	lda	xbc, (xsp)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 1
	ld	(xbc+7), 5
	ld	(xbc+8), 1
	ld	(xbc+9), 0
	ld	a, (xsp+12)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	pushw	16
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 60
	ld	bc, 0:i3
	ld	de, 0:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	ld	wa, 6:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+14)
	ret
	cp	a, 0:i3
	ret	z
	ldw	wa, 59
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	nz
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
	lda	xsp, (xsp-12)
	pushw	iz
	ld	(xsp+12), bc
	ld	iz, wa
	lda	xwa, (xsp+6)
	call	SeMenu_LoadPatchStatus
	.byte 0x8f, 0x06
	push	xsp
	nop
	jr	nz, 13
	lda	xwa, (xsp+2)
	call	SeMenu_DisplayState_Data
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, 80
	lda	xde, (xsp+10)
	lda	xwa, (xsp+8)
	push	xwa
	ld	wa, iz
	ld	bc, (xsp+16)
	call	SeMenu_SetupPartDisplay_End_0x90
	cp	hl, 0xffff
	jr	z, 58
	call	SeMenu_OrPartConfig_Data_0x6
	cp	l, 0:i3
	jr	z, 15
	lda	xwa, (xsp+4)
	call	SeMenu_DisplayState_Data_0xA
	ld	a, (xsp+10)
	.byte 0x8f, 0x04, 0xf1
	jr	nz, 35
	ld	a, (xsp+10)
	extz	wa
	call	SeMenu_DisplayState_Data_0x5
	ld	a, (xsp+8)
	extz	wa
	ld	c, (xsp+10)
	extz	bc
	sla	bc, 2
	lda	xde, (GUI_DisplayStructData_0x13FF:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	popw	iz
	lda	xsp, (xsp+12)
	ret
	dec	6, xsp
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+6), a
	lda	xwa, (xsp+2)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	z, 81
	lda	xwa, (xsp+2)
	call	SeMenu_LoadPatchStatus
	.byte 0x8f
	push	sr
	push	xsp
	normal
	jr	z, 68
	ld	a, (xsp+6)
	res	7, a
	ldb_erp a, 251
	lda	xbc, (xsp+4)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+4)
	extz	wa
	call	SeMenu_IsPartEnabled
	ld	a, (xsp+4)
	extz	wa
	cp	hl, 0:i3
	jr	z, 9
	cpib_erp 251, 0
	jr z, 27
	ld bc, 0:i3
	jr 7
	cpib_erp 251, 0
	jr nz, 18
	ld	bc, 1:i3
	call	SeMenu_PartMask_Data_0x5
	pushw	2
	pushw	32
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	pop qiz
	inc	6, xsp
	ret
	lda	xsp, (xsp-12)
	ld	(xsp+10), a
	lda	xwa, (xsp+6)
	call	SeMenu_LoadObjEntries
	.byte 0x8f, 0x06
	push	xsp
	nop
	jr	z, 117
	lda	xwa, (xsp+6)
	call	SeMenu_LoadPatchStatus
	.byte 0x8f, 0x06
	push	xsp
	normal
	jr	z, 104
	lda	xbc, (xsp)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	c, (xsp)
	extz	bc
	lda	xde, (xsp+4)
	ld	wa, 3:i3
	call	SeMenu_ApplySynthParam_Data_0x53
	lda	xwa, (xsp+2)
	call	SeMenu_ApplyPartEdit_Data2_0x1C84
	ld	a, (xsp+10)
	res	7, a
	cp	a, 0:i3
	jr	nz, 15
	ld	a, (xsp+2)
	dec	1, a
	cp	(xsp+4), a
	jr	nc, 56
	incm8	1, (xsp+4)
	jr	9
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	z, 45
	decm8	1, (xsp+4)
	ld	c, (xsp+4)
	extz	bc
	lda	xde, (xsp+8)
	ld	wa, 3:i3
	call	SeMenu_ApplySynthParam_Data
	ld	a, (xsp)
	extz	wa
	ld	bc, (xsp+8)
	call	SeMenu_RegisterParamDisplay_Data
	ld	a, (xsp)
	extz	wa
	ldw	bc, 16
	call	SeMenu_InitDisplayField
	ld	wa, 2:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+12)
	ret
	lda	xsp, (xsp-10)
	ld	(xsp+8), a
	lda	xwa, (xsp+6)
	call	SeMenu_LoadObjEntries
	.byte 0x8f, 0x06
	push	xsp
	nop
	jr	z, 104
	lda	xwa, (xsp+6)
	call	SeMenu_LoadPatchStatus
	.byte 0x8f, 0x06
	push	xsp
	normal
	jr	z, 91
	lda	xbc, (xsp+4)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+4)
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_ApplyPartEdit_Data2_0x1C63
	lda	xwa, (xsp)
	call	SeMenu_ApplyPartEdit_Data2_0x1C7A
	ld	a, (xsp+8)
	res	7, a
	cp	a, 0:i3
	jr	nz, 14
	ld	wa, (xsp)
	dec	1, wa
	cp	(xsp+2), wa
	jr	nc, 45
	incw	1, (xsp+2)
	jr	10
	cpw	(xsp+2), 0
	jr	z, 33
	decm	1, (xsp+2)
	ld	a, (xsp+4)
	extz	wa
	ld	bc, (xsp+2)
	call	SeMenu_RegisterParamDisplay_Data
	ld	a, (xsp+4)
	extz	wa
	ldw	bc, 16
	call	SeMenu_InitDisplayField
	ld	wa, 3:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+10)
	ret
	lda	xsp, (xsp-18)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+18), a
	lda	xwa, (xsp+14)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	ret
	push	xsp
	nop
	jrl	z, 133
	lda	xwa, (xsp+14)
	call	SeMenu_LoadPatchStatus
	.byte 0x8f
	ret
	push	xsp
	normal
	jr	z, 120
	lda	xbc, (xsp+16)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+16)
	inc	2, a
	ldb_erp a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+2)
	ld	(xbc+6), 127
	ld	(xbc+7), 0
	ld	(xbc+8), 127
	ld	(xbc+9), 0
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	stb_erp c, 251
	extz	bc
	ld	a, (xsp+16)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	inc	5, xwa
	extz	wa
	pushw	wa
	.byte 0xbf, 0x04
	.asciz "080 "
	ld	de, 0:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	cp	l, 1:i3
	jr	nz, 14
	ld	a, (xsp+16)
	extz	wa
	ld	c, (xsp+5)
	extz	bc
	call	SeMenu_StoreParamByte
	ld	wa, 4:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	pop qiz
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-18)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+18), a
	lda	xwa, (xsp+14)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	ret
	push	xsp
	nop
	jr	z, 115
	lda	xwa, (xsp+14)
	call	SeMenu_LoadPatchStatus
	.byte 0x8f
	ret
	push	xsp
	normal
	jr	z, 102
	lda	xbc, (xsp+16)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+16)
	inc	4, a
	ldb_erp a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+2)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	stb_erp c, 251
	extz	bc
	ld	a, (xsp+16)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	inc	3, xwa
	extz	wa
	pushw	wa
	.byte 0xbf, 0x04
	.asciz "080 "
	ld	de, 0:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	ld	wa, 5:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	pop qiz
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-18)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+18), a
	lda	xwa, (xsp+14)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	ret
	push	xsp
	nop
	jr	z, 115
	lda	xwa, (xsp+14)
	call	SeMenu_LoadPatchStatus
	.byte 0x8f
	ret
	push	xsp
	normal
	jr	z, 102
	lda	xbc, (xsp+16)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+16)
	inc	6, a
	ldb_erp a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+2)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	stb_erp c, 251
	extz	bc
	ld	a, (xsp+16)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	inc	4, xwa
	extz	wa
	pushw	wa
	.byte 0xbf, 0x04
	.asciz "080 "
	ld	de, 0:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	ld	wa, 6:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	pop qiz
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-10)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+10), a
	lda	xwa, (xsp+4)
	call	SeMenu_LoadObjEntries
	.byte 0x8f, 0x04
	push	xsp
	nop
	jrl	z, 199
	lda	xwa, (xsp+4)
	call	SeMenu_LoadPatchStatus
	.byte 0x8f, 0x04
	push	xsp
	normal
	jrl	z, 185
	lda	xbc, (xsp+8)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+8)
	inc	8, a
	ldb_erp a, 250
	ld	a, (xsp+10)
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_SetupPartDisplay_End_0x219
	ld	a, (xsp+10)
	res	7, a
	ldb_erp a, 251
	stb_erp a, 250
	extz	wa
	lda	xbc, (xsp+6)
	call	SeMenu_LoadPartParam
	.byte 0xbf, 0x06, 0xb7, 0xc7
	swi	3
	dec	6, wa
	push_f
	.byte 0x8f, 0x06
	push	xsp
	jrl	nc, 31087
	ld	a, (xsp+2)
	add	(xsp+6), a
	.byte 0x8f, 0x06
	push	xsp
	jrl	nc, 7527
	ld	(xsp+6), 127
	jr	23
	.byte 0x8f, 0x06
	push	xsp
	nop
	jr	z, 97
	ld	a, (xsp+6)
	.byte 0x8f
	push	sr
	.byte 0x81
	ld	(xsp+6), a
	cp	a, 0:i3
	jr	ge, 4
	ld	(xsp+6), 0
	stb_erp a, 250
	extz	wa
	ld	c, (xsp+6)
	extz	bc
	call	SeMenu_StorePartParam
	ld	a, (xsp+8)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	ld	c, a
	lda	xde, (xsp+6)
	pushw	127
	ld	wa, 0:i3
	call	SeMenu_SetupDisplayObject_Alt1
	ld	a, (xsp+8)
	extz	wa
	call	SeMenu_ApplyPartEdit
	ld	a, (xsp+8)
	add	a, 12
	ldb_erp a, 250
	extz	wa
	pushw	wa
	pushw	32
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	ld	wa, 7:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	pop qiz
	lda	xsp, (xsp+10)
	ret
	lda	xsp, (xsp-16)
	ld	(xsp+14), a
	lda	xwa, (xsp+12)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	incf
	push	xsp
	nop
	jr	z, 78
	lda	xwa, (xsp+12)
	call	SeMenu_LoadPatchStatus
	cp	(xsp+12), 1
	jr	z, 65
	lda	xbc, (xsp)
	ldw	wa, 11
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 127
	ld	(xbc+7), 0
	ld	(xbc+8), 127
	ld	(xbc+9), 0
	ld	a, (xsp+14)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	pushw	15
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 32
	ldw	bc, 11
	ld	de, 0:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	ldw	wa, 8
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+16)
	ret
	lda	xsp, (xsp-10)
	ld	(xsp+8), a
	lda	xwa, (xsp+2)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, 51
	.byte 0x8f
	ld	(63:8), 0:io
	jr	nz, 28
	lda	xbc, (xsp)
	ld	wa, 1:i3
	call	SeMenu_LoadPartParam
	.byte 0x87
	push	xsp
	nop
	scc8	z, a
	extz	wa
	call	SeMenu_SetupDisplayObject_Alt2_Continue_0x21
	ldw	wa, 16
	call	SeMenu_RegisterParamDisplay
	jr	83
	ld	wa, 0:i3
	call	SeMenu_HandleMenuChange_Data_0x5
	ldw	wa, 62
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	jr	66
	lda	xwa, (xsp+2)
	call	SeMenu_LoadPatchStatus
	.byte 0x8f
	push	sr
	push	xsp
	normal
	jr	z, 53
	.byte 0x8f
	ld	(63:8), 0:io
	jr	nz, 47
	lda	xwa, (xsp+6)
	call	SeMenu_SetMode_Data_0x5
	lda	xwa, (xsp+4)
	call	SeMenu_SetMode_Data_0xF
	ld	wa, (xsp+4)
	dec	1, wa
	cp	(xsp+6), wa
	jr	nc, 23
	incw	1, (xsp+6)
	ld	wa, (xsp+6)
	call	SeMenu_SetupDisplayObject_Data
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	call	SeMenu_OrPartConfig_Data
	lda	xsp, (xsp+10)
	ret
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x87
	push	xsp
	nop
	jr	nz, 20
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	nz, 7
	ldw	wa, 33
	ld	bc, 0:i3
	jr	35
	ldw	wa, 34
	ld	bc, 0:i3
	jr	28
	lda	xwa, (xsp)
	call	SeMenu_LoadPatchStatus
	.byte 0x87
	push	xsp
	normal
	jr	nz, 23
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	nz, 15
	ld	wa, 0:i3
	call	SeMenu_SetPatchBank
	ldw	wa, 32
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	jr	43
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	nz, 37
	lda	xwa, (xsp+2)
	call	SeMenu_SetMode_Data_0x5
	cpw	(xsp+2), 0
	jr	z, 23
	decm	1, (xsp+2)
	ld	wa, (xsp+2)
	call	SeMenu_SetupDisplayObject_Data
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	call	SeMenu_OrPartConfig_Data
	inc	6, xsp
	ret
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp+2)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, 24
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	nz, 7
	ldw	wa, 36
	ld	bc, 0:i3
	jr	5
	ldw	wa, 43
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	jr	84
	lda	xwa, (xsp+2)
	call	SeMenu_LoadPatchStatus
	.byte 0x8f
	push	sr
	push	xsp
	normal
	jr	nz, 26
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	nz, 18
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	ld	wa, 0:i3
	call	SeMenu_SetPatchBank
	ld	wa, 2:i3
	call	SeMenu_ClearNotification
	jr	45
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	z, 39
	lda	xbc, (xsp)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	.byte 0x87
	push	xsp
	normal
	jr	z, 26
	ld	wa, 0:i3
	ld	bc, 1:i3
	call	SeMenu_StorePartParam
	ld	wa, 1:i3
	call	SeMenu_SetupMenuDisplay_Finalize_Data
	pushw	0
	pushw	32
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	inc	6, xsp
	ret
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp+2)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, 24
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	nz, 7
	ldw	wa, 58
	ld	bc, 0:i3
	jr	5
	ldw	wa, 39
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	jr	58
	lda	xwa, (xsp+2)
	call	SeMenu_LoadPatchStatus
	.byte 0x8f
	push	sr
	push	xsp
	normal
	jr	z, 45
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	z, 39
	lda	xbc, (xsp)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	.byte 0x87
	push	xsp
	push	sr
	jr	z, 26
	ld	wa, 0:i3
	ld	bc, 2:i3
	call	SeMenu_StorePartParam
	ld	wa, 2:i3
	call	SeMenu_SetupMenuDisplay_Finalize_Data
	pushw	0
	pushw	32
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	inc	6, xsp
	ret
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp+2)
	call	SeMenu_LoadObjEntries
	lda	xwa, (xsp+2)
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	nz, 32
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, 7
	ldw	wa, 59
	ld	bc, 0:i3
	jr	30
	call	SeMenu_LoadPatchStatus
	.byte 0x8f
	push	sr
	push	xsp
	normal
	.asciz "fi0="
	call	SeMenu_SetupPartDisplay_End_0x26E
	jr	96
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, 11
	ldw	wa, 48
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	jr	79
	call	SeMenu_LoadPatchStatus
	.byte 0x8f
	push	sr
	push	xsp
	normal
	jr	z, 69
	call	SeMenu_OrPartConfig_Data_0x6
	cp	l, 0:i3
	jr	nz, 61
	lda	xwa, (xsp)
	call	SeMenu_LoadMasterPtr
	ld	a, (xsp)
	extz	wa
	ld	bc, 0:i3
	ld	de, 1:i3
	call	SndParam_UpdateChannelTuning
	cp	l, 255
	jr	nz, 17
	ld	a, (xsp)
	extz	wa
	ld	bc, 1:i3
	ld	de, 1:i3
	call	SndParam_UpdateChannelTuning
	cp	l, 255
	jr	z, 21
	ld	wa, 1:i3
	call	SeMenu_SetFilterMode
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	inc	6, xsp
	ret
	cp	a, 0:i3
	ret	nz
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	ld	wa, 0:i3
	call	SeMenu_SetPatchBank
	ld	wa, 2:i3
	call	SeMenu_ClearNotification
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeMenu_SetupPartDisplay_End_0x90
	cp	hl, 0xffff
	jr	z, 25
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (ToneGen_ParamTable_0x1E:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeMenu_SetupPartDisplay_End_0x90
	cp	hl, 0xffff
	jr	z, 25
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (ToneGen_ParamTable_0x66:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeMenu_SetupPartDisplay_End_0x90
	cp	hl, 0xffff
	jr	z, 25
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (ToneGen_ParamTable_0xAE:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeMenu_SetupPartDisplay_End_0x90
	cp	hl, 0xffff
	jr	z, 25
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (ToneGen_ParamTable_0xF6:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeMenu_SetupPartDisplay_End_0x90
	cp	hl, 0xffff
	jr	z, 25
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (ToneGen_ParamTable_0x13E:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	inc	4, xsp
	ret
	dec	4, xsp
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+4), a
	lda	xbc, (xsp+2)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+4)
	res	7, a
	ldb_erp a, 251
	ld	a, (xsp+2)
	extz	wa
	call	SeMenu_IsPartEnabled
	ld	a, (xsp+2)
	extz	wa
	cp	hl, 0:i3
	jr	z, 9
	cpib_erp 251, 0
	jr z, 33
	ld bc, 0:i3
	jr	7
	cpib_erp 251, 0
	jr nz, 24
	ld	bc, 1:i3
	call	SeMenu_PartMask_Data_0x5
	pushw	1
	pushw	34
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	ld	wa, 1:i3
	call	SeMenu_SetupMenuDisplay
	pop qiz
	inc	4, xsp
	ret
	lda	xsp, (xsp-10)
	ld	(xsp+8), a
	lda	xbc, (xsp+2)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	c, (xsp+2)
	extz	bc
	lda	xde, (xsp+6)
	ld	wa, 0:i3
	call	SeMenu_ApplySynthParam_Data_0x53
	lda	xwa, (xsp+4)
	call	SeMenu_ApplyPartEdit_Data2_0x1C84
	ld	a, (xsp+8)
	res	7, a
	cp	a, 0:i3
	jr	nz, 15
	ld	a, (xsp+4)
	dec	1, a
	cp	(xsp+6), a
	jr	nc, 56
	incm8	1, (xsp+6)
	jr	9
	.byte 0x8f, 0x06
	push	xsp
	nop
	jr	z, 45
	decm8	1, (xsp+6)
	ld	c, (xsp+6)
	extz	bc
	lda	xde, (xsp)
	ld	wa, 0:i3
	call	SeMenu_ApplySynthParam_Data
	ld	a, (xsp+2)
	extz	wa
	ld	bc, (xsp)
	call	SeMenu_RegisterParamDisplay_Data
	ld	a, (xsp+2)
	extz	wa
	ldw	bc, 16
	call	SeMenu_InitDisplayField
	ld	wa, 2:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+10)
	ret
	dec	8, xsp
	ld	(xsp+6), a
	lda	xbc, (xsp+4)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+4)
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_ApplyPartEdit_Data2_0x1C63
	lda	xwa, (xsp)
	call	SeMenu_ApplyPartEdit_Data2_0x1C7A
	ld	a, (xsp+6)
	res	7, a
	cp	a, 0:i3
	jr	nz, 14
	ld	wa, (xsp)
	dec	1, wa
	cp	(xsp+2), wa
	jr	nc, 45
	incw	1, (xsp+2)
	jr	10
	cpw	(xsp+2), 0
	jr	z, 33
	decm	1, (xsp+2)
	ld	a, (xsp+4)
	extz	wa
	ld	bc, (xsp+2)
	call	SeMenu_RegisterParamDisplay_Data
	ld	a, (xsp+4)
	extz	wa
	ldw	bc, 16
	call	SeMenu_InitDisplayField
	ld	wa, 3:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	inc	8, xsp
	ret
	lda	xsp, (xsp-16)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+16), a
	lda	xbc, (xsp+14)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+14)
	mul	a, 3
	ldb_erp a, 251
	dec1b_erp 251
	stb_erp a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+2)
	ld	(xbc+6), 127
	ld	(xbc+7), 0
	ld	(xbc+8), 127
	ld	(xbc+9), 0
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	stb_erp c, 251
	extz	bc
	ld	e, (xsp+14)
	extz	de
	pushw	23
	.byte 0xbf, 0x04
	.asciz "080\""
	call	SeMenu_TransferPartValues_EndData_0x169
	cp	l, 1:i3
	jr	nz, 14
	ld	a, (xsp+14)
	extz	wa
	ld	c, (xsp+5)
	extz	bc
	call	SeMenu_StoreParamByte
	ld	wa, 6:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	pop qiz
	lda	xsp, (xsp+16)
	ret
	lda	xsp, (xsp-16)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+16), a
	lda	xbc, (xsp+14)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+14)
	mul	a, 3
	ldb_erp a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+2)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 24
	ld	(xbc+9), 232
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	stb_erp c, 251
	extz	bc
	ld	e, (xsp+14)
	extz	de
	pushw	4
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 34
	call	SeMenu_TransferPartValues_EndData_0x169
	ld	wa, 7:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	pop qiz
	lda	xsp, (xsp+16)
	ret
	lda	xsp, (xsp-16)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+16), a
	lda	xbc, (xsp+14)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+14)
	mul	a, 3
	ldb_erp a, 251
	inc1b_erp 251
	stb_erp a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+2)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	stb_erp c, 251
	extz	bc
	ld	e, (xsp+14)
	extz	de
	pushw	5
	.byte 0xbf, 0x04
	.asciz "080\""
	call	SeMenu_TransferPartValues_EndData_0x169
	ldw	wa, 8
	call	SeMenu_SetupPartDisplay_End_0x1F6
	pop qiz
	lda	xsp, (xsp+16)
	ret
	cp	a, 0:i3
	ret	z
	call	SeMenu_BitShiftMask_End_0x1A3
	ret
	cp	a, 0:i3
	ret	z
	ldw	wa, 34
	ld	bc, 1:i3
	ld	de, 0:i3
	call	SeMenu_ApplyPartEdit_Data2_0x17C1
	ret
	cp	a, 0:i3
	ret	z
	ldw	wa, 34
	ld	bc, 2:i3
	ld	de, 0:i3
	call	SeMenu_ApplyPartEdit_Data2_0x17C1
	ret
	cp	a, 0:i3
	ret	z
	ldw	wa, 34
	ld	bc, 3:i3
	ld	de, 0:i3
	call	SeMenu_ApplyPartEdit_Data2_0x17C1
	ret
	cp	a, 0:i3
	ret	z
	ldw	wa, 34
	ld	bc, 4:i3
	ld	de, 0:i3
	call	SeMenu_ApplyPartEdit_Data2_0x17C1
	ret
	cp	a, 0:i3
	ret	nz
	ldw	wa, 38
	call	SeMenu_SetupPartDisplay_End_0x26E
	ret
	cp	a, 0:i3
	ret	nz
	ldw	wa, 32
	call	SeMenu_SetupPartDisplay_End_0x26E
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	ret
	dec	8, xsp
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+8), a
	lda	xwa, (xsp+6)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp+4)
	ld	wa, 1:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+6)
	inc	1, a
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	ld	a, (xsp+4)
	extz	wa
	ld	c, (xsp+6)
	.byte 0x8f, 0x06
	and	(xhl), c
	jr	gt, -39
	ccf
	call	SeMenu_BitShiftMask_End
	.byte 0xc7
	swi	2
	cp	(xsp-57), de
	ld	d, 143
	ld	(33:8), 201:io
	ldw	wa, 0xc907
	dec	6, wa
	push_f
	.byte 0xbf
	push	sr
	scc8	nz, l
	.byte 0xab
	nop
	.byte 0xc7
	swi	2
	dec	6, bc
	ld	(191:8), 2:io
	.byte 0xbf, 0xc7
	swi	2
	.byte 0xa8
	jr	27
	inc1b_erp 250
	jr 22
	.byte 0xbf
	push	sr
	inc	6, l
	ld	(191:8), 2:io
	.byte 0xb7, 0xc7
	swi	2
	.byte 0xa9
	jr	9
	cpib_erp 250, 0
	jrl z, 134
	.byte 0xc7
	swi	2
	jr	ge, -113
	.byte 0x06
	ld	a, 143:opc
	.byte 0x06
	and	(xbc), a
	jr	gt, -55
	.byte 0x8b
	extz	bc
	ld	wa, 3:i3
	call	SeMenu_BitShiftMask
	ldb_erp l, 251
	stb_erp a, 251
	cpl	a
	and	(xsp+4), a
	stb_erp a, 250
	extz	wa
	ld	c, (xsp+6)
	.byte 0x8f, 0x06
	and	(xhl), c
	jr	gt, -39
	ccf
	call	SeMenu_BitShiftMask
	or	(xsp+4), l
	ld	a, (xsp+6)
	extz	wa
	lda	xde, (xsp+2)
	pushw	128
	ld	bc, 0:i3
	call	SeMenu_RegisterElement_Extended
	lda	xde, (xsp+4)
	stb_erp a, 251
	extz	wa
	pushw	wa
	ld	wa, 0:i3
	ldw	bc, 18
	call	SeMenu_RegisterElement_Extended
	ld	a, (xsp+6)
	inc	1, a
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	call	SeMenu_StorePartParam
	ld	c, (xsp+4)
	extz	bc
	ld	wa, 1:i3
	call	SeMenu_StorePartParam
	pushw	1
	pushw	35
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	ld	wa, 2:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	pop qiz
	inc	8, xsp
	ret
	lda	xsp, (xsp-16)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+16), a
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	ld	a, (xsp+14)
	inc	1, a
	ldb_erp a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+2)
	ld	(xbc+6), 63
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 0
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	stb_erp c, 251
	extz	bc
	ld	e, (xsp+14)
	extz	de
	pushw	0
	.byte 0xbf, 0x04
	.asciz "080#"
	call	SeMenu_TransferPartValues_EndData_0x169
	ld	wa, 4:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	pop qiz
	lda	xsp, (xsp+16)
	ret
	lda	xsp, (xsp-10)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+10), a
	lda	xwa, (xsp+8)
	call	SeMenu_ValidatePartNumber
	ld	a, (xsp+8)
	inc	5, a
	ld	(xsp+2), a
	ld	a, (xsp+10)
	extz	wa
	lda	xbc, (xsp+4)
	call	SeMenu_SetupPartDisplay_End_0x219
	ld	a, (xsp+10)
	res	7, a
	ldb_erp a, 251
	ld	a, (xsp+2)
	extz	wa
	lda	xbc, (xsp+6)
	call	SeMenu_LoadPartParam
	.byte 0xbf, 0x06, 0xb7, 0xc7
	swi	3
	dec	6, wa
	push_f
	.byte 0x8f, 0x06
	push	xsp
	jrl	nc, 27759
	ld	a, (xsp+4)
	add	(xsp+6), a
	.byte 0x8f, 0x06
	push	xsp
	jrl	nc, 7527
	ld	(xsp+6), 127
	jr	23
	.byte 0x8f, 0x06
	push	xsp
	nop
	jr	z, 84
	ld	a, (xsp+6)
	.byte 0x8f, 0x04, 0x81
	ld	(xsp+6), a
	cp	a, 0:i3
	jr	ge, 4
	ld	(xsp+6), 0
	ld	a, (xsp+2)
	extz	wa
	ld	c, (xsp+6)
	extz	bc
	call	SeMenu_StorePartParam
	ld	a, (xsp+8)
	extz	wa
	lda	xde, (xsp+6)
	pushw	127
	ld	bc, 1:i3
	call	SeMenu_RegisterElement_Extended
	ld	a, (xsp+8)
	extz	wa
	call	SeMenu_ApplyPartEdit
	ld	a, (xsp+8)
	add	a, 11
	ld	(xsp+2), a
	extz	wa
	pushw	wa
	pushw	35
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	ld	wa, 6:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	pop qiz
	lda	xsp, (xsp+10)
	ret
	lda	xsp, (xsp-14)
	ld	(xsp+12), a
	lda	xbc, (xsp)
	ldw	wa, 10
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 127
	ld	(xbc+7), 0
	ld	(xbc+8), 127
	ld	(xbc+9), 0
	ld	a, (xsp+12)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	pushw	92
	.byte 0xbf
	push	sr
	.asciz "080#"
	ldw	bc, 10
	ld	de, 0:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	ld	wa, 7:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+14)
	ret
	cp	a, 0:i3
	ret	z
	call	SeMenu_BitShiftMask_End_0x1A3
	ret
	cp	a, 0:i3
	ret	z
	ldw	wa, 35
	ld	bc, 1:i3
	ld	de, 1:i3
	call	SeMenu_ApplyPartEdit_Data2_0x17C1
	ret
	cp	a, 0:i3
	ret	z
	ldw	wa, 35
	ld	bc, 2:i3
	ld	de, 1:i3
	call	SeMenu_ApplyPartEdit_Data2_0x17C1
	ret
	cp	a, 0:i3
	ret	z
	ldw	wa, 35
	ld	bc, 3:i3
	ld	de, 1:i3
	call	SeMenu_ApplyPartEdit_Data2_0x17C1
	ret
	cp	a, 0:i3
	ret	z
	ldw	wa, 35
	ld	bc, 4:i3
	ld	de, 1:i3
	call	SeMenu_ApplyPartEdit_Data2_0x17C1
	ret
	cp	a, 0:i3
	ret	z
	ldw	wa, 38
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	nz
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
	dec	8, xsp
	ld	(xsp+6), a
	lda	xbc, (xsp+4)
	ld	wa, 1:i3
	call	SeMenu_LoadPartParam
	.byte 0xbf, 0x04, 0xb7
	ld	a, (xsp+6)
	extz	wa
	ld	c, (xsp+4)
	extz	bc
	pushw	bc
	ld	bc, 2:i3
	ld	de, 0:i3
	call	SeMenu_PatchBank_Data_0x74
	cp	l, 1:i3
	jr	nz, 57
	lda	xwa, (xsp+2)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 2:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+2)
	extz	wa
	lda	xde, (xsp)
	pushw	127
	ldw	bc, 31
	call	SeMenu_RegisterElement_Extended
	pushw	2
	pushw	36
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	ld	c, (xsp+2)
	extz	bc
	ld	wa, 0:i3
	ld	de, 1:i3
	call	SeMenu_ApplyPartEdit_Data2_0x162C
	ld	wa, 3:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	inc	8, xsp
	ret
	lda	xsp, (xsp-10)
	ld	(xsp+8), a
	lda	xbc, (xsp+6)
	ld	wa, 2:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+4)
	ld	wa, 3:i3
	call	SeMenu_LoadPartParam
	.byte 0xbf, 0x06, 0xb7, 0xbf, 0x04, 0xb7
	ld	a, (xsp+8)
	extz	wa
	ld	e, (xsp+6)
	extz	de
	ld	c, (xsp+4)
	extz	bc
	pushw	bc
	ld	bc, 1:i3
	call	SeMenu_PatchBank_Data_0x74
	cp	l, 1:i3
	jr	nz, 57
	lda	xwa, (xsp+2)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 1:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+2)
	extz	wa
	lda	xde, (xsp)
	pushw	127
	ldw	bc, 30
	call	SeMenu_RegisterElement_Extended
	pushw	1
	pushw	36
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	ld	c, (xsp+2)
	extz	bc
	ld	wa, 0:i3
	ld	de, 1:i3
	call	SeMenu_ApplyPartEdit_Data2_0x162C
	ld	wa, 4:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+10)
	ret
	lda	xsp, (xsp-10)
	ld	(xsp+8), a
	lda	xbc, (xsp+6)
	ld	wa, 1:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+4)
	ld	wa, 4:i3
	call	SeMenu_LoadPartParam
	.byte 0xbf, 0x06, 0xb7, 0xbf, 0x04, 0xb7
	ld	a, (xsp+8)
	extz	wa
	ld	e, (xsp+6)
	extz	de
	ld	c, (xsp+4)
	extz	bc
	pushw	bc
	ld	bc, 3:i3
	call	SeMenu_PatchBank_Data_0x74
	cp	l, 1:i3
	jr	nz, 57
	lda	xwa, (xsp+2)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 3:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+2)
	extz	wa
	lda	xde, (xsp)
	pushw	127
	ldw	bc, 32
	call	SeMenu_RegisterElement_Extended
	pushw	3
	pushw	36
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	ld	c, (xsp+2)
	extz	bc
	ld	wa, 0:i3
	ld	de, 1:i3
	call	SeMenu_ApplyPartEdit_Data2_0x162C
	ld	wa, 5:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+10)
	ret
	dec	8, xsp
	ld	(xsp+6), a
	lda	xbc, (xsp+4)
	ld	wa, 3:i3
	call	SeMenu_LoadPartParam
	.byte 0xbf, 0x04, 0xb7
	ld	a, (xsp+6)
	extz	wa
	ld	e, (xsp+4)
	extz	de
	pushw	127
	ld	bc, 4:i3
	call	SeMenu_PatchBank_Data_0x74
	cp	l, 1:i3
	jr	nz, 57
	lda	xwa, (xsp+2)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 4:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+2)
	extz	wa
	lda	xde, (xsp)
	pushw	127
	ldw	bc, 33
	call	SeMenu_RegisterElement_Extended
	pushw	4
	pushw	36
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	ld	c, (xsp+2)
	extz	bc
	ld	wa, 0:i3
	ld	de, 1:i3
	call	SeMenu_ApplyPartEdit_Data2_0x162C
	ld	wa, 6:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	inc	8, xsp
	ret
	cp	a, 0:i3
	ret	z
	call	SeMenu_BitShiftMask_End_0x1A3
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 1:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 36
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	jr	nz, 7
	ldw	wa, 37
	ld	bc, 0:i3
	jr	15
	ld	wa, 2:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 36
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 3:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 36
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 4:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 36
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	nz
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
	lda	xsp, (xsp-18)
	ld	(xsp+16), a
	lda	xbc, (xsp+12)
	ld	wa, 1:i3
	call	SeMenu_LoadPartParam
	.byte 0xbf
	incf
	.byte 0xb7
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 2:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 127
	ld	(xbc+7), 0
	ld	a, (xsp+12)
	ld	(xbc+8), a
	ld	(xbc+9), 0
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	ld	e, (xsp+14)
	extz	de
	pushw	35
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 37
	ld	bc, 2:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	cp	l, 1:i3
	jr	nz, 13
	ld	c, (xsp+14)
	extz	bc
	ld	wa, 1:i3
	ld	de, 1:i3
	call	SeMenu_ApplyPartEdit_Data2_0x162C
	ld	wa, 3:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+18), a
	lda	xbc, (xsp+14)
	ld	wa, 2:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+12)
	ld	wa, 3:i3
	call	SeMenu_LoadPartParam
	.byte 0xbf
	ret
	.byte 0xb7, 0xbf
	incf
	.byte 0xb7
	lda	xwa, (xsp+16)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 1:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 127
	ld	(xbc+7), 0
	ld	a, (xsp+12)
	ld	(xbc+8), a
	ld	a, (xsp+14)
	ld	(xbc+9), a
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	ld	e, (xsp+16)
	extz	de
	pushw	34
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 37
	ld	bc, 1:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	cp	l, 1:i3
	jr	nz, 13
	ld	c, (xsp+16)
	extz	bc
	ld	wa, 1:i3
	ld	de, 1:i3
	call	SeMenu_ApplyPartEdit_Data2_0x162C
	ld	wa, 4:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+18), a
	lda	xbc, (xsp+14)
	ld	wa, 1:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+12)
	ld	wa, 4:i3
	call	SeMenu_LoadPartParam
	.byte 0xbf
	ret
	.byte 0xb7, 0xbf
	incf
	.byte 0xb7
	lda	xwa, (xsp+16)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 3:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 127
	ld	(xbc+7), 0
	ld	a, (xsp+12)
	ld	(xbc+8), a
	ld	a, (xsp+14)
	ld	(xbc+9), a
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	ld	e, (xsp+16)
	extz	de
	pushw	36
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 37
	ld	bc, 3:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	cp	l, 1:i3
	jr	nz, 13
	ld	c, (xsp+16)
	extz	bc
	ld	wa, 1:i3
	ld	de, 1:i3
	call	SeMenu_ApplyPartEdit_Data2_0x162C
	ld	wa, 5:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-18)
	ld	(xsp+16), a
	lda	xbc, (xsp+12)
	ld	wa, 3:i3
	call	SeMenu_LoadPartParam
	.byte 0xbf
	incf
	.byte 0xb7
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	lda	xbc, (xsp)
	ld	wa, 4:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 127
	ld	(xbc+7), 0
	ld	(xbc+8), 127
	ld	a, (xsp+12)
	ld	(xbc+9), a
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	ld	e, (xsp+14)
	extz	de
	pushw	37
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 37
	ld	bc, 4:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	cp	l, 1:i3
	jr	nz, 13
	ld	c, (xsp+14)
	extz	bc
	ld	wa, 1:i3
	ld	de, 1:i3
	call	SeMenu_ApplyPartEdit_Data2_0x162C
	ld	wa, 6:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+18)
	ret
	cp	a, 0:i3
	ret	z
	call	SeMenu_BitShiftMask_End_0x1A3
	ret
	cp	a, 0:i3
	jr	nz, 7
	ldw	wa, 36
	ld	bc, 0:i3
	jr	15
	ld	wa, 1:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 37
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 2:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 37
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 3:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 37
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 4:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 37
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	nz
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
	dec	4, xsp
	.byte 0xd7
	swi	2
	.byte 0x04, 0xc7
	swi	3
	cp	(xbc-57), hl
	ldw	wa, 0xbf07
	.byte 0x04
	ldw	bc, 0xa8d8
	call	SeMenu_LoadPartParam
	cpib_erp 251, 0
	jr nz, 18
	.byte 0x8f, 0x04
	push	xsp
	normal
	jr	z, 62
	decm8	1, (xsp+4)
	ld	c, (xsp+4)
	extz	bc
	ld	wa, 0:i3
	jr	34
	.byte 0x8f, 0x04
	push	xsp
	max
	jr	z, 44
	ld	a, (xsp+4)
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	.byte 0x8f
	push	sr
	push	xsp
	jrl	nc, 6758
	incm8	1, (xsp+4)
	ld	c, (xsp+4)
	extz	bc
	ld	wa, 0:i3
	call	SeMenu_StorePartParam
	pushw	0
	pushw	38
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	pop qiz
	inc	4, xsp
	ret
	lda	xsp, (xsp-12)
	ld	(xsp+10), a
	lda	xbc, (xsp+2)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	lda	xwa, (xsp+4)
	call	SeMenu_ValidatePartNumber
	ld	c, (xsp+2)
	extz	bc
	lda	xde, (xsp+8)
	ld	wa, 1:i3
	call	SeMenu_ApplySynthParam_Data_0x53
	lda	xwa, (xsp+6)
	call	SeMenu_ApplyPartEdit_Data2_0x1C84
	ld	a, (xsp+10)
	res	7, a
	cp	a, 0:i3
	jr	nz, 15
	ld	a, (xsp+6)
	dec	1, a
	cp	(xsp+8), a
	jr	nc, 66
	incm8	1, (xsp+8)
	jr	9
	.byte 0x8f
	ld	(63:8), 0:io
	jr	z, 55
	decm8	1, (xsp+8)
	ld	c, (xsp+8)
	extz	bc
	lda	xde, (xsp)
	ld	wa, 1:i3
	call	SeMenu_ApplySynthParam_Data
	ld	a, (xsp+4)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	ld	de, (xsp)
	call	SeMenu_RegisterParamDisplay_Data_0x71
	ld	a, (xsp+4)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	ldw	de, 16
	call	SeMenu_InitDisplayField_Alt
	ld	wa, 2:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+12)
	ret
	lda	xsp, (xsp-10)
	ld	(xsp+8), a
	lda	xbc, (xsp+4)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	lda	xwa, (xsp+6)
	call	SeMenu_ValidatePartNumber
	ld	a, (xsp+4)
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_ApplyPartEdit_Data2_0x1C63
	lda	xwa, (xsp)
	call	SeMenu_ApplyPartEdit_Data2_0x1C7A
	ld	a, (xsp+8)
	res	7, a
	cp	a, 0:i3
	jr	nz, 14
	ld	wa, (xsp)
	dec	1, wa
	cp	(xsp+2), wa
	jr	nc, 55
	incw	1, (xsp+2)
	jr	10
	cpw	(xsp+2), 0
	jr	z, 43
	decm	1, (xsp+2)
	ld	a, (xsp+6)
	extz	wa
	ld	c, (xsp+4)
	extz	bc
	ld	de, (xsp+2)
	call	SeMenu_RegisterParamDisplay_Data_0x71
	ld	a, (xsp+6)
	extz	wa
	ld	c, (xsp+4)
	extz	bc
	ldw	de, 16
	call	SeMenu_InitDisplayField_Alt
	ld	wa, 3:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+10)
	ret
	lda	xsp, (xsp-22)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+22), a
	lda	xbc, (xsp+8)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	.byte 0x8f
	ld	(63:8), 4:io
	jrl	z, 634
	lda	xwa, (xsp+12)
	ld	(xwa), 0
	lda	xbc, (xwa+1)
	ld	wa, 1:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+14)
	ld	wa, 4:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+15)
	ld	wa, 2:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+16)
	ld	wa, 5:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+17)
	ld	wa, 3:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+18)
	ld	wa, 6:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+19)
	ld	wa, 7:i3
	call	SeMenu_LoadPartParam
	ld	l, (xsp+22)
	res	7, l
	ld	a, (xsp+8)
	.byte 0x8f
	ld	(129:8), 201:io
	jr	ge, -57
	.byte 0xe2, 0x99
	extz	wa
	lda	xde, (xsp+12)
	lda_rr xbc, xde, wa
	cp l, 0:i3
	jr	nz, 33
	ld	xde, xbc
	ld	a, (xbc)
	cp	a, 127
	jrl	nc, 524
	.byte 0xbf
	ex_ff
	inc	6, l
	.byte 0x04
	inc	3, a
	jr	2
	inc	1, a
	ld	(xde), a
	.byte 0x82
	push	xsp
	jrl	nc, 16231
	ld	(xde), 127
	jr	58
	ld	xhl, xde
	ld	xde, xbc
	ld	w, (xsp+8)
	dec	1, w
	ld	a, (xbc)
	cp	a, w
	jrl	ule, 485
	cp	a, 127
	jr	nz, 13
	stb_erp a, 226
	inc 2, a
	extz	wa
	.byte 0xf3
	reti
	or	xwa, xix
	nop
	jrl	nc, 5823
	inc	6, l
	scf
	ld	a, (xde)
	cp	a, 3:i3
	jr	ugt, 5
	ld	(xde), 0
	jr	8
	dec	3, a
	ld	(xde), a
	jr	2
	decm8	1, (xde)
	stb_erp	a, 226
	extz	wa
	lda	xhl, (xsp+12)
	lda_rr xde, xhl, wa
	ld c, (xde)
	cp	c, 127
	jr	z, 17
	stb_erp a, 226
	inc 1, a
	ldb_erp	a, 240
	extz	ix
	inc	1, c
	.byte 0xf3
	reti
	cp	xwa, xix
	ld	xhl, 0x04bf2182
	ld	xbc, 0x23a8fbc7
	nop
	ld	a, c
	add	a, c
	inc	1, a
	extz	wa
	.byte 0xc3
	reti
	or	xwa, xix
	push	xsp
	jrl	nc, 1902
	inc	1, c
	ld	(xsp+2), c
	jr	6
	inc	1, c
	cp	c, 4:i3
	jr	c, -29
	stb_erp a, 251
	addb_erp a, 251
	ldb_erp a, 226
	extz	wa
	lda_rr xiy, xhl, wa
	ld c, (xiy)
	ld	b, c
	stb_erp a, 226
	inc 1, a
	extz	wa
	lda_rr xix, xhl, wa
	ld a, (xix)
	ldb_erp a, 226
	stb_erp w, 251
	inc	1, w
	cp	(xsp+8), w
	jr	ule, 34
	ld	a, (xsp+8)
	sub	a, w
	ld	w, a
	.byte 0xc7
	add	(0x81c889:24), xsp
	.byte 0x04
	swi	1
	jr	nc, 71
	ld	a, (xsp+4)
	sub	a, w
	ldb_erp	a, 226
	cp	a, c
	jr	nc, 59
	stb_erp b, 226
	jr 54
	cp (xsp+8), w
	jr nc, 41
	cp	(xsp+2), w
	jr	c, 6
	.byte 0x8f, 0x04
	push	xsp
	jrl	nc, 1134
	ld	b, 0:opc
	jr	34
	.byte 0x8f
	ld	(160:8), 143:io
	max
	ld	a, 200:opc
	and	(xbc), b
	.byte 0xf1
	jr	ule, 2
	ld	b, a
	stb_erp	a, 226
	cp	a, b
	jr	nc, 13
	.byte 0xc7
	add	(0x08689a:24), xsp
	.byte 0x04
	swi	2
	jr	nc, 3
	ld	b, (xsp+4)
	ld	(xiy), b
	stb_erp	a, 226
	ld	(xix), a
	inc1b_erp 251
	cpib_erp 251, 4
	jrl c, -182
	ld	a, (xsp+4)
	ld	(xde), a
	ld	c, (xhl+1)
	extz	bc
	ld	wa, 1:i3
	call	SeMenu_StorePartParam
	ld	c, (xsp+14)
	extz	bc
	ld	wa, 4:i3
	call	SeMenu_StorePartParam
	ld	c, (xsp+15)
	extz	bc
	ld	wa, 2:i3
	call	SeMenu_StorePartParam
	ld	c, (xsp+16)
	extz	bc
	ld	wa, 5:i3
	call	SeMenu_StorePartParam
	ld	c, (xsp+17)
	extz	bc
	ld	wa, 3:i3
	call	SeMenu_StorePartParam
	ld	c, (xsp+18)
	extz	bc
	ld	wa, 6:i3
	call	SeMenu_StorePartParam
	ld	c, (xsp+19)
	extz	bc
	ld	wa, 7:i3
	call	SeMenu_StorePartParam
	lda	xwa, (xsp+10)
	call	SeMenu_LoadObjEntries
	lda	xwa, (xsp+6)
	.byte 0x8f
	ldw	(63:8), 0x6e00:io
	ldw	hl, 0x6c1d
	jrl	lt, -14352
	swi	3
	cp	(xbc-57), xhl
	.byte 0x89
	extz	wa
	lda	xbc, (xsp+4)
	call	SeMenu_LoadPartParam
	ld	a, (xsp+6)
	extz	wa
	ld	c, 0:opc
	.byte 0xc7
	swi	3
	and	(xhl), c
	jr	ge, -65
	.byte 0x04
	ldw	de, 0x7f0b
	nop
	call	SeMenu_RegisterElement_Extended
	inc1b_erp 251
	cpib_erp 251, 3
	jr ule, -42
	jr	49
	call	SeMenu_ValidatePartNumber
	ldib_erp 251, 1
	stb_erp a, 251
	extz	wa
	lda	xbc, (xsp+4)
	call	SeMenu_LoadPartParam
	ld	a, (xsp+6)
	extz	wa
	ld	c, 0:opc
	.byte 0xc7
	swi	3
	and	(xhl), c
	jr	ge, -65
	.byte 0x04
	ldw	de, 0x7f0b
	nop
	call	SeMenu_SetupDisplayObject_Alt1
	inc1b_erp 251
	cpib_erp 251, 3
	jr ule, -42
	pushw	1
	pushw	38
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	ld	wa, 6:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	pop qiz
	lda	xsp, (xsp+22)
	ret
	cp	a, 0:i3
	ret	z
	call	SeMenu_BitShiftMask_End_0x1A3
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 1:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 38
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 2:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	ret	z
	ldw	wa, 38
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x87
	push	xsp
	normal
	jr	z, 25
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	z, 19
	ld	wa, 3:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	jr	z, 9
	ldw	wa, 38
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x87
	push	xsp
	normal
	jr	z, 25
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	z, 19
	ld	wa, 4:i3
	call	SeMenu_TransferPartValues_EndData_0x1E0
	cp	l, 0:i3
	jr	z, 9
	ldw	wa, 38
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x87
	push	xsp
	normal
	jr	z, 22
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, 7
	ldw	wa, 35
	ld	bc, 0:i3
	jr	5
	ldw	wa, 34
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	inc	4, xsp
	ret
	dec	2, xsp
	cp	a, 0:i3
	jr	nz, 33
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	.byte 0x87
	push	xsp
	nop
	jr	nz, 7
	ldw	wa, 32
	ld	bc, 0:i3
	jr	5
	ldw	wa, 61
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	inc	2, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeMenu_SetupPartDisplay_End_0x90
	cp	hl, 0xffff
	jr	z, 25
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (ToneGen_ParamTable_0x186:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeMenu_SetupPartDisplay_End_0x90
	cp	hl, 0xffff
	jr	z, 25
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (ToneGen_ParamTable_0x2A6:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeMenu_SetupPartDisplay_End_0x90
	cp	hl, 0xffff
	jr	z, 25
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (ToneGen_ParamTable_0x1CE:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	inc	4, xsp
	ret
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeMenu_SetupPartDisplay_End_0x90
	cp	hl, 0xffff
	jr	z, 25
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (ToneGen_ParamTable_0x216:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	inc	4, xsp
	ret
	dec	8, xsp
	pushw	iz
	ld	(xsp+8), bc
	ld	iz, wa
	lda	xwa, (xsp+2)
	call	SeMenu_DisplayState_Data
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, 48
	lda	xde, (xsp+6)
	lda	xwa, (xsp+4)
	push	xwa
	ld	wa, iz
	ld	bc, (xsp+12)
	call	SeMenu_SetupPartDisplay_End_0x90
	cp	hl, 0xffff
	jr	z, 26
	ld	a, (xsp+4)
	extz	wa
	ld	c, (xsp+6)
	extz	bc
	sla	bc, 2
	lda	xde, (ToneGen_ParamTable_0x25E:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
	popw	iz
	inc	8, xsp
	ret
	lda	xsp, (xsp-20)
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+20), a
	lda	xbc, (xsp+18)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	.byte 0x8f
	ccf
	push	xsp
	halt
	jrl	z, 170
	.byte 0x8f
	ccf
	push	xsp
	ld	(118:8), 163:io
	nop
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	lda	xde, (xsp+2)
	ld	(xde+6), 255
	ld	(xde+7), 0
	lda	xwa, (xde+8)
	lda	xbc, (xde+9)
	.byte 0x8f
	ccf
	push	xsp
	push	sr
	jr	nz, 8
	ld	(xwa), 21
	ld	(xbc), 0
	jr	6
	ld	(xwa), 10
	ld	(xbc), 246
	ld	a, (xsp+20)
	extz	wa
	lda	xbc, (xde+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	lda	xwa, (xsp+2)
	call	SeMenu_BitShiftMask_End_0x14
	cp	l, 1:i3
	jrl	nz, 397
	ld	a, (xsp+18)
	extz	wa
	ld	c, (xsp+5)
	extz	bc
	call	SeMenu_StorePartParam
	ld	a, (xsp+18)
	extz	wa
	pushw	wa
	pushw	33
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	.byte 0x8f
	ccf
	push	xsp
	push	sr
	jr	nz, 10
	lda	xbc, (xsp+5)
	ld	a, (xbc)
	sub	a, 11
	ld	(xbc), a
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xsp+5)
	call	SeMenu_InitDisplayColumn_Data
	.byte 0x8f
	ccf
	push	xsp
	push	sr
	jr	c, 22
	.byte 0x8f
	ccf
	push	xsp
	max
	jr	ugt, 16
	ld	a, (xsp+18)
	dec	2, a
	extz	wa
	ld	c, (xsp+5)
	extz	bc
	call	SeMenu_StoreEffectCoeff
	ld	wa, 4:i3
	jrl	239
	lda	xbc, (xsp+2)
	.byte 0x8f
	ccf
	push	xsp
	halt
	jr	nz, 68
	ld	(xsp+18), 9
	ldw	wa, 9
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+2)
	ld	(xbc+6), 15
	ld	(xbc+7), 0
	ld	(xbc+8), 10
	ld	(xbc+9), 6
	ld	a, (xsp+20)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	ld	c, (xsp+18)
	extz	bc
	pushw	41
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 33
	ld	de, 0:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	ld	wa, 4:i3
	jrl	162
	.byte 0x8f
	ccf
	push	xsp
	ld	(126:8), 159:io
	nop
	ld	(xsp+18), 10
	ld	a, (xsp+20)
	res	7, a
	ldb_erp a, 251
	ldw	wa, 10
	call	SeMenu_LoadPartParam
	lda	xwa, (xsp+2)
	ld	(xwa+6), 15
	ld	(xwa+7), 0
	ld	(xwa+8), 11
	ld	(xwa+9), 0
	lda	xwa, (xsp+14)
	call	SeMenu_LoadMasterPtr
	.byte 0xc7
	swi	3
	dec	6, wa
	jr	nz, -65
	push	sr
	ldw	wa, 0xcfb0
	jr	nz, 33
	.byte 0xb0, 0xbf
	ld	a, (xwa)
	ld	(xsp+16), a
	ld	wa, 4:i3
	ldw	bc, 64
	ld	de, 1:i3
	call	SeMenu_PatchBank_Data
	ld	a, (xsp+14)
	extz	wa
	pushw	64
	ld	bc, 4:i3
	ldw	de, 64
	jr	114
	ld	(xwa+10), 1
	call	SeMenu_BitShiftMask_End_0x14
	cp	l, 1:i3
	jr	nz, 120
	ld	a, (xsp+5)
	ld	(xsp+16), a
	lda	xde, (xsp+16)
	pushw	15
	ld	wa, 0:i3
	ldw	bc, 93
	call	SeMenu_RegisterElement_Extended
	ld	a, (xsp+18)
	extz	wa
	ld	c, (xsp+16)
	extz	bc
	call	SeMenu_StorePartParam
	ld	a, (xsp+18)
	extz	wa
	pushw	wa
	pushw	33
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	ld	wa, 4:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	jr	62
	lda	xwa, (xsp+2)
	.byte 0xb0
	inc	6, l
	.byte 0x37
	ld	c, (xwa)
	and	c, 15
	jr	nz, 36
	.byte 0xb0, 0xb7
	ld	a, (xwa)
	ld	(xsp+16), a
	ld	wa, 4:i3
	ldw	bc, 64
	ld	de, 0:i3
	call	SeMenu_PatchBank_Data
	ld	a, (xsp+14)
	extz	wa
	pushw	64
	ld	bc, 4:i3
	ld	de, 0:i3
	call	AddswbWr
	jr	-102
	ld	(xwa+10), 255
	call	SeMenu_BitShiftMask_End_0x14
	cp	l, 1:i3
	jr	z, -120
	pop qiz
	lda	xsp, (xsp+20)
	ret
	cp	a, 0:i3
	ret	z
	ld	wa, 0:i3
	call	SeMenu_HandleMenuChange_Data_0x5
	ldw	wa, 62
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xbc, (xsp)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, 11
	.byte 0x87
	push	xsp
	halt
	jr	z, 31
	ld	wa, 0:i3
	ld	bc, 5:i3
	jr	9
	.byte 0x87
	push	xsp
	normal
	jr	z, 20
	ld	wa, 0:i3
	ld	bc, 1:i3
	call	SeMenu_StorePartParam
	pushw	0
	pushw	33
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xbc, (xsp)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, 11
	.byte 0x87
	push	xsp
	.byte 0x06
	jr	z, 31
	ld	wa, 0:i3
	ld	bc, 6:i3
	jr	9
	.byte 0x87
	push	xsp
	push	sr
	jr	z, 20
	ld	wa, 0:i3
	ld	bc, 2:i3
	call	SeMenu_StorePartParam
	pushw	0
	pushw	33
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xbc, (xsp)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, 11
	.byte 0x87
	push	xsp
	reti
	jr	z, 31
	ld	wa, 0:i3
	ld	bc, 7:i3
	jr	9
	.byte 0x87
	push	xsp
	pop	sr
	jr	z, 20
	ld	wa, 0:i3
	ld	bc, 3:i3
	call	SeMenu_StorePartParam
	pushw	0
	pushw	33
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xbc, (xsp)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	.byte 0x8f
	push	sr
	push	xsp
	nop
	jr	nz, 12
	.byte 0x87
	push	xsp
	ld	(102:8), 32:io
	ld	wa, 0:i3
	ldw	bc, 8
	jr	9
	.byte 0x87
	push	xsp
	max
	jr	z, 20
	ld	wa, 0:i3
	ld	bc, 4:i3
	call	SeMenu_StorePartParam
	pushw	0
	pushw	33
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	inc	4, xsp
	ret
	cp	a, 0:i3
	ret	nz
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
	lda	xsp, (xsp-16)
	ld	(xsp+14), a
	lda	xbc, (xsp+12)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	.byte 0x8f
	incf
	push	xix
	retd	0x31b7
	ld	wa, 1:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	a, (xsp+14)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	ld	e, (xsp+12)
	lda	xbc, (xsp)
	lda	xwa, (xbc+8)
	lda	xbc, (xbc+9)
	cp	e, 9
	jr	z, 56
	cp	e, 10
	jr	z, 56
	cp	e, 11
	jr	z, 51
	cp	e, 8
	jr	ugt, 51
	cp	e, 0:i3
	jr	c, 47
	ld	(xwa), 50
	ld	(xbc), 0
	ld	xwa, 94
	extz	wa
	pushw	wa
	.byte 0xbf
	push	sr
	.asciz "080:"
	ld	bc, 1:i3
	ld	de, 0:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	ld	wa, 1:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	jr	10
	ld	(xwa), 30
	jr	-39
	ld	(xwa), 1
	jr	-44
	lda	xsp, (xsp+16)
	ret
	lda	xsp, (xsp-16)
	ld	(xsp+14), a
	lda	xbc, (xsp+12)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	.byte 0x8f
	incf
	push	xix
	retd	0x31b7
	ld	wa, 2:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	a, (xsp+14)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	ld	e, (xsp+12)
	lda	xbc, (xsp)
	lda	xwa, (xbc+8)
	lda	xbc, (xbc+9)
	cp	e, 8
	jr	z, 64
	cp	e, 9
	jr	z, 67
	cp	e, 10
	jr	z, 13
	cp	e, 11
	jr	z, 8
	cp	e, 7:i3
	jr	ugt, 61
	cp	e, 0:i3
	jr	c, 57
	lda	xwa, (xsp)
	ld	(xwa+8), 50
	ld	(xwa+9), 0
	ld	xwa, 1:i3
	lda	xwa, (xwa+94)
	extz	wa
	pushw	wa
	.byte 0xbf
	push	sr
	.asciz "080:"
	ld	bc, 2:i3
	ld	de, 0:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	ld	wa, 2:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	jr	16
	ld	(xwa), 50
	ld	(xbc), 206
	jr	-39
	ld	(xwa), 30
	ld	(xbc), 0
	jr	-47
	lda	xsp, (xsp+16)
	ret
	lda	xsp, (xsp-16)
	ld	(xsp+14), a
	lda	xbc, (xsp+12)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	.byte 0x8f
	incf
	push	xix
	retd	0x31b7
	ld	wa, 3:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	a, (xsp+14)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	ld	a, (xsp+12)
	extz	wa
	cp	wa, 0:i3
	jr	mi, 109
	cp	wa, 11
	jr	gt, 103
	add	wa, wa
	lda	xix, (ToneGen_ParamTable_0x2EE:24)
	ld_rrw wa, xix, wa
	lda xix, (15785099:24)
	jp_rr 8, xix, wa
	lda	xwa, (xsp)
	ld	(xwa+8), 50
	ld	(xwa+9), 206
	ld	xwa, 2:i3
	lda	xwa, (xwa+94)
	extz	wa
	pushw	wa
	.byte 0xbf
	push	sr
	.asciz "080:"
	ld	bc, 3:i3
	ld	de, 0:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	ld	wa, 3:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	jr	40
	lda	xwa, (xsp)
	ld	(xwa+8), 50
	jr	26
	lda	xwa, (xsp)
	ld	(xwa+8), 3
	jr	18
	lda	xwa, (xsp)
	ld	(xwa+8), 24
	ld	(xwa+9), 232
	jr	-59
	lda	xwa, (xsp)
	ld	(xwa+8), 30
	ld	(xwa+9), 0
	jr	-71
	lda	xsp, (xsp+16)
	ret
	lda	xsp, (xsp-16)
	ld	(xsp+14), a
	lda	xbc, (xsp+12)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	.byte 0x8f
	incf
	push	xix
	retd	0x31b7
	ld	wa, 4:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	a, (xsp+14)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	ld	a, (xsp+12)
	extz	wa
	cp	wa, 0:i3
	jr	mi, 85
	cp	wa, 9
	jr	gt, 79
	add	wa, wa
	lda	xix, (ToneGen_ParamTable_0x306:24)
	ld_rrw wa, xix, wa
	lda xix, (15785270:24)
	jp_rr 8, xix, wa
	lda	xwa, (xsp)
	ld	(xwa+8), 50
	ld	(xwa+9), 0
	ld	xwa, 3:i3
	lda	xwa, (xwa+94)
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 58
	ld	bc, 4:i3
	ld	de, 0:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	ld	wa, 4:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	jr	16
	lda	xwa, (xsp)
	ld	(xwa+8), 100
	jr	-43
	lda	xwa, (xsp)
	ld	(xwa+8), 30
	jr	-51
	lda	xsp, (xsp+16)
	ret
	lda	xsp, (xsp-16)
	ld	(xsp+14), a
	lda	xbc, (xsp+12)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	.byte 0x8f
	incf
	push	xix
	retd	0x31b7
	ld	wa, 5:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	a, (xsp+14)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	ld	a, (xsp+12)
	extz	wa
	cp	wa, 0:i3
	jr	mi, 79
	cp	wa, 5:i3
	jr	gt, 75
	add	wa, wa
	lda	xix, (ToneGen_ParamTable_0x31A:24)
	ld_rrw wa, xix, wa
	lda xix, (15785415:24)
	jp_rr 8, xix, wa
	lda	xwa, (xsp)
	ld	(xwa+8), 100
	ld	(xwa+9), 0
	ld	xwa, 4:i3
	lda	xwa, (xwa+94)
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 58
	ld	bc, 5:i3
	ld	de, 0:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	ld	wa, 5:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	jr	12
	lda	xwa, (xsp)
	ld	(xwa+8), 50
	ld	(xwa+9), 206
	jr	-43
	lda	xsp, (xsp+16)
	ret
	lda	xsp, (xsp-16)
	ld	(xsp+14), a
	lda	xbc, (xsp+12)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	.byte 0x8f
	incf
	push	xix
	retd	0x31b7
	ld	wa, 6:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	a, (xsp+14)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	ld	a, (xsp+12)
	cp	a, 5:i3
	jr	z, 4
	cp	a, 4:i3
	jr	nz, 36
	lda	xbc, (xsp)
	ld	(xbc+8), 50
	ld	(xbc+9), 0
	ld	xwa, 5:i3
	lda	xwa, (xwa+94)
	extz	wa
	.asciz "(90:"
	ld	bc, 6:i3
	ld	de, 0:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	ld	wa, 6:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+16)
	ret
	lda	xsp, (xsp-16)
	ld	(xsp+14), a
	lda	xbc, (xsp+12)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	.byte 0x8f
	incf
	push	xix
	retd	0x31b7
	ld	wa, 7:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	a, (xsp+14)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	ld	a, (xsp+12)
	cp	a, 10
	jr	z, 50
	cp	a, 11
	jr	z, 9
	cp	a, 9
	jr	ugt, 40
	cp	a, 0:i3
	jr	c, 36
	lda	xbc, (xsp)
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	xwa, 6:i3
	lda	xwa, (xwa+94)
	extz	wa
	.asciz "(90:"
	ld	bc, 7:i3
	ld	de, 0:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	ld	wa, 7:i3
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+16)
	ret
	lda	xsp, (xsp-16)
	ld	(xsp+14), a
	lda	xbc, (xsp+12)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	.byte 0x8f
	incf
	push	xix
	retd	0x31b7
	ldw	wa, 8
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	a, (xsp+14)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SetupPartDisplay_End_0x219
	ld	a, (xsp+12)
	cp	a, 11
	jr	ugt, 42
	cp	a, 0:i3
	jr	c, 38
	lda	xbc, (xsp)
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	xwa, 7:i3
	lda	xwa, (xwa+94)
	extz	wa
	pushw	wa
	push	xbc
	ldw	wa, 58
	ldw	bc, 8
	ld	de, 0:i3
	call	SeMenu_TransferPartValues_EndData_0x169
	ldw	wa, 8
	call	SeMenu_SetupPartDisplay_End_0x1F6
	lda	xsp, (xsp+16)
	ret
	dec	4, xsp
	lda	xbc, (xsp+2)
	cp	a, 0:i3
	jr	nz, 74
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+2)
	and	a, 15
	cp	a, 11
	jrl	z, 168
	cp	a, 11
	jrl	ugt, 162
	inc	1, a
	.byte 0x8f
	push	sr
	push	xix
	stiw_d8 143, 233, 143
	push sr
	ld c, 217:opc
	ccf
	ld	wa, 0:i3
	call	SeMenu_StorePartParam
	lda	xde, (xsp+2)
	pushw	15
	ld	wa, 0:i3
	ldw	bc, 93
	call	SeMenu_RegisterElement_Extended
	ldw	wa, 58
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	call	SeMenu_OrPartConfig_Data
	jr	112
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	lda	xwa, (xsp)
	call	SeMenu_LoadMasterPtr
	.byte 0xbf
	push	sr
	inc	6, l
	jp	0xb702bf
	ld	wa, 4:i3
	ldw	bc, 64
	ld	de, 0:i3
	call	SeMenu_PatchBank_Data
	ld	a, (xsp)
	extz	wa
	pushw	64
	ld	bc, 4:i3
	ld	de, 0:i3
	jr	26
	.byte 0xbf
	push	sr
	.byte 0xbf
	ld	wa, 4:i3
	ldw	bc, 64
	ld	de, 1:i3
	call	SeMenu_PatchBank_Data
	ld	a, (xsp)
	extz	wa
	pushw	64
	ld	bc, 4:i3
	ldw	de, 64
	call	AddswbWr
	ld	c, (xsp+2)
	extz	bc
	ld	wa, 0:i3
	call	SeMenu_StorePartParam
	lda	xde, (xsp+2)
	pushw	128
	ld	wa, 0:i3
	ldw	bc, 93
	call	SeMenu_RegisterElement_Extended
	pushw	0
	pushw	58
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	inc	4, xsp
	ret
	dec	2, xsp
	lda	xbc, (xsp)
	cp	a, 0:i3
	jr	nz, 64
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp)
	and	a, 15
	jr	z, 103
	cp	a, 11
	jr	ugt, 98
	dec	1, a
	.byte 0x87
	push	xix
	.byte 0xf0
	or	(xsp), a
	ld	c, (xsp)
	extz	bc
	ld	wa, 0:i3
	call	SeMenu_StorePartParam
	lda	xde, (xsp)
	pushw	15
	ld	wa, 0:i3
	ldw	bc, 93
	call	SeMenu_RegisterElement_Extended
	ldw	wa, 58
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	call	SeMenu_OrPartConfig_Data
	jr	52
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	.byte 0xb7
	inc	6, h
	.byte 0x04, 0xb7, 0xb6
	jr	2
	.byte 0xb7, 0xbe
	ld	c, (xsp)
	extz	bc
	ld	wa, 0:i3
	call	SeMenu_StorePartParam
	lda	xde, (xsp)
	pushw	64
	ld	wa, 0:i3
	ldw	bc, 93
	call	SeMenu_RegisterElement_Extended
	pushw	0
	pushw	58
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	inc	2, xsp
	ret
	cp	a, 0:i3
	ret	nz
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
	dec	2, xsp
	cp	a, 0:i3
	jr	z, 44
	lda	xwa, (xsp)
	call	SeMenu_SetupPartDisplay_End_0x1AA
	ld	a, (xsp)
	extz	wa
	ldw	bc, 62
	call	SeMenu_RegisterElement_Type1_ClearLoop_0x44
	ld	a, (xsp)
	extz	wa
	call	SeMenu_SetDisplayValue_Data
	ldw	wa, 35
	call	SeMenu_TriggerNotification
	ld	wa, 1:i3
	call	SeMenu_HandleMenuChange_Data_0x5
	ld	wa, 0:i3
	call	SeMenu_SetSelectedRow
	inc	2, xsp
	ret
	dec	6, xsp
	cp	a, 0:i3
	jr	nz, 106
	lda	xwa, (xsp+4)
	call	SeMenu_SetupPartDisplay_End_0x1AA
	.byte 0x8f, 0x04
	push	xsp
	ld	l, 111:opc
	pop	xiy
	incm8	1, (xsp+4)
	ld	a, (xsp+4)
	extz	wa
	call	SeMenu_SetupPartDisplay_End_0x1AF
	lda	xde, (xsp)
	ld	a, (xsp+4)
	extz	wa
	extz	xwa
	div	wa, 20
	ld	(xde), a
	lda	xbc, (xde+1)
	ld	a, (xsp+4)
	extz	wa
	extz	xwa
	div	wa, 20
	ld wa, qwa
	ld (xbc), a
	incm8 1, (xde)
	incm8 1, (xbc)
	ld c, (xde)
	extz bc
	ld	wa, 0:i3
	call	SeMenu_StorePartParam
	ld	c, (xsp+1)
	extz	bc
	ld	wa, 1:i3
	call	SeMenu_StorePartParam
	pushw	0
	pushw	62
	call	SeMenu_ShowConfirmDialog
	pushw	1
	pushw	62
	call	SeMenu_ShowConfirmDialog
	inc	8, xsp
	inc	6, xsp
	ret
	dec	6, xsp
	cp	a, 0:i3
	jr	nz, 106
	lda	xwa, (xsp+4)
	call	SeMenu_SetupPartDisplay_End_0x1AA
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	z, 93
	decm8	1, (xsp+4)
	ld	a, (xsp+4)
	extz	wa
	call	SeMenu_SetupPartDisplay_End_0x1AF
	lda	xde, (xsp)
	ld	a, (xsp+4)
	extz	wa
	extz	xwa
	div	wa, 20
	ld	(xde), a
	lda	xbc, (xde+1)
	ld	a, (xsp+4)
	extz	wa
	extz	xwa
	div	wa, 20
	ld wa, qwa
	ld (xbc), a
	incm8 1, (xde)
	incm8 1, (xbc)
	ld c, (xde)
	extz bc
	ld	wa, 0:i3
	call	SeMenu_StorePartParam
	ld	c, (xsp+1)
	extz	bc
	ld	wa, 1:i3
	call	SeMenu_StorePartParam
	pushw	0
	pushw	62
	call	SeMenu_ShowConfirmDialog
	pushw	1
	pushw	62
	call	SeMenu_ShowConfirmDialog
	inc	8, xsp
	inc	6, xsp
	ret
	cp	a, 0:i3
	ret	nz
	ldw	wa, 63
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
	cp	a, 0:i3
	ret	nz
	ld	wa, 0:i3
	call	SeMenu_SetSelectedRow
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
	jrl	391
	jrl	477
	jrl	576
	jrl	788
	jrl	978
	jrl	1090
	ld	c, a
	res	7, c
	ldw	wa, 0x8000
	cp	c, 0:i3
	jr	nz, 2
	ld	wa, 0:i3
	jrl	1149
	jrl	1267
	dec	4, xsp
	.byte 0xd7
	swi	2
	.byte 0x04
	cp	a, 0:i3
	jr	nz, 5
	calr	1331
	jr	82
	lda	xwa, (xsp+2)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push	sr
	push	xsp
	normal
	jr	z, 69
	ldib_erp 251, 0
	stb_erp a, 251
	extz	wa
	lda	xbc, (xsp+4)
	call	SeMenu_SetupPartDisplay_End_0x1C6
	lda	xbc, (xsp+4)
	ld	xwa, xbc
	call	FontGlyph_ByteData
	stb_erp a, 251
	extz	wa
	extz	xwa
	ld	c, a
	lda	xde, (xsp+4)
	pushw	127
	ld	wa, 0:i3
	call	SeMenu_RegisterElement_Extended
	inc1b_erp 251
	cp_erpb 251, 16
	jr	c, -51
	ld	wa, 0:i3
	call	SeMenu_HandleMenuChange_Data_0x5
	ldw	wa, 62
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	pop qiz
	inc	4, xsp
	ret
	cp	a, 0:i3
	ret	nz
	jrl	1303
	lda	xsp, (xsp-20)
	.byte 0xd7
	swi	2
	.byte 0x04
	cp	a, 0:i3
	jrl	nz, 130
	lda	xwa, (xsp+2)
	call	SeMenu_LoadObjEntries
	.byte 0x8f
	push	sr
	push	xsp
	normal
	jr	nz, 57
	lda	xbc, (xsp+4)
	ld	wa, 1:i3
	ldw	de, 13
	call	SeMenu_SetupPartDisplay_End
	ldib_erp 251, 0
	stb_erp a, 251
	extz	wa
	ld	bc, wa
	extz	xbc
	lda	xde, (xsp+4)
	lda_rr xde, xde, wa
	pushw 127
	ld	wa, 0:i3
	call	SeMenu_SetupDisplayObject_Alt1
	inc1b_erp 251
	cp_erpb 251, 13
	jr	c, -35
	ldw	wa, 61
	ld	bc, 0:i3
	jr	56
	ldib_erp 251, 0
	stb_erp a, 251
	extz	wa
	lda	xbc, (xsp+20)
	call	SeMenu_SetupPartDisplay_End_0x1C6
	stb_erp a, 251
	extz	wa
	extz	xwa
	ld	c, a
	lda	xde, (xsp+20)
	pushw	127
	ld	wa, 0:i3
	call	SeMenu_RegisterElement_Extended
	inc1b_erp 251
	cp_erpb 251, 16
	jr	c, -42
	ld	wa, 0:i3
	call	SeMenu_HandleMenuChange_Data_0x5
	ldw	wa, 62
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	pop qiz
	lda	xsp, (xsp+20)
	ret
	dec	4, xsp
	ld	c, a
	and	c, 31
	cp	c, 16
	jr	ule, 2
	ld	c, 16:opc
	extz	bc
	ld	wa, 2:i3
	call	SeMenu_StorePartParam
	lda	xbc, (xsp+2)
	ld	wa, 0:i3
	call	SeMenu_SetupPartDisplay_End_0x1C6
	ld	a, (xsp+2)
	extz	wa
	lda	xbc, (xsp)
	call	SeMenu_SetupPartDisplay_End_0x24D
	ld	c, (xsp)
	extz	bc
	ld	wa, 1:i3
	call	SeMenu_StorePartParam
	ld	wa, 0:i3
	ld	bc, 0:i3
	call	SeMenu_StorePartParam
	pushw	63
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	ld	wa, 1:i3
	call	SeMenu_SetupPartDisplay_End_0x1DA
	ld	wa, 0:i3
	ldw	bc, 8
	ld	de, 0:i3
	call	SeMenu_SetupPartDisplay_End_0x1E0
	ld	wa, 1:i3
	ld	bc, 6:i3
	ld	de, 0:i3
	call	SeMenu_SetupPartDisplay_End_0x1E0
	inc	4, xsp
	ret
	dec	6, xsp
	lda	xbc, (xsp+4)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	.byte 0x8f, 0x04
	push	xsp
	nop
	jr	z, 69
	decm8	1, (xsp+4)
	ld	c, (xsp+4)
	extz	bc
	ld	wa, 0:i3
	call	SeMenu_StorePartParam
	ld	a, (xsp+4)
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_SetupPartDisplay_End_0x1C6
	ld	a, (xsp+2)
	extz	wa
	lda	xbc, (xsp)
	call	SeMenu_SetupPartDisplay_End_0x24D
	ld	c, (xsp)
	extz	bc
	ld	wa, 1:i3
	call	SeMenu_StorePartParam
	pushw	0
	pushw	63
	call	SeMenu_ShowConfirmDialog
	pushw	1
	pushw	63
	call	SeMenu_ShowConfirmDialog
	inc	8, xsp
	inc	6, xsp
	ret
	dec	8, xsp
	lda	xbc, (xsp+6)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	wa, 2:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp)
	dec	1, a
	cp	(xsp+6), a
	jr	nc, 71
	incm8	1, (xsp+6)
	ld	c, (xsp+6)
	extz	bc
	ld	wa, 0:i3
	call	SeMenu_StorePartParam
	ld	a, (xsp+6)
	extz	wa
	lda	xbc, (xsp+4)
	call	SeMenu_SetupPartDisplay_End_0x1C6
	ld	a, (xsp+4)
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_SetupPartDisplay_End_0x24D
	ld	c, (xsp+2)
	extz	bc
	ld	wa, 1:i3
	call	SeMenu_StorePartParam
	pushw	0
	pushw	63
	call	SeMenu_ShowConfirmDialog
	pushw	1
	pushw	63
	call	SeMenu_ShowConfirmDialog
	inc	8, xsp
	inc	8, xsp
	ret
	lda	xsp, (xsp-24)
	.byte 0xd7
	swi	2
	.byte 0x04
	lda	xbc, (xsp+2)
	ld	wa, 2:i3
	call	SeMenu_LoadPartParam
	ldib_erp 251, 0
	stb_erp a, 251
	extz	wa
	lda	xbc, (xsp+6)
	.byte 0xf3
	reti
	.byte 0xe4, 0xe0
	ldw	bc, 0x691d
	jrl	ov, -14352
	swi	3
	jr	lt, -57
	swi	3
	.byte 0xcf
	retd	0xe663
	ld	c, (xsp+2)
	dec	1, c
	extz	bc
	lda	xwa, (xsp+6)
	.byte 0xc3
	reti
	.byte 0xe0, 0xe4
	push	xsp
	ld	w, 126:opc
	.byte 0x91
	nop
	lda	xbc, (xsp+24)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ldib_erp 251, 0
	ld	a, (xsp+2)
	.byte 0x8f
	push_f
	and	(xbc), xbc
	jr	ge, -57
	ld	xsp, (0x028f99:24)
	dec	1, l
	lda	xbc, (xsp+6)
	ld	xix, xbc
	ld	e, (xsp+2)
	add	e, 254
	extz	de
	extz	hl
	stb_erp a, 251
	cpb_erp a, 226
	jr	nc, 29
	ld	iy, hl
	ld	wa, de
	ld_rrb a, xix, wa
	st_rrb a, xix, iy
	inc1b_erp 251
	dec 1, hl
	dec 1, de
	stb_erp a, 251
	cpb_erp a, 226
	jr c, -29
	ld a, (xsp+24)
	extz wa
	.byte 0xf3
	reti
	.byte 0xe4, 0xe0
	nop
	ld	w, 216:opc
	.byte 0xa9
	ldw	de, 16
	call	SeMenu_SetupPartDisplay
	ld	c, (xsp+24)
	extz	bc
	lda	xwa, (xsp+6)
	ld_rrb a, xwa, bc
	extz wa
	lda	xbc, (xsp+4)
	call	SeMenu_SetupPartDisplay_End_0x24D
	ld	c, (xsp+4)
	extz	bc
	ld	wa, 1:i3
	call	SeMenu_StorePartParam
	pushw	1
	pushw	63
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	pop qiz
	lda	xsp, (xsp+24)
	ret
	lda	xsp, (xsp-24)
	.byte 0xd7
	swi	2
	.byte 0x04
	lda	xbc, (xsp+2)
	ld	wa, 2:i3
	call	SeMenu_LoadPartParam
	ldib_erp 251, 0
	stb_erp a, 251
	extz	wa
	lda	xbc, (xsp+6)
	.byte 0xf3
	reti
	.byte 0xe4, 0xe0
	ldw	bc, 0x691d
	jrl	ov, -14352
	swi	3
	jr	lt, -57
	swi	3
	.byte 0xcf
	retd	0xe663
	lda	xbc, (xsp+24)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+24)
	ldb_erp a, 251
	ld	c, (xsp+2)
	dec	1, c
	ld	l, c
	stb_erp a, 251
	cp	a, l
	jr	nc, 43
	lda	xde, (xsp+6)
	stb_erp c, 251
	extz	bc
	ld	wa, 1:i3
	add	bc, wa
	ld	ix, bc
	ldw	wa, 0xffff
	add	ix, wa
	ld	wa, bc
	ld_rrb a, xde, wa
	st_rrb a, xde, ix
	inc1b_erp 251
	inc 1, bc
	stb_erp a, 251
	cp	a, l
	jr	c, -31
	ld	a, (xsp+2)
	dec	1, a
	extz	wa
	lda	xbc, (xsp+6)
	.byte 0xf3
	reti
	.byte 0xe4, 0xe0
	nop
	ld	w, 216:opc
	.byte 0xa9
	ldw	de, 16
	call	SeMenu_SetupPartDisplay
	ld	c, (xsp+24)
	extz	bc
	lda	xwa, (xsp+6)
	ld_rrb a, xwa, bc
	extz wa
	lda	xbc, (xsp+4)
	call	SeMenu_SetupPartDisplay_End_0x24D
	ld	c, (xsp+4)
	extz	bc
	ld	wa, 1:i3
	call	SeMenu_StorePartParam
	pushw	1
	pushw	63
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	pop qiz
	lda	xsp, (xsp+24)
	ret
	dec	6, xsp
	lda	xbc, (xsp+4)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+4)
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_SetupPartDisplay_End_0x1C6
	lda	xde, (xsp+2)
	ld	a, (xde)
	cp	a, 65
	jr	c, 62
	cp	a, 90
	jr	ugt, 57
	sub	a, 65
	ld	c, 97:opc
	add	a, c
	ld	(xde), a
	ld	a, (xsp+4)
	extz	wa
	ld	c, (xde)
	extz	bc
	call	SeMenu_SetupPartDisplay_End_0x1B4
	ld	a, (xsp+2)
	extz	wa
	lda	xbc, (xsp)
	call	SeMenu_SetupPartDisplay_End_0x24D
	ld	c, (xsp)
	extz	bc
	ld	wa, 1:i3
	call	SeMenu_StorePartParam
	pushw	1
	pushw	63
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	jr	17
	cp	a, 97
	jr	c, 12
	cp	a, 122
	jr	ugt, 7
	.byte 0xc9, 0xca
	.ascii "a#Ah»"
	inc	6, xsp
	ret
	dec	6, xsp
	lda	xbc, (xsp)
	ld	wa, 1:i3
	call	SeMenu_LoadPartParam
	.byte 0x87
	push	xsp
	nop
	jr	z, 58
	decm8	1, (xsp)
	ld	c, (xsp)
	extz	bc
	ld	wa, 1:i3
	call	SeMenu_StorePartParam
	ld	a, (xsp)
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_SetupPartDisplay_End_0x235
	lda	xbc, (xsp+4)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+4)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	call	SeMenu_SetupPartDisplay_End_0x1B4
	pushw	1
	pushw	63
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	inc	6, xsp
	ret
	dec	6, xsp
	.byte 0xd7
	swi	2
	.byte 0x04
	and	wa, 0x8000
	cp	wa, 0:i3
	scc8	nz, a
	ldb_erp a, 251
	lda	xbc, (xsp+4)
	ld	wa, 1:i3
	call	SeMenu_LoadPartParam
	cpib_erp 251, 0
	jr nz, 12
	.byte 0x8f, 0x04
	push	xsp
	rcf
	jr	c, 79
	.byte 0x8f, 0x04
	push	xde
	rcf
	jr	15
	ld	a, (xsp+4)
	add	a, 16
	cp	a, 95
	jr	ugt, 62
	.byte 0x8f, 0x04
	push	xwa
	rcf
	ld	c, (xsp+4)
	extz	bc
	ld	wa, 1:i3
	call	SeMenu_StorePartParam
	ld	a, (xsp+4)
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_SetupPartDisplay_End_0x235
	lda	xbc, (xsp+6)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+6)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	call	SeMenu_SetupPartDisplay_End_0x1B4
	pushw	1
	pushw	63
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	pop qiz
	inc	6, xsp
	ret
	dec	6, xsp
	lda	xbc, (xsp)
	ld	wa, 1:i3
	call	SeMenu_LoadPartParam
	.byte 0x87
	.ascii "?_o:‡"
	jr	lt, -121
	ld	c, 217:opc
	ccf
	ld	wa, 1:i3
	call	SeMenu_StorePartParam
	ld	a, (xsp)
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_SetupPartDisplay_End_0x235
	lda	xbc, (xsp+4)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+4)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	call	SeMenu_SetupPartDisplay_End_0x1B4
	pushw	1
	pushw	63
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	inc	6, xsp
	ret
	.byte 0xd7
	swi	2
	.byte 0x04, 0xc7
	swi	3
	cp	(xwa-57), xhl
	.byte 0x89
	extz	wa
	ldw	bc, 32
	call	SeMenu_SetupPartDisplay_End_0x1B4
	inc1b_erp 251
	cp_erpb 251, 15
	jr ule, -21
	ld	wa, 0:i3
	ld	bc, 0:i3
	call	SeMenu_StorePartParam
	ld	wa, 1:i3
	ld	bc, 0:i3
	call	SeMenu_StorePartParam
	pushw	0
	pushw	63
	call	SeMenu_ShowConfirmDialog
	pushw	1
	pushw	63
	call	SeMenu_ShowConfirmDialog
	inc	8, xsp
	pop qiz
	ret
	lda	xsp, (xsp-42)
	push	xiz
	ldib_erp 249, 0
	lda	xbc, (xsp+4)
	ld	wa, 2:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+6)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ldib_erp 250, 0
	stb_erp a, 250
	extz	wa
	lda	xbc, (xsp+28)
	.byte 0xf3
	reti
	.byte 0xe4, 0xe0
	ldw	bc, 0x691d
	jrl	ov, -14352
	swi	2
	jr	lt, -57
	swi	2
	.byte 0xcf
	retd	0xe663
	.byte 0xc7
	swi	2
	.byte 0xa8
	ld	a, (xsp+4)
	dec	1, a
	ld	c, a
	cp	a, 0:i3
	jr	c, 29
	lda	xde, (xsp+28)
	stb_erp a, 250
	extz	wa
	.byte 0xc3
	reti
	or	xwa, xwa
	push	xsp
	ld	w, 110:opc
	ldf	0xc7
	swi	1
	jr	lt, -57
	swi	2
	jr	lt, -57
	swi	2
	.byte 0x89
	cp	a, c
	jr	ule, -26
	stb_erp a, 249
	cp	a, c
	jr	ule, 16
	jrl	255
	stb_erp a, 250
	ldb_erp a, 251
	stb_erp a, 249
	cp	a, c
	jr	ugt, -16
	ldib_erp 250, 0
	cp c, 0:i3
	jr	c, 31
	lda	xde, (xsp+28)
	ld	a, c
	subb_erp a, 250
	extz wa
	.byte 0xc3
	reti
	or	xwa, xwa
	push	xsp
	ld	w, 110:opc
	decf
	inc1b_erp 249
	inc1b_erp 250
	stb_erp a, 250
	cp	a, c
	jr	ule, -28
	ld	a, (xsp+4)
	.byte 0xc7
	swi	0
	cp	(xbc-57), bc
	.byte 0xa1, 0xc7
	swi	0
	cp	(xbc-57), bc
	.byte 0xef, 0x01
	lda	xwa, (xsp+10)
	lda	xbc, (xsp+28)
	ldw	de, 16
	call	SeMenu_SetupPartDisplay_End_0xD3
	ldib_erp 250, 0
	cpib_erp 249, 0
	jr ule, 26
	lda	xde, (xsp+10)
	ld	bc, 0:i3
	ld	wa, bc
	.byte 0xf3
	reti
	or	xwa, xwa
	nop
	ld	w, 199:opc
	swi	2
	jr	lt, -39
	jr	lt, -57
	swi	2
	cp	(xbc-57), a
	.byte 0xf1
	jr	c, -21
	stb_erp a, 249
	extz	wa
	lda	xbc, (xsp+10)
	exts	xwa
	add	xwa, xbc
	stb_erp c, 251
	extz	bc
	lda	xde, (xsp+28)
	exts	xbc
	add	xbc, xde
	stb_erp e, 248
	extz	de
	call	SeMenu_SetupPartDisplay_End_0xD3
	stb_erp a, 249
	addb_erp a, 248
	ldb_erp a, 250
	ld	c, (xsp+4)
	dec	1, c
	ld	e, c
	stb_erp a, 250
	cp	a, e
	jr	ugt, 28
	lda	xhl, (xsp+10)
	stb_erp c, 250
	extz	bc
	ld	wa, bc
	.byte 0xf3
	reti
	or	xwa, xix
	nop
	ld	w, 199:opc
	swi	2
	jr	lt, -39
	jr	lt, -57
	swi	2
	.byte 0x89
	cp	a, e
	jr	ule, -20
	lda	xbc, (xsp+10)
	ld	wa, 1:i3
	ldw	de, 16
	call	SeMenu_SetupPartDisplay
	ld	a, (xsp+6)
	extz	wa
	lda	xbc, (xsp+10)
	ld_rrb a, xbc, wa
	extz wa
	lda	xbc, (xsp+8)
	call	SeMenu_SetupPartDisplay_End_0x24D
	ld	c, (xsp+8)
	extz	bc
	ld	wa, 1:i3
	call	SeMenu_StorePartParam
	pushw	1
	pushw	63
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	pop	xiz
	lda	xsp, (xsp+42)
	ret
	cp	a, 0:i3
	jr	nz, 7
	ldw	wa, 38
	ld	bc, 0:i3
	jr	5
	ldw	wa, 43
	ld	bc, 0:i3
	jp	SeMenu_SendEvent
	cp	a, 0:i3
	jr	nz, 7
	ldw	wa, 59
	ld	bc, 0:i3
	jr	5
	ldw	wa, 48
	ld	bc, 0:i3
	jp	SeMenu_SendEvent
	cp	a, 0:i3
	ret	nz
	ldw	wa, 63
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ld	wa, 2:i3
	call	SeMenu_SetSelectedRow
	ret
	cp	a, 0:i3
	ret	nz
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
	ret

SeMenu_PopupDialog_Init:
	push xiz
	ldiw_erp 0xfa, 0
	jr SeMenu_PopupDialog_Setup

SeMenu_PopupDialog_CheckState:
	stw_erp WA, 0xfa
	extz xwa
	ld xbc, 0x20c33
	add xbc, xwa
	ld (xbc), l
	inc1w_erp 0xfa
	cpiw_erp 0xfa, 6
	jr nc, SeMenu_PopupDialog_ShowTitle

SeMenu_PopupDialog_Setup:
	call SeqBuf_SoundEdit_ReadByte
	cp hl, 0:i3
	jr ge, SeMenu_PopupDialog_CheckState

SeMenu_PopupDialog_ShowTitle:
	lda xde, (0x020c33:24)
	ld c, (xde)
	ld a, c
	and a, 0xf0
	cp a, 0x80
	jr z, SeMenu_PopupDialog_ShowBody_Data

SeMenu_PopupDialog_ShowBody:
	call SeqBuf_SoundEdit_ReadByte
	cp hl, 0:i3
	jr ge, SeMenu_PopupDialog_ShowBody
	jrl SeMenu_ListSelector_ScrollDown

SeMenu_PopupDialog_ShowBody_Data:
	cpiw_erp 0xfa, 6
	jrl c, SeMenu_ListSelector_ScrollDown
	cp c, 0x80
	jrl nz, SeMenu_ValueEditor_Data4
	ld a, (xde + 2)
	cp a, 4:i3
	jr nz, SeMenu_PopupDialog_Confirm
	ld iz, 0:i3
	jr SeMenu_PopupDialog_HandleInput_Data

SeMenu_PopupDialog_HandleInput:
	stw_erp WA, 0xfa
	inc1w_erp 0xfa
	extz xwa
	ld xbc, 0x20c33
	add xbc, xwa
	ld (xbc), l
	cp_erpw 0xfa, 0x20, 0x00
	jrl nc, SeMenu_ListSelector_ScrollUp
	inc 1, iz
	cp iz, 0x10
	jrl nc, SeMenu_ListSelector_ScrollUp

SeMenu_PopupDialog_HandleInput_Data:
	call SeqBuf_SoundEdit_ReadByte
	cp hl, 0:i3
	jr ge, SeMenu_PopupDialog_HandleInput
	jrl SeMenu_ListSelector_ScrollUp

SeMenu_PopupDialog_Confirm:
	cp a, 0x17
	jr nz, SeMenu_PopupDialog_Cancel
	call SeqBuf_SoundEdit_ReadByte
	call SeqBuf_SoundEdit_ReadByte
	jrl SeMenu_ListSelector_ScrollDown

SeMenu_PopupDialog_Cancel:
	cp a, 0xb
	jr z, SeMenu_PopupDialog_Close
	cp a, 0xc
	jr z, SeMenu_PopupDialog_Close
	cp a, 0:i3
	jr nz, SeMenu_ValueEditor_Setup

SeMenu_PopupDialog_Close:
	call SeqBuf_SoundEdit_ReadByte
	cp hl, 0:i3
	jr lt, SeMenu_PopupDialog_Close_Data
	stw_erp WA, 0xfa
	inc1w_erp 0xfa
	extz xwa
	ld xbc, 0x20c33
	add xbc, xwa
	ld (xbc), l
	cp_erpw 0xfa, 0x20, 0x00
	jr c, SeMenu_PopupDialog_Close

SeMenu_PopupDialog_Close_Data:
	ld a, (0x8d38:16)
	cp (0x020c38:24), a
	jr nz, SeMenu_ValueEditor_Init
	cp a, 0x20
	jr c, SeMenu_ValueEditor_Init
	cp a, 0x3f
	jr ugt, SeMenu_ValueEditor_Init
	sub a, 0x20
	extz wa
	sla wa, 2
	lda xbc, (ToneGen_ParamTable_0x326:24)
	ld_sril3 XHL, 0x07, 0xe4, 0xe0
	call (xhl)

SeMenu_ValueEditor_Init:
	cp (0x8d38:16), 32
	jrl nz, SeMenu_ValueEditor_Data3
	cp (0x020c38:24), 0x10
	jrl nz, SeMenu_ValueEditor_Data3
	calr SeMenu_NameEditor_Init
	jrl SeMenu_ListSelector_ScrollDown

SeMenu_ValueEditor_Setup:
	call SeqBuf_SoundEdit_ReadByte
	lda xwa, (0x020c33:24)
	cp hl, 0:i3
	jr lt, SeMenu_ValueEditor_Draw
	stw_erp BC, 0xfa
	inc1w_erp 0xfa
	extz xbc
	ld xde, xwa
	add xde, xbc
	ld (xde), l
	cp_erpw 0xfa, 0x20, 0x00
	jr c, SeMenu_ValueEditor_Setup

SeMenu_ValueEditor_Draw:
	ld e, (xwa + 2)
	lda xbc, (xwa + 5)
	cp e, 0x9
	jr nz, SeMenu_ValueEditor_Increment
	cp (0x8d38:16), 34
	jr nz, SeMenu_ValueEditor_Data3
	ld a, (xbc)
	cp a, 0x22
	jr nz, SeMenu_ValueEditor_HandleInput
	call SeMenu_AltUpdate
	jrl SeMenu_ListSelector_ScrollDown

SeMenu_ValueEditor_HandleInput:
	cp a, 0x10
	jr z, SeMenu_ValueEditor_Data2
	jrl SeMenu_ListSelector_ScrollDown

SeMenu_ValueEditor_Increment:
	cp e, 0xa
	jr z, SeMenu_ValueEditor_Decrement
	cp e, 0x13
	jr nz, SeMenu_ValueEditor_Redraw

SeMenu_ValueEditor_Decrement:
	cp (0x8d38:16), 38
	jr nz, SeMenu_ValueEditor_Data3
	ld a, (xbc)
	cp a, 0x26
	jr nz, SeMenu_ValueEditor_ClampAndStore
	call SeMenu_ControllerUpdate
	jrl SeMenu_ListSelector_ScrollDown

SeMenu_ValueEditor_ClampAndStore:
	cp a, 0x10
	jr nz, SeMenu_ValueEditor_Data3
	calr SeMenu_ListSelector_Data3
	jrl SeMenu_ListSelector_ScrollDown

SeMenu_ValueEditor_Redraw:
	cp e, 0x10
	jr nz, SeMenu_ValueEditor_Complete
	ld a, (0x8d38:16)
	cp a, (xbc)
	jr z, SeMenu_ValueEditor_Cancel
	jrl SeMenu_ListSelector_ScrollDown

SeMenu_ValueEditor_Complete:
	cp e, 0x12
	jr nz, SeMenu_ValueEditor_Data3
	cp (0x8d38:16), 32
	jr nz, SeMenu_ValueEditor_Data3
	ld a, (xbc)
	cp a, 0x20
	jr nz, SeMenu_ValueEditor_Data1

SeMenu_ValueEditor_Cancel:
	call UpdSeSel_ProcessStep
	jrl SeMenu_ListSelector_ScrollDown

SeMenu_ValueEditor_Data1:
	cp a, 0x10
	jr nz, SeMenu_ValueEditor_Data3

SeMenu_ValueEditor_Data2:
	calr SeMenu_ListSelector_Cancel

SeMenu_ValueEditor_Data3:
	jrl SeMenu_ListSelector_ScrollDown

SeMenu_ValueEditor_Data4:
	ld a, (xde + 3)
	ldb_erp A, 0xf8
	extz iz
	jr SeMenu_ListSelector_Init

SeMenu_ValueEditor_Data5:
	stw_erp WA, 0xfa
	inc1w_erp 0xfa
	extz xwa
	ld xbc, 0x20c33
	add xbc, xwa
	ld (xbc), l
	cp_erpw 0xfa, 0x20, 0x00
	jr nc, SeMenu_ListSelector_Setup
	dec 1, iz

SeMenu_ListSelector_Init:
	cp iz, 0:i3
	jr z, SeMenu_ListSelector_Setup
	call SeqBuf_SoundEdit_ReadByte
	cp hl, 0:i3
	jr ge, SeMenu_ValueEditor_Data5

SeMenu_ListSelector_Setup:
	lda xbc, (0x020c33:24)
	ld a, (xbc + 3)
	inc 6, a
	extz wa
	cpw_erp WA, 0xfa
	jr nz, SeMenu_ListSelector_ScrollDown
	cp (xbc), 0x80
	jr nz, SeMenu_ListSelector_Draw
	cp (xbc + 2), 0xff
	jr z, SeMenu_ListSelector_ScrollDown

SeMenu_ListSelector_Draw:
	ld c, (xbc + 5)
	cp c, 0x10
	jr nz, SeMenu_ListSelector_HandleInput
	call SeMenu_HandleMenuChange
	jr SeMenu_ListSelector_ScrollDown

SeMenu_ListSelector_HandleInput:
	ld a, (0x8d38:16)
	cp c, a
	jr nz, SeMenu_ListSelector_ScrollDown
	cp a, 0x20
	jr c, SeMenu_ListSelector_HandleInput_Data
	cp a, 0x3f
	jr ugt, SeMenu_ListSelector_HandleInput_Data
	sub a, 0x20
	extz wa
	sla wa, 2
	lda xbc, (ToneGen_ParamTable_0x326:24)
	ld_sril3 XHL, 0x07, 0xe4, 0xe0
	call (xhl)
	jr SeMenu_ListSelector_ScrollDown

SeMenu_ListSelector_HandleInput_Data:
	cp a, 0xea
	jr nz, SeMenu_ListSelector_ScrollDown

SeMenu_ListSelector_ScrollUp:
	call FDemoText_ParseControlMessage

SeMenu_ListSelector_ScrollDown:
	pop xiz
	ret

SeMenu_ListSelector_Select:
	call SeqBuf_NoteEvent_CheckSongEnd
	cp hl, 0:i3
	ret z

SeMenu_ListSelector_Complete:
	calr SeMenu_PopupDialog_Init
	call SeqBuf_NoteEvent_CheckSongEnd
	cp hl, 0:i3
	jr nz, SeMenu_ListSelector_Complete
	ret

SeMenu_ListSelector_Cancel:
	dec 4, xsp
	lda xwa, (xsp)
	call SeMenu_LoadObjEntries
	lda xbc, (xsp + 2)
	ld wa, 0:i3
	call SeMenu_LoadPartParam
	ld a, (xsp + 2)
	extz wa
	call SeMenu_ApplyFilter
	cp (xsp), 0x0
	jr nz, SeMenu_ListSelector_Data
	ld a, (xsp + 2)
	add a, 0xd
	extz wa
	pushw wa
	pushw 0x22
	jr SeMenu_ListSelector_Data2

SeMenu_ListSelector_Data:
	ld a, (xsp + 2)
	add a, 0xe
	extz wa
	pushw wa
	pushw 0x20

SeMenu_ListSelector_Data2:
	call SeMenu_ShowConfirmDialog
	inc 8, xsp
	ret

SeMenu_ListSelector_Data3:
	dec 2, xsp
	lda xbc, (xsp)
	ld wa, 0:i3
	call SeMenu_LoadPartParam
	ld a, (xsp)
	extz wa
	call SeMenu_ApplySynthParam_Alt
	ld a, (xsp)
	inc 7, a
	extz wa
	pushw wa
	pushw 0x26
	call SeMenu_ShowConfirmDialog
	inc 6, xsp
	ret

SeMenu_NameEditor_Init:
	lda xsp, (xsp - 36)
	lda xwa, (xsp)
	call SeMenu_FillObjTable
	ld c, (xsp + 256)
	extz bc
	ld wa, 1:i3
	call SeMenu_StorePartParam
	pushw 0x1
	pushw 0x20
	call SeMenu_ShowConfirmDialog
	lda xsp, (xsp + 40)
	ret

SeMenu_NameEditor_Setup:
	; --- Wrapper function 1: push xwa/xbc, ld from xiy/xix, call, pop, ret ---
	push xwa
	push xbc
	ld xwa, xiy
	ld xbc, xix
	call GraphicsRender_ProcessEntries
	pop xbc
	pop xwa
	ret
SeMenu_NameEditor_Draw:
	; --- Wrapper function 2: same pattern ---
	push xwa
	push xbc
	ld xwa, xiy
	ld xbc, xix
	call GraphicsRender_Start
	pop xbc
	pop xwa
	ret
SeMenu_NameEditor_HandleInput:
	; --- Wrapper function 3: push xwa, ld xwa=xiy, call, pop, ret ---
	push xwa
	ld xwa, xiy
	call GraphicsRender_ShortByteBlock_0x5
	pop xwa
	ret
SeMenu_NameEditor_HandleInput_Data:
	; --- Wrapper function 4: set flag, push, ld xwa=imm, call, pop, ret ---
	ld	(0x03efa8:24), 0
	push xwa
	ld xwa, 0x000006ca
	call DrawText_LayoutAndRender_Variant1_0x2EB
	pop xwa
	ret
SeMenu_NameEditor_InsertChar:
	; --- Wrapper function 5: same pattern ---
	ld	(0x03efa8:24), 0
	push xwa
	ld xwa, 0x000006ca
	call DrawText_LayoutAndRender_Variant1_0x33F
	pop xwa
	ret
SeMenu_NameEditor_DeleteChar:
	; --- Wrapper function 6: set flag + store 4 regs, call ---
	ld	(0x03efa8:24), 0
	push xwa
	ld	(1740:16), xiy
	ld	(1744:16), ix
	ld	(1746:16), bc
	ld	(1748:16), hl
	ld xwa, 0x000006ca
	call DrawText_LayoutAndRender_Variant1_0x616
	pop xwa
	ret
SeMenu_NameEditor_MoveCursor:
	; --- Wrapper function 7: same as 4/5 pattern ---
	ld	(0x03efa8:24), 0
	push xwa
	ld xwa, 0x000006ca
	call DrawText_LayoutAndRender_Variant1_0x6CA
	pop xwa
	ret
SeMenu_NameEditor_MoveCursor_Data:
	; --- Wrapper function 8: push xwa, ld xwa=xiy, call, pop, ret ---
	push xwa
	ld xwa, xiy
	call DrawText_LayoutAndRender
	pop xwa
	ret
SeMenu_NameEditor_ChangeCase:
	; --- Wrapper function 9 ---
	push xwa
	ld xwa, xiy
	call DrawText_LayoutAndRender_Variant1
	pop xwa
	ret
SeMenu_NameEditor_ChangeCase_Data:
	; --- Wrapper function 10: set flag, push, ld xwa=imm, call, pop, ret ---
	ld	(0x03efa8:24), 0
	push xwa
	ld xwa, 0x000006ca
	call DrawText_LayoutAndRender_Variant1_0x3E7
	pop xwa
	ret
SeMenu_NameEditor_SelectCharSet:
	; --- Wrapper function 11 ---
	push xwa
	ld xwa, xiy
	call ColorBlit_ComputeRectAndBlit
	pop xwa
	ret
SeMenu_NameEditor_SelectCharSet_Data:
	; --- Wrapper function 12: set flag, push, ld xwa=imm, call, pop, ret ---
	ld	(0x03efa8:24), 0
	push xwa
	ld xwa, 0x000006ca
	call DrawText_LayoutAndRender_Variant1_0x3BD
	pop xwa
	ret
SeMenu_NameEditor_Complete:
	; --- Wrapper function 13: set flag, push, ld xwa=imm, call, pop, ret ---
	ld	(0x03efa8:24), 0
	push xwa
	ld xwa, 0x000006ca
	call ColorBlit_ByteData
	pop xwa
	ret
SeMenu_NameEditor_Cancel:
	; --- Wrapper function 14 ---
	push xwa
	ld xwa, xiy
	call DrawFunc_Init
	pop xwa
	ret
SeMenu_NameEditor_Cancel_Data:
	; --- Wrapper function 15 ---
	push xwa
	ld xwa, xiy
	call DrawText_ExtendedLayout
	pop xwa
	ret
SeMenu_NameEditor_Redraw:
	; --- Wrapper function 16 ---
	push xwa
	ld xwa, xiy
	call ColorBlit_WithPaletteSave
	pop xwa
	ret
SeMenu_NameEditor_Redraw_Data:
	; --- Wrapper function 17 ---
	push xwa
	ld xwa, xiy
	call DrawFunc_Init_Variant1_0x108
	pop xwa
	ret


SeMenu_NameEditor_End:
	.byte 0xc1
	jrl	pl, 16320
	max
	jr	nz, 80
	ld	a, (0xc07f:16)
	and	a, 64
	jr	z, 71
	ld	a, (0xc07e:16)
	and	a, 64
	sla	a, 1
	.byte 0xc1
	push	xwa
	ld	a, (xiy+63)
	jr	nz, 19
	ld	w, (1642:16)
	and	w, 127
	or	w, a
	ld	(1642:16), w
	call	SeMenu_NameEdit_CheckBit7
	jr	35
	.byte 0xc1
	push	xwa
	.byte 0x8d
	push	xsp
	push	xde
	jr	nz, 28
	ld	w, (1632:16)
	and	w, 127
	or	w, a
	ld	(1632:16), w
	ld	(0x03efa8:24), 0
	ld	xiy, TuningSystem_Handler_Table_0x242C
	call	SeMenu_NameEditor_HandleInput
	ret

SeMenu_DisplayPartValue:
	push xiz
	ld xiz, xsp
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	ld wa, (xiz + 10)
	ld w, 0xff:opc
	ld de, (xiz + 8)
	ld d, 0x0:opc
	push xiz
	call SwbtWr_QueueMainEvent
	pop xiz
	ld wa, (xiz + 12)
	ld w, 0x7f:opc
	ld de, (xiz + 8)
	ld d, 0x1:opc
	push xiz
	call SwbtWr_QueueMainEvent
	pop xiz
	call BitMapOut_DeltaEncode_Type90Return
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	pop xiz
	ret

SeMenu_DisplayPartValue_Data:	.ascii ">89:;<="
	ld	wa, (xiz+8)
	cp	wa, 50
	jr	nz, 12
	ld	(1740:16), wa
	inc	1, wa
	ld	(1744:16), wa
	jr	30
	cp	wa, 50
	jr	nz, 12
	ld	(1744:16), wa
	dec	1, wa
	ld	(1740:16), wa
	jr	12
	dec	1, wa
	ld	(1740:16), wa
	inc	2, wa
	ld	(1744:16), wa
	ld	wa, (xiz+10)
	cp	wa, 58
	jr	nz, 12
	ld	(1742:16), wa
	inc	1, wa
	ld	(1746:16), wa
	jr	30
	cp	wa, 146
	jr	nz, 12
	ld	(1746:16), wa
	dec	1, wa
	ld	(1742:16), wa
	jr	12
	dec	1, wa
	ld	(1742:16), wa
	inc	2, wa
	ld	(1746:16), wa
	ld	(0x03efa8:24), 0
	call	SeMenu_NameEditor_ChangeCase_Data
	pop	xiy
	.ascii "\\[ZYX^"
	ret
	push xiz
	ld	xiz, xsp
	.ascii "89:;<="
	ld	wa, (xiz+8)
	ld	(1740:16), wa
	ld	wa, (xiz+10)
	ld	(1742:16), wa
	ld	wa, (xiz+12)
	ld	(1744:16), wa
	ld	wa, (xiz+14)
	ld	(1746:16), wa
	ld	(0x03efa8:24), 0
	call	SeMenu_NameEditor_HandleInput_Data
	pop	xiy
	pop	xix
	pop	xhl
	pop	xde
	pop	xbc
	pop	xwa
	pop	xiz
	ret
	push	xiz
	ld	xiz, xsp
	.ascii "89:;<=ž"
	ld	(32:8), 241:io
	cpl	d
	.byte 0x50
	ld	wa, (xiz+10)
	ld	(1742:16), wa
	ld	wa, (xiz+12)
	ld	(1744:16), wa
	ld	wa, (xiz+14)
	ld	(1746:16), wa
	ld	(0x03efa8:24), 0
	call	SeMenu_NameEditor_SelectCharSet_Data
	pop	xiy
	pop	xix
	pop	xhl
	pop	xde
	pop	xbc
	pop	xwa
	pop	xiz
	ret

SeMenu_ShowPopupDialog:
	push xiz
	ld xiz, xsp
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	ld hl, (xiz + 8)
	sub hl, 0x20
	ld xiy, SeMenu_ShowPopupDialog_Draw
	sla hl, 2
	ld_sril3 XIY, 0x07, 0xf4, 0xec
	push xiy
	call SeMenu_WaveformSelect_Handler
	pop xiy
	call (xiy)
	call SeMenu_WaveformSelect_Process
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	pop xiz
	ret

SeMenu_ShowPopupDialog_Draw:
	.long SeMenu_WaveformSelect_Data
	.long SeMenu_NameEdit_DataBlock2
	.long SeMenu_PresetManager_SaveApply
	.long SeMenu_PresetInit_Main
	.long SeMenu_FxEdit_Init
	.long SeMenu_FxEdit_DataBlock1
	.long SeMenu_PresetManager_Data
	.long SeMenu_PresetBrowser_Init
	.long SeMenu_FxEdit_DataBlock2
	.long SeMenu_FxEdit_DataBlock3
	.long SeMenu_PresetBrowser_Data
	.long SeMenu_CompareAndApply_Init
	.long SeMenu_CompareAndApply_Data5
	.long SeMenu_Utility_CopyBlock
	.long SeMenu_Utility_FillBlock
	.long SeMenu_FilterEdit_DataBlock2
	.long SeMenu_Utility_CompareBlock
	.long SeMenu_Utility_FormatSigned_Data
	.long SeMenu_Utility_FormatPercent
	.long SeMenu_Utility_FormatPercent_Data
	.long SeMenu_Utility_FormatHex
	.long SeMenu_Utility_FormatHex_Data
	.long SeMenu_FxEdit_DataBlock4
	.long SeMenu_Utility_End
	.long SeMenu_FilterEdit_Init
	.long SeMenu_FilterEdit_DataBlock1
	.long SeMenu_NameEdit_DataBlock1
	.long SeMenu_FilterEdit_DataBlock5
	.long SeMenu_EqEdit_Init
	.long SeMenu_PresetManager_Load
	.long SeMenu_DataBlock_11
	.long SeMenu_DataBlock_12
	.long SeMenu_WaveformSelect_End
	.long SeMenu_WaveformSelect_End
	.long SeMenu_WaveformSelect_End
	.long SeMenu_WaveformSelect_End
	.long SeMenu_WaveformSelect_End
	.long SeMenu_WaveformSelect_End
	.long SeMenu_WaveformSelect_End
	.long SeMenu_WaveformSelect_End
	.long SeMenu_WaveformSelect_End
	.long SeMenu_WaveformSelect_End
	.long SeMenu_WaveformSelect_End
	.long SeMenu_WaveformSelect_End
	.long SeMenu_WaveformSelect_End
	.long SeMenu_WaveformSelect_End
	.long SeMenu_WaveformSelect_End
	.long SeMenu_WaveformSelect_End

SeMenu_ShowConfirmDialog:
	push xiz
	ld xiz, xsp
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	ld hl, (xiz + 8)
	ld a, (xiz + 10)
	sub hl, 0x20
	ld xiy, SeMenu_ShowConfirmDialog_Data
	sla hl, 2
	ld_sril3 XIY, 0x07, 0xf4, 0xec
	call (xiy)
	or (0xe3e2:16), 8
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	pop xiz
	ret


SeMenu_ShowConfirmDialog_Data:
	.long SeMenu_PresetManager_Init
	.long SeMenu_NameEdit_Dispatch
	.long SeMenu_PatchEdit_Dispatch
	.long SeMenu_FilterEdit_Dispatch
	.long SeMenu_FilterEdit_AltDispatch
	.long SeMenu_FilterEdit_DataBlock3
	.long SeMenu_BankEdit_Dispatch
	.long SeMenu_DrumKit_Dispatch
	.long SeMenu_DataBlock_10
	.long SeMenu_FilterEdit_DataBlock4
	.long Data_UnknownBlock
	.long SeMenu_DataBlock_01
	.long SeMenu_DataBlock_02
	.long SeMenu_DataBlock_03
	.long SeMenu_DataBlock_04
	.long Data_UnknownBlock
	.long SeMenu_DataBlock_05
	.long SeMenu_DataBlock_06
	.long SeMenu_DataBlock_07
	.long SeMenu_DataBlock_08
	.long SeMenu_DataBlock_09
	.long SeMenu_WaveformSelect_End
	.long SeMenu_DataBlock_02
	.long SeMenu_DataBlock_10
	.long SeMenu_FilterEdit_DataBlock4
	.long Data_UnknownBlock
	.long SeMenu_PatchEdit_DataBlock
	.long SeMenu_EqEdit_Dispatch
	.long SeMenu_EqEdit_DrawInit
	.long SeMenu_WaveformSelect_End
	.long SeMenu_DataBlock_13
	.long SeMenu_DataBlock_14
	.long SeMenu_WaveformSelect_End
	.long SeMenu_WaveformSelect_End
	.long SeMenu_WaveformSelect_End
	.long SeMenu_WaveformSelect_End
	.long SeMenu_WaveformSelect_End
	.long SeMenu_WaveformSelect_End
	.long SeMenu_WaveformSelect_End
	.long SeMenu_WaveformSelect_End
	.long SeMenu_WaveformSelect_End
	.long SeMenu_WaveformSelect_End
	.long SeMenu_WaveformSelect_End
	.long SeMenu_WaveformSelect_End
	.long SeMenu_WaveformSelect_End
	.long SeMenu_WaveformSelect_End
	.long SeMenu_WaveformSelect_End
	.long SeMenu_WaveformSelect_End
	.ascii "89:;<=>ò"
	.byte 0xa8, 0xef
	pop	sr
	nop
	nop
	ld	xiy, SeBitmap_EnvCurve5_0x46B
	ld	xix, SeBitmap_EnvCurve5_0x492
	call	SeMenu_NameEditor_Setup
	.byte 0xc1
	pop	xix
	ei	63
	nop
	jr	z, 12
	ld	xiy, SeBitmap_EnvCurve5_0x492
	ld	xix, SeBitmap_EnvCurve5_0x49C
	jr	16
	ld	(0x03efa8:24), 1
	ld	xiy, SeBitmap_EnvCurve5_0x49C
	ld	xix, SeBitmap_EnvCurve5_0x4A6
	call	SeMenu_NameEditor_Setup
	.ascii "^]\\[ZYX"
	ret
	.ascii "89:;<=>"
	.byte 0xc1, 0xae, 0x06
	push	xsp
	.byte 0x01
	jr	nz, 24
	ld	(0x03efa8:24), 0
	ld	xiy, SeBitmap_EnvCurve5_0x313
	ld	xix, SeBitmap_EnvCurve5_0x31D
	call	SeMenu_NameEditor_Setup
	ld	c, 2:opc
	jr	22
	ld	(0x03efa8:24), 0
	ld	xiy, SeBitmap_EnvCurve5_0x313
	ld	xix, SeBitmap_EnvCurve5_0x327
	call	SeMenu_NameEditor_Setup
	ld	c, 4:opc
	ld	w, (1630:16)
	ld	a, c
	sla	a, 1
	dec	1, a
	.byte 0xc8
	swi	7
	jr	c, 34
	push	c
	xor	b, b
	sla	bc, 2
	ld	xiz, SeBitmap_EnvCurve5_0x453
	.byte 0xe3
	reti
	swi	0
	.byte 0xe4
	ld	e, 217:opc
	push	w
	nop
	.byte 0xe3
	reti
	swi	0
	.byte 0xe4
	ld	d, 29:opc
	nop
	cp	xwa, xix
	pop	c
	jr	32
	push	c
	xor	b, b
	sla	bc, 2
	ld	xiz, SeBitmap_EnvCurve5_0x40B
	.byte 0xe3
	reti
	swi	0
	.byte 0xe4
	ld	e, 217:opc
	push	w
	nop
	.byte 0xe3
	reti
	swi	0
	.byte 0xe4
	ld	d, 29:opc
	nop
	cp	xwa, xix
	pop	c
	djnz8	c, -84
	ld	(0x03efa8:24), 1
	ld	xiy, SeBitmap_EnvCurve5_0x4A6
	ld	xix, SeBitmap_EnvCurve5_0x4B0
	call	SeMenu_NameEditor_Setup
	ld	xiy, SeBitmap_EnvCurve5_0x4B0
	call	SeMenu_NameEditor_Redraw
	pop	xiz
	.ascii "]\\[ZYX"
	ret
	push	xiz
	ld	xiz, xsp
	.ascii "89:;<="
	ld	wa, (xiz+8)
	ld	(1740:16), wa
	ld	wa, (xiz+10)
	ld	(1742:16), wa
	ld	wa, (xiz+12)
	ld	(1744:16), wa
	ld	wa, (xiz+14)
	ld	(1746:16), wa
	ld	(0x03efa8:24), 0
	call	SeMenu_NameEditor_Complete
	pop	xiy
	pop	xix
	pop	xhl
	pop	xde
	pop	xbc
	pop	xwa
	pop	xiz
	ret
	ld	(0x03efa8:24), 0
	ld	c, 7:opc
	ld	ix, (1734:16)
	ld	iy, (1736:16)
	pushw	ix
	pushw	iy
	push	c
	call	SeMenu_ShowConfirmDialog_Data_0x331
	pop	c
	popw	iy
	popw	ix
	add	ix, 28
	dec	1, c
	jr	nz, -20
	ld	ix, (1734:16)
	ld	iy, (1736:16)
	ld	(1740:16), ix
	.byte 0xd1
	cpl	d
	push	xwa
	.byte 0xc4
	nop
	ld	(1744:16), ix
	.byte 0xd1, 0xd0, 0x06
	push	xwa
	.byte 0xc8
	nop
	ld	(1742:16), iy
	ld	(1746:16), iy
	.byte 0xd1, 0xd2, 0x06
	push	xwa
	incf
	nop
	call	SeMenu_NameEditor_ChangeCase_Data
	ld	ix, (1734:16)
	ld	iy, (1736:16)
	add	ix, 196
	ld	(1740:16), ix
	ld	(1744:16), ix
	ld	(1742:16), iy
	.byte 0xd1
	cpl	h
	push	xde
	halt
	nop
	ld	(1746:16), iy
	.byte 0xd1, 0xd2, 0x06
	push	xde
	.byte 0x01
	nop
	call	SeMenu_NameEditor_ChangeCase_Data
	ld	ix, (1734:16)
	ld	iy, (1736:16)
	ld	(1740:16), ix
	.byte 0xd1
	cpl	d
	push	xde
	ld	(0:8), 241:io
	.byte 0xd0, 0x06, 0x54
	ld	(1742:16), iy
	ld	(1746:16), iy
	.byte 0xd1, 0xd2, 0x06
	push	xwa
	incf
	nop
	call	SeMenu_NameEditor_ChangeCase_Data
	ld	ix, (1734:16)
	ld	iy, (1736:16)
	ld	(1740:16), ix
	.byte 0xd1
	cpl	d
	push	xde
	halt
	nop
	ld	(1744:16), ix
	.byte 0xd1, 0xd0, 0x06
	push	xde
	pop	sr
	nop
	ld	(1742:16), iy
	.byte 0xd1
	cpl	h
	push	xwa
	.byte 0x01
	nop
	ld	(1746:16), iy
	.byte 0xd1, 0xd2, 0x06
	push	xwa
	reti
	nop
	call	SeMenu_NameEditor_ChangeCase_Data
	ld	ix, (1734:16)
	ld	iy, (1736:16)
	sub	ix, 4
	ld	(1740:16), ix
	ld	(1744:16), ix
	ld	(1742:16), iy
	.byte 0xd1
	cpl	h
	push	xwa
	.byte 0x01
	nop
	ld	(1746:16), iy
	.byte 0xd1, 0xd2, 0x06
	push	xwa
	pushw	7424
	ldw	iy, 0xf0ec
	ld	ix, (1734:16)
	ld	iy, (1736:16)
	ld	(1740:16), ix
	.byte 0xd1
	cpl	d
	push	xwa
	.byte 0x1c
	nop
	ld	(1744:16), ix
	.byte 0xd1, 0xd0, 0x06
	push	xwa
	.byte 0xab
	nop
	ld	(1742:16), iy
	.byte 0xd1
	cpl	h
	push	xwa
	decf
	nop
	ld	(1746:16), iy
	.byte 0xd1, 0xd2, 0x06
	push	xwa
	ret
	nop
	call	SeMenu_NameEditor_ChangeCase_Data
	ret
	ld	(1740:16), ix
	ld	(1744:16), ix
	ld	(1742:16), iy
	.byte 0xd1
	cpl	h
	push	xde
	halt
	nop
	ld	(1746:16), iy
	.byte 0xd1, 0xd2, 0x06
	push	xde
	.byte 0x01
	nop
	pushw	ix
	pushw	iy
	call	SeMenu_NameEditor_InsertChar
	popw	iy
	popw	ix
	ld	(1740:16), ix
	ld	(1742:16), iy
	ld	(1744:16), ix
	.byte 0xd1, 0xd0, 0x06
	push	xwa
	.byte 0x1c
	nop
	ld	(1746:16), iy
	.byte 0xd1, 0xd2, 0x06
	push	xwa
	incf
	nop
	pushw	ix
	pushw	iy
	call	SeMenu_NameEditor_ChangeCase_Data
	popw	iy
	popw	ix
	ld	c, 5:opc
	ld	xiz, SeMenu_ShowConfirmDialog_Data_0x3F4
	ld	hl, (xiz)
	ld	de, (xiz+2)
	add	xiz, 4
	ld	(1740:16), ix
	.byte 0xd1
	cpl	d
	.byte 0x8b
	ld	(1744:16), ix
	.byte 0xd1, 0xd0, 0x06
	and	(xde-15), h
	.byte 0x06, 0x55, 0xd1
	cpl	h
	push	xwa
	.byte 0x01
	nop
	ld	(1746:16), iy
	.byte 0xd1, 0xd2, 0x06
	push	xwa
	reti
	nop
	push	c
	push	xiz
	pushw	ix
	pushw	iy
	call	SeMenu_NameEditor_ChangeCase_Data
	popw	iy
	popw	ix
	pop	xiz
	pop	c
	dec	1, c
	jr	nz, -65
	ld	c, 6:opc
	add	ix, 4
	ld	(1740:16), ix
	ld	(1744:16), ix
	ld	(1742:16), iy
	.byte 0xd1
	cpl	h
	push	xwa
	.byte 0x01
	nop
	ld	(1746:16), iy
	.byte 0xd1, 0xd2, 0x06
	push	xwa
	pushw	0xcb00
	.byte 0x04
	pushw	ix
	pushw	iy
	call	SeMenu_NameEditor_InsertChar
	popw	iy
	popw	ix
	pop	c
	dec	1, c
	jr	nz, -48
	ret
	pop	sr
	nop
	halt
	nop
	reti
	nop
	push	0
	retd	4352
	nop
	zcf
	nop
	pop_a
	nop
	ldf	0
	pop_f
	nop
	.byte 0xc1, 0xae, 0x06
	push	xsp
	.byte 0x01
	jr	nz, 22
	ld	(0x03efa8:24), 0
	ld	xiy, SeBitmap_EnvCurve5_0xD82
	ld	xix, SeBitmap_EnvCurve5_0xD8C
	call	SeMenu_NameEditor_Setup
	jr	20
	ld	(0x03efa8:24), 0
	ld	xiy, SeBitmap_EnvCurve5_0xD78
	ld	xix, SeBitmap_EnvCurve5_0xD82
	call	SeMenu_NameEditor_Setup
	xor	xwa, xwa
	ld	a, (1629:16)
	sla	wa, 2
	.byte 0xc1, 0xae, 0x06
	push	xsp
	.byte 0x01
	jr	nz, 7
	ld	xiz, SeBitmap_EnvCurve5_0xEBC
	jr	5
	ld	xiz, SeBitmap_EnvCurve5_0xEA8
	push	xwa
	add	xiz, xwa
	ld	wa, (xiz)
	ld	(1734:16), wa
	ld	wa, (xiz+2)
	ld	(1736:16), wa
	.byte 0xc1, 0xae, 0x06
	push	xsp
	.byte 0x01
	jr	nz, 7
	ld	xiz, 1634
	jr	5
	ld	xiz, 1640
	xor	xwa, xwa
	ld	a, (1629:16)
	add	xiz, xwa
	call	SeMenu_ShowConfirmDialog_Data_0x4A9
	pop	xwa
	.byte 0xc1, 0xae, 0x06
	push	xsp
	.byte 0x01
	jr	nz, 7
	ld	xiz, SeBitmap_EnvCurve5_0xE9C
	jr	5
	ld	xiz, SeBitmap_EnvCurve5_0xE88
	add	xiz, xwa
	ld	xiy, (xiz)
	ld	xix, xiy
	add	xix, 42
	call	SeMenu_NameEditor_Setup
	ret
	ld	a, (xiz)
	and	a, 224
	srl	a, 5
	cp	a, 3:i3
	jr	nz, 106
	ld	ix, (1734:16)
	ld	iy, (1736:16)
	ld	(1740:16), ix
	.byte 0xd1
	cpl	d
	push	xwa
	.byte 0x01
	nop
	ld	(1744:16), ix
	.byte 0xd1, 0xd0, 0x06
	push	xwa
	ld	e, 0:opc
	ld	(1742:16), iy
	.byte 0xd1
	cpl	h
	push	xwa
	.byte 0x01
	nop
	ld	(1746:16), iy
	.byte 0xd1, 0xd2, 0x06
	push	xwa
	ld	e, 0:opc
	call	SeMenu_NameEditor_Complete
	ld	ix, (1734:16)
	ld	iy, (1736:16)
	ld	(1740:16), ix
	.byte 0xd1
	cpl	d
	push	xwa
	.byte 0x01
	nop
	ld	(1744:16), ix
	.byte 0xd1, 0xd0, 0x06
	push	xwa
	ld	h, 0:opc
	ld	(1742:16), iy
	.byte 0xd1
	cpl	h
	push	xwa
	ld	h, 0:opc
	ld	(1746:16), iy
	.byte 0xd1, 0xd2, 0x06
	push	xwa
	.byte 0x01
	nop
	call	SeMenu_NameEditor_HandleInput_Data
	jr	44
	ld	xiz, SeMenu_ShowConfirmDialog_Data_0x54C
	xor	w, w
	sll	wa, 2
	.byte 0xe3
	reti
	swi	0
	.byte 0xe0
	ld	e, 209:opc
	.byte 0xc6, 0x06
	ld	w, 201:opc
	ldw	(8:8), 0xd0c8:io
	ld	hl, (1736:16)
	mul	l, 40
	add	hl, wa
	ld	ix, hl
	ld	bc, 5:i3
	ldw	hl, 40
	call	SeMenu_NameEditor_DeleteChar
	ret
	.byte 0x96
	rcf
	.byte 0xf1
	nop


SeMenu_WaveformSelect_Init:
	.long SeBitmap_EnvCurve5
	.long SeBitmap_EnvCurve4
	.long SeBitmap_EnvCurve1
	.long SeBitmap_EnvCurve3
	.long SeBitmap_EnvCurve2
	.long SeBitmap_EnvCurve1
SeMenu_WaveformSelect_End:
	ret

SeMenu_WaveformSelect_Handler:
	ld c, 0x0:opc
	ld a, 0xc:opc
	ld a, 0x10:opc
	call Display_DeferOrDrawWall
	ret

SeMenu_WaveformSelect_Process:
	ld c, 0x7:opc
	ld a, 0xc:opc
	call Display_DeferOrUpdateScreen
	ret

SeMenu_WaveformSelect_Apply:
	ld	(0x03efa8:24), 0
	ld	xiz, TuningSystem_Handler_Table_0x1E73
	xor	xwa, xwa
	ld	a, (0x0340e4:24)
	sla	wa, 2
	add	xiz, xwa
	ld	xiy, (xiz)
	ld	xix, (xiz+4)
	call	SeMenu_NameEditor_Setup
	ld	xiy, TuningSystem_Handler_Table_0x1C06
	ld	xix, TuningSystem_Handler_Table_0x1C45
	call	SeMenu_NameEditor_Setup
	ret
SeMenu_WaveformSelect_Data:
	cp	(1720:16), 1
	jr	nz, 6
	call	SeMenu_WaveformSelect_Apply
	jr	95
	ld	(0x03efa8:24), 0
	cp	(1710:16), 1
	jr	z, 20
	ld	xiy, SeBitmap_EnvCurve5_0x19A
	ld	xix, SeBitmap_EnvCurve5_0x2BD
	call	SeMenu_NameEditor_Setup
	call	SeMenu_WaveformSelect_Data_0x6D
	.ascii "h>E&]"
	.byte 0xf1
	nop
	ld	xix, FlashWrite_BlockRef_Type6_0x561
	call	SeMenu_NameEditor_Setup
	call	SeMenu_PresetManager_Data_0x152
	ld	xiy, DrumDetailEdit_Entry_01
	ld	xix, Data_Dispatch_Entry_0x39
	call	SeMenu_NameEditor_Draw
	call	SeMenu_WaveformSelect_Data_0x99
	ld	(0x03efa8:24), 1
	ld	xiy, FlashWrite_BlockRef_Type6_0x561
	ld	xix, DrumDetailEdit_Entry_01
	call	SeMenu_NameEditor_Setup
	ld	(0x03efa8:24), 0
	ret
	ld	(0x03efa8:24), 0
	.byte 0xc1
	jr	lt, 6
	push	xsp
	normal
	jr	z, 16
	ld	xiy, SeBitmap_EnvCurve5_0x2BD
	ld	xix, SeBitmap_EnvCurve5_0x2E9
	call	SeMenu_NameEditor_Setup
	jr	14
	ld	xiy, SeBitmap_EnvCurve5_0x2E9
	ld	xix, SeBitmap_EnvCurve5_0x313
	call	SeMenu_NameEditor_Setup
	ret
	ld	(0x03efa8:24), 0
	ld	a, 13:opc
	push_a
	call	SeMenu_WaveformSelect_Data_0xAF
	pop_a
	inc	1, a
	cp	a, 15
	jr	c, -13
	ret
	xor	xbc, xbc
	xor	w, w
	extz	xwa
	ld	xbc, 1632
	add	xbc, xwa
	ld	d, (xbc)
	cp	d, 0:i3
	jr	z, 15
	ld	xiy, FlashWrite_BlockRef_Type6_0x69A
	ld	(0x03efa8:24), 0
	call	SeMenu_EqEdit_DrawInit_0x15
	ret
SeMenu_PresetManager_Init:
	.byte 0xc1, 0xae, 0x06
	push	xsp
	normal
	jr	z, 7
	call	SeMenu_WaveformSelect_Data_0x6D
	jrl	194
	cp	a, 0:i3
	jr	z, 52
	cp	a, 1:i3
	jr	z, 101
	cp	a, 2:i3
	jr	z, 117
	cp	a, 15
	jr	z, 118
	cp	a, 16
	jrl	z, 134
	cp	a, 13
	jrl	c, 150
	ld	(0x03efa8:24), 0
	ld	xiy, FlashWrite_BlockRef_Type6_0x633
	ld	xix, FlashWrite_BlockRef_Type6_0x655
	call	SeMenu_NameEditor_Draw
	call	SeMenu_WaveformSelect_Data_0x99
	jrl	138
	ld	(0x03efa8:24), 1
	ld	xiy, FlashWrite_BlockRef_Type6_0x690
	ld	xix, FlashWrite_BlockRef_Type6_0x69A
	call	SeMenu_NameEditor_Setup
	ld	a, 0:opc
	ld	xiy, FlashWrite_BlockRef_Type6_0x69A
	call	SeMenu_EqEdit_DrawInit_0x15
	ld	(0x03efa8:24), 1
	ld	xiy, FlashWrite_BlockRef_Type6_0x561
	ld	xix, DrumDetailEdit_Entry_01
	call	SeMenu_NameEditor_Setup
	jr	85
	ld	xiy, DrumDetailEdit_Entry_01
	ld	xix, Data_Dispatch_Entry_0x39
	call	SeMenu_NameEditor_Draw
	call	SeMenu_WaveformSelect_Data_0x99
	jr	65
	call	SeMenu_PresetManager_Data_0x152
	jr	59
	ld	(0x03efa8:24), 0
	ld	xiy, DrumDetailEdit_Entry_02
	ld	xix, DrumDetailEdit_Entry_03
	call	SeMenu_NameEditor_Draw
	jr	37
	ld	(0x03efa8:24), 0
	ld	xiy, DrumDetailEdit_Entry_06
	ld	xix, DrumDetailEdit_Entry_07
	call	SeMenu_NameEditor_Draw
	jr	15
	ld	xiy, FlashWrite_BlockRef_Type6_0x69A
	ld	(0x03efa8:24), 0
	call	SeMenu_EqEdit_DrawInit_0x15
	ret
SeMenu_PresetManager_Load:
	; --- Wrapper 1: conditional XIY/XIX setup + call (28 bytes) ---
	ld	(0x03efa8:24), 0
	cp	(1710:16), 1
	jr nz, SeMenu_PresetManager_End
	ld xiy, 0x00f1616f
	ld xix, 0x00f16239
	call SeMenu_NameEditor_Setup
SeMenu_PresetManager_End:
	ret
SeMenu_PresetManager_Save:
	; --- Wrapper 2: XIY/XIX setup + 2 calls (25 bytes) ---
	ld	(0x03efa8:24), 0
	ld xiy, 0x00f1115e
	ld xix, 0x00f11168
	call SeMenu_NameEditor_Setup
	call Display_DeferOrUpdateScreen_Direct_0xF
	ret


SeMenu_PresetManager_SaveApply:
	call	SeMenu_PresetManager_Data_0x1AF
	call	SeMenu_PresetManager_Save
	ld	xiy, SeBitmap_EnvCurve5_0x612
	ld	xix, SeBitmap_EnvCurve5_0x7B6
	call	SeMenu_NameEditor_Setup
	call	SeMenu_ShowConfirmDialog_Data_0xC0
	call	SeMenu_PresetManager_Data_0xEA
	ld	(0x03efa8:24), 0
	ld	xiy, SeBitmap_EnvCurve5_0x1A03
	ld	xix, SeBitmap_EnvCurve5_0x1B06
	call	SeMenu_NameEditor_Draw
	call	SeMenu_PresetManager_Data_0x1C4
	ret
SeMenu_PresetManager_Data:
	call	SeMenu_PresetManager_Data_0x1AF
	.byte 0xc1, 0xae, 0x06
	push	xsp
	normal
	jr	z, 20
	ld	xiy, TuningSystem_Handler_Table_0x1A15
	ld	xix, TuningSystem_Handler_Table_0x1BD9
	call	SeMenu_NameEditor_Setup
	call	SeMenu_PresetManager_Save
	jr	28
	ld	xiy, TuningSystem_Handler_Table_0x1BD9
	ld	xix, TuningSystem_Handler_Table_0x1C06
	call	SeMenu_NameEditor_Setup
	ld	xiy, TuningSystem_Handler_Table_0x1A20
	ld	xix, TuningSystem_Handler_Table_0x1BD9
	call	SeMenu_NameEditor_Setup
	call	SeMenu_ShowConfirmDialog_Data_0xC0
	call	SeMenu_ShowConfirmDialog_Data_0x10A
	ld	(0x03efa8:24), 0
	ld	xiy, SeBitmap_EnvCurve5_0x1BAD
	ld	xix, SeBitmap_EnvCurve5_0x1BB8
	call	SeMenu_NameEditor_Draw
	call	SeMenu_BankEdit_LoopHelper
	call	SeMenu_PresetManager_Data_0x1C4
	ret
	.byte 0xc1, 0xae, 0x06
	push	xsp
	normal
	jr	nz, 24
	ld	(0x03efa8:24), 0
	ld	xiy, SeBitmap_EnvCurve5_0x7B6
	ld	xix, SeBitmap_EnvCurve5_0x7C0
	call	SeMenu_NameEditor_Setup
	ld	c, 2:opc
	jr	22
	ld	(0x03efa8:24), 0
	ld	xiy, SeBitmap_EnvCurve5_0x7B6
	ld	xix, SeBitmap_EnvCurve5_0x7CA
	call	SeMenu_NameEditor_Setup
	ld	c, 4:opc
	ld	w, (1630:16)
	ld	a, c
	sla	a, 1
	dec	1, a
	.byte 0xc8
	swi	7
	jr	c, 34
	push	c
	xor	b, b
	sla	bc, 2
	ld	xiz, SeBitmap_EnvCurve5_0x82E
	.byte 0xe3
	reti
	swi	0
	.byte 0xe4
	ld	e, 217:opc
	push	w
	nop
	.byte 0xe3
	reti
	swi	0
	.byte 0xe4
	ld	d, 29:opc
	nop
	cp	xwa, xix
	pop	c
	jr	32
	push	c
	xor	b, b
	sla	bc, 2
	ld	xiz, SeBitmap_EnvCurve5_0x7E6
	.byte 0xe3
	reti
	swi	0
	.byte 0xe4
	ld	e, 217:opc
	push	w
	nop
	.byte 0xe3
	reti
	swi	0
	.byte 0xe4
	ld	d, 29:opc
	nop
	cp	xwa, xix
	pop	c
	djnz8	c, -84
	ret
	ld	(0x03efa8:24), 0
	.byte 0xc1, 0xae, 0x06
	push	xsp
	normal
	jr	nz, 4
	ld	c, 2:opc
	jr	2
	ld	c, 4:opc
	ld	w, (1630:16)
	ld	a, c
	sla	a, 1
	dec	1, a
	.byte 0xc8
	swi	7
	jr	c, 34
	push	c
	xor	b, b
	sla	bc, 2
	ld	xiz, SeBitmap_EnvCurve5_0x90A
	.byte 0xe3
	reti
	swi	0
	.byte 0xe4
	ld	e, 217:opc
	push	w
	nop
	.byte 0xe3
	reti
	swi	0
	.byte 0xe4
	ld	d, 29:opc
	nop
	cp	xwa, xix
	pop	c
	jr	32
	push	c
	xor	b, b
	sla	bc, 2
	ld	xiz, SeBitmap_EnvCurve5_0x892
	.byte 0xe3
	reti
	swi	0
	.byte 0xe4
	ld	e, 217:opc
	push	w
	nop
	.byte 0xe3
	reti
	swi	0
	.byte 0xe4
	ld	d, 29:opc
	nop
	cp	xwa, xix
	pop	c
	djnz8	c, -84
	ret
	ld	(0x03efa8:24), 0
	ld	c, 2:opc
	ld	w, (1630:16)
	ld	a, c
	sla	a, 1
	dec	1, a
	.byte 0xc8
	swi	7
	jr	c, 34
	push	c
	xor	b, b
	sla	bc, 2
	ld	xiz, SeBitmap_EnvCurve5_0x986
	.byte 0xe3
	reti
	swi	0
	.byte 0xe4
	ld	e, 217:opc
	push	w
	nop
	.byte 0xe3
	reti
	swi	0
	.byte 0xe4
	ld	d, 29:opc
	nop
	cp	xwa, xix
	pop	c
	jr	32
	push	c
	xor	b, b
	sla	bc, 2
	ld	xiz, SeBitmap_EnvCurve5_0x94C
	.byte 0xe3
	reti
	swi	0
	.byte 0xe4
	ld	e, 217:opc
	push	w
	nop
	.byte 0xe3
	reti
	swi	0
	.byte 0xe4
	ld	d, 29:opc
	nop
	cp	xwa, xix
	pop	c
	djnz8	c, -84
	ret
	ld	(0x03efa8:24), 0
	ld	xiy, SeBitmap_EnvCurve5_0x5E2
	ld	xix, SeBitmap_EnvCurve5_0x60D
	call	SeMenu_NameEditor_Setup
	ret
	ld	(0x03efa8:24), 0
	ld	xiy, SeBitmap_EnvCurve5_0x60D
	ld	xix, SeBitmap_EnvCurve5_0x612
	call	SeMenu_NameEditor_Setup
	ret
	ld	(0x03efa8:24), 0
	ld	xiy, SeBitmap_EnvCurve5_0x50F
	ld	xix, SeBitmap_EnvCurve5_0x5E2
	call	SeMenu_NameEditor_Setup
	ld	(0x03efa8:24), 0
	ret
SeMenu_PresetBrowser_Init:
	; --- Main: call sub, setup XIY/XIX, call F0EC00, 3 more calls (51 bytes) ---
	call SeMenu_PresetBrowser_Navigate
	ld xiy, 0x00f11a37
	ld xix, 0x00f11c49
	call SeMenu_NameEditor_Setup
	call SeMenu_ShowConfirmDialog_Data_0xC0
	call SeMenu_PresetManager_Data_0x60
	ld	(0x03efa8:24), 0
	ld xiy, TuningSys_Param_01
	ld xix, 0x00f132bf
	call SeMenu_NameEditor_Draw
	call SeMenu_PresetBrowser_Select
	ret
SeMenu_PresetBrowser_Navigate:
	; --- Helper 1: clear flag, setup XIY/XIX, call F0EC00 (21 bytes) ---
	ld	(0x03efa8:24), 0
	ld xiy, 0x00f11964
	ld xix, 0x00f11a14
	call SeMenu_NameEditor_Setup
	ret
SeMenu_PresetBrowser_Select:
	; --- Helper 2: clear flag, setup XIY/XIX, call F0EC00 (21 bytes) ---
	ld	(0x03efa8:24), 0
	ld xiy, 0x00f11a14
	ld xix, 0x00f11a19
	call SeMenu_NameEditor_Setup
	ret


SeMenu_PresetBrowser_Data:
	call	SeMenu_PresetBrowser_Navigate
	call	SeMenu_PresetBrowser_Select
	ld	xiy, TuningSystem_Handler_Table_0xE1F
	ld	xix, TuningSystem_Handler_Table_0xFC4
	call	SeMenu_NameEditor_Setup
	call	SeMenu_PresetBrowser_Data_0x3B
	call	SeMenu_ShowConfirmDialog_Data_0xC0
	call	SeMenu_PresetBrowser_Data_0x98
	call	Data_UnknownBlock_0x6E
	ld	(0x03efa8:24), 0
	ld	xiy, TuningSystem_Handler_Table_0x3C
	ld	xix, TuningSystem_Handler_Table_0x8D
	call	SeMenu_NameEditor_Draw
	ret
	ld	(0x03efa8:24), 0
	ld	c, 4:opc
	ld	w, (1630:16)
	ld	a, c
	sla	a, 1
	dec	1, a
	.byte 0xc8
	swi	7
	jr	c, 34
	push	c
	xor	b, b
	sla	bc, 2
	ld	xiz, TuningSystem_Handler_Table_0x1028
	.byte 0xe3
	reti
	swi	0
	.byte 0xe4
	ld	e, 217:opc
	push	w
	nop
	.byte 0xe3
	reti
	swi	0
	.byte 0xe4
	ld	d, 29:opc
	nop
	cp	xwa, xix
	pop	c
	jr	32
	push	c
	xor	b, b
	sla	bc, 2
	ld	xiz, TuningSystem_Handler_Table_0xFE0
	.byte 0xe3
	reti
	swi	0
	.byte 0xe4
	ld	e, 217:opc
	push	w
	nop
	.byte 0xe3
	reti
	swi	0
	.byte 0xe4
	ld	d, 29:opc
	nop
	cp	xwa, xix
	pop	c
	djnz8	c, -84
	ret
	ld	(0x03efa8:24), 1
	ld	xiy, TuningSystem_Handler_Table_0x12D
	ld	xix, TuningSystem_Handler_Table_0x137
	call	SeMenu_NameEditor_Setup
	ld	(0x03efa8:24), 0
	ld	xiy, TuningSystem_Handler_Table_0x17D
	ld	xix, TuningSystem_Handler_Table_0x187
	call	SeMenu_NameEditor_Setup
	ld	xiy, TuningSystem_Handler_Table_0x187
	ld	xix, TuningSystem_Handler_Table_0x191
	call	SeMenu_NameEditor_Setup
	ld	(0x03efa8:24), 2
	ld	xiy, TuningSystem_Handler_Table_0x187
	ld	xix, TuningSystem_Handler_Table_0x191
	call	SeMenu_NameEditor_Setup
	ld	c, 4:opc
	ld	xiy, 1637
	ld	w, (xiy)
	and	w, 32
	jrl	z, 187
	push	w
	push	c
	push	xiy
	ld	d, 4:opc
	sub	d, c
	ld	e, d
	xor	d, d
	sla	de, 2
	ld	xiz, TuningSystem_Handler_Table_0x15F
	ld_rrl xiy, xiz, de
	pushw de
	add	de, 4
	.byte 0xe3
	reti
	swi	0
	.byte 0xe8
	ld	d, 29:opc
	nop
	cp	xwa, xix
	popw	de
	pop	xiy
	pop	c
	pop	w
	ld	(0x03efa8:24), 0
	push	c
	push	xiy
	ld	xiz, TuningSystem_Handler_Table_0x2C1
	ld_rrl xiy, xiz, de
	ld xix, xiy
	add xix, 7
	pushw	de
	call	SeMenu_NameEditor_Setup
	popw	de
	pop	xiy
	pop	c
	push	c
	push	xiy
	ld	a, (xiy)
	and	a, 192
	srl	a, 6
	xor	w, w
	mul	a, 10
	ld	xiz, TuningSystem_Handler_Table_0x295
	ld_rrl xiy, xiz, de
	extz xwa
	add	xiy, xwa
	ld	xix, xiy
	add	xix, 10
	pushw	de
	call	SeMenu_NameEditor_Setup
	popw	de
	pop	xiy
	pop	c
	push	c
	push	xiy
	ld	xiz, TuningSystem_Handler_Table_0xDF
	ld_rrl xiy, xiz, de
	pushw de
	call	SeMenu_NameEditor_HandleInput
	popw	de
	pop	xiy
	pop	c
	ld	(0x03efa8:24), 2
	push	c
	push	xiy
	ld	xiz, TuningSystem_Handler_Table_0x1040
	ld_rrl xiy, xiz, de
	ld xix, xiy
	add xix, 20
	call	SeMenu_NameEditor_Setup
	pop	xiy
	pop	c
	jr	0
	add	xiy, 1
	dec	1, c
	jrl	nz, -206
	ret
SeMenu_CompareAndApply_Init:
	; --- Main dispatch: language check, XIY/XIX setup, calls (111 bytes) ---
	call SeMenu_CompareAndApply_Data
	cp	(1710:16), 1
	jr z, SeMenu_CompareAndApply_Check
	call SeMenu_PresetManager_Save
	ld xiy, 0x00f11e96
	ld xix, 0x00f11f83
	call SeMenu_NameEditor_Setup
	jr t, SeMenu_CompareAndApply_Match
SeMenu_CompareAndApply_Check:
	ld xiy, 0x00f16239
	ld xix, 0x00f162d3
	call SeMenu_NameEditor_Setup
SeMenu_CompareAndApply_Match:
	call SeMenu_ShowConfirmDialog_Data_0xC0
	call SeMenu_PresetManager_Data_0x60
	call SeMenu_ShowConfirmDialog_Data_0x408
	cp	(1710:16), 1
	jr z, SeMenu_CompareAndApply_Apply
	ld	(0x03efa8:24), 0
	ld xiy, 0x00f12f95
	ld xix, 0x00f13020
	call SeMenu_NameEditor_Draw
	jr t, SeMenu_CompareAndApply_End
SeMenu_CompareAndApply_Apply:
	ld	(0x03efa8:24), 0
	ld xiy, 0x00f163aa
	ld xix, 0x00f163e1
	call SeMenu_NameEditor_Draw
SeMenu_CompareAndApply_End:
	call SeMenu_CompareAndApply_Data4
	ret
SeMenu_CompareAndApply_Data:
	; --- Init helper: language-conditional XIX setup (35 bytes) ---
	ld	(0x03efa8:24), 0
	ld xiy, 0x00f11c8f
	cp	(1710:16), 1
	jr z, SeMenu_CompareAndApply_Data2
	ld xix, 0x00f11d41
	jr t, SeMenu_CompareAndApply_Data3
SeMenu_CompareAndApply_Data2:
	ld xix, 0x00f11d06
SeMenu_CompareAndApply_Data3:
	call SeMenu_NameEditor_Setup
	ret
SeMenu_CompareAndApply_Data4:
	; --- Tail helper: clear flag, setup XIY/XIX, call F0EC00 (21 bytes) ---
	ld	(0x03efa8:24), 0
	ld xiy, 0x00f11d41
	ld xix, 0x00f11d46
	call SeMenu_NameEditor_Setup
	ret


SeMenu_CompareAndApply_Data5:
	call	SeMenu_ShowConfirmDialog_Data_0xC0
	call	SeMenu_ShowConfirmDialog_Data_0x10A
	.byte 0x1d, 0xbd
SeMenu_CompareAndApply_Data6:
	swi	3
	.byte 0xf0
	call	SeMenu_PresetManager_Save
	ld	(0x03efa8:24), 2
	ld	xiy, SeBitmap_EnvCurve5_0x108A
	ld	xix, SeBitmap_EnvCurve5_0x109E
	call	SeMenu_NameEditor_Setup
	ld	(0x03efa8:24), 0
	ld	xiy, SeBitmap_EnvCurve5_0xFB5
	ld	xix, SeBitmap_EnvCurve5_0x108A
	call	SeMenu_NameEditor_Setup
	call	SeMenu_CompareAndApply_Data4
	ldw	(1734:16), 56
	ldw	(1736:16), 139
	call	SeMenu_ShowConfirmDialog_Data_0x1F6
	ld	(0x03efa8:24), 0
	ld	xiy, SeMenu_CompareScreen_DataTable_0x141
	ld	xix, SeMenu_CompareScreen_DataTable_0x179
	call	SeMenu_NameEditor_Draw
	ret
SeMenu_Utility_CopyBlock:
	call	SeMenu_CompareAndApply_Data
	cp	(1710:16), 1
	.ascii "f(El "
	.byte 0xf1
	nop
	ld	xix, SeBitmap_EnvCurve5_0x115B
	call	SeMenu_NameEditor_Setup
	call	SeMenu_Utility_CompareBlock_End
	ld	(0x03efa8:24), 2
	ld	xiy, SeBitmap_EnvCurve5_0x1723
	ld	xix, SeBitmap_EnvCurve5_0x172D
	call	SeMenu_NameEditor_Setup
	jr	28
	ld	xiy, SeBitmap_EnvCurve5_0x109E
	ld	xix, SeBitmap_EnvCurve5_0x10B6
	call	SeMenu_NameEditor_Setup
	ld	xiy, DrumDetailEdit_Menu_Table_0x1A4
	ld	xix, DrumDetailEdit_Menu_Table_0x27B
	call	SeMenu_NameEditor_Setup
	call	SeMenu_ShowConfirmDialog_Data_0xC0
	call	SeMenu_ShowConfirmDialog_Data_0x10A
	ld	(0x03efa8:24), 0
	.byte 0xc1, 0xae, 0x06
	push	xsp
	normal
	jr	z, 16
	ld	xiy, SeMenu_CompareScreen_DataTable_0x189
	ld	xix, SeMenu_CompareScreen_DataTable_0x1CF
	call	SeMenu_NameEditor_Draw
	jr	18
	ld	xiy, DrumDetailEdit_Menu_Table_0x2E8
	ld	xix, DrumDetailEdit_Menu_Table_0x32A
	call	SeMenu_NameEditor_Draw
	call	SeMenu_Utility_CopyBlock_0x8B
	call	SeMenu_CompareAndApply_Data4
	ret
	ld	(0x03efa8:24), 0
	ld	a, (1632:16)
	and	a, 32
	.byte 0x66
	.ascii "$Eyd"
	.byte 0xf1
	nop
	ld	xix, DrumDetailEdit_Menu_Table_0x35E
	call	SeMenu_NameEditor_Draw
	ld	(0x03efa8:24), 2
	ld	xiy, SeBitmap_EnvCurve5_0x1723
	ld	xix, SeBitmap_EnvCurve5_0x1739
	call	SeMenu_NameEditor_Setup
	jr	34
	ld	xiy, DrumDetailEdit_Menu_Table_0x35E
	ld	xix, EffectParamEdit_Entry_01
	call	SeMenu_NameEditor_Setup
	ld	(0x03efa8:24), 2
	ld	xiy, SeBitmap_EnvCurve5_0x1739
	ld	xix, SeBitmap_EnvCurve5_0x1743
	call	SeMenu_NameEditor_Setup
	ret
SeMenu_Utility_FillBlock:
	call	SeMenu_CompareAndApply_Data
	ld	xiy, SeBitmap_EnvCurve5_0x115B
	ld	xix, SeBitmap_EnvCurve5_0x12A6
	call	SeMenu_NameEditor_Setup
	ld	(0x03efa8:24), 2
	ld	xiy, SeBitmap_EnvCurve5_0x12A6
	ld	xix, SeBitmap_EnvCurve5_0x12BA
	call	SeMenu_NameEditor_Setup
	call	SeMenu_PresetManager_Save
	ldw	(1734:16), 56
	ldw	(1736:16), 139
	call	SeMenu_ShowConfirmDialog_Data_0x1F6
	call	SeMenu_ShowConfirmDialog_Data_0xC0
	call	SeMenu_ShowConfirmDialog_Data_0x10A
	ld	(0x03efa8:24), 0
	ld	xiy, SeMenu_CompareScreen_DataTable_0x1EB
	ld	xix, SeMenu_CompareScreen_DataTable_0x260
	call	SeMenu_NameEditor_Draw
	call	SeMenu_CompareAndApply_Data4
	ret
SeMenu_Utility_CompareBlock:
	; --- Main: init, 2x XIY/XIX setup, language branch, 3 calls (80 bytes) ---
	call SeMenu_Utility_SearchByte
	ld xiy, 0x00f12391
	ld xix, 0x00f124de
	call SeMenu_NameEditor_Setup
	ld xiy, 0x00f124f3
	ld xix, 0x00f12507
	call SeMenu_NameEditor_Setup
	cp	(1710:16), 1
	jr z, SeMenu_Utility_CompareBlock_Loop
	call SeMenu_Utility_CompareBlock_End
SeMenu_Utility_CompareBlock_Loop:
	call SeMenu_ShowConfirmDialog_Data_0xC0
	call SeMenu_ShowConfirmDialog_Data_0x10A
	call SeMenu_Utility_FormatNumber_End
	ld	(0x03efa8:24), 0
	ld xiy, 0x00f12d66
	ld xix, 0x00f12dc6
	call SeMenu_NameEditor_Draw
	call SeMenu_Utility_FormatNumber_Loop
	ret
SeMenu_Utility_CompareBlock_End:
	; --- Helper: XIY/XIX setup + call F0EC00, call F0F6F5 (19 bytes) ---
	ld xiy, 0x00f12386
	ld xix, 0x00f12391
	call SeMenu_NameEditor_Setup
	call SeMenu_PresetManager_Save
	ret
SeMenu_Utility_SearchByte:
	; --- Init: language-conditional XIX selection (35 bytes) ---
	ld	(0x03efa8:24), 0
	cp	(1710:16), 1
	jr z, SeMenu_Utility_SearchByte_End
	ld xix, 0x00f12341
	jr t, SeMenu_Utility_FormatNumber
SeMenu_Utility_SearchByte_End:
	ld xix, 0x00f122ae
SeMenu_Utility_FormatNumber:
	ld xiy, 0x00f12288
	call SeMenu_NameEditor_Setup
	ret
SeMenu_Utility_FormatNumber_Loop:
	; --- Tail: clear flag, XIY/XIX, call F0EC00 (21 bytes) ---
	ld	(0x03efa8:24), 0
	ld xiy, 0x00f12341
	ld xix, 0x00f12346
	call SeMenu_NameEditor_Setup
	ret
SeMenu_Utility_FormatNumber_End:
	; --- Data setup: load A, store, set flag=2, language-conditional XIX (58 bytes) ---
	ld	a, (0x8d36:16)
	ld	(1656:16), a
	ld	(0x03efa8:24), 2
	ld xiy, 0x00f12364
	cp	(1710:16), 1
	jr z, SeMenu_Utility_FormatNumber_Data
	ld xix, 0x00f12386
	jr t, SeMenu_Utility_FormatSigned
SeMenu_Utility_FormatNumber_Data:
	ld xix, 0x00f1237c
SeMenu_Utility_FormatSigned:
	call SeMenu_NameEditor_Setup
	ld	(0x03efa8:24), 0
	ld xiy, 0x00f12d33
	call SeMenu_NameEditor_HandleInput
	ret


SeMenu_Utility_FormatSigned_Data:
	call	SeMenu_Utility_SearchByte
	ld	xiy, SeBitmap_EnvCurve5_0x13C3
	ld	xix, SeBitmap_EnvCurve5_0x1510
	call	SeMenu_NameEditor_Setup
	ld	xiy, SeBitmap_EnvCurve5_0x1510
	ld	xix, SeBitmap_EnvCurve5_0x1525
	call	SeMenu_NameEditor_Setup
	.byte 0xc1, 0xae, 0x06
	push	xsp
	normal
	jr	z, 4
	call	SeMenu_Utility_CompareBlock_End
	call	SeMenu_ShowConfirmDialog_Data_0xC0
	call	SeMenu_ShowConfirmDialog_Data_0x10A
	call	SeMenu_Utility_FormatNumber_End
	ld	(0x03efa8:24), 0
	ld	xiy, SeBitmap_EnvCurve5_0x1D98
	ld	xix, SeBitmap_EnvCurve5_0x1DF8
	call	SeMenu_NameEditor_Draw
	call	SeMenu_Utility_FormatNumber_Loop
	ret
SeMenu_Utility_FormatPercent:
	call	SeMenu_Utility_SearchByte
	ld	xiy, SeBitmap_EnvCurve5_0x1539
	ld	xix, SeBitmap_EnvCurve5_0x15CF
	call	SeMenu_NameEditor_Setup
	ld	xiy, SeBitmap_EnvCurve5_0x15CF
	ld	xix, SeBitmap_EnvCurve5_0x15E3
	call	SeMenu_NameEditor_Setup
	.byte 0xc1, 0xae, 0x06
	push	xsp
	normal
	jr	z, 4
	call	SeMenu_Utility_CompareBlock_End
	call	SeMenu_ShowConfirmDialog_Data_0xC0
	call	SeMenu_ShowConfirmDialog_Data_0x10A
	call	SeMenu_Utility_FormatNumber_End
	ld	(0x03efa8:24), 0
	ld	xiy, SeBitmap_EnvCurve5_0x1E54
	ld	xix, SeBitmap_EnvCurve5_0x1E87
	call	SeMenu_NameEditor_Draw
	call	SeMenu_Utility_FormatNumber_Loop
	ret
SeMenu_Utility_FormatPercent_Data:
	call	SeMenu_Utility_SearchByte
	ld	xiy, SeBitmap_EnvCurve5_0x1539
	ld	xix, SeBitmap_EnvCurve5_0x15CF
	call	SeMenu_NameEditor_Setup
	ld	xiy, SeBitmap_EnvCurve5_0x15E3
	ld	xix, SeBitmap_EnvCurve5_0x15F8
	call	SeMenu_NameEditor_Setup
	.byte 0xc1, 0xae, 0x06
	push	xsp
	normal
	jr	z, 4
	call	SeMenu_Utility_CompareBlock_End
	call	SeMenu_ShowConfirmDialog_Data_0xC0
	call	SeMenu_ShowConfirmDialog_Data_0x10A
	call	SeMenu_Utility_FormatNumber_End
	ld	(0x03efa8:24), 0
	ld	xiy, SeBitmap_EnvCurve5_0x1E54
	ld	xix, SeBitmap_EnvCurve5_0x1E87
	call	SeMenu_NameEditor_Draw
	call	SeMenu_Utility_FormatNumber_Loop
	ret
SeMenu_Utility_FormatHex:
	call	SeMenu_Utility_SearchByte
	ld	xiy, SeBitmap_EnvCurve5_0x15F8
	ld	xix, SeBitmap_EnvCurve5_0x1702
	call	SeMenu_NameEditor_Setup
	.byte 0xc1, 0xae, 0x06
	push	xsp
	normal
	jr	z, 4
	call	SeMenu_Utility_CompareBlock_End
	call	SeMenu_ShowConfirmDialog_Data_0xC0
	call	SeMenu_ShowConfirmDialog_Data_0x10A
	call	SeMenu_Utility_FormatNumber_End
	ld	(0x03efa8:24), 0
	ld	xiy, SeBitmap_EnvCurve5_0x1E97
	ld	xix, SeBitmap_EnvCurve5_0x1EE8
	call	SeMenu_NameEditor_Draw
	call	SeMenu_Utility_FormatNumber_Loop
	ret
SeMenu_Utility_FormatHex_Data:
	call	SeMenu_Utility_SearchByte
	ld	xiy, SeBitmap_EnvCurve5_0x1702
	ld	xix, SeBitmap_EnvCurve5_0x1719
	call	SeMenu_NameEditor_Setup
	.byte 0xc1, 0xae, 0x06
	push	xsp
	normal
	jr	z, 4
	call	SeMenu_Utility_CompareBlock_End
	call	SeMenu_ShowConfirmDialog_Data_0xC0
	call	SeMenu_ShowConfirmDialog_Data_0x10A
	call	SeMenu_Utility_FormatNumber_End
	call	SeMenu_Utility_FormatNumber_Loop
	ret
SeMenu_Utility_End:
	call	SeMenu_Utility_SearchByte
	ld	xiy, SeBitmap_EnvCurve5_0x1865
	ld	xix, SeBitmap_EnvCurve5_0x18B2
	call	SeMenu_NameEditor_Setup
	ld	xiy, SeBitmap_EnvCurve5_0x1743
	ld	xix, SeBitmap_EnvCurve5_0x1865
	call	SeMenu_NameEditor_Setup
	call	SeMenu_PresetManager_Save
	ld	(0x03efa8:24), 2
	ld	xiy, SeBitmap_EnvCurve5_0x1719
	ld	xix, SeBitmap_EnvCurve5_0x172D
	call	SeMenu_NameEditor_Setup
	call	SeMenu_ShowConfirmDialog_Data_0xC0
	call	SeMenu_ShowConfirmDialog_Data_0x10A
	ld	(0x03efa8:24), 0
	ld	xiy, SeBitmap_EnvCurve5_0x1F00
	ld	xix, SeBitmap_EnvCurve5_0x1F75
	call	SeMenu_NameEditor_Draw
	call	SeMenu_Utility_FormatNumber_Loop
	ret
SeMenu_NameEdit_DataBlock1:
	ld	a, (1632:16)
	and	a, 15
	ld	(1648:16), a
	cp	a, 10
	jr	nz, 7
	ld	xiy, TuningSystem_Handler_Table_0x1F9A
	jr	5
	ld	xiy, TuningSystem_Handler_Table_0x1F7B
	ld	xix, TuningSystem_Handler_Table_0x209A
	call	SeMenu_NameEditor_Setup
	xor	xwa, xwa
	ld	a, (1648:16)
	sla	wa, 3
	ld	xiz, TuningSystem_Handler_Table_0x23BD
	add	xiz, xwa
	ld	xiy, (xiz)
	ld	xix, (xiz+4)
	call	SeMenu_NameEditor_Setup
	ld	xiy, TuningSystem_Handler_Table_0x1E8B
	xor	xbc, xbc
	ld	xiz, FlashWrite_BlockRef_Type6_0x40
	ld	c, (1648:16)
	sla	bc, 2
	.byte 0xe3
	reti
	swi	0
	.byte 0xe4
	ld	d, 29:opc
	nop
	cp	xwa, xix
	ld	a, (1648:16)
	cp	a, 10
	jr	nz, 7
	ld	xiy, TuningSystem_Handler_Table_0x1F5D
	jr	5
	ld	xiy, TuningSystem_Handler_Table_0x1F3F
	ld	xix, TuningSystem_Handler_Table_0x1F7B
	call	SeMenu_NameEditor_Setup
	ld	xiy, TuningSystem_Handler_Table_0x241D
	ld	a, (1648:16)
	cp	a, 10
	jr	nz, 7
	ld	xix, FlashRead_BlockData_Field7
	jr	5
	ld	xix, FlashWrite_BlockHandler_Table
	call	SeMenu_NameEditor_Draw
	xor	xwa, xwa
	ld	a, (1648:16)
	sla	wa, 3
	ld	xiz, FlashWrite_BlockHandler_Table
	add	xiz, xwa
	ld	xiy, (xiz)
	ld	xix, (xiz+4)
	call	SeMenu_NameEditor_Draw
	ret
SeMenu_NameEdit_DataBlock2:
	ld	xiy, FlashWrite_BlockRef_Type6_0x118
	ld	xix, FlashWrite_BlockRef_Type6_0x295
	call	SeMenu_NameEditor_Setup
	ld	xiy, EffectParamEdit_Entry_01
	ld	xix, DrumDetailEdit_Menu_Table_0x3C8
	call	SeMenu_NameEditor_Draw
	call	SeMenu_NameEdit_CheckBit7
	ret
SeMenu_NameEdit_Dispatch:
	; --- Dispatch on A: XIY/XIX setup, 3 paths (53 bytes) ---
	cp	a, 0:i3
	jr z, SeMenu_NameEdit_SetupPath
	cp a, 0x0a
	jr nz, SeMenu_NameEdit_DefaultPath
	call SeMenu_NameEdit_CheckBit7
	jr t, SeMenu_NameEdit_Return
SeMenu_NameEdit_SetupPath:
	ld	(0x03efa8:24), 1
	ld xiy, 0x00f1659f
	ld xix, 0x00f165a9
	call SeMenu_NameEditor_Setup
	ld a, 0x00:opc
SeMenu_NameEdit_DefaultPath:
	ld	(0x03efa8:24), 0
	ld xiy, EffectParam_Edit_Table
	call SeMenu_EqEdit_DrawInit_0x15
SeMenu_NameEdit_Return:
	ret
SeMenu_NameEdit_CheckBit7:
	; --- Helper: conditional XIY based on bit 7 of (0x066a) (32 bytes) ---
	ld	(0x03efa8:24), 0
	ld	a, (1642:16)
	and a, 0x80
	jr nz, SeMenu_NameEdit_Bit7Set
	ld xiy, 0x00f16506
	jr t, SeMenu_NameEdit_HandleInput
SeMenu_NameEdit_Bit7Set:
	ld xiy, 0x00f164f7
SeMenu_NameEdit_HandleInput:
	call SeMenu_NameEditor_HandleInput
	ret


SeMenu_PatchEdit_DataBlock:
	cp	a, 0:i3
	jr	z, 25
	cp	a, 7:i3
	jr	nc, 37
	xor	xbc, xbc
	ld	xiz, FlashWrite_BlockRef_Type6_0x10
	ld	c, (1648:16)
	sla	bc, 2
	ld_rrl xiy, xiz, bc
	jr 21
	ld	xiy, TuningSystem_Handler_Table_0x242C
	ld	xix, FlashRead_BlockData_Field8
	call	SeMenu_NameEditor_Draw
	jr	15
	ld	xiy, FlashRead_BlockHandler_Table
	ld	(0x03efa8:24), 0
	call	SeMenu_EqEdit_DrawInit_0x15
	ret
SeMenu_PatchEdit_Dispatch:
	; --- Dispatch on A: table lookup, 4 paths (92 bytes) ---
	cp	a, 0:i3
	jr z, SeMenu_PatchEdit_SetupPath
	cp	a, 1:i3
	jr z, SeMenu_PatchEdit_CallHelper
	cp a, 0x0e
	jr c, SeMenu_PatchEdit_DefaultPath
	ld xiy, 0x00f12afd
	extz xwa
	xor w, w
	sla	wa, 2
	add xiy, xwa
	ld xiz, xiy
	ld xiy, (xiz)
	ld xix, (xiz+4)
	ld	(0x03efa8:24), 0
	call SeMenu_NameEditor_Draw
	jr t, SeMenu_PatchEdit_Return
SeMenu_PatchEdit_SetupPath:
	ld	(0x03efa8:24), 1
	ld xiy, 0x00f12b49
	ld xix, 0x00f12b53
	call SeMenu_NameEditor_Setup
	ld a, 0x00:opc
	jr t, SeMenu_PatchEdit_DefaultPath
SeMenu_PatchEdit_CallHelper:
	call SeMenu_PresetManager_Data_0xEA
	jr t, SeMenu_PatchEdit_Return
SeMenu_PatchEdit_DefaultPath:
	ld xiy, 0x00f12afd
	ld	(0x03efa8:24), 0
	call SeMenu_EqEdit_DrawInit_0x15
SeMenu_PatchEdit_Return:
	ret


SeMenu_BankEdit_Dispatch:
	; --- Dispatcher: A==0 path with XIY/XIX setup + loop subroutine (187 bytes) ---
	cp	a, 0:i3
	jr z, SeMenu_BankEdit_SetupPath
	call SeMenu_BankEdit_LoopHelper
	jr t, SeMenu_BankEdit_Return
SeMenu_BankEdit_SetupPath:
	ld	(0x03efa8:24), 1
	ld xiy, 0x00f12d01
	ld xix, 0x00f12d0b
	call SeMenu_NameEditor_Setup
	ld xiy, 0x00f12b7b
	call SeMenu_NameEditor_HandleInput
SeMenu_BankEdit_Return:
	ret
SeMenu_BankEdit_LoopHelper:
	; --- Loop over 3 entries: indexed XIY/XIX pointer table lookups ---
	ld	(0x03efa8:24), 0
	ld xiy, 0x00f12c44
	ld xix, 0x00f12c4c
	call SeMenu_NameEditor_Setup
	ld xiy, 0x00f12b86
	ld xix, 0x00f12bae
	call SeMenu_NameEditor_Draw
	ld c, 0x00:opc
	ld xiz, 0x00000664
SeMenu_BankEdit_LoopBody:
	push c
	push xiz
	cp (xiz), 0x00
	jr z, SeMenu_BankEdit_EmptyEntry
	ld xiy, 0x00f12cab
	extz xbc
	xor b, b
	sla	bc, 2
	add xiy, xbc
	ld xiy, (xiy)
	ld xix, xiy
	add xix, 0x00000032
	push xbc
	call SeMenu_NameEditor_Draw
	pop xbc
	ld xiy, 0x00f12cc3
	add xiy, xbc
	ld xiy, (xiy)
	ld xix, xiy
	add xix, 0x00000005
	call SeMenu_NameEditor_Setup
	jr t, SeMenu_BankEdit_LoopContinue
SeMenu_BankEdit_EmptyEntry:
	ld xiy, 0x00f12cb7
	extz xbc
	xor b, b
	sla	bc, 2
	add xiy, xbc
	ld xiy, (xiy)
	ld xix, xiy
	add xix, 0x00000014
	call SeMenu_NameEditor_Setup
SeMenu_BankEdit_LoopContinue:
	pop xiz
	pop c
	add c, 0x01
	add xiz, 0x00000001
	cp	c, 3:i3
	jr nz, SeMenu_BankEdit_LoopBody
	ret


SeMenu_DrumKit_Dispatch:
	cp	a, 0:i3
	jr	z, 32
	cp	a, 13
	jr	z, 51
	cp	a, 16
	jr	nz, 68
	ld	(0x03efa8:24), 0
	ld	xiy, TuningSys_Param_01_0xAE
	ld	xix, TuningSys_Param_01_0xC4
	call	SeMenu_NameEditor_Draw
	jr	61
	ld	(0x03efa8:24), 1
	ld	xiy, TuningSys_Param_01_0x24A
	ld	xix, TuningSys_Param_01_0x254
	call	SeMenu_NameEditor_Setup
	ld	a, 0:opc
	jr	22
	ld	(0x03efa8:24), 1
	ld	xiy, TuningSys_Param_01_0x254
	ld	xix, TuningSys_Param_01_0x25E
	call	SeMenu_NameEditor_Setup
	ld	a, 13:opc
	ld	(0x03efa8:24), 0
	ld	xiy, TuningSys_Param_01_0x25E
	call	SeMenu_EqEdit_DrawInit_0x15
	ret
Data_UnknownBlock:
	cp	a, 0:i3
	jr	z, 14
	cp	a, 3:i3
	jr	z, 36
	cp	a, 4:i3
	jr z, 54
	cp a, 5:i3
	.ascii "oHhLò"
	.byte 0xa8, 0xef
	pop	sr
	nop
	.byte 0x01
	ld	xiy, TuningSystem_Handler_Table_0x123
	ld	xix, TuningSystem_Handler_Table_0x12D
	call	SeMenu_NameEditor_Setup
	call	Data_UnknownBlock_0x6E
	jr	65
	ld	(0x03efa8:24), 0
	ld	xiy, TuningSystem_Handler_Table_0x69
	ld	xix, TuningSystem_Handler_Table_0x82
	call	SeMenu_NameEditor_Draw
	jr	43
	ld	(0x03efa8:24), 0
	ld	xiy, TuningSystem_Handler_Table_0x3C
	ld	xix, TuningSystem_Handler_Table_0x55
	call	SeMenu_NameEditor_Draw
	jr	21
	call	SeMenu_PresetBrowser_Data_0x98
	jr	15
	ld	(0x03efa8:24), 0
	ld	xiy, TuningSystem_Handler_Table_0xCB
	call	SeMenu_EqEdit_DrawInit_0x15
	ret
	ld	(0x03efa8:24), 0
	ld	xiy, TuningSystem_Handler_Table_0x173
	ld	xix, TuningSystem_Handler_Table_0x17D
	call	SeMenu_NameEditor_Setup
	ld	c, (1632:16)
	xor	b, b
	sla	bc, 2
	ld	xiz, TuningSystem_Handler_Table_0x1E1
	ld_rrl xiy, xiz, bc
	ld xix, xiy
	add xix, 20
	call	SeMenu_NameEditor_Setup
	ret
	.byte 0xc1, 0xae, 0x06
	push	xsp
	normal
	jr	nz, 6
	cp	a, 3:i3
	jr	c, 15
	jr	5
	cp	a, 9
	jr	c, 8
	push_a
	call	SeMenu_ShowConfirmDialog_Data_0x408
	pop_a
	jr	55
	cp	a, 0:i3
	jr	nz, 51
	call	SeMenu_ShowConfirmDialog_Data_0x408
	.byte 0xc1, 0xae, 0x06
	push	xsp
	normal
	jr	z, 18
	ld	(0x03efa8:24), 1
	ld	xiy, SeMenu_CompareScreen_DataTable_0x10F
	ld	xix, SeMenu_CompareScreen_DataTable_0x119
	jr	16
	ld	(0x03efa8:24), 1
	ld	xiy, DrumDetailEdit_Menu_Table_0x2C6
	ld	xix, DrumDetailEdit_Menu_Table_0x2D0
	call	SeMenu_NameEditor_Setup
	ld	a, 0:opc
	ld	(0x03efa8:24), 0
	.byte 0xc1, 0xae, 0x06
	push	xsp
	normal
	jr	z, 7
	ld	xiy, SeMenu_CompareScreen_DataTable_0xDB
	jr	5
	ld	xiy, DrumDetailEdit_Menu_Table_0x2B2
	call	SeMenu_EqEdit_DrawInit_0x15
	ret
	ld	(0x03efa8:24), 0
	ld	xiy, SeMenu_CompareScreen_DataTable_0x179
	call	SeMenu_EqEdit_DrawInit_0x15
	ret
	.byte 0xc1, 0xae, 0x06
	push	xsp
	normal
	jr	z, 7
	ld	xiy, SeMenu_CompareScreen_DataTable_0x1CF
	jr	30
	cp	a, 0:i3
	jr	nz, 21
	ld	(0x03efa8:24), 0
	ld	xiy, DrumDetailEdit_Menu_Table_0x32A
	call	SeMenu_EqEdit_DrawInit_0x15
	call	SeMenu_Utility_CopyBlock_0x8B
	jr	15
	ld	xiy, DrumDetailEdit_Menu_Table_0x32A
	ld	(0x03efa8:24), 0
	call	SeMenu_EqEdit_DrawInit_0x15
	ret
	ld	(0x03efa8:24), 0
	ld	xiy, SeMenu_CompareScreen_DataTable_0x278
	call	SeMenu_EqEdit_DrawInit_0x15
	ret
	cp	a, 5:i3
	jr	nz, 22
	ld	(0x03efa8:24), 0
	ld	xiy, SeBitmap_EnvCurve5_0x1DDA
	ld	xix, SeBitmap_EnvCurve5_0x1DF8
	call	SeMenu_NameEditor_Draw
	jr	15
	ld	(0x03efa8:24), 0
	ld	xiy, SeBitmap_EnvCurve5_0x1DF8
	call	SeMenu_EqEdit_DrawInit_0x15
	ret
	cp	a, 5:i3
	jr	nz, 22
	ld	(0x03efa8:24), 0
	ld	xiy, SeBitmap_EnvCurve5_0x1DDA
	ld	xix, SeBitmap_EnvCurve5_0x1DF8
	call	SeMenu_NameEditor_Draw
	jr	15
	ld	(0x03efa8:24), 0
	ld	xiy, SeBitmap_EnvCurve5_0x1DF8
	call	SeMenu_EqEdit_DrawInit_0x15
	ret
	ld	(0x03efa8:24), 0
	ld	xiy, SeBitmap_EnvCurve5_0x1E87
	call	SeMenu_EqEdit_DrawInit_0x15
	ret
	ld	(0x03efa8:24), 0
	ld	xiy, SeBitmap_EnvCurve5_0x1E87
	call	SeMenu_EqEdit_DrawInit_0x15
	ret
	ld	(0x03efa8:24), 0
	ld	xiy, SeBitmap_EnvCurve5_0x1EE8
	call	SeMenu_EqEdit_DrawInit_0x15
	ret
	cp	a, 0:i3
	jr	nz, 22
	ld	(0x03efa8:24), 1
	ld	xiy, SeMenu_CompareScreen_DataTable_0x10
	ld	xix, SeMenu_CompareScreen_DataTable_0x24
	call	SeMenu_NameEditor_Setup
	ld	a, 0:opc
	ld	(0x03efa8:24), 0
	ld	xiy, SeMenu_CompareScreen_DataTable_0x24
	call	SeMenu_EqEdit_DrawInit_0x15
	ret
	ld	(0x03efa8:24), 0
	ld	xiy, TuningSystem_Handler_Table_0x2D1
	ld	xix, TuningSystem_Handler_Table_0x3C9
	call	SeMenu_NameEditor_Setup
	ld	xiy, TuningSystem_Handler_Table_0x3C9
	ld	xix, TuningSystem_Handler_Table_0x3F1
	call	SeMenu_NameEditor_Draw
	call	Data_UnknownBlock_0x23D
	ret
	ld	l, (1632:16)
	cp	l, 1:i3
	jr	z, 4
	ld	l, 17:opc
	jr	2
	ld	l, 16:opc
	ld	(0x90ea:16), l
	ld	h, (1633:16)
	dec	1, h
	ld	(0x90eb:16), h
	ld	a, (0x8d3a:16)
	ld	(0x90ec:16), a
	ld	xwa, 0x90ea
	call	SndParam_ApplyProgramChange
	ld	a, (0x90ed:16)
	ld	c, (0x90ee:16)
	ld	xde, 0x020c13
	call	SndParam_ApplyProgramChangeAsync
	ld	c, 20:opc
	xor	hl, hl
	ldw	ix, 5889
	ld	xiy, 0x020c13
	push	xwa
	push	xbc
	push	d
	ld	xwa, xiy
	ld	xbc, xiy
	ld	d, 0:opc
	cp	d, 16
	jr	z, 29
	push	xwa
	push	xbc
	push	d
	call	FontGlyph_ByteData_0x11
	pop	d
	pop	xbc
	pop	xwa
	add	xwa, 1
	add	xbc, 1
	add	d, 1
	jr	-34
	pop	d
	pop	xbc
	pop	xwa
	ld	(xiy-3), c
	ld	(xiy-2), ix
	sub	xiy, 4
	call	SeMenu_NameEditor_ChangeCase
	ret
	ld	(0x03efa8:24), 0
	.byte 0xc1, 0xae, 0x06
	push	xsp
	normal
	jr	z, 14
	ld	xiy, TuningSystem_Handler_Table_0x3F4
	ld	xix, TuningSystem_Handler_Table_0x416
	call	SeMenu_NameEditor_Setup
	ld	(0x03efa8:24), 0
	ld	xiy, TuningSystem_Handler_Table_0x416
	ld	xix, TuningSystem_Handler_Table_0x5F9
	call	SeMenu_NameEditor_Setup
	jr	14
	ld	xiy, TuningSystem_Handler_Table_0x442
	ld	xix, TuningSystem_Handler_Table_0x5F9
	call	SeMenu_NameEditor_Setup
	.byte 0xc1
	jr	le, 6
	push	xsp
	rcf
	jr	z, 41
	.byte 0xc1
	jr	le, 6
	push	xsp
	push	sr
	.ascii "fDEJ:"
	ld	(0x4400:16), ix
	push	xde
	ld	(7424:16), 236
	.byte 0xf0
	ld	xiy, TuningSystem_Handler_Table_0x633
	ld	xix, TuningSystem_Handler_Table_0x64F
	call	SeMenu_NameEditor_Draw
	call	Data_UnknownBlock_0x46B
	.ascii "hBE@:ñ"
	nop
	ld	xix, TuningSystem_Handler_Table_0x603
	call	SeMenu_NameEditor_Setup
	ld	xiy, TuningSystem_Handler_Table_0x617
	ld	xix, TuningSystem_Handler_Table_0x633
	call	SeMenu_NameEditor_Draw
	call	Data_UnknownBlock_0x46B
	.ascii "h ET:"
	.byte 0xf1
	nop
	ld	xix, TuningSystem_Handler_Table_0x617
	call	SeMenu_NameEditor_Setup
	ld	xiy, TuningSystem_Handler_Table_0x64F
	ld	xix, TuningSystem_Handler_Table_0x66B
	call	SeMenu_NameEditor_Draw
	call	Data_UnknownBlock_0x46B
	ret
	ld	xiy, TuningSystem_Handler_Table_0x3C9
	ld	xix, TuningSystem_Handler_Table_0x3F1
	call	SeMenu_NameEditor_Draw
	call	Data_UnknownBlock_0x23D
	ret
	cp	a, 0:i3
	jr	z, 92
	cp	a, 1:i3
	jr	z, 4
	cp	a, 2:i3
	jr	z, 119
	ld	(0x03efa8:24), 1
	ld	xiy, TuningSystem_Handler_Table_0x675
	ld	xix, TuningSystem_Handler_Table_0x67F
	call	SeMenu_NameEditor_Setup
	ld	(0x03efa8:24), 0
	.byte 0xc1
	jr	le, 6
	push	xsp
	decf
	jr	z, 19
	.byte 0xc1
	jr	le, 6
	push	xsp
	push	sr
	jr	z, 24
	ld	xiy, TuningSystem_Handler_Table_0x617
	ld	xix, TuningSystem_Handler_Table_0x633
	jr	22
	ld	xiy, TuningSystem_Handler_Table_0x633
	ld	xix, TuningSystem_Handler_Table_0x64F
	jr	10
	ld	xiy, TuningSystem_Handler_Table_0x64F
	ld	xix, TuningSystem_Handler_Table_0x66B
	call	SeMenu_NameEditor_Draw
	call	Data_UnknownBlock_0x46B
	jr	125
	ld	(0x03efa8:24), 1
	ld	xiy, TuningSystem_Handler_Table_0x66B
	ld	xix, TuningSystem_Handler_Table_0x67F
	call	SeMenu_NameEditor_Setup
	ld	xiy, TuningSystem_Handler_Table_0x628
	call	SeMenu_NameEditor_HandleInput
	call	Data_UnknownBlock_0x46B
	jr	90
	ld	(0x03efa8:24), 1
	ld	xiy, TuningSystem_Handler_Table_0x66B
	ld	xix, TuningSystem_Handler_Table_0x67F
	call	SeMenu_NameEditor_Setup
	ld	(0x03efa8:24), 0
	.byte 0xc1
	jr	le, 6
	push	xsp
	decf
	jr	z, 23
	.byte 0xc1
	jr	le, 6
	push	xsp
	push	sr
	.ascii "f E^:"
	.byte 0xf1
	nop
	ld	xix, TuningSystem_Handler_Table_0x633
	call	SeMenu_NameEditor_Draw
	jr	30
	ld	xiy, TuningSystem_Handler_Table_0x633
	ld	xix, TuningSystem_Handler_Table_0x64F
	call	SeMenu_NameEditor_Draw
	jr	14
	ld	xiy, TuningSystem_Handler_Table_0x64F
	ld	xix, TuningSystem_Handler_Table_0x66B
	call	SeMenu_NameEditor_Draw
	call	Data_UnknownBlock_0x46B
	ret
	xor	wa, wa
	ld	a, (1633:16)
	div	a, 16
	ld	xiz, TuningSystem_Handler_Table_0x6FF
	xor	hl, hl
	ld	l, w
	sla	hl, 1
	ld_rrw ix, xiz, hl
	ld (1740:16), ix
	add	ix, 8
	ld	(1744:16), ix
	ld	xiz, TuningSystem_Handler_Table_0x71F
	xor	hl, hl
	ld	l, a
	sla	hl, 1
	ld_rrw ix, xiz, hl
	ld (1742:16), ix
	add	ix, 14
	ld	(1746:16), ix
	call	SeMenu_NameEditor_MoveCursor
	ret
SeMenu_PresetInit_Main:
	; --- Main: init, XIY/XIX setup, 2 loops, 9 calls (63 bytes) ---
	call SeMenu_PresetManager_Data_0x1AF
	call SeMenu_PresetManager_Save
	ld xiy, 0x00f13f72
	ld xix, 0x00f140ef
	call SeMenu_NameEditor_Setup
	call SeMenu_ShowConfirmDialog_Data_0xC0
	call SeMenu_PresetManager_Data_0x60
	ld	(0x03efa8:24), 0
	ld xiy, 0x00f144e7
	ld xix, 0x00f1459c
	call SeMenu_NameEditor_Draw
	call SeMenu_PresetInit_Loop1
	call SeMenu_PresetInit_Loop2
	call SeMenu_PresetManager_Data_0x1C4
	ret
SeMenu_PresetInit_Loop1:
	; --- Loop 1: iterate A from 2 to 5, call table lookup (15 bytes) ---
	ld a, 0x02:opc
SeMenu_PresetInit_Loop1Body:
	push_a
	call SeMenu_PresetInit_TableLookup1
	pop_a
	inc 1, a
	cp	a, 6:i3
	jr c, SeMenu_PresetInit_Loop1Body
	ret
SeMenu_PresetInit_TableLookup1:
	; --- Table lookup 1: index into 0x660, test bit 7 of D (36 bytes) ---
	xor xbc, xbc
	xor w, w
	extz xwa
	ld xbc, 0x00000660
	add xbc, xwa
	ld d, (xbc)
	and d, 0x80
	jr z, SeMenu_PresetInit_Lookup1Return
	ld xiy, 0x00f14640
	ld	(0x03efa8:24), 0
	call SeMenu_EqEdit_DrawInit_0x15
SeMenu_PresetInit_Lookup1Return:
	ret
SeMenu_PresetInit_Loop2:
	; --- Loop 2: iterate A from 0x0c to 0x0f, call table lookup (16 bytes) ---
	ld a, 0x0c:opc
SeMenu_PresetInit_Loop2Body:
	push_a
	call SeMenu_PresetInit_TableLookup2
	pop_a
	inc 1, a
	cp a, 0x10
	jr c, SeMenu_PresetInit_Loop2Body
	ret
SeMenu_PresetInit_TableLookup2:
	; --- Table lookup 2: index into 0x660, test D != 0 (35 bytes) ---
	xor xbc, xbc
	xor w, w
	extz xwa
	ld xbc, 0x00000660
	add xbc, xwa
	ld d, (xbc)
	cp	d, 0:i3
	jr z, SeMenu_PresetInit_Lookup2Return
	ld xiy, 0x00f145c4
	ld	(0x03efa8:24), 0
	call SeMenu_EqEdit_DrawInit_0x15
SeMenu_PresetInit_Lookup2Return:
	ret


SeMenu_FxEdit_Init:
	call	SeMenu_PresetManager_Data_0x1D9
	ld	(0x03efa8:24), 0
	ld	xiy, TuningSystem_Handler_Table_0xCB2
	ld	xix, TuningSystem_Handler_Table_0xD22
	call	SeMenu_NameEditor_Setup
	ld	(0x03efa8:24), 2
	ld	xiy, TuningSystem_Handler_Table_0xCA8
	ld	xix, TuningSystem_Handler_Table_0xCB2
	call	SeMenu_NameEditor_Setup
	ldw	(1734:16), 47
	ldw	(1736:16), 51
	call	SeMenu_ShowConfirmDialog_Data_0x1F6
	call	SeMenu_ShowConfirmDialog_Data_0xC0
	call	SeMenu_ShowConfirmDialog_Data_0x10A
	ld	(0x03efa8:24), 0
	ld	xiy, TuningSystem_Handler_Table_0x126F
	ld	xix, TuningSystem_Handler_Table_0x12B6
	call	SeMenu_NameEditor_Draw
	ret
SeMenu_FxEdit_DataBlock1:
	call	SeMenu_PresetManager_Data_0x1D9
	ld	(0x03efa8:24), 0
	ld	xiy, TuningSystem_Handler_Table_0xD22
	ld	xix, TuningSystem_Handler_Table_0xDF2
	call	SeMenu_NameEditor_Setup
	ld	(0x03efa8:24), 2
	ld	xiy, TuningSystem_Handler_Table_0xCA8
	ld	xix, TuningSystem_Handler_Table_0xCB2
	call	SeMenu_NameEditor_Setup
	call	SeMenu_ShowConfirmDialog_Data_0xC0
	call	SeMenu_ShowConfirmDialog_Data_0x10A
	ld	(0x03efa8:24), 0
	ld	xiy, TuningSystem_Handler_Table_0x12FC
	ld	xix, TuningSystem_Handler_Table_0x132F
	call	SeMenu_NameEditor_Draw
	ret
SeMenu_FxEdit_DataBlock2:
	call	SeMenu_PresetBrowser_Navigate
	ld	xiy, SeBitmap_EnvCurve5_0xC7B
	ld	xix, SeBitmap_EnvCurve5_0xCC1
	call	SeMenu_NameEditor_Setup
	call	SeMenu_PresetManager_Save
	call	SeMenu_Utility_End_0x12
	call	SeMenu_PresetBrowser_Select
	ret
SeMenu_FxEdit_DataBlock3:
	call	SeMenu_PresetBrowser_Navigate
	call	SeMenu_FilterEdit_Init_0x4
	call	SeMenu_PresetBrowser_Select
	ret
SeMenu_FxEdit_DataBlock4:
	call	SeMenu_Utility_SearchByte
	ld	xiy, SeBitmap_EnvCurve5_0xFB5
	ld	xix, SeBitmap_EnvCurve5_0x1069
	call	SeMenu_NameEditor_Setup
	ld	(0x03efa8:24), 2
	ld	xiy, SeBitmap_EnvCurve5_0x108A
	ld	xix, SeBitmap_EnvCurve5_0x109E
	call	SeMenu_NameEditor_Setup
	ld	(0x03efa8:24), 0
	ld	xiy, TuningSystem_Handler_Table_0xDF2
	ld	xix, TuningSystem_Handler_Table_0xE1F
	call	SeMenu_NameEditor_Setup
	call	SeMenu_PresetManager_Save
	call	SeMenu_CompareAndApply_Data6_0x32
	call	SeMenu_Utility_FormatNumber_Loop
	ret
SeMenu_FilterEdit_Init:
	call	SeMenu_Utility_SearchByte
	ld	xiy, SeBitmap_EnvCurve5_0x18B2
	ld	xix, SeBitmap_EnvCurve5_0x19EF
	call	SeMenu_NameEditor_Setup
	ld	(0x03efa8:24), 2
	ld	xiy, SeBitmap_EnvCurve5_0x19EF
	ld	xix, SeBitmap_EnvCurve5_0x1A03
	call	SeMenu_NameEditor_Setup
	call	SeMenu_PresetManager_Save
	ldw	(1734:16), 56
	ldw	(1736:16), 139
	call	SeMenu_ShowConfirmDialog_Data_0x1F6
	call	SeMenu_ShowConfirmDialog_Data_0xC0
	call	SeMenu_ShowConfirmDialog_Data_0x10A
	ld	(0x03efa8:24), 0
	ld	xiy, TuningSystem_Handler_Table_0x1343
	ld	xix, TuningSystem_Handler_Table_0x139A
	call	SeMenu_NameEditor_Draw
	call	SeMenu_Utility_FormatNumber_Loop
	ret
SeMenu_FilterEdit_DataBlock1:
	call	SeMenu_Utility_SearchByte
	call	SeMenu_PresetBrowser_Data_0x8
	call	SeMenu_Utility_FormatNumber_Loop
	ret
SeMenu_FilterEdit_DataBlock2:
	call	SeMenu_CompareAndApply_Data
	call	SeMenu_PresetBrowser_Data_0x8
	call	SeMenu_CompareAndApply_Data4
	ret
SeMenu_FilterEdit_Dispatch:
	cp a, 0:i3
	jr z, 61
	cp	a, 1:i3
	jr	z, 31
	cp	a, 11
	jr	c, 74
	ld	(0x03efa8:24), 0
	ld	xiy, TuningSystem_Handler_Table_0x110E
	ld	xix, TuningSystem_Handler_Table_0x114A
	call	SeMenu_NameEditor_Draw
	call	SeMenu_PresetInit_Loop2
	jr	63
	ld	(0x03efa8:24), 0
	ld	xiy, TuningSystem_Handler_Table_0x10A0
	ld	xix, TuningSystem_Handler_Table_0x10DC
	call	SeMenu_NameEditor_Draw
	call	SeMenu_PresetInit_Loop1
	jr	37
	ld	(0x03efa8:24), 1
	ld	xiy, TuningSystem_Handler_Table_0x123D
	ld	xix, TuningSystem_Handler_Table_0x1247
	call	SeMenu_NameEditor_Setup
	ld	a, 0:opc
	ld	xiy, TuningSystem_Handler_Table_0x117D
	ld	(0x03efa8:24), 0
	call	SeMenu_EqEdit_DrawInit_0x15
	ret
SeMenu_FilterEdit_AltDispatch:
	cp	a, 0:i3
	jr	nz, 22
	ld	(0x03efa8:24), 1
	ld	xiy, TuningSystem_Handler_Table_0x12CA
	ld	xix, TuningSystem_Handler_Table_0x12D4
	call	SeMenu_NameEditor_Setup
	ld	a, 0:opc
	ld	(0x03efa8:24), 0
	ld	xiy, TuningSystem_Handler_Table_0x12B6
	call	SeMenu_EqEdit_DrawInit_0x15
	ret
SeMenu_FilterEdit_DataBlock3:
	cp	a, 0:i3
	jr	nz, 22
	ld	(0x03efa8:24), 1
	ld	xiy, TuningSystem_Handler_Table_0x12CA
	ld	xix, TuningSystem_Handler_Table_0x12D4
	call	SeMenu_NameEditor_Setup
	ld	a, 0:opc
	ld	(0x03efa8:24), 0
	ld	xiy, TuningSystem_Handler_Table_0x132F
	call	SeMenu_EqEdit_DrawInit_0x15
	ret
SeMenu_FilterEdit_DataBlock4:
	ld	(0x03efa8:24), 0
	ld	xiy, TuningSystem_Handler_Table_0x139A
	call	SeMenu_EqEdit_DrawInit_0x15
	ret
SeMenu_FilterEdit_DataBlock5:
	call	SeMenu_EqEdit_SetupHelper1
	.byte 0xc1, 0xae, 0x06
	push	xsp
	normal
	jr	z, 26
	ld	(0x03efa8:24), 0
	ld	xiy, TuningSystem_Handler_Table_0x13F6
	ld	xix, TuningSystem_Handler_Table_0x14D6
	call	SeMenu_NameEditor_Setup
	call	SeMenu_Utility_CompareBlock_End
	jr	41
	ld	(0x03efa8:24), 0
	ld	xiy, TuningSystem_Handler_Table_0x13F6
	ld	xix, TuningSystem_Handler_Table_0x14A5
	call	SeMenu_NameEditor_Setup
	ld	xiy, TuningSystem_Handler_Table_0x14D6
	ld	xix, TuningSystem_Handler_Table_0x14F5
	call	SeMenu_NameEditor_Setup
	ld	xiy, TuningSystem_Handler_Table_0x15B0
	jr	5
	ld	xiy, TuningSystem_Handler_Table_0x1592
	ld	(0x03efa8:24), 0
	ld	xix, TuningSystem_Handler_Table_0x161F
	call	SeMenu_NameEditor_Draw
	call	SeMenu_EqEdit_SetupHelper2
	ret
SeMenu_EqEdit_Init:
	; --- Main: call helpers, setup XIY/XIX pairs, call F0EC00/F0EC0D (53 bytes) ---
	call SeMenu_EqEdit_SetupHelper1
	call SeMenu_PresetManager_Save
	ld	(0x03efa8:24), 0
	ld xiy, 0x00f1493c
	ld xix, 0x00f149d9
	call SeMenu_NameEditor_Setup
	ld	(0x03efa8:24), 0
	ld xiy, 0x00f14e28
	ld xix, 0x00f14e46
	call SeMenu_NameEditor_Draw
	call SeMenu_EqEdit_SetupHelper2
	ret
SeMenu_EqEdit_SetupHelper1:
	; --- Helper 1: clear flag, setup XIY/XIX, call F0EC00 (21 bytes) ---
	ld	(0x03efa8:24), 0
	ld xiy, 0x00f14809
	ld xix, 0x00f14838
	call SeMenu_NameEditor_Setup
	ret
SeMenu_EqEdit_SetupHelper2:
	; --- Helper 2: clear flag, setup XIY/XIX, call F0EC00 (21 bytes) ---
	ld	(0x03efa8:24), 0
	ld xiy, 0x00f14838
	ld xix, 0x00f1483d
	call SeMenu_NameEditor_Setup
	ret


SeMenu_EqEdit_Dispatch:
	; --- Dispatch on A: 4 paths with language branching (99 bytes) ---
	cp	a, 0:i3
	jr z, SeMenu_EqEdit_SetupPath
	cp a, 0x0b
	jr z, SeMenu_EqEdit_SetConstA
	cp a, 0x0c
	jr nz, SeMenu_EqEdit_DefaultPath
	ld	(0x03efa8:24), 0
	cp	(1710:16), 1
	jr z, SeMenu_EqEdit_DrawTable
	ld xiy, 0x00f149d9
	ld xix, 0x00f149f7
	call SeMenu_NameEditor_Draw
SeMenu_EqEdit_DrawTable:
	ld xiy, 0x00f14a3d
	ld xix, 0x00f14a5b
	call SeMenu_NameEditor_Draw
	jr t, SeMenu_EqEdit_Return
SeMenu_EqEdit_SetupPath:
	ld	(0x03efa8:24), 1
	ld xiy, 0x00f14dd2
	ld xix, 0x00f14df0
	call SeMenu_NameEditor_Setup
	ld a, 0x00:opc
	jr t, SeMenu_EqEdit_DefaultPath
SeMenu_EqEdit_SetConstA:
	ld a, 0x07:opc
SeMenu_EqEdit_DefaultPath:
	ld	(0x03efa8:24), 0
	ld xiy, 0x00f14a66
	call SeMenu_EqEdit_DrawInit_0x15
SeMenu_EqEdit_Return:
	ret


SeMenu_EqEdit_DrawInit:
	ld	(0x03efa8:24), 0
	ld	xiy, TuningSystem_Handler_Table_0x19E1
	ld	xix, TuningSystem_Handler_Table_0x19FF
	call	SeMenu_NameEditor_Draw
	ret
	extz	xwa
	xor	w, w
	sla	wa, 2
	add	xiy, xwa
	ld	xiy, (xiy)
	call	SeMenu_NameEditor_HandleInput
	ret
	.ascii "89:;<=>^]\\[ZYX"
	ret
	ld	(16:8), 40:io
	rcf
	ld	(16:8), 8:io
	rcf
	pushw	wa
	push_a
	nop
	nop
	.ascii "*U T*"
	normal
	pushw	de
	.byte 0x54
	ld	(16:8), 42:io
	.byte 0x54
	ld	(16:8), 8:io
	rcf
	ld	(4:8), 42:io
	.byte 0x55
	ld	b, 1:opc
	push	sr
	max
	ld	(16:8), 42:io
	.byte 0x55
	nop
	nop
	.ascii "*U\"A\"A\"A"
	push	sr
	normal
	push	sr
	pop_a
	pushw	de
	ld	xbc, 0x152a4122
	pushw	de
	.byte 0x55
	ld	b, 1:opc
	ldw	(4:8), 0x4102:io
	pushw	de
	push_a
	nop
	nop
	pushw	de
	.ascii "U @ @ @"
	push	sr
	normal
	push	sr
	pop_a
	pushw	de
	ld	xbc, 0x152a4122
	max
	ldw	(20:8), 5130:io
	ld	b, 85:opc
	pushw	de
	max
	push	sr
	rcf
	ld	(84:8), 42:io
	rcf
	ld	(16:8), 8:io
	push_a
	ld	(64:8), 32:io
	.byte 0x40
	.ascii "*U\"A\"A\""
	reti
	push_f
	.ascii " 'OOOO' "
	push_f
	reti
	incm8	8, (xwa)
	rcf
	and	(xwa), wa
	add	w, 200
	.byte 0x90
	rcf
	jr	f, -128
	reti
	push_f
	.ascii "  @@@@  "
	push_f
	reti
	incm8	8, (xwa)
	rcf
	rcf
	ld	(8:8), 8:io
	ld	(16:8), 16:io
	jr	f, -128
SeBitmap_EnvCurve1:
	swi	7
	.fill 8, 1, 0x80
	.byte 0x80, 0x80, 0x81, 0x81, 0x82, 0x84
	add	(xix), w
	.byte 0x88, 0x90, 0x90, 0x90, 0xa0, 0xa0, 0xa0, 0xa0
	.byte 0xa0, 0xa0, 0xa0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0
	.byte 0xc0, 0xc0, 0xc0, 0xc0
	cp	(xwa), l
	jrl	nc, 255
	nop
	nop
	nop
	pop	sr
	.byte 0x04
	push_f
	ldw	wa, 0xc060
	.byte 0x80
	nop
	nop
	nop
	nop
	nop
	.zero 16
	nop
	nop
	nop
	nop
	nop
	swi	7
	swi	7
	swi	7
	nop
	reti
	push	xwa
	.byte 0xc0
	nop
	nop
	nop
	nop
	.zero 24
	nop
	nop
	nop
	nop
	nop
	swi	7
	swi	7
	swi	7
	retd	240
	nop
	nop
	nop
	nop
	nop
	.zero 24
	nop
	nop
	nop
	nop
	nop
	swi	7
	swi	7
	swi	6
	swi	2
	pop	sr
	pop	sr
	pop	sr
	pop	sr
	pop	sr
	pop	sr
	pop	sr
	.fill 8, 1, 0x03
	.fill 8, 1, 0x03
	.fill 8, 1, 0x03
	pop	sr
	pop	sr
	pop	sr
	pop	sr
	pop	sr
	swi	7
	swi	7
SeBitmap_EnvCurve2:
	swi	7
	.fill 8, 1, 0x80
	.fill 8, 1, 0x80
	.byte 0x80, 0x81, 0x81, 0x82, 0x82, 0x84
	add	(xix), w
	.byte 0x88, 0x90, 0x90, 0x90, 0xa0, 0xa0, 0xa0, 0xa0
	.byte 0xc0, 0xc0, 0xc0, 0xc0, 0xc0
	swi	7
	.byte 0x7f
	swi	7
	.zero 8
	.byte 0x01
	push	sr
	.byte 0x04
	ld	(16:8), 32:io
	ld	xwa, 0x8040
	nop
	nop
	nop
	nop
	nop
	.zero 8
	nop
	nop
	nop
	nop
	nop
	swi	7
	swi	7
	swi	7
	nop
	nop
	nop
	pop	sr
	incf
	rcf
	ld	w, 192:opc
	.zero 24
	nop
	nop
	nop
	nop
	nop
	swi	7
	swi	7
	swi	7
	.byte 0x01
	ret
	jrl	f, 128
	nop
	nop
	nop
	.zero 24
	nop
	nop
	nop
	nop
	nop
	swi	7
	swi	7
	swi	6
	swi	6
	pop	sr
	pop	sr
	pop	sr
	pop	sr
	pop	sr
	pop	sr
	pop	sr
	.fill 8, 1, 0x03
	.fill 8, 1, 0x03
	.fill 8, 1, 0x03
	pop	sr
	pop	sr
	pop	sr
	pop	sr
	pop	sr
	swi	7
	swi	7
SeBitmap_EnvCurve3:
	swi	7
	.fill 8, 1, 0x80
	.fill 8, 1, 0x80
	.fill 8, 1, 0x80
	.byte 0x81, 0x83, 0x86, 0x84
	add	(xix), w
	.byte 0x88, 0x90, 0x90, 0xa0, 0xa0, 0xa0, 0xc0
	swi	7
	jrl nc, 255
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	normal
	pop	sr
	ei	12
	ld	(24:8), 48:io
	jr	f, -64
	.byte 0x80, 0x80
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	swi	7
	swi	7
	swi	7
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	normal
	pop	sr
	ei	12
	push	xwa
	jr	f, -64
	.byte 0x80
	nop
	.zero 16
	nop
	nop
	nop
	nop
	nop
	swi	7
	swi	7
	swi	7
	nop
	nop
	nop
	pop	sr
	.byte 0x1c
	ldw	wa, 0xc060
	.zero 24
	nop
	nop
	nop
	nop
	nop
	swi	7
	swi	7
	swi	6
	ei	59
	.byte 0xc3
	pop	sr
	pop	sr
	pop	sr
	pop	sr
	pop	sr
	.fill 8, 1, 0x03
	.fill 8, 1, 0x03
	.fill 8, 1, 0x03
	pop	sr
	pop	sr
	pop	sr
	pop	sr
	pop	sr
	swi	7
	swi	7
SeBitmap_EnvCurve4:
	swi	7
	.fill 8, 1, 0x80
	.fill 8, 1, 0x80
	.fill 8, 1, 0x80
	.fill 8, 1, 0x80
	.byte 0x80, 0x81, 0x86, 0xb8, 0xc0
	swi	7
	jrl nc, 255
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	normal
	reti
	incf
	push_f
	jrl	f, 128
	nop
	nop
	swi	7
	swi	7
	swi	7
	.zero 16
	nop
	nop
	nop
	nop
	nop
	normal
	pop	sr
	ei	12
	push	xwa
	jr	f, -64
	.byte 0x80
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	swi	7
	swi	7
	swi	7
	.zero 8
	nop
	nop
	nop
	normal
	pop	sr
	push	sr
	ei	12
	push_f
	ldw	wa, 0x6020
	.byte 0xc0, 0x80
	nop
	nop
	.zero 8
	nop
	nop
	nop
	nop
	nop
	swi	7
	swi	7
	swi	6
	.byte 0x06
	pushw	2827
	zcf
	zcf
	ld	c, 35:opc
	ld	xhl, 0x0383c343
	pop	sr
	pop	sr
	pop	sr
	.fill 8, 1, 0x03
	.fill 8, 1, 0x03
	pop	sr
	pop	sr
	pop	sr
	pop	sr
	pop	sr
	swi	7
	swi	7
SeBitmap_EnvCurve5:
	swi	7
	.fill 8, 1, 0x80
	.fill 8, 1, 0x80
	.fill 8, 1, 0x80
	.fill 8, 1, 0x80
	.byte 0x80, 0x80, 0x80
	cp	(xwa), l
	swi	7
	.byte 0x7f
	swi	7
	.zero 32
	nop
	pop	sr
	.byte 0x1c, 0xe0
	nop
	swi	7
	swi	7
	swi	7
	.zero 24
	nop
	nop
	nop
	nop
	.byte 0x01, 0x06
	ld	(16:8), 96:io
	.byte 0x80
	nop
	nop
	nop
	swi	7
	swi	7
	swi	7
	.zero 16
	nop
	nop
	.byte 0x01, 0x01
	push	sr
	.byte 0x04, 0x04
	ld	(16:8), 32:io
	ld	xwa, 128
	nop
	nop
	nop
	nop
	nop
	nop
	swi	7
	swi	7
	swi	6
	ei	7
	reti
	reti
	reti
	pushw	2827
	pushw	4883
	zcf
	ld	c, 35:opc
	ld	xhl, 0x03838343
	pop	sr
	pop	sr
	pop	sr
	pop	sr
	pop	sr
	.fill 8, 1, 0x03
	pop	sr
	pop	sr
	pop	sr
	pop	sr
	pop	sr
	swi	7
	swi	7
	swi	7
	.fill 8, 1, 0x80
	.fill 8, 1, 0x80
	.fill 8, 1, 0x80
	.fill 8, 1, 0x80
	.byte 0x80, 0x80, 0x80, 0x80, 0xbf
	swi	7
	.byte 0x7f
	swi	7
	.zero 32
	nop
	nop
	nop
	.byte 0x1f, 0xe0
	swi	7
	swi	7
	swi	7
	.zero 32
	.byte 0x01, 0x06
	push	xwa
	.byte 0xc0
	nop
	swi	7
	swi	7
	swi	7
	.zero 24
	nop
	.byte 0x01
	pop	sr
	ei	12
	push_f
	ldw	wa, 0x8040
	nop
	nop
	nop
	nop
	swi	7
	swi	7
	swi	6
	push	sr
	reti
	reti
	reti
	reti
	reti
	reti
	reti
	reti
	reti
	pushw	2827
	pushw	2827
	pushw	4883
	zcf
	ld	c, 35:opc
	ld	xhl, 0x03038343
	pop	sr
	pop	sr
	pop	sr
	pop	sr
	pop	sr
	pop	sr
	pop	sr
	pop	sr
	pop	sr
	pop	sr
	swi	7
	swi	7
	jp	778
	push	sr
	nop
	push	xwa
	.byte 0x01
	pop	sr
	nop
	.byte 0x1c
	rcf
	jr	nz, 0
	halt
	nop
	.byte 0x53
	.ascii "OUND EDIT"
	.byte 0x06
	pushw	1440
	rcf
	ld	w, 87:opc
	.byte 0x52
	popw	bc
	.byte 0x54
	ld	xiy, 0x0bdf0506
	scf
	ei	5
	ld	(12:8), 16:io
	ei	13
	.byte 0x1f
	incf
	.ascii "EASY EDIT"
	.byte 0x06
	retd	3287
	.byte 0x54
	.ascii "ONE SELECT"
	ei	5
	ldx
	scf
	scf
	ei	5
	swi	0
	scf
	rcf
	ei	13
	.byte 0x77
	ccf
	.ascii "AMPLITUDE"
	ei	14
	.byte 0x86
	ccf
	.byte 0x54
	popw	sp
	popw	iz
	.ascii "E LAYER"
	.byte 0x06
	pushw 0x1786
	ld	xix, 0x54494749
	ld	xbc, 0xbf05064c
	ldf	17
	ei	5
	push	xwa
	push_f
	rcf
	.byte 0x06
	push	103
	push_f
	.byte 0x50
	popw	bc
	.byte 0x54
	ld	xhl, 0x930a0648
	pop_f
	.ascii "EFFECT"
	ei	5
	swi	7
	call	0x050611
	.byte 0x50
	calr	1552
	ldw	(127:8), 0x461e:io
	popw	bc
	popw	ix
	.byte 0x54
	ld	xiy, 0xde0e0652
	.byte 0x1e, 0x43
	.ascii "ONTROLLER"
	push	10
	incf
	nop
	.byte 0x1f
	nop
	push	xix
	nop
	ldw	de, 2304
	ldw	(14:8), 8448:io
	nop
	push	xde
	nop
	ldw	wa, 8704
	ldw	(174:8), 0x3e00:io
	nop
	ldw	ix, 0x6301
	nop
	.byte 0x01
	ldw	(15:8), 0x4100:io
	nop
	.byte 0xae
	nop
	ld	xbc, 0x0f0a0100
	nop
	.byte 0xd9
	nop
	ldw	bc, 0xd901
	nop
	push	sr
	ldw	(15:8), 0x4100:io
	nop
	retd	0xd900
	nop
	push	sr
	ldw	(49:8), 0x6501:io
	nop
	ldw	bc, 0xd901
	nop
	ld	c, 5:opc
	rcf
	.byte 0x82
	nop
	ld	c, 5:opc
	jr	lt, -109
	pushw	1315
	jr	ule, -125
	scf
	ld	c, 5:opc
	reti
	jrl	ule, 8983
	halt
	ld	a, 179:opc
	call	0x620523
	.byte 0xea
	ldw	(35:8), 0x6405:io
	.byte 0xa2
	scf
	ld	c, 5:opc
	ldw	(146:8), 8983:io
	halt
	pop	xsp
	or	(0x0a1b1d:24), ix
	nop
	.byte 0x1f
	nop
	ldw	ix, 0x3201
	nop
	ei	14
	.byte 0xbe
	halt
	.ascii "ORIGINAL "
	scf
	push	10
	.byte 0xec
	nop
	.byte 0x1f
	nop
	ldw	ix, 0x3201
	nop
	push	10
	.byte 0xee
	nop
	ld	a, 0:opc
	ldw	de, 0x3001
	nop
	.long NakaInst_Hard_Analogue_148_0x65
	.byte 0x1f
	nop
	ldw	ix, 0x3201
	nop
	ei	12
	.byte 0xc0
	halt
	.byte 0x45, 0x44
	.ascii "ITED "
	scf
	push	10
	swi	4
	nop
	.byte 0x1f
	nop
	ldw	ix, 0x3201
	nop
	push	10
	swi	6
	nop
	ld	a, 0:opc
	ldw	de, 0x3001
	nop
	ei	5
	.byte 0x90
	pushw	1552
	halt
	pop	xwa
	scf
	rcf
	ei	5
	popw	wa
	ldf	16
	ei	5
	rcf
	call	16
	.zero 16
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x1f
	ldw	wa, 3871
	nop
	nop
	nop
	nop
	nop
	nop
	.zero 8
	pop	sr
	.byte 0x04, 0x0b
	pop_a
	.ascii "+-F@@@a?"
	calr	11320
	pushw	ix
	pushw	ix
	add	xhl, xsp
	ld	xiz, 0xff182c
	swi	7
	swi	7
	nop
	nop
	nop
	nop
	nop
	nop
	.zero 8
	.byte 0x80
	.ascii "@``phtz"
	and	h, e
	.byte 0x83, 0x81
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	swi	7
	nop
	swi	7
	swi	7
	nop
	nop
	nop
	nop
	nop
	nop
	.zero 16
	nop
	.byte 0x80
	ld	xwa, 0x3878d0a0
	nop
	nop
	.byte 0x01
	push	sr
	.byte 0x04
	ld	(16:8), 224:io
	nop
	swi	0
	.byte 0xf4, 0x1a
	decf
	ei	3
	.byte 0x01
	nop
	.zero 19
	.ascii "  PPˆˆˆˆˆˆÈÈÈÈÈˆˆˆˆØÐ"
	jrl	f, 32
	nop
	nop
	nop
	ld	w, 7:opc
	.byte 0x91, 0x0b
	.ascii "1ST "
	reti
	pop	xbc
	scf
	.ascii "2ND "
	reti
	popw	bc
	.byte 0x17
	.ascii "3RD "
	reti
	scf
	call	0x485434
	.byte 0xbd
	zcf
	.byte 0xf1
	nop
	.byte 0xbd
	zcf
	.byte 0xf1
	nop
	.byte 0xc4
	zcf
	.byte 0xf1
	nop
	exts	c
	.byte 0xf1
	nop
	xor	(0xf113:24), bc
	zcf
	.byte 0xf1
	nop
	pop	sr
	incf
	ei	12
	.byte 0xf1
	nop
	.byte 0x91
	pushw	3
	ldw	(0:8), 3075:io
	ld	d, 12:opc
	.byte 0xf1
	nop
	pop	xbc
	scf
	pop	sr
	nop
	ldw	(0:8), 3075:io
	ld	xde, 0x4900f10c
	ldf	3
	nop
	ldw	(0:8), 3075:io
	jr	f, 12
	.byte 0xf1
	nop
	scf
	call	0x0a0003
	nop
	ld	(0xf113:16), 241
	zcf
	.byte 0xf1
	nop
	swi	5
	zcf
	.byte 0xf1
	nop
	push	20
	.byte 0xf1
	nop
	pop_a
	push_a
	.byte 0xf1
	nop
	ld	a, 20:opc
	.byte 0xf1
	nop
	.byte 0x06
	push	80
	halt
	rcf
	.byte 0x53
	popw	sp
	popw	ix
	popw	sp
	push	10
	halt
	nop
	calr	11008
	nop
	pushw	sp
	nop
	push	10
	reti
	nop
	ld	w, 0:opc
	pushw	bc
	nop
	pushw	iy
	nop
	jp	1546
	.byte 0x1f
	nop
	ei	0
	pushw	iz
	nop
	halt
	ldw	(8:8), 8448:io
	nop
	pushw	wa
	nop
	pushw	ix
	nop
	jp	2058
	ld	a, 0:opc
	pushw	wa
	nop
	pushw	ix
	nop
	jp	2058
	popw	bc
	nop
	ld	b, 0:opc
	.byte 0xc5
	nop
	pop	sr
	pushw	1629
	retd	1280
	.byte 0x89
	push_a
	ld	(2048:16), 73
	nop
	ld	b, 0:opc
	.byte 0x56
	nop
	ld	(0:8), 73:io
	nop
	ld	b, 0:opc
	.byte 0x56
	nop
	ld	(0:8), 110:io
	nop
	ld	b, 0:opc
	jrl	ugt, 2048
	nop
	.byte 0x93
	nop
	ld	b, 0:opc
	.byte 0xa0
	nop
	ld	(0:8), 184:io
	nop
	ld	b, 0:opc
	.byte 0xc5
	nop
	.ascii "NORM 1/2 1/4 1/81/161/321/64 FIXOFF ONOFFON "
	.byte 0x1c
	rcf
	jrl	ule, 1280
	nop
	.ascii "T0NE LAYER"
	ldf	16
	ei	0
	reti
	nop
	.ascii "SOUND EDIT"
	ei	7
	scf
	pushw	0x454b
	pop	xbc
	ei	5
	.byte 0xb7
	pushw	1553
	push	25
	decf
	popw	ix
	ld	xbc, 0x06524559
	reti
	.byte 0x01
	scf
	.byte 0x56
	ld	xiy, 0xa705064c
	scf
	scf
	.byte 0x06
	push	9
	zcf
	popw	ix
	ld	xbc, 0x07524559
	halt
	jrl	le, 24351
	reti
	halt
	.byte 0x82, 0x1f
	pop	xsp
	ei	5
	jr	lt, 32
	popw	ix
	ei	19
	.ascii "c FADE LOW HIGH H"
	.byte 0x06, 0x08
	.ascii "s FADE"
	reti
	halt
	popw	hl
	ld	d, 18:opc
	reti
	halt
	.byte 0x51
	ld	d, 18:opc
	reti
	halt
	.byte 0x56
	ld	d, 18:opc
	reti
	halt
	pop	xhl
	ld	d, 18:opc
	push	10
	.byte 0x04
	nop
	.byte 0x04
	nop
	ld	xix, 0x09001000
	ldw	(4:8), 0x4201:io
	nop
	ldw	ix, 0x6001
	nop
	push	10
	.byte 0x04, 0x01
	jr	0
	ldw	ix, 0x8601
	nop
	push	10
	ld	xiy, 0xfb00cc00
	nop
	.byte 0xe9
	nop
	.byte 0x01
	ldw	(69:8), 0xdb00:io
	nop
	swi	3
	nop
	.byte 0xdb
	nop
	push	sr
	ldw	(156:8), 0xcc00:io
	nop
	.byte 0x9c
	nop
	.byte 0xe9
	nop
	halt
	ldw	(70:8), 0xdc00:io
	nop
	.long NakaInst_LEFT_0x04
	ld	c, 5:opc
	jr	ov, -125
	nop
	.byte 0x1c
	scf
	jrl	le, 1280
	nop
	.byte 0x54
	.ascii "0NE SELECT"
	ldf	16
	ei	0
	reti
	nop
	.ascii "SOUND EDIT"
	push	10
	.byte 0x04
	nop
	.byte 0x04
	nop
	ld	xix, 0x23001000
	halt
	jr	lt, -125
	nop
	.byte 0x06
	pushw	272
	.byte 0x50
	ld	xbc, 0x2f314547
	ldw	hl, 2583
	.byte 0x54
	nop
	push	xix
	nop
	.byte 0x54
	popw	sp
	popw	iz
	ld	xiy, 0x720c17
	push	xix
	nop
	.byte 0x53
	ld	xiy, 0x5443454c
	.byte 0x17
	pushw	199
	push	xix
	nop
	popw	ix
	ld	xiy, 0x174c4556
	push	241
	nop
	push	xix
	nop
	popw	hl
	ld	xiy, 0x090c1759
	.byte 0x01
	push	xix
	nop
	ld	xix, 0x4e555445
	ld	xiy, 0x0c300506
	rcf
	ei	5
	.byte 0xd9
	incf
	push	xde
	ei	5
	.byte 0xd9
	scf
	push	xde
	ei	5
	swi	0
	scf
	rcf
	ei	5
	.byte 0xd9
	ex_ff
	push	xde
	ei	5
	jrl	f, 4119
	ei	5
	.byte 0xd9
	jp	0x05063a
	push	xwa
	call	0x0c1710
	push	sr
	nop
	.byte 0xd1
	nop
	.ascii "ON/OFF"
	.byte 0x17
	pushw	48
	.byte 0xd1
	nop
	ld	xsp, 0x50554f52
	.byte 0x17
	ldw	(88:8), 0xd100:io
	nop
	.byte 0x54
	popw	sp
	popw	iz
	ld	xiy, 0xcc0b17
	.byte 0xd1
	nop
	popw	ix
	ld	xiy, 0x174c4556
	push	250
	nop
	.byte 0xd1
	nop
	popw	hl
	ld	xiy, 0x190c1759
	.byte 0x01, 0xd1
	nop
	ld	xix, 0x4e555445
	ld	xiy, 0x22120506
	.byte 0x8d
	ei	5
	.byte 0x17
	ld	b, 141:opc
	ei	5
	.byte 0x1c
	ld	b, 141:opc
	ei	5
	pushw	hl
	ld	b, 141:opc
	ei	5
	ldw	wa, 0x8d22
	ei	5
	ldw	iy, 0x8d22
	ei	5
	ld	xhl, (xde)
	.byte 0x8e
	ei	5
	ld	xhl, (xsp)
	.byte 0x8e
	ei	5
	add	(xix+35), xiz
	ei	5
	.byte 0xbb
	ld	c, 142:opc
	ei	5
	.byte 0xc0
	ld	c, 142:opc
	ei	5
	.byte 0xc5
	ld	c, 142:opc
	ld	b, 10:opc
	pushw	0x3600
	nop
	ldw	iy, 0xc701
	nop
	ld	b, 10:opc
	push	0
	.byte 0xda
	nop
	calr	60928
	nop
	ld	b, 10:opc
	ldw	bc, 0xda00
	nop
	ld	xiz, 0x2200ee00
	ldw	(89:8), 0xda00:io
	nop
	jr	nz, 0
	.byte 0xee
	nop
	ld	b, 10:opc
	.byte 0xd1
	nop
	.byte 0xda
	nop
	.byte 0xe6
	nop
	.byte 0xee
	nop
	ld	b, 10:opc
	swi	1
	nop
	.byte 0xda
	nop
	ret
	.byte 0x01, 0xee
	nop
	ld	b, 10:opc
	ld	a, 1:opc
	.byte 0xda
	nop
	ldw	iz, 0xee01
	nop
	.byte 0x01
	ldw	(11:8), 0x4700:io
	nop
	ldw	iy, 0x4701
	nop
	.byte 0x01
	ldw	(11:8), 0x6700:io
	nop
	ldw	iy, 0x6701
	nop
	.byte 0x01
	ldw	(11:8), 0x8700:io
	nop
	ldw	iy, 0x8701
	nop
	.byte 0x01
	ldw	(11:8), 0xa700:io
	nop
	ldw	iy, 0xa701
	nop
	.byte 0x01
	ldw	(9:8), 0xe400:io
	nop
	calr	58368
	nop
	.byte 0x01
	ldw	(49:8), 0xe400:io
	nop
	ld	xiz, 0x0100e400
	ldw	(89:8), 0xe400:io
	nop
	jr	nz, 0
	.byte 0xe4
	nop
	.byte 0x01
	ldw	(209:8), 0xe400:io
	nop
	.byte 0xe6
	nop
	.byte 0xe4
	nop
	.byte 0x01
	ldw	(249:8), 0xe400:io
	nop
	ret
	.byte 0x01, 0xe4
	nop
	.byte 0x01
	ldw	(33:8), 0xe401:io
	nop
	ldw	iz, 0xe401
	nop
	push	sr
	ldw	(60:8), 0x3600:io
	nop
	push	xix
	nop
	.byte 0xc7
	nop
	push	sr
	ldw	(188:8), 0x3600:io
	nop
	.byte 0xbc
	nop
	.byte 0xc7
	nop
	ei	5
	ldw	wa, 4108
	ei	5
	swi	0
	scf
	rcf
	ei	5
	jrl	f, 4119
	ei	5
	push	xwa
	call	0x072010
	pop	xde
	incf
	ldw	bc, 0x5453
	ld	w, 7:opc
	pop	xde
	scf
	.ascii "2ND "
	reti
	pop	xde
	ex_ff
	.ascii "3RD "
	reti
	pop	xde
	jp	0x485434
	.byte 0x98, 0x17, 0xf1
	nop
	.byte 0x98, 0x17, 0xf1
	nop
	.byte 0x9f, 0x17, 0xf1
	nop
	.byte 0xa6, 0x17, 0xf1
	nop
	.byte 0xad, 0x17, 0xf1
	nop
	.byte 0xb4, 0x17, 0xf1
	nop
	pop	sr
	incf
	ei	12
	.byte 0xf1
	nop
	pop	xde
	incf
	pop	sr
	nop
	ldw	(0:8), 3075:io
	ld	d, 12:opc
	.byte 0xf1
	nop
	pop	xde
	scf
	pop	sr
	nop
	ldw	(0:8), 3075:io
	ld	xde, 0x5a00f10c
	ex_ff
	pop	sr
	nop
	ldw	(0:8), 3075:io
	jr	f, 12
	.byte 0xf1
	nop
	pop	xde
	jp	0x0a0003
	nop
	.byte 0xcc, 0x17, 0xf1
	nop
	.byte 0xcc, 0x17, 0xf1
	nop
	.byte 0xd8, 0x17, 0xf1
	nop
	.byte 0xe4, 0x17, 0xf1
	nop
	.byte 0xf0, 0x17, 0xf1
	nop
	swi	4
	.byte 0x17, 0xf1
	nop
	pop	sr
	incf
	jrl	nz, -3828
	nop
	.byte 0xd2
	incf
	push	sr
	nop
	incf
	nop
	ld	w, 7:opc
	.byte 0xd4
	incf
	ldw	bc, 0x5453
	pop	sr
	incf
	jrl	nz, -3828
	nop
	.byte 0xd2
	scf
	push	sr
	nop
	incf
	nop
	ld	w, 7:opc
	.byte 0xd4
	scf
	ldw	de, 0x444e
	pop	sr
	incf
	jrl	nz, -3828
	nop
	.byte 0xd2
	ex_ff
	push	sr
	nop
	incf
	nop
	ld	w, 7:opc
	.byte 0xd4
	ex_ff
	ldw	hl, 0x4452
	pop	sr
	incf
	jrl	nz, -3828
	nop
	.byte 0xd2
	jp	0x0c0002
	nop
	ld	w, 7:opc
	.byte 0xd4
	jp	0x485434
	push_a
	push_f
	.byte 0xf1
	nop
	push_a
	push_f
	.byte 0xf1
	nop
	ld	l, 24:opc
	.byte 0xf1
	nop
	push	xde
	push_f
	.byte 0xf1
	nop
	popw	iy
	push_f
	.byte 0xf1
	nop
	jr	f, 24
	.byte 0xf1
	nop
	pop	sr
	incf
	.byte 0x96
	incf
	.byte 0xf1
	nop
	.byte 0xd2
	incf
	push	sr
	nop
	incf
	nop
	pop	sr
	incf
	ei	12
	.byte 0xf1
	nop
	.byte 0xd4
	incf
	pop	sr
	nop
	ldw	(0:8), 3075:io
	.byte 0x96
	incf
	.byte 0xf1
	nop
	.byte 0xd2
	scf
	push	sr
	nop
	incf
	nop
	pop	sr
	incf
	ld	d, 12:opc
	.byte 0xf1
	nop
	.byte 0xd4
	scf
	pop	sr
	nop
	ldw	(0:8), 3075:io
	.byte 0x96
	incf
	.byte 0xf1
	nop
	.byte 0xd2
	ex_ff
	push	sr
	nop
	incf
	nop
	pop	sr
	incf
	ld	xde, 0xd400f10c
	ex_ff
	pop	sr
	nop
	ldw	(0:8), 3075:io
	.byte 0x96
	incf
	.byte 0xf1
	nop
	.byte 0xd2
	jp	0x0c0002
	nop
	pop	sr
	incf
	jr	f, 12
	.byte 0xf1
	nop
	.byte 0xd4
	jp	0x0a0003
	nop
	jrl	-3816
	nop
	jrl	-3816
	nop
	.byte 0x90
	push_f
	.byte 0xf1
	nop
	.byte 0xa8
	push_f
	.byte 0xf1
	nop
	.byte 0xc0
	push_f
	.byte 0xf1
	nop
	.byte 0xd8
	push_f
	.byte 0xf1
	nop
	pop	sr
	incf
	jrl	nz, -3828
	nop
	.byte 0x9a
	ccf
	push	sr
	nop
	incf
	nop
	.byte 0x17
	push	33
	nop
	jrl	gt, 12544
	.byte 0x53, 0x54
	pop	sr
	incf
	jrl	nz, -3828
	nop
	popw	de
	ldf	2
	nop
	incf
	nop
	.byte 0x17
	push	33
	nop
	.byte 0x98
	nop
	ldw	de, 0x444e
	.byte 0xf0
	push_f
	.byte 0xf1
	nop
	.byte 0xf0
	push_f
	.byte 0xf1
	nop
	halt
	pop_f
	.byte 0xf1
	nop
	.byte 0x1a
	pop_f
	.byte 0xf1
	nop
	pop	sr
	incf
	.byte 0x96
	incf
	.byte 0xf1
	nop
	.byte 0x9a
	ccf
	push	sr
	nop
	incf
	nop
	.byte 0x17
	push	33
	nop
	jrl	gt, 12544
	.byte 0x53, 0x54
	pop	sr
	incf
	.byte 0x96
	incf
	.byte 0xf1
	nop
	popw	de
	ldf	2
	nop
	incf
	nop
	.byte 0x17
	push	33
	nop
	.byte 0x98
	nop
	ldw	de, 0x444e
	pushw	de
	pop_f
	.byte 0xf1
	nop
	pushw	de
	pop_f
	.byte 0xf1
	nop
	push	xsp
	pop_f
	.byte 0xf1
	nop
	.byte 0x54
	pop_f
	.byte 0xf1
	nop
	.byte 0x1c
	pushw	140
	halt
	nop
	.byte 0x50
	popw	bc
	.byte 0x54
	ld	xhl, 0x06101748
	nop
	reti
	nop
	.byte 0x53
	popw	sp
	.ascii "UND EDIT"
	.byte 0x06
	push	139
	.byte 0x06
	.ascii "ENV "
	scf
	.byte 0x06
	pushw	3033
	.byte 0x50
	popw	bc
	.byte 0x54
	ld	xhl, 0x06112048
	push	43
	scf
	.ascii "LF0 "
	scf
	push	10
	.byte 0x04
	nop
	.byte 0x04
	nop
	ld	xix, 0x09001000
	ldw	(20:8), 9473:io
	nop
	ldw	ix, 0x3601
	nop
	push	10
	.byte 0x04, 0x01
	ld	xbc, 0x5e013400
	nop
	push	10
	push_a
	.byte 0x01
	jr	ge, 0
	ldw	ix, 0x7a01
	nop
	.byte 0x01
	ldw	(32:8), 0x3d01:io
	nop
	ld	l, 1:opc
	push	xiy
	nop
	.byte 0x01
	ldw	(33:8), 0x3e01:io
	nop
	ld	h, 1:opc
	push	xiz
	nop
	.byte 0x01
	ldw	(34:8), 0x3f01:io
	nop
	ld	e, 1:opc
	push	xsp
	nop
	.byte 0x01
	ldw	(34:8), 0x6001:io
	nop
	ld	e, 1:opc
	jr	f, 0
	.byte 0x01
	ldw	(33:8), 0x6101:io
	nop
	ld	h, 1:opc
	jr	lt, 0
	.byte 0x01
	ldw	(32:8), 0x6201:io
	nop
	ld	l, 1:opc
	jr	le, 0
	push	10
	ld	c, 1:opc
	ldw	iz, 9216
	.byte 0x01
	ld	xbc, 0x230a0900
	.byte 0x01
	pop	xiz
	nop
	ld	d, 1:opc
	jr	ge, 0
	ld	c, 5:opc
	reti
	.byte 0x86
	nop
	halt
	ldw	(22:8), 9985:io
	nop
	ldw	de, 0x3401
	nop
	halt
	ldw	(14:8), 0x4301:io
	nop
	ldw	de, 0x5c01
	nop
	halt
	ldw	(22:8), 0x6b01:io
	nop
	ldw	de, 0x7801
	nop
	.byte 0x17
	push	49
	nop
	.byte 0x37
	nop
	popw	hl
	ld	xiy, 0x5b091759
	nop
	.byte 0x37
	nop
	ld	xix, 0x0a172d45
	.byte 0x84
	nop
	.byte 0x37
	nop
	.byte 0x54
	popw	sp
	popw	iz
	ld	xiy, 0xb61117
	.byte 0x37
	nop
	.ascii "KEY SCALING"
	.byte 0x17
	pushw	49
	ld	xwa, 0x49485300
	ld	xiz, 0x5b0a1754
	nop
	ld	xwa, 0x4e555400
	ld	xiy, 0x840b17
	ld	xwa, 0x41435300
	popw	ix
	ld	xiy, 0x0c300506
	rcf
	.byte 0x17
	retd	187
	pop	xsp
	nop
	.ascii "OCT-SHIFT"
	ei	5
	swi	0
	scf
	rcf
	ldf	17
	ld	(xiz), 135
	nop
	.ascii "RIGHT SPLIT"
	ei	5
	.byte 0x94, 0x17, 0x8d
	ei	5
	jrl	f, 4119
	ei	5
	.byte 0x97, 0x17, 0xa9, 0x17
	incf
	zcf
	.byte 0x01, 0xac
	nop
	ld	xhl, 0x4f535255
	.byte 0x52, 0x17
	rcf
	.byte 0xba
	nop
	.byte 0xaf
	nop
	.ascii "LEFT SPLIT"
	ei	5
	push	xwa
	call	0x050610
	.byte 0xd4
	call	0x05068e
	sub	(xsp+29), xbc
	.byte 0x17
	push	51
	nop
	.byte 0xd1
	nop
	popw	hl
	ld	xiy, 0x520c1759
	nop
	.byte 0xd1
	nop
	.ascii "DETUNE"
	.byte 0x17
	pushw	125
	.byte 0xd1
	nop
	.byte 0x53
	ld	xhl, 0x17454c41
	pushw	205
	.byte 0xd1
	nop
	.byte 0x56
	ld	xbc, 0x0645554c
	halt
	.byte 0x17
	ld	b, 141:opc
	ei	5
	.byte 0x1c
	ld	b, 141:opc
	ei	5
	ld	a, 34:opc
	.byte 0x8d
	ei	5
	pushw	hl
	ld	b, 141:opc
	ei	5
	ld	xhl, (xsp)
	.byte 0x8e
	ei	5
	add	(xix+35), xiz
	ei	5
	.byte 0xb1
	ld	c, 142:opc
	ei	5
	.byte 0xbb
	ld	c, 142:opc
	ld	b, 10:opc
	pushw	0x3300
	nop
	.byte 0xa8
	nop
	.byte 0xca
	nop
	ld	b, 10:opc
	ld	(xhl), 51
	nop
	swi	3
	nop
	.byte 0x52
	nop
	ld	b, 10:opc
	ld	(xhl), 91
	nop
	swi	3
	nop
	jrl	gt, 8704
	ldw	(179:8), 0x8300:io
	nop
	swi	3
	nop
	.byte 0xa2
	nop
	push	10
	.byte 0x17, 0x01, 0x94
	nop
	ldw	wa, 0xa301
	nop
	push	10
	pop_f
	.byte 0x01, 0x96
	nop
	pushw	iz
	.byte 0x01, 0xa1
	nop
	ld	b, 10:opc
	ld	(xhl), 171
	nop
	swi	3
	nop
	.byte 0xca
	nop
	push	10
	.byte 0x17, 0x01, 0xbb
	nop
	ldw	wa, 0xca01
	nop
	push	10
	pop_f
	.byte 0x01, 0xbd
	nop
	pushw	iz
	.byte 0x01, 0xc8
	nop
	ld	b, 10:opc
	ldw	bc, 0xda00
	nop
	ld	xiz, 0x2200ee00
	ldw	(89:8), 0xda00:io
	nop
	jr	nz, 0
	.byte 0xee
	nop
	ld	b, 10:opc
	.byte 0x81
	nop
	.byte 0xda
	nop
	.long NakaInst_Param_Val7F
	ld	b, 10:opc
	.byte 0xd1
	nop
	.long NakaData_DescriptorPad_ZeroC
	.byte 0xee
	nop
	.byte 0x01
	ldw	(179:8), 0x4100:io
	nop
	swi	3
	nop
	ld	xbc, 0x0b0a0100
	nop
	popw	de
	nop
	.byte 0xa8
	nop
	popw	de
	nop
	.byte 0x01
	ldw	(179:8), 0x6900:io
	nop
	swi	3
	nop
	jr	ge, 0
	.byte 0x01
	ldw	(11:8), 0x6a00:io
	nop
	.byte 0xa8
	nop
	jr	gt, 0
	.byte 0x01
	ldw	(11:8), 0x8a00:io
	nop
	.byte 0xa8
	nop
	.byte 0x8a
	nop
	.byte 0x01
	ldw	(179:8), 0x9100:io
	nop
	swi	3
	nop
	.byte 0x91
	nop
	.byte 0x01
	ldw	(11:8), 0xaa00:io
	nop
	.byte 0xa8
	nop
	.byte 0xaa
	nop
	.byte 0x01
	ldw	(179:8), 0xb900:io
	nop
	swi	3
	nop
	.byte 0xb9
	nop
	.byte 0x01, 0x0a
	.long Pad_NakaExternal_Block2
	.long Pad_NakaExternal_Block3
	.byte 0x01
	ldw	(89:8), 0xe400:io
	nop
	jr	nz, 0
	.byte 0xe4
	nop
	.byte 0x01
	ldw	(129:8), 0xe400:io
	nop
	.long NakaData_ExternalPadBlock_A
	.byte 0x01, 0x0a, 0xd1
	nop
	.long NakaData_DescriptorZero_PadA
	.byte 0xe4
	nop
	push	sr
	ldw	(44:8), 0x3300:io
	nop
	pushw	ix
	nop
	.byte 0xca
	nop
	halt
	ldw	(6:8), 0x4301:io
	nop
	ldw	de, 0x5c01
	nop
	ldf	17
	.byte 0x43
	nop
	.byte 0xb2
	nop
	.ascii "START PITCH"
	.byte 0x17
	ldw	(146:8), 0xb200:io
	nop
	.byte 0x53, 0x54
	popw	sp
	.byte 0x50, 0x17
	pushw	173
	ld	(xde), 80
	popw	bc
	.byte 0x54
	ld	xhl, 0xd80b1748
	nop
	ld	(xde), 84
	popw	sp
	.byte 0x54
	ld	xbc, 0xfc0b174c
	nop
	.byte 0xb2
	nop
	ld	xix, 0x48545045
	push	sr
	ldw	(213:8), 0xae00:io
	nop
	.byte 0xd5
	nop
	.byte 0xcb
	nop
	.byte 0x1c
	retd	122
	halt
	nop
	.byte 0x41
	popw	iy
	.ascii "PLITUDE"
	ldf	16
	ei	0
	reti
	nop
	.byte 0x53
	popw	sp
	.byte 0x55
	.ascii "ND EDIT"
	.byte 0x06
	push	139
	.byte 0x06
	.ascii "ENV "
	scf
	.byte 0x06
	push	219
	.byte 0x0b
	.ascii "AMP "
	scf
	push	10
	.byte 0x04
	nop
	.byte 0x04
	nop
	ld	xix, 0x09001000
	ldw	(20:8), 9473:io
	nop
	ldw	ix, 0x3601
	nop
	push	10
	push_a
	.byte 0x01
	ld	xbc, 0x5e013400
	nop
	.byte 0x01
	ldw	(32:8), 0x3d01:io
	nop
	ld	l, 1:opc
	push	xiy
	nop
	.byte 0x01
	ldw	(33:8), 0x3e01:io
	nop
	ld	h, 1:opc
	push	xiz
	nop
	.byte 0x01
	ldw	(34:8), 0x3f01:io
	nop
	ld	e, 1:opc
	push	xsp
	nop
	push	10
	ld	c, 1:opc
	ldw	iz, 9216
	.byte 0x01
	ld	xbc, 0x2b090600
	scf
	.ascii "LF0 "
	scf
	.byte 0x01
	ldw	(34:8), 0x6001:io
	nop
	ld	e, 1:opc
	jr	f, 0
	.byte 0x01
	ldw	(33:8), 0x6101:io
	nop
	ld	h, 1:opc
	jr	lt, 0
	.byte 0x01
	ldw	(32:8), 0x6201:io
	nop
	ld	l, 1:opc
	jr	le, 0
	push	10
	ld	c, 1:opc
	pop	xiz
	nop
	ld	d, 1:opc
	jr	ge, 0
	push	10
	push_a
	.byte 0x01
	jr	ge, 0
	ldw	ix, 0x7a01
	nop
	ld	c, 5:opc
	jr	ule, -124
	nop
	jp	0xd60a
	ld	xiz, 0xe1010700
	nop
	jp	0x9e0a
	ld	xiz, 0xa100d200
	nop
	.byte 0x17
	pushw	226
	jrl	le, 21504
	popw	sp
	.byte 0x55
	ld	xhl, 0xe80b1748
	nop
	jrl	ugt, 17152
	.byte 0x55, 0x52, 0x56
	ld	xiy, Bitmap_1bit_Completed_0x15C
	ld	xiz, 0x6c010600
	nop
	.byte 0x01
	ldw	(214:8), 0x5a00:io
	nop
	.byte 0xe0
	nop
	pop	xde
	nop
	.byte 0x17
	pushw	226
	.byte 0x92
	nop
	.ascii "TOUCH"
	.long NakaObj_FmuteVol_LinkEntry1
	.byte 0x9b
	nop
	ld	xhl, 0x45565255
	ld	b, 10:opc
	.byte 0xe0
	nop
	jr	z, 0
	ei	1
	.byte 0x8c
	nop
	.byte 0x01
	ldw	(214:8), 0x7a00:io
	nop
	.byte 0xe0
	nop
	jrl	gt, 5888
	pushw	226
	ld	(xde), 84
	popw	sp
	.byte 0x55
	ld	xhl, 0xe80b1748
	nop
	.byte 0xbb
	nop
	.ascii "CURVE\""
	ldw	(224:8), 0x8600:io
	nop
	ei	1
	.byte 0xac
	nop
	.byte 0x01
	ldw	(214:8), 0x9a00:io
	nop
	.byte 0xe0
	nop
	.byte 0x9a
	nop
	.byte 0x17
	pushw	226
	.byte 0xd2
	nop
	.byte 0x54
	popw	sp
	.byte 0x55
	ld	xhl, 0xe80b1748
	nop
	.byte 0xdb
	nop
	.ascii "CURVE\""
	ldw	(224:8), 0xa600:io
	nop
	ei	1
	.byte 0xcc
	nop
	.byte 0x01
	ldw	(214:8), 0xba00:io
	nop
	.byte 0xe0
	nop
	.byte 0xba
	nop
	.byte 0x17
	pushw	170
	jrl	le, 21504
	popw	sp
	.byte 0x55
	ld	xhl, 0xb00b1748
	nop
	jrl	ugt, 17152
	.byte 0x55, 0x52, 0x56
	ld	xiy, 0xa80a22
	ld	xiz, 0x6c00ce00
	nop
	.byte 0x01
	ldw	(158:8), 0x5a00:io
	nop
	.byte 0xa8
	nop
	pop	xde
	nop
	.byte 0x17
	pushw	170
	.byte 0x92
	nop
	.byte 0x54
	popw	sp
	.byte 0x55
	ld	xhl, 0xb00b1748
	nop
	.byte 0x9b
	nop
	ld	xhl, 0x45565255
	ld	b, 10:opc
	.byte 0xa8
	nop
	jr	z, 0
	.byte 0xce
	nop
	.byte 0x8c
	nop
	.byte 0x01
	ldw	(158:8), 0x7a00:io
	nop
	.byte 0xa8
	nop
	jrl	gt, 23040
	call	0x5a00f1
	call	0x8400f1
	call	0xae00f1
	call	0xd800f1
	call	0x0200f1
	calr	241
	push	sr
	calr	241
	pushw	ix
	calr	241
	.byte 0xe0
	nop
	ld	xiz, 0x4600e000
	nop
	.byte 0xe0
	nop
	jr	z, 0
	.byte 0xe0
	nop
	.byte 0x86
	nop
	.byte 0xe0
	nop
	.byte 0xa6
	nop
	.byte 0xa8
	nop
	ld	xiz, 0x4600a800
	nop
	.byte 0xa8
	nop
	jr	z, 0
	.byte 0x06
	pushw 0x0110
	.byte 0x50
	ld	xbc, 0x2f314547
	ldw	de, 2839
	ld	xhl, 0x4c003e00
	ld	xiy, 0x174c4556
	pushw	115
	push	xiz
	nop
	.byte 0x54
	popw	sp
	.byte 0x55
	ld	xhl, 0xa30b1748
	nop
	push	xiz
	nop
	ld	xhl, 0x45565255
	.byte 0x17
	pushw	78
	.byte 0xd1
	nop
	popw	ix
	ld	xiy, 0x174c4556
	pushw	124
	.byte 0xd1
	nop
	.byte 0x54
	popw	sp
	.byte 0x55
	ld	xhl, 0xa50b1748
	nop
	.byte 0xd1
	nop
	ld	xhl, 0x45565255
	ei	5
	jp	0x068d22
	halt
	ld	a, 34:opc
	.byte 0x8d
	ei	5
	ld	h, 34:opc
	.byte 0x8d
	ei	5
	add	(xhl+35), xiz
	ei	5
	.byte 0xb1
	ld	c, 142:opc
	ei	5
	.byte 0xb6
	ld	c, 142:opc
	ld	b, 10:opc
	pushw	0x3500
	nop
	.byte 0xd4
	nop
	.byte 0xca
	nop
	ld	b, 10:opc
	.byte 0x51
	nop
	.byte 0xda
	nop
	jr	z, 0
	.byte 0xee
	nop
	ld	b, 10:opc
	.byte 0x81
	nop
	.byte 0xda
	nop
	.byte 0x96
	nop
	.byte 0xee
	nop
	ld	b, 10:opc
	.byte 0xa9
	nop
	.byte 0xda
	nop
	.byte 0xbe
	nop
	.byte 0xee
	nop
	.byte 0x01
	ldw	(11:8), 0x4a00:io
	nop
	.byte 0xd4
	nop
	popw	de
	nop
	.byte 0x01
	ldw	(11:8), 0x6a00:io
	nop
	.byte 0xd4
	nop
	jr	gt, 0
	.byte 0x01
	ldw	(11:8), 0x8a00:io
	nop
	.byte 0xd4
	nop
	.byte 0x8a
	nop
	.byte 0x01
	ldw	(11:8), 0xaa00:io
	nop
	.byte 0xd4
	nop
	.byte 0xaa
	nop
	.byte 0x01
	ldw	(81:8), 0xe400:io
	nop
	.long NakaData_ExternalBase_0x66
	.byte 0x01
	ldw	(129:8), 0xe400:io
	nop
	.byte 0x96
	nop
	.byte 0xe4
	nop
	.byte 0x01, 0x0a
	.long NakaData_ExternalPadBlock_B
	.long Pad_BeforeNakaData_UserMemoryConfig
	push	sr
	ldw	(46:8), 0x3500:io
	nop
	pushw	iz
	nop
	.byte 0xca
	nop
	halt
	ldw	(22:8), 0x4301:io
	nop
	ldw	de, 0x5c01
	nop
	.byte 0x06
	pushw	272
	.ascii "PAGE2/2"
	ldf	16
	jrl	z, 15872
	nop
	popw	hl
	.byte 0x45
	pop	xbc
	.ascii " FOLLOW"
	ldf	7
	ld	xde, 0x30008200
	ldf	7
	pop	xiy
	nop
	.byte 0x82
	nop
	ldw	bc, 1815
	jrl	gt, -32256
	nop
	ldw	de, 1815
	.byte 0x96
	nop
	.byte 0x82
	nop
	ldw	hl, 1815
	ld	(xde), 130
	nop
	ldw	ix, 1815
	.byte 0xce
	nop
	.byte 0x82
	nop
	ldw	iy, 1815
	.byte 0xea
	nop
	.byte 0x82
	nop
	ldw	iz, 2839
	.byte 0x56
	nop
	.byte 0xd1
	nop
	.byte 0x53
	popw	ix
	popw	sp
	.byte 0x50
	ld	xiy, 0xa10b17
	.byte 0xd1
	nop
	.ascii "RANGE "
	ei	155
	.ascii "\"-- "
	.byte 0x06
	ld	xde, (xwa)
	pushw	iy
	pushw	iy
	reti
	halt
	popw	ix
	ld	d, 18:opc
	reti
	halt
	.byte 0x51
	ld	d, 18:opc
	reti
	halt
	.byte 0x56
	ld	d, 18:opc
	reti
	halt
	pop	xhl
	ld	d, 18:opc
	ld	b, 10:opc
	pushw	sp
	nop
	popw	wa
	nop
	swi	7
	nop
	jrl	gt, 256
	ldw	(82:8), 0xdb00:io
	nop
	.byte 0xeb
	nop
	.byte 0xdb
	nop
	push	sr
	ldw	(119:8), 0xcd00:io
	nop
	.long Bitmap_TechnichordBackground_1
	halt
	ldw	(22:8), 0x4301:io
	nop
	ldw	de, 0x5c01
	nop
	halt
	ldw	(83:8), 0xdc00:io
	nop
	.byte 0xea
	nop
	.byte 0xe8
	nop
	.byte 0x17
	pushw	14
	pop	xsp
	nop
	popw	ix
	ld	xiy, 0x174c4556
	ex_ff
	jr	pl, 0
	.byte 0xc3
	nop
	.ascii "LEVEL KEY FOLLOW"
	.byte 0x01
	ldw	(47:8), 0x6100:io
	nop
	swi	7
	nop
	jr	lt, 0
	push	10
	.byte 0x52
	nop
	.byte 0xcd
	nop
	.byte 0xeb
	nop
	.byte 0xe9
	nop
	ldf	14
	jrl	nc, 12288
	nop
	.ascii "ENVELOPE\""
	ldw	(50:8), 0x3a00:io
	nop
	.byte 0x01, 0x01, 0x91
	nop
	ldf	12
	.byte 0xc3
	nop
	.byte 0x97
	nop
	popw	hl
	ld	xiy, 0x46464f59
	.byte 0x17
	push	11
	nop
	.byte 0xcf
	nop
	ld	xbc, 0x0a174b54
	pushw	bc
	nop
	.byte 0xcf
	nop
	.byte 0x50
	ld	xiy, 0x0c174b41
	.byte 0x47
	nop
	.byte 0xcf
	nop
	.ascii "DECAY1"
	.byte 0x17
	pushw	113
	.byte 0xcf
	nop
	.byte 0x53, 0x55, 0x53, 0x54
	ldw	bc, 3095
	.byte 0x9b
	nop
	.byte 0xcf
	nop
	.ascii "DECAY2"
	.byte 0x17
	pushw	197
	.byte 0xcf
	nop
	.byte 0x53, 0x55, 0x53, 0x54
	ldw	de, 3351
	.byte 0xef
	nop
	.byte 0xcf
	nop
	.ascii "RELEASE"
	reti
	halt
	.byte 0x1a
	ld	d, 18:opc
	reti
	halt
	.byte 0x1f
	ld	d, 18:opc
	reti
	halt
	ld	d, 36:opc
	ccf
	reti
	halt
	pushw	bc
	ld	d, 18:opc
	reti
	halt
	pushw	iz
	ld	d, 18:opc
	reti
	halt
	ldw	hl, 4644
	reti
	halt
	push	xbc
	ld	d, 18:opc
	push	10
	pop	sr
	nop
	.byte 0xcb
	nop
	.long NakaInst_2d_d
	.byte 0x01
	ldw	(3:8), 0xd900:io
	nop
	call	0xd901
	halt
	ldw	(4:8), 0xda00:io
	nop
	.byte 0x1c, 0x01, 0xe7
	nop
	halt
	ldw	(22:8), 9985:io
	nop
	ldw	de, 0x3401
	nop
	.byte 0x06
	pushw	272
	.byte 0x50, 0x41
	ld	xsp, 0x322f3245
	ldf	18
	.byte 0x55
	nop
	push	xiz
	nop
	.ascii "KEY FOLLOW ("
	ldf	7
	ld	xde, 0x30008200
	ldf	7
	pop	xiy
	nop
	.byte 0x82
	nop
	ldw	bc, 1815
	jrl	gt, -32256
	nop
	ldw	de, 1815
	.byte 0x96
	nop
	.byte 0x82
	nop
	ldw	hl, 1815
	ld	(xde), 130
	nop
	ldw	ix, 1815
	.byte 0xce
	nop
	.byte 0x82
	nop
	ldw	iy, 1815
	.byte 0xea
	nop
	.byte 0x82
	nop
	ldw	iz, 3607
	push	xiy
	nop
	.byte 0xc3
	nop
	.byte 0x45
	popw	iz
	.ascii "VELOPE"
	.byte 0x17
	push	115
	nop
	.byte 0xc3
	nop
	popw	hl
	ld	xiy, 0x8b0c1759
	nop
	.byte 0xc3
	nop
	ld	xiz, 0x4f4c4c4f
	.byte 0x57, 0x17
	pushw	256
	.byte 0xc3
	nop
	.byte 0x54
	popw	sp
	.byte 0x55
	ld	xhl, 0x07091748
	nop
	.byte 0xd1
	nop
	ld	xbc, 0x0b174b54
	ld	e, 0:opc
	.byte 0xd1
	nop
	ld	xix, 0x59414345
	ldf	13
	popw	bc
	nop
	.byte 0xd1
	nop
	.ascii "RELEASE"
	.byte 0x17
	pushw	158
	.byte 0xd1
	nop
	.byte 0x52
	ld	xbc, 0x1745474e
	incf
	.byte 0xf1
	nop
	.byte 0xd1
	nop
	.ascii "ATTACK"
	.byte 0x17
	pushw	283
	.byte 0xd1
	nop
	ld	xix, 0x59414345
	reti
	halt
	.byte 0xaa
	ld	a, 95:opc
	reti
	halt
	.byte 0xb0
	ld	a, 95:opc
	ei	5
	swi	3
	ld	a, 95:opc
	ei	5
	swi	7
	ld	a, 95:opc
	reti
	halt
	ld	xde, 0x05071224
	ld	xsp, 0x05071224
	popw	ix
	ld	d, 18:opc
	reti
	halt
	.byte 0x51
	ld	d, 18:opc
	reti
	halt
	.byte 0x56
	ld	d, 18:opc
	reti
	halt
	pop	xhl
	ld	d, 18:opc
	reti
	halt
	jr	f, 36
	ccf
	reti
	halt
	jr	z, 36
	ccf
	ld	b, 10:opc
	pushw	sp
	nop
	popw	wa
	nop
	swi	7
	nop
	jrl	gt, 2304
	ldw	(237:8), 0xcd00:io
	nop
	push	xiy
	.byte 0x01, 0xe9
	nop
	.byte 0x01
	ldw	(3:8), 0xda00:io
	nop
	.byte 0xe6
	nop
	.byte 0xda
	nop
	.byte 0x01
	ldw	(237:8), 0xda00:io
	nop
	push	xiy
	.byte 0x01, 0xda
	nop
	push	sr
	ldw	(117:8), 0xcd00:io
	nop
	jrl	mi, -5888
	nop
	halt
	ldw	(22:8), 9985:io
	nop
	ldw	de, 0x3401
	nop
	halt
	ldw	(4:8), 0xdb00:io
	nop
	.byte 0xe5
	nop
	.byte 0xe8
	nop
	halt
	ldw	(238:8), 0xdb00:io
	nop
	push	xix
	.byte 0x01, 0xe8
	nop
	.byte 0x01
	ldw	(47:8), 0x6100:io
	nop
	swi	7
	nop
	jr	lt, 0
	push	10
	pop	sr
	nop
	.byte 0xcd
	nop
	.byte 0xe6
	nop
	.byte 0xe9
	nop
	.byte 0x1c
	incf
	.byte 0x8c
	nop
	halt
	nop
	ld	xiz, 0x45544c49
	.byte 0x52, 0x17
	rcf
	ei	0
	reti
	nop
	.ascii "SOUND EDIT"
	push	10
	.byte 0x04
	nop
	.byte 0x04
	nop
	ld	xix, 0x06001000
	push	139
	.byte 0x06
	.ascii "ENV "
	scf
	ei	7
	.byte 0xea
	ldw	(70:8), 0x4c49:io
	ei	5
	.byte 0xdf
	pushw	1553
	reti
	.byte 0xcb
	incf
	.byte 0x54
	ld	xiy, 0x2b090652
	scf
	popw	ix
	ld	xiz, 0x09112030
	ldw	(20:8), 9473:io
	nop
	ldw	ix, 0x3601
	nop
	push	10
	incf
	.byte 0x01
	ld	xbc, 0x5e013400
	nop
	push	10
	push_a
	.byte 0x01
	jr	ge, 0
	ldw	ix, 0x7a01
	nop
	.byte 0x01
	ldw	(32:8), 0x3d01:io
	nop
	ld	l, 1:opc
	push	xiy
	nop
	.byte 0x01
	ldw	(33:8), 0x3e01:io
	nop
	ld	h, 1:opc
	push	xiz
	nop
	.byte 0x01
	ldw	(34:8), 0x3f01:io
	nop
	ld	e, 1:opc
	push	xsp
	nop
	.byte 0x01
	ldw	(34:8), 0x6001:io
	nop
	ld	e, 1:opc
	jr	f, 0
	.byte 0x01
	ldw	(33:8), 0x6101:io
	nop
	ld	h, 1:opc
	jr	lt, 0
	.byte 0x01
	ldw	(32:8), 0x6201:io
	nop
	ld	l, 1:opc
	jr	le, 0
	push	10
	ld	c, 1:opc
	ldw	iz, 9216
	.byte 0x01
	ld	xbc, 0x230a0900
	.byte 0x01
	pop	xiz
	nop
	ld	d, 1:opc
	jr	ge, 0
	ld	c, 5:opc
	ld	a, 134:opc
	nop
	halt
	ldw	(22:8), 9985:io
	nop
	ldw	de, 0x3401
	nop
	halt
	ldw	(14:8), 0x4301:io
	nop
	ldw	de, 0x5c01
	nop
	halt
	ldw	(22:8), 0x6b01:io
	nop
	ldw	de, 0x7801
	nop
	.byte 0x06
	ld	(136:8), 21:io
	popw	iy
	ldw	wa, 0x4544
	ei	6
	ret
	push_f
	ld	w, 17:opc
	halt
	ldw	(252:8), 0x9500:io
	nop
	ldw	ix, 0xa601
	nop
	halt
	ldw	(14:8), 0x4301:io
	nop
	ldw	de, 0x5c01
	nop
	.byte 0x06
	pushw 0x0110
	.byte 0x50
	ld	xbc, 0x2f314547
	ldw	de, 3351
	.byte 0x43
	nop
	.byte 0x1e
	nop
	.ascii "FILTER:"
	ldf	12
	.byte 0xd5
	nop
	jr	le, 0
	ld	xhl, 0x464f5455
	ld	xiz, 0x430f17
	jr	nov, 0
	.ascii "EQUALIZER"
	.byte 0x17
	ldw	(221:8), 0xb000:io
	nop
	ld	xiz, 0x06514552
	.byte 0x0a
	pushw	sp
	.byte 0x1e
	.ascii "FILTER"
	.byte 0x06, 0x0a
	.byte 0x43, 0x1e
	.ascii "EQUALI "
	halt
	popw	bc
	calr	1626
	ei	74
	calr	21061
	ldf	12
	ei	0
	.byte 0xd1
	nop
	.ascii "CUTOFF"
	.byte 0x17
	ldw	(52:8), 0xd100:io
	nop
	.byte 0x52
	ld	xiy, 0x0b174f53
	pop	xbc
	nop
	.byte 0xd1
	nop
	.byte 0x54
	popw	sp
	.byte 0x55
	ld	xhl, 0x7d0b1748
	nop
	.byte 0xd1
	nop
	ld	xhl, 0x45565255
	.byte 0x17
	pushw	202
	.byte 0xd1
	nop
	.byte 0x52
	ld	xbc, 0x1745474e
	ldw	(244:8), 0xd100:io
	nop
	ld	xiz, 0x17514552
	ldw	(24:8), 0xd101:io
	nop
	ld	xsp, 0x064e4941
	halt
	.byte 0x8c
	ld	b, 75:opc
	ei	5
	.byte 0xa9
	ld	b, 75:opc
	ei	6
	ld	de, (xbc)
	jr	ov, 66
	ei	6
	.byte 0xad
	ld	b, 100:opc
	ld	xde, 0x24420507
	ccf
	reti
	halt
	ld	xsp, 0x05071224
	popw	ix
	ld	d, 18:opc
	reti
	halt
	.byte 0x51
	ld	d, 18:opc
	reti
	halt
	pop	xhl
	ld	d, 18:opc
	reti
	halt
	jr	f, 36
	ccf
	reti
	halt
	jr	mi, 36
	ccf
	ld	b, 10:opc
	ld	xde, 0xe9002700
	nop
	pop	xiz
	nop
	ld	b, 10:opc
	ld	xde, 0xe9007500
	nop
	.byte 0xac
	nop
	push	10
	push	sr
	nop
	.byte 0xcd
	nop
	.byte 0xa0
	nop
	.byte 0xe9
	nop
	push	10
	.byte 0xbb
	nop
	.byte 0xcd
	nop
	push	xix
	.byte 0x01, 0xe9
	nop
	.byte 0x01
	ldw	(146:8), 0x7100:io
	nop
	.byte 0x99
	nop
	jrl	lt, 256
	ldw	(147:8), 0x7200:io
	nop
	.byte 0x98
	nop
	jrl	le, 256
	ldw	(148:8), 0x7300:io
	nop
	.byte 0x97
	nop
	jrl	ule, 256
	ldw	(2:8), 0xdb00:io
	nop
	.byte 0xa0
	nop
	.byte 0xdb
	nop
	.byte 0x01
	ldw	(187:8), 0xdb00:io
	nop
	push	xix
	.byte 0x01, 0xdb
	nop
	push	10
	.byte 0x95
	nop
	jr	f, 0
	.byte 0x96
	nop
	jrl	mi, 1280
	ldw	(3:8), 0xdc00:io
	nop
	.byte 0x9f
	nop
	.byte 0xe8
	nop
	halt
	ldw	(188:8), 0xdc00:io
	nop
	push	xhl
	.byte 0x01, 0xe8
	nop
	ldf	21
	jr	pl, 0
	calr	18432
	popw	bc
	.byte 0x47
	.ascii "H PASS -12dB"
	ldf	20
	jr	pl, 0
	.byte 0x1e
	nop
	.ascii "LOW PASS -12dB"
	ldf	13
	ld	xhl, 0x46004300
	popw	bc
	popw	ix
	.byte 0x54
	ld	xiy, 0x0c173a52
	.byte 0xd3
	nop
	.byte 0x87
	nop
	ld	xhl, 0x464f5455
	ld	xiz, 0x1e390a06
	ld	xiz, 0x45544c49
	.byte 0x52, 0x17
	incf
	.byte 0x56
	nop
	.byte 0xd1
	nop
	.ascii "CUTOFF"
	.byte 0x17
	ldw	(132:8), 0xd100:io
	nop
	.byte 0x52
	ld	xiy, 0x0b174f53
	.byte 0xa9
	nop
	.byte 0xd1
	nop
	.byte 0x54
	popw	sp
	.byte 0x55
	ld	xhl, 0xcd0b1748
	nop
	.byte 0xd1
	nop
	ld	xhl, 0x45565255
	ei	5
	ld	de, (xiz)
	popw	hl
	ei	6
	incw	4, (xhl+34)
	ld	xde, 0x244c0507
	ccf
	reti
	halt
	.byte 0x51
	ld	d, 18:opc
	reti
	halt
	.byte 0x56
	ld	d, 18:opc
	reti
	halt
	pop	xhl
	ld	d, 18:opc
	ld	b, 10:opc
	ld	xde, 0xe9004c00
	nop
	.byte 0x83
	nop
	push	10
	popw	iy
	nop
	.byte 0xcd
	nop
	.byte 0xf0
	nop
	.byte 0xe9
	nop
	.byte 0x01
	ldw	(77:8), 0xdb00:io
	nop
	.byte 0xf0
	nop
	.byte 0xdb
	nop
	halt
	.byte 0x0a
	popw	iz
	nop
	.long NakaState_ZeroBlock_0
	.byte 0xe8
	nop
	ldf	20
	jr	pl, 0
	.byte 0x43
	nop
	.ascii "LOW PASS -24dB"
	ldf	21
	jr	pl, 0
	.byte 0x43
	nop
	.ascii "HIGH PASS -24dB"
	ldf	13
	ld	xhl, 0x46004300
	popw	bc
	popw	ix
	.byte 0x54
	ld	xiy, 0x0f173a52
	jr	pl, 0
	.byte 0x43
	nop
	.ascii "BAND PASS"
	.byte 0x17
	pushw	85
	.byte 0x87
	nop
	.byte 0x7f
	.ascii " LOW"
	ldf	12
	.byte 0xa9
	nop
	.byte 0x87
	nop
	popw	wa
	popw	bc
	ld	xsp, 0x177e2048
	incf
	.byte 0xd4
	nop
	.byte 0x87
	nop
	.ascii "CUTOFF"
	ei	7
	ldw	wa, 0x4c1e
	ldw	wa, 1623
	ld	(63:8), 30:io
	popw	wa
	popw	bc
	ld	xsp, 0x260c1748
	nop
	.byte 0xd1
	nop
	ld	xhl, 0x464f5455
	ld	xiz, 0x540a17
	.byte 0xd1
	nop
	.byte 0x52
	ld	xiy, 0x0c174f53
	jrl	nz, -12032
	nop
	.ascii "CUTOFF"
	.byte 0x17
	ldw	(172:8), 0xd100:io
	nop
	.byte 0x52
	ld	xiy, 0x0b174f53
	.byte 0xd1
	nop
	.byte 0xd1
	nop
	.byte 0x54
	popw	sp
	.byte 0x55
	ld	xhl, 0xf50b1748
	nop
	.byte 0xd1
	nop
	ld	xhl, 0x45565255
	ei	5
	.byte 0x8f
	ld	b, 75:opc
	ei	6
	ld	de, (xix)
	jr	ov, 66
	ei	5
	.byte 0x9b
	ld	b, 75:opc
	ei	6
	ld	xde, (xwa)
	jr	ov, 66
	reti
	halt
	ld	xiz, 0x05071224
	popw	hl
	ld	d, 18:opc
	reti
	halt
	.byte 0x51
	ld	d, 18:opc
	reti
	halt
	.byte 0x56
	ld	d, 18:opc
	reti
	halt
	pop	xhl
	ld	d, 18:opc
	reti
	halt
	jr	f, 36
	ccf
	ld	b, 10:opc
	ld	xde, 0xe9004c00
	nop
	.byte 0x83
	nop
	push	10
	call	0xcd00
	jrl	mi, -5888
	nop
	push	10
	jrl	gt, -13056
	nop
	push_f
	.byte 0x01, 0xe9
	nop
	.byte 0x01
	ldw	(29:8), 0xdb00:io
	nop
	jrl	mi, -9472
	nop
	.byte 0x01
	ldw	(122:8), 0xdb00:io
	nop
	push_f
	.byte 0x01, 0xdb
	nop
	halt
	ldw	(30:8), 0xdc00:io
	nop
	jrl	ov, -6144
	nop
	halt
	ldw	(123:8), 0xdc00:io
	nop
	.byte 0x17, 0x01, 0xe8
	nop
	.byte 0x1c
	decf
	jrl	f, 24576
	nop
	.byte 0x54
	.ascii "HROUGH\""
	ldw	(66:8), 0x4c00:io
	nop
	.byte 0xe9
	nop
	.byte 0x83
	nop
	scf
	ldw	(50:8), 0x6600:io
	nop
	.byte 0x01, 0x01
	jr	z, 0
	ccf
	ldw	(213:8), 0x3a00:io
	nop
	.byte 0xd5
	nop
	.byte 0x91
	nop
	ldf	12
	.byte 0xc3
	nop
	.byte 0x97
	nop
	.ascii "KEYOFF"
	jp	0xc30a
	push	xde
	nop
	.byte 0xe7
	nop
	.byte 0x9d
	nop
	.byte 0x06
	pushw	272
	.byte 0x50, 0x41
	ld	xsp, 0x322f3145
	ldf	14
	jrl	nc, 12288
	nop
	ld	xiy, 0x4c45564e
	popw	sp
	.byte 0x50
	ld	xiy, 0xc30c17
	.byte 0x97
	nop
	.ascii "KEYOFF"
	ei	6
	.byte 0xe6, 0x17, 0x8d
	ld	w, 23:opc
	push	38
	.byte 0x01, 0xaa
	nop
	ld	xhl, 0x09175255
	pushw	ix
	.byte 0x01
	ld	(xhl), 83
	popw	sp
	.byte 0x52
	ei	6
	ld	h, 30:opc
	.byte 0x8e
	ld	w, 23:opc
	push	11
	nop
	.byte 0xcf
	nop
	ld	xbc, 0x0a174b54
	pushw	bc
	nop
	.byte 0xcf
	nop
	.byte 0x50
	ld	xiy, 0x0c174b41
	ld	xsp, 0x4400cf00
	ld	xiy, 0x31594143
	.byte 0x17
	pushw	113
	.byte 0xcf
	nop
	.byte 0x53, 0x55, 0x53, 0x54
	ldw	bc, 3095
	.byte 0x9b
	nop
	.byte 0xcf
	nop
	ld	xix, 0x59414345
	ldw	de, 2839
	.byte 0xc5
	nop
	.byte 0xcf
	nop
	.byte 0x53, 0x55, 0x53, 0x54
	ldw	de, 3351
	.byte 0xef
	nop
	.byte 0xcf
	nop
	.byte 0x52
	ld	xiy, 0x5341454c
	ld	xiy, 0x241a0507
	ccf
	reti
	halt
	.byte 0x1f
	ld	d, 18:opc
	reti
	halt
	ld	d, 36:opc
	ccf
	reti
	halt
	pushw	bc
	ld	d, 18:opc
	reti
	halt
	pushw	iz
	ld	d, 18:opc
	reti
	halt
	ldw	hl, 4644
	reti
	halt
	push	xbc
	ld	d, 18:opc
	ld	b, 10:opc
	ldw	de, 0x3a00
	nop
	.byte 0x01, 0x01, 0x91
	nop
	push	10
	ld	h, 1:opc
	.byte 0x96
	nop
	push	xsp
	.byte 0x01, 0xa5
	nop
	push	10
	pushw	wa
	.byte 0x01, 0x98
	nop
	push	xiy
	.byte 0x01, 0xa3
	nop
	push	10
	push	xix
	nop
	.byte 0xae
	nop
	call	0xcb01
	push	10
	ld	h, 1:opc
	.byte 0xbd
	nop
	push	xsp
	.byte 0x01, 0xcc
	nop
	push	10
	pushw	wa
	.byte 0x01, 0xbf
	nop
	push	xiy
	.byte 0x01, 0xca
	nop
	.byte 0x01
	ldw	(60:8), 0xbc00:io
	nop
	call	0xbc01
	push	sr
	ldw	(138:8), 0xae00:io
	nop
	.byte 0x8a
	nop
	.byte 0xcb
	nop
	push	10
	pop	sr
	nop
	.byte 0xcb
	nop
	call	0xe801
	.byte 0x01
	ldw	(3:8), 0xd900:io
	nop
	call	0xd901
	halt
	ldw	(22:8), 9985:io
	nop
	ldw	de, 0x3401
	nop
	.byte 0x17
	pushw	65
	ld	(xde), 83
	.byte 0x54
	ld	xbc, 0x0b175452
	jr	ule, 0
	ld	(xde), 80
	popw	sp
	popw	bc
	popw	iz
	.byte 0x54, 0x17
	ldw	(142:8), 0xb200:io
	nop
	.byte 0x53, 0x54
	popw	sp
	.byte 0x50, 0x17
	pushw	169
	ld	(xde), 80
	popw	sp
	popw	bc
	popw	iz
	.byte 0x54, 0x17
	incf
	.byte 0xcc
	nop
	ld	(xde), 67
	.byte 0x55, 0x54
	popw	sp
	ld	xiz, 0xf60c1746
	nop
	.byte 0xb2
	nop
	.ascii "ADJUST"
	push	sr
	ldw	(202:8), 0xae00:io
	nop
	.byte 0xca
	nop
	.byte 0xcb
	nop
	.byte 0x06
	pushw	272
	.byte 0x50
	ld	xbc, 0x2f324547
	ldw	de, 2327
	.byte 0x55
	nop
	push	xiz
	nop
	popw	hl
	ld	xiy, 0x6d0c1759
	nop
	push	xiz
	nop
	ld	xiz, 0x4f4c4c4f
	.byte 0x57, 0x17
	reti
	.byte 0x97
	nop
	push	xiz
	nop
	pushw	wa
	ldf	7
	ld	xde, 0x30008200
	ldf	7
	pop	xiy
	nop
	.byte 0x82
	nop
	ldw	bc, 1815
	jrl	gt, -32256
	nop
	ldw	de, 1815
	.byte 0x96
	nop
	.byte 0x82
	nop
	ldw	hl, 1815
	ld	(xde), 130
	nop
	ldw	ix, 1815
	.byte 0xce
	nop
	.byte 0x82
	nop
	ldw	iy, 1815
	.byte 0xea
	nop
	.byte 0x82
	nop
	ldw	iz, 3607
	push	xiy
	nop
	.byte 0xc3
	nop
	.byte 0x45
	.ascii "NVELOPE"
	.byte 0x17
	push	115
	nop
	.byte 0xc3
	nop
	popw	hl
	ld	xiy, 0x8b0c1759
	nop
	.byte 0xc3
	nop
	ld	xiz, 0x4f4c4c4f
	.byte 0x57, 0x17
	pushw	256
	.byte 0xc3
	nop
	.byte 0x54
	popw	sp
	.byte 0x55
	ld	xhl, 0x220c1748
	nop
	.byte 0xd1
	nop
	ld	xbc, 0x43415454
	popw	hl
	.byte 0x17
	pushw	76
	.byte 0xd1
	nop
	ld	xix, 0x59414345
	ldf	13
	jrl	f, -12032
	nop
	.byte 0x52
	ld	xiy, 0x5341454c
	ld	xiy, 0xa40c17
	.byte 0xd1
	nop
	.ascii "CENTER"
	ldf	14
	.byte 0xe6
	nop
	.byte 0xd1
	nop
	ld	xbc, 0x542d5244
	popw	bc
	popw	iy
	ld	xiy, 0x011c0b17
	.byte 0xd1
	nop
	ld	xix, 0x48545045
	reti
	halt
	ld	xsp, 0x05071224
	popw	ix
	ld	d, 18:opc
	reti
	halt
	.byte 0x51
	ld	d, 18:opc
	reti
	halt
	.byte 0x56
	ld	d, 18:opc
	reti
	halt
	jr	f, 36
	ccf
	reti
	halt
	jr	z, 36
	ccf
	ld	b, 10:opc
	pushw	sp
	nop
	popw	wa
	nop
	swi	7
	nop
	.byte 0x7a
	nop
	.long NakaData_ExternalBitmapBlock
	.byte 0xcd
	nop
	push	xiy
	.byte 0x01, 0xe9
	nop
	.byte 0x01
	ldw	(30:8), 0xda00:io
	nop
	.byte 0xce
	nop
	.byte 0xda
	nop
	.byte 0x01
	ldw	(228:8), 0xda00:io
	nop
	push	xiy
	.byte 0x01, 0xda
	nop
	push	sr
	ldw	(158:8), 0xcd00:io
	nop
	.byte 0x9e
	nop
	.byte 0xe9
	nop
	halt
	ldw	(31:8), 0xdb00:io
	nop
	.byte 0xcd
	nop
	.byte 0xe8
	nop
	halt
	ldw	(229:8), 0xdb00:io
	nop
	.long AlignedStr_ON
	halt
	ldw	(22:8), 9985:io
	nop
	ldw	de, 0x3401
	nop
	.byte 0x01
	ldw	(47:8), 0x6100:io
	nop
	swi	7
	nop
	jr	lt, 0
	push	10
	calr	52480
	nop
	.byte 0xce
	nop
	.byte 0xe9
	nop
	push	sr
	retd	1646
	retd	8192
	.byte 0xd4
	pushw	de
	ld	(256:16), 216
	incf
	push	sr
	retd	0
	nop
	nop
	ld	w, 243:opc
	pushw	2
	decf
	nop
	.byte 0xda
	incf
	push	sr
	retd	1647
	retd	8192
	.byte 0xd4
	pushw	de
	ld	(256:16), 216
	scf
	push	sr
	retd	0
	nop
	nop
	ld	w, 3:opc
	incf
	push	sr
	nop
	decf
	nop
	.byte 0xda
	scf
	push	sr
	retd	1648
	retd	8192
	.byte 0xd4
	pushw	de
	ld	(256:16), 216
	ex_ff
	push	sr
	retd	0
	nop
	nop
	ld	w, 19:opc
	incf
	push	sr
	nop
	decf
	nop
	.byte 0xda
	ex_ff
	push	sr
	retd	1649
	retd	8192
	.byte 0xd4
	pushw	de
	ld	(256:16), 216
	jp	3842
	nop
	nop
	nop
	ld	w, 35:opc
	incf
	push	sr
	nop
	decf
	nop
	.byte 0xda
	jp	0x620a00
	.byte 0x06
	jrl	nc, 8192
	link	xbc, 1283
	pushw	1635
	swi	7
	nop
	ld	w, 238:opc
	incf
	push	sr
	nop
	halt
	pushw	1636
	swi	7
	nop
	ld	w, 242:opc
	incf
	push	sr
	nop
	nop
	ldw	(101:8), 0x7f06:io
	nop
	ld	w, 233:opc
	scf
	pop	sr
	halt
	pushw	1638
	swi	7
	nop
	ld	w, 238:opc
	scf
	push	sr
	nop
	halt
	pushw	1639
	swi	7
	nop
	ld	w, 242:opc
	scf
	push	sr
	nop
	nop
	ldw	(104:8), 0x7f06:io
	nop
	ld	w, 233:opc
	ex_ff
	pop	sr
	halt
	pushw	1641
	swi	7
	nop
	ld	w, 238:opc
	ex_ff
	push	sr
	nop
	halt
	pushw	1642
	swi	7
	nop
	ld	w, 242:opc
	ex_ff
	push	sr
	nop
	nop
	ldw	(107:8), 0x7f06:io
	nop
	ld	w, 233:opc
	jp	0x0b0503
	jr	nov, 6
	swi	7
	nop
	ld	w, 238:opc
	jp	0x050002
	pushw	1645
	swi	7
	nop
	ld	w, 242:opc
	jp	0x030002
	pushw	1629
	retd	1280
	.byte 0x53
	pushw	hl
	ld	(0x4100:16), b
	.byte 0x43
	.ascii "DEFGHIJKLMNOPQRSUVWXYZLOW HIGHMONOPOLY"
	xorcf_a_8 a
	.byte 0xf1
	nop
	popw	bc
	pushw	de
	.byte 0xf1
	nop
	popw	bc
	pushw	de
	.byte 0xf1
	nop
	.byte 0x53
	pushw	de
	.byte 0xf1
	nop
	pop	xiz
	pushw	de
	.byte 0xf1
	nop
	jr	ge, 42
	.byte 0xf1
	nop
	jrl	ule, -3798
	nop
	jrl	nz, -3798
	nop
	.byte 0x89
	pushw	de
	.byte 0xf1
	nop
	.byte 0x93
	pushw	de
	.byte 0xf1
	nop
	.byte 0x9e
	pushw	de
	.byte 0xf1
	nop
	.byte 0xa9
	pushw	de
	.byte 0xf1
	nop
	.byte 0xb3
	pushw	de
	.byte 0xf1
	nop
	.byte 0xbe
	pushw	de
	.byte 0xf1
	nop
	.byte 0xd1
	pushw	bc
	.byte 0xf1
	nop
	.byte 0xef
	pushw	bc
	.byte 0xf1
	nop
	decf
	pushw	de
	.byte 0xf1
	nop
	pushw	hl
	pushw	de
	.byte 0xf1
	nop
	popw	bc
	pushw	de
	.byte 0xf1
	nop
	jp	3338
	popw	bc
	nop
	ldw	hl, 0xc501
	nop
	decf
	nop
	popw	bc
	nop
	ldw	hl, 0x6501
	nop
	decf
	nop
	popw	bc
	nop
	ldw	hl, 0x6501
	nop
	decf
	nop
	jr	ge, 0
	ldw	hl, 0x8501
	nop
	decf
	nop
	.byte 0x89
	nop
	ldw	hl, 0xa501
	nop
	decf
	nop
	.byte 0xa9
	nop
	ldw	hl, 0xc501
	nop
	pop	sr
	pushw	1632
	retd	1280
	pushw	0xf12d
	nop
; se_drumkit_display: 329 bytes (293 screen data + 36 DrumKit_VariantSelect_Table)
; Compiled from C source (maincpu/audio/sound_editor_screens/se_drumkit_display.c)
	.incbin "includes/generated/se_drumkit_display.bin"
	.ascii "A:B:C:D:E:F:G:H:I:J:K:L:M:N:O:P:Q:R:S:U:V:W:X:Y:Z:"
	jp	0x3d0a
	jrl	z, -1024
	nop
	ld	(xix), 61
	nop
	jrl	z, -1024
	nop
	.byte 0x84
	nop
	push	xiy
	nop
	jrl	z, -1024
	nop
	.byte 0x84
	nop
	push	xiy
	nop
	.byte 0x86
	nop
	swi	4
	nop
	.byte 0x94
	nop
	push	xiy
	nop
	.byte 0x96
	nop
	swi	4
	nop
	.byte 0xa4
	nop
	push	xiy
	nop
	.byte 0xa6
	nop
	swi	4
	nop
	ld	(xix), 2
	retd	1656
	reti
	nop
	ld	w, 66:opc
	pushw	iy
	ld	(1536:16), 8
	push_f
	.ascii "LPF+EQHPF+EQLPF24 HPF24  BPF   THRU "
; se_general_edit: 96 bytes (7 commands)
; Compiled from C source (maincpu/audio/sound_editor_screens/se_general_edit.c)
	.incbin "includes/generated/se_general_edit.bin"
	jr	z, 45
	.byte 0xf1
	nop
	jrl	lt, -3795
	nop
	jrl	ugt, -3795
	nop
	.byte 0x8a
	pushw	iy
	.byte 0xf1
	nop
	.byte 0x99
	pushw	iy
	.byte 0xf1
	nop
	.ascii "-6-3 0+3+6+9-12- 6  0+ 6+12+18 -- -6 -5 -4 -3 -2 -1  0 +1 +2 +3 +4 +5 +6"
	halt
	pushw	1632
	.byte 0xe0
	halt
	ld	w, 162:opc
	ld	b, 1:opc
	pop	sr
	nop
	ldw	(97:8), 0x3f06:io
	nop
	ld	w, 158:opc
	ld	b, 2:opc
	push	sr
	retd	1634
	jrl	nc, 8192
	.byte 0xf2
	push	xix
	ld	(1280:16), 146
	ld	b, 2:opc
	retd	1635
	reti
	nop
	ld	w, 230:opc
	pushw	iy
	ld	(768:16), 152
	ld	b, 34:opc
	pushw	iz
	.byte 0xf1
	nop
	pushw	iy
	pushw	iz
	.byte 0xf1
	nop
	.byte 0x37
	pushw	iz
	.byte 0xf1
	nop
	ld	xiz, 0x0500f12e
	pushw	1632
	.byte 0xe0
	halt
	ld	w, 167:opc
	ld	b, 1:opc
	pop	sr
	nop
	ldw	(97:8), 0x3f06:io
	nop
	ld	w, 163:opc
	ld	b, 2:opc
	push	sr
	retd	1634
	jrl	nc, 8192
	.byte 0xf2
	push	xix
	ld	(1280:16), 140
	ld	b, 2:opc
	retd	1635
	reti
	nop
	ld	w, 218:opc
	pushw	iy
	ld	(512:16), 146
	ld	b, 2:opc
	retd	1636
	jrl	nc, 8192
	.byte 0xf2
	push	xix
	ld	(1280:16), 152
	ld	b, 2:opc
	retd	1637
	reti
	nop
	ld	w, 218:opc
	pushw	iy
	ld	(512:16), 158
	ld	b, 101:opc
	pushw	iz
	.byte 0xf1
	nop
	jrl	f, -3794
	nop
	jrl	gt, -3794
	nop
	.byte 0x89
	pushw	iz
	.byte 0xf1
	nop
	.byte 0x98
	pushw	iz
	.byte 0xf1
	nop
	.byte 0xa7
	pushw	iz
	.byte 0xf1
	nop
	halt
	pushw	1634
	swi	7
	nop
	ld	w, 226:opc
	call	0x050002
	pushw	1642
	swi	7
	nop
	ld	w, 236:opc
	call	0x050002
	pushw	1633
	swi	7
	nop
	ld	w, 247:opc
	call	2
	ldw	(99:8), 0xff06:io
	nop
	ld	w, 97:opc
	ld	b, 3:opc
	halt
	pushw	1636
	swi	7
	nop
	ld	w, 101:opc
	ld	b, 2:opc
	nop
	nop
	ldw	(101:8), 0x7f06:io
	nop
	ld	w, 106:opc
	ld	b, 3:opc
	halt
	pushw	1638
	swi	7
	nop
	ld	w, 111:opc
	ld	b, 2:opc
	nop
	nop
	ldw	(103:8), 0x7f06:io
	nop
	ld	w, 116:opc
	ld	b, 3:opc
	halt
	pushw	1640
	swi	7
	nop
	ld	w, 121:opc
	ld	b, 2:opc
	nop
	nop
	ldw	(105:8), 0x7f06:io
	nop
	ld	w, 127:opc
	ld	b, 3:opc
	pop	sr
	pushw	1632
	.byte 0x01
	nop
	halt
	ld	xiy, 0x2b00f12f
	pushw	iy
SeMenu_CompareScreen_DataTable:
	.byte 0x3d, 0x00
	.byte 0xbd, 0x00, 0x1c, 0x01, 0xca, 0x00, 0x04, 0x00
	.byte 0xda, 0x00, 0x1c, 0x01, 0xe7, 0x00, 0x1b, 0x0a
	.byte 0x3d, 0x00, 0xbd, 0x00, 0x1c, 0x01, 0xca, 0x00
	.byte 0x1b, 0x0a, 0x04, 0x00, 0xda, 0x00, 0x1c, 0x01
	.byte 0xe7, 0x00, 0x38, 0x2f, 0xf1, 0x00, 0xe4, 0x2e
	.byte 0xf1, 0x00, 0xce, 0x2e, 0xf1, 0x00, 0xef, 0x2e
	.byte 0xf1, 0x00, 0xf9, 0x2e, 0xf1, 0x00, 0x04, 0x2f
	.byte 0xf1, 0x00, 0x0e, 0x2f, 0xf1, 0x00, 0x19, 0x2f
	.byte 0xf1, 0x00, 0x23, 0x2f, 0xf1, 0x00, 0x2e, 0x2f
	.byte 0xf1, 0x00, 0xd9, 0x2e, 0xf1, 0x00
; se_compare_screen: 139 bytes (13 commands)
; Compiled from C source (maincpu/audio/sound_editor_screens/se_compare_screen.c)
	.incbin "includes/generated/se_compare_screen.bin"
	.byte 0x15, 0x30, 0xf1, 0x00, 0x95, 0x2f, 0xf1
	.byte 0x00, 0x9f, 0x2f, 0xf1, 0x00, 0xa9, 0x2f, 0xf1
	.byte 0x00, 0xb3, 0x2f, 0xf1, 0x00, 0xbd, 0x2f, 0xf1
	.byte 0x00, 0xc8, 0x2f, 0xf1, 0x00, 0xd3, 0x2f, 0xf1
	.byte 0x00, 0xde, 0x2f, 0xf1, 0x00, 0xe9, 0x2f, 0xf1
	.byte 0x00, 0xf4, 0x2f, 0xf1, 0x00, 0xff, 0x2f, 0xf1
	.byte 0x00, 0x0a, 0x30, 0xf1, 0x00, 0x1b, 0x0a, 0x0d
	.byte 0x00, 0x4c, 0x00, 0xd2, 0x00, 0xc8, 0x00, 0x0d
	.byte 0x00, 0x4c, 0x00, 0xd2, 0x00, 0x68, 0x00, 0x0d
	.byte 0x00, 0x4c, 0x00, 0xd2, 0x00, 0x68, 0x00, 0x0d
	.byte 0x00, 0x6c, 0x00, 0xd2, 0x00, 0x88, 0x00, 0x0d
	.byte 0x00, 0x8c, 0x00, 0xd2, 0x00, 0xa8, 0x00, 0x0d
	.byte 0x00, 0xac, 0x00, 0xd2, 0x00, 0xc8, 0x00, 0x05
	.byte 0x0b, 0x63, 0x06, 0xff, 0x00, 0x20, 0x93, 0x22
	.byte 0x02, 0x00, 0x02, 0x0f, 0x61, 0x06, 0x7f, 0x00
	.byte 0x20, 0x72, 0x3b, 0xf1, 0x00, 0x03, 0x00, 0x98
	.byte 0x22, 0x02, 0x0f, 0x60, 0x06, 0x7f, 0x00, 0x20
	.byte 0x72, 0x3b, 0xf1, 0x00, 0x03, 0x00, 0x9d, 0x22
	.byte 0x02, 0x0f, 0x62, 0x06, 0x7f, 0x00, 0x20, 0x72
	.byte 0x3b, 0xf1, 0x00, 0x03, 0x00, 0xa2, 0x22, 0xa0
	.byte 0x30, 0xf1, 0x00, 0x91, 0x30, 0xf1, 0x00, 0xaf
	.byte 0x30, 0xf1, 0x00, 0x86, 0x30, 0xf1, 0x00, 0x00
	.byte 0x0a, 0x60, 0x06, 0x7f, 0x00, 0x20, 0x61, 0x22
	.byte 0x03, 0x00, 0x0a, 0x61, 0x06, 0x7f, 0x00, 0x20
	.byte 0x65, 0x22, 0x03, 0x00, 0x0a, 0x62, 0x06, 0x7f
	.byte 0x00, 0x20, 0x6a, 0x22, 0x03, 0x00, 0x0a, 0x63
	.byte 0x06, 0x7f, 0x00, 0x20, 0x6f, 0x22, 0x03, 0x00
	.byte 0x0a, 0x64, 0x06, 0x7f, 0x00, 0x20, 0x74, 0x22
	.byte 0x03, 0x00, 0x0a, 0x65, 0x06, 0x7f, 0x00, 0x20
	.byte 0x79, 0x22, 0x03, 0x00, 0x0a, 0x66, 0x06, 0x7f
	.byte 0x00, 0x20, 0x7f, 0x22, 0x03, 0xce, 0x30, 0xf1
	.byte 0x00, 0xd8, 0x30, 0xf1, 0x00, 0xe2, 0x30, 0xf1
	.byte 0x00, 0xec, 0x30, 0xf1, 0x00, 0xf6, 0x30, 0xf1
	.byte 0x00, 0x00, 0x31, 0xf1, 0x00, 0x0a, 0x31, 0xf1
	.byte 0x00, 0x05, 0x0b, 0x60, 0x06, 0xff, 0x00, 0x20
	.byte 0xa6, 0x22, 0x02, 0x00, 0x05, 0x0b, 0x61, 0x06
	.byte 0xff, 0x00, 0x20, 0xac, 0x22, 0x02, 0x00, 0x02
	.byte 0x0f, 0x62, 0x06, 0x7f, 0x00, 0x06, 0x72, 0x3b
	.byte 0xf1, 0x00, 0x03, 0x00, 0x9c, 0x22, 0x02, 0x0f
	.byte 0x63, 0x06, 0x7f, 0x00, 0x06, 0x72, 0x3b, 0xf1
	.byte 0x00, 0x03, 0x00, 0x97, 0x22, 0x02, 0x0f, 0x64
	.byte 0x06, 0x7f, 0x00, 0x06, 0x72, 0x3b, 0xf1, 0x00
	.byte 0x03, 0x00, 0xa1, 0x22, 0x05, 0x0b, 0x65, 0x06
	.byte 0xff, 0x00, 0x20, 0x89, 0x22, 0x02, 0x00, 0x05
	.byte 0x0b, 0x66, 0x06, 0xff, 0x00, 0x20, 0x8e, 0x22
	.byte 0x02, 0x00, 0x05, 0x0b, 0x67, 0x06, 0xff, 0x00
	.byte 0x20, 0x92, 0x22, 0x02, 0x00, 0x07, 0x11, 0x69
	.byte 0x06, 0x03, 0x00, 0x17, 0xa5, 0x31, 0xf1, 0x00
	.byte 0x08, 0x00, 0x9d, 0x00, 0x3e, 0x00, 0x41, 0x54
	.ascii "TACK) DECAY)  RELEASE)01"
	.byte 0xf1, 0x00, 0x3b, 0x31, 0xf1, 0x00, 0x46, 0x31
	.byte 0xf1, 0x00, 0x55, 0x31, 0xf1, 0x00, 0x64, 0x31
	.byte 0xf1, 0x00, 0x73, 0x31, 0xf1, 0x00, 0x7e, 0x31
	.byte 0xf1, 0x00, 0x89, 0x31, 0xf1, 0x00, 0x94, 0x31
	.byte 0xf1, 0x00, 0x94, 0x31, 0xf1, 0x00
TuningSys_Param_01:
; se_name_editor: 218 bytes (15 commands)
; Compiled from C source (maincpu/audio/sound_editor_screens/se_name_editor.c)
	.incbin "includes/generated/se_name_editor.bin"
.set TuningSys_Param_02, TuningSys_Param_01 + 11
.set TuningSys_Param_03, TuningSys_Param_01 + 22
.set TuningSys_Param_04, TuningSys_Param_01 + 37
.set TuningSys_Param_05, TuningSys_Param_01 + 48
.set TuningSys_Param_06, TuningSys_Param_01 + 59
.set TuningSys_Param_07, TuningSys_Param_01 + 74
.set TuningSys_Param_08, TuningSys_Param_01 + 85
.set TuningSys_Param_09, TuningSys_Param_01 + 96
.set TuningSys_Param_10, TuningSys_Param_01 + 111
.set TuningSys_Param_11, TuningSys_Param_01 + 122
.set TuningSys_Param_12, TuningSys_Param_01 + 133
.set TuningSys_Param_13, TuningSys_Param_01 + 148
.set TuningSys_Param_NamesAndCoords, TuningSys_Param_01 + 163
.set TuningSys_Param_ModeSelect, TuningSys_Param_01 + 207
	.ascii "OFF     PURE MAJPURE MINPHYTHAGOWERCKMEIKIRNBERGOFF     OFF     OFF     OFF     OFF     OFF     OFF     OFF     OFF     OFF     ARABIC1 ARABIC2 ARABIC3 ARABIC4 ARABIC5 SLENDRO PELOG   OFF     OFF     OFF     OFF     OFF     OFF     OFF     OFF     OFF     NORM 1/2 1/4 1/81/161/321/64 FIX"
	decf
	nop
	popw	ix
	nop
	.byte 0xa6
	nop
	jr	0
	decf
	nop
	popw	ix
	nop
	.byte 0xa6
	nop
	jr	0
	decf
	nop
	jr	nov, 0
	.byte 0xa6
	nop
	.byte 0x88
	nop
	decf
	nop
	.byte 0x8c
	nop
	.byte 0xa6
	nop
	.byte 0xa8
	nop
	decf
	nop
	.byte 0xac
	nop
	.byte 0xa6
	nop
	.byte 0xc8
	nop
	ld	(xiy), 67
	nop
	swi	1
	nop
	.byte 0x50
	nop
	ld	(xiy), 67
	nop
	swi	1
	nop
	.byte 0x50
	nop
	ld	(xiy), 107
	nop
	swi	1
	nop
	jrl	-19200
	nop
	.byte 0x93
	nop
	swi	1
	nop
	.byte 0xa0
	nop
	ld	(xiy), 187
	nop
	swi	1
	nop
	.byte 0xc8
	nop
	jp	3338
	popw	ix
	nop
	.byte 0xa6
	nop
	.byte 0xc8
	nop
	jp	0xb50a
	ld	xhl, 0xc800f900
	nop
	.byte 0xa9
	ldw	de, 241
TuningSystem_Handler_Table:
	.long TuningSys_Param_01
	.long TuningSys_Param_02
	.long TuningSys_Param_03
	.long TuningSys_Param_04
	.long TuningSys_Param_05
	.long TuningSys_Param_06
	.long TuningSys_Param_07
	.long TuningSys_Param_08
	.long TuningSys_Param_09
	.long TuningSys_Param_10
	.long TuningSys_Param_11
	.long TuningSys_Param_12
	.long TuningSys_Param_ModeSelect
	.long TuningSys_Param_13
	.long TuningSys_Param_NamesAndCoords
	push	sr
	retd	0x0664
	ld_sd8b	w, 6
	ldw	iz, 0xf135
	nop
	pop	sr
	nop
	ld	de, (xix)
	nop
	ldw	(100:8), 7942:io
	nop
	ld	w, 152:opc
	ld	b, 3:opc
	nop
	ldw	(98:8), 0x7f06:io
	nop
	ld	w, 157:opc
	ld	b, 3:opc
	nop
	ldw	(97:8), 0x7f06:io
	nop
	ld	w, 161:opc
	ld	b, 3:opc
	nop
	ldw	(99:8), 0x3f06:io
	nop
	ld	w, 166:opc
	ld	b, 2:opc
	push	sr
	retd	0x0663
	.byte 0x80, 0x07
	ld	w, 209:opc
	push_a
	ld	(768:16), 171
	ld	b, 3:opc
	pushw 1632
	reti
	nop
	halt
	ld	xde, 0x0200f135
	retd	0x0665
	rcf
	max
	ld	w, 16:opc
	ldw	iy, 241
	normal
	nop
	ldw	de, 522
	retd	0x0666
	rcf
	max
	ld	w, 16:opc
	ldw	iy, 241
	normal
	nop
	ldw	(15:8), 3842:io
	jr	c, 6
	rcf
	max
	ld	w, 16:opc
	ldw	iy, 241
	normal
	nop
	.byte 0xe2, 0x13, 0x02, 0x0f, 0x68
	ei	0x10
	max
	ld	w, 16:opc
	ldw	iy, 241
	normal
	nop
	.byte 0xba, 0x18, 0x2b
	pushw	iy
	.byte 0xc9, 0x34, 0xf1
	nop
	.byte 0xa6, 0x34
	lda	xix, (0x9c00:16)
	lda	xix, (0xb000:16)
	lda	xix, (0x8300:16)
	lda	xix, (0xd400:16)
	lda	xix, (0xe300:16)
	lda	xix, (0xf200:16)
	lda	xiy, (256:16)
	.byte 0xf1, 0x00, 0x53
	.ascii "INTRISQRSAW"
	.byte 0xb6, 0x00, 0x3e, 0x00, 0xda
	.byte 0x00, 0x4b, 0x00, 0xb6, 0x00, 0x3e, 0x00, 0xda
	.byte 0x00, 0x4b, 0x00, 0xb6, 0x00, 0x5e, 0x00, 0xda
	.byte 0x00, 0x6b, 0x00, 0xb6, 0x00, 0x7c, 0x00, 0xda
	.byte 0x00, 0x89, 0x00, 0xb6, 0x00, 0x9c, 0x00, 0xda
	.byte 0x00, 0xa9, 0x00, 0x1b, 0x0a, 0xb6, 0x00, 0x3e
	.byte 0x00, 0xda, 0x00, 0xa9, 0x00, 0x1b, 0x0a, 0x2e
	.byte 0x00, 0x3e, 0x00, 0x4a, 0x00, 0xa9, 0x00, 0x05
	.byte 0x0a, 0x2e, 0x00, 0x3e, 0x00, 0x4a, 0x00, 0x4b
	.byte 0x00, 0x05, 0x0a, 0x2e, 0x00, 0x5d, 0x00, 0x4a
	.byte 0x00, 0x6a, 0x00, 0x05, 0x0a, 0x2e, 0x00, 0x7c
	.byte 0x00, 0x4a, 0x00, 0x89, 0x00, 0x05, 0x0a, 0x2e
	.byte 0x00, 0x9c, 0x00, 0x4a, 0x00, 0xa9, 0x00, 0x7e
	.byte 0x35, 0xf1, 0x00, 0x88, 0x35, 0xf1, 0x00, 0x92
	.byte 0x35, 0xf1, 0x00, 0x9c, 0x35, 0xf1, 0x00, 0xa6
	.byte 0x35, 0xf1, 0x00, 0x1b, 0x0a, 0xdd, 0x00, 0x44
	.byte 0x00, 0xed, 0x00, 0xcb, 0x00, 0x1b, 0x0a, 0x59
	.byte 0x00, 0x43, 0x00, 0xb3, 0x00, 0xa6, 0x00, 0x1b
	.byte 0x0a, 0x4d, 0x00, 0x41, 0x00, 0x58, 0x00, 0xa7
	.byte 0x00, 0x11, 0x0a, 0xde, 0x00, 0x44, 0x00, 0xed
	.byte 0x00, 0x44, 0x00, 0x12, 0x0a, 0xed, 0x00, 0x44
	.byte 0x00, 0xed, 0x00, 0xcb, 0x00, 0x11, 0x0a, 0xde
	.byte 0x00, 0x64, 0x00, 0xed, 0x00, 0x64, 0x00, 0x12
	.byte 0x0a, 0xed, 0x00, 0x64, 0x00, 0xed, 0x00, 0xcb
	.byte 0x00, 0x11, 0x0a, 0xde, 0x00, 0x82, 0x00, 0xed
	.byte 0x00, 0x82, 0x00, 0x12, 0x0a, 0xed, 0x00, 0x82
	.byte 0x00, 0xed, 0x00, 0xcb, 0x00, 0x11, 0x0a, 0xde
	.byte 0x00, 0xa2, 0x00, 0xed, 0x00, 0xa2, 0x00, 0x12
	.byte 0x0a, 0xed, 0x00, 0xa2, 0x00, 0xed, 0x00, 0xcb
	.byte 0x00, 0xd8, 0x35, 0xf1, 0x00, 0xd8, 0x35, 0xf1
	.byte 0x00, 0xec, 0x35, 0xf1, 0x00, 0x00, 0x36, 0xf1
	.byte 0x00, 0x14, 0x36, 0xf1, 0x00, 0x01, 0x0a, 0x5d
	.byte 0x00, 0x46, 0x00, 0xb4, 0x00, 0x46, 0x00, 0x00
	.byte 0x0a, 0x5d, 0x00, 0x46, 0x00, 0xb4, 0x00, 0x65
	.byte 0x00, 0x00, 0x0a, 0x5d, 0x00, 0x46, 0x00, 0xb4
	.byte 0x00, 0x84, 0x00, 0x00, 0x0a, 0x5d, 0x00, 0x46
	.byte 0x00, 0xb4, 0x00, 0xa3, 0x00, 0x00, 0x0a, 0x5d
	.byte 0x00, 0x65, 0x00, 0xb4, 0x00, 0x46, 0x00, 0x01
	.byte 0x0a, 0x5d, 0x00, 0x65, 0x00, 0xb4, 0x00, 0x65
	.byte 0x00, 0x00, 0x0a, 0x5d, 0x00, 0x65, 0x00, 0xb4
	.byte 0x00, 0x84, 0x00, 0x00, 0x0a, 0x5d, 0x00, 0x65
	.byte 0x00, 0xb4, 0x00, 0xa3, 0x00, 0x00, 0x0a, 0x5d
	.byte 0x00, 0x84, 0x00, 0xb4, 0x00, 0x46, 0x00, 0x00
	.byte 0x0a, 0x5d, 0x00, 0x84, 0x00, 0xb4, 0x00, 0x65
	.byte 0x00, 0x01, 0x0a, 0x5d, 0x00, 0x84, 0x00, 0xb4
	.byte 0x00, 0x84, 0x00, 0x00, 0x0a, 0x5d, 0x00, 0x84
	.byte 0x00, 0xb4, 0x00, 0xa3, 0x00, 0x00, 0x0a, 0x5d
	.byte 0x00, 0xa3, 0x00, 0xb4, 0x00, 0x46, 0x00, 0x00
	.byte 0x0a, 0x5d, 0x00, 0xa3, 0x00, 0xb4, 0x00, 0x65
	.byte 0x00, 0x00, 0x0a, 0x5d, 0x00, 0xa3, 0x00, 0xb4
	.byte 0x00, 0x84, 0x00, 0x01, 0x0a, 0x5d, 0x00, 0xa3
	.byte 0x00, 0xb4, 0x00, 0xa3, 0x00, 0x3c, 0x36, 0xf1
	.byte 0x00, 0x64, 0x36, 0xf1, 0x00, 0x8c, 0x36, 0xf1
	.byte 0x00, 0xb4, 0x36, 0xf1, 0x00, 0x17, 0x07, 0x58
	.byte 0x00, 0x43, 0x00, 0x10, 0x17, 0x07, 0x58, 0x00
	.byte 0x62, 0x00, 0x10, 0x17, 0x07, 0x58, 0x00, 0x81
	.byte 0x00, 0x10, 0x17, 0x07, 0x58, 0x00, 0xa0, 0x00
	.byte 0x10, 0xec, 0x36, 0xf1, 0x00, 0xf3, 0x36, 0xf1
	.byte 0x00, 0xfa, 0x36, 0xf1, 0x00, 0x01, 0x37, 0xf1
	.byte 0x00, 0x1c, 0x12, 0x63, 0x00, 0x05, 0x00, 0x4d
	.ascii "EM0RY WRITE"
	.byte 0x17, 0x10, 0x06, 0x00, 0x07
	.byte 0x00
	.ascii "SOUND EDIT"
	reti
	halt
	.byte 0x50
	halt
	rcf
	ld	w, 6:opc
	jrl	gt, 12293
	popw hl
	reti
	.byte 0x09
	jr	nc, 0x0b
	popw iz
	ld	xbc, 0x173a454d
	reti
	ldw	iz, 0x6d01
	nop
	.byte 0x91, 0x07
	halt
	jrl	po, 0x8d11
	reti
	halt
	.byte 0xcf, 0x11, 0xa9, 0x07, 0x13, 0x67, 0x13
	.ascii "MEMORY BANK:  -"
	.byte 0x17, 0x07, 0x36, 0x01, 0x94
	.byte 0x00, 0x91, 0x07, 0x05, 0xbc, 0x17, 0x8e, 0x07
	.byte 0x05, 0xe7, 0x17, 0xa9, 0x07, 0x05, 0xd7, 0x1d
	.byte 0x11, 0x07, 0x10, 0xf0, 0x1d, 0x53, 0x4f, 0x55
	.ascii "ND NAMING"
	.byte 0x09, 0x0a, 0x04, 0x00, 0x04, 0x00, 0x44
	.byte 0x00, 0x10, 0x00, 0x09, 0x0a, 0x0b, 0x00, 0x1e
	.byte 0x00, 0x25, 0x00, 0x31, 0x00, 0x09, 0x0a, 0x0d
	.byte 0x00, 0x20, 0x00, 0x23, 0x00, 0x2f, 0x00, 0x22
	.byte 0x0a, 0x29, 0x00, 0x3c, 0x00, 0xee, 0x00, 0xac
	.byte 0x00, 0x09, 0x0a, 0x12, 0x01, 0x6c, 0x00, 0x35
	.byte 0x01, 0x7f, 0x00, 0x09, 0x0a, 0x14, 0x01, 0x6e
	.byte 0x00, 0x33, 0x01, 0x7d, 0x00, 0x09, 0x0a, 0x12
	.byte 0x01, 0x93, 0x00, 0x35, 0x01, 0xa6, 0x00, 0x09
	.byte 0x0a, 0x14, 0x01, 0x95, 0x00, 0x33, 0x01, 0xa4
	.byte 0x00, 0x22, 0x0a, 0xb1, 0x00, 0xb3, 0x00, 0x30
	.byte 0x01, 0xd6, 0x00, 0x09, 0x0a, 0xf7, 0x00, 0x89
	.byte 0x00, 0x0a, 0x01, 0x8a, 0x00, 0x09, 0x0a, 0x0a
	.byte 0x01, 0x75, 0x00, 0x0b, 0x01, 0x9e, 0x00, 0x01
	.byte 0x0a, 0x29, 0x00, 0x72, 0x00, 0xee, 0x00, 0x72
	.byte 0x00, 0x02, 0x0f, 0x60, 0x06, 0x03, 0x00, 0x07
	.byte 0x38, 0x38, 0xf1, 0x00, 0x01, 0x00, 0x74, 0x13
	.byte 0x00, 0x0a, 0x61, 0x06, 0xff, 0x00, 0x07, 0x76
	.byte 0x13, 0x02, 0x02, 0x0f, 0x00, 0x00, 0x00, 0x00
	.byte 0x07, 0xf3, 0x0b, 0x02, 0x00, 0x10, 0x00, 0x69
	.byte 0x0e, 0x20, 0x41, 0x42, 0x07, 0x05, 0x50, 0x05
	.byte 0x10, 0x06, 0x09, 0x7a, 0x05, 0x57, 0x52, 0x49
	.byte 0x54, 0x45, 0x09, 0x0a, 0x0c, 0x00, 0x1e, 0x00
	.byte 0x3c, 0x00, 0x31, 0x00, 0x09, 0x0a, 0x0e, 0x00
	.byte 0x20, 0x00, 0x3a, 0x00, 0x2f, 0x00, 0x17, 0x10
	.byte 0x06, 0x00, 0x07, 0x00
	.ascii "SOUND EDIT"
	.byte 0x1c, 0x12
	.byte 0x66, 0x00, 0x05, 0x00
	.ascii "S0UND NAMING"
	.byte 0x09, 0x0a, 0x04, 0x00, 0x04, 0x00, 0x44, 0x00
	.byte 0x10, 0x00, 0x06, 0x21, 0x46, 0x10, 0x41, 0x20
	.ascii "B C D E F G H I J K L M N O"
	.byte 0x06, 0x23, 0x9c, 0x12, 0x50
	.ascii " Q R S T U V W X Y Z a b c d e"
	.byte 0x06, 0x23
	.byte 0xf4, 0x14
	.ascii "f g h i j k l m n o p q r s t u"
	.byte 0x06, 0x23, 0x4c, 0x17, 0x76, 0x20, 0x77
	.ascii " x y z 0 1 2 3 4 5 6 7 8 9 !"
	.byte 0x06, 0x23, 0xa4, 0x19
	.ascii "\" # $ % & ' ( ) + - * / = , . @"
	.byte 0x06
	.byte 0x23, 0xfc, 0x1b
	.ascii ": ; ? \\ ^ _ ` | ~ "
	jrl	nc, 0x3c20
	.ascii " > [ ] ( )"
	.byte 0x06, 0x07, 0x9b, 0x05, 0x43, 0x4c
	.byte 0x52, 0x07, 0x05, 0x9f, 0x05, 0x11, 0x07, 0x05
	.byte 0x8b, 0x0b, 0x7e, 0x07, 0x05, 0x8d, 0x0b, 0x7f
	.byte 0x07, 0x05, 0x8f, 0x0b, 0x11, 0x06, 0x05, 0xb4
	.byte 0x0b, 0x20, 0x07, 0x06, 0x98, 0x1e, 0x2e, 0x2e
	.byte 0x06, 0x0c, 0xc9, 0x1e
	.ascii "P0SITI0N"
	.byte 0x06, 0x07, 0xe5, 0x1e
	.byte 0x41, 0x42, 0x43, 0x06, 0x07, 0xea, 0x1e, 0x5d
	.byte 0x28, 0x29, 0x06, 0x05, 0x18, 0x21, 0x8d, 0x06
	.byte 0x0a, 0x12
	.ascii "\"<    >"
	.byte 0x06, 0x11, 0x1b
	.ascii "\"INS  DEL  A/a"
	ei	5
	pushw hl
	ld	b, 60:opc
	ei	5
	ldw	iy, 0x3e22
	ei	5
	swi	0
	ld	b, 142:opc
	ldw	(10:8), 277:io
	call16	0x3200
	normal
	ldw	ix, 2560
	ldw	(21:8), 0x4201:io
	nop
	ldw	de, 0x5a01
	nop
	zcf
	ldw	(15:8), 0x6200:io
	nop
	pushw ix
	normal
	.byte 0xc2, 0x00, 0x0a, 0x0a, 0x05
	nop
	.byte 0xd2, 0x00, 0x22, 0x00, 0xea
	nop
	.byte 0x0a, 0x0a, 0x2d, 0x00, 0xd2, 0x00, 0x4a, 0x00
	.byte 0xea
	nop
	.byte 0x0a, 0x0a, 0x55, 0x00, 0xd2, 0x00, 0x72, 0x00
	.byte 0xea
	nop
	.byte 0x0a, 0x0a, 0x7d, 0x00, 0xd2, 0x00, 0x9a, 0x00
	.byte 0xea
	nop
	.byte 0x0a, 0x0a, 0xa5, 0x00, 0xd2, 0x00, 0xc2, 0x00
	.byte 0xea
	nop
	.byte 0x0a, 0x0a, 0xcd, 0x00, 0xd2, 0x00, 0xea, 0x00
	.byte 0xea
	nop
	.byte 0x0a, 0x0a, 0xf5, 0x00, 0xd2, 0x00, 0x12, 0x01
	.byte 0xea
	nop
	ldw	(10:8), 285:io
	.byte 0xd2, 0x00, 0x3a, 0x01, 0xea
	nop
	normal
	ldw	(245:8), 0xde00:io
	nop
	ccf
	normal
	.byte 0xde, 0x00, 0x0a, 0x0a, 0x4d, 0x00
	push xhl
	nop
	halt
	normal
	.byte 0x51
	nop
	.byte 0x0a, 0x0a, 0x4d, 0x00
	push xhl
	nop
	.byte 0xe5, 0x00, 0x51
	nop
	.byte 0x0a, 0x0a, 0x4d, 0x00
	push xhl
	nop
	jr	po, 0
	.byte 0x51
	nop
	reti
	scf
	nop
	nop
	nop
	nop
	call16	3059
	push	sr
	nop
	rcf
	nop
	.byte 0x51
	nop
	push xsp
	nop
	pop	sr
	pushw 1632
	retd	1280
	.byte 0xc6
	push xde
	.byte 0xf1, 0x00, 0x07, 0x11
	nop
	nop
	nop
	nop
	call16	3059
	push	sr
	nop
	decf
	nop
	.byte 0x51
	nop
	push xsp
	nop
	pop	sr
	pushw 1632
	retd	1280
	.byte 0xc6
	push xde
	.byte 0xf1, 0x00, 0x07, 0x11
	nop
	nop
	nop
	nop
	call16	3059
	push	sr
	nop
	push	sr
	nop
	.byte 0x51
	nop
	push xsp
	nop
	pop	sr
	pushw 1632
	retd	1280
	.byte 0xc6
	push xde
	.byte 0xf1, 0x00, 0x1b, 0x0a, 0x51
	nop
	push xiz
	nop
	normal
	normal
	popw sp
	nop
	jp	8202
	jr	c, 0
	push_f
	normal
	.byte 0xc0, 0x00, 0x51
	nop
	push xiz
	nop
	pop xix
	nop
	.byte 0x4f
	nop
	pop xix
	nop
	push xiz
	nop
	jr	c, 0
	popw sp
	nop
	jr	c, 0
	push xiz
	nop
	jrl	le, 20224
	nop
	jrl	le, 15872
	nop
	.byte 0x7d, 0x00, 0x4f
	nop
	.byte 0x7d, 0x00, 0x3e
	nop
	.byte 0x88, 0x00, 0x4f
	nop
	.byte 0x88, 0x00, 0x3e, 0x00, 0x93, 0x00
	popw sp
	nop
	.byte 0x93, 0x00
	push xiz
	nop
	.byte 0x9e, 0x00, 0x4f
	nop
	.byte 0x9e, 0x00, 0x3e, 0x00, 0xa9
	nop
	.byte 0x4f
	nop
	.byte 0xa9, 0x00, 0x3e
	nop
	ld	(xix), 79
	nop
	ld	(xix), 62
	nop
	.byte 0xbf, 0x00, 0x4f
	nop
	.byte 0xbf, 0x00, 0x3e
	nop
	.byte 0xca, 0x00
	popw sp
	nop
	.byte 0xca, 0x00
	push xiz
	nop
	.byte 0xd5, 0x00, 0x4f
	nop
	.byte 0xd5, 0x00, 0x3e, 0x00, 0xe0
	nop
	.byte 0x4f
	nop
	.byte 0xe0, 0x00, 0x3e
	nop
	.byte 0xeb, 0x00
	popw sp
	nop
	.byte 0xeb, 0x00
	push xiz
	nop
	.byte 0xf6
	nop
	.byte 0x4f
	nop
	.byte 0xf6
	nop
	push xiz
	nop
	normal
	normal
	popw sp
	nop
	ld	w, 0:opc
	ldw	wa, 0x4000
	nop
	.byte 0x50
	nop
	jr	f, 0
	jrl	f, 0x8000
	nop
	.byte 0x90, 0x00, 0xa0, 0x00
	ld	(xwa), 192
	nop
	.byte 0xd0, 0x00, 0xe0
	nop
	.byte 0xf0, 0x00, 0x00, 0x01
	rcf
	normal
	jr	c, 0
	jrl	z, 0x8500
	nop
	.byte 0x94, 0x00, 0xa3, 0x00
	ld	(xde), 67
	pushw iy
	ldw	de, 0x8844
	pushw iy
	.byte 0x44, 0x2d, 0x32, 0x45
	mul8_rid8 xwa, 0x2d, e
	.ascii "-2F-2FŒ-G-2Aˆ-A-"
	ldw	de, 0x8842
	pushw iy
	ld	xde, 0xb043322d
	ld	w, 68:opc
	.byte 0x88, 0xb0, 0x44, 0xb0, 0x20
	ld	xiy, 0xb045b088
	ld	w, 70:opc
	.byte 0xb0, 0x20
	ld	xiz, 0xb047b08c
	ld	w, 65:opc
	.byte 0x88, 0xb0, 0x41, 0xb0, 0x20
	ld	xde, 0xb042b088
	.ascii " C0 Dˆ0D0 E"
	mul8_rid8 xwa, 0x30, e
	.ascii "0 F0 FŒ0G0 Aˆ0A0 Bˆ0B0 C1 Dˆ1D1 Eˆ1E1 F1 FŒ1G1 Aˆ1A1 Bˆ1B1 C2 Dˆ2D2 E"
	mul8_rid8 xwa, 0x32, e
	.ascii "2 F2 FŒ2G2 Aˆ2A2 Bˆ2B2 C3 Dˆ3D3 Eˆ3E3 F3 FŒ3G3 Aˆ3A3 Bˆ3B3 C4 Dˆ4D4 E"
	mul8_rid8 xwa, 0x34, e
	.ascii "4 F4 FŒ4G4 Aˆ4A4 Bˆ4B4 C5 Dˆ5D5 Eˆ5E5 F5 FŒ5G5 Aˆ5A5 Bˆ5B5 C6 Dˆ6D6 E"
	mul8_rid8 xwa, 0x36, e
	.ascii "6 F6 FŒ6G6 Aˆ6A6 Bˆ6B6 C7 Dˆ7D7 Eˆ7E7 F7 FŒ7G7 Aˆ7A7 Bˆ7B7 C8 Dˆ8D8 E"
	mul8_rid8 xwa, 0x38, e
	.ascii "8 F8 FŒ8G8  65.4 69.3 73.4 77.8 82.4 87.3 92.5 98.0103.8110.0116.5123.5130.8138.6146.8155.6164.8174.6185.0196.0207.6220.0233.1246.9261.6277.2293.6311.1329.6349.2370.0392.0415.3440.0466.1493.8523.2554.3587.3622.2659.2698.4739.9783.9830.5879.9932.2987.71.05K1.11K1.17K1.24K1.32K1.40K1.48K1.57K1.66K1.76K1.86K1.98K2.09K2.22K2.35K2.49K2.64K2.79K2.96K3.14K3.32K3.52K3.73K3.95K4.19K4.43K4.70K4.98K5.27K5.59K5.92K6.27K6.64K7.04K7.46K7.90K8.37K8.87K9.40K9.96K10.5K11.2K11.8K12.5K13.3K14.1K14.9K15.8K16.7K17.7K18.8K19.9K21.1K 22K  23K  24K  25K  26K  27K  28K  29K  30K  31K  32K  33K  34K  35K  36K  37K  38K  39K  40K  41K  42K  43K  44K  45K  46K  47K  48K "
	.byte 0x06, 0x0b, 0x10, 0x01, 0x50
	.ascii "AGE3/3"
	ldf	13
	push xbc
	nop
	push xiz
	nop
	.byte 0x54, 0x52
	popw bc
	ld	xsp, 0x17524547
	pushw 134
	push xiz
	nop
	ld	xix, 0x59414c45
	ldf	13
	ld	(xiy), 62
	nop
	.byte 0x50
	ld	xbc, 0x4e494e4e
	ld	xsp, 0x0c300506
	rcf
	ei	5
	swi	0
	scf
	rcf
	ei	5
	jrl	f, 4119
	ldf	12
	.byte 0xf7
	nop
	.byte 0x9e, 0x00
	.ascii "REVERB"
	ldf	11
	swi	2
	nop
	.byte 0xa8, 0x00, 0x44
	ld	xiy, 0x06485450
	halt
	push xwa
	call	0x0d1710
	ld	l, 0:opc
	.byte 0xd1, 0x00, 0x54, 0x52
	popw bc
	ld	xsp, 0x17524547
	pushw 124
	.byte 0xd1, 0x00
	ld	xix, 0x59414c45
	ldf	13
	.byte 0xb8, 0x00, 0xd1
	nop
	.byte 0x50
	ld	xbc, 0x4e494e4e
	ld	xsp, TextInput_Prop_NullTerm_0x1
	.byte 0xd1, 0x00
	.ascii "REVERB"
	.byte 0x17
	.byte 0x0b, 0x12, 0x01, 0xd1, 0x00, 0x44, 0x45, 0x50
	.byte 0x54, 0x48, 0x06, 0x05, 0x17, 0x22, 0x8d, 0x06
	.byte 0x05, 0x21, 0x22, 0x8d, 0x06, 0x05, 0x2a, 0x22
	.byte 0x8d, 0x06, 0x05, 0x31, 0x22, 0x8d, 0x06, 0x05
	.byte 0xa7, 0x23, 0x8e, 0x06, 0x05, 0xb1, 0x23, 0x8e
	.byte 0x06, 0x05, 0xba, 0x23, 0x8e, 0x06, 0x05, 0xc1
	.byte 0x23, 0x8e, 0x22, 0x0a, 0x0b, 0x00, 0x38, 0x00
	.byte 0xe6, 0x00, 0xca, 0x00, 0x22, 0x0a, 0xf2, 0x00
	.byte 0x9a, 0x00, 0x21, 0x01, 0xca, 0x00, 0x22, 0x0a
	.byte 0x31, 0x00, 0xda, 0x00, 0x46, 0x00, 0xee, 0x00
	.byte 0x22, 0x0a, 0x81, 0x00, 0xda, 0x00, 0x96, 0x00
	.byte 0xee, 0x00, 0x22, 0x0a, 0xc9, 0x00, 0xda, 0x00
	.long NakaInst_Param_Val01_07
	ld	b, 10:opc
	normal
	normal
	.byte 0xda, 0x00
	ex_ff
	normal
	.byte 0xee, 0x00
	normal
	ldw	(11:8), 0x4a00:io
	nop
	.byte 0xe6
	nop
	popw	de
	nop
	normal
	ldw	(11:8), 0x6a00:io
	nop
	.byte 0xe6
	nop
	jr	gt, 0
	normal
	ldw	(11:8), 0x8a00:io
	nop
	.byte 0xe6
	nop
	.byte 0x8a, 0x00, 0x01, 0x0a, 0x0b, 0x00
	.long NakaData_DescriptorPad_ZeroB
	.byte 0xaa, 0x00, 0x01
	ldw	(242:8), 0xb200:io
	nop
	ld	a, 1:opc
	ld	(xde), 1
	ldw	(49:8), 0xe400:io
	nop
	ld	xiz, 0x0100e400
	ldw	(129:8), 0xe400:io
	nop
	.long NakaData_ExternalPadBlock_A
	normal
	ldw	(201:8), 0xe400:io
	nop
	.byte 0xde, 0x00, 0xe4, 0x00, 0x01, 0x0a
	.long Pad_AfterNakaData_UserMemoryConfig
	.long Pad_BeforeNakaData_StyleBitmapPad
	push	sr
	ldw	(44:8), 0x3800:io
	nop
	pushw	ix
	nop
	.byte 0xca, 0x00
	push	sr
	ldw	(124:8), 0x3800:io
	nop
	jrl	po, 0xca00
	nop
	push	sr
	ldw	(174:8), 0x3800:io
	nop
	.byte 0xae, 0x00, 0xca
	nop
	halt
	ldw	(244:8), 0xb400:io
	nop
	.byte 0x1f
	normal
	.byte 0xc8, 0x00
	push 10
	ld	xiy, 0xfb00cc00
	nop
	.byte 0xe9, 0x00
	ei	0x0d
	.byte 0xbd, 0x04, 0x4b, 0x45
	.ascii "Y LAYER"
	.byte 0x17
	.byte 0x07, 0x39, 0x00, 0x2a, 0x00, 0x30, 0x17, 0x07
	.byte 0x54, 0x00, 0x2a, 0x00, 0x31, 0x17, 0x07, 0x71
	.byte 0x00, 0x2a, 0x00, 0x32, 0x17, 0x07, 0x8d, 0x00
	.byte 0x2a, 0x00, 0x33, 0x17, 0x07, 0xa9, 0x00, 0x2a
	.byte 0x00, 0x34, 0x17, 0x07, 0xc5, 0x00, 0x2a, 0x00
	.byte 0x35, 0x17, 0x07, 0xe1, 0x00, 0x2a, 0x00, 0x36
	.byte 0x09, 0x0a, 0x27, 0x00, 0x62, 0x00, 0xf6, 0x00
	.byte 0x63, 0x00, 0x09, 0x0a, 0x27, 0x00, 0x81, 0x00
	.byte 0xf6, 0x00, 0x82, 0x00, 0x09, 0x0a, 0x27, 0x00
	.byte 0xa0, 0x00, 0xf6, 0x00, 0xa1, 0x00, 0x09, 0x0a
	.byte 0x27, 0x00, 0xbf, 0x00, 0xf6, 0x00, 0xc0, 0x00
	.byte 0x05, 0x0a, 0x06, 0x01, 0x44, 0x00, 0x32, 0x01
	.byte 0x5e, 0x00, 0x06, 0x12, 0x5b, 0x05, 0x56, 0x45
	.ascii "LOCITY LAYER"
	.byte 0x17, 0x07, 0x2d, 0x00
	.byte 0x32, 0x00, 0x30, 0x17, 0x08, 0x5b, 0x00, 0x32
	.byte 0x00, 0x33, 0x32, 0x17, 0x08, 0x8a, 0x00, 0x32
	.byte 0x00, 0x36, 0x34, 0x17, 0x08, 0xba, 0x00, 0x32
	.byte 0x00, 0x39, 0x36, 0x17, 0x09, 0xe4, 0x00, 0x33
	.byte 0x00, 0x31, 0x32, 0x37, 0x11, 0x0a, 0x30, 0x00
	.byte 0x3d, 0x00, 0xf0, 0x00, 0x3d, 0x00, 0x09, 0x0a
	.byte 0x30, 0x00, 0x62, 0x00, 0xf0, 0x00, 0x63, 0x00
	.byte 0x09, 0x0a, 0x30, 0x00, 0x81, 0x00, 0xf0, 0x00
	.byte 0x82, 0x00, 0x09, 0x0a, 0x30, 0x00, 0xa0, 0x00
	.byte 0xf0, 0x00, 0xa1, 0x00, 0x09, 0x0a, 0x30, 0x00
	.byte 0xbf, 0x00, 0xf0, 0x00, 0xc0, 0x00, 0x02, 0x0a
	.byte 0x30, 0x00, 0x3c, 0x00, 0x30, 0x00, 0x3e, 0x00
	.byte 0x02, 0x0a, 0x48, 0x00, 0x3c, 0x00, 0x48, 0x00
	.byte 0x3e, 0x00, 0x02, 0x0a, 0x60, 0x00, 0x3c, 0x00
	.byte 0x60, 0x00, 0x3e, 0x00, 0x02, 0x0a, 0x78, 0x00
	.byte 0x3c, 0x00, 0x78, 0x00, 0x3e, 0x00, 0x02, 0x0a
	.byte 0x90, 0x00, 0x3c, 0x00, 0x90, 0x00, 0x3e, 0x00
	.byte 0x02, 0x0a, 0xa8, 0x00, 0x3c, 0x00, 0xa8, 0x00
	.byte 0x3e, 0x00, 0x02, 0x0a, 0xc0, 0x00, 0x3c, 0x00
	.byte 0xc0, 0x00, 0x3e, 0x00, 0x02, 0x0a, 0xd8, 0x00
	.byte 0x3c, 0x00, 0xd8, 0x00, 0x3e, 0x00, 0x02, 0x0a
	.byte 0xf0, 0x00, 0x3c, 0x00, 0xf0, 0x00, 0x3e, 0x00
	.byte 0x05, 0x0a, 0x06, 0x01, 0x6a, 0x00, 0x32, 0x01
	.byte 0x84, 0x00, 0x17, 0x0c, 0x08, 0x00, 0x5f, 0x00
	.ascii "CUTOFF"
	.byte 0x17, 0x17
	.byte 0x6a, 0x00, 0xc3, 0x00
	.ascii "FILTER KEY FOLLOW"
	halt
	ldw	(14:8), 0x4301:io
	nop
	ldw	de, 0x5c01
	nop
	ei	8
	ldf	10
	popw ix
	ld	xiz, 0x05063130
	.byte 0xb8, 0x0b, 0x10
	ei	8
	ldf	15
	popw ix
	ld	xiz, 0x05063230
	.byte 0xa8, 0x11, 0x10
	ei	8
	.byte 0xc7, 0x13, 0x4c
	ld	xiz, 0x05063330
	.byte 0xc0, 0x17, 0x10
	ei	8
	.byte 0xc7, 0x18, 0x4c
	ld	xiz, 0x05063430
	.byte 0xb0, 0x1d
	rcf
	ei	7
	ld	w, (xix)
	popw ix
	ld	xiz, 0x600a1730
	nop
	.byte 0xd0, 0x00, 0x57
	ld	xbc, 0x0b174556
	jrl	nz, 0xd000
	nop
	ld	xix, 0x59414c45
	ldf	11
	.byte 0xa2, 0x00, 0xd0, 0x00, 0x53, 0x50
	ld	xiy, 0x0b174445
	.byte 0xc6
	nop
	.byte 0xd0, 0x00
	ld	xix, 0x48545045
	ldf	11
	.byte 0xea, 0x00, 0xd0, 0x00, 0x54
	popw sp
	.byte 0x55
	ld	xhl, 0x0e0d1748
	normal
	.byte 0xd0, 0x00, 0x4b
	ld	xiy, 0x4e595359
	.byte 0x43, 0x06, 0x0a, 0x64
	.ascii "\"SELECT"
	.byte 0x07
	.byte 0x05, 0x47, 0x24, 0x12, 0x07, 0x05, 0x4c, 0x24
	.byte 0x12, 0x07, 0x05, 0x51, 0x24, 0x12, 0x07, 0x05
	.byte 0x56, 0x24, 0x12, 0x07, 0x05, 0x5b, 0x24, 0x12
	.byte 0x07, 0x05, 0x60, 0x24, 0x12, 0x07, 0x05, 0x65
	.byte 0x24, 0x12, 0x09, 0x0a, 0x2c, 0x00, 0x3c, 0x00
	.byte 0x4c, 0x00, 0x4d, 0x00, 0x09, 0x0a, 0xb4, 0x00
	.byte 0x3c, 0x00, 0xdc, 0x00, 0x4d, 0x00, 0x09, 0x0a
	.byte 0x2c, 0x00, 0x5b, 0x00, 0x4c, 0x00, 0x6c, 0x00
	.byte 0x09, 0x0a, 0xb4, 0x00, 0x5c, 0x00, 0xdc, 0x00
	.byte 0x6d, 0x00, 0x09, 0x0a, 0x2c, 0x00, 0x7a, 0x00
	.byte 0x4c, 0x00, 0x8b, 0x00, 0x09, 0x0a, 0xb4, 0x00
	.byte 0x7a, 0x00, 0xdc, 0x00, 0x8b, 0x00, 0x09, 0x0a
	.byte 0x2c, 0x00, 0x9a, 0x00, 0x4c, 0x00, 0xab, 0x00
	.byte 0x09, 0x0a, 0xb4, 0x00, 0x9a, 0x00, 0xdc, 0x00
	.byte 0xab, 0x00, 0x09, 0x0a, 0x59, 0x00, 0xcc, 0x00
	.long NakaData_TechnichordBitmap2
	ld	b, 10:opc
	call	0xcd00
	.byte 0x52
	nop
	.byte 0xe8, 0x00
	scf
	ldw	(24:8), 0x4400:io
	nop
	pushw	ix
	nop
	ld	xix, 0x080a1100
	nop
	.byte 0x4f
	nop
	push_f
	nop
	.byte 0x4f
	nop
	scf
	ldw	(24:8), 0x6400:io
	nop
	pushw	ix
	nop
	jr	pe, 0
	scf
	ldw	(8:8), 0x7500:io
	nop
	push_f
	nop
	jrl	mi, 4352
	ldw	(24:8), 0x8200:io
	nop
	pushw	ix
	nop
	.byte 0x82, 0x00
	scf
	ldw	(8:8), 0x9c00:io
	nop
	push_f
	nop
	.byte 0x9c, 0x00, 0x11
	ldw	(31:8), 0xa200:io
	nop
	pushw	ix
	nop
	.byte 0xa2, 0x00
	scf
	ldw	(8:8), 0xc200:io
	nop
	.byte 0x1f
	nop
	.byte 0xc2, 0x00, 0x12, 0x0a, 0x18
	nop
	ld	xix, 0x4f001800
	nop
	ccf
	ldw	(24:8), 0x6400:io
	nop
	push_f
	nop
	jrl	mi, 4608
	ldw	(24:8), 0x8200:io
	nop
	push_f
	nop
	.byte 0x9c, 0x00, 0x12
	ldw	(31:8), 0xa200:io
	nop
	.byte 0x1f
	nop
	.byte 0xc2, 0x00, 0x01, 0x0a, 0x59
	nop
	.byte 0xdb, 0x00
	push	xiy
	normal
	.byte 0xdb, 0x00
	halt
	ldw	(22:8), 0x6b01:io
	nop
	ldw	de, 0x7801
	nop
	halt
	ldw	(90:8), 0xdc00:io
	nop
	.long AlignedStr_ON
; se_rhythm_transport_tables: 220 bytes (16 commands + 2 dispatch tables)
; RhythmTransport_Control_Table (6 entries) + DrumSound_ParamEdit_Table (10 entries)
; Compiled from C source (maincpu/audio/sound_editor_screens/se_rhythm_transport_tables.c)
	.incbin "includes/generated/se_rhythm_transport_tables.bin"
; se_parameter_grid: 221 bytes (17 commands)
; Compiled from C source (maincpu/audio/sound_editor_screens/se_parameter_grid.c)
	.incbin "includes/generated/se_parameter_grid.bin"
	.byte 0x91, 0x45
	ld	(0xe700:16), d
	ld	(8960:16), e
	ld	(0x2d00:16), e
	ld	(0x3700:16), e
	ld	(0x4100:16), e
	ld	(0x9c00:16), e
	ld	(0xa600:16), e
	ld	(0xb000:16), e
	ld	(0xba00:16), e
	ld	(0x4b00:16), e
	ld	(0x5500:16), e
	ld	(0x9c00:16), e
	ld	(0xa600:16), e
	ld	(0xb000:16), e
	ld	(0xba00:16), e
	.byte 0xf1, 0x00, 0x02, 0x0f
	jr	le, 6
	.byte 0x80, 0x07
	ld	w, 118:opc
	ld	xiz, 0x0700f1
	.byte 0x4f
	decf
	push	sr
	retd	0x0663
	.byte 0x80, 0x07
	ld	w, 118:opc
	ld	xiz, 0x0700f1
	jrl	c, 530
	retd	0x0664
	.byte 0x80, 0x07
	ld	w, 118:opc
	ld	xiz, 0x0700f1
	.byte 0x4f
	ldf	2
	retd	0x0665
	.byte 0x80, 0x07
	ld	w, 118:opc
	ld	xiz, 0x0700f1
	popw sp
	call16	0x4604
	ld	(1024:16), h
	ld	(1024:16), h
	ld	(4864:16), h
	ld	(8704:16), h
	ld	(0x3100:16), h
	.byte 0xf1, 0x00
	.ascii "CTRL  R  KEY ON KEY OFFLEGATO NON LEGCHORD  "
	.byte 0x1b, 0x0a, 0x0d
	.byte 0x00, 0x4c, 0x00, 0xe4, 0x00, 0xc8, 0x00, 0x0d
	.byte 0x00, 0x4c, 0x00, 0xe4, 0x00, 0x68, 0x00, 0x0d
	.byte 0x00, 0x4c, 0x00, 0xe4, 0x00, 0x68, 0x00, 0x0d
	.byte 0x00, 0x6c, 0x00, 0xe4, 0x00, 0x88, 0x00, 0x0d
	.byte 0x00, 0x8c, 0x00, 0xe4, 0x00, 0xa8, 0x00, 0x0d
	.byte 0x00, 0xac, 0x00, 0xe4, 0x00, 0xc8, 0x00, 0x02
	.byte 0x0f, 0x62, 0x06, 0x7f, 0x00, 0x20, 0x72, 0x3b
	.byte 0xf1, 0x00, 0x03, 0x00, 0x92, 0x22, 0x02, 0x0f
	.byte 0x61, 0x06, 0x7f, 0x00, 0x20, 0x72, 0x3b, 0xf1
	.byte 0x00, 0x03, 0x00, 0x98, 0x22, 0x02, 0x0f, 0x63
	.byte 0x06, 0x7f, 0x00, 0x20, 0x72, 0x3b, 0xf1, 0x00
	.byte 0x03, 0x00, 0x9d, 0x22, 0x02, 0x0f, 0x64, 0x06
	.byte 0x7f, 0x00, 0x20, 0x72, 0x3b, 0xf1, 0x00, 0x03
	.byte 0x00, 0xa2, 0x22, 0x03, 0x0b, 0x5d, 0x06, 0x0f
	.byte 0x00, 0x05, 0x1b, 0x47, 0xf1, 0x00, 0xf2, 0x46
	.byte 0xf1, 0x00, 0xc5, 0x46, 0xf1, 0x00, 0xb6, 0x46
	.byte 0xf1, 0x00, 0xd4, 0x46, 0xf1, 0x00, 0xe3, 0x46
	.byte 0xf1, 0x00, 0x1b, 0x0a, 0x08, 0x00, 0x49, 0x00
	.byte 0xfa, 0x00, 0xc5, 0x00, 0x08, 0x00, 0x49, 0x00
	.byte 0xfa, 0x00, 0x67, 0x00, 0x08, 0x00, 0x49, 0x00
	.byte 0xfa, 0x00, 0x67, 0x00, 0x08, 0x00, 0x68, 0x00
	.byte 0xfa, 0x00, 0x86, 0x00, 0x08, 0x00, 0x87, 0x00
	.byte 0xfa, 0x00, 0xa5, 0x00, 0x08, 0x00, 0xa6, 0x00
	.byte 0xfa, 0x00, 0xc5, 0x00, 0x00, 0x0a, 0x62, 0x06
	.byte 0x7f, 0x00, 0x20, 0x91, 0x22, 0x03, 0x00, 0x0a
	.byte 0x61, 0x06, 0x7f, 0x00, 0x20, 0x97, 0x22, 0x03
	.byte 0x00, 0x0a, 0x63, 0x06, 0x7f, 0x00, 0x20, 0x9d
	.byte 0x22, 0x03, 0x00, 0x0a, 0x64, 0x06, 0x7f, 0x00
	.byte 0x20, 0xa2, 0x22, 0x03, 0x03, 0x0b, 0x5d, 0x06
	.byte 0x0f, 0x00, 0x05, 0x1b, 0x47, 0xf1, 0x00, 0x6b
	.byte 0x47, 0xf1, 0x00, 0x4d, 0x47, 0xf1, 0x00, 0x43
	.byte 0x47, 0xf1, 0x00, 0x57, 0x47, 0xf1, 0x00, 0x61
	.byte 0x47, 0xf1, 0x00, 0x05, 0x0b, 0x60, 0x06, 0xff
	.byte 0x00, 0x20, 0xa6, 0x22, 0x02, 0x00, 0x05, 0x0b
	.byte 0x61, 0x06, 0xff, 0x00, 0x20, 0xac, 0x22, 0x02
	.byte 0x00, 0x02, 0x0f, 0x62, 0x06, 0x7f, 0x00, 0x06
	.byte 0x72, 0x3b, 0xf1, 0x00, 0x03, 0x00, 0x9d, 0x22
	.byte 0x05, 0x0b, 0x63, 0x06, 0xff, 0x00, 0x20, 0x8d
	.byte 0x22, 0x02, 0x00, 0x05, 0x0b, 0x64, 0x06, 0xff
	.byte 0x00, 0x20, 0x92, 0x22, 0x02, 0x00, 0x05, 0x0b
	.byte 0x65, 0x06, 0xff, 0x00, 0x20, 0x97, 0x22, 0x02
	.byte 0x00, 0x07, 0x11, 0x69, 0x06, 0x03, 0x00, 0x17
	.byte 0xa5, 0x31, 0xf1, 0x00, 0x08, 0x00, 0x9d, 0x00
	.byte 0x3e, 0x00, 0x8a, 0x47, 0xf1, 0x00, 0x95, 0x47
	.byte 0xf1, 0x00, 0xa0, 0x47, 0xf1, 0x00, 0xaf, 0x47
	.byte 0xf1, 0x00, 0xba, 0x47, 0xf1, 0x00, 0xc5, 0x47
	.byte 0xf1, 0x00, 0xd0, 0x47, 0xf1, 0x00, 0xd0, 0x47
	.byte 0xf1, 0x00, 0xd0, 0x47, 0xf1, 0x00, 0xd0, 0x47
	.byte 0xf1, 0x00, 0x1c, 0x10, 0x72, 0x00, 0x05, 0x00
	.ascii "C0NTR0LLER"
	.byte 0x17, 0x10, 0x06, 0x00, 0x07, 0x00
	.ascii "SOUND EDIT"
	push 10
	max
	nop
	max
	nop
	ld	xix, 0x23001000
	halt
	pop xsp
	.byte 0x83, 0x00
	ld	c, 5:opc
	pop xsp
	.byte 0x83, 0x00
	reti
	ei	31
	pushw 0x5f5f
	reti
	halt
	jr	t, 11
	rcf
	reti
	halt
	.byte 0x8f, 0x0b, 0x11
	reti
	ei	191
	rcf
	pop xsp
	pop xsp
	reti
	halt
	.byte 0xa8, 0x11, 0x10
	reti
	halt
	.byte 0xcf, 0x11
	scf
	ldf	11
	.byte 0x0a, 0x00, 0x86, 0x00
	ld	xbc, 0x52455446
	ldf	11
	pushw iz
	nop
	.byte 0x86, 0x00, 0x54
	popw sp
	.byte 0x55
	ld	xhl, 0x67090648
	.byte 0x20
	ld	xix, 0x48545045
	ei	0x0c
	popw	hl
	.ascii "!FUNCTION"
	.byte 0x07, 0x05, 0x1e, 0x24, 0x12, 0x07, 0x05
	.byte 0x51, 0x24, 0x12, 0x07, 0x05, 0x57, 0x24, 0x12
	.byte 0x07, 0x05, 0x5c, 0x24, 0x12, 0x09, 0x0a, 0x4b
	.byte 0x00, 0x48, 0x00, 0x2c, 0x01, 0x5b, 0x00, 0x09
	.byte 0x0a, 0x4b, 0x00, 0x6c, 0x00, 0x2c, 0x01, 0x7f
	.byte 0x00, 0x22, 0x0a, 0x13, 0x00, 0xcc, 0x00, 0x5d
	.byte 0x00, 0xe7, 0x00, 0x09, 0x0a, 0x75, 0x00, 0xcc
	.byte 0x00, 0xa4, 0x00, 0xe9, 0x00, 0x02, 0x0a, 0xbc
	.byte 0x00, 0x48, 0x00, 0xbc, 0x00, 0x5b, 0x00, 0x02
	.byte 0x0a, 0xbc, 0x00, 0x6c, 0x00, 0xbc, 0x00, 0x7f
	.byte 0x00, 0x23, 0x05, 0x60, 0x1b, 0x0b, 0x23, 0x05
	.byte 0x39, 0xbb, 0x10, 0x05, 0x0a, 0x76, 0x00, 0xdc
	.byte 0x00, 0xa3, 0x00, 0xe8, 0x00, 0x06, 0x13, 0x6f
	.ascii " 1ST 2ND 3RD 4TH"
	.byte 0x07, 0x05, 0x61, 0x24, 0x12, 0x07, 0x05, 0x66
	.byte 0x24, 0x12, 0x09, 0x0a, 0xb5, 0x00, 0xcc, 0x00
	.long NakaInst_SequencerComboBox_0x03
	.byte 0x05, 0x0a, 0xb6, 0x00
	.byte 0xdb, 0x00, 0x32, 0x01, 0xe8, 0x00, 0x06, 0x0b
	.ascii "o 1ST 2ND"
	.byte 0x09, 0x0a, 0xb5, 0x00, 0xcc, 0x00, 0xf4
	.byte 0x00, 0xe9, 0x00, 0x05, 0x0a, 0xb6, 0x00, 0xdb
	.byte 0x00, 0xf3, 0x00, 0xe8, 0x00, 0x06, 0x0b, 0x10
	.byte 0x01
	.ascii "PAGE2/2"
	.byte 0x06, 0x16, 0x66, 0x0e
	.ascii "SUSTAIN PEDAL MODE"
	.byte 0x06, 0x05
	.byte 0x79, 0x0e, 0x3a, 0x06, 0x09, 0x36, 0x11, 0x47
	.byte 0x4c, 0x49, 0x44, 0x45
	.byte 0x06, 0x05, 0x49, 0x11
	.byte 0x3a, 0x17, 0x18, 0x26, 0x00, 0xd1, 0x00, 0x53
	.ascii "USTAIN PEDAL MODE"
	.byte 0x17, 0x0b, 0xcc, 0x00, 0xd1, 0x00, 0x47
	.byte 0x4c, 0x49, 0x44, 0x45
	.byte 0x06, 0x05, 0x1c, 0x22
	.byte 0x8d, 0x06, 0x05, 0x2b, 0x22, 0x8d, 0x06, 0x05
	.byte 0xac, 0x23, 0x8e, 0x06, 0x05, 0xbb, 0x23, 0x8e
	.byte 0x22, 0x0a, 0x21, 0x00, 0x4e, 0x00, 0x18, 0x01
	.byte 0x84, 0x00, 0x22, 0x0a, 0x59, 0x00, 0xda, 0x00
	.long NakaInst_Param_Field48
	.byte 0x22, 0x0a, 0xd1, 0x00
	.long NakaData_DescriptorPad_ZeroC
	.byte 0xee, 0x00, 0x01, 0x0a
	.long Pad_BeforeNakaData_ExternalBase_0x66
	.long Pad_AfterNakaData_ExternalBase_0x66
	normal
	ldw	(209:8), 0xe400:io
	nop
	.byte 0xe6
	nop
	.byte 0xe4, 0x00
; se_transport_display: 141 bytes (14 commands)
; Compiled from C source (maincpu/audio/sound_editor_screens/se_transport_display.c)
	.incbin "includes/generated/se_transport_display.bin"
	pop	xhl
	popw	de
	.byte 0xf1, 0x00, 0xf7, 0x49, 0xf1, 0x00, 0x06, 0x4a, 0xf1, 0x00, 0x15, 0x4a, 0xf1, 0x00, 0x24, 0x4a, 0xf1, 0x00, 0x15, 0x4a, 0xf1, 0x00, 0x24, 0x4a, 0xf1, 0x00, 0x33, 0x4a, 0xf1, 0x00, 0x4f
	.ascii "FF ON---INV-------------PITCH BEND   AMP ENV SUST FILTER CUTOFFPTCH LFO1 DEPPTCH LFO2 DEPPTCH LFO3 DEPPTCH LFO4 DEPAMP LFO1 DEP AMP LFO2 DEP AMP LFO3 DEP AMP LFO4 DEP FLT LFO1 DEP FLT LFO2 DEP FLT LFO3 DEP FLT LFO4 DEP PTCH LFO1 SPDPTCH LFO2 SPDPTCH LFO3 SPDPTCH LFO4 SPDAMP LFO1 SPD AMP LFO2 SPD AMP LFO3 SPD AMP LFO4 SPD FLT LFO1 SPD FLT LFO2 SPD FLT LFO3 SPD FLT LFO4 SPD            28           29           30           31           32           33           34           35           36           37           38           39           40           41           42           43           44           45           46           47           48           49           50           51           52           53           54           55           56           57           58           59           60           61           62           63"
	.byte 0x05, 0x0a, 0x4d, 0x00, 0x4a
	.byte 0x00, 0x2a, 0x01, 0x59, 0x00, 0x05, 0x0a, 0x4d
	.byte 0x00, 0x6e, 0x00, 0x2a, 0x01, 0x7d, 0x00, 0x05
	.byte 0x0a, 0x4d, 0x00, 0x8d, 0x00, 0x2a, 0x01, 0x9c
	.byte 0x00, 0x4d, 0x00, 0x4a, 0x00, 0xba, 0x00, 0x59
	.byte 0x00, 0x4d, 0x00, 0x4a, 0x00, 0xba, 0x00, 0x59
	.byte 0x00, 0xbe, 0x00, 0x4a, 0x00, 0x2a, 0x01, 0x59
	.byte 0x00, 0x4d, 0x00, 0x8d, 0x00, 0xba, 0x00, 0x9c
	.byte 0x00, 0xbe, 0x00, 0x8d, 0x00, 0x2a, 0x01, 0x9c
	.byte 0x00, 0x4d, 0x00, 0x6e, 0x00, 0xba, 0x00, 0x7d
	.byte 0x00, 0xbe, 0x00, 0x6e, 0x00, 0x2a, 0x01, 0x7d
	.byte 0x00
; se_setup_sel3: 30 bytes (2 commands)
; Compiled from C source (maincpu/audio/sound_editor_screens/se_setup_sel3.c)
	.incbin "includes/generated/se_setup_sel3.bin"
	.byte 0x4c
	.ascii "ONGHOLDDISABLEENABLE "
	.byte 0x06, 0x0b, 0x10
	.byte 0x01
	.ascii "PAGE2/3"
	.byte 0x09, 0x0a, 0x65, 0x00, 0x3a, 0x00, 0xc5, 0x00
	.byte 0x48, 0x00, 0x1b, 0x0a, 0x63, 0x00, 0x36, 0x00
	.byte 0xc3, 0x00, 0x44, 0x00, 0x09, 0x0a, 0x63, 0x00
	.byte 0x36, 0x00, 0xc3, 0x00, 0x44, 0x00, 0x1b, 0x0a
	.byte 0x61, 0x00, 0x32, 0x00, 0xc1, 0x00, 0x40, 0x00
	.byte 0x09, 0x0a, 0x61, 0x00, 0x32, 0x00, 0xc1, 0x00
	.byte 0x40, 0x00, 0x1b, 0x0a, 0x5f, 0x00, 0x2e, 0x00
	.byte 0xbf, 0x00, 0x3c, 0x00, 0x09, 0x0a, 0x5f, 0x00
	.byte 0x2e, 0x00, 0xbf, 0x00, 0x3c, 0x00, 0x17, 0x0a
	.byte 0x83, 0x00, 0x23, 0x00
	.byte 0x54, 0x4f, 0x4e, 0x45
	.byte 0x17, 0x13, 0x67, 0x00, 0x32, 0x00, 0x54, 0x4f
	.ascii "NE WAVEFORM"
	.byte 0x17, 0x13, 0x55, 0x00, 0x67
	.byte 0x00
	.ascii "TONE WAVEFORM"
	.byte 0x17, 0x0e
	.byte 0xc3, 0x00, 0x67, 0x00
	.ascii "VELOCITY"
	.byte 0x17, 0x0a, 0x58, 0x00
	.byte 0xc8, 0x00
	.byte 0x54, 0x4f, 0x4e, 0x45
	.byte 0x06, 0x0a
	.ascii "* CURS0R"
	.byte 0x17, 0x0b, 0x24, 0x00, 0xd1, 0x00, 0x47, 0x52
	.byte 0x4f, 0x55, 0x50, 0x17, 0x0e, 0x4c, 0x00, 0xd1
	.byte 0x00
	.ascii "WAVEFORM"
	.byte 0x17, 0x0e, 0xc4, 0x00, 0xd1, 0x00, 0x56
	.ascii "ELOCITY"
	.byte 0x06
	.byte 0x05, 0x16, 0x22, 0x8d, 0x06, 0x05, 0x1c, 0x22
	.byte 0x8d, 0x06, 0x05, 0x2b, 0x22, 0x8d, 0x07, 0x05
	.byte 0x0d, 0x22, 0x8d, 0x06, 0x05, 0xa6, 0x23, 0x8e
	.byte 0x06, 0x05, 0xac, 0x23, 0x8e, 0x06, 0x05, 0xbb
	.byte 0x23, 0x8e, 0x07, 0x05, 0x9d, 0x23, 0x8e, 0x22
	.byte 0x0a, 0x3c, 0x00, 0x61, 0x00, 0xfd, 0x00, 0xb7
	.byte 0x00, 0x22, 0x0a, 0x29, 0x00, 0xda, 0x00, 0x3e
	.byte 0x00, 0xee, 0x00, 0x22, 0x0a, 0x59, 0x00, 0xda
	.byte 0x00, 0x6e, 0x00, 0xee, 0x00, 0x22, 0x0a, 0xd1
	.byte 0x00, 0xda, 0x00, 0xe6, 0x00, 0xee, 0x00, 0x22
	.byte 0x0a, 0x1d, 0x01, 0xda, 0x00, 0x3a, 0x01, 0xee
	.byte 0x00, 0x01, 0x0a, 0x55, 0x00, 0x26, 0x00, 0x80
	.byte 0x00, 0x26, 0x00, 0x01, 0x0a, 0x9d, 0x00, 0x26
	.byte 0x00, 0xcf, 0x00, 0x26, 0x00, 0x09, 0x0a, 0xcf
	.byte 0x00, 0x39, 0x00, 0xf5, 0x00, 0x3a, 0x00, 0x01
	.byte 0x0a, 0xf2, 0x00, 0x3a, 0x00, 0xf5, 0x00, 0x3a
	.byte 0x00, 0x01, 0x0a, 0x55, 0x00, 0x51, 0x00, 0xcf
	.byte 0x00, 0x51, 0x00, 0x01, 0x0a, 0x3c, 0x00, 0x72
	.byte 0x00, 0xfd, 0x00, 0x72, 0x00, 0x01, 0x0a, 0x29
	.byte 0x00, 0xe4, 0x00, 0x3e, 0x00, 0xe4, 0x00, 0x01
	.byte 0x0a, 0x59, 0x00, 0xe4, 0x00, 0x6e, 0x00, 0xe4
	.byte 0x00, 0x01, 0x0a, 0xd1, 0x00, 0xe4, 0x00, 0xe6
	.byte 0x00, 0xe4, 0x00, 0x01, 0x0a, 0x1d, 0x01, 0xe4
	.byte 0x00, 0x3a, 0x01, 0xe4, 0x00, 0x02, 0x0a, 0x55
	.byte 0x00, 0x26, 0x00, 0x55, 0x00, 0x51, 0x00, 0x02
	.byte 0x0a, 0xbd, 0x00, 0x61, 0x00, 0xbd, 0x00, 0xb7
	.byte 0x00, 0x02, 0x0a, 0xcf, 0x00, 0x26, 0x00, 0xcf
	.byte 0x00, 0x51, 0x00, 0x02, 0x0a, 0xf2, 0x00, 0x36
	.byte 0x00, 0xf2, 0x00, 0x3d, 0x00, 0x02, 0x0a, 0xf3
	.byte 0x00, 0x37, 0x00, 0xf3, 0x00, 0x3c, 0x00, 0x02
	.byte 0x0a, 0xf4, 0x00, 0x38, 0x00, 0xf4, 0x00, 0x3b
	.byte 0x00, 0x1c, 0x13, 0x72, 0x00, 0x05, 0x00, 0x54
	.ascii "ONE DYNAMICS"
	.byte 0x17, 0x10, 0x06, 0x00
	.byte 0x07, 0x00
	.ascii "SOUND EDIT"
	.byte 0x09, 0x0a, 0x04, 0x00
	.byte 0x04, 0x00, 0x44, 0x00, 0x10, 0x00, 0x07, 0x05
	.byte 0xb7, 0x0b, 0x11, 0x20, 0x07, 0xdb, 0x0b, 0x59
	.byte 0x45, 0x53, 0x07, 0x05, 0xcf, 0x11, 0x11, 0x20
	.byte 0x06, 0xf3, 0x11, 0x4e, 0x4f, 0x09, 0x0a, 0x13
	.byte 0x01, 0x46, 0x00, 0x35, 0x01, 0x59, 0x00, 0x09
	.byte 0x0a, 0x15, 0x01, 0x48, 0x00, 0x33, 0x01, 0x57
	.byte 0x00, 0x09, 0x0a, 0x13, 0x01, 0x6d, 0x00, 0x35
	.byte 0x01, 0x80, 0x00, 0x09, 0x0a, 0x15, 0x01, 0x6f
	.byte 0x00, 0x33, 0x01, 0x7e, 0x00, 0x08, 0x0e, 0x07
	.byte 0x0a
	.ascii "ATTENTION!"
	.byte 0x07, 0x1e, 0x6c, 0x10, 0x54
	.ascii "HE SELECTED DRUM KIT WILL"
	.byte 0x07, 0x1e, 0xf4, 0x14, 0x42, 0x45, 0x20
	.ascii "COPIED TO THE USER KIT."
	.byte 0x08
	.byte 0x11, 0xf4, 0x19
	.ascii "ARE YOU SURE?\""
	.byte 0x0a, 0x07, 0x00, 0x2f, 0x00, 0x0b, 0x01
	.byte 0xcc, 0x00, 0x09, 0x0a, 0x36, 0x00, 0x50, 0x00
	.byte 0xd4, 0x00, 0x51, 0x00, 0x08, 0x0c, 0xd9, 0x07
	.ascii "ACHTUNG!"
	.byte 0x07, 0x23, 0x89, 0x0e
	.ascii "SIE KOPIEREN EIN PRESET-DRUMKIT"
	.byte 0x07, 0x14, 0x71, 0x12, 0x49
	.ascii "N DAS USER KIT."
	.byte 0x08
	.byte 0x14, 0xa1, 0x19
	.ascii "SIND SIE SICHER?\""
	.byte 0x0a, 0x02, 0x00, 0x21
	.byte 0x00, 0x0b, 0x01, 0xc9, 0x00, 0x09, 0x0a, 0x48
	.byte 0x00, 0x42, 0x00, 0xc6, 0x00, 0x43, 0x00, 0x08
	.byte 0x0e, 0x77, 0x08
	.ascii "ATTENTION!"
	.byte 0x07, 0x1c, 0x8d
	.byte 0x0e
	.ascii "COPIE DU DRUMKIT VERS LE"
	.byte 0x07, 0x0d, 0x75, 0x12, 0x55, 0x53, 0x45
	.ascii "R KIT."
	.byte 0x07, 0x17
	.byte 0x40, 0x18
	.ascii "VEUILLEZ CONFIRMER,"
	.byte 0x07, 0x05, 0xc2
	.byte 0x1a, 0x2c, 0x07, 0x05, 0x51, 0x1c, 0x53, 0x07
	.byte 0x12, 0x53, 0x1c
	.ascii "IL VOUS PLAIT!\""
	.byte 0x0a, 0x03, 0x00, 0x25, 0x00, 0x0e
	.byte 0x01, 0xd2, 0x00, 0x09, 0x0a, 0x36, 0x00, 0x46
	.byte 0x00, 0xd8, 0x00, 0x47, 0x00, 0x08, 0x0d, 0x30
	.byte 0x0a
	.ascii "ATENCION!"
	.byte 0x07, 0x21, 0x7b, 0x0f, 0x43, 0x4f
	.ascii "PIA DEL EQUIPO DE TAMBOR EN"
	.byte 0x07, 0x1a, 0x8b, 0x13, 0x45
	.ascii "L EQUIPO DEL USUARIO."
	.byte 0x08, 0x09, 0x7c
	.byte 0x19, 0xbb, 0x45, 0x53, 0x54, 0xb4, 0x08, 0x0b
	.byte 0x88, 0x19
	.ascii "SEGURO?\""
	.byte 0x0a, 0x07, 0x00, 0x2f, 0x00, 0x0b
	.byte 0x01, 0xcc, 0x00, 0x09, 0x0a, 0x40, 0x00, 0x51
	.byte 0x00, 0xcb, 0x00, 0x52, 0x00, 0x08, 0x0f, 0x56
	.byte 0x0a
	.ascii "ATTENZIONE!"
	.byte 0x07, 0x19, 0xbe, 0x10
	.ascii "COPIATURA DEL DRUMKIT"
	.byte 0x07, 0x05, 0x41
	.byte 0x13, 0x2c, 0x07, 0x07, 0xce, 0x14, 0x41, 0x4c
	.byte 0x4c, 0x07, 0x0d, 0xd2, 0x14, 0x55, 0x53, 0x45
	.ascii "R KIT."
	.byte 0x08, 0x11
	.byte 0xbc, 0x1a
	.ascii "SIETE SICURI?\""
	.byte 0x0a, 0x07, 0x00, 0x2f, 0x00, 0x0b, 0x01, 0xcc
	.byte 0x00, 0x09, 0x0a, 0x2e, 0x00, 0x52, 0x00, 0xdd
	.byte 0x00, 0x53, 0x00, 0x8c, 0x50, 0xf1, 0x00, 0xfb
	.byte 0x50, 0xf1, 0x00, 0x66, 0x51, 0xf1, 0x00, 0xe4
	.byte 0x51, 0xf1, 0x00, 0x54, 0x52, 0xf1, 0x00, 0xba
	.byte 0x52, 0xf1, 0x00, 0x06, 0x05, 0x12, 0x22, 0x8d
	.byte 0x06, 0x05, 0xa2, 0x23, 0x8e, 0x22, 0x0a, 0x09
	.byte 0x00, 0xda, 0x00, 0x1e, 0x00, 0xee, 0x00, 0x01
	.byte 0x0a, 0x09, 0x00, 0xe4, 0x00, 0x1e, 0x00, 0xe4
	.byte 0x00, 0x06, 0x05, 0x17, 0x22, 0x8d, 0x06, 0x05
	.byte 0xa7, 0x23, 0x8e, 0x22, 0x0a, 0x31, 0x00, 0xda
	.byte 0x00, 0x46, 0x00, 0xee, 0x00, 0x01, 0x0a, 0x31
	.byte 0x00, 0xe4, 0x00, 0x46, 0x00, 0xe4, 0x00, 0x06
	.byte 0x05, 0x1c, 0x22, 0x8d, 0x06, 0x05, 0xac, 0x23
	.byte 0x8e, 0x22, 0x0a, 0x59, 0x00, 0xda, 0x00, 0x6e
	.byte 0x00, 0xee, 0x00, 0x01, 0x0a, 0x59, 0x00, 0xe4
	.byte 0x00, 0x6e, 0x00, 0xe4, 0x00, 0x06, 0x05, 0x21
	.byte 0x22, 0x8d, 0x06, 0x05, 0xb1, 0x23, 0x8e, 0x22
	.byte 0x0a, 0x81, 0x00, 0xda, 0x00, 0x96, 0x00, 0xee
	.byte 0x00, 0x01, 0x0a, 0x81, 0x00, 0xe4, 0x00, 0x96
	.byte 0x00, 0xe4, 0x00, 0x06, 0x05, 0x26, 0x22, 0x8d
	.byte 0x06, 0x05, 0xb6, 0x23, 0x8e, 0x22, 0x0a, 0xa9
	.byte 0x00, 0xda, 0x00, 0xbe, 0x00, 0xee, 0x00, 0x01
	.byte 0x0a, 0xa9, 0x00, 0xe4, 0x00, 0xbe, 0x00, 0xe4
	.byte 0x00, 0x06, 0x05, 0x2b, 0x22, 0x8d, 0x06, 0x05
	.byte 0xbb, 0x23, 0x8e, 0x22, 0x0a, 0xd1, 0x00, 0xda
	.byte 0x00, 0xe6, 0x00, 0xee, 0x00, 0x01, 0x0a, 0xd1
	.byte 0x00, 0xe4, 0x00, 0xe6, 0x00, 0xe4, 0x00, 0x06
	.byte 0x05, 0x30, 0x22, 0x8d, 0x06, 0x05, 0xc0, 0x23
	.byte 0x8e, 0x22, 0x0a, 0xf9, 0x00, 0xda, 0x00, 0x0e
	.byte 0x01, 0xee, 0x00, 0x01, 0x0a, 0xf9, 0x00, 0xe4
	.byte 0x00, 0x0e, 0x01, 0xe4, 0x00, 0x06, 0x05, 0x35
	.byte 0x22, 0x8d, 0x06, 0x05, 0xc5, 0x23, 0x8e, 0x22
	.byte 0x0a, 0x21, 0x01, 0xda, 0x00, 0x36, 0x01, 0xee
	.byte 0x00, 0x01, 0x0a, 0x21, 0x01, 0xe4, 0x00, 0x36
	.byte 0x01, 0xe4, 0x00, 0x06, 0x0d, 0x0b, 0x19, 0x49
	.ascii "NTENSITY"
	.byte 0x06, 0x05, 0x19, 0x19, 0x3a, 0x17, 0x0d, 0xf0
	.byte 0x00, 0xd1, 0x00
	.byte 0x49, 0x4e, 0x54, 0x45, 0x4e
	.byte 0x53, 0x2e, 0x23, 0x05, 0x0a, 0x82, 0x00, 0x1c
	.byte 0x14, 0x6f, 0x00, 0x05, 0x00, 0x44, 0x49, 0x47
	.ascii "ITAL EFFECT"
	.byte 0x17, 0x10, 0x06, 0x00, 0x07
	.byte 0x00
	.ascii "SOUND EDIT"
	.byte 0x06, 0x08, 0x03, 0x08, 0x54
	.byte 0x59, 0x50, 0x45, 0x06, 0x05, 0x08, 0x08, 0x3a
	.byte 0x17, 0x07, 0x36, 0x01, 0x46, 0x00, 0x91, 0x07
	.byte 0x05, 0x68, 0x0b, 0x10, 0x07, 0x07, 0x8c, 0x0b
	.byte 0x8d, 0x20, 0x20, 0x07, 0x05, 0xb7, 0x0b, 0xa9
	.byte 0x06, 0x08, 0xaa, 0x0e
	.byte 0x54, 0x59, 0x50, 0x45
	.byte 0x17, 0x07, 0x36, 0x01, 0x6d, 0x00, 0x91, 0x07
	.byte 0x05, 0x80, 0x11, 0x10, 0x07, 0x07, 0xa4, 0x11
	.byte 0x8e, 0x20, 0x20, 0x07, 0x05, 0xcf, 0x11, 0xa9
	.byte 0x06, 0x13, 0x63, 0x1b
	.ascii "REVERB DEPTH  :"
	.byte 0x17, 0x0c, 0x1a, 0x01, 0xd1
	.byte 0x00
	.ascii "REVERB"
	.byte 0x09
	.byte 0x0a, 0x04, 0x00, 0x04, 0x00, 0x44, 0x00, 0x10
	.byte 0x00, 0x22, 0x0a, 0x47, 0x00, 0x2e, 0x00, 0xfb
	.byte 0x00, 0xbb, 0x00, 0x09, 0x0a, 0x12, 0x01, 0x45
	.byte 0x00, 0x35, 0x01, 0x58, 0x00, 0x09, 0x0a, 0x0c
	.byte 0x00, 0x46, 0x00, 0x2c, 0x00, 0x59, 0x00, 0x09
	.byte 0x0a, 0x14, 0x01, 0x47, 0x00, 0x33, 0x01, 0x56
	.byte 0x00, 0x09, 0x0a, 0x0e, 0x00, 0x48, 0x00, 0x2a
	.byte 0x00, 0x57, 0x00, 0x09, 0x0a, 0x0c, 0x00, 0x6c
	.byte 0x00, 0x44, 0x00, 0x7f, 0x00, 0x09, 0x0a, 0x12
	.byte 0x01, 0x6c, 0x00, 0x35, 0x01, 0x7f, 0x00, 0x09
	.byte 0x0a, 0x0e, 0x00, 0x6e, 0x00, 0x42, 0x00, 0x7d
	.byte 0x00, 0x09, 0x0a, 0x14, 0x01, 0x6e, 0x00, 0x33
	.byte 0x01, 0x7d, 0x00, 0x01, 0x0a, 0x47, 0x00, 0x41
	.byte 0x00, 0xfb, 0x00, 0x41, 0x00, 0x23, 0x05, 0x0a
	.byte 0x82, 0x00, 0x06, 0x09, 0xfb, 0x0a, 0x44, 0x45
	.byte 0x50, 0x54, 0x48, 0x06, 0x05, 0x09, 0x0b, 0x3a
	.byte 0x06, 0x09, 0x53, 0x0d
	.byte 0x53, 0x50, 0x45, 0x45
	.byte 0x44, 0x06, 0x05, 0x61, 0x0d, 0x3a, 0x06, 0x0a
	.byte 0xab, 0x0f
	.ascii "DETUNE"
	ei	5
	.byte 0xb9, 0x0f, 0x3a
	ei	9
	pop	sr
	ccf
	ld	xix, 0x59414c45
	ei	5
	scf
	ccf
	push xde
	ei	11
	pop xhl
	push_a
	.byte 0x42
	.ascii "ALANCE"
	ei	5
	jr	ge, 20
	push xde
	ldf	11
	ei	0
	.byte 0xd1, 0x00
	ld	xix, 0x48545045
	ldf	11
	pushw iy
	nop
	.byte 0xd1, 0x00, 0x53, 0x50
	ld	xiy, 0x0c174445
	.byte 0x52
	nop
	.byte 0xd1, 0x00, 0x44
	ld	xiy, 0x454e5554
	ldf	11
	jrl	po, 0xd100
	nop
	ld	xix, 0x59414c45
	ldf	13
	.byte 0xa0, 0x00, 0xd1, 0x00, 0x42, 0x41
	popw	ix
	ld	xbc, 0x0645434e
	.byte 0x0a, 0xfb, 0x0a
	.ascii "DEPTH1"
	.byte 0x06
	.byte 0x05, 0x09, 0x0b, 0x3a, 0x06, 0x0a, 0x53, 0x0d
	.ascii "SPEED1"
	ei	5
	jr	lt, 13
	push xde
	ei	10
	.byte 0xab, 0x0f, 0x44
	ld	xiy, 0x32485450
	ei	5
	.byte 0xb9, 0x0f, 0x3a
	ei	10
	pop	sr
	ccf
	.byte 0x53, 0x50
	ld	xiy, 0x06324445
	halt
	scf
	ccf
	push xde
	ei	10
	pop xhl
	push_a
	ld	xix, 0x4e555445
	ld	xiy, 0x14690506
	push xde
	ei	9
	.byte 0xb3, 0x16, 0x44, 0x45
	popw ix
	ld	xbc, 0xc1050659
	ex_ff
	push xde
	ldf	12
	push	sr
	nop
	.byte 0xd1, 0x00, 0x44, 0x45, 0x50, 0x54
	popw wa
	ldw	bc, 3095
	pushw de
	nop
	.byte 0xd1, 0x00
	.ascii "SPEED1"
	.byte 0x17, 0x0c
	.byte 0x52, 0x00, 0xd1, 0x00
	.byte 0x44, 0x45, 0x50, 0x54
	.byte 0x48, 0x32, 0x17, 0x0c, 0x7a, 0x00, 0xd1, 0x00
	.ascii "SPEED2"
	ldf	12
	.byte 0xa2, 0x00, 0xd1, 0x00, 0x44, 0x45, 0x54, 0x55
	popw iz
	ld	xiy, 0xcd0b17
	.byte 0xd1, 0x00
	ld	xix, 0x59414c45
	ei	9
	swi	3
	.byte 0x0a
	ld	xix, 0x48545045
	ei	5
	push 11
	push xde
	ei	9
	.byte 0x53
	decf
	.byte 0x53, 0x50
	ld	xiy, 0x05064445
	jr	lt, 13
	push xde
	ei	8
	.byte 0xab, 0x0f, 0x57
	ld	xbc, 0x05064556
	.byte 0xb9, 0x0f, 0x3a
	ei	11
	pop	sr
	ccf
	.ascii "BALANCE"
	ei	5
	scf
	ccf
	push xde
	ldf	11
	halt
	nop
	.byte 0xd1, 0x00, 0x44, 0x45, 0x50, 0x54
	popw wa
	ldf	11
	pushw ix
	nop
	.byte 0xd1, 0x00, 0x53, 0x50
	ld	xiy, 0x0a174445
	pop xwa
	nop
	.byte 0xd1, 0x00, 0x57, 0x41, 0x56
	ld	xiy, 0x770d17
	.byte 0xd1, 0x00, 0x42, 0x41
	popw ix
	ld	xbc, 0x0645434e
	ldw	(251:8), 0x440a:io
	ld	xiy, 0x31485450
	ei	0x05
	push 11
	push	xde
	ei	0x0a
	.byte 0x53
	decf
	.byte 0x53, 0x50
	ld	xiy, 0x06314445
	halt
	jr	lt, 13
	push	xde
	ei	0x0a
	.byte 0xab, 0x0f, 0x44
	ld	xiy, 0x32485450
	ei	0x05
	.byte 0xb9, 0x0f, 0x3a
	ei	0x0a
	pop	sr
	ccf
	.byte 0x53, 0x50
	ld	xiy, 0x06324445
	halt
	scf
	ccf
	push	xde
	ldf	12
	push	sr
	nop
	.byte 0xd1, 0x00, 0x44, 0x45, 0x50, 0x54
	popw	wa
	ldw	bc, 3095
	pushw	de
	nop
	.byte 0xd1, 0x00
	.ascii "SPEED1"
	.byte 0x17
	.byte 0x0c, 0x52, 0x00, 0xd1, 0x00, 0x44, 0x45, 0x50
	.byte 0x54, 0x48, 0x32, 0x17, 0x0c, 0x7a, 0x00, 0xd1
	.byte 0x00
	.ascii "SPEED2"
	ei	9
	swi	3
	.byte 0x0a
	ld	xix, 0x59414c45
	ei	5
	push 11
	push xde
	ei	10
	.byte 0x53
	decf
	.ascii "DETUNE"
	.byte 0x06
	.byte 0x05, 0x61, 0x0d, 0x3a, 0x06, 0x0d, 0xab, 0x0f
	.ascii "KEY SHIFT"
	.byte 0x06, 0x05, 0xb9, 0x0f, 0x3a, 0x06, 0x0b
	.byte 0x03, 0x12
	.ascii "BALANCE"
	ei	5
	scf
	ccf
	push xde
	ldf	11
	push	sr
	nop
	.byte 0xd1, 0x00, 0x44, 0x45
	popw ix
	ld	xbc, 0x2a0c1759
	nop
	.byte 0xd1, 0x00, 0x44
	ld	xiy, 0x454e5554
	ldf	9
	pop xhl
	nop
	.byte 0xd1, 0x00, 0x4b, 0x45
	pop xbc
	ldf	13
	jrl	t, 0xd100
	nop
	ld	xde, 0x4e414c41
	ld	xhl, 0xfb090645
	ldw	(83:8), 0x4550:io
	ld	xiy, 0x09050644
	pushw 1594
	push 83
	decf
	ld	xix, 0x59414345
	ei	5
	jr	lt, 13
	push xde
	.byte 0x06
	pushw 0x0fab
	.byte 0x53, 0x55, 0x53, 0x54
	ld	xbc, 0x05064e49
	.byte 0xb9, 0x0f, 0x3a, 0x06
	pushw 0x1203
	.byte 0x52
	ld	xiy, 0x5341454c
	ld	xiy, 0x12110506
	push	xde
	ldf	11
	max
	nop
	.byte 0xd1, 0x00, 0x53, 0x50
	ld	xiy, 0x0b174445
	pushw	iy
	nop
	.byte 0xd1, 0x00
	ld	xix, 0x59414345
	ldf	13
	.byte 0x50
	nop
	.byte 0xd1, 0x00, 0x53, 0x55, 0x53, 0x54
	ld	xbc, 0x0d174e49
	.byte 0x80, 0x00, 0xd1, 0x00
	.ascii "RELEASE"
	.byte 0x06
	.byte 0x0e, 0xfb, 0x0a
	.ascii "DISTORTION"
	.byte 0x06, 0x05, 0x09
	.byte 0x0b, 0x3a, 0x06, 0x0f, 0x53, 0x0d, 0x54, 0x4f
	.ascii "UCH DEPTH"
	ei	5
	jr	lt, 13
	push xde
	ei	9
	.byte 0xab, 0x0f
	ld	xix, 0x48545045
	ei	5
	.byte 0xb9, 0x0f, 0x3a
	ldf	11
	reti
	nop
	.byte 0xd1, 0x00
	ld	xix, 0x2e545349
	ldf	11
	pushw iy
	nop
	.byte 0xd1, 0x00, 0x54, 0x4f, 0x55
	ld	xhl, 0x550b1748
	nop
	.byte 0xd1, 0x00
	ld	xix, 0x48545045
	.byte 0xe1, 0x54, 0xf1, 0x00, 0x64, 0x55
	ld	(0xe100:16), ix
	ld	(0x6400:16), iy
	ld	(0xe100:16), ix
	ld	(0x6400:16), iy
	ld	(0xe100:16), ix
	ld	(0x6400:16), iy
	ld	(0x6400:16), iy
	ld	(1024:16), iz
	ld	(0x6400:16), iy
	ld	(1024:16), iz
	ld	(1024:16), iz
	ld	(0x6a00:16), iz
	ld	(0x6a00:16), iz
	ld	(0xd600:16), iz
	ld	(0xd600:16), iz
	.byte 0xf1, 0x00, 0x42, 0x57, 0xf1, 0x00, 0x42, 0x57, 0xf1, 0x00, 0xae, 0x57, 0xf1, 0x00, 0xae, 0x57, 0xf1, 0x00, 0x04, 0x58, 0xf1, 0x00, 0xae, 0x57, 0xf1, 0x00, 0x04, 0x58, 0xf1, 0x00, 0x02, 0x0f
	jr	f, 6
	retd	0x2000
	normal
	pop	xhl
	ld	(3328:16), 9
	ld	(2:8), 15:io
	jr	f, 6
	.byte 0x80, 0x07
	ld	w, 215:opc
	push_a
	ld	(768:16), 186
	pushw 3842
	jr	f, 6
	ld	xwa, 0x5b9d2006
	ld	(1536:16), 170
	scf
	halt
	pushw 1640
	swi	7
	nop
	ld	w, 115:opc
	jp	0x050002
	pushw 1639
	swi	7
	nop
	ld	w, 27:opc
	pop_f
	push	sr
	nop

	.include "storage/flash_floppy_handlers.s"

S2cShowHideFunc:
	cp xbc, 0x1c0000c
	jr z, S2cShow_ReturnZero
	cp xbc, 0x1c0000b
	jr z, S2cShow_ReturnZero
	cp xbc, 0x1c00002
	jr z, S2cShow_ReturnZero
	cp xbc, 0x1c00001
	jr nz, S2cShow_ReturnZero
	or xde, xde
	jr nz, S2cShow_ReturnZero
	ld (0x3a77:16), 3

S2cShow_ReturnZero:
	ld xhl, 0:i3
	ret

S2cGridCheck:
	lda xsp, (xsp - 18)
	ld xwa, xbc
	cp xbc, 0x1e0008d
	jrl z, S2c_GridCheck_Dispatch
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, S2c_GridCheck_EventEnc
	cp xwa, 0x6
	jrl gt, S2c_GridCheck_EventEnc
	add xwa, xwa
	add xwa, StrBeatOff_0x4
	ld wa, (xwa)
	lda xix, (S2c_GridCheck_DataBlock:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

S2c_GridCheck_DataBlock:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 0x01e0008f
	ld	xde, 0:i3
	call	SendEvent
	ld	xde, xhl
	lda	xwa, (xsp+10)
	ld	xbc, xde
	srl	xbc, 0
	ld	qbc, 0
	ld	(xwa), bc
	ld	(xwa+2), de
	cpw	(xwa), 1
	jrl	nz, 164
	exts	xde
	ld	xwa, 0x0144000e
	ld	xbc, 0x01e40010
	jr	53
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 0x01e0008f
	ld	xde, 0:i3
	call	SendEvent
	ld	xde, xhl
	lda	xwa, (xsp+10)
	ld	xbc, xde
	srl	xbc, 0
	ld	qbc, 0
	ld	(xwa), bc
	ld	(xwa+2), de
	cpw	(xwa), 1
	jr	nz, 109
	exts	xde
	ld	xwa, 0x0144000e
	ld	xbc, 0x01e40011
	call	MainFuncCall
	jr	91

; S2cGridCheck dispatch
S2c_GridCheck_Dispatch:
	lda xbc, (xsp + 10)
	ld xwa, xde
	srl xwa, 0
	ldiw_erp 0xe2, 0
	ld (xbc), wa
	lda xwa, (xbc + 2)
	ld (xwa), de
	lda xde, (xsp)
	ld (xbc + 4), xde
	cpw (xbc), 0x1
	jr nz, S2c_GridCheck_GetFocusSendEvt
	ld wa, (xwa)
	dec 2, a
	extz wa
	sla wa, 2
	lda xbc, (StrTranspose_Minus25_0x12:24)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld a, (xwa)
	extz wa
	sla wa, 2
	lda xbc, (0x03dc4e:24)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	push xde
	call Sprintf_Locked
	inc 8, xsp

S2c_GridCheck_GetFocusSendEvt:
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 10)
	ld xbc, 0x1e0008c
	call SendEvent

; S2cGridCheck event encoding dispatch
S2c_GridCheck_EventEnc:
	ld xhl, 0:i3
	lda xsp, (xsp + 18)
	ret

CmpClrYesFunc:
	ld xwa, 0x144000c
	ld xbc, 0x1e40006
	ld xde, 0:i3
	call MainFuncCall
	ld xhl, 0:i3
	ret

CmpClrNoFunc:
	ld xwa, 0x144000c
	ld xbc, 0x1e40007
	ld xde, 0:i3
	call MainFuncCall
	ld xhl, 0:i3
	ret
PsCmpCpFGrpBox_Entry:

PsCmpCpFGrpBoxProc:
	lda_dri XSP, 0xfd, 0xf0, 0xfe
	push xiz
	stl_dri XDE, 0xfd, 0x0c, 0x01
	stl_dri XWA, 0xfd, 0x10, 0x01
	cp xbc, 0x1e40004
	jr z, PsCmpCpFGrpBox_HandleEvt4
	cp xbc, 0x1c0000c
	jr z, PsCmpCpFGrpBox_HandleEvtBC
	cp xbc, 0x1c0000b
	jr z, PsCmpCpFGrpBox_HandleEvtBC
	cp xbc, 0x1c00002
	jr z, PsCmpCpFGrpBox_HandleEvt2
	cp xbc, 0x1c00001
	jr z, PsCmpCpFGrpBox_HandleEvt1
	ld XWA, (xsp + 0x0110)
	ld XDE, (xsp + 0x010c)
	call InheritedProc
	jrl PsCmpCpFGrpBox_Epilogue

PsCmpCpFGrpBox_HandleEvt1:
	ld XWA, (xsp + 0x0110)
	ld XDE, (xsp + 0x010c)
	jr PsCmpCpFGrpBox_CallInherited

PsCmpCpFGrpBox_HandleEvt2:
	ld XWA, (xsp + 0x0110)
	ld XDE, (xsp + 0x010c)

PsCmpCpFGrpBox_CallInherited:
	call InheritedProc
	jrl PsCmpCpFGrpBox_ReturnZero

PsCmpCpFGrpBox_HandleEvtBC:
	ld XWA, (xsp + 0x0110)
	ld XDE, (xsp + 0x010c)
	call InheritedProc
	ld xwa, 0x144000b
	ld xbc, 0x1e40002
	ld xde, 0:i3
	call MainFuncCall
	jrl PsCmpCpFGrpBox_ReturnZero

PsCmpCpFGrpBox_HandleEvt4:
	ld XWA, (xsp + 0x0110)
	call GetViewInstance
	ld xiz, xhl
	ld XWA, (xsp + 0x010c)
	push xwa
	lda xwa, (xsp + 16)
	push xwa
	call Sprintf_Locked
	inc 8, xsp
	lda xwa, (xiz + 22)
	lda xbc, (xiz + 32)
	cp (0x39a7:16), 0
	jr nz, PsCmpCpFGrpBox_SetColorFF
	cp (0x3a80:16), 0
	jr nz, PsCmpCpFGrpBox_SetColorFF
	ldw (xbc), 0x0
	ldw (xwa), 0xff
	jr PsCmpCpFGrpBox_SendNotify

PsCmpCpFGrpBox_SetColorFF:
	ldw (xbc), 0xff
	ldw (xwa), 0xf5

PsCmpCpFGrpBox_SendNotify:
	ld XWA, (xsp + 0x0110)
	ld xbc, 0x1c0000d
	ld xde, 0:i3
	call SendEvent
	lda xde, (xsp + 12)
	ld XWA, (xsp + 0x0110)
	ld xbc, 0x1c0000f
	call SendEvent
	lda xwa, (xsp + 4)
	ldw (xwa), 0x8
	lda xde, (xwa + 2)
	ldw (xde), 0x3c
	ld bc, (xwa)
	add bc, 0x8c
	ld (xwa + 4), bc
	ld bc, (xde)
	add bc, 0x27
	ld (xwa + 6), bc
	cp (0x39a7:16), 0
	jr nz, PsCmpCpFGrpBox_PushF5
	pushw 0xf2
	ld bc, 1:i3
	ld de, 2:i3
	jr PsCmpCpFGrpBox_DrawFrame

PsCmpCpFGrpBox_PushF5:
	pushw 0xf5
	ld bc, 1:i3
	ld de, 2:i3

PsCmpCpFGrpBox_DrawFrame:
	call DrawDesignFrame

PsCmpCpFGrpBox_ReturnZero:
	ld xhl, 0:i3

PsCmpCpFGrpBox_Epilogue:
	pop xiz
	lda_dri XSP, 0xfd, 0x10, 0x01
	ret
PsCmpCpFVariBox_Entry:

PsCmpCpFVariBoxProc:
	lda_dri XSP, 0xfd, 0xf0, 0xfe
	push xiz
	stl_dri XDE, 0xfd, 0x0c, 0x01
	stl_dri XWA, 0xfd, 0x10, 0x01
	cp xbc, 0x1e40005
	jr z, PsCmpCpFVariBox_HandleEvt5
	cp xbc, 0x1c0000c
	jr z, PsCmpCpFVariBox_HandleEvtBC
	cp xbc, 0x1c0000b
	jr z, PsCmpCpFVariBox_HandleEvtBC
	cp xbc, 0x1c00002
	jr z, PsCmpCpFVariBox_HandleEvt2
	cp xbc, 0x1c00001
	jr z, PsCmpCpFVariBox_HandleEvt1
	ld XWA, (xsp + 0x0110)
	ld XDE, (xsp + 0x010c)
	call InheritedProc
	jrl PsCmpCpFVariBox_Epilogue

PsCmpCpFVariBox_HandleEvt1:
	ld XWA, (xsp + 0x0110)
	ld XDE, (xsp + 0x010c)
	jr PsCmpCpFVariBox_CallInherited

PsCmpCpFVariBox_HandleEvt2:
	ld XWA, (xsp + 0x0110)
	ld XDE, (xsp + 0x010c)

PsCmpCpFVariBox_CallInherited:
	call InheritedProc
	jrl DesignFrame_Return

PsCmpCpFVariBox_HandleEvtBC:
	ld XWA, (xsp + 0x0110)
	ld XDE, (xsp + 0x010c)
	call InheritedProc
	ld xwa, 0x144000b
	ld xbc, 0x1e40003
	ld xde, 0:i3
	call MainFuncCall
	jrl DesignFrame_Return

PsCmpCpFVariBox_HandleEvt5:
	call GetTitleNow
	cp xhl, 0x1a000ee
	jrl z, DesignFrame_Return
	ld XWA, (xsp + 0x0110)
	call GetViewInstance
	ld xiz, xhl
	ld XWA, (xsp + 0x010c)
	push xwa
	lda xwa, (xsp + 16)
	push xwa
	call Sprintf_Locked
	inc 8, xsp
	lda xwa, (xiz + 22)
	lda xbc, (xiz + 32)
	cp (0x39a7:16), 1
	jr nz, PsCmpCpFVariBox_SetColorFF
	cp (0x3a80:16), 0
	jr nz, PsCmpCpFVariBox_SetColorFF
	ldw (xbc), 0x0
	ldw (xwa), 0xff
	jr PsCmpCpFVariBox_SendNotify

PsCmpCpFVariBox_SetColorFF:
	ldw (xbc), 0xff
	ldw (xwa), 0xf5

PsCmpCpFVariBox_SendNotify:
	ld XWA, (xsp + 0x0110)
	ld xbc, 0x1c0000d
	ld xde, 0:i3
	call SendEvent
	lda xde, (xsp + 12)
	ld XWA, (xsp + 0x0110)
	ld xbc, 0x1c0000f
	call SendEvent
	call GetTitleNow
	cp xhl, 0x1a000b8
	jr nz, DesignFrame_Return
	lda xwa, (xsp + 4)
	ldw (xwa), 0x8
	lda xde, (xwa + 2)
	ldw (xde), 0x64
	ld bc, (xwa)
	add bc, 0x8c
	ld (xwa + 4), bc
	ld bc, (xde)
	add bc, 0x27
	ld (xwa + 6), bc
	cp (0x39a7:16), 1
	jr nz, PsCmpCpFVariBox_PushF5
	pushw 0xf2
	ld bc, 1:i3
	ld de, 2:i3
	jr PsCmpCpFVariBox_DrawFrame

PsCmpCpFVariBox_PushF5:
	pushw 0xf5
	ld bc, 1:i3
	ld de, 2:i3

PsCmpCpFVariBox_DrawFrame:
	call DrawDesignFrame

DesignFrame_Return:
	ld xhl, 0:i3

PsCmpCpFVariBox_Epilogue:
	pop xiz
	lda_dri XSP, 0xfd, 0x10, 0x01
	ret
PsCmpCpFPtnBox_Entry:

PsCmpCpFPtnBoxProc:
	lda_dri XSP, 0xfd, 0xf4, 0xfe
	push xiz
	stl_dri XWA, 0xfd, 0x0c, 0x01
	cp xbc, 0x1c0000c
	jr z, PsCmpCpFPtnBox_HandleEvtBC
	cp xbc, 0x1c0000b
	jr z, PsCmpCpFPtnBox_HandleEvtBC
	cp xbc, 0x1c00002
	jr z, PsCmpCpFPtnBox_HandleEvt2
	cp xbc, 0x1c00001
	jr z, PsCmpCpFPtnBox_HandleEvt1
	ld XWA, (xsp + 0x010c)
	call InheritedProc
	jrl PsCmpCpFPtnBox_Epilogue

PsCmpCpFPtnBox_HandleEvt1:
	ld XWA, (xsp + 0x010c)
	jr PsCmpCpFPtnBox_CallInherited

PsCmpCpFPtnBox_HandleEvt2:
	ld XWA, (xsp + 0x010c)

PsCmpCpFPtnBox_CallInherited:
	call InheritedProc
	jrl PsCmpCpFPtnBox_ReturnZero

PsCmpCpFPtnBox_HandleEvtBC:
	ld XWA, (xsp + 0x010c)
	call InheritedProc
	ld XWA, (xsp + 0x010c)
	call GetViewInstance
	ld xiz, xhl
	ld a, (0x34ef:16)
	extz wa
	sla wa, 2
	lda xbc, (StrBeatOff_0x12:24)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	lda xwa, (xsp + 16)
	push xwa
	call Sprintf_Locked
	inc 8, xsp
	lda xwa, (xiz + 22)
	lda xbc, (xiz + 32)
	cp (0x39a7:16), 2
	jr nz, PsCmpCpFPtnBox_SetColorFF
	cp (0x3a80:16), 0
	jr nz, PsCmpCpFPtnBox_SetColorFF
	ldw (xbc), 0x0
	ldw (xwa), 0xff
	jr PsCmpCpFPtnBox_SendNotify

PsCmpCpFPtnBox_SetColorFF:
	ldw (xbc), 0xff
	ldw (xwa), 0xf5

PsCmpCpFPtnBox_SendNotify:
	ld XWA, (xsp + 0x010c)
	ld xbc, 0x1c0000d
	ld xde, 0:i3
	call SendEvent
	lda xde, (xsp + 12)
	ld XWA, (xsp + 0x010c)
	ld xbc, 0x1c0000f
	call SendEvent
	lda xwa, (xsp + 4)
	ldw (xwa), 0x8
	lda xde, (xwa + 2)
	ldw (xde), 0x8c
	ld bc, (xwa)
	add bc, 0x8c
	ld (xwa + 4), bc
	ld bc, (xde)
	add bc, 0x26
	ld (xwa + 6), bc
	cp (0x39a7:16), 2
	jr nz, PsCmpCpFPtnBox_PushF5
	pushw 0xf2
	ld bc, 1:i3
	ld de, 2:i3
	jr PsCmpCpFPtnBox_DrawFrame

PsCmpCpFPtnBox_PushF5:
	pushw 0xf5
	ld bc, 1:i3
	ld de, 2:i3

PsCmpCpFPtnBox_DrawFrame:
	call DrawDesignFrame

PsCmpCpFPtnBox_ReturnZero:
	ld xhl, 0:i3

PsCmpCpFPtnBox_Epilogue:
	pop xiz
	lda_dri XSP, 0xfd, 0x0c, 0x01
	ret
PsCstmCpBnkBox_Entry:

PsCstmCpBnkBoxProc:
	lda_dri XSP, 0xfd, 0x00, 0xff
	push xiz
	ld xiz, xwa
	cp xbc, 0x1c0000c
	jr z, PsCstmCpBnkBox_HandleEvtBC
	cp xbc, 0x1c0000b
	jr z, PsCstmCpBnkBox_HandleEvtBC
	cp xbc, 0x1c00002
	jr z, PsCstmCpBnkBox_HandleEvt2
	cp xbc, 0x1c00001
	jr z, PsCstmCpBnkBox_HandleEvt1
	ld xwa, xiz
	call InheritedProc
	jr PsCstmCpBnkBox_Epilogue

PsCstmCpBnkBox_HandleEvt1:
	ld xwa, xiz
	jr PsCstmCpBnkBox_CallInherited

PsCstmCpBnkBox_HandleEvt2:
	ld xwa, xiz

PsCstmCpBnkBox_CallInherited:
	call InheritedProc
	jr PsCstmCpBnkBox_ReturnZero

PsCstmCpBnkBox_HandleEvtBC:
	ld xwa, xiz
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	cp (xhl + 36), 0x0
	jr nz, PsCstmCpBnkBox_ReadParam2
	ld a, (0x39b6:16)
	jr PsCstmCpBnkBox_LookupAndSend

PsCstmCpBnkBox_ReadParam2:
	ld a, (0x39b7:16)

PsCstmCpBnkBox_LookupAndSend:
	extz wa
	sla wa, 2
	lda xbc, (PtrTbl_RhySlotLongNames:24)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	lda xwa, (xsp + 8)
	push xwa
	call Sprintf_Locked
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1c0000f
	call SendEvent

PsCstmCpBnkBox_ReturnZero:
	ld xhl, 0:i3

PsCstmCpBnkBox_Epilogue:
	pop xiz
	lda_dri XSP, 0xfd, 0x00, 0x01
	ret
PsCstmCpSwBox_Entry:

PsCstmCpSwBoxProc:
	lda_dri XSP, 0xfd, 0x00, 0xff
	push xiz
	ld xiz, xwa
	cp xbc, 0x1c0000c
	jr z, PsCstmCpSwBox_HandleEvtBC
	cp xbc, 0x1c0000b
	jr z, PsCstmCpSwBox_HandleEvtBC
	cp xbc, 0x1c00002
	jr z, PsCstmCpSwBox_HandleEvt2
	cp xbc, 0x1c00001
	jr z, PsCstmCpSwBox_HandleEvt1
	ld xwa, xiz
	call InheritedProc
	jr PsCstmCpSwBox_Epilogue

PsCstmCpSwBox_HandleEvt1:
	ld xwa, xiz
	jr PsCstmCpSwBox_CallInherited

PsCstmCpSwBox_HandleEvt2:
	ld xwa, xiz

PsCstmCpSwBox_CallInherited:
	call InheritedProc
	jr PsCstmCpSwBox_ReturnZero

PsCstmCpSwBox_HandleEvtBC:
	ld xwa, xiz
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	lda xbc, (xsp + 4)
	cp (xhl + 36), 0x0
	jr nz, PsCstmCpSwBox_ReadParam2
	ld xwa, StrRhySlot_MemoryA_0x12
	cp (0x39b6:16), 10
	jr nc, PsCstmCpSwBox_PushTableAddr0
	ld xwa, StrRhySlot_MemoryA_0xA

PsCstmCpSwBox_PushTableAddr0:
	push xwa
	push xbc
	jr PsCstmCpSwBox_SendCommand

PsCstmCpSwBox_ReadParam2:
	ld xwa, StrRhySlot_MemoryA_0x22
	cp (0x39b7:16), 10
	jr nc, PsCstmCpSwBox_PushTableAddr1
	ld xwa, StrRhySlot_MemoryA_0x1A

PsCstmCpSwBox_PushTableAddr1:
	push xwa
	push xbc

PsCstmCpSwBox_SendCommand:
	call Sprintf_Locked
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1c0000f
	call SendEvent

PsCstmCpSwBox_ReturnZero:
	ld xhl, 0:i3

PsCstmCpSwBox_Epilogue:
	pop xiz
	lda_dri XSP, 0xfd, 0x00, 0x01
	ret
PsCstmCpNameBox_Entry:

PsCstmCpNameBoxProc:
	lda_dri XSP, 0xfd, 0xfc, 0xfe
	push xiz
	stl_dri XDE, 0xfd, 0x04, 0x01
	ld xiz, xwa
	cp xbc, 0x1e4002e
	jrl z, PsCstmCpNameBox_HandleEvt2E
	cp xbc, 0x1e4002d
	jrl z, PsCstmCpNameBox_HandleEvt2D
	cp xbc, 0x1c0000d
	jr z, PsCstmCpNameBox_HandleEvtD
	cp xbc, 0x1c00002
	jr z, PsCstmCpNameBox_HandleEvt2
	cp xbc, 0x1c00001
	jr z, PsCstmCpNameBox_HandleEvt1
	ld xwa, xiz
	ld XDE, (xsp + 0x0104)
	call InheritedProc
	jrl PsCstmCpNameBox_Epilogue

PsCstmCpNameBox_HandleEvt1:
	ld xwa, xiz
	ld XDE, (xsp + 0x0104)
	jr PsCstmCpNameBox_CallInherited

PsCstmCpNameBox_HandleEvt2:
	ld xwa, xiz
	ld XDE, (xsp + 0x0104)

PsCstmCpNameBox_CallInherited:
	call InheritedProc
	jrl PsCtmAtt_ReturnZero

PsCstmCpNameBox_HandleEvtD:
	cp (0x3a7e:16), 0
	jrl nz, PsCtmAtt_ReturnZero
	ld xwa, xiz
	ld XDE, (xsp + 0x0104)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld a, (xhl + 36)
	cp a, 1:i3
	jr z, PsCstmCpNameBox_FuncCall2C
	cp a, 0:i3
	jr nz, PsCtmAtt_ReturnZero
	ld xwa, 0x144001a
	ld xbc, 0x1e4002b
	ld xde, 0:i3
	jr PsCstmCpNameBox_MainFuncCall

PsCstmCpNameBox_FuncCall2C:
	ld xwa, 0x144001a
	ld xbc, 0x1e4002c
	ld xde, 0:i3

PsCstmCpNameBox_MainFuncCall:
	call MainFuncCall
	jr PsCtmAtt_ReturnZero

PsCstmCpNameBox_HandleEvt2D:
	cp (0x3a7e:16), 0
	jr nz, PsCtmAtt_ReturnZero
	ld xwa, xiz
	call GetViewInstance
	ld XWA, (xsp + 0x0104)
	push xwa
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1c0000f
	jr PsCstmCpNameBox_SendEventJoin

PsCstmCpNameBox_HandleEvt2E:
	cp (0x3a7e:16), 0
	jr nz, PsCtmAtt_ReturnZero
	ld xwa, xiz
	call GetViewInstance
	ld XWA, (xsp + 0x0104)
	push xwa
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1c0000f

PsCstmCpNameBox_SendEventJoin:
	call SendEvent

PsCtmAtt_ReturnZero:
	ld xhl, 0:i3

PsCstmCpNameBox_Epilogue:
	pop xiz
	lda_dri XSP, 0xfd, 0x04, 0x01
	ret
PsCtmAttStrBox_Entry:

PsCtmAttStrBoxProc:
	lda_dri XSP, 0xfd, 0x00, 0xff
	push xiz
	ld xiz, xwa
	cp xbc, 0x1c0000c
	jr z, PsCtmAttStrBox_HandleEvtBC
	cp xbc, 0x1c0000b
	jr z, PsCtmAttStrBox_HandleEvtBC
	cp xbc, 0x1c00002
	jr z, PsCtmAttStrBox_HandleEvt2
	cp xbc, 0x1c00001
	jr z, PsCtmAttStrBox_HandleEvt1
	ld xwa, xiz
	call InheritedProc
	jr PsCtmAttStrBox_Epilogue

PsCtmAttStrBox_HandleEvt1:
	ld xwa, xiz
	jr PsCtmAttStrBox_CallInherited

PsCtmAttStrBox_HandleEvt2:
	ld xwa, xiz

PsCtmAttStrBox_CallInherited:
	call InheritedProc
	jr PsCtmAttStrBox_ReturnZero

PsCtmAttStrBox_HandleEvtBC:
	ld xwa, xiz
	call InheritedProc
	pushw 0x0
	pushw 0x3a4f
	lda xwa, (xsp + 8)
	push xwa
	call Sprintf_Locked
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1c0000f
	call SendEvent

PsCtmAttStrBox_ReturnZero:
	ld xhl, 0:i3

PsCtmAttStrBox_Epilogue:
	pop xiz
	lda_dri XSP, 0xfd, 0x00, 0x01
	ret
AcMemNoBox_Entry:

AcMemNoBoxProc:
	lda_dri XSP, 0xfd, 0xf4, 0xfe
	push xiz
	stl_dri XWA, 0xfd, 0x0c, 0x01
	cp xbc, 0x1c0000c
	jr z, AcMemNoBox_HandleEvtBC
	cp xbc, 0x1c0000b
	jr z, AcMemNoBox_HandleEvtBC
	cp xbc, 0x1c00002
	jr z, AcMemNoBox_HandleEvt2
	cp xbc, 0x1c00001
	jr z, AcMemNoBox_HandleEvt1
	ld XWA, (xsp + 0x010c)
	call InheritedProc
	jrl AcMemNoBox_Epilogue

AcMemNoBox_HandleEvt1:
	ld XWA, (xsp + 0x010c)
	jr AcMemNoBox_CallInherited

AcMemNoBox_HandleEvt2:
	ld XWA, (xsp + 0x010c)

AcMemNoBox_CallInherited:
	call InheritedProc
	jrl AcMemNoBox_ReturnZero

AcMemNoBox_HandleEvtBC:
	ld XWA, (xsp + 0x010c)
	call InheritedProc
	ld XWA, (xsp + 0x010c)
	call GetViewInstance
	ld xiz, xhl
	ld a, (0x34d6:16)
	extz wa
	sla wa, 2
	lda xbc, (StrRhySlot_MemoryA_0x2A:24)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	lda xwa, (xsp + 16)
	push xwa
	call Sprintf_Locked
	inc 8, xsp
	lda xwa, (xiz + 22)
	lda xbc, (xiz + 32)
	cp (0x39a8:16), 1
	jr nz, AcMemNoBox_SetColorFF
	cp (0x3a80:16), 1
	jr nz, AcMemNoBox_SetColorFF
	ldw (xbc), 0x0
	ldw (xwa), 0xff
	jr AcMemNoBox_SendNotify

AcMemNoBox_SetColorFF:
	ldw (xbc), 0xff
	ldw (xwa), 0xf5

AcMemNoBox_SendNotify:
	ld XWA, (xsp + 0x010c)
	ld xbc, 0x1c0000d
	ld xde, 0:i3
	call SendEvent
	lda xde, (xsp + 12)
	ld XWA, (xsp + 0x010c)
	ld xbc, 0x1c0000f
	call SendEvent
	call GetTitleNow
	cp xhl, 0x1a000b8
	jr nz, AcMemNoBox_ReturnZero
	lda xwa, (xsp + 4)
	ldw (xwa), 0xc5
	lda xde, (xwa + 2)
	ldw (xde), 0x64
	ld bc, (xwa)
	add bc, 0x58
	ld (xwa + 4), bc
	ld bc, (xde)
	add bc, 0x2e
	ld (xwa + 6), bc
	cp (0x39a8:16), 1
	jr nz, AcMemNoBox_PushF5
	pushw 0xf2
	ld bc, 1:i3
	ld de, 2:i3
	jr AcMemNoBox_DrawFrame

AcMemNoBox_PushF5:
	pushw 0xf5
	ld bc, 1:i3
	ld de, 2:i3

AcMemNoBox_DrawFrame:
	call DrawDesignFrame

AcMemNoBox_ReturnZero:
	ld xhl, 0:i3

AcMemNoBox_Epilogue:
	pop xiz
	lda_dri XSP, 0xfd, 0x0c, 0x01
	ret
AcCmpRecBox_Entry:

AcCmpRecBoxProc:
	lda_dri XSP, 0xfd, 0xe8, 0xfe
	push xiz
	stl_dri XDE, 0xfd, 0x10, 0x01
	stl_dri XBC, 0xfd, 0x14, 0x01
	stl_dri XWA, 0xfd, 0x18, 0x01
	ld XWA, (xsp + 0x0114)
	cp xwa, 0x1c0000c
	jr z, AcCmpRecBox_HandleEvtBC
	cp xwa, 0x1c0000b
	jr z, AcCmpRecBox_HandleEvtBC
	cp xwa, 0x1c00002
	jr z, AcCmpRecBox_HandleEvt2
	cp xwa, 0x1c00001
	jr z, AcCmpRecBox_HandleEvt1
	ld XWA, (xsp + 0x0118)
	ld XBC, (xsp + 0x0114)
	ld XDE, (xsp + 0x0110)
	call InheritedProc
	jrl AcCmpRecBox_Epilogue

AcCmpRecBox_HandleEvt1:
	ld XWA, (xsp + 0x0118)
	ld XBC, (xsp + 0x0114)
	ld XDE, (xsp + 0x0110)
	jr AcCmpRecBox_CallInherited

AcCmpRecBox_HandleEvt2:
	ld XWA, (xsp + 0x0118)
	ld XBC, (xsp + 0x0114)
	ld XDE, (xsp + 0x0110)

AcCmpRecBox_CallInherited:
	call InheritedProc
	jrl AcCmpRecBox_ReturnZero

AcCmpRecBox_HandleEvtBC:
	ld XWA, (xsp + 0x0118)
	call GetViewInstance
	ld xiz, xhl
	ld (xsp + 4), xiz
	ld XWA, (xsp + 0x0118)
	call GetViewInstance
	ld (xsp + 12), xhl
	ld xwa, (xsp + 12)
	ld (xsp + 8), xwa
	ld e, (xiz + 36)
	ld a, (0x379b:16)
	and a, e
	lda xhl, (StrStyleSect2_A_Vari1_0x8:24)
	lda xbc, (xsp + 16)
	cp a, e
	jr nz, AcCmpRecBox_CheckParam2
	ld xwa, (xhl + 4)
	push xwa
	push xbc
	call Sprintf_Locked
	inc 8, xsp
	ld xwa, (xsp + 12)
	ldw (xwa + 22), 0xf2
	jr AcCmpRecBox_InheritAndSend

AcCmpRecBox_CheckParam2:
	ld xwa, (xsp + 4)
	ld e, (xwa + 37)
	ld a, (0x34f1:16)
	and a, e
	cp a, e
	jr nz, AcCmpRecBox_AdjustTable
	inc 8, xhl

AcCmpRecBox_AdjustTable:
	ld xwa, (xhl)
	push xwa
	push xbc
	call Sprintf_Locked
	inc 8, xsp
	ld xwa, (xsp + 8)
	ldw (xwa + 22), 0xf5

AcCmpRecBox_InheritAndSend:
	ld XWA, (xsp + 0x0118)
	ld XBC, (xsp + 0x0114)
	ld XDE, (xsp + 0x0110)
	call InheritedProc
	lda xde, (xsp + 16)
	ld XWA, (xsp + 0x0118)
	ld xbc, 0x1c0000f
	call SendEvent

AcCmpRecBox_ReturnZero:
	ld xhl, 0:i3

AcCmpRecBox_Epilogue:
	pop xiz
	lda_dri XSP, 0xfd, 0x18, 0x01
	ret
PsCmpQtzBox_Entry:

PsCmpQtzBoxProc:
	lda_dri XSP, 0xfd, 0x00, 0xff
	push xiz
	ld xiz, xwa
	cp xbc, 0x1c0000c
	jr z, PsCmpQtzBox_HandleEvtBC
	cp xbc, 0x1c0000b
	jr z, PsCmpQtzBox_HandleEvtBC
	cp xbc, 0x1c00002
	jr z, PsCmpQtzBox_HandleEvt2
	cp xbc, 0x1c00001
	jr z, PsCmpQtzBox_HandleEvt1
	ld xwa, xiz
	call InheritedProc
	jr PsCmpQtzBox_Epilogue

PsCmpQtzBox_HandleEvt1:
	ld xwa, xiz
	jr PsCmpQtzBox_CallInherited

PsCmpQtzBox_HandleEvt2:
	ld xwa, xiz

PsCmpQtzBox_CallInherited:
	call InheritedProc
	jr PsCmpQtzBox_ReturnZero

PsCmpQtzBox_HandleEvtBC:
	ld xwa, xiz
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld a, (0x34db:16)
	extz wa
	sla wa, 2
	lda xbc, (PtrTbl_NotePositionStrs:24)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	lda xwa, (xsp + 8)
	push xwa
	call Sprintf_Locked
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1c0000f
	call SendEvent

PsCmpQtzBox_ReturnZero:
	ld xhl, 0:i3

PsCmpQtzBox_Epilogue:
	pop xiz
	lda_dri XSP, 0xfd, 0x00, 0x01
	ret
PsCmpMeasBox_Entry:

PsCmpMeasBoxProc:
	lda_dri XSP, 0xfd, 0xf8, 0xfe
	push xiz
	stl_dri XDE, 0xfd, 0x04, 0x01
	ld xiz, xbc
	stl_dri XWA, 0xfd, 0x08, 0x01
	cp xiz, 0x1c0000c
	jr z, PsCmpMeasBox_HandleEvtBC
	cp xiz, 0x1c0000b
	jr z, PsCmpMeasBox_HandleEvtBC
	cp xiz, 0x1c00002
	jr z, PsCmpMeasBox_HandleEvt2
	cp xiz, 0x1c00001
	jr z, PsCmpMeasBox_HandleEvt1
	ld XWA, (xsp + 0x0108)
	ld xbc, xiz
	ld XDE, (xsp + 0x0104)
	call InheritedProc
	jr PsCmpMeasBox_Epilogue

PsCmpMeasBox_HandleEvt1:
	ld XWA, (xsp + 0x0108)
	ld xbc, xiz
	ld XDE, (xsp + 0x0104)
	jr PsCmpMeasBox_CallInherited

PsCmpMeasBox_HandleEvt2:
	ld XWA, (xsp + 0x0108)
	ld xbc, xiz
	ld XDE, (xsp + 0x0104)

PsCmpMeasBox_CallInherited:
	call InheritedProc
	jr PsCmpMeasBox_ReturnZero

PsCmpMeasBox_HandleEvtBC:
	call GetTitleNow
	cp xhl, 0x1a000b5
	jr nz, PsCmpMeasBox_ReturnZero
	ld XWA, (xsp + 0x0108)
	ld xbc, xiz
	ld XDE, (xsp + 0x0104)
	call InheritedProc
	ld XWA, (xsp + 0x0108)
	call GetViewInstance
	ld a, (0x34dc:16)
	inc 1, a
	extz wa
	pushw wa
	pushw 0xe1
	pushw 0xdd7a
	lda xwa, (xsp + 10)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	lda xde, (xsp + 4)
	ld XWA, (xsp + 0x0108)
	ld xbc, 0x1c0000f
	call SendEvent

PsCmpMeasBox_ReturnZero:
	ld xhl, 0:i3

PsCmpMeasBox_Epilogue:
	pop xiz
	lda_dri XSP, 0xfd, 0x08, 0x01
	ret
PsCmpMemBox_Entry:

PsCmpMemBoxProc:
	lda_dri XSP, 0xfd, 0xf8, 0xfe
	push xiz
	stl_dri XDE, 0xfd, 0x04, 0x01
	ld xiz, xbc
	stl_dri XWA, 0xfd, 0x08, 0x01
	cp xiz, 0x1c0000c
	jr z, PsCmpMemBox_HandleEvtBC
	cp xiz, 0x1c0000b
	jr z, PsCmpMemBox_HandleEvtBC
	cp xiz, 0x1c00002
	jr z, PsCmpMemBox_HandleEvt2
	cp xiz, 0x1c00001
	jr z, PsCmpMemBox_HandleEvt1
	ld XWA, (xsp + 0x0108)
	ld xbc, xiz
	ld XDE, (xsp + 0x0104)
	call InheritedProc
	jr PsCmpMemBox_Epilogue

PsCmpMemBox_HandleEvt1:
	ld XWA, (xsp + 0x0108)
	ld xbc, xiz
	ld XDE, (xsp + 0x0104)
	jr PsCmpMemBox_CallInherited

PsCmpMemBox_HandleEvt2:
	ld XWA, (xsp + 0x0108)
	ld xbc, xiz
	ld XDE, (xsp + 0x0104)

PsCmpMemBox_CallInherited:
	call InheritedProc
	jr PsCmpMemBox_ReturnZero

PsCmpMemBox_HandleEvtBC:
	call GetTitleNow
	cp xhl, 0x1a000b5
	jr nz, PsCmpMemBox_ReturnZero
	ld XWA, (xsp + 0x0108)
	ld xbc, xiz
	ld XDE, (xsp + 0x0104)
	call InheritedProc
	ld XWA, (xsp + 0x0108)
	call GetViewInstance
	ld a, (0x39ab:16)
	extz wa
	pushw wa
	pushw 0xe1
	pushw 0xdd7e
	lda xwa, (xsp + 10)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	lda xde, (xsp + 4)
	ld XWA, (xsp + 0x0108)
	ld xbc, 0x1c0000f
	call SendEvent

PsCmpMemBox_ReturnZero:
	ld xhl, 0:i3

PsCmpMemBox_Epilogue:
	pop xiz
	lda_dri XSP, 0xfd, 0x08, 0x01
	ret
AcCmpTempoBox_Entry:

AcCmpTempoBoxProc:
	lda_dri XSP, 0xfd, 0xfc, 0xfe
	push xiz
	ld xiz, xde
	stl_dri XWA, 0xfd, 0x04, 0x01
	cp xbc, 0x1c0001c
	jr z, AcCmpTempoBox_HandleEvt1C
	cp xbc, 0x1c0000c
	jr z, AcCmpTempoBox_HandleEvtBC
	cp xbc, 0x1c0000b
	jr z, AcCmpTempoBox_HandleEvtBC
	cp xbc, 0x1c00002
	jr z, AcCmpTempoBox_HandleEvt2
	cp xbc, 0x1c00001
	jr z, AcCmpTempoBox_HandleEvt1
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	jr AcCmpTempoBox_Epilogue

AcCmpTempoBox_HandleEvt1:
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld XWA, (xsp + 0x0104)
	ld xbc, 4:i3
	call SetLswFilter
	jr CmpFunc_Return

AcCmpTempoBox_HandleEvt2:
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld XWA, (xsp + 0x0104)
	ld xbc, 4:i3
	call ResetLswFilter
	jr CmpFunc_Return

AcCmpTempoBox_HandleEvtBC:
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld xwa, 4:i3
	call MainLswGet
	jr CmpFunc_Return

AcCmpTempoBox_HandleEvt1C:
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld xwa, (xiz)
	cp xwa, 0x4
	jr nz, CmpFunc_Return
	pushm (xiz + 4)
	pushw 0xe1
	pushw 0xdd82
	lda xwa, (xsp + 10)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	lda xde, (xsp + 4)
	ld XWA, (xsp + 0x0104)
	ld xbc, 0x1c0000f
	call SendEvent

CmpFunc_Return:
	ld xhl, 0:i3

AcCmpTempoBox_Epilogue:
	pop xiz
	lda_dri XSP, 0xfd, 0x04, 0x01
	ret

CmpNamingCheck:
	push xiz
	ld xiz, xwa
	cp xbc, 0x1e0007c
	jr z, CmpNamingCheck_Return0xD
	cp xbc, 0x1e00084
	jr z, CmpNamingCheck_ReturnZero
	cp xbc, 0x1e0003a
	jr nz, CmpNamingCheck_ReturnZero
	pushw 0x0
	pushw 0x34bc
	push xde
	call Strcpy
	pushw 0xd
	pushw 0x0
	pushw 0x34bc
	pushw 0x2
	pushw 0xc54
	call Strncpy
	lda xsp, (xsp + 18)
	ld (0x020c61:24), 0x00
	ld xhl, xiz
	jr CmpNamingCheck_Epilogue

CmpNamingCheck_ReturnZero:
	ld xhl, 0:i3
	jr CmpNamingCheck_Epilogue

CmpNamingCheck_Return0xD:
	ld xhl, 0xd

CmpNamingCheck_Epilogue:
	pop xiz
	ret

CmpNameOkFunc:
	cp xbc, 0x1c00007
	jr nz, CmpNameOkFunc_ReturnZero
	call GetNamingWindowID
	ld xwa, xhl
	ld xbc, 0x1e0003a
	ld xde, 0x20c62
	call SendEvent
	ld xwa, 0x144000a
	ld xbc, 0x1e40000
	ld xde, 0x20c62
	call MainFuncCall

CmpNameOkFunc_ReturnZero:
	ld xhl, 0:i3
	ret
PsNameMemBox_Entry:

PsNameMemBoxProc:
	lda_dri XSP, 0xfd, 0xf4, 0xfe
	push xiz
	stl_dri XWA, 0xfd, 0x0c, 0x01
	cp xbc, 0x1c0000c
	jr z, PsNameMemBox_HandleEvtBC
	cp xbc, 0x1c0000b
	jr z, PsNameMemBox_HandleEvtBC
	cp xbc, 0x1c00002
	jr z, PsNameMemBox_HandleEvt2
	cp xbc, 0x1c00001
	jr z, PsNameMemBox_HandleEvt1
	ld XWA, (xsp + 0x010c)
	call InheritedProc
	jrl EasyCmp_TtlCase3

PsNameMemBox_HandleEvt1:
	ld XWA, (xsp + 0x010c)
	jr PsNameMemBox_CallInherited

PsNameMemBox_HandleEvt2:
	ld XWA, (xsp + 0x010c)

PsNameMemBox_CallInherited:
	call InheritedProc
	jrl EasyCmp_TtlCase2

PsNameMemBox_HandleEvtBC:
	ld XWA, (xsp + 0x010c)
	call InheritedProc
	ld XWA, (xsp + 0x010c)
	call GetViewInstance
	ld xiz, xhl
	ld a, (0x34d6:16)
	extz wa
	sla wa, 2
	lda xbc, (PtrTbl_StyleVarGroupCodes:24)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	lda xwa, (xsp + 8)
	push xwa
	call Sprintf_Locked
	inc 8, xsp
	lda xwa, (xiz + 22)
	lda xbc, (xiz + 32)
	cp (0x39a8:16), 0
	jr nz, PsNameMemBox_SetColorFF
	cp (0x3a80:16), 1
	jr nz, PsNameMemBox_SetColorFF
	ldw (xbc), 0x0
	ldw (xwa), 0xff
	jr PsNameMemBox_SendNotify

PsNameMemBox_SetColorFF:
	ldw (xbc), 0xff
	ldw (xwa), 0xf5

PsNameMemBox_SendNotify:
	ld XWA, (xsp + 0x010c)
	ld xbc, 0x1c0000d
	ld xde, 0:i3
	call SendEvent
	lda xde, (xsp + 4)
	ld XWA, (xsp + 0x010c)
	ld xbc, 0x1c0000f
	call SendEvent
	call GetTitleNow
	cp xhl, 0x1a000b8
	jr nz, EasyCmp_TtlCase2
	lda_dri XWA, 0xfd, 0x04, 0x01
	ldw (xwa), 0xc5
	lda xde, (xwa + 2)
	ldw (xde), 0x3c
	ld bc, (xwa)
	add bc, 0x58
	ld (xwa + 4), bc
	ld bc, (xde)
	add bc, 0x26
	ld (xwa + 6), bc
	cp (0x39a8:16), 0
	jr nz, EasyCmp_TtlDispatch
	pushw 0xf2
	ld bc, 1:i3
	ld de, 2:i3
	jr EasyCmp_TtlCase1

; EasyCmp title dispatch
EasyCmp_TtlDispatch:
	pushw 0xf5
	ld bc, 1:i3
	ld de, 2:i3

; EasyCmp title case 1
EasyCmp_TtlCase1:
	call DrawDesignFrame

; EasyCmp title case 2
EasyCmp_TtlCase2:
	ld xhl, 0:i3

; EasyCmp title case 3
EasyCmp_TtlCase3:
	pop xiz
	lda_dri XSP, 0xfd, 0x0c, 0x01
	ret
; EasyCmp title default
EasyCmp_TtlDefault:
AcEasyCmpGridBoxProc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 12), xde
	ld (xsp + 16), xbc
	ld xiz, xwa
	ld xbc, (xsp + 16)
	cp xbc, 0x1e0008d
	jrl z, EasyCmp_GridCheck_Case3
	ld xwa, (xsp + 16)
	cp xwa, 0x1e0008b
	jrl z, EasyCmp_GridCheck_Case1
	cp xwa, 0x1e0008a
	jrl z, EasyCmp_GridCheck
	cp xwa, 0x1c00001
	jr z, EasyCmp_DialGrid
	sub xbc, 0x1c00017
	cp xbc, 0x0
	jrl lt, EasyCmp_GridCheck_Case4
	cp xbc, 0x6
	jrl gt, EasyCmp_GridCheck_Case4
	add xbc, xbc
	add xbc, StyleVarGrp_AEnd2b_0x2
	ld bc, (xbc)
	lda xix, (EasyCmp_DialGrid:24)
	jp_ind 8, 0x07, 0xf0, 0xe4

; EasyCmp dial grid dispatch (7-entry, table 0xe1de4c)
EasyCmp_DialGrid:
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
	jrl EasyCmp_SetDialEnable
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, EasyCmp_SendEvt091
	ld xwa, xiz
	ld xbc, 0x1e0008f
	ld xde, 0:i3
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
	jrl EasyCmp_ReturnZeroJmp

EasyCmp_SendEvt091:
	ld xwa, xiz
	ld xbc, 0x1e00091
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jrl z, EasyCmp_ReturnZeroJmp
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
	jrl EasyCmp_SetDialEnable
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, EasyCmp_IncSendEvt091
	ld xwa, xiz
	ld xbc, 0x1e0008f
	ld xde, 0:i3
	call SendEvent
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
	jrl EasyCmp_ReturnZeroJmp

EasyCmp_IncSendEvt091:
	ld xwa, xiz
	ld xbc, 0x1e00091
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, EasyCmp_ReturnZeroJmp
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

EasyCmp_SetDialEnable:
	call SetDialEnable
	jr EasyCmp_ReturnZeroJmp

; EasyCmpGridCheck dispatch
EasyCmp_GridCheck:
	ld xwa, xiz
	ld xiz, 0x3e
	jr EasyCmp_GridCheck_Case2

; EasyCmpGridCheck case 1
EasyCmp_GridCheck_Case1:
	ld xwa, xiz
	ld xiz, 0x42

; EasyCmpGridCheck case 2
EasyCmp_GridCheck_Case2:
	call GetViewInstance
	add xhl, xiz
	ld xwa, (xhl)
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	jr EasyCmp_ReturnZeroJmp

; EasyCmpGridCheck case 3
EasyCmp_GridCheck_Case3:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call ApFuncCall

EasyCmp_ReturnZeroJmp:
	ld xhl, 0:i3
	jr EasyCmp_GridCheck_Case5

; EasyCmpGridCheck case 4
EasyCmp_GridCheck_Case4:
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc

; EasyCmpGridCheck case 5
EasyCmp_GridCheck_Case5:
	pop xiz
	lda xsp, (xsp + 16)
	ret

EasyCmpGridCheck:
	lda xsp, (xsp - 28)
	ld xwa, xbc
	cp xbc, 0x1e0008d
	jrl z, EasyCmp_GridCheck_EventEnc
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, EasyCmp_GridCheck_EventCase4
	cp xwa, 0x6
	jrl gt, EasyCmp_GridCheck_EventCase4
	add xwa, xwa
	add xwa, StrGenre_8Beat_0x1A
	ld wa, (xwa)
	lda xix, (EasyCmp_GridCheck_DataBlock:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

EasyCmp_GridCheck_DataBlock:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 0x01e0008f
	ld	xde, 0:i3
	call	SendEvent
	ld	xde, xhl
	lda	xwa, (xsp+20)
	ld	xbc, xde
	srl	xbc, 0
	ld	qbc, 0
	ld	(xwa), bc
	ld	(xwa+2), de
	ld	wa, (xwa)
	exts	xde
	cp	wa, 2:i3
	jr	z, 17
	cp	wa, 1:i3
	jrl	nz, 232
	ld	xwa, 0x01440018
	ld	xbc, 0x01e40027
	jr	82
	ld	xwa, 0x01440018
	ld	xbc, 0x01e40029
	jr	70
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 0x01e0008f
	ld	xde, 0:i3
	call	SendEvent
	ld	xde, xhl
	lda	xwa, (xsp+20)
	ld	xbc, xde
	srl	xbc, 0
	ld	qbc, 0
	ld	(xwa), bc
	ld	(xwa+2), de
	ld	wa, (xwa)
	exts	xde
	cp	wa, 2:i3
	jr	z, 17
	cp	wa, 1:i3
	jrl	nz, 160
	ld	xwa, 0x01440018
	ld	xbc, 0x01e40028
	jr	10
	ld	xwa, 0x01440018
	ld	xbc, 0x01e4002a
	call	MainFuncCall
	jrl	131

; EasyCmpGridCheck event encoding dispatch
EasyCmp_GridCheck_EventEnc:
	lda xbc, (xsp + 20)
	ld xwa, xde
	srl xwa, 0
	ldiw_erp 0xe2, 0
	ld (xbc), wa
	lda xwa, (xbc + 2)
	ld (xwa), de
	lda xde, (xsp)
	ld (xbc + 4), xde
	ld bc, (xbc)
	ld wa, (xwa)
	dec 2, a
	extz wa
	cp bc, 2:i3
	jr z, EasyCmp_GridEvtEnc_Case2
	cp bc, 1:i3
	jr nz, EasyCmp_GridCheck_EventCase3
	lda xbc, (0x37ab:16)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	extz wa
	sla wa, 2
	lda xbc, (0x03dc92:24)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	jr EasyCmp_GridCheck_EventCase1

EasyCmp_GridEvtEnc_Case2:
	lda xbc, (0x37b2:16)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, 0:i3
	jr nz, EasyCmp_GridCheck_EventCase2
	ld xwa, StrGenre_8Beat_0x12
	push xwa

; EasyCmpGridCheck event case 1
EasyCmp_GridCheck_EventCase1:
	push xde
	call Sprintf_Locked
	inc 8, xsp
	jr EasyCmp_GridCheck_EventCase3

; EasyCmpGridCheck event case 2
EasyCmp_GridCheck_EventCase2:
	extz wa
	pushw wa
	pushw 0xe1
	pushw 0xdf12
	push xde
	call Sprintf_Locked
	lda xsp, (xsp + 10)

; EasyCmpGridCheck event case 3
EasyCmp_GridCheck_EventCase3:
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 20)
	ld xbc, 0x1e0008c
	call SendEvent

; EasyCmpGridCheck event case 4
EasyCmp_GridCheck_EventCase4:
	ld xhl, 0:i3
	lda xsp, (xsp + 28)
	ret

MspNameBnkFunc:
	lda xsp, (xsp - 16)
	push xiz
	ld xhl, xbc
	ld xiz, xwa
	ld xiy, StrGenre_8Beat_0x28
	lda xix, (xsp + 4)
	ldw bc, 0x8
	ldirw
	ld xwa, xhl
	cp xhl, 0x1e00082
	jr z, MspNameBnk_Dispatch
	sub xwa, 0x1e0003e
	cp xwa, 0x0
	jrl lt, MspNaming_CleanupExit
	cp xwa, 0x9
	jr gt, MspNaming_CleanupExit
	add xwa, xwa
	add xwa, StrBankShort_User1_0xA
	ld wa, (xwa)
	lda xix, (EasyCmp_GridEvtCase_Default:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

EasyCmp_GridEvtCase_Default:
	ld	xwa, (xde+14)
	sll	xwa, 2
	lda	xbc, (xsp+4)
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xde+18)
	push	xwa
	call	Strcpy
	inc	8, xsp
	ld	xhl, xiz
	jr	79
	ld	xhl, 1:i3
	jr	75
	ld	xhl, 3:i3
	jr	71
	lda	xhl, (0x7f3e:16)
	jr	t, 0x41

; MspNameBnkFunc dispatch (10-entry, table 0xe1df5c)
MspNameBnk_Dispatch:
	cp xde, 0x4
	jr nc, MspNaming_CleanupExit
	ld xwa, xde
	sll xwa, 4
	cp xde, 0x2
	jr nc, EasyCmp_GridEvtCase_Scroll
	add xwa, 0x1e8a80
	jr EasyCmp_GridEvtCase_Epilogue

EasyCmp_GridEvtCase_Scroll:
	sub xwa, 0x20
	add xwa, 0x1e8a40

EasyCmp_GridEvtCase_Epilogue:
	pushw 0x10
	push xwa
	pushw 0x0
	pushw 0x34bc
	call Strncpy
	lda xsp, (xsp + 10)
	ld (0x34cc:16), 0

MspNaming_CleanupExit:
	ld xhl, 0:i3
	pop xiz
	lda xsp, (xsp + 16)
	ret

MspNamingCheck:
	push xiz
	ld xiz, xwa
	cp xbc, 0x1e0007c
	jr z, MspNamingCheck_ReturnHex10
	cp xbc, 0x1e00084
	jr z, MspNamingCheck_ReturnZero
	cp xbc, 0x1e0003a
	jr nz, MspNamingCheck_ReturnZero
	pushw 0x0
	pushw 0x34bc
	push xde
	call Strcpy
	pushw 0x10
	pushw 0x0
	pushw 0x34bc
	pushw 0x2
	pushw 0xc70
	call Strncpy
	lda xsp, (xsp + 18)
	ld xhl, xiz
	jr MspNamingCheck_Epilogue

MspNamingCheck_ReturnZero:
	ld xhl, 0:i3
	jr MspNamingCheck_Epilogue

MspNamingCheck_ReturnHex10:
	ld xhl, 0x10

MspNamingCheck_Epilogue:
	pop xiz
	ret

MspNameOkFunc:
	cp xbc, 0x1c00007
	jr nz, MspNameOkFunc_ReturnZero
	call GetNamingWindowID
	ld xwa, xhl
	ld xbc, 0x1e0003a
	ld xde, 0x20c82
	call SendEvent
	ld xwa, 0x144000a
	ld xbc, 0x1e40001
	ld xde, 0x20c82
	call MainFuncCall

MspNameOkFunc_ReturnZero:
	ld xhl, 0:i3
	ret
MspNameOkFunc_End:

PsMspNameBnkProc:
	lda_dri XSP, 0xfd, 0x00, 0xff
	push xiz
	ld xiz, xwa
	cp xbc, 0x1c0000c
	jr z, PsMspNameBnk_HandleEvtBC
	cp xbc, 0x1c0000b
	jr z, PsMspNameBnk_HandleEvtBC
	cp xbc, 0x1c00002
	jr z, PsMspNameBnk_HandleEvt2
	cp xbc, 0x1c00001
	jr z, PsMspNameBnk_HandleEvt1
	ld xwa, xiz
	call InheritedProc
	jr PsMspNameBnk_Epilogue

PsMspNameBnk_HandleEvt1:
	ld xwa, xiz
	jr PsMspNameBnk_CallInherited

PsMspNameBnk_HandleEvt2:
	ld xwa, xiz

PsMspNameBnk_CallInherited:
	call InheritedProc
	jr PsMspNameBnk_SetReturnZero

PsMspNameBnk_HandleEvtBC:
	ld xwa, xiz
	call InheritedProc
	ld a, (0x7f3e:16)
	extz wa
	sla wa, 2
	lda xbc, (PtrTbl_MspCompileBankLabels:24)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	lda xwa, (xsp + 8)
	push xwa
	call Sprintf_Locked
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1c0000f
	call SendEvent

PsMspNameBnk_SetReturnZero:
	ld xhl, 0:i3

PsMspNameBnk_Epilogue:
	pop xiz
	lda_dri XSP, 0xfd, 0x00, 0x01
	ret
PsMspNameBnk_End:

VwVariBoxProc:
	lda_dri XSP, 0xfd, 0xe8, 0xfe
	push xiz
	stl_dri XDE, 0xfd, 0x14, 0x01
	ld xiz, xbc
	stl_dri XWA, 0xfd, 0x18, 0x01
	cp xiz, 0x1e0003c
	jrl z, VwVariBox_CanScroll
	cp xiz, 0x1c0001b
	jrl z, VwVariBox_Release
	cp xiz, 0x1c00007
	jrl z, VwVariBox_OK
	cp xiz, 0x1e0003a
	jrl z, VwVariBox_GetText
	cp xiz, 0x1c0000f
	jrl z, VwVariBox_Confirm
	cp xiz, 0x1c0000d
	jrl z, VwVariBox_Paint
	cp xiz, 0x1c0001c
	jrl z, VwVariBox_Match
	cp xiz, 0x1c00001
	jr z, VwVariBox_Init
	cp xiz, 0x1e0004d
	jrl nz, VwVariBox_Default
	ld XWA, (xsp + 0x0118)
	call GetViewInstance
	lda xwa, (xhl + 38)
	ld xbc, (xwa)
	ld bc, (xbc)
	exts xbc
	cpl_sri_rm XBC, 0xfd, 0x14, 0x01
	jrl z, VwVariBox_ReturnHandled
	ld xbc, (xwa)
	ld XWA, (xsp + 0x0114)
	ld (xbc), wa
	ld XWA, (xsp + 0x0118)
	ld xbc, 0x1c0000d
	ld xde, 0:i3
	jrl VwVariBox_DispatchAndReturn

VwVariBox_Init:
	ld xwa, 0x28800
	call SndParam_LookupReadOnly
	ld (xsp + 6), hl
	ld XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld XDE, (xsp + 0x0114)
	call InheritedProc
	ld XWA, (xsp + 0x0118)
	call GetViewInstance
	ld a, (xhl + 42)
	extz wa
	lda xbc, (xhl + 38)
	cp wa, (xsp + 6)
	scc16 z, wa
	ld xbc, (xbc)
	ld (xbc), wa
	ld XWA, (xsp + 0x0118)
	ld xbc, 0x1c0000d
	ld xde, 0:i3
	jrl VwVariBox_DispatchAndReturn

VwVariBox_Match:
	ld XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld XDE, (xsp + 0x0114)
	call InheritedProc
	ld XWA, (xsp + 0x0118)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, 0x28800
	call SndParam_LookupReadOnly
	ld (xsp + 6), hl
	ld XWA, (xsp + 0x0114)
	ld xwa, (xwa)
	cp xwa, 0x28800
	jrl nz, VwVariBox_ReturnHandled
	ld c, (xiz + 42)
	extz bc
	ld xwa, (xiz + 38)
	cp bc, (xsp + 6)
	jr nz, VwVariBox_Match_ValueMismatch
	ldw (xwa), 0x1
	jr VwVariBox_Match_Repaint

VwVariBox_Match_ValueMismatch:
	ldw (xwa), 0x0
	cpw (xsp + 6), 0xa
	jr ge, VwVariBox_Match_HighIndex
	ld xwa, 0xc80001
	ld xbc, 0x1e00056
	ld xde, 0:i3
	call SendEvent
	cp xhl, 0x1
	jr z, VwVariBox_Match_Repaint
	ld xwa, 0xc80001
	ld xbc, 0x1e0007f
	ld xde, 1:i3
	call SendEvent
	ld xwa, 0xc80001
	ld xbc, 0x1c0000f
	ld xde, 1:i3
	jr VwVariBox_Match_DispatchConfirm

VwVariBox_Match_HighIndex:
	ld xwa, 0xc80001
	ld xbc, 0x1e00056
	ld xde, 0:i3
	call SendEvent
	cp xhl, 0x2
	jr z, VwVariBox_Match_Repaint
	ld xwa, 0xc80001
	ld xbc, 0x1e0007f
	ld xde, 2:i3
	call SendEvent
	ld xwa, 0xc80001
	ld xbc, 0x1c0000f
	ld xde, 2:i3

VwVariBox_Match_DispatchConfirm:
	call ApDeliveryEvent

VwVariBox_Match_Repaint:
	ld XWA, (xsp + 0x0118)
	ld xbc, 0x1c0000d
	ld xde, 0:i3
	jrl VwVariBox_DispatchAndReturn

VwVariBox_Paint:
	ld XWA, (xsp + 0x0118)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 38)
	cpw (xwa), 0x0
	jr z, VwVariBox_Paint_Greyed
	ld XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld XDE, (xsp + 0x0114)
	call InheritedProc
	jr VwVariBox_Paint_DrawLabel

VwVariBox_Paint_Greyed:
	lda_dri XBC, 0xfd, 0x08, 0x01
	ld XWA, (xsp + 0x0118)
	call GetBox
	lda_dri XWA, 0xfd, 0x08, 0x01
	ldw bc, 0xf5
	call DrawBox

VwVariBox_Paint_DrawLabel:
	ld xwa, (xsp + 4)
	ld wa, (xwa + 36)
	call DrawEditSw
	ld XWA, (xsp + 0x0118)
	ld xbc, 0x1c0000f
	ld xde, 0:i3
	jrl VwVariBox_DispatchAndReturn

VwVariBox_Confirm:
	ld XWA, (xsp + 0x0118)
	call GetViewInstance
	ld (xsp + 4), xhl
	lda_dri XBC, 0xfd, 0x08, 0x01
	ld XWA, (xsp + 0x0118)
	call GetClientBox
	lda_dri XWA, 0xfd, 0x08, 0x01
	lda_dri XBC, 0xfd, 0x10, 0x01
	call GetBoxCenter
	lda xde, (xsp + 8)
	ld xwa, xde
	lda xbc, (xde + 17)

VwVariBox_Confirm_ClearBuf:
	stib_dsp 0xe0, 0x00
	cp xwa, xbc
	jr c, VwVariBox_Confirm_ClearBuf
	ld XWA, (xsp + 0x0118)
	ld xbc, 0x1e0003a
	call SendEvent
	ld xwa, (xsp + 4)
	ld xiz, (xwa + 38)
	lda_dri XBC, 0xfd, 0x10, 0x01
	lda_dri XDE, 0xfd, 0x08, 0x01
	lda xiy, (xwa + 28)
	ld a, (xwa + 34)
	ldb_erp A, 0xf0
	extz ix
	lda xhl, (xsp + 8)
	cpw (xiz), 0x0
	jr z, VwVariBox_Confirm_NoSelection
	ld xwa, (xiy)
	push xwa
	ld xwa, (xsp + 8)
	pushm (xwa + 32)
	pushw 0xf7
	pushw ix
	ld xwa, xde
	ld xde, xhl
	jr VwVariBox_Confirm_Render

VwVariBox_Confirm_NoSelection:
	ld xwa, (xiy)
	push xwa
	pushw 0xff
	pushw 0xf7
	pushw ix
	ld xwa, xde
	ld xde, xhl

VwVariBox_Confirm_Render:
	call DrawStringAlignment

VwVariBox_ReturnHandled:
	ld xhl, 0:i3
	jrl VwVariBox_Return

VwVariBox_GetText:
	ld XWA, (xsp + 0x0118)
	call GetViewInstance
	lda xwa, (xhl + 42)
	cp (xwa), 0xd
	jr c, VwVariBox_GetText_LookupAudio
	ld c, (xwa)
	cp c, 0x10
	jr ule, VwVariBox_GetText_HighValues

VwVariBox_GetText_LookupAudio:
	ld a, (xwa)
	extz wa
	sla wa, 2
	lda xbc, (PtrTbl_MusicStyleBankNames:24)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	ld XWA, (xsp + 0x0118)
	push xwa
	call Sprintf_Locked
	inc 8, xsp
	jr VwVariBox_ReturnHandled

VwVariBox_GetText_HighValues:
	cp c, 0x10
	jr z, VwVariBox_GetText_Val10
	cp c, 0xf
	jr z, VwVariBox_GetText_Val0F
	cp c, 0xe
	jr z, VwVariBox_GetText_Val0E
	cp c, 0xd
	jr nz, VwVariBox_GetText_PlaySample
	ld xwa, 0x1e8a80
	jr VwVariBox_GetText_PlaySample

VwVariBox_GetText_Val0E:
	ld xwa, 0x1e8a90
	jr VwVariBox_GetText_PlaySample

VwVariBox_GetText_Val0F:
	ld xwa, 0x1e8a40
	jr VwVariBox_GetText_PlaySample

VwVariBox_GetText_Val10:
	ld xwa, 0x1e8a50

VwVariBox_GetText_PlaySample:
	pushw 0x10
	push xwa
	ld XWA, (xsp + 0x011a)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	jr VwVariBox_ReturnHandled

VwVariBox_OK:
	ld XWA, (xsp + 0x0118)
	call GetViewInstance
	cp (0x7f0b:16), 0
	jr nz, VwVariBox_OK_Forward
	ld wa, (xhl + 36)
	extz xwa
	cpl_sri_rm XWA, 0xfd, 0x14, 0x01
	jr nz, VwVariBox_OK_Forward
	ld de, (xhl + 26)
	cp de, 0xffff
	jr z, VwVariBox_OK_Forward
	exts xde
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001b
	call SendEvent
	ld XWA, (xsp + 0x0118)
	ld xbc, 0x1e0004d
	ld xde, 1:i3
	call SendEvent
	ld XWA, (xsp + 0x0118)
	call GetViewInstance
	ld c, (xhl + 42)
	extz bc
	ld xwa, 0x28800
	ld de, 0:i3
	call MainLswPut
	jrl VwVariBox_ReturnHandled

VwVariBox_OK_Forward:
	ld XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld XDE, (xsp + 0x0114)
	jr VwVariBox_ForwardToBase

VwVariBox_Release:
	ld XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld XDE, (xsp + 0x0114)
	call InheritedProc
	ld XWA, (xsp + 0x0118)
	call GetViewInstance
	ld wa, (xhl + 26)
	exts xwa
	cpl_sri_rm XWA, 0xfd, 0x14, 0x01
	jrl nz, VwVariBox_ReturnHandled
	ld xwa, (xhl + 38)
	cpw (xwa), 0x0
	jrl z, VwVariBox_ReturnHandled
	ld XWA, (xsp + 0x0118)
	ld xbc, 0x1e0004d
	ld xde, 0:i3

VwVariBox_DispatchAndReturn:
	call SendEvent
	jrl VwVariBox_ReturnHandled

VwVariBox_CanScroll:
	ld XWA, (xsp + 0x0118)
	call GetViewInstance
	ld wa, (xhl + 26)
	exts xwa
	cpl_sri_rm XWA, 0xfd, 0x14, 0x01
	jrl nz, VwVariBox_ReturnHandled
	ld xwa, (xhl + 38)
	cpw (xwa), 0x1
	jrl nz, VwVariBox_ReturnHandled
	ld xhl, 1:i3
	jr VwVariBox_Return

VwVariBox_Default:
	ld XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld XDE, (xsp + 0x0114)

VwVariBox_ForwardToBase:
	call InheritedProc

VwVariBox_Return:
	pop xiz
	lda_dri XSP, 0xfd, 0x18, 0x01
	ret

MspBnkShow:
	push xiz
	cp xbc, 0x1c0000c
	jrl z, MspBnk_ReturnZero
	cp xbc, 0x1c0000b
	jr z, MspBnk_ReturnZero
	cp xbc, 0x1c00002
	jr z, MspBnk_ReturnZero
	cp xbc, 0x1c00001
	jr nz, MspBnk_ReturnZero
	call GetTitleOld
	ld xiz, xhl
	call GetTitleNow
	cp xhl, xiz
	jr z, MspBnk_ReturnZero
	ld xwa, 0x28800
	call SndParam_LookupReadOnly
	cp hl, 0xa
	jr ge, MspBnk_SendEvt56_Case2
	ld xwa, 0xc80001
	ld xbc, 0x1e00056
	ld xde, 0:i3
	call SendEvent
	cp xhl, 0x1
	jr z, MspBnk_ReturnZero
	ld xwa, 0xc80001
	ld xbc, 0x1e0007f
	ld xde, 1:i3
	jr MspBnk_SendEvt7F

MspBnk_SendEvt56_Case2:
	ld xwa, 0xc80001
	ld xbc, 0x1e00056
	ld xde, 0:i3
	call SendEvent
	cp xhl, 0x2
	jr z, MspBnk_ReturnZero
	ld xwa, 0xc80001
	ld xbc, 0x1e0007f
	ld xde, 2:i3

MspBnk_SendEvt7F:
	call SendEvent

MspBnk_ReturnZero:
	ld xhl, 0:i3
	pop xiz
	ret
AcMspBnkSlBox_Entry:

AcMspBnkSlBoxProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld xiz, xbc
	ld (xsp + 12), xwa
	cp xiz, 0x1c00007
	jrl z, MspBnkSlBox_HandleEvt7
	cp xiz, 0x1e0004d
	jrl z, MspBnkSlBox_ReturnZeroJmp
	cp xiz, 0x1c0001c
	jrl z, MspBnkSlBox_HandleEvt1C
	cp xiz, 0x1c0000c
	jr z, MspBnkSlBox_HandleEvtBC
	cp xiz, 0x1c0000b
	jr z, MspBnkSlBox_HandleEvtBC
	cp xiz, 0x1c00002
	jr z, MspBnkSlBox_HandleEvt2
	cp xiz, 0x1c00001
	jrl nz, MspBnkSlBox_DefaultHandler
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xwa, (xsp + 12)
	ld xbc, 0x28800
	call SetLswFilter
	jrl MspBnkSlBox_ReturnZeroJmp

MspBnkSlBox_HandleEvt2:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xwa, (xsp + 12)
	ld xbc, 0x28800
	call ResetLswFilter
	jrl MspBnkSlBox_ReturnZeroJmp

MspBnkSlBox_HandleEvtBC:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xwa, 0x28800
	jrl MspBnkSlBox_CallMainLswGet

MspBnkSlBox_HandleEvt1C:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xiy, (xsp + 8)
	ld xwa, (xiy)
	cp xwa, 0x28800
	jr nz, MspBnkSlBox_ReturnZeroJmp
	ld a, (xhl + 50)
	ldb_erp A, 0xf0
	extz ix
	lda xde, (xhl + 46)
	ld xbc, (xde)
	cp ix, (xiy + 4)
	jr nz, MspBnkSlBox_Evt1C_SetZero
	ldw (xbc), 0x1
	jr MspBnkSlBox_Evt1C_SendNotify

MspBnkSlBox_Evt1C_SetZero:
	ldw (xbc), 0x0

MspBnkSlBox_Evt1C_SendNotify:
	ld xwa, (xde)
	ld de, (xwa)
	exts xde
	ld xwa, (xsp + 12)
	ld xbc, 0x1c0000e
	call SendEvent
	jr MspBnkSlBox_ReturnZeroJmp

MspBnkSlBox_HandleEvt7:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 12)
	call GetViewInstance
	cp (0x7f0b:16), 0
	jr nz, MspBnk_JoinLoadParams
	ld xwa, (xsp + 4)
	ld wa, (xwa + 42)
	extz xwa
	cp xwa, (xsp + 8)
	jr nz, MspBnk_JoinLoadParams
	cpw (xhl + 26), 0xffff
	jr z, MspBnk_JoinLoadParams
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld c, (xhl + 50)
	extz bc
	ld xwa, 0x28800
	ld de, 0:i3
	call MainLswPut
	ld xwa, 0x28800

MspBnkSlBox_CallMainLswGet:
	call MainLswGet

MspBnkSlBox_ReturnZeroJmp:
	ld xhl, 0:i3
	jr MspBnkSlBox_Epilogue

MspBnk_JoinLoadParams:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	jr MspBnkSlBox_CallInherited

MspBnkSlBox_DefaultHandler:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)

MspBnkSlBox_CallInherited:
	call InheritedProc

MspBnkSlBox_Epilogue:
	pop xiz
	lda xsp, (xsp + 12)
	ret
MspBnkSlBox_End:

PsMspBnkNameBoxProc:
	lda_dri XSP, 0xfd, 0xfc, 0xfe
	push xiz
	stl_dri XDE, 0xfd, 0x04, 0x01
	ld xiz, xwa
	cp xbc, 0x1e4001e
	jrl z, RgpSetBnk_GridCheck
	cp xbc, 0x1e4001d
	jrl z, MspBnkNameBox_HandleEvt1D
	cp xbc, 0x1e4001c
	jrl z, MspBnkNameBox_HandleEvt1C
	cp xbc, 0x1e4001b
	jrl z, MspBnkNameBox_HandleEvt1B
	cp xbc, 0x1c0000d
	jr z, MspBnkNameBox_HandleEvtD
	cp xbc, 0x1c00002
	jr z, MspBnkNameBox_HandleEvt2
	cp xbc, 0x1c00001
	jrl nz, RgpSetBnk_GridCheck_Case2
	ld xwa, xiz
	ld XDE, (xsp + 0x0104)
	jr MspBnkNameBox_CallInherited

MspBnkNameBox_HandleEvt2:
	ld xwa, xiz
	ld XDE, (xsp + 0x0104)

MspBnkNameBox_CallInherited:
	call InheritedProc
	jrl RgpSetBnk_GridCheck_Case1

MspBnkNameBox_HandleEvtD:
	ld xwa, xiz
	ld XDE, (xsp + 0x0104)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld a, (xhl + 36)
	cp a, 3:i3
	jr z, MspBnkNameBox_EvtD_Case3
	cp a, 2:i3
	jr z, MspBnkNameBox_EvtD_Case2
	cp a, 1:i3
	jr z, MspBnkNameBox_EvtD_Case1
	cp a, 0:i3
	jrl nz, RgpSetBnk_GridCheck_Case1
	ld xwa, 0x1440010
	ld xbc, 0x1e40017
	ld xde, 0:i3
	jr MspBnk_MainFuncDispatch

MspBnkNameBox_EvtD_Case1:
	ld xwa, 0x1440010
	ld xbc, 0x1e40018
	ld xde, 0:i3
	jr MspBnk_MainFuncDispatch

MspBnkNameBox_EvtD_Case2:
	ld xwa, 0x1440010
	ld xbc, 0x1e40019
	ld xde, 0:i3
	jr MspBnk_MainFuncDispatch

MspBnkNameBox_EvtD_Case3:
	ld xwa, 0x1440010
	ld xbc, 0x1e4001a
	ld xde, 0:i3

MspBnk_MainFuncDispatch:
	call MainFuncCall
	jrl RgpSetBnk_GridCheck_Case1

MspBnkNameBox_HandleEvt1B:
	ld xwa, xiz
	call GetViewInstance
	ld XWA, (xsp + 0x0104)
	push xwa
	lda xwa, (xsp + 8)
	push xwa
	call Sprintf_Locked
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1c0000f
	jr MspBnk_SendEventJoin

MspBnkNameBox_HandleEvt1C:
	ld xwa, xiz
	call GetViewInstance
	ld XWA, (xsp + 0x0104)
	push xwa
	lda xwa, (xsp + 8)
	push xwa
	call Sprintf_Locked
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1c0000f
	jr MspBnk_SendEventJoin

MspBnkNameBox_HandleEvt1D:
	ld xwa, xiz
	call GetViewInstance
	ld XWA, (xsp + 0x0104)
	push xwa
	lda xwa, (xsp + 8)
	push xwa
	call Sprintf_Locked
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1c0000f
	jr MspBnk_SendEventJoin

; RgpSetBnkCheck dispatch
RgpSetBnk_GridCheck:
	ld xwa, xiz
	call GetViewInstance
	ld XWA, (xsp + 0x0104)
	push xwa
	lda xwa, (xsp + 8)
	push xwa
	call Sprintf_Locked
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1c0000f

MspBnk_SendEventJoin:
	call SendEvent

; RgpSetBnkCheck case 1
RgpSetBnk_GridCheck_Case1:
	ld xhl, 0:i3
	jr RgpSetBnk_GridCheck_Case3

; RgpSetBnkCheck case 2
RgpSetBnk_GridCheck_Case2:
	ld xwa, xiz
	ld XDE, (xsp + 0x0104)
	call InheritedProc

; RgpSetBnkCheck case 3
RgpSetBnk_GridCheck_Case3:
	pop xiz
	lda_dri XSP, 0xfd, 0x04, 0x01
	ret

MspRGrpSetGridCheck:
	lda xsp, (xsp - 28)
	ld xwa, xbc
	cp xbc, 0x1e0008d
	jrl z, RgpSetBnk_GridCheck_EventEnc
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, RgpSetBnk_GridCheck_Return
	cp xwa, 0x6
	jrl gt, RgpSetBnk_GridCheck_Return
	add xwa, xwa
	add xwa, StrMsBankLong2_Effect1_0x18
	ld wa, (xwa)
	lda xix, (MspRGrpSetGridCheck_DataBlock:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

MspRGrpSetGridCheck_DataBlock:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 0x01e0008f
	ld	xde, 0:i3
	call	SendEvent
	ld	xde, xhl
	lda	xwa, (xsp+20)
	ld	xbc, xde
	srl	xbc, 0
	ld	qbc, 0
	ld	(xwa), bc
	ld	(xwa+2), de
	ld	wa, (xwa)
	exts	xde
	cp	wa, 2:i3
	jr	z, 17
	cp	wa, 1:i3
	jrl	nz, 273
	ld	xwa, 0x0144000f
	ld	xbc, 0x01e40012
	jr	82
	ld	xwa, 0x0144000f
	ld	xbc, 0x01e40014
	jr	70
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 0x01e0008f
	ld	xde, 0:i3
	call	SendEvent
	ld	xde, xhl
	lda	xwa, (xsp+20)
	ld	xbc, xde
	srl	xbc, 0
	ld	qbc, 0
	ld	(xwa), bc
	ld	(xwa+2), de
	ld	wa, (xwa)
	exts	xde
	cp	wa, 2:i3
	jr	z, 17
	cp	wa, 1:i3
	jrl	nz, 201
	ld	xwa, 0x0144000f
	ld	xbc, 0x01e40013
	jr	10
	ld	xwa, 0x0144000f
	ld	xbc, 0x01e40015
	call	MainFuncCall
	jrl	172

; RgpSetBnkCheck event encoding dispatch
RgpSetBnk_GridCheck_EventEnc:
	lda xhl, (xsp + 20)
	ld xwa, xde
	srl xwa, 0
	ldiw_erp 0xe2, 0
	ld (xhl), wa
	lda xbc, (xhl + 2)
	ld (xbc), de
	lda xde, (xsp)
	ld (xhl + 4), xde
	ld a, (0x7f3d:16)
	sll a, 4
	ld w, 0x0:opc
	extz xwa
	add xwa, 0x1e8a00
	ld xix, xwa
	ld hl, (xhl)
	ld wa, (xbc)
	sla wa, 1
	dec 4, wa
	exts xwa
	add xwa, xix
	cp hl, 2:i3
	jr z, RgpSetBnk_EvtEnc_SendAudioCmd
	cp hl, 1:i3
	jr nz, AudioEvt_GetFocusRetZero
	ld xbc, xwa
	ld l, (xwa)
	cp l, 0xd
	jr nc, RgpSetBnk_EvtEnc_HighIndex
	ld a, (xbc)
	extz wa
	sla wa, 2
	lda xbc, (PtrTbl_MusicStyleBankNames2:24)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	push xde
	call Sprintf_Locked
	inc 8, xsp
	jr AudioEvt_GetFocusRetZero

RgpSetBnk_EvtEnc_HighIndex:
	ld xwa, 0x1e8a80
	cp l, 0xe
	jr nz, RgpSetBnk_EvtEnc_CopyMem
	ld xwa, 0x1e8a90

RgpSetBnk_EvtEnc_CopyMem:
	pushw 0x10
	push xwa
	push xde
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld (xsp + 16), 0x0
	jr AudioEvt_GetFocusRetZero

RgpSetBnk_EvtEnc_SendAudioCmd:
	ld a, (xwa + 1)
	inc 1, a
	extz wa
	pushw wa
	pushw 0xe1
	pushw 0xe2bc
	push xde
	call Sprintf_Locked
	lda xsp, (xsp + 10)

AudioEvt_GetFocusRetZero:
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 20)
	ld xbc, 0x1e0008c
	call SendEvent

; RgpSetBnkCheck return
RgpSetBnk_GridCheck_Return:
	ld xhl, 0:i3
	lda xsp, (xsp + 28)
	ret
PsRgpSetBnkBoxProc_Entry:

PsRgpSetBnkBoxProc:
	lda_dri XSP, 0xfd, 0x00, 0xff
	push xiz
	ld xiz, xwa
	cp xbc, 0x1c0000c
	jr z, RgpSetBnkBox_HandleEvtBC
	cp xbc, 0x1c0000b
	jr z, RgpSetBnkBox_HandleEvtBC
	cp xbc, 0x1c00002
	jr z, RgpSetBnkBox_HandleEvt2
	cp xbc, 0x1c00001
	jr z, RgpSetBnkBox_HandleEvt1
	ld xwa, xiz
	call InheritedProc
	jr RgpSetBnkBox_Epilogue

RgpSetBnkBox_HandleEvt1:
	ld xwa, xiz
	jr RgpSetBnkBox_CallInherited

RgpSetBnkBox_HandleEvt2:
	ld xwa, xiz

RgpSetBnkBox_CallInherited:
	call InheritedProc
	jr RgpSetBnkBox_SetReturnZero

RgpSetBnkBox_HandleEvtBC:
	ld xwa, xiz
	call InheritedProc
	ld a, (0x7f3d:16)
	extz wa
	sla wa, 2
	lda xbc, (StrMsBankLong2_Effect1_0x26:24)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	lda xwa, (xsp + 8)
	push xwa
	call Sprintf_Locked
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1c0000f
	call SendEvent

RgpSetBnkBox_SetReturnZero:
	ld xhl, 0:i3

RgpSetBnkBox_Epilogue:
	pop xiz
	lda_dri XSP, 0xfd, 0x00, 0x01
	ret

MspRGrpSetBnkFunc:
	pushw_erp 0xfa
	cp xbc, 0x1c00007
	jr nz, MspRGrpSetBnk_ReturnZero
	cp (0x7f3d:16), 0
	jr nz, MspRGrpSetBnk_SetToZero
	ld (0x7f3d:16), 1
	jr MspRGrpSetBnk_UpdateLsw

MspRGrpSetBnk_SetToZero:
	ld (0x7f3d:16), 0

MspRGrpSetBnk_UpdateLsw:
	ld c, (0x7f3d:16)
	add c, 0xf
	extz bc
	ld xwa, 0x28800
	ld de, 0:i3
	call MainLswPut
	ld xwa, 0xcc0007
	ld xbc, 0x1c0000b
	ld xde, 0:i3
	call SendEvent
	ldib_erp 0xfa, 2

MspRGrpSetBnk_OuterLoop:
	ldib_erp 0xfb, 1

MspRGrpSetBnk_InnerLoop:
	stb_erp A, 0xfa
	extz wa
	ld bc, wa
	extz xbc
	stb_erp A, 0xfb
	extz wa
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld xwa, 0xcc0003
	ld xbc, 0x1e0008d
	call SendEvent
	inc1b_erp 0xfb
	cpib_erp 0xfb, 2
	jr ule, MspRGrpSetBnk_InnerLoop
	inc1b_erp 0xfa
	cpib_erp 0xfa, 7
	jr ule, MspRGrpSetBnk_OuterLoop

MspRGrpSetBnk_ReturnZero:
	ld xhl, 0:i3
	popw_erp 0xfa
	ret

MspRgpShowHideFunc:
	cp xbc, 0x1c0000c
	jr z, MspRgpShow_ReturnZero
	cp xbc, 0x1c0000b
	jr z, MspRgpShow_ReturnZero
	cp xbc, 0x1c00002
	jr z, MspRgpShow_ReturnZero
	cp xbc, 0x1c00001
	jr nz, MspRgpShow_ReturnZero
	or xde, xde
	jr nz, MspRgpShow_ReturnZero
	ld a, (0x7f3d:16)
	cp a, 1:i3
	jr z, MspRgpShowHide_BankSelect1
	cp a, 0:i3
	jr nz, MspRgpShow_ReturnZero
	ld xwa, 0x28800
	ldw bc, 0xf
	ld de, 0:i3
	jr MspRgpShowHide_PutLsw

MspRgpShowHide_BankSelect1:
	ld xwa, 0x28800
	ldw bc, 0x10
	ld de, 0:i3

MspRgpShowHide_PutLsw:
	call MainLswPut

MspRgpShow_ReturnZero:
	ld xhl, 0:i3
	ret
MspRgpShowHide_End:

PsMspMeasBoxProc:
	lda_dri XSP, 0xfd, 0x00, 0xff
	push xiz
	ld xiz, xwa
	cp xbc, 0x1c0000c
	jr z, MspMeasBox_HandleEvtBC
	cp xbc, 0x1c0000b
	jr z, MspMeasBox_HandleEvtBC
	cp xbc, 0x1c00002
	jr z, MspMeasBox_HandleEvt2
	cp xbc, 0x1c00001
	jr z, MspMeasBox_HandleEvt1
	ld xwa, xiz
	call InheritedProc
	jr MspMeasBox_Epilogue

MspMeasBox_HandleEvt1:
	ld xwa, xiz
	jr MspMeasBox_CallInherited

MspMeasBox_HandleEvt2:
	ld xwa, xiz

MspMeasBox_CallInherited:
	call InheritedProc
	jr MspMeasBox_SetReturnZero

MspMeasBox_HandleEvtBC:
	ld xwa, xiz
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld wa, (0x7f0e:16)
	pushw wa
	pushw 0xe1
	pushw 0xe2f8
	lda xwa, (xsp + 10)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1c0000f
	call SendEvent

MspMeasBox_SetReturnZero:
	ld xhl, 0:i3

MspMeasBox_Epilogue:
	pop xiz
	lda_dri XSP, 0xfd, 0x00, 0x01
	ret
MspMeasBox_End:

PsMspMemBoxProc:
	lda_dri XSP, 0xfd, 0x00, 0xff
	push xiz
	ld xiz, xwa
	cp xbc, 0x1c0000c
	jr z, MspMemBox_HandleEvtBC
	cp xbc, 0x1c0000b
	jr z, MspMemBox_HandleEvtBC
	cp xbc, 0x1c00002
	jr z, MspMemBox_HandleEvt2
	cp xbc, 0x1c00001
	jr z, MspMemBox_HandleEvt1
	ld xwa, xiz
	call InheritedProc
	jr MspMemBox_Epilogue

MspMemBox_HandleEvt1:
	ld xwa, xiz
	jr MspMemBox_CallInherited

MspMemBox_HandleEvt2:
	ld xwa, xiz

MspMemBox_CallInherited:
	call InheritedProc
	jr MspMemBox_SetReturnZero

MspMemBox_HandleEvtBC:
	ld xwa, xiz
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld wa, (0x7e18:16)
	mul wa, 0x64
	extz xwa
	div wa, 0x39
	cp wa, 0x63
	jr ule, MspMemBox_ClampValue
	ldw wa, 0x63

MspMemBox_ClampValue:
	extz wa
	pushw wa
	pushw 0xe1
	pushw 0xe306
	lda xwa, (xsp + 10)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1c0000f
	call SendEvent

MspMemBox_SetReturnZero:
	ld xhl, 0:i3

MspMemBox_Epilogue:
	pop xiz
	lda_dri XSP, 0xfd, 0x00, 0x01
	ret
MspMemBox_End:

PsMspRecBnkBoxProc:
	lda_dri XSP, 0xfd, 0x00, 0xff
	push xiz
	ld xiz, xwa
	cp xbc, 0x1c0000c
	jr z, MspRecBnkBox_HandleEvtBC
	cp xbc, 0x1c0000b
	jr z, MspRecBnkBox_HandleEvtBC
	cp xbc, 0x1c00002
	jr z, MspRecBnkBox_HandleEvt2
	cp xbc, 0x1c00001
	jr z, MspRecBnkBox_HandleEvt1
	ld xwa, xiz
	call InheritedProc
	jr MspRecBnkBox_Epilogue

MspRecBnkBox_HandleEvt1:
	ld xwa, xiz
	jr MspRecBnkBox_CallInherited

MspRecBnkBox_HandleEvt2:
	ld xwa, xiz

MspRecBnkBox_CallInherited:
	call InheritedProc
	jr MspRecBnkBox_SetReturnZero

MspRecBnkBox_HandleEvtBC:
	ld xwa, xiz
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld xwa, 0x1e8a80
	cp (0x7f14:16), 5
	jr ule, MspRecBnkBox_CopyMemBlock
	ld xwa, 0x1e8a90

MspRecBnkBox_CopyMemBlock:
	pushw 0x10
	push xwa
	lda xwa, (xsp + 10)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	lda xde, (xsp + 4)
	ld (xde + 16), 0x0
	ld xwa, xiz
	ld xbc, 0x1c0000f
	call SendEvent

MspRecBnkBox_SetReturnZero:
	ld xhl, 0:i3

MspRecBnkBox_Epilogue:
	pop xiz
	lda_dri XSP, 0xfd, 0x00, 0x01
	ret
MspRecBnkBox_End:

PsMspRecPadBoxProc:
	lda_dri XSP, 0xfd, 0x00, 0xff
	push xiz
	ld xiz, xwa
	cp xbc, 0x1c0000c
	jr z, MspRecPadBox_HandleEvtBC
	cp xbc, 0x1c0000b
	jr z, MspRecPadBox_HandleEvtBC
	cp xbc, 0x1c00002
	jr z, MspRecPadBox_HandleEvt2
	cp xbc, 0x1c00001
	jr z, MspRecPadBox_HandleEvt1
	ld xwa, xiz
	call InheritedProc
	jr AcSndArgGrid_BnkCase2

MspRecPadBox_HandleEvt1:
	ld xwa, xiz
	jr MspRecPadBox_CallInherited

MspRecPadBox_HandleEvt2:
	ld xwa, xiz

MspRecPadBox_CallInherited:
	call InheritedProc
	jr AcSndArgGrid_BnkCase1

MspRecPadBox_HandleEvtBC:
	ld xwa, xiz
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld a, (0x7f14:16)
	cp a, 5:i3
	jr ule, AcSndArgGrid_BnkDispatch
	dec 6, a

; AcSndArgGridBnkFunc dispatch
AcSndArgGrid_BnkDispatch:
	inc 1, a
	extz wa
	pushw wa
	pushw 0xe1
	pushw 0xe314
	lda xwa, (xsp + 10)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1c0000f
	call SendEvent

; AcSndArgGridBnk case 1
AcSndArgGrid_BnkCase1:
	ld xhl, 0:i3

; AcSndArgGridBnk case 2
AcSndArgGrid_BnkCase2:
	pop xiz
	lda_dri XSP, 0xfd, 0x00, 0x01
	ret

MspPlayModeFunc:
	lda xsp, (xsp - 12)
	push xiz
	ld xiz, xde
	ld xde, xbc
	ld (xsp + 12), xwa
	ld xiy, StrCompileBank1_0x30
	lda xix, (xsp + 4)
	ld bc, 4:i3
	ldirw
	ld xwa, xde
	cp xde, 0x1e00082
	jr z, AcSndArgGrid_BoxProc
	sub xwa, 0x1e0003e
	cp xwa, 0x0
	jr lt, AcSndArgGrid_BoxCase1
	cp xwa, 0x9
	jr gt, AcSndArgGrid_BoxCase1
	add xwa, xwa
	add xwa, StrInstantStart_0x12
	ld wa, (xwa)
	lda xix, (MspPlayModeFunc_DataBlock:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

MspPlayModeFunc_DataBlock:
	ld	wa, 0:i3
	call	SetDialEnable
	ld	xwa, (xiz+14)
	sll	xwa, 2
	lda	xbc, (xsp+4)
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xiz+18)
	push	xwa
	call	Strcpy
	inc	8, xsp
	ld	xhl, (xsp+12)
	jr	43
	ld	a, (1054:16)
	and	a, 4
	cp	a, 4:i3
	scc16	nz, hl
	extz	xhl
	jr	28
	ld	xhl, 1:i3
	jr	24
	lda	xhl, (0x7f3f:16)
	jr	18

; AcSndArgGridBoxProc dispatch (7-entry, table 0xe1e35e)
AcSndArgGrid_BoxProc:
	ld xwa, 0x1440015
	ld xbc, 0x1e4001f
	ld xde, xiz
	call MainFuncCall

; AcSndArgGridBox case 1
AcSndArgGrid_BoxCase1:
	ld xhl, 0:i3
	pop xiz
	lda xsp, (xsp + 12)
	ret
; AcSndArgGridBox case 2
AcSndArgGrid_BoxCase2:
AcSndArgGridBoxProc:
	lda xsp, (xsp - 22)
	push xiz
	ld (xsp + 18), xde
	ld xiz, xbc
	ld (xsp + 22), xwa
	ld xiy, StrInstantStart_0x26
	lda xix, (xsp + 12)
	ld bc, 2:i3
	ldirw
	ldi85
	ld xwa, xiz
	cp xiz, 0x1e0008c
	jrl z, AcSndArgGrid_PlayAudio
	cp xiz, 0x1e40023
	jrl z, AcSndArgGrid_ForwardToParent
	cp xiz, 0x1e40022
	jrl z, AcSndArgGrid_ForwardToParent
	cp xiz, 0x1e0008d
	jrl z, AcSndArgGrid_ForwardToParent
	cp xiz, 0x1e0008b
	jrl z, AcSndArgGrid_GetRowText
	cp xiz, 0x1e0008a
	jrl z, AcSndArgGrid_GetColText
	cp xiz, 0x1c00001
	jr z, AcSndArgGrid_Init
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, AcSndArgGrid_ForwardToBase
	cp xwa, 0x6
	jrl gt, AcSndArgGrid_ForwardToBase
	add xwa, xwa
	add xwa, StrInstantStart_0x2C
	ld wa, (xwa)
	lda xix, (AcSndArgGrid_Init:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

AcSndArgGrid_Init:
	ld xwa, (xsp + 22)
	ld xbc, xiz
	ld xde, (xsp + 18)
	call InheritedProc
	ld xwa, (xsp + 22)
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, (xsp + 22)
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
	ld xwa, (xsp + 22)
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
	ld xwa, (xsp + 22)
	ld xbc, 0x1c00018
	call SetDialDown
	ld wa, 1:i3
	jrl AcSndArgGrid_ScrollCommit
	ld xwa, (xsp + 22)
	ld xbc, xiz
	ld xde, (xsp + 18)
	call InheritedProc
	ld xwa, (xsp + 22)
	ld xbc, 0x1e00050
	ld xde, (xsp + 18)
	call SendEvent
	or xhl, xhl
	jr z, AcSndArgGrid_ScrollUp_NoCanScroll
	ld xwa, (xsp + 22)
	ld xbc, 0x1e0008f
	ld xde, 0:i3
	call SendEvent
	dec 1, hl
	extz xhl
	add xhl, 0xffff0000
	ld xwa, (xsp + 22)
	ld xbc, 0x1c0000e
	ld xde, xhl
	call SendEvent
	ld xwa, (xsp + 22)
	ld xbc, 0x1c00019
	ld xde, (xsp + 18)
	call SetAutoInc
	ld xwa, (xsp + 22)
	call GetViewInstance
	ld xwa, (xhl + 42)
	ld de, (xwa)
	ld a, e
	dec 2, a
	extz wa
	lda xbc, (xsp + 12)
	ldmm_srib 0x07, 0xe4, 0xe0, 0x8e, 0x33
	ld d, 0x0:opc
	extz xde
	ld xwa, 0x144001b
	ld xbc, 0x1e40024
	call MainFuncCall
	jrl AcSndArgGrid_ReturnHandled

AcSndArgGrid_ScrollUp_NoCanScroll:
	ld xwa, (xsp + 22)
	ld xbc, 0x1e00091
	ld xde, (xsp + 18)
	call SendEvent
	or xhl, xhl
	jrl z, AcSndArgGrid_ReturnHandled
	ld xwa, (xsp + 22)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, xiz
	ld xde, (xsp + 18)
	call ApFuncCall
	ld xwa, (xsp + 22)
	ld xbc, 0x1c00019
	ld xde, (xsp + 18)
	call SetAutoInc
	ld xwa, (xsp + 22)
	ld xbc, 0x1c00017
	ld xde, (xsp + 18)
	call SetDialUp
	ld xwa, (xsp + 22)
	ld xbc, 0x1c00018
	ld xde, (xsp + 18)
	call SetDialDown
	ld wa, 1:i3
	jrl AcSndArgGrid_ScrollCommit
	ld xwa, (xsp + 22)
	ld xbc, xiz
	ld xde, (xsp + 18)
	call InheritedProc
	ld xwa, (xsp + 22)
	ld xbc, 0x1e00050
	ld xde, (xsp + 18)
	call SendEvent
	or xhl, xhl
	jr z, AcSndArgGrid_ScrollDown_NoCanScroll
	ld xwa, (xsp + 22)
	ld xbc, 0x1e0008f
	ld xde, 0:i3
	call SendEvent
	inc 1, hl
	extz xhl
	add xhl, 0xffff0000
	ld xwa, (xsp + 22)
	ld xbc, 0x1c0000e
	ld xde, xhl
	call SendEvent
	ld xwa, (xsp + 22)
	ld xbc, 0x1c0001a
	ld xde, (xsp + 18)
	call SetAutoInc
	ld xwa, (xsp + 22)
	call GetViewInstance
	ld xwa, (xhl + 42)
	ld de, (xwa)
	ld a, e
	dec 2, a
	extz wa
	lda xbc, (xsp + 12)
	ldmm_srib 0x07, 0xe4, 0xe0, 0x8e, 0x33
	ld d, 0x0:opc
	extz xde
	ld xwa, 0x144001b
	ld xbc, 0x1e40024
	call MainFuncCall
	jrl AcSndArgGrid_ReturnHandled

AcSndArgGrid_ScrollDown_NoCanScroll:
	ld xwa, (xsp + 22)
	ld xbc, 0x1e00091
	ld xde, (xsp + 18)
	call SendEvent
	or xhl, xhl
	jrl z, AcSndArgGrid_ReturnHandled
	ld xwa, (xsp + 22)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, xiz
	ld xde, (xsp + 18)
	call ApFuncCall
	ld xwa, (xsp + 22)
	ld xbc, 0x1c0001a
	ld xde, (xsp + 18)
	call SetAutoInc
	ld xwa, (xsp + 22)
	ld xbc, 0x1c00017
	ld xde, (xsp + 18)
	call SetDialUp
	ld xwa, (xsp + 22)
	ld xbc, 0x1c00018
	ld xde, (xsp + 18)
	call SetDialDown
	ld wa, 1:i3

AcSndArgGrid_ScrollCommit:
	call SetDialEnable
	jrl AcSndArgGrid_ReturnHandled

AcSndArgGrid_GetColText:
	ld xwa, (xsp + 22)
	ld xiz, 0x3e
	jr AcSndArgGrid_CopyText

AcSndArgGrid_GetRowText:
	ld xwa, (xsp + 22)
	ld xiz, 0x42

AcSndArgGrid_CopyText:
	call GetViewInstance
	add xhl, xiz
	ld xwa, (xhl)
	push xwa
	ld xwa, (xsp + 22)
	push xwa
	call Strcpy
	inc 8, xsp
	jrl AcSndArgGrid_ReturnHandled
	ld xwa, (xsp + 22)
	ld xbc, xiz
	ld xde, (xsp + 18)
	call InheritedProc
	call GetTitleNow
	cp xhl, 0x1a000dc
	jrl nz, AcSndArgGrid_ReturnHandled
	ld xwa, (xsp + 18)
	ld xwa, (xwa)
	cp xwa, 0xc85e
	jrl z, AcSndArgGrid_CellSel_C85E
	cp xwa, 0xc820
	jrl z, AcSndArgGrid_CellSel_C800
	cp xwa, 0xc800
	jrl z, AcSndArgGrid_CellSel_C800
	cp xwa, 0xc45e
	jrl z, AcSndArgGrid_CellSel_C45E
	cp xwa, 0xc420
	jrl z, AcSndArgGrid_CellSel_C400
	cp xwa, 0xc400
	jrl z, AcSndArgGrid_CellSel_C400
	cp xwa, 0xc05e
	jr z, AcSndArgGrid_CellSel_C05E
	cp xwa, 0xc020
	jr z, AcSndArgGrid_CellSel_C000
	cp xwa, 0xc000
	jr z, AcSndArgGrid_CellSel_C000
	cp xwa, 0xcc5e
	jr z, AcSndArgGrid_CellSel_CC5E
	cp xwa, 0xcc20
	jr z, AcSndArgGrid_CellSel_CC00
	cp xwa, 0xcc00
	jr z, AcSndArgGrid_CellSel_CC00
	cp xwa, 0xd000
	jrl nz, AcSndArgGrid_ReturnHandled
	ld xwa, (xsp + 22)
	ld xbc, 0x1e0008d
	ld xde, 0x10002
	jr AcSndArgGrid_CellSel_Dispatch

AcSndArgGrid_CellSel_CC00:
	ld xwa, (xsp + 22)
	ld xbc, 0x1e0008d
	ld xde, 0x10003
	jr AcSndArgGrid_CellSel_Dispatch

AcSndArgGrid_CellSel_CC5E:
	ld xwa, (xsp + 22)
	ld xbc, 0x1e0008d
	ld xde, 0x20003
	jr AcSndArgGrid_CellSel_Dispatch

AcSndArgGrid_CellSel_C000:
	ld xwa, (xsp + 22)
	ld xbc, 0x1e0008d
	ld xde, 0x10004
	jr AcSndArgGrid_CellSel_Dispatch

AcSndArgGrid_CellSel_C05E:
	ld xwa, (xsp + 22)
	ld xbc, 0x1e0008d
	ld xde, 0x20004
	jr AcSndArgGrid_CellSel_Dispatch

AcSndArgGrid_CellSel_C400:
	ld xwa, (xsp + 22)
	ld xbc, 0x1e0008d
	ld xde, 0x10005
	jr AcSndArgGrid_CellSel_Dispatch

AcSndArgGrid_CellSel_C45E:
	ld xwa, (xsp + 22)
	ld xbc, 0x1e0008d
	ld xde, 0x20005
	jr AcSndArgGrid_CellSel_Dispatch

AcSndArgGrid_CellSel_C800:
	ld xwa, (xsp + 22)
	ld xbc, 0x1e0008d
	ld xde, 0x10006
	jr AcSndArgGrid_CellSel_Dispatch

AcSndArgGrid_CellSel_C85E:
	ld xwa, (xsp + 22)
	ld xbc, 0x1e0008d
	ld xde, 0x20006

AcSndArgGrid_CellSel_Dispatch:
	call SendEvent
	jr AcSndArgGrid_ReturnHandled

AcSndArgGrid_ForwardToParent:
	ld xwa, (xsp + 22)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, xiz
	ld xde, (xsp + 18)
	call ApFuncCall
	jr AcSndArgGrid_ReturnHandled

AcSndArgGrid_PlayAudio:
	call GetTitleNow
	cp xhl, 0x1a000ee
	jr nz, AcSndArgGrid_ForwardToBase

AcSndArgGrid_ReturnHandled:
	ld xhl, 0:i3
	jr AcSndArgGrid_Return

AcSndArgGrid_ForwardToBase:
	ld xwa, (xsp + 22)
	ld xbc, xiz
	ld xde, (xsp + 18)
	call InheritedProc

AcSndArgGrid_Return:
	pop xiz
	lda xsp, (xsp + 22)
	ret

SndArgGridCheck:
	lda xsp, (xsp - 28)
	push xiz
	ld xiy, xbc
	ld wa, de
	srl xde, 0
	ldw_erp WA, 0xe2
	ldiw_erp 0xea, 0
	ld wa, de
	lda xix, (xsp + 24)
	lda xiz, (xsp + 4)
	lda xde, (xix + 2)
	lda xhl, (xix + 4)
	cp xbc, 0x1e40023
	jrl z, SndArgGridCheck_PlayRowAudio
	cp xbc, 0x1e40022
	jr z, SndArgGridCheck_PlayColAudio
	cp xbc, 0x1e0008d
	jr z, SndArgGridCheck_CellSelect
	ld xhl, 0:i3
	ld xwa, xiy
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, SndArgGridCheck_Return
	cp xwa, 0x6
	jrl gt, SndArgGridCheck_Return
	add xwa, xwa
	add xwa, StrInstantStart_0x3A
	ld wa, (xwa)
	lda xix, (SndArgGridCheck_JumpTableFallthrough:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

SndArgGridCheck_JumpTableFallthrough:
	jrl	t, 0x00e7

SndArgGridCheck_CellSelect:
	ld (xix), wa
	stw_erp WA, 0xe2
	ld (xde), wa
	ld (xhl), xiz
	ld wa, (xix)
	ld de, (xde)
	exts xde
	cp wa, 2:i3
	jr z, SndArgGridCheck_CellSel_Row2
	cp wa, 1:i3
	jrl nz, SndArgGridCheck_ReturnHandled
	ld xwa, 0x144001b
	ld xbc, 0x1e40020
	jr SndArgGridCheck_CellSel_SendEvent

SndArgGridCheck_CellSel_Row2:
	ld xwa, 0x144001b
	ld xbc, 0x1e40021

SndArgGridCheck_CellSel_SendEvent:
	call MainFuncCall
	jrl SndArgGridCheck_ReturnHandled

SndArgGridCheck_PlayColAudio:
	ld (xix), wa
	stw_erp WA, 0xe2
	ld (xde), wa
	ld xbc, xiz
	ld (xhl), xiz
	ld wa, (xde)
	dec 2, wa
	cp wa, 4:i3
	jr z, SndArgGridCheck_PlayCol_4
	cp wa, 3:i3
	jr z, SndArgGridCheck_PlayCol_3
	cp wa, 2:i3
	jr z, SndArgGridCheck_PlayCol_2
	cp wa, 1:i3
	jr z, SndArgGridCheck_PlayCol_1
	cp wa, 0:i3
	jr nz, SndArgGridCheck_PlayCol_Send
	lda xwa, (0x39f8:16)
	jr SndArgGridCheck_PlayCol_Strcpy

SndArgGridCheck_PlayCol_1:
	lda xwa, (0x3a09:16)
	jr SndArgGridCheck_PlayCol_Strcpy

SndArgGridCheck_PlayCol_2:
	lda xwa, (0x3a1a:16)
	jr SndArgGridCheck_PlayCol_Strcpy

SndArgGridCheck_PlayCol_3:
	lda xwa, (0x3a2b:16)
	jr SndArgGridCheck_PlayCol_Strcpy

SndArgGridCheck_PlayCol_4:
	lda xwa, (0x3a3c:16)

SndArgGridCheck_PlayCol_Strcpy:
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp

SndArgGridCheck_PlayCol_Send:
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 24)
	ld xbc, 0x1e0008c
	jr SndArgGridCheck_DispatchPlayAudio

SndArgGridCheck_PlayRowAudio:
	ld (xix), wa
	stw_erp WA, 0xe2
	ld (xde), wa
	ld xbc, xiz
	ld (xhl), xiz
	ld wa, (xde)
	dec 2, wa
	cp wa, 4:i3
	jr z, SndArgGridCheck_PlayRow_4
	cp wa, 3:i3
	jr z, SndArgGridCheck_PlayRow_3
	cp wa, 2:i3
	jr z, SndArgGridCheck_PlayRow_2
	cp wa, 1:i3
	jr z, SndArgGridCheck_PlayRow_1
	cp wa, 0:i3
	jr nz, SndArgGridCheck_PlayRow_Finalize
	lda xwa, (0x39e4:16)
	jr SndArgGridCheck_PlayRow_Send

SndArgGridCheck_PlayRow_1:
	lda xwa, (0x39e8:16)
	jr SndArgGridCheck_PlayRow_Send

SndArgGridCheck_PlayRow_2:
	lda xwa, (0x39ec:16)
	jr SndArgGridCheck_PlayRow_Send

SndArgGridCheck_PlayRow_3:
	lda xwa, (0x39f0:16)
	jr SndArgGridCheck_PlayRow_Send

SndArgGridCheck_PlayRow_4:
	lda xwa, (0x39f4:16)

SndArgGridCheck_PlayRow_Send:
	push xwa
	push xbc
	call Sprintf_Locked
	inc 8, xsp

SndArgGridCheck_PlayRow_Finalize:
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 24)
	ld xbc, 0x1e0008c

SndArgGridCheck_DispatchPlayAudio:
	call SendEvent

SndArgGridCheck_ReturnHandled:
	ld xhl, 0:i3

SndArgGridCheck_Return:
	pop xiz
	lda xsp, (xsp + 28)
	ret

SndArgTtlCheck:
	cp xbc, 0x1c00001
	jr nz, ParamList_ReturnZero
	call GetTitleOld
	cp xhl, 0x1a000ee
	jr nz, ParamList_ReturnZero
	cp (0x339f:16), 1
	jr nz, ParamList_ReturnZero
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	ld xde, 1:i3
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	ld xde, 0:i3
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c00014
	ld xde, 0x1800001
	call PostEvent

ParamList_ReturnZero:
	ld xhl, 0:i3
	ret
PsParaListBoxProc_Entry:

PsParaListBoxProc:
	lda_dri XSP, 0xfd, 0x62, 0xff
	push xiz
	stl_dri XDE, 0xfd, 0x9e, 0x00
	ld xiz, xwa
	cp xbc, 0x1e4002f
	jrl z, SndArgGrid_CheckCase2
	cp xbc, 0x1c0000f
	jrl z, ParaListBox_HandleEvtF
	cp xbc, 0x1c0000b
	jr z, ParaListBox_HandleEvtB
	ld xwa, xiz
	ld_sril XDE, (xsp + 0x009e)
	call InheritedProc
	jrl SndArgGrid_CheckCase3

ParaListBox_HandleEvtB:
	ld xwa, xiz
	ld_sril XDE, (xsp + 0x009e)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 10), xhl
	ld xwa, (xsp + 10)
	cpw (xwa + 34), 0x2
	jrl lt, PsParaListBoxProc_Return
	lda_dri XBC, 0xfd, 0x8e, 0x00
	ld xwa, xiz
	call GetClientBox
	lda_dri XDE, 0xfd, 0x8e, 0x00
	ld bc, (xde + 4)
	sub bc, (xde)
	exts xbc
	ld xwa, (xsp + 10)
	mrdw3 0x98, 0x22, 0x59
	ld (xsp + 4), bc
	ld wa, (xde + 2)
	inc 1, wa
	stw_dri WA, 0xfd, 0x9c, 0x00
	ld wa, (xde + 6)
	dec 1, wa
	stw_dri WA, 0xfd, 0x98, 0x00
	ld iz, 1:i3
	jr ParaListBox_DrawLineLoop_Check

ParaListBox_DrawLineLoop_Body:
	ld wa, (xsp + 4)
	mul xwa, xiz
	ldw_sri0 BC, (xsp + 0x008e)
	add bc, wa
	dec 1, bc
	lda_dri XWA, 0xfd, 0x9a, 0x00
	ld (xwa), bc
	lda_dri XBC, 0xfd, 0x96, 0x00
	ld de, (xwa)
	ld (xbc), de
	ld de, 7:i3
	call DrawLine
	inc 1, iz

ParaListBox_DrawLineLoop_Check:
	ld xwa, (xsp + 10)
	ld wa, (xwa + 34)
	cp iz, wa
	jr c, ParaListBox_DrawLineLoop_Body
	jrl PsParaListBoxProc_Return

ParaListBox_HandleEvtF:
	ld xwa, xiz
	ld_sril XDE, (xsp + 0x009e)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 6), xhl
	ld_sril XDE, (xsp + 0x009e)
	or xde, xde
	jrl z, PsParaListBoxProc_Return
	ld xwa, (xsp + 6)
	ld bc, (xwa + 34)
	mrdw3 0x98, 0x24, 0x49
	ld a, (xde)
	exts wa
	cp wa, bc
	jrl ge, PsParaListBoxProc_Return
	lda_dri XBC, 0xfd, 0x8e, 0x00
	ld xwa, xiz
	call GetClientBox
	lda_dri XBC, 0xfd, 0x8e, 0x00
	lda xwa, (xbc + 4)
	ld (xsp + 10), xwa
	ld de, (xwa)
	sub de, (xbc)
	exts xde
	ld xwa, (xsp + 6)
	mrdw3 0x98, 0x22, 0x5a
	ld (xsp + 4), de
	lda xiy, (xbc + 6)
	lda xix, (xbc + 2)
	ld hl, (xix)
	ld iz, (xiy)
	sub iz, hl
	ld de, (xwa + 36)
	exts xiz
	divs xiz, xde
	ld_sril XWA, (xsp + 0x009e)
	ld a, (xwa)
	exts wa
	exts xwa
	divs xwa, xde
	stw_erp WA, 0xe2
	ldw_erp WA, 0xea
	ld_sril XWA, (xsp + 0x009e)
	ld a, (xwa)
	exts wa
	exts xwa
	divs xwa, xde
	ld de, wa
	ld wa, iz
	mulw_erp WA, 0xea
	inc 2, wa
	add hl, wa
	ld (xix), hl
	add hl, iz
	ld (xiy), hl
	ld wa, (xsp + 4)
	mul xwa, xde
	inc 2, wa
	add (xbc), wa
	ld de, (xbc)
	add de, (xsp + 4)
	ld xwa, (xsp + 10)
	ld (xwa), de
	lda_dri XDE, 0xfd, 0x9a, 0x00
	ld wa, (xbc)
	ld (xde), wa
	ld wa, (xix)
	ld (xde + 2), wa
	ld_sril XWA, (xsp + 0x009e)
	inc 1, xwa
	push xwa
	lda xwa, (xsp + 18)
	push xwa
	call Strcpy
	inc 8, xsp
	ld xbc, (xsp + 6)
	ld xix, (xbc + 38)
	ld_sril XWA, (xsp + 0x009e)
	ld a, (xwa)
	ldb_erp A, 0xf4
	exts iy
	lda xde, (xsp + 14)
	lda xhl, (xbc + 28)
	lda_dri XBC, 0xfd, 0x9a, 0x00
	lda_dri XWA, 0xfd, 0x8e, 0x00
	cp iy, (xix)
	jr nz, SndArgGrid_CheckDispatch
	ld xhl, (xhl)
	push xhl
	pushw 0x0
	pushw 0xff
	jr SndArgGrid_CheckCase1

; SndArgGridCheck dispatch (7-entry, table 0xe1e36c)
SndArgGrid_CheckDispatch:
	ld xhl, (xhl)
	push xhl
	ld xhl, (xsp + 10)
	pushm (xhl + 32)
	pushm (xhl + 22)

; SndArgGridCheck case 1
SndArgGrid_CheckCase1:
	call DrawString
	jr PsParaListBoxProc_Return

; SndArgGridCheck case 2
SndArgGrid_CheckCase2:
	ld xwa, xiz
	call GetViewInstance
	ld xbc, (xhl + 38)
	ld_sril XWA, (xsp + 0x009e)
	ld (xbc), wa

PsParaListBoxProc_Return:
	ld xhl, 0:i3

; SndArgGridCheck case 3
SndArgGrid_CheckCase3:
	pop xiz
	lda_dri XSP, 0xfd, 0x9e, 0x00
	ret

StylCnvStorBnkSel:
	lda xsp, (xsp - 92)
	push xiz
	ld xhl, xde
	ld xde, xbc
	ld xiz, xwa
	ld xiy, SLOT_NAME_PTRS
	lda xix, (xsp + 4)
	ldw bc, 0x2e
	ldirw
	sub xde, 0x1e0003e
	cp xde, 0x0
	jr lt, PsSCTxtBox_EventDispatch
	cp xde, 0x9
	jr gt, PsSCTxtBox_EventDispatch
	add xde, xde
	add xde, MsgBox_AttentionHeader
	ld de, (xde)
	lda xix, (StylCnvStorBnkSel_DataBlock:24)
	jp_ind 8, 0x07, 0xf0, 0xe8

StylCnvStorBnkSel_DataBlock:
	ld	xwa, (xhl+14)
	sll	xwa, 2
	lda	xbc, (xsp+4)
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xhl+18)
	push	xwa
	call	Strcpy
	inc	8, xsp
	ld	xhl, xiz
	jr	19
	ld	xhl, 1:i3
	jr	15
	ld	xhl, 22
	jr	8
	.byte 0xf1
	.ascii "M:3h"
	push	sr

; PsSCTxtBoxProc event dispatch (10-entry, table 0xe1e4bc)
PsSCTxtBox_EventDispatch:
	ld xhl, 0:i3
	pop xiz
	lda xsp, (xsp + 92)
	ret
PsSCTxtBoxProc_Entry:

PsSCTxtBoxProc:
	lda_dri XSP, 0xfd, 0x00, 0xfe
	push xiz
	ld xiz, xwa
	cp xbc, 0x1c0000c
	jr z, SCTxtBox_HandleEvtBC
	cp xbc, 0x1c0000b
	jr z, SCTxtBox_HandleEvtBC
	cp xbc, 0x1c00002
	jr z, SCTxtBox_HandleEvt2
	cp xbc, 0x1c00001
	jr z, SCTxtBox_HandleEvt1
	ld xwa, xiz
	call InheritedProc
	jr SCTxtBox_Epilogue

SCTxtBox_HandleEvt1:
	ld xwa, xiz
	jr SCTxtBox_CallInherited

SCTxtBox_HandleEvt2:
	ld xwa, xiz

SCTxtBox_CallInherited:
	call InheritedProc
	jr SCTxtBox_SetReturnZero

SCTxtBox_HandleEvtBC:
	ld xwa, xiz
	call InheritedProc
	pushw 0x0
	pushw 0x3d68
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1c0000f
	call SendEvent

SCTxtBox_SetReturnZero:
	ld xhl, 0:i3

SCTxtBox_Epilogue:
	pop xiz
	lda_dri XSP, 0xfd, 0x00, 0x02
	ret
PsSCTxtBox2Proc_Entry:

PsSCTxtBox2Proc:
	lda_dri XSP, 0xfd, 0x00, 0xfe
	push xiz
	ld xiz, xwa
	cp xbc, 0x1c0000c
	jr z, SCTxtBox2_HandleEvtBC
	cp xbc, 0x1c0000b
	jr z, SCTxtBox2_HandleEvtBC
	cp xbc, 0x1e00089
	jr z, SCTxtBox2_HandleEvt89
	cp xbc, 0x1c00002
	jr z, SCTxtBox2_HandleEvt2
	cp xbc, 0x1c00001
	jr z, SCTxtBox2_HandleEvt1
	ld xwa, xiz
	call InheritedProc
	jr SCTxtBox2_Epilogue

SCTxtBox2_HandleEvt1:
	ld xwa, xiz
	jr SCTxtBox2_CallInherited

SCTxtBox2_HandleEvt2:
	ld xwa, xiz

SCTxtBox2_CallInherited:
	call InheritedProc
	jr SCTxtBox2_SetReturnZero

SCTxtBox2_HandleEvt89:
	lda xhl, (0x3d68:16)
	jr SCTxtBox2_Epilogue

SCTxtBox2_HandleEvtBC:
	ld xwa, xiz
	call InheritedProc
	pushw 0x0
	pushw 0x3d68
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1c0000f
	call SendEvent

SCTxtBox2_SetReturnZero:
	ld xhl, 0:i3

SCTxtBox2_Epilogue:
	pop xiz
	lda_dri XSP, 0xfd, 0x00, 0x02
	ret

StylCnvStorOkFunc:
	cp xbc, 0x1c00007
	jr nz, StylCnvStorOkFunc_ReturnZero
	ld xde, 0:i3
	ld e, (0x3a4d:16)
	ld xwa, 0x1440023
	ld xbc, 0x1e40030
	call MainFuncCall

StylCnvStorOkFunc_ReturnZero:
	ld xhl, 0:i3
	ret

StylCnvStorOkFunc_DataBlock:
	dec	8, xsp
	ld	xhl, xbc
	cpw	(xsp+12), 0
	jr	z, 29
	lda	xix, (xsp+4)
	ld	bc, (xwa+2)
	ld	(xix), bc
	ld	wa, (xwa)
	ld	(xix+2), wa
	lda	xbc, (xsp)
	ld	wa, (xhl+2)
	ld	(xbc), wa
	ld	wa, (xhl)
	ld	(xbc+2), wa
	ld	xwa, xix
	jr	2
	ld	xbc, xhl
	call	DrawLine
	inc	8, xsp
	retd	2
	lda	xsp, (xsp-30)
	push	xiz
	ld	(xsp+32), bc
	ld	bc, (xsp+38)
	cp	bc, 3:i3
	jr	z, 106
	cp	bc, 2:i3
	jr	z, 95
	cp	bc, 1:i3
	scc16	nz, bc
	ld	(xsp+8), bc
	ldw (xsp+10), 0
	ld	xiy, xwa
	lda	xix, (xsp+24)
	ld	bc, 4:i3
	ldirw
	lda	xhl, (xsp+24)
	ld	bc, (xhl+4)
	ld	wa, bc
	.byte 0x93
	xor	(xwa), xde
	ld	xwa, 0x12ee8ed8
	div	iz, 100
	lda	xwa, (xhl+6)
	ld	(xsp+12), xwa
	lda	xde, (xhl+2)
	ld	xwa, (xsp+12)
	ld	wa, (xwa)
	.byte 0x92, 0xa0, 0x9f
	pushw	wa
	ld	xwa, 0x12ec8cd8
	div	ix, 100
	ld	wa, bc
	.byte 0x93, 0xa0
	ld	(xsp+4), wa
	sub	(xsp+4), iz
	.byte 0x9f
	ld	(63:8), 0:io
	nop
	jr	z, 54
	ld	(xsp+20), bc
	ldw (xsp+6), 65535
	jr	54
	.byte 0xbf
	ld	(2:8), 1:io
	nop
	jr	5
	ldw (xsp+8), 0
	.byte 0xbf
	ldw	(2:8), 1:io
	lda	xhl, (xsp+24)
	ld	bc, (xwa+2)
	ld	(xhl), bc
	ld	bc, (xwa)
	ld	(xhl+2), bc
	ld	bc, (xwa+6)
	ld	(xhl+4), bc
	ld	wa, (xwa+4)
	ld	(xhl+6), wa
	jr	-118
	ld	wa, (xhl)
	ld	(xsp+20), wa
	.byte 0xbf
	ei	2
	.byte 0x01
	nop
	lda	xhl, (xsp+16)
	lda	xiy, (xsp+20)
	ld	wa, (xiy)
	ld	(xhl), wa
	ld	bc, (xde)
	ld	xwa, (xsp+12)
	ld	wa, (xwa)
	sub	wa, bc
	exts	xwa
	divs	wa, 2
	add	bc, wa
	srl	ix, 1
	ld	wa, ix
	add	wa, bc
	ld	(xiy+2), wa
	ld	bc, (xde)
	ld	xwa, (xsp+12)
	ld	wa, (xwa)
	sub	wa, bc
	exts	xwa
	divs	wa, 2
	add	bc, wa
	sub	bc, ix
	ld	(xhl+2), bc
	ldw	(xsp+14), 0
	cp	iz, 0:i3
	jr	ule, 32
	lda	xwa, (xsp+20)
	lda	xbc, (xsp+16)
	.byte 0x9f
	ldw	(4:8), 8863:io
	ld	b, 30:opc
	.byte 0xd3
	swi	6
	ld	wa, (xsp+6)
	add	(xsp+20), wa
	add	(xsp+16), wa
	incw	1, (xsp+14)
	cp	(xsp+14), iz
	jr	c, -32
	lda	xwa, (xsp+24)
	lda	xbc, (xsp+20)
	.byte 0x9f
	ld	(63:8), 0:io
	nop
	jr	z, 14
	ld	wa, (xwa+4)
	sub	wa, iz
	ld	(xbc), wa
	ldw (xsp+6), 65535
	jr	11
	ld	wa, (xwa)
	add	wa, iz
	ld	(xbc), wa
	.byte 0xbf
	ei	2
	.byte 0x01
	nop
	lda	xix, (xsp+16)
	lda	xhl, (xsp+20)
	ld	wa, (xhl)
	ld	(xix), wa
	lda	xde, (xsp+24)
	lda	xbc, (xde+2)
	ld	wa, (xbc)
	ld	(xhl+2), wa
	ld	bc, (xbc)
	ld	wa, (xde+6)
	sub	wa, bc
	exts	xwa
	divs	wa, 2
	add	bc, wa
	ld	(xix+2), bc
	ldw	(xsp+14), 0
	.byte 0x9f, 0x04
	push	xsp
	nop
	nop
	jr	ule, 32
	lda	xwa, (xsp+20)
	lda	xbc, (xsp+16)
	.byte 0x9f
	ldw	(4:8), 8863:io
	ld	b, 30:opc
	pop	xde
	swi	6
	ld	wa, (xsp+6)
	add	(xsp+16), wa
	incw	1, (xsp+14)
	ld	wa, (xsp+14)
	.byte 0x9f, 0x04, 0xf0
	jr	c, -32
	lda	xix, (xsp+16)
	lda	xhl, (xsp+20)
	ld	wa, (xhl)
	ld	(xix), wa
	lda	xde, (xsp+24)
	lda	xbc, (xde+6)
	ld	wa, (xbc)
	ld	(xhl+2), wa
	ld	bc, (xbc)
	ld	wa, bc
	.byte 0x9a
	push	sr
	or	(xwa), xwa
	zcf
	divs	wa, 2
	sub	bc, wa
	ld	(xix+2), bc
	ldw	(xsp+14), 0
	.byte 0x9f, 0x04
	push	xsp
	nop
	nop
	jr	ule, 32
	lda	xwa, (xsp+20)
	lda	xbc, (xsp+16)
	.byte 0x9f
	ldw	(4:8), 8863:io
	ld	b, 30:opc
	reti
	swi	6
	ld	wa, (xsp+6)
	add	(xsp+16), wa
	incw	1, (xsp+14)
	ld	wa, (xsp+14)
	.byte 0x9f, 0x04, 0xf0
	jr	c, -32
	pop	xiz
	lda	xsp, (xsp+30)
	retd	4
	lda	xsp, (xsp-32)
	push	xiz
	ld	(xsp+34), bc
	ld	bc, (xsp+40)
	cp	bc, 3:i3
	jr	z, 114
	cp	bc, 2:i3
	jr	z, 103
	cp	bc, 1:i3
	scc16	nz, bc
	ld	(xsp+6), bc
	ldw (xsp+8), 0
	ld	xiy, xwa
	lda	xix, (xsp+26)
	ld	bc, 4:i3
	ldirw
	lda	xhl, (xsp+26)
	lda	xix, (xhl+4)
	ld	bc, (xix)
	ld	wa, bc
	.byte 0x93
	xor	(xwa), xde
	ld	xwa, 0xe898fad7
	ccf
	div	wa, 100
	ld qiz, wa
	lda	xde, (xhl+6)
	lda	xiy, (xhl+2)
	ld	wa, (xde)
	.byte 0x95, 0xa0, 0x9f
	pushw	de
	ld	xwa, 0x12e88ed8
	div	wa, 100
	ld	iz, wa
	ld	wa, bc
	.byte 0x93, 0xa0
	ld	(xsp+4), wa
	ld wa, qiz
	sub	(xsp+4), wa
	.byte 0x9f, 0x06
	push	xsp
	nop
	nop
	jr	z, 57
	ld	(xsp+22), bc
	ld	wa, (xix)
	sub wa, qiz
	ld	(xsp+18), wa
	jr	57
	.byte 0xbf
	ei	2
	.byte 0x01
	nop
	jr	5
	ldw (xsp+6), 0
	.byte 0xbf
	ld	(2:8), 1:io
	nop
	lda	xhl, (xsp+26)
	ld	bc, (xwa+2)
	ld	(xhl), bc
	ld	bc, (xwa)
	ld	(xhl+2), bc
	ld	bc, (xwa+6)
	ld	(xhl+4), bc
	ld	wa, (xwa+4)
	ld	(xhl+6), wa
	jr	-126
	ld	wa, (xhl)
	ld	(xsp+22), wa
	ld	wa, (xhl)
	add wa, qiz
	ld	(xsp+18), wa
	ld	bc, (xiy)
	ld	wa, (xde)
	sub	wa, bc
	exts	xwa
	divs	wa, 2
	add	bc, wa
	ld	wa, iz
	srl	wa, 1
	sub	bc, wa
	lda	xwa, (xsp+22)
	ld	(xwa+2), bc
	lda	xde, (xsp+18)
	ld	(xde+2), bc
	lda	xiy, (xsp+22)
	lda	xix, (xsp+14)
	ldiw
	ldiw
	.byte 0x9f
	ld	(4:8), 234:io
	ld	d, (xbc-97)
	ld	b, 30:opc
	reti
	swi	5
	lda	xwa, (xsp+22)
	lda	xbc, (xsp+18)
	ld	de, (xbc)
	ld	(xwa), de
	ld	de, (xsp+28)
	ld	(xwa+2), de
	.byte 0x9f
	ld	(4:8), 159:io
	ld	d, 34:opc
	calr	64750
	lda	xwa, (xsp+22)
	ld	bc, (xsp+14)
	ld	(xwa), bc
	lda	xbc, (xsp+26)
	ld	de, (xbc+2)
	ld	bc, (xbc+6)
	sub	bc, de
	exts	xbc
	divs	bc, 2
	add	de, bc
	ld	bc, iz
	srl	bc, 1
	add	bc, de
	ld	(xwa+2), bc
	lda	xde, (xsp+18)
	ld	(xde+2), bc
	lda	xiy, (xsp+22)
	lda	xix, (xsp+10)
	ldiw
	ldiw
	.byte 0x9f
	ld	(4:8), 234:io
	ld	d, (xbc-97)
	ld	b, 30:opc
	.byte 0xae
	swi	4
	lda	xwa, (xsp+22)
	lda	xbc, (xsp+18)
	ld	de, (xbc)
	ld	(xwa), de
	ld	de, (xsp+32)
	ld	(xwa+2), de
	.byte 0x9f
	ld	(4:8), 159:io
	ld	d, 34:opc
	calr	64661
	lda	xiy, (xsp+14)
	lda	xix, (xsp+22)
	ldiw
	ldiw
	lda	xiy, (xsp+10)
	lda	xix, (xsp+18)
	ldiw
	ldiw
	lda	xwa, (xsp+22)
	lda	xbc, (xsp+18)
	.byte 0x9f
	ld	(4:8), 159:io
	ld	d, 34:opc
	calr	64626
	lda	xwa, (xsp+26)
	lda	xbc, (xsp+22)
	lda	xde, (xsp+18)
	.byte 0x9f, 0x06
	push	xsp
	nop
	nop
	jr	z, 17
	ld	wa, (xwa+4)
	sub wa, qiz
	ld	(xbc), wa
	.byte 0x9f, 0x04
	xor	(xwa), xwa
	jr	lt, -78
	.byte 0x50
	jr	14
	ld	wa, (xwa)
	add wa, qiz
	ld	(xbc), wa
	.byte 0x9f, 0x04
	xor	(xwa), w
	jr	ge, -78
	.byte 0x50
	lda	xwa, (xsp+22)
	lda	xhl, (xsp+26)
	lda	xde, (xhl+2)
	ld	bc, (xde)
	ld	(xwa+2), bc
	ld	de, (xde)
	ld	bc, (xhl+6)
	sub	bc, de
	exts	xbc
	divs	bc, 2
	add	de, bc
	lda	xbc, (xsp+18)
	ld	(xbc+2), de
	.byte 0x9f
	ld	(4:8), 159:io
	ld	d, 34:opc
	calr	64535
	lda	xwa, (xsp+22)
	lda	xhl, (xsp+26)
	lda	xde, (xhl+6)
	ld	bc, (xde)
	ld	(xwa+2), bc
	ld	de, (xde)
	ld	bc, de
	.byte 0x9b
	push	sr
	or	(xbc), xbc
	zcf
	divs	bc, 2
	sub	de, bc
	lda	xbc, (xsp+18)
	ld	(xbc+2), de
	.byte 0x9f
	ld	(4:8), 159:io
	ld	d, 34:opc
	calr	64491
	pop	xiz
	lda	xsp, (xsp+32)
	retd	4
StylCnvStorBnk_ProcDataBlock:
	lda	xsp, (xsp-16)
	push	xiz
	ld	(xsp+16), xwa
	cp	xbc, 0x01c0000b
	jr	z, 9
	ld	xwa, (xsp+16)
	call	InheritedProc
	jr	72
	ld	xwa, (xsp+16)
	call	InheritedProc
	ld	xwa, (xsp+16)
	call	GetViewInstance
	ld	xiz, xhl
	ld	(xsp+4), xiz
	lda	xbc, (xsp+8)
	ld	xwa, (xsp+16)
	call	GetClientBox
	lda	xwa, (xsp+8)
	lda	xhl, (xiz+26)
	ld	xbc, (xsp+4)
	lda	xix, (xbc+30)
	ld	de, (xbc+28)
	ld	bc, (xiz+22)
	.byte 0x9e
	push_f
	push	xsp
	nop
	nop
	jr	z, 9
	.byte 0x94, 0x04, 0x93, 0x04
	calr	64928
	jr	7
	.byte 0x94, 0x04, 0x93, 0x04
	calr	64441
	ld	xhl, 0:i3
	pop	xiz
	lda	xsp, (xsp+16)
	ret
CmpNameMenuBoxProc_Entry:

CmpNameMenuBoxProc:
	push xiz
	ld xiz, xwa
	cp xbc, 0x1c0000d
	jr z, CmpNameMenu_HandleEvtD
	ld xwa, xiz
	call InheritedProc
	jr CmpNameMenu_Epilogue

CmpNameMenu_HandleEvtD:
	cp (0x34d6:16), 12
	jr nc, CmpNameMenu_SetReturnZero
	ld xwa, xiz
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1c0000f
	ld xde, 0:i3
	call SendEvent

CmpNameMenu_SetReturnZero:
	ld xhl, 0:i3

CmpNameMenu_Epilogue:
	pop xiz
	ret

AttLangCheck:
	cp xbc, 0x1e0009f
	jr nz, AttLangCheck_ReturnZero
	lda xhl, (MSG_ATTENTION_ID_0xC:24)
	ret

AttLangCheck_ReturnZero:
	ld xhl, 0:i3
	ret

SureLangCheck:
	cp xbc, 0x1e0009f
	jr nz, SureLangCheck_ReturnZero
	lda xhl, (MSG_ARE_YOU_SURE_ID_0x1C:24)
	ret

SureLangCheck_ReturnZero:
	ld xhl, 0:i3
	ret

SndMemLangCheck:
	cp xbc, 0x1e0009f
	jr nz, SndMemLangCheck_ReturnZero
	lda xhl, (MSG_CUSTOM_SOUND_COPY_ID_0x8E:24)
	ret

SndMemLangCheck_ReturnZero:
	ld xhl, 0:i3
	ret

SndMem1LangCheck:
	cp xbc, 0x1e0009f
	jr nz, SndMem1LangCheck_ReturnZero
	lda xhl, (MSG_SOUND_GROUP_AFFECTED_ID_0x24:24)
	ret

SndMem1LangCheck_ReturnZero:
	ld xhl, 0:i3
	ret

MemfulLangCheck:
	cp xbc, 0x1e0009f
	jr nz, MemfulLangCheck_ReturnZero
	lda xhl, (MSG_CUSTOM_SOUND_FULL_ID_0x7C:24)
	ret

MemfulLangCheck_ReturnZero:
	ld xhl, 0:i3
	ret

Memful2LangCheck:
	cp xbc, 0x1e0009f
	jr nz, Memful2LangCheck_ReturnZero
	lda xhl, (MSG_CUSTOM_RHYTHMS_AFFECTED_ID_0x1E:24)
	ret

Memful2LangCheck_ReturnZero:
	ld xhl, 0:i3
	ret

StylCnvLangCheck:
	cp xbc, 0x1e0009f
	jr nz, StylCnvLangCheck_ReturnZero
	lda xhl, (MSG_INSERT_STYLE_CONVERT_ID_0x26:24)
	ret

StylCnvLangCheck_ReturnZero:
	ld xhl, 0:i3
	ret

SndArrLangCheck:
	cp xbc, 0x1e0009f
	jr nz, SndArrLangCheck_ReturnZero
	lda xhl, (Hama_ModeInit_Table:24)
	ret

SndArrLangCheck_ReturnZero:
	ld xhl, 0:i3
	ret
PsStylCnvVerProc_Entry:

PsStylCnvVerProc:
	lda_dri XSP, 0xfd, 0x00, 0xfe
	push xiz
	ld xiz, xwa
	cp xbc, 0x1c0000c
	jr z, StylCnvVer_HandleEvtBC
	cp xbc, 0x1c0000b
	jr z, StylCnvVer_HandleEvtBC
	cp xbc, 0x1e00089
	jr z, StylCnvVer_HandleEvt89
	cp xbc, 0x1c00002
	jr z, StylCnvVer_HandleEvt2
	cp xbc, 0x1c00001
	jr z, StylCnvVer_HandleEvt1
	ld xwa, xiz
	call InheritedProc
	jr StylCnvVer_Epilogue

StylCnvVer_HandleEvt1:
	ld xwa, xiz
	jr StylCnvVer_CallInherited

StylCnvVer_HandleEvt2:
	ld xwa, xiz

StylCnvVer_CallInherited:
	call InheritedProc
	jr StylCnvVer_SetReturnZero

StylCnvVer_HandleEvt89:
	lda xhl, (0x3f68:16)
	jr StylCnvVer_Epilogue

StylCnvVer_HandleEvtBC:
	ld xwa, xiz
	call InheritedProc
	pushw 0x0
	pushw 0x3f68
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1c0000f
	call SendEvent

StylCnvVer_SetReturnZero:
	ld xhl, 0:i3

StylCnvVer_Epilogue:
	pop xiz
	lda_dri XSP, 0xfd, 0x00, 0x02
	ret


.include "factory_test/test_init.s"
