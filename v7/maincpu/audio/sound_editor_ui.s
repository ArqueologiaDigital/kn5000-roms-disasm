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
	.incbin "includes/generated/v7_block_sebitmap_envcurve5.bin"
SeMenu_CompareScreen_DataTable:
	.incbin "includes/generated/v7_block_semenu_comparescreen_datatable.bin"
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
	.byte 0x7f
	ldw	de, 241
TuningSystem_Handler_Table:
	.incbin "includes/generated/v7_fix_tuningsystem_handler_table.bin"
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
