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
	ldto_berp A, 0xfb
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
	ldto_berp A, 0xfb
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
	ldto_berp A, 0xfb
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
	ldto_berp A, 0xfb
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
	ldto_berp A, 0xfb
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
	push	qiz
	lda	xwa, (xsp+38)
	call	SeMenu_ReadObjData
	ld	wa, 0:i3
	ld	bc, 1:i3
	call	SeMenu_StorePartParam
	cp	(xsp+38), 0
	jr	nz, UpdSeSel_DetailedUpdate_Skip14
	ldw	wa, 33
	call	SeMenu_SetDisplayValue
	ld	wa, 1:i3
	jr	UpdSeSel_DetailedUpdate_Join
UpdSeSel_DetailedUpdate_Skip14:
	cp	(xsp+38), 1
	jr	nz, UpdSeSel_DetailedUpdate_Skip15
	lda	xwa, (xsp+2)
	call	SeMenu_FillObjTable
	ldib_erp 251, 1
UpdSeSel_DetailedUpdate_Loop:
	ldto_berp a, 251
	extz	wa
	ldto_berp e, 251
	dec 1, e
	extz	de
	lda	xbc, (xsp+2)
	ld	c, (xbc+de)
	extz bc
	call	SeMenu_StorePartParam
	inc1b_erp 251
	cp_erpb 251, 8
	jr ule, UpdSeSel_DetailedUpdate_Loop
	pushw 33
	ld	wa, 0:i3
	ldw	bc, 41
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	ld	wa, 2:i3
	jr	UpdSeSel_DetailedUpdate_Join
UpdSeSel_DetailedUpdate_Skip15:
	lda	xwa, (xsp+2)
	cp	(xsp+38), 2
	jr	nz, UpdSeSel_DetailedUpdate_Skip
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
UpdSeSel_DetailedUpdate_Join:
	call	SeMenu_SetCurrentStep
	jr	UpdSeSel_DetailedUpdate_Epilogue
UpdSeSel_DetailedUpdate_Skip:
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
UpdSeSel_DetailedUpdate_Epilogue:
	pop qiz
	lda	xsp, (xsp+38)
	ret
UpdSeSel_DetailedUpdate_SetDisplayState_Join:
	lda	xsp, (xsp-10)
	push	qiz
	lda	xwa, (xsp+10)
	call	SeMenu_ReadObjData
	cp	(xsp+10), 0
	jr	nz, UpdSeSel_DetailedUpdate_Skip16
	ldib_erp	250, 1
UpdSeSel_DetailedUpdate_Loop12:
	ldib_erp	251, 0
UpdSeSel_DetailedUpdate_Loop13:
	ldto_berp	a, 250
	extz	wa
	ld	c, 4:opc
	addb_erp c, 251
	pushw	39
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 251
	cpib_erp 251, 3
	jr c, UpdSeSel_DetailedUpdate_Loop13
	inc1b_erp 250
	cpib_erp 250, 4
	jr ule, UpdSeSel_DetailedUpdate_Loop12
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
	jrl	UpdSeSel_DetailedUpdate_Epilogue2
UpdSeSel_DetailedUpdate_Skip16:
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
	jr	ule, UpdSeSel_DetailedUpdate_Epilogue2
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
UpdSeSel_DetailedUpdate_Epilogue2:
	pop qiz
	lda	xsp, (xsp+10)
	ret
UpdSeSel_DetailedUpdate_SetDisplayState_Join2:
	lda	xsp, (xsp-10)
	push	qiz
	lda	xwa, (xsp+10)
	call	SeMenu_ReadObjData
	cp	(xsp+10), 0
	jr	nz, UpdSeSel_DetailedUpdate_Skip17
	lda	xwa, (xsp+2)
	call	SeMenu_ValidatePartNumber
	ldib_erp 251, 0
UpdSeSel_DetailedUpdate_Loop2:
	ld	a, (xsp+2)
	extz	wa
	ld	c, 7:opc
	addb_erp c, 251
	pushw	40
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 251
	cp_erpb 251, 10
	jr c, UpdSeSel_DetailedUpdate_Loop2
	ld	wa, 1:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_AdvanceSubIndex
	ld	wa, 0:i3
	ld	bc, 1:i3
	call	SeMenu_StorePartParam
	jr	UpdSeSel_DetailedUpdate_Epilogue3
UpdSeSel_DetailedUpdate_Skip17:
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
	jr	ule, UpdSeSel_DetailedUpdate_Epilogue3
	pushw	40
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	call	SeMenu_ApplyPartEdit_Helper7
	ld	wa, 1:i3
	call	SeMenu_SetupMenuDisplay
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_ResetSubIndex
UpdSeSel_DetailedUpdate_Epilogue3:
	pop qiz
	lda	xsp, (xsp+10)
	ret
UpdSeSel_DetailedUpdate_SetDisplayState_Join3:
	lda	xsp, (xsp-10)
	push	qiz
	lda	xwa, (xsp+10)
	call	SeMenu_ReadObjData
	cp	(xsp+10), 0
	jr	nz, UpdSeSel_DetailedUpdate_Skip18
	lda	xwa, (xsp+2)
	call	SeMenu_ValidatePartNumber
	ldib_erp 251, 0
UpdSeSel_DetailedUpdate_Loop3:
	ld	a, (xsp+2)
	extz	wa
	ld	c, 17:opc
	addb_erp c, 251
	pushw	41
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 251
	cpib_erp 251, 6
	jr c, UpdSeSel_DetailedUpdate_Loop3
	ld	wa, 1:i3
	call	SeMenu_SetCurrentStep
	jr	UpdSeSel_DetailedUpdate_Epilogue4
UpdSeSel_DetailedUpdate_Skip18:
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
	jr	ule, UpdSeSel_DetailedUpdate_Epilogue4
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
	call	SeMenu_DrawKeyScaleGraph
	ld	wa, 1:i3
	call	SeMenu_SetupMenuDisplay
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_ResetSubIndex
UpdSeSel_DetailedUpdate_Epilogue4:
	pop qiz
	lda	xsp, (xsp+10)
	ret
UpdSeSel_DetailedUpdate_SetDisplayState_Join4:
	ldw	wa, 42
	jr	UpdSeSel_DetailedUpdate_Join2
UpdSeSel_DetailedUpdate_Join2:
	lda	xsp, (xsp-14)
	push	qiz
	ld	(xsp+14), a
	cp	(xsp+14), 42
	jrl	nz, UpdSeSel_DetailedUpdate_Skip19
	ldib_erp 251, 1
UpdSeSel_DetailedUpdate_Join3:
	lda	xwa, (xsp+12)
	call	SeMenu_ReadObjData
	cp	(xsp+12), 0
	jrl	nz, UpdSeSel_DetailedUpdate_Skip20
	ldto_berp a, 251
	extz	wa
	lda	xbc, (xsp+4)
	call	SeMenu_TransferPartValues_EndData
	ldto_berp a, 251
	extz	wa
	ld	c, (xsp+4)
	extz	bc
	lda	xde, (xsp+2)
	call	SeMenu_TransferPartValues
	ldib_erp 250, 0
UpdSeSel_DetailedUpdate_Loop4:
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
	jr c, UpdSeSel_DetailedUpdate_Loop4
	ldto_berp a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_TransferPartValues_EndData_Helper2
	ldib_erp 250, 1
UpdSeSel_DetailedUpdate_Loop14:
	ldto_berp a, 250
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	ld	e, (xsp+14)
	extz	de
	pushw	de
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp	250
	cpib_erp	250, 4
	jr	ule, UpdSeSel_DetailedUpdate_Loop14
	ld	wa, 1:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_AdvanceSubIndex
	ld	c, (xsp+4)
	extz	bc
	ld	wa, 0:i3
	call	SeMenu_StorePartParam
	jr	UpdSeSel_DetailedUpdate_Epilogue5
UpdSeSel_DetailedUpdate_Skip19:
	cp	(xsp+14), 47
	jr	nz, UpdSeSel_DetailedUpdate_Entry
	ldib_erp 251, 0
	jrl	UpdSeSel_DetailedUpdate_Join3
UpdSeSel_DetailedUpdate_Entry:
	cp	(xsp+14), 57
	jr	nz, UpdSeSel_DetailedUpdate_Epilogue5
	ldib_erp 251, 2
	jrl	UpdSeSel_DetailedUpdate_Join3
UpdSeSel_DetailedUpdate_Skip20:
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
	jr	ule, UpdSeSel_DetailedUpdate_Epilogue5
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
UpdSeSel_DetailedUpdate_Epilogue5:
	pop qiz
	lda	xsp, (xsp+14)
	ret
UpdSeSel_DetailedUpdate_SetDisplayState_Join5:
	lda	xsp, (xsp-12)
	lda	xwa, (xsp+10)
	call	SeMenu_ReadObjData
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+10), 0
	jr	nz, UpdSeSel_DetailedUpdate_Skip21
	cp	(xsp), 0
	jr	nz, UpdSeSel_DetailedUpdate_Skip2
	calr	UpdSeSel_DetailedUpdate_Helper
	jr	UpdSeSel_DetailedUpdate_Join4
UpdSeSel_DetailedUpdate_Skip2:
	calr	UpdSeSel_DetailedUpdate_Helper2
UpdSeSel_DetailedUpdate_Join4:
	ld	wa, 1:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_AdvanceSubIndex
	lda	xwa, (xsp+4)
	call	SeMenu_ValidatePartNumber
	ld	c, (xsp+4)
	extz	bc
	ld	wa, 0:i3
	call	SeMenu_StorePartParam
	jrl	UpdSeSel_DetailedUpdate_Epilogue6
UpdSeSel_DetailedUpdate_Skip21:
	lda	xwa, (xsp+2)
	call	SeMenu_ReadObjParam
	lda	xwa, (xsp+6)
	call	SeMenu_FillEntryTable
	ld	a, (xsp+2)
	extz	wa
	ld	c, (xsp+6)
	extz	bc
	call	SeMenu_StorePartParam
	cp	(xsp), 0
	jr	nz, UpdSeSel_DetailedUpdate_Skip3
	call	SeMenu_AdvanceSubIndex
	cp	l, 12
	jr	ule, UpdSeSel_DetailedUpdate_Epilogue6
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
UpdSeSel_DetailedUpdate_Loop15:
	pushw	43
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	ld	wa, 1:i3
	call	SeMenu_SetupMenuDisplay
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_ResetSubIndex
	jr	UpdSeSel_DetailedUpdate_Epilogue6
UpdSeSel_DetailedUpdate_Skip3:
	call	SeMenu_AdvanceSubIndex
	cp	l, 4:i3
	jr	ugt, UpdSeSel_DetailedUpdate_Loop15
UpdSeSel_DetailedUpdate_Epilogue6:
	lda	xsp, (xsp+12)
	ret
UpdSeSel_DetailedUpdate_Helper:
	push	qiz
	ldib_erp	250, 0
UpdSeSel_DetailedUpdate_Helper_Loop:
	ldib_erp	251, 1
UpdSeSel_DetailedUpdate_Helper_Loop2:
	ldto_berp	a, 251
	extz	wa
	ld	c, 23:opc
	addb_erp c, 250
	pushw	43
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 251
	cpib_erp 251, 4
	jr ule, UpdSeSel_DetailedUpdate_Helper_Loop2
	inc1b_erp 250
	cpib_erp 250, 3
	jr c, UpdSeSel_DetailedUpdate_Helper_Loop
	pop qiz
	ret
UpdSeSel_DetailedUpdate_Helper2:
	push	qiz
	ldib_erp	250, 0
UpdSeSel_DetailedUpdate_Helper2_Loop:
	ldib_erp	251, 0
UpdSeSel_DetailedUpdate_Helper2_Loop2:
	ldto_berp	a, 251
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
	jr c, UpdSeSel_DetailedUpdate_Helper2_Loop2
	inc1b_erp 250
	cpib_erp 250, 2
	jr c, UpdSeSel_DetailedUpdate_Helper2_Loop
	pop qiz
	ret
UpdSeSel_DetailedUpdate_SetDisplayState_Join6:
	lda	xsp, (xsp-10)
	push	qiz
	lda	xwa, (xsp+10)
	call	SeMenu_ReadObjData
	cp	(xsp+10), 0
	jr	nz, UpdSeSel_DetailedUpdate_Helper2_Skip
	lda	xwa, (xsp+2)
	call	SeMenu_ValidatePartNumber
	ldib_erp 251, 0
UpdSeSel_DetailedUpdate_Loop5:
	ld	a, (xsp+2)
	extz	wa
	ld	c, 26:opc
	addb_erp c, 251
	pushw	44
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 251
	cpib_erp 251, 4
	jr c, UpdSeSel_DetailedUpdate_Loop5
	ld	wa, 1:i3
	call	SeMenu_SetCurrentStep
	jr	UpdSeSel_DetailedUpdate_Epilogue7
UpdSeSel_DetailedUpdate_Helper2_Skip:
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
	jr	ule, UpdSeSel_DetailedUpdate_Epilogue7
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
	call	SeMenu_DrawKeyScaleGraph
	ld	wa, 1:i3
	call	SeMenu_SetupMenuDisplay
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_ResetSubIndex
UpdSeSel_DetailedUpdate_Epilogue7:
	pop qiz
	lda	xsp, (xsp+10)
	ret
UpdSeSel_DetailedUpdate_SetDisplayState_Join7:
	lda	xsp, (xsp-10)
	lda	xwa, (xsp+8)
	call	SeMenu_ReadObjData
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+8), 0
	jr	nz, UpdSeSel_DetailedUpdate_Skip5
	cp	(xsp), 0
	jr	nz, UpdSeSel_DetailedUpdate_Skip4
	calr	UpdSeSel_DetailedUpdate_Helper3
	jr	UpdSeSel_DetailedUpdate_Join5
UpdSeSel_DetailedUpdate_Skip4:
	calr	UpdSeSel_DetailedUpdate_Helper4
UpdSeSel_DetailedUpdate_Join5:
	ld	wa, 1:i3
	call	SeMenu_SetCurrentStep
	jr	UpdSeSel_DetailedUpdate_Epilogue8
UpdSeSel_DetailedUpdate_Skip5:
	lda	xwa, (xsp+2)
	call	SeMenu_ReadObjParam
	lda	xwa, (xsp+4)
	call	SeMenu_FillEntryTable
	ld	a, (xsp+2)
	extz	wa
	ld	c, (xsp+4)
	extz	bc
	call	SeMenu_StorePartParam
	cp	(xsp), 0
	jr	nz, UpdSeSel_DetailedUpdate_Skip6
	call	SeMenu_AdvanceSubIndex
	cp	l, 6:i3
	jr	ugt, UpdSeSel_DetailedUpdate_Skip7
	jr	UpdSeSel_DetailedUpdate_Epilogue8
UpdSeSel_DetailedUpdate_Skip6:
	call	SeMenu_AdvanceSubIndex
	cp	l, 7:i3
	jr	ule, UpdSeSel_DetailedUpdate_Epilogue8
UpdSeSel_DetailedUpdate_Skip7:
	pushw	45
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	call	SeMenu_DrawAmpEnvGraph
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	ld	wa, 1:i3
	call	SeMenu_SetupMenuDisplay
	call	SeMenu_ResetSubIndex
UpdSeSel_DetailedUpdate_Epilogue8:
	lda	xsp, (xsp+10)
	ret
UpdSeSel_DetailedUpdate_Helper3:
	dec	2, xsp
	push	qiz
	lda	xwa, (xsp+2)
	call	SeMenu_ValidatePartNumber
	ldib_erp 251, 0
UpdSeSel_DetailedUpdate_Helper3_Loop:
	ld	a, (xsp+2)
	extz	wa
	ld	c, 39:opc
	addb_erp c, 251
	pushw	45
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 251
	cpib_erp 251, 7
	jr	c, UpdSeSel_DetailedUpdate_Helper3_Loop
	pop qiz
	inc	2, xsp
	ret
UpdSeSel_DetailedUpdate_Helper4:
	dec	2, xsp
	push	qiz
	lda	xwa, (xsp+2)
	call	SeMenu_ValidatePartNumber
	pushw	45
	ld	wa, 0:i3
	ldw	bc, 13
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type2
	ldib_erp 251, 0
UpdSeSel_DetailedUpdate_Helper4_Loop:
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
	jr	c, UpdSeSel_DetailedUpdate_Helper4_Loop
	pop qiz
	inc	2, xsp
	ret
UpdSeSel_DetailedUpdate_SetDisplayState_Join8:
	lda	xsp, (xsp-10)
	push	qiz
	lda	xwa, (xsp+10)
	call	SeMenu_ReadObjData
	cp	(xsp+10), 0
	jr	nz, UpdSeSel_DetailedUpdate_Helper4_Skip
	lda	xwa, (xsp+2)
	call	SeMenu_ValidatePartNumber
	ldib_erp 251, 0
UpdSeSel_DetailedUpdate_Loop6:
	ld	a, (xsp+2)
	extz	wa
	ld	c, 46:opc
	addb_erp c, 251
	pushw	46
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 251
	cp_erpb 251, 8
	jr c, UpdSeSel_DetailedUpdate_Loop6
	ld	wa, 1:i3
	call	SeMenu_SetCurrentStep
	jr	UpdSeSel_DetailedUpdate_Epilogue9
UpdSeSel_DetailedUpdate_Helper4_Skip:
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
	jr	ule, UpdSeSel_DetailedUpdate_Epilogue9
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
	call	SeMenu_DrawKeyScaleGraph
	ld	wa, 1:i3
	call	SeMenu_SetupMenuDisplay
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_ResetSubIndex
UpdSeSel_DetailedUpdate_Epilogue9:
	pop qiz
	lda	xsp, (xsp+10)
	ret
UpdSeSel_DetailedUpdate_SetDisplayState_Join9:
	ldw	wa, 47
	jrl	UpdSeSel_DetailedUpdate_Join2
UpdSeSel_DetailedUpdate_SetDisplayState_Join10:
	lda	xsp, (xsp-10)
	lda	xwa, (xsp+8)
	call	SeMenu_ReadObjData
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+8), 0
	jr	nz, UpdSeSel_DetailedUpdate_Skip9
	cp	(xsp), 0
	jr	nz, UpdSeSel_DetailedUpdate_Skip8
	calr	UpdSeSel_DetailedUpdate_Helper5
	jr	UpdSeSel_DetailedUpdate_Join6
UpdSeSel_DetailedUpdate_Skip8:
	calr	UpdSeSel_DetailedUpdate_Helper6
UpdSeSel_DetailedUpdate_Join6:
	ld	wa, 1:i3
	call	SeMenu_SetCurrentStep
	jr	UpdSeSel_DetailedUpdate_Epilogue10
UpdSeSel_DetailedUpdate_Skip9:
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
	jr	ule, UpdSeSel_DetailedUpdate_Epilogue10
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
UpdSeSel_DetailedUpdate_Epilogue10:
	lda	xsp, (xsp+10)
	ret
UpdSeSel_DetailedUpdate_Helper5:
	dec	4, xsp
	push	qiz
	ldib_erp	251, 0
UpdSeSel_DetailedUpdate_Helper5_Loop:
	ldto_berp	a, 251
	mul	a, 3
	add	a, 24
	ld	c, a
	pushw	59
	ld	wa, 0:i3
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 251
	cpib_erp 251, 6
	jr c, UpdSeSel_DetailedUpdate_Helper5_Loop
	lda	xwa, (xsp+4)
	call	UpdSeSel_DetailedUpdate_SetDisplayState_Helper
	ld	a, (xsp+4)
	extz	wa
	lda	xbc, (xsp+2)
	call	UpdSeSel_DetailedUpdate_SetDisplayState_Helper2
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
UpdSeSel_DetailedUpdate_Helper6:
	dec	4, xsp
	push	qiz
	ldib_erp	251, 0
UpdSeSel_DetailedUpdate_Helper6_Loop:
	ldto_berp	a, 251
	mul	a, 3
	add	a, 22
	ld	c, a
	pushw	59
	ld	wa, 3:i3
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type2
	inc1b_erp 251
	cpib_erp 251, 6
	jr c, UpdSeSel_DetailedUpdate_Helper6_Loop
	lda	xwa, (xsp+4)
	call	UpdSeSel_DetailedUpdate_SetDisplayState_Helper
	ld	a, (xsp+4)
	extz	wa
	lda	xbc, (xsp+2)
	call	UpdSeSel_DetailedUpdate_SetDisplayState_Helper3
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
UpdSeSel_DetailedUpdate_SetDisplayState_Join11:
	dec	6, xsp
	lda	xwa, (xsp+4)
	call	SeMenu_ReadObjData
	cp	(xsp+4), 0
	jr	nz, UpdSeSel_DetailedUpdate_Skip10
	pushw	60
	ld	wa, 0:i3
	ldw	bc, 16
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	ld	wa, 1:i3
	jr	UpdSeSel_DetailedUpdate_Join7
UpdSeSel_DetailedUpdate_Skip10:
	lda	xwa, (xsp)
	call	SeMenu_FillEntryTable
	ld c, (xsp+0:8)
	extz bc
	ld	wa, 0:i3
	call	SeMenu_StorePartParam
	pushw	60
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	ld	wa, 0:i3
UpdSeSel_DetailedUpdate_Join7:
	call	SeMenu_SetCurrentStep
	inc	6, xsp
	ret
UpdSeSel_DetailedUpdate_SetDisplayState_Join12:
	lda	xsp, (xsp-10)
	lda	xwa, (xsp+8)
	call	SeMenu_ReadObjData
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+8), 0
	jr	nz, UpdSeSel_DetailedUpdate_Skip12
	cp	(xsp), 0
	jr	nz, UpdSeSel_DetailedUpdate_Skip11
	calr	UpdSeSel_DetailedUpdate_Helper7
	jr	UpdSeSel_DetailedUpdate_Join8
UpdSeSel_DetailedUpdate_Skip11:
	calr	UpdSeSel_DetailedUpdate_Helper8
UpdSeSel_DetailedUpdate_Join8:
	ld	wa, 1:i3
	call	SeMenu_SetCurrentStep
	jr	UpdSeSel_DetailedUpdate_Epilogue11
UpdSeSel_DetailedUpdate_Skip12:
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
	jr	ule, UpdSeSel_DetailedUpdate_Epilogue11
	lda	xbc, (xsp+4)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	andmi8	(xsp+4), 7
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_ResetSubIndex
	lda	xbc, (xsp+4)
	ld	a, (xbc)
	cp	a, 1:i3
	jr	ule, UpdSeSel_DetailedUpdate_Helper6_Skip
	cp	a, 5:i3
	jr	ugt, UpdSeSel_DetailedUpdate_Helper6_Skip
	dec	1, a
	ld	(xbc), a
	add	a, 48
	extz	wa
	ld	bc, 0:i3
	jr	UpdSeSel_DetailedUpdate_Join9
UpdSeSel_DetailedUpdate_Helper6_Skip:
	cp	a, 0:i3
	jr	nz, UpdSeSel_DetailedUpdate_Skip13
	ldw	wa, 53
	ld	bc, 0:i3
UpdSeSel_DetailedUpdate_Join9:
	call	SeMenu_SendEvent
	jr	UpdSeSel_DetailedUpdate_Epilogue11
UpdSeSel_DetailedUpdate_Skip13:
	pushw	48
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	ld	wa, 0:i3
	ld	bc, 0:i3
	call	SeMenu_DrawFilterGraph
	call	Scoop_SoundEditorData_Helper10
	ld	wa, 1:i3
	call	SeMenu_SetupMenuDisplay
UpdSeSel_DetailedUpdate_Epilogue11:
	lda	xsp, (xsp+10)
	ret
UpdSeSel_DetailedUpdate_Helper7:
	dec	2, xsp
	push	qiz
	lda	xwa, (xsp+2)
	call	SeMenu_ValidatePartNumber
	ldib_erp 251, 0
UpdSeSel_DetailedUpdate_Loop7:
	ld	a, (xsp+2)
	extz	wa
	ld	c, 54:opc
	addb_erp c, 251
	pushw	48
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 251
	cpib_erp 251, 2
	jr c, UpdSeSel_DetailedUpdate_Loop7
	ldib_erp 251, 0
UpdSeSel_DetailedUpdate_Helper7_Loop:
	ld	a, (xsp+2)
	extz	wa
	ld	c, 77:opc
	addb_erp c, 251
	pushw	48
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 251
	cpib_erp 251, 4
	jr c, UpdSeSel_DetailedUpdate_Helper7_Loop
	pop qiz
	inc	2, xsp
	ret
UpdSeSel_DetailedUpdate_Helper8:
	dec	2, xsp
	push	qiz
	lda	xwa, (xsp+2)
	call	SeMenu_ValidatePartNumber
	ldib_erp 251, 0
UpdSeSel_DetailedUpdate_Loop8:
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
	jr c, UpdSeSel_DetailedUpdate_Loop8
	pop qiz
	inc	2, xsp
	ret
UpdSeSel_DetailedUpdate_SetDisplayState_Join13:
	pushw	49
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	ld	wa, 1:i3
	ld	bc, 0:i3
	call	SeMenu_DrawFilterGraph
	call	Scoop_SoundEditorData_Helper10
	ld	wa, 1:i3
	jp	SeMenu_SetupMenuDisplay
UpdSeSel_DetailedUpdate_SetDisplayState_Join14:
	pushw	50
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	ld	wa, 0:i3
	ld	bc, 1:i3
	call	SeMenu_DrawFilterGraph
	ld	wa, 1:i3
	jp	SeMenu_SetupMenuDisplay
UpdSeSel_DetailedUpdate_SetDisplayState_Join15:
	pushw	51
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	ld	wa, 1:i3
	ld	bc, 1:i3
	call	SeMenu_DrawFilterGraph
	ld	wa, 1:i3
	jp	SeMenu_SetupMenuDisplay
UpdSeSel_DetailedUpdate_SetDisplayState_Join16:
	pushw	52
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	call	SeMenu_DrawBandPassCurve
	ld	wa, 1:i3
	jp	SeMenu_SetupMenuDisplay
UpdSeSel_DetailedUpdate_SetDisplayState_Join17:
	pushw	53
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	ld	wa, 1:i3
	jp	SeMenu_SetupMenuDisplay
UpdSeSel_DetailedUpdate_SetDisplayState_Join18:
	lda	xsp, (xsp-10)
	push	qiz
	lda	xwa, (xsp+10)
	call	SeMenu_ReadObjData
	cp	(xsp+10), 0
	jr	nz, UpdSeSel_DetailedUpdate_Helper8_Skip
	lda	xwa, (xsp+2)
	call	SeMenu_ValidatePartNumber
	ldib_erp 251, 0
UpdSeSel_DetailedUpdate_Loop9:
	ld	a, (xsp+2)
	extz	wa
	ld	c, 57:opc
	addb_erp c, 251
	pushw	54
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 251
	cpib_erp 251, 4
	jr c, UpdSeSel_DetailedUpdate_Loop9
	ld	wa, 1:i3
	call	SeMenu_SetCurrentStep
	jr	UpdSeSel_DetailedUpdate_Epilogue12
UpdSeSel_DetailedUpdate_Helper8_Skip:
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
	jr	ule, UpdSeSel_DetailedUpdate_Epilogue12
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
	call	SeMenu_DrawKeyScaleGraph
	ld	wa, 1:i3
	call	SeMenu_SetupMenuDisplay
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_ResetSubIndex
UpdSeSel_DetailedUpdate_Epilogue12:
	pop qiz
	lda	xsp, (xsp+10)
	ret
UpdSeSel_DetailedUpdate_SetDisplayState_Join19:
	lda	xsp, (xsp-10)
	push	qiz
	lda	xwa, (xsp+10)
	call	SeMenu_ReadObjData
	cp	(xsp+10), 0
	jr	nz, UpdSeSel_DetailedUpdate_Helper8_Skip2
	lda	xwa, (xsp+2)
	call	SeMenu_ValidatePartNumber
	ldib_erp 251, 0
UpdSeSel_DetailedUpdate_Loop10:
	ld	a, (xsp+2)
	extz	wa
	ld	c, 61:opc
	addb_erp c, 251
	pushw	55
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 251
	cp_erpb 251, 10
	jr c, UpdSeSel_DetailedUpdate_Loop10
	ld	wa, 1:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_AdvanceSubIndex
	ld	wa, 0:i3
	ld	bc, 1:i3
	call	SeMenu_StorePartParam
	jr	UpdSeSel_DetailedUpdate_Epilogue13
UpdSeSel_DetailedUpdate_Helper8_Skip2:
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
	jr	ule, UpdSeSel_DetailedUpdate_Epilogue13
	pushw	55
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	call	SeMenu_ApplyPartEdit_Helper7
	ld	wa, 1:i3
	call	SeMenu_SetupMenuDisplay
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_ResetSubIndex
UpdSeSel_DetailedUpdate_Epilogue13:
	pop qiz
	lda	xsp, (xsp+10)
	ret
UpdSeSel_DetailedUpdate_SetDisplayState_Join20:
	lda	xsp, (xsp-10)
	push	qiz
	lda	xwa, (xsp+10)
	call	SeMenu_ReadObjData
	cp	(xsp+10), 0
	jr	nz, UpdSeSel_DetailedUpdate_Helper8_Skip3
	lda	xwa, (xsp+2)
	call	SeMenu_ValidatePartNumber
	ldib_erp 251, 0
UpdSeSel_DetailedUpdate_Loop11:
	ld	a, (xsp+2)
	extz	wa
	ld	c, 71:opc
	addb_erp c, 251
	pushw	56
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 251
	cpib_erp 251, 6
	jr c, UpdSeSel_DetailedUpdate_Loop11
	ld	wa, 1:i3
	call	SeMenu_SetCurrentStep
	jr	UpdSeSel_DetailedUpdate_Epilogue14
UpdSeSel_DetailedUpdate_Helper8_Skip3:
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
	jr	ule, UpdSeSel_DetailedUpdate_Epilogue14
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
	call	SeMenu_DrawKeyScaleGraph
	ld	wa, 1:i3
	call	SeMenu_SetupMenuDisplay
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_ResetSubIndex
UpdSeSel_DetailedUpdate_Epilogue14:
	pop qiz
	lda	xsp, (xsp+10)
	ret
UpdSeSel_DetailedUpdate_SetDisplayState_Join21:
	ldw	wa, 57
	jrl	UpdSeSel_DetailedUpdate_Join2

SeMenu_AltUpdate:
	lda xsp, (xsp - 38)
	pushw_erp 0xfa
	lda xwa, (xsp + 38)
	call SeMenu_ReadObjData
	cp (xsp + 38), 0x0
	jr nz, SeMenu_AltUpdate_Step1
	ldib_erp 0xfb, 1

SeMenu_AltUpdate_RegLoop:
	ldto_berp A, 0xfb
	extz wa
	pushw 0x22
	ldw bc, 0x17
	ld de, 1:i3
	call SeMenu_RegisterElement_Type1
	ldto_berp A, 0xfb
	extz wa
	pushw 0x22
	ld bc, 4:i3
	ld de, 1:i3
	call SeMenu_RegisterElement_Type1
	ldto_berp A, 0xfb
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
	push	qiz
	lda	xwa, (xsp+10)
	call	SeMenu_ReadObjData
	cp	(xsp+10), 0
	jr	nz, SeMenu_AltUpdate_Skip
	pushw	35
	ld	wa, 0:i3
	ldw	bc, 18
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	ldib_erp 251, 1
SeMenu_AltUpdate_Loop:
	ldto_berp a, 251
	extz	wa
	pushw	35
	ld	bc, 0:i3
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 251
	cpib_erp 251, 4
	jr ule, SeMenu_AltUpdate_Loop
	ldib_erp 251, 1
SeMenu_AltUpdate_Loop2:
	ldto_berp a, 251
	extz	wa
	pushw	35
	ld	bc, 1:i3
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 251
	cpib_erp 251, 4
	jr ule, SeMenu_AltUpdate_Loop2
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
	jr	SeMenu_AltUpdate_Epilogue
SeMenu_AltUpdate_Skip:
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
	jr	ule, SeMenu_AltUpdate_Epilogue
	ldib_erp 251, 1
SeMenu_AltUpdate_Loop3:
	ldto_berp a, 251
	extz	wa
	call	SeMenu_ApplyPartEdit
	inc1b_erp 251
	cpib_erp 251, 4
	jr ule, SeMenu_AltUpdate_Loop3
	pushw	35
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	ld	wa, 1:i3
	call	SeMenu_SetupMenuDisplay
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_ResetSubIndex
SeMenu_AltUpdate_Epilogue:
	pop qiz
	lda	xsp, (xsp+10)
	ret
SeMenu_AltUpdate_Step3Plus_Join:
	lda	xsp, (xsp-10)
	push	qiz
	lda	xwa, (xsp+10)
	call	SeMenu_ReadObjData
	cp	(xsp+10), 0
	jr	nz, SeMenu_AltUpdate_Skip2
	lda	xwa, (xsp+2)
	call	SeMenu_ValidatePartNumber
	ldib_erp 250, 0
SeMenu_AltUpdate_Loop5:
	ld	a, (xsp+2)
	extz	wa
	ld	c, 30:opc
	addb_erp c, 250
	pushw	36
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 250
	cpib_erp 250, 4
	jr c, SeMenu_AltUpdate_Loop5
	ldib_erp 251, 1
SeMenu_AltUpdate_Loop6:
	ldib_erp 250, 0
SeMenu_AltUpdate_Loop7:
	ldto_berp a, 251
	extz	wa
	ld	c, 30:opc
	addb_erp c, 250
	pushw	36
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp	250
	cpib_erp	250, 4
	jr	c, SeMenu_AltUpdate_Loop7
	inc1b_erp	251
	cpib_erp	251, 4
	jr	ule, SeMenu_AltUpdate_Loop6
	ld	wa, 1:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_AdvanceSubIndex
	ld	c, (xsp+2)
	extz	bc
	ld	wa, 0:i3
	call	SeMenu_StorePartParam
	jr	SeMenu_AltUpdate_Epilogue2
SeMenu_AltUpdate_Skip2:
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
	jr	ule, SeMenu_AltUpdate_Epilogue2
	pushw	36
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	ldib_erp 250, 1
SeMenu_AltUpdate_Loop8:
	ldto_berp c, 250
	extz	bc
	ldto_berp a, 250
	sll a, 2
	inc	1, a
	ld	e, a
	extz	de
	ld	wa, 0:i3
	call	SeMenu_DrawPartRangeGraph
	inc1b_erp 250
	cpib_erp 250, 4
	jr ule, SeMenu_AltUpdate_Loop8
	ld	wa, 1:i3
	call	SeMenu_SetupMenuDisplay
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_ResetSubIndex
SeMenu_AltUpdate_Epilogue2:
	pop qiz
	lda	xsp, (xsp+10)
	ret
SeMenu_AltUpdate_Step3Plus_Join2:
	lda	xsp, (xsp-10)
	push	qiz
	lda	xwa, (xsp+10)
	call	SeMenu_ReadObjData
	cp	(xsp+10), 0
	jr	nz, SeMenu_AltUpdate_Skip3
	lda	xwa, (xsp+2)
	call	SeMenu_ValidatePartNumber
	ldib_erp 250, 0
SeMenu_AltUpdate_Loop9:
	ld	a, (xsp+2)
	extz	wa
	ld	c, 34:opc
	addb_erp c, 250
	pushw	37
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 250
	cpib_erp 250, 4
	jr c, SeMenu_AltUpdate_Loop9
	ldib_erp 251, 1
SeMenu_AltUpdate_Loop10:
	ldib_erp 250, 0
SeMenu_AltUpdate_Loop11:
	ldto_berp a, 251
	extz	wa
	ld	c, 34:opc
	addb_erp c, 250
	pushw	37
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp	250
	cpib_erp	250, 4
	jr	c, SeMenu_AltUpdate_Loop11
	inc1b_erp	251
	cpib_erp	251, 4
	jr	ule, SeMenu_AltUpdate_Loop10
	ld	wa, 1:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_AdvanceSubIndex
	ld	c, (xsp+2)
	extz	bc
	ld	wa, 0:i3
	call	SeMenu_StorePartParam
	jr	SeMenu_AltUpdate_Epilogue3
SeMenu_AltUpdate_Skip3:
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
	jr	ule, SeMenu_AltUpdate_Epilogue3
	pushw	37
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	ldib_erp 250, 1
SeMenu_AltUpdate_Loop4:
	ldto_berp c, 250
	extz	bc
	ldto_berp a, 250
	sll a, 2
	inc	1, a
	ld	e, a
	extz	de
	ld	wa, 1:i3
	call	SeMenu_DrawPartRangeGraph
	inc1b_erp 250
	cpib_erp 250, 4
	jr ule, SeMenu_AltUpdate_Loop4
	ld	wa, 1:i3
	call	SeMenu_SetupMenuDisplay
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_ResetSubIndex
SeMenu_AltUpdate_Epilogue3:
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
	push	qiz
	lda	xwa, (xsp+2)
	call	SeMenu_HandleMenuChange_Data
	cp	(xsp+2), 1
	jr	nz, SeMenu_CopyWriteUpdate_Skip42
	ld	wa, 2:i3
	call	SeMenu_ClearNotification
	ld	wa, 0:i3
	call	SeMenu_CopyWriteUpdate_Step3_Helper14
	jrl	SeMenu_CopyWriteUpdate_Epilogue
SeMenu_CopyWriteUpdate_Skip42:
	lda	xwa, (xsp+24)
	call	SeMenu_ReadObjData
	cp	(xsp+24), 0
	jr	nz, SeMenu_CopyWriteUpdate_Skip43
	pushw	62
	ld	wa, 0:i3
	ld	bc, 0:i3
	ldw	de, 16
	call	SeMenu_RegisterElement_Type1
	ld	wa, 1:i3
	call	SeMenu_SetCurrentStep
	jrl	SeMenu_CopyWriteUpdate_Epilogue
SeMenu_CopyWriteUpdate_Skip43:
	lda	xwa, (xsp+6)
	call	SeMenu_FillEntryTable
	ldib_erp 251, 0
SeMenu_CopyWriteUpdate_Loop:
	ldto_berp a, 251
	extz	wa
	lda	xbc, (xsp+6)
	lda	xbc, (xbc+wa)
	ld xwa, xbc
	call	SeMenu_CopyWriteUpdate_Step3_Helper18
	inc1b_erp 251
	cp_erpb 251, 16
	jr	c, SeMenu_CopyWriteUpdate_Loop
	lda	xbc, (xsp+6)
	ld	wa, 1:i3
	ldw	de, 16
	call	SeMenu_SetupPartDisplay
	lda	xwa, (xsp+4)
	call	SeMenu_CopyWriteUpdate_Step3_Helper5
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
	call	SeMenu_ApplyPartEdit_Helper4_Helper
	ld	wa, 0:i3
	ldw	bc, 11
	ld	de, 0:i3
	call	SeMenu_SetupPartDisplay_End_Sub
	ld	wa, 1:i3
	ldw	bc, 12
	ld	de, 0:i3
	call	SeMenu_SetupPartDisplay_End_Sub
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	ldw	wa, 30
	ld	bc, 0:i3
	call	SeMenu_StorePartParam
	call	SeMenu_ResetSubIndex
SeMenu_CopyWriteUpdate_Epilogue:
	pop qiz
	lda	xsp, (xsp+24)
	ret
SeMenu_CopyWriteUpdate_Step3_Join:
	dec	2, xsp
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	ld	a, 13:opc
	cp	(xsp), 1
	jr	z, SeMenu_CopyWriteUpdate_Skip44
	ld	a, 16:opc
SeMenu_CopyWriteUpdate_Skip44:
	extz	wa
	call	SeMenu_CopyWriteUpdate_Step3_Helper17
	inc	2, xsp
	ret
SeMenu_CopyWriteUpdate_Step3_Join2:
	lda	xsp, (xsp-10)
	push	qiz
	lda	xwa, (xsp+10)
	call	SeMenu_ReadObjData
	cp	(xsp+10), 0
	jr	nz, SeMenu_CopyWriteUpdate_Skip45
	ld	wa, 1:i3
	call	SeMenu_SetDisplayState
	ldib_erp 251, 0
SeMenu_CopyWriteUpdate_Loop2:
	ld	c, 93:opc
	addb_erp c, 251
	pushw	58
	ld	wa, 0:i3
	ld	de, 1:i3
	call	SeMenu_RegisterElement_Type1
	inc1b_erp 251
	cp_erpb 251, 9
	jr c, SeMenu_CopyWriteUpdate_Loop2
	ld	wa, 1:i3
	call	SeMenu_SetCurrentStep
	jr	SeMenu_CopyWriteUpdate_Epilogue2
SeMenu_CopyWriteUpdate_Skip45:
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
	jr	ule, SeMenu_CopyWriteUpdate_Epilogue2
	lda	xbc, (xsp+2)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+2)
	and	a, 15
	cp	a, 11
	jr	ule, SeMenu_CopyWriteUpdate_Skip
	andmi8	(xsp+2), 240
	ld	c, (xsp+2)
	extz	bc
	ld	wa, 0:i3
	call	SeMenu_StorePartParam
SeMenu_CopyWriteUpdate_Skip:
	pushw	58
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	call	SeMenu_ResetSubIndex
	ld	wa, 0:i3
	call	SeMenu_SetDisplayState
SeMenu_CopyWriteUpdate_Epilogue2:
	pop qiz
	lda	xsp, (xsp+10)
	ret
SeMenu_CopyWriteUpdate_Step3_Join3:
	lda	xsp, (xsp-20)
	lda	xwa, (xsp+18)
	call	SeMenu_ReadObjData
	cp	(xsp+18), 0
	jr	nz, SeMenu_CopyWriteUpdate_Skip2
	pushw	61
	ld	wa, 0:i3
	ld	bc, 0:i3
	ldw	de, 13
	call	SeMenu_RegisterElement_Type2
	ld	wa, 1:i3
	jr	SeMenu_CopyWriteUpdate_Join
SeMenu_CopyWriteUpdate_Skip2:
	lda	xwa, (xsp)
	call	SeMenu_FillEntryTable
	lda	xbc, (xsp)
	ld	xwa, xbc
	lda	xde, (xbc+13)
SeMenu_CopyWriteUpdate_Entry:
	cp	(xwa), 127
	jr	ule, SeMenu_CopyWriteUpdate_Skip46
	ld	(xwa), 32
SeMenu_CopyWriteUpdate_Skip46:
	inc	1, xwa
	cp	xwa, xde
	jr	c, SeMenu_CopyWriteUpdate_Entry
	ld	wa, 1:i3
	ldw	de, 13
	call	SeMenu_SetupPartDisplay
	pushw	61
	call	SeMenu_ShowPopupDialog
	inc	2, xsp
	ld	wa, 0:i3
SeMenu_CopyWriteUpdate_Join:
	call	SeMenu_SetCurrentStep
	lda	xsp, (xsp+20)
	ret
SeMenu_CopyWriteUpdate_Step3_Join4:
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
SeMenu_CopyWriteUpdate_Step3_Return:
	ret
SeMenu_CopyWriteUpdate_Step3_Join5:
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
SeMenu_CopyWriteUpdate_Step3_Return2:
	ret
SeMenu_CopyWriteUpdate_Step3_Join6:
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
SeMenu_CopyWriteUpdate_Step3_Return3:
	ret
SeMenu_CopyWriteUpdate_Step3_Join7:
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
SeMenu_CopyWriteUpdate_Step3_Return4:
	ret
SeMenu_CopyWriteUpdate_Step3_Join8:
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
SeMenu_CopyWriteUpdate_Step3_Return5:
	ret
SeMenu_CopyWriteUpdate_Step3_Join9:
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
SeMenu_CopyWriteUpdate_Step3_Return6:
	ret
SeMenu_CopyWriteUpdate_Step3_Join10:
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
SeMenu_CopyWriteUpdate_Step3_Return7:
	ret
SeMenu_CopyWriteUpdate_Step3_Join11:
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
SeMenu_CopyWriteUpdate_Step3_Return8:
	ret
SeMenu_CopyWriteUpdate_Step3_Join12:
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
SeMenu_CopyWriteUpdate_Step3_Return9:
	ret
SeMenu_CopyWriteUpdate_Step3_Join13:
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
SeMenu_CopyWriteUpdate_Step3_Return10:
	ret
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
	ret
SeMenu_CopyWriteUpdate_Step3_Join14:
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
SeMenu_CopyWriteUpdate_Step3_Return11:
	ret
SeMenu_CopyWriteUpdate_Step3_Join15:
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
SeMenu_CopyWriteUpdate_Step3_Return12:
	ret
SeMenu_CopyWriteUpdate_Step3_Join16:
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
SeMenu_CopyWriteUpdate_Step3_Return13:
	ret
SeMenu_CopyWriteUpdate_Step3_Join17:
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
SeMenu_CopyWriteUpdate_Step3_Return14:
	ret
SeMenu_CopyWriteUpdate_Step3_Join18:
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
SeMenu_CopyWriteUpdate_Step3_Return15:
	ret
SeMenu_CopyWriteUpdate_Step3_Join19:
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
SeMenu_CopyWriteUpdate_Step3_Return16:
	ret
SeMenu_CopyWriteUpdate_Step3_Join20:
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
SeMenu_CopyWriteUpdate_Step3_Return17:
	ret
SeMenu_CopyWriteUpdate_Step3_Join21:
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
SeMenu_CopyWriteUpdate_Step3_Return18:
	ret
SeMenu_CopyWriteUpdate_Step3_Join22:
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
SeMenu_CopyWriteUpdate_Step3_Return19:
	ret
SeMenu_CopyWriteUpdate_Step3_Join23:
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
SeMenu_CopyWriteUpdate_Step3_Return20:
	ret
SeMenu_CopyWriteUpdate_Step3_Join24:
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
SeMenu_CopyWriteUpdate_Step3_Return21:
	ret
SeMenu_CopyWriteUpdate_Step3_Join25:
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
SeMenu_CopyWriteUpdate_Step3_Return22:
	ret
SeMenu_CopyWriteUpdate_Step3_Join26:
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
SeMenu_CopyWriteUpdate_Step3_Return23:
	ret
SeMenu_CopyWriteUpdate_Step3_Join27:
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
SeMenu_CopyWriteUpdate_Step3_Return24:
	ret
SeMenu_CopyWriteUpdate_Step3_Join28:
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
SeMenu_CopyWriteUpdate_Step3_Return25:
	ret
SeMenu_CopyWriteUpdate_Step3_Join29:
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
SeMenu_CopyWriteUpdate_Step3_Return26:
	ret
SeMenu_CopyWriteUpdate_Step3_Join30:
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
SeMenu_CopyWriteUpdate_Step3_Return27:
	ret
SeMenu_CopyWriteUpdate_Step3_Return28:
	ret
SeMenu_CopyWriteUpdate_Step3_Return29:
	ret
SeMenu_CopyWriteUpdate_Step3_Return30:
	ret
SeMenu_CopyWriteUpdate_Step3_Return31:
	ret
SeMenu_CopyWriteUpdate_Step3_Join31:
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
SeMenu_CopyWriteUpdate_Step3_Return32:
	ret
SeMenu_CopyWriteUpdate_Step3_Join32:
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
SeMenu_CopyWriteUpdate_Step3_Return33:
	ret
SeMenu_CopyWriteUpdate_Step3_Join33:
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	jp	SeMenu_ResetSubIndex
SeMenu_CopyWriteUpdate_Step3_Return34:
	ret
SeCtr2TitleFunc_DispatchSwitch:
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeTitle_DecodeSwitch
	cp	hl, 0xffff
	jr	z, SeMenu_CopyWriteUpdate_Epilogue3
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (SeCtr2TitleFunc_SwitchHandlers:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
SeMenu_CopyWriteUpdate_Epilogue3:
	inc	4, xsp
	ret
SeCtr3TitleFunc_DispatchSwitch:
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeTitle_DecodeSwitch
	cp	hl, 0xffff
	jr	z, SeMenu_CopyWriteUpdate_Epilogue4
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (SeCtr3TitleFunc_SwitchHandlers:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
SeMenu_CopyWriteUpdate_Epilogue4:
	inc	4, xsp
	ret
SeCtr2_OnColumn2:
	extz	wa
	ld	bc, 2:i3
	jp	SeMenu_ApplyPartEdit_AltStore_Join21
SeCtr2_OnColumn4:
	extz	wa
	jp	SeMenu_ApplyPartEdit_AltStore_Join22
SeCtr2_OnColumn5:
	ld	c, a
	extz	bc
	ld	wa, 1:i3
	jp	SeCtr2_OnPartColumn
SeCtr2_OnColumn6:
	ld	c, a
	extz	bc
	ld	wa, 2:i3
	jp	SeCtr2_OnPartColumn
SeCtr2_OnColumn7:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, SeMenu_CopyWriteUpdate_Epilogue42
	ld	c, (xsp+2)
	extz	bc
	ld	wa, 3:i3
	call	SeCtr2_OnPartColumn
SeMenu_CopyWriteUpdate_Epilogue42:
	inc	4, xsp
	ret
SeCtr2_OnColumn8:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, SeMenu_CopyWriteUpdate_Epilogue43
	ld	c, (xsp+2)
	extz	bc
	ld	wa, 4:i3
	call	SeCtr2_OnPartColumn
SeMenu_CopyWriteUpdate_Epilogue43:
	inc	4, xsp
	ret
SeCtr2_OnSideRow2:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xbc, (xsp)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	cp	(xsp+2), 0
	jr	nz, SeMenu_CopyWriteUpdate_Skip47
	cp	(xsp), 2
	jr	z, SeMenu_CopyWriteUpdate_Epilogue44
	ld	wa, 2:i3
	jr	SeMenu_CopyWriteUpdate_Join23
SeMenu_CopyWriteUpdate_Skip47:
	cp	(xsp), 1
	jr	z, SeMenu_CopyWriteUpdate_Epilogue44
	ld	wa, 1:i3
SeMenu_CopyWriteUpdate_Join23:
	call	SeMenu_CopyWriteUpdate_Step3_Helper4
	ldw	wa, 59
	ld	bc, 1:i3
	call	SeMenu_SendEvent
SeMenu_CopyWriteUpdate_Epilogue44:
	inc	4, xsp
	ret
SeCtr2_OnSideRow3:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xbc, (xsp)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	cp	(xsp+2), 0
	jr	nz, SeMenu_CopyWriteUpdate_Skip48
	cp	(xsp), 6
	jr	z, SeMenu_CopyWriteUpdate_Epilogue45
	ld	wa, 6:i3
	jr	SeMenu_CopyWriteUpdate_Join24
SeMenu_CopyWriteUpdate_Skip48:
	cp	(xsp), 5
	jr	z, SeMenu_CopyWriteUpdate_Epilogue45
	ld	wa, 5:i3
SeMenu_CopyWriteUpdate_Join24:
	call	SeMenu_CopyWriteUpdate_Step3_Helper4
	ldw	wa, 59
	ld	bc, 1:i3
	call	SeMenu_SendEvent
SeMenu_CopyWriteUpdate_Epilogue45:
	inc	4, xsp
	ret
SeCtr2_OnSwitch25:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, SeMenu_CopyWriteUpdate_Epilogue46
	cp	(xsp+2), 0
	jr	nz, SeMenu_CopyWriteUpdate_Epilogue46
	ldw	wa, 60
	ld	bc, 0:i3
	call	SeMenu_SendEvent
SeMenu_CopyWriteUpdate_Epilogue46:
	inc	4, xsp
	ret
SeCtr2_OnSwitch15:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, SeMenu_CopyWriteUpdate_Epilogue5
	cp	(xsp), 0
	jr	nz, SeMenu_CopyWriteUpdate_Skip3
	ldw	wa, 32
	ld	bc, 0:i3
	jr	SeMenu_CopyWriteUpdate_Join2
SeMenu_CopyWriteUpdate_Skip3:
	ldw	wa, 61
	ld	bc, 0:i3
SeMenu_CopyWriteUpdate_Join2:
	call	SeMenu_SendEvent
SeMenu_CopyWriteUpdate_Epilogue5:
	inc	4, xsp
	ret
SeCtr3_OnColumn3:
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
	call	SeMenu_SwitchToValueStep
	pushw	16
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 60
	ld	bc, 0:i3
	ld	de, 0:i3
	call	SeMenu_StepParamFieldAndSend
	ld	wa, 3:i3
	call	SeMenu_BindDialToColumn
	lda	xsp, (xsp+14)
	ret
SeCtr3_OnColumn6:
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
	call	SeMenu_SwitchToValueStep
	pushw	16
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 60
	ld	bc, 0:i3
	ld	de, 0:i3
	call	SeMenu_StepParamFieldAndSend
	ld	wa, 6:i3
	call	SeMenu_BindDialToColumn
	lda	xsp, (xsp+14)
	ret
SeCtr3_OnSwitch25:
	cp	a, 0:i3
	ret	z
	ldw	wa, 59
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
SeCtr3_OnSwitch15:
	cp	a, 0:i3
	ret	nz
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
SeMenuTitleFunc_DispatchSwitch:
	lda	xsp, (xsp-12)
	pushw	iz
	ld	(xsp+12), bc
	ld	iz, wa
	lda	xwa, (xsp+6)
	call	SeMenu_LoadPatchStatus
	cp	(xsp+6), 0
	jr	nz, SeMenu_CopyWriteUpdate_Skip4
	lda	xwa, (xsp+2)
	call	SeMenu_DisplayState_Data
	cp	(xsp+2), 0
	jr	nz, SeMenu_CopyWriteUpdate_Epilogue6
SeMenu_CopyWriteUpdate_Skip4:
	lda	xde, (xsp+10)
	lda	xwa, (xsp+8)
	push	xwa
	ld	wa, iz
	ld	bc, (xsp+16)
	call	SeTitle_DecodeSwitch
	cp	hl, 0xffff
	jr	z, SeMenu_CopyWriteUpdate_Epilogue6
	call	SeMenu_GetPartConfigBit3
	cp	l, 0:i3
	jr	z, SeMenu_CopyWriteUpdate_Skip5
	lda	xwa, (xsp+4)
	call	SeMenu_CopyWriteUpdate_Step3_Helper16
	ld	a, (xsp+10)
	.byte 0x8f, 0x04, 0xf1
	jr	nz, SeMenu_CopyWriteUpdate_Epilogue6
SeMenu_CopyWriteUpdate_Skip5:
	ld	a, (xsp+10)
	extz	wa
	call	SeMenu_CopyWriteUpdate_Step3_Helper15
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
SeMenu_CopyWriteUpdate_Epilogue6:
	popw	iz
	lda	xsp, (xsp+12)
	ret
	dec	6, xsp
	push	qiz
	ld	(xsp+6), a
	lda	xwa, (xsp+2)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	z, SeMenu_CopyWriteUpdate_Epilogue7
	lda	xwa, (xsp+2)
	call	SeMenu_LoadPatchStatus
	cp	(xsp+2), 1
	jr	z, SeMenu_CopyWriteUpdate_Epilogue7
	ld	a, (xsp+6)
	res	7, a
	ldfr_berp a, 251
	lda	xbc, (xsp+4)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+4)
	extz	wa
	call	SeMenu_IsPartEnabled
	ld	a, (xsp+4)
	extz	wa
	cp	hl, 0:i3
	jr	z, SeMenu_CopyWriteUpdate_Skip6
	cpib_erp 251, 0
	jr z, SeMenu_CopyWriteUpdate_Epilogue7
	ld bc, 0:i3
	jr SeMenu_CopyWriteUpdate_Join3
SeMenu_CopyWriteUpdate_Skip6:
	cpib_erp 251, 0
	jr nz, SeMenu_CopyWriteUpdate_Epilogue7
	ld	bc, 1:i3
SeMenu_CopyWriteUpdate_Join3:
	call	SeMenu_CopyWriteUpdate_Step3_Helper3
	pushw	2
	pushw	32
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
SeMenu_CopyWriteUpdate_Epilogue7:
	pop qiz
	inc	6, xsp
	ret
	lda	xsp, (xsp-12)
	ld	(xsp+10), a
	lda	xwa, (xsp+6)
	call	SeMenu_LoadObjEntries
	cp	(xsp+6), 0
	jr	z, SeMenu_CopyWriteUpdate_Epilogue8
	lda	xwa, (xsp+6)
	call	SeMenu_LoadPatchStatus
	cp	(xsp+6), 1
	jr	z, SeMenu_CopyWriteUpdate_Epilogue8
	lda	xbc, (xsp)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	c, (xsp)
	extz	bc
	lda	xde, (xsp+4)
	ld	wa, 3:i3
	call	SeMenu_CopyWriteUpdate_Step3_Helper11
	lda	xwa, (xsp+2)
	call	SeMenu_GetEntryCount
	ld	a, (xsp+10)
	res	7, a
	cp	a, 0:i3
	jr	nz, SeMenu_CopyWriteUpdate_Entry2
	ld	a, (xsp+2)
	dec	1, a
	cp	(xsp+4), a
	jr	nc, SeMenu_CopyWriteUpdate_Epilogue8
	incm8	1, (xsp+4)
	jr	SeMenu_CopyWriteUpdate_Join4
SeMenu_CopyWriteUpdate_Entry2:
	cp	(xsp+4), 0
	jr	z, SeMenu_CopyWriteUpdate_Epilogue8
	decm8	1, (xsp+4)
SeMenu_CopyWriteUpdate_Join4:
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
	call	SeMenu_BindDialToColumn
SeMenu_CopyWriteUpdate_Epilogue8:
	lda	xsp, (xsp+12)
	ret
	lda	xsp, (xsp-10)
	ld	(xsp+8), a
	lda	xwa, (xsp+6)
	call	SeMenu_LoadObjEntries
	cp	(xsp+6), 0
	jr	z, SeMenu_CopyWriteUpdate_Epilogue9
	lda	xwa, (xsp+6)
	call	SeMenu_LoadPatchStatus
	cp	(xsp+6), 1
	jr	z, SeMenu_CopyWriteUpdate_Epilogue9
	lda	xbc, (xsp+4)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+4)
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_CopyWriteUpdate_Step3_Helper8
	lda	xwa, (xsp)
	call	SeMenu_CopyWriteUpdate_Step3_Helper9
	ld	a, (xsp+8)
	res	7, a
	cp	a, 0:i3
	jr	nz, SeMenu_CopyWriteUpdate_Skip7
	ld	wa, (xsp)
	dec	1, wa
	cp	(xsp+2), wa
	jr	nc, SeMenu_CopyWriteUpdate_Epilogue9
	incw	1, (xsp+2)
	jr	SeMenu_CopyWriteUpdate_Join5
SeMenu_CopyWriteUpdate_Skip7:
	cpw	(xsp+2), 0
	jr	z, SeMenu_CopyWriteUpdate_Epilogue9
	decm	1, (xsp+2)
SeMenu_CopyWriteUpdate_Join5:
	ld	a, (xsp+4)
	extz	wa
	ld	bc, (xsp+2)
	call	SeMenu_RegisterParamDisplay_Data
	ld	a, (xsp+4)
	extz	wa
	ldw	bc, 16
	call	SeMenu_InitDisplayField
	ld	wa, 3:i3
	call	SeMenu_BindDialToColumn
SeMenu_CopyWriteUpdate_Epilogue9:
	lda	xsp, (xsp+10)
	ret
	lda	xsp, (xsp-18)
	push	qiz
	ld	(xsp+18), a
	lda	xwa, (xsp+14)
	call	SeMenu_LoadObjEntries
	cp	(xsp+14), 0
	jrl	z, SeMenu_CopyWriteUpdate_Epilogue47
	lda	xwa, (xsp+14)
	call	SeMenu_LoadPatchStatus
	cp	(xsp+14), 1
	jr	z, SeMenu_CopyWriteUpdate_Epilogue47
	lda	xbc, (xsp+16)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+16)
	inc	2, a
	ldfr_berp a, 251
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
	call	SeMenu_SwitchToValueStep
	ldto_berp c, 251
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
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 32
	ld	de, 0:i3
	call	SeMenu_StepParamFieldAndSend
	cp	l, 1:i3
	jr	nz, SeMenu_CopyWriteUpdate_Skip49
	ld	a, (xsp+16)
	extz	wa
	ld	c, (xsp+5)
	extz	bc
	call	SeMenu_StoreParamByte
SeMenu_CopyWriteUpdate_Skip49:
	ld	wa, 4:i3
	call	SeMenu_BindDialToColumn
SeMenu_CopyWriteUpdate_Epilogue47:
	pop qiz
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-18)
	push	qiz
	ld	(xsp+18), a
	lda	xwa, (xsp+14)
	call	SeMenu_LoadObjEntries
	cp	(xsp+14), 0
	jr	z, SeMenu_CopyWriteUpdate_Epilogue48
	lda	xwa, (xsp+14)
	call	SeMenu_LoadPatchStatus
	cp	(xsp+14), 1
	jr	z, SeMenu_CopyWriteUpdate_Epilogue48
	lda	xbc, (xsp+16)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+16)
	inc	4, a
	ldfr_berp a, 251
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
	call	SeMenu_SwitchToValueStep
	ldto_berp c, 251
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
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 32
	ld	de, 0:i3
	call	SeMenu_StepParamFieldAndSend
	ld	wa, 5:i3
	call	SeMenu_BindDialToColumn
SeMenu_CopyWriteUpdate_Epilogue48:
	pop qiz
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-18)
	push	qiz
	ld	(xsp+18), a
	lda	xwa, (xsp+14)
	call	SeMenu_LoadObjEntries
	cp	(xsp+14), 0
	jr	z, SeMenu_CopyWriteUpdate_Epilogue49
	lda	xwa, (xsp+14)
	call	SeMenu_LoadPatchStatus
	cp	(xsp+14), 1
	jr	z, SeMenu_CopyWriteUpdate_Epilogue49
	lda	xbc, (xsp+16)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+16)
	inc	6, a
	ldfr_berp a, 251
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
	call	SeMenu_SwitchToValueStep
	ldto_berp c, 251
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
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 32
	ld	de, 0:i3
	call	SeMenu_StepParamFieldAndSend
	ld	wa, 6:i3
	call	SeMenu_BindDialToColumn
SeMenu_CopyWriteUpdate_Epilogue49:
	pop qiz
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-10)
	push	qiz
	ld	(xsp+10), a
	lda	xwa, (xsp+4)
	call	SeMenu_LoadObjEntries
	cp	(xsp+4), 0
	jrl	z, SeMenu_CopyWriteUpdate_Epilogue10
	lda	xwa, (xsp+4)
	call	SeMenu_LoadPatchStatus
	cp	(xsp+4), 1
	jrl	z, SeMenu_CopyWriteUpdate_Epilogue10
	lda	xbc, (xsp+8)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+8)
	inc	8, a
	ldfr_berp a, 250
	ld	a, (xsp+10)
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_SwitchToValueStep
	ld	a, (xsp+10)
	res	7, a
	ldfr_berp a, 251
	ldto_berp a, 250
	extz	wa
	lda	xbc, (xsp+6)
	call	SeMenu_LoadPartParam
	resm	7, (xsp+6)
	cpib_erp	251, 0
	jr	nz, SeMenu_CopyWriteUpdate_Skip50
	cp	(xsp+6), 127
	jr	nc, SeMenu_CopyWriteUpdate_Epilogue10
	ld	a, (xsp+2)
	add	(xsp+6), a
	cp	(xsp+6), 127
	jr	c, SeMenu_CopyWriteUpdate_Skip8
	ld	(xsp+6), 127
	jr	SeMenu_CopyWriteUpdate_Skip8
SeMenu_CopyWriteUpdate_Skip50:
	cp	(xsp+6), 0
	jr	z, SeMenu_CopyWriteUpdate_Epilogue10
	ld	a, (xsp+6)
	add	a, (xsp+2)
	ld	(xsp+6), a
	cp	a, 0:i3
	jr	ge, SeMenu_CopyWriteUpdate_Skip8
	ld	(xsp+6), 0
SeMenu_CopyWriteUpdate_Skip8:
	ldto_berp a, 250
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
	ldfr_berp a, 250
	extz	wa
	pushw	wa
	pushw	32
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	ld	wa, 7:i3
	call	SeMenu_BindDialToColumn
SeMenu_CopyWriteUpdate_Epilogue10:
	pop qiz
	lda	xsp, (xsp+10)
	ret
	lda	xsp, (xsp-16)
	ld	(xsp+14), a
	lda	xwa, (xsp+12)
	call	SeMenu_LoadObjEntries
	cp	(xsp+12), 0
	jr	z, SeMenu_CopyWriteUpdate_Epilogue50
	lda	xwa, (xsp+12)
	call	SeMenu_LoadPatchStatus
	cp	(xsp+12), 1
	jr	z, SeMenu_CopyWriteUpdate_Epilogue50
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
	call	SeMenu_SwitchToValueStep
	pushw	15
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 32
	ldw	bc, 11
	ld	de, 0:i3
	call	SeMenu_StepParamFieldAndSend
	ldw	wa, 8
	call	SeMenu_BindDialToColumn
SeMenu_CopyWriteUpdate_Epilogue50:
	lda	xsp, (xsp+16)
	ret
	lda	xsp, (xsp-10)
	ld	(xsp+8), a
	lda	xwa, (xsp+2)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, SeMenu_CopyWriteUpdate_Skip10
	cp	(xsp+8), 0
	jr	nz, SeMenu_CopyWriteUpdate_Skip9
	lda	xbc, (xsp)
	ld	wa, 1:i3
	call	SeMenu_LoadPartParam
	cp	(xsp), 0
	scc8	z, a
	extz	wa
	call	SeMenu_CopyWriteUpdate_Step3_Helper2
	ldw	wa, 16
	call	SeMenu_RegisterParamDisplay
	jr	SeMenu_CopyWriteUpdate_Epilogue51
SeMenu_CopyWriteUpdate_Skip9:
	ld	wa, 0:i3
	call	SeMenu_CopyWriteUpdate_Step3_Helper14
	ldw	wa, 62
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	jr	SeMenu_CopyWriteUpdate_Epilogue51
SeMenu_CopyWriteUpdate_Skip10:
	lda	xwa, (xsp+2)
	call	SeMenu_LoadPatchStatus
	cp	(xsp+2), 1
	jr	z, SeMenu_CopyWriteUpdate_Epilogue51
	cp	(xsp+8), 0
	jr	nz, SeMenu_CopyWriteUpdate_Epilogue51
	lda	xwa, (xsp+6)
	call	SeMenu_CopyWriteUpdate_Step3_Helper12
	lda	xwa, (xsp+4)
	call	SeMenu_CopyWriteUpdate_Step3_Helper13
	ld	wa, (xsp+4)
	dec	1, wa
	cp	(xsp+6), wa
	jr	nc, SeMenu_CopyWriteUpdate_Epilogue51
	incw	1, (xsp+6)
	ld	wa, (xsp+6)
	call	SeMenu_SetupDisplayObject_Data
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	call	SeMenu_SetPartConfigBit3
SeMenu_CopyWriteUpdate_Epilogue51:
	lda	xsp, (xsp+10)
	ret
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 0
	jr	nz, SeMenu_CopyWriteUpdate_Skip11
	cp	(xsp+4), 0
	jr	nz, SeMenu_CopyWriteUpdate_Skip51
	ldw	wa, 33
	ld	bc, 0:i3
	jr	SeMenu_CopyWriteUpdate_Join25
SeMenu_CopyWriteUpdate_Skip51:
	ldw	wa, 34
	ld	bc, 0:i3
	jr	SeMenu_CopyWriteUpdate_Join25
SeMenu_CopyWriteUpdate_Skip11:
	lda	xwa, (xsp)
	call	SeMenu_LoadPatchStatus
	cp	(xsp), 1
	jr	nz, SeMenu_CopyWriteUpdate_Skip53
	cp	(xsp+4), 0
	jr	nz, SeMenu_CopyWriteUpdate_Skip52
	ld	wa, 0:i3
	call	SeMenu_SetPatchBank
	ldw	wa, 32
	ld	bc, 1:i3
SeMenu_CopyWriteUpdate_Join25:
	call	SeMenu_SendEvent
SeMenu_CopyWriteUpdate_Skip52:
	jr	SeMenu_CopyWriteUpdate_Epilogue11
SeMenu_CopyWriteUpdate_Skip53:
	cp	(xsp+4), 0
	jr	nz, SeMenu_CopyWriteUpdate_Epilogue11
	lda	xwa, (xsp+2)
	call	SeMenu_CopyWriteUpdate_Step3_Helper12
	cpw	(xsp+2), 0
	jr	z, SeMenu_CopyWriteUpdate_Epilogue11
	decm	1, (xsp+2)
	ld	wa, (xsp+2)
	call	SeMenu_SetupDisplayObject_Data
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	call	SeMenu_SetPartConfigBit3
SeMenu_CopyWriteUpdate_Epilogue11:
	inc	6, xsp
	ret
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp+2)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, SeMenu_CopyWriteUpdate_Skip12
	cp	(xsp+4), 0
	jr	nz, SeMenu_CopyWriteUpdate_Skip54
	ldw	wa, 36
	ld	bc, 0:i3
	jr	SeMenu_CopyWriteUpdate_Join26
SeMenu_CopyWriteUpdate_Skip54:
	ldw	wa, 43
	ld	bc, 0:i3
SeMenu_CopyWriteUpdate_Join26:
	call	SeMenu_SendEvent
	jr	SeMenu_CopyWriteUpdate_Epilogue52
SeMenu_CopyWriteUpdate_Skip12:
	lda	xwa, (xsp+2)
	call	SeMenu_LoadPatchStatus
	cp	(xsp+2), 1
	jr	nz, SeMenu_CopyWriteUpdate_Skip56
	cp	(xsp+4), 0
	jr	nz, SeMenu_CopyWriteUpdate_Skip55
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
	ld	wa, 0:i3
	call	SeMenu_SetPatchBank
	ld	wa, 2:i3
	call	SeMenu_ClearNotification
SeMenu_CopyWriteUpdate_Skip55:
	jr	SeMenu_CopyWriteUpdate_Epilogue52
SeMenu_CopyWriteUpdate_Skip56:
	cp	(xsp+4), 0
	jr	z, SeMenu_CopyWriteUpdate_Epilogue52
	lda	xbc, (xsp)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	cp	(xsp), 1
	jr	z, SeMenu_CopyWriteUpdate_Epilogue52
	ld	wa, 0:i3
	ld	bc, 1:i3
	call	SeMenu_StorePartParam
	ld	wa, 1:i3
	call	SeMenu_SetupMenuDisplay_Finalize_Data
	pushw	0
	pushw	32
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
SeMenu_CopyWriteUpdate_Epilogue52:
	inc	6, xsp
	ret
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp+2)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 0
	jr	nz, SeMenu_CopyWriteUpdate_Skip13
	cp	(xsp+4), 0
	jr	nz, SeMenu_CopyWriteUpdate_Skip57
	ldw	wa, 58
	ld	bc, 0:i3
	jr	SeMenu_CopyWriteUpdate_Join27
SeMenu_CopyWriteUpdate_Skip57:
	ldw	wa, 39
	ld	bc, 0:i3
SeMenu_CopyWriteUpdate_Join27:
	call	SeMenu_SendEvent
	jr	SeMenu_CopyWriteUpdate_Epilogue53
SeMenu_CopyWriteUpdate_Skip13:
	lda	xwa, (xsp+2)
	call	SeMenu_LoadPatchStatus
	cp	(xsp+2), 1
	jr	z, SeMenu_CopyWriteUpdate_Epilogue53
	cp	(xsp+4), 0
	jr	z, SeMenu_CopyWriteUpdate_Epilogue53
	lda	xbc, (xsp)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	cp	(xsp), 2
	jr	z, SeMenu_CopyWriteUpdate_Epilogue53
	ld	wa, 0:i3
	ld	bc, 2:i3
	call	SeMenu_StorePartParam
	ld	wa, 2:i3
	call	SeMenu_SetupMenuDisplay_Finalize_Data
	pushw	0
	pushw	32
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
SeMenu_CopyWriteUpdate_Epilogue53:
	inc	6, xsp
	ret
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp+2)
	call	SeMenu_LoadObjEntries
	lda	xwa, (xsp+2)
	cp	(xsp+4), 0
	jr	nz, SeMenu_CopyWriteUpdate_Skip84
	cp	(xsp+2), 0
	jr	nz, SeMenu_CopyWriteUpdate_Skip83
	ldw	wa, 59
	ld	bc, 0:i3
	jr	SeMenu_CopyWriteUpdate_Join41
SeMenu_CopyWriteUpdate_Skip83:
	call	SeMenu_LoadPatchStatus
	cp	(xsp+2), 1
	jr	z, SeMenu_CopyWriteUpdate_Epilogue12
	ldw	wa, 61
	call	SeMenu_CopyWriteUpdate_Step3_Helper6
	jr	SeMenu_CopyWriteUpdate_Epilogue12
SeMenu_CopyWriteUpdate_Skip84:
	cp	(xsp+2), 0
	jr	nz, SeMenu_CopyWriteUpdate_Skip85
	ldw	wa, 48
	ld	bc, 0:i3
SeMenu_CopyWriteUpdate_Join41:
	call	SeMenu_SendEvent
	jr	SeMenu_CopyWriteUpdate_Epilogue12
SeMenu_CopyWriteUpdate_Skip85:
	call	SeMenu_LoadPatchStatus
	cp	(xsp+2), 1
	jr	z, SeMenu_CopyWriteUpdate_Epilogue12
	call	SeMenu_GetPartConfigBit3
	cp	l, 0:i3
	jr	nz, SeMenu_CopyWriteUpdate_Epilogue12
	lda	xwa, (xsp)
	call	SeMenu_LoadMasterPtr
	ld	a, (xsp)
	extz	wa
	ld	bc, 0:i3
	ld	de, 1:i3
	call	SndParam_UpdateChannelTuning
	cp	l, 255
	jr	nz, SeMenu_CopyWriteUpdate_Skip14
	ld	a, (xsp)
	extz	wa
	ld	bc, 1:i3
	ld	de, 1:i3
	call	SndParam_UpdateChannelTuning
	cp	l, 255
	jr	z, SeMenu_CopyWriteUpdate_Epilogue12
SeMenu_CopyWriteUpdate_Skip14:
	ld	wa, 1:i3
	call	SeMenu_SetFilterMode
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ld	wa, 0:i3
	call	SeMenu_SetCurrentStep
SeMenu_CopyWriteUpdate_Epilogue12:
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
SeTonTon1TitleFunc_DispatchSwitch:
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeTitle_DecodeSwitch
	cp	hl, 0xffff
	jr	z, SeMenu_CopyWriteUpdate_Epilogue13
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (SeTonTon1TitleFunc_SwitchHandlers:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
SeMenu_CopyWriteUpdate_Epilogue13:
	inc	4, xsp
	ret
SeTonTon2TitleFunc_DispatchSwitch:
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeTitle_DecodeSwitch
	cp	hl, 0xffff
	jr	z, SeMenu_CopyWriteUpdate_Epilogue14
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (SeTonTon2TitleFunc_SwitchHandlers:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
SeMenu_CopyWriteUpdate_Epilogue14:
	inc	4, xsp
	ret
SeTonRan1TitleFunc_DispatchSwitch:
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeTitle_DecodeSwitch
	cp	hl, 0xffff
	jr	z, SeMenu_CopyWriteUpdate_Epilogue15
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (SeTonRan1TitleFunc_SwitchHandlers:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
SeMenu_CopyWriteUpdate_Epilogue15:
	inc	4, xsp
	ret
SeTonRan2TitleFunc_DispatchSwitch:
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeTitle_DecodeSwitch
	cp	hl, 0xffff
	jr	z, SeMenu_CopyWriteUpdate_Epilogue16
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (SeTonRan2TitleFunc_SwitchHandlers:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
SeMenu_CopyWriteUpdate_Epilogue16:
	inc	4, xsp
	ret
SeTonHyb1TitleFunc_DispatchSwitch:
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeTitle_DecodeSwitch
	cp	hl, 0xffff
	jr	z, SeMenu_CopyWriteUpdate_Epilogue17
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (SeTonHyb1TitleFunc_SwitchHandlers:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
SeMenu_CopyWriteUpdate_Epilogue17:
	inc	4, xsp
	ret
SeTonTon1_OnColumn1:
	dec	4, xsp
	push	qiz
	ld	(xsp+4), a
	lda	xbc, (xsp+2)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+4)
	res	7, a
	ldfr_berp a, 251
	ld	a, (xsp+2)
	extz	wa
	call	SeMenu_IsPartEnabled
	ld	a, (xsp+2)
	extz	wa
	cp	hl, 0:i3
	jr	z, SeMenu_CopyWriteUpdate_Skip15
	cpib_erp 251, 0
	jr z, SeMenu_CopyWriteUpdate_Epilogue18
	ld bc, 0:i3
	jr	SeMenu_CopyWriteUpdate_Join6
SeMenu_CopyWriteUpdate_Skip15:
	cpib_erp 251, 0
	jr nz, SeMenu_CopyWriteUpdate_Epilogue18
	ld	bc, 1:i3
SeMenu_CopyWriteUpdate_Join6:
	call	SeMenu_CopyWriteUpdate_Step3_Helper3
	pushw	1
	pushw	34
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	ld	wa, 1:i3
	call	SeMenu_SetupMenuDisplay
SeMenu_CopyWriteUpdate_Epilogue18:
	pop qiz
	inc	4, xsp
	ret
SeTonTon1_OnColumn2:
	lda	xsp, (xsp-10)
	ld	(xsp+8), a
	lda	xbc, (xsp+2)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	c, (xsp+2)
	extz	bc
	lda	xde, (xsp+6)
	ld	wa, 0:i3
	call	SeMenu_CopyWriteUpdate_Step3_Helper11
	lda	xwa, (xsp+4)
	call	SeMenu_GetEntryCount
	ld	a, (xsp+8)
	res	7, a
	cp	a, 0:i3
	jr	nz, SeMenu_CopyWriteUpdate_Entry3
	ld	a, (xsp+4)
	dec	1, a
	cp	(xsp+6), a
	jr	nc, SeMenu_CopyWriteUpdate_Epilogue19
	incm8	1, (xsp+6)
	jr	SeMenu_CopyWriteUpdate_Join7
SeMenu_CopyWriteUpdate_Entry3:
	cp	(xsp+6), 0
	jr	z, SeMenu_CopyWriteUpdate_Epilogue19
	decm8	1, (xsp+6)
SeMenu_CopyWriteUpdate_Join7:
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
	call	SeMenu_BindDialToColumn
SeMenu_CopyWriteUpdate_Epilogue19:
	lda	xsp, (xsp+10)
	ret
SeTonTon1_OnColumn3:
	dec	8, xsp
	ld	(xsp+6), a
	lda	xbc, (xsp+4)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+4)
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_CopyWriteUpdate_Step3_Helper8
	lda	xwa, (xsp)
	call	SeMenu_CopyWriteUpdate_Step3_Helper9
	ld	a, (xsp+6)
	res	7, a
	cp	a, 0:i3
	jr	nz, SeMenu_CopyWriteUpdate_Skip16
	ld	wa, (xsp)
	dec	1, wa
	cp	(xsp+2), wa
	jr	nc, SeMenu_CopyWriteUpdate_Epilogue20
	incw	1, (xsp+2)
	jr	SeMenu_CopyWriteUpdate_Join8
SeMenu_CopyWriteUpdate_Skip16:
	cpw	(xsp+2), 0
	jr	z, SeMenu_CopyWriteUpdate_Epilogue20
	decm	1, (xsp+2)
SeMenu_CopyWriteUpdate_Join8:
	ld	a, (xsp+4)
	extz	wa
	ld	bc, (xsp+2)
	call	SeMenu_RegisterParamDisplay_Data
	ld	a, (xsp+4)
	extz	wa
	ldw	bc, 16
	call	SeMenu_InitDisplayField
	ld	wa, 3:i3
	call	SeMenu_BindDialToColumn
SeMenu_CopyWriteUpdate_Epilogue20:
	inc	8, xsp
	ret
SeTonTon1_OnColumn6:
	lda	xsp, (xsp-16)
	push	qiz
	ld	(xsp+16), a
	lda	xbc, (xsp+14)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+14)
	mul	a, 3
	ldfr_berp a, 251
	dec1b_erp 251
	ldto_berp a, 251
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
	call	SeMenu_SwitchToValueStep
	ldto_berp c, 251
	extz	bc
	ld	e, (xsp+14)
	extz	de
	pushw	23
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 34
	call	SeMenu_StepParamFieldAndSend
	cp	l, 1:i3
	jr	nz, SeMenu_CopyWriteUpdate_Skip58
	ld	a, (xsp+14)
	extz	wa
	ld	c, (xsp+5)
	extz	bc
	call	SeMenu_StoreParamByte
SeMenu_CopyWriteUpdate_Skip58:
	ld	wa, 6:i3
	call	SeMenu_BindDialToColumn
	pop qiz
	lda	xsp, (xsp+16)
	ret
SeTonTon1_OnColumn7:
	lda	xsp, (xsp-16)
	push	qiz
	ld	(xsp+16), a
	lda	xbc, (xsp+14)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+14)
	mul	a, 3
	ldfr_berp a, 251
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
	call	SeMenu_SwitchToValueStep
	ldto_berp c, 251
	extz	bc
	ld	e, (xsp+14)
	extz	de
	pushw	4
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 34
	call	SeMenu_StepParamFieldAndSend
	ld	wa, 7:i3
	call	SeMenu_BindDialToColumn
	pop qiz
	lda	xsp, (xsp+16)
	ret
SeTonTon1_OnColumn8:
	lda	xsp, (xsp-16)
	push	qiz
	ld	(xsp+16), a
	lda	xbc, (xsp+14)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+14)
	mul	a, 3
	ldfr_berp a, 251
	inc1b_erp 251
	ldto_berp a, 251
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
	call	SeMenu_SwitchToValueStep
	ldto_berp c, 251
	extz	bc
	ld	e, (xsp+14)
	extz	de
	pushw	5
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 34
	call	SeMenu_StepParamFieldAndSend
	ldw	wa, 8
	call	SeMenu_BindDialToColumn
	pop qiz
	lda	xsp, (xsp+16)
	ret
SeTonTon1_OnSideRow1:
	cp	a, 0:i3
	ret	z
	call	SeMenu_ToggleSolo
	ret
SeTonTon1_OnSideRow2:
	cp	a, 0:i3
	ret	z
	ldw	wa, 34
	ld	bc, 1:i3
	ld	de, 0:i3
	call	SeMenu_SelectPartAndRedraw
	ret
SeTonTon1_OnSideRow3:
	cp	a, 0:i3
	ret	z
	ldw	wa, 34
	ld	bc, 2:i3
	ld	de, 0:i3
	call	SeMenu_SelectPartAndRedraw
	ret
SeTonTon1_OnSideRow4:
	cp	a, 0:i3
	ret	z
	ldw	wa, 34
	ld	bc, 3:i3
	ld	de, 0:i3
	call	SeMenu_SelectPartAndRedraw
	ret
SeTonTon1_OnSideRow5:
	cp	a, 0:i3
	ret	z
	ldw	wa, 34
	ld	bc, 4:i3
	ld	de, 0:i3
	call	SeMenu_SelectPartAndRedraw
	ret
SeTonTon1_OnSwitch25:
	cp	a, 0:i3
	ret	nz
	ldw	wa, 38
	call	SeMenu_CopyWriteUpdate_Step3_Helper6
	ret
SeTonTon1_OnSwitch15:
	cp	a, 0:i3
	ret	nz
	ldw	wa, 32
	call	SeMenu_CopyWriteUpdate_Step3_Helper6
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	ret
SeTonTon2_OnColumn2:
	dec	8, xsp
	push	qiz
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
	add	c, (xsp+6)
	dec	2, c
	extz	bc
	call	SeMenu_BitShiftMask_End
	ldfr_berp	l, 250
	and_erpb	250, 3
	ld	a, (xsp+8)
	res	7, a
	cp	a, 0:i3
	jr	nz, SeMenu_CopyWriteUpdate_Skip87
	bitm	7, (xsp+2)
	jrl	nz, SeMenu_CopyWriteUpdate_Epilogue54
	cpib_erp	250, 1
	jr	nz, SeMenu_CopyWriteUpdate_Skip86
	setm	7, (xsp+2)
	ldib_erp	250, 0
	jr	SeMenu_CopyWriteUpdate_Join28
SeMenu_CopyWriteUpdate_Skip86:
	inc1b_erp 250
	jr SeMenu_CopyWriteUpdate_Join28
SeMenu_CopyWriteUpdate_Skip87:
	bitm	7, (xsp+2)
	jr	z, SeMenu_CopyWriteUpdate_Skip59
	resm	7, (xsp+2)
	ldib_erp	250, 1
	jr	SeMenu_CopyWriteUpdate_Join28
SeMenu_CopyWriteUpdate_Skip59:
	cpib_erp 250, 0
	jrl z, SeMenu_CopyWriteUpdate_Epilogue54
	dec1b_erp	250
SeMenu_CopyWriteUpdate_Join28:
	ld	a, (xsp+6)
	add	a, (xsp+6)
	dec	2, a
	ld	c, a
	extz	bc
	ld	wa, 3:i3
	call	SeMenu_BitShiftMask
	ldfr_berp l, 251
	ldto_berp a, 251
	cpl	a
	and	(xsp+4), a
	ldto_berp a, 250
	extz	wa
	ld	c, (xsp+6)
	add	c, (xsp+6)
	dec	2, c
	extz	bc
	call	SeMenu_BitShiftMask
	or	(xsp+4), l
	ld	a, (xsp+6)
	extz	wa
	lda	xde, (xsp+2)
	pushw	128
	ld	bc, 0:i3
	call	SeMenu_RegisterElement_Extended
	lda	xde, (xsp+4)
	ldto_berp a, 251
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
	call	SeMenu_BindDialToColumn
SeMenu_CopyWriteUpdate_Epilogue54:
	pop qiz
	inc	8, xsp
	ret
SeTonTon2_OnColumn4:
	lda	xsp, (xsp-16)
	push	qiz
	ld	(xsp+16), a
	lda	xwa, (xsp+14)
	call	SeMenu_ValidatePartNumber
	ld	a, (xsp+14)
	inc	1, a
	ldfr_berp a, 251
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
	call	SeMenu_SwitchToValueStep
	ldto_berp c, 251
	extz	bc
	ld	e, (xsp+14)
	extz	de
	pushw	0
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 35
	call	SeMenu_StepParamFieldAndSend
	ld	wa, 4:i3
	call	SeMenu_BindDialToColumn
	pop qiz
	lda	xsp, (xsp+16)
	ret
SeTonTon2_OnColumn6:
	lda	xsp, (xsp-10)
	push	qiz
	ld	(xsp+10), a
	lda	xwa, (xsp+8)
	call	SeMenu_ValidatePartNumber
	ld	a, (xsp+8)
	inc	5, a
	ld	(xsp+2), a
	ld	a, (xsp+10)
	extz	wa
	lda	xbc, (xsp+4)
	call	SeMenu_SwitchToValueStep
	ld	a, (xsp+10)
	res	7, a
	ldfr_berp a, 251
	ld	a, (xsp+2)
	extz	wa
	lda	xbc, (xsp+6)
	call	SeMenu_LoadPartParam
	resm	7, (xsp+6)
	cpib_erp	251, 0
	jr	nz, SeMenu_CopyWriteUpdate_Skip60
	cp	(xsp+6), 127
	jr	nc, SeMenu_CopyWriteUpdate_Epilogue21
	ld	a, (xsp+4)
	add	(xsp+6), a
	cp	(xsp+6), 127
	jr	c, SeMenu_CopyWriteUpdate_Skip17
	ld	(xsp+6), 127
	jr	SeMenu_CopyWriteUpdate_Skip17
SeMenu_CopyWriteUpdate_Skip60:
	cp	(xsp+6), 0
	jr	z, SeMenu_CopyWriteUpdate_Epilogue21
	ld	a, (xsp+6)
	.byte 0x8f, 0x04, 0x81
	ld	(xsp+6), a
	cp	a, 0:i3
	jr	ge, SeMenu_CopyWriteUpdate_Skip17
	ld	(xsp+6), 0
SeMenu_CopyWriteUpdate_Skip17:
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
	call	SeMenu_BindDialToColumn
SeMenu_CopyWriteUpdate_Epilogue21:
	pop qiz
	lda	xsp, (xsp+10)
	ret
SeTonTon2_OnColumn7:
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
	call	SeMenu_SwitchToValueStep
	pushw	92
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 35
	ldw	bc, 10
	ld	de, 0:i3
	call	SeMenu_StepParamFieldAndSend
	ld	wa, 7:i3
	call	SeMenu_BindDialToColumn
	lda	xsp, (xsp+14)
	ret
SeTonTon2_OnSideRow1:
	cp	a, 0:i3
	ret	z
	call	SeMenu_ToggleSolo
	ret
SeTonTon2_OnSideRow2:
	cp	a, 0:i3
	ret	z
	ldw	wa, 35
	ld	bc, 1:i3
	ld	de, 1:i3
	call	SeMenu_SelectPartAndRedraw
	ret
SeTonTon2_OnSideRow3:
	cp	a, 0:i3
	ret	z
	ldw	wa, 35
	ld	bc, 2:i3
	ld	de, 1:i3
	call	SeMenu_SelectPartAndRedraw
	ret
SeTonTon2_OnSideRow4:
	cp	a, 0:i3
	ret	z
	ldw	wa, 35
	ld	bc, 3:i3
	ld	de, 1:i3
	call	SeMenu_SelectPartAndRedraw
	ret
SeTonTon2_OnSideRow5:
	cp	a, 0:i3
	ret	z
	ldw	wa, 35
	ld	bc, 4:i3
	ld	de, 1:i3
	call	SeMenu_SelectPartAndRedraw
	ret
SeTonTon2_OnSwitch25:
	cp	a, 0:i3
	ret	z
	ldw	wa, 38
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
SeTonTon2_OnSwitch15:
	cp	a, 0:i3
	ret	nz
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
SeTonRan1_OnColumn3:
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
	call	SeMenu_StepNoteParamInRange
	cp	l, 1:i3
	jr	nz, SeMenu_CopyWriteUpdate_Skip18
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
	call	SeMenu_DrawPartRangeGraph
SeMenu_CopyWriteUpdate_Skip18:
	ld	wa, 3:i3
	call	SeMenu_BindDialToColumn
	inc	8, xsp
	ret
SeTonRan1_OnColumn4:
	lda	xsp, (xsp-10)
	ld	(xsp+8), a
	lda	xbc, (xsp+6)
	ld	wa, 2:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+4)
	ld	wa, 3:i3
	call	SeMenu_LoadPartParam
	resm	7, (xsp+6)
	resm	7, (xsp+4)
	ld	a, (xsp+8)
	extz	wa
	ld	e, (xsp+6)
	extz	de
	ld	c, (xsp+4)
	extz	bc
	pushw	bc
	ld	bc, 1:i3
	call	SeMenu_StepNoteParamInRange
	cp	l, 1:i3
	jr	nz, SeMenu_CopyWriteUpdate_Skip19
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
	call	SeMenu_DrawPartRangeGraph
SeMenu_CopyWriteUpdate_Skip19:
	ld	wa, 4:i3
	call	SeMenu_BindDialToColumn
	lda	xsp, (xsp+10)
	ret
SeTonRan1_OnColumn5:
	lda	xsp, (xsp-10)
	ld	(xsp+8), a
	lda	xbc, (xsp+6)
	ld	wa, 1:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+4)
	ld	wa, 4:i3
	call	SeMenu_LoadPartParam
	resm	7, (xsp+6)
	resm	7, (xsp+4)
	ld	a, (xsp+8)
	extz	wa
	ld	e, (xsp+6)
	extz	de
	ld	c, (xsp+4)
	extz	bc
	pushw	bc
	ld	bc, 3:i3
	call	SeMenu_StepNoteParamInRange
	cp	l, 1:i3
	jr	nz, SeMenu_CopyWriteUpdate_Skip20
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
	call	SeMenu_DrawPartRangeGraph
SeMenu_CopyWriteUpdate_Skip20:
	ld	wa, 5:i3
	call	SeMenu_BindDialToColumn
	lda	xsp, (xsp+10)
	ret
SeTonRan1_OnColumn6:
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
	call	SeMenu_StepNoteParamInRange
	cp	l, 1:i3
	jr	nz, SeMenu_CopyWriteUpdate_Skip21
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
	call	SeMenu_DrawPartRangeGraph
SeMenu_CopyWriteUpdate_Skip21:
	ld	wa, 6:i3
	call	SeMenu_BindDialToColumn
	inc	8, xsp
	ret
SeTonRan1_OnSideRow1:
	cp	a, 0:i3
	ret	z
	call	SeMenu_ToggleSolo
	ret
SeTonRan1_OnSideRow2:
	cp	a, 0:i3
	ret	z
	ld	wa, 1:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	ret	z
	ldw	wa, 36
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
SeTonRan1_OnSideRow3:
	cp	a, 0:i3
	jr	nz, SeMenu_CopyWriteUpdate_Skip22
	ldw	wa, 37
	ld	bc, 0:i3
	jr	SeMenu_CopyWriteUpdate_Join9
SeMenu_CopyWriteUpdate_Skip22:
	ld	wa, 2:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	ret	z
	ldw	wa, 36
	ld	bc, 1:i3
SeMenu_CopyWriteUpdate_Join9:
	call	SeMenu_SendEvent
	ret
SeTonRan1_OnSideRow4:
	cp	a, 0:i3
	ret	z
	ld	wa, 3:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	ret	z
	ldw	wa, 36
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
SeTonRan1_OnSideRow5:
	cp	a, 0:i3
	ret	z
	ld	wa, 4:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	ret	z
	ldw	wa, 36
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
SeTonRan1_OnSwitch15:
	cp	a, 0:i3
	ret	nz
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
SeTonRan2_OnColumn3:
	lda	xsp, (xsp-18)
	ld	(xsp+16), a
	lda	xbc, (xsp+12)
	ld	wa, 1:i3
	call	SeMenu_LoadPartParam
	resm	7, (xsp+12)
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
	call	SeMenu_SwitchToValueStep
	ld	e, (xsp+14)
	extz	de
	pushw	35
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 37
	ld	bc, 2:i3
	call	SeMenu_StepParamFieldAndSend
	cp	l, 1:i3
	jr	nz, SeMenu_CopyWriteUpdate_Skip23
	ld	c, (xsp+14)
	extz	bc
	ld	wa, 1:i3
	ld	de, 1:i3
	call	SeMenu_DrawPartRangeGraph
SeMenu_CopyWriteUpdate_Skip23:
	ld	wa, 3:i3
	call	SeMenu_BindDialToColumn
	lda	xsp, (xsp+18)
	ret
SeTonRan2_OnColumn4:
	lda	xsp, (xsp-20)
	ld	(xsp+18), a
	lda	xbc, (xsp+14)
	ld	wa, 2:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+12)
	ld	wa, 3:i3
	call	SeMenu_LoadPartParam
	resm	7, (xsp+14)
	resm	7, (xsp+12)
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
	call	SeMenu_SwitchToValueStep
	ld	e, (xsp+16)
	extz	de
	pushw	34
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 37
	ld	bc, 1:i3
	call	SeMenu_StepParamFieldAndSend
	cp	l, 1:i3
	jr	nz, SeMenu_CopyWriteUpdate_Skip24
	ld	c, (xsp+16)
	extz	bc
	ld	wa, 1:i3
	ld	de, 1:i3
	call	SeMenu_DrawPartRangeGraph
SeMenu_CopyWriteUpdate_Skip24:
	ld	wa, 4:i3
	call	SeMenu_BindDialToColumn
	lda	xsp, (xsp+20)
	ret
SeTonRan2_OnColumn5:
	lda	xsp, (xsp-20)
	ld	(xsp+18), a
	lda	xbc, (xsp+14)
	ld	wa, 1:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp+12)
	ld	wa, 4:i3
	call	SeMenu_LoadPartParam
	resm	7, (xsp+14)
	resm	7, (xsp+12)
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
	call	SeMenu_SwitchToValueStep
	ld	e, (xsp+16)
	extz	de
	pushw	36
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 37
	ld	bc, 3:i3
	call	SeMenu_StepParamFieldAndSend
	cp	l, 1:i3
	jr	nz, SeMenu_CopyWriteUpdate_Skip25
	ld	c, (xsp+16)
	extz	bc
	ld	wa, 1:i3
	ld	de, 1:i3
	call	SeMenu_DrawPartRangeGraph
SeMenu_CopyWriteUpdate_Skip25:
	ld	wa, 5:i3
	call	SeMenu_BindDialToColumn
	lda	xsp, (xsp+20)
	ret
SeTonRan2_OnColumn6:
	lda	xsp, (xsp-18)
	ld	(xsp+16), a
	lda	xbc, (xsp+12)
	ld	wa, 3:i3
	call	SeMenu_LoadPartParam
	resm	7, (xsp+12)
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
	call	SeMenu_SwitchToValueStep
	ld	e, (xsp+14)
	extz	de
	pushw	37
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 37
	ld	bc, 4:i3
	call	SeMenu_StepParamFieldAndSend
	cp	l, 1:i3
	jr	nz, SeMenu_CopyWriteUpdate_Skip26
	ld	c, (xsp+14)
	extz	bc
	ld	wa, 1:i3
	ld	de, 1:i3
	call	SeMenu_DrawPartRangeGraph
SeMenu_CopyWriteUpdate_Skip26:
	ld	wa, 6:i3
	call	SeMenu_BindDialToColumn
	lda	xsp, (xsp+18)
	ret
SeTonRan2_OnSideRow1:
	cp	a, 0:i3
	ret	z
	call	SeMenu_ToggleSolo
	ret
SeTonRan2_OnSideRow2:
	cp	a, 0:i3
	jr	nz, SeMenu_CopyWriteUpdate_Skip27
	ldw	wa, 36
	ld	bc, 0:i3
	jr	SeMenu_CopyWriteUpdate_Join10
SeMenu_CopyWriteUpdate_Skip27:
	ld	wa, 1:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	ret	z
	ldw	wa, 37
	ld	bc, 1:i3
SeMenu_CopyWriteUpdate_Join10:
	call	SeMenu_SendEvent
	ret
SeTonRan2_OnSideRow3:
	cp	a, 0:i3
	ret	z
	ld	wa, 2:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	ret	z
	ldw	wa, 37
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
SeTonRan2_OnSideRow4:
	cp	a, 0:i3
	ret	z
	ld	wa, 3:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	ret	z
	ldw	wa, 37
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
SeTonRan2_OnSideRow5:
	cp	a, 0:i3
	ret	z
	ld	wa, 4:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	ret	z
	ldw	wa, 37
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
SeTonRan2_OnSwitch15:
	cp	a, 0:i3
	ret	nz
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
SeTonHyb1_OnColumn8:
	dec	4, xsp
	push	qiz
	ldfr_berp	a, 251
	res_erpb	251, 7
	lda	xbc, (xsp+4)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	cpib_erp 251, 0
	jr nz, SeMenu_CopyWriteUpdate_Skip61
	cp	(xsp+4), 1
	jr	z, SeMenu_CopyWriteUpdate_Epilogue55
	decm8	1, (xsp+4)
	ld	c, (xsp+4)
	extz	bc
	ld	wa, 0:i3
	jr	SeMenu_CopyWriteUpdate_Join29
SeMenu_CopyWriteUpdate_Skip61:
	cp	(xsp+4), 4
	jr	z, SeMenu_CopyWriteUpdate_Epilogue55
	ld	a, (xsp+4)
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	cp	(xsp+2), 127
	jr	z, SeMenu_CopyWriteUpdate_Epilogue55
	incm8	1, (xsp+4)
	ld	c, (xsp+4)
	extz	bc
	ld	wa, 0:i3
SeMenu_CopyWriteUpdate_Join29:
	call	SeMenu_StorePartParam
	pushw	0
	pushw	38
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
SeMenu_CopyWriteUpdate_Epilogue55:
	pop qiz
	inc	4, xsp
	ret
SeTonHyb1_OnColumn2:
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
	call	SeMenu_CopyWriteUpdate_Step3_Helper11
	lda	xwa, (xsp+6)
	call	SeMenu_GetEntryCount
	ld	a, (xsp+10)
	res	7, a
	cp	a, 0:i3
	jr	nz, SeMenu_CopyWriteUpdate_Entry4
	ld	a, (xsp+6)
	dec	1, a
	cp	(xsp+8), a
	jr	nc, SeMenu_CopyWriteUpdate_Epilogue22
	incm8	1, (xsp+8)
	jr	SeMenu_CopyWriteUpdate_Join11
SeMenu_CopyWriteUpdate_Entry4:
	cp	(xsp+8), 0
	jr	z, SeMenu_CopyWriteUpdate_Epilogue22
	decm8	1, (xsp+8)
SeMenu_CopyWriteUpdate_Join11:
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
	call	SeMenu_CopyWriteUpdate_Step3_Helper
	ld	a, (xsp+4)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	ldw	de, 16
	call	SeMenu_InitDisplayField_Alt
	ld	wa, 2:i3
	call	SeMenu_BindDialToColumn
SeMenu_CopyWriteUpdate_Epilogue22:
	lda	xsp, (xsp+12)
	ret
SeTonHyb1_OnColumn3:
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
	call	SeMenu_CopyWriteUpdate_Step3_Helper8
	lda	xwa, (xsp)
	call	SeMenu_CopyWriteUpdate_Step3_Helper9
	ld	a, (xsp+8)
	res	7, a
	cp	a, 0:i3
	jr	nz, SeMenu_CopyWriteUpdate_Skip28
	ld	wa, (xsp)
	dec	1, wa
	cp	(xsp+2), wa
	jr	nc, SeMenu_CopyWriteUpdate_Epilogue23
	incw	1, (xsp+2)
	jr	SeMenu_CopyWriteUpdate_Join12
SeMenu_CopyWriteUpdate_Skip28:
	cpw	(xsp+2), 0
	jr	z, SeMenu_CopyWriteUpdate_Epilogue23
	decm	1, (xsp+2)
SeMenu_CopyWriteUpdate_Join12:
	ld	a, (xsp+6)
	extz	wa
	ld	c, (xsp+4)
	extz	bc
	ld	de, (xsp+2)
	call	SeMenu_CopyWriteUpdate_Step3_Helper
	ld	a, (xsp+6)
	extz	wa
	ld	c, (xsp+4)
	extz	bc
	ldw	de, 16
	call	SeMenu_InitDisplayField_Alt
	ld	wa, 3:i3
	call	SeMenu_BindDialToColumn
SeMenu_CopyWriteUpdate_Epilogue23:
	lda	xsp, (xsp+10)
	ret
SeTonHyb1_OnColumn6:
	lda	xsp, (xsp-22)
	push	qiz
	ld	(xsp+22), a
	lda	xbc, (xsp+8)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	cp	(xsp+8), 4
	jrl	z, SeMenu_CopyWriteUpdate_Epilogue24
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
	add	a, (xsp+8)
	dec	1, a
	ldfr_berp	a, 226
	extz	wa
	lda	xde, (xsp+12)
	lda	xbc, (xde+wa)
	cp l, 0:i3
	jr	nz, SeMenu_CopyWriteUpdate_Skip29
	ld	xde, xbc
	ld	a, (xbc)
	cp	a, 127
	jrl	nc, SeMenu_CopyWriteUpdate_Epilogue24
	bitm	7, (xsp+22)
	jr	z, SeMenu_CopyWriteUpdate_Skip62
	inc	3, a
	jr	SeMenu_CopyWriteUpdate_Join13
SeMenu_CopyWriteUpdate_Skip62:
	inc	1, a
SeMenu_CopyWriteUpdate_Join13:
	ld	(xde), a
	cp	(xde), 127
	jr	c, SeMenu_CopyWriteUpdate_Join14
	ld	(xde), 127
	jr	SeMenu_CopyWriteUpdate_Join14
SeMenu_CopyWriteUpdate_Skip29:
	ld	xhl, xde
	ld	xde, xbc
	ld	w, (xsp+8)
	dec	1, w
	ld	a, (xbc)
	cp	a, w
	jrl	ule, SeMenu_CopyWriteUpdate_Epilogue24
	cp	a, 127
	jr	nz, SeMenu_CopyWriteUpdate_Skip88
	ldto_berp a, 226
	inc 2, a
	extz	wa
	ld	(xhl+wa), 0x7f
SeMenu_CopyWriteUpdate_Skip88:
	bit	7, (xsp+22)
	jr	z, SeMenu_CopyWriteUpdate_Skip90
	ld	a, (xde)
	cp	a, 3:i3
	jr	ugt, SeMenu_CopyWriteUpdate_Skip89
	ld	(xde), 0
	jr	SeMenu_CopyWriteUpdate_Join14
SeMenu_CopyWriteUpdate_Skip89:
	dec	3, a
	ld	(xde), a
	jr	SeMenu_CopyWriteUpdate_Join14
SeMenu_CopyWriteUpdate_Skip90:
	decm8	1, (xde)
SeMenu_CopyWriteUpdate_Join14:
	ldto_berp	a, 226
	extz	wa
	lda	xhl, (xsp+12)
	lda	xde, (xhl+wa)
	ld c, (xde)
	cp	c, 127
	jr	z, SeMenu_CopyWriteUpdate_Skip63
	ldto_berp a, 226
	inc 1, a
	ldfr_berp	a, 240
	extz	ix
	inc	1, c
	ld	(xhl+ix), c
SeMenu_CopyWriteUpdate_Skip63:
	ld	a, (xde)
	ld	(xsp+4), a
	ldib_erp	251, 0
SeMenu_CopyWriteUpdate_Loop4:
	ld	c, 0:opc
SeMenu_CopyWriteUpdate_Loop7:
	ld	a, c
	add	a, c
	inc	1, a
	extz	wa
	cp	(xhl+wa), 0x7f
	jr	nz, SeMenu_CopyWriteUpdate_Skip91
	inc	1, c
	ld	(xsp+2), c
	jr	SeMenu_CopyWriteUpdate_Join42
SeMenu_CopyWriteUpdate_Skip91:
	inc	1, c
	cp	c, 4:i3
	jr	c, SeMenu_CopyWriteUpdate_Loop7
SeMenu_CopyWriteUpdate_Join42:
	ldto_berp a, 251
	addb_erp a, 251
	ldfr_berp a, 226
	extz	wa
	lda	xiy, (xhl+wa)
	ld c, (xiy)
	ld	b, c
	ldto_berp a, 226
	inc 1, a
	extz	wa
	lda	xix, (xhl+wa)
	ld a, (xix)
	ldfr_berp a, 226
	ldto_berp w, 251
	inc	1, w
	cp	(xsp+8), w
	jr	ule, SeMenu_CopyWriteUpdate_Skip64
	ld	a, (xsp+8)
	sub	a, w
	ld	w, a
	ldto_berp	a, 226
	add	a, w
	cp	(xsp+4), a
	jr	nc, SeMenu_CopyWriteUpdate_Join30
	ld	a, (xsp+4)
	sub	a, w
	ldfr_berp	a, 226
	cp	a, c
	jr	nc, SeMenu_CopyWriteUpdate_Join30
	ldto_berp b, 226
	jr SeMenu_CopyWriteUpdate_Join30
SeMenu_CopyWriteUpdate_Skip64:
	cp (xsp+8), w
	jr nc, SeMenu_CopyWriteUpdate_Skip68
	cp	(xsp+2), w
	jr	c, SeMenu_CopyWriteUpdate_Skip65
	cp	(xsp+4), 127
	jr	nz, SeMenu_CopyWriteUpdate_Skip66
SeMenu_CopyWriteUpdate_Skip65:
	ld	b, 0:opc
	jr	SeMenu_CopyWriteUpdate_Join30
SeMenu_CopyWriteUpdate_Skip66:
	sub	w, (xsp+8)
	ld	a, (xsp+4)
	add	a, w
	cp	a, b
	jr	ule, SeMenu_CopyWriteUpdate_Skip67
	ld	b, a
SeMenu_CopyWriteUpdate_Skip67:
	ldto_berp	a, 226
	cp	a, b
	jr	nc, SeMenu_CopyWriteUpdate_Join30
	ldfr_berp	b, 226
	jr	SeMenu_CopyWriteUpdate_Join30
SeMenu_CopyWriteUpdate_Skip68:
	cp	(xsp+4), b
	jr	nc, SeMenu_CopyWriteUpdate_Join30
	ld	b, (xsp+4)
SeMenu_CopyWriteUpdate_Join30:
	ld	(xiy), b
	ldto_berp	a, 226
	ld	(xix), a
	inc1b_erp 251
	cpib_erp 251, 4
	jrl c, SeMenu_CopyWriteUpdate_Loop4
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
	cp	(xsp+10), 0
	jr	nz, SeMenu_CopyWriteUpdate_Skip69
	call	SeMenu_InitObjEntry
	ldib_erp	251, 1
SeMenu_CopyWriteUpdate_Loop5:
	ldto_berp	a, 251
	extz	wa
	lda	xbc, (xsp+4)
	call	SeMenu_LoadPartParam
	ld	a, (xsp+6)
	extz	wa
	ld	c, 0:opc
	addb_erp	c, 251
	dec	1, c
	lda	xde, (xsp+4)
	pushw	127
	call	SeMenu_RegisterElement_Extended
	inc1b_erp 251
	cpib_erp 251, 3
	jr ule, SeMenu_CopyWriteUpdate_Loop5
	jr	SeMenu_CopyWriteUpdate_Join31
SeMenu_CopyWriteUpdate_Skip69:
	call	SeMenu_ValidatePartNumber
	ldib_erp 251, 1
SeMenu_CopyWriteUpdate_Loop6:
	ldto_berp a, 251
	extz	wa
	lda	xbc, (xsp+4)
	call	SeMenu_LoadPartParam
	ld	a, (xsp+6)
	extz	wa
	ld	c, 0:opc
	addb_erp	c, 251
	dec	1, c
	lda	xde, (xsp+4)
	pushw	127
	call	SeMenu_SetupDisplayObject_Alt1
	inc1b_erp 251
	cpib_erp 251, 3
	jr ule, SeMenu_CopyWriteUpdate_Loop6
SeMenu_CopyWriteUpdate_Join31:
	pushw	1
	pushw	38
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	ld	wa, 6:i3
	call	SeMenu_BindDialToColumn
SeMenu_CopyWriteUpdate_Epilogue24:
	pop qiz
	lda	xsp, (xsp+22)
	ret
SeTonHyb1_OnSideRow1:
	cp	a, 0:i3
	ret	z
	call	SeMenu_ToggleSolo
	ret
SeTonHyb1_OnSideRow2:
	cp	a, 0:i3
	ret	z
	ld	wa, 1:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	ret	z
	ldw	wa, 38
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
SeTonHyb1_OnSideRow3:
	cp	a, 0:i3
	ret	z
	ld	wa, 2:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	ret	z
	ldw	wa, 38
	ld	bc, 1:i3
	call	SeMenu_SendEvent
	ret
SeTonHyb1_OnSideRow4:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, SeMenu_CopyWriteUpdate_Epilogue56
	cp	(xsp+2), 0
	jr	z, SeMenu_CopyWriteUpdate_Epilogue56
	ld	wa, 3:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	jr	z, SeMenu_CopyWriteUpdate_Epilogue56
	ldw	wa, 38
	ld	bc, 1:i3
	call	SeMenu_SendEvent
SeMenu_CopyWriteUpdate_Epilogue56:
	inc	4, xsp
	ret
SeTonHyb1_OnSideRow5:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, SeMenu_CopyWriteUpdate_Epilogue57
	cp	(xsp+2), 0
	jr	z, SeMenu_CopyWriteUpdate_Epilogue57
	ld	wa, 4:i3
	call	SeMenu_SelectPartIfEnabled
	cp	l, 0:i3
	jr	z, SeMenu_CopyWriteUpdate_Epilogue57
	ldw	wa, 38
	ld	bc, 1:i3
	call	SeMenu_SendEvent
SeMenu_CopyWriteUpdate_Epilogue57:
	inc	4, xsp
	ret
SeTonHyb1_OnSwitch25:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 1
	jr	z, SeMenu_CopyWriteUpdate_Epilogue58
	cp	(xsp+2), 0
	jr	nz, SeMenu_CopyWriteUpdate_Skip70
	ldw	wa, 35
	ld	bc, 0:i3
	jr	SeMenu_CopyWriteUpdate_Join32
SeMenu_CopyWriteUpdate_Skip70:
	ldw	wa, 34
	ld	bc, 0:i3
SeMenu_CopyWriteUpdate_Join32:
	call	SeMenu_SendEvent
SeMenu_CopyWriteUpdate_Epilogue58:
	inc	4, xsp
	ret
SeTonHyb1_OnSwitch15:
	dec	2, xsp
	cp	a, 0:i3
	jr	nz, SeMenu_CopyWriteUpdate_Epilogue25
	ld	wa, 0:i3
	call	SeMenu_SetupMenuDisplay
	lda	xwa, (xsp)
	call	SeMenu_LoadObjEntries
	cp	(xsp), 0
	jr	nz, SeMenu_CopyWriteUpdate_Skip30
	ldw	wa, 32
	ld	bc, 0:i3
	jr	SeMenu_CopyWriteUpdate_Join15
SeMenu_CopyWriteUpdate_Skip30:
	ldw	wa, 61
	ld	bc, 0:i3
SeMenu_CopyWriteUpdate_Join15:
	call	SeMenu_SendEvent
SeMenu_CopyWriteUpdate_Epilogue25:
	inc	2, xsp
	ret
SeEasyTitleFunc_DispatchSwitch:
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeTitle_DecodeSwitch
	cp	hl, 0xffff
	jr	z, SeMenu_CopyWriteUpdate_Epilogue26
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (SeEasyTitleFunc_SwitchHandlers:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
SeMenu_CopyWriteUpdate_Epilogue26:
	inc	4, xsp
	ret
SeCopyTitleFunc_DispatchSwitch:
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeTitle_DecodeSwitch
	cp	hl, 0xffff
	jr	z, SeMenu_CopyWriteUpdate_Epilogue27
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (SeCopyTitleFunc_SwitchHandlers:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
SeMenu_CopyWriteUpdate_Epilogue27:
	inc	4, xsp
	ret
SeWrtMemTitleFunc_DispatchSwitch:
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeTitle_DecodeSwitch
	cp	hl, 0xffff
	jr	z, SeMenu_CopyWriteUpdate_Epilogue28
	ld	a, (xsp)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	sla	bc, 2
	lda	xde, (SeWrtMemTitleFunc_SwitchHandlers:24)
	exts	xbc
	add	xbc, xde
	ld	xhl, (xbc)
	call	(xhl)
SeMenu_CopyWriteUpdate_Epilogue28:
	inc	4, xsp
	ret
Scoop_SoundEditorData_Helper12:
	dec	4, xsp
	lda	xde, (xsp+2)
	lda	xhl, (xsp)
	push	xhl
	call	SeTitle_DecodeSwitch
	cp	hl, 0xffff
	jr	z, SeMenu_CopyWriteUpdate_Epilogue29
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
SeMenu_CopyWriteUpdate_Epilogue29:
	inc	4, xsp
	ret
SeDigEffTitleFunc_DispatchSwitch:
	dec	8, xsp
	pushw	iz
	ld	(xsp+8), bc
	ld	iz, wa
	lda	xwa, (xsp+2)
	call	SeMenu_DisplayState_Data
	cp	(xsp+2), 0
	jr	nz, SeMenu_CopyWriteUpdate_Epilogue30
	lda	xde, (xsp+6)
	lda	xwa, (xsp+4)
	push	xwa
	ld	wa, iz
	ld	bc, (xsp+12)
	call	SeTitle_DecodeSwitch
	cp	hl, 0xffff
	jr	z, SeMenu_CopyWriteUpdate_Epilogue30
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
SeMenu_CopyWriteUpdate_Epilogue30:
	popw	iz
	inc	8, xsp
	ret
SeEasy_OnColumn4:
	lda	xsp, (xsp-20)
	push	qiz
	ld	(xsp+20), a
	lda	xbc, (xsp+18)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	cp	(xsp+18), 5
	jrl	z, SeMenu_CopyWriteUpdate_Skip72
	cp	(xsp+18), 8
	jrl	z, SeMenu_CopyWriteUpdate_Skip72
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_LoadPartParam
	lda	xde, (xsp+2)
	ld	(xde+6), 255
	ld	(xde+7), 0
	lda	xwa, (xde+8)
	lda	xbc, (xde+9)
	cp	(xsp+18), 2
	jr	nz, SeMenu_CopyWriteUpdate_Skip31
	ld	(xwa), 21
	ld	(xbc), 0
	jr	SeMenu_CopyWriteUpdate_Join16
SeMenu_CopyWriteUpdate_Skip31:
	ld	(xwa), 10
	ld	(xbc), 246
SeMenu_CopyWriteUpdate_Join16:
	ld	a, (xsp+20)
	extz	wa
	lda	xbc, (xde+10)
	call	SeMenu_SwitchToValueStep
	lda	xwa, (xsp+2)
	call	SeMenu_TransferPartValues_EndData_Helper
	cp	l, 1:i3
	jrl	nz, SeMenu_CopyWriteUpdate_Epilogue31
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
	cp	(xsp+18), 2
	jr	nz, SeMenu_CopyWriteUpdate_Skip32
	lda	xbc, (xsp+5)
	ld	a, (xbc)
	sub	a, 11
	ld	(xbc), a
SeMenu_CopyWriteUpdate_Skip32:
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xsp+5)
	call	SeMenu_InitDisplayColumn_Data
	cp	(xsp+18), 2
	jr	c, SeMenu_CopyWriteUpdate_Skip71
	cp	(xsp+18), 4
	jr	ugt, SeMenu_CopyWriteUpdate_Skip71
	ld	a, (xsp+18)
	dec	2, a
	extz	wa
	ld	c, (xsp+5)
	extz	bc
	call	SeMenu_StoreEffectCoeff
SeMenu_CopyWriteUpdate_Skip71:
	ld	wa, 4:i3
	jrl	SeMenu_CopyWriteUpdate_Join18
SeMenu_CopyWriteUpdate_Skip72:
	lda	xbc, (xsp+2)
	cp	(xsp+18), 5
	jr	nz, SeMenu_CopyWriteUpdate_Skip73
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
	call	SeMenu_SwitchToValueStep
	ld	c, (xsp+18)
	extz	bc
	pushw	41
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 33
	ld	de, 0:i3
	call	SeMenu_StepParamFieldAndSend
	ld	wa, 4:i3
	jrl	SeMenu_CopyWriteUpdate_Join18
SeMenu_CopyWriteUpdate_Skip73:
	cp	(xsp+18), 8
	jrl	nz, SeMenu_CopyWriteUpdate_Skip75
	ld	(xsp+18), 10
	ld	a, (xsp+20)
	res	7, a
	ldfr_berp a, 251
	ldw	wa, 10
	call	SeMenu_LoadPartParam
	lda	xwa, (xsp+2)
	ld	(xwa+6), 15
	ld	(xwa+7), 0
	ld	(xwa+8), 11
	ld	(xwa+9), 0
	lda	xwa, (xsp+14)
	call	SeMenu_LoadMasterPtr
	cpib_erp	251, 0
	jr	nz, SeMenu_CopyWriteUpdate_Skip76
	lda	xwa, (xsp+2)
	bitm	7, (xwa)
	jr	nz, SeMenu_CopyWriteUpdate_Skip74
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
	jr	SeMenu_CopyWriteUpdate_Join19
SeMenu_CopyWriteUpdate_Skip74:
	ld	(xwa+10), 1
	call	SeMenu_TransferPartValues_EndData_Helper
	cp	l, 1:i3
	jr	nz, SeMenu_CopyWriteUpdate_Epilogue31
SeMenu_CopyWriteUpdate_Loop3:
	ld	a, (xsp+5)
	ld	(xsp+16), a
SeMenu_CopyWriteUpdate_Join17:
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
SeMenu_CopyWriteUpdate_Join18:
	call	SeMenu_BindDialToColumn
SeMenu_CopyWriteUpdate_Skip75:
	jr	SeMenu_CopyWriteUpdate_Epilogue31
SeMenu_CopyWriteUpdate_Skip76:
	lda	xwa, (xsp+2)
	bitm	7, (xwa)
	jr	z, SeMenu_CopyWriteUpdate_Epilogue31
	ld	c, (xwa)
	and	c, 15
	jr	nz, SeMenu_CopyWriteUpdate_Skip33
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
SeMenu_CopyWriteUpdate_Join19:
	call	AddswbWr
	jr	SeMenu_CopyWriteUpdate_Join17
SeMenu_CopyWriteUpdate_Skip33:
	ld	(xwa+10), 255
	call	SeMenu_TransferPartValues_EndData_Helper
	cp	l, 1:i3
	jr	z, SeMenu_CopyWriteUpdate_Loop3
SeMenu_CopyWriteUpdate_Epilogue31:
	pop qiz
	lda	xsp, (xsp+20)
	ret
SeEasy_OnSideRow1:
	cp	a, 0:i3
	ret	z
	ld	wa, 0:i3
	call	SeMenu_CopyWriteUpdate_Step3_Helper14
	ldw	wa, 62
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
SeEasy_OnSideRow2:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xbc, (xsp)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	cp	(xsp+2), 0
	jr	nz, SeMenu_CopyWriteUpdate_Skip77
	cp	(xsp), 5
	jr	z, SeMenu_CopyWriteUpdate_Epilogue59
	ld	wa, 0:i3
	ld	bc, 5:i3
	jr	SeMenu_CopyWriteUpdate_Join33
SeMenu_CopyWriteUpdate_Skip77:
	cp	(xsp), 1
	jr	z, SeMenu_CopyWriteUpdate_Epilogue59
	ld	wa, 0:i3
	ld	bc, 1:i3
SeMenu_CopyWriteUpdate_Join33:
	call	SeMenu_StorePartParam
	pushw	0
	pushw	33
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
SeMenu_CopyWriteUpdate_Epilogue59:
	inc	4, xsp
	ret
SeEasy_OnSideRow3:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xbc, (xsp)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	cp	(xsp+2), 0
	jr	nz, SeMenu_CopyWriteUpdate_Entry5
	cp	(xsp), 6
	jr	z, SeMenu_CopyWriteUpdate_Epilogue32
	ld	wa, 0:i3
	ld	bc, 6:i3
	jr	SeMenu_CopyWriteUpdate_Join20
SeMenu_CopyWriteUpdate_Entry5:
	cp	(xsp), 2
	jr	z, SeMenu_CopyWriteUpdate_Epilogue32
	ld	wa, 0:i3
	ld	bc, 2:i3
SeMenu_CopyWriteUpdate_Join20:
	call	SeMenu_StorePartParam
	pushw	0
	pushw	33
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
SeMenu_CopyWriteUpdate_Epilogue32:
	inc	4, xsp
	ret
SeEasy_OnSideRow4:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xbc, (xsp)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	cp	(xsp+2), 0
	jr	nz, SeMenu_CopyWriteUpdate_Skip78
	cp	(xsp), 7
	jr	z, SeMenu_CopyWriteUpdate_Epilogue60
	ld	wa, 0:i3
	ld	bc, 7:i3
	jr	SeMenu_CopyWriteUpdate_Join34
SeMenu_CopyWriteUpdate_Skip78:
	cp	(xsp), 3
	jr	z, SeMenu_CopyWriteUpdate_Epilogue60
	ld	wa, 0:i3
	ld	bc, 3:i3
SeMenu_CopyWriteUpdate_Join34:
	call	SeMenu_StorePartParam
	pushw	0
	pushw	33
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
SeMenu_CopyWriteUpdate_Epilogue60:
	inc	4, xsp
	ret
SeEasy_OnSideRow5:
	dec	4, xsp
	ld	(xsp+2), a
	lda	xbc, (xsp)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	cp	(xsp+2), 0
	jr	nz, SeMenu_CopyWriteUpdate_Skip79
	cp	(xsp), 8
	jr	z, SeMenu_CopyWriteUpdate_Epilogue61
	ld	wa, 0:i3
	ldw	bc, 8
	jr	SeMenu_CopyWriteUpdate_Join35
SeMenu_CopyWriteUpdate_Skip79:
	cp	(xsp), 4
	jr	z, SeMenu_CopyWriteUpdate_Epilogue61
	ld	wa, 0:i3
	ld	bc, 4:i3
SeMenu_CopyWriteUpdate_Join35:
	call	SeMenu_StorePartParam
	pushw	0
	pushw	33
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
SeMenu_CopyWriteUpdate_Epilogue61:
	inc	4, xsp
	ret
SeEasy_OnSwitch15:
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
	andmi8	(xsp+12), 15
	lda	xbc, (xsp)
	ld	wa, 1:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	a, (xsp+14)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SwitchToValueStep
	ld	e, (xsp+12)
	lda	xbc, (xsp)
	lda	xwa, (xbc+8)
	lda	xbc, (xbc+9)
	cp	e, 9
	jr	z, SeMenu_CopyWriteUpdate_Skip34
	cp	e, 10
	jr	z, SeMenu_CopyWriteUpdate_Skip35
	cp	e, 11
	jr	z, SeMenu_CopyWriteUpdate_Skip35
	cp	e, 8
	jr	ugt, SeMenu_CopyWriteUpdate_Epilogue33
	cp	e, 0:i3
	jr	c, SeMenu_CopyWriteUpdate_Epilogue33
	ld	(xwa), 50
SeMenu_CopyWriteUpdate_Join36:
	ld	(xbc), 0
	ld	xwa, 94
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 58
	ld	bc, 1:i3
	ld	de, 0:i3
	call	SeMenu_StepParamFieldAndSend
	ld	wa, 1:i3
	call	SeMenu_BindDialToColumn
	jr	SeMenu_CopyWriteUpdate_Epilogue33
SeMenu_CopyWriteUpdate_Skip34:
	ld	(xwa), 30
	jr	SeMenu_CopyWriteUpdate_Join36
SeMenu_CopyWriteUpdate_Skip35:
	ld	(xwa), 1
	jr	SeMenu_CopyWriteUpdate_Join36
SeMenu_CopyWriteUpdate_Epilogue33:
	lda	xsp, (xsp+16)
	ret
	lda	xsp, (xsp-16)
	ld	(xsp+14), a
	lda	xbc, (xsp+12)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	andmi8	(xsp+12), 15
	lda	xbc, (xsp)
	ld	wa, 2:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	a, (xsp+14)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SwitchToValueStep
	ld	e, (xsp+12)
	lda	xbc, (xsp)
	lda	xwa, (xbc+8)
	lda	xbc, (xbc+9)
	cp	e, 8
	jr	z, SeMenu_CopyWriteUpdate_Skip37
	cp	e, 9
	jr	z, SeMenu_CopyWriteUpdate_Skip38
	cp	e, 10
	jr	z, SeMenu_CopyWriteUpdate_Skip36
	cp	e, 11
	jr	z, SeMenu_CopyWriteUpdate_Skip36
	cp	e, 7:i3
	jr	ugt, SeMenu_CopyWriteUpdate_Epilogue34
	cp	e, 0:i3
	jr	c, SeMenu_CopyWriteUpdate_Epilogue34
SeMenu_CopyWriteUpdate_Skip36:
	lda	xwa, (xsp)
	ld	(xwa+8), 50
	ld	(xwa+9), 0
SeMenu_CopyWriteUpdate_Join37:
	ld	xwa, 1:i3
	lda	xwa, (xwa+94)
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 58
	ld	bc, 2:i3
	ld	de, 0:i3
	call	SeMenu_StepParamFieldAndSend
	ld	wa, 2:i3
	call	SeMenu_BindDialToColumn
	jr	SeMenu_CopyWriteUpdate_Epilogue34
SeMenu_CopyWriteUpdate_Skip37:
	ld	(xwa), 50
	ld	(xbc), 206
	jr	SeMenu_CopyWriteUpdate_Join37
SeMenu_CopyWriteUpdate_Skip38:
	ld	(xwa), 30
	ld	(xbc), 0
	jr	SeMenu_CopyWriteUpdate_Join37
SeMenu_CopyWriteUpdate_Epilogue34:
	lda	xsp, (xsp+16)
	ret
	lda	xsp, (xsp-16)
	ld	(xsp+14), a
	lda	xbc, (xsp+12)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	andmi8	(xsp+12), 15
	lda	xbc, (xsp)
	ld	wa, 3:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	a, (xsp+14)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SwitchToValueStep
	ld	a, (xsp+12)
	extz	wa
	cp	wa, 0:i3
	jr	mi, SeMenu_CopyWriteUpdate_Epilogue35
	cp	wa, 11
	jr	gt, SeMenu_CopyWriteUpdate_Epilogue35
	add	wa, wa
	lda	xix, (ToneGen_ParamTable_0x2EE:24)
	ld	wa, (xix+wa)
	lda xix, (SeMenu_CopyWriteUpdate_Step3_Code:24)
	jp	t, (xix+wa)
SeMenu_CopyWriteUpdate_Step3_Code:
	lda	xwa, (xsp)
	ld	(xwa+8), 50
	ld	(xwa+9), 206
SeMenu_CopyWriteUpdate_Join38:
	ld	xwa, 2:i3
	lda	xwa, (xwa+94)
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 58
	ld	bc, 3:i3
	ld	de, 0:i3
	call	SeMenu_StepParamFieldAndSend
	ld	wa, 3:i3
	call	SeMenu_BindDialToColumn
	jr	SeMenu_CopyWriteUpdate_Epilogue35
SeMenu_CopyWriteUpdate_Entry5_Case4:	; cases 4, 5, 7, 10, 11
	lda	xwa, (xsp)
	ld	(xwa+8), 50
	jr	SeMenu_CopyWriteUpdate_Join21
SeMenu_CopyWriteUpdate_Entry5_Case6:
	lda	xwa, (xsp)
	ld	(xwa+8), 3
	jr	SeMenu_CopyWriteUpdate_Join21
SeMenu_CopyWriteUpdate_Entry5_Case8:
	lda	xwa, (xsp)
	ld	(xwa+8), 24
	ld	(xwa+9), 232
	jr	SeMenu_CopyWriteUpdate_Join38
SeMenu_CopyWriteUpdate_Entry5_Case9:
	lda	xwa, (xsp)
	ld	(xwa+8), 30
SeMenu_CopyWriteUpdate_Join21:
	ld	(xwa+9), 0
	jr	SeMenu_CopyWriteUpdate_Join38
SeMenu_CopyWriteUpdate_Epilogue35:
	lda	xsp, (xsp+16)
	ret
	lda	xsp, (xsp-16)
	ld	(xsp+14), a
	lda	xbc, (xsp+12)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	andmi8	(xsp+12), 15
	lda	xbc, (xsp)
	ld	wa, 4:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	a, (xsp+14)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SwitchToValueStep
	ld	a, (xsp+12)
	extz	wa
	cp	wa, 0:i3
	jr	mi, SeMenu_CopyWriteUpdate_Epilogue36
	cp	wa, 9
	jr	gt, SeMenu_CopyWriteUpdate_Epilogue36
	add	wa, wa
	lda	xix, (ToneGen_ParamTable_0x306:24)
	ld	wa, (xix+wa)
	lda xix, (SeMenu_CopyWriteUpdate_Step3_Code_2:24)
	jp	t, (xix+wa)
SeMenu_CopyWriteUpdate_Step3_Code_2:
	lda	xwa, (xsp)
	ld	(xwa+8), 50
SeMenu_CopyWriteUpdate_Join39:
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
	call	SeMenu_StepParamFieldAndSend
	ld	wa, 4:i3
	call	SeMenu_BindDialToColumn
	jr	SeMenu_CopyWriteUpdate_Epilogue36
SeMenu_CopyWriteUpdate_Entry5_Switch2_Case6:	; cases 6, 8
	lda	xwa, (xsp)
	ld	(xwa+8), 100
	jr	SeMenu_CopyWriteUpdate_Join39
SeMenu_CopyWriteUpdate_Entry5_Switch2_Case9:
	lda	xwa, (xsp)
	ld	(xwa+8), 30
	jr	SeMenu_CopyWriteUpdate_Join39
SeMenu_CopyWriteUpdate_Epilogue36:
	lda	xsp, (xsp+16)
	ret
	lda	xsp, (xsp-16)
	ld	(xsp+14), a
	lda	xbc, (xsp+12)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	andmi8	(xsp+12), 15
	lda	xbc, (xsp)
	ld	wa, 5:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	a, (xsp+14)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SwitchToValueStep
	ld	a, (xsp+12)
	extz	wa
	cp	wa, 0:i3
	jr	mi, SeMenu_CopyWriteUpdate_Epilogue37
	cp	wa, 5:i3
	jr	gt, SeMenu_CopyWriteUpdate_Epilogue37
	add	wa, wa
	lda	xix, (ToneGen_ParamTable_0x31A:24)
	ld	wa, (xix+wa)
	lda xix, (SeMenu_CopyWriteUpdate_Step3_Code_3:24)
	jp	t, (xix+wa)
SeMenu_CopyWriteUpdate_Step3_Code_3:
	lda	xwa, (xsp)
	ld	(xwa+8), 100
	ld	(xwa+9), 0
SeMenu_CopyWriteUpdate_Join40:
	ld	xwa, 4:i3
	lda	xwa, (xwa+94)
	extz	wa
	pushw	wa
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 58
	ld	bc, 5:i3
	ld	de, 0:i3
	call	SeMenu_StepParamFieldAndSend
	ld	wa, 5:i3
	call	SeMenu_BindDialToColumn
	jr	SeMenu_CopyWriteUpdate_Epilogue37
SeMenu_CopyWriteUpdate_Entry5_Switch3_Case4:	; cases 4, 5
	lda	xwa, (xsp)
	ld	(xwa+8), 50
	ld	(xwa+9), 206
	jr	SeMenu_CopyWriteUpdate_Join40
SeMenu_CopyWriteUpdate_Epilogue37:
	lda	xsp, (xsp+16)
	ret
	lda	xsp, (xsp-16)
	ld	(xsp+14), a
	lda	xbc, (xsp+12)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	andmi8	(xsp+12), 15
	lda	xbc, (xsp)
	ld	wa, 6:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	a, (xsp+14)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SwitchToValueStep
	ld	a, (xsp+12)
	cp	a, 5:i3
	jr	z, SeMenu_CopyWriteUpdate_Skip39
	cp	a, 4:i3
	jr	nz, SeMenu_CopyWriteUpdate_Epilogue38
SeMenu_CopyWriteUpdate_Skip39:
	lda	xbc, (xsp)
	ld	(xbc+8), 50
	ld	(xbc+9), 0
	ld	xwa, 5:i3
	lda	xwa, (xwa+94)
	extz	wa
	pushw	wa
	push	xbc
	ldw	wa, 58
	ld	bc, 6:i3
	ld	de, 0:i3
	call	SeMenu_StepParamFieldAndSend
	ld	wa, 6:i3
	call	SeMenu_BindDialToColumn
SeMenu_CopyWriteUpdate_Epilogue38:
	lda	xsp, (xsp+16)
	ret
	lda	xsp, (xsp-16)
	ld	(xsp+14), a
	lda	xbc, (xsp+12)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	andmi8	(xsp+12), 15
	lda	xbc, (xsp)
	ld	wa, 7:i3
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	a, (xsp+14)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SwitchToValueStep
	ld	a, (xsp+12)
	cp	a, 10
	jr	z, SeMenu_CopyWriteUpdate_Epilogue39
	cp	a, 11
	jr	z, SeMenu_CopyWriteUpdate_Skip40
	cp	a, 9
	jr	ugt, SeMenu_CopyWriteUpdate_Epilogue39
	cp	a, 0:i3
	jr	c, SeMenu_CopyWriteUpdate_Epilogue39
SeMenu_CopyWriteUpdate_Skip40:
	lda	xbc, (xsp)
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	xwa, 6:i3
	lda	xwa, (xwa+94)
	extz	wa
	pushw	wa
	push	xbc
	ldw	wa, 58
	ld	bc, 7:i3
	ld	de, 0:i3
	call	SeMenu_StepParamFieldAndSend
	ld	wa, 7:i3
	call	SeMenu_BindDialToColumn
SeMenu_CopyWriteUpdate_Epilogue39:
	lda	xsp, (xsp+16)
	ret
	lda	xsp, (xsp-16)
	ld	(xsp+14), a
	lda	xbc, (xsp+12)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	andmi8	(xsp+12), 15
	lda	xbc, (xsp)
	ldw	wa, 8
	call	SeMenu_LoadPartParam
	lda	xbc, (xsp)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	a, (xsp+14)
	extz	wa
	lda	xbc, (xbc+10)
	call	SeMenu_SwitchToValueStep
	ld	a, (xsp+12)
	cp	a, 11
	jr	ugt, SeMenu_CopyWriteUpdate_Epilogue40
	cp	a, 0:i3
	jr	c, SeMenu_CopyWriteUpdate_Epilogue40
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
	call	SeMenu_StepParamFieldAndSend
	ldw	wa, 8
	call	SeMenu_BindDialToColumn
SeMenu_CopyWriteUpdate_Epilogue40:
	lda	xsp, (xsp+16)
	ret
	dec	4, xsp
	lda	xbc, (xsp+2)
	cp	a, 0:i3
	jr	nz, SeMenu_CopyWriteUpdate_Skip41
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+2)
	and	a, 15
	cp	a, 11
	jrl	z, SeMenu_CopyWriteUpdate_Epilogue41
	cp	a, 11
	jrl	ugt, SeMenu_CopyWriteUpdate_Epilogue41
	inc	1, a
	andmi8	(xsp+2), 240
	or	(xsp+2), a
	ld	c, (xsp+2)
	extz	bc
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
	call	SeMenu_SetPartConfigBit3
	jr	SeMenu_CopyWriteUpdate_Epilogue41
SeMenu_CopyWriteUpdate_Skip41:
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	lda	xwa, (xsp)
	call	SeMenu_LoadMasterPtr
	bitm	7, (xsp+2)
	jr	z, SeMenu_CopyWriteUpdate_Skip80
	resm	7, (xsp+2)
	ld	wa, 4:i3
	ldw	bc, 64
	ld	de, 0:i3
	call	SeMenu_PatchBank_Data
	ld	a, (xsp)
	extz	wa
	pushw	64
	ld	bc, 4:i3
	ld	de, 0:i3
	jr	SeMenu_CopyWriteUpdate_Join22
SeMenu_CopyWriteUpdate_Skip80:
	setm	7, (xsp+2)
	ld	wa, 4:i3
	ldw	bc, 64
	ld	de, 1:i3
	call	SeMenu_PatchBank_Data
	ld	a, (xsp)
	extz	wa
	pushw	64
	ld	bc, 4:i3
	ldw	de, 64
SeMenu_CopyWriteUpdate_Join22:
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
SeMenu_CopyWriteUpdate_Epilogue41:
	inc	4, xsp
	ret
	dec	2, xsp
	lda	xbc, (xsp)
	cp	a, 0:i3
	jr	nz, SeMenu_CopyWriteUpdate_Data_Skip
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp)
	and	a, 15
	jr	z, SeMenu_CopyWriteUpdate_Data_Epilogue
	cp	a, 11
	jr	ugt, SeMenu_CopyWriteUpdate_Data_Epilogue
	dec	1, a
	andmi8	(xsp), 240
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
	call	SeMenu_SetPartConfigBit3
	jr	SeMenu_CopyWriteUpdate_Data_Epilogue
SeMenu_CopyWriteUpdate_Data_Skip:
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	bitm	6, (xsp)
	jr	z, SeMenu_CopyWriteUpdate_Entry6
	resm	6, (xsp)
	jr	SeMenu_CopyWriteUpdate_Data_Join
SeMenu_CopyWriteUpdate_Entry6:
	.byte 0xb7, 0xbe
SeMenu_CopyWriteUpdate_Data_Join:
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
SeMenu_CopyWriteUpdate_Data_Epilogue:
	inc	2, xsp
	ret
	cp	a, 0:i3
	ret	nz
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
SeWrtMem_OnSideRow1:
	dec	2, xsp
	cp	a, 0:i3
	jr	z, SeMenu_CopyWriteUpdate_Data_Epilogue2
	lda	xwa, (xsp)
	call	SeMenu_GetWriteMemSlot
	ld	a, (xsp)
	extz	wa
	ldw	bc, 62
	call	SeMenu_CopyWriteUpdate_Step3_Code_3_Helper
	ld	a, (xsp)
	extz	wa
	call	SeMenu_SetDisplayValue_Data
	ldw	wa, 35
	call	SeMenu_TriggerNotification
	ld	wa, 1:i3
	call	SeMenu_CopyWriteUpdate_Step3_Helper14
	ld	wa, 0:i3
	call	SeMenu_SetSelectedRow
SeMenu_CopyWriteUpdate_Data_Epilogue2:
	inc	2, xsp
	ret
SeWrtMem_OnSideRow3:
	dec	6, xsp
	cp	a, 0:i3
	jr	nz, SeMenu_CopyWriteUpdate_Data_Epilogue3
	lda	xwa, (xsp+4)
	call	SeMenu_GetWriteMemSlot
	cp	(xsp+4), 39
	jr	nc, SeMenu_CopyWriteUpdate_Data_Epilogue3
	incm8	1, (xsp+4)
	ld	a, (xsp+4)
	extz	wa
	call	SeMenu_CopyWriteUpdate_Step3_Code_3_Helper4
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
SeMenu_CopyWriteUpdate_Data_Epilogue3:
	inc	6, xsp
	ret
SeWrtMem_OnSideRow4:
	dec	6, xsp
	cp	a, 0:i3
	jr	nz, SeMenu_CopyWriteUpdate_Data_Epilogue4
	lda	xwa, (xsp+4)
	call	SeMenu_GetWriteMemSlot
	cp	(xsp+4), 0
	jr	z, SeMenu_CopyWriteUpdate_Data_Epilogue4
	decm8	1, (xsp+4)
	ld	a, (xsp+4)
	extz	wa
	call	SeMenu_CopyWriteUpdate_Step3_Code_3_Helper4
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
SeMenu_CopyWriteUpdate_Data_Epilogue4:
	inc	6, xsp
	ret
SeWrtMem_OnSideRow5:
	cp	a, 0:i3
	ret	nz
	ldw	wa, 63
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
SeWrtMem_OnSwitch15:
	cp	a, 0:i3
	ret	nz
	ld	wa, 0:i3
	call	SeMenu_SetSelectedRow
	ldw	wa, 32
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ret
	jrl	SeMenu_CopyWriteUpdate_Data_Join3
	jrl	SeMenu_CopyWriteUpdate_Data_Join4
	jrl	SeMenu_CopyWriteUpdate_Data_Join5
	jrl	SeMenu_CopyWriteUpdate_Data_Epilogue4_Join
	jrl	SeMenu_CopyWriteUpdate_Data_Epilogue4_Join2
	jrl	SeMenu_CopyWriteUpdate_Data_Epilogue4_Join3
	ld	c, a
	res	7, c
	ldw	wa, 0x8000
	cp	c, 0:i3
	jr	nz, SeMenu_CopyWriteUpdate_Skip81
	ld	wa, 0:i3
SeMenu_CopyWriteUpdate_Skip81:
	jrl	SeMenu_CopyWriteUpdate_Data_Epilogue4_Join4
	jrl	SeMenu_CopyWriteUpdate_Data_Epilogue4_Join5
	dec	4, xsp
	push	qiz
	cp	a, 0:i3
	jr	nz, SeMenu_CopyWriteUpdate_Skip82
	calr	SeMenu_CopyWriteUpdate_Helper
	jr	SeMenu_CopyWriteUpdate_Data_Epilogue4_Epilogue
SeMenu_CopyWriteUpdate_Skip82:
	lda	xwa, (xsp+2)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 1
	jr	z, SeMenu_CopyWriteUpdate_Data_Epilogue4_Epilogue
	ldib_erp 251, 0
SeMenu_CopyWriteUpdate_Data_Loop:
	ldto_berp a, 251
	extz	wa
	lda	xbc, (xsp+4)
	call	SeMenu_CopyWriteUpdate_Step3_Code_3_Helper6
	lda	xbc, (xsp+4)
	ld	xwa, xbc
	call	FontGlyph_ByteData
	ldto_berp a, 251
	extz	wa
	extz	xwa
	ld	c, a
	lda	xde, (xsp+4)
	pushw	127
	ld	wa, 0:i3
	call	SeMenu_RegisterElement_Extended
	inc1b_erp 251
	cp_erpb 251, 16
	jr	c, SeMenu_CopyWriteUpdate_Data_Loop
	ld	wa, 0:i3
	call	SeMenu_CopyWriteUpdate_Step3_Helper14
	ldw	wa, 62
	ld	bc, 0:i3
	call	SeMenu_SendEvent
SeMenu_CopyWriteUpdate_Data_Epilogue4_Epilogue:
	pop qiz
	inc	4, xsp
	ret
	cp	a, 0:i3
	ret	nz
	jrl	SeMenu_CopyWriteUpdate_Data_Loop_Join
	lda	xsp, (xsp-20)
	push	qiz
	cp	a, 0:i3
	jrl	nz, SeMenu_CopyWriteUpdate_Data_Loop_Epilogue
	lda	xwa, (xsp+2)
	call	SeMenu_LoadObjEntries
	cp	(xsp+2), 1
	jr	nz, SeMenu_CopyWriteUpdate_Data_Loop_Skip
	lda	xbc, (xsp+4)
	ld	wa, 1:i3
	ldw	de, 13
	call	SeMenu_SetupPartDisplay_End
	ldib_erp 251, 0
SeMenu_CopyWriteUpdate_Data_Loop2:
	ldto_berp a, 251
	extz	wa
	ld	bc, wa
	extz	xbc
	lda	xde, (xsp+4)
	lda	xde, (xde+wa)
	pushw 127
	ld	wa, 0:i3
	call	SeMenu_SetupDisplayObject_Alt1
	inc1b_erp 251
	cp_erpb 251, 13
	jr	c, SeMenu_CopyWriteUpdate_Data_Loop2
	ldw	wa, 61
	ld	bc, 0:i3
	jr	SeMenu_CopyWriteUpdate_Data_Join2
SeMenu_CopyWriteUpdate_Data_Loop_Skip:
	ldib_erp 251, 0
SeMenu_CopyWriteUpdate_Data_Loop3:
	ldto_berp a, 251
	extz	wa
	lda	xbc, (xsp+20)
	call	SeMenu_CopyWriteUpdate_Step3_Code_3_Helper6
	ldto_berp a, 251
	extz	wa
	extz	xwa
	ld	c, a
	lda	xde, (xsp+20)
	pushw	127
	ld	wa, 0:i3
	call	SeMenu_RegisterElement_Extended
	inc1b_erp 251
	cp_erpb 251, 16
	jr	c, SeMenu_CopyWriteUpdate_Data_Loop3
	ld	wa, 0:i3
	call	SeMenu_CopyWriteUpdate_Step3_Helper14
	ldw	wa, 62
	ld	bc, 0:i3
SeMenu_CopyWriteUpdate_Data_Join2:
	call	SeMenu_SendEvent
SeMenu_CopyWriteUpdate_Data_Loop_Epilogue:
	pop qiz
	lda	xsp, (xsp+20)
	ret
SeMenu_CopyWriteUpdate_Step3_Helper17:
	dec	4, xsp
	ld	c, a
	and	c, 31
	cp	c, 16
	jr	ule, SeMenu_CopyWriteUpdate_Data_Skip2
	ld	c, 16:opc
SeMenu_CopyWriteUpdate_Data_Skip2:
	extz	bc
	ld	wa, 2:i3
	call	SeMenu_StorePartParam
	lda	xbc, (xsp+2)
	ld	wa, 0:i3
	call	SeMenu_CopyWriteUpdate_Step3_Code_3_Helper6
	ld	a, (xsp+2)
	extz	wa
	lda	xbc, (xsp)
	call	SeMenu_CopyWriteUpdate_Step3_Code_3_Helper8
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
	call	SeMenu_ApplyPartEdit_Helper4_Helper
	ld	wa, 0:i3
	ldw	bc, 8
	ld	de, 0:i3
	call	SeMenu_SetupPartDisplay_End_Sub
	ld	wa, 1:i3
	ld	bc, 6:i3
	ld	de, 0:i3
	call	SeMenu_SetupPartDisplay_End_Sub
	inc	4, xsp
	ret
SeMenu_CopyWriteUpdate_Data_Join3:
	dec	6, xsp
	lda	xbc, (xsp+4)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	cp	(xsp+4), 0
	jr	z, SeMenu_CopyWriteUpdate_Data_Epilogue5
	decm8	1, (xsp+4)
	ld	c, (xsp+4)
	extz	bc
	ld	wa, 0:i3
	call	SeMenu_StorePartParam
	ld	a, (xsp+4)
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_CopyWriteUpdate_Step3_Code_3_Helper6
	ld	a, (xsp+2)
	extz	wa
	lda	xbc, (xsp)
	call	SeMenu_CopyWriteUpdate_Step3_Code_3_Helper8
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
SeMenu_CopyWriteUpdate_Data_Epilogue5:
	inc	6, xsp
	ret
SeMenu_CopyWriteUpdate_Data_Join4:
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
	jr	nc, SeMenu_CopyWriteUpdate_Data_Epilogue6
	incm8	1, (xsp+6)
	ld	c, (xsp+6)
	extz	bc
	ld	wa, 0:i3
	call	SeMenu_StorePartParam
	ld	a, (xsp+6)
	extz	wa
	lda	xbc, (xsp+4)
	call	SeMenu_CopyWriteUpdate_Step3_Code_3_Helper6
	ld	a, (xsp+4)
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_CopyWriteUpdate_Step3_Code_3_Helper8
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
SeMenu_CopyWriteUpdate_Data_Epilogue6:
	inc	8, xsp
	ret
SeMenu_CopyWriteUpdate_Data_Join5:
	lda	xsp, (xsp-24)
	push	qiz
	lda	xbc, (xsp+2)
	ld	wa, 2:i3
	call	SeMenu_LoadPartParam
	ldib_erp 251, 0
SeMenu_CopyWriteUpdate_Entry6_Code_Loop:
	ldto_berp a, 251
	extz	wa
	lda	xbc, (xsp+6)
	lda	xbc, (xbc+wa)
	call	SeMenu_CopyWriteUpdate_Step3_Code_3_Helper6
	inc1b_erp	251
	cp_erpb	251, 15
	jr	ule, SeMenu_CopyWriteUpdate_Entry6_Code_Loop
	ld	c, (xsp+2)
	dec	1, c
	extz	bc
	lda	xwa, (xsp+6)
	cp	(xwa+bc), 0x20
	jrl	nz, SeMenu_CopyWriteUpdate_Entry6_Code_Epilogue
	lda	xbc, (xsp+24)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ldib_erp 251, 0
	ld	a, (xsp+2)
	sub	a, (xsp+24)
	dec	1, a
	ldfr_berp	a, 226
	ld	l, (xsp+2)
	dec	1, l
	lda	xbc, (xsp+6)
	ld	xix, xbc
	ld	e, (xsp+2)
	add	e, 254
	extz	de
	extz	hl
	ldto_berp a, 251
	cpb_erp a, 226
	jr	nc, SeMenu_CopyWriteUpdate_Data_Skip3
SeMenu_CopyWriteUpdate_Entry6_Code_Loop2:
	ld	iy, hl
	ld	wa, de
	ld	a, (xix+wa)
	ld	(xix+iy), a
	inc1b_erp 251
	dec 1, hl
	dec 1, de
	ldto_berp a, 251
	cpb_erp a, 226
	jr c, SeMenu_CopyWriteUpdate_Entry6_Code_Loop2
SeMenu_CopyWriteUpdate_Data_Skip3:
	ld a, (xsp+24)
	extz wa
	ld	(xbc+wa), 0x20
	ld	wa, 1:i3
	ldw	de, 16
	call	SeMenu_SetupPartDisplay
	ld	c, (xsp+24)
	extz	bc
	lda	xwa, (xsp+6)
	ld	a, (xwa+bc)
	extz wa
	lda	xbc, (xsp+4)
	call	SeMenu_CopyWriteUpdate_Step3_Code_3_Helper8
	ld	c, (xsp+4)
	extz	bc
	ld	wa, 1:i3
	call	SeMenu_StorePartParam
	pushw	1
	pushw	63
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
SeMenu_CopyWriteUpdate_Entry6_Code_Epilogue:
	pop qiz
	lda	xsp, (xsp+24)
	ret
SeMenu_CopyWriteUpdate_Data_Epilogue4_Join:
	lda	xsp, (xsp-24)
	push	qiz
	lda	xbc, (xsp+2)
	ld	wa, 2:i3
	call	SeMenu_LoadPartParam
	ldib_erp 251, 0
SeMenu_CopyWriteUpdate_Data_Skip3_Loop:
	ldto_berp a, 251
	extz	wa
	lda	xbc, (xsp+6)
	lda	xbc, (xbc+wa)
	call	SeMenu_CopyWriteUpdate_Step3_Code_3_Helper6
	inc1b_erp	251
	cp_erpb	251, 15
	jr	ule, SeMenu_CopyWriteUpdate_Data_Skip3_Loop
	lda	xbc, (xsp+24)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+24)
	ldfr_berp a, 251
	ld	c, (xsp+2)
	dec	1, c
	ld	l, c
	ldto_berp a, 251
	cp	a, l
	jr	nc, SeMenu_CopyWriteUpdate_Data_Skip3_Skip
	lda	xde, (xsp+6)
	ldto_berp c, 251
	extz	bc
	ld	wa, 1:i3
	add	bc, wa
SeMenu_CopyWriteUpdate_Entry6_Code_Loop3:
	ld	ix, bc
	ldw	wa, 0xffff
	add	ix, wa
	ld	wa, bc
	ld	a, (xde+wa)
	ld	(xde+ix), a
	inc1b_erp 251
	inc 1, bc
	ldto_berp a, 251
	cp	a, l
	jr	c, SeMenu_CopyWriteUpdate_Entry6_Code_Loop3
SeMenu_CopyWriteUpdate_Data_Skip3_Skip:
	ld	a, (xsp+2)
	dec	1, a
	extz	wa
	lda	xbc, (xsp+6)
	ld	(xbc+wa), 0x20
	ld	wa, 1:i3
	ldw	de, 16
	call	SeMenu_SetupPartDisplay
	ld	c, (xsp+24)
	extz	bc
	lda	xwa, (xsp+6)
	ld	a, (xwa+bc)
	extz wa
	lda	xbc, (xsp+4)
	call	SeMenu_CopyWriteUpdate_Step3_Code_3_Helper8
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
SeMenu_CopyWriteUpdate_Data_Epilogue4_Join2:
	dec	6, xsp
	lda	xbc, (xsp+4)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+4)
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_CopyWriteUpdate_Step3_Code_3_Helper6
	lda	xde, (xsp+2)
	ld	a, (xde)
	cp	a, 65
	jr	c, SeMenu_CopyWriteUpdate_Data_Skip4
	cp	a, 90
	jr	ugt, SeMenu_CopyWriteUpdate_Data_Skip4
	sub	a, 65
	ld	c, 97:opc
SeMenu_CopyWriteUpdate_Data_Skip3_Join:
	add	a, c
	ld	(xde), a
	ld	a, (xsp+4)
	extz	wa
	ld	c, (xde)
	extz	bc
	call	SeMenu_CopyWriteUpdate_Step3_Code_3_Helper5
	ld	a, (xsp+2)
	extz	wa
	lda	xbc, (xsp)
	call	SeMenu_CopyWriteUpdate_Step3_Code_3_Helper8
	ld	c, (xsp)
	extz	bc
	ld	wa, 1:i3
	call	SeMenu_StorePartParam
	pushw	1
	pushw	63
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
	jr	SeMenu_CopyWriteUpdate_Data_Epilogue7
SeMenu_CopyWriteUpdate_Data_Skip4:
	cp	a, 97
	jr	c, SeMenu_CopyWriteUpdate_Data_Epilogue7
	cp	a, 122
	jr	ugt, SeMenu_CopyWriteUpdate_Data_Epilogue7
	sub	a, 97
	ld	c, 65:opc
	jr	SeMenu_CopyWriteUpdate_Data_Skip3_Join
SeMenu_CopyWriteUpdate_Data_Epilogue7:
	inc	6, xsp
	ret
SeMenu_CopyWriteUpdate_Data_Epilogue4_Join3:
	dec	6, xsp
	lda	xbc, (xsp)
	ld	wa, 1:i3
	call	SeMenu_LoadPartParam
	cp	(xsp), 0
	jr	z, SeMenu_CopyWriteUpdate_Data_Epilogue8
	decm8	1, (xsp)
	ld	c, (xsp)
	extz	bc
	ld	wa, 1:i3
	call	SeMenu_StorePartParam
	ld	a, (xsp)
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_CopyWriteUpdate_Step3_Code_3_Helper7
	lda	xbc, (xsp+4)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+4)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	call	SeMenu_CopyWriteUpdate_Step3_Code_3_Helper5
	pushw	1
	pushw	63
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
SeMenu_CopyWriteUpdate_Data_Epilogue8:
	inc	6, xsp
	ret
SeMenu_CopyWriteUpdate_Data_Epilogue4_Join4:
	dec	6, xsp
	push	qiz
	and	wa, 0x8000
	cp	wa, 0:i3
	scc8	nz, a
	ldfr_berp a, 251
	lda	xbc, (xsp+4)
	ld	wa, 1:i3
	call	SeMenu_LoadPartParam
	cpib_erp 251, 0
	jr nz, SeMenu_CopyWriteUpdate_Data_Epilogue8_Skip
	cp	(xsp+4), 16
	jr	c, SeMenu_CopyWriteUpdate_Data_Epilogue9
	submi8	(xsp+4), 16
	jr	SeMenu_CopyWriteUpdate_Data_Join6
SeMenu_CopyWriteUpdate_Data_Epilogue8_Skip:
	ld	a, (xsp+4)
	add	a, 16
	cp	a, 95
	jr	ugt, SeMenu_CopyWriteUpdate_Data_Epilogue9
	addmi8	(xsp+4), 16
SeMenu_CopyWriteUpdate_Data_Join6:
	ld	c, (xsp+4)
	extz	bc
	ld	wa, 1:i3
	call	SeMenu_StorePartParam
	ld	a, (xsp+4)
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_CopyWriteUpdate_Step3_Code_3_Helper7
	lda	xbc, (xsp+6)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+6)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	call	SeMenu_CopyWriteUpdate_Step3_Code_3_Helper5
	pushw	1
	pushw	63
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
SeMenu_CopyWriteUpdate_Data_Epilogue9:
	pop qiz
	inc	6, xsp
	ret
SeMenu_CopyWriteUpdate_Data_Epilogue4_Join5:
	dec	6, xsp
	lda	xbc, (xsp)
	ld	wa, 1:i3
	call	SeMenu_LoadPartParam
	cp	(xsp), 95
	jr	nc, SeMenu_CopyWriteUpdate_Data_Epilogue9_Epilogue
	incm8	1, (xsp)
	ld	c, (xsp)
	extz	bc
	ld	wa, 1:i3
	call	SeMenu_StorePartParam
	ld	a, (xsp)
	extz	wa
	lda	xbc, (xsp+2)
	call	SeMenu_CopyWriteUpdate_Step3_Code_3_Helper7
	lda	xbc, (xsp+4)
	ld	wa, 0:i3
	call	SeMenu_LoadPartParam
	ld	a, (xsp+4)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	call	SeMenu_CopyWriteUpdate_Step3_Code_3_Helper5
	pushw	1
	pushw	63
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
SeMenu_CopyWriteUpdate_Data_Epilogue9_Epilogue:
	inc	6, xsp
	ret
SeMenu_CopyWriteUpdate_Helper:
	push	qiz
	ldib_erp	251, 0
SeMenu_CopyWriteUpdate_Data_Epilogue9_Loop:
	ldto_berp	a, 251
	extz	wa
	ldw	bc, 32
	call	SeMenu_CopyWriteUpdate_Step3_Code_3_Helper5
	inc1b_erp 251
	cp_erpb 251, 15
	jr ule, SeMenu_CopyWriteUpdate_Data_Epilogue9_Loop
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
SeMenu_CopyWriteUpdate_Data_Loop_Join:
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
SeMenu_CopyWriteUpdate_Helper_Loop:
	ldto_berp a, 250
	extz	wa
	lda	xbc, (xsp+28)
	lda	xbc, (xbc+wa)
	call	SeMenu_CopyWriteUpdate_Step3_Code_3_Helper6
	inc1b_erp	250
	cp_erpb	250, 15
	jr	ule, SeMenu_CopyWriteUpdate_Helper_Loop
	ldib_erp	250, 0
	ld	a, (xsp+4)
	dec	1, a
	ld	c, a
	cp	a, 0:i3
	jr	c, SeMenu_CopyWriteUpdate_Helper_Skip
	lda	xde, (xsp+28)
SeMenu_CopyWriteUpdate_Helper_Loop2:
	ldto_berp a, 250
	extz	wa
	cp	(xde+wa), 0x20
	jr	nz, SeMenu_CopyWriteUpdate_Helper_Skip2
	inc1b_erp	249
	inc1b_erp	250
	ldto_berp	a, 250
	cp	a, c
	jr	ule, SeMenu_CopyWriteUpdate_Helper_Loop2
SeMenu_CopyWriteUpdate_Helper_Skip:
	ldto_berp a, 249
	cp	a, c
	jr	ule, SeMenu_CopyWriteUpdate_Helper_Skip3
SeMenu_CopyWriteUpdate_Helper_Loop3:
	jrl	SeMenu_CopyWriteUpdate_Helper_Epilogue
SeMenu_CopyWriteUpdate_Helper_Skip2:
	ldto_berp a, 250
	ldfr_berp a, 251
	ldto_berp a, 249
	cp	a, c
	jr	ugt, SeMenu_CopyWriteUpdate_Helper_Loop3
SeMenu_CopyWriteUpdate_Helper_Skip3:
	ldib_erp 250, 0
	cp c, 0:i3
	jr	c, SeMenu_CopyWriteUpdate_Helper_Skip4
	lda	xde, (xsp+28)
SeMenu_CopyWriteUpdate_Helper_Loop4:
	ld	a, c
	subb_erp a, 250
	extz wa
	cp	(xde+wa), 0x20
	jr	nz, SeMenu_CopyWriteUpdate_Helper_Skip4
	inc1b_erp 249
	inc1b_erp 250
	ldto_berp a, 250
	cp	a, c
	jr	ule, SeMenu_CopyWriteUpdate_Helper_Loop4
SeMenu_CopyWriteUpdate_Helper_Skip4:
	ld	a, (xsp+4)
	ldfr_berp	a, 248
	subb_erp	a, 249
	ldfr_berp	a, 248
	srl_erpb	249, 1
	lda	xwa, (xsp+10)
	lda	xbc, (xsp+28)
	ldw	de, 16
	call	SeMenu_CopyWriteUpdate_Step3_Code_3_Helper2
	ldib_erp 250, 0
	cpib_erp 249, 0
	jr ule, SeMenu_CopyWriteUpdate_Helper_Skip5
	lda	xde, (xsp+10)
	ld	bc, 0:i3
SeMenu_CopyWriteUpdate_Helper_Loop5:
	ld	wa, bc
	ld	(xde+wa), 0x20
	inc1b_erp	250
	inc	1, bc
	ldto_berp	a, 250
	cpb_erp	a, 249
	jr	c, SeMenu_CopyWriteUpdate_Helper_Loop5
SeMenu_CopyWriteUpdate_Helper_Skip5:
	ldto_berp a, 249
	extz	wa
	lda	xbc, (xsp+10)
	exts	xwa
	add	xwa, xbc
	ldto_berp c, 251
	extz	bc
	lda	xde, (xsp+28)
	exts	xbc
	add	xbc, xde
	ldto_berp e, 248
	extz	de
	call	SeMenu_CopyWriteUpdate_Step3_Code_3_Helper2
	ldto_berp a, 249
	addb_erp a, 248
	ldfr_berp a, 250
	ld	c, (xsp+4)
	dec	1, c
	ld	e, c
	ldto_berp a, 250
	cp	a, e
	jr	ugt, SeMenu_CopyWriteUpdate_Helper_Skip6
	lda	xhl, (xsp+10)
	ldto_berp c, 250
	extz	bc
SeMenu_CopyWriteUpdate_Helper_Loop6:
	ld	wa, bc
	ld	(xhl+wa), 0x20
	inc1b_erp	250
	inc	1, bc
	ldto_berp	a, 250
	cp	a, e
	jr	ule, SeMenu_CopyWriteUpdate_Helper_Loop6
SeMenu_CopyWriteUpdate_Helper_Skip6:
	lda	xbc, (xsp+10)
	ld	wa, 1:i3
	ldw	de, 16
	call	SeMenu_SetupPartDisplay
	ld	a, (xsp+6)
	extz	wa
	lda	xbc, (xsp+10)
	ld	a, (xbc+wa)
	extz wa
	lda	xbc, (xsp+8)
	call	SeMenu_CopyWriteUpdate_Step3_Code_3_Helper8
	ld	c, (xsp+8)
	extz	bc
	ld	wa, 1:i3
	call	SeMenu_StorePartParam
	pushw	1
	pushw	63
	call	SeMenu_ShowConfirmDialog
	inc	4, xsp
SeMenu_CopyWriteUpdate_Helper_Epilogue:
	pop	xiz
	lda	xsp, (xsp+42)
	ret
SeCopy_OnSideRow2:
	cp	a, 0:i3
	jr	nz, SeMenu_CopyWriteUpdate_Data_Skip5
	ldw	wa, 38
	ld	bc, 0:i3
	jr	SeMenu_CopyWriteUpdate_Data_Join7
SeMenu_CopyWriteUpdate_Data_Skip5:
	ldw	wa, 43
	ld	bc, 0:i3
SeMenu_CopyWriteUpdate_Data_Join7:
	jp	SeMenu_SendEvent
SeCopy_OnSideRow3:
	cp	a, 0:i3
	jr	nz, SeMenu_CopyWriteUpdate_Data_Skip6
	ldw	wa, 59
	ld	bc, 0:i3
	jr	SeMenu_CopyWriteUpdate_Data_Join8
SeMenu_CopyWriteUpdate_Data_Skip6:
	ldw	wa, 48
	ld	bc, 0:i3
SeMenu_CopyWriteUpdate_Data_Join8:
	jp	SeMenu_SendEvent
SeCopy_OnSideRow5:
	cp	a, 0:i3
	ret	nz
	ldw	wa, 63
	ld	bc, 0:i3
	call	SeMenu_SendEvent
	ld	wa, 2:i3
	call	SeMenu_SetSelectedRow
	ret
SeCopy_OnSwitch15:
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
	ldto_werp WA, 0xfa
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
	ldto_werp WA, 0xfa
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
	ldto_werp WA, 0xfa
	inc1w_erp 0xfa
	extz xwa
	ld xbc, 0x20c33
	add xbc, xwa
	ld (xbc), l
	cp_erpw 0xfa, 0x20, 0x00
	jr c, SeMenu_PopupDialog_Close

SeMenu_PopupDialog_Close_Data:
	ld a, (ACTIVE_TITLE:16)
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
	ld	xhl, (xbc+wa)
	call (xhl)

SeMenu_ValueEditor_Init:
	cp (ACTIVE_TITLE:16), 32
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
	ldto_werp BC, 0xfa
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
	cp (ACTIVE_TITLE:16), 34
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
	cp (ACTIVE_TITLE:16), 38
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
	ld a, (ACTIVE_TITLE:16)
	cp a, (xbc)
	jr z, SeMenu_ValueEditor_Cancel
	jrl SeMenu_ListSelector_ScrollDown

SeMenu_ValueEditor_Complete:
	cp e, 0x12
	jr nz, SeMenu_ValueEditor_Data3
	cp (ACTIVE_TITLE:16), 32
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
	ldfr_berp A, 0xf8
	extz iz
	jr SeMenu_ListSelector_Init

SeMenu_ValueEditor_Data5:
	ldto_werp WA, 0xfa
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
	ld a, (ACTIVE_TITLE:16)
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
	ld	xhl, (xbc+wa)
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
	ld c, (xsp + 0:8)
	extz bc
	ld wa, 1:i3
	call SeMenu_StorePartParam
	pushw 0x1
	pushw 0x20
	call SeMenu_ShowConfirmDialog
	lda xsp, (xsp + 40)
	ret

; =============================================================================
; SeGfx_* -- the sound editor's 17 wrappers around the ScreenData record
; interpreter in display/graphics_text_vga.s.  Every sound-editor screen draws
; through them.  (Named SeMenu_NameEditor_* until 2026-09-25; none of them
; touches the name editor.)
;
; A ScreenData record is {u8 op, u8 len, payload[len-2]}: `len` is the whole
; record's size and is the stride the interpreters advance by.  There are two
; interpreters, each copying its own handler table onto the stack first:
;   GraphicsRender_ProcessEntries  36 handlers, ops 0x00-0x23, table at
;       Str_No+0xBFE (v10/v9 0xEAAF14).  "STATIC" records: the handlers draw
;       from the record alone (e.g. ops 00/01/02/05/09/0A/11/12/15/1B/22 read
;       four u16 at +2/+4/+6/+8; 06/07/20 draw the text at +4 at the 40-column
;       cell index in u16 +2; 17/1C draw the text at +6 at pixel x=u16 +2,
;       y=u16 +4; 03 blits the 1-bpp bitmap at u32 +2).
;   GraphicsRender_Start           12 handlers, ops 0x00-0x0B, table at
;       GraphicsRender_Start_PtrTable (v10/v9 0xEAAFA4).  "BOUND" records: ops 00 02 03 04 05 07
;       08 09 0B first compute value = (RAM byte[u16 +2] & u8 +4) >> (u8 +5 & 15)
;       and draw according to it; ops 06 and 0A instead print the 16-bit word at
;       RAM[u16 +2] (no mask or shift) at cell u16 +7, style u8 +6, format
;       %1d/%2d/%3d chosen by u8 +9 (06) or u8 +0B (0A); op 01 is a null handler.
; The handlers are named by op and by what they draw (scripts/tools/label_segfx_ops.py): lines 00-02,
; dotted lines 11/12/15, dotted box 13, box 09 (DrawRect: the clipped outline), boxes with a 1- / 2-pixel
; drop shadow 22 / 0A, highlight fill 05 (ColorBlit in mode 1), bitmap 03, text at a cell 06/07/08/20 and
; at a pixel 17/1C, which differ only in the font they pass (0/1/2/6, 3/4: table_data/fonts.s).  Every
; text handler and DrawRect clip to the full screen (0,0)-(319,239).
; List wrappers take the first record in XIY and the end (exclusive) in XIX.
; Single-record wrappers take the record in XIY, or -- the *_FromBuf ones -- use
; the RAM record buffer at 0x0006CA that the caller has just filled (fields +2..
; at 0x06CC..); SeGfx_StaticOp03_BlitAtCell builds the op-03 record there itself,
; from XIY = 1-bpp bitmap, IX = cell, BC = bytes per row, HL = rows.
; Evidence: scripts/lanes/seui/se_gfx_wrappers_probe.py reads both handler
; tables out of each ROM and checks every wrapper's call target against the
; entry its name claims (v10, v9, v7: 51/51).
; =============================================================================
SeGfx_DrawStaticList:
	; --- Wrapper function 1: push xwa/xbc, ld from xiy/xix, call, pop, ret ---
	push xwa
	push xbc
	ld xwa, xiy
	ld xbc, xix
	call GraphicsRender_ProcessEntries
	pop xbc
	pop xwa
	ret
SeGfx_DrawBoundList:
	; --- Wrapper function 2: same pattern ---
	push xwa
	push xbc
	ld xwa, xiy
	ld xbc, xix
	call GraphicsRender_Start
	pop xbc
	pop xwa
	ret
SeGfx_DrawBoundRecord:
	; --- Wrapper function 3: push xwa, ld xwa=xiy, call, pop, ret ---
	push xwa
	ld xwa, xiy
	call SeGfx_DrawBoundRecord_Helper
	pop xwa
	ret
SeGfx_StaticOp00_FromBuf:
	; --- Wrapper function 4: set flag, push, ld xwa=imm, call, pop, ret ---
	ld	(COLORBLIT_MODE:24), 0
	push xwa
	ld xwa, 0x000006ca
	call SeGfx_StaticOp00_Line
	pop xwa
	ret
SeGfx_StaticOp02_FromBuf:
	; --- Wrapper function 5: same pattern ---
	ld	(COLORBLIT_MODE:24), 0
	push xwa
	ld xwa, 0x000006ca
	call SeGfx_StaticOp02_Line
	pop xwa
	ret
SeGfx_StaticOp03_BlitAtCell:
	; --- Wrapper function 6: set flag + store 4 regs, call ---
	ld	(COLORBLIT_MODE:24), 0
	push xwa
	ld	(1740:16), xiy
	ld	(1744:16), ix
	ld	(1746:16), bc
	ld	(1748:16), hl
	ld xwa, 0x000006ca
	call SeGfx_StaticOp03_Bitmap
	pop xwa
	ret
SeGfx_StaticOp05_FromBuf:
	; --- Wrapper function 7: same as 4/5 pattern ---
	ld	(COLORBLIT_MODE:24), 0
	push xwa
	ld xwa, 0x000006ca
	call SeGfx_StaticOp05_FillBoxMode1
	pop xwa
	ret
SeGfx_StaticOp06_Text:
	; --- Wrapper function 8: push xwa, ld xwa=xiy, call, pop, ret ---
	push xwa
	ld xwa, xiy
	call SeGfx_StaticOp06_CellTextFont0
	pop xwa
	ret
SeGfx_StaticOp07_Text:
	; --- Wrapper function 9 ---
	push xwa
	ld xwa, xiy
	call SeGfx_StaticOp07_CellTextFont1
	pop xwa
	ret
SeGfx_StaticOp09_FromBuf:
	; --- Wrapper function 10: set flag, push, ld xwa=imm, call, pop, ret ---
	ld	(COLORBLIT_MODE:24), 0
	push xwa
	ld xwa, 0x000006ca
	call SeGfx_StaticOp09_Box
	pop xwa
	ret
SeGfx_StaticOp0E:
	; --- Wrapper function 11 ---
	push xwa
	ld xwa, xiy
	call ColorBlit_ComputeRectAndBlit
	pop xwa
	ret
SeGfx_StaticOp15_FromBuf:
	; --- Wrapper function 12: set flag, push, ld xwa=imm, call, pop, ret ---
	ld	(COLORBLIT_MODE:24), 0
	push xwa
	ld xwa, 0x000006ca
	call SeGfx_StaticOp15_DottedLine
	pop xwa
	ret
SeGfx_StaticOp1B_FromBuf:
	; --- Wrapper function 13: set flag, push, ld xwa=imm, call, pop, ret ---
	ld	(COLORBLIT_MODE:24), 0
	push xwa
	ld xwa, 0x000006ca
	call ColorBlit_ByteData
	pop xwa
	ret
SeGfx_BoundOp00:
	; --- Wrapper function 14 ---
	push xwa
	ld xwa, xiy
	call DrawFunc_Init
	pop xwa
	ret
SeGfx_BoundOp02:
	; --- Wrapper function 15 ---
	push xwa
	ld xwa, xiy
	call DrawText_ExtendedLayout
	pop xwa
	ret
SeGfx_BoundOp03:
	; --- Wrapper function 16 ---
	push xwa
	ld xwa, xiy
	call ColorBlit_WithPaletteSave
	pop xwa
	ret
SeGfx_BoundOp06:
	; --- Wrapper function 17 ---
	push xwa
	ld xwa, xiy
	call SeGfx_BoundOp06_Helper
	pop xwa
	ret


SeMenu_NameEditor_End:
	cp	(SWBTWR_PAYLOAD_1:16), 4
	jr	nz, SeMenu_NameEditor_End_Code_Return
	ld	a, (SWBTWR_PAYLOAD_3:16)
	and	a, 64
	jr	z, SeMenu_NameEditor_End_Code_Return
	ld	a, (SWBTWR_PAYLOAD_2:16)
	and	a, 64
	sla	a, 1
	cp	(ACTIVE_TITLE:16), 33
	jr	nz, SeMenu_NameEditor_End_Skip
	ld	w, (1642:16)
	and	w, 127
	or	w, a
	ld	(1642:16), w
	call	SeMenu_NameEdit_CheckBit7
	jr	SeMenu_NameEditor_End_Code_Return
SeMenu_NameEditor_End_Skip:
	cp	(ACTIVE_TITLE:16), 58
	jr	nz, SeMenu_NameEditor_End_Code_Return
	ld	w, (1632:16)
	and	w, 127
	or	w, a
	ld	(1632:16), w
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x4C6D
	call	SeGfx_DrawBoundRecord
SeMenu_NameEditor_End_Code_Return:
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

SeMenu_DisplayPartValue_Data:
	push	xiz	; was .ascii ">89:;<="
	push	xwa
	push	xbc
	push	xde
	push	xhl
	push	xix
	push	xiy
	ld	wa, (xiz+8)
	cp	wa, 50
	jr	nz, SeMenu_DisplayPartValue_Data_Code_Skip
	ld	(1740:16), wa
	inc	1, wa
	ld	(1744:16), wa
	jr	SeMenu_DisplayPartValue_Data_Code_Join
SeMenu_DisplayPartValue_Data_Code_Skip:
	cp	wa, 50
	jr	nz, SeMenu_DisplayPartValue_Data_Code_Skip2
	ld	(1744:16), wa
	dec	1, wa
	ld	(1740:16), wa
	jr	SeMenu_DisplayPartValue_Data_Code_Join
SeMenu_DisplayPartValue_Data_Code_Skip2:
	dec	1, wa
	ld	(1740:16), wa
	inc	2, wa
	ld	(1744:16), wa
SeMenu_DisplayPartValue_Data_Code_Join:
	ld	wa, (xiz+10)
	cp	wa, 58
	jr	nz, SeMenu_DisplayPartValue_Data_Code_Skip3
	ld	(1742:16), wa
	inc	1, wa
	ld	(1746:16), wa
	jr	SeMenu_DisplayPartValue_Data_Code_Join2
SeMenu_DisplayPartValue_Data_Code_Skip3:
	cp	wa, 146
	jr	nz, SeMenu_DisplayPartValue_Data_Code_Skip4
	ld	(1746:16), wa
	dec	1, wa
	ld	(1742:16), wa
	jr	SeMenu_DisplayPartValue_Data_Code_Join2
SeMenu_DisplayPartValue_Data_Code_Skip4:
	dec	1, wa
	ld	(1742:16), wa
	inc	2, wa
	ld	(1746:16), wa
SeMenu_DisplayPartValue_Data_Code_Join2:
	ld	(COLORBLIT_MODE:24), 0
	call	SeGfx_StaticOp09_FromBuf
	pop	xiy
	pop	xix
	pop	xhl
	pop	xde
	pop	xbc
	pop	xwa
	pop	xiz
	ret
SeMenu_ApplyPartEdit_AltStore_Helper:
	push xiz
	ld	xiz, xsp
	push	xwa
	push	xbc
	push	xde
	push	xhl
	push	xix
	push	xiy
	ld	wa, (xiz+8)
	ld	(1740:16), wa
	ld	wa, (xiz+10)
	ld	(1742:16), wa
	ld	wa, (xiz+12)
	ld	(1744:16), wa
	ld	wa, (xiz+14)
	ld	(1746:16), wa
	ld	(COLORBLIT_MODE:24), 0
	call	SeGfx_StaticOp00_FromBuf
	pop	xiy
	pop	xix
	pop	xhl
	pop	xde
	pop	xbc
	pop	xwa
	pop	xiz
	ret
SeMenu_ApplyPartEdit_AltStore_Helper2:
	push	xiz
	ld	xiz, xsp
	push	xwa
	push	xbc
	push	xde
	push	xhl
	push	xix
	push	xiy
	ld	wa, (xiz+8)
	ld	(0x6cc:16), wa
	ld	wa, (xiz+10)
	ld	(1742:16), wa
	ld	wa, (xiz+12)
	ld	(1744:16), wa
	ld	wa, (xiz+14)
	ld	(1746:16), wa
	ld	(COLORBLIT_MODE:24), 0
	call	SeGfx_StaticOp15_FromBuf
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
	ld	xiy, (xiy+hl)
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

; -----------------------------------------------------------------------------
; Screen-handler table: 48 LE32 entries, one per event code 0x20-0x4F.
; Read by SeMenu_ShowPopupDialog: hl = (xiz+8) - 0x20, sla hl,2, xiy = (table+hl),
; call (xiy); then Display_DeferOrDrawWall before and Display_DeferOrUpdateScreen after the
; call (via SeMenu_WaveformSelect_Handler / _Process).  Entry count: the table ends where the next
; routine begins.  Entries 32-47 point at SeMenu_WaveformSelect_End, a bare
; `ret`: codes this screen set does not handle.  (Label name historical --
; shared/positional_labels.s builds aliases on it.)
; -----------------------------------------------------------------------------
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
	ld	xiy, (xiy+hl)
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


; -----------------------------------------------------------------------------
; Screen-handler table: 48 LE32 entries, one per event code 0x20-0x4F.
; Read by SeMenu_ShowConfirmDialog: hl = (xiz+8) - 0x20, sla hl,2, xiy = (table+hl),
; call (xiy); then `or (0xe3e2), 8`.  Entry count: the table ends where the next
; routine begins.  Entries 21, 29, 32-47 point at SeMenu_WaveformSelect_End, a bare
; `ret`: codes this screen set does not handle.  (Label name historical --
; shared/positional_labels.s builds aliases on it.)
; -----------------------------------------------------------------------------
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
; SeMenu_DrawSoloButton: Draws the sound editor's SOLO button (label and frame from SeScreenData_0x0833) lit when the
;   SOLO flag (0x65C) is set, unlit otherwise. Basis: callers + body -- called by SeMenu_ToggleSolo and by the page-
;   draw routines after their static lists.
SeMenu_DrawSoloButton:
	push	xwa
	push	xbc
	push	xde
	push	xhl
	push	xix
	push	xiy
	push	xiz
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x0833
	ld	xix, SeScreenData_0x085A
	call	SeGfx_DrawStaticList
	cp	(0x65c:16), 0
	jr	z, SeMenu_ShowConfirmDialog_Data_Code_Skip6
	ld	xiy, SeScreenData_0x085A
	ld	xix, SeScreenData_0x0864
	jr	SeMenu_ShowConfirmDialog_Data_Code_Join4
SeMenu_ShowConfirmDialog_Data_Code_Skip6:
	ld	(COLORBLIT_MODE:24), 1
	ld	xiy, SeScreenData_0x0864
	ld	xix, SeScreenData_0x086E
SeMenu_ShowConfirmDialog_Data_Code_Join4:
	call	SeGfx_DrawStaticList
	pop	xiz
	pop	xiy
	pop	xix
	pop	xhl
	pop	xde
	pop	xbc
	pop	xwa
	ret
; SeMenu_DrawPartSelector: Draws the part selector on the side rows: for each part (2 or 4, by (0x6AE)) its
;   "1ST".."4TH" label if enabled in mask (0x65E), a hatch pattern if not, then the highlight box around the selected
;   part (0x65D). Basis: callers + body -- page-draw routines call it right after SeMenu_DrawSoloButton.
SeMenu_DrawPartSelector:
	push	xwa
	push	xbc
	push	xde
	push	xhl
	push	xix
	push	xiy
	push	xiz
	cp	(0x6ae:16), 1
	jr	nz, SeMenu_ShowConfirmDialog_Data_Code_Skip
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x06DB
	ld	xix, SeScreenData_0x06DB + 10
	call	SeGfx_DrawStaticList
	ld	c, 2:opc
	jr	SeMenu_PresetManager_SaveApply_Helper_Join
SeMenu_ShowConfirmDialog_Data_Code_Skip:
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x06DB
	ld	xix, SeBitmap_Picture40x40
	call	SeGfx_DrawStaticList
	ld	c, 4:opc
SeMenu_PresetManager_SaveApply_Helper_Join:
	ld	w, (1630:16)
	ld	a, c
	sla	a, 1
	dec	1, a
	srla	w	; srl A,W
	jr	c, SeMenu_PresetManager_SaveApply_Helper_Skip
	push	c
	xor	b, b
	sla	bc, 2
	ld	xiz, SeScreenData_0x081B
	ld	xiy, (xiz+bc)
	add	bc, 4
	ld	xix, (xiz+bc)
	call	SeGfx_DrawStaticList
	pop	c
	jr	SeMenu_PresetManager_SaveApply_Helper_Join2
SeMenu_PresetManager_SaveApply_Helper_Skip:
	push	c
	xor	b, b
	sla	bc, 2
	ld	xiz, SeScreenData_0x07D3
	ld	xiy, (xiz+bc)
	add	bc, 4
	ld	xix, (xiz+bc)
	call	SeGfx_DrawStaticList
	pop	c
SeMenu_PresetManager_SaveApply_Helper_Join2:
	djnz8	c, -84
	ld	(COLORBLIT_MODE:24), 1
	ld	xiy, SeScreenData_0x086E
	ld	xix, SeScreenData_0x0878
	call	SeGfx_DrawStaticList
	ld	xiy, SeScreenData_0x0878
	call	SeGfx_BoundOp03
	pop	xiz
	pop	xiy
	pop	xix
	pop	xhl
	pop	xde
	pop	xbc
	pop	xwa
	ret
SeMenu_ApplyPartEdit_AltStore_Helper3:
	push	xiz
	ld	xiz, xsp
	push	xwa
	push	xbc
	push	xde
	push	xhl
	push	xix
	push	xiy
	ld	wa, (xiz+8)
	ld	(1740:16), wa
	ld	wa, (xiz+10)
	ld	(1742:16), wa
	ld	wa, (xiz+12)
	ld	(1744:16), wa
	ld	wa, (xiz+14)
	ld	(1746:16), wa
	ld	(COLORBLIT_MODE:24), 0
	call	SeGfx_StaticOp1B_FromBuf
	pop	xiy
	pop	xix
	pop	xhl
	pop	xde
	pop	xbc
	pop	xwa
	pop	xiz
	ret
SeMenu_CompareAndApply_Apply_Helper:
	ld	(COLORBLIT_MODE:24), 0
	ld	c, 7:opc
	ld	ix, (1734:16)
	ld	iy, (1736:16)
SeMenu_ShowConfirmDialog_Data_Code_Loop:
	pushw	ix
	pushw	iy
	push	c
	call	SeMenu_ShowConfirmDialog_Helper
	pop	c
	popw	iy
	popw	ix
	add	ix, 28
	dec	1, c
	jr	nz, SeMenu_ShowConfirmDialog_Data_Code_Loop
	ld	ix, (1734:16)
	ld	iy, (1736:16)
	ld	(1740:16), ix
	addw	(0x6cc:16), 196
	ld	(1744:16), ix
	addw	(0x6d0:16), 200
	ld	(1742:16), iy
	ld	(1746:16), iy
	addw	(0x6d2:16), 12
	call	SeGfx_StaticOp09_FromBuf
	ld	ix, (1734:16)
	ld	iy, (1736:16)
	add	ix, 196
	ld	(1740:16), ix
	ld	(1744:16), ix
	ld	(1742:16), iy
	subw	(0x6ce:16), 5
	ld	(1746:16), iy
	subw	(0x6d2:16), 1
	call	SeGfx_StaticOp09_FromBuf
	ld	ix, (1734:16)
	ld	iy, (1736:16)
	ld	(1740:16), ix
	subw	(0x6cc:16), 8
	ld	(0x6d0:16), ix
	ld	(1742:16), iy
	ld	(1746:16), iy
	addw	(0x6d2:16), 12
	call	SeGfx_StaticOp09_FromBuf
	ld	ix, (1734:16)
	ld	iy, (1736:16)
	ld	(1740:16), ix
	subw	(0x6cc:16), 5
	ld	(1744:16), ix
	subw	(0x6d0:16), 3
	ld	(1742:16), iy
	addw	(0x6ce:16), 1
	ld	(1746:16), iy
	addw	(0x6d2:16), 7
	call	SeGfx_StaticOp09_FromBuf
	ld	ix, (1734:16)
	ld	iy, (1736:16)
	sub	ix, 4
	ld	(1740:16), ix
	ld	(1744:16), ix
	ld	(1742:16), iy
	addw	(0x6ce:16), 1
	ld	(1746:16), iy
	addw	(0x6d2:16), 11
	call	SeGfx_StaticOp02_FromBuf
	ld	ix, (1734:16)
	ld	iy, (1736:16)
	ld	(1740:16), ix
	addw	(0x6cc:16), 28
	ld	(1744:16), ix
	addw	(0x6d0:16), 171
	ld	(1742:16), iy
	addw	(0x6ce:16), 13
	ld	(1746:16), iy
	addw	(0x6d2:16), 14
	call	SeGfx_StaticOp09_FromBuf
	ret
SeMenu_ShowConfirmDialog_Helper:
	ld	(1740:16), ix
	ld	(1744:16), ix
	ld	(1742:16), iy
	subw	(0x6ce:16), 5
	ld	(1746:16), iy
	subw	(0x6d2:16), 1
	pushw	ix
	pushw	iy
	call	SeGfx_StaticOp02_FromBuf
	popw	iy
	popw	ix
	ld	(1740:16), ix
	ld	(1742:16), iy
	ld	(1744:16), ix
	addw	(0x6d0:16), 28
	ld	(1746:16), iy
	addw	(0x6d2:16), 12
	pushw	ix
	pushw	iy
	call	SeGfx_StaticOp09_FromBuf
	popw	iy
	popw	ix
	ld	c, 5:opc
	ld	xiz, SeMenu_ShowConfirmDialog_Code
SeMenu_ShowConfirmDialog_Data_Code_Loop2:
	ld	hl, (xiz)
	ld	de, (xiz+2)
	add	xiz, 4
	ld	(1740:16), ix
	add	(0x6cc:16), hl
	ld	(1744:16), ix
	add	(0x6d0:16), de
	ld	(0x6ce:16), iy
	addw	(0x6ce:16), 1
	ld	(1746:16), iy
	addw	(0x6d2:16), 7
	push	c
	push	xiz
	pushw	ix
	pushw	iy
	call	SeGfx_StaticOp09_FromBuf
	popw	iy
	popw	ix
	pop	xiz
	pop	c
	dec	1, c
	jr	nz, SeMenu_ShowConfirmDialog_Data_Code_Loop2
	ld	c, 6:opc
SeMenu_ShowConfirmDialog_Helper_Loop:
	add	ix, 4
	ld	(1740:16), ix
	ld	(1744:16), ix
	ld	(1742:16), iy
	addw	(0x6ce:16), 1
	ld	(1746:16), iy
	addw	(0x6d2:16), 11
	push	c
	pushw	ix
	pushw	iy
	call	SeGfx_StaticOp02_FromBuf
	popw	iy
	popw	ix
	pop	c
	dec	1, c
	jr	nz, SeMenu_ShowConfirmDialog_Helper_Loop
	ret
SeMenu_ShowConfirmDialog_Code:
	pop	sr
	nop
	halt
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xF0F381-0xF0F392 (17 B), unreached CODE-territory, was disassembled as 13 plausible-but-dead instruction lines; per=100% dist=9 near SeMenu_ShowConfirmDialog_Code+3
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
SeMenu_ShowConfirmDialog_Sub:
	cp	(0x6ae:16), 1
	jr	nz, SeMenu_ShowConfirmDialog_Sub_Skip
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeMenu_ShowConfirmDialog_Sub_Data_2
	ld	xix, SeMenu_ShowConfirmDialog_Sub_Data_3
	call	SeGfx_DrawStaticList
	jr	SeMenu_ShowConfirmDialog_Sub_Join
SeMenu_ShowConfirmDialog_Sub_Skip:
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeMenu_ShowConfirmDialog_Sub_Data
	ld	xix, SeMenu_ShowConfirmDialog_Sub_Data_2
	call	SeGfx_DrawStaticList
SeMenu_ShowConfirmDialog_Sub_Join:
	xor	xwa, xwa
	ld	a, (1629:16)
	sla	wa, 2
	cp	(0x6ae:16), 1
	jr	nz, SeMenu_ShowConfirmDialog_Data_Code_Skip2
	ld	xiz, SeScreenData_0x1284
	jr	SeMenu_ShowConfirmDialog_Data_Code_Join
SeMenu_ShowConfirmDialog_Data_Code_Skip2:
	ld	xiz, SeScreenData_0x1270
SeMenu_ShowConfirmDialog_Data_Code_Join:
	push	xwa
	add	xiz, xwa
	ld	wa, (xiz)
	ld	(1734:16), wa
	ld	wa, (xiz+2)
	ld	(1736:16), wa
	cp	(0x6ae:16), 1
	jr	nz, SeMenu_ShowConfirmDialog_Data_Code_Skip3
	ld	xiz, 1634
	jr	SeMenu_ShowConfirmDialog_Data_Code_Join2
SeMenu_ShowConfirmDialog_Data_Code_Skip3:
	ld	xiz, 1640
SeMenu_ShowConfirmDialog_Data_Code_Join2:
	xor	xwa, xwa
	ld	a, (1629:16)
	add	xiz, xwa
	call	SeMenu_ShowConfirmDialog_Helper2
	pop	xwa
	cp	(0x6ae:16), 1
	jr	nz, SeMenu_ShowConfirmDialog_Data_Code_Skip4
	ld	xiz, SeScreenData_0x1264
	jr	SeMenu_ShowConfirmDialog_Data_Code_Join3
SeMenu_ShowConfirmDialog_Data_Code_Skip4:
	ld	xiz, SeScreenData_0x1250
SeMenu_ShowConfirmDialog_Data_Code_Join3:
	add	xiz, xwa
	ld	xiy, (xiz)
	ld	xix, xiy
	add	xix, 42
	call	SeGfx_DrawStaticList
	ret
SeMenu_ShowConfirmDialog_Helper2:
	ld	a, (xiz)
	and	a, 224
	srl	a, 5
	cp	a, 3:i3
	jr	nz, SeMenu_ShowConfirmDialog_Data_Code_Skip5
	ld	ix, (1734:16)
	ld	iy, (1736:16)
	ld	(1740:16), ix
	addw	(0x6cc:16), 1
	ld	(1744:16), ix
	addw	(0x6d0:16), 37
	ld	(1742:16), iy
	addw	(0x6ce:16), 1
	ld	(1746:16), iy
	addw	(0x6d2:16), 37
	call	SeGfx_StaticOp1B_FromBuf
	ld	ix, (1734:16)
	ld	iy, (1736:16)
	ld	(1740:16), ix
	addw	(0x6cc:16), 1
	ld	(1744:16), ix
	addw	(0x6d0:16), 38
	ld	(1742:16), iy
	addw	(0x6ce:16), 38
	ld	(1746:16), iy
	addw	(0x6d2:16), 1
	call	SeGfx_StaticOp00_FromBuf
	jr	SeMenu_ShowConfirmDialog_Data_Code_Return
SeMenu_ShowConfirmDialog_Data_Code_Skip5:
	ld	xiz, SeEnvCurve_BitmapTable
	xor	w, w
	sll	wa, 2
	ld	xiy, (xiz+wa)
	ldw_d16	wa, (0x6c6)
	div	a, 8
	xor	w, w
	ld	hl, (1736:16)
	mul	l, 40
	add	hl, wa
	ld	ix, hl
	ld	bc, 5:i3
	ldw	hl, 40
	call	SeGfx_StaticOp03_BlitAtCell
SeMenu_ShowConfirmDialog_Data_Code_Return:
	ret

; -----------------------------------------------------------------------------
; SeEnvCurve_BitmapTable -- 7 LE32 pointers to the 40x40 envelope-curve bitmaps
; in SeScreenData, indexed by bits 7-5 of the curve-type byte (`and a, 0xe0 / srl a,
; 5`).  Value 3 draws a framed box instead (ops 1B + 00), so entry 3 (the same bitmap
; as entry 6, 0xF10CAE) is never read by this reader; value 7 is not range-checked and would read
; past the table.  Read by the code just above: `ld xiz, table /
; sll 2,wa / ld xiy,(xiz+wa)`, then drawn with SeGfx_StaticOp03_BlitAtCell with
; BC = 5 bytes per row and HL = 40 rows (static ScreenData op 03 layout; the
; bitmaps are stored column by column -- see the SeScreenData header).
; Entry 0 was spelled `.byte 0x96 / rcf / .byte 0xf1 / nop` (a pointer framed as
; instructions); entries 1-6 were under the label SeMenu_WaveformSelect_Init,
; which nothing references and which named a routine -- removed.
; -----------------------------------------------------------------------------
SeEnvCurve_BitmapTable:
	.long SeBitmap_EnvCurve6
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
	ld	(COLORBLIT_MODE:24), 0
	ld	xiz, SeScreenData_0x46B4
	xor	xwa, xwa
	ld	a, (0x0340e4:24)
	sla	wa, 2
	add	xiz, xwa
	ld	xiy, (xiz)
	ld	xix, (xiz+4)
	call	SeGfx_DrawStaticList
	ld	xiy, SeScreenData_0x4447
	ld	xix, SeScreenData_0x4486
	call	SeGfx_DrawStaticList
	ret
SeMenu_WaveformSelect_Data:
	cp	(1720:16), 1
	jr	nz, SeMenu_WaveformSelect_Data_Skip
	call	SeMenu_WaveformSelect_Apply
	jr	SeMenu_WaveformSelect_Data_Return
SeMenu_WaveformSelect_Data_Skip:
	ld	(COLORBLIT_MODE:24), 0
	cp	(1710:16), 1
	jr	z, SeMenu_WaveformSelect_Data_Skip2
	ld	xiy, SeMenu_WaveformSelect_Apply_Data
	ld	xix, SeScreenData_0x0685
	call	SeGfx_DrawStaticList
	call	SeMenu_WaveformSelect_Apply_Helper
	jr	SeMenu_WaveformSelect_Data_Return
SeMenu_WaveformSelect_Data_Skip2:
	ld	xiy, SeScreenData_0x5120
	ld	xix, SeScreenData_0x53EC
	call	SeGfx_DrawStaticList
	call	SeMenu_WaveformSelect_Apply_Helper4
	ld	xiy, DrumDetailEdit_Entry_01
	ld	xix, SeScreenData_0x54EB
	call	SeGfx_DrawBoundList
	call	SeMenu_WaveformSelect_Apply_Helper2
	ld	(COLORBLIT_MODE:24), 1
	ld	xiy, SeScreenData_0x53EC
	ld	xix, DrumDetailEdit_Entry_01
	call	SeGfx_DrawStaticList
	ld	(COLORBLIT_MODE:24), 0
SeMenu_WaveformSelect_Data_Return:
	ret
SeMenu_WaveformSelect_Apply_Helper:
	ld	(COLORBLIT_MODE:24), 0
	cp	(0x661:16), 1
	jr	z, SeMenu_WaveformSelect_Data_Skip3
	ld	xiy, SeScreenData_0x0685
	ld	xix, SeScreenData_0x06B1
	call	SeGfx_DrawStaticList
	jr	SeMenu_WaveformSelect_Data_Return2
SeMenu_WaveformSelect_Data_Skip3:
	ld	xiy, SeScreenData_0x06B1
	ld	xix, SeScreenData_0x06DB
	call	SeGfx_DrawStaticList
SeMenu_WaveformSelect_Data_Return2:
	ret
SeMenu_WaveformSelect_Apply_Helper2:
	ld	(COLORBLIT_MODE:24), 0
	ld	a, 13:opc
SeMenu_WaveformSelect_Data_Loop:
	push_a
	call	SeMenu_WaveformSelect_Apply_Helper3
	pop_a
	inc	1, a
	cp	a, 15
	jr	c, SeMenu_WaveformSelect_Data_Loop
	ret
SeMenu_WaveformSelect_Apply_Helper3:
	xor	xbc, xbc
	xor	w, w
	extz	xwa
	ld	xbc, 1632
	add	xbc, xwa
	ld	d, (xbc)
	cp	d, 0:i3
	jr	z, SeMenu_WaveformSelect_Data_Return3
	ld	xiy, SeScreenData_0x5525
	ld	(COLORBLIT_MODE:24), 0
	call	SeGfx_DrawIndexedBoundRecord
SeMenu_WaveformSelect_Data_Return3:
	ret
SeMenu_PresetManager_Init:
	cp	(0x6ae:16), 1
	jr	z, SeMenu_PresetManager_Init_Skip
	call	SeMenu_WaveformSelect_Apply_Helper
	jrl	SeMenu_PresetManager_Init_Code_Return
SeMenu_PresetManager_Init_Skip:
	cp	a, 0:i3
	jr	z, SeMenu_PresetManager_Init_Skip2
	cp	a, 1:i3
	jr	z, SeMenu_PresetManager_Init_Skip3
	cp	a, 2:i3
	jr	z, SeMenu_PresetManager_Init_Skip4
	cp	a, 15
	jr	z, SeMenu_PresetManager_Init_Skip5
	cp	a, 16
	jrl	z, SeMenu_PresetManager_Init_Code_Skip
	cp	a, 13
	jrl	c, SeMenu_PresetManager_Init_Code_Skip2
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x54BE
	ld	xix, SeScreenData_0x54E0
	call	SeGfx_DrawBoundList
	call	SeMenu_WaveformSelect_Apply_Helper2
	jrl	SeMenu_PresetManager_Init_Code_Return
SeMenu_PresetManager_Init_Skip2:
	ld	(COLORBLIT_MODE:24), 1
	ld	xiy, SeScreenData_0x551B
	ld	xix, SeScreenData_0x5525
	call	SeGfx_DrawStaticList
	ld	a, 0:opc
	ld	xiy, SeScreenData_0x5525
	call	SeGfx_DrawIndexedBoundRecord
	ld	(COLORBLIT_MODE:24), 1
	ld	xiy, SeScreenData_0x53EC
	ld	xix, DrumDetailEdit_Entry_01
	call	SeGfx_DrawStaticList
	jr	SeMenu_PresetManager_Init_Code_Return
SeMenu_PresetManager_Init_Skip3:
	ld	xiy, DrumDetailEdit_Entry_01
	ld	xix, SeScreenData_0x54EB
	call	SeGfx_DrawBoundList
	call	SeMenu_WaveformSelect_Apply_Helper2
	jr	SeMenu_PresetManager_Init_Code_Return
SeMenu_PresetManager_Init_Skip4:
	call	SeMenu_WaveformSelect_Apply_Helper4
	jr	SeMenu_PresetManager_Init_Code_Return
SeMenu_PresetManager_Init_Skip5:
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, DrumDetailEdit_Entry_02
	ld	xix, DrumDetailEdit_Entry_03
	call	SeGfx_DrawBoundList
	jr	SeMenu_PresetManager_Init_Code_Return
SeMenu_PresetManager_Init_Code_Skip:
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, DrumDetailEdit_Entry_06
	ld	xix, DrumDetailEdit_Entry_07
	call	SeGfx_DrawBoundList
	jr	SeMenu_PresetManager_Init_Code_Return
SeMenu_PresetManager_Init_Code_Skip2:
	ld	xiy, SeScreenData_0x5525
	ld	(COLORBLIT_MODE:24), 0
	call	SeGfx_DrawIndexedBoundRecord
SeMenu_PresetManager_Init_Code_Return:
	ret
SeMenu_PresetManager_Load:
	; --- Wrapper 1: conditional XIY/XIX setup + call (28 bytes) ---
	ld	(COLORBLIT_MODE:24), 0
	cp	(1710:16), 1
	jr nz, SeMenu_PresetManager_End
	ld xiy, SeScreenData_0x5569
	ld xix, SeMenu_PresetManager_Load_Data
	call SeGfx_DrawStaticList
SeMenu_PresetManager_End:
	ret
SeMenu_PresetManager_Save:
	; --- Wrapper 2: XIY/XIX setup + 2 calls (25 bytes) ---
	ld	(COLORBLIT_MODE:24), 0
	ld xiy, SeScreenData_0x0558
	ld xix, SeMenu_WaveformSelect_Apply_Data
	call SeGfx_DrawStaticList
	call SeMenu_PresetManager_Save_Helper
	ret


SeMenu_PresetManager_SaveApply:
	call	SeMenu_PresetManager_SaveApply_Helper3
	call	SeMenu_PresetManager_Save
	ld	xiy, SeScreenData_0x09DA
	ld	xix, SeScreenData_0x0B7E
	call	SeGfx_DrawStaticList
	call	SeMenu_DrawSoloButton
	call	SeMenu_PresetManager_SaveApply_Helper2
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x1DCB
	ld	xix, SeScreenData_0x1ECE
	call	SeGfx_DrawBoundList
	call	SeMenu_PresetManager_SaveApply_Helper4
	ret
SeMenu_PresetManager_Data:
	call	SeMenu_PresetManager_SaveApply_Helper3
	cp	(0x6ae:16), 1
	jr	z, SeMenu_PresetManager_Data_Skip
	ld	xiy, SeScreenData_0x4256
	ld	xix, SeScreenData_0x441A
	call	SeGfx_DrawStaticList
	call	SeMenu_PresetManager_Save
	jr	SeMenu_PresetManager_Data_Join
SeMenu_PresetManager_Data_Skip:
	ld	xiy, SeScreenData_0x441A
	ld	xix, SeScreenData_0x4447
	call	SeGfx_DrawStaticList
	ld	xiy, SeScreenData_0x4261
	ld	xix, SeScreenData_0x441A
	call	SeGfx_DrawStaticList
SeMenu_PresetManager_Data_Join:
	call	SeMenu_DrawSoloButton
	call	SeMenu_DrawPartSelector
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x1F75
	ld	xix, SeScreenData_0x1F80
	call	SeGfx_DrawBoundList
	call	SeMenu_BankEdit_LoopHelper
	call	SeMenu_PresetManager_SaveApply_Helper4
	ret
; SeMenu_DrawPartLabels: Draws the part labels in the alternate side-row layout (y 79/111/143/175): "1ST".."4TH" for
;   parts enabled in (0x65E), a hatch pattern for disabled ones, 2 or 4 parts by (0x6AE); no selection box (unlike
;   SeMenu_DrawPartSelector). Basis: callers + body -- page-draw routines call it after SeMenu_DrawSoloButton.
SeMenu_DrawPartLabels:
	cp	(0x6ae:16), 1
	jr	nz, SeMenu_PresetManager_Data_Skip2
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x0B7E
	ld	xix, SeScreenData_0x0B7E + 10
	call	SeGfx_DrawStaticList
	ld	c, 2:opc
	jr	SeMenu_PresetBrowser_Init_Helper_Join
SeMenu_PresetManager_Data_Skip2:
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x0B7E
	ld	xix, SeScreenData_0x0B92
	call	SeGfx_DrawStaticList
	ld	c, 4:opc
SeMenu_PresetBrowser_Init_Helper_Join:
	ld	w, (1630:16)
	ld	a, c
	sla	a, 1
	dec	1, a
	srla	w	; srl A,W
	jr	c, SeMenu_PresetBrowser_Init_Helper_Skip
	push	c
	xor	b, b
	sla	bc, 2
	ld	xiz, SeScreenData_0x0BF6
	ld	xiy, (xiz+bc)
	add	bc, 4
	ld	xix, (xiz+bc)
	call	SeGfx_DrawStaticList
	pop	c
	jr	SeMenu_PresetBrowser_Init_Helper_Join2
SeMenu_PresetBrowser_Init_Helper_Skip:
	push	c
	xor	b, b
	sla	bc, 2
	ld	xiz, SeScreenData_0x0BAE
	ld	xiy, (xiz+bc)
	add	bc, 4
	ld	xix, (xiz+bc)
	call	SeGfx_DrawStaticList
	pop	c
SeMenu_PresetBrowser_Init_Helper_Join2:
	djnz8	c, -84
	ret
SeMenu_PresetManager_SaveApply_Helper2:
	ld	(COLORBLIT_MODE:24), 0
	cp	(0x6ae:16), 1
	jr	nz, SeMenu_PresetManager_SaveApply_Helper2_Skip
	ld	c, 2:opc
	jr	SeMenu_PresetManager_SaveApply_Helper2_Join
SeMenu_PresetManager_SaveApply_Helper2_Skip:
	ld	c, 4:opc
SeMenu_PresetManager_SaveApply_Helper2_Join:
	ld	w, (1630:16)
	ld	a, c
	sla	a, 1
	dec	1, a
	srla	w	; srl A,W
	jr	c, SeMenu_PresetManager_SaveApply_Helper2_Skip2
	push	c
	xor	b, b
	sla	bc, 2
	ld	xiz, SeScreenData_0x0CD2
	ld	xiy, (xiz+bc)
	add	bc, 4
	ld	xix, (xiz+bc)
	call	SeGfx_DrawStaticList
	pop	c
	jr	SeMenu_PresetManager_SaveApply_Helper2_Join2
SeMenu_PresetManager_SaveApply_Helper2_Skip2:
	push	c
	xor	b, b
	sla	bc, 2
	ld	xiz, SeScreenData_0x0C5A
	ld	xiy, (xiz+bc)
	add	bc, 4
	ld	xix, (xiz+bc)
	call	SeGfx_DrawStaticList
	pop	c
SeMenu_PresetManager_SaveApply_Helper2_Join2:
	djnz8	c, -84
	ret
SeMenu_WaveformSelect_Apply_Helper4:
	ld	(COLORBLIT_MODE:24), 0
	ld	c, 2:opc
	ld	w, (1630:16)
	ld	a, c
	sla	a, 1
	dec	1, a
	srla	w	; srl A,W
	jr	c, SeMenu_WaveformSelect_Apply_Helper4_Skip
	push	c
	xor	b, b
	sla	bc, 2
	ld	xiz, SeScreenData_0x0D4E
	ld	xiy, (xiz+bc)
	add	bc, 4
	ld	xix, (xiz+bc)
	call	SeGfx_DrawStaticList
	pop	c
	jr	SeMenu_WaveformSelect_Apply_Helper4_Join
SeMenu_WaveformSelect_Apply_Helper4_Skip:
	push	c
	xor	b, b
	sla	bc, 2
	ld	xiz, SeScreenData_0x0D14
	ld	xiy, (xiz+bc)
	add	bc, 4
	ld	xix, (xiz+bc)
	call	SeGfx_DrawStaticList
	pop	c
SeMenu_WaveformSelect_Apply_Helper4_Join:
	djnz8	c, -84
	ret
SeMenu_PresetManager_SaveApply_Helper3:
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x09AA
	ld	xix, SeScreenData_0x09D5
	call	SeGfx_DrawStaticList
	ret
SeMenu_PresetManager_SaveApply_Helper4:
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x09D5
	ld	xix, SeScreenData_0x09DA
	call	SeGfx_DrawStaticList
	ret
SeMenu_FxEdit_Init_Helper:
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x08D7
	ld	xix, SeScreenData_0x09AA
	call	SeGfx_DrawStaticList
	ld	(COLORBLIT_MODE:24), 0
	ret
SeMenu_PresetBrowser_Init:
	; --- Main: call sub, setup XIY/XIX, call F0EC00, 3 more calls (51 bytes) ---
	call SeMenu_PresetBrowser_Navigate
	ld xiy, SeMenu_PresetBrowser_Init_Data
	ld xix, SeScreenData_0x1043
	call SeGfx_DrawStaticList
	call SeMenu_DrawSoloButton
	call SeMenu_DrawPartLabels
	ld	(COLORBLIT_MODE:24), 0
	ld xiy, TuningSys_Param_01
	ld xix, SeScreenData_0x26B9
	call SeGfx_DrawBoundList
	call SeMenu_PresetBrowser_Select
	ret
SeMenu_PresetBrowser_Navigate:
	; --- Helper 1: clear flag, setup XIY/XIX, call F0EC00 (21 bytes) ---
	ld	(COLORBLIT_MODE:24), 0
	ld xiy, SeScreenData_0x0D5E
	ld xix, SeMenu_PresetBrowser_Navigate_Data
	call SeGfx_DrawStaticList
	ret
SeMenu_PresetBrowser_Select:
	; --- Helper 2: clear flag, setup XIY/XIX, call F0EC00 (21 bytes) ---
	ld	(COLORBLIT_MODE:24), 0
	ld xiy, SeMenu_PresetBrowser_Navigate_Data
	ld xix, SeMenu_PresetBrowser_Navigate_Data + 5
	call SeGfx_DrawStaticList
	ret


SeMenu_PresetBrowser_Data:
	call	SeMenu_PresetBrowser_Navigate
	call	SeMenu_PresetBrowser_Select
SeMenu_PresetBrowser_Select_Sub:
	ld	xiy, SeScreenData_0x3660
	ld	xix, SeScreenData_0x3805
	call	SeGfx_DrawStaticList
	call	SeMenu_PresetBrowser_Select_Helper
	call	SeMenu_DrawSoloButton
	call	SeMenu_PresetBrowser_Select_Helper2
	call	SeMenu_PresetBrowser_Select_Helper3
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x287D
	ld	xix, SeScreenData_0x28CE
	call	SeGfx_DrawBoundList
	ret
SeMenu_PresetBrowser_Select_Helper:
	ld	(COLORBLIT_MODE:24), 0
	ld	c, 4:opc
	ld	w, (1630:16)
	ld	a, c
	sla	a, 1
	dec	1, a
	srla	w	; srl A,W
	jr	c, SeMenu_PresetBrowser_Select_Helper_Skip
	push	c
	xor	b, b
	sla	bc, 2
	ld	xiz, SeMenu_PresetBrowser_Select_Sub_Data_2 + 12
	ld	xiy, (xiz+bc)
	add	bc, 4
	ld	xix, (xiz+bc)
	call	SeGfx_DrawStaticList
	pop	c
	jr	SeMenu_PresetBrowser_Select_Helper_Join
SeMenu_PresetBrowser_Select_Helper_Skip:
	push	c
	xor	b, b
	sla	bc, 2
	ld	xiz, SeMenu_PresetBrowser_Select_Sub_Data + 7
	ld	xiy, (xiz+bc)
	add	bc, 4
	ld	xix, (xiz+bc)
	call	SeGfx_DrawStaticList
	pop	c
SeMenu_PresetBrowser_Select_Helper_Join:
	djnz8	c, -84
	ret
SeMenu_PresetBrowser_Select_Helper2:
	ld	(COLORBLIT_MODE:24), 1
	ld	xiy, SeScreenData_0x296E
	ld	xix, SeScreenData_0x2978
	call	SeGfx_DrawStaticList
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x29BE
	ld	xix, SeScreenData_0x29C8
	call	SeGfx_DrawStaticList
	ld	xiy, SeScreenData_0x29C8
	ld	xix, SeScreenData_0x29D2
	call	SeGfx_DrawStaticList
	ld	(COLORBLIT_MODE:24), 2
	ld	xiy, SeScreenData_0x29C8
	ld	xix, SeScreenData_0x29D2
	call	SeGfx_DrawStaticList
	ld	c, 4:opc
	ld	xiy, 1637
SeMenu_PresetBrowser_Data_Loop:
	ld	w, (xiy)
	and	w, 32
	jrl	z, SeMenu_PresetBrowser_Data_Join
	push	w
	push	c
	push	xiy
	ld	d, 4:opc
	sub	d, c
	ld	e, d
	xor	d, d
	sla	de, 2
	ld	xiz, SeScreenData_0x29A0
	ld	xiy, (xiz+de)
	pushw de
	add	de, 4
	ld	xix, (xiz+de)
	call	SeGfx_DrawStaticList
	popw	de
	pop	xiy
	pop	c
	pop	w
	ld	(COLORBLIT_MODE:24), 0
	push	c
	push	xiy
	ld	xiz, SeScreenData_0x2B02
	ld	xiy, (xiz+de)
	ld xix, xiy
	add xix, 7
	pushw	de
	call	SeGfx_DrawStaticList
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
	ld	xiz, SeScreenData_0x2AD6
	ld	xiy, (xiz+de)
	extz xwa
	add	xiy, xwa
	ld	xix, xiy
	add	xix, 10
	pushw	de
	call	SeGfx_DrawStaticList
	popw	de
	pop	xiy
	pop	c
	push	c
	push	xiy
	ld	xiz, SeScreenData_0x2920
	ld	xiy, (xiz+de)
	pushw de
	call	SeGfx_DrawBoundRecord
	popw	de
	pop	xiy
	pop	c
	ld	(COLORBLIT_MODE:24), 2
	push	c
	push	xiy
	ld	xiz, SeMenu_PresetBrowser_Select_Sub_Data_2 + 36
	ld	xiy, (xiz+de)
	ld xix, xiy
	add xix, 20
	call	SeGfx_DrawStaticList
SeMenu_PresetBrowser_Data_Sub:
	pop	xiy
	pop	c
	jr	SeMenu_PresetBrowser_Data_Join
SeMenu_PresetBrowser_Data_Join:
	add	xiy, 1
	dec	1, c
	jrl	nz, SeMenu_PresetBrowser_Data_Loop
	ret
SeMenu_CompareAndApply_Init:
	; --- Main dispatch: language check, XIY/XIX setup, calls (111 bytes) ---
	call SeMenu_CompareAndApply_Data
	cp	(1710:16), 1
	jr z, SeMenu_CompareAndApply_Check
	call SeMenu_PresetManager_Save
	ld xiy, SeScreenData_0x1290
	ld xix, SeScreenData_0x137D
	call SeGfx_DrawStaticList
	jr t, SeMenu_CompareAndApply_Match
SeMenu_CompareAndApply_Check:
	ld xiy, SeMenu_PresetManager_Load_Data
	ld xix, SeScreenData_0x56CD
	call SeGfx_DrawStaticList
SeMenu_CompareAndApply_Match:
	call SeMenu_DrawSoloButton
	call SeMenu_DrawPartLabels
	call SeMenu_ShowConfirmDialog_Sub
	cp	(1710:16), 1
	jr z, SeMenu_CompareAndApply_Apply
	ld	(COLORBLIT_MODE:24), 0
	ld xiy, SeScreenData_0x238F
	ld xix, SeScreenData_0x241A
	call SeGfx_DrawBoundList
	jr t, SeMenu_CompareAndApply_End
SeMenu_CompareAndApply_Apply:
	ld	(COLORBLIT_MODE:24), 0
	ld xiy, SeScreenData_0x57A4
	ld xix, SeScreenData_0x57DB
	call SeGfx_DrawBoundList
SeMenu_CompareAndApply_End:
	call SeMenu_CompareAndApply_Data4
	ret
SeMenu_CompareAndApply_Data:
	; --- Init helper: language-conditional XIX setup (35 bytes) ---
	ld	(COLORBLIT_MODE:24), 0
	ld xiy, SeScreenData_0x1089
	cp	(1710:16), 1
	jr z, SeMenu_CompareAndApply_Data2
	ld xix, SeScreenData_0x113B
	jr t, SeMenu_CompareAndApply_Data3
SeMenu_CompareAndApply_Data2:
	ld xix, SeScreenData_0x1089 + 119
SeMenu_CompareAndApply_Data3:
	call SeGfx_DrawStaticList
	ret
SeMenu_CompareAndApply_Data4:
	; --- Tail helper: clear flag, setup XIY/XIX, call F0EC00 (21 bytes) ---
	ld	(COLORBLIT_MODE:24), 0
	ld xiy, SeScreenData_0x113B
	ld xix, SeMenu_ShowConfirmDialog_Sub_Data
	call SeGfx_DrawStaticList
	ret


SeMenu_CompareAndApply_Data5:
	call	SeMenu_DrawSoloButton
	call	SeMenu_DrawPartSelector
	.set	SeMenu_CompareAndApply_Data6, . + 2	; no instruction starts here: the name points 2 byte(s) into the one below
	call	SeMenu_CompareAndApply_Data
	call	SeMenu_PresetManager_Save
	ld	(COLORBLIT_MODE:24), 2
	ld	xiy, SeScreenData_0x1452
	ld	xix, SeScreenData_0x1466
	call	SeGfx_DrawStaticList
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x137D
	ld	xix, SeScreenData_0x1452
	call	SeGfx_DrawStaticList
	call	SeMenu_CompareAndApply_Data4
SeMenu_CompareAndApply_Apply_Sub:
	ldw	(1734:16), 56
	ldw	(1736:16), 139
	call	SeMenu_CompareAndApply_Apply_Helper
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x2480
	ld	xix, SeScreenData_0x24B8
	call	SeGfx_DrawBoundList
	ret
SeMenu_Utility_CopyBlock:
	call	SeMenu_CompareAndApply_Data
	cp	(1710:16), 1
	jr	z, SeMenu_Utility_CopyBlock_Skip
	ld	xiy, SeScreenData_0x1466
	ld	xix, SeScreenData_0x1523
	call	SeGfx_DrawStaticList
	call	SeMenu_Utility_CompareBlock_End
	ld	(COLORBLIT_MODE:24), 2
	ld	xiy, SeScreenData_0x1AEB
	ld	xix, SeScreenData_0x1AEB + 10
	call	SeGfx_DrawStaticList
	jr	SeMenu_Utility_CopyBlock_Join
SeMenu_Utility_CopyBlock_Skip:
	ld	xiy, SeScreenData_0x1466
	ld	xix, SeScreenData_0x1466 + 24
	call	SeGfx_DrawStaticList
	ld	xiy, SeScreenData_0x56CD
	ld	xix, SeScreenData_0x57A4
	call	SeGfx_DrawStaticList
SeMenu_Utility_CopyBlock_Join:
	call	SeMenu_DrawSoloButton
	call	SeMenu_DrawPartSelector
	ld	(COLORBLIT_MODE:24), 0
	cp	(0x6ae:16), 1
	jr	z, SeMenu_Utility_CopyBlock_Skip2
	ld	xiy, SeScreenData_0x24C8
	ld	xix, SeScreenData_0x250E
	call	SeGfx_DrawBoundList
	jr	SeMenu_Utility_CopyBlock_Join2
SeMenu_Utility_CopyBlock_Skip2:
	ld	xiy, SeScreenData_0x5811
	ld	xix, SeScreenData_0x5853
	call	SeGfx_DrawBoundList
	call	SeMenu_Utility_CopyBlock_Helper
SeMenu_Utility_CopyBlock_Join2:
	call	SeMenu_CompareAndApply_Data4
	ret
SeMenu_Utility_CopyBlock_Helper:
	ld	(COLORBLIT_MODE:24), 0
	ld	a, (1632:16)
	and	a, 32
	jr	z, SeMenu_Utility_CopyBlock_Skip3
	ld	xiy, SeScreenData_0x5873
	ld	xix, SeScreenData_0x5887
	call	SeGfx_DrawBoundList
	ld	(COLORBLIT_MODE:24), 2
	ld	xiy, SeScreenData_0x1AEB
	ld	xix, SeScreenData_0x1B01
	call	SeGfx_DrawStaticList
	jr	SeMenu_Utility_CopyBlock_Return
SeMenu_Utility_CopyBlock_Skip3:
	ld	xiy, SeScreenData_0x5887
	ld	xix, EffectParamEdit_Entry_01
	call	SeGfx_DrawStaticList
	ld	(COLORBLIT_MODE:24), 2
	ld	xiy, SeScreenData_0x1B01
	ld	xix, SeScreenData_0x1B0B
	call	SeGfx_DrawStaticList
SeMenu_Utility_CopyBlock_Return:
	ret
SeMenu_Utility_FillBlock:
	call	SeMenu_CompareAndApply_Data
	ld	xiy, SeScreenData_0x1523
	ld	xix, SeScreenData_0x166E
	call	SeGfx_DrawStaticList
	ld	(COLORBLIT_MODE:24), 2
	ld	xiy, SeScreenData_0x166E
	ld	xix, SeScreenData_0x1682
	call	SeGfx_DrawStaticList
	call	SeMenu_PresetManager_Save
	ldw	(1734:16), 56
	ldw	(1736:16), 139
	call	SeMenu_CompareAndApply_Apply_Helper
	call	SeMenu_DrawSoloButton
	call	SeMenu_DrawPartSelector
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x252A
	ld	xix, SeScreenData_0x259F
	call	SeGfx_DrawBoundList
	call	SeMenu_CompareAndApply_Data4
	ret
SeMenu_Utility_CompareBlock:
	; --- Main: init, 2x XIY/XIX setup, language branch, 3 calls (80 bytes) ---
	call SeMenu_Utility_SearchByte
	ld xiy, SeMenu_Utility_CompareBlock_Data_2
	ld xix, SeScreenData_0x18D8
	call SeGfx_DrawStaticList
	ld xiy, SeScreenData_0x18ED
	ld xix, SeMenu_Utility_CompareBlock_Data_3
	call SeGfx_DrawStaticList
	cp	(1710:16), 1
	jr z, SeMenu_Utility_CompareBlock_Loop
	call SeMenu_Utility_CompareBlock_End
SeMenu_Utility_CompareBlock_Loop:
	call SeMenu_DrawSoloButton
	call SeMenu_DrawPartSelector
	call SeMenu_Utility_FormatNumber_End
	ld	(COLORBLIT_MODE:24), 0
	ld xiy, SeScreenData_0x2160
	ld xix, SeScreenData_0x21C0
	call SeGfx_DrawBoundList
	call SeMenu_Utility_FormatNumber_Loop
	ret
SeMenu_Utility_CompareBlock_End:
	; --- Helper: XIY/XIX setup + call F0EC00, call F0F6F5 (19 bytes) ---
	ld xiy, SeMenu_Utility_CompareBlock_Data
	ld xix, SeMenu_Utility_CompareBlock_Data_2
	call SeGfx_DrawStaticList
	call SeMenu_PresetManager_Save
	ret
SeMenu_Utility_SearchByte:
	; --- Init: language-conditional XIX selection (35 bytes) ---
	ld	(COLORBLIT_MODE:24), 0
	cp	(1710:16), 1
	jr z, SeMenu_Utility_SearchByte_End
	ld xix, SeScreenData_0x173B
	jr t, SeMenu_Utility_FormatNumber
SeMenu_Utility_SearchByte_End:
	ld xix, SeScreenData_0x1682 + 38
SeMenu_Utility_FormatNumber:
	ld xiy, SeScreenData_0x1682
	call SeGfx_DrawStaticList
	ret
SeMenu_Utility_FormatNumber_Loop:
	; --- Tail: clear flag, XIY/XIX, call F0EC00 (21 bytes) ---
	ld	(COLORBLIT_MODE:24), 0
	ld xiy, SeScreenData_0x173B
	ld xix, SeScreenData_0x173B + 5
	call SeGfx_DrawStaticList
	ret
SeMenu_Utility_FormatNumber_End:
	; --- Data setup: load A, store, set flag=2, language-conditional XIX (58 bytes) ---
	ld	a, (CURRENT_TITLE:16)
	ld	(1656:16), a
	ld	(COLORBLIT_MODE:24), 2
	ld xiy, SeMenu_Utility_FormatNumber_Data_2
	cp	(1710:16), 1
	jr z, SeMenu_Utility_FormatNumber_Data
	ld xix, SeMenu_Utility_CompareBlock_Data
	jr t, SeMenu_Utility_FormatSigned
SeMenu_Utility_FormatNumber_Data:
	ld xix, SeMenu_Utility_FormatNumber_Data_2 + 24
SeMenu_Utility_FormatSigned:
	call SeGfx_DrawStaticList
	ld	(COLORBLIT_MODE:24), 0
	ld xiy, SeScreenData_0x212D
	call SeGfx_DrawBoundRecord
	ret


SeMenu_Utility_FormatSigned_Data:
	call	SeMenu_Utility_SearchByte
	ld	xiy, SeMenu_Utility_CompareBlock_Data_2
	ld	xix, SeScreenData_0x18D8
	call	SeGfx_DrawStaticList
	ld	xiy, SeScreenData_0x18D8
	ld	xix, SeScreenData_0x18ED
	call	SeGfx_DrawStaticList
	cp	(0x6ae:16), 1
	jr	z, SeMenu_Utility_FormatSigned_Data_Skip
	call	SeMenu_Utility_CompareBlock_End
SeMenu_Utility_FormatSigned_Data_Skip:
	call	SeMenu_DrawSoloButton
	call	SeMenu_DrawPartSelector
	call	SeMenu_Utility_FormatNumber_End
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x2160
	ld	xix, SeScreenData_0x21C0
	call	SeGfx_DrawBoundList
	call	SeMenu_Utility_FormatNumber_Loop
	ret
SeMenu_Utility_FormatPercent:
	call	SeMenu_Utility_SearchByte
	ld	xiy, SeMenu_Utility_CompareBlock_Data_3
	ld	xix, SeScreenData_0x1997
	call	SeGfx_DrawStaticList
	ld	xiy, SeScreenData_0x1997
	ld	xix, SeScreenData_0x19AB
	call	SeGfx_DrawStaticList
	cp	(0x6ae:16), 1
	jr	z, SeMenu_Utility_FormatPercent_Skip
	call	SeMenu_Utility_CompareBlock_End
SeMenu_Utility_FormatPercent_Skip:
	call	SeMenu_DrawSoloButton
	call	SeMenu_DrawPartSelector
	call	SeMenu_Utility_FormatNumber_End
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x221C
	ld	xix, SeScreenData_0x224F
	call	SeGfx_DrawBoundList
	call	SeMenu_Utility_FormatNumber_Loop
	ret
SeMenu_Utility_FormatPercent_Data:
	call	SeMenu_Utility_SearchByte
	ld	xiy, SeMenu_Utility_CompareBlock_Data_3
	ld	xix, SeScreenData_0x1997
	call	SeGfx_DrawStaticList
	ld	xiy, SeScreenData_0x19AB
	ld	xix, SeScreenData_0x19C0
	call	SeGfx_DrawStaticList
	cp	(0x6ae:16), 1
	jr	z, SeMenu_Utility_FormatPercent_Data_Skip
	call	SeMenu_Utility_CompareBlock_End
SeMenu_Utility_FormatPercent_Data_Skip:
	call	SeMenu_DrawSoloButton
	call	SeMenu_DrawPartSelector
	call	SeMenu_Utility_FormatNumber_End
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x221C
	ld	xix, SeScreenData_0x224F
	call	SeGfx_DrawBoundList
	call	SeMenu_Utility_FormatNumber_Loop
	ret
SeMenu_Utility_FormatHex:
	call	SeMenu_Utility_SearchByte
	ld	xiy, SeScreenData_0x19C0
	ld	xix, SeScreenData_0x1ACA
	call	SeGfx_DrawStaticList
	cp	(0x6ae:16), 1
	jr	z, SeMenu_Utility_FormatHex_Skip
	call	SeMenu_Utility_CompareBlock_End
SeMenu_Utility_FormatHex_Skip:
	call	SeMenu_DrawSoloButton
	call	SeMenu_DrawPartSelector
	call	SeMenu_Utility_FormatNumber_End
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x225F
	ld	xix, SeScreenData_0x22B0
	call	SeGfx_DrawBoundList
	call	SeMenu_Utility_FormatNumber_Loop
	ret
SeMenu_Utility_FormatHex_Data:
	call	SeMenu_Utility_SearchByte
	ld	xiy, SeScreenData_0x1ACA
	ld	xix, SeScreenData_0x1AE1
	call	SeGfx_DrawStaticList
	cp	(0x6ae:16), 1
	jr	z, SeMenu_Utility_FormatHex_Data_Skip
	call	SeMenu_Utility_CompareBlock_End
SeMenu_Utility_FormatHex_Data_Skip:
	call	SeMenu_DrawSoloButton
	call	SeMenu_DrawPartSelector
	call	SeMenu_Utility_FormatNumber_End
	call	SeMenu_Utility_FormatNumber_Loop
	ret
SeMenu_Utility_End:
	call	SeMenu_Utility_SearchByte
	ld	xiy, SeScreenData_0x1C2D
	ld	xix, SeScreenData_0x1C7A
	call	SeGfx_DrawStaticList
SeMenu_Utility_FormatHex_Sub:
	ld	xiy, SeScreenData_0x1B0B
	ld	xix, SeScreenData_0x1C2D
	call	SeGfx_DrawStaticList
	call	SeMenu_PresetManager_Save
	ld	(COLORBLIT_MODE:24), 2
	ld	xiy, SeScreenData_0x1AE1
	ld	xix, SeScreenData_0x1AEB + 10
	call	SeGfx_DrawStaticList
	call	SeMenu_DrawSoloButton
	call	SeMenu_DrawPartSelector
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x22C8
	ld	xix, SeScreenData_0x233D
	call	SeGfx_DrawBoundList
	call	SeMenu_Utility_FormatNumber_Loop
	ret
SeMenu_NameEdit_DataBlock1:
	ld	a, (1632:16)
	and	a, 15
	ld	(1648:16), a
	cp	a, 10
	jr	nz, SeMenu_NameEdit_DataBlock1_Skip
	ld	xiy, SeScreenData_0x47DB
	jr	SeMenu_NameEdit_DataBlock1_Join
SeMenu_NameEdit_DataBlock1_Skip:
	ld	xiy, SeScreenData_0x47BC
SeMenu_NameEdit_DataBlock1_Join:
	ld	xix, SeScreenData_0x48DB
	call	SeGfx_DrawStaticList
	xor	xwa, xwa
	ld	a, (1648:16)
	sla	wa, 3
	ld	xiz, SeScreenData_0x4BFE
	add	xiz, xwa
	ld	xiy, (xiz)
	ld	xix, (xiz+4)
	call	SeGfx_DrawStaticList
	ld	xiy, SeScreenData_0x46CC
	xor	xbc, xbc
	ld	xiz, SeScreenData_0x4ECB
	ld	c, (1648:16)
	sla	bc, 2
	ld	xix, (xiz+bc)
	call	SeGfx_DrawStaticList
	ld	a, (1648:16)
	cp	a, 10
	jr	nz, SeMenu_NameEdit_DataBlock1_Skip3
	ld	xiy, SeScreenData_0x479E
	jr	SeMenu_NameEdit_DataBlock1_Join3
SeMenu_NameEdit_DataBlock1_Skip3:
	ld	xiy, SeScreenData_0x4780
SeMenu_NameEdit_DataBlock1_Join3:
	ld	xix, SeScreenData_0x47BC
	call	SeGfx_DrawStaticList
	ld	xiy, SeScreenData_0x4C5E
	ld	a, (1648:16)
	cp	a, 10
	jr	nz, SeMenu_NameEdit_DataBlock1_Skip2
	ld	xix, FlashRead_BlockData_Field7
	jr	SeMenu_NameEdit_DataBlock1_Join2
SeMenu_NameEdit_DataBlock1_Skip2:
	ld	xix, SeScreenData_ListBounds
SeMenu_NameEdit_DataBlock1_Join2:
	call	SeGfx_DrawBoundList
	xor	xwa, xwa
	ld	a, (1648:16)
	sla	wa, 3
	ld	xiz, SeScreenData_ListBounds
	add	xiz, xwa
	ld	xiy, (xiz)
	ld	xix, (xiz+4)
	call	SeGfx_DrawBoundList
	ret
SeMenu_NameEdit_DataBlock2:
	ld	xiy, SeScreenData_0x4FA3
	ld	xix, SeScreenData_0x5120
	call	SeGfx_DrawStaticList
	ld	xiy, EffectParamEdit_Entry_01
	ld	xix, SeScreenData_0x58F1
	call	SeGfx_DrawBoundList
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
	ld	(COLORBLIT_MODE:24), 1
	ld xiy, SeScreenData_0x5999
	ld xix, SeScreenData_0x59A3
	call SeGfx_DrawStaticList
	ld a, 0x00:opc
SeMenu_NameEdit_DefaultPath:
	ld	(COLORBLIT_MODE:24), 0
	ld xiy, EffectParam_Edit_Table
	call SeGfx_DrawIndexedBoundRecord
SeMenu_NameEdit_Return:
	ret
SeMenu_NameEdit_CheckBit7:
	; --- Helper: conditional XIY based on bit 7 of (0x066a) (32 bytes) ---
	ld	(COLORBLIT_MODE:24), 0
	ld	a, (1642:16)
	and a, 0x80
	jr nz, SeMenu_NameEdit_Bit7Set
	ld xiy, SeScreenData_0x5900
	jr t, SeMenu_NameEdit_HandleInput
SeMenu_NameEdit_Bit7Set:
	ld xiy, SeScreenData_0x58F1
SeMenu_NameEdit_HandleInput:
	call SeGfx_DrawBoundRecord
	ret


SeMenu_PatchEdit_DataBlock:
	cp	a, 0:i3
	jr	z, SeMenu_PatchEdit_DataBlock_Skip
	cp	a, 7:i3
	jr	nc, SeMenu_PatchEdit_DataBlock_Skip2
	xor	xbc, xbc
	ld	xiz, SeScreenData_0x4E9B
	ld	c, (1648:16)
	sla	bc, 2
	ld	xiy, (xiz+bc)
	jr SeMenu_PatchEdit_DataBlock_Join
SeMenu_PatchEdit_DataBlock_Skip:
	ld	xiy, SeScreenData_0x4C6D
	ld	xix, FlashRead_BlockData_Field8
	call	SeGfx_DrawBoundList
	jr	SeMenu_PatchEdit_DataBlock_Return
SeMenu_PatchEdit_DataBlock_Skip2:
	ld	xiy, SeScreenData_0x4D89
SeMenu_PatchEdit_DataBlock_Join:
	ld	(COLORBLIT_MODE:24), 0
	call	SeGfx_DrawIndexedBoundRecord
SeMenu_PatchEdit_DataBlock_Return:
	ret
SeMenu_PatchEdit_Dispatch:
	; --- Dispatch on A: table lookup, 4 paths (92 bytes) ---
	cp	a, 0:i3
	jr z, SeMenu_PatchEdit_SetupPath
	cp	a, 1:i3
	jr z, SeMenu_PatchEdit_CallHelper
	cp a, 0x0e
	jr c, SeMenu_PatchEdit_DefaultPath
	ld xiy, SeScreenData_0x1EF7
	extz xwa
	xor w, w
	sla	wa, 2
	add xiy, xwa
	ld xiz, xiy
	ld xiy, (xiz)
	ld xix, (xiz+4)
	ld	(COLORBLIT_MODE:24), 0
	call SeGfx_DrawBoundList
	jr t, SeMenu_PatchEdit_Return
SeMenu_PatchEdit_SetupPath:
	ld	(COLORBLIT_MODE:24), 1
	ld xiy, SeScreenData_0x1F43
	ld xix, SeScreenData_0x1F4D
	call SeGfx_DrawStaticList
	ld a, 0x00:opc
	jr t, SeMenu_PatchEdit_DefaultPath
SeMenu_PatchEdit_CallHelper:
	call SeMenu_PresetManager_SaveApply_Helper2
	jr t, SeMenu_PatchEdit_Return
SeMenu_PatchEdit_DefaultPath:
	ld xiy, SeScreenData_0x1EF7
	ld	(COLORBLIT_MODE:24), 0
	call SeGfx_DrawIndexedBoundRecord
SeMenu_PatchEdit_Return:
	ret


SeMenu_BankEdit_Dispatch:
	; --- Dispatcher: A==0 path with XIY/XIX setup + loop subroutine (187 bytes) ---
	cp	a, 0:i3
	jr z, SeMenu_BankEdit_SetupPath
	call SeMenu_BankEdit_LoopHelper
	jr t, SeMenu_BankEdit_Return
SeMenu_BankEdit_SetupPath:
	ld	(COLORBLIT_MODE:24), 1
	ld xiy, SeScreenData_0x20FB
	ld xix, SeScreenData_0x2105
	call SeGfx_DrawStaticList
	ld xiy, SeScreenData_0x1F75
	call SeGfx_DrawBoundRecord
SeMenu_BankEdit_Return:
	ret
SeMenu_BankEdit_LoopHelper:
	; --- Loop over 3 entries: indexed XIY/XIX pointer table lookups ---
	ld	(COLORBLIT_MODE:24), 0
	ld xiy, SeMenu_BankEdit_LoopHelper_Data_2
	ld xix, SeMenu_BankEdit_LoopHelper_Data_3
	call SeGfx_DrawStaticList
	ld xiy, SeScreenData_0x1F80
	ld xix, SeMenu_BankEdit_LoopHelper_Data
	call SeGfx_DrawBoundList
	ld c, 0x00:opc
	ld xiz, 0x00000664
SeMenu_BankEdit_LoopBody:
	push c
	push xiz
	cp (xiz), 0x00
	jr z, SeMenu_BankEdit_EmptyEntry
	ld xiy, SeMenu_BankEdit_LoopBody_Data + 20
	extz xbc
	xor b, b
	sla	bc, 2
	add xiy, xbc
	ld xiy, (xiy)
	ld xix, xiy
	add xix, 0x00000032
	push xbc
	call SeGfx_DrawBoundList
	pop xbc
	ld xiy, SeMenu_BankEdit_LoopBody_Data + 44
	add xiy, xbc
	ld xiy, (xiy)
	ld xix, xiy
	add xix, 0x00000005
	call SeGfx_DrawStaticList
	jr t, SeMenu_BankEdit_LoopContinue
SeMenu_BankEdit_EmptyEntry:
	ld xiy, SeMenu_BankEdit_LoopBody_Data + 32
	extz xbc
	xor b, b
	sla	bc, 2
	add xiy, xbc
	ld xiy, (xiy)
	ld xix, xiy
	add xix, 0x00000014
	call SeGfx_DrawStaticList
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
	jr	z, SeMenu_DrumKit_Dispatch_Skip
	cp	a, 13
	jr	z, SeMenu_DrumKit_Dispatch_Skip2
	cp	a, 16
	jr	nz, SeMenu_DrumKit_Dispatch_Join
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeMenu_DrumKit_Dispatch_Data
	ld	xix, SeMenu_DrumKit_Dispatch_Data_2
	call	SeGfx_DrawBoundList
	jr	SeMenu_DrumKit_Dispatch_Return
SeMenu_DrumKit_Dispatch_Skip:
	ld	(COLORBLIT_MODE:24), 1
	ld	xiy, SeScreenData_0x2829
	ld	xix, SeScreenData_0x2833
	call	SeGfx_DrawStaticList
	ld	a, 0:opc
	jr	SeMenu_DrumKit_Dispatch_Join
SeMenu_DrumKit_Dispatch_Skip2:
	ld	(COLORBLIT_MODE:24), 1
	ld	xiy, SeScreenData_0x2833
	ld	xix, SeScreenData_0x283D
	call	SeGfx_DrawStaticList
	ld	a, 13:opc
SeMenu_DrumKit_Dispatch_Join:
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x283D
	call	SeGfx_DrawIndexedBoundRecord
SeMenu_DrumKit_Dispatch_Return:
	ret
Data_UnknownBlock:
	cp	a, 0:i3
	jr	z, Data_UnknownBlock_Skip8
	cp	a, 3:i3
	jr	z, Data_UnknownBlock_Skip
	cp	a, 4:i3
	jr z, Data_UnknownBlock_Skip2
	cp a, 5:i3
	jr	nc, Data_UnknownBlock_Skip9
	jr	Data_UnknownBlock_Join2
Data_UnknownBlock_Skip8:
	ld	(COLORBLIT_MODE:24), 1
	ld	xiy, SeScreenData_0x2964
	ld	xix, SeScreenData_0x296E
	call	SeGfx_DrawStaticList
	call	SeMenu_PresetBrowser_Select_Helper3
	jr	Data_UnknownBlock_Return
Data_UnknownBlock_Skip:
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x28AA
	ld	xix, SeScreenData_0x28C3
	call	SeGfx_DrawBoundList
	jr	Data_UnknownBlock_Return
Data_UnknownBlock_Skip2:
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x287D
	ld	xix, SeScreenData_0x2896
	call	SeGfx_DrawBoundList
	jr	Data_UnknownBlock_Return
Data_UnknownBlock_Skip9:
	call	SeMenu_PresetBrowser_Select_Helper2
	jr	Data_UnknownBlock_Return
Data_UnknownBlock_Join2:
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x290C
	call	SeGfx_DrawIndexedBoundRecord
Data_UnknownBlock_Return:
	ret
SeMenu_PresetBrowser_Select_Helper3:
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x29B4
	ld	xix, SeScreenData_0x29BE
	call	SeGfx_DrawStaticList
	ld	c, (1632:16)
	xor	b, b
	sla	bc, 2
	ld	xiz, SeScreenData_0x2A22
	ld	xiy, (xiz+bc)
	ld xix, xiy
	add xix, 20
	call	SeGfx_DrawStaticList
	ret
SeMenu_DataBlock_01:
	cp	(0x6ae:16), 1
	jr	nz, Data_UnknownBlock_Skip10
	cp	a, 3:i3
	jr	c, Data_UnknownBlock_Skip11
	jr	Data_UnknownBlock_Join3
Data_UnknownBlock_Skip10:
	cp	a, 9
	jr	c, Data_UnknownBlock_Skip11
Data_UnknownBlock_Join3:
	push_a
	call	SeMenu_ShowConfirmDialog_Sub
	pop_a
	jr	Data_UnknownBlock_Join5
Data_UnknownBlock_Skip11:
	cp	a, 0:i3
	jr	nz, Data_UnknownBlock_Join5
	call	SeMenu_ShowConfirmDialog_Sub
	cp	(0x6ae:16), 1
	jr	z, Data_UnknownBlock_Skip12
	ld	(COLORBLIT_MODE:24), 1
	ld	xiy, SeScreenData_0x244E
	ld	xix, SeScreenData_0x2458
	jr	Data_UnknownBlock_Join4
Data_UnknownBlock_Skip12:
	ld	(COLORBLIT_MODE:24), 1
	ld	xiy, SeScreenData_0x57EF
	ld	xix, SeScreenData_0x57F9
Data_UnknownBlock_Join4:
	call	SeGfx_DrawStaticList
	ld	a, 0:opc
Data_UnknownBlock_Join5:
	ld	(COLORBLIT_MODE:24), 0
	cp	(0x6ae:16), 1
	jr	z, Data_UnknownBlock_Skip13
	ld	xiy, SeScreenData_0x241A
	jr	Data_UnknownBlock_Join6
Data_UnknownBlock_Skip13:
	ld	xiy, SeScreenData_0x57DB
Data_UnknownBlock_Join6:
	call	SeGfx_DrawIndexedBoundRecord
	ret
SeMenu_DataBlock_02:
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x24B8
	call	SeGfx_DrawIndexedBoundRecord
	ret
SeMenu_DataBlock_03:
	cp	(0x6ae:16), 1
	jr	z, Data_UnknownBlock_Skip14
	ld	xiy, SeScreenData_0x250E
	jr	Data_UnknownBlock_Join7
Data_UnknownBlock_Skip14:
	cp	a, 0:i3
	jr	nz, Data_UnknownBlock_Skip15
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x5853
	call	SeGfx_DrawIndexedBoundRecord
	call	SeMenu_Utility_CopyBlock_Helper
	jr	Data_UnknownBlock_Return5
Data_UnknownBlock_Skip15:
	ld	xiy, SeScreenData_0x5853
Data_UnknownBlock_Join7:
	ld	(COLORBLIT_MODE:24), 0
	call	SeGfx_DrawIndexedBoundRecord
Data_UnknownBlock_Return5:
	ret
SeMenu_DataBlock_04:
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x25B7
	call	SeGfx_DrawIndexedBoundRecord
	ret
SeMenu_DataBlock_05:
	cp	a, 5:i3
	jr	nz, Data_UnknownBlock_Skip3
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeMenu_DataBlock_05_Data
	ld	xix, SeScreenData_0x21C0
	call	SeGfx_DrawBoundList
	jr	Data_UnknownBlock_Return2
Data_UnknownBlock_Skip3:
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x21C0
	call	SeGfx_DrawIndexedBoundRecord
Data_UnknownBlock_Return2:
	ret
SeMenu_DataBlock_06:
	cp	a, 5:i3
	jr	nz, Data_UnknownBlock_Skip4
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeMenu_DataBlock_05_Data
	ld	xix, SeScreenData_0x21C0
	call	SeGfx_DrawBoundList
	jr	Data_UnknownBlock_Return3
Data_UnknownBlock_Skip4:
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x21C0
	call	SeGfx_DrawIndexedBoundRecord
Data_UnknownBlock_Return3:
	ret
SeMenu_DataBlock_07:
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x224F
	call	SeGfx_DrawIndexedBoundRecord
	ret
SeMenu_DataBlock_08:
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x224F
	call	SeGfx_DrawIndexedBoundRecord
	ret
SeMenu_DataBlock_09:
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x22B0
	call	SeGfx_DrawIndexedBoundRecord
	ret
SeMenu_DataBlock_10:
	cp	a, 0:i3
	jr	nz, Data_UnknownBlock_Skip5
	ld	(COLORBLIT_MODE:24), 1
	ld	xiy, SeScreenData_0x234F
	ld	xix, SeScreenData_0x2363
	call	SeGfx_DrawStaticList
	ld	a, 0:opc
Data_UnknownBlock_Skip5:
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x2363
	call	SeGfx_DrawIndexedBoundRecord
	ret
SeMenu_DataBlock_11:
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x2B12
	ld	xix, SeScreenData_0x2C0A
	call	SeGfx_DrawStaticList
	ld	xiy, SeScreenData_0x2C0A
	ld	xix, SeScreenData_0x2C32
	call	SeGfx_DrawBoundList
	call	SeMenu_DataBlock_11_Helper
	ret
SeMenu_DataBlock_11_Helper:
	ld	l, (1632:16)
	cp	l, 1:i3
	jr	z, Data_UnknownBlock_Skip6
	ld	l, 17:opc
	jr	Data_UnknownBlock_Join
Data_UnknownBlock_Skip6:
	ld	l, 16:opc
Data_UnknownBlock_Join:
	ld	(0x90ea:16), l
	ld	h, (1633:16)
	dec	1, h
	ld	(0x90eb:16), h
	ld	a, (PART_SELECT:16)
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
Data_UnknownBlock_Join8:
	cp	d, 16
	jr	z, Data_UnknownBlock_Skip7
	push	xwa
	push	xbc
	push	d
	call	SeMenu_CopyWriteUpdate_Step3_Helper18
	pop	d
	pop	xbc
	pop	xwa
	add	xwa, 1
	add	xbc, 1
	add	d, 1
	jr	Data_UnknownBlock_Join8
Data_UnknownBlock_Skip7:
	pop	d
	pop	xbc
	pop	xwa
	ld	(xiy-3), c
	ld	(xiy-2), ix
	sub	xiy, 4
	call	SeGfx_StaticOp07_Text
	ret
SeMenu_DataBlock_12:
	ld	(COLORBLIT_MODE:24), 0
	cp	(0x6ae:16), 1
	jr	z, Data_UnknownBlock_Skip16
	ld	xiy, SeScreenData_0x2C35
	ld	xix, SeScreenData_0x2C57
	call	SeGfx_DrawStaticList
Data_UnknownBlock_Skip16:
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x2C57
	ld	xix, SeScreenData_0x2E3A
	call	SeGfx_DrawStaticList
	jr	Data_UnknownBlock_Join9
	ld	xiy, SeScreenData_0x2C83
	ld	xix, SeScreenData_0x2E3A
	call	SeGfx_DrawStaticList
Data_UnknownBlock_Join9:
	cp	(0x662:16), 16
	jr	z, Data_UnknownBlock_Skip25
	cp	(0x662:16), 2
	jr	z, Data_UnknownBlock_Skip17
	ld	xiy, SeScreenData_0x2E44
	ld	xix, SeScreenData_0x2E4E
	call	SeGfx_DrawStaticList
	ld	xiy, SeScreenData_0x2E74
	ld	xix, SeScreenData_0x2E90
	call	SeGfx_DrawBoundList
	call	SeMenu_DataBlock_12_Helper
	jr	Data_UnknownBlock_Return6
Data_UnknownBlock_Skip25:
	ld	xiy, SeScreenData_0x2E3A
	ld	xix, SeScreenData_0x2E44
	call	SeGfx_DrawStaticList
	ld	xiy, SeScreenData_0x2E58
	ld	xix, SeScreenData_0x2E74
	call	SeGfx_DrawBoundList
	call	SeMenu_DataBlock_12_Helper
	jr	Data_UnknownBlock_Return6
Data_UnknownBlock_Skip17:
	ld	xiy, SeScreenData_0x2E4E
	ld	xix, SeScreenData_0x2E58
	call	SeGfx_DrawStaticList
	ld	xiy, SeScreenData_0x2E90
	ld	xix, SeScreenData_0x2EAC
	call	SeGfx_DrawBoundList
	call	SeMenu_DataBlock_12_Helper
Data_UnknownBlock_Return6:
	ret
SeMenu_DataBlock_13:
	ld	xiy, SeScreenData_0x2C0A
	ld	xix, SeScreenData_0x2C32
	call	SeGfx_DrawBoundList
	call	SeMenu_DataBlock_11_Helper
	ret
SeMenu_DataBlock_14:
	cp	a, 0:i3
	jr	z, Data_UnknownBlock_Skip21
	cp	a, 1:i3
	jr	z, Data_UnknownBlock_Skip18
	cp	a, 2:i3
	jr	z, Data_UnknownBlock_Skip22
Data_UnknownBlock_Skip18:
	ld	(COLORBLIT_MODE:24), 1
	ld	xiy, SeScreenData_0x2EB6
	ld	xix, SeScreenData_0x2EC0
	call	SeGfx_DrawStaticList
	ld	(COLORBLIT_MODE:24), 0
	cp	(0x662:16), 13
	jr	z, Data_UnknownBlock_Skip19
	cp	(0x662:16), 2
	jr	z, Data_UnknownBlock_Skip20
	ld	xiy, SeScreenData_0x2E58
	ld	xix, SeScreenData_0x2E74
	jr	Data_UnknownBlock_Join10
Data_UnknownBlock_Skip19:
	ld	xiy, SeScreenData_0x2E74
	ld	xix, SeScreenData_0x2E90
	jr	Data_UnknownBlock_Join10
Data_UnknownBlock_Skip20:
	ld	xiy, SeScreenData_0x2E90
	ld	xix, SeScreenData_0x2EAC
Data_UnknownBlock_Join10:
	call	SeGfx_DrawBoundList
	call	SeMenu_DataBlock_12_Helper
	jr	Data_UnknownBlock_Return4
Data_UnknownBlock_Skip21:
	ld	(COLORBLIT_MODE:24), 1
	ld	xiy, SeScreenData_0x2EAC
	ld	xix, SeScreenData_0x2EC0
	call	SeGfx_DrawStaticList
	ld	xiy, SeScreenData_0x2E69
	call	SeGfx_DrawBoundRecord
	call	SeMenu_DataBlock_12_Helper
	jr	Data_UnknownBlock_Return4
Data_UnknownBlock_Skip22:
	ld	(COLORBLIT_MODE:24), 1
	ld	xiy, SeScreenData_0x2EAC
	ld	xix, SeScreenData_0x2EC0
	call	SeGfx_DrawStaticList
	ld	(COLORBLIT_MODE:24), 0
	cp	(0x662:16), 13
	jr	z, Data_UnknownBlock_Skip23
	cp	(0x662:16), 2
	jr	z, Data_UnknownBlock_Skip24
	ld	xiy, SeScreenData_0x2E58
	ld	xix, SeScreenData_0x2E74
	call	SeGfx_DrawBoundList
	jr	Data_UnknownBlock_Join11
Data_UnknownBlock_Skip23:
	ld	xiy, SeScreenData_0x2E74
	ld	xix, SeScreenData_0x2E90
	call	SeGfx_DrawBoundList
	jr	Data_UnknownBlock_Join11
Data_UnknownBlock_Skip24:
	ld	xiy, SeScreenData_0x2E90
	ld	xix, SeScreenData_0x2EAC
	call	SeGfx_DrawBoundList
Data_UnknownBlock_Join11:
	call	SeMenu_DataBlock_12_Helper
Data_UnknownBlock_Return4:
	ret
SeMenu_DataBlock_12_Helper:
	xor	wa, wa
	ld	a, (1633:16)
	div	a, 16
	ld	xiz, SeScreenData_0x2F40
	xor	hl, hl
	ld	l, w
	sla	hl, 1
	ld	ix, (xiz+hl)
	ld (1740:16), ix
	add	ix, 8
	ld	(1744:16), ix
	ld	xiz, SeScreenData_0x2F60
	xor	hl, hl
	ld	l, a
	sla	hl, 1
	ld	ix, (xiz+hl)
	ld (1742:16), ix
	add	ix, 14
	ld	(1746:16), ix
	call	SeGfx_StaticOp05_FromBuf
	ret
SeMenu_PresetInit_Main:
	; --- Main: init, XIY/XIX setup, 2 loops, 9 calls (63 bytes) ---
	call SeMenu_PresetManager_SaveApply_Helper3
	call SeMenu_PresetManager_Save
	ld xiy, SeScreenData_0x336C
	ld xix, SeScreenData_0x34E9
	call SeGfx_DrawStaticList
	call SeMenu_DrawSoloButton
	call SeMenu_DrawPartLabels
	ld	(COLORBLIT_MODE:24), 0
	ld xiy, SeScreenData_0x38E1
	ld xix, SeMenu_PresetInit_Main_Data
	call SeGfx_DrawBoundList
	call SeMenu_PresetInit_Loop1
	call SeMenu_PresetInit_Loop2
	call SeMenu_PresetManager_SaveApply_Helper4
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
	ld xiy, SeScreenData_0x3A3A
	ld	(COLORBLIT_MODE:24), 0
	call SeGfx_DrawIndexedBoundRecord
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
	ld xiy, SeScreenData_0x39BE
	ld	(COLORBLIT_MODE:24), 0
	call SeGfx_DrawIndexedBoundRecord
SeMenu_PresetInit_Lookup2Return:
	ret


SeMenu_FxEdit_Init:
	call	SeMenu_FxEdit_Init_Helper
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeMenu_FxEdit_Init_Data
	ld	xix, SeMenu_FxEdit_Init_Data_2
	call	SeGfx_DrawStaticList
	ld	(COLORBLIT_MODE:24), 2
	ld	xiy, SeScreenData_0x34E9
	ld	xix, SeMenu_FxEdit_Init_Data
	call	SeGfx_DrawStaticList
	ldw	(1734:16), 47
	ldw	(1736:16), 51
	call	SeMenu_CompareAndApply_Apply_Helper
	call	SeMenu_DrawSoloButton
	call	SeMenu_DrawPartSelector
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x3AB0
	ld	xix, SeScreenData_0x3AF7
	call	SeGfx_DrawBoundList
	ret
SeMenu_FxEdit_DataBlock1:
	call	SeMenu_FxEdit_Init_Helper
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeMenu_FxEdit_Init_Data_2
	ld	xix, SeScreenData_0x3633
	call	SeGfx_DrawStaticList
	ld	(COLORBLIT_MODE:24), 2
	ld	xiy, SeScreenData_0x34E9
	ld	xix, SeMenu_FxEdit_Init_Data
	call	SeGfx_DrawStaticList
	call	SeMenu_DrawSoloButton
	call	SeMenu_DrawPartSelector
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x3B3D
	ld	xix, SeScreenData_0x3B70
	call	SeGfx_DrawBoundList
	ret
SeMenu_FxEdit_DataBlock2:
	call	SeMenu_PresetBrowser_Navigate
	ld	xiy, SeScreenData_0x1043
	ld	xix, SeScreenData_0x1089
	call	SeGfx_DrawStaticList
	call	SeMenu_PresetManager_Save
	call	SeMenu_Utility_FormatHex_Sub
	call	SeMenu_PresetBrowser_Select
	ret
SeMenu_FxEdit_DataBlock3:
	call	SeMenu_PresetBrowser_Navigate
	call	SeMenu_FilterEdit_Init_Sub
	call	SeMenu_PresetBrowser_Select
	ret
SeMenu_FxEdit_DataBlock4:
	call	SeMenu_Utility_SearchByte
	ld	xiy, SeScreenData_0x137D
	ld	xix, SeScreenData_0x137D + 180
	call	SeGfx_DrawStaticList
	ld	(COLORBLIT_MODE:24), 2
	ld	xiy, SeScreenData_0x1452
	ld	xix, SeScreenData_0x1466
	call	SeGfx_DrawStaticList
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x3633
	ld	xix, SeScreenData_0x3660
	call	SeGfx_DrawStaticList
	call	SeMenu_PresetManager_Save
	call	SeMenu_CompareAndApply_Apply_Sub
	call	SeMenu_Utility_FormatNumber_Loop
	ret
SeMenu_FilterEdit_Init:
	call	SeMenu_Utility_SearchByte
SeMenu_FilterEdit_Init_Sub:
	ld	xiy, SeScreenData_0x1C7A
	ld	xix, SeScreenData_0x1DB7
	call	SeGfx_DrawStaticList
	ld	(COLORBLIT_MODE:24), 2
	ld	xiy, SeScreenData_0x1DB7
	ld	xix, SeScreenData_0x1DCB
	call	SeGfx_DrawStaticList
	call	SeMenu_PresetManager_Save
	ldw	(1734:16), 56
	ldw	(1736:16), 139
	call	SeMenu_CompareAndApply_Apply_Helper
	call	SeMenu_DrawSoloButton
	call	SeMenu_DrawPartSelector
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x3B84
	ld	xix, SeScreenData_0x3BDB
	call	SeGfx_DrawBoundList
	call	SeMenu_Utility_FormatNumber_Loop
	ret
SeMenu_FilterEdit_DataBlock1:
	call	SeMenu_Utility_SearchByte
	call	SeMenu_PresetBrowser_Select_Sub
	call	SeMenu_Utility_FormatNumber_Loop
	ret
SeMenu_FilterEdit_DataBlock2:
	call	SeMenu_CompareAndApply_Data
	call	SeMenu_PresetBrowser_Select_Sub
	call	SeMenu_CompareAndApply_Data4
	ret
SeMenu_FilterEdit_Dispatch:
	cp a, 0:i3
	jr z, SeMenu_FilterEdit_Dispatch_Skip2
	cp	a, 1:i3
	jr	z, SeMenu_FilterEdit_Dispatch_Skip
	cp	a, 11
	jr	c, SeMenu_FilterEdit_Dispatch_Skip3
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeMenu_FilterEdit_Dispatch_Data_2
	ld	xix, SeMenu_FilterEdit_Dispatch_Data_3
	call	SeGfx_DrawBoundList
	call	SeMenu_PresetInit_Loop2
	jr	SeMenu_FilterEdit_Dispatch_Return
SeMenu_FilterEdit_Dispatch_Skip:
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x38E1
	ld	xix, SeMenu_FilterEdit_Dispatch_Data
	call	SeGfx_DrawBoundList
	call	SeMenu_PresetInit_Loop1
	jr	SeMenu_FilterEdit_Dispatch_Return
SeMenu_FilterEdit_Dispatch_Skip2:
	ld	(COLORBLIT_MODE:24), 1
	ld	xiy, SeScreenData_0x3A7E
	ld	xix, SeScreenData_0x3A88
	call	SeGfx_DrawStaticList
	ld	a, 0:opc
SeMenu_FilterEdit_Dispatch_Skip3:
	ld	xiy, SeScreenData_0x39BE
	ld	(COLORBLIT_MODE:24), 0
	call	SeGfx_DrawIndexedBoundRecord
SeMenu_FilterEdit_Dispatch_Return:
	ret
SeMenu_FilterEdit_AltDispatch:
	cp	a, 0:i3
	jr	nz, SeMenu_FilterEdit_AltDispatch_Skip
	ld	(COLORBLIT_MODE:24), 1
	ld	xiy, SeScreenData_0x3B0B
	ld	xix, SeScreenData_0x3B15
	call	SeGfx_DrawStaticList
	ld	a, 0:opc
SeMenu_FilterEdit_AltDispatch_Skip:
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x3AF7
	call	SeGfx_DrawIndexedBoundRecord
	ret
SeMenu_FilterEdit_DataBlock3:
	cp	a, 0:i3
	jr	nz, SeMenu_FilterEdit_DataBlock3_Skip
	ld	(COLORBLIT_MODE:24), 1
	ld	xiy, SeScreenData_0x3B0B
	ld	xix, SeScreenData_0x3B15
	call	SeGfx_DrawStaticList
	ld	a, 0:opc
SeMenu_FilterEdit_DataBlock3_Skip:
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x3B70
	call	SeGfx_DrawIndexedBoundRecord
	ret
SeMenu_FilterEdit_DataBlock4:
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x3BDB
	call	SeGfx_DrawIndexedBoundRecord
	ret
SeMenu_FilterEdit_DataBlock5:
	call	SeMenu_EqEdit_SetupHelper1
	cp	(0x6ae:16), 1
	jr	z, SeMenu_FilterEdit_DataBlock5_Skip
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeMenu_FilterEdit_DataBlock5_Data
	ld	xix, SeScreenData_0x3D17
	call	SeGfx_DrawStaticList
	call	SeMenu_Utility_CompareBlock_End
	jr	SeMenu_FilterEdit_DataBlock5_Join2
SeMenu_FilterEdit_DataBlock5_Skip:
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeMenu_FilterEdit_DataBlock5_Data
	ld	xix, SeMenu_FilterEdit_DataBlock5_Data + 175
	call	SeGfx_DrawStaticList
	ld	xiy, SeScreenData_0x3D17
	ld	xix, SeScreenData_0x3D36
	call	SeGfx_DrawStaticList
	ld	xiy, SeMenu_FilterEdit_DataBlock5_Data_2
	jr	SeMenu_FilterEdit_DataBlock5_Join
SeMenu_FilterEdit_DataBlock5_Join2:
	ld	xiy, SeScreenData_0x3DD3
SeMenu_FilterEdit_DataBlock5_Join:
	ld	(COLORBLIT_MODE:24), 0
	ld	xix, SeScreenData_0x3E60
	call	SeGfx_DrawBoundList
	call	SeMenu_EqEdit_SetupHelper2
	ret
SeMenu_EqEdit_Init:
	; --- Main: call helpers, setup XIY/XIX pairs, call F0EC00/F0EC0D (53 bytes) ---
	call SeMenu_EqEdit_SetupHelper1
	call SeMenu_PresetManager_Save
	ld	(COLORBLIT_MODE:24), 0
	ld xiy, SeScreenData_0x3D36
	ld xix, SeScreenData_0x3DD3
	call SeGfx_DrawStaticList
	ld	(COLORBLIT_MODE:24), 0
	ld xiy, SeScreenData_0x4222
	ld xix, SeScreenData_0x4240
	call SeGfx_DrawBoundList
	call SeMenu_EqEdit_SetupHelper2
	ret
SeMenu_EqEdit_SetupHelper1:
	; --- Helper 1: clear flag, setup XIY/XIX, call F0EC00 (21 bytes) ---
	ld	(COLORBLIT_MODE:24), 0
	ld xiy, SeScreenData_0x3C03
	ld xix, SeMenu_EqEdit_SetupHelper1_Data
	call SeGfx_DrawStaticList
	ret
SeMenu_EqEdit_SetupHelper2:
	; --- Helper 2: clear flag, setup XIY/XIX, call F0EC00 (21 bytes) ---
	ld	(COLORBLIT_MODE:24), 0
	ld xiy, SeMenu_EqEdit_SetupHelper1_Data
	ld xix, SeMenu_FilterEdit_DataBlock5_Data
	call SeGfx_DrawStaticList
	ret


SeMenu_EqEdit_Dispatch:
	; --- Dispatch on A: 4 paths with language branching (99 bytes) ---
	cp	a, 0:i3
	jr z, SeMenu_EqEdit_SetupPath
	cp a, 0x0b
	jr z, SeMenu_EqEdit_SetConstA
	cp a, 0x0c
	jr nz, SeMenu_EqEdit_DefaultPath
	ld	(COLORBLIT_MODE:24), 0
	cp	(1710:16), 1
	jr z, SeMenu_EqEdit_DrawTable
	ld xiy, SeScreenData_0x3DD3
	ld xix, SeMenu_FilterEdit_DataBlock5_Data_2
	call SeGfx_DrawBoundList
SeMenu_EqEdit_DrawTable:
	ld xiy, SeMenu_EqEdit_DrawTable_Data
	ld xix, SeMenu_EqEdit_DrawTable_Data_2
	call SeGfx_DrawBoundList
	jr t, SeMenu_EqEdit_Return
SeMenu_EqEdit_SetupPath:
	ld	(COLORBLIT_MODE:24), 1
	ld xiy, SeScreenData_0x41CC
	ld xix, SeScreenData_0x41EA
	call SeGfx_DrawStaticList
	ld a, 0x00:opc
	jr t, SeMenu_EqEdit_DefaultPath
SeMenu_EqEdit_SetConstA:
	ld a, 0x07:opc
SeMenu_EqEdit_DefaultPath:
	ld	(COLORBLIT_MODE:24), 0
	ld xiy, SeScreenData_0x3E60
	call SeGfx_DrawIndexedBoundRecord
SeMenu_EqEdit_Return:
	ret


SeMenu_EqEdit_DrawInit:
	ld	(COLORBLIT_MODE:24), 0
	ld	xiy, SeScreenData_0x4222
	ld	xix, SeScreenData_0x4240
	call	SeGfx_DrawBoundList
	ret
; SeGfx_DrawIndexedBoundRecord: Draws bound ScreenData record number A of the pointer table at XIY: XIY = table[A],
;   then SeGfx_DrawBoundRecord. Basis: callers + body -- all 25 call sites load XIY with a SeScreenData_* pointer
;   table (and A with an index) right before the call.
SeGfx_DrawIndexedBoundRecord:
	extz	xwa
	xor	w, w
	sla	wa, 2
	add	xiy, xwa
	ld	xiy, (xiy)
	call	SeGfx_DrawBoundRecord
	ret
	push	xwa
	push	xbc
	push	xde
	push	xhl
	push	xix
	push	xiy
	push	xiz
	pop	xiz
	pop	xiy
	pop	xix
	pop	xhl
	pop	xde
	pop	xbc
	pop	xwa
	ret
; -----------------------------------------------------------------------------
; ScreenData record macros (lane seui 2026-09-25).  One macro = one record =
; {u8 op, u8 len, payload}; the layouts are the reads the interpreter's own
; handlers make (se_gfx_wrappers_probe.py / se_screendata_model.py):
;  static (GraphicsRender_ProcessEntries, 36-entry table):
;   sd_quad   op, a, b, c, d   len 10, four u16 at +2/+4/+6/+8 (ops 00 01 02 05
;                              09 0A 11 12 13 15 1B 22: two corner points)
;   sd_ctext  op, len, cell, text   u16 +2 = y*40 + x/8, written Y*40+C below
;                              (the handler divides by 40: y = cell/40 pixel
;                              rows, x = 8*(cell%40)); text = len-4 bytes
;                              (ops 06 07 08 20)
;   sd_ptext  op, len, x, y, text   u16 +2 = x, u16 +4 = y in pixels, text =
;                              len-6 bytes (ops 17 1C)
;   sd_blit   bitmap, cell, bpr, rows   op 03 len 12: u32 +2 1-bpp bitmap,
;                              u16 +6 cell, u16 +8 bytes per row, u16 +10 rows
;   sd_op23   style, cell      op 23 len 5: u8 +2, u16 +3 cell
;   sd_rec    op, len, bytes...     any other static record, payload verbatim
;  bound (GraphicsRender_Start, 12-entry table): value = (RAM[ram] & mask) >>
;  (shift & 15), then:
;   sdb_num   ram, mask, shift, style, cell, digits      op 00 len 10
;   sdb_snum  ram, mask, shift, style, cell, digits, zero op 05 len 11: prints
;                              value-zero with a '+'/'-' sign
;   sdb_str   ram, mask, shift, style, table, width, cell      op 02 len 15:
;                              `width` chars of table[value*width] at cell
;   sdb_strxy ram, mask, shift, style, table, width, x, y      op 07 len 17
;   sdb_box   op, ram, mask, shift, b6, table   ops 03/04/08 len 11: u32 +7
;                              -> table of {x1,y1,x2,y2} u16 boxes, [value]
; -----------------------------------------------------------------------------
.macro sd_quad op, a, b, c, d
	.byte \op, 10
	.short \a, \b, \c, \d
.endm
.macro sd_ctext op, len, cell, text:vararg
	.byte \op, \len
	.short \cell
	.ascii \text
.endm
.macro sd_ptext op, len, x, y, text:vararg
	.byte \op, \len
	.short \x, \y
	.ascii \text
.endm
.macro sd_blit bitmap, cell, bpr, rows
	.byte 0x03, 12
	.long \bitmap
	.short \cell, \bpr, \rows
.endm
.macro sd_op23 style, cell
	.byte 0x23, 5, \style
	.short \cell
.endm
.macro sd_rec op, len, bytes:vararg
	.byte \op, \len, \bytes
.endm
.macro sdb_num ram, mask, shift, style, cell, digits
	.byte 0x00, 10
	.short \ram
	.byte \mask, \shift, \style
	.short \cell
	.byte \digits
.endm
.macro sdb_snum ram, mask, shift, style, cell, digits, zero
	.byte 0x05, 11
	.short \ram
	.byte \mask, \shift, \style
	.short \cell
	.byte \digits, \zero
.endm
.macro sdb_str ram, mask, shift, style, table, width, cell
	.byte 0x02, 15
	.short \ram
	.byte \mask, \shift, \style
	.long \table
	.short \width, \cell
.endm
.macro sdb_strxy ram, mask, shift, style, table, width, x, y
	.byte 0x07, 17
	.short \ram
	.byte \mask, \shift, \style
	.long \table
	.short \width, \x, \y
.endm
.macro sdb_box op, ram, mask, shift, b6, table
	.byte \op, 11
	.short \ram
	.byte \mask, \shift, \b6
	.long \table
.endm
; =============================================================================
; SeScreenData -- the sound editor's screen-layout block (19617 bytes up to
; SeScreenData_End).  Everything in it is read by the ScreenData interpreters
; in display/graphics_text_vga.s through the SeGfx_* wrappers, or by the
; sound-editor code directly; the model that pins every object -- which code
; loads which address, which list parses exactly to its stated end, which
; pointer field names which table -- is scripts/lanes/seui/se_screendata_model.py
; (run it to see the evidence for any object).  Rendered from that model by
; scripts/lanes/seui/se_screendata_render.py (lane seui, 2026-09-25); until then
; the tree spelled this block as instructions (v10/v9) or verbatim ROM slices
; (v7).  Labels are SeScreenData_0xNNNN = offset from SeScreenData, identical
; in v10, v9 and v7.  The byte-exact C screen descriptors (`.incbin` of
; includes/generated/se_*.bin) inside the block are earlier lanes' work and
; are kept as they were.
; =============================================================================
; (The 2026-09 data-as-code census flagged 34 spans in this block as unreached code; all of
; them are typed screen data now, so its per-span notes were removed on 2026-10-02.)
SeScreenData:
; 1-bpp bitmap 24x10 px, stored column by column (3 byte-columns of 10 rows;
; bit 7 is tested first), drawn by static op 03 via ColorBlit2_LargeCodeBlock
; evidence: static op03 record at SeScreenData_0x07EB, static op03 record at SeScreenData_0x0BC6, static op03 record at SeScreenData_0x0C7E, static op03 record at SeScreenData_0x3839
SeBitmap_Pattern24x10_1:
	; column 0 (x 0-7)
	.byte	0b00001000
	.byte	0b00010000
	.byte	0b00101000
	.byte	0b00010000
	.byte	0b00001000
	.byte	0b00010000
	.byte	0b00001000
	.byte	0b00010000
	.byte	0b00101000
	.byte	0b00010100
	; column 1 (x 8-15)
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00101010
	.byte	0b01010101
	.byte	0b00100000
	.byte	0b01010100
	.byte	0b00101010
	.byte	0b00000001
	.byte	0b00101010
	.byte	0b01010100
	; column 2 (x 16-23)
	.byte	0b00001000
	.byte	0b00010000
	.byte	0b00101010
	.byte	0b01010100
	.byte	0b00001000
	.byte	0b00010000
	.byte	0b00001000
	.byte	0b00010000
	.byte	0b00001000
	.byte	0b00000100
; 1-bpp bitmap 24x10 px, stored column by column (3 byte-columns of 10 rows;
; bit 7 is tested first), drawn by static op 03 via ColorBlit2_LargeCodeBlock
; evidence: static op03 record at SeScreenData_0x07F7, static op03 record at SeScreenData_0x0BD2, static op03 record at SeScreenData_0x0C96, static op03 record at SeScreenData_0x3845
SeBitmap_Pattern24x10_2:
	; column 0 (x 0-7)
	.byte	0b00101010
	.byte	0b01010101
	.byte	0b00100010
	.byte	0b00000001
	.byte	0b00000010
	.byte	0b00000100
	.byte	0b00001000
	.byte	0b00010000
	.byte	0b00101010
	.byte	0b01010101
	; column 1 (x 8-15)
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00101010
	.byte	0b01010101
	.byte	0b00100010
	.byte	0b01000001
	.byte	0b00100010
	.byte	0b01000001
	.byte	0b00100010
	.byte	0b01000001
	; column 2 (x 16-23)
	.byte	0b00000010
	.byte	0b00000001
	.byte	0b00000010
	.byte	0b00010101
	.byte	0b00101010
	.byte	0b01000001
	.byte	0b00100010
	.byte	0b01000001
	.byte	0b00101010
	.byte	0b00010101
; 1-bpp bitmap 24x10 px, stored column by column (3 byte-columns of 10 rows;
; bit 7 is tested first), drawn by static op 03 via ColorBlit2_LargeCodeBlock
; evidence: static op03 record at SeScreenData_0x0803, static op03 record at SeScreenData_0x0BDE, static op03 record at SeScreenData_0x0CAE, static op03 record at SeScreenData_0x3851
SeBitmap_Pattern24x10_3:
	; column 0 (x 0-7)
	.byte	0b00101010
	.byte	0b01010101
	.byte	0b00100010
	.byte	0b00000001
	.byte	0b00001010
	.byte	0b00000100
	.byte	0b00000010
	.byte	0b01000001
	.byte	0b00101010
	.byte	0b00010100
	; column 1 (x 8-15)
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00101010
	.byte	0b01010101
	.byte	0b00100000
	.byte	0b01000000
	.byte	0b00100000
	.byte	0b01000000
	.byte	0b00100000
	.byte	0b01000000
	; column 2 (x 16-23)
	.byte	0b00000010
	.byte	0b00000001
	.byte	0b00000010
	.byte	0b00010101
	.byte	0b00101010
	.byte	0b01000001
	.byte	0b00100010
	.byte	0b01000001
	.byte	0b00101010
	.byte	0b00010101
; 1-bpp bitmap 24x10 px, stored column by column (3 byte-columns of 10 rows;
; bit 7 is tested first), drawn by static op 03 via ColorBlit2_LargeCodeBlock
; evidence: static op03 record at SeScreenData_0x080F, static op03 record at SeScreenData_0x0BEA, static op03 record at SeScreenData_0x0CC6, static op03 record at SeMenu_PresetBrowser_Select_Sub_Data_2
SeBitmap_Pattern24x10_4:
	; column 0 (x 0-7)
	.byte	0b00000100
	.byte	0b00001010
	.byte	0b00010100
	.byte	0b00001010
	.byte	0b00010100
	.byte	0b00100010
	.byte	0b01010101
	.byte	0b00101010
	.byte	0b00000100
	.byte	0b00000010
	; column 1 (x 8-15)
	.byte	0b00010000
	.byte	0b00001000
	.byte	0b01010100
	.byte	0b00101010
	.byte	0b00010000
	.byte	0b00001000
	.byte	0b00010000
	.byte	0b00001000
	.byte	0b00010100
	.byte	0b00001000
	; column 2 (x 16-23)
	.byte	0b01000000
	.byte	0b00100000
	.byte	0b01000000
	.byte	0b00101010
	.byte	0b01010101
	.byte	0b00100010
	.byte	0b01000001
	.byte	0b00100010
	.byte	0b01000001
	.byte	0b00100010
; 1-bpp bitmap 16x12 px, stored column by column (2 byte-columns of 12 rows;
; bit 7 is tested first), drawn by static op 03 via ColorBlit2_LargeCodeBlock
; evidence: static op03 record at SeScreenData_0x0C0E, static op03 record at SeScreenData_0x0C21, static op03 record at SeScreenData_0x0C34, static op03 record at SeScreenData_0x0C47 (+2 more)
SeBitmap_RadioOn:
	; column 0 (x 0-7)
	.byte	0b00000111
	.byte	0b00011000
	.byte	0b00100000
	.byte	0b00100111
	.byte	0b01001111
	.byte	0b01001111
	.byte	0b01001111
	.byte	0b01001111
	.byte	0b00100111
	.byte	0b00100000
	.byte	0b00011000
	.byte	0b00000111
	; column 1 (x 8-15)
	.byte	0b10000000
	.byte	0b01100000
	.byte	0b00010000
	.byte	0b10010000
	.byte	0b11001000
	.byte	0b11001000
	.byte	0b11001000
	.byte	0b11001000
	.byte	0b10010000
	.byte	0b00010000
	.byte	0b01100000
	.byte	0b10000000
; 1-bpp bitmap 16x12 px, stored column by column (2 byte-columns of 12 rows;
; bit 7 is tested first), drawn by static op 03 via ColorBlit2_LargeCodeBlock
; evidence: static op03 record at SeScreenData_0x0C72, static op03 record at SeScreenData_0x0C8A, static op03 record at SeScreenData_0x0CA2, static op03 record at SeScreenData_0x0CBA (+2 more)
SeBitmap_RadioOff:
	; column 0 (x 0-7)
	.byte	0b00000111
	.byte	0b00011000
	.byte	0b00100000
	.byte	0b00100000
	.byte	0b01000000
	.byte	0b01000000
	.byte	0b01000000
	.byte	0b01000000
	.byte	0b00100000
	.byte	0b00100000
	.byte	0b00011000
	.byte	0b00000111
	; column 1 (x 8-15)
	.byte	0b10000000
	.byte	0b01100000
	.byte	0b00010000
	.byte	0b00010000
	.byte	0b00001000
	.byte	0b00001000
	.byte	0b00001000
	.byte	0b00001000
	.byte	0b00010000
	.byte	0b00010000
	.byte	0b01100000
	.byte	0b10000000
; 1-bpp bitmap 40x40 px, stored column by column (5 byte-columns of 40 rows;
; bit 7 is tested first), drawn by static op 03 via ColorBlit2_LargeCodeBlock
; evidence: curve table code 0xF0F4D6
SeBitmap_EnvCurve1:
	; column 0 (x 0-7)
	.byte	0b11111111
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000001
	.byte	0b10000001
	.byte	0b10000010
	.byte	0b10000100
	.byte	0b10000100
	.byte	0b10001000
	.byte	0b10001000
	.byte	0b10010000
	.byte	0b10010000
	.byte	0b10010000
	.byte	0b10100000
	.byte	0b10100000
	.byte	0b10100000
	.byte	0b10100000
	.byte	0b10100000
	.byte	0b10100000
	.byte	0b10100000
	.byte	0b11000000
	.byte	0b11000000
	.byte	0b11000000
	.byte	0b11000000
	.byte	0b11000000
	.byte	0b11000000
	.byte	0b11000000
	.byte	0b11000000
	.byte	0b11000000
	.byte	0b10000000
	.byte	0b11111111
	.byte	0b01111111
	; column 1 (x 8-15)
	.byte	0b11111111
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000011
	.byte	0b00000100
	.byte	0b00011000
	.byte	0b00110000
	.byte	0b01100000
	.byte	0b11000000
	.byte	0b10000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b11111111
	.byte	0b11111111
	; column 2 (x 16-23)
	.byte	0b11111111
	.byte	0b00000000
	.byte	0b00000111
	.byte	0b00111000
	.byte	0b11000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b11111111
	.byte	0b11111111
	; column 3 (x 24-31)
	.byte	0b11111111
	.byte	0b00001111
	.byte	0b11110000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b11111111
	.byte	0b11111111
	; column 4 (x 32-39)
	.byte	0b11111110
	.byte	0b11111010
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b11111111
	.byte	0b11111111
; 1-bpp bitmap 40x40 px, stored column by column (5 byte-columns of 40 rows;
; bit 7 is tested first), drawn by static op 03 via ColorBlit2_LargeCodeBlock
; evidence: curve table code 0xF0F4D6
SeBitmap_EnvCurve2:
	; column 0 (x 0-7)
	.byte	0b11111111
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000001
	.byte	0b10000001
	.byte	0b10000010
	.byte	0b10000010
	.byte	0b10000100
	.byte	0b10000100
	.byte	0b10001000
	.byte	0b10001000
	.byte	0b10010000
	.byte	0b10010000
	.byte	0b10010000
	.byte	0b10100000
	.byte	0b10100000
	.byte	0b10100000
	.byte	0b10100000
	.byte	0b11000000
	.byte	0b11000000
	.byte	0b11000000
	.byte	0b11000000
	.byte	0b11000000
	.byte	0b11111111
	.byte	0b01111111
	; column 1 (x 8-15)
	.byte	0b11111111
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000001
	.byte	0b00000010
	.byte	0b00000100
	.byte	0b00001000
	.byte	0b00010000
	.byte	0b00100000
	.byte	0b01000000
	.byte	0b01000000
	.byte	0b10000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b11111111
	.byte	0b11111111
	; column 2 (x 16-23)
	.byte	0b11111111
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000011
	.byte	0b00001100
	.byte	0b00010000
	.byte	0b00100000
	.byte	0b11000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b11111111
	.byte	0b11111111
	; column 3 (x 24-31)
	.byte	0b11111111
	.byte	0b00000001
	.byte	0b00001110
	.byte	0b01110000
	.byte	0b10000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b11111111
	.byte	0b11111111
	; column 4 (x 32-39)
	.byte	0b11111110
	.byte	0b11111110
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b11111111
	.byte	0b11111111
; 1-bpp bitmap 40x40 px, stored column by column (5 byte-columns of 40 rows;
; bit 7 is tested first), drawn by static op 03 via ColorBlit2_LargeCodeBlock
; evidence: curve table code 0xF0F4D6
SeBitmap_EnvCurve3:
	; column 0 (x 0-7)
	.byte	0b11111111
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000001
	.byte	0b10000011
	.byte	0b10000110
	.byte	0b10000100
	.byte	0b10000100
	.byte	0b10001000
	.byte	0b10001000
	.byte	0b10010000
	.byte	0b10010000
	.byte	0b10100000
	.byte	0b10100000
	.byte	0b10100000
	.byte	0b11000000
	.byte	0b11111111
	.byte	0b01111111
	; column 1 (x 8-15)
	.byte	0b11111111
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000001
	.byte	0b00000011
	.byte	0b00000110
	.byte	0b00001100
	.byte	0b00001000
	.byte	0b00011000
	.byte	0b00110000
	.byte	0b01100000
	.byte	0b11000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b11111111
	.byte	0b11111111
	; column 2 (x 16-23)
	.byte	0b11111111
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000001
	.byte	0b00000011
	.byte	0b00000110
	.byte	0b00001100
	.byte	0b00111000
	.byte	0b01100000
	.byte	0b11000000
	.byte	0b10000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b11111111
	.byte	0b11111111
	; column 3 (x 24-31)
	.byte	0b11111111
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000011
	.byte	0b00011100
	.byte	0b00110000
	.byte	0b01100000
	.byte	0b11000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b11111111
	.byte	0b11111111
	; column 4 (x 32-39)
	.byte	0b11111110
	.byte	0b00000110
	.byte	0b00111011
	.byte	0b11000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b11111111
	.byte	0b11111111
; 1-bpp bitmap 40x40 px, stored column by column (5 byte-columns of 40 rows;
; bit 7 is tested first), drawn by static op 03 via ColorBlit2_LargeCodeBlock
; evidence: curve table code 0xF0F4D6
SeBitmap_EnvCurve4:
	; column 0 (x 0-7)
	.byte	0b11111111
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000001
	.byte	0b10000110
	.byte	0b10111000
	.byte	0b11000000
	.byte	0b11111111
	.byte	0b01111111
	; column 1 (x 8-15)
	.byte	0b11111111
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000001
	.byte	0b00000111
	.byte	0b00001100
	.byte	0b00011000
	.byte	0b01110000
	.byte	0b10000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b11111111
	.byte	0b11111111
	; column 2 (x 16-23)
	.byte	0b11111111
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000001
	.byte	0b00000011
	.byte	0b00000110
	.byte	0b00001100
	.byte	0b00111000
	.byte	0b01100000
	.byte	0b11000000
	.byte	0b10000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b11111111
	.byte	0b11111111
	; column 3 (x 24-31)
	.byte	0b11111111
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000001
	.byte	0b00000011
	.byte	0b00000010
	.byte	0b00000110
	.byte	0b00001100
	.byte	0b00011000
	.byte	0b00110000
	.byte	0b00100000
	.byte	0b01100000
	.byte	0b11000000
	.byte	0b10000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b11111111
	.byte	0b11111111
	; column 4 (x 32-39)
	.byte	0b11111110
	.byte	0b00000110
	.byte	0b00001011
	.byte	0b00001011
	.byte	0b00001011
	.byte	0b00010011
	.byte	0b00010011
	.byte	0b00100011
	.byte	0b00100011
	.byte	0b01000011
	.byte	0b01000011
	.byte	0b11000011
	.byte	0b10000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b11111111
	.byte	0b11111111
; 1-bpp bitmap 40x40 px, stored column by column (5 byte-columns of 40 rows;
; bit 7 is tested first), drawn by static op 03 via ColorBlit2_LargeCodeBlock
; evidence: curve table code 0xF0F4D6
SeBitmap_EnvCurve5:
	; column 0 (x 0-7)
	.byte	0b11111111
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b11111111
	.byte	0b11111111
	.byte	0b01111111
	; column 1 (x 8-15)
	.byte	0b11111111
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000011
	.byte	0b00011100
	.byte	0b11100000
	.byte	0b00000000
	.byte	0b11111111
	.byte	0b11111111
	; column 2 (x 16-23)
	.byte	0b11111111
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000001
	.byte	0b00000110
	.byte	0b00001000
	.byte	0b00010000
	.byte	0b01100000
	.byte	0b10000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b11111111
	.byte	0b11111111
	; column 3 (x 24-31)
	.byte	0b11111111
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000001
	.byte	0b00000001
	.byte	0b00000010
	.byte	0b00000100
	.byte	0b00000100
	.byte	0b00001000
	.byte	0b00010000
	.byte	0b00100000
	.byte	0b01000000
	.byte	0b10000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b11111111
	.byte	0b11111111
	; column 4 (x 32-39)
	.byte	0b11111110
	.byte	0b00000110
	.byte	0b00000111
	.byte	0b00000111
	.byte	0b00000111
	.byte	0b00000111
	.byte	0b00001011
	.byte	0b00001011
	.byte	0b00001011
	.byte	0b00001011
	.byte	0b00010011
	.byte	0b00010011
	.byte	0b00010011
	.byte	0b00100011
	.byte	0b00100011
	.byte	0b01000011
	.byte	0b01000011
	.byte	0b10000011
	.byte	0b10000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b11111111
	.byte	0b11111111
; 1-bpp bitmap 40x40 px, stored column by column (5 byte-columns of 40 rows;
; bit 7 is tested first), drawn by static op 03 via ColorBlit2_LargeCodeBlock
; evidence: curve table code 0xF0F4D6
SeBitmap_EnvCurve6:
	; column 0 (x 0-7)
	.byte	0b11111111
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10000000
	.byte	0b10111111
	.byte	0b11111111
	.byte	0b01111111
	; column 1 (x 8-15)
	.byte	0b11111111
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00011111
	.byte	0b11100000
	.byte	0b11111111
	.byte	0b11111111
	; column 2 (x 16-23)
	.byte	0b11111111
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000001
	.byte	0b00000110
	.byte	0b00111000
	.byte	0b11000000
	.byte	0b00000000
	.byte	0b11111111
	.byte	0b11111111
	; column 3 (x 24-31)
	.byte	0b11111111
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000001
	.byte	0b00000011
	.byte	0b00000110
	.byte	0b00001100
	.byte	0b00011000
	.byte	0b00110000
	.byte	0b01000000
	.byte	0b10000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b11111111
	.byte	0b11111111
	; column 4 (x 32-39)
	.byte	0b11111110
	.byte	0b00000010
	.byte	0b00000111
	.byte	0b00000111
	.byte	0b00000111
	.byte	0b00000111
	.byte	0b00000111
	.byte	0b00000111
	.byte	0b00000111
	.byte	0b00000111
	.byte	0b00000111
	.byte	0b00001011
	.byte	0b00001011
	.byte	0b00001011
	.byte	0b00001011
	.byte	0b00001011
	.byte	0b00001011
	.byte	0b00001011
	.byte	0b00010011
	.byte	0b00010011
	.byte	0b00010011
	.byte	0b00100011
	.byte	0b00100011
	.byte	0b01000011
	.byte	0b01000011
	.byte	0b10000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b00000011
	.byte	0b11111111
	.byte	0b11111111
; se_setup_waveform: 206 bytes -- screen layout data, base 0xF1115E
; Compiled from C source (maincpu/audio/sound_editor_screens/se_setup_waveform.c)
; reader (se_screendata_model.py): static record list(s) from here, read by GraphicsRender_ProcessEntries;
; evidence: SeMenu_PresetManager_Save
SeScreenData_0x0558:			.incbin "includes/generated/se_setup_waveform.bin", 0x0, 0xA
SeMenu_WaveformSelect_Apply_Data:	.incbin "includes/generated/se_setup_waveform.bin", 0xA, 0xC4
; --- comments carried over from the lines this .incbin replaced; the byte-exact C descriptor
;     supersedes their verdicts but not the record of them: ---
	; head of the next record, split off at se_setup_waveform's proven end
	sd_quad	0x22, 174, 62, 308, 99
	sd_quad	0x01, 15, 65, 174, 65
	sd_quad	0x01, 15, 217, 305, 217
	sd_quad	0x02, 15, 65, 15, 217
	sd_quad	0x02, 305, 101, 305, 217
	sd_op23	0x10, 3*40+10
	sd_op23	0x61, 74*40+3
	sd_op23	0x63, 112*40+3
	sd_op23	0x07, 150*40+3
	sd_op23	0x21, 190*40+3
	sd_op23	0x62, 69*40+34
	sd_op23	0x64, 112*40+34
	sd_op23	0x0a, 150*40+34
	sd_op23	0x5f, 190*40+34
; static record list (4 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x06B1
; evidence: SeMenu_WaveformSelect_Data
SeScreenData_0x0685:
	sd_quad	0x1b, 236, 31, 308, 50
	sd_ctext	0x06, 14, 36*40+30, "ORIGINAL \021"
	sd_quad	0x09, 236, 31, 308, 50
	sd_quad	0x09, 238, 33, 306, 48
; static record list (4 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x06DB
; evidence: SeMenu_WaveformSelect_Data
SeScreenData_0x06B1:
	sd_quad	0x1b, 236, 31, 308, 50
	sd_ctext	0x06, 12, 36*40+32, "EDITED \021"
	sd_quad	0x09, 252, 31, 308, 50
	sd_quad	0x09, 254, 33, 306, 48
; static record list (4 records), read by GraphicsRender_ProcessEntries; ends SeScreenData_0x06E5, SeBitmap_Picture40x40
; evidence: SeMenu_ShowConfirmDialog_Data
SeScreenData_0x06DB:
	sd_ctext	0x06, 5, 74*40+0, "\020"
	sd_ctext	0x06, 5, 111*40+0, "\020"
	sd_ctext	0x06, 5, 149*40+0, "\020"
	sd_ctext	0x06, 5, 186*40+0, "\020"
; NO READER FOUND for these 200 bytes.  Searched: LE32/LE24/LE16 of every
; address in the span, ld xiy/xix/xiz immediates, and the loop bounds of the
; tables beside it.
; Shape only: read column by column like the six SeBitmap_EnvCurve* bitmaps
; it follows, it is a coherent 40x40 picture.
; Its address occurs in code only as the exclusive END (XIX) of the record
; list SeScreenData_0x06DB.
SeBitmap_Picture40x40:
	; column 0 (x 0-7)
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00011111
	.byte	0b00110000
	.byte	0b00011111
	.byte	0b00001111
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	; column 1 (x 8-15)
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000011
	.byte	0b00000100
	.byte	0b00001011
	.byte	0b00010101
	.byte	0b00101011
	.byte	0b00101101
	.byte	0b01000110
	.byte	0b01000000
	.byte	0b01000000
	.byte	0b01000000
	.byte	0b01100001
	.byte	0b00111111
	.byte	0b00011110
	.byte	0b00111000
	.byte	0b00101100
	.byte	0b00101100
	.byte	0b00101100
	.byte	0b11101111
	.byte	0b10000011
	.byte	0b01000110
	.byte	0b00101100
	.byte	0b00011000
	.byte	0b11111111
	.byte	0b00000000
	.byte	0b11111111
	.byte	0b11111111
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	; column 2 (x 16-23)
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b10000000
	.byte	0b01000000
	.byte	0b01100000
	.byte	0b01100000
	.byte	0b01110000
	.byte	0b01101000
	.byte	0b01110100
	.byte	0b01111010
	.byte	0b11001101
	.byte	0b11000110
	.byte	0b10000011
	.byte	0b10000001
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b11111111
	.byte	0b00000000
	.byte	0b11111111
	.byte	0b11111111
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	; column 3 (x 24-31)
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b10000000
	.byte	0b01000000
	.byte	0b10100000
	.byte	0b11010000
	.byte	0b01111000
	.byte	0b00111000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000001
	.byte	0b00000010
	.byte	0b00000100
	.byte	0b00001000
	.byte	0b00010000
	.byte	0b11100000
	.byte	0b00000000
	.byte	0b11111000
	.byte	0b11110100
	.byte	0b00011010
	.byte	0b00001101
	.byte	0b00000110
	.byte	0b00000011
	.byte	0b00000001
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	; column 4 (x 32-39)
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00100000
	.byte	0b00100000
	.byte	0b01010000
	.byte	0b01010000
	.byte	0b10001000
	.byte	0b10001000
	.byte	0b10001000
	.byte	0b10001000
	.byte	0b10001000
	.byte	0b10001000
	.byte	0b11001000
	.byte	0b11001000
	.byte	0b11001000
	.byte	0b11001000
	.byte	0b11001000
	.byte	0b10001000
	.byte	0b10001000
	.byte	0b10001000
	.byte	0b10001000
	.byte	0b11011000
	.byte	0b11010000
	.byte	0b01110000
	.byte	0b00100000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00000000
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x07BE
; evidence: bounds at SeScreenData_0x07D3
SeScreenData_0x07B7:
	sd_ctext	0x20, 7, 74*40+1, "1ST"
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x07C5
; evidence: bounds at SeScreenData_0x07D3
SeScreenData_0x07BE:
	sd_ctext	0x20, 7, 111*40+1, "2ND"
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x07CC
; evidence: bounds at SeScreenData_0x07D3
SeScreenData_0x07C5:
	sd_ctext	0x20, 7, 149*40+1, "3RD"
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x07D3
; evidence: bounds at SeScreenData_0x07D3
SeScreenData_0x07CC:
	sd_ctext	0x20, 7, 186*40+1, "4TH"
; list-boundary table: entry i and i+1 bound list i (6 entries, LE32)
; evidence: SeMenu_ShowConfirmDialog_Data
SeScreenData_0x07D3:
	.long	SeScreenData_0x07B7
	.long	SeScreenData_0x07B7
	.long	SeScreenData_0x07BE
	.long	SeScreenData_0x07C5
	.long	SeScreenData_0x07CC
	.long	SeScreenData_0x07D3
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x07F7
; evidence: bounds at SeScreenData_0x081B
SeScreenData_0x07EB:
	sd_blit	SeBitmap_Pattern24x10_1, 74*40+1, 3, 10
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x0803
; evidence: bounds at SeScreenData_0x081B
SeScreenData_0x07F7:
	sd_blit	SeBitmap_Pattern24x10_2, 111*40+1, 3, 10
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x080F
; evidence: bounds at SeScreenData_0x081B
SeScreenData_0x0803:
	sd_blit	SeBitmap_Pattern24x10_3, 149*40+1, 3, 10
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x081B
; evidence: bounds at SeScreenData_0x081B
SeScreenData_0x080F:
	sd_blit	SeBitmap_Pattern24x10_4, 186*40+1, 3, 10
; list-boundary table: entry i and i+1 bound list i (6 entries, LE32)
; evidence: SeMenu_ShowConfirmDialog_Data
SeScreenData_0x081B:
	.long	SeScreenData_0x07EB
	.long	SeScreenData_0x07EB
	.long	SeScreenData_0x07F7
	.long	SeScreenData_0x0803
	.long	SeScreenData_0x080F
	.long	SeScreenData_0x081B
; static record list (4 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x085A
; evidence: SeMenu_ShowConfirmDialog_Data
SeScreenData_0x0833:
	sd_ctext	0x06, 9, 34*40+0, "\020SOLO"
	sd_quad	0x09, 5, 30, 43, 47
	sd_quad	0x09, 7, 32, 41, 45
	sd_quad	0x1b, 6, 31, 6, 46
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x0864
; evidence: SeMenu_ShowConfirmDialog_Data
SeScreenData_0x085A:
	sd_quad	0x05, 8, 33, 40, 44
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x086E
; evidence: SeMenu_ShowConfirmDialog_Data
SeScreenData_0x0864:
	sd_quad	0x1b, 8, 33, 40, 44
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x0878
; evidence: SeMenu_ShowConfirmDialog_Data
SeScreenData_0x086E:
	sd_quad	0x1b, 8, 73, 34, 197
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: SeMenu_ShowConfirmDialog_Data
SeScreenData_0x0878:
	sdb_box	0x03, 0x065d, 0x0f, 0, 0x05, SeScreenData_0x0883
; box table: {x1, y1, x2, y2} u16 per entry, indexed by a bound op 03/04/08
; record's value (pointer field +7; value at most 16 by the record's mask; the table holds 5 cells; values >= 5 would read past it)
; evidence: bound op03 record at SeScreenData_0x0878
SeScreenData_0x0883:
	.short	8, 73, 34, 86
	.short	8, 73, 34, 86
	.short	8, 110, 34, 123
	.short	8, 147, 34, 160
	.short	8, 184, 34, 197
; NO READER FOUND for these 32 bytes.  Searched: LE32/LE24/LE16 of every
; address in the span, ld xiy/xix/xiz immediates, and the loop bounds of the
; tables beside it.
; Shape only: printable text. The same 32 bytes also sit at
; SeScreenData_0x27B9.
SeScreenData_0x08AB:
	.ascii	"NORM 1/2 1/4 1/81/161/321/64 FIX"
; string table, 3-char cells, indexed by a bound record's value (field +7 of
; a bound op 02/07 record; value at most 2 by the record's mask; the table holds 2 cells)
; evidence: bound op02 record at SeScreenData_0x28B4, bound op02 record DrumDetailEdit_Menu_Table
SeScreenData_0x08CB:
	.ascii	"OFF", " ON"
; string table, 3-char cells, indexed by a bound record's value (field +7 of
; a bound op 02/07 record; value at most 2 by the record's mask; the table holds 2 cells)
; evidence: bound op02 record at SeScreenData_0x4C6D
SeScreenData_0x08D1:
	.ascii	"OFF", "ON "
; static record list (25 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x09AA
; evidence: SeMenu_PresetManager_Data
SeScreenData_0x08D7:
	sd_ptext	0x1c, 16, 115, 5, "T0NE LAYER"
	sd_ptext	0x17, 16, 6, 7, "SOUND EDIT"
	sd_ctext	0x06, 7, 70*40+33, "KEY"
	sd_ctext	0x06, 5, 74*40+39, "\021"
	sd_ctext	0x06, 9, 83*40+33, "LAYER"
	sd_ctext	0x06, 7, 108*40+33, "VEL"
	sd_ctext	0x06, 5, 112*40+39, "\021"
	sd_ctext	0x06, 9, 121*40+33, "LAYER"
	sd_ctext	0x07, 5, 201*40+10, "_"
	sd_ctext	0x07, 5, 201*40+26, "_"
	sd_ctext	0x06, 5, 207*40+9, "L"
	sd_ctext	0x06, 19, 207*40+11, "FADE LOW HIGH H"
	sd_ctext	0x06, 8, 207*40+27, "FADE"
	sd_ctext	0x07, 5, 232*40+11, "\022"
	sd_ctext	0x07, 5, 232*40+17, "\022"
	sd_ctext	0x07, 5, 232*40+22, "\022"
	sd_ctext	0x07, 5, 232*40+27, "\022"
	sd_quad	0x09, 4, 4, 68, 16
	sd_quad	0x09, 260, 66, 308, 96
	sd_quad	0x09, 260, 104, 308, 134
	sd_quad	0x09, 69, 204, 251, 233
	sd_quad	0x01, 69, 219, 251, 219
	sd_quad	0x02, 156, 204, 156, 233
	sd_quad	0x05, 70, 220, 250, 232
	sd_op23	0x64, 3*40+11
; static record list (3 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x09D5
; evidence: SeMenu_PresetManager_Data
SeScreenData_0x09AA:
	sd_ptext	0x1c, 17, 114, 5, "T0NE SELECT"
	sd_ptext	0x17, 16, 6, 7, "SOUND EDIT"
	sd_quad	0x09, 4, 4, 68, 16
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x09DA
; evidence: SeMenu_PresetManager_Data
SeScreenData_0x09D5:
	sd_op23	0x61, 3*40+11
; static record list (51 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x0B7E
; evidence: SeMenu_PresetManager_SaveApply
SeScreenData_0x09DA:
	sd_ctext	0x06, 11, 6*40+32, "PAGE1/3"
	sd_ptext	0x17, 10, 84, 60, "TONE"
	sd_ptext	0x17, 12, 114, 60, "SELECT"
	sd_ptext	0x17, 11, 199, 60, "LEVEL"
	sd_ptext	0x17, 9, 241, 60, "KEY"
	sd_ptext	0x17, 12, 265, 60, "DETUNE"
	sd_ctext	0x06, 5, 78*40+0, "\020"
	sd_ctext	0x06, 5, 82*40+9, ":"
	sd_ctext	0x06, 5, 114*40+9, ":"
	sd_ctext	0x06, 5, 115*40+0, "\020"
	sd_ctext	0x06, 5, 146*40+9, ":"
	sd_ctext	0x06, 5, 150*40+0, "\020"
	sd_ctext	0x06, 5, 178*40+9, ":"
	sd_ctext	0x06, 5, 187*40+0, "\020"
	sd_ptext	0x17, 12, 2, 209, "ON/OFF"
	sd_ptext	0x17, 11, 48, 209, "GROUP"
	sd_ptext	0x17, 10, 88, 209, "TONE"
	sd_ptext	0x17, 11, 204, 209, "LEVEL"
	sd_ptext	0x17, 9, 250, 209, "KEY"
	sd_ptext	0x17, 12, 281, 209, "DETUNE"
	sd_ctext	0x06, 5, 218*40+2, "\215"
	sd_ctext	0x06, 5, 218*40+7, "\215"
	sd_ctext	0x06, 5, 218*40+12, "\215"
	sd_ctext	0x06, 5, 218*40+27, "\215"
	sd_ctext	0x06, 5, 218*40+32, "\215"
	sd_ctext	0x06, 5, 218*40+37, "\215"
	sd_ctext	0x06, 5, 228*40+2, "\216"
	sd_ctext	0x06, 5, 228*40+7, "\216"
	sd_ctext	0x06, 5, 228*40+12, "\216"
	sd_ctext	0x06, 5, 228*40+27, "\216"
	sd_ctext	0x06, 5, 228*40+32, "\216"
	sd_ctext	0x06, 5, 228*40+37, "\216"
	sd_quad	0x22, 11, 54, 309, 199
	sd_quad	0x22, 9, 218, 30, 238
	sd_quad	0x22, 49, 218, 70, 238
	sd_quad	0x22, 89, 218, 110, 238
	sd_quad	0x22, 209, 218, 230, 238
	sd_quad	0x22, 249, 218, 270, 238
	sd_quad	0x22, 289, 218, 310, 238
	sd_quad	0x01, 11, 71, 309, 71
	sd_quad	0x01, 11, 103, 309, 103
	sd_quad	0x01, 11, 135, 309, 135
	sd_quad	0x01, 11, 167, 309, 167
	sd_quad	0x01, 9, 228, 30, 228
	sd_quad	0x01, 49, 228, 70, 228
	sd_quad	0x01, 89, 228, 110, 228
	sd_quad	0x01, 209, 228, 230, 228
	sd_quad	0x01, 249, 228, 270, 228
	sd_quad	0x01, 289, 228, 310, 228
	sd_quad	0x02, 60, 54, 60, 199
	sd_quad	0x02, 188, 54, 188, 199
; static record list (4 records), read by GraphicsRender_ProcessEntries; ends SeScreenData_0x0B88, SeScreenData_0x0B92
; evidence: SeMenu_PresetManager_Data
SeScreenData_0x0B7E:
	sd_ctext	0x06, 5, 78*40+0, "\020"
	sd_ctext	0x06, 5, 115*40+0, "\020"
	sd_ctext	0x06, 5, 150*40+0, "\020"
	sd_ctext	0x06, 5, 187*40+0, "\020"
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x0B99
; evidence: bounds at SeScreenData_0x0BAE
SeScreenData_0x0B92:
	sd_ctext	0x20, 7, 79*40+2, "1ST"
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x0BA0
; evidence: bounds at SeScreenData_0x0BAE
SeScreenData_0x0B99:
	sd_ctext	0x20, 7, 111*40+2, "2ND"
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x0BA7
; evidence: bounds at SeScreenData_0x0BAE
SeScreenData_0x0BA0:
	sd_ctext	0x20, 7, 143*40+2, "3RD"
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x0BAE
; evidence: bounds at SeScreenData_0x0BAE
SeScreenData_0x0BA7:
	sd_ctext	0x20, 7, 175*40+2, "4TH"
; list-boundary table: entry i and i+1 bound list i (6 entries, LE32)
; evidence: SeMenu_PresetManager_Data
SeScreenData_0x0BAE:
	.long	SeScreenData_0x0B92
	.long	SeScreenData_0x0B92
	.long	SeScreenData_0x0B99
	.long	SeScreenData_0x0BA0
	.long	SeScreenData_0x0BA7
	.long	SeScreenData_0x0BAE
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x0BD2
; evidence: bounds at SeScreenData_0x0BF6
SeScreenData_0x0BC6:
	sd_blit	SeBitmap_Pattern24x10_1, 79*40+2, 3, 10
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x0BDE
; evidence: bounds at SeScreenData_0x0BF6
SeScreenData_0x0BD2:
	sd_blit	SeBitmap_Pattern24x10_2, 111*40+2, 3, 10
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x0BEA
; evidence: bounds at SeScreenData_0x0BF6
SeScreenData_0x0BDE:
	sd_blit	SeBitmap_Pattern24x10_3, 143*40+2, 3, 10
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x0BF6
; evidence: bounds at SeScreenData_0x0BF6
SeScreenData_0x0BEA:
	sd_blit	SeBitmap_Pattern24x10_4, 175*40+2, 3, 10
; list-boundary table: entry i and i+1 bound list i (6 entries, LE32)
; evidence: SeMenu_PresetManager_Data
SeScreenData_0x0BF6:
	.long	SeScreenData_0x0BC6
	.long	SeScreenData_0x0BC6
	.long	SeScreenData_0x0BD2
	.long	SeScreenData_0x0BDE
	.long	SeScreenData_0x0BEA
	.long	SeScreenData_0x0BF6
; static record list (2 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x0C21
; evidence: bounds at SeScreenData_0x0C5A
SeScreenData_0x0C0E:
	sd_blit	SeBitmap_RadioOn, 82*40+2, 2, 12
	sd_ctext	0x20, 7, 82*40+4, "1ST"
; static record list (2 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x0C34
; evidence: bounds at SeScreenData_0x0C5A
SeScreenData_0x0C21:
	sd_blit	SeBitmap_RadioOn, 114*40+2, 2, 12
	sd_ctext	0x20, 7, 114*40+4, "2ND"
; static record list (2 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x0C47
; evidence: bounds at SeScreenData_0x0C5A
SeScreenData_0x0C34:
	sd_blit	SeBitmap_RadioOn, 146*40+2, 2, 12
	sd_ctext	0x20, 7, 146*40+4, "3RD"
; static record list (2 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x0C5A
; evidence: bounds at SeScreenData_0x0C5A
SeScreenData_0x0C47:
	sd_blit	SeBitmap_RadioOn, 178*40+2, 2, 12
	sd_ctext	0x20, 7, 178*40+4, "4TH"
; list-boundary table: entry i and i+1 bound list i (6 entries, LE32)
; evidence: SeMenu_PresetManager_Data
SeScreenData_0x0C5A:
	.long	SeScreenData_0x0C0E
	.long	SeScreenData_0x0C0E
	.long	SeScreenData_0x0C21
	.long	SeScreenData_0x0C34
	.long	SeScreenData_0x0C47
	.long	SeScreenData_0x0C5A
; static record list (2 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x0C8A
; evidence: bounds at SeScreenData_0x0CD2
SeScreenData_0x0C72:
	sd_blit	SeBitmap_RadioOff, 82*40+2, 2, 12
	sd_blit	SeBitmap_Pattern24x10_1, 82*40+4, 3, 10
; static record list (2 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x0CA2
; evidence: bounds at SeScreenData_0x0CD2
SeScreenData_0x0C8A:
	sd_blit	SeBitmap_RadioOff, 114*40+2, 2, 12
	sd_blit	SeBitmap_Pattern24x10_2, 114*40+4, 3, 10
; static record list (2 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x0CBA
; evidence: bounds at SeScreenData_0x0CD2
SeScreenData_0x0CA2:
	sd_blit	SeBitmap_RadioOff, 146*40+2, 2, 12
	sd_blit	SeBitmap_Pattern24x10_3, 146*40+4, 3, 10
; static record list (2 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x0CD2
; evidence: bounds at SeScreenData_0x0CD2
SeScreenData_0x0CBA:
	sd_blit	SeBitmap_RadioOff, 178*40+2, 2, 12
	sd_blit	SeBitmap_Pattern24x10_4, 178*40+4, 3, 10
; list-boundary table: entry i and i+1 bound list i (6 entries, LE32)
; evidence: SeMenu_PresetManager_Data
SeScreenData_0x0CD2:
	.long	SeScreenData_0x0C72
	.long	SeScreenData_0x0C72
	.long	SeScreenData_0x0C8A
	.long	SeScreenData_0x0CA2
	.long	SeScreenData_0x0CBA
	.long	SeScreenData_0x0CD2
; static record list (2 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x0CFF
; evidence: bounds at SeScreenData_0x0D14
SeScreenData_0x0CEA:
	sd_blit	SeBitmap_RadioOn, 119*40+2, 2, 12
	sd_ptext	0x17, 9, 33, 122, "1ST"
; static record list (2 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x0D14
; evidence: bounds at SeScreenData_0x0D14
SeScreenData_0x0CFF:
	sd_blit	SeBitmap_RadioOn, 149*40+2, 2, 12
	sd_ptext	0x17, 9, 33, 152, "2ND"
; list-boundary table: entry i and i+1 bound list i (4 entries, LE32)
; evidence: SeMenu_PresetManager_Data
SeScreenData_0x0D14:
	.long	SeScreenData_0x0CEA
	.long	SeScreenData_0x0CEA
	.long	SeScreenData_0x0CFF
	.long	SeScreenData_0x0D14
; static record list (2 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x0D39
; evidence: bounds at SeScreenData_0x0D4E
SeScreenData_0x0D24:
	sd_blit	SeBitmap_RadioOff, 119*40+2, 2, 12
	sd_ptext	0x17, 9, 33, 122, "1ST"
; static record list (2 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x0D4E
; evidence: bounds at SeScreenData_0x0D4E
SeScreenData_0x0D39:
	sd_blit	SeBitmap_RadioOff, 149*40+2, 2, 12
	sd_ptext	0x17, 9, 33, 152, "2ND"
; list-boundary table: entry i and i+1 bound list i (4 entries, LE32)
; evidence: SeMenu_PresetManager_Data
SeScreenData_0x0D4E:
	.long	SeScreenData_0x0D24
	.long	SeScreenData_0x0D24
	.long	SeScreenData_0x0D39
	.long	SeScreenData_0x0D4E
; se_setup_params_full: 471 bytes -- screen layout data, base 0xF11964
; Compiled from C source (maincpu/audio/sound_editor_screens/se_setup_params_full.c)
; reader (se_screendata_model.py): static record list(s) from here, read by GraphicsRender_ProcessEntries;
; evidence: SeMenu_PresetBrowser_Navigate
SeScreenData_0x0D5E:			.incbin "includes/generated/se_setup_params_full.bin", 0x0, 0xB0
SeMenu_PresetBrowser_Navigate_Data:	.incbin "includes/generated/se_setup_params_full.bin", 0xB0, 0x23
SeMenu_PresetBrowser_Init_Data:		.incbin "includes/generated/se_setup_params_full.bin", 0xD3, 0x104
; --- comments carried over from the lines this .incbin replaced; the byte-exact C descriptor
;     supersedes their verdicts but not the record of them: ---
	sd_quad	0x22, 11, 51, 168, 202
	sd_quad	0x22, 179, 51, 251, 82
	sd_quad	0x22, 179, 91, 251, 122
	sd_quad	0x22, 179, 131, 251, 162
	sd_quad	0x09, 279, 148, 304, 163
	sd_quad	0x09, 281, 150, 302, 161
	sd_quad	0x22, 179, 171, 251, 202
	sd_quad	0x09, 279, 187, 304, 202
	sd_quad	0x09, 281, 189, 302, 200
	sd_quad	0x22, 49, 218, 70, 238
	sd_quad	0x22, 89, 218, 110, 238
	sd_quad	0x22, 129, 218, 150, 238
	sd_quad	0x22, 209, 218, 230, 238
	sd_quad	0x01, 179, 65, 251, 65
	sd_quad	0x01, 11, 74, 168, 74
	sd_quad	0x01, 179, 105, 251, 105
	sd_quad	0x01, 11, 106, 168, 106
	sd_quad	0x01, 11, 138, 168, 138
	sd_quad	0x01, 179, 145, 251, 145
	sd_quad	0x01, 11, 170, 168, 170
	sd_quad	0x01, 179, 185, 251, 185
	sd_quad	0x01, 49, 228, 70, 228
	sd_quad	0x01, 89, 228, 110, 228
	sd_quad	0x01, 129, 228, 150, 228
	sd_quad	0x01, 209, 228, 230, 228
	sd_quad	0x02, 44, 51, 44, 202
	sd_quad	0x05, 262, 67, 306, 92
; static record list (6 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x1089
; evidence: SeMenu_FxEdit_DataBlock2
SeScreenData_0x1043:
	sd_ptext	0x17, 17, 67, 178, "START PITCH"
	sd_ptext	0x17, 10, 146, 178, "STOP"
	sd_ptext	0x17, 11, 173, 178, "PITCH"
	sd_ptext	0x17, 11, 216, 178, "TOTAL"
	sd_ptext	0x17, 11, 252, 178, "DEPTH"
	sd_quad	0x02, 213, 174, 213, 203
; static record list (17 records), read by GraphicsRender_ProcessEntries; ends SeScreenData_0x1100, SeScreenData_0x113B
; evidence: SeMenu_CompareAndApply_Data3
SeScreenData_0x1089:
	sd_ptext	0x1c, 15, 122, 5, "AMPLITUDE"
	sd_ptext	0x17, 16, 6, 7, "SOUND EDIT"
	sd_ctext	0x06, 9, 41*40+35, "ENV \021"
	sd_ctext	0x06, 9, 75*40+35, "AMP \021"
	sd_quad	0x09, 4, 4, 68, 16
	sd_quad	0x09, 276, 37, 308, 54
	sd_quad	0x09, 276, 65, 308, 94
	sd_quad	0x01, 288, 61, 295, 61
	sd_quad	0x01, 289, 62, 294, 62
	sd_quad	0x01, 290, 63, 293, 63
	sd_quad	0x09, 291, 54, 292, 65
	sd_ctext	0x06, 9, 109*40+35, "LF0 \021"
	sd_quad	0x01, 290, 96, 293, 96
	sd_quad	0x01, 289, 97, 294, 97
	sd_quad	0x01, 288, 98, 295, 98
	sd_quad	0x09, 291, 94, 292, 105
	sd_quad	0x09, 276, 105, 308, 122
; se_setup_labels: 47 bytes -- screen layout data, base 0xF11D41
; Compiled from C source (maincpu/audio/sound_editor_screens/se_setup_labels.c)
; reader (se_screendata_model.py): static record list(s) from here, read by GraphicsRender_ProcessEntries;
; evidence: SeMenu_CompareAndApply_Data4
SeScreenData_0x113B:			.incbin "includes/generated/se_setup_labels.bin", 0x0, 0x5
SeMenu_ShowConfirmDialog_Sub_Data:	.incbin "includes/generated/se_setup_labels.bin", 0x5, 0xA
SeMenu_ShowConfirmDialog_Sub_Data_2:	.incbin "includes/generated/se_setup_labels.bin", 0xF, 0xA
SeMenu_ShowConfirmDialog_Sub_Data_3:	.incbin "includes/generated/se_setup_labels.bin", 0x19, 0x16
	; head of the next record, split off at se_setup_labels's proven end
	sd_quad	0x22, 224, 70, 262, 108
	sd_quad	0x01, 214, 90, 224, 90
; static record list (4 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x11A8
; evidence: startptrs at SeScreenData_0x1250
SeScreenData_0x117E:
	sd_ptext	0x17, 11, 226, 146, "TOUCH"
	sd_ptext	0x17, 11, 232, 155, "CURVE"
	sd_quad	0x22, 224, 102, 262, 140
	sd_quad	0x01, 214, 122, 224, 122
; static record list (4 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x11D2
; evidence: startptrs at SeScreenData_0x1250
SeScreenData_0x11A8:
	sd_ptext	0x17, 11, 226, 178, "TOUCH"
	sd_ptext	0x17, 11, 232, 187, "CURVE"
	sd_quad	0x22, 224, 134, 262, 172
	sd_quad	0x01, 214, 154, 224, 154
; static record list (4 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x11FC
; evidence: startptrs at SeScreenData_0x1250
SeScreenData_0x11D2:
	sd_ptext	0x17, 11, 226, 210, "TOUCH"
	sd_ptext	0x17, 11, 232, 219, "CURVE"
	sd_quad	0x22, 224, 166, 262, 204
	sd_quad	0x01, 214, 186, 224, 186
; static record list (4 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x1226
; evidence: startptrs at SeScreenData_0x1264
SeScreenData_0x11FC:
	sd_ptext	0x17, 11, 170, 114, "TOUCH"
	sd_ptext	0x17, 11, 176, 123, "CURVE"
	sd_quad	0x22, 168, 70, 206, 108
	sd_quad	0x01, 158, 90, 168, 90
; static record list (4 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x1250
; evidence: startptrs at SeScreenData_0x1264
SeScreenData_0x1226:
	sd_ptext	0x17, 11, 170, 146, "TOUCH"
	sd_ptext	0x17, 11, 176, 155, "CURVE"
	sd_quad	0x22, 168, 102, 206, 140
	sd_quad	0x01, 158, 122, 168, 122
; list-start table: entry i -> a list of 42 bytes (5 entries, LE32)
; evidence: code 0xF0F42E
SeScreenData_0x1250:
	.long	SeMenu_ShowConfirmDialog_Sub_Data_3
	.long	SeMenu_ShowConfirmDialog_Sub_Data_3
	.long	SeScreenData_0x117E
	.long	SeScreenData_0x11A8
	.long	SeScreenData_0x11D2
; list-start table: entry i -> a list of 42 bytes (3 entries, LE32)
; evidence: code 0xF0F42E
SeScreenData_0x1264:
	.long	SeScreenData_0x11FC
	.long	SeScreenData_0x11FC
	.long	SeScreenData_0x1226
; u16 table, stride 4, fields +0/+2, indexed directly by code
; evidence: code 0xF0F3E2, code 0xF0F3E8
SeScreenData_0x1270:
	.short	224, 70
	.short	224, 70
	.short	224, 102
	.short	224, 134
	.short	224, 166
; u16 table, stride 4, fields +0/+2, indexed directly by code
; evidence: code 0xF0F3E2, code 0xF0F3E8
SeScreenData_0x1284:
	.short	168, 70
	.short	168, 70
	.short	168, 102
; se_setup_env: 107 bytes -- screen layout data, base 0xF11E96
; Compiled from C source (maincpu/audio/sound_editor_screens/se_setup_env.c)
; reader (se_screendata_model.py): static record list(s) from here, read by GraphicsRender_ProcessEntries;
; evidence: SeMenu_CompareAndApply_Init
SeScreenData_0x1290:
	.incbin "includes/generated/se_setup_env.bin"
	sd_quad	0x22, 11, 53, 212, 202
	sd_quad	0x22, 81, 218, 102, 238
	sd_quad	0x22, 129, 218, 150, 238
	sd_quad	0x22, 169, 218, 190, 238
	sd_quad	0x01, 11, 74, 212, 74
	sd_quad	0x01, 11, 106, 212, 106
	sd_quad	0x01, 11, 138, 212, 138
	sd_quad	0x01, 11, 170, 212, 170
	sd_quad	0x01, 81, 228, 102, 228
	sd_quad	0x01, 129, 228, 150, 228
	sd_quad	0x01, 169, 228, 190, 228
	sd_quad	0x02, 46, 53, 46, 202
	sd_quad	0x05, 278, 67, 306, 92
; se_screen_f11f83: 130 bytes -- screen layout data, base 0xF11F83
; Compiled from C source (maincpu/audio/sound_editor_screens/se_screen_f11f83.c)
; reader (se_screendata_model.py): static record list(s) from here, read by GraphicsRender_ProcessEntries;
; evidence: SeMenu_CompareAndApply_Data6, SeMenu_FxEdit_DataBlock4
SeScreenData_0x137D:
	.incbin "includes/generated/se_screen_f11f83.bin"
	sd_quad	0x22, 47, 72, 255, 122
	sd_quad	0x01, 82, 219, 235, 219
	sd_quad	0x02, 119, 205, 119, 233
	sd_quad	0x05, 278, 67, 306, 92
	sd_quad	0x05, 83, 220, 234, 232
	sd_ptext	0x17, 11, 14, 95, "LEVEL"
	sd_ptext	0x17, 22, 109, 195, "LEVEL KEY FOLLOW"
; static record list (2 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x1466
; evidence: SeMenu_CompareAndApply_Data6, SeMenu_FxEdit_DataBlock4
SeScreenData_0x1452:
	sd_quad	0x01, 47, 97, 255, 97
	sd_quad	0x09, 82, 205, 235, 233
; static record list (21 records), read by GraphicsRender_ProcessEntries; ends SeScreenData_0x147E, SeScreenData_0x1523
; evidence: SeMenu_Utility_CopyBlock
SeScreenData_0x1466:
	sd_ptext	0x17, 14, 127, 48, "ENVELOPE"
	sd_quad	0x22, 50, 58, 257, 145
	sd_ptext	0x17, 12, 195, 151, "KEYOFF"
	sd_ptext	0x17, 9, 11, 207, "ATK"
	sd_ptext	0x17, 10, 41, 207, "PEAK"
	sd_ptext	0x17, 12, 71, 207, "DECAY1"
	sd_ptext	0x17, 11, 113, 207, "SUST1"
	sd_ptext	0x17, 12, 155, 207, "DECAY2"
	sd_ptext	0x17, 11, 197, 207, "SUST2"
	sd_ptext	0x17, 13, 239, 207, "RELEASE"
	sd_ctext	0x07, 5, 231*40+2, "\022"
	sd_ctext	0x07, 5, 231*40+7, "\022"
	sd_ctext	0x07, 5, 231*40+12, "\022"
	sd_ctext	0x07, 5, 231*40+17, "\022"
	sd_ctext	0x07, 5, 231*40+22, "\022"
	sd_ctext	0x07, 5, 231*40+27, "\022"
	sd_ctext	0x07, 5, 231*40+33, "\022"
	sd_quad	0x09, 3, 203, 285, 232
	sd_quad	0x01, 3, 217, 285, 217
	sd_quad	0x05, 4, 218, 284, 231
	sd_quad	0x05, 278, 39, 306, 52
; static record list (39 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x166E
; evidence: SeMenu_Utility_FillBlock
SeScreenData_0x1523:
	sd_ctext	0x06, 11, 6*40+32, "PAGE2/2"
	sd_ptext	0x17, 18, 85, 62, "KEY FOLLOW ("
	sd_ptext	0x17, 7, 66, 130, "0"
	sd_ptext	0x17, 7, 93, 130, "1"
	sd_ptext	0x17, 7, 122, 130, "2"
	sd_ptext	0x17, 7, 150, 130, "3"
	sd_ptext	0x17, 7, 178, 130, "4"
	sd_ptext	0x17, 7, 206, 130, "5"
	sd_ptext	0x17, 7, 234, 130, "6"
	sd_ptext	0x17, 14, 61, 195, "ENVELOPE"
	sd_ptext	0x17, 9, 115, 195, "KEY"
	sd_ptext	0x17, 12, 139, 195, "FOLLOW"
	sd_ptext	0x17, 11, 256, 195, "TOUCH"
	sd_ptext	0x17, 9, 7, 209, "ATK"
	sd_ptext	0x17, 11, 37, 209, "DECAY"
	sd_ptext	0x17, 13, 73, 209, "RELEASE"
	sd_ptext	0x17, 11, 158, 209, "RANGE"
	sd_ptext	0x17, 12, 241, 209, "ATTACK"
	sd_ptext	0x17, 11, 283, 209, "DECAY"
	sd_ctext	0x07, 5, 215*40+18, "_"
	sd_ctext	0x07, 5, 215*40+24, "_"
	sd_ctext	0x06, 5, 217*40+19, "_"
	sd_ctext	0x06, 5, 217*40+23, "_"
	sd_ctext	0x07, 5, 232*40+2, "\022"
	sd_ctext	0x07, 5, 232*40+7, "\022"
	sd_ctext	0x07, 5, 232*40+12, "\022"
	sd_ctext	0x07, 5, 232*40+17, "\022"
	sd_ctext	0x07, 5, 232*40+22, "\022"
	sd_ctext	0x07, 5, 232*40+27, "\022"
	sd_ctext	0x07, 5, 232*40+32, "\022"
	sd_ctext	0x07, 5, 232*40+38, "\022"
	sd_quad	0x22, 47, 72, 255, 122
	sd_quad	0x09, 237, 205, 317, 233
	sd_quad	0x01, 3, 218, 230, 218
	sd_quad	0x01, 237, 218, 317, 218
	sd_quad	0x02, 117, 205, 117, 233
	sd_quad	0x05, 278, 39, 306, 52
	sd_quad	0x05, 4, 219, 229, 232
	sd_quad	0x05, 238, 219, 316, 232
; static record list (2 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x1682
; evidence: SeMenu_Utility_FillBlock
SeScreenData_0x166E:
	sd_quad	0x01, 47, 97, 255, 97
	sd_quad	0x09, 3, 205, 230, 233
; static record list (19 records), read by GraphicsRender_ProcessEntries; ends SeScreenData_0x16A8, SeScreenData_0x173B
; evidence: SeMenu_Utility_FormatNumber
SeScreenData_0x1682:
	sd_ptext	0x1c, 12, 140, 5, "FILTER"
	sd_ptext	0x17, 16, 6, 7, "SOUND EDIT"
	sd_quad	0x09, 4, 4, 68, 16
	sd_ctext	0x06, 9, 41*40+35, "ENV \021"
	sd_ctext	0x06, 7, 69*40+34, "FIL"
	sd_ctext	0x06, 5, 75*40+39, "\021"
	sd_ctext	0x06, 7, 81*40+35, "TER"
	sd_ctext	0x06, 9, 109*40+35, "LF0 \021"
	sd_quad	0x09, 276, 37, 308, 54
	sd_quad	0x09, 268, 65, 308, 94
	sd_quad	0x09, 276, 105, 308, 122
	sd_quad	0x01, 288, 61, 295, 61
	sd_quad	0x01, 289, 62, 294, 62
	sd_quad	0x01, 290, 63, 293, 63
	sd_quad	0x01, 290, 96, 293, 96
	sd_quad	0x01, 289, 97, 294, 97
	sd_quad	0x01, 288, 98, 295, 98
	sd_quad	0x09, 291, 54, 292, 65
	sd_quad	0x09, 291, 94, 292, 105
; se_setup_nav_full: 293 bytes -- screen layout data, base 0xF12341
; Compiled from C source (maincpu/audio/sound_editor_screens/se_setup_nav_full.c)
; reader (se_screendata_model.py): static record list(s) from here, read by GraphicsRender_ProcessEntries;
; evidence: SeMenu_Utility_FormatNumber
SeScreenData_0x173B:			.incbin "includes/generated/se_setup_nav_full.bin", 0x0, 0x23
SeMenu_Utility_FormatNumber_Data_2:	.incbin "includes/generated/se_setup_nav_full.bin", 0x23, 0x22
SeMenu_Utility_CompareBlock_Data:	.incbin "includes/generated/se_setup_nav_full.bin", 0x45, 0xB
SeMenu_Utility_CompareBlock_Data_2:	.incbin "includes/generated/se_setup_nav_full.bin", 0x50, 0xD5
; --- comments carried over from the lines this .incbin replaced; the byte-exact C descriptor
;     supersedes their verdicts but not the record of them: ---
	sd_quad	0x22, 66, 39, 233, 94
	sd_quad	0x22, 66, 117, 233, 172
	sd_quad	0x09, 2, 205, 160, 233
	sd_quad	0x09, 187, 205, 316, 233
	sd_quad	0x01, 146, 113, 153, 113
	sd_quad	0x01, 147, 114, 152, 114
	sd_quad	0x01, 148, 115, 151, 115
	sd_quad	0x01, 2, 219, 160, 219
	sd_quad	0x01, 187, 219, 316, 219
	sd_quad	0x09, 149, 96, 150, 117
	sd_quad	0x05, 3, 220, 159, 232
	sd_quad	0x05, 188, 220, 315, 232
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x18ED
; evidence: SeMenu_Utility_FormatSigned_Data
SeScreenData_0x18D8:
	sd_ptext	0x17, 21, 109, 30, "HIGH PASS -12dB"
; se_setup_ctrl_list: 130 bytes -- screen layout data, base 0xF124F3
; Compiled from C source (maincpu/audio/sound_editor_screens/se_setup_ctrl_list.c)
; reader (se_screendata_model.py): static record list(s) from here, read by GraphicsRender_ProcessEntries;
; evidence: SeMenu_Utility_CompareBlock
SeScreenData_0x18ED:			.incbin "includes/generated/se_setup_ctrl_list.bin", 0x0, 0x14
SeMenu_Utility_CompareBlock_Data_3:	.incbin "includes/generated/se_setup_ctrl_list.bin", 0x14, 0x6E
	sd_quad	0x22, 66, 76, 233, 131
	sd_quad	0x09, 77, 205, 240, 233
	sd_quad	0x01, 77, 219, 240, 219
	sd_quad	0x05, 78, 220, 239, 232
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x19AB
; evidence: SeMenu_Utility_FormatPercent
SeScreenData_0x1997:
	sd_ptext	0x17, 20, 109, 67, "LOW PASS -24dB"
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x19C0
; evidence: SeMenu_Utility_FormatPercent_Data
SeScreenData_0x19AB:
	sd_ptext	0x17, 21, 109, 67, "HIGH PASS -24dB"
; static record list (30 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x1ACA
; evidence: SeMenu_Utility_FormatHex
SeScreenData_0x19C0:
	sd_ptext	0x17, 13, 67, 67, "FILTER:"
	sd_ptext	0x17, 15, 109, 67, "BAND PASS"
	sd_ptext	0x17, 11, 85, 135, "\177 LOW"
	sd_ptext	0x17, 12, 169, 135, "HIGH ~"
	sd_ptext	0x17, 12, 212, 135, "CUTOFF"
	sd_ctext	0x06, 7, 193*40+8, "L0W"
	sd_ctext	0x06, 8, 193*40+23, "HIGH"
	sd_ptext	0x17, 12, 38, 209, "CUTOFF"
	sd_ptext	0x17, 10, 84, 209, "RESO"
	sd_ptext	0x17, 12, 126, 209, "CUTOFF"
	sd_ptext	0x17, 10, 172, 209, "RESO"
	sd_ptext	0x17, 11, 209, 209, "TOUCH"
	sd_ptext	0x17, 11, 245, 209, "CURVE"
	sd_ctext	0x06, 5, 221*40+7, "K"
	sd_ctext	0x06, 6, 221*40+12, "dB"
	sd_ctext	0x06, 5, 221*40+19, "K"
	sd_ctext	0x06, 6, 221*40+24, "dB"
	sd_ctext	0x07, 5, 232*40+6, "\022"
	sd_ctext	0x07, 5, 232*40+11, "\022"
	sd_ctext	0x07, 5, 232*40+17, "\022"
	sd_ctext	0x07, 5, 232*40+22, "\022"
	sd_ctext	0x07, 5, 232*40+27, "\022"
	sd_ctext	0x07, 5, 232*40+32, "\022"
	sd_quad	0x22, 66, 76, 233, 131
	sd_quad	0x09, 29, 205, 117, 233
	sd_quad	0x09, 122, 205, 280, 233
	sd_quad	0x01, 29, 219, 117, 219
	sd_quad	0x01, 122, 219, 280, 219
	sd_quad	0x05, 30, 220, 116, 232
	sd_quad	0x05, 123, 220, 279, 232
; static record list (2 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x1AE1
; evidence: SeMenu_Utility_FormatHex_Data
SeScreenData_0x1ACA:
	sd_ptext	0x1c, 13, 112, 96, "THROUGH"
	sd_quad	0x22, 66, 76, 233, 131
; static record list (2 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x1AF5
; evidence: SeMenu_Utility_End
SeScreenData_0x1AE1:
	sd_quad	0x11, 50, 102, 257, 102
; static record list (2 records), read by GraphicsRender_ProcessEntries; ends SeScreenData_0x1AF5, SeScreenData_0x1B01
; evidence: SeMenu_Utility_CopyBlock
SeScreenData_0x1AEB:
	sd_quad	0x12, 213, 58, 213, 145
	sd_ptext	0x17, 12, 195, 151, "KEYOFF"
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x1B0B
; evidence: SeMenu_Utility_CopyBlock
SeScreenData_0x1B01:
	sd_quad	0x1b, 195, 58, 231, 157
; static record list (32 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x1C2D
; evidence: SeMenu_Utility_End
SeScreenData_0x1B0B:
	sd_ctext	0x06, 11, 6*40+32, "PAGE1/2"
	sd_ptext	0x17, 14, 127, 48, "ENVELOPE"
	sd_ptext	0x17, 12, 195, 151, "KEYOFF"
	sd_ctext	0x06, 6, 152*40+38, "\215 "
	sd_ptext	0x17, 9, 294, 170, "CUR"
	sd_ptext	0x17, 9, 300, 179, "SOR"
	sd_ctext	0x06, 6, 192*40+38, "\216 "
	sd_ptext	0x17, 9, 11, 207, "ATK"
	sd_ptext	0x17, 10, 41, 207, "PEAK"
	sd_ptext	0x17, 12, 71, 207, "DECAY1"
	sd_ptext	0x17, 11, 113, 207, "SUST1"
	sd_ptext	0x17, 12, 155, 207, "DECAY2"
	sd_ptext	0x17, 11, 197, 207, "SUST2"
	sd_ptext	0x17, 13, 239, 207, "RELEASE"
	sd_ctext	0x07, 5, 231*40+2, "\022"
	sd_ctext	0x07, 5, 231*40+7, "\022"
	sd_ctext	0x07, 5, 231*40+12, "\022"
	sd_ctext	0x07, 5, 231*40+17, "\022"
	sd_ctext	0x07, 5, 231*40+22, "\022"
	sd_ctext	0x07, 5, 231*40+27, "\022"
	sd_ctext	0x07, 5, 231*40+33, "\022"
	sd_quad	0x22, 50, 58, 257, 145
	sd_quad	0x09, 294, 150, 319, 165
	sd_quad	0x09, 296, 152, 317, 163
	sd_quad	0x09, 60, 174, 285, 203
	sd_quad	0x09, 294, 189, 319, 204
	sd_quad	0x09, 296, 191, 317, 202
	sd_quad	0x01, 60, 188, 285, 188
	sd_quad	0x02, 138, 174, 138, 203
	sd_quad	0x09, 3, 203, 285, 232
	sd_quad	0x01, 3, 217, 285, 217
	sd_quad	0x05, 278, 39, 306, 52
; static record list (7 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x1C7A
; evidence: SeMenu_Utility_End
SeScreenData_0x1C2D:
	sd_ptext	0x17, 11, 65, 178, "START"
	sd_ptext	0x17, 11, 99, 178, "POINT"
	sd_ptext	0x17, 10, 142, 178, "STOP"
	sd_ptext	0x17, 11, 169, 178, "POINT"
	sd_ptext	0x17, 12, 204, 178, "CUTOFF"
	sd_ptext	0x17, 12, 246, 178, "ADJUST"
	sd_quad	0x02, 202, 174, 202, 203
; static record list (35 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x1DB7
; evidence: SeMenu_FilterEdit_Init
SeScreenData_0x1C7A:
	sd_ctext	0x06, 11, 6*40+32, "PAGE2/2"
	sd_ptext	0x17, 9, 85, 62, "KEY"
	sd_ptext	0x17, 12, 109, 62, "FOLLOW"
	sd_ptext	0x17, 7, 151, 62, "("
	sd_ptext	0x17, 7, 66, 130, "0"
	sd_ptext	0x17, 7, 93, 130, "1"
	sd_ptext	0x17, 7, 122, 130, "2"
	sd_ptext	0x17, 7, 150, 130, "3"
	sd_ptext	0x17, 7, 178, 130, "4"
	sd_ptext	0x17, 7, 206, 130, "5"
	sd_ptext	0x17, 7, 234, 130, "6"
	sd_ptext	0x17, 14, 61, 195, "ENVELOPE"
	sd_ptext	0x17, 9, 115, 195, "KEY"
	sd_ptext	0x17, 12, 139, 195, "FOLLOW"
	sd_ptext	0x17, 11, 256, 195, "TOUCH"
	sd_ptext	0x17, 12, 34, 209, "ATTACK"
	sd_ptext	0x17, 11, 76, 209, "DECAY"
	sd_ptext	0x17, 13, 112, 209, "RELEASE"
	sd_ptext	0x17, 12, 164, 209, "CENTER"
	sd_ptext	0x17, 14, 230, 209, "ADR-TIME"
	sd_ptext	0x17, 11, 284, 209, "DEPTH"
	sd_ctext	0x07, 5, 232*40+7, "\022"
	sd_ctext	0x07, 5, 232*40+12, "\022"
	sd_ctext	0x07, 5, 232*40+17, "\022"
	sd_ctext	0x07, 5, 232*40+22, "\022"
	sd_ctext	0x07, 5, 232*40+32, "\022"
	sd_ctext	0x07, 5, 232*40+38, "\022"
	sd_quad	0x22, 47, 72, 255, 122
	sd_quad	0x09, 228, 205, 317, 233
	sd_quad	0x01, 30, 218, 206, 218
	sd_quad	0x01, 228, 218, 317, 218
	sd_quad	0x02, 158, 205, 158, 233
	sd_quad	0x05, 31, 219, 205, 232
	sd_quad	0x05, 229, 219, 316, 232
	sd_quad	0x05, 278, 39, 306, 52
; static record list (2 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x1DCB
; evidence: SeMenu_FilterEdit_Init
SeScreenData_0x1DB7:
	sd_quad	0x01, 47, 97, 255, 97
	sd_quad	0x09, 30, 205, 206, 233
; se_screen_f129d1: 248 bytes -- screen layout data, base 0xF129D1
; Compiled from C source (maincpu/audio/sound_editor_screens/se_screen_f129d1.c)
; reader (se_screendata_model.py): bound record list(s) from here, read by GraphicsRender_Start;
; evidence: SeMenu_PresetManager_SaveApply, bounds SeScreenData_0x1EF7
SeScreenData_0x1DCB:
	.set	SeScreenData_0x1DE9, . + 30
	.set	SeScreenData_0x1E07, . + 60
	.set	SeScreenData_0x1E25, . + 90
	.set	SeScreenData_0x1E43, . + 120
	.set	SeScreenData_0x1E4D, . + 130
	.set	SeScreenData_0x1E58, . + 141
	.set	SeScreenData_0x1E63, . + 152
	.set	SeScreenData_0x1E6D, . + 162
	.set	SeScreenData_0x1E78, . + 173
	.set	SeScreenData_0x1E83, . + 184
	.set	SeScreenData_0x1E8D, . + 194
	.set	SeScreenData_0x1E98, . + 205
	.set	SeScreenData_0x1EA3, . + 216
	.set	SeScreenData_0x1EAD, . + 226
	.set	SeScreenData_0x1EB8, . + 237
	.incbin "includes/generated/se_screen_f129d1.bin"
	; head of the next record, split off at se_screen_f129d1's proven end
; ** RE-FRAMED 2026-08-30 (lane B4). Was CODE territory. It is a chain of
; records whose every boundary is confirmed twice over -- once by a length
; field, once by a pointer from OUTSIDE the span:
;   0xF12AD0 + 4 (this record's LE32 pointer field) = 0xF12AD4
;   0xF12AD4 + 41 (the ASCII cells)                 = 0xF12AFD  <- 5 refs to start
;   0xF12AFD + 76 (19 LE32 pointers)                = 0xF12B49  <- 2 refs
;   0xF12B49 + 10 (its own length byte, 0x0a)       = 0xF12B53  <- 1 ref
;   0xF12B53 + 40 (five 8-byte cells)               = 0xF12B7B  <- 2 refs
;   0xF12B7B + 11 (its own length byte, 0x0b)       = 0xF12B86  <- the .incbin
; The last record's trailing LE32 is 0x00F12D0B; the tree framed its 0x00 high
; byte as a `nop`, and that phantom is what gave run 9 of the reachability work
; list a STRONG fall-through seed.
; bound record (op 0x03), pointed at by the table below/above;
; part of the record lists that table bounds
; evidence: bounds at SeScreenData_0x1EF7
SeScreenData_0x1EC3:
	sdb_box	0x03, 0x065d, 0x0f, 0, 0x05, SeScreenData_0x1F4D
	; 0xF12AD4: 25 one-character cells (note: no 'T')
; string table, 1-char cells, indexed by a bound record's value (field +7 of
; a bound op 02/07 record; value at most 16 by the record's mask; the table holds 25 cells)
; evidence: bound op02 record at SeScreenData_0x1DCB, bound op02 record at SeScreenData_0x1DE9, bound op02 record at SeScreenData_0x1E07, bound op02 record at SeScreenData_0x1E25
SeScreenData_0x1ECE:
	.ascii	"A", "B", "C", "D", "E", "F", "G", "H"
	.ascii	"I", "J", "K", "L", "M", "N", "O", "P"
	.ascii	"Q", "R", "S", "U", "V", "W", "X", "Y"
	.ascii	"Z"
	; 0xF12AED: two 4-byte cells -- 0xF12AED is referenced from outside
	; 0xF12AF5: two more 4-byte cells
; string table, 4-char cells, indexed by a bound record's value (field +7 of
; a bound op 02/07 record; value at most 2 by the record's mask; the table holds 4 cells)
; evidence: bound op02 record at SeMenu_DataBlock_05_Data
SeScreenData_0x1EE7:
	.ascii	"LOW ", "HIGH", "MONO", "POLY"
	; 0xF12AFD: 19 LE32 pointers back into the record stream above
; list-boundary table: entry i and i+1 bound list i (19 entries, LE32)
; evidence: SeMenu_PatchEdit_Dispatch, SeMenu_PatchEdit_DefaultPath
SeScreenData_0x1EF7:
	.long	SeScreenData_0x1EC3
	.long	SeScreenData_0x1E43
	.long	SeScreenData_0x1E43
	.long	SeScreenData_0x1E4D
	.long	SeScreenData_0x1E58
	.long	SeScreenData_0x1E63
	.long	SeScreenData_0x1E6D
	.long	SeScreenData_0x1E78
	.long	SeScreenData_0x1E83
	.long	SeScreenData_0x1E8D
	.long	SeScreenData_0x1E98
	.long	SeScreenData_0x1EA3
	.long	SeScreenData_0x1EAD
	.long	SeScreenData_0x1EB8
	.long	SeScreenData_0x1DCB
	.long	SeScreenData_0x1DE9
	.long	SeScreenData_0x1E07
	.long	SeScreenData_0x1E25
	.long	SeScreenData_0x1E43
	; 0xF12B49: record, type 0x1b, length 0x0a
; se_setup_sel1: 10 bytes -- screen layout data, base 0xF12B49
; Compiled from C source (maincpu/audio/sound_editor_screens/se_setup_sel1.c)
; reader (se_screendata_model.py): static record list(s) from here, read by GraphicsRender_ProcessEntries;
; evidence: SeMenu_PatchEdit_SetupPath
SeScreenData_0x1F43:	.incbin "includes/generated/se_setup_sel1.bin"
	; 0xF12B53: five 8-byte cells
	; |..I.3.e.|
	; |..I.3.e.|
	; |..i.3...|
	; |....3...|
	; |....3...|
; box table: {x1, y1, x2, y2} u16 per entry, indexed by a bound op 03/04/08
; record's value (pointer field +7; value at most 16 by the record's mask; the table holds 5 cells; values >= 5 would read past it)
; evidence: bound op03 record at SeScreenData_0x1EC3
SeScreenData_0x1F4D:
	.short	13, 73, 307, 101
	.short	13, 73, 307, 101
	.short	13, 105, 307, 133
	.short	13, 137, 307, 165
	.short	13, 169, 307, 197
	; 0xF12B7B: record, type 0x03, length 0x0b, trailing pointer 0x00F12D0B
	; |..`....|
; bound record list (1 record), read by GraphicsRender_Start; end SeScreenData_0x1F80
; evidence: SeMenu_PresetManager_Data
SeScreenData_0x1F75:
	sdb_box	0x03, 0x0660, 0x0f, 0, 0x05, SeScreenData_0x2105
; se_drumkit_display: 329 bytes (293 screen data + 36 DrumKit_VariantSelect_Table)
; Compiled from C source (maincpu/audio/sound_editor_screens/se_drumkit_display.c)
; reader (se_screendata_model.py): bound record list(s) from here, read by GraphicsRender_Start;
; evidence: SeMenu_BankEdit_LoopHelper
SeScreenData_0x1F80:			.incbin "includes/generated/se_drumkit_display.bin", 0x0, 0x28
SeMenu_BankEdit_LoopHelper_Data:	.incbin "includes/generated/se_drumkit_display.bin", 0x28, 0x96
SeMenu_BankEdit_LoopHelper_Data_2:	.incbin "includes/generated/se_drumkit_display.bin", 0xBE, 0x8
SeMenu_BankEdit_LoopHelper_Data_3:	.incbin "includes/generated/se_drumkit_display.bin", 0xC6, 0x4B
SeMenu_BankEdit_LoopBody_Data:		.incbin "includes/generated/se_drumkit_display.bin", 0x111, 0x38
; string table, 2-char cells, indexed by a bound record's value (field +7 of
; a bound op 02/07 record; value at most 32 by the record's mask; the table holds 25 cells; values >= 25 would read past it)
; evidence: bound op07 record DrumDetailEdit_Entry_02, bound op07 record DrumDetailEdit_Entry_06, bound op02 record at SeScreenData_0x1F80, bound op02 record at SeMenu_BankEdit_LoopHelper_Data (+2 more)
SeScreenData_0x20C9:
	.ascii	"A:", "B:", "C:", "D:", "E:", "F:", "G:", "H:"
	.ascii	"I:", "J:", "K:", "L:", "M:", "N:", "O:", "P:"
	.ascii	"Q:", "R:", "S:", "U:", "V:", "W:", "X:", "Y:"
	.ascii	"Z:"
; se_setup_sel2: 10 bytes -- screen layout data, base 0xF12D01
; Compiled from C source (maincpu/audio/sound_editor_screens/se_setup_sel2.c)
; reader (se_screendata_model.py): static record list(s) from here, read by GraphicsRender_ProcessEntries;
; evidence: SeMenu_BankEdit_SetupPath
SeScreenData_0x20FB:	.incbin "includes/generated/se_setup_sel2.bin"
	; head of the next record, split off at se_setup_sel2's proven end
	; tail of the record before se_screen_f12d33, split off at its proven boundary
; box table: {x1, y1, x2, y2} u16 per entry, indexed by a bound op 03/04/08
; record's value (pointer field +7; value at most 16 by the record's mask; the table holds 5 cells; values >= 5 would read past it)
; evidence: bound op03 record at SeScreenData_0x1F75
SeScreenData_0x2105:
	.short	61, 118, 252, 132
	.short	61, 118, 252, 132
	.short	61, 134, 252, 148
	.short	61, 150, 252, 164
	.short	61, 166, 252, 180
; se_screen_f12d33: 15 bytes -- screen layout data, base 0xF12D33
; Compiled from C source (maincpu/audio/sound_editor_screens/se_screen_f12d33.c)
SeScreenData_0x212D:	.incbin "includes/generated/se_screen_f12d33.bin"
; string table, 6-char cells, indexed by a bound record's value (field +7 of
; a bound op 02/07 record; value at most 8 by the record's mask; the table holds 6 cells; values >= 6 would read past it)
; evidence: bound op02 record at SeScreenData_0x212D
SeScreenData_0x213C:
	.ascii	"LPF+EQ"
	.ascii	"HPF+EQ"
	.ascii	"LPF24 "
	.ascii	"HPF24 "
	.ascii	" BPF  "
	.ascii	" THRU "
; se_general_edit: 96 bytes (7 commands)
; Compiled from C source (maincpu/audio/sound_editor_screens/se_general_edit.c)
; reader (se_screendata_model.py): bound record list(s) from here, read by GraphicsRender_Start;
; evidence: SeMenu_Utility_CompareBlock, SeMenu_Utility_FormatSigned_Data
SeScreenData_0x2160:
	.set	SeScreenData_0x216B, . + 11
	.set	SeScreenData_0x2175, . + 21
	.set	SeScreenData_0x2184, . + 36
	.set	SeScreenData_0x2193, . + 51
	.incbin "includes/generated/se_general_edit.bin", 0x0, 0x42
SeMenu_DataBlock_05_Data:	.incbin "includes/generated/se_general_edit.bin", 0x42, 0x1E
; record-pointer table: entry i -> one bound record, drawn with SeGfx_DrawBoundRecord (5 entries, LE32)
; evidence: SeMenu_DataBlock_05, SeMenu_DataBlock_06
SeScreenData_0x21C0:
	.long	SeScreenData_0x2160
	.long	SeScreenData_0x216B
	.long	SeScreenData_0x2175
	.long	SeScreenData_0x2184
	.long	SeScreenData_0x2193
; string table, 2-char cells, indexed by a bound record's value (field +7 of
; a bound op 02/07 record; value at most 8 by the record's mask; the table holds 6 cells; values >= 6 would read past it)
; evidence: bound op02 record at SeScreenData_0x2184, bound op02 record at SeScreenData_0x2283, bound op02 record at SeScreenData_0x22A1
SeScreenData_0x21D4:
	.ascii	"-6", "-3", " 0", "+3", "+6", "+9"
; string table, 3-char cells, indexed by a bound record's value (field +7 of
; a bound op 02/07 record; value at most 8 by the record's mask; the table holds 6 cells; values >= 6 would read past it)
; evidence: bound op02 record at SeScreenData_0x2240
SeScreenData_0x21E0:
	.ascii	"-12", "- 6", "  0", "+ 6"
	.ascii	"+12", "+18"
; string table, 3-char cells, indexed by a bound record's value (field +7 of
; a bound op 02/07 record; value at most 128 by the record's mask; the table holds 14 cells; values >= 14 would read past it)
; evidence: bound op02 record at SeScreenData_0x21B1
SeScreenData_0x21F2:
	.ascii	" --", " -6", " -5", " -4"
	.ascii	" -3", " -2", " -1", "  0"
	.ascii	" +1", " +2", " +3", " +4"
	.ascii	" +5", " +6"
; bound record list (4 records), read by GraphicsRender_Start; end SeScreenData_0x224F
; evidence: SeMenu_Utility_FormatPercent, SeMenu_Utility_FormatPercent_Data
SeScreenData_0x221C:
	sdb_snum	0x0660, 0xe0, 5, 0x20, 221*40+26, 1, 0x03
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x224F
SeScreenData_0x2227:
	sdb_num	0x0661, 0x3f, 0, 0x20, 221*40+22, 2
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x224F
SeScreenData_0x2231:
	sdb_str	0x0662, 0x7f, 0, 0x20, SeScreenData_0x30EC, 5, 221*40+10
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x224F
SeScreenData_0x2240:
	sdb_str	0x0663, 0x07, 0, 0x20, SeScreenData_0x21E0, 3, 221*40+16
; record-pointer table: entry i -> one bound record, drawn with SeGfx_DrawBoundRecord (4 entries, LE32)
; evidence: SeMenu_DataBlock_07, SeMenu_DataBlock_08
SeScreenData_0x224F:
	.long	SeScreenData_0x221C
	.long	SeScreenData_0x2227
	.long	SeScreenData_0x2231
	.long	SeScreenData_0x2240
; bound record list (6 records), read by GraphicsRender_Start; end SeScreenData_0x22B0
; evidence: SeMenu_Utility_FormatHex
SeScreenData_0x225F:
	sdb_snum	0x0660, 0xe0, 5, 0x20, 221*40+31, 1, 0x03
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x22B0
SeScreenData_0x226A:
	sdb_num	0x0661, 0x3f, 0, 0x20, 221*40+27, 2
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x22B0
SeScreenData_0x2274:
	sdb_str	0x0662, 0x7f, 0, 0x20, SeScreenData_0x30EC, 5, 221*40+4
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x22B0
SeScreenData_0x2283:
	sdb_str	0x0663, 0x07, 0, 0x20, SeScreenData_0x21D4, 2, 221*40+10
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x22B0
SeScreenData_0x2292:
	sdb_str	0x0664, 0x7f, 0, 0x20, SeScreenData_0x30EC, 5, 221*40+16
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x22B0
SeScreenData_0x22A1:
	sdb_str	0x0665, 0x07, 0, 0x20, SeScreenData_0x21D4, 2, 221*40+22
; record-pointer table: entry i -> one bound record, drawn with SeGfx_DrawBoundRecord (6 entries, LE32)
; evidence: SeMenu_DataBlock_09
SeScreenData_0x22B0:
	.long	SeScreenData_0x225F
	.long	SeScreenData_0x226A
	.long	SeScreenData_0x2274
	.long	SeScreenData_0x2283
	.long	SeScreenData_0x2292
	.long	SeScreenData_0x22A1
; bound record list (11 records), read by GraphicsRender_Start; end SeScreenData_0x233D
; evidence: SeMenu_Utility_End
SeScreenData_0x22C8:
	sdb_snum	0x0662, 0xff, 0, 0x20, 191*40+10, 2, 0x00
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x2363
SeScreenData_0x22D3:
	sdb_snum	0x066a, 0xff, 0, 0x20, 191*40+20, 2, 0x00
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x2363
SeScreenData_0x22DE:
	sdb_snum	0x0661, 0xff, 0, 0x20, 191*40+31, 2, 0x00
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x2363
SeScreenData_0x22E9:
	sdb_num	0x0663, 0xff, 0, 0x20, 220*40+1, 3
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x2363
SeScreenData_0x22F3:
	sdb_snum	0x0664, 0xff, 0, 0x20, 220*40+5, 2, 0x00
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x2363
SeScreenData_0x22FE:
	sdb_num	0x0665, 0x7f, 0, 0x20, 220*40+10, 3
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x2363
SeScreenData_0x2308:
	sdb_snum	0x0666, 0xff, 0, 0x20, 220*40+15, 2, 0x00
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x2363
SeScreenData_0x2313:
	sdb_num	0x0667, 0x7f, 0, 0x20, 220*40+20, 3
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x2363
SeScreenData_0x231D:
	sdb_snum	0x0668, 0xff, 0, 0x20, 220*40+25, 2, 0x00
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x2363
SeScreenData_0x2328:
	sdb_num	0x0669, 0x7f, 0, 0x20, 220*40+31, 3
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x2363
SeScreenData_0x2332:
	sdb_box	0x03, 0x0660, 0x01, 0, 0x05, SeMenu_CompareScreen_DataTable
; NO READER FOUND for these 2 bytes.  Searched: LE32/LE24/LE16 of every
; address in the span, ld xiy/xix/xiz immediates, and the loop bounds of the
; tables beside it.
; Shape only: printable text. The same 2 bytes also sit at
; SeScreenData_0x071D, SeScreenData_0x290A.
SeScreenData_0x233D:
	.ascii	"+-"
; box table: {x1, y1, x2, y2} u16 per entry, indexed by a bound op 03/04/08
; record's value (pointer field +7; value at most 2 by the record's mask; the table holds 2 cells)
; evidence: bound op03 record at SeScreenData_0x2332
SeMenu_CompareScreen_DataTable:
	.short	61, 189, 284, 202
	.short	4, 218, 284, 231
; static record list (2 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2363
; evidence: SeMenu_DataBlock_10
SeScreenData_0x234F:
	sd_quad	0x1b, 61, 189, 284, 202
	sd_quad	0x1b, 4, 218, 284, 231
; record-pointer table: entry i -> one bound record, drawn with SeGfx_DrawBoundRecord (11 entries, LE32)
; evidence: SeMenu_DataBlock_10
SeScreenData_0x2363:
	.long	SeScreenData_0x2332
	.long	SeScreenData_0x22DE
	.long	SeScreenData_0x22C8
	.long	SeScreenData_0x22E9
	.long	SeScreenData_0x22F3
	.long	SeScreenData_0x22FE
	.long	SeScreenData_0x2308
	.long	SeScreenData_0x2313
	.long	SeScreenData_0x231D
	.long	SeScreenData_0x2328
	.long	SeScreenData_0x22D3
; se_compare_screen: 139 bytes (13 commands)
; Compiled from C source (maincpu/audio/sound_editor_screens/se_compare_screen.c)
; reader (se_screendata_model.py): bound record list(s) from here, read by GraphicsRender_Start;
; evidence: SeMenu_CompareAndApply_Match
SeScreenData_0x238F:
	.set	SeScreenData_0x2399, . + 10
	.set	SeScreenData_0x23A3, . + 20
	.set	SeScreenData_0x23AD, . + 30
	.set	SeScreenData_0x23B7, . + 40
	.set	SeScreenData_0x23C2, . + 51
	.set	SeScreenData_0x23CD, . + 62
	.set	SeScreenData_0x23D8, . + 73
	.set	SeScreenData_0x23E3, . + 84
	.set	SeScreenData_0x23EE, . + 95
	.set	SeScreenData_0x23F9, . + 106
	.set	SeScreenData_0x2404, . + 117
	.set	SeScreenData_0x240F, . + 128
	.incbin "includes/generated/se_compare_screen.bin"
; record-pointer table: entry i -> one bound record, drawn with SeGfx_DrawBoundRecord (13 entries, LE32)
; evidence: SeMenu_DataBlock_01
SeScreenData_0x241A:
	.long	SeScreenData_0x240F
	.long	SeScreenData_0x238F
	.long	SeScreenData_0x2399
	.long	SeScreenData_0x23A3
	.long	SeScreenData_0x23AD
	.long	SeScreenData_0x23B7
	.long	SeScreenData_0x23C2
	.long	SeScreenData_0x23CD
	.long	SeScreenData_0x23D8
	.long	SeScreenData_0x23E3
	.long	SeScreenData_0x23EE
	.long	SeScreenData_0x23F9
	.long	SeScreenData_0x2404
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2458
; evidence: SeMenu_DataBlock_01
SeScreenData_0x244E:
	sd_quad	0x1b, 13, 76, 210, 200
; box table: {x1, y1, x2, y2} u16 per entry, indexed by a bound op 03/04/08
; record's value (pointer field +7; value at most 16 by the record's mask; the table holds 5 cells; values >= 5 would read past it)
; evidence: bound op03 record at SeScreenData_0x240F
SeScreenData_0x2458:
	.short	13, 76, 210, 104
	.short	13, 76, 210, 104
	.short	13, 108, 210, 136
	.short	13, 140, 210, 168
	.short	13, 172, 210, 200
; bound record list (4 records), read by GraphicsRender_Start; end SeScreenData_0x24B8
; evidence: SeMenu_CompareAndApply_Data6
SeScreenData_0x2480:
	sdb_snum	0x0663, 0xff, 0, 0x20, 221*40+11, 2, 0x00
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x24B8
SeScreenData_0x248B:
	sdb_str	0x0661, 0x7f, 0, 0x20, SeScreenData_0x2F6C, 3, 221*40+16
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x24B8
SeScreenData_0x249A:
	sdb_str	0x0660, 0x7f, 0, 0x20, SeScreenData_0x2F6C, 3, 221*40+21
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x24B8
SeScreenData_0x24A9:
	sdb_str	0x0662, 0x7f, 0, 0x20, SeScreenData_0x2F6C, 3, 221*40+26
; record-pointer table: entry i -> one bound record, drawn with SeGfx_DrawBoundRecord (4 entries, LE32)
; evidence: SeMenu_DataBlock_02
SeScreenData_0x24B8:
	.long	SeScreenData_0x249A
	.long	SeScreenData_0x248B
	.long	SeScreenData_0x24A9
	.long	SeScreenData_0x2480
; bound record list (7 records), read by GraphicsRender_Start; end SeScreenData_0x250E
; evidence: SeMenu_Utility_CopyBlock
SeScreenData_0x24C8:
	sdb_num	0x0660, 0x7f, 0, 0x20, 220*40+1, 3
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x250E
SeScreenData_0x24D2:
	sdb_num	0x0661, 0x7f, 0, 0x20, 220*40+5, 3
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x250E
SeScreenData_0x24DC:
	sdb_num	0x0662, 0x7f, 0, 0x20, 220*40+10, 3
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x250E
SeScreenData_0x24E6:
	sdb_num	0x0663, 0x7f, 0, 0x20, 220*40+15, 3
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x250E
SeScreenData_0x24F0:
	sdb_num	0x0664, 0x7f, 0, 0x20, 220*40+20, 3
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x250E
SeScreenData_0x24FA:
	sdb_num	0x0665, 0x7f, 0, 0x20, 220*40+25, 3
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x250E
SeScreenData_0x2504:
	sdb_num	0x0666, 0x7f, 0, 0x20, 220*40+31, 3
; record-pointer table: entry i -> one bound record, drawn with SeGfx_DrawBoundRecord (7 entries, LE32)
; evidence: SeMenu_DataBlock_03
SeScreenData_0x250E:
	.long	SeScreenData_0x24C8
	.long	SeScreenData_0x24D2
	.long	SeScreenData_0x24DC
	.long	SeScreenData_0x24E6
	.long	SeScreenData_0x24F0
	.long	SeScreenData_0x24FA
	.long	SeScreenData_0x2504
; bound record list (9 records), read by GraphicsRender_Start; end SeScreenData_0x259F
; evidence: SeMenu_Utility_FillBlock
SeScreenData_0x252A:
	sdb_snum	0x0660, 0xff, 0, 0x20, 221*40+30, 2, 0x00
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x25B7
SeScreenData_0x2535:
	sdb_snum	0x0661, 0xff, 0, 0x20, 221*40+36, 2, 0x00
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x25B7
SeScreenData_0x2540:
	sdb_str	0x0662, 0x7f, 0, 0x06, SeScreenData_0x2F6C, 3, 221*40+20
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x25B7
SeScreenData_0x254F:
	sdb_str	0x0663, 0x7f, 0, 0x06, SeScreenData_0x2F6C, 3, 221*40+15
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x25B7
SeScreenData_0x255E:
	sdb_str	0x0664, 0x7f, 0, 0x06, SeScreenData_0x2F6C, 3, 221*40+25
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x25B7
SeScreenData_0x256D:
	sdb_snum	0x0665, 0xff, 0, 0x20, 221*40+1, 2, 0x00
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x25B7
SeScreenData_0x2578:
	sdb_snum	0x0666, 0xff, 0, 0x20, 221*40+6, 2, 0x00
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x25B7
SeScreenData_0x2583:
	sdb_snum	0x0667, 0xff, 0, 0x20, 221*40+10, 2, 0x00
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x25B7
SeScreenData_0x258E:
	sdb_strxy	0x0669, 0x03, 0, 0x17, SeScreenData_0x259F, 8, 157, 62
; string table, 8-char cells, indexed by a bound record's value (field +7 of
; a bound op 02/07 record; value at most 4 by the record's mask; the table holds 3 cells; values >= 3 would read past it)
; evidence: bound op07 record at SeScreenData_0x258E, bound op07 record at SeScreenData_0x3BCA
SeScreenData_0x259F:
	.ascii	"ATTACK) "
	.ascii	"DECAY)  "
	.ascii	"RELEASE)"
; record-pointer table: entry i -> one bound record, drawn with SeGfx_DrawBoundRecord (10 entries, LE32)
; evidence: SeMenu_DataBlock_04
SeScreenData_0x25B7:
	.long	SeScreenData_0x252A
	.long	SeScreenData_0x2535
	.long	SeScreenData_0x2540
	.long	SeScreenData_0x254F
	.long	SeScreenData_0x255E
	.long	SeScreenData_0x256D
	.long	SeScreenData_0x2578
	.long	SeScreenData_0x2583
	.long	SeScreenData_0x258E
	.long	SeScreenData_0x258E
; se_name_editor: 218 bytes (15 commands)
; Compiled from C source (maincpu/audio/sound_editor_screens/se_name_editor.c)
; reader (se_screendata_model.py): bound record list(s) from here, read by GraphicsRender_Start;
; evidence: SeMenu_PresetBrowser_Init
TuningSys_Param_01:
	.set	SeScreenData_0x25EA, . + 11
	.set	SeScreenData_0x25F5, . + 22
	.set	SeScreenData_0x2604, . + 37
	.set	SeScreenData_0x260F, . + 48
	.set	SeScreenData_0x261A, . + 59
	.set	SeScreenData_0x2629, . + 74
	.set	SeScreenData_0x2634, . + 85
	.set	SeScreenData_0x263F, . + 96
	.set	SeScreenData_0x264E, . + 111
	.set	SeScreenData_0x2659, . + 122
	.set	SeScreenData_0x2664, . + 133
	.set	SeScreenData_0x2673, . + 148
	.set	SeScreenData_0x2682, . + 163
	.set	SeScreenData_0x26AE, . + 207
	.incbin "includes/generated/se_name_editor.bin", 0x0, 0xAE
SeMenu_DrumKit_Dispatch_Data:	.incbin "includes/generated/se_name_editor.bin", 0xAE, 0x16
SeMenu_DrumKit_Dispatch_Data_2:	.incbin "includes/generated/se_name_editor.bin", 0xC4, 0x16
; string table, 8-char cells, indexed by a bound record's value (field +7 of
; a bound op 02/07 record; value at most 32 by the record's mask; the table holds 32 cells)
; evidence: bound op02 record at SeScreenData_0x2673
SeScreenData_0x26B9:
	.ascii	"OFF     "
	.ascii	"PURE MAJ"
	.ascii	"PURE MIN"
	.ascii	"PHYTHAGO"
	.ascii	"WERCKMEI"
	.ascii	"KIRNBERG"
	.ascii	"OFF     "
	.ascii	"OFF     "
	.ascii	"OFF     "
	.ascii	"OFF     "
	.ascii	"OFF     "
	.ascii	"OFF     "
	.ascii	"OFF     "
	.ascii	"OFF     "
	.ascii	"OFF     "
	.ascii	"OFF     "
	.ascii	"ARABIC1 "
	.ascii	"ARABIC2 "
	.ascii	"ARABIC3 "
	.ascii	"ARABIC4 "
	.ascii	"ARABIC5 "
	.ascii	"SLENDRO "
	.ascii	"PELOG   "
	.ascii	"OFF     "
	.ascii	"OFF     "
	.ascii	"OFF     "
	.ascii	"OFF     "
	.ascii	"OFF     "
	.ascii	"OFF     "
	.ascii	"OFF     "
	.ascii	"OFF     "
	.ascii	"OFF     "
; string table, 4-char cells, indexed by a bound record's value (field +7 of
; a bound op 02/07 record; value at most 8 by the record's mask; the table holds 8 cells)
; evidence: bound op02 record at SeScreenData_0x25F5, bound op02 record at SeScreenData_0x261A, bound op02 record at SeScreenData_0x263F, bound op02 record at SeScreenData_0x2664
SeScreenData_0x27B9:
	.ascii	"NORM", " 1/2", " 1/4", " 1/8"
	.ascii	"1/16", "1/32", "1/64", " FIX"
; box table: {x1, y1, x2, y2} u16 per entry, indexed by a bound op 03/04/08
; record's value (pointer field +7; value at most 8 by the record's mask; the table holds 5 cells; values >= 5 would read past it)
; evidence: bound op03 record at SeMenu_DrumKit_Dispatch_Data_2
SeScreenData_0x27D9:
	.short	13, 76, 166, 104
	.short	13, 76, 166, 104
	.short	13, 108, 166, 136
	.short	13, 140, 166, 168
	.short	13, 172, 166, 200
; box table: {x1, y1, x2, y2} u16 per entry, indexed by a bound op 03/04/08
; record's value (pointer field +7; value at most 16 by the record's mask; the table holds 5 cells; values >= 5 would read past it)
; evidence: bound op03 record at SeScreenData_0x26AE
SeScreenData_0x2801:
	.short	181, 67, 249, 80
	.short	181, 67, 249, 80
	.short	181, 107, 249, 120
	.short	181, 147, 249, 160
	.short	181, 187, 249, 200
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2833
; evidence: SeMenu_DrumKit_Dispatch
SeScreenData_0x2829:
	sd_quad	0x1b, 13, 76, 166, 200
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x283D
; evidence: SeMenu_DrumKit_Dispatch
SeScreenData_0x2833:
	sd_quad	0x1b, 181, 67, 249, 200
; record-pointer table: entry i -> one bound record, drawn with SeGfx_DrawBoundRecord (16 entries, LE32)
; evidence: SeMenu_DrumKit_Dispatch
	.set	TuningSystem_Handler_Table, . + 4
SeScreenData_0x283D:
	.long	SeMenu_DrumKit_Dispatch_Data_2
	.long	TuningSys_Param_01
	.long	SeScreenData_0x25EA
	.long	SeScreenData_0x25F5
	.long	SeScreenData_0x2604
	.long	SeScreenData_0x260F
	.long	SeScreenData_0x261A
	.long	SeScreenData_0x2629
	.long	SeScreenData_0x2634
	.long	SeScreenData_0x263F
	.long	SeScreenData_0x264E
	.long	SeScreenData_0x2659
	.long	SeScreenData_0x2664
	.long	SeScreenData_0x26AE
	.long	SeScreenData_0x2673
	.long	SeScreenData_0x2682
; bound record list (7 records), read by GraphicsRender_Start; ends SeScreenData_0x2896, SeScreenData_0x28CE
; evidence: SeMenu_PresetBrowser_Data, Data_UnknownBlock
SeScreenData_0x287D:
	sdb_str	0x0664, 0xc0, 6, 0x20, SeScreenData_0x2930, 3, 221*40+12
	sdb_num	0x0664, 0x1f, 0, 0x20, 221*40+16, 3
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x290C
SeScreenData_0x2896:
	sdb_num	0x0662, 0x7f, 0, 0x20, 221*40+21, 3
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x290C
SeScreenData_0x28A0:
	sdb_num	0x0661, 0x7f, 0, 0x20, 221*40+25, 3
; bound record list (2 records), read by GraphicsRender_Start; end SeScreenData_0x28C3
; evidence: Data_UnknownBlock
SeScreenData_0x28AA:
	sdb_num	0x0663, 0x3f, 0, 0x20, 221*40+30, 2
	sdb_str	0x0663, 0x80, 7, 0x20, SeScreenData_0x08CB, 3, 221*40+35
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x290C
SeScreenData_0x28C3:
	sdb_box	0x03, 0x0660, 0x07, 0, 0x05, SeScreenData_0x293C
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x2920
SeScreenData_0x28CE:
	sdb_str	0x0665, 0x10, 4, 0x20, SeScreenData_0x290A, 1, 65*40+10
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x2920
SeScreenData_0x28DD:
	sdb_str	0x0666, 0x10, 4, 0x20, SeScreenData_0x290A, 1, 96*40+10
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x2920
SeScreenData_0x28EC:
	sdb_str	0x0667, 0x10, 4, 0x20, SeScreenData_0x290A, 1, 127*40+10
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x2920
SeScreenData_0x28FB:
	sdb_str	0x0668, 0x10, 4, 0x20, SeScreenData_0x290A, 1, 158*40+10
; string table, 1-char cells, indexed by a bound record's value (field +7 of
; a bound op 02/07 record; value at most 2 by the record's mask; the table holds 2 cells)
; evidence: bound op02 record at SeScreenData_0x28CE, bound op02 record at SeScreenData_0x28DD, bound op02 record at SeScreenData_0x28EC, bound op02 record at SeScreenData_0x28FB
SeScreenData_0x290A:
	.ascii	"+", "-"
; record-pointer table: entry i -> one bound record, drawn with SeGfx_DrawBoundRecord (5 entries, LE32)
; evidence: Data_UnknownBlock
SeScreenData_0x290C:
	.long	SeScreenData_0x28C3
	.long	SeScreenData_0x28A0
	.long	SeScreenData_0x2896
	.long	SeScreenData_0x28AA
	.long	SeScreenData_0x287D
; record-pointer table: entry i -> one bound record, drawn with SeGfx_DrawBoundRecord (4 entries, LE32)
; evidence: SeMenu_PresetBrowser_Data
SeScreenData_0x2920:
	.long	SeScreenData_0x28CE
	.long	SeScreenData_0x28DD
	.long	SeScreenData_0x28EC
	.long	SeScreenData_0x28FB
; string table, 3-char cells, indexed by a bound record's value (field +7 of
; a bound op 02/07 record; value at most 4 by the record's mask; the table holds 4 cells)
; evidence: bound op02 record at SeScreenData_0x287D
SeScreenData_0x2930:
	.ascii	"SIN", "TRI", "SQR", "SAW"
; box table: {x1, y1, x2, y2} u16 per entry, indexed by a bound op 03/04/08
; record's value (pointer field +7; value at most 8 by the record's mask; the table holds 5 cells; values >= 5 would read past it)
; evidence: bound op03 record at SeScreenData_0x28C3
SeScreenData_0x293C:
	.short	182, 62, 218, 75
	.short	182, 62, 218, 75
	.short	182, 94, 218, 107
	.short	182, 124, 218, 137
	.short	182, 156, 218, 169
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x296E
; evidence: Data_UnknownBlock
SeScreenData_0x2964:
	sd_quad	0x1b, 182, 62, 218, 169
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2978
; evidence: SeMenu_PresetBrowser_Data
SeScreenData_0x296E:
	sd_quad	0x1b, 46, 62, 74, 169
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2982
; evidence: bounds at SeScreenData_0x29A0
SeScreenData_0x2978:
	sd_quad	0x05, 46, 62, 74, 75
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x298C
; evidence: bounds at SeScreenData_0x29A0
SeScreenData_0x2982:
	sd_quad	0x05, 46, 93, 74, 106
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2996
; evidence: bounds at SeScreenData_0x29A0
SeScreenData_0x298C:
	sd_quad	0x05, 46, 124, 74, 137
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x29A0
; evidence: bounds at SeScreenData_0x29A0
SeScreenData_0x2996:
	sd_quad	0x05, 46, 156, 74, 169
; list-boundary table: entry i and i+1 bound list i (5 entries, LE32)
; evidence: SeMenu_PresetBrowser_Data
SeScreenData_0x29A0:
	.long	SeScreenData_0x2978
	.long	SeScreenData_0x2982
	.long	SeScreenData_0x298C
	.long	SeScreenData_0x2996
	.long	SeScreenData_0x29A0
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x29BE
; evidence: Data_UnknownBlock
SeScreenData_0x29B4:
	sd_quad	0x1b, 221, 68, 237, 203
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x29C8
; evidence: SeMenu_PresetBrowser_Data
SeScreenData_0x29BE:
	sd_quad	0x1b, 89, 67, 179, 166
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x29D2
; evidence: SeMenu_PresetBrowser_Data
SeScreenData_0x29C8:
	sd_quad	0x1b, 77, 65, 88, 167
; static record list (2 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x29E6
; evidence: startptrs at SeScreenData_0x2A22
SeScreenData_0x29D2:
	sd_quad	0x11, 222, 68, 237, 68
	sd_quad	0x12, 237, 68, 237, 203
; static record list (2 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x29FA
; evidence: startptrs at SeScreenData_0x2A22
SeScreenData_0x29E6:
	sd_quad	0x11, 222, 100, 237, 100
	sd_quad	0x12, 237, 100, 237, 203
; static record list (2 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2A0E
; evidence: startptrs at SeScreenData_0x2A22
SeScreenData_0x29FA:
	sd_quad	0x11, 222, 130, 237, 130
	sd_quad	0x12, 237, 130, 237, 203
; static record list (2 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2A22
; evidence: startptrs at SeScreenData_0x2A22
SeScreenData_0x2A0E:
	sd_quad	0x11, 222, 162, 237, 162
	sd_quad	0x12, 237, 162, 237, 203
; list-start table: entry i -> a list of 20 bytes (5 entries, LE32)
; evidence: Data_UnknownBlock
SeScreenData_0x2A22:
	.long	SeScreenData_0x29D2
	.long	SeScreenData_0x29D2
	.long	SeScreenData_0x29E6
	.long	SeScreenData_0x29FA
	.long	SeScreenData_0x2A0E
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2A40
; evidence: grouptab at SeScreenData_0x2AD6
SeScreenData_0x2A36:
	sd_quad	0x01, 93, 70, 180, 70
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2A4A
; evidence: grouptab at SeScreenData_0x2AD6
SeScreenData_0x2A40:
	sd_quad	0x00, 93, 70, 180, 101
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2A54
; evidence: grouptab at SeScreenData_0x2AD6
SeScreenData_0x2A4A:
	sd_quad	0x00, 93, 70, 180, 132
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2A5E
; evidence: grouptab at SeScreenData_0x2AD6
SeScreenData_0x2A54:
	sd_quad	0x00, 93, 70, 180, 163
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2A68
; evidence: grouptab at SeScreenData_0x2AD6
SeScreenData_0x2A5E:
	sd_quad	0x00, 93, 101, 180, 70
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2A72
; evidence: grouptab at SeScreenData_0x2AD6
SeScreenData_0x2A68:
	sd_quad	0x01, 93, 101, 180, 101
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2A7C
; evidence: grouptab at SeScreenData_0x2AD6
SeScreenData_0x2A72:
	sd_quad	0x00, 93, 101, 180, 132
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2A86
; evidence: grouptab at SeScreenData_0x2AD6
SeScreenData_0x2A7C:
	sd_quad	0x00, 93, 101, 180, 163
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2A90
; evidence: grouptab at SeScreenData_0x2AD6
SeScreenData_0x2A86:
	sd_quad	0x00, 93, 132, 180, 70
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2A9A
; evidence: grouptab at SeScreenData_0x2AD6
SeScreenData_0x2A90:
	sd_quad	0x00, 93, 132, 180, 101
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2AA4
; evidence: grouptab at SeScreenData_0x2AD6
SeScreenData_0x2A9A:
	sd_quad	0x01, 93, 132, 180, 132
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2AAE
; evidence: grouptab at SeScreenData_0x2AD6
SeScreenData_0x2AA4:
	sd_quad	0x00, 93, 132, 180, 163
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2AB8
; evidence: grouptab at SeScreenData_0x2AD6
SeScreenData_0x2AAE:
	sd_quad	0x00, 93, 163, 180, 70
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2AC2
; evidence: grouptab at SeScreenData_0x2AD6
SeScreenData_0x2AB8:
	sd_quad	0x00, 93, 163, 180, 101
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2ACC
; evidence: grouptab at SeScreenData_0x2AD6
SeScreenData_0x2AC2:
	sd_quad	0x00, 93, 163, 180, 132
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2AD6
; evidence: grouptab at SeScreenData_0x2AD6
SeScreenData_0x2ACC:
	sd_quad	0x01, 93, 163, 180, 163
; record-group table: entry i -> 10-byte records, one picked by value (4 entries, LE32)
; evidence: SeMenu_PresetBrowser_Data
SeScreenData_0x2AD6:
	.long	SeScreenData_0x2A36
	.long	SeScreenData_0x2A5E
	.long	SeScreenData_0x2A86
	.long	SeScreenData_0x2AAE
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2AED
; evidence: startptrs at SeScreenData_0x2B02
SeScreenData_0x2AE6:
	sd_ptext	0x17, 7, 88, 67, "\020"
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2AF4
; evidence: startptrs at SeScreenData_0x2B02
SeScreenData_0x2AED:
	sd_ptext	0x17, 7, 88, 98, "\020"
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2AFB
; evidence: startptrs at SeScreenData_0x2B02
SeScreenData_0x2AF4:
	sd_ptext	0x17, 7, 88, 129, "\020"
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2B02
; evidence: startptrs at SeScreenData_0x2B02
SeScreenData_0x2AFB:
	sd_ptext	0x17, 7, 88, 160, "\020"
; list-start table: entry i -> a list of 7 bytes (4 entries, LE32)
; evidence: SeMenu_PresetBrowser_Data
SeScreenData_0x2B02:
	.long	SeScreenData_0x2AE6
	.long	SeScreenData_0x2AED
	.long	SeScreenData_0x2AF4
	.long	SeScreenData_0x2AFB
; static record list (26 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2C0A
; evidence: SeMenu_DataBlock_11
SeScreenData_0x2B12:
	sd_ptext	0x1c, 18, 99, 5, "MEM0RY WRITE"
	sd_ptext	0x17, 16, 6, 7, "SOUND EDIT"
	sd_ctext	0x07, 5, 34*40+0, "\020"
	sd_ctext	0x20, 6, 35*40+2, "0K"
	sd_ctext	0x07, 9, 73*40+7, "NAME:"
	sd_ptext	0x17, 7, 310, 109, "\221"
	sd_ctext	0x07, 5, 111*40+36, "\215"
	sd_ctext	0x07, 5, 113*40+39, "\251"
	sd_ctext	0x07, 19, 124*40+7, "MEMORY BANK:  -"
	sd_ptext	0x17, 7, 310, 148, "\221"
	sd_ctext	0x07, 5, 151*40+36, "\216"
	sd_ctext	0x07, 5, 152*40+39, "\251"
	sd_ctext	0x07, 5, 190*40+39, "\021"
	sd_ctext	0x07, 16, 191*40+24, "SOUND NAMING"
	sd_quad	0x09, 4, 4, 68, 16
	sd_quad	0x09, 11, 30, 37, 49
	sd_quad	0x09, 13, 32, 35, 47
	sd_quad	0x22, 41, 60, 238, 172
	sd_quad	0x09, 274, 108, 309, 127
	sd_quad	0x09, 276, 110, 307, 125
	sd_quad	0x09, 274, 147, 309, 166
	sd_quad	0x09, 276, 149, 307, 164
	sd_quad	0x22, 177, 179, 304, 214
	sd_quad	0x09, 247, 137, 266, 138
	sd_quad	0x09, 266, 117, 267, 158
	sd_quad	0x01, 41, 114, 238, 114
; bound record list (3 records), read by GraphicsRender_Start; end SeScreenData_0x2C32
; evidence: SeMenu_DataBlock_11, SeMenu_DataBlock_13
SeScreenData_0x2C0A:
	sdb_str	0x0660, 0x03, 0, 0x07, SeScreenData_0x2C32, 1, 124*40+20
	sdb_num	0x0661, 0xff, 0, 0x07, 124*40+22, 2
	sdb_str	0x0000, 0x00, 0, 0x07, 0x00020bf3, 16, 92*40+9
; string table, 1-char cells, indexed by a bound record's value (field +7 of
; a bound op 02/07 record; value at most 4 by the record's mask; the table holds 3 cells; values >= 3 would read past it)
; evidence: bound op02 record at SeScreenData_0x2C0A
SeScreenData_0x2C32:
	.ascii	" ", "A", "B"
; static record list (4 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2C57
; evidence: SeMenu_DataBlock_12
SeScreenData_0x2C35:
	sd_ctext	0x07, 5, 34*40+0, "\020"
	sd_ctext	0x06, 9, 35*40+2, "WRITE"
	sd_quad	0x09, 12, 30, 60, 49
	sd_quad	0x09, 14, 32, 58, 47
; static record list (37 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2E3A
; evidence: SeMenu_DataBlock_12
SeScreenData_0x2C57:
	sd_ptext	0x17, 16, 6, 7, "SOUND EDIT"
	sd_ptext	0x1c, 18, 102, 5, "S0UND NAMING"
	sd_quad	0x09, 4, 4, 68, 16
; static record list (34 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2E3A
; evidence: SeMenu_DataBlock_12
SeScreenData_0x2C83:
	sd_ctext	0x06, 33, 104*40+6, "A B C D E F G H I J K L M N O"
	sd_ctext	0x06, 35, 119*40+4, "P Q R S T U V W X Y Z a b c d e"
	sd_ctext	0x06, 35, 134*40+4, "f g h i j k l m n o p q r s t u"
	sd_ctext	0x06, 35, 149*40+4, "v w x y z 0 1 2 3 4 5 6 7 8 9 !"
	sd_ctext	0x06, 35, 164*40+4, "\" # $ % & ' ( ) + - * / = , . @"
	sd_ctext	0x06, 35, 179*40+4, ": ; ? \\ ^ _ ` | ~ \177 < > [ ] ( )"
	sd_ctext	0x06, 7, 35*40+35, "CLR"
	sd_ctext	0x07, 5, 35*40+39, "\021"
	sd_ctext	0x07, 5, 73*40+35, "~"
	sd_ctext	0x07, 5, 73*40+37, "\177"
	sd_ctext	0x07, 5, 73*40+39, "\021"
	sd_ctext	0x06, 5, 74*40+36, " "
	sd_ctext	0x07, 6, 195*40+32, ".."
	sd_ctext	0x06, 12, 197*40+1, "P0SITI0N"
	sd_ctext	0x06, 7, 197*40+29, "ABC"
	sd_ctext	0x06, 7, 197*40+34, "]()"
	sd_ctext	0x06, 5, 211*40+32, "\215"
	sd_ctext	0x06, 10, 218*40+2, "<    >"
	sd_ctext	0x06, 17, 218*40+11, "INS  DEL  A/a"
	sd_ctext	0x06, 5, 218*40+27, "<"
	sd_ctext	0x06, 5, 218*40+37, ">"
	sd_ctext	0x06, 5, 223*40+32, "\216"
	sd_quad	0x0a, 277, 28, 306, 52
	sd_quad	0x0a, 277, 66, 306, 90
	sd_quad	0x13, 15, 98, 300, 194
	sd_quad	0x0a, 5, 210, 34, 234
	sd_quad	0x0a, 45, 210, 74, 234
	sd_quad	0x0a, 85, 210, 114, 234
	sd_quad	0x0a, 125, 210, 154, 234
	sd_quad	0x0a, 165, 210, 194, 234
	sd_quad	0x0a, 205, 210, 234, 234
	sd_quad	0x0a, 245, 210, 274, 234
	sd_quad	0x0a, 285, 210, 314, 234
	sd_quad	0x01, 245, 222, 274, 222
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2E44
; evidence: SeMenu_DataBlock_12
SeScreenData_0x2E3A:
	sd_quad	0x0a, 77, 59, 261, 81
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2E4E
; evidence: SeMenu_DataBlock_12
SeScreenData_0x2E44:
	sd_quad	0x0a, 77, 59, 229, 81
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2E58
; evidence: SeMenu_DataBlock_12
SeScreenData_0x2E4E:
	sd_quad	0x0a, 77, 59, 108, 81
; bound record list (2 records), read by GraphicsRender_Start; end SeScreenData_0x2E74
; evidence: SeMenu_DataBlock_12, SeMenu_DataBlock_14
SeScreenData_0x2E58:
	sdb_strxy	0x0000, 0x00, 0, 0x1c, 0x00020bf3, 16, 81, 63
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: SeMenu_DataBlock_14
SeScreenData_0x2E69:
	sdb_box	0x03, 0x0660, 0x0f, 0, 0x05, SeScreenData_0x2EC0
; bound record list (2 records), read by GraphicsRender_Start; end SeScreenData_0x2E90
; evidence: SeMenu_DataBlock_12, SeMenu_DataBlock_14
SeScreenData_0x2E74:
	sdb_strxy	0x0000, 0x00, 0, 0x1c, 0x00020bf3, 13, 81, 63
	sdb_box	0x03, 0x0660, 0x0f, 0, 0x05, SeScreenData_0x2EC0
; bound record list (2 records), read by GraphicsRender_Start; end SeScreenData_0x2EAC
; evidence: SeMenu_DataBlock_12, SeMenu_DataBlock_14
SeScreenData_0x2E90:
	sdb_strxy	0x0000, 0x00, 0, 0x1c, 0x00020bf3, 2, 81, 63
	sdb_box	0x03, 0x0660, 0x0f, 0, 0x05, SeScreenData_0x2EC0
; static record list (2 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2EC0
; evidence: SeMenu_DataBlock_14
SeScreenData_0x2EAC:
	sd_quad	0x1b, 81, 62, 257, 79
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x2EC0
; evidence: SeMenu_DataBlock_14
SeScreenData_0x2EB6:
	sd_quad	0x1b, 32, 103, 280, 192
; box table: {x1, y1, x2, y2} u16 per entry, indexed by a bound op 03/04/08
; record's value (pointer field +7; value at most 16 by the record's mask; the table holds 16 cells)
; evidence: bound op03 record at SeScreenData_0x2E85, bound op03 record at SeScreenData_0x2EA1, bound op03 record at SeScreenData_0x2E69
SeScreenData_0x2EC0:
	.short	81, 62, 92, 79
	.short	92, 62, 103, 79
	.short	103, 62, 114, 79
	.short	114, 62, 125, 79
	.short	125, 62, 136, 79
	.short	136, 62, 147, 79
	.short	147, 62, 158, 79
	.short	158, 62, 169, 79
	.short	169, 62, 180, 79
	.short	180, 62, 191, 79
	.short	191, 62, 202, 79
	.short	202, 62, 213, 79
	.short	213, 62, 224, 79
	.short	224, 62, 235, 79
	.short	235, 62, 246, 79
	.short	246, 62, 257, 79
; u16 table, stride 2, fields +0, indexed directly by code
; evidence: SeMenu_DataBlock_14
SeScreenData_0x2F40:
	.short	32, 48, 64, 80, 96, 112, 128, 144
	.short	160, 176, 192, 208, 224, 240, 256, 272
; u16 table, stride 2, fields +0, indexed directly by code
; evidence: SeMenu_DataBlock_14
SeScreenData_0x2F60:
	.short	103, 118, 133, 148, 163, 178
; string table, 3-char cells, indexed by a bound record's value (field +7 of
; a bound op 02/07 record; value at most 128 by the record's mask; the table holds 128 cells)
; evidence: bound op07 record DrumDetailEdit_Entry_01, bound op02 record at SeScreenData_0x248B, bound op02 record at SeScreenData_0x249A, bound op02 record at SeScreenData_0x24A9 (+8 more)
SeScreenData_0x2F6C:
	.ascii	"C-2", "D\210-", "D-2", "E\210-"
	.ascii	"E-2", "F-2", "F\214-", "G-2"
	.ascii	"A\210-", "A-2", "B\210-", "B-2"
	.ascii	"C\260 ", "D\210\260", "D\260 ", "E\210\260"
	.ascii	"E\260 ", "F\260 ", "F\214\260", "G\260 "
	.ascii	"A\210\260", "A\260 ", "B\210\260", "B\260 "
	.ascii	"C0 ", "D\2100", "D0 ", "E\2100"
	.ascii	"E0 ", "F0 ", "F\2140", "G0 "
	.ascii	"A\2100", "A0 ", "B\2100", "B0 "
	.ascii	"C1 ", "D\2101", "D1 ", "E\2101"
	.ascii	"E1 ", "F1 ", "F\2141", "G1 "
	.ascii	"A\2101", "A1 ", "B\2101", "B1 "
	.ascii	"C2 ", "D\2102", "D2 ", "E\2102"
	.ascii	"E2 ", "F2 ", "F\2142", "G2 "
	.ascii	"A\2102", "A2 ", "B\2102", "B2 "
	.ascii	"C3 ", "D\2103", "D3 ", "E\2103"
	.ascii	"E3 ", "F3 ", "F\2143", "G3 "
	.ascii	"A\2103", "A3 ", "B\2103", "B3 "
	.ascii	"C4 ", "D\2104", "D4 ", "E\2104"
	.ascii	"E4 ", "F4 ", "F\2144", "G4 "
	.ascii	"A\2104", "A4 ", "B\2104", "B4 "
	.ascii	"C5 ", "D\2105", "D5 ", "E\2105"
	.ascii	"E5 ", "F5 ", "F\2145", "G5 "
	.ascii	"A\2105", "A5 ", "B\2105", "B5 "
	.ascii	"C6 ", "D\2106", "D6 ", "E\2106"
	.ascii	"E6 ", "F6 ", "F\2146", "G6 "
	.ascii	"A\2106", "A6 ", "B\2106", "B6 "
	.ascii	"C7 ", "D\2107", "D7 ", "E\2107"
	.ascii	"E7 ", "F7 ", "F\2147", "G7 "
	.ascii	"A\2107", "A7 ", "B\2107", "B7 "
	.ascii	"C8 ", "D\2108", "D8 ", "E\2108"
	.ascii	"E8 ", "F8 ", "F\2148", "G8 "
; string table, 5-char cells, indexed by a bound record's value (field +7 of
; a bound op 02/07 record; value at most 128 by the record's mask; the table holds 128 cells)
; evidence: bound op02 record at SeScreenData_0x2175, bound op02 record at SeScreenData_0x2193, bound op02 record at SeScreenData_0x2231, bound op02 record at SeScreenData_0x2274 (+1 more)
SeScreenData_0x30EC:
	.ascii	" 65.4"
	.ascii	" 69.3"
	.ascii	" 73.4"
	.ascii	" 77.8"
	.ascii	" 82.4"
	.ascii	" 87.3"
	.ascii	" 92.5"
	.ascii	" 98.0"
	.ascii	"103.8"
	.ascii	"110.0"
	.ascii	"116.5"
	.ascii	"123.5"
	.ascii	"130.8"
	.ascii	"138.6"
	.ascii	"146.8"
	.ascii	"155.6"
	.ascii	"164.8"
	.ascii	"174.6"
	.ascii	"185.0"
	.ascii	"196.0"
	.ascii	"207.6"
	.ascii	"220.0"
	.ascii	"233.1"
	.ascii	"246.9"
	.ascii	"261.6"
	.ascii	"277.2"
	.ascii	"293.6"
	.ascii	"311.1"
	.ascii	"329.6"
	.ascii	"349.2"
	.ascii	"370.0"
	.ascii	"392.0"
	.ascii	"415.3"
	.ascii	"440.0"
	.ascii	"466.1"
	.ascii	"493.8"
	.ascii	"523.2"
	.ascii	"554.3"
	.ascii	"587.3"
	.ascii	"622.2"
	.ascii	"659.2"
	.ascii	"698.4"
	.ascii	"739.9"
	.ascii	"783.9"
	.ascii	"830.5"
	.ascii	"879.9"
	.ascii	"932.2"
	.ascii	"987.7"
	.ascii	"1.05K"
	.ascii	"1.11K"
	.ascii	"1.17K"
	.ascii	"1.24K"
	.ascii	"1.32K"
	.ascii	"1.40K"
	.ascii	"1.48K"
	.ascii	"1.57K"
	.ascii	"1.66K"
	.ascii	"1.76K"
	.ascii	"1.86K"
	.ascii	"1.98K"
	.ascii	"2.09K"
	.ascii	"2.22K"
	.ascii	"2.35K"
	.ascii	"2.49K"
	.ascii	"2.64K"
	.ascii	"2.79K"
	.ascii	"2.96K"
	.ascii	"3.14K"
	.ascii	"3.32K"
	.ascii	"3.52K"
	.ascii	"3.73K"
	.ascii	"3.95K"
	.ascii	"4.19K"
	.ascii	"4.43K"
	.ascii	"4.70K"
	.ascii	"4.98K"
	.ascii	"5.27K"
	.ascii	"5.59K"
	.ascii	"5.92K"
	.ascii	"6.27K"
	.ascii	"6.64K"
	.ascii	"7.04K"
	.ascii	"7.46K"
	.ascii	"7.90K"
	.ascii	"8.37K"
	.ascii	"8.87K"
	.ascii	"9.40K"
	.ascii	"9.96K"
	.ascii	"10.5K"
	.ascii	"11.2K"
	.ascii	"11.8K"
	.ascii	"12.5K"
	.ascii	"13.3K"
	.ascii	"14.1K"
	.ascii	"14.9K"
	.ascii	"15.8K"
	.ascii	"16.7K"
	.ascii	"17.7K"
	.ascii	"18.8K"
	.ascii	"19.9K"
	.ascii	"21.1K"
	.ascii	" 22K "
	.ascii	" 23K "
	.ascii	" 24K "
	.ascii	" 25K "
	.ascii	" 26K "
	.ascii	" 27K "
	.ascii	" 28K "
	.ascii	" 29K "
	.ascii	" 30K "
	.ascii	" 31K "
	.ascii	" 32K "
	.ascii	" 33K "
	.ascii	" 34K "
	.ascii	" 35K "
	.ascii	" 36K "
	.ascii	" 37K "
	.ascii	" 38K "
	.ascii	" 39K "
	.ascii	" 40K "
	.ascii	" 41K "
	.ascii	" 42K "
	.ascii	" 43K "
	.ascii	" 44K "
	.ascii	" 45K "
	.ascii	" 46K "
	.ascii	" 47K "
	.ascii	" 48K "
; se_setup_rhythm: 191 bytes -- screen layout data, base 0xF13F72
; Compiled from C source (maincpu/audio/sound_editor_screens/se_setup_rhythm.c)
; reader (se_screendata_model.py): static record list(s) from here, read by GraphicsRender_ProcessEntries;
; evidence: SeMenu_PresetInit_Main
SeScreenData_0x336C:	.incbin "includes/generated/se_setup_rhythm.bin"
	; head of the next record, split off at se_setup_rhythm's proven end
	sd_quad	0x22, 11, 56, 230, 202
	sd_quad	0x22, 242, 154, 289, 202
	sd_quad	0x22, 49, 218, 70, 238
	sd_quad	0x22, 129, 218, 150, 238
	sd_quad	0x22, 201, 218, 222, 238
	sd_quad	0x22, 257, 218, 278, 238
	sd_quad	0x01, 11, 74, 230, 74
	sd_quad	0x01, 11, 106, 230, 106
	sd_quad	0x01, 11, 138, 230, 138
	sd_quad	0x01, 11, 170, 230, 170
	sd_quad	0x01, 242, 178, 289, 178
	sd_quad	0x01, 49, 228, 70, 228
	sd_quad	0x01, 129, 228, 150, 228
	sd_quad	0x01, 201, 228, 222, 228
	sd_quad	0x01, 257, 228, 278, 228
	sd_quad	0x02, 44, 56, 44, 202
	sd_quad	0x02, 124, 56, 124, 202
	sd_quad	0x02, 174, 56, 174, 202
	sd_quad	0x05, 244, 180, 287, 200
; se_screen_f140ef: 180 bytes -- screen layout data, base 0xF140EF
; Compiled from C source (maincpu/audio/sound_editor_screens/se_screen_f140ef.c)
; reader (se_screendata_model.py): static record list(s) from here, read by GraphicsRender_ProcessEntries;
; evidence: SeMenu_FxEdit_Init, SeMenu_FxEdit_DataBlock1
SeScreenData_0x34E9:		.incbin "includes/generated/se_screen_f140ef.bin", 0x0, 0xA
SeMenu_FxEdit_Init_Data:	.incbin "includes/generated/se_screen_f140ef.bin", 0xA, 0x70
SeMenu_FxEdit_Init_Data_2:	.incbin "includes/generated/se_screen_f140ef.bin", 0x7A, 0x3A
	; head of the next record, split off at se_screen_f140ef's proven end
	sd_quad	0x11, 48, 61, 240, 61
	sd_quad	0x09, 48, 98, 240, 99
	sd_quad	0x09, 48, 129, 240, 130
	sd_quad	0x09, 48, 160, 240, 161
	sd_quad	0x09, 48, 191, 240, 192
	sd_quad	0x02, 48, 60, 48, 62
	sd_quad	0x02, 72, 60, 72, 62
	sd_quad	0x02, 96, 60, 96, 62
	sd_quad	0x02, 120, 60, 120, 62
	sd_quad	0x02, 144, 60, 144, 62
	sd_quad	0x02, 168, 60, 168, 62
	sd_quad	0x02, 192, 60, 192, 62
	sd_quad	0x02, 216, 60, 216, 62
	sd_quad	0x02, 240, 60, 240, 62
	sd_quad	0x05, 262, 106, 306, 132
; static record list (3 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x3660
; evidence: SeMenu_FxEdit_DataBlock4
SeScreenData_0x3633:
	sd_ptext	0x17, 12, 8, 95, "CUTOFF"
	sd_ptext	0x17, 23, 106, 195, "FILTER KEY FOLLOW"
	sd_quad	0x05, 270, 67, 306, 92
; static record list (48 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x3805
; evidence: SeMenu_PresetBrowser_Data
SeScreenData_0x3660:
	sd_ctext	0x06, 8, 64*40+23, "LF01"
	sd_ctext	0x06, 5, 75*40+0, "\020"
	sd_ctext	0x06, 8, 96*40+23, "LF02"
	sd_ctext	0x06, 5, 113*40+0, "\020"
	sd_ctext	0x06, 8, 126*40+23, "LF03"
	sd_ctext	0x06, 5, 152*40+0, "\020"
	sd_ctext	0x06, 8, 158*40+23, "LF04"
	sd_ctext	0x06, 5, 190*40+0, "\020"
	sd_ctext	0x06, 7, 208*40+4, "LF0"
	sd_ptext	0x17, 10, 96, 208, "WAVE"
	sd_ptext	0x17, 11, 126, 208, "DELAY"
	sd_ptext	0x17, 11, 162, 208, "SPEED"
	sd_ptext	0x17, 11, 198, 208, "DEPTH"
	sd_ptext	0x17, 11, 234, 208, "TOUCH"
	sd_ptext	0x17, 13, 270, 208, "KEYSYNC"
	sd_ctext	0x06, 10, 220*40+4, "SELECT"
	sd_ctext	0x07, 5, 232*40+7, "\022"
	sd_ctext	0x07, 5, 232*40+12, "\022"
	sd_ctext	0x07, 5, 232*40+17, "\022"
	sd_ctext	0x07, 5, 232*40+22, "\022"
	sd_ctext	0x07, 5, 232*40+27, "\022"
	sd_ctext	0x07, 5, 232*40+32, "\022"
	sd_ctext	0x07, 5, 232*40+37, "\022"
	sd_quad	0x09, 44, 60, 76, 77
	sd_quad	0x09, 180, 60, 220, 77
	sd_quad	0x09, 44, 91, 76, 108
	sd_quad	0x09, 180, 92, 220, 109
	sd_quad	0x09, 44, 122, 76, 139
	sd_quad	0x09, 180, 122, 220, 139
	sd_quad	0x09, 44, 154, 76, 171
	sd_quad	0x09, 180, 154, 220, 171
	sd_quad	0x09, 89, 204, 317, 233
	sd_quad	0x22, 29, 205, 82, 232
	sd_quad	0x11, 24, 68, 44, 68
	sd_quad	0x11, 8, 79, 24, 79
	sd_quad	0x11, 24, 100, 44, 100
	sd_quad	0x11, 8, 117, 24, 117
	sd_quad	0x11, 24, 130, 44, 130
	sd_quad	0x11, 8, 156, 24, 156
	sd_quad	0x11, 31, 162, 44, 162
	sd_quad	0x11, 8, 194, 31, 194
	sd_quad	0x12, 24, 68, 24, 79
	sd_quad	0x12, 24, 100, 24, 117
	sd_quad	0x12, 24, 130, 24, 156
	sd_quad	0x12, 31, 162, 31, 194
	sd_quad	0x01, 89, 219, 317, 219
	sd_quad	0x05, 278, 107, 306, 120
	sd_quad	0x05, 90, 220, 316, 232
; se_rhythm_transport_tables: 220 bytes (16 commands + 2 dispatch tables)
; RhythmTransport_Control_Table (6 entries) + DrumSound_ParamEdit_Table (10 entries)
; Compiled from C source (maincpu/audio/sound_editor_screens/se_rhythm_transport_tables.c)
; reader (se_screendata_model.py): static record list(s) from here, read by GraphicsRender_ProcessEntries;
; evidence: bounds SeScreenData_0x3821
SeScreenData_0x3805:
	.set	SeScreenData_0x3839, . + 52
	.set	SeScreenData_0x3845, . + 64
	.set	SeScreenData_0x3851, . + 76
	.incbin "includes/generated/se_rhythm_transport_tables.bin", 0x0, 0x15
SeMenu_PresetBrowser_Select_Sub_Data:	.incbin "includes/generated/se_rhythm_transport_tables.bin", 0x15, 0x43
SeMenu_PresetBrowser_Select_Sub_Data_2:	.incbin "includes/generated/se_rhythm_transport_tables.bin", 0x58, 0x84
; se_parameter_grid: 221 bytes (17 commands)
; Compiled from C source (maincpu/audio/sound_editor_screens/se_parameter_grid.c)
; reader (se_screendata_model.py): bound record list(s) from here, read by GraphicsRender_Start;
; evidence: SeMenu_PresetInit_Main, SeMenu_FilterEdit_Dispatch
SeScreenData_0x38E1:
	.set	SeScreenData_0x3927, . + 70
	.set	SeScreenData_0x3931, . + 80
	.set	SeScreenData_0x393B, . + 90
	.set	SeScreenData_0x3945, . + 100
	.set	SeScreenData_0x39A0, . + 191
	.set	SeScreenData_0x39AA, . + 201
	.set	SeScreenData_0x39B4, . + 211
	.incbin "includes/generated/se_parameter_grid.bin", 0x0, 0x3C
SeMenu_FilterEdit_Dispatch_Data:	.incbin "includes/generated/se_parameter_grid.bin", 0x3C, 0x32
SeMenu_FilterEdit_Dispatch_Data_2:	.incbin "includes/generated/se_parameter_grid.bin", 0x6E, 0x3C
SeMenu_FilterEdit_Dispatch_Data_3:	.incbin "includes/generated/se_parameter_grid.bin", 0xAA, 0xB
SeMenu_PresetInit_Main_Data:		.incbin "includes/generated/se_parameter_grid.bin", 0xB5, 0x28
; record-pointer table: entry i -> one bound record, drawn with SeGfx_DrawBoundRecord (16 entries, LE32)
; evidence: SeMenu_PresetInit_TableLookup2, SeMenu_FilterEdit_Dispatch
SeScreenData_0x39BE:
	.long	SeMenu_FilterEdit_Dispatch_Data_3
	.long	SeScreenData_0x38E1
	.long	SeMenu_FilterEdit_Dispatch_Data
	.long	SeScreenData_0x3927
	.long	SeScreenData_0x3931
	.long	SeScreenData_0x393B
	.long	SeMenu_PresetInit_Main_Data
	.long	SeScreenData_0x39A0
	.long	SeScreenData_0x39AA
	.long	SeScreenData_0x39B4
	.long	SeScreenData_0x3945
	.long	SeMenu_FilterEdit_Dispatch_Data_2
	.long	SeMenu_PresetInit_Main_Data
	.long	SeScreenData_0x39A0
	.long	SeScreenData_0x39AA
	.long	SeScreenData_0x39B4
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x3A3A
SeScreenData_0x39FE:
	sdb_str	0x0662, 0x80, 7, 0x20, SeScreenData_0x3A70, 7, 85*40+7
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x3A3A
SeScreenData_0x3A0D:
	sdb_str	0x0663, 0x80, 7, 0x20, SeScreenData_0x3A70, 7, 118*40+7
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x3A3A
SeScreenData_0x3A1C:
	sdb_str	0x0664, 0x80, 7, 0x20, SeScreenData_0x3A70, 7, 149*40+7
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x3A3A
SeScreenData_0x3A2B:
	sdb_str	0x0665, 0x80, 7, 0x20, SeScreenData_0x3A70, 7, 181*40+7
; record-pointer table: entry i -> one bound record, drawn with SeGfx_DrawBoundRecord (6 entries, LE32)
; evidence: SeMenu_PresetInit_TableLookup1
SeScreenData_0x3A3A:
	.long	SeScreenData_0x39FE
	.long	SeScreenData_0x39FE
	.long	SeScreenData_0x39FE
	.long	SeScreenData_0x3A0D
	.long	SeScreenData_0x3A1C
	.long	SeScreenData_0x3A2B
; string table, 3-char cells, indexed by a bound record's value (field +7 of
; a bound op 02/07 record; value at most 4 by the record's mask; the table holds 3 cells; values >= 3 would read past it)
; evidence: bound op07 record DrumDetailEdit_Entry_09, bound op02 record at SeMenu_FilterEdit_Dispatch_Data_2, bound op02 record at SeScreenData_0x395E, bound op02 record at SeScreenData_0x396D (+1 more)
SeScreenData_0x3A52:
	.ascii	"CTR", "L  ", "R  "
; string table, 7-char cells, indexed by a bound record's value (field +7 of
; a bound op 02/07 record; value at most 4 by the record's mask; the table holds 3 cells; values >= 3 would read past it)
; evidence: bound op02 record at SeScreenData_0x38E1, bound op02 record at SeScreenData_0x38F0, bound op02 record at SeScreenData_0x38FF, bound op02 record at SeScreenData_0x390E
SeScreenData_0x3A5B:
	.ascii	"KEY ON "
	.ascii	"KEY OFF"
	.ascii	"LEGATO "
; string table, 7-char cells, indexed by a bound record's value (field +7 of
; a bound op 02/07 record; value at most 2 by the record's mask; the table holds 2 cells)
; evidence: bound op02 record at SeScreenData_0x39FE, bound op02 record at SeScreenData_0x3A0D, bound op02 record at SeScreenData_0x3A1C, bound op02 record at SeScreenData_0x3A2B
SeScreenData_0x3A70:
	.ascii	"NON LEG"
	.ascii	"CHORD  "
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x3A88
; evidence: SeMenu_FilterEdit_Dispatch
SeScreenData_0x3A7E:
	sd_quad	0x1b, 13, 76, 228, 200
; box table: {x1, y1, x2, y2} u16 per entry, indexed by a bound op 03/04/08
; record's value (pointer field +7; value at most 16 by the record's mask; the table holds 5 cells; values >= 5 would read past it)
; evidence: bound op03 record at SeMenu_FilterEdit_Dispatch_Data_3
SeScreenData_0x3A88:
	.short	13, 76, 228, 104
	.short	13, 76, 228, 104
	.short	13, 108, 228, 136
	.short	13, 140, 228, 168
	.short	13, 172, 228, 200
; bound record list (5 records), read by GraphicsRender_Start; end SeScreenData_0x3AF7
; evidence: SeMenu_FxEdit_Init
SeScreenData_0x3AB0:
	sdb_str	0x0662, 0x7f, 0, 0x20, SeScreenData_0x2F6C, 3, 221*40+10
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x3AF7
SeScreenData_0x3ABF:
	sdb_str	0x0661, 0x7f, 0, 0x20, SeScreenData_0x2F6C, 3, 221*40+16
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x3AF7
SeScreenData_0x3ACE:
	sdb_str	0x0663, 0x7f, 0, 0x20, SeScreenData_0x2F6C, 3, 221*40+21
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x3AF7
SeScreenData_0x3ADD:
	sdb_str	0x0664, 0x7f, 0, 0x20, SeScreenData_0x2F6C, 3, 221*40+26
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x3AF7
SeScreenData_0x3AEC:
	sdb_box	0x03, 0x065d, 0x0f, 0, 0x05, SeScreenData_0x3B15
; record-pointer table: entry i -> one bound record, drawn with SeGfx_DrawBoundRecord (5 entries, LE32)
; evidence: SeMenu_FilterEdit_AltDispatch
SeScreenData_0x3AF7:
	.long	SeScreenData_0x3AEC
	.long	SeScreenData_0x3ABF
	.long	SeScreenData_0x3AB0
	.long	SeScreenData_0x3ACE
	.long	SeScreenData_0x3ADD
; static record list (1 record), read by GraphicsRender_ProcessEntries; end SeScreenData_0x3B15
; evidence: SeMenu_FilterEdit_AltDispatch, SeMenu_FilterEdit_DataBlock3
SeScreenData_0x3B0B:
	sd_quad	0x1b, 8, 73, 250, 197
; box table: {x1, y1, x2, y2} u16 per entry, indexed by a bound op 03/04/08
; record's value (pointer field +7; value at most 16 by the record's mask; the table holds 5 cells; values >= 5 would read past it)
; evidence: bound op03 record at SeScreenData_0x3AEC, bound op03 record at SeScreenData_0x3B65
SeScreenData_0x3B15:
	.short	8, 73, 250, 103
	.short	8, 73, 250, 103
	.short	8, 104, 250, 134
	.short	8, 135, 250, 165
	.short	8, 166, 250, 197
; bound record list (5 records), read by GraphicsRender_Start; end SeScreenData_0x3B70
; evidence: SeMenu_FxEdit_DataBlock1
SeScreenData_0x3B3D:
	sdb_num	0x0662, 0x7f, 0, 0x20, 221*40+9, 3
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x3B70
SeScreenData_0x3B47:
	sdb_num	0x0661, 0x7f, 0, 0x20, 221*40+15, 3
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x3B70
SeScreenData_0x3B51:
	sdb_num	0x0663, 0x7f, 0, 0x20, 221*40+21, 3
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x3B70
SeScreenData_0x3B5B:
	sdb_num	0x0664, 0x7f, 0, 0x20, 221*40+26, 3
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x3B70
SeScreenData_0x3B65:
	sdb_box	0x03, 0x065d, 0x0f, 0, 0x05, SeScreenData_0x3B15
; record-pointer table: entry i -> one bound record, drawn with SeGfx_DrawBoundRecord (5 entries, LE32)
; evidence: SeMenu_FilterEdit_DataBlock3
SeScreenData_0x3B70:
	.long	SeScreenData_0x3B65
	.long	SeScreenData_0x3B47
	.long	SeScreenData_0x3B3D
	.long	SeScreenData_0x3B51
	.long	SeScreenData_0x3B5B
; bound record list (7 records), read by GraphicsRender_Start; end SeScreenData_0x3BDB
; evidence: SeMenu_FilterEdit_Init
SeScreenData_0x3B84:
	sdb_snum	0x0660, 0xff, 0, 0x20, 221*40+30, 2, 0x00
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x3BDB
SeScreenData_0x3B8F:
	sdb_snum	0x0661, 0xff, 0, 0x20, 221*40+36, 2, 0x00
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x3BDB
SeScreenData_0x3B9A:
	sdb_str	0x0662, 0x7f, 0, 0x06, SeScreenData_0x2F6C, 3, 221*40+21
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x3BDB
SeScreenData_0x3BA9:
	sdb_snum	0x0663, 0xff, 0, 0x20, 221*40+5, 2, 0x00
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x3BDB
SeScreenData_0x3BB4:
	sdb_snum	0x0664, 0xff, 0, 0x20, 221*40+10, 2, 0x00
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x3BDB
SeScreenData_0x3BBF:
	sdb_snum	0x0665, 0xff, 0, 0x20, 221*40+15, 2, 0x00
; single bound record, read by SeGfx_DrawBoundRecord (GraphicsRender_Start)
; evidence: recptrs at SeScreenData_0x3BDB
SeScreenData_0x3BCA:
	sdb_strxy	0x0669, 0x03, 0, 0x17, SeScreenData_0x259F, 8, 157, 62
	; tail of the record before se_setup_ctrl_full, split off at its proven boundary
; record-pointer table: entry i -> one bound record, drawn with SeGfx_DrawBoundRecord (10 entries, LE32)
; evidence: SeMenu_FilterEdit_DataBlock4
SeScreenData_0x3BDB:
	.long	SeScreenData_0x3B84
	.long	SeScreenData_0x3B8F
	.long	SeScreenData_0x3B9A
	.long	SeScreenData_0x3BA9
	.long	SeScreenData_0x3BB4
	.long	SeScreenData_0x3BBF
	.long	SeScreenData_0x3BCA
	.long	SeScreenData_0x3BCA
	.long	SeScreenData_0x3BCA
	.long	SeScreenData_0x3BCA
; se_setup_ctrl_full: 167 bytes -- screen layout data, base 0xF14809
; Compiled from C source (maincpu/audio/sound_editor_screens/se_setup_ctrl_full.c)
; reader (se_screendata_model.py): static record list(s) from here, read by GraphicsRender_ProcessEntries;
; evidence: SeMenu_EqEdit_SetupHelper1
SeScreenData_0x3C03:			.incbin "includes/generated/se_setup_ctrl_full.bin", 0x0, 0x2F
SeMenu_EqEdit_SetupHelper1_Data:	.incbin "includes/generated/se_setup_ctrl_full.bin", 0x2F, 0x5
SeMenu_FilterEdit_DataBlock5_Data:	.incbin "includes/generated/se_setup_ctrl_full.bin", 0x34, 0x73
	; head of the next record, split off at se_setup_ctrl_full's proven end
	sd_quad	0x22, 19, 204, 93, 231
	sd_quad	0x09, 117, 204, 164, 233
	sd_quad	0x02, 188, 72, 188, 91
	sd_quad	0x02, 188, 108, 188, 127
	sd_op23	0x60, 71*40+3
	sd_op23	0x39, 107*40+3
	sd_quad	0x05, 118, 220, 163, 232
	sd_ctext	0x06, 19, 207*40+23, "1ST 2ND 3RD 4TH"
	sd_ctext	0x07, 5, 232*40+33, "\022"
	sd_ctext	0x07, 5, 232*40+38, "\022"
	sd_quad	0x09, 181, 204, 307, 233
	sd_quad	0x05, 182, 219, 306, 232
; static record list (3 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x3D36
; evidence: SeMenu_FilterEdit_DataBlock5
SeScreenData_0x3D17:
	sd_ctext	0x06, 11, 207*40+23, "1ST 2ND"
	sd_quad	0x09, 181, 204, 244, 233
	; tail of the record before se_setup_transport, split off at its proven boundary
	sd_quad	0x05, 182, 219, 243, 232
; se_setup_transport: 107 bytes -- screen layout data, base 0xF1493C
; Compiled from C source (maincpu/audio/sound_editor_screens/se_setup_transport.c)
; reader (se_screendata_model.py): static record list(s) from here, read by GraphicsRender_ProcessEntries;
; evidence: SeMenu_EqEdit_Init
SeScreenData_0x3D36:
	.incbin "includes/generated/se_setup_transport.bin"
	sd_quad	0x22, 33, 78, 280, 132
	sd_quad	0x22, 89, 218, 110, 238
	sd_quad	0x22, 209, 218, 230, 238
	sd_quad	0x01, 89, 228, 110, 228
	sd_quad	0x01, 209, 228, 230, 228
; se_transport_display: 141 bytes (14 commands)
; Compiled from C source (maincpu/audio/sound_editor_screens/se_transport_display.c)
; reader (se_screendata_model.py): bound record list(s) from here, read by GraphicsRender_Start;
; evidence: SeMenu_FilterEdit_DataBlock5, SeMenu_EqEdit_Dispatch
SeScreenData_0x3DD3:
	.set	SeScreenData_0x3E00, . + 45
	.set	SeScreenData_0x3E0F, . + 60
	.set	SeScreenData_0x3E1E, . + 75
	.set	SeScreenData_0x3E2D, . + 90
	.incbin "includes/generated/se_transport_display.bin", 0x0, 0x1E
SeMenu_FilterEdit_DataBlock5_Data_2:	.incbin "includes/generated/se_transport_display.bin", 0x1E, 0x46
SeMenu_EqEdit_DrawTable_Data:		.incbin "includes/generated/se_transport_display.bin", 0x64, 0x1E
SeMenu_EqEdit_DrawTable_Data_2:		.incbin "includes/generated/se_transport_display.bin", 0x82, 0xB
; record-pointer table: entry i -> one bound record, drawn with SeGfx_DrawBoundRecord (8 entries, LE32)
; evidence: SeMenu_EqEdit_DefaultPath
SeScreenData_0x3E60:
	.long	SeMenu_EqEdit_DrawTable_Data_2
	.long	SeMenu_FilterEdit_DataBlock5_Data_2
	.long	SeScreenData_0x3E00
	.long	SeScreenData_0x3E0F
	.long	SeScreenData_0x3E1E
	.long	SeScreenData_0x3E0F
	.long	SeScreenData_0x3E1E
	.long	SeScreenData_0x3E2D
; string table, 3-char cells, indexed by a bound record's value (field +7 of
; a bound op 02/07 record; value at most 4 by the record's mask; the table holds 4 cells)
; evidence: bound op02 record at SeMenu_EqEdit_DrawTable_Data, bound op02 record at SeScreenData_0x3E46, bound op02 record at SeScreenData_0x3DD3, bound op02 record at SeScreenData_0x3DE2
SeScreenData_0x3E80:
	.ascii	"OFF", " ON", "---", "INV"
; string table, 13-char cells, indexed by a bound record's value (field +7 of
; a bound op 02/07 record; value at most 64 by the record's mask; the table holds 64 cells)
; evidence: bound op02 record at SeMenu_FilterEdit_DataBlock5_Data_2, bound op02 record at SeScreenData_0x3E00, bound op02 record at SeScreenData_0x3E0F, bound op02 record at SeScreenData_0x3E1E
SeScreenData_0x3E8C:
	.ascii	"-------------"
	.ascii	"PITCH BEND   "
	.ascii	"AMP ENV SUST "
	.ascii	"FILTER CUTOFF"
	.ascii	"PTCH LFO1 DEP"
	.ascii	"PTCH LFO2 DEP"
	.ascii	"PTCH LFO3 DEP"
	.ascii	"PTCH LFO4 DEP"
	.ascii	"AMP LFO1 DEP "
	.ascii	"AMP LFO2 DEP "
	.ascii	"AMP LFO3 DEP "
	.ascii	"AMP LFO4 DEP "
	.ascii	"FLT LFO1 DEP "
	.ascii	"FLT LFO2 DEP "
	.ascii	"FLT LFO3 DEP "
	.ascii	"FLT LFO4 DEP "
	.ascii	"PTCH LFO1 SPD"
	.ascii	"PTCH LFO2 SPD"
	.ascii	"PTCH LFO3 SPD"
	.ascii	"PTCH LFO4 SPD"
	.ascii	"AMP LFO1 SPD "
	.ascii	"AMP LFO2 SPD "
	.ascii	"AMP LFO3 SPD "
	.ascii	"AMP LFO4 SPD "
	.ascii	"FLT LFO1 SPD "
	.ascii	"FLT LFO2 SPD "
	.ascii	"FLT LFO3 SPD "
	.ascii	"FLT LFO4 SPD "
	.ascii	"           28"
	.ascii	"           29"
	.ascii	"           30"
	.ascii	"           31"
	.ascii	"           32"
	.ascii	"           33"
	.ascii	"           34"
	.ascii	"           35"
	.ascii	"           36"
	.ascii	"           37"
	.ascii	"           38"
	.ascii	"           39"
	.ascii	"           40"
	.ascii	"           41"
	.ascii	"           42"
	.ascii	"           43"
	.ascii	"           44"
	.ascii	"           45"
	.ascii	"           46"
	.ascii	"           47"
	.ascii	"           48"
	.ascii	"           49"
	.ascii	"           50"
	.ascii	"           51"
	.ascii	"           52"
	.ascii	"           53"
	.ascii	"           54"
	.ascii	"           55"
	.ascii	"           56"
	.ascii	"           57"
	.ascii	"           58"
	.ascii	"           59"
	.ascii	"           60"
	.ascii	"           61"
	.ascii	"           62"
	.ascii	"           63"
; se_setup_sel_rects: 30 bytes -- screen layout data, base 0xF14DD2
; Compiled from C source (maincpu/audio/sound_editor_screens/se_setup_sel_rects.c)
; reader (se_screendata_model.py): static record list(s) from here, read by GraphicsRender_ProcessEntries;
; evidence: SeMenu_EqEdit_SetupPath
SeScreenData_0x41CC:	.incbin "includes/generated/se_setup_sel_rects.bin"
	; head of the next record, split off at se_setup_sel_rects's proven end
; box table: {x1, y1, x2, y2} u16 per entry, indexed by a bound op 03/04/08
; record's value (pointer field +7; value at most 8 by the record's mask; the table holds 7 cells; values >= 7 would read past it)
; evidence: bound op03 record at SeMenu_EqEdit_DrawTable_Data_2
SeScreenData_0x41EA:
	.short	77, 74, 186, 89
	.short	77, 74, 186, 89
	.short	190, 74, 298, 89
	.short	77, 141, 186, 156
	.short	190, 141, 298, 156
	.short	77, 110, 186, 125
	.short	190, 110, 298, 125
; se_setup_sel3: 30 bytes (2 commands)
; Compiled from C source (maincpu/audio/sound_editor_screens/se_setup_sel3.c)
; reader (se_screendata_model.py): bound record list(s) from here, read by GraphicsRender_Start;
; evidence: SeMenu_EqEdit_Init, SeMenu_EqEdit_DrawInit
SeScreenData_0x4222:	.incbin "includes/generated/se_setup_sel3.bin"
; string table, 4-char cells, indexed by a bound record's value (field +7 of
; a bound op 02/07 record; value at most 2 by the record's mask; the table holds 2 cells)
; evidence: bound op02 record at SeScreenData_0x4222
SeScreenData_0x4240:
	.ascii	"LONG", "HOLD"
; string table, 7-char cells, indexed by a bound record's value (field +7 of
; a bound op 02/07 record; value at most 2 by the record's mask; the table holds 2 cells)
; evidence: bound op02 record at SeScreenData_0x4231
SeScreenData_0x4248:
	.ascii	"DISABLE"
	.ascii	"ENABLE "
; static record list (46 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x441A
; evidence: SeMenu_PresetManager_Data
SeScreenData_0x4256:
	sd_ctext	0x06, 11, 6*40+32, "PAGE2/3"
; static record list (45 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x441A
; evidence: SeMenu_PresetManager_Data
SeScreenData_0x4261:
	sd_quad	0x09, 101, 58, 197, 72
	sd_quad	0x1b, 99, 54, 195, 68
	sd_quad	0x09, 99, 54, 195, 68
	sd_quad	0x1b, 97, 50, 193, 64
	sd_quad	0x09, 97, 50, 193, 64
	sd_quad	0x1b, 95, 46, 191, 60
	sd_quad	0x09, 95, 46, 191, 60
	sd_ptext	0x17, 10, 131, 35, "TONE"
	sd_ptext	0x17, 19, 103, 50, "TONE WAVEFORM"
	sd_ptext	0x17, 19, 85, 103, "TONE WAVEFORM"
	sd_ptext	0x17, 14, 195, 103, "VELOCITY"
	sd_ptext	0x17, 10, 88, 200, "TONE"
	sd_ctext	0x06, 10, 205*40+34, "CURS0R"
	sd_ptext	0x17, 11, 36, 209, "GROUP"
	sd_ptext	0x17, 14, 76, 209, "WAVEFORM"
	sd_ptext	0x17, 14, 196, 209, "VELOCITY"
	sd_ctext	0x06, 5, 218*40+6, "\215"
	sd_ctext	0x06, 5, 218*40+12, "\215"
	sd_ctext	0x06, 5, 218*40+27, "\215"
	sd_ctext	0x07, 5, 217*40+37, "\215"
	sd_ctext	0x06, 5, 228*40+6, "\216"
	sd_ctext	0x06, 5, 228*40+12, "\216"
	sd_ctext	0x06, 5, 228*40+27, "\216"
	sd_ctext	0x07, 5, 227*40+37, "\216"
	sd_quad	0x22, 60, 97, 253, 183
	sd_quad	0x22, 41, 218, 62, 238
	sd_quad	0x22, 89, 218, 110, 238
	sd_quad	0x22, 209, 218, 230, 238
	sd_quad	0x22, 285, 218, 314, 238
	sd_quad	0x01, 85, 38, 128, 38
	sd_quad	0x01, 157, 38, 207, 38
	sd_quad	0x09, 207, 57, 245, 58
	sd_quad	0x01, 242, 58, 245, 58
	sd_quad	0x01, 85, 81, 207, 81
	sd_quad	0x01, 60, 114, 253, 114
	sd_quad	0x01, 41, 228, 62, 228
	sd_quad	0x01, 89, 228, 110, 228
	sd_quad	0x01, 209, 228, 230, 228
	sd_quad	0x01, 285, 228, 314, 228
	sd_quad	0x02, 85, 38, 85, 81
	sd_quad	0x02, 189, 97, 189, 183
	sd_quad	0x02, 207, 38, 207, 81
	sd_quad	0x02, 242, 54, 242, 61
	sd_quad	0x02, 243, 55, 243, 60
	sd_quad	0x02, 244, 56, 244, 59
; static record list (3 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x4447
; evidence: SeMenu_PresetManager_Data
SeScreenData_0x441A:
	sd_ptext	0x1c, 19, 114, 5, "TONE DYNAMICS"
	sd_ptext	0x17, 16, 6, 7, "SOUND EDIT"
	sd_quad	0x09, 4, 4, 68, 16
; static record list (8 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x4486
; evidence: SeMenu_WaveformSelect_Apply
SeScreenData_0x4447:
	sd_ctext	0x07, 5, 74*40+39, "\021"
	sd_ctext	0x20, 7, 75*40+35, "YES"
	sd_ctext	0x07, 5, 113*40+39, "\021"
	sd_ctext	0x20, 6, 114*40+35, "NO"
	sd_quad	0x09, 275, 70, 309, 89
	sd_quad	0x09, 277, 72, 307, 87
	sd_quad	0x09, 275, 109, 309, 128
	sd_quad	0x09, 277, 111, 307, 126
; static record list (6 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x44F5
; evidence: bounds at SeScreenData_0x46B4
SeScreenData_0x4486:
	sd_ctext	0x08, 14, 64*40+7, "ATTENTION!"
	sd_ctext	0x07, 30, 105*40+4, "THE SELECTED DRUM KIT WILL"
	sd_ctext	0x07, 30, 134*40+4, "BE COPIED TO THE USER KIT."
	sd_ctext	0x08, 17, 166*40+4, "ARE YOU SURE?"
	sd_quad	0x22, 7, 47, 267, 204
	sd_quad	0x09, 54, 80, 212, 81
; static record list (6 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x4560
; evidence: bounds at SeScreenData_0x46B4
SeScreenData_0x44F5:
	sd_ctext	0x08, 12, 50*40+9, "ACHTUNG!"
	sd_ctext	0x07, 35, 93*40+1, "SIE KOPIEREN EIN PRESET-DRUMKIT"
	sd_ctext	0x07, 20, 118*40+1, "IN DAS USER KIT."
	sd_ctext	0x08, 20, 164*40+1, "SIND SIE SICHER?"
	sd_quad	0x22, 2, 33, 267, 201
	sd_quad	0x09, 72, 66, 198, 67
; static record list (9 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x45DE
; evidence: bounds at SeScreenData_0x46B4
SeScreenData_0x4560:
	sd_ctext	0x08, 14, 54*40+7, "ATTENTION!"
	sd_ctext	0x07, 28, 93*40+5, "COPIE DU DRUMKIT VERS LE"
	sd_ctext	0x07, 13, 118*40+5, "USER KIT."
	sd_ctext	0x07, 23, 155*40+8, "VEUILLEZ CONFIRMER,"
	sd_ctext	0x07, 5, 171*40+10, ","
	sd_ctext	0x07, 5, 181*40+9, "S"
	sd_ctext	0x07, 18, 181*40+11, "IL VOUS PLAIT!"
	sd_quad	0x22, 3, 37, 270, 210
	sd_quad	0x09, 54, 70, 216, 71
; static record list (7 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x464E
; evidence: bounds at SeScreenData_0x46B4
SeScreenData_0x45DE:
	sd_ctext	0x08, 13, 65*40+8, "ATENCION!"
	sd_ctext	0x07, 33, 99*40+3, "COPIA DEL EQUIPO DE TAMBOR EN"
	sd_ctext	0x07, 26, 125*40+3, "EL EQUIPO DEL USUARIO."
	sd_ctext	0x08, 9, 163*40+4, "\273EST\264"
	sd_ctext	0x08, 11, 163*40+16, "SEGURO?"
	sd_quad	0x22, 7, 47, 267, 204
	sd_quad	0x09, 64, 81, 203, 82
; static record list (8 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x46B4
; evidence: bounds at SeScreenData_0x46B4
SeScreenData_0x464E:
	sd_ctext	0x08, 15, 66*40+6, "ATTENZIONE!"
	sd_ctext	0x07, 25, 107*40+6, "COPIATURA DEL DRUMKIT"
	sd_ctext	0x07, 5, 123*40+9, ","
	sd_ctext	0x07, 7, 133*40+6, "ALL"
	sd_ctext	0x07, 13, 133*40+10, "USER KIT."
	sd_ctext	0x08, 17, 171*40+4, "SIETE SICURI?"
	sd_quad	0x22, 7, 47, 267, 204
	sd_quad	0x09, 46, 82, 221, 83
; list-boundary table: entry i and i+1 bound list i (6 entries, LE32)
; evidence: SeMenu_WaveformSelect_Apply
SeScreenData_0x46B4:
	.long	SeScreenData_0x4486
	.long	SeScreenData_0x44F5
	.long	SeScreenData_0x4560
	.long	SeScreenData_0x45DE
	.long	SeScreenData_0x464E
	.long	SeScreenData_0x46B4
; static record list (24 records), read by GraphicsRender_ProcessEntries; ends SeScreenData_0x4726, SeScreenData_0x4744, SeScreenData_0x4762 ...
; evidence: SeMenu_NameEdit_DataBlock1
SeScreenData_0x46CC:
	sd_ctext	0x06, 5, 218*40+2, "\215"
	sd_ctext	0x06, 5, 228*40+2, "\216"
	sd_quad	0x22, 9, 218, 30, 238
	sd_quad	0x01, 9, 228, 30, 228
	sd_ctext	0x06, 5, 218*40+7, "\215"
	sd_ctext	0x06, 5, 228*40+7, "\216"
	sd_quad	0x22, 49, 218, 70, 238
	sd_quad	0x01, 49, 228, 70, 228
	sd_ctext	0x06, 5, 218*40+12, "\215"
	sd_ctext	0x06, 5, 228*40+12, "\216"
	sd_quad	0x22, 89, 218, 110, 238
	sd_quad	0x01, 89, 228, 110, 228
	sd_ctext	0x06, 5, 218*40+17, "\215"
	sd_ctext	0x06, 5, 228*40+17, "\216"
	sd_quad	0x22, 129, 218, 150, 238
	sd_quad	0x01, 129, 228, 150, 228
	sd_ctext	0x06, 5, 218*40+22, "\215"
	sd_ctext	0x06, 5, 228*40+22, "\216"
	sd_quad	0x22, 169, 218, 190, 238
	sd_quad	0x01, 169, 228, 190, 228
	sd_ctext	0x06, 5, 218*40+27, "\215"
	sd_ctext	0x06, 5, 228*40+27, "\216"
	sd_quad	0x22, 209, 218, 230, 238
	sd_quad	0x01, 209, 228, 230, 228
; static record list (8 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x47BC
; evidence: SeMenu_NameEdit_DataBlock1
SeScreenData_0x4780:
	sd_ctext	0x06, 5, 218*40+32, "\215"
	sd_ctext	0x06, 5, 228*40+32, "\216"
	sd_quad	0x22, 249, 218, 270, 238
	sd_quad	0x01, 249, 228, 270, 228
; static record list (4 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x47BC
; evidence: SeMenu_NameEdit_DataBlock1
SeScreenData_0x479E:
	sd_ctext	0x06, 5, 218*40+37, "\215"
	sd_ctext	0x06, 5, 228*40+37, "\216"
	sd_quad	0x22, 289, 218, 310, 238
	sd_quad	0x01, 289, 228, 310, 228
; static record list (31 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x48DB
; evidence: SeMenu_NameEdit_DataBlock1
SeScreenData_0x47BC:
	sd_ctext	0x06, 13, 160*40+11, "INTENSITY"
	sd_ctext	0x06, 5, 160*40+25, ":"
	sd_ptext	0x17, 13, 240, 209, "INTENS."
; static record list (28 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x48DB
; evidence: SeMenu_NameEdit_DataBlock1
SeScreenData_0x47DB:
	sd_op23	0x0a, 3*40+10
	sd_ptext	0x1c, 20, 111, 5, "DIGITAL EFFECT"
	sd_ptext	0x17, 16, 6, 7, "SOUND EDIT"
	sd_ctext	0x06, 8, 51*40+11, "TYPE"
	sd_ctext	0x06, 5, 51*40+16, ":"
	sd_ptext	0x17, 7, 310, 70, "\221"
	sd_ctext	0x07, 5, 73*40+0, "\020"
	sd_ctext	0x07, 7, 73*40+36, "\215  "
	sd_ctext	0x07, 5, 74*40+39, "\251"
	sd_ctext	0x06, 8, 93*40+34, "TYPE"
	sd_ptext	0x17, 7, 310, 109, "\221"
	sd_ctext	0x07, 5, 112*40+0, "\020"
	sd_ctext	0x07, 7, 112*40+36, "\216  "
	sd_ctext	0x07, 5, 113*40+39, "\251"
	sd_ctext	0x06, 19, 175*40+11, "REVERB DEPTH  :"
	sd_ptext	0x17, 12, 282, 209, "REVERB"
	sd_quad	0x09, 4, 4, 68, 16
	sd_quad	0x22, 71, 46, 251, 187
	sd_quad	0x09, 274, 69, 309, 88
	sd_quad	0x09, 12, 70, 44, 89
	sd_quad	0x09, 276, 71, 307, 86
	sd_quad	0x09, 14, 72, 42, 87
	sd_quad	0x09, 12, 108, 68, 127
	sd_quad	0x09, 274, 108, 309, 127
	sd_quad	0x09, 14, 110, 66, 125
	sd_quad	0x09, 276, 110, 307, 125
	sd_quad	0x01, 71, 65, 251, 65
	sd_op23	0x0a, 3*40+10
; static record list (15 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x495E
; evidence: pairs at SeScreenData_0x4BFE
SeScreenData_0x48DB:
	sd_ctext	0x06, 9, 70*40+11, "DEPTH"
	sd_ctext	0x06, 5, 70*40+25, ":"
	sd_ctext	0x06, 9, 85*40+11, "SPEED"
	sd_ctext	0x06, 5, 85*40+25, ":"
	sd_ctext	0x06, 10, 100*40+11, "DETUNE"
	sd_ctext	0x06, 5, 100*40+25, ":"
	sd_ctext	0x06, 9, 115*40+11, "DELAY"
	sd_ctext	0x06, 5, 115*40+25, ":"
	sd_ctext	0x06, 11, 130*40+11, "BALANCE"
	sd_ctext	0x06, 5, 130*40+25, ":"
	sd_ptext	0x17, 11, 6, 209, "DEPTH"
	sd_ptext	0x17, 11, 45, 209, "SPEED"
	sd_ptext	0x17, 12, 82, 209, "DETUNE"
	sd_ptext	0x17, 11, 124, 209, "DELAY"
	sd_ptext	0x17, 13, 160, 209, "BALANCE"
; static record list (18 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x49FE
; evidence: pairs at SeScreenData_0x4BFE
SeScreenData_0x495E:
	sd_ctext	0x06, 10, 70*40+11, "DEPTH1"
	sd_ctext	0x06, 5, 70*40+25, ":"
	sd_ctext	0x06, 10, 85*40+11, "SPEED1"
	sd_ctext	0x06, 5, 85*40+25, ":"
	sd_ctext	0x06, 10, 100*40+11, "DEPTH2"
	sd_ctext	0x06, 5, 100*40+25, ":"
	sd_ctext	0x06, 10, 115*40+11, "SPEED2"
	sd_ctext	0x06, 5, 115*40+25, ":"
	sd_ctext	0x06, 10, 130*40+11, "DETUNE"
	sd_ctext	0x06, 5, 130*40+25, ":"
	sd_ctext	0x06, 9, 145*40+11, "DELAY"
	sd_ctext	0x06, 5, 145*40+25, ":"
	sd_ptext	0x17, 12, 2, 209, "DEPTH1"
	sd_ptext	0x17, 12, 42, 209, "SPEED1"
	sd_ptext	0x17, 12, 82, 209, "DEPTH2"
	sd_ptext	0x17, 12, 122, 209, "SPEED2"
	sd_ptext	0x17, 12, 162, 209, "DETUNE"
	sd_ptext	0x17, 11, 205, 209, "DELAY"
; static record list (12 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x4A64
; evidence: pairs at SeScreenData_0x4BFE
SeScreenData_0x49FE:
	sd_ctext	0x06, 9, 70*40+11, "DEPTH"
	sd_ctext	0x06, 5, 70*40+25, ":"
	sd_ctext	0x06, 9, 85*40+11, "SPEED"
	sd_ctext	0x06, 5, 85*40+25, ":"
	sd_ctext	0x06, 8, 100*40+11, "WAVE"
	sd_ctext	0x06, 5, 100*40+25, ":"
	sd_ctext	0x06, 11, 115*40+11, "BALANCE"
	sd_ctext	0x06, 5, 115*40+25, ":"
	sd_ptext	0x17, 11, 5, 209, "DEPTH"
	sd_ptext	0x17, 11, 44, 209, "SPEED"
	sd_ptext	0x17, 10, 88, 209, "WAVE"
	sd_ptext	0x17, 13, 119, 209, "BALANCE"
; static record list (12 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x4AD0
; evidence: pairs at SeScreenData_0x4BFE
SeScreenData_0x4A64:
	sd_ctext	0x06, 10, 70*40+11, "DEPTH1"
	sd_ctext	0x06, 5, 70*40+25, ":"
	sd_ctext	0x06, 10, 85*40+11, "SPEED1"
	sd_ctext	0x06, 5, 85*40+25, ":"
	sd_ctext	0x06, 10, 100*40+11, "DEPTH2"
	sd_ctext	0x06, 5, 100*40+25, ":"
	sd_ctext	0x06, 10, 115*40+11, "SPEED2"
	sd_ctext	0x06, 5, 115*40+25, ":"
	sd_ptext	0x17, 12, 2, 209, "DEPTH1"
	sd_ptext	0x17, 12, 42, 209, "SPEED1"
	sd_ptext	0x17, 12, 82, 209, "DEPTH2"
	sd_ptext	0x17, 12, 122, 209, "SPEED2"
; static record list (12 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x4B3C
; evidence: pairs at SeScreenData_0x4BFE
SeScreenData_0x4AD0:
	sd_ctext	0x06, 9, 70*40+11, "DELAY"
	sd_ctext	0x06, 5, 70*40+25, ":"
	sd_ctext	0x06, 10, 85*40+11, "DETUNE"
	sd_ctext	0x06, 5, 85*40+25, ":"
	sd_ctext	0x06, 13, 100*40+11, "KEY SHIFT"
	sd_ctext	0x06, 5, 100*40+25, ":"
	sd_ctext	0x06, 11, 115*40+11, "BALANCE"
	sd_ctext	0x06, 5, 115*40+25, ":"
	sd_ptext	0x17, 11, 2, 209, "DELAY"
	sd_ptext	0x17, 12, 42, 209, "DETUNE"
	sd_ptext	0x17, 9, 91, 209, "KEY"
	sd_ptext	0x17, 13, 120, 209, "BALANCE"
; static record list (12 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x4BA8
; evidence: pairs at SeScreenData_0x4BFE
SeScreenData_0x4B3C:
	sd_ctext	0x06, 9, 70*40+11, "SPEED"
	sd_ctext	0x06, 5, 70*40+25, ":"
	sd_ctext	0x06, 9, 85*40+11, "DECAY"
	sd_ctext	0x06, 5, 85*40+25, ":"
	sd_ctext	0x06, 11, 100*40+11, "SUSTAIN"
	sd_ctext	0x06, 5, 100*40+25, ":"
	sd_ctext	0x06, 11, 115*40+11, "RELEASE"
	sd_ctext	0x06, 5, 115*40+25, ":"
	sd_ptext	0x17, 11, 4, 209, "SPEED"
	sd_ptext	0x17, 11, 45, 209, "DECAY"
	sd_ptext	0x17, 13, 80, 209, "SUSTAIN"
	sd_ptext	0x17, 13, 128, 209, "RELEASE"
; static record list (9 records), read by GraphicsRender_ProcessEntries; end SeScreenData_0x4BFE
; evidence: pairs at SeScreenData_0x4BFE
SeScreenData_0x4BA8:
	sd_ctext	0x06, 14, 70*40+11, "DISTORTION"
	sd_ctext	0x06, 5, 70*40+25, ":"
	sd_ctext	0x06, 15, 85*40+11, "TOUCH DEPTH"
	sd_ctext	0x06, 5, 85*40+25, ":"
	sd_ctext	0x06, 9, 100*40+11, "DEPTH"
	sd_ctext	0x06, 5, 100*40+25, ":"
	sd_ptext	0x17, 11, 7, 209, "DIST."
	sd_ptext	0x17, 11, 45, 209, "TOUCH"
	sd_ptext	0x17, 11, 85, 209, "DEPTH"
; (start, end) pair table, 8 bytes per list (24 entries, LE32)
; evidence: SeMenu_NameEdit_DataBlock1
SeScreenData_0x4BFE:
	.long	SeScreenData_0x48DB, SeScreenData_0x495E
	.long	SeScreenData_0x48DB, SeScreenData_0x495E
	.long	SeScreenData_0x48DB, SeScreenData_0x495E
	.long	SeScreenData_0x48DB, SeScreenData_0x495E
	.long	SeScreenData_0x495E, SeScreenData_0x49FE
	.long	SeScreenData_0x495E, SeScreenData_0x49FE
	.long	SeScreenData_0x49FE, SeScreenData_0x4A64
	.long	SeScreenData_0x4A64, SeScreenData_0x4AD0
	.long	SeScreenData_0x4AD0, SeScreenData_0x4B3C
	.long	SeScreenData_0x4B3C, SeScreenData_0x4BA8
	.long	SeScreenData_0x4BA8, SeScreenData_0x4BFE
	.long	SeScreenData_0x4BA8, SeScreenData_0x4BFE
; bound record list (5 records), read by GraphicsRender_Start; ends FlashRead_BlockData_Field7, SeScreenData_End
; evidence: SeMenu_NameEdit_DataBlock1
SeScreenData_0x4C5E:
	sdb_str	0x0660, 0x0f, 0, 0x20, SeScreenData_0x4EFB, 13, 51*40+17
; bound record list (2 records), read by GraphicsRender_Start; end FlashRead_BlockData_Field8
; evidence: SeMenu_PatchEdit_DataBlock
SeScreenData_0x4C6D:
	sdb_str	0x0660, 0x80, 7, 0x20, SeScreenData_0x08D1, 3, 75*40+2
	sdb_str	0x0660, 0x40, 6, 0x20, TuningSys_Param_01_Data, 6, 113*40+2
FlashRead_BlockData_Field8:
	sdb_snum	0x0668, 0xff, 0, 0x20, 175*40+27, 2, 0x00
FlashRead_BlockData_Field7:
	sdb_snum	0x0667, 0xff, 0, 0x20, 160*40+27, 2, 0x00
SeScreenData_End:

	.include "storage/flash_floppy_handlers.s"

S2cShowHideFunc:
	cp xbc, EVT_REPAINT
	jr z, S2cShow_ReturnZero
	cp xbc, EVT_PAINT
	jr z, S2cShow_ReturnZero
	cp xbc, EVT_HIDE
	jr z, S2cShow_ReturnZero
	cp xbc, EVT_SHOW
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
	cp xbc, EVT_REQUEST_GRID_DRAW
	jrl z, S2c_GridCheck_Dispatch
	sub xwa, EVT_INDEXSW_UP
	cp xwa, 0x0
	jrl lt, S2c_GridCheck_EventEnc
	cp xwa, 0x6
	jrl gt, S2c_GridCheck_EventEnc
	add xwa, xwa
	add xwa, S2cGridCheck_CaseTable
	ld wa, (xwa)
	lda xix, (S2c_GridCheck_DataBlock:24)
	jp	t, (xix+wa)

S2c_GridCheck_DataBlock:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	ld	xde, xhl
	lda	xwa, (xsp+10)
	ld	xbc, xde
	srl	xbc, 16
	ld	qbc, 0
	ld	(xwa), bc
	ld	(xwa+2), de
	cpw	(xwa), 1
	jrl	nz, S2c_GridCheck_EventEnc
	exts	xde
	ld	xwa, NAKA_MAINFUNC_MainS2cFunc
	ld	xbc, EVT_S2C_TR_UP
	jr	S2cGridCheck_Join
S2cGridCheck_OnIndexswDown:	; cases 29360152, 29360154
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	ld	xde, xhl
	lda	xwa, (xsp+10)
	ld	xbc, xde
	srl	xbc, 16
	ld	qbc, 0
	ld	(xwa), bc
	ld	(xwa+2), de
	cpw	(xwa), 1
	jr	nz, S2c_GridCheck_EventEnc
	exts	xde
	ld	xwa, NAKA_MAINFUNC_MainS2cFunc
	ld	xbc, EVT_S2C_TR_DN
S2cGridCheck_Join:
	call	MainFuncCall
	jr	S2c_GridCheck_EventEnc

; S2cGridCheck dispatch
S2c_GridCheck_Dispatch:
	lda xbc, (xsp + 10)
	ld xwa, xde
	srl xwa, 16
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
	lda xbc, (S2c_GridCheck_Dispatch_Data:24)
	ld	xwa, (xbc+wa)
	ld a, (xwa)
	extz wa
	sla wa, 2
	lda xbc, (0x03dc4e:24)
	ld	xwa, (xbc+wa)
	push xwa
	push xde
	call Sprintf_Locked
	inc 8, xsp

S2c_GridCheck_GetFocusSendEvt:
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 10)
	ld xbc, EVT_GRID_DRAW
	call SendEvent

; S2cGridCheck event encoding dispatch
S2c_GridCheck_EventEnc:
	ld xhl, 0:i3
	lda xsp, (xsp + 18)
	ret

CmpClrYesFunc:
	ld xwa, NAKA_MAINFUNC_MiddleCmpClrFunc
	ld xbc, EVT_CMP_CLR_YES
	ld xde, 0:i3
	call MainFuncCall
	ld xhl, 0:i3
	ret

CmpClrNoFunc:
	ld xwa, NAKA_MAINFUNC_MiddleCmpClrFunc
	ld xbc, EVT_CMP_CLR_NO
	ld xde, 0:i3
	call MainFuncCall
	ld xhl, 0:i3
	ret

PsCmpCpFGrpBoxProc:
	lda xsp, (xsp-272)
	push xiz
	ld	(xsp+268), xde
	ld	(xsp+272), xwa
	cp xbc, EVT_AP_RHY_GRP_NM
	jr z, PsCmpCpFGrpBoxProc_OnApRhyGrpNm
	cp xbc, EVT_REPAINT
	jr z, PsCmpCpFGrpBoxProc_OnPaintOrRepaint
	cp xbc, EVT_PAINT
	jr z, PsCmpCpFGrpBoxProc_OnPaintOrRepaint
	cp xbc, EVT_HIDE
	jr z, PsCmpCpFGrpBoxProc_OnHide
	cp xbc, EVT_SHOW
	jr z, PsCmpCpFGrpBoxProc_OnShow
	ld XWA, (xsp + 0x0110)
	ld XDE, (xsp + 0x010c)
	call InheritedProc
	jrl PsCmpCpFGrpBox_Epilogue

PsCmpCpFGrpBoxProc_OnShow:
	ld XWA, (xsp + 0x0110)
	ld XDE, (xsp + 0x010c)
	jr PsCmpCpFGrpBox_CallInherited

PsCmpCpFGrpBoxProc_OnHide:
	ld XWA, (xsp + 0x0110)
	ld XDE, (xsp + 0x010c)

PsCmpCpFGrpBox_CallInherited:
	call InheritedProc
	jrl PsCmpCpFGrpBox_ReturnZero

PsCmpCpFGrpBoxProc_OnPaintOrRepaint:
	ld XWA, (xsp + 0x0110)
	ld XDE, (xsp + 0x010c)
	call InheritedProc
	ld xwa, NAKA_MAINFUNC_MainCmpCpFunc
	ld xbc, EVT_RHY_GRP_NM_GET
	ld xde, 0:i3
	call MainFuncCall
	jrl PsCmpCpFGrpBox_ReturnZero

PsCmpCpFGrpBoxProc_OnApRhyGrpNm:
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
	ld xbc, EVT_DRAW
	ld xde, 0:i3
	call SendEvent
	lda xde, (xsp + 12)
	ld XWA, (xsp + 0x0110)
	ld xbc, EVT_PARA_DRAW
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
	lda xsp, (xsp+272)
	ret

PsCmpCpFVariBoxProc:
	lda xsp, (xsp-272)
	push xiz
	ld	(xsp+268), xde
	ld	(xsp+272), xwa
	cp xbc, EVT_AP_RHY_VARI_NM
	jr z, PsCmpCpFVariBoxProc_OnApRhyVariNm
	cp xbc, EVT_REPAINT
	jr z, PsCmpCpFVariBoxProc_OnPaintOrRepaint
	cp xbc, EVT_PAINT
	jr z, PsCmpCpFVariBoxProc_OnPaintOrRepaint
	cp xbc, EVT_HIDE
	jr z, PsCmpCpFVariBoxProc_OnHide
	cp xbc, EVT_SHOW
	jr z, PsCmpCpFVariBoxProc_OnShow
	ld XWA, (xsp + 0x0110)
	ld XDE, (xsp + 0x010c)
	call InheritedProc
	jrl PsCmpCpFVariBox_Epilogue

PsCmpCpFVariBoxProc_OnShow:
	ld XWA, (xsp + 0x0110)
	ld XDE, (xsp + 0x010c)
	jr PsCmpCpFVariBox_CallInherited

PsCmpCpFVariBoxProc_OnHide:
	ld XWA, (xsp + 0x0110)
	ld XDE, (xsp + 0x010c)

PsCmpCpFVariBox_CallInherited:
	call InheritedProc
	jrl DesignFrame_Return

PsCmpCpFVariBoxProc_OnPaintOrRepaint:
	ld XWA, (xsp + 0x0110)
	ld XDE, (xsp + 0x010c)
	call InheritedProc
	ld xwa, NAKA_MAINFUNC_MainCmpCpFunc
	ld xbc, EVT_RHY_VARI_NM_GET
	ld xde, 0:i3
	call MainFuncCall
	jrl DesignFrame_Return

PsCmpCpFVariBoxProc_OnApRhyVariNm:
	call GetTitleNow
	cp xhl, TITLE_MESAGE
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
	ld xbc, EVT_DRAW
	ld xde, 0:i3
	call SendEvent
	lda xde, (xsp + 12)
	ld XWA, (xsp + 0x0110)
	ld xbc, EVT_PARA_DRAW
	call SendEvent
	call GetTitleNow
	cp xhl, TITLE_CMPNCP
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
	lda xsp, (xsp+272)
	ret

PsCmpCpFPtnBoxProc:
	lda xsp, (xsp-268)
	push xiz
	ld	(xsp+268), xwa
	cp xbc, EVT_REPAINT
	jr z, PsCmpCpFPtnBoxProc_OnPaintOrRepaint
	cp xbc, EVT_PAINT
	jr z, PsCmpCpFPtnBoxProc_OnPaintOrRepaint
	cp xbc, EVT_HIDE
	jr z, PsCmpCpFPtnBoxProc_OnHide
	cp xbc, EVT_SHOW
	jr z, PsCmpCpFPtnBoxProc_OnShow
	ld XWA, (xsp + 0x010c)
	call InheritedProc
	jrl PsCmpCpFPtnBox_Epilogue

PsCmpCpFPtnBoxProc_OnShow:
	ld XWA, (xsp + 0x010c)
	jr PsCmpCpFPtnBox_CallInherited

PsCmpCpFPtnBoxProc_OnHide:
	ld XWA, (xsp + 0x010c)

PsCmpCpFPtnBox_CallInherited:
	call InheritedProc
	jrl PsCmpCpFPtnBox_ReturnZero

PsCmpCpFPtnBoxProc_OnPaintOrRepaint:
	ld XWA, (xsp + 0x010c)
	call InheritedProc
	ld XWA, (xsp + 0x010c)
	call GetViewInstance
	ld xiz, xhl
	ld a, (0x34ef:16)
	extz wa
	sla wa, 2
	lda xbc, (PsCmpCpFPtnBox_HandleEvtBC_Data:24)
	ld	xwa, (xbc+wa)
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
	ld xbc, EVT_DRAW
	ld xde, 0:i3
	call SendEvent
	lda xde, (xsp + 12)
	ld XWA, (xsp + 0x010c)
	ld xbc, EVT_PARA_DRAW
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
	lda xsp, (xsp+268)
	ret

PsCstmCpBnkBoxProc:
	lda xsp, (xsp-256)
	push xiz
	ld xiz, xwa
	cp xbc, EVT_REPAINT
	jr z, PsCstmCpBnkBoxProc_OnPaintOrRepaint
	cp xbc, EVT_PAINT
	jr z, PsCstmCpBnkBoxProc_OnPaintOrRepaint
	cp xbc, EVT_HIDE
	jr z, PsCstmCpBnkBoxProc_OnHide
	cp xbc, EVT_SHOW
	jr z, PsCstmCpBnkBoxProc_OnShow
	ld xwa, xiz
	call InheritedProc
	jr PsCstmCpBnkBox_Epilogue

PsCstmCpBnkBoxProc_OnShow:
	ld xwa, xiz
	jr PsCstmCpBnkBox_CallInherited

PsCstmCpBnkBoxProc_OnHide:
	ld xwa, xiz

PsCstmCpBnkBox_CallInherited:
	call InheritedProc
	jr PsCstmCpBnkBox_ReturnZero

PsCstmCpBnkBoxProc_OnPaintOrRepaint:
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
	ld	xwa, (xbc+wa)
	push xwa
	lda xwa, (xsp + 8)
	push xwa
	call Sprintf_Locked
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	call SendEvent

PsCstmCpBnkBox_ReturnZero:
	ld xhl, 0:i3

PsCstmCpBnkBox_Epilogue:
	pop xiz
	lda xsp, (xsp+256)
	ret

PsCstmCpSwBoxProc:
	lda xsp, (xsp-256)
	push xiz
	ld xiz, xwa
	cp xbc, EVT_REPAINT
	jr z, PsCstmCpSwBoxProc_OnPaintOrRepaint
	cp xbc, EVT_PAINT
	jr z, PsCstmCpSwBoxProc_OnPaintOrRepaint
	cp xbc, EVT_HIDE
	jr z, PsCstmCpSwBoxProc_OnHide
	cp xbc, EVT_SHOW
	jr z, PsCstmCpSwBoxProc_OnShow
	ld xwa, xiz
	call InheritedProc
	jr PsCstmCpSwBox_Epilogue

PsCstmCpSwBoxProc_OnShow:
	ld xwa, xiz
	jr PsCstmCpSwBox_CallInherited

PsCstmCpSwBoxProc_OnHide:
	ld xwa, xiz

PsCstmCpSwBox_CallInherited:
	call InheritedProc
	jr PsCstmCpSwBox_ReturnZero

PsCstmCpSwBoxProc_OnPaintOrRepaint:
	ld xwa, xiz
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	lda xbc, (xsp + 4)
	cp (xhl + 36), 0x0
	jr nz, PsCstmCpSwBox_ReadParam2
	ld xwa, PsCstmCpSwBox_HandleEvtBC_Str_CUSTOM
	cp (0x39b6:16), 10
	jr nc, PsCstmCpSwBox_PushTableAddr0
	ld xwa, PsCstmCpSwBox_HandleEvtBC_Str_MEMORY

PsCstmCpSwBox_PushTableAddr0:
	push xwa
	push xbc
	jr PsCstmCpSwBox_SendCommand

PsCstmCpSwBox_ReadParam2:
	ld xwa, PsCstmCpSwBox_ReadParam2_Str_CUSTOM
	cp (0x39b7:16), 10
	jr nc, PsCstmCpSwBox_PushTableAddr1
	ld xwa, PsCstmCpSwBox_ReadParam2_Str_MEMORY

PsCstmCpSwBox_PushTableAddr1:
	push xwa
	push xbc

PsCstmCpSwBox_SendCommand:
	call Sprintf_Locked
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	call SendEvent

PsCstmCpSwBox_ReturnZero:
	ld xhl, 0:i3

PsCstmCpSwBox_Epilogue:
	pop xiz
	lda xsp, (xsp+256)
	ret

PsCstmCpNameBoxProc:
	lda xsp, (xsp-260)
	push xiz
	ld	(xsp+260), xde
	ld xiz, xwa
	cp xbc, EVT_CSTM_T_NM_DISP
	jrl z, PsCstmCpNameBoxProc_OnCstmTNmDisp
	cp xbc, EVT_CSTM_F_NM_DISP
	jrl z, PsCstmCpNameBoxProc_OnCstmFNmDisp
	cp xbc, EVT_DRAW
	jr z, PsCstmCpNameBoxProc_OnDraw
	cp xbc, EVT_HIDE
	jr z, PsCstmCpNameBoxProc_OnHide
	cp xbc, EVT_SHOW
	jr z, PsCstmCpNameBoxProc_OnShow
	ld xwa, xiz
	ld XDE, (xsp + 0x0104)
	call InheritedProc
	jrl PsCstmCpNameBox_Epilogue

PsCstmCpNameBoxProc_OnShow:
	ld xwa, xiz
	ld XDE, (xsp + 0x0104)
	jr PsCstmCpNameBox_CallInherited

PsCstmCpNameBoxProc_OnHide:
	ld xwa, xiz
	ld XDE, (xsp + 0x0104)

PsCstmCpNameBox_CallInherited:
	call InheritedProc
	jrl PsCtmAtt_ReturnZero

PsCstmCpNameBoxProc_OnDraw:
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
	ld xwa, NAKA_MAINFUNC_MainCstmNameFunc
	ld xbc, EVT_CSTM_F_NM_GET
	ld xde, 0:i3
	jr PsCstmCpNameBox_MainFuncCall

PsCstmCpNameBox_FuncCall2C:
	ld xwa, NAKA_MAINFUNC_MainCstmNameFunc
	ld xbc, EVT_CSTM_T_NM_GET
	ld xde, 0:i3

PsCstmCpNameBox_MainFuncCall:
	call MainFuncCall
	jr PsCtmAtt_ReturnZero

PsCstmCpNameBoxProc_OnCstmFNmDisp:
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
	ld xbc, EVT_PARA_DRAW
	jr PsCstmCpNameBox_SendEventJoin

PsCstmCpNameBoxProc_OnCstmTNmDisp:
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
	ld xbc, EVT_PARA_DRAW

PsCstmCpNameBox_SendEventJoin:
	call SendEvent

PsCtmAtt_ReturnZero:
	ld xhl, 0:i3

PsCstmCpNameBox_Epilogue:
	pop xiz
	lda xsp, (xsp+260)
	ret

PsCtmAttStrBoxProc:
	lda xsp, (xsp-256)
	push xiz
	ld xiz, xwa
	cp xbc, EVT_REPAINT
	jr z, PsCtmAttStrBoxProc_OnPaintOrRepaint
	cp xbc, EVT_PAINT
	jr z, PsCtmAttStrBoxProc_OnPaintOrRepaint
	cp xbc, EVT_HIDE
	jr z, PsCtmAttStrBoxProc_OnHide
	cp xbc, EVT_SHOW
	jr z, PsCtmAttStrBoxProc_OnShow
	ld xwa, xiz
	call InheritedProc
	jr PsCtmAttStrBox_Epilogue

PsCtmAttStrBoxProc_OnShow:
	ld xwa, xiz
	jr PsCtmAttStrBox_CallInherited

PsCtmAttStrBoxProc_OnHide:
	ld xwa, xiz

PsCtmAttStrBox_CallInherited:
	call InheritedProc
	jr PsCtmAttStrBox_ReturnZero

PsCtmAttStrBoxProc_OnPaintOrRepaint:
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
	ld xbc, EVT_PARA_DRAW
	call SendEvent

PsCtmAttStrBox_ReturnZero:
	ld xhl, 0:i3

PsCtmAttStrBox_Epilogue:
	pop xiz
	lda xsp, (xsp+256)
	ret

AcMemNoBoxProc:
	lda xsp, (xsp-268)
	push xiz
	ld	(xsp+268), xwa
	cp xbc, EVT_REPAINT
	jr z, AcMemNoBoxProc_OnPaintOrRepaint
	cp xbc, EVT_PAINT
	jr z, AcMemNoBoxProc_OnPaintOrRepaint
	cp xbc, EVT_HIDE
	jr z, AcMemNoBoxProc_OnHide
	cp xbc, EVT_SHOW
	jr z, AcMemNoBoxProc_OnShow
	ld XWA, (xsp + 0x010c)
	call InheritedProc
	jrl AcMemNoBox_Epilogue

AcMemNoBoxProc_OnShow:
	ld XWA, (xsp + 0x010c)
	jr AcMemNoBox_CallInherited

AcMemNoBoxProc_OnHide:
	ld XWA, (xsp + 0x010c)

AcMemNoBox_CallInherited:
	call InheritedProc
	jrl AcMemNoBox_ReturnZero

AcMemNoBoxProc_OnPaintOrRepaint:
	ld XWA, (xsp + 0x010c)
	call InheritedProc
	ld XWA, (xsp + 0x010c)
	call GetViewInstance
	ld xiz, xhl
	ld a, (0x34d6:16)
	extz wa
	sla wa, 2
	lda xbc, (AcMemNoBox_HandleEvtBC_Data:24)
	ld	xwa, (xbc+wa)
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
	ld xbc, EVT_DRAW
	ld xde, 0:i3
	call SendEvent
	lda xde, (xsp + 12)
	ld XWA, (xsp + 0x010c)
	ld xbc, EVT_PARA_DRAW
	call SendEvent
	call GetTitleNow
	cp xhl, TITLE_CMPNCP
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
	lda xsp, (xsp+268)
	ret

AcCmpRecBoxProc:
	lda xsp, (xsp-280)
	push xiz
	ld	(xsp+272), xde
	ld	(xsp+276), xbc
	ld	(xsp+280), xwa
	ld XWA, (xsp + 0x0114)
	cp xwa, EVT_REPAINT
	jr z, AcCmpRecBoxProc_OnPaintOrRepaint
	cp xwa, EVT_PAINT
	jr z, AcCmpRecBoxProc_OnPaintOrRepaint
	cp xwa, EVT_HIDE
	jr z, AcCmpRecBoxProc_OnHide
	cp xwa, EVT_SHOW
	jr z, AcCmpRecBoxProc_OnShow
	ld XWA, (xsp + 0x0118)
	ld XBC, (xsp + 0x0114)
	ld XDE, (xsp + 0x0110)
	call InheritedProc
	jrl AcCmpRecBox_Epilogue

AcCmpRecBoxProc_OnShow:
	ld XWA, (xsp + 0x0118)
	ld XBC, (xsp + 0x0114)
	ld XDE, (xsp + 0x0110)
	jr AcCmpRecBox_CallInherited

AcCmpRecBoxProc_OnHide:
	ld XWA, (xsp + 0x0118)
	ld XBC, (xsp + 0x0114)
	ld XDE, (xsp + 0x0110)

AcCmpRecBox_CallInherited:
	call InheritedProc
	jrl AcCmpRecBox_ReturnZero

AcCmpRecBoxProc_OnPaintOrRepaint:
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
	lda xhl, (AcCmpRecBox_HandleEvtBC_Data:24)
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
	ld xbc, EVT_PARA_DRAW
	call SendEvent

AcCmpRecBox_ReturnZero:
	ld xhl, 0:i3

AcCmpRecBox_Epilogue:
	pop xiz
	lda xsp, (xsp+280)
	ret

PsCmpQtzBoxProc:
	lda xsp, (xsp-256)
	push xiz
	ld xiz, xwa
	cp xbc, EVT_REPAINT
	jr z, PsCmpQtzBoxProc_OnPaintOrRepaint
	cp xbc, EVT_PAINT
	jr z, PsCmpQtzBoxProc_OnPaintOrRepaint
	cp xbc, EVT_HIDE
	jr z, PsCmpQtzBoxProc_OnHide
	cp xbc, EVT_SHOW
	jr z, PsCmpQtzBoxProc_OnShow
	ld xwa, xiz
	call InheritedProc
	jr PsCmpQtzBox_Epilogue

PsCmpQtzBoxProc_OnShow:
	ld xwa, xiz
	jr PsCmpQtzBox_CallInherited

PsCmpQtzBoxProc_OnHide:
	ld xwa, xiz

PsCmpQtzBox_CallInherited:
	call InheritedProc
	jr PsCmpQtzBox_ReturnZero

PsCmpQtzBoxProc_OnPaintOrRepaint:
	ld xwa, xiz
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld a, (0x34db:16)
	extz wa
	sla wa, 2
	lda xbc, (PtrTbl_NotePositionStrs:24)
	ld	xwa, (xbc+wa)
	push xwa
	lda xwa, (xsp + 8)
	push xwa
	call Sprintf_Locked
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	call SendEvent

PsCmpQtzBox_ReturnZero:
	ld xhl, 0:i3

PsCmpQtzBox_Epilogue:
	pop xiz
	lda xsp, (xsp+256)
	ret

PsCmpMeasBoxProc:
	lda xsp, (xsp-264)
	push xiz
	ld	(xsp+260), xde
	ld xiz, xbc
	ld	(xsp+264), xwa
	cp xiz, EVT_REPAINT
	jr z, PsCmpMeasBox_HandleEvtBC
	cp xiz, EVT_PAINT
	jr z, PsCmpMeasBox_HandleEvtBC
	cp xiz, EVT_HIDE
	jr z, PsCmpMeasBox_HandleEvt2
	cp xiz, EVT_SHOW
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
	cp xhl, TITLE_CMREAL
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
	pushw PsCmpMeasBox_HandleEvtBC_Str_Fmtd@hi16
	pushw PsCmpMeasBox_HandleEvtBC_Str_Fmtd@lo16
	lda xwa, (xsp + 10)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	lda xde, (xsp + 4)
	ld XWA, (xsp + 0x0108)
	ld xbc, EVT_PARA_DRAW
	call SendEvent

PsCmpMeasBox_ReturnZero:
	ld xhl, 0:i3

PsCmpMeasBox_Epilogue:
	pop xiz
	lda xsp, (xsp+264)
	ret

PsCmpMemBoxProc:
	lda xsp, (xsp-264)
	push xiz
	ld	(xsp+260), xde
	ld xiz, xbc
	ld	(xsp+264), xwa
	cp xiz, EVT_REPAINT
	jr z, PsCmpMemBox_HandleEvtBC
	cp xiz, EVT_PAINT
	jr z, PsCmpMemBox_HandleEvtBC
	cp xiz, EVT_HIDE
	jr z, PsCmpMemBox_HandleEvt2
	cp xiz, EVT_SHOW
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
	cp xhl, TITLE_CMREAL
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
	pushw PsCmpMemBox_HandleEvtBC_Str_Fmt2d@hi16
	pushw PsCmpMemBox_HandleEvtBC_Str_Fmt2d@lo16
	lda xwa, (xsp + 10)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	lda xde, (xsp + 4)
	ld XWA, (xsp + 0x0108)
	ld xbc, EVT_PARA_DRAW
	call SendEvent

PsCmpMemBox_ReturnZero:
	ld xhl, 0:i3

PsCmpMemBox_Epilogue:
	pop xiz
	lda xsp, (xsp+264)
	ret

AcCmpTempoBoxProc:
	lda xsp, (xsp-260)
	push xiz
	ld xiz, xde
	ld	(xsp+260), xwa
	cp xbc, EVT_LSW_DATA
	jr z, AcCmpTempoBoxProc_OnLswData
	cp xbc, EVT_REPAINT
	jr z, AcCmpTempoBoxProc_OnPaintOrRepaint
	cp xbc, EVT_PAINT
	jr z, AcCmpTempoBoxProc_OnPaintOrRepaint
	cp xbc, EVT_HIDE
	jr z, AcCmpTempoBoxProc_OnHide
	cp xbc, EVT_SHOW
	jr z, AcCmpTempoBoxProc_OnShow
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	jr AcCmpTempoBox_Epilogue

AcCmpTempoBoxProc_OnShow:
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld XWA, (xsp + 0x0104)
	ld xbc, 4:i3
	call SetLswFilter
	jr CmpFunc_Return

AcCmpTempoBoxProc_OnHide:
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld XWA, (xsp + 0x0104)
	ld xbc, 4:i3
	call ResetLswFilter
	jr CmpFunc_Return

AcCmpTempoBoxProc_OnPaintOrRepaint:
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld xwa, 4:i3
	call MainLswGet
	jr CmpFunc_Return

AcCmpTempoBoxProc_OnLswData:
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld xwa, (xiz)
	cp xwa, 0x4
	jr nz, CmpFunc_Return
	pushm (xiz + 4)
	pushw AcCmpTempoBox_HandleEvt1C_Str_Fmt3d@hi16
	pushw AcCmpTempoBox_HandleEvt1C_Str_Fmt3d@lo16
	lda xwa, (xsp + 10)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	lda xde, (xsp + 4)
	ld XWA, (xsp + 0x0104)
	ld xbc, EVT_PARA_DRAW
	call SendEvent

CmpFunc_Return:
	ld xhl, 0:i3

AcCmpTempoBox_Epilogue:
	pop xiz
	lda xsp, (xsp+260)
	ret

CmpNamingCheck:
	push xiz
	ld xiz, xwa
	cp xbc, EVT_GET_STRING_LENGTH
	jr z, CmpNamingCheck_Return0xD
	cp xbc, EVT_GET_NAMING_MODE
	jr z, CmpNamingCheck_ReturnZero
	cp xbc, EVT_GET_STRING
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
	cp xbc, EVT_SW_IN
	jr nz, CmpNameOkFunc_ReturnZero
	call GetNamingWindowID
	ld xwa, xhl
	ld xbc, EVT_GET_STRING
	ld xde, 0x20c62
	call SendEvent
	ld xwa, NAKA_MAINFUNC_MiddleNameFunc
	ld xbc, EVT_CMP_NAME_SET
	ld xde, 0x20c62
	call MainFuncCall

CmpNameOkFunc_ReturnZero:
	ld xhl, 0:i3
	ret

PsNameMemBoxProc:
	lda xsp, (xsp-268)
	push xiz
	ld	(xsp+268), xwa
	cp xbc, EVT_REPAINT
	jr z, PsNameMemBoxProc_OnPaintOrRepaint
	cp xbc, EVT_PAINT
	jr z, PsNameMemBoxProc_OnPaintOrRepaint
	cp xbc, EVT_HIDE
	jr z, PsNameMemBoxProc_OnHide
	cp xbc, EVT_SHOW
	jr z, PsNameMemBoxProc_OnShow
	ld XWA, (xsp + 0x010c)
	call InheritedProc
	jrl EasyCmp_TtlCase3

PsNameMemBoxProc_OnShow:
	ld XWA, (xsp + 0x010c)
	jr PsNameMemBox_CallInherited

PsNameMemBoxProc_OnHide:
	ld XWA, (xsp + 0x010c)

PsNameMemBox_CallInherited:
	call InheritedProc
	jrl EasyCmp_TtlCase2

PsNameMemBoxProc_OnPaintOrRepaint:
	ld XWA, (xsp + 0x010c)
	call InheritedProc
	ld XWA, (xsp + 0x010c)
	call GetViewInstance
	ld xiz, xhl
	ld a, (0x34d6:16)
	extz wa
	sla wa, 2
	lda xbc, (PtrTbl_StyleVarGroupCodes:24)
	ld	xwa, (xbc+wa)
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
	ld xbc, EVT_DRAW
	ld xde, 0:i3
	call SendEvent
	lda xde, (xsp + 4)
	ld XWA, (xsp + 0x010c)
	ld xbc, EVT_PARA_DRAW
	call SendEvent
	call GetTitleNow
	cp xhl, TITLE_CMPNCP
	jr nz, EasyCmp_TtlCase2
	lda xwa, (xsp+260)
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
	lda xsp, (xsp+268)
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
	cp xbc, EVT_REQUEST_GRID_DRAW
	jrl z, EasyCmp_GridCheck_Case3
	ld xwa, (xsp + 16)
	cp xwa, EVT_GET_FIXED_ROW_STR
	jrl z, AcEasyCmpGridBoxProc_OnGetFixedRowStr
	cp xwa, EVT_GET_FIXED_COL_STR
	jrl z, EasyCmp_GridCheck
	cp xwa, EVT_SHOW
	jr z, EasyCmp_DialGrid
	sub xbc, EVT_INDEXSW_UP
	cp xbc, 0x0
	jrl lt, EasyCmp_GridCheck_Case4
	cp xbc, 0x6
	jrl gt, EasyCmp_GridCheck_Case4
	add xbc, xbc
	add xbc, AcEasyCmpGridBoxProc_CaseTable
	ld bc, (xbc)
	lda xix, (EasyCmp_DialGrid:24)
	jp	t, (xix+bc)

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
	jrl EasyCmp_SetDialEnable
AcEasyCmpGridBoxProc_OnIndexswUp:	; cases 29360151, 29360153
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_CHECK_INDEX
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, EasyCmp_SendEvt091
	ld xwa, xiz
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	dec 1, hl
	extz xhl
	add xhl, 0xffff0000
	ld xwa, xiz
	ld xbc, EVT_SELE_DRAW
	ld xde, xhl
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl EasyCmp_ReturnZeroJmp

EasyCmp_SendEvt091:
	ld xwa, xiz
	ld xbc, EVT_CHECK_GRID_INDEX
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
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 12)
	call SetDialDown
	ld wa, 1:i3
	jrl EasyCmp_SetDialEnable
AcEasyCmpGridBoxProc_OnIndexswDown:	; cases 29360152, 29360154
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_CHECK_INDEX
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, EasyCmp_IncSendEvt091
	ld xwa, xiz
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	inc 1, hl
	extz xhl
	add xhl, 0xffff0000
	ld xwa, xiz
	ld xbc, EVT_SELE_DRAW
	ld xde, xhl
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl EasyCmp_ReturnZeroJmp

EasyCmp_IncSendEvt091:
	ld xwa, xiz
	ld xbc, EVT_CHECK_GRID_INDEX
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
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, EVT_INDEXSW_DOWN
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
AcEasyCmpGridBoxProc_OnGetFixedRowStr:
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
	cp xbc, EVT_REQUEST_GRID_DRAW
	jrl z, EasyCmp_GridCheck_EventEnc
	sub xwa, EVT_INDEXSW_UP
	cp xwa, 0x0
	jrl lt, EasyCmp_GridCheck_EventCase4
	cp xwa, 0x6
	jrl gt, EasyCmp_GridCheck_EventCase4
	add xwa, xwa
	add xwa, EasyCmpGridCheck_CaseTable
	ld wa, (xwa)
	lda xix, (EasyCmp_GridCheck_DataBlock:24)
	jp	t, (xix+wa)

EasyCmp_GridCheck_DataBlock:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	ld	xde, xhl
	lda	xwa, (xsp+20)
	ld	xbc, xde
	srl	xbc, 16
	ld	qbc, 0
	ld	(xwa), bc
	ld	(xwa+2), de
	ld	wa, (xwa)
	exts	xde
	cp	wa, 2:i3
	jr	z, EasyCmpGridCheck_Skip
	cp	wa, 1:i3
	jrl	nz, EasyCmp_GridCheck_EventCase4
	ld	xwa, NAKA_MAINFUNC_MainEsCmpFunc
	ld	xbc, EVT_ES_CMP_STYL_UP
	jr	EasyCmpGridCheck_Join
EasyCmpGridCheck_Skip:
	ld	xwa, NAKA_MAINFUNC_MainEsCmpFunc
	ld	xbc, EVT_ES_CMP_VARI_UP
	jr	EasyCmpGridCheck_Join
EasyCmpGridCheck_OnIndexswDown:	; cases 29360152, 29360154
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	ld	xde, xhl
	lda	xwa, (xsp+20)
	ld	xbc, xde
	srl	xbc, 16
	ld	qbc, 0
	ld	(xwa), bc
	ld	(xwa+2), de
	ld	wa, (xwa)
	exts	xde
	cp	wa, 2:i3
	jr	z, EasyCmpGridCheck_Skip2
	cp	wa, 1:i3
	jrl	nz, EasyCmp_GridCheck_EventCase4
	ld	xwa, NAKA_MAINFUNC_MainEsCmpFunc
	ld	xbc, EVT_ES_CMP_STYL_DN
	jr	EasyCmpGridCheck_Join
EasyCmpGridCheck_Skip2:
	ld	xwa, NAKA_MAINFUNC_MainEsCmpFunc
	ld	xbc, EVT_ES_CMP_VARI_DN
EasyCmpGridCheck_Join:
	call	MainFuncCall
	jrl	EasyCmp_GridCheck_EventCase4

; EasyCmpGridCheck event encoding dispatch
EasyCmp_GridCheck_EventEnc:
	lda xbc, (xsp + 20)
	ld xwa, xde
	srl xwa, 16
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
	ld	xwa, (xbc+wa)
	push xwa
	jr EasyCmp_GridCheck_EventCase1

EasyCmp_GridEvtEnc_Case2:
	lda xbc, (0x37b2:16)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, 0:i3
	jr nz, EasyCmp_GridCheck_EventCase2
	ld xwa, EasyCmp_GridCheck_EventEnc_Str_OFF
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
	pushw EasyCmp_GridCheck_EventCase2_Str_Fmt3d@hi16
	pushw EasyCmp_GridCheck_EventCase2_Str_Fmt3d@lo16
	push xde
	call Sprintf_Locked
	lda xsp, (xsp + 10)

; EasyCmpGridCheck event case 3
EasyCmp_GridCheck_EventCase3:
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 20)
	ld xbc, EVT_GRID_DRAW
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
	ld xiy, MspNameBnkFunc_Data
	lda xix, (xsp + 4)
	ldw bc, 0x8
	ldirw
	ld xwa, xhl
	cp xhl, EVT_RAM_DATA_REQ
	jr z, MspNameBnk_Dispatch
	sub xwa, EVT_GET_LARGE_STEP
	cp xwa, 0x0
	jrl lt, MspNaming_CleanupExit
	cp xwa, 0x9
	jr gt, MspNaming_CleanupExit
	add xwa, xwa
	add xwa, MspNameBnkFunc_CaseTable
	ld wa, (xwa)
	lda xix, (EasyCmp_GridEvtCase_Default:24)
	jp	t, (xix+wa)

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
	jr	MspNameBnkFunc_Epilogue
MspNameBnkFunc_OnGetLargeStep:	; cases 31457342, 31457343, 31457350
	ld	xhl, 1:i3
	jr	MspNameBnkFunc_Epilogue
MspNameBnkFunc_OnGetMax:
	ld	xhl, 3:i3
	jr	MspNameBnkFunc_Epilogue
MspNameBnkFunc_OnGetRamAddress:
	lda	xhl, (0x7f3e:16)
	jr	t, MspNameBnkFunc_Epilogue

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
MspNameBnkFunc_Epilogue:
	pop xiz
	lda xsp, (xsp + 16)
	ret

MspNamingCheck:
	push xiz
	ld xiz, xwa
	cp xbc, EVT_GET_STRING_LENGTH
	jr z, MspNamingCheck_ReturnHex10
	cp xbc, EVT_GET_NAMING_MODE
	jr z, MspNamingCheck_ReturnZero
	cp xbc, EVT_GET_STRING
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
	cp xbc, EVT_SW_IN
	jr nz, MspNameOkFunc_ReturnZero
	call GetNamingWindowID
	ld xwa, xhl
	ld xbc, EVT_GET_STRING
	ld xde, 0x20c82
	call SendEvent
	ld xwa, NAKA_MAINFUNC_MiddleNameFunc
	ld xbc, EVT_MSP_NAME_SET
	ld xde, 0x20c82
	call MainFuncCall

MspNameOkFunc_ReturnZero:
	ld xhl, 0:i3
	ret
MspNameOkFunc_End:

PsMspNameBnkProc:
	lda xsp, (xsp-256)
	push xiz
	ld xiz, xwa
	cp xbc, EVT_REPAINT
	jr z, PsMspNameBnkProc_OnPaintOrRepaint
	cp xbc, EVT_PAINT
	jr z, PsMspNameBnkProc_OnPaintOrRepaint
	cp xbc, EVT_HIDE
	jr z, PsMspNameBnkProc_OnHide
	cp xbc, EVT_SHOW
	jr z, PsMspNameBnkProc_OnShow
	ld xwa, xiz
	call InheritedProc
	jr PsMspNameBnk_Epilogue

PsMspNameBnkProc_OnShow:
	ld xwa, xiz
	jr PsMspNameBnk_CallInherited

PsMspNameBnkProc_OnHide:
	ld xwa, xiz

PsMspNameBnk_CallInherited:
	call InheritedProc
	jr PsMspNameBnk_SetReturnZero

PsMspNameBnkProc_OnPaintOrRepaint:
	ld xwa, xiz
	call InheritedProc
	ld a, (0x7f3e:16)
	extz wa
	sla wa, 2
	lda xbc, (PtrTbl_MspCompileBankLabels:24)
	ld	xwa, (xbc+wa)
	push xwa
	lda xwa, (xsp + 8)
	push xwa
	call Sprintf_Locked
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	call SendEvent

PsMspNameBnk_SetReturnZero:
	ld xhl, 0:i3

PsMspNameBnk_Epilogue:
	pop xiz
	lda xsp, (xsp+256)
	ret
PsMspNameBnk_End:

VwVariBoxProc:
	lda xsp, (xsp-280)
	push xiz
	ld	(xsp+276), xde
	ld xiz, xbc
	ld	(xsp+280), xwa
	cp xiz, EVT_CHECK_SELECTED
	jrl z, VwVariBox_CanScroll
	cp xiz, EVT_INDEX_SELECT
	jrl z, VwVariBox_Release
	cp xiz, EVT_SW_IN
	jrl z, VwVariBox_OK
	cp xiz, EVT_GET_STRING
	jrl z, VwVariBox_GetText
	cp xiz, EVT_PARA_DRAW
	jrl z, VwVariBox_Confirm
	cp xiz, EVT_DRAW
	jrl z, VwVariBox_Paint
	cp xiz, EVT_LSW_DATA
	jrl z, VwVariBox_Match
	cp xiz, EVT_SHOW
	jr z, VwVariBox_Init
	cp xiz, EVT_SET_SELECTED
	jrl nz, VwVariBox_Default
	ld XWA, (xsp + 0x0118)
	call GetViewInstance
	lda xwa, (xhl + 38)
	ld xbc, (xwa)
	ld bc, (xbc)
	exts xbc
	cp	xbc, (xsp+276)
	jrl z, VwVariBox_ReturnHandled
	ld xbc, (xwa)
	ld XWA, (xsp + 0x0114)
	ld (xbc), wa
	ld XWA, (xsp + 0x0118)
	ld xbc, EVT_DRAW
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
	ld xbc, EVT_DRAW
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
	ld xbc, EVT_GET_PAGE_NOW
	ld xde, 0:i3
	call SendEvent
	cp xhl, 0x1
	jr z, VwVariBox_Match_Repaint
	ld xwa, 0xc80001
	ld xbc, EVT_SET_PAGE
	ld xde, 1:i3
	call SendEvent
	ld xwa, 0xc80001
	ld xbc, EVT_PARA_DRAW
	ld xde, 1:i3
	jr VwVariBox_Match_DispatchConfirm

VwVariBox_Match_HighIndex:
	ld xwa, 0xc80001
	ld xbc, EVT_GET_PAGE_NOW
	ld xde, 0:i3
	call SendEvent
	cp xhl, 0x2
	jr z, VwVariBox_Match_Repaint
	ld xwa, 0xc80001
	ld xbc, EVT_SET_PAGE
	ld xde, 2:i3
	call SendEvent
	ld xwa, 0xc80001
	ld xbc, EVT_PARA_DRAW
	ld xde, 2:i3

VwVariBox_Match_DispatchConfirm:
	call ApDeliveryEvent

VwVariBox_Match_Repaint:
	ld XWA, (xsp + 0x0118)
	ld xbc, EVT_DRAW
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
	lda xbc, (xsp+264)
	ld XWA, (xsp + 0x0118)
	call GetBox
	lda xwa, (xsp+264)
	ldw bc, 0xf5
	call DrawBox

VwVariBox_Paint_DrawLabel:
	ld xwa, (xsp + 4)
	ld wa, (xwa + 36)
	call DrawEditSw
	ld XWA, (xsp + 0x0118)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl VwVariBox_DispatchAndReturn

VwVariBox_Confirm:
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
	ld xwa, xde
	lda xbc, (xde + 17)

VwVariBox_Confirm_ClearBuf:
	ld (xwa+), 0x00
	cp xwa, xbc
	jr c, VwVariBox_Confirm_ClearBuf
	ld XWA, (xsp + 0x0118)
	ld xbc, EVT_GET_STRING
	call SendEvent
	ld xwa, (xsp + 4)
	ld xiz, (xwa + 38)
	lda xbc, (xsp+272)
	lda xde, (xsp+264)
	lda xiy, (xwa + 28)
	ld a, (xwa + 34)
	ldfr_berp A, 0xf0
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
	ld	xwa, (xbc+wa)
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
	cp	xwa, (xsp+276)
	jr nz, VwVariBox_OK_Forward
	ld de, (xhl + 26)
	cp de, 0xffff
	jr z, VwVariBox_OK_Forward
	exts xde
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEX_SELECT
	call SendEvent
	ld XWA, (xsp + 0x0118)
	ld xbc, EVT_SET_SELECTED
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
	cp	xwa, (xsp+276)
	jrl nz, VwVariBox_ReturnHandled
	ld xwa, (xhl + 38)
	cpw (xwa), 0x0
	jrl z, VwVariBox_ReturnHandled
	ld XWA, (xsp + 0x0118)
	ld xbc, EVT_SET_SELECTED
	ld xde, 0:i3

VwVariBox_DispatchAndReturn:
	call SendEvent
	jrl VwVariBox_ReturnHandled

VwVariBox_CanScroll:
	ld XWA, (xsp + 0x0118)
	call GetViewInstance
	ld wa, (xhl + 26)
	exts xwa
	cp	xwa, (xsp+276)
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
	lda xsp, (xsp+280)
	ret

MspBnkShow:
	push xiz
	cp xbc, EVT_REPAINT
	jrl z, MspBnk_ReturnZero
	cp xbc, EVT_PAINT
	jr z, MspBnk_ReturnZero
	cp xbc, EVT_HIDE
	jr z, MspBnk_ReturnZero
	cp xbc, EVT_SHOW
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
	ld xbc, EVT_GET_PAGE_NOW
	ld xde, 0:i3
	call SendEvent
	cp xhl, 0x1
	jr z, MspBnk_ReturnZero
	ld xwa, 0xc80001
	ld xbc, EVT_SET_PAGE
	ld xde, 1:i3
	jr MspBnk_SendEvt7F

MspBnk_SendEvt56_Case2:
	ld xwa, 0xc80001
	ld xbc, EVT_GET_PAGE_NOW
	ld xde, 0:i3
	call SendEvent
	cp xhl, 0x2
	jr z, MspBnk_ReturnZero
	ld xwa, 0xc80001
	ld xbc, EVT_SET_PAGE
	ld xde, 2:i3

MspBnk_SendEvt7F:
	call SendEvent

MspBnk_ReturnZero:
	ld xhl, 0:i3
	pop xiz
	ret

AcMspBnkSlBoxProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld xiz, xbc
	ld (xsp + 12), xwa
	cp xiz, EVT_SW_IN
	jrl z, MspBnkSlBox_HandleEvt7
	cp xiz, EVT_SET_SELECTED
	jrl z, MspBnkSlBox_ReturnZeroJmp
	cp xiz, EVT_LSW_DATA
	jrl z, MspBnkSlBox_HandleEvt1C
	cp xiz, EVT_REPAINT
	jr z, MspBnkSlBox_HandleEvtBC
	cp xiz, EVT_PAINT
	jr z, MspBnkSlBox_HandleEvtBC
	cp xiz, EVT_HIDE
	jr z, MspBnkSlBox_HandleEvt2
	cp xiz, EVT_SHOW
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
	ldfr_berp A, 0xf0
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
	ld xbc, EVT_SELE_DRAW
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
	lda xsp, (xsp-260)
	push xiz
	ld	(xsp+260), xde
	ld xiz, xwa
	cp xbc, EVT_MSP_RGP2_NM_DISP
	jrl z, RgpSetBnk_GridCheck
	cp xbc, EVT_MSP_RGP1_NM_DISP
	jrl z, PsMspBnkNameBoxProc_OnMspRgp1NmDisp
	cp xbc, EVT_MSP_USR2_NM_DISP
	jrl z, PsMspBnkNameBoxProc_OnMspUsr2NmDisp
	cp xbc, EVT_MSP_USR1_NM_DISP
	jrl z, PsMspBnkNameBoxProc_OnMspUsr1NmDisp
	cp xbc, EVT_DRAW
	jr z, PsMspBnkNameBoxProc_OnDraw
	cp xbc, EVT_HIDE
	jr z, PsMspBnkNameBoxProc_OnHide
	cp xbc, EVT_SHOW
	jrl nz, RgpSetBnk_GridCheck_Case2
	ld xwa, xiz
	ld XDE, (xsp + 0x0104)
	jr MspBnkNameBox_CallInherited

PsMspBnkNameBoxProc_OnHide:
	ld xwa, xiz
	ld XDE, (xsp + 0x0104)

MspBnkNameBox_CallInherited:
	call InheritedProc
	jrl RgpSetBnk_GridCheck_Case1

PsMspBnkNameBoxProc_OnDraw:
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
	ld xwa, NAKA_MAINFUNC_MainMspBnkNameFunc
	ld xbc, EVT_MSP_USR1_NM_GET
	ld xde, 0:i3
	jr MspBnk_MainFuncDispatch

MspBnkNameBox_EvtD_Case1:
	ld xwa, NAKA_MAINFUNC_MainMspBnkNameFunc
	ld xbc, EVT_MSP_USR2_NM_GET
	ld xde, 0:i3
	jr MspBnk_MainFuncDispatch

MspBnkNameBox_EvtD_Case2:
	ld xwa, NAKA_MAINFUNC_MainMspBnkNameFunc
	ld xbc, EVT_MSP_RGP1_NM_GET
	ld xde, 0:i3
	jr MspBnk_MainFuncDispatch

MspBnkNameBox_EvtD_Case3:
	ld xwa, NAKA_MAINFUNC_MainMspBnkNameFunc
	ld xbc, EVT_MSP_RGP2_NM_GET
	ld xde, 0:i3

MspBnk_MainFuncDispatch:
	call MainFuncCall
	jrl RgpSetBnk_GridCheck_Case1

PsMspBnkNameBoxProc_OnMspUsr1NmDisp:
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
	ld xbc, EVT_PARA_DRAW
	jr MspBnk_SendEventJoin

PsMspBnkNameBoxProc_OnMspUsr2NmDisp:
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
	ld xbc, EVT_PARA_DRAW
	jr MspBnk_SendEventJoin

PsMspBnkNameBoxProc_OnMspRgp1NmDisp:
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
	ld xbc, EVT_PARA_DRAW
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
	ld xbc, EVT_PARA_DRAW

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
	lda xsp, (xsp+260)
	ret

MspRGrpSetGridCheck:
	lda xsp, (xsp - 28)
	ld xwa, xbc
	cp xbc, EVT_REQUEST_GRID_DRAW
	jrl z, RgpSetBnk_GridCheck_EventEnc
	sub xwa, EVT_INDEXSW_UP
	cp xwa, 0x0
	jrl lt, RgpSetBnk_GridCheck_Return
	cp xwa, 0x6
	jrl gt, RgpSetBnk_GridCheck_Return
	add xwa, xwa
	add xwa, MspRGrpSetGridCheck_CaseTable
	ld wa, (xwa)
	lda xix, (MspRGrpSetGridCheck_DataBlock:24)
	jp	t, (xix+wa)

MspRGrpSetGridCheck_DataBlock:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	ld	xde, xhl
	lda	xwa, (xsp+20)
	ld	xbc, xde
	srl	xbc, 16
	ld	qbc, 0
	ld	(xwa), bc
	ld	(xwa+2), de
	ld	wa, (xwa)
	exts	xde
	cp	wa, 2:i3
	jr	z, MspRGrpSetGridCheck_Skip
	cp	wa, 1:i3
	jrl	nz, RgpSetBnk_GridCheck_Return
	ld	xwa, NAKA_MAINFUNC_MainMspRgpSetFunc
	ld	xbc, EVT_RGP_BNK_UP
	jr	MspRGrpSetGridCheck_Join
MspRGrpSetGridCheck_Skip:
	ld	xwa, NAKA_MAINFUNC_MainMspRgpSetFunc
	ld	xbc, EVT_RGP_PAD_UP
	jr	MspRGrpSetGridCheck_Join
MspRGrpSetGridCheck_OnIndexswDown:	; cases 29360152, 29360154
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	ld	xde, xhl
	lda	xwa, (xsp+20)
	ld	xbc, xde
	srl	xbc, 16
	ld	qbc, 0
	ld	(xwa), bc
	ld	(xwa+2), de
	ld	wa, (xwa)
	exts	xde
	cp	wa, 2:i3
	jr	z, MspRGrpSetGridCheck_Skip2
	cp	wa, 1:i3
	jrl	nz, RgpSetBnk_GridCheck_Return
	ld	xwa, NAKA_MAINFUNC_MainMspRgpSetFunc
	ld	xbc, EVT_RGP_BNK_DN
	jr	MspRGrpSetGridCheck_Join
MspRGrpSetGridCheck_Skip2:
	ld	xwa, NAKA_MAINFUNC_MainMspRgpSetFunc
	ld	xbc, EVT_RGP_PAD_DN
MspRGrpSetGridCheck_Join:
	call	MainFuncCall
	jrl	RgpSetBnk_GridCheck_Return

; RgpSetBnkCheck event encoding dispatch
RgpSetBnk_GridCheck_EventEnc:
	lda xhl, (xsp + 20)
	ld xwa, xde
	srl xwa, 16
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
	ld	xwa, (xbc+wa)
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
	pushw RgpSetBnk_EvtEnc_SendAudioCmd_Str_PAD_Fmtd@hi16
	pushw RgpSetBnk_EvtEnc_SendAudioCmd_Str_PAD_Fmtd@lo16
	push xde
	call Sprintf_Locked
	lda xsp, (xsp + 10)

AudioEvt_GetFocusRetZero:
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 20)
	ld xbc, EVT_GRID_DRAW
	call SendEvent

; RgpSetBnkCheck return
RgpSetBnk_GridCheck_Return:
	ld xhl, 0:i3
	lda xsp, (xsp + 28)
	ret

PsRgpSetBnkBoxProc:
	lda xsp, (xsp-256)
	push xiz
	ld xiz, xwa
	cp xbc, EVT_REPAINT
	jr z, PsRgpSetBnkBoxProc_OnPaintOrRepaint
	cp xbc, EVT_PAINT
	jr z, PsRgpSetBnkBoxProc_OnPaintOrRepaint
	cp xbc, EVT_HIDE
	jr z, PsRgpSetBnkBoxProc_OnHide
	cp xbc, EVT_SHOW
	jr z, PsRgpSetBnkBoxProc_OnShow
	ld xwa, xiz
	call InheritedProc
	jr RgpSetBnkBox_Epilogue

PsRgpSetBnkBoxProc_OnShow:
	ld xwa, xiz
	jr RgpSetBnkBox_CallInherited

PsRgpSetBnkBoxProc_OnHide:
	ld xwa, xiz

RgpSetBnkBox_CallInherited:
	call InheritedProc
	jr RgpSetBnkBox_SetReturnZero

PsRgpSetBnkBoxProc_OnPaintOrRepaint:
	ld xwa, xiz
	call InheritedProc
	ld a, (0x7f3d:16)
	extz wa
	sla wa, 2
	lda xbc, (RgpSetBnkBox_HandleEvtBC_Data:24)
	ld	xwa, (xbc+wa)
	push xwa
	lda xwa, (xsp + 8)
	push xwa
	call Sprintf_Locked
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	call SendEvent

RgpSetBnkBox_SetReturnZero:
	ld xhl, 0:i3

RgpSetBnkBox_Epilogue:
	pop xiz
	lda xsp, (xsp+256)
	ret

MspRGrpSetBnkFunc:
	pushw_erp 0xfa
	cp xbc, EVT_SW_IN
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
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call SendEvent
	ldib_erp 0xfa, 2

MspRGrpSetBnk_OuterLoop:
	ldib_erp 0xfb, 1

MspRGrpSetBnk_InnerLoop:
	ldto_berp A, 0xfa
	extz wa
	ld bc, wa
	extz xbc
	ldto_berp A, 0xfb
	extz wa
	extz xwa
	sll xwa, 16
	ld xde, xwa
	add xde, xbc
	ld xwa, 0xcc0003
	ld xbc, EVT_REQUEST_GRID_DRAW
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
	cp xbc, EVT_REPAINT
	jr z, MspRgpShow_ReturnZero
	cp xbc, EVT_PAINT
	jr z, MspRgpShow_ReturnZero
	cp xbc, EVT_HIDE
	jr z, MspRgpShow_ReturnZero
	cp xbc, EVT_SHOW
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
	lda xsp, (xsp-256)
	push xiz
	ld xiz, xwa
	cp xbc, EVT_REPAINT
	jr z, PsMspMeasBoxProc_OnPaintOrRepaint
	cp xbc, EVT_PAINT
	jr z, PsMspMeasBoxProc_OnPaintOrRepaint
	cp xbc, EVT_HIDE
	jr z, PsMspMeasBoxProc_OnHide
	cp xbc, EVT_SHOW
	jr z, PsMspMeasBoxProc_OnShow
	ld xwa, xiz
	call InheritedProc
	jr MspMeasBox_Epilogue

PsMspMeasBoxProc_OnShow:
	ld xwa, xiz
	jr MspMeasBox_CallInherited

PsMspMeasBoxProc_OnHide:
	ld xwa, xiz

MspMeasBox_CallInherited:
	call InheritedProc
	jr MspMeasBox_SetReturnZero

PsMspMeasBoxProc_OnPaintOrRepaint:
	ld xwa, xiz
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld wa, (0x7f0e:16)
	pushw wa
	pushw MspMeasBox_HandleEvtBC_Str_MEASURE_Fmtd@hi16
	pushw MspMeasBox_HandleEvtBC_Str_MEASURE_Fmtd@lo16
	lda xwa, (xsp + 10)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	call SendEvent

MspMeasBox_SetReturnZero:
	ld xhl, 0:i3

MspMeasBox_Epilogue:
	pop xiz
	lda xsp, (xsp+256)
	ret
MspMeasBox_End:

PsMspMemBoxProc:
	lda xsp, (xsp-256)
	push xiz
	ld xiz, xwa
	cp xbc, EVT_REPAINT
	jr z, PsMspMemBoxProc_OnPaintOrRepaint
	cp xbc, EVT_PAINT
	jr z, PsMspMemBoxProc_OnPaintOrRepaint
	cp xbc, EVT_HIDE
	jr z, PsMspMemBoxProc_OnHide
	cp xbc, EVT_SHOW
	jr z, PsMspMemBoxProc_OnShow
	ld xwa, xiz
	call InheritedProc
	jr MspMemBox_Epilogue

PsMspMemBoxProc_OnShow:
	ld xwa, xiz
	jr MspMemBox_CallInherited

PsMspMemBoxProc_OnHide:
	ld xwa, xiz

MspMemBox_CallInherited:
	call InheritedProc
	jr MspMemBox_SetReturnZero

PsMspMemBoxProc_OnPaintOrRepaint:
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
	pushw MspMemBox_ClampValue_Str_MEMORY_Fmt2d@hi16
	pushw MspMemBox_ClampValue_Str_MEMORY_Fmt2d@lo16
	lda xwa, (xsp + 10)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	call SendEvent

MspMemBox_SetReturnZero:
	ld xhl, 0:i3

MspMemBox_Epilogue:
	pop xiz
	lda xsp, (xsp+256)
	ret
MspMemBox_End:

PsMspRecBnkBoxProc:
	lda xsp, (xsp-256)
	push xiz
	ld xiz, xwa
	cp xbc, EVT_REPAINT
	jr z, PsMspRecBnkBoxProc_OnPaintOrRepaint
	cp xbc, EVT_PAINT
	jr z, PsMspRecBnkBoxProc_OnPaintOrRepaint
	cp xbc, EVT_HIDE
	jr z, PsMspRecBnkBoxProc_OnHide
	cp xbc, EVT_SHOW
	jr z, PsMspRecBnkBoxProc_OnShow
	ld xwa, xiz
	call InheritedProc
	jr MspRecBnkBox_Epilogue

PsMspRecBnkBoxProc_OnShow:
	ld xwa, xiz
	jr MspRecBnkBox_CallInherited

PsMspRecBnkBoxProc_OnHide:
	ld xwa, xiz

MspRecBnkBox_CallInherited:
	call InheritedProc
	jr MspRecBnkBox_SetReturnZero

PsMspRecBnkBoxProc_OnPaintOrRepaint:
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
	ld xbc, EVT_PARA_DRAW
	call SendEvent

MspRecBnkBox_SetReturnZero:
	ld xhl, 0:i3

MspRecBnkBox_Epilogue:
	pop xiz
	lda xsp, (xsp+256)
	ret
MspRecBnkBox_End:

PsMspRecPadBoxProc:
	lda xsp, (xsp-256)
	push xiz
	ld xiz, xwa
	cp xbc, EVT_REPAINT
	jr z, PsMspRecPadBoxProc_OnPaintOrRepaint
	cp xbc, EVT_PAINT
	jr z, PsMspRecPadBoxProc_OnPaintOrRepaint
	cp xbc, EVT_HIDE
	jr z, PsMspRecPadBoxProc_OnHide
	cp xbc, EVT_SHOW
	jr z, PsMspRecPadBoxProc_OnShow
	ld xwa, xiz
	call InheritedProc
	jr AcSndArgGrid_BnkCase2

PsMspRecPadBoxProc_OnShow:
	ld xwa, xiz
	jr MspRecPadBox_CallInherited

PsMspRecPadBoxProc_OnHide:
	ld xwa, xiz

MspRecPadBox_CallInherited:
	call InheritedProc
	jr AcSndArgGrid_BnkCase1

PsMspRecPadBoxProc_OnPaintOrRepaint:
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
	pushw AcSndArgGrid_BnkDispatch_Str_Fmtd@hi16
	pushw AcSndArgGrid_BnkDispatch_Str_Fmtd@lo16
	lda xwa, (xsp + 10)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	call SendEvent

; AcSndArgGridBnk case 1
AcSndArgGrid_BnkCase1:
	ld xhl, 0:i3

; AcSndArgGridBnk case 2
AcSndArgGrid_BnkCase2:
	pop xiz
	lda xsp, (xsp+256)
	ret

MspPlayModeFunc:
	lda xsp, (xsp - 12)
	push xiz
	ld xiz, xde
	ld xde, xbc
	ld (xsp + 12), xwa
	ld xiy, MspPlayModeFunc_Data
	lda xix, (xsp + 4)
	ld bc, 4:i3
	ldirw
	ld xwa, xde
	cp xde, EVT_RAM_DATA_REQ
	jr z, AcSndArgGrid_BoxProc
	sub xwa, EVT_GET_LARGE_STEP
	cp xwa, 0x0
	jr lt, AcSndArgGrid_BoxCase1
	cp xwa, 0x9
	jr gt, AcSndArgGrid_BoxCase1
	add xwa, xwa
	add xwa, MspPlayModeFunc_CaseTable
	ld wa, (xwa)
	lda xix, (MspPlayModeFunc_DataBlock:24)
	jp	t, (xix+wa)

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
	jr	MspPlayModeFunc_Epilogue
MspPlayModeFunc_OnGetLargeStep:	; cases 31457342, 31457343
	ld	a, (1054:16)
	and	a, 4
	cp	a, 4:i3
	scc16	nz, hl
	extz	xhl
	jr	MspPlayModeFunc_Epilogue
MspPlayModeFunc_OnGetMax:	; cases 31457347, 31457350
	ld	xhl, 1:i3
	jr	MspPlayModeFunc_Epilogue
MspPlayModeFunc_OnGetRamAddress:
	lda	xhl, (0x7f3f:16)
	jr	MspPlayModeFunc_Epilogue

; AcSndArgGridBoxProc dispatch (7-entry, table 0xe1e35e)
AcSndArgGrid_BoxProc:
	ld xwa, NAKA_MAINFUNC_MspRecTtlFunc
	ld xbc, EVT_MSP_PLY_MD_SET
	ld xde, xiz
	call MainFuncCall

; AcSndArgGridBox case 1
AcSndArgGrid_BoxCase1:
	ld xhl, 0:i3
MspPlayModeFunc_Epilogue:
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
	ld xiy, AcSndArgGridBoxProc_Data
	lda xix, (xsp + 12)
	ld bc, 2:i3
	ldirw
	ldi85
	ld xwa, xiz
	cp xiz, EVT_GRID_DRAW
	jrl z, AcSndArgGrid_PlayAudio
	cp xiz, EVT_ARG_CHO_DISP
	jrl z, AcSndArgGrid_ForwardToParent
	cp xiz, EVT_ARG_TONE_NM_DISP
	jrl z, AcSndArgGrid_ForwardToParent
	cp xiz, EVT_REQUEST_GRID_DRAW
	jrl z, AcSndArgGrid_ForwardToParent
	cp xiz, EVT_GET_FIXED_ROW_STR
	jrl z, AcSndArgGrid_GetRowText
	cp xiz, EVT_GET_FIXED_COL_STR
	jrl z, AcSndArgGrid_GetColText
	cp xiz, EVT_SHOW
	jr z, AcSndArgGrid_Init
	sub xwa, EVT_INDEXSW_UP
	cp xwa, 0x0
	jrl lt, AcSndArgGrid_ForwardToBase
	cp xwa, 0x6
	jrl gt, AcSndArgGrid_ForwardToBase
	add xwa, xwa
	add xwa, AcSndArgGridBoxProc_CaseTable
	ld wa, (xwa)
	lda xix, (AcSndArgGrid_Init:24)
	jp	t, (xix+wa)

AcSndArgGrid_Init:
	ld xwa, (xsp + 22)
	ld xbc, xiz
	ld xde, (xsp + 18)
	call InheritedProc
	ld xwa, (xsp + 22)
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, (xsp + 22)
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
	ld xwa, (xsp + 22)
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
	ld xwa, (xsp + 22)
	ld xbc, EVT_INDEXSW_DOWN
	call SetDialDown
	ld wa, 1:i3
	jrl AcSndArgGrid_ScrollCommit
AcSndArgGridBoxProc_OnIndexswUp:	; cases 29360151, 29360153
	ld xwa, (xsp + 22)
	ld xbc, xiz
	ld xde, (xsp + 18)
	call InheritedProc
	ld xwa, (xsp + 22)
	ld xbc, EVT_CHECK_INDEX
	ld xde, (xsp + 18)
	call SendEvent
	or xhl, xhl
	jr z, AcSndArgGrid_ScrollUp_NoCanScroll
	ld xwa, (xsp + 22)
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	dec 1, hl
	extz xhl
	add xhl, 0xffff0000
	ld xwa, (xsp + 22)
	ld xbc, EVT_SELE_DRAW
	ld xde, xhl
	call SendEvent
	ld xwa, (xsp + 22)
	ld xbc, EVT_INDEXSW_UP_AIC
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
	ld	(0x338e:16), (xbc+wa)
	ld d, 0x0:opc
	extz xde
	ld xwa, NAKA_MAINFUNC_SndArgNmGet
	ld xbc, EVT_SET_PT_SEL
	call MainFuncCall
	jrl AcSndArgGrid_ReturnHandled

AcSndArgGrid_ScrollUp_NoCanScroll:
	ld xwa, (xsp + 22)
	ld xbc, EVT_CHECK_GRID_INDEX
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
	ld xbc, EVT_INDEXSW_UP_AIC
	ld xde, (xsp + 18)
	call SetAutoInc
	ld xwa, (xsp + 22)
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 18)
	call SetDialUp
	ld xwa, (xsp + 22)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 18)
	call SetDialDown
	ld wa, 1:i3
	jrl AcSndArgGrid_ScrollCommit
AcSndArgGridBoxProc_OnIndexswDown:	; cases 29360152, 29360154
	ld xwa, (xsp + 22)
	ld xbc, xiz
	ld xde, (xsp + 18)
	call InheritedProc
	ld xwa, (xsp + 22)
	ld xbc, EVT_CHECK_INDEX
	ld xde, (xsp + 18)
	call SendEvent
	or xhl, xhl
	jr z, AcSndArgGrid_ScrollDown_NoCanScroll
	ld xwa, (xsp + 22)
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	inc 1, hl
	extz xhl
	add xhl, 0xffff0000
	ld xwa, (xsp + 22)
	ld xbc, EVT_SELE_DRAW
	ld xde, xhl
	call SendEvent
	ld xwa, (xsp + 22)
	ld xbc, EVT_INDEXSW_DOWN_AIC
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
	ld	(0x338e:16), (xbc+wa)
	ld d, 0x0:opc
	extz xde
	ld xwa, NAKA_MAINFUNC_SndArgNmGet
	ld xbc, EVT_SET_PT_SEL
	call MainFuncCall
	jrl AcSndArgGrid_ReturnHandled

AcSndArgGrid_ScrollDown_NoCanScroll:
	ld xwa, (xsp + 22)
	ld xbc, EVT_CHECK_GRID_INDEX
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
	ld xbc, EVT_INDEXSW_DOWN_AIC
	ld xde, (xsp + 18)
	call SetAutoInc
	ld xwa, (xsp + 22)
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 18)
	call SetDialUp
	ld xwa, (xsp + 22)
	ld xbc, EVT_INDEXSW_DOWN
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
AcSndArgGridBoxProc_OnLswData:
	ld xwa, (xsp + 22)
	ld xbc, xiz
	ld xde, (xsp + 18)
	call InheritedProc
	call GetTitleNow
	cp xhl, TITLE_SNDARG
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
	ld xbc, EVT_REQUEST_GRID_DRAW
	ld xde, 0x10002
	jr AcSndArgGrid_CellSel_Dispatch

AcSndArgGrid_CellSel_CC00:
	ld xwa, (xsp + 22)
	ld xbc, EVT_REQUEST_GRID_DRAW
	ld xde, 0x10003
	jr AcSndArgGrid_CellSel_Dispatch

AcSndArgGrid_CellSel_CC5E:
	ld xwa, (xsp + 22)
	ld xbc, EVT_REQUEST_GRID_DRAW
	ld xde, 0x20003
	jr AcSndArgGrid_CellSel_Dispatch

AcSndArgGrid_CellSel_C000:
	ld xwa, (xsp + 22)
	ld xbc, EVT_REQUEST_GRID_DRAW
	ld xde, 0x10004
	jr AcSndArgGrid_CellSel_Dispatch

AcSndArgGrid_CellSel_C05E:
	ld xwa, (xsp + 22)
	ld xbc, EVT_REQUEST_GRID_DRAW
	ld xde, 0x20004
	jr AcSndArgGrid_CellSel_Dispatch

AcSndArgGrid_CellSel_C400:
	ld xwa, (xsp + 22)
	ld xbc, EVT_REQUEST_GRID_DRAW
	ld xde, 0x10005
	jr AcSndArgGrid_CellSel_Dispatch

AcSndArgGrid_CellSel_C45E:
	ld xwa, (xsp + 22)
	ld xbc, EVT_REQUEST_GRID_DRAW
	ld xde, 0x20005
	jr AcSndArgGrid_CellSel_Dispatch

AcSndArgGrid_CellSel_C800:
	ld xwa, (xsp + 22)
	ld xbc, EVT_REQUEST_GRID_DRAW
	ld xde, 0x10006
	jr AcSndArgGrid_CellSel_Dispatch

AcSndArgGrid_CellSel_C85E:
	ld xwa, (xsp + 22)
	ld xbc, EVT_REQUEST_GRID_DRAW
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
	cp xhl, TITLE_MESAGE
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
	srl xde, 16
	ldfr_werp WA, 0xe2
	ldiw_erp 0xea, 0
	ld wa, de
	lda xix, (xsp + 24)
	lda xiz, (xsp + 4)
	lda xde, (xix + 2)
	lda xhl, (xix + 4)
	cp xbc, EVT_ARG_CHO_DISP
	jrl z, SndArgGridCheck_PlayRowAudio
	cp xbc, EVT_ARG_TONE_NM_DISP
	jr z, SndArgGridCheck_PlayColAudio
	cp xbc, EVT_REQUEST_GRID_DRAW
	jr z, SndArgGridCheck_CellSelect
	ld xhl, 0:i3
	ld xwa, xiy
	sub xwa, EVT_INDEXSW_UP
	cp xwa, 0x0
	jrl lt, SndArgGridCheck_Return
	cp xwa, 0x6
	jrl gt, SndArgGridCheck_Return
	add xwa, xwa
	add xwa, SndArgGridCheck_CaseTable
	ld wa, (xwa)
	lda xix, (SndArgGridCheck_JumpTableFallthrough:24)
	jp	t, (xix+wa)

SndArgGridCheck_JumpTableFallthrough:
	jrl	t, SndArgGridCheck_Return

SndArgGridCheck_CellSelect:
	ld (xix), wa
	ldto_werp WA, 0xe2
	ld (xde), wa
	ld (xhl), xiz
	ld wa, (xix)
	ld de, (xde)
	exts xde
	cp wa, 2:i3
	jr z, SndArgGridCheck_CellSel_Row2
	cp wa, 1:i3
	jrl nz, SndArgGridCheck_ReturnHandled
	ld xwa, NAKA_MAINFUNC_SndArgNmGet
	ld xbc, EVT_ARG_TONE_NM_GET
	jr SndArgGridCheck_CellSel_SendEvent

SndArgGridCheck_CellSel_Row2:
	ld xwa, NAKA_MAINFUNC_SndArgNmGet
	ld xbc, EVT_ARG_CHO_GET

SndArgGridCheck_CellSel_SendEvent:
	call MainFuncCall
	jrl SndArgGridCheck_ReturnHandled

SndArgGridCheck_PlayColAudio:
	ld (xix), wa
	ldto_werp WA, 0xe2
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
	ld xbc, EVT_GRID_DRAW
	jr SndArgGridCheck_DispatchPlayAudio

SndArgGridCheck_PlayRowAudio:
	ld (xix), wa
	ldto_werp WA, 0xe2
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
	ld xbc, EVT_GRID_DRAW

SndArgGridCheck_DispatchPlayAudio:
	call SendEvent

SndArgGridCheck_ReturnHandled:
	ld xhl, 0:i3

SndArgGridCheck_Return:
	pop xiz
	lda xsp, (xsp + 28)
	ret

SndArgTtlCheck:
	cp xbc, EVT_SHOW
	jr nz, ParamList_ReturnZero
	call GetTitleOld
	cp xhl, TITLE_MESAGE
	jr nz, ParamList_ReturnZero
	cp (0x339f:16), 1
	jr nz, ParamList_ReturnZero
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 1:i3
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 0:i3
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_MODE
	ld xde, NAKA_MODE_MD_NORMAL
	call PostEvent

ParamList_ReturnZero:
	ld xhl, 0:i3
	ret

PsParaListBoxProc:
	lda xsp, (xsp-158)
	push xiz
	ld	(xsp+158), xde
	ld xiz, xwa
	cp xbc, EVT_SET_SELECTED_LINE
	jrl z, SndArgGrid_CheckCase2
	cp xbc, EVT_PARA_DRAW
	jrl z, PsParaListBoxProc_OnParaDraw
	cp xbc, EVT_PAINT
	jr z, PsParaListBoxProc_OnPaint
	ld xwa, xiz
	ld	xde, (xsp+158)
	call InheritedProc
	jrl SndArgGrid_CheckCase3

PsParaListBoxProc_OnPaint:
	ld xwa, xiz
	ld	xde, (xsp+158)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 10), xhl
	ld xwa, (xsp + 10)
	cpw (xwa + 34), 0x2
	jrl lt, PsParaListBoxProc_Return
	lda xbc, (xsp+142:16)
	ld xwa, xiz
	call GetClientBox
	lda xde, (xsp+142:16)
	ld bc, (xde + 4)
	sub bc, (xde)
	exts xbc
	ld xwa, (xsp + 10)
	mrdw3 0x98, 0x22, 0x59
	ld (xsp + 4), bc
	ld wa, (xde + 2)
	inc 1, wa
	ld	(xsp+156), wa
	ld wa, (xde + 6)
	dec 1, wa
	ld	(xsp+152), wa
	ld iz, 1:i3
	jr ParaListBox_DrawLineLoop_Check

ParaListBox_DrawLineLoop_Body:
	ld wa, (xsp + 4)
	mul xwa, iz
	ld	bc, (xsp+142)
	add bc, wa
	dec 1, bc
	lda xwa, (xsp+154:16)
	ld (xwa), bc
	lda xbc, (xsp+150:16)
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

PsParaListBoxProc_OnParaDraw:
	ld xwa, xiz
	ld	xde, (xsp+158)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 6), xhl
	ld	xde, (xsp+158)
	or xde, xde
	jrl z, PsParaListBoxProc_Return
	ld xwa, (xsp + 6)
	ld bc, (xwa + 34)
	mrdw3 0x98, 0x24, 0x49
	ld a, (xde)
	exts wa
	cp wa, bc
	jrl ge, PsParaListBoxProc_Return
	lda xbc, (xsp+142:16)
	ld xwa, xiz
	call GetClientBox
	lda xbc, (xsp+142:16)
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
	divs xiz, de
	ld	xwa, (xsp+158)
	ld a, (xwa)
	exts wa
	exts xwa
	divs xwa, de
	ldto_werp WA, 0xe2
	ldfr_werp WA, 0xea
	ld	xwa, (xsp+158)
	ld a, (xwa)
	exts wa
	exts xwa
	divs xwa, de
	ld de, wa
	ld wa, iz
	mul xwa, qde
	inc 2, wa
	add hl, wa
	ld (xix), hl
	add hl, iz
	ld (xiy), hl
	ld wa, (xsp + 4)
	mul xwa, de
	inc 2, wa
	add (xbc), wa
	ld de, (xbc)
	add de, (xsp + 4)
	ld xwa, (xsp + 10)
	ld (xwa), de
	lda xde, (xsp+154:16)
	ld wa, (xbc)
	ld (xde), wa
	ld wa, (xix)
	ld (xde + 2), wa
	ld	xwa, (xsp+158)
	inc 1, xwa
	push xwa
	lda xwa, (xsp + 18)
	push xwa
	call Strcpy
	inc 8, xsp
	ld xbc, (xsp + 6)
	ld xix, (xbc + 38)
	ld	xwa, (xsp+158)
	ld a, (xwa)
	ldfr_berp A, 0xf4
	exts iy
	lda xde, (xsp + 14)
	lda xhl, (xbc + 28)
	lda xbc, (xsp+154:16)
	lda xwa, (xsp+142:16)
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
	ld	xwa, (xsp+158)
	ld (xbc), wa

PsParaListBoxProc_Return:
	ld xhl, 0:i3

; SndArgGridCheck case 3
SndArgGrid_CheckCase3:
	pop xiz
	lda xsp, (xsp+158:16)
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
	sub xde, EVT_GET_LARGE_STEP
	cp xde, 0x0
	jr lt, PsSCTxtBox_EventDispatch
	cp xde, 0x9
	jr gt, PsSCTxtBox_EventDispatch
	add xde, xde
	add xde, MsgBox_AttentionHeader
	ld de, (xde)
	lda xix, (StylCnvStorBnkSel_DataBlock:24)
	jp	t, (xix+de)

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
	jr	StylCnvStorBnkSel_Epilogue
StylCnvStorBnkSel_OnGetLargeStep:	; cases 31457342, 31457343, 31457350
	ld	xhl, 1:i3
	jr	StylCnvStorBnkSel_Epilogue
StylCnvStorBnkSel_OnGetMax:
	ld	xhl, 22
	jr	StylCnvStorBnkSel_Epilogue
StylCnvStorBnkSel_OnGetRamAddress:
	lda_d16	xhl, (0x3a4d)
	jr	StylCnvStorBnkSel_Epilogue

; PsSCTxtBoxProc event dispatch (10-entry, table 0xe1e4bc)
PsSCTxtBox_EventDispatch:
	ld xhl, 0:i3
StylCnvStorBnkSel_Epilogue:
	pop xiz
	lda xsp, (xsp + 92)
	ret

PsSCTxtBoxProc:
	lda xsp, (xsp-512)
	push xiz
	ld xiz, xwa
	cp xbc, EVT_REPAINT
	jr z, PsSCTxtBoxProc_OnPaintOrRepaint
	cp xbc, EVT_PAINT
	jr z, PsSCTxtBoxProc_OnPaintOrRepaint
	cp xbc, EVT_HIDE
	jr z, PsSCTxtBoxProc_OnHide
	cp xbc, EVT_SHOW
	jr z, PsSCTxtBoxProc_OnShow
	ld xwa, xiz
	call InheritedProc
	jr SCTxtBox_Epilogue

PsSCTxtBoxProc_OnShow:
	ld xwa, xiz
	jr SCTxtBox_CallInherited

PsSCTxtBoxProc_OnHide:
	ld xwa, xiz

SCTxtBox_CallInherited:
	call InheritedProc
	jr SCTxtBox_SetReturnZero

PsSCTxtBoxProc_OnPaintOrRepaint:
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
	ld xbc, EVT_PARA_DRAW
	call SendEvent

SCTxtBox_SetReturnZero:
	ld xhl, 0:i3

SCTxtBox_Epilogue:
	pop xiz
	lda xsp, (xsp+512)
	ret

PsSCTxtBox2Proc:
	lda xsp, (xsp-512)
	push xiz
	ld xiz, xwa
	cp xbc, EVT_REPAINT
	jr z, PsSCTxtBox2Proc_OnPaintOrRepaint
	cp xbc, EVT_PAINT
	jr z, PsSCTxtBox2Proc_OnPaintOrRepaint
	cp xbc, EVT_GET_STR_PTR
	jr z, PsSCTxtBox2Proc_OnGetStrPtr
	cp xbc, EVT_HIDE
	jr z, PsSCTxtBox2Proc_OnHide
	cp xbc, EVT_SHOW
	jr z, PsSCTxtBox2Proc_OnShow
	ld xwa, xiz
	call InheritedProc
	jr SCTxtBox2_Epilogue

PsSCTxtBox2Proc_OnShow:
	ld xwa, xiz
	jr SCTxtBox2_CallInherited

PsSCTxtBox2Proc_OnHide:
	ld xwa, xiz

SCTxtBox2_CallInherited:
	call InheritedProc
	jr SCTxtBox2_SetReturnZero

PsSCTxtBox2Proc_OnGetStrPtr:
	lda xhl, (0x3d68:16)
	jr SCTxtBox2_Epilogue

PsSCTxtBox2Proc_OnPaintOrRepaint:
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
	ld xbc, EVT_PARA_DRAW
	call SendEvent

SCTxtBox2_SetReturnZero:
	ld xhl, 0:i3

SCTxtBox2_Epilogue:
	pop xiz
	lda xsp, (xsp+512)
	ret

StylCnvStorOkFunc:
	cp xbc, EVT_SW_IN
	jr nz, StylCnvStorOkFunc_ReturnZero
	ld xde, 0:i3
	ld e, (0x3a4d:16)
	ld xwa, NAKA_MAINFUNC_MainStylCnvFunc
	ld xbc, EVT_STYL_CNV_STOR
	call MainFuncCall

StylCnvStorOkFunc_ReturnZero:
	ld xhl, 0:i3
	ret

StylCnvStorOkFunc_DataBlock:
	dec	8, xsp
	ld	xhl, xbc
	cpw	(xsp+12), 0
	jr	z, StylCnvStorOkFunc_DataBlock_Skip
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
	jr	StylCnvStorOkFunc_DataBlock_Join
StylCnvStorOkFunc_DataBlock_Skip:
	ld	xbc, xhl
StylCnvStorOkFunc_DataBlock_Join:
	call	DrawLine
	inc	8, xsp
	retd	2
StylCnvStorBnk_ProcDataBlock_Helper:
	lda	xsp, (xsp-30)
	push	xiz
	ld	(xsp+32), bc
	ld	bc, (xsp+38)
	cp	bc, 3:i3
	jr	z, StylCnvStorOkFunc_DataBlock_Skip2
	cp	bc, 2:i3
	jr	z, StylCnvStorOkFunc_DataBlock_Entry
	cp	bc, 1:i3
	scc16	nz, bc
	ld	(xsp+8), bc
	ldw (xsp+10), 0
	ld	xiy, xwa
	lda	xix, (xsp+24)
	ld	bc, 4:i3
	ldirw
StylCnvStorOkFunc_DataBlock_Join2:
	lda	xhl, (xsp+24)
	ld	bc, (xhl+4)
	ld	wa, bc
	sub	wa, (xhl)
	mul	xwa, de
	ld	iz, wa
	extz	xiz
	div	iz, 100
	lda	xwa, (xhl+6)
	ld	(xsp+12), xwa
	lda	xde, (xhl+2)
	ld	xwa, (xsp+12)
	ld	wa, (xwa)
	sub	wa, (xde)
	mul	xwa, (xsp+40)
	ld	ix, wa
	extz	xix
	div	ix, 100
	ld	wa, bc
	.byte 0x93, 0xa0
	ld	(xsp+4), wa
	sub	(xsp+4), iz
	cpw	(xsp+8), 0
	jr	z, StylCnvStorOkFunc_DataBlock_Skip3
	ld	(xsp+20), bc
	ldw (xsp+6), 65535
	jr	StylCnvStorOkFunc_DataBlock_Join3
StylCnvStorOkFunc_DataBlock_Entry:
	ldw	(xsp+8), 1
	jr	StylCnvStorOkFunc_DataBlock_Entry2
StylCnvStorOkFunc_DataBlock_Skip2:
	ldw (xsp+8), 0
StylCnvStorOkFunc_DataBlock_Entry2:
	ldw	(xsp+10), 1
	lda	xhl, (xsp+24)
	ld	bc, (xwa+2)
	ld	(xhl), bc
	ld	bc, (xwa)
	ld	(xhl+2), bc
	ld	bc, (xwa+6)
	ld	(xhl+4), bc
	ld	wa, (xwa+4)
	ld	(xhl+6), wa
	jr	StylCnvStorOkFunc_DataBlock_Join2
StylCnvStorOkFunc_DataBlock_Skip3:
	ld	wa, (xhl)
	ld	(xsp+20), wa
	ldw	(xsp+6), 1
StylCnvStorOkFunc_DataBlock_Join3:
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
	jr	ule, StylCnvStorOkFunc_DataBlock_Skip5
StylCnvStorOkFunc_DataBlock_Loop:
	lda	xwa, (xsp+20)
	lda	xbc, (xsp+16)
	pushm	(xsp+10)
	ld	de, (xsp+34)
	calr	StylCnvStorOkFunc_DataBlock
	ld	wa, (xsp+6)
	add	(xsp+20), wa
	add	(xsp+16), wa
	incw	1, (xsp+14)
	cp	(xsp+14), iz
	jr	c, StylCnvStorOkFunc_DataBlock_Loop
StylCnvStorOkFunc_DataBlock_Skip5:
	lda	xwa, (xsp+24)
	lda	xbc, (xsp+20)
	cpw	(xsp+8), 0
	jr	z, StylCnvStorOkFunc_DataBlock_Skip6
	ld	wa, (xwa+4)
	sub	wa, iz
	ld	(xbc), wa
	ldw (xsp+6), 65535
	jr	StylCnvStorOkFunc_DataBlock_Join4
StylCnvStorOkFunc_DataBlock_Skip6:
	ld	wa, (xwa)
	add	wa, iz
	ld	(xbc), wa
	ldw	(xsp+6), 1
StylCnvStorOkFunc_DataBlock_Join4:
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
	cpw	(xsp+4), 0
	jr	ule, StylCnvStorOkFunc_DataBlock_Skip7
StylCnvStorOkFunc_DataBlock_Loop2:
	lda	xwa, (xsp+20)
	lda	xbc, (xsp+16)
	pushm	(xsp+10)
	ld	de, (xsp+34)
	calr	StylCnvStorOkFunc_DataBlock
	ld	wa, (xsp+6)
	add	(xsp+16), wa
	incw	1, (xsp+14)
	ld	wa, (xsp+14)
	.byte 0x9f, 0x04, 0xf0
	jr	c, StylCnvStorOkFunc_DataBlock_Loop2
StylCnvStorOkFunc_DataBlock_Skip7:
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
	sub	wa, (xde+2)
	exts	xwa
	divs	wa, 2
	sub	bc, wa
	ld	(xix+2), bc
	ldw	(xsp+14), 0
	cpw	(xsp+4), 0
	jr	ule, StylCnvStorOkFunc_DataBlock_Epilogue
StylCnvStorOkFunc_DataBlock_Loop3:
	lda	xwa, (xsp+20)
	lda	xbc, (xsp+16)
	pushm	(xsp+10)
	ld	de, (xsp+34)
	calr	StylCnvStorOkFunc_DataBlock
	ld	wa, (xsp+6)
	add	(xsp+16), wa
	incw	1, (xsp+14)
	ld	wa, (xsp+14)
	.byte 0x9f, 0x04, 0xf0
	jr	c, StylCnvStorOkFunc_DataBlock_Loop3
StylCnvStorOkFunc_DataBlock_Epilogue:
	pop	xiz
	lda	xsp, (xsp+30)
	retd	4
StylCnvStorBnk_ProcDataBlock_Helper2:
	lda	xsp, (xsp-32)
	push	xiz
	ld	(xsp+34), bc
	ld	bc, (xsp+40)
	cp	bc, 3:i3
	jr	z, StylCnvStorOkFunc_DataBlock_Skip4
	cp	bc, 2:i3
	jr	z, StylCnvStorOkFunc_DataBlock_Entry3
	cp	bc, 1:i3
	scc16	nz, bc
	ld	(xsp+6), bc
	ldw (xsp+8), 0
	ld	xiy, xwa
	lda	xix, (xsp+26)
	ld	bc, 4:i3
	ldirw
StylCnvStorOkFunc_DataBlock_Join5:
	lda	xhl, (xsp+26)
	lda	xix, (xhl+4)
	ld	bc, (xix)
	ld	wa, bc
	sub	wa, (xhl)
	mul	xwa, de
	ld	qiz, wa
	extz	xwa
	div	wa, 100
	ld qiz, wa
	lda	xde, (xhl+6)
	lda	xiy, (xhl+2)
	ld	wa, (xde)
	sub	wa, (xiy)
	mul	xwa, (xsp+42)
	ld	iz, wa
	extz	xwa
	div	wa, 100
	ld	iz, wa
	ld	wa, bc
	.byte 0x93, 0xa0
	ld	(xsp+4), wa
	ld wa, qiz
	sub	(xsp+4), wa
	cpw	(xsp+6), 0
	jr	z, StylCnvStorOkFunc_DataBlock_Skip8
	ld	(xsp+22), bc
	ld	wa, (xix)
	sub wa, qiz
	ld	(xsp+18), wa
	jr	StylCnvStorOkFunc_DataBlock_Join7
StylCnvStorOkFunc_DataBlock_Entry3:
	ldw	(xsp+6), 1
	jr	StylCnvStorOkFunc_DataBlock_Join6
StylCnvStorOkFunc_DataBlock_Skip4:
	ldw (xsp+6), 0
StylCnvStorOkFunc_DataBlock_Join6:
	ldw	(xsp+8), 1
	lda	xhl, (xsp+26)
	ld	bc, (xwa+2)
	ld	(xhl), bc
	ld	bc, (xwa)
	ld	(xhl+2), bc
	ld	bc, (xwa+6)
	ld	(xhl+4), bc
	ld	wa, (xwa+4)
	ld	(xhl+6), wa
	jr	StylCnvStorOkFunc_DataBlock_Join5
StylCnvStorOkFunc_DataBlock_Skip8:
	ld	wa, (xhl)
	ld	(xsp+22), wa
	ld	wa, (xhl)
	add wa, qiz
	ld	(xsp+18), wa
StylCnvStorOkFunc_DataBlock_Join7:
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
	pushm	(xsp+8)
	ld	xbc, xde
	ld	de, (xsp+36)
	calr	StylCnvStorOkFunc_DataBlock
	lda	xwa, (xsp+22)
	lda	xbc, (xsp+18)
	ld	de, (xbc)
	ld	(xwa), de
	ld	de, (xsp+28)
	ld	(xwa+2), de
	pushm	(xsp+8)
	ld	de, (xsp+36)
	calr	StylCnvStorOkFunc_DataBlock
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
	pushm	(xsp+8)
	ld	xbc, xde
	ld	de, (xsp+36)
	calr	StylCnvStorOkFunc_DataBlock
	lda	xwa, (xsp+22)
	lda	xbc, (xsp+18)
	ld	de, (xbc)
	ld	(xwa), de
	ld	de, (xsp+32)
	ld	(xwa+2), de
	pushm	(xsp+8)
	ld	de, (xsp+36)
	calr	StylCnvStorOkFunc_DataBlock
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
	pushm	(xsp+8)
	ld	de, (xsp+36)
	calr	StylCnvStorOkFunc_DataBlock
	lda	xwa, (xsp+26)
	lda	xbc, (xsp+22)
	lda	xde, (xsp+18)
	cpw	(xsp+6), 0
	jr	z, StylCnvStorOkFunc_DataBlock_Skip9
	ld	wa, (xwa+4)
	sub wa, qiz
	ld	(xbc), wa
	sub	wa, (xsp+4)
	inc	1, wa
	ld	(xde), wa
	jr	StylCnvStorOkFunc_DataBlock_Join8
StylCnvStorOkFunc_DataBlock_Skip9:
	ld	wa, (xwa)
	add wa, qiz
	ld	(xbc), wa
	add	wa, (xsp+4)
	dec	1, wa
	ld	(xde), wa
StylCnvStorOkFunc_DataBlock_Join8:
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
	pushm	(xsp+8)
	ld	de, (xsp+36)
	calr	StylCnvStorOkFunc_DataBlock
	lda	xwa, (xsp+22)
	lda	xhl, (xsp+26)
	lda	xde, (xhl+6)
	ld	bc, (xde)
	ld	(xwa+2), bc
	ld	de, (xde)
	ld	bc, de
	sub	bc, (xhl+2)
	exts	xbc
	divs	bc, 2
	sub	de, bc
	lda	xbc, (xsp+18)
	ld	(xbc+2), de
	pushm	(xsp+8)
	ld	de, (xsp+36)
	calr	StylCnvStorOkFunc_DataBlock
	pop	xiz
	lda	xsp, (xsp+32)
	retd	4
StylCnvStorBnk_ProcDataBlock:
	lda	xsp, (xsp-16)
	push	xiz
	ld	(xsp+16), xwa
	cp	xbc, EVT_PAINT
	jr	z, StylCnvStorBnk_ProcDataBlock_OnPaint
	ld	xwa, (xsp+16)
	call	InheritedProc
	jr	StylCnvStorBnk_ProcDataBlock_Epilogue
StylCnvStorBnk_ProcDataBlock_OnPaint:
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
	cpw	(xiz+24), 0
	jr	z, StylCnvStorBnk_ProcDataBlock_Skip2
	pushm	(xix)
	pushm	(xhl)
	calr	StylCnvStorBnk_ProcDataBlock_Helper2
	jr	StylCnvStorBnk_ProcDataBlock_Join
StylCnvStorBnk_ProcDataBlock_Skip2:
	pushm	(xix)
	pushm	(xhl)
	calr	StylCnvStorBnk_ProcDataBlock_Helper
StylCnvStorBnk_ProcDataBlock_Join:
	ld	xhl, 0:i3
StylCnvStorBnk_ProcDataBlock_Epilogue:
	pop	xiz
	lda	xsp, (xsp+16)
	ret

CmpNameMenuBoxProc:
	push xiz
	ld xiz, xwa
	cp xbc, EVT_DRAW
	jr z, CmpNameMenuBoxProc_OnDraw
	ld xwa, xiz
	call InheritedProc
	jr CmpNameMenu_Epilogue

CmpNameMenuBoxProc_OnDraw:
	cp (0x34d6:16), 12
	jr nc, CmpNameMenu_SetReturnZero
	ld xwa, xiz
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call SendEvent

CmpNameMenu_SetReturnZero:
	ld xhl, 0:i3

CmpNameMenu_Epilogue:
	pop xiz
	ret

AttLangCheck:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, AttLangCheck_ReturnZero
	lda xhl, (AttLangCheck_Data:24)
	ret

AttLangCheck_ReturnZero:
	ld xhl, 0:i3
	ret

SureLangCheck:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, SureLangCheck_ReturnZero
	lda xhl, (SureLangCheck_Data:24)
	ret

SureLangCheck_ReturnZero:
	ld xhl, 0:i3
	ret

SndMemLangCheck:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, SndMemLangCheck_ReturnZero
	lda xhl, (SndMemLangCheck_Data:24)
	ret

SndMemLangCheck_ReturnZero:
	ld xhl, 0:i3
	ret

SndMem1LangCheck:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, SndMem1LangCheck_ReturnZero
	lda xhl, (SndMem1LangCheck_Data:24)
	ret

SndMem1LangCheck_ReturnZero:
	ld xhl, 0:i3
	ret

MemfulLangCheck:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, MemfulLangCheck_ReturnZero
	lda xhl, (MemfulLangCheck_Data:24)
	ret

MemfulLangCheck_ReturnZero:
	ld xhl, 0:i3
	ret

Memful2LangCheck:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, Memful2LangCheck_ReturnZero
	lda xhl, (Memful2LangCheck_Data:24)
	ret

Memful2LangCheck_ReturnZero:
	ld xhl, 0:i3
	ret

StylCnvLangCheck:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, StylCnvLangCheck_ReturnZero
	lda xhl, (StylCnvLangCheck_Data:24)
	ret

StylCnvLangCheck_ReturnZero:
	ld xhl, 0:i3
	ret

SndArrLangCheck:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, SndArrLangCheck_ReturnZero
	lda xhl, (Hama_ModeInit_Table:24)
	ret

SndArrLangCheck_ReturnZero:
	ld xhl, 0:i3
	ret

PsStylCnvVerProc:
	lda xsp, (xsp-512)
	push xiz
	ld xiz, xwa
	cp xbc, EVT_REPAINT
	jr z, PsStylCnvVerProc_OnPaintOrRepaint
	cp xbc, EVT_PAINT
	jr z, PsStylCnvVerProc_OnPaintOrRepaint
	cp xbc, EVT_GET_STR_PTR
	jr z, PsStylCnvVerProc_OnGetStrPtr
	cp xbc, EVT_HIDE
	jr z, PsStylCnvVerProc_OnHide
	cp xbc, EVT_SHOW
	jr z, PsStylCnvVerProc_OnShow
	ld xwa, xiz
	call InheritedProc
	jr StylCnvVer_Epilogue

PsStylCnvVerProc_OnShow:
	ld xwa, xiz
	jr StylCnvVer_CallInherited

PsStylCnvVerProc_OnHide:
	ld xwa, xiz

StylCnvVer_CallInherited:
	call InheritedProc
	jr StylCnvVer_SetReturnZero

PsStylCnvVerProc_OnGetStrPtr:
	lda xhl, (0x3f68:16)
	jr StylCnvVer_Epilogue

PsStylCnvVerProc_OnPaintOrRepaint:
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
	ld xbc, EVT_PARA_DRAW
	call SendEvent

StylCnvVer_SetReturnZero:
	ld xhl, 0:i3

StylCnvVer_Epilogue:
	pop xiz
	lda xsp, (xsp+512)
	ret


.include "factory_test/test_init.s"
