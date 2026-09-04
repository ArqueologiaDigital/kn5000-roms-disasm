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
	lda xsp, (xsp - 0x26)
	push QIZ
	lda xwa, (xsp + 0x26)
	call SeMenu_ReadObjData
	lds wa, 0
	lds bc, 1
	call SeMenu_StorePartParam
	cp (XSP+0x26),0x00
	jr nz, .Lc_f0a6a1
	ldw WA, 0x0021
	call SeMenu_SetDisplayValue
	lds wa, 1
	jr t, .Lc_f0a70f
.Lc_f0a6a1:
	cp (XSP+0x26),0x01
	jr nz, .Lc_f0a6e6
	lda xwa, (xsp + 0x02)
	call SeMenu_FillObjTable
	lds_erpb 0xfb, 1
.Lc_f0a6b1:
	ld_erpb_rr a, 0xfb
	extz WA
	ld_erpb_rr e, 0xfb
	dec 1,E
	extz DE
	lda xbc, (xsp + 0x02)
	ldb_dri c, 0x07, 0xe4, 0xe8
	extz BC
	call SeMenu_StorePartParam
	incb_erp 0xfb, 1
	cp_erpb 0xfb, 0x08
	jr ule, .Lc_f0a6b1
	pushw 0x0021
	lds wa, 0
	ldw BC, 0x0029
	lds de, 1
	call SeMenu_RegisterElement_Type1
	lds wa, 2
	jr t, .Lc_f0a70f
.Lc_f0a6e6:
	lda xwa, (xsp + 0x02)
	cp (XSP+0x26),0x02
	jr nz, .Lc_f0a715
	call SeMenu_FillEntryTable
	ld C,(XSP+0x02)
	extz BC
	ldw WA, 0x0009
	call SeMenu_StorePartParam
	pushw 0x0021
	lds wa, 0
	ldw BC, 0x005d
	lds de, 1
	call SeMenu_RegisterElement_Type1
	lds wa, 3
.Lc_f0a70f:
	call SeMenu_SetCurrentStep
	jr t, .Lc_f0a755
.Lc_f0a715:
	call SeMenu_FillEntryTable
	ld C,(XSP+0x02)
	extz BC
	ldw WA, 0x000a
	call SeMenu_StorePartParam
	lda xbc, (xsp + 0x02)
	lds wa, 2
	call SeMenu_LoadPartParam
	lda xbc, (xsp + 0x02)
	ld A,(XBC)
	add A,0x0b
	ld (XBC),A
	ld C,A
	extz BC
	lds wa, 2
	call SeMenu_StorePartParam
	pushw 0x0021
	call SeMenu_ShowPopupDialog
	inc 2,XSP
	lds wa, 0
	call SeMenu_SetCurrentStep
	call SeMenu_ResetSubIndex
.Lc_f0a755:
	pop QIZ
	lda xsp, (xsp + 0x26)
	ret
	lda xsp, (xsp - 0x0a)
	push QIZ
	lda xwa, (xsp + 0x0a)
	call SeMenu_ReadObjData
	cp (XSP+0x0a),0x00
	jr nz, .Lc_f0a7e1
	lds_erpb 0xfa, 1
.Lc_f0a772:
	lds_erpb 0xfb, 0
.Lc_f0a775:
	ld_erpb_rr a, 0xfa
	extz WA
	ldb C, 0x04
	addb_erp c, 0xfb
	pushw 0x0027
	lds de, 1
	call SeMenu_RegisterElement_Type1
	incb_erp 0xfb, 1
	cps_erpb 0xfb, 3
	jr c, .Lc_f0a775
	incb_erp 0xfa, 1
	cps_erpb 0xfa, 4
	jr ule, .Lc_f0a772
	pushw 0x0027
	lds wa, 0
	ldw BC, 0x0013
	lds de, 1
	call SeMenu_RegisterElement_Type1
	pushw 0x0027
	lds wa, 0
	ldw BC, 0x0029
	lds de, 1
	call SeMenu_RegisterElement_Type1
	pushw 0x0027
	lds wa, 0
	ldw BC, 0x002a
	lds de, 1
	call SeMenu_RegisterElement_Type1
	lds wa, 1
	call SeMenu_SetCurrentStep
	call SeMenu_AdvanceSubIndex
	lda xwa, (xsp + 0x04)
	call SeMenu_ValidatePartNumber
	ld C,(XSP+0x04)
	extz BC
	lds wa, 0
	call SeMenu_StorePartParam
	jrl t, .Lc_f0a86a
.Lc_f0a7e1:
	lda xwa, (xsp + 0x02)
	call SeMenu_ReadObjParam
	lda xwa, (xsp + 0x06)
	call SeMenu_FillEntryTable
	ld A,(XSP+0x02)
	extz WA
	ld C,(XSP+0x06)
	extz BC
	call SeMenu_StorePartParam
	call SeMenu_AdvanceSubIndex
	cp L,0x0f
	jr ule, .Lc_f0a86a
	lda xbc, (xsp + 0x06)
	ldw WA, 0x000f
	call SeMenu_LoadPartParam
	ld C,(XSP+0x06)
	extz BC
	ldw WA, 0x0010
	call SeMenu_StorePartParam
	lda xbc, (xsp + 0x06)
	ldw WA, 0x000e
	call SeMenu_LoadPartParam
	ld C,(XSP+0x06)
	extz BC
	ldw WA, 0x000f
	call SeMenu_StorePartParam
	lda xbc, (xsp + 0x06)
	ldw WA, 0x000d
	call SeMenu_LoadPartParam
	ld C,(XSP+0x06)
	extz BC
	ldw WA, 0x000e
	call SeMenu_StorePartParam
	ldw WA, 0x000d
	lds bc, 1
	call SeMenu_StorePartParam
	pushw 0x0027
	call SeMenu_ShowPopupDialog
	inc 2,XSP
	lds wa, 1
	call SeMenu_SetupMenuDisplay
	lds wa, 0
	call SeMenu_SetCurrentStep
	call SeMenu_ResetSubIndex
.Lc_f0a86a:
	pop QIZ
	lda xsp, (xsp + 0x0a)
	ret
	lda xsp, (xsp - 0x0a)
	push QIZ
	lda xwa, (xsp + 0x0a)
	call SeMenu_ReadObjData
	cp (XSP+0x0a),0x00
	jr nz, .Lc_f0a8be
	lda xwa, (xsp + 0x02)
	call SeMenu_ValidatePartNumber
	lds_erpb 0xfb, 0
.Lc_f0a88e:
	ld A,(XSP+0x02)
	extz WA
	ldb C, 0x07
	addb_erp c, 0xfb
	pushw 0x0028
	lds de, 1
	call SeMenu_RegisterElement_Type1
	incb_erp 0xfb, 1
	cp_erpb 0xfb, 0x0a
	jr c, .Lc_f0a88e
	lds wa, 1
	call SeMenu_SetCurrentStep
	call SeMenu_AdvanceSubIndex
	lds wa, 0
	lds bc, 1
	call SeMenu_StorePartParam
	jr t, .Lc_f0a900
.Lc_f0a8be:
	lda xwa, (xsp + 0x04)
	call SeMenu_ReadObjParam
	lda xwa, (xsp + 0x06)
	call SeMenu_FillEntryTable
	ld A,(XSP+0x04)
	extz WA
	ld C,(XSP+0x06)
	extz BC
	call SeMenu_StorePartParam
	call SeMenu_AdvanceSubIndex
	cp L,0x0a
	jr ule, .Lc_f0a900
	pushw 0x0028
	call SeMenu_ShowPopupDialog
	inc 2,XSP
	call SeMenu_ApplyPartEdit_Data2_0xDB3
	lds wa, 1
	call SeMenu_SetupMenuDisplay
	lds wa, 0
	call SeMenu_SetCurrentStep
	call SeMenu_ResetSubIndex
.Lc_f0a900:
	pop QIZ
	lda xsp, (xsp + 0x0a)
	ret
	lda xsp, (xsp - 0x0a)
	push QIZ
	lda xwa, (xsp + 0x0a)
	call SeMenu_ReadObjData
	cp (XSP+0x0a),0x00
	jr nz, .Lc_f0a947
	lda xwa, (xsp + 0x02)
	call SeMenu_ValidatePartNumber
	lds_erpb 0xfb, 0
.Lc_f0a924:
	ld A,(XSP+0x02)
	extz WA
	ldb C, 0x11
	addb_erp c, 0xfb
	pushw 0x0029
	lds de, 1
	call SeMenu_RegisterElement_Type1
	incb_erp 0xfb, 1
	cps_erpb 0xfb, 6
	jr c, .Lc_f0a924
	lds wa, 1
	call SeMenu_SetCurrentStep
	jr t, .Lc_f0a9aa
.Lc_f0a947:
	lda xwa, (xsp + 0x04)
	call SeMenu_ReadObjParam
	lda xwa, (xsp + 0x06)
	call SeMenu_FillEntryTable
	ld A,(XSP+0x04)
	extz WA
	ld C,(XSP+0x06)
	extz BC
	call SeMenu_StorePartParam
	call SeMenu_AdvanceSubIndex
	cps l, 5
	jr ule, .Lc_f0a9aa
	lda xbc, (xsp + 0x06)
	lds wa, 3
	call SeMenu_LoadPartParam
	ld C,(XSP+0x06)
	extz BC
	ldw WA, 0x000a
	call SeMenu_StorePartParam
	ldw WA, 0x0009
	lds bc, 0
	call SeMenu_StorePartParam
	pushw 0x0029
	call SeMenu_ShowPopupDialog
	inc 2,XSP
	lds wa, 2
	lds bc, 1
	call SeMenu_ApplyPartEdit_Data2_0x13DE
	lds wa, 1
	call SeMenu_SetupMenuDisplay
	lds wa, 0
	call SeMenu_SetCurrentStep
	call SeMenu_ResetSubIndex
.Lc_f0a9aa:
	pop QIZ
	lda xsp, (xsp + 0x0a)
	ret
	ldw WA, 0x002a
	jr t, .Lc_f0a9b6
.Lc_f0a9b6:
	lda xsp, (xsp - 0x0e)
	push QIZ
	ld (XSP+0x0e),A
	cp (XSP+0x0e),0x2a
	jrl nz, .Lc_f0aa59
	lds_erpb 0xfb, 1
.Lc_f0a9c9:
	lda xwa, (xsp + 0x0c)
	call SeMenu_ReadObjData
	cp (XSP+0x0c),0x00
	jrl nz, .Lc_f0aa71
	ld_erpb_rr a, 0xfb
	extz WA
	lda xbc, (xsp + 0x04)
	call SeMenu_TransferPartValues_EndData
	ld_erpb_rr a, 0xfb
	extz WA
	ld C,(XSP+0x04)
	extz BC
	lda xde, (xsp + 0x02)
	call SeMenu_TransferPartValues
	lds_erpb 0xfa, 0
.Lc_f0a9f7:
	ld C,(XSP+0x02)
	addb_erp c, 0xfa
	extz BC
	ld A,(XSP+0x0e)
	extz WA
	pushw wa
	lds wa, 0
	lds de, 1
	call SeMenu_RegisterElement_Type1
	incb_erp 0xfa, 1
	cps_erpb 0xfa, 4
	jr c, .Lc_f0a9f7
	ld_erpb_rr a, 0xfb
	extz WA
	lda xbc, (xsp + 0x02)
	call SeMenu_TransferPartValues_AltLoop_0x9
	lds_erpb 0xfa, 1
.Lc_f0aa24:
	ld_erpb_rr a, 0xfa
	extz WA
	ld C,(XSP+0x02)
	extz BC
	ld E,(XSP+0x0e)
	extz DE
	pushw de
	lds de, 1
	call SeMenu_RegisterElement_Type1
	incb_erp 0xfa, 1
	cps_erpb 0xfa, 4
	jr ule, .Lc_f0aa24
	lds wa, 1
	call SeMenu_SetCurrentStep
	call SeMenu_AdvanceSubIndex
	ld C,(XSP+0x04)
	extz BC
	lds wa, 0
	call SeMenu_StorePartParam
	jr t, .Lc_f0aab2
.Lc_f0aa59:
	cp (XSP+0x0e),0x2f
	jr nz, .Lc_f0aa65
	lds_erpb 0xfb, 0
	jrl t, .Lc_f0a9c9
.Lc_f0aa65:
	cp (XSP+0x0e),0x39
	jr nz, .Lc_f0aab2
	lds_erpb 0xfb, 2
	jrl t, .Lc_f0a9c9
.Lc_f0aa71:
	lda xwa, (xsp + 0x06)
	call SeMenu_ReadObjParam
	lda xwa, (xsp + 0x08)
	call SeMenu_FillEntryTable
	ld A,(XSP+0x06)
	extz WA
	ld C,(XSP+0x08)
	extz BC
	call SeMenu_StorePartParam
	call SeMenu_AdvanceSubIndex
	cp L,0x08
	jr ule, .Lc_f0aab2
	ld A,(XSP+0x0e)
	extz WA
	pushw wa
	call SeMenu_ShowPopupDialog
	inc 2,XSP
	lds wa, 1
	call SeMenu_SetupMenuDisplay
	lds wa, 0
	call SeMenu_SetCurrentStep
	call SeMenu_ResetSubIndex
.Lc_f0aab2:
	pop QIZ
	lda xsp, (xsp + 0x0e)
	ret
	lda	xsp, (xsp-12)
	lda	xwa, (xsp+10)
	call	15757661
	lda	xwa, (xsp)
	call	15766913
	.byte 0x8f, 0x0a, 0x3f, 0x00
	jr	nz, 44
	.byte 0x87, 0x3f, 0x00
	jr	nz, 5
	calr	197
	jr	3
	calr	240
	lds	wa, 1
	call	15757666
	call	15757677
	lda	xwa, (xsp+4)
	call	15755792
	ld	c, (xsp+4)
	extz	bc
	lds	wa, 0
	call	15756036
	jrl	157
	lda	xwa, (xsp+2)
	call	15757693
	lda	xwa, (xsp+6)
	call	15757724
	ld	a, (xsp+2)
	extz	wa
	ld	c, (xsp+6)
	extz	bc
	call	15756036
	.byte 0x87, 0x3f, 0x00
	jr	nz, 116
	call	15757677
	cp	l, 12
	jr	ule, 115
	lda	xbc, (xsp+6)
	lds	wa, 1
	call	15767749
	ld	c, (xsp+6)
	extz	bc
	lds	wa, 1
	call	15756036
	lda	xbc, (xsp+6)
	lds	wa, 2
	call	15767749
	ld	c, (xsp+6)
	extz	bc
	lds	wa, 2
	call	15756036
	lda	xbc, (xsp+6)
	lds	wa, 3
	call	15767749
	ld	c, (xsp+6)
	extz	bc
	lds	wa, 3
	call	15756036
	lda	xbc, (xsp+6)
	lds	wa, 4
	call	15767749
	ld	c, (xsp+6)
	extz	bc
	lds	wa, 4
	call	15756036
	pushw 43
	call	15789632
	inc	2, xsp
	lds	wa, 1
	call	15755525
	lds	wa, 0
	call	15757666
	call	15757671
	jr	8
	call	15757677
	cps	l, 4
	jr	ugt, -35
	lda	xsp, (xsp+12)
	ret
	.byte 0xd7, 0xfa, 0x04
	ldib_erp	250, 0
	ldib_erp	251, 1
	stb_erp	a, 251
	extz	wa
	ldb	c, 23
	addb_erp	c, 250
	pushw 43
	lds	de, 1
	call	15753743
	inc1b_erp	251
	cpib_erp	251, 4
	jr	ule, -27
	inc1b_erp	250
	cpib_erp	250, 3
	jr	c, -38
	pop qiz
	ret
	.byte 0xd7, 0xfa, 0x04
	ldib_erp	250, 0
	ldib_erp	251, 0
	stb_erp	a, 251
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	inc	6, xwa
	addb_erp	a, 250
	ld	c, a
	pushw 43
	lds	wa, 0
	lds	de, 1
	call	15754165
	inc1b_erp	251
	cpib_erp	251, 2
	jr	c, -40
	inc1b_erp	250
	cpib_erp	250, 2
	jr	c, -51
	pop qiz
	ret
	lda xsp, (xsp - 0x0a)
	push QIZ
	lda xwa, (xsp + 0x0a)
	call SeMenu_ReadObjData
	cp (XSP+0x0a),0x00
	jr nz, .Lc_f0ac49
	lda xwa, (xsp + 0x02)
	call SeMenu_ValidatePartNumber
	lds_erpb 0xfb, 0
.Lc_f0ac26:
	ld A,(XSP+0x02)
	extz WA
	ldb C, 0x1a
	addb_erp c, 0xfb
	pushw 0x002c
	lds de, 1
	call SeMenu_RegisterElement_Type1
	incb_erp 0xfb, 1
	cps_erpb 0xfb, 4
	jr c, .Lc_f0ac26
	lds wa, 1
	call SeMenu_SetCurrentStep
	jr t, .Lc_f0aca3
.Lc_f0ac49:
	lda xwa, (xsp + 0x04)
	call SeMenu_ReadObjParam
	lda xwa, (xsp + 0x06)
	call SeMenu_FillEntryTable
	ld A,(XSP+0x04)
	extz WA
	ld C,(XSP+0x06)
	extz BC
	call SeMenu_StorePartParam
	call SeMenu_AdvanceSubIndex
	cps l, 3
	jr ule, .Lc_f0aca3
	pushw 0x002c
	call SeMenu_ShowPopupDialog
	inc 2,XSP
	lda xbc, (xsp + 0x06)
	lds wa, 3
	call SeMenu_LoadPartParam
	ld C,(XSP+0x06)
	extz BC
	ldw WA, 0x000a
	call SeMenu_StorePartParam
	lds wa, 0
	lds bc, 0
	call SeMenu_ApplyPartEdit_Data2_0x13DE
	lds wa, 1
	call SeMenu_SetupMenuDisplay
	lds wa, 0
	call SeMenu_SetCurrentStep
	call SeMenu_ResetSubIndex
.Lc_f0aca3:
	pop QIZ
	lda xsp, (xsp + 0x0a)
	ret
	lda	xsp, (xsp-10)
	lda	xwa, (xsp+8)
	call	15757661
	lda	xwa, (xsp)
	call	15766913
	.byte 0x8f, 0x08, 0x3f, 0x00
	jr	nz, 21
	.byte 0x87, 0x3f, 0x00
	jr	nz, 5
	calr	97
	jr	3
	calr	140
	lds	wa, 1
	call	15757666
	jr	80
	lda	xwa, (xsp+2)
	call	15757693
	lda	xwa, (xsp+4)
	call	15757724
	ld	a, (xsp+2)
	extz	wa
	ld	c, (xsp+4)
	extz	bc
	call	15756036
	.byte 0x87, 0x3f, 0x00
	jr	nz, 10
	call	15757677
	cps	l, 6
	jr	ugt, 10
	jr	37
	call	15757677
	cps	l, 7
	jr	ule, 29
	pushw 45
	call	15789632
	inc	2, xsp
	call	15761579
	lds	wa, 0
	call	15757666
	lds	wa, 1
	call	15755525
	call	15757671
	lda	xsp, (xsp+10)
	ret
	dec	2, xsp
	.byte 0xd7, 0xfa, 0x04
	lda	xwa, (xsp+2)
	call	15755792
	ldib_erp	251, 0
	ld	a, (xsp+2)
	extz	wa
	ldb	c, 39
	addb_erp	c, 251
	pushw 45
	lds	de, 1
	call	15753743
	inc1b_erp	251
	cpib_erp	251, 7
	jr	c, -27
	pop qiz
	inc	2, xsp
	ret
	dec	2, xsp
	.byte 0xd7, 0xfa, 0x04
	lda	xwa, (xsp+2)
	call	15755792
	pushw 45
	lds	wa, 0
	ldw	bc, 13
	lds	de, 1
	call	15754165
	ldib_erp	251, 0
	ld	a, (xsp+2)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	inc	8, xwa
	addb_erp	a, 251
	ld	c, a
	pushw 45
	lds	wa, 0
	lds	de, 1
	call	15754165
	inc1b_erp	251
	cpib_erp	251, 7
	jr	c, -42
	pop qiz
	inc	2, xsp
	ret
	lda xsp, (xsp - 0x0a)
	push QIZ
	lda xwa, (xsp + 0x0a)
	call SeMenu_ReadObjData
	cp (XSP+0x0a),0x00
	jr nz, .Lc_f0ade7
	lda xwa, (xsp + 0x02)
	call SeMenu_ValidatePartNumber
	lds_erpb 0xfb, 0
.Lc_f0adc3:
	ld A,(XSP+0x02)
	extz WA
	ldb C, 0x2e
	addb_erp c, 0xfb
	pushw 0x002e
	lds de, 1
	call SeMenu_RegisterElement_Type1
	incb_erp 0xfb, 1
	cp_erpb 0xfb, 0x08
	jr c, .Lc_f0adc3
	lds wa, 1
	call SeMenu_SetCurrentStep
	jr t, .Lc_f0ae4a
.Lc_f0ade7:
	lda xwa, (xsp + 0x04)
	call SeMenu_ReadObjParam
	lda xwa, (xsp + 0x06)
	call SeMenu_FillEntryTable
	ld A,(XSP+0x04)
	extz WA
	ld C,(XSP+0x06)
	extz BC
	call SeMenu_StorePartParam
	call SeMenu_AdvanceSubIndex
	cps l, 7
	jr ule, .Lc_f0ae4a
	lda xbc, (xsp + 0x06)
	lds wa, 5
	call SeMenu_LoadPartParam
	ld C,(XSP+0x06)
	extz BC
	ldw WA, 0x000a
	call SeMenu_StorePartParam
	ldw WA, 0x0009
	lds bc, 0
	call SeMenu_StorePartParam
	pushw 0x002e
	call SeMenu_ShowPopupDialog
	inc 2,XSP
	lds wa, 2
	lds bc, 0
	call SeMenu_ApplyPartEdit_Data2_0x13DE
	lds wa, 1
	call SeMenu_SetupMenuDisplay
	lds wa, 0
	call SeMenu_SetCurrentStep
	call SeMenu_ResetSubIndex
.Lc_f0ae4a:
	pop QIZ
	lda xsp, (xsp + 0x0a)
	ret
	ldw	wa, 47
	jrl	-1185
	lda	xsp, (xsp-10)
	lda	xwa, (xsp+8)
	call	15757661
	lda	xwa, (xsp)
	call	15766913
	.byte 0x8f, 0x08, 0x3f, 0x00
	jr	nz, 21
	.byte 0x87, 0x3f, 0x00
	jr	nz, 5
	calr	116
	jr	3
	calr	235
	lds	wa, 1
	call	15757666
	jr	99
	lda	xwa, (xsp+2)
	call	15757693
	lda	xwa, (xsp+4)
	call	15757724
	ld	a, (xsp+2)
	extz	wa
	ld	c, (xsp+4)
	extz	bc
	call	15756036
	call	15757677
	cp	l, 8
	jr	ule, 62
	lda	xbc, (xsp+4)
	lds	wa, 7
	call	15756049
	ld	c, (xsp+4)
	extz	bc
	ldw	wa, 11
	call	15756036
	lda	xbc, (xsp+4)
	ldw	wa, 8
	call	15756049
	ld	c, (xsp+4)
	extz	bc
	ldw	wa, 12
	call	15756036
	pushw 59
	call	15789632
	inc	2, xsp
	lds	wa, 0
	call	15757666
	call	15757671
	lda	xsp, (xsp+10)
	ret
	dec	4, xsp
	.byte 0xd7, 0xfa, 0x04, 0xc7, 0xfb, 0xa8, 0xc7, 0xfb, 0x89
	mul	a, 3
	add	a, 24
	ld	c, a
	pushw 59
	lds	wa, 0
	lds	de, 1
	call	15753743
	inc1b_erp	251
	cpib_erp	251, 6
	jr	c, -30
	lda	xwa, (xsp+4)
	call	15756849
	ld	a, (xsp+4)
	extz	wa
	lda	xbc, (xsp+2)
	call	15756871
	ld	c, (xsp+2)
	inc	2, c
	extz	bc
	pushw 59
	lds	wa, 0
	lds	de, 1
	call	15753743
	ld	c, (xsp+2)
	extz	bc
	pushw 59
	lds	wa, 0
	lds	de, 1
	call	15753743
	ld	c, (xsp+2)
	extz	bc
	ldw	wa, 13
	call	15756036
	call	15757677
	ld	c, (xsp+4)
	extz	bc
	lds	wa, 0
	call	15756036
	pop qiz
	inc	4, xsp
	ret
	dec	4, xsp
	.byte 0xd7, 0xfa, 0x04, 0xc7, 0xfb, 0xa8, 0xc7, 0xfb, 0x89
	mul	a, 3
	add	a, 22
	ld	c, a
	pushw 59
	lds	wa, 3
	lds	de, 1
	call	15754165
	inc1b_erp	251
	cpib_erp	251, 6
	jr	c, -30
	lda	xwa, (xsp+4)
	call	15756849
	ld	a, (xsp+4)
	extz	wa
	lda	xbc, (xsp+2)
	call	15756900
	ld	c, (xsp+2)
	inc	2, c
	extz	bc
	pushw 59
	lds	wa, 3
	lds	de, 1
	call	15754165
	ld	c, (xsp+2)
	extz	bc
	pushw 59
	lds	wa, 3
	lds	de, 1
	call	15754165
	ld	c, (xsp+2)
	extz	bc
	ldw	wa, 13
	call	15756036
	call	15757677
	ld	c, (xsp+4)
	extz	bc
	lds	wa, 0
	call	15756036
	pop qiz
	inc	4, xsp
	ret
	dec	6, xsp
	lda	xwa, (xsp+4)
	call	15757661
	.byte 0x8f, 0x04, 0x3f, 0x00
	jr	nz, 18
	pushw 60
	lds	wa, 0
	ldw	bc, 16
	lds	de, 1
	call	15753743
	lds	wa, 1
	jr	28
	lda	xwa, (xsp)
	call	15757724
	ld	c, (xsp+256)
	extz	bc
	lds	wa, 0
	call	15756036
	pushw 60
	call	15789632
	inc	2, xsp
	lds	wa, 0
	call	15757666
	inc	6, xsp
	ret
	lda	xsp, (xsp-10)
	lda	xwa, (xsp+8)
	call	15757661
	lda	xwa, (xsp)
	call	15766913
	.byte 0x8f, 0x08, 0x3f, 0x00
	jr	nz, 21
	.byte 0x87, 0x3f, 0x00
	jr	nz, 5
	calr	144
	jr	3
	calr	217
	lds	wa, 1
	call	15757666
	jr	127
	lda	xwa, (xsp+2)
	call	15757693
	lda	xwa, (xsp+4)
	call	15757724
	ld	a, (xsp+2)
	extz	wa
	ld	c, (xsp+4)
	extz	bc
	call	15756036
	call	15757677
	cps	l, 5
	jr	ule, 91
	lda	xbc, (xsp+4)
	lds	wa, 0
	call	15756049
	.byte 0x8f, 0x04, 0x3c, 0x07
	lds	wa, 0
	call	15757666
	call	15757671
	lda	xbc, (xsp+4)
	ld	a, (xbc)
	cps	a, 1
	jr	ule, 17
	cps	a, 5
	jr	ugt, 13
	dec	1, a
	ld	(xbc), a
	add	a, 48
	extz	wa
	lds	bc, 0
	jr	9
	cps	a, 0
	jr	nz, 11
	ldw	wa, 53
	lds	bc, 0
	call	15753542
	jr	27
	pushw 48
	call	15789632
	inc	2, xsp
	lds	wa, 0
	lds	bc, 0
	call	15765079
	call	15765503
	lds	wa, 1
	call	15755525
	lda	xsp, (xsp+10)
	ret
	dec	2, xsp
	.byte 0xd7, 0xfa, 0x04
	lda	xwa, (xsp+2)
	call	15755792
	ldib_erp	251, 0
	ld	a, (xsp+2)
	extz	wa
	ldb	c, 54
	addb_erp c, 251
	pushw 48
	lds	de, 1
	call	15753743
	inc1b_erp	251
	cpib_erp	251, 2
	jr	c, -27
	ldib_erp	251, 0
	ld	a, (xsp+2)
	extz	wa
	ldb	c, 77
	addb_erp c, 251
	pushw 48
	lds	de, 1
	call	15753743
	inc1b_erp 251
	cpib_erp 251, 4
	jr	c, -27
	pop qiz
	inc	2, xsp
	ret
	dec	2, xsp
	.byte 0xd7, 0xfa, 0x04
	lda	xwa, (xsp+2)
	call	15755792
	ldib_erp 251, 0
	ld	a, (xsp+2)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	lda	xwa, (xwa+15)
	addb_erp a, 251
	ld	c, a
	pushw 48
	lds	wa, 0
	lds	de, 1
	call	15754165
	inc1b_erp 251
	cpib_erp 251, 6
	jr	c, -43
	pop qiz
	inc	2, xsp
	ret
	pushw 0x0031
	call SeMenu_ShowPopupDialog
	inc 2,XSP
	lds wa, 1
	lds bc, 0
	call SeMenu_ApplyPartEdit_Data2_0x1815
	call SeMenu_ApplyPartEdit_Data2_0x19BD
	lds wa, 1
	jp SeMenu_SetupMenuDisplay
	pushw 0x0032
	call SeMenu_ShowPopupDialog
	inc 2,XSP
	lds wa, 0
	lds bc, 1
	call SeMenu_ApplyPartEdit_Data2_0x1815
	lds wa, 1
	jp SeMenu_SetupMenuDisplay
	pushw 0x0033
	call SeMenu_ShowPopupDialog
	inc 2,XSP
	lds wa, 1
	lds bc, 1
	call SeMenu_ApplyPartEdit_Data2_0x1815
	lds wa, 1
	jp SeMenu_SetupMenuDisplay
	pushw 0x0034
	call SeMenu_ShowPopupDialog
	inc 2,XSP
	call SeMenu_ApplyPartEdit_Data2_0x1AAD
	lds wa, 1
	jp SeMenu_SetupMenuDisplay
	pushw 0x0035
	call SeMenu_ShowPopupDialog
	inc 2,XSP
	lds wa, 1
	jp SeMenu_SetupMenuDisplay
	lda xsp, (xsp - 0x0a)
	push QIZ
	lda xwa, (xsp + 0x0a)
	call SeMenu_ReadObjData
	cp (XSP+0x0a),0x00
	jr nz, .Lc_f0b20c
	lda xwa, (xsp + 0x02)
	call SeMenu_ValidatePartNumber
	lds_erpb 0xfb, 0
.Lc_f0b1e9:
	ld A,(XSP+0x02)
	extz WA
	ldb C, 0x39
	addb_erp c, 0xfb
	pushw 0x0036
	lds de, 1
	call SeMenu_RegisterElement_Type1
	incb_erp 0xfb, 1
	cps_erpb 0xfb, 4
	jr c, .Lc_f0b1e9
	lds wa, 1
	call SeMenu_SetCurrentStep
	jr t, .Lc_f0b266
.Lc_f0b20c:
	lda xwa, (xsp + 0x04)
	call SeMenu_ReadObjParam
	lda xwa, (xsp + 0x06)
	call SeMenu_FillEntryTable
	ld A,(XSP+0x04)
	extz WA
	ld C,(XSP+0x06)
	extz BC
	call SeMenu_StorePartParam
	call SeMenu_AdvanceSubIndex
	cps l, 3
	jr ule, .Lc_f0b266
	lda xbc, (xsp + 0x06)
	lds wa, 3
	call SeMenu_LoadPartParam
	ld C,(XSP+0x06)
	extz BC
	ldw WA, 0x000a
	call SeMenu_StorePartParam
	pushw 0x0036
	call SeMenu_ShowPopupDialog
	inc 2,XSP
	lds wa, 0
	lds bc, 0
	call SeMenu_ApplyPartEdit_Data2_0x13DE
	lds wa, 1
	call SeMenu_SetupMenuDisplay
	lds wa, 0
	call SeMenu_SetCurrentStep
	call SeMenu_ResetSubIndex
.Lc_f0b266:
	pop QIZ
	lda xsp, (xsp + 0x0a)
	ret
	lda xsp, (xsp - 0x0a)
	push QIZ
	lda xwa, (xsp + 0x0a)
	call SeMenu_ReadObjData
	cp (XSP+0x0a),0x00
	jr nz, .Lc_f0b2ba
	lda xwa, (xsp + 0x02)
	call SeMenu_ValidatePartNumber
	lds_erpb 0xfb, 0
.Lc_f0b28a:
	ld A,(XSP+0x02)
	extz WA
	ldb C, 0x3d
	addb_erp c, 0xfb
	pushw 0x0037
	lds de, 1
	call SeMenu_RegisterElement_Type1
	incb_erp 0xfb, 1
	cp_erpb 0xfb, 0x0a
	jr c, .Lc_f0b28a
	lds wa, 1
	call SeMenu_SetCurrentStep
	call SeMenu_AdvanceSubIndex
	lds wa, 0
	lds bc, 1
	call SeMenu_StorePartParam
	jr t, .Lc_f0b2fc
.Lc_f0b2ba:
	lda xwa, (xsp + 0x04)
	call SeMenu_ReadObjParam
	lda xwa, (xsp + 0x06)
	call SeMenu_FillEntryTable
	ld A,(XSP+0x04)
	extz WA
	ld C,(XSP+0x06)
	extz BC
	call SeMenu_StorePartParam
	call SeMenu_AdvanceSubIndex
	cp L,0x0a
	jr ule, .Lc_f0b2fc
	pushw 0x0037
	call SeMenu_ShowPopupDialog
	inc 2,XSP
	call SeMenu_ApplyPartEdit_Data2_0xDB3
	lds wa, 1
	call SeMenu_SetupMenuDisplay
	lds wa, 0
	call SeMenu_SetCurrentStep
	call SeMenu_ResetSubIndex
.Lc_f0b2fc:
	pop QIZ
	lda xsp, (xsp + 0x0a)
	ret
	lda xsp, (xsp - 0x0a)
	push QIZ
	lda xwa, (xsp + 0x0a)
	call SeMenu_ReadObjData
	cp (XSP+0x0a),0x00
	jr nz, .Lc_f0b343
	lda xwa, (xsp + 0x02)
	call SeMenu_ValidatePartNumber
	lds_erpb 0xfb, 0
.Lc_f0b320:
	ld A,(XSP+0x02)
	extz WA
	ldb C, 0x47
	addb_erp c, 0xfb
	pushw 0x0038
	lds de, 1
	call SeMenu_RegisterElement_Type1
	incb_erp 0xfb, 1
	cps_erpb 0xfb, 6
	jr c, .Lc_f0b320
	lds wa, 1
	call SeMenu_SetCurrentStep
	jr t, .Lc_f0b3a6
.Lc_f0b343:
	lda xwa, (xsp + 0x04)
	call SeMenu_ReadObjParam
	lda xwa, (xsp + 0x06)
	call SeMenu_FillEntryTable
	ld A,(XSP+0x04)
	extz WA
	ld C,(XSP+0x06)
	extz BC
	call SeMenu_StorePartParam
	call SeMenu_AdvanceSubIndex
	cps l, 5
	jr ule, .Lc_f0b3a6
	lda xbc, (xsp + 0x06)
	lds wa, 3
	call SeMenu_LoadPartParam
	ld C,(XSP+0x06)
	extz BC
	ldw WA, 0x000a
	call SeMenu_StorePartParam
	ldw WA, 0x0009
	lds bc, 0
	call SeMenu_StorePartParam
	pushw 0x0038
	call SeMenu_ShowPopupDialog
	inc 2,XSP
	lds wa, 2
	lds bc, 1
	call SeMenu_ApplyPartEdit_Data2_0x13DE
	lds wa, 1
	call SeMenu_SetupMenuDisplay
	lds wa, 0
	call SeMenu_SetCurrentStep
	call SeMenu_ResetSubIndex
.Lc_f0b3a6:
	pop QIZ
	lda xsp, (xsp + 0x0a)
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
	lda xsp, (xsp - 0x0a)
	push QIZ
	lda xwa, (xsp + 0x0a)
	call SeMenu_ReadObjData
	cp (XSP+0x0a),0x00
	jr nz, .Lc_f0b5ad
	pushw 0x0023
	lds wa, 0
	ldw BC, 0x0012
	lds de, 1
	call SeMenu_RegisterElement_Type1
	lds_erpb 0xfb, 1
.Lc_f0b54e:
	ld_erpb_rr a, 0xfb
	extz WA
	pushw 0x0023
	lds bc, 0
	lds de, 1
	call SeMenu_RegisterElement_Type1
	incb_erp 0xfb, 1
	cps_erpb 0xfb, 4
	jr ule, .Lc_f0b54e
	lds_erpb 0xfb, 1
.Lc_f0b569:
	ld_erpb_rr a, 0xfb
	extz WA
	pushw 0x0023
	lds bc, 1
	lds de, 1
	call SeMenu_RegisterElement_Type1
	incb_erp 0xfb, 1
	cps_erpb 0xfb, 4
	jr ule, .Lc_f0b569
	pushw 0x0023
	lds wa, 0
	ldw BC, 0x005c
	lds de, 1
	call SeMenu_RegisterElement_Type1
	lds wa, 1
	call SeMenu_SetCurrentStep
	call SeMenu_AdvanceSubIndex
	lda xwa, (xsp + 0x02)
	call SeMenu_ValidatePartNumber
	ld C,(XSP+0x02)
	extz BC
	lds wa, 0
	call SeMenu_StorePartParam
	jr t, .Lc_f0b5ff
.Lc_f0b5ad:
	lda xwa, (xsp + 0x04)
	call SeMenu_ReadObjParam
	lda xwa, (xsp + 0x06)
	call SeMenu_FillEntryTable
	ld A,(XSP+0x04)
	extz WA
	ld C,(XSP+0x06)
	extz BC
	call SeMenu_StorePartParam
	call SeMenu_AdvanceSubIndex
	cp L,0x0a
	jr ule, .Lc_f0b5ff
	lds_erpb 0xfb, 1
.Lc_f0b5d5:
	ld_erpb_rr a, 0xfb
	extz WA
	call SeMenu_ApplyPartEdit
	incb_erp 0xfb, 1
	cps_erpb 0xfb, 4
	jr ule, .Lc_f0b5d5
	pushw 0x0023
	call SeMenu_ShowPopupDialog
	inc 2,XSP
	lds wa, 1
	call SeMenu_SetupMenuDisplay
	lds wa, 0
	call SeMenu_SetCurrentStep
	call SeMenu_ResetSubIndex
.Lc_f0b5ff:
	pop QIZ
	lda xsp, (xsp + 0x0a)
	ret
	lda xsp, (xsp - 0x0a)
	push QIZ
	lda xwa, (xsp + 0x0a)
	call SeMenu_ReadObjData
	cp (XSP+0x0a),0x00
	jr nz, .Lc_f0b67e
	lda xwa, (xsp + 0x02)
	call SeMenu_ValidatePartNumber
	lds_erpb 0xfa, 0
.Lc_f0b623:
	ld A,(XSP+0x02)
	extz WA
	ldb C, 0x1e
	addb_erp c, 0xfa
	pushw 0x0024
	lds de, 1
	call SeMenu_RegisterElement_Type1
	incb_erp 0xfa, 1
	cps_erpb 0xfa, 4
	jr c, .Lc_f0b623
	lds_erpb 0xfb, 1
.Lc_f0b641:
	lds_erpb 0xfa, 0
.Lc_f0b644:
	ld_erpb_rr a, 0xfb
	extz WA
	ldb C, 0x1e
	addb_erp c, 0xfa
	pushw 0x0024
	lds de, 1
	call SeMenu_RegisterElement_Type1
	incb_erp 0xfa, 1
	cps_erpb 0xfa, 4
	jr c, .Lc_f0b644
	incb_erp 0xfb, 1
	cps_erpb 0xfb, 4
	jr ule, .Lc_f0b641
	lds wa, 1
	call SeMenu_SetCurrentStep
	call SeMenu_AdvanceSubIndex
	ld C,(XSP+0x02)
	extz BC
	lds wa, 0
	call SeMenu_StorePartParam
	jr t, .Lc_f0b6de
.Lc_f0b67e:
	lda xwa, (xsp + 0x04)
	call SeMenu_ReadObjParam
	lda xwa, (xsp + 0x06)
	call SeMenu_FillEntryTable
	ld A,(XSP+0x04)
	extz WA
	ld C,(XSP+0x06)
	extz BC
	call SeMenu_StorePartParam
	call SeMenu_AdvanceSubIndex
	cp L,0x14
	jr ule, .Lc_f0b6de
	pushw 0x0024
	call SeMenu_ShowPopupDialog
	inc 2,XSP
	lds_erpb 0xfa, 1
.Lc_f0b6af:
	ld_erpb_rr c, 0xfa
	extz BC
	ld_erpb_rr a, 0xfa
	sll A, 0x02
	inc 1,A
	ld E,A
	extz DE
	lds wa, 0
	call SeMenu_ApplyPartEdit_Data2_0x162C
	incb_erp 0xfa, 1
	cps_erpb 0xfa, 4
	jr ule, .Lc_f0b6af
	lds wa, 1
	call SeMenu_SetupMenuDisplay
	lds wa, 0
	call SeMenu_SetCurrentStep
	call SeMenu_ResetSubIndex
.Lc_f0b6de:
	pop QIZ
	lda xsp, (xsp + 0x0a)
	ret
	lda xsp, (xsp - 0x0a)
	push QIZ
	lda xwa, (xsp + 0x0a)
	call SeMenu_ReadObjData
	cp (XSP+0x0a),0x00
	jr nz, .Lc_f0b75d
	lda xwa, (xsp + 0x02)
	call SeMenu_ValidatePartNumber
	lds_erpb 0xfa, 0
.Lc_f0b702:
	ld A,(XSP+0x02)
	extz WA
	ldb C, 0x22
	addb_erp c, 0xfa
	pushw 0x0025
	lds de, 1
	call SeMenu_RegisterElement_Type1
	incb_erp 0xfa, 1
	cps_erpb 0xfa, 4
	jr c, .Lc_f0b702
	lds_erpb 0xfb, 1
.Lc_f0b720:
	lds_erpb 0xfa, 0
.Lc_f0b723:
	ld_erpb_rr a, 0xfb
	extz WA
	ldb C, 0x22
	addb_erp c, 0xfa
	pushw 0x0025
	lds de, 1
	call SeMenu_RegisterElement_Type1
	incb_erp 0xfa, 1
	cps_erpb 0xfa, 4
	jr c, .Lc_f0b723
	incb_erp 0xfb, 1
	cps_erpb 0xfb, 4
	jr ule, .Lc_f0b720
	lds wa, 1
	call SeMenu_SetCurrentStep
	call SeMenu_AdvanceSubIndex
	ld C,(XSP+0x02)
	extz BC
	lds wa, 0
	call SeMenu_StorePartParam
	jr t, .Lc_f0b7bd
.Lc_f0b75d:
	lda xwa, (xsp + 0x04)
	call SeMenu_ReadObjParam
	lda xwa, (xsp + 0x06)
	call SeMenu_FillEntryTable
	ld A,(XSP+0x04)
	extz WA
	ld C,(XSP+0x06)
	extz BC
	call SeMenu_StorePartParam
	call SeMenu_AdvanceSubIndex
	cp L,0x14
	jr ule, .Lc_f0b7bd
	pushw 0x0025
	call SeMenu_ShowPopupDialog
	inc 2,XSP
	lds_erpb 0xfa, 1
.Lc_f0b78e:
	ld_erpb_rr c, 0xfa
	extz BC
	ld_erpb_rr a, 0xfa
	sll A, 0x02
	inc 1,A
	ld E,A
	extz DE
	lds wa, 1
	call SeMenu_ApplyPartEdit_Data2_0x162C
	incb_erp 0xfa, 1
	cps_erpb 0xfa, 4
	jr ule, .Lc_f0b78e
	lds wa, 1
	call SeMenu_SetupMenuDisplay
	lds wa, 0
	call SeMenu_SetCurrentStep
	call SeMenu_ResetSubIndex
.Lc_f0b7bd:
	pop QIZ
	lda xsp, (xsp + 0x0a)
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
	lda	xsp, (xsp-24)
	.byte 0xd7, 0xfa, 0x04
	lda	xwa, (xsp+2)
	call	15767349
	.byte 0x8f, 0x02, 0x3f, 0x01
	jr	nz, 15
	lds	wa, 2
	call	15753592
	lds	wa, 0
	call	15767354
	jrl	209
	lda	xwa, (xsp+24)
	call	15757661
	.byte 0x8f, 0x18, 0x3f, 0x00
	jr	nz, 23
	pushw 62
	lds	wa, 0
	lds	bc, 0
	ldw	de, 16
	call	15753743
	lds	wa, 1
	call	15757666
	jrl	173
	lda	xwa, (xsp+6)
	call	15757724
	ldib_erp	251, 0
	stb_erp	a, 251
	extz	wa
	lda	xbc, (xsp+6)
	lda_rr	xbc, xbc, wa
	ld	xwa, xbc
	call	16458804
	inc1b_erp	251
	cp_erpb	251, 16
	jr	c, -28
	lda	xbc, (xsp+6)
	lds	wa, 1
	ldw	de, 16
	call	15757801
	lda	xwa, (xsp+4)
	call	15758177
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
	ld	wa, qwa
	ld	(xbc), a
	incm8	1, (xde)
	incm8	1, (xbc)
	ld	c, (xde)
	extz	bc
	lds	wa, 0
	call	15756036
	ld	c, (xsp+7)
	extz	bc
	lds	wa, 1
	call	15756036
	pushw 62
	call	15789632
	inc	2, xsp
	lds	wa, 1
	call	15758419
	lds	wa, 0
	ldw	bc, 11
	lds	de, 0
	call	15758425
	lds	wa, 1
	ldw	bc, 12
	lds	de, 0
	call	15758425
	lds	wa, 0
	call	15757666
	ldw	wa, 30
	lds	bc, 0
	call	15756036
	call	15757671
	pop qiz
	lda	xsp, (xsp+24)
	ret
	dec	2, xsp
	lda	xwa, (xsp)
	call	15766913
	ldb	a, 13
	.byte 0x87, 0x3f, 0x01
	jr	z, 2
	ldb	a, 16
	extz	wa
	call	15786696
	inc	2, xsp
	ret
	lda xsp, (xsp - 0x0a)
	push QIZ
	lda xwa, (xsp + 0x0a)
	call SeMenu_ReadObjData
	cp (XSP+0x0a),0x00
	jr nz, .Lc_f0baeb
	lds wa, 1
	call SeMenu_SetDisplayState
	lds_erpb 0xfb, 0
.Lc_f0baca:
	ldb C, 0x5d
	addb_erp c, 0xfb
	pushw 0x003a
	lds wa, 0
	lds de, 1
	call SeMenu_RegisterElement_Type1
	incb_erp 0xfb, 1
	cp_erpb 0xfb, 0x09
	jr c, .Lc_f0baca
	lds wa, 1
	call SeMenu_SetCurrentStep
	jr t, .Lc_f0bb4c
.Lc_f0baeb:
	lda xwa, (xsp + 0x04)
	call SeMenu_ReadObjParam
	lda xwa, (xsp + 0x06)
	call SeMenu_FillEntryTable
	ld A,(XSP+0x04)
	extz WA
	ld C,(XSP+0x06)
	extz BC
	call SeMenu_StorePartParam
	call SeMenu_AdvanceSubIndex
	cp L,0x08
	jr ule, .Lc_f0bb4c
	lda xbc, (xsp + 0x02)
	lds wa, 0
	call SeMenu_LoadPartParam
	ld A,(XSP+0x02)
	and A,0x0f
	cp A,0x0b
	jr ule, .Lc_f0bb33
	and (XSP+0x02),0xf0
	ld C,(XSP+0x02)
	extz BC
	lds wa, 0
	call SeMenu_StorePartParam
.Lc_f0bb33:
	pushw 0x003a
	call SeMenu_ShowPopupDialog
	inc 2,XSP
	lds wa, 0
	call SeMenu_SetCurrentStep
	call SeMenu_ResetSubIndex
	lds wa, 0
	call SeMenu_SetDisplayState
.Lc_f0bb4c:
	pop QIZ
	lda xsp, (xsp + 0x0a)
	ret
	lda xsp, (xsp - 0x14)
	lda xwa, (xsp + 0x12)
	call SeMenu_ReadObjData
	cp (XSP+0x12),0x00
	jr nz, .Lc_f0bb75
	pushw 0x003d
	lds wa, 0
	lds bc, 0
	ldw DE, 0x000d
	call SeMenu_RegisterElement_Type2
	lds wa, 1
	jr t, .Lc_f0bba4
.Lc_f0bb75:
	lda XWA, (XSP)
	call SeMenu_FillEntryTable
	lda XBC, (XSP)
	ld XWA,XBC
	lda xde, (xbc + 0x0d)
.Lc_f0bb82:
	cp (XWA),0x7f
	jr ule, .Lc_f0bb8a
	ld (XWA),0x20
.Lc_f0bb8a:
	inc 1,XWA
	cp XWA,XDE
	jr c, .Lc_f0bb82
	lds wa, 1
	ldw DE, 0x000d
	call SeMenu_SetupPartDisplay
	pushw 0x003d
	call SeMenu_ShowPopupDialog
	inc 2,XSP
	lds wa, 0
.Lc_f0bba4:
	call SeMenu_SetCurrentStep
	lda xsp, (xsp + 0x14)
	ret
	lds wa, 0
	call SeMenu_SetCurrentStep
	jp SeMenu_ResetSubIndex
	ret
	lds wa, 0
	call SeMenu_SetCurrentStep
	jp SeMenu_ResetSubIndex
	ret
	lds wa, 0
	call SeMenu_SetCurrentStep
	jp SeMenu_ResetSubIndex
	ret
	lds wa, 0
	call SeMenu_SetCurrentStep
	jp SeMenu_ResetSubIndex
	ret
	lds wa, 0
	call SeMenu_SetCurrentStep
	jp SeMenu_ResetSubIndex
	ret
	lds wa, 0
	call SeMenu_SetCurrentStep
	jp SeMenu_ResetSubIndex
	ret
	lds wa, 0
	call SeMenu_SetCurrentStep
	jp SeMenu_ResetSubIndex
	ret
	lds wa, 0
	call SeMenu_SetCurrentStep
	jp SeMenu_ResetSubIndex
	ret
	lds wa, 0
	call SeMenu_SetCurrentStep
	jp SeMenu_ResetSubIndex
	ret
	lds wa, 0
	call SeMenu_SetCurrentStep
	jp SeMenu_ResetSubIndex
	ret
	.byte 0xd8, 0xa8, 0x1d, 0x62, 0x71, 0xf0, 0x1b, 0x67
	.byte 0x71, 0xf0, 0x0e
	lds wa, 0
	call SeMenu_SetCurrentStep
	jp SeMenu_ResetSubIndex
	ret
	lds wa, 0
	call SeMenu_SetCurrentStep
	jp SeMenu_ResetSubIndex
	ret
	lds wa, 0
	call SeMenu_SetCurrentStep
	jp SeMenu_ResetSubIndex
	ret
	lds wa, 0
	call SeMenu_SetCurrentStep
	jp SeMenu_ResetSubIndex
	ret
	lds wa, 0
	call SeMenu_SetCurrentStep
	jp SeMenu_ResetSubIndex
	ret
	lds wa, 0
	call SeMenu_SetCurrentStep
	jp SeMenu_ResetSubIndex
	ret
	lds wa, 0
	call SeMenu_SetCurrentStep
	jp SeMenu_ResetSubIndex
	ret
	lds wa, 0
	call SeMenu_SetCurrentStep
	jp SeMenu_ResetSubIndex
	ret
	lds wa, 0
	call SeMenu_SetCurrentStep
	jp SeMenu_ResetSubIndex
	ret
	lds wa, 0
	call SeMenu_SetCurrentStep
	jp SeMenu_ResetSubIndex
	ret
	lds wa, 0
	call SeMenu_SetCurrentStep
	jp SeMenu_ResetSubIndex
	ret
	lds wa, 0
	call SeMenu_SetCurrentStep
	jp SeMenu_ResetSubIndex
	ret
	lds wa, 0
	call SeMenu_SetCurrentStep
	jp SeMenu_ResetSubIndex
	ret
	lds wa, 0
	call SeMenu_SetCurrentStep
	jp SeMenu_ResetSubIndex
	ret
	lds wa, 0
	call SeMenu_SetCurrentStep
	jp SeMenu_ResetSubIndex
	ret
	lds wa, 0
	call SeMenu_SetCurrentStep
	jp SeMenu_ResetSubIndex
	ret
	lds wa, 0
	call SeMenu_SetCurrentStep
	jp SeMenu_ResetSubIndex
	ret
	ret
	ret
	ret
	ret
	lds wa, 0
	call SeMenu_SetCurrentStep
	jp SeMenu_ResetSubIndex
	ret
	lds wa, 0
	call SeMenu_SetCurrentStep
	jp SeMenu_ResetSubIndex
	ret
	lds wa, 0
	call SeMenu_SetCurrentStep
	jp SeMenu_ResetSubIndex
	ret
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeMenu_SetupPartDisplay_End_0x90
	cp HL,0xffff
	jr z, .Lc_f0bd30
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (GUI_DisplayStructData_0x136F:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f0bd30:
	inc 4,XSP
	ret
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeMenu_SetupPartDisplay_End_0x90
	cp HL,0xffff
	jr z, .Lc_f0bd5e
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (GUI_DisplayStructData_0x13B7:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f0bd5e:
	inc 4,XSP
	ret
	extz	wa
	lds	bc, 2
	jp	15761290
	extz	wa
	jp	15761503
	ld	c, a
	extz	bc
	lds	wa, 1
	jp	15761547
	ld	c, a
	extz	bc
	lds	wa, 2
	jp	15761547
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	15766913
	.byte 0x87, 0x3f, 0x01
	jr	z, 11
	ld	c, (xsp+2)
	extz	bc
	lds	wa, 3
	call	15761547
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	15766913
	.byte 0x87, 0x3f, 0x01
	jr	z, 11
	ld	c, (xsp+2)
	extz	bc
	lds	wa, 4
	call	15761547
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xbc, (xsp)
	lds	wa, 0
	call	15756049
	.byte 0x8f, 0x02, 0x3f, 0x00
	jr	nz, 9
	.byte 0x87, 0x3f, 0x02
	jr	z, 24
	lds	wa, 2
	jr	7
	.byte 0x87, 0x3f, 0x01
	jr	z, 15
	lds	wa, 1
	call	15756866
	ldw	wa, 59
	lds	bc, 1
	call	15753542
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xbc, (xsp)
	lds	wa, 0
	call	15756049
	.byte 0x8f, 0x02, 0x3f, 0x00
	jr	nz, 9
	.byte 0x87, 0x3f, 0x06
	jr	z, 24
	lds	wa, 6
	jr	7
	.byte 0x87, 0x3f, 0x05
	jr	z, 15
	lds	wa, 5
	call	15756866
	ldw	wa, 59
	lds	bc, 1
	call	15753542
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	15766913
	.byte 0x87, 0x3f, 0x01
	jr	z, 15
	.byte 0x8f, 0x02, 0x3f, 0x00
	jr	nz, 9
	ldw	wa, 60
	lds	bc, 0
	call	15753542
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	15766913
	.byte 0x8f, 0x02, 0x3f, 0x00
	jr	nz, 21
	.byte 0x87, 0x3f, 0x00
	jr	nz, 7
	ldw	wa, 32
	lds	bc, 0
	jr	5
	ldw	wa, 61
	lds	bc, 0
	call	15753542
	inc	4, xsp
	ret
	lda	xsp, (xsp-14)
	ld	(xsp+12), a
	lda	xbc, (xsp)
	lds	wa, 0
	call	15756049
	lda	xbc, (xsp)
	ld	(xbc+6), 1
	ld	(xbc+7), 4
	ld	(xbc+8), 1
	ld	(xbc+9), 0
	ld	a, (xsp+12)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758482
	pushw 16
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 60
	lds	bc, 0
	lds	de, 0
	call	15757069
	lds	wa, 3
	call	15758447
	lda	xsp, (xsp+14)
	ret
	lda	xsp, (xsp-14)
	ld	(xsp+12), a
	lda	xbc, (xsp)
	lds	wa, 0
	call	15756049
	lda	xbc, (xsp)
	ld	(xbc+6), 1
	ld	(xbc+7), 5
	ld	(xbc+8), 1
	ld	(xbc+9), 0
	ld	a, (xsp+12)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758482
	pushw 16
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 60
	lds	bc, 0
	lds	de, 0
	call	15757069
	lds	wa, 6
	call	15758447
	lda	xsp, (xsp+14)
	ret
	cps	a, 0
	ret	z
	ldw	wa, 59
	lds	bc, 0
	call	15753542
	ret
	cps	a, 0
	ret	nz
	ldw	wa, 32
	lds	bc, 0
	call	15753542
	ret
	lda xsp, (xsp - 0x0c)
	pushw iz
	ld (XSP+0x0c),BC
	ld IZ,WA
	lda xwa, (xsp + 0x06)
	call SeMenu_LoadPatchStatus
	cp (XSP+0x06),0x00
	jr nz, .Lc_f0bf3f
	lda xwa, (xsp + 0x02)
	call SeMenu_DisplayState_Data
	cp (XSP+0x02),0x00
	jr nz, .Lc_f0bf8f
.Lc_f0bf3f:
	lda xde, (xsp + 0x0a)
	lda xwa, (xsp + 0x08)
	push XWA
	ld WA,IZ
	ld BC,(XSP+0x10)
	call SeMenu_SetupPartDisplay_End_0x90
	cp HL,0xffff
	jr z, .Lc_f0bf8f
	call SeMenu_OrPartConfig_Data_0x6
	cps l, 0
	jr z, .Lc_f0bf6c
	lda xwa, (xsp + 0x04)
	call SeMenu_DisplayState_Data_0xA
	ld A,(XSP+0x0a)
	cp A,(XSP+0x04)
	jr nz, .Lc_f0bf8f
.Lc_f0bf6c:
	ld A,(XSP+0x0a)
	extz WA
	call SeMenu_DisplayState_Data_0x5
	ld A,(XSP+0x08)
	extz WA
	ld C,(XSP+0x0a)
	extz BC
	sla BC, 0x02
	lda xde, (GUI_DisplayStructData_0x13FF:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f0bf8f:
	popw iz
	lda xsp, (xsp + 0x0c)
	ret
	dec	6, xsp
	.byte 0xd7, 0xfa, 0x04
	ld	(xsp+6), a
	lda	xwa, (xsp+2)
	call	15766913
	.byte 0x8f, 0x02, 0x3f, 0x00
	jr	z, 81
	lda	xwa, (xsp+2)
	call	15767359
	.byte 0x8f, 0x02, 0x3f, 0x01
	jr	z, 68
	ld	a, (xsp+6)
	res	7, a
	ldb_erp	a, 251
	lda	xbc, (xsp+4)
	lds	wa, 0
	call	15756049
	ld	a, (xsp+4)
	extz	wa
	call	15756001
	ld	a, (xsp+4)
	extz	wa
	cps	hl, 0
	jr	z, 9
	cpib_erp	251, 0
	jr	z, 27
	lds	bc, 0
	jr	7
	cpib_erp	251, 0
	jr	nz, 18
	lds	bc, 1
	call	15755899
	pushw 2
	pushw 32
	call	15789873
	inc	4, xsp
	pop qiz
	inc	6, xsp
	ret
	lda	xsp, (xsp-12)
	ld	(xsp+10), a
	lda	xwa, (xsp+6)
	call	15766913
	.byte 0x8f, 0x06, 0x3f, 0x00
	jr	z, 117
	lda	xwa, (xsp+6)
	call	15767359
	.byte 0x8f, 0x06, 0x3f, 0x01
	jr	z, 104
	lda	xbc, (xsp)
	lds	wa, 0
	call	15756049
	ld	c, (xsp)
	extz	bc
	lda	xde, (xsp+4)
	lds	wa, 3
	call	15766845
	lda	xwa, (xsp+2)
	call	15766214
	ld	a, (xsp+10)
	res	7, a
	cps	a, 0
	jr	nz, 15
	ld	a, (xsp+2)
	dec	1, a
	cp	(xsp+4), a
	jr	nc, 56
	incm8	1, (xsp+4)
	jr	9
	.byte 0x8f, 0x04, 0x3f, 0x00
	jr	z, 45
	decm8	1, (xsp+4)
	ld	c, (xsp+4)
	extz	bc
	lda	xde, (xsp+8)
	lds	wa, 3
	call	15766762
	ld	a, (xsp)
	extz	wa
	ld	bc, (xsp+8)
	call	15754341
	ld	a, (xsp)
	extz	wa
	ldw	bc, 16
	call	15753900
	lds	wa, 2
	call	15758447
	lda	xsp, (xsp+12)
	ret
	lda	xsp, (xsp-10)
	ld	(xsp+8), a
	lda	xwa, (xsp+6)
	call	15766913
	.byte 0x8f, 0x06, 0x3f, 0x00
	jr	z, 104
	lda	xwa, (xsp+6)
	call	15767359
	.byte 0x8f, 0x06, 0x3f, 0x01
	jr	z, 91
	lda	xbc, (xsp+4)
	lds	wa, 0
	call	15756049
	ld	a, (xsp+4)
	extz	wa
	lda	xbc, (xsp+2)
	call	15766181
	lda	xwa, (xsp)
	call	15766204
	ld	a, (xsp+8)
	res	7, a
	cps	a, 0
	jr	nz, 14
	ld	wa, (xsp)
	dec	1, wa
	cp	(xsp+2), wa
	jr	nc, 45
	incw	1, (xsp+2)
	jr	10
	.byte 0x9f, 0x02, 0x3f, 0x00, 0x00
	jr	z, 33
	decm	1, (xsp+2)
	ld	a, (xsp+4)
	extz	wa
	ld	bc, (xsp+2)
	call	15754341
	ld	a, (xsp+4)
	extz	wa
	ldw	bc, 16
	call	15753900
	lds	wa, 3
	call	15758447
	lda	xsp, (xsp+10)
	ret
	lda	xsp, (xsp-18)
	.byte 0xd7, 0xfa, 0x04
	ld	(xsp+18), a
	lda	xwa, (xsp+14)
	call	15766913
	.byte 0x8f, 0x0e, 0x3f, 0x00
	jrl	z, 133
	lda	xwa, (xsp+14)
	call	15767359
	.byte 0x8f, 0x0e, 0x3f, 0x01
	jr	z, 120
	lda	xbc, (xsp+16)
	lds	wa, 0
	call	15756049
	ld	a, (xsp+16)
	inc	2, a
	ldb_erp	a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	15756049
	lda	xbc, (xsp+2)
	ld	(xbc+6), 127
	ld	(xbc+7), 0
	ld	(xbc+8), 127
	ld	(xbc+9), 0
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758482
	stb_erp	c, 251
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
	lds	de, 0
	call	15757069
	cps	l, 1
	jr	nz, 14
	ld	a, (xsp+16)
	extz	wa
	ld	c, (xsp+5)
	extz	bc
	call	15767734
	lds	wa, 4
	call	15758447
	pop qiz
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-18)
	.byte 0xd7, 0xfa, 0x04
	ld	(xsp+18), a
	lda	xwa, (xsp+14)
	call	15766913
	.byte 0x8f, 0x0e, 0x3f, 0x00
	jr	z, 115
	lda	xwa, (xsp+14)
	call	15767359
	.byte 0x8f, 0x0e, 0x3f, 0x01
	jr	z, 102
	lda	xbc, (xsp+16)
	lds	wa, 0
	call	15756049
	ld	a, (xsp+16)
	inc	4, a
	ldb_erp	a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	15756049
	lda	xbc, (xsp+2)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758482
	stb_erp	c, 251
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
	lds	de, 0
	call	15757069
	lds	wa, 5
	call	15758447
	pop qiz
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-18)
	.byte 0xd7, 0xfa, 0x04
	ld	(xsp+18), a
	lda	xwa, (xsp+14)
	call	15766913
	.byte 0x8f, 0x0e, 0x3f, 0x00
	jr	z, 115
	lda	xwa, (xsp+14)
	call	15767359
	.byte 0x8f, 0x0e, 0x3f, 0x01
	jr	z, 102
	lda	xbc, (xsp+16)
	lds	wa, 0
	call	15756049
	ld	a, (xsp+16)
	inc	6, a
	ldb_erp	a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	15756049
	lda	xbc, (xsp+2)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+18)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758482
	stb_erp	c, 251
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
	lds	de, 0
	call	15757069
	lds	wa, 6
	call	15758447
	pop qiz
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-10)
	.byte 0xd7, 0xfa, 0x04
	ld	(xsp+10), a
	lda	xwa, (xsp+4)
	call	15766913
	.byte 0x8f, 0x04, 0x3f, 0x00
	jrl	z, 199
	lda	xwa, (xsp+4)
	call	15767359
	.byte 0x8f, 0x04, 0x3f, 0x01
	jrl	z, 185
	lda	xbc, (xsp+8)
	lds	wa, 0
	call	15756049
	ld	a, (xsp+8)
	inc	8, a
	ldb_erp	a, 250
	ld	a, (xsp+10)
	extz	wa
	lda	xbc, (xsp+2)
	call	15758482
	ld	a, (xsp+10)
	res	7, a
	ldb_erp	a, 251
	stb_erp	a, 250
	extz	wa
	lda	xbc, (xsp+6)
	call	15756049
	.byte 0xbf, 0x06, 0xb7
	cpib_erp	251, 0
	jr	nz, 24
	.byte 0x8f, 0x06, 0x3f, 0x7f
	jr	nc, 121
	ld	a, (xsp+2)
	add	(xsp+6), a
	.byte 0x8f, 0x06, 0x3f, 0x7f
	jr	c, 29
	ld	(xsp+6), 127
	jr	23
	.byte 0x8f, 0x06, 0x3f, 0x00
	jr	z, 97
	ld	a, (xsp+6)
	.byte 0x8f, 0x02, 0x81
	ld	(xsp+6), a
	cps	a, 0
	jr	ge, 4
	ld	(xsp+6), 0
	stb_erp	a, 250
	extz	wa
	ld	c, (xsp+6)
	extz	bc
	call	15756036
	ld	a, (xsp+8)
	dec	1, a
	extz	wa
	muls	wa, 21
	extz	xwa
	lda	xwa, (xwa+16)
	ld	c, a
	lda	xde, (xsp+6)
	pushw 127
	lds	wa, 0
	call	15754738
	ld	a, (xsp+8)
	extz	wa
	call	15758689
	ld	a, (xsp+8)
	add	a, 12
	ldb_erp	a, 250
	extz	wa
	pushw	wa
	pushw 32
	call	15789873
	inc	4, xsp
	lds	wa, 7
	call	15758447
	pop qiz
	lda	xsp, (xsp+10)
	ret
	lda	xsp, (xsp-16)
	ld	(xsp+14), a
	lda	xwa, (xsp+12)
	call	15766913
	.byte 0x8f, 0x0c, 0x3f, 0x00
	jr	z, 78
	lda	xwa, (xsp+12)
	call	15767359
	.byte 0x8f, 0x0c, 0x3f, 0x01
	jr	z, 65
	lda	xbc, (xsp)
	ldw	wa, 11
	call	15756049
	lda	xbc, (xsp)
	ld	(xbc+6), 127
	ld	(xbc+7), 0
	ld	(xbc+8), 127
	ld	(xbc+9), 0
	ld	a, (xsp+14)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758482
	pushw 15
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 32
	ldw	bc, 11
	lds	de, 0
	call	15757069
	ldw	wa, 8
	call	15758447
	lda	xsp, (xsp+16)
	ret
	lda	xsp, (xsp-10)
	ld	(xsp+8), a
	lda	xwa, (xsp+2)
	call	15766913
	.byte 0x8f, 0x02, 0x3f, 0x00
	jr	nz, 51
	.byte 0x8f, 0x08, 0x3f, 0x00
	jr	nz, 28
	lda	xbc, (xsp)
	lds	wa, 1
	call	15756049
	.byte 0x87, 0x3f, 0x00
	scc	z, a
	extz	wa
	call	15754857
	ldw	wa, 16
	call	15754282
	jr	83
	lds	wa, 0
	call	15767354
	ldw	wa, 62
	lds	bc, 0
	call	15753542
	jr	66
	lda	xwa, (xsp+2)
	call	15767359
	.byte 0x8f, 0x02, 0x3f, 0x01
	jr	z, 53
	.byte 0x8f, 0x08, 0x3f, 0x00
	jr	nz, 47
	lda	xwa, (xsp+6)
	call	15766928
	lda	xwa, (xsp+4)
	call	15766938
	ld	wa, (xsp+4)
	dec	1, wa
	cp	(xsp+6), wa
	jr	nc, 23
	incw	1, (xsp+6)
	ld	wa, (xsp+6)
	call	15754651
	ldw	wa, 32
	lds	bc, 0
	call	15753542
	call	15767719
	lda	xsp, (xsp+10)
	ret
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp)
	call	15766913
	.byte 0x87, 0x3f, 0x00
	jr	nz, 20
	.byte 0x8f, 0x04, 0x3f, 0x00
	jr	nz, 7
	ldw	wa, 33
	lds	bc, 0
	jr	35
	ldw	wa, 34
	lds	bc, 0
	jr	28
	lda	xwa, (xsp)
	call	15767359
	.byte 0x87, 0x3f, 0x01
	jr	nz, 23
	.byte 0x8f, 0x04, 0x3f, 0x00
	jr	nz, 15
	lds	wa, 0
	call	15767364
	ldw	wa, 32
	lds	bc, 1
	call	15753542
	jr	43
	.byte 0x8f, 0x04, 0x3f, 0x00
	jr	nz, 37
	lda	xwa, (xsp+2)
	call	15766928
	.byte 0x9f, 0x02, 0x3f, 0x00, 0x00
	jr	z, 23
	decm	1, (xsp+2)
	ld	wa, (xsp+2)
	call	15754651
	ldw	wa, 32
	lds	bc, 0
	call	15753542
	call	15767719
	inc	6, xsp
	ret
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp+2)
	call	15766913
	.byte 0x8f, 0x02, 0x3f, 0x00
	jr	nz, 24
	.byte 0x8f, 0x04, 0x3f, 0x00
	jr	nz, 7
	ldw	wa, 36
	lds	bc, 0
	jr	5
	ldw	wa, 43
	lds	bc, 0
	call	15753542
	jr	84
	lda	xwa, (xsp+2)
	call	15767359
	.byte 0x8f, 0x02, 0x3f, 0x01
	jr	nz, 26
	.byte 0x8f, 0x04, 0x3f, 0x00
	jr	nz, 18
	lds	wa, 0
	call	15757666
	lds	wa, 0
	call	15767364
	lds	wa, 2
	call	15753592
	jr	45
	.byte 0x8f, 0x04, 0x3f, 0x00
	jr	z, 39
	lda	xbc, (xsp)
	lds	wa, 0
	call	15756049
	.byte 0x87, 0x3f, 0x01
	jr	z, 26
	lds	wa, 0
	lds	bc, 1
	call	15756036
	lds	wa, 1
	call	15755773
	pushw 0
	pushw 32
	call	15789873
	inc	4, xsp
	inc	6, xsp
	ret
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp+2)
	call	15766913
	.byte 0x8f, 0x02, 0x3f, 0x00
	jr	nz, 24
	.byte 0x8f, 0x04, 0x3f, 0x00
	jr	nz, 7
	ldw	wa, 58
	lds	bc, 0
	jr	5
	ldw	wa, 39
	lds	bc, 0
	call	15753542
	jr	58
	lda	xwa, (xsp+2)
	call	15767359
	.byte 0x8f, 0x02, 0x3f, 0x01
	jr	z, 45
	.byte 0x8f, 0x04, 0x3f, 0x00
	jr	z, 39
	lda	xbc, (xsp)
	lds	wa, 0
	call	15756049
	.byte 0x87, 0x3f, 0x02
	jr	z, 26
	lds	wa, 0
	lds	bc, 2
	call	15756036
	lds	wa, 2
	call	15755773
	pushw 0
	pushw 32
	call	15789873
	inc	4, xsp
	inc	6, xsp
	ret
	dec	6, xsp
	ld	(xsp+4), a
	lda	xwa, (xsp+2)
	call	15766913
	lda	xwa, (xsp+2)
	.byte 0x8f, 0x04, 0x3f, 0x00
	jr	nz, 32
	.byte 0x8f, 0x02, 0x3f, 0x00
	jr	nz, 7
	ldw	wa, 59
	lds	bc, 0
	jr	30
	call	15767359
	.byte 0x8f, 0x02, 0x3f, 0x01
	jr	z, 105
	ldw	wa, 61
	call	15758567
	jr	96
	.byte 0x8f, 0x02, 0x3f, 0x00
	jr	nz, 11
	ldw	wa, 48
	lds	bc, 0
	call	15753542
	jr	79
	call	15767359
	.byte 0x8f, 0x02, 0x3f, 0x01
	jr	z, 69
	call	15767725
	cps	l, 0
	jr	nz, 61
	lda	xwa, (xsp)
	call	15753611
	ld	a, (xsp)
	extz	wa
	lds	bc, 0
	lds	de, 1
	call	16670253
	cp	l, 255
	jr	nz, 17
	ld	a, (xsp)
	extz	wa
	lds	bc, 1
	lds	de, 1
	call	16670253
	cp	l, 255
	jr	z, 21
	lds	wa, 1
	call	15766968
	ldw	wa, 32
	lds	bc, 0
	call	15753542
	lds	wa, 0
	call	15757666
	inc	6, xsp
	ret
	cps	a, 0
	ret	nz
	lds	wa, 0
	call	15757666
	lds	wa, 0
	call	15767364
	lds	wa, 2
	call	15753592
	ret
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeMenu_SetupPartDisplay_End_0x90
	cp HL,0xffff
	jr z, .Lc_f0c6da
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (ToneGen_ParamTable_0x1E:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f0c6da:
	inc 4,XSP
	ret
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeMenu_SetupPartDisplay_End_0x90
	cp HL,0xffff
	jr z, .Lc_f0c708
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (ToneGen_ParamTable_0x66:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f0c708:
	inc 4,XSP
	ret
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeMenu_SetupPartDisplay_End_0x90
	cp HL,0xffff
	jr z, .Lc_f0c736
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (ToneGen_ParamTable_0xAE:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f0c736:
	inc 4,XSP
	ret
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeMenu_SetupPartDisplay_End_0x90
	cp HL,0xffff
	jr z, .Lc_f0c764
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (ToneGen_ParamTable_0xF6:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f0c764:
	inc 4,XSP
	ret
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeMenu_SetupPartDisplay_End_0x90
	cp HL,0xffff
	jr z, .Lc_f0c792
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (ToneGen_ParamTable_0x13E:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f0c792:
	inc 4,XSP
	ret
	dec	4, xsp
	.byte 0xd7, 0xfa, 0x04
	ld	(xsp+4), a
	lda	xbc, (xsp+2)
	lds	wa, 0
	call	15756049
	ld	a, (xsp+4)
	res	7, a
	ldb_erp	a, 251
	ld	a, (xsp+2)
	extz	wa
	call	15756001
	ld	a, (xsp+2)
	extz	wa
	cps	hl, 0
	jr	z, 9
	cpib_erp	251, 0
	jr	z, 33
	lds	bc, 0
	jr	7
	cpib_erp	251, 0
	jr	nz, 24
	lds	bc, 1
	call	15755899
	.byte 0x0b, 0x01, 0x00, 0x0b, 0x22, 0x00
	call	15789873
	inc	4, xsp
	lds	wa, 1
	call	15755525
	pop qiz
	inc	4, xsp
	ret
	lda	xsp, (xsp-10)
	ld	(xsp+8), a
	lda	xbc, (xsp+2)
	lds	wa, 0
	call	15756049
	ld	c, (xsp+2)
	extz	bc
	lda	xde, (xsp+6)
	lds	wa, 0
	call	15766845
	lda	xwa, (xsp+4)
	call	15766214
	ld	a, (xsp+8)
	res	7, a
	cps	a, 0
	jr	nz, 15
	ld	a, (xsp+4)
	dec	1, a
	cp	(xsp+6), a
	jr	nc, 56
	incm8	1, (xsp+6)
	jr	9
	.byte 0x8f, 0x06, 0x3f, 0x00
	jr	z, 45
	decm8	1, (xsp+6)
	ld	c, (xsp+6)
	extz	bc
	lda	xde, (xsp)
	lds	wa, 0
	call	15766762
	ld	a, (xsp+2)
	extz	wa
	ld	bc, (xsp)
	call	15754341
	ld	a, (xsp+2)
	extz	wa
	ldw	bc, 16
	call	15753900
	lds	wa, 2
	call	15758447
	lda	xsp, (xsp+10)
	ret
	dec	8, xsp
	ld	(xsp+6), a
	lda	xbc, (xsp+4)
	lds	wa, 0
	call	15756049
	ld	a, (xsp+4)
	extz	wa
	lda	xbc, (xsp+2)
	call	15766181
	lda	xwa, (xsp)
	call	15766204
	ld	a, (xsp+6)
	res	7, a
	cps	a, 0
	jr	nz, 14
	ld	wa, (xsp)
	dec	1, wa
	cp	(xsp+2), wa
	jr	nc, 45
	incw	1, (xsp+2)
	jr	10
	.byte 0x9f, 0x02, 0x3f, 0x00, 0x00
	jr	z, 33
	decm	1, (xsp+2)
	ld	a, (xsp+4)
	extz	wa
	ld	bc, (xsp+2)
	call	15754341
	ld	a, (xsp+4)
	extz	wa
	ldw	bc, 16
	call	15753900
	lds	wa, 3
	call	15758447
	inc	8, xsp
	ret
	lda	xsp, (xsp-16)
	.byte 0xd7, 0xfa, 0x04
	ld	(xsp+16), a
	lda	xbc, (xsp+14)
	lds	wa, 0
	call	15756049
	ld	a, (xsp+14)
	mul	a, 3
	ldb_erp	a, 251
	dec1b_erp	251
	stb_erp	a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	15756049
	lda	xbc, (xsp+2)
	ld	(xbc+6), 127
	ld	(xbc+7), 0
	ld	(xbc+8), 127
	ld	(xbc+9), 0
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758482
	stb_erp	c, 251
	extz	bc
	ld	e, (xsp+14)
	extz	de
	pushw 23
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 34
	call	15757069
	cps	l, 1
	jr	nz, 14
	ld	a, (xsp+14)
	extz	wa
	ld	c, (xsp+5)
	extz	bc
	call	15767734
	lds	wa, 6
	call	15758447
	pop qiz
	lda	xsp, (xsp+16)
	ret
	lda	xsp, (xsp-16)
	.byte 0xd7, 0xfa, 0x04
	ld	(xsp+16), a
	lda	xbc, (xsp+14)
	lds	wa, 0
	call	15756049
	ld	a, (xsp+14)
	mul	a, 3
	ldb_erp	a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	15756049
	lda	xbc, (xsp+2)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 24
	ld	(xbc+9), 232
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758482
	stb_erp	c, 251
	extz	bc
	ld	e, (xsp+14)
	extz	de
	.byte 0x0b, 0x04, 0x00
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 34
	call	15757069
	lds	wa, 7
	call	15758447
	pop qiz
	lda	xsp, (xsp+16)
	ret
	lda	xsp, (xsp-16)
	.byte 0xd7, 0xfa, 0x04
	ld	(xsp+16), a
	lda	xbc, (xsp+14)
	lds	wa, 0
	call	15756049
	ld	a, (xsp+14)
	mul	a, 3
	ldb_erp a, 251
	inc1b_erp 251
	stb_erp a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	15756049
	lda	xbc, (xsp+2)
	ld	(xbc+6), 255
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 206
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758482
	stb_erp	c, 251
	extz	bc
	ld	e, (xsp+14)
	extz	de
	pushw 5
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 34
	call	15757069
	ldw	wa, 8
	call	15758447
	pop qiz
	lda	xsp, (xsp+16)
	ret
	cps	a, 0
	ret	z
	call	15756503
	ret
	cps	a, 0
	ret	z
	ldw	wa, 34
	lds	bc, 1
	lds	de, 0
	call	15764995
	ret
	cps	a, 0
	ret	z
	ldw	wa, 34
	lds	bc, 2
	lds	de, 0
	call	15764995
	ret
	cps	a, 0
	ret	z
	ldw	wa, 34
	lds	bc, 3
	lds	de, 0
	call	15764995
	ret
	cps	a, 0
	ret	z
	ldw	wa, 34
	lds	bc, 4
	lds	de, 0
	call	15764995
	ret
	cps	a, 0
	ret	nz
	ldw	wa, 38
	call	15758567
	ret
	cps	a, 0
	ret	nz
	ldw	wa, 32
	call	15758567
	lds	wa, 0
	call	15755525
	ret
	dec	8, xsp
	.byte 0xd7, 0xfa, 0x04
	ld	(xsp+8), a
	lda	xwa, (xsp+6)
	call	15755792
	lda	xbc, (xsp+4)
	lds	wa, 1
	call	15756049
	ld	a, (xsp+6)
	inc	1, a
	extz	wa
	lda	xbc, (xsp+2)
	call	15756049
	ld	a, (xsp+4)
	extz	wa
	ld	c, (xsp+6)
	.byte 0x8f, 0x06, 0x83
	dec	2, c
	extz	bc
	call	15756084
	ldb_erp l, 250
	and_erpb 250, 3
	ld	a, (xsp+8)
	res	7, a
	cps	a, 0
	jr	nz, 24
	.byte 0xbf, 0x02, 0xcf
	jrl	nz, 171
	cpib_erp 250, 1
	jr	nz, 8
	.byte 0xbf, 0x02, 0xbf, 0xc7, 0xfa, 0xa8
	jr	27
	inc1b_erp	250
	jr	22
	.byte 0xbf, 0x02, 0xcf
	jr	z, 8
	.byte 0xbf, 0x02, 0xb7, 0xc7, 0xfa, 0xa9
	jr	9
	cpib_erp	250, 0
	jrl	z, 134
	dec1b_erp	250
	ld	a, (xsp+6)
	.byte 0x8f, 0x06, 0x81
	dec	2, a
	ld	c, a
	extz	bc
	lds	wa, 3
	call	15756065
	ldb_erp	l, 251
	stb_erp	a, 251
	cpl	a
	and	(xsp+4), a
	stb_erp	a, 250
	extz	wa
	ld	c, (xsp+6)
	.byte 0x8f, 0x06, 0x83
	dec	2, c
	extz	bc
	call	15756065
	or	(xsp+4), l
	ld	a, (xsp+6)
	extz	wa
	lda	xde, (xsp+2)
	pushw 128
	lds	bc, 0
	call	15753648
	lda	xde, (xsp+4)
	stb_erp	a, 251
	extz	wa
	pushw	wa
	lds	wa, 0
	ldw	bc, 18
	call	15753648
	ld	a, (xsp+6)
	inc	1, a
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	call	15756036
	ld	c, (xsp+4)
	extz	bc
	lds	wa, 1
	call	15756036
	.byte 0x0b, 0x01, 0x00, 0x0b, 0x23, 0x00
	call	15789873
	inc	4, xsp
	lds	wa, 2
	call	15758447
	pop qiz
	inc	8, xsp
	ret
	lda	xsp, (xsp-16)
	.byte 0xd7, 0xfa, 0x04
	ld	(xsp+16), a
	lda	xwa, (xsp+14)
	call	15755792
	ld	a, (xsp+14)
	inc	1, a
	ldb_erp a, 251
	extz	wa
	lda	xbc, (xsp+2)
	call	15756049
	lda	xbc, (xsp+2)
	ld	(xbc+6), 63
	ld	(xbc+7), 0
	ld	(xbc+8), 50
	ld	(xbc+9), 0
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758482
	stb_erp	c, 251
	extz	bc
	ld	e, (xsp+14)
	extz	de
	pushw 0
	lda	xwa, (xsp+4)
	push	xwa
	ldw	wa, 35
	call	15757069
	lds	wa, 4
	call	15758447
	pop qiz
	lda	xsp, (xsp+16)
	ret
	lda	xsp, (xsp-10)
	.byte 0xd7, 0xfa, 0x04
	ld	(xsp+10), a
	lda	xwa, (xsp+8)
	call	15755792
	ld	a, (xsp+8)
	inc	5, a
	ld	(xsp+2), a
	ld	a, (xsp+10)
	extz	wa
	lda	xbc, (xsp+4)
	call	15758482
	ld	a, (xsp+10)
	res	7, a
	ldb_erp a, 251
	ld	a, (xsp+2)
	extz	wa
	lda	xbc, (xsp+6)
	call	15756049
	.byte 0xbf, 0x06, 0xb7, 0xc7, 0xfb, 0xd8
	jr	nz, 24
	.byte 0x8f, 0x06, 0x3f, 0x7f
	jr	nc, 108
	ld	a, (xsp+4)
	add	(xsp+6), a
	.byte 0x8f, 0x06, 0x3f, 0x7f
	jr	c, 29
	ld	(xsp+6), 127
	jr	23
	.byte 0x8f, 0x06, 0x3f, 0x00
	jr	z, 84
	ld	a, (xsp+6)
	.byte 0x8f, 0x04, 0x81
	ld	(xsp+6), a
	cps	a, 0
	jr	ge, 4
	ld	(xsp+6), 0
	ld	a, (xsp+2)
	extz	wa
	ld	c, (xsp+6)
	extz	bc
	call	15756036
	ld	a, (xsp+8)
	extz	wa
	lda	xde, (xsp+6)
	pushw 127
	lds	bc, 1
	call	15753648
	ld	a, (xsp+8)
	extz	wa
	call	15758689
	ld	a, (xsp+8)
	add	a, 11
	ld	(xsp+2), a
	extz	wa
	pushw	wa
	pushw 35
	call	15789873
	inc	4, xsp
	lds	wa, 6
	call	15758447
	pop qiz
	lda	xsp, (xsp+10)
	ret
	lda	xsp, (xsp-14)
	ld	(xsp+12), a
	lda	xbc, (xsp)
	ldw	wa, 10
	call	15756049
	lda	xbc, (xsp)
	ld	(xbc+6), 127
	ld	(xbc+7), 0
	ld	(xbc+8), 127
	ld	(xbc+9), 0
	ld	a, (xsp+12)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758482
	pushw 92
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 35
	ldw	bc, 10
	lds	de, 0
	call	15757069
	lds	wa, 7
	call	15758447
	lda	xsp, (xsp+14)
	ret
	cps	a, 0
	ret	z
	call	15756503
	ret
	cps	a, 0
	ret	z
	ldw	wa, 35
	lds	bc, 1
	lds	de, 1
	call	15764995
	ret
	cps	a, 0
	ret	z
	ldw	wa, 35
	lds	bc, 2
	lds	de, 1
	call	15764995
	ret
	cps	a, 0
	ret	z
	ldw	wa, 35
	lds	bc, 3
	lds	de, 1
	call	15764995
	ret
	cps	a, 0
	ret	z
	ldw	wa, 35
	lds	bc, 4
	lds	de, 1
	call	15764995
	ret
	cps	a, 0
	ret	z
	ldw	wa, 38
	lds	bc, 0
	call	15753542
	ret
	cps	a, 0
	ret	nz
	lds	wa, 0
	call	15755525
	ldw	wa, 32
	lds	bc, 0
	call	15753542
	ret
	dec	8, xsp
	ld	(xsp+6), a
	lda	xbc, (xsp+4)
	lds	wa, 1
	call	15756049
	.byte 0xbf, 0x04, 0xb7
	ld	a, (xsp+6)
	extz	wa
	ld	c, (xsp+4)
	extz	bc
	pushw	bc
	lds	bc, 2
	lds	de, 0
	call	15767485
	cps	l, 1
	jr	nz, 57
	lda	xwa, (xsp+2)
	call	15755792
	lda	xbc, (xsp)
	lds	wa, 2
	call	15756049
	ld	a, (xsp+2)
	extz	wa
	lda	xde, (xsp)
	pushw 127
	ldw	bc, 31
	call	15753648
	pushw 2
	pushw 36
	call	15789873
	inc	4, xsp
	ld	c, (xsp+2)
	extz	bc
	lds	wa, 0
	lds	de, 1
	call	15764590
	lds	wa, 3
	call	15758447
	inc	8, xsp
	ret
	lda	xsp, (xsp-10)
	ld	(xsp+8), a
	lda	xbc, (xsp+6)
	lds	wa, 2
	call	15756049
	lda	xbc, (xsp+4)
	lds	wa, 3
	call	15756049
	.byte 0xbf, 0x06, 0xb7, 0xbf, 0x04, 0xb7
	ld	a, (xsp+8)
	extz	wa
	ld	e, (xsp+6)
	extz	de
	ld	c, (xsp+4)
	extz	bc
	pushw	bc
	lds	bc, 1
	call	15767485
	cps	l, 1
	jr	nz, 57
	lda	xwa, (xsp+2)
	call	15755792
	lda	xbc, (xsp)
	lds	wa, 1
	call	15756049
	ld	a, (xsp+2)
	extz	wa
	lda	xde, (xsp)
	pushw 127
	ldw	bc, 30
	call	15753648
	.byte 0x0b, 0x01, 0x00, 0x0b, 0x24, 0x00
	call	15789873
	inc	4, xsp
	ld	c, (xsp+2)
	extz	bc
	lds	wa, 0
	lds	de, 1
	call	15764590
	lds	wa, 4
	call	15758447
	lda	xsp, (xsp+10)
	ret
	lda	xsp, (xsp-10)
	ld	(xsp+8), a
	lda	xbc, (xsp+6)
	lds	wa, 1
	call	15756049
	lda	xbc, (xsp+4)
	lds	wa, 4
	call	15756049
	.byte 0xbf, 0x06, 0xb7, 0xbf, 0x04, 0xb7
	ld	a, (xsp+8)
	extz	wa
	ld	e, (xsp+6)
	extz	de
	ld	c, (xsp+4)
	extz	bc
	pushw	bc
	lds	bc, 3
	call	15767485
	cps	l, 1
	jr	nz, 57
	lda	xwa, (xsp+2)
	call	15755792
	lda	xbc, (xsp)
	lds	wa, 3
	call	15756049
	ld	a, (xsp+2)
	extz	wa
	lda	xde, (xsp)
	pushw 127
	ldw	bc, 32
	call	15753648
	pushw 3
	pushw 36
	call	15789873
	inc	4, xsp
	ld	c, (xsp+2)
	extz	bc
	lds	wa, 0
	lds	de, 1
	call	15764590
	lds	wa, 5
	call	15758447
	lda	xsp, (xsp+10)
	ret
	dec	8, xsp
	ld	(xsp+6), a
	lda	xbc, (xsp+4)
	lds	wa, 3
	call	15756049
	.byte 0xbf, 0x04, 0xb7
	ld	a, (xsp+6)
	extz	wa
	ld	e, (xsp+4)
	extz	de
	pushw 127
	lds	bc, 4
	call	15767485
	cps	l, 1
	jr	nz, 57
	lda	xwa, (xsp+2)
	call	15755792
	lda	xbc, (xsp)
	lds	wa, 4
	call	15756049
	ld	a, (xsp+2)
	extz	wa
	lda	xde, (xsp)
	pushw 127
	ldw	bc, 33
	call	15753648
	.byte 0x0b, 0x04, 0x00, 0x0b, 0x24, 0x00
	call	15789873
	inc	4, xsp
	ld	c, (xsp+2)
	extz	bc
	lds	wa, 0
	lds	de, 1
	call	15764590
	lds	wa, 6
	call	15758447
	inc	8, xsp
	ret
	cps	a, 0
	ret	z
	call	15756503
	ret
	cps	a, 0
	ret	z
	lds	wa, 1
	call	15757188
	cps	l, 0
	ret	z
	ldw	wa, 36
	lds	bc, 1
	call	15753542
	ret
	cps	a, 0
	jr	nz, 7
	ldw	wa, 37
	lds	bc, 0
	jr	15
	lds	wa, 2
	call	15757188
	cps	l, 0
	ret	z
	ldw	wa, 36
	lds	bc, 1
	call	15753542
	ret
	cps	a, 0
	ret	z
	lds	wa, 3
	call	15757188
	cps	l, 0
	ret	z
	ldw	wa, 36
	lds	bc, 1
	call	15753542
	ret
	cps	a, 0
	ret	z
	lds	wa, 4
	call	15757188
	cps	l, 0
	ret	z
	ldw	wa, 36
	lds	bc, 1
	call	15753542
	ret
	cps	a, 0
	ret	nz
	lds	wa, 0
	call	15755525
	ldw	wa, 32
	lds	bc, 0
	call	15753542
	ret
	lda	xsp, (xsp-18)
	ld	(xsp+16), a
	lda	xbc, (xsp+12)
	lds	wa, 1
	call	15756049
	.byte 0xbf, 0x0c, 0xb7
	lda	xwa, (xsp+14)
	call	15755792
	lda	xbc, (xsp)
	lds	wa, 2
	call	15756049
	lda	xbc, (xsp)
	ld	(xbc+6), 127
	ld	(xbc+7), 0
	ld	a, (xsp+12)
	ld	(xbc+8), a
	ld	(xbc+9), 0
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758482
	ld	e, (xsp+14)
	extz	de
	pushw 35
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 37
	lds	bc, 2
	call	15757069
	cps	l, 1
	jr	nz, 13
	ld	c, (xsp+14)
	extz	bc
	lds	wa, 1
	lds	de, 1
	call	15764590
	lds	wa, 3
	call	15758447
	lda	xsp, (xsp+18)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+18), a
	lda	xbc, (xsp+14)
	lds	wa, 2
	call	15756049
	lda	xbc, (xsp+12)
	lds	wa, 3
	call	15756049
	.byte 0xbf, 0x0e, 0xb7, 0xbf, 0x0c, 0xb7
	lda	xwa, (xsp+16)
	call	15755792
	lda	xbc, (xsp)
	lds	wa, 1
	call	15756049
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
	call	15758482
	ld	e, (xsp+16)
	extz	de
	pushw 34
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 37
	lds	bc, 1
	call	15757069
	cps	l, 1
	jr	nz, 13
	ld	c, (xsp+16)
	extz	bc
	lds	wa, 1
	lds	de, 1
	call	15764590
	lds	wa, 4
	call	15758447
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-20)
	ld	(xsp+18), a
	lda	xbc, (xsp+14)
	lds	wa, 1
	call	15756049
	lda	xbc, (xsp+12)
	lds	wa, 4
	call	15756049
	.byte 0xbf, 0x0e, 0xb7, 0xbf, 0x0c, 0xb7
	lda	xwa, (xsp+16)
	call	15755792
	lda	xbc, (xsp)
	lds	wa, 3
	call	15756049
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
	call	15758482
	ld	e, (xsp+16)
	extz	de
	pushw 36
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 37
	lds	bc, 3
	call	15757069
	cps	l, 1
	jr	nz, 13
	ld	c, (xsp+16)
	extz	bc
	lds	wa, 1
	lds	de, 1
	call	15764590
	lds	wa, 5
	call	15758447
	lda	xsp, (xsp+20)
	ret
	lda	xsp, (xsp-18)
	ld	(xsp+16), a
	lda	xbc, (xsp+12)
	lds	wa, 3
	call	15756049
	.byte 0xbf, 0x0c, 0xb7
	lda	xwa, (xsp+14)
	call	15755792
	lda	xbc, (xsp)
	lds	wa, 4
	call	15756049
	lda	xbc, (xsp)
	ld	(xbc+6), 127
	ld	(xbc+7), 0
	ld	(xbc+8), 127
	ld	a, (xsp+12)
	ld	(xbc+9), a
	ld	a, (xsp+16)
	extz	wa
	lda	xbc, (xbc+10)
	call	15758482
	ld	e, (xsp+14)
	extz	de
	pushw 37
	lda	xwa, (xsp+2)
	push	xwa
	ldw	wa, 37
	lds	bc, 4
	call	15757069
	cps	l, 1
	jr	nz, 13
	ld	c, (xsp+14)
	extz	bc
	lds	wa, 1
	lds	de, 1
	call	15764590
	lds	wa, 6
	call	15758447
	lda	xsp, (xsp+18)
	ret
	cps	a, 0
	ret	z
	call	15756503
	ret
	cps	a, 0
	jr	nz, 7
	ldw	wa, 36
	lds	bc, 0
	jr	15
	lds	wa, 1
	call	15757188
	cps	l, 0
	ret	z
	ldw	wa, 37
	lds	bc, 1
	call	15753542
	ret
	cps	a, 0
	ret	z
	lds	wa, 2
	call	15757188
	cps	l, 0
	ret	z
	ldw	wa, 37
	lds	bc, 1
	call	15753542
	ret
	cps	a, 0
	ret	z
	lds	wa, 3
	call	15757188
	cps	l, 0
	ret	z
	ldw	wa, 37
	lds	bc, 1
	call	15753542
	ret
	cps	a, 0
	ret	z
	lds	wa, 4
	call	15757188
	cps	l, 0
	ret	z
	ldw	wa, 37
	lds	bc, 1
	call	15753542
	ret
	cps	a, 0
	ret	nz
	lds	wa, 0
	call	15755525
	ldw	wa, 32
	lds	bc, 0
	call	15753542
	ret
	dec	4, xsp
	.byte 0xd7, 0xfa, 0x04, 0xc7, 0xfb, 0x99, 0xc7, 0xfb, 0x30, 0x07
	lda	xbc, (xsp+4)
	lds	wa, 0
	call	15756049
	cpib_erp 251, 0
	jr	nz, 18
	.byte 0x8f, 0x04, 0x3f, 0x01
	jr	z, 62
	decm8	1, (xsp+4)
	ld	c, (xsp+4)
	extz	bc
	lds	wa, 0
	jr	34
	.byte 0x8f, 0x04, 0x3f, 0x04
	jr	z, 44
	ld	a, (xsp+4)
	extz	wa
	lda	xbc, (xsp+2)
	call	15756049
	.byte 0x8f, 0x02, 0x3f, 0x7f
	jr	z, 26
	incm8	1, (xsp+4)
	ld	c, (xsp+4)
	extz	bc
	lds	wa, 0
	call	15756036
	pushw 0
	pushw 38
	call	15789873
	inc	4, xsp
	pop qiz
	inc	4, xsp
	ret
	lda	xsp, (xsp-12)
	ld	(xsp+10), a
	lda	xbc, (xsp+2)
	lds	wa, 0
	call	15756049
	lda	xwa, (xsp+4)
	call	15755792
	ld	c, (xsp+2)
	extz	bc
	lda	xde, (xsp+8)
	lds	wa, 1
	call	15766845
	lda	xwa, (xsp+6)
	call	15766214
	ld	a, (xsp+10)
	res	7, a
	cps	a, 0
	jr	nz, 15
	ld	a, (xsp+6)
	dec	1, a
	cp	(xsp+8), a
	jr	nc, 66
	incm8	1, (xsp+8)
	jr	9
	.byte 0x8f, 0x08, 0x3f, 0x00
	jr	z, 55
	decm8	1, (xsp+8)
	ld	c, (xsp+8)
	extz	bc
	lda	xde, (xsp)
	lds	wa, 1
	call	15766762
	ld	a, (xsp+4)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	ld	de, (xsp)
	call	15754454
	ld	a, (xsp+4)
	extz	wa
	ld	c, (xsp+2)
	extz	bc
	ldw	de, 16
	call	15753989
	lds	wa, 2
	call	15758447
	lda	xsp, (xsp+12)
	ret
	lda	xsp, (xsp-10)
	ld	(xsp+8), a
	lda	xbc, (xsp+4)
	lds	wa, 0
	call	15756049
	lda	xwa, (xsp+6)
	call	15755792
	ld	a, (xsp+4)
	extz	wa
	lda	xbc, (xsp+2)
	call	15766181
	lda	xwa, (xsp)
	call	15766204
	ld	a, (xsp+8)
	res	7, a
	cps	a, 0
	jr	nz, 14
	ld	wa, (xsp)
	dec	1, wa
	cp	(xsp+2), wa
	jr	nc, 55
	incw	1, (xsp+2)
	jr	10
	.byte 0x9f, 0x02, 0x3f, 0x00, 0x00
	jr	z, 43
	decm	1, (xsp+2)
	ld	a, (xsp+6)
	extz	wa
	ld	c, (xsp+4)
	extz	bc
	ld	de, (xsp+2)
	call	15754454
	ld	a, (xsp+6)
	extz	wa
	ld	c, (xsp+4)
	extz	bc
	ldw	de, 16
	call	15753989
	lds	wa, 3
	call	15758447
	lda	xsp, (xsp+10)
	ret
	lda	xsp, (xsp-22)
	.byte 0xd7, 0xfa, 0x04
	ld	(xsp+22), a
	lda	xbc, (xsp+8)
	lds	wa, 0
	call	15756049
	.byte 0x8f, 0x08, 0x3f, 0x04
	jrl	z, 634
	lda	xwa, (xsp+12)
	ld	(xwa), 0
	lda	xbc, (xwa+1)
	lds	wa, 1
	call	15756049
	lda	xbc, (xsp+14)
	lds	wa, 4
	call	15756049
	lda	xbc, (xsp+15)
	lds	wa, 2
	call	15756049
	lda	xbc, (xsp+16)
	lds	wa, 5
	call	15756049
	lda	xbc, (xsp+17)
	lds	wa, 3
	call	15756049
	lda	xbc, (xsp+18)
	lds	wa, 6
	call	15756049
	lda	xbc, (xsp+19)
	lds	wa, 7
	call	15756049
	ld	l, (xsp+22)
	res	7, l
	ld	a, (xsp+8)
	.byte 0x8f, 0x08, 0x81
	dec	1, a
	.byte 0xc7, 0xe2, 0x99
	extz	wa
	lda	xde, (xsp+12)
	lda_rr xbc, xde, wa
	cps	l, 0
	jr	nz, 33
	ld	xde, xbc
	ld	a, (xbc)
	cp	a, 127
	jrl	nc, 524
	.byte 0xbf, 0x16, 0xcf
	jr	z, 4
	inc	3, a
	jr	2
	inc	1, a
	ld	(xde), a
	.byte 0x82, 0x3f, 0x7f
	jr	c, 63
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
	inc	2, a
	extz	wa
	.byte 0xf3, 0x07, 0xec, 0xe0, 0x00, 0x7f, 0xbf, 0x16, 0xcf
	jr	z, 17
	ld	a, (xde)
	cps	a, 3
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
	lda_rr	xde, xhl, wa
	ld	c, (xde)
	cp	c, 127
	jr	z, 17
	stb_erp	a, 226
	inc	1, a
	ldb_erp	a, 240
	extz	ix
	inc	1, c
	st_rrb	c, xhl, ix
	ld	a, (xde)
	ld	(xsp+4), a
	ldib_erp	251, 0
	ldb	c, 0
	ld	a, c
	add	a, c
	inc	1, a
	extz	wa
	.byte 0xc3, 0x07, 0xec, 0xe0, 0x3f, 0x7f
	jr	nz, 7
	inc	1, c
	ld	(xsp+2), c
	jr	6
	inc	1, c
	cps	c, 4
	jr	c, -29
	stb_erp	a, 251
	addb_erp	a, 251
	ldb_erp	a, 226
	extz	wa
	lda_rr	xiy, xhl, wa
	ld	c, (xiy)
	ld	b, c
	stb_erp	a, 226
	inc	1, a
	extz	wa
	lda_rr	xix, xhl, wa
	ld	a, (xix)
	ldb_erp	a, 226
	stb_erp	w, 251
	inc	1, w
	cp	(xsp+8), w
	jr	ule, 34
	ld	a, (xsp+8)
	sub	a, w
	ld	w, a
	stb_erp	a, 226
	add	a, w
	cp	(xsp+4), a
	jr	nc, 71
	ld	a, (xsp+4)
	sub	a, w
	ldb_erp	a, 226
	cp	a, c
	jr	nc, 59
	stb_erp	b, 226
	jr	54
	cp	(xsp+8), w
	jr	nc, 41
	cp	(xsp+2), w
	jr	c, 6
	.byte 0x8f, 0x04, 0x3f, 0x7f
	jr	nz, 4
	ldb	b, 0
	jr	34
	.byte 0x8f, 0x08, 0xa0
	ld	a, (xsp+4)
	add	a, w
	cp	a, b
	jr	ule, 2
	ld	b, a
	stb_erp	a, 226
	cp	a, b
	jr	nc, 13
	ldb_erp	b, 226
	jr	8
	cp	(xsp+4), b
	jr	nc, 3
	ld	b, (xsp+4)
	ld	(xiy), b
	stb_erp	a, 226
	ld	(xix), a
	inc1b_erp	251
	cpib_erp	251, 4
	jrl	c, -182
	ld	a, (xsp+4)
	ld	(xde), a
	ld	c, (xhl+1)
	extz	bc
	lds	wa, 1
	call	15756036
	ld	c, (xsp+14)
	extz	bc
	lds	wa, 4
	call	15756036
	ld	c, (xsp+15)
	extz	bc
	lds	wa, 2
	call	15756036
	ld	c, (xsp+16)
	extz	bc
	lds	wa, 5
	call	15756036
	ld	c, (xsp+17)
	extz	bc
	lds	wa, 3
	call	15756036
	ld	c, (xsp+18)
	extz	bc
	lds	wa, 6
	call	15756036
	ld	c, (xsp+19)
	extz	bc
	lds	wa, 7
	call	15756036
	lda	xwa, (xsp+10)
	call	15766913
	lda	xwa, (xsp+6)
	.byte 0x8f, 0x0a, 0x3f, 0x00
	jr	nz, 51
	call	15757634
	.byte 0xc7, 0xfb, 0xa9, 0xc7, 0xfb, 0x89
	extz	wa
	lda	xbc, (xsp+4)
	call	15756049
	ld	a, (xsp+6)
	extz	wa
	ldb	c, 0
	addb_erp c, 251
	dec	1, c
	lda	xde, (xsp+4)
	pushw 127
	call	15753648
	inc1b_erp 251
	cpib_erp 251, 3
	jr	ule, -42
	jr	49
	call	15755792
	ldib_erp 251, 1
	stb_erp a, 251
	extz	wa
	lda	xbc, (xsp+4)
	call	15756049
	ld	a, (xsp+6)
	extz	wa
	ldb	c, 0
	addb_erp c, 251
	dec	1, c
	lda	xde, (xsp+4)
	pushw 127
	call	15754738
	inc1b_erp 251
	cpib_erp 251, 3
	jr	ule, -42
	.byte 0x0b, 0x01, 0x00, 0x0b, 0x26, 0x00
	call	15789873
	inc	4, xsp
	lds	wa, 6
	call	15758447
	pop qiz
	lda	xsp, (xsp+22)
	ret
	cps	a, 0
	ret	z
	call	15756503
	ret
	cps	a, 0
	ret	z
	lds	wa, 1
	call	15757188
	cps	l, 0
	ret	z
	ldw	wa, 38
	lds	bc, 1
	call	15753542
	ret
	cps	a, 0
	ret	z
	lds	wa, 2
	call	15757188
	cps	l, 0
	ret	z
	ldw	wa, 38
	lds	bc, 1
	call	15753542
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	15766913
	.byte 0x87, 0x3f, 0x01
	jr	z, 25
	.byte 0x8f, 0x02, 0x3f, 0x00
	jr	z, 19
	lds	wa, 3
	call	15757188
	cps	l, 0
	jr	z, 9
	ldw	wa, 38
	lds	bc, 1
	call	15753542
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	15766913
	.byte 0x87, 0x3f, 0x01
	jr	z, 25
	.byte 0x8f, 0x02, 0x3f, 0x00
	jr	z, 19
	lds	wa, 4
	call	15757188
	cps	l, 0
	jr	z, 9
	ldw	wa, 38
	lds	bc, 1
	call	15753542
	inc	4, xsp
	ret
	dec	4, xsp
	ld	(xsp+2), a
	lda	xwa, (xsp)
	call	15766913
	.byte 0x87, 0x3f, 0x01
	jr	z, 22
	.byte 0x8f, 0x02, 0x3f, 0x00
	jr	nz, 7
	ldw	wa, 35
	lds	bc, 0
	jr	5
	ldw	wa, 34
	lds	bc, 0
	call	15753542
	inc	4, xsp
	ret
	dec	2, xsp
	cps	a, 0
	jr	nz, 33
	lds	wa, 0
	call	15755525
	lda	xwa, (xsp)
	call	15766913
	.byte 0x87, 0x3f, 0x00
	jr	nz, 7
	ldw	wa, 32
	lds	bc, 0
	jr	5
	ldw	wa, 61
	lds	bc, 0
	call	15753542
	inc	2, xsp
	ret
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeMenu_SetupPartDisplay_End_0x90
	cp HL,0xffff
	jr z, .Lc_f0d711
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (ToneGen_ParamTable_0x186:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f0d711:
	inc 4,XSP
	ret
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeMenu_SetupPartDisplay_End_0x90
	cp HL,0xffff
	jr z, .Lc_f0d73f
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (ToneGen_ParamTable_0x2A6:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f0d73f:
	inc 4,XSP
	ret
	dec 4,XSP
	lda xde, (xsp + 0x02)
	lda XHL, (XSP)
	push XHL
	call SeMenu_SetupPartDisplay_End_0x90
	cp HL,0xffff
	jr z, .Lc_f0d76d
	ld A,(XSP)
	extz WA
	ld C,(XSP+0x02)
	extz BC
	sla BC, 0x02
	lda xde, (ToneGen_ParamTable_0x1CE:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f0d76d:
	inc 4,XSP
	ret
	.byte 0xef, 0x6c, 0xbf, 0x02, 0x32, 0xb7, 0x33, 0x3b
	.byte 0x1d, 0x09, 0x73, 0xf0, 0xdb, 0xcf, 0xff, 0xff
	.byte 0x66, 0x19, 0x87, 0x21, 0xd8, 0x12, 0x8f, 0x02
	.byte 0x23, 0xd9, 0x12, 0xd9, 0xec, 0x02, 0xf2, 0x1d
	.byte 0xe6, 0xe0, 0x32, 0xe9, 0x13, 0xea, 0x81, 0xa1
	.byte 0x23, 0xb3, 0xe8, 0xef, 0x64, 0x0e
	dec 0,XSP
	pushw iz
	ld (XSP+0x08),BC
	ld IZ,WA
	lda xwa, (xsp + 0x02)
	call SeMenu_DisplayState_Data
	cp (XSP+0x02),0x00
	jr nz, .Lc_f0d7e3
	lda xde, (xsp + 0x06)
	lda xwa, (xsp + 0x04)
	push XWA
	ld WA,IZ
	ld BC,(XSP+0x0c)
	call SeMenu_SetupPartDisplay_End_0x90
	cp HL,0xffff
	jr z, .Lc_f0d7e3
	ld A,(XSP+0x04)
	extz WA
	ld C,(XSP+0x06)
	extz BC
	sla BC, 0x02
	lda xde, (ToneGen_ParamTable_0x25E:24)
	exts XBC
	add XBC,XDE
	ld XHL,(XBC)
	call (XHL)
.Lc_f0d7e3:
	popw iz
	inc 0,XSP
	ret
	.byte 0xbf, 0xec, 0x37, 0xd7, 0xfa, 0x04, 0xbf, 0x14
	.byte 0x41, 0xbf, 0x12, 0x31, 0xd8, 0xa8, 0x1d, 0x11
	.byte 0x6b, 0xf0, 0x8f, 0x12, 0x3f, 0x05, 0x76, 0xaa
	.byte 0x00, 0x8f, 0x12, 0x3f, 0x08, 0x76, 0xa3, 0x00
	.byte 0x8f, 0x12, 0x21, 0xd8, 0x12, 0xbf, 0x02, 0x31
	.byte 0x1d, 0x11, 0x6b, 0xf0, 0xbf, 0x02, 0x32, 0xba
	.byte 0x06, 0x00, 0xff, 0xba, 0x07, 0x00, 0x00, 0xba
	.byte 0x08, 0x30, 0xba, 0x09, 0x31, 0x8f, 0x12, 0x3f
	.byte 0x02, 0x6e, 0x08, 0xb0, 0x00, 0x15, 0xb1, 0x00
	.byte 0x00, 0x68, 0x06, 0xb0, 0x00, 0x0a, 0xb1, 0x00
	.byte 0xf6, 0x8f, 0x14, 0x21, 0xd8, 0x12, 0xba, 0x0a
	.byte 0x31, 0x1d, 0x92, 0x74, 0xf0, 0xbf, 0x02, 0x30
	.byte 0x1d, 0x48, 0x6b, 0xf0, 0xcf, 0xd9, 0x7e, 0x8d
	.byte 0x01, 0x8f, 0x12, 0x21, 0xd8, 0x12, 0x8f, 0x05
	.byte 0x23, 0xd9, 0x12, 0x1d, 0x04, 0x6b, 0xf0, 0x8f
	.byte 0x12, 0x21, 0xd8, 0x12, 0x28, 0x0b, 0x21, 0x00
	.byte 0x1d, 0x31, 0xef, 0xf0, 0xef, 0x64, 0x8f, 0x12
	.byte 0x3f, 0x02, 0x6e, 0x0a, 0xbf, 0x05, 0x31, 0x81
	.byte 0x21, 0xc9, 0xca, 0x0b, 0xb1, 0x41, 0x8f, 0x12
	.byte 0x21, 0xd8, 0x12, 0xbf, 0x05, 0x31, 0x1d, 0x12
	.byte 0x67, 0xf0, 0x8f, 0x12, 0x3f, 0x02, 0x67, 0x16
	.byte 0x8f, 0x12, 0x3f, 0x04, 0x6b, 0x10, 0x8f, 0x12
	.byte 0x21, 0xc9, 0x6a, 0xd8, 0x12, 0x8f, 0x05, 0x23
	.byte 0xd9, 0x12, 0x1d, 0x13, 0x99, 0xf0, 0xd8, 0xac
	.byte 0x78, 0xef, 0x00, 0xbf, 0x02, 0x31, 0x8f, 0x12
	.byte 0x3f, 0x05, 0x6e, 0x44, 0xbf, 0x12, 0x00, 0x09
	.byte 0x30, 0x09, 0x00, 0x1d, 0x11, 0x6b, 0xf0, 0xbf
	.byte 0x02, 0x31, 0xb9, 0x06, 0x00, 0x0f, 0xb9, 0x07
	.byte 0x00, 0x00, 0xb9, 0x08, 0x00, 0x0a, 0xb9, 0x09
	.byte 0x00, 0x06, 0x8f, 0x14, 0x21, 0xd8, 0x12, 0xb9
	.byte 0x0a, 0x31, 0x1d, 0x92, 0x74, 0xf0, 0x8f, 0x12
	.byte 0x23, 0xd9, 0x12, 0x0b, 0x29, 0x00, 0xbf, 0x04
	.byte 0x30, 0x38, 0x30, 0x21, 0x00, 0xda, 0xa8, 0x1d
	.byte 0x0d, 0x6f, 0xf0, 0xd8, 0xac, 0x78, 0xa2, 0x00
	.byte 0x8f, 0x12, 0x3f, 0x08, 0x7e, 0x9f, 0x00, 0xbf
	.byte 0x12, 0x00, 0x0a, 0x8f, 0x14, 0x21, 0xc9, 0x30
	.byte 0x07, 0xc7, 0xfb, 0x99, 0x30, 0x0a, 0x00, 0x1d
	.byte 0x11, 0x6b, 0xf0, 0xbf, 0x02, 0x30, 0xb8, 0x06
	.byte 0x00, 0x0f, 0xb8, 0x07, 0x00, 0x00, 0xb8, 0x08
	.byte 0x00, 0x0b, 0xb8, 0x09, 0x00, 0x00, 0xbf, 0x0e
	.byte 0x30, 0x1d, 0x8b, 0x61, 0xf0, 0xc7, 0xfb, 0xd8
	.byte 0x6e, 0x6e, 0xbf, 0x02, 0x30, 0xb0, 0xcf, 0x6e
	.byte 0x21, 0xb0, 0xbf, 0x80, 0x21, 0xbf, 0x10, 0x41
	.byte 0xd8, 0xac, 0x31, 0x40, 0x00, 0xda, 0xa9, 0x1d
	.byte 0x49, 0x97, 0xf0, 0x8f, 0x0e, 0x21, 0xd8, 0x12
	.byte 0x0b, 0x40, 0x00, 0xd9, 0xac, 0x32, 0x40, 0x00
	.byte 0x68, 0x72, 0xb8, 0x0a, 0x00, 0x01, 0x1d, 0x48
	.byte 0x6b, 0xf0, 0xcf, 0xd9, 0x6e, 0x78, 0x8f, 0x05
	.byte 0x21, 0xbf, 0x10, 0x41, 0xbf, 0x10, 0x32, 0x0b
	.byte 0x0f, 0x00, 0xd8, 0xa8, 0x31, 0x5d, 0x00, 0x1d
	.byte 0xb0, 0x61, 0xf0, 0x8f, 0x12, 0x21, 0xd8, 0x12
	.byte 0x8f, 0x10, 0x23, 0xd9, 0x12, 0x1d, 0x04, 0x6b
	.byte 0xf0, 0x8f, 0x12, 0x21, 0xd8, 0x12, 0x28, 0x0b
	.byte 0x21, 0x00, 0x1d, 0x31, 0xef, 0xf0, 0xef, 0x64
	.byte 0xd8, 0xac, 0x1d, 0x6f, 0x74, 0xf0, 0x68, 0x3e
	.byte 0xbf, 0x02, 0x30, 0xb0, 0xcf, 0x66, 0x37, 0x80
	.byte 0x23, 0xcb, 0xcc, 0x0f, 0x6e, 0x24, 0xb0, 0xb7
	.byte 0x80, 0x21, 0xbf, 0x10, 0x41, 0xd8, 0xac, 0x31
	.byte 0x40, 0x00, 0xda, 0xa8, 0x1d, 0x49, 0x97, 0xf0
	.byte 0x8f, 0x0e, 0x21, 0xd8, 0x12, 0x0b, 0x40, 0x00
	.byte 0xd9, 0xac, 0xda, 0xa8, 0x1d, 0x53, 0xaa, 0xfd
	.byte 0x68, 0x9a, 0xb8, 0x0a, 0x00, 0xff, 0x1d, 0x48
	.byte 0x6b, 0xf0, 0xcf, 0xd9, 0x66, 0x88, 0xd7, 0xfa
	.byte 0x05, 0xbf, 0x14, 0x37, 0x0e, 0xc9, 0xd8, 0xb0
	.byte 0xf6, 0xd8, 0xa8, 0x1d, 0x3a, 0x97, 0xf0, 0x30
	.byte 0x3e, 0x00, 0xd9, 0xa8, 0x1d, 0x46, 0x61, 0xf0
	.byte 0x0e, 0xef, 0x6c, 0xbf, 0x02, 0x41, 0xb7, 0x31
	.byte 0xd8, 0xa8, 0x1d, 0x11, 0x6b, 0xf0, 0x8f, 0x02
	.byte 0x3f, 0x00, 0x6e, 0x0b, 0x87, 0x3f, 0x05, 0x66
	.byte 0x1f, 0xd8, 0xa8, 0xd9, 0xad, 0x68, 0x09, 0x87
	.byte 0x3f, 0x01, 0x66, 0x14, 0xd8, 0xa8, 0xd9, 0xa9
	.byte 0x1d, 0x04, 0x6b, 0xf0, 0x0b, 0x00, 0x00, 0x0b
	.byte 0x21, 0x00, 0x1d, 0x31, 0xef, 0xf0, 0xef, 0x64
	.byte 0xef, 0x64, 0x0e, 0xef, 0x6c, 0xbf, 0x02, 0x41
	.byte 0xb7, 0x31, 0xd8, 0xa8, 0x1d, 0x11, 0x6b, 0xf0
	.byte 0x8f, 0x02, 0x3f, 0x00, 0x6e, 0x0b, 0x87, 0x3f
	.byte 0x06, 0x66, 0x1f, 0xd8, 0xa8, 0xd9, 0xae, 0x68
	.byte 0x09, 0x87, 0x3f, 0x02, 0x66, 0x14, 0xd8, 0xa8
	.byte 0xd9, 0xaa, 0x1d, 0x04, 0x6b, 0xf0, 0x0b, 0x00
	.byte 0x00, 0x0b, 0x21, 0x00, 0x1d, 0x31, 0xef, 0xf0
	.byte 0xef, 0x64, 0xef, 0x64, 0x0e, 0xef, 0x6c, 0xbf
	.byte 0x02, 0x41, 0xb7, 0x31, 0xd8, 0xa8, 0x1d, 0x11
	.byte 0x6b, 0xf0, 0x8f, 0x02, 0x3f, 0x00, 0x6e, 0x0b
	.byte 0x87, 0x3f, 0x07, 0x66, 0x1f, 0xd8, 0xa8, 0xd9
	.byte 0xaf, 0x68, 0x09, 0x87, 0x3f, 0x03, 0x66, 0x14
	.byte 0xd8, 0xa8, 0xd9, 0xab, 0x1d, 0x04, 0x6b, 0xf0
	.byte 0x0b, 0x00, 0x00, 0x0b, 0x21, 0x00, 0x1d, 0x31
	.byte 0xef, 0xf0, 0xef, 0x64, 0xef, 0x64, 0x0e, 0xef
	.byte 0x6c, 0xbf, 0x02, 0x41, 0xb7, 0x31, 0xd8, 0xa8
	.byte 0x1d, 0x11, 0x6b, 0xf0, 0x8f, 0x02, 0x3f, 0x00
	.byte 0x6e, 0x0c, 0x87, 0x3f, 0x08, 0x66, 0x20, 0xd8
	.byte 0xa8, 0x31, 0x08, 0x00, 0x68, 0x09, 0x87, 0x3f
	.byte 0x04, 0x66, 0x14, 0xd8, 0xa8, 0xd9, 0xac, 0x1d
	.byte 0x04, 0x6b, 0xf0, 0x0b, 0x00, 0x00, 0x0b, 0x21
	.byte 0x00, 0x1d, 0x31, 0xef, 0xf0, 0xef, 0x64, 0xef
	.byte 0x64, 0x0e, 0xc9, 0xd8, 0xb0, 0xfe, 0x30, 0x20
	.byte 0x00, 0xd9, 0xa8, 0x1d, 0x46, 0x61, 0xf0, 0x0e
	.byte 0xbf, 0xf0, 0x37, 0xbf, 0x0e, 0x41, 0xbf, 0x0c
	.byte 0x31, 0xd8, 0xa8, 0x1d, 0x11, 0x6b, 0xf0, 0x8f
	.byte 0x0c, 0x3c, 0x0f, 0xb7, 0x31, 0xd8, 0xa9, 0x1d
	.byte 0x11, 0x6b, 0xf0, 0xb7, 0x31, 0xb9, 0x06, 0x00
	.byte 0xff, 0xb9, 0x07, 0x00, 0x00, 0x8f, 0x0e, 0x21
	.byte 0xd8, 0x12, 0xb9, 0x0a, 0x31, 0x1d, 0x92, 0x74
	.byte 0xf0, 0x8f, 0x0c, 0x25, 0xb7, 0x31, 0xb9, 0x08
	.byte 0x30, 0xb9, 0x09, 0x31, 0xcd, 0xcf, 0x09, 0x66
	.byte 0x38, 0xcd, 0xcf, 0x0a, 0x66, 0x38, 0xcd, 0xcf
	.byte 0x0b, 0x66, 0x33, 0xcd, 0xcf, 0x08, 0x6b, 0x33
	.byte 0xcd, 0xd8, 0x67, 0x2f, 0xb0, 0x00, 0x32, 0xb1
	.byte 0x00, 0x00, 0x40, 0x5e, 0x00, 0x00, 0x00, 0xd8
	.byte 0x12, 0x28, 0xbf, 0x02, 0x30, 0x38, 0x30, 0x3a
	.byte 0x00, 0xd9, 0xa9, 0xda, 0xa8, 0x1d, 0x0d, 0x6f
	.byte 0xf0, 0xd8, 0xa9, 0x1d, 0x6f, 0x74, 0xf0, 0x68
	.byte 0x0a, 0xb0, 0x00, 0x1e, 0x68, 0xd9, 0xb0, 0x00
	.byte 0x01, 0x68, 0xd4, 0xbf, 0x10, 0x37, 0x0e, 0xbf
	.byte 0xf0, 0x37, 0xbf, 0x0e, 0x41, 0xbf, 0x0c, 0x31
	.byte 0xd8, 0xa8, 0x1d, 0x11, 0x6b, 0xf0, 0x8f, 0x0c
	.byte 0x3c, 0x0f, 0xb7, 0x31, 0xd8, 0xaa, 0x1d, 0x11
	.byte 0x6b, 0xf0, 0xb7, 0x31, 0xb9, 0x06, 0x00, 0xff
	.byte 0xb9, 0x07, 0x00, 0x00, 0x8f, 0x0e, 0x21, 0xd8
	.byte 0x12, 0xb9, 0x0a, 0x31, 0x1d, 0x92, 0x74, 0xf0
	.byte 0x8f, 0x0c, 0x25, 0xb7, 0x31, 0xb9, 0x08, 0x30
	.byte 0xb9, 0x09, 0x31, 0xcd, 0xcf, 0x08, 0x66, 0x40
	.byte 0xcd, 0xcf, 0x09, 0x66, 0x43, 0xcd, 0xcf, 0x0a
	.byte 0x66, 0x0d, 0xcd, 0xcf, 0x0b, 0x66, 0x08, 0xcd
	.byte 0xdf, 0x6b, 0x3d, 0xcd, 0xd8, 0x67, 0x39, 0xb7
	.byte 0x30, 0xb8, 0x08, 0x00, 0x32, 0xb8, 0x09, 0x00
	.byte 0x00, 0xe8, 0xa9, 0xb8, 0x5e, 0x30, 0xd8, 0x12
	.byte 0x28, 0xbf, 0x02, 0x30, 0x38, 0x30, 0x3a, 0x00
	.byte 0xd9, 0xaa, 0xda, 0xa8, 0x1d, 0x0d, 0x6f, 0xf0
	.byte 0xd8, 0xaa, 0x1d, 0x6f, 0x74, 0xf0, 0x68, 0x10
	.byte 0xb0, 0x00, 0x32, 0xb1, 0x00, 0xce, 0x68, 0xd9
	.byte 0xb0, 0x00, 0x1e, 0xb1, 0x00, 0x00, 0x68, 0xd1
	.byte 0xbf, 0x10, 0x37, 0x0e, 0xbf, 0xf0, 0x37, 0xbf
	.byte 0x0e, 0x41, 0xbf, 0x0c, 0x31, 0xd8, 0xa8, 0x1d
	.byte 0x11, 0x6b, 0xf0, 0x8f, 0x0c, 0x3c, 0x0f, 0xb7
	.byte 0x31, 0xd8, 0xab, 0x1d, 0x11, 0x6b, 0xf0, 0xb7
	.byte 0x31, 0xb9, 0x06, 0x00, 0xff, 0xb9, 0x07, 0x00
	.byte 0x00, 0x8f, 0x0e, 0x21, 0xd8, 0x12, 0xb9, 0x0a
	.byte 0x31, 0x1d, 0x92, 0x74, 0xf0, 0x8f, 0x0c, 0x21
	.byte 0xd8, 0x12, 0xd8, 0xd8, 0x65, 0x6d, 0xd8, 0xcf
	.byte 0x0b, 0x00, 0x6a, 0x67, 0xd8, 0x80, 0xf2, 0xf5
	.byte 0xe6, 0xe0, 0x34, 0xd3, 0x07, 0xf0, 0xe0, 0x20
	.byte 0xf2, 0x61, 0xdc, 0xf0, 0x34, 0xf3, 0x07, 0xf0
	.byte 0xe0, 0xd8, 0xb7, 0x30, 0xb8, 0x08, 0x00, 0x32
	.byte 0xb8, 0x09, 0x00, 0xce, 0xe8, 0xaa, 0xb8, 0x5e
	.byte 0x30, 0xd8, 0x12, 0x28, 0xbf, 0x02, 0x30, 0x38
	.byte 0x30, 0x3a, 0x00, 0xd9, 0xab, 0xda, 0xa8, 0x1d
	.byte 0x0d, 0x6f, 0xf0, 0xd8, 0xab, 0x1d, 0x6f, 0x74
	.byte 0xf0, 0x68, 0x28, 0xb7, 0x30, 0xb8, 0x08, 0x00
	.byte 0x32, 0x68, 0x1a, 0xb7, 0x30, 0xb8, 0x08, 0x00
	.byte 0x03, 0x68, 0x12, 0xb7, 0x30, 0xb8, 0x08, 0x00
	.byte 0x18, 0xb8, 0x09, 0x00, 0xe8, 0x68, 0xc5, 0xb7
	.byte 0x30, 0xb8, 0x08, 0x00, 0x1e, 0xb8, 0x09, 0x00
	.byte 0x00, 0x68, 0xb9, 0xbf, 0x10, 0x37, 0x0e, 0xbf
	.byte 0xf0, 0x37, 0xbf, 0x0e, 0x41, 0xbf, 0x0c, 0x31
	.byte 0xd8, 0xa8, 0x1d, 0x11, 0x6b, 0xf0, 0x8f, 0x0c
	.byte 0x3c, 0x0f, 0xb7, 0x31, 0xd8, 0xac, 0x1d, 0x11
	.byte 0x6b, 0xf0, 0xb7, 0x31, 0xb9, 0x06, 0x00, 0xff
	.byte 0xb9, 0x07, 0x00, 0x00, 0x8f, 0x0e, 0x21, 0xd8
	.byte 0x12, 0xb9, 0x0a, 0x31, 0x1d, 0x92, 0x74, 0xf0
	.byte 0x8f, 0x0c, 0x21, 0xd8, 0x12, 0xd8, 0xd8, 0x65
	.byte 0x55, 0xd8, 0xcf, 0x09, 0x00, 0x6a, 0x4f, 0xd8
	.byte 0x80, 0xf2, 0x0d, 0xe7, 0xe0, 0x34, 0xd3, 0x07
	.byte 0xf0, 0xe0, 0x20, 0xf2, 0x0c, 0xdd, 0xf0, 0x34
	.byte 0xf3, 0x07, 0xf0, 0xe0, 0xd8, 0xb7, 0x30, 0xb8
	.byte 0x08, 0x00, 0x32, 0xb8, 0x09, 0x00, 0x00, 0xe8
	.byte 0xab, 0xb8, 0x5e, 0x30, 0xd8, 0x12, 0x28, 0xbf
	.byte 0x02, 0x30, 0x38, 0x30, 0x3a, 0x00, 0xd9, 0xac
	.byte 0xda, 0xa8, 0x1d, 0x0d, 0x6f, 0xf0, 0xd8, 0xac
	.byte 0x1d, 0x6f, 0x74, 0xf0, 0x68, 0x10, 0xb7, 0x30
	.byte 0xb8, 0x08, 0x00, 0x64, 0x68, 0xd5, 0xb7, 0x30
	.byte 0xb8, 0x08, 0x00, 0x1e, 0x68, 0xcd, 0xbf, 0x10
	.byte 0x37, 0x0e, 0xbf, 0xf0, 0x37, 0xbf, 0x0e, 0x41
	.byte 0xbf, 0x0c, 0x31, 0xd8, 0xa8, 0x1d, 0x11, 0x6b
	.byte 0xf0, 0x8f, 0x0c, 0x3c, 0x0f, 0xb7, 0x31, 0xd8
	.byte 0xad, 0x1d, 0x11, 0x6b, 0xf0, 0xb7, 0x31, 0xb9
	.byte 0x06, 0x00, 0xff, 0xb9, 0x07, 0x00, 0x00, 0x8f
	.byte 0x0e, 0x21, 0xd8, 0x12, 0xb9, 0x0a, 0x31, 0x1d
	.byte 0x92, 0x74, 0xf0, 0x8f, 0x0c, 0x21, 0xd8, 0x12
	.byte 0xd8, 0xd8, 0x65, 0x4f, 0xd8, 0xdd, 0x6a, 0x4b
	.byte 0xd8, 0x80, 0xf2, 0x21, 0xe7, 0xe0, 0x34, 0xd3
	.byte 0x07, 0xf0, 0xe0, 0x20, 0xf2, 0x9d, 0xdd, 0xf0
	.byte 0x34, 0xf3, 0x07, 0xf0, 0xe0, 0xd8, 0xb7, 0x30
	.byte 0xb8, 0x08, 0x00, 0x64, 0xb8, 0x09, 0x00, 0x00
	.byte 0xe8, 0xac, 0xb8, 0x5e, 0x30, 0xd8, 0x12, 0x28
	.byte 0xbf, 0x02, 0x30, 0x38, 0x30, 0x3a, 0x00, 0xd9
	.byte 0xad, 0xda, 0xa8, 0x1d, 0x0d, 0x6f, 0xf0, 0xd8
	.byte 0xad, 0x1d, 0x6f, 0x74, 0xf0, 0x68, 0x0c, 0xb7
	.byte 0x30, 0xb8, 0x08, 0x00, 0x32, 0xb8, 0x09, 0x00
	.byte 0xce, 0x68, 0xd5, 0xbf, 0x10, 0x37, 0x0e, 0xbf
	.byte 0xf0, 0x37, 0xbf, 0x0e, 0x41, 0xbf, 0x0c, 0x31
	.byte 0xd8, 0xa8, 0x1d, 0x11, 0x6b, 0xf0, 0x8f, 0x0c
	.byte 0x3c, 0x0f, 0xb7, 0x31, 0xd8, 0xae, 0x1d, 0x11
	.byte 0x6b, 0xf0, 0xb7, 0x31, 0xb9, 0x06, 0x00, 0xff
	.byte 0xb9, 0x07, 0x00, 0x00, 0x8f, 0x0e, 0x21, 0xd8
	.byte 0x12, 0xb9, 0x0a, 0x31, 0x1d, 0x92, 0x74, 0xf0
	.byte 0x8f, 0x0c, 0x21, 0xc9, 0xdd, 0x66, 0x04, 0xc9
	.byte 0xdc, 0x6e, 0x24, 0xb7, 0x31, 0xb9, 0x08, 0x00
	.byte 0x32, 0xb9, 0x09, 0x00, 0x00, 0xe8, 0xad, 0xb8
	.byte 0x5e, 0x30, 0xd8, 0x12, 0x28, 0x39, 0x30, 0x3a
	.byte 0x00, 0xd9, 0xae, 0xda, 0xa8, 0x1d, 0x0d, 0x6f
	.byte 0xf0, 0xd8, 0xae, 0x1d, 0x6f, 0x74, 0xf0, 0xbf
	.byte 0x10, 0x37, 0x0e, 0xbf, 0xf0, 0x37, 0xbf, 0x0e
	.byte 0x41, 0xbf, 0x0c, 0x31, 0xd8, 0xa8, 0x1d, 0x11
	.byte 0x6b, 0xf0, 0x8f, 0x0c, 0x3c, 0x0f, 0xb7, 0x31
	.byte 0xd8, 0xaf, 0x1d, 0x11, 0x6b, 0xf0, 0xb7, 0x31
	.byte 0xb9, 0x06, 0x00, 0xff, 0xb9, 0x07, 0x00, 0x00
	.byte 0x8f, 0x0e, 0x21, 0xd8, 0x12, 0xb9, 0x0a, 0x31
	.byte 0x1d, 0x92, 0x74, 0xf0, 0x8f, 0x0c, 0x21, 0xc9
	.byte 0xcf, 0x0a, 0x66, 0x32, 0xc9, 0xcf, 0x0b, 0x66
	.byte 0x09, 0xc9, 0xcf, 0x09, 0x6b, 0x28, 0xc9, 0xd8
	.byte 0x67, 0x24, 0xb7, 0x31, 0xb9, 0x08, 0x00, 0x32
	.byte 0xb9, 0x09, 0x00, 0xce, 0xe8, 0xae, 0xb8, 0x5e
	.byte 0x30, 0xd8, 0x12, 0x28, 0x39, 0x30, 0x3a, 0x00
	.byte 0xd9, 0xaf, 0xda, 0xa8, 0x1d, 0x0d, 0x6f, 0xf0
	.byte 0xd8, 0xaf, 0x1d, 0x6f, 0x74, 0xf0, 0xbf, 0x10
	.byte 0x37, 0x0e, 0xbf, 0xf0, 0x37, 0xbf, 0x0e, 0x41
	.byte 0xbf, 0x0c, 0x31, 0xd8, 0xa8, 0x1d, 0x11, 0x6b
	.byte 0xf0, 0x8f, 0x0c, 0x3c, 0x0f, 0xb7, 0x31, 0x30
	.byte 0x08, 0x00, 0x1d, 0x11, 0x6b, 0xf0, 0xb7, 0x31
	.byte 0xb9, 0x06, 0x00, 0xff, 0xb9, 0x07, 0x00, 0x00
	.byte 0x8f, 0x0e, 0x21, 0xd8, 0x12, 0xb9, 0x0a, 0x31
	.byte 0x1d, 0x92, 0x74, 0xf0, 0x8f, 0x0c, 0x21, 0xc9
	.byte 0xcf, 0x0b, 0x6b, 0x2a, 0xc9, 0xd8, 0x67, 0x26
	.byte 0xb7, 0x31, 0xb9, 0x08, 0x00, 0x32, 0xb9, 0x09
	.byte 0x00, 0xce, 0xe8, 0xaf, 0xb8, 0x5e, 0x30, 0xd8
	.byte 0x12, 0x28, 0x39, 0x30, 0x3a, 0x00, 0x31, 0x08
	.byte 0x00, 0xda, 0xa8, 0x1d, 0x0d, 0x6f, 0xf0, 0x30
	.byte 0x08, 0x00, 0x1d, 0x6f, 0x74, 0xf0, 0xbf, 0x10
	.byte 0x37, 0x0e, 0xef, 0x6c, 0xbf, 0x02, 0x31, 0xc9
	.byte 0xd8, 0x6e, 0x4a, 0xd8, 0xa8, 0x1d, 0x11, 0x6b
	.byte 0xf0, 0x8f, 0x02, 0x21, 0xc9, 0xcc, 0x0f, 0xc9
	.byte 0xcf, 0x0b, 0x76, 0xa8, 0x00, 0xc9, 0xcf, 0x0b
	.byte 0x7b, 0xa2, 0x00, 0xc9, 0x61, 0x8f, 0x02, 0x3c
	.byte 0xf0, 0x8f, 0x02, 0xe9, 0x8f, 0x02, 0x23, 0xd9
	.byte 0x12, 0xd8, 0xa8, 0x1d, 0x04, 0x6b, 0xf0, 0xbf
	.byte 0x02, 0x32, 0x0b, 0x0f, 0x00, 0xd8, 0xa8, 0x31
	.byte 0x5d, 0x00, 0x1d, 0xb0, 0x61, 0xf0, 0x30, 0x3a
	.byte 0x00, 0xd9, 0xa9, 0x1d, 0x46, 0x61, 0xf0, 0x1d
	.byte 0xa7, 0x98, 0xf0, 0x68, 0x70, 0xd8, 0xa8, 0x1d
	.byte 0x11, 0x6b, 0xf0, 0xb7, 0x30, 0x1d, 0x8b, 0x61
	.byte 0xf0, 0xbf, 0x02, 0xcf, 0x66, 0x1b, 0xbf, 0x02
	.byte 0xb7, 0xd8, 0xac, 0x31, 0x40, 0x00, 0xda, 0xa8
	.byte 0x1d, 0x49, 0x97, 0xf0, 0x87, 0x21, 0xd8, 0x12
	.byte 0x0b, 0x40, 0x00, 0xd9, 0xac, 0xda, 0xa8, 0x68
	.byte 0x1a, 0xbf, 0x02, 0xbf, 0xd8, 0xac, 0x31, 0x40
	.byte 0x00, 0xda, 0xa9, 0x1d, 0x49, 0x97, 0xf0, 0x87
	.byte 0x21, 0xd8, 0x12, 0x0b, 0x40, 0x00, 0xd9, 0xac
	.byte 0x32, 0x40, 0x00, 0x1d, 0x53, 0xaa, 0xfd, 0x8f
	.byte 0x02, 0x23, 0xd9, 0x12, 0xd8, 0xa8, 0x1d, 0x04
	.byte 0x6b, 0xf0, 0xbf, 0x02, 0x32, 0x0b, 0x80, 0x00
	.byte 0xd8, 0xa8, 0x31, 0x5d, 0x00, 0x1d, 0xb0, 0x61
	.byte 0xf0, 0x0b, 0x00, 0x00, 0x0b, 0x3a, 0x00, 0x1d
	.byte 0x31, 0xef, 0xf0, 0xef, 0x64, 0xef, 0x64, 0x0e
	.byte 0xef, 0x6a, 0xb7, 0x31, 0xc9, 0xd8, 0x6e, 0x40
	.byte 0xd8, 0xa8, 0x1d, 0x11, 0x6b, 0xf0, 0x87, 0x21
	.byte 0xc9, 0xcc, 0x0f, 0x66, 0x67, 0xc9, 0xcf, 0x0b
	.byte 0x6b, 0x62, 0xc9, 0x69, 0x87, 0x3c, 0xf0, 0x87
	.byte 0xe9, 0x87, 0x23, 0xd9, 0x12, 0xd8, 0xa8, 0x1d
	.byte 0x04, 0x6b, 0xf0, 0xb7, 0x32, 0x0b, 0x0f, 0x00
	.byte 0xd8, 0xa8, 0x31, 0x5d, 0x00, 0x1d, 0xb0, 0x61
	.byte 0xf0, 0x30, 0x3a, 0x00, 0xd9, 0xa9, 0x1d, 0x46
	.byte 0x61, 0xf0, 0x1d, 0xa7, 0x98, 0xf0, 0x68, 0x34
	.byte 0xd8, 0xa8, 0x1d, 0x11, 0x6b, 0xf0, 0xb7, 0xce
	.byte 0x66, 0x04, 0xb7, 0xb6, 0x68, 0x02, 0xb7, 0xbe
	.byte 0x87, 0x23, 0xd9, 0x12, 0xd8, 0xa8, 0x1d, 0x04
	.byte 0x6b, 0xf0, 0xb7, 0x32, 0x0b, 0x40, 0x00, 0xd8
	.byte 0xa8, 0x31, 0x5d, 0x00, 0x1d, 0xb0, 0x61, 0xf0
	.byte 0x0b, 0x00, 0x00, 0x0b, 0x3a, 0x00, 0x1d, 0x31
	.byte 0xef, 0xf0, 0xef, 0x64, 0xef, 0x62, 0x0e, 0xc9
	.byte 0xd8, 0xb0, 0xfe, 0x30, 0x20, 0x00, 0xd9, 0xa8
	.byte 0x1d, 0x46, 0x61, 0xf0, 0x0e, 0xef, 0x6a, 0xc9
	.byte 0xd8, 0x66, 0x2c, 0xb7, 0x30, 0x1d, 0x23, 0x74
	.byte 0xf0, 0x87, 0x21, 0xd8, 0x12, 0x31, 0x3e, 0x00
	.byte 0x1d, 0x66, 0x62, 0xf0, 0x87, 0x21, 0xd8, 0x12
	.byte 0x1d, 0x99, 0x67, 0xf0, 0x30, 0x23, 0x00, 0x1d
	.byte 0x6a, 0x61, 0xf0, 0xd8, 0xa9, 0x1d, 0x3a, 0x97
	.byte 0xf0, 0xd8, 0xa8, 0x1d, 0x77, 0x95, 0xf0, 0xef
	.byte 0x62, 0x0e, 0xef, 0x6e, 0xc9, 0xd8, 0x6e, 0x6a
	.byte 0xbf, 0x04, 0x30, 0x1d, 0x23, 0x74, 0xf0, 0x8f
	.byte 0x04, 0x3f, 0x27, 0x6f, 0x5d, 0x8f, 0x04, 0x61
	.byte 0x8f, 0x04, 0x21, 0xd8, 0x12, 0x1d, 0x28, 0x74
	.byte 0xf0, 0xb7, 0x32, 0x8f, 0x04, 0x21, 0xd8, 0x12
	.byte 0xe8, 0x12, 0xd8, 0x0a, 0x14, 0x00, 0xb2, 0x41
	.byte 0xba, 0x01, 0x31, 0x8f, 0x04, 0x21, 0xd8, 0x12
	.byte 0xe8, 0x12, 0xd8, 0x0a, 0x14, 0x00, 0xd7, 0xe2
	.byte 0x88, 0xb1, 0x41, 0x82, 0x61, 0x81, 0x61, 0x82
	.byte 0x23, 0xd9, 0x12, 0xd8, 0xa8, 0x1d, 0x04, 0x6b
	.byte 0xf0, 0x8f, 0x01, 0x23, 0xd9, 0x12, 0xd8, 0xa9
	.byte 0x1d, 0x04, 0x6b, 0xf0, 0x0b, 0x00, 0x00, 0x0b
	.byte 0x3e, 0x00, 0x1d, 0x31, 0xef, 0xf0, 0x0b, 0x01
	.byte 0x00, 0x0b, 0x3e, 0x00, 0x1d, 0x31, 0xef, 0xf0
	.byte 0xef, 0x60, 0xef, 0x66, 0x0e, 0xef, 0x6e, 0xc9
	.byte 0xd8, 0x6e, 0x6a, 0xbf, 0x04, 0x30, 0x1d, 0x23
	.byte 0x74, 0xf0, 0x8f, 0x04, 0x3f, 0x00, 0x66, 0x5d
	.byte 0x8f, 0x04, 0x69, 0x8f, 0x04, 0x21, 0xd8, 0x12
	.byte 0x1d, 0x28, 0x74, 0xf0, 0xb7, 0x32, 0x8f, 0x04
	.byte 0x21, 0xd8, 0x12, 0xe8, 0x12, 0xd8, 0x0a, 0x14
	.byte 0x00, 0xb2, 0x41, 0xba, 0x01, 0x31, 0x8f, 0x04
	.byte 0x21, 0xd8, 0x12, 0xe8, 0x12, 0xd8, 0x0a, 0x14
	.byte 0x00, 0xd7, 0xe2, 0x88, 0xb1, 0x41, 0x82, 0x61
	.byte 0x81, 0x61, 0x82, 0x23, 0xd9, 0x12, 0xd8, 0xa8
	.byte 0x1d, 0x04, 0x6b, 0xf0, 0x8f, 0x01, 0x23, 0xd9
	.byte 0x12, 0xd8, 0xa9, 0x1d, 0x04, 0x6b, 0xf0, 0x0b
	.byte 0x00, 0x00, 0x0b, 0x3e, 0x00, 0x1d, 0x31, 0xef
	.byte 0xf0, 0x0b, 0x01, 0x00, 0x0b, 0x3e, 0x00, 0x1d
	.byte 0x31, 0xef, 0xf0, 0xef, 0x60, 0xef, 0x66, 0x0e
	.byte 0xc9, 0xd8, 0xb0, 0xfe, 0x30, 0x3f, 0x00, 0xd9
	.byte 0xa8, 0x1d, 0x46, 0x61, 0xf0, 0x0e, 0xc9, 0xd8
	.byte 0xb0, 0xfe, 0xd8, 0xa8, 0x1d, 0x77, 0x95, 0xf0
	.byte 0x30, 0x20, 0x00, 0xd9, 0xa8, 0x1d, 0x46, 0x61
	.byte 0xf0, 0x0e, 0x78, 0x87, 0x01, 0x78, 0xdd, 0x01
	.byte 0x78, 0x40, 0x02, 0x78, 0x14, 0x03, 0x78, 0xd2
	.byte 0x03, 0x78, 0x42, 0x04, 0xc9, 0x8b, 0xcb, 0x30
	.byte 0x07, 0x30, 0x00, 0x80, 0xcb, 0xd8, 0x6e, 0x02
	.byte 0xd8, 0xa8, 0x78, 0x7d, 0x04, 0x78, 0xf3, 0x04
	.byte 0xef, 0x6c, 0xd7, 0xfa, 0x04, 0xc9, 0xd8, 0x6e
	.byte 0x05, 0x1e, 0x33, 0x05, 0x68, 0x52, 0xbf, 0x02
	.byte 0x30, 0x1d, 0x81, 0x95, 0xf0, 0x8f, 0x02, 0x3f
	.byte 0x01, 0x66, 0x45, 0xc7, 0xfb, 0xa8, 0xc7, 0xfb
	.byte 0x89, 0xd8, 0x12, 0xbf, 0x04, 0x31, 0x1d, 0x3f
	.byte 0x74, 0xf0, 0xbf, 0x04, 0x31, 0xe9, 0x88, 0x1d
	.byte 0x23, 0x24, 0xfb, 0xc7, 0xfb, 0x89, 0xd8, 0x12
	.byte 0xe8, 0x12, 0xc9, 0x8b, 0xbf, 0x04, 0x32, 0x0b
	.byte 0x7f, 0x00, 0xd8, 0xa8, 0x1d, 0xb0, 0x61, 0xf0
	.byte 0xc7, 0xfb, 0x61, 0xc7, 0xfb, 0xcf, 0x10, 0x67
	.byte 0xcd, 0xd8, 0xa8, 0x1d, 0x3a, 0x97, 0xf0, 0x30
	.byte 0x3e, 0x00, 0xd9, 0xa8, 0x1d, 0x46, 0x61, 0xf0
	.byte 0xd7, 0xfa, 0x05, 0xef, 0x64, 0x0e, 0xc9, 0xd8
	.byte 0xb0, 0xfe, 0x78, 0x17, 0x05, 0xbf, 0xec, 0x37
	.byte 0xd7, 0xfa, 0x04, 0xc9, 0xd8, 0x7e, 0x82, 0x00
	.byte 0xbf, 0x02, 0x30, 0x1d, 0x81, 0x95, 0xf0, 0x8f
	.byte 0x02, 0x3f, 0x01, 0x6e, 0x39, 0xbf, 0x04, 0x31
	.byte 0xd8, 0xa9, 0x32, 0x0d, 0x00, 0x1d, 0x79, 0x72
	.byte 0xf0, 0xc7, 0xfb, 0xa8, 0xc7, 0xfb, 0x89, 0xd8
	.byte 0x12, 0xd8, 0x89, 0xe9, 0x12, 0xbf, 0x04, 0x32
	.byte 0xf3, 0x07, 0xe8, 0xe0, 0x32, 0x0b, 0x7f, 0x00
	.byte 0xd8, 0xa8, 0x1d, 0xf2, 0x65, 0xf0, 0xc7, 0xfb
	.byte 0x61, 0xc7, 0xfb, 0xcf, 0x0d, 0x67, 0xdd, 0x30
	.byte 0x3d, 0x00, 0xd9, 0xa8, 0x68, 0x38, 0xc7, 0xfb
	.byte 0xa8, 0xc7, 0xfb, 0x89, 0xd8, 0x12, 0xbf, 0x14
	.byte 0x31, 0x1d, 0x3f, 0x74, 0xf0, 0xc7, 0xfb, 0x89
	.byte 0xd8, 0x12, 0xe8, 0x12, 0xc9, 0x8b, 0xbf, 0x14
	.byte 0x32, 0x0b, 0x7f, 0x00, 0xd8, 0xa8, 0x1d, 0xb0
	.byte 0x61, 0xf0, 0xc7, 0xfb, 0x61, 0xc7, 0xfb, 0xcf
	.byte 0x10, 0x67, 0xd6, 0xd8, 0xa8, 0x1d, 0x3a, 0x97
	.byte 0xf0, 0x30, 0x3e, 0x00, 0xd9, 0xa8, 0x1d, 0x46
	.byte 0x61, 0xf0, 0xd7, 0xfa, 0x05, 0xbf, 0x14, 0x37
	.byte 0x0e, 0xef, 0x6c, 0xc9, 0x8b, 0xcb, 0xcc, 0x1f
	.byte 0xcb, 0xcf, 0x10, 0x63, 0x02, 0x23, 0x10, 0xd9
	.byte 0x12, 0xd8, 0xaa, 0x1d, 0x04, 0x6b, 0xf0, 0xbf
	.byte 0x02, 0x31, 0xd8, 0xa8, 0x1d, 0x3f, 0x74, 0xf0
	.byte 0x8f, 0x02, 0x21, 0xd8, 0x12, 0xb7, 0x31, 0x1d
	.byte 0xc6, 0x74, 0xf0, 0x87, 0x23, 0xd9, 0x12, 0xd8
	.byte 0xa9, 0x1d, 0x04, 0x6b, 0xf0, 0xd8, 0xa8, 0xd9
	.byte 0xa8, 0x1d, 0x04, 0x6b, 0xf0, 0x0b, 0x3f, 0x00
	.byte 0x1d, 0x40, 0xee, 0xf0, 0xef, 0x62, 0xd8, 0xa9
	.byte 0x1d, 0x53, 0x74, 0xf0, 0xd8, 0xa8, 0x31, 0x08
	.byte 0x00, 0xda, 0xa8, 0x1d, 0x59, 0x74, 0xf0, 0xd8
	.byte 0xa9, 0xd9, 0xae, 0xda, 0xa8, 0x1d, 0x59, 0x74
	.byte 0xf0, 0xef, 0x64, 0x0e, 0xef, 0x6e, 0xbf, 0x04
	.byte 0x31, 0xd8, 0xa8, 0x1d, 0x11, 0x6b, 0xf0, 0x8f
	.byte 0x04, 0x3f, 0x00, 0x66, 0x45, 0x8f, 0x04, 0x69
	.byte 0x8f, 0x04, 0x23, 0xd9, 0x12, 0xd8, 0xa8, 0x1d
	.byte 0x04, 0x6b, 0xf0, 0x8f, 0x04, 0x21, 0xd8, 0x12
	.byte 0xbf, 0x02, 0x31, 0x1d, 0x3f, 0x74, 0xf0, 0x8f
	.byte 0x02, 0x21, 0xd8, 0x12, 0xb7, 0x31, 0x1d, 0xc6
	.byte 0x74, 0xf0, 0x87, 0x23, 0xd9, 0x12, 0xd8, 0xa9
	.byte 0x1d, 0x04, 0x6b, 0xf0, 0x0b, 0x00, 0x00, 0x0b
	.byte 0x3f, 0x00, 0x1d, 0x31, 0xef, 0xf0, 0x0b, 0x01
	.byte 0x00, 0x0b, 0x3f, 0x00, 0x1d, 0x31, 0xef, 0xf0
	.byte 0xef, 0x60, 0xef, 0x66, 0x0e, 0xef, 0x68, 0xbf
	.byte 0x06, 0x31, 0xd8, 0xa8, 0x1d, 0x11, 0x6b, 0xf0
	.byte 0xb7, 0x31, 0xd8, 0xaa, 0x1d, 0x11, 0x6b, 0xf0
	.byte 0x87, 0x21, 0xc9, 0x69, 0x8f, 0x06, 0xf9, 0x6f
	.byte 0x47, 0x8f, 0x06, 0x61, 0x8f, 0x06, 0x23, 0xd9
	.byte 0x12, 0xd8, 0xa8, 0x1d, 0x04, 0x6b, 0xf0, 0x8f
	.byte 0x06, 0x21, 0xd8, 0x12, 0xbf, 0x04, 0x31, 0x1d
	.byte 0x3f, 0x74, 0xf0, 0x8f, 0x04, 0x21, 0xd8, 0x12
	.byte 0xbf, 0x02, 0x31, 0x1d, 0xc6, 0x74, 0xf0, 0x8f
	.byte 0x02, 0x23, 0xd9, 0x12, 0xd8, 0xa9, 0x1d, 0x04
	.byte 0x6b, 0xf0, 0x0b, 0x00, 0x00, 0x0b, 0x3f, 0x00
	.byte 0x1d, 0x31, 0xef, 0xf0, 0x0b, 0x01, 0x00, 0x0b
	.byte 0x3f, 0x00, 0x1d, 0x31, 0xef, 0xf0, 0xef, 0x60
	.byte 0xef, 0x60, 0x0e, 0xbf, 0xe8, 0x37, 0xd7, 0xfa
	.byte 0x04, 0xbf, 0x02, 0x31, 0xd8, 0xaa, 0x1d, 0x11
	.byte 0x6b, 0xf0, 0xc7, 0xfb, 0xa8, 0xc7, 0xfb, 0x89
	.byte 0xd8, 0x12, 0xbf, 0x06, 0x31, 0xf3, 0x07, 0xe4
	.byte 0xe0, 0x31, 0x1d, 0x3f, 0x74, 0xf0, 0xc7, 0xfb
	.byte 0x61, 0xc7, 0xfb, 0xcf, 0x0f, 0x63, 0xe6, 0x8f
	.byte 0x02, 0x23, 0xcb, 0x69, 0xd9, 0x12, 0xbf, 0x06
	.byte 0x30, 0xc3, 0x07, 0xe0, 0xe4, 0x3f, 0x20, 0x7e
	.byte 0x91, 0x00, 0xbf, 0x18, 0x31, 0xd8, 0xa8, 0x1d
	.byte 0x11, 0x6b, 0xf0, 0xc7, 0xfb, 0xa8, 0x8f, 0x02
	.byte 0x21, 0x8f, 0x18, 0xa1, 0xc9, 0x69, 0xc7, 0xe2
	.byte 0x99, 0x8f, 0x02, 0x27, 0xcf, 0x69, 0xbf, 0x06
	.byte 0x31, 0xe9, 0x8c, 0x8f, 0x02, 0x25, 0xcd, 0xc8
	.byte 0xfe, 0xda, 0x12, 0xdb, 0x12, 0xc7, 0xfb, 0x89
	.byte 0xc7, 0xe2, 0xf1, 0x6f, 0x1d, 0xdb, 0x8d, 0xda
	.byte 0x88, 0xc3, 0x07, 0xf0, 0xe0, 0x21, 0xf3, 0x07
	.byte 0xf0, 0xf4, 0x41, 0xc7, 0xfb, 0x61, 0xdb, 0x69
	.byte 0xda, 0x69, 0xc7, 0xfb, 0x89, 0xc7, 0xe2, 0xf1
	.byte 0x67, 0xe3, 0x8f, 0x18, 0x21, 0xd8, 0x12, 0xf3
	.byte 0x07, 0xe4, 0xe0, 0x00, 0x20, 0xd8, 0xa9, 0x32
	.byte 0x10, 0x00, 0x1d, 0xe9, 0x71, 0xf0, 0x8f, 0x18
	.byte 0x23, 0xd9, 0x12, 0xbf, 0x06, 0x30, 0xc3, 0x07
	.byte 0xe0, 0xe4, 0x21, 0xd8, 0x12, 0xbf, 0x04, 0x31
	.byte 0x1d, 0xc6, 0x74, 0xf0, 0x8f, 0x04, 0x23, 0xd9
	.byte 0x12, 0xd8, 0xa9, 0x1d, 0x04, 0x6b, 0xf0, 0x0b
	.byte 0x01, 0x00, 0x0b, 0x3f, 0x00, 0x1d, 0x31, 0xef
	.byte 0xf0, 0xef, 0x64, 0xd7, 0xfa, 0x05, 0xbf, 0x18
	.byte 0x37, 0x0e, 0xbf, 0xe8, 0x37, 0xd7, 0xfa, 0x04
	.byte 0xbf, 0x02, 0x31, 0xd8, 0xaa, 0x1d, 0x11, 0x6b
	.byte 0xf0, 0xc7, 0xfb, 0xa8, 0xc7, 0xfb, 0x89, 0xd8
	.byte 0x12, 0xbf, 0x06, 0x31, 0xf3, 0x07, 0xe4, 0xe0
	.byte 0x31, 0x1d, 0x3f, 0x74, 0xf0, 0xc7, 0xfb, 0x61
	.byte 0xc7, 0xfb, 0xcf, 0x0f, 0x63, 0xe6, 0xbf, 0x18
	.byte 0x31, 0xd8, 0xa8, 0x1d, 0x11, 0x6b, 0xf0, 0x8f
	.byte 0x18, 0x21, 0xc7, 0xfb, 0x99, 0x8f, 0x02, 0x23
	.byte 0xcb, 0x69, 0xcb, 0x8f, 0xc7, 0xfb, 0x89, 0xcf
	.byte 0xf1, 0x6f, 0x2b, 0xbf, 0x06, 0x32, 0xc7, 0xfb
	.byte 0x8b, 0xd9, 0x12, 0xd8, 0xa9, 0xd8, 0x81, 0xd9
	.byte 0x8c, 0x30, 0xff, 0xff, 0xd8, 0x84, 0xd9, 0x88
	.byte 0xc3, 0x07, 0xe8, 0xe0, 0x21, 0xf3, 0x07, 0xe8
	.byte 0xf0, 0x41, 0xc7, 0xfb, 0x61, 0xd9, 0x61, 0xc7
	.byte 0xfb, 0x89, 0xcf, 0xf1, 0x67, 0xe1, 0x8f, 0x02
	.byte 0x21, 0xc9, 0x69, 0xd8, 0x12, 0xbf, 0x06, 0x31
	.byte 0xf3, 0x07, 0xe4, 0xe0, 0x00, 0x20, 0xd8, 0xa9
	.byte 0x32, 0x10, 0x00, 0x1d, 0xe9, 0x71, 0xf0, 0x8f
	.byte 0x18, 0x23, 0xd9, 0x12, 0xbf, 0x06, 0x30, 0xc3
	.byte 0x07, 0xe0, 0xe4, 0x21, 0xd8, 0x12, 0xbf, 0x04
	.byte 0x31, 0x1d, 0xc6, 0x74, 0xf0, 0x8f, 0x04, 0x23
	.byte 0xd9, 0x12, 0xd8, 0xa9, 0x1d, 0x04, 0x6b, 0xf0
	.byte 0x0b, 0x01, 0x00, 0x0b, 0x3f, 0x00, 0x1d, 0x31
	.byte 0xef, 0xf0, 0xef, 0x64, 0xd7, 0xfa, 0x05, 0xbf
	.byte 0x18, 0x37, 0x0e, 0xef, 0x6e, 0xbf, 0x04, 0x31
	.byte 0xd8, 0xa8, 0x1d, 0x11, 0x6b, 0xf0, 0x8f, 0x04
	.byte 0x21, 0xd8, 0x12, 0xbf, 0x02, 0x31, 0x1d, 0x3f
	.byte 0x74, 0xf0, 0xbf, 0x02, 0x32, 0x82, 0x21, 0xc9
	.byte 0xcf, 0x41, 0x67, 0x3e, 0xc9, 0xcf, 0x5a, 0x6b
	.byte 0x39, 0xc9, 0xca, 0x41, 0x23, 0x61, 0xcb, 0x81
	.byte 0xb2, 0x41, 0x8f, 0x04, 0x21, 0xd8, 0x12, 0x82
	.byte 0x23, 0xd9, 0x12, 0x1d, 0x2d, 0x74, 0xf0, 0x8f
	.byte 0x02, 0x21, 0xd8, 0x12, 0xb7, 0x31, 0x1d, 0xc6
	.byte 0x74, 0xf0, 0x87, 0x23, 0xd9, 0x12, 0xd8, 0xa9
	.byte 0x1d, 0x04, 0x6b, 0xf0, 0x0b, 0x01, 0x00, 0x0b
	.byte 0x3f, 0x00, 0x1d, 0x31, 0xef, 0xf0, 0xef, 0x64
	.byte 0x68, 0x11, 0xc9, 0xcf, 0x61, 0x67, 0x0c, 0xc9
	.byte 0xcf, 0x7a, 0x6b, 0x07, 0xc9, 0xca, 0x61, 0x23
	.byte 0x41, 0x68, 0xbb, 0xef, 0x66, 0x0e, 0xef, 0x6e
	.byte 0xb7, 0x31, 0xd8, 0xa9, 0x1d, 0x11, 0x6b, 0xf0
	.byte 0x87, 0x3f, 0x00, 0x66, 0x3a, 0x87, 0x69, 0x87
	.byte 0x23, 0xd9, 0x12, 0xd8, 0xa9, 0x1d, 0x04, 0x6b
	.byte 0xf0, 0x87, 0x21, 0xd8, 0x12, 0xbf, 0x02, 0x31
	.byte 0x1d, 0xae, 0x74, 0xf0, 0xbf, 0x04, 0x31, 0xd8
	.byte 0xa8, 0x1d, 0x11, 0x6b, 0xf0, 0x8f, 0x04, 0x21
	.byte 0xd8, 0x12, 0x8f, 0x02, 0x23, 0xd9, 0x12, 0x1d
	.byte 0x2d, 0x74, 0xf0, 0x0b, 0x01, 0x00, 0x0b, 0x3f
	.byte 0x00, 0x1d, 0x31, 0xef, 0xf0, 0xef, 0x64, 0xef
	.byte 0x66, 0x0e, 0xef, 0x6e, 0xd7, 0xfa, 0x04, 0xd8
	.byte 0xcc, 0x00, 0x80, 0xd8, 0xd8, 0xc9, 0x7e, 0xc7
	.byte 0xfb, 0x99, 0xbf, 0x04, 0x31, 0xd8, 0xa9, 0x1d
	.byte 0x11, 0x6b, 0xf0, 0xc7, 0xfb, 0xd8, 0x6e, 0x0c
	.byte 0x8f, 0x04, 0x3f, 0x10, 0x67, 0x4f, 0x8f, 0x04
	.byte 0x3a, 0x10, 0x68, 0x0f, 0x8f, 0x04, 0x21, 0xc9
	.byte 0xc8, 0x10, 0xc9, 0xcf, 0x5f, 0x6b, 0x3e, 0x8f
	.byte 0x04, 0x38, 0x10, 0x8f, 0x04, 0x23, 0xd9, 0x12
	.byte 0xd8, 0xa9, 0x1d, 0x04, 0x6b, 0xf0, 0x8f, 0x04
	.byte 0x21, 0xd8, 0x12, 0xbf, 0x02, 0x31, 0x1d, 0xae
	.byte 0x74, 0xf0, 0xbf, 0x06, 0x31, 0xd8, 0xa8, 0x1d
	.byte 0x11, 0x6b, 0xf0, 0x8f, 0x06, 0x21, 0xd8, 0x12
	.byte 0x8f, 0x02, 0x23, 0xd9, 0x12, 0x1d, 0x2d, 0x74
	.byte 0xf0, 0x0b, 0x01, 0x00, 0x0b, 0x3f, 0x00, 0x1d
	.byte 0x31, 0xef, 0xf0, 0xef, 0x64, 0xd7, 0xfa, 0x05
	.byte 0xef, 0x66, 0x0e, 0xef, 0x6e, 0xb7, 0x31, 0xd8
	.byte 0xa9, 0x1d, 0x11, 0x6b, 0xf0, 0x87, 0x3f, 0x5f
	.byte 0x6f, 0x3a, 0x87, 0x61, 0x87, 0x23, 0xd9, 0x12
	.byte 0xd8, 0xa9, 0x1d, 0x04, 0x6b, 0xf0, 0x87, 0x21
	.byte 0xd8, 0x12, 0xbf, 0x02, 0x31, 0x1d, 0xae, 0x74
	.byte 0xf0, 0xbf, 0x04, 0x31, 0xd8, 0xa8, 0x1d, 0x11
	.byte 0x6b, 0xf0, 0x8f, 0x04, 0x21, 0xd8, 0x12, 0x8f
	.byte 0x02, 0x23, 0xd9, 0x12, 0x1d, 0x2d, 0x74, 0xf0
	.byte 0x0b, 0x01, 0x00, 0x0b, 0x3f, 0x00, 0x1d, 0x31
	.byte 0xef, 0xf0, 0xef, 0x64, 0xef, 0x66, 0x0e, 0xd7
	.byte 0xfa, 0x04, 0xc7, 0xfb, 0xa8, 0xc7, 0xfb, 0x89
	.byte 0xd8, 0x12, 0x31, 0x20, 0x00, 0x1d, 0x2d, 0x74
	.byte 0xf0, 0xc7, 0xfb, 0x61, 0xc7, 0xfb, 0xcf, 0x0f
	.byte 0x63, 0xeb, 0xd8, 0xa8, 0xd9, 0xa8, 0x1d, 0x04
	.byte 0x6b, 0xf0, 0xd8, 0xa9, 0xd9, 0xa8, 0x1d, 0x04
	.byte 0x6b, 0xf0, 0x0b, 0x00, 0x00, 0x0b, 0x3f, 0x00
	.byte 0x1d, 0x31, 0xef, 0xf0, 0x0b, 0x01, 0x00, 0x0b
	.byte 0x3f, 0x00, 0x1d, 0x31, 0xef, 0xf0, 0xef, 0x60
	.byte 0xd7, 0xfa, 0x05, 0x0e, 0xbf, 0xd6, 0x37, 0x3e
	.byte 0xc7, 0xf9, 0xa8, 0xbf, 0x04, 0x31, 0xd8, 0xaa
	.byte 0x1d, 0x11, 0x6b, 0xf0, 0xbf, 0x06, 0x31, 0xd8
	.byte 0xa8, 0x1d, 0x11, 0x6b, 0xf0, 0xc7, 0xfa, 0xa8
	.byte 0xc7, 0xfa, 0x89, 0xd8, 0x12, 0xbf, 0x1c, 0x31
	.byte 0xf3, 0x07, 0xe4, 0xe0, 0x31, 0x1d, 0x3f, 0x74
	.byte 0xf0, 0xc7, 0xfa, 0x61, 0xc7, 0xfa, 0xcf, 0x0f
	.byte 0x63, 0xe6, 0xc7, 0xfa, 0xa8, 0x8f, 0x04, 0x21
	.byte 0xc9, 0x69, 0xc9, 0x8b, 0xc9, 0xd8, 0x67, 0x1d
	.byte 0xbf, 0x1c, 0x32, 0xc7, 0xfa, 0x89, 0xd8, 0x12
	.byte 0xc3, 0x07, 0xe8, 0xe0, 0x3f, 0x20, 0x6e, 0x17
	.byte 0xc7, 0xf9, 0x61, 0xc7, 0xfa, 0x61, 0xc7, 0xfa
	.byte 0x89, 0xcb, 0xf1, 0x63, 0xe6, 0xc7, 0xf9, 0x89
	.byte 0xcb, 0xf1, 0x63, 0x10, 0x78, 0xff, 0x00, 0xc7
	.byte 0xfa, 0x89, 0xc7, 0xfb, 0x99, 0xc7, 0xf9, 0x89
	.byte 0xcb, 0xf1, 0x6b, 0xf0, 0xc7, 0xfa, 0xa8, 0xcb
	.byte 0xd8, 0x67, 0x1f, 0xbf, 0x1c, 0x32, 0xcb, 0x89
	.byte 0xc7, 0xfa, 0xa1, 0xd8, 0x12, 0xc3, 0x07, 0xe8
	.byte 0xe0, 0x3f, 0x20, 0x6e, 0x0d, 0xc7, 0xf9, 0x61
	.byte 0xc7, 0xfa, 0x61, 0xc7, 0xfa, 0x89, 0xcb, 0xf1
	.byte 0x63, 0xe4, 0x8f, 0x04, 0x21, 0xc7, 0xf8, 0x99
	.byte 0xc7, 0xf9, 0xa1, 0xc7, 0xf8, 0x99, 0xc7, 0xf9
	.byte 0xef, 0x01, 0xbf, 0x0a, 0x30, 0xbf, 0x1c, 0x31
	.byte 0x32, 0x10, 0x00, 0x1d, 0x4c, 0x73, 0xf0, 0xc7
	.byte 0xfa, 0xa8, 0xc7, 0xf9, 0xd8, 0x63, 0x1a, 0xbf
	.byte 0x0a, 0x32, 0xd9, 0xa8, 0xd9, 0x88, 0xf3, 0x07
	.byte 0xe8, 0xe0, 0x00, 0x20, 0xc7, 0xfa, 0x61, 0xd9
	.byte 0x61, 0xc7, 0xfa, 0x89, 0xc7, 0xf9, 0xf1, 0x67
	.byte 0xeb, 0xc7, 0xf9, 0x89, 0xd8, 0x12, 0xbf, 0x0a
	.byte 0x31, 0xe8, 0x13, 0xe9, 0x80, 0xc7, 0xfb, 0x8b
	.byte 0xd9, 0x12, 0xbf, 0x1c, 0x32, 0xe9, 0x13, 0xea
	.byte 0x81, 0xc7, 0xf8, 0x8d, 0xda, 0x12, 0x1d, 0x4c
	.byte 0x73, 0xf0, 0xc7, 0xf9, 0x89, 0xc7, 0xf8, 0x81
	.byte 0xc7, 0xfa, 0x99, 0x8f, 0x04, 0x23, 0xcb, 0x69
	.byte 0xcb, 0x8d, 0xc7, 0xfa, 0x89, 0xcd, 0xf1, 0x6b
	.byte 0x1c, 0xbf, 0x0a, 0x33, 0xc7, 0xfa, 0x8b, 0xd9
	.byte 0x12, 0xd9, 0x88, 0xf3, 0x07, 0xec, 0xe0, 0x00
	.byte 0x20, 0xc7, 0xfa, 0x61, 0xd9, 0x61, 0xc7, 0xfa
	.byte 0x89, 0xcd, 0xf1, 0x63, 0xec, 0xbf, 0x0a, 0x31
	.byte 0xd8, 0xa9, 0x32, 0x10, 0x00, 0x1d, 0xe9, 0x71
	.byte 0xf0, 0x8f, 0x06, 0x21, 0xd8, 0x12, 0xbf, 0x0a
	.byte 0x31, 0xc3, 0x07, 0xe4, 0xe0, 0x21, 0xd8, 0x12
	.byte 0xbf, 0x08, 0x31, 0x1d, 0xc6, 0x74, 0xf0, 0x8f
	.byte 0x08, 0x23, 0xd9, 0x12, 0xd8, 0xa9, 0x1d, 0x04
	.byte 0x6b, 0xf0, 0x0b, 0x01, 0x00, 0x0b, 0x3f, 0x00
	.byte 0x1d, 0x31, 0xef, 0xf0, 0xef, 0x64, 0x5e, 0xbf
	.byte 0x2a, 0x37, 0x0e, 0xc9, 0xd8, 0x6e, 0x07, 0x30
	.byte 0x26, 0x00, 0xd9, 0xa8, 0x68, 0x05, 0x30, 0x2b
	.byte 0x00, 0xd9, 0xa8, 0x1b, 0x46, 0x61, 0xf0, 0xc9
	.byte 0xd8, 0x6e, 0x07, 0x30, 0x3b, 0x00, 0xd9, 0xa8
	.byte 0x68, 0x05, 0x30, 0x30, 0x00, 0xd9, 0xa8, 0x1b
	.byte 0x46, 0x61, 0xf0, 0xc9, 0xd8, 0xb0, 0xfe, 0x30
	.byte 0x3f, 0x00, 0xd9, 0xa8, 0x1d, 0x46, 0x61, 0xf0
	.byte 0xd8, 0xaa, 0x1d, 0x77, 0x95, 0xf0, 0x0e, 0xc9
	.byte 0xd8, 0xb0, 0xfe, 0x30, 0x20, 0x00, 0xd9, 0xa8
	.byte 0x1d, 0x46, 0x61, 0xf0, 0x0e, 0x0e
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
	lda xde, (0x020c33:24)
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
	ld	a, (35996:16)
	cp	(134200:24), a
	jr	nz, 30	; -> 0xF0E9F0
	cp	a, 32
	jr	c, 25	; -> 0xF0E9F0
	cp	a, 63
	jr	ugt, 20	; -> 0xF0E9F0
	sub	a, 32
	extz	wa
	sla	wa, 2
	lda	xbc, (14739245:24)
	ld_rrl	xhl, xbc, wa
	call	(xhl)
SeMenu_ValueEditor_Init:
	.byte 0xc1, 0x9c, 0x8c, 0x3f, 0x20	; cpdi8 (0x8d38), 32 (v7 patched)

	.byte 0x7e, 0xb5, 0x00	; jrl nz, SeMenu_ValueEditor_Data3 (v7 displacement)

	cp (0x020c38:24), 0x10

	.byte 0x7e, 0xac, 0x00	; jrl nz, SeMenu_ValueEditor_Data3 (v7 displacement)

	.byte 0x1e, 0xb0, 0x01	; calr SeMenu_NameEditor_Init (v7 displacement)

	.byte 0x78, 0x34, 0x01	; jrl SeMenu_ListSelector_ScrollDown (v7 displacement)



SeMenu_ValueEditor_Setup:
	call SeqBuf_SoundEdit_ReadByte
	lda xwa, (0x020c33:24)
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
	ld	e, (xwa+2)
	lda	xbc, (xwa+5)
	cp	e, 9
	jr	nz, 29
	cp	(35996:16), 34
	jr	nz, 114
	ld	a, (xbc)
	cp	a, 34
	jr	nz, 7
	call	15774643
	jrl	242
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
	cp	(35996:16), 38
	jr	nz, 75
	ld	a, (xbc)
	cp	a, 38
	jr	nz, 7
	call	15775684
	jrl	203
SeMenu_ValueEditor_ClampAndStore:
	cp a, 0x10
	jr nz, SeMenu_ValueEditor_Data3
	calr SeMenu_ListSelector_Data3
	jrl SeMenu_ListSelector_ScrollDown

SeMenu_ValueEditor_Redraw:
	.byte 0xcd, 0xcf, 0x10, 0x6e, 0x0b, 0xc1, 0x9c, 0x8c
	.byte 0x21, 0x81, 0xf1, 0x66, 0x16, 0x78, 0xb0, 0x00
SeMenu_ValueEditor_Complete:
	.byte 0xcd, 0xcf, 0x12, 0x6e, 0x1d, 0xc1, 0x9c, 0x8c
	.byte 0x3f, 0x20, 0x6e, 0x16, 0x81, 0x21, 0xc9, 0xcf
	.byte 0x20, 0x6e, 0x07
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
	ld	a, (35996:16)
	cp	c, a
	jr	nz, 41	; -> 0xF0EB3B
	cp	a, 32
	jr	c, 27	; -> 0xF0EB32
	cp	a, 63
	jr	ugt, 22	; -> 0xF0EB32
	sub	a, 32
	extz	wa
	sla	wa, 2
	lda	xbc, (14739245:24)
	ld_rrl	xhl, xbc, wa
	call	(xhl)
	jr	9	; -> 0xF0EB3B
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
	.incbin "includes/romslices/v7_transplant_SeMenu_NameEditor_End.bin"
SeMenu_DisplayPartValue:
	push	xiz
	ld	xiz, xsp
	push	xwa
	push	xbc
	push	xde
	push	xhl
	push	xix
	push	xiy
	ld	wa, (xiz+10)
	ldb	w, 255
	ld	de, (xiz+8)
	ldb	d, 0
	push	xiz
	call	16624640
	pop	xiz
	ld	wa, (xiz+12)
	ldb	w, 127
	ld	de, (xiz+8)
	ldb	d, 1
	push	xiz
	call	16624640
	pop	xiz
	call	16471590
	pop	xiy
	pop	xix
	pop	xhl
	pop	xde
	pop	xbc
	pop	xwa
	pop	xiz
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
	ldio	32, 241
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
	push XIZ
	ld XIZ,XSP
	push XWA
	push XBC
	push XDE
	push XHL
	push XIX
	push XIY
	ld HL,(XIZ+0x08)
	ld A,(XIZ+0x0a)
	sub HL,0x0020
	ld XIY,SeMenu_ShowConfirmDialog_Data
	sla HL, 0x02
	.byte 0xe3, 0x07, 0xf4, 0xec, 0x25, 0xb5, 0xe8, 0xc1
	.byte 0x1c, 0xe3, 0x3e, 0x08, 0x5d, 0x5c, 0x5b, 0x5a
	.byte 0x59, 0x58, 0x5e, 0x0e
SeMenu_ShowConfirmDialog_Data:
	.long SeMenu_PresetManager_Init
	.long SeMenu_NameEdit_Dispatch
	.long SeMenu_PatchEdit_Dispatch
	.long SeMenu_FilterEdit_Dispatch
	.long SeMenu_FilterEdit_AltDispatch
	.long SeMenu_FilterEdit_DataBlock3
	.long SeMenu_BankEdit_Dispatch
	.long SeMenu_DrumKit_Dispatch
	.long Data_UnknownBlock_0x6E + 382
	.long SeMenu_FilterEdit_DataBlock4
	.long Data_UnknownBlock
	.long Data_UnknownBlock_0x6E + 52
	.long Data_UnknownBlock_0x6E + 163
	.long Data_UnknownBlock_0x6E + 179
	.long Data_UnknownBlock_0x6E + 234
	.long Data_UnknownBlock
	.long Data_UnknownBlock_0x6E + 250
	.long Data_UnknownBlock_0x6E + 292
	.long Data_UnknownBlock_0x6E + 334
	.long Data_UnknownBlock_0x6E + 350
	.long Data_UnknownBlock_0x6E + 366
	.long SeMenu_WaveformSelect_End
	.long Data_UnknownBlock_0x6E + 163
	.long Data_UnknownBlock_0x6E + 382
	.long SeMenu_FilterEdit_DataBlock4
	.long Data_UnknownBlock
	.long SeMenu_PatchEdit_DataBlock
	.long SeMenu_EqEdit_Dispatch
	.long SeMenu_EqEdit_DrawInit
	.long SeMenu_WaveformSelect_End
	.long Data_UnknownBlock_0x23D + 317
	.long Data_UnknownBlock_0x23D + 336
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
	push XWA
	push XBC
	push XDE
	push XHL
	push XIX
	push XIY
	push XIZ
	ld (0x03efa8:24), 0x00
	ld XIY,SeBitmap_EnvCurve5_0x46B
	ld XIX,SeBitmap_EnvCurve5_0x492
	call SeMenu_NameEditor_Setup
	cp (0x065c:16), 0x00
	jr z, .Lc_f0f04e
	ld XIY,SeBitmap_EnvCurve5_0x492
	ld XIX,SeBitmap_EnvCurve5_0x49C
	jr t, .Lc_f0f05e
.Lc_f0f04e:
	ld (0x03efa8:24), 0x01
	ld XIY,SeBitmap_EnvCurve5_0x49C
	ld XIX,SeBitmap_EnvCurve5_0x4A6
.Lc_f0f05e:
	call SeMenu_NameEditor_Setup
	pop XIZ
	pop XIY
	pop XIX
	pop XHL
	pop XDE
	pop XBC
	pop XWA
	ret
	push XWA
	push XBC
	push XDE
	push XHL
	push XIX
	push XIY
	push XIZ
	cp (0x06ae:16), 0x01
	jr nz, .Lc_f0f090
	ld (0x03efa8:24), 0x00
	ld XIY,SeBitmap_EnvCurve5_0x313
	ld XIX,SeBitmap_EnvCurve5_0x31D
	call SeMenu_NameEditor_Setup
	ldb C, 0x02
	jr t, .Lc_f0f0a6
.Lc_f0f090:
	ld (0x03efa8:24), 0x00
	ld XIY,SeBitmap_EnvCurve5_0x313
	ld XIX,SeBitmap_EnvCurve5_0x327
	call SeMenu_NameEditor_Setup
	ldb C, 0x04
.Lc_f0f0a6:
	ld w, (0x065e:16)
	ld A,C
	sla A, 0x01
	dec 1,A
	.incbin "includes/romslices/v7_transplant_SeMenu_ShowConfirmDialog_Data_tail_mid0.bin"
	ld (0x03efa8:24), 0x00
	ldb C, 0x07
	ld ix, (0x06c6:16)
	ld iy, (0x06c8:16)
.Lc_f0f166:
	pushw ix
	pushw iy
	push C
	call SeMenu_ShowConfirmDialog_Data_0x331
	pop C
	popw iy
	popw ix
	add IX,0x001c
	dec 1,C
	jr nz, .Lc_f0f166
	ld ix, (0x06c6:16)
	ld iy, (0x06c8:16)
	ld (0x06cc:16), ix
	addw (0x06cc:16), 0x00c4
	ld (0x06d0:16), ix
	addw (0x06d0:16), 0x00c8
	ld (0x06ce:16), iy
	ld (0x06d2:16), iy
	addw (0x06d2:16), 0x000c
	call SeMenu_NameEditor_ChangeCase_Data
	ld ix, (0x06c6:16)
	ld iy, (0x06c8:16)
	add IX,0x00c4
	ld (0x06cc:16), ix
	ld (0x06d0:16), ix
	ld (0x06ce:16), iy
	subdi16 (0x06ce), 0x0005
	ld (0x06d2:16), iy
	subdi16 (0x06d2), 0x0001
	call SeMenu_NameEditor_ChangeCase_Data
	ld ix, (0x06c6:16)
	ld iy, (0x06c8:16)
	ld (0x06cc:16), ix
	subdi16 (0x06cc), 0x0008
	ld (0x06d0:16), ix
	ld (0x06ce:16), iy
	ld (0x06d2:16), iy
	addw (0x06d2:16), 0x000c
	call SeMenu_NameEditor_ChangeCase_Data
	ld ix, (0x06c6:16)
	ld iy, (0x06c8:16)
	ld (0x06cc:16), ix
	subdi16 (0x06cc), 0x0005
	ld (0x06d0:16), ix
	subdi16 (0x06d0), 0x0003
	ld (0x06ce:16), iy
	addw (0x06ce:16), 0x0001
	ld (0x06d2:16), iy
	addw (0x06d2:16), 0x0007
	call SeMenu_NameEditor_ChangeCase_Data
	ld ix, (0x06c6:16)
	ld iy, (0x06c8:16)
	sub IX,0x0004
	ld (0x06cc:16), ix
	ld (0x06d0:16), ix
	ld (0x06ce:16), iy
	addw (0x06ce:16), 0x0001
	ld (0x06d2:16), iy
	addw (0x06d2:16), 0x000b
	call SeMenu_NameEditor_InsertChar
	ld ix, (0x06c6:16)
	ld iy, (0x06c8:16)
	ld (0x06cc:16), ix
	addw (0x06cc:16), 0x001c
	ld (0x06d0:16), ix
	addw (0x06d0:16), 0x00ab
	ld (0x06ce:16), iy
	addw (0x06ce:16), 0x000d
	ld (0x06d2:16), iy
	addw (0x06d2:16), 0x000e
	call SeMenu_NameEditor_ChangeCase_Data
	ret
	ld (0x06cc:16), ix
	ld (0x06d0:16), ix
	ld (0x06ce:16), iy
	subdi16 (0x06ce), 0x0005
	ld (0x06d2:16), iy
	subdi16 (0x06d2), 0x0001
	pushw ix
	pushw iy
	call SeMenu_NameEditor_InsertChar
	popw iy
	popw ix
	ld (0x06cc:16), ix
	ld (0x06ce:16), iy
	ld (0x06d0:16), ix
	addw (0x06d0:16), 0x001c
	ld (0x06d2:16), iy
	addw (0x06d2:16), 0x000c
	pushw ix
	pushw iy
	call SeMenu_NameEditor_ChangeCase_Data
	popw iy
	popw ix
	ldb C, 0x05
	ld XIZ,SeMenu_ShowConfirmDialog_Data_0x3F4
.Lc_f0f2e0:
	ld HL,(XIZ)
	ld DE,(XIZ+0x02)
	add XIZ,0x00000004
	ld (0x06cc:16), ix
	.incbin "includes/romslices/v7_transplant_SeMenu_ShowConfirmDialog_Data_tail_tail_tail.bin"
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
	.byte 0xc1, 0xb8, 0x06, 0x3f, 0x01, 0x6e, 0x06, 0x1d
	.byte 0xdd, 0xf4, 0xf0, 0x68, 0x5f, 0xf2, 0xa8, 0xef
	.byte 0x03, 0x00, 0x00, 0xc1, 0xae, 0x06, 0x3f, 0x01
	.byte 0x66, 0x14, 0x45, 0x3e, 0x11, 0xf1, 0x00, 0x44
	.byte 0x61, 0x12, 0xf1, 0x00, 0x1d, 0xd6, 0xeb, 0xf0
	.byte 0x1d, 0x79, 0xf5, 0xf0, 0x68, 0x3e, 0x45, 0xfc
	.byte 0x5c, 0xf1, 0x00, 0x44, 0xc8, 0x5f, 0xf1, 0x00
	.byte 0x1d, 0xd6, 0xeb, 0xf0, 0x1d, 0x6d, 0xf8, 0xf0
	.byte 0x45, 0xdc, 0x5f, 0xf1, 0x00, 0x44, 0xc7, 0x60
	.byte 0xf1, 0x00, 0x1d, 0xe3, 0xeb, 0xf0, 0x1d, 0xa5
	.byte 0xf5, 0xf0, 0xf2, 0xa8, 0xef, 0x03, 0x00, 0x01
	.byte 0x45, 0xc8, 0x5f, 0xf1, 0x00, 0x44, 0xdc, 0x5f
	.byte 0xf1, 0x00, 0x1d, 0xd6, 0xeb, 0xf0, 0xf2, 0xa8
	.byte 0xef, 0x03, 0x00, 0x00, 0x0e
	ld (0x03efa8:24), 0x00
	cp (0x0661:16), 0x01
	jr z, .Lc_f0f596
	ld XIY,SeBitmap_EnvCurve5_0x2BD
	ld XIX,SeBitmap_EnvCurve5_0x2E9
	call SeMenu_NameEditor_Setup
	jr t, .Lc_f0f5a4
.Lc_f0f596:
	ld XIY,SeBitmap_EnvCurve5_0x2E9
	ld XIX,SeBitmap_EnvCurve5_0x313
	call SeMenu_NameEditor_Setup
.Lc_f0f5a4:
	ret
	.byte 0xf2, 0xa8, 0xef, 0x03, 0x00, 0x00, 0x21, 0x0d
	.byte 0x14, 0x1d, 0xbb, 0xf5, 0xf0, 0x15, 0xc9, 0x61
	.byte 0xc9, 0xcf, 0x0f, 0x67, 0xf3, 0x0e, 0xe9, 0xd1
	.byte 0xc8, 0xd0, 0xe8, 0x12, 0x41, 0x60, 0x06, 0x00
	.byte 0x00, 0xe8, 0x81, 0x81, 0x24, 0xcc, 0xd8, 0x66
	.byte 0x0f, 0x45, 0x01, 0x61, 0xf1, 0x00, 0xf2, 0xa8
	.byte 0xef, 0x03, 0x00, 0x00, 0x1d, 0xbd, 0x0b, 0xf1
	.byte 0x0e
SeMenu_PresetManager_Init:
	.byte 0xc1, 0xae, 0x06
	push	xsp
	normal
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
	ldb	a, 0
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
	.byte 0xf2, 0xa8, 0xef, 0x03, 0x00, 0x00, 0xc1, 0xae
	.byte 0x06, 0x3f, 0x01, 0x6e, 0x0e, 0x45, 0x45, 0x61
	.byte 0xf1, 0x00, 0x44, 0x0f, 0x62, 0xf1, 0x00, 0x1d
	.byte 0xd6, 0xeb, 0xf0
SeMenu_PresetManager_End:
	ret
SeMenu_PresetManager_Save:
	ld	(257960:24), 0
	ld	xiy, 15798580
	ld	xix, 15798590
	call	15789014
	call	16454011
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
	call	15792330
	cp	(1710:16), 1
	jr	z, 20
	ld	xiy, 15814194
	ld	xix, 15814646
	call	15789014
	call	15791819
	jr	28
	ld	xiy, 15814646
	ld	xix, 15814691
	call	15789014
	ld	xiy, 15814205
	ld	xix, 15814646
	call	15789014
	call	15790112
	call	15790186
	ld	(257960:24), 0
	ld	xiy, 15805265
	ld	xix, 15805276
	call	15789027
	call	15794653
	call	15792351
	ret
	cp (0x06ae:16), 0x01
	jr nz, .Lc_f0f79a
	ld (0x03efa8:24), 0x00
	ld XIY,SeBitmap_EnvCurve5_0x7B6
	ld XIX,SeBitmap_EnvCurve5_0x7C0
	call SeMenu_NameEditor_Setup
	ldb C, 0x02
	jr t, .Lc_f0f7b0
.Lc_f0f79a:
	ld (0x03efa8:24), 0x00
	ld XIY,SeBitmap_EnvCurve5_0x7B6
	ld XIX,SeBitmap_EnvCurve5_0x7CA
	call SeMenu_NameEditor_Setup
	ldb C, 0x04
.Lc_f0f7b0:
	ld w, (0x065e:16)
	ld A,C
	sla A, 0x01
	dec 1,A
	.byte 0xc8, 0xff
	jr	c, 34
	.byte 0xcb, 0x04
	xor	b, b
	sla	bc, 2
	ld	xiz, 15800274
	ld_rrl	xiy, xiz, bc
	add	bc, 4
	ld_rrl	xix, xiz, bc
	call	15789014
	pop c
	jr	32
	.byte 0xcb, 0x04
	xor	b, b
	sla	bc, 2
	ld	xiz, 15800202
	ld_rrl	xiy, xiz, bc
	add	bc, 4
	ld_rrl	xix, xiz, bc
	call	15789014
	pop c
	djnz8	c, -84
	ret
	ld (0x03efa8:24), 0x00
	cp (0x06ae:16), 0x01
	jr nz, .Lc_f0f816
	ldb C, 0x02
	jr t, .Lc_f0f818
.Lc_f0f816:
	ldb C, 0x04
.Lc_f0f818:
	ld w, (0x065e:16)
	ld A,C
	sla A, 0x01
	dec 1,A
	.byte 0xc8, 0xff
	jr	c, 34
	.byte 0xcb, 0x04
	xor	b, b
	sla	bc, 2
	ld	xiz, 15800494
	ld_rrl	xiy, xiz, bc
	add	bc, 4
	ld_rrl	xix, xiz, bc
	call	15789014
	pop c
	jr	32
	.byte 0xcb, 0x04
	xor	b, b
	sla	bc, 2
	ld	xiz, 15800374
	ld_rrl	xiy, xiz, bc
	add	bc, 4
	ld_rrl	xix, xiz, bc
	call	15789014
	pop c
	djnz8	c, -84
	ret
	ld (0x03efa8:24), 0x00
	ldb C, 0x02
	ld w, (0x065e:16)
	ld A,C
	sla A, 0x01
	dec 1,A
	.byte 0xc8, 0xff
	jr	c, 34
	.byte 0xcb, 0x04
	xor	b, b
	sla	bc, 2
	ld	xiz, 15800618
	ld_rrl	xiy, xiz, bc
	add	bc, 4
	ld_rrl	xix, xiz, bc
	call	15789014
	pop c
	jr	32
	.byte 0xcb, 0x04
	xor	b, b
	sla	bc, 2
	ld	xiz, 15800560
	ld_rrl	xiy, xiz, bc
	add	bc, 4
	ld_rrl	xix, xiz, bc
	call	15789014
	pop c
	djnz8	c, -84
	ret
	ld (0x03efa8:24), 0x00
	ld XIY,SeBitmap_EnvCurve5_0x5E2
	ld XIX,SeBitmap_EnvCurve5_0x60D
	call SeMenu_NameEditor_Setup
	ret
	ld (0x03efa8:24), 0x00
	ld XIY,SeBitmap_EnvCurve5_0x60D
	ld XIX,SeBitmap_EnvCurve5_0x612
	call SeMenu_NameEditor_Setup
	ret
	ld (0x03efa8:24), 0x00
	ld XIY,SeBitmap_EnvCurve5_0x50F
	ld XIX,SeBitmap_EnvCurve5_0x5E2
	call SeMenu_NameEditor_Setup
	ld (0x03efa8:24), 0x00
	ret
SeMenu_PresetBrowser_Init:
	call	15792450
	ld	xiy, 15800845
	ld	xix, 15801375
	call	15789014
	call	15790112
	call	15791995
	ld	(257960:24), 0
	ld	xiy, 15806907
	ld	xix, 15807125
	call	15789027
	call	15792471
	ret
SeMenu_PresetBrowser_Navigate:
	ld	(257960:24), 0
	ld	xiy, 15800634
	ld	xix, 15800810
	call	15789014
	ret
SeMenu_PresetBrowser_Select:
	ld	(257960:24), 0
	ld	xiy, 15800810
	ld	xix, 15800815
	call	15789014
	ret
SeMenu_PresetBrowser_Data:
	.byte 0x1d, 0x42, 0xf9, 0xf0, 0x1d, 0x57, 0xf9, 0xf0
	ld XIY,TuningSystem_Handler_Table_0xE1F
	ld XIX,TuningSystem_Handler_Table_0xFC4
	call SeMenu_NameEditor_Setup
	call SeMenu_PresetBrowser_Data_0x3B
	call SeMenu_ShowConfirmDialog_Data_0xC0
	call SeMenu_PresetBrowser_Data_0x98
	call Data_UnknownBlock_0x6E
	ld	(257960:24), 0
	ld	xiy, 15807577
	ld	xix, 15807658
	call	15789027
	ret
	ld	(257960:24), 0
	ldb	c, 4
	ld	w, (1630:16)
	ld	a, c
	sla	a, 1
	dec	1, a
	.byte 0xc8, 0xff
	jr	c, 34
	.byte 0xcb, 0x04
	xor	b, b
	sla	bc, 2
	ld	xiz, 15811653
	ld_rrl	xiy, xiz, bc
	add	bc, 4
	ld_rrl	xix, xiz, bc
	call	15789014
	pop c
	jr	32
	.byte 0xcb, 0x04
	xor	b, b
	sla	bc, 2
	ld	xiz, 15811581
	ld_rrl	xiy, xiz, bc
	add	bc, 4
	ld_rrl	xix, xiz, bc
	call	15789014
	pop c
	djnz8	c, -84
	ret
	ld	(257960:24), 1
	ld	xiy, 15807818
	ld	xix, 15807828
	call	15789014
	ld	(257960:24), 0
	ld	xiy, 15807898
	ld	xix, 15807908
	call	15789014
	ld	xiy, 15807908
	ld	xix, 15807918
	call	15789014
	ld	(257960:24), 2
	ld	xiy, 15807908
	ld	xix, 15807918
	call	15789014
	ldb	c, 4
	ld	xiy, 1637
	ld	w, (xiy)
	and	w, 32
	jrl	z, 187
	.byte 0xc8, 0x04, 0xcb, 0x04
	push	xiy
	ldb	d, 4
	sub	d, c
	ld	e, d
	xor	d, d
	sla	de, 2
	ld	xiz, 15807868
	ld_rrl	xiy, xiz, de
	pushw	de
	add	de, 4
	ld_rrl	xix, xiz, de
	call	15789014
	popw	de
	pop	xiy
	pop c
	pop w
	ld	(257960:24), 0
	.byte 0xcb, 0x04
	push	xiy
	ld	xiz, 15808222
	ld_rrl	xiy, xiz, de
	ld	xix, xiy
	add	xix, 7
	pushw	de
	call	15789014
	popw	de
	pop	xiy
	.byte 0xcb, 0x05, 0xcb, 0x04
	push	xiy
	ld	a, (xiy)
	and	a, 192
	srl	a, 6
	xor	w, w
	mul	a, 10
	ld	xiz, 15808178
	ld_rrl	xiy, xiz, de
	extz	xwa
	add	xiy, xwa
	ld	xix, xiy
	add	xix, 10
	pushw	de
	call	15789014
	popw	de
	pop	xiy
	.byte 0xcb, 0x05, 0xcb, 0x04
	push	xiy
	ld	xiz, 15807740
	ld_rrl	xiy, xiz, de
	pushw	de
	call	15789040
	popw	de
	pop	xiy
	pop c
	ld	(257960:24), 2
	.byte 0xcb, 0x04
	push	xiy
	ld	xiz, 15811677
	ld_rrl	xiy, xiz, de
	ld	xix, xiy
	add	xix, 20
	call	15789014
	pop	xiy
	pop c
	jr	0
	add	xiy, 1
	dec	1, c
	jrl	nz, -206
	ret
SeMenu_CompareAndApply_Init:
	call	15793043
	cp	(1710:16), 1
	jr	z, 20
	call	15791819
	ld	xiy, 15801964
	ld	xix, 15802201
	call	15789014
	jr	14
SeMenu_CompareAndApply_Check:
	ld	xiy, 15819279
	ld	xix, 15819433
	call	15789014
SeMenu_CompareAndApply_Match:
	call	15790112
	call	15791995
	call	15790952
	cp	(1710:16), 1
	jr	z, 22
	ld	(257960:24), 0
	ld	xiy, 15806315
	ld	xix, 15806454
	call	15789027
	jr	20
SeMenu_CompareAndApply_Apply:
	ld	(257960:24), 0
	ld	xiy, 15819648
	ld	xix, 15819703
	call	15789027
SeMenu_CompareAndApply_End:
	call SeMenu_CompareAndApply_Data4
	ret
SeMenu_CompareAndApply_Data:
	ld (0x03efa8:24), 0x00
	ld XIY,SeBitmap_EnvCurve5_0xCC1
	cp (0x06ae:16), 0x01
	jr z, SeMenu_CompareAndApply_Data2
	ld XIX,0x00f11d17
	jr t, SeMenu_CompareAndApply_Data3
SeMenu_CompareAndApply_Data2:
	ld	xix, 15801564
SeMenu_CompareAndApply_Data3:
	call SeMenu_NameEditor_Setup
	ret
SeMenu_CompareAndApply_Data4:
	ld	(257960:24), 0
	ld	xiy, 15801623
	ld	xix, 15801628
	call	15789014
	ret
SeMenu_CompareAndApply_Data5:
	.byte 0x1d, 0x20, 0xf0, 0xf0, 0x1d, 0x6a, 0xf0, 0xf0
	.byte 0x1d, 0x93
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
	call	15793043
	cp	(1710:16), 1
	jr	z, 40
	ld	xiy, 15802434
	ld	xix, 15802623
	call	15789014
	call	15793592
	ld	(257960:24), 2
	ld	xiy, 15804103
	ld	xix, 15804113
	call	15789014
	jr	28
	ld	xiy, 15802434
	ld	xix, 15802458
	call	15789014
	ld	xiy, 15819433
	ld	xix, 15819648
	call	15789014
	call	15790112
	call	15790186
	ld	(257960:24), 0
	cp	(1710:16), 1
	jr	z, 16
	ld	xiy, 15806628
	ld	xix, 15806698
	call	15789027
	jr	18
	ld	xiy, 15819757
	ld	xix, 15819823
	call	15789027
	call	15793335
	call	15793078
	ret
	ld	(257960:24), 0
	ld	a, (1632:16)
	and	a, 32
	jr	z, 36
	ld	xiy, 15819855
	ld	xix, 15819875
	call	15789027
	ld	(257960:24), 2
	ld	xiy, 15804103
	ld	xix, 15804125
	call	15789014
	jr	34
	ld	xiy, 15819875
	ld	xix, 15819889
	call	15789014
	ld	(257960:24), 2
	ld	xiy, 15804125
	ld	xix, 15804135
	call	15789014
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
	.byte 0x1d, 0xcb, 0xfd, 0xf0, 0x45, 0x67, 0x23, 0xf1
	.byte 0x00, 0x44, 0xb4, 0x24, 0xf1, 0x00, 0x1d, 0xd6
	.byte 0xeb, 0xf0, 0x45, 0xc9, 0x24, 0xf1, 0x00, 0x44
	.byte 0xdd, 0x24, 0xf1, 0x00, 0x1d, 0xd6, 0xeb, 0xf0
	.byte 0xc1, 0xae, 0x06, 0x3f, 0x01, 0x66, 0x04, 0x1d
	.byte 0xb8, 0xfd, 0xf0
SeMenu_Utility_CompareBlock_Loop:
	call	15790112
	call	15790186
	call	15793667
	ld	(257960:24), 0
	ld	xiy, 15805756
	ld	xix, 15805852
	call	15789027
	call	15793646
	ret
SeMenu_Utility_CompareBlock_End:
	ld	xiy, 15803228
	ld	xix, 15803239
	call	15789014
	call	15791819
	ret
SeMenu_Utility_SearchByte:
	ld (0x03efa8:24), 0x00
	cp (0x06ae:16), 0x01
	jr z, SeMenu_Utility_SearchByte_End
	ld XIX,0x00f12317
	jr t, SeMenu_Utility_FormatNumber
SeMenu_Utility_SearchByte_End:
	ld	xix, 15803012
SeMenu_Utility_FormatNumber:
	ld	xiy, 15802974
	call	15789014
	ret
SeMenu_Utility_FormatNumber_Loop:
	ld	(257960:24), 0
	ld	xiy, 15803159
	ld	xix, 15803164
	call	15789014
	ret
SeMenu_Utility_FormatNumber_End:
	ld a, (0x8c9a:16)
	ld (0x0678:16), a
	ld (0x03efa8:24), 0x02
	ld XIY,0x00f1233a
	cp (0x06ae:16), 0x01
	jr z, SeMenu_Utility_FormatNumber_Data
	ld XIX,0x00f1235c
	jr t, SeMenu_Utility_FormatSigned
SeMenu_Utility_FormatNumber_Data:
	ld	xix, 15803218
SeMenu_Utility_FormatSigned:
	call	15789014
	ld	(257960:24), 0
	ld	xiy, 15805705
	call	15789040
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
	ld	xiy, 15815607
	jr	5
	ld	xiy, 15815576
	ld	xix, 15815863
	call	15789014
	xor	xwa, xwa
	ld	a, (1648:16)
	sla	wa, 3
	ld	xiz, 15816666
	add	xiz, xwa
	ld	xiy, (xiz)
	ld	xix, (xiz+4)
	call	15789014
	ld	xiy, 15815336
	xor	xbc, xbc
	ld	xiz, 15817383
	ld	c, (1648:16)
	sla	bc, 2
	ld_rrl	xix, xiz, bc
	call	15789014
	ld	a, (1648:16)
	cp	a, 10
	jr	nz, 7
	ld	xiy, 15815546
	jr	5
	ld	xiy, 15815516
	ld	xix, 15815576
	call	15789014
	ld	xiy, 15816762
	ld	a, (1648:16)
	cp	a, 10
	jr	nz, 7
	ld	xix, 15816818
	jr	5
	ld	xix, 15816829
	call	15789027
	xor	xwa, xwa
	ld	a, (1648:16)
	sla	wa, 3
	ld	xiz, 15816829
	add	xiz, xwa
	ld	xiy, (xiz)
	ld	xix, (xiz+4)
	call	15789027
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
	cps	a, 0
	jr z, SeMenu_NameEdit_SetupPath
	cp a, 0x0a
	jr nz, SeMenu_NameEdit_DefaultPath
	call SeMenu_NameEdit_CheckBit7
	jr t, SeMenu_NameEdit_Return
SeMenu_NameEdit_SetupPath:
	ld	(257960:24), 1
	ld	xiy, 15820149
	ld	xix, 15820159
	call	15789014
	ldb	a, 0
SeMenu_NameEdit_DefaultPath:
	ld	(0x03efa8:24), 0
	ld xiy, EffectParam_Edit_Table
	call SeMenu_EqEdit_DrawInit_0x15
SeMenu_NameEdit_Return:
	ret
SeMenu_NameEdit_CheckBit7:
	ld	(257960:24), 0
	ld	a, (1642:16)
	and	a, 128
	jr	nz, 7
	ld	xiy, 15819996
	jr	5
SeMenu_NameEdit_Bit7Set:
	ld	xiy, 15819981
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
	cps	a, 0
	jr	z, 42
	cps	a, 1
	jr	z, 62
	cp	a, 14
	jr	c, 63
	ld	xiy, 15805139
	extz	xwa
	xor	w, w
	sla	wa, 2
	add	xiy, xwa
	ld	xiz, xiy
	ld	xiy, (xiz)
	ld	xix, (xiz+4)
	ld	(257960:24), 0
	call	15789027
	jr	45
SeMenu_PatchEdit_SetupPath:
	ld	(257960:24), 1
	ld	xiy, 15805215
	ld	xix, 15805225
	call	15789014
	ldb	a, 0
	jr	6
SeMenu_PatchEdit_CallHelper:
	call SeMenu_PresetManager_Data_0xEA
	jr t, SeMenu_PatchEdit_Return
SeMenu_PatchEdit_DefaultPath:
	ld	xiy, 15805139
	ld	(257960:24), 0
	call	15797181
SeMenu_PatchEdit_Return:
	ret


SeMenu_BankEdit_Dispatch:
	; --- Dispatcher: A==0 path with XIY/XIX setup + loop subroutine (187 bytes) ---
	cps	a, 0
	jr z, SeMenu_BankEdit_SetupPath
	call SeMenu_BankEdit_LoopHelper
	jr t, SeMenu_BankEdit_Return
SeMenu_BankEdit_SetupPath:
	ld	(257960:24), 1
	ld	xiy, 15805655
	ld	xix, 15805665
	call	15789014
	ld	xiy, 15805265
	call	15789040
SeMenu_BankEdit_Return:
	ret
SeMenu_BankEdit_LoopHelper:
	ld	(257960:24), 0
	ld	xiy, 15805466
	ld	xix, 15805474
	call	15789014
	ld	xiy, 15805276
	ld	xix, 15805316
	call	15789027
	ldb	c, 0
	ld	xiz, 1636
SeMenu_BankEdit_LoopBody:
	.byte 0xcb, 0x04, 0x3e, 0x86, 0x3f, 0x00, 0x66, 0x35
	.byte 0x45, 0x81, 0x2c, 0xf1, 0x00, 0xe9, 0x12, 0xca
	.byte 0xd2, 0xd9, 0xec, 0x02, 0xe9, 0x85, 0xa5, 0x25
	.byte 0xed, 0x8c, 0xec, 0xc8, 0x32, 0x00, 0x00, 0x00
	.byte 0x39, 0x1d, 0xe3, 0xeb, 0xf0, 0x59, 0x45, 0x99
	.byte 0x2c, 0xf1, 0x00, 0xe9, 0x85, 0xa5, 0x25, 0xed
	.byte 0x8c, 0xec, 0xc8, 0x05, 0x00, 0x00, 0x00, 0x1d
	.byte 0xd6, 0xeb, 0xf0, 0x68, 0x1c
SeMenu_BankEdit_EmptyEntry:
	ld	xiy, 15805581
	extz	xbc
	xor	b, b
	sla	bc, 2
	add	xiy, xbc
	ld	xiy, (xiy)
	ld	xix, xiy
	add	xix, 20
	call	15789014
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
	ld	(0x03efa8:24), 0
	ld	xiy, TuningSys_Param_01_0xAE
	ld	xix, TuningSys_Param_01_0xC4
	call	SeMenu_NameEditor_Draw
	jr	61
	ld	(0x03efa8:24), 1
	ld	xiy, TuningSys_Param_01_0x24A
	ld	xix, TuningSys_Param_01_0x254
	call	SeMenu_NameEditor_Setup
	ldb	a, 0
	jr	22
	ld	(0x03efa8:24), 1
	ld	xiy, TuningSys_Param_01_0x254
	ld	xix, TuningSys_Param_01_0x25E
	call	SeMenu_NameEditor_Setup
	ldb	a, 13
	ld	(0x03efa8:24), 0
	ld	xiy, TuningSys_Param_01_0x25E
	call	SeMenu_EqEdit_DrawInit_0x15
	ret
Data_UnknownBlock:
	.byte 0xc9, 0xd8, 0x66, 0x0e, 0xc9, 0xdb, 0x66, 0x24
	.byte 0xc9, 0xdc, 0x66, 0x36, 0xc9, 0xdd, 0x6f, 0x48
	.byte 0x68, 0x4c, 0xf2, 0xa8, 0xef, 0x03, 0x00, 0x01
	.byte 0x45, 0x40, 0x35, 0xf1, 0x00, 0x44, 0x4a, 0x35
	.byte 0xf1, 0x00, 0x1d, 0xd6, 0xeb, 0xf0, 0x1d, 0x40
	.byte 0x03, 0xf1, 0x68, 0x41, 0xf2, 0xa8, 0xef, 0x03
	.byte 0x00, 0x00, 0x45, 0x86, 0x34, 0xf1, 0x00, 0x44
	.byte 0x9f, 0x34, 0xf1, 0x00, 0x1d, 0xe3, 0xeb, 0xf0
	.byte 0x68, 0x2b, 0xf2, 0xa8, 0xef, 0x03, 0x00, 0x00
	.byte 0x45, 0x59, 0x34, 0xf1, 0x00, 0x44, 0x72, 0x34
	.byte 0xf1, 0x00, 0x1d, 0xe3, 0xeb, 0xf0, 0x68, 0x15
	.byte 0x1d, 0x04, 0xfa, 0xf0, 0x68, 0x0f, 0xf2, 0xa8
	.byte 0xef, 0x03, 0x00, 0x00, 0x45, 0xe8, 0x34, 0xf1
	.byte 0x00, 0x1d, 0xbd, 0x0b, 0xf1, 0x0e
	ld (0x03efa8:24), 0x00
	ld XIY,TuningSystem_Handler_Table_0x173
	ld XIX,TuningSystem_Handler_Table_0x17D
	call SeMenu_NameEditor_Setup
	ld c, (0x0660:16)
	xor B,B
	sla BC, 0x02
	ld XIZ,TuningSystem_Handler_Table_0x1E1
	ldl_dri xiy, 0x07, 0xf8, 0xe4
	ld XIX,XIY
	add XIX,0x00000014
	call SeMenu_NameEditor_Setup
	ret
	.byte 0xc1, 0xae, 0x06, 0x3f, 0x01, 0x6e, 0x06, 0xc9
	.byte 0xdb, 0x67, 0x0f, 0x68, 0x05, 0xc9, 0xcf, 0x09
	.byte 0x67, 0x08, 0x14, 0x1d, 0x68, 0xf3, 0xf0, 0x15
	.byte 0x68, 0x37, 0xc9, 0xd8, 0x6e, 0x33, 0x1d, 0x68
	.byte 0xf3, 0xf0, 0xc1, 0xae, 0x06, 0x3f, 0x01, 0x66
	.byte 0x12, 0xf2, 0xa8, 0xef, 0x03, 0x00, 0x01, 0x45
	.byte 0x2a, 0x30, 0xf1, 0x00, 0x44, 0x34, 0x30, 0xf1
	.byte 0x00, 0x68, 0x10, 0xf2, 0xa8, 0xef, 0x03, 0x00
	.byte 0x01, 0x45, 0xcb, 0x63, 0xf1, 0x00, 0x44, 0xd5
	.byte 0x63, 0xf1, 0x00, 0x1d, 0xd6, 0xeb, 0xf0, 0x21
	.byte 0x00, 0xf2, 0xa8, 0xef, 0x03, 0x00, 0x00, 0xc1
	.byte 0xae, 0x06, 0x3f, 0x01, 0x66, 0x07, 0x45, 0xf6
	.byte 0x2f, 0xf1, 0x00, 0x68, 0x05, 0x45, 0xb7, 0x63
	.byte 0xf1, 0x00, 0x1d, 0xbd, 0x0b, 0xf1, 0x0e, 0xf2
	.byte 0xa8, 0xef, 0x03, 0x00, 0x00, 0x45, 0x94, 0x30
	.byte 0xf1, 0x00, 0x1d, 0xbd, 0x0b, 0xf1, 0x0e, 0xc1
	.byte 0xae, 0x06, 0x3f, 0x01, 0x66, 0x07, 0x45, 0xea
	.byte 0x30, 0xf1, 0x00, 0x68, 0x1e, 0xc9, 0xd8, 0x6e
	.byte 0x15, 0xf2, 0xa8, 0xef, 0x03, 0x00, 0x00, 0x45
	.byte 0x2f, 0x64, 0xf1, 0x00, 0x1d, 0xbd, 0x0b, 0xf1
	.byte 0x1d, 0xb7, 0xfc, 0xf0, 0x68, 0x0f, 0x45, 0x2f
	.byte 0x64, 0xf1, 0x00, 0xf2, 0xa8, 0xef, 0x03, 0x00
	.byte 0x00, 0x1d, 0xbd, 0x0b, 0xf1, 0x0e, 0xf2, 0xa8
	.byte 0xef, 0x03, 0x00, 0x00, 0x45, 0x93, 0x31, 0xf1
	.byte 0x00, 0x1d, 0xbd, 0x0b, 0xf1, 0x0e, 0xc9, 0xdd
	.byte 0x6e, 0x16, 0xf2, 0xa8, 0xef, 0x03, 0x00, 0x00
	.byte 0x45, 0x7e, 0x2d, 0xf1, 0x00, 0x44, 0x9c, 0x2d
	.byte 0xf1, 0x00, 0x1d, 0xe3, 0xeb, 0xf0, 0x68, 0x0f
	.byte 0xf2, 0xa8, 0xef, 0x03, 0x00, 0x00, 0x45, 0x9c
	.byte 0x2d, 0xf1, 0x00, 0x1d, 0xbd, 0x0b, 0xf1, 0x0e
	.byte 0xc9, 0xdd, 0x6e, 0x16, 0xf2, 0xa8, 0xef, 0x03
	.byte 0x00, 0x00, 0x45, 0x7e, 0x2d, 0xf1, 0x00, 0x44
	.byte 0x9c, 0x2d, 0xf1, 0x00, 0x1d, 0xe3, 0xeb, 0xf0
	.byte 0x68, 0x0f, 0xf2, 0xa8, 0xef, 0x03, 0x00, 0x00
	.byte 0x45, 0x9c, 0x2d, 0xf1, 0x00, 0x1d, 0xbd, 0x0b
	.byte 0xf1, 0x0e, 0xf2, 0xa8, 0xef, 0x03, 0x00, 0x00
	.byte 0x45, 0x2b, 0x2e, 0xf1, 0x00, 0x1d, 0xbd, 0x0b
	.byte 0xf1, 0x0e, 0xf2, 0xa8, 0xef, 0x03, 0x00, 0x00
	.byte 0x45, 0x2b, 0x2e, 0xf1, 0x00, 0x1d, 0xbd, 0x0b
	.byte 0xf1, 0x0e, 0xf2, 0xa8, 0xef, 0x03, 0x00, 0x00
	.byte 0x45, 0x8c, 0x2e, 0xf1, 0x00, 0x1d, 0xbd, 0x0b
	.byte 0xf1, 0x0e, 0xc9, 0xd8, 0x6e, 0x16, 0xf2, 0xa8
	.byte 0xef, 0x03, 0x00, 0x01, 0x45, 0x2b, 0x2f, 0xf1
	.byte 0x00, 0x44, 0x3f, 0x2f, 0xf1, 0x00, 0x1d, 0xd6
	.byte 0xeb, 0xf0, 0x21, 0x00, 0xf2, 0xa8, 0xef, 0x03
	.byte 0x00, 0x00, 0x45, 0x3f, 0x2f, 0xf1, 0x00, 0x1d
	.byte 0xbd, 0x0b, 0xf1, 0x0e, 0xf2, 0xa8, 0xef, 0x03
	.byte 0x00, 0x00, 0x45, 0xee, 0x36, 0xf1, 0x00, 0x44
	.byte 0xe6, 0x37, 0xf1, 0x00, 0x1d, 0xd6, 0xeb, 0xf0
	.byte 0x45, 0xe6, 0x37, 0xf1, 0x00, 0x44, 0x0e, 0x38
	.byte 0xf1, 0x00, 0x1d, 0xe3, 0xeb, 0xf0, 0x1d, 0x0f
	.byte 0x05, 0xf1, 0x0e, 0xc1, 0x60, 0x06, 0x27, 0xcf
	.byte 0xd9, 0x66, 0x04, 0x27, 0x11, 0x68, 0x02, 0x27
	.byte 0x10, 0xf1, 0x4e, 0x90, 0x47, 0xc1, 0x61, 0x06
	.byte 0x26, 0xce, 0x69, 0xf1, 0x4f, 0x90, 0x46, 0xc1
	.byte 0x9e, 0x8c, 0x21, 0xf1, 0x50, 0x90, 0x41, 0x40
	.byte 0x4e, 0x90, 0x00, 0x00, 0x1d, 0x92, 0xe0, 0xfe
	.byte 0xc1, 0x51, 0x90, 0x21, 0xc1, 0x52, 0x90, 0x23
	.byte 0x42, 0x13, 0x0c, 0x02, 0x00, 0x1d, 0x7b, 0xde
	.byte 0xfe, 0x23, 0x14, 0xdb, 0xd3, 0x34, 0x01, 0x17
	.byte 0x45, 0x13, 0x0c, 0x02, 0x00, 0x38, 0x39, 0xcc
	.byte 0x04, 0xed, 0x88, 0xed, 0x89, 0x24, 0x00, 0xcc
	.byte 0xcf, 0x10, 0x66, 0x1d, 0x38, 0x39, 0xcc, 0x04
	.byte 0x1d, 0x34, 0x24, 0xfb, 0xcc, 0x05, 0x59, 0x58
	.byte 0xe8, 0xc8, 0x01, 0x00, 0x00, 0x00, 0xe9, 0xc8
	.byte 0x01, 0x00, 0x00, 0x00, 0xcc, 0xc8, 0x01, 0x68
	.byte 0xde, 0xcc, 0x05, 0x59, 0x58, 0xbd, 0xfd, 0x43
	.byte 0xbd, 0xfe, 0x54, 0xed, 0xca, 0x04, 0x00, 0x00
	.byte 0x00, 0x1d, 0x5a, 0xec, 0xf0, 0x0e, 0xf2, 0xa8
	.byte 0xef, 0x03, 0x00, 0x00, 0xc1, 0xae, 0x06, 0x3f
	.byte 0x01, 0x66, 0x0e, 0x45, 0x11, 0x38, 0xf1, 0x00
	.byte 0x44, 0x33, 0x38, 0xf1, 0x00, 0x1d, 0xd6, 0xeb
	.byte 0xf0, 0xf2, 0xa8, 0xef, 0x03, 0x00, 0x00, 0x45
	.byte 0x33, 0x38, 0xf1, 0x00, 0x44, 0x16, 0x3a, 0xf1
	.byte 0x00, 0x1d, 0xd6, 0xeb, 0xf0, 0x68, 0x0e, 0x45
	.byte 0x5f, 0x38, 0xf1, 0x00, 0x44, 0x16, 0x3a, 0xf1
	.byte 0x00, 0x1d, 0xd6, 0xeb, 0xf0, 0xc1, 0x62, 0x06
	.byte 0x3f, 0x10, 0x66, 0x29, 0xc1, 0x62, 0x06, 0x3f
	.byte 0x02, 0x66, 0x44, 0x45, 0x20, 0x3a, 0xf1, 0x00
	.byte 0x44, 0x2a, 0x3a, 0xf1, 0x00, 0x1d, 0xd6, 0xeb
	.byte 0xf0, 0x45, 0x50, 0x3a, 0xf1, 0x00, 0x44, 0x6c
	.byte 0x3a, 0xf1, 0x00, 0x1d, 0xe3, 0xeb, 0xf0, 0x1d
	.byte 0x3d, 0x07, 0xf1, 0x68, 0x42, 0x45, 0x16, 0x3a
	.byte 0xf1, 0x00, 0x44, 0x20, 0x3a, 0xf1, 0x00, 0x1d
	.byte 0xd6, 0xeb, 0xf0, 0x45, 0x34, 0x3a, 0xf1, 0x00
	.byte 0x44, 0x50, 0x3a, 0xf1, 0x00, 0x1d, 0xe3, 0xeb
	.byte 0xf0, 0x1d, 0x3d, 0x07, 0xf1, 0x68, 0x20, 0x45
	.byte 0x2a, 0x3a, 0xf1, 0x00, 0x44, 0x34, 0x3a, 0xf1
	.byte 0x00, 0x1d, 0xd6, 0xeb, 0xf0, 0x45, 0x6c, 0x3a
	.byte 0xf1, 0x00, 0x44, 0x88, 0x3a, 0xf1, 0x00, 0x1d
	.byte 0xe3, 0xeb, 0xf0, 0x1d, 0x3d, 0x07, 0xf1, 0x0e
	.byte 0x45, 0xe6, 0x37, 0xf1, 0x00, 0x44, 0x0e, 0x38
	.byte 0xf1, 0x00, 0x1d, 0xe3, 0xeb, 0xf0, 0x1d, 0x0f
	.byte 0x05, 0xf1, 0x0e, 0xc9, 0xd8, 0x66, 0x5c, 0xc9
	.byte 0xd9, 0x66, 0x04, 0xc9, 0xda, 0x66, 0x77, 0xf2
	.byte 0xa8, 0xef, 0x03, 0x00, 0x01, 0x45, 0x92, 0x3a
	.byte 0xf1, 0x00, 0x44, 0x9c, 0x3a, 0xf1, 0x00, 0x1d
	.byte 0xd6, 0xeb, 0xf0, 0xf2, 0xa8, 0xef, 0x03, 0x00
	.byte 0x00, 0xc1, 0x62, 0x06, 0x3f, 0x0d, 0x66, 0x13
	.byte 0xc1, 0x62, 0x06, 0x3f, 0x02, 0x66, 0x18, 0x45
	.byte 0x34, 0x3a, 0xf1, 0x00, 0x44, 0x50, 0x3a, 0xf1
	.byte 0x00, 0x68, 0x16, 0x45, 0x50, 0x3a, 0xf1, 0x00
	.byte 0x44, 0x6c, 0x3a, 0xf1, 0x00, 0x68, 0x0a, 0x45
	.byte 0x6c, 0x3a, 0xf1, 0x00, 0x44, 0x88, 0x3a, 0xf1
	.byte 0x00, 0x1d, 0xe3, 0xeb, 0xf0, 0x1d, 0x3d, 0x07
	.byte 0xf1, 0x68, 0x7d, 0xf2, 0xa8, 0xef, 0x03, 0x00
	.byte 0x01, 0x45, 0x88, 0x3a, 0xf1, 0x00, 0x44, 0x9c
	.byte 0x3a, 0xf1, 0x00, 0x1d, 0xd6, 0xeb, 0xf0, 0x45
	.byte 0x45, 0x3a, 0xf1, 0x00, 0x1d, 0xf0, 0xeb, 0xf0
	.byte 0x1d, 0x3d, 0x07, 0xf1, 0x68, 0x5a, 0xf2, 0xa8
	.byte 0xef, 0x03, 0x00, 0x01, 0x45, 0x88, 0x3a, 0xf1
	.byte 0x00, 0x44, 0x9c, 0x3a, 0xf1, 0x00, 0x1d, 0xd6
	.byte 0xeb, 0xf0, 0xf2, 0xa8, 0xef, 0x03, 0x00, 0x00
	.byte 0xc1, 0x62, 0x06, 0x3f, 0x0d, 0x66, 0x17, 0xc1
	.byte 0x62, 0x06, 0x3f, 0x02, 0x66, 0x20, 0x45, 0x34
	.byte 0x3a, 0xf1, 0x00, 0x44, 0x50, 0x3a, 0xf1, 0x00
	.byte 0x1d, 0xe3, 0xeb, 0xf0, 0x68, 0x1e, 0x45, 0x50
	.byte 0x3a, 0xf1, 0x00, 0x44, 0x6c, 0x3a, 0xf1, 0x00
	.byte 0x1d, 0xe3, 0xeb, 0xf0, 0x68, 0x0e, 0x45, 0x6c
	.byte 0x3a, 0xf1, 0x00, 0x44, 0x88, 0x3a, 0xf1, 0x00
	.byte 0x1d, 0xe3, 0xeb, 0xf0, 0x1d, 0x3d, 0x07, 0xf1
	.byte 0x0e, 0xd8, 0xd0, 0xc1, 0x61, 0x06, 0x21, 0xc9
	.byte 0x0a, 0x10, 0x46, 0x1c, 0x3b, 0xf1, 0x00, 0xdb
	.byte 0xd3, 0xc8, 0x8f, 0xdb, 0xec, 0x01, 0xd3, 0x07
	.byte 0xf8, 0xec, 0x24, 0xf1, 0xcc, 0x06, 0x54, 0xdc
	.byte 0xc8, 0x08, 0x00, 0xf1, 0xd0, 0x06, 0x54, 0x46
	.byte 0x3c, 0x3b, 0xf1, 0x00, 0xdb, 0xd3, 0xc9, 0x8f
	.byte 0xdb, 0xec, 0x01, 0xd3, 0x07, 0xf8, 0xec, 0x24
	.byte 0xf1, 0xce, 0x06, 0x54, 0xdc, 0xc8, 0x0e, 0x00
	.byte 0xf1, 0xd2, 0x06, 0x54, 0x1d, 0x3f, 0xec, 0xf0
	.byte 0x0e
SeMenu_PresetInit_Main:
	call	15792330
	call	15791819
	ld	xiy, 15810376
	ld	xix, 15810757
	call	15789014
	call	15790112
	call	15791995
	ld	(257960:24), 0
	ld	xiy, 15811773
	ld	xix, 15811954
	call	15789027
	call	15796164
	call	15796215
	call	15792351
	ret
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
	xor	xbc, xbc
	xor	w, w
	extz	xwa
	ld	xbc, 1632
	add	xbc, xwa
	ld	d, (xbc)
	and	d, 128
	jr	z, 15
	ld	xiy, 15812118
	ld	(257960:24), 0
	call	15797181
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
	xor	xbc, xbc
	xor	w, w
	extz	xwa
	ld	xbc, 1632
	add	xbc, xwa
	ld	d, (xbc)
	cps	d, 0
	jr	z, 15
	ld	xiy, 15811994
	ld	(257960:24), 0
	call	15797181
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
	cps a, 0
	jr z, 61
	cps	a, 1
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
	ldb	a, 0
	ld	xiy, TuningSystem_Handler_Table_0x117D
	ld	(0x03efa8:24), 0
	call	SeMenu_EqEdit_DrawInit_0x15
	ret
SeMenu_FilterEdit_AltDispatch:
	cps	a, 0
	jr	nz, 22
	ld	(0x03efa8:24), 1
	ld	xiy, TuningSystem_Handler_Table_0x12CA
	ld	xix, TuningSystem_Handler_Table_0x12D4
	call	SeMenu_NameEditor_Setup
	ldb	a, 0
	ld	(0x03efa8:24), 0
	ld	xiy, TuningSystem_Handler_Table_0x12B6
	call	SeMenu_EqEdit_DrawInit_0x15
	ret
SeMenu_FilterEdit_DataBlock3:
	cps	a, 0
	jr	nz, 22
	ld	(0x03efa8:24), 1
	ld	xiy, TuningSystem_Handler_Table_0x12CA
	ld	xix, TuningSystem_Handler_Table_0x12D4
	call	SeMenu_NameEditor_Setup
	ldb	a, 0
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
	call	15797019
	call	15791819
	ld	(257960:24), 0
	ld	xiy, 15812882
	ld	xix, 15813039
	call	15789014
	ld	(257960:24), 0
	ld	xiy, 15814142
	ld	xix, 15814172
	call	15789027
	call	15797040
	ret
SeMenu_EqEdit_SetupHelper1:
	ld	(257960:24), 0
	ld	xiy, 15812575
	ld	xix, 15812622
	call	15789014
	ret
SeMenu_EqEdit_SetupHelper2:
	ld	(257960:24), 0
	ld	xiy, 15812622
	ld	xix, 15812627
	call	15789014
	ret
SeMenu_EqEdit_Dispatch:
	.byte 0xc9, 0xd8, 0x66, 0x35, 0xc9, 0xcf, 0x0b, 0x66
	.byte 0x48, 0xc9, 0xcf, 0x0c, 0x6e, 0x45, 0xf2, 0xa8
	.byte 0xef, 0x03, 0x00, 0x00, 0xc1, 0xae, 0x06, 0x3f
	.byte 0x01, 0x66, 0x0e, 0x45, 0xaf, 0x49, 0xf1, 0x00
	.byte 0x44, 0xcd, 0x49, 0xf1, 0x00, 0x1d, 0xe3, 0xeb
	.byte 0xf0
SeMenu_EqEdit_DrawTable:
	ld	xiy, 15813139
	ld	xix, 15813169
	call	15789027
	jr	41
SeMenu_EqEdit_SetupPath:
	ld	(257960:24), 1
	ld	xiy, 15814056
	ld	xix, 15814086
	call	15789014
	ldb	a, 0
	jr	2
SeMenu_EqEdit_SetConstA:
	ldb a, 0x07
SeMenu_EqEdit_DefaultPath:
	ld	(257960:24), 0
	ld	xiy, 15813180
	call	15797181
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
	ldio	16, 40
	rcf
	ldio	16, 8
	rcf
	pushw	wa
	push_a
	nop
	nop
	.ascii "*U T*"
	normal
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
	max
	ldio	16, 42
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
	ldb	b, 1
	ldwio	4, 0x4102
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
	ldwio	20, 5130
	ldb	b, 85
	pushw	de
	max
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
	.incbin "includes/romslices/v7_block_sebitmap_envcurve5.bin"
SeMenu_CompareScreen_DataTable:
	.incbin "includes/romslices/v7_block_semenu_comparescreen_datatable.bin"
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
	.incbin "includes/romslices/v7_fix_tuningsystem_handler_table_tail.bin"
	.include "storage/flash_floppy_handlers.s"

S2cShowHideFunc:
	cp	xbc, 29360140
	jr	z, 33
	cp	xbc, 29360139
	jr	z, 25
	cp	xbc, 29360130
	jr	z, 17
	cp	xbc, 29360129
	jr	nz, 9
	or	xde, xde
	jr	nz, 5
	ld	(14811:16), 3
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
	lda xix, (S2c_GridCheck_DataBlock:24)
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
	lda xbc, (xsp + 0x0a)
	ld XWA,XDE
	srl XWA, 0x00
	ld QWA,0
	ld (XBC),WA
	lda xwa, (xbc + 0x02)
	ld (XWA),DE
	lda XDE, (XSP)
	ld (XBC+0x04),XDE
	cpw (XBC), 0x0001
	jr nz, S2c_GridCheck_GetFocusSendEvt
	ld WA,(XWA)
	dec 2,A
	extz WA
	sla WA, 0x02
	lda xbc, (StrTranspose_Minus25_0x12:24)
	ldl_dri xwa, 0x07, 0xe4, 0xe0
	ld A,(XWA)
	extz WA
	sla WA, 0x02
	lda xbc, (0x03dc4e:24)
	ldl_dri xwa, 0x07, 0xe4, 0xe0
	push XWA
	push XDE
	call 0xff0295
	inc 0,XSP
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
	lds32 xde, 0
	call MainFuncCall
	jrl PsCmpCpFGrpBox_ReturnZero

PsCmpCpFGrpBox_HandleEvt4:
	.byte 0xe3, 0xfd, 0x10, 0x01, 0x20, 0x1d, 0x59, 0x5e
	.byte 0xfa, 0xeb, 0x8e, 0xe3, 0xfd, 0x0c, 0x01, 0x20
	.byte 0x38, 0xbf, 0x10, 0x30, 0x38, 0x1d, 0x95, 0x02
	.byte 0xff, 0xef, 0x60, 0xbe, 0x16, 0x30, 0xbe, 0x20
	.byte 0x31, 0xc1, 0x0b, 0x39, 0x3f, 0x00, 0x6e, 0x11
	.byte 0xc1, 0xe4, 0x39, 0x3f, 0x00, 0x6e, 0x0a, 0xb1
	.byte 0x02, 0x00, 0x00, 0xb0, 0x02, 0xff, 0x00, 0x68
	.byte 0x08
PsCmpCpFGrpBox_SetColorFF:
	ldw (xbc), 0xff
	ldw (xwa), 0xf5
PsCmpCpFGrpBox_SendNotify:
	ld	xwa, (xsp+272)
	ld	xbc, 29360141
	lds32	xde, 0
	call	16421459
	lda	xde, (xsp+12)
	ld	xwa, (xsp+272)
	ld	xbc, 29360143
	call	16421459
	lda	xwa, (xsp+4)
	ldw	(xwa), 8
	lda	xde, (xwa+2)
	ldw	(xde), 60
	ld	bc, (xwa)
	add	bc, 140
	ld	(xwa+4), bc
	ld	bc, (xde)
	add	bc, 39
	ld	(xwa+6), bc
	cp	(14603:16), 0
	jr	nz, 9
	pushw 242
	lds	bc, 1
	lds	de, 2
	jr	7
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
	lds32 xde, 0
	call MainFuncCall
	jrl DesignFrame_Return

PsCmpCpFVariBox_HandleEvt5:
	.byte 0x1d, 0x5a, 0x54, 0xfa, 0xeb, 0xcf, 0xee, 0x00
	.byte 0xa0, 0x01, 0x76, 0xa9, 0x00, 0xe3, 0xfd, 0x10
	.byte 0x01, 0x20, 0x1d, 0x59, 0x5e, 0xfa, 0xeb, 0x8e
	.byte 0xe3, 0xfd, 0x0c, 0x01, 0x20, 0x38, 0xbf, 0x10
	.byte 0x30, 0x38, 0x1d, 0x95, 0x02, 0xff, 0xef, 0x60
	.byte 0xbe, 0x16, 0x30, 0xbe, 0x20, 0x31, 0xc1, 0x0b
	.byte 0x39, 0x3f, 0x01, 0x6e, 0x11, 0xc1, 0xe4, 0x39
	.byte 0x3f, 0x00, 0x6e, 0x0a, 0xb1, 0x02, 0x00, 0x00
	.byte 0xb0, 0x02, 0xff, 0x00, 0x68, 0x08
PsCmpCpFVariBox_SetColorFF:
	ldw (xbc), 0xff
	ldw (xwa), 0xf5
PsCmpCpFVariBox_SendNotify:
	ld	xwa, (xsp+272)
	ld	xbc, 29360141
	lds32	xde, 0
	call	16421459
	lda	xde, (xsp+12)
	ld	xwa, (xsp+272)
	ld	xbc, 29360143
	call	16421459
	call	16405594
	cp	xhl, 27263160
	jr	nz, 59
	lda	xwa, (xsp+4)
	ldw	(xwa), 8
	lda	xde, (xwa+2)
	ldw	(xde), 100
	ld	bc, (xwa)
	add	bc, 140
	ld	(xwa+4), bc
	ld	bc, (xde)
	add	bc, 39
	ld	(xwa+6), bc
	cp	(14603:16), 1
	jr	nz, 9
	pushw 242
	lds	bc, 1
	lds	de, 2
	jr	7
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
	ld	xwa, (xsp+268)
	call	16400380
	ld	xwa, (xsp+268)
	call	16408153
	ld	xiz, xhl
	ld	a, (13395:16)
	extz	wa
	sla	wa, 2
	lda	xbc, (14800796:24)
	ld_rrl	xwa, xbc, wa
	push	xwa
	lda	xwa, (xsp+16)
	push	xwa
	call	16712341
	inc	8, xsp
	lda	xwa, (xiz+22)
	lda	xbc, (xiz+32)
	cp	(14603:16), 2
	jr	nz, 17
	cp	(14820:16), 0
	jr	nz, 10
	ldw	(xbc), 0
	ldw	(xwa), 255
	jr	8
PsCmpCpFPtnBox_SetColorFF:
	ldw (xbc), 0xff
	ldw (xwa), 0xf5
PsCmpCpFPtnBox_SendNotify:
	ld	xwa, (xsp+268)
	ld	xbc, 29360141
	lds32	xde, 0
	call	16421459
	lda	xde, (xsp+12)
	ld	xwa, (xsp+268)
	ld	xbc, 29360143
	call	16421459
	lda	xwa, (xsp+4)
	ldw	(xwa), 8
	lda	xde, (xwa+2)
	ldw	(xde), 140
	ld	bc, (xwa)
	add	bc, 140
	ld	(xwa+4), bc
	ld	bc, (xde)
	add	bc, 38
	ld	(xwa+6), bc
	cp	(14603:16), 2
	jr	nz, 9
	pushw 242
	lds	bc, 1
	lds	de, 2
	jr	7
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
	.byte 0xee, 0x88, 0x1d, 0xfc, 0x3f, 0xfa, 0xee, 0x88
	.byte 0x1d, 0x59, 0x5e, 0xfa, 0x8b, 0x24, 0x3f, 0x00
	.byte 0x6e, 0x06, 0xc1, 0x1a, 0x39, 0x21, 0x68, 0x04
PsCstmCpBnkBox_ReadParam2:
	ld	a, (14619:16)
PsCstmCpBnkBox_LookupAndSend:
	extz	wa
	sla	wa, 2
	lda	xbc, (14801336:24)
	ld_rrl	xwa, xbc, wa
	push	xwa
	lda	xwa, (xsp+8)
	push	xwa
	call	16712341
	inc	8, xsp
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16421459
PsCstmCpBnkBox_ReturnZero:
	lds32 xhl, 0

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
	.byte 0xee, 0x88, 0x1d, 0xfc, 0x3f, 0xfa, 0xee, 0x88
	.byte 0x1d, 0x59, 0x5e, 0xfa, 0xbf, 0x04, 0x31, 0x8b
	.byte 0x24, 0x3f, 0x00, 0x6e, 0x15, 0x40, 0x64, 0xdb
	.byte 0xe1, 0x00, 0xc1, 0x1a, 0x39, 0x3f, 0x0a, 0x6f
	.byte 0x05, 0x40, 0x5c, 0xdb, 0xe1, 0x00
PsCstmCpSwBox_PushTableAddr0:
	push xwa
	push xbc
	jr PsCstmCpSwBox_SendCommand

PsCstmCpSwBox_ReadParam2:
	ld	xwa, 14801780
	cp	(14619:16), 10
	jr	nc, 5
	ld	xwa, 14801772
PsCstmCpSwBox_PushTableAddr1:
	push xwa
	push xbc

PsCstmCpSwBox_SendCommand:
	call	16712341
	inc	8, xsp
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16421459
PsCstmCpSwBox_ReturnZero:
	lds32 xhl, 0

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
	.byte 0xc1, 0xe2, 0x39, 0x3f, 0x00, 0x7e, 0x90, 0x00
	.byte 0xee, 0x88, 0xe3, 0xfd, 0x04, 0x01, 0x22, 0x1d
	.byte 0xfc, 0x3f, 0xfa, 0xee, 0x88, 0x1d, 0x59, 0x5e
	.byte 0xfa, 0x8b, 0x24, 0x21, 0xc9, 0xd9, 0x66, 0x12
	.byte 0xc9, 0xd8, 0x6e, 0x74, 0x40, 0x1a, 0x00, 0x44
	.byte 0x01, 0x41, 0x2b, 0x00, 0xe4, 0x01, 0xea, 0xa8
	.byte 0x68, 0x0c
PsCstmCpNameBox_FuncCall2C:
	ld xwa, 0x144001a
	ld xbc, 0x1e4002c
	lds32 xde, 0

PsCstmCpNameBox_MainFuncCall:
	call MainFuncCall
	jr PsCtmAtt_ReturnZero

PsCstmCpNameBox_HandleEvt2D:
	cp (0x39e2:16), 0x00
	jr nz, PsCtmAtt_ReturnZero
	ld XWA,XIZ
	call GetViewInstance
	ld XWA,(XSP+0x0104)
	push XWA
	lda xwa, (xsp + 0x08)
	push XWA
	call Free_Compare2
	inc 0,XSP
	lda xde, (xsp + 0x04)
	ld XWA,XIZ
	ld XBC,0x01c0000f
	jr t, PsCstmCpNameBox_SendEventJoin
PsCstmCpNameBox_HandleEvt2E:
	cp (0x39e2:16), 0x00
	jr nz, PsCtmAtt_ReturnZero
	ld XWA,XIZ
	call GetViewInstance
	ld XWA,(XSP+0x0104)
	push XWA
	lda xwa, (xsp + 0x08)
	push XWA
	call Free_Compare2
	inc 0,XSP
	lda xde, (xsp + 0x04)
	ld XWA,XIZ
	ld XBC,0x01c0000f
PsCstmCpNameBox_SendEventJoin:
	call SendEvent

PsCtmAtt_ReturnZero:
	lds32 xhl, 0

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
	ld	xwa, xiz
	call	16400380
	pushw	0
	pushw	14771
	lda	xwa, (xsp+8)
	push	xwa
	call	16712341
	inc	8, xsp
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16421459
PsCtmAttStrBox_ReturnZero:
	lds32 xhl, 0

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
	ld	xwa, (xsp+268)
	call	16400380
	ld	xwa, (xsp+268)
	call	16408153
	ld	xiz, xhl
	ld	a, (13370:16)
	extz	wa
	sla	wa, 2
	lda	xbc, (14801788:24)
	ld_rrl	xwa, xbc, wa
	push	xwa
	lda	xwa, (xsp+16)
	push	xwa
	call	16712341
	inc	8, xsp
	lda	xwa, (xiz+22)
	lda	xbc, (xiz+32)
	cp	(14604:16), 1
	jr	nz, 17
	cp	(14820:16), 1
	jr	nz, 10
	ldw	(xbc), 0
	ldw	(xwa), 255
	jr	8
AcMemNoBox_SetColorFF:
	ldw (xbc), 0xff
	ldw (xwa), 0xf5
AcMemNoBox_SendNotify:
	ld	xwa, (xsp+268)
	ld	xbc, 29360141
	lds32	xde, 0
	call	16421459
	lda	xde, (xsp+12)
	ld	xwa, (xsp+268)
	ld	xbc, 29360143
	call	16421459
	call	16405594
	cp	xhl, 27263160
	jr	nz, 59
	lda	xwa, (xsp+4)
	ldw	(xwa), 197
	lda	xde, (xwa+2)
	ldw	(xde), 100
	ld	bc, (xwa)
	add	bc, 88
	ld	(xwa+4), bc
	ld	bc, (xde)
	add	bc, 46
	ld	(xwa+6), bc
	cp	(14604:16), 1
	jr	nz, 9
	pushw 242
	lds	bc, 1
	lds	de, 2
	jr	7
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
	ld	xwa, (xsp+280)
	call	GetViewInstance
	ld	xiz, xhl
	ld	(xsp+4), xiz
	ld	xwa, (xsp+280)
	call	GetViewInstance
	ld	(xsp+12), xhl
	ld	xwa, (xsp+12)
	ld	(xsp+8), xwa
	ld	e, (xiz+36)
	ld	a, (14079:16)
	and	a, e
	lda	xhl, (14802184:24)
	lda	xbc, (xsp+16)
	cp	a, e
	jr	nz, 21	; -> 0xF1BB71
	ld	xwa, (xhl+4)
	push	xwa
	push	xbc
	call	16712341
	inc	8, xsp
	ld	xwa, (xsp+12)
	ldw	(xwa+22), 242
	jr	36	; -> 0xF1BB95
AcCmpRecBox_CheckParam2:
	ld	xwa, (xsp+4)
	ld	e, (xwa+37)
	ld	a, (13397:16)
	and	a, e
	cp	a, e
	jr	nz, 2
	inc	8, xhl
AcCmpRecBox_AdjustTable:
	ld xwa, (xhl)

	push xwa

	push xbc

	call	16712341

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
	lds32 xhl, 0

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
	ld	xwa, xiz
	call	16400380
	ld	xwa, xiz
	call	16408153
	ld	a, (13375:16)
	extz	wa
	sla	wa, 2
	lda	xbc, (14802214:24)
	ld_rrl	xwa, xbc, wa
	push	xwa
	lda	xwa, (xsp+8)
	push	xwa
	call	16712341
	inc	8, xsp
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16421459
PsCmpQtzBox_ReturnZero:
	lds32 xhl, 0

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
	call	16405594
	cp	xhl, 27263157
	jr	nz, 68
	ld	xwa, (xsp+264)
	ld	xbc, xiz
	ld	xde, (xsp+260)
	call	16400380
	ld	xwa, (xsp+264)
	call	16408153
	ld	a, (13376:16)
	inc	1, a
	extz	wa
	pushw	wa
	pushw	225
	pushw	56698
	lda	xwa, (xsp+10)
	push	xwa
	call	16712341
	lda	xsp, (xsp+10)
	lda	xde, (xsp+4)
	ld	xwa, (xsp+264)
	ld	xbc, 29360143
	call	16421459
PsCmpMeasBox_ReturnZero:
	lds32 xhl, 0

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
	call	16405594
	cp	xhl, 27263157
	jr	nz, 66
	ld	xwa, (xsp+264)
	ld	xbc, xiz
	ld	xde, (xsp+260)
	call	16400380
	ld	xwa, (xsp+264)
	call	16408153
	ld	a, (14607:16)
	extz	wa
	pushw	wa
	pushw	225
	pushw	56702
	lda	xwa, (xsp+10)
	push	xwa
	call	16712341
	lda	xsp, (xsp+10)
	lda	xde, (xsp+4)
	ld	xwa, (xsp+264)
	ld	xbc, 29360143
	call	16421459
PsCmpMemBox_ReturnZero:
	lds32 xhl, 0

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
	lds32 xbc, 4
	call SetLswFilter
	jr CmpFunc_Return

AcCmpTempoBox_HandleEvt2:
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld XWA, (xsp + 0x0104)
	lds32 xbc, 4
	call ResetLswFilter
	jr CmpFunc_Return

AcCmpTempoBox_HandleEvtBC:
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	lds32 xwa, 4
	call MainLswGet
	jr CmpFunc_Return

AcCmpTempoBox_HandleEvt1C:
	.byte 0xe3, 0xfd, 0x04, 0x01, 0x20, 0xee, 0x8a, 0x1d
	.byte 0xfc, 0x3f, 0xfa, 0xa6, 0x20, 0xe8, 0xcf, 0x04
	.byte 0x00, 0x00, 0x00, 0x6e, 0x25, 0x9e, 0x04, 0x04
	.byte 0x0b, 0xe1, 0x00, 0x0b, 0x82, 0xdd, 0xbf, 0x0a
	.byte 0x30, 0x38, 0x1d, 0x95, 0x02, 0xff, 0xbf, 0x0a
	.byte 0x37, 0xbf, 0x04, 0x32, 0xe3, 0xfd, 0x04, 0x01
	.byte 0x20, 0x41, 0x0f, 0x00, 0xc0, 0x01, 0x1d, 0x53
	.byte 0x92, 0xfa
CmpFunc_Return:
	lds32 xhl, 0

AcCmpTempoBox_Epilogue:
	pop xiz
	lda_dri XSP, 0xfd, 0x04, 0x01
	ret

CmpNamingCheck:
	push	xiz
	ld	xiz, xwa
	cp	xbc, 31457404
	jr	z, 63
	cp	xbc, 31457412
	jr	z, 51
	cp	xbc, 31457338
	jr	nz, 43
	pushw	0
	pushw	13344
	push	xde
	call	16713584
	pushw	13
	pushw	0
	pushw	13344
	pushw	2
	pushw	3156
	call	16712982
	lda	xsp, (xsp+18)
	ld	(134241:24), 0
	ld	xhl, xiz
	jr	9
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
	ld	xwa, (xsp+268)
	call	16400380
	ld	xwa, (xsp+268)
	call	16408153
	ld	xiz, xhl
	ld	a, (13370:16)
	extz	wa
	sla	wa, 2
	lda	xbc, (14802310:24)
	ld_rrl	xwa, xbc, wa
	push	xwa
	lda	xwa, (xsp+8)
	push	xwa
	call	16712341
	inc	8, xsp
	lda	xwa, (xiz+22)
	lda	xbc, (xiz+32)
	cp	(14604:16), 0
	jr	nz, 17
	cp	(14820:16), 1
	jr	nz, 10
	ldw	(xbc), 0
	ldw	(xwa), 255
	jr	8
PsNameMemBox_SetColorFF:
	ldw (xbc), 0xff
	ldw (xwa), 0xf5
PsNameMemBox_SendNotify:
	ld	xwa, (xsp+268)
	ld	xbc, 29360141
	lds32	xde, 0
	call	16421459
	lda	xde, (xsp+4)
	ld	xwa, (xsp+268)
	ld	xbc, 29360143
	call	16421459
	call	16405594
	cp	xhl, 27263160
	jr	nz, 61
	lda	xwa, (xsp+260)
	ldw	(xwa), 197
	lda	xde, (xwa+2)
	ldw	(xde), 60
	ld	bc, (xwa)
	add	bc, 88
	ld	(xwa+4), bc
	ld	bc, (xde)
	add	bc, 38
	ld	(xwa+6), bc
	cp	(14604:16), 0
	jr	nz, 9
	pushw 242
	lds	bc, 1
	lds	de, 2
	jr	7
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
	call	16408153
	add	xhl, xiz
	ld	xwa, (xhl)
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	16713584
	inc	8, xsp
	jr	19
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
	lda xix, (EasyCmp_GridCheck_DataBlock:24)
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
	lda xbc, (xsp + 0x14)
	ld XWA,XDE
	srl XWA, 0x00
	ld QWA,0
	ld (XBC),WA
	lda xwa, (xbc + 0x02)
	ld (XWA),DE
	lda XDE, (XSP)
	ld (XBC+0x04),XDE
	ld BC,(XBC)
	ld WA,(XWA)
	dec 2,A
	extz WA
	cps bc, 2
	jr z, EasyCmp_GridEvtEnc_Case2
	cps bc, 1
	jr nz, EasyCmp_GridCheck_EventCase3
	lda xbc, (0x370f:16)
	extz XWA
	add XWA,XBC
	ld A,(XWA)
	extz WA
	sla WA, 0x02
	lda xbc, (0x03dc92:24)
	ldl_dri xwa, 0x07, 0xe4, 0xe0
	push XWA
	jr t, EasyCmp_GridCheck_EventCase1
EasyCmp_GridEvtEnc_Case2:
	lda	xbc, (14102:16)
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	cps	a, 0
	jr	nz, 15
	ld	xwa, 14802702
	push	xwa
EasyCmp_GridCheck_EventCase1:
	push	xde
	call	16712341
	inc	8, xsp
	jr	17
EasyCmp_GridCheck_EventCase2:
	extz	wa
	pushw	wa
	pushw	225
	pushw	57106
	push	xde
	call	16712341
	lda	xsp, (xsp+10)
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
	call	16713584
	inc	8, xsp
	ld	xhl, xiz
	jr	79
	lds32	xhl, 1
	jr	75
	lds32	xhl, 3
	jr	71
	lda	xhl, (32418:16)
	jr	65
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
	pushw	16
	push	xwa
	pushw	0
	pushw	13344
	call	16712982
	lda	xsp, (xsp+10)
	ld	(13360:16), 0
MspNaming_CleanupExit:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 16)
	ret

MspNamingCheck:
	push	xiz
	ld	xiz, xwa
	cp	xbc, 31457404
	jr	z, 57
	cp	xbc, 31457412
	jr	z, 45
	cp	xbc, 31457338
	jr	nz, 37
	pushw	0
	pushw	13344
	push	xde
	call	16713584
	pushw	16
	pushw	0
	pushw	13344
	pushw	2
	pushw	3184
	call	16712982
	lda	xsp, (xsp+18)
	ld	xhl, xiz
	jr	9
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
	ld	xwa, xiz
	call	16400380
	ld	a, (32418:16)
	extz	wa
	sla	wa, 2
	lda	xbc, (14802800:24)
	ld_rrl	xwa, xbc, wa
	push	xwa
	lda	xwa, (xsp+8)
	push	xwa
	call	16712341
	inc	8, xsp
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16421459
PsMspNameBnk_SetReturnZero:
	lds32 xhl, 0

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
	lds32 xde, 0
	jrl VwVariBox_DispatchAndReturn

VwVariBox_Init:
	ld xwa, 0x28800

	call 16567398

	ld (xsp + 6), hl

	ld XWA, (xsp + 0x0118)

	ld xbc, xiz

	ld XDE, (xsp + 0x0114)

	.byte 0x1d, 0xfc, 0x3f, 0xfa	; call InheritedProc (v7 addr)

	ld XWA, (xsp + 0x0118)

	.byte 0x1d, 0x59, 0x5e, 0xfa	; call GetViewInstance (v7 addr)

	ld a, (xhl + 42)

	extz wa

	lda xbc, (xhl + 38)

	cp wa, (xsp + 6)

	scc16 z, wa

	ld xbc, (xbc)

	ld (xbc), wa

	ld XWA, (xsp + 0x0118)

	ld xbc, 0x1c0000d

	lds32 xde, 0

	.byte 0x78, 0xe7, 0x02	; jrl VwVariBox_DispatchAndReturn (v7 displacement)



VwVariBox_Match:
	ld XWA,(XSP+0x0118)
	ld XBC,XIZ
	ld XDE,(XSP+0x0114)
	call InheritedProc
	ld XWA,(XSP+0x0118)
	call GetViewInstance
	ld XIZ,XHL
	ld XWA,0x00028800
	call 0xfccc66
	ld (XSP+0x06),HL
	ld XWA,(XSP+0x0114)
	ld XWA,(XWA)
	cp XWA,0x00028800
	jrl nz, VwVariBox_ReturnHandled
	ld C,(XIZ+0x2a)
	extz BC
	ld XWA,(XIZ+0x26)
	cp BC,(XSP+0x06)
	jr nz, VwVariBox_Match_ValueMismatch
	ldw (XWA), 0x0001
	jr t, VwVariBox_Match_Repaint
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
	ld XWA, (xsp + 0x0118)
	ld xbc, 0x1c0000d
	lds32 xde, 0
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
	lds32 xde, 0
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
	lds32 xhl, 0
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
	ld	a, (xwa)
	extz	wa
	sla	wa, 2
	lda	xbc, (14802896:24)
	ld_rrl	xwa, xbc, wa
	push	xwa
	ld	xwa, (xsp+280)
	push	xwa
	call	16712341
	inc	8, xsp
	jr	-61
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
	pushw	16
	push	xwa
	ld	xwa, (xsp+282)
	push	xwa
	call	16713148
	lda	xsp, (xsp+10)
	jr	-126
VwVariBox_OK:
	ld XWA,(XSP+0x0118)
	call GetViewInstance
	cp (0x7e6f:16), 0x00
	jr nz, VwVariBox_OK_Forward
	ld WA,(XHL+0x24)
	extz XWA
	cp XWA,(XSP+0x0114)
	jr nz, VwVariBox_OK_Forward
	ld DE,(XHL+0x1a)
	cp DE,0xffff
	jr z, VwVariBox_OK_Forward
	exts XDE
	ld XWA,0xffffffff
	ld XBC,0x01c0001b
	call SendEvent
	ld XWA,(XSP+0x0118)
	ld XBC,0x01e0004d
	lds32 xde, 1
	call SendEvent
	ld XWA,(XSP+0x0118)
	call GetViewInstance
	ld C,(XHL+0x2a)
	extz BC
	ld XWA,0x00028800
	lds de, 0
	call MainLswPut
	jrl t, VwVariBox_ReturnHandled
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
	lds32 xde, 0

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
	lds32 xhl, 1
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
	push	xiz
	cp	xbc, 29360140
	jrl	z, 131
	cp	xbc, 29360139
	jr	z, 123
	cp	xbc, 29360130
	jr	z, 115
	cp	xbc, 29360129
	jr	nz, 107
	call	16405600
	ld	xiz, xhl
	call	16405594
	cp	xhl, xiz
	jr	z, 93
	ld	xwa, 165888
	call	16567398
	cp	hl, 10
	jr	ge, 38
	ld	xwa, 13107201
	ld	xbc, 31457366
	lds32	xde, 0
	call	16421459
	cp	xhl, 1
	jr	z, 54
	ld	xwa, 13107201
	ld	xbc, 31457407
	lds32	xde, 1
	jr	36
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
	ld XWA,(XSP+0x0c)
	call GetViewInstance
	ld (XSP+0x04),XHL
	ld XWA,(XSP+0x0c)
	call GetViewInstance
	cp (0x7e6f:16), 0x00
	jr nz, MspBnk_JoinLoadParams
	ld XWA,(XSP+0x04)
	ld WA,(XWA+0x2a)
	extz XWA
	cp XWA,(XSP+0x08)
	jr nz, MspBnk_JoinLoadParams
	cpw (XHL+0x1a), 0xffff
	jr z, MspBnk_JoinLoadParams
	ld XWA,(XSP+0x0c)
	call GetViewInstance
	ld C,(XHL+0x32)
	extz BC
	ld XWA,0x00028800
	lds de, 0
	call MainLswPut
	ld XWA,0x00028800
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
	ld	xwa, xiz
	call	16408153
	ld	xwa, (xsp+260)
	push	xwa
	lda	xwa, (xsp+8)
	push	xwa
	call	16712341
	inc	8, xsp
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, 29360143
	jr	100
MspBnkNameBox_HandleEvt1C:
	ld	xwa, xiz
	call	16408153
	ld	xwa, (xsp+260)
	push	xwa
	lda	xwa, (xsp+8)
	push	xwa
	call	16712341
	inc	8, xsp
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, 29360143
	jr	66
MspBnkNameBox_HandleEvt1D:
	ld	xwa, xiz
	call	16408153
	ld	xwa, (xsp+260)
	push	xwa
	lda	xwa, (xsp+8)
	push	xwa
	call	16712341
	inc	8, xsp
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, 29360143
	jr	32
RgpSetBnk_GridCheck:
	ld	xwa, xiz
	call	16408153
	ld	xwa, (xsp+260)
	push	xwa
	lda	xwa, (xsp+8)
	push	xwa
	call	16712341
	inc	8, xsp
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, 29360143
MspBnk_SendEventJoin:
	call SendEvent

; RgpSetBnkCheck case 1
RgpSetBnk_GridCheck_Case1:
	lds32 xhl, 0
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
	lda xhl, (xsp + 0x14)
	ld XWA,XDE
	srl XWA, 0x00
	ld QWA,0
	ld (XHL),WA
	lda xbc, (xhl + 0x02)
	ld (XBC),DE
	lda XDE, (XSP)
	ld (XHL+0x04),XDE
	ld a, (0x7ea1:16)
	sll A, 0x04
	ldb W, 0x00
	extz XWA
	add XWA,0x001e8a00
	ld XIX,XWA
	ld HL,(XHL)
	ld WA,(XBC)
	sla WA, 0x01
	dec 4,WA
	exts XWA
	add XWA,XIX
	cps hl, 2
	jr z, RgpSetBnk_EvtEnc_SendAudioCmd
	cps hl, 1
	jr nz, AudioEvt_GetFocusRetZero
	ld XBC,XWA
	ld L,(XWA)
	cp L,0x0d
	jr nc, RgpSetBnk_EvtEnc_HighIndex
	ld A,(XBC)
	extz WA
	sla WA, 0x02
	lda xbc, (PtrTbl_MusicStyleBankNames2:24)
	ldl_dri xwa, 0x07, 0xe4, 0xe0
	push XWA
	push XDE
	call 0xff0295
	inc 0,XSP
	jr t, AudioEvt_GetFocusRetZero
RgpSetBnk_EvtEnc_HighIndex:
	ld xwa, 0x1e8a80
	cp l, 0xe
	jr nz, RgpSetBnk_EvtEnc_CopyMem
	ld xwa, 0x1e8a90

RgpSetBnk_EvtEnc_CopyMem:
	pushw	16
	push	xwa
	push	xde
	call	16713148
	lda	xsp, (xsp+10)
	ld	(xsp+16), 0
	jr	22
RgpSetBnk_EvtEnc_SendAudioCmd:
	ld	a, (xwa+1)
	inc	1, a
	extz	wa
	pushw	wa
	pushw	225
	pushw	58044
	push	xde
	call	16712341
	lda	xsp, (xsp+10)
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
	ld	xwa, xiz
	call	16400380
	ld	a, (32417:16)
	extz	wa
	sla	wa, 2
	lda	xbc, (14803664:24)
	ld_rrl	xwa, xbc, wa
	push	xwa
	lda	xwa, (xsp+8)
	push	xwa
	call	16712341
	inc	8, xsp
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16421459
RgpSetBnkBox_SetReturnZero:
	lds32 xhl, 0

RgpSetBnkBox_Epilogue:
	pop xiz
	lda_dri XSP, 0xfd, 0x00, 0x01
	ret

MspRGrpSetBnkFunc:
	.byte 0xd7, 0xfa, 0x04, 0xe9, 0xcf, 0x07, 0x00, 0xc0
	.byte 0x01, 0x6e, 0x72, 0xc1, 0xa1, 0x7e, 0x3f, 0x00
	.byte 0x6e, 0x07, 0xf1, 0xa1, 0x7e, 0x00, 0x01, 0x68
	.byte 0x05
MspRGrpSetBnk_SetToZero:
	ld	(32417:16), 0
MspRGrpSetBnk_UpdateLsw:
	ld c, (32417:16)

	add c, 0xf

	extz bc

	ld xwa, 0x28800

	lds de, 0

	call	16381053

	ld xwa, 0xcc0007

	ld xbc, 0x1c0000b

	lds32 xde, 0

	call	16421459

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
	lds32 xhl, 0
	popw_erp 0xfa
	ret

MspRgpShowHideFunc:
	cp	xbc, 29360140
	jr	z, 66
	cp	xbc, 29360139
	jr	z, 58
	cp	xbc, 29360130
	jr	z, 50
	cp	xbc, 29360129
	jr	nz, 42
	or	xde, xde
	jr	nz, 38
	ld	a, (32417:16)
	cps	a, 1
	jr	z, 16
	cps	a, 0
	jr	nz, 26
	ld	xwa, 165888
	ldw	bc, 15
	lds	de, 0
	jr	10
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
	ld	xwa, xiz
	call	16400380
	ld	xwa, xiz
	call	16408153
	ld	wa, (32370:16)
	pushw	wa
	pushw	225
	pushw	58104
	lda	xwa, (xsp+10)
	push	xwa
	call	16712341
	lda	xsp, (xsp+10)
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16421459
MspMeasBox_SetReturnZero:
	lds32 xhl, 0

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
	ld	xwa, xiz
	call	16400380
	ld	xwa, xiz
	call	16408153
	ld	wa, (32124:16)
	mul	wa, 100
	extz	xwa
	div	wa, 57
	cp	wa, 99
	jr	ule, 3
	ldw	wa, 99
MspMemBox_ClampValue:
	extz	wa
	pushw	wa
	pushw	225
	pushw	58118
	lda	xwa, (xsp+10)
	push	xwa
	call	16712341
	lda	xsp, (xsp+10)
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16421459
MspMemBox_SetReturnZero:
	lds32 xhl, 0

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
	.byte 0xee, 0x88, 0x1d, 0xfc, 0x3f, 0xfa, 0xee, 0x88
	.byte 0x1d, 0x59, 0x5e, 0xfa, 0x40, 0x80, 0x8a, 0x1e
	.byte 0x00, 0xc1, 0x78, 0x7e, 0x3f, 0x05, 0x63, 0x05
	.byte 0x40, 0x90, 0x8a, 0x1e, 0x00
MspRecBnkBox_CopyMemBlock:
	pushw	16
	push	xwa
	lda	xwa, (xsp+10)
	push	xwa
	call	16713148
	lda	xsp, (xsp+10)
	lda	xde, (xsp+4)
	ld	(xde+16), 0
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16421459
MspRecBnkBox_SetReturnZero:
	lds32 xhl, 0

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
	ld	xwa, xiz
	call	16400380
	ld	xwa, xiz
	call	16408153
	ld	a, (32376:16)
	cps	a, 5
	jr	ule, 2
	dec	6, a
AcSndArgGrid_BnkDispatch:
	inc	1, a
	extz	wa
	pushw	wa
	pushw	225
	pushw	58132
	lda	xwa, (xsp+10)
	push	xwa
	call	16712341
	lda	xsp, (xsp+10)
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16421459
AcSndArgGrid_BnkCase1:
	lds32 xhl, 0

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
	lda xix, (MspPlayModeFunc_DataBlock:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

MspPlayModeFunc_DataBlock:
	lds	wa, 0
	call	16359726
	ld	xwa, (xiz+14)
	sll	xwa, 2
	lda	xbc, (xsp+4)
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xiz+18)
	push	xwa
	call	16713584
	inc	8, xsp
	ld	xhl, (xsp+12)
	jr	43
	ld	a, (1054:16)
	and	a, 4
	cps	a, 4
	scc16	nz, hl
	extz	xhl
	jr	28
	lds32	xhl, 1
	jr	24
	lda	xhl, (32419:16)
	jr	18
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
	lda xix, (AcSndArgGrid_Init:24)
	jp_ind 8, 0x07, 0xf0, 0xe0
AcSndArgGrid_Init:
	ld	xwa, (xsp+22)
	ld	xbc, xiz
	ld	xde, (xsp+18)
	call	16400380
	ld	xwa, (xsp+22)
	call	16408153
	ld	(xsp+8), xhl
	ld	xwa, (xsp+22)
	ld	xbc, 31457423
	lds32	xde, 0
	call	16421459
	ld	(xsp+4), xhl
	ld	xwa, (xsp+8)
	ld	bc, (xwa+26)
	ld	xwa, (xsp+4)
	srl	xwa, 0
	ld	qwa, 0
	add	wa, bc
	ld	de, wa
	extz	xde
	ld	xwa, (xsp+22)
	ld	xbc, 29360151
	call	16359788
	ld	xwa, (xsp+8)
	ld	bc, (xwa+26)
	ld	xwa, (xsp+4)
	srl	xwa, 0
	ld	qwa, 0
	add	wa, bc
	ld	de, wa
	extz	xde
	ld	xwa, (xsp+22)
	ld	xbc, 29360152
	call	16359805
	lds	wa, 1
	jrl	441
	ld	xwa, (xsp+22)
	ld	xbc, xiz
	ld	xde, (xsp+18)
	call	16400380
	ld	xwa, (xsp+22)
	ld	xbc, 31457360
	ld	xde, (xsp+18)
	call	16421459
	or	xhl, xhl
	jr	z, 102
	ld	xwa, (xsp+22)
	ld	xbc, 31457423
	lds32	xde, 0
	call	16421459
	dec	1, hl
	extz	xhl
	add	xhl, 4294901760
	ld	xwa, (xsp+22)
	ld	xbc, 29360142
	ld	xde, xhl
	call	16421459
	ld	xwa, (xsp+22)
	ld	xbc, 29360153
	ld	xde, (xsp+18)
	call	16359856
	ld	xwa, (xsp+22)
	call	16408153
	ld	xwa, (xhl+42)
	ld	de, (xwa)
	ld	a, e
	dec	2, a
	extz	wa
	lda	xbc, (xsp+12)
	.byte 0xc3, 0x07, 0xe4, 0xe0, 0x19, 0xf2, 0x32
	ldb	d, 0
	extz	xde
	ld	xwa, 21233691
	ld	xbc, 31719460
	call	16402006
	jrl	668
AcSndArgGrid_ScrollUp_NoCanScroll:
	ld	xwa, (xsp+22)
	ld	xbc, 31457425
	ld	xde, (xsp+18)
	call	16421459
	or	xhl, xhl
	jrl	z, 648
	ld	xwa, (xsp+22)
	call	16408153
	ld	xwa, (xhl+70)
	ld	xbc, xiz
	ld	xde, (xsp+18)
	call	16401834
	ld	xwa, (xsp+22)
	ld	xbc, 29360153
	ld	xde, (xsp+18)
	call	16359856
	ld	xwa, (xsp+22)
	ld	xbc, 29360151
	ld	xde, (xsp+18)
	call	16359788
	ld	xwa, (xsp+22)
	ld	xbc, 29360152
	ld	xde, (xsp+18)
	call	16359805
	lds	wa, 1
	jrl	219
	ld	xwa, (xsp+22)
	ld	xbc, xiz
	ld	xde, (xsp+18)
	call	16400380
	ld	xwa, (xsp+22)
	ld	xbc, 31457360
	ld	xde, (xsp+18)
	call	16421459
	or	xhl, xhl
	jr	z, 102
	ld	xwa, (xsp+22)
	ld	xbc, 31457423
	lds32	xde, 0
	call	16421459
	inc	1, hl
	extz	xhl
	add	xhl, 4294901760
	ld	xwa, (xsp+22)
	ld	xbc, 29360142
	ld	xde, xhl
	call	16421459
	ld	xwa, (xsp+22)
	ld	xbc, 29360154
	ld	xde, (xsp+18)
	call	16359856
	ld	xwa, (xsp+22)
	call	16408153
	ld	xwa, (xhl+42)
	ld	de, (xwa)
	ld	a, e
	dec	2, a
	extz	wa
	lda	xbc, (xsp+12)
	.byte 0xc3, 0x07, 0xe4, 0xe0, 0x19, 0xf2, 0x32
	ldb	d, 0
	extz	xde
	ld	xwa, 21233691
	ld	xbc, 31719460
	call	16402006
	jrl	446
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
	call	16408153
	add	xhl, xiz
	ld	xwa, (xhl)
	push	xwa
	ld	xwa, (xsp+22)
	push	xwa
	call	16713584
	inc	8, xsp
	jrl	313
	ld	xwa, (xsp+22)
	ld	xbc, xiz
	ld	xde, (xsp+18)
	call	16400380
	call	16405594
	cp	xhl, 27263196
	jrl	nz, 288
	ld	xwa, (xsp+18)
	ld	xwa, (xwa)
	cp	xwa, 51294
	jrl	z, 222
	cp	xwa, 51232
	jrl	z, 198
	cp	xwa, 51200
	jrl	z, 189
	cp	xwa, 50270
	jrl	z, 165
	cp	xwa, 50208
	jrl	z, 141
	cp	xwa, 50176
	jrl	z, 132
	cp	xwa, 49246
	jr	z, 109
	cp	xwa, 49184
	jr	z, 86
	cp	xwa, 49152
	jr	z, 78
	cp	xwa, 52318
	jr	z, 55
	cp	xwa, 52256
	jr	z, 32
	cp	xwa, 52224
	jr	z, 24
	cp	xwa, 53248
	jrl	nz, 172
	ld	xwa, (xsp+22)
	ld	xbc, 31457421
	ld	xde, 65538
	jr	118
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
	ld	(xix), wa
	ld	wa, qwa
	ld	(xde), wa
	ld	xbc, xiz
	ld	(xhl), xiz
	ld	wa, (xde)
	dec	2, wa
	cps	wa, 4
	jr	z, 40
	cps	wa, 3
	jr	z, 30
	cps	wa, 2
	jr	z, 20
	cps	wa, 1
	jr	z, 10
	cps	wa, 0
	jr	nz, 36
	lda	xwa, (14684:16)
	jr	22
SndArgGridCheck_PlayCol_1:
	lda	xwa, (14701:16)
	jr	16
SndArgGridCheck_PlayCol_2:
	lda	xwa, (14718:16)
	jr	10
SndArgGridCheck_PlayCol_3:
	lda	xwa, (14735:16)
	jr	4
SndArgGridCheck_PlayCol_4:
	lda	xwa, (14752:16)
SndArgGridCheck_PlayCol_Strcpy:
	push	xwa
	push	xbc
	call	16713584
	inc	8, xsp
SndArgGridCheck_PlayCol_Send:
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 24)
	ld xbc, 0x1e0008c
	jr SndArgGridCheck_DispatchPlayAudio

SndArgGridCheck_PlayRowAudio:
	ld	(xix), wa
	ld	wa, qwa
	ld	(xde), wa
	ld	xbc, xiz
	ld	(xhl), xiz
	ld	wa, (xde)
	dec	2, wa
	cps	wa, 4
	jr	z, 40
	cps	wa, 3
	jr	z, 30
	cps	wa, 2
	jr	z, 20
	cps	wa, 1
	jr	z, 10
	cps	wa, 0
	jr	nz, 36
	lda	xwa, (14664:16)
	jr	22
SndArgGridCheck_PlayRow_1:
	lda	xwa, (14668:16)
	jr	16
SndArgGridCheck_PlayRow_2:
	lda	xwa, (14672:16)
	jr	10
SndArgGridCheck_PlayRow_3:
	lda	xwa, (14676:16)
	jr	4
SndArgGridCheck_PlayRow_4:
	lda	xwa, (14680:16)
SndArgGridCheck_PlayRow_Send:
	push	xwa
	push	xbc
	call	16712341
	inc	8, xsp
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
	.byte 0xe9, 0xcf, 0x01, 0x00, 0xc0, 0x01, 0x6e, 0x46
	.byte 0x1d, 0x60, 0x54, 0xfa, 0xeb, 0xcf, 0xee, 0x00
	.byte 0xa0, 0x01, 0x6e, 0x3a, 0xc1, 0x03, 0x33, 0x3f
	.byte 0x01, 0x6e, 0x33, 0x40, 0xff, 0xff, 0xff, 0xff
	.byte 0x41, 0x9e, 0x00, 0xe0, 0x01, 0xea, 0xa9, 0x1d
	.byte 0x53, 0x92, 0xfa, 0x40, 0xff, 0xff, 0xff, 0xff
	.byte 0x41, 0x9e, 0x00, 0xe0, 0x01, 0xea, 0xa8, 0x1d
	.byte 0x45, 0x93, 0xfa, 0x40, 0xff, 0xff, 0xff, 0xff
	.byte 0x41, 0x14, 0x00, 0xc0, 0x01, 0x42, 0x01, 0x00
	.byte 0x80, 0x01, 0x1d, 0x45, 0x93, 0xfa
ParamList_ReturnZero:
	lds32 xhl, 0
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
	lds iz, 1
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
	ld XWA,XIZ
	ld XDE,(XSP+0x009e)
	call InheritedProc
	ld XWA,XIZ
	call GetViewInstance
	ld (XSP+0x06),XHL
	ld XDE,(XSP+0x009e)
	or XDE,XDE
	jrl z, PsParaListBoxProc_Return
	ld XWA,(XSP+0x06)
	ld BC,(XWA+0x22)
	.byte 0x98, 0x24, 0x49
	ld	a, (xde)
	exts	wa
	cp	wa, bc
	jrl	ge, 239
	lda	xbc, (xsp+142)
	ld	xwa, xiz
	call	16355792
	lda	xbc, (xsp+142)
	lda	xwa, (xbc+4)
	ld	(xsp+10), xwa
	ld	de, (xwa)
	.byte 0x91, 0xa2
	exts	xde
	ld	xwa, (xsp+6)
	.byte 0x98, 0x22, 0x5a
	ld	(xsp+4), de
	lda	xiy, (xbc+6)
	lda	xix, (xbc+2)
	ld	hl, (xix)
	ld	iz, (xiy)
	sub	iz, hl
	ld	de, (xwa+36)
	exts	xiz
	divs	xiz, xde
	ld	xwa, (xsp+158)
	ld	a, (xwa)
	exts	wa
	exts	xwa
	divs	xwa, xde
	ld	wa, qwa
	ld	qde, wa
	ld	xwa, (xsp+158)
	ld	a, (xwa)
	exts	wa
	exts	xwa
	divs	xwa, xde
	ld	de, wa
	ld	wa, iz
	mul	wa, qde
	inc	2, wa
	add	hl, wa
	ld	(xix), hl
	add	hl, iz
	ld	(xiy), hl
	ld	wa, (xsp+4)
	mul	xwa, xde
	inc	2, wa
	add	(xbc), wa
	ld	de, (xbc)
	.byte 0x9f, 0x04, 0x82
	ld	xwa, (xsp+10)
	ld	(xwa), de
	lda	xde, (xsp+154)
	ld	wa, (xbc)
	ld	(xde), wa
	ld	wa, (xix)
	ld	(xde+2), wa
	ld	xwa, (xsp+158)
	inc	1, xwa
	push	xwa
	lda	xwa, (xsp+18)
	push	xwa
	call	16713584
	inc	8, xsp
	ld	xbc, (xsp+6)
	ld	xix, (xbc+38)
	ld	xwa, (xsp+158)
	ld	a, (xwa)
	ldb_erp	a, 244
	exts	iy
	lda	xde, (xsp+14)
	lda	xhl, (xbc+28)
	lda	xbc, (xsp+154)
	lda	xwa, (xsp+142)
	.byte 0x94, 0xf5
	jr	nz, 11
	ld	xhl, (xhl)
	push	xhl
	pushw 0
	pushw 255
	jr	12
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
	call	16713584
	inc	8, xsp
	ld	xhl, xiz
	jr	19
	lds32	xhl, 1
	jr	15
	ld	xhl, 22
	jr	8
	lda	xhl, (14769:16)
	jr	2
PsSCTxtBox_EventDispatch:
	lds32 xhl, 0
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
	ld	xwa, xiz
	call	16400380
	pushw	0
	pushw	15564
	lda	xwa, (xsp+8)
	push	xwa
	call	16713584
	inc	8, xsp
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16421459
SCTxtBox_SetReturnZero:
	lds32 xhl, 0

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
	lda	xhl, (15564:16)
	jr	38
SCTxtBox2_HandleEvtBC:
	ld	xwa, xiz
	call	16400380
	pushw	0
	pushw	15564
	lda	xwa, (xsp+8)
	push	xwa
	call	16713584
	inc	8, xsp
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16421459
SCTxtBox2_SetReturnZero:
	lds32 xhl, 0

SCTxtBox2_Epilogue:
	pop xiz
	lda_dri XSP, 0xfd, 0x00, 0x02
	ret

StylCnvStorOkFunc:
	cp	xbc, 29360135
	jr	nz, 20
	lds32	xde, 0
	ld	e, (14769:16)
	ld	xwa, 21233699
	ld	xbc, 31719472
	call	16402006
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
	ldw (xsp+10), 0
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
	ldw (xsp+6), 65535
	jr	54
	.byte 0xbf
	ldio	2, 1
	nop
	jr	5
	ldw (xsp+8), 0
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
	incw	1, (xsp+14)
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
	ldwio	4, 8863
	ldb	b, 30
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
	ldwio	4, 8863
	ldb	b, 30
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
	cps	bc, 3
	jr	z, 114
	cps	bc, 2
	jr	z, 103
	cps	bc, 1
	scc16	nz, bc
	ld	(xsp+6), bc
	ldw (xsp+8), 0
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
	cp	(13370:16), 12
	jr	nc, 19
	ld	xwa, xiz
	call	16400380
	ld	xwa, xiz
	ld	xbc, 29360143
	lds32	xde, 0
	call	16421459
CmpNameMenu_SetReturnZero:
	lds32 xhl, 0

CmpNameMenu_Epilogue:
	pop xiz
	ret

AttLangCheck:
	cp xbc, 0x1e0009f
	jr nz, AttLangCheck_ReturnZero
	lda xhl, (MSG_ATTENTION_ID_0xC:24)
	ret

AttLangCheck_ReturnZero:
	lds32 xhl, 0
	ret

SureLangCheck:
	cp xbc, 0x1e0009f
	jr nz, SureLangCheck_ReturnZero
	lda xhl, (MSG_ARE_YOU_SURE_ID_0x1C:24)
	ret

SureLangCheck_ReturnZero:
	lds32 xhl, 0
	ret

SndMemLangCheck:
	cp xbc, 0x1e0009f
	jr nz, SndMemLangCheck_ReturnZero
	lda xhl, (MSG_CUSTOM_SOUND_COPY_ID_0x8E:24)
	ret

SndMemLangCheck_ReturnZero:
	lds32 xhl, 0
	ret

SndMem1LangCheck:
	cp xbc, 0x1e0009f
	jr nz, SndMem1LangCheck_ReturnZero
	lda xhl, (MSG_SOUND_GROUP_AFFECTED_ID_0x24:24)
	ret

SndMem1LangCheck_ReturnZero:
	lds32 xhl, 0
	ret

MemfulLangCheck:
	cp xbc, 0x1e0009f
	jr nz, MemfulLangCheck_ReturnZero
	lda xhl, (MSG_CUSTOM_SOUND_FULL_ID_0x7C:24)
	ret

MemfulLangCheck_ReturnZero:
	lds32 xhl, 0
	ret

Memful2LangCheck:
	cp xbc, 0x1e0009f
	jr nz, Memful2LangCheck_ReturnZero
	lda xhl, (MSG_CUSTOM_RHYTHMS_AFFECTED_ID_0x1E:24)
	ret

Memful2LangCheck_ReturnZero:
	lds32 xhl, 0
	ret

StylCnvLangCheck:
	cp xbc, 0x1e0009f
	jr nz, StylCnvLangCheck_ReturnZero
	lda xhl, (MSG_INSERT_STYLE_CONVERT_ID_0x26:24)
	ret

StylCnvLangCheck_ReturnZero:
	lds32 xhl, 0
	ret

SndArrLangCheck:
	cp xbc, 0x1e0009f
	jr nz, SndArrLangCheck_ReturnZero
	lda xhl, (Hama_ModeInit_Table:24)
	ret

SndArrLangCheck_ReturnZero:
	lds32 xhl, 0
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
	lda	xhl, (16076:16)
	jr	38
StylCnvVer_HandleEvtBC:
	ld	xwa, xiz
	call	16400380
	pushw	0
	pushw	16076
	lda	xwa, (xsp+8)
	push	xwa
	call	16713584
	inc	8, xsp
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, 29360143
	call	16421459
StylCnvVer_SetReturnZero:
	lds32 xhl, 0

StylCnvVer_Epilogue:
	pop xiz
	lda_dri XSP, 0xfd, 0x00, 0x02
	ret


.include "factory_test/test_init.s"
