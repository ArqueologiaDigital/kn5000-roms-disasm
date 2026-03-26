; =============================================================================
; Sound Editor UI
; =============================================================================
;
; Sound editor user interface: patch/bank selection, parameter
; editing, drum kit editor. Includes flash/floppy integration
; for saving/loading sound patches.
; =============================================================================

InitializeSeMenuDefaults:
	lds wa, 0
	call SeMenu_SetSoundBank
	lds wa, 0
	call SeMenu_SetPatchBank
	call AccWrap_PlayModeDispatch
	lds wa, 1
	call SeMenu_SetEditEnable
	lds wa, 1
	call SeMenu_OrPartConfig
	lds wa, 0
	call SeMenu_SetConfirmState
	jp SeMenu_ClearDisplayBuffer

UpdateSeMenuSelection:
	dec 2, xsp
	lds wa, 0
	call SeMenu_SetSelectedRow
	lds wa, 0
	call SeMenu_SetEditEnable
	lda xwa, (xsp)
	call SeMenu_LoadObjEntries
	cp (xsp), 0x2
	jr z, UpdSeSel_SkipMenuSetup
	lds wa, 0
	call SeMenu_SetupMenuDisplay

UpdSeSel_SkipMenuSetup:
	lds wa, 0
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
	lds wa, 1
	call SeMenu_SetDisplayState
	pushw 0x20
	lds wa, 0
	ldw bc, 0x10
	lds de, 1
	call SeMenu_RegisterElement_Type1
	lds wa, 1
	call SeMenu_SetCurrentStep
	jrl UpdSeSel_ProcessStep_End

UpdSeSel_Step1_CheckEnabled:
	cp (xsp + 16), 0x1
	jr nz, UpdSeSel_UpdateEntries
	ldw wa, 0x81
	call SeMenu_CheckObjEnabled
	cps hl, 0
	jr nz, UpdSeSel_Step1_Disable
	ldw wa, 0x10
	call SeMenu_CheckObjValid
	cps hl, 0
	jr z, UpdSeSel_Step1_FillTable

UpdSeSel_Step1_Disable:
	ldw wa, 0x10
	call SeMenu_SetCurrentStep
	lds wa, 0
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
	lds wa, 1
	call SeMenu_SetMode
	lds wa, 2
	jr UpdSeSel_Step1_SetStep

UpdSeSel_Step1_Flag40:
	cp a, 0x40
	jr nz, UpdSeSel_Step1_DefaultMode
	lds wa, 2
	call SeMenu_SetMode
	ldw wa, 0xea
	lds bc, 0
	call SeMenu_SendEvent
	lds wa, 0
	call SeMenu_SetCurrentStep
	lds wa, 0

UpdSeSel_Step1_SetDisplayState:
	call SeMenu_SetDisplayState
	jr UpdSeSel_ProcessStep_End

UpdSeSel_Step1_DefaultMode:
	lds wa, 0
	call SeMenu_SetMode
	lds wa, 2

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
	lds wa, 0
	ldw bc, 0x11
	lds de, 1
	call SeMenu_RegisterElement_Type1
	lds wa, 3
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
	lds wa, 4
	jrl UpdSeSel_SimpleUpdate_SetStepAndJump

UpdSeSel_SimpleUpdate_Step4:
	cp (xsp + 42), 0x4
	jr nz, UpdSeSel_SimpleUpdate_Step5
	lda xwa, (xsp + 6)
	call SeMenu_FillObjTable
	ld c, (xsp + 7)
	extz bc
	lds wa, 0
	call SeMenu_StoreEffectCoeff
	ld c, (xsp + 8)
	extz bc
	lds wa, 1
	call SeMenu_StoreEffectCoeff
	ld c, (xsp + 9)
	extz bc
	lds wa, 2
	call SeMenu_StoreEffectCoeff
	lda xde, (xsp + 2)
	lds wa, 0
	lds bc, 1
	call SeMenu_TransferPartValues
	ld c, (xsp + 2)
	extz bc
	pushw 0x20
	lds wa, 0
	lds de, 4
	call SeMenu_RegisterElement_Type1
	lds wa, 5
	jr UpdSeSel_SimpleUpdate_SetStepAndJump

UpdSeSel_SimpleUpdate_Step5:
	lda xwa, (xsp + 6)
	cp (xsp + 42), 0x5
	jr nz, UpdSeSel_SimpleUpdate_Step6
	call SeMenu_FillEntryTable
	ld c, (xsp + 6)
	extz bc
	lds wa, 0
	call SeMenu_StoreEffectParam
	ld c, (xsp + 7)
	extz bc
	lds wa, 1
	call SeMenu_StoreEffectParam
	ld c, (xsp + 9)
	extz bc
	lds wa, 2
	call SeMenu_StoreEffectParam
	ldw wa, 0x20
	call SeMenu_RegisterParamDisplay
	lds wa, 6

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
	lds wa, 1
	call SeMenu_StorePartParam
	ldib_erp 0xfb, 1

UpdSeSel_SimpleUpdate_Step6_RegLoop:
	stb_erp A, 0xfb
	extz wa
	pushw 0x20
	ldw bc, 0x17
	lds de, 1
	call SeMenu_RegisterElement_Type1
	inc1b_erp 0xfb
	cpib_erp 0xfb, 4
	jr ule, UpdSeSel_SimpleUpdate_Step6_RegLoop
	lds wa, 7
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
	cps l, 4
	jr ule, UpdSeSel_SimpleUpdate_End
	pushw 0x20
	call SeMenu_ShowPopupDialog
	inc 2, xsp
	lds wa, 0
	call SeMenu_SetCurrentStep
	call SeMenu_ResetSubIndex
	lds wa, 0
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
	lds wa, 0
	call SeMenu_StorePartParam
	lda xwa, (xsp + 14)
	lda xbc, (xsp + 12)
	call SeMenu_SetupSoundBankPair
	cp (xsp + 12), 0xff
	jr nz, UpdSeSel_DetailedUpdate_Step3_Store
	lds wa, 0
	call SeMenu_SetCurrentStep
	ldw wa, 0x10
	call SeMenu_SetCurrentStep
	lds wa, 0
	jrl UpdSeSel_DetailedUpdate_SetDisplayState

UpdSeSel_DetailedUpdate_Step3_Store:
	ld c, (xsp + 14)
	extz bc
	lds wa, 1
	call SeMenu_StorePartParam
	lda xwa, (xsp + 12)
	call SeMenu_SetupDisplayObject
	lds wa, 4
	call SeMenu_SetCurrentStep
	ldw wa, 0x20
	lds bc, 1
	jrl UpdSeSel_DetailedUpdate_SendEventAndEnd

UpdSeSel_DetailedUpdate_Step2:
	cp (xsp + 32), 0x2
	jrl nz, UpdSeSel_DetailedUpdate_Step4
	lda xwa, (xsp + 2)
	call SeMenu_LoadConfirmData
	cp (xsp + 2), 0x1
	jr nz, UpdSeSel_DetailedUpdate_Step2_CheckActive
	lds wa, 2
	call SeMenu_ClearNotification
	lds wa, 0
	call SeMenu_SetConfirmState
	jrl UpdSeSel_DetailedUpdate_End

UpdSeSel_DetailedUpdate_Step2_CheckActive:
	call SeMenu_ReturnZero
	cps l, 0
	jr z, UpdSeSel_DetailedUpdate_Step2_ReadPatch
	lds wa, 1
	call SeMenu_SetConfirmState
	ldw wa, 0x2d
	call SeMenu_TriggerNotification
	lds wa, 0
	jrl UpdSeSel_DetailedUpdate_SetStepAndJump

UpdSeSel_DetailedUpdate_Step2_ReadPatch:
	lda xwa, (xsp + 4)
	call SeMenu_LoadPatchStatus
	cp (xsp + 4), 0x0
	jr nz, UpdSeSel_DetailedUpdate_Step2_SetStep3
	pushw 0x20
	lds wa, 0
	ldw bc, 0x12
	lds de, 1
	call SeMenu_RegisterElement_Type2
	lds wa, 1
	call SeMenu_SetPatchBank
	jrl UpdSeSel_DetailedUpdate_End

UpdSeSel_DetailedUpdate_Step2_SetStep3:
	lds wa, 3
	call SeMenu_SetCurrentStep
	ldw wa, 0x86
	call SeMenu_CheckObjEnabled
	cps hl, 0
	jr nz, UpdSeSel_DetailedUpdate_Step2_Disable
	ldw wa, 0x12
	call SeMenu_CheckObjValid
	cps hl, 0
	jr z, UpdSeSel_DetailedUpdate_Step2_FillTable

UpdSeSel_DetailedUpdate_Step2_Disable:
	ldw wa, 0x10
	call SeMenu_SetCurrentStep
	lds wa, 0
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
	lds wa, 0
	call SeMenu_SetPatchBank
	ldw wa, 0x20
	lds bc, 1

UpdSeSel_DetailedUpdate_SendEventAndEnd:
	call SeMenu_SendEvent
	jrl UpdSeSel_DetailedUpdate_End

UpdSeSel_DetailedUpdate_Step4:
	cp (xsp + 32), 0x4
	jrl nz, UpdSeSel_DetailedUpdate_Step5
	call SeMenu_InitTrackInfo
	pushw 0x20
	lds wa, 0
	ldw bc, 0xd
	lds de, 1
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
	lds wa, 0
	lds de, 1
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
	lds wa, 0
	lds de, 1
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
	lds wa, 0
	lds de, 1
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
	lds wa, 0
	lds de, 1
	call SeMenu_RegisterElement_Type2
	inc1b_erp 0xfb
	cpib_erp 0xfb, 2
	jr c, UpdSeSel_DetailedUpdate_Step4_RegLoop4
	pushw 0x20
	lds wa, 0
	ldw bc, 0xf
	lds de, 1
	call SeMenu_RegisterElement_Type2
	lds wa, 5
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
	lds wa, 2
	call SeMenu_LoadPartParam
	ld a, (xsp + 10)
	extz wa
	call SeMenu_StorePartMask
	lds wa, 1
	call SeMenu_ApplyPartEdit
	lds wa, 2
	call SeMenu_ApplyPartEdit
	lda xbc, (xsp + 16)
	lds wa, 3
	call SeMenu_LoadPartParam
	ld c, (xsp + 16)
	extz bc
	lds wa, 1
	call SeMenu_StoreParamByte
	lda xbc, (xsp + 16)
	lds wa, 4
	call SeMenu_LoadPartParam
	ld c, (xsp + 16)
	extz bc
	lds wa, 2
	call SeMenu_StoreParamByte
	lds wa, 1
	ldw bc, 0x20
	call SeMenu_InitDisplayField
	lds wa, 6
	jr UpdSeSel_DetailedUpdate_SetStepAndJump

UpdSeSel_DetailedUpdate_Step6:
	cp (xsp + 32), 0x6
	jr nz, UpdSeSel_DetailedUpdate_Step7
	lds wa, 1
	call SeMenu_ApplyFilter
	lds wa, 2
	ldw bc, 0x20
	call SeMenu_InitDisplayField
	lds wa, 7
	jr UpdSeSel_DetailedUpdate_SetStepAndJump

UpdSeSel_DetailedUpdate_Step7:
	cp (xsp + 32), 0x7
	jr nz, UpdSeSel_DetailedUpdate_Step8
	lds wa, 2
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
	lds wa, 3
	ldw bc, 0x20
	call SeMenu_InitDisplayColumn
	ldw wa, 0x9
	jr UpdSeSel_DetailedUpdate_SetStepAndJump

UpdSeSel_DetailedUpdate_Step9:
	cp (xsp + 32), 0x9
	jr nz, UpdSeSel_DetailedUpdate_StepA
	lds32 xwa, 3
	call SeMenu_ProcessEffect
	lds wa, 2
	ldw bc, 0x20
	call SeMenu_InitDisplayColumn
	ldw wa, 0xa

UpdSeSel_DetailedUpdate_SetStepAndJump:
	call SeMenu_SetCurrentStep
	jr UpdSeSel_DetailedUpdate_End

UpdSeSel_DetailedUpdate_StepA:
	cp (xsp + 32), 0xa
	jr nz, UpdSeSel_DetailedUpdate_End
	lds32 xwa, 2
	call SeMenu_ProcessEffect
	pushw 0x20
	call SeMenu_ShowPopupDialog
	pushw 0x0
	pushw 0x20
	call SeMenu_ShowConfirmDialog
	inc 6, xsp
	lds wa, 0
	call SeMenu_SetCurrentStep
	call SeMenu_ResetSubIndex
	ldw wa, 0x10
	call SeMenu_SetCurrentStep
	lds wa, 0

UpdSeSel_DetailedUpdate_SetDisplayState:
	call SeMenu_SetDisplayState

UpdSeSel_DetailedUpdate_End:
	popw_erp 0xfa
	lda xsp, (xsp + 32)
	ret

UpdSeSel_ExtendedOps_Data:
	.incbin "includes/generated/v7_transplant_UpdSeSel_ExtendedOps_Data.bin"
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
	lds de, 1
	call SeMenu_RegisterElement_Type1
	stb_erp A, 0xfb
	extz wa
	pushw 0x22
	lds bc, 4
	lds de, 1
	call SeMenu_RegisterElement_Type1
	stb_erp A, 0xfb
	extz wa
	pushw 0x22
	lds bc, 5
	lds de, 1
	call SeMenu_RegisterElement_Type1
	inc1b_erp 0xfb
	cpib_erp 0xfb, 4
	jr ule, SeMenu_AltUpdate_RegLoop
	lds wa, 1
	call SeMenu_SetCurrentStep
	call SeMenu_AdvanceSubIndex
	lda xwa, (xsp + 4)
	call SeMenu_ValidatePartNumber
	ld c, (xsp + 4)
	extz bc
	lds wa, 0
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
	lds wa, 2
	jr SeMenu_AltUpdate_SetStepAndJump

SeMenu_AltUpdate_Step2:
	cp (xsp + 38), 0x2
	jr nz, SeMenu_AltUpdate_Step3Plus
	call SeMenu_ReadObjParam
	ld a, (xsp + 2)
	extz wa
	call SeMenu_ApplyFilter
	call SeMenu_AdvanceSubIndex
	cps l, 4
	jr ugt, SeMenu_AltUpdate_Step2_InitCol
	lda xwa, (xsp + 2)
	call SeMenu_ReadObjParam
	ld a, (xsp + 2)
	extz wa
	ldw bc, 0x22
	call SeMenu_InitDisplayField
	jrl SeMenu_AltUpdate_End

SeMenu_AltUpdate_Step2_InitCol:
	lds wa, 0
	ldw bc, 0x22
	call SeMenu_InitDisplayColumn
	lds wa, 3

SeMenu_AltUpdate_SetStepAndJump:
	call SeMenu_SetCurrentStep
	jr SeMenu_AltUpdate_End

SeMenu_AltUpdate_Step3Plus:
	lds32 xwa, 0
	call SeMenu_ProcessEffect
	lda xbc, (xsp + 6)
	lds wa, 1
	call SeMenu_LoadParamByte
	ld c, (xsp + 6)
	extz bc
	lds wa, 2
	call SeMenu_StorePartParam
	lda xbc, (xsp + 6)
	lds wa, 2
	call SeMenu_LoadParamByte
	ld c, (xsp + 6)
	extz bc
	lds wa, 5
	call SeMenu_StorePartParam
	lda xbc, (xsp + 6)
	lds wa, 3
	call SeMenu_LoadParamByte
	ld c, (xsp + 6)
	extz bc
	ldw wa, 0x8
	call SeMenu_StorePartParam
	lda xbc, (xsp + 6)
	lds wa, 4
	call SeMenu_LoadParamByte
	ld c, (xsp + 6)
	extz bc
	ldw wa, 0xb
	call SeMenu_StorePartParam
	pushw 0x22
	call SeMenu_ShowPopupDialog
	inc 2, xsp
	lds wa, 1
	call SeMenu_SetupMenuDisplay
	lds wa, 0
	call SeMenu_SetCurrentStep
	call SeMenu_ResetSubIndex

SeMenu_AltUpdate_End:
	popw_erp 0xfa
	lda xsp, (xsp + 38)
	ret

SeMenu_AltUpdate_Data:
	.incbin "includes/generated/v7_transplant_SeMenu_AltUpdate_Data.bin"
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
	ldb c, 0x0
	addb_erp C, 0xfb
	pushw 0x26
	lds de, 1
	call SeMenu_RegisterElement_Type1
	inc1b_erp 0xfb
	cpib_erp 0xfb, 3
	jr c, SeMenu_ControllerUpdate_Step1
	jr SeMenu_ControllerUpdate_Step3

SeMenu_ControllerUpdate_Step2:
	ld a, (xsp + 8)
	extz wa
	ldb c, 0x0
	addb_erp C, 0xfb
	pushw 0x26
	lds de, 1
	call SeMenu_RegisterElement_Type2
	inc1b_erp 0xfb
	cpib_erp 0xfb, 3
	jr c, SeMenu_ControllerUpdate_Step2

SeMenu_ControllerUpdate_Step3:
	lds wa, 1
	call SeMenu_SetCurrentStep
	call SeMenu_AdvanceSubIndex
	lds wa, 0
	lds bc, 1
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
	cps l, 3
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
	lds wa, 2
	jr SeMenu_ControllerData_Offset3

SeMenu_ControllerUpdate_End:
	cp (xsp + 42), 0x2
	jr nz, SeMenu_ControllerData_Offset4
	call SeMenu_ReadObjParam
	ld a, (xsp + 4)
	extz wa
	call SeMenu_ApplySynthParam_Alt
	call SeMenu_AdvanceSubIndex
	cps l, 4
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
	lds wa, 1
	ldw bc, 0x26
	jr SeMenu_ControllerData_Offset2

SeMenu_ControllerData_Offset1:
	lds wa, 4
	ldw bc, 0x26

SeMenu_ControllerData_Offset2:
	call SeMenu_InitDisplayColumn
	lds wa, 3

SeMenu_ControllerData_Offset3:
	call SeMenu_SetCurrentStep
	jr SeMenu_ControllerData_End

SeMenu_ControllerData_Offset4:
	cp (xsp + 2), 0x0
	jr nz, SeMenu_ControllerData_Offset5
	lds32 xwa, 1
	jr SeMenu_ControllerData_Offset6

SeMenu_ControllerData_Offset5:
	lds32 xwa, 4

SeMenu_ControllerData_Offset6:
	call SeMenu_ProcessEffect
	calr SeMenu_CopyWriteUpdate
	pushw 0x26
	call SeMenu_ShowPopupDialog
	inc 2, xsp
	lds wa, 1
	call SeMenu_SetupMenuDisplay
	lds wa, 0
	call SeMenu_SetCurrentStep
	call SeMenu_ResetSubIndex

SeMenu_ControllerData_End:
	popw_erp 0xfa
	lda xsp, (xsp + 42)
	ret

SeMenu_CopyWriteUpdate:
	dec 2, xsp
	lda xbc, (xsp)
	lds wa, 1
	call SeMenu_LoadPartParam
	cp (xsp), 0x7f
	jr nz, SeMenu_CopyWriteUpdate_Step1
	lds wa, 4
	lds bc, 0
	call SeMenu_StorePartParam
	lds wa, 5
	lds bc, 0
	call SeMenu_StorePartParam
	lds wa, 6
	lds bc, 0
	jr SeMenu_CopyWriteUpdate_End

SeMenu_CopyWriteUpdate_Step1:
	ld c, (xsp)
	inc 1, c
	extz bc
	lds wa, 4
	call SeMenu_StorePartParam
	lda xbc, (xsp)
	lds wa, 2
	call SeMenu_LoadPartParam
	cp (xsp), 0x7f
	jr nz, SeMenu_CopyWriteUpdate_Step2
	lds wa, 5
	lds bc, 0
	call SeMenu_StorePartParam
	lds wa, 6
	lds bc, 0
	jr SeMenu_CopyWriteUpdate_End

SeMenu_CopyWriteUpdate_Step2:
	ld c, (xsp)
	inc 1, c
	extz bc
	lds wa, 5
	call SeMenu_StorePartParam
	lda xbc, (xsp)
	lds wa, 3
	call SeMenu_LoadPartParam
	cp (xsp), 0x7f
	jr nz, SeMenu_CopyWriteUpdate_Step3
	lds wa, 6
	lds bc, 0
	jr SeMenu_CopyWriteUpdate_End

SeMenu_CopyWriteUpdate_Step3:
	ld c, (xsp)
	inc 1, c
	extz bc
	lds wa, 6
	call SeMenu_StorePartParam
	lds wa, 7
	ldw bc, 0x7f

SeMenu_CopyWriteUpdate_End:
	call SeMenu_StorePartParam
	inc 2, xsp
	ret

SeMenu_CopyWriteUpdate_Data:
	.incbin "includes/generated/v7_transplant_SeMenu_CopyWriteUpdate_Data.bin"
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
	cps hl, 0
	jr ge, SeMenu_PopupDialog_CheckState

SeMenu_PopupDialog_ShowTitle:
	lda_24 xde, (0x020c33)
	ld c, (xde)
	ld a, c
	and a, 0xf0
	cp a, 0x80
	jr z, SeMenu_PopupDialog_ShowBody_Data

SeMenu_PopupDialog_ShowBody:
	call SeqBuf_SoundEdit_ReadByte
	cps hl, 0
	jr ge, SeMenu_PopupDialog_ShowBody
	jrl SeMenu_ListSelector_ScrollDown

SeMenu_PopupDialog_ShowBody_Data:
	cpiw_erp 0xfa, 6
	jrl c, SeMenu_ListSelector_ScrollDown
	cp c, 0x80
	jrl nz, SeMenu_ValueEditor_Data4
	ld a, (xde + 2)
	cps a, 4
	jr nz, SeMenu_PopupDialog_Confirm
	lds iz, 0
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
	cps hl, 0
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
	cps a, 0
	jr nz, SeMenu_ValueEditor_Setup

SeMenu_PopupDialog_Close:
	call SeqBuf_SoundEdit_ReadByte
	cps hl, 0
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
	.incbin "includes/generated/v7_transplant_SeMenu_PopupDialog_Close_Data.bin"
SeMenu_ValueEditor_Init:
	.incbin "includes/generated/v7_transplant_SeMenu_ValueEditor_Init.bin"
SeMenu_ValueEditor_Setup:
	call SeqBuf_SoundEdit_ReadByte
	lda_24 xwa, (0x020c33)
	cps hl, 0
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
	.incbin "includes/generated/v7_transplant_SeMenu_ValueEditor_Draw.bin"
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
	.incbin "includes/generated/v7_transplant_SeMenu_ValueEditor_Decrement.bin"
SeMenu_ValueEditor_ClampAndStore:
	cp a, 0x10
	jr nz, SeMenu_ValueEditor_Data3
	calr SeMenu_ListSelector_Data3
	jrl SeMenu_ListSelector_ScrollDown

SeMenu_ValueEditor_Redraw:
	.incbin "includes/generated/v7_transplant_SeMenu_ValueEditor_Redraw.bin"
SeMenu_ValueEditor_Complete:
	.incbin "includes/generated/v7_transplant_SeMenu_ValueEditor_Complete.bin"
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
	cps iz, 0
	jr z, SeMenu_ListSelector_Setup
	call SeqBuf_SoundEdit_ReadByte
	cps hl, 0
	jr ge, SeMenu_ValueEditor_Data5

SeMenu_ListSelector_Setup:
	lda_24 xbc, (0x020c33)
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
	.incbin "includes/generated/v7_transplant_SeMenu_ListSelector_HandleInput.bin"
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
	cps hl, 0
	ret z

SeMenu_ListSelector_Complete:
	calr SeMenu_PopupDialog_Init
	call SeqBuf_NoteEvent_CheckSongEnd
	cps hl, 0
	jr nz, SeMenu_ListSelector_Complete
	ret

SeMenu_ListSelector_Cancel:
	dec 4, xsp
	lda xwa, (xsp)
	call SeMenu_LoadObjEntries
	lda xbc, (xsp + 2)
	lds wa, 0
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
	lds wa, 0
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
	lds wa, 1
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
	stib_da	(0x03efa8), 0
	push xwa
	ld xwa, 0x000006ca
	call DrawText_LayoutAndRender_Variant1_0x2EB
	pop xwa
	ret
SeMenu_NameEditor_InsertChar:
	; --- Wrapper function 5: same pattern ---
	stib_da	(0x03efa8), 0
	push xwa
	ld xwa, 0x000006ca
	call DrawText_LayoutAndRender_Variant1_0x33F
	pop xwa
	ret
SeMenu_NameEditor_DeleteChar:
	; --- Wrapper function 6: set flag + store 4 regs, call ---
	stib_da	(0x03efa8), 0
	push xwa
	stda32	1740, xiy
	stda16	(1744), ix
	stda16	(1746), bc
	stda16	(1748), hl
	ld xwa, 0x000006ca
	call DrawText_LayoutAndRender_Variant1_0x616
	pop xwa
	ret
SeMenu_NameEditor_MoveCursor:
	; --- Wrapper function 7: same as 4/5 pattern ---
	stib_da	(0x03efa8), 0
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
	stib_da	(0x03efa8), 0
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
	stib_da	(0x03efa8), 0
	push xwa
	ld xwa, 0x000006ca
	call DrawText_LayoutAndRender_Variant1_0x3BD
	pop xwa
	ret
SeMenu_NameEditor_Complete:
	; --- Wrapper function 13: set flag, push, ld xwa=imm, call, pop, ret ---
	stib_da	(0x03efa8), 0
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
	.incbin "includes/generated/v7_transplant_SeMenu_NameEditor_End.bin"
SeMenu_DisplayPartValue:
	.incbin "includes/generated/v7_transplant_SeMenu_DisplayPartValue.bin"
SeMenu_DisplayPartValue_Data:	.ascii ">89:;<="
	ld	wa, (xiz+8)
	cp	wa, 50
	jr	nz, 12
	stda16	(1740), wa
	inc	1, wa
	stda16	(1744), wa
	jr	30
	cp	wa, 50
	jr	nz, 12
	stda16	(1744), wa
	dec	1, wa
	stda16	(1740), wa
	jr	12
	dec	1, wa
	stda16	(1740), wa
	inc	2, wa
	stda16	(1744), wa
	ld	wa, (xiz+10)
	cp	wa, 58
	jr	nz, 12
	stda16	(1742), wa
	inc	1, wa
	stda16	(1746), wa
	jr	30
	cp	wa, 146
	jr	nz, 12
	stda16	(1746), wa
	dec	1, wa
	stda16	(1742), wa
	jr	12
	dec	1, wa
	stda16	(1742), wa
	inc	2, wa
	stda16	(1746), wa
	stib_da	(0x03efa8), 0
	call	SeMenu_NameEditor_ChangeCase_Data
	pop	xiy
	.ascii "\\[ZYX^"
	ret
	push xiz
	ld	xiz, xsp
	.ascii "89:;<="
	ld	wa, (xiz+8)
	stda16	(1740), wa
	ld	wa, (xiz+10)
	stda16	(1742), wa
	ld	wa, (xiz+12)
	stda16	(1744), wa
	ld	wa, (xiz+14)
	stda16	(1746), wa
	stib_da	(0x03efa8), 0
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
	ldio	32, 241
	cpl	d
	.byte 0x50
	ld	wa, (xiz+10)
	stda16	(1742), wa
	ld	wa, (xiz+12)
	stda16	(1744), wa
	ld	wa, (xiz+14)
	stda16	(1746), wa
	stib_da	(0x03efa8), 0
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
	.incbin "includes/generated/v7_transplant_SeMenu_ShowConfirmDialog.bin"
SeMenu_ShowConfirmDialog_Data:
	.incbin "includes/generated/v7_transplant_SeMenu_ShowConfirmDialog_Data.bin"
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
	ldb c, 0x0
	ldb a, 0xc
	ldb a, 0x10
	call Display_DeferOrDrawWall
	ret

SeMenu_WaveformSelect_Process:
	ldb c, 0x7
	ldb a, 0xc
	call Display_DeferOrUpdateScreen
	ret

SeMenu_WaveformSelect_Apply:
	stib_da	(0x03efa8), 0
	ld	xiz, TuningSystem_Handler_Table_0x1E73
	xor	xwa, xwa
	ldb_da	a, (0x0340e4)
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
	.incbin "includes/generated/v7_transplant_SeMenu_WaveformSelect_Data.bin"
SeMenu_PresetManager_Init:
	.byte 0xc1, 0xae, 0x06
	push	xsp
	.byte 0x01
	jr	z, 7
	call	SeMenu_WaveformSelect_Data_0x6D
	jrl	194
	cps	a, 0
	jr	z, 52
	cps	a, 1
	jr	z, 101
	cps	a, 2
	jr	z, 117
	cp	a, 15
	jr	z, 118
	cp	a, 16
	jrl	z, 134
	cp	a, 13
	jrl	c, 150
	stib_da	(0x03efa8), 0
	ld	xiy, FlashWrite_BlockRef_Type6_0x633
	ld	xix, FlashWrite_BlockRef_Type6_0x655
	call	SeMenu_NameEditor_Draw
	call	SeMenu_WaveformSelect_Data_0x99
	jrl	138
	stib_da	(0x03efa8), 1
	ld	xiy, FlashWrite_BlockRef_Type6_0x690
	ld	xix, FlashWrite_BlockRef_Type6_0x69A
	call	SeMenu_NameEditor_Setup
	ldb	a, 0
	ld	xiy, FlashWrite_BlockRef_Type6_0x69A
	call	SeMenu_EqEdit_DrawInit_0x15
	stib_da	(0x03efa8), 1
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
	stib_da	(0x03efa8), 0
	ld	xiy, DrumDetailEdit_Entry_02
	ld	xix, DrumDetailEdit_Entry_03
	call	SeMenu_NameEditor_Draw
	jr	37
	stib_da	(0x03efa8), 0
	ld	xiy, DrumDetailEdit_Entry_06
	ld	xix, DrumDetailEdit_Entry_07
	call	SeMenu_NameEditor_Draw
	jr	15
	ld	xiy, FlashWrite_BlockRef_Type6_0x69A
	stib_da	(0x03efa8), 0
	call	SeMenu_EqEdit_DrawInit_0x15
	ret
SeMenu_PresetManager_Load:
	.incbin "includes/generated/v7_transplant_SeMenu_PresetManager_Load.bin"
SeMenu_PresetManager_End:
	ret
SeMenu_PresetManager_Save:
	.incbin "includes/generated/v7_transplant_SeMenu_PresetManager_Save.bin"
SeMenu_PresetManager_SaveApply:
	call	SeMenu_PresetManager_Data_0x1AF
	call	SeMenu_PresetManager_Save
	ld	xiy, SeBitmap_EnvCurve5_0x612
	ld	xix, SeBitmap_EnvCurve5_0x7B6
	call	SeMenu_NameEditor_Setup
	call	SeMenu_ShowConfirmDialog_Data_0xC0
	call	SeMenu_PresetManager_Data_0xEA
	stib_da	(0x03efa8), 0
	ld	xiy, SeBitmap_EnvCurve5_0x1A03
	ld	xix, SeBitmap_EnvCurve5_0x1B06
	call	SeMenu_NameEditor_Draw
	call	SeMenu_PresetManager_Data_0x1C4
	ret
SeMenu_PresetManager_Data:
	.incbin "includes/generated/v7_transplant_SeMenu_PresetManager_Data.bin"
SeMenu_PresetBrowser_Init:
	.incbin "includes/generated/v7_transplant_SeMenu_PresetBrowser_Init.bin"
SeMenu_PresetBrowser_Navigate:
	.incbin "includes/generated/v7_transplant_SeMenu_PresetBrowser_Navigate.bin"
SeMenu_PresetBrowser_Select:
	.incbin "includes/generated/v7_transplant_SeMenu_PresetBrowser_Select.bin"
SeMenu_PresetBrowser_Data:
	.incbin "includes/generated/v7_transplant_SeMenu_PresetBrowser_Data.bin"
SeMenu_CompareAndApply_Init:
	.incbin "includes/generated/v7_transplant_SeMenu_CompareAndApply_Init.bin"
SeMenu_CompareAndApply_Check:
	.incbin "includes/generated/v7_transplant_SeMenu_CompareAndApply_Check.bin"
SeMenu_CompareAndApply_Match:
	.incbin "includes/generated/v7_transplant_SeMenu_CompareAndApply_Match.bin"
SeMenu_CompareAndApply_Apply:
	.incbin "includes/generated/v7_transplant_SeMenu_CompareAndApply_Apply.bin"
SeMenu_CompareAndApply_End:
	call SeMenu_CompareAndApply_Data4
	ret
SeMenu_CompareAndApply_Data:
	.incbin "includes/generated/v7_transplant_SeMenu_CompareAndApply_Data.bin"
SeMenu_CompareAndApply_Data2:
	.incbin "includes/generated/v7_transplant_SeMenu_CompareAndApply_Data2.bin"
SeMenu_CompareAndApply_Data3:
	call SeMenu_NameEditor_Setup
	ret
SeMenu_CompareAndApply_Data4:
	.incbin "includes/generated/v7_transplant_SeMenu_CompareAndApply_Data4.bin"
SeMenu_CompareAndApply_Data5:
	.incbin "includes/generated/v7_transplant_SeMenu_CompareAndApply_Data5.bin"
SeMenu_CompareAndApply_Data6:
	swi	3
	.byte 0xf0
	call	SeMenu_PresetManager_Save
	stib_da	(0x03efa8), 2
	ld	xiy, SeBitmap_EnvCurve5_0x108A
	ld	xix, SeBitmap_EnvCurve5_0x109E
	call	SeMenu_NameEditor_Setup
	stib_da	(0x03efa8), 0
	ld	xiy, SeBitmap_EnvCurve5_0xFB5
	ld	xix, SeBitmap_EnvCurve5_0x108A
	call	SeMenu_NameEditor_Setup
	call	SeMenu_CompareAndApply_Data4
	stdi16	(1734), 56
	stdi16	(1736), 139
	call	SeMenu_ShowConfirmDialog_Data_0x1F6
	stib_da	(0x03efa8), 0
	ld	xiy, SeMenu_CompareScreen_DataTable_0x141
	ld	xix, SeMenu_CompareScreen_DataTable_0x179
	call	SeMenu_NameEditor_Draw
	ret
SeMenu_Utility_CopyBlock:
	.incbin "includes/generated/v7_transplant_SeMenu_Utility_CopyBlock.bin"
SeMenu_Utility_FillBlock:
	call	SeMenu_CompareAndApply_Data
	ld	xiy, SeBitmap_EnvCurve5_0x115B
	ld	xix, SeBitmap_EnvCurve5_0x12A6
	call	SeMenu_NameEditor_Setup
	stib_da	(0x03efa8), 2
	ld	xiy, SeBitmap_EnvCurve5_0x12A6
	ld	xix, SeBitmap_EnvCurve5_0x12BA
	call	SeMenu_NameEditor_Setup
	call	SeMenu_PresetManager_Save
	stdi16	(1734), 56
	stdi16	(1736), 139
	call	SeMenu_ShowConfirmDialog_Data_0x1F6
	call	SeMenu_ShowConfirmDialog_Data_0xC0
	call	SeMenu_ShowConfirmDialog_Data_0x10A
	stib_da	(0x03efa8), 0
	ld	xiy, SeMenu_CompareScreen_DataTable_0x1EB
	ld	xix, SeMenu_CompareScreen_DataTable_0x260
	call	SeMenu_NameEditor_Draw
	call	SeMenu_CompareAndApply_Data4
	ret
SeMenu_Utility_CompareBlock:
	.incbin "includes/generated/v7_transplant_SeMenu_Utility_CompareBlock.bin"
SeMenu_Utility_CompareBlock_Loop:
	.incbin "includes/generated/v7_transplant_SeMenu_Utility_CompareBlock_Loop.bin"
SeMenu_Utility_CompareBlock_End:
	.incbin "includes/generated/v7_transplant_SeMenu_Utility_CompareBlock_End.bin"
SeMenu_Utility_SearchByte:
	.incbin "includes/generated/v7_transplant_SeMenu_Utility_SearchByte.bin"
SeMenu_Utility_SearchByte_End:
	.incbin "includes/generated/v7_transplant_SeMenu_Utility_SearchByte_End.bin"
SeMenu_Utility_FormatNumber:
	.incbin "includes/generated/v7_transplant_SeMenu_Utility_FormatNumber.bin"
SeMenu_Utility_FormatNumber_Loop:
	.incbin "includes/generated/v7_transplant_SeMenu_Utility_FormatNumber_Loop.bin"
SeMenu_Utility_FormatNumber_End:
	.incbin "includes/generated/v7_transplant_SeMenu_Utility_FormatNumber_End.bin"
SeMenu_Utility_FormatNumber_Data:
	.incbin "includes/generated/v7_transplant_SeMenu_Utility_FormatNumber_Data.bin"
SeMenu_Utility_FormatSigned:
	.incbin "includes/generated/v7_transplant_SeMenu_Utility_FormatSigned.bin"
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
	.byte 0x01
	jr	z, 4
	call	SeMenu_Utility_CompareBlock_End
	call	SeMenu_ShowConfirmDialog_Data_0xC0
	call	SeMenu_ShowConfirmDialog_Data_0x10A
	call	SeMenu_Utility_FormatNumber_End
	stib_da	(0x03efa8), 0
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
	.byte 0x01
	jr	z, 4
	call	SeMenu_Utility_CompareBlock_End
	call	SeMenu_ShowConfirmDialog_Data_0xC0
	call	SeMenu_ShowConfirmDialog_Data_0x10A
	call	SeMenu_Utility_FormatNumber_End
	stib_da	(0x03efa8), 0
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
	.byte 0x01
	jr	z, 4
	call	SeMenu_Utility_CompareBlock_End
	call	SeMenu_ShowConfirmDialog_Data_0xC0
	call	SeMenu_ShowConfirmDialog_Data_0x10A
	call	SeMenu_Utility_FormatNumber_End
	stib_da	(0x03efa8), 0
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
	.byte 0x01
	jr	z, 4
	call	SeMenu_Utility_CompareBlock_End
	call	SeMenu_ShowConfirmDialog_Data_0xC0
	call	SeMenu_ShowConfirmDialog_Data_0x10A
	call	SeMenu_Utility_FormatNumber_End
	stib_da	(0x03efa8), 0
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
	.byte 0x01
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
	stib_da	(0x03efa8), 2
	ld	xiy, SeBitmap_EnvCurve5_0x1719
	ld	xix, SeBitmap_EnvCurve5_0x172D
	call	SeMenu_NameEditor_Setup
	call	SeMenu_ShowConfirmDialog_Data_0xC0
	call	SeMenu_ShowConfirmDialog_Data_0x10A
	stib_da	(0x03efa8), 0
	ld	xiy, SeBitmap_EnvCurve5_0x1F00
	ld	xix, SeBitmap_EnvCurve5_0x1F75
	call	SeMenu_NameEditor_Draw
	call	SeMenu_Utility_FormatNumber_Loop
	ret
SeMenu_NameEdit_DataBlock1:
	.incbin "includes/generated/v7_transplant_SeMenu_NameEdit_DataBlock1.bin"
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
	cps	a, 0
	jr z, SeMenu_NameEdit_SetupPath
	cp a, 0x0a
	jr nz, SeMenu_NameEdit_DefaultPath
	call SeMenu_NameEdit_CheckBit7
	jr t, SeMenu_NameEdit_Return
SeMenu_NameEdit_SetupPath:
	.incbin "includes/generated/v7_transplant_SeMenu_NameEdit_SetupPath.bin"
SeMenu_NameEdit_DefaultPath:
	stib_da	(0x03efa8), 0
	ld xiy, EffectParam_Edit_Table
	call SeMenu_EqEdit_DrawInit_0x15
SeMenu_NameEdit_Return:
	ret
SeMenu_NameEdit_CheckBit7:
	.incbin "includes/generated/v7_transplant_SeMenu_NameEdit_CheckBit7.bin"
SeMenu_NameEdit_Bit7Set:
	.incbin "includes/generated/v7_transplant_SeMenu_NameEdit_Bit7Set.bin"
SeMenu_NameEdit_HandleInput:
	call SeMenu_NameEditor_HandleInput
	ret


SeMenu_PatchEdit_DataBlock:
	cps	a, 0
	jr	z, 25
	cps	a, 7
	jr	nc, 37
	xor	xbc, xbc
	ld	xiz, FlashWrite_BlockRef_Type6_0x10
	ldb_d8	c, (1648)
	sla	bc, 2
	.byte 0xe3
	reti
	swi	0
	.byte 0xe4
	ldb	e, 104
	pop_a
	ld	xiy, TuningSystem_Handler_Table_0x242C
	ld	xix, FlashRead_BlockData_Field8
	call	SeMenu_NameEditor_Draw
	jr	15
	ld	xiy, FlashRead_BlockHandler_Table
	stib_da	(0x03efa8), 0
	call	SeMenu_EqEdit_DrawInit_0x15
	ret
SeMenu_PatchEdit_Dispatch:
	.incbin "includes/generated/v7_transplant_SeMenu_PatchEdit_Dispatch.bin"
SeMenu_PatchEdit_SetupPath:
	.incbin "includes/generated/v7_transplant_SeMenu_PatchEdit_SetupPath.bin"
SeMenu_PatchEdit_CallHelper:
	call SeMenu_PresetManager_Data_0xEA
	jr t, SeMenu_PatchEdit_Return
SeMenu_PatchEdit_DefaultPath:
	.incbin "includes/generated/v7_transplant_SeMenu_PatchEdit_DefaultPath.bin"
SeMenu_PatchEdit_Return:
	ret


SeMenu_BankEdit_Dispatch:
	; --- Dispatcher: A==0 path with XIY/XIX setup + loop subroutine (187 bytes) ---
	cps	a, 0
	jr z, SeMenu_BankEdit_SetupPath
	call SeMenu_BankEdit_LoopHelper
	jr t, SeMenu_BankEdit_Return
SeMenu_BankEdit_SetupPath:
	.incbin "includes/generated/v7_transplant_SeMenu_BankEdit_SetupPath.bin"
SeMenu_BankEdit_Return:
	ret
SeMenu_BankEdit_LoopHelper:
	.incbin "includes/generated/v7_transplant_SeMenu_BankEdit_LoopHelper.bin"
SeMenu_BankEdit_LoopBody:
	.incbin "includes/generated/v7_transplant_SeMenu_BankEdit_LoopBody.bin"
SeMenu_BankEdit_EmptyEntry:
	.incbin "includes/generated/v7_transplant_SeMenu_BankEdit_EmptyEntry.bin"
SeMenu_BankEdit_LoopContinue:
	pop xiz
	pop c
	add c, 0x01
	add xiz, 0x00000001
	cps	c, 3
	jr nz, SeMenu_BankEdit_LoopBody
	ret


SeMenu_DrumKit_Dispatch:
	cps	a, 0
	jr	z, 32
	cp	a, 13
	jr	z, 51
	cp	a, 16
	jr	nz, 68
	stib_da	(0x03efa8), 0
	ld	xiy, TuningSys_Param_01_0xAE
	ld	xix, TuningSys_Param_01_0xC4
	call	SeMenu_NameEditor_Draw
	jr	61
	stib_da	(0x03efa8), 1
	ld	xiy, TuningSys_Param_01_0x24A
	ld	xix, TuningSys_Param_01_0x254
	call	SeMenu_NameEditor_Setup
	ldb	a, 0
	jr	22
	stib_da	(0x03efa8), 1
	ld	xiy, TuningSys_Param_01_0x254
	ld	xix, TuningSys_Param_01_0x25E
	call	SeMenu_NameEditor_Setup
	ldb	a, 13
	stib_da	(0x03efa8), 0
	ld	xiy, TuningSys_Param_01_0x25E
	call	SeMenu_EqEdit_DrawInit_0x15
	ret
Data_UnknownBlock:
	.incbin "includes/generated/v7_transplant_Data_UnknownBlock.bin"
SeMenu_PresetInit_Main:
	.incbin "includes/generated/v7_transplant_SeMenu_PresetInit_Main.bin"
SeMenu_PresetInit_Loop1:
	; --- Loop 1: iterate A from 2 to 5, call table lookup (15 bytes) ---
	ldb a, 0x02
SeMenu_PresetInit_Loop1Body:
	push_a
	call SeMenu_PresetInit_TableLookup1
	pop_a
	inc 1, a
	cps	a, 6
	jr c, SeMenu_PresetInit_Loop1Body
	ret
SeMenu_PresetInit_TableLookup1:
	.incbin "includes/generated/v7_transplant_SeMenu_PresetInit_TableLookup1.bin"
SeMenu_PresetInit_Lookup1Return:
	ret
SeMenu_PresetInit_Loop2:
	; --- Loop 2: iterate A from 0x0c to 0x0f, call table lookup (16 bytes) ---
	ldb a, 0x0c
SeMenu_PresetInit_Loop2Body:
	push_a
	call SeMenu_PresetInit_TableLookup2
	pop_a
	inc 1, a
	cp a, 0x10
	jr c, SeMenu_PresetInit_Loop2Body
	ret
SeMenu_PresetInit_TableLookup2:
	.incbin "includes/generated/v7_transplant_SeMenu_PresetInit_TableLookup2.bin"
SeMenu_PresetInit_Lookup2Return:
	ret


SeMenu_FxEdit_Init:
	call	SeMenu_PresetManager_Data_0x1D9
	stib_da	(0x03efa8), 0
	ld	xiy, TuningSystem_Handler_Table_0xCB2
	ld	xix, TuningSystem_Handler_Table_0xD22
	call	SeMenu_NameEditor_Setup
	stib_da	(0x03efa8), 2
	ld	xiy, TuningSystem_Handler_Table_0xCA8
	ld	xix, TuningSystem_Handler_Table_0xCB2
	call	SeMenu_NameEditor_Setup
	stdi16	(1734), 47
	stdi16	(1736), 51
	call	SeMenu_ShowConfirmDialog_Data_0x1F6
	call	SeMenu_ShowConfirmDialog_Data_0xC0
	call	SeMenu_ShowConfirmDialog_Data_0x10A
	stib_da	(0x03efa8), 0
	ld	xiy, TuningSystem_Handler_Table_0x126F
	ld	xix, TuningSystem_Handler_Table_0x12B6
	call	SeMenu_NameEditor_Draw
	ret
SeMenu_FxEdit_DataBlock1:
	call	SeMenu_PresetManager_Data_0x1D9
	stib_da	(0x03efa8), 0
	ld	xiy, TuningSystem_Handler_Table_0xD22
	ld	xix, TuningSystem_Handler_Table_0xDF2
	call	SeMenu_NameEditor_Setup
	stib_da	(0x03efa8), 2
	ld	xiy, TuningSystem_Handler_Table_0xCA8
	ld	xix, TuningSystem_Handler_Table_0xCB2
	call	SeMenu_NameEditor_Setup
	call	SeMenu_ShowConfirmDialog_Data_0xC0
	call	SeMenu_ShowConfirmDialog_Data_0x10A
	stib_da	(0x03efa8), 0
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
	stib_da	(0x03efa8), 2
	ld	xiy, SeBitmap_EnvCurve5_0x108A
	ld	xix, SeBitmap_EnvCurve5_0x109E
	call	SeMenu_NameEditor_Setup
	stib_da	(0x03efa8), 0
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
	stib_da	(0x03efa8), 2
	ld	xiy, SeBitmap_EnvCurve5_0x19EF
	ld	xix, SeBitmap_EnvCurve5_0x1A03
	call	SeMenu_NameEditor_Setup
	call	SeMenu_PresetManager_Save
	stdi16	(1734), 56
	stdi16	(1736), 139
	call	SeMenu_ShowConfirmDialog_Data_0x1F6
	call	SeMenu_ShowConfirmDialog_Data_0xC0
	call	SeMenu_ShowConfirmDialog_Data_0x10A
	stib_da	(0x03efa8), 0
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
	.byte 0xc9
	inc	6, wa
	push	xiy
	cps	a, 1
	jr	z, 31
	cp	a, 11
	jr	c, 74
	stib_da	(0x03efa8), 0
	ld	xiy, TuningSystem_Handler_Table_0x110E
	ld	xix, TuningSystem_Handler_Table_0x114A
	call	SeMenu_NameEditor_Draw
	call	SeMenu_PresetInit_Loop2
	jr	63
	stib_da	(0x03efa8), 0
	ld	xiy, TuningSystem_Handler_Table_0x10A0
	ld	xix, TuningSystem_Handler_Table_0x10DC
	call	SeMenu_NameEditor_Draw
	call	SeMenu_PresetInit_Loop1
	jr	37
	stib_da	(0x03efa8), 1
	ld	xiy, TuningSystem_Handler_Table_0x123D
	ld	xix, TuningSystem_Handler_Table_0x1247
	call	SeMenu_NameEditor_Setup
	ldb	a, 0
	ld	xiy, TuningSystem_Handler_Table_0x117D
	stib_da	(0x03efa8), 0
	call	SeMenu_EqEdit_DrawInit_0x15
	ret
SeMenu_FilterEdit_AltDispatch:
	cps	a, 0
	jr	nz, 22
	stib_da	(0x03efa8), 1
	ld	xiy, TuningSystem_Handler_Table_0x12CA
	ld	xix, TuningSystem_Handler_Table_0x12D4
	call	SeMenu_NameEditor_Setup
	ldb	a, 0
	stib_da	(0x03efa8), 0
	ld	xiy, TuningSystem_Handler_Table_0x12B6
	call	SeMenu_EqEdit_DrawInit_0x15
	ret
SeMenu_FilterEdit_DataBlock3:
	cps	a, 0
	jr	nz, 22
	stib_da	(0x03efa8), 1
	ld	xiy, TuningSystem_Handler_Table_0x12CA
	ld	xix, TuningSystem_Handler_Table_0x12D4
	call	SeMenu_NameEditor_Setup
	ldb	a, 0
	stib_da	(0x03efa8), 0
	ld	xiy, TuningSystem_Handler_Table_0x132F
	call	SeMenu_EqEdit_DrawInit_0x15
	ret
SeMenu_FilterEdit_DataBlock4:
	stib_da	(0x03efa8), 0
	ld	xiy, TuningSystem_Handler_Table_0x139A
	call	SeMenu_EqEdit_DrawInit_0x15
	ret
SeMenu_FilterEdit_DataBlock5:
	call	SeMenu_EqEdit_SetupHelper1
	.byte 0xc1, 0xae, 0x06
	push	xsp
	.byte 0x01
	jr	z, 26
	stib_da	(0x03efa8), 0
	ld	xiy, TuningSystem_Handler_Table_0x13F6
	ld	xix, TuningSystem_Handler_Table_0x14D6
	call	SeMenu_NameEditor_Setup
	call	SeMenu_Utility_CompareBlock_End
	jr	41
	stib_da	(0x03efa8), 0
	ld	xiy, TuningSystem_Handler_Table_0x13F6
	ld	xix, TuningSystem_Handler_Table_0x14A5
	call	SeMenu_NameEditor_Setup
	ld	xiy, TuningSystem_Handler_Table_0x14D6
	ld	xix, TuningSystem_Handler_Table_0x14F5
	call	SeMenu_NameEditor_Setup
	ld	xiy, TuningSystem_Handler_Table_0x15B0
	jr	5
	ld	xiy, TuningSystem_Handler_Table_0x1592
	stib_da	(0x03efa8), 0
	ld	xix, TuningSystem_Handler_Table_0x161F
	call	SeMenu_NameEditor_Draw
	call	SeMenu_EqEdit_SetupHelper2
	ret
SeMenu_EqEdit_Init:
	.incbin "includes/generated/v7_transplant_SeMenu_EqEdit_Init.bin"
SeMenu_EqEdit_SetupHelper1:
	.incbin "includes/generated/v7_transplant_SeMenu_EqEdit_SetupHelper1.bin"
SeMenu_EqEdit_SetupHelper2:
	.incbin "includes/generated/v7_transplant_SeMenu_EqEdit_SetupHelper2.bin"
SeMenu_EqEdit_Dispatch:
	.incbin "includes/generated/v7_transplant_SeMenu_EqEdit_Dispatch.bin"
SeMenu_EqEdit_DrawTable:
	.incbin "includes/generated/v7_transplant_SeMenu_EqEdit_DrawTable.bin"
SeMenu_EqEdit_SetupPath:
	.incbin "includes/generated/v7_transplant_SeMenu_EqEdit_SetupPath.bin"
SeMenu_EqEdit_SetConstA:
	ldb a, 0x07
SeMenu_EqEdit_DefaultPath:
	.incbin "includes/generated/v7_transplant_SeMenu_EqEdit_DefaultPath.bin"
SeMenu_EqEdit_Return:
	ret


SeMenu_EqEdit_DrawInit:
	stib_da	(0x03efa8), 0
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
	ldio	16, 40
	rcf
	ldio	16, 8
	rcf
	pushw	wa
	push_a
	nop
	nop
	.ascii "*U T*"
	.byte 0x01
	pushw	de
	.byte 0x54
	ldio	16, 42
	.byte 0x54
	ldio	16, 8
	rcf
	ldio	4, 42
	.byte 0x55
	ldb	b, 1
	push	sr
	.byte 0x04
	ldio	16, 42
	.byte 0x55
	nop
	nop
	.ascii "*U\"A\"A\"A"
	push	sr
	.byte 0x01
	push	sr
	pop_a
	pushw	de
	ld	xbc, 0x152a4122
	pushw	de
	.byte 0x55
	ldb	b, 1
	ldwio	4, 0x4102
	pushw	de
	push_a
	nop
	nop
	pushw	de
	.ascii "U @ @ @"
	push	sr
	.byte 0x01
	push	sr
	pop_a
	pushw	de
	ld	xbc, 0x152a4122
	.byte 0x04
	ldwio	20, 5130
	ldb	b, 85
	pushw	de
	.byte 0x04
	push	sr
	rcf
	ldio	84, 42
	rcf
	ldio	16, 8
	push_a
	ldio	64, 32
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
	ldio	8, 8
	ldio	16, 16
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
	ldio	16, 32
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
	ldb	w, 192
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
	.byte 0x7f
	swi	7
	.zero 8
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x01
	pop	sr
	ei	12
	ldio	24, 48
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
	.byte 0x01
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
	.byte 0x7f
	swi	7
	.zero 24
	nop
	nop
	nop
	nop
	.byte 0x01
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
	.byte 0x01
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
	.byte 0x01
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
	ldb	c, 35
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
	ldio	16, 96
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
	ldio	16, 32
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
	ldb	c, 35
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
	ldb	c, 35
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
	ldb	w, 87
	.byte 0x52
	popw	bc
	.byte 0x54
	ld	xiy, 0x0bdf0506
	scf
	ei	5
	ldio	12, 16
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
	ldwio	127, 0x461e
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
	ldwio	14, 8448
	nop
	push	xde
	nop
	ldw	wa, 8704
	ldwio	174, 0x3e00
	nop
	ldw	ix, 0x6301
	nop
	.byte 0x01
	ldwio	15, 0x4100
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
	ldwio	15, 0x4100
	nop
	retd	0xd900
	nop
	push	sr
	ldwio	49, 0x6501
	nop
	ldw	bc, 0xd901
	nop
	ldb	c, 5
	rcf
	.byte 0x82
	nop
	ldb	c, 5
	jr	lt, -109
	pushw	1315
	jr	ule, -125
	scf
	ldb	c, 5
	reti
	jrl	ule, 8983
	halt
	ldb	a, 179
	call	0x620523
	.byte 0xea
	ldwio	35, 0x6405
	.byte 0xa2
	scf
	ldb	c, 5
	ldwio	146, 8983
	halt
	pop	xsp
	ordm16_24	(0x0a1b1d), ix
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
	ldb	a, 0
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
	ldb	a, 0
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
	ldio	16, 224
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
	ldb	w, 7
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
	xordm16_24	(0xf113), bc
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
	ldwio	0, 3075
	ldb	d, 12
	.byte 0xf1
	nop
	pop	xbc
	scf
	pop	sr
	nop
	ldwio	0, 3075
	ld	xde, 0x4900f10c
	ldf	3
	nop
	ldwio	0, 3075
	jr	f, 12
	.byte 0xf1
	nop
	scf
	call	0x0a0003
	nop
	stdi8	(0xf113), 241
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
	ldb	a, 20
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
	ldb	w, 0
	pushw	bc
	nop
	pushw	iy
	nop
	jp	1546
	.byte 0x1f
	nop
	di
	pushw	iz
	nop
	halt
	ldwio	8, 8448
	nop
	pushw	wa
	nop
	pushw	ix
	nop
	jp	2058
	ldb	a, 0
	pushw	wa
	nop
	pushw	ix
	nop
	jp	2058
	popw	bc
	nop
	ldb	b, 0
	.byte 0xc5
	nop
	pop	sr
	pushw	1629
	retd	1280
	.byte 0x89
	push_a
	stdi8	(2048), 73
	nop
	ldb	b, 0
	.byte 0x56
	nop
	ldio	0, 73
	nop
	ldb	b, 0
	.byte 0x56
	nop
	ldio	0, 110
	nop
	ldb	b, 0
	jrl	ugt, 2048
	nop
	.byte 0x93
	nop
	ldb	b, 0
	.byte 0xa0
	nop
	ldio	0, 184
	nop
	ldb	b, 0
	.byte 0xc5
	nop
	.ascii "NORM 1/2 1/4 1/81/161/321/64 FIXOFF ONOFFON "
	.byte 0x1c
	rcf
	jrl	ule, 1280
	nop
	.ascii "T0NE LAYER"
	ldf	16
	di
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
	ldb	d, 18
	reti
	halt
	.byte 0x51
	ldb	d, 18
	reti
	halt
	.byte 0x56
	ldb	d, 18
	reti
	halt
	pop	xhl
	ldb	d, 18
	push	10
	.byte 0x04
	nop
	.byte 0x04
	nop
	ld	xix, 0x09001000
	ldwio	4, 0x4201
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
	ldwio	69, 0xdb00
	nop
	swi	3
	nop
	.byte 0xdb
	nop
	push	sr
	ldwio	156, 0xcc00
	nop
	.byte 0x9c
	nop
	.byte 0xe9
	nop
	halt
	ldwio	70, 0xdc00
	nop
	.long NakaInst_LEFT_0x04
	ldb	c, 5
	jr	ov, -125
	nop
	.byte 0x1c
	scf
	jrl	le, 1280
	nop
	.byte 0x54
	.ascii "0NE SELECT"
	ldf	16
	di
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
	ldwio	88, 0xd100
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
	ldb	b, 141
	ei	5
	.byte 0x1c
	ldb	b, 141
	ei	5
	pushw	hl
	ldb	b, 141
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
	ldb	c, 142
	ei	5
	.byte 0xc0
	ldb	c, 142
	ei	5
	.byte 0xc5
	ldb	c, 142
	ldb	b, 10
	pushw	0x3600
	nop
	ldw	iy, 0xc701
	nop
	ldb	b, 10
	push	0
	.byte 0xda
	nop
	calr	60928
	nop
	ldb	b, 10
	ldw	bc, 0xda00
	nop
	ld	xiz, 0x2200ee00
	ldwio	89, 0xda00
	nop
	jr	nz, 0
	.byte 0xee
	nop
	ldb	b, 10
	.byte 0xd1
	nop
	.byte 0xda
	nop
	.byte 0xe6
	nop
	.byte 0xee
	nop
	ldb	b, 10
	swi	1
	nop
	.byte 0xda
	nop
	ret
	.byte 0x01, 0xee
	nop
	ldb	b, 10
	ldb	a, 1
	.byte 0xda
	nop
	ldw	iz, 0xee01
	nop
	.byte 0x01
	ldwio	11, 0x4700
	nop
	ldw	iy, 0x4701
	nop
	.byte 0x01
	ldwio	11, 0x6700
	nop
	ldw	iy, 0x6701
	nop
	.byte 0x01
	ldwio	11, 0x8700
	nop
	ldw	iy, 0x8701
	nop
	.byte 0x01
	ldwio	11, 0xa700
	nop
	ldw	iy, 0xa701
	nop
	.byte 0x01
	ldwio	9, 0xe400
	nop
	calr	58368
	nop
	.byte 0x01
	ldwio	49, 0xe400
	nop
	ld	xiz, 0x0100e400
	ldwio	89, 0xe400
	nop
	jr	nz, 0
	.byte 0xe4
	nop
	.byte 0x01
	ldwio	209, 0xe400
	nop
	.byte 0xe6
	nop
	.byte 0xe4
	nop
	.byte 0x01
	ldwio	249, 0xe400
	nop
	ret
	.byte 0x01, 0xe4
	nop
	.byte 0x01
	ldwio	33, 0xe401
	nop
	ldw	iz, 0xe401
	nop
	push	sr
	ldwio	60, 0x3600
	nop
	push	xix
	nop
	.byte 0xc7
	nop
	push	sr
	ldwio	188, 0x3600
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
	ldb	w, 7
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
	ldwio	0, 3075
	ldb	d, 12
	.byte 0xf1
	nop
	pop	xde
	scf
	pop	sr
	nop
	ldwio	0, 3075
	ld	xde, 0x5a00f10c
	ex_ff
	pop	sr
	nop
	ldwio	0, 3075
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
	ldb	w, 7
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
	ldb	w, 7
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
	ldb	w, 7
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
	ldb	w, 7
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
	ldb	l, 24
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
	ldwio	0, 3075
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
	ldb	d, 12
	.byte 0xf1
	nop
	.byte 0xd4
	scf
	pop	sr
	nop
	ldwio	0, 3075
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
	ldwio	0, 3075
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
	ldwio	20, 9473
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
	ldwio	32, 0x3d01
	nop
	ldb	l, 1
	push	xiy
	nop
	.byte 0x01
	ldwio	33, 0x3e01
	nop
	ldb	h, 1
	push	xiz
	nop
	.byte 0x01
	ldwio	34, 0x3f01
	nop
	ldb	e, 1
	push	xsp
	nop
	.byte 0x01
	ldwio	34, 0x6001
	nop
	ldb	e, 1
	jr	f, 0
	.byte 0x01
	ldwio	33, 0x6101
	nop
	ldb	h, 1
	jr	lt, 0
	.byte 0x01
	ldwio	32, 0x6201
	nop
	ldb	l, 1
	jr	le, 0
	push	10
	ldb	c, 1
	ldw	iz, 9216
	.byte 0x01
	ld	xbc, 0x230a0900
	.byte 0x01
	pop	xiz
	nop
	ldb	d, 1
	jr	ge, 0
	ldb	c, 5
	reti
	.byte 0x86
	nop
	halt
	ldwio	22, 9985
	nop
	ldw	de, 0x3401
	nop
	halt
	ldwio	14, 0x4301
	nop
	ldw	de, 0x5c01
	nop
	halt
	ldwio	22, 0x6b01
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
	ldb	b, 141
	ei	5
	.byte 0x1c
	ldb	b, 141
	ei	5
	ldb	a, 34
	.byte 0x8d
	ei	5
	pushw	hl
	ldb	b, 141
	ei	5
	ld	xhl, (xsp)
	.byte 0x8e
	ei	5
	add	(xix+35), xiz
	ei	5
	.byte 0xb1
	ldb	c, 142
	ei	5
	.byte 0xbb
	ldb	c, 142
	ldb	b, 10
	pushw	0x3300
	nop
	.byte 0xa8
	nop
	.byte 0xca
	nop
	ldb	b, 10
	ld	(xhl), 51
	nop
	swi	3
	nop
	.byte 0x52
	nop
	ldb	b, 10
	ld	(xhl), 91
	nop
	swi	3
	nop
	jrl	gt, 8704
	ldwio	179, 0x8300
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
	ldb	b, 10
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
	ldb	b, 10
	ldw	bc, 0xda00
	nop
	ld	xiz, 0x2200ee00
	ldwio	89, 0xda00
	nop
	jr	nz, 0
	.byte 0xee
	nop
	ldb	b, 10
	.byte 0x81
	nop
	.byte 0xda
	nop
	.long NakaInst_Param_Val7F
	ldb	b, 10
	.byte 0xd1
	nop
	.long NakaData_DescriptorPad_ZeroC
	.byte 0xee
	nop
	.byte 0x01
	ldwio	179, 0x4100
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
	ldwio	179, 0x6900
	nop
	swi	3
	nop
	jr	ge, 0
	.byte 0x01
	ldwio	11, 0x6a00
	nop
	.byte 0xa8
	nop
	jr	gt, 0
	.byte 0x01
	ldwio	11, 0x8a00
	nop
	.byte 0xa8
	nop
	.byte 0x8a
	nop
	.byte 0x01
	ldwio	179, 0x9100
	nop
	swi	3
	nop
	.byte 0x91
	nop
	.byte 0x01
	ldwio	11, 0xaa00
	nop
	.byte 0xa8
	nop
	.byte 0xaa
	nop
	.byte 0x01
	ldwio	179, 0xb900
	nop
	swi	3
	nop
	.byte 0xb9
	nop
	.byte 0x01, 0x0a
	.long Pad_NakaExternal_Block2
	.long Pad_NakaExternal_Block3
	.byte 0x01
	ldwio	89, 0xe400
	nop
	jr	nz, 0
	.byte 0xe4
	nop
	.byte 0x01
	ldwio	129, 0xe400
	nop
	.long NakaData_ExternalPadBlock_A
	.byte 0x01, 0x0a, 0xd1
	nop
	.long NakaData_DescriptorZero_PadA
	.byte 0xe4
	nop
	push	sr
	ldwio	44, 0x3300
	nop
	pushw	ix
	nop
	.byte 0xca
	nop
	halt
	ldwio	6, 0x4301
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
	ldwio	146, 0xb200
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
	ldwio	213, 0xae00
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
	di
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
	ldwio	20, 9473
	nop
	ldw	ix, 0x3601
	nop
	push	10
	push_a
	.byte 0x01
	ld	xbc, 0x5e013400
	nop
	.byte 0x01
	ldwio	32, 0x3d01
	nop
	ldb	l, 1
	push	xiy
	nop
	.byte 0x01
	ldwio	33, 0x3e01
	nop
	ldb	h, 1
	push	xiz
	nop
	.byte 0x01
	ldwio	34, 0x3f01
	nop
	ldb	e, 1
	push	xsp
	nop
	push	10
	ldb	c, 1
	ldw	iz, 9216
	.byte 0x01
	ld	xbc, 0x2b090600
	scf
	.ascii "LF0 "
	scf
	.byte 0x01
	ldwio	34, 0x6001
	nop
	ldb	e, 1
	jr	f, 0
	.byte 0x01
	ldwio	33, 0x6101
	nop
	ldb	h, 1
	jr	lt, 0
	.byte 0x01
	ldwio	32, 0x6201
	nop
	ldb	l, 1
	jr	le, 0
	push	10
	ldb	c, 1
	pop	xiz
	nop
	ldb	d, 1
	jr	ge, 0
	push	10
	push_a
	.byte 0x01
	jr	ge, 0
	ldw	ix, 0x7a01
	nop
	ldb	c, 5
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
	ldwio	214, 0x5a00
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
	ldb	b, 10
	.byte 0xe0
	nop
	jr	z, 0
	ei	1
	.byte 0x8c
	nop
	.byte 0x01
	ldwio	214, 0x7a00
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
	ldwio	224, 0x8600
	nop
	ei	1
	.byte 0xac
	nop
	.byte 0x01
	ldwio	214, 0x9a00
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
	ldwio	224, 0xa600
	nop
	ei	1
	.byte 0xcc
	nop
	.byte 0x01
	ldwio	214, 0xba00
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
	ldwio	158, 0x5a00
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
	ldb	b, 10
	.byte 0xa8
	nop
	jr	z, 0
	.byte 0xce
	nop
	.byte 0x8c
	nop
	.byte 0x01
	ldwio	158, 0x7a00
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
	ldb	a, 34
	.byte 0x8d
	ei	5
	ldb	h, 34
	.byte 0x8d
	ei	5
	add	(xhl+35), xiz
	ei	5
	.byte 0xb1
	ldb	c, 142
	ei	5
	.byte 0xb6
	ldb	c, 142
	ldb	b, 10
	pushw	0x3500
	nop
	.byte 0xd4
	nop
	.byte 0xca
	nop
	ldb	b, 10
	.byte 0x51
	nop
	.byte 0xda
	nop
	jr	z, 0
	.byte 0xee
	nop
	ldb	b, 10
	.byte 0x81
	nop
	.byte 0xda
	nop
	.byte 0x96
	nop
	.byte 0xee
	nop
	ldb	b, 10
	.byte 0xa9
	nop
	.byte 0xda
	nop
	.byte 0xbe
	nop
	.byte 0xee
	nop
	.byte 0x01
	ldwio	11, 0x4a00
	nop
	.byte 0xd4
	nop
	popw	de
	nop
	.byte 0x01
	ldwio	11, 0x6a00
	nop
	.byte 0xd4
	nop
	jr	gt, 0
	.byte 0x01
	ldwio	11, 0x8a00
	nop
	.byte 0xd4
	nop
	.byte 0x8a
	nop
	.byte 0x01
	ldwio	11, 0xaa00
	nop
	.byte 0xd4
	nop
	.byte 0xaa
	nop
	.byte 0x01
	ldwio	81, 0xe400
	nop
	.long NakaData_ExternalBase_0x66
	.byte 0x01
	ldwio	129, 0xe400
	nop
	.byte 0x96
	nop
	.byte 0xe4
	nop
	.byte 0x01, 0x0a
	.long NakaData_ExternalPadBlock_B
	.long Pad_BeforeNakaData_UserMemoryConfig
	push	sr
	ldwio	46, 0x3500
	nop
	pushw	iz
	nop
	.byte 0xca
	nop
	halt
	ldwio	22, 0x4301
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
	ldb	d, 18
	reti
	halt
	.byte 0x51
	ldb	d, 18
	reti
	halt
	.byte 0x56
	ldb	d, 18
	reti
	halt
	pop	xhl
	ldb	d, 18
	ldb	b, 10
	pushw	sp
	nop
	popw	wa
	nop
	swi	7
	nop
	jrl	gt, 256
	ldwio	82, 0xdb00
	nop
	.byte 0xeb
	nop
	.byte 0xdb
	nop
	push	sr
	ldwio	119, 0xcd00
	nop
	.long Bitmap_TechnichordBackground_1
	halt
	ldwio	22, 0x4301
	nop
	ldw	de, 0x5c01
	nop
	halt
	ldwio	83, 0xdc00
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
	ldwio	47, 0x6100
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
	ldwio	50, 0x3a00
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
	ldb	d, 18
	reti
	halt
	.byte 0x1f
	ldb	d, 18
	reti
	halt
	ldb	d, 36
	ccf
	reti
	halt
	pushw	bc
	ldb	d, 18
	reti
	halt
	pushw	iz
	ldb	d, 18
	reti
	halt
	ldw	hl, 4644
	reti
	halt
	push	xbc
	ldb	d, 18
	push	10
	pop	sr
	nop
	.byte 0xcb
	nop
	.long NakaInst_2d_d
	.byte 0x01
	ldwio	3, 0xd900
	nop
	call	0xd901
	halt
	ldwio	4, 0xda00
	nop
	.byte 0x1c, 0x01, 0xe7
	nop
	halt
	ldwio	22, 9985
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
	ldb	e, 0
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
	ldb	a, 95
	reti
	halt
	.byte 0xb0
	ldb	a, 95
	ei	5
	swi	3
	ldb	a, 95
	ei	5
	swi	7
	ldb	a, 95
	reti
	halt
	ld	xde, 0x05071224
	ld	xsp, 0x05071224
	popw	ix
	ldb	d, 18
	reti
	halt
	.byte 0x51
	ldb	d, 18
	reti
	halt
	.byte 0x56
	ldb	d, 18
	reti
	halt
	pop	xhl
	ldb	d, 18
	reti
	halt
	jr	f, 36
	ccf
	reti
	halt
	jr	z, 36
	ccf
	ldb	b, 10
	pushw	sp
	nop
	popw	wa
	nop
	swi	7
	nop
	jrl	gt, 2304
	ldwio	237, 0xcd00
	nop
	push	xiy
	.byte 0x01, 0xe9
	nop
	.byte 0x01
	ldwio	3, 0xda00
	nop
	.byte 0xe6
	nop
	.byte 0xda
	nop
	.byte 0x01
	ldwio	237, 0xda00
	nop
	push	xiy
	.byte 0x01, 0xda
	nop
	push	sr
	ldwio	117, 0xcd00
	nop
	jrl	mi, -5888
	nop
	halt
	ldwio	22, 9985
	nop
	ldw	de, 0x3401
	nop
	halt
	ldwio	4, 0xdb00
	nop
	.byte 0xe5
	nop
	.byte 0xe8
	nop
	halt
	ldwio	238, 0xdb00
	nop
	push	xix
	.byte 0x01, 0xe8
	nop
	.byte 0x01
	ldwio	47, 0x6100
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
	di
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
	ldwio	70, 0x4c49
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
	ldwio	20, 9473
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
	ldwio	32, 0x3d01
	nop
	ldb	l, 1
	push	xiy
	nop
	.byte 0x01
	ldwio	33, 0x3e01
	nop
	ldb	h, 1
	push	xiz
	nop
	.byte 0x01
	ldwio	34, 0x3f01
	nop
	ldb	e, 1
	push	xsp
	nop
	.byte 0x01
	ldwio	34, 0x6001
	nop
	ldb	e, 1
	jr	f, 0
	.byte 0x01
	ldwio	33, 0x6101
	nop
	ldb	h, 1
	jr	lt, 0
	.byte 0x01
	ldwio	32, 0x6201
	nop
	ldb	l, 1
	jr	le, 0
	push	10
	ldb	c, 1
	ldw	iz, 9216
	.byte 0x01
	ld	xbc, 0x230a0900
	.byte 0x01
	pop	xiz
	nop
	ldb	d, 1
	jr	ge, 0
	ldb	c, 5
	ldb	a, 134
	nop
	halt
	ldwio	22, 9985
	nop
	ldw	de, 0x3401
	nop
	halt
	ldwio	14, 0x4301
	nop
	ldw	de, 0x5c01
	nop
	halt
	ldwio	22, 0x6b01
	nop
	ldw	de, 0x7801
	nop
	.byte 0x06
	ldio	136, 21
	popw	iy
	ldw	wa, 0x4544
	ei	6
	ret
	push_f
	ldb	w, 17
	halt
	ldwio	252, 0x9500
	nop
	ldw	ix, 0xa601
	nop
	halt
	ldwio	14, 0x4301
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
	ldwio	221, 0xb000
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
	di
	.byte 0xd1
	nop
	.ascii "CUTOFF"
	.byte 0x17
	ldwio	52, 0xd100
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
	ldwio	244, 0xd100
	nop
	ld	xiz, 0x17514552
	ldwio	24, 0xd101
	nop
	ld	xsp, 0x064e4941
	halt
	.byte 0x8c
	ldb	b, 75
	ei	5
	.byte 0xa9
	ldb	b, 75
	ei	6
	ld	de, (xbc)
	jr	ov, 66
	ei	6
	.byte 0xad
	ldb	b, 100
	ld	xde, 0x24420507
	ccf
	reti
	halt
	ld	xsp, 0x05071224
	popw	ix
	ldb	d, 18
	reti
	halt
	.byte 0x51
	ldb	d, 18
	reti
	halt
	pop	xhl
	ldb	d, 18
	reti
	halt
	jr	f, 36
	ccf
	reti
	halt
	jr	mi, 36
	ccf
	ldb	b, 10
	ld	xde, 0xe9002700
	nop
	pop	xiz
	nop
	ldb	b, 10
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
	ldwio	146, 0x7100
	nop
	.byte 0x99
	nop
	jrl	lt, 256
	ldwio	147, 0x7200
	nop
	.byte 0x98
	nop
	jrl	le, 256
	ldwio	148, 0x7300
	nop
	.byte 0x97
	nop
	jrl	ule, 256
	ldwio	2, 0xdb00
	nop
	.byte 0xa0
	nop
	.byte 0xdb
	nop
	.byte 0x01
	ldwio	187, 0xdb00
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
	ldwio	3, 0xdc00
	nop
	.byte 0x9f
	nop
	.byte 0xe8
	nop
	halt
	ldwio	188, 0xdc00
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
	ldwio	132, 0xd100
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
	incm	4, (xhl+34)
	ld	xde, 0x244c0507
	ccf
	reti
	halt
	.byte 0x51
	ldb	d, 18
	reti
	halt
	.byte 0x56
	ldb	d, 18
	reti
	halt
	pop	xhl
	ldb	d, 18
	ldb	b, 10
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
	ldwio	77, 0xdb00
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
	ldio	63, 30
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
	ldwio	172, 0xd100
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
	ldb	b, 75
	ei	6
	ld	de, (xix)
	jr	ov, 66
	ei	5
	.byte 0x9b
	ldb	b, 75
	ei	6
	ld	xde, (xwa)
	jr	ov, 66
	reti
	halt
	ld	xiz, 0x05071224
	popw	hl
	ldb	d, 18
	reti
	halt
	.byte 0x51
	ldb	d, 18
	reti
	halt
	.byte 0x56
	ldb	d, 18
	reti
	halt
	pop	xhl
	ldb	d, 18
	reti
	halt
	jr	f, 36
	ccf
	ldb	b, 10
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
	ldwio	29, 0xdb00
	nop
	jrl	mi, -9472
	nop
	.byte 0x01
	ldwio	122, 0xdb00
	nop
	push_f
	.byte 0x01, 0xdb
	nop
	halt
	ldwio	30, 0xdc00
	nop
	jrl	ov, -6144
	nop
	halt
	ldwio	123, 0xdc00
	nop
	.byte 0x17, 0x01, 0xe8
	nop
	.byte 0x1c
	decf
	jrl	f, 24576
	nop
	.byte 0x54
	.ascii "HROUGH\""
	ldwio	66, 0x4c00
	nop
	.byte 0xe9
	nop
	.byte 0x83
	nop
	scf
	ldwio	50, 0x6600
	nop
	.byte 0x01, 0x01
	jr	z, 0
	ccf
	ldwio	213, 0x3a00
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
	ldb	w, 23
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
	ldb	h, 30
	.byte 0x8e
	ldb	w, 23
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
	ldb	d, 18
	reti
	halt
	ldb	d, 36
	ccf
	reti
	halt
	pushw	bc
	ldb	d, 18
	reti
	halt
	pushw	iz
	ldb	d, 18
	reti
	halt
	ldw	hl, 4644
	reti
	halt
	push	xbc
	ldb	d, 18
	ldb	b, 10
	ldw	de, 0x3a00
	nop
	.byte 0x01, 0x01, 0x91
	nop
	push	10
	ldb	h, 1
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
	ldb	h, 1
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
	ldwio	60, 0xbc00
	nop
	call	0xbc01
	push	sr
	ldwio	138, 0xae00
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
	ldwio	3, 0xd900
	nop
	call	0xd901
	halt
	ldwio	22, 9985
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
	ldwio	142, 0xb200
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
	ldwio	202, 0xae00
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
	ldb	d, 18
	reti
	halt
	.byte 0x51
	ldb	d, 18
	reti
	halt
	.byte 0x56
	ldb	d, 18
	reti
	halt
	jr	f, 36
	ccf
	reti
	halt
	jr	z, 36
	ccf
	ldb	b, 10
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
	ldwio	30, 0xda00
	nop
	.byte 0xce
	nop
	.byte 0xda
	nop
	.byte 0x01
	ldwio	228, 0xda00
	nop
	push	xiy
	.byte 0x01, 0xda
	nop
	push	sr
	ldwio	158, 0xcd00
	nop
	.byte 0x9e
	nop
	.byte 0xe9
	nop
	halt
	ldwio	31, 0xdb00
	nop
	.byte 0xcd
	nop
	.byte 0xe8
	nop
	halt
	ldwio	229, 0xdb00
	nop
	.long AlignedStr_ON
	halt
	ldwio	22, 9985
	nop
	ldw	de, 0x3401
	nop
	.byte 0x01
	ldwio	47, 0x6100
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
	stdi8	(256), 216
	incf
	push	sr
	retd	0
	nop
	nop
	ldb	w, 243
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
	stdi8	(256), 216
	scf
	push	sr
	retd	0
	nop
	nop
	ldb	w, 3
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
	stdi8	(256), 216
	ex_ff
	push	sr
	retd	0
	nop
	nop
	ldb	w, 19
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
	stdi8	(256), 216
	jp	3842
	nop
	nop
	nop
	ldb	w, 35
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
	ldb	w, 238
	incf
	push	sr
	nop
	halt
	pushw	1636
	swi	7
	nop
	ldb	w, 242
	incf
	push	sr
	nop
	nop
	ldwio	101, 0x7f06
	nop
	ldb	w, 233
	scf
	pop	sr
	halt
	pushw	1638
	swi	7
	nop
	ldb	w, 238
	scf
	push	sr
	nop
	halt
	pushw	1639
	swi	7
	nop
	ldb	w, 242
	scf
	push	sr
	nop
	nop
	ldwio	104, 0x7f06
	nop
	ldb	w, 233
	ex_ff
	pop	sr
	halt
	pushw	1641
	swi	7
	nop
	ldb	w, 238
	ex_ff
	push	sr
	nop
	halt
	pushw	1642
	swi	7
	nop
	ldb	w, 242
	ex_ff
	push	sr
	nop
	nop
	ldwio	107, 0x7f06
	nop
	ldb	w, 233
	jp	0x0b0503
	jr	nov, 6
	swi	7
	nop
	ldb	w, 238
	jp	0x050002
	pushw	1645
	swi	7
	nop
	ldb	w, 242
	jp	0x030002
	pushw	1629
	retd	1280
	.byte 0x53
	pushw	hl
	stb_d8	(0x4100), b
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
	ldb	w, 66
	pushw	iy
	stdi8	(1536), 8
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
	ldb	w, 162
	ldb	b, 1
	pop	sr
	nop
	ldwio	97, 0x3f06
	nop
	ldb	w, 158
	ldb	b, 2
	push	sr
	retd	1634
	jrl	nc, 8192
	.byte 0xf2
	push	xix
	stdi8	(1280), 146
	ldb	b, 2
	retd	1635
	reti
	nop
	ldb	w, 230
	pushw	iy
	stdi8	(768), 152
	ldb	b, 34
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
	ldb	w, 167
	ldb	b, 1
	pop	sr
	nop
	ldwio	97, 0x3f06
	nop
	ldb	w, 163
	ldb	b, 2
	push	sr
	retd	1634
	jrl	nc, 8192
	.byte 0xf2
	push	xix
	stdi8	(1280), 140
	ldb	b, 2
	retd	1635
	reti
	nop
	ldb	w, 218
	pushw	iy
	stdi8	(512), 146
	ldb	b, 2
	retd	1636
	jrl	nc, 8192
	.byte 0xf2
	push	xix
	stdi8	(1280), 152
	ldb	b, 2
	retd	1637
	reti
	nop
	ldb	w, 218
	pushw	iy
	stdi8	(512), 158
	ldb	b, 101
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
	ldb	w, 226
	call	0x050002
	pushw	1642
	swi	7
	nop
	ldb	w, 236
	call	0x050002
	pushw	1633
	swi	7
	nop
	ldb	w, 247
	call	2
	ldwio	99, 0xff06
	nop
	ldb	w, 97
	ldb	b, 3
	halt
	pushw	1636
	swi	7
	nop
	ldb	w, 101
	ldb	b, 2
	nop
	nop
	ldwio	101, 0x7f06
	nop
	ldb	w, 106
	ldb	b, 3
	halt
	pushw	1638
	swi	7
	nop
	ldb	w, 111
	ldb	b, 2
	nop
	nop
	ldwio	103, 0x7f06
	nop
	ldb	w, 116
	ldb	b, 3
	halt
	pushw	1640
	swi	7
	nop
	ldb	w, 121
	ldb	b, 2
	nop
	nop
	ldwio	105, 0x7f06
	nop
	ldb	w, 127
	ldb	b, 3
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
	ldwio	100, 7942
	nop
	ldb	w, 152
	ldb	b, 3
	nop
	ldwio	98, 0x7f06
	nop
	ldb	w, 157
	ldb	b, 3
	nop
	ldwio	97, 0x7f06
	nop
	ldb	w, 161
	ldb	b, 3
	nop
	ldwio	99, 0x3f06
	nop
	ldb	w, 166
	ldb	b, 2
	push	sr
	retd	0x0663
	.byte 0x80, 0x07
	ldb	w, 209
	push_a
	stdi8	(768), 171
	ldb	b, 3
	pushw 1632
	reti
	nop
	halt
	ld	xde, 0x0200f135
	retd	0x0665
	rcf
	max
	ldb	w, 16
	ldw	iy, 241
	normal
	nop
	ldw	de, 522
	retd	0x0666
	rcf
	max
	ldb	w, 16
	ldw	iy, 241
	normal
	nop
	ldwio	15, 3842
	jr	c, 6
	rcf
	max
	ldb	w, 16
	ldw	iy, 241
	normal
	nop
	.byte 0xe2, 0x13, 0x02, 0x0f, 0x68
	ei	0x10
	max
	ldb	w, 16
	ldw	iy, 241
	normal
	nop
	.byte 0xba, 0x18, 0x2b
	pushw	iy
	.byte 0xc9, 0x34, 0xf1
	nop
	.byte 0xa6, 0x34
	lda_d16	xix, (0x9c00)
	lda_d16	xix, (0xb000)
	lda_d16	xix, (0x8300)
	lda_d16	xix, (0xd400)
	lda_d16	xix, (0xe300)
	lda_d16	xix, (0xf200)
	lda_d16	xiy, (256)
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
	ldb	w, 6
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
	jrl	po, 16747793
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
	ldb	b, 60
	ei	5
	ldw	iy, 0x3e22
	ei	5
	swi	0
	ldb	b, 142
	ldwio	10, 277
	call16	0x3200
	normal
	ldw	ix, 2560
	ldwio	21, 0x4201
	nop
	ldw	de, 0x5a01
	nop
	zcf
	ldwio	15, 0x6200
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
	ldwio	10, 285
	.byte 0xd2, 0x00, 0x3a, 0x01, 0xea
	nop
	normal
	ldwio	245, 0xde00
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
	ldb	w, 0
	ldw	wa, 0x4000
	nop
	.byte 0x50
	nop
	jr	f, 0
	jrl	f, 16744448
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
	jrl	z, 16745728
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
	ldb	w, 68
	.byte 0x88, 0xb0, 0x44, 0xb0, 0x20
	ld	xiy, 0xb045b088
	ldb	w, 70
	.byte 0xb0, 0x20
	ld	xiz, 0xb047b08c
	ldb	w, 65
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
	ldb	l, 0
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
	ldb	b, 10
	normal
	normal
	.byte 0xda, 0x00
	ex_ff
	normal
	.byte 0xee, 0x00
	normal
	ldwio	11, 0x4a00
	nop
	.byte 0xe6
	nop
	popw	de
	nop
	normal
	ldwio	11, 0x6a00
	nop
	.byte 0xe6
	nop
	jr	gt, 0
	normal
	ldwio	11, 0x8a00
	nop
	.byte 0xe6
	nop
	.byte 0x8a, 0x00, 0x01, 0x0a, 0x0b, 0x00
	.long NakaData_DescriptorPad_ZeroB
	.byte 0xaa, 0x00, 0x01
	ldwio	242, 0xb200
	nop
	ldb	a, 1
	ld	(xde), 1
	ldwio	49, 0xe400
	nop
	ld	xiz, 0x0100e400
	ldwio	129, 0xe400
	nop
	.long NakaData_ExternalPadBlock_A
	normal
	ldwio	201, 0xe400
	nop
	.byte 0xde, 0x00, 0xe4, 0x00, 0x01, 0x0a
	.long Pad_AfterNakaData_UserMemoryConfig
	.long Pad_BeforeNakaData_StyleBitmapPad
	push	sr
	ldwio	44, 0x3800
	nop
	pushw	ix
	nop
	.byte 0xca, 0x00
	push	sr
	ldwio	124, 0x3800
	nop
	jrl	po, 16763392
	nop
	push	sr
	ldwio	174, 0x3800
	nop
	.byte 0xae, 0x00, 0xca
	nop
	halt
	ldwio	244, 0xb400
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
	ldwio	14, 0x4301
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
	jrl	nz, 16764928
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
	ldb	b, 10
	call	0xcd00
	.byte 0x52
	nop
	.byte 0xe8, 0x00
	scf
	ldwio	24, 0x4400
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
	ldwio	24, 0x6400
	nop
	pushw	ix
	nop
	jr	pe, 0
	scf
	ldwio	8, 0x7500
	nop
	push_f
	nop
	jrl	mi, 4352
	ldwio	24, 0x8200
	nop
	pushw	ix
	nop
	.byte 0x82, 0x00
	scf
	ldwio	8, 0x9c00
	nop
	push_f
	nop
	.byte 0x9c, 0x00, 0x11
	ldwio	31, 0xa200
	nop
	pushw	ix
	nop
	.byte 0xa2, 0x00
	scf
	ldwio	8, 0xc200
	nop
	.byte 0x1f
	nop
	.byte 0xc2, 0x00, 0x12, 0x0a, 0x18
	nop
	ld	xix, 0x4f001800
	nop
	ccf
	ldwio	24, 0x6400
	nop
	push_f
	nop
	jrl	mi, 4608
	ldwio	24, 0x8200
	nop
	push_f
	nop
	.byte 0x9c, 0x00, 0x12
	ldwio	31, 0xa200
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
	ldwio	22, 0x6b01
	nop
	ldw	de, 0x7801
	nop
	halt
	ldwio	90, 0xdc00
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
	stb_d8	(0xe700), d
	stb_d8	(8960), e
	stb_d8	(0x2d00), e
	stb_d8	(0x3700), e
	stb_d8	(0x4100), e
	stb_d8	(0x9c00), e
	stb_d8	(0xa600), e
	stb_d8	(0xb000), e
	stb_d8	(0xba00), e
	stb_d8	(0x4b00), e
	stb_d8	(0x5500), e
	stb_d8	(0x9c00), e
	stb_d8	(0xa600), e
	stb_d8	(0xb000), e
	stb_d8	(0xba00), e
	.byte 0xf1, 0x00, 0x02, 0x0f
	jr	le, 6
	.byte 0x80, 0x07
	ldb	w, 118
	ld	xiz, 0x0700f1
	.byte 0x4f
	decf
	push	sr
	retd	0x0663
	.byte 0x80, 0x07
	ldb	w, 118
	ld	xiz, 0x0700f1
	jrl	c, 530
	retd	0x0664
	.byte 0x80, 0x07
	ldb	w, 118
	ld	xiz, 0x0700f1
	.byte 0x4f
	ldf	2
	retd	0x0665
	.byte 0x80, 0x07
	ldb	w, 118
	ld	xiz, 0x0700f1
	popw sp
	call16	0x4604
	stb_d8	(1024), h
	stb_d8	(1024), h
	stb_d8	(4864), h
	stb_d8	(8704), h
	stb_d8	(0x3100), h
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
	ldb	c, 5
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
	ldwio	209, 0xe400
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
	jrl	po, 16765184
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
	ldwio	251, 0x440a
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
	jrl	t, 16765184
	nop
	ld	xde, 0x4e414c41
	ld	xhl, 0xfb090645
	ldwio	83, 0x4550
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
	stda16	(0xe100), ix
	stda16	(0x6400), iy
	stda16	(0xe100), ix
	stda16	(0x6400), iy
	stda16	(0xe100), ix
	stda16	(0x6400), iy
	stda16	(0x6400), iy
	stda16	(1024), iz
	stda16	(0x6400), iy
	stda16	(1024), iz
	stda16	(1024), iz
	stda16	(0x6a00), iz
	stda16	(0x6a00), iz
	stda16	(0xd600), iz
	stda16	(0xd600), iz
	.byte 0xf1, 0x00, 0x42, 0x57, 0xf1, 0x00, 0x42, 0x57, 0xf1, 0x00, 0xae, 0x57, 0xf1, 0x00, 0xae, 0x57, 0xf1, 0x00, 0x04, 0x58, 0xf1, 0x00, 0xae, 0x57, 0xf1, 0x00, 0x04, 0x58, 0xf1, 0x00, 0x02, 0x0f
	jr	f, 6
	retd	0x2000
	normal
	pop	xhl
	stdi8	(3328), 9
	ldio	2, 15
	jr	f, 6
	.byte 0x80, 0x07
	ldb	w, 215
	push_a
	stdi8	(768), 186
	pushw 3842
	jr	f, 6
	ld	xwa, 0x5b9d2006
	stdi8	(1536), 170
	scf
	halt
	pushw 1640
	swi	7
	nop
	ldb	w, 115
	jp	0x050002
	pushw 1639
	swi	7
	nop
	ldb	w, 27
	pop_f
	push	sr
	nop

	.include "storage/flash_floppy_handlers.s"

S2cShowHideFunc:
	.incbin "includes/generated/v7_transplant_S2cShowHideFunc.bin"
S2cShow_ReturnZero:
	lds32 xhl, 0
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
	lda_24 xix, (S2c_GridCheck_DataBlock)
	jp_ind 8, 0x07, 0xf0, 0xe0

S2c_GridCheck_DataBlock:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 0x01e0008f
	lds32	xde, 0
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
	lds32	xde, 0
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
	.incbin "includes/generated/v7_transplant_S2c_GridCheck_Dispatch.bin"
S2c_GridCheck_GetFocusSendEvt:
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 10)
	ld xbc, 0x1e0008c
	call SendEvent

; S2cGridCheck event encoding dispatch
S2c_GridCheck_EventEnc:
	lds32 xhl, 0
	lda xsp, (xsp + 18)
	ret

CmpClrYesFunc:
	ld xwa, 0x144000c
	ld xbc, 0x1e40006
	lds32 xde, 0
	call MainFuncCall
	lds32 xhl, 0
	ret

CmpClrNoFunc:
	ld xwa, 0x144000c
	ld xbc, 0x1e40007
	lds32 xde, 0
	call MainFuncCall
	lds32 xhl, 0
	ret
PsCmpCpFGrpBox_Entry:

PsCmpCpFGrpBoxProc:
	stb_dri L, 0xfd, 0xf0, 0xfe
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
	ld_sril XWA, (xsp + 0x0110)
	ld_sril XDE, (xsp + 0x010c)
	call InheritedProc
	jrl PsCmpCpFGrpBox_Epilogue

PsCmpCpFGrpBox_HandleEvt1:
	ld_sril XWA, (xsp + 0x0110)
	ld_sril XDE, (xsp + 0x010c)
	jr PsCmpCpFGrpBox_CallInherited

PsCmpCpFGrpBox_HandleEvt2:
	ld_sril XWA, (xsp + 0x0110)
	ld_sril XDE, (xsp + 0x010c)

PsCmpCpFGrpBox_CallInherited:
	call InheritedProc
	jrl PsCmpCpFGrpBox_ReturnZero

PsCmpCpFGrpBox_HandleEvtBC:
	ld_sril XWA, (xsp + 0x0110)
	ld_sril XDE, (xsp + 0x010c)
	call InheritedProc
	ld xwa, 0x144000b
	ld xbc, 0x1e40002
	lds32 xde, 0
	call MainFuncCall
	jrl PsCmpCpFGrpBox_ReturnZero

PsCmpCpFGrpBox_HandleEvt4:
	.incbin "includes/generated/v7_transplant_PsCmpCpFGrpBox_HandleEvt4.bin"
PsCmpCpFGrpBox_SetColorFF:
	ldw (xbc), 0xff
	ldw (xwa), 0xf5

PsCmpCpFGrpBox_SendNotify:
	.incbin "includes/generated/v7_transplant_PsCmpCpFGrpBox_SendNotify.bin"
PsCmpCpFGrpBox_PushF5:
	pushw 0xf5
	lds bc, 1
	lds de, 2

PsCmpCpFGrpBox_DrawFrame:
	call DrawDesignFrame

PsCmpCpFGrpBox_ReturnZero:
	lds32 xhl, 0

PsCmpCpFGrpBox_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0x10, 0x01
	ret
PsCmpCpFVariBox_Entry:

PsCmpCpFVariBoxProc:
	stb_dri L, 0xfd, 0xf0, 0xfe
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
	ld_sril XWA, (xsp + 0x0110)
	ld_sril XDE, (xsp + 0x010c)
	call InheritedProc
	jrl PsCmpCpFVariBox_Epilogue

PsCmpCpFVariBox_HandleEvt1:
	ld_sril XWA, (xsp + 0x0110)
	ld_sril XDE, (xsp + 0x010c)
	jr PsCmpCpFVariBox_CallInherited

PsCmpCpFVariBox_HandleEvt2:
	ld_sril XWA, (xsp + 0x0110)
	ld_sril XDE, (xsp + 0x010c)

PsCmpCpFVariBox_CallInherited:
	call InheritedProc
	jrl DesignFrame_Return

PsCmpCpFVariBox_HandleEvtBC:
	ld_sril XWA, (xsp + 0x0110)
	ld_sril XDE, (xsp + 0x010c)
	call InheritedProc
	ld xwa, 0x144000b
	ld xbc, 0x1e40003
	lds32 xde, 0
	call MainFuncCall
	jrl DesignFrame_Return

PsCmpCpFVariBox_HandleEvt5:
	.incbin "includes/generated/v7_transplant_PsCmpCpFVariBox_HandleEvt5.bin"
PsCmpCpFVariBox_SetColorFF:
	ldw (xbc), 0xff
	ldw (xwa), 0xf5

PsCmpCpFVariBox_SendNotify:
	.incbin "includes/generated/v7_transplant_PsCmpCpFVariBox_SendNotify.bin"
PsCmpCpFVariBox_PushF5:
	pushw 0xf5
	lds bc, 1
	lds de, 2

PsCmpCpFVariBox_DrawFrame:
	call DrawDesignFrame

DesignFrame_Return:
	lds32 xhl, 0

PsCmpCpFVariBox_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0x10, 0x01
	ret
PsCmpCpFPtnBox_Entry:

PsCmpCpFPtnBoxProc:
	stb_dri L, 0xfd, 0xf4, 0xfe
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
	ld_sril XWA, (xsp + 0x010c)
	call InheritedProc
	jrl PsCmpCpFPtnBox_Epilogue

PsCmpCpFPtnBox_HandleEvt1:
	ld_sril XWA, (xsp + 0x010c)
	jr PsCmpCpFPtnBox_CallInherited

PsCmpCpFPtnBox_HandleEvt2:
	ld_sril XWA, (xsp + 0x010c)

PsCmpCpFPtnBox_CallInherited:
	call InheritedProc
	jrl PsCmpCpFPtnBox_ReturnZero

PsCmpCpFPtnBox_HandleEvtBC:
	.incbin "includes/generated/v7_transplant_PsCmpCpFPtnBox_HandleEvtBC.bin"
PsCmpCpFPtnBox_SetColorFF:
	ldw (xbc), 0xff
	ldw (xwa), 0xf5

PsCmpCpFPtnBox_SendNotify:
	.incbin "includes/generated/v7_transplant_PsCmpCpFPtnBox_SendNotify.bin"
PsCmpCpFPtnBox_PushF5:
	pushw 0xf5
	lds bc, 1
	lds de, 2

PsCmpCpFPtnBox_DrawFrame:
	call DrawDesignFrame

PsCmpCpFPtnBox_ReturnZero:
	lds32 xhl, 0

PsCmpCpFPtnBox_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0x0c, 0x01
	ret
PsCstmCpBnkBox_Entry:

PsCstmCpBnkBoxProc:
	stb_dri L, 0xfd, 0x00, 0xff
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
	.incbin "includes/generated/v7_transplant_PsCstmCpBnkBox_HandleEvtBC.bin"
PsCstmCpBnkBox_ReadParam2:
	.incbin "includes/generated/v7_transplant_PsCstmCpBnkBox_ReadParam2.bin"
PsCstmCpBnkBox_LookupAndSend:
	.incbin "includes/generated/v7_transplant_PsCstmCpBnkBox_LookupAndSend.bin"
PsCstmCpBnkBox_ReturnZero:
	lds32 xhl, 0

PsCstmCpBnkBox_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0x00, 0x01
	ret
PsCstmCpSwBox_Entry:

PsCstmCpSwBoxProc:
	stb_dri L, 0xfd, 0x00, 0xff
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
	.incbin "includes/generated/v7_transplant_PsCstmCpSwBox_HandleEvtBC.bin"
PsCstmCpSwBox_PushTableAddr0:
	push xwa
	push xbc
	jr PsCstmCpSwBox_SendCommand

PsCstmCpSwBox_ReadParam2:
	.incbin "includes/generated/v7_transplant_PsCstmCpSwBox_ReadParam2.bin"
PsCstmCpSwBox_PushTableAddr1:
	push xwa
	push xbc

PsCstmCpSwBox_SendCommand:
	.incbin "includes/generated/v7_transplant_PsCstmCpSwBox_SendCommand.bin"
PsCstmCpSwBox_ReturnZero:
	lds32 xhl, 0

PsCstmCpSwBox_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0x00, 0x01
	ret
PsCstmCpNameBox_Entry:

PsCstmCpNameBoxProc:
	stb_dri L, 0xfd, 0xfc, 0xfe
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
	ld_sril XDE, (xsp + 0x0104)
	call InheritedProc
	jrl PsCstmCpNameBox_Epilogue

PsCstmCpNameBox_HandleEvt1:
	ld xwa, xiz
	ld_sril XDE, (xsp + 0x0104)
	jr PsCstmCpNameBox_CallInherited

PsCstmCpNameBox_HandleEvt2:
	ld xwa, xiz
	ld_sril XDE, (xsp + 0x0104)

PsCstmCpNameBox_CallInherited:
	call InheritedProc
	jrl PsCtmAtt_ReturnZero

PsCstmCpNameBox_HandleEvtD:
	.incbin "includes/generated/v7_transplant_PsCstmCpNameBox_HandleEvtD.bin"
PsCstmCpNameBox_FuncCall2C:
	ld xwa, 0x144001a
	ld xbc, 0x1e4002c
	lds32 xde, 0

PsCstmCpNameBox_MainFuncCall:
	call MainFuncCall
	jr PsCtmAtt_ReturnZero

PsCstmCpNameBox_HandleEvt2D:
	.incbin "includes/generated/v7_transplant_PsCstmCpNameBox_HandleEvt2D.bin"
PsCstmCpNameBox_HandleEvt2E:
	.incbin "includes/generated/v7_transplant_PsCstmCpNameBox_HandleEvt2E.bin"
PsCstmCpNameBox_SendEventJoin:
	call SendEvent

PsCtmAtt_ReturnZero:
	lds32 xhl, 0

PsCstmCpNameBox_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0x04, 0x01
	ret
PsCtmAttStrBox_Entry:

PsCtmAttStrBoxProc:
	stb_dri L, 0xfd, 0x00, 0xff
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
	.incbin "includes/generated/v7_transplant_PsCtmAttStrBox_HandleEvtBC.bin"
PsCtmAttStrBox_ReturnZero:
	lds32 xhl, 0

PsCtmAttStrBox_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0x00, 0x01
	ret
AcMemNoBox_Entry:

AcMemNoBoxProc:
	stb_dri L, 0xfd, 0xf4, 0xfe
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
	ld_sril XWA, (xsp + 0x010c)
	call InheritedProc
	jrl AcMemNoBox_Epilogue

AcMemNoBox_HandleEvt1:
	ld_sril XWA, (xsp + 0x010c)
	jr AcMemNoBox_CallInherited

AcMemNoBox_HandleEvt2:
	ld_sril XWA, (xsp + 0x010c)

AcMemNoBox_CallInherited:
	call InheritedProc
	jrl AcMemNoBox_ReturnZero

AcMemNoBox_HandleEvtBC:
	.incbin "includes/generated/v7_transplant_AcMemNoBox_HandleEvtBC.bin"
AcMemNoBox_SetColorFF:
	ldw (xbc), 0xff
	ldw (xwa), 0xf5

AcMemNoBox_SendNotify:
	.incbin "includes/generated/v7_transplant_AcMemNoBox_SendNotify.bin"
AcMemNoBox_PushF5:
	pushw 0xf5
	lds bc, 1
	lds de, 2

AcMemNoBox_DrawFrame:
	call DrawDesignFrame

AcMemNoBox_ReturnZero:
	lds32 xhl, 0

AcMemNoBox_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0x0c, 0x01
	ret
AcCmpRecBox_Entry:

AcCmpRecBoxProc:
	stb_dri L, 0xfd, 0xe8, 0xfe
	push xiz
	stl_dri XDE, 0xfd, 0x10, 0x01
	stl_dri XBC, 0xfd, 0x14, 0x01
	stl_dri XWA, 0xfd, 0x18, 0x01
	ld_sril XWA, (xsp + 0x0114)
	cp xwa, 0x1c0000c
	jr z, AcCmpRecBox_HandleEvtBC
	cp xwa, 0x1c0000b
	jr z, AcCmpRecBox_HandleEvtBC
	cp xwa, 0x1c00002
	jr z, AcCmpRecBox_HandleEvt2
	cp xwa, 0x1c00001
	jr z, AcCmpRecBox_HandleEvt1
	ld_sril XWA, (xsp + 0x0118)
	ld_sril XBC, (xsp + 0x0114)
	ld_sril XDE, (xsp + 0x0110)
	call InheritedProc
	jrl AcCmpRecBox_Epilogue

AcCmpRecBox_HandleEvt1:
	ld_sril XWA, (xsp + 0x0118)
	ld_sril XBC, (xsp + 0x0114)
	ld_sril XDE, (xsp + 0x0110)
	jr AcCmpRecBox_CallInherited

AcCmpRecBox_HandleEvt2:
	ld_sril XWA, (xsp + 0x0118)
	ld_sril XBC, (xsp + 0x0114)
	ld_sril XDE, (xsp + 0x0110)

AcCmpRecBox_CallInherited:
	call InheritedProc
	jrl AcCmpRecBox_ReturnZero

AcCmpRecBox_HandleEvtBC:
	.incbin "includes/generated/v7_transplant_AcCmpRecBox_HandleEvtBC.bin"
AcCmpRecBox_CheckParam2:
	.incbin "includes/generated/v7_transplant_AcCmpRecBox_CheckParam2.bin"
AcCmpRecBox_AdjustTable:
	.incbin "includes/generated/v7_transplant_AcCmpRecBox_AdjustTable.bin"
AcCmpRecBox_InheritAndSend:
	ld_sril XWA, (xsp + 0x0118)
	ld_sril XBC, (xsp + 0x0114)
	ld_sril XDE, (xsp + 0x0110)
	call InheritedProc
	lda xde, (xsp + 16)
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, 0x1c0000f
	call SendEvent

AcCmpRecBox_ReturnZero:
	lds32 xhl, 0

AcCmpRecBox_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0x18, 0x01
	ret
PsCmpQtzBox_Entry:

PsCmpQtzBoxProc:
	stb_dri L, 0xfd, 0x00, 0xff
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
	.incbin "includes/generated/v7_transplant_PsCmpQtzBox_HandleEvtBC.bin"
PsCmpQtzBox_ReturnZero:
	lds32 xhl, 0

PsCmpQtzBox_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0x00, 0x01
	ret
PsCmpMeasBox_Entry:

PsCmpMeasBoxProc:
	stb_dri L, 0xfd, 0xf8, 0xfe
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
	ld_sril XWA, (xsp + 0x0108)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0104)
	call InheritedProc
	jr PsCmpMeasBox_Epilogue

PsCmpMeasBox_HandleEvt1:
	ld_sril XWA, (xsp + 0x0108)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0104)
	jr PsCmpMeasBox_CallInherited

PsCmpMeasBox_HandleEvt2:
	ld_sril XWA, (xsp + 0x0108)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0104)

PsCmpMeasBox_CallInherited:
	call InheritedProc
	jr PsCmpMeasBox_ReturnZero

PsCmpMeasBox_HandleEvtBC:
	.incbin "includes/generated/v7_transplant_PsCmpMeasBox_HandleEvtBC.bin"
PsCmpMeasBox_ReturnZero:
	lds32 xhl, 0

PsCmpMeasBox_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0x08, 0x01
	ret
PsCmpMemBox_Entry:

PsCmpMemBoxProc:
	stb_dri L, 0xfd, 0xf8, 0xfe
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
	ld_sril XWA, (xsp + 0x0108)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0104)
	call InheritedProc
	jr PsCmpMemBox_Epilogue

PsCmpMemBox_HandleEvt1:
	ld_sril XWA, (xsp + 0x0108)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0104)
	jr PsCmpMemBox_CallInherited

PsCmpMemBox_HandleEvt2:
	ld_sril XWA, (xsp + 0x0108)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0104)

PsCmpMemBox_CallInherited:
	call InheritedProc
	jr PsCmpMemBox_ReturnZero

PsCmpMemBox_HandleEvtBC:
	.incbin "includes/generated/v7_transplant_PsCmpMemBox_HandleEvtBC.bin"
PsCmpMemBox_ReturnZero:
	lds32 xhl, 0

PsCmpMemBox_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0x08, 0x01
	ret
AcCmpTempoBox_Entry:

AcCmpTempoBoxProc:
	stb_dri L, 0xfd, 0xfc, 0xfe
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
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	jr AcCmpTempoBox_Epilogue

AcCmpTempoBox_HandleEvt1:
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld_sril XWA, (xsp + 0x0104)
	lds32 xbc, 4
	call SetLswFilter
	jr CmpFunc_Return

AcCmpTempoBox_HandleEvt2:
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld_sril XWA, (xsp + 0x0104)
	lds32 xbc, 4
	call ResetLswFilter
	jr CmpFunc_Return

AcCmpTempoBox_HandleEvtBC:
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	lds32 xwa, 4
	call MainLswGet
	jr CmpFunc_Return

AcCmpTempoBox_HandleEvt1C:
	.incbin "includes/generated/v7_transplant_AcCmpTempoBox_HandleEvt1C.bin"
CmpFunc_Return:
	lds32 xhl, 0

AcCmpTempoBox_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0x04, 0x01
	ret

CmpNamingCheck:
	.incbin "includes/generated/v7_transplant_CmpNamingCheck.bin"
CmpNamingCheck_ReturnZero:
	lds32 xhl, 0
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
	lds32 xhl, 0
	ret
PsNameMemBox_Entry:

PsNameMemBoxProc:
	stb_dri L, 0xfd, 0xf4, 0xfe
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
	ld_sril XWA, (xsp + 0x010c)
	call InheritedProc
	jrl EasyCmp_TtlCase3

PsNameMemBox_HandleEvt1:
	ld_sril XWA, (xsp + 0x010c)
	jr PsNameMemBox_CallInherited

PsNameMemBox_HandleEvt2:
	ld_sril XWA, (xsp + 0x010c)

PsNameMemBox_CallInherited:
	call InheritedProc
	jrl EasyCmp_TtlCase2

PsNameMemBox_HandleEvtBC:
	.incbin "includes/generated/v7_transplant_PsNameMemBox_HandleEvtBC.bin"
PsNameMemBox_SetColorFF:
	ldw (xbc), 0xff
	ldw (xwa), 0xf5

PsNameMemBox_SendNotify:
	.incbin "includes/generated/v7_transplant_PsNameMemBox_SendNotify.bin"
EasyCmp_TtlDispatch:
	pushw 0xf5
	lds bc, 1
	lds de, 2

; EasyCmp title case 1
EasyCmp_TtlCase1:
	call DrawDesignFrame

; EasyCmp title case 2
EasyCmp_TtlCase2:
	lds32 xhl, 0

; EasyCmp title case 3
EasyCmp_TtlCase3:
	pop xiz
	stb_dri L, 0xfd, 0x0c, 0x01
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
	lda_24 xix, (EasyCmp_DialGrid)
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
	lds32 xde, 0
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
	lds wa, 1
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
	lds32 xde, 0
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
	lds wa, 1

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
	.incbin "includes/generated/v7_transplant_EasyCmp_GridCheck_Case2.bin"
EasyCmp_GridCheck_Case3:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call ApFuncCall

EasyCmp_ReturnZeroJmp:
	lds32 xhl, 0
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
	lda_24 xix, (EasyCmp_GridCheck_DataBlock)
	jp_ind 8, 0x07, 0xf0, 0xe0

EasyCmp_GridCheck_DataBlock:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 0x01e0008f
	lds32	xde, 0
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
	cps	wa, 2
	jr	z, 17
	cps	wa, 1
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
	lds32	xde, 0
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
	cps	wa, 2
	jr	z, 17
	cps	wa, 1
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
	.incbin "includes/generated/v7_transplant_EasyCmp_GridCheck_EventEnc.bin"
EasyCmp_GridEvtEnc_Case2:
	.incbin "includes/generated/v7_transplant_EasyCmp_GridEvtEnc_Case2.bin"
EasyCmp_GridCheck_EventCase1:
	.incbin "includes/generated/v7_transplant_EasyCmp_GridCheck_EventCase1.bin"
EasyCmp_GridCheck_EventCase2:
	.incbin "includes/generated/v7_transplant_EasyCmp_GridCheck_EventCase2.bin"
EasyCmp_GridCheck_EventCase3:
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 20)
	ld xbc, 0x1e0008c
	call SendEvent

; EasyCmpGridCheck event case 4
EasyCmp_GridCheck_EventCase4:
	lds32 xhl, 0
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
	lda_24 xix, (EasyCmp_GridEvtCase_Default)
	jp_ind 8, 0x07, 0xf0, 0xe0

EasyCmp_GridEvtCase_Default:
	.incbin "includes/generated/v7_transplant_EasyCmp_GridEvtCase_Default.bin"
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
	.incbin "includes/generated/v7_transplant_EasyCmp_GridEvtCase_Epilogue.bin"
MspNaming_CleanupExit:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 16)
	ret

MspNamingCheck:
	.incbin "includes/generated/v7_transplant_MspNamingCheck.bin"
MspNamingCheck_ReturnZero:
	lds32 xhl, 0
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
	lds32 xhl, 0
	ret
MspNameOkFunc_End:

PsMspNameBnkProc:
	stb_dri L, 0xfd, 0x00, 0xff
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
	.incbin "includes/generated/v7_transplant_PsMspNameBnk_HandleEvtBC.bin"
PsMspNameBnk_SetReturnZero:
	lds32 xhl, 0

PsMspNameBnk_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0x00, 0x01
	ret
PsMspNameBnk_End:

VwVariBoxProc:
	stb_dri L, 0xfd, 0xe8, 0xfe
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
	ld_sril XWA, (xsp + 0x0118)
	call GetViewInstance
	lda xwa, (xhl + 38)
	ld xbc, (xwa)
	ld bc, (xbc)
	exts xbc
	cpl_sri_rm XBC, 0xfd, 0x14, 0x01
	jrl z, VwVariBox_ReturnHandled
	ld xbc, (xwa)
	ld_sril XWA, (xsp + 0x0114)
	ld (xbc), wa
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, 0x1c0000d
	lds32 xde, 0
	jrl VwVariBox_DispatchAndReturn

VwVariBox_Init:
	.incbin "includes/generated/v7_transplant_VwVariBox_Init.bin"
VwVariBox_Match:
	.incbin "includes/generated/v7_transplant_VwVariBox_Match.bin"
VwVariBox_Match_ValueMismatch:
	ldw (xwa), 0x0
	cpw (xsp + 6), 0xa
	jr ge, VwVariBox_Match_HighIndex
	ld xwa, 0xc80001
	ld xbc, 0x1e00056
	lds32 xde, 0
	call SendEvent
	cp xhl, 0x1
	jr z, VwVariBox_Match_Repaint
	ld xwa, 0xc80001
	ld xbc, 0x1e0007f
	lds32 xde, 1
	call SendEvent
	ld xwa, 0xc80001
	ld xbc, 0x1c0000f
	lds32 xde, 1
	jr VwVariBox_Match_DispatchConfirm

VwVariBox_Match_HighIndex:
	ld xwa, 0xc80001
	ld xbc, 0x1e00056
	lds32 xde, 0
	call SendEvent
	cp xhl, 0x2
	jr z, VwVariBox_Match_Repaint
	ld xwa, 0xc80001
	ld xbc, 0x1e0007f
	lds32 xde, 2
	call SendEvent
	ld xwa, 0xc80001
	ld xbc, 0x1c0000f
	lds32 xde, 2

VwVariBox_Match_DispatchConfirm:
	call ApDeliveryEvent

VwVariBox_Match_Repaint:
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, 0x1c0000d
	lds32 xde, 0
	jrl VwVariBox_DispatchAndReturn

VwVariBox_Paint:
	ld_sril XWA, (xsp + 0x0118)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 38)
	cpw (xwa), 0x0
	jr z, VwVariBox_Paint_Greyed
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0114)
	call InheritedProc
	jr VwVariBox_Paint_DrawLabel

VwVariBox_Paint_Greyed:
	stb_dri A, 0xfd, 0x08, 0x01
	ld_sril XWA, (xsp + 0x0118)
	call GetBox
	stb_dri W, 0xfd, 0x08, 0x01
	ldw bc, 0xf5
	call DrawBox

VwVariBox_Paint_DrawLabel:
	ld xwa, (xsp + 4)
	ld wa, (xwa + 36)
	call DrawEditSw
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jrl VwVariBox_DispatchAndReturn

VwVariBox_Confirm:
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
	ld xwa, xde
	lda xbc, (xde + 17)

VwVariBox_Confirm_ClearBuf:
	stib_dsp 0xe0, 0x00
	cp xwa, xbc
	jr c, VwVariBox_Confirm_ClearBuf
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, 0x1e0003a
	call SendEvent
	ld xwa, (xsp + 4)
	ld xiz, (xwa + 38)
	stb_dri A, 0xfd, 0x10, 0x01
	stb_dri B, 0xfd, 0x08, 0x01
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
	lds32 xhl, 0
	jrl VwVariBox_Return

VwVariBox_GetText:
	ld_sril XWA, (xsp + 0x0118)
	call GetViewInstance
	lda xwa, (xhl + 42)
	cp (xwa), 0xd
	jr c, VwVariBox_GetText_LookupAudio
	ld c, (xwa)
	cp c, 0x10
	jr ule, VwVariBox_GetText_HighValues

VwVariBox_GetText_LookupAudio:
	.incbin "includes/generated/v7_transplant_VwVariBox_GetText_LookupAudio.bin"
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
	.incbin "includes/generated/v7_transplant_VwVariBox_GetText_PlaySample.bin"
VwVariBox_OK:
	.incbin "includes/generated/v7_transplant_VwVariBox_OK.bin"
VwVariBox_OK_Forward:
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0114)
	jr VwVariBox_ForwardToBase

VwVariBox_Release:
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0114)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0118)
	call GetViewInstance
	ld wa, (xhl + 26)
	exts xwa
	cpl_sri_rm XWA, 0xfd, 0x14, 0x01
	jrl nz, VwVariBox_ReturnHandled
	ld xwa, (xhl + 38)
	cpw (xwa), 0x0
	jrl z, VwVariBox_ReturnHandled
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, 0x1e0004d
	lds32 xde, 0

VwVariBox_DispatchAndReturn:
	call SendEvent
	jrl VwVariBox_ReturnHandled

VwVariBox_CanScroll:
	ld_sril XWA, (xsp + 0x0118)
	call GetViewInstance
	ld wa, (xhl + 26)
	exts xwa
	cpl_sri_rm XWA, 0xfd, 0x14, 0x01
	jrl nz, VwVariBox_ReturnHandled
	ld xwa, (xhl + 38)
	cpw (xwa), 0x1
	jrl nz, VwVariBox_ReturnHandled
	lds32 xhl, 1
	jr VwVariBox_Return

VwVariBox_Default:
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0114)

VwVariBox_ForwardToBase:
	call InheritedProc

VwVariBox_Return:
	pop xiz
	stb_dri L, 0xfd, 0x18, 0x01
	ret

MspBnkShow:
	.incbin "includes/generated/v7_transplant_MspBnkShow.bin"
MspBnk_SendEvt56_Case2:
	ld xwa, 0xc80001
	ld xbc, 0x1e00056
	lds32 xde, 0
	call SendEvent
	cp xhl, 0x2
	jr z, MspBnk_ReturnZero
	ld xwa, 0xc80001
	ld xbc, 0x1e0007f
	lds32 xde, 2

MspBnk_SendEvt7F:
	call SendEvent

MspBnk_ReturnZero:
	lds32 xhl, 0
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
	.incbin "includes/generated/v7_transplant_MspBnkSlBox_HandleEvt7.bin"
MspBnkSlBox_CallMainLswGet:
	call MainLswGet

MspBnkSlBox_ReturnZeroJmp:
	lds32 xhl, 0
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
	stb_dri L, 0xfd, 0xfc, 0xfe
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
	ld_sril XDE, (xsp + 0x0104)
	jr MspBnkNameBox_CallInherited

MspBnkNameBox_HandleEvt2:
	ld xwa, xiz
	ld_sril XDE, (xsp + 0x0104)

MspBnkNameBox_CallInherited:
	call InheritedProc
	jrl RgpSetBnk_GridCheck_Case1

MspBnkNameBox_HandleEvtD:
	ld xwa, xiz
	ld_sril XDE, (xsp + 0x0104)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld a, (xhl + 36)
	cps a, 3
	jr z, MspBnkNameBox_EvtD_Case3
	cps a, 2
	jr z, MspBnkNameBox_EvtD_Case2
	cps a, 1
	jr z, MspBnkNameBox_EvtD_Case1
	cps a, 0
	jrl nz, RgpSetBnk_GridCheck_Case1
	ld xwa, 0x1440010
	ld xbc, 0x1e40017
	lds32 xde, 0
	jr MspBnk_MainFuncDispatch

MspBnkNameBox_EvtD_Case1:
	ld xwa, 0x1440010
	ld xbc, 0x1e40018
	lds32 xde, 0
	jr MspBnk_MainFuncDispatch

MspBnkNameBox_EvtD_Case2:
	ld xwa, 0x1440010
	ld xbc, 0x1e40019
	lds32 xde, 0
	jr MspBnk_MainFuncDispatch

MspBnkNameBox_EvtD_Case3:
	ld xwa, 0x1440010
	ld xbc, 0x1e4001a
	lds32 xde, 0

MspBnk_MainFuncDispatch:
	call MainFuncCall
	jrl RgpSetBnk_GridCheck_Case1

MspBnkNameBox_HandleEvt1B:
	.incbin "includes/generated/v7_transplant_MspBnkNameBox_HandleEvt1B.bin"
MspBnkNameBox_HandleEvt1C:
	.incbin "includes/generated/v7_transplant_MspBnkNameBox_HandleEvt1C.bin"
MspBnkNameBox_HandleEvt1D:
	.incbin "includes/generated/v7_transplant_MspBnkNameBox_HandleEvt1D.bin"
RgpSetBnk_GridCheck:
	.incbin "includes/generated/v7_transplant_RgpSetBnk_GridCheck.bin"
MspBnk_SendEventJoin:
	call SendEvent

; RgpSetBnkCheck case 1
RgpSetBnk_GridCheck_Case1:
	lds32 xhl, 0
	jr RgpSetBnk_GridCheck_Case3

; RgpSetBnkCheck case 2
RgpSetBnk_GridCheck_Case2:
	ld xwa, xiz
	ld_sril XDE, (xsp + 0x0104)
	call InheritedProc

; RgpSetBnkCheck case 3
RgpSetBnk_GridCheck_Case3:
	pop xiz
	stb_dri L, 0xfd, 0x04, 0x01
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
	lda_24 xix, (MspRGrpSetGridCheck_DataBlock)
	jp_ind 8, 0x07, 0xf0, 0xe0

MspRGrpSetGridCheck_DataBlock:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 0x01e0008f
	lds32	xde, 0
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
	cps	wa, 2
	jr	z, 17
	cps	wa, 1
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
	lds32	xde, 0
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
	cps	wa, 2
	jr	z, 17
	cps	wa, 1
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
	.incbin "includes/generated/v7_transplant_RgpSetBnk_GridCheck_EventEnc.bin"
RgpSetBnk_EvtEnc_HighIndex:
	ld xwa, 0x1e8a80
	cp l, 0xe
	jr nz, RgpSetBnk_EvtEnc_CopyMem
	ld xwa, 0x1e8a90

RgpSetBnk_EvtEnc_CopyMem:
	.incbin "includes/generated/v7_transplant_RgpSetBnk_EvtEnc_CopyMem.bin"
RgpSetBnk_EvtEnc_SendAudioCmd:
	.incbin "includes/generated/v7_transplant_RgpSetBnk_EvtEnc_SendAudioCmd.bin"
AudioEvt_GetFocusRetZero:
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 20)
	ld xbc, 0x1e0008c
	call SendEvent

; RgpSetBnkCheck return
RgpSetBnk_GridCheck_Return:
	lds32 xhl, 0
	lda xsp, (xsp + 28)
	ret
PsRgpSetBnkBoxProc_Entry:

PsRgpSetBnkBoxProc:
	stb_dri L, 0xfd, 0x00, 0xff
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
	.incbin "includes/generated/v7_transplant_RgpSetBnkBox_HandleEvtBC.bin"
RgpSetBnkBox_SetReturnZero:
	lds32 xhl, 0

RgpSetBnkBox_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0x00, 0x01
	ret

MspRGrpSetBnkFunc:
	.incbin "includes/generated/v7_transplant_MspRGrpSetBnkFunc.bin"
MspRGrpSetBnk_SetToZero:
	.incbin "includes/generated/v7_transplant_MspRGrpSetBnk_SetToZero.bin"
MspRGrpSetBnk_UpdateLsw:
	.incbin "includes/generated/v7_transplant_MspRGrpSetBnk_UpdateLsw.bin"
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
	lds32 xhl, 0
	popw_erp 0xfa
	ret

MspRgpShowHideFunc:
	.incbin "includes/generated/v7_transplant_MspRgpShowHideFunc.bin"
MspRgpShowHide_BankSelect1:
	ld xwa, 0x28800
	ldw bc, 0x10
	lds de, 0

MspRgpShowHide_PutLsw:
	call MainLswPut

MspRgpShow_ReturnZero:
	lds32 xhl, 0
	ret
MspRgpShowHide_End:

PsMspMeasBoxProc:
	stb_dri L, 0xfd, 0x00, 0xff
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
	.incbin "includes/generated/v7_transplant_MspMeasBox_HandleEvtBC.bin"
MspMeasBox_SetReturnZero:
	lds32 xhl, 0

MspMeasBox_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0x00, 0x01
	ret
MspMeasBox_End:

PsMspMemBoxProc:
	stb_dri L, 0xfd, 0x00, 0xff
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
	.incbin "includes/generated/v7_transplant_MspMemBox_HandleEvtBC.bin"
MspMemBox_ClampValue:
	.incbin "includes/generated/v7_transplant_MspMemBox_ClampValue.bin"
MspMemBox_SetReturnZero:
	lds32 xhl, 0

MspMemBox_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0x00, 0x01
	ret
MspMemBox_End:

PsMspRecBnkBoxProc:
	stb_dri L, 0xfd, 0x00, 0xff
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
	.incbin "includes/generated/v7_transplant_MspRecBnkBox_HandleEvtBC.bin"
MspRecBnkBox_CopyMemBlock:
	.incbin "includes/generated/v7_transplant_MspRecBnkBox_CopyMemBlock.bin"
MspRecBnkBox_SetReturnZero:
	lds32 xhl, 0

MspRecBnkBox_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0x00, 0x01
	ret
MspRecBnkBox_End:

PsMspRecPadBoxProc:
	stb_dri L, 0xfd, 0x00, 0xff
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
	.incbin "includes/generated/v7_transplant_MspRecPadBox_HandleEvtBC.bin"
AcSndArgGrid_BnkDispatch:
	.incbin "includes/generated/v7_transplant_AcSndArgGrid_BnkDispatch.bin"
AcSndArgGrid_BnkCase1:
	lds32 xhl, 0

; AcSndArgGridBnk case 2
AcSndArgGrid_BnkCase2:
	pop xiz
	stb_dri L, 0xfd, 0x00, 0x01
	ret

MspPlayModeFunc:
	lda xsp, (xsp - 12)
	push xiz
	ld xiz, xde
	ld xde, xbc
	ld (xsp + 12), xwa
	ld xiy, StrCompileBank1_0x30
	lda xix, (xsp + 4)
	lds bc, 4
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
	lda_24 xix, (MspPlayModeFunc_DataBlock)
	jp_ind 8, 0x07, 0xf0, 0xe0

MspPlayModeFunc_DataBlock:
	.incbin "includes/generated/v7_transplant_MspPlayModeFunc_DataBlock.bin"
AcSndArgGrid_BoxProc:
	ld xwa, 0x1440015
	ld xbc, 0x1e4001f
	ld xde, xiz
	call MainFuncCall

; AcSndArgGridBox case 1
AcSndArgGrid_BoxCase1:
	lds32 xhl, 0
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
	lds bc, 2
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
	lda_24 xix, (AcSndArgGrid_Init)
	jp_ind 8, 0x07, 0xf0, 0xe0

AcSndArgGrid_Init:
	.incbin "includes/generated/v7_transplant_AcSndArgGrid_Init.bin"
AcSndArgGrid_ScrollUp_NoCanScroll:
	.incbin "includes/generated/v7_transplant_AcSndArgGrid_ScrollUp_NoCanScroll.bin"
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
	lds wa, 1

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
	.incbin "includes/generated/v7_transplant_AcSndArgGrid_CopyText.bin"
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
	lds32 xhl, 0
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
	lds32 xhl, 0
	ld xwa, xiy
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, SndArgGridCheck_Return
	cp xwa, 0x6
	jrl gt, SndArgGridCheck_Return
	add xwa, xwa
	add xwa, StrInstantStart_0x3A
	ld wa, (xwa)
	lda_24 xix, (SndArgGridCheck_JumpTableFallthrough)
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
	cps wa, 2
	jr z, SndArgGridCheck_CellSel_Row2
	cps wa, 1
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
	.incbin "includes/generated/v7_transplant_SndArgGridCheck_PlayColAudio.bin"
SndArgGridCheck_PlayCol_1:
	.incbin "includes/generated/v7_transplant_SndArgGridCheck_PlayCol_1.bin"
SndArgGridCheck_PlayCol_2:
	.incbin "includes/generated/v7_transplant_SndArgGridCheck_PlayCol_2.bin"
SndArgGridCheck_PlayCol_3:
	.incbin "includes/generated/v7_transplant_SndArgGridCheck_PlayCol_3.bin"
SndArgGridCheck_PlayCol_4:
	.incbin "includes/generated/v7_transplant_SndArgGridCheck_PlayCol_4.bin"
SndArgGridCheck_PlayCol_Strcpy:
	.incbin "includes/generated/v7_transplant_SndArgGridCheck_PlayCol_Strcpy.bin"
SndArgGridCheck_PlayCol_Send:
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 24)
	ld xbc, 0x1e0008c
	jr SndArgGridCheck_DispatchPlayAudio

SndArgGridCheck_PlayRowAudio:
	.incbin "includes/generated/v7_transplant_SndArgGridCheck_PlayRowAudio.bin"
SndArgGridCheck_PlayRow_1:
	.incbin "includes/generated/v7_transplant_SndArgGridCheck_PlayRow_1.bin"
SndArgGridCheck_PlayRow_2:
	.incbin "includes/generated/v7_transplant_SndArgGridCheck_PlayRow_2.bin"
SndArgGridCheck_PlayRow_3:
	.incbin "includes/generated/v7_transplant_SndArgGridCheck_PlayRow_3.bin"
SndArgGridCheck_PlayRow_4:
	.incbin "includes/generated/v7_transplant_SndArgGridCheck_PlayRow_4.bin"
SndArgGridCheck_PlayRow_Send:
	.incbin "includes/generated/v7_transplant_SndArgGridCheck_PlayRow_Send.bin"
SndArgGridCheck_PlayRow_Finalize:
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 24)
	ld xbc, 0x1e0008c

SndArgGridCheck_DispatchPlayAudio:
	call SendEvent

SndArgGridCheck_ReturnHandled:
	lds32 xhl, 0

SndArgGridCheck_Return:
	pop xiz
	lda xsp, (xsp + 28)
	ret

SndArgTtlCheck:
	.incbin "includes/generated/v7_transplant_SndArgTtlCheck.bin"
ParamList_ReturnZero:
	lds32 xhl, 0
	ret
PsParaListBoxProc_Entry:

PsParaListBoxProc:
	stb_dri L, 0xfd, 0x62, 0xff
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
	stb_dri A, 0xfd, 0x8e, 0x00
	ld xwa, xiz
	call GetClientBox
	stb_dri B, 0xfd, 0x8e, 0x00
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
	lds iz, 1
	jr ParaListBox_DrawLineLoop_Check

ParaListBox_DrawLineLoop_Body:
	ld wa, (xsp + 4)
	mul xwa, xiz
	ldw_sri0 BC, (xsp + 0x008e)
	add bc, wa
	dec 1, bc
	stb_dri W, 0xfd, 0x9a, 0x00
	ld (xwa), bc
	stb_dri A, 0xfd, 0x96, 0x00
	ld de, (xwa)
	ld (xbc), de
	lds de, 7
	call DrawLine
	inc 1, iz

ParaListBox_DrawLineLoop_Check:
	ld xwa, (xsp + 10)
	ld wa, (xwa + 34)
	cp iz, wa
	jr c, ParaListBox_DrawLineLoop_Body
	jrl PsParaListBoxProc_Return

ParaListBox_HandleEvtF:
	.incbin "includes/generated/v7_transplant_ParaListBox_HandleEvtF.bin"
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
	lds32 xhl, 0

; SndArgGridCheck case 3
SndArgGrid_CheckCase3:
	pop xiz
	stb_dri L, 0xfd, 0x9e, 0x00
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
	lda_24 xix, (StylCnvStorBnkSel_DataBlock)
	jp_ind 8, 0x07, 0xf0, 0xe8

StylCnvStorBnkSel_DataBlock:
	.incbin "includes/generated/v7_transplant_StylCnvStorBnkSel_DataBlock.bin"
PsSCTxtBox_EventDispatch:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 92)
	ret
PsSCTxtBoxProc_Entry:

PsSCTxtBoxProc:
	stb_dri L, 0xfd, 0x00, 0xfe
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
	.incbin "includes/generated/v7_transplant_SCTxtBox_HandleEvtBC.bin"
SCTxtBox_SetReturnZero:
	lds32 xhl, 0

SCTxtBox_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0x00, 0x02
	ret
PsSCTxtBox2Proc_Entry:

PsSCTxtBox2Proc:
	stb_dri L, 0xfd, 0x00, 0xfe
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
	.incbin "includes/generated/v7_transplant_SCTxtBox2_HandleEvt89.bin"
SCTxtBox2_HandleEvtBC:
	.incbin "includes/generated/v7_transplant_SCTxtBox2_HandleEvtBC.bin"
SCTxtBox2_SetReturnZero:
	lds32 xhl, 0

SCTxtBox2_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0x00, 0x02
	ret

StylCnvStorOkFunc:
	.incbin "includes/generated/v7_transplant_StylCnvStorOkFunc.bin"
StylCnvStorOkFunc_ReturnZero:
	lds32 xhl, 0
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
	cps	bc, 3
	jr	z, 106
	cps	bc, 2
	jr	z, 95
	cps	bc, 1
	scc16	nz, bc
	ld	(xsp+8), bc
	.byte 0xbf
	ldwio	2, 0
	ld	xiy, xwa
	lda	xix, (xsp+24)
	lds	bc, 4
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
	ldio	63, 0
	nop
	jr	z, 54
	ld	(xsp+20), bc
	.byte 0xbf
	ei	2
	swi	7
	swi	7
	jr	54
	.byte 0xbf
	ldio	2, 1
	nop
	jr	5
	.byte 0xbf
	ldio	2, 0
	nop
	.byte 0xbf
	ldwio	2, 1
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
	cps	iz, 0
	jr	ule, 32
	lda	xwa, (xsp+20)
	lda	xbc, (xsp+16)
	.byte 0x9f
	ldwio	4, 8863
	ldb	b, 30
	.byte 0xd3
	swi	6
	ld	wa, (xsp+6)
	add	(xsp+20), wa
	add	(xsp+16), wa
	incm	1, (xsp+14)
	cp	(xsp+14), iz
	jr	c, -32
	lda	xwa, (xsp+24)
	lda	xbc, (xsp+20)
	.byte 0x9f
	ldio	63, 0
	nop
	jr	z, 14
	ld	wa, (xwa+4)
	sub	wa, iz
	ld	(xbc), wa
	.byte 0xbf
	ei	2
	swi	7
	swi	7
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
	ldwio	4, 8863
	ldb	b, 30
	pop	xde
	swi	6
	ld	wa, (xsp+6)
	add	(xsp+16), wa
	incm	1, (xsp+14)
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
	ldwio	4, 8863
	ldb	b, 30
	reti
	swi	6
	ld	wa, (xsp+6)
	add	(xsp+16), wa
	incm	1, (xsp+14)
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
	cps	bc, 3
	jr	z, 114
	cps	bc, 2
	jr	z, 103
	cps	bc, 1
	scc16	nz, bc
	ld	(xsp+6), bc
	.byte 0xbf
	ldio	2, 0
	nop
	ld	xiy, xwa
	lda	xix, (xsp+26)
	lds	bc, 4
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
	.byte 0xd7
	swi	2
	.byte 0x98
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
	.byte 0xd7
	swi	2
	.byte 0x88
	sub	(xsp+4), wa
	.byte 0x9f, 0x06
	push	xsp
	nop
	nop
	jr	z, 57
	ld	(xsp+22), bc
	ld	wa, (xix)
	.byte 0xd7
	swi	2
	.byte 0xa0
	ld	(xsp+18), wa
	jr	57
	.byte 0xbf
	ei	2
	.byte 0x01
	nop
	jr	5
	.byte 0xbf
	ei	2
	nop
	nop
	.byte 0xbf
	ldio	2, 1
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
	.byte 0xd7
	swi	2
	.byte 0x80
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
	ldio	4, 234
	ld	d, (xbc-97)
	ldb	b, 30
	reti
	swi	5
	lda	xwa, (xsp+22)
	lda	xbc, (xsp+18)
	ld	de, (xbc)
	ld	(xwa), de
	ld	de, (xsp+28)
	ld	(xwa+2), de
	.byte 0x9f
	ldio	4, 159
	ldb	d, 34
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
	ldio	4, 234
	ld	d, (xbc-97)
	ldb	b, 30
	.byte 0xae
	swi	4
	lda	xwa, (xsp+22)
	lda	xbc, (xsp+18)
	ld	de, (xbc)
	ld	(xwa), de
	ld	de, (xsp+32)
	ld	(xwa+2), de
	.byte 0x9f
	ldio	4, 159
	ldb	d, 34
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
	ldio	4, 159
	ldb	d, 34
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
	.byte 0xd7
	swi	2
	.byte 0xa0
	ld	(xbc), wa
	.byte 0x9f, 0x04
	xor	(xwa), xwa
	jr	lt, -78
	.byte 0x50
	jr	14
	ld	wa, (xwa)
	.byte 0xd7
	swi	2
	.byte 0x80
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
	ldio	4, 159
	ldb	d, 34
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
	ldio	4, 159
	ldb	d, 34
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
	lds32	xhl, 0
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
	.incbin "includes/generated/v7_transplant_CmpNameMenu_HandleEvtD.bin"
CmpNameMenu_SetReturnZero:
	lds32 xhl, 0

CmpNameMenu_Epilogue:
	pop xiz
	ret

AttLangCheck:
	cp xbc, 0x1e0009f
	jr nz, AttLangCheck_ReturnZero
	lda_24 xhl, (MSG_ATTENTION_ID_0xC)
	ret

AttLangCheck_ReturnZero:
	lds32 xhl, 0
	ret

SureLangCheck:
	cp xbc, 0x1e0009f
	jr nz, SureLangCheck_ReturnZero
	lda_24 xhl, (MSG_ARE_YOU_SURE_ID_0x1C)
	ret

SureLangCheck_ReturnZero:
	lds32 xhl, 0
	ret

SndMemLangCheck:
	cp xbc, 0x1e0009f
	jr nz, SndMemLangCheck_ReturnZero
	lda_24 xhl, (MSG_CUSTOM_SOUND_COPY_ID_0x8E)
	ret

SndMemLangCheck_ReturnZero:
	lds32 xhl, 0
	ret

SndMem1LangCheck:
	cp xbc, 0x1e0009f
	jr nz, SndMem1LangCheck_ReturnZero
	lda_24 xhl, (MSG_SOUND_GROUP_AFFECTED_ID_0x24)
	ret

SndMem1LangCheck_ReturnZero:
	lds32 xhl, 0
	ret

MemfulLangCheck:
	cp xbc, 0x1e0009f
	jr nz, MemfulLangCheck_ReturnZero
	lda_24 xhl, (MSG_CUSTOM_SOUND_FULL_ID_0x7C)
	ret

MemfulLangCheck_ReturnZero:
	lds32 xhl, 0
	ret

Memful2LangCheck:
	cp xbc, 0x1e0009f
	jr nz, Memful2LangCheck_ReturnZero
	lda_24 xhl, (MSG_CUSTOM_RHYTHMS_AFFECTED_ID_0x1E)
	ret

Memful2LangCheck_ReturnZero:
	lds32 xhl, 0
	ret

StylCnvLangCheck:
	cp xbc, 0x1e0009f
	jr nz, StylCnvLangCheck_ReturnZero
	lda_24 xhl, (MSG_INSERT_STYLE_CONVERT_ID_0x26)
	ret

StylCnvLangCheck_ReturnZero:
	lds32 xhl, 0
	ret

SndArrLangCheck:
	cp xbc, 0x1e0009f
	jr nz, SndArrLangCheck_ReturnZero
	lda_24 xhl, (Hama_ModeInit_Table)
	ret

SndArrLangCheck_ReturnZero:
	lds32 xhl, 0
	ret
PsStylCnvVerProc_Entry:

PsStylCnvVerProc:
	stb_dri L, 0xfd, 0x00, 0xfe
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
	.incbin "includes/generated/v7_transplant_StylCnvVer_HandleEvt89.bin"
StylCnvVer_HandleEvtBC:
	.incbin "includes/generated/v7_transplant_StylCnvVer_HandleEvtBC.bin"
StylCnvVer_SetReturnZero:
	lds32 xhl, 0

StylCnvVer_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0x00, 0x02
	ret


.include "factory_test/test_init.s"
