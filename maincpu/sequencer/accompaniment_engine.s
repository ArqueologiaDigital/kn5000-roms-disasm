; =============================================================================
; Accompaniment Engine (32K lines)
; =============================================================================
;
; Rhythm note dispatch, accompaniment voice selection, timing,
; patch management, drum configuration, and style conversion.
; One of the largest files in the ROM.
; =============================================================================

Rhythm_DispatchNote:
	ld l, a
	ld h, d
	call VoiceParam_ClampAndValidate
	ld a, l
	ld d, h
	cp a, 0x80
	jr c, Rhythm_DispatchNote_Lookup
	cp a, 0xF0
	jr c, Rhythm_DispatchNote_SetParam
	call AccTone_LookupByProgramWrapped
	jr Rhythm_DispatchNote_Return

Rhythm_DispatchNote_SetParam:
	and a, 0x7F
	call AccPatch_SetVoiceParam
	jr Rhythm_DispatchNote_Return

Rhythm_DispatchNote_Lookup:
	ld h, d
	call AccVoice_LookupWithOffset
	call AccStyle_ReadVoiceParam

Rhythm_DispatchNote_Return:
	ret

AccStyle_TempoLookupData:
	push	xiz
	calr	2
	pop	xiz
	ret
	call	16115859
	ret

AccStyle_LookupTempoAndVelocity:
	push xhl
	push xwa
	xor xhl, xhl
	ldda8 l, 37098
	cp l, 0xF
	jr ule, AccStyle_LookupTempo_ClampL
	xor l, l

AccStyle_LookupTempo_ClampL:
	sla l, 1
	ld xwa, 0xF55C2F
	ld_sriw3 HL, 0x03, 0xE0, 0xEC
	xor xwa, xwa
	ldda8 a, 37099
	cp a, 0x4F
	jr ule, AccStyle_LookupTempo_AddAndStore
	xor a, a

AccStyle_LookupTempo_AddAndStore:
	add xhl, xwa
	sla xhl, 1
	add xhl, 0xE49B5F
	ld wa, (xhl)
	stda8 37102, a
	stda8 37103, w
	pop xwa
	pop xhl
	ret

AccStyle_TempoMultiplierTable:
	nop
	nop
	.byte 0x14
	nop
	pushw	wa
	nop
	push	xix
	nop
	.byte 0x50
	nop
	.byte 0x64, 0x00
	jrl	-29696
	nop
	.byte 0xa0, 0x00
	ld	(xix), 200
	nop
	.byte 0xdc, 0x00, 0xf0, 0x00, 0x04, 0x01
	push_f
	.byte 0x01
	jr	1

AccStyle_LookupVelocityTable:
	push xhl
	push xwa
	cpdi8 37098, 128
	jr nc, AccStyle_Velocity_ExtendedRange
	xor xhl, xhl
	ldda8 l, 37098
	sla xhl, 3
	xor xwa, xwa
	ldda8 a, 37099
	and a, 0x7
	add xhl, xwa
	sla xhl, 1
	add xhl, 0xE4935F
	ld wa, (xhl)
	jr AccStyle_Velocity_StoreResult

AccStyle_Velocity_ExtendedRange:
	cpdi8 37098, 240
	jr nc, AccStyle_Velocity_HighRange
	xor xhl, xhl
	ldda8 l, 37098
	and l, 0x7F
	cp l, 0xB
	jr ule, AccStyle_Velocity_ExtClamp
	xor l, l

AccStyle_Velocity_ExtClamp:
	sla xhl, 3
	xor xwa, xwa
	ldda8 a, 37099
	and a, 0x7
	add xhl, xwa
	sla xhl, 1
	add xhl, 0xE49E53
	ld wa, (xhl)
	jr AccStyle_Velocity_StoreResult

AccStyle_Velocity_HighRange:
	xor xhl, xhl
	ldda8 l, 37098
	and l, 0xF
	cps l, 4
	jr ule, AccStyle_Velocity_HighClamp
	xor l, l

AccStyle_Velocity_HighClamp:
	sla xhl, 1
	add xhl, 0xE49F53
	ld wa, (xhl)

AccStyle_Velocity_StoreResult:
	stda8 37102, a
	stda8 37103, w
	pop xwa
	pop xhl
	ret

AccStyle_CheckRecordMode:
	ldda8 a, 13041
	cp a, 0xE
	jr nz, AccStyle_CheckRecordReturn
	ldda8 a, 36148
	cp a, 0xE
	jr z, AccStyle_CheckRecordReturn
	ordi8 13517, 128

AccStyle_CheckRecordReturn:
	ret

AccStyle_DetectChanges:
	anddi8 13115, 254
	bitda 0, 12931
	jrl nz, AccStyle_DetectChanges_CompareParams
	bitda 1, 12931
	jrl z, AccStyle_DetectChanges_CompareParams
	bitda 4, 1057
	jr z, AccStyle_DetectChanges_Init
	call NoteMap_SendAllNotesOff

AccStyle_DetectChanges_Init:
	stdi8 13026, 0
	call Rhythm_SendNoteOnMax
	call AccompVoice_BulkReadRegisters
	call Rhythm_SendChanPressure
	calr Rhythm_SendResetMsg
	anddi8 13076, 192
	anddi8 13077, 192
	anddi8 13074, 192
	anddi8 13075, 192
	anddi8 13078, 192
	anddi8 13079, 192
	anddi8 13080, 192
	anddi8 13149, 192
	anddi8 13094, 192
	anddi8 13095, 192
	anddi8 12932, 231
	xor a, a
	stda8 13065, a
	stda8 13066, a
	stda8 13067, a
	stda8 13068, a
	stda8 13069, a
	stda8 13070, a
	stda8 13071, a
	stdi8 13099, 0
	anddi8 13424, 2
	anddi8 13097, 192
	ldda8 a, 64607
	and a, 0xFC
	jr z, AccStyle_DetectChanges_QueueDone
	anddi8 64607, 3
	ldb a, 0x0
	ldb w, 0x0
	ldb d, 0x5
	ldb e, 0x48
	call Rhythm_QueuePartChangeEvent

AccStyle_DetectChanges_QueueDone:
	bitda 2, 64608
	jr z, AccStyle_DetectChanges_MarkDirty
	anddi8 64608, 251
	ldb a, 0x0
	ldb w, 0x0
	ldb d, 0x6
	ldb e, 0x48
	call Rhythm_QueuePartChangeEvent

AccStyle_DetectChanges_MarkDirty:
	ordi8 13115, 1

AccStyle_DetectChanges_CompareParams:
	bitda 0, 13043
	jr nz, AccStyle_Compare_StyleNumber
	call Rhythm_SendChanPressure
	ordi8 13115, 1
	jrl AccStyle_DetectChanges_Epilogue

AccStyle_Compare_StyleNumber:
	ldda8 a, 13045
	cpda8 a, 13046
	jr z, AccStyle_Compare_StyleNumDone
	ordi8 13115, 1

AccStyle_Compare_StyleNumDone:
	ldda8 a, 13047
	cpda8 a, 13048
	jr z, AccStyle_Compare_Variation
	ordi8 13115, 1

AccStyle_Compare_Variation:
	ldda8 a, 13049
	and a, 0x7
	cpda8 a, 13050
	jr z, AccStyle_Compare_VariationDone
	ordi8 13115, 1

AccStyle_Compare_VariationDone:
	bitda 7, 13517
	jr z, AccStyle_Compare_RegistrationFlag
	anddi8 13517, 127
	ordi8 13115, 1

AccStyle_Compare_RegistrationFlag:
	ldda8 a, 13109
	xorda8 a, 13042
	and a, 0x2
	cps a, 0
	jr z, AccStyle_Compare_SplitA
	ordi8 13115, 1
	jr AccStyle_DetectChanges_Epilogue

AccStyle_Compare_SplitA:
	ldda8 a, 13055
	cpda8 a, 13056
	jr z, AccStyle_Compare_SplitADone
	ordi8 13115, 1

AccStyle_Compare_SplitADone:
	ldda8 a, 13057
	cpda8 a, 13058
	jr z, AccStyle_Compare_LayerA
	ordi8 13115, 1

AccStyle_Compare_LayerA:
	ldda8 a, 13061
	cpda8 a, 13062
	jr z, AccStyle_Compare_LayerADone
	ordi8 13115, 1

AccStyle_Compare_LayerADone:
	ldda8 a, 13063
	cpda8 a, 13064
	jr z, AccStyle_Compare_TuningState
	ordi8 13115, 1

AccStyle_Compare_TuningState:
	ldda8 a, 13288
	xorda8 a, 13289
	bit 0, a
	jr z, AccStyle_Compare_TuningDone
	ordi8 13115, 1

AccStyle_Compare_TuningDone:
	call AccTuning_Toggle

AccStyle_DetectChanges_Epilogue:
	bitda 0, 13115
	jr z, AccStyle_DetectChanges_ClearFlags
	calr AccStyle_ApplyChanges

AccStyle_DetectChanges_ClearFlags:
	stdi8 13140, 0
	stdi8 13141, 0
	stdi8 13151, 0
	anddi8 13143, 252
	anddi8 13153, 120
	ret

AccStyle_ApplyChanges:
	calr AccStyle_ResetAllVoiceState
	anddi8 12931, 251
	stdi8 1122, 0
	calr AccBuf_ResetAllPositions
	call AccompVoice_BulkReadRegisters
	ldda8 a, 13047
	and a, 0x7F
	and a, 0x7
	stda8 13030, a
	stda8 13032, a
	ldda8 a, 13045
	stda8 13029, a
	stda8 13031, a
	stda8 13168, a
	call AccTuning_Init
	cpdi8 13029, 128
	jr nc, AccStyle_ApplyChanges_Extended
	calr AccStyle_ApplyStandardStyle
	jr AccStyle_ApplyChanges_Finalize

AccStyle_ApplyChanges_Extended:
	calr AccStyle_ApplyExtendedStyle
	jr __jrt_nop_F55EDB
__jrt_nop_F55EDB:

AccStyle_ApplyChanges_Finalize:
	calr AccBuf_InitKbd1WithMarkers
	ldda8 a, 1075
	stda8 1112, a
	stdi8 13036, 1
	call Rhythm_ProcessAllPartsAndLoad
	ret

AccStyle_ResetAllVoiceState:
	xor wa, wa
	stda8 1045, a
	stda8 1046, a
	stda8 12927, a
	stda8 12928, a
	stda16 12925, xwa
	stda8 13096, a
	stda8 12971, a
	stda8 12972, a
	stda8 12977, a
	stda8 12973, a
	stda8 12974, a
	stda8 12975, a
	stda8 12976, a
	stda8 1076, a
	stda8 1077, a
	stda8 12980, a
	stda8 12981, a
	stda8 12982, a
	stda8 12987, a
	stda8 12983, a
	stda8 12984, a
	stda8 12985, a
	stda8 12986, a
	stda8 13133, a
	stda8 12989, a
	stda8 12990, a
	stda8 12991, a
	stda8 12992, a
	stda8 12993, a
	stda8 12994, a
	stda8 13189, a
	stda8 13190, a
	stda8 13191, a
	stda8 13192, a
	stda8 13193, a
	stda8 13194, a
	call AccTone_CallWithSaveAll
	ret

AccStyle_ApplyStandardStyle:
	ldda8 a, 13061
	and a, 0x3
	stda8 13112, a
	stda8 13114, a
	ldda8 a, 13029
	ldda8 h, 13030
	call AccVoice_LookupWithOffset
	stda32 13006, xiy
	call AccVoice_SelectAndApplyPatch
	call AccVoice_ReadBankAssign
	ldda32 xiy, 13006
	call Rhythm_UpdateTuningConfig
	ldda32 xiy, 13006
	ldda8 a, 13055
	and a, 0x7
	jr z, AccStyle_ApplyStd_LoadTuning
	calr AccVoice_SelectPartOffset
	jr AccStyle_ApplyStd_Return

AccStyle_ApplyStd_LoadTuning:
	calr AccStyle_SetupPartAddresses
	ldda8 a, 12963
	ldb w, 0x0
	calr AccPart_GetVoiceParamOffsetTable
	call AccVoice_LoadTuningBlock
	ordi8 13100, 63

AccStyle_ApplyStd_Return:
	ret

AccStyle_SetupPartAddresses:
	ld_srib A, (xiy + 0x03d1)
	stda8 12933, a
	stdi8 13268, 1
	ldda8 a, 12963
	calr AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	stda16 12935, xwa
	stdi8 13268, 2
	ldda8 a, 12964
	calr AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	stda16 12937, xwa
	stdi8 13268, 4
	ldda8 a, 12965
	calr AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	stda16 12939, xwa
	stdi8 13268, 8
	ldda8 a, 12966
	calr AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	stda16 12941, xwa
	stdi8 13268, 16
	ldda8 a, 12967
	calr AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	stda16 12943, xwa
	stdi8 13268, 32
	ldda8 a, 12968
	calr AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	stda16 12945, xwa
	ld xwa, 0xE46BB9
	add xwa, 0x6
	stda32 12947, xwa
	anddi8 13078, 192
	anddi8 13079, 192
	anddi8 13080, 192
	ret

AccStyle_ApplyExtendedStyle:
	ld xiy, 0xE46BF9
	ldda8 a, 13029
	and a, 0x7F
	cp a, 0x1D
	jr ule, AccStyle_ApplyExt_ClampIndex
	xor a, a

AccStyle_ApplyExt_ClampIndex:
	ld_srib3 A, 0x03, 0xF4, 0xE0
	stda8 13112, a
	ldda8 a, 13029
	and a, 0x7F
	call AccVoice_ResolveParamAddr
	stda32 13006, xiy
	ld l, (xiy + 16)
	ld h, (xiy + 17)
	and h, 0xF
	and h, 0x7
	cp hl, 0x208
	jr z, AccStyle_ApplyExt_SkipClamp
	cp hl, 0x318
	jr z, AccStyle_ApplyExt_SkipClamp
	call VoiceParam_ClampAndValidate

AccStyle_ApplyExt_SkipClamp:
	ld a, l
	call AccVoice_LookupWithOffset
	stda32 13011, xiy
	call AccVoice_SelectAndApplyPatch
	ldda8 w, 13029
	call AccPatch_SetByChordIndex
	bitda 0, 13155
	jr nz, AccStyle_ApplyExt_CheckSplit
	call AccPedal_ProcessAllChanges

AccStyle_ApplyExt_CheckSplit:
	ldda8 a, 13055
	and a, 0x7
	jrl z, Seq_ProcessAndContinue
	bitda 0, 13155
	jrl z, AccStyle_ApplyExt_SelectPart
	bitda 1, 13055
	jr z, AccStyle_ApplyExt_CheckBit0
	ldda8 a, 1075
	ld xhl, 0xE46BB0
	bit_dri 0, 0x03, 0xEC, 0xE0
	jr z, AccStyle_ApplyExt_SelectPart
	anddi8 13055, 253
	anddi8 64607, 247
	ldb e, 0x48
	ldb d, 0x5
	ldb a, 0x0
	ldb w, 0x0
	call Rhythm_QueuePartChangeEvent
	jr Seq_ProcessAndContinue

AccStyle_ApplyExt_CheckBit0:
	bitda 0, 13055
	jr z, AccStyle_ApplyExt_CheckBit1
	ldda8 a, 13156
	cpda8 a, 1075
	jr z, AccStyle_ApplyExt_UseSecondary
	anddi8 13055, 254
	anddi8 64607, 251
	ldb e, 0x48
	ldb d, 0x5
	ldb a, 0x0
	ldb w, 0x0
	call Rhythm_QueuePartChangeEvent
	jr Seq_ProcessAndContinue

AccStyle_ApplyExt_CheckBit1:
	ldda8 a, 13158
	cpda8 a, 1075
	jr z, AccStyle_ApplyExt_UseSecondary
	anddi8 13055, 251
	anddi8 64608, 251
	ldb e, 0x48
	ldb d, 0x5
	ldb a, 0x0
	ldb w, 0x0
	call Rhythm_QueuePartChangeEvent
	jr Seq_ProcessAndContinue

AccStyle_ApplyExt_UseSecondary:
	calr AccStyle_UseSecondarySource
	jr AccStyle_ApplyExt_UpdateTuning


; -----------------------------------------------------------------------------
; Section: Sequence Processing & Voice Selection
; -----------------------------------------------------------------------------
; Sequence continuation and accompaniment voice
; part offset selection.
; -----------------------------------------------------------------------------

Seq_ProcessAndContinue:
	calr AccPart_ResetAndCopyTuning
	jr AccStyle_ApplyExt_UpdateTuning

AccStyle_ApplyExt_SelectPart:
	ldda32 xiy, 13011
	calr AccVoice_SelectPartOffset

AccStyle_ApplyExt_UpdateTuning:
	ldda32 xiy, 13011
	calr Rhythm_UpdateTuningConfig
	ret

AccVoice_SelectPartOffset:
	ldw hl, 0x20
	bitda 0, 13055
	jr nz, AccVoice_SelectPartOffset_Resolved
	ldw hl, 0x22
	bitda 1, 13055
	jr nz, AccVoice_SelectPartOffset_Resolved
	ldw hl, 0x420

AccVoice_SelectPartOffset_Resolved:
	calr AccStyle_SetupPartAddressesByHL
	cpdi8 13029, 128
	jr c, AccVoice_SelectPartOffset_Bound
	ldda32 xiy, 13006
	call AccTuning_CopyAllPartsFromStyle
	jr AccVoice_SelectPartOffset_Apply63

AccVoice_SelectPartOffset_Bound:
	ldda8 a, 12963
	ldb w, 0x3
	bitda 2, 13055
	jr z, AccVoice_SelectPartOffset_SetModeW
	ldb w, 0x4

AccVoice_SelectPartOffset_SetModeW:
	calr AccPart_GetVoiceParamOffsetTable
	call AccVoice_LoadTuningBlock

AccVoice_SelectPartOffset_Apply63:
	ordi8 13100, 63
	bitda 0, 13055
	jr z, AccVoice_SelectPartOffset_Bit1
	ordi8 13078, 63
	anddi8 13079, 192
	anddi8 13080, 192
	jr AccVoice_SelectPartOffset_Return

AccVoice_SelectPartOffset_Bit1:
	bitda 1, 13055
	jr z, AccVoice_SelectPartOffset_Mode3
	anddi8 13078, 192
	ordi8 13079, 63
	anddi8 13080, 192
	jr AccVoice_SelectPartOffset_Return

AccVoice_SelectPartOffset_Mode3:
	anddi8 13078, 192
	anddi8 13079, 192
	ordi8 13080, 63

AccVoice_SelectPartOffset_Return:
	ret

AccStyle_SetupPartAddressesByHL:
	ld_srib A, (xiy + 0x03d1)
	stda8 12933, a
	ldfr_werp HL, 0x3C
	stdi8 13268, 1
	call AccPart_GetParamAddr
	stda16 12935, xwa
	ldto_werp HL, 0x3C
	stdi8 13268, 2
	call AccPart_GetParamAddr
	stda16 12937, xwa
	ldto_werp HL, 0x3C
	stdi8 13268, 4
	call AccPart_GetParamAddr
	stda16 12939, xwa
	ldto_werp HL, 0x3C
	stdi8 13268, 8
	call AccPart_GetParamAddr
	stda16 12941, xwa
	ldto_werp HL, 0x3C
	stdi8 13268, 16
	call AccPart_GetParamAddr
	stda16 12943, xwa
	ldto_werp HL, 0x3C
	stdi8 13268, 32
	call AccPart_GetParamAddr
	stda16 12945, xwa
	ld xwa, 0xE46BB9
	add xwa, 0x6
	stda32 12947, xwa
	ret

AccStyle_UseSecondarySource:
	ldda8 a, 13157
	bitda 0, 13055
	jr nz, AccStyle_UseSecondary_Resolve
	ldda8 a, 13159

AccStyle_UseSecondary_Resolve:
	call AccVoice_ResolveParamAddr
	calr AccPart_InitPositionsAndBase
	call AccTuning_CopyAllPartsFromStyle
	ordi8 13100, 63
	bitda 0, 13055
	jr z, AccStyle_UseSecondary_Mode3
	ordi8 13078, 63
	anddi8 13079, 192
	anddi8 13080, 192
	jr AccStyle_UseSecondary_Return

AccStyle_UseSecondary_Mode3:
	anddi8 13078, 192
	anddi8 13079, 192
	ordi8 13080, 63

AccStyle_UseSecondary_Return:
	ret


; -----------------------------------------------------------------------------
; Section: Accompaniment Part Management
; -----------------------------------------------------------------------------
; Part position initialization, buffer reset, tuning
; configuration, and style index lookup.
; -----------------------------------------------------------------------------

AccPart_InitPositionsAndBase:
	call AccInit_AllPartPositions
	ld xwa, 0xE46BB9
	add xwa, 0x6
	stda32 12947, xwa
	ret

AccPart_ResetAndCopyTuning:
	ldda32 xiy, 13006
	calr AccPart_InitPositionsAndBase
	call AccTuning_CopyAllPartsFromStyle
	ordi8 13100, 63
	anddi8 13078, 192
	anddi8 13079, 192
	anddi8 13080, 192
	ret

AccBuf_ResetAllPositions:
	ld xhl, 0x2A94
	call AccBuf_ResetOnePosition
	ld xhl, 0x2B94
	call AccBuf_ResetOnePosition
	ld xhl, 0x2C94
	call AccBuf_ResetOnePosition
	ld xhl, 0x2D94
	call AccBuf_ResetOnePosition
	ld xhl, 0x2E94
	call AccBuf_ResetOnePosition
	ld xhl, 0x2F94
	call AccBuf_ResetOnePosition
	ret

AccBuf_InitKbd1WithMarkers:
	ld xhl, 0x2A94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	stib_dri 0x07, 0xEC, 0xF4, 0xD0
	call RingBuf_AdvanceIndex
	stib_dri 0x07, 0xEC, 0xF4, 0x01
	call RingBuf_AdvanceIndex
	stib_dri 0x07, 0xEC, 0xF4, 0x10
	call RingBuf_AdvanceIndex
	stib_dri 0x07, 0xEC, 0xF4, 0x01
	call RingBuf_AdvanceIndex
	ld (xhl + 4), iy
	ret

Rhythm_SendResetMsg:
	ldb a, 0xD8
	ldb w, 0x10
	ldb e, 0x0
	call Rhythm_Send3ByteMsg
	ret

Rhythm_UpdateTuningConfig:
	ldda8 w, 13016
	ldda8 a, 13112
	calr Rhythm_LookupTuningByStyle
	stda8 12963, a
	stda8 12964, a
	stda8 12965, a
	stda8 12966, a
	stda8 12967, a
	stda8 12968, a
	ldda8 w, 13016
	ldda8 a, 13112
	calr Rhythm_LookupTuningRange
	ret

Rhythm_LookupTuningByStyle:
	calr Rhythm_LookupStyleIndex
	calr AccVoice_LookupParamIndex
	ld xhl, 0xF5646E
	ld_srib3 A, 0x03, 0xEC, 0xE0
	ret

Rhythm_LookupTuningRange:
	cpdi8 13029, 128
	jr nc, Rhythm_LookupTuning_DefaultRange
	calr Rhythm_LookupStyleIndex
	calr AccVoice_LookupParamIndex
	ld xhl, 0xF56476
	sla a, 1
	ld_sriw3 HL, 0x03, 0xEC, 0xE0
	ld_sriw3 WA, 0x07, 0xF4, 0xEC
	jr Rhythm_StoreTuningRange

Rhythm_LookupTuning_DefaultRange:
	ldb a, 0x39
	ldb w, 0x39

Rhythm_StoreTuningRange:
	stda8 13119, a
	stda8 13120, w
	ret

Rhythm_LookupStyleIndex:
	ld xhl, 0xF56439
	cp w, 0x30
	jr c, Rhythm_LookupStyleIndex_Compute
	xor w, w

Rhythm_LookupStyleIndex_Compute:
	ld_srib3 W, 0x03, 0xEC, 0xE1
	and w, 0x3
	ld xhl, 0xF5646A
	ld_srib3 L, 0x03, 0xEC, 0xE1
	xor h, h
	ret

AccVoice_LookupParamIndex:
	push xhl
	ld xhl, 0xF56413
	and wa, 0x3
	ld_srib3 A, 0x07, 0xEC, 0xE0
	pop xhl
	ret

AccVoice_ParamIndexData:
	nop
	pop_sr
	.byte 0x04
	reti
	add	hl, 994
	extz	wa
	.byte 0xd7, 0x30, 0x98
	add	hl, wa
	.byte 0xc3, 0x07, 0xf4, 0xec, 0x21
	cp	a, 255
	jr	nz, 12
	.byte 0xd7, 0x30, 0x88
	add	wa, 994
	.byte 0xc3, 0x07, 0xf4, 0xe0, 0x21
	ret
	nop
	nop
	.byte 0x01, 0x01
	nop
	push_sr
	.byte 0x01, 0x01
	push_sr
	.byte 0x01, 0x01, 0x01, 0x01
	nop
	.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
	push_sr
	.byte 0x01, 0x01
	nop
	.byte 0x01, 0x01, 0x01, 0x01, 0x01
	nop
	.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
	nop
	.byte 0x02
	.zero 8
	ldio	4, 12
	nop
	halt
	ldwio	15, 6420
	calr	-11741
	pop_sr
	.byte 0xd4, 0x03, 0xd6
	pop_sr
	ld	wa, 2002
	.byte 0xd4, 0x07, 0xd6
	reti
	neg	wa

AccPart_GetVoiceParamOffsetTable:
	ld xhl, 0xF564A6
	ldfr_berp W, 0x31
	extz wa
	sla wa, 2
	ld_sril3 XHL, 0x07, 0xEC, 0xE0
	ldto_berp W, 0x31
	sla w, 1
	ld_sriw3 HL, 0x03, 0xEC, 0xE1
	extz xhl
	ret

AccPart_VoiceParamDispatchTable:
	.long AccPart_VoiceParamOffsets_BaseA
	.long AccPart_VoiceParamOffsets_BaseA
	.long AccPart_VoiceParamOffsets_BaseA
	.long AccPart_VoiceParamOffsets_BaseA
	.long AccPart_VoiceParamOffsets_BaseA
	.long AccPart_VoiceParamOffsets_BaseA
	.long AccPart_VoiceParamOffsets_BaseA
	.long AccPart_VoiceParamOffsets_BaseA
	.long AccPart_VoiceParamOffsets_BaseA
	.long AccPart_VoiceParamOffsets_BaseA
	.long AccPart_VoiceParamOffsets_BaseA
	.long AccPart_VoiceParamOffsets_BaseA
	.long AccPart_VoiceParamOffsets_BaseA
	.long AccPart_VoiceParamOffsets_BaseA
	.long AccPart_VoiceParamOffsets_BaseA
	.long AccPart_VoiceParamOffsets_BaseB
	.long AccPart_VoiceParamOffsets_BaseB
	.long AccPart_VoiceParamOffsets_BaseB
	.long AccPart_VoiceParamOffsets_BaseB
	.long AccPart_VoiceParamOffsets_BaseB
	.long AccPart_VoiceParamOffsets_ChordA
	.long AccPart_VoiceParamOffsets_ChordA
	.long AccPart_VoiceParamOffsets_ChordA
	.long AccPart_VoiceParamOffsets_ChordA
	.long AccPart_VoiceParamOffsets_ChordA
	.long AccPart_VoiceParamOffsets_ChordA
	.long AccPart_VoiceParamOffsets_ChordA
	.long AccPart_VoiceParamOffsets_ChordA
	.long AccPart_VoiceParamOffsets_ChordA
	.long AccPart_VoiceParamOffsets_ChordA
	.long AccPart_VoiceParamOffsets_ChordA
	.long AccPart_VoiceParamOffsets_ChordA
	.long AccPart_VoiceParamOffsets_ChordA
	.long AccPart_VoiceParamOffsets_ChordA
	.long AccPart_VoiceParamOffsets_ChordA
	.long AccPart_VoiceParamOffsets_ChordB
	.long AccPart_VoiceParamOffsets_ChordB
	.long AccPart_VoiceParamOffsets_ChordB
	.long AccPart_VoiceParamOffsets_ChordB
	.long AccPart_VoiceParamOffsets_ChordB
AccPart_VoiceParamOffsets_BaseA:
	nop
	nop
	jr	le, 0
	.byte 0xc4, 0x00, 0x26, 0x01
	ldb	h, 5
	.byte 0x57, 0x01, 0x57
	halt
AccPart_VoiceParamOffsets_BaseB:
	ldw	bc, 37632
	nop
	.byte 0xf5, 0x00, 0x26, 0x01
	ldb	h, 5
	.byte 0x57, 0x01, 0x57
	halt
AccPart_VoiceParamOffsets_ChordA:
	nop
	.byte 0x04
	jr	le, 4
	.byte 0xc4, 0x04, 0x26, 0x01
	ldb	h, 5
	.byte 0x57, 0x01, 0x57
	halt
AccPart_VoiceParamOffsets_ChordB:
	ldw	bc, 37636
	.byte 0x04, 0xf5, 0x04, 0x26, 0x01
	ldb	h, 5
	.byte 0x57, 0x01, 0x57
	halt

AccPart_LookupBoundVoiceParam:
	ld w, a
	calr AccStyle_ReadParamOffset
	ld xhl, 0xF5669A
	cp a, 0x14
	jr c, AccPart_LookupBound_ComputeIdx
	ld xhl, 0xF566AA

AccPart_LookupBound_ComputeIdx:
	sla w, 1
	ld_sriw3 HL, 0x03, 0xEC, 0xE1
	ret

AccStyle_ReadParamOffset:
	ld xhl, 0xF5664A
	sla w, 1
	ld_sriw3 HL, 0x03, 0xEC, 0xE1
	extz xhl
	add xhl, xiy
	cpdi8 13268, 1
	jr nz, AccStyle_ReadParamOff_Part2
	ld w, (xhl + 256)
	jr AccStyle_ReadParamRet

AccStyle_ReadParamOff_Part2:
	cpdi8 13268, 2
	jr nz, AccStyle_ReadParamOff_Part4
	ld w, (xhl + 256)
	jr AccStyle_ReadParamRet

AccStyle_ReadParamOff_Part4:
	cpdi8 13268, 4
	jr nz, AccStyle_ReadParamOff_Part8
	ld w, (xhl + 40)
	jr AccStyle_ReadParamRet

AccStyle_ReadParamOff_Part8:
	cpdi8 13268, 8
	jr nz, AccStyle_ReadParamOff_Part16
	ld w, (xhl + 80)
	jr AccStyle_ReadParamRet

AccStyle_ReadParamOff_Part16:
	cpdi8 13268, 16
	jr nz, AccStyle_ReadParamOff_Part32
	ld w, (xhl + 120)
	jr AccStyle_ReadParamRet

AccStyle_ReadParamOff_Part32:
	ld_srib W, (xhl + 0x00a0)

AccStyle_ReadParamRet:
	ret

AccStyle_ByteDataBlock:
	ld	xhl, 16082506
	sla	a, 1
	.byte 0xd3, 0x03, 0xec, 0xe0, 0x23
	extz	xhl
	add	xhl, xiy
	cpdi8	13268, 1
	jr	nz, 5
	ld	a, (xhl+20)
	jr	62
	cpdi8	13268, 2
	jr	nz, 5
	ld	a, (xhl+20)
	jr	50
	cpdi8	13268, 4
	jr	nz, 5
	.byte 0x8b
	.ascii "<!h&ÁÔ3"
	push xsp
	.byte 0x08, 0x6e, 0x05
	ld	a, (xhl+100)
	.byte 0x68, 0x1a, 0xc1, 0xd4, 0x33, 0x3f, 0x10, 0x6e
	.byte 0x07
	ld	a, (xhl+140)
	.byte 0x68, 0x0c, 0xc1
	.byte 0xd4
	.ascii "3? n"
	.byte 0x05, 0xc3, 0xed
	.byte 0xb4, 0x00, 0x21, 0x0e, 0x00, 0x00, 0x01, 0x00
	.byte 0x02, 0x00, 0x03, 0x00, 0x04, 0x00, 0x05, 0x00
	.byte 0x06, 0x00, 0x07, 0x00, 0x08, 0x00, 0x09, 0x00
	.byte 0x0a, 0x00, 0x0b, 0x00, 0x0c, 0x00, 0x0d, 0x00
	.byte 0x0e, 0x00, 0x0f, 0x00, 0x10, 0x00, 0x11, 0x00
	.byte 0x12, 0x00, 0x13, 0x00, 0x00, 0x04, 0x01, 0x04
	.byte 0x02, 0x04, 0x03, 0x04, 0x04, 0x04, 0x05, 0x04
	.byte 0x06, 0x04, 0x07, 0x04, 0x08, 0x04, 0x09, 0x04
	.byte 0x0a, 0x04, 0x0b, 0x04, 0x0c, 0x04, 0x0d, 0x04
	.byte 0x0e, 0x04, 0x0f, 0x04, 0x10, 0x04, 0x11, 0x04
	.byte 0x12, 0x04, 0x13, 0x04, 0x00, 0x00, 0x02, 0x00
	.byte 0x04, 0x00, 0x06, 0x00, 0x08, 0x00, 0x0a, 0x00
	.byte 0x0c, 0x00, 0x0e, 0x00, 0x00, 0x04, 0x02, 0x04
	.byte 0x04, 0x04, 0x06, 0x04, 0x08, 0x04, 0x0a, 0x04
	.byte 0x0c, 0x04, 0x0e, 0x04

AccVoice_ComputeParamAddr:
	cp a, 0xF
	jr nc, AccVoice_ParamAddr_Range0F_14
	ldw hl, 0x18
	bitda 0, 13065
	jr nz, AccVoice_ReturnExtHL
	ldw hl, 0x1A
	jr AccVoice_ReturnExtHL

AccVoice_ParamAddr_Range0F_14:
	cp a, 0x14
	jr nc, AccVoice_ParamAddr_Range14_23
	ldw hl, 0x1C
	bitda 0, 13065
	jr nz, AccVoice_ReturnExtHL
	ldw hl, 0x1E
	jr AccVoice_ReturnExtHL

AccVoice_ParamAddr_Range14_23:
	cp a, 0x23
	jr nc, AccVoice_ParamAddr_Range23Plus
	ldw hl, 0x418
	bitda 0, 13065
	jr nz, AccVoice_ReturnExtHL
	ldw hl, 0x41A
	jr AccVoice_ReturnExtHL

AccVoice_ParamAddr_Range23Plus:
	ldw hl, 0x41C
	bitda 0, 13065
	jr nz, AccVoice_ReturnExtHL
	ldw hl, 0x41E

AccVoice_ReturnExtHL:
	extz xhl
	ret

AccTuning_SetAllFromLookup:
	calr AccTuning_FetchValue
	stda8 12963, a
	stda8 12964, a
	stda8 12965, a
	stda8 12966, a
	stda8 12967, a
	stda8 12968, a
	ret

AccTuning_FetchValue:
	ld xhl, 0xF56729
	ld_srib3 A, 0x03, 0xEC, 0xE0
	ret

AccTuning_ValueTable:
	nop
	nop
	nop
	nop
	nop
	halt
	halt
	halt
	halt
	halt
	ldwio	10, 2570
	ldwio	15, 3855
	retd	0x140f
	push_a
	push_a
	push_a
	push_a
	pop_f
	pop_f
	pop_f
	pop_f
	pop_f
	.byte 0x1e, 0x1e
	calr	0x1e1e
	.ascii "#####"

AccVoice_ProcessAllSixParts:
	calr AccVoice_SavePartState1
	calr AccVoice_ProcessEventLoop
	calr AccVoice_RestorePartState1
	ret

AccVoice_SavePartState1:
	anddi8 13044, 252
	stdi8 13037, 0
	ldb a, 0x1
	stda8 13268, a
	ldda16 xwa, 12951
	stda16 13270, xwa
	ldda16 xwa, 12935
	stda16 13272, xwa
	ldda8 a, 12981
	stda8 13274, a
	ldda8 a, 12971
	stda8 13275, a
	ldda8 a, 12963
	stda8 13269, a
	ldda8 a, 13291
	stda8 13290, a
	ret

AccVoice_RestorePartState1:
	ldda16 xwa, 13270
	stda16 12951, xwa
	ldda16 xwa, 13272
	stda16 12935, xwa
	ldda8 a, 13274
	stda8 12981, a
	ldda8 a, 13275
	stda8 12971, a
	ldda8 a, 13269
	stda8 12963, a
	ldda8 a, 13290
	stda8 13291, a
	ret


; -----------------------------------------------------------------------------
; Section: Voice Event Processing
; -----------------------------------------------------------------------------
; Per-voice event loop, event dispatch, and
; sound patch handling.
; -----------------------------------------------------------------------------

AccVoice_ProcessEventLoop:
	bitda 0, 13044
	jr z, AccVoice_EventLoop_Active
	jr AccVoice_EventLoop_Idle

AccVoice_EventLoop_Active:
	calr AccVoice_DispatchByChannel
	bitda 0, 13044
	jr z, AccVoice_EventLoop_Dispatch
	jr AccVoice_EventProcessingReturn

AccVoice_EventLoop_Dispatch:
	ldda8 w, 13268
	ldda16 xiz, 13270
	call AccVoice_SelectByMask
	ldda16 xiy, 13272
	ld_srib3 A, 0x07, 0xEC, 0xF4
	cp a, 0x83
	jr nz, AccVoice_EventLoop_Check81
	calr AccVoice_HandleMarker83
	jr AccVoice_EventProcessingReturn

AccVoice_EventLoop_Check81:
	cp a, 0x81
	jr nz, AccVoice_EventLoop_CheckNoteOn
	calr AccVoice_HandleBarEndEvent
	jr AccVoice_EventProcessingReturn

AccVoice_EventLoop_CheckNoteOn:
	cp a, 0x90
	jr z, AccVoice_HandleEvent_D5
	cp a, 0x91
	jr z, AccVoice_HandleEvent_D5
	cp a, 0xD1
	jr z, AccVoice_HandleEvent_D5
	cp a, 0xD2
	jr z, AccVoice_HandleEvent_D5
	cp a, 0xD3
	jr z, AccVoice_HandleEvent_D5
	cp a, 0xD4
	jr z, AccVoice_HandleEvent_D5
	cp a, 0xD5
	jr nz, AccVoice_EventLoop_Unknown

AccVoice_HandleEvent_D5:
	calr AccVoice_HandleNoteOnEvent
	jr AccVoice_EventProcessingReturn

AccVoice_EventLoop_Unknown:
	calr AccVoice_AdvanceAndCheckEnd

AccVoice_EventProcessingReturn:
	jr AccVoice_ProcessEventLoop

AccVoice_EventLoop_Idle:
	ret

AccVoice_DispatchByChannel:
	cpdi8 13268, 1
	jr nz, AccVoice_DispatchCh_Kbd2
	bitda 0, 13100
	jr z, SoundPatch_NullRet
	calr AccKbd1_ProcessNotes
	jr SoundPatch_NullRet

AccVoice_DispatchCh_Kbd2:
	cpdi8 13268, 2
	jr nz, AccVoice_DispatchCh_Acc1
	bitda 1, 13100
	jr z, SoundPatch_NullRet
	calr AccKbd2_ProcessNotes
	jr SoundPatch_NullRet

AccVoice_DispatchCh_Acc1:
	cpdi8 13268, 4
	jr nz, AccVoice_DispatchCh_Acc2
	bitda 2, 13100
	jr z, SoundPatch_NullRet
	call AccCh1_ProcessNotes
	jr SoundPatch_NullRet

AccVoice_DispatchCh_Acc2:
	cpdi8 13268, 8
	jr nz, AccVoice_DispatchCh_Acc3
	bitda 3, 13100
	jr z, SoundPatch_NullRet
	call AccCh2_ProcessNotes
	jr SoundPatch_NullRet

AccVoice_DispatchCh_Acc3:
	cpdi8 13268, 16
	jr nz, AccVoice_DispatchCh_Acc4
	bitda 4, 13100
	jr z, SoundPatch_NullRet
	call AccCh3_ProcessNotes
	jr SoundPatch_NullRet

AccVoice_DispatchCh_Acc4:
	cpdi8 13268, 32
	jr nz, SoundPatch_NullRet
	bitda 5, 13100
	jr z, SoundPatch_NullRet
	call AccCh4_ProcessNotes
	jr __jrt_nop_F568A7
__jrt_nop_F568A7:

SoundPatch_NullRet:
	ret

AccVoice_AdvanceAndCheckEnd:
	calr AccBuf_AdvanceNoPage
	incdi8 1, 13037
	cpdi8 13037, 32
	jr nz, AccVoice_AdvanceAndCheck_Return
	call AccWrap_PlayModeDispatch
	call AccDemo_InitDone
	stdi8 13045, 255
	ordi8 13044, 33

AccVoice_AdvanceAndCheck_Return:
	ret

AccVoice_HandleNoteOnEvent:
	calr AccVoice_AdvanceWithSave
	ldda8 w, 13275
	calr AccVoice_LookupTableAddress
	ldda16 xbc, 12925
	ldda8 w, 13274
	calr AccTempo_PositionCompare
	cp a, 0x18
	jr ule, AccVoice_NoteOn_InRange
	ordi8 13044, 1
	jr AccVoice_NoteOn_Return

AccVoice_NoteOn_InRange:
	calr AccMidi_Dispatch

AccVoice_NoteOn_Return:
	ret

AccVoice_HandleBarEndEvent:
	bitda 1, 13044
	jr z, AccVoice_BarEnd_Process
	ordi8 13044, 1
	jrl AccVoice_NullRet

AccVoice_BarEnd_Process:
	ldda8 w, 13275
	calr AccVoice_LookupExtParamAddr
	ldda16 xbc, 12925
	ldda8 w, 13274
	calr AccTempo_PositionCompare
	cp a, 0x18
	jr ule, AccVoice_BarEnd_InRange
	ordi8 13044, 1
	jrl AccVoice_NullRet

AccVoice_BarEnd_InRange:
	ordi8 13044, 2
	ldda8 a, 13275
	inc 1, a
	ld w, a
	and a, 0xF
	cpda8 a, 1075
	jr z, AccVoice_BarEnd_NextPage
	stda8 13275, w
	calr AccBuf_AdvanceNoPage
	jrl AccVoice_NullRet

AccVoice_BarEnd_NextPage:
	and w, 0xF0
	add w, 0x10
	stda8 13275, w
	incdi8 1, 13274
	calr AccBuf_AdvanceNoPage
	call AccVoice_IncrementBarWithSave
	calr AccPart_Reactivate
	anddi8 13153, 251
	bitda 0, 13068
	jr nz, AccVoice_BarEnd_CheckChord94
	ldda8 a, 13067
	and a, 0x3
	jr z, AccVoice_BarEnd_CheckChord65

AccVoice_BarEnd_CheckChord94:
	ldda8 a, 13268
	andda8 a, 13094
	jr nz, AccVoice_SetChordChangeFlags

AccVoice_BarEnd_CheckChord65:
	ldda8 a, 13065
	and a, 0x3
	jr nz, AccVoice_BarEnd_CheckChord95
	ldda8 a, 13066
	and a, 0xD
	jr z, AccVoice_BarEnd_CheckSync69

AccVoice_BarEnd_CheckChord95:
	ldda8 a, 13268
	andda8 a, 13095
	jr nz, AccVoice_SetChordChangeFlags

AccVoice_BarEnd_CheckSync69:
	bitda 0, 13069
	jr nz, AccVoice_SetChordChangeFlags
	ldda8 a, 13148
	and a, 0x3F
	jr z, AccVoice_NullRet
	bitda 7, 13153
	jr nz, AccVoice_SetChordChangeFlags
	jr AccVoice_NullRet


; -----------------------------------------------------------------------------
; Section: Chord, Table & Address Lookup
; -----------------------------------------------------------------------------
; Chord change flags, voice table address lookup,
; and buffer advance routines.
; -----------------------------------------------------------------------------

AccVoice_SetChordChangeFlags:
	ordi8 13043, 128
	ordi8 13044, 1
	ldda8 a, 13074
	orda8 a, 13075
	and a, 0x3F
	jr z, AccVoice_NullRet
	bitda 0, 13057
	jr z, AccVoice_NullRet
	anddi8 13070, 252
	ordi8 13070, 1
	ldda8 a, 13268
	andda8 a, 13074
	jr z, AccVoice_NullRet
	ordi8 13070, 2

AccVoice_NullRet:
	ret

AccVoice_LookupTableAddress:
	ld xde, 0xE46B9E
	and w, 0x7
	sla w, 1
	ld_sriw3 DE, 0x03, 0xE8, 0xE1
	xor w, w
	add de, wa
	ret

AccVoice_LookupExtParamAddr:
	ld xde, 0xE46B9E
	and w, 0x7
	inc 1, w
	sla w, 1
	ld_sriw3 DE, 0x03, 0xE8, 0xE1
	ret

AccVoice_AdvanceWithSave:
	ldda16 xiy, 13272
	ldda16 xiz, 13270
	call AccBuf_AdvanceWithPageTurn
	ret

AccBuf_AdvanceNoPage:
	ldda16 xiy, 13272
	ldda16 xiz, 13270
	call AccBuf_Advance
	stda16 13270, xiz
	stda16 13272, xiy
	ret

AccVoice_HandleMarker83:
	ldda8 w, 13268
	ldda8 a, 13076
	orda8 a, 13077
	and w, a
	jr nz, AccVoice_Marker83_Activate
	ldda8 a, 13268
	andda8 a, 13096
	jr z, AccVoice_Marker83_CheckDeact

AccVoice_Marker83_Activate:
	calr AccVoice_ActivatePart
	jr AccVoice_Marker83_Return

AccVoice_Marker83_CheckDeact:
	calr AccPart_CheckAnyActive
	andda8 a, 13268
	jr z, AccVoice_Marker83_NextPart
	calr AccPart_Deactivate
	jr AccVoice_Marker83_Return

AccVoice_Marker83_NextPart:
	calr AccPart_AdvanceAndResolve

AccVoice_Marker83_Return:
	ret

AccVoice_ActivatePart:
	ldda8 a, 13268
	orddm8 13098, a
	orddm8 13096, a
	ordi8 13044, 1
	ldda8 a, 13098
	and a, 0x3F
	cp a, 0x3F
	jr nz, AccVoice_ActivatePart_Return
	ordi8 12931, 4
	anddi8 13098, 192

AccVoice_ActivatePart_Return:
	ret

AccVoice_ActivateByteData:
	ldda8	a, 13424
	and	a, 192
	jr	nz, 10
	ldda8	a, 13268
	andda8	a, 13097
	jr	z, 16
	calr	278
	ldda8	a, 13268
	xor	a, 255
	anddm8	13097, a
	jr	104
	ldda8	a, 13078
	orda8	a, 13079
	orda8	a, 13080
	andda8	a, 13268
	jr	nz, 43
	.byte 0xf1, 0x01, 0x33, 0xc8
	jr	z, 37
	.byte 0xc1, 0x0e, 0x33, 0x3c, 0xfc, 0xc1, 0x0e, 0x33, 0x3e, 0x01
	ldda8	a, 13268
	andda8	a, 13074
	jr	z, 5
	.byte 0xc1, 0x0e, 0x33, 0x3e, 0x02, 0xc1, 0xf3, 0x32, 0x3e, 0x80, 0xc1, 0xf4, 0x32, 0x3e, 0x01
	jr	6
	calr	46
	calr	102
	ldda8	a, 13268
	xor	a, 255
	anddm8	13074, a
	anddm8	13075, a
	anddm8	13078, a
	anddm8	13079, a
	anddm8	13080, a
	stdi8	13275, 0
	stdi8	13290, 0
	ret
	.byte 0xc1, 0xf4, 0x32, 0x3e, 0x01

AccPart_SelectSourceOrParam:
	cpdi8 13029, 128
	jr c, AccPart_SelectSource_Param
	calr AccPart_SelectSource
	jr AccPart_SelectSource_Done

AccPart_SelectSource_Param:
	calr AccPart_LoadParamOffsetTable

AccPart_SelectSource_Done:
	ldda8 w, 13268
	ret

AccPart_AdvanceAndResolve:
	calr AccPart_IncrementIndex
	ldda8 a, 13268
	andda8 a, 13149
	jr z, AccPart_AdvanceResolve_Done
	call AccVoice_InitPerChannel
	calr AccPart_LoadParamOffsetTable
	ldda8 a, 13268
	xor a, 0xFF
	anddm8 13149, a
	call AccVoice_AssignPerPart

AccPart_AdvanceResolve_Done:
	calr AccPart_ResolveStyleAddr
	ret

AccPart_ResolveStyleAddr:
	cpdi8 13029, 128
	jr c, AccPart_ResolveStyle_Bound
	ldda8 a, 13029
	and a, 0x7F
	call AccVoice_ResolveParamAddr
	calr AccPart_GetFreeVoiceAddr
	stda16 13270, xwa
	stdi16 13272, 6
	jr AccPart_ResolveStyle_Return

AccPart_ResolveStyle_Bound:
	ldda32 xiy, 13006
	ldda8 a, 13269
	call AccPart_LookupBoundVoiceParam
	calr AccPart_GetParamAddr
	stda16 13272, xwa

AccPart_ResolveStyle_Return:
	ret

AccPart_IncrementIndex:
	cpdi8 13029, 128
	jr nc, AccPart_IncrementIndex_Return
	ldda32 xiy, 13006
	incdi8 1, 13269
	xor xhl, xhl
	ldda8 w, 13269
	call AccStyle_ReadParamOffset
	cp w, 0x83
	jr nz, AccPart_IncrementIndex_Return
	ldda8 a, 13269
	call AccTuning_FetchValue
	stda8 13269, a

AccPart_IncrementIndex_Return:
	ret

AccPart_ResolveWithPedal:
	cpdi8 13029, 128
	jr c, AccPart_ResolveWithPedal_Bound
	bitda 0, 13155
	jr nz, AccPart_ResolveWithPedal_DirB
	calr AccPedal_DirectionA
	ldda32 xiy, 13011
	calr AccPart_GetParamAddr
	stda16 13272, xwa
	jr AccPart_ResolveWithPedal_Return

AccPart_ResolveWithPedal_DirB:
	ldda8 w, 13268
	calr AccPedal_DirectionB
	call AccVoice_ResolveParamAddr
	calr AccPart_GetFreeVoiceAddr
	stda16 13270, xwa
	stdi16 13272, 6
	jr AccPart_ResolveWithPedal_Return

AccPart_ResolveWithPedal_Bound:
	calr AccPedal_DirectionA
	ldda32 xiy, 13006
	calr AccPart_GetParamAddr
	stda16 13272, xwa

AccPart_ResolveWithPedal_Return:
	ret

AccPart_LoadParamOffsetTable:
	ldda32 xiy, 13006
	ldda8 a, 13269
	ldb w, 0x0
	call AccPart_GetVoiceParamOffsetTable
	calr AccPart_LoadTuningByChannel
	ret

AccPart_LoadTuningByChannel:
	cpdi8 13268, 1
	jr nz, AccPart_LoadTuning_Kbd2
	call AccTuning_LoadAndApplyMaster
	ordi8 13100, 1
	jr AccPart_NullRet

AccPart_LoadTuning_Kbd2:
	cpdi8 13268, 2
	jr nz, AccPart_LoadTuning_Acc1
	call AccTuning_LoadAndApplyMaster
	ordi8 13100, 2
	jr AccPart_NullRet

AccPart_LoadTuning_Acc1:
	cpdi8 13268, 4
	jr nz, AccPart_LoadTuning_Acc2
	call AccTuning_LoadCoarseFromStyle
	ordi8 13100, 4
	jr AccPart_NullRet

AccPart_LoadTuning_Acc2:
	cpdi8 13268, 8
	jr nz, AccPart_LoadTuning_Acc3
	call AccTuning_LoadFineFromStyle
	ordi8 13100, 8
	jr AccPart_NullRet

AccPart_LoadTuning_Acc3:
	cpdi8 13268, 16
	jr nz, AccPart_LoadTuning_Acc4
	call AccTuning_LoadOctaveFromStyle
	ordi8 13100, 16
	jr AccPart_NullRet

AccPart_LoadTuning_Acc4:
	cpdi8 13268, 32
	jr nz, AccPart_NullRet
	call AccTuning_LoadTransposeFromStyle
	ordi8 13100, 32

AccPart_NullRet:
	ret

AccPart_GetFreeVoiceAddr:
	ldda8 a, 13268
	xor a, 0xFF
	anddm8 13280, a
	cpdi8 13268, 1
	jr nz, AccPart_FreeAddr_Kbd2
	ld wa, (xiy + 256)
	jr AccPart_CheckEndOfDataMarker

AccPart_FreeAddr_Kbd2:
	cpdi8 13268, 2
	jr nz, AccPart_FreeAddr_Acc1
	ldw wa, 0xFFFE
	jr AccPart_CheckEndOfDataMarker

AccPart_FreeAddr_Acc1:
	cpdi8 13268, 4
	jr nz, AccPart_FreeAddr_Acc2
	ld wa, (xiy + 4)
	jr AccPart_CheckEndOfDataMarker

AccPart_FreeAddr_Acc2:
	cpdi8 13268, 8
	jr nz, AccPart_FreeAddr_Acc3
	ld wa, (xiy + 6)
	jr AccPart_CheckEndOfDataMarker

AccPart_FreeAddr_Acc3:
	cpdi8 13268, 16
	jr nz, AccPart_FreeAddr_Acc4
	ld wa, (xiy + 8)
	jr AccPart_CheckEndOfDataMarker

AccPart_FreeAddr_Acc4:
	cpdi8 13268, 32
	jr nz, AccPart_CheckEndOfDataMarker
	ld wa, (xiy + 10)

AccPart_CheckEndOfDataMarker:
	cp wa, 0xFFFE
	jr nz, AccPart_FreeAddr_Return
	ldda8 a, 13268
	orddm8 13280, a
	ldw wa, 0xFFFE

AccPart_FreeAddr_Return:
	ret

; ============================================================================
; AccPart_GetParamAddr - Get parameter address for accompaniment part
; ============================================================================
; Input:  HL = base pointer, channel selector bitmask at 13268
; Output: WA = parameter address for the selected part
; Adds per-part offset (0x118-0x1D6) based on channel (kbd/acc1-5).
; ============================================================================
AccPart_GetParamAddr:
	ldda8 a, 13268
	xor a, 0xFF
	anddm8 13280, a
	cpdi8 13268, 1
	jr nz, AccPart_ParamAddr_Kbd2
	add hl, 0x118
	ld_sriw3 WA, 0x07, 0xF4, 0xEC
	jr AccPart_SubtractBaseAddr

AccPart_ParamAddr_Kbd2:
	cpdi8 13268, 2
	jr nz, AccPart_ParamAddr_Acc1
	add hl, 0x13E
	ld_sriw3 WA, 0x07, 0xF4, 0xEC
	jr AccPart_SubtractBaseAddr

AccPart_ParamAddr_Acc1:
	cpdi8 13268, 4
	jr nz, AccPart_ParamAddr_Acc2
	add hl, 0x164
	ld_sriw3 WA, 0x07, 0xF4, 0xEC
	jr AccPart_SubtractBaseAddr

AccPart_ParamAddr_Acc2:
	cpdi8 13268, 8
	jr nz, AccPart_ParamAddr_Acc3
	add hl, 0x18A
	ld_sriw3 WA, 0x07, 0xF4, 0xEC
	jr AccPart_SubtractBaseAddr

AccPart_ParamAddr_Acc3:
	cpdi8 13268, 16
	jr nz, AccPart_ParamAddr_Acc4
	add hl, 0x1B0
	ld_sriw3 WA, 0x07, 0xF4, 0xEC
	jr AccPart_SubtractBaseAddr

AccPart_ParamAddr_Acc4:
	cpdi8 13268, 32
	jr nz, AccPart_SubtractBaseAddr
	add hl, 0x1D6
	ld_sriw3 WA, 0x07, 0xF4, 0xEC
	jr __jrt_nop_F56D47
__jrt_nop_F56D47:

AccPart_SubtractBaseAddr:
	sub wa, 0x8000
	add wa, 0x6
	ret

AccPart_SelectSource:
	ldda32 xiy, 13006
	cpdi8 13268, 1
	jr z, AccPart_SelectKbd
	cpdi8 13268, 2
	jr nz, AccPart_CheckAcc1

AccPart_SelectKbd:
	add xiy, 0x18
	ld xix, 0x3246
	jr AccPart_CopyData

AccPart_CheckAcc1:
	cpdi8 13268, 4
	jr nz, AccPart_CheckAcc2
	add xiy, 0x20
	ld xix, 0x324D
	jr AccPart_CopyData

AccPart_CheckAcc2:
	cpdi8 13268, 8
	jr nz, AccPart_CheckAcc3
	add xiy, 0x28
	ld xix, 0x3254
	jr AccPart_CopyData

AccPart_CheckAcc3:
	cpdi8 13268, 16
	jr nz, AccPart_CheckAcc4
	add xiy, 0x30
	ld xix, 0x325B
	jr AccPart_CopyData

AccPart_CheckAcc4:
	cpdi8 13268, 32
	jr nz, AccPart_CheckAcc4
	add xiy, 0x38
	ld xix, 0x3262

AccPart_CopyData:
	lds bc, 7
	ldir85
	ldda8 a, 13268
	orddm8 13100, a
	ret

AccPart_CheckAnyActive:
	ldda8 a, 13078
	orda8 a, 13079
	orda8 a, 13080
	orda8 a, 13074
	orda8 a, 13075
	ret


; -----------------------------------------------------------------------------
; Section: Pedal Direction & MIDI Dispatch
; -----------------------------------------------------------------------------
; Pedal direction control (forward/reverse/alternate)
; and accompaniment MIDI event dispatch.
; -----------------------------------------------------------------------------

AccPedal_DirectionA:
	ldda8 a, 13424
	and a, 0xC0
	jr z, AccPedal_DirA_CheckBit1
	bitda 7, 13424
	jr z, AccPedal_DirA_SetForward
	bitda 6, 13424
	jr z, AccPedal_DirA_SetReverse

AccPedal_DirA_CheckBit1:
	bitda 1, 13051
	jr nz, AccPedal_DirA_SetReverse

AccPedal_DirA_SetForward:
	ordi8 13065, 1
	jr AccPedal_DirA_Apply

AccPedal_DirA_SetReverse:
	ordi8 13065, 2

AccPedal_DirA_Apply:
	ldda8 a, 13269
	call AccVoice_ComputeParamAddr
	anddi8 13065, 252
	ret

AccPedal_DirectionB:
	ldda8 a, 13424
	and a, 0xC0
	jr z, AccPedal_DirB_CheckBit0
	bitda 7, 13424
	jr z, AccPedal_DirB_Alternate
	bitda 6, 13424
	jr z, AccPedal_DirB_InvertAndStore

AccPedal_DirB_CheckBit0:
	bitda 0, 13051
	jr nz, AccPedal_DirB_Alternate

AccPedal_DirB_InvertAndStore:
	ld a, w
	xor w, 0xFF
	anddm8 13074, w
	ldda8 w, 1075
	cpda8 w, 13162
	jr nz, AccPedal_DirB_DefaultStyle
	orddm8 13075, a
	ldda8 a, 13163
	jr AccPedal_DirB_Return

AccPedal_DirB_Alternate:
	ld a, w
	xor w, 0xFF
	anddm8 13075, w
	ldda8 w, 1075
	cpda8 w, 13160
	jr nz, AccPedal_DirB_DefaultStyle
	orddm8 13074, a
	ldda8 a, 13161
	jr AccPedal_DirB_Return

AccPedal_DirB_DefaultStyle:
	ldda8 a, 13029
	and a, 0x7F

AccPedal_DirB_Return:
	ret

AccMidi_Dispatch:
	calr AccMidi_NormalizeVelocity
	cp a, 0x90
	jr z, AccMidi_NoteEvent
	cp a, 0x91
	jr z, AccMidi_NoteEvent
	cp a, 0xD1
	jr z, AccMidi_ControlEvent
	cp a, 0xD2
	jr z, AccMidi_ControlEvent
	cp a, 0xD3
	jr z, AccMidi_ControlEvent
	cp a, 0xD4
	jr z, AccMidi_ControlEvent
	cp a, 0xD5
	jr z, AccMidi_ControlEvent

AccMidi_NoteEvent:
	calr AccMidi_ParseNoteOn
	calr AccMidi_SelectVelocitySource
	calr AccMidi_DispatchPerPart
	jr AccMidi_DispatchReturn

AccMidi_ControlEvent:
	call AccMidi_ParseDType
	calr AccMidi_SelectVelocitySource
	call AccMidi_DispatchDType

AccMidi_DispatchReturn:
	ret

AccMidi_NormalizeVelocity:
	cps a, 0
	jr nz, AccMidi_VelNonZero
	ldb a, 0x1

AccMidi_VelNonZero:
	ld e, a
	stda8 13266, a
	ld_srib3 A, 0x07, 0xEC, 0xF4
	ret

AccMidi_ParseNoteOn:
	calr AccMidi_ParseCommon
	cpdi8 13357, 145
	jr nz, AccMidi_ParseNoteOn_StorePos
	ld_srib3 A, 0x07, 0xEC, 0xF4
	stda8 13363, a
	call AccBuf_Advance
	ld_srib3 A, 0x07, 0xEC, 0xF4
	stda8 13364, a
	call AccBuf_Advance

AccMidi_ParseNoteOn_StorePos:
	stda16 13272, xiy
	stda16 13270, xiz
	ret

AccMidi_ParseCommon:
	stda8 13357, a
	call AccBuf_Advance
	stda8 13358, e
	call AccBuf_Advance
	ld_srib3 A, 0x07, 0xEC, 0xF4
	stda8 13359, a
	cpdi8 13268, 1
	jr z, AccMidi_ParseCommon_ExtraFields
	cpdi8 13268, 2
	jr z, AccMidi_ParseCommon_ExtraFields
	call Rhythm_CheckVelocityThreshold

AccMidi_ParseCommon_ExtraFields:
	call AccBuf_Advance
	ld_srib3 A, 0x07, 0xEC, 0xF4
	stda8 13360, a
	call AccBuf_Advance
	ld_srib3 A, 0x07, 0xEC, 0xF4
	stda8 13361, a
	call AccBuf_Advance
	ld_srib3 A, 0x07, 0xEC, 0xF4
	stda8 13362, a
	call AccBuf_Advance
	ret

AccMidi_SelectVelocitySource:
	ldda8 a, 13268
	ldda8 w, 13119
	andda8 a, 13078
	jr nz, AccMidi_VelSource_Active
	andda8 a, 13079
	jr nz, AccMidi_VelSource_Active
	andda8 a, 13080
	jr nz, AccMidi_VelSource_Active
	andda8 a, 13076
	jr nz, AccMidi_VelSource_Active
	andda8 a, 13077
	jr z, AccMidi_VelSource_Store

AccMidi_VelSource_Active:
	ldda8 w, 13120

AccMidi_VelSource_Store:
	stda8 13278, w
	ret

AccMidi_DispatchPerPart:
	cpdi8 13268, 1
	jr nz, AccMidi_DispatchKbd2
	calr AccKbd1_RingBufEntry
	jr AccMidi_DispatchAcc4Return

AccMidi_DispatchKbd2:
	cpdi8 13268, 2
	jr nz, AccMidi_DispatchAcc1
	calr AccKbd2_RingBufEntry
	jr AccMidi_DispatchAcc4Return

AccMidi_DispatchAcc1:
	cpdi8 13268, 4
	jr nz, AccMidi_DispatchAcc2
	call AccCh1_NoteOnEntry
	jr AccMidi_DispatchAcc4Return

AccMidi_DispatchAcc2:
	cpdi8 13268, 8
	jr nz, AccMidi_DispatchAcc3
	call AccCh2_NoteOnEntry
	jr AccMidi_DispatchAcc4Return

AccMidi_DispatchAcc3:
	cpdi8 13268, 16
	jr nz, AccMidi_DispatchAcc4
	call AccCh3_NoteOnEntry
	jr AccMidi_DispatchAcc4Return

AccMidi_DispatchAcc4:
	cpdi8 13268, 32
	jr nz, AccMidi_DispatchAcc4Return
	call AccCh4_NoteOnEntry

AccMidi_DispatchAcc4Return:
	ret

AccKbd1_RingBufEntry:
	calr AccKbd1_CheckEligible
	bitda 0, 13281
	jr z, AccKbd1_RingBufReturn
	ld xhl, 0x2A94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccBuf_WriteNoteEvent

AccKbd1_RingBufReturn:
	ret

AccKbd1_CheckEligible:
	anddi8 13281, 254
	bitda 0, 13278
	jr z, AccKbd1_CheckReturn
	bitda 0, 13154
	jr nz, AccKbd1_CheckReturn
	bitda 0, 13063
	jr z, AccKbd1_CheckReturn
	bitda 4, 14235
	jr z, AccKbd1_CheckRecording
	bitda 2, 13519
	jr nz, AccKbd1_CheckReturn
	bitda 7, 13656
	jr z, AccKbd1_CheckRecording
	ldda8 a, 13656
	and a, 0x7F
	cpda8 a, 13359
	jr z, AccKbd1_CheckReturn
	cp a, 0x30
	jr nz, AccKbd1_CheckRecording
	cpdi8 13359, 93
	jr z, AccKbd1_CheckReturn

AccKbd1_CheckRecording:
	bitda 1, 13109
	jr nz, AccKbd1_CheckReturn
	bitda 0, 13434
	jr nz, AccKbd1_CheckReturn
	bitda 0, 13288
	jr nz, AccKbd1_CheckReturn
	ld xhl, 0x2A94
	calr AccBuf_ComputeFillLevel
	cpdi16 13092, 16
	jr ule, AccKbd1_CheckReturn
	ordi8 13281, 1

AccKbd1_CheckReturn:
	ret

AccBuf_WriteNoteEvent:
	ldda8 a, 13357
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	call RingBuf_AdvanceIndex
	call RhythmAccent_UpdateRingBufPosition
	ldda8 a, 13359
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	call RingBuf_AdvanceIndex
	ldda8 a, 13360
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	call RingBuf_AdvanceIndex
	ldda8 a, 13361
	cps a, 0
	jr nz, AccBuf_WriteNote_VelNonZero
	ldb a, 0x1

AccBuf_WriteNote_VelNonZero:
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	call RingBuf_AdvanceIndex
	ldda8 a, 13362
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	call RingBuf_AdvanceIndex
	ld (xhl + 4), iy
	ret

AccBuf_ComputeFillLevel:
	ld wa, (xhl + 6)
	cp wa, (xhl + 4)
	jr c, AccBuf_FillLevel_Wrapped
	jr ugt, AccBuf_FillLevel_Simple
	ld wa, (xhl + 2)
	sub wa, (xhl + 256)
	inc 1, wa
	jr AccBuf_FillLevel_Store

AccBuf_FillLevel_Wrapped:
	ld wa, (xhl + 2)
	sub wa, (xhl + 256)
	inc 1, wa
	sub wa, (xhl + 4)
	add wa, (xhl + 6)
	jr AccBuf_FillLevel_Store

AccBuf_FillLevel_Simple:
	sub wa, (xhl + 4)

AccBuf_FillLevel_Store:
	stda16 13092, xwa
	ret

AccTempo_PositionCompare:
	cpda8 w, 12980
	jr nz, AccTempo_DiffBar
	cp bc, de
	jr c, AccTempo_SameBar
	ldb a, 0x0
	jr AccTempo_Return

AccTempo_SameBar:
	sub de, bc
	ld a, e
	cps d, 0
	jr z, AccTempo_Return
	ldb a, 0x60
	jr AccTempo_Return

AccTempo_DiffBar:
	cpda8 w, 12980
	jr c, AccTempo_BarZero
	cp w, 0xFF
	jr nz, AccTempo_ComputeDelta
	cpdi8 12980, 0
	jr z, AccTempo_TooFar
	jr AccTempo_ComputeDelta

AccTempo_BarZero:
	cps w, 0
	jr nz, AccTempo_TooFar
	cpdi8 12980, 255
	jr z, AccTempo_ComputeDelta

AccTempo_TooFar:
	ldb a, 0x0
	jr AccTempo_Return

AccTempo_ComputeDelta:
	xor xwa, xwa
	ldda8 a, 1112
	sla a, 1
	add xwa, 0xE46B9E
	add de, (xwa)
	sub de, bc
	ld a, e
	cps d, 0
	jr z, AccTempo_Return
	ldb a, 0x60

AccTempo_Return:
	ret

AccKbd1_ProcessNotes:
	calr AccKbd1_TimingCheck
	bitda 0, 13044
	jr nz, AccKbd1_ProcessReturn
	calr AccKbd1_ScanSlots
	calr AccKbd1_DrainRingBuf
	ld xiy, 0x3214
	ld xix, 0x322D
	lds bc, 5
	ldir85
	ldda8 a, 13372
	stda8 13036, a
	call RhythmPart1_ProcessAccentData
	anddi8 13100, 254

AccKbd1_ProcessReturn:
	ret

AccKbd1_TimingCheck:
	ldb a, 0x0
	ldda8 w, 13275
	calr AccVoice_LookupTableAddress
	ldda16 xbc, 12925
	ldda8 w, 13274
	calr AccTempo_PositionCompare
	cp a, 0x18
	jr ule, AccKbd1_TimingOK
	ordi8 13044, 1
	jr AccKbd1_TimingReturn

AccKbd1_TimingOK:
	stda8 13372, a
	ldb a, 0x5F
	ldda8 w, 1112
	dec 1, w
	calr AccVoice_LookupTableAddress
	ldda16 xbc, 12925
	ldda8 w, 13274
	dec 1, w
	calr AccTempo_PositionCompare
	stda8 13371, a

AccKbd1_TimingReturn:
	ret

AccKbd1_ScanSlots:
	ld xhl, 0x3094

AccKbd1_ScanSlots_Loop:
	calr AccSlot_CheckAndUpdate
	add xhl, 0x6
	cp xhl, 0x30C4
	jr c, AccKbd1_ScanSlots_Loop
	ret

AccSlot_CheckAndUpdate:
	bitm 7, (xhl)
	jr z, AccSlot_Return
	ld de, (xhl + 4)
	ldda8 a, 13371
	xor w, w
	ei 6
	addda16 xwa, 1120
	subda8 a, 1124
	jr pl, AccSlot_CompareAndUpdate
	cps w, 0
	jr z, AccSlot_TimingZero
	dec 1, w
	add a, 0x60
	jr AccSlot_CompareAndUpdate

AccSlot_TimingZero:
	xor wa, wa

AccSlot_CompareAndUpdate:
	cp de, wa
	jr ule, AccSlot_RestoreInterrupts
	ld (xhl + 4), wa
	cpdm16 13170, xwa
	jr ule, AccSlot_RestoreInterrupts
	stda16 13170, xwa

AccSlot_RestoreInterrupts:
	ei 0

AccSlot_Return:
	ret

AccKbd1_DrainRingBuf:
	ld xhl, 0x2A94
	ld iy, (xhl + 6)
	ld bc, (xhl + 2)

AccKbd1_DrainLoop:
	cp (xhl + 4), iy
	jr z, AccKbd1_DrainDone
	ld_srib3 A, 0x07, 0xEC, 0xF4
	cp a, 0x90
	jr nz, AccKbd1_DrainSkip
	calr AccBuf_ProcessNoteEvent
	call RingBuf_AdvanceIndex
	jr AccKbd1_DrainLoop

AccKbd1_DrainSkip:
	call RingBuf_AdvanceIndex
	jr AccKbd1_DrainLoop

AccKbd1_DrainDone:
	ret

AccBuf_ProcessNoteEvent:
	call RingBuf_AdvanceIndex
	ld_srib3 W, 0x07, 0xEC, 0xF4
	call Rhythm_AdvancePosition
	ld_srib3 E, 0x07, 0xEC, 0xF4
	pushw iy
	inc 1, iy
	cp iy, bc
	jr ule, AccBuf_NoteEvent_WrapPos
	ld iy, (xhl + 256)

AccBuf_NoteEvent_WrapPos:
	ld_srib3 D, 0x07, 0xEC, 0xF4
	popw iy
	ldda8 a, 13371
	ei 6
	addda8 a, 1122
	addda8 w, 1124
	sub a, w
	jr pl, AccBuf_NoteEvent_StoreTiming
	ldb a, 0x0

AccBuf_NoteEvent_StoreTiming:
	xor w, w
	cp de, wa
	jr ule, AccBuf_NoteEvent_SkipTiming
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	call RingBuf_AdvanceIndex
	lda_dri3 XWA, 0x07, 0xEC, 0xF4
	jr AccBuf_NoteEvent_Return

AccBuf_NoteEvent_SkipTiming:
	call RingBuf_AdvanceIndex

AccBuf_NoteEvent_Return:
	ei 0
	ret

AccKbd2_CheckActive:
	ldda8	a, 13268
	andda8	a, 13280
	jr	z, 76
	ldda8	a, 13268
	ldda8	w, 13076
	orda8	w, 13077
	and	w, a
	jr	z, 10
	orddm8	13098, a
	orddm8	13096, a
	jr	50
	ldda8	a, 13268
	xor	a, 255
	anddm8	13074, a
	anddm8	13075, a
	anddm8	13078, a
	anddm8	13079, a
	anddm8	13080, a
	anddm8	13149, a
	anddm8	13097, a
	stdi8	13290, 0
	stdi8	13270, 254
	stdi8	13272, 6
	ret

AccKbd2_ProcessEntry:
	calr AccKbd2_SaveState
	calr AccVoice_ProcessEventLoop
	calr AccKbd2_RestoreState

AccKbd2_SaveState:
	anddi8 13044, 252
	stdi8 13037, 0
	ldb a, 0x2
	stda8 13268, a
	ldda16 xwa, 12953
	stda16 13270, xwa
	ldda16 xwa, 12937
	stda16 13272, xwa
	ldda8 a, 12982
	stda8 13274, a
	ldda8 a, 12972
	stda8 13275, a
	ldda8 a, 12964
	stda8 13269, a
	ldda8 a, 13292
	stda8 13290, a
	ret

AccKbd2_RestoreState:
	ldda16 xwa, 13270
	stda16 12953, xwa
	ldda16 xwa, 13272
	stda16 12937, xwa
	ldda8 a, 13274
	stda8 12982, a
	ldda8 a, 13275
	stda8 12972, a
	ldda8 a, 13269
	stda8 12964, a
	ldda8 a, 13290
	stda8 13292, a
	ret

AccKbd2_RingBufEntry:
	calr AccKbd2_CheckEligible
	bitda 0, 13281
	jr z, AccKbd2_RingBufReturn
	ld xhl, 0x2B94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccBuf_WriteNoteEvent

AccKbd2_RingBufReturn:
	ret

AccKbd2_CheckEligible:
	anddi8 13281, 254
	cpdi8 13029, 128
	jr nc, AccKbd2_CheckReturn
	bitda 1, 13278
	jr z, AccKbd2_CheckReturn
	bitda 0, 13063
	jr z, AccKbd2_CheckReturn
	bitda 1, 13109
	jr nz, AccKbd2_CheckReturn
	bitda 0, 13434
	jr nz, AccKbd2_CheckReturn
	bitda 0, 13288
	jr nz, AccKbd2_CheckReturn
	ld xhl, 0x2B94
	calr AccBuf_ComputeFillLevel
	cpdi16 13092, 16
	jr ule, AccKbd2_CheckReturn
	ordi8 13281, 1

AccKbd2_CheckReturn:
	ret

AccKbd2_ProcessNotes:
	calr AccKbd1_TimingCheck
	bitda 0, 13044
	jr nz, AccKbd2_ProcessReturn
	calr AccKbd2_ScanSlots
	calr AccKbd2_DrainRingBuf
	anddi8 13100, 253

AccKbd2_ProcessReturn:
	ret

AccKbd2_ScanSlots:
	ld xhl, 0x30C4

AccKbd2_ScanSlots_Loop:
	calr AccSlot_CheckAndUpdate
	add xhl, 0x6
	cp xhl, 0x30F4
	jr c, AccKbd2_ScanSlots_Loop
	ret

AccKbd2_DrainRingBuf:
	ld xhl, 0x2B94
	ld iy, (xhl + 6)
	ld bc, (xhl + 2)

AccKbd2_DrainLoop:
	cp (xhl + 4), iy
	jr z, AccKbd2_DrainDone
	ld_srib3 A, 0x07, 0xEC, 0xF4
	cp a, 0x90
	jr nz, AccKbd2_DrainSkip
	calr AccBuf_ProcessNoteEvent
	call RingBuf_AdvanceIndex
	jr AccKbd2_DrainLoop

AccKbd2_DrainSkip:
	call RingBuf_AdvanceIndex
	jr AccKbd2_DrainLoop

AccKbd2_DrainDone:
	ret

AccSeq_ScanPattern:
	anddi8 13044, 252

AccSeq_ScanLoop:
	bitda 0, 13044
	jrl nz, AccSeq_ScanDone
	ldda32 xhl, 12947
	ld a, (xhl)
	cp a, 0x83
	jr nz, AccSeq_CheckMarker81
	calr AccSeq_ResetToStart

AccSeq_CheckMarker81:
	cp a, 0x81
	jr z, AccSeq_EndOfBar
	cp a, 0x90
	jr z, AccSeq_NoteOn90
	calr AccSeq_AdvancePointer
	jr AccSeq_ScanLoop

AccSeq_NoteOn90:
	calr AccSeq_ReadNextByte
	ldda8 w, 12977
	calr AccVoice_LookupTableAddress
	ldda16 xbc, 12925
	ldda8 w, 12987
	calr AccTempo_PositionCompare
	cp a, 0x18
	jr ugt, AccSeq_NoteOn_TooFar
	calr AccSeq_ParseNoteEvent
	jr AccSeq_NoteOn_Continue

AccSeq_NoteOn_TooFar:
	ordi8 13044, 1

AccSeq_NoteOn_Continue:
	jr AccSeq_ScanLoop

AccSeq_EndOfBar:
	bitda 1, 13044
	jr z, AccSeq_EndOfBar_Process
	ordi8 13044, 1
	jr AccSeq_ScanLoop

AccSeq_EndOfBar_Process:
	ldda8 w, 12977
	calr AccVoice_LookupExtParamAddr
	ldda16 xbc, 12925
	ldda8 w, 12987
	calr AccTempo_PositionCompare
	cp a, 0x18
	jr ugt, AccSeq_EndOfBar_TooFar
	ordi8 13044, 2
	ldda8 a, 12977
	inc 1, a
	ld w, a
	and a, 0xF
	cpda8 a, 1075
	jr z, AccSeq_NextBarPage
	stda8 12977, w
	calr AccSeq_AdvancePointer
	jrl AccSeq_ScanLoop

AccSeq_NextBarPage:
	and w, 0xF0
	add w, 0x10
	stda8 12977, w
	incdi8 1, 12987
	ld xhl, 0xE46BB9
	add xhl, 0x6
	stda32 12947, xhl
	jrl AccSeq_ScanLoop

AccSeq_EndOfBar_TooFar:
	ordi8 13044, 1
	jrl AccSeq_ScanLoop

AccSeq_ScanDone:
	ret

AccSeq_ReadNextByte:
	ldda32 xhl, 12947
	inc 1, xhl
	ld a, (xhl)
	ret

AccSeq_AdvancePointer:
	ldda32 xhl, 12947
	inc 1, xhl
	stda32 12947, xhl
	ret

AccSeq_ResetToStart:
	ld xhl, 0xE46BB9
	add xhl, 0x6
	stda32 12947, xhl
	ld a, (xhl)
	ret

AccSeq_ParseNoteEvent:
	cps a, 0
	jr nz, AccSeq_ParseNote_VelNonZero
	ldb a, 0x1

AccSeq_ParseNote_VelNonZero:
	ld e, a
	ldda32 xhl, 12947
	ld a, (xhl)
	stda8 13357, a
	calr AccSeq_AdvancePointer
	stda8 13358, e
	calr AccSeq_AdvancePointer
	ld a, (xhl)
	stda8 13359, a
	calr AccSeq_AdvancePointer
	ld a, (xhl)
	stda8 13360, a
	calr AccSeq_AdvancePointer
	ldb a, 0x1
	stda8 13361, a
	calr AccSeq_AdvancePointer
	ldb a, 0x0
	stda8 13362, a
	calr AccSeq_AdvancePointer
	ldda8 a, 14235
	and a, 0x3F
	jr z, AccSeq_ParseNote_CheckMode
	cpdi8 36150, 181
	jr z, AccSeq_ParseNote_WriteToKbd2
	jr AccSeq_ParseNote_Return

AccSeq_ParseNote_CheckMode:
	ldda8 a, 13109
	cps a, 3
	jr nz, AccSeq_ParseNote_CheckRec
	bitda 0, 13434
	jr z, AccSeq_ParseNote_WriteToKbd2

AccSeq_ParseNote_CheckRec:
	bitda 0, 13288
	jr z, AccSeq_ParseNote_Return

AccSeq_ParseNote_WriteToKbd2:
	ld xhl, 0x2B94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccBuf_WriteNoteEvent

AccSeq_ParseNote_Return:
	ret

AccCh1_ProcessEntry:
	calr AccCh1_SaveState
	call AccVoice_ProcessEventLoop
	calr AccCh1_RestoreState
	ret

AccCh1_SaveState:
	anddi8 13044, 252
	stdi8 13037, 0
	ldb a, 0x4
	stda8 13268, a
	ldda16 xwa, 12955
	stda16 13270, xwa
	ldda16 xwa, 12939
	stda16 13272, xwa
	ldda8 a, 12983
	stda8 13274, a
	ldda8 a, 12973
	stda8 13275, a
	ldda8 a, 12965
	stda8 13269, a
	ldda8 a, 13293
	stda8 13290, a
	ret

AccCh1_RestoreState:
	ldda16 xwa, 13270
	stda16 12955, xwa
	ldda16 xwa, 13272
	stda16 12939, xwa
	ldda8 a, 13274
	stda8 12983, a
	ldda8 a, 13275
	stda8 12973, a
	ldda8 a, 13269
	stda8 12965, a
	ldda8 a, 13290
	stda8 13293, a
	ret

AccVoice_AssignPerPart:
	cpdi8 13268, 1
	jr z, AccVoice_AssignReturn
	cpdi8 13268, 2
	jr z, AccVoice_AssignReturn
	ldda8 a, 13269
	call AccTuning_FetchValue
	stda8 13129, a
	calr AccVoice_ScanInstruments
	calr AccVoice_SendProgChange

AccVoice_AssignReturn:
	ret

AccVoice_ScanInstruments:
	ldda8 e, 13129
	stdi8 13107, 0

AccVoice_ScanLoop:
	cpda8 e, 13269
	jr z, AccVoice_ScanDone
	ldda32 xiy, 13006
	ld a, e
	call AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	ld iy, wa
	ldda8 a, 12933
	call AccVoice_TableLookup
	call AccVoice_ScanForD3
	inc 1, e
	jr AccVoice_ScanLoop

AccVoice_ScanDone:
	ret

AccVoice_SendProgChange:
	cpdi8 13268, 4
	jr nz, AccVoice_SendD4
	ldb a, 0xD7
	ldb w, 0x3
	ldda8 e, 13107
	stda8 13103, e
	call Rhythm_Send3ByteMsg
	jr AccCh_ReturnStub

AccVoice_SendD4:
	cpdi8 13268, 8
	jr nz, AccVoice_SendD5
	ldb a, 0xD4
	ldb w, 0x3
	ldda8 e, 13107
	stda8 13104, e
	call Rhythm_Send3ByteMsg
	jr AccCh_ReturnStub

AccVoice_SendD5:
	cpdi8 13268, 16
	jr nz, AccVoice_SendD6
	ldb a, 0xD5
	ldb w, 0x3
	ldda8 e, 13107
	stda8 13105, e
	call Rhythm_Send3ByteMsg
	jr AccCh_ReturnStub

AccVoice_SendD6:
	ldb a, 0xD6
	ldb w, 0x3
	ldda8 e, 13107
	stda8 13106, e
	call Rhythm_Send3ByteMsg
	jr __jrt_nop_F57654
__jrt_nop_F57654:

AccCh_ReturnStub:
	ret

AccBuf_Write3ByteEvent:
	ldda8 a, 13357
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	call RingBuf_AdvanceIndex
	call RhythmAccent_UpdateRingBufPosition
	ldda8 a, 13359
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	call RingBuf_AdvanceIndex
	ldda8 a, 13360
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	call RingBuf_AdvanceIndex
	ld (xhl + 4), iy
	ret

AccCh1_Padding:
	.byte 0x00, 0x00

AccCh1_NoteOnEntry:
	calr AccCh1_CheckEligible
	bitda 0, 13281
	jr z, AccCh1_NoteOnReturn
	ldda8 a, 12995
	stda8 13003, a
	ldda8 a, 12999
	stda8 13004, a
	anddi8 13044, 251
	ordi8 13044, 8
	ld xhl, 0x2C94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccBuf_WriteExtendedEvent

AccCh1_NoteOnReturn:
	ret

AccCh1_CheckEligible:
	anddi8 13281, 254
	bitda 2, 13154
	jr nz, AccCh1_CheckReturn
	bitda 1, 13063
	jr z, AccCh1_CheckReturn
	bitda 3, 50592
	jr z, AccCh1_CheckReturn
	calr AccCh_CheckOverlap
	cps a, 0
	jr nz, AccCh1_CheckReturn
	bitda 1, 13109
	jr nz, AccCh1_CheckReturn
	bitda 0, 13434
	jr nz, AccCh1_CheckReturn
	bitda 0, 13288
	jr nz, AccCh1_CheckReturn
	ld xhl, 0x2C94
	call AccBuf_ComputeFillLevel
	cpdi16 13092, 16
	jr ugt, AccCh1_SetReady
	calr AccBuf_InitWithDefaults
	jr AccCh1_CheckReturn

AccCh1_SetReady:
	ordi8 13281, 1

AccCh1_CheckReturn:
	ret

AccBuf_WriteExtendedEvent:
	ldda8 a, 13363
	stda8 13110, a
	ldda8 a, 13364
	stda8 13111, a
	ldda8 a, 13357
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	call RingBuf_AdvanceIndex
	call RhythmAccent_UpdateRingBufPosition
	ldda8 a, 13359
	stda8 13365, a
	calr AccVoice_CheckStyle
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	call RingBuf_AdvanceIndex
	ldda8 a, 13360
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	call RingBuf_AdvanceIndex
	ldda8 a, 13361
	cps a, 0
	jr nz, AccBuf_ExtEvt_VelNonZero
	ldb a, 0x1

AccBuf_ExtEvt_VelNonZero:
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	call RingBuf_AdvanceIndex
	ldda8 a, 13362
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	call RingBuf_AdvanceIndex
	calr AccBuf_ExtEvt_WriteExtra
	ldda8 a, 13365
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	call RingBuf_AdvanceIndex
	ld (xhl + 4), iy
	ret

AccBuf_ExtEvt_WriteExtra:
	cpdi8 13357, 144
	jr z, AccBuf_ExtEvt_ExtraReturn
	ldda8 a, 13110
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	call RingBuf_AdvanceIndex
	ldda8 a, 13111
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	call RingBuf_AdvanceIndex

AccBuf_ExtEvt_ExtraReturn:
	ret

AccVoice_CheckStyle:
	cpdi8 13029, 240
	jr c, AccVoice_CallCorrection

AccVoice_CallCorrection:
	call AccVoice_CorrectNote
	ret

AccVoice_CorrectionData:
	push	xhl
	pushw	iy
	ldda8	a, 13359
	.byte 0xf1, 0xf4, 0x32, 0xcc
	jr	nz, 14
	.byte 0xf1, 0xf4, 0x32, 0xcb
	jr	z, 4
	call	16076763
	call	16076848
	call	16077521
	popw	iy
	pop	xhl
	ret

AccVoice_CorrectNote:
	push xhl
	pushw iy
	ldda8 a, 13359
	bitda 4, 13044
	jr nz, AccVoice_VelocityLookup
	bitda 3, 13044
	jr z, AccVoice_NoteRangeCheck
	call Rhythm_CrossVoiceCorrect

AccVoice_NoteRangeCheck:
	call Rhythm_NoteRangeCheck

AccVoice_VelocityLookup:
	cpdi8 13357, 145
	jr z, AccVoice_UseVoiceMap
	call Rhythm_VelocityLookup_A
	jr AccVoice_CorrectReturn

AccVoice_UseVoiceMap:
	call Rhythm_VoiceMapLookup

AccVoice_CorrectReturn:
	popw iy
	pop xhl
	ret

AccMidi_ParseDType:
	ld d, a
	and a, 0xF0
	stda8 13357, a
	call AccBuf_Advance
	stda8 13358, e
	call AccBuf_Advance
	ld a, d
	and a, 0xF
	stda8 13359, a
	ld_srib3 A, 0x07, 0xEC, 0xF4
	stda8 13360, a
	call AccBuf_Advance
	stda16 13272, xiy
	stda16 13270, xiz
	ret

AccMidi_DispatchDType:
	cpdi8 13268, 1
	jr nz, AccMidi_DType_CheckKbd2
	jr AccMidi_DType_Return

AccMidi_DType_CheckKbd2:
	cpdi8 13268, 2
	jr nz, AccMidi_DType_CheckAcc1
	jr AccMidi_DType_Return

AccMidi_DType_CheckAcc1:
	cpdi8 13268, 4
	jr nz, AccMidi_DType_CheckAcc2
	calr AccCh1_DTypeEntry
	jr AccMidi_DType_Return

AccMidi_DType_CheckAcc2:
	cpdi8 13268, 8
	jr nz, AccMidi_DType_CheckAcc3
	calr AccCh2_DTypeEntry
	jr AccMidi_DType_Return

AccMidi_DType_CheckAcc3:
	cpdi8 13268, 16
	jr nz, AccMidi_DType_CheckAcc4
	calr AccCh3_DTypeEntry
	jr AccMidi_DType_Return

AccMidi_DType_CheckAcc4:
	cpdi8 13268, 32
	jr nz, AccMidi_DType_CheckAcc4
	calr AccCh4_DTypeEntry

AccMidi_DType_Return:
	ret

AccCh1_DTypeEntry:
	calr AccCh1_CheckEligible
	bitda 0, 13281
	jr z, AccCh1_DTypeReturn
	ld xhl, 0x2C94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccBuf_Write3ByteEvent

AccCh1_DTypeReturn:
	ret

AccCh_CheckOverlap:
	ldb a, 0x0
	bitda 2, 13519
	jr z, AccCh_OverlapReturn
	bitda 3, 14235
	jr z, AccCh_OverlapReturn
	ldb a, 0x1

AccCh_OverlapReturn:
	ret

AccBuf_InitWithDefaults:
	ldw (xhl + 256), 0xA
	ldw (xhl + 2), 0xFF
	ldw (xhl + 4), 0xA
	ldw (xhl + 6), 0xA
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	stdi8 13357, 208
	ldda8 a, 13266
	stda8 13358, a
	stdi8 13359, 2
	stdi8 13360, 64
	calr AccBuf_Write3ByteEvent
	ldda8 a, 13266
	stda8 13358, a
	stdi8 13359, 1
	stdi8 13360, 0
	calr AccBuf_Write3ByteEvent
	ldda8 a, 13266
	stda8 13358, a
	stdi8 13359, 3
	stdi8 13360, 0
	calr AccBuf_Write3ByteEvent
	ldda8 a, 13266
	stda8 13358, a
	stdi8 13359, 5
	stdi8 13360, 127
	calr AccBuf_Write3ByteEvent
	ret

AccCh1_ProcessNotes:
	call AccKbd1_TimingCheck
	bitda 0, 13044
	jr nz, AccCh1_ProcessReturn
	calr AccCh1_ScanSlots
	calr AccCh1_DrainRingBuf
	calr AccCh1_InitProgChange
	ld xiy, 0x3219
	ld xix, 0x3232
	lds bc, 5
	ldir85
	ldda8 a, 13372
	stda8 13036, a
	call RhythmPart2_ProcessAccentData
	anddi8 13100, 251

AccCh1_ProcessReturn:
	ret

AccCh1_ScanSlots:
	ld xhl, 0x30F4

AccCh1_ScanSlots_Loop:
	call AccSlot_CheckAndUpdate
	add xhl, 0x9
	cp xhl, 0x313C
	jr c, AccCh1_ScanSlots_Loop
	ret

AccCh1_DrainRingBuf:
	ld xhl, 0x2C94
	ld iy, (xhl + 6)
	ld bc, (xhl + 2)

AccCh1_DrainLoop:
	cp (xhl + 4), iy
	jr z, AccCh1_DrainDone
	ld_srib3 A, 0x07, 0xEC, 0xF4
	cp a, 0x90
	jr nz, AccCh1_DrainType91
	call AccBuf_ProcessNoteEvent
	call RingBuf_AdvanceIndex
	call RingBuf_AdvanceIndex
	jr AccCh1_DrainLoop

AccCh1_DrainType91:
	cp a, 0x91
	jr nz, AccCh1_DrainOther
	call AccBuf_ProcessNoteEvent
	call RingBuf_AdvanceIndex
	call Rhythm_AdvancePosition
	jr AccCh1_DrainLoop

AccCh1_DrainOther:
	call RingBuf_AdvanceIndex
	jr AccCh1_DrainLoop

AccCh1_DrainDone:
	ret

AccCh2_ProcessEntry:
	calr AccCh2_SaveState
	call AccVoice_ProcessEventLoop
	calr AccCh2_RestoreState
	ret

AccCh2_SaveState:
	anddi8 13044, 252
	stdi8 13037, 0
	ldb a, 0x8
	stda8 13268, a
	ldda16 xwa, 12957
	stda16 13270, xwa
	ldda16 xwa, 12941
	stda16 13272, xwa
	ldda8 a, 12984
	stda8 13274, a
	ldda8 a, 12974
	stda8 13275, a
	ldda8 a, 12966
	stda8 13269, a
	ldda8 a, 13294
	stda8 13290, a
	ret

AccCh2_RestoreState:
	ldda16 xwa, 13270
	stda16 12957, xwa
	ldda16 xwa, 13272
	stda16 12941, xwa
	ldda8 a, 13274
	stda8 12984, a
	ldda8 a, 13275
	stda8 12974, a
	ldda8 a, 13269
	stda8 12966, a
	ldda8 a, 13290
	stda8 13294, a
	ret

AccCh2_NoteOnEntry:
	calr AccCh2_CheckEligible
	bitda 0, 13281
	jr z, AccCh2_NoteOnReturn
	ldda8 a, 12996
	stda8 13003, a
	ldda8 a, 13000
	stda8 13004, a
	ordi8 13044, 4
	anddi8 13044, 247
	ld xhl, 0x2D94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccBuf_WriteExtendedEvent

AccCh2_NoteOnReturn:
	ret

AccCh2_CheckEligible:
	anddi8 13281, 254
	bitda 3, 13278
	jr z, AccCh2_CheckReturn
	bitda 3, 13154
	jr nz, AccCh2_CheckReturn
	bitda 2, 13063
	jr z, AccCh2_CheckReturn
	bitda 0, 13072
	jr z, AccCh2_CheckReturn
	bitda 0, 50592
	jr z, AccCh2_CheckReturn
	calr AccCh2_CheckOverlap
	cps a, 0
	jr nz, AccCh2_CheckReturn
	bitda 1, 13109
	jr nz, AccCh2_CheckReturn
	bitda 0, 13434
	jr nz, AccCh2_CheckReturn
	bitda 0, 13288
	jr nz, AccCh2_CheckReturn
	ld xhl, 0x2D94
	call AccBuf_ComputeFillLevel
	cpdi16 13092, 16
	jr ugt, AccCh2_SetReady
	calr AccBuf_InitWithDefaults
	jr AccCh2_CheckReturn

AccCh2_SetReady:
	ordi8 13281, 1

AccCh2_CheckReturn:
	ret

AccCh2_DTypeEntry:
	calr AccCh2_CheckEligible
	bitda 0, 13281
	jr z, AccCh2_DTypeReturn
	ld xhl, 0x2D94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccBuf_Write3ByteEvent

AccCh2_DTypeReturn:
	ret

AccCh2_CheckOverlap:
	ldb a, 0x0
	bitda 2, 13519
	jr z, AccCh2_OverlapReturn
	bitda 0, 14235
	jr z, AccCh2_OverlapReturn
	ldb a, 0x1

AccCh2_OverlapReturn:
	ret

AccCh2_ProcessNotes:
	call AccKbd1_TimingCheck
	bitda 0, 13044
	jr nz, AccCh2_ProcessReturn
	calr AccCh2_ScanSlots
	calr AccCh2_DrainRingBuf
	calr AccCh2_InitProgChange
	ld xiy, 0x321E
	ld xix, 0x3237
	lds bc, 5
	ldir85
	ldda8 a, 13372
	stda8 13036, a
	call AccVoice_LoadRhythmParams_Part3
	anddi8 13100, 247

AccCh2_ProcessReturn:
	ret

AccCh2_ScanSlots:
	ld xhl, 0x313C

AccCh2_ScanSlots_Loop:
	call AccSlot_CheckAndUpdate
	add xhl, 0x9
	cp xhl, 0x3184
	jr c, AccCh2_ScanSlots_Loop
	ret

AccCh2_DrainRingBuf:
	ld xhl, 0x2D94
	ld iy, (xhl + 6)
	ld bc, (xhl + 2)

AccCh2_DrainLoop:
	cp (xhl + 4), iy
	jr z, AccCh2_DrainDone
	ld_srib3 A, 0x07, 0xEC, 0xF4
	cp a, 0x90
	jr nz, AccCh2_DrainType91
	call AccBuf_ProcessNoteEvent
	call RingBuf_AdvanceIndex
	call RingBuf_AdvanceIndex
	jr AccCh2_DrainLoop

AccCh2_DrainType91:
	cp a, 0x91
	jr nz, AccCh2_DrainOther
	call AccBuf_ProcessNoteEvent
	call RingBuf_AdvanceIndex
	call Rhythm_AdvancePosition
	jr AccCh2_DrainLoop

AccCh2_DrainOther:
	call RingBuf_AdvanceIndex
	jr AccCh2_DrainLoop

AccCh2_DrainDone:
	ret

AccCh3_ProcessEntry:
	calr AccCh3_SaveState
	call AccVoice_ProcessEventLoop
	calr AccCh3_RestoreState
	ret

AccCh3_SaveState:
	anddi8 13044, 252
	stdi8 13037, 0
	ldb a, 0x10
	stda8 13268, a
	ldda16 xwa, 12959
	stda16 13270, xwa
	ldda16 xwa, 12943
	stda16 13272, xwa
	ldda8 a, 12985
	stda8 13274, a
	ldda8 a, 12975
	stda8 13275, a
	ldda8 a, 12967
	stda8 13269, a
	ldda8 a, 13295
	stda8 13290, a
	ret

AccCh3_RestoreState:
	ldda16 xwa, 13270
	stda16 12959, xwa
	ldda16 xwa, 13272
	stda16 12943, xwa
	ldda8 a, 13274
	stda8 12985, a
	ldda8 a, 13275
	stda8 12975, a
	ldda8 a, 13269
	stda8 12967, a
	ldda8 a, 13290
	stda8 13295, a
	ret

AccCh3_NoteOnEntry:
	calr AccCh3_CheckEligible
	bitda 0, 13281
	jr z, AccCh3_NoteOnReturn
	ldda8 a, 12997
	stda8 13003, a
	ldda8 a, 13001
	stda8 13004, a
	anddi8 13044, 251
	anddi8 13044, 247
	ld xhl, 0x2E94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccBuf_WriteExtendedEvent

AccCh3_NoteOnReturn:
	ret

AccCh3_CheckEligible:
	anddi8 13281, 254
	bitda 4, 13278
	jr z, AccCh3_CheckReturn
	bitda 4, 13154
	jr nz, AccCh3_CheckReturn
	bitda 3, 13063
	jr z, AccCh3_CheckReturn
	bitda 1, 13072
	jr z, AccCh3_CheckReturn
	bitda 1, 50592
	jr z, AccCh3_CheckReturn
	calr AccCh3_CheckOverlap
	cps a, 0
	jr nz, AccCh3_CheckReturn
	bitda 1, 13109
	jr nz, AccCh3_CheckReturn
	bitda 0, 13434
	jr nz, AccCh3_CheckReturn
	bitda 0, 13288
	jr nz, AccCh3_CheckReturn
	ld xhl, 0x2E94
	call AccBuf_ComputeFillLevel
	cpdi16 13092, 16
	jr ugt, AccCh3_SetReady
	calr AccBuf_InitWithDefaults
	jr AccCh3_CheckReturn

AccCh3_SetReady:
	ordi8 13281, 1

AccCh3_CheckReturn:
	ret

AccCh3_DTypeEntry:
	calr AccCh3_CheckEligible
	bitda 0, 13281
	jr z, AccCh3_DTypeReturn
	ld xhl, 0x2E94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccBuf_Write3ByteEvent

AccCh3_DTypeReturn:
	ret

AccCh3_CheckOverlap:
	ldb a, 0x0
	bitda 2, 13519
	jr z, AccCh3_OverlapReturn
	bitda 1, 14235
	jr z, AccCh3_OverlapReturn
	ldb a, 0x1

AccCh3_OverlapReturn:
	ret

AccCh3_ProcessNotes:
	call AccKbd1_TimingCheck
	bitda 0, 13044
	jr nz, AccCh3_ProcessReturn
	calr AccCh3_ScanSlots
	calr AccCh3_DrainRingBuf
	calr AccCh3_InitProgChange
	ld xiy, 0x3223
	ld xix, 0x323C
	lds bc, 5
	ldir85
	ldda8 a, 13372
	stda8 13036, a
	call AccVoice_LoadRhythmParams_Part4
	anddi8 13100, 239

AccCh3_ProcessReturn:
	ret

AccCh3_ScanSlots:
	ld xhl, 0x3184

AccCh3_ScanSlots_Loop:
	call AccSlot_CheckAndUpdate
	add xhl, 0x9
	cp xhl, 0x31CC
	jr c, AccCh3_ScanSlots_Loop
	ret

AccCh3_DrainRingBuf:
	ld xhl, 0x2E94
	ld iy, (xhl + 6)
	ld bc, (xhl + 2)

AccCh3_DrainLoop:
	cp (xhl + 4), iy
	jr z, AccCh3_DrainDone
	ld_srib3 A, 0x07, 0xEC, 0xF4
	cp a, 0x90
	jr nz, AccCh3_DrainType91
	call AccBuf_ProcessNoteEvent
	call RingBuf_AdvanceIndex
	call RingBuf_AdvanceIndex
	jr AccCh3_DrainLoop

AccCh3_DrainType91:
	cp a, 0x91
	jr nz, AccCh3_DrainOther
	call AccBuf_ProcessNoteEvent
	call RingBuf_AdvanceIndex
	call Rhythm_AdvancePosition
	jr AccCh3_DrainLoop

AccCh3_DrainOther:
	call RingBuf_AdvanceIndex
	jr AccCh3_DrainLoop

AccCh3_DrainDone:
	ret

AccCh4_ProcessEntry:
	calr AccCh4_SaveState
	call AccVoice_ProcessEventLoop
	calr AccCh4_RestoreState
	ret

AccCh4_SaveState:
	anddi8 13044, 252
	stdi8 13037, 0
	ldb a, 0x20
	stda8 13268, a
	ldda16 xwa, 12961
	stda16 13270, xwa
	ldda16 xwa, 12945
	stda16 13272, xwa
	ldda8 a, 12986
	stda8 13274, a
	ldda8 a, 12976
	stda8 13275, a
	ldda8 a, 12968
	stda8 13269, a
	ldda8 a, 13296
	stda8 13290, a
	ret

AccCh4_RestoreState:
	ldda16 xwa, 13270
	stda16 12961, xwa
	ldda16 xwa, 13272
	stda16 12945, xwa
	ldda8 a, 13274
	stda8 12986, a
	ldda8 a, 13275
	stda8 12976, a
	ldda8 a, 13269
	stda8 12968, a
	ldda8 a, 13290
	stda8 13296, a
	ret

AccCh4_NoteOnEntry:
	calr AccCh4_CheckEligible
	bitda 0, 13281
	jr z, AccCh4_NoteOnReturn
	ldda8 a, 12998
	stda8 13003, a
	ldda8 a, 13002
	stda8 13004, a
	anddi8 13044, 251
	anddi8 13044, 247
	ld xhl, 0x2F94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccBuf_WriteExtendedEvent

AccCh4_NoteOnReturn:
	ret

AccCh4_CheckEligible:
	anddi8 13281, 254
	bitda 5, 13278
	jr z, AccCh4_CheckReturn
	bitda 5, 13154
	jr nz, AccCh4_CheckReturn
	bitda 4, 13063
	jr z, AccCh4_CheckReturn
	bitda 2, 13072
	jr z, AccCh4_CheckReturn
	bitda 2, 50592
	jr z, AccCh4_CheckReturn
	calr AccCh4_CheckOverlap
	cps a, 0
	jr nz, AccCh4_CheckReturn
	bitda 1, 13109
	jr nz, AccCh4_CheckReturn
	bitda 0, 13434
	jr nz, AccCh4_CheckReturn
	bitda 0, 13288
	jr nz, AccCh4_CheckReturn
	ld xhl, 0x2F94
	call AccBuf_ComputeFillLevel
	cpdi16 13092, 16
	jr ugt, AccCh4_SetReady
	calr AccBuf_InitWithDefaults
	jr AccCh4_CheckReturn

AccCh4_SetReady:
	ordi8 13281, 1

AccCh4_CheckReturn:
	ret

AccCh4_DTypeEntry:
	calr AccCh4_CheckEligible
	bitda 0, 13281
	jr z, AccCh4_DTypeReturn
	ld xhl, 0x2F94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccBuf_Write3ByteEvent

AccCh4_DTypeReturn:
	ret

AccCh4_CheckOverlap:
	ldb a, 0x0
	bitda 2, 13519
	jr z, AccCh4_OverlapReturn
	bitda 2, 14235
	jr z, AccCh4_OverlapReturn
	ldb a, 0x1

AccCh4_OverlapReturn:
	ret

AccCh4_ProcessNotes:
	call AccKbd1_TimingCheck
	bitda 0, 13044
	jr nz, AccCh4_ProcessReturn
	calr AccCh4_ScanSlots
	calr AccCh4_DrainRingBuf
	calr AccCh4_InitProgChange
	ld xiy, 0x3228
	ld xix, 0x3241
	lds bc, 5
	ldir85
	ldda8 a, 13372
	stda8 13036, a
	call AccVoice_LoadRhythmParams_Part5
	anddi8 13100, 223

AccCh4_ProcessReturn:
	ret

AccCh4_ScanSlots:
	ld xhl, 0x31CC

AccCh4_ScanSlots_Loop:
	call AccSlot_CheckAndUpdate
	add xhl, 0x9
	cp xhl, 0x3214
	jr c, AccCh4_ScanSlots_Loop
	ret

AccCh4_DrainRingBuf:
	ld xhl, 0x2F94
	ld iy, (xhl + 6)
	ld bc, (xhl + 2)

AccCh4_DrainLoop:
	cp (xhl + 4), iy
	jr z, AccCh4_DrainDone
	ld_srib3 A, 0x07, 0xEC, 0xF4
	cp a, 0x90
	jr nz, AccCh4_DrainType91
	call AccBuf_ProcessNoteEvent
	call RingBuf_AdvanceIndex
	call RingBuf_AdvanceIndex
	jr AccCh4_DrainLoop

AccCh4_DrainType91:
	cp a, 0x91
	jr nz, AccCh4_DrainOther
	call AccBuf_ProcessNoteEvent
	call RingBuf_AdvanceIndex
	call Rhythm_AdvancePosition
	jr AccCh4_DrainLoop

AccCh4_DrainOther:
	call RingBuf_AdvanceIndex
	jr AccCh4_DrainLoop

AccCh4_DrainDone:
	ret

AccCh1_InitProgChange:
	ld xhl, 0x2C94
	calr AccBuf_WriteD0Defaults
	ret

AccCh2_InitProgChange:
	ld xhl, 0x2D94
	calr AccBuf_WriteD0Defaults
	ret

AccCh3_InitProgChange:
	ld xhl, 0x2E94
	calr AccBuf_WriteD0Defaults
	ret

AccCh4_InitProgChange:
	ld xhl, 0x2F94
	calr AccBuf_WriteD0Defaults
	ret

AccBuf_WriteD0Defaults:
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	stdi8 13357, 208
	ldda8 a, 13372
	stda8 13358, a
	stdi8 13359, 2
	stdi8 13360, 64
	calr AccBuf_Write3ByteEvent
	ldda8 a, 13372
	stda8 13358, a
	stdi8 13359, 1
	stdi8 13360, 0
	calr AccBuf_Write3ByteEvent
	ldda8 a, 13372
	stda8 13358, a
	stdi8 13359, 3
	stdi8 13360, 0
	calr AccBuf_Write3ByteEvent
	ldda8 a, 13372
	stda8 13358, a
	stdi8 13359, 5
	stdi8 13360, 127
	calr AccBuf_Write3ByteEvent
	ret

AccPart_Deactivate:
	ldda8 a, 13424
	and a, 0xC0
	jr nz, AccPart_Deactivate_WithPedal
	ldda8 a, 13268
	andda8 a, 13097
	jr z, AccPart_Deactivate_NoPedal

AccPart_Deactivate_WithPedal:
	calr AccPart_ResolveWithPedal
	ldda8 a, 13268
	xor a, 0xFF
	anddm8 13097, a
	jrl AccPart_DeactivateReturn

AccPart_Deactivate_NoPedal:
	ldda8 a, 13078
	orda8 a, 13079
	orda8 a, 13080
	andda8 a, 13268
	jr nz, AccPart_Deactivate_ActiveNote
	bitda 0, 13057
	jr nz, AccPart_Deactivate_WithSync
	bitda 0, 13071
	jr nz, AccPart_Deactivate_SetDone
	jr AccPart_Deactivate_SendOff

AccPart_Deactivate_WithSync:
	anddi8 13070, 252
	ordi8 13070, 1
	ldda8 a, 13268
	andda8 a, 13074
	jr z, AccPart_Deactivate_SetDone
	ordi8 13070, 2
	jr AccPart_Deactivate_SetDone

AccPart_Deactivate_ActiveNote:
	bitda 0, 13071
	jr z, AccPart_Deactivate_SendOff

AccPart_Deactivate_SetDone:
	ordi8 13043, 128
	ordi8 13044, 1
	jr AccPart_Deactivate_ClearMasks

AccPart_Deactivate_SendOff:
	calr AccPart_SelectSourceOrParam
	calr AccPart_ResolveStyleAddr

AccPart_Deactivate_ClearMasks:
	ldda8 a, 13268
	xor a, 0xFF
	anddm8 13074, a
	anddm8 13075, a
	anddm8 13078, a
	anddm8 13079, a
	anddm8 13080, a
	stdi8 13275, 0
	stdi8 13290, 0

AccPart_DeactivateReturn:
	ret

AccPart_Reactivate:
	ldda8 a, 13268
	andda8 a, 13280
	jr z, AccPart_ReactivateReturn
	ldda8 a, 13268
	ldda8 w, 13076
	orda8 w, 13077
	and w, a
	jr z, AccPart_Reactivate_Inactive
	orddm8 13098, a
	orddm8 13096, a
	stdi8 13270, 254
	stdi8 13272, 6
	jr AccPart_ReactivateReturn

AccPart_Reactivate_Inactive:
	ldda8 a, 13268
	xor a, 0xFF
	anddm8 13074, a
	anddm8 13075, a
	anddm8 13078, a
	anddm8 13079, a
	anddm8 13080, a
	anddm8 13149, a
	anddm8 13097, a
	stdi8 13290, 0
	stdi8 13270, 254
	stdi8 13272, 6

AccPart_ReactivateReturn:
	ret

AccTick_Main:
	bitda 2, 12931
	jrl nz, AccTick_CheckCollect
	calr AccTempo_BarCompare
	bitda 6, 13044
	jrl nz, AccTick_Return
	calr AccPedal_CheckCombined
	bitda 6, 13044
	jrl nz, AccTick_Return
	call AccTuning_ApplyChange
	bitda 7, 13100
	jr z, AccTick_AfterSync
	call Rhythm_ProcessAllPartsAndLoad
	anddi8 13100, 127

AccTick_AfterSync:
	call AccVoice_ProcessAllSixParts
	bitda 5, 13044
	jrl nz, AccTick_Return
	call AccKbd2_ProcessEntry
	call AccSeq_ScanPattern
	bitda 0, 13434
	jr nz, AccTick_ProcessAccChannels
	bitda 0, 12931
	jr z, AccTick_CheckNoteOn
	ldda16 xwa, 50582
	and wa, 0x200
	jr z, AccTick_CheckNoteOn

AccTick_ProcessAccChannels:
	call AccCh1_ProcessEntry
	call AccCh2_ProcessEntry
	call AccCh3_ProcessEntry
	call AccCh4_ProcessEntry

AccTick_CheckNoteOn:
	bitda 7, 13043
	jr z, AccTick_CheckCollect
	anddi8 13043, 127
	call AccTempo_CalcPosition
	bitda 0, 13070
	jr nz, AccTick_DispatchNoteOn
	bitda 0, 13071
	jr nz, AccTick_DispatchNoteOn
	bitda 0, 13069
	jr nz, AccTick_DispatchNoteOn
	bitda 0, 13068
	jr nz, AccTick_DispatchNoteOn
	ldda8 a, 13065
	and a, 0x3
	jr nz, AccTick_DispatchNoteOn
	ldda8 a, 13066
	and a, 0xD
	jr nz, AccTick_DispatchNoteOn
	ldda8 a, 13067
	and a, 0x3
	jr z, AccTick_FlushAndRepeat

AccTick_DispatchNoteOn:
	call AccFlags_Aggregate

AccTick_FlushAndRepeat:
	call AccNote_FlushAll
	jrl AccTick_AfterSync

AccTick_CheckCollect:
	bitda 2, 12931
	jr z, AccTick_Return
	call AccState_CollectAll

AccTick_Return:
	ret

AccVelocity_CurveTable:
	decf
	.byte 0x1a, 0x33, 0x4d
	jr	z, -128
	and	(xde-77), ix
	.byte 0xe6
	swi	7

AccVoice_InitPerChannel:
	cpdi8 13268, 4
	jr nz, AccVoice_InitCh2
	calr AccVoice_InitCh1_D7
	jr AccVoice_InitReturn

AccVoice_InitCh2:
	cpdi8 13268, 8
	jr nz, AccVoice_InitCh3
	calr AccVoice_InitCh2_D4
	jr AccVoice_InitReturn

AccVoice_InitCh3:
	cpdi8 13268, 16
	jr nz, AccVoice_InitCh4
	calr AccVoice_InitCh3_D5
	jr AccVoice_InitReturn

AccVoice_InitCh4:
	cpdi8 13268, 32
	jr nz, AccVoice_InitReturn
	calr AccVoice_InitCh4_D6

AccVoice_InitReturn:
	ret

AccVoice_InitCh1_D7:
	pushw hl
	push xiy
	ld xhl, 0x2C94
	calr AccBuf_DrainAndReset
	ldb a, 0xD7
	ldb w, 0x2
	ldb e, 0x40
	call Rhythm_Send3ByteMsg
	ldb a, 0xD7
	ldb w, 0x1
	ldb e, 0x0
	call Rhythm_Send3ByteMsg
	ldb a, 0xD7
	ldb w, 0x3
	ldb e, 0x0
	call Rhythm_Send3ByteMsg
	stdi8 13103, 0
	ldb a, 0xD7
	ldb w, 0x5
	ldb e, 0x7F
	call Rhythm_Send3ByteMsg
	pop xiy
	popw hl
	ret

AccBuf_WriteD0WithVoice:
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	stib_dri 0x07, 0xEC, 0xF4, 0xD0
	call RingBuf_AdvanceIndex
	ldda8 a, 13034
	stda8 13358, a
	call RhythmAccent_UpdateRingBufPosition
	stib_dri 0x07, 0xEC, 0xF4, 0x03
	call RingBuf_AdvanceIndex
	ldda8 a, 13107
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	call RingBuf_AdvanceIndex
	ld (xhl + 4), iy
	ret

AccVoice_InitCh2_D4:
	pushw hl
	push xiy
	ld xhl, 0x2D94
	calr AccBuf_DrainAndReset
	ldb a, 0xD4
	ldb w, 0x2
	ldb e, 0x40
	call Rhythm_Send3ByteMsg
	ldb a, 0xD4
	ldb w, 0x1
	ldb e, 0x0
	call Rhythm_Send3ByteMsg
	ldb a, 0xD4
	ldb w, 0x3
	ldb e, 0x0
	call Rhythm_Send3ByteMsg
	stdi8 13104, 0
	ldb a, 0xD4
	ldb w, 0x5
	ldb e, 0x7F
	call Rhythm_Send3ByteMsg
	pop xiy
	popw hl
	ret

AccVoice_InitCh3_D5:
	pushw hl
	push xiy
	ld xhl, 0x2E94
	calr AccBuf_DrainAndReset
	ldb a, 0xD5
	ldb w, 0x2
	ldb e, 0x40
	call Rhythm_Send3ByteMsg
	ldb a, 0xD5
	ldb w, 0x1
	ldb e, 0x0
	call Rhythm_Send3ByteMsg
	ldb a, 0xD5
	ldb w, 0x3
	ldb e, 0x0
	call Rhythm_Send3ByteMsg
	stdi8 13105, 0
	ldb a, 0xD5
	ldb w, 0x5
	ldb e, 0x7F
	call Rhythm_Send3ByteMsg
	pop xiy
	popw hl
	ret

AccVoice_InitCh4_D6:
	pushw hl
	push xiy
	ld xhl, 0x2F94
	calr AccBuf_DrainAndReset
	ldb a, 0xD6
	ldb w, 0x2
	ldb e, 0x40
	call Rhythm_Send3ByteMsg
	ldb a, 0xD6
	ldb w, 0x1
	ldb e, 0x0
	call Rhythm_Send3ByteMsg
	ldb a, 0xD6
	ldb w, 0x3
	ldb e, 0x0
	call Rhythm_Send3ByteMsg
	stdi8 13106, 0
	ldb a, 0xD6
	ldb w, 0x5
	ldb e, 0x7F
	call Rhythm_Send3ByteMsg
	pop xiy
	popw hl
	ret

AccPedal_CheckCombined:
	bitda 0, 13068
	jr nz, AccPedal_CheckFlags
	ldda8 a, 13067
	and a, 0x3
	jr z, AccPedal_CheckDirection

AccPedal_CheckFlags:
	ldda8 a, 13094
	and a, 0x3F
	jr z, AccPedal_TriggerReInit

AccPedal_CheckDirection:
	ldda8 a, 13066
	and a, 0xD
	jr nz, AccPedal_CheckCounter
	ldda8 a, 13065
	and a, 0x3
	jr z, AccPedal_CombinedReturn

AccPedal_CheckCounter:
	ldda8 a, 13095
	and a, 0x3F
	jr nz, AccPedal_CombinedReturn

AccPedal_TriggerReInit:
	calr AccInit_FullReInit

AccPedal_CombinedReturn:
	ret

AccTick_ByteData:
	call	16073687
	call	16073552
	calr	3162
	call	16073734
	calr	3214
	ldda8	a, 13074
	orda8	a, 13075
	and	a, 63
	jr	z, 44
	.byte 0xf1, 0x01, 0x33, 0xc8
	jr	z, 38
	.byte 0xc1, 0x0c, 0x33, 0x3e, 0x01
	ldda8	a, 13074
	and	a, 63
	jr	z, 13
	cpdi8	13114, 0
	jr	z, 17
	.byte 0xc1
	.ascii ":3ih"
	.byte 0x0b
	.byte 0xc1, 0x3a, 0x33, 0x3f, 0x03, 0x66, 0x04, 0xc1
	.byte 0x3a, 0x33, 0x61, 0xf1, 0x0f, 0x33, 0xc8, 0x6e
	.byte 0x0f, 0xf1, 0x0c, 0x33, 0xc8, 0x66, 0x17, 0xc1
	.byte 0x26, 0x33, 0x21, 0xc9, 0xcc, 0x3f, 0x6e, 0x0e
	.byte 0x1e, 0xfe, 0x03, 0x1e, 0x12, 0x05, 0xc1, 0x33
	.byte 0x04, 0x21, 0xf1, 0x58, 0x04, 0x41, 0xc1, 0x0a
	.byte 0x33, 0x21, 0xc9, 0xcc, 0x0d, 0x66, 0x03, 0x1e
	.byte 0x76, 0x06, 0xc1, 0x09, 0x33, 0x21, 0xc9, 0xcc
	.byte 0x03, 0x6e, 0x18, 0xf1, 0x70, 0x34, 0xce, 0x66
	.byte 0x07, 0xc1, 0x09, 0x33, 0x3e, 0x01, 0x68, 0x0b
	.byte 0xf1, 0x70, 0x34, 0xcf, 0x66, 0x08, 0xc1, 0x09
	.byte 0x33, 0x3e, 0x02, 0x1e, 0x46, 0x08, 0xc1, 0x0b
	.byte 0x33, 0x21, 0xc9, 0xcc, 0x03, 0x66, 0x0a, 0x1e
	.byte 0x96, 0x0c, 0x1d, 0x84, 0x97, 0xf5, 0x1e, 0x69
	.byte 0x0a, 0xc1, 0xab, 0x32, 0x3c, 0xf0, 0xc1, 0xac
	.byte 0x32, 0x3c, 0xf0, 0xc1, 0xad, 0x32, 0x3c, 0xf0
	.byte 0xc1, 0xae, 0x32, 0x3c, 0xf0, 0xc1, 0xaf, 0x32
	.byte 0x3c, 0xf0, 0xc1, 0xb0, 0x32, 0x3c, 0xf0, 0x1e
	.byte 0x64, 0x00, 0xf1, 0xf4, 0x32, 0xce, 0x6e, 0x03
	.byte 0x1e, 0x39, 0x02, 0xc1, 0x2c, 0x33, 0x3e, 0x80
	.byte 0x0e

AccTempo_BarCompare:
	ldda8 w, 12981
	cpda8 w, 12980
	jr c, AccTempo_BarLess
	jr z, AccTempo_BarEqual
	jr ugt, AccTempo_BarGreater

AccTempo_BarLess:
	cps w, 0
	jr nz, AccTempo_BarChanged
	cpdi8 12980, 255
	jr nz, AccTempo_BarChanged
	jr AccTempo_ComputeSubDelta

AccTempo_BarEqual:
	ldda16 xwa, 13027
	cpdm8 12928, w
	jr c, AccTempo_ComputeSubDelta
	jr ugt, AccTempo_BarChanged
	cpdm8 12927, a
	jr ule, AccTempo_ComputeSubDelta
	jr AccTempo_BarChanged

AccTempo_BarGreater:
	cp w, 0xFF
	jr nz, AccTempo_ComputeSubDelta
	cpdi8 12980, 0
	jr nz, AccTempo_ComputeSubDelta

AccTempo_BarChanged:
	ldb a, 0x1
	jr AccTempo_StoreDelta

AccTempo_ComputeSubDelta:
	ldda16 xwa, 13027
	subda8 a, 12927
	jr nc, AccTempo_StoreDelta
	add a, 0x60

AccTempo_StoreDelta:
	stda8 13034, a
	stda8 13036, a
	ret

AccSeq_DualPartScan:
	ldda16 xde, 13027
	stdi8 13038, 0
	stdi8 13107, 0
	ldda16 xwa, 12935
	stda16 13272, xwa
	ldda8 a, 12971
	stda8 13275, a
	ldda16 xiz, 12951
	stda16 13270, xiz
	ldb w, 0x1
	calr AccVoice_SelectByMask
	calr AccSeq_PatternScanner
	ldda16 xwa, 13270
	stda16 12951, xwa
	ldda8 a, 13275
	stda8 12971, a
	ldda16 xwa, 13272
	stda16 12935, xwa
	bitda 6, 13044
	jr nz, AccSeq_DualPartReturn
	ldda16 xde, 13027
	stdi8 13038, 0
	stdi8 13107, 0
	ldda16 xwa, 12937
	stda16 13272, xwa
	ldda8 a, 12972
	stda8 13275, a
	ldda16 xiz, 12953
	stda16 13270, xiz
	ldb w, 0x2
	calr AccVoice_SelectByMask
	calr AccSeq_PatternScanner
	ldda16 xwa, 13270
	stda16 12953, xwa
	ldda8 a, 13275
	stda8 12972, a
	ldda16 xwa, 13272
	stda16 12937, xwa

AccSeq_DualPartReturn:
	ret

AccSeq_PatternScanner:
	ldda16 xiy, 13272
	ldda16 xiz, 13270
	anddi8 13044, 254
	xor bc, bc

AccSeq_ScannerLoop:
	bitda 0, 13044
	jrl nz, AccSeq_Scanner_Done
	ld_srib3 A, 0x07, 0xEC, 0xF4
	cp a, 0x81
	jr nz, AccSeq_Scanner_EventType
	add b, 0x1
	xor c, c
	cp de, bc
	jr nc, AccSeq_Scanner_BarEnd
	ordi8 13044, 1
	jr AccSeq_ScannerLoop

AccSeq_Scanner_BarEnd:
	ldda8 a, 13275
	inc 1, a
	ld w, a
	and a, 0xF
	cpda8 a, 1075
	jr nz, AccSeq_Scanner_StorePos
	and w, 0xF0
	add w, 0x10

AccSeq_Scanner_StorePos:
	stda8 13275, w
	calr AccBuf_Advance
	jr AccSeq_ScannerLoop

AccSeq_Scanner_EventType:
	cp a, 0x90
	jr z, AccSeq_Scanner_EventMatch
	cp a, 0x91
	jr z, AccSeq_Scanner_EventMatch
	cp a, 0xD1
	jr z, AccSeq_Scanner_EventMatch
	cp a, 0xD2
	jr z, AccSeq_Scanner_EventMatch
	cp a, 0xD3
	jr z, AccSeq_Scanner_EventMatch
	cp a, 0xD4
	jr z, AccSeq_Scanner_EventMatch
	cp a, 0xD5
	jr z, AccSeq_Scanner_EventMatch
	jr nz, AccSeq_Scanner_Unknown

AccSeq_Scanner_EventMatch:
	calr AccBuf_AdvanceWithPageTurn
	ld c, a
	cp de, bc
	jr nc, AccSeq_Scanner_SkipFields
	ordi8 13044, 1
	jr AccSeq_ScannerLoop

AccSeq_Scanner_SkipFields:
	ld_srib3 A, 0x07, 0xEC, 0xF4
	cp a, 0xD3
	jr z, AccSeq_Scanner_D3Voice
	cp a, 0x90
	jr nz, AccSeq_Scanner_Skip91
	calr AccBuf_Advance
	calr AccBuf_Advance
	calr AccBuf_Advance
	calr AccBuf_Advance
	calr AccBuf_Advance
	calr AccBuf_Advance
	jrl AccSeq_ScannerLoop

AccSeq_Scanner_Skip91:
	cp a, 0x91
	jr nz, AccSeq_Scanner_SkipOther
	calr AccBuf_Advance
	calr AccBuf_Advance
	calr AccBuf_Advance
	calr AccBuf_Advance
	calr AccBuf_Advance
	calr AccBuf_Advance
	calr AccBuf_Advance
	calr AccBuf_Advance
	jrl AccSeq_ScannerLoop

AccSeq_Scanner_SkipOther:
	calr AccBuf_Advance
	calr AccBuf_Advance
	calr AccBuf_Advance
	jrl AccSeq_ScannerLoop

AccSeq_Scanner_D3Voice:
	calr AccBuf_Advance
	calr AccBuf_Advance
	ld_srib3 A, 0x07, 0xEC, 0xF4
	stda8 13107, a
	calr AccBuf_Advance
	jrl AccSeq_ScannerLoop

AccSeq_Scanner_Unknown:
	incdi8 1, 13038
	cpdi8 13038, 32
	jr c, AccSeq_Scanner_Skip1
	call AccWrap_PlayModeDispatch
	call AccDemo_InitDone
	stdi8 13045, 255
	ordi8 13044, 65

AccSeq_Scanner_Skip1:
	calr AccBuf_Advance
	jrl AccSeq_ScannerLoop

AccSeq_Scanner_Done:
	stda16 13270, xiz
	stda16 13272, xiy
	ret

AccSeq_ScannerPadding:
	.byte 0x00, 0x00

AccBuf_AdvanceWithPageTurn:
	pushw iy
	inc 1, iy
	ld_srib3 A, 0x07, 0xEC, 0xF4
	cp a, 0x87
	jr nz, AccBuf_AdvanceReturn
	push xhl
	pushw iz
	ld iz, (xhl + 3)
	calr AccWave_BankResolve
	ld a, (xhl + 6)
	popw iz
	pop xhl

AccBuf_AdvanceReturn:
	popw iy
	ret

AccBuf_Advance:
	inc 1, iy
	ld_srib3 A, 0x07, 0xEC, 0xF4
	cp a, 0x87
	jr nz, AccBuf_AdvanceSimpleReturn
	ld hl, (xhl + 3)
	ld iz, hl
	calr AccWave_BankResolve
	lds iy, 6

AccBuf_AdvanceSimpleReturn:
	ret

AccSeq_FourChannelScan:
	ldda16 xde, 13027
	stdi8 13038, 0
	stdi8 13107, 0
	ldda16 xwa, 12939
	stda16 13272, xwa
	ldda8 a, 12973
	stda8 13275, a
	ldda16 xiz, 12955
	stda16 13270, xiz
	ldb w, 0x4
	calr AccVoice_SelectByMask
	calr AccSeq_PatternScanner
	ldda16 xwa, 13270
	stda16 12955, xwa
	ldda8 a, 13275
	stda8 12973, a
	ldda16 xwa, 13272
	stda16 12939, xwa
	ld xhl, 0x2C94
	calr AccBuf_WriteD0WithVoice
	bitda 6, 13044
	jrl nz, AccSeq_FourChannelReturn
	ldda16 xde, 13027
	stdi8 13038, 0
	stdi8 13107, 0
	ldda16 xwa, 12941
	stda16 13272, xwa
	ldda8 a, 12974
	stda8 13275, a
	ldda16 xiz, 12957
	stda16 13270, xiz
	ldb w, 0x8
	calr AccVoice_SelectByMask
	calr AccSeq_PatternScanner
	ldda16 xwa, 13270
	stda16 12957, xwa
	ldda8 a, 13275
	stda8 12974, a
	ldda16 xwa, 13272
	stda16 12941, xwa
	ld xhl, 0x2D94
	calr AccBuf_WriteD0WithVoice
	bitda 6, 13044
	jrl nz, AccSeq_FourChannelReturn
	ldda16 xde, 13027
	stdi8 13038, 0
	stdi8 13107, 0
	ldda16 xwa, 12943
	stda16 13272, xwa
	ldda8 a, 12975
	stda8 13275, a
	ldda16 xiz, 12959
	stda16 13270, xiz
	ldb w, 0x10
	calr AccVoice_SelectByMask
	calr AccSeq_PatternScanner
	ldda16 xwa, 13270
	stda16 12959, xwa
	ldda8 a, 13275
	stda8 12975, a
	ldda16 xwa, 13272
	stda16 12943, xwa
	ld xhl, 0x2E94
	calr AccBuf_WriteD0WithVoice
	bitda 6, 13044
	jr nz, AccSeq_FourChannelReturn
	ldda16 xde, 13027
	stdi8 13038, 0
	stdi8 13107, 0
	ldda16 xwa, 12945
	stda16 13272, xwa
	ldda8 a, 12976
	stda8 13275, a
	ldda16 xiz, 12961
	stda16 13270, xiz
	ldb w, 0x20
	calr AccVoice_SelectByMask
	calr AccSeq_PatternScanner
	ldda16 xwa, 13270
	stda16 12961, xwa
	ldda8 a, 13275
	stda8 12976, a
	ldda16 xwa, 13272
	stda16 12945, xwa
	ld xhl, 0x2F94
	calr AccBuf_WriteD0WithVoice

AccSeq_FourChannelReturn:
	ret

AccStyle_Init:
	ldda8 a, 13032
	and a, 0x7F
	and a, 0x7
	stda8 13030, a
	ldda8 a, 13031
	stda8 13029, a
	call AccTuning_Init
	cpdi8 13029, 128
	jr nc, AccStyle_ExtendedInit
	ldda8 a, 13114
	and a, 0x3
	stda8 13112, a
	ldda8 a, 13029
	ldda8 h, 13030
	call AccVoice_LookupWithOffset
	stda32 13006, xiy
	call Rhythm_UpdateTuningConfig
	ldda8 a, 12963
	ldb w, 0x0
	call AccPart_GetVoiceParamOffsetTable
	call AccVoice_LoadTuningBlock
	ordi8 13100, 63
	jr AccStyle_Finalize

AccStyle_ExtendedInit:
	ld xiy, 0xE46BF9
	ldda8 a, 13029
	and a, 0x7F
	cp a, 0x1D
	jr ule, AccStyle_LookupTable
	xor a, a

AccStyle_LookupTable:
	ld_srib3 A, 0x03, 0xF4, 0xE0
	stda8 13112, a
	ldda8 a, 13029
	and a, 0x7F
	call AccVoice_ResolveParamAddr
	stda32 13006, xiy
	ld l, (xiy + 16)
	ld h, (xiy + 17)
	and h, 0xF
	and a, 0x7
	cp hl, 0x208
	jr z, AccStyle_LoadAndApply
	cp hl, 0x318
	jr z, AccStyle_LoadAndApply
	call VoiceParam_ClampAndValidate

AccStyle_LoadAndApply:
	ld a, l
	call AccVoice_LookupWithOffset
	stda32 13011, xiy
	call Rhythm_UpdateTuningConfig
	ldda32 xiy, 13006
	call AccTuning_CopyAllPartsFromStyle
	ordi8 13100, 63
	ldda8 w, 13029
	call AccPatch_SetByChordIndex

AccStyle_Finalize:
	call AccVoice_SelectAndApplyPatch
	jr __jrt_nop_F587C4
__jrt_nop_F587C4:

AccInit_ClearAllFlags:
	anddi8 13068, 254
	anddi8 13069, 254
	anddi8 13070, 252
	xor a, a
	stda8 13078, a
	stda8 13079, a
	stda8 13080, a
	stda8 13074, a
	stda8 13075, a
	stda8 13076, a
	stda8 13077, a
	stda8 13149, a
	stda8 13133, a
	stda8 12989, a
	stda8 12990, a
	stda8 12991, a
	stda8 12992, a
	stda8 12993, a
	stda8 12994, a
	call AccTone_CallWithSaveAll
	ret

AccVoice_SetupAllParts:
	cpdi8 13029, 128
	jr c, AccVoice_SetupAll_Extended
	ldda32 xiy, 13006
	jr AccVoice_SetupAll_Dispatch

AccVoice_SetupAll_Extended:
	ldda32 xiy, 13006
	ld_srib A, (xiy + 0x03d1)
	stda8 12933, a

AccVoice_SetupAll_Dispatch:
	calr AccVoice_SetupKbd1
	calr AccVoice_SetupKbd2
	calr AccVoice_SetupAcc1
	calr AccVoice_SetupAcc2
	calr AccVoice_SetupAcc3
	calr AccVoice_SetupAcc4
	ret

AccVoice_SetupKbd1:
	anddi8 12971, 15
	cpdi8 13029, 128
	jr nc, AccVoice_SetupKbd1_Free
	stdi8 13268, 1
	ldda8 a, 12963
	call AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	stda16 12935, xwa
	jr AccVoice_SetupKbd1_Return

AccVoice_SetupKbd1_Free:
	stdi8 13268, 1
	call AccPart_GetFreeVoiceAddr
	stda16 12951, xwa
	stdi16 12935, 6

AccVoice_SetupKbd1_Return:
	ret

AccVoice_SetupKbd2:
	anddi8 12972, 15
	cpdi8 13029, 128
	jr nc, AccVoice_SetupKbd2_Free
	stdi8 13268, 2
	ldda8 a, 12964
	call AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	stda16 12937, xwa
	jr AccVoice_SetupKbd2_Return

AccVoice_SetupKbd2_Free:
	stdi8 13268, 2
	call AccPart_GetFreeVoiceAddr
	stda16 12953, xwa
	stdi16 12937, 6

AccVoice_SetupKbd2_Return:
	ret

AccVoice_SetupAcc1:
	anddi8 12973, 15
	cpdi8 13029, 128
	jr nc, AccVoice_SetupAcc1_Free
	stdi8 13268, 4
	ldda8 a, 12965
	call AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	stda16 12939, xwa
	jr AccVoice_SetupAcc1_Return

AccVoice_SetupAcc1_Free:
	stdi8 13268, 4
	call AccPart_GetFreeVoiceAddr
	stda16 12955, xwa
	stdi16 12939, 6

AccVoice_SetupAcc1_Return:
	ret

AccVoice_SetupAcc2:
	anddi8 12974, 15
	cpdi8 13029, 128
	jr nc, AccVoice_SetupAcc2_Free
	stdi8 13268, 8
	ldda8 a, 12966
	call AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	stda16 12941, xwa
	jr AccVoice_SetupAcc2_Return

AccVoice_SetupAcc2_Free:
	stdi8 13268, 8
	call AccPart_GetFreeVoiceAddr
	stda16 12957, xwa
	stdi16 12941, 6

AccVoice_SetupAcc2_Return:
	ret

AccVoice_SetupAcc3:
	anddi8 12975, 15
	cpdi8 13029, 128
	jr nc, AccVoice_SetupAcc3_Free
	stdi8 13268, 16
	ldda8 a, 12967
	call AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	stda16 12943, xwa
	jr AccVoice_SetupAcc3_Return

AccVoice_SetupAcc3_Free:
	stdi8 13268, 16
	call AccPart_GetFreeVoiceAddr
	stda16 12959, xwa
	stdi16 12943, 6

AccVoice_SetupAcc3_Return:
	ret

AccVoice_SetupAcc4:
	anddi8 12976, 15
	cpdi8 13029, 128
	jr nc, AccVoice_SetupAcc4_Free
	stdi8 13268, 32
	ldda8 a, 12968
	call AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	stda16 12945, xwa
	jrl AccVoice_SetupAcc4_Return

AccVoice_SetupAcc4_Free:
	stdi8 13268, 32
	call AccPart_GetFreeVoiceAddr
	stda16 12961, xwa
	stdi16 12945, 6

AccVoice_SetupAcc4_Return:
	ret

AccVoice_ResetAll:
	anddi8 12971, 15
	anddi8 12972, 15
	anddi8 12973, 15
	anddi8 12974, 15
	anddi8 12975, 15
	anddi8 12976, 15
	cpdi8 13029, 128
	jr c, AccVoice_Reset_UseStyle
	bitda 0, 13155
	jr z, AccVoice_Reset_UseSecondary
	calr AccVoice_Reassign
	jr AccVoice_Reset_SetMasks

AccVoice_Reset_UseSecondary:
	ldda32 xiy, 13011
	jr AccVoice_Reset_SelectMode

AccVoice_Reset_UseStyle:
	ldda32 xiy, 13006

AccVoice_Reset_SelectMode:
	ldw hl, 0x20
	bitda 0, 13066
	jr nz, AccVoice_Reset_LoadParams
	ldw hl, 0x22
	bitda 2, 13066
	jr nz, AccVoice_Reset_LoadParams
	ldw hl, 0x420

AccVoice_Reset_LoadParams:
	calr AccVoice_LoadAllParts
	cpdi8 13029, 128
	jr c, AccVoice_Reset_Extended
	ldda32 xiy, 13006
	call AccTuning_CopyAllPartsFromStyle
	jr AccVoice_Reset_ApplyAll

AccVoice_Reset_Extended:
	ldda8 a, 12963
	ldb w, 0x3
	bitda 3, 13066
	jr z, AccVoice_Reset_SetMode
	ldb w, 0x4

AccVoice_Reset_SetMode:
	call AccPart_GetVoiceParamOffsetTable
	call AccVoice_LoadTuningBlock

AccVoice_Reset_ApplyAll:
	ordi8 13100, 63

AccVoice_Reset_SetMasks:
	bitda 3, 13066
	jrl nz, AccVoice_Reset_Mode3
	bitda 2, 13066
	jr nz, AccVoice_Reset_Mode2
	anddi8 13066, 254
	ordi8 13078, 63
	xor a, a
	stda8 13074, a
	stda8 13075, a
	stda8 13079, a
	stda8 13080, a
	stda8 13076, a
	stda8 13077, a
	stda8 13149, a
	stda8 13096, a
	stda8 13098, a
	anddi8 12931, 251
	jrl AccVoice_Reset_Return

AccVoice_Reset_Mode2:
	anddi8 13066, 251
	ordi8 13079, 63
	xor a, a
	stda8 13074, a
	stda8 13075, a
	stda8 13078, a
	stda8 13080, a
	stda8 13076, a
	stda8 13077, a
	stda8 13149, a
	stda8 13096, a
	stda8 13098, a
	anddi8 12931, 251
	jr AccVoice_Reset_Return

AccVoice_Reset_Mode3:
	anddi8 13066, 247
	ordi8 13080, 63
	xor a, a
	stda8 13074, a
	stda8 13075, a
	stda8 13078, a
	stda8 13079, a
	stda8 13076, a
	stda8 13077, a
	stda8 13149, a
	stda8 13096, a
	stda8 13098, a
	anddi8 12931, 251

AccVoice_Reset_Return:
	ret

AccVoice_Reassign:
	bitda 3, 13066
	jrl nz, AccVoice_Reassign_Mode3
	bitda 2, 13066
	jr nz, AccVoice_Reassign_Mode2
	ldda8 a, 13029
	and a, 0x7F
	call AccPatch_SetVoiceParam
	cpda8 a, 13156
	jr z, AccVoice_Reassign_MatchA
	anddi8 64607, 251
	ldb e, 0x48
	ldb d, 0x5
	ldb w, 0x0
	ldb a, 0x0
	call Rhythm_QueuePartChangeEvent
	ldda32 xiy, 13006
	jr AccVoice_Reassign_Apply

AccVoice_Reassign_MatchA:
	ldda8 a, 13157
	call AccVoice_ResolveParamAddr
	jr AccVoice_Reassign_Apply

AccVoice_Reassign_Mode2:
	ldda8 a, 13029
	and a, 0x7F
	call AccPatch_SetVoiceParam
	ld xhl, 0xE46BB0
	bit_dri 1, 0x03, 0xEC, 0xE0
	jr z, AccVoice_Reassign_Fallback
	anddi8 64607, 247
	ldb e, 0x48
	ldb d, 0x5
	ldb w, 0x0
	ldb a, 0x0
	call Rhythm_QueuePartChangeEvent
	ldda32 xiy, 13006
	jr AccVoice_Reassign_Apply

AccVoice_Reassign_Mode3:
	ldda8 a, 13029
	and a, 0x7F
	call AccPatch_SetVoiceParam
	cpda8 a, 13158
	jr z, AccVoice_Reassign_MatchB
	anddi8 64608, 251
	ldb e, 0x48
	ldb d, 0x6
	ldb w, 0x0
	ldb a, 0x0
	call Rhythm_QueuePartChangeEvent
	ldda32 xiy, 13006
	jr AccVoice_Reassign_Apply

AccVoice_Reassign_MatchB:
	ldda8 a, 13159
	call AccVoice_ResolveParamAddr

AccVoice_Reassign_Apply:
	calr AccInit_AllPartPositions
	call AccTuning_CopyAllPartsFromStyle
	ordi8 13100, 63
	jr AccVoice_Reassign_Return

AccVoice_Reassign_Fallback:
	ldda32 xiy, 13011
	ldw hl, 0x22
	calr AccVoice_LoadAllParts
	xor xhl, xhl
	ldw hl, 0x126
	call AccVoice_LoadTuningBlock
	ordi8 13100, 63

AccVoice_Reassign_Return:
	ret

AccVoice_SplitPointSetup:
	anddi8 12971, 15
	anddi8 12972, 15
	anddi8 12973, 15
	anddi8 12974, 15
	anddi8 12975, 15
	anddi8 12976, 15
	cpdi8 13029, 128
	jr c, AccVoice_Split_UseStyle
	bitda 0, 13155
	jr z, AccVoice_Split_UseSecondary
	calr AccVoice_SplitReassign
	jr AccVoice_Split_SetForward

AccVoice_Split_UseSecondary:
	ldda32 xiy, 13011
	jr AccVoice_Split_LoadAndApply

AccVoice_Split_UseStyle:
	ldda32 xiy, 13006

AccVoice_Split_LoadAndApply:
	ldda8 a, 12963
	call AccVoice_ComputeParamAddr
	calr AccVoice_LoadAllParts
	ldda8 a, 12963
	call AccTuning_SetAllFromLookup
	cpdi8 13029, 128
	jr c, AccVoice_Split_StyleMode
	ldda32 xiy, 13006
	call AccTuning_CopyAllPartsFromStyle
	jr AccVoice_Split_Apply63

AccVoice_Split_StyleMode:
	ldda8 a, 12963
	ldb w, 0x2
	call AccPart_GetVoiceParamOffsetTable
	call AccVoice_LoadTuningBlock

AccVoice_Split_Apply63:
	ordi8 13100, 63

AccVoice_Split_SetForward:
	bitda 0, 13065
	jr z, AccVoice_Split_SetReverse
	anddi8 13065, 254
	ordi8 13074, 63
	xor a, a
	stda8 13078, a
	stda8 13079, a
	stda8 13080, a
	stda8 13075, a
	stda8 13076, a
	stda8 13077, a
	stda8 13149, a
	stda8 13096, a
	stda8 13098, a
	anddi8 12931, 251
	jr AccVoice_Split_Return

AccVoice_Split_SetReverse:
	anddi8 13065, 253
	ordi8 13075, 63
	xor a, a
	stda8 13078, a
	stda8 13079, a
	stda8 13080, a
	stda8 13074, a
	stda8 13076, a
	stda8 13077, a
	stda8 13149, a
	stda8 13096, a
	stda8 13098, a
	anddi8 12931, 251

AccVoice_Split_Return:
	ret

AccVoice_SplitReassign:
	bitda 0, 13065
	jr z, AccVoice_SplitReassign_Reverse
	ldda8 a, 13029
	and a, 0x7F
	call AccPatch_SetVoiceParam
	cpda8 a, 13160
	jr z, AccVoice_SplitReassign_MatchFwd
	anddi8 64607, 191
	ldb e, 0x48
	ldb d, 0x5
	ldb w, 0x0
	ldb a, 0x0
	call Rhythm_QueuePartChangeEvent
	ldda32 xiy, 13006
	jr AccVoice_SplitReassign_Apply

AccVoice_SplitReassign_MatchFwd:
	ldda8 a, 13161
	call AccVoice_ResolveParamAddr
	jr AccVoice_SplitReassign_Apply

AccVoice_SplitReassign_Reverse:
	ldda8 a, 13029
	and a, 0x7F
	call AccPatch_SetVoiceParam
	cpda8 a, 13162
	jr z, AccVoice_SplitReassign_MatchRev
	anddi8 64607, 127
	ldb e, 0x48
	ldb d, 0x5
	ldb w, 0x0
	ldb a, 0x0
	call Rhythm_QueuePartChangeEvent
	ldda32 xiy, 13006
	jr AccVoice_SplitReassign_Apply

AccVoice_SplitReassign_MatchRev:
	ldda8 a, 13163
	call AccVoice_ResolveParamAddr

AccVoice_SplitReassign_Apply:
	calr AccInit_AllPartPositions
	call AccTuning_CopyAllPartsFromStyle
	ordi8 13100, 63
	ret

AccVoice_LoadAllParts:
	ld_srib A, (xiy + 0x03d1)
	stda8 12933, a
	ldfr_werp HL, 0x3C
	stdi8 13268, 1
	call AccPart_GetParamAddr
	stda16 12935, xwa
	ldto_werp HL, 0x3C
	stdi8 13268, 2
	call AccPart_GetParamAddr
	stda16 12937, xwa
	ldto_werp HL, 0x3C
	stdi8 13268, 4
	call AccPart_GetParamAddr
	stda16 12939, xwa
	ldto_werp HL, 0x3C
	stdi8 13268, 8
	call AccPart_GetParamAddr
	stda16 12941, xwa
	ldto_werp HL, 0x3C
	stdi8 13268, 16
	call AccPart_GetParamAddr
	stda16 12943, xwa
	ldto_werp HL, 0x3C
	stdi8 13268, 32
	call AccPart_GetParamAddr
	stda16 12945, xwa
	ret

AccInit_AllPartPositions:
	stdi8 13268, 1
	call AccPart_GetFreeVoiceAddr
	stda16 12951, xwa
	stdi16 12935, 6
	stdi8 13268, 4
	call AccPart_GetFreeVoiceAddr
	stda16 12955, xwa
	stdi16 12939, 6
	stdi8 13268, 8
	call AccPart_GetFreeVoiceAddr
	stda16 12957, xwa
	stdi16 12941, 6
	stdi8 13268, 16
	call AccPart_GetFreeVoiceAddr
	stda16 12959, xwa
	stdi16 12943, 6
	stdi8 13268, 32
	call AccPart_GetFreeVoiceAddr
	stda16 12961, xwa
	stdi16 12945, 6
	stdi8 13268, 2
	call AccPart_GetFreeVoiceAddr
	stda16 12953, xwa
	stdi16 12937, 6
	ret

AccVoice_ThirdLayer:
	anddi8 12971, 15
	anddi8 12972, 15
	anddi8 12973, 15
	anddi8 12974, 15
	anddi8 12975, 15
	anddi8 12976, 15
	cpdi8 13029, 128
	jr c, AccVoice_ThirdLayer_Style
	bitda 0, 13155
	jr z, AccVoice_ThirdLayer_Secondary
	calr AccVoice_ThirdLayerReassign
	jr AccVoice_ThirdLayer_SetMasks

AccVoice_ThirdLayer_Secondary:
	ldda32 xiy, 13011
	jr AccVoice_ThirdLayer_SelectMode

AccVoice_ThirdLayer_Style:
	ldda32 xiy, 13006

AccVoice_ThirdLayer_SelectMode:
	ldw hl, 0x24
	bitda 0, 13067
	jr nz, AccVoice_ThirdLayer_LoadParams
	ldw hl, 0x424

AccVoice_ThirdLayer_LoadParams:
	calr AccVoice_LoadAllParts
	ldda8 a, 12963
	call AccTuning_SetAllFromLookup
	cpdi8 13029, 128
	jr c, AccVoice_ThirdLayer_StyleMode
	ldda32 xiy, 13006
	call AccTuning_CopyAllPartsFromStyle
	jr AccVoice_ThirdLayer_Apply

AccVoice_ThirdLayer_StyleMode:
	ldda8 a, 12963
	ldb w, 0x5
	bitda 1, 13067
	jr z, AccVoice_ThirdLayer_SetModeW
	ldb w, 0x6

AccVoice_ThirdLayer_SetModeW:
	call AccPart_GetVoiceParamOffsetTable
	call AccVoice_LoadTuningBlock

AccVoice_ThirdLayer_Apply:
	ordi8 13100, 63

AccVoice_ThirdLayer_SetMasks:
	bitda 0, 13067
	jr z, AccVoice_ThirdLayer_Reverse
	anddi8 13067, 254
	ordi8 13076, 63
	xor a, a
	stda8 13078, a
	stda8 13079, a
	stda8 13080, a
	stda8 13074, a
	stda8 13075, a
	stda8 13077, a
	stda8 13149, a
	jr AccVoice_ThirdLayer_Return

AccVoice_ThirdLayer_Reverse:
	anddi8 13067, 253
	ordi8 13077, 63
	xor a, a
	stda8 13078, a
	stda8 13079, a
	stda8 13080, a
	stda8 13074, a
	stda8 13075, a
	stda8 13076, a
	stda8 13149, a

AccVoice_ThirdLayer_Return:
	ret

AccVoice_ThirdLayerReassign:
	bitda 0, 13067
	jr z, AccVoice_ThirdReassign_Reverse
	ldda8 a, 13029
	and a, 0x7F
	call AccPatch_SetVoiceParam
	cpda8 a, 13164
	jr z, AccVoice_ThirdReassign_MatchFwd
	anddi8 64607, 239
	ldb e, 0x48
	ldb d, 0x5
	ldb w, 0x0
	ldb a, 0x0
	call Rhythm_QueuePartChangeEvent
	ldda32 xiy, 13006
	jr AccVoice_ThirdReassign_Apply

AccVoice_ThirdReassign_MatchFwd:
	ldda8 a, 13165
	call AccVoice_ResolveParamAddr
	jr AccVoice_ThirdReassign_Apply

AccVoice_ThirdReassign_Reverse:
	ldda8 a, 13029
	and a, 0x7F
	call AccPatch_SetVoiceParam
	cpda8 a, 13166
	jr z, AccVoice_ThirdReassign_MatchRev
	anddi8 64607, 223
	ldb e, 0x48
	ldb d, 0x5
	ldb w, 0x0
	ldb a, 0x0
	call Rhythm_QueuePartChangeEvent
	ldda32 xiy, 13006
	jr AccVoice_ThirdReassign_Apply

AccVoice_ThirdReassign_MatchRev:
	ldda8 a, 13167
	call AccVoice_ResolveParamAddr

AccVoice_ThirdReassign_Apply:
	calr AccInit_AllPartPositions
	call AccTuning_CopyAllPartsFromStyle
	ordi8 13100, 63
	ret

AccBuf_WriteAllNotesOff:
	ld xhl, 0x2A94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	stib_dri 0x07, 0xEC, 0xF4, 0x9F
	call RingBuf_AdvanceIndex
	ldda8 a, 13034
	stda8 13358, a
	call RhythmAccent_UpdateRingBufPosition
	ldb a, 0x7F
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	call RingBuf_AdvanceIndex
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	call RingBuf_AdvanceIndex
	ld (xhl + 4), iy
	ret

AccBuf_AllNotesOffPadding:
	.byte 0x00, 0x00

AccBuf_ResetAll4:
	ld xhl, 0x2C94
	calr AccBuf_DrainAndReset
	ld xhl, 0x2D94
	calr AccBuf_DrainAndReset
	ld xhl, 0x2E94
	calr AccBuf_DrainAndReset
	ld xhl, 0x2F94
	calr AccBuf_DrainAndReset
	ret

AccBuf_DrainAndReset:
	ld iy, (xhl + 6)
	ld bc, (xhl + 2)

AccBuf_DrainReset_Loop:
	cp iy, (xhl + 4)
	jr z, AccBuf_DrainReset_Done
	ld_srib3 A, 0x07, 0xEC, 0xF4
	cp a, 0xD0
	jr z, AccBuf_DrainReset_D0Found
	call RingBuf_AdvanceIndex
	jr AccBuf_DrainReset_Loop

AccBuf_DrainReset_D0Found:
	call RingBuf_AdvanceIndex
	call RingBuf_AdvanceIndex
	ld_srib3 A, 0x07, 0xEC, 0xF4
	cps a, 2
	jr nz, AccBuf_DrainReset_Sub1
	call RingBuf_AdvanceIndex
	stib_dri 0x07, 0xEC, 0xF4, 0x40
	call RingBuf_AdvanceIndex
	jr AccBuf_DrainReset_Loop

AccBuf_DrainReset_Sub1:
	cps a, 1
	jr nz, AccBuf_DrainReset_Sub3
	call RingBuf_AdvanceIndex
	stib_dri 0x07, 0xEC, 0xF4, 0x00
	call RingBuf_AdvanceIndex
	jr AccBuf_DrainReset_Loop

AccBuf_DrainReset_Sub3:
	cps a, 3
	jr nz, AccBuf_DrainReset_Sub5
	call RingBuf_AdvanceIndex
	stib_dri 0x07, 0xEC, 0xF4, 0x00
	call RingBuf_AdvanceIndex
	jr AccBuf_DrainReset_Loop

AccBuf_DrainReset_Sub5:
	cps a, 5
	jr nz, AccBuf_DrainReset_Other
	call RingBuf_AdvanceIndex
	stib_dri 0x07, 0xEC, 0xF4, 0x7F
	call RingBuf_AdvanceIndex
	jr AccBuf_DrainReset_Loop

AccBuf_DrainReset_Other:
	call RingBuf_AdvanceIndex
	jr AccBuf_DrainReset_Loop

AccBuf_DrainReset_Done:
	ret

AccTiming_CallHelper:
	bitda 1, 12932
	jr z, AccTiming_HelperReturn
	call SeqEvt_CallTimingHelper
	call Voice_UpdatePlayModeState
	call AccChord_ReadAndStoreKeys
	call AccChord_CompareAndSetDirty
	call Rhythm_CompareAndTrigger

AccTiming_HelperReturn:
	ret

AccVoice_SelectByMask:
	cpdi8 13029, 128
	jr c, AccVoice_SelectByMask_Default
	ldfr_berp W, 0x31
	andda8 w, 13079
	jr nz, AccVoice_SelectByMask_Default
	bitda 0, 13155
	jr nz, AccVoice_SelectByMask_Direct
	ldda8 a, 13078
	orda8 a, 13080
	orda8 a, 13074
	orda8 a, 13075
	orda8 a, 13076
	orda8 a, 13077
	orda8 a, 13096
	and_berp A, 0x31
	jr nz, AccVoice_SelectByMask_Default

AccVoice_SelectByMask_Direct:
	calr AccWave_BankResolve
	jr AccVoice_SelectReturn

AccVoice_SelectByMask_Default:
	ldda8 a, 12933
	call AccVoice_TableLookup

AccVoice_SelectReturn:
	ret

AccWave_BankResolve_Short:
	cp	iz, 65534
	jr	nz, 7
	ld	xhl, 613312
	jr	13
	extz	xiz
	ld	xhl, xiz
	sla	xhl, 8
	add	xhl, 613376
	ret

AccWave_BankResolve:
	push xwa
	push xix
	push xiz
	cp iz, 0xFFFE
	jr nz, AccWave_BankResolve_Normal
	ld xhl, 0x95BC0
	jr AccWave_BankResolve_Epilogue

AccWave_BankResolve_Normal:
	ld wa, iz
	and iz, 0xFFF
	extz xiz
	ld xhl, xiz
	sla xhl, 8
	srl wa, 10
	ld xix, 0xF59089
	ld_sril3 XIX, 0x07, 0xF0, 0xE0
	add xhl, xix

AccWave_BankResolve_Epilogue:
	pop xiz
	pop xix
	pop xwa
	ret

AccWave_BankTable:
	nop
	pop	xix
	push 0
	nop
	.byte 0x14
	ldw	wa, 0
	.byte 0xac, 0x31, 0x00
	nop
	.byte 0x14
	ldw	hl, 0
	.byte 0xac, 0x34, 0x00
	nop
	.byte 0x14
	ldw	iz, 0
	.byte 0xac, 0x37, 0x00
	nop
	.byte 0x14
	push	xbc
	nop

AccVoice_TableLookup:
	call AccVoice_TableLookup_Inner
	add xhl, 0x8000
	ret

AccVoice_TableLookup_Inner:
	cp a, 0x3F
	jr ule, AccVoice_TableLookup_Compute
	xor a, a

AccVoice_TableLookup_Compute:
	xor xhl, xhl
	xor w, w
	ld hl, wa
	sll xhl, 2
	add xhl, 0xF590D1
	ld xhl, (xhl)
	addda32 xhl, 12919
	ret

AccVoice_OffsetTable:
	nop
	nop
	ld	xwa, 1090519040
	nop
	nop
	nop
	ld	xde, 1124073472
	nop
	nop
	nop
	ld	xix, 1157627904
	nop
	nop
	nop
	ld	xiz, 1191182336
	nop
	nop
	nop
	popw	wa
	nop
	nop
	nop
	popw	bc
	nop
	nop
	nop
	popw	de
	nop
	nop
	nop
	popw	hl
	nop
	nop
	nop
	popw	ix
	nop
	nop
	nop
	popw	iy
	nop
	nop
	nop
	popw	iz
	nop
	nop
	nop
	.byte 0x4f
	nop
	nop
	nop
	.byte 0x50
	nop
	nop
	nop
	.byte 0x51
	nop
	nop
	nop
	.byte 0x52
	nop
	nop
	nop
	.byte 0x53
	nop
	nop
	nop
	.byte 0x54
	nop
	nop
	nop
	.byte 0x55
	nop
	nop
	nop
	.byte 0x56
	nop
	nop
	nop
	.byte 0x57
	nop
	nop
	nop
	pop	xwa
	nop
	nop
	nop
	pop	xbc
	nop
	nop
	nop
	pop	xde
	nop
	nop
	nop
	pop	xhl
	nop
	nop
	nop
	pop	xix
	nop
	nop
	nop
	pop	xiy
	nop
	nop
	nop
	pop	xiz
	nop
	nop
	nop
	pop	xsp
	nop
	nop
	nop
	jr	f, 0
	nop
	nop
	jr	lt, 0
	nop
	nop
	jr	le, 0
	nop
	nop
	jr	ule, 0
	nop
	nop
	.byte 0x64, 0x00
	nop
	nop
	jr	mi, 0
	nop
	nop
	jr	z, 0
	nop
	nop
	jr	c, 0
	nop
	nop
	jr	0
	nop
	nop
	jr	ge, 0
	nop
	nop
	jr	gt, 0
	nop
	nop
	jr	ugt, 0
	nop
	nop
	.byte 0x6c, 0x00
	nop
	nop
	jr	pl, 0
	nop
	nop
	jr	nz, 0
	nop
	nop
	jr	nc, 0
	nop
	nop
	jrl	f, 0
	nop
	jrl	lt, 0
	nop
	jrl	le, 0
	nop
	jrl	ule, 0
	nop
	.byte 0x74, 0x00, 0x00
	nop
	jrl	mi, 0
	nop
	jrl	z, 0
	nop
	jrl	c, 0
	nop
	jrl	0
	nop
	jrl	ge, 0
	nop
	jrl	gt, 0
	nop
	jrl	ugt, 0
	nop
	.byte 0x7c, 0x00, 0x00
	nop
	jrl	pl, 0
	nop
	jrl	nz, 0
	nop
	.byte 0x7f, 0x00

AccState_CollectAll:
	bitda 3, 1054
	jrl nz, AccState_CollectReturn
	bitda 2, 1054
	jrl z, AccState_CollectReturn
	ld xhl, 0x3094
	xor iy, iy
	ld_srib3 A, 0x07, 0xEC, 0xF4

AccState_CollectKbd1_Loop:
	or_srib_rm A, 0x07, 0xEC, 0xF4
	add iy, 0x6
	cp iy, 0x30
	jr c, AccState_CollectKbd1_Loop
	ld xhl, 0x30C4
	xor iy, iy

AccState_CollectKbd2_Loop:
	or_srib_rm A, 0x07, 0xEC, 0xF4
	add iy, 0x6
	cp iy, 0x30
	jr c, AccState_CollectKbd2_Loop
	ld xhl, 0x30F4
	xor iy, iy

AccState_CollectAcc1_Loop:
	or_srib_rm A, 0x07, 0xEC, 0xF4
	add iy, 0x9
	cp iy, 0x48
	jr c, AccState_CollectAcc1_Loop
	ld xhl, 0x313C
	xor iy, iy

AccState_CollectAcc2_Loop:
	or_srib_rm A, 0x07, 0xEC, 0xF4
	add iy, 0x9
	cp iy, 0x48
	jr c, AccState_CollectAcc2_Loop
	ld xhl, 0x3184
	xor iy, iy

AccState_CollectAcc3_Loop:
	or_srib_rm A, 0x07, 0xEC, 0xF4
	add iy, 0x9
	cp iy, 0x48
	jr c, AccState_CollectAcc3_Loop
	ld xhl, 0x31CC
	xor iy, iy

AccState_CollectAcc4_Loop:
	or_srib_rm A, 0x07, 0xEC, 0xF4
	add iy, 0x9
	cp iy, 0x48
	jr c, AccState_CollectAcc4_Loop
	bit 7, a
	jr nz, AccState_CollectReturn
	cpdi16 10420, 0
	jr nz, AccState_CollectAcc4_Active
	cpdi16 10408, 0
	jr nz, AccState_CollectAcc4_Active
	call AccWrap_PlayModeStopSync
	jr AccState_Apply

AccState_CollectAcc4_Active:
	call AccWrap_PlayModeStartPlay

AccState_Apply:
	call AccInit_CallF435A9
	ldda8 a, 52959
	stda8 36162, a
	ldda8 a, 52960
	stda8 36160, a
	call AccDisplay_RefreshIfDiskActive
	anddi8 64607, 207
	anddi8 12931, 251
	xor a, a
	stda8 13076, a
	stda8 13077, a
	stda8 13074, a
	stda8 13075, a
	stda8 13078, a
	stda8 13079, a
	stda8 13080, a
	ordi8 13471, 2

AccState_CollectReturn:
	ret

AccState_ScanLookupTable:
	nop
	.byte 0x01
	push_sr
	pop_sr
	.byte 0x04
	nop
	.byte 0x01
	push_sr
	pop_sr
	.byte 0x04
	nop
	.byte 0x01
	push_sr
	pop_sr
	.byte 0x04
	nop
	.byte 0x01
	push_sr
	pop_sr
	.byte 0x04
	nop
	nop
	nop
	nop
	.zero 10

AccVoice_ScanForD3:
	ld_srib3 A, 0x07, 0xEC, 0xF4
	cp a, 0x83
	jr z, AccVoice_ScanDone2
	cp a, 0xD3
	jr nz, AccVoice_ScanSkip
	call AccBuf_Advance
	call AccBuf_Advance
	ld_srib3 A, 0x07, 0xEC, 0xF4
	stda8 13107, a

AccVoice_ScanSkip:
	call AccBuf_Advance
	jr AccVoice_ScanForD3

AccVoice_ScanDone2:
	ret

AccVoice_SetupByteData:
	stdi8	13268, 4
	ldda8	e, 13129
	stdi8	13107, 0
	ldda32	xiy, 13006
	cpda8	e, 12965
	jr	z, 28
	ld	a, e
	call	16082302
	call	16084176
	ld	iy, wa
	ldda8	a, 12933
	call	16093353
	call	16093935
	inc	1, e
	jr	-38
	ret
	stdi8	13268, 8
	ldda8	e, 13129
	stdi8	13107, 0
	ldda32	xiy, 13006
	cpda8	e, 12966
	jr	z, 28
	ld	a, e
	call	16082302
	call	16084176
	ld	iy, wa
	ldda8	a, 12933
	call	16093353
	call	16093935
	inc	1, e
	jr	-38
	ret
	stdi8	13268, 8
	ldda8	e, 13129
	stdi8	13107, 0
	ldda32	xiy, 13006
	cpda8	e, 12967
	jr	z, 28
	ld	a, e
	call	16082302
	call	16084176
	ld	iy, wa
	ldda8	a, 12933
	call	16093353
	call	16093935
	inc	1, e
	jr	-38
	ret
	stdi8	13268, 8
	ldda8	e, 13129
	stdi8	13107, 0
	ldda32	xiy, 13006
	cpda8	e, 12968
	jr	z, 28
	ld	a, e
	call	16082302
	call	16084176
	ld	iy, wa
	ldda8	a, 12933
	call	16093353
	call	16093935
	inc	1, e
	jr	-38
	ret
	ld	a, (xiy+977)
	stda8	12933, a
	stdi8	13268, 1
	ldda8	a, 12963
	call	16082302
	call	16084176
	stda16	12935, wa
	stdi8	13268, 2
	ldda8	a, 12964
	call	16082302
	call	16084176
	stda16	12937, wa
	stdi8	13268, 4
	ldda8	a, 12965
	call	16082302
	call	16084176
	stda16	12939, wa
	stdi8	13268, 8
	ldda8	a, 12966
	call	16082302
	call	16084176
	stda16	12941, wa
	stdi8	13268, 16
	ldda8	a, 12967
	call	16082302
	call	16084176
	stda16	12943, wa
	stdi8	13268, 32
	ldda8	l, 12968
	call	16082302
	call	16084176
	stda16	12945, wa
	ret

AccFlags_Aggregate:
	anddi8 13094, 192
	anddi8 13095, 192
	calr AccBuf_ResetAll4Positions
	bitda 0, 13070
	jr z, AccFlags_BuildIndex
	ordi8 13069, 1
	bitda 1, 13070
	jr z, AccFlags_CheckDecay
	cpdi8 13114, 0
	jr z, AccFlags_BuildIndex
	decdi8 1, 13114
	jr AccFlags_BuildIndex

AccFlags_CheckDecay:
	cpdi8 13114, 3
	jr z, AccFlags_BuildIndex
	incdi8 1, 13114

AccFlags_BuildIndex:
	xor w, w
	ldda8 a, 13066
	and a, 0xD
	jr z, AccFlags_CheckDir65
	or w, 0x1

AccFlags_CheckDir65:
	ldda8 a, 13065
	and a, 0x3
	jr z, AccFlags_CheckDir67
	or w, 0x2

AccFlags_CheckDir67:
	ldda8 a, 13067
	and a, 0x3
	jr z, AccFlags_CheckNoteOn
	or w, 0x4

AccFlags_CheckNoteOn:
	bitda 0, 13068
	jr z, AccFlags_CheckSync69
	or w, 0x8
	bitda 6, 13424
	jr z, AccFlags_PedalBit7
	or w, 0x2
	ordi8 13065, 1

AccFlags_PedalBit7:
	bitda 7, 13424
	jr z, AccFlags_CheckSync69
	or w, 0x2
	ordi8 13065, 2

AccFlags_CheckSync69:
	bitda 0, 13069
	jr z, AccFlags_CheckSync71
	or w, 0x8

AccFlags_CheckSync71:
	bitda 0, 13071
	jr z, AccFlags_Dispatch
	or w, 0x8

AccFlags_Dispatch:
	and w, 0xF
	sla w, 2
	ld xhl, 0xF59517
	ld_sril3 XWA, 0x03, 0xEC, 0xE1
	jp (xwa)


AccFlags_JumpTable:
	.long AccFlags_Handler0
	.long AccFlags_Handler1
	.long AccFlags_Handler2
	.long AccFlags_Handler2
	.long AccFlags_Handler4
	.long AccFlags_Handler4
	.long AccFlags_Handler4
	.long AccFlags_Handler4
	.long AccFlags_Handler0
	.long AccFlags_Handler9
	.long AccFlags_Handler10
	.long AccFlags_Handler10
	.long AccFlags_Handler8
	.long AccFlags_Handler8
	.long AccFlags_Handler8
	.long AccFlags_Handler8
AccFlags_Handler0:
	call	16090879
	call	16091158
	.byte 0xc1, 0x16, 0x33, 0x3c, 0xc0, 0xc1, 0x17, 0x33, 0x3c, 0xc0, 0xc1, 0x18, 0x33, 0x3c, 0xc0, 0xc1, 0x12, 0x33, 0x3c, 0xc0, 0xc1, 0x13, 0x33, 0x3c, 0xc0
	jr	62
AccFlags_Handler4:
	call	16093150
	call	16095108
	call	16092600
	jr	48
AccFlags_Handler8:
	call	16090879
	call	16093150
	call	16095108
	call	16092600
	jr	t, 0x1e
AccFlags_Handler2:
	call	16092034
	jr	24
AccFlags_Handler10:
	call	16090879
	call	16092034
	jr	t, 0x0e
AccFlags_Handler1:
	call	16091534
	jr	8
AccFlags_Handler9:
	call	16090879
	call	16091534
	call	16078240
	call	16073734
	calr	59
	ret

AccBuf_ResetAll4Positions:
	ld xhl, 0x2C94
	calr AccBuf_ResetOnePosition
	ld xhl, 0x2D94
	calr AccBuf_ResetOnePosition
	ld xhl, 0x2E94
	calr AccBuf_ResetOnePosition
	ld xhl, 0x2F94
	calr AccBuf_ResetOnePosition
	ret

AccBuf_ResetOnePosition:
	ld (xhl + 256), 0xA
	ld (xhl + 2), 0xFF
	ldw wa, 0xA
	ldw bc, 0xA
	ei 6
	ld (xhl + 4), wa
	ld (xhl + 6), bc
	ei 0
	ret

AccBuf_ResetByteData:
	ldb	a, 0
	ld	xhl, 12532
	xor	iy, iy
	.byte 0xf3, 0x07, 0xec, 0xf4, 0x41
	add	iy, 9
	cp	iy, 72
	jr	c, -15
	ld	xhl, 12604
	xor	iy, iy
	.byte 0xf3, 0x07, 0xec, 0xf4, 0x41
	add	iy, 9
	cp	iy, 72
	jr	c, -15
	ld	xhl, 12676
	xor	iy, iy
	.byte 0xf3, 0x07, 0xec, 0xf4, 0x41
	add	iy, 9
	cp	iy, 72
	jr	c, -15
	ld	xhl, 12748
	xor	iy, iy
	.byte 0xf3, 0x07, 0xec, 0xf4, 0x41
	add	iy, 9
	cp	iy, 72
	jr	c, -15
	ret

AccNote_FlushAll:
	ldda8 a, 13100
	and a, 0x3F
	jr z, AccNote_FlushReturn
	call RhythmPart_CopyData
	call RhythmPart1_ProcessAccentData
	ldb a, 0x1
	stda8 13036, a
	call RhythmPart2_ProcessAccentData
	call AccVoice_LoadRhythmParams_Part3
	call AccVoice_LoadRhythmParams_Part4
	call AccVoice_LoadRhythmParams_Part5
	anddi8 13100, 192

AccNote_FlushReturn:
	ret

AccTempo_CalcPosition:
	ldb a, 0x5F
	ldda8 w, 1112
	dec 1, w
	call AccVoice_LookupTableAddress
	ldda16 xbc, 12925
	ldda8 w, 12981
	dec 1, w
	call AccTempo_PositionCompare
	stda8 13036, a
	stda8 13034, a
	ret

AccInit_FullReInit:
	call Rhythm_SendNoteOnMax
	call AccompVoice_BulkReadRegisters
	calr AccBuf_WriteAllNotesOff
	call Rhythm_SendChanPressure
	calr AccBuf_ResetAll4
	ldda8 a, 13074
	orda8 a, 13075
	and a, 0x3F
	jr z, AccInit_ReInit_CheckNoteOn
	bitda 0, 13057
	jr z, AccInit_ReInit_CheckNoteOn
	ordi8 13068, 1
	ldda8 a, 13074
	and a, 0x3F
	jr z, AccInit_ReInit_AdjustDecay
	cpdi8 13114, 0
	jr z, AccInit_ReInit_CheckNoteOn
	decdi8 1, 13114
	jr AccInit_ReInit_CheckNoteOn

AccInit_ReInit_AdjustDecay:
	cpdi8 13114, 3
	jr z, AccInit_ReInit_CheckNoteOn
	incdi8 1, 13114

AccInit_ReInit_CheckNoteOn:
	bitda 0, 13068
	jr z, AccInit_ReInit_CheckModes
	ldda8 a, 13094
	and a, 0x3F
	jr nz, AccInit_ReInit_CheckModes
	calr AccStyle_Init
	calr AccVoice_SetupAllParts
	ldda8 a, 1075
	stda8 1112, a

AccInit_ReInit_CheckModes:
	ldda8 a, 13066
	and a, 0xD
	jr z, AccInit_ReInit_CheckSplit
	calr AccVoice_ResetAll

AccInit_ReInit_CheckSplit:
	ldda8 a, 13065
	and a, 0x3
	jr nz, AccInit_ReInit_ApplySplit
	bitda 6, 13424
	jr z, AccInit_ReInit_CheckPedalBit7
	ordi8 13065, 1
	jr AccInit_ReInit_ApplySplit

AccInit_ReInit_CheckPedalBit7:
	bitda 7, 13424
	jr z, AccInit_ReInit_CheckThird
	ordi8 13065, 2

AccInit_ReInit_ApplySplit:
	calr AccVoice_SplitPointSetup

AccInit_ReInit_CheckThird:
	ldda8 a, 13067
	and a, 0x3
	jr z, AccInit_ReInit_ClearHighBits
	calr AccTiming_CallHelper
	call AccInit_ResetSongCounter
	calr AccVoice_ThirdLayer

AccInit_ReInit_ClearHighBits:
	anddi8 12971, 240
	anddi8 12972, 240
	anddi8 12973, 240
	anddi8 12974, 240
	anddi8 12975, 240
	anddi8 12976, 240
	calr AccSeq_DualPartScan
	bitda 6, 13044
	jr nz, AccInit_ReInit_SetDirty
	calr AccSeq_FourChannelScan

AccInit_ReInit_SetDirty:
	ordi8 13100, 128
	ret

AccInit_ResetSongCounter:
	cpdi8 13026, 0
	jr nz, AccInit_ResetSong_Store
	call SeqVoice_SendNoteOffAndFlush

AccInit_ResetSong_Store:
	stdi8 13026, 0
	ret

AccInit_CallF435A9:
	call SeqVoice_SendNoteOffAndFlush
	ret

AccTuning_CheckChange:
	cpdi8 13029, 128
	jr nc, AccTuning_ChangeReturn
	ldda8 a, 13201
	xorda8 a, 13202
	bit 0, a
	jr z, AccTuning_ChangeReturn
	ordi8 13203, 1

AccTuning_ChangeReturn:
	ret

AccTuning_LoadFromROM:
	push xwa
	push xhl
	call AccHelper_ComputeVoiceOffset
	add xhl, 0x1E7810
	bitm 7, (xhl + 1)
	jrl z, AccTuning_LoadReturn
	ld a, (xhl + 4)
	stda8 12884, a
	ld a, (xhl + 5)
	ld w, a
	and w, 0x7F
	stda8 12885, w
	and a, 0x80
	srl a, 7
	stda8 12887, a
	ld a, (xhl + 6)
	stda8 12891, a
	ld a, (xhl + 7)
	ld w, a
	and w, 0x7F
	stda8 12892, w
	and a, 0x80
	srl a, 7
	stda8 12894, a
	ld a, (xhl + 8)
	stda8 12898, a
	ld a, (xhl + 9)
	ld w, a
	and w, 0x7F
	stda8 12899, w
	and a, 0x80
	srl a, 7
	stda8 12901, a
	ld a, (xhl + 2)
	stda8 12877, a
	ld a, (xhl + 3)
	ld w, a
	and w, 0x7F
	stda8 12878, w
	and a, 0x80
	srl a, 7
	stda8 12880, a
	ld a, (xhl + 256)
	stda8 12870, a
	ld a, (xhl + 1)
	and a, 0x7F
	stda8 12871, a

AccTuning_LoadReturn:
	pop xhl
	pop xwa
	ret

AccTuning_LoadMaster:
	call AccHelper_ComputeVoiceOffset
	add xhl, 0x1E7810
	bitm 7, (xhl + 1)
	jr z, AccTuning_LoadMasterReturn
	ld a, (xhl + 256)
	stda8 12870, a
	ld a, (xhl + 1)
	and a, 0x7F
	stda8 12871, a

AccTuning_LoadMasterReturn:
	ret

AccTuning_LoadCoarse:
	call AccHelper_ComputeVoiceOffset
	add xhl, 0x1E7810
	bitm 7, (xhl + 1)
	jr z, AccTuning_LoadCoarseReturn
	ld a, (xhl + 2)
	stda8 12877, a
	ld a, (xhl + 3)
	ld w, a
	and w, 0x7F
	stda8 12878, w
	and a, 0x80
	srl a, 7
	stda8 12880, a

AccTuning_LoadCoarseReturn:
	ret

AccTuning_LoadFine:
	call AccHelper_ComputeVoiceOffset
	add xhl, 0x1E7810
	bitm 7, (xhl + 1)
	jr z, AccTuning_LoadFineReturn
	ld a, (xhl + 4)
	stda8 12884, a
	ld a, (xhl + 5)
	ld w, a
	and w, 0x7F
	stda8 12885, w
	and a, 0x80
	srl a, 7
	stda8 12887, a

AccTuning_LoadFineReturn:
	ret

AccTuning_LoadOctave:
	call AccHelper_ComputeVoiceOffset
	add xhl, 0x1E7810
	bitm 7, (xhl + 1)
	jr z, AccTuning_LoadOctaveReturn
	ld a, (xhl + 6)
	stda8 12891, a
	ld a, (xhl + 7)
	ld w, a
	and w, 0x7F
	stda8 12892, w
	and a, 0x80
	srl a, 7
	stda8 12894, a

AccTuning_LoadOctaveReturn:
	ret

AccTuning_LoadTranspose:
	call AccHelper_ComputeVoiceOffset
	add xhl, 0x1E7810
	bitm 7, (xhl + 1)
	jr z, AccTuning_LoadTransposeReturn
	ld a, (xhl + 8)
	stda8 12898, a
	ld a, (xhl + 9)
	ld w, a
	and w, 0x7F
	stda8 12899, w
	and a, 0x80
	srl a, 7
	stda8 12901, a

AccTuning_LoadTransposeReturn:
	ret

AccTuning_ApplyChange:
	bitda 0, 13203
	jrl z, AccTuning_ApplyReturn
	call AccHelper_ComputeVoiceOffset
	add xhl, 0x1E7810
	bitda 0, 13201
	jr z, AccTuning_ApplyChange_ClearBit
	ormi8 (xhl + 1), 0x80
	jr AccTuning_ApplyChange_SelectMode

AccTuning_ApplyChange_ClearBit:
	andmi8 (xhl + 1), 0x7F

AccTuning_ApplyChange_SelectMode:
	ldda8 a, 13078
	orda8 a, 13079
	and a, 0x3F
	jrl nz, AccTuning_Mode_078
	ldda8 a, 13080
	and a, 0x3F
	jr nz, AccTuning_Mode_080
	ldda8 a, 13076
	and a, 0x3F
	jr nz, AccTuning_Mode_076
	orda8 a, 13077
	and a, 0x3F
	jr nz, AccTuning_Mode_077
	ldda8 a, 13074
	orda8 a, 13075
	and a, 0x3F
	jr nz, AccTuning_Mode_074
	ldda8 a, 13149
	and a, 0x3F
	jr nz, AccTuning_Mode_149
	jr AccTuning_Mode_None

AccTuning_Mode_078:
	ldb w, 0x3
	jr AccTuning_ApplyVoice

AccTuning_Mode_080:
	ldb w, 0x4
	jr AccTuning_ApplyVoice

AccTuning_Mode_076:
	ldb w, 0x5
	jr AccTuning_ApplyVoice

AccTuning_Mode_077:
	ldb w, 0x6
	jr AccTuning_ApplyVoice

AccTuning_Mode_074:
	ldb w, 0x2
	jr AccTuning_ApplyVoice

AccTuning_Mode_149:
	ldb w, 0x1
	jr AccTuning_ApplyVoice

AccTuning_Mode_None:
	ldb w, 0x0

AccTuning_ApplyVoice:
	ldda8 a, 12963
	ldda32 xiy, 13006
	call AccPart_GetVoiceParamOffsetTable
	call AccVoice_LoadTuningBlock
	ordi8 13100, 63
	ordi8 13100, 128

AccTuning_ApplyReturn:
	anddi8 13203, 254
	ret

AccTuning_Toggle:
	cpdi8 13029, 128
	jr nc, AccTuning_Toggle_NoStyle
	ldda8 a, 13201
	xorda8 a, 13202
	bit 0, a
	jr z, AccTuning_Toggle_CheckDirty
	call AccHelper_ComputeVoiceOffset
	add xhl, 0x1E7810
	bitda 0, 13201
	jr z, AccTuning_Toggle_ClearBit
	ormi8 (xhl + 1), 0x80
	jr AccTuning_Toggle_SetFlag

AccTuning_Toggle_ClearBit:
	andmi8 (xhl + 1), 0x7F

AccTuning_Toggle_SetFlag:
	ordi8 13115, 1
	jr AccTuning_Toggle_Return

AccTuning_Toggle_CheckDirty:
	bitda 0, 13203
	jr z, AccTuning_Toggle_Return
	anddi8 13203, 254
	ordi8 13115, 1
	jr AccTuning_Toggle_Return

AccTuning_Toggle_NoStyle:
	anddi8 13201, 254
	call AccTuning_LEDOff

AccTuning_Toggle_Return:
	ret

AccTuning_SaveState:
	ldda8 a, 13201
	stda8 13202, a
	ret

AccTuning_Init:
	push xwa
	push xhl
	cpdi8 13029, 128
	jr nc, AccTuning_Init_NoTuning
	call AccHelper_ComputeVoiceOffset
	add xhl, 0x1E7810
	bitm 7, (xhl + 1)
	jr z, AccTuning_Init_NoTuning
	ordi8 13201, 1
	call AccTuning_LEDOn
	ldda8 a, 13201
	stda8 13202, a
	jr AccTuning_Init_Epilogue

AccTuning_Init_NoTuning:
	anddi8 13201, 254
	call AccTuning_LEDOff
	ldda8 a, 13201
	stda8 13202, a

AccTuning_Init_Epilogue:
	pop xhl
	pop xwa
	ret

AccTuning_DisableIfNoStyle:
	cpdi8 13029, 128
	jr c, AccTuning_DisableReturn
	anddi8 13201, 254
	call AccTuning_LEDOff

AccTuning_DisableReturn:
	ret

AccTuning_LEDOn:
	stdi8 13200, 1
	ldb a, 0x4A
	call CtrlPanel_SetIndicatorBit
	ret

AccTuning_LEDOff:
	stdi8 13200, 0
	ldb a, 0x4A
	call CtrlPanel_SetIndicatorBit
	ret

AccWrap_JumpTable:
	jp	16095894
	jp	16095893
	jp	16095893
	jp	16095893
	jp	16095893
	ret
	ret
AccWrap_ReplayStop:
	jp	16096032
AccWrap_ReplayStopAlt:
	jp	16096111

AccWrap_AutoPlayCheck:
	push xiz
	call AccAutoPlay_NoteDispatch
	pop xiz
	ret

AccWrap_PlayModeByteData:
	jp	16101542
	jp	16100660

AccWrap_DeferredAction:
	jp AccAutoPlay_DeferredAction

AccWrap_AutoPlayStateMachine:
	push xiz
	call AccAutoPlay_StateMachine
	pop xiz
	ret

AccWrap_PlayModeDispatch:
	push xiz
	call AccPlayMode_Dispatch
	pop xiz
	ret

AccWrap_PlayModeStart:
	push xiz
	call AccPlayMode_StartPlayFull
	pop xiz
	ret

AccWrap_PlayModeStopData:
	jp	16101298

AccWrap_PlayModeStartAccPlay:
	jp AccPlayMode_StartAccPlayFull

AccWrap_PlayModeStopSync:
	jp AccPlayMode_StopToSync2

AccWrap_PlayModeStopExpr:
	push xiz
	call AccPlayMode_StopExprD
	pop xiz
	ret

AccWrap_PlayModeStartPlay:
	push xiz
	call AccPlayMode_StartPlay2
	pop xiz
	ret

AccWrap_ReplaySavedPedal:
	push xiz
	call AccReplay_SavedPedal
	pop xiz
	ret

AccWrap_ReplaySavedExpr:
	jp AccReplay_SavedExpression

AccWrap_FullStop:
	push xiz
	call AccReplay_FullStop
	pop xiz
	ret

AccWrap_PositionClear:
	push xiz
	call AccPos_ClearOnStart
	pop xiz
	ret

AccWrap_PositionSaveData:
	push	xiz
	call	16102420
	pop	xiz
	ret

AccWrap_FlagSync:
	jp AccFlags_SyncTo64607
AccWrap_PlayModeStopData2:
	jp	16101541

AccWrap_AutoPlayZoneTrack:
	push xiz
	call AccAutoPlay_ZoneTrack
	pop xiz
	ret

AccWrap_AutoPlayByteData:
	jp	16100284
	push	xiz
	calr	5156
	pop	xiz
	ret
	push	xiz
	calr	5268
	pop	xiz
	ret

AccPedal_EventDispatch:
	ldda8 a, 49277
	stda8 13450, a
	cps a, 5
	jr z, AccPedal_TypeSustainOrExpr
	cps a, 6
	jr z, AccPedal_TypeSustainOrExpr
	jr AccPedal_CheckType0

AccPedal_TypeSustainOrExpr:
	ldda8 a, 49278
	stda8 13438, a
	ldda8 a, 49279
	cp a, 0xFF
	jr nz, AccPedal_ParseValue
	xor a, a

AccPedal_ParseValue:
	stda8 13439, a
	calr AccPedal_SustainHandler
	calr AccPedal_ExprToggle
	calr AccPedal_DistributeParams

AccPedal_CheckType0:
	ldda8 a, 49277
	cps a, 0
	jr z, AccPedal_SavePosition
	cps a, 7
	jr nz, AccPedal_EventReturn
	ldda8 a, 49279
	and a, 0x30
	cps a, 0
	jr z, AccPedal_EventReturn

AccPedal_SavePosition:
	calr AccPos_SaveOnStop

AccPedal_EventReturn:
	ret

AccPedal_RawHandler:
	nop
	nop
	ldda8	a, 49277
	cps	a, 3
	jr	nz, 27
	ldda8	a, 49278
	and	a, 7
	stda8	13438, a
	ldda8	a, 49279
	stda8	13439, a
	ldda8	a, 49277
	stda8	13450, a
	ret
	nop
	nop

AccPedal_SustainHandler:
	cpdi8 13450, 5
	jrl nz, AccPedal_SustainReturn
	ldda8 a, 13438
	andda8 a, 13439
	bit 0, a
	jr nz, AccPedal_Sustain_CallReset
	jp AccPedal_SustainReturn

AccPedal_Sustain_CallReset:
	push xwa
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	call CompIface_ResetPedal
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	pop xwa
	cpdi8 32523, 0
	jr z, AccPedal_Sustain_CheckStyle
	call AccPlay_ToggleEntry
	jrl AccPedal_SustainReturn

AccPedal_Sustain_CheckStyle:
	cpdi8 36150, 111
	jr z, AccPedal_Sustain_SpecialStyle
	cpdi8 36150, 112
	jr z, AccPedal_Sustain_SpecialStyle
	cpdi8 36150, 113
	jr z, AccPedal_Sustain_SpecialStyle
	cpdi8 36150, 114
	jr nz, AccPedal_Sustain_CheckPlay

AccPedal_Sustain_SpecialStyle:
	ordi8 3381, 1
	jrl AccPedal_SustainReturn

AccPedal_Sustain_CheckPlay:
	bitda 2, 10407
	jr z, AccPedal_Sustain_CheckMultiStyle
	calr AccPlayMode_Dispatch
	bitda 3, 3411
	jr z, AccPedal_Sustain_PlayJump
	cpdi8 3429, 0
	jr z, AccPedal_Sustain_PlayJump
	call AccPedal_ScanVoiceSlots
	ldb a, 0x86
	bitda 1, 3411
	jr nz, AccPedal_Sustain_WriteTempo
	ldb a, 0x85

AccPedal_Sustain_WriteTempo:
	calr AccTempo_WriteStopMarker

AccPedal_Sustain_PlayJump:
	jrl AccPedal_SustainReturn

AccPedal_Sustain_CheckMultiStyle:
	cpdi8 36150, 120
	jr z, AccPedal_Sustain_MultiMatch
	cpdi8 36150, 122
	jr z, AccPedal_Sustain_MultiMatch
	cpdi8 36150, 115
	jr z, AccPedal_Sustain_MultiMatch
	cpdi8 36150, 116
	jr z, AccPedal_Sustain_MultiMatch
	cpdi8 36150, 117
	jr z, AccPedal_Sustain_MultiMatch
	cpdi8 36150, 118
	jr z, AccPedal_Sustain_MultiMatch
	cpdi8 36150, 119
	jr z, AccPedal_Sustain_MultiMatch
	cpdi8 36150, 121
	jr z, AccPedal_Sustain_MultiMatch
	cpdi8 36150, 108
	jr z, AccPedal_Sustain_MultiMatch
	cpdi8 36150, 109
	jr z, AccPedal_Sustain_MultiMatch
	cpdi8 36150, 110
	jr nz, AccPedal_Sustain_Normal

AccPedal_Sustain_MultiMatch:
	ordi8 3381, 1
	jr AccPedal_SustainReturn

AccPedal_Sustain_Normal:
	bitda 2, 10418
	jr nz, AccPedal_SustainReturn
	pushw wa
	calr AccPedal_StyleCheck
	cps a, 1
	popw wa
	jr z, AccPedal_SustainReturn
	ei 6
	ldda8 a, 1056
	bit 2, a
	jr nz, AccPedal_Sustain_CallPlayMode
	bit 0, a
	jr z, AccPedal_Sustain_CallPlayMode
	xor a, a
	stda8 1056, a
	stda8 1054, a
	stda8 1057, a
	ei 0
	jr AccPedal_SustainReturn

AccPedal_Sustain_CallPlayMode:
	ei 0
	calr AccPlayMode_TransitionRouter

AccPedal_SustainReturn:
	ret

AccPedal_SustainPadding:
	.byte 0x00, 0x00

AccPedal_StyleCheck:
	cpdi8 36150, 111
	jr z, AccPedal_StyleCheck_Ineligible
	cpdi8 36150, 108
	jr c, AccPedal_StyleCheck_Extended
	cpdi8 36150, 122
	jr ugt, AccPedal_StyleCheck_Extended
	jr AccPedal_StyleCheck_Ineligible

AccPedal_StyleCheck_Extended:
	cpdi8 36148, 19
	jr z, AccPedal_StyleCheck_Ineligible
	cpdi8 36150, 120
	jr z, AccPedal_StyleCheck_Match120
	jr AccPedal_StyleCheck_Eligible

AccPedal_StyleCheck_Match120:
	jr AccPedal_StyleCheck_Ineligible

AccPedal_StyleCheck_Eligible:
	ldb a, 0x0
	jr AccPedal_StyleCheckReturn

AccPedal_StyleCheck_Ineligible:
	ldb a, 0x1

AccPedal_StyleCheckReturn:
	ret

AccPedal_ExprToggle:
	cpdi8 13450, 5
	jr nz, AccPedal_ExprReturn
	ldda8 a, 13438
	andda8 a, 13439
	bit 1, a
	jr z, AccPedal_ExprReturn
	ldb a, 0x2
	xordm8 64607, a
	cpdi8 37112, 255
	jr z, AccPedal_ExprReturn
	bitda 3, 64854
	jr z, AccPedal_ExprReturn
	ldda8 e, 64607
	and e, 0x2
	ld xix, 0x38E8
	ld (xix + 256), 0x48
	ld (xix + 1), 0x5
	ld (xix + 2), e
	ld (xix + 3), 0x2
	push xix
	call MidiPkt_DispatchViaTable_4DCE
	inc 4, xsp

AccPedal_ExprReturn:
	ret

AccPedal_ExprPadding:
	.byte 0x00, 0x00

AccPedal_DistributeParams:
	cpdi8 36148, 14
	jr z, AccPedal_Distribute_JumpMain
	bitda 0, 10406
	jr z, AccPedal_Distribute_ClearAll

AccPedal_Distribute_JumpMain:
	jp AccPedal_DistributeReturn

AccPedal_Distribute_ClearAll:
	xor wa, wa
	stda8 13440, a
	stda8 13441, a
	stda8 13442, a
	stda8 13443, a
	stda8 13444, a
	stda8 13445, a
	stda8 13446, a
	stda8 13447, a
	calr AccPedal_ProcessAllBits
	bitda 3, 3411
	jr z, AccPedal_Distribute_CheckRecord
	anddi8 64607, 15
	stdi8 13441, 0
	stdi8 13443, 0
	stdi8 13445, 0
	stdi8 13447, 0

AccPedal_Distribute_CheckRecord:
	calr AccPedal_StateSync
	bitda 3, 3411
	jr z, AccPedal_DistributeReturn
	cpdi8 3429, 0
	jr z, AccPedal_DistributeReturn
	xor wa, wa
	stda8 13440, a
	stda8 13441, a
	stda8 13444, a
	stda8 13445, a
	calr AccPedal_MapToAcc
	calr AccPedal_SendEvents

AccPedal_DistributeReturn:
	ret

AccPedal_DistributePadding:
	.byte 0x00, 0x00

AccPedal_SendEvents:
	ldda8 a, 13440
	xor a, 0xFF
	andda8 a, 13441
	cps a, 0
	jr z, AccPedal_SendEvents_Group2
	ldb b, 0x5
	ldb c, 0x48
	ld d, a
	ldda8 e, 13440
	call MIDI_TransmitTempoCC

AccPedal_SendEvents_Group2:
	ldda8 a, 13444
	xor a, 0xFF
	andda8 a, 13445
	cps a, 0
	jr z, AccPedal_SendEvents_OnSustain
	ldb b, 0x6
	ldb c, 0x48
	ld d, a
	ldda8 e, 13444
	call MIDI_TransmitTempoCC

AccPedal_SendEvents_OnSustain:
	ldda8 a, 13440
	andda8 a, 13441
	cps a, 0
	jr z, AccPedal_SendEvents_OnExpr
	ldb b, 0x5
	ldb c, 0x48
	ld d, a
	ldda8 e, 13440
	call MIDI_TransmitTempoCC

AccPedal_SendEvents_OnExpr:
	ldda8 a, 13444
	andda8 a, 13445
	cps a, 0
	jr z, AccPedal_SendEventsReturn
	ldb b, 0x6
	ldb c, 0x48
	ld d, a
	ldda8 e, 13444
	call MIDI_TransmitTempoCC

AccPedal_SendEventsReturn:
	ret

AccPedal_ProcessAllBits:
	calr AccPedal_Bit2_Sustain
	calr AccPedal_Bit2_Expression
	calr AccPedal_Bit7_Portamento
	calr AccPedal_Bit6_Hold
	calr AccPedal_Bit4_Sostenuto
	calr AccPedal_Bit5_Soft
	calr AccPedal_Bit3_Damper
	ret

AccPedal_ProcessBitsPadding:
	.byte 0x00, 0x00

AccPedal_Bit2_Sustain:
	cpdi8 13450, 5
	jr nz, AccPedal_Bit2_Return
	ldda8 a, 13438
	andda8 a, 13439
	bit 2, a
	jr z, AccPedal_Bit2_Off
	ordi16 4360, 4
	cpdi8 37112, 127
	jr z, AccPedal_Bit2_CheckPlay
	calr AccPedal_SustainOn
	jr AccPedal_Bit2_Off

AccPedal_Bit2_CheckPlay:
	bitda 2, 1054
	jr nz, AccPedal_Bit2_Sostenuto
	calr AccPedal_SustainOn
	jr AccPedal_Bit2_Off

AccPedal_Bit2_Sostenuto:
	calr AccPedal_SostenutoOn

AccPedal_Bit2_Off:
	bitda 2, 13439
	jr z, AccPedal_Bit2_Return
	bitda 2, 13438
	jr nz, AccPedal_Bit2_Return
	cpdi8 37112, 127
	jr z, AccPedal_Bit2_OffPlay
	calr AccPedal_SustainOff
	jr AccPedal_Bit2_Return

AccPedal_Bit2_OffPlay:
	bitda 2, 1054
	jr nz, AccPedal_Bit2_OffSostenuto
	calr AccPedal_SustainOff
	jr AccPedal_Bit2_Return

AccPedal_Bit2_OffSostenuto:
	calr AccPedal_SostenutoOff

AccPedal_Bit2_Return:
	ret

AccPedal_Bit2_Expression:
	cpdi8 13450, 6
	jr nz, AccPedal_Expr_Return
	ldda8 a, 13438
	andda8 a, 13439
	bit 2, a
	jr z, AccPedal_Expr_Off
	lds de, 4
	sla de, 8
	orddm16 4360, xde
	cpdi8 37112, 127
	jr z, AccPedal_Expr_CheckPlay
	calr AccPedal_ExprOn
	jr AccPedal_Expr_Off

AccPedal_Expr_CheckPlay:
	bitda 2, 1054
	jr nz, AccPedal_Expr_Soft
	calr AccPedal_ExprOn
	jr AccPedal_Expr_Off

AccPedal_Expr_Soft:
	calr AccPedal_SoftOn

AccPedal_Expr_Off:
	bitda 2, 13439
	jr z, AccPedal_Expr_Return
	bitda 2, 13438
	jr nz, AccPedal_Expr_Return
	cpdi8 37112, 127
	jr z, AccPedal_Expr_OffPlay
	calr AccPedal_ExprOff
	jr AccPedal_Expr_Return

AccPedal_Expr_OffPlay:
	bitda 2, 1054
	jr nz, AccPedal_Expr_OffSoft
	calr AccPedal_ExprOff
	jr AccPedal_Expr_Return

AccPedal_Expr_OffSoft:
	calr AccPedal_SoftOff

AccPedal_Expr_Return:
	ret

AccPedal_Bit7_Portamento:
	cpdi8 13450, 5
	jr nz, AccPedal_Bit7_Return
	ldda8 a, 13438
	andda8 a, 13439
	bit 7, a
	jr z, AccPedal_Bit7_Off
	ordi16 4360, 128
	bitda 2, 1054
	jr z, AccPedal_Bit7_Damper
	calr AccPedal_PortamentoOn
	jr AccPedal_Bit7_Off

AccPedal_Bit7_Damper:
	calr AccPedal_DamperOn

AccPedal_Bit7_Off:
	bitda 7, 13439
	jr z, AccPedal_Bit7_Return
	bitda 7, 13438
	jr nz, AccPedal_Bit7_Return
	bitda 2, 1054
	jr z, AccPedal_Bit7_OffDamper
	calr AccPedal_PortamentoOff
	jr AccPedal_Bit7_Return

AccPedal_Bit7_OffDamper:
	calr AccPedal_DamperOff

AccPedal_Bit7_Return:
	ret

AccPedal_Bit6_Hold:
	cpdi8 13450, 5
	jr nz, AccPedal_Bit6_Return
	ldda8 a, 13438
	andda8 a, 13439
	bit 6, a
	jr z, AccPedal_Bit6_HoldOff
	ordi16 4360, 64
	bitda 2, 1054
	jr z, AccPedal_Bit6_HoldOff
	calr AccPedal_HoldOn
	jr __jrt_nop_F59F4D
__jrt_nop_F59F4D:

AccPedal_Bit6_HoldOff:
	bitda 6, 13439
	jr z, AccPedal_Bit6_Return
	bitda 6, 13438
	jr nz, AccPedal_Bit6_Return
	bitda 2, 1054
	jr z, AccPedal_Bit6_Return
	calr AccPedal_HoldOff
	jr __jrt_nop_F59F64
__jrt_nop_F59F64:

AccPedal_Bit6_Return:
	ret

AccPedal_Bit4_Sostenuto:
	cpdi8 13450, 5
	jr nz, AccPedal_Bit4_Return
	ldda8 a, 13438
	andda8 a, 13439
	bit 4, a
	jr z, AccPedal_Bit4_Off
	bitda 2, 1054
	jr z, AccPedal_Bit4_Off
	calr AccPedal_SostenutoOn

AccPedal_Bit4_Off:
	bitda 4, 13439
	jr z, AccPedal_Bit4_Return
	bitda 4, 13438
	jr nz, AccPedal_Bit4_Return
	bitda 2, 1054
	jr z, AccPedal_Bit4_Return
	calr AccPedal_SostenutoOff

AccPedal_Bit4_Return:
	ret

AccPedal_Bit5_Soft:
	cpdi8 13450, 5
	jr nz, AccPedal_Bit5_Return
	ldda8 a, 13438
	andda8 a, 13439
	bit 5, a
	jr z, AccPedal_Bit5_Off
	bitda 2, 1054
	jr z, AccPedal_Bit5_Off
	calr AccPedal_SoftOn

AccPedal_Bit5_Off:
	bitda 5, 13439
	jr z, AccPedal_Bit5_Return
	bitda 5, 13438
	jr nz, AccPedal_Bit5_Return
	bitda 2, 1054
	jr z, AccPedal_Bit5_Return
	calr AccPedal_SoftOff

AccPedal_Bit5_Return:
	ret

AccPedal_Bit3_Damper:
	cpdi8 13450, 5
	jr nz, AccPedal_Bit3_Return
	ldda8 a, 13438
	andda8 a, 13439
	bit 3, a
	jr z, AccPedal_Bit3_Off
	calr AccPedal_DamperOn

AccPedal_Bit3_Off:
	bitda 3, 13439
	jr z, AccPedal_Bit3_Return
	bitda 3, 13438
	jr nz, AccPedal_Bit3_Return
	calr AccPedal_DamperOff

AccPedal_Bit3_Return:
	ret

AccPedal_StateSync:
	cpdi8 37112, 127
	jr z, AccPedal_Sync_SendEvents
	cpdi8 37112, 255
	jr nz, AccPedal_Sync_DispatchAll

AccPedal_Sync_SendEvents:
	calr AccPedal_SendEvents

AccPedal_Sync_DispatchAll:
	cpdi8 37112, 255
	jr z, AccPedal_Sync_Return
	call AccPedal_SendCtrl1
	call AccPedal_SendCtrl2
	call AccPedal_SendCtrl3
	call AccPedal_SendCtrl4

AccPedal_Sync_Return:
	ret

AccPedal_SendCtrl1:
	ldda8 a, 13442
	xor a, 0xFF
	andda8 a, 13443
	cps a, 0
	jr z, AccPedal_SendCtrl1_Return
	bitda 3, 64854
	jr z, AccPedal_SendCtrl1_CheckPort
	ldb b, 0x5
	ld d, a
	ldda8 e, 13442
	ld xix, 0x38E8
	ld (xix + 256), 0x48
	ld (xix + 1), b
	ld (xix + 2), e
	ld (xix + 3), d
	push xix
	call MidiPkt_DispatchViaTable_4DCE
	inc 4, xsp

AccPedal_SendCtrl1_CheckPort:
	bitda 4, 64848
	jr nz, AccPedal_SendCtrl1_Return
	ldda8 a, 37092
	and a, 0x8F
	stda8 37093, a
	cpdi8 37112, 127
	jr nz, AccPedal_SendCtrl1_UpdateMask
	anddi8 37093, 127

AccPedal_SendCtrl1_UpdateMask:
	ldda8 a, 13442
	xor a, 0xFF
	andda8 a, 13443
	ldb b, 0x5
	ldb c, 0x48
	ld d, a
	ldda8 e, 13442
	call MIDI_DispatchCC

AccPedal_SendCtrl1_Return:
	ret

AccPedal_SendCtrl2:
	ldda8 a, 13446
	xor a, 0xFF
	andda8 a, 13447
	cps a, 0
	jr z, AccPedal_SendCtrl2_Return
	bitda 3, 64854
	jr z, AccPedal_SendCtrl2_CheckPort
	ldb b, 0x6
	ld d, a
	ldda8 e, 13446
	ld xix, 0x38E8
	ld (xix + 256), 0x48
	ld (xix + 1), b
	ld (xix + 2), e
	ld (xix + 3), d
	push xix
	call MidiPkt_DispatchViaTable_4DCE
	inc 4, xsp

AccPedal_SendCtrl2_CheckPort:
	bitda 4, 64848
	jr nz, AccPedal_SendCtrl2_Return
	ldda8 a, 37092
	and a, 0x8F
	stda8 37093, a
	cpdi8 37112, 127
	jr nz, AccPedal_SendCtrl2_UpdateMask
	anddi8 37093, 127

AccPedal_SendCtrl2_UpdateMask:
	ldda8 a, 13446
	xor a, 0xFF
	andda8 a, 13447
	ldb b, 0x6
	ldb c, 0x48
	ld d, a
	ldda8 e, 13446
	call MIDI_DispatchCC

AccPedal_SendCtrl2_Return:
	ret

AccPedal_SendCtrl3:
	ldda8 a, 13442
	andda8 a, 13443
	cps a, 0
	jr z, AccPedal_SendCtrl3_Return
	bitda 3, 64854
	jr z, AccPedal_SendCtrl3_CheckPort
	ldb b, 0x5
	ld d, a
	ldda8 e, 13442
	ld xix, 0x38E8
	ld (xix + 256), 0x48
	ld (xix + 1), b
	ld (xix + 2), e
	ld (xix + 3), d
	push xix
	call MidiPkt_DispatchViaTable_4DCE
	inc 4, xsp

AccPedal_SendCtrl3_CheckPort:
	bitda 4, 64848
	jr nz, AccPedal_SendCtrl3_Return
	ldda8 a, 37092
	and a, 0x8F
	stda8 37093, a
	cpdi8 37112, 127
	jr nz, AccPedal_SendCtrl3_UpdateMask
	anddi8 37093, 127

AccPedal_SendCtrl3_UpdateMask:
	ldda8 a, 13442
	andda8 a, 13443
	ldb b, 0x5
	ldb c, 0x48
	ld d, a
	ldda8 e, 13442
	call MIDI_DispatchCC

AccPedal_SendCtrl3_Return:
	ret

AccPedal_SendCtrl4:
	ldda8 a, 13446
	andda8 a, 13447
	cps a, 0
	jr z, AccPedal_SendCtrl4_Return
	bitda 3, 64854
	jr z, AccPedal_SendCtrl4_CheckPort
	ldb b, 0x6
	ld d, a
	ldda8 e, 13446
	ld xix, 0x38E8
	ld (xix + 256), 0x48
	ld (xix + 1), b
	ld (xix + 2), e
	ld (xix + 3), d
	push xix
	call MidiPkt_DispatchViaTable_4DCE
	inc 4, xsp

AccPedal_SendCtrl4_CheckPort:
	bitda 4, 64848
	jr nz, AccPedal_SendCtrl4_Return
	ldda8 a, 37092
	and a, 0x8F
	stda8 37093, a
	cpdi8 37112, 127
	jr nz, AccPedal_SendCtrl4_UpdateMask
	anddi8 37093, 127

AccPedal_SendCtrl4_UpdateMask:
	ldda8 a, 13446
	andda8 a, 13447
	ldb b, 0x6
	ldb c, 0x48
	ld d, a
	ldda8 e, 13446
	call MIDI_DispatchCC

AccPedal_SendCtrl4_Return:
	ret

AccPedal_MapToAcc:
	cpdi8 13450, 5
	jr nz, AccPedal_MapToAcc_Send
	ldda8 a, 13438
	andda8 a, 13439
	bit 6, a
	jr z, AccPedal_MapToAcc_Send
	call AccPedal_ScanVoiceSlots
	bitda 1, 3411
	jr z, AccPedal_MapToAcc_Send
	ordi8 13441, 64
	ordi8 13440, 64

AccPedal_MapToAcc_Send:
	cpdi8 13450, 5
	jr nz, AccPedal_MapToAcc_UpdateMask
	ldda8 a, 13438
	andda8 a, 13439
	bit 7, a
	jr z, AccPedal_MapToAcc_UpdateMask
	call AccPedal_ScanVoiceSlots
	bitda 1, 3411
	jr z, AccPedal_MapToAcc_CheckDir
	ordi8 13441, 128
	ordi8 13440, 128
	jr AccPedal_MapToAcc_UpdateMask

AccPedal_MapToAcc_CheckDir:
	ordi8 13441, 8
	ordi8 13440, 8

AccPedal_MapToAcc_UpdateMask:
	cpdi8 13450, 5
	jr nz, AccPedal_MapToAcc_SetMask
	ldda8 a, 13438
	andda8 a, 13439
	bit 2, a
	jr z, AccPedal_MapToAcc_SetMask
	call AccPedal_ScanVoiceSlots
	bitda 1, 3411
	jr z, AccPedal_MapToAcc_ClearMask
	ordi8 13441, 16
	ordi8 13440, 16
	jr AccPedal_MapToAcc_SetMask

AccPedal_MapToAcc_ClearMask:
	ordi8 13441, 4
	ordi8 13440, 4

AccPedal_MapToAcc_SetMask:
	cpdi8 13450, 6
	jr nz, AccPedal_MapToAcc_Return
	ldda8 a, 13438
	andda8 a, 13439
	bit 2, a
	jr z, AccPedal_MapToAcc_Return
	call AccPedal_ScanVoiceSlots
	bitda 1, 3411
	jr z, AccPedal_MapToAcc_Apply
	ordi8 13441, 32
	ordi8 13440, 32
	jr AccPedal_MapToAcc_Return

AccPedal_MapToAcc_Apply:
	ordi8 13445, 4
	ordi8 13444, 4

AccPedal_MapToAcc_Return:
	cpdi8 13450, 5
	jr nz, AccPedal_MapPadding
	ldda8 a, 13438
	andda8 a, 13439
	bit 5, a
	jr z, AccPedal_MapPadding
	call AccPedal_ScanVoiceSlots
	bitda 1, 3411
	jr z, AccPedal_MapPadding
	ordi8 13441, 32
	ordi8 13440, 32
	jr __jrt_nop_F5A2B1
__jrt_nop_F5A2B1:

AccPedal_MapPadding:
	ret

AccPedal_MapPadding2:
	.byte 0x00, 0x00

AccPedal_SustainOn:
	bitda 2, 13424
	jrl nz, AccPedal_SustainOn_AltRoute
	ordi8 13424, 4
	bitda 2, 64607
	jr nz, AccPedal_SustainOn_SetMask
	ordi8 64607, 4
	ordi8 13442, 4
	ordi8 13440, 4
	jr AccPedal_SustainOn_Update64607

AccPedal_SustainOn_SetMask:
	cpdi8 37112, 127
	jr nz, AccPedal_SustainOn_Update64607
	anddi8 64607, 251
	anddi8 13442, 251
	anddi8 13440, 251

AccPedal_SustainOn_Update64607:
	ordi8 13441, 4
	ordi8 13443, 4
	bitda 3, 64607
	jr z, AccPedal_SustainOn_Post
	anddi8 64607, 247
	anddi8 13440, 247
	ordi8 13441, 8
	anddi8 13442, 247
	ordi8 13443, 8

AccPedal_SustainOn_Post:
	bitda 2, 64608
	jr z, AccPedal_SustainOn_Finalize
	anddi8 64608, 251
	anddi8 13444, 251
	ordi8 13445, 4
	anddi8 13446, 251
	ordi8 13447, 4

AccPedal_SustainOn_Finalize:
	bitda 6, 64607
	jr z, AccPedal_SustainOn_CheckAlt
	anddi8 64607, 191

AccPedal_SustainOn_CheckAlt:
	bitda 7, 64607
	jr z, AccPedal_SustainOn_AltRoute
	anddi8 64607, 127

AccPedal_SustainOn_AltRoute:
	cpdi8 37112, 127
	jr z, AccPedal_SustainOn_Return
	anddi8 13424, 251

AccPedal_SustainOn_Return:
	ret

AccPedal_SustainOff_Padding:
	.byte 0x00, 0x00

AccPedal_SustainOff:
	bitda 2, 13424
	jr z, AccPedal_SustainOff_Clear
	anddi8 13424, 251

AccPedal_SustainOff_Clear:
	cpdi8 37112, 127
	jr z, AccPedal_SustainOff_Return
	anddi8 64607, 251

AccPedal_SustainOff_Return:
	ret

AccPedal_ExprOn_Padding:
	.byte 0x00, 0x00

AccPedal_ExprOn:
	bitda 0, 13424
	jrl nz, AccPedal_ExprOn_AltRoute
	ordi8 13424, 1
	bitda 2, 64608
	jr nz, AccPedal_ExprOn_SetMask
	ordi8 64608, 4
	ordi8 13446, 4
	ordi8 13444, 4
	jr AccPedal_ExprOn_Update64607

AccPedal_ExprOn_SetMask:
	cpdi8 37112, 127
	jr nz, AccPedal_ExprOn_Update64607
	anddi8 64608, 251
	anddi8 13446, 251
	anddi8 13444, 251

AccPedal_ExprOn_Update64607:
	ordi8 13445, 4
	ordi8 13447, 4
	bitda 3, 64607
	jr z, AccPedal_ExprOn_Post
	anddi8 64607, 247
	anddi8 13440, 247
	ordi8 13441, 8
	anddi8 13442, 247
	ordi8 13443, 8

AccPedal_ExprOn_Post:
	bitda 2, 64607
	jr z, AccPedal_ExprOn_Finalize
	anddi8 64607, 251
	anddi8 13440, 251
	ordi8 13441, 4
	anddi8 13442, 251
	ordi8 13443, 4

AccPedal_ExprOn_Finalize:
	bitda 6, 64607
	jr z, AccPedal_ExprOn_CheckAlt
	anddi8 64607, 191

AccPedal_ExprOn_CheckAlt:
	bitda 7, 64607
	jr z, AccPedal_ExprOn_AltRoute
	anddi8 64607, 127

AccPedal_ExprOn_AltRoute:
	cpdi8 37112, 127
	jr z, AccPedal_ExprOn_Return
	anddi8 13424, 254

AccPedal_ExprOn_Return:
	ret

AccPedal_ExprOff_Padding:
	.byte 0x00, 0x00

AccPedal_ExprOff:
	bitda 0, 13424
	jr z, AccPedal_ExprOff_Clear
	anddi8 13424, 254

AccPedal_ExprOff_Clear:
	cpdi8 37112, 127
	jr z, AccPedal_ExprOff_Return
	anddi8 64608, 251

AccPedal_ExprOff_Return:
	ret

AccPedal_SostenutoOn_Padding:
	.byte 0x00, 0x00

AccPedal_SostenutoOn:
	bitda 4, 13424
	jrl nz, AccPedal_SostenutoOn_Return
	ordi8 13424, 16
	ordi8 64607, 16
	ordi8 13441, 16
	ordi8 13440, 16
	ordi8 13443, 16
	ordi8 13442, 16
	bitda 5, 64607
	jr z, AccPedal_SostenutoOn_SetMask
	anddi8 64607, 223

AccPedal_SostenutoOn_SetMask:
	bitda 6, 64607
	jr z, AccPedal_SostenutoOn_Update
	anddi8 64607, 191

AccPedal_SostenutoOn_Update:
	bitda 7, 64607
	jr z, AccPedal_SostenutoOn_Post
	anddi8 64607, 127

AccPedal_SostenutoOn_Post:
	bitda 2, 64607
	jr z, AccPedal_SostenutoOn_Finalize
	anddi8 64607, 251
	ordi8 13443, 4
	anddi8 13442, 251
	ordi8 13441, 4
	anddi8 13440, 251

AccPedal_SostenutoOn_Finalize:
	bitda 3, 64607
	jr z, AccPedal_SostenutoOn_CheckAlt
	anddi8 64607, 247
	ordi8 13443, 8
	anddi8 13442, 247
	ordi8 13441, 8
	anddi8 13440, 247

AccPedal_SostenutoOn_CheckAlt:
	bitda 2, 64608
	jr z, AccPedal_SostenutoOn_Return
	anddi8 64608, 251
	ordi8 13447, 4
	anddi8 13446, 251
	ordi8 13445, 4
	anddi8 13444, 251

AccPedal_SostenutoOn_Return:
	ret

AccPedal_SostenutoOff_Padding:
	.byte 0x00, 0x00

AccPedal_SostenutoOff:
	bitda 4, 13424
	jr z, AccPedal_SostenutoOff_Return
	anddi8 13424, 239
	ordi8 13441, 16
	anddi8 13440, 239
	ordi8 13443, 16
	anddi8 13442, 239

AccPedal_SostenutoOff_Return:
	ret

AccPedal_SostenutoOff_Padding2:
	.byte 0x00, 0x00

AccPedal_SoftOn:
	bitda 5, 13424
	jrl nz, AccPedal_SoftOn_Return
	ordi8 13424, 32
	ordi8 64607, 32
	ordi8 13441, 32
	ordi8 13440, 32
	ordi8 13443, 32
	ordi8 13442, 32
	bitda 4, 64607
	jr z, AccPedal_SoftOn_SetMask
	anddi8 64607, 239

AccPedal_SoftOn_SetMask:
	bitda 6, 64607
	jr z, AccPedal_SoftOn_Update
	anddi8 64607, 191

AccPedal_SoftOn_Update:
	bitda 7, 64607
	jr z, AccPedal_SoftOn_Post
	anddi8 64607, 127

AccPedal_SoftOn_Post:
	bitda 2, 64607
	jr z, AccPedal_SoftOn_Finalize
	anddi8 64607, 251
	ordi8 13443, 4
	anddi8 13442, 251
	ordi8 13441, 4
	anddi8 13440, 251

AccPedal_SoftOn_Finalize:
	bitda 3, 64607
	jr z, AccPedal_SoftOn_CheckAlt
	anddi8 64607, 247
	ordi8 13443, 8
	anddi8 13442, 247
	ordi8 13441, 8
	anddi8 13440, 247

AccPedal_SoftOn_CheckAlt:
	bitda 2, 64608
	jr z, AccPedal_SoftOn_Return
	anddi8 64608, 251
	ordi8 13447, 4
	anddi8 13446, 251
	ordi8 13445, 4
	anddi8 13444, 251

AccPedal_SoftOn_Return:
	ret

AccPedal_SoftOff_Padding:
	.byte 0x00, 0x00

AccPedal_SoftOff:
	bitda 5, 13424
	jr z, AccPedal_SoftOff_Return
	anddi8 13424, 223
	ordi8 13441, 32
	anddi8 13440, 223
	ordi8 13443, 32
	anddi8 13442, 223

AccPedal_SoftOff_Return:
	ret

AccPedal_HoldOn_Padding:
	.byte 0x00, 0x00

AccPedal_HoldOn:
	bitda 6, 13424
	jrl nz, AccPedal_HoldOn_Return
	ordi8 13424, 64
	ordi8 64607, 64
	ordi8 13441, 64
	ordi8 13440, 64
	ordi8 13443, 64
	ordi8 13442, 64
	bitda 4, 64607
	jr z, AccPedal_HoldOn_SetMask
	anddi8 64607, 239

AccPedal_HoldOn_SetMask:
	bitda 5, 64607
	jr z, AccPedal_HoldOn_Update
	anddi8 64607, 223

AccPedal_HoldOn_Update:
	bitda 2, 64607
	jr z, AccPedal_HoldOn_Post
	anddi8 64607, 251
	ordi8 13443, 4
	anddi8 13442, 251
	ordi8 13441, 4
	anddi8 13440, 251

AccPedal_HoldOn_Post:
	bitda 3, 64607
	jr z, AccPedal_HoldOn_Finalize
	anddi8 64607, 247
	ordi8 13443, 8
	anddi8 13442, 247
	ordi8 13441, 8
	anddi8 13440, 247

AccPedal_HoldOn_Finalize:
	bitda 2, 64608
	jr z, AccPedal_HoldOn_CheckAlt
	anddi8 64608, 251
	ordi8 13447, 4
	anddi8 13446, 251
	ordi8 13445, 4
	anddi8 13444, 251

AccPedal_HoldOn_CheckAlt:
	bitda 7, 64607
	jr z, AccPedal_HoldOn_Return
	anddi8 64607, 127

AccPedal_HoldOn_Return:
	ret

AccPedal_HoldOff_Padding:
	.byte 0x00, 0x00

AccPedal_HoldOff:
	bitda 6, 13424
	jr z, AccPedal_HoldOff_Return
	anddi8 13424, 191
	ordi8 13441, 64
	anddi8 13440, 191
	ordi8 13443, 64
	anddi8 13442, 191

AccPedal_HoldOff_Return:
	ret

AccPedal_HoldOff_Padding2:
	.byte 0x00, 0x00

AccPedal_DamperOn:
	bitda 3, 13424
	jrl nz, AccPedal_DamperOn_FinalCheck
	ordi8 13424, 8
	bitda 3, 64607
	jr nz, AccPedal_DamperOn_SetMask
	ordi8 64607, 8
	ordi8 13442, 8
	ordi8 13440, 8
	jr AccPedal_DamperOn_Update

AccPedal_DamperOn_SetMask:
	cpdi8 37112, 127
	jr nz, AccPedal_DamperOn_Update
	anddi8 64607, 247
	anddi8 13442, 247
	anddi8 13440, 247

AccPedal_DamperOn_Update:
	ordi8 13441, 8
	ordi8 13443, 8
	bitda 2, 64607
	jr z, AccPedal_DamperOn_Post
	anddi8 64607, 251
	anddi8 13440, 251
	ordi8 13441, 4
	anddi8 13442, 251
	ordi8 13443, 4

AccPedal_DamperOn_Post:
	bitda 2, 64608
	jr z, AccPedal_DamperOn_Finalize
	anddi8 64608, 251
	anddi8 13444, 251
	ordi8 13445, 4
	anddi8 13446, 251
	ordi8 13447, 4

AccPedal_DamperOn_Finalize:
	bitda 6, 64607
	jr z, AccPedal_DamperOn_CheckAlt
	anddi8 64607, 191

AccPedal_DamperOn_CheckAlt:
	bitda 7, 64607
	jr z, AccPedal_DamperOn_AltRoute
	anddi8 64607, 127

AccPedal_DamperOn_AltRoute:
	bitda 4, 64607
	jr z, AccPedal_DamperOn_Apply
	anddi8 64607, 239

AccPedal_DamperOn_Apply:
	bitda 5, 64607
	jr z, AccPedal_DamperOn_FinalCheck
	anddi8 64607, 223

AccPedal_DamperOn_FinalCheck:
	cpdi8 37112, 127
	jr z, AccPedal_DamperOn_Return
	anddi8 13424, 247

AccPedal_DamperOn_Return:
	ret

AccPedal_DamperOff_Padding:
	.byte 0x00, 0x00

AccPedal_DamperOff:
	bitda 3, 13424
	jr z, AccPedal_DamperOff_Clear
	anddi8 13424, 247

AccPedal_DamperOff_Clear:
	cpdi8 37112, 127
	jr z, AccPedal_DamperOff_Return
	anddi8 64607, 247

AccPedal_DamperOff_Return:
	ret

AccPedal_DamperOff_Padding2:
	.byte 0x00, 0x00

AccPedal_PortamentoOn:
	bitda 7, 13424
	jrl nz, AccPedal_PortamentoOn_Return
	ordi8 13424, 128
	ordi8 64607, 128
	ordi8 13441, 128
	ordi8 13440, 128
	ordi8 13443, 128
	ordi8 13442, 128
	bitda 4, 64607
	jr z, AccPedal_PortamentoOn_SetMask
	anddi8 64607, 239

AccPedal_PortamentoOn_SetMask:
	bitda 5, 64607
	jr z, AccPedal_PortamentoOn_Update
	anddi8 64607, 223

AccPedal_PortamentoOn_Update:
	bitda 2, 64607
	jr z, AccPedal_PortamentoOn_Post
	anddi8 64607, 251
	ordi8 13443, 4
	anddi8 13442, 251
	ordi8 13441, 4
	anddi8 13440, 251

AccPedal_PortamentoOn_Post:
	bitda 3, 64607
	jr z, AccPedal_PortamentoOn_Finalize
	anddi8 64607, 247
	ordi8 13443, 8
	anddi8 13442, 247
	ordi8 13441, 8
	anddi8 13440, 247

AccPedal_PortamentoOn_Finalize:
	bitda 2, 64608
	jr z, AccPedal_PortamentoOn_CheckAlt
	anddi8 64608, 251
	ordi8 13447, 4
	anddi8 13446, 251
	ordi8 13445, 4
	anddi8 13444, 251

AccPedal_PortamentoOn_CheckAlt:
	bitda 6, 64607
	jr z, AccPedal_PortamentoOn_Return
	anddi8 64607, 191

AccPedal_PortamentoOn_Return:
	ret

AccPedal_PortamentoOff_Padding:
	.byte 0x00, 0x00

AccPedal_PortamentoOff:
	bitda 7, 13424
	jr z, AccPedal_PortamentoOff_Return
	anddi8 13424, 127
	ordi8 13441, 128
	anddi8 13440, 127
	ordi8 13443, 128
	anddi8 13442, 127

AccPedal_PortamentoOff_Return:
	ret

AccPedal_PortamentoOff_Padding2:
	.byte 0x00, 0x00

AccAutoPlay_NoteDispatch:
	ld w, a
	ld a, c
	cpdi8 32523, 0
	jr nz, AccAutoPlay_NoteDispatch_Process
	pushw wa
	calr AccPedal_StyleCheck
	cps a, 1
	popw wa
	jr z, AccAutoPlay_NoteDispatch_Process
	bitda 2, 10407
	jr nz, AccAutoPlay_NoteDispatch_Process
	push xwa
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	call CompIface_ResetPedal
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	pop xwa
	calr AccAutoPlay_SplitDetect
	cps c, 0
	jr z, AccAutoPlay_NoteDispatch_Check
	ordi8 13464, 1

AccAutoPlay_NoteDispatch_Check:
	ordi8 13464, 128

AccAutoPlay_NoteDispatch_Process:
	cpdi16 10408, 0
	jr z, AccAutoPlay_NoteDispatch_Return
	bitda 2, 1054
	jr nz, AccAutoPlay_NoteDispatch_Return
	bitda 1, 64607
	jr z, AccAutoPlay_NoteDispatch_Return
	bitda 3, 10419
	jr z, AccAutoPlay_NoteDispatch_Return
	bitda 0, 10418
	jr nz, AccAutoPlay_NoteDispatch_Return
	bitda 2, 10417
	jr nz, AccAutoPlay_NoteDispatch_Return
	bitda 0, 13464
	jr z, AccAutoPlay_NoteDispatch_Return
	anddi8 10419, 247
	call Audio_CheckSubsystemReady

AccAutoPlay_NoteDispatch_Return:
	ret

AccAutoPlay_SplitDetect:
	ldb c, 0x0
	cpdi16 10408, 0
	jr z, AccAutoPlay_SplitDetect_Check
	bitda 3, 10419
	jr z, AccAutoPlay_SplitDetect_Check
	bitda 0, 10418
	jr nz, AccAutoPlay_SplitDetect_Return
	bitda 2, 10417
	jr nz, AccAutoPlay_SplitDetect_Return

AccAutoPlay_SplitDetect_Check:
	bit 7, w
	jr z, AccAutoPlay_SplitDetect_Process
	push_a
	calr AccAutoPlay_ModeAvail
	pop_a
	cp l, a
	jr c, AccAutoPlay_SplitDetect_Upper
	ldb c, 0x1
	jr AccAutoPlay_SplitDetect_Return

AccAutoPlay_SplitDetect_Upper:
	ldb c, 0x0
	jr AccAutoPlay_SplitDetect_Return

AccAutoPlay_SplitDetect_Process:
	bitda 0, 64851
	jr nz, AccAutoPlay_SplitDetect_NoSplit
	and w, 0xF
	ldda8 l, 63939
	and l, 0xF
	cp l, w
	jr z, AccAutoPlay_SplitDetect_Lower
	ldda8 l, 64485
	bit 7, l
	jr nz, AccAutoPlay_SplitDetect_Apply
	and l, 0xF
	cp l, w
	jr nz, AccAutoPlay_SplitDetect_Apply
	ldb c, 0x1
	jr AccAutoPlay_SplitDetect_Return

AccAutoPlay_SplitDetect_Lower:
	push_a
	calr AccAutoPlay_ModeAvail
	pop_a
	cp l, a
	jr c, AccAutoPlay_SplitDetect_Apply
	ldb c, 0x1
	jr AccAutoPlay_SplitDetect_Return

AccAutoPlay_SplitDetect_Apply:
	ldb c, 0x0
	jr AccAutoPlay_SplitDetect_Return

AccAutoPlay_SplitDetect_NoSplit:
	and w, 0xF
	ldda8 l, 63991
	bit 7, l
	jr nz, AccAutoPlay_SplitDetect_Store
	and l, 0xF
	cp l, w
	jr nz, AccAutoPlay_SplitDetect_Store
	ldb c, 0x1
	jr AccAutoPlay_SplitDetect_Return

AccAutoPlay_SplitDetect_Store:
	ldda8 l, 64485
	bit 7, l
	jr nz, AccAutoPlay_SplitDetect_Return
	and l, 0xF
	cp l, w
	jr nz, AccAutoPlay_SplitDetect_Return
	ldb c, 0x1

AccAutoPlay_SplitDetect_Return:
	ret

AccAutoPlay_ZoneTrack:
	cpdi8 32523, 0
	jr nz, AccAutoPlay_ZoneTrack_Update
	pushw wa
	calr AccPedal_StyleCheck
	cps a, 1
	popw wa
	jr z, AccAutoPlay_ZoneTrack_Update
	bitda 2, 10407
	jr nz, AccAutoPlay_ZoneTrack_Update
	calr AccAutoPlay_ZoneTrack_Apply
	ldda16 xhl, 13468
	stda16 13466, xhl
	stda16 13468, xwa

AccAutoPlay_ZoneTrack_Update:
	ret

AccAutoPlay_ZoneTrack_Apply:
	ld xix, 0xCEFF
	ld wa, (xix + 2)
	cps wa, 0
	jr nz, AccAutoPlay_ZoneTrack_Check
	ldb l, 0x80
	jr AccAutoPlay_ZoneTrack_Store

AccAutoPlay_ZoneTrack_Check:
	cps wa, 1
	jr nz, AccAutoPlay_ZoneTrack_Upper
	ldb l, 0x0
	jr AccAutoPlay_ZoneTrack_Store

AccAutoPlay_ZoneTrack_Upper:
	ldb l, 0xF0

AccAutoPlay_ZoneTrack_Store:
	ld w, l
	calr AccAutoPlay_ZoneTrack_SetFlag
	stdi16 14568, 0
	ld bc, (xix + 256)
	ldb e, 0x5

AccAutoPlay_ZoneTrack_Clear:
	cps bc, 0
	jr z, AccAutoPlay_ZoneTrack_Default
	ld_srib3 A, 0x03, 0xF0, 0xE8
	cp l, a
	jr c, AccAutoPlay_ZoneTrack_Finalize
	incdi16 1, 14568

AccAutoPlay_ZoneTrack_Finalize:
	inc 2, e
	dec 1, bc
	jr AccAutoPlay_ZoneTrack_Clear

AccAutoPlay_ZoneTrack_Default:
	ldda16 xwa, 14568
	ret

AccAutoPlay_ZoneTrack_SetFlag:
	ldb c, 0x0
	bit 7, w
	jr z, AccAutoPlay_ZoneTrack_Done
	calr AccAutoPlay_ModeAvail
	jr AccAutoPlay_ZoneTrack_Return2

AccAutoPlay_ZoneTrack_Done:
	bitda 0, 64851
	jr nz, AccAutoPlay_ZoneTrack_Final
	calr AccAutoPlay_ModeAvail
	jr AccAutoPlay_ZoneTrack_Return2

AccAutoPlay_ZoneTrack_Final:
	ldb l, 0x7F

AccAutoPlay_ZoneTrack_Return2:
	ret

AccAutoPlay_ZoneTrack_Return:
	.byte 0x0e

AccAutoPlay_StateMachine:
	calr AccAutoPlay_TriggerCheck
	bitda 6, 13422
	jr z, AccAutoPlay_SM_CheckEligible
	cpdi16 61854, 0
	jr z, AccAutoPlay_SM_CheckEligible
	cpdi16 10408, 0
	jr nz, AccAutoPlay_SM_CheckEligible
	calr AccAutoPlay_SetConfig
	bitda 7, 13421
	jr nz, AccAutoPlay_SM_CheckEligible
	calr AccAutoPlay_Disable

AccAutoPlay_SM_CheckEligible:
	stdi8 13428, 0
	calr AccAutoPlay_ActionDispatch
	bitda 0, 13428
	jr z, AccAutoPlay_SM_Return
	stdi8 13428, 0
	ordi8 13422, 4
	calr AccReplay_FullRestart

AccAutoPlay_SM_Return:
	ret

AccAutoPlay_SM_Padding:
	.byte 0x00, 0x00

AccAutoPlay_TriggerCheck:
	bitda 2, 10407
	jrl nz, AccAutoPlay_ModeAvail_Padding2
	calr AccAutoPlay_SetConfig
	bitda 0, 13464
	jrl z, AccAutoPlay_ModeAvail_Padding2
	bitda 0, 13465
	jrl nz, AccAutoPlay_Trigger_Activate
	bitda 7, 13421
	jr nz, AccAutoPlay_Trigger_Evaluate
	bitda 2, 1054
	jr nz, AccAutoPlay_Trigger_Process
	bitda 1, 64607
	jr z, AccAutoPlay_Trigger_Process

AccAutoPlay_Trigger_Evaluate:
	calr AccAutoPlay_Configure

AccAutoPlay_Trigger_Process:
	ordi8 13464, 1
	ordi8 13465, 1
	jr AccAutoPlay_ModeAvail_Padding

AccAutoPlay_Trigger_Activate:
	bitda 7, 13464
	jr nz, AccAutoPlay_ModeAvail_Padding
	bitda 7, 13421
	jr z, AccAutoPlay_Trigger_Return
	cpdi16 13468, 0
	jr nz, AccAutoPlay_Trigger_Configure
	cpdi16 13466, 0
	jr z, AccAutoPlay_Trigger_Configure
	calr AccAutoPlay_SeqHandoff
	anddi8 13464, 254
	anddi8 13465, 254
	stdi16 13466, 0
	jr AccAutoPlay_ModeAvail_Padding

AccAutoPlay_Trigger_Configure:
	cpdi16 13468, 0
	jr nz, AccAutoPlay_Trigger_Finalize
	cpdi16 13466, 0
	jr nz, AccAutoPlay_Trigger_Finalize
	stdi8 13464, 0
	stdi8 13465, 0

AccAutoPlay_Trigger_Finalize:
	jr AccAutoPlay_ModeAvail_Padding

AccAutoPlay_Trigger_Return:
	anddi8 13464, 254
	anddi8 13465, 254
	jr __jrt_nop_F5AA8E
__jrt_nop_F5AA8E:

AccAutoPlay_ModeAvail_Padding:
	anddi8 13464, 127

AccAutoPlay_ModeAvail_Padding2:
	ret

AccAutoPlay_ModeAvail_Padding3:
	.byte 0x00, 0x00

AccAutoPlay_ModeAvail:
	ldda8 l, 64770
	and l, 0x3
	cps l, 0
	jr nz, AccAutoPlay_ModeAvail_Process
	ldda8 l, 64771
	and l, 0x7F
	dec 1, l
	cp l, 0xFF
	jr nz, AccAutoPlay_ModeAvail_Check
	ldb l, 0x0

AccAutoPlay_ModeAvail_Check:
	jr AccAutoPlay_ModeAvail_SetMode

AccAutoPlay_ModeAvail_Process:
	push l
	lds32 xhl, 0
	pop l
	add xhl, 0xF5AACD
	ld l, (xhl)

AccAutoPlay_ModeAvail_SetMode:
	cpdi8 36148, 14
	jr nz, AccAutoPlay_ModeAvail_Return
	ldb l, 0x7F

AccAutoPlay_ModeAvail_Return:
	ret

AccAutoPlay_ModeAvail_Extended:
	nop
	nop
	push	xhl
	ldw	iz, 16955
	ld	xsp, 3389267697
	jr	nz, 34
	.byte 0xf1, 0x6e, 0x34, 0xc9
	jr	z, 28
	.byte 0xf1, 0x98, 0x34, 0xc8
	jr	z, 22
	.byte 0xf1, 0x99, 0x34, 0xc8
	jr	nz, 16
	calr	72
	ldda8	a, 13464
	stda8	13465, a
	.byte 0xc1, 0x98, 0x34, 0x3e, 0x01
	ret

AccAutoPlay_SetConfig:
	cpdi16 10408, 0
	jr nz, AccAutoPlay_SetConfig_Apply
	cpdi16 61854, 0
	jr nz, AccAutoPlay_SetConfig_Apply
	cpdi8 14235, 0
	jr nz, AccAutoPlay_SetConfig_Apply
	ldda8 a, 64605
	bit 3, a
	jr nz, AccAutoPlay_SetConfig_Apply
	and a, 0x7
	cps a, 0
	jr z, AccAutoPlay_SetConfig_Apply
	bitda 1, 64607
	jr z, AccAutoPlay_SetConfig_Apply
	ordi8 13421, 128
	jr AccAutoPlay_SetConfig_Return

AccAutoPlay_SetConfig_Apply:
	stdi8 13421, 0

AccAutoPlay_SetConfig_Return:
	ret

AccAutoPlay_Configure:
	anddi8 13422, 31
	cpdi8 14235, 0
	jr nz, AccAutoPlay_Configure_Mode1
	cpdi16 10408, 0
	jr nz, AccAutoPlay_Configure_Mode2
	cpdi16 61854, 0
	jr z, AccAutoPlay_Configure_Mode1
	jr AccAutoPlay_Configure_Store

AccAutoPlay_Configure_Mode1:
	ordi8 13422, 160
	calr AccAutoPlay_SubModeA
	jr AccAutoPlay_Configure_Return

AccAutoPlay_Configure_Mode2:
	cpdi16 61854, 0
	jr nz, AccAutoPlay_Configure_Store
	bitda 2, 1056
	jr z, AccAutoPlay_Configure_Apply
	ordi8 13422, 128
	jr AccAutoPlay_Configure_Check

AccAutoPlay_Configure_Apply:
	ordi8 13422, 224

AccAutoPlay_Configure_Check:
	jr AccAutoPlay_Configure_Return

AccAutoPlay_Configure_Store:
	bitda 2, 1056
	jr nz, AccAutoPlay_Configure_Return
	calr AccAutoPlay_ModeDecode
	calr AccAutoPlay_SubModeB

AccAutoPlay_Configure_Return:
	ret

AccAutoPlay_Configure_Extended:
	; --- Bit-flag conditional: check bits, and/clear (0x3498)/(0x3499) (54 bytes) ---
	nop
	nop
	.byte 0xf1, 0x6e, 0x34, 0xc9
	jr nz, AccAutoPlay_Configure_Final
	.byte 0xc1, 0x99, 0x34, 0x3c, 0xfe		; and (0x3499), 0xFE  [C1 prefix]
	.byte 0xc1, 0x98, 0x34, 0x3c, 0xfe		; and (0x3498), 0xFE  [C1 prefix]
	jr t, AccAutoPlay_Configure_Return2
AccAutoPlay_Configure_Final:
	.byte 0xf1, 0x98, 0x34, 0xc8			; bit 0, (0x3498)  [F1 prefix]
	jr nz, AccAutoPlay_Configure_Return2
	.byte 0xf1, 0x99, 0x34, 0xc8			; bit 0, (0x3499)  [F1 prefix]
	jr z, AccAutoPlay_Configure_Return2
	.byte 0xf1, 0x6d, 0x34, 0xcf			; bit 7, (0x346D)  [F1 prefix]
	jr z, AccAutoPlay_Configure_Done
	calr AccAutoPlay_SeqHandoff
AccAutoPlay_Configure_Done:
	.byte 0xc1, 0x99, 0x34, 0x3c, 0xfe		; and (0x3499), 0xFE  [C1 prefix]
	.byte 0xc1, 0x98, 0x34, 0x3c, 0xfe		; and (0x3498), 0xFE  [C1 prefix]
AccAutoPlay_Configure_Return2:
	ret
	nop
	nop


AccAutoPlay_PeriodicCheck:
	bitda 1, 64607
	jr nz, AccAutoPlay_Periodic_Evaluate
	jr AccAutoPlay_Periodic_Return

AccAutoPlay_Periodic_Evaluate:
	bitda 2, 13422
	jr z, AccAutoPlay_Periodic_Process
	calr AccAutoPlay_SetConfig
	bitda 7, 13421
	jr nz, AccAutoPlay_Periodic_Padding
	calr AccAutoPlay_Disable
	jr __jrt_nop_F5ABD8
__jrt_nop_F5ABD8:

AccAutoPlay_Periodic_Padding:
	anddi8 13422, 251
	jr AccAutoPlay_Periodic_Return

AccAutoPlay_Periodic_Process:
	cpdi16 61854, 0
	jr nz, AccAutoPlay_Periodic_Toggle
	cpdi16 10408, 0
	jr z, AccAutoPlay_Periodic_Return

AccAutoPlay_Periodic_Toggle:
	calr AccAutoPlay_Disable

AccAutoPlay_Periodic_Return:
	ret

AccAutoPlay_Disable:
	anddi8 64607, 253
	ldb w, 0x2
	ldb a, 0x0
	ldb d, 0x5
	ldb e, 0x48
	call SwbtWr_QueuePostEvent
	ret

AccAutoPlay_Disable_Return:
	.byte 0x00, 0x00

AccAutoPlay_SubModeA:
	bitda 7, 13421
	jr z, AccAutoPlay_SubModeA_Return
	bitda 2, 1054
	jr nz, AccAutoPlay_SubModeA_Apply
	bitda 0, 12931
	jr z, AccAutoPlay_SubModeA_Check
	bitda 1, 12931
	jr z, AccAutoPlay_SubModeA_Check
	anddi8 13421, 239
	ordi8 13421, 1
	jr AccAutoPlay_SubModeA_Return

AccAutoPlay_SubModeA_Check:
	anddi8 13421, 239
	ordi8 13421, 4
	jr AccAutoPlay_SubModeA_Return

AccAutoPlay_SubModeA_Apply:
	ldda8 a, 1056
	bit 2, a
	jr z, AccAutoPlay_SubModeA_Return
	bit 3, a
	jr z, AccAutoPlay_SubModeA_Return
	anddi8 1056, 247
	anddi8 1054, 247
	anddi8 13421, 239
	ordi8 13421, 8

AccAutoPlay_SubModeA_Return:
	ret

AccAutoPlay_SubModeA_Padding:
	.byte 0x00, 0x00

AccAutoPlay_SubModeB:
	bitda 7, 13421
	jr z, AccAutoPlay_SubModeB_Return
	bitda 2, 1054
	jr nz, AccAutoPlay_SubModeB_Apply
	bitda 0, 12931
	jr z, AccAutoPlay_SubModeB_Check
	bitda 1, 12931
	jr z, AccAutoPlay_SubModeB_Check
	anddi8 13421, 239
	ordi8 13421, 2
	jr AccAutoPlay_SubModeB_Return

AccAutoPlay_SubModeB_Check:
	anddi8 13421, 239
	ordi8 13421, 4
	jr AccAutoPlay_SubModeB_Return

AccAutoPlay_SubModeB_Apply:
	ldda8 a, 1056
	bit 2, a
	jr z, AccAutoPlay_SubModeB_Return
	bit 3, a
	jr z, AccAutoPlay_SubModeB_Return
	anddi8 1056, 247
	anddi8 1054, 247
	anddi8 1057, 247
	anddi8 13421, 239
	ordi8 13421, 8

AccAutoPlay_SubModeB_Return:
	ret

AccAutoPlay_SubModeB_Padding:
	.byte 0x00, 0x00

AccAutoPlay_SeqHandoff:
	cpdi8 14235, 0
	jr nz, AccAutoPlay_SeqHandoff_Return
	cpdi16 10410, 0
	jr nz, AccAutoPlay_SeqHandoff_Return
	bitda 2, 1054
	jr z, AccAutoPlay_SeqHandoff_Return
	anddi8 13421, 247
	ordi8 13421, 16
	cpdi16 61854, 0
	jr nz, AccAutoPlay_SeqHandoff_Process
	bitda 2, 1056
	jr z, AccAutoPlay_SeqHandoff_Return
	ei 6
	calr AccPlayMode_StopToSync2
	ei 0
	jr AccAutoPlay_SeqHandoff_Return

AccAutoPlay_SeqHandoff_Process:
	bitda 2, 1057
	jr z, AccAutoPlay_SeqHandoff_Return
	bitda 2, 1054
	jr z, AccAutoPlay_SeqHandoff_Finalize
	ei 6
	calr AccPlayMode_StopExprFull
	ei 0
	jr AccAutoPlay_SeqHandoff_Return

AccAutoPlay_SeqHandoff_Finalize:
	ei 6
	calr AccPlayMode_StopExprC
	ei 0

AccAutoPlay_SeqHandoff_Return:
	ret

AccAutoPlay_SeqHandoff_Padding:
	.byte 0x00, 0x00

AccAutoPlay_ModeDecode:
	ldda8 a, 10407
	and a, 0x3
	cps a, 2
	jr nz, AccAutoPlay_ModeDecode_Process
	ordi8 13422, 160
	jr AccAutoPlay_ModeDecode_Return

AccAutoPlay_ModeDecode_Process:
	cps a, 1
	jr nz, AccAutoPlay_ModeDecode_Apply
	ordi8 13422, 96
	jr AccAutoPlay_ModeDecode_Return

AccAutoPlay_ModeDecode_Apply:
	cps a, 3
	jr nz, AccAutoPlay_ModeDecode_Return
	ordi8 13422, 224

AccAutoPlay_ModeDecode_Return:
	ret

AccAutoPlay_ModeDecode_Padding:
	.byte 0x00, 0x00

AccAutoPlay_ActionDispatch:
	ldda8 a, 13421
	bit 7, a
	jr z, AccAutoPlay_Action_Check
	bitda 2, 13421
	jr z, AccAutoPlay_Action_Finalize
	and a, 0xFB
	or a, 0x8
	stda8 13421, a

AccAutoPlay_Action_Check:
	ldda8 a, 13422
	ld b, a
	and a, 0xE0
	cps a, 0
	ld a, b
	jr z, AccAutoPlay_Action_Return
	bit 7, a
	jr z, AccAutoPlay_Action_Activate
	bit 5, a
	jr nz, AccAutoPlay_Action_Process
	calr AccPlayMode_StartAccPlay
	jr AccAutoPlay_Action_Apply

AccAutoPlay_Action_Process:
	bit 6, a
	jr z, AccAutoPlay_Action_Deactivate
	calr AccPlayMode_StopExprB
	jr AccAutoPlay_Action_Apply

AccAutoPlay_Action_Activate:
	calr AccPlayMode_StartPlayFull
	jr AccAutoPlay_Action_Apply

AccAutoPlay_Action_Deactivate:
	calr AccPlayMode_StartAccPlayFull

AccAutoPlay_Action_Apply:
	bitda 3, 13421
	jr nz, AccAutoPlay_Action_Finalize

AccAutoPlay_Action_Finalize:
	anddi8 13422, 31

AccAutoPlay_Action_Return:
	ret

AccAutoPlay_Action_Padding:
	.byte 0x00, 0x00

AccAutoPlay_DeferredAction:
	bitda 7, 13421
	jr z, AccAutoPlay_Deferred_Return
	bitda 0, 13421
	jr z, AccAutoPlay_Deferred_Process
	anddi8 13421, 238
	ordi8 13421, 8
	ei 6
	calr AccPlayMode_StartAccPlayFull
	ei 0
	calr AccReplay_FullRestart
	jr AccAutoPlay_Deferred_Return

AccAutoPlay_Deferred_Process:
	bitda 1, 13421
	jr z, AccAutoPlay_Deferred_Return
	anddi8 13421, 237
	ordi8 13421, 8
	ei 6
	calr AccPlayMode_StartPlay
	ei 0
	calr AccReplay_FullRestart

AccAutoPlay_Deferred_Return:
	ret

AccAutoPlay_Deferred_Padding:
	.byte 0x00, 0x00

AccPlayMode_Dispatch:
	xor xhl, xhl
	ei 6
	bitda 2, 1054
	jr z, AccPlayMode_Dispatch_Check
	or l, 0x4

AccPlayMode_Dispatch_Check:
	bitda 2, 1057
	jr z, AccPlayMode_Dispatch_Select
	or l, 0x8

AccPlayMode_Dispatch_Select:
	bitda 2, 1056
	jr z, AccPlayMode_Dispatch_Execute
	or l, 0x10

AccPlayMode_Dispatch_Execute:
	ld xwa, 0xF5ADF9
	add xhl, xwa
	ld xwa, (xhl)
	call (xwa)
	ei 0
	ret

AccPlayMode_Dispatch_Table:
	nop
	nop
	pop_f
	.byte 0xae, 0xf5, 0x00
	popw	iy
	.byte 0xaf, 0xf5, 0x00, 0xd0, 0xaf, 0xf5
	nop
	.byte 0x04, 0xb0, 0xf5
	nop
	.byte 0xb7, 0xaf, 0xf5, 0x00, 0x3c, 0xaf, 0xf5, 0x00, 0xb2, 0xaf, 0xf5, 0x00, 0x9d, 0xaf, 0xf5, 0x00
	ret
	nop
	nop

AccPlayMode_TransitionRouter:
	cpdi16 10408, 0
	jr z, AccPlayMode_Router_Process
	cpdi16 61854, 0
	jr z, AccPlayMode_Router_Check
	calr AccPlayMode_Router_Alt
	jr AccPlayMode_Router_Return

AccPlayMode_Router_Check:
	calr AccPlayMode_StartRecording
	jr AccPlayMode_Router_Return

AccPlayMode_Router_Process:
	cpdi16 61854, 0
	jr z, AccPlayMode_Router_Apply
	calr AccPlayMode_StartAcc
	jr AccPlayMode_Router_Return

AccPlayMode_Router_Apply:
	calr AccPlayMode_StopToSync

AccPlayMode_Router_Return:
	ret

AccPlayMode_Router_Padding:
	.byte 0x00, 0x00

AccPlayMode_Router_Alt:
	bitda 2, 1056
	jr nz, AccPlayMode_Router_AltPadding
	calr AccPlayMode_StartPlay
	jr __jrt_nop_F5AE54
__jrt_nop_F5AE54:

AccPlayMode_Router_AltPadding:
	ret

AccPlayMode_StartRecording_Padding:
	.byte 0x00, 0x00

AccPlayMode_StartRecording:
	bitda 2, 1056
	jr nz, AccPlayMode_StartRec_Apply
	bitda 1, 10407
	jr z, AccPlayMode_StartRec_Process
	ei 6
	calr AccPlayMode_StopExprB
	ei 0
	jr AccPlayMode_StartRec_Return

AccPlayMode_StartRec_Process:
	calr AccPlayMode_Dispatch
	jr AccPlayMode_StartRec_Return

AccPlayMode_StartRec_Apply:
	calr AccPlayMode_StopExprA

AccPlayMode_StartRec_Return:
	ret

AccPlayMode_StartRec_Padding:
	.byte 0x00, 0x00

AccPlayMode_StartAcc:
	bitda 2, 1056
	jr nz, AccPlayMode_StartAcc_Apply
	bitda 1, 10407
	jr z, AccPlayMode_StartAcc_Process
	ei 6
	calr AccPlayMode_StopExprB
	ei 0
	jr AccPlayMode_StartAcc_Return

AccPlayMode_StartAcc_Process:
	ei 6
	calr AccPlayMode_StartPlayFull
	ei 0
	jr AccPlayMode_StartAcc_Return

AccPlayMode_StartAcc_Apply:
	calr AccPlayMode_Dispatch

AccPlayMode_StartAcc_Return:
	ret

AccPlayMode_StartAcc_Padding:
	.byte 0x00, 0x00

AccPlayMode_StopToSync:
	bitda 2, 1056
	jr nz, AccPlayMode_StopToSync_Process
	ei 6
	calr AccPlayMode_StartAccPlayFull
	ei 0
	jr AccPlayMode_StopToSync_Return

AccPlayMode_StopToSync_Process:
	ei 6
	calr AccPlayMode_StopToSync2
	ei 0

AccPlayMode_StopToSync_Return:
	ret

AccPlayMode_StopToSync_Padding:
	.byte 0x00, 0x00

AccPlayMode_StartPlay:
	bitda 2, 10407
	jr nz, AccPlayMode_StartPlay_Return
	bitda 1, 10407
	jr nz, AccPlayMode_StartPlay_Process
	ei 6
	calr AccPlayMode_StartPlayFull
	ei 0
	jr AccPlayMode_StartPlay_Return

AccPlayMode_StartPlay_Process:
	ei 6
	calr AccPlayMode_StopExprB
	ei 0

AccPlayMode_StartPlay_Return:
	ret

AccPlayMode_StartPlay_Padding:
	.byte 0x00, 0x00

AccPlayMode_StopExprA:
	bitda 2, 1054
	jr nz, AccPlayMode_StopExprA_Process
	ei 6
	calr AccPlayMode_StartAccPlay
	ei 0
	jr AccPlayMode_StopExprA_Return

AccPlayMode_StopExprA_Process:
	ei 6
	calr AccPlayMode_StartPlay2
	ei 0

AccPlayMode_StopExprA_Return:
	ret

AccPlayMode_StopExprA_Padding:
	.byte 0x00, 0x00

AccPlayMode_StopExprB:
	bitda 0, 1056
	jr nz, AccPlayMode_StopExprB_Return
	bitda 2, 1056
	jr nz, AccPlayMode_StopExprB_Return
	bitda 2, 10418
	jr nz, AccPlayMode_StopExprB_Process
	bitda 1, 10418
	jr z, AccPlayMode_StopExprB_Process
	call SeqPlay_SetBarAndResetScroll
	stdi8 1054, 128
	ordi8 10418, 4
	jr AccPlayMode_StartAccPlay_Return

AccPlayMode_StopExprB_Process:
	stdi8 1056, 1
	calr AccTempo_ClearCounters
	calr AccSync_MidiClock

AccPlayMode_StopExprB_Return:
	stdi8 1057, 1
	calr AccTempo_ClearSubPos

AccPlayMode_StartAccPlay:
	stdi8 1054, 1
	ordi8 13428, 1
	calr AccTempo_ClearPositions
	ldb a, 0x85
	calr AccTempo_WriteStartMarker

AccPlayMode_StartAccPlay_Return:
	ret

AccPlayMode_StartAccPlay_Padding:
	.byte 0x00, 0x00

AccPlayMode_StopToSync2:
	bitda 3, 1056
	jr nz, AccPlayMode_StartPlay2
	bitda 2, 1056
	jr z, AccPlayMode_StartPlay2
	stdi8 1056, 12

AccPlayMode_StartPlay2:
	stdi8 1054, 12
	stdi8 13424, 0
	ldb a, 0x86
	calr AccTempo_WriteStartMarker
	ret

AccPlayMode_StartPlay2_Padding:
	.byte 0x00, 0x00

AccPlayMode_StartPlayFull:
	bitda 2, 10418
	jr nz, AccPlayMode_StartPlayFull_Process
	bitda 1, 10418
	jr z, AccPlayMode_StartPlayFull_Process
	call SeqPlay_SetBarAndResetScroll
	stdi8 1054, 128
	ordi8 10418, 4
	jr AccPlayMode_StartPlayFull_Return

AccPlayMode_StartPlayFull_Process:
	stdi8 1057, 1
	calr AccTempo_ClearSubPos
	bitda 0, 1056
	jr nz, AccPlayMode_StartPlayFull_Return
	bitda 2, 1056
	jr nz, AccPlayMode_StartPlayFull_Return
	stdi8 1056, 1
	calr AccTempo_ClearCounters
	calr AccSync_MidiClock

AccPlayMode_StartPlayFull_Return:
	ret

AccPlayMode_StartPlayFull_Padding:
	.byte 0x00, 0x00

AccPlayMode_StopExprFull:
	stdi8 1054, 12
	bitda 0, 10418
	jr nz, AccPlayMode_StopExprFull_Process
	ordi8 13434, 4

AccPlayMode_StopExprFull_Process:
	ldb a, 0x86
	calr AccTempo_WriteStartMarker

AccPlayMode_StopExprC:
	stdi8 1057, 12
	bitda 3, 1056
	jr nz, AccPlayMode_StopExprC_Process
	bitda 2, 1056
	jr z, AccPlayMode_StopExprC_Process
	stdi8 1056, 12

AccPlayMode_StopExprC_Process:
	stdi8 13424, 0
	ret

AccPlayMode_StopExprC_Return:
	.byte 0x00, 0x00

AccPlayMode_StopExprD:
	stdi8 1057, 12
	ret

AccPlayMode_StopExprD_Return:
	.byte 0x00, 0x00

AccPlayMode_StartAccPlayFull:
	stdi8 1054, 1
	ordi8 13428, 1
	calr AccTempo_ClearPositions
	ldb a, 0x85
	calr AccTempo_WriteStartMarker
	bitda 0, 1056
	jr nz, AccPlayMode_StartAccPlayFull_Return
	bitda 2, 1056
	jr nz, AccPlayMode_StartAccPlayFull_Return
	stdi8 1056, 1
	calr AccTempo_ClearCounters
	calr AccSync_MidiClock

AccPlayMode_StartAccPlayFull_Return:
	ret

AccPlayMode_StartAccPlayFull_Padding:
	nop
	nop
	stdi8	1057, 12
	stdi8	1054, 12
	.byte 0xc1, 0x70, 0x34, 0x3c, 0x0f
	ldb	a, 134
	calr	108
	ret
	nop
	nop

AccTempo_ClearCounters:
	xor wa, wa
	ei 6
	stda8 1047, a
	stda16 1048, xwa
	ei 0
	ret

AccTempo_ClearPositions:
	xor wa, wa
	ei 6
	bitda 0, 10406
	jr nz, AccTempo_ClearPositions_Loop
	stda8 1045, a
	stda8 1046, a

AccTempo_ClearPositions_Loop:
	stda8 1076, a
	stda8 1077, a
	ei 0
	anddi8 10406, 254
	ret

AccTempo_ClearSubPos:
	xor wa, wa
	ei 6
	bitda 3, 10407
	jr nz, AccTempo_ClearSubPos_Loop
	stda16 1052, xwa
	stda8 1051, a

AccTempo_ClearSubPos_Loop:
	ei 0
	ret

AccSync_MidiClock:
	bitda 2, 64850
	jr z, AccSync_MidiClock_Return
	ei 6
	bitda 3, 10407
	jr z, AccSync_MidiClock_Update
	ordi8 1065, 4
	jr AccSync_MidiClock_Apply

AccSync_MidiClock_Update:
	ordi8 1065, 2

AccSync_MidiClock_Apply:
	call MIDI_SC0_TX_DISPATCH
	ei 0

AccSync_MidiClock_Return:
	ret

AccSync_MidiClock_Padding:
	.byte 0x00, 0x00

AccTempo_WriteStartMarker:
	cpdi16 10410, 0
	jr z, AccTempo_WriteMarker_Return

AccTempo_WriteStopMarker:
	ei 6
	pushw wa
	call TempoRingBuf_WriteByte_Ext
	inc 2, xsp
	ldda8 a, 1051
	pushw wa
	call TempoRingBuf_WriteByte_Ext
	inc 2, xsp
	ei 0

AccTempo_WriteMarker_Return:
	ret

AccTempo_WriteMarker_Padding:
	nop
	nop
	ret

AccReplay_FullRestart:
	stdi8 13428, 0
	ordi8 13457, 1
	calr AccPlayMode_WaitIdle
	xor bc, bc

AccReplay_Restart_WaitIdle:
	pushw bc
	call SeqTiming_Snapshot
	popw bc
	xor wa, wa
	pushw bc
	call RhythmBuf_CheckEmpty
	popw bc
	cps wa, 0
	jr nz, AccReplay_Restart_Snapshot
	inc 1, bc
	cp bc, 0x200
	jr c, AccReplay_Restart_WaitIdle
	jr AccReplay_Restart_ReInit

AccReplay_Restart_Snapshot:
	call RhythmBuf_DispatchWrap
	xor wa, wa
	call RhythmBuf_CheckEmpty
	cps wa, 0
	jr z, AccReplay_Restart_ReInit
	call RhythmBuf_DispatchWrap
	calr AccTiming_AlignTo8Tick
	calr AccTempo_CheckSource
	call SeqTiming_Snapshot

AccReplay_Restart_Drain:
	xor wa, wa
	call RhythmBuf_CheckEmpty
	cps wa, 0
	jr z, AccReplay_Restart_ReInit
	call RhythmBuf_DispatchWrap
	jr AccReplay_Restart_Drain

AccReplay_Restart_ReInit:
	anddi8 13457, 254
	ret

AccReplay_Restart_Return:
	.byte 0x00, 0x00

AccTiming_AlignTo8Tick:
	pushw hl
	ldw bc, 0x8
	ldda16 xwa, 1033
	add wa, bc

AccTiming_Align_Compute:
	ld hl, wa
	subda16 xhl, 1033
	cps hl, 0
	jr le, AccTiming_Align_Return
	jr AccTiming_Align_Compute

AccTiming_Align_Return:
	popw hl
	ret

AccPlayMode_WaitIdle:
	xor bc, bc

AccPlayMode_WaitIdle_Check:
	bitda 0, 1054
	jr z, AccPlayMode_WaitIdle_Loop
	inc 1, bc
	cp bc, 0x500
	jr nz, AccPlayMode_WaitIdle_Check

AccPlayMode_WaitIdle_Loop:
	ret

AccPlayMode_WaitIdle_Return:
	.byte 0x00, 0x00

AccTempo_CheckSource:
	cpdi8 1115, 1
	jr nz, AccTempo_CheckSource_Process
	cpdi8 52959, 0
	jr z, AccTempo_CheckSource_Process
	stdi8 1115, 0

AccTempo_CheckSource_Process:
	bitda 0, 1115
	jr z, AccTempo_CheckSource_Clear
	bitda 2, 1054
	jr nz, AccTempo_CheckSource_Return

AccTempo_CheckSource_Clear:
	call Seq_DispatcherEntry
	stdi8 1124, 0

AccTempo_CheckSource_Return:
	ret

AccTempo_CheckSource_Padding:
	.byte 0x00, 0x00

AccReplay_SavedPedal:
	ldda8 a, 49277
	pushw wa
	ldda8 w, 49278
	ldda8 a, 49279
	pushw wa
	ldda8 a, 13448
	stda8 49277, a
	ldda8 a, 13429
	stda8 49278, a
	ldda8 a, 13430
	stda8 49279, a
	ldda8 a, 37112
	pushw wa
	stdi8 37112, 0
	calr AccPedal_EventDispatch
	popw wa
	stda8 37112, a
	popw wa
	stda8 49278, w
	stda8 49279, a
	popw wa
	stda8 49277, a
	xor a, a
	stda8 13429, a
	stda8 13430, a
	stda8 13448, a
	lds wa, 0
	ldb d, 0x5
	ldb e, 0x48
	call SwbtWr_QueuePostEvent
	lds wa, 0
	ldb d, 0x6
	ldb e, 0x48
	call SwbtWr_QueuePostEvent
	call AudioMode_SetStereoFlags
	ret

AccReplay_SavedPedal_Return:
	.byte 0x00, 0x00

AccReplay_SendPedalType5:
	push xiz
	calr AccReplay_SendPedalType6
	pop xiz
	ret

AccReplay_SendPedalType6:
	ld hl, wa
	ldda8 a, 49277
	pushw wa
	ldda8 w, 49278
	ldda8 a, 49279
	pushw wa
	cps l, 0
	jr nz, AccReplay_SendPedal_Process
	stdi8 49277, 5
	stdi8 49278, 4
	stdi8 49279, 4
	jr AccReplay_SendPedal_Dispatch

AccReplay_SendPedal_Process:
	stdi8 49277, 6
	stdi8 49278, 4
	stdi8 49279, 4

AccReplay_SendPedal_Dispatch:
	ldda8 a, 37112
	pushw wa
	stdi8 37112, 0
	calr AccPedal_EventDispatch
	popw wa
	stda8 37112, a
	popw wa
	stda8 49278, w
	stda8 49279, a
	popw wa
	stda8 49277, a
	lds wa, 0
	ldb d, 0x5
	ldb e, 0x48
	call SwbtWr_QueuePostEvent
	lds wa, 0
	ldb d, 0x6
	ldb e, 0x48
	call SwbtWr_QueuePostEvent
	call AudioMode_SetStereoFlags
	ret

AccReplay_SendPedal_Return:
	.byte 0x00, 0x00

AccReplay_SavedExpression:
	ldda8 a, 49277
	pushw wa
	ldda8 w, 49278
	ldda8 a, 49279
	pushw wa
	ldda8 a, 13449
	stda8 49277, a
	ldda8 a, 13436
	stda8 49278, a
	ldda8 a, 13437
	stda8 49279, a
	ldda8 a, 37112
	pushw wa
	stdi8 37112, 255
	calr AccPedal_EventDispatch
	popw wa
	stda8 37112, a
	popw wa
	stda8 49278, w
	stda8 49279, a
	popw wa
	stda8 49277, a
	xor a, a
	stda8 13436, a
	stda8 13437, a
	stda8 13449, a
	lds wa, 0
	ldb d, 0x5
	ldb e, 0x48
	call SwbtWr_QueuePostEvent
	lds wa, 0
	ldb d, 0x6
	ldb e, 0x48
	call SwbtWr_QueuePostEvent
	call AudioMode_SetStereoFlags
	ret

AccReplay_SavedExpr_Return:
	nop
	nop
	ld	xwa, 608256
	add	xwa, 14
	ld	wa, (xwa)
	cps	wa, 0
	jr	z, 4
	call	16116017
	ret
	nop
	nop

AccReplay_FullStop:
	ldda8 a, 64607
	and a, 0xC
	ldda8 c, 64608
	and c, 0x4
	or a, c
	cps a, 0
	jr z, AccReplay_Stop_ClearPedals
	anddi8 64607, 243
	lds wa, 0
	ldb d, 0x5
	ldb e, 0x48
	call SwbtWr_QueuePostEvent
	anddi8 64608, 251
	lds wa, 0
	ldb d, 0x6
	ldb e, 0x48
	call SwbtWr_QueuePostEvent

AccReplay_Stop_ClearPedals:
	call Seq_DispatcherEntry
	cpdi8 13433, 0
	jr z, AccReplay_Stop_ResetPosition
	ldda8 a, 13433
	adddm8 1079, a
	stdi8 13433, 0

AccReplay_Stop_ResetPosition:
	anddi8 1079, 7
	ldda8 a, 1079
	cpda8 a, 1075
	jr c, AccReplay_Stop_Rebuild
	subda8 a, 1075
	stda8 1079, a
	ldda8 a, 1075
	stda8 13433, a

AccReplay_Stop_Rebuild:
	xor wa, wa
	stda8 1045, a
	stda8 1046, a
	ordi8 13517, 128
	ordi8 13434, 1
	ldda8 e, 1078
	ldda8 d, 1079
	cps de, 0
	jr z, AccReplay_Stop_Finalize
	sub e, 0x18
	jr nc, AccReplay_Stop_CheckMode
	add e, 0x60
	dec 1, d
	cp d, 0xFF
	jr nz, AccReplay_Stop_CheckMode
	lds de, 0

AccReplay_Stop_CheckMode:
	xor bc, bc
	anddi8 13434, 127

AccReplay_Stop_Process:
	stda8 1045, c
	stda8 1046, b
	pushw bc
	pushw de
	call Seq_DispatcherEntry
	popw de
	popw bc
	add c, 0x18
	cp c, 0x60
	jr nz, AccReplay_Stop_UpdateFlags
	inc 1, b
	xor c, c

AccReplay_Stop_UpdateFlags:
	bitda 7, 13434
	jr nz, AccReplay_Stop_Finalize
	cp bc, de
	jr c, AccReplay_Stop_Process
	ordi8 13434, 128
	cp bc, de
	jr z, AccReplay_Stop_Process
	ld bc, de
	jr AccReplay_Stop_Process

AccReplay_Stop_Finalize:
	ldda8 a, 1078
	stda8 1045, a
	ldda8 a, 1079
	stda8 1046, a
	anddi8 13434, 254
	call Seq_DispatcherEntry
	ret

AccReplay_Stop_Return:
	.byte 0x00, 0x00

AccPos_SaveOnStop:
	ldda8 a, 49279
	cps a, 0
	jr z, AccPos_SaveOnStop_Return
	bitda 0, 10406
	jr z, AccPos_SaveOnStop_Return
	ei 6
	ldda8 a, 1045
	stda8 1078, a
	ldda8 a, 1046
	stda8 1079, a
	xor wa, wa
	stda8 1045, a
	stda8 1046, a
	ei 0
	calr AccReplay_FullStop

AccPos_SaveOnStop_Return:
	ret

AccPos_SaveOnStop_Padding:
	.byte 0x00, 0x00

AccPos_ClearOnStart:
	bitda 0, 12931
	jr nz, AccPos_ClearOnStart_Return
	xor wa, wa
	ei 6
	stda8 1045, a
	stda8 1046, a
	ei 0
	stda8 1078, a
	stda8 1079, a
	stda8 13433, a
	ordi8 13517, 128
	call Seq_DispatcherEntry

AccPos_ClearOnStart_Return:
	ret

AccPos_ClearOnStart_Padding:
	nop
	nop
	cpdi8	36148, 19
	jr	nz, 12
	.byte 0xc1, 0x7a, 0x34, 0x3c, 0xfd, 0xc1, 0xa6, 0x28, 0x3c, 0xfe
	jr	30
	.byte 0xf1, 0x7a, 0x34, 0xc9
	jr	z, 24
	ldda8	a, 12931
	and	a, 3
	cps	a, 0
	jr	nz, 13
	stdi8	13433, 0
	calr	-378
	.byte 0xc1, 0x7a, 0x34, 0x3c, 0xfd
	ret
	nop
	nop

AccFlags_SyncTo64607:
	ldda8 e, 1056
	anddi8 64607, 254
	bit 2, e
	jr z, AccFlags_Sync_Process
	ordi8 64607, 1

AccFlags_Sync_Process:
	ld a, e
	xorda8 a, 13435
	bit 2, a
	jr z, AccFlags_Sync_UpdateLED
	ldb a, 0x22
	call CtrlPanel_SetIndicatorBit

AccFlags_Sync_UpdateLED:
	stda8 13435, e
	bitda 0, 13470
	jr z, AccFlags_Sync_Return
	anddi8 13470, 254

AccFlags_Sync_Return:
	ret

AccFlags_Sync_Padding:
	.byte 0x00, 0x00

AccTiming_InitAllParts:
	stdi16 13172, 65375
	stdi16 13180, 6
	stdi16 13182, 48
	ld xbc, 0x3094
	calr AccKbdTiming_TableScan
	ld xbc, 0x30C4
	calr AccKbdTiming_TableScan
	stdi16 13180, 9
	stdi16 13182, 72
	stdi8 13196, 7
	ld xbc, 0x30F4
	calr AccAccTiming_TableScan
	stdi8 13196, 4
	ld xbc, 0x313C
	calr AccAccTiming_TableScan
	stdi8 13196, 5
	ld xbc, 0x3184
	calr AccAccTiming_TableScan
	stdi8 13196, 6
	ld xbc, 0x31CC
	calr AccAccTiming_TableScan
	ldda16 xwa, 13172
	stda16 13170, xwa
	jr __jrt_nop_F5B4EA
__jrt_nop_F5B4EA:

AccTiming_MasterTick_Return:
	ret

AccTiming_MasterTick:
	stdi8 13175, 95
	stdi16 13180, 6
	stdi16 13182, 48
	ldda8 a, 13189
	stda8 13188, a
	ld xhl, 0x2A94
	ld xbc, 0x3094
	calr AccKbdTiming_ScanRingBuf
	ldda8 a, 13188
	stda8 13189, a
	ldda8 a, 13190
	stda8 13188, a
	ld xhl, 0x2B94
	ld xbc, 0x30C4
	calr AccKbdTiming_ScanRingBuf
	ldda8 a, 13188
	stda8 13190, a
	stdi16 13180, 9
	anddi8 13197, 254
	stdi16 13182, 72
	stdi8 13196, 7
	ldda8 a, 13191
	stda8 13188, a
	ldda8 a, 13103
	stda8 13107, a
	ld xhl, 0x2C94
	ld xbc, 0x30F4
	calr AccAccTiming_ScanRingBuf
	ldda8 a, 13188
	stda8 13191, a
	ldda8 a, 13107
	stda8 13103, a
	stdi8 13196, 4
	ldda8 a, 13192
	stda8 13188, a
	ldda8 a, 13104
	stda8 13107, a
	ld xhl, 0x2D94
	ld xbc, 0x313C
	calr AccAccTiming_ScanRingBuf
	ldda8 a, 13188
	stda8 13192, a
	ldda8 a, 13107
	stda8 13104, a
	stdi8 13196, 5
	ldda8 a, 13193
	stda8 13188, a
	ldda8 a, 13105
	stda8 13107, a
	ld xhl, 0x2E94
	ld xbc, 0x3184
	calr AccAccTiming_ScanRingBuf
	ldda8 a, 13188
	stda8 13193, a
	ldda8 a, 13107
	stda8 13105, a
	stdi8 13196, 6
	ldda8 a, 13194
	stda8 13188, a
	ldda8 a, 13106
	stda8 13107, a
	ld xhl, 0x2F94
	ld xbc, 0x31CC
	calr AccAccTiming_ScanRingBuf
	ldda8 a, 13188
	stda8 13194, a
	ldda8 a, 13107
	stda8 13106, a
	ldda8 a, 13175
	stda8 13174, a
	jr __jrt_nop_F5B619
__jrt_nop_F5B619:

AccKbdTiming_Ret:
	ret

AccKbdTiming_ScanRingBuf:
	stdi8 14968, 255
	ld ix, (xhl + 6)

AccKbdTiming_EventLoop:
	cp (xhl + 4), ix
	jrl z, AccKbdTiming_ScanDone
	ld_srib3 A, 0x07, 0xEC, 0xF0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_ClassifyEvent
	ld ix, (xhl + 256)

AccKbdTiming_ClassifyEvent:
	ld w, a
	cp a, 0xDF
	jr z, AccKbdTiming_SpecialEvent
	cp a, 0x9F
	jr nz, AccKbdTiming_CheckNoteOn

AccKbdTiming_SpecialEvent:
	stdi8 13184, 2
	jr AccKbdTiming_StoreEventData

AccKbdTiming_CheckNoteOn:
	cp a, 0x90
	jr nz, AccKbdTiming_CheckProgramChg
	stdi8 13184, 4
	jr AccKbdTiming_StoreEventData

AccKbdTiming_CheckProgramChg:
	and a, 0xF0
	cp a, 0xC0
	jr nz, AccKbdTiming_CheckControl
	stdi8 13184, 5
	jr AccKbdTiming_StoreEventData

AccKbdTiming_CheckControl:
	cp a, 0xD0
	jrl nz, AccKbdTiming_SkipEvent
	stdi8 13184, 2

AccKbdTiming_StoreEventData:
	stda8 14969, a
	ld_srib3 A, 0x07, 0xEC, 0xF0
	stda16 13176, xix
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_CheckTimestamp
	ld ix, (xhl + 256)

AccKbdTiming_CheckTimestamp:
	cpda8 a, 1117
	jrl ugt, AccKbdTiming_TimestampOverflow
	ld a, w
	and a, 0xF0
	cp w, 0x9F
	jrl z, AccKbdTiming_WriteNonNote
	cp w, 0xDF
	jrl z, AccKbdTiming_WriteNonNote
	cp a, 0x90
	jrl nz, AccKbdTiming_WriteNonNote_Prep
	cpdi8 14968, 0
	jr nz, AccKbdTiming_NoteSlotScan
	pushw wa
	ldb a, 0x8
	stda8 14972, a
	popw wa
	calr AccKbdTiming_CatchupReplay
	stdi8 14968, 255

AccKbdTiming_NoteSlotScan:
	xor iz, iz

AccKbdTiming_SlotLoop:
	cpda16 xiz, 13182
	jr nc, AccKbdTiming_SlotOverflow
	bit_dri 7, 0x07, 0xE4, 0xF8
	jr z, AccKbdTiming_WriteNoteEvent
	addda16 xiz, 13180
	jr AccKbdTiming_SlotLoop

AccKbdTiming_SlotOverflow:
	pushw wa
	xor xwa, xwa
	ldda8 a, 13188
	sla xwa, 2
	add xwa, 0xF5BD36
	ld iz, (xwa)
	ld_srib3 A, 0x07, 0xE4, 0xF8
	and_srib_im 0x07, 0xE4, 0xF8, 0x7F
	pushw iz
	inc 2, iz
	ld_srib3 W, 0x07, 0xE4, 0xF8
	and a, 0xF0
	or a, 0x8
	calr AccSeq_WriteByte
	ld a, w
	calr AccSeq_WriteByte
	ldb a, 0x0
	calr AccSeq_WriteByte
	popw iz
	popw wa
	incdi8 1, 13188
	cpdi8 13188, 8
	jr c, AccKbdTiming_SlotOverflow_Done
	stdi8 13188, 0

AccKbdTiming_SlotOverflow_Done:
	jr AccKbdTiming_WriteNoteEvent

AccKbdTiming_SkipEvent:
	ld ix, (xhl + 4)
	ld (xhl + 6), ix
	jrl AccKbdTiming_EventLoop

AccKbdTiming_WriteNoteEvent:
	or a, 0x8
	calr AccSeq_WriteByte
	ld a, w
	lda_dri3 XBC, 0x07, 0xE4, 0xF8
	inc 1, iz
	ldb a, 0x0
	lda_dri3 XBC, 0x07, 0xE4, 0xF8
	inc 1, iz
	ld_srib3 A, 0x07, 0xEC, 0xF0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNote_Byte2
	ld ix, (xhl + 256)

AccKbdTiming_WriteNote_Byte2:
	calr AccSeq_WriteByte
	lda_dri3 XBC, 0x07, 0xE4, 0xF8
	inc 1, iz
	ld_srib3 A, 0x07, 0xEC, 0xF0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNote_Byte3
	ld ix, (xhl + 256)

AccKbdTiming_WriteNote_Byte3:
	calr AccSeq_WriteByte
	lda_dri3 XBC, 0x07, 0xE4, 0xF8
	inc 1, iz
	ld_srib3 A, 0x07, 0xEC, 0xF0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNote_ReadTiming
	ld ix, (xhl + 256)

AccKbdTiming_WriteNote_ReadTiming:
	ld_srib3 W, 0x07, 0xEC, 0xF0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNote_ClampTiming
	ld ix, (xhl + 256)

AccKbdTiming_WriteNote_ClampTiming:
	cp wa, 0xA
	jr ugt, AccKbdTiming_WriteNote_AddBase
	ldw wa, 0xA

AccKbdTiming_WriteNote_AddBase:
	addda16 xwa, 1118
	cp a, 0x60
	jr c, AccKbdTiming_WriteNote_StoreTiming
	inc 1, w
	sub a, 0x60

AccKbdTiming_WriteNote_StoreTiming:
	st_dri3w WA, 0x07, 0xE4, 0xF8
	cpda16 xwa, 13170
	jr nc, AccKbdTiming_WriteNote_UpdateReadPos
	stda16 13170, xwa

AccKbdTiming_WriteNote_UpdateReadPos:
	ld (xhl + 6), ix
	jrl AccKbdTiming_EventLoop

AccKbdTiming_WriteNonNote_Prep:
	ld w, a
	or a, 0x8

AccKbdTiming_WriteNonNote:
	calr AccSeq_WriteByte
	ld_srib3 A, 0x07, 0xEC, 0xF0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNonNote_Byte2
	ld ix, (xhl + 256)

AccKbdTiming_WriteNonNote_Byte2:
	calr AccSeq_WriteByte
	ld_srib3 A, 0x07, 0xEC, 0xF0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNonNote_Byte3
	ld ix, (xhl + 256)

AccKbdTiming_WriteNonNote_Byte3:
	calr AccSeq_WriteByte
	cp w, 0xDF
	jr nz, AccKbdTiming_WriteNonNote_CheckType
	ldb a, 0x0
	stda8 13103, a
	stda8 13104, a
	stda8 13105, a
	stda8 13106, a
	jr AccKbdTiming_WriteNonNote_Done

AccKbdTiming_WriteNonNote_CheckType:
	cp w, 0x9F
	jr z, AccKbdTiming_WriteNonNote_Done
	cp w, 0xD0
	jr z, AccKbdTiming_WriteNonNote_Done
	ld_srib3 A, 0x07, 0xEC, 0xF0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNonNote_Byte4
	ld ix, (xhl + 256)

AccKbdTiming_WriteNonNote_Byte4:
	calr AccSeq_WriteByte
	ld_srib3 A, 0x07, 0xEC, 0xF0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNonNote_Byte5
	ld ix, (xhl + 256)

AccKbdTiming_WriteNonNote_Byte5:
	calr AccSeq_WriteByte
	ld_srib3 A, 0x07, 0xEC, 0xF0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNonNote_Byte6
	ld ix, (xhl + 256)

AccKbdTiming_WriteNonNote_Byte6:
	calr AccSeq_WriteByte

AccKbdTiming_WriteNonNote_Done:
	ld (xhl + 6), ix
	jrl AccKbdTiming_EventLoop

AccKbdTiming_TimestampOverflow:
	cpdi8 14969, 192
	jr nz, AccKbdTiming_Overflow_SubBase
	stdi8 14968, 0

AccKbdTiming_Overflow_SubBase:
	subda8 a, 1117
	cpda8 a, 13175
	jr nc, AccKbdTiming_Overflow_CalcSkip
	stda8 13175, a

AccKbdTiming_Overflow_CalcSkip:
	ldda16 xix, 13176
	lda_dri3 XBC, 0x07, 0xEC, 0xF0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_Overflow_AdvancePos
	ld ix, (xhl + 256)

AccKbdTiming_Overflow_AdvancePos:
	xor wa, wa
	ldda8 a, 13184
	add ix, wa
	cp ix, (xhl + 2)
	jrl ule, AccKbdTiming_EventLoop
	sub ix, (xhl + 2)
	dec 1, ix
	add ix, (xhl + 256)
	jrl AccKbdTiming_EventLoop

AccKbdTiming_ScanDone:
	ret

AccKbdTiming_CatchupReplay:
	push xwa
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	ld iy, ix
	ld ix, (xhl + 6)

AccKbdTiming_Catchup_Loop:
	cp ix, iy
	jr z, AccKbdTiming_Catchup_Done
	ld_srib3 A, 0x07, 0xEC, 0xF0
	ld w, a
	and w, 0xF0
	cp w, 0xC0
	jr nz, AccKbdTiming_Catchup_SkipNonC0
	ld a, w
	orda8 a, 14972
	calr AccSeq_WriteByte
	calr AccKbdTiming_AdvancePos
	calr AccKbdTiming_AdvancePos
	ld_srib3 A, 0x07, 0xEC, 0xF0
	calr AccSeq_WriteByte
	calr AccKbdTiming_AdvancePos
	ld_srib3 A, 0x07, 0xEC, 0xF0
	calr AccSeq_WriteByte
	calr AccKbdTiming_AdvancePos
	ld_srib3 A, 0x07, 0xEC, 0xF0
	calr AccSeq_WriteByte
	calr AccKbdTiming_AdvancePos
	ld_srib3 A, 0x07, 0xEC, 0xF0
	calr AccSeq_WriteByte
	calr AccKbdTiming_AdvancePos
	ld_srib3 A, 0x07, 0xEC, 0xF0
	calr AccSeq_WriteByte
	calr AccKbdTiming_AdvancePos
	jr AccKbdTiming_Catchup_Loop

AccKbdTiming_Catchup_SkipNonC0:
	calr AccKbdTiming_AdvancePos
	jr AccKbdTiming_Catchup_Loop

AccKbdTiming_Catchup_Done:
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	pop xwa
	ret

AccKbdTiming_AdvancePos:
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_AdvancePos_Ret
	ld ix, (xhl + 256)

AccKbdTiming_AdvancePos_Ret:
	ret

AccKbdTiming_TableScan:
	xor iz, iz

AccKbdTiming_TableScan_Loop:
	cpda16 xiz, 13182
	jp_24 nc, 0xF5B98D
	bit_dri 7, 0x07, 0xE4, 0xF8
	jr z, AccKbdTiming_TableScan_NextSlot
	ld ix, iz
	ld_srib3 A, 0x07, 0xE4, 0xF0
	stda8 13185, a
	inc 2, ix
	ld_srib3 A, 0x07, 0xE4, 0xF0
	stda8 13186, a
	inc 1, ix
	ld_srib3 A, 0x07, 0xE4, 0xF0
	stda8 13187, a
	inc 1, ix
	ld_sriw3 WA, 0x07, 0xE4, 0xF0
	cpda16 xwa, 1118
	jr gt, AccKbdTiming_TableScan_Decrement
	ldb a, 0xF0
	andda8 a, 13185
	or a, 0x8
	calr AccSeq_WriteByte
	ldda8 a, 13186
	calr AccSeq_WriteByte
	ldb a, 0x0
	calr AccSeq_WriteByte
	and_srib_im 0x07, 0xE4, 0xF8, 0x7F
	jr AccKbdTiming_TableScan_NextSlot

AccKbdTiming_TableScan_Decrement:
	subda16 xwa, 1118
	bit 7, a
	jr z, AccKbdTiming_TableScan_StoreTiming
	add a, 0x60

AccKbdTiming_TableScan_StoreTiming:
	st_dri3w WA, 0x07, 0xE4, 0xF0
	cpda16 xwa, 13172
	jr nc, AccKbdTiming_TableScan_NextSlot
	stda16 13172, xwa

AccKbdTiming_TableScan_NextSlot:
	addda16 xiz, 13180
	jrl AccKbdTiming_TableScan_Loop

AccKbdTiming_TableScan_Done:
	ret

AccSeq_WriteByte:
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	pushw wa
	pushw wa
	call RhythmBuf_WriteByte
	inc 2, xsp
	popw wa
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	ret

AccAccTiming_ScanRingBuf:
	stdi8 14970, 255
	ld ix, (xhl + 6)

AccAccTiming_EventLoop:
	cp (xhl + 4), ix
	jrl z, AccAccTiming_ScanDone
	ld_srib3 A, 0x07, 0xEC, 0xF0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_ClassifyEvent
	ld ix, (xhl + 256)

AccAccTiming_ClassifyEvent:
	ld w, a
	cp a, 0x90
	jr nz, AccAccTiming_Check0x91
	stdi8 13184, 5
	jr AccAccTiming_StoreEventData

AccAccTiming_Check0x91:
	cp a, 0x91
	jr nz, AccAccTiming_Check0x92
	stdi8 13184, 7
	jr AccAccTiming_StoreEventData

AccAccTiming_Check0x92:
	cp a, 0x92
	jr nz, AccAccTiming_CheckProgramChg
	stdi8 13184, 6
	jr AccAccTiming_StoreEventData

AccAccTiming_CheckProgramChg:
	and a, 0xF0
	cp a, 0xC0
	jr nz, AccAccTiming_CheckControl
	stdi8 13184, 5
	jr AccAccTiming_StoreEventData

AccAccTiming_CheckControl:
	cp a, 0xD0
	jrl nz, AccAccTiming_SkipEvent
	stdi8 13184, 2

AccAccTiming_StoreEventData:
	stda8 14971, a
	ld_srib3 A, 0x07, 0xEC, 0xF0
	stda16 13178, xix
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_CheckTimestamp
	ld ix, (xhl + 256)

AccAccTiming_CheckTimestamp:
	cpda8 a, 1117
	jrl ugt, AccAccTiming_TimestampOverflow
	ld a, w
	and a, 0xF0
	cp a, 0x90
	jrl nz, AccAccTiming_WriteNonNote
	cpdi8 14970, 0
	jr nz, AccAccTiming_NoteSlotScan
	pushw wa
	ldda8 a, 13196
	stda8 14972, a
	popw wa
	calr AccKbdTiming_CatchupReplay
	stdi8 14970, 255

AccAccTiming_NoteSlotScan:
	pushw wa
	ld_srib3 W, 0x07, 0xEC, 0xF0
	xor iz, iz

AccAccTiming_NoteSlot_Loop:
	cpda16 xiz, 13182
	jr nc, AccAccTiming_NoteSlot_FindFree
	bit_dri 7, 0x07, 0xE4, 0xF8
	jr z, AccAccTiming_NoteSlot_NextSlot
	ldfr_werp IZ, 0xFA
	add iz, 0x2
	cp_srib_mr W, 0x07, 0xE4, 0xF8
	ldto_werp IZ, 0xFA
	jr z, AccAccTiming_NoteSlot_SendNoteOff

AccAccTiming_NoteSlot_NextSlot:
	addda16 xiz, 13180
	jr AccAccTiming_NoteSlot_Loop

AccAccTiming_NoteSlot_SendNoteOff:
	ld_srib3 A, 0x07, 0xE4, 0xF8
	and_srib_im 0x07, 0xE4, 0xF8, 0x7F
	and a, 0xF0
	orda8 a, 13196
	calr AccSeq_WriteByte
	ld a, w
	calr AccSeq_WriteByte
	ldb a, 0x0
	calr AccSeq_WriteByte
	bitda 0, 13197
	jr nz, AccAccTiming_NoteSlot_FindFree
	ordi8 13197, 1
	ldb a, 0x90
	calr AccSeq_WriteByte
	ldb a, 0x0
	calr AccSeq_WriteByte
	calr AccSeq_WriteByte

AccAccTiming_NoteSlot_FindFree:
	popw wa
	xor iz, iz

AccAccTiming_NoteSlot_FreeLoop:
	cpda16 xiz, 13182
	jr nc, AccAccTiming_SlotOverflow
	bit_dri 7, 0x07, 0xE4, 0xF8
	jr z, AccAccTiming_WriteNoteEvent
	addda16 xiz, 13180
	jr AccAccTiming_NoteSlot_FreeLoop

AccAccTiming_SlotOverflow:
	pushw wa
	xor xwa, xwa
	ldda8 a, 13188
	sla xwa, 2
	add xwa, 0xF5BD56
	ld iz, (xwa)
	ld_srib3 A, 0x07, 0xE4, 0xF8
	and_srib_im 0x07, 0xE4, 0xF8, 0x7F
	pushw iz
	inc 2, iz
	ld_srib3 W, 0x07, 0xE4, 0xF8
	and a, 0xF0
	orda8 a, 13196
	calr AccSeq_WriteByte
	ld a, w
	calr AccSeq_WriteByte
	ldb a, 0x0
	calr AccSeq_WriteByte
	popw iz
	popw wa
	incdi8 1, 13188
	cpdi8 13188, 8
	jr c, AccAccTiming_SlotOverflow_Done
	stdi8 13188, 0

AccAccTiming_SlotOverflow_Done:
	jr AccAccTiming_WriteNoteEvent

AccAccTiming_SkipEvent:
	ld ix, (xhl + 4)
	ld (xhl + 6), ix
	jrl AccAccTiming_EventLoop

AccAccTiming_WriteNoteEvent:
	orda8 a, 13196
	calr AccSeq_WriteByte
	ld a, w
	lda_dri3 XBC, 0x07, 0xE4, 0xF8
	inc 1, iz
	ldb a, 0x0
	lda_dri3 XBC, 0x07, 0xE4, 0xF8
	inc 1, iz
	ld_srib3 A, 0x07, 0xEC, 0xF0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNote_Byte2
	ld ix, (xhl + 256)

AccAccTiming_WriteNote_Byte2:
	calr AccSeq_WriteByte
	lda_dri3 XBC, 0x07, 0xE4, 0xF8
	inc 1, iz
	ld_srib3 A, 0x07, 0xEC, 0xF0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNote_Byte3
	ld ix, (xhl + 256)

AccAccTiming_WriteNote_Byte3:
	calr AccSeq_WriteByte
	lda_dri3 XBC, 0x07, 0xE4, 0xF8
	inc 1, iz
	pushw wa
	ld_srib3 A, 0x07, 0xEC, 0xF0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNote_ReadTimingLo
	ld ix, (xhl + 256)

AccAccTiming_WriteNote_ReadTimingLo:
	ld_srib3 W, 0x07, 0xEC, 0xF0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNote_ReadTimingHi
	ld ix, (xhl + 256)

AccAccTiming_WriteNote_ReadTimingHi:
	addda16 xwa, 1118
	cp a, 0x60
	jr c, AccAccTiming_WriteNote_StoreTiming
	inc 1, w
	sub a, 0x60

AccAccTiming_WriteNote_StoreTiming:
	st_dri3w WA, 0x07, 0xE4, 0xF8
	inc 2, iz
	cpda16 xwa, 13170
	jr nc, AccAccTiming_WriteNote_ExtraBytes
	stda16 13170, xwa

AccAccTiming_WriteNote_ExtraBytes:
	popw wa
	ld_srib3 A, 0x07, 0xEC, 0xF0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNote_StoreExtra1
	ld ix, (xhl + 256)

AccAccTiming_WriteNote_StoreExtra1:
	lda_dri3 XBC, 0x07, 0xE4, 0xF8
	inc 1, iz
	cp w, 0x90
	jr z, AccAccTiming_WriteNote_Done
	ld_srib3 A, 0x07, 0xEC, 0xF0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNote_StoreExtra2
	ld ix, (xhl + 256)

AccAccTiming_WriteNote_StoreExtra2:
	lda_dri3 XBC, 0x07, 0xE4, 0xF8
	inc 1, iz
	cp w, 0x92
	jr z, AccAccTiming_WriteNote_Done
	ld_srib3 A, 0x07, 0xEC, 0xF0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNote_StoreExtra3
	ld ix, (xhl + 256)

AccAccTiming_WriteNote_StoreExtra3:
	lda_dri3 XBC, 0x07, 0xE4, 0xF8
	inc 1, iz

AccAccTiming_WriteNote_Done:
	ld (xhl + 6), ix
	jrl AccAccTiming_EventLoop

AccAccTiming_WriteNonNote:
	ld w, a
	orda8 a, 13196
	calr AccSeq_WriteByte
	ld_srib3 A, 0x07, 0xEC, 0xF0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNonNote_Byte2
	ld ix, (xhl + 256)

AccAccTiming_WriteNonNote_Byte2:
	calr AccSeq_WriteByte
	stda8 13108, a
	ld_srib3 A, 0x07, 0xEC, 0xF0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNonNote_Byte3
	ld ix, (xhl + 256)

AccAccTiming_WriteNonNote_Byte3:
	calr AccSeq_WriteByte
	cp w, 0xD0
	jr nz, AccAccTiming_WriteNonNote_ExtBytes
	cpdi8 13108, 3
	jr nz, AccAccTiming_WriteNonNote_Done
	stda8 13107, a
	jr AccAccTiming_WriteNonNote_Done

AccAccTiming_WriteNonNote_ExtBytes:
	ld_srib3 A, 0x07, 0xEC, 0xF0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNonNote_Byte5
	ld ix, (xhl + 256)

AccAccTiming_WriteNonNote_Byte5:
	calr AccSeq_WriteByte
	ld_srib3 A, 0x07, 0xEC, 0xF0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNonNote_Byte6
	ld ix, (xhl + 256)

AccAccTiming_WriteNonNote_Byte6:
	calr AccSeq_WriteByte
	ld_srib3 A, 0x07, 0xEC, 0xF0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNonNote_Byte7
	ld ix, (xhl + 256)

AccAccTiming_WriteNonNote_Byte7:
	calr AccSeq_WriteByte

AccAccTiming_WriteNonNote_Done:
	ld (xhl + 6), ix
	jrl AccAccTiming_EventLoop

AccAccTiming_TimestampOverflow:
	cpdi8 14971, 192
	jr nz, AccAccTiming_Overflow_SubBase
	stdi8 14970, 0

AccAccTiming_Overflow_SubBase:
	subda8 a, 1117
	cpda8 a, 13175
	jr nc, AccAccTiming_Overflow_CalcSkip
	stda8 13175, a

AccAccTiming_Overflow_CalcSkip:
	ldda16 xix, 13178
	lda_dri3 XBC, 0x07, 0xEC, 0xF0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_Overflow_AdvancePos
	ld ix, (xhl + 256)

AccAccTiming_Overflow_AdvancePos:
	xor wa, wa
	ldda8 a, 13184
	add ix, wa
	cp ix, (xhl + 2)
	jrl ule, AccAccTiming_EventLoop
	sub ix, (xhl + 2)
	dec 1, ix
	add ix, (xhl + 256)
	jrl AccAccTiming_EventLoop

AccAccTiming_ScanDone:
	ret

AccAccTiming_TableScan:
	xor iz, iz

AccAccTiming_TableScan_Loop:
	cpda16 xiz, 13182
	jp_24 nc, 0xF5BD35
	bit_dri 7, 0x07, 0xE4, 0xF8
	jr z, AccAccTiming_TableScan_NextSlot
	ld ix, iz
	ld_srib3 A, 0x07, 0xE4, 0xF0
	stda8 13185, a
	inc 2, ix
	ld_srib3 A, 0x07, 0xE4, 0xF0
	stda8 13186, a
	inc 1, ix
	ld_srib3 A, 0x07, 0xE4, 0xF0
	stda8 13187, a
	inc 1, ix
	ld_sriw3 WA, 0x07, 0xE4, 0xF0
	cpda16 xwa, 1118
	jr gt, AccAccTiming_TableScan_Decrement
	ldb a, 0xF0
	andda8 a, 13185
	orda8 a, 13196
	calr AccSeq_WriteByte
	ldda8 a, 13186
	calr AccSeq_WriteByte
	ldb a, 0x0
	calr AccSeq_WriteByte
	and_srib_im 0x07, 0xE4, 0xF8, 0x7F
	jr AccAccTiming_TableScan_NextSlot

AccAccTiming_TableScan_Decrement:
	subda16 xwa, 1118
	bit 7, a
	jr z, AccAccTiming_TableScan_StoreTiming
	add a, 0x60

AccAccTiming_TableScan_StoreTiming:
	st_dri3w WA, 0x07, 0xE4, 0xF0
	cpda16 xwa, 13172
	jr nc, AccAccTiming_TableScan_NextSlot
	stda16 13172, xwa

AccAccTiming_TableScan_NextSlot:
	addda16 xiz, 13180
	jrl AccAccTiming_TableScan_Loop

AccAccTiming_TableScan_Done:
	ret

AccTiming_SlotOffsetTables:
	nop
	nop
	nop
	nop
	ei	0x00
	nop
	nop
	incf
	nop
	nop
	nop
	ccf
	nop
	nop
	nop
	.byte 0x18
	nop
	nop
	nop
	calr	0
	nop
	ldb	d, 0
	nop
	nop
	pushw	de
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	push 0
	nop
	nop
	ccf
	nop
	nop
	nop
	jp	0
	ldb	d, 0
	nop
	nop
	pushw	iy
	nop
	nop
	nop
	ldw	iz, 0
	nop
	push	xsp
	nop
	nop
	nop

AccDir_Entry:
	jp AccDir_Main

AccDir_PeriodicEntry:
	jp AccDir_PeriodicCheck

AccDir_Main:
	calr AccDir_ReadState
	cpdi8 13479, 0
	jr nz, AccDir_CheckLeftNote
	cpdi8 13480, 0
	jr z, AccDir_CheckLeftNote
	ordi8 13471, 1

AccDir_CheckLeftNote:
	cpdi8 13481, 0
	jr nz, AccDir_CheckRightHandState
	cpdi8 13482, 0
	jr z, AccDir_CheckRightHandState
	ordi8 13471, 8

AccDir_CheckRightHandState:
	ldda8 a, 13477
	bit 0, a
	jr nz, AccDir_Finalize
	bit 1, a
	jr z, AccDir_Finalize
	anddi8 13471, 246
	stdi8 13478, 0

AccDir_Finalize:
	calr AccDir_AdjustDirection
	calr AccDir_SavePrevState
	ret

AccDir_Padding1:
	.byte 0x00, 0x00

AccDir_ReadState:
	ldda8 a, 64602
	stda8 13476, a
	ldda8 a, 13074
	and a, 0x3F
	stda8 13479, a
	ldda8 a, 13075
	and a, 0x3F
	stda8 13481, a
	ldda8 a, 1045
	stda8 13472, a
	ldda8 a, 13477
	and a, 0xFE
	bitda 0, 12931
	jr z, AccDir_ReadState_StoreFlags
	or a, 0x1

AccDir_ReadState_StoreFlags:
	stda8 13477, a
	ldda8 a, 64921
	bit 0, a
	jr nz, AccDir_ReadState_Ret
	anddi8 13471, 246

AccDir_ReadState_Ret:
	ret

AccDir_Padding2:
	.byte 0x00, 0x00

AccDir_SavePrevState:
	ldda8 a, 13479
	stda8 13480, a
	ldda8 a, 13481
	stda8 13482, a
	ldda8 a, 13477
	and a, 0xFD
	bit 0, a
	jr z, AccDir_SavePrevState_StoreFlags
	or a, 0x2

AccDir_SavePrevState_StoreFlags:
	stda8 13477, a
	ret

AccDir_Padding3:
	.byte 0x00, 0x00

AccDir_AdjustDirection:
	ldda8 a, 13471
	and a, 0x9
	cps a, 0
	jp_24 z, 0xF5BEC9
	bitda 0, 13471
	jr z, AccDir_Adjust_LeftHand
	anddi8 13471, 254
	cpdi8 13476, 128
	jr nc, AccDir_Adjust_LeftHand
	ldda8 w, 64921
	and w, 0x1
	ldda8 a, 64609
	and a, 0x30
	srl a, 4
	cps w, 0
	jr z, AccDir_Adjust_LeftHand
	dec 1, a
	cp a, 0xFF
	jr nz, AccDir_Adjust_RightDec
	ldb a, 0x0

AccDir_Adjust_RightDec:
	sll a, 4
	anddi8 64609, 207
	orddm8 64609, a
	calr AccDir_DispatchEvent

AccDir_Adjust_LeftHand:
	bitda 3, 13471
	jr z, AccDir_Adjust_SetChanged
	anddi8 13471, 247
	cpdi8 13476, 128
	jr nc, AccDir_Adjust_SetChanged
	ldda8 w, 64921
	and w, 0x1
	ldda8 a, 64609
	and a, 0x30
	srl a, 4
	cps w, 0
	jr z, AccDir_Adjust_SetChanged
	inc 1, a
	cps a, 4
	jr c, AccDir_Adjust_LeftInc
	ldb a, 0x3

AccDir_Adjust_LeftInc:
	sll a, 4
	anddi8 64609, 207
	orddm8 64609, a
	calr AccDir_DispatchEvent

AccDir_Adjust_SetChanged:
	stdi8 13478, 1

AccDir_Adjust_Ret:
	ret

AccDir_Padding4:
	.byte 0x00, 0x00

AccDir_DispatchEvent:
	ldda8 w, 64921
	and w, 0x1
	cps w, 0
	jr z, AccDir_DispatchEvent_Ret
	cpdi8 13476, 128
	jr nc, AccDir_DispatchEvent_Ret
	ldb e, 0x48
	ldb d, 0x7
	ldda8 a, 64609
	ldb w, 0x30
	call SwbtWr_QueuePostEvent
	ldda8 a, 64921
	and a, 0x70
	cp a, 0x10
	jr z, AccDir_DispatchEvent_Ret
	ldda8 a, 64609
	and a, 0x30
	srl a, 4
	stda8 36180, a
	call EffectMode_ReinitWithFlag

AccDir_DispatchEvent_Ret:
	ret

AccDir_Padding5:
	.byte 0x00, 0x00

AccDir_PeriodicCheck:
	bitda 4, 12932
	jr z, AccDir_Periodic_Ret
	cpdi8 13478, 0
	jr z, AccDir_Periodic_CheckCountdown
	decdi8 1, 13478

AccDir_Periodic_CheckCountdown:
	cpdi8 13478, 0
	jr nz, AccDir_Periodic_Ret
	ldda8 a, 1045
	cp a, 0x5D
	jr nc, AccDir_Periodic_DisableAndReset
	cp a, 0x30
	jr ugt, AccDir_Periodic_Ret

AccDir_Periodic_DisableAndReset:
	anddi8 12932, 239
	anddi8 12932, 251
	call AudioMode_SetStereoFlags

AccDir_Periodic_Ret:
	ret

AccDir_JumpTable:
	nop
	nop
	call	16105294
	ret

AccProcess_Entry:
	call AccProcess_TimerCompare
	ret

AccProcess_InlinedCode:
	ldda8	a, 49277
	cp	a, 18
	.byte 0xf2, 0xe1, 0xbf, 0xf5, 0xde
	ldda8	a, 49278
	andda8	a, 49279
	and	a, 1
	cps	a, 1
	.byte 0xf2, 0xe1, 0xbf, 0xf5, 0xde, 0xf1, 0x90, 0x34, 0xc8
	jr	nz, 15
	ldda16	wa, 1033
	stda16	13454, wa
	.byte 0xc1, 0x90, 0x34, 0x3e, 0x01
	jr	96
	ldda16	wa, 1033
	ldda16	bc, 13454
	cp	wa, bc
	jr	c, 4
	sub	wa, bc
	jr	20
	and	xwa, 65535
	and	xbc, 65535
	add	xwa, 65536
	sub	xwa, xbc
	cp	wa, 750
	jr	c, 3
	ldw	wa, 750
	cp	wa, 100
	jr	ugt, 3
	ldw	wa, 100
	ld	bc, wa
	ld	xwa, 30000
	div	xwa, xbc
	pushw	wa
	calr	30
	popw	wa
	ldda16	hl, 13460
	stda16	13462, hl
	ldda16	hl, 13458
	stda16	13460, hl
	stda16	13458, wa
	ldda16	wa, 1033
	stda16	13454, wa
	ret
	ldda16	de, 13458
	ldda16	bc, 13460
	cps	de, 0
	jr	nz, 4
	jp	16105485
	cps	bc, 0
	jr	nz, 9
	add	wa, de
	srl	wa, 1
	jp	16105485
	add	wa, de
	add	wa, bc
	and	xwa, 65535
	div	wa, 3
	ldb	e, 72
	ldb	d, 8
	call	16626706
	ret

AccProcess_TimerCompare:
	bitda 0, 13456
	jr z, AccProcess_Timer_Ret
	ldda16 xwa, 1033
	ldda16 xbc, 13454
	cp wa, bc
	jr c, AccProcess_Timer_WrapCase
	sub wa, bc
	cp wa, 0x400
	jr c, AccProcess_Timer_Skip
	anddi8 13456, 254
	xor wa, wa
	stda16 13458, xwa
	stda16 13460, xwa
	stda16 13462, xwa

AccProcess_Timer_Skip:
	jr AccProcess_Timer_Ret

AccProcess_Timer_WrapCase:
	and xwa, 0xFFFF
	and xbc, 0xFFFF
	add xwa, 0x10000
	sub xwa, xbc
	cp wa, 0x400
	jr c, AccProcess_Timer_Ret
	anddi8 13456, 254
	xor wa, wa
	stda16 13458, xwa
	stda16 13460, xwa
	stda16 13462, xwa

AccProcess_Timer_Ret:
	ret

AccVoice_DispatchEntry:
	jp AccVoice_Dispatch

AccVoice_DispatchWithChannel:
	push xiz
	ld l, a
	ld h, c
	call AccVoice_Dispatch
	ld xhl, xiy
	pop xiz
	ret

AccVoice_GetChannelCount_Wrap:
	push xiz
	ld l, a
	call AccVoice_GetChannelCount
	pop xiz
	ret

AccVoice_GetChannelCount_Direct:
	call AccVoice_GetChannelCount
	ret

AccVoice_CopyFromROM_Wrap:
	push xiz
	ld l, a
	call AccVoice_CopyFromROM
	ld xhl, xiy
	pop xiz
	ret

AccVoice_Dispatch:
	push xwa
	push xbc
	push xde
	push xhl
	push xiy
	cp l, 0x10
	jr c, AccVoice_Dispatch_ClampH
	xor l, l

AccVoice_Dispatch_ClampH:
	cp h, 0x50
	jr c, AccVoice_Dispatch_CheckType
	xor h, h

AccVoice_Dispatch_CheckType:
	cp l, 0xF
	jr nz, AccVoice_Dispatch_Type0E
	calr AccVoice_ROMLookup
	jr AccVoice_Dispatch_Epilogue

AccVoice_Dispatch_Type0E:
	cp l, 0xE
	jr nz, AccVoice_Dispatch_TypeDefault
	calr AccVoice_IndexedTableLookup
	jr AccVoice_Dispatch_Epilogue

AccVoice_Dispatch_TypeDefault:
	calr AccVoice_ComputedCopy

AccVoice_Dispatch_Epilogue:
	pop xiy
	pop xhl
	pop xde
	pop xbc
	pop xwa
	ld xiy, 0x34AB
	ret

AccVoice_Dispatch_Padding:
	.byte 0x00, 0x00

AccVoice_ComputedCopy:
	ld a, l
	xor w, w
	muls wa, 0x14
	ld l, h
	xor h, h
	add wa, hl
	muls wa, 0xD
	add xwa, 0xE47147
	ld xiy, xwa
	ld xix, 0x34AB
	ldw bc, 0xD
	ldir85
	ret

AccVoice_ComputedCopy_Padding:
	.byte 0x00, 0x00

AccVoice_ROMLookup:
	ld l, h
	and hl, 0xF
	sla hl, 2
	ld xix, 0xF5C120
	ld xiy, 0x94800
	add_sril_rm XIY, 0x07, 0xF0, 0xEC
	ld xix, 0x34AB
	ldw bc, 0xD
	ldir85
	ret

AccVoice_ROMLookup_OffsetTable:
	nop
	nop
	.byte 0xa0, 0x00
	nop
	nop
	nop
	.byte 0x01


	naka_header NAKA_TYPE_0x00
	nop
	nop
	.byte 0xc0, 0x01, 0x00
	nop
	ldb	w, 2
	nop
	nop
	.byte 0x80, 0x02
	nop
	nop
	.byte 0xe0, 0x02, 0x00
	nop
	ld	xwa, 2684354563
	pop_sr
	nop
	nop
	nop
	.byte 0x04
	nop
	nop
	.byte 0x60, 0x04
	nop
	nop
	.byte 0xc0, 0x04, 0x00
	nop
	.byte 0xa0, 0x00
	nop
	nop
	.byte 0xa0, 0x00
	nop
	nop
	.byte 0xa0, 0x00
	nop
	nop
	.byte 0xa0, 0x00
	nop
	nop

AccVoice_IndexedTableLookup:
	ld l, h
	xor h, h
	sla hl, 2
	ld xix, 0xF5C188
	ld_sril3 XIY, 0x07, 0xF0, 0xEC
	ld xix, 0xF5C2D8
	add_sril_rm XIY, 0x07, 0xF0, 0xEC
	ld xix, 0x34AB
	ldw bc, 0xD
	ldir85
	ret

AccVoice_IndexedTableLookup_BaseOffsets:
	nop
	nop
	nop
	nop
	ldw	wa, 0
	nop
	ldw	wa, 0
	nop
	ldw	wa, 0
	nop
	ldw	wa, 0
	nop
	ldw	wa, 0
	nop
	ldw	wa, 0
	nop
	ldw	wa, 0
	nop
	ldw	wa, 0
	nop
	ldw	wa, 0
	nop
	ldw	wa, 0
	nop
	ldw	wa, 0
	nop
	ldw	wa, 0
	.byte 0x98, 0x31, 0x00
	nop
	.byte 0x98, 0x31, 0x00
	nop
	.byte 0x98, 0x31, 0x00
	nop
	.byte 0x98, 0x31, 0x00
	nop
	.byte 0x98, 0x31, 0x00
	nop
	.byte 0x98, 0x31, 0x00
	nop
	.byte 0x98, 0x31, 0x00
	nop
	.byte 0x98, 0x31, 0x00
	nop
	.byte 0x98, 0x31, 0x00
	nop
	.byte 0x98, 0x31, 0x00
	nop
	.byte 0x98, 0x31, 0x00
	nop
	.byte 0x98, 0x31, 0x00
	nop
	nop
	ldw	hl, 0
	nop
	ldw	hl, 0
	nop
	ldw	hl, 0
	nop
	ldw	hl, 0
	nop
	ldw	hl, 0
	nop
	ldw	hl, 0
	nop
	ldw	hl, 0
	nop
	ldw	hl, 0
	nop
	ldw	hl, 0
	nop
	ldw	hl, 0
	nop
	ldw	hl, 0
	nop
	ldw	hl, 0
	.byte 0x98, 0x34, 0x00
	nop
	.byte 0x98, 0x34, 0x00
	nop
	.byte 0x98, 0x34, 0x00
	nop
	.byte 0x98, 0x34, 0x00
	nop
	.byte 0x98, 0x34, 0x00
	nop
	.byte 0x98, 0x34, 0x00
	nop
	.byte 0x98, 0x34, 0x00
	nop
	.byte 0x98, 0x34, 0x00
	nop
	.byte 0x98, 0x34, 0x00
	nop
	.byte 0x98, 0x34, 0x00
	nop
	.byte 0x98, 0x34, 0x00
	nop
	.byte 0x98, 0x34, 0x00
	nop
	nop
	ldw	iz, 0
	nop
	ldw	iz, 0
	nop
	ldw	iz, 0
	nop
	ldw	iz, 0
	nop
	ldw	iz, 0
	nop
	ldw	iz, 0
	nop
	ldw	iz, 0
	nop
	ldw	iz, 0
	nop
	ldw	iz, 0
	nop
	ldw	iz, 0
	nop
	ldw	iz, 0
	nop
	ldw	iz, 0
	.byte 0x98, 0x37, 0x00
	nop
	.byte 0x98, 0x37, 0x00
	nop
	.byte 0x98, 0x37, 0x00
	nop
	.byte 0x98, 0x37, 0x00
	nop
	.byte 0x98, 0x37, 0x00
	nop
	.byte 0x98, 0x37, 0x00
	nop
	.byte 0x98, 0x37, 0x00
	nop
	.byte 0x98, 0x37, 0x00
	nop
	.byte 0x98, 0x37, 0x00
	nop
	.byte 0x98, 0x37, 0x00
	nop
	.byte 0x98, 0x37, 0x00
	nop
	.byte 0x98, 0x37, 0x00
	nop
	nop
	push	xbc
	nop
	nop
	nop
	push	xbc
	nop
	nop
	nop
	push	xbc
	nop
	nop
	nop
	push	xbc
	nop
	nop
	nop
	push	xbc
	nop
	nop
	nop
	push	xbc
	nop
	nop
	nop
	push	xbc
	nop
	nop
	nop
	push	xbc
	nop
	nop
	nop
	push	xbc
	nop
	nop
	nop
	push	xbc
	nop
	nop
	nop
	push	xbc
	nop
	nop
	nop
	push	xbc
	nop
	.byte 0xa0, 0x00
	nop
	nop
	nop
	.byte 0x01


	naka_header NAKA_TYPE_0x00
	nop
	nop
	.byte 0xc0, 0x01, 0x00
	nop
	ldb	w, 2
	nop
	nop
	.byte 0x80, 0x02
	nop
	nop
	.byte 0xe0, 0x02, 0x00
	nop
	ld	xwa, 2684354563
	pop_sr
	nop
	nop
	nop
	.byte 0x04
	nop
	nop
	.byte 0x60, 0x04
	nop
	nop
	.byte 0xc0, 0x04, 0x00
	nop
	.byte 0xa0, 0x00
	nop
	nop
	nop
	.byte 0x01


	naka_header NAKA_TYPE_0x00
	nop
	nop
	.byte 0xc0, 0x01, 0x00
	nop
	ldb	w, 2
	nop
	nop
	.byte 0x80, 0x02
	nop
	nop
	.byte 0xe0, 0x02, 0x00
	nop
	ld	xwa, 2684354563
	pop_sr
	nop
	nop
	nop
	.byte 0x04
	nop
	nop
	.byte 0x60, 0x04
	nop
	nop
	.byte 0xc0, 0x04, 0x00
	nop
	.byte 0xa0, 0x00
	nop
	nop
	nop
	.byte 0x01


	naka_header NAKA_TYPE_0x00
	nop
	nop
	.byte 0xc0, 0x01, 0x00
	nop
	ldb	w, 2
	nop
	nop
	.byte 0x80, 0x02
	nop
	nop
	.byte 0xe0, 0x02, 0x00
	nop
	ld	xwa, 2684354563
	pop_sr
	nop
	nop
	nop
	.byte 0x04
	nop
	nop
	.byte 0x60, 0x04
	nop
	nop
	.byte 0xc0, 0x04, 0x00
	nop
	.byte 0xa0, 0x00
	nop
	nop
	nop
	.byte 0x01


	naka_header NAKA_TYPE_0x00
	nop
	nop
	.byte 0xc0, 0x01, 0x00
	nop
	ldb	w, 2
	nop
	nop
	.byte 0x80, 0x02
	nop
	nop
	.byte 0xe0, 0x02, 0x00
	nop
	ld	xwa, 2684354563
	pop_sr
	nop
	nop
	nop
	.byte 0x04
	nop
	nop
	.byte 0x60, 0x04
	nop
	nop
	.byte 0xc0, 0x04, 0x00
	nop
	.byte 0xa0, 0x00
	nop
	nop
	nop
	.byte 0x01


	naka_header NAKA_TYPE_0x00
	nop
	nop
	.byte 0xc0, 0x01, 0x00
	nop
	ldb	w, 2
	nop
	nop
	.byte 0x80, 0x02
	nop
	nop
	.byte 0xe0, 0x02, 0x00
	nop
	ld	xwa, 2684354563
	pop_sr
	nop
	nop
	nop
	.byte 0x04
	nop
	nop
	.byte 0x60, 0x04
	nop
	nop
	.byte 0xc0, 0x04, 0x00
	nop
	.byte 0xa0, 0x00
	nop
	nop
	nop
	.byte 0x01


	naka_header NAKA_TYPE_0x00
	nop
	nop
	.byte 0xc0, 0x01, 0x00
	nop
	ldb	w, 2
	nop
	nop
	.byte 0x80, 0x02
	nop
	nop
	.byte 0xe0, 0x02, 0x00
	nop
	ld	xwa, 2684354563
	pop_sr
	nop
	nop
	nop
	.byte 0x04
	nop
	nop
	.byte 0x60, 0x04
	nop
	nop
	.byte 0xc0, 0x04, 0x00
	nop
	.byte 0xa0, 0x00
	nop
	nop
	nop
	.byte 0x01


	naka_header NAKA_TYPE_0x00
	nop
	nop
	.byte 0xc0, 0x01, 0x00
	nop
	ldb	w, 2
	nop
	nop
	.byte 0x80, 0x02
	nop
	nop
	.byte 0xe0, 0x02, 0x00
	nop
	ld	xwa, 2684354563
	pop_sr
	nop
	nop
	nop
	.byte 0x04
	nop
	nop
	.byte 0x60, 0x04
	nop
	nop
	.byte 0xc0, 0x04, 0x00
	nop
	sub	l, 140
	and	hl, 7
	sla	hl, 2
	ld	xix, 16106574
	ld	xiy, 608256
	.byte 0xe3, 0x07, 0xf0, 0xec, 0x85
	ld	xix, 13483
	ldw	bc, 13
	ldir85
	ret
	nop
	nop
	.byte 0xb0, 0x0b
	nop
	nop
	.byte 0xd0, 0x0b, 0x00
	nop
	.byte 0xf0, 0x0b, 0x00, 0x00
	rcf
	incf
	nop
	nop
	ldw	wa, 12
	nop
	.byte 0xb0, 0x0b
	nop
	nop
	.byte 0xb0, 0x0b
	nop
	nop
	.byte 0xb0, 0x0b
	nop
	nop

AccVoice_GetChannelCount:
	push xix
	cp l, 0x10
	jr c, AccVoice_GetChannelCount_Lookup
	xor l, l

AccVoice_GetChannelCount_Lookup:
	and hl, 0x1F
	ld xix, 0xF5C488
	ld_srib3 L, 0x07, 0xF0, 0xEC
	pop xix
	ret

AccVoice_ChannelCountTable:
	nop
	nop
	retd	0x100c
	push 18
	decf
	incf
	ret
	incf
	ccf
	pushw 3083
	decf
	zcf
	.byte 0x0b

AccVoice_CopyFromROM:
	push xwa
	push xbc
	push xhl
	push xiy
	cp l, 0x10
	jr c, AccVoice_CopyFromROM_Do
	xor l, l

AccVoice_CopyFromROM_Do:
	ld a, l
	xor w, w
	muls wa, 0x10
	add xwa, 0xE47047
	ld xiy, xwa
	ld xix, 0x34AB
	ldw bc, 0x10
	ldir85
	pop xiy
	pop xhl
	pop xbc
	pop xwa
	ld xiy, 0x34AB
	ret

AccVoice_CopyFromROM_DataBlock:
	nop
	nop
	pushw	hl
	calr	-1072
	popw	hl
	lds32	xix, 0
	ldw	bc, 8
	ldirw
	ld	xiy, 16106765
	jr	c, 5
	ld	xiy, 16106804
	ld	wa, (xiy)
	ld	c, (xiy+2)
	cp	wa, 65535
	jr	z, 28
	cp	wa, hl
	jr	z, 6
	add	iy, 3
	jr	-21
	cps	c, 0
	jr	nz, 8
	ldio	0, 0
	ldio	1, 1
	jr	6
	ldio	11, 0
	ldio	12, 1
	lds32	xiy, 0
	ret
	nop
	nop
	pop_sr
	push_sr
	nop
	.byte 0x04
	pop_sr
	nop
	.byte 0x04, 0x04
	nop
	halt
	.byte 0x02
	nop
	ei	0x04
	nop
	ei	0x06
	.byte 0x01
	pushw 3
	pushw 4
	decf
	.byte 0x02
	nop
	decf
	reti
	.byte 0x01
	ret
	.byte 0x01
	nop
	swi	7
	swi	7
	nop
	swi	7
	swi	7
	nop
	pop_sr
	push_sr
	nop
	.byte 0x04
	push_sr
	nop
	.byte 0x04
	ei	0x00
	halt
	.byte 0x02
	nop
	pushw 2
	pushw 261
	decf
	.byte 0x02
	nop
	ret
	reti
	nop
	ret
	push 1
	ret
	ldwio	1, 65535
	nop
	swi	7
	swi	7
	nop

AccStyle_Entry:
	jp AccStyle_Process
AccStyle_JumpTable:
	jp	16106967
	jp	16107087
	jp	16107164
	jp	16107226

AccStyle_InitVRAM_Wrap:
	push xiz
	call AccStyle_InitVRAM
	pop xiz
	ret

AccStyle_JumpTable2:
	jp	16107018
	jp	16108900
	jp	16108925
	jp	16108950
	jp	16108975
	jp	16109000
	ret
	nop
	nop
	nop
	ret
	nop
	nop
	nop
	ret
	nop
	nop
	nop
	ret
	nop
	nop
	nop
	ret
	nop
	nop
	nop

AccStyle_Process:
	ldda8 a, 13198
	and a, 0x1F
	jr z, AccStyle_Process_SaveState
	ldda8 a, 13199
	and a, 0x1F
	jr nz, AccStyle_Process_DoChain
	calr AccVoiceState_Snapshot

AccStyle_Process_DoChain:
	calr AccHelper_ComputeVoiceOffset
	ld xiy, xhl
	add xiy, 0x1E7810
	calr AccVoiceDelta_Part1
	calr AccVoiceDelta_Part2
	calr AccVoiceDelta_Part3
	calr AccVoiceDelta_Part4
	calr AccVoiceDelta_Part5

AccStyle_Process_SaveState:
	ldda8 a, 13198
	stda8 13199, a
	ret

AccStyle_ToggleBit0:
	; --- Routine 1: XOR toggle bit 0 at (0x3391), conditional calls (51 bytes) ---
	cpdi8	36148, 17
	jr nz, AccStyle_ToggleBit0_CheckC07D
	jr t, AccStyle_ToggleBit0_Ret
AccStyle_ToggleBit0_CheckC07D:
	cpdi8	49277, 6
	jr nz, AccStyle_ToggleBit0_Ret
	ldda8	a, 49278
	andda8	a, 49279
	bit 0, a
	jr z, AccStyle_ToggleBit0_Ret
	.byte 0xc1, 0x91, 0x33, 0x3d, 0x01		; xor (0x3391), 0x01  [C1 prefix]
	.byte 0xf1, 0x91, 0x33, 0xc8			; bit 0, (0x3391)  [F1 prefix]
	jr nz, AccStyle_ToggleBit0_CallOn
	call AccTuning_LEDOff
	jr t, AccStyle_ToggleBit0_Ret
AccStyle_ToggleBit0_CallOn:
	call AccTuning_LEDOn
AccStyle_ToggleBit0_Ret:
	ret
AccStyle_IndexedLookup:
	; --- Routine 2: indexed table lookup at 0xF5C8B4, store + DE/W setup (63 bytes) ---
	cpdi8	36148, 17
	jr nz, AccStyle_IndexedLookup_Ret
	cpdi8	49277, 16
	jr nz, AccStyle_IndexedLookup_Ret
	ldda8	a, 13198
	and a, 0x1f
	jr z, AccStyle_IndexedLookup_Ret
	ldda8	l, 13198
	and l, 0x1f
	extz hl
	ld xwa, 0x00F5C8B4
	.byte 0xc3, 0x07, 0xe0, 0xec, 0x21		; ld a, (xwa+hl)  [register-indexed]
	cpdm8	36154, a
	jr z, AccStyle_IndexedLookup_Ret
	stda8	36154, a
	ldb e, 0x90
	ldb d, 0x10
	ldb w, 0xff
	call SwbtWr_QueuePostEvent
AccStyle_IndexedLookup_Ret:
	ret


AccStyle_ModeEnter_Wrap:
	push xiz
	calr AccStyle_ModeEnter
	pop xiz
	ret

AccStyle_ModeEnter:
	cpdi8 36149, 17
	jr z, AccStyle_ModeEnter_Ret
	stdi8 13198, 0
	stdi8 13199, 0
	stdi8 13215, 0
	anddi8 13265, 254
	cpdi16 61854, 0
	jr z, AccStyle_ModeEnter_SetFlags
	call SeqAcc_SetIndicator_PB
	stdi16 61854, 0
	call Audio_CheckSubsystemReady
	ordi8 13265, 1

AccStyle_ModeEnter_SetFlags:
	ordi8 13517, 8
	ordi8 13267, 1
	ldb a, 0x4B
	call CtrlPanel_SetIndicatorBit

AccStyle_ModeEnter_Ret:
	ret

AccStyle_ModeExit_Wrap:
	push xiz
	calr AccStyle_ModeExit
	pop xiz
	ret

AccStyle_ModeExit:
	cpdi8 36148, 17
	jr z, AccStyle_ModeExit_Ret
	stdi8 13198, 0
	stdi8 13199, 0
	stdi8 13215, 0
	anddi8 13517, 247
	bitda 0, 13265
	jr z, AccStyle_ModeExit_ClearFlags
	anddi8 13265, 254
	call AccWrap_PlayModeDispatch
	call SeqAcc_RestorePlaybackState

AccStyle_ModeExit_ClearFlags:
	anddi8 13267, 252
	call PartSelect_UpdateDisplayState

AccStyle_ModeExit_Ret:
	ret

AccStyle_InlinedBlock:
	push	xiz
	calr	2
	pop	xiz
	ret
	cpdi8	36151, 220
	jrl	z, 354
	cpdi8	64602, 128
	jr	c, 23
	stdi8	13215, 1
	ldb	a, 8
	call	16694689
	stdi8	32578, 54
	call	16144626
	jrl	371
	stdi8	13198, 32
	call	16109025
	add	xhl, 1996816
	.byte 0x8b, 0x01, 0x3e, 0x80
	calr	799
	call	16095156
	.byte 0xc1, 0x46
	ldw	de, 0xc125
	ld	xsp, 339944498
	ldw	de, 0
	ld	(xhl), e
	ld	(xhl+1), d
	ldda8	e, 12877
	ldda8	d, 12878
	ldda8	a, 12879
	stda8	13359, a
	ldda8	a, 12880
	stda8	13360, a
	ldda8	a, 12881
	stda8	13361, a
	ldda8	a, 12882
	stda8	12995, a
	ldda8	a, 12883
	stda8	12999, a
	call	16073009
	ld	xhl, 12825
	call	16072982
	ldda8	e, 12884
	ldda8	d, 12885
	ldda8	a, 12886
	stda8	13359, a
	ldda8	a, 12887
	stda8	13360, a
	ldda8	a, 12888
	stda8	13361, a
	ldda8	a, 12889
	stda8	12995, a
	ldda8	a, 12890
	stda8	12999, a
	call	16073009
	ld	xhl, 12830
	call	16072982
	ldda8	e, 12891
	ldda8	d, 12892
	ldda8	a, 12893
	stda8	13359, a
	ldda8	a, 12894
	stda8	13360, a
	ldda8	a, 12895
	stda8	13361, a
	ldda8	a, 12896
	stda8	12995, a
	ldda8	a, 12897
	stda8	12999, a
	call	16073009
	ld	xhl, 12835
	call	16072982
	ldda8	e, 12898
	ldda8	d, 12899
	ldda8	a, 12900
	stda8	13359, a
	ldda8	a, 12901
	stda8	13360, a
	ldda8	a, 12902
	stda8	13361, a
	ldda8	a, 12903
	stda8	12995, a
	ldda8	a, 12904
	stda8	12999, a
	call	16073009
	ld	xhl, 12840
	call	16072982
	calr	481
	calr	402
	calr	171
	calr	244
	calr	317
	stdi8	13198, 1
	ldb	a, 20
	stda8	36154, a
	ldb	e, 144
	ldb	d, 16
	ldb	w, 255
	call	16626673
	cpdi8	13215, 1
	jr	nz, 10
	xor	wa, wa
	ldb	a, 1
	call	16356451
	jr	30
	ldda8	a, 13198
	and	a, 31
	jr	z, 16
	.byte 0xc1, 0xd3, 0x33, 0x3c, 0xfd, 0xc1, 0x91, 0x33, 0x3e, 0x01
	call	16095849
	jr	5
	.byte 0xc1, 0xd3, 0x33, 0x3e, 0x02
	ret
	nop
	nop
	.byte 0x01
	nop
	rcf
	nop
	nop
	nop
	ldio	0, 0
	nop
	nop
	nop
	nop
	nop
	.byte 0x04
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	.zero 8
	.byte 0x02
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	.zero 24
	nop
	.byte 0x14
	zcf
	nop
	rcf
	nop
	nop
	nop
	scf
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	ccf
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	.zero 8

AccVoiceReg_WritePart3:
	cpdi8 36148, 17
	jr nz, AccVoiceReg_WritePart3_Ret
	ldda8 a, 13198
	and a, 0x1F
	jr nz, AccVoiceReg_WritePart3_Ret
	ldda8 a, 12830
	ldda8 w, 12831
	bit 4, w
	jr z, AccVoiceReg_WritePart3_StoreBit4
	or a, 0x80
	and w, 0xEF

AccVoiceReg_WritePart3_StoreBit4:
	stda8 64342, a
	and w, 0x7F
	anddi8 64343, 128
	orddm8 64343, w
	ldda8 a, 12833
	sla a, 6
	and a, 0x40
	anddi8 64346, 191
	orddm8 64346, a
	ldb l, 0x4
	calr AccVoiceState_DispatchChange

AccVoiceReg_WritePart3_Ret:
	ret

AccVoiceReg_WritePart4:
	cpdi8 36148, 17
	jr nz, AccVoiceReg_WritePart4_Ret
	ldda8 a, 13198
	and a, 0x1F
	jr nz, AccVoiceReg_WritePart4_Ret
	ldda8 a, 12835
	ldda8 w, 12836
	bit 4, w
	jr z, AccVoiceReg_WritePart4_StoreBit4
	or a, 0x80
	and w, 0xEF

AccVoiceReg_WritePart4_StoreBit4:
	stda8 64368, a
	and w, 0x7F
	anddi8 64369, 128
	orddm8 64369, w
	ldda8 a, 12838
	sla a, 6
	and a, 0x40
	anddi8 64372, 191
	orddm8 64372, a
	ldb l, 0x8
	calr AccVoiceState_DispatchChange

AccVoiceReg_WritePart4_Ret:
	ret

AccVoiceReg_WritePart5:
	cpdi8 36148, 17
	jr nz, AccVoiceReg_WritePart5_Ret
	ldda8 a, 13198
	and a, 0x1F
	jr nz, AccVoiceReg_WritePart5_Ret
	ldda8 a, 12840
	ldda8 w, 12841
	bit 4, w
	jr z, AccVoiceReg_WritePart5_StoreBit4
	or a, 0x80
	and w, 0xEF

AccVoiceReg_WritePart5_StoreBit4:
	stda8 64394, a
	and w, 0x7F
	anddi8 64395, 128
	orddm8 64395, w
	ldda8 a, 12843
	sla a, 6
	and a, 0x40
	anddi8 64398, 191
	orddm8 64398, a
	ldb l, 0x10
	calr AccVoiceState_DispatchChange

AccVoiceReg_WritePart5_Ret:
	ret

AccVoiceReg_WritePart2:
	cpdi8 36148, 17
	jr nz, AccVoiceReg_WritePart2_Ret
	ldda8 a, 13198
	and a, 0x1F
	jr nz, AccVoiceReg_WritePart2_Ret
	ldda8 a, 12825
	ldda8 w, 12826
	bit 4, w
	jr z, AccVoiceReg_WritePart2_StoreBit4
	or a, 0x80
	and w, 0xEF

AccVoiceReg_WritePart2_StoreBit4:
	stda8 64420, a
	and w, 0x7F
	anddi8 64421, 128
	orddm8 64421, w
	ldda8 a, 12828
	sla a, 6
	and a, 0x40
	anddi8 64424, 191
	orddm8 64424, a
	ldb l, 0x2
	calr AccVoiceState_DispatchChange

AccVoiceReg_WritePart2_Ret:
	ret

AccVoiceReg_WritePart1:
	cpdi8 36148, 17
	jr nz, AccVoiceReg_WritePart1_Ret
	ldda8 a, 13198
	and a, 0x1F
	jr nz, AccVoiceReg_WritePart1_Ret
	ldda8 a, 12820
	or a, 0xF0
	ldda8 w, 12821
	and w, 0x7F
	stda8 64446, a
	anddi8 64447, 128
	orddm8 64447, w
	ldb l, 0x1
	calr AccVoiceState_DispatchChange

AccVoiceReg_WritePart1_Ret:
	ret

AccVoiceState_Snapshot:
	calr AccHelper_ComputeVoiceOffset
	ld xiy, xhl
	add xiy, 0x1E7810
	ldda8 a, 64446
	ldda8 w, 64447
	and w, 0x7F
	stda16 13205, xwa
	and a, 0xF
	ld (xiy + 256), a
	andmi8 (xiy + 1), 0x80
	or (xiy + 1), w
	ldda8 a, 64420
	ldda8 w, 64421
	and w, 0x7F
	ldda8 l, 64424
	and l, 0x40
	sla l, 1
	or w, l
	stda16 13207, xwa
	ld (xiy + 2), a
	andmi8 (xiy + 3), 0x0
	or (xiy + 3), w
	ldda8 a, 64342
	ldda8 w, 64343
	and w, 0x7F
	ldda8 l, 64346
	and l, 0x40
	sla l, 1
	or w, l
	stda16 13209, xwa
	ld (xiy + 4), a
	andmi8 (xiy + 5), 0x0
	or (xiy + 5), w
	ldda8 a, 64368
	ldda8 w, 64369
	and w, 0x7F
	ldda8 l, 64372
	and l, 0x40
	sla l, 1
	or w, l
	stda16 13211, xwa
	ld (xiy + 6), a
	andmi8 (xiy + 7), 0x0
	or (xiy + 7), w
	ldda8 a, 64394
	ldda8 w, 64395
	and w, 0x7F
	ldda8 l, 64398
	and l, 0x40
	sla l, 1
	or w, l
	stda16 13213, xwa
	ld (xiy + 8), a
	andmi8 (xiy + 9), 0x0
	or (xiy + 9), w
	ordi8 13203, 1
	ret

AccVoiceState_DispatchChange:
	push xiy
	ld xwa, 0xF5C8B4
	ld_srib3 E, 0x03, 0xE0, 0xEC
	extz hl
	sla hl, 2
	ld xwa, 0xF5CBE3
	ld_sril3 XWA, 0x07, 0xE0, 0xEC
	ld xiy, 0xF5CB63
	ld_sril3 XIY, 0x07, 0xF4, 0xEC
	stda8 37111, e
	ld l, (xiy + 256)
	and l, 0xFF
	ld h, (xiy + 1)
	and h, 0x7F
	pushw de
	push xwa
	push xiy
	call PartCtrl_WriteProgramChange
	pop xiy
	pop xwa
	popw de
	lda_dri3 XIZ, 0x03, 0xE0, 0xEC
	ld a, (xiy + 1)
	and a, 0x7F
	ldb w, 0x7F
	ldb d, 0x1
	pushw wa
	pushw de
	push xhl
	call SwbtWr_QueuePostEvent
	pop xhl
	popw de
	popw wa
	ld a, (xiy + 256)
	and a, 0xFF
	ldb w, 0xFF
	ldb d, 0x0
	pushw wa
	pushw de
	push xhl
	call SwbtWr_QueuePostEvent
	pop xhl
	popw de
	popw wa
	pop xiy
	ret

AccVoiceState_PartLookupTable:
	nop
	nop
	nop
	nop
	ld	(xiz-5), 0
	cp	(xix), xhl
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x56
	swi	3
	nop
	nop
	nop
	nop
	nop
	nop
	.zero 8
	jrl	f, 251
	nop
	nop
	nop
	nop
	nop
	.zero 24
	.byte 0x8a, 0xfb, 0x00
	nop
	nop
	nop
	nop
	nop
	.zero 56
	nop
	nop
	nop
	nop
	jr	gt, -1
	nop
	nop
	.byte 0x56
	swi	7
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x1a, 0xff, 0x00
	nop
	nop
	nop
	nop
	nop
	.zero 8
	pushw	iz
	swi	7
	nop
	nop
	nop
	nop
	nop
	nop
	.zero 24
	ld	xde, 255
	nop
	nop
	nop
	.zero 56

AccVoiceDelta_Part1:
	ldda8 a, 64446
	ldda8 w, 64447
	and w, 0x7F
	cpdm16 13205, xwa
	jr z, AccVoiceDelta_Part1_Store
	and a, 0xF
	ld (xiy + 256), a
	andmi8 (xiy + 1), 0x80
	or (xiy + 1), w
	or a, 0xF0
	ordi8 13203, 1

AccVoiceDelta_Part1_Store:
	stda16 13205, xwa
	ret

AccVoiceDelta_Part2:
	ldda8 a, 64420
	ldda8 w, 64421
	and w, 0x7F
	ldda8 l, 64424
	and l, 0x40
	sla l, 1
	or w, l
	cpdm16 13207, xwa
	jr z, AccVoiceDelta_Part2_Store
	ld (xiy + 2), a
	andmi8 (xiy + 3), 0x0
	or (xiy + 3), w
	ordi8 13203, 1

AccVoiceDelta_Part2_Store:
	stda16 13207, xwa
	ret

AccVoiceDelta_Part3:
	ldda8 a, 64342
	ldda8 w, 64343
	and w, 0x7F
	ldda8 l, 64346
	and l, 0x40
	sla l, 1
	or w, l
	cpdm16 13209, xwa
	jr z, AccVoiceDelta_Part3_Store
	ld (xiy + 4), a
	andmi8 (xiy + 5), 0x0
	or (xiy + 5), w
	ordi8 13203, 1

AccVoiceDelta_Part3_Store:
	stda16 13209, xwa
	ret

AccVoiceDelta_Part4:
	ldda8 a, 64368
	ldda8 w, 64369
	and w, 0x7F
	ldda8 l, 64372
	and l, 0x40
	sla l, 1
	or w, l
	cpdm16 13211, xwa
	jr z, AccVoiceDelta_Part4_Store
	ld (xiy + 6), a
	andmi8 (xiy + 7), 0x0
	or (xiy + 7), w
	ordi8 13203, 1

AccVoiceDelta_Part4_Store:
	stda16 13211, xwa
	ret

AccVoiceDelta_Part5:
	ldda8 a, 64394
	ldda8 w, 64395
	and w, 0x7F
	ldda8 l, 64398
	and l, 0x40
	sla l, 1
	or w, l
	cpdm16 13213, xwa
	jr z, AccVoiceDelta_Part5_Store
	ld (xiy + 8), a
	andmi8 (xiy + 9), 0x0
	or (xiy + 9), w
	ordi8 13203, 1

AccVoiceDelta_Part5_Store:
	stda16 13213, xwa
	ret

AccStyle_InitVRAM:
	xor a, a
	ld xiy, 0xE47F7F
	ld xix, 0x1E7800
	ldw bc, 0x7E0
	ldir85
	ret

AccStyle_SC0ByteSelect:
	.long LABEL_E3E0F1
	rcf
	ldda8	a, 13198
	and	a, 31
	jr	nz, 5
	stdi8	58334, 16
	stdi8	13198, 1
	ret
	stdi8	58336, 16
	ldda8	a, 13198
	and	a, 31
	jr	nz, 5
	stdi8	58334, 16
	stdi8	13198, 16
	ret
	stdi8	58336, 16
	ldda8	a, 13198
	and	a, 31
	jr	nz, 5
	.long LABEL_E3DEF1
	rcf
	stdi8	13198, 8
	ret
	stdi8	58336, 16
	ldda8	a, 13198
	and	a, 31
	jr	nz, 5
	stdi8	58334, 16
	stdi8	13198, 4
	ret
	stdi8	58336, 16
	ldda8	a, 13198
	and	a, 31
	jr	nz, 5
	stdi8	58334, 16
	stdi8	13198, 2
	ret

AccHelper_ComputeVoiceOffset:
	xor xwa, xwa
	ldda8 l, 64602
	ldda8 h, 64603
	and h, 0x7
	stdi8 37111, 72
	call PartCtrl_WriteProgramChange
	xor xwa, xwa
	xor xwa, xwa
	ld a, h
	ld h, l
	xor l, l

AccHelper_VoiceOffset_Loop:
	cp h, l
	jr z, AccHelper_VoiceOffset_Done
	pushw hl
	push xwa
	call AccVoice_GetChannelCount_Direct
	pop xwa
	inc 1, l
	add a, l
	popw hl
	inc 1, l
	jr AccHelper_VoiceOffset_Loop

AccHelper_VoiceOffset_Done:
	ld xhl, xwa
	sla xwa, 3
	sla xhl, 1
	add xhl, xwa
	ret

AccDemo_Init_Wrap:
	calr AccDemo_Init
	ret

AccDemo_Init:
	xor xbc, xbc
	calr AccDemo_LoadRhythm
	calr AccDemo_LoadVariation
	calr AccDemo_LoadFillIn
	calr AccDemo_LoadVariationData
	calr Demo_LoadVariationC_Data
	stdi16 13524, 190
	anddi8 13043, 254
	bitda 7, 13521
	jr nz, AccDemo_Init_ConfigTimers
	call AccWidget_DispatchTable

AccDemo_Init_ConfigTimers:
	anddi8 13521, 127
	stdi8 14774, 0
	stdi8 14775, 10
	ret

AccDemo_Init_DataBlock:
	nop
	nop
	ld	xix, 608256
	ld	(xix+2976), 0
	ld	(xix+2977), 1
	ld	(xix+2978), 2
	ld	(xix+2979), 3
	.byte 0x0e

AccDemo_LoadRhythm:
	ld xiy, 0xF5CFCC
	ld xix, 0x94800
	add xix, 0x0
	ldw bc, 0x60
	ldir85
	ret

AccDemo_LoadVariation:
	ldb a, 0x0
	ld xix, 0x94800
	add xix, 0x60
	lds hl, 0

AccDemo_LoadVariation_EntryLoop:
	ld (xix), hl
	inc 2, xix
	ldw (xix), 0x0
	inc 2, xix
	inc 1, hl
	ld (xix), hl
	inc 2, xix
	inc 1, hl
	ld (xix), hl
	inc 2, xix
	inc 1, hl
	ld (xix), hl
	inc 2, xix
	inc 1, hl
	ld (xix), hl
	inc 1, hl
	inc 2, xix
	ld xiy, 0xF5D20C
	ldw bc, 0x34
	ldir85
	ld xiy, 0xF5D02C
	xor xde, xde
	ld e, a
	mul e, 0x10
	add xiy, xde
	ldw bc, 0x10
	ldir85
	ld xiy, 0xF5D548
	ldw bc, 0x10
	ldir85
	add a, 0x1
	cp a, 0x1E
	jr lt, AccDemo_LoadVariation_EntryLoop
	ret

AccDemo_LoadVariation_DataBlock:
	ld	xiy, 16110144
	ld	xix, 608256
	add	xix, 2976
	ldw	bc, 160
	ldir85
	ret
	lds32	xwa, 0
	ld	xix, 608256
	add	xix, 3136
	lds32	xde, 0
	ld	qde, 6
	ld	de, wa
	ld	(xix), xde
	add	xix, 4
	ld	(xix), xde
	add	xix, 4
	ld	(xix), xde
	add	xix, 4
	ld	(xix), xde
	add	xix, 4
	ld	(xix), xde
	add	xix, 4
	ld	(xix), xde
	add	xix, 4
	ld	(xix), xde
	add	xix, 4
	ld	(xix), xde
	add	xix, 4
	add	wa, 1
	cp	wa, 60
	jr	lt, -79
	ret

AccDemo_LoadFillIn:
	ldw bc, 0x40
	ld xix, 0x94800
	add xix, 0x13C0
	ld xiy, 0xF5D300
	ldir85
	ret

AccDemo_LoadVariationData:
	ld xix, 0x94800
	add xix, 0x1400
	ldb a, 0x1E

Demo_LoadVariationData:
	ld xiy, 0xF5D340
	ldw bc, 0x100
	ldir85
	ldb l, 0x4

Demo_LoadVariationData_Inner:
	ld xiy, 0xF5D440
	ldw bc, 0x100
	ldir85
	dec 1, l
	cps l, 0
	jr gt, Demo_LoadVariationData_Inner
	dec 1, a
	cps a, 0
	jr nz, Demo_LoadVariationData
	ret

Demo_LoadVariationC_Data:
	ld xix, 0x94800
	add xix, 0xAA00
	ldb a, 0xBE

Demo_LoadVariationC_Loop:
	ld xiy, 0xF5D540
	ldw bc, 0x100
	ldir85
	dec 1, a
	cps a, 0
	jr nz, Demo_LoadVariationC_Loop
	ret

Demo_StyleRhythmData:
	popw	wa
	nop
	popw	hl
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	pop	xde
	pop	xde
	pop	xde
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x01, 0x01, 0x01, 0x01
	push_sr
	push_sr
	push_sr
	push_sr
	nop
	cpd
	jr	f, 0
	jr	f, 0
	calr	0
	.byte 0x01, 0x54, 0x01
	ld	xwa, 2147483648
	.byte 0x16
	.zero 48
	.ascii "a-variation1    a-variation2    a-variation3    a-variation4    b-variation1    b-variation2    b-variation3    b-variation4    c-variation1    c-variation2    c-variation3    c-variation4     a-intro 1       a-intro 2       a-fill in 1     a-fill in 2     a-ending 1      a-ending 2      b-intro 1       b-intro 2       b-fill in 1     b-fill in 2     b-ending 1      b-ending 2      c-intro 1       c-intro 2       c-fill in 1     c-fill in 2     c-ending 1      c-ending 2     "
	.byte 0x07, 0x03, 0x20, 0x00, 0x58, 0x02, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0x00
	.byte 0x50, 0x00, 0x7f, 0x00, 0x28, 0x00, 0x40, 0x00
	.byte 0x50, 0x06, 0x7f, 0x00, 0x00, 0x00, 0x40, 0x00
	.byte 0x50, 0x06, 0x7f, 0x00, 0x1c, 0x00, 0x40, 0x00
	.byte 0x50, 0x06, 0x7f, 0x00, 0x1d, 0x00, 0x40, 0x00
	.byte 0x50, 0x06, 0x7f, 0x00, 0x00, 0xff, 0xff, 0xff
	.zero 12
	.ascii "chord map 1     "
	.byte 0x01, 0xff, 0xff, 0xff
	.zero 12
	.ascii "chord map 2     "
	.byte 0x02, 0xff, 0xff, 0xff
	.zero 12
	.ascii "chord map 3     "
	.byte 0x03, 0xff, 0xff, 0xff
	.zero 12
	.ascii "chord map 4     "
	.byte 0x04, 0xff, 0xff, 0xff
	.zero 12
	.asciz "chord map 5     "
	.byte 0x00, 0x06, 0x00
	.byte 0x00, 0x00, 0x06, 0x00, 0x00, 0x00, 0x06, 0x00
	.byte 0x00, 0x00, 0x06, 0x00, 0x00, 0x00, 0x06, 0x00
	.byte 0x00, 0x00, 0x06, 0x00, 0x00, 0x00, 0x06, 0x00
	.byte 0x00, 0x00, 0x06, 0x00, 0x80, 0xff, 0xff, 0xff
	.byte 0xff, 0x87, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81
	.byte 0x81, 0x81, 0x83, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 40
	.byte 0x00, 0x00, 0x00, 0x87, 0x80, 0xff, 0xff, 0xff
	.byte 0xff, 0x87, 0x90, 0x00, 0x43, 0x58, 0x03, 0x00
	.byte 0x81, 0x90, 0x00, 0x43, 0x40, 0x03, 0x00, 0x81
	.byte 0x90, 0x00, 0x43, 0x40, 0x03, 0x00, 0x81, 0x90
	.byte 0x00, 0x43, 0x40, 0x03, 0x00, 0x81, 0x90, 0x00
	.byte 0x43, 0x58, 0x03, 0x00, 0x81, 0x90, 0x00, 0x43
	.byte 0x40, 0x03, 0x00, 0x81, 0x90, 0x00, 0x43, 0x40
	.byte 0x03, 0x00, 0x81, 0x90, 0x00, 0x43, 0x40, 0x03
	.byte 0x00, 0x81, 0x90, 0x00, 0x43, 0x58, 0x03, 0x00
	.byte 0x81, 0x90, 0x00, 0x43, 0x40, 0x03, 0x00, 0x81
	.byte 0x90, 0x00, 0x43, 0x40, 0x03, 0x00, 0x81, 0x90
	.byte 0x00, 0x43, 0x40, 0x03, 0x00, 0x81, 0x90, 0x00
	.byte 0x43, 0x58, 0x03, 0x00, 0x81, 0x90, 0x00, 0x43
	.byte 0x40, 0x03, 0x00, 0x81, 0x90, 0x00, 0x43, 0x40
	.byte 0x03, 0x00, 0x81, 0x90, 0x00, 0x43, 0x40, 0x03
	.byte 0x00, 0x81, 0x83, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 128
	nop
	nop
	nop
	add	w, (xsp)
	swi	7
	swi	7
	swi	7
	swi	7
	add	a, (xsp)
	add	a, (xbc)
	add	a, (xbc)
	.byte 0x81
	.fill 8, 1, 0x81
	add	a, (xbc)
	.byte 0x83, 0x00
	nop
	nop
	nop
	nop
	.zero 224
	nop
	nop
	nop
	.byte 0x87, 0x00
	swi	7
	swi	7
	swi	7
	swi	7
	.byte 0x87, 0x00
	nop
	nop
	nop
	nop
	nop
	.zero 240
	nop
	nop
	nop
	.byte 0x87

AccTone_LookupByProgram:
	sub a, 0xF0
	extz wa
	sla wa, 2
	lda_24 xbc, 0xe49fb4
	ld_sril3 XDE, 0x07, 0xE4, 0xE0
	ld a, (xde)
	extz wa
	sla wa, 2
	lda_24 xbc, 0xe46312
	ld xde, 0x94860
	add_sril_rm XDE, 0x07, 0xE4, 0xE0
	ld a, (xde + 12)
	extz wa
	lda_24 xbc, 0xe46b8a
	ld_srib3 L, 0x07, 0xE4, 0xE0
	ret

AccTone_ReadAndProcess:
	dec 4, xsp
	ldada xbc, 64602
	ld e, (xbc)
	and e, 0xFF
	lda xwa, (xsp + 2)
	ld (xwa), e
	ld e, (xbc + 1)
	res 7, e
	ld (xwa + 1), e
	call AccTone_ValidateAndClamp
	lda xwa, (xsp)
	lda xbc, (xsp + 2)
	call AccTone_WriteProgramChange
	lda xwa, (xsp + 2)
	cp (xwa), 0x80
	jr nc, AccTone_Process_Under80
	lda xbc, (xsp)
	ld a, (xbc)
	extz wa
	ld c, (xbc + 1)
	extz bc
	calr AccTone_NoteLookup
	jr AccTone_Process_Cleanup

AccTone_Process_Under80:
	cp (xwa), 0xF0
	jr nc, AccTone_Process_UnderF0
	ld e, (xwa)
	res 7, e
	ld c, (xwa + 1)
	extz de
	extz bc
	ld wa, de
	jr AccTone_Process_CalcResult

AccTone_Process_UnderF0:
	ld a, (xwa)
	sub a, 0xF0
	extz wa
	sla wa, 2
	lda_24 xbc, 0xe49fb4
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld e, (xwa)
	extz de
	ld wa, de
	lds bc, 0

AccTone_Process_CalcResult:
	calr AccTone_ExtendAndDispatch

AccTone_Process_Cleanup:
	inc 4, xsp
	ret

AccTone_NoteLookup:
	ldfr_berp A, 0xF4
	extz iy
	ldda16 xde, 4360
	ld ix, de
	and ix, 0x4
	lda_24 xhl, 0xe46d17
	ld a, c
	add a, c
	mul iy, 0x28
	ld c, a
	extz bc
	ld wa, iy
	add wa, bc
	cps ix, 4
	jr z, AccTone_NoteLookup_ReadTable
	ld bc, de
	and bc, 0x400
	cp bc, 0x400
	jr nz, AccTone_NoteLookup_CheckBit3
	inc 1, wa

AccTone_NoteLookup_ReadTable:
	extz xwa
	add xhl, xwa
	ld l, (xhl)
	jr AccTone_NoteLookup_Ret

AccTone_NoteLookup_CheckBit3:
	and de, 0x8
	ldb l, 0x0
	cp de, 0x8
	ret nz
	ldb l, 0x1

AccTone_NoteLookup_Ret:
	ret

AccTone_ExtendAndDispatch:
	extz bc
	extz wa
	jr __jrt_nop_F5D740
__jrt_nop_F5D740:

AccTone_ExtendAndDispatch_Body:
	push xiz
	extz bc
	sla bc, 2
	lda_24 xde, 0xe49f94
	ld_sril3 XIY, 0x07, 0xE8, 0xE4
	ld e, a
	extz de
	ld wa, de
	sla wa, 2
	lda_24 xix, 0xe46312
	ld xiz, xiy
	add_sril_rm XIZ, 0x07, 0xF0, 0xE0
	ld a, (xiz + 12)
	extz wa
	lda_24 xhl, 0xe46b8a
	ld_srib3 A, 0x07, 0xEC, 0xE0
	ldfr_berp A, 0xE2
	lda_24 xiz, 0xe49f74
	ld_sril3 XBC, 0x07, 0xF8, 0xE4
	add de, 0x11
	ld_srib3 C, 0x07, 0xE4, 0xE8
	ldda16 xwa, 4360
	ld de, wa
	and de, 0x4
	extz bc
	cps de, 4
	jr nz, AccTone_CheckBit10Flag
	lda_24 xde, 0xe4a03c
	ld_srib3 A, 0x07, 0xE8, 0xE4
	extz wa
	sla wa, 2
	ld xiz, xiy
	add_sril_rm XIZ, 0x07, 0xF0, 0xE0
	ld c, (xiz + 12)
	extz bc
	ldto_berp A, 0xE2
	cp_srib_rm A, 0x07, 0xEC, 0xE4
	jr z, AccTone_FoundMatch_IncRet

AccTone_SetupExit:
	ldb l, 0x0

AccTone_ExtendAndDispatch_PopRet:
	pop xiz
	ret

AccTone_CheckBit10Flag:
	ld de, wa
	and de, 0x400
	cp de, 0x400
	jr nz, AccTone_CheckBit3Flag
	lda_24 xde, 0xe4a040
	ld_srib3 A, 0x07, 0xE8, 0xE4
	extz wa
	sla wa, 2
	ld xiz, xiy
	add_sril_rm XIZ, 0x07, 0xF0, 0xE0
	ld c, (xiz + 12)
	extz bc
	ldto_berp A, 0xE2
	cp_srib_rm A, 0x07, 0xEC, 0xE4
	jr nz, AccTone_SetupExit

AccTone_FoundMatch_IncRet:
	ld l, (xiz + 13)
	inc 1, l
	jr AccTone_ExtendAndDispatch_PopRet

AccTone_CheckBit3Flag:
	and wa, 0x8
	cp wa, 0x8
	jr nz, AccTone_SetupExit
	ldto_berp A, 0xE2
	extz wa
	lda_24 xbc, 0xe46bb0
	bit_dri 0, 0x07, 0xE4, 0xE0
	jr nz, AccTone_SetupExit
	ldb l, 0x1
	jr AccTone_ExtendAndDispatch_PopRet
	dec 4, xsp
	ldda16 xde, 4360
	and de, 0x40C
	jrl z, AccTone_LookupFailed
	extz bc
	sla bc, 2
	lda_24 xde, 0xe49f94
	ld_sril3 XDE, 0x07, 0xE8, 0xE4
	extz wa
	sla wa, 2
	lda_24 xbc, 0xe46312
	add_sril_rm XDE, 0x07, 0xE4, 0xE0
	ld a, (xde + 12)
	extz wa
	lda_24 xbc, 0xe46b8a
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	lda_24 xbc, 0xe46bb0
	bit_dri 0, 0x07, 0xE4, 0xE0
	jr nz, AccTone_LookupFailed
	lda xwa, (xsp)
	ld c, (xde + 16)
	ld (xwa), c
	ld e, (xde + 17)
	ld (xwa + 1), e
	ld l, (xwa)
	extz hl
	extz de
	sll de, 8
	ld bc, de
	or bc, hl
	cp bc, 0x208
	jr z, AccTone_CheckDirectAddr
	ld c, (xwa)
	extz bc
	or de, bc
	cp de, 0x318
	jr nz, AccTone_ValidateAndWrite

AccTone_CheckDirectAddr:
	ldda8 a, 13055
	cps a, 1
	jr z, AccTone_DirectAddr_Mode1
	cps a, 2
	jr z, AccTone_DirectAddr_Mode2

AccTone_DirectAddr_Mode1:
	ldb l, 0x2
	jr AccTone_LookupDone

AccTone_DirectAddr_Mode2:
	ldb l, 0x1
	jr AccTone_LookupDone

AccTone_ValidateAndWrite:
	call AccTone_ValidateAndClamp
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	call AccTone_WriteProgramChange
	lda xbc, (xsp + 2)
	ld a, (xbc)
	extz wa
	ld c, (xbc + 1)
	extz bc
	calr AccTone_NoteLookup
	jr AccTone_LookupDone

AccTone_LookupFailed:
	ldb l, 0x0

AccTone_LookupDone:
	inc 4, xsp
	ret

AccTone_InlineBytecodeData:
	.byte 0xf1, 0x1f, 0x34, 0xb0
	cpdi8	13079, 0
	scc16	z, bc
	cpdi8	13078, 0
	scc16	z, de
	and	de, bc
	cpdi8	13080, 0
	scc16	z, bc
	and	bc, de
	cpdi8	13074, 0
	scc16	z, de
	and	de, bc
	cpdi8	13075, 0
	scc16	z, bc
	and	bc, de
	cpdi8	13076, 0
	scc16	z, de
	and	de, bc
	cpdi8	13077, 0
	scc16	z, wa
	and	wa, de
	ret	z
	cpdi8	13029, 240
	ret	c
	ldda8	a, 12928
	cpda8	a, 13349
	jr	z, 4
	.byte 0xf1, 0x1e, 0x34, 0xb0, 0xf1, 0x1e, 0x34, 0xc8
	ret	nz
	calr	31
	ldda8	a, 13345
	cpda8	a, 13354
	jr	z, 8
	.byte 0xf1, 0x1f, 0x34, 0xb8, 0xf1, 0x1e, 0x34, 0xb8, 0xc1, 0x2a, 0x34, 0x19, 0x21, 0x34, 0xc1, 0x2b, 0x34, 0x19, 0x20, 0x34
	ret
	ldda8	a, 13016
	extz	wa
	lda_24	xbc, 14983112
	.byte 0xc3, 0x07, 0xe4, 0xe0, 0x21
	stda8	13355, a
	ldda32	xbc, 13006
	extz	wa
	.byte 0xc3, 0x07, 0xe4, 0xe0, 0x21
	stda8	13354, a
	cp	a, 255
	ret	nz
	.byte 0x81, 0x19, 0x2a, 0x34
	stdi8	13355, 0
	ret
	.byte 0xf1, 0x1f, 0x34, 0xc8
	ret	z
	call	16115629
	call	16115636
	ldda8	a, 13345
	extz	wa
	sla	wa, 2
	lda_24	xde, 14967570
	ld	xbc, 608352
	.byte 0xe3, 0x07, 0xe8, 0xe0, 0x81
	stda32	13350, xbc
	ld	xwa, xbc
	call	16115497
	.byte 0xc1, 0x2c, 0x33, 0x3e, 0x3f, 0xf1, 0x2c, 0x33, 0xbf
	calr	23
	.byte 0xc1, 0xd8, 0x32, 0x19, 0xdf, 0x32, 0xc1, 0xd9, 0x32, 0x19, 0xe0, 0x32, 0xc1, 0xda, 0x32, 0x19, 0xe1, 0x32, 0xf1, 0x1f, 0x34, 0xb0
	ret
	calr	1327
	.byte 0xc1, 0xab, 0x32, 0x3c, 0xf0, 0xc1, 0xac, 0x32, 0x3c, 0xf0, 0xc1, 0xad, 0x32, 0x3c, 0xf0, 0xc1, 0xae, 0x32, 0x3c, 0xf0, 0xc1, 0xaf, 0x32, 0x3c, 0xf0, 0xc1, 0xb0, 0x32, 0x3c, 0xf0
	call	16115643
	.byte 0xf1, 0xf4, 0x32, 0xce
	ret	nz
	call	16115650
	ret
	extz	de
	sla	de, 2
	extz	bc
	sla	bc, 5
	ld	hl, bc
	add	hl, de
	ldb	w, 0
	extz	xwa
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 5
	add	xbc, 611392
	.byte 0xd3, 0x07, 0xe4, 0xec, 0x23
	ret
	extz	de
	sla	de, 2
	extz	bc
	sla	bc, 5
	ld	hl, bc
	add	hl, de
	ldb	w, 0
	extz	xwa
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 5
	add	xbc, 611392
	.byte 0xf3, 0x07, 0xe4, 0xec, 0x30
	ld	hl, (xwa+2)
	ret
	dec	2, xsp
	push	xiz
	ldda8	a, 13029
	sub	a, 240
	extz	wa
	sla	wa, 2
	lda_24	xbc, 14983092
	.byte 0xe3, 0x07, 0xe4, 0xe0, 0x20
	stda32	13006, xwa
	ld	a, (xwa)
	stda8	13297, a
	extz	wa
	lda_24	xbc, 14969849
	.byte 0xc3, 0x07, 0xe4, 0xe0, 0x19, 0x38, 0x33
	ld	bc, wa
	sla	bc, 2
	.byte 0xf2, 0x12
	jr	ule, 0xe4
	ldw	de, 24640
	popw	wa
	push 0
	.byte 0xe3, 0x07, 0xe8, 0xe4, 0x80
	stda32	13298, xwa
	ld	xiz, xwa
	lda	xwa, (xsp+4)
	ld	c, (xiz+16)
	ld	(xwa), c
	ld	e, (xiz+17)
	ld	(xwa+1), e
	ld	l, (xwa)
	extz	hl
	extz	de
	sll	de, 8
	ld	bc, de
	or	bc, hl
	cp	bc, 520
	jr	z, 15
	ld	c, (xwa)
	extz	bc
	or	de, bc
	cp	de, 792
	.byte 0xf2, 0xeb, 0xe6, 0xf5, 0xee
	lda	xbc, (xsp+4)
	ld	a, (xbc)
	extz	wa
	ld	c, (xbc+1)
	extz	bc
	call	16115456
	ld	xwa, xhl
	call	16115479
	ld	a, (xiz+12)
	extz	wa
	lda_24	xbc, 14969738
	.byte 0xc3, 0x07, 0xe4, 0xe0, 0x19, 0x33, 0x04
	ldda8	a, 1075
	extz	wa
	add	wa, wa
	lda_24	xbc, 14969758
	.byte 0xd3, 0x07, 0xe4, 0xe0, 0x19, 0x7b, 0x32
	ldda8	a, 13297
	add	a, 128
	stda8	13356, a
	extz	wa
	call	16115488
	calr	-466
	ldda8	a, 13354
	stda8	13345, a
	.byte 0xc1, 0x2b, 0x34, 0x19, 0x20, 0x34
	ldda8	a, 13354
	extz	wa
	sla	wa, 2
	lda_24	xde, 14967570
	ld	xbc, 608352
	.byte 0xe3, 0x07, 0xe8, 0xe0, 0x81
	stda32	13350, xbc
	ld	xwa, xbc
	call	16115497
	.byte 0xc1, 0x2c, 0x33, 0x3e, 0x3f
	pop	xiz
	inc	2, xsp
	ret
	cpdi8	13029, 240
	ret	c
	calr	-533
	ldda8	a, 13354
	cpda8	a, 13345
	ret	z
	.byte 0xf1, 0x3b, 0x33, 0xb8
	ret
	dec	2, xsp
	push	xiz
	ldda8	a, 13029
	sub	a, 240
	extz	wa
	sla	wa, 2
	lda_24	xbc, 14983092
	.byte 0xe3, 0x07, 0xe4, 0xe0, 0x20
	stda32	13006, xwa
	ld	a, (xwa)
	stda8	13297, a
	extz	wa
	lda_24	xbc, 14969849
	.byte 0xc3, 0x07, 0xe4, 0xe0, 0x19, 0x38, 0x33
	ld	bc, wa
	sla	bc, 2
	lda_24	xde, 14967570
	ld	xwa, 608352
	.byte 0xe3, 0x07, 0xe8, 0xe4, 0x80
	stda32	13298, xwa
	ld	xiz, xwa
	lda	xwa, (xsp+4)
	ld	c, (xiz+16)
	ld	(xwa), c
	ld	e, (xiz+17)
	ld	(xwa+1), e
	ld	l, (xwa)
	extz	hl
	extz	de
	sll	de, 8
	ld	bc, de
	or	bc, hl
	cp	bc, 520
	jr	z, 15
	ld	c, (xwa)
	extz	bc
	or	de, bc
	cp	de, 792
	.byte 0xf2, 0xeb, 0xe6, 0xf5, 0xee
	lda	xbc, (xsp+4)
	ld	a, (xbc)
	extz	wa
	ld	c, (xbc+1)
	extz	bc
	call	16115456
	ld	xwa, xhl
	call	16115479
	ld	a, (xiz+12)
	extz	wa
	lda_24	xbc, 14969738
	.byte 0xc3, 0x07, 0xe4, 0xe0, 0x19, 0x33, 0x04
	ldda8	a, 1075
	extz	wa
	add	wa, wa
	lda_24	xbc, 14969758
	.byte 0xd3, 0x07, 0xe4, 0xe0, 0x19, 0x7b, 0x32
	ldda8	a, 13297
	add	a, 128
	stda8	13356, a
	extz	wa
	call	16115488
	calr	-750
	.byte 0xc1, 0x2a, 0x34, 0x19, 0x21, 0x34, 0xc1, 0x2b, 0x34, 0x19, 0x20, 0x34, 0xf1, 0x63, 0x33, 0xc8, 0xf2, 0x68, 0xe7, 0xf5, 0xe6
	ldda8	c, 13345
	extz	bc
	sla	bc, 2
	lda_24	xde, 14967570
	ld	xwa, 608352
	.byte 0xe3, 0x07, 0xe8, 0xe4, 0x80
	stda32	13350, xwa
	calr	4
	pop	xiz
	inc	2, xsp
	ret
	ldda8	c, 13055
	ld	a, c
	and	a, 7
	jr	z, 40
	.byte 0xf1, 0x63, 0x33, 0xc8
	jr	z, 36
	cps	c, 1
	jr	z, 49
	cps	c, 4
	jr	z, 30
	cps	c, 2
	jr	nz, 41
	ldda8	a, 1075
	extz	wa
	lda_24	xbc, 14969776
	.byte 0xc3, 0x07, 0xe4, 0xe0, 0x3f, 0x01
	jr	nz, 5
	calr	252
	.ascii "h$hG"
	.byte 0xc1, 0x33, 0x04
	.byte 0x21, 0xc1, 0x66, 0x33, 0xf1, 0x66, 0x0f, 0x1e
	.byte 0x19, 0x01, 0x68, 0xed, 0xc1, 0x33, 0x04, 0x21
	.byte 0xc1, 0x64, 0x33, 0xf1, 0x6e, 0x04, 0x1b, 0x00
	.byte 0xe9, 0xf5, 0x1e, 0xef, 0x00, 0x68, 0xda, 0xe1
	.byte 0x26, 0x34, 0x20, 0x1d, 0x56, 0xe7, 0xf5, 0xe1
	.byte 0x26, 0x34, 0x20, 0x1d, 0x29, 0xe7, 0xf5, 0xc1
	.byte 0x2c, 0x33, 0x3e, 0x3f
	.byte 0xc1, 0x16, 0x33, 0x3c
	.byte 0xc0, 0xc1, 0x17, 0x33, 0x3c, 0xc0, 0xc1, 0x18
	.byte 0x33, 0x3c, 0xc0, 0x0e, 0xef, 0x6a, 0x2e, 0xc1
	.byte 0xff, 0x32, 0x21, 0xc9, 0xdc, 0x66, 0x09, 0xc9
	.byte 0xda, 0x6e, 0x0a, 0x36, 0x22, 0x00, 0x68, 0x08
	.byte 0x36, 0x20, 0x04, 0x68, 0x03, 0x36, 0x20, 0x00
	.byte 0xe1, 0xf2, 0x33, 0x22, 0xbf, 0x02, 0x30, 0x8a
	.byte 0x10, 0x23, 0xb0, 0x43, 0x8a, 0x11, 0x25, 0xb8
	.byte 0x01, 0x45, 0x80, 0x27, 0xdb, 0x12, 0xda, 0x12
	.byte 0xda, 0xee, 0x08, 0xda, 0x89, 0xdb, 0xe1, 0xd9
	.byte 0xcf, 0x08, 0x02, 0x66, 0x0f, 0x80, 0x23, 0xd9
	.byte 0x12, 0xd9, 0xe2, 0xda, 0xcf, 0x18, 0x03, 0xf2
	.byte 0xeb, 0xe6, 0xf5, 0xee, 0xbf, 0x02, 0x31, 0x81
	.byte 0x21, 0xd8, 0x12, 0x89, 0x01, 0x23, 0xd9, 0x12
	.byte 0x1d, 0x00, 0xe7, 0xf5, 0xeb, 0x88, 0xde, 0x89
	.byte 0x1d, 0x6f, 0xe7, 0xf5, 0xe1, 0xf2, 0x33, 0x20
	.byte 0x1d, 0x29, 0xe7, 0xf5, 0xc1, 0x2c, 0x33, 0x3e
	.byte 0x3f, 0xc1, 0xff, 0x32, 0x21, 0xc9, 0xdc, 0x66
	.byte 0x10, 0xc9, 0xda, 0x6e, 0x1d, 0xc1, 0x16, 0x33
	.byte 0x3c, 0xc0, 0xc1, 0x17
	.ascii "3>?h"
	.byte 0x1b, 0xc1, 0x16, 0x33, 0x3c, 0xc0, 0xc1, 0x17
	.byte 0x33, 0x3c, 0xc0, 0xc1, 0x18, 0x33, 0x3e, 0x3f
	.byte 0x68, 0x0f, 0xc1, 0x16, 0x33, 0x3e, 0x3f, 0xc1
	.byte 0x17, 0x33, 0x3c, 0xc0, 0xc1, 0x18, 0x33, 0x3c
	.byte 0xc0, 0x4e, 0xef, 0x62, 0x0e, 0xf1, 0xff, 0x32
	.byte 0xb1, 0xf1, 0x5f, 0xfc, 0xb3, 0x0b, 0x00, 0x00
	.byte 0x30, 0x48, 0x00, 0xd9, 0xad, 0xda, 0xa8, 0x1d
	.byte 0x24, 0xb2, 0xfd, 0x0e, 0xf1, 0xff, 0x32, 0xb0
	.byte 0xf1, 0x5f, 0xfc, 0xb2, 0x0b, 0x00, 0x00, 0x30
	.byte 0x48, 0x00, 0xd9, 0xad, 0xda, 0xa8, 0x1d, 0x24
	.byte 0xb2, 0xfd, 0x0e, 0xf1, 0xff, 0x32, 0xb2, 0xf1
	.byte 0x60, 0xfc, 0xb2, 0x0b, 0x00, 0x00, 0x30, 0x48
	.byte 0x00, 0xd9, 0xae, 0xda, 0xa8, 0x1d, 0x24, 0xb2
	.byte 0xfd, 0x0e, 0xf1, 0xfd, 0x32, 0xb0, 0xf1, 0x5f
	.byte 0xfc, 0xb4, 0x0b, 0x00, 0x00, 0x30, 0x48, 0x00
	.byte 0xd9, 0xad, 0xda, 0xa8, 0x1d, 0x24, 0xb2, 0xfd
	.byte 0x0e, 0xf1, 0xfd, 0x32, 0xb1, 0xf1, 0x5f, 0xfc
	.byte 0xb5, 0x0b, 0x00, 0x00, 0x30, 0x48, 0x00, 0xd9
	.byte 0xad, 0xda, 0xa8, 0x1d, 0x24, 0xb2, 0xfd, 0x0e
	.byte 0xf1, 0xfb, 0x32, 0xb0, 0xf1, 0x5f, 0xfc, 0xb6
	.byte 0x0b, 0x00, 0x00, 0x30, 0x48, 0x00, 0xd9, 0xad
	.byte 0xda, 0xa8, 0x1d, 0x24, 0xb2, 0xfd, 0x0e, 0xf1
	.byte 0xfb, 0x32, 0xb1, 0xf1, 0x5f, 0xfc, 0xb7, 0x0b
	.byte 0x00, 0x00, 0x30, 0x48, 0x00, 0xd9, 0xad, 0xda
	.byte 0xa8, 0x1d, 0x24, 0xb2, 0xfd, 0x0e, 0xc9, 0xda
	.byte 0x6e, 0x08, 0xf1, 0xd6, 0x33, 0x02, 0xfe, 0xff
	.byte 0x68, 0x1b, 0xd8, 0x12, 0xf2, 0xf8, 0x9f, 0xe4
	.byte 0x31, 0xc3, 0x07, 0xe4, 0xe0, 0x21, 0xe1, 0x26
	.byte 0x34, 0x21, 0xd8, 0x12, 0xd8, 0x80, 0xd3, 0x07
	.byte 0xe4, 0xe0, 0x19, 0xd6, 0x33, 0xf1, 0xd8, 0x33
	.byte 0x02, 0x06, 0x00, 0x0e, 0xe1, 0x26, 0x34, 0x24
	.byte 0xc9, 0x8b, 0xd9, 0x12, 0xf2, 0x1a, 0xa0, 0xe4
	.byte 0x32, 0xc3, 0x07, 0xe8, 0xe4, 0x25, 0xda, 0x12
	.byte 0xda, 0x89, 0xd9, 0x09, 0x07, 0x00, 0xf1, 0x46
	.byte 0x32, 0x33, 0xf3, 0x07, 0xec, 0xe4, 0x33, 0xda
	.byte 0xec, 0x03, 0xda, 0xc8, 0x18, 0x00, 0xea, 0x13
	.byte 0xec, 0x82, 0x82, 0x23, 0xb3, 0x43, 0x8a, 0x01
	.byte 0x23, 0xbb, 0x01, 0x43, 0x8a, 0x02, 0x23, 0xbb
	.byte 0x02, 0x43, 0x8a, 0x03, 0x23, 0xbb, 0x03, 0x43
	.byte 0x8a, 0x04, 0x23, 0xbb, 0x04, 0x43, 0x8a, 0x05
	.byte 0x23, 0xbb, 0x05, 0x43, 0x8a, 0x06, 0x23, 0xbb
	.byte 0x06, 0x43, 0xc1, 0x2c, 0x33, 0xe9, 0x0e

AccVoice_ClearChannelStates:
	stdi8 13291, 0
	stdi8 13292, 0
	stdi8 13293, 0
	stdi8 13294, 0
	stdi8 13295, 0
	stdi8 13296, 0
	ret

AccVoice_IncrementBarCounter:
	ldda8 a, 13290
	inc 1, a
	stda8 13290, a
	ldda32 xbc, 13350
	cp a, (xbc + 13)
	ret ule
	stdi8 13290, 0
	ret

AccVoice_BarCounterBytecodeData:
	stdi8	13280, 0
	ldda8	a, 13345
	extz	wa
	ldda8	e, 13291
	extz	de
	lds	bc, 0
	calr	-1304
	stda16	12951, hl
	cp	hl, 65534
	jr	nz, 4
	.byte 0xf1, 0xe0, 0x33, 0xb8
	ldda8	a, 13345
	extz	wa
	ldda8	e, 13291
	extz	de
	lds	bc, 0
	calr	-1295
	stda16	12935, hl
	ldda8	a, 13345
	extz	wa
	ldda8	e, 13293
	extz	de
	lds	bc, 1
	calr	-1356
	stda16	12955, hl
	cp	hl, 65534
	jr	nz, 4
	.byte 0xf1, 0xe0, 0x33, 0xba
	ldda8	a, 13345
	extz	wa
	ldda8	e, 13293
	extz	de
	lds	bc, 1
	calr	-1347
	stda16	12939, hl
	ldda8	a, 13345
	extz	wa
	ldda8	e, 13294
	extz	de
	lds	bc, 2
	calr	-1408
	stda16	12957, hl
	cp	hl, 65534
	jr	nz, 4
	.byte 0xf1, 0xe0, 0x33, 0xbb
	ldda8	a, 13345
	extz	wa
	ldda8	e, 13294
	extz	de
	lds	bc, 2
	calr	-1399
	stda16	12941, hl
	ldda8	a, 13345
	extz	wa
	ldda8	e, 13295
	extz	de
	lds	bc, 3
	calr	-1460
	stda16	12959, hl
	cp	hl, 65534
	jr	nz, 4
	.byte 0xf1, 0xe0, 0x33, 0xbc
	ldda8	a, 13345
	extz	wa
	ldda8	e, 13295
	extz	de
	lds	bc, 3
	calr	-1451
	stda16	12943, hl
	ldda8	a, 13345
	extz	wa
	ldda8	e, 13296
	extz	de
	lds	bc, 4
	calr	-1512
	stda16	12961, hl
	cp	hl, 65534
	jr	nz, 4
	.byte 0xf1, 0xe0, 0x33, 0xbd
	ldda8	a, 13345
	extz	wa
	ldda8	e, 13296
	extz	de
	lds	bc, 4
	calr	-1503
	stda16	12945, hl
	stdi16	12953, 65534
	stdi16	12937, 6
	.byte 0xf1, 0xe0, 0x33, 0xb9
	ret
	dec	2, xsp
	push	xiz
	lda_24	xbc, 14967570
	.byte 0xf1, 0x63, 0x33, 0xc8
	jr	z, 126
	ldda8	a, 13067
	cps	a, 1
	jr	z, 62
	cps	a, 2
	jr	nz, 58
	ldda8	a, 1075
	cpda8	a, 13166
	jr	nz, 30
	ldda8	a, 13167
	extz	wa
	sla	wa, 2
	ld	xiz, 608352
	.byte 0xe3, 0x07, 0xe4, 0xe0, 0x86
	ld	xwa, xiz
	call	16115551
	ld	xwa, xiz
	jrl	172
	calr	-613
	ldda32	xwa, 13350
	call	16115551
	.byte 0xe1
	.ascii "&4 x"
	.byte 0x9a, 0x00, 0xc1, 0x33
	.byte 0x04, 0x21, 0xc1, 0x6c, 0x33, 0xf1, 0x6e, 0x1d
	.byte 0xc1, 0x6d, 0x33, 0x21, 0xd8, 0x12, 0xd8, 0xec
	.byte 0x02, 0x46, 0x60, 0x48, 0x09, 0x00, 0xe3, 0x07
	.byte 0xe4, 0xe0, 0x86, 0xee, 0x88, 0x1d, 0x5f, 0xe7
	.byte 0xf5, 0xee, 0x88, 0x68, 0x73, 0x1e, 0x4b, 0xfd
	.byte 0xe1, 0x26, 0x34, 0x20, 0x1d, 0x5f, 0xe7, 0xf5
	.byte 0xe1
	.ascii "&4 hbáò"
	.byte 0x33, 0x22, 0xbf, 0x04, 0x30, 0x8a, 0x10, 0x23
	.byte 0xb0, 0x43, 0x8a, 0x11, 0x25, 0xb8, 0x01, 0x45
	.byte 0x80, 0x27, 0xdb, 0x12, 0xda, 0x12, 0xda, 0xee
	.byte 0x08, 0xda, 0x89, 0xdb, 0xe1, 0xd9, 0xcf, 0x08
	.byte 0x02, 0x66, 0x0f, 0x80, 0x23, 0xd9, 0x12, 0xd9
	.byte 0xe2, 0xda, 0xcf, 0x18, 0x03, 0xf2, 0xeb, 0xe6
	.byte 0xf5, 0xee, 0xbf, 0x04, 0x31, 0x81, 0x21, 0xd8
	.byte 0x12, 0x89, 0x01, 0x23, 0xd9, 0x12, 0x1d, 0x00
	.byte 0xe7, 0xf5, 0xeb, 0x88, 0xc1, 0x0b, 0x33, 0x23
	.byte 0xcb, 0xd9, 0x66, 0x09, 0xcb, 0xda, 0x6e, 0x05
	.byte 0x31, 0x24, 0x04, 0x68, 0x03, 0x31, 0x24, 0x00
	.byte 0x1d, 0x80, 0xe7, 0xf5, 0xe1, 0xf2, 0x33, 0x20
	.byte 0x1d, 0x29, 0xe7, 0xf5, 0xc1, 0x2c, 0x33, 0x3e
	.byte 0x3f, 0x5e, 0xef, 0x62, 0x0e, 0xef, 0x6a, 0x3e
	.byte 0xf2, 0x12, 0x63, 0xe4, 0x31, 0xf1, 0x63, 0x33
	.byte 0xc8, 0x66, 0x7e, 0xc1, 0x09, 0x33, 0x21, 0xc9
	.byte 0xd9, 0x66, 0x3e, 0xc9, 0xda, 0x6e, 0x3a, 0xc1
	.byte 0x33, 0x04, 0x21, 0xc1, 0x6a, 0x33, 0xf1, 0x6e
	.byte 0x1e, 0xc1, 0x6b, 0x33, 0x21, 0xd8, 0x12, 0xd8
	.byte 0xec, 0x02, 0x46, 0x60, 0x48, 0x09, 0x00, 0xe3
	.byte 0x07, 0xe4, 0xe0, 0x86, 0xee, 0x88, 0x1d, 0x5f
	.byte 0xe7, 0xf5, 0xee, 0x88, 0x78, 0xa6, 0x00, 0x1e
	.byte 0xce, 0xfc, 0xe1, 0x26, 0x34, 0x20, 0x1d, 0x5f
	.byte 0xe7, 0xf5, 0xe1
	.ascii "&4 x”"
	.byte 0x00, 0xc1, 0x33, 0x04, 0x21, 0xc1, 0x68, 0x33
	.byte 0xf1, 0x6e, 0x1d, 0xc1, 0x69, 0x33, 0x21, 0xd8
	.byte 0x12, 0xd8, 0xec, 0x02, 0x46, 0x60, 0x48, 0x09
	.byte 0x00, 0xe3, 0x07, 0xe4, 0xe0, 0x86, 0xee, 0x88
	.byte 0x1d, 0x5f, 0xe7, 0xf5, 0xee, 0x88, 0x68, 0x6d
	.byte 0x1e, 0x7e, 0xfc, 0xe1, 0x26, 0x34, 0x20, 0x1d
	.byte 0x5f, 0xe7, 0xf5, 0xe1
	.ascii "&4 h\\"
	.byte 0xe1, 0xf2, 0x33, 0x22, 0xbf, 0x04, 0x30
	.byte 0x8a, 0x10, 0x23, 0xb0, 0x43, 0x8a, 0x11, 0x25
	.byte 0xb8, 0x01, 0x45, 0x80, 0x27, 0xdb, 0x12, 0xda
	.byte 0x12, 0xda, 0xee, 0x08, 0xda, 0x89, 0xdb, 0xe1
	.byte 0xd9, 0xcf, 0x08, 0x02, 0x66, 0x0f, 0x80, 0x23
	.byte 0xd9, 0x12, 0xd9, 0xe2, 0xda, 0xcf, 0x18, 0x03
	.byte 0xf2, 0xeb, 0xe6, 0xf5, 0xee, 0xbf, 0x04, 0x31
	.byte 0x81, 0x21, 0xd8, 0x12, 0x89, 0x01, 0x23, 0xd9
	.byte 0x12, 0x1d, 0x00, 0xe7, 0xf5, 0xeb, 0x8e, 0xc1
	.byte 0xa3, 0x32, 0x21, 0xd8, 0x12, 0x1d, 0x43, 0xe7
	.byte 0xf5, 0xdb, 0x89, 0xee, 0x88, 0x1d, 0x80, 0xe7
	.byte 0xf5, 0xe1, 0xf2, 0x33, 0x20, 0x1d, 0x29, 0xe7
	.byte 0xf5, 0xc1
	.byte 0x2c, 0x33, 0x3e, 0x3f, 0x5e
	.byte 0xef
	.byte 0x62, 0x0e, 0xef, 0x6a, 0x3e, 0xe1, 0xf2, 0x33
	.byte 0x20, 0xf2, 0x12, 0x63, 0xe4, 0x35, 0xb8, 0x11
	.byte 0x34, 0x88, 0x10, 0x25, 0xbf, 0x04, 0x33, 0xbb
	.byte 0x01, 0x31, 0xf1, 0x63, 0x33, 0xc8, 0x76, 0xfd
	.byte 0x00, 0xc1, 0x0a, 0x33, 0x21, 0xc9, 0xd9, 0x76
	.byte 0xbc, 0x00, 0xc9, 0xdc, 0x66, 0x40, 0xc9, 0xcf
	.byte 0x08, 0x7e, 0xb2, 0x00, 0xc1, 0x33, 0x04, 0x21
	.byte 0xc1, 0x66, 0x33, 0xf1, 0x6e, 0x1e, 0xc1, 0x67
	.byte 0x33, 0x21, 0xd8, 0x12, 0xd8, 0xec, 0x02, 0x46
	.byte 0x60, 0x48, 0x09, 0x00, 0xe3, 0x07, 0xf4, 0xe0
	.byte 0x86, 0xee, 0x88, 0x1d, 0x5f, 0xe7, 0xf5, 0xee
	.byte 0x88, 0x78, 0x26, 0x01, 0x1e, 0x65, 0xfb, 0xe1
	.byte 0x26, 0x34, 0x20, 0x1d, 0x5f, 0xe7, 0xf5, 0xe1
	.ascii "&4 x"
	.byte 0x14, 0x01, 0xc1, 0x33
	.byte 0x04, 0x21, 0xd8, 0x12, 0xf2, 0xb0, 0x6b, 0xe4
	.byte 0x35, 0xc3, 0x07, 0xf4, 0xe0, 0x3f, 0x01, 0x6e
	.byte 0x12, 0x1e, 0x12, 0xfb, 0xe1, 0x26, 0x34, 0x20
	.byte 0x1d, 0x5f, 0xe7, 0xf5, 0xe1, 0x26, 0x34, 0x20
	.byte 0x78, 0xef, 0x00, 0xeb, 0x88, 0xb3, 0x45, 0x84
	.byte 0x25, 0xb1, 0x45, 0x83, 0x27, 0xdb, 0x12, 0xda
	.byte 0x12, 0xda, 0xee, 0x08, 0xda, 0x89, 0xdb, 0xe1
	.byte 0xd9, 0xcf, 0x08, 0x02, 0x66, 0x0f, 0x80, 0x23
	.byte 0xd9, 0x12, 0xd9, 0xe2, 0xda, 0xcf, 0x18, 0x03
	.byte 0xf2, 0xeb, 0xe6, 0xf5, 0xee, 0xbf, 0x04, 0x31
	.byte 0x81, 0x21, 0xd8, 0x12, 0x89, 0x01, 0x23, 0xd9
	.byte 0x12, 0x1d, 0x00, 0xe7, 0xf5, 0xeb, 0x8e, 0xee
	.byte 0x88, 0x31, 0x22, 0x00, 0x1d, 0x80, 0xe7, 0xf5
	.byte 0xee, 0x88, 0x41, 0x26, 0x01, 0x00, 0x00, 0x1d
	.byte 0x32, 0xe7, 0xf5, 0x78, 0xa0, 0x00, 0xc1, 0x33
	.byte 0x04, 0x21, 0xc1, 0x64, 0x33, 0xf1, 0x6e, 0x1d
	.byte 0xc1, 0x65, 0x33, 0x21, 0xd8, 0x12, 0xd8, 0xec
	.byte 0x02, 0x46, 0x60, 0x48, 0x09, 0x00, 0xe3, 0x07
	.byte 0xf4, 0xe0, 0x86, 0xee, 0x88, 0x1d, 0x5f, 0xe7
	.byte 0xf5, 0xee, 0x88, 0x68, 0x75, 0x1e, 0x9d, 0xfa
	.byte 0xe1, 0x26, 0x34, 0x20, 0x1d, 0x5f, 0xe7, 0xf5
	.byte 0xe1
	.ascii "&4 hd"
	ld	xwa, xhl
	ld	(xhl), e
	ld	e, (xix)
	ld	(xbc), e
	ld	l, (xhl)
	extz	hl
	extz	de
	sll	de, 8
	ld	bc, de
	or	bc, hl
	cp	bc, 520
	.byte 0x66, 0x0f
	ld	c, (xwa)
	extz	bc
	or	de, bc
	cp	de, 792
	.byte 0xf2, 0xeb, 0xe6, 0xf5, 0xee, 0xbf, 0x04, 0x31
	ld	a, (xbc)
	extz	wa
	ld	c, (xbc+1)
	extz	bc
	call	16115456
	ld	xiz, xhl
	.byte 0xc1, 0x0a, 0x33, 0x21
	cps	a, 1
	.byte 0x66, 0x13
	cps	a, 4
	.byte 0x66, 0x0a
	cp	a, 8
	.byte 0x6e, 0x0a
	ldw	bc, 1056
	.byte 0x68, 0x08
	ldw	bc, 34
	.byte 0x68, 0x03
	ldw	bc, 32
	ld	xwa, xiz
	call	16115584
	.byte 0xe1, 0xf2, 0x33, 0x20
	call	16115497
	.byte 0xc1, 0x2c, 0x33, 0x3e, 0x3f
	pop xiz
	inc	2, xsp
	ret

AccTuning_ReadAndApplyOffset:
	ldda8 a, 13347
	extz wa
	lda_24 xbc, 0xe49fc8
	ldmm_srib 0x07, 0xE4, 0xE0, 0x22, 0x34
	ret

AccTuning_ComplexBytecodeData:
	dec	2, xsp
	push	xiz
	.byte 0xf1, 0x63, 0x33, 0xc8
	jrl	z, 179
	ldda8	c, 13424
	ld	e, c
	and	e, 128
	ldda8	l, 13268
	cpl	l
	cp	e, 128
	jr	z, 13
	ldda8	e, 13051
	ld	a, e
	and	a, 2
	cps	a, 2
	jr	nz, 48
	anddm8	13074, l
	ldda8	a, 1075
	cpda8	a, 13162
	jr	nz, 14
	ldda8	a, 13268
	.byte 0xc1, 0x13, 0x33
	and	xbc, xbc
	.ascii "k3%h"
	.byte 0x04, 0xc1, 0x21, 0x34, 0x25, 0xc1, 0xd4, 0x33
	.byte 0x21
	cps	a, 2
	.byte 0x6e, 0x35, 0xf1, 0xd6, 0x33, 0x02, 0xfe, 0xff
	.byte 0x68, 0x5a
	and	c, 64
	cp	c, 64
	.byte 0x66, 0x09
	and	e, 1
	ld	a, e
	cps	a, 1
	.byte 0x6e, 0xdf, 0xc1, 0x13, 0x33, 0xcf, 0xc1, 0x33
	.byte 0x04, 0x21, 0xc1, 0x68, 0x33, 0xf1, 0x6e, 0xcd
	.byte 0xc1, 0xd4, 0x33, 0x21, 0xc1, 0x12
	ldw	hl, 0xc1e9
	.ascii "i3%hÃ"
	.byte 0xd8, 0x12, 0xf2, 0xf8, 0x9f, 0xe4, 0x31, 0xc3
	.byte 0x07, 0xe4, 0xe0, 0x27, 0xcd, 0x89, 0xd8, 0x12
	.byte 0xd8, 0xec, 0x02, 0xf2, 0x12, 0x63, 0xe4, 0x31
	.byte 0x42, 0x60, 0x48, 0x09, 0x00, 0xe3, 0x07, 0xe4
	.byte 0xe0, 0x82, 0xdb, 0x12, 0xdb, 0x83, 0xd3, 0x07
	.byte 0xe8, 0xec, 0x19, 0xd6, 0x33, 0xf1, 0xd8, 0x33
	.byte 0x02, 0x06, 0x00, 0x68, 0x56, 0xe1, 0xf2, 0x33
	.byte 0x22, 0xbf, 0x04, 0x30, 0x8a, 0x10, 0x23, 0xb0
	.byte 0x43, 0x8a, 0x11, 0x25, 0xb8, 0x01, 0x45, 0x80
	.byte 0x27, 0xdb, 0x12, 0xda, 0x12, 0xda, 0xee, 0x08
	.byte 0xda, 0x89, 0xdb, 0xe1, 0xd9, 0xcf, 0x08, 0x02
	.byte 0x66, 0x0f, 0x80, 0x23, 0xd9, 0x12, 0xd9, 0xe2
	.byte 0xda, 0xcf, 0x18, 0x03, 0xf2, 0xeb, 0xe6, 0xf5
	.byte 0xee, 0xbf, 0x04, 0x31, 0x81, 0x21, 0xd8, 0x12
	.byte 0x89, 0x01, 0x23, 0xd9, 0x12, 0x1d, 0x00, 0xe7
	.byte 0xf5, 0xeb, 0x8e, 0x1d, 0xc9, 0xe7, 0xf5, 0xee
	.byte 0x88, 0xdb, 0x89, 0x1d, 0xd6, 0xe7, 0xf5, 0xf1
	.byte 0xd8, 0x33, 0x53, 0x5e, 0xef, 0x62, 0x0e, 0xf1
	.byte 0xe0, 0x33, 0x00, 0x00, 0xc1, 0xeb, 0x33, 0x25
	.byte 0xda, 0x12, 0xda, 0xec, 0x02, 0xe8, 0xa8, 0xc1
	.byte 0x21, 0x34, 0x21, 0xe8, 0x89, 0xe9, 0xee, 0x02
	.byte 0xe8, 0x81, 0xe9, 0xee, 0x05, 0xe9, 0xc8, 0x40
	.byte 0x54, 0x09, 0x00, 0xd3, 0x07, 0xe4, 0xe8, 0x19
	.byte 0x97, 0x32, 0xd1, 0x97, 0x32, 0x3f, 0xfe, 0xff
	.byte 0x6e, 0x04, 0xf1, 0xe0, 0x33, 0xb8, 0xc1, 0xeb
	.byte 0x33, 0x25, 0xda, 0x12, 0xda, 0xec, 0x02, 0xe8
	.byte 0xa8, 0xc1, 0x21, 0x34, 0x21, 0xe8, 0x89, 0xe9
	.byte 0xee, 0x02, 0xe8, 0x81, 0xe9, 0xee, 0x05, 0xe9
	.byte 0xc8, 0x40, 0x54, 0x09, 0x00, 0xf3, 0x07, 0xe4
	.byte 0xe8, 0x30, 0x98, 0x02, 0x19, 0x87, 0x32, 0xc1
	.byte 0xed, 0x33, 0x21, 0xd8, 0x12, 0xd8, 0xec, 0x02
	.byte 0xd8, 0x8a, 0xda, 0xc8, 0x20, 0x00, 0xe8, 0xa8
	.byte 0xc1, 0x21, 0x34, 0x21, 0xe8, 0x89, 0xe9, 0xee
	.byte 0x02, 0xe8, 0x81, 0xe9, 0xee, 0x05, 0xe9, 0xc8
	.byte 0x40, 0x54, 0x09, 0x00, 0xd3, 0x07, 0xe4, 0xe8
	.byte 0x19, 0x9b, 0x32, 0xd1, 0x9b, 0x32, 0x3f, 0xfe
	.byte 0xff, 0x6e, 0x04, 0xf1, 0xe0, 0x33, 0xba, 0xc1
	.byte 0xed, 0x33, 0x21, 0xd8, 0x12, 0xd8, 0xec, 0x02
	.byte 0xd8, 0x8a, 0xda, 0xc8, 0x20, 0x00, 0xe8, 0xa8
	.byte 0xc1, 0x21, 0x34, 0x21, 0xe8, 0x89, 0xe9, 0xee
	.byte 0x02, 0xe8, 0x81, 0xe9, 0xee, 0x05, 0xe9, 0xc8
	.byte 0x40, 0x54, 0x09, 0x00, 0xf3, 0x07, 0xe4, 0xe8
	.byte 0x30, 0x98, 0x02, 0x19, 0x8b, 0x32, 0xc1, 0xee
	.byte 0x33, 0x21, 0xd8, 0x12, 0xd8, 0xec, 0x02, 0xd8
	.byte 0x8a, 0xda, 0xc8, 0x40, 0x00, 0xe8, 0xa8, 0xc1
	.byte 0x21, 0x34, 0x21, 0xe8, 0x89, 0xe9, 0xee, 0x02
	.byte 0xe8, 0x81, 0xe9, 0xee, 0x05, 0xe9, 0xc8, 0x40
	.byte 0x54, 0x09, 0x00, 0xd3, 0x07, 0xe4, 0xe8, 0x19
	.byte 0x9d, 0x32, 0xd1, 0x9d, 0x32, 0x3f, 0xfe, 0xff
	.byte 0x6e, 0x04, 0xf1, 0xe0, 0x33, 0xbb, 0xc1, 0xee
	.byte 0x33, 0x21, 0xd8, 0x12, 0xd8, 0xec, 0x02, 0xd8
	.byte 0x8a, 0xda, 0xc8, 0x40, 0x00, 0xe8, 0xa8, 0xc1
	.byte 0x21, 0x34, 0x21, 0xe8, 0x89, 0xe9, 0xee, 0x02
	.byte 0xe8, 0x81, 0xe9, 0xee, 0x05, 0xe9, 0xc8, 0x40
	.byte 0x54, 0x09, 0x00, 0xf3, 0x07, 0xe4, 0xe8, 0x30
	.byte 0x98, 0x02, 0x19, 0x8d, 0x32, 0xc1, 0xef, 0x33
	.byte 0x21, 0xd8, 0x12, 0xd8, 0xec, 0x02, 0xd8, 0x8a
	.byte 0xda, 0xc8, 0x60, 0x00, 0xe8, 0xa8, 0xc1, 0x21
	.byte 0x34, 0x21, 0xe8, 0x89, 0xe9, 0xee, 0x02, 0xe8
	.byte 0x81, 0xe9, 0xee, 0x05, 0xe9, 0xc8, 0x40, 0x54
	.byte 0x09, 0x00, 0xd3, 0x07, 0xe4, 0xe8, 0x19, 0x9f
	.byte 0x32, 0xd1, 0x9f, 0x32, 0x3f, 0xfe, 0xff, 0x6e
	.byte 0x04, 0xf1, 0xe0, 0x33, 0xbc, 0xc1, 0xef, 0x33
	.byte 0x21, 0xd8, 0x12, 0xd8, 0xec, 0x02, 0xd8, 0x8a
	.byte 0xda, 0xc8, 0x60, 0x00, 0xe8, 0xa8, 0xc1, 0x21
	.byte 0x34, 0x21, 0xe8, 0x89, 0xe9, 0xee, 0x02, 0xe8
	.byte 0x81, 0xe9, 0xee, 0x05, 0xe9, 0xc8, 0x40, 0x54
	.byte 0x09, 0x00, 0xf3, 0x07, 0xe4, 0xe8, 0x30, 0x98
	.byte 0x02, 0x19, 0x8f, 0x32, 0xc1, 0xf0, 0x33, 0x21
	.byte 0xd8, 0x12, 0xd8, 0xec, 0x02, 0xd8, 0x8a, 0xda
	.byte 0xc8, 0x80, 0x00, 0xe8, 0xa8, 0xc1, 0x21, 0x34
	.byte 0x21, 0xe8, 0x89, 0xe9, 0xee, 0x02, 0xe8, 0x81
	.byte 0xe9, 0xee, 0x05, 0xe9, 0xc8, 0x40, 0x54, 0x09
	.byte 0x00, 0xd3, 0x07, 0xe4, 0xe8, 0x19, 0xa1, 0x32
	.byte 0xd1, 0xa1, 0x32, 0x3f, 0xfe, 0xff, 0x6e, 0x04
	.byte 0xf1, 0xe0, 0x33, 0xbd, 0xc1, 0xf0, 0x33, 0x21
	.byte 0xd8, 0x12, 0xd8, 0xec, 0x02, 0xd8, 0x8a, 0xda
	.byte 0xc8, 0x80, 0x00, 0xe8, 0xa8, 0xc1, 0x21, 0x34
	.byte 0x21, 0xe8, 0x89, 0xe9, 0xee, 0x02, 0xe8, 0x81
	.byte 0xe9, 0xee, 0x05, 0xe9, 0xc8, 0x40, 0x54, 0x09
	.byte 0x00, 0xf3, 0x07, 0xe4, 0xe8, 0x30, 0x98, 0x02
	.byte 0x19, 0x91, 0x32, 0xf1, 0x99, 0x32, 0x02, 0xfe
	.byte 0xff, 0xf1, 0x89, 0x32, 0x02, 0x06, 0x00, 0xf1
	.byte 0xe0, 0x33, 0xb9, 0x0e, 0x1e, 0x01, 0x00, 0x0e
	.byte 0x0e

AccTone_WriteProgramChange:
	push xiz
	ld xix, xwa
	ld l, (xbc)
	ld h, (xbc + 1)
	stdi8 37111, 72
	push xix
	call PartCtrl_WriteProgramChange
	pop xix
	ld xbc, xix
	ld (xbc), l
	ld (xbc + 1), h
	pop xiz
	ret

AccTone_ValidateAndClamp:
	push xiz
	ld xbc, xwa
	ld l, (xbc)
	ld h, (xbc + 1)
	push xbc
	call VoiceParam_ClampAndValidate
	pop xbc
	ld (xbc), l
	ld (xbc + 1), h
	pop xiz
	ret

AccTone_LookupByProgram_Dispatch:
	push	xiz
	and	xwa, 255
	and	xbc, 255
	ld	h, c
	call	16072090
	ld	xhl, xiy
	pop	xiz
	ret
	push	xiz
	ld	xiy, xwa
	call	16081779
	pop	xiz
	ret
	push	xiz
	ld	w, a
	call	16074376
	pop	xiz
	ret
	push	xiz
	ld	xiy, xwa
	call	16072277
	pop	xiz
	ret
	push	xiz
	ld	xiy, xwa
	ld	xhl, xbc
	and	xhl, 65535
	call	16072203
	pop	xiz
	ret
	push	xiz
	and	xwa, 255
	call	16082618
	and	xhl, 65535
	pop	xiz
	ret
	push	xiz
	ld	xiy, xwa
	call	16081606
	pop	xiz
	ret
	push	xiz
	ld	xiy, xwa
	call	16092485
	pop	xiz
	ret
	push	xiz
	call	16070640
	pop	xiz
	ret
	push	xiz
	ld	xiy, xwa
	ld	xhl, xbc
	and	xhl, 65535
	call	16081416
	pop	xiz
	ret
	push	xiz
	ld	xiy, xwa
	ld	xhl, xbc
	and	xhl, 65535
	call	16092379
	pop	xiz
	ret
	push	xiz
	call	16080528
	pop	xiz
	ret
	push	xiz
	call	16073687
	pop	xiz
	ret
	push	xiz
	call	16073552
	pop	xiz
	ret
	push	xiz
	call	16092931
	pop	xiz
	ret
	push	xiz
	call	16073734
	pop	xiz
	ret
	push	xiz
	call	16092990
	pop	xiz
	ret
	push	xiz
	call	16090068
	pop	xiz
	ret
	push	xiz
	call	16090546
	pop	xiz
	ret
	push	xiz
	call	16084447
	and	xhl, 65535
	pop	xiz
	ret
	push	xiz
	ld	xiy, xwa
	ld	xhl, xbc
	and	xhl, 65535
	call	16084176
	and	xwa, 65535
	ld	xhl, xwa
	pop	xiz
	ret
	push	xix
	.ascii "=>89:;"
	xor	xwa, xwa
	.byte 0xc1, 0xd4, 0x33, 0x21
	call	16113211
	.ascii "[ZYX^]\\"
	.byte 0x0e
	.ascii "<=>89:;è"
	.byte 0xd0, 0xc1, 0xd4, 0x33, 0x21, 0x1d, 0x69, 0xde
	.byte 0xf5
	.ascii "[ZYX^]\\"
	.byte 0x0e

AccTone_CallWithSaveAll:
	push xix
	push xiy
	push xiz
	push xwa
	push xbc
	push xde
	push xhl
	call AccVoice_ClearChannelStates
	pop xhl
	pop xde
	pop xbc
	pop xwa
	pop xiz
	pop xiy
	pop xix
	ret

AccVoice_IncrementBarWithSave:
	push xix
	push xiy
	push xiz
	push xwa
	push xbc
	push xde
	push xhl
	call AccVoice_IncrementBarCounter
	pop xhl
	pop xde
	pop xbc
	pop xwa
	pop xiz
	pop xiy
	pop xix
	ret

AccTuning_DispatchDataBlock_A:	.ascii "<=>89:;"
	call	16113404
	pop	xhl
	pop	xde
	pop	xbc
	pop	xwa
	pop	xiz
	pop	xiy
	pop	xix
	ret
	push	xix
	push	xiy
	push	xiz
	push	xwa
	push	xbc
	push	xde
	push	xhl
	call	16113686
	pop	xhl
	pop	xde
	pop	xbc
	pop	xwa
	pop	xiz
	pop	xiy
	pop	xix
	ret
	push	xix
	push	xiy
	push	xiz
	push	xwa
	push	xbc
	push	xde
	push	xhl
	call	16113937
	.ascii "[ZYX^]\\"
	.byte 0x0e
	.ascii "<=>89:;"
	.byte 0x1d, 0x06, 0xe2, 0xf5
	.byte 0x5b, 0x5a, 0x59, 0x58
	.byte 0x5e, 0x5d, 0x5c, 0x0e
	.byte 0x3c, 0x3d, 0x3e, 0x38
	.byte 0x39, 0x3a, 0x3b, 0x1d, 0x78, 0xd6, 0xf5, 0xcf
	.byte 0x89, 0x5b, 0x5a, 0xc9, 0x8d, 0x59, 0x58, 0x5e
	.byte 0x5d, 0x5c, 0x0e

AccTuning_CallWithSaveRestore:
	push xix
	push xiy
	push xiz
	push xwa
	push xbc
	push xde
	push xhl
	call AccTuning_ReadAndApplyOffset
	pop xhl
	pop xde
	pop xbc
	pop xwa
	pop xiz
	pop xiy
	pop xix
	ret

AccTuning_DispatchDataBlock_B:	.ascii "<=>9;"
	call	16114598
	pop	xhl
	pop	xbc
	pop	xiz
	pop	xiy
	pop	xix
	ret

AccTone_LookupByProgramWrapped:
	push xix
	push xiy
	push xiz
	push xbc
	push xhl
	and xwa, 0xFF
	xor xbc, xbc
	ld c, d
	call AccTone_LookupByProgram
	ld a, l
	pop xhl
	pop xbc
	pop xiz
	pop xiy
	pop xix
	ret

AccTone_JumpTableData:
	call	16111813
	ret
	call	16112489
	ret
	call	16112464
	ret
	call	16112205
	ret
	call	16111991
	ret
	push	xiz
	call	16081537
	pop	xiz
	ret
	.byte 0x18
	cp	xiy, xbc
	nop
	ldf	233
	.byte 0xf5, 0x00, 0x31
	cp	xiy, xbc
	nop
	ldb	a, 233
	.byte 0xf5, 0x00

AccTone_StubReturn_A:
	ret

AccTone_StubReturn_B:
	ret

AccPatch_CountSlots_Wrapper:
	calr AccPatch_CountAvailableSlots
	ret

AccPatch_CountSlotsAlt:
	calr AccPatch_CountSlotsAlt_Body
	ret

AccPatch_InitAndCountSlots:
	calr AccPatch_CheckAndInitDemo
	calr AccPatch_CountAvailableSlots
	call VoiceSlot_Dispatch_Type81
	stdi8 14775, 10
	ret

AccDemo_InitDone:
	push xiz
	call AccDemo_Init_Wrap
	calr AccPatch_CountAvailableSlots
	pop xiz
	ret

AccPatch_InitByteData:
	push	xiz
	call	16167437
	pop	xiz
	ret
	call	16167845
	ret
	call	16109088
	ret
	push	xiz
	calr	4581
	calr	2801
	.byte 0xc1, 0xcd, 0x34, 0x3e, 0x80
	pop	xiz
	ret

AccDemo_InitWithFlag:
	push xiz
	ordi8 13521, 128
	call AccDemo_Init_Wrap
	pop xiz
	ret

AccPatch_MultiCallWrapper:
	push	xiz
	calr	4559
	calr	18
	pop	xiz
	ret
	push	xiz
	calr	12
	call	16167437
	pop	xiz
	ret
	push	xiz
	calr	2
	pop	xiz
	.byte 0x0e

AccPatch_ClearModeFlag:
	stdi8 13781, 0
	ret


Not_sure_maybe_SOFT_VERSION_related:
	.byte 0xc1, 0x16, 0x36, 0x3c, 0xfe
	stdi8	13781, 0
	ld	xwa, 608256
	cps	hl, 0
	jr	z, 19
	stdi8	13781, 1
	call	16776933
	cp	l, 255
	jr	z, 5
	stdi8	13781, 0
	ret
	.byte 0xc1, 0x9b, 0x37, 0x04, 0xc1, 0x16, 0x36, 0x3c, 0xfe
	stdi8	13781, 0
	.byte 0xc1, 0xd6, 0x34, 0x04
	stdi8	13526, 0
	cpdi8	13526, 30
	jr	z, 46
	stdi8	14235, 16
	calr	62
	stdi8	14235, 8
	calr	54
	stdi8	14235, 1
	calr	46
	stdi8	14235, 2
	calr	38
	stdi8	14235, 4
	calr	30
	incdi8	1, 13526
	jr	-53
	.byte 0xf1, 0xd6, 0x34, 0x04, 0xf1, 0x9b, 0x37, 0x04, 0xc1, 0x16, 0x36, 0x3c, 0xfe
	cpdi8	13781, 0
	jr	z, 3
	calr	-222
	ret
	calr	367
	calr	446
	ldb	w, 0
	mul8rr	a, c
	calr	38
	cpdi16	13842, 65535
	jr	z, 5
	calr	145
	jr	8
	calr	-252
	.byte 0xc1, 0x16, 0x36, 0x3e, 0x01, 0xf1, 0x16, 0x36, 0xc8
	jr	z, 5
	stdi8	13781, 1
	.byte 0xc1, 0x16, 0x36, 0x3c, 0xfe
	ret
	ldb	w, 0
	ldb	c, 0
	cp	c, a
	jr	z, 26
	push c
	pushw	wa
	calr	350
	cp	a, 131
	jr	z, 7
	popw	wa
	pop c
	inc	1, c
	jr	-22
	popw	wa
	pop c
	calr	3
	ld	w, b
	ret
	cp	c, a
	jr	z, 17
	push c
	push_a
	calr	17
	cps	b, 1
	jr	z, 9
	pop_a
	pop c
	inc	1, c
	jr	-21
	jr	3
	pop_a
	pop c
	ret
	ldda16	hl, 13842
	calr	836
	ldda16	hl, 13844
	.byte 0xf3
	.long StyleGroup_FunkFusion_Pad
	xor	a, (xbc)
	push_a
	ldw	iz, 55328
	.byte 0xcf, 0xfe
	nop
	jr	nz, 20
	cpdi16	13524, 0
	jr	nz, 4
	ldb	b, 1
	jr	16
	call	16124355
	ldb	b, 0
	jr	8
	inc	1, wa
	stda16	13844, wa
	ldb	b, 0
	ret
	ldda16	hl, 13842
	calr	780
	ldda16	hl, 13844
	.byte 0xf3
	.long StyleGroup_FunkFusion_Pad
	adc	(xhl), d
	pop_sr
	ldb	c, 188
	pop_sr
	push_sr
	swi	7
	swi	7
	cp	hl, 340
	jr	nc, 21
	calr	753
	.byte 0x84, 0x3c, 0x7f
	ld	hl, (xix+3)
	.byte 0xbc, 0x01, 0x02, 0xff, 0xff, 0xbc, 0x03, 0x02, 0xff, 0xff
	jr	-27
	ret

AccPatch_CheckAndInitDemo:
	ld xiy, 0x94800
	add xiy, 0xE
	ld wa, (xiy)
	cps wa, 0
	jr z, AccPatch_CheckAndInitDemo_Ret
	call AccDemo_Init_Wrap

AccPatch_CheckAndInitDemo_Ret:
	ret

AccPatch_SlotConfigByteData:
	ret
	ret
	.byte 0xc1, 0x9b, 0x37, 0x04, 0xc1, 0xd6, 0x34, 0x04
	stdi8	13526, 0
	cpdi8	13526, 12
	jr	z, 46
	stdi8	14235, 16
	calr	47
	stdi8	14235, 8
	calr	39
	stdi8	14235, 1
	calr	31
	stdi8	14235, 2
	calr	23
	stdi8	14235, 4
	calr	15
	incdi8	1, 13526
	jr	-53
	.byte 0xf1, 0xd6, 0x34, 0x04, 0xf1, 0x9b, 0x37, 0x04
	ret
	cpdi8	13526, 12
	jr	nc, 41
	calr	39
	calr	62
	calr	115
	ld	e, c
	ldb	c, 1
	cp	c, e
	jr	z, 24
	push e
	push_a
	push c
	calr	121
	pop c
	push c
	calr	134
	pop c
	pop_a
	pop e
	inc	1, c
	jr	-28
	ret

AccPatch_InitCurrentSlotPointer:
	calr AccPatch_GetCurrentSlotAddr
	ldda8 a, 14235
	calr MapBitFlagsToChannelOffset
	ld_sriw3 HL, 0x03, 0xF4, 0xE1
	stda16 13842, xhl
	stdi16 13844, 6
	ret

AccPatch_SlotScanByteData:
	ldb	c, 0
	cp	c, 8
	jr	z, 11
	push c
	calr	86
	pop c
	inc	1, c
	jr	-16
	ret
	call	16121368
	cp	a, 129
	jr	z, 19
	cp	a, 131
	jr	z, 22
	.byte 0x14
	call	16121389
	pop_a
	.byte 0xf1, 0x16, 0x36, 0xc8
	jr	nz, 2
	jr	-28
	.byte 0x14
	call	16121389
	.byte 0x15
	jr	0
	ret
	calr	435
	lds32	xwa, 0
	ld	a, (xiy+12)
	add	xwa, 14969738
	ld	a, (xwa)
	ld	c, (xiy+13)
	inc	1, c
	ret
	ldb	c, 0
	cp	c, a
	jr	z, 13
	push c
	push_a
	calr	-71
	pop_a
	pop c
	inc	1, c
	jr	-17
	ret
	push c
	lds32	xwa, 0
	ldb	a, 160
	ldda8	c, 13526
	mul8rr	a, c
	lds32	xbc, 0
	ldda8	c, 14235
	and	c, 31
	srl	c, 1
	add	xbc, 16116814
	lds32	xde, 0
	ld	e, (xbc)
	mul	de, 32
	add	xwa, xde
	add	xwa, 3136
	add	xwa, 608256
	ld	xix, xwa
	pop c
	sll	c, 2
	ldda16	wa, 13842
	.byte 0xf3, 0x03, 0xf0, 0xe4, 0x50
	ldda16	wa, 13844
	inc	2, c
	.byte 0xf3, 0x03, 0xf0, 0xe4, 0x50
	ret
	push_sr
	pop_sr
	.byte 0x04
	nop
	.byte 0x01
	nop
	nop
	nop
	nop

AccPatch_RefreshSlotOffset_Wrap:
	push xiz
	call AccPatch_RefreshSlotOffset
	pop xiz
	ret

AccPatch_RefreshSlotOffset:
	calr AccPatch_GetCurrentSlotAddr
	lds32 xhl, 0
	ld l, (xiy + 12)
	sll l, 1
	add xhl, 0xF5F068
	ld wa, (xhl)
	ld (xiy + 16), wa
	ret

Seq_RhythmProcessor:
	calr RhythmProc_CheckStyleChange
	calr RhythmProc_CheckPlayMode
	calr RhythmProc_CallDispatch
	calr RhythmProc_NullStub
	calr RhythmProc_CheckRhythmEdit
	calr RhythmProc_CheckStyleSwitch
	calr RhythmProc_CheckRepeatFlag
	calr AccPatch_ProcessPartChanges
	calr RhythmProc_SavePrevState
	ret

RhythmProc_CheckStyleChange:
	cpdi8 36150, 178
	jr z, RhythmProc_StyleChange_Init
	jr RhythmProc_StyleChange_Ret

RhythmProc_StyleChange_Init:
	bitda 2, 13517
	jr z, RhythmProc_StyleChange_Ret
	anddi8 13517, 251
	calr AccPatch_InitCurrentSlot
	calr AccPatch_UpdateAllChains
	call RhythmPatInit_LoadParams

RhythmProc_StyleChange_Ret:
	ret

RhythmProc_CheckPlayMode:
	cpdi8 36150, 181
	jr z, RhythmProc_PlayMode_Compare
	ldda8 a, 13519
	and a, 0xF3
	stda8 13519, a
	jr AccPatch_CopySlotsExit

RhythmProc_PlayMode_Compare:
	cpdi8 13605, 181
	jr z, RhythmProc_PlayMode_SendTempo
	stdi8 13822, 0
	ldda8 a, 12979
	and a, 0x7
	stda8 13532, a

RhythmProc_PlayMode_SendTempo:
	bitda 1, 13519
	jr z, AccPatch_DetectModeChange
	anddi8 13519, 253
	ldda8 a, 13519
	and a, 0xC
	cps a, 0
	jr nz, AccPatch_DetectModeChange
	ldda8 a, 13820
	and a, 0xC
	cps a, 0
	jr nz, AccPatch_DetectModeChange
	calr AccPatch_RebuildChannelSlot
	push xwa
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	call SoundCtrl_SendTempoScaled
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	pop xwa

AccPatch_DetectModeChange:
	call AccPatch_SeqDispatch_Entry
	ldda8 a, 12979
	and a, 0x7
	cpda8 a, 13532
	jr z, AccPatch_CopySlotsExit
	stda8 13532, a
	cpdi8 36152, 181
	jr nz, AccPatch_CopySlotsExit
	push xwa
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	call SoundCtrl_SendAccTempo
	call SoundCtrl_SendTempoScaled
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	pop xwa

AccPatch_CopySlotsExit:
	ret

RhythmProc_CallDispatch:
	call AccPlayback_InitOrUpdate
	ret

RhythmProc_NullStub:
	ret

RhythmProc_CopySlotData_Wrap:
	push xiz
	call RhythmProc_CopySlotData
	pop xiz
	ret

RhythmProc_CopySlotData:
	calr AccPatch_GetCurrentSlotAddr
	ld xbc, 0x40
	add xiy, xbc
	ld xix, 0x34BC
	push xix
	push xiy
	pop xix
	pop xiy
	ld xbc, 0x10
	ldir85
	ret

RhythmProc_ChannelMapTable:
	nop
	nop
	nop
	nop
	.byte 0x04, 0x04, 0x04, 0x04
	ldio	8, 8
	ldio	0, 0
	nop
	nop
	nop
	nop
	.byte 0x04, 0x04, 0x04, 0x04, 0x04, 0x04
	.fill 6, 1, 0x08

; ============================================================================
; AccPatch_GetCurrentSlotAddr - Get address of current accompaniment patch slot
; ============================================================================
; Input:  None (reads current slot index from 13526)
; Output: XIY = pointer to patch slot data (at 0x94800 + slot*96 + 96)
; Reads the current patch slot index (0-29, capped), multiplies by 96-byte
; stride, and returns a pointer into the accompaniment patch table at 0x94800.
; ============================================================================
AccPatch_GetCurrentSlotAddr:
	lds32 xhl, 0
	ldda8 l, 13526
	cp l, 0x1E
	jr c, AccPatch_GetSlotAddr_Valid
	ldb l, 0x0

AccPatch_GetSlotAddr_Valid:
	mul hl, 0x60
	add xhl, 0x60
	ld xiy, 0x94800
	add xiy, xhl
	ret

AccPatch_GetSlotAddr_Preserve:
	push	xwa
	push	xix
	xor	xhl, xhl
	ldda8	l, 13526
	cp	l, 30
	jr	c, 2
	xor	l, l
	mul	hl, 96
	add	xhl, 96
	ld	xiy, 608256
	add	xiy, xhl
	pop	xix
	pop	xwa
	ret

; ============================================================================
; AccPatch_GetEntryAddr - Get address of an accompaniment patch entry by index
; ============================================================================
; Input:  HL = patch entry index (0xFFFF = return immediately)
; Output: XIX = pointer to patch entry (at 0x95C00 + index*256)
; Converts a patch index to a memory address in the patch data table.
; Each entry is 256 bytes. Returns immediately if index is 0xFFFF (invalid).
; ============================================================================
AccPatch_GetEntryAddr:
	cp hl, 0xFFFF
	jr z, AccPatch_GetEntryAddr_Ret
	pushw hl
	pushw hl
	lds32 xhl, 0
	popw hl
	sll xhl, 8
	ld xix, 0x95C00
	add xix, xhl
	popw hl

AccPatch_GetEntryAddr_Ret:
	ret

AccPatch_InitCurrentSlot:
	calr AccPatch_GetCurrentSlotAddr
	calr AccPatch_FreeAllChains
	calr AccPatch_CopyDefaultsForInit
	calr AccPatch_FillAllVoiceData
	ordi8 13517, 128
	calr AccPatch_ScanToSequenceStart
	ret

AccPatch_InitFromSlotIndex:
	push xiz
	calr AccPatch_InitFromIndex
	pop xiz
	ret

AccPatch_InitFromIndex:
	xor xhl, xhl
	ldda8 l, 14764
	cp l, 0x1E
	jr c, AccPatch_InitFromIndex_Valid
	xor l, l

AccPatch_InitFromIndex_Valid:
	mul hl, 0x60
	add xhl, 0x60
	ldda32 xiy, 14766
	add xiy, xhl
	calr AccPatch_FreeAllChains_Alt
	calr AccPatch_CopyDefaultsToSlot
	calr AccPatch_FillAllSlots_Alt
	ordi8 13517, 128
	calr AccPatch_ScanSequenceToEnd
	ret

AccPatch_InitByteStub:
	push	xiz
	calr	2
	pop	xiz
	ret

AccPat_InitWorkAreaFromSlot:
	push xwa
	ldda8 a, 13526
	stda8 14764, a
	ld xwa, 0x94800
	stda32 14766, xwa
	pop xwa
	calr AccPatch_InitFromIndex
	ret

AccPatch_CopyDefaultsToSlot:
	push xiy
	push xwa
	push xbc
	ld a, (xiy + 12)
	pushw wa
	ld wa, (xiy + 16)
	pushw wa
	push xiy
	add xiy, 0xC
	ld xix, 0xF5EFA7
	ld xbc, 0x54
	push xiy
	push xix
	pop xiy
	pop xix
	ldir85
	pop xiy
	popw wa
	ld bc, wa
	popw wa
	cps a, 7
	jr nz, AccPatch_CopyDefaults_Done
	ld (xiy + 16), bc

AccPatch_CopyDefaults_Done:
	pop xbc
	pop xwa
	pop xiy
	calr AccPatch_ClearSlot13ByIndex
	ret

AccPatch_ClearSlot13ByIndex:
	push xwa
	ldb a, 0x0
	ldda8 w, 14764
	cp w, 0xE
	jr nz, AccPatch_ClearSlot13_Check0F
	ld (xiy + 13), a

AccPatch_ClearSlot13_Check0F:
	cp w, 0xF
	jr nz, AccPatch_ClearSlot13_Check14
	ld (xiy + 13), a

AccPatch_ClearSlot13_Check14:
	cp w, 0x14
	jr nz, AccPatch_ClearSlot13_Check15
	ld (xiy + 13), a

AccPatch_ClearSlot13_Check15:
	cp w, 0x15
	jr nz, AccPatch_ClearSlot13_Check1A
	ld (xiy + 13), a

AccPatch_ClearSlot13_Check1A:
	cp w, 0x1A
	jr nz, AccPatch_ClearSlot13_Check1B
	ld (xiy + 13), a

AccPatch_ClearSlot13_Check1B:
	cp w, 0x1B
	jr nz, AccPatch_ClearSlot13_Done
	ld (xiy + 13), a

AccPatch_ClearSlot13_Done:
	pop xwa
	ret

AccPatch_MiscByteData:
	calr	-274
	calr	15
	calr	177
	calr	88
	.byte 0xc1, 0xcd, 0x34, 0x3e, 0x80
	calr	4341
	ret

AccPatch_FreeAllChains:
	ld hl, (xiy + 256)
	calr AccPatch_FreeChainEntries
	ld hl, (xiy + 4)
	calr AccPatch_FreeChainEntries
	ld hl, (xiy + 6)
	calr AccPatch_FreeChainEntries
	ld hl, (xiy + 8)
	calr AccPatch_FreeChainEntries
	ld hl, (xiy + 10)
	calr AccPatch_FreeChainEntries
	ret

AccPatch_FreeChainEntries:
	push xiy
	calr AccPatch_GetEntryAddr
	ld wa, (xix + 3)
	cp wa, 0xFFFF
	jr z, AccPatch_FreeChain_Done

AccPatch_FreeChainLoop:
	ld hl, wa
	ldw (xix + 3), 0xFFFF
	calr AccPatch_GetEntryAddr
	ldw (xix + 1), 0xFFFF
	andmi8 (xix), 0x7F
	incdi16 1, 13524
	ld wa, (xix + 3)
	cp wa, 0xFFFF
	jr z, AccPatch_FreeChain_Done
	jr AccPatch_FreeChainLoop

AccPatch_FreeChain_Done:
	pop xiy
	ret

AccPatch_FillAllVoiceData:
	ld hl, (xiy + 256)
	calr AccPatch_FillEntryWithVoiceData
	ld hl, (xiy + 4)
	calr AccPatch_FillEntryWithVoiceData
	ld hl, (xiy + 6)
	calr AccPatch_FillEntryWithVoiceData
	ld hl, (xiy + 8)
	calr AccPatch_FillEntryWithVoiceData
	ld hl, (xiy + 10)
	calr AccPatch_FillEntryWithVoiceData
	ret

AccPatch_FillEntryWithVoiceData:
	push xiy
	pushw hl
	ld l, (xiy + 12)
	xor h, h
	lds32 xwa, 0
	ld xbc, 0xE46B8A
	ld_srib3 A, 0x07, 0xE4, 0xEC
	lds32 xbc, 0
	ld b, (xiy + 13)
	inc 1, b
	mul8rr a, b
	popw hl
	calr AccPatch_GetEntryAddr
	add xix, 0x6
	ldb l, 0x81

AccPatch_FillVoice_Loop:
	ld (xix), l
	dec 1, wa
	inc 1, xix
	cps wa, 0
	jr nz, AccPatch_FillVoice_Loop
	ld (xix), 0x83
	pop xiy
	ret

AccPatch_CopyDefaultsForInit:
	push xiy
	push xwa
	push xbc
	ld a, (xiy + 12)
	pushw wa
	ld wa, (xiy + 16)
	pushw wa
	push xiy
	add xiy, 0xC
	ld xix, 0xF5EFA7
	ld xbc, 0x54
	push xiy
	push xix
	pop xiy
	pop xix
	ldir85
	pop xiy
	popw wa
	ld bc, wa
	popw wa
	cps a, 7
	jr nz, AccPatch_CopyDefaults_InitDone
	ld (xiy + 16), bc

AccPatch_CopyDefaults_InitDone:
	pop xbc
	pop xwa
	pop xiy
	calr AccPatch_ClearSlot13BySlotIdx
	ret

AccPatch_DefaultSlotData:
	reti
	.byte 0x01
	ldb	w, 128
	pop	xwa
	.byte 0x02
	nop
	nop
	.zero 8
	nop
	nop
	nop
	nop
	pushw	wa
	nop
	ld	xwa, 2131120128
	nop
	nop
	nop
	incf
	nop
	.byte 0x50
	ei	0x7f
	nop
	push	xwa
	nop
	.byte 0x74, 0x00, 0x50
	ei	0x7f
	nop
	ld	xbc, 1342193664
	ei	0x7f
	nop
	.asciz "    clear       "
	.zero 15

AccPatch_ClearSlot13BySlotIdx:
	ldb a, 0x0
	cpdi8 13526, 14
	jr nz, AccPatch_ClearSlot13_Idx0F
	ld (xiy + 13), a

AccPatch_ClearSlot13_Idx0F:
	cpdi8 13526, 15
	jr nz, AccPatch_ClearSlot13_Idx14
	ld (xiy + 13), a

AccPatch_ClearSlot13_Idx14:
	cpdi8 13526, 20
	jr nz, AccPatch_ClearSlot13_Idx15
	ld (xiy + 13), a

AccPatch_ClearSlot13_Idx15:
	cpdi8 13526, 21
	jr nz, AccPatch_ClearSlot13_Idx1A
	ld (xiy + 13), a

AccPatch_ClearSlot13_Idx1A:
	cpdi8 13526, 26
	jr nz, AccPatch_ClearSlot13_Idx1B
	ld (xiy + 13), a

AccPatch_ClearSlot13_Idx1B:
	cpdi8 13526, 27
	jr nz, AccPatch_ClearSlot13_IdxDone
	ld (xiy + 13), a

AccPatch_ClearSlot13_IdxDone:
	ret

AccPatch_SetVoiceAndInit:
	calr AccPatch_GetCurrentSlotAddr
	ldda8 a, 13528
	ld (xiy + 12), a
	push xiy
	calr AccPatch_InitAllSentinels
	pop xiy
	lds32 xhl, 0
	ldda8 l, 13528
	sll l, 1
	xor h, h
	add xhl, 0xF5F068
	ld wa, (xhl)
	ld (xiy + 16), wa
	calr AccPatch_CheckConfigType
	ordi8 13517, 128
	ret

AccPatch_VoiceStrideTable:
	nop
	nop
	pop	xwa
	.byte 0x02
	ldio	2, 24
	.byte 0x03
	nop
	nop
	nop
	nop
	push 1
	pop	xwa
	.byte 0x02
	nop
	nop
	ldio	2, 0
	nop
	push_f
	pop_sr
	nop
	nop
	nop
	nop
	push 1
	pop	xwa
	.byte 0x02
	nop
	nop
	ldio	2, 0
	nop
	push_f
	pop_sr

AccPatch_CheckConfigType:
	cpdi8 13529, 6
	jr z, RhythmConfig_CheckAndSkip
	cpdi8 13529, 8
	jr z, RhythmConfig_CheckAndSkip
	cpdi8 13529, 4
	jr z, RhythmConfig_CheckAndSkip
	cpdi8 13529, 3
	jr z, RhythmConfig_CheckAndSkip
	jr AccPatch_CheckConfig_Done

RhythmConfig_CheckAndSkip:
	call RhythmConfig_ReturnStub

AccPatch_CheckConfig_Done:
	ret

AccPatch_InitAllSentinels:
	calr AccPatch_ReadVoiceStride
	lds32 xwa, 0
	ldda8 a, 13529
	ldda8 b, 13527
	and b, 0x7
	inc 1, b
	mul8rr a, b
	ld c, a
	ld hl, (xiy + 256)
	calr AccPatch_InitSlotSentinels
	ld hl, (xiy + 4)
	calr AccPatch_InitSlotSentinels
	ld hl, (xiy + 6)
	calr AccPatch_InitSlotSentinels
	ld hl, (xiy + 8)
	calr AccPatch_InitSlotSentinels
	ld hl, (xiy + 10)
	calr AccPatch_InitSlotSentinels
	ret

AccPatch_InitSlotSentinels:
	push xiy
	push c
	calr AccPatch_GetEntryAddr
	add xix, 0x6
	pop c
	ld b, c

AccPatch_WriteSentinel_Loop:
	ld (xix), 0x81
	inc 1, xix
	dec 1, b
	cps b, 0
	jr nz, AccPatch_WriteSentinel_Loop
	ld (xix), 0x83
	pop xiy
	ret

AccPatch_ReadVoiceStride:
	lds32 xhl, 0
	ldda8 l, 13528
	ld xbc, 0xE46B8A
	add xbc, xhl
	ld a, (xbc)
	stda8 13529, a
	ret

RhythmProc_CheckRhythmEdit:
	cpdi8 36150, 180
	jr nz, RhythmProc_RhythmEdit_Ret
	calr RhythmProc_CheckVoiceChange
	calr RhythmProc_CheckConfigBits

RhythmProc_RhythmEdit_Ret:
	ret

RhythmProc_CheckVoiceChange:
	bitda 1, 13518
	jr z, RhythmProc_CheckVoiceUpdate
	anddi8 13518, 253
	calr AccPatch_SetVoiceAndInit

RhythmProc_CheckVoiceUpdate:
	bitda 0, 13518
	jr z, RhythmProc_VoiceUpdate_Ret
	anddi8 13518, 254
	calr RhythmProc_UpdateVoiceSentinels

RhythmProc_VoiceUpdate_Ret:
	ret

RhythmProc_UpdateVoiceSentinels:
	calr AccPatch_GetCurrentSlotAddr
	ldda8 a, 13527
	and a, 0x7
	ld (xiy + 13), a
	calr AccPatch_InitAllSentinels
	ret

RhythmProc_CheckConfigBits:
	bitda 0, 13522
	jr z, RhythmProc_ConfigBit1
	anddi8 13522, 254
	calr AccPatch_GetCurrentSlotAddr
	andmi8 (xiy + 14), 0xF0
	ldda8 a, 13545
	and a, 0xF
	or (xiy + 14), a

RhythmProc_ConfigBit1:
	bitda 1, 13522
	jr z, RhythmProc_ConfigBit2
	anddi8 13522, 253
	calr AccPatch_GetCurrentSlotAddr
	andmi8 (xiy + 14), 0xEF
	bitda 4, 13546
	jr z, RhythmProc_ConfigBit2
	ormi8 (xiy + 14), 0x10

RhythmProc_ConfigBit2:
	bitda 2, 13522
	jr z, RhythmProc_ConfigBits_Done
	anddi8 13522, 251
	calr AccPatch_GetCurrentSlotAddr
	andmi8 (xiy + 14), 0x9F
	bitda 5, 13546
	jr z, RhythmProc_ConfigBit2_SetBit6
	ormi8 (xiy + 14), 0x20

RhythmProc_ConfigBit2_SetBit6:
	bitda 6, 13546
	jr z, RhythmProc_ConfigBits_Done
	ormi8 (xiy + 14), 0x40

RhythmProc_ConfigBits_Done:
	ret

AccPatch_RebuildChannelSlot:
	ldda8 a, 14235
	and a, 0x1F
	cps a, 0
	jr z, AccPatch_RebuildChannel_Done
	calr MapBitFlagsToChannelOffset
	stda8 13358, w
	ld c, w
	push c
	calr AccPatch_GetCurrentSlotAddr
	pop c
	ld_sriw3 HL, 0x03, 0xF4, 0xE4
	stda16 13373, xhl
	calr AccPatch_FreeChainEntries
	lds32 xhl, 0
	ldda8 l, 13528
	add xhl, 0xE46B8A
	ld a, (xhl)
	lds32 xhl, 0
	ldda8 l, 13527
	and l, 0x7
	inc 1, l
	mul8rr l, a
	and hl, 0x7F
	ld c, l
	ldda16 xhl, 13373
	calr AccPatch_InitSlotSentinels
	calr AccPatch_ComputeSeqPosition
	stdi8 13822, 0
	calr AccPatch_WriteRhythmInit
	bitda 0, 12931
	jr nz, AccPatch_RebuildChannel_Done
	ordi8 13517, 128

AccPatch_RebuildChannel_Done:
	ret

MapBitFlagsToChannelOffset:
	ldb w, 0x0
	bit 4, a
	jr nz, MapBitFlags_NullRet
	ldb w, 0x4
	bit 3, a
	jr nz, MapBitFlags_NullRet
	ldb w, 0x6
	bit 0, a
	jr nz, MapBitFlags_NullRet
	ldb w, 0x8
	bit 1, a
	jr nz, MapBitFlags_NullRet
	ldb w, 0xA

MapBitFlags_NullRet:
	ret

AccPatch_ComputeSeqPosition:
	lds32 xwa, 0
	ldda8 a, 12979
	ldda8 c, 13529
	mul8rr a, c
	addda8 a, 12928
	ld l, a
	ldda8 a, 12927
	add a, 0x18
	cp a, 0x60
	jr lt, AccPatch_SeqPosition_Store
	inc 1, l
	lds32 xwa, 0
	ldda8 a, 13529
	ldda8 c, 13527
	inc 1, c
	mul8rr a, c
	cp a, l
	jr nz, AccPatch_SeqPosition_Store
	ldb l, 0x0

AccPatch_SeqPosition_Store:
	lds32 xbc, 0
	ld c, l
	ldda16 xhl, 13373
	lds wa, 6
	add wa, bc
	lds32 xhl, 0
	ldda8 l, 13358
	sll l, 1
	add xhl, 0xF5F2A7
	ld xhl, (xhl)
	ld (xhl), wa
	lds32 xhl, 0
	ldda8 l, 13358
	sll l, 1
	add xhl, 0xF5F2BF
	ld xhl, (xhl)
	ldda16 xwa, 13373
	ld (xhl), wa
	ret

AccPatch_SeqBaseAddrTable:
	.byte 0x87, 0x32
	nop
	nop
	.byte 0x89, 0x32, 0x00
	nop
	.byte 0x8b, 0x32, 0x00
	nop
	.byte 0x8d, 0x32, 0x00
	nop
	.byte 0x8f, 0x32, 0x00
	nop
	.byte 0x91, 0x32
	nop
	nop
	.byte 0x97, 0x32
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x9b, 0x32, 0x00
	nop
	.byte 0x9d, 0x32, 0x00
	nop
	.byte 0x9f, 0x32, 0x00
	nop
	.byte 0xa1, 0x32
	nop
	nop

AccPatch_WriteRhythmInit:
	ldda8 l, 13358
	cps l, 0
	jr z, AccPatch_WriteRhythm_Done
	lds32 xhl, 0
	ldda8 l, 13358
	add xhl, 0xF5F310
	ld a, (xhl)
	push_sd16b 0x2E, 0x34
	calr AccPatch_WriteRhythmParams
	popb_dd16 0x2E, 0x34
	lds32 xhl, 0
	ldda8 l, 13358
	sll hl, 1
	add xhl, 0xF5F320
	ld xhl, (xhl)
	ld iy, (xhl + 4)
	ld (xhl + 6), iy

AccPatch_WriteRhythm_Done:
	ret

AccPatch_ChannelToParamTable:
	nop
	nop
	nop
	nop
	.byte 0xd7, 0x00, 0xd4
	nop
	.byte 0xd5, 0x00, 0xd6
	nop
	nop
	nop
	nop
	nop
	.zero 8
	.byte 0x94, 0x2c
	nop
	nop
	.byte 0x94, 0x2d
	nop
	nop
	.byte 0x94, 0x2e
	nop
	nop
	.byte 0x94, 0x2f
	nop
	nop

AccPatch_WriteRhythmParams:
	calr AccPatch_FetchVolumeForChannel
	push_a
	lds32 xwa, 0
	pop_a
	ldb c, 0x0

AccPatch_WriteRhythmParam_Loop:
	cps c, 6
	jr z, AccPatch_WriteRhythmParam_Done
	push c
	push xwa
	push c
	pushw wa
	call RhythmBuf_WriteByte
	inc 2, xsp
	pop c
	sll c, 1
	ld xwa, 0xF5F38E
	ld_srib3 A, 0x03, 0xE0, 0xE4
	push c
	pushw wa
	call RhythmBuf_WriteByte
	inc 2, xsp
	pop c
	inc 1, c
	ld xwa, 0xF5F38E
	ld_srib3 A, 0x03, 0xE0, 0xE4
	cps c, 7
	jr nz, AccPatch_WriteRhythmParam_Push
	ldda8 a, 13389

AccPatch_WriteRhythmParam_Push:
	pushw wa
	call RhythmBuf_WriteByte
	inc 2, xsp
	pop xwa
	pop c
	inc 1, c
	jr AccPatch_WriteRhythmParam_Loop

AccPatch_WriteRhythmParam_Done:
	ret

AccPatch_RhythmParamDefaults:
	.byte 0x01
	nop
	.byte 0x02
	ld	xwa, 1074003971
	halt
	jrl	nc, 6

AccPatch_FetchVolumeForChannel:
	push xwa
	push xhl
	push xix
	push xiy
	calr AccPatch_GetCurrentSlotAddr
	ld xix, 0x22
	cp a, 0xD7
	jr z, ToneGen_FetchSelectRestore
	ld xix, 0x2A
	cp a, 0xD4
	jr z, ToneGen_FetchSelectRestore
	ld xix, 0x32
	cp a, 0xD5
	jr z, ToneGen_FetchSelectRestore
	ld xix, 0x3A
	cp a, 0xD6
	jr z, ToneGen_FetchSelectRestore
	ldb a, 0x40
	jr AccPatch_FetchVolume_Default

ToneGen_FetchSelectRestore:
	add xix, xiy
	ld a, (xix)

AccPatch_FetchVolume_Default:
	stda8 13389, a
	pop xiy
	pop xix
	pop xhl
	pop xwa
	ret

RhythmProc_CheckStyleSwitch:
	cpdi8 36150, 184
	jr z, RhythmProc_StyleSwitch_Call
	jr RhythmProc_StyleSwitch_Ret

RhythmProc_StyleSwitch_Call:
	call AccPat_DispatchNoteChange

RhythmProc_StyleSwitch_Ret:
	ret

RhythmProc_CheckRepeatFlag:
	cpdi8 36150, 189
	jr nz, RhythmProc_RepeatFlag_Ret
	bitda 1, 13523
	jr z, RhythmProc_RepeatFlag_Ret
	anddi8 13523, 253
	ld xiy, 0x94800
	add xiy, 0x0
	add xiy, 0x10
	ld a, (xiy)
	and a, 0xFE
	bitda 0, 13523
	jr z, RhythmProc_RepeatFlag_Store
	or a, 0x1

RhythmProc_RepeatFlag_Store:
	ld (xiy), a

RhythmProc_RepeatFlag_Ret:
	ret

RhythmProc_SavePrevState:
	ldda8 a, 36150
	stda8 13605, a
	ldda8 a, 14235
	and a, 0x7F
	stda8 13584, a
	ldda8 a, 12931
	stda8 13825, a
	cpdi8 36148, 14
	jr z, RhythmProc_SavePrevState_Done
	stdi8 14235, 0

RhythmProc_SavePrevState_Done:
	ret

AccPatch_CountAvailableSlots:
	ldw wa, 0xBE
	ldw de, 0x153
	xor iy, iy

AccPatch_CountSlots_Loop:
	ld hl, de
	calr AccPatch_GetEntryAddr
	bitm 7, (xix)
	jr z, AccPatch_CountSlots_Dec
	dec 1, wa

AccPatch_CountSlots_Dec:
	dec 1, de
	cp de, 0x95
	jr z, AccPatch_CountSlots_Store
	jr AccPatch_CountSlots_Loop

AccPatch_CountSlots_Store:
	stda16 13524, xwa
	ret

AccPatch_CountSlotsAlt_Body:
	ldda32 xix, 14766
	push xix
	ld xix, 0x69800
	stda32 14766, xix
	ldw wa, 0xBE
	ldw de, 0x153
	xor iy, iy

AccPatch_CountSlotsAlt_Loop:
	ld hl, de
	calr AccPatch_ResolveSlotAddr
	bitm 7, (xix)
	jr z, AccPatch_CountSlotsAlt_Dec
	dec 1, wa

AccPatch_CountSlotsAlt_Dec:
	dec 1, de
	cp de, 0x95
	jr z, AccPatch_CountSlotsAlt_Store
	jr AccPatch_CountSlotsAlt_Loop

AccPatch_CountSlotsAlt_Store:
	stda16 13524, xwa
	pop xix
	stda32 14766, xix
	ret

AccPatch_MiscDataBlock:
	ld	xwa, 100
	.byte 0xd1, 0xd4, 0x34, 0x40
	ldw	hl, 190
	div	xwa, xhl
	cp	a, 100
	jr	c, 2
	ldb	a, 99
	stda8	14763, a
	ret

AccPatch_ProcessPartChanges:
	ldda8 a, 14235
	and a, 0x1F
	cps a, 0
	jr nz, AccPatch_PartChanges_MapLookup
	ldda8 w, 13584
	and w, 0x1F
	cps w, 0
	jr z, AccPatch_PartChanges_NoNew
	push xwa
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	call PartSelect_UpdateDisplayState
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	pop xwa

AccPatch_PartChanges_NoNew:
	jr AccPatch_PartChanges_CheckFlag

AccPatch_PartChanges_MapLookup:
	ldda8 a, 14235
	and a, 0x1F
	lds32 xhl, 0
	ld l, a
	add xhl, 0xF5F558
	ld a, (xhl)
	stda8 36154, a
	ld e, a
	ldda8 a, 14235
	ldda8 w, 13584
	and a, 0x1F
	and w, 0x1F
	cp w, a
	jr z, AccPatch_PartChanges_Update
	ld a, e
	ldb e, 0x90
	ldb d, 0x10
	ldb w, 0xFF
	call SwbtWr_QueuePostEvent

AccPatch_PartChanges_Update:
	calr AccPatch_SyncAllVoiceParams

AccPatch_PartChanges_CheckFlag:
	ldda8 a, 13584
	bit 6, a
	jr z, AccPatch_PartChanges_Done
	ldda8 w, 14235
	bit 5, w
	jr z, AccPatch_PartChanges_Done
	call AccPatch_ReadRepeatBit
	calr AccPatch_UpdateAllChains

AccPatch_PartChanges_Done:
	ret

AccPatch_ReadRepeatBit:
	ld xix, 0x94800
	add xix, 0x0
	add xix, 0x10
	ld a, (xix)
	bit 0, a
	jr nz, AccPatch_SetRepeatBitOn
	anddi8 13523, 254
	jr AccPatch_SetRepeatBit_Done

AccPatch_SetRepeatBitOn:
	ordi8 13523, 1

AccPatch_SetRepeatBit_Done:
	ret

AccPatch_PartNumberTable:
	nop
	rcf
	scf
	nop
	ccf
	nop
	nop
	nop
	zcf
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x14
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	.zero 8

AccPatch_UpdateAllChains:
	calr AccPatch_GetCurrentSlotAddr
	calr AccPatch_UpdateChain_Rhythm
	calr AccPatch_UpdateChain_Bass
	calr AccPatch_UpdateChain_Acc1
	calr AccPatch_UpdateChain_Acc2
	calr AccPatch_UpdateChain_Acc3
	ret

; Curious thing I've just observed:
; The routines below are almost identical to each other...

AccPatch_UpdateChain_Rhythm:
	push xiy
	add xiy, 0x20
	ld xix, 0xFBA4
	ld a, (xiy + 3)
	and a, 0x1
	sll a, 6
	andmi8 (xix + 4), 0xBF
	andmi8 (xix + 4), 0xF7
	or (xix + 4), a
	ld b, a
	ld a, (xiy + 1)
	and a, 0x7F
	andmi8 (xix + 1), 0x80
	or (xix + 1), a
	ld d, a
	ld a, (xiy + 256)
	andmi8 (xix + 256), 0x0
	or (xix + 256), a
	ld e, a
	sll b, 1
	stda8 13537, e
	stda8 13538, d
	orddm8 13538, b
	push d
	push e
	ld a, d
	ldb d, 0x1
	ldb w, 0x7F
	ldb e, 0x13
	call SwbtWr_QueuePostEvent
	pop e
	push e
	ld a, e
	ldb d, 0x0
	ldb w, 0xFF
	ldb e, 0x13
	call SwbtWr_QueuePostEvent
	pop e
	pop d
	ld h, d
	ld l, e
	stdi8 37111, 19
	call PartCtrl_WriteProgramChange
	ld xbc, 0xFF56
	lda_dri3 XIZ, 0x03, 0xE4, 0xEC
	ld a, (xiy + 3)
	sla a, 6
	ldb d, 0x4
	ldb w, 0x40
	ldb e, 0x13
	call SwbtWr_QueuePostEvent
	pop xiy
	ret

AccPatch_UpdateChain_Bass:
	push xiy
	add xiy, 0x18
	ld xix, 0xFBBE
	ld a, (xiy + 3)
	and a, 0x1
	sll a, 6
	andmi8 (xix + 4), 0xBF
	andmi8 (xix + 4), 0xF7
	or (xix + 4), a
	ld b, a
	ld a, (xiy + 1)
	and a, 0x7F
	andmi8 (xix + 1), 0x80
	or (xix + 1), a
	ld d, a
	ld a, (xiy + 256)
	or a, 0xF0
	andmi8 (xix + 256), 0x0
	or (xix + 256), a
	ld e, a
	sll b, 1
	stda8 13535, e
	stda8 13536, d
	orddm8 13536, b
	push d
	push e
	ld a, d
	ldb d, 0x1
	ldb w, 0x7F
	ldb e, 0x14
	call SwbtWr_QueuePostEvent
	pop e
	push e
	ld a, e
	ldb d, 0x0
	ldb w, 0xFF
	ldb e, 0x14
	call SwbtWr_QueuePostEvent
	pop e
	pop d
	ld h, d
	ld l, e
	stdi8 37111, 20
	call PartCtrl_WriteProgramChange
	ld xbc, 0xFF6A
	lda_dri3 XIZ, 0x03, 0xE4, 0xEC
	ld a, (xiy + 3)
	sla a, 6
	ldb d, 0x4
	ldb w, 0x40
	ldb e, 0x14
	call SwbtWr_QueuePostEvent
	pop xiy
	ret

AccPatch_UpdateChain_Acc1:
	push xiy
	add xiy, 0x28
	ld xix, 0xFB56
	ld a, (xiy + 3)
	and a, 0x1
	sll a, 6
	andmi8 (xix + 4), 0xBF
	andmi8 (xix + 4), 0xF7
	or (xix + 4), a
	ld b, a
	ld a, (xiy + 1)
	and a, 0x7F
	andmi8 (xix + 1), 0x80
	or (xix + 1), a
	ld d, a
	ld a, (xiy + 256)
	andmi8 (xix + 256), 0x0
	or (xix + 256), a
	ld e, a
	sll b, 1
	stda8 13539, e
	stda8 13540, d
	orddm8 13540, b
	push d
	push e
	ld a, d
	ldb d, 0x1
	ldb w, 0x7F
	ldb e, 0x10
	call SwbtWr_QueuePostEvent
	pop e
	push e
	ld a, e
	ldb d, 0x0
	ldb w, 0xFF
	ldb e, 0x10
	call SwbtWr_QueuePostEvent
	pop e
	pop d
	ld h, d
	ld l, e
	stdi8 37111, 16
	call PartCtrl_WriteProgramChange
	ld xbc, 0xFF1A
	lda_dri3 XIZ, 0x03, 0xE4, 0xEC
	ld a, (xiy + 3)
	sla a, 6
	ldb d, 0x4
	ldb w, 0x40
	ldb e, 0x10
	call SwbtWr_QueuePostEvent
	pop xiy
	ret

AccPatch_UpdateChain_Acc2:
	push xiy
	add xiy, 0x30
	ld xix, 0xFB70
	ld a, (xiy + 3)
	and a, 0x1
	sll a, 6
	andmi8 (xix + 4), 0xBF
	andmi8 (xix + 4), 0xF7
	or (xix + 4), a
	ld b, a
	ld a, (xiy + 1)
	and a, 0x7F
	andmi8 (xix + 1), 0x80
	or (xix + 1), a
	ld d, a
	ld a, (xiy + 256)
	andmi8 (xix + 256), 0x0
	or (xix + 256), a
	ld e, a
	sll b, 1
	stda8 13541, e
	stda8 13542, d
	orddm8 13542, b
	push d
	push e
	ld a, d
	ldb d, 0x1
	ldb w, 0x7F
	ldb e, 0x11
	call SwbtWr_QueuePostEvent
	pop e
	push e
	ld a, e
	ldb d, 0x0
	ldb w, 0xFF
	ldb e, 0x11
	call SwbtWr_QueuePostEvent
	pop e
	pop d
	ld h, d
	ld l, e
	stdi8 37111, 17
	call PartCtrl_WriteProgramChange
	ld xbc, 0xFF2E
	lda_dri3 XIZ, 0x03, 0xE4, 0xEC
	ld a, (xiy + 3)
	sla a, 6
	ldb d, 0x4
	ldb w, 0x40
	ldb e, 0x11
	call SwbtWr_QueuePostEvent
	pop xiy
	ret

AccPatch_UpdateChain_Acc3:
	push xiy
	add xiy, 0x38
	ld xix, 0xFB8A
	ld a, (xiy + 3)
	and a, 0x1
	sll a, 6
	andmi8 (xix + 4), 0xBF
	andmi8 (xix + 4), 0xF7
	or (xix + 4), a
	ld b, a
	ld a, (xiy + 1)
	and a, 0x7F
	andmi8 (xix + 1), 0x80
	or (xix + 1), a
	ld d, a
	ld a, (xiy + 256)
	andmi8 (xix + 256), 0x0
	or (xix + 256), a
	ld e, a
	sll b, 1
	stda8 13543, e
	stda8 13544, d
	orddm8 13544, b
	push d
	push e
	ld a, d
	ldb d, 0x1
	ldb w, 0x7F
	ldb e, 0x12
	push xiy
	call SwbtWr_QueuePostEvent
	pop xiy
	pop e
	push e
	ld a, e
	ldb d, 0x0
	ldb w, 0xFF
	ldb e, 0x12
	push xiy
	call SwbtWr_QueuePostEvent
	pop xiy
	pop e
	pop d
	ld h, d
	ld l, e
	stdi8 37111, 18
	push xiy
	call PartCtrl_WriteProgramChange
	pop xiy
	ld xbc, 0xFF42
	lda_dri3 XIZ, 0x03, 0xE4, 0xEC
	ld a, (xiy + 3)
	sla a, 6
	ldb d, 0x4
	ldb w, 0x40
	ldb e, 0x12
	call SwbtWr_QueuePostEvent
	pop xiy
	ret

AccPatch_SyncAllVoiceParams:
	calr AccPatch_GetCurrentSlotAddr
	calr AccPatch_SyncVoice_Rhythm
	calr AccPatch_SyncVoice_Acc1
	calr AccPatch_SyncVoice_Acc2
	calr AccPatch_SyncVoice_Acc3
	calr AccPatch_SyncVoice_Bass
	ret

AccPatch_SyncVoice_Rhythm:
	push xiy
	add xiy, 0x20
	ld xix, 0xFBA4
	ld w, (xix + 256)
	and w, 0xFF
	ld a, (xix + 1)
	and a, 0x7F
	bitm 6, (xix + 4)
	jr z, AccPatch_SyncRhythm_HasBank
	ldb h, 0x40
	sll h, 1
	or a, h

AccPatch_SyncRhythm_HasBank:
	ldda8 h, 13537
	ldda8 l, 13538
	cp hl, wa
	jr z, AccPatch_SyncRhythm_Done
	pushw wa
	ld (xiy + 256), w
	ld c, a
	and c, 0x7F
	ld (xiy + 1), c
	and a, 0x80
	srl a, 7
	ld (xiy + 3), a
	popw wa
	stda8 13537, w
	stda8 13538, a
	ld xix, 0x3219
	calr AccPatch_LoadVoiceParams

AccPatch_SyncRhythm_Done:
	pop xiy
	ret

AccPatch_SyncVoice_Bass:
	push xiy
	add xiy, 0x18
	ld xix, 0xFBBE
	ld w, (xix + 256)
	and w, 0xFF
	and w, 0xF
	ld a, (xix + 1)
	and a, 0x7F
	bitm 6, (xix + 4)
	jr z, AccPatch_SyncBass_HasBank
	ldb h, 0x40
	sll h, 1
	or a, h

AccPatch_SyncBass_HasBank:
	ldda8 h, 13535
	ldda8 l, 13536
	cp hl, wa
	jr z, AccPatch_SyncBass_Done
	pushw wa
	ld (xiy + 256), w
	ld c, a
	and c, 0x7F
	ld (xiy + 1), c
	and a, 0x80
	srl a, 7
	ld (xiy + 3), a
	popw wa
	stda8 13535, w
	stda8 13536, a
	ld xix, 0x3214
	calr AccPatch_LoadVoiceParams

AccPatch_SyncBass_Done:
	pop xiy
	ret

AccPatch_SyncVoice_Acc1:
	push xiy
	add xiy, 0x28
	ld xix, 0xFB56
	ld w, (xix + 256)
	and w, 0xFF
	ld a, (xix + 1)
	and a, 0x7F
	bitm 6, (xix + 4)
	jr z, AccPatch_SyncAcc1_HasBank
	ldb h, 0x40
	sll h, 1
	or a, h

AccPatch_SyncAcc1_HasBank:
	ldda8 h, 13539
	ldda8 l, 13540
	cp hl, wa
	jr z, AccPatch_SyncAcc1_Done
	pushw wa
	ld (xiy + 256), w
	ld c, a
	and c, 0x7F
	ld (xiy + 1), c
	and a, 0x80
	srl a, 7
	ld (xiy + 3), a
	popw wa
	stda8 13539, w
	stda8 13540, a
	ld xix, 0x321E
	calr AccPatch_LoadVoiceParams

AccPatch_SyncAcc1_Done:
	pop xiy
	ret

AccPatch_SyncVoice_Acc2:
	push xiy
	add xiy, 0x30
	ld xix, 0xFB70
	ld w, (xix + 256)
	and w, 0xFF
	ld a, (xix + 1)
	and a, 0x7F
	bitm 6, (xix + 4)
	jr z, AccPatch_SyncAcc2_HasBank
	ldb h, 0x40
	sll h, 1
	or a, h

AccPatch_SyncAcc2_HasBank:
	ldda8 h, 13541
	ldda8 l, 13542
	cp hl, wa
	jr z, AccPatch_SyncAcc2_Done
	pushw wa
	ld (xiy + 256), w
	ld c, a
	and c, 0x7F
	ld (xiy + 1), c
	and a, 0x80
	srl a, 7
	ld (xiy + 3), a
	popw wa
	stda8 13541, w
	stda8 13542, a
	ld xix, 0x3223
	calr AccPatch_LoadVoiceParams

AccPatch_SyncAcc2_Done:
	pop xiy
	ret

AccPatch_SyncVoice_Acc3:
	push xiy
	add xiy, 0x38
	ld xix, 0xFB8A
	ld w, (xix + 256)
	and w, 0xFF
	ld a, (xix + 1)
	and a, 0x7F
	bitm 6, (xix + 4)
	jr z, AccPatch_SyncAcc3_HasBank
	ldb h, 0x40
	sll h, 1
	or a, h

AccPatch_SyncAcc3_HasBank:
	ldda8 h, 13543
	ldda8 l, 13544
	cp hl, wa
	jr z, AccPatch_SyncAcc3_Done
	pushw wa
	ld (xiy + 256), w
	ld c, a
	and c, 0x7F
	ld (xiy + 1), c
	and a, 0x80
	srl a, 7
	ld (xiy + 3), a
	popw wa
	stda8 13543, w
	stda8 13544, a
	ld xix, 0x3228
	calr AccPatch_LoadVoiceParams

AccPatch_SyncAcc3_Done:
	pop xiy
	ret

AccPatch_LoadVoiceParams:
	ld e, (xiy + 256)
	ld d, (xiy + 1)
	ld a, (xiy + 2)
	stda8 13359, a
	ld a, (xiy + 3)
	stda8 13360, a
	ld a, (xiy + 4)
	stda8 13361, a
	calr AccPatch_CallParamLookup
	ret

AccPatch_CallParamLookup:
	push xix
	pushw de
	push_sd16b 0x2F, 0x34
	push_sd16b 0x30, 0x34
	push_sd16b 0x31, 0x34
	call RhythmPart_CopyData_Tramp
	popb_dd16 0x31, 0x34
	popb_dd16 0x30, 0x34
	popb_dd16 0x2F, 0x34
	popw de
	pop xix
	bit 7, e
	jr z, AccPatch_StoreVoiceParams
	or d, 0x10
	and e, 0x7F

AccPatch_StoreVoiceParams:
	ld (xix), e
	ld (xix + 1), d
	ldda8 a, 13359
	ld (xix + 2), a
	ldda8 a, 13360
	ld (xix + 3), a
	ldda8 a, 13361
	ld (xix + 4), a
	call AccVoice_LoadAllChannelParams
	ret

AccPatch_ComplexDataBlock:
	ldda8	a, 36148
	cp	a, 14
	jr	nz, 3
	calr	1
	ret
	ldda8	a, 49277
	cps	a, 0
	jr	nz, 51
	cpdi8	49278, 128
	jr	nc, 44
	cpdi8	49279, 0
	jr	z, 37
	ldda8	a, 36150
	cp	a, 180
	jr	nz, 28
	ld	xiy, 608256
	add	xiy, 0
	ld	a, (xiy+16)
	bit	0, a
	jr	nz, 9
	call	16144339
	stdi8	13632, 7
	ldda8	a, 49277
	cps	a, 0
	jr	nz, 28
	cpdi8	49279, 0
	jr	z, 21
	ldda8	a, 36150
	cp	a, 184
	jr	nz, 12
	call	16145212
	call	16145399
	call	16144339
	ret
	calr	48
	ret
	ld	xiy, 608256
	add	xiy, 0
	add	xiy, 0
	.byte 0x8d, 0x00, 0x21
	cp	a, 72
	jr	nz, 17
	ld	a, (xiy+1)
	cps	a, 0
	jr	nz, 10
	ld	a, (xiy+2)
	cp	a, 75
	jr	nz, 2
	jr	4
	call	16109088
	ret
	add	xiy, 0
	add	xiy, 0
	.byte 0x8d, 0x00, 0x21
	cp	a, 72
	jr	nz, 22
	ld	a, (xiy+1)
	cps	a, 0
	jr	nz, 15
	ld	a, (xiy+2)
	cp	a, 75
	jr	nz, 7
	call	16120853
	jrl	130
	cp	(xiy), 76
	jr	nz, 22
	cp	(xiy+1), 75
	jr	nz, 16
	cp	(xiy+2), 69
	jr	nz, 10
	call	16120853
	call	16120854
	jr	103
	.byte 0x8d, 0x00, 0x21
	cp	a, 71
	jr	nz, 25
	ld	a, (xiy+1)
	cps	a, 0
	jr	nz, 18
	ld	a, (xiy+2)
	cp	a, 75
	jr	nz, 10
	call	16120853
	call	16120854
	jr	70
	.byte 0x8d, 0x00, 0x21
	cp	a, 70
	jr	nz, 17
	ld	a, (xiy+1)
	cps	a, 0
	jr	nz, 10
	ld	a, (xiy+2)
	cp	a, 75
	jr	nz, 2
	jr	39
	.byte 0x8d, 0x00, 0x21
	cp	a, 77
	jr	nz, 25
	ld	a, (xiy+1)
	cp	a, 75
	jr	nz, 17
	ld	a, (xiy+2)
	cp	a, 66
	jr	nz, 2
	jr	13
	cp	a, 65
	jr	nz, 2
	jr	6
	call	16109088
	jr	6
	call	16167845
	jr	0
	ret
	ret
	ld	xiy, 608256
	add	xiy, 0
	add	xiy, 0
	ldb	a, 72
	.byte 0xbd, 0x00, 0x41
	ldb	a, 0
	ld	(xiy+1), a
	ldb	a, 75
	ld	(xiy+2), a
	ret
	calr	-3760
	calr	-3275
	calr	1
	ret
	.byte 0x9d, 0x00, 0x23
	calr	25
	ld	hl, (xiy+4)
	calr	19
	ld	hl, (xiy+6)
	calr	13
	ld	hl, (xiy+8)
	calr	7
	ld	hl, (xiy+10)
	calr	1
	ret
	push	xiy
	calr	-3736
	.byte 0xbc, 0x03, 0x02, 0xff, 0xff
	pushw	hl
	ld	l, (xiy+12)
	xor	h, h
	lds32	xwa, 0
	ld	xbc, 14969738
	.byte 0xc3, 0x07, 0xe4, 0xec, 0x21
	lds32	xbc, 0
	ld	b, (xiy+13)
	inc	1, b
	mul8rr	a, b
	popw	hl
	calr	-3772
	add	xix, 6
	ldb	l, 129
	ld	(xix), l
	dec	1, wa
	inc	1, xix
	cps	wa, 0
	jr	nz, -10
	ld	(xix), 131
	pop	xiy
	ret

AccPatch_FreeAllChains_Alt:
	ld hl, (xiy + 256)
	calr AccPatch_ClearLinkedListEntries
	ld hl, (xiy + 4)
	calr AccPatch_ClearLinkedListEntries
	ld hl, (xiy + 6)
	calr AccPatch_ClearLinkedListEntries
	ld hl, (xiy + 8)
	calr AccPatch_ClearLinkedListEntries
	ld hl, (xiy + 10)
	calr AccPatch_ClearLinkedListEntries
	ret

AccPatch_ClearLinkedListEntries:
	push xiy
	calr AccPatch_ResolveSlotAddr
	ld wa, (xix + 3)
	cp wa, 0xFFFF
	jr z, AccPatch_FreeChain_Alt_Done

AccPatch_FreeChainLoop_Alt:
	ld hl, wa
	ldw (xix + 3), 0xFFFF
	calr AccPatch_ResolveSlotAddr
	ldw (xix + 1), 0xFFFF
	andmi8 (xix), 0x7F
	incdi16 1, 13524
	ld wa, (xix + 3)
	cp wa, 0xFFFF
	jr z, AccPatch_FreeChain_Alt_Done
	jr AccPatch_FreeChainLoop_Alt

AccPatch_FreeChain_Alt_Done:
	pop xiy
	ret

AccPatch_ResolveSlotAddr:
	cp hl, 0xFFFF
	jr z, AccPatch_ResolveSlotAddr_Ret
	pushw hl
	pushw hl
	lds32 xhl, 0
	popw hl
	sll xhl, 8
	ldda32 xix, 14766
	add xix, 0x1400
	add xix, xhl
	popw hl

AccPatch_ResolveSlotAddr_Ret:
	ret

AccPatch_FillAllSlots_Alt:
	ld hl, (xiy + 256)
	calr AccPatch_FillSlotWithVoiceData
	ld hl, (xiy + 4)
	calr AccPatch_FillSlotWithVoiceData
	ld hl, (xiy + 6)
	calr AccPatch_FillSlotWithVoiceData
	ld hl, (xiy + 8)
	calr AccPatch_FillSlotWithVoiceData
	ld hl, (xiy + 10)
	calr AccPatch_FillSlotWithVoiceData
	ret

AccPatch_FillSlotWithVoiceData:
	push xiy
	pushw hl
	ld l, (xiy + 12)
	xor h, h
	lds32 xwa, 0
	ld xbc, 0xE46B8A
	ld_srib3 A, 0x07, 0xE4, 0xEC
	lds32 xbc, 0
	ld b, (xiy + 13)
	inc 1, b
	mul8rr a, b
	popw hl
	calr AccPatch_ResolveSlotAddr
	add xix, 0x6
	ldb l, 0x81

AccPatch_FillSlot_Alt_Loop:
	ld (xix), l
	dec 1, wa
	inc 1, xix
	cps wa, 0
	jr nz, AccPatch_FillSlot_Alt_Loop
	ld (xix), 0x83
	pop xiy
	ret

AccPatch_ScanSequenceToEnd:
	calr AccPatch_InitSlotPointer_Alt

AccPatch_ScanSeq_Loop:
	calr AccPatch_SeqReadByte_Alt
	cp a, 0x83
	jr z, AccPatch_ScanSeq_StorePosAndRet
	calr AccPatch_SeqAdvance_Alt
	bitda 0, 13846
	jr nz, AccPatch_ScanSeq_StorePosAndRet
	jr AccPatch_ScanSeq_Loop

AccPatch_ScanSeq_StorePosAndRet:
	ldda16 xwa, 13842
	stda16 13830, xwa
	ldda16 xwa, 13844
	stda16 13832, xwa
	ret

AccPatch_SeqReadByte_Alt:
	push xix
	ldda16 xhl, 13842
	calr AccPatch_ResolveSlotAddr
	ldda16 xhl, 13844
	ld_srib3 A, 0x07, 0xF0, 0xEC
	pop xix
	ret

AccPatch_SeqAdvance_Alt:
	ldda16 xwa, 13844
	cp wa, 0xFE
	jr nz, AccPatch_SeqAdvance_Inc
	ldda16 xhl, 13842
	calr AccPatch_ResolveSlotAddr
	ld wa, (xix + 3)
	stda16 13842, xwa
	cp wa, 0xFFFF
	jr nz, AccPatch_SeqAdvance_CheckLimit
	ordi8 13846, 1

AccPatch_SeqAdvance_CheckLimit:
	cp wa, 0x154
	jr lt, AccPatch_SeqAdvance_ResetBase
	ordi8 13846, 1

AccPatch_SeqAdvance_ResetBase:
	lds wa, 6
	jr AccPatch_SeqAdvance_Store

AccPatch_SeqAdvance_Inc:
	inc 1, wa

AccPatch_SeqAdvance_Store:
	stda16 13844, xwa
	ret

AccPatch_InitSlotPointer_Alt:
	xor xhl, xhl
	ldda8 l, 14764
	cp l, 0x1E
	jr c, AccPatch_InitSlotAlt_Valid
	xor l, l

AccPatch_InitSlotAlt_Valid:
	mul hl, 0x60
	add xhl, 0x60
	ldda32 xiy, 14766
	add xiy, xhl
	ldda8 a, 14235
	calr MapBitFlagsToChannelOffset
	ld_sriw3 HL, 0x03, 0xF4, 0xE1
	stda16 13842, xhl
	stdi16 13844, 6
	ret

AccPatch_SeqDispatch_Entry:
	jr AccPatch_SeqDispatch_Main
	adc wa, (xwa)
	adc wa, (xwa)
	adc wa, (xwa)
	adc wa, (xwa)
	adc wa, (xwa)
	adc wa, (xwa)
	jrl AccPatch_SeqAdvanceStep

AccPatch_SeqReadByte:
	push xix
	ldda16 xhl, 13842
	calr AccPatch_GetEntryAddr
	ldda16 xhl, 13844
	ld_srib3 A, 0x07, 0xF0, 0xEC
	pop xix
	ret

AccPatch_SeqDispatch_Padding:
	.byte 0x00, 0x00

AccPatch_AdvanceSeqIndex:
	ldda16 xwa, 13844
	cp wa, 0xFE
	jr nz, AccPatch_AdvSeq_Inc
	ldda16 xhl, 13842
	calr AccPatch_GetEntryAddr
	ld wa, (xix + 3)
	stda16 13842, xwa
	cp wa, 0xFFFF
	jr nz, AccPatch_AdvSeq_CheckLimit
	ordi8 13846, 1

AccPatch_AdvSeq_CheckLimit:
	cp wa, 0x154
	jr lt, AccPatch_AdvSeq_ResetBase
	ordi8 13846, 1

AccPatch_AdvSeq_ResetBase:
	lds wa, 6
	jr AccPatch_AdvSeq_Store

AccPatch_AdvSeq_Inc:
	inc 1, wa

AccPatch_AdvSeq_Store:
	stda16 13844, xwa
	ret

AccPatch_AdvSeq_Padding:
	.byte 0x00, 0x00

AccPatch_SeqDispatch_Main:
	ldda8 a, 14235
	cpda8 a, 13822
	jr z, AccPatch_SeqDispatch_CheckEmpty
	calr AccPatch_ScanToSequenceStart
	calr AccPatch_InitAndLoadSequence

AccPatch_SeqDispatch_CheckEmpty:
	ldda8 a, 14235
	and a, 0x1F
	cps a, 0
	jr nz, AccPatch_SeqDispatch_CheckPlaying
	jrl AccPatch_SyncStateAndReturn

AccPatch_SeqDispatch_CheckPlaying:
	bitda 0, 12931
	jr nz, AccPatch_SeqDispatch_CheckStarted
	call TempoRingBuf_ReInitAndRet
	jrl AccPatch_SyncStateAndReturn

AccPatch_SeqDispatch_CheckStarted:
	bitda 0, 13825
	jr nz, AccPatch_SeqDispatch_ProcessFlags
	calr AccPatch_ResetSeqCounters
	calr AccPatch_InitCurrentSlotPointer
	ldda16 xwa, 13842
	stda16 13826, xwa
	ldda16 xwa, 13844
	stda16 13828, xwa

AccPatch_SeqDispatch_ProcessFlags:
	calr AccPatch_ReadModeFlags
	ldda8 a, 13519
	and a, 0xC
	cps a, 0
	jr nz, AccPatch_SeqDispatch_ModeChange
	ldda8 a, 13820
	and a, 0xC
	cps a, 0
	jr z, AccPatch_SeqDispatch_RunNotes

AccPatch_SeqDispatch_ModeChange:
	calr AccPatch_UpdateSequenceState
	jr AccPatch_SyncStateAndReturn

AccPatch_SeqDispatch_RunNotes:
	call AccPatch_CheckEmpty
	cps wa, 0
	jr z, AccPatch_SyncStateAndReturn
	stdi16 13834, 0
	stdi16 13838, 0
	stdi8 13823, 0
	calr AccPatch_EventDispatch_Nop
	cpdi16 13834, 0
	jr z, AccPatch_SeqDispatch_CheckQueued
	ldda16 xwa, 13826
	stda16 14078, xwa
	ldda16 xwa, 13828
	stda16 14080, xwa
	calr AccPatch_InitSlotAndCopyData
	calr AccPatch_AdvancePlayPos
	calr AccPatch_AdvanceAllSteps
	stdi16 13834, 0

AccPatch_SeqDispatch_CheckQueued:
	cpdi16 13838, 0
	jr z, AccPatch_SyncStateAndReturn
	calr AccPatch_DispatchQueuedNotes

AccPatch_SyncStateAndReturn:
	ldda8 a, 14235
	stda8 13822, a
	ret

AccPatch_SeqDispatch_MiscData:
	nop
	nop
	.byte 0xc1, 0xcf, 0x34, 0x3e, 0x08
	ret
	.byte 0xc1, 0xcf, 0x34, 0x3c, 0xf7
	call	16121834
	ret

AccPatch_ReadModeFlags:
	ldda8 a, 13519
	and a, 0xF3
	stda8 13519, a
	cpdi8 36152, 181
	jr z, AccPatch_ReadModeFlags_Active
	jr AccPatch_SetFlagExit

AccPatch_ReadModeFlags_Active:
	ld32_24 xwa, 0x02749a
	orda32_24 xwa, 160926
	stda32 4560, xwa
	ld32_24 xwa, 0x02749e
	stda32 14816, xwa
	ldda32 xwa, 4560
	and xwa, 0x200
	cp xwa, 0x0
	jr z, AccPatch_ReadModeFlags_Check400
	ldda32 xwa, 14816
	and xwa, 0x200
	cp xwa, 0x0
	jr nz, AccPatch_ReadModeFlags_Check400
	ldda8 a, 13519
	or a, 0x4
	stda8 13519, a

AccPatch_ReadModeFlags_Check400:
	ldda32 xwa, 4560
	and xwa, 0x400
	cp xwa, 0x0
	jr z, AccPatch_SetFlagExit
	ldda32 xwa, 14816
	and xwa, 0x400
	cp xwa, 0x0
	jr nz, AccPatch_SetFlagExit
	ldda8 a, 13519
	or a, 0x8
	stda8 13519, a

AccPatch_SetFlagExit:
	ret

AccPatch_ScanSeq_PaddingByte:
	.byte 0x0e

AccPatch_ScanToSequenceStart:
	calr AccPatch_InitCurrentSlotPointer

AccPatch_ScanSeq_ReadLoop:
	calr AccPatch_SeqReadByte
	cp a, 0x83
	jr z, AccPatch_ScanSeq_StorePosition
	calr AccPatch_AdvanceSeqIndex
	bitda 0, 13846
	jr nz, AccPatch_ScanSeq_StorePosition
	jr AccPatch_ScanSeq_ReadLoop

AccPatch_ScanSeq_StorePosition:
	ldda16 xwa, 13842
	stda16 13830, xwa
	ldda16 xwa, 13844
	stda16 13832, xwa
	ret

AccPatch_ScanSeq_PaddingWord:
	.byte 0x00, 0x00

AccPatch_InitAndLoadSequence:
	ld xhl, 0x361A
	ldw bc, 0x8

AccPatch_InitSeq_ClearLoop:
	ldw (xhl), 0x0
	add hl, 0x6
	djnz xbc, AccPatch_InitSeq_ClearLoop
	ei 6
	bitda 0, 13898
	jr nz, AccPatch_InitSeq_LoadTempo
	call TempoRingBuf_ReInitAndRet

AccPatch_InitSeq_LoadTempo:
	ldda8 a, 1077
	ldda8 c, 1046
	ei 0
	anddi8 13898, 254
	ldda8 b, 13529
	mul8rr a, b
	add c, a
	xor b, b
	pushw bc
	calr AccPatch_InitCurrentSlotPointer
	popw bc
	cps bc, 0
	jr z, AccPatch_InitSeq_AdvDone

AccPatch_InitSeq_AdvLoop:
	pushw bc
	calr AccPatch_ScanToSequenceEnd
	popw bc
	djnz xbc, AccPatch_InitSeq_AdvLoop

AccPatch_InitSeq_AdvDone:
	ret

AccPatch_InitSeq_Padding:
	.byte 0x00, 0x00

AccPatch_ResetSeqCounters:
	ld xhl, 0x361A
	ldw bc, 0x8

AccPatch_ResetSeqCounters_Loop:
	ldw (xhl), 0x0
	add hl, 0x6
	djnz xbc, AccPatch_ResetSeqCounters_Loop
	ei 6
	ldda8 a, 1077
	ldda8 c, 1046
	ei 0
	anddi8 13898, 254
	ldda8 b, 13529
	mul8rr a, b
	add c, a
	xor b, b
	pushw bc
	call AccPatch_InitCurrentSlotPointer
	popw bc
	cps bc, 0
	jr z, AccPatch_ResetSeqCounters_Done

AccPatch_ResetSeqCounters_AdvLoop:
	pushw bc
	calr AccPatch_ScanToSequenceEnd
	popw bc
	djnz xbc, AccPatch_ResetSeqCounters_AdvLoop

AccPatch_ResetSeqCounters_Done:
	ret

__pad_F60077:
	.byte 0x00, 0x00

AccPatch_ScanToSequenceEnd:
	calr AccPatch_SeqReadByte
	cp a, 0x81
	jr z, AccPatch_ScanSeqEnd_HandleMarker
	calr AccPatch_AdvanceSeqIndex
	bitda 0, 13846
	jr nz, AccPatch_ScanDone
	jr AccPatch_ScanToSequenceEnd

AccPatch_ScanSeqEnd_HandleMarker:
	calr AccPatch_AdvanceSeqIndex
	bitda 0, 13846
	jr nz, AccPatch_ScanDone
	calr AccPatch_SeqReadByte
	cp a, 0x83
	jr nz, AccPatch_ScanDone
	calr AccPatch_MarkAllSlotsActive

AccPatch_ScanDone:
	ret

__pad_F600A1:
	.byte 0x00, 0x00

AccPatch_MarkAllSlotsActive:
	ld xhl, 0x361A

AccPatch_MarkSlots_Loop:
	bitm 7, (xhl)
	jr z, AccPatch_MarkSlots_Next
	ormi8 (xhl + 1), 0x80

AccPatch_MarkSlots_Next:
	add xhl, 0x6
	cp xhl, 0x364A
	jr c, AccPatch_MarkSlots_Loop
	calr AccPatch_InitCurrentSlotPointer
	ret

AccPatch_UpdateSequenceState:
	ldda16 xwa, 13842
	stda16 13786, xwa
	ldda16 xwa, 13844
	stda16 13788, xwa
	ei 6
	ldda8 a, 1077
	stda8 13817, a
	ldda16 xwa, 1045
	stda16 14086, xwa
	ei 0
	ldda8 a, 13519
	ldda8 w, 13820
	bit 2, a
	jr nz, AccPatch_UpdateSeqState_CheckXor
	bit 2, w
	jr nz, AccPatch_UpdateSeqState_CheckXor
	jr AccPatch_UpdateSeqState_CheckBit4

AccPatch_UpdateSeqState_CheckXor:
	ld c, a
	xor c, w
	and a, c
	cps a, 0
	jr z, AccPatch_UpdateSeqState_AndCheck
	calr AccPatch_SeekToPosition
	ordi8 13821, 1
	jr AccPatch_LoadNextSequencePointers

AccPatch_UpdateSeqState_AndCheck:
	and w, c
	cps w, 0
	jr z, AccPatch_UpdateSeqState_ResumeSeq
	calr AccPatch_InitAndLoadSequence
	jr AccPatch_UpdateSeqState_CheckBit3

AccPatch_UpdateSeqState_ResumeSeq:
	calr AccPatch_ResumeSequencePlayback
	jr AccPatch_LoadNextSequencePointers

AccPatch_UpdateSeqState_CheckBit4:
	bitda 4, 14235
	jr z, AccPatch_LoadNextSequencePointers
	ldda8 a, 13656
	stda8 13819, a
	bitda 3, 13519
	jr z, AccPatch_UpdateSeqState_ClearBit7
	bitda 7, 13656
	jr nz, AccPatch_UpdateSeqState_ScanNoteOff
	calr AccPatch_ClearAndScanForNote
	jr AccPatch_UpdateSeqState_AfterScan

AccPatch_UpdateSeqState_ScanNoteOff:
	calr AccPatch_ScanForNoteOff

AccPatch_UpdateSeqState_AfterScan:
	jr AccPatch_UpdateSeqState_CompareBits

AccPatch_UpdateSeqState_ClearBit7:
	anddi8 13656, 127

AccPatch_UpdateSeqState_CompareBits:
	ldda8 a, 13656
	ldda8 c, 13819
	bit 7, a
	jr z, AccPatch_UpdateSeqState_CheckC7
	bit 7, c
	jr nz, AccPatch_UpdateSeqState_BothSet
	calr AccPatch_SeekToPosition
	jr AccPatch_LoadNextSequencePointers

AccPatch_UpdateSeqState_CheckC7:
	bit 7, c
	jr z, AccPatch_LoadNextSequencePointers
	calr AccPatch_InitAndLoadSequence
	jr AccPatch_UpdateSeqState_CheckBit3

AccPatch_UpdateSeqState_BothSet:
	calr AccPatch_PrepareAndProcessEvents

AccPatch_LoadNextSequencePointers:
	ldda16 xwa, 13786
	stda16 13842, xwa
	ldda16 xwa, 13788
	stda16 13844, xwa

AccPatch_UpdateSeqState_CheckBit3:
	bitda 3, 13519
	jr nz, AccPatch_UpdateSeqState_StoreFlags
	bitda 3, 13820
	jr z, AccPatch_UpdateSeqState_StoreFlags
	calr AccPatch_InitAndLoadSequence

AccPatch_UpdateSeqState_StoreFlags:
	ldda8 a, 13519
	stda8 13820, a
	anddi8 13819, 253
	bitda 0, 13819
	jr z, AccPatch_UpdateSeqState_Return
	ordi8 13819, 2

AccPatch_UpdateSeqState_Return:
	ret

__pad_F601A3:
	.byte 0x00, 0x00

AccPatch_ClearAndScanForNote:
	anddi8 13656, 127

AccPatch_ScanForActiveNote:
	call AccPatch_CheckEmpty
	cps wa, 0
	jr z, AccPatch_ScanNote_Done
	lds bc, 1
	calr TempoRingBuf_SkipBytes
	ld w, a
	and w, 0xF0
	cp w, 0x90
	jr nz, AccPatch_ScanNote_Continue
	lds bc, 2
	calr TempoRingBuf_SkipBytes
	ld l, a
	push l
	lds bc, 1
	calr TempoRingBuf_SkipBytes
	pop l
	cps a, 0
	jr z, AccPatch_ScanNote_Continue
	or l, 0x80
	stda8 13656, l
	call TempoRingBuf_ReInitAndRet

AccPatch_ScanNote_Continue:
	jr AccPatch_ScanForActiveNote

AccPatch_ScanNote_Done:
	ret

TempoRingBuf_SkipBytes:
	cps bc, 0
	jr z, TempoRingBuf_SkipBytes_Done
	pushw bc
	call TempoRingBuf_ReadByteToA
	popw bc
	dec 1, bc
	jr TempoRingBuf_SkipBytes

TempoRingBuf_SkipBytes_Done:
	ret

AccPatch_ScanForNoteOff:
	call AccPatch_CheckEmpty
	cps wa, 0
	jr z, AccPatch_ScanForNoteOff_Done
	lds bc, 1
	calr TempoRingBuf_SkipBytes
	ld w, a
	and w, 0xF0
	cp w, 0x90
	jr nz, AccPatch_ErrorExit
	lds bc, 2
	calr TempoRingBuf_SkipBytes
	ld l, a
	ldda8 h, 13656
	and h, 0x7F
	cp h, l
	jr nz, AccPatch_ErrorExit
	lds bc, 1
	calr TempoRingBuf_SkipBytes
	cps a, 0
	jr nz, AccPatch_ErrorExit
	anddi8 13656, 127
	call TempoRingBuf_ReInitAndRet

AccPatch_ErrorExit:
	jr AccPatch_ScanForNoteOff

AccPatch_ScanForNoteOff_Done:
	ret

AccPatch_SeekToPosition:
	calr AccPatch_SeekForwardSteps
	ldda8 a, 14086
	stda8 14072, a
	calr AccPatch_ParseSequenceHeader
	ldda16 xwa, 13842
	stda16 13790, xwa
	ldda16 xwa, 13844
	stda16 13792, xwa
	ret

AccPatch_SeekForwardSteps:
	ldda8 a, 13817
	ldda8 c, 14087
	ldda8 b, 13529
	mul8rr a, b
	add c, a
	xor b, b
	pushw bc
	calr AccPatch_InitCurrentSlotPointer
	popw bc
	cps bc, 0
	jr z, AccPatch_SeekFwd_Done

AccPatch_SeekFwd_AdvLoop:
	pushw bc
	calr AccPatch_ScanToSequenceEnd
	popw bc
	djnz xbc, AccPatch_SeekFwd_AdvLoop

AccPatch_SeekFwd_Done:
	ret

__pad_F60273:
	.byte 0x00, 0x00

AccPatch_ParseSequenceHeader:
	ldda16 xwa, 13842
	stda16 14074, xwa
	ldda16 xwa, 13844
	stda16 14076, xwa
	calr AccPatch_SeqReadByte
	cp a, 0x81
	jr z, AccPatch_ParseHdr_RestorePos
	cp a, 0x83
	jr nz, AccPatch_ParseHdr_AdvanceAndCompare
	ordi8 13846, 2
	jr AccPatch_ParseHdr_Return

AccPatch_ParseHdr_AdvanceAndCompare:
	calr AccPatch_AdvanceSeqIndex
	calr AccPatch_SeqReadByte
	cpda8 a, 14072
	jr ugt, AccPatch_ParseHdr_RestorePos

AccPatch_ParseHdr_AdvanceAndRead:
	calr AccPatch_AdvanceSeqIndex
	calr AccPatch_SeqReadByte
	bitda 0, 13846
	jr z, AccPatch_ParseHdr_CheckBit7
	jr AccPatch_ParseHdr_Return

AccPatch_ParseHdr_CheckBit7:
	bit 7, a
	jr z, AccPatch_ParseHdr_AdvanceAndRead
	jr AccPatch_ParseSequenceHeader

AccPatch_ParseHdr_RestorePos:
	ldda16 xwa, 14074
	stda16 13842, xwa
	ldda16 xwa, 14076
	stda16 13844, xwa

AccPatch_ParseHdr_Return:
	ret

__pad_F602CB:
	.byte 0x00, 0x00

AccPatch_ResumeSequencePlayback:
	anddi8 13821, 254
	calr AccPatch_PrepareSequencePlayback
	ldda16 xwa, 13790
	stda16 13842, xwa
	ldda16 xwa, 13792
	stda16 13844, xwa
	stdi16 13834, 0

AccPatch_ResumeSeq_ComparePos:
	ldda16 xwa, 13842
	cpda16 xwa, 13794
	jr nz, AccPatch_ResumeSeq_ReadByte
	ldda16 xwa, 13844
	cpda16 xwa, 13796
	jr nz, AccPatch_ResumeSeq_ReadByte
	calr AccPatch_CheckSequenceChanged
	jrl AccPatch_ResumeSeq_Return

AccPatch_ResumeSeq_ReadByte:
	calr AccPatch_SeqReadByte
	cp a, 0x90
	jr z, AccPatch_ResumeSeq_Skip6
	cp a, 0x91
	jr z, AccPatch_ResumeSeq_Skip8
	cp a, 0x92
	jr z, AccPatch_ResumeSeq_Skip6
	cp a, 0x81
	jr z, AccPatch_ResumeSeq_HandleMarker
	and a, 0xF0
	cp a, 0xD0
	jr z, AccPatch_ResumeSeq_Skip3
	calr AccPatch_ProcessSeqEvt_RetNop
	jr AccPatch_ResumeSeq_Return

AccPatch_ResumeSeq_Skip6:
	lds bc, 6
	jr AccPatch_ResumeSeq_AddAndAdvance

AccPatch_ResumeSeq_Skip8:
	ldw bc, 0x8
	jr AccPatch_ResumeSeq_AddAndAdvance

AccPatch_ResumeSeq_Skip3:
	lds bc, 3

AccPatch_ResumeSeq_AddAndAdvance:
	adddm16 13834, xbc

AccPatch_ResumeSeq_AdvLoop:
	calr AccPatch_AdvanceSeqIndex
	djnz xbc, AccPatch_ResumeSeq_AdvLoop
	jr AccPatch_ResumeSeq_ComparePos

AccPatch_ResumeSeq_HandleMarker:
	calr AccPatch_CheckSequenceChanged
	calr AccPatch_AdvanceSeqIndex
	ldda16 xwa, 13842
	stda16 13790, xwa
	ldda16 xwa, 13844
	stda16 13792, xwa
	calr AccPatch_SeqReadByte
	cp a, 0x83
	jr z, AccPatch_ResumeSeq_InitSlot
	cpdi16 13834, 0
	jr z, AccPatch_ResumeSeq_LoopBack
	calr AccPatch_PrepareSequencePlayback
	stdi16 13834, 0

AccPatch_ResumeSeq_LoopBack:
	jrl AccPatch_ResumeSeq_ComparePos

AccPatch_ResumeSeq_InitSlot:
	calr AccPatch_InitCurrentSlotPointer
	ldda16 xwa, 13842
	stda16 13790, xwa
	ldda16 xwa, 13844
	stda16 13792, xwa

AccPatch_ResumeSeq_Return:
	ret

__pad_F60386:
	.byte 0x00, 0x00

AccPatch_PrepareSequencePlayback:
	calr AccPatch_SeekForwardSteps
	ldda8 a, 14086
	stda8 14072, a
	calr AccPatch_ParseSequenceHeader
	ldda16 xwa, 13842
	stda16 13794, xwa
	ldda16 xwa, 13844
	stda16 13796, xwa
	ret

AccPatch_CheckSequenceChanged:
	cpdi16 13834, 0
	jr z, AccPatch_CheckChanged_Return
	ldda16 xwa, 13790
	stda16 13914, xwa
	ldda16 xwa, 13792
	stda16 13920, xwa
	ldda16 xwa, 13842
	stda16 13912, xwa
	ldda16 xwa, 13844
	stda16 13918, xwa
	ldda16 xwa, 13914
	cpda16 xwa, 13912
	jr nz, AccPatch_CheckChanged_DoCopy
	ldda16 xwa, 13920
	cpda16 xwa, 13918
	jr nz, AccPatch_CheckChanged_DoCopy
	jr AccPatch_CheckChanged_Return

AccPatch_CheckChanged_DoCopy:
	calr AccPatch_CopySequenceEntry
	calr AccPatch_UpdateEntryFromTable
	ldda16 xwa, 13790
	stda16 13842, xwa
	ldda16 xwa, 13792
	stda16 13844, xwa

AccPatch_CheckChanged_Return:
	ret

__pad_F603FC:
	.byte 0x00, 0x00

AccPatch_CopySequenceEntry:
	ldda16 xde, 13830
	ldda16 xwa, 13832
	stda16 13922, xwa
	ldda16 xhl, 13912
	calr AccPatch_GetEntryAddr
	stda32 13904, xix
	ldda16 xhl, 13914
	calr AccPatch_GetEntryAddr
	stda32 13900, xix
	calr AccPatch_SetupBlockCopyDispatch
	dec 1, ix
	stda16 14084, xix
	ldda16 xwa, 13914
	cpda16 xwa, 13830
	jr z, AccPatch_CopyEntry_Store
	incdi16 1, 13524
	ldda16 xhl, 13914
	calr AccPatch_GetEntryAddr
	ld wa, (xix + 3)
	ldw (xix + 3), 0xFFFF
	ld hl, wa
	calr AccPatch_GetEntryAddr
	andmi8 (xix), 0x7F
	ldw (xix + 1), 0xFFFF

AccPatch_CopyEntry_Store:
	ldda16 xwa, 13914
	stda16 13830, xwa
	ldda16 xwa, 14084
	stda16 13832, xwa
	ret

__pad_F60464:
	.byte 0x00, 0x00

AccPatch_UpdateEntryFromTable:
	calr AccPatch_LoadTablePointers
	ld de, (xix)
	ld hl, (xiy)
	pushw de
	pushw hl
	calr AccPatch_GetEntryAddr
	popw hl
	popw de
	cpda16 xhl, 13790
	jr z, AccPatch_UpdateEntry_CheckDE
	cpw (xix + 1), 0xFFFF
	jr z, AccPatch_NullRet
	calr AccPatch_AdjustTableEntryPos
	jr AccPatch_NullRet

AccPatch_UpdateEntry_CheckDE:
	cpda16 xde, 13792
	jr nc, AccPatch_UpdateEntry_AdjustOffset
	jr AccPatch_NullRet

AccPatch_UpdateEntry_AdjustOffset:
	subda16 xde, 13834
	cps de, 6
	jr z, AccPatch_UpdateEntry_StoreDirect
	jr ugt, AccPatch_UpdateEntry_StoreDirect
	lds hl, 6
	sub hl, de
	ld de, hl
	pushw de
	ld wa, (xix + 1)
	pushw wa
	calr AccPatch_LoadTablePointers
	popw wa
	ld (xiy), wa
	popw de
	ldw hl, 0xFF
	sub hl, de
	ld (xix), hl
	jr AccPatch_NullRet

AccPatch_UpdateEntry_StoreDirect:
	pushw de
	calr AccPatch_LoadTablePointers
	popw de
	ld (xix), de

AccPatch_NullRet:
	ret

__pad_F604BB:
	.byte 0x00, 0x00

AccPatch_LoadTablePointers:
	push xbc
	lds32 xbc, 0
	ldda8 c, 14235
	sll bc, 2
	push xbc
	add xbc, 0xF60CA5
	ld xix, xbc
	ld xix, (xix)
	pop xbc
	ld xiy, 0xF60C61
	add xiy, xbc
	ld xiy, (xiy)
	pop xbc
	ret

AccPatch_AdjustTableEntryPos:
	calr AccPatch_LoadTablePointers
	ld de, (xix)
	ld wa, (xiy)
	sub de, 0x6
	cpda16 xde, 13834
	jr c, AccPatch_AdjustEntry_Overflow
	subda16 xde, 13834
	add de, 0x6
	ld (xix), de
	jr AccPatch_AdjustEntry_Return

AccPatch_AdjustEntry_Overflow:
	ldda16 xhl, 13834
	sub hl, de
	ldw de, 0xFF
	sub de, hl
	ld (xix), de
	ld hl, wa
	push xiy
	calr AccPatch_GetEntryAddr
	pop xiy
	ld hl, (xix + 1)
	ld (xiy), hl

AccPatch_AdjustEntry_Return:
	ret

AccPatch_PrepareAndProcessEvents:
	calr AccPatch_PrepareSequencePlayback
	ldda16 xwa, 13790
	stda16 13842, xwa
	ldda16 xwa, 13792
	stda16 13844, xwa

AccPatch_ProcessSequenceEvents:
	ldda16 xwa, 13842
	cpda16 xwa, 13794
	jr nz, AccPatch_ProcessSeqEvt_SavePos
	ldda16 xwa, 13844
	cpda16 xwa, 13796
	jr nz, AccPatch_ProcessSeqEvt_SavePos
	jrl AccPatch_ProcessSeqEvt_StorePos

AccPatch_ProcessSeqEvt_SavePos:
	ldda16 xwa, 13842
	stda16 14074, xwa
	ldda16 xwa, 13844
	stda16 14076, xwa
	calr AccPatch_SeqReadByte
	stda8 14073, a
	cp a, 0x90
	jr z, AccPatch_SkipNoteOff
	cp a, 0x91
	jr z, AccPatch_SkipNoteOff
	cp a, 0x92
	jr z, AccPatch_SkipNoteOff
	cp a, 0x81
	jr z, AccPatch_ProcessSeqEvt_HandleEnd
	and a, 0xF0
	cp a, 0xD0
	jr z, AccPatch_ProcessSeqEvt_SkipD
	jrl AccPatch_ProcessSeqEvt_RetNop

AccPatch_SkipNoteOff:
	calr AccPatch_AdvanceSeqIndex
	calr AccPatch_AdvanceSeqIndex
	calr AccPatch_SeqReadByte
	stda8 13818, a
	lds bc, 6
	cpdi8 14073, 145
	jr z, AccPatch_ProcessSeqEvt_AdvLoop
	lds bc, 4

AccPatch_ProcessSeqEvt_AdvLoop:
	calr AccPatch_AdvanceSeqIndex
	djnz xbc, AccPatch_ProcessSeqEvt_AdvLoop
	ldda8 a, 13818
	ldda8 b, 13656
	and b, 0x7F
	cp a, b
	jr z, AccPatch_ProcessSeqEvt_SetSize
	cp a, 0x5D
	jr nz, AccPatch_ProcessSeqEvt_LoopBack
	cp b, 0x30
	jr nz, AccPatch_ProcessSeqEvt_LoopBack
	jr AccPatch_ProcessSeqEvt_SetSize

AccPatch_ProcessSeqEvt_LoopBack:
	jrl AccPatch_ProcessSequenceEvents

AccPatch_ProcessSeqEvt_HandleEnd:
	calr AccPatch_AdvanceSeqIndex
	calr AccPatch_SeqReadByte
	cp a, 0x83
	jr z, AccPatch_ProcessSeqEvt_InitSlot
	jrl AccPatch_ProcessSequenceEvents

AccPatch_ProcessSeqEvt_SkipD:
	lds bc, 3

AccPatch_ProcessSeqEvt_SkipDLoop:
	calr AccPatch_AdvanceSeqIndex
	djnz xbc, AccPatch_ProcessSeqEvt_SkipDLoop
	jrl AccPatch_ProcessSequenceEvents

AccPatch_ProcessSeqEvt_SetSize:
	stdi16 13834, 8
	cpdi8 14073, 145
	jr z, AccPatch_ProcessSeqEvt_StoreAndPrep
	stdi16 13834, 6

AccPatch_ProcessSeqEvt_StoreAndPrep:
	ldda16 xwa, 14074
	stda16 13790, xwa
	ldda16 xwa, 14076
	stda16 13792, xwa
	calr AccPatch_CheckSequenceChanged
	stdi16 13834, 0
	calr AccPatch_PrepareSequencePlayback
	jrl AccPatch_ProcessSequenceEvents

AccPatch_ProcessSeqEvt_InitSlot:
	calr AccPatch_InitCurrentSlotPointer

AccPatch_ProcessSeqEvt_StorePos:
	ldda16 xwa, 13842
	stda16 13790, xwa
	ldda16 xwa, 13844
	stda16 13792, xwa
	ret

AccPatch_ProcessSeqEvt_RetNop:
	ret

AccPatch_EventDispatch_Nop:
	nop

AccPatch_EventDispatchLoop:
	call AccPatch_CheckEmpty
	cps wa, 0
	jr nz, AccPatch_EventDispatch_ReadCmd
	jrl AccPatch_EventDispatch_Done

AccPatch_EventDispatch_ReadCmd:
	call TempoRingBuf_PeekByte
	cp a, 0x81
	jr z, AccPatch_EventDispatch_EndMarker
	ldb w, 0xF0
	and w, a
	cp w, 0x90
	jr z, AccPatch_EventDispatch_NoteOn
	cp a, 0xD1
	jr nz, AccPatch_EventDispatch_CheckD2
	jr AccPatch_ProcessMarkerCommand

AccPatch_EventDispatch_CheckD2:
	cp a, 0xD2
	jr nz, AccPatch_EventDispatch_CheckD4
	jr AccPatch_ProcessMarkerCommand

AccPatch_EventDispatch_CheckD4:
	cp a, 0xD4
	jr nz, AccPatch_EventDispatch_CheckD3
	jr AccPatch_ProcessMarkerCommand

AccPatch_EventDispatch_CheckD3:
	cp a, 0xD3
	jr nz, AccPatch_EventDispatch_CheckD5
	jr AccPatch_ProcessMarkerCommand

AccPatch_EventDispatch_CheckD5:
	cp a, 0xD5
	jr z, AccPatch_ProcessMarkerCommand
	calr AccPatch_SkipToMarker
	jr AccPatch_ContinueProcessing

AccPatch_EventDispatch_NoteOn:
	lds bc, 5
	calr AccPatch_ReadRingBufBytes
	cpdi8 14061, 0
	jr nz, AccPatch_EventDispatch_NoteResolve
	calr AccPatch_TransposeAndCopyNote
	jr AccPatch_ContinueProcessing

AccPatch_EventDispatch_NoteResolve:
	calr AccPatch_ParseAndResolve
	calr AccPatch_CopyNoteStepsToSlots
	jr AccPatch_ContinueProcessing

AccPatch_EventDispatch_EndMarker:
	call TempoRingBuf_ReadByteToA
	calr AccPatch_UpdatePlayback
	bitda 1, 13898
	jr nz, AccPatch_EventDispatch_AdvSlots
	calr AccPatch_ScanToSequenceEnd

AccPatch_EventDispatch_AdvSlots:
	calr AccPatch_AdvanceSlotCounters
	anddi8 13898, 253
	jr AccPatch_ContinueProcessing

AccPatch_ProcessMarkerCommand:
	lds bc, 3
	calr AccPatch_ReadRingBufBytes
	calr AccPatch_ParseAndResolve
	calr AccPatch_ProcessMarkerEvent
	jr __jrt_nop_F60695
__jrt_nop_F60695:

AccPatch_ContinueProcessing:
	jrl AccPatch_EventDispatchLoop

AccPatch_EventDispatch_Done:
	ret

__pad_F60699:
	.byte 0x00, 0x00

AccPatch_UpdatePlayback:
	cpdi16 13834, 0
	jr z, AccPatch_UpdatePlayback_CheckQueue
	ldda16 xwa, 13826
	stda16 14078, xwa
	ldda16 xwa, 13828
	stda16 14080, xwa
	calr AccPatch_InitSlotAndCopyData
	calr AccPatch_AdvancePlayPos
	calr AccPatch_AdvanceAllSteps
	stdi16 13834, 0

AccPatch_UpdatePlayback_CheckQueue:
	cpdi16 13838, 0
	jr z, AccPatch_UpdatePlayback_ClearStep
	calr AccPatch_DispatchQueuedNotes

AccPatch_UpdatePlayback_ClearStep:
	stdi8 13823, 0
	ret

__pad_F606D3:
	.byte 0x00, 0x00

AccPatch_AdvanceSlotCounters:
	ld xhl, 0x361A

AccPatch_AdvSlotCtr_Loop:
	bitm 7, (xhl)
	jr z, AccPatch_AdvSlotCtr_Next
	ld a, (xhl + 1)
	cp a, 0xFF
	jr z, AccPatch_AdvSlotCtr_Store
	inc 1, a

AccPatch_AdvSlotCtr_Store:
	ld (xhl + 1), a

AccPatch_AdvSlotCtr_Next:
	add xhl, 0x6
	cp xhl, 0x364A
	jr nz, AccPatch_AdvSlotCtr_Loop
	ret

__pad_F606FA:
	.byte 0x00, 0x00

AccPatch_ReadRingBufBytes:
	lds32 xhl, 0

AccPatch_ReadBuf_Loop:
	cp hl, bc
	jr z, AccPatch_ReadBuf_Done
	pushw bc
	pushw hl
	call TempoRingBuf_ReadByteToA
	cp a, 0xFF
	jr nz, AccPatch_ReadBuf_StoreAndNext
	nop

AccPatch_ReadBuf_StoreAndNext:
	popw hl
	popw bc
	ld xiz, 0x36EA
	lda_dri3 XBC, 0x07, 0xF8, 0xEC
	inc 1, hl
	jr AccPatch_ReadBuf_Loop

AccPatch_ReadBuf_Done:
	ret

__pad_F6071F:
	.byte 0x00, 0x00

AccPatch_ParseAndResolve:
	ldda8 a, 14059
	stda8 14071, a
	stda8 14072, a
	calr AccPatch_LookupStepByDrumParam
	cpdi8 13823, 0
	jr z, AccPatch_ParseResolve_ParseHdr
	ldda8 a, 13824
	cpda8 a, 14072
	jr z, AccPatch_ParseResolve_IncStep
	calr AccPatch_UpdatePlayback

AccPatch_ParseResolve_ParseHdr:
	calr AccPatch_ParseSequenceHeader
	ldda16 xwa, 13842
	stda16 13826, xwa
	ldda16 xwa, 13844
	stda16 13828, xwa

AccPatch_ParseResolve_IncStep:
	incdi8 1, 13823
	ldda8 a, 14072
	stda8 13824, a
	ret

__pad_F60764:
	.byte 0x00, 0x00

AccPatch_LookupStepByDrumParam:
	xor w, w
	ld iy, wa
	ldda8 a, 13531
	cps a, 0
	jr z, AccPatch_SetStepDone
	ld wa, iy
	ldda8 w, 13531
	and w, 0x7
	call DrumParam_Wrapper
	cp a, 0x7F
	jr nz, AccPatch_LookupStep_StoreResult
	ldb a, 0x0
	stda8 14072, a
	stda8 14059, a
	bitda 1, 13898
	jr nz, AccPatch_SetStepDone
	ordi8 13898, 2
	calr AccPatch_UpdatePlayback
	calr AccPatch_ScanToSequenceEnd
	jr AccPatch_SetStepDone

AccPatch_LookupStep_StoreResult:
	stda8 14072, a
	stda8 14059, a

AccPatch_SetStepDone:
	ret

__pad_F607AA:
	.byte 0x00, 0x00

AccPatch_CopyNoteStepsToSlots:
	ld xhl, 0x361A
	xor iy, iy

AccPatch_CopySteps_FindFreeSlot:
	bit_dri 7, 0x07, 0xEC, 0xF4
	jr z, AccPatch_CopySteps_ProcessEntry
	add iy, 0x6
	cp iy, 0x30
	jr z, AccPatch_CopyStepsDone
	jr AccPatch_CopySteps_FindFreeSlot

AccPatch_CopySteps_ProcessEntry:
	ld de, iy
	cpdi16 13524, 0
	jr z, AccPatch_CopySteps_Overflow
	stdi8 13361, 0
	stdi8 14058, 144
	bitda 4, 14235
	jr nz, AccPatch_CopySteps_StartFetch
	calr AccPatch_TransposeNote

AccPatch_CopySteps_StartFetch:
	ldda8 a, 14058
	calr AccPatch_FetchStepEntry
	calr AccPatch_SeqAdvanceStep
	ldda8 a, 14059
	calr AccPatch_FetchStepEntry
	calr AccPatch_SeqAdvanceStep
	ldda8 a, 14060
	calr AccPatch_FetchStepEntry
	calr AccPatch_UpdateSlotVoiceData
	calr AccPatch_SeqAdvanceStep
	ldda8 a, 14061
	calr AccPatch_FetchStepEntry
	calr AccPatch_SeqAdvanceStep
	ldb a, 0x10
	calr AccPatch_FetchStepEntry
	calr AccPatch_SeqAdvanceStep
	ldb a, 0x0
	calr AccPatch_FetchStepEntry
	calr AccPatch_SeqAdvanceStep
	bitda 0, 13361
	jr z, AccPatch_CopyStepsDone
	ldda8 a, 14064
	calr AccPatch_FetchStepEntry
	calr AccPatch_SeqAdvanceStep
	ldda8 a, 14065
	calr AccPatch_FetchStepEntry
	calr AccPatch_SeqAdvanceStep

AccPatch_CopyStepsDone:
	ret

AccPatch_CopySteps_Overflow:
	stdi8 32578, 15
	call DrumVoice_NotifyEE
	ldb a, 0x8
	call MIDI_SendSysExCmd
	jr AccPatch_CopyStepsDone

AccPatch_TransposeNote:
	ldda8 a, 13545
	and a, 0xF
	cps a, 0
	jr z, AccPatch_Transpose_LookupTable
	calr AccPatch_ReadTransposeAmount
	cpda8 a, 14926
	jr ugt, AccPatch_Transpose_AddBack
	subdm8 14060, a
	jr nc, AccPatch_Transpose_Done
	ldb a, 0xC
	adddm8 14060, a

AccPatch_Transpose_Done:
	jr AccPatch_Transpose_LookupTable

AccPatch_Transpose_AddBack:
	ldb w, 0xC
	sub w, a
	adddm8 14060, w

AccPatch_Transpose_LookupTable:
	lds32 xhl, 0
	ldda8 l, 14060
	add xhl, 0xE46142
	ld a, (xhl)
	bitda 4, 13546
	jr z, AccPatch_Transpose_CheckBit6
	ld w, a
	lds32 xhl, 0
	ld l, a
	add xhl, 0xF60909
	ld l, (xhl)
	bit 0, l
	jr z, AccPatch_Transpose_CheckBit6
	inc 1, w
	ldda8 a, 14060
	inc 1, a
	stda8 14060, a
	ld a, w

AccPatch_Transpose_CheckBit6:
	bitda 6, 13546
	jr z, AccPatch_Transpose_CheckBit5
	bitda 3, 14235
	jr z, AccPatch_Transpose_CheckBit5
	jr AccPatch_Transpose_SetDrumSplit

AccPatch_Transpose_CheckBit5:
	bitda 5, 13546
	jr z, AccPatch_StoreDrumParams
	bitda 3, 14235
	jr nz, AccPatch_StoreDrumParams

AccPatch_Transpose_SetDrumSplit:
	cps a, 7
	jr nz, AccPatch_StoreDrumParams
	stdi8 13361, 1
	stdi8 14064, 3
	stdi8 14065, 0
	jr AccPatch_StoreDrumParams_CheckSplit

AccPatch_StoreDrumParams:
	lds32 xhl, 0
	ld l, a
	sll a, 1
	add l, a
	add xhl, 0xF60915
	ld a, (xhl)
	stda8 13361, a
	ld a, (xhl + 1)
	stda8 14064, a
	ld a, (xhl + 2)
	stda8 14065, a

AccPatch_StoreDrumParams_CheckSplit:
	bitda 0, 13361
	jr z, AccPatch_StoreDrumParams_Return
	stdi8 14058, 145

AccPatch_StoreDrumParams_Return:
	ret

AccPatch_TransposeNoteTable:
	nop
	nop
	nop
	nop
	nop
	.byte 0x01
	nop
	nop
	.zero 8
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x01
	nop
	scf
	.byte 0x01
	nop
	scf
	nop
	nop
	nop
	.zero 8
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x01
	scf
	scf

AccPatch_ReadTransposeAmount:
	push xwa
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	call AccPatch_GetCurrentSlotAddr
	ldda8 a, 14235
	ld xix, 0x25
	bit 3, a
	jr nz, AccPatch_SelectTranspose
	ld xix, 0x2D
	bit 0, a
	jr nz, AccPatch_SelectTranspose
	ld xix, 0x35
	bit 1, a
	jr nz, AccPatch_SelectTranspose
	ld xix, 0x3D

AccPatch_SelectTranspose:
	add xix, xiy
	ld a, (xix)
	stda8 14926, a
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	pop xwa
	ret

AccPatch_FetchStepEntry:
	ld xiy, 0x366A
	ldda16 xhl, 13834
	lda_dri3 XBC, 0x07, 0xF4, 0xEC
	inc 1, hl
	stda16 13834, xhl
	ret

AccPatch_FetchStepData:
	ld	xiy, 13994
	ldda16	hl, 13838
	.byte 0xf3, 0x07, 0xf4, 0xec, 0x41
	inc	1, hl
	stda16	13838, hl
	ret

AccPatch_SeqAdvanceStep:
	ldda16 xwa, 13844
	cp wa, 0xFE
	jr nz, AccPatch_SeqAdvStep_Increment
	cpdi16 13524, 0
	jr z, AccPatch_SeqAdvStep_Return
	calr AccPatch_SeqAdvStep_WrapToNext
	jr AccPatch_SeqAdvStep_Return

AccPatch_SeqAdvStep_Increment:
	inc 1, wa
	stda16 13844, xwa

AccPatch_SeqAdvStep_Return:
	ret

AccPatch_SeqAdvStep_WrapToNext:
	ldda16 xhl, 13842
	calr AccPatch_GetEntryAddr
	ld hl, (xix + 3)
	cp hl, 0xFFFF
	jr z, AccPatch_SeqAdvStep_ScanFromStart
	jr AccPatch_SeqAdvStep_StorePos

AccPatch_SeqAdvStep_ScanFromStart:
	ldw hl, 0x95

AccPatch_SeqAdvStep_ScanLoop:
	inc 1, hl
	calr AccPatch_GetEntryAddr
	bitm 7, (xix)
	jr z, AccPatch_SeqAdvStep_StorePos
	jr AccPatch_SeqAdvStep_ScanLoop

AccPatch_SeqAdvStep_StorePos:
	stda16 13842, xhl
	stdi16 13844, 6
	ret

__pad_F609EE:
	.byte 0x00, 0x00

AccPatch_UpdateSlotVoiceData:
	ld xhl, 0x361A
	ld iy, de
	or a, 0x80
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	pushw iy
	inc 1, iy
	stib_dri 0x07, 0xEC, 0xF4, 0x00
	ldda8 a, 14071
	inc 1, iy
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	ldda16 xwa, 13842
	inc 1, iy
	st_dri3w WA, 0x07, 0xEC, 0xF4
	ldda16 xwa, 13844
	inc 2, iy
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	popw iy
	ret

AccPatch_TransposeAndCopyNote:
	bitda 4, 14235
	jr nz, AccPatch_TransposeCopy_DoCopy
	calr AccPatch_TransposeNote

AccPatch_TransposeCopy_DoCopy:
	ld xiy, 0x36EA
	ld xix, 0x36AA
	lds32 xbc, 0
	ldda16 xbc, 13838
	add xix, xbc
	lds bc, 6
	ldir85
	adddi16 13838, 6
	ret

__pad_F60A51:
	.byte 0x00, 0x00

AccPatch_ProcessMarkerEvent:
	cpdi16 13524, 0
	jr z, AccPatch_ProcessMarker_Return
	ldda8 a, 14058
	cp a, 0xD4
	jr nz, AccPatch_ProcessMarker_CheckD3
	ldb a, 0xD3
	jr AccPatch_FetchSequence

AccPatch_ProcessMarker_CheckD3:
	cp a, 0xD3
	jr nz, AccPatch_ProcessMarker_CheckD5
	ldb a, 0xD5
	jr AccPatch_FetchSequence

AccPatch_ProcessMarker_CheckD5:
	cp a, 0xD5
	jr nz, AccPatch_FetchSequence
	ldb a, 0xD4
	jr __jrt_nop_F60A7A
__jrt_nop_F60A7A:

AccPatch_FetchSequence:
	calr AccPatch_FetchStepEntry
	calr AccPatch_SeqAdvanceStep
	ldda8 a, 14059
	calr AccPatch_FetchStepEntry
	calr AccPatch_SeqAdvanceStep
	ldda8 a, 14060
	calr AccPatch_FetchStepEntry
	calr AccPatch_SeqAdvanceStep

AccPatch_ProcessMarker_Return:
	ret

__pad_F60A95:
	.byte 0x00, 0x00

AccPatch_SkipToMarker:
	call TempoRingBuf_ReadByteToA
	bit 7, a
	jr z, AccPatch_SkipToMarker
	ret

AccPatch_SlotCopyDataBlock:
	nop
	nop
	pushw	bc
	call	16126841
	popw	bc
	dec	1, bc
	cps	bc, 0
	jr	nz, -12
	ret
	stdi16	13840, 0
	ld	xix, 13994
	.byte 0xd1, 0x10, 0x36, 0x84
	calr	664
	ldda16	wa, 13840
	add	wa, 6
	stda16	13840, wa
	.byte 0xd1, 0x0e, 0x36, 0xf0
	jr	c, -30
	stdi16	13838, 0
	ret

AccPatch_InitSlotAndCopyData:
	lds32 xhl, 0
	ldda8 l, 13526
	call AccPatch_GetCurrentSlotAddr
	andmi8 (xiy + 15), 0x7F
	ldda16 xde, 13826
	ldda16 xhl, 13830
	stda16 13912, xhl
	calr AccPatch_GetEntryAddr
	stda32 13904, xix
	ldda16 xwa, 13832
	stda16 13918, xwa
	ldw bc, 0xFE
	sub bc, wa
	stda16 14082, xbc
	cpda16 xbc, 13834
	jr nc, AccPatch_InitSlot_SameBlock
	jr AccPatch_InitSlot_CrossBlock

AccPatch_InitSlot_SameBlock:
	ldda16 xhl, 13830
	stda16 13914, xhl
	calr AccPatch_GetEntryAddr
	stda32 13900, xix
	ldda16 xwa, 13832
	addda16 xwa, 13834
	stda16 13920, xwa
	jr AccPatch_InitSlot_StoreAddrs

AccPatch_InitSlot_CrossBlock:
	calr AccPatch_FindFreeEntrySlot
	stda16 13914, xwa
	ld hl, wa
	calr AccPatch_GetEntryAddr
	stda32 13900, xix
	ldda16 xwa, 13834
	subda16 xwa, 14082
	add wa, 0x5
	stda16 13920, xwa

AccPatch_InitSlot_StoreAddrs:
	ldda16 xwa, 13914
	stda16 13830, xwa
	ldda16 xwa, 13920
	stda16 13832, xwa
	calr AccPatch_CalcBlockCopySetup
	inc 1, ix
	stda16 14084, xix
	ldda16 xhl, 13826
	calr AccPatch_GetEntryAddr
	lds32 xwa, 0
	ldda16 xwa, 13828
	add xix, xwa
	ld xiy, 0x366A
	lds32 xbc, 0
	ldw bc, 0xFE
	subda16 xbc, 13828
	inc 1, bc
	cpda16 xbc, 13834
	jr c, AccPatch_InitSlot_SplitCopy
	lds32 xbc, 0
	ldda16 xbc, 13834
	ldir85
	jr AccPatch_InitSlot_Finalize

AccPatch_InitSlot_SplitCopy:
	ld wa, bc
	ldir85
	lds32 xbc, 0
	ldda16 xbc, 13834
	sub bc, wa
	ldda16 xhl, 13826
	calr AccPatch_GetEntryAddr
	ld hl, (xix + 3)
	calr AccPatch_GetEntryAddr
	add xix, 0x6
	cps bc, 0
	jr z, AccPatch_InitSlot_Finalize
	ldir85

AccPatch_InitSlot_Finalize:
	ldda16 xwa, 13914
	stda16 13826, xwa
	ldda16 xwa, 14084
	stda16 13828, xwa
	ret

__pad_F60BD0:
	.byte 0x00, 0x00

AccPatch_FindFreeEntrySlot:
	ldw hl, 0x95

AccPatch_FindFreeSlot_Loop:
	inc 1, hl
	calr AccPatch_GetEntryAddr
	bitm 7, (xix)
	jr z, AccPatch_FindFreeSlot_Found
	jr AccPatch_FindFreeSlot_Loop

AccPatch_FindFreeSlot_Found:
	ld wa, hl
	push xix
	ldda16 xhl, 13830
	pushw wa
	calr AccPatch_GetEntryAddr
	popw wa
	ld (xix + 3), wa
	pop xix
	ormi8 (xix), 0x80
	ldda16 xbc, 13830
	ld (xix + 1), bc
	ldw (xix + 3), 0xFFFF
	decdi16 1, 13524
	ret

__pad_F60C04:
	.byte 0x00, 0x00

AccPatch_AdvancePlayPos:
	calr AccPatch_LoadTablePointers
	ld de, (xix)
	ld hl, (xiy)
	pushw de
	pushw hl
	calr AccPatch_GetEntryAddr
	popw hl
	popw de
	cpda16 xhl, 14078
	jr z, AccPatch_AdvPlayPos_CheckDE
	cpw (xix + 1), 0xFFFF
	jr nz, AccPatch_AdvPlayPos_AddAndCheck
	jr AccPatch_StoreEntryPtr

AccPatch_AdvPlayPos_CheckDE:
	cpda16 xde, 14080
	jr nc, AccPatch_AdvPlayPos_AddAndCheck
	jr AccPatch_StoreEntryPtr

AccPatch_AdvPlayPos_AddAndCheck:
	addda16 xde, 13834
	cp de, 0xFE
	jr z, AccPatch_AdvPlayPos_StoreDirect
	jr c, AccPatch_AdvPlayPos_StoreDirect
	sub de, 0xFE
	pushw de
	calr AccPatch_GetEntryAddr
	ld wa, (xix + 3)
	pushw wa
	calr AccPatch_LoadTablePointers
	popw wa
	popw de
	ld (xiy), wa
	add de, 0x5
	ld (xix), de
	jr AccPatch_StoreEntryPtr

AccPatch_AdvPlayPos_StoreDirect:
	pushw de
	calr AccPatch_LoadTablePointers
	popw de
	ld (xix), de

AccPatch_StoreEntryPtr:
	ret

AccPatch_AdvPlayPos_DataBlock:
	.zero 8
	nop
	nop
	nop
	.byte 0x9d, 0x32, 0x00
	nop
	.byte 0x9f, 0x32, 0x00
	nop
	nop
	nop
	nop
	nop
	.byte 0xa1, 0x32
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
	.byte 0x9b, 0x32, 0x00
	nop
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
	nop
	nop
	.byte 0x97, 0x32
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x8d, 0x32, 0x00
	nop
	.byte 0x8f, 0x32, 0x00
	nop
	nop
	nop
	nop
	nop
	.byte 0x91, 0x32
	nop
	nop
	nop
	.zero 8
	nop
	nop
	nop
	.byte 0x8b, 0x32, 0x00
	nop
	nop
	.zero 24
	nop
	nop
	nop
	.byte 0x87, 0x32
	nop
	nop

AccPatch_AdvanceAllSteps:
	ld xix, 0x361A

AccPatch_AdvAllSteps_Loop:
	bitm 7, (xix + 1)
	jr z, AccPatch_AdvAllSteps_Next
	ldda16 xbc, 13834

AccPatch_AdvAllSteps_InnerLoop:
	calr AccPatch_AdvanceSingleStep
	djnz xbc, AccPatch_AdvAllSteps_InnerLoop

AccPatch_AdvAllSteps_Next:
	add xix, 0x6
	cp xix, 0x364A
	jr c, AccPatch_AdvAllSteps_Loop
	ret

__pad_F60D0C:
	.byte 0x00, 0x00

AccPatch_AdvanceSingleStep:
	xor w, w
	ld a, (xix + 5)
	cp wa, 0xFE
	jr nz, AccPatch_AdvSingleStep_Inc
	ld hl, (xix + 3)
	push xix
	calr AccPatch_GetEntryAddr
	ld xiy, xix
	pop xix
	ld wa, (xiy + 3)
	ld (xix + 3), wa
	lds wa, 6
	jr AccPatch_AdvSingleStep_Store

AccPatch_AdvSingleStep_Inc:
	inc 1, wa

AccPatch_AdvSingleStep_Store:
	ld (xix + 5), a
	ret

__pad_F60D33:
	.byte 0x00, 0x00

AccPatch_DispatchQueuedNotes:
	ld xix, 0x36AA

AccPatch_DispatchQueued_Loop:
	calr AccPatch_DispatchNoteToVoice
	add xix, 0x6
	ld xwa, xix
	sub xwa, 0x36AA
	cpda16 xwa, 13838
	jr c, AccPatch_DispatchQueued_Loop
	stdi16 13838, 0
	ret

__pad_F60D58:
	.byte 0x00, 0x00

AccPatch_DispatchNoteToVoice:
	ld xhl, 0x361A
	ldw iy, 0x2A

AccPatch_DispatchNote_Loop:
	bit_dri 7, 0x07, 0xEC, 0xF4
	jr z, AccPatch_DispatchNote_NextSlot
	ld_srib3 A, 0x07, 0xEC, 0xF4
	and a, 0x7F
	cp a, (xix + 2)
	jr nz, AccPatch_DispatchNote_NextSlot
	and_srib_im 0x07, 0xEC, 0xF4, 0x7F
	inc 1, iy
	and_srib_im 0x07, 0xEC, 0xF4, 0x7F
	ld_srib3 D, 0x07, 0xEC, 0xF4
	inc 1, iy
	ld_srib3 A, 0x07, 0xEC, 0xF4
	ld c, (xix + 1)
	cp c, a
	jr nc, AccPatch_DispatchNote_CalcVelocity
	add c, 0x60
	cps d, 0
	jr z, AccPatch_DispatchNote_CalcVelocity
	dec 1, d

AccPatch_DispatchNote_CalcVelocity:
	sub c, a
	ld a, c
	calr AccPatch_WriteVelocityToSeq
	jr AccPatch_DispatchNote_Return

AccPatch_DispatchNote_NextSlot:
	sub iy, 0x6
	cps iy, 0
	jr lt, AccPatch_DispatchNote_Return
	jr AccPatch_DispatchNote_Loop

AccPatch_DispatchNote_Return:
	ret

__pad_F60DB4:
	.byte 0x00, 0x00

AccPatch_WriteVelocityToSeq:
	pushw de
	pushw wa
	ldda16 xwa, 13842
	stda16 14074, xwa
	ldda16 xwa, 13844
	stda16 14076, xwa
	inc 1, iy
	ld_sriw3 WA, 0x07, 0xEC, 0xF4
	stda16 13842, xwa
	pushw iy
	inc 2, iy
	xor wa, wa
	ld_srib3 A, 0x07, 0xEC, 0xF4
	popw iy
	stda16 13844, xwa
	calr AccPatch_SeqReadByte
	cp a, (xix + 2)
	jr z, AccPatch_WriteVel_MatchFound
	popw wa
	popw de
	jr AccPatch_WriteVel_RestorePos

AccPatch_WriteVel_MatchFound:
	calr AccPatch_AdvanceSeqIndex
	calr AccPatch_AdvanceSeqIndex
	popw wa
	calr AccPatch_WriteSeqByte
	calr AccPatch_AdvanceSeqIndex
	popw de
	ld a, d
	calr AccPatch_WriteSeqByte

AccPatch_WriteVel_RestorePos:
	ldda16 xwa, 14074
	stda16 13842, xwa
	ldda16 xwa, 14076
	stda16 13844, xwa
	ret

__pad_F60E12:
	.byte 0x00, 0x00

AccPatch_WriteSeqByte:
	push xix
	ldda16 xhl, 13842
	calr AccPatch_GetEntryAddr
	push xwa
	lds32 xwa, 0
	ldda16 xwa, 13844
	add xix, xwa
	pop xwa
	ld (xix), a
	pop xix
	ret

__pad_F60E2A:
	.byte 0x00, 0x00

AccPatch_CalcBlockCopySetup:
	stdi8 32578, 0
	cpda16 xde, 13912
	jr nz, AccPatch_CalcBlockCopy_DiffEntry
	ldda16 xiy, 13918
	sub iy, 0x6
	inc 1, iy
	stda16 13924, xiy
	ldda16 xiy, 13918
	ldda16 xix, 13920
	sub ix, 0x6
	inc 1, ix
	stda16 13926, xix
	ldda16 xix, 13920
	calr AccPatch_CalcBlockCopyBounds
	jr AccPatch_CalcBlockCopy_Done

AccPatch_CalcBlockCopy_DiffEntry:
	ldda16 xwa, 13920
	cpda16 xwa, 13918
	jr ugt, AccPatch_CalcBlockCopy_Clamp
	jr z, AccPatch_CalcBlockCopy_StoreIY
	jr AccPatch_CalcBlockCopy_CheckIX

AccPatch_CalcBlockCopy_Clamp:
	calr __pad_F60E86
	jr AccPatch_CalcBlockCopy_StoreIX

AccPatch_CalcBlockCopy_StoreIY:
	calr BlockCopy_SameEntry_Reverse
	jr AccPatch_CalcBlockCopy_StoreIX

AccPatch_CalcBlockCopy_CheckIX:
	calr BlockCopy_IXFirst_Reverse

AccPatch_CalcBlockCopy_StoreIX:
	cpdi8 32578, 0
	jr nz, AccPatch_CalcBlockCopy_Done
	calr AccPatch_CalcBlockCopyBounds

AccPatch_CalcBlockCopy_Done:
	ret

__pad_F60E86:
	ldda16 xwa, 13920
	subda16 xwa, 13918
	stda16 13908, xwa
	ldw bc, 0xFF
	sub bc, 0x6
	sub bc, wa
	stda16 13910, xbc
	lds32 xix, 0
	lds32 xiy, 0
	ldda16 xiy, 13918
	ldda16 xix, 13920
	ldda16 xbc, 13918
	sub bc, 0x6
	inc 1, bc
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IY
	cpdi8 32578, 0
	jr z, BlockCopy_Rev_CheckSameEntry
	jr DSP_SetupDone

BlockCopy_Rev_CheckSameEntry:
	cpda16 xde, 13912
	jr nz, BlockCopy_Rev_CopyDiffEntry
	jr BlockCopy_Rev_StoreBounds

BlockCopy_Rev_CopyDiffEntry:
	ldda16 xbc, 13908
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IX
	cpdi8 32578, 0
	jr z, BlockCopy_Rev_CopyRemainder
	jr DSP_SetupDone

BlockCopy_Rev_CopyRemainder:
	ldda16 xbc, 13910
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IY
	cpdi8 32578, 0
	jr z, BlockCopy_Rev_CheckSameEntry
	jr DSP_SetupDone

BlockCopy_Rev_StoreBounds:
	ldda16 xwa, 13908
	stda16 13926, xwa
	ldw bc, 0xFF
	sub bc, 0x6
	stda16 13924, xbc

DSP_SetupDone:
	ret

DSP_BlockCopyReverse:
	push xwa
	push xhl
	and xiy, 0xFF
	and xix, 0xFF
	ldda32 xwa, 13900
	ldda32 xhl, 13904
	push xwa
	push xhl
	add xwa, xix
	ld xix, xwa
	add xhl, xiy
	ld xiy, xhl
	lddr85
	pop xhl
	pop xwa
	stda32 13904, xhl
	stda32 13900, xwa
	and xiy, 0xFF
	and xix, 0xFF
	pop xhl
	pop xwa
	ret

DSP_BlockCopyForward:
	push xwa
	push xhl
	and xiy, 0xFF
	and xix, 0xFF
	ldda32 xwa, 13900
	ldda32 xhl, 13904
	push xwa
	push xhl
	add xwa, xix
	ld xix, xwa
	add xhl, xiy
	ld xiy, xhl
	ldir85
	pop xhl
	pop xwa
	stda32 13904, xhl
	stda32 13900, xwa
	and xiy, 0xFF
	and xix, 0xFF
	pop xhl
	pop xwa
	ret

BlockCopy_SameEntry_Reverse:
	ldda16 xbc, 13918
	sub bc, 0x6
	inc 1, bc
	ldda16 xiy, 13918
	ldda16 xix, 13920
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IX
	cpdi8 32578, 0
	jr z, BlockCopy_SameEntry_AdvIY
	jr DSP_NullRet

BlockCopy_SameEntry_AdvIY:
	calr AccPatch_AdvanceNextEntry_IY
	cpdi8 32578, 0
	jr z, BlockCopy_SameEntry_CheckDE
	jr DSP_NullRet

BlockCopy_SameEntry_CheckDE:
	cpda16 xde, 13912
	jr nz, BlockCopy_SameEntry_FullCopy
	jr BlockCopy_SameEntry_StoreBounds

BlockCopy_SameEntry_FullCopy:
	ldw bc, 0xFF
	sub bc, 0x6
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IX
	cpdi8 32578, 0
	jr z, BlockCopy_SameEntry_AdvIYLoop
	jr DSP_NullRet

BlockCopy_SameEntry_AdvIYLoop:
	calr AccPatch_AdvanceNextEntry_IY
	cpdi8 32578, 0
	jr z, BlockCopy_SameEntry_CheckDE
	jr DSP_NullRet

BlockCopy_SameEntry_StoreBounds:
	ldw bc, 0xFF
	sub bc, 0x6
	stda16 13926, xbc
	stda16 13924, xbc

DSP_NullRet:
	ret

BlockCopy_IXFirst_Reverse:
	ldda16 xwa, 13918
	subda16 xwa, 13920
	stda16 13908, xwa
	ldw bc, 0xFF
	sub bc, 0x6
	sub bc, wa
	stda16 13910, xbc
	lds32 xix, 0
	lds32 xiy, 0
	ldda16 xiy, 13918
	ldda16 xix, 13920
	ldda16 xbc, 13920
	sub bc, 0x6
	inc 1, bc
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IX
	cpdi8 32578, 0
	jr z, BlockCopy_IXFirst_CopyOffset
	jr DSP_NullRet2

BlockCopy_IXFirst_CopyOffset:
	ldda16 xbc, 13908
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IY
	cpdi8 32578, 0
	jr z, BlockCopy_IXFirst_CheckDE
	jr DSP_NullRet2

BlockCopy_IXFirst_CheckDE:
	cpda16 xde, 13912
	jr nz, BlockCopy_IXFirst_CopyRemainder
	jr BlockCopy_IXFirst_StoreBounds

BlockCopy_IXFirst_CopyRemainder:
	ldda16 xbc, 13910
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IX
	cpdi8 32578, 0
	jr z, BlockCopy_IXFirst_CopyOffset2
	jr DSP_NullRet2

BlockCopy_IXFirst_CopyOffset2:
	ldda16 xbc, 13908
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IY
	cpdi8 32578, 0
	jr z, BlockCopy_IXFirst_CheckDE
	jr DSP_NullRet2

BlockCopy_IXFirst_StoreBounds:
	ldda16 xwa, 13910
	stda16 13926, xwa
	ldw wa, 0xFF
	sub wa, 0x6
	stda16 13924, xwa

DSP_NullRet2:
	ret

AccPatch_CalcBlockCopyBounds:
	ldda16 xwa, 13828
	sub wa, 0x6
	ldda16 xbc, 13924
	sub bc, wa
	stda16 13928, xbc
	cpdm16 13926, xbc
	jr nc, BlockCopyBounds_UseBC
	jr BlockCopyBounds_UseSmaller

BlockCopyBounds_UseBC:
	calr DSP_BlockCopyReverse
	jr BlockCopyBounds_Return

BlockCopyBounds_UseSmaller:
	ldda16 xbc, 13926
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IX
	cpdi8 32578, 0
	jr z, BlockCopyBounds_CopyRemainder
	jr BlockCopyBounds_Return

BlockCopyBounds_CopyRemainder:
	ldda16 xbc, 13928
	subda16 xbc, 13926
	calr DSP_BlockCopyReverse

BlockCopyBounds_Return:
	ret

AccPatch_AdvanceNextEntry_IY:
	push xix
	ldda32 xiy, 13904
	ld hl, (xiy + 1)
	stda16 13912, xhl
	calr AccPatch_GetEntryAddr
	bitm 7, (xix + 256)
	jr nz, AdvNextEntry_IY_StoreAndReset
	stdi8 32578, 11
	jr AdvNextEntry_IY_Return

AdvNextEntry_IY_StoreAndReset:
	stda32 13904, xix
	lds32 xiy, 0
	ldw iy, 0xFE

AdvNextEntry_IY_Return:
	pop xix
	ret

AccPatch_AdvanceNextEntry_IX:
	ldda32 xix, 13900
	ld hl, (xix + 1)
	stda16 13914, xhl
	calr AccPatch_GetEntryAddr
	bitm 7, (xix + 256)
	jr nz, AdvNextEntry_IX_StoreAndReset
	stdi8 32578, 11
	jr AdvNextEntry_IX_Return

AdvNextEntry_IX_StoreAndReset:
	stda32 13900, xix
	lds32 xix, 0
	ldw ix, 0xFE

AdvNextEntry_IX_Return:
	ret

AccPatch_SetupBlockCopyDispatch:
	stdi8 32578, 0
	ldda16 xhl, 13912
	calr AccPatch_GetEntryAddr
	stda32 13904, xix
	cpda16 xde, 13912
	jr nz, BlockCopyDisp_CompareOffsets
	lds32 xiy, 0
	ldw iy, 0xFF
	subda16 xiy, 13918
	stda16 13924, xiy
	ldda16 xiy, 13918
	lds32 xix, 0
	ldw ix, 0xFF
	subda16 xix, 13920
	stda16 13926, xix
	ldda16 xix, 13920
	calr AccPatch_ForwardBlockCopy
	jr BlockCopyDisp_Return

BlockCopyDisp_CompareOffsets:
	ldda16 xwa, 13920
	cpda16 xwa, 13918
	jr c, BlockCopyDisp_IXSmaller
	jr z, BlockCopyDisp_Equal
	jr ugt, BlockCopyDisp_IXLarger

BlockCopyDisp_IXSmaller:
	calr BlockCopy_FwdIYSmaller
	jr BlockCopyDisp_CheckAndForward

BlockCopyDisp_Equal:
	calr BlockCopy_FwdEqual
	jr BlockCopyDisp_CheckAndForward

BlockCopyDisp_IXLarger:
	calr BlockCopy_FwdIXSmaller
	jr __jrt_nop_F61158
__jrt_nop_F61158:

BlockCopyDisp_CheckAndForward:
	cpdi8 32578, 0
	jr nz, BlockCopyDisp_Return
	calr AccPatch_ForwardBlockCopy

BlockCopyDisp_Return:
	ret

BlockCopy_FwdIYSmaller:
	ldw wa, 0xFF
	subda16 xwa, 13920
	ldw bc, 0xFF
	subda16 xbc, 13918
	sub wa, bc
	stda16 13908, xwa
	ldw bc, 0xFF
	sub bc, 0x6
	sub bc, wa
	stda16 13910, xbc
	lds32 xiy, 0
	ldda16 xiy, 13918
	lds32 xix, 0
	ldda16 xix, 13920
	ldw bc, 0xFF
	subda16 xbc, 13918
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IY
	cpdi8 32578, 0
	jr z, BlockCopy_FwdIYSmall_CheckDE
	jr DSP_CopyDone

BlockCopy_FwdIYSmall_CheckDE:
	cpda16 xde, 13912
	jr nz, BlockCopy_FwdIYSmall_CopyOffset
	jr BlockCopy_FwdIYSmall_StoreBounds

BlockCopy_FwdIYSmall_CopyOffset:
	ldda16 xbc, 13908
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IX
	cpdi8 32578, 0
	jr z, BlockCopy_FwdIYSmall_CopyRem
	jr DSP_CopyDone

BlockCopy_FwdIYSmall_CopyRem:
	ldda16 xbc, 13910
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IY
	cpdi8 32578, 0
	jr z, BlockCopy_FwdIYSmall_CheckDE
	jr DSP_CopyDone

BlockCopy_FwdIYSmall_StoreBounds:
	ldda16 xwa, 13908
	stda16 13926, xwa
	ldw bc, 0xFF
	sub bc, 0x6
	stda16 13924, xbc

DSP_CopyDone:
	ret

BlockCopy_FwdEqual:
	ldw bc, 0xFF
	subda16 xbc, 13918
	lds32 xiy, 0
	ldda16 xiy, 13918
	lds32 xix, 0
	ldda16 xix, 13920
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IY
	cpdi8 32578, 0
	jr z, BlockCopy_FwdEqual_AdvIX
	jr AccPatch_NullRet2

BlockCopy_FwdEqual_AdvIX:
	calr AccPatch_AdvancePrevEntry_IX
	cpdi8 32578, 0
	jr z, BlockCopy_FwdEqual_CheckDE
	jr AccPatch_NullRet2

BlockCopy_FwdEqual_CheckDE:
	cpda16 xde, 13912
	jr nz, BlockCopy_FwdEqual_FullCopy
	jr BlockCopy_FwdEqual_StoreBounds

BlockCopy_FwdEqual_FullCopy:
	ldw bc, 0xFF
	sub bc, 0x6
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IY
	cpdi8 32578, 0
	jr z, BlockCopy_FwdEqual_AdvIXLoop
	jr AccPatch_NullRet2

BlockCopy_FwdEqual_AdvIXLoop:
	calr AccPatch_AdvancePrevEntry_IX
	cpdi8 32578, 0
	jr z, BlockCopy_FwdEqual_CheckDE
	jr AccPatch_NullRet2

BlockCopy_FwdEqual_StoreBounds:
	ldw bc, 0xFF
	sub bc, 0x6
	stda16 13926, xbc
	stda16 13924, xbc

AccPatch_NullRet2:
	ret

BlockCopy_FwdIXSmaller:
	ldw wa, 0xFF
	subda16 xwa, 13918
	ldw bc, 0xFF
	subda16 xbc, 13920
	sub wa, bc
	stda16 13908, xwa
	ldw bc, 0xFF
	sub bc, 0x6
	sub bc, wa
	stda16 13910, xbc
	lds32 xiy, 0
	ldda16 xiy, 13918
	lds32 xix, 0
	ldda16 xix, 13920
	ldw bc, 0xFF
	subda16 xbc, 13920
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IX
	cpdi8 32578, 0
	jr z, BlockCopy_FwdIXSmall_CopyOff
	jr AccPatch_NullRet3

BlockCopy_FwdIXSmall_CopyOff:
	ldda16 xbc, 13908
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IY
	cpdi8 32578, 0
	jr z, BlockCopy_FwdIXSmall_CheckDE
	jr AccPatch_NullRet3

BlockCopy_FwdIXSmall_CheckDE:
	cpda16 xde, 13912
	jr nz, BlockCopy_FwdIXSmall_CopyRem
	jr BlockCopy_FwdIXSmall_StoreBounds

BlockCopy_FwdIXSmall_CopyRem:
	ldda16 xbc, 13910
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IX
	cpdi8 32578, 0
	jr z, BlockCopy_FwdIXSmall_CopyOff2
	jr AccPatch_NullRet3

BlockCopy_FwdIXSmall_CopyOff2:
	ldda16 xbc, 13908
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IY
	cpdi8 32578, 0
	jr z, BlockCopy_FwdIXSmall_CheckDE
	jr AccPatch_NullRet3

BlockCopy_FwdIXSmall_StoreBounds:
	ldda16 xwa, 13910
	stda16 13926, xwa
	ldw wa, 0xFF
	sub wa, 0x6
	stda16 13924, xwa

AccPatch_NullRet3:
	ret

AccPatch_ForwardBlockCopy:
	cpdi8 32578, 0
	jr nz, AccPatch_DoneBlockCopy
	ldw wa, 0xFE
	subda16 xwa, 13922
	ldda16 xbc, 13924
	sub bc, wa
	stda16 13928, xbc
	cpdm16 13926, xbc
	jr nc, FwdBlockCopy_UseFull
	jr FwdBlockCopy_UseSmaller

FwdBlockCopy_UseFull:
	calr DSP_BlockCopyForward
	jr AccPatch_DoneBlockCopy

FwdBlockCopy_UseSmaller:
	ldda16 xbc, 13926
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IX
	cpdi8 32578, 0
	jr z, FwdBlockCopy_CopyRemainder
	jr AccPatch_DoneBlockCopy

FwdBlockCopy_CopyRemainder:
	ldda16 xbc, 13928
	subda16 xbc, 13926
	calr DSP_BlockCopyForward

AccPatch_DoneBlockCopy:
	ret

AccPatch_AdvancePrevEntry_IX:
	ldda32 xix, 13900
	ld hl, (xix + 3)
	stda16 13914, xhl
	calr AccPatch_GetEntryAddr
	bitm 7, (xix)
	jr nz, AdvPrevEntry_IX_StoreAndReset
	stdi8 32578, 11
	jr AdvPrevEntry_IX_Return

AdvPrevEntry_IX_StoreAndReset:
	stda32 13900, xix
	lds32 xix, 0
	lds ix, 6

AdvPrevEntry_IX_Return:
	ret

AccPatch_AdvancePrevEntry_IY:
	push xix
	ldda32 xix, 13904
	ld hl, (xix + 3)
	stda16 13912, xhl
	calr AccPatch_GetEntryAddr
	bitm 7, (xix)
	jr nz, AdvPrevEntry_IY_StoreAndReset
	stdi8 32578, 11
	jr AdvPrevEntry_IY_Return

AdvPrevEntry_IY_StoreAndReset:
	stda32 13904, xix
	lds32 xiy, 0
	lds iy, 6

AdvPrevEntry_IY_Return:
	pop xix
	ret

AccPatch_CheckEmpty:
	call TempoRingBuf_CheckEmpty
	ld wa, hl
	ret

TempoRingBuf_ReadByteToA:
	call TempoRingBuf_ReadByte
	ld a, l
	ret

TempoRingBuf_ReInitAndRet:
	call TempoRingBuf_Init
	ret

TempoRingBuf_PeekByte:
	call TempoRingBuf_SaveReadPos
	call TempoRingBuf_ReadAlternate
	ld a, l
	ret

AccPlayback_InitOrUpdate:
	anddi8 13520, 239
	ldda8 a, 14235
	and a, 0x7F
	cpda8 a, 13584
	jr z, AccPlayback_CheckStyleMatch
	and a, 0x1F
	cps a, 0
	jr z, AccPlayback_CheckStyleMatch
	ordi8 13520, 16

AccPlayback_CheckStyleMatch:
	ldda8 a, 36150
	cp a, 0xB6
	jr z, AccPlayback_CheckActiveStyle
	jrl AccPlayback_Finalize

AccPlayback_CheckActiveStyle:
	cpda8 a, 13605
	jr z, AccPlayback_CheckBit4
	stdi8 13565, 0
	call TempoRingBuf_Init
	bitda 0, 12931
	jr nz, AccPlayback_GetSlotAddr
	ordi8 13517, 128

AccPlayback_GetSlotAddr:
	call AccPatch_GetCurrentSlotAddr
	call AccPatch_ReadVoiceStride

AccPlayback_CheckBit4:
	bitda 4, 13520
	jr nz, AccPlayback_InitTimingVars
	ldda8 a, 13605
	cp a, 0xB6
	jr z, AccPlayback_CheckStateFlags

AccPlayback_InitTimingVars:
	ldb a, 0x0
	stda8 13562, a
	stda8 13564, a
	stda8 13563, a
	stda8 14150, a
	stdi16 14151, 1
	calr AccPlayback_CalcTimingPosition
	call AccPatch_GetCurrentSlotAddr
	call AccPatch_ScanToSequenceStart
	stdi8 14098, 4
	stdi8 14103, 255
	stdi8 13602, 0
	anddi8 13519, 127

AccPlayback_CheckStateFlags:
	anddi8 13520, 254
	ldda8 a, 14099
	and a, 0xC0
	cps a, 0
	jr z, AccPlayback_CheckSkipInit
	ordi8 13520, 1
	calr AccPlayback_AdjustBeatPosition
	calr AccPlayback_CalcTimingPosition
	call AccPatch_GetCurrentSlotAddr
	calr AccVoice_InitPatternBuffer
	ordi8 58336, 16

AccPlayback_CheckSkipInit:
	bitda 4, 13520
	jr nz, AccPlayback_ApplyChanges
	bitda 0, 13520
	jr nz, AccPlayback_ApplyChanges
	ldda8 a, 13605
	cp a, 0xB6
	jr z, AccPlayback_CheckBit0_3

AccPlayback_ApplyChanges:
	anddi8 13520, 223
	calr AccPlayback_ProcessStyleChanges
	anddi8 13520, 254
	anddi8 14099, 63

AccPlayback_CheckBit0_3:
	ldda8 a, 14099
	and a, 0x3
	cps a, 0
	jr z, AccPlayback_ProcessMiscFlags
	calr AccPlayback_ProcessPartChanges
	anddi8 14099, 252

AccPlayback_ProcessMiscFlags:
	ldda8 a, 14125
	and a, 0x3F
	cps a, 0
	jr z, AccPlayback_RunPeriodicTasks
	calr AccPlayback_ProcessVoiceType5
	anddi8 14125, 192

AccPlayback_RunPeriodicTasks:
	calr AccPlayback_ReadEventLoop
	calr AccPlayback_ProcessBit5Change
	calr AccPlayback_ProcessTempoAdvance

AccPlayback_Finalize:
	calr AccPlayback_UpdateRhythmSustain
	ret

__pad_F614A3:
	nop
	nop
	pushw	hl
	and	hl, 4095
	sla	hl, 4
	popw	hl
	ret
	nop
	nop

; ============================================================================
; ToneGen_CalcBufferAddr - Compute tone generator buffer address
; ============================================================================
; Input:  HL = buffer index
; Output: XHL = 0x95C00 + (HL & 0xFFFF) * 256
; Calculates address into tone generator hardware buffer memory.
; Called from MIDI voice processing code (handles status bytes 0x81-0x91).
; ============================================================================
ToneGen_CalcBufferAddr:
	and xhl, 0xFFFF
	sla xhl, 8
	add xhl, 0x95C00
	ret

__pad_F614C1:
	.byte 0x00, 0x00

AccPlayback_CalcTimingPosition:
	ldda8 a, 13562
	inc 1, a
	xor w, w
	stda16 14106, xwa
	calr ToneGen_StepFwd_Alternate
	jr AccTiming_ComputeOffset
	ldb a, 0x20
	cpdi8 13563, 4
	jr c, AccTiming_StorePartA

AccTiming_StorePartA:
	stda8 14108, a

AccTiming_ComputeOffset:
	ldda8 w, 13563
	ldb a, 0x8
	muls8rr a, w
	ld h, a
	ldda8 a, 13564
	xor w, w
	ldb l, 0xC
	div8rr a, l
	add h, a
	inc 1, h
	ldda8 a, 13562
	subda8 a, 14150
	ldb w, 0x20
	cpdi8 13529, 5
	jr c, AccTiming_UseFullBar
	ldb w, 0x40

AccTiming_UseFullBar:
	muls8rr a, w
	add h, a
	stda8 14095, h
	jr AccTiming_CompareStyles
	cp h, 0x20
	jr ule, AccTiming_StoreResult
	sub h, 0x20

AccTiming_StoreResult:
	stda8 14095, h

AccTiming_CompareStyles:
	ldda8 a, 36150
	cpda8 a, 36152
	jr nz, AccTiming_Return

AccTiming_Return:
	ret

__pad_F6152D:
	.byte 0x00, 0x00

AccPlayback_AdjustBeatPosition:
	ldda16 xwa, 14106
	dec 1, a
	bitda 7, 14099
	jr z, AccBeatAdj_CheckBit6
	inc 1, a
	cpda8 a, 13527
	jr ule, AccBeatAdj_CheckBit6
	ldb a, 0x0

AccBeatAdj_CheckBit6:
	bitda 6, 14099
	jr z, AccBeatAdj_StoreAndClear
	dec 1, a
	cp a, 0xFF
	jr nz, AccBeatAdj_StoreAndClear
	ldda8 a, 13527

AccBeatAdj_StoreAndClear:
	stda8 13562, a
	stdi8 13564, 0
	stdi8 13563, 0
	ret

__pad_F61565:
	.byte 0x00, 0x00

AccVoice_InitPatternBuffer:
	ld xhl, 0x372E
	lds wa, 0
	push xwa
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	call AccAudio_LockAcquire
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	pop xwa
	ld (xhl), wa
	ld (xhl + 2), wa
	ld (xhl + 4), wa
	ld (xhl + 6), wa
	ld (xhl + 8), wa
	ld (xhl + 10), wa
	ld (xhl + 12), wa
	ld (xhl + 14), wa
	calr AccPlayback_InitPartAssignment
	ldda8 a, 14150
	ldda8 w, 13529
	muls8rr a, w
	ld c, a
	jr ToneGen_SkipToNoteEntry
	ldda8 a, 13562
	ldda8 w, 13529
	muls8rr a, w
	ld c, a
	cpdi8 13529, 5
	jr c, ToneGen_SkipToNoteEntry
	cpdi8 13563, 4
	jr c, ToneGen_SkipToNoteEntry
	add c, 0x4

ToneGen_SkipToNoteEntry:
	pushw bc
	calr ToneGen_GetSlotIndex
	ld de, hl
	calr ToneGen_CalcBufferAddr
	lds32 xix, 6
	add xix, xhl
	popw bc

ToneGen_SkipLoop:
	cps c, 0
	jr z, ToneGen_ParseAllEvents
	ld a, (xix)
	cp a, 0x81
	jr nz, ToneGen_SkipLoop_ReadNext
	dec 1, c

ToneGen_SkipLoop_ReadNext:
	calr ToneGen_ReadBufferWithIndirection
	jr ToneGen_SkipLoop

ToneGen_ParseAllEvents:
	stdi8 13582, 0
	ldda8 c, 14142
	calr ToneGen_ParseEventBuffer
	incdi8 1, 13582
	ldda8 c, 14143
	calr ToneGen_ParseEventBuffer
	incdi8 1, 13582
	ldda8 c, 14144
	calr ToneGen_ParseEventBuffer
	incdi8 1, 13582
	ldda8 c, 14145
	calr ToneGen_ParseEventBuffer
	ldda8 a, 36150
	cpda8 a, 36152
	jr nz, ToneGen_SaveRegsAndCall
	stdi8 58336, 16

ToneGen_SaveRegsAndCall:
	push xwa
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	call AccAudio_LockRelease
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	pop xwa
	ret

__pad_F61634:
	.byte 0x00, 0x00

ToneGen_ParseEventBuffer:
	stdi8 13583, 0

EventBuffer_ParseLoop:
	cps c, 0
	jr nz, EventBuffer_ReadByte
	jrl ToneGen_ParseEvent_Done

EventBuffer_ReadByte:
	ld a, (xix)
	cp a, 0x81
	jr nz, EventBuffer_CheckNoteType
	dec 1, c
	incdi8 1, 13583
	calr ToneGen_ReadBufferWithIndirection
	jr EventBuffer_ParseLoop

EventBuffer_CheckNoteType:
	cp a, 0x90
	jr z, ToneGen_MapNoteToOctaveBitmask
	cp a, 0x91
	jr z, ToneGen_MapNoteToOctaveBitmask
	cp a, 0xD1
	jr z, ToneGen_MapNoteToOctaveBitmask
	cp a, 0xD2
	jr z, ToneGen_MapNoteToOctaveBitmask
	cp a, 0xD3
	jr z, ToneGen_MapNoteToOctaveBitmask
	cp a, 0xD4
	jr z, ToneGen_MapNoteToOctaveBitmask
	cp a, 0xD5
	jr z, ToneGen_MapNoteToOctaveBitmask
	cp a, 0xD6
	jr z, ToneGen_MapNoteToOctaveBitmask
	calr ToneGen_ReadBufferWithIndirection
	jr EventBuffer_ParseLoop

ToneGen_MapNoteToOctaveBitmask:
	calr ToneGen_ReadBufferWithIndirection
	ld a, (xix)
	xor w, w
	ldb l, 0xC
	div8rr a, l
	pushw bc
	push xix
	and a, 0x7
	ld c, a
	xor b, b
	ld xix, 0xF616A1
	ld_srib3 C, 0x07, 0xF0, 0xE4
	jr ToneGen_MapNote_OrMask
	; Bit mask lookup table (powers of 2):
	.byte 0x01
	push_sr
	.byte 0x04
	ldio	16, 32
	.byte 0x40, 0x80

ToneGen_MapNote_OrMask:
	ldda8 l, 13583
	xor h, h
	ldda8 a, 13582
	and a, 0x3
	sla a, 2
	add l, a
	ld xix, 0x372E
	ld_srib3 A, 0x07, 0xF0, 0xEC
	or a, c
	lda_dri3 XBC, 0x07, 0xF0, 0xEC
	pop xix
	popw bc
	calr ToneGen_ReadBufferWithIndirection
	jrl EventBuffer_ParseLoop

ToneGen_ParseEvent_Done:
	ret

__pad_F616D5:
	.byte 0x00, 0x00

AccPlayback_ProcessStyleChanges:
	stdi8 14095, 1
	stdi8 14098, 4
	stdi8 14103, 255
	push xwa
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	call UI_PostTimerResetEvent
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	pop xwa
	ldb a, 0x0
	stda8 13559, a
	stda8 13563, a
	stda8 13564, a
	ldda16 xwa, 14106
	dec 1, a
	stda8 13562, a
	call AccPatch_GetCurrentSlotAddr
	calr AccPlayback_CalcTimingPosition
	calr AccVoice_InitPatternBuffer
	ret

AccStyleChange_CheckPartCount:
	.byte 0x00, 0x00

AccPlayback_ProcessPartChanges:
	anddi8 13602, 115
	cpdi8 13564, 0
	jr nz, AccPartChange_Bit1
	ordi8 13602, 4

AccPartChange_Bit1:
	bitda 0, 14099
	jr nz, AccPartChange_CheckBit2
	calr ToneGen_ProcessWithRestore
	jrl ToneGen_UpdateAndInitPattern

AccPartChange_CheckBit2:
	bitda 5, 13520
	jr z, AccPartChange_Done
	calr ToneGen_ScanRestoredVoiceEvents
	jr AccPartChange_ProcessBit2

AccPartChange_Done:
	call AccPatch_GetCurrentSlotAddr
	calr ToneGen_ProcessVoiceSlots

AccPartChange_ProcessBit2:
	calr ToneGen_CalcNoteWithWrap
	cp bc, wa
	jr ugt, AccPartChange_StoreResult
	jr __pad_F61760

AccPartChange_StoreResult:
	anddi8 13520, 223

ToneGen_CalcAndRestart:
	calr ToneGen_RecalcAndRestart
	jrl ToneGen_UpdateAndInitPattern

__pad_F61760:
	ldda16 xwa, 13419
	stda16 13588, xwa
	ldda16 xwa, 13385
	stda16 13586, xwa
	ordi8 13520, 32
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ldda16 xwa, 13385
	ld_srib3 A, 0x07, 0xEC, 0xE0
	cp a, 0x81
	jr nz, ToneGen_PushAndReadType
	calr ToneGen_StepToNextVoiceSlot
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ldda16 xwa, 13385
	ld_srib3 A, 0x07, 0xEC, 0xE0
	cp a, 0x90
	jr z, ToneGen_ProcessVoiceEvent
	cp a, 0x91
	jr z, ToneGen_ProcessVoiceEvent
	cp a, 0xD1
	jr z, ToneGen_ProcessVoiceEvent
	cp a, 0xD2
	jr z, ToneGen_ProcessVoiceEvent
	cp a, 0xD3
	jr z, ToneGen_ProcessVoiceEvent
	cp a, 0xD4
	jr z, ToneGen_ProcessVoiceEvent
	cp a, 0xD5
	jr z, ToneGen_ProcessVoiceEvent
	cp a, 0xD6
	jr z, ToneGen_ProcessVoiceEvent
	jr ToneGen_CalcAndRestart

ToneGen_ProcessVoiceEvent:
	calr AccVoice_ReadCurrentToneType
	cps a, 0
	jr nz, ToneGen_CalcAndRestart
	ldda16 xwa, 13419
	stda16 13588, xwa
	ldda16 xwa, 13385
	stda16 13586, xwa
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ldda16 xwa, 13385
	ld_srib3 A, 0x07, 0xEC, 0xE0
	pushw wa
	push xhl
	calr ToneGen_AdvancePeriodWrap
	pop xhl
	popw wa

ToneGen_PushAndReadType:
	pushw wa
	calr AccVoice_ReadCurrentToneType
	ld w, a
	stda8 13564, w
	popw wa
	calr ToneGen_ClassifyAndDispatch

ToneGen_UpdateAndInitPattern:
	anddi8 13519, 127
	calr AccPlayback_CalcTimingPosition
	call AccPatch_GetCurrentSlotAddr
	calr AccVoice_InitPatternBuffer
	ordi8 58336, 16
	ret

ToneGen_VoiceSlotLookupTable:
	nop
	nop
	nop
	adc	iy, (xix)
	nop
	.byte 0x96, 0x00
	nop
	nop
	.byte 0x97, 0x00
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x98

ToneGen_ProcessWithRestore:
	bitda 5, 13520
	jr z, ToneGen_ProcessRestore_Direct
	calr ToneGen_RestoreFromSavedPos
	jr ToneGen_ProcessRestore_CalcPos

ToneGen_ProcessRestore_Direct:
	call AccPatch_GetCurrentSlotAddr
	calr ToneGen_ProcessVoiceSlots
	anddi8 13602, 254

ToneGen_ProcessRestore_CalcPos:
	calr ToneGen_CalcNotePosition
	ldda16 xbc, 13600
	cp bc, wa
	jr c, ToneGen_ProcessRestore_CheckDelta
	sub bc, wa
	cp bc, 0x200
	jr ugt, ToneGen_ProcessRestore_CheckDelta
	jr ToneGen_ProcessRestore_UseSaved

ToneGen_ProcessRestore_CheckDelta:
	cps bc, 0
	jr nz, ToneGen_ProcessRestore_ClearBit5
	bitda 3, 13602
	jr z, ToneGen_ProcessRestore_ClearBit5
	jr ToneGen_ProcessRestore_UseSaved

ToneGen_ProcessRestore_ClearBit5:
	anddi8 13520, 223

ToneGen_ProcessRestore_CalcNote:
	ldda8 a, 13564
	ld e, a
	xor w, w
	ldb l, 0xC
	div8rr a, l
	cps w, 0
	jr nz, ToneGen_ProcessRestore_AdjNote
	ldb w, 0xC

ToneGen_ProcessRestore_AdjNote:
	calr ToneGen_AdjustNoteWrap
	ldb a, 0x4
	stda8 14098, a
	ldb w, 0xFF
	stdi8 14103, 255
	jr ToneGen_ProcessRestore_Return

ToneGen_ProcessRestore_UseSaved:
	bitda 0, 13602
	jr nz, ToneGen_ProcessRestore_UseActive
	ldda16 xwa, 13594
	stda16 13588, xwa
	stda16 13419, xwa
	ldda16 xwa, 13598
	stda16 13586, xwa
	stda16 13385, xwa
	jr ToneGen_ProcessRestore_SetBit5

ToneGen_ProcessRestore_UseActive:
	ldda16 xwa, 13419
	stda16 13588, xwa
	ldda16 xwa, 13385
	stda16 13586, xwa

ToneGen_ProcessRestore_SetBit5:
	ordi8 13520, 32
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ld_srib3 A, 0x07, 0xEC, 0xE0
	cp a, 0x81
	jr nz, ToneGen_ProcessRestore_ReadType
	bitda 7, 13519
	jr z, ToneGen_ProcessRestore_JumpCalc
	anddi8 13520, 223
	anddi8 13519, 127

ToneGen_ProcessRestore_JumpCalc:
	jr ToneGen_ProcessRestore_CalcNote

ToneGen_ProcessRestore_ReadType:
	pushw wa
	calr AccVoice_ReadCurrentToneType
	ldda8 w, 13564
	sub w, a
	jr nc, ToneGen_ProcessRestore_WrapOctave
	add w, 0x60

ToneGen_ProcessRestore_WrapOctave:
	ldda8 e, 13564
	calr ToneGen_AdjustNoteWrap
	popw wa
	calr ToneGen_ClassifyAndDispatch

ToneGen_ProcessRestore_Return:
	ret

__pad_F618FF:
	.byte 0x00, 0x00

ToneGen_RestoreFromSavedPos:
	ldda16 xiy, 13586
	stda16 13385, xiy
	ldda16 xwa, 13588
	stda16 13419, xwa
	ldb a, 0x0
	stda8 13365, a
	anddi8 13602, 253
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ldda16 xwa, 13385
	ld_srib3 A, 0x07, 0xEC, 0xE0
	cp a, 0x81
	jr nz, ToneGen_EventDispatchLoop
	ordi8 13602, 2
	anddi8 13602, 251

ToneGen_EventDispatchLoop:
	calr ToneGen_StepVoiceForward
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ldda16 xwa, 13385
	ld_srib3 A, 0x07, 0xEC, 0xE0
	bit 7, a
	jr z, ToneGen_EventDispatchLoop
	cp a, 0x81
	jrl z, ToneGen_Velocity_HandleEnd
	cp a, 0x83
	jr z, ToneGen_EventDisp_EndOfBlock
	cp a, 0x90
	jr z, ToneGen_CalcEventVelocity_WithFlags
	cp a, 0x91
	jr z, ToneGen_CalcEventVelocity_WithFlags
	cp a, 0xD1
	jr z, ToneGen_CalcEventVelocity_WithFlags
	cp a, 0xD2
	jr z, ToneGen_CalcEventVelocity_WithFlags
	cp a, 0xD3
	jr z, ToneGen_CalcEventVelocity_WithFlags
	cp a, 0xD4
	jr z, ToneGen_CalcEventVelocity_WithFlags
	cp a, 0xD5
	jr z, ToneGen_CalcEventVelocity_WithFlags
	cp a, 0xD6
	jr z, ToneGen_CalcEventVelocity_WithFlags
	jr ToneGen_EventDispatchLoop

ToneGen_EventDisp_EndOfBlock:
	call AccPatch_GetCurrentSlotAddr
	calr ToneGen_GetSlotIndex
	stda16 13419, xhl
	calr ToneGen_CalcBufferAddr
	lds ix, 6
	stda16 13385, xix
	stdi8 13365, 6
	jr ToneGen_EventDispatchLoop

ToneGen_CalcEventVelocity_WithFlags:
	calr AccVoice_ReadCurrentToneType
	ld c, a
	ldda8 b, 13563
	bitda 1, 13602
	jr z, ToneGen_Velocity_SkipDec
	dec 1, b
	cp b, 0xFF
	jr nz, ToneGen_Velocity_SkipDec
	ldda8 b, 13529
	dec 1, b
	ldda8 a, 13529
	ldda8 w, 13562
	dec 1, w
	cp w, 0xFF
	jr nz, ToneGen_Velocity_Multiply
	ldda8 w, 13527

ToneGen_Velocity_Multiply:
	muls8rr a, w
	add b, a
	jr ToneGen_Velocity_Store

ToneGen_Velocity_SkipDec:
	jr VoiceVelocity_CalcDone

ToneGen_Velocity_HandleEnd:
	bitda 7, 13602
	jr nz, VoiceVelocity_CalcDone
	bitda 2, 13602
	jr z, ToneGen_Velocity_DefaultCalc
	ordi8 13602, 2
	ordi8 13602, 128
	jrl ToneGen_EventDispatchLoop

ToneGen_Velocity_DefaultCalc:
	ldb c, 0x0
	ldda8 b, 13563
	dec 1, b
	cp b, 0xFF
	jr nz, VoiceVelocity_CalcDone
	ldda8 b, 13529
	dec 1, b

VoiceVelocity_CalcDone:
	ldda8 a, 13529
	ldda8 w, 13562
	muls8rr a, w
	add b, a

ToneGen_Velocity_Store:
	stda16 13600, xbc
	ordi8 13602, 1
	ret

__pad_F61A1C:
	.byte 0x00, 0x00

ToneGen_CalcNotePosition:
	ldda8 a, 13564
	ld e, a
	xor w, w
	ldb l, 0xC
	div8rr a, l
	ldda8 d, 13563
	ld bc, wa
	ldda8 a, 13529
	ldda8 w, 13562
	muls8rr a, w
	add d, a
	ld wa, bc
	cps w, 0
	jr nz, ToneGen_CalcPos_SubOctave
	ldb w, 0xC

ToneGen_CalcPos_SubOctave:
	ld a, e
	sub a, w
	jr nc, ToneGen_CalcPos_Return
	add a, 0x60
	dec 1, d
	cp d, 0xFF
	jr nz, ToneGen_CalcPos_Return
	ldda8 d, 13529
	dec 1, d
	ordi8 13602, 8

ToneGen_CalcPos_Return:
	ld w, d
	ret

__pad_F61A62:
	.byte 0x00, 0x00

ToneGen_AdjustNoteWrap:
	ld a, e
	sub a, w
	jr c, ToneGen_AdjWrap_AddOctave
	stda8 13564, a
	jr SustainLevel_SetExit

ToneGen_AdjWrap_AddOctave:
	add a, 0x60
	stda8 13564, a
	ldda8 a, 13563
	dec 1, a
	cp a, 0xFF
	jr z, ToneGen_AdjWrap_WrapBar
	stda8 13563, a
	jr SustainLevel_SetExit

ToneGen_AdjWrap_WrapBar:
	ldda8 a, 13529
	dec 1, a
	stda8 13563, a
	ldda8 a, 13562
	dec 1, a
	cp a, 0xFF
	jr z, ToneGen_AdjWrap_WrapMeasure
	stda8 13562, a
	jr SustainLevel_SetExit

ToneGen_AdjWrap_WrapMeasure:
	ldda8 a, 13527
	and a, 0x7
	stda8 13562, a

SustainLevel_SetExit:
	ret

__pad_F61AAF:
	.byte 0x00, 0x00

ToneGen_ScanRestoredVoiceEvents:
	ldda16 xiy, 13586
	stda16 13385, xiy
	ldda16 xwa, 13588
	stda16 13419, xwa
	ldb a, 0x0
	stda8 13365, a

ToneGen_ScanRestored_Loop:
	calr ToneGen_StepToNextVoiceSlot
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ldda16 xwa, 13385
	ld_srib3 A, 0x07, 0xEC, 0xE0
	cp a, 0x81
	jrl z, ToneGen_ScanRestored_EndMarker
	cp a, 0x83
	jr z, ToneGen_ScanRestored_EndBlock
	cp a, 0x90
	jr z, ToneGen_CalcEventVelocity_Restored
	cp a, 0x91
	jr z, ToneGen_CalcEventVelocity_Restored
	cp a, 0xD1
	jr z, ToneGen_CalcEventVelocity_Restored
	cp a, 0xD2
	jr z, ToneGen_CalcEventVelocity_Restored
	cp a, 0xD3
	jr z, ToneGen_CalcEventVelocity_Restored
	cp a, 0xD4
	jr z, ToneGen_CalcEventVelocity_Restored
	cp a, 0xD5
	jr z, ToneGen_CalcEventVelocity_Restored
	cp a, 0xD6
	jr z, ToneGen_CalcEventVelocity_Restored
	jr ToneGen_ScanRestored_Loop

ToneGen_ScanRestored_EndBlock:
	call AccPatch_GetCurrentSlotAddr
	calr ToneGen_GetSlotIndex
	stda16 13419, xhl
	calr ToneGen_CalcBufferAddr
	lds ix, 6
	stda16 13385, xix
	stdi8 13365, 6
	jr ToneGen_ScanRestored_Loop

ToneGen_CalcEventVelocity_Restored:
	calr AccVoice_ReadCurrentToneType
	ld c, a
	ldda8 b, 13563
	ldda8 a, 13529
	ldda8 w, 13562
	muls8rr a, w
	add b, a
	jr ToneGen_ScanRestored_Return

ToneGen_ScanRestored_EndMarker:
	ldb c, 0x0
	ldda8 b, 13563
	inc 1, b
	ldda8 a, 13529
	ldda8 w, 13562
	muls8rr a, w
	add b, a

ToneGen_ScanRestored_Return:
	ret

__pad_F61B56:
	.byte 0x00, 0x00

ToneGen_GetSlotIndex:
	ldda8 a, 14235
	and a, 0x1F
	cps a, 0
	jr nz, ToneGen_GetSlot_Lookup
	or a, 0x10
	stda8 14235, a

ToneGen_GetSlot_Lookup:
	call MapBitFlagsToChannelOffset
	ld l, w
	xor h, h
	ld_sriw3 HL, 0x07, 0xF4, 0xEC
	ret

__pad_F61B78:
	.byte 0x00, 0x00

ToneGen_CalcNoteWithWrap:
	ldda8 a, 13564
	ld e, a
	xor w, w
	ldb l, 0xC
	div8rr a, l
	ld a, e
	sub a, w
	add a, 0xC
	ldda8 w, 13563
	cp a, 0x60
	jr nz, ToneGen_CalcWrap_Store
	ldb a, 0x0
	inc 1, w

ToneGen_CalcWrap_Store:
	ld hl, wa
	ldda8 a, 13529
	ldda8 w, 13562
	muls8rr a, w
	add h, a
	ld wa, hl
	ret

__pad_F61BAB:
	.byte 0x00, 0x00

ToneGen_RecalcAndRestart:
	ldda8 a, 13564
	ld e, a
	xor w, w
	ldb l, 0xC
	div8rr a, l
	ld a, e
	sub a, w
	add a, 0xC
	calr ToneGen_StoreNoteOrWrap
	stdi8 14098, 4
	stdi8 14103, 255
	ret

__pad_F61BCE:
	.byte 0x00, 0x00

ToneGen_StoreNoteOrWrap:
	cp a, 0x60
	jr z, ToneGen_AdvancePeriodWrap
	stda8 13564, a
	jr PitchValidate_Exit

ToneGen_AdvancePeriodWrap:
	stdi8 13564, 0
	ldda8 a, 13563
	inc 1, a
	cpda8 a, 13529
	jr z, ToneGen_PeriodWrap_NextBar
	stda8 13563, a
	jr PitchValidate_Exit

ToneGen_PeriodWrap_NextBar:
	stdi8 13563, 0
	ldda8 a, 13562
	inc 1, a
	ldda8 w, 13527
	and w, 0x7
	inc 1, w
	cp a, w
	jr z, ToneGen_PeriodWrap_ResetBar
	stda8 13562, a
	jr PitchValidate_Exit

ToneGen_PeriodWrap_ResetBar:
	stdi8 13562, 0

PitchValidate_Exit:
	ret

__pad_F61C16:
	.byte 0x00, 0x00

ToneGen_ClassifyAndDispatch:
	cp a, 0xD1
	jr z, ToneGen_ClassifyStereoType
	cp a, 0xD2
	jr z, ToneGen_ClassifyStereoType
	cp a, 0xD3
	jr z, ToneGen_ClassifyStereoType
	cp a, 0xD4
	jr z, ToneGen_ClassifyStereoType
	cp a, 0xD5
	jr z, ToneGen_ClassifyStereoType
	cp a, 0xD6
	jr z, ToneGen_ClassifyStereoType
	calr ToneGen_ClassifyMonoEvent
	jr ToneGen_Classify_Return

ToneGen_ClassifyStereoType:
	calr ToneGen_ClassifyStereoEvent

ToneGen_Classify_Return:
	ret

__pad_F61C3F:
	.byte 0x00, 0x00

ToneGen_ClassifyStereoEvent:
	ldb a, 0x5
	stda8 14098, a
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ldda16 xwa, 13385
	ld_srib3 A, 0x07, 0xEC, 0xE0
	ldb e, 0x1
	cp a, 0xD2
	jr z, ToneGen_ClassifyStereoSlot_Common
	ldb e, 0x2
	cp a, 0xD1
	jr z, ToneGen_ClassifyStereoSlot_Common
	ldb e, 0x3
	cp a, 0xD3
	jr z, ToneGen_ClassifyStereoSlot_Common
	ldb e, 0x4
	cp a, 0xD4
	jr z, ToneGen_ClassifyStereoSlot_Common
	ldb e, 0x5
	cp a, 0xD5
	jr z, ToneGen_ClassifyStereoSlot_Common
	ldb e, 0x6

ToneGen_ClassifyStereoSlot_Common:
	stda8 14112, e
	calr ToneGen_StepToNextStereoSlot
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ldda16 xwa, 13385
	ld_srib3 A, 0x07, 0xEC, 0xE0
	stda8 14113, a
	ret

__pad_F61C98:
	.byte 0x00, 0x00

ToneGen_ClassifyMonoEvent:
	ldb a, 0x4
	stda8 14098, a
	calr ToneGen_StepToNextStereoSlot
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ldda16 xwa, 13385
	ld_srib3 A, 0x07, 0xEC, 0xE0
	stda8 14104, a
	calr ToneGen_StepToNextVoiceSlot
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ldda16 xwa, 13385
	ld_srib3 W, 0x07, 0xEC, 0xE0
	stda8 14103, w
	ldda8 a, 14104
	ld de, wa
	ldda8 a, 14235
	and a, 0x1F
	cps a, 0
	jr nz, ToneGen_ClassifyMono_MapChannel
	or a, 0x10
	stda8 14235, a

ToneGen_ClassifyMono_MapChannel:
	ld l, a
	xor h, h
	ld xiy, 0xF6181A
	ld_srib3 A, 0x07, 0xF4, 0xEC
	cpdi8 13592, 0
	jr z, ToneGen_ClassifyMono_WriteNew
	pushw de
	pushw wa
	ldda8 a, 13590
	pushw wa
	call RhythmBuf_WriteByte
	inc 2, xsp
	ldda8 a, 13591
	pushw wa
	call RhythmBuf_WriteByte
	inc 2, xsp
	ldb a, 0x0
	pushw wa
	call RhythmBuf_WriteByte
	inc 2, xsp
	popw wa
	popw de

ToneGen_ClassifyMono_WriteNew:
	pushw de
	pushw wa
	pushw wa
	call RhythmBuf_WriteByte
	inc 2, xsp
	ld a, e
	pushw wa
	call RhythmBuf_WriteByte
	inc 2, xsp
	ld a, d
	pushw wa
	call RhythmBuf_WriteByte
	inc 2, xsp
	popw wa
	popw de
	stda8 13590, a
	stda8 13591, e
	ldb a, 0x10
	stda8 13592, a
	bitda 4, 14235
	jr z, ToneGen_ClassifyMono_Return
	ldda8 a, 14104
	ldda8 w, 64446
	push xwa
	push xbc
	push xde
	push xix
	push xiy
	ld e, a
	xor d, d
	ld c, w
	xor b, b
	lds wa, 1
	call Param_SignExtendReturn
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xwa
	ld a, l
	stda8 14104, a

ToneGen_ClassifyMono_Return:
	ret

__pad_F61D76:
	.byte 0x00, 0x00

AccPlayback_ReadEventLoop:
	anddi8 13520, 127

AccPlayback_ReadEvt_CheckEmpty:
	call AccPatch_CheckEmpty
	cps wa, 0
	jr z, AccPlayback_ReadEvt_CheckBit7
	bitda 7, 13520
	jr nz, AccPlayback_ReadEvt_CheckBit7
	call TempoRingBuf_ReadByteToA
	cp a, 0x90
	jr nz, AccPlayback_ReadEvt_Continue
	calr AccPlayback_ProcessNoteOnEvent

AccPlayback_ReadEvt_Continue:
	jr AccPlayback_ReadEvt_CheckEmpty

AccPlayback_ReadEvt_CheckBit7:
	bitda 7, 13520
	jr z, ToneGenSetup_Done
	cpdi16 13524, 0
	jr nz, AccPlayback_ReadEvt_HasEntries
	stdi8 32578, 15
	stdi8 58332, 238
	stdi8 58334, 64
	anddi8 13520, 127
	ldb a, 0x8
	call MIDI_SendSysExCmd
	jr ToneGenSetup_Done

AccPlayback_ReadEvt_HasEntries:
	anddi8 13520, 223
	calr ToneGen_CalcTempo
	bitda 4, 14235
	jr z, AccPlayback_ReadEvt_Overflow
	calr AccPlayback_NoteOn_Check91
	jr AccPlayback_ReadEvt_OverflowOK

AccPlayback_ReadEvt_Overflow:
	calr AccPlayback_AdvPattern_Loop

AccPlayback_ReadEvt_OverflowOK:
	call AccPatch_GetCurrentSlotAddr
	calr AccPlayback_ProcessOngoingEvents
	calr ToneGen_AdvanceByTempo
	calr AccPlayback_CalcTimingPosition
	call AccPatch_GetCurrentSlotAddr
	calr AccVoice_InitPatternBuffer
	stdi8 14098, 4
	stdi8 14103, 255
	ldda8 a, 36150
	cpda8 a, 36152
	jr nz, ToneGenSetup_Done
	stdi8 58336, 16

ToneGenSetup_Done:
	ret

AccPlayback_ReadEvt_Return:
	.byte 0x00, 0x00

AccPlayback_ProcessNoteOnEvent:
	call TempoRingBuf_ReadByteToA
	call TempoRingBuf_ReadByteToA
	stda8 13357, a
	call TempoRingBuf_ReadByteToA
	stda8 13358, a
	call TempoRingBuf_ReadByteToA
	cpdi8 13358, 0
	jr nz, AccPlayback_NoteOn_ReadParams
	jr AccPlayback_NoteOn_WriteVoice

AccPlayback_NoteOn_ReadParams:
	ldda8 l, 13565
	cps l, 5
	jr ugt, AccPlayback_NoteOn_Store
	xor h, h
	ld xiy, 0x3500
	ldda8 a, 13357
	lda_dri3 XBC, 0x07, 0xF4, 0xEC
	ldda8 a, 13358
	pushw hl
	add hl, 0x6
	lda_dri3 XBC, 0x07, 0xF4, 0xEC
	popw hl
	inc 1, l
	stda8 13565, l
	cpda8 l, 13566
	jr ule, AccPlayback_NoteOn_Store
	stda8 13566, l

AccPlayback_NoteOn_Store:
	jr TimeoutCounter_CheckExit

AccPlayback_NoteOn_WriteVoice:
	ldda8 a, 13565
	dec 1, a
	cp a, 0xFF
	jr z, TimeoutCounter_CheckExit
	stda8 13565, a
	cps a, 0
	jr nz, TimeoutCounter_CheckExit
	ordi8 13520, 128

TimeoutCounter_CheckExit:
	ret

AccPlayback_NoteOn_SetBit:
	.byte 0x00, 0x00

AccPlayback_NoteOn_Check91:
	lds wa, 0
	stda16 13834, xwa
	ldda8 e, 13566
	xor h, h
	ld xix, 0x3500
	ld xiy, 0x366A

AccPlayback_NoteOn_WritePan:
	cps e, 0
	jr z, AccPlayback_NoteOn_Return
	ld l, e
	dec 1, l
	adddi16 13834, 6
	ld (xiy), 0x90
	inc 1, xiy
	calr ToneGen_WriteVoiceEventEntry
	dec 1, e
	jr AccPlayback_NoteOn_WritePan

AccPlayback_NoteOn_Return:
	ret

__pad_F61EAF:
	.byte 0x00, 0x00

ToneGen_WriteVoiceEventEntry:
	ldda8 a, 13564
	ld (xiy), a
	inc 1, xiy
	ld_srib3 A, 0x07, 0xF0, 0xEC
	ld (xiy), a
	inc 1, xiy
	pushw hl
	add hl, 0x6
	ld_srib3 A, 0x07, 0xF0, 0xEC
	ld (xiy), a
	popw hl
	inc 1, xiy
	ldda8 a, 13357
	ld (xiy), a
	inc 1, xiy
	ldda8 a, 13358
	ld (xiy), a
	inc 1, xiy
	ret

AccPlayback_AdvancePattern:
	.byte 0x00, 0x00

AccPlayback_AdvPattern_Loop:
	lds wa, 0
	stda16 13834, xwa
	ldda8 e, 13566
	xor h, h
	ld xix, 0x3500
	ld xiy, 0x366A

AccPlayback_AdvPattern_Check81:
	cps e, 0
	jr z, AccPlayback_AdvPattern_Nop
	ld l, e
	dec 1, l
	calr AccPlayback_AdvanceRingBuffer
	bitda 0, 13361
	jr nz, AccPlayback_AdvPattern_Check90
	adddi16 13834, 6
	ld (xiy), 0x90
	inc 1, xiy
	calr ToneGen_WriteVoiceEventEntry
	jr AccPlayback_AdvPattern_Done

AccPlayback_AdvPattern_Check90:
	adddi16 13834, 8
	ld (xiy), 0x91
	inc 1, xiy
	calr ToneGen_WriteVoiceEventEntry
	ldda8 a, 13362
	ld (xiy), a
	inc 1, xiy
	ldda8 a, 13363
	ld (xiy), a
	inc 1, xiy

AccPlayback_AdvPattern_Done:
	dec 1, e
	jr AccPlayback_AdvPattern_Check81

AccPlayback_AdvPattern_Nop:
	ret

__pad_F61F3E:
	.byte 0x00, 0x00

AccPlayback_AdvanceRingBuffer:
	ldda8 a, 13545
	and a, 0xF
	cps a, 0
	jr z, AccPlayback_TrackPosition
	call AccPatch_ReadTransposeAmount
	cpda8 a, 14926
	jr ugt, __pad_F61F65
	sub_srib_mr A, 0x07, 0xF0, 0xEC
	jr nc, AccPlayback_AdvRingBuf_Return
	ldb a, 0xC
	add_srib_mr A, 0x07, 0xF0, 0xEC

AccPlayback_AdvRingBuf_Return:
	jr AccPlayback_TrackPosition

__pad_F61F65:
	ldb w, 0xC
	sub w, a
	add_srib_mr W, 0x07, 0xF0, 0xEC

AccPlayback_TrackPosition:
	ld_srib3 A, 0x07, 0xF0, 0xEC
	push xix
	xor w, w
	ld xix, 0xE46142
	ld_srib3 A, 0x07, 0xF0, 0xE0
	pop xix
	bitda 4, 13546
	jr z, __pad_F61FAC
	ld c, a
	push xix
	xor w, w
	ld xix, 0xF62004
	ld_srib3 A, 0x07, 0xF0, 0xE0
	pop xix
	bit 0, a
	jr z, AccPlayback_TrackPos_Return
	inc 1, c
	ld_srib3 A, 0x07, 0xF0, 0xEC
	inc 1, a
	lda_dri3 XBC, 0x07, 0xF0, 0xEC

AccPlayback_TrackPos_Return:
	ld a, c

__pad_F61FAC:
	bitda 6, 13546
	jr z, AccPlayback_TrackPos_WrapCheck
	bitda 3, 14235
	jr z, AccPlayback_TrackPos_WrapCheck
	jr AccPlayback_TrackPos_WrapDone

AccPlayback_TrackPos_WrapCheck:
	bitda 5, 13546
	jr z, ToneGen_LoadRhythmPatternParams
	bitda 3, 14235
	jr nz, ToneGen_LoadRhythmPatternParams

AccPlayback_TrackPos_WrapDone:
	cps a, 7
	jr nz, ToneGen_LoadRhythmPatternParams
	stdi8 13361, 1
	stdi8 13362, 3
	stdi8 13363, 0
	jr AccPlayback_StyleRecalc_Return

ToneGen_LoadRhythmPatternParams:
	xor xbc, xbc
	ld c, a
	sla a, 1
	add c, a
	push xix
	ld xix, 0xF62010
	add xix, xbc
	ld a, (xix)
	stda8 13361, a
	ld a, (xix + 1)
	stda8 13362, a
	ld a, (xix + 2)
	stda8 13363, a
	pop xix

AccPlayback_StyleRecalc_Return:
	ret

__pad_F62002:
	nop
	nop
	nop
	nop
	nop
	.byte 0x01
	nop
	nop
	.zero 8
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x01
	nop
	scf
	.byte 0x01
	nop
	scf
	nop
	nop
	nop
	.zero 8
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x01
	scf
	scf

AccPlayback_ProcessOngoingEvents:
	andmi8 (xiy + 15), 0x7F
	calr ToneGen_ProcessVoiceSlots
	ldda16 xwa, 13419
	stda16 13826, xwa
	xor w, w
	ldda8 a, 13365
	stda16 13828, xwa
	stda16 13381, xwa
	ldda16 xwa, 13826
	stda16 13383, xwa
	ldda16 xwa, 13834
	stda16 13387, xwa
	call AccPatch_InitSlotAndCopyData
	calr ToneGen_AdvanceSeqList
	stdi8 13566, 0
	bitda 0, 12931
	jr nz, ToneGen_NullRet
	cpdi8 13562, 0
	jr nz, ToneGen_NullRet
	cpdi8 13563, 0
	jr nz, ToneGen_NullRet
	cpdi8 13564, 48
	jr ugt, ToneGen_NullRet
	ordi8 13517, 128

ToneGen_NullRet:
	ret

AccPlayback_Ongoing_HandleType:
	.byte 0x00, 0x00

ToneGen_ProcessVoiceSlots:
	calr AccPlayback_Ongoing_AdvSlot
	calr ToneGen_GetSlotIndex
	stda16 13419, xhl
	calr ToneGen_CalcBufferAddr
	stdi16 13385, 6
	ldda8 a, 13562
	ldda8 w, 13529
	muls8rr a, w
	ld d, a
	ldda8 a, 13563
	add d, a
	ldda8 e, 13564
	anddi8 13044, 254
	xor bc, bc
	stdi8 13365, 6

AccPlayback_Ongoing_NoteOff:
	bitda 0, 13044
	jr z, AccPlayback_Ongoing_NoteOffDone
	jrl AccPlayback_Ongoing_Return

AccPlayback_Ongoing_NoteOffDone:
	ldda16 xiy, 13385
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ld_srib3 A, 0x07, 0xEC, 0xF4
	cp a, 0x81
	jr nz, AccPlayback_Ongoing_D2Type
	add b, 0x1
	xor c, c
	cp de, bc
	jr c, AccPlayback_Ongoing_D1Type
	calr ToneGen_StepToNextVoiceSlot
	jr AccPlayback_Ongoing_D1_Return

AccPlayback_Ongoing_D1Type:
	ordi8 13044, 1

AccPlayback_Ongoing_D1_Return:
	jr AccPlayback_Ongoing_NoteOff

AccPlayback_Ongoing_D2Type:
	calr AccVoice_ReadCurrentToneType
	ld c, a
	cp de, bc
	jr ule, AccPlayback_Ongoing_StoreDone
	calr __pad_F621A7
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ld_srib3 A, 0x07, 0xEC, 0xF4
	cp a, 0x90
	jr nz, AccPlayback_Ongoing_D2_Return
	calr ToneGen_StepToNextStereoSlot
	calr ToneGen_StepToNextStereoSlot
	calr ToneGen_StepToNextStereoSlot
	jr ToneGen_StepVoiceReturn

AccPlayback_Ongoing_D2_Return:
	cp a, 0x91
	jr nz, AccPlayback_Ongoing_WriteChan
	calr ToneGen_StepToNextStereoSlot
	calr ToneGen_StepToNextStereoSlot
	calr ToneGen_StepToNextStereoSlot
	calr ToneGen_StepToNextStereoSlot
	jr ToneGen_StepVoiceReturn

AccPlayback_Ongoing_WriteChan:
	cp a, 0xD1
	jr z, ToneGen_StepToNextStereoVoicePair
	cp a, 0xD2
	jr z, ToneGen_StepToNextStereoVoicePair
	cp a, 0xD3
	jr z, ToneGen_StepToNextStereoVoicePair
	cp a, 0xD4
	jr z, ToneGen_StepToNextStereoVoicePair
	cp a, 0xD5
	jr z, ToneGen_StepToNextStereoVoicePair
	cp a, 0xD6
	jr z, ToneGen_StepToNextStereoVoicePair
	jr AccPlayback_Ongoing_StorePan

ToneGen_StepToNextStereoVoicePair:
	calr ToneGen_StepToNextStereoSlot
	calr ToneGen_StepToNextVoiceSlot
	jr ToneGen_StepVoiceReturn

AccPlayback_Ongoing_StorePan:
	calr ToneGen_StepToNextVoiceSlot
	jr ToneGen_StepVoiceReturn

AccPlayback_Ongoing_StoreDone:
	ordi8 13044, 1

ToneGen_StepVoiceReturn:
	jrl AccPlayback_Ongoing_NoteOff

AccPlayback_Ongoing_Return:
	ret

__pad_F62169:
	.byte 0x00, 0x00

AccPlayback_Ongoing_AdvSlot:
	ldda16 xwa, 13832
	dec 1, a
	stda8 13596, a
	ld e, a
	ldda16 xwa, 13830
	stda16 13594, xwa
	ld hl, wa
	calr ToneGen_CalcBufferAddr
	ldda8 a, 13596
	xor w, w
	stda16 13598, xwa
	ldda8 a, 13527
	inc 1, a
	ldda8 w, 13529
	muls8rr a, w
	dec 1, a
	ld b, a
	xor c, c
	stda16 13600, xbc
	ret

AccPlayback_Ongoing_AdvDone:
	.byte 0x00, 0x00

__pad_F621A7:
	ldda16 xwa, 13419
	stda16 13594, xwa
	ldda8 a, 13365
	stda8 13596, a
	ldda16 xwa, 13385
	stda16 13598, xwa
	stda16 13600, xbc
	ret

AccPlayback_UpdateVoiceState:
	.byte 0x00, 0x00

ToneGen_AdvanceSeqList:
	calr ToneGen_InitPlaybackState
	ldda32 xhl, 13640
	ld wa, (xhl)
	cpda16 xwa, 13383
	jr z, AccPlayback_VoiceState_NoChange
	ldda16 xde, 13377
	calr ToneGen_SearchVoiceBuffer
	jr AccPlayback_VoiceState_Changed

AccPlayback_VoiceState_NoChange:
	ldda16 xde, 13377
	cpda16 xde, 13381
	jr c, AccPlayback_VoiceState_Changed
	ordi8 13520, 64

AccPlayback_VoiceState_Changed:
	bitda 6, 13520
	jr z, AccPlayback_VoiceState_Return
	ldda16 xwa, 13387
	add de, wa
	cp de, 0xFF
	jr nc, AccPlayback_VoiceState_CalcOff
	ldda16 xix, 13377
	ldda16 xwa, 13387
	add ix, wa
	ldda32 xhl, 13644
	ld (xhl), ix
	jr AccPlayback_VoiceState_Return

AccPlayback_VoiceState_CalcOff:
	ldda16 xhl, 13620
	calr ToneGen_CalcBufferAddr
	ld hl, (xhl + 3)
	ldda32 xix, 13640
	ld (xix), hl
	lds ix, 6
	sub de, 0xFF
	add ix, de
	ldda32 xhl, 13644
	ld (xhl), ix

AccPlayback_VoiceState_Return:
	ret

__pad_F62230:
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x9d, 0x32, 0x00
	nop
	.byte 0x9f, 0x32, 0x00
	nop
	nop
	nop
	nop
	nop
	.byte 0xa1, 0x32
	nop
	nop
	nop
	nop
	.zero 8
	nop
	nop
	.byte 0x9b, 0x32, 0x00
	nop
	nop
	nop
	.zero 24
	nop
	nop
	.byte 0x97, 0x32
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x8d, 0x32, 0x00
	nop
	.byte 0x8f, 0x32, 0x00
	nop
	nop
	nop
	nop
	nop
	.byte 0x91, 0x32
	.zero 8
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x8b, 0x32
	.zero 24
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x87, 0x32
	nop
	nop

ToneGen_SearchVoiceBuffer:
	call AccPatch_GetCurrentSlotAddr
	ldda8 a, 14235
	and a, 0x1F
	cps a, 0
	jr nz, ToneGen_SearchBuf_MapChannel
	or a, 0x10
	stda8 14235, a

ToneGen_SearchBuf_MapChannel:
	call MapBitFlagsToChannelOffset
	ld l, w
	xor h, h
	ld_sriw3 WA, 0x07, 0xF4, 0xEC

ToneGen_SearchBuf_CompareLoop:
	cpda16 xwa, 13383
	jr nz, ToneGen_SearchBuf_CheckEnd
	ordi8 13520, 64
	jr ToneGen_SearchBuf_Return

ToneGen_SearchBuf_CheckEnd:
	cpda16 xwa, 13620
	jr nz, ToneGen_SearchBuf_FollowChain
	jr ToneGen_SearchBuf_Return

ToneGen_SearchBuf_FollowChain:
	ld hl, wa
	calr ToneGen_CalcBufferAddr
	ld wa, (xhl + 3)
	jr ToneGen_SearchBuf_CompareLoop

ToneGen_SearchBuf_Return:
	ret

__pad_F622FD:
	.byte 0x00, 0x00

AccPlayback_ProcessBit5Change:
	bitda 5, 14099
	jr nz, AccBit5_CheckBit5Active
	jrl AccBit5_Return

AccBit5_CheckBit5Active:
	bitda 5, 13520
	jr nz, AccBit5_InitAndScan
	jrl FlagClear_Exit

AccBit5_InitAndScan:
	anddi8 13520, 223
	anddi8 13519, 127
	ldda16 xwa, 13588
	stda16 13419, xwa
	stda16 13914, xwa
	stda16 13616, xwa
	ldda16 xiy, 13586
	stda16 13387, xiy
	stda16 13385, xiy
	stda16 13920, xiy
	ld wa, iy
	stda8 13365, a
	ldda16 xiy, 13586
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ld_srib3 A, 0x07, 0xEC, 0xF4
	cp a, 0x81
	jrl z, FlagClear_Exit
	stdi8 13389, 6
	cp a, 0x90
	jr z, AccBit5_StepTwice
	stdi8 13389, 8
	cp a, 0x91
	jr z, AccBit5_StepOnce
	stdi8 13389, 3
	cp a, 0xD1
	jr z, AccVoice_InitPlaybackState
	cp a, 0xD2
	jr z, AccVoice_InitPlaybackState
	cp a, 0xD3
	jr z, AccVoice_InitPlaybackState
	cp a, 0xD4
	jr z, AccVoice_InitPlaybackState
	cp a, 0xD5
	jr z, AccVoice_InitPlaybackState
	cp a, 0xD6
	jr z, AccVoice_InitPlaybackState
	jr FlagClear_Exit

AccBit5_StepOnce:
	calr ToneGen_StepToNextStereoSlot

AccBit5_StepTwice:
	calr ToneGen_StepToNextStereoSlot
	calr ToneGen_StepToNextVoiceSlot

AccVoice_InitPlaybackState:
	calr ToneGen_StepToNextStereoSlot
	calr ToneGen_StepToNextVoiceSlot
	ldda16 xwa, 13419
	stda16 13912, xwa
	stda16 13618, xwa
	xor w, w
	ldda8 a, 13365
	stda16 13918, xwa
	calr ToneGen_ScanVoicePosition
	call AccPatch_CopySequenceEntry
	call AccPatch_GetCurrentSlotAddr
	calr AccVoice_InitPatternBuffer
	stdi8 14098, 4
	stdi8 14103, 255
	stdi8 58336, 16

FlagClear_Exit:
	anddi8 14099, 223

AccBit5_Return:
	ret

__pad_F623D8:
	.byte 0x00, 0x00

ToneGen_ScanVoicePosition:
	calr ToneGen_InitPlaybackState
	call AccPatch_GetCurrentSlotAddr
	calr ToneGen_GetSlotIndex
	ld de, hl
	calr ToneGen_CalcBufferAddr
	ldb c, 0x3
	lds iy, 3
	stdi8 13603, 0

ToneGen_ScanPos_CompareLoop:
	cpda16 xiy, 13387
	jr nz, ToneGen_ScanPos_CheckEnd
	cpda16 xde, 13616
	jr nz, ToneGen_ScanPos_CheckEnd
	ordi8 13603, 1
	jr VoiceState_CheckExit

ToneGen_ScanPos_CheckEnd:
	cpda16 xiy, 13385
	jr nz, VoiceState_CheckExit
	cpda16 xde, 13618
	jr nz, VoiceState_CheckExit
	ordi8 13603, 2

VoiceState_CheckExit:
	cpda16 xiy, 13377
	jr nz, ToneGen_ScanPos_AdvanceStep
	cpda16 xde, 13620
	jr nz, ToneGen_ScanPos_AdvanceStep
	jr ToneGen_ScanPos_ProcessFlags

ToneGen_ScanPos_AdvanceStep:
	calr ToneGen_AdvanceVoiceStep
	jr ToneGen_ScanPos_CompareLoop

ToneGen_ScanPos_ProcessFlags:
	ldda8 a, 13603
	and a, 0x3
	cps a, 0
	jr z, PlaybackState_InitDone
	bitda 1, 13603
	jr nz, ToneGen_ScanPos_AdjustBit1
	ldda16 xiy, 13387
	ldda32 xix, 13644
	ld (xix), iy
	ldda32 xix, 13640
	ld (xix), de
	stda8 13365, c
	jr PlaybackState_InitDone

ToneGen_ScanPos_AdjustBit1:
	ldda16 xiy, 13389
	and iy, 0xFF
	ld wa, iy
	sub c, a
	jr c, ToneGen_ScanPos_WrapBlock
	cps c, 6
	jr c, ToneGen_ScanPos_WrapBlock
	stda8 13365, c
	ldda32 xix, 13644
	ld wa, (xix)
	sub wa, iy
	ld (xix), wa
	ldda32 xix, 13640
	ld (xix), de
	jr PlaybackState_InitDone

ToneGen_ScanPos_WrapBlock:
	sub c, 0x7
	stda8 13365, c
	ld hl, de
	calr ToneGen_CalcBufferAddr
	ld wa, (xhl + 1)
	ldda32 xix, 13640
	ld (xix), wa
	xor w, w
	ld a, c
	ldda32 xix, 13644
	ld (xix), iy

PlaybackState_InitDone:
	ret

__pad_F62498:
	.byte 0x00, 0x00

ToneGen_InitPlaybackState:
	anddi8 13520, 191
	ldda8 a, 14235
	and a, 0x1F
	cps a, 0
	jr nz, ToneGen_InitPlay_SetupTables
	or a, 0x10
	stda8 14235, a

ToneGen_InitPlay_SetupTables:
	sla a, 2
	ld l, a
	xor h, h
	ld xix, 0xF62232
	ld_sril3 XIX, 0x07, 0xF0, 0xEC
	stda32 13640, xix
	ld xix, 0xF62276
	ld_sril3 XIX, 0x07, 0xF0, 0xEC
	stda32 13644, xix
	ld hl, (xix)
	stda16 13377, xhl
	ldda32 xix, 13640
	ld hl, (xix)
	stda16 13620, xhl
	ret

__pad_F624E5:
	.byte 0x00, 0x00

ToneGen_AdvanceVoiceStep:
	inc 1, iy
	inc 1, c
	cp c, 0xFF
	jr nz, ToneGen_AdvVoiceStep_Return
	ld hl, de
	calr ToneGen_CalcBufferAddr
	ld hl, (xhl + 3)
	ld de, hl
	calr ToneGen_CalcBufferAddr
	lds iy, 6
	ldb c, 0x6

ToneGen_AdvVoiceStep_Return:
	ret

__pad_F62502:
	.byte 0x00, 0x00

AccPlayback_ProcessTempoAdvance:
	bitda 2, 14099
	jr z, AccPlayback_TempoAdv_Return
	anddi8 13520, 223
	calr ToneGen_CalcTempo
	calr ToneGen_AdvanceByTempo
	calr AccPlayback_CalcTimingPosition
	call AccPatch_GetCurrentSlotAddr
	calr AccVoice_InitPatternBuffer
	stdi8 14098, 4
	stdi8 14103, 255
	stdi8 58336, 16
	anddi8 14099, 251

AccPlayback_TempoAdv_Return:
	ret

__pad_F62534:
	.byte 0x00, 0x00

ToneGen_CalcTempo:
	ldda8 l, 14100
	cps l, 0
	jr nz, ToneGen_CalcTempo_Lookup
	ldb l, 0x6

ToneGen_CalcTempo_Lookup:
	sla l, 1
	xor h, h
	push xix
	ld xix, 0xF625C4
	ld_sriw3 DE, 0x07, 0xF0, 0xEC
	ldda8 l, 14101
	sla l, 1
	ld_sriw3 BC, 0x07, 0xF0, 0xEC
	add de, bc
	pop xix
	ld wa, de
	ldb l, 0x60
	div8rr a, l
	stda8 13359, w
	stda8 13360, a
	ldda8 a, 14102
	cps a, 1
	jr nz, ToneGen_CalcTempo_Mode0
	sla de, 2
	ld wa, de
	xor de, de
	lds hl, 5
	ldfr_werp DE, 0xE2
	div xwa, xhl
	jr ToneGen_CalcTempoBeatsAndTicks

ToneGen_CalcTempo_Mode0:
	cps a, 0
	jr nz, ToneGen_CalcTempo_Mode2
	ld wa, de
	sla wa, 4
	add wa, de
	add wa, de
	add wa, de
	xor de, de
	ldw hl, 0x14
	ldfr_werp DE, 0xE2
	div xwa, xhl
	jr ToneGen_CalcTempoBeatsAndTicks

ToneGen_CalcTempo_Mode2:
	cps a, 2
	jr nz, ToneGen_CalcTempo_Mode3
	srl de, 1
	ld wa, de
	jr ToneGen_CalcTempoBeatsAndTicks

ToneGen_CalcTempo_Mode3:
	srl de, 2
	ld wa, de

ToneGen_CalcTempoBeatsAndTicks:
	ldb l, 0x60
	div8rr a, l
	stda8 13357, w
	stda8 13358, a
	ordi8 13519, 128
	ret

ToneGen_CalcTempo_DataTable:
	nop
	nop
	nop
	nop
	ldio	0, 12
	nop
	rcf
	nop
	.byte 0x18
	nop
	ldb	w, 0
	ldw	wa, 16384
	nop
	jr	f, 0
	.byte 0xc0, 0x00, 0x80, 0x01
	nop
	pop_sr
	.byte 0x80, 0x04
	nop
	.byte 0x06

ToneGen_AdvanceByTempo:
	ldda8 a, 13359
	ldda8 w, 13360
	addda8 a, 13564
	cp a, 0x60
	jr c, ToneGen_AdvTempo_StoreNote
	sub a, 0x60
	inc 1, w

ToneGen_AdvTempo_StoreNote:
	stda8 13564, a
	addda8 w, 13563
	ldda8 l, 13529
	ldda8 h, 13527
	and h, 0x7
	inc 1, h

ToneGen_AdvTempo_WrapLoop:
	cp w, l
	jr c, ToneGen_AdvTempo_StoreBeat
	sub w, l
	incdi8 1, 13562
	cpda8 h, 13562
	jr nz, ToneGen_AdvTempo_Continue
	stdi8 13562, 0

ToneGen_AdvTempo_Continue:
	jr ToneGen_AdvTempo_WrapLoop

ToneGen_AdvTempo_StoreBeat:
	stda8 13563, w
	ret

__pad_F62627:
	.byte 0x00, 0x00

AccPlayback_UpdateRhythmSustain:
	ldda8 a, 13592
	cps a, 0
	jr z, AccPlayback_RhythmSust_Return
	dec 1, a
	stda8 13592, a
	cps a, 0
	jr nz, AccPlayback_RhythmSust_Return
	ldda8 a, 13590
	ldda8 e, 13591
	ldb d, 0x0
	pushw wa
	call RhythmBuf_WriteByte
	inc 2, xsp
	ld a, e
	pushw wa
	call RhythmBuf_WriteByte
	inc 2, xsp
	ld a, d
	pushw wa
	call RhythmBuf_WriteByte
	inc 2, xsp

AccPlayback_RhythmSust_Return:
	ret

__pad_F6265F:
	.byte 0x00, 0x00

AccPlayback_ProcessVoiceType5:
	bitda 5, 13520
	jr z, AccVoice_DispatchType5Handler
	cpdi8 14098, 4
	jr nz, AccVoice_DispatchType5Handler
	ldda8 a, 14125
	and a, 0xC
	cps a, 0
	jr z, AccVoiceType5_CheckBit01
	calr ToneGen_AdjustVoiceVelocity

AccVoiceType5_CheckBit01:
	ldda8 a, 14125
	and a, 0x3
	cps a, 0
	jr z, AccVoice_DispatchType5Handler
	calr ToneGen_AdjustVolumePan

AccVoice_DispatchType5Handler:
	bitda 5, 13520
	jr z, TempoCheck_Exit
	cpdi8 14098, 5
	jr nz, TempoCheck_Exit
	ldda8 a, 14125
	and a, 0x30
	cps a, 0
	jr z, TempoCheck_Exit
	calr ToneGen_ProcessStereoType

TempoCheck_Exit:
	ret

__pad_F626A6:
	.byte 0x00, 0x00

ToneGen_AdjustVoiceVelocity:
	ldda16 xwa, 13586
	stda16 13385, xwa
	ldda16 xwa, 13588
	stda16 13419, xwa
	stdi8 13365, 0
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ldda16 xwa, 13385
	ld_srib3 A, 0x07, 0xEC, 0xE0
	cp a, 0x81
	jrl z, ToneGen_AdjVel_Return
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ldda16 xwa, 13385
	ld_srib3 A, 0x07, 0xEC, 0xE0
	bitda 4, 14235
	jr z, ToneGen_AdjVel_CheckBit2
	ldda8 w, 64446
	push xwa
	push xbc
	push xde
	push xix
	push xiy
	xor d, d
	ld e, a
	ld c, w
	xor b, b
	lds wa, 1
	call Param_SignExtendReturn
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xwa
	ld a, l

ToneGen_AdjVel_CheckBit2:
	bitda 2, 14125
	jr z, ToneGen_AdjVel_Decrement
	inc 1, a
	cp a, 0x80
	jr c, ToneGen_AdjVel_ClampHigh
	ldb a, 0x7F

ToneGen_AdjVel_ClampHigh:
	jr ToneGen_AdjVel_StoreAndParam

ToneGen_AdjVel_Decrement:
	dec 1, a
	cp a, 0xFF
	jr nz, ToneGen_AdjVel_StoreAndParam
	ldb a, 0x0

ToneGen_AdjVel_StoreAndParam:
	ld e, a
	bitda 4, 14235
	jr z, ToneGen_AdjVel_WriteToBuffer
	ldda8 w, 64446
	push xwa
	push xbc
	push xde
	push xix
	push xiy
	xor bc, bc
	ld c, w
	lds wa, 2
	xor d, d
	call Param_SignExtendReturn
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xwa
	ld a, l

ToneGen_AdjVel_WriteToBuffer:
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	pushw ix
	ldda16 xix, 13385
	lda_dri3 XBC, 0x07, 0xEC, 0xF0
	stda8 14104, e
	popw ix
	push xde
	call AccScreen_DrawInit_StackWrap
	pop xde
	ldda8 a, 14235
	and a, 0xF
	cps a, 0
	jr z, ToneGen_AdjVel_Return
	calr ToneGen_WriteMultiChanParam

ToneGen_AdjVel_Return:
	ret

__pad_F62776:
	.byte 0x00, 0x00

ToneGen_AdjustVolumePan:
	ldda16 xwa, 13586
	stda16 13385, xwa
	ldda16 xwa, 13588
	stda16 13419, xwa
	stdi8 13365, 0
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ldda16 xwa, 13385
	ld_srib3 A, 0x07, 0xEC, 0xE0
	cp a, 0x81
	jr z, ToneGen_AdjVol_Return
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ldda16 xwa, 13385
	ld_srib3 A, 0x07, 0xEC, 0xE0
	bitda 0, 14125
	jr z, ToneGen_AdjVol_Decrement
	inc 1, a
	cp a, 0x80
	jr c, ToneGen_AdjVol_ClampHigh
	ldb a, 0x7F

ToneGen_AdjVol_ClampHigh:
	jr ToneGen_AdjVol_WriteToBuffer

ToneGen_AdjVol_Decrement:
	dec 1, a
	cps a, 0
	jr z, ToneGen_AdjVol_ClampLow
	cp a, 0xFF
	jr nz, ToneGen_AdjVol_WriteToBuffer

ToneGen_AdjVol_ClampLow:
	ldb a, 0x1

ToneGen_AdjVol_WriteToBuffer:
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	pushw ix
	ldda16 xix, 13385
	lda_dri3 XBC, 0x07, 0xEC, 0xF0
	stda8 14103, a
	popw ix
	call AccScreen_UpdateBeat_StackWrap

ToneGen_AdjVol_Return:
	ret

__pad_F627F4:
	.byte 0x00, 0x00

ToneGen_ProcessStereoType:
	ldda16 xwa, 13586
	stda16 13385, xwa
	ldda16 xwa, 13588
	stda16 13419, xwa
	stdi8 13365, 0
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ldda16 xwa, 13385
	ld_srib3 A, 0x07, 0xEC, 0xE0
	cp a, 0x81
	jr z, ToneGen_Stereo_Return
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ldda16 xwa, 13385
	ld_srib3 C, 0x07, 0xEC, 0xE0
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ldda16 xwa, 13385
	ld_srib3 A, 0x07, 0xEC, 0xE0
	cp c, 0xD3
	jr z, ToneGen_Stereo_ClampLow
	bitda 4, 14125
	jr z, ToneGen_Stereo_Increment
	inc 1, a
	cp a, 0x80
	jr c, ToneGen_Stereo_CheckInc
	ldb a, 0x7F

ToneGen_Stereo_CheckInc:
	jr ToneGen_Stereo_Decrement

ToneGen_Stereo_Increment:
	dec 1, a
	cp a, 0xFF
	jr nz, ToneGen_Stereo_Decrement
	ldb a, 0x0

ToneGen_Stereo_Decrement:
	jr ToneGen_Stereo_WriteParam

ToneGen_Stereo_ClampLow:
	bitda 4, 14125
	jr z, ToneGen_Stereo_Store
	ldb a, 0x7F
	jr ToneGen_Stereo_WriteParam

ToneGen_Stereo_Store:
	ldb a, 0x0

ToneGen_Stereo_WriteParam:
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	pushw ix
	ldda16 xix, 13385
	lda_dri3 XBC, 0x07, 0xEC, 0xF0
	stda8 14113, a
	popw ix
	call AccScreen_DrawMeasure_StackWrap

ToneGen_Stereo_Return:
	ret

__pad_F6288E:
	nop
	nop
	ret
	nop
	nop
	push_sr
	.byte 0x53, 0x54
	.ascii "UVWX_`aR"
	.byte 0x03
	.ascii "bcdefghPiQj'(*,.$%& "
	.byte 0x1f, 0x29, 0x21
	.ascii "+\"-#/0123456789:=>"
	.byte 0x1b, 0x1c, 0x1d, 0x1e, 0x41, 0x42
	.ascii "CDEkl"
	.byte 0x19, 0x1a, 0x46
	.byte 0x18, 0x4c, 0x4b, 0x11, 0x12, 0x13, 0x14, 0x15
	.byte 0x16, 0x17, 0x4d, 0x4e, 0x4f, 0x0c, 0x0d, 0x0e
	.byte 0x0f, 0x10, 0x0a, 0x0b, 0x09, 0x47, 0x07, 0x08
	.byte 0x3b, 0x3c, 0x40, 0x3f
	.byte 0x05, 0x06, 0x49, 0x04
	.ascii "JHmnopqrstuvwxyz{|}~"
	.byte 0x7f, 0x0e, 0x00, 0x00
	.ascii "b_]^XYZ[\\NOPQRSTKHI=>?@('*,.$%&"
	.byte 0x1f
	.ascii " )!+\"-#/0123456789:cd;<feABCDEJ`likMLUVW"
	.byte 0x1b, 0x1d, 0x12, 0x09, 0x0a, 0x0b, 0x0c, 0x0d
	.byte 0x0e, 0x01, 0x02, 0x03, 0x04, 0x05, 0x07, 0x0f
	.byte 0x10, 0x11, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19
	.byte 0x1a, 0x1c, 0x1e
	.ascii "FGmnopqrstuvwxyz{|}~"
	.byte 0x7f

ToneGen_WriteMultiChanParam:
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ldda16 xiy, 13586
	ld_srib3 D, 0x07, 0xEC, 0xF4
	xor h, h
	ld l, e
	push xix
	ld xix, 0xE46142
	ld_srib3 A, 0x07, 0xF0, 0xEC
	pop xix
	ldb e, 0x90
	bitda 6, 13546
	jr z, ToneGen_MultiChan_Compare
	bitda 3, 14235
	jr z, ToneGen_MultiChan_Compare
	jr ToneGen_MultiChan_AdjustVel

ToneGen_MultiChan_Compare:
	bitda 5, 13546
	jr z, AccVoice_ResolveNoteOnOffType
	bitda 3, 14235
	jr nz, AccVoice_ResolveNoteOnOffType

ToneGen_MultiChan_AdjustVel:
	cps a, 7
	jr nz, AccVoice_ResolveNoteOnOffType
	ldb e, 0x91
	jr ToneGen_MultiChan_CheckBit4

AccVoice_ResolveNoteOnOffType:
	xor xhl, xhl
	ld l, a
	sla a, 1
	add l, a
	push xix
	ld xix, 0xF62010
	add xix, xhl
	ld a, (xix)
	pop xix
	cps a, 0
	jr z, ToneGen_MultiChan_CheckBit4
	ldb e, 0x91

ToneGen_MultiChan_CheckBit4:
	cp d, 0x90
	jr nz, ToneGen_MultiChan_WriteNoteOff
	cp e, 0x90
	jr z, VoiceCompare_Done
	calr ToneGen_CompareVoiceBlocks
	jr VoiceCompare_Done

ToneGen_MultiChan_WriteNoteOff:
	cp e, 0x90
	jr nz, VoiceCompare_Done
	calr ToneGen_CompareVoiceBlocks

VoiceCompare_Done:
	ret

ToneGen_MultiChan_WriteFinalNote:
	.byte 0x00, 0x00

ToneGen_CompareVoiceBlocks:
	calr __pad_F62A0D
	calr __pad_F62AAC
	calr __pad_F62B29
	calr ToneGen_StepWithBoundsCheck
	ret

ToneGen_MultiChan_Return:
	.byte 0x00, 0x00

__pad_F62A0D:
	ldda16 xwa, 13586
	stda16 13385, xwa
	ldda16 xwa, 13588
	stda16 13419, xwa
	stdi8 13365, 0
	ldda16 xiy, 13385
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ld_srib3 A, 0x07, 0xEC, 0xF4
	stda8 13366, a
	calr ToneGen_StepToNextVoiceSlot
	ldda16 xiy, 13385
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ld_srib3 A, 0x07, 0xEC, 0xF4
	stda8 13367, a
	calr ToneGen_StepToNextVoiceSlot
	ldda16 xiy, 13385
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ld_srib3 A, 0x07, 0xEC, 0xF4
	stda8 13368, a
	calr ToneGen_StepToNextVoiceSlot
	ldda16 xiy, 13385
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ld_srib3 A, 0x07, 0xEC, 0xF4
	stda8 13369, a
	calr ToneGen_StepToNextVoiceSlot
	ldda16 xiy, 13385
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ld_srib3 A, 0x07, 0xEC, 0xF4
	stda8 13370, a
	calr ToneGen_StepToNextVoiceSlot
	ldda16 xiy, 13385
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ld_srib3 A, 0x07, 0xEC, 0xF4
	stda8 13371, a
	ret

ToneGen_VoiceParamDisp_Return:
	.byte 0x00, 0x00

__pad_F62AAC:
	ldda16 xwa, 13588
	stda16 13419, xwa
	stda16 13914, xwa
	stda16 13616, xwa
	ldda16 xiy, 13586
	stda16 13387, xiy
	stda16 13385, xiy
	stda16 13920, xiy
	ld wa, iy
	stda8 13365, a
	stdi8 13389, 6
	ldda16 xiy, 13586
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ld_srib3 A, 0x07, 0xEC, 0xF4
	cp a, 0x90
	jr z, ToneGen_CalcBeatSubdivision
	stdi8 13389, 8
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot

ToneGen_CalcBeatSubdivision:
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot
	ldda16 xwa, 13419
	stda16 13912, xwa
	stda16 13618, xwa
	xor w, w
	ldda8 a, 13365
	stda16 13918, xwa
	calr ToneGen_ScanVoicePosition
	call AccPatch_CopySequenceEntry
	ret

ToneGen_CalcBeat_Return:
	.byte 0x00, 0x00

__pad_F62B29:
	ld xiy, 0x366A
	ldda8 a, 13366
	ld (xiy), a
	ldda8 a, 13367
	ld (xiy + 1), a
	ldda8 a, 13368
	ld (xiy + 2), a
	ldda8 a, 13369
	ld (xiy + 3), a
	ldda8 a, 13370
	ld (xiy + 4), a
	ldda8 a, 13371
	ld (xiy + 5), a
	ldda8 a, 13368
	xor h, h
	ld l, a
	push xix
	ld xix, 0xE46142
	ld_srib3 A, 0x07, 0xF0, 0xEC
	pop xix
	bitda 6, 13546
	jr z, ToneGen_ReadBufferUtility
	bitda 3, 14235
	jr z, ToneGen_ReadBufferUtility
	jr ToneGen_ReadBufUtil_Loop

ToneGen_ReadBufferUtility:
	bitda 5, 13546
	jr z, AccVoice_WriteNoteEventToBuffer
	bitda 3, 14235
	jr nz, AccVoice_WriteNoteEventToBuffer

ToneGen_ReadBufUtil_Loop:
	cps a, 7
	jr nz, AccVoice_WriteNoteEventToBuffer
	ld (xiy), 0x91
	ld (xiy + 6), 0x3
	ld (xiy + 7), 0x0
	jr __pad_F62BC0

AccVoice_WriteNoteEventToBuffer:
	xor xhl, xhl
	ld l, a
	sla a, 1
	add l, a
	push xix
	ld xix, 0xF62010
	add xix, xhl
	ld a, (xix)
	ld (xiy), 0x90
	cps a, 0
	jr z, ToneGen_ReadBufUtil_Return
	ld (xiy), 0x91
	ld a, (xix + 1)
	ld (xiy + 6), a
	ld a, (xix + 2)
	ld (xiy + 7), a

ToneGen_ReadBufUtil_Return:
	pop xix

__pad_F62BC0:
	ret

__pad_F62BC1_2:
	.byte 0x00, 0x00

ToneGen_StepWithBoundsCheck:
	cpdi16 13524, 0
	jr z, ToneGen_SeqAdvanceMain
	ld xiy, 0x366A
	ld a, (xiy)
	stdi16 13834, 6
	cp a, 0x90
	jr z, ToneGen_StepBounds_Return
	stdi16 13834, 8

ToneGen_StepBounds_Return:
	ldda16 xwa, 13588
	stda16 13419, xwa
	ldda16 xiy, 13586
	ld wa, iy
	stda8 13365, a
	ldda16 xwa, 13419
	stda16 13826, xwa
	xor w, w
	ldda8 a, 13365
	stda16 13828, xwa
	ldda16 xwa, 13828
	stda16 13381, xwa
	ldda16 xwa, 13826
	stda16 13383, xwa
	ldda16 xwa, 13834
	stda16 13387, xwa
	call AccPatch_InitSlotAndCopyData
	calr ToneGen_AdvanceSeqList
	jr ToneGen_SeqAdv_Return

ToneGen_SeqAdvanceMain:
	stdi8 32578, 15
	stdi8 58332, 238
	stdi8 58334, 64
	ldb a, 0x8
	call MIDI_SendSysExCmd

ToneGen_SeqAdv_Return:
	ret

__pad_F62C3E:
	.byte 0x00, 0x00

AccVoice_ReadCurrentToneType:
	push xiy
	push xhl
	xor xiy, xiy
	ldda16 xiy, 13385
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	add xhl, xiy
	ld a, (xhl + 1)
	cp a, 0x87
	jr nz, ToneGen_InterpolateParam
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ld hl, (xhl + 3)
	calr ToneGen_CalcBufferAddr
	ld a, (xhl + 6)

ToneGen_InterpolateParam:
	pop xhl
	pop xiy
	ret

ToneGen_Interp_Loop:
	.byte 0x00, 0x00

ToneGen_StepToNextVoiceSlot:
	push xiy
	push xhl
	ldda16 xiy, 13385
	inc 1, iy
	incdi8 1, 13365
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ld_srib3 A, 0x07, 0xEC, 0xF4
	cp a, 0x87
	jr z, ToneGen_Interp_StoreResult
	cp a, 0x83
	jr nz, ToneGen_Interp_WrapPoint
	jr ToneGen_Interp_CheckExit

ToneGen_Interp_StoreResult:
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ld hl, (xhl + 3)
	stda16 13419, xhl
	calr ToneGen_CalcBufferAddr
	lds iy, 6
	stdi8 13365, 6
	jr ToneGen_Interp_WrapPoint

ToneGen_Interp_CheckExit:
	call AccPatch_GetCurrentSlotAddr
	calr ToneGen_GetSlotIndex
	stda16 13419, xhl
	calr ToneGen_CalcBufferAddr
	lds iy, 6
	stdi8 13365, 6

ToneGen_Interp_WrapPoint:
	stda16 13385, xiy
	pop xhl
	pop xiy
	ret

ToneGen_Interp_Done:
	.byte 0x00, 0x00

ToneGen_StepToNextStereoSlot:
	push xiy
	push xhl
	ldda16 xiy, 13385
	inc 1, iy
	incdi8 1, 13365
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ld_srib3 A, 0x07, 0xEC, 0xF4
	cp a, 0x87
	jr nz, ToneGen_Interp_Return
	calr ToneGen_StepToNextBuffer

ToneGen_Interp_Return:
	inc 1, iy
	incdi8 1, 13365
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ld_srib3 A, 0x07, 0xEC, 0xF4
	cp a, 0x87
	jr nz, ToneGen_Interp_OverflowCheck
	calr ToneGen_StepToNextBuffer

ToneGen_Interp_OverflowCheck:
	stda16 13385, xiy
	pop xhl
	pop xiy
	ret

ToneGen_Interp_OverflowDone:
	.byte 0x00, 0x00

ToneGen_StepToNextBuffer:
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	xor iy, iy
	ld hl, (xhl + 3)
	stda16 13419, xhl
	calr ToneGen_CalcBufferAddr
	lds iy, 6
	stdi8 13365, 6
	ret

ToneGen_AdvanceBeatCounter:
	nop
	nop
	inc	1, iy
	cp	iy, bc
	jr	ule, 3
	.byte 0x9b, 0x00, 0x25
	ret
	nop
	nop

ToneGen_ReadBufferWithIndirection:
	push xhl
	inc 1, xix
	ld hl, de
	calr ToneGen_CalcBufferAddr
	ld a, (xix)
	cp a, 0x87
	jr nz, ToneGen_AdvBeat_Return
	ld hl, (xhl + 3)
	ld de, hl
	calr ToneGen_CalcBufferAddr
	ld xix, xhl
	add xix, 0x6

ToneGen_AdvBeat_Return:
	pop xhl
	ret

__pad_F62D57:
	.byte 0x00, 0x00

ToneGen_StepVoiceForward:
	push xiy
	push xhl
	ldda16 xiy, 13385
	dec 1, iy
	decdi8 1, 13365
	ldda16 xhl, 13419
	calr ToneGen_CalcBufferAddr
	ld_srib3 A, 0x07, 0xEC, 0xF4
	cp a, 0x87
	jr nz, ToneGen_StepFwd_WrapDone
	ld hl, (xhl + 1)
	cp hl, 0xFFFF
	jr z, ToneGen_StepFwd_CheckWrap
	stda16 13419, xhl
	calr ToneGen_CalcBufferAddr
	ldw iy, 0xFE
	stdi8 13365, 254
	jr ToneGen_StepFwd_WrapDone

ToneGen_StepFwd_CheckWrap:
	ldda16 xhl, 13830
	stda16 13419, xhl
	calr ToneGen_CalcBufferAddr
	ldda16 xhl, 13832
	dec 1, hl
	ld iy, hl
	stda8 13365, l

ToneGen_StepFwd_WrapDone:
	stda16 13385, xiy
	pop xhl
	pop xiy
	ret

ToneGen_StepFwd_Exit:
	.byte 0x00, 0x00

ToneGen_StepFwd_Alternate:
	ldda8 e, 14106
	ldda8 d, 14151
	ldda8 c, 14150
	ldda8 b, 13527
	cpdi8 13529, 4
	jr ugt, ToneGen_StepAlt_Overflow
	cps b, 3
	jr ugt, ToneGen_StepAlt_CheckBeat
	ldb c, 0x0
	jr ToneGen_StepAlt_Return

ToneGen_StepAlt_CheckBeat:
	calr __pad_F62E01
	calr ChordDetect_CheckDescending
	calr ChordDetect_CheckRoot1
	calr ChordDetect_CheckInversion1

ToneGen_StepAlt_Return:
	jr ToneGen_StepAlt_StoreResult

ToneGen_StepAlt_Overflow:
	cps b, 1
	jr ugt, ToneGen_StepAlt_OverflowDone
	ldb c, 0x0
	jr ToneGen_StepAlt_StoreResult

ToneGen_StepAlt_OverflowDone:
	calr ChordDetect_CheckAscending
	calr ChordDetect_CheckMirror
	calr ChordDetect_CheckRoot2
	calr ChordDetect_CheckInversion2

ToneGen_StepAlt_StoreResult:
	stda8 14150, c
	xor d, d
	stda16 14151, xde
	calr AccPlayback_DetectMeasurePos
	ret

ToneGen_StepAlt_Done:
	.byte 0x00, 0x00

__pad_F62E01:
	ld a, c
	add a, 0x3
	cp b, a
	jr ule, RhythmParam_CheckExit6
	inc 1, a
	cp a, d
	jr nz, RhythmParam_CheckExit6
	ld a, d
	inc 1, a
	cp a, e
	jr nz, RhythmParam_CheckExit6
	inc 1, c

RhythmParam_CheckExit6:
	ret

__pad_F62E1B:
	.byte 0x00, 0x00

ChordDetect_CheckDescending:
	cps c, 0
	jr z, ToneGen_NullRet2
	ld a, c
	add a, 0x2
	cp b, a
	jr ule, ToneGen_NullRet2
	ld a, c
	inc 1, a
	cp a, d
	jr nz, ToneGen_NullRet2
	ld a, d
	dec 1, a
	cp a, e
	jr nz, ToneGen_NullRet2
	dec 1, c

ToneGen_NullRet2:
	ret

__pad_F62E3D:
	.byte 0x00, 0x00

ChordDetect_CheckRoot1:
	cps c, 0
	jr nz, RhythmParam_CheckExit5
	cps d, 1
	jr nz, RhythmParam_CheckExit5
	ld a, b
	inc 1, a
	cp e, a
	jr nz, RhythmParam_CheckExit5
	ld a, b
	sub a, 0x3
	ld c, a

RhythmParam_CheckExit5:
	ret

__pad_F62E57:
	.byte 0x00, 0x00

ChordDetect_CheckInversion1:
	ld a, b
	sub a, 0x3
	cp c, a
	jr nz, RhythmParam_CheckExit4
	ld a, b
	inc 1, a
	cp d, a
	jr nz, RhythmParam_CheckExit4
	cps e, 1
	jr nz, RhythmParam_CheckExit4
	ldb c, 0x0

RhythmParam_CheckExit4:
	ret

__pad_F62E71:
	.byte 0x00, 0x00

ChordDetect_CheckAscending:
	ld a, c
	add a, 0x1
	cp b, a
	jr ule, RhythmParam_CheckExit3
	inc 1, a
	cp a, d
	jr nz, RhythmParam_CheckExit3
	ld a, d
	inc 1, a
	cp a, e
	jr nz, RhythmParam_CheckExit3
	inc 1, c

RhythmParam_CheckExit3:
	ret

__pad_F62E8D:
	.byte 0x00, 0x00

ChordDetect_CheckMirror:
	cps c, 0
	jr z, Rhythm_NullRet
	ld a, c
	cp b, a
	jr ule, Rhythm_NullRet
	ld a, c
	inc 1, a
	cp a, d
	jr nz, Rhythm_NullRet
	ld a, d
	dec 1, a
	cp a, e
	jr nz, Rhythm_NullRet
	dec 1, c

Rhythm_NullRet:
	ret

__pad_F62EAC:
	.byte 0x00, 0x00

ChordDetect_CheckRoot2:
	cps c, 0
	jr nz, RhythmParam_CheckExit2
	cps d, 1
	jr nz, RhythmParam_CheckExit2
	ld a, b
	inc 1, a
	cp e, a
	jr nz, RhythmParam_CheckExit2
	ld a, b
	dec 1, a
	ld c, a

RhythmParam_CheckExit2:
	ret

__pad_F62EC5:
	.byte 0x00, 0x00

ChordDetect_CheckInversion2:
	ld a, b
	dec 1, a
	cp c, a
	jr nz, RhythmParam_ValidExit
	ld a, b
	inc 1, a
	cp d, a
	jr nz, RhythmParam_ValidExit
	cps e, 1
	jr nz, RhythmParam_ValidExit
	ldb c, 0x0

RhythmParam_ValidExit:
	ret

__pad_F62EDE:
	.byte 0x00, 0x00

AccPlayback_DetectMeasurePos:
	ld a, c
	inc 1, a
	cpdi8 13529, 4
	jr ugt, AccPlayback_MeasPos_SmallBeat
	cp e, a
	jr c, AccPlayback_MeasPos_SetLower
	add a, 0x3
	cp e, a
	jr ugt, AccPlayback_MeasPos_SetUpper
	jr RhythmChannel_NullRet

AccPlayback_MeasPos_SetLower:
	ld c, e
	dec 1, c
	stda8 14150, c
	jr RhythmChannel_NullRet

AccPlayback_MeasPos_SetUpper:
	ld c, e
	sub c, 0x3
	dec 1, c
	stda8 14150, c
	jr RhythmChannel_NullRet

AccPlayback_MeasPos_SmallBeat:
	cp e, a
	jr c, AccPlayback_MeasPos_SmallLower
	add a, 0x1
	cp e, a
	jr ugt, AccPlayback_MeasPos_SmallUpper
	jr RhythmChannel_NullRet

AccPlayback_MeasPos_SmallLower:
	ld c, e
	dec 1, c
	stda8 14150, c
	jr RhythmChannel_NullRet

AccPlayback_MeasPos_SmallUpper:
	ld c, e
	sub c, 0x1
	dec 1, c
	stda8 14150, c

RhythmChannel_NullRet:
	ret

__pad_F62F32:
	.byte 0x00, 0x00

AccPlayback_InitPartAssignment:
	xor wa, wa
	stda16 14142, xwa
	stda16 14144, xwa
	stda16 14146, xwa
	stda16 14148, xwa
	jr AccPlayback_PartAssign_Check4
	ldda8 a, 13529
	cps a, 4
	jr ule, AccPlayback_PartAssign_Store
	cpdi8 13563, 4
	jr nc, AccPlayback_PartAssign_Sub4
	ldb a, 0x4
	jr AccPlayback_PartAssign_Store

AccPlayback_PartAssign_Sub4:
	sub a, 0x4

AccPlayback_PartAssign_Store:
	stda8 14142, a
	jrl RhythmFunc_NullRet

AccPlayback_PartAssign_Check4:
	cpdi8 13529, 4
	jrl ugt, AccPlayback_PartAssign_LargeBeat
	cpdi8 13527, 2
	jr ugt, AccPlayback_PartAssign_LargeMeasure
	cpdi8 14150, 0
	jr z, AccPlayback_PartAssign_SmallPart
	jrl RhythmFunc_NullRet

AccPlayback_PartAssign_SmallPart:
	ldda8 a, 13529
	stda8 14142, a
	stdi8 14146, 1
	cpdi8 13527, 1
	jr c, AccPlayback_PartAssign_Check2
	stda8 14143, a
	stdi8 14147, 2

AccPlayback_PartAssign_Check2:
	cpdi8 13527, 2
	jr c, AccPlayback_PartAssign_Check3
	stda8 14144, a
	stdi8 14148, 3

AccPlayback_PartAssign_Check3:
	jrl RhythmFunc_NullRet

AccPlayback_PartAssign_LargeMeasure:
	ldda8 a, 13527
	subda8 a, 14150
	cps a, 2
	jr gt, AccPlayback_PartAssign_FullSetup
	jrl RhythmFunc_NullRet

AccPlayback_PartAssign_FullSetup:
	ldda8 a, 13529
	stda8 14142, a
	stda8 14143, a
	stda8 14144, a
	stda8 14145, a
	ldda8 a, 14150
	inc 1, a
	stda8 14146, a
	inc 1, a
	stda8 14147, a
	inc 1, a
	stda8 14148, a
	inc 1, a
	stda8 14149, a
	jr RhythmFunc_NullRet

AccPlayback_PartAssign_LargeBeat:
	cpdi8 13527, 0
	jr nz, AccPlayback_PartAssign_LargeBeat2
	cpdi8 14150, 0
	jr nz, RhythmFunc_NullRet
	stdi8 14142, 4
	ldda8 a, 13529
	sub a, 0x4
	stda8 14143, a
	stdi8 14146, 1
	jr RhythmFunc_NullRet

AccPlayback_PartAssign_LargeBeat2:
	ldda8 a, 13527
	subda8 a, 14150
	cps a, 0
	jr le, RhythmFunc_NullRet
	stdi8 14142, 4
	ldda8 a, 13529
	sub a, 0x4
	stda8 14143, a
	stdi8 14144, 4
	stda8 14145, a
	ldda8 a, 14150
	inc 1, a
	stda8 14146, a
	inc 1, a
	stda8 14148, a

RhythmFunc_NullRet:
	ret

AccPlayback_PartAssign_DataBlock:
	nop
	nop
	cpdi8	36152, 182
	jr	z, 2
	jr	60
	ldda8	a, 14095
	ldw	ix, 480
	calr	53
	ldda8	a, 14106
	ldw	ix, 6962
	calr	43
	ldda8	a, 14104
	ldw	ix, 6967
	calr	33
	ldda8	a, 14103
	ldw	ix, 6972
	calr	23
	ldda8	a, 14100
	ldw	ix, 6977
	calr	13
	ldda8	a, 14101
	ldw	ix, 6982
	calr	3
	ret
	nop
	nop
	calr	20
	pushw	ix
	ld	a, d
	calr	11
	popw	ix
	inc	1, ix
	ld	a, e
	calr	3
	ret
	nop
	nop
	ret
	nop
	nop
	ld	e, a
	and	wa, 240
	srl	wa, 4
	ld	hl, wa
	ld	d, a
	ld	a, e
	and	wa, 15
	ld	hl, wa
	ret
	nop
	.byte 0x00
	.ascii "0123456789ABCDEF"
	.byte 0x0e

AccPat_ShiftAndMask:
	pushw hl
	and hl, 0xFFF
	sla hl, 4
	popw hl
	ret

__pad_F630DE:
	.byte 0x00, 0x00

AccPat_IndexToAddress:
	and xhl, 0xFFFF
	sla xhl, 8
	add xhl, 0x95C00
	ret

AccPat_InlineFunctions_DataBlock:
	nop
	nop
	and	xhl, 65535
	sla	xhl, 8
	add	xhl, 613376
	ret
	push	xwa
	push	xix
	ld	wa, hl
	and	xhl, 4095
	sla	xhl, 8
	and	wa, 61440
	srl	wa, 10
	ld	xix, 16134437
	.byte 0xe3, 0x07, 0xf0, 0xe0, 0x24
	add	xhl, xix
	pop	xix
	pop	xwa
	ret
	nop
	pop	xix
	push 0
	nop
	pop	xix
	push 0
	nop
	pop	xix
	push 0
	nop
	pop	xix
	push 0
	nop
	pop	xix
	push 0
	nop
	pop	xix
	push 0
	nop
	pop	xix
	push 0
	nop
	pop	xix
	push 0
	nop
	pop	xix
	push 0
	push	xiz
	calr	2
	pop	xiz
	ret

AccPat_DispatchNoteChange:
	bitda 0, 13521
	jr nz, AccPat_Dispatch_AllocAndProcess
	jp AccPat_Dispatch_Return

AccPat_Dispatch_AllocAndProcess:
	ld xwa, 0x800
	push xwa
	call Malloc
	add xsp, 0x4
	stda32 13668, xhl
	ldda8 a, 13549
	ldda8 w, 13550
	pushw wa
	anddi8 13521, 254
	anddi8 13744, 254
	ldda8 a, 13549
	cp a, 0x80
	jr c, AccPat_Dispatch_LowRange
	cp a, 0xA0
	jrl nc, AccPat_CleanupAndFree
	cpdi8 13551, 26
	jr nz, AccPat_Dispatch_CalcAccent
	calr AccWidget_ProcessSpecialCmd
	jrl AccPat_CleanupAndFree

AccPat_Dispatch_CalcAccent:
	calr AccPat_CalcAccentVelocity
	ldda8 a, 13549
	and a, 0x7F
	cpda8 a, 13526
	jr z, AccPat_CleanupAndFree
	cp a, 0x1E
	jr nc, AccPat_CleanupAndFree
	ordi8 13517, 128
	call AccPat_InitWorkAreaFromSlot
	ldda8 a, 13549
	and a, 0x7F
	stda8 14764, a
	ldda8 a, 13526
	stda8 14765, a
	push xix
	ld xix, 0x94800
	stda32 14766, xix
	stda32 14770, xix
	pop xix
	calr AccPatch_LoadDualVoiceParams
	jr AccPat_Dispatch_CheckBit0

AccPat_Dispatch_LowRange:
	ordi8 13517, 128
	cpdi8 13551, 26
	jr nz, AccPat_Dispatch_InitWorkArea
	calr RhythmROM_LoadDrumKit
	jr AccPat_CleanupAndFree

AccPat_Dispatch_InitWorkArea:
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher

AccPat_Dispatch_CheckBit0:
	bitda 0, 13744
	jr nz, AccPat_Dispatch_InitSlot
	cpdi8 36150, 184
	jr nz, AccPat_CleanupAndFree
	stdi8 32578, 20
	call DrumVoice_NotifyEE
	jr AccPat_CleanupAndFree

AccPat_Dispatch_InitSlot:
	call AccPatch_InitCurrentSlot
	stdi8 32578, 23
	call DrumVoice_NotifyEE
	ldb a, 0x8
	call MIDI_SendSysExCmd

AccPat_CleanupAndFree:
	popw wa
	stda8 13549, a
	stda8 13550, w
	ldda32 xwa, 13668
	push xwa
	call Free
	add xsp, 0x4

AccPat_Dispatch_Return:
	ret

__pad_F6323D:
	.byte 0x00, 0x00

DualVoice_ParamLoadDone:
	push xiz
	calr AccPatch_LoadDualVoiceParams
	pop xiz
	ret

AccPatch_LoadDualVoiceParams:
	ldda8 l, 14764
	cp l, 0x1E
	jr c, AccPat_DualVoice_ClampIndex
	xor l, l

AccPat_DualVoice_ClampIndex:
	sla l, 2
	xor h, h
	ld xix, 0xE46312
	ld_sril3 XIY, 0x07, 0xF0, 0xEC
	addda32 xiy, 14766
	add xiy, 0x60
	stda32 13660, xiy
	ldda8 l, 14765
	cp l, 0x1E
	jr c, AccPat_DualVoice_ClampIndex2
	xor l, l

AccPat_DualVoice_ClampIndex2:
	sla l, 2
	xor h, h
	ld xix, 0xE46312
	ld_sril3 XIY, 0x07, 0xF0, 0xEC
	addda32 xiy, 14770
	add xiy, 0x60
	stda32 13664, xiy
	ldda32 xiy, 13660
	add xiy, 0xC
	ldda32 xix, 13664
	add xix, 0xC
	ldw bc, 0x54
	ldir85
	calr AccPat_DualVoice_ReadParamsA
	calr AccPatch_LoadDualVoiceParamsB
	calr AccPat_DualVoice_CopyAllBanks
	ret

AccPat_DualVoice_DataBlock:
	nop
	nop
	ldda8	l, 13549
	and	l, 127
	cp	l, 30
	jr	c, 2
	xor	l, l
	sla	l, 2
	xor	h, h
	ld	xix, 14967570
	.byte 0xe3, 0x07, 0xf0, 0xec, 0x25
	add	xiy, 608256
	add	xiy, 96
	stda32	13660, xiy
	ldda8	l, 13526
	cp	l, 30
	jr	c, 2
	xor	l, l
	sla	l, 2
	xor	h, h
	.byte 0x44
	.long LABEL_E46312
	.byte 0xe3, 0x07, 0xf0, 0xec, 0x25
	add	xiy, 608256
	add	xiy, 96
	.byte 0xf1, 0x60, 0x35
	jr	mi, 0x0e

AccPat_DualVoice_ReadParamsA:
	ldda32 xiy, 13660
	ld hl, (xiy + 256)
	stda16 13732, xhl
	ld hl, (xiy + 4)
	stda16 13734, xhl
	ld hl, (xiy + 6)
	stda16 13736, xhl
	ld hl, (xiy + 8)
	stda16 13738, xhl
	ld hl, (xiy + 10)
	stda16 13740, xhl
	ret

__pad_F6333A:
	.byte 0x00, 0x00

AccPatch_LoadDualVoiceParamsB:
	ldda32 xiy, 13664
	ld hl, (xiy + 256)
	stda16 13720, xhl
	ld hl, (xiy + 4)
	stda16 13722, xhl
	ld hl, (xiy + 6)
	stda16 13724, xhl
	ld hl, (xiy + 8)
	stda16 13726, xhl
	ld hl, (xiy + 10)
	stda16 13728, xhl
	ret

__pad_F63364:
	.byte 0x00, 0x00

AccPat_DualVoice_CopyAllBanks:
	ldda16 xiy, 13732
	ldda16 xix, 13720
	calr ToneBank_CopyEntry
	ldda16 xiy, 13734
	ldda16 xix, 13722
	calr ToneBank_CopyEntry
	ldda16 xiy, 13736
	ldda16 xix, 13724
	calr ToneBank_CopyEntry
	ldda16 xiy, 13738
	ldda16 xix, 13726
	calr ToneBank_CopyEntry
	ldda16 xiy, 13740
	ldda16 xix, 13728
	calr ToneBank_CopyEntry
	ret

__pad_F6339E:
	.byte 0x00, 0x00

ToneBank_CopyEntry:
	stda16 13718, xix
	stda16 13730, xiy
	ld hl, iy
	ldda32 xwa, 14766
	calr ToneBank_ComputeEntryAddress
	ld wa, (xhl + 3)
	stda16 13742, xwa
	ldda16 xhl, 13718
	ldda32 xwa, 14770
	calr ToneBank_ComputeEntryAddress
	ld xix, xhl
	ldda16 xhl, 13730
	ldda32 xwa, 14766
	calr ToneBank_ComputeEntryAddress
	ld xiy, xhl
	add xiy, 0x6
	add xix, 0x6
	ldw bc, 0xF9
	ldir85

__pad_F633E3:
	cpdi16 13742, 65535
	jrl z, ToneBank_CopyComplete_Return
	calr ToneBank_CopyChunk_Return
	bitda 0, 13744
	jr nz, ToneBank_CopyComplete_Return
	decdi16 1, 13524
	ld hl, de
	ldda32 xwa, 14770
	calr ToneBank_ComputeEntryAddress
	ormi8 (xhl), 0x80
	ldda16 xhl, 13718
	ldda32 xwa, 14770
	calr ToneBank_ComputeEntryAddress
	ld (xhl + 3), de
	ld hl, de
	ldda32 xwa, 14770
	calr ToneBank_ComputeEntryAddress
	ldda16 xwa, 13718
	ld (xhl + 1), wa
	stda16 13718, xde
	ldda16 xwa, 13742
	stda16 13730, xwa
	ld hl, wa
	ldda32 xwa, 14766
	calr ToneBank_ComputeEntryAddress
	ld wa, (xhl + 3)
	stda16 13742, xwa
	calr AccPat_ShiftAndMask
	ldda16 xhl, 13718
	ldda32 xwa, 14770
	calr ToneBank_ComputeEntryAddress
	ld xix, xhl
	ldda16 xhl, 13730
	ldda32 xwa, 14766
	calr ToneBank_ComputeEntryAddress
	ld xiy, xhl
	add xiy, 0x6
	add xix, 0x6
	ldw bc, 0xF9
	ldir85
	jrl __pad_F633E3

ToneBank_CopyComplete_Return:
	ldda16 xhl, 13718
	ldda32 xwa, 14770
	calr ToneBank_ComputeEntryAddress
	ldw wa, 0xFFFF
	ld (xhl + 3), wa
	ret

ToneBank_CopyChunk:
	.byte 0x00

ToneBank_ComputeEntryAddress:
	and xhl, 0xFFF
	sla xhl, 8
	add xhl, xwa
	add xhl, 0x1400
	ret

ToneBank_CopyChunk_Return:
	ldw de, 0x96

__pad_F63498:
	cp de, 0x154
	jr nc, ToneBank_ComputeAddr_CheckRange
	ld hl, de
	ldda32 xwa, 14770
	calr ToneBank_ComputeEntryAddress
	bitm 7, (xhl)
	jr z, ToneBank_ComputeAddr_Return
	inc 1, de
	jr __pad_F63498

ToneBank_ComputeAddr_CheckRange:
	ordi8 13744, 1

ToneBank_ComputeAddr_Return:
	ret

__pad_F634B5:
	ldw de, 0x96

ToneBank_CopyChunkWithSwap:
	cp de, 0x154
	jr nc, ToneBank_SwapCopy_Return
	ld hl, de
	calr AccPat_IndexToAddress
	bitm 7, (xhl)
	jr z, ToneBank_SwapCopy_Pad
	inc 1, de
	jr ToneBank_CopyChunkWithSwap

ToneBank_SwapCopy_Return:
	ordi8 13744, 1

ToneBank_SwapCopy_Pad:
	ret

__pad_F634D1:
	nop
	nop
	ldw	de, 150
	cp	de, 340
	jr	nc, 13
	ld	hl, de
	calr	-1007
	.byte 0xb3, 0xcf
	jr	z, 9
	inc	1, de
	jr	-19
	.byte 0xc1, 0xb0, 0x35, 0x3e, 0x01
	or	de, 32768
	ret

RhythmROM_PatternDispatcher:
	anddi8 13744, 249
	ldda8 l, 13549
	ldda8 h, 13550
	call VoiceParam_ClampAndValidate_Tramp
	stda8 13549, l
	stda8 13550, h
	sla l, 1
	sla hl, 1
	ld xiy, 0xE45142
	ld_sriw3 WA, 0x07, 0xF4, 0xEC
	stda16 13658, xwa
	add hl, 0x2
	ld_sriw3 WA, 0x07, 0xF4, 0xEC
	stda16 13660, xwa
	ldda8 l, 13526
	cp l, 0x1E
	jr c, AccPat_CalcAccentVelocity_Body
	xor l, l

AccPat_CalcAccentVelocity_Body:
	sla l, 2
	xor h, h
	ld xix, 0xE46312
	ld_sril3 XIY, 0x07, 0xF0, 0xEC
	add xiy, 0x94800
	add xiy, 0x60
	stda32 13664, xiy
	calr RhythmROM_LoadPattern
	cpdi8 13551, 0
	jr z, RhythmROM_LoadAndInit
	cpdi8 13551, 1
	jr z, RhythmROM_LoadAndInit
	cpdi8 13551, 2
	jr z, RhythmROM_LoadAndInit
	cpdi8 13551, 3
	jr z, RhythmROM_LoadAndInit
	calr __pad_F63A6C
	calr AccPatch_LoadDualVoiceParamsB
	calr VoiceSlot_Resolve_Loop
	jr AccPat_CalcAccent_Return

RhythmROM_LoadAndInit:
	calr DrumKit_DataTable_Entry0
	calr AccPatch_LoadDualVoiceParamsB
	calr AccSection_ProcessEntry

AccPat_CalcAccent_Return:
	ret

__pad_F6358B:
	.byte 0x00, 0x00

RhythmROM_LoadPattern:
	ldda16 xwa, 13658
	ld w, a
	calr RhythmROM_CalcPatternAddr
	xor xiy, xiy
	ldda16 xiy, 13660
	add xiy, xix
	ldda32 xix, 13668
	ldw bc, 0x400
	ldirw
	ldda8 l, 13551
	and l, 0xF
	xor h, h
	sla hl, 1
	ld xix, 0xF635C1
	xor xwa, xwa
	ld_sriw3 WA, 0x07, 0xF0, 0xEC
	jr RhythmROM_PatternDisp_ReadByte
	xorda16_24 xde, 251907
	reti
RhythmROM_PatternDisp_InitLoop:
	neg	wa
	.byte 0xd3, 0x03, 0xd3, 0x07, 0xd3
	pop_sr
	.byte 0xd3, 0x07, 0xd2, 0x03, 0xd2
	pop_sr
	ld	wa, 984
	xordm16_24	512519, wa
	reti
	neg	wa

RhythmROM_PatternDisp_ReadByte:
	ldda32 xiy, 13668
	add xiy, xwa
	ld a, (xiy)
	stda8 13745, a
	ldda32 xiy, 13668
	ldda32 xix, 13664
	add xix, 0xC
	ld_srib A, (xiy + 0x03d0)
	ld (xix), a
	inc 1, xix
	push xix
	calr __pad_F636FB
	pop xix
	ld (xix), a
	inc 1, xix
	ldb a, 0x20
	ld (xix), a
	inc 1, xix
	ldb a, 0x0
	ld (xix), a
	inc 1, xix
	ldda8 a, 13549
	ld (xix), a
	inc 1, xix
	ldda8 a, 13550
	ld (xix), a
	inc 1, xix
	ldda8 l, 13551
	and l, 0xF
	xor h, h
	sla hl, 1
	ld xix, 0xF63643
	xor xwa, xwa
	ld_sriw3 WA, 0x07, 0xF0, 0xEC
	jr RhythmROM_PatternDisp_Handle90

RhythmROM_PatternDisp_CheckCmd:
	popw	wa
	.byte 0x02
	jrl	ge, 18434
	ei	0x79
	ei	0x6e
	.byte 0x03
	jr	nz, 7
	.byte 0x9f, 0x03, 0x9f
	reti
	incf
	.byte 0x03
	incf
	.byte 0x03
	push	xiy
	.byte 0x03
	push	xiy
	.byte 0x03
	incf
	reti
	incf
	reti
	push	xiy
	reti
	push	xiy
	reti

RhythmROM_PatternDisp_Handle90:
	ldda32 xiy, 13668
	add xiy, xwa
	ldda32 xix, 13664
	add xix, 0x18
	ldb a, 0x5

RhythmROM_PatternDisp_Check91:
	lds bc, 7
	ldir85
	inc 1, xix
	dec 1, a
	cps a, 0
	jr nz, RhythmROM_PatternDisp_Check91
	ldda32 xix, 13664
	ld xiy, 0x22
	add xiy, xix
	ld (xiy), 0x40
	ld xiy, 0x2A
	add xiy, xix
	ld (xiy), 0xC
	ld xiy, 0x32
	add xiy, xix
	ld (xiy), 0x74
	ld xiy, 0x3A
	add xiy, xix
	ld (xiy), 0x40
	ldda8 a, 13549
	stda8 37098, a
	ldda8 a, 13550
	stda8 37099, a
	call Rhythm_DispatchNote_Finalize
	ldda8 h, 37103
	ldda8 l, 37102
	call AccVoice_DispatchEntry
	ld xiy, 0x34AB
	ldda32 xix, 13664
	add xix, 0x40
	ldw bc, 0x10
	ldir85
	ret

RhythmROM_PatternDisp_Handle91:
	.byte 0x00, 0x00

RhythmROM_CalcPatternAddr:
	and xwa, 0xFF00
	sla xwa, 8
	ld xix, 0x400000
	addda32 xix, 12919
	add xix, xwa
	ret

RhythmROM_PatternDisp_Return:
	.byte 0x00, 0x00

__pad_F636FB:
	ldda32 xhl, 13668
	add xhl, 0x118
	calr RhythmROM_CountEntries
	stda8 13747, e
	ldda8 a, 13551
	cps a, 0
	jr z, RhythmROM_InitPattern
	cps a, 1
	jr z, RhythmROM_InitPattern
	cps a, 2
	jr z, RhythmROM_InitPattern
	cps a, 3
	jr z, RhythmROM_InitPattern
	jr __pad_F63748

RhythmROM_InitPattern:
	ldda32 xhl, 13664
	xor wa, wa
	ld a, (xhl + 12)
	ld xhl, 0xF63EC8
	ld_srib3 L, 0x07, 0xEC, 0xE0
	ldb a, 0x7
	cpda8 l, 13747
	jr nz, RhythmVoice_WriteParam_Return
	ordi8 13744, 2
	ldb a, 0x3

RhythmVoice_WriteParam_Return:
	jp RhythmROM_NullRet

__pad_F63748:
	ldda32 xhl, 13668
	add xhl, 0x138
	cps a, 4
	jr z, RhythmROM_ProcessPattern
	ldda32 xhl, 13668
	add xhl, 0x13C
	cps a, 6
	jr z, RhythmROM_ProcessPattern
	ldda32 xhl, 13668
	add xhl, 0x538
	cps a, 5
	jr z, RhythmROM_ProcessPattern
	ldda32 xhl, 13668
	add xhl, 0x53C
	cps a, 7
	jr z, RhythmROM_ProcessPattern
	jr RhythmVoice_SetupChannels

RhythmROM_ProcessPattern:
	calr RhythmROM_CountEntries
	ldda32 xhl, 13664
	xor wa, wa
	ld a, (xhl + 12)
	ld xhl, 0xF63EC8
	ld_srib3 A, 0x07, 0xEC, 0xE0
	ex8 a, e
	xor w, w
	div8rr a, e
	dec 1, a
	cps w, 0
	jr z, RhythmROM_NullRet
	ldb a, 0x8
	call MIDI_SendSysExCmd
	jr RhythmROM_NullRet

RhythmVoice_SetupChannels:
	cp a, 0x8
	jr z, RhythmROM_ReturnZero
	cp a, 0x9
	jr z, RhythmROM_ReturnZero
	cp a, 0xA
	jr z, RhythmROM_ReturnZero
	cp a, 0xB
	jr z, RhythmROM_ReturnZero
	cp a, 0xC
	jr z, RhythmROM_ReturnZero
	cp a, 0xD
	jr z, RhythmROM_ReturnZero
	cp a, 0xE
	jr z, RhythmROM_ReturnZero
	cp a, 0xF
	jr z, RhythmROM_ReturnZero
	jr RhythmROM_NullRet

RhythmROM_ReturnZero:
	xor a, a

RhythmROM_NullRet:
	ret

RhythmVoice_SetupChan_Finalize:
	.byte 0x00, 0x00

RhythmROM_CountEntries:
	push xhl
	ldda32 xhl, 13668
	add xhl, 0x3D1
	ld w, (xhl)
	pop xhl
	calr RhythmROM_CalcPatternAddr
	ld hl, (xhl)
	and xhl, 0xFFFF
	add hl, 0x6
	add xhl, xix
	xor e, e
	ld a, (xhl)
	inc 1, xhl

RhythmVoice_WriteToBuffer:
	cp a, 0x83
	jr z, RhythmVoice_WriteBuf_Done
	cp a, 0x81
	jr nz, RhythmVoice_WriteBuf_Clamp
	inc 1, e

RhythmVoice_WriteBuf_Clamp:
	ld a, (xhl)
	inc 1, xhl
	jr RhythmVoice_WriteToBuffer

RhythmVoice_WriteBuf_Done:
	ret

__pad_F63813:
	nop
	nop
	ldb	c, 16
	ld	a, (xiy)
	jr	nz, 3
	ld	(xiy), 32
	jr	nz, 3
	ld	(xiy), 32
	dec	1, bc
	inc	1, iy
	cps	bc, 0
	jr	nz, -20
	ret
	nop
	nop

DrumKit_DataTable_Entry0:
	ldda32 xix, 13668
	ldda32 xiy, 13668
	cpdi8 13551, 0
	jr nz, DrumKit_DataTable_Entry1
	add xix, 0x0
	add xiy, 0x118

DrumKit_DataTable_Entry1:
	cpdi8 13551, 1
	jr nz, DrumKit_DataTable_Entry2
	add xix, 0xF
	add xiy, 0x118

DrumKit_DataTable_Entry2:
	cpdi8 13551, 2
	jr nz, DrumKit_DataTable_Entry3
	add xix, 0x400
	add xiy, 0x518

DrumKit_DataTable_Entry3:
	cpdi8 13551, 3
	jr nz, DrumKit_DataTable_Entry4
	add xix, 0x40F
	add xiy, 0x518

DrumKit_DataTable_Entry4:
	lds32 xhl, 0
	bitda 0, 13745
	jr nz, DrumKit_DataTable_Entry5
	ld xhl, 0x26

DrumKit_DataTable_Entry5:
	add xhl, xiy
	ld a, (xix + 256)
	calr ToneData_LookupEffectParam
	stda8 13708, a
	stda16 13674, xhl
	ld xhl, 0x4C
	add xhl, xiy
	ld a, (xix + 40)
	calr ToneData_LookupEffectParam
	stda8 13709, a
	stda16 13676, xhl
	ld xhl, 0x72
	add xhl, xiy
	ld a, (xix + 80)
	calr ToneData_LookupEffectParam
	stda8 13710, a
	stda16 13678, xhl
	ld xhl, 0x98
	add xhl, xiy
	ld a, (xix + 120)
	calr ToneData_LookupEffectParam
	stda8 13711, a
	stda16 13680, xhl
	ld xhl, 0xBE
	add xhl, xiy
	ld_srib A, (xix + 0x00a0)
	calr ToneData_LookupEffectParam
	stda8 13712, a
	stda16 13682, xhl
	lds32 xhl, 0
	bitda 0, 13745
	jr nz, DrumKit_DataTable_Entry6
	ld xhl, 0x26

DrumKit_DataTable_Entry6:
	add xhl, xiy
	ld a, (xix + 1)
	calr ToneData_LookupEffectParam
	stda8 13713, a
	stda16 13684, xhl
	ld xhl, 0x4C
	add xhl, xiy
	ld a, (xix + 41)
	calr ToneData_LookupEffectParam
	stda8 13714, a
	stda16 13686, xhl
	ld xhl, 0x72
	add xhl, xiy
	ld a, (xix + 81)
	calr ToneData_LookupEffectParam
	stda8 13715, a
	stda16 13688, xhl
	ld xhl, 0x98
	add xhl, xiy
	ld a, (xix + 121)
	calr ToneData_LookupEffectParam
	stda8 13716, a
	stda16 13690, xhl
	ld xhl, 0xBE
	add xhl, xiy
	ld_srib A, (xix + 0x00a1)
	calr ToneData_LookupEffectParam
	stda8 13717, a
	stda16 13692, xhl
	lds32 xhl, 0
	bitda 0, 13745
	jr nz, DrumKit_DataTable_Entry7
	ld xhl, 0x26

DrumKit_DataTable_Entry7:
	add xhl, xiy
	ld a, (xix + 2)
	calr ToneData_LookupEffectParam
	stda8 13760, a
	stda16 13750, xhl
	ld xhl, 0x4C
	add xhl, xiy
	ld a, (xix + 42)
	calr ToneData_LookupEffectParam
	stda8 13761, a
	stda16 13752, xhl
	ld xhl, 0x72
	add xhl, xiy
	ld a, (xix + 82)
	calr ToneData_LookupEffectParam
	stda8 13762, a
	stda16 13754, xhl
	ld xhl, 0x98
	add xhl, xiy
	ld a, (xix + 122)
	calr ToneData_LookupEffectParam
	stda8 13763, a
	stda16 13756, xhl
	ld xhl, 0xBE
	add xhl, xiy
	ld_srib A, (xix + 0x00a2)
	calr ToneData_LookupEffectParam
	stda8 13764, a
	stda16 13758, xhl
	lds32 xhl, 0
	bitda 0, 13745
	jr nz, DrumKit_DataTable_Entry8
	ld xhl, 0x26

DrumKit_DataTable_Entry8:
	add xhl, xiy
	ld a, (xix + 3)
	calr ToneData_LookupEffectParam
	stda8 13776, a
	stda16 13766, xhl
	ld xhl, 0x4C
	add xhl, xiy
	ld a, (xix + 43)
	calr ToneData_LookupEffectParam
	stda8 13777, a
	stda16 13768, xhl
	ld xhl, 0x72
	add xhl, xiy
	ld a, (xix + 83)
	calr ToneData_LookupEffectParam
	stda8 13778, a
	stda16 13770, xhl
	ld xhl, 0x98
	add xhl, xiy
	ld a, (xix + 123)
	calr ToneData_LookupEffectParam
	stda8 13779, a
	stda16 13772, xhl
	ld xhl, 0xBE
	add xhl, xiy
	ld_srib A, (xix + 0x00a3)
	calr ToneData_LookupEffectParam
	stda8 13780, a
	stda16 13774, xhl
	ret

RhythmROM_LoadKit_InitLDA:
	.byte 0x00, 0x00

ToneData_LookupEffectParam:
	sla a, 1
	xor w, w
	ld_sriw3 HL, 0x07, 0xEC, 0xE0
	push xix
	ldda32 xix, 13668
	add xix, 0x3D1
	ld a, (xix)
	pop xix
	ret

RhythmROM_LoadKit_Return:
	.byte 0x00, 0x00

__pad_F63A6C:
	ldda32 xix, 13668
	add xix, 0x3D1
	ld a, (xix)
	stda8 13708, a
	stda8 13709, a
	stda8 13710, a
	stda8 13711, a
	stda8 13712, a
	calr __pad_F63AE7
	ldda32 xiy, 13668
	xor xhl, xhl
	ldda16 xhl, 13748
	add xiy, xhl
	lds32 xhl, 0
	bitda 0, 13745
	jr nz, RhythmROM_LoadKit_CopyLoop
	ld xhl, 0x26

RhythmROM_LoadKit_CopyLoop:
	add xhl, xiy
	ld hl, (xhl)
	stda16 13674, xhl
	ld xhl, 0x4C
	add xhl, xiy
	ld hl, (xhl)
	stda16 13676, xhl
	ld xhl, 0x72
	add xhl, xiy
	ld hl, (xhl)
	stda16 13678, xhl
	ld xhl, 0x98
	add xhl, xiy
	ld hl, (xhl)
	stda16 13680, xhl
	ld xhl, 0xBE
	add xhl, xiy
	ld hl, (xhl)
	stda16 13682, xhl
	ret

RhythmROM_LoadKit_CopyReturn:
	.byte 0x00, 0x00

__pad_F63AE7:
	ldda8 l, 13551
	and l, 0xF
	xor h, h
	sla hl, 1
	ld xix, 0xF63B04
	ld_sriw3 WA, 0x07, 0xF0, 0xEC
	stda16 13748, xwa
	ret

VoiceSlot_ResolveIndex:
	.zero 8
	nop
	nop
	push	xwa
	.byte 0x01
	push	xwa
	halt
	push	xix
	.byte 0x01
	push	xix
	halt
	ldw	wa, 12801
	.byte 0x01
	ldw	ix, 13825
	.byte 0x01
	ldw	wa, 12805
	halt
	ldw	ix, 13829
	halt
	ret
	nop
	nop

VoiceSlot_Resolve_Loop:
	ldda8 w, 13708
	calr RhythmROM_CalcPatternAddr
	ldda16 xiy, 13674
	ldda16 xde, 13720
	bitda 0, 13745
	jr nz, VoiceSlot_Resolve_CheckA
	bitda 1, 13745
	jr nz, VoiceSlot_Resolve_CheckA
	jr VoiceSlot_Resolve_CheckB

VoiceSlot_Resolve_CheckA:
	calr RhythmBuf_LoadPattern
	jr VoiceSlot_Resolve_StoreA

VoiceSlot_Resolve_CheckB:
	calr RhythmBuf_FillEmptyPattern

VoiceSlot_Resolve_StoreA:
	anddi8 13744, 251
	ldda8 w, 13709
	calr RhythmROM_CalcPatternAddr
	ldda16 xiy, 13676
	ldda16 xde, 13722
	bitda 2, 13745
	jr z, VoiceSlot_Resolve_CheckC
	calr RhythmBuf_LoadPattern
	jr VoiceSlot_Resolve_StoreB

VoiceSlot_Resolve_CheckC:
	calr RhythmBuf_FillEmptyPattern

VoiceSlot_Resolve_StoreB:
	anddi8 13744, 251
	ldda8 w, 13710
	calr RhythmROM_CalcPatternAddr
	ldda16 xiy, 13678
	ldda16 xde, 13724
	bitda 3, 13745
	jr z, VoiceSlot_Resolve_CheckD
	calr RhythmBuf_LoadPattern
	jr VoiceSlot_Resolve_StoreC

VoiceSlot_Resolve_CheckD:
	calr RhythmBuf_FillEmptyPattern

VoiceSlot_Resolve_StoreC:
	anddi8 13744, 251
	ldda8 w, 13711
	calr RhythmROM_CalcPatternAddr
	ldda16 xiy, 13680
	ldda16 xde, 13726
	bitda 4, 13745
	jr z, VoiceSlot_Resolve_CheckE
	calr RhythmBuf_LoadPattern
	jr VoiceSlot_Resolve_StoreD

VoiceSlot_Resolve_CheckE:
	calr RhythmBuf_FillEmptyPattern

VoiceSlot_Resolve_StoreD:
	anddi8 13744, 251
	ldda8 w, 13712
	calr RhythmROM_CalcPatternAddr
	ldda16 xiy, 13682
	ldda16 xde, 13728
	bitda 5, 13745
	jr z, VoiceSlot_Resolve_StoreE
	calr RhythmBuf_LoadPattern
	jr VoiceSlot_Resolve_Done

VoiceSlot_Resolve_StoreE:
	calr RhythmBuf_FillEmptyPattern

VoiceSlot_Resolve_Done:
	anddi8 13744, 251
	ret

__pad_F63BDA:
	nop
	nop
	ldda8	w, 13708
	calr	-1279
	ldda16	iy, 13674
	ldda16	ix, 13696
	ldda16	de, 13720
	calr	577
	ldda8	w, 13713
	calr	-1301
	ldda16	iy, 13684
	calr	563
	.byte 0xc1, 0xb0, 0x35, 0x3c, 0xfb
	ldda8	w, 13709
	calr	-1320
	ldda16	iy, 13676
	ldda16	ix, 13698
	ldda16	de, 13722
	calr	536
	ldda8	w, 13714
	calr	-1342
	ldda16	iy, 13686
	calr	522
	.byte 0xc1, 0xb0, 0x35, 0x3c, 0xfb
	ldda8	w, 13710
	calr	-1361
	ldda16	iy, 13678
	ldda16	ix, 13700
	ldda16	de, 13724
	calr	495
	ldda8	w, 13715
	calr	-1383
	ldda16	iy, 13688
	calr	481
	.byte 0xc1, 0xb0, 0x35, 0x3c, 0xfb
	ldda8	w, 13711
	calr	-1402
	ldda16	iy, 13680
	ldda16	ix, 13702
	ldda16	de, 13726
	calr	454
	ldda8	w, 13716
	calr	-1424
	ldda16	iy, 13690
	calr	440
	.byte 0xc1, 0xb0, 0x35, 0x3c, 0xfb
	ldda8	w, 13712
	calr	-1443
	ldda16	iy, 13682
	ldda16	ix, 13704
	ldda16	de, 13728
	calr	413
	ldda8	w, 13717
	calr	-1465
	ldda16	iy, 13692
	calr	399
	.byte 0xc1, 0xb0, 0x35, 0x3c, 0xfb
	ret
	nop
	nop

AccSection_ProcessEntry:
	ldda8 w, 13708
	calr RhythmROM_CalcPatternAddr
	ldda16 xiy, 13674
	ldda16 xde, 13720
	bitda 0, 13745
	jr nz, AccSection_Process_Loop
	bitda 1, 13745
	jr nz, AccSection_Process_Loop
	jr AccSection_Process_Return

AccSection_Process_Loop:
	calr RhythmBuf_LoadPattern
	ldda8 w, 13713
	calr RhythmROM_CalcPatternAddr
	ldda16 xiy, 13684
	calr RhythmBuf_LoadPattern
	ldda8 w, 13760
	calr RhythmROM_CalcPatternAddr
	ldda16 xiy, 13750
	calr RhythmBuf_LoadPattern
	ldda8 w, 13776
	calr RhythmROM_CalcPatternAddr
	ldda16 xiy, 13766
	calr RhythmBuf_LoadPattern
	jr __pad_F63CFB

AccSection_Process_Return:
	calr RhythmBuf_FillEmptyPattern

__pad_F63CFB:
	anddi8 13744, 251
	ldda8 w, 13709
	calr RhythmROM_CalcPatternAddr
	ldda16 xiy, 13676
	ldda16 xde, 13722
	bitda 2, 13745
	jr z, AccSection_Process2_Return
	calr RhythmBuf_LoadPattern
	ldda8 w, 13714
	calr RhythmROM_CalcPatternAddr
	ldda16 xiy, 13686
	calr RhythmBuf_LoadPattern
	ldda8 w, 13761
	calr RhythmROM_CalcPatternAddr
	ldda16 xiy, 13752
	calr RhythmBuf_LoadPattern
	ldda8 w, 13777
	calr RhythmROM_CalcPatternAddr
	ldda16 xiy, 13768
	calr RhythmBuf_LoadPattern
	jr __pad_F63D47

AccSection_Process2_Return:
	calr RhythmBuf_FillEmptyPattern

__pad_F63D47:
	anddi8 13744, 251
	ldda8 w, 13710
	calr RhythmROM_CalcPatternAddr
	ldda16 xiy, 13678
	ldda16 xde, 13724
	bitda 3, 13745
	jr z, AccSection_Process3_Return
	calr RhythmBuf_LoadPattern
	ldda8 w, 13715
	calr RhythmROM_CalcPatternAddr
	ldda16 xiy, 13688
	calr RhythmBuf_LoadPattern
	ldda8 w, 13762
	calr RhythmROM_CalcPatternAddr
	ldda16 xiy, 13754
	calr RhythmBuf_LoadPattern
	ldda8 w, 13778
	calr RhythmROM_CalcPatternAddr
	ldda16 xiy, 13770
	calr RhythmBuf_LoadPattern
	jr __pad_F63D93

AccSection_Process3_Return:
	calr RhythmBuf_FillEmptyPattern

__pad_F63D93:
	anddi8 13744, 251
	ldda8 w, 13711
	calr RhythmROM_CalcPatternAddr
	ldda16 xiy, 13680
	ldda16 xde, 13726
	bitda 4, 13745
	jr z, AccSection_Process4_Return
	calr RhythmBuf_LoadPattern
	ldda8 w, 13716
	calr RhythmROM_CalcPatternAddr
	ldda16 xiy, 13690
	calr RhythmBuf_LoadPattern
	ldda8 w, 13763
	calr RhythmROM_CalcPatternAddr
	ldda16 xiy, 13756
	calr RhythmBuf_LoadPattern
	ldda8 w, 13779
	calr RhythmROM_CalcPatternAddr
	ldda16 xiy, 13772
	calr RhythmBuf_LoadPattern
	jr __pad_F63DDF

AccSection_Process4_Return:
	calr RhythmBuf_FillEmptyPattern

__pad_F63DDF:
	anddi8 13744, 251
	ldda8 w, 13712
	calr RhythmROM_CalcPatternAddr
	ldda16 xiy, 13682
	ldda16 xde, 13728
	bitda 5, 13745
	jr z, AccSection_Process5_Return
	calr RhythmBuf_LoadPattern
	ldda8 w, 13717
	calr RhythmROM_CalcPatternAddr
	ldda16 xiy, 13692
	calr RhythmBuf_LoadPattern
	ldda8 w, 13764
	calr RhythmROM_CalcPatternAddr
	ldda16 xiy, 13758
	calr RhythmBuf_LoadPattern
	ldda8 w, 13780
	calr RhythmROM_CalcPatternAddr
	ldda16 xiy, 13774
	calr RhythmBuf_LoadPattern
	jr __pad_F63E2B

AccSection_Process5_Return:
	calr RhythmBuf_FillEmptyPattern

__pad_F63E2B:
	anddi8 13744, 251
	ret

AccSection_Finalize:
	.byte 0x00, 0x00

; ============================================================================
; RhythmBuf_LoadPattern - Load rhythm pattern from ROM to DRAM buffer
; ============================================================================
; Input:  XIY = source ROM pointer, XIZ = write offset, XDE = dest base
; Output: Pattern data at 0x95C00 + index*256
; Copies bytes until end marker (0x83) or buffer full (0xFE). Chains buffers.
; ============================================================================
RhythmBuf_LoadPattern:
	bitda 0, 13744
	jr z, AccFill_CheckPattern
	jp AccFill_AdvCheck_Done

AccFill_CheckPattern:
	add iy, 0x6
	and xiy, 0xFFFF
	add xiy, xix
	bitda 2, 13744
	jr z, AccFill_ProcessEntry
	jr AccFill_ProcessDone

AccFill_ProcessEntry:
	ordi8 13744, 4
	stda16 13718, xde
	lds32 xiz, 6

AccFill_ProcessDone:
	ld a, (xiy)
	ldda16 xhl, 13718
	calr AccPat_IndexToAddress
	add xhl, xiz
	ld (xhl), a

__pad_F63E69:
	cp a, 0x83
	jr z, AccFill_AdvCheck_Return
	inc 1, xiy
	inc 1, xiz
	cp xiz, 0xFE
	jr ule, AccFill_AdvanceAndCheck
	calr __pad_F634B5
	bitda 0, 13744
	jr nz, AccFill_AdvCheck_Return
	push xiy
	ldda16 xhl, 13718
	calr AccPat_IndexToAddress
	lds32 xiy, 3
	add xiy, xhl
	ld (xiy), de
	ld hl, de
	calr AccPat_IndexToAddress
	lds32 xiy, 1
	add xiy, xhl
	ldda16 xwa, 13718
	ld (xiy), wa
	stda16 13718, xde
	ormi8 (xhl), 0x80
	decdi16 1, 13524
	lds32 xiz, 6
	pop xiy

AccFill_AdvanceAndCheck:
	ld a, (xiy)
	ld hl, de
	calr AccPat_IndexToAddress
	add xhl, xiz
	ld (xhl), a
	jr __pad_F63E69

AccFill_AdvCheck_Return:
	ldw wa, 0xFFFF
	ld hl, de
	calr AccPat_IndexToAddress
	lds32 xiy, 3

AccFill_AdvCheck_Done:
	ret

__pad_F63EC6:
	nop
	nop
	push_sr
	.byte 0x04
	ei	0x08
	.byte 0x01
	push_sr
	pop_sr
	.byte 0x04
	halt
	ei	0x07
	ldio	1, 2
	pop_sr
	.byte 0x04
	halt
	ei	0x07
	.byte 0x08

RhythmBuf_FillEmptyPattern:
	ldda32 xiy, 13664
	ld l, (xiy + 12)
	xor h, h
	ld xix, 0xF63EC8
	ld_srib3 W, 0x07, 0xF0, 0xEC
	ld a, (xiy + 13)
	and a, 0x7
	inc 1, a
	mul8rr a, w
	push xwa
	ld hl, de
	calr AccPat_IndexToAddress
	pop xwa
	add xhl, 0x6
	ld e, a
	ldb a, 0x81

StyleConvert_ReloadParams:
	ld (xhl), a
	inc 1, xhl
	dec 1, e
	cps e, 0
	jr nz, StyleConvert_ReloadParams
	ld (xhl), 0x83
	ret

StyleConvert_Reload_Loop:
	nop
	nop
	cpdi8	13551, 16
	jr	ule, 30
	ldb	a, 123
	cpdi8	13549, 132
	jr	c, 13
	add	a, 6
	cpdi8	13549, 136
	jr	c, 3
	add	a, 6
	addda8	a, 13551
	stda8	13549, a
	ret
	nop
	nop

AccPat_CalcAccentVelocity:
	cpdi8 13551, 19
	jr ule, StyleConvert_Reload_Return
	ldb a, 0x78
	cpdi8 13549, 132
	jr c, StyleConvert_Reload_CheckEnd
	add a, 0x6
	cpdi8 13549, 136
	jr c, StyleConvert_Reload_CheckEnd
	add a, 0x6

StyleConvert_Reload_CheckEnd:
	addda8 a, 13551
	stda8 13549, a
	jr StyleConvert_Reload_Done

StyleConvert_Reload_Return:
	cpdi8 13551, 16
	jr c, StyleConvert_Reload_Done
	ldb a, 0x70
	cpdi8 13549, 132
	jr c, StyleConvert_Reload_Fallback
	add a, 0x4
	cpdi8 13549, 136
	jr c, StyleConvert_Reload_Fallback
	add a, 0x4

StyleConvert_Reload_Fallback:
	addda8 a, 13551
	stda8 13549, a

StyleConvert_Reload_Done:
	ret

__pad_F63F8F:
	ldda8	l, 13549
	ldda8	h, 13550
	call	16069349
	ld	de, hl
	ld	xiy, 16138178
	xor	hl, hl
	.byte 0xd3, 0x07, 0xf4, 0xec, 0x20
	cp	wa, 65535
	jr	z, 14
	cp	wa, de
	jr	z, 6
	add	hl, 2
	jr	-21
	ldb	a, 1
	jr	2
	ldb	a, 0
	ret
	nop
	nop
	ei	0x00
	ei	0x01
	ei	0x02
	ei	0x03
	reti
	nop
	reti
	.byte 0x01
	reti
	.byte 0x02
	swi	7
	swi	7
	swi	7
	swi	7
	ldda8	l, 13549
	ldda8	h, 13526
	cp	l, 128
	jr	nc, 42
	cp	h, 12
	jr	nc, 12
	ldb	a, 0
	ldda8	w, 64609
	jr	z, 2
	ldb	a, 1
	jr	48
	ldda8	a, 13526
	sub	a, 12
	and	a, 3
	ldda8	w, 64609
	jr	z, 3
	or	a, 4
	xor	hl, hl
	ld	l, a
	jr	23
	cp	h, 12
	jr	nc, 4
	ldb	a, 0
	jr	14
	ldda8	a, 13526
	sub	a, 12
	and	a, 3
	xor	hl, hl
	ld	l, a
	stda8	13551, a
	ret
	nop
	nop
	.byte 0x04
	ldio	9, 6
	.byte 0x04
	ldio	9, 6
	ret
	.byte 0xf1, 0xd1, 0x34, 0xc8
	jr	nz, 4
	jp	16138551
	ldda8	l, 13526
	ldda8	a, 13549
	ldda8	w, 13550
	pushw	hl
	pushw	wa
	cpdi8	13549, 128
	jr	c, 4
	jp	16138524
	cpdi8	13526, 0
	jr	z, 4
	jp	16138524
	stdi8	13526, 0
	stdi8	13526, 6
	stdi8	13526, 7
	stdi8	13526, 8
	stdi8	13526, 9
	.byte 0xc1, 0xb0, 0x35, 0x3c, 0xf7
	stdi8	13551, 0
	stdi8	13526, 0
	.byte 0xc1, 0xd1, 0x34, 0x3e, 0x01
	calr	-3905
	.byte 0xf1, 0xb0, 0x35, 0xc8
	jr	z, 5
	.byte 0xc1, 0xb0, 0x35, 0x3e, 0x08
	stdi8	13551, 4
	stdi8	13526, 6
	.byte 0xc1, 0xd1, 0x34, 0x3e, 0x01
	calr	-3934
	.byte 0xf1, 0xb0, 0x35, 0xc8
	jr	z, 5
	.byte 0xc1, 0xb0, 0x35, 0x3e, 0x08
	stdi8	13551, 8
	stdi8	13526, 7
	.byte 0xc1, 0xd1, 0x34, 0x3e, 0x01
	calr	-3963
	.byte 0xf1, 0xb0, 0x35, 0xc8
	jr	z, 5
	.byte 0xc1, 0xb0, 0x35, 0x3e, 0x08
	stdi8	13551, 9
	stdi8	13526, 8
	.byte 0xc1, 0xd1, 0x34, 0x3e, 0x01
	calr	-3992
	.byte 0xf1, 0xb0, 0x35, 0xc8
	jr	z, 5
	.byte 0xc1, 0xb0, 0x35, 0x3e, 0x08
	stdi8	13551, 6
	stdi8	13526, 9
	.byte 0xc1, 0xd1, 0x34, 0x3e, 0x01
	calr	-4021
	.byte 0xf1, 0xb0, 0x35, 0xc8
	jr	z, 5
	.byte 0xc1, 0xb0, 0x35, 0x3e, 0x08, 0xf1, 0xb0, 0x35, 0xcb
	jr	z, 5
	.byte 0xc1, 0xb0, 0x35, 0x3e, 0x01
	jr	13
	stdi8	13551, 0
	.byte 0xc1, 0xd1, 0x34, 0x3e, 0x01
	calr	-4058
	popw	wa
	popw	hl
	stda8	13550, w
	stda8	13549, a
	stda8	13526, l
	ret
	nop
	nop

AccWidget_DispatchTable:
	ld xiy, 0x9B4000
	ld xix, 0x94800
	ldw bc, 0x8000
	ldirw
	jp AccWidget_Dispatch_Return

AccWidget_Dispatch_Return:
	ret

__pad_F6414E:
	.byte 0x00, 0x00

AccWidget_ProcessSpecialCmd:
	cpdi8 13550, 0
	jr nz, __pad_F64174
	ldda8 a, 13549
	and a, 0x7F
	ld xix, 0xF644FF
	ld_srib3 A, 0x03, 0xF0, 0xE0
	ldda8 w, 13526
	sub w, 0x1E
	cp a, w
	jrl z, DrumKit_Return

__pad_F64174:
	ldda8 a, 13549
	ldda8 w, 13550
	ldda8 l, 13551
	ldda8 h, 13526
	pushw wa
	pushw hl
	ordi8 13517, 128
	stdi8 13551, 16
	ldda8 l, 13526
	sub l, 0x1E
	stda8 14757, l
	ld xix, 0xF6453B
	ld_srib3 L, 0x03, 0xF0, 0xEC
	stda8 13526, l
	stda8 14758, l
	calr AccPat_CalcAccentVelocity
	call AccPat_InitWorkAreaFromSlot
	ldda8 a, 13549
	and a, 0x7F
	stda8 14764, a
	ldda8 a, 13526
	stda8 14765, a
	push xix
	ld xix, 0x94800
	stda32 14766, xix
	stda32 14770, xix
	pop xix
	calr AccPatch_LoadDualVoiceParams
	bitda 0, 13744
	jrl nz, DrumKit_ErrorFallbackLoop
	stdi8 13551, 17
	ldda8 l, 14758
	inc 1, l
	stda8 13526, l
	calr AccPat_CalcAccentVelocity
	call AccPat_InitWorkAreaFromSlot
	ldda8 a, 13549
	and a, 0x7F
	stda8 14764, a
	ldda8 a, 13526
	stda8 14765, a
	push xix
	ld xix, 0x94800
	stda32 14766, xix
	stda32 14770, xix
	pop xix
	calr AccPatch_LoadDualVoiceParams
	bitda 0, 13744
	jrl nz, DrumKit_ErrorFallbackLoop
	stdi8 13551, 18
	ldda8 l, 14758
	add l, 0x2
	stda8 13526, l
	calr AccPat_CalcAccentVelocity
	call AccPat_InitWorkAreaFromSlot
	ldda8 a, 13549
	and a, 0x7F
	stda8 14764, a
	ldda8 a, 13526
	stda8 14765, a
	push xix
	ld xix, 0x94800
	stda32 14766, xix
	stda32 14770, xix
	pop xix
	calr AccPatch_LoadDualVoiceParams
	bitda 0, 13744
	jrl nz, DrumKit_ErrorFallbackLoop
	stdi8 13551, 19
	ldda8 l, 14758
	add l, 0x3
	stda8 13526, l
	calr AccPat_CalcAccentVelocity
	call AccPat_InitWorkAreaFromSlot
	ldda8 a, 13549
	and a, 0x7F
	stda8 14764, a
	ldda8 a, 13526
	stda8 14765, a
	push xix
	ld xix, 0x94800
	stda32 14766, xix
	stda32 14770, xix
	pop xix
	calr AccPatch_LoadDualVoiceParams
	bitda 0, 13744
	jrl nz, DrumKit_ErrorFallbackLoop
	stdi8 13551, 20
	ldda8 a, 13549
	pushw wa
	calr AccPat_CalcAccentVelocity
	ldda8 l, 14757
	ld xix, 0xF6453E
	ld_srib3 L, 0x03, 0xF0, 0xEC
	stda8 13526, l
	call AccPat_InitWorkAreaFromSlot
	ldda8 a, 13549
	and a, 0x7F
	stda8 14764, a
	ldda8 a, 13526
	stda8 14765, a
	push xix
	ld xix, 0x94800
	stda32 14766, xix
	stda32 14770, xix
	pop xix
	calr AccPatch_LoadDualVoiceParams
	popw wa
	stda8 13549, a
	bitda 0, 13744
	jrl nz, DrumKit_ErrorFallbackLoop
	stdi8 13551, 21
	ldda8 a, 13549
	pushw wa
	calr AccPat_CalcAccentVelocity
	ldda8 l, 14757
	ld xix, 0xF64541
	ld_srib3 L, 0x03, 0xF0, 0xEC
	stda8 13526, l
	call AccPat_InitWorkAreaFromSlot
	ldda8 a, 13549
	and a, 0x7F
	stda8 14764, a
	ldda8 a, 13526
	stda8 14765, a
	push xix
	ld xix, 0x94800
	stda32 14766, xix
	stda32 14770, xix
	pop xix
	calr AccPatch_LoadDualVoiceParams
	popw wa
	stda8 13549, a
	bitda 0, 13744
	jrl nz, DrumKit_ErrorFallbackLoop
	stdi8 13551, 22
	ldda8 a, 13549
	pushw wa
	calr AccPat_CalcAccentVelocity
	ldda8 l, 14757
	ld xix, 0xF64544
	ld_srib3 L, 0x03, 0xF0, 0xEC
	stda8 13526, l
	call AccPat_InitWorkAreaFromSlot
	ldda8 a, 13549
	and a, 0x7F
	stda8 14764, a
	ldda8 a, 13526
	stda8 14765, a
	push xix
	ld xix, 0x94800
	stda32 14766, xix
	stda32 14770, xix
	pop xix
	calr AccPatch_LoadDualVoiceParams
	popw wa
	stda8 13549, a
	bitda 0, 13744
	jrl nz, DrumKit_ErrorFallbackLoop
	stdi8 13551, 23
	ldda8 a, 13549
	pushw wa
	calr AccPat_CalcAccentVelocity
	ldda8 l, 14757
	ld xix, 0xF64547
	ld_srib3 L, 0x03, 0xF0, 0xEC
	stda8 13526, l
	call AccPat_InitWorkAreaFromSlot
	ldda8 a, 13549
	and a, 0x7F
	stda8 14764, a
	ldda8 a, 13526
	stda8 14765, a
	push xix
	ld xix, 0x94800
	stda32 14766, xix
	stda32 14770, xix
	pop xix
	calr AccPatch_LoadDualVoiceParams
	popw wa
	stda8 13549, a
	bitda 0, 13744
	jrl nz, DrumKit_ErrorFallbackLoop
	stdi8 13551, 24
	ldda8 a, 13549
	pushw wa
	calr AccPat_CalcAccentVelocity
	ldda8 l, 14757
	ld xix, 0xF6454A
	ld_srib3 L, 0x03, 0xF0, 0xEC
	stda8 13526, l
	call AccPat_InitWorkAreaFromSlot
	ldda8 a, 13549
	and a, 0x7F
	stda8 14764, a
	ldda8 a, 13526
	stda8 14765, a
	push xix
	ld xix, 0x94800
	stda32 14766, xix
	stda32 14770, xix
	pop xix
	calr AccPatch_LoadDualVoiceParams
	popw wa
	stda8 13549, a
	bitda 0, 13744
	jrl nz, DrumKit_ErrorFallbackLoop
	stdi8 13551, 25
	ldda8 a, 13549
	pushw wa
	calr AccPat_CalcAccentVelocity
	ldda8 l, 14757
	ld xix, 0xF6454D
	ld_srib3 L, 0x03, 0xF0, 0xEC
	stda8 13526, l
	call AccPat_InitWorkAreaFromSlot
	ldda8 a, 13549
	and a, 0x7F
	stda8 14764, a
	ldda8 a, 13526
	stda8 14765, a
	push xix
	ld xix, 0x94800
	stda32 14766, xix
	stda32 14770, xix
	pop xix
	calr AccPatch_LoadDualVoiceParams
	popw wa
	stda8 13549, a
	bitda 0, 13744
	jr z, DrumKit_SetErrorCode20

DrumKit_ErrorFallbackLoop:
	xor c, c
	ld xix, 0xF6472A

DrumKit_ErrorFallbackSlotIter:
	ldda8 a, 14757
	ld w, a
	sll a, 3
	sll w, 1
	add a, w
	extz wa
	extz xwa
	add xwa, xix
	ld_srib3 A, 0x03, 0xE0, 0xE4
	stda8 13526, a
	push xbc
	push xix
	call AccPat_InitWorkAreaFromSlot
	pop xix
	pop xbc
	inc 1, c
	cp c, 0xA
	jr c, DrumKit_ErrorFallbackSlotIter
	stdi8 32578, 23
	call DrumVoice_NotifyEE
	ldb a, 0x8
	call MIDI_SendSysExCmd
	jr DrumKit_RestoreRegisters

DrumKit_SetErrorCode20:
	stdi8 32578, 20
	call DrumVoice_NotifyEE

DrumKit_RestoreRegisters:
	popw hl
	popw wa
	stda8 13551, l
	stda8 13526, h
	stda8 13550, w
	stda8 13549, a

DrumKit_Return:
	ret

DrumKit_GroupAssignTable:
	nop
	nop
	nop
	nop
	.byte 0x01, 0x01, 0x01, 0x01
	push_sr
	push_sr
	push_sr
	push_sr
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
	push_sr
	push_sr
	push_sr
	push_sr
	push_sr
	push_sr
	nop
	nop
	nop
	nop
	.byte 0x04, 0x04, 0x04, 0x04
	ldio	8, 8
	ldio	0, 0
	nop
	nop
	nop
	nop
	.byte 0x04, 0x04, 0x04, 0x04, 0x04, 0x04
	ldio	8, 8
	ldio	8, 8
	nop
	.byte 0x04
	ldio	12, 18
	.byte 0x18
	decf
	zcf
	.byte 0x19
	ret
	push_a
	.byte 0x1a, 0x0f, 0x15
	jp	1840656
	scf
	ldf	29

RhythmROM_LoadDrumKit:
	ldda8 a, 13549
	ldda8 w, 13550
	ldda8 l, 13551
	ldda8 h, 13526
	pushw wa
	pushw hl
	stdi8 13551, 0
	ldda8 l, 13526
	sub l, 0x1E
	stda8 14757, l
	sll l, 2
	ld xix, 0xF6451D
	ld_srib3 L, 0x03, 0xF0, 0xEC
	stda8 13526, l
	stda8 14758, l
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher
	bitda 0, 13744
	jrl nz, DrumKit_PatternLoadFailed
	stdi8 13551, 1
	ldda8 l, 14758
	inc 1, l
	stda8 13526, l
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher
	bitda 0, 13744
	jrl nz, DrumKit_PatternLoadFailed
	stdi8 13551, 2
	ldda8 l, 14758
	add l, 0x2
	stda8 13526, l
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher
	bitda 0, 13744
	jrl nz, DrumKit_PatternLoadFailed
	stdi8 13551, 3
	ldda8 l, 14758
	add l, 0x3
	stda8 13526, l
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher
	bitda 0, 13744
	jrl nz, DrumKit_PatternLoadFailed
	stdi8 13551, 4
	ldda8 l, 14757
	ld xix, 0xF6453E
	ld_srib3 L, 0x03, 0xF0, 0xEC
	stda8 13526, l
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher
	bitda 0, 13744
	jrl nz, DrumKit_PatternLoadFailed
	stdi8 13551, 5
	ldda8 l, 14757
	ld xix, 0xF64541
	ld_srib3 L, 0x03, 0xF0, 0xEC
	stda8 13526, l
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher
	bitda 0, 13744
	jrl nz, DrumKit_PatternLoadFailed
	stdi8 13551, 10
	ldda8 l, 14757
	ld xix, 0xF64544
	ld_srib3 L, 0x03, 0xF0, 0xEC
	stda8 13526, l
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher
	bitda 0, 13744
	jrl nz, DrumKit_PatternLoadFailed
	stdi8 13551, 11
	ldda8 l, 14757
	ld xix, 0xF64547
	ld_srib3 L, 0x03, 0xF0, 0xEC
	stda8 13526, l
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher
	bitda 0, 13744
	jrl nz, DrumKit_PatternLoadFailed
	stdi8 13551, 6
	ldda8 l, 14757
	ld xix, 0xF6454A
	ld_srib3 L, 0x03, 0xF0, 0xEC
	stda8 13526, l
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher
	bitda 0, 13744
	jr nz, DrumKit_PatternLoadFailed
	stdi8 13551, 7
	ldda8 l, 14757
	ld xix, 0xF6454D
	ld_srib3 L, 0x03, 0xF0, 0xEC
	stda8 13526, l
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher
	bitda 0, 13744
	jr z, DrumKit_AllPatternsOK

DrumKit_PatternLoadFailed:
	xor c, c
	ld xix, 0xF6472A

DrumKit_FallbackSlotLoop:
	ldda8 a, 14757
	ld w, a
	sll a, 3
	sll w, 1
	add a, w
	extz wa
	extz xwa
	add xwa, xix
	ld_srib3 A, 0x03, 0xE0, 0xE4
	stda8 13526, a
	push xbc
	push xix
	call AccPat_InitWorkAreaFromSlot
	pop xix
	pop xbc
	inc 1, c
	cp c, 0xA
	jr c, DrumKit_FallbackSlotLoop
	stdi8 32578, 23
	call DrumVoice_NotifyEE
	ldb a, 0x8
	call MIDI_SendSysExCmd
	jr DrumKit_Epilogue

DrumKit_AllPatternsOK:
	stdi8 32578, 20
	call DrumVoice_NotifyEE

DrumKit_Epilogue:
	popw hl
	popw wa
	stda8 13526, h
	stda8 13551, l
	stda8 13550, w
	stda8 13549, a
	ret

DrumKit_FallbackSlotTable:
	nop
	.byte 0x01
	push_sr
	pop_sr
	incf
	decf
	ret
	retd	0x1110
	.byte 0x04
	halt
	ei	0x07
	ccf
	zcf
	push_a
	pop_a
	ex_ff
	ldf	8
	push 10
	pushw 6424
	.byte 0x1a, 0x1b, 0x1d, 0x1d

DrumParam_Wrapper:
	calr DrumParam_Lookup
	ret

DrumParam_Lookup:
	push xhl
	lds32 xhl, 0
	and w, 0x7
	sll w, 2
	ld l, w
	add xhl, 0xF6476B
	ld xhl, (xhl)
	push_a
	lds32 xwa, 0
	pop_a
	add xhl, xwa
	ld a, (xhl)
	pop xhl
	ret

DrumParam_PointerTableAndData:
	nop
	nop
	cp	iz, (xhl+71)
	nop
	muls	xbc, xhl
	.byte 0xf6
	nop
	.byte 0xbb, 0x48, 0xf6
	nop
	jrl	ugt, -2487
	nop
	pop	xhl
	popw	wa
	.byte 0xf6
	nop
	jp	63049
	swi	3
	ld	xsp, 1201340662
	.byte 0xf6
	nop
	.byte 0xf4, 0xf4, 0xf4, 0xf4, 0xf4, 0xf4
	.fill 8, 1, 0xf4
	.byte 0xf4, 0xf4, 0x00, 0x00
	nop
	nop
	nop
	nop
	.zero 40
	nop
	nop
	jrl	nc, 32639
	jrl	nc, 32639
	.fill 8, 1, 0x7f
	.fill 8, 1, 0x7f
	.fill 8, 1, 0x7f
	.fill 8, 1, 0x7f
	.fill 8, 1, 0x7f
	jrl	nc, 127
	nop
	nop
	nop
	nop
	nop
	.zero 18
	.ascii "000000000000000000000000000000000000000000000000"
	.byte 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f
	.fill 8, 1, 0x7f
	.fill 8, 1, 0x7f
	.byte 0x7f, 0x7f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x18, 0x18
	.fill 8, 1, 0x18
	.fill 8, 1, 0x18
	.byte 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x30, 0x30
	.ascii "0000000000000000000000HHHHHHHHHHHHHHHHHHHHHHHH"
	.byte 0x7f, 0x7f
	.fill 8, 1, 0x7f
	.byte 0x7f, 0x7f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.fill 8, 1, 0x0c
	.byte 0x0c, 0x0c, 0x0c, 0x0c, 0x18, 0x18, 0x18, 0x18
	.fill 8, 1, 0x18
	.ascii "$$$$$$$$$$$$000000000000<<<<<<<<<<<<IIIIIIIIIIIITTTTTTTTTTTT"
	.byte 0x7f, 0x7f, 0x7f, 0x7f
	.byte 0x7f, 0x7f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 10
	.ascii "                                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
	.byte 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f
	.fill 8, 1, 0x7f
	.byte 0x7f, 0x7f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10
	.fill 8, 1, 0x10
	.byte 0x10, 0x10
	.ascii "                0000000000000000@@@@@@@@@@@@@@@@PPPPPPPPPPPPPPPP"
	.byte 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f
	.byte 0x7f, 0x7f, 0x00, 0x00, 0x00, 0x00, 0x08, 0x08
	.byte 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x10, 0x10
	.byte 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x18, 0x18
	.byte 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x20, 0x20
	.ascii "      ((((((((0000000088888888@@@@@@@@HHHHHHHHPPPPPPPPXXXXXXXX"
	.byte 0x7f, 0x7f
	.byte 0x7f, 0x7f

DrumKitInit_Wrapper:
	push xiz
	call DrumKitInit_Entry
	pop xiz
	ret

DrumKitInit_Entry:
	ldb a, 0x48
	call CtrlPanel_SetIndicatorBit
	cpdi8 36149, 14
	jr nz, DrumKitInit_Setup
	jrl DrumKitInit_Return

DrumKitInit_Setup:
	stdi8 13553, 0
	stdi8 13531, 0
	stdi8 14100, 4
	stdi8 14101, 0
	stdi8 14102, 1
	call AccWrap_PlayModeDispatch
	ordi8 10407, 4
	stdi8 14235, 64
	ldda8 a, 64602
	stda8 13549, a
	ldda8 a, 64603
	stda8 13550, a
	ldda8 a, 64602
	stda8 13611, a
	ldda8 a, 64603
	stda8 13612, a
	calr DrumKit_SendProgramChange
	bitda 2, 64607
	jr nz, DrumKitInit_ClearAssignFlags
	bitda 3, 64607
	jr z, DrumKitInit_CheckExtAssign

DrumKitInit_ClearAssignFlags:
	anddi8 64607, 243
	ldb d, 0x5
	ldb e, 0x48
	xor wa, wa
	call SwbtWr_QueuePostEvent

DrumKitInit_CheckExtAssign:
	bitda 2, 64608
	jr z, DrumKitInit_FinalSetup
	anddi8 64608, 251
	ldb d, 0x6
	ldb e, 0x48
	xor wa, wa
	call SwbtWr_QueuePostEvent

DrumKitInit_FinalSetup:
	call AccPatch_CountSlots_Wrapper
	stdi8 13580, 0
	call SeqAcc_SetIndicator_PB
	stdi16 61854, 0
	call Audio_CheckSubsystemReady
	anddi8 58338, 158
	ordi8 13517, 64

DrumKitInit_Return:
	ret

DrumKit_SendProgramChange:
	lds32 xhl, 0
	ldda8 l, 13526
	cp l, 0x1E
	jr c, DrumKit_SendPC_MaskAndSend
	sub l, 0x1E
	sll l, 2

DrumKit_SendPC_MaskAndSend:
	and l, 0x1F
	add l, 0x80
	ld xbc, 0xFC5A
	ldb a, 0x0
	lda_dri3 XSP, 0x03, 0xE4, 0xE0
	ldb a, 0x1
	ld_srib3 H, 0x03, 0xE4, 0xE0
	and h, 0x80
	lda_dri3 XIZ, 0x03, 0xE4, 0xE0
	calr DrumKit_PostMidiEvents
	ret

DrumKitExit_Wrapper:
	push xiz
	call DrumKitExit_Entry
	pop xiz
	ret

DrumKitExit_Entry:
	ldb a, 0x48
	call CtrlPanel_SetIndicatorBit
	cpdi8 36148, 14
	jr nz, DrumKitExit_CheckState1
	jrl DrumKitExit_Return

DrumKitExit_CheckState1:
	cpdi8 36148, 1
	jr z, DrumKitExit_ClearFlags
	anddi8 36232, 254

DrumKitExit_ClearFlags:
	anddi8 10407, 251
	anddi8 58338, 254
	anddi8 58338, 247
	anddi8 58338, 223
	stdi8 13553, 0
	stdi8 14235, 0
	push xwa
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	call PartSelect_UpdateDisplayState
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	pop xwa
	bitda 6, 13517
	jr z, DrumKitExit_PostRestore
	anddi8 13517, 191
	ldda8 a, 13611
	stda8 64602, a
	ldda8 a, 13612
	and a, 0x7F
	anddi8 64603, 128
	orddm8 64603, a
	calr DrumKit_PostMidiEvents

DrumKitExit_PostRestore:
	call AccWrap_PlayModeDispatch
	calr DrumKit_ValidateBank
	call SeqAcc_RestorePlaybackState
	cpdi16 10408, 0
	jr nz, DrumKitExit_ExtraInit
	cpdi16 61854, 0
	jr nz, DrumKitExit_ExtraInit
	jr DrumKitExit_CheckAutoPlay

DrumKitExit_ExtraInit:
	call AccWrap_PlayModeDispatch

DrumKitExit_CheckAutoPlay:
	bitda 0, 12931
	jr nz, DrumKitExit_Return
	ordi8 13517, 128

DrumKitExit_Return:
	ret

DrumKitExit_DataPad:
	ret
	push	xiz
	call	16141266
	pop	xiz
	ret

DrumKit_ValidateBank:
	ldda8 a, 64602
	cp a, 0x80
	jr c, DrumKit_ValidateBank_Return
	cp a, 0x8B
	jr ule, DrumKit_ValidateBank_Return
	cp a, 0x91
	jr ugt, DrumKit_ValidateBank_Mid
	ldb l, 0x80
	jr DrumKit_ValidateBank_Apply

DrumKit_ValidateBank_Mid:
	cp a, 0x97
	jr ugt, DrumKit_ValidateBank_High
	ldb l, 0x84
	jr DrumKit_ValidateBank_Apply

DrumKit_ValidateBank_High:
	ldb l, 0x88

DrumKit_ValidateBank_Apply:
	push l
	calr DrumKit_StoreAndSendBank
	pop l
	and l, 0x1F
	stda8 13526, l
	calr DrumKit_SendProgramChange

DrumKit_ValidateBank_Return:
	ret

DrumKit_StoreAndSendBank:
	stda8 64602, l
	anddi8 64603, 128
	ldb h, 0x0
	call PartCtrl_WriteProgramChange
	ld xix, 0xFF92
	lda_dri3 XIZ, 0x03, 0xF0, 0xEC
	call DrumKit_PostMidiEvents
	ret

DrumKit_PostMidiEvents:
	ldb e, 0x48
	ldda8 a, 64603
	and a, 0x7F
	ldb d, 0x1
	ldb w, 0x0
	push_a
	call SwbtWr_QueuePostEvent
	pop_a
	ld h, a
	ldb e, 0x48
	ldda8 a, 64602
	and a, 0xFF
	ldb d, 0x0
	ldb w, 0x0
	push h
	push_a
	call SwbtWr_QueuePostEvent
	pop_a
	pop h
	ld l, a
	stdi8 37111, 72
	call PartCtrl_WriteProgramChange
	ldb c, 0x48
	call MIDI_SetupChannelParams
	ret

DrumKit_UpdateStatusFlags:
	ldda8 w, 13553
	and w, 0xC2
	bit 7, w
	jr z, DrumKit_StoreStatus
	ldda8 a, 14235
	bit 4, a
	jr z, DrumKit_StatusBit3
	or w, 0x3C

DrumKit_StatusBit3:
	bit 3, a
	jr z, DrumKit_StatusBit0
	or w, 0x39

DrumKit_StatusBit0:
	bit 0, a
	jr z, DrumKit_StatusBit1
	or w, 0x35

DrumKit_StatusBit1:
	bit 1, a
	jr z, DrumKit_StatusBit2
	or w, 0x2D

DrumKit_StatusBit2:
	bit 2, a
	jr z, DrumKit_StoreStatus
	or w, 0x1D

DrumKit_StoreStatus:
	stda8 13553, w
	ret

DrumKit_InlineCode1:
	push	xiz
	call	16141478
	pop	xiz
	ret
	ret
	push	xiz
	call	16141486
	pop	xiz
	ret
	cpdi8	36151, 177
	jr	z, 16
	calr	109
	stdi8	14235, 64
	.byte 0xc1, 0xcd, 0x34, 0x3c, 0xbf
	calr	6
	.byte 0xc1, 0xe2, 0xe3, 0x3c, 0x9e
	ret
	ldda8	e, 13517
	and	e, 48
	lds32	xhl, 0
	ldda8	l, 13526
	ld	xwa, 16141568
	add	xwa, xhl
	ld	a, (xwa)
	cp	a, e
	jr	z, 26
	cps	e, 0
	jr	nz, 4
	ldb	l, 0
	jr	11
	cp	e, 32
	jr	nz, 4
	ldb	l, 4
	jr	2
	ldb	l, 8
	stda8	13526, l
	calr	-529
	ret
	nop
	nop
	nop
	nop
	ldb	w, 32
	ldb	w, 32
	rcf
	rcf
	rcf
	rcf
	nop
	nop
	nop
	nop
	nop
	nop
	.ascii "      "
	.byte 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x3e
	.byte 0x1d, 0x25, 0x4d, 0xf6, 0x5e, 0x0e, 0xe8, 0xd0
	.byte 0xea, 0xd2, 0xc1, 0x5d, 0xfc, 0x21, 0xc9, 0xcc
	.byte 0x07, 0xc9, 0xd8, 0x6e, 0x1c, 0x21, 0x02, 0x20
	.byte 0x07, 0x25, 0x48, 0x24, 0x03, 0x1d, 0x12, 0xb4
	.byte 0xfd, 0x21, 0x08, 0xc1, 0x5d, 0xfc, 0xe9, 0x20
	.byte 0x08, 0x25, 0x48, 0x24, 0x03, 0x1d, 0xf1, 0xb3
	.byte 0xfd, 0x0e

DrumSlot_DispatchWrapper:
	push xiz
	call DrumSlot_Dispatch
	pop xiz
	ret

DrumSlot_Dispatch:
	cp hl, 0xA
	jr c, DrumSlot_ClampAndLookup
	lds hl, 0

DrumSlot_ClampAndLookup:
	ld xiy, 0xF64D75
	pushw hl
	sll hl, 2
	ld_sril3 XWA, 0x07, 0xF4, 0xEC
	popw hl
	call (xwa)
	calr DrumKit_SendProgramChange
	ret

DrumSlot_HandlerTable:
	.long DrumSlot_Handler_Type0
	.long DrumSlot_Handler_Type0
	.long DrumSlot_Handler_Type0
	.long DrumSlot_Handler_Type0
	.long DrumSlot_Handler_Type1
	.long DrumSlot_Handler_Type1
	.long DrumSlot_Handler_Type1
	.long DrumSlot_Handler_Type1
	.long DrumSlot_Handler_Type1
	.long DrumSlot_Handler_Type1
DrumSlot_Handler_Type0:
	calr	5
	ret
DrumSlot_Handler_Type1:
	; --- Wrapper: calr to F64DC4, ret (4 bytes) ---
	calr DrumSlot_OffsetCalc_Extended
	ret
DrumSlot_OffsetCalc_Simple:
	; --- Offset calc 1: add 0/4/8 to L based on (0x34CD) bits 5:4 (30 bytes) ---
	ldda8	e, 13517
	and e, 0x30
	cps	e, 0
	jr nz, DrumSlot_OffsetCalc_Check20
	jr t, DrumSlot_OffsetCalc_StoreAndRet
DrumSlot_OffsetCalc_Check20:
	cp e, 0x20
	jr nz, DrumSlot_OffsetCalc_AddHigh
	add l, 0x04
	jr t, DrumSlot_OffsetCalc_StoreAndRet
DrumSlot_OffsetCalc_AddHigh:
	add l, 0x08
DrumSlot_OffsetCalc_StoreAndRet:
	stda8	13526, l
	ret
DrumSlot_OffsetCalc_Extended:
	; --- Offset calc 2: add 8/0x0E/0x14 to L based on (0x34CD) bits 5:4 (33 bytes) ---
	ldda8	e, 13517
	and e, 0x30
	cps	e, 0
	jr nz, DrumSlot_ExtOffset_Check20
	add l, 0x08
	jr t, DrumSlot_ExtOffset_StoreAndRet
DrumSlot_ExtOffset_Check20:
	cp e, 0x20
	jr nz, DrumSlot_ExtOffset_AddHigh
	add l, 0x0E
	jr t, DrumSlot_ExtOffset_StoreAndRet
DrumSlot_ExtOffset_AddHigh:
	add l, 0x14
DrumSlot_ExtOffset_StoreAndRet:
	stda8	13526, l
	ret
RhythmPatInit_Wrapper:
	; --- Push XIZ wrapper for inner routine (7 bytes) ---
	push xiz
	call RhythmPatInit_Entry
	pop xiz
	ret
RhythmPatInit_Entry:
	; --- Conditional init: check (0x8D37), calr, store, optional call (39 bytes) ---
	cpdi8	36151, 178
	jr z, RhythmPatInit_Cleanup
	calr RhythmPatInit_LoadParams
	stdi8	14235, 32
	cpdi8	36151, 181
	jr nz, RhythmPatInit_Cleanup
	call AccWrap_PlayModeDispatch
	.byte 0xc1, 0xa7, 0x28, 0x3e, 0x04		; or (0x28A7), 0x04  [C1 prefix]
	jr t, RhythmPatInit_Cleanup
RhythmPatInit_Cleanup:
	.byte 0xc1, 0xe2, 0xe3, 0x3c, 0x9e		; and (0xE3E2), 0x9E  [C1 prefix]
	ret


RhythmPatInit_LoadParams:
	call AccPatch_GetCurrentSlotAddr
	ld a, (xiy + 12)
	stda8 13528, a
	ld l, a
	ld xwa, 0xF64E95
	ld_srib3 A, 0x03, 0xE0, 0xEC
	stda8 13529, a
	ld a, (xiy + 13)
	stda8 13527, a
	anddi8 13518, 127
	ld a, (xiy + 15)
	bit 7, a
	jr z, RhythmPatInit_FlagBit7
	ordi8 13518, 128

RhythmPatInit_FlagBit7:
	ld a, (xiy + 14)
	ld w, a
	and a, 0xF
	stda8 13545, a
	anddi8 13546, 143
	bit 4, w
	jr z, RhythmPatInit_Tempo4
	ordi8 13546, 16

RhythmPatInit_Tempo4:
	bit 5, w
	jr z, RhythmPatInit_Tempo5
	ordi8 13546, 32

RhythmPatInit_Tempo5:
	bit 6, w
	jr z, RhythmPatInit_CopyChannels
	ordi8 13546, 64

RhythmPatInit_CopyChannels:
	add xiy, 0x40
	ld xix, 0x34BC
	ld xbc, 0xD
	ldir85
	stib_dpi 0xF0, 0x00
	stib_dpi 0xF0, 0x00
	ld (xix), 0x0
	ret

RhythmPatInit_KitIndexTable:
	push_sr
	.byte 0x04
	ei	0x08
	.byte 0x01
	push_sr
	pop_sr
	.byte 0x04
	halt
	ei	0x07
	ldio	1, 2
	pop_sr
	.byte 0x04
	halt
	ei	0x07
	ldio	62, 29
	.byte 0xb0, 0x4e, 0xf6
	pop	xiz
	ret
	pushw	hl
	lds32	xhl, 0
	popw	hl
	ld	xix, 16142024
	and	hl, 3
	sll	hl, 2
	.byte 0xe3, 0x07, 0xf0, 0xec, 0x23
	call	(xhl)
	ret
	muls	xiz, xbc
	.byte 0xf6
	nop
	swi	7
	popw	iz
	.byte 0xf6
	nop
	pop_a
	popw sp
	.byte 0xf6
	nop
	muls	xiz, xwa
	.byte 0xf6
	nop
	ret
	cpdi8	13580, 1
	jr	z, 7
	stdi8	13580, 1
	jr	23
	.byte 0xc1, 0xcd, 0x34, 0x3e, 0x04
	stdi8	13580, 0
	stdi8	32578, 35
	calr	2553
	.byte 0xc1, 0x88, 0x8d, 0x3e, 0x01
	ret
	cpdi8	13580, 1
	jr	z, 9
	cpdi8	13526, 11
	jr	ugt, 0
	jr	5
	stdi8	13580, 0
	ret
	cpdi8	13580, 1
	jr	z, 2
	jr	0
	ret

RhythmFillIn_Wrapper:
	push xiz
	call RhythmFillIn_Select
	pop xiz
	ret

RhythmFillIn_Select:
	anddi8 58338, 247
	ld xwa, 0xF64F4D
	cps hl, 4
	jr c, RhythmFillIn_LookupAndApply
	sub hl, 0x4

RhythmFillIn_LookupAndApply:
	ld_srib3 A, 0x07, 0xE0, 0xEC
	stda8 14235, a
	calr DrumKit_UpdateStatusFlags
	call AudioInit_SelectAndDispatch
	call AudioMode_ResetVoiceState
	ret

RhythmFillIn_PatternTable:
	rcf
	.byte 0x04
	push_sr
	.byte 0x01
	ldio	16, 16
	rcf
	push	xiz
	call	16142172
	pop	xiz
	ret
	.byte 0xc1, 0xa7, 0x28, 0x3c, 0xfb, 0xc1, 0xe2, 0xe3, 0x3c, 0xfe
	cpdi8	36151, 181
	jr	z, 31
	.byte 0xc1, 0x88, 0x8d, 0x3e, 0x01, 0xf1, 0x83, 0x32, 0xc8
	jr	nz, 20
	.byte 0xc1, 0xcd, 0x34, 0x3e, 0x80
	call	16069345
	cpdi8	36151, 178
	jr	nz, 4
	call	16095947
	ret

RhythmMute_Wrapper:
	push xiz
	call RhythmMute_Toggle
	pop xiz
	ret

RhythmMute_Toggle:
	calr RhythmMute_StateMachine
	ret

RhythmMute_StateMachine:
	ordi8 58338, 8
	incdi8 1, 13531
	cpdi8 13531, 4
	jr nz, RhythmMute_State1
	stdi8 13531, 0
	jr RhythmMute_StateDone

RhythmMute_State1:
	cpdi8 13531, 1
	jr nz, RhythmMute_State8
	stdi8 13531, 4
	jr RhythmMute_StateDone

RhythmMute_State8:
	cpdi8 13531, 8
	jr nz, RhythmMute_StateDone
	stdi8 13531, 1

RhythmMute_StateDone:
	ret

RhythmMute_InlineCode:
	.byte 0xc1, 0xe2, 0xe3, 0x3e, 0x08
	bit	7, w
	jr	nz, 41
	cpdi8	13531, 0
	jr	nz, 7
	stdi8	13531, 4
	jr	25
	cpdi8	13531, 3
	jr	nz, 7
	stdi8	13531, 0
	jr	11
	cpdi8	13531, 7
	jr	z, 4
	incdi8	1, 13531
	jr	39
	cpdi8	13531, 0
	jr	nz, 7
	stdi8	13531, 3
	jr	25
	cpdi8	13531, 4
	jr	nz, 7
	stdi8	13531, 0
	jr	11
	cpdi8	13531, 1
	jr	z, 4
	.byte 0xc1, 0xdb
	ldw	ix, 0x0e69

RhythmSolo_Wrapper:
	push xiz
	calr RhythmSolo_Toggle
	pop xiz
	ret

RhythmSolo_Toggle:
	bitda 7, 13553
	jr nz, RhythmSolo_Disable
	stdi8 13553, 128
	jr RhythmSolo_UpdateStatus

RhythmSolo_Disable:
	stdi8 13553, 0

RhythmSolo_UpdateStatus:
	calr DrumKit_UpdateStatusFlags
	bitda 0, 12931
	jr nz, RhythmSolo_Return
	ordi8 13517, 128

RhythmSolo_Return:
	ret

RhythmVariation_Wrapper:
	push xiz
	calr RhythmVariation_Select
	pop xiz
	ret

RhythmVariation_Select:
	ldda8 a, 13519
	and a, 0xC
	cps a, 0
	jr nz, RhythmVariation_Return
	ldda8 a, 13820
	and a, 0xC
	cps a, 0
	jr nz, RhythmVariation_Return
	and hl, 0xF
	ld xwa, 0xF64F4D
	ld_srib3 A, 0x07, 0xE0, 0xEC
	stda8 14235, a
	calr DrumKit_UpdateStatusFlags
	bitda 0, 12931
	jr nz, RhythmVariation_PostDispatch
	ordi8 13517, 128

RhythmVariation_PostDispatch:
	call AudioInit_SelectAndDispatch
	call AudioMode_ResetVoiceState

RhythmVariation_Return:
	ret

RhythmVariation_InlineCode:
	calr	-1074
	ret
	push	xiz
	calr	2
	pop	xiz
	ret
	cpdi8	36151, 182
	jr	z, 10
	stdi8	14098, 4
	.byte 0xc1, 0x88, 0x8d, 0x3e, 0x01, 0xc1, 0xe2, 0xe3, 0x3c, 0xfe, 0xc1, 0xcd, 0x34, 0x3e, 0x08
	ret
	push	xiz
	calr	2
	pop	xiz
	ret
	.byte 0xc1, 0xcd, 0x34, 0x3c, 0xf7
	ret
	push	xiz
	calr	2
	pop	xiz
	ret
	lds32	xhl, 0
	ldda8	l, 14235
	and	l, 31
	add	xhl, 16142570
	ld	a, (xhl)
	stda8	14235, a
	call	16637679
	call	16637863
	calr	-1159
	ret
	nop
	ldio	1, 0
	.byte 0x02
	nop
	nop
	nop
	ldio	0, 0
	nop
	nop
	nop
	nop
	nop
	.byte 0x04
	nop
	nop
	nop
	nop
	nop
	nop
	.zero 8
	nop
	push	xiz
	calr	2
	pop	xiz
	ret
	lds32	xhl, 0
	ldda8	l, 14235
	and	l, 31
	add	xhl, 16142641
	ld	a, (xhl)
	stda8	14235, a
	call	16637679
	call	16637863
	calr	-1230
	ret
	nop
	push_sr
	.byte 0x04
	nop
	rcf
	nop
	nop
	nop
	.byte 0x01
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	rcf
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	.zero 8
	ret
	push	xiz
	calr	2
	pop	xiz
	ret
	cpdi8	14098, 4
	jr	z, 2
	jr	41
	bit	7, w
	jr	nz, 18
	incdi8	1, 14100
	cpdi8	14100, 13
	jr	ule, 23
	stdi8	14100, 13
	jr	16
	decdi8	1, 14100
	cpdi8	14100, 1
	jr	ge, 5
	stdi8	14100, 1
	jr	0
	ret
	push	xiz
	calr	2
	pop	xiz
	ret
	cpdi8	14098, 4
	jr	nz, 41
	bit	7, w
	jr	nz, 18
	incdi8	1, 14101
	cpdi8	14101, 13
	jr	ule, 23
	stdi8	14101, 13
	jr	16
	decdi8	1, 14101
	cpdi8	14101, 255
	jr	nz, 5
	stdi8	14101, 0
	jr	0
	ret
	push	xiz
	calr	2
	pop	xiz
	ret
	cpdi8	14098, 4
	jr	z, 2
	jr	41
	bit	7, w
	jr	nz, 18
	incdi8	1, 14102
	cpdi8	14102, 3
	jr	ule, 23
	stdi8	14102, 3
	jr	16
	decdi8	1, 14102
	cpdi8	14102, 255
	jr	nz, 5
	stdi8	14102, 0
	jr	17
	bit	7, w
	jr	nz, 7
	.byte 0xc1, 0x2d, 0x37, 0x3e, 0x10
	jr	5
	.byte 0xc1, 0x2d, 0x37, 0x3e, 0x20
	ret
	push	xiz
	call	16142867
	pop	xiz
	ret
	cpdi8	36151, 180
	jr	z, 27
	stdi8	13632, 1
	call	16117130
	ld	l, (xiy+16)
	and	l, 255
	ld	h, (xiy+17)
	and	h, 127
	calr	1955
	calr	-1553
	calr	1435
	ret

RhythmConfig_ReturnStub:
	ret

RhythmConfig_InlineCode2:
	push	xiz
	call	16142913
	pop	xiz
	ret
	cpdi8	36150, 180
	jr	z, 3
	calr	-1885
	ret

DrumTempo_Adjust:
	push xiz
	push xix
	ldda8 a, 13632
	bit 7, w
	jr nz, DrumTempo_Decrement
	ldb l, 0x6
	ld xix, 0x94800
	add xix, 0x10
	bitm 0, (xix)
	jr nz, DrumTempo_CheckMax
	cpdi8 13526, 11
	jr ugt, DrumTempo_CheckMax
	ldb l, 0x8

DrumTempo_CheckMax:
	cp a, l
	jr z, DrumTempo_Done
	inc 1, a
	jr DrumTempo_Store

DrumTempo_Decrement:
	cps a, 1
	jr z, DrumTempo_Done
	dec 1, a

DrumTempo_Store:
	stda8 13632, a

DrumTempo_Done:
	pop xix
	pop xiz
	ret

DrumVoice_Select:
	push xiz
	xor hl, hl
	ldda8 l, 13632
	cps l, 1
	jr nc, DrumVoice_ClampMin
	ldb l, 0x1

DrumVoice_ClampMin:
	dec 1, l
	calr DrumVoice_Dispatch
	pop xiz
	ret

DrumVoice_InlineStub:
	push	xiz
	call	16143009
	pop	xiz
	ret

DrumVoice_Dispatch:
	ordi8 36232, 1
	pushw hl
	lds32 xhl, 0
	popw hl
	and l, 0xF
	sll xhl, 2
	add xhl, 0xF652BB
	ld xhl, (xhl)
	call (xhl)
	ret


DrumVoice_DispatchTable:
	.long DrumVoice_Handler0
	.long DrumVoice_Handler1
	.long DrumVoice_Handler2
	.long DrumVoice_Handler3
	.long DrumVoice_Handler4
	.long DrumVoice_Handler5
	.long DrumVoice_Handler6
	.long DrumVoice_Handler7
	.long DrumVoice_NullHandler
	.long DrumVoice_NullHandler
	.long DrumVoice_NullHandler
	.long DrumVoice_NullHandler
	.long DrumVoice_NullHandler
	.long DrumVoice_NullHandler
	.long DrumVoice_NullHandler
DrumVoice_NullHandler:
	.byte 0x0e
DrumVoice_Handler0:
	.byte 0xf1, 0xce, 0x34, 0xcf
	jr	z, 46
	bit	7, w
	jr	nz, 18
	incdi8	1, 13527
	cpdi8	13527, 7
	jr	ule, 23
	stdi8	13527, 7
	jr	16
	decdi8	1, 13527
	cpdi8	13527, 0
	jr	ge, 5
	stdi8	13527, 0
	.byte 0xc1, 0xce, 0x34, 0x3e, 0x01
	jr	8
	stdi8	32578, 19
	calr	1470
	ret
DrumVoice_Handler1:
	.byte 0xf1, 0xce, 0x34, 0xcf
	jr	z, 46
	bit	7, w
	jr	nz, 18
	incdi8	1, 13528
	cpdi8	13528, 11
	jr	ule, 23
	stdi8	13528, 11
	jr	16
	decdi8	1, 13528
	cpdi8	13528, 4
	jr	ge, 5
	stdi8	13528, 4
	.byte 0xc1, 0xce, 0x34, 0x3e, 0x02
	jr	8
	stdi8	32578, 19
	calr	1409
	ret
DrumVoice_Handler2:
	.byte 0xc1, 0xe2, 0xe3, 0x3e, 0x08
	bit	7, w
	jr	nz, 18
	incdi8	1, 13545
	cpdi8	13545, 11
	jr	ule, 23
	stdi8	13545, 11
	jr	16
	decdi8	1, 13545
	cpdi8	13545, 0
	jr	ge, 5
	stdi8	13545, 0
	.byte 0xc1, 0xd2, 0x34, 0x3e, 0x01
	ret
DrumVoice_Handler3:
	.byte 0xc1, 0xe2, 0xe3, 0x3e, 0x08
	bit	7, w
	jr	nz, 7
	.byte 0xc1, 0xea, 0x34, 0x3e, 0x10
	jr	5
	.byte 0xc1, 0xea, 0x34, 0x3c, 0xef, 0xc1, 0xd2, 0x34, 0x3e, 0x02
	ret
DrumVoice_Handler5:
	.byte 0xc1, 0xe2, 0xe3, 0x3c, 0xf7
	bit	7, w
	jr	nz, 18
	.byte 0xf1, 0xea, 0x34, 0xcd
	jr	nz, 28
	.byte 0xc1, 0xea, 0x34, 0x3e, 0x20, 0xc1, 0xd2, 0x34, 0x3e, 0x04
	jr	16
	.byte 0xf1, 0xea, 0x34, 0xcd
	jr	z, 10
	.byte 0xc1, 0xea, 0x34, 0x3c, 0xdf, 0xc1, 0xd2, 0x34, 0x3e, 0x04
	ret
DrumVoice_Handler4:
	.byte 0xc1, 0xe2, 0xe3, 0x3c, 0xf7
	bit	7, w
	jr	nz, 18
	.byte 0xf1, 0xea, 0x34, 0xce
	jr	nz, 28
	.byte 0xc1, 0xea, 0x34, 0x3e, 0x40, 0xc1, 0xd2, 0x34, 0x3e, 0x04
	jr	16
	.byte 0xf1, 0xea, 0x34, 0xce
	jr	z, 10
	.byte 0xc1, 0xea, 0x34, 0x3c, 0xbf, 0xc1, 0xd2, 0x34, 0x3e, 0x04
	ret
	.byte 0xc1, 0xe2, 0xe3, 0x3e, 0x08
	ldda8	a, 13546
	and	a, 96
	bit	7, w
	jr	nz, 35
	cps	a, 0
	jr	nz, 4
	ldb	a, 64
	jr	25
	cp	a, 64
	jr	nz, 4
	ldb	a, 32
	jr	16
	cp	a, 32
	jr	nz, 4
	ldb	a, 96
	jr	7
	cp	a, 96
	jr	nz, 2
	ldb	a, 96
	jr	33
	cps	a, 0
	jr	nz, 4
	ldb	a, 0
	jr	25
	cp	a, 64
	jr	nz, 4
	ldb	a, 0
	jr	16
	cp	a, 32
	jr	nz, 4
	ldb	a, 64
	jr	7
	cp	a, 96
	jr	nz, 2
	ldb	a, 32
	.byte 0xc1, 0xea, 0x34, 0x3c, 0x9f, 0xc1, 0xea, 0x34, 0xe9, 0xc1, 0xd2, 0x34, 0x3e, 0x04
	ret
DrumVoice_Handler6:
	.byte 0xc1, 0xe2, 0xe3, 0x3e, 0x08, 0xc1, 0xe2, 0xe3, 0x3e, 0x01
	stdi16	58340, 1927
	stdi16	58340, 1670
	ld	xiy, 608256
	add	xiy, 16
	ld	a, (xiy)
	bit	0, a
	jr	nz, 9
	calr	722
	calr	-2184
	calr	804
	ret
DrumVoice_Handler7:
	.byte 0xc1, 0xe2, 0xe3, 0x3e, 0x08, 0xc1, 0xe2, 0xe3, 0x3e, 0x01
	stdi16	58340, 1927
	ld	xiy, 608256
	add	xiy, 16
	ld	a, (xiy)
	bit	0, a
	jr	nz, 9
	calr	839
	calr	-2228
	calr	760
	ret
	push	xiz
	.byte 0xf1, 0xd3, 0x34, 0xc8
	jr	nz, 10
	cpdi8	13526, 12
	jr	nc, 3
	calr	2
	pop	xiz
	ret
	.byte 0xc1, 0x88, 0x8d, 0x3e, 0x01, 0xc1, 0xe2, 0xe3, 0x3c, 0xf7
	ld	xiy, 608256
	add	xiy, 16
	ld	a, (xiy)
	bit	0, a
	jr	nz, 10
	cpdi8	13526, 12
	jr	nc, 3
	calr	880
	ret
	ret
	ret
	ret
	ret
	ret
	ret
	ret
	ret
	ret
	.byte 0xc1, 0xe2, 0xe3, 0x3c, 0xfe
	ret
	push	xiz
	call	16143660
	pop	xiz
	ret
	cpdi8	36151, 184
	jr	z, 22
	calr	1565
	ldda8	l, 13549
	ldda8	h, 13550
	calr	1168
	calr	-2336
	.byte 0xc1, 0xcd, 0x34, 0x3c, 0xbf
	calr	1520
	calr	4
	calr	1537
	ret
	ldda8	a, 64602
	and	a, 255
	cp	a, 128
	jr	c, 50
	cp	a, 128
	jr	z, 45
	cp	a, 132
	jr	z, 40
	cp	a, 136
	jr	z, 35
	and	a, 127
	ld	xix, 16143762
	.byte 0xc3, 0x03, 0xf0, 0xe0, 0x21
	stda8	64602, a
	stda8	13549, a
	and	a, 127
	stda8	65441, a
	stda8	65471, a
	calr	-2413
	ret
	add	w, (xwa)
	add	w, (xwa)
	add	d, (xix)
	add	d, (xix)
	add	(xwa-120), w
	.byte 0x88, 0x3e, 0x1d, 0xa5, 0x55, 0xf6
	pop	xiz
	ret
	cpdi8	36150, 184
	jr	z, 3
	calr	-2753
	ret
	push	xiz
	call	16143799
	pop	xiz
	ret
	ldda8	a, 14759
	bit	7, w
	jr	z, 8
	cps	a, 2
	jr	z, 14
	inc	1, a
	jr	6
	cps	a, 0
	jr	z, 6
	dec	1, a
	stda8	14759, a
	ret
	push	xiz
	call	16143834
	pop	xiz
	ret
	ldda8	a, 14759
	sll	a, 1
	ld	xix, 16143856
	.byte 0xd3, 0x03, 0xf0, 0xe0, 0x23
	call	16143937
	ret
	nop
	nop
	.byte 0x01
	nop
	.byte 0x02
	nop
	push	xiz
	call	16143869
	pop	xiz
	ret
	ldda8	a, 14760
	bit	7, w
	jr	z, 8
	cps	a, 1
	jr	z, 14
	inc	1, a
	jr	6
	cps	a, 0
	jr	z, 6
	dec	1, a
	stda8	14760, a
	ret
	push	xiz
	call	16143904
	pop	xiz
	ret
	ldda8	a, 14760
	sll	a, 1
	ld	xix, 16143926
	.byte 0xd3, 0x03, 0xf0, 0xe0, 0x23
	call	16143937
	ret
	.byte 0x03
	nop
	.byte 0x04
	nop
	push	xiz
	call	16143937
	pop	xiz
	ret
	pushw	hl
	lds32	xhl, 0
	popw	hl
	and	hl, 7
	sll	hl, 2
	add	xhl, 16143959
	ld	xhl, (xhl)
	call	(xhl)
	ret
	jrl	ule, -2474
	nop
	.byte 0x90, 0x56, 0xf6
	nop
	cp	xiz, (xde+86)
	nop
	.byte 0xbe, 0x56, 0xf6
	nop
	div8rr	h, e
	.byte 0xf6
	nop
	ldx
	.byte 0x52, 0xf6
	nop
	ldx
	.byte 0x52, 0xf6
	nop
	.byte 0xc1, 0xe2, 0xe3, 0x3e, 0x08, 0xc1, 0xe2, 0xe3, 0x3e, 0x01
	stdi16	58340, 128
	calr	889
	calr	-2661
	calr	1200
	calr	1384
	ret
	.byte 0xc1, 0xe2, 0xe3, 0x3e, 0x08, 0xc1, 0xe2, 0xe3, 0x3e, 0x01
	stdi16	58340, 385
	calr	1010
	calr	-2690
	calr	1171
	ret
	.byte 0xc1, 0xe2, 0xe3, 0x3e, 0x08, 0xc1, 0xe2, 0xe3, 0x3e, 0x01
	stdi16	58340, 642
	calr	1359
	ret
	.byte 0xc1, 0xe2, 0xe3, 0x3e, 0x01
	stdi16	58340, 34053
	calr	1573
	ret
	.byte 0xc1, 0xe2, 0xe3, 0x3e, 0x08, 0xc1, 0xe2, 0xe3, 0x3e, 0x01
	stdi16	58340, 1670
	calr	1668
	ret
	push	xiz
	call	16144104
	pop	xiz
	ret
	cpdi8	36151, 189
	jr	z, 33
	.byte 0xc1, 0xcd, 0x34, 0x3c, 0xbf
	ld	xix, 608256
	add	xix, 16
	ld	a, (xix)
	.byte 0xc1, 0xd3, 0x34, 0x3c, 0xfe
	bit	0, a
	jr	z, 5
	.byte 0xc1, 0xd3, 0x34, 0x3e, 0x01, 0xc1, 0xe2, 0xe3, 0x3c, 0xde
	ret
	ret
	ret
	push	xiz
	call	16144159
	pop	xiz
	ret
	cpdi8	36151, 187
	jr	z, 5
	.byte 0xc1, 0xcd, 0x34, 0x3c, 0xbf
	cpdi8	36153, 187
	jr	z, 0
	.byte 0xc1, 0xe2, 0xe3, 0x3c, 0xfe
	ret
	.byte 0xc1, 0xe2, 0xe3, 0x3e, 0x08
	ldda8	a, 64954
	and	a, 15
	ld	w, a
	cps	hl, 0
	jr	nz, 11
	inc	1, a
	cp	a, 13
	jr	c, 13
	ldb	a, 12
	jr	9
	dec	1, a
	cp	a, 255
	jr	nz, 2
	ldb	a, 0
	stda8	64954, a
	cp	a, w
	jr	z, 10
	ldb	w, 15
	ldb	e, 145
	ldb	d, 4
	call	16626673
	ret
	ret
	stdi8	13526, 0
	calr	-3212
	ret
	push w
	ldda8	l, 64602
	and	l, 255
	ldda8	h, 64603
	and	h, 127
	ldb	a, 72
	stda8	37111, a
	call	16556463
	pop w
	bit	7, w
	jr	nz, 11
	inc	1, l
	cp	l, 14
	jr	c, 13
	ldb	l, 13
	jr	9
	dec	1, l
	cp	l, 255
	jr	nz, 2
	ldb	l, 0
	ld	xix, 65426
	.byte 0xc3, 0x03, 0xf0, 0xec, 0x26
	ldb	a, 72
	stda8	37110, a
	call	16556428
	and	l, 255
	stda8	64602, l
	and	h, 127
	stda8	64603, h
	ret
	ldda8	l, 64602
	and	l, 255
	ldda8	h, 64603
	and	h, 127
	sll	l, 1
	sll	hl, 1
	ld	xiy, 14963010
	.byte 0xd3, 0x07, 0xf4, 0xec, 0x20
	add	hl, 2
	lds32	xde, 0
	.byte 0xd3, 0x07, 0xf4, 0xec, 0x22
	ld	w, a
	and	xwa, 65280
	sll	xwa, 8
	ld	xix, 4194304
	add	xix, xwa
	add	xix, xde
	jr	0
	ld	a, (xix+976)
	stda8	13552, a
	ret
	push w
	ldda8	l, 64602
	and	l, 255
	ldda8	h, 64603
	and	h, 127
	ldb	a, 72
	stda8	37111, a
	call	16556463
	ld	a, h
	pushw	hl
	call	16105613
	stda8	13357, l
	popw	hl
	pop w
	bit	7, w
	jr	nz, 14
	inc	1, a
	cpda8	a, 13357
	jr	ule, 15
	ldda8	a, 13357
	jr	9
	dec	1, a
	cp	a, 255
	jr	nz, 2
	ldb	a, 0
	ld	h, a
	ld	xwa, 65426
	.byte 0xf3, 0x03, 0xe0, 0xec, 0x46
	ldb	a, 72
	stda8	37110, a
	call	16556428
	and	l, 255
	stda8	64602, l
	and	h, 127
	stda8	64603, h
	ret
	ldda8	l, 13552
	and	l, 31
	xor	h, h
	sll	hl, 3
	ld	xbc, 16144649
	add	xbc, 7
	.byte 0xc3, 0x07, 0xe4, 0xec, 0x20
	ldda8	l, 13528
	and	l, 31
	xor	h, h
	sll	hl, 3
	ld	xbc, 16144649
	add	xbc, 7
	.byte 0xc3, 0x07, 0xe4, 0xec, 0x21
	cp	a, w
	jr	nz, 34
	call	16117130
	ldda8	a, 64602
	and	a, 255
	ld	(xiy+16), a
	ldda8	a, 64603
	and	a, 127
	ld	(xiy+17), a
	stdi8	32578, 21
	calr	17
	jr	14
	stdi8	32578, 22
	calr	7
	ldb	a, 8
	call	16694689
	ret

DrumVoice_NotifyEE:
	push xwa
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	xor wa, wa
	ldb a, 0xEE
	call SoundCtrl_SendCommand
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	pop xwa
	ret

TimeSig_DisplayStrings:	.ascii "(1/2)+0  "
	.byte 0x02
	.ascii "(2/2)+0  "
	.byte 0x04
	.ascii "(3/2)+0  "
	.byte 0x06, 0x28, 0x34
	.ascii "/2)+0  "
	.byte 0x08
	.ascii "(1/4)+0  "
	.byte 0x01
	.ascii "(2/4)+0  "
	.byte 0x02
	.ascii "(3/4)+0  "
	.byte 0x03, 0x28, 0x34
	.ascii "/4)+0  "
	.byte 0x04
	.ascii "(5/4)+0  "
	.byte 0x05
	.ascii "(6/4)+0  "
	.byte 0x06
	.ascii "(7/4)+0  "
	.byte 0x07, 0x28, 0x38
	.ascii "/4)+0  "
	.byte 0x08
	.ascii "(2/8)+0  "
	.byte 0x01
	.ascii "(4/8)+0  "
	.byte 0x02
	.ascii "(6/8)+0  "
	.byte 0x03, 0x28, 0x38
	.ascii "/8)+0  "
	.byte 0x04
	.ascii "(10/8)+0 "
	.byte 0x05
	.ascii "(12/8)+0 "
	.byte 0x06
	.ascii "(14/8)+0 "
	.byte 0x07, 0x28, 0x31
	.ascii "6/8)+0 "
	.byte 0x08
	.byte 0x1d, 0xe5, 0x32, 0xf5, 0xf1, 0x5a, 0xfc, 0x47
	.byte 0xce, 0xcc, 0x7f, 0xc1, 0x5b, 0xfc, 0x3c, 0x80
	.byte 0xc1, 0x5b, 0xfc, 0xee, 0xf1, 0xf7, 0x90, 0x00
	.byte 0x48, 0x1d, 0xaf, 0xa1, 0xfc, 0xce, 0x88, 0xdb
	.byte 0x12, 0xeb, 0x12, 0xeb, 0xc8, 0x92, 0xff, 0x00
	.byte 0x00, 0x68, 0x00, 0xb3, 0x40, 0x0e, 0xc8, 0x04
	.byte 0xc1, 0x5a, 0xfc, 0x27, 0xcf, 0xcc, 0xff, 0xc1
	.byte 0x5b, 0xfc, 0x26, 0xce, 0xcc, 0x7f, 0x21, 0x48
	.byte 0xf1, 0xf7, 0x90, 0x41, 0x1d, 0xaf, 0xa1, 0xfc
	.byte 0xc8, 0x05, 0xc8, 0x33, 0x07, 0x6e, 0x14, 0xcf
	.byte 0x61, 0xcf, 0xcf, 0x0e, 0x6e, 0x04, 0x27, 0x0f
	.byte 0x68, 0x1b, 0xcf, 0xcf, 0x10, 0x67, 0x16, 0x27
	.byte 0x0f, 0x68, 0x12, 0xcf, 0x69, 0xcf, 0xcf, 0x0e
	.byte 0x6e, 0x04, 0x27, 0x0d, 0x68, 0x07, 0xcf, 0xcf
	.byte 0xff, 0x6e, 0x02, 0x27, 0x00, 0xcf, 0x89, 0x44
	.byte 0x92, 0xff, 0x00, 0x00, 0xc3, 0x03, 0xf0, 0xec
	.byte 0x26, 0xc9, 0x8f, 0x21, 0x48, 0xf1, 0xf6, 0x90
	.byte 0x41, 0x1d, 0x8c, 0xa1, 0xfc, 0xcf, 0xcc, 0xff
	.byte 0xf1, 0x5a, 0xfc, 0x47, 0xce, 0xcc, 0x7f, 0xf1
	.byte 0x5b, 0xfc, 0x46, 0xc1, 0xef, 0x34, 0x3f, 0x1a
	.byte 0x66, 0x21, 0xc1, 0x5a, 0xfc, 0x3f, 0x80, 0x67
	.byte 0x0e, 0xc1, 0xef, 0x34, 0x3f, 0x10, 0x6f, 0x13
	.byte 0xf1, 0xef, 0x34, 0x00, 0x10, 0x68, 0x0c, 0xc1
	.byte 0xef, 0x34, 0x3f, 0x10, 0x67, 0x05, 0xf1, 0xef
	.byte 0x34, 0x00, 0x00, 0x0e, 0xc8, 0x04, 0xc1, 0x5a
	.byte 0xfc, 0x27, 0xcf, 0xcc, 0xff, 0xc1, 0x5b, 0xfc
	.byte 0x26, 0xce, 0xcc, 0x7f, 0x21, 0x48, 0xf1, 0xf7
	.byte 0x90, 0x41, 0x1d, 0xaf, 0xa1, 0xfc, 0xce, 0x89
	.byte 0x2b, 0x1d, 0x8d, 0xc0, 0xf5, 0xf1, 0x2d, 0x34
	.byte 0x47, 0x4b, 0xc8, 0x05, 0xc8, 0x33, 0x07, 0x6e
	.byte 0x21, 0xcf, 0xcf, 0x0f, 0x6e, 0x0e, 0x3c, 0x44
	.byte 0x24, 0x5b, 0xf6, 0x00, 0xc3, 0x03, 0xf0, 0xe0
	.ascii "!\\h*ÉaÁ-"
	.byte 0x34, 0xf1, 0x63, 0x22, 0xc1, 0x2d, 0x34, 0x21
	.byte 0x68, 0x1c, 0xcf, 0xcf, 0x0f, 0x6e, 0x0e, 0x3c
	.byte 0x44, 0x30, 0x5b, 0xf6, 0x00, 0xc3, 0x03, 0xf0
	.byte 0xe0, 0x21, 0x5c, 0x68, 0x09, 0xc9, 0x69, 0xc9
	.byte 0xcf, 0xff, 0x6e, 0x02, 0x21, 0x00, 0xc9, 0x8e
	.byte 0x40, 0x92, 0xff, 0x00, 0x00, 0xf3, 0x03, 0xe0
	.byte 0xec, 0x46, 0x21, 0x48, 0xf1, 0xf6, 0x90, 0x41
	.byte 0x1d, 0x8c, 0xa1, 0xfc, 0xcf, 0xcc, 0xff, 0xf1
	.byte 0x5a, 0xfc, 0x47, 0xce, 0xcc, 0x7f, 0xf1, 0x5b
	.byte 0xfc, 0x46, 0x0e, 0x04, 0x04, 0x04, 0x04, 0x08
	.byte 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04
	.byte 0x04, 0x04, 0x04, 0xc1, 0x5a, 0xfc, 0x21, 0xc9
	.byte 0xcc, 0xff, 0xc1, 0x5b, 0xfc, 0x20, 0xc8, 0xcc
	.byte 0x7f, 0xf1, 0xed, 0x34, 0x41, 0xf1, 0xee, 0x34
	.byte 0x40, 0x0e, 0xc1, 0xed, 0x34, 0x27, 0xcf, 0xcc
	.byte 0xff, 0xcf, 0xcf, 0xf0, 0x67, 0x0b, 0x27, 0x80
	.byte 0xf1, 0xed, 0x34, 0x47, 0xf1, 0xee, 0x34, 0x00
	.byte 0x00, 0xcf, 0xcf, 0x80, 0x67, 0x10, 0xc1, 0xee
	.byte 0x34, 0x21, 0xc9, 0xcc, 0x7f, 0xc9, 0xd8, 0x66
	.byte 0x05, 0xf1, 0xee, 0x34, 0x00, 0x00, 0xcf, 0xcf
	.byte 0x80, 0x67, 0x64, 0xc1, 0xef, 0x34, 0x3f, 0x10
	.byte 0x6f, 0x05, 0xf1, 0xef, 0x34, 0x00, 0x1a, 0xc1
	.byte 0xef, 0x34, 0x3f, 0x1a, 0x6e, 0x25, 0xc1, 0xcd
	.byte 0x34, 0x21, 0xc9, 0xcc, 0x30, 0xc9, 0xd8, 0x66
	.byte 0x0c, 0xc9, 0xcf, 0x20, 0x66, 0x0e, 0xf1, 0xd6
	.byte 0x34, 0x00, 0x20, 0x68, 0x48, 0xf1, 0xd6, 0x34
	.byte 0x00, 0x1e, 0x68, 0x41, 0xf1, 0xd6, 0x34, 0x00
	.byte 0x1f, 0x68, 0x3a, 0xc1, 0xd6, 0x34, 0x3f, 0x1e
	.byte 0x67, 0x33, 0xc1, 0xcd, 0x34, 0x21, 0xc9, 0xcc
	.byte 0x30, 0xc9, 0xd8, 0x66, 0x13, 0xc9, 0xcf, 0x20
	.byte 0x66, 0x07, 0xf1, 0xd6, 0x34, 0x00, 0x08, 0x68
	.byte 0x1c, 0xf1, 0xd6, 0x34, 0x00, 0x04, 0x68, 0x15
	.byte 0xf1, 0xd6, 0x34, 0x00, 0x00, 0x68, 0x0e, 0xc1
	.byte 0xef, 0x34, 0x3f, 0x10, 0x67, 0x05, 0xf1, 0xef
	.byte 0x34, 0x00, 0x1a, 0x68, 0x9a, 0x0e, 0x0e, 0xc1
	.byte 0xed, 0x34, 0x3f, 0x80, 0x67, 0x0c, 0xc1, 0xef
	.byte 0x34, 0x3f, 0x0a, 0x67, 0x05, 0xf1, 0xef, 0x34
	.byte 0x00, 0x00, 0x0e, 0xc8, 0x04, 0xc1, 0x5a, 0xfc
	.byte 0x27, 0xcf, 0xcc, 0xff, 0xc1, 0x5b, 0xfc, 0x26
	.byte 0xce, 0xcc, 0x7f, 0x21, 0x48, 0xf1, 0xf7, 0x90
	.byte 0x41, 0x1d, 0xaf, 0xa1, 0xfc, 0x2b, 0x1d, 0x8d
	.byte 0xc0, 0xf5, 0xf1
	.byte 0x2d, 0x34, 0x46, 0x4b
	.byte 0xcf
	.byte 0x89, 0xc9, 0xcf, 0x0f, 0x61, 0x0c, 0xf1, 0x2e
	.byte 0x34, 0x00, 0x19, 0xf1, 0x2f, 0x34, 0x00, 0x10
	.byte 0x68, 0x0a, 0xf1, 0x2e, 0x34, 0x00, 0x0f, 0xf1
	.byte 0x2f, 0x34, 0x00, 0x00, 0xc1, 0xef, 0x34, 0x21
	.byte 0xc8, 0x05, 0xc8, 0x33, 0x07, 0x6e, 0x2d, 0xc9
	.byte 0xcf, 0x1a, 0x6e, 0x1a, 0x3c, 0xc1, 0xd6, 0x34
	.byte 0x21, 0x44, 0xd0, 0x5c, 0xf6, 0x00, 0xc3, 0x03
	.byte 0xf0, 0xe0, 0x21, 0xf1, 0xd6, 0x34, 0x41, 0x5c
	.byte 0xc1
	.ascii "/4!h3"
	inc	1, a
	.byte 0xc1, 0x2e, 0x34, 0xf1, 0x63, 0x2b, 0xc1, 0x2e
	.ascii "4!h%"
	.byte 0xc9, 0xcf, 0x1a, 0x66
	.byte 0x20, 0xc9, 0x69, 0xc1, 0x2f, 0x34, 0xf1, 0x69
	.byte 0x18, 0x3c, 0xc1, 0xd6, 0x34, 0x21, 0x44, 0xaf
	.byte 0x5c, 0xf6, 0x00, 0xc3, 0x03, 0xf0, 0xe0, 0x21
	.byte 0xf1, 0xd6
	.byte 0x34, 0x41, 0x5c, 0x21
	.byte 0x1a, 0x68
	.byte 0x00, 0xf1, 0xef, 0x34, 0x41, 0x0e, 0x1e, 0x1e
	.byte 0x1e, 0x1e, 0x1f, 0x1f, 0x1f, 0x1f, 0x20, 0x20
	.byte 0x20, 0x20, 0x1e, 0x1e, 0x1e, 0x1e, 0x1e, 0x1e
	.byte 0x1f, 0x1f, 0x1f, 0x1f, 0x1f, 0x1f, 0x20, 0x20
	.ascii "    "
	.byte 0x1e, 0x1f, 0x20, 0x00
	.byte 0x00, 0x00, 0x00, 0x04, 0x04, 0x04, 0x04, 0x08
	.byte 0x08, 0x08, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x08
	.byte 0x08, 0x08, 0x08, 0x08, 0x08, 0x00, 0x04, 0x08
	.byte 0xc8, 0x33, 0x07, 0x6e, 0x3a, 0xf1, 0xcd, 0x34
	.byte 0xcd, 0x66, 0x16, 0xc1, 0xcd, 0x34, 0x3c, 0xcf
	.byte 0xc1, 0xcd, 0x34, 0x3e, 0x10, 0xf1, 0xd6, 0x34
	.byte 0x00, 0x20, 0xf1, 0xef, 0x34, 0x00, 0x1a, 0x68
	.byte 0x51, 0xf1, 0xcd, 0x34, 0xcc, 0x66, 0x02, 0x68
	.byte 0x49, 0xc1, 0xcd, 0x34, 0x3c, 0xcf, 0xc1, 0xcd
	.byte 0x34, 0x3e, 0x20, 0xf1, 0xd6, 0x34, 0x00, 0x1f
	.byte 0xf1, 0xef, 0x34, 0x00, 0x1a, 0x68, 0x33, 0xf1
	.byte 0xcd, 0x34, 0xcd, 0x66, 0x11, 0xc1, 0xcd, 0x34
	.byte 0x3c, 0xcf, 0xf1, 0xd6, 0x34, 0x00, 0x1e, 0xf1
	.byte 0xef, 0x34, 0x00, 0x1a, 0x68, 0x1c, 0xf1, 0xcd
	.byte 0x34, 0xcc, 0x66, 0x16, 0xc1, 0xcd, 0x34, 0x3c
	.byte 0xcf, 0xc1, 0xcd, 0x34, 0x3e, 0x20, 0xf1, 0xd6
	.byte 0x34, 0x00, 0x1f, 0xf1, 0xef, 0x34, 0x00, 0x1a
	.byte 0x68, 0x00, 0x0e, 0xc1, 0xd6, 0x34, 0x21, 0xf1
	.byte 0xcd, 0x34, 0xcc, 0x66, 0x05, 0x1e, 0xcc, 0x00
	.byte 0x68, 0x0e, 0xf1, 0xcd, 0x34, 0xcd, 0x66, 0x05
	.byte 0x1e, 0x73, 0x00, 0x68, 0x03, 0x1e, 0x05, 0x00
	.byte 0xf1, 0xd6, 0x34, 0x41, 0x0e, 0xc8, 0x33, 0x07
	.byte 0x6e, 0x21, 0xc9, 0x61, 0xc9, 0xcf, 0x1f, 0x6e
	.byte 0x07, 0x1e, 0x41, 0x00, 0x21, 0x00, 0x68, 0x11
	.byte 0xc9, 0xdc, 0x6e, 0x04, 0x21, 0x0c, 0x68, 0x09
	.byte 0xc9, 0xcf, 0x12, 0x61, 0x04, 0x21, 0x11, 0x68
	.byte 0x00, 0x68, 0x29, 0xc9, 0x69, 0xc9, 0xcf, 0x1d
	.byte 0x6e, 0x04, 0x21, 0x1e, 0x68, 0x1e, 0xc9, 0xcf
	.byte 0xff, 0x6e, 0x09, 0x21, 0x1e, 0xf1, 0xef, 0x34
	.byte 0x00, 0x1a, 0x68, 0x10, 0xc9, 0xcf, 0x0b, 0x6e
	.byte 0x04, 0x21, 0x03, 0x68, 0x07, 0xc9, 0xcf, 0x12
	.byte 0x61, 0x02, 0x21, 0x11, 0x0e, 0xc1, 0x5a, 0xfc
	.byte 0x21, 0xc9, 0xcc, 0xff, 0xc9, 0xcf, 0x80, 0x67
	.byte 0x07, 0xf1, 0xef, 0x34, 0x00, 0x10, 0x68, 0x05
	.byte 0xf1, 0xef, 0x34, 0x00, 0x00, 0x0e, 0xc8, 0x33
	.byte 0x07, 0x6e, 0x20, 0xc9, 0x61, 0xc9, 0xcf, 0x20
	.byte 0x6e, 0x07, 0x1e, 0xd8, 0xff, 0x21, 0x04, 0x68
	.byte 0x10, 0xc9, 0xcf, 0x08, 0x6e, 0x04, 0x21, 0x12
	.byte 0x68, 0x07, 0xc9, 0xcf, 0x18, 0x61, 0x02, 0x21
	.byte 0x17, 0x68, 0x28, 0xc9, 0x69, 0xc9, 0xcf, 0x1e
	.byte 0x6e, 0x04, 0x21, 0x1f, 0x68, 0x1d, 0xc9, 0xdb
	.byte 0x6e, 0x09, 0x21, 0x1f, 0xf1, 0xef, 0x34, 0x00
	.byte 0x1a, 0x68, 0x10, 0xc9, 0xcf, 0x11, 0x6e, 0x04
	.byte 0x21, 0x07, 0x68, 0x07, 0xc9, 0xcf, 0x18, 0x61
	.byte 0xd8, 0x21, 0x17, 0x0e, 0xc8, 0x33, 0x07, 0x6e
	.byte 0x22, 0xc9, 0x61, 0xc9, 0xcf, 0x21, 0x6e, 0x07
	.byte 0x1e, 0x8a, 0xff, 0x21, 0x08, 0x68, 0x12, 0xc9
	.byte 0xcf, 0x0c, 0x6e, 0x04, 0x21, 0x18, 0x68, 0x09
	.byte 0xc9, 0xcf, 0x1e, 0x61, 0x04, 0x21, 0x1d, 0x68
	.byte 0x00, 0x68, 0x2a, 0xc9, 0x69, 0xc9, 0xcf, 0x1f
	.byte 0x6e, 0x04, 0x21, 0x20, 0x68, 0x1f, 0xc9, 0xdf
	.byte 0x6e, 0x09, 0x21, 0x20, 0xf1, 0xef, 0x34, 0x00
	.byte 0x1a, 0x68, 0x12, 0xc9, 0xcf, 0x17, 0x6e, 0x04
	.byte 0x21, 0x0b, 0x68, 0x09, 0xc9, 0xcf, 0x1e, 0x61
	.byte 0xd8, 0x21, 0x1d, 0x68, 0x00, 0x0e, 0x1d, 0xb9
	.byte 0x9a, 0xf5, 0xc1, 0xa7, 0x28, 0x3e, 0x04, 0xc1
	.byte 0x5a, 0xfc, 0x21, 0xc9, 0xcc, 0x0f, 0xf1, 0x0a
	.byte 0x39, 0x41, 0x1d, 0xd5, 0x5e, 0xf6, 0xf1, 0x1e
	.byte 0x39, 0x65, 0xed, 0xc8, 0x10, 0x00, 0x00, 0x00
	.byte 0xf1, 0x22, 0x39, 0x65, 0xf1, 0x26, 0x39, 0xc8
	.byte 0x6e, 0x12, 0xe9, 0xac, 0xe1, 0x1e, 0x39, 0x25
	.byte 0x44, 0x0e, 0x39, 0x00, 0x00, 0x85, 0x11, 0xf1
	.byte 0x0d, 0x39, 0x00, 0x00, 0xc1, 0x26, 0x39, 0x3c
	.byte 0xfe, 0x0e, 0x0e, 0x0e, 0xe8, 0xa8, 0xe9, 0xa8
	.byte 0x21, 0x20, 0xc1, 0x0a, 0x39, 0x23, 0xcb, 0x41
	.byte 0xe8, 0xc8, 0x00, 0x48, 0x09, 0x00, 0xe8, 0xc8
	.byte 0xa0, 0x0b, 0x00, 0x00, 0xe8, 0x8d, 0x0e, 0xc1
	.byte 0x0c, 0x39, 0x21, 0x45, 0x0e, 0x39, 0x00, 0x00
	.byte 0xc3, 0x03, 0xf4, 0xe0, 0x23, 0xf1, 0x09, 0x39
	.byte 0x43, 0x0e, 0xc1, 0x0b, 0x39, 0x21, 0x45, 0x0e
	.byte 0x39, 0x00, 0x00, 0xc3, 0x03, 0xf4, 0xe0, 0x23
	.byte 0xf1, 0x08, 0x39, 0x43, 0x0e, 0xc1, 0xa7, 0x28
	.byte 0x3c, 0xfb, 0xc1, 0x26, 0x39, 0x3c, 0xfe, 0x0e
	.byte 0xc1, 0x0a, 0x39, 0x21, 0xc8, 0x33, 0x07, 0x6e
	.byte 0x0c, 0xc9, 0xdc, 0x6f, 0x04, 0xc9, 0x61, 0x68
	.byte 0x02, 0x21, 0x04, 0x68, 0x0a, 0xc9, 0xd8, 0x63
	.byte 0x04, 0xc9, 0x69, 0x68, 0x02, 0x21, 0x00, 0xf1
	.byte 0x0a, 0x39, 0x41, 0xc9, 0xce, 0xf0, 0xf1, 0x5a
	.byte 0xfc, 0x41, 0x21, 0x00, 0xf1, 0x5b, 0xfc, 0x41
	.byte 0x1e, 0xd0, 0xec, 0xf1, 0x0d, 0x39, 0x00, 0x00
	.byte 0x0e, 0xc8, 0x04, 0x1e, 0xa4, 0xff, 0xc8, 0x05
	.byte 0xc8, 0x33, 0x07, 0x6e, 0x22, 0xc1, 0x08, 0x39
	.byte 0x3f, 0x0b, 0x6f, 0x06, 0xc1, 0x08, 0x39, 0x61
	.byte 0x68, 0x13, 0xc1, 0x08, 0x39, 0x3f, 0xff, 0x6e
	.byte 0x07, 0xf1, 0x08, 0x39, 0x00, 0x00, 0x68, 0x05
	.byte 0xf1, 0x08, 0x39, 0x00, 0x0b, 0x68, 0x20, 0xc1
	.byte 0x08, 0x39, 0x3f, 0x00, 0x62, 0x06, 0xc1, 0x08
	.byte 0x39, 0x69, 0x68, 0x13, 0xc1, 0x0b, 0x39, 0x3f
	.byte 0x00, 0x6e, 0x07, 0xf1, 0x08, 0x39, 0x00, 0x00
	.byte 0x68, 0x05, 0xf1, 0x08, 0x39, 0x00, 0xff, 0xc1
	.byte 0x08, 0x39, 0x21, 0xf1, 0x09, 0x39, 0x41, 0x44
	.byte 0x0e, 0x39, 0x00, 0x00, 0xc1, 0x0b, 0x39, 0x23
	.byte 0xf3, 0x03, 0xf0, 0xe4, 0x41, 0x44, 0x0e, 0x39
	.byte 0x00, 0x00, 0x1e, 0x06, 0x00, 0xc1, 0x26, 0x39
	.byte 0x3e, 0x01, 0x0e, 0xf1, 0x0d, 0x39, 0x00, 0x00
	.byte 0x26, 0x00, 0x1e, 0x3f, 0x00, 0xd9, 0x88, 0x28
	.byte 0x26, 0x01, 0x1e, 0x37, 0x00, 0x48, 0xd9, 0xcf
	.byte 0xff, 0xff, 0x66, 0x07, 0xd8, 0xf1, 0x66, 0x03
	.byte 0x1e, 0x51, 0x00, 0x28, 0x26, 0x02, 0x1e, 0x23
	.byte 0x00, 0x48, 0xd9, 0xcf, 0xff, 0xff, 0x66, 0x07
	.byte 0xd8, 0xf1, 0x66, 0x03, 0x1e, 0x3d, 0x00, 0x28
	.byte 0x26, 0x03, 0x1e, 0x0f, 0x00, 0x48, 0xd9, 0xcf
	.byte 0xff, 0xff, 0x66, 0x07, 0xd8, 0xf1, 0x66, 0x03
	.byte 0x1e, 0x29, 0x00, 0x0e, 0xc3, 0x03, 0xf0, 0xed
	.byte 0x27, 0xcf, 0xcf, 0xff, 0x66, 0x1a, 0xc1, 0xd6
	.byte 0x34, 0x04, 0xf1, 0xd6, 0x34, 0x47, 0xce, 0x04
	.byte 0x3c, 0x1d, 0xd4, 0xeb, 0xf5, 0x5c, 0xce, 0x05
	.byte 0xf1, 0xd6, 0x34, 0x04, 0xc9, 0x8a, 0x68, 0x03
	.byte 0x31, 0xff, 0xff, 0x0e
	.byte 0x38, 0x40, 0x4e, 0x60
	.byte 0xf6, 0x00, 0xc3, 0x03, 0xe0, 0xed, 0x21, 0xc1
	.byte 0x0d, 0x39, 0xe9, 0x58, 0x0e, 0x01, 0x02, 0x04
	.byte 0x08, 0x08, 0x08, 0x08, 0x08, 0x3e, 0x1d, 0x5d
	.byte 0x60, 0xf6, 0x5e, 0x0e, 0x0e, 0xc1, 0x0a, 0x39
	.byte 0x04, 0xc1, 0x0b, 0x39, 0x04, 0xf1, 0x0a, 0x39
	.byte 0x00, 0x00, 0xc1, 0x0a, 0x39, 0x3f, 0x05, 0x66
	.byte 0x13, 0x1e, 0x60, 0xfe, 0xed, 0x8c, 0x3c, 0x1e
	.byte 0x51, 0xff, 0x5c, 0x1e, 0x14, 0x00, 0xc1, 0x0a
	.byte 0x39, 0x61, 0x68, 0xe6, 0xf1, 0x0b, 0x39, 0x04
	.byte 0xf1, 0x0a, 0x39, 0x04, 0xf1, 0x0d, 0x39, 0x00
	.byte 0x00, 0x0e, 0xf1, 0x0d, 0x39, 0xc9, 0x66, 0x09
	.byte 0x22, 0xff, 0x21, 0x01, 0xf3, 0x03, 0xf0, 0xe0
	.byte 0x42, 0xf1, 0x0d, 0x39, 0xca, 0x66, 0x09, 0x22
	.byte 0xff, 0x21, 0x02, 0xf3, 0x03, 0xf0, 0xe0, 0x42
	.byte 0xf1, 0x0d, 0x39, 0xcb, 0x66, 0x09, 0x22, 0xff
	.byte 0x21, 0x03, 0xf3, 0x03, 0xf0, 0xe0, 0x42, 0x0e
	.byte 0xe9, 0xac, 0xe1, 0x1e, 0x39, 0x24, 0x45, 0x0e
	.byte 0x39, 0x00, 0x00, 0x85, 0x11, 0x0e, 0x3e, 0x1d
	.byte 0xd6, 0x60, 0xf6, 0x5e, 0x0e, 0x1e, 0x0f, 0x00
	.byte 0x1e, 0x86, 0xeb, 0x1d, 0xef, 0xde, 0xfd, 0x1d
	.byte 0xa7, 0xdf, 0xfd, 0x1e, 0x2d, 0xed, 0x0e, 0xf1
	.byte 0x9b, 0x37, 0x00, 0x01, 0xf1, 0xc9, 0x37, 0xcc
	.byte 0x6e, 0x26, 0xf1, 0x9b, 0x37, 0x00, 0x02, 0xf1
	.byte 0xc9, 0x37, 0xcd, 0x6e, 0x1b, 0xf1, 0x9b, 0x37
	.byte 0x00, 0x04, 0xf1, 0xc9, 0x37, 0xce, 0x6e, 0x10
	.byte 0xf1, 0x9b, 0x37, 0x00, 0x08, 0xf1, 0xc9, 0x37
	.byte 0xcb, 0x6e, 0x05, 0xf1, 0x9b, 0x37, 0x00, 0x10
	.byte 0x0e, 0xf1, 0xc9, 0x37, 0x00, 0x10, 0xf1, 0x9b
	.byte 0x37, 0xc8, 0x6e, 0x26, 0xf1, 0xc9, 0x37, 0x00
	.byte 0x20, 0xf1, 0x9b, 0x37, 0xc9, 0x6e, 0x1b, 0xf1
	.byte 0xc9, 0x37, 0x00, 0x40, 0xf1, 0x9b, 0x37, 0xca
	.byte 0x6e, 0x10, 0xf1, 0xc9, 0x37, 0x00, 0x08, 0xf1
	.byte 0x9b, 0x37, 0xcb, 0x6e, 0x05, 0xf1, 0xc9, 0x37
	.byte 0x00, 0x01, 0x0e, 0x3e, 0x1d, 0x53, 0x61, 0xf6
	.byte 0x5e, 0x0e, 0xc1, 0xaa, 0x39, 0x21, 0xc8, 0x33
	.byte 0x07, 0x6e, 0x08, 0xc9, 0xdb, 0x66, 0x0e, 0xc9
	.byte 0x61, 0x68, 0x06, 0xc9, 0xd8, 0x66, 0x06, 0xc9
	.byte 0x69, 0xf1, 0xaa, 0x39, 0x41, 0x0e, 0x3e, 0x1d
	.byte 0x76, 0x61, 0xf6, 0x5e, 0x0e, 0x28, 0x1d, 0x8a
	.byte 0xed, 0xf5, 0x48, 0x44, 0xa9, 0x61, 0xf6, 0x00
	.byte 0xc1, 0xaa, 0x39, 0x21, 0xc3, 0x03, 0xf0, 0xe0
	.byte 0x21, 0xc3, 0x03, 0xf4, 0xe0, 0x27, 0xc8, 0x33
	.byte 0x07, 0x6e, 0x09, 0xcf, 0xcf, 0x7f, 0x66, 0x0f
	.byte 0xcf, 0x61, 0x68, 0x06, 0xcf, 0xd8, 0x66, 0x07
	.byte 0xcf, 0x69, 0xf3, 0x03, 0xf4, 0xe0, 0x47, 0x0e
	.byte 0x22, 0x2a, 0x32, 0x3a, 0x3e
	.byte 0x1d, 0xb4, 0x61
	.byte 0xf6, 0x5e, 0x0e, 0x28, 0x1d, 0x8a, 0xed, 0xf5
	.byte 0x48, 0x44, 0xe7, 0x61, 0xf6, 0x00, 0xc1, 0xaa
	.byte 0x39, 0x21, 0xc3, 0x03, 0xf0, 0xe0, 0x21, 0xc3
	.byte 0x03, 0xf4, 0xe0, 0x27, 0xc8, 0x33, 0x07, 0x6e
	.byte 0x09, 0xcf, 0xcf, 0x0b, 0x66, 0x0f, 0xcf, 0x61
	.byte 0x68, 0x06, 0xcf, 0xd8, 0x66, 0x07, 0xcf, 0x69
	.byte 0xf3, 0x03, 0xf4, 0xe0, 0x47, 0x0e, 0x25, 0x2d
	.byte 0x35, 0x3d, 0xc1, 0x36, 0x8d, 0x21, 0xc1, 0x37
	.byte 0x8d, 0xf1, 0xb0, 0xf6, 0xc2, 0xe3, 0xff, 0x00
	.byte 0x21, 0xc9, 0x61, 0xf1, 0x89, 0x39, 0x41, 0xd1
	.byte 0x8a, 0x39, 0x20, 0xd8, 0xd8, 0xb0, 0xfe, 0xf1
	.byte 0x8a, 0x39, 0x02, 0x01, 0x00, 0xf1, 0x8c, 0x39
	.byte 0x02, 0x01, 0x00, 0xf1, 0x8e, 0x39, 0x00, 0x19
	.byte 0xf1, 0x8f, 0x39, 0x00, 0x00, 0xf1, 0x90, 0x39
	.byte 0x00, 0x00, 0xf1, 0x91, 0x39, 0x00, 0x00, 0xf1
	.byte 0x92, 0x39, 0x00, 0x00, 0xf1, 0x93, 0x39, 0x00
	.byte 0x00, 0xf1, 0x94, 0x39, 0x00, 0x00, 0xf1, 0x95
	.byte 0x39, 0x00, 0x00, 0x0e, 0x0e, 0xd8, 0x8a, 0xda
	.byte 0xcf, 0x17, 0x00, 0xb0, 0xfb, 0xd9, 0xcc, 0x80
	.byte 0x00, 0xd9, 0xd8, 0xc9, 0x7e, 0xd8, 0x12, 0xda
	.byte 0x89, 0xe9, 0x12, 0xe9, 0xee, 0x02, 0x42, 0x44
	.byte 0xa0, 0xe4, 0x00, 0xe9, 0x82, 0xa2, 0x23, 0xb3
	.byte 0xe8, 0x0e

Tempo_AdjustStartMeasure:
	dec 2, xsp
	ld (xsp), a
	ldw wa, 0x80
	lds bc, 0
	calr Tempo_DisplayParamCommon
	ldda16 xwa, 14730
	cp (xsp), 0x0
	jr nz, Tempo_StartMeasureDec
	ld bc, wa
	cp wa, 0x3E7
	jr nc, Tempo_StartMeasureReturn
	inc 1, bc
	stda16 14730, xbc
	jr Tempo_StartMeasureSync

Tempo_StartMeasureDec:
	ld bc, wa
	cps wa, 1
	jr ule, Tempo_StartMeasureReturn
	dec 1, bc
	stda16 14730, xbc

Tempo_StartMeasureSync:
	ldda16 xbc, 14732
	ldda16 xwa, 14730
	cp wa, bc
	jr ule, Tempo_StartMeasureSyncFar
	stda16 14732, xwa
	jr Tempo_StartMeasureSetDirty

Tempo_StartMeasureSyncFar:
	inc 7, wa
	cp wa, bc
	jr nc, Tempo_StartMeasureSetDirty
	stda16 14732, xwa

Tempo_StartMeasureSetDirty:
	setda 4, 58336

Tempo_StartMeasureReturn:
	inc 2, xsp
	ret

Tempo_AdjustEndMeasure:
	dec 2, xsp
	ld (xsp), a
	ldw wa, 0x81
	lds bc, 1
	calr Tempo_DisplayParamCommon
	ldda16 xwa, 14732
	cp (xsp), 0x0
	jr nz, Tempo_EndMeasureDec
	ld bc, wa
	cp wa, 0x3E7
	jr nc, Tempo_EndMeasureReturn
	inc 1, bc
	stda16 14732, xbc
	ld wa, bc
	jr Tempo_EndMeasureSyncStart

Tempo_EndMeasureDec:
	ld bc, wa
	cps wa, 1
	jr ule, Tempo_EndMeasureReturn
	dec 1, bc
	stda16 14732, xbc
	ldda16 xwa, 14732

Tempo_EndMeasureSyncStart:
	ldda16 xbc, 14730
	cp bc, wa
	jr ule, Tempo_EndMeasureSyncFar
	stda16 14730, xwa
	jr Tempo_EndMeasureSetDirty

Tempo_EndMeasureSyncFar:
	inc 7, bc
	cp bc, wa
	jr nc, Tempo_EndMeasureSetDirty
	dec 7, wa
	stda16 14730, xwa

Tempo_EndMeasureSetDirty:
	setda 4, 58336

Tempo_EndMeasureReturn:
	inc 2, xsp
	ret

Tempo_AdjustQuantize:
	dec 2, xsp
	ld (xsp), a
	ldw wa, 0x82
	lds bc, 2
	calr Tempo_DisplayParamCommon
	ldda8 a, 14734
	cp (xsp), 0x0
	jr nz, Tempo_QuantizeDec
	ld c, a
	cp a, 0x31
	jr nc, Tempo_QuantizeReturn
	inc 1, c
	stda8 14734, c
	jr Tempo_QuantizeSetDirty

Tempo_QuantizeDec:
	ld c, a
	cps a, 1
	jr ule, Tempo_QuantizeReturn
	dec 1, c
	stda8 14734, c

Tempo_QuantizeSetDirty:
	setda 4, 58336

Tempo_QuantizeReturn:
	inc 2, xsp
	ret

Tempo_AdjustEffect:
	dec 2, xsp
	ld (xsp), a
	ldw wa, 0x86
	lds bc, 6
	calr Tempo_DisplayParamCommon
	ldda8 a, 14736
	extz wa
	sla wa, 2
	lda_24 xbc, 0xe4a0a4
	ld_sril3 XBC, 0x07, 0xE4, 0xE0
	ld a, (xbc)
	cp (xsp), 0x0
	jr nz, Tempo_EffectDec
	cp a, 0x10
	jr nc, Tempo_EffectReturn
	inc 1, a
	jr Tempo_EffectStore

Tempo_EffectDec:
	cps a, 0
	jr z, Tempo_EffectReturn
	dec 1, a

Tempo_EffectStore:
	ld (xbc), a
	setda 4, 58336

Tempo_EffectReturn:
	inc 2, xsp
	ret

Tempo_IncrementTimeSigNum:
	cps a, 0
	ret nz
	ldw wa, 0x9
	ldw bc, 0x8
	calr Tempo_DisplayParamCommon
	ldda8 a, 14735
	cp a, 0x1D
	ret nc
	inc 1, a
	stda8 14735, a
	setda 4, 58336
	ret

Tempo_DecrementTimeSigNum:
	cps a, 0
	ret nz
	ldw wa, 0x9
	ldw bc, 0x8
	calr Tempo_DisplayParamCommon
	ldda8 a, 14735
	cps a, 0
	ret z
	dec 1, a
	stda8 14735, a
	setda 4, 58336
	ret

Tempo_TimeSigCodeBlock:
	cps	a, 0
	ret	nz
	ldw	wa, 10
	ldw	bc, 11
	calr	391
	ldda8	a, 14736
	cps	a, 0
	ret	z
	dec	1, a
	stda8	14736, a
	.byte 0xf1, 0xe0, 0xe3, 0xbc
	ret
	dec	2, xsp
	ld	(xsp), a
	ldw	wa, 132
	lds	bc, 4
	calr	360
	ldda8	a, 14736
	cp	(xsp), 0
	jr	nz, 14
	ld	c, a
	cps	a, 4
	jr	nc, 24
	inc	1, c
	stda8	14736, c
	jr	12
	ld	c, a
	cps	a, 0
	jr	z, 10
	dec	1, c
	stda8	14736, c
	.byte 0xf1, 0xe0, 0xe3, 0xbc
	inc	2, xsp
	ret

Tempo_EditBPM:
	cps a, 0
	ret nz
	setda 0, 36232
	calr Tempo_DisplayParamReturn
	stda8 14728, l
	cps l, 1
	jr z, Tempo_EditBPMDec
	cps l, 0
	jr nz, Tempo_EditBPMClamp
	ldw wa, 0x23
	calr Tempo_DisplayParamSkipClear
	jr Tempo_EditBPMClamp

Tempo_EditBPMDec:
	ldw wa, 0xF
	calr Tempo_DisplayParamSkipClear
	ldw wa, 0x8
	call MIDI_SendSysExCmd

Tempo_EditBPMClamp:
	setda 7, 13517
	setda 7, 13517
	ret

Tempo_EditBPMApply:
	cps	a, 0
	ret	nz
	ldw	wa, 176
	call	16356496
	ret
	dec	2, xsp
	ld	(xsp), a
	ldw	wa, 146
	ldw	bc, 18
	calr	240
	ldda16	wa, 14730
	cp	(xsp), 0
	jr	nz, 32
	ld	bc, wa
	cp	wa, 999
	jr	nc, 84
	cp	bc, 989
	jr	c, 8
	stdi16	14730, 999
	jr	38
	add	bc, 10
	stda16	14730, bc
	jr	28
	ld	bc, wa
	cps	wa, 1
	jr	ule, 54
	cp	bc, 10
	jr	ugt, 8
	stdi16	14730, 1
	jr	8
	sub	bc, 10
	stda16	14730, bc
	ldda16	bc, 14732
	ldda16	wa, 14730
	cp	wa, bc
	jr	ule, 6
	stda16	14732, wa
	jr	10
	inc	7, wa
	cp	wa, bc
	jr	nc, 4
	stda16	14732, wa
	.byte 0xf1, 0xe0, 0xe3, 0xbc
	inc	2, xsp
	ret
	dec	2, xsp
	ld	(xsp), a
	ldw	wa, 147
	ldw	bc, 19
	calr	123
	ldda16	wa, 14732
	cp	(xsp), 0
	jr	nz, 37
	ld	bc, wa
	cp	wa, 999
	jr	nc, 93
	cp	bc, 989
	jr	c, 11
	stdi16	14732, 999
	ldw	wa, 999
	jr	46
	add	bc, 10
	stda16	14732, bc
	ld	wa, bc
	jr	34
	ld	bc, wa
	cps	wa, 1
	jr	ule, 58
	cp	bc, 10
	jr	ugt, 10
	stdi16	14732, 1
	lds	wa, 1
	jr	12
	sub	bc, 10
	stda16	14732, bc
	ldda16	wa, 14732
	ldda16	bc, 14730
	cp	bc, wa
	jr	ule, 6
	stda16	14730, wa
	jr	12
	inc	7, bc
	cp	bc, wa
	jr	nc, 6
	dec	7, wa
	stda16	14730, wa
	.byte 0xf1, 0xe0, 0xe3, 0xbc
	inc	2, xsp
	ret
	extz	wa
	jrl	-581
	extz	wa
	jrl	-531

Tempo_DisplayParamCommon:
	ordi8 58338, 9
	stda8 58340, a
	stda8 58342, c
	ret

Tempo_DisplayParamSkipClear:
	stda8 32578, a
	ldw wa, 0xEE
	jp SoundCtrl_SendCommand
Tempo_DisplayParamFormat:
	.long LABEL_E3DEF1
	cp	a, (xwa)
	or	hl, ix
	.byte 0x41, 0x0e, 0x0e

Tempo_DisplayParamReturn:
	push_werp 0xFA
	ldi_berp 0xFB, 0
	calr MIDIChan_ScanForFree
	calr VoiceSlot_UpdateState
	calr Tempo_DisplayBPMReturn
	lds wa, 0
	calr SeqRec_ValidateDone
	ldda8 a, 14737
	cps a, 0
	jr z, Tempo_DisplayStartMeasure
	extz wa
	calr Part_IsPercussionType
	cps l, 0
	jr nz, Tempo_DisplayStartMeasure
	ldda8 c, 14737
	extz bc
	ldda16 xwa, 14730
	calr SetWall_StoreAndResolve
	cpdi8 10362, 0
	jr nz, Tempo_DisplayStartMeasure
	lds wa, 0
	calr Part_StoreVoiceTableIndex
	lds wa, 0
	calr Tempo_FormatBPM
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 1
	jrl z, Tempo_DisplayEffect

Tempo_DisplayStartMeasure:
	lds wa, 1
	calr SeqRec_ValidateDone
	ldda8 a, 14738
	cps a, 0
	jr z, Tempo_DisplayEndMeasure
	extz wa
	calr Part_IsPercussionType
	cps l, 0
	jr nz, Tempo_DisplayEndMeasure
	ldda8 c, 14738
	extz bc
	ldda16 xwa, 14730
	calr SetWall_StoreAndResolve
	cpdi8 10362, 0
	jr nz, Tempo_DisplayEndMeasure
	lds wa, 1
	calr Part_StoreVoiceTableIndex
	lds wa, 1
	calr Tempo_FormatBPM
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 1
	jrl z, Tempo_DisplayEffect

Tempo_DisplayEndMeasure:
	lds wa, 2
	calr SeqRec_ValidateDone
	ldda8 a, 14739
	cps a, 0
	jr z, Tempo_DisplayQuantize
	extz wa
	calr Part_IsPercussionType
	cps l, 0
	jr nz, Tempo_DisplayQuantize
	ldda8 c, 14739
	extz bc
	ldda16 xwa, 14730
	calr SetWall_StoreAndResolve
	cpdi8 10362, 0
	jr nz, Tempo_DisplayQuantize
	lds wa, 2
	calr Part_StoreVoiceTableIndex
	lds wa, 2
	calr Tempo_FormatBPM
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 1
	jr z, Tempo_DisplayEffect

Tempo_DisplayQuantize:
	lds wa, 3
	calr SeqRec_ValidateDone
	ldda8 a, 14740
	cps a, 0
	jr z, Tempo_DisplayTimeSigNum
	extz wa
	calr Part_IsPercussionType
	cps l, 0
	jr nz, Tempo_DisplayTimeSigNum
	ldda8 c, 14740
	extz bc
	ldda16 xwa, 14730
	calr SetWall_StoreAndResolve
	cpdi8 10362, 0
	jr nz, Tempo_DisplayTimeSigNum
	lds wa, 3
	calr Part_StoreVoiceTableIndex
	lds wa, 3
	calr Tempo_FormatBPM
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 1
	jr z, Tempo_DisplayEffect

Tempo_DisplayTimeSigNum:
	lds wa, 4
	calr SeqRec_ValidateDone
	ldda8 a, 14741
	cps a, 0
	jr z, Tempo_DisplayEffectLookup
	extz wa
	calr Part_IsPercussionType
	cps l, 0
	jr nz, Tempo_DisplayEffectLookup
	ldda8 c, 14741
	extz bc
	ldda16 xwa, 14730
	calr SetWall_StoreAndResolve
	cpdi8 10362, 0
	jr nz, Tempo_DisplayEffectLookup
	lds wa, 4
	calr Part_StoreVoiceTableIndex
	lds wa, 4
	calr Tempo_FormatBPM
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 1
	jr nz, Tempo_DisplayEffectLookup

Tempo_DisplayEffect:
	calr Tempo_DisplayEffectRender

Tempo_DisplayEffectLookup:
	ldto_berp L, 0xFB
	pop_werp 0xFA
	ret

Tempo_DisplayEffectRender:
	lds wa, 0
	calr SeqRec_ValidateDone
	lds wa, 1
	calr SeqRec_ValidateDone
	lds wa, 2
	calr SeqRec_ValidateDone
	lds wa, 3
	calr SeqRec_ValidateDone
	lds wa, 4
	jrl SeqRec_ValidateDone

Tempo_FormatBPM:
	push_werp 0xFA
	ldada xde, 14744
	ld xbc, xde
	lda xde, (xde + 10)

Tempo_FormatBPMDigit:
	stib_dpi 0xE4, 0x00
	cp xbc, xde
	jr c, Tempo_FormatBPMDigit
	cps a, 0
	jr nz, Tempo_FormatBPMDone
	setda 0, 14743
	jr Tempo_FormatBPMOutput

Tempo_FormatBPMDone:
	resda 0, 14743

Tempo_FormatBPMOutput:
	cps a, 1
	jr nz, Tempo_FormatBPMPad
	setda 1, 14743
	jr Tempo_DisplayBPMValue

Tempo_FormatBPMPad:
	resda 1, 14743

Tempo_DisplayBPMValue:
	ldda16 xwa, 14732
	subda16 xwa, 14730
	inc 1, a
	ldfr_berp A, 0xFA
	mul_sd16b 1, 0x86, 0x39
	ldfr_berp A, 0xFA

Tempo_DisplayBPMFraction:
	cpi_berp 0xFA, 0
	jr z, Tempo_DisplayBPMWithDec
	calr Voice_ReadEventBytes
	calr RhythmParam_TypeCheck
	ldda8 a, 14744
	cp a, 0x81
	jr nz, Tempo_DisplayBPMNoFrac
	dec1_berp 0xFA
	jr Tempo_DisplayBPMDecimal

Tempo_DisplayBPMNoFrac:
	cp a, 0x83
	jr z, Tempo_DisplayBPMWithDec

Tempo_DisplayBPMDecimal:
	calr Voice_ScanTableByType
	cps l, 1
	jr nz, Tempo_DisplayBPMFraction
	jr Tempo_DisplayBPMExit

Tempo_DisplayBPMWithDec:
	cpi_berp 0xFA, 0
	jr z, Tempo_DisplayBPMClean
	ldi_berp 0xFB, 0

Tempo_DisplayBPMFinal:
	stdi8 14744, 129
	calr Voice_ScanTableByType
	cps l, 1
	jr z, Tempo_DisplayBPMExit
	inc1_berp 0xFB
	ldto_berp A, 0xFB
	cp_berp A, 0xFA
	jr nz, Tempo_DisplayBPMFinal

Tempo_DisplayBPMClean:
	stdi8 14744, 131
	calr Voice_ScanTableByType
	cps l, 1
	jr z, Tempo_DisplayBPMExit
	ldb l, 0x0

Tempo_DisplayBPMExit:
	pop_werp 0xFA
	ret

Tempo_DisplayBPMReturn:
	lda xsp, (xsp - 18)
	push xiz
	ld xiy, 0xE4A0B8
	lda xix, (xsp + 6)
	ldw bc, 0x8
	ldirw
	ldda8 e, 14735
	lds32 xwa, 0
	ld a, e
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 5
	ld xiz, xbc
	add xiz, 0x94860
	lda xbc, (xiz + 12)
	ldda8 a, 14726
	inc 3, a
	cp a, (xbc)
	jr z, Tempo_DisplayMeasureRange
	ldmi16 (xsp + 4), 0x34D6
	stda8 13526, e
	ldda8 a, 14726
	inc 3, a
	ld (xbc), a
	push xde
	push xhl
	push xix
	push xiz
	call AccPatch_RefreshSlotOffset_Wrap
	pop xiz
	pop xix
	pop xhl
	pop xde
	mrdb5 0x8F, 0x04, 0x19, 0xD6, 0x34

Tempo_DisplayMeasureRange:
	ldda16 xwa, 14732
	subda16 xwa, 14730
	ld (xiz + 13), a
	resm 7, (xiz + 15)
	lda xde, (xsp + 6)
	lda xwa, (xiz + 64)
	ld xbc, xwa
	lda xhl, (xwa + 16)

Tempo_DisplayMeasureStart:
	ld_spib A, 0xE8
	lda_dpi XBC, 0xE4
	cp xbc, xhl
	jr c, Tempo_DisplayMeasureStart
	cpdi8 14737, 0
	jr z, Tempo_DisplayMeasureSep
	lds wa, 0
	calr Tempo_DisplayEffectValLookup

Tempo_DisplayMeasureSep:
	cpdi8 14738, 0
	jr z, Tempo_DisplayMeasureEnd
	lds wa, 1
	calr Tempo_DisplayEffectValLookup

Tempo_DisplayMeasureEnd:
	cpdi8 14739, 0
	jr z, Tempo_DisplayQuantizeVal
	lds wa, 2
	calr Tempo_DisplayEffectValLookup

Tempo_DisplayQuantizeVal:
	cpdi8 14740, 0
	jr z, Tempo_DisplayTimeSig
	lds wa, 3
	calr Tempo_DisplayEffectValLookup

Tempo_DisplayTimeSig:
	cpdi8 14741, 0
	jr z, Tempo_DisplayEffectVal
	lds wa, 4
	calr Tempo_DisplayEffectValLookup

Tempo_DisplayEffectVal:
	pop xiz
	lda xsp, (xsp + 18)
	ret

Tempo_DisplayEffectValLookup:
	dec 8, xsp
	push xiz
	ld (xsp + 10), a
	cp (xsp + 10), 0x4
	jr z, Tempo_RefreshDisplay4
	cp (xsp + 10), 0x3
	jr z, Tempo_RefreshDisplay3
	cp (xsp + 10), 0x2
	jr z, Tempo_RefreshDisplay2
	cp (xsp + 10), 0x1
	jr z, Tempo_RefreshDisplay1
	cp (xsp + 10), 0x0
	jr nz, Tempo_RefreshDisplay5
	ldda8 a, 14737
	ldfr_berp A, 0xFB
	ld (xsp + 8), 0x18
	jr Tempo_RefreshDisplay5

Tempo_RefreshDisplay1:
	ldda8 a, 14738
	ldfr_berp A, 0xFB
	ld (xsp + 8), 0x20
	jr Tempo_RefreshDisplay5

Tempo_RefreshDisplay2:
	ldda8 a, 14739
	ldfr_berp A, 0xFB
	ld (xsp + 8), 0x28
	jr Tempo_RefreshDisplay5

Tempo_RefreshDisplay3:
	ldda8 a, 14740
	ldfr_berp A, 0xFB
	ld (xsp + 8), 0x30
	jr Tempo_RefreshDisplay5

Tempo_RefreshDisplay4:
	ldda8 a, 14741
	ldfr_berp A, 0xFB
	ld (xsp + 8), 0x38

Tempo_RefreshDisplay5:
	cpi_berp 0xFB, 0
	jrl z, SeqRec_UpdateFlags
	lds32 xwa, 0
	ldda8 a, 14735
	ld xhl, xwa
	add xhl, xhl
	add xhl, xwa
	sll xhl, 5
	add xhl, 0x94860
	ld (xsp + 4), xhl
	ldto_berp A, 0xFB
	dec 1, a
	extz wa
	ldada xbc, 61856
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	extz wa
	sla wa, 2
	lda_24 xbc, 0xe4a0c8
	ld_sril3 XIX, 0x07, 0xE4, 0xE0
	ld e, (xix + 1)
	extz de
	ld c, (xsp + 8)
	extz bc
	cp (xsp + 10), 0x0
	jr nz, SeqRec_InitState
	st_dri3b W, 0x07, 0xEC, 0xE4
	ld c, (xix)
	extz bc
	calr SeqRec_CheckOverflow
	jr SeqRec_InitChannels

SeqRec_InitState:
	ld xwa, (xsp + 4)
	st_dri3b W, 0x07, 0xE0, 0xE4
	ld c, (xix)
	extz bc
	calr SeqRec_OverflowCleanup

SeqRec_InitChannels:
	ldto_berp C, 0xFB
	extz bc
	lds wa, 1
	calr SetWall_StoreAndResolve
	ldda16 xbc, 14730
	dec 1, bc
	ldda8 a, 14726
	extz wa
	ldfr_werp WA, 0xFA
	mul xwa, xbc
	ldfr_werp WA, 0xFA
	lds iz, 0

SeqRec_StartRecord:
	cp_werp IZ, 0xFA
	jr nc, SeqRec_UpdateFlags

SeqRec_StartRecordImpl:
	calr Voice_ReadEventBytes
	ldada xhl, 14744
	ld c, (xhl)
	ld a, c
	and a, 0xF0
	cp a, 0xC0
	jr z, SeqRec_StopRecordImpl
	cp a, 0x80
	jr nz, SeqRec_StartRecord
	cp c, 0x81
	jr nz, SeqRec_StopRecord
	inc 1, iz
	jr SeqRec_StartRecord

SeqRec_StopRecord:
	cp c, 0x82
	jr z, SeqRec_UpdateFlags
	cp c, 0x84
	jr nz, SeqRec_StartRecord
	jr SeqRec_UpdateFlags

SeqRec_StopRecordImpl:
	ld e, (xsp + 8)
	extz de
	ld xwa, (xsp + 4)
	st_dri3b W, 0x07, 0xE0, 0xE8
	and c, 0x1
	sll c, 7
	ld e, (xhl + 5)
	res 7, e
	ld l, (xhl + 4)
	res 7, l
	extz de
	or c, l
	extz bc
	cp (xsp + 10), 0x0
	jr nz, SeqRec_UpdateState
	calr SeqRec_CheckOverflow
	jr SeqRec_StartRecord

SeqRec_UpdateState:
	calr SeqRec_OverflowCleanup
	cp_werp IZ, 0xFA
	jr c, SeqRec_StartRecordImpl

SeqRec_UpdateFlags:
	pop xiz
	inc 8, xsp
	ret

SeqRec_CheckOverflow:
	lda xhl, (xwa + 1)
	cp c, 0xF0
	jr c, SeqRec_HandleOverflow
	and c, 0xF
	ld (xwa), c
	ld (xhl), e
	ret

SeqRec_HandleOverflow:
	ld (xwa), 0x0
	ld (xhl), 0x0
	ret

SeqRec_OverflowCleanup:
	lda xhl, (xwa + 1)
	cp c, 0xF0
	jr nc, SeqRec_CommitData
	cp c, 0x80
	jr c, SeqRec_CommitData
	cps e, 7
	jr nz, SeqRec_CommitData
	ldb c, 0x58
	jr SeqRec_CommitFinalize

SeqRec_CommitData:
	cp c, 0xF0
	jr c, SeqRec_Validate
	ldb c, 0x0

SeqRec_CommitFinalize:
	ld (xwa), c
	ld (xhl), 0x0
	ret

SeqRec_Validate:
	ld (xwa), c
	res 7, e
	ld (xhl), e
	ret

SeqRec_ValidateDone:
	push_werp 0xFA
	ldda8 c, 13526
	ldfr_berp C, 0xFA
	ldda8 c, 14235
	ldfr_berp C, 0xFB
	cps a, 4
	jr z, Part_SetVoiceType4
	cps a, 3
	jr z, Part_SetVoiceType2
	cps a, 2
	jr z, Part_SetVoiceType1
	cps a, 1
	jr z, SeqRec_Cleanup
	cps a, 0
	jr nz, Part_LoadAndIndexVoiceTable
	stdi8 14235, 16
	jr Part_LoadAndIndexVoiceTable

SeqRec_Cleanup:
	stdi8 14235, 8
	jr Part_LoadAndIndexVoiceTable

Part_SetVoiceType1:
	stdi8 14235, 1
	jr Part_LoadAndIndexVoiceTable

Part_SetVoiceType2:
	stdi8 14235, 2
	jr Part_LoadAndIndexVoiceTable

Part_SetVoiceType4:
	stdi8 14235, 4

Part_LoadAndIndexVoiceTable:
	ldda8 a, 14735
	stda8 13526, a
	lds32 xwa, 0
	ldda8 a, 14735
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 5
	add xbc, 0x94860
	ld a, (xbc + 12)
	dec 3, a
	stda8 13529, a
	ld a, (xbc + 13)
	stda8 13527, a
	push xde
	push xhl
	push xix
	push xiz
	call VoiceSlot_InitFromTable
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldto_berp A, 0xFA
	stda8 13526, a
	ldto_berp A, 0xFB
	stda8 14235, a
	pop_werp 0xFA
	ret

Part_StoreVoiceTableIndex:
	ld c, a
	extz bc
	ldda8 a, 14735
	extz wa
	mul wa, 0x5
	add wa, bc
	stda16 14720, xwa
	stdi16 14724, 6
	ret

SetWall_StoreAndResolve:
	stda16 10367, xwa
	extz bc
	ld wa, bc
	jp Voice_ResolveSlotAddr

MIDIChan_ScanForFree:
	ld xbc, 0xF1A0
	ldb a, 0x1

MIDIChan_ScanLoop:
	cp (xbc), 0x10
	jr z, MIDIChan_Found
	inc 1, xbc
	inc 1, a
	cp a, 0x11
	jr ule, MIDIChan_ScanLoop

MIDIChan_Found:
	cp a, 0x10
	jr ule, MIDIChan_StoreResult
	stdi8 14742, 0
	ret

MIDIChan_StoreResult:
	stda8 14742, a
	ret

VoiceSlot_UpdateState:
	ldda8 a, 14742
	stda8 10381, a
	cpdi8 14742, 0
	jr nz, VoiceSlot_SetBit2
	resda 2, 10363
	jr VoiceSlot_ValidateAndResolve

VoiceSlot_SetBit2:
	setda 2, 10363

VoiceSlot_ValidateAndResolve:
	call SeqVoice_ValidateAndProcessState
	ldmm16 10367, 14730
	ldda8 a, 14739
	cps a, 0
	jr z, VoiceSlot_CheckSlot2
	extz wa
	jr VoiceSlot_ResolveAddr

VoiceSlot_CheckSlot2:
	ldda8 a, 14740
	cps a, 0
	jr z, VoiceSlot_CheckSlot3
	extz wa
	jr VoiceSlot_ResolveAddr

VoiceSlot_CheckSlot3:
	ldda8 a, 14741
	cps a, 0
	jr z, VoiceSlot_CheckSlot4
	extz wa
	jr VoiceSlot_ResolveAddr

VoiceSlot_CheckSlot4:
	ldda8 a, 14738
	cps a, 0
	jr z, VoiceSlot_CheckSlot5
	extz wa
	jr VoiceSlot_ResolveAddr

VoiceSlot_CheckSlot5:
	ldda8 a, 14737
	cps a, 0
	jr z, VoiceSlot_StoreAndReturn
	extz wa

VoiceSlot_ResolveAddr:
	call Voice_ResolveSlotAddr

VoiceSlot_StoreAndReturn:
	ldmm8 14726, 10382
	ret

Part_IsPercussionType:
	dec 1, a
	extz wa
	extz xwa
	add xwa, 0xF1A0
	ld a, (xwa)
	cp a, 0xD
	jr z, EventCode_CheckExit
	cp a, 0xE
	jr z, EventCode_CheckExit
	cp a, 0xF
	jr z, EventCode_CheckExit
	cp a, 0x10
	jr nz, PartType_NotPercussion

EventCode_CheckExit:
	ldb l, 0x1
	jr PartType_Return

PartType_NotPercussion:
	ldb l, 0x0

PartType_Return:
	ret

Voice_ReadEventBytes:
	push xiz
	calr VoiceTable_ResolveReadAddr
	ld xwa, xhl
	ld c, (xwa)
	and c, 0xF0
	cp c, 0x80
	jr z, VoiceEvt_Size1
	cp c, 0xD0
	jr z, VoiceEvt_CheckD2
	cp c, 0xC0
	jr z, VoiceEvt_Size6
	cp c, 0xB0
	jr z, VoiceEvt_Size6
	cp c, 0x90
	jr nz, VoiceEvt_Size1

VoiceEvt_Size6:
	ldi_werp 0xFA, 6
	jr VoiceBuffer_CopyLoop

VoiceEvt_CheckD2:
	cp (xwa), 0xD2
	jr nz, VoiceEvt_Size3
	ldi_werp 0xFA, 4
	jr VoiceBuffer_CopyLoop

VoiceEvt_Size3:
	ldi_werp 0xFA, 3
	jr VoiceBuffer_CopyLoop

VoiceEvt_Size1:
	ldi_werp 0xFA, 1

VoiceBuffer_CopyLoop:
	lds iz, 0
	cpi_werp 0xFA, 0
	jr ule, VoiceBuf_CopyDone

VoiceBuf_CopyLoop:
	ldada xbc, 14744
	ld de, iz
	extz xde
	add xde, xbc
	ld c, (xwa)
	ld (xde), c
	calr VoiceTable_AdvanceReadPos
	ld xwa, xhl
	inc 1, iz
	cp_werp IZ, 0xFA
	jr c, VoiceBuf_CopyLoop

VoiceBuf_CopyDone:
	pop xiz
	ret

Voice_ScanTableByType:
	push xiz
	calr Voice_ResolveTableAddr
	ld xwa, xhl
	ldda8 c, 14744
	cp c, 0x83
	jr z, VoiceScan_Size1
	cp c, 0x81
	jr z, VoiceScan_Size1
	cp c, 0xD5
	jr z, Voice_SetScanType3
	cp c, 0xD4
	jr z, Voice_SetScanType3
	cp c, 0xD3
	jr z, Voice_SetScanType3
	cp c, 0xD2
	jr z, Voice_SetScanType3
	cp c, 0xD1
	jr z, Voice_SetScanType3
	cp c, 0x91
	jr z, VoiceScan_Size8
	cp c, 0x90
	jr nz, VoiceScan_Size0
	ldi_werp 0xFA, 6
	jr Voice_ScanTableEntries

VoiceScan_Size8:
	ldi_erpw 0xFA, 0x08, 0x00
	jr Voice_ScanTableEntries

Voice_SetScanType3:
	ldi_werp 0xFA, 3
	jr Voice_ScanTableEntries

VoiceScan_Size1:
	ldi_werp 0xFA, 1
	jr Voice_ScanTableEntries

VoiceScan_Size0:
	ldi_werp 0xFA, 0

Voice_ScanTableEntries:
	lds iz, 0
	cpi_werp 0xFA, 0
	jr ule, VoiceScan_NotFound

VoiceScan_WriteLoop:
	ldada xbc, 14744
	ld de, iz
	extz xde
	add xde, xbc
	ld c, (xde)
	ld (xwa), c
	calr VoiceTable_AdvanceWritePos
	ld xwa, xhl
	cp xwa, 0xFFFFFFFF
	jr nz, VoiceScan_NextEntry
	ldb l, 0x1
	jr VoiceScan_Return

VoiceScan_NextEntry:
	inc 1, iz
	cp_werp IZ, 0xFA
	jr c, VoiceScan_WriteLoop

VoiceScan_NotFound:
	ldb l, 0x0

VoiceScan_Return:
	pop xiz
	ret

VoiceTable_AdvanceReadPos:
	ld xhl, xwa
	ldda16 xwa, 14722
	inc 1, wa
	stda16 14722, xwa
	cp wa, 0x100
	jr c, VoiceTable_AdvRead_Done
	ldda16 xwa, 14718
	dec 1, wa
	extz xwa
	sll xwa, 8
	ld xde, xwa
	add xde, 0xB0000
	ld c, (xde + 4)
	extz bc
	sll bc, 8
	ld a, (xde + 3)
	extz wa
	add wa, bc
	stda16 14718, xwa
	stdi16 14722, 5

VoiceTable_AdvRead_Done:
	jr __jrt_nop_F66C60
__jrt_nop_F66C60:

VoiceTable_ResolveReadAddr:
	ldda16 xbc, 14722
	extz xbc
	ldda16 xwa, 14718
	dec 1, wa
	extz xwa
	sll xwa, 8
	add xwa, 0xB0000
	add xwa, xbc
	ld xhl, xwa
	ret

VoiceTable_AdvanceWritePos:
	ld xhl, xwa
	ldda16 xwa, 14724
	inc 1, wa
	stda16 14724, xwa
	cp wa, 0xFF
	jr c, RhythmParam_Setup
	ldda16 xwa, 13524
	cps wa, 0
	jr nz, VoiceTable_AdvWrite_AllocSlot
	ld xhl, 0xFFFFFFFF
	jr RhythmParam_Entry

VoiceTable_AdvWrite_AllocSlot:
	dec 1, wa
	stda16 13524, xwa
	ldw bc, 0x96
	ld xde, 0x9F200

VoiceTable_AdvWrite_ScanLoop:
	bitm 7, (xde)
	jr z, VoiceTable_AdvWrite_LinkEntry
	inc 1, bc
	st_dri3b B, 0xE9, 0x00, 0x01
	cp bc, 0x153
	jr ule, VoiceTable_AdvWrite_ScanLoop

VoiceTable_AdvWrite_LinkEntry:
	ldda16 xwa, 14720
	extz xwa
	sll xwa, 8
	ld xhl, xwa
	add xhl, 0x95C00
	ld a, c
	ld (xhl + 3), a
	ld wa, bc
	srl wa, 8
	ld (xhl + 4), a
	ldda16 xwa, 14720
	ld (xde + 1), a
	ldda16 xwa, 14720
	srl wa, 8
	ld (xde + 2), a
	stda16 14720, xbc
	stdi16 14724, 6
	setm 7, (xde)

; Rhythm parameter dispatch setup
RhythmParam_Setup:
	calr Voice_ResolveTableAddr

; Rhythm parameter entry
RhythmParam_Entry:
	ret

Voice_ResolveTableAddr:
	ldda16 xbc, 14724
	extz xbc
	ldda16 xwa, 14720
	extz xwa
	sll xwa, 8
	add xwa, 0x95C00
	add xwa, xbc
	ld xhl, xwa
	ret

; Rhythm parameter type check
RhythmParam_TypeCheck:
	ldada xwa, 14744
	bitda 0, 14743
	jr z, RhythmParam_Process
	ld xde, xwa
	ld c, (xwa)
	ld a, c
	and a, 0xF0
	cp a, 0x80
	jr z, RhythmParam_Dispatch
	cp a, 0x90
	jr nz, RhythmParam_CheckExit
	ld (xde), 0x90
	ret

; Rhythm parameter dispatch (voice type classification)
RhythmParam_Dispatch:
	extz bc
	sub bc, 0x80
	cps bc, 0
	jr lt, RhythmParam_CheckExit
	cps bc, 6
	jr gt, RhythmParam_CheckExit
	add bc, bc
	lda_24 xix, 0xe4a126
	ld_sriw3 BC, 0x07, 0xF0, 0xE4
	lda_24 xix, 0xf66d5a
	jp_dri 8, 0x07, 0xF0, 0xE4

RhythmParam_CheckExit:
	ld (xde), 0x0
	ret

RhythmParam_DispatchTableData:
	ld	(xde), 131
	ret

; Rhythm parameter processing
RhythmParam_Process:
	ld xhl, xwa
	ld e, (xwa)
	ld d, e
	and d, 0xF0
	cp d, 0x80
	jrl z, VoiceSlot_Dispatch
	lda xbc, (xhl + 2)
	lda xwa, (xhl + 3)
	cp d, 0xD0
	jrl z, VoiceParam_D0Handler
	cp d, 0xB0
	jrl z, VoiceParam_B0_Handler
	cp d, 0x90
	jrl nz, Voice_ClearSlotAndRet
	ldda8 e, 14734
	cp e, 0x19
	jr ule, VoiceNote_SubtractOffset
	ld xix, xbc
	sub e, 0x19
	ld a, (xbc)
	add a, e
	ld (xbc), a
	cp a, 0x7F
	jr ule, Voice_BoundaryCheck
	ld (xix), 0x7F
	jr Voice_BoundaryCheck

VoiceNote_SubtractOffset:
	cp e, 0x19
	jr nc, Voice_BoundaryCheck
	ld xix, xbc
	ldb a, 0x19
	sub a, e
	ld e, a
	ld a, (xbc)
	sub a, e
	ld (xbc), a
	cps a, 0
	jr ge, Voice_BoundaryCheck
	ld (xix), 0x0

Voice_BoundaryCheck:
	bitda 1, 14743
	jr z, VoiceBound_CalcOctave
	lda xbc, (xhl + 2)
	ld a, (xbc)
	cp a, 0xC
	jr c, VoiceBound_CalcOctave
	sub a, 0xC
	ld (xbc), a

VoiceBound_CalcOctave:
	ld a, (xhl + 2)
	extz wa
	div a, 0xC
	ld e, w
	lda xwa, (xhl + 6)
	lda xbc, (xhl + 7)
	cp e, 0xB
	jr z, VoiceParam_D0_CheckD4
	cps e, 7
	jr z, VoiceParam_D0_Skip
	cps e, 4
	jr z, VoiceParam_D0_Process
	cps e, 3
	jr nz, VoiceParam_D0_StoreD5

VoiceParam_D0_Process:
	ld (xhl), 0x91
	ld (xwa), 0x0
	jr VoiceParam_D0_CheckD5

VoiceParam_D0_Skip:
	ld (xhl), 0x91
	ld (xwa), 0x3
	ld (xbc), 0x0
	ret

VoiceParam_D0_CheckD4:
	ld (xhl), 0x91
	ld (xwa), 0x11

VoiceParam_D0_CheckD5:
	ld (xbc), 0x11
	ret

VoiceParam_D0_StoreD5:
	ld (xhl), 0x90
	ret

VoiceParam_B0_Handler:
	ld xde, xbc
	ld c, (xbc)
	res 7, c
	cp c, 0x16
	jr ule, VoiceParam_B0_CheckType
	cp c, 0x19
	jrl nz, Voice_ClearSlotAndRet

VoiceParam_B0_CheckType:
	ld a, (xwa)
	and a, 0x1F
	lda xbc, (xhl + 4)
	lda xix, (xhl + 5)
	cps a, 4
	jr nz, __pad_F66E4B
	bitm 3, (xix)
	jr z, __pad_F66E4B
	ld (xhl), 0xD3
	bitm 3, (xbc)
	jr nz, VoiceParam_B0_Process
	ld (xde), 0x0
	ret

VoiceParam_B0_Process:
	ld (xde), 0x7F
	ret

__pad_F66E4B:
	cp a, 0x8
	jr nz, Voice_ClearSlotAndRet
	ld a, (xix)
	res 7, a
	cps a, 0
	jr z, Voice_ClearSlotAndRet
	ld (xhl), 0xD4
	ld a, (xbc)
	res 7, a
	ld (xde), a
	ret

; Voice parameter D0 type (fine tuning)
VoiceParam_D0Handler:
	cp e, 0xD2
	jr nz, VoiceParam_D3Special
	ld e, (xwa)
	cp e, 0x40
	jr c, VoiceParam_DownscaleBelow40
	sub e, 0x40
	extz de
	div e, 0x6
	add e, 0x40
	ld (xbc), e
	ret

; Voice param downscale below 0x40
VoiceParam_DownscaleBelow40:
	ldb a, 0x40
	sub a, e
	extz wa
	div a, 0x6
	ld e, a
	ldb a, 0x40
	sub a, e
	ld (xbc), a
	ret

; Voice parameter D3 special case (transition to D5)
VoiceParam_D3Special:
	cp e, 0xD3
	ret nz
	ld (xhl), 0xD5
	ret

; Voice slot dispatch
VoiceSlot_Dispatch:
	extz de
	sub de, 0x80
	cps de, 0
	jr lt, Voice_ClearSlotAndRet
	cps de, 6
	jr gt, Voice_ClearSlotAndRet
	add de, de
	lda_24 xix, 0xe4a118
	ld_sriw3 DE, 0x07, 0xF0, 0xE8
	lda_24 xix, 0xf66ebd
	jp_dri 8, 0x07, 0xF0, 0xE8

Voice_ClearSlotAndRet:
	ld (xhl), 0x0
	ret

VoiceSlot_DispatchByType:
	ld	(xhl), 131
	ret
	ret
	nop
	nop
	nop
	ret
	nop
	nop
	nop
	ret
	nop
	nop
	nop
	ret
	nop
	nop
	nop
	ret
	nop
	nop
	nop
	ret
	nop
	nop
	nop
	pushw	wa
	pushw	hl
	call	16147006
	inc	4, xsp
	ret

Voice_ResolveSlotAddr:
	push xiz
	ldda8 w, 14742
	call SetWall_SlotResolve
	stda16 14722, xiy
	ldda16 xiy, 10415
	stda16 14718, xiy
	pop xiz
	ret

VoiceSlot_Dispatch_Type81:
	ldb a, 0x7F
	stda8 14280, a
	ldb a, 0xFF
	stda8 14279, a
	ldb c, 0x0

VoiceSlot_Dispatch_Type90:
	cps c, 7
	jr z, VoiceSlot_Dispatch_D0Type
	ld xwa, 0x37AB
	ldb e, 0x0
	lda_dri3 XIY, 0x03, 0xE0, 0xE4
	ld xwa, 0x37B2
	ldb e, 0x1
	lda_dri3 XIY, 0x03, 0xE0, 0xE4
	ld xwa, 0x37B9
	ldb e, 0xFF
	lda_dri3 XIY, 0x03, 0xE0, 0xE4
	ld xwa, 0x37C0
	ldb e, 0xFF
	lda_dri3 XIY, 0x03, 0xE0, 0xE4
	inc 1, c
	jr VoiceSlot_Dispatch_Type90

VoiceSlot_Dispatch_D0Type:
	stdi8 14281, 64
	calr RhythmDrum_LoadVoiceParams
	stdi8 14281, 32
	calr RhythmDrum_LoadVoiceParams
	stdi8 14281, 16
	calr RhythmDrum_LoadVoiceParams
	stdi8 14281, 8
	calr RhythmDrum_LoadVoiceParams
	stdi8 14281, 4
	calr RhythmDrum_LoadVoiceParams
	stdi8 14281, 2
	calr RhythmDrum_LoadVoiceParams
	stdi8 14281, 1
	calr RhythmDrum_LoadVoiceParams
	ret

VoiceSlot_Dispatch_Return:
	push	xiz
	call	16150403
	pop	xiz
	ret
	bit	7, a
	jr	nz, 20
	cpdi8	13526, 11
	jr	ge, 6
	incdi8	1, 13526
	jr	5
	stdi8	13526, 11
	jr	18
	cpdi8	13526, 0
	jr	gt, 7
	stdi8	13526, 0
	jr	4
	decdi8	1, 13526
	calr	4
	calr	174
	ret
	lds32	xhl, 0
	ldda8	l, 13526
	and	l, 31
	add	l, 128
	ld	xbc, 64602
	ldb	a, 0
	.byte 0xf3, 0x03, 0xe4, 0xe0, 0x47
	ldb	a, 1
	.byte 0xc3, 0x03, 0xe4, 0xe0, 0x26
	and	h, 128
	.byte 0xf3, 0x03, 0xe4, 0xe0, 0x46
	ldda8	a, 64602
	ldb	w, 0
	ldb	e, 72
	ldb	d, 0
	call	16626673
	ret

DrumParam_ProcessChannel:
	push xiz
	calr DrumParam_LookupChannelBit
	call __pad_F67013
	pop xiz
	ret

DrumParam_LookupChannelBit:
	push xwa
	push xix
	ldda8 a, 14776
	ld xix, 0xF6700C
	ld_srib3 A, 0x03, 0xF0, 0xE0
	stda8 14281, a
	pop xix
	pop xwa
	ret

PatIdx_Lookup_Return:
	.byte 0x01
	push_sr
	.byte 0x04
	ldio	16, 32
	.byte 0x40

__pad_F67013:
	push_a
	calr DrumParam_ReadVoiceCount
	ld l, a
	pop_a
	push l
	push_a
	calr Rhythm_MapChannelToDrumIndex
	pop_a
	ld xiy, 0x37AB
	add xiy, xbc
	bit 7, a
	jr nz, VoiceTable_InitEntry_Loop
	cp (xiy), 0x9
	jr ge, VoiceTable_InitEntry
	incm8 1, (xiy)
	jr RhythmVoice_LoadParams

VoiceTable_InitEntry:
	ld (xiy), 0x9
	jr RhythmVoice_LoadParams

VoiceTable_InitEntry_Loop:
	cp (xiy), 0x0
	jr z, RhythmVoice_LoadParams
	decm8 1, (xiy)

RhythmVoice_LoadParams:
	pop l
	push l
	calr DrumParam_ReadMaxCount
	pop l
	cp l, w
	jr ule, VoiceTable_InitEntry_Done
	push w
	calr DrumParam_ReadVoiceCount
	pop w
	ld (xix), w

VoiceTable_InitEntry_Done:
	calr RhythmDrum_LoadVoiceParams
	calr __pad_F67459
	calr DrumParam_BuildActiveMask
	ret

DrumParam_BuildActiveMask:
	ldb w, 0x0
	stda8 14280, w
	xor bc, bc
	ldb w, 0x1
	ld xix, 0x37AB
	ld xiy, 0x37B9

VoiceTable_InitEntry_Store:
	ld_spib A, 0xF0
	cp_spib A, 0xF4
	jr z, VoiceTable_InitEntry_Return
	orddm8 14280, w

VoiceTable_InitEntry_Return:
	sll w, 1
	inc 1, bc
	cps bc, 7
	jr lt, VoiceTable_InitEntry_Store
	xor bc, bc
	ldb w, 0x1
	ld xix, 0x37B2
	ld xiy, 0x37C0

MultiVoice_SetupChannel:
	ld_spib A, 0xF0
	cp_spib A, 0xF4
	jr z, MultiVoice_Setup_Loop
	orddm8 14280, w

MultiVoice_Setup_Loop:
	sll w, 1
	inc 1, bc
	cps bc, 7
	jr lt, MultiVoice_SetupChannel
	ldda8 a, 13526
	cpda8 a, 14279
	jr z, MultiVoice_Setup_WriteParam
	ldb b, 0x7F
	stda8 14280, b

MultiVoice_Setup_WriteParam:
	ret

Rhythm_MapChannelToDrumIndex:
	lds32 xbc, 0
	ldda8 c, 14281
	srl c, 1
	add xbc, 0xF670DD
	ld c, (xbc)
	cps c, 6
	jr le, MultiVoice_Setup_NextChan
	ldb c, 0x0

MultiVoice_Setup_NextChan:
	push c
	lds32 xbc, 0
	pop c
	ret

MultiVoice_Setup_Done:
	nop
	.byte 0x01
	push_sr
	nop
	.byte 0x03
	nop
	nop
	nop
	.byte 0x04
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	halt
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	.zero 8
	.byte 0x06

DrumParam_ReadVoiceCount:
	calr Rhythm_MapChannelToDrumIndex
	ld xix, 0x37B2
	add xix, xbc
	ld a, (xix)
	ret

RhythmDrum_LoadVoiceParams:
	calr Rhythm_MapChannelToDrumIndex
	ld xix, 0x37AB
	add xix, xbc
	lds32 xwa, 0
	ld a, (xix)
	mul bc, 0xA
	add xbc, xwa
	lds32 xde, 0
	lds32 xhl, 0
	ld xwa, 0xE4A1D4

VoiceAssign_ProcessRequest:
	cp hl, bc
	jr z, VoiceAssign_Process_Loop
	push xbc
	ld_srib3 C, 0x07, 0xE0, 0xEC
	and xbc, 0xFF
	add xde, xbc
	pop xbc
	inc 1, hl
	jr VoiceAssign_ProcessRequest

VoiceAssign_Process_Loop:
	push xde
	calr Rhythm_MapChannelToDrumIndex
	ld xix, 0x37B2
	add xix, xbc
	lds32 xwa, 0
	ld a, (xix)
	pop xde
	add xde, xwa
	sll xde, 2
	ld xwa, 0xE4A21A
	add xwa, xde
	ld xhl, (xwa)
	push xhl
	calr Rhythm_MapChannelToDrumIndex
	pop xhl
	ld xde, xhl
	srl xde, 8
	srl xde, 8
	srl xde, 8
	ld xwa, 0x3881
	add xwa, xbc
	ld (xwa), e
	push xhl
	calr VoiceAssign_Process_Return
	pop xhl
	srl xhl, 8
	srl xhl, 8
	push l
	lds32 xhl, 0
	pop l
	calr __pad_F671E7
	ret

VoiceAssign_Process_Return:
	stdi8 37110, 72
	call SndParam_ApplyProgramChange_Safe
	call VoiceParam_ClampAndValidate_Tramp
	pushw hl
	calr Rhythm_MapChannelToDrumIndex
	popw hl
	ld xix, 0x38D2
	lda_dri3 XSP, 0x03, 0xF0, 0xE4
	ld xix, 0x38D9
	lda_dri3 XIZ, 0x03, 0xF0, 0xE4
	sll l, 1
	sll hl, 1
	ld xiy, 0xE45142
	ld_sriw3 WA, 0x07, 0xF4, 0xEC
	add hl, 0x2
	lds32 xde, 0
	ld_sriw3 DE, 0x07, 0xF4, 0xEC
	ld w, a
	and xwa, 0xFF00
	sll xwa, 8
	ld xix, 0x400000
	addda32 xix, 12919
	add xix, xwa
	add xix, xde
	jr __jrt_nop_F671E6
__jrt_nop_F671E6:

VoiceAssign_StoreFinal:
	ret

__pad_F671E7:
	pushw hl
	push xix
	calr Rhythm_MapChannelToDrumIndex
	pop xix
	popw hl
	ld xwa, 0xF67244
	ld_srib3 A, 0x07, 0xE0, 0xEC
	and xwa, 0x7
	push xwa
	ld xbc, xwa
	sll xbc, 1
	add xbc, 0xF67248
	lds32 xde, 0
	ld de, (xbc)
	push xix
	calr RegPreset_Load_Loop
	pop xix
	pop xwa
	push xwa
	ld xbc, xwa
	sll xbc, 1
	add xbc, 0xF67258
	lds32 xde, 0
	ld de, (xbc)
	push xix
	calr MIDIChan_DispatchDone
	pop xix
	pop xwa
	push xwa
	ld xbc, xwa
	sll xbc, 1
	add xbc, 0xF67268
	ld de, (xbc)
	push xix
	calr VoiceResolve_CheckAndStore
	pop xix
	pop xwa
	push xix
	calr __pad_F6742B
	pop xix
	ret

RegPreset_LoadVoiceData:
	nop
	pop_sr
	.byte 0x04
	reti
	nop
	nop
	retd	0x0f04
	.byte 0x04
	retd	0x0000
	.byte 0x04
	retd	0x0f04
	.byte 0x04
	retd	0x0004
	nop
	ldw	bc, 12548
	.byte 0x04
	ldw	bc, 0
	.byte 0x04
	ldw	bc, 12548
	.byte 0x04
	ldw	bc, 4
	nop
	ei	0x04
	ei	0x04
	ei	0x00
	nop
	.byte 0x04
	ei	0x04
	ei	0x04
	ei	0x04

RegPreset_Load_Loop:
	push xix
	push xde
	calr DrumChannel_MapToIndexA
	pop xde
	pop xix
	ld wa, bc
	sll wa, 1
	mul a, 0x14
	add wa, de
	push xwa
	call MIDIChan_DispatchTable
	pop xwa
	lds hl, 1
	cp wa, 0x400
	jr nc, RegPreset_Load_Return
	lds hl, 0

RegPreset_Load_Return:
	lds32 xbc, 0

__pad_F6729B:
	cps c, 4
	jr z, ChanAssign_StoreResult
	push xbc
	pushw wa
	push xbc
	calr __pad_F672B2
	pop xbc
	calr ChanAssign_Lookup_Found
	popw wa
	pop xbc
	inc 1, wa
	inc 1, c
	jr __pad_F6729B

ChanAssign_StoreResult:
	ret

__pad_F672B2:
	lds32 xde, 0
	ld_srib3 E, 0x07, 0xF0, 0xE0
	sll e, 1
	push xix
	pushw de
	pushw hl
	calr DrumChannel_MapToIndexB
	popw hl
	popw de
	pop xix
	mul c, 0x26
	add bc, de
	cps hl, 0
	jr nz, ChanAssign_Lookup
	add bc, 0x118
	jr ChanAssign_Lookup_Loop

ChanAssign_Lookup:
	add bc, 0x518

ChanAssign_Lookup_Loop:
	lds32 xwa, 0
	ld_sriw3 WA, 0x07, 0xF0, 0xE4
	ld xde, xiy
	add xde, xwa
	ret

ChanAssign_Lookup_Found:
	push xde
	push xbc
	calr Rhythm_MapChannelToDrumIndex
	sll xbc, 4
	ld xwa, xbc
	pop xbc
	sll bc, 2
	add xwa, xbc
	add xwa, 0x380A
	pop xde
	add xde, 0x6
	ld (xwa), xde
	ret

MIDIChan_DispatchTable:
	ldw bc, 0x3D1
	lds32 xwa, 0
	ld_srib3 W, 0x07, 0xF0, 0xE4
	and xwa, 0xFF00
	sll xwa, 8
	ld xiy, 0x400000
	addda32 xix, 12919
	add xiy, xwa
	ret

DrumChannel_MapToIndexA:
	cpdi8 14281, 1
	jr nz, MIDIChan_Dispatch_Ch1
	lds32 xbc, 0
	jr DrumChannel_MapA_NullRet

MIDIChan_Dispatch_Ch1:
	cpdi8 14281, 2
	jr nz, MIDIChan_Dispatch_Ch2
	lds32 xbc, 0
	jr DrumChannel_MapA_NullRet

MIDIChan_Dispatch_Ch2:
	cpdi8 14281, 4
	jr nz, MIDIChan_Dispatch_Ch3
	lds32 xbc, 0
	jr DrumChannel_MapA_NullRet

MIDIChan_Dispatch_Ch3:
	cpdi8 14281, 8
	jr nz, MIDIChan_Dispatch_Ch4
	lds32 xbc, 1
	jr DrumChannel_MapA_NullRet

MIDIChan_Dispatch_Ch4:
	cpdi8 14281, 16
	jr nz, MIDIChan_Dispatch_Ch5
	lds32 xbc, 2
	jr DrumChannel_MapA_NullRet

MIDIChan_Dispatch_Ch5:
	cpdi8 14281, 32
	jr nz, MIDIChan_Dispatch_Ch6
	lds32 xbc, 3
	jr DrumChannel_MapA_NullRet

MIDIChan_Dispatch_Ch6:
	lds32 xbc, 4

DrumChannel_MapA_NullRet:
	ret

DrumChannel_MapToIndexB:
	cpdi8 14281, 1
	jr nz, MIDIChan_Dispatch_Ch7
	lds32 xbc, 0
	jr DrumChannel_MapB_NullRet

MIDIChan_Dispatch_Ch7:
	cpdi8 14281, 2
	jr nz, MIDIChan_Dispatch_Ch8
	lds32 xbc, 0
	jr DrumChannel_MapB_NullRet

MIDIChan_Dispatch_Ch8:
	cpdi8 14281, 4
	jr nz, MIDIChan_Dispatch_Ch9
	lds32 xbc, 0
	jr DrumChannel_MapB_NullRet

MIDIChan_Dispatch_Ch9:
	cpdi8 14281, 8
	jr nz, MIDIChan_Dispatch_Ch10
	lds32 xbc, 2
	jr DrumChannel_MapB_NullRet

MIDIChan_Dispatch_Ch10:
	cpdi8 14281, 16
	jr nz, MIDIChan_Dispatch_Ch11
	lds32 xbc, 3
	jr DrumChannel_MapB_NullRet

MIDIChan_Dispatch_Ch11:
	cpdi8 14281, 32
	jr nz, MIDIChan_Dispatch_Ch12
	lds32 xbc, 4
	jr DrumChannel_MapB_NullRet

MIDIChan_Dispatch_Ch12:
	lds32 xbc, 5

DrumChannel_MapB_NullRet:
	ret

MIDIChan_DispatchDone:
	push xix
	push xde
	calr DrumChannel_MapToIndexA
	pop xde
	pop xix
	mul bc, 0x7
	add xbc, xde
	add xbc, 0x248
	add xix, xbc
	calr Rhythm_MapChannelToDrumIndex
	mul bc, 0x8
	add xbc, 0x37D1
	ld xiy, xbc
	lds32 xbc, 7
	push xiy
	push xix
	pop xiy
	pop xix
	ldir85
	ret

VoiceResolve_CheckAndStore:
	bitda 0, 14281
	jr nz, Rhythm_ClearChannelDrumIndex
	bitda 1, 14281
	jr nz, Rhythm_ClearChannelDrumIndex
	bitda 2, 14281
	jr nz, Rhythm_ClearChannelDrumIndex
	bitda 3, 14281
	jr nz, Rhythm_ClearChannelDrumIndex
	add de, 0x3D2
	ld_srib3 A, 0x07, 0xF0, 0xE8
	calr Rhythm_MapChannelToDrumIndex
	add xbc, 0xF67424
	ld c, (xbc)
	and a, c
	cp a, c
	jr nz, VoiceResolve_Return
	ldb a, 0x0
	jr __pad_F67412

VoiceResolve_Return:
	ldb a, 0x1

__pad_F67412:
	jr VoiceResolve_InitSearch

Rhythm_ClearChannelDrumIndex:
	ldb a, 0x0

VoiceResolve_InitSearch:
	push_a
	calr Rhythm_MapChannelToDrumIndex
	pop_a
	add xbc, 0x387A
	ld (xbc), a
	ret

VoiceResolve_SearchDone:
	ldio	8, 8
	ldio	8, 16
	.byte 0x20

__pad_F6742B:
	ldw bc, 0x3D0
	ld_srib3 A, 0x07, 0xF0, 0xE4
	push xix
	calr VoiceResolve_FindSlot
	pop xix
	push_a
	push xix
	calr Rhythm_MapChannelToDrumIndex
	pop xix
	pop_a
	add xbc, 0x37CA
	ld (xbc), a
	ret

VoiceResolve_FindSlot:
	push xbc
	ld xbc, 0xE46B8A
	ld_srib3 A, 0x03, 0xE4, 0xE0
	pop xbc
	ret

VoiceResolve_FindSlot_Return:
	add	a, 3
	ret

__pad_F67459:
	calr Rhythm_MapChannelToDrumIndex
	add xbc, 0x37AB
	lds32 xwa, 0
	ld a, (xbc)
	sll xwa, 4
	ld xiy, 0xE4A134
	add xiy, xwa
	ld xix, 0x3888
	ld xbc, 0x10
	push xix
	ldir85
	pop xix
	calr RhythmDrum_LoadVoiceParams
	ret

DrumParam_ProcessChannelAlt:
	push xiz
	calr DrumParam_LookupChannelBit
	call PartVoice_UpdateParams
	pop xiz
	ret

PartVoice_UpdateParams:
	push_a
	calr DrumParam_ReadMaxCount
	pop_a
	calr Rhythm_MapChannelToDrumIndex
	ld xix, 0x37B2
	add xix, xbc
	ld c, (xix)
	cps a, 0
	jr nz, PartVoice_Update_Loop
	cp c, w
	jr ge, DrumParam_ClampVoiceCount
	inc 1, c
	jr DrumParam_ClampVoiceCount

PartVoice_Update_Loop:
	cps c, 0
	jr z, DrumParam_ClampVoiceCount
	dec 1, c
	bitda 0, 14281
	jr z, DrumParam_ClampVoiceCount
	cps c, 1
	jr ge, DrumParam_ClampVoiceCount
	ldb c, 0x1

DrumParam_ClampVoiceCount:
	cp c, w
	jr gt, PartVoice_Update_Return
	cps c, 0
	jr lt, PartVoice_Update_Done
	jr __pad_F674CB

PartVoice_Update_Return:
	ld c, w
	jr __pad_F674CB

PartVoice_Update_Done:
	ldb c, 0x0

__pad_F674CB:
	ld (xix), c
	calr RhythmDrum_LoadVoiceParams
	calr DrumParam_BuildActiveMask
	ret

DrumParam_ReadMaxCount:
	calr Rhythm_MapChannelToDrumIndex
	ld xhl, xbc
	add xhl, 0x37AB
	ld l, (xhl)
	mul bc, 0xA
	ld xwa, 0xE4A1D4
	add xwa, xbc
	ld_srib3 W, 0x03, 0xE0, 0xEC
	dec 1, w
	ret

ExtVoice_ProcessList:
	ret
	push	xiz
	call	16151804
	pop	xiz
	ret
	.byte 0xf1, 0x1e, 0x04, 0xca
	jr	nz, 13
	.byte 0xc1, 0xcd, 0x34, 0x3e, 0x80
	call	16069345
	call	16095947
	ret
	push	xiz
	call	16151831
	pop	xiz
	ret
	call	16095929
	calr	80
	call	16069345
	.byte 0xc1, 0xc9, 0x37, 0x04
	calr	78
	calr	115
	stdi8	32578, 0
	calr	113
	cpdi8	32578, 0
	jr	z, 11
	.byte 0x1d
	and	(xhl-15883), xwa
	.byte 0x37, 0x3e, 0x7f
	jr	5
	stdi8	14280, 0
	.byte 0xf1, 0xc9, 0x37, 0x04, 0xc1, 0xcd, 0x34, 0x3e, 0x80
	call	16069345
	cpdi8	32578, 0
	jr	nz, 6
	call	16095947
	jr	3
	calr	1
	ret
	call	16144626
	ret
	.byte 0xf1, 0x1e, 0x04, 0xca
	jr	z, 2
	jr	-8
	ret
	stdi8	14281, 1
	calr	-1216
	ld	xwa, 14282
	add	xwa, xbc
	ld	a, (xwa)
	cpda8	a, 13529
	jr	z, 16
	stdi8	14280, 127
	stda8	13529, a
	calr	-325
	stda8	13528, a
	ret
	stdi8	13527, 3
	ret
	.byte 0xf1, 0xc8, 0x37, 0xcb
	jr	z, 27
	stdi8	14281, 8
	calr	150
	calr	-1271
	ld	xix, 14458
	.byte 0xc3, 0x07, 0xf0, 0xe4, 0x3f, 0x00
	jr	nz, 3
	calr	337
	.byte 0xf1, 0xc8, 0x37, 0xcc
	jr	z, 27
	stdi8	14281, 16
	calr	117
	calr	-1304
	ld	xix, 14458
	.byte 0xc3, 0x07, 0xf0, 0xe4, 0x3f, 0x00
	jr	nz, 3
	calr	304
	.byte 0xf1, 0xc8, 0x37, 0xcd
	jr	z, 27
	stdi8	14281, 32
	calr	84
	calr	-1337
	ld	xix, 14458
	.byte 0xc3, 0x07, 0xf0, 0xe4, 0x3f, 0x00
	jr	nz, 3
	calr	271
	.byte 0xf1, 0xc8, 0x37, 0xce
	jr	z, 27
	stdi8	14281, 64
	calr	51
	calr	-1370
	ld	xix, 14458
	.byte 0xc3, 0x07, 0xf0, 0xe4, 0x3f, 0x00
	jr	nz, 3
	calr	238
	.byte 0xf1, 0xc8, 0x37, 0xc8
	jr	nz, 14
	.byte 0xf1, 0xc8, 0x37, 0xc9
	jr	nz, 8
	.byte 0xf1, 0xc8, 0x37, 0xca
	jr	nz, 2
	jr	11
	stdi8	14281, 1
	calr	4
	calr	828
	ret

AccVoice_SetupStyleSlots:
	calr __pad_F676E6
	calr DrumChannel_MapToIndexB
	sll xbc, 1
	add xix, xbc
	ld hl, (xix)
	pushw hl
	calr AccPatch_ResolveEntryAddr
	push xwa
	add xwa, 0x3
	ld hl, (xwa)
	ldw (xwa), 0xFFFF
	pop xwa
	pushw hl
	calr Voice_ClearSlotBuffer
	calr __pad_F676C1
	popw hl

AccVoice_SetupSlots_Loop:
	cp hl, 0xFFFF
	jr z, AccVoice_SetupSlots_InitEntry
	calr AccPatch_ResolveEntryAddr
	push xwa
	add xwa, 0x3
	ld hl, (xwa)
	ldw (xwa), 0xFFFF
	pop xwa
	push xwa
	add xwa, 0x1
	ldw (xwa), 0xFFFF
	pop xwa
	push xwa
	andmi8 (xwa), 0x7F
	pop xwa
	pushw hl
	calr Voice_ClearSlotBuffer
	popw hl
	incdi16 1, 13524
	jr AccVoice_SetupSlots_Loop

AccVoice_SetupSlots_InitEntry:
	popw hl
	ret

Voice_ClearSlotBuffer:
	add xwa, 0x6
	ld xix, xwa
	ld xbc, 0xF9

AccVoice_SetupSlots_StoreEntry:
	cps bc, 0
	jr z, AccVoice_SetupSlots_Return
	ldb a, 0x0
	ld (xix), a
	inc 1, xix
	dec 1, bc
	jr AccVoice_SetupSlots_StoreEntry

AccVoice_SetupSlots_Return:
	ret

__pad_F676C1:
	add xwa, 0x6
	lds32 xbc, 0
	ldda8 c, 13527
	inc 1, c
	mul_sd16b 3, 0xD9, 0x34

AccVoice_SetupSlots_CheckType:
	cps bc, 0
	jr z, AccVoice_SetupSlots_Done
	ldb e, 0x81
	ld (xwa), e
	inc 1, xwa
	dec 1, bc
	jr AccVoice_SetupSlots_CheckType

AccVoice_SetupSlots_Done:
	ldb c, 0x83
	ld (xwa), c
	ret

__pad_F676E6:
	lds32 xhl, 0
	ldda8 l, 13526
	cp l, 0x1E
	jr lt, AccVoice_SetupSlots_Write
	ldb l, 0x0

AccVoice_SetupSlots_Write:
	mul l, 0x60
	add hl, 0x60
	ld xix, 0x94800
	add xix, xhl
	ret

AccVoice_SetupSlots_WriteDone:
	.byte 0x00, 0x00

AccPatch_ResolveEntryAddr:
	push xix
	pushw hl
	pushw hl
	lds32 xhl, 0
	popw hl
	sll xhl, 8
	ld xwa, 0x95C00
	add xwa, xhl
	popw hl
	pop xix
	ret

AccVoice_SetupSlots_DataBlock:
	calr	-1627
	add	xbc, 14258
	ld	a, (xbc)
	cps	a, 0
	jr	z, 9
	calr	7
	calr	43
	calr	65
	ret
	calr	-1652
	sll	xbc, 3
	add	xbc, 14289
	ld	xiy, xbc
	calr	-91
	push	xix
	calr	-1058
	pop	xix
	sll	bc, 3
	add	bc, 24
	add	xix, xbc
	ld	xbc, 8
	ldir85
	ret
	calr	-116
	calr	-1013
	sll	bc, 1
	.byte 0xd3, 0x07, 0xf0, 0xe4, 0x23
	stda16	13842, hl
	stdi16	13844, 6
	ret
	ldb	c, 0
	stda8	14545, c
	ldda8	c, 13527
	inc	1, c
	cpda8	c, 14545
	jr	le, 19
	push c
	calr	18
	pop c
	ldda8	a, 14545
	inc	1, a
	stda8	14545, a
	jr	-25
	calr	466
	ret
	calr	52
	push	xwa
	calr	-1761
	pop	xwa
	sll	xbc, 2
	add	xbc, 14488
	ld	(xbc), xwa
	ldb	a, 0
	stda8	14544, a
	ldda8	c, 13529
	cpdm8	14544, c
	jr	ge, 19
	push c
	calr	41
	ldda8	a, 14544
	inc	1, a
	stda8	14544, a
	pop c
	jr	-25
	ret
	calr	-1812
	sll	xbc, 4
	add	xbc, 14346
	lds32	xwa, 0
	ldda8	a, 14545
	sll	xwa, 2
	add	xbc, xwa
	ld	xwa, (xbc)
	ret
	calr	53
	cp	a, 131
	jr	nz, 30
	calr	-1846
	sll	bc, 2
	add	xbc, 14488
	ld	xwa, 16152605
	ld	(xbc), xwa
	push	xbc
	lds32	xbc, 1
	calr	110
	pop	xbc
	ldb	a, 129
	jr	5
	.byte 0x14
	calr	101
	.byte 0x15
	cp	a, 129
	jr	z, 2
	jr	-50
	ret
	cp	(xbc), l
	swi	7
	swi	7
	swi	7
	calr	-1894
	sll	xbc, 2
	add	xbc, 14488
	ld	xwa, (xbc)
	cp	xwa, 16152605
	jr	z, 4
	ld	a, (xwa)
	jr	2
	ldb	a, 131
	ret
	ldb	c, 0
	cp	a, 144
	jr	nz, 4
	ldb	c, 6
	jr	46
	cp	a, 145
	jr	nz, 4
	ldb	c, 8
	jr	37
	cp	a, 129
	jr	nz, 4
	ldb	c, 1
	jr	28
	cp	a, 131
	jr	nz, 4
	ldb	c, 1
	jr	19
	ld	w, a
	and	w, 208
	cp	w, 208
	jr	nz, 4
	ldb	c, 3
	jr	5
	cps	c, 0
	jr	nz, 1
	nop
	ret
	calr	-1981
	sll	xbc, 2
	add	xbc, 14488
	ld	xiy, (xbc)
	ld	a, (xiy)
	lds32	xbc, 0
	calr	-79
	ldda16	hl, 13842
	pushw	bc
	calr	-402
	popw	bc
	ld	xix, xwa
	lds32	xwa, 0
	ldda16	wa, 13844
	add	xix, xwa
	ldw	de, 255
	.byte 0xd1, 0x14, 0x36, 0xa2
	cp	bc, de
	jr	gt, 12
	.byte 0xd1, 0x14, 0x36, 0x89
	cps	bc, 0
	jr	z, 2
	ldir85
	jr	60
	pushw	bc
	ld	bc, de
	.byte 0xd1, 0x14, 0x36, 0x89
	cps	bc, 0
	jr	z, 2
	ldir85
	popw	bc
	push	xiy
	sub	bc, de
	stda16	13373, bc
	stda16	13375, de
	calr	64
	ldda16	hl, 13842
	calr	-471
	ld	xix, xwa
	lds32	xwa, 0
	ldda16	wa, 13844
	add	xix, xwa
	pop	xiy
	ldda16	bc, 13373
	.byte 0xd1, 0x14, 0x36, 0x89
	cps	bc, 0
	jr	z, 2
	ldir85
	push	xiy
	calr	-2105
	sll	xbc, 2
	add	xbc, 14488
	pop	xiy
	ld	(xbc), xiy
	cp	xiy, 16152606
	jr	nz, 7
	ld	xiy, 16152605
	ld	(xbc), xiy
	ret
	cpdi16	13524, 0
	jr	z, 66
	ldw	hl, 150
	pushw	hl
	calr	-543
	popw	hl
	.byte 0xb0, 0xcf
	jr	z, 4
	inc	1, hl
	jr	-13
	ld	c, (xwa)
	or	c, 128
	ld	(xwa), c
	lds	de, 1
	ldda16	bc, 13842
	.byte 0xf3, 0x07, 0xe0, 0xe8, 0x51
	pushw	hl
	ldda16	hl, 13842
	calr	-578
	lds	de, 3
	popw	hl
	.byte 0xf3, 0x07, 0xe0, 0xe8, 0x53
	decdi16	1, 13524
	stda16	13842, hl
	lds	wa, 6
	stda16	13844, wa
	jr	11
	lds	wa, 6
	stda16	13844, wa
	stdi8	32578, 15
	ret
	calr	-2222
	sll	bc, 2
	add	xbc, 14488
	ld	xwa, 16152963
	ld	(xbc), xwa
	ldb	c, 1
	calr	-265
	ret
	ld	a, (xhl)
	.byte 0x01
	stda8	14281, a
	calr	-605
	calr	7
	calr	-572
	calr	124
	ret
	calr	-692
	ldda8	w, 13528
	ldb	a, 12
	.byte 0xf3, 0x03, 0xf0, 0xe0, 0x40
	ldda8	w, 13527
	ldb	a, 13
	.byte 0xf3, 0x03, 0xf0, 0xe0
	.ascii "@  !"
	ret
	.byte 0xf3, 0x03, 0xf0, 0xe0, 0x40
	ldb	w, 0
	ldb	a, 15
	.byte 0xf3, 0x03, 0xf0, 0xe0, 0x40
	ldb	a, 1
	.byte 0xf1, 0xc9, 0x37, 0x41
	push xix
	.byte 0x1e, 0xf3, 0xf6
	pop xix
	ld	xiy, 14546
	.byte 0xc3, 0x03, 0xf4, 0xe4, 0x20
	ldb	a, 16
	.byte 0xf3, 0x03, 0xf0, 0xe0, 0x40
	ld	xiy, 14553
	.byte 0xc3, 0x03, 0xf4, 0xe4, 0x20
	ldb	a, 17
	.byte 0xf3, 0x03, 0xf0, 0xe0, 0x40
	ld	xiy, 16153090
	add	xix, 64
	lds32	xbc, 0
	ldw	bc, 16
	ldir85
	ret
	aligned_string "Easy            #"
	.byte 0xf1, 0xd1, 0x38, 0x43, 0xc1, 0xd7, 0x34, 0x23
	add	c, 1
	.byte 0xc1, 0xd1, 0x38, 0xf3, 0x62, 0x13
	push c
	.byte 0x1e, 0x12, 0x00
	pop c
	.byte 0xc1, 0xd1, 0x38, 0x21
	inc	1, a
	.byte 0xf1, 0xd1, 0x38, 0x41, 0x68, 0xe7, 0x1e, 0x2f
	.byte 0xff
	ret
	ldb	a, 1
	.byte 0xf1, 0xc9, 0x37, 0x41, 0x1e, 0x8b, 0xfd
	push xwa
	.byte 0x1e, 0x76, 0xf6
	pop xwa
	sll	xbc, 2
	add	xbc, 14488
	ld	(xbc), xwa
	ldb	a, 2
	.byte 0xf1, 0xc9, 0x37, 0x41, 0x1e, 0x72, 0xfd
	push xwa
	.byte 0x1e, 0x5d, 0xf6
	pop xwa
	sll	xbc, 2
	add	xbc, 14488
	ld	(xbc), xwa
	ldb	a, 4
	.byte 0xf1, 0xc9, 0x37, 0x41, 0x1e, 0x59, 0xfd
	push xwa
	.byte 0x1e, 0x44, 0xf6
	pop xwa
	sll	xbc, 2
	add	xbc, 14488
	ld	(xbc), xwa
	ldb	a, 0
	.byte 0xf1, 0xd0, 0x38, 0x41, 0xc1, 0xd9, 0x34, 0x23
	.byte 0xc1, 0xd0, 0x38, 0xfb, 0x69, 0x13
	push c
	.byte 0x1e, 0x0f, 0x00, 0xc1, 0xd0, 0x38, 0x21
	inc	1, a
	.byte 0xf1, 0xd0, 0x38, 0x41
	pop c
	.byte 0x68, 0xe7
	ret
	ldb	a, 1
	.byte 0xf1, 0xc9, 0x37, 0x41, 0x1e, 0x7b, 0x00
	ldb	a, 2
	.byte 0xf1, 0xc9, 0x37, 0x41, 0x1e, 0x72, 0x00
	ldb	a, 4
	.byte 0xf1, 0xc9, 0x37, 0x41, 0x1e, 0x69, 0x00, 0x1e
	.byte 0x49, 0x01
	push l
	.byte 0x1e, 0xa8, 0x00
	pop l
	cps	w, 0
	.byte 0x66, 0x0d, 0x1e, 0xe0, 0x00, 0xf1, 0xc9, 0x37
	.byte 0x47, 0x1e, 0x9b, 0xfd, 0x78, 0xca, 0xff
	ldb	a, 1
	.byte 0xf1, 0xc9, 0x37, 0x41
	lds32	xbc, 0
	ldb	c, 1
	.byte 0x1e, 0x8b, 0xfd
	ldb	a, 2
	.byte 0xf1, 0xc9, 0x37, 0x41, 0x1e, 0xc8, 0xf5
	sll	xbc, 2
	add	xbc, 14488
	ld	xwa, (xbc)
	cp	xwa, 16152605
	.byte 0x66, 0x04
	inc	1, xwa
	ld	(xbc), xwa
	ldb	a, 4
	.byte 0xf1, 0xc9, 0x37, 0x41, 0x1e, 0xa8, 0xf5
	sll	xbc, 2
	add	xbc, 14488
	ld	xwa, (xbc)
	cp	xwa, 16152605
	.byte 0x66, 0x04
	inc	1, xwa
	ld	(xbc), xwa
	ret
	.byte 0x1e, 0x8d, 0xf5
	add	xbc, 14258
	ld	a, (xbc)
	cps	a, 0
	.byte 0x66, 0x21, 0x1e, 0x13, 0x01, 0x1e, 0x7b, 0xf5
	sll	xbc, 2
	add	xbc, 14488
	ld	xwa, (xbc)
	ld	l, (xwa)
	cp	l, 131
	.byte 0x6e, 0x07
	ld	xwa, 16152605
	ld	(xbc), xwa
	.byte 0x68, 0x13, 0x1e, 0x5d, 0xf5
	sll	xbc, 2
	add	xbc, 14488
	ld	xwa, 16152605
	ld	(xbc), xwa
	.byte 0x1e, 0x5c, 0x00
	ret
	ldb	a, 1
	.byte 0xf1, 0xc9, 0x37, 0x41, 0x1e, 0x28, 0x00
	cp	a, 129
	.byte 0x6e, 0x20
	ldb	a, 2
	.byte 0xf1, 0xc9, 0x37, 0x41, 0x1e, 0x1a, 0x00
	cp	a, 129
	.byte 0x6e, 0x12
	ldb	a, 4
	.byte 0xf1, 0xc9, 0x37, 0x41, 0x1e, 0x0c, 0x00
	cp	a, 129
	.byte 0x6e, 0x04
	ldb	w, 0
	.byte 0x68, 0x02
	ldb	w, 1
	ret
	ld	xix, 13357
	push xix
	.byte 0x1e, 0x0f, 0xf5
	pop xix
	.byte 0xc3, 0x03, 0xf0, 0xe4, 0x21
	ret
	push l
	lds32	xhl, 0
	pop l
	and	l, 7
	add	xhl, 16153545
	ld	l, (xhl)
	ret
	.byte 0x01
	push_sr
	.byte 0x04, 0x08, 0x10, 0x20
	ld	xwa, 4109049408
	push xbc
	add	xbc, 13357
	ld	xix, xbc
	pop xbc
	sll	xbc, 2
	add	xbc, 14488
	ld	xwa, (xbc)
	ld	a, (xwa)
	cp	a, 144
	.byte 0x66, 0x19
	cp	a, 145
	.byte 0x66, 0x14
	ld	w, a
	and	w, 240
	cp	w, 208
	.byte 0x66, 0x0a
	ld	(xix), a
	cp	a, 135
	.byte 0x6e, 0x01
	nop
	.byte 0x68, 0x08
	ld	xwa, (xbc)
	inc	1, xwa
	ld	a, (xwa)
	ld	(xix), a
	ret
	ldb	l, 0
	ldb	a, 0
	ld	xix, 13357
	cps	l, 2
	.byte 0x6a, 0x2e
	cps	a, 2
	.byte 0x6a, 0x2a, 0xc3, 0x03, 0xf0, 0xec, 0x26
	bit	7, h
	.byte 0x66, 0x04
	inc	1, l
	.byte 0x68, 0x1a, 0xc3, 0x03, 0xf0, 0xe0, 0x20
	bit	7, w
	.byte 0x66, 0x04
	inc	1, a
	.byte 0x68, 0x0c
	cp	h, w
	.byte 0x6a, 0x04
	inc	1, a
	.byte 0x68, 0x04
	inc	1, l
	.byte 0x68, 0x00, 0x68, 0xce
	cps	l, 2
	.byte 0x62, 0x02
	ldb	l, 0
	ret
	.byte 0x1e, 0x68, 0xf4
	ld	ix, bc
	sll	xbc, 2
	add	xbc, 14488
	ld	xwa, (xbc)
	ld	a, (xwa)
	cp	a, 144
	.byte 0x66, 0x11
	cp	a, 145
	.byte 0x66, 0x0c
	ld	e, a
	and	a, 240
	cp	a, 208
	.byte 0x66, 0x02, 0x68, 0x26
	ld	xwa, (xbc)
	inc	2, xwa
	ld	a, (xwa)
	.byte 0x1e, 0x1e, 0x00, 0xc1, 0xc9, 0x37, 0xf3, 0x66
	.byte 0x17, 0x1e, 0x31, 0xf4
	sll	xbc, 2
	add	xbc, 14488
	ld	xix, (xbc)
	push xbc
	.byte 0x1e, 0x2a, 0x00
	pop xbc
	ld	(xbc), xix
	.byte 0x68, 0xc0
	ret
	push_a
	.byte 0x1e, 0x18, 0xf4
	ld	xwa, 14465
	.byte 0xc3, 0x07, 0xe0, 0xe4, 0x25
	push e
	lds32	xde, 0
	pop e
	sll	de, 7
	add	xde, 14990578
	pop_a
	.byte 0xc3, 0x03, 0xe8, 0xe0, 0x23
	ret
	ld	a, (xix)
	.byte 0x1e, 0x73, 0xfb
	push c
	lds32	xbc, 0
	pop c
	add	xix, xbc
	ret

VoiceSlot_InitFromTable:
	push xiz
	call VoiceSlot_Init_CheckType
	pop xiz
	ret

VoiceSlot_Init_CheckType:
	calr VoiceSlot_Init_Process
	calr AccVoice_SetupStyleSlots
	ret

VoiceSlot_Init_Process:
	stdi8 14281, 16
	bitda 0, 14235
	jr nz, CmpMode_NullRet
	stdi8 14281, 32
	bitda 1, 14235
	jr nz, CmpMode_NullRet
	stdi8 14281, 64
	bitda 2, 14235
	jr nz, CmpMode_NullRet
	stdi8 14281, 8
	bitda 3, 14235
	jr nz, CmpMode_NullRet
	stdi8 14281, 1

CmpMode_NullRet:
	ret

__pad_F67D15:
	push	xiz
	call	16153884
	pop	xiz
	ret
	ldda8	e, 14281
	and	e, 1
	cps	e, 1
	jr	z, 70
	ldda8	e, 14281
	and	e, 2
	cps	e, 2
	jr	z, 66
	ldda8	e, 14281
	and	e, 4
	cps	e, 4
	jr	z, 48
	ldda8	e, 14281
	and	e, 8
	cp	e, 8
	jr	z, 57
	ldda8	e, 14281
	and	e, 16
	cp	e, 16
	jr	z, 52
	ldda8	e, 14281
	and	e, 32
	cp	e, 32
	jr	z, 47
	ldda8	e, 14281
	and	e, 64
	cp	e, 64
	jr	z, 42
	stdi8	14776, 0
	jr	42
	stdi8	14776, 1
	jr	35
	stdi8	14776, 2
	jr	28
	stdi8	14776, 3
	jr	21
	stdi8	14776, 4
	jr	14
	stdi8	14776, 5
	jr	7
	stdi8	14776, 6
	jr	0
	ret
; CmpMenuTtlFunc setup
CmpMenuTtl_Setup:
CmpModeFunc:
	cp xbc, 0x1C00013
	jr nz, DrumKitExit_ReturnZero
	cp xde, 0x1
	jr z, CmpMenuTtl_InitTitle
	or xde, xde
	jr nz, DrumKitExit_ReturnZero
	push xde
	push xhl
	push xix
	push xiz
	call DrumKitInit_Wrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	jr DrumKitExit_ReturnZero

; CmpMenuTtlFunc init title
CmpMenuTtl_InitTitle:
	push xde
	push xhl
	push xix
	push xiz
	call DrumKitExit_Wrapper
	pop xiz
	pop xix
	pop xhl
	pop xde

DrumKitExit_ReturnZero:
	lds32 xhl, 0
	ret
; CmpMenuTtlFunc main handler
CmpMenuTtl_MainHandler:
CmpMenuTtlFunc:
	cp xbc, 0x1C00007
	jr z, CmpMenuTtl_SpecialKeys
	cp xbc, 0x1C00013
	jr nz, CmpMenuTtl_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jr c, CmpMenuTtl_ReturnZero
	cp xde, 0x6
	jr ugt, CmpMenuTtl_ReturnZero
	add xde, xde
	add xde, 0xE4BE72
	ld de, (xde)
	lda_24 xix, 0xf67e06
	jp_dri 8, 0x07, 0xF0, 0xE8
; CmpMenuTtlFunc title dispatch
CmpMenuTtl_Dispatch:
	.byte 0xf1, 0xa7, 0x28, 0xba
	call	16095929
	jr	t, 0x46

; CmpMenuTtl special key handler (0x88-0x8A)
CmpMenuTtl_SpecialKeys:
	ldda8 a, 13517
	cp xde, 0x8A
	jr z, CmpMenuTtl_SetBit4
	cp xde, 0x89
	jr z, CmpMenuTtl_SetBit5
	cp xde, 0x88
	jr nz, CmpMenuTtl_ReturnZero
	anddi8 13517, 207
	ldw wa, 0xB1
	jr CmpMenuTtl_PostModeEvent

; CmpMenuTtl set mode bit 5
CmpMenuTtl_SetBit5:
	and a, 0xCF
	set 5, a
	stda8 13517, a
	ldw wa, 0xB1
	jr CmpMenuTtl_PostModeEvent

; CmpMenuTtl set mode bit 4
CmpMenuTtl_SetBit4:
	and a, 0xCF
	set 4, a
	stda8 13517, a
	ldw wa, 0xB1

; CmpMenuTtl post mode change event
CmpMenuTtl_PostModeEvent:
	call UI_PostModeChangeEvent

CmpMenuTtl_ReturnZero:
	lds32 xhl, 0
	ret
; CmpSetTtlFunc main handler
CmpSetTtl_MainHandler:
CmpSetTtlFunc:
	cp xbc, 0x1C00007
	jr z, CmpSetTtl_ModeSwitch
	cp xbc, 0x1C00013
	jrl nz, CmpReal_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, CmpReal_ReturnZero
	cp xde, 0x6
	jrl ugt, CmpReal_ReturnZero
	add xde, xde
	add xde, 0xE4BE98
	ld de, (xde)
	lda_24 xix, 0xf67e92
	jp_dri 8, 0x07, 0xF0, 0xE8
; CmpSetTtlFunc title dispatch
CmpSetTtl_Dispatch:
	cpdi8	36151, 180
	jrl	z, 337
	call	16142860
	ld	xwa, 11796487
	ld	xbc, 31457422
	ld	xde, 4294901761
	call	16424455
	jrl	311
	cpdi8	36150, 180
	jrl	z, 303
	call	16142906
	jrl	296

; CmpSetTtl mode switch (5-way branch)
CmpSetTtl_ModeSwitch:
	cpdi8 13580, 0
	jrl nz, CmpSetTtl_SecondaryDispatch
	cp xde, 0x85
	jr z, CmpSetTtl_DrumVoice1
	cp xde, 0x84
	jr z, CmpSetTtl_DrumVoice1
	cp xde, 0x5
	jr z, CmpSetTtl_DrumVoice0
	cp xde, 0x4
	jr z, CmpSetTtl_DrumVoice0
	cp xde, 0x82
	jr z, VoiceSlot_Resolve_StoreMap
	cp xde, 0x81
	jr z, VoiceSlot_Resolve_StoreMap
	cp xde, 0x2
	jr z, VoiceSlot_ResolveFromMap
	cp xde, 0x1
	jrl nz, CmpReal_ReturnZero

VoiceSlot_ResolveFromMap:
	push xde
	push xhl
	push xix
	push xiz
	ldb w, 0x0
	call DrumTempo_Adjust
	pop xiz
	pop xix
	pop xhl
	pop xde
	jrl CmpReal_ReturnZero

VoiceSlot_Resolve_StoreMap:
	push xde
	push xhl
	push xix
	push xiz
	ldb w, 0x80
	call DrumTempo_Adjust
	pop xiz
	pop xix
	pop xhl
	pop xde
	jrl CmpReal_ReturnZero

; CmpSetTtl drum voice select (w=0)
CmpSetTtl_DrumVoice0:
	push xde
	push xhl
	push xix
	push xiz
	ldb w, 0x0
	call DrumVoice_Select
	pop xiz
	pop xix
	pop xhl
	pop xde
	jrl CmpReal_ReturnZero

; CmpSetTtl drum voice select (w=0x80)
CmpSetTtl_DrumVoice1:
	push xde
	push xhl
	push xix
	push xiz
	ldb w, 0x80
	call DrumVoice_Select
	pop xiz
	pop xix
	pop xhl
	pop xde
	jrl CmpReal_ReturnZero

; CmpSetTtl secondary dispatch
CmpSetTtl_SecondaryDispatch:
	dec 1, xde
	cp xde, 0x0
	jrl c, CmpReal_ReturnZero
	cp xde, 0x5
	jr ule, CmpSetTtl_DynamicLookup
	sub xde, 0x7A
	cp xde, 0x6
	jr c, CmpReal_ReturnZero
	cp xde, 0xB
	jr ugt, CmpReal_ReturnZero

; CmpSetTtl dynamic table lookup
CmpSetTtl_DynamicLookup:
	add xde, xde
	add xde, 0xE4BE80
	ld de, (xde)
	lda_24 xix, 0xf67f8d
	jp_dri 8, 0x07, 0xF0, 0xE8
; CmpSetTtlFunc title dispatch 2
CmpSetTtl_Dispatch2:
	.asciz ":;<> "
	.byte 0x1d, 0x4c
	jr	lt, 0xf6
	.ascii "^\\[ZhN:;<> "
	.byte 0x80, 0x1d
	popw ix
	jr	lt, 0xf6
	.asciz "^\\[Zh>:;<> "
	.byte 0x1d, 0x6f
	jr	lt, 0xf6
	.ascii "^\\[Zh.:;<> "
	.byte 0x80, 0x1d, 0x6f
	jr	lt, 0xf6
	.ascii "^\\[Zh"
	.byte 0x1e
	.asciz ":;<> "
	.byte 0x1d, 0xad
	jr	lt, 0xf6
	.ascii "^\\[Zh"
	.byte 0x0e
	.ascii ":;<> "
	.byte 0x80, 0x1d, 0xad
	jr	lt, 0xf6
	.ascii "^\\[Z"

CmpReal_ReturnZero:
	lds32 xhl, 0
	ret
; CmpRealTtlFunc entry
CmpRealTtl_Entry:
CmpRealTtlFunc:
	cp xbc, 0x1C00007
	jr z, CmpRealTtl_MajorDispatch
	cp xbc, 0x1C00013
	jrl nz, CmpBk_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, CmpBk_ReturnZero
	cp xde, 0x6
	jrl ugt, CmpBk_ReturnZero
	add xde, xde
	add xde, 0xE4BEC0
	ld de, (xde)
	lda_24 xix, 0xf68027
	jp_dri 8, 0x07, 0xF0, 0xE8
; CmpRealTtlFunc title dispatch
CmpRealTtl_Dispatch:
	.ascii ":;<>"
	.byte 0x1d, 0x55, 0x4f, 0xf6
	.byte 0x5e, 0x5c, 0x5b, 0x5a
	.byte 0x1e, 0x43, 0x1c, 0x78
	.byte 0xa6, 0x02
	.byte 0x3a, 0x3b, 0x3c, 0x3e
	.byte 0x1d, 0x55
	.byte 0x4f, 0xf6
	.ascii "^\\[Zx—"
	.byte 0x02

; CmpRealTtl major dispatch (5-way)
CmpRealTtl_MajorDispatch:
	ld xwa, xde
	cp xde, 0x84
	jrl z, CmpRealTtl_RhythmVar4
	cp xde, 0x83
	jrl z, CmpRealTtl_RhythmVar3
	cp xde, 0x82
	jrl z, CmpRealTtl_RhythmVar2
	cp xde, 0x81
	jrl z, CmpRealTtl_RhythmVar1
	cp xde, 0x80
	jr z, CmpRealTtl_RhythmVar0
	cp xwa, 0xC
	jrl ugt, CmpBk_ReturnZero
	add xwa, xwa
	add xwa, 0xE4BEA6
	ld wa, (xwa)
	lda_24 xix, 0xf68093
	jp_dri 8, 0x07, 0xF0, 0xE0

; CmpRealTtl rhythm variation 0
CmpRealTtl_RhythmVar0:
	push xde
	push xhl
	push xix
	push xiz
	lds hl, 0
	call RhythmVariation_Wrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld xwa, 0xB50019
	ld xbc, 0x1C0000B
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB5001B
	ld xbc, 0x1C0000B
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB5001A
	ld xbc, 0x1C0000B
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB50018
	ld xbc, 0x1C0000B
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB5001C
	ld xbc, 0x1C0000B
	lds32 xde, 0
	jrl CmpBk_DeliverEvent

; CmpRealTtl rhythm variation 1
CmpRealTtl_RhythmVar1:
	push xde
	push xhl
	push xix
	push xiz
	lds hl, 1
	call RhythmVariation_Wrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld xwa, 0xB50019
	ld xbc, 0x1C0000B
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB5001B
	ld xbc, 0x1C0000B
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB5001A
	ld xbc, 0x1C0000B
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB50018
	ld xbc, 0x1C0000B
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB5001C
	ld xbc, 0x1C0000B
	lds32 xde, 0
	jrl CmpBk_DeliverEvent

; CmpRealTtl rhythm variation 2
CmpRealTtl_RhythmVar2:
	push xde
	push xhl
	push xix
	push xiz
	lds hl, 2
	call RhythmVariation_Wrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld xwa, 0xB50019
	ld xbc, 0x1C0000B
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB5001B
	ld xbc, 0x1C0000B
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB5001A
	ld xbc, 0x1C0000B
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB50018
	ld xbc, 0x1C0000B
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB5001C
	ld xbc, 0x1C0000B
	lds32 xde, 0
	jrl CmpBk_DeliverEvent

; CmpRealTtl rhythm variation 3
CmpRealTtl_RhythmVar3:
	push xde
	push xhl
	push xix
	push xiz
	lds hl, 3
	call RhythmVariation_Wrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld xwa, 0xB50019
	ld xbc, 0x1C0000B
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB5001B
	ld xbc, 0x1C0000B
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB5001A
	ld xbc, 0x1C0000B
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB50018
	ld xbc, 0x1C0000B
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB5001C
	ld xbc, 0x1C0000B
	lds32 xde, 0
	jrl CmpBk_DeliverEvent

; CmpRealTtl rhythm variation 4
CmpRealTtl_RhythmVar4:
	push xde
	push xhl
	push xix
	push xiz
	lds hl, 4
	call RhythmVariation_Wrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld xwa, 0xB50019
	ld xbc, 0x1C0000B
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB5001B
	ld xbc, 0x1C0000B
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB5001A
	ld xbc, 0x1C0000B
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB50018
	ld xbc, 0x1C0000B
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB5001C
	ld xbc, 0x1C0000B
	lds32 xde, 0
	jr CmpBk_DeliverEvent
	setda 1, 13519
	jr CmpBk_ReturnZero
	push xde
	push xhl
	push xix
	push xiz
	call RhythmMute_Wrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld xwa, 0xB5001D
	ld xbc, 0x1C0000B
	lds32 xde, 0
	jr CmpBk_DeliverEvent
	push xde
	push xhl
	push xix
	push xiz
	call RhythmSolo_Wrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld xwa, 0xB50019
	ld xbc, 0x1C0000B
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB5001B
	ld xbc, 0x1C0000B
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB5001A
	ld xbc, 0x1C0000B
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB50018
	ld xbc, 0x1C0000B
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB5001C
	ld xbc, 0x1C0000B
	lds32 xde, 0

CmpBk_DeliverEvent:
	call ApDeliveryEvent

CmpBk_ReturnZero:
	lds32 xhl, 0
	ret
; CmpOffsetFunc dispatch
CmpOffset_Dispatch:
CmpBkslTtlFunc:
	cp xbc, 0x1C00007
	jr z, CmpBkslTtl_Mode1
	cp xbc, 0x1C00013
	jrl nz, CmpBksl_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, CmpBksl_ReturnZero
	cp xde, 0x6
	jrl ugt, CmpBksl_ReturnZero
	add xde, xde
	add xde, 0xE4BECE
	ld de, (xde)
	lda_24 xix, 0xf6831b
	jp_dri 8, 0x07, 0xF0, 0xE8
; CmpBkslTtlFunc title dispatch
CmpBkslTtl_Dispatch:
	.ascii ":;<>"
	.byte 0x1d, 0xa7, 0x4c, 0xf6
	.ascii "^\\[Zx."
	.byte 0x01, 0x3a
	.byte 0x3b, 0x3c, 0x3e, 0x1d, 0xa7, 0x4c, 0xf6, 0x5e
	.ascii "\\[Zx"
	.byte 0x1f, 0x01

; CmpBkslTtl mode 1
CmpBkslTtl_Mode1:
	cp xde, 0x8C
	jrl z, CmpBkslTtl_ModeDefault
	cp xde, 0xC
	jrl z, CmpBkslTtl_ModeSelect
	cp xde, 0x8B
	jrl z, DrumSlot_Dispatch_Slot6
	cp xde, 0xB
	jrl z, DrumSlot_Dispatch_Slot7
	cp xde, 0x8A
	jrl z, DrumSlot_Dispatch_Slot4
	cp xde, 0xA
	jr z, DrumSlot_Dispatch_Slot5
	cp xde, 0x89
	jr z, DrumSlot_Dispatch_Slot2
	cp xde, 0x9
	jr z, DrumSlot_Dispatch_Slot3_WithMode
	cp xde, 0x88
	jr z, DrumSlot_Dispatch_Slot0
	cp xde, 0x8
	jrl nz, CmpBksl_ReturnZero
	push xde
	push xhl
	push xix
	push xiz
	lds hl, 1
	call DrumSlot_DispatchWrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw wa, 0xB2
	jrl CmpBksl_ApplyAndReturnZero

DrumSlot_Dispatch_Slot0:
	push xde
	push xhl
	push xix
	push xiz
	lds hl, 0
	call DrumSlot_DispatchWrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw wa, 0xB2
	jrl CmpBksl_ApplyAndReturnZero

DrumSlot_Dispatch_Slot3_WithMode:
	push xde
	push xhl
	push xix
	push xiz
	lds hl, 3
	call DrumSlot_DispatchWrapper
	ldw wa, 0xB2
	call UI_PostModeChangeEvent
	pop xiz
	pop xix
	pop xhl
	pop xde
	jrl CmpBksl_ReturnZero

DrumSlot_Dispatch_Slot2:
	push xde
	push xhl
	push xix
	push xiz
	lds hl, 2
	call DrumSlot_DispatchWrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw wa, 0xB2
	jr CmpBksl_ApplyAndReturnZero

DrumSlot_Dispatch_Slot5:
	push xde
	push xhl
	push xix
	push xiz
	lds hl, 5
	call DrumSlot_DispatchWrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw wa, 0xB2
	jr CmpBksl_ApplyAndReturnZero

DrumSlot_Dispatch_Slot4:
	push xde
	push xhl
	push xix
	push xiz
	lds hl, 4
	call DrumSlot_DispatchWrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw wa, 0xB2
	jr CmpBksl_ApplyAndReturnZero

DrumSlot_Dispatch_Slot7:
	push xde
	push xhl
	push xix
	push xiz
	lds hl, 7
	call DrumSlot_DispatchWrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw wa, 0xB2
	jr CmpBksl_ApplyAndReturnZero

DrumSlot_Dispatch_Slot6:
	push xde
	push xhl
	push xix
	push xiz
	lds hl, 6
	call DrumSlot_DispatchWrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw wa, 0xB2
	jr CmpBksl_ApplyAndReturnZero

; CmpBkslTtl mode select
CmpBkslTtl_ModeSelect:
	push xde
	push xhl
	push xix
	push xiz
	ldw hl, 0x9
	call DrumSlot_DispatchWrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw wa, 0xB2
	jr CmpBksl_ApplyAndReturnZero

; CmpBkslTtl mode default
CmpBkslTtl_ModeDefault:
	push xde
	push xhl
	push xix
	push xiz
	ldw hl, 0x8
	call DrumSlot_DispatchWrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw wa, 0xB2

CmpBksl_ApplyAndReturnZero:
	call UI_PostModeChangeEvent

CmpBksl_ReturnZero:
	lds32 xhl, 0
	ret
; CmpBksl_STtlFunc main handler
CmpBkslSTtl_MainHandler:
CmpBksl_STtlFunc:
	cp xbc, 0x1C00007
	jr z, CmpBkslSTtl_DirectMode
	cp xbc, 0x1C00013
	jrl nz, DisplayFunc_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, DisplayFunc_ReturnZero
	cp xde, 0x6
	jrl ugt, DisplayFunc_ReturnZero
	add xde, xde
	add xde, 0xE4BEF2
	ld de, (xde)
	lda_24 xix, 0xf68494
	jp_dri 8, 0x07, 0xF0, 0xE8
; CmpBksl_STtlFunc title dispatch
CmpBkslSTtl_Dispatch:
	.ascii ":;<>"
	call	16141798
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	stdi8	32578, 0
	jrl	334
	stdi8	13580, 0
	jrl	326
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	16141798
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jrl	t, 0x0137

; CmpBkslSTtl direct mode handler (0x80+)
CmpBkslSTtl_DirectMode:
	ld xwa, xde
	cp xde, 0x4
	jrl z, CmpBkslSTtl_FillIn8
	cp xde, 0x3
	jrl z, CmpBkslSTtl_FillIn7
	cp xde, 0x2
	jr z, CmpBkslSTtl_FillIn6
	cp xde, 0x1
	jr z, CmpBkslSTtl_FillIn5
	or xde, xde
	jr z, CmpBkslSTtl_FillIn4
	sub xwa, 0x80
	cp xwa, 0x0
	jrl c, DisplayFunc_ReturnZero
	cp xwa, 0xA
	jrl ugt, DisplayFunc_ReturnZero
	add xwa, xwa
	add xwa, 0xE4BEDC
	ld wa, (xwa)
	lda_24 xix, 0xf68513
	jp_dri 8, 0x07, 0xF0, 0xE0

; CmpBkslSTtl fill-in level 4
CmpBkslSTtl_FillIn4:
	cpdi8 13580, 0
	jrl nz, DisplayFunc_ReturnZero
	push xde
	push xhl
	push xix
	push xiz
	lds hl, 4
	call RhythmFillIn_Wrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw wa, 0xB5
	jrl CmpBk_PostModeChange

; CmpBkslSTtl fill-in level 5
CmpBkslSTtl_FillIn5:
	cpdi8 13580, 0
	jrl nz, DisplayFunc_ReturnZero
	push xde
	push xhl
	push xix
	push xiz
	lds hl, 5
	call RhythmFillIn_Wrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw wa, 0xB5
	jrl CmpBk_PostModeChange

; CmpBkslSTtl fill-in level 6
CmpBkslSTtl_FillIn6:
	cpdi8 13580, 0
	jrl nz, DisplayFunc_ReturnZero
	push xde
	push xhl
	push xix
	push xiz
	lds hl, 6
	call RhythmFillIn_Wrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw wa, 0xB5
	jrl CmpBk_PostModeChange

; CmpBkslSTtl fill-in level 7
CmpBkslSTtl_FillIn7:
	cpdi8 13580, 0
	jrl nz, DisplayFunc_ReturnZero
	push xde
	push xhl
	push xix
	push xiz
	lds hl, 7
	call RhythmFillIn_Wrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw wa, 0xB5
	jr CmpBk_PostModeChange

; CmpBkslSTtl fill-in level 8
CmpBkslSTtl_FillIn8:
	cpdi8 13580, 0
	jr nz, DisplayFunc_ReturnZero
	push xde
	push xhl
	push xix
	push xiz
	ldw hl, 0x8
	call RhythmFillIn_Wrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw wa, 0xB5
	jr CmpBk_PostModeChange
	cpdi8 13580, 0
	jr nz, DisplayFunc_ReturnZero
	cpi8_24 0x0340ea, 0x00
	jr nz, CmpBkslSTtl_EventPost
	setda 2, 13517
	stdi8 32578, 35
	ldw wa, 0xEE
	call SoundCtrl_SendCommand
	jr DisplayFunc_ReturnZero

; CmpBkslSTtl post accompaniment event
CmpBkslSTtl_EventPost:
	stdi8 13580, 1
	ld xwa, 0xB20012
	ld xbc, 0x1C00001
	lds32 xde, 5
	call ApPostEvent
	jr DisplayFunc_ReturnZero
	cpdi8 13580, 0
	jr nz, DisplayFunc_ReturnZero
	cpdi8 13526, 12
	jr nc, DisplayFunc_ReturnZero
	ldw wa, 0xB3
	jr CmpBk_PostModeChange
	cpdi8 13580, 0
	jr nz, DisplayFunc_ReturnZero
	ldw wa, 0xB4

CmpBk_PostModeChange:
	call UI_PostModeChangeEvent

DisplayFunc_ReturnZero:
	lds32 xhl, 0
	ret
; CmpNcpTtlFunc main handler
CmpNcpTtl_MainHandler:
CmpNcpTtlFunc:
	cp xbc, 0x1C00007
	jrl z, CmpNcpTtl_SpecialMode7
	cp xbc, 0x1C00013
	jrl nz, CmEsy_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, CmEsy_ReturnZero
	cp xde, 0x6
	jrl ugt, CmEsy_ReturnZero
	add xde, xde
	add xde, 0xE4BF28
	ld de, (xde)
	lda_24 xix, 0xf68633
	jp_dri 8, 0x07, 0xF0, 0xE8
; CmpNcpTtlFunc title dispatch
CmpNcpTtl_Dispatch:
	.ascii ":;<>"
	.byte 0x1d, 0x25, 0x55, 0xf6
	.byte 0x5e, 0x5c, 0x5b, 0x5a
	.byte 0xc1, 0x80, 0x3a, 0x21
	.byte 0xc9, 0xd9, 0x66, 0x16, 0xc9, 0xd8, 0x7e, 0xca
	.byte 0x05, 0xd8, 0xa9, 0x1d, 0x25, 0x95, 0xf9, 0xd8
	.byte 0xaa, 0x1d, 0x6d, 0x95, 0xf9, 0x30, 0x82, 0x00
	.byte 0x68, 0x5f, 0xd8, 0xa9, 0x1d, 0x25, 0x95, 0xf9
	.byte 0xd8, 0xae, 0x1d, 0x6d, 0x95, 0xf9, 0x30, 0x86
	.byte 0x00, 0x68, 0x4e, 0xd8, 0xa8, 0x1d, 0x25, 0x95
	.byte 0xf9
	.byte 0x3a, 0x3b, 0x3c, 0x3e
	.byte 0x1d, 0x9e, 0x55
	.byte 0xf6
	.ascii "^\\[Zx"
	.byte 0x93, 0x05
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	16143653
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ldda8	a, 14976
	cps	a, 1
	jr	z, 22
	cps	a, 0
	jrl	nz, 1402
	lds	wa, 1
	call	16356645
	lds	wa, 2
	call	16356717
	ldw	wa, 130
	jr	15
	lds	wa, 1
	call	16356645
	lds	wa, 6
	call	16356717
	ldw	wa, 134
	call	16356697
	jrl	1363

; CmpNcpTtl special mode 7
CmpNcpTtl_SpecialMode7:
	cp xde, 0xB
	jr ule, CmpNcpTtl_TableDispatch
	sub xde, 0x74
	cp xde, 0xC
	jrl c, CmEsy_ReturnZero
	cp xde, 0x13
	jrl ugt, CmEsy_ReturnZero

; CmpNcpTtl table-driven dispatch
CmpNcpTtl_TableDispatch:
	add xde, xde
	add xde, 0xE4BF00
	ld de, (xde)
	lda_24 xix, 0xf686f7
	jp_dri 8, 0x07, 0xF0, 0xE8
; CmpNcpTtlFunc title dispatch 2
CmpNcpTtl_Dispatch2:
	lds	wa, 1
	call	16356677
	push	xde
	push	xhl
	push	xix
	push	xiz
	ldb	w, 0
	call	16143792
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	cpdi8	14976, 0
	jr	z, 56
	stdi8	14976, 0
	ld	xwa, 12058651
	ld	xbc, 29360140
	lds32	xde, 0
	call	16424455
	ld	xwa, 12058650
	ld	xbc, 29360140
	lds32	xde, 0
	call	16424455
	lds	wa, 1
	call	16356645
	lds	wa, 2
	call	16356717
	ldw	wa, 130
	call	16356697
	ld	xwa, 12058654
	ld	xbc, 29360140
	lds32	xde, 0
	call	16424455
	ld	xwa, 12058655
	ld	xbc, 29360140
	lds32	xde, 0
	call	16424455
	ld	xwa, 12058642
	ld	xbc, 29360140
	lds32	xde, 0
	jrl	1171
	lds	wa, 1
	call	16356677
	.ascii ":;<> "
	.byte 0x80, 0x1d
	ld	(xwa), iy
	.byte 0xf6
	pop xiz
	pop xix
	pop xhl
	pop xde
	.byte 0xc1, 0x80, 0x3a, 0x3f, 0x00, 0x66, 0x38, 0xf1
	.byte 0x80, 0x3a, 0x00, 0x00
	ld	xwa, 12058651
	ld	xbc, 29360140
	lds32	xde, 0
	call	16424455
	ld	xwa, 12058650
	ld	xbc, 29360140
	lds32	xde, 0
	call	16424455
	lds	wa, 1
	call	16356645
	lds	wa, 2
	call	16356717
	ldw	wa, 130
	call	16356697
	ld	xwa, 12058654
	ld	xbc, 29360140
	lds32	xde, 0
	call	16424455
	ld	xwa, 12058655
	ld	xbc, 29360140
	lds32	xde, 0
	call	16424455
	ld	xwa, 12058642
	ld	xbc, 29360140
	lds32	xde, 0
	.byte 0x78, 0x11, 0x04
	lds	wa, 1
	.byte 0x1d, 0x45
	cp	(xiy), bc
	.asciz ":;<> "
	.byte 0x1d, 0xd3, 0x55, 0xf6
	.byte 0x5e, 0x5c, 0x5b, 0x5a
	.byte 0xc1, 0x80, 0x3a, 0x3f, 0x00, 0x66, 0x38, 0xf1
	.byte 0x80, 0x3a, 0x00, 0x00, 0x40, 0x1b, 0x00, 0xb8
	.byte 0x00, 0x41, 0x0c, 0x00, 0xc0, 0x01, 0xea, 0xa8
	.byte 0x1d, 0x07, 0x9e, 0xfa, 0x40, 0x1a, 0x00, 0xb8
	.byte 0x00, 0x41, 0x0c, 0x00, 0xc0, 0x01, 0xea, 0xa8
	.byte 0x1d, 0x07, 0x9e, 0xfa, 0xd8, 0xa9, 0x1d, 0x25
	.byte 0x95, 0xf9, 0xd8, 0xaa, 0x1d, 0x6d, 0x95, 0xf9
	.byte 0x30, 0x82, 0x00, 0x1d, 0x59, 0x95, 0xf9, 0xc1
	.byte 0xa7, 0x39, 0x21, 0xc9, 0xda, 0x66, 0x57, 0xc9
	.byte 0xd9, 0x66, 0x34, 0xc9, 0xd8, 0x7e, 0xb7, 0x03
	.byte 0x40, 0x1e, 0x00, 0xb8, 0x00, 0x41, 0x0c, 0x00
	.byte 0xc0, 0x01, 0xea, 0xa8, 0x1d, 0x07, 0x9e, 0xfa
	.byte 0x40, 0x1f, 0x00, 0xb8, 0x00, 0x41, 0x0c, 0x00
	.byte 0xc0, 0x01, 0xea, 0xa8, 0x1d, 0x07, 0x9e, 0xfa
	.byte 0x40, 0x12, 0x00, 0xb8, 0x00, 0x41, 0x0c, 0x00
	.byte 0xc0, 0x01, 0xea, 0xa8, 0x78, 0x7e, 0x03, 0x40
	.byte 0x1f, 0x00, 0xb8, 0x00, 0x41, 0x0c, 0x00, 0xc0
	.byte 0x01, 0xea, 0xa8, 0x1d, 0x07, 0x9e, 0xfa, 0x40
	.byte 0x1b, 0x00, 0xb8, 0x00, 0x41, 0x0c, 0x00, 0xc0
	.byte 0x01, 0xea, 0xa8, 0x78, 0x5f, 0x03, 0x40, 0x12
	.byte 0x00, 0xb8, 0x00, 0x41, 0x0c, 0x00, 0xc0, 0x01
	.byte 0xea, 0xa8, 0x1d, 0x07, 0x9e, 0xfa, 0x40, 0x1b
	.byte 0x00, 0xb8, 0x00, 0x41, 0x0c, 0x00, 0xc0, 0x01
	.byte 0xea, 0xa8, 0x78, 0x40, 0x03, 0xd8, 0xa9, 0x1d
	.byte 0x45, 0x95, 0xf9
	.ascii ":;<> "
	.byte 0x80, 0x1d, 0xd3, 0x55, 0xf6, 0x5e, 0x5c, 0x5b
	.byte 0x5a, 0xc1, 0x80, 0x3a, 0x3f, 0x00, 0x66, 0x38
	.byte 0xf1, 0x80, 0x3a, 0x00, 0x00, 0x40, 0x1b, 0x00
	.byte 0xb8, 0x00, 0x41, 0x0c, 0x00, 0xc0, 0x01, 0xea
	.byte 0xa8, 0x1d, 0x07, 0x9e, 0xfa, 0x40, 0x1a, 0x00
	.byte 0xb8, 0x00, 0x41, 0x0c, 0x00, 0xc0, 0x01, 0xea
	.byte 0xa8, 0x1d, 0x07, 0x9e, 0xfa, 0xd8, 0xa9, 0x1d
	.byte 0x25, 0x95, 0xf9, 0xd8, 0xaa, 0x1d, 0x6d, 0x95
	.byte 0xf9, 0x30, 0x82, 0x00, 0x1d, 0x59, 0x95, 0xf9
	.byte 0xc1, 0xa7, 0x39, 0x21, 0xc9, 0xda, 0x66, 0x57
	.byte 0xc9, 0xd9, 0x66, 0x34, 0xc9, 0xd8, 0x7e, 0xe6
	.byte 0x02, 0x40, 0x1e, 0x00, 0xb8, 0x00, 0x41, 0x0c
	.byte 0x00, 0xc0, 0x01, 0xea, 0xa8, 0x1d, 0x07, 0x9e
	.byte 0xfa, 0x40, 0x1f, 0x00, 0xb8, 0x00, 0x41, 0x0c
	.byte 0x00, 0xc0, 0x01, 0xea, 0xa8, 0x1d, 0x07, 0x9e
	.byte 0xfa, 0x40, 0x12, 0x00, 0xb8, 0x00, 0x41, 0x0c
	.byte 0x00, 0xc0, 0x01, 0xea, 0xa8, 0x78, 0xad, 0x02
	.byte 0x40, 0x1f, 0x00, 0xb8, 0x00, 0x41, 0x0c, 0x00
	.byte 0xc0, 0x01, 0xea, 0xa8, 0x1d, 0x07, 0x9e, 0xfa
	.byte 0x40, 0x1b, 0x00, 0xb8, 0x00, 0x41, 0x0c, 0x00
	.byte 0xc0, 0x01, 0xea, 0xa8, 0x78, 0x8e, 0x02, 0x40
	.byte 0x12, 0x00, 0xb8, 0x00, 0x41, 0x0c, 0x00, 0xc0
	.byte 0x01, 0xea, 0xa8, 0x1d, 0x07, 0x9e, 0xfa, 0x40
	.byte 0x1b, 0x00, 0xb8, 0x00, 0x41, 0x0c, 0x00, 0xc0
	.byte 0x01, 0xea, 0xa8, 0x78, 0x6f, 0x02, 0x3a, 0x3b
	.byte 0x3c, 0x3e, 0x20, 0x00, 0x1d, 0xf6, 0x55, 0xf6
	.byte 0x5e, 0x5c, 0x5b, 0x5a
	.byte 0xc1, 0x80, 0x3a, 0x3f
	.byte 0x01, 0x66, 0x48, 0xf1, 0x80, 0x3a, 0x00, 0x01
	.byte 0x40, 0x1e, 0x00, 0xb8, 0x00, 0x41, 0x0c, 0x00
	.byte 0xc0, 0x01, 0xea, 0xa8, 0x1d, 0x07, 0x9e, 0xfa
	.byte 0x40, 0x1f, 0x00, 0xb8, 0x00, 0x41, 0x0c, 0x00
	.byte 0xc0, 0x01, 0xea, 0xa8, 0x1d, 0x07, 0x9e, 0xfa
	.byte 0x40, 0x12, 0x00, 0xb8, 0x00, 0x41, 0x0c, 0x00
	.byte 0xc0, 0x01, 0xea, 0xa8, 0x1d, 0x07, 0x9e, 0xfa
	.byte 0xd8, 0xa9, 0x1d, 0x25, 0x95, 0xf9, 0xd8, 0xae
	.byte 0x1d, 0x6d, 0x95, 0xf9, 0x30, 0x86, 0x00, 0x1d
	.byte 0x59, 0x95, 0xf9, 0x40, 0x1a, 0x00, 0xb8, 0x00
	.byte 0x41, 0x0c, 0x00, 0xc0, 0x01, 0xea, 0xa8, 0x1d
	.byte 0x07, 0x9e, 0xfa, 0x40, 0x1b, 0x00, 0xb8, 0x00
	.byte 0x41, 0x0c, 0x00, 0xc0, 0x01, 0xea, 0xa8, 0x78
	.byte 0xf3, 0x01
	.ascii ":;<> €"
	call	16143862
	pop xiz
	pop xix
	pop xhl
	pop xde
	.byte 0xc1, 0x80, 0x3a, 0x3f, 0x01, 0x66, 0x48, 0xf1
	.byte 0x80, 0x3a, 0x00, 0x01
	ld	xwa, 12058654
	ld	xbc, 29360140
	lds32	xde, 0
	call	16424455
	ld	xwa, 12058655
	ld	xbc, 29360140
	lds32	xde, 0
	call	16424455
	ld	xwa, 12058642
	ld	xbc, 29360140
	lds32	xde, 0
	call	16424455
	lds	wa, 1
	call	16356645
	lds	wa, 6
	call	16356717
	ldw	wa, 134
	call	16356697
	ld	xwa, 12058651
	ld	xbc, 29360140
	lds32	xde, 0
	call	16424455
	ld	xwa, 12058650
	ld	xbc, 29360140
	lds32	xde, 0
	.byte 0x78, 0x77, 0x01
	lds	wa, 1
	call	16356677
	push xde
	push xhl
	push xix
	push xiz
	ldb	w, 0
	call	16143897
	pop xiz
	pop xix
	pop xhl
	pop xde
	.byte 0xc1, 0x80, 0x3a, 0x3f, 0x01, 0x66, 0x48, 0xf1
	.byte 0x80, 0x3a, 0x00, 0x01
	ld	xwa, 12058654
	ld	xbc, 29360140
	lds32	xde, 0
	call	16424455
	ld	xwa, 12058655
	ld	xbc, 29360140
	lds32	xde, 0
	call	16424455
	ld	xwa, 12058642
	ld	xbc, 29360140
	lds32	xde, 0
	call	16424455
	lds	wa, 1
	call	16356645
	lds	wa, 6
	call	16356717
	ldw	wa, 134
	call	16356697
	.byte 0xc1, 0xa8, 0x39, 0x21
	cps	a, 1
	.byte 0x66, 0x34
	cps	a, 0
	.byte 0x7e, 0x11, 0x01
	ld	xwa, 12058650
	ld	xbc, 29360140
	lds32	xde, 0
	call	16424455
	ld	xwa, 12058651
	ld	xbc, 29360140
	lds32	xde, 0
	call	16424455
	ld	xwa, 12058642
	ld	xbc, 29360140
	lds32	xde, 0
	.byte 0x78, 0xd8, 0x00
	ld	xwa, 12058651
	ld	xbc, 29360140
	lds32	xde, 0
	call	16424455
	ld	xwa, 12058642
	ld	xbc, 29360140
	lds32	xde, 0
	.byte 0x78, 0xb9, 0x00
	lds	wa, 1
	.byte 0x1d, 0x45
	cp	(xiy), bc
	.ascii ":;<> €"
	.byte 0x1d, 0x19, 0x56, 0xf6
	.byte 0x5e, 0x5c, 0x5b, 0x5a
	.byte 0xc1, 0x80, 0x3a, 0x3f, 0x01, 0x66, 0x48, 0xf1
	.byte 0x80, 0x3a, 0x00, 0x01, 0x40, 0x1e, 0x00, 0xb8
	.byte 0x00, 0x41, 0x0c, 0x00, 0xc0, 0x01, 0xea, 0xa8
	.byte 0x1d, 0x07, 0x9e, 0xfa, 0x40, 0x1f, 0x00, 0xb8
	.byte 0x00, 0x41, 0x0c, 0x00, 0xc0, 0x01, 0xea, 0xa8
	.byte 0x1d, 0x07, 0x9e, 0xfa, 0x40, 0x12, 0x00, 0xb8
	.byte 0x00, 0x41, 0x0c, 0x00, 0xc0, 0x01, 0xea, 0xa8
	.byte 0x1d, 0x07, 0x9e, 0xfa, 0xd8, 0xa9, 0x1d, 0x25
	.byte 0x95, 0xf9, 0xd8, 0xae, 0x1d, 0x6d, 0x95, 0xf9
	.byte 0x30, 0x86, 0x00, 0x1d, 0x59, 0x95, 0xf9, 0xc1
	.byte 0xa8, 0x39, 0x21, 0xc9, 0xd9, 0x66, 0x32, 0xc9
	.byte 0xd8, 0x6e, 0x54, 0x40, 0x1a, 0x00, 0xb8, 0x00
	.byte 0x41, 0x0c, 0x00, 0xc0, 0x01, 0xea, 0xa8, 0x1d
	.byte 0x07, 0x9e, 0xfa, 0x40, 0x1b, 0x00, 0xb8, 0x00
	.byte 0x41, 0x0c, 0x00, 0xc0, 0x01, 0xea, 0xa8, 0x1d
	.byte 0x07, 0x9e, 0xfa, 0x40, 0x12, 0x00, 0xb8, 0x00
	.byte 0x41, 0x0c, 0x00, 0xc0, 0x01, 0xea, 0xa8, 0x68
	.byte 0x1c, 0x40, 0x1b, 0x00, 0xb8, 0x00, 0x41, 0x0c
	.byte 0x00, 0xc0, 0x01, 0xea, 0xa8, 0x1d, 0x07, 0x9e
	.byte 0xfa, 0x40, 0x12, 0x00, 0xb8, 0x00, 0x41, 0x0c
	.byte 0x00, 0xc0, 0x01, 0xea, 0xa8, 0x1d, 0x07, 0x9e
	.byte 0xfa, 0x68, 0x04, 0xf1, 0xd1, 0x34, 0xb8

CmEsy_ReturnZero:
	lds32 xhl, 0
	ret
; CmEsyTtlFunc main handler
CmpEsyTtl_MainHandler:
CmEsyTtlFunc:
	cp xbc, 0x1C00007
	jrl z, CmpEsyTtl_Mode1
	cp xbc, 0x1C00013
	jrl nz, S2cTtl_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, S2cTtl_ReturnZero
	cp xde, 0x6
	jrl ugt, S2cTtl_ReturnZero
	add xde, xde
	add xde, 0xE4BF56
	ld de, (xde)
	lda_24 xix, 0xf68c53
	jp_dri 8, 0x07, 0xF0, 0xE8
; CmEsyTtlFunc title dispatch
CmEsyTtl_Dispatch:
	cpdi8	36151, 186
	jrl	z, 388
	ldda8	a, 13526
	cp	a, 29
	jr	ule, 10
	sub	a, 30
	sll	a, 2
	stda8	13526, a
	.byte 0xc1, 0xc8, 0x37, 0x3e, 0x7f, 0xf1, 0xa7, 0x28, 0xb2, 0xf1, 0xcd, 0x34, 0xb6
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	16141598
	call	16141259
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	stdi8	13553, 0
	ld	xwa, 12189706
	ld	xbc, 31457422
	ld	xde, 4294901762
	jrl	219
	cpdi8	14265, 255
	jrl	z, 309
	ldada	xiy, 14265
	ldada	xix, 14251
	ldada	xhl, 14272
	ldada	xde, 14258
	lds32	xbc, 0
	.byte 0xc5, 0xf4, 0x21, 0xf5, 0xf0, 0x41, 0xc5, 0xec, 0x21, 0xf5, 0xe8, 0x41
	inc	1, xbc
	cp	xbc, 7
	jr	c, -22
	.byte 0xc1, 0xc7, 0x37, 0x19, 0xd6, 0x34
	jrl	260

; CmpEsyTtl mode 1
CmpEsyTtl_Mode1:
	cp xde, 0xB
	jr ule, CmpEsyTtl_Mode2
	sub xde, 0x74
	cp xde, 0xC
	jrl c, S2cTtl_ReturnZero
	cp xde, 0x13
	jrl ugt, S2cTtl_ReturnZero

; CmpEsyTtl mode 2
CmpEsyTtl_Mode2:
	add xde, 0xE4BF36
	ld de, (xde)
	extz de
	sll de, 1
	ld xix, 0xE4BF4A
	ld_sriw3 DE, 0x07, 0xF0, 0xE8
	lda_24 xix, 0xf68d1c
	jp_dri 8, 0x07, 0xF0, 0xE8
; CmEsyTtlFunc title dispatch 2
CmEsyTtl_Dispatch2:
	; --- Multi-branch dispatch subroutine (195 bytes) ---
	lds	wa, 0
	jrl t, CmpEsyTtl_SubModeD_Cont
	push xde
	push xhl
	push xix
	push xiz
	call 0xF674F5
	call 0xF660CF
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw wa, 0x00B5
	call UI_PostModeChangeEvent
	jrl t, S2cTtl_ReturnZero
	lds	wa, 1
	call UI_PostEvent_0x6E
	push xde
	push xhl
	push xix
	push xiz
	ldb a, 0x00
	call VoiceSlot_Dispatch_Return
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld xwa, 0x00BA0009
	ld xbc, 0x01C0000B
	lds32	xde, 0
	jr t, CmpEsy_DeliverEventAndCheck
	lds	wa, 1
	call UI_PostEvent_0x6E
	push xde
	push xhl
	push xix
	push xiz
	ldb a, 0x80
	call VoiceSlot_Dispatch_Return
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld xwa, 0x00BA0009
	ld xbc, 0x01C0000B
	lds32	xde, 0
CmpEsy_DeliverEventAndCheck:
	call ApDeliveryEvent
	jr t, S2cTtl_ReturnZero
	cpdi8	14280, 0
	jr z, CmpEsyTtl_SubModeC
	push xde
	push xhl
	push xix
	push xiz
	call 0xF67510
	pop xiz
	pop xix
	pop xhl
	pop xde
	cpdi8	32578, 0
	jr nz, CmpEsyTtl_SubModeD
	ldada	xiy, 14251
	ldada	xix, 14265
	ldada	xhl, 14258
	ldada	xde, 14272
	lds32	xbc, 0
; CmpEsyTtl sub-mode B
CmpEsyTtl_SubModeB:
	.byte 0xc5, 0xf4, 0x21			; ld a, (xiy+)  [post-increment]
	.byte 0xf5, 0xf0, 0x41			; ld (xix+), a  [post-increment]
	.byte 0xc5, 0xec, 0x21			; ld a, (xhl+)  [post-increment]
	.byte 0xf5, 0xe8, 0x41			; ld (xde+), a  [post-increment]
	inc 1, xbc
	cp xbc, 0x00000007
	jr c, CmpEsyTtl_SubModeB
	.byte 0xc1, 0xd6, 0x34, 0x19, 0xc7, 0x37	; ld (0x37C7), (0x34D6)  [mem-to-mem 8-bit direct]
	jr t, CmpEsyTtl_SubModeD
; CmpEsyTtl sub-mode C
CmpEsyTtl_SubModeC:
	push xde
	push xhl
	push xix
	push xiz
	call 0xF674F5
	pop xiz
	pop xix
	pop xhl
	pop xde
; CmpEsyTtl sub-mode D entry
CmpEsyTtl_SubModeD:
	lds	wa, 0
; CmpEsyTtl sub-mode D continuation
CmpEsyTtl_SubModeD_Cont:
	call UI_PostDialEnable


S2cTtl_ReturnZero:
	lds32 xhl, 0
	ret
; CmpEsyTtl sub-mode E dispatch
CmpEsyTtl_SubModeE:
S2cTtlFunc:
	cp xbc, 0x1C00007
	jrl z, CmpEsyTtl_E_Var1
	cp xbc, 0x1C00013
	jrl nz, CstmCp_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, CstmCp_ReturnZero
	cp xde, 0x6
	jrl ugt, CstmCp_ReturnZero
	add xde, xde
	add xde, 0xE4BF7C
	ld de, (xde)
	lda_24 xix, 0xf68e1c
	jp_dri 8, 0x07, 0xF0, 0xE8
; S2cTtlFunc title dispatch
S2cTtl_Dispatch:
	cpdi8	36151, 185
	jr	z, 19
	ld	xwa, 12124193
	ld	xbc, 31457422
	ld	xde, 4294901762
	call	16424455
	call	16146923
	jrl	999
	ldda8	a, 14967
	cps	a, 2
	jr	z, 43
	cps	a, 1
	jr	z, 22
	cps	a, 0
	jrl	nz, 982
	lds	wa, 1
	call	16356645
	lds	wa, 0
	call	16356717
	ldw	wa, 128
	jr	32
	lds	wa, 1
	call	16356645
	lds	wa, 1
	call	16356717
	ldw	wa, 129
	jr	15
	lds	wa, 1
	call	16356645
	lds	wa, 2
	call	16356717
	ldw	wa, 130
	call	16356697
	jrl	926

; CmpEsyTtl E variant 1
CmpEsyTtl_E_Var1:
	ld xwa, xde
	cp xde, 0x86
	jrl z, CstmCp_ReturnZero
	cp xde, 0x84
	jrl z, CstmCp_ReturnZero
	cp xde, 0x82
	jrl z, S2cTtl_SecondaryHandler
	cp xde, 0x81
	jrl z, S2cTtl_MainHandler
	cp xde, 0x80
	jrl z, CmpEsyTtl_E_Var2
	cp xwa, 0xB
	jrl ugt, CstmCp_ReturnZero
	add xwa, xwa
	add xwa, 0xE4BF64
	ld wa, (xwa)
	lda_24 xix, 0xf68ed2
	jp_dri 8, 0x07, 0xF0, 0xE0

CmpEsy_E_DispatchDataBlock:
	lds	wa, 1
	call	16356677
	lds	wa, 1
	call	16356645
	lds	wa, 0
	call	16356717
	ldw	wa, 128
	call	16356697
	lds	wa, 0
	call	16147043
	cpdi8	14967, 0
	jr	nz, 31
	ld	xwa, 12124188
	ld	xbc, 29360140
	lds32	xde, 0
	call	16424455
	ld	xwa, 12124191
	ld	xbc, 29360140
	lds32	xde, 0
	jrl	769
	stdi8	14967, 0
	ld	xwa, 12124188
	ld	xbc, 29360140
	lds32	xde, 0
	call	16424455
	ld	xwa, 12124191
	ld	xbc, 29360140
	lds32	xde, 0
	call	16424455
	ld	xwa, 12124184
	ld	xbc, 29360140
	lds32	xde, 0
	call	16424455
	ld	xwa, 12124193
	ld	xbc, 31719473
	lds32	xde, 0
	jrl	701

; CmpEsyTtl E variant 2
CmpEsyTtl_E_Var2:
	lds wa, 1
	call UI_PostEvent_0x6E
	lds wa, 1
	call UI_PostDialEnable
	lds wa, 0
	call UI_PostDialValueEvent
	ldw wa, 0x80
	call UI_PostDialRangeEvent
	lds wa, 1
	call Tempo_AdjustStartMeasure
	cpdi8 14967, 0
	jr nz, CmpEsy_E_Var2_StoreMeasure
	ld xwa, 0xB9001C
	ld xbc, 0x1C0000C
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB9001F
	ld xbc, 0x1C0000C
	lds32 xde, 0
	jrl TtlFunc_SendEventAndReturn

CmpEsy_E_Var2_StoreMeasure:
	stdi8 14967, 0
	ld xwa, 0xB9001C
	ld xbc, 0x1C0000C
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB9001F
	ld xbc, 0x1C0000C
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB90018
	ld xbc, 0x1C0000C
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB90021
	ld xbc, 0x1E40031
	lds32 xde, 0
	jrl TtlFunc_SendEventAndReturn
	lds wa, 1
	call UI_PostEvent_0x6E
	lds wa, 1
	call UI_PostDialEnable
	lds wa, 1
	call UI_PostDialValueEvent
	ldw wa, 0x81
	call UI_PostDialRangeEvent
	lds wa, 0
	call Tempo_AdjustEndMeasure
	cpdi8 14967, 1
	jr nz, CmpEsy_E_EndMeasure_Store
	ld xwa, 0xB9001F
	ld xbc, 0x1C0000C
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB9001C
	ld xbc, 0x1C0000C
	lds32 xde, 0
	jrl TtlFunc_SendEventAndReturn

CmpEsy_E_EndMeasure_Store:
	stdi8 14967, 1
	ld xwa, 0xB9001F
	ld xbc, 0x1C0000C
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB9001C
	ld xbc, 0x1C0000C
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB90018
	ld xbc, 0x1C0000C
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB90021
	ld xbc, 0x1E40031
	lds32 xde, 0
	jrl TtlFunc_SendEventAndReturn

; S2cTtlFunc main handler
S2cTtl_MainHandler:
	lds wa, 1
	call UI_PostEvent_0x6E
	lds wa, 1
	call UI_PostDialEnable
	lds wa, 1
	call UI_PostDialValueEvent
	ldw wa, 0x81
	call UI_PostDialRangeEvent
	lds wa, 1
	call Tempo_AdjustEndMeasure
	cpdi8 14967, 1
	jr nz, CmpEsy_Main_EndMeasure_Store
	ld xwa, 0xB9001F
	ld xbc, 0x1C0000C
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB9001C
	ld xbc, 0x1C0000C
	lds32 xde, 0
	jrl TtlFunc_SendEventAndReturn

CmpEsy_Main_EndMeasure_Store:
	stdi8 14967, 1
	ld xwa, 0xB9001F
	ld xbc, 0x1C0000C
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB9001C
	ld xbc, 0x1C0000C
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB90018
	ld xbc, 0x1C0000C
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB90021
	ld xbc, 0x1E40031
	lds32 xde, 0
	jrl TtlFunc_SendEventAndReturn
	lds wa, 1
	call UI_PostEvent_0x6E
	lds wa, 1
	call UI_PostDialEnable
	lds wa, 2
	call UI_PostDialValueEvent
	ldw wa, 0x82
	call UI_PostDialRangeEvent
	lds wa, 0
	call Tempo_AdjustQuantize
	cpdi8 14967, 2
	jr nz, CmpEsy_Quantize_Store
	ld xwa, 0xB90018
	ld xbc, 0x1C0000C
	lds32 xde, 0
	jrl TtlFunc_SendEventAndReturn

CmpEsy_Quantize_Store:
	stdi8 14967, 2
	ld xwa, 0xB90018
	ld xbc, 0x1C0000C
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB9001F
	ld xbc, 0x1C0000C
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB9001C
	ld xbc, 0x1C0000C
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB90021
	ld xbc, 0x1E40031
	lds32 xde, 0
	jrl TtlFunc_SendEventAndReturn

; S2cTtlFunc secondary handler
S2cTtl_SecondaryHandler:
	lds wa, 1
	call UI_PostEvent_0x6E
	lds wa, 1
	call UI_PostDialEnable
	lds wa, 2
	call UI_PostDialValueEvent
	ldw wa, 0x82
	call UI_PostDialRangeEvent
	lds wa, 1
	call Tempo_AdjustQuantize
	cpdi8 14967, 2
	jr nz, CmpEsy_SecQuantize_Store
	ld xwa, 0xB90018
	ld xbc, 0x1C0000C
	lds32 xde, 0
	jr TtlFunc_SendEventAndReturn

CmpEsy_SecQuantize_Store:
	stdi8 14967, 2
	ld xwa, 0xB90018
	ld xbc, 0x1C0000C
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB9001F
	ld xbc, 0x1C0000C
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB9001C
	ld xbc, 0x1C0000C
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB90021
	ld xbc, 0x1E40031
	lds32 xde, 0
	jr TtlFunc_SendEventAndReturn
	lds wa, 1
	call UI_PostEvent_0x6E
	lds wa, 0
	call Tempo_IncrementTimeSigNum
	ld xwa, 0xB9001E
	ld xbc, 0x1C0000C
	lds32 xde, 0
	jr TtlFunc_SendEventAndReturn
	lds wa, 1
	call UI_PostEvent_0x6E
	lds wa, 0
	call Tempo_DecrementTimeSigNum
	ld xwa, 0xB9001E
	ld xbc, 0x1C0000C
	lds32 xde, 0

TtlFunc_SendEventAndReturn:
	call ApDeliveryEvent
	jr CstmCp_ReturnZero
	lds wa, 0
	call Tempo_EditBPM

CstmCp_ReturnZero:
	lds32 xhl, 0
	ret
; CstmCpTtl record dispatch
CstmCpTtl_RecDispatch:
CstmCpTtlFunc:
	cp xbc, 0x1C00007
	jrl z, CstmCpTtl_RecMode1
	cp xbc, 0x1C00013
	jrl nz, CstmCp_ReturnZero2
	dec 2, xde
	cp xde, 0x0
	jrl c, CstmCp_ReturnZero2
	cp xde, 0x6
	jrl ugt, CstmCp_ReturnZero2
	add xde, xde
	add xde, 0xE4BFB2
	ld de, (xde)
	lda_24 xix, 0xf69261
	jp_dri 8, 0x07, 0xF0, 0xE8
; CstmCpTtlFunc title dispatch
CstmCpTtl_Dispatch:
	cpdi8	36151, 190
	jr	z, 8
	stdi8	14974, 0
	jrl	804
	cpdi8	36153, 238
	jrl	nz, 796
	ldda8	a, 14974
	cps	a, 2
	jr	z, 5
	cps	a, 1
	jrl	nz, 783
	cpdi8	14774, 3
	jr	nc, 15
	ld	xwa, 12451857
	ld	xbc, 29360129
	lds32	xde, 5
	jrl	708
	ld	xwa, 12451865
	ld	xbc, 29360129
	lds32	xde, 5
	jrl	693
	ldda8	a, 14974
	cps	a, 2
	jr	z, 5
	cps	a, 1
	jrl	nz, 733
	cpdi8	14774, 3
	jr	nc, 15
	ld	xwa, 12451857
	ld	xbc, 29360129
	lds32	xde, 5
	jrl	658
	ld	xwa, 12451865
	ld	xbc, 29360129
	lds32	xde, 5
	jrl	t, 0x0283

; CstmCpTtl record mode 1
CstmCpTtl_RecMode1:
	cp xde, 0xB
	jr ule, CstmCpTtl_RecMode2
	sub xde, 0x74
	cp xde, 0xC
	jrl c, CstmCp_ReturnZero2
	cp xde, 0x13
	jrl ugt, CstmCp_ReturnZero2

; CstmCpTtl record mode 2
CstmCpTtl_RecMode2:
	add xde, xde
	add xde, 0xE4BF8A
	ld de, (xde)
	lda_24 xix, 0xf69310
	jp_dri 8, 0x07, 0xF0, 0xE8
; CstmCpTtlFunc title dispatch 2
CstmCpTtl_Dispatch2:
	cpdi8	14974, 0
	jrl	nz, 636
	lds	wa, 1
	call	16356677
	ldb	c, 29
	ldda8	a, 14774
	cp	a, 10
	jr	nc, 2
	ldb	c, 2
	cp	a, c
	jrl	nc, 612
	inc	1, a
	stda8	14774, a
	ld	xwa, 12451843
	ld	xbc, 29360139
	lds32	xde, 0
	call	16424455
	ld	xwa, 12451844
	ld	xbc, 29360141
	lds32	xde, 0
	jrl	322
	cpdi8	14974, 0
	jrl	nz, 567
	lds	wa, 1
	call	16356677
	ldb	c, 10
	ldda8	a, 14774
	cp	a, 10
	jr	nc, 2
	ldb	c, 0
	cp	a, c
	jrl	ule, 543
	dec	1, a
	stda8	14774, a
	ld	xwa, 12451843
	ld	xbc, 29360139
	lds32	xde, 0
	call	16424455
	ld	xwa, 12451844
	ld	xbc, 29360141
	lds32	xde, 0
	jrl	253
	cpdi8	14974, 0
	jrl	nz, 498
	ldda8	a, 14774
	ldda8	c, 14775
	stda8	14774, c
	stda8	14775, a
	ld	xwa, 12451843
	ld	xbc, 29360139
	lds32	xde, 0
	call	16424455
	ld	xwa, 12451851
	ld	xbc, 29360139
	lds32	xde, 0
	call	16424455
	ld	xwa, 12451853
	ld	xbc, 29360139
	lds32	xde, 0
	call	16424455
	ld	xwa, 12451854
	ld	xbc, 29360139
	lds32	xde, 0
	call	16424455
	ld	xwa, 12451844
	ld	xbc, 29360141
	lds32	xde, 0
	call	16424455
	ld	xwa, 12451855
	ld	xbc, 29360141
	lds32	xde, 0
	jrl	134
	cpdi8	14974, 0
	jrl	nz, 379
	lds	wa, 1
	call	16356677
	ldb	c, 29
	ldda8	a, 14775
	cp	a, 10
	jr	nc, 2
	ldb	c, 2
	cp	a, c
	jrl	nc, 355
	inc	1, a
	stda8	14775, a
	ld	xwa, 12451851
	ld	xbc, 29360139
	lds32	xde, 0
	call	16424455
	ld	xwa, 12451855
	ld	xbc, 29360141
	lds32	xde, 0
	jr	66
	cpdi8	14974, 0
	jrl	nz, 311
	lds	wa, 1
	call	16356677
	ldb	c, 10
	ldda8	a, 14775
	cp	a, 10
	jr	nc, 2
	ldb	c, 0
	cp	a, c
	jrl	ule, 287
	dec	1, a
	stda8	14775, a
	ld	xwa, 12451851
	ld	xbc, 29360139
	lds32	xde, 0
	call	16424455
	ld	xwa, 12451855
	ld	xbc, 29360141
	lds32	xde, 0
	call	16424455
	jrl	246
	ldda8	a, 14974
	cps	a, 2
	jr	z, 5
	cps	a, 1
	jrl	nz, 233
	lds	wa, 0
	call	15822218
	cps	l, 1
	jrl	z, 222
	cps	l, 0
	jrl	nz, 217
	stdi8	14974, 0
	ld	xwa, 4294967295
	ld	xbc, 29360130
	lds32	xde, 0
	call	16424280
	stdi8	32578, 35
	ldw	wa, 238
	jrl	181
	ldda8	a, 14974
	cps	a, 2
	jrl	z, 129
	cps	a, 1
	jr	z, 125
	cps	a, 0
	jrl	nz, 167
	cpdi8	14774, 3
	jr	nc, 12
	.byte 0xf1, 0x42, 0x7f, 0x00
	.long LABEL_EE3025
	call	16356541
	ldda8	a, 14774
	extz	wa
	ldda8	c, 14775
	extz	bc
	call	15821515
	cps	l, 2
	jr	z, 28
	cps	l, 1
	jr	z, 14
	cps	l, 0
	jr	nz, 120
	.byte 0xf1, 0x42, 0x7f, 0x00
	.long LABEL_EE3023
	jr	106
	stdi8	32578, 15
	ldw	wa, 238
	jr	96
	ld	xwa, 4294967295
	ld	xbc, 31457401
	lds32	xde, 0
	call	16424455
	cpdi8	14774, 3
	jr	nc, 7
	stdi8	14974, 1
	jr	70
	stdi8	14974, 2
	ld	xwa, 12451865
	ld	xbc, 29360129
	lds32	xde, 5
	call	16424280
	jr	47
	lds	wa, 2
	call	15822218
	cps	l, 1
	jr	z, 37
	cps	l, 0
	jr	nz, 33
	stdi8	14974, 0
	ld	xwa, 4294967295
	ld	xbc, 29360130
	lds32	xde, 0
	call	16424280
	stdi8	32578, 35
	ldw	wa, 238
	call	16356541

CstmCp_ReturnZero2:
	lds32 xhl, 0
	ret

CstmCp_StyleDataBlock:
	cp	xbc, 31719446
	jr	nz, 40
	ldda8	a, 14774
	extz	wa
	ldda8	c, 14775
	extz	bc
	call	15821515
	cps	l, 2
	jr	z, 20
	cps	l, 1
	jr	z, 16
	cps	l, 0
	jr	nz, 12
	.byte 0xf1, 0x42, 0x7f, 0x00
	.long LABEL_EE3023
	call	16356541
	lds32	xhl, 0
	ret
__pad_F695CA:

MainCstmNameFunc:
	lda xsp, (xsp - 120)
	push xiz
	ld xde, xbc
	ld xiy, 0xE4BFC0
	lda xix, (xsp + 4)
	ldw bc, 0x3C
	ldirw
	cp xde, 0x1E4002C
	jr z, CstmName_HandleEvent2C
	cp xde, 0x1E4002B
	jrl nz, CstmName_ReturnZero
	pushw 0x11
	call Malloc
	ld xiz, xhl
	ldda8 a, 14774
	extz wa
	sla wa, 2
	lda xbc, (xsp + 6)
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	add xwa, 0x40
	pushw 0xD
	push xwa
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 12)
	ld (xiz + 13), 0x0
	ld (xiz + 14), 0x0
	ld (xiz + 15), 0x0
	ld (xiz + 16), 0x0
	ld xwa, 0xBE0004
	ld xbc, 0x1E4002D
	ld xde, xiz
	call ApDeliveryEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E00023
	ld xde, xiz
	jr CstmName_PostEventAndReturn

CstmName_HandleEvent2C:
	pushw 0x11
	call Malloc
	ld xiz, xhl
	ldda8 a, 14775
	extz wa
	sla wa, 2
	lda xbc, (xsp + 6)
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	add xwa, 0x40
	pushw 0xD
	push xwa
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 12)
	ld (xiz + 13), 0x0
	ld (xiz + 14), 0x0
	ld (xiz + 15), 0x0
	ld (xiz + 16), 0x0
	ld xwa, 0xBE000F
	ld xbc, 0x1E4002E
	ld xde, xiz
	call ApDeliveryEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E00023
	ld xde, xiz

CstmName_PostEventAndReturn:
	call ApPostEvent

CstmName_ReturnZero:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 120)
	ret
__pad_F696AB:

MainS2cFunc:
	dec 4, xsp
	ld (xsp), xde
	ld xwa, (xsp)
	dec 2, a
	cp xbc, 0x1E40011
	jr z, S2cFunc_HandleEvent11
	cp xbc, 0x1E40010
	jrl nz, EventDelivery_ReturnZero
	stda8 14736, a
	lds wa, 0
	call Tempo_AdjustEffect
	ld xwa, (xsp)
	ld de, wa
	extz xde
	add xde, 0x10000
	ld xwa, 0xB90021
	ld xbc, 0x1E0008D
	call ApDeliveryEvent
	cpdi8 14967, 3
	jrl z, EventDelivery_ReturnZero
	stdi8 14967, 3
	ld xwa, 0xB9001C
	ld xbc, 0x1C0000C
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB9001F
	ld xbc, 0x1C0000C
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB90018
	ld xbc, 0x1C0000C
	lds32 xde, 0
	jr S2cFunc_DeliverAndReturn

S2cFunc_HandleEvent11:
	stda8 14736, a
	lds wa, 1
	call Tempo_AdjustEffect
	ld xwa, (xsp)
	ld de, wa
	extz xde
	add xde, 0x10000
	ld xwa, 0xB90021
	ld xbc, 0x1E0008D
	call ApDeliveryEvent
	cpdi8 14967, 3
	jr z, EventDelivery_ReturnZero
	stdi8 14967, 3
	ld xwa, 0xB9001C
	ld xbc, 0x1C0000C
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB9001F
	ld xbc, 0x1C0000C
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xB90018
	ld xbc, 0x1C0000C
	lds32 xde, 0

S2cFunc_DeliverAndReturn:
	call ApDeliveryEvent

EventDelivery_ReturnZero:
	lds32 xhl, 0
	inc 4, xsp
	ret
__pad_F69788:

MiddleNameFunc:
	ldada xwa, 13500
	cp xbc, 0x1E40001
	jr z, MiddleName_HandleEvent01
	cp xbc, 0x1E40000
	jr nz, MiddleName_ReturnZero
	push xde
	push xwa
	call Strcpy
	inc 8, xsp
	push xde
	push xhl
	push xix
	push xiz
	call RhythmProc_CopySlotData_Wrap
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw wa, 0xB2
	jr MiddleName_PostModeChange

MiddleName_HandleEvent01:
	push xde
	push xwa
	call Strcpy
	inc 8, xsp
	ldda8 c, 32574
	ld a, c
	sll a, 4
	cps c, 2
	jr nc, MiddleName_CalcROMAddr_High
	ldb w, 0x0
	extz xwa
	add xwa, 0x1E8A80
	jr MiddleName_CopyAndPost

MiddleName_CalcROMAddr_High:
	sub a, 0x20
	ldb w, 0x0
	extz xwa
	add xwa, 0x1E8A40

MiddleName_CopyAndPost:
	pushw 0x10
	pushw 0x0
	pushw 0x34BC
	push xwa
	call Strncpy
	lda xsp, (xsp + 10)
	ldw wa, 0xCA

MiddleName_PostModeChange:
	call UI_PostModeChangeEvent

MiddleName_ReturnZero:
	lds32 xhl, 0
	ret
__pad_F697FE:

MiddleCmpClrFunc:
	cp xbc, 0x1E40007
	jr z, MiddleCmpClr_HandleEvent07
	cp xbc, 0x1E40006
	jr nz, MiddleCmpClr_ReturnZero
	setda 2, 13517
	stdi8 13580, 0
	ld xwa, 0xB20012
	ld xbc, 0x1C00002
	lds32 xde, 0
	call ApPostEvent
	stdi8 32578, 35
	ldw wa, 0xEE
	call SoundCtrl_SendCommand
	jr MiddleCmpClr_ReturnZero

MiddleCmpClr_HandleEvent07:
	stdi8 13580, 0
	ld xwa, 0xB20012
	ld xbc, 0x1C00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xB20000
	ld xbc, 0x1C0000A
	lds32 xde, 0
	call ApDeliveryEvent

MiddleCmpClr_ReturnZero:
	lds32 xhl, 0
	ret
__pad_F6985D:

MainCmpCpFunc:
	lda xsp, (xsp - 18)
	push xiz
	ld xde, xbc
	ld xiy, 0xE4C038
	lda xix, (xsp + 10)
	lds bc, 6
	ldirw
	cp xde, 0x1E40003
	jr z, MainCmpCp_HandleEvent03
	cp xde, 0x1E40002
	jrl nz, MainCmpSet_Case4
	pushw 0x11
	call Malloc
	inc 2, xsp
	ld xiz, xhl
	ld xwa, 0x28000
	call SndParam_LookupReadOnly
	ld (xsp + 7), l
	ld xwa, 0x28001
	call SndParam_LookupReadOnly
	lda xwa, (xsp + 4)
	ld (xwa + 4), l
	ld (xwa + 2), 0x48
	call SndParam_ResolveVoiceEntry
	ld a, (xsp + 4)
	extz wa
	call AccVoice_CopyFromROM_Wrap
	extz xhl
	pushw 0x10
	push xhl
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld (xiz + 16), 0x0
	ld xwa, 0xB8001E
	ld xbc, 0x1E40004
	ld xde, xiz
	call ApDeliveryEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E00023
	ld xde, xiz
	jrl MainCmpSet_Case3

MainCmpCp_HandleEvent03:
	pushw 0xF
	call Malloc
	inc 2, xsp
	ld xiz, xhl
	ld xwa, 0x28000
	call SndParam_LookupReadOnly
	ld (xsp + 7), l
	ld xwa, 0x28001
	call SndParam_LookupReadOnly
	lda xwa, (xsp + 4)
	ld (xwa + 4), l
	ld (xwa + 2), 0x48
	call SndParam_ResolveVoiceEntry
	lda xbc, (xsp + 4)
	ld a, (xbc)
	extz wa
	ld c, (xbc + 1)
	extz bc
	call AccVoice_DispatchWithChannel
	extz xhl
	cpdi8 36152, 184
	jr nz, MemCopy_SetupParams
	lda xbc, (xsp + 4)
	ld a, (xbc + 3)
	cp a, 0x80
	jr c, MemCopy_SetupParams
	cp (xbc + 4), 0x0
	jr nz, MemCopy_SetupParams
	res 7, a
	cps a, 4
	jr nc, MainCmpCp_ClampRange4
	ldb a, 0x0
	jr MainCmpCp_StoreClampResult

MainCmpCp_ClampRange4:
	cp a, 0x8
	jr nc, MainCmpCp_ClampRange8
	ldb a, 0x1
	jr MainCmpCp_StoreClampResult

MainCmpCp_ClampRange8:
	ldb a, 0x2

MainCmpCp_StoreClampResult:
	pushw 0xD
	extz wa
	sla wa, 2
	lda xbc, (xsp + 12)
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	push xwa
	jr MainCmpCp_MemCopyAndFinalize

MemCopy_SetupParams:
	pushw 0xD
	push xhl

MainCmpCp_MemCopyAndFinalize:
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld (xiz + 13), 0x0
	ldda8 a, 36152
	cp a, 0xB8
	jr nz, MainCmpSet_Init
	ld xwa, 0xB8001F
	ld xbc, 0x1E40005
	ld xde, xiz
	jr MainCmpSet_Case1

; MainCmpSetFunc init
MainCmpSet_Init:
	cp a, 0xDC
	jr nz, MainCmpSet_Case2
	ld xwa, 0xDC0002
	ld xbc, 0x1E40005
	ld xde, xiz

; MainCmpSetFunc case 1
MainCmpSet_Case1:
	call ApDeliveryEvent

; MainCmpSetFunc case 2
MainCmpSet_Case2:
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E00023
	ld xde, xiz

; MainCmpSetFunc case 3
MainCmpSet_Case3:
	call ApPostEvent

; MainCmpSetFunc case 4
MainCmpSet_Case4:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 18)
	ret
; CmpSongTtlFunc main handler
CmpSong_MainHandler:
MainCmpSetFunc:
	dec 4, xsp
	ld (xsp), xde
	ldda8 a, 13526
	extz wa
	sla wa, 2
	lda_24 xde, 0xe46312
	ld xhl, 0x94860
	add_sril_rm XHL, 0x07, 0xE8, 0xE0
	ld xde, xhl
	ld xhl, xbc
	ld xwa, (xsp)
	ld c, a
	sub xhl, 0x1E40008
	cp xhl, 0x0
	jrl lt, CmpSong_VariantA
	cp xhl, 0x7
	jrl gt, CmpSong_VariantA
	add xhl, xhl
	add xhl, 0xE4C06E
	ld hl, (xhl)
	lda_24 xix, 0xf69a0c
	jp_dri 8, 0x07, 0xF0, 0xEC
; MainCmpSetFunc dispatch
MainCmpSet_Dispatch:
	ld	xwa, (xsp)
	sll	xwa, 3
	add	xwa, 16
	add	xwa, xde
	inc	2, xwa
	ld	c, (xwa)
	cp	c, 127
	jrl	nc, 292
	inc	1, c
	ld	(xwa), c
	ld	xwa, (xsp)
	ld	de, wa
	extz	xde
	add	xde, 65536
	ld	xwa, 11796494
	ld	xbc, 31457421
	jrl	259
	ld	xwa, (xsp)
	sll	xwa, 3
	add	xwa, 16
	add	xwa, xde
	inc	2, xwa
	ld	c, (xwa)
	cps	c, 0
	jrl	z, 241
	dec	1, c
	ld	(xwa), c
	ld	xwa, (xsp)
	ld	de, wa
	extz	xde
	add	xde, 65536
	ld	xwa, 11796494
	ld	xbc, 31457421
	jrl	208
	ld	xwa, (xsp)
	sll	xwa, 3
	add	xwa, 16
	add	xwa, xde
	inc	5, xwa
	ld	c, (xwa)
	cp	c, 11
	jrl	nc, 189
	inc	1, c
	ld	(xwa), c
	ld	xwa, (xsp)
	ld	de, wa
	extz	xde
	add	xde, 131072
	ld	xwa, 11796494
	ld	xbc, 31457421
	jrl	156
	ld	xwa, (xsp)
	sll	xwa, 3
	add	xwa, 16
	add	xwa, xde
	inc	5, xwa
	ld	c, (xwa)
	cps	c, 0
	jrl	z, 138
	dec	1, c
	ld	(xwa), c
	ld	xwa, (xsp)
	ld	de, wa
	extz	xde
	add	xde, 131072
	ld	xwa, 11796494
	ld	xbc, 31457421
	jr	106
	ld	a, c
	stda8	13632, c
	cps	c, 2
	jr	ule, 6
	.byte 0xc9
	jr	gt, 0xf1
	.asciz "@5A:;<> "
	.byte 0x1d, 0x86, 0x52, 0xf6, 0x5e
	.byte 0x5c, 0x5b, 0x5a, 0xa7, 0x20, 0xd8, 0x8a, 0xea
	.byte 0x12, 0xea, 0xc8, 0x00, 0x00, 0x01, 0x00, 0x40
	.byte 0x07, 0x00, 0xb4, 0x00, 0x41, 0x8d, 0x00, 0xe0
	.byte 0x01, 0x68, 0x34, 0xcb, 0x89, 0xf1, 0x40, 0x35
	.byte 0x43, 0xcb, 0xda, 0x63, 0x06, 0xc9, 0x6a, 0xf1
	.ascii "@5A:;<> "
	.byte 0x80, 0x1d, 0x86, 0x52, 0xf6, 0x5e, 0x5c, 0x5b
	.byte 0x5a, 0xa7, 0x20, 0xd8, 0x8a, 0xea, 0x12, 0xea
	.byte 0xc8, 0x00, 0x00, 0x01, 0x00, 0x40, 0x07, 0x00
	.byte 0xb4, 0x00, 0x41, 0x8d, 0x00, 0xe0, 0x01, 0x1d
	.byte 0x07, 0x9e, 0xfa

; CmpSong variant A
CmpSong_VariantA:
	lds32 xhl, 0
	inc 4, xsp
	ret
__pad_F69B4C:

MainEsCmpFunc:
	dec 4, xsp
	ld (xsp), xde
	ld xde, (xsp)
	ld a, e
	dec 2, a
	cp xbc, 0x1E4002A
	jrl z, EsCmp_HandleEvent2A
	cp xbc, 0x1E40029
	jrl z, EsCmp_HandleEvent29
	cp xbc, 0x1E40028
	jr z, EsCmp_HandleEvent28
	cp xbc, 0x1E40027
	jrl nz, EsCmp_ReturnZero
	stda8 14776, a
	push xde
	push xhl
	push xix
	push xiz
	ldb a, 0x0
	call DrumParam_ProcessChannel
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld wa, de
	extz xde
	add xde, 0x10000
	ld xwa, 0xBA000A
	ld xbc, 0x1E0008D
	call ApDeliveryEvent
	ld xwa, (xsp)
	ld de, wa
	extz xde
	add xde, 0x20000
	ld xwa, 0xBA000A
	ld xbc, 0x1E0008D
	jrl MspBksl_EventDeliver

EsCmp_HandleEvent28:
	stda8 14776, a
	push xde
	push xhl
	push xix
	push xiz
	ldb a, 0x80
	call DrumParam_ProcessChannel
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld xwa, (xsp)
	ld de, wa
	extz xde
	add xde, 0x10000
	ld xwa, 0xBA000A
	ld xbc, 0x1E0008D
	call ApDeliveryEvent
	ld xwa, (xsp)
	ld de, wa
	extz xde
	add xde, 0x20000
	ld xwa, 0xBA000A
	ld xbc, 0x1E0008D
	jr MspBksl_EventDeliver

EsCmp_HandleEvent29:
	stda8 14776, a
	push xde
	push xhl
	push xix
	push xiz
	ldb a, 0x0
	call DrumParam_ProcessChannelAlt
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld xwa, (xsp)
	ld de, wa
	extz xde
	add xde, 0x20000
	ld xwa, 0xBA000A
	ld xbc, 0x1E0008D
	jr MspBksl_EventDeliver

EsCmp_HandleEvent2A:
	stda8 14776, a
	push xde
	push xhl
	push xix
	push xiz
	ldb a, 0x80
	call DrumParam_ProcessChannelAlt
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld xwa, (xsp)
	ld de, wa
	extz xde
	add xde, 0x20000
	ld xwa, 0xBA000A
	ld xbc, 0x1E0008D

MspBksl_EventDeliver:
	call ApDeliveryEvent

EsCmp_ReturnZero:
	lds32 xhl, 0
	inc 4, xsp
	ret
__pad_F69C5B:

MspBkslTtlFunc:
	lds32 xhl, 0
	ret
__pad_F69C5E:

MainMspBnkNameFunc:
	lds32 xhl, 0
	ret

SoundCtrl_SendAccTempo:
	cpdi8 36152, 181
	ret nz
	ld xwa, 0xB5001E
	ld xbc, 0x1C0000B
	lds32 xde, 0
	call ApDeliveryEvent
	ret

SoundCtrl_SendTempoScaled:
	cpdi8 36152, 181
	ret nz
	calr SoundCtrl_CalcScaledTempo
	ld xwa, 0xB50002
	ld xbc, 0x1C0000B
	lds32 xde, 0
	call ApDeliveryEvent
	ret

SoundCtrl_CalcScaledTempo:
	ld xhl, 0x64
	ldda16 xbc, 13524
	extz xbc
	ld xwa, xhl
	call Math_MultiplyAccumulate
	ld xwa, xhl
	ld xbc, 0xBE
	call Math_DivideU32
	cp xhl, 0x63
	jr ule, SoundCtrl_CalcTempo_Clamp
	ld xhl, 0x63

SoundCtrl_CalcTempo_Clamp:
	stda8 14763, l
	ret

AccGuard_ProgramChangeCheck:
	; --- Multi-condition guard with conditional calls (85 bytes) ---
	ldda8	c, 49278
	ldda8	a, 49277
	cps	a, 5
	jr nz, AccGuard_CheckMode09
	cpdi8	49279, 0
	jr z, AccGuard_CheckMode09
	cps	c, 2
	ret nz
	jr t, AccGuard_SendProgramChange
AccGuard_CheckMode09:
	cp a, 0x09
	ret nz
	cpdi8	49279, 0
	ret z
	cp c, 0x40
	ret nz
	ldda8	a, 36150
	cp a, 0xcb
	ret z
	cp a, 0xcc
	ret z
	ldw wa, 0x00c8
	call SoundCtrl_SendCommand
	ret
AccGuard_SendProgramChange:
	ld xwa, 0x00028080
	call SndParam_LookupReadOnly
	cps	hl, 0
	ret z
	ldw wa, 0x00ed
	call SoundCtrl_SendCommand
	ret


AccSeq_DeliverC9_0009:
	cpdi8 36152, 201
	ret nz
	ld xwa, 0xC90009
	ld xbc, 0x1C0000B
	lds32 xde, 0
	call ApDeliveryEvent
	ret

AccSeq_DeliverC9_000A:
	cpdi8 36152, 201
	ret nz
	ld xwa, 0xC9000A
	ld xbc, 0x1C0000B
	lds32 xde, 0
	call ApDeliveryEvent
	ret
__pad_F69D47:

MainMspRgpSetFunc:
	ldda8 a, 32573
	sll a, 4
	ldb w, 0x0
	extz xwa
	add xwa, 0x1E8A00
	ld xiy, xwa
	ld ix, de
	extz xix
	ld xhl, xix
	add xhl, 0x10000
	ld xwa, xde
	add xwa, xwa
	ld xde, xix
	add xde, 0x20000
	dec 4, xwa
	ld xix, xwa
	add xix, xiy
	lda xwa, (xix + 1)
	cp xbc, 0x1E40015
	jr z, MspMenuTtl_Case1
	cp xbc, 0x1E40014
	jr z, MspMenuTtl_Init
	cp xbc, 0x1E40013
	jr z, MspRgpSet_HandleEvent13
	cp xbc, 0x1E40012
	jrl nz, AccBass_ReturnZero
	cpdi8 32523, 0
	jr nz, AccBass_ReturnZero
	ld xbc, xix
	ld a, (xix)
	cp a, 0xE
	jr nc, AccBass_ReturnZero
	inc 1, a
	ld (xbc), a
	ld xwa, 0xCC0003
	ld xbc, 0x1E0008D
	ld xde, xhl
	jr AccBass_EventDeliver

MspRgpSet_HandleEvent13:
	cpdi8 32523, 0
	jr nz, AccBass_ReturnZero
	ld xbc, xix
	ld a, (xix)
	cps a, 0
	jr z, AccBass_ReturnZero
	dec 1, a
	ld (xbc), a
	ld xwa, 0xCC0003
	ld xbc, 0x1E0008D
	ld xde, xhl
	jr AccBass_EventDeliver

; MspMenuTtlFunc init
MspMenuTtl_Init:
	cpdi8 32523, 0
	jr nz, AccBass_ReturnZero
	ld xbc, xwa
	ld a, (xwa)
	cps a, 5
	jr nc, AccBass_ReturnZero
	inc 1, a
	ld (xbc), a
	ld xwa, 0xCC0003
	ld xbc, 0x1E0008D
	jr AccBass_EventDeliver

; MspMenuTtlFunc case 1
MspMenuTtl_Case1:
	cpdi8 32523, 0
	jr nz, AccBass_ReturnZero
	ld xbc, xwa
	ld a, (xwa)
	cps a, 0
	jr z, AccBass_ReturnZero
	dec 1, a
	ld (xbc), a
	ld xwa, 0xCC0003
	ld xbc, 0x1E0008D

AccBass_EventDeliver:
	call ApDeliveryEvent

AccBass_ReturnZero:
	lds32 xhl, 0
	ret
; MspMenuTtlFunc case 2
MspMenuTtl_Case2:
MspMenuTtlFunc:
	cp xbc, 0x1C00013
	jr nz, MspNameTtl_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jr c, MspNameTtl_ReturnZero
	cp xde, 0x6
	jr ugt, MspNameTtl_ReturnZero
	add xde, xde
	add xde, 0xE4C086
	ld de, (xde)
	lda_24 xix, 0xf69e50
	jp_dri 8, 0x07, 0xF0, 0xE8
; MspMenuTtlFunc title dispatch
MspMenuTtl_Dispatch:
	ld	xwa, 165888
	call	16569399
	cp	l, 13
	jr	c, 5
	cp	l, 16
	jr	ule, 4
	ldb	l, 0
	jr	3
	sub	l, 13
	stda8	32574, l
	ld	a, l
	sll	a, 4
	cps	l, 2
	jr	nc, 12
	ldb	w, 0
	extz	xwa
	add	xwa, 2001536
	jr	13
	sub	a, 32
	ldb	w, 0
	extz	xwa
	add	xwa, 2001472
	pushw	16
	push	xwa
	pushw	0
	pushw	13500
	call	16714995
	lda	xsp, (xsp+10)
	stdi8	13516, 0

MspNameTtl_ReturnZero:
	lds32 xhl, 0
	ret
; MspNameTtlFunc mode 1
MspNameTtl_Mode1:
MspNameTtlFunc:
	cp xbc, 0x1C00013
	jr nz, MspRecMode_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jr c, MspRecMode_ReturnZero
	cp xde, 0x6
	jr ugt, MspRecMode_ReturnZero
	add xde, xde
	add xde, 0xE4C094
	ld de, (xde)
	lda_24 xix, 0xf69ed7
	jp_dri 8, 0x07, 0xF0, 0xE8
; MspNameTtlFunc title dispatch
MspNameTtl_Dispatch:
	cpdi8	36151, 203
	jr	z, 20
	ldda8	c, 32574
	add	c, 13
	extz	bc
	ld	xwa, 165888
	lds	de, 0
	call	16568833
	cpdi8	36151, 204
	jr	z, 19
	ld	xwa, 13369347
	ld	xbc, 31457422
	ld	xde, 4294901762
	call	16424455

MspRecMode_ReturnZero:
	lds32 xhl, 0
	ret
; MspNameTtlFunc mode 2
MspNameTtl_Mode2:
MspRecModeFunc:
	cp xbc, 0x1C00013
	jr nz, MspNameTtl_Mode4
	cp xde, 0x1
	jr z, MspNameTtl_Mode3
	or xde, xde
	jr nz, MspNameTtl_Mode4

; MspNameTtlFunc mode 3
MspNameTtl_Mode3:
	stdi8 32523, 0

; MspNameTtlFunc mode 4
MspNameTtl_Mode4:
	lds32 xhl, 0
	ret
; MspNameTtlFunc mode 5
MspNameTtl_Mode5:
MspRecTtlFunc:
	cp xbc, 0x1E4001F
	jrl z, MspRecTtl_SubA
	cp xbc, 0x1C00013
	jrl nz, MspRecTtl_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, MspRecTtl_ReturnZero
	cp xde, 0x6
	jrl ugt, MspRecTtl_ReturnZero
	add xde, xde
	add xde, 0xE4C0A2
	ld de, (xde)
	lda_24 xix, 0xf69f65
	jp_dri 8, 0x07, 0xF0, 0xE8
; MspRecTtlFunc title dispatch
MspRecTtl_Dispatch:
	cpdi8	36151, 201
	jr	z, 61
	ld	xwa, 164099
	lds	bc, 0
	lds	de, 3
	call	16568833
	ld	xwa, 165888
	call	16569399
	cp	l, 13
	jr	z, 5
	cp	l, 14
	jr	nz, 29
	ldda8	a, 32532
	sll	a, 4
	ldb	w, 0
	extz	xwa
	add	xwa, 2000928
	ld	a, (xwa)
	and	a, 16
	srl	a, 4
	stda8	32575, a
	lds	wa, 0
	call	16356645
	jr	71
	cpdi8	36150, 201
	jr	z, 64
	cpdi8	32523, 0
	jr	z, 57
	stdi8	32523, 0
	jr	50

; MspRecTtlFunc sub-handler A
MspRecTtl_SubA:
	ld xwa, 0x28800
	call SndParam_LookupReadOnly
	cp l, 0xD
	jr z, MspRecTtl_SubA_CheckRange
	cp l, 0xE
	jr nz, MspRecTtl_ReturnZero

MspRecTtl_SubA_CheckRange:
	ldda8 a, 32532
	sll a, 4
	ldb w, 0x0
	extz xwa
	add xwa, 0x1E8820
	ldda8 c, 32575
	and c, 0x1
	sll c, 4
	resm 4, (xwa)
	or (xwa), c

MspRecTtl_ReturnZero:
	lds32 xhl, 0
	ret

AccSeq_PostEvent9E_Enable:
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	jp ApPostEvent

AccSeq_PostEvent9E_Disable:
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	jp ApPostEvent
AccSeq_DcModeDataBlock:
	cpdi8	36152, 220
	ret	nz
	ld	xwa, 14417925
	ld	xbc, 29360143
	lds32	xde, 0
	call	16424455
	ret
; SndArgTtlFunc sub-handler A
SndArgTtl_SubA:
SndArgModeFunc:
	cp xbc, 0x1C00013
	jr nz, AccStyle_ExitReturn
	cp xde, 0x1
	jr z, SndArgTtl_SubB
	or xde, xde
	jr nz, AccStyle_ExitReturn
	push xde
	push xhl
	push xix
	push xiz
	call AccStyle_ModeEnter_Wrap
	pop xiz
	pop xix
	pop xhl
	pop xde
	jr AccStyle_ExitReturn

; SndArgTtlFunc sub-handler B
SndArgTtl_SubB:
	push xde
	push xhl
	push xix
	push xiz
	call AccStyle_ModeExit_Wrap
	pop xiz
	pop xix
	pop xhl
	pop xde

AccStyle_ExitReturn:
	lds32 xhl, 0
	ret
; SndArgTtlFunc sub-handler C
SndArgTtl_SubC:
SndArgTtlFunc:
	cp xbc, 0x1C00013
	jr nz, SndArgTtl_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jr c, SndArgTtl_ReturnZero
	cp xde, 0x6
	jr ugt, SndArgTtl_ReturnZero
	add xde, xde
	add xde, 0xE4C0B0
	ld de, (xde)
	lda_24 xix, 0xf6a092
	jp_dri 8, 0x07, 0xF0, 0xE8
; SndArgTtlFunc title dispatch
SndArgTtl_Dispatch:
	cpdi8	36151, 220
	jr	z, 19
	ld	xwa, 14417925
	ld	xbc, 31457422
	ld	xde, 4294901762
	call	16424455
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	16107220
	.ascii "^\\[Z"

SndArgTtl_ReturnZero:
	lds32 xhl, 0
	ret
__pad_F6A0BB:

SndArgNmGet:
	lda xsp, (xsp - 76)
	push_werp 0xFA
	ld (xsp + 70), xde
	ld (xsp + 74), xbc
	ld xiy, 0xE4C0BE
	lda xix, (xsp + 66)
	ldiw
	ldiw
	ld xiy, 0xE4C0C6
	lda xix, (xsp + 58)
	lds bc, 4
	ldirw
	ld xiy, 0xE4C0D6
	lda xix, (xsp + 52)
	lds bc, 2
	ldirw
	ldi85
	ld xiy, 0xE4C0DC
	lda xix, (xsp + 32)
	ldw bc, 0xA
	ldirw
	ld xiy, 0xE4C0F0
	lda xix, (xsp + 12)
	ldw bc, 0xA
	ldirw
	ld xwa, 0x28000
	call SndParam_LookupReadOnly
	ld (xsp + 9), l
	ld xwa, 0x28001
	call SndParam_LookupReadOnly
	lda xwa, (xsp + 6)
	ld (xwa + 4), l
	ld (xwa + 2), 0x48
	call SndParam_ResolveVoiceEntry
	ldw (xsp + 2), 0x0
	ld (xsp + 4), 0x0
	jr SndArgNm_CheckChannelDone

SndArgNm_ChannelLoop:
	ld a, (xsp + 4)
	call AccVoice_GetChannelCount_Wrap
	ldfr_berp L, 0xFB
	inc1_berp 0xFB
	ldto_berp A, 0xFB
	extz wa
	add (xsp + 2), wa
	incm8 1, (xsp + 4)

SndArgNm_CheckChannelDone:
	lda xbc, (xsp + 6)
	ld xde, (xsp + 70)
	dec 2, xde
	ld xhl, (xsp + 70)
	add xhl, xhl
	ld a, (xsp + 4)
	cp a, (xbc)
	jr c, SndArgNm_ChannelLoop
	ld a, (xbc + 1)
	extz wa
	add (xsp + 2), wa
	ld wa, (xsp + 2)
	mul wa, 0xA
	extz xwa
	add xwa, 0x1E7810
	ld xix, xwa
	lda xwa, (xsp + 52)
	ld (xsp + 2), xwa
	dec 4, xhl
	ld xwa, (xsp + 74)
	cp xwa, 0x1E40024
	jrl z, SndArgNm_HandleEvent24
	add xhl, xix
	cp xwa, 0x1E40021
	jrl z, SndArgNm_HandleEvent21
	cp xwa, 0x1E40020
	jrl nz, SndArgNm_ReturnZero
	ld xix, xhl
	ld a, (xhl)
	ldfr_berp A, 0xFB
	ld xiy, xde
	or xde, xde
	jr nz, SndArgNm_ProcessEntry
	or_erpb 0xFB, 0xF0

SndArgNm_ProcessEntry:
	lda xde, (xbc + 3)
	ldto_berp A, 0xFB
	ld (xde), a
	ld a, (xix + 1)
	res 7, a
	ldfr_berp A, 0xFB
	lda xhl, (xbc + 4)
	ldto_berp A, 0xFB
	ld (xhl), a
	ld xwa, (xsp + 2)
	add xwa, xiy
	ld a, (xwa)
	ldfr_berp A, 0xFB
	ld (xbc + 2), a
	ld xwa, (xsp + 70)
	dec 2, a
	ldfr_berp A, 0xFB
	ld a, (xde)
	extz wa
	ld c, (xhl)
	extz bc
	ldto_berp E, 0xFB
	extz de
	sla de, 2
	lda xhl, (xsp + 32)
	ld_sril3 XDE, 0x07, 0xEC, 0xE8
	call SndParam_ApplyProgramChangeAsync
	ldto_berp A, 0xFB
	extz wa
	sla wa, 2
	lda xbc, (xsp + 32)
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld (xwa + 16), 0x0
	ld xwa, (xsp + 70)
	ld de, wa
	extz xde
	add xde, 0x10000
	ld xwa, 0xDC0005
	ld xbc, 0x1E40022
	jrl SndArgNm_DeliverAndReturn

SndArgNm_HandleEvent21:
	or xde, xde
	jr nz, SndArgNm_HandleEvent21_Copy
	pushw 0x3
	ld xwa, (xsp + 68)
	push xwa
	pushw 0x0
	pushw 0x39E4
	call Mem_Copy
	lda xsp, (xsp + 10)
	stdi8 14823, 0
	jr SndArgNm_DeliverEvent

SndArgNm_HandleEvent21_Copy:
	ld a, (xhl + 1)
	and a, 0x80
	srl a, 7
	ldfr_berp A, 0xFB
	ld xwa, (xsp + 70)
	ld e, a
	dec 2, e
	pushw 0x3
	ldto_berp A, 0xFB
	extz wa
	sla wa, 2
	lda xbc, (xsp + 60)
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	push xwa
	extz de
	sla de, 2
	lda xbc, (xsp + 18)
	ld_sril3 XWA, 0x07, 0xE4, 0xE8
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	ldto_berp A, 0xFB
	extz wa
	sla wa, 2
	lda xbc, (xsp + 12)
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld (xwa + 3), 0x0

SndArgNm_DeliverEvent:
	ld xwa, (xsp + 70)
	ld de, wa
	extz xde
	add xde, 0x20000
	ld xwa, 0xDC0005
	ld xbc, 0x1E40023

SndArgNm_DeliverAndReturn:
	call ApDeliveryEvent
	jr SndArgNm_ReturnZero

SndArgNm_HandleEvent24:
	ld xwa, (xsp + 2)
	add xwa, xde
	mrib4 0x80, 0x19, 0x3A, 0x8D
	ldda8 e, 36154
	extz de
	pushw 0xFF
	ldw wa, 0x90
	ldw bc, 0x10
	call AddswbWr
	ldmm8 13199, 13198

SndArgNm_ReturnZero:
	lds32 xhl, 0
	pop_werp 0xFA
	lda xsp, (xsp + 76)
	ret
__pad_F6A2E2:

CmpStepTitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, 0xE4C104
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

CmpStep_DataBlock:
	cpdi8	36151, 182
	jr	z, 25
	ldw	wa, 255
	call	16454736
	ldw	wa, 245
	call	16454730
	call	16454839
	ldw	wa, 255
	call	16454742
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	16163741
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	16163951
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
	push	xde
	push	xhl
	push	xix
	push	xiz
	.byte 0x1d, 0x7a
	cp	xiz, (xix)
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
	ret

AccAudio_LockAcquire:
	ldw wa, 0x8
	jp Audio_Lock_Acquire

AccAudio_LockRelease:
	ldw wa, 0x8
	jp Audio_Lock_Release
AccAudio_DataBlock1:
	ld	xwa, xiy
	ld	xbc, xix
	call	16455060
	ret

AccGraphics_RenderStart:
	push xwa
	push xbc
	ld xwa, xiy
	ld xbc, xix
	call GraphicsRender_Start
	pop xbc
	pop xwa
	ret

AccGraphics_DataBlock2:
	push	xwa
	ld	xwa, xiy
	call	16458955
	pop	xwa
	ret

AccDraw_Init:
	push xwa
	ld xwa, xiy
	call DrawFunc_Init
	pop xwa
	ret

AccDraw_Secondary:
	push xwa
	ld xwa, xiy
	call DrawText_ExtendedLayout
	pop xwa
	ret

AccScreen_DataBlock:
	push	xwa
	ld	xwa, xiy
	pop	xwa
	ret
	push	xwa
	ld	xwa, xiy
	call	16458241
	pop	xwa
	ret
	push	xwa
	ld	xwa, xiy
	call	16459064
	pop	xwa
	ret
	push	xiz
	calr	2
	pop	xiz
	ret
	cpdi8	36151, 182
	jr	z, 19
	call	16126864
	stdi8	13605, 182
	.byte 0xc1, 0xe0, 0xe3, 0x3c, 0xef, 0xc1, 0xde, 0xe3, 0x3c, 0xef
	call	16142485
	.byte 0xf1, 0xe0, 0xe3, 0xcc
	jr	nz, 12
	ld	xwa, 16163808
	push	xwa
	call	16426220
	inc	4, xsp
	ld	xwa, 16163840
	push	xwa
	call	16426220
	inc	4, xsp
	ret
	calr	1530
	sti8_24	257960, 2
	ld	xiy, 16165386
	ld	xix, 16165681
	calr	-161
	calr	773
	calr	795
	calr	1176
	ret
	calr	726
	sti8_24	257960, 1
	ld	xiy, 16165992
	calr	-125
	calr	1155
	sti8_24	257960, 0
	calr	1492
	.byte 0xc1, 0xd6, 0x34, 0x19, 0xbb, 0x39, 0xc1, 0x42, 0x37, 0x19, 0xbc, 0x39, 0xc1, 0x43, 0x37, 0x19, 0xbd, 0x39, 0xc1, 0x44, 0x37, 0x19, 0xbe, 0x39, 0xc1, 0x45, 0x37, 0x19, 0xbf, 0x39, 0xc1, 0x1a, 0x37, 0x19, 0xc0, 0x39
	ld	xiy, 16165822
	ld	xix, 16165933
	calr	-240
	sti8_24	257960, 0
	.byte 0xc1, 0x12, 0x37, 0x19, 0xbb, 0x39
	ld	xiy, 16165950
	calr	-229
	calr	765
	calr	1095
	calr	978
	calr	1402
	ret
	push	xiz
	calr	2
	pop	xiz
	ret
	call	16142519
	ret
	push	xiz
	calr	2
	pop	xiz
	ret
	ld	xix, 16163977
	calr	81
	ret
	sub	iy, (xiz)
	.byte 0xf6
	nop
	.byte 0xa8, 0xa5, 0xf6
	nop
	.byte 0xc6
	cp	xiz, (xiy)
	nop
	.byte 0xe4, 0xa5, 0xf6
	nop
	.byte 0x04
	cp	xiz, (xiz)
	nop
	ldb	d, 166
	.byte 0xf6
	nop
	.byte 0x56
	cp	xiz, (xiz)
	nop
	jr	z, -90
	.byte 0xf6
	nop
	jrl	z, -2394
	nop
	sub	iz, (xwa)
	.byte 0xf6
	nop
	.byte 0xaa, 0xa6, 0xf6
	nop
	.byte 0xb5, 0xa6, 0xf6
	nop
	.byte 0xc0, 0xa6, 0xf6
	nop
	.byte 0xc1, 0xa6, 0xf6, 0x00
	andda8_24	c, 63142
	cp	xiz, (xiz)
	nop
	.byte 0xd5, 0xa6, 0xf6
	nop
	.byte 0xd6
	cp	xiz, (xiz)
	nop
	.byte 0xd7, 0xa6, 0xf6
	nop
	sub	iz, wa
	.byte 0xf6
	nop
	cp	hl, 15
	jr	ugt, 27
	ld	e, l
	inc	1, e
	calr	21
	.byte 0xc1, 0xe2, 0xe3, 0x3c, 0xfe
	ld	xbc, xhl
	and	l, 31
	sla	l, 2
	.byte 0xe3, 0x03, 0xf0, 0xec, 0x24
	call	(xix)
	ret
	push	xix
	cp	e, 32
	jr	ule, 2
	xor	e, e
	sla	e, 2
	ld	xix, 16164114
	.byte 0xe3, 0x03, 0xf0, 0xe8, 0x22
	pop	xix
	ret
	nop
	nop
	nop
	nop
	.byte 0x01
	nop
	nop
	nop
	.byte 0x02
	nop
	nop
	nop
	.byte 0x04
	nop
	nop
	nop
	ldio	0, 0
	nop
	rcf
	nop
	nop
	nop
	ldb	w, 0
	nop
	nop
	ld	xwa, 2147483648
	nop
	nop
	nop
	nop
	.byte 0x01
	nop
	nop
	nop
	.byte 0x02
	nop
	nop
	nop
	.byte 0x04
	nop
	nop
	nop
	ldio	0, 0
	nop
	rcf
	nop
	nop
	nop
	ldb	w, 0
	nop
	nop
	ld	xwa, 2147483648
	nop
	nop
	nop
	nop
	.byte 0x01
	nop
	nop
	nop
	.byte 0x02
	nop
	nop
	nop
	.byte 0x04
	nop
	nop
	nop
	ldio	0, 0
	nop
	rcf
	nop
	nop
	nop
	ldb	w, 0
	nop
	nop
	ld	xwa, 2147483648
	nop
	nop
	nop
	nop
	.byte 0x01
	nop
	nop
	nop
	.byte 0x02
	nop
	nop
	nop
	.byte 0x04
	nop
	nop
	nop
	ldio	0, 0
	nop
	rcf
	nop
	nop
	nop
	ldb	w, 0
	nop
	nop
	ld	xwa, 2147483648
	bit	7, w
	jr	nz, 7
	.byte 0xc1, 0x13, 0x37, 0x3e, 0x40
	jr	5
	.byte 0xc1, 0x13, 0x37, 0x3e, 0x80
	ret
	cpdi8	14098, 4
	jr	nz, 22
	.byte 0xc1, 0xe2, 0xe3, 0x3e, 0x08
	bit	7, w
	jr	nz, 7
	.byte 0xc1, 0x2d, 0x37, 0x3e, 0x04
	jr	5
	.byte 0xc1, 0x2d, 0x37, 0x3e, 0x08
	ret
	cpdi8	14098, 4
	jr	nz, 22
	.byte 0xc1, 0xe2, 0xe3, 0x3e, 0x08
	bit	7, w
	jr	nz, 7
	.byte 0xc1, 0x2d, 0x37, 0x3e, 0x01
	jr	5
	.byte 0xc1, 0x2d, 0x37, 0x3e, 0x02
	ret
	.byte 0xc1, 0xe2, 0xe3, 0x3e, 0x08
	call	16142674
	ld	xwa, 16164346
	push	xwa
	call	16426220
	inc	4, xsp
	ret
	sti8_24	257960, 0
	calr	813
	ret
	.byte 0xc1, 0xe2, 0xe3, 0x3e, 0x08
	call	16142731
	ld	xwa, 16164378
	push	xwa
	call	16426220
	inc	4, xsp
	ret
	sti8_24	257960, 0
	calr	781
	ret
	.byte 0xc1, 0xe2, 0xe3, 0x3e, 0x08
	call	16142786
	cpdi8	14098, 4
	jr	nz, 12
	ld	xwa, 16164417
	push	xwa
	call	16426220
	inc	4, xsp
	ret
	sti8_24	257960, 0
	.byte 0xc1, 0x16, 0x37, 0x19, 0xbb, 0x39
	ld	xiy, 16166287
	calr	-728
	ret
	.byte 0xc1, 0xe2, 0xe3, 0x3e, 0x08, 0xc1, 0x13, 0x37, 0x3e, 0x02, 0xc1, 0x13, 0x37, 0x3c, 0xfe
	ret
	.byte 0xc1, 0xe2, 0xe3, 0x3e, 0x08, 0xc1, 0x13, 0x37, 0x3e, 0x01, 0xc1, 0x13, 0x37, 0x3c, 0xfd
	ret
	.byte 0xc1, 0xe2, 0xe3, 0x3e, 0x08
	bit	7, w
	jr	nz, 15
	.byte 0xf1, 0x9b, 0x37, 0xcb
	jr	nz, 9
	call	16142531
	.byte 0xc1, 0xe0, 0xe3, 0x3e, 0x10
	ret
	.byte 0xc1, 0xe2, 0xe3, 0x3e, 0x08
	bit	7, w
	jr	nz, 15
	.byte 0xf1, 0x9b, 0x37, 0xcc
	jr	nz, 9
	call	16142602
	.byte 0xc1, 0xe0, 0xe3, 0x3e, 0x10
	ret
	bit	7, w
	jr	nz, 5
	.byte 0xc1, 0x13, 0x37, 0x3e, 0x20
	ret
	bit	7, w
	jr	nz, 5
	.byte 0xc1, 0x13, 0x37, 0x3e, 0x04
	ret
	ret
	ret
	ret
	bit	7, w
	jr	nz, 12
	stdi8	58332, 181
	stdi8	58334, 128
	jr	0
	ret
	ret
	ret
	ret
	ret
	sti8_24	257960, 2
	cpdi8	14098, 4
	jr	nz, 15
	ld	xiy, 16165681
	ld	xix, 16165822
	calr	-926
	jr	8
	ld	xiy, 16165933
	calr	-873
	ret
	xor	wa, wa
	ld	xiy, 16166605
	ld	xix, xiy
	ldb	a, 35
	ldda8	c, 14142
	mul8rr	a, c
	extz	xwa
	add	xix, xwa
	calr	-961
	ret
	ld	xiy, 16166745
	ldda8	c, 14142
	calr	37
	ld	xiy, 16166835
	ldda8	c, 14143
	calr	25
	ld	xiy, 16166925
	ldda8	c, 14144
	calr	13
	ld	xiy, 16167015
	ldda8	c, 14145
	calr	1
	ret
	xor	wa, wa
	ld	xix, xiy
	add	xix, 10
	ldb	a, 20
	mul8rr	a, c
	cps	a, 0
	jr	z, 7
	extz	xwa
	add	xix, xwa
	calr	-1036
	ret
	ld	xiy, 14126
	ld	xix, 2601
	xor	de, de
	xor	bc, bc
	ld	xiz, 14142
	xor	wa, wa
	ld	a, e
	extz	xwa
	add	xiz, xwa
	ld	d, (xiz)
	cps	d, 0
	.ascii "fW8;9:<=>"
	.byte 0x1d, 0x47, 0xa3, 0xf6
	.ascii "^]\\ZY[XÛ"
	.byte 0xd3, 0xcb, 0x8f, 0xc3, 0x07, 0xf4, 0xec, 0x27
	and	l, 15
	.byte 0x1e, 0x54, 0x00
	add	xix, 4
	xor	hl, hl
	ld	l, c
	.byte 0xc3, 0x07, 0xf4, 0xec, 0x27
	and	l, 240
	srl	l, 4
	.byte 0x1e, 0x3c, 0x00
	add	xix, 4
	inc	1, c
	cp	c, d
	jr	c, 0xcd
	.ascii "8;9:<=>"
	.byte 0x1d, 0x4e, 0xa3, 0xf6, 0x5e, 0x5d, 0x5c
	.byte 0x5a, 0x59, 0x5b, 0x58
	.byte 0xcd, 0x61, 0xcd, 0xdc
	.byte 0x69, 0x17, 0xed, 0xc8, 0x04, 0x00, 0x00, 0x00
	.byte 0x21, 0x08, 0xcb, 0x41, 0xe8, 0x12, 0xe8, 0xa4
	.byte 0xec, 0xc8, 0xb0, 0x04, 0x00, 0x00, 0x78, 0x77
	.byte 0xff, 0x0e
	.byte 0x3d, 0x3c, 0x2a, 0x29, 0x45
	.byte 0x8d
	.byte 0xae, 0xf6, 0x00, 0xd9, 0xac, 0x21, 0x06, 0x40
	.byte 0xcc, 0x39, 0x00, 0x00, 0xb0, 0x00, 0x06, 0xb8
	.byte 0x01, 0x00, 0x08, 0xb8, 0x02, 0x54, 0xdb, 0x12
	.byte 0xeb, 0x12, 0xeb, 0xee, 0x02, 0xeb, 0x85, 0xc5
	.byte 0xf4, 0x27, 0xb8, 0x04, 0x47, 0xc5, 0xf4, 0x27
	.byte 0xb8, 0x05, 0x47, 0xc5, 0xf4, 0x27, 0xb8, 0x06
	.byte 0x47, 0x85, 0x27, 0xb8, 0x07, 0x47, 0x1d, 0x4e
	.byte 0x16, 0xfb
	.byte 0x49, 0x4a, 0x5c, 0x5d
	.byte 0x0e, 0xd8
	.byte 0xd0, 0xc1, 0x0f, 0x37, 0x21, 0xc9, 0xd8, 0x66
	.byte 0x02, 0xc9, 0x69, 0xc9, 0xcc, 0x7f, 0x23, 0x20
	.byte 0xcb, 0x51, 0xf1, 0xb9, 0x39, 0x41, 0xd8, 0xec
	.byte 0x01, 0xeb, 0xd3, 0xc8, 0x8f, 0x45, 0xc1, 0xb0
	.byte 0xf6, 0x00, 0xeb, 0x85, 0x95, 0x21, 0xf1, 0xc4
	.byte 0x39, 0x51, 0xd9, 0xc8, 0x06, 0x00, 0xf1, 0xc8
	.byte 0x39, 0x51, 0xeb, 0xd3, 0xc9, 0x8f, 0x45, 0x01
	.byte 0xb1, 0xf6, 0x00, 0xeb, 0x85, 0x95, 0x21, 0xf1
	.byte 0xc6, 0x39, 0x51, 0xd9, 0xc8, 0x08, 0x00, 0xf1
	.byte 0xca, 0x39, 0x51, 0x21, 0x05, 0x38, 0x40, 0xc2
	.byte 0x39, 0x00, 0x00, 0x1d, 0xb3, 0x1d, 0xfb, 0x58
	.byte 0x0e, 0xd8, 0xd0, 0xc1, 0x0f, 0x37, 0x21, 0xc9
	.byte 0xd8, 0x66, 0x02, 0xc9, 0x69, 0xc9, 0xcc, 0x7f
	.byte 0x23, 0x20, 0xcb, 0x51, 0xf1, 0xb9, 0x39, 0x41
	.byte 0x0e, 0xf2, 0xa8, 0xef, 0x03, 0x00, 0x00, 0xc1
	.byte 0x12, 0x37, 0x3f, 0x04, 0x66, 0x05, 0x1e, 0xd7
	.byte 0x00, 0x68, 0x20, 0xc1, 0x17, 0x37, 0x21, 0xc9
	.byte 0xcf, 0xff, 0x66, 0x06, 0x1e, 0x15, 0x00, 0x1e
	.byte 0x36, 0x00, 0x1e, 0x5d, 0x00, 0xc1, 0x16, 0x37
	.byte 0x19, 0xbb, 0x39, 0x45, 0x8f, 0xad, 0xf6, 0x00
	.byte 0x1e, 0x9c, 0xfa, 0x0e

AccScreen_DrawTempoDisplay:
	calr AccScreen_CalcTempoParams
	ld xiy, 0xF6AD37
	ld xix, 0xF6AD55
	calr AccGraphics_RenderStart
	ret

AccScreen_CalcTempoParams:
	xor wa, wa
	ldda8 a, 14104
	ldb l, 0xC
	divs8rr a, l
	stda8 14776, w
	stda8 14778, a
	ret

AccScreen_UpdateBeatDisplay:
	ldmm8 14779, 14103
	ld xiy, 0xF6AD55
	push xwa
	ld xwa, xiy
	call DrawText_LayoutAndRender
	pop xwa
	cpdi8 14103, 99
	jr ugt, AccScreen_BeatDisplay_Large
	ld xiy, 0xF6AD5D
	jr AccScreen_BeatDisplay_Draw

AccScreen_BeatDisplay_Large:
	ld xiy, 0xF6AD67

AccScreen_BeatDisplay_Draw:
	calr AccDraw_Init
	ret

AccScreen_BeatDataBlock:
	cpdi8	14098, 4
	jr	nz, 25
	.byte 0xc1, 0x14, 0x37, 0x19, 0xbb, 0x39, 0xc1, 0x15, 0x37, 0x19, 0xbc, 0x39
	ld	xiy, 16166257
	ld	xix, 16166287
	calr	-1522
	ret

AccScreen_DrawInit_StackWrap:
	ld xwa, 0xF6A95E
	push xwa
	call DrawFunc_StackEntry
	inc 4, xsp
	ret

AccScreen_DrawInit_Body:
	sti8_24 0x03efa8, 0x00
	calr AccScreen_DrawTempoDisplay
	ret

AccScreen_UpdateBeat_StackWrap:
	ld xwa, 0xF6A975
	push xwa
	call DrawFunc_StackEntry
	inc 4, xsp
	ret

AccScreen_UpdateBeat_Body:
	sti8_24 0x03efa8, 0x00
	calr AccScreen_UpdateBeatDisplay
	ret

AccScreen_DrawMeasure_StackWrap:
	ld xwa, 0xF6A98C
	push xwa
	call DrawFunc_StackEntry
	inc 4, xsp
	ret

AccScreen_DrawMeasure_Body:
	sti8_24 0x03efa8, 0x00
	calr AccScreen_DrawMeasureDetail
	ret

AccScreen_DrawMeasureDetail:
	ldda8 a, 14112
	dec 1, a
	stda8 14778, a
	ld xiy, 0xF6AC91
	calr AccDraw_Secondary
	ldda8 a, 14113
	stda8 14778, a
	cpdi8 14112, 3
	jr nz, AccScreen_DrawMeas_Other
	ldda8 a, 14113
	cps a, 0
	jr z, AccScreen_DrawMeas_Variant3
	stdi8 14778, 1

AccScreen_DrawMeas_Variant3:
	ld xiy, 0xF6AD18
	calr AccDraw_Secondary
	jr AccScreen_DrawMeas_Return

AccScreen_DrawMeas_Other:
	ld xiy, 0xF6AD2D
	calr AccDraw_Init

AccScreen_DrawMeas_Return:
	ret

AccScreen_UIDataBlock:
; Accompaniment engine screen data block
; Total: 2096 bytes (698 + 15 + 120 + 15 + 6 + 287 + 955)
; Screen data blocks compiled from C source, included as .incbin

; Accompaniment step recording UI data: 698 bytes
	sti8_24	257960, 0
	ldb	c, 0
	ldb	a, 12
	ldb	a, 16
	call	16454966
	ret
	ldb	c, 7
	ldb	a, 12
	call	16455007
	ret
	xor	wa, wa
	ldda8	a, 14235
	and	a, 31
	jr	z, 9
	srl	a, 1
	jr	c, 4
	inc	1, w
	jr	-9
	stda8	14776, w
	ret
	ldb	c, 5
	ldw	ix, 45
	reti
	ccf
	.byte 0x84, 0x00, 0x53, 0x54
	ld	xiy, 1163010128
	ld	xhl, 1229214287
	popw	iz
	ld	xsp, 70913056
	.byte 0x50
	ld	xbc, 1380275284
	popw	iz
	push	xde
	ldb	w, 9
	ldb	c, 4
	.byte 0x50
	ld	xbc, 104485970
	halt
	.byte 0xc4, 0x05, 0x8d
	ei	0x08
	.byte 0xe3, 0x08, 0x50
	ld	xbc, 84300882
	add	(xix+11), h
	ei	0x07
	.byte 0xcb, 0x11
	ld	xiy, 134632274
	ldwio	24, 17746
	.byte 0x53, 0x54
	reti
	halt
	.byte 0xef, 0x05
	scf
	reti
	halt
	.byte 0x8f, 0x0b, 0x11
	reti
	halt
	.byte 0xa7, 0x11
	scf
	reti
	halt
	.byte 0xe7, 0x17, 0x11
	ei	0x08
	pop_f
	.byte 0x1f
	popw	iy
	ld	xiy, 168186689
	push	xwa
	.byte 0x1f
	ld	xhl, 1330860629
	.byte 0x52
	ei	0x05
	ldb	b, 33
	.byte 0x8d, 0x06, 0x05
	pushw	de
	ldb	c, 142
	ei	0x05
	push	xhl
	ldb	a, 141
	ei	0x05
	ld	xhl, 84315683
	ldw	wa, 15394
	ei	0x05
	ldw	iy, 15906
	push 10
	pop_a
	.byte 0x01
	ldb	c, 0
	ldw	hl, 12801
	nop
	push 10
	zcf
	.byte 0x01
	ldb	a, 0
	ldw	iy, 13313
	nop
	push 10
	pop_a
	.byte 0x01
	ld	xsp, 1442919168
	nop
	push 10
	zcf
	.byte 0x01
	ld	xiy, 1476474112
	nop
	push 10
	pop_a
	.byte 0x01
	jr	nz, 0
	ldw	hl, 32001
	nop
	push 10
	zcf
	.byte 0x01, 0x6c, 0x00
	ldw	iy, 32513
	nop
	push 10
	decf
	.byte 0x01, 0x96, 0x00
	ldw	hl, 42241
	nop
	push 10
	pushw 37889
	nop
	ldw	iy, 42753
	nop
	ldwio	10, 12
	.byte 0xaa, 0x00, 0xfa
	nop
	.byte 0xc0, 0x00, 0x0a
	ldwio	5, 53760
	nop
	ldb	c, 0
	.byte 0xec, 0x00
	ldwio	10, 205
	ordm16_24	60160, ix
	nop
	ldwio	10, 245
	ordm16_24	70400, ix
	nop
	ldwio	10, 285
	ordm16_24	80640, ix
	nop
	.byte 0x01
	ldwio	5, 57088
	nop
	ldb	c, 0
	.byte 0xdf, 0x00, 0x01
	ldwio	205, 57088
	nop
	.byte 0xeb, 0x00, 0xdf, 0x00
	ei	0x15
	calr	19999
	popw sp
	.byte 0x54
	ld	xiy, 1279612448
	ldb	w, 32
	ldb	w, 76
	ld	xiy, 1213482830
	ei	0x14
	ldb	l, 33
	ld	w, (xiy+32)
	ldb	w, 32
	ld	w, (xiy+32)
	ldb	w, 32
	ld	w, (xiy+32)
	ldb	w, 32
	.byte 0x8d, 0x06, 0x14
	pushw sp
	ldb	c, 142
	ldb	w, 32
	ldb	w, 32
	ld	w, (xiz+32)
	ldb	w, 32
	ld	w, (xiz+32)
	ldb	w, 32
	.byte 0x8e, 0x0a, 0x0a
	pushw	iy
	nop
	ordm16_24	19200, ix
	nop
	ldwio	10, 85
	ordm16_24	29440, ix
	nop
	ldwio	10, 125
	ordm16_24	39680, ix
	nop
	ldwio	10, 165
	ordm16_24	49920, ix
	nop
	.byte 0x01
	ldwio	45, 57088
	nop
	popw	hl
	nop
	.byte 0xdf, 0x00, 0x01
	ldwio	85, 57088
	nop
	jrl	ule, -8448
	nop
	.byte 0x01
	ldwio	125, 57088
	nop
	.byte 0x9b, 0x00, 0xdf
	nop
	.byte 0x01
	ldwio	165, 57088
	nop
	.byte 0xc3, 0x00, 0xdf
	nop
	.byte 0x02
	retd	0x39bb
	swi	7
	nop
	ldb	w, 9
	.byte 0xb1, 0xf6
	nop
	reti
	nop
	.byte 0x1a, 0x04, 0x02
	retd	0x39b8
	reti
	nop
	ldb	w, 92
	.byte 0xae, 0xf6, 0x00
	ldio	0, 40
	.byte 0x04
	push_sr
	retd	0x39bc
	retd	0x0600
	sub	(xix), h
	.byte 0xf6
	nop
	.byte 0x01
	nop
	ldb	a, 8
	.byte 0x02
	retd	0x39bd
	retd	0x0600
	sub	(xix), h
	.byte 0xf6
	nop
	.byte 0x01
	nop
	.byte 0xd1, 0x0c, 0x02, 0x0f, 0xbe, 0x39, 0x0f
	nop
	ei	0x84
	.byte 0xae, 0xf6, 0x00, 0x01
	nop
	.byte 0x81, 0x11
	push_sr
	retd	0x39bf
	retd	0x0600
	sub	(xix), h
	.byte 0xf6
	nop
	.byte 0x01
	nop
	ldw	bc, 1046
	pushw 0
	nop
	nop
	ret
	.byte 0x8b, 0xac, 0xf6
	nop
	nop
	ldwio	192, 3897
	nop
	ei	0x83
	jp	721921
	nop
	nop
	nop
	nop
	ret
	push	xwa
	.byte 0xac, 0xf6, 0x00
	call	5151
	pushw	wa
	nop
	.byte 0x02
	retd	0x39bb
	.byte 0x01
	nop
	ei	0x4d
	.byte 0xac, 0xf6, 0x00
	halt
	nop
	ldw	bc, 8223
	.byte 0x50
	popw	wa
	.byte 0x52, 0x53, 0x56
	ld	xbc, 71652684
	pushw 0
	nop
	nop
	ret
	jr	le, -84
	.byte 0xf6
	nop
	.byte 0xf0, 0x05, 0x22
	nop
	.byte 0x88, 0x00, 0x04
	pushw 14777
	pop_sr
	nop
	ret
	jrl	ule, -2388
	nop
	.byte 0x51
	ldwio	33, 2304
	nop
	.byte 0x01
	retd	0x0021
	push 0
	.byte 0xb1, 0x13
	ldb	a, 0
	push 0
	jr	lt, 24
	ldb	a, 0
	push 0
	.byte 0xb9, 0x1a, 0x1f
	nop
	.byte 0x16
	nop

; accomp_section_widget: 15 bytes (compiled from C)
	.incbin "includes/generated/accomp_section_widget.bin"

; Accompaniment variation/section data: 120 bytes
	ld	xhl, 1381256783
	.byte 0x4f
	popw	ix
	ldb	w, 80
	popw	bc
	.byte 0x54
	ld	xhl, 1161961544
	popw	iz
	ld	xix, 1329806624
	popw	iz
	.byte 0x54, 0x52
	popw sp
	popw	ix
	ldb	w, 77
	.byte 0x4f
	ld	xix, 1413565525
	popw	bc
	.byte 0x4f
	popw	iz
	ldb	w, 61
	ld	xhl, 1381256783
	.byte 0x4f
	popw	ix
	ldb	w, 83
	.byte 0x55, 0x53, 0x54
	ld	xbc, 538988105
	ldb	w, 32
	push	xiy
	ld	xhl, 1381256783
	.byte 0x4f
	popw	ix
	ldb	w, 80
	ld	xbc, 1414484046
	ldb	w, 32
	ldb	w, 32
	ldb	w, 61
	ld	xhl, 1381256783
	.byte 0x4f
	popw	ix
	ldb	w, 69
	pop	xwa
	.byte 0x50, 0x52
	ld	xiy, 1330205523
	popw	iz
	ldb	w, 61
	ld	xhl, 1381256783
	.byte 0x4f
	popw	ix
	ldb	w, 65
	ld	xiz, 542262612
	.byte 0x54
	popw sp
	.byte 0x55, 0x43, 0x48, 0x3d

; accomp_part_widget: 15 bytes (compiled from C)
	.incbin "includes/generated/accomp_part_widget.bin"

; Gap: 6 bytes
	.byte 0x4f
	ld	xiz, 1313808454

; accomp_display_full: 287 bytes (compiled from C)
	.incbin "includes/generated/accomp_display_full.bin"

; Accompaniment part names and ordering: 955 bytes
	.byte 0x54
	ld	xiy, 1330533710
	.byte 0x52
	popw	iy
	.byte 0x53, 0x54
	ld	xbc, 1414873923
	.byte 0x54
	ld	xbc, 1297040195
	.byte 0x50
	ldb	w, 49
	ld	xbc, 1297040195
	.byte 0x50
	ldb	w, 50
	ld	xbc, 1297040195
	.byte 0x50
	ldb	w, 51
	ld	xde, 542331713
	ldb	w, 32
	ldb	w, 68
	.byte 0x52, 0x55
	popw	iy
	ldb	w, 32
	ldb	w, 32
	ldb	w, 49
	ldw	de, 13363
	ldw	iy, 14134
	push	xwa
	adc	bc, (xbc)
	adc	bc, (xbc)
	pushw	de
	adc	bc, (xbc)
	adc	bc, (xbc)
	pushw	de
	adc	bc, (xbc)
	pushw	de
	pushw	de
	adc	bc, (xbc)
	adc	bc, (xbc)
	pushw	de
	.byte 0x91, 0x2a, 0x91, 0x2a
	adc	bc, (xbc)
	pushw	de
	pushw	de
	.byte 0x91, 0x2a
	pushw	de
	pushw	de
	adc	bc, (xbc)
	adc	bc, (xbc)
	pushw	de
	pushw	de
	adc	bc, (xbc)
	pushw	de
	.byte 0x91, 0x2a, 0x91, 0x2a
	pushw	de
	pushw	de
	.byte 0x91, 0x2a
	adc	bc, (xbc)
	pushw	de
	pushw	de
	pushw	de
	.byte 0x91, 0x2a
	pushw	de
	.byte 0x91, 0x2a
	pushw	de
	pushw	de
	pushw	de
	pushw	de
	pushw	de
	pushw	de
	.byte 0x01
	ldwio	7, 12288
	nop
	ld	xiz, 33566720
	ldwio	7, 12288
	nop
	reti
	nop
	ldw	iy, 512
	ldwio	70, 12288
	nop
	ld	xiz, 100676864
	halt
	.byte 0xbd, 0x06, 0x15, 0x01
	ldwio	74, 12288
	nop
	.byte 0x86, 0x00
	ldw	wa, 512
	ldwio	74, 12288
	nop
	popw	de
	nop
	ldw	iy, 512
	ldwio	134, 12288
	nop
	.byte 0x86, 0x00
	ldw	iy, 1536
	halt
	.byte 0xc5, 0x06, 0x15, 0x01
	ldwio	138, 12288
	nop
	.byte 0xc6
	nop
	ldw	wa, 512
	ldwio	138, 12288
	nop
	.byte 0x8a, 0x00, 0x35
	nop
	.byte 0x02
	ldwio	198, 12288
	nop
	.byte 0xc6
	nop
	ldw	iy, 1536
	halt
	cpl	e
	pop_a
	.byte 0x01
	ldwio	202, 12288
	nop
	push 1
	ldw	wa, 512
	ldwio	202, 12288
	nop
	.byte 0xca, 0x00
	ldw	iy, 512
	ldwio	9, 12289
	nop
	push 1
	ldw	iy, 1536
	halt
	.byte 0xd5, 0x06, 0x15
	push_sr
	ldwio	7, 17664
	nop
	reti
	nop
	popw	ix
	nop
	.byte 0x01
	ldwio	7, 19456
	nop
	popw	wa
	nop
	popw	ix
	nop
	.byte 0x02
	ldwio	72, 17664
	nop
	popw	wa
	nop
	popw	ix
	nop
	.byte 0x01
	ldwio	73, 19456
	nop
	.byte 0x88, 0x00, 0x4c
	nop
	.byte 0x02
	ldwio	136, 17664
	nop
	.byte 0x88, 0x00, 0x4c
	nop
	.byte 0x01
	ldwio	137, 19456
	nop
	.byte 0xc8, 0x00
	popw	ix
	nop
	.byte 0x02
	ldwio	200, 17664
	nop
	.byte 0xc8, 0x00
	popw	ix
	nop
	.byte 0x01
	ldwio	201, 19456
	nop
	push 1
	popw	ix
	nop
	.byte 0x02
	ldwio	9, 17665
	nop
	push 1
	popw	ix
	nop
	.byte 0x02
	ldwio	7, 25344
	nop
	reti
	nop
	jr	gt, 0
	.byte 0x01
	ldwio	7, 27136
	nop
	popw	wa
	nop
	jr	gt, 0
	.byte 0x02
	ldwio	72, 25344
	nop
	popw	wa
	nop
	jr	gt, 0
	.byte 0x01
	ldwio	73, 27136
	nop
	.byte 0x88, 0x00, 0x6a
	nop
	.byte 0x02
	ldwio	136, 25344
	nop
	.byte 0x88, 0x00, 0x6a
	nop
	.byte 0x01
	ldwio	137, 27136
	nop
	.byte 0xc8, 0x00
	jr	gt, 0
	.byte 0x02
	ldwio	200, 25344
	nop
	.byte 0xc8, 0x00
	jr	gt, 0
	.byte 0x01
	ldwio	201, 27136
	nop
	push 1
	jr	gt, 0
	.byte 0x02
	ldwio	9, 25345
	nop
	push 1
	jr	gt, 0
	.byte 0x02
	ldwio	7, 33024
	nop
	reti
	nop
	.byte 0x88, 0x00, 0x01
	ldwio	7, 34816
	nop
	popw	wa
	nop
	.byte 0x88, 0x00, 0x02
	ldwio	72, 33024
	nop
	popw	wa
	nop
	.byte 0x88, 0x00, 0x01
	ldwio	73, 34816
	nop
	.byte 0x88, 0x00, 0x88
	nop
	.byte 0x02
	ldwio	136, 33024
	nop
	.byte 0x88, 0x00, 0x88
	nop
	.byte 0x01
	ldwio	137, 34816
	nop
	.byte 0xc8, 0x00, 0x88, 0x00, 0x02
	ldwio	200, 33024
	nop
	.byte 0xc8, 0x00, 0x88, 0x00, 0x01
	ldwio	201, 34816
	nop
	push 1
	.byte 0x88, 0x00, 0x02
	ldwio	9, 33025
	nop
	push 1
	.byte 0x88, 0x00, 0x02
	ldwio	7, 40704
	nop
	reti
	nop
	.byte 0xa6, 0x00, 0x01
	ldwio	7, 42496
	nop
	popw	wa
	nop
	.byte 0xa6, 0x00
	push_sr
	ldwio	72, 40704
	nop
	popw	wa
	nop
	.byte 0xa6, 0x00, 0x01
	ldwio	73, 42496
	nop
	.byte 0x88, 0x00, 0xa6
	nop
	.byte 0x02
	ldwio	136, 40704
	nop
	.byte 0x88, 0x00, 0xa6
	nop
	.byte 0x01
	ldwio	137, 42496
	nop
	.byte 0xc8, 0x00, 0xa6, 0x00
	push_sr
	ldwio	200, 40704
	nop
	.byte 0xc8, 0x00, 0xa6, 0x00, 0x01
	ldwio	201, 42496
	nop
	push 1
	.byte 0xa6, 0x00
	push_sr
	ldwio	9, 40705
	nop
	push 1
	.byte 0xa6, 0x00
	push 0
	scf
	nop
	.byte 0x19
	nop
	ldb	a, 0
	pushw	bc
	nop
	ldw	bc, 14592
	nop
	ld	xbc, 1358973184
	nop
	pop	xbc
	nop
	jr	lt, 0
	jr	ge, 0
	jrl	lt, 30976
	nop
	.byte 0x81, 0x00, 0x89, 0x00, 0x91
	nop
	.byte 0x99, 0x00, 0xa1
	nop
	.byte 0xa9, 0x00, 0xb1
	nop
	.byte 0xb9, 0x00, 0xc1
	nop
	.byte 0xc9, 0x00, 0xd1, 0x00, 0xd9, 0x00, 0xe1, 0x00, 0xe9, 0x00
	stdi8	63744, 1
	.byte 0x01
	ld	xde, 2113953792
	nop
	.byte 0x9c, 0x00, 0x41
	pushw	iy
	jrl	z, 29281
	jr	ge, 49
	ld	xbc, 1918989869
	jr	ge, 50
	ld	xbc, 1918989869
	jr	ge, 51
	ld	xbc, 1918989869
	jr	ge, 52
	ld	xde, 1918989869
	jr	ge, 49
	ld	xde, 1918989869
	jr	ge, 50
	ld	xde, 1918989869
	jr	ge, 51
	ld	xde, 1918989869
	jr	ge, 52
	ld	xhl, 1918989869
	jr	ge, 49
	ld	xhl, 1918989869
	jr	ge, 50
	ld	xhl, 1918989869
	jr	ge, 51
	ld	xhl, 1918989869
	jr	ge, 52
	ld	xbc, 1414416685
	ldb	w, 49
	ld	xbc, 1414416685
	ldb	w, 50
	ld	xbc, 1279870509
	popw	ix
	ldw	bc, 11585
	ld	xiz, 843861065
	ld	xbc, 1145980205
	ldb	w, 49
	ld	xbc, 1145980205
	ldb	w, 50
	ld	xde, 1414416685
	ldb	w, 49
	ld	xde, 1414416685
	ldb	w, 50
	ld	xde, 1279870509
	popw	ix
	ldw	bc, 11586
	ld	xiz, 843861065
	ld	xde, 1145980205
	ldb	w, 49
	ld	xde, 1145980205
	ldb	w, 50
	ld	xhl, 1414416685
	ldb	w, 49
	ld	xhl, 1414416685
	ldb	w, 50
	ld	xhl, 1279870509
	popw	ix
	ldw	bc, 11587
	ld	xiz, 843861065
	ld	xhl, 1145980205
	ldb	w, 49
	ld	xhl, 1145980205
	ldb	w, 50
	push	xhl
	ldda8	a, 13630
	pop	xhl
	ret
	nop
	.byte 0x01
	push_sr
	pop_sr
	incf
	decf
	ret
	retd	0x1110
	.byte 0x04
	halt
	ei	0x07
	ccf
	zcf
	push_a
	pop_a
	ex_ff
	ldf	8
	push 10
	pushw 6424
	.byte 0x1a, 0x1b, 0x1c
	call	3981627
	ldw	iy, 23329
	ret

AccPatch_InitSlotChain_Wrap:
	push xiz
	calr AccPatch_InitSlotChain
	pop xiz
	ret

AccPatch_InitSlotChain_WithAddr:
	push xiz
	ld xiz, 0x94800
	stda32 14766, xiz
	calr AccPatch_InitSlotChain
	pop xiz
	ret

AccPatch_InitSlotChain:
	xor xwa, xwa
	xor xbc, xbc
	ldda32 xhl, 14766
	add xhl, 0x1400
	stda32 14190, xhl
	ld wa, (xhl + 3)
	stda16 14206, xwa
	ldw bc, 0x96
	stda16 14222, xbc
	ldda32 xhl, 14766
	add xhl, 0xAA00
	stda32 14186, xhl
	ldw bc, 0x96
	xor xhl, xhl

AccPatch_IterateSlotChain:
	cpdi16 14206, 65535
	jr z, AccPatch_IterateSlot_NextBlock
	ldda16 xhl, 14206
	calr AccPatch_CalcSlotBufferAddr
	stda32 14170, xiz
	cpda16 xhl, 14222
	jr z, AccPatch_IterateSlot_Advance
	calr AccPatch_UpdateLinkPointers
	calr AccPatch_SwapSlotBuffers

AccPatch_IterateSlot_Advance:
	ldda32 xiz, 14186
	ld wa, (xiz + 3)
	stda16 14206, xwa
	incdi16 1, 14222
	ldda16 xhl, 14222
	calr AccPatch_CalcSlotBufferAddr
	stda32 14186, xiz
	jr AccPatch_IterateSlotChain

AccPatch_IterateSlot_NextBlock:
	ld xiz, 0x100
	adddm32 14190, xiz
	ldda32 xiz, 14190
	ld wa, (xiz + 3)
	stda16 14206, xwa
	djnz xbc, AccPatch_IterateSlotChain
	xor xwa, xwa
	xor xhl, xhl
	ldda16 xwa, 14222
	ldw hl, 0x100
	mul xwa, xhl
	add xwa, 0x1400
	add xwa, 0x3FF
	and xwa, 0xFFFFFC00
	srl xwa, 4
	ldda32 xiy, 14766
	ld (xiy + 46), wa
	ret

AccPatch_SwapSlotBuffers:
	push xbc
	ld xwa, 0x400
	push xwa
	call Malloc
	add xsp, 0x4
	stda32 13668, xhl
	ldw bc, 0x100
	ldda32 xix, 13668
	ldda32 xiy, 14186
	ldir85
	ldw bc, 0x100
	ldda32 xix, 14186
	ldda32 xiy, 14170
	ldir85
	ldw bc, 0x100
	ldda32 xiy, 13668
	ldda32 xix, 14170
	ldir85
	ldda32 xwa, 13668
	push xwa
	call Free
	add xsp, 0x4
	pop xbc
	ret

AccPatch_UpdateLinkPointers:
	xor xwa, xwa
	xor xhl, xhl
	ldda32 xiy, 14170
	ld wa, (xiy + 3)
	stda16 14631, xwa
	ld wa, (xiy + 1)
	stda16 14633, xwa
	ldda32 xix, 14186
	ld wa, (xix + 3)
	stda16 14635, xwa
	ld wa, (xix + 1)
	stda16 14637, xwa
	ldda16 xhl, 14631
	cp hl, 0xFFFF
	jr z, AccPatch_UpdateLink_Back
	calr AccPatch_CalcSlotBufferAddr
	ldda16 xwa, 14222
	ld (xiz + 1), wa

AccPatch_UpdateLink_Back:
	ldda16 xhl, 14633
	cp hl, 0xFFFF
	jr z, AccPatch_UpdateLink_Fwd1
	calr AccPatch_CalcSlotBufferAddr
	ldda16 xwa, 14222
	ld (xiz + 3), wa

AccPatch_UpdateLink_Fwd1:
	ldda16 xhl, 14635
	cp hl, 0xFFFF
	jr z, AccPatch_UpdateLink_Fwd2
	calr AccPatch_CalcSlotBufferAddr
	ldda16 xwa, 14206
	ld (xiz + 1), wa

AccPatch_UpdateLink_Fwd2:
	ldda16 xhl, 14637
	cp hl, 0xFFFF
	jr z, AccPatch_UpdateLink_Return
	calr AccPatch_CalcSlotBufferAddr
	ldda16 xwa, 14206
	ld (xiz + 3), wa

AccPatch_UpdateLink_Return:
	ret

AccPatch_CalcSlotBufferAddr:
	xor xiz, xiz
	ld xiz, 0x100
	mul xiz, xhl
	addda32 xiz, 14766
	add xiz, 0x1400
	ret

AccPatch_VoiceAssignDataBlock:
	ret
	ret
	ldda32	xiy, 14158
	.byte 0x8d, 0x00, 0x21
	cp	a, 109
	jr	nz, 23
	ld	a, (xiy+1)
	cp	a, 107
	jr	nz, 45
	ld	a, (xiy+2)
	cp	a, 97
	jr	nz, 37
	stdi8	14234, 0
	jr	71
	.byte 0x8d, 0x00, 0x21
	cp	a, 102
	jr	nz, 22
	ld	a, (xiy+1)
	cps	a, 0
	jr	nz, 15
	ld	a, (xiy+2)
	cp	a, 107
	jr	nz, 7
	stdi8	14234, 0
	jr	41
	.byte 0x8d, 0x00, 0x21
	cp	a, 109
	jr	nz, 23
	ld	a, (xiy+1)
	cp	a, 107
	jr	nz, 15
	ld	a, (xiy+2)
	cp	a, 98
	jr	nz, 7
	stdi8	14234, 0
	jr	10
	stdi8	14234, 255
	stdi8	14672, 130
	ret
	xor	xbc, xbc
	ldw	bc, 42
	add	xiy, 12
	add	xix, 12
	ldirw
	djnz8	e, -22
	ret
	cp	xix, xiy
	jr	ugt, 15
	xor	xbc, xbc
	ldw	bc, 128
	ldirw
	dec	1, e
	cps	e, 0
	jr	ugt, -13
	jr	38
	push d
	ldb	d, 0
	lds32	xbc, 0
	ldw	bc, 256
	mul	xbc, xde
	pop d
	add	xix, xbc
	add	xiy, xbc
	push	xix
	push	xiy
	dec	1, xix
	dec	1, xiy
	lds32	xbc, 0
	ldw	bc, 256
	lddr85
	dec	1, e
	cps	e, 0
	jr	ugt, -13
	pop	xiy
	pop	xix
	ret
	xor	xbc, xbc
	ld	(xiy), 0
	.byte 0xbd, 0x01, 0x02, 0xff, 0xff, 0xbd, 0x03, 0x02, 0xff, 0xff
	ldb	c, 249
	add	xiy, 6
	.byte 0xf5, 0xf4, 0x00, 0x00
	dec	1, c
	cps	c, 0
	jr	ugt, -10
	inc	1, xiy
	dec	1, e
	cps	e, 0
	jr	ugt, -39
	ret
	xor	xbc, xbc
	ld	xiy, 651776
	ldda8	c, 14654
	cp	(xiy+1), wa
	jr	nz, 31
	.byte 0x9d, 0x03, 0x3f, 0xff, 0xff
	jr	nz, 6
	.byte 0xc1
	.ascii "=9ah"
	.byte 0x1e, 0xc1, 0x3d
	push xbc
	.byte 0x61, 0xed, 0xc8, 0x00, 0x01
	nop
	nop
	dec	1, c
	cps	c, 0
	.byte 0x6b, 0xe3, 0x68, 0x0c
	add	xiy, 256
	dec	1, c
	cps	c, 0
	.byte 0x6b, 0xd0
	inc	1, wa
	.byte 0xd7, 0xe2, 0xf0, 0x63, 0xc0
	ret
	ld	xiy, 651776
	xor	xbc, xbc
	ldb	c, 190
	cp	(xiy), 128
	.byte 0x6e, 0x0d, 0xc1, 0x42, 0x39, 0x61
	add	xiy, 256
	.byte 0xcb, 0x1c, 0xee
	ret
	xor	xde, xde
	ld	de, (xiy+3)
	cp	de, 65535
	.byte 0x66, 0x73, 0xd1, 0x46, 0x39, 0x22
	ld	(xiy+3), de
	.byte 0xd1, 0x44, 0x39, 0x22
	ld	(xix+1), de
	.byte 0xf1, 0x4c, 0x39, 0x02, 0x00, 0x00, 0x9c, 0x03
	.byte 0x3f, 0xff, 0xff, 0x66, 0x3d, 0xd1, 0x4c, 0x39
	.byte 0x22
	cps	de, 0
	.byte 0x6e, 0x19, 0xd1, 0x46, 0x39, 0x61, 0xd1, 0x46
	.byte 0x39, 0x22
	ld	(xix+3), de
	add	xix, 256
	.byte 0xf1, 0x4c, 0x39, 0x02, 0xff, 0x00, 0x68, 0xd8
	.byte 0xd1, 0x46, 0x39, 0x22
	dec	1, de
	ld	(xix+1), de
	.byte 0xd1, 0x46, 0x39, 0x61, 0xd1, 0x46, 0x39, 0x22
	ld	(xix+3), de
	add	xix, 256
	.byte 0x68, 0xbc, 0xd1, 0x4c, 0x39, 0x22
	cps	de, 0
	.byte 0x66, 0x09, 0xd1, 0x46, 0x39, 0x22
	dec	1, de
	ld	(xix+1), de
	.byte 0xd1, 0x46, 0x39, 0x61
	add	xix, 256
	.byte 0xd1, 0x44, 0x39, 0x61
	add	xiy, 256
	dec	1, c
	cps	c, 0
	.byte 0x7b, 0x73, 0xff
	ret
	xor	xiz, xiz
	ld	xiz, 256
	.byte 0xdb, 0x46
	add	xiz, 613376
	ret
	push xiz
	call	16168339
	pop xiz
	ret
	.byte 0xf1, 0x50, 0x39, 0x00, 0x00, 0xf1, 0x70, 0x39
	.byte 0x02, 0x00, 0x00, 0xf1, 0x72, 0x39, 0x02, 0x96
	.byte 0x00, 0x1e, 0x2d, 0x06, 0x1e, 0x2b, 0x06, 0xc1
	.byte 0x50, 0x39, 0x3f, 0x84, 0x66, 0x36, 0x1e, 0x55
	.byte 0x00
	cp	w, 255
	.byte 0x6e, 0x07, 0xf1, 0x50, 0x39, 0x00, 0x82, 0x68
	.byte 0x27, 0x1e, 0x33, 0x00
	call	16167387
	.byte 0x1e, 0x94, 0x00, 0x1e, 0xa4, 0x00, 0xf1, 0x50
	.byte 0x39, 0xcf, 0x6e, 0x14, 0x1e, 0x91, 0x02, 0xf1
	.byte 0x50, 0x39, 0xcf, 0x6e, 0x0b, 0x1e, 0xdc, 0x04
	.byte 0xf1, 0x50, 0x39, 0xcf, 0x6e, 0x02, 0x68, 0x07
	call	16167387
	.byte 0x1e, 0x70, 0x00, 0x1e, 0xe7, 0x05
	call	16116095
	ret
	xor	xwa, xwa
	ld	xiy, 432128
	ld	wa, (xiy+14)
	ld	xiy, 608256
	ld	(xiy+14), wa
	ret
	ld	xhl, 432128
	cp	(xhl+1), 72
	.byte 0x6e, 0x10
	cp	(xhl+2), 0
	.byte 0x6e, 0x0a
	cp	(xhl+2), 75
	.byte 0x6e, 0x04
	ldb	w, 5
	.byte 0x68, 0x39, 0x8b, 0x00, 0x21
	cp	a, 103
	.byte 0x6e, 0x13
	ld	a, (xhl+1)
	cps	a, 0
	.byte 0x6e, 0x0c
	ld	a, (xhl+2)
	cp	a, 107
	.byte 0x6e, 0x04
	ldb	w, 5
	.byte 0x68, 0x1e, 0x8b, 0x00, 0x21
	cp	a, 76
	.byte 0x6e, 0x14
	ld	a, (xhl+1)
	cp	a, 75
	.byte 0x6e, 0x0c
	ld	a, (xhl+2)
	cp	a, 69
	.byte 0x6e, 0x04
	ldb	w, 5
	.byte 0x68, 0x02
	ldb	w, 255
	ret
	.byte 0xc1, 0xd6, 0x34, 0x20, 0xf1, 0xd6, 0x34, 0x41
	pushw wa
	.byte 0x1d
	cp	xbc, (xhl+18677)
	.byte 0xd6
	ldw	ix, 3648
	xor	xhl, xhl
	xor	xwa, xwa
	call	16167424
	ld	l, a
	ldb	a, 96
	mul8rr	a, l
	add	wa, 96
	stda16	14714, wa
	xor	xwa, xwa
	call	16167387
	ld	l, a
	ldb	a, 96
	mul8rr	a, l
	add	wa, 96
	stda16	14716, wa
	cpdi16	14714, 960
	jr	c, 26
	cpdi16	14714, 960
	jr	z, 23
	cpdi16	14714, 2016
	jr	c, 20
	cpdi16	14714, 2016
	.ascii "f!h4"
	.byte 0x1e, 0x4f, 0x00, 0x68, 0x4c, 0x1e, 0x79, 0x00
	.byte 0x68, 0x47, 0x1e, 0x0d, 0x05, 0xc1, 0x50, 0x39
	.byte 0x3f, 0x81, 0x66, 0x3d, 0xd1, 0x7a, 0x39, 0x3a
	.byte 0x00, 0x04, 0x1e, 0x35, 0x00, 0x68, 0x32, 0x1e
	.byte 0xf8, 0x04, 0xc1, 0x50, 0x39, 0x3f, 0x81, 0x66
	.byte 0x28, 0xd1, 0x7a, 0x39, 0x3a, 0x00, 0x04, 0x1e
	.byte 0x4f, 0x00, 0x68, 0x1d, 0x1e, 0xe3, 0x04, 0xc1
	.byte 0x50, 0x39, 0x3f, 0x81, 0x66, 0x13, 0x1e, 0xd9
	.byte 0x04, 0xc1, 0x50, 0x39, 0x3f, 0x81, 0x66, 0x09
	.byte 0xd1, 0x7a, 0x39, 0x3a, 0x00, 0x08, 0x1e, 0x8c
	.byte 0x00, 0x0e, 0xee, 0xd6, 0x45, 0x00, 0x98, 0x06
	.byte 0x00, 0xd1, 0x7a, 0x39, 0x26, 0xee, 0x85, 0xed
	.byte 0xc8, 0x0c, 0x00, 0x00, 0x00, 0x44, 0x00, 0x48
	.byte 0x09, 0x00, 0xd1, 0x7c, 0x39, 0x26, 0xee, 0x84
	.byte 0xec, 0xc8, 0x0c, 0x00, 0x00, 0x00, 0xe9, 0xd1
	.byte 0x31, 0x54, 0x00, 0x85, 0x11, 0x1e, 0x8e, 0x00
	.byte 0x0e, 0xe8, 0xd0, 0xe9, 0xd1, 0xee, 0xd6, 0x30
	.byte 0x00, 0x04, 0xd1, 0x7a, 0x39, 0xa0, 0xd8, 0x89
	.byte 0xd9, 0xca, 0x0c, 0x00, 0x45, 0x00, 0x98, 0x06
	.byte 0x00, 0x44, 0x00, 0x48, 0x09, 0x00, 0xd1, 0x7a
	.byte 0x39, 0x26, 0xee, 0x85, 0xed, 0xc8, 0x0c, 0x00
	.byte 0x00, 0x00, 0xd1, 0x7c, 0x39, 0x26, 0xee, 0x84
	.byte 0xec, 0xc8, 0x0c, 0x00, 0x00, 0x00, 0x39, 0x85
	.byte 0x11, 0x3d, 0x3c, 0x1e, 0x50, 0x00, 0x1e, 0x59
	.byte 0x04, 0x5c, 0x5d, 0xf1, 0x50, 0x39, 0xcf, 0x6e
	.byte 0x13, 0x59, 0x45, 0x00, 0x98, 0x06, 0x00, 0x30
	.byte 0x60, 0x00, 0xd9, 0xa0, 0xd8, 0x89, 0xd9, 0xca
	.byte 0x0c, 0x00, 0x85, 0x11, 0x0e, 0xed, 0xd5, 0xec
	.byte 0xd4, 0xd1, 0x7a, 0x39, 0x25, 0xed, 0xc8, 0x00
	.byte 0x98, 0x06, 0x00, 0xed, 0xc8, 0x0c, 0x00, 0x00
	.byte 0x00, 0xd1, 0x7c, 0x39, 0x24, 0xec, 0xc8, 0x00
	.byte 0x48, 0x09, 0x00, 0xec, 0xc8, 0x0c, 0x00, 0x00
	.byte 0x00, 0x31, 0x60, 0x00, 0xd9, 0xca, 0x0c, 0x00
	.byte 0x85, 0x11, 0x1e, 0x01, 0x00, 0x0e, 0xed, 0xd5
	.byte 0xec, 0xd4, 0xe8, 0xd0, 0xd1, 0x7a, 0x39, 0x25
	.byte 0x43, 0x00, 0x98, 0x06, 0x00, 0xeb, 0xc8, 0x00
	.byte 0x00, 0x00, 0x00, 0xd3, 0x07, 0xec, 0xf4, 0x20
	.byte 0xf1
	.asciz "R9PC"
	.byte 0x98, 0x06
	.byte 0x00, 0xeb, 0xc8, 0x04, 0x00, 0x00, 0x00, 0xd3
	.byte 0x07, 0xec, 0xf4, 0x20, 0xf1, 0x54, 0x39, 0x50
	.byte 0x43, 0x00, 0x98, 0x06, 0x00, 0xeb, 0xc8, 0x06
	.byte 0x00, 0x00, 0x00, 0xd3, 0x07, 0xec, 0xf4, 0x20
	.byte 0xf1
	.asciz "V9PC"
	.byte 0x98, 0x06
	.byte 0x00, 0xeb, 0xc8, 0x08, 0x00, 0x00, 0x00, 0xd3
	.byte 0x07, 0xec, 0xf4, 0x20, 0xf1, 0x58, 0x39, 0x50
	.byte 0x43, 0x00, 0x98, 0x06, 0x00, 0xeb, 0xc8, 0x0a
	.byte 0x00, 0x00, 0x00, 0xd3, 0x07, 0xec, 0xf4, 0x20
	.byte 0xf1, 0x5a, 0x39, 0x50, 0xd1, 0x7c, 0x39, 0x24
	.byte 0xec, 0xc8, 0x00, 0x48, 0x09, 0x00, 0x9c, 0x00
	.byte 0x20, 0xf1, 0x5c, 0x39, 0x50, 0x9c, 0x04, 0x20
	.byte 0xf1, 0x5e, 0x39, 0x50, 0x9c, 0x06, 0x20, 0xf1
	.byte 0x60, 0x39, 0x50, 0x9c, 0x08, 0x20, 0xf1, 0x62
	.byte 0x39, 0x50, 0x9c, 0x0a, 0x20, 0xf1, 0x64, 0x39
	.byte 0x50, 0x0e, 0x1e, 0x6c, 0x03, 0xf1, 0x50, 0x39
	.byte 0xcf, 0x6e, 0x1f, 0xe8, 0xad, 0x38, 0x1e, 0x61
	.byte 0x03, 0x58, 0xf1, 0x50, 0x39, 0xcf, 0x6e, 0x12
	.byte 0xc9, 0x1c, 0xf2, 0x1e, 0x0d, 0x00, 0x1e, 0x36
	.byte 0x00, 0x1e, 0x5f, 0x00, 0x1e, 0x88, 0x00, 0x1e
	.byte 0xb1, 0x00, 0x0e, 0xd1, 0x52, 0x39, 0x20, 0xf1
	.byte 0x74, 0x39, 0x50, 0xd1, 0x5c, 0x39, 0x20, 0xf1
	.byte 0x76, 0x39, 0x50, 0x1e, 0xc9, 0x00, 0xd1, 0x74
	.byte 0x39, 0x20, 0xf1, 0x52, 0x39, 0x50, 0xd1, 0x78
	.byte 0x39, 0x20, 0xf1, 0x66, 0x39, 0x50, 0xd1, 0x76
	.byte 0x39, 0x20, 0xf1, 0x5c, 0x39, 0x50, 0x0e, 0xd1
	.byte 0x54, 0x39, 0x20, 0xf1, 0x74, 0x39, 0x50, 0xd1
	.byte 0x5e, 0x39, 0x20, 0xf1, 0x76, 0x39, 0x50, 0x1e
	.byte 0x9d, 0x00, 0xd1, 0x74, 0x39, 0x20, 0xf1, 0x54
	.byte 0x39, 0x50, 0xd1, 0x78, 0x39, 0x20, 0xf1, 0x68
	.byte 0x39, 0x50, 0xd1, 0x76, 0x39, 0x20, 0xf1, 0x5e
	.byte 0x39, 0x50, 0x0e, 0xd1, 0x56, 0x39, 0x20, 0xf1
	.byte 0x74, 0x39, 0x50, 0xd1, 0x60, 0x39, 0x20, 0xf1
	.byte 0x76, 0x39, 0x50, 0x1e, 0x71, 0x00, 0xd1, 0x74
	.byte 0x39, 0x20, 0xf1, 0x56, 0x39, 0x50, 0xd1, 0x78
	.byte 0x39, 0x20, 0xf1, 0x6a, 0x39, 0x50, 0xd1, 0x76
	.byte 0x39, 0x20, 0xf1, 0x60, 0x39, 0x50, 0x0e, 0xd1
	.byte 0x58, 0x39, 0x20, 0xf1, 0x74, 0x39, 0x50, 0xd1
	.byte 0x62, 0x39, 0x20, 0xf1, 0x76, 0x39, 0x50, 0x1e
	.byte 0x45, 0x00, 0xd1, 0x74, 0x39, 0x20, 0xf1, 0x58
	.byte 0x39, 0x50, 0xd1, 0x78, 0x39, 0x20, 0xf1, 0x6c
	.byte 0x39, 0x50, 0xd1, 0x76, 0x39, 0x20, 0xf1, 0x62
	.byte 0x39, 0x50, 0x0e, 0xd1, 0x5a, 0x39, 0x20, 0xf1
	.byte 0x74, 0x39, 0x50, 0xd1, 0x64, 0x39, 0x20, 0xf1
	.byte 0x76, 0x39, 0x50, 0x1e, 0x19, 0x00, 0xd1, 0x74
	.byte 0x39, 0x20, 0xf1, 0x5a, 0x39, 0x50, 0xd1, 0x78
	.byte 0x39, 0x20, 0xf1, 0x6e, 0x39, 0x50, 0xd1, 0x76
	.byte 0x39, 0x20, 0xf1, 0x64, 0x39, 0x50, 0x0e, 0xf1
	.byte 0x50, 0x39, 0xcf, 0x6e, 0x0f, 0x1e, 0x0d, 0x00
	.byte 0xf1, 0x50, 0x39, 0xcf, 0x6e, 0x06, 0x1e, 0xdb
	.byte 0x00, 0x1e, 0x06, 0x01, 0x0e, 0x1e, 0x41, 0x00
	.byte 0xda, 0xd8, 0x66, 0x3c, 0xd1, 0x74, 0x39, 0x20
	.byte 0xd1, 0x70, 0x39, 0xf0, 0x67, 0x2f, 0xeb, 0xd3
	.byte 0xe9, 0xd1, 0xd1, 0x74, 0x39, 0x21, 0xd9, 0xef
	.byte 0x02, 0xd1, 0x70, 0x39, 0x23, 0xdb, 0xef, 0x02
	.byte 0xdb, 0xa1, 0xd9, 0xd8, 0x63, 0x15, 0x39, 0x1e
	.byte 0x28, 0x02, 0x59, 0xf1, 0x50, 0x39, 0xcf, 0x6e
	.byte 0x0a, 0xd1, 0x70, 0x39, 0x38, 0x04, 0x00, 0xd9
	.byte 0x69, 0x68, 0xe7, 0x68, 0x03, 0x1e, 0x23, 0x00
	.byte 0x0e, 0xe8, 0xd0, 0xeb, 0xd3, 0xea, 0xd2, 0xd1
	.byte 0x74, 0x39, 0x20, 0xd1, 0x70, 0x39, 0x23, 0xdb
	.byte 0xf0, 0x67, 0x0c, 0xdb, 0xc8, 0x03, 0x00, 0xdb
	.byte 0xf0, 0x6b, 0x04, 0xda, 0xa8, 0x68, 0x03, 0x32
	.byte 0xff, 0x00, 0x0e, 0xf1, 0x50, 0x39, 0xcf, 0x6e
	.byte 0x52, 0xd1
	.ascii "t9?T"
	.byte 0x01, 0x6f
	.byte 0x45, 0x1e, 0xdd, 0x01, 0xf1, 0x50, 0x39, 0xcf
	.byte 0x6e, 0x41, 0xe8, 0xac, 0x38, 0x1e, 0xd2, 0x01
	.byte 0x58, 0xf1, 0x50, 0x39, 0xcf, 0x6e, 0x34, 0xc9
	.byte 0x1c, 0xf2, 0xf1, 0x70, 0x39, 0x02, 0x00, 0x00
	.byte 0xe9, 0xd1, 0xd1, 0x74, 0x39, 0x21, 0xd9, 0xef
	.byte 0x02, 0xd9, 0x61, 0xd9, 0xd8, 0x63, 0x15, 0x39
	.byte 0x1e, 0xaf, 0x01, 0x59, 0xf1, 0x50, 0x39, 0xcf
	.byte 0x6e, 0x11, 0xd1, 0x70, 0x39, 0x38, 0x04, 0x00
	.byte 0xd9, 0x69, 0x68, 0xe7, 0x68, 0x05, 0xf1, 0x50
	.byte 0x39, 0x00, 0x80, 0x0e, 0xe8, 0xd0, 0xeb, 0xd3
	.byte 0xd1, 0x74, 0x39, 0x20, 0xd1, 0x70, 0x39, 0x23
	.byte 0xdb, 0xa0, 0x33, 0x00, 0x01, 0xdb, 0x40, 0xf1
	.byte 0x7a, 0x39, 0x50, 0x0e, 0x1e, 0xe5, 0xff, 0xed
	.byte 0xd5, 0xd1, 0x7a, 0x39, 0x25, 0xed, 0xc8, 0x06
	.byte 0x00, 0x00, 0x00, 0xed, 0xc8, 0x00, 0x98, 0x06
	.byte 0x00, 0xeb, 0xd3, 0xd1, 0x76, 0x39, 0x23, 0x1e
	.byte 0x05, 0xfb, 0xee, 0x8c, 0xec, 0xc8, 0x06, 0x00
	.byte 0x00, 0x00, 0xe9, 0xd1, 0x31, 0xf9, 0x00, 0x85
	.byte 0x11, 0x0e, 0xed, 0xd5, 0xe8, 0xd0, 0x1e, 0xb3
	.byte 0xff, 0xd1
	.asciz "z9%C"
	.byte 0x98, 0x06, 0x00
	add	xhl, 3
	.byte 0xd3, 0x07, 0xec, 0xf4, 0x20, 0xf1, 0x74, 0x39
	.byte 0x50
	xor	xhl, xhl
	.byte 0xd1, 0x76, 0x39, 0x23, 0xf1, 0x78, 0x39, 0x53
	.byte 0x1e, 0xc9, 0xfa
	ld	wa, (xiz+3)
	.byte 0xf1, 0x76, 0x39, 0x50
	ret
	.byte 0xd1, 0x52, 0x39, 0x20, 0xf1, 0x74, 0x39, 0x50
	.byte 0xd1, 0x66, 0x39, 0x20, 0xf1, 0x78, 0x39, 0x50
	.byte 0x1e, 0x4d, 0x00, 0xd1, 0x54, 0x39, 0x20, 0xf1
	.byte 0x74, 0x39, 0x50, 0xd1, 0x68, 0x39, 0x20, 0xf1
	.byte 0x78, 0x39, 0x50, 0x1e, 0x3a, 0x00, 0xd1, 0x56
	.byte 0x39, 0x20, 0xf1, 0x74, 0x39, 0x50, 0xd1, 0x6a
	.byte 0x39, 0x20, 0xf1, 0x78, 0x39, 0x50, 0x1e, 0x27
	.byte 0x00, 0xd1, 0x58, 0x39, 0x20, 0xf1, 0x74, 0x39
	.byte 0x50, 0xd1, 0x6c, 0x39, 0x20, 0xf1, 0x78, 0x39
	.byte 0x50, 0x1e, 0x14, 0x00, 0xd1, 0x5a, 0x39, 0x20
	.byte 0xf1, 0x74, 0x39, 0x50, 0xd1, 0x6e, 0x39, 0x20
	.byte 0xf1, 0x78, 0x39, 0x50, 0x1e, 0x01, 0x00
	ret
	xor	xwa, xwa
	.byte 0xf1, 0x50, 0x39, 0xcf, 0x7e, 0x84, 0x00, 0xd1
	.byte 0x74, 0x39, 0x3f, 0xff, 0xff, 0x66, 0x7b, 0x1e
	jrl	ugt, 0xd100
	.ascii "r9?T"
	.byte 0x01
	.byte 0x6f, 0x64, 0xd1, 0x72, 0x39, 0x20, 0xf1, 0x76
	.byte 0x39, 0x50, 0x1e, 0x40, 0xfe, 0xf1, 0x50, 0x39
	.byte 0xcf, 0x6e, 0x53, 0x1e, 0x0e, 0xff, 0xeb, 0xd3
	.byte 0xd1, 0x78, 0x39, 0x23, 0x1e, 0x28, 0xfa, 0xd1
	.byte 0x76, 0x39, 0x20, 0xbe, 0x03, 0x50, 0xd8, 0x8b
	.byte 0x1e, 0x1c, 0xfa, 0x86, 0x3e, 0x80, 0xd1, 0xd4
	.byte 0x34, 0x69, 0xd1, 0x78, 0x39, 0x20, 0xbe, 0x01
	.byte 0x50, 0xed, 0xd5, 0xd1, 0x7a, 0x39, 0x25, 0xed
	.byte 0xc8, 0x00, 0x98, 0x06, 0x00, 0x9d, 0x03, 0x20
	.byte 0xd8, 0xcf, 0xff, 0xff, 0x66, 0x05, 0xbe, 0x03
	.byte 0x50, 0x68, 0x05, 0xbe, 0x03, 0x02, 0xff, 0xff
	.byte 0xf1, 0x74, 0x39, 0x50, 0xd1, 0x76, 0x39, 0x20
	.byte 0xf1
	.ascii "x9Ph‰Ñv"
	push xbc
	ldb	c, 30
	.byte 0xda, 0xf9, 0xbe, 0x03, 0x02, 0xff, 0xff
	nop
	nop
	ret
	xor	xhl, xhl
	.byte 0xd1, 0x72, 0x39, 0x23
	cp	hl, 340
	.byte 0x6f, 0x19, 0x1e
	and	(xiz+8582), a
	ldw	hl, 26119
	retd	25051
	cp	hl, 340
	.byte 0x6f, 0x02, 0x68, 0xec, 0xf1, 0x50, 0x39, 0x00
	.byte 0x83, 0xf1, 0x72, 0x39, 0x53
	ret
	ret
	ret
	ret
	ret
	.byte 0xc1, 0x50, 0x39, 0x3f, 0x00, 0x66, 0x3f, 0xc1
	.byte 0x50, 0x39, 0x3f, 0x84, 0x66, 0x1c, 0xc1, 0x50
	.byte 0x39, 0x3f, 0x82, 0x66, 0x2a, 0xc1, 0x50, 0x39
	.byte 0x3f, 0x83, 0x66, 0x15, 0xc1, 0x50, 0x39, 0x3f
	.byte 0x81, 0x66, 0x15, 0xf1, 0x42, 0x7f, 0x00, 0x01
	.byte 0x68, 0x21, 0xf1, 0x42, 0x7f, 0x00, 0x03, 0x68
	.byte 0x1a, 0xf1, 0x42, 0x7f, 0x00, 0x17, 0x68, 0x13
	.byte 0xf1, 0x42, 0x7f, 0x00, 0x01, 0x68, 0x0c, 0xf1
	.byte 0x42, 0x7f, 0x00, 0x00, 0x68, 0x05, 0xf1, 0x42
	.byte 0x7f, 0x00, 0x23
	ret

cmp_ld_mae:
	push xiz
	calr CmpLoad_InitWithFlag
	pop xiz
	ret

CmpLoad_InitWithFlag:
	call AccDemo_InitWithFlag
	ret

cmp_ld_ato:
	push xiz
	calr CmpLoadAuto_CheckAndInit
	pop xiz
	ret

CmpLoadAuto_CheckAndInit:
	cps wa, 0
	jr lt, CmpLoadAuto_DemoInit
	call AccPatch_ClearModeFlag
	jr CmpLoadAuto_CountSlots

CmpLoadAuto_DemoInit:
	call AccDemo_Init_Wrap

CmpLoadAuto_CountSlots:
	call AccPatch_CountAvailableSlots
	ret

cmp_sv_mae:
	push xiz
	calr CmpSave_InitSlotAndCalcSize
	pop xiz
	ret

CmpSave_InitSlotAndCalcSize:
	call AccPatch_InitSlotChain_WithAddr
	ld hl, wa
	extz xhl
	sll xhl, 4
	ret

cmp_sv_ato:
	push xiz
	calr CmpSaveAuto_ClearFlag
	pop xiz
	ret

CmpSaveAuto_ClearFlag:
	anddi8 36232, 254
	ret

msp_ld_mae:
	push xiz
	calr MspLoad_InitVoice
	pop xiz
	ret

MspLoad_InitVoice:
	call AccompSeq_InitBankTables
	ret

msp_ld_ato:
	push xiz
	calr MspLoadAuto_CheckAndInit
	pop xiz
	ret

MspLoadAuto_CheckAndInit:
	cps wa, 0
	jr lt, MspLoadAuto_NegativeCase
	jr MspLoadAuto_Return

MspLoadAuto_NegativeCase:
	call Voice_InitBankDataSafe

MspLoadAuto_Return:
	ret

msp_sv_mae:
	push xiz
	calr MspSave_InitAndCalcSize
	pop xiz
	ret

MspSave_InitAndCalcSize:
	call Voice_RefreshBankData
	ld xhl, 0x1E881C
	ld hl, (xhl)
	extz xhl
	sll xhl, 4
	ret

msp_sv_ato:
	push xiz
	calr MspSaveAuto_Return
	pop xiz
	ret

MspSaveAuto_Return:
	ret

AccDisplay_FullInit:
	call SeqBuf_Init
	call NoteMap_SendAllNotesOff
	call Part_ReinitAllActive
	call AccompSeq_StopSequence
	call AccWrap_PlayModeDispatch
	setda 2, 10407
	call AudioInit_RefreshToneBank
	call NoteMap_ProcessAndMerge
	call Voice_InitializeAll
	call Voice_InitTablePair
	call Voice_InitTableGroup
	call MIDI_SendAllSoundOff
	call Vga_SetupMultiPlaneDisplay
	jr AccDisplay_CopyToBackBuffer

Display_RestoreEntry:
	resda 2, 10407
	call Vga_RestoreMultiPlaneDisplay
	jr AccDisplay_CopyToFrontBuffer

AccDisplay_CopyToBackBuffer:
	lda_24 xbc, 0x094800
	stda32 21980, xbc
	lda_24 xwa, 0x069800
	stda32 21984, xwa
	ld xiy, xbc
	ld xix, xwa
	ldw bc, 0xB400
	ldirw
	ret

AccDisplay_CopyToFrontBuffer:
	lda_24 xde, 0x094800
	stda32 21980, xde
	lda_24 xwa, 0x069800
	stda32 21984, xwa
	ld xiy, xwa
	ld xix, xde
	ldw bc, 0xB400
	ldirw
	ret

AccBankData_InitAllSlots:
	push_werp 0xFA
	ldda32 xwa, 15708
	stda32 21980, xwa
	ldi_berp 0xFB, 0
	lds wa, 0

AccBankData_InitSlot_OuterLoop:
	lds32 xde, 0

AccBankData_InitSlot_InnerLoop:
	st_dri3b A, 0x07, 0xE8, 0xE0
	addda32 xbc, 21980
	st_dri3b A, 0xE5, 0xA0, 0x00
	cp (xbc), 0x0
	jr nz, AccBankData_InitSlot_NonZero
	ld (xbc), 0x20
	jr AccBankData_InitSlot_PadSpaces

AccBankData_InitSlot_NonZero:
	inc 1, xde
	cp xde, 0x10
	jr c, AccBankData_InitSlot_InnerLoop

AccBankData_InitSlot_PadSpaces:
	cp xde, 0x10
	jr nc, AccBankData_PadSpaces_Done
	cp xde, 0x10
	jr nc, AccBankData_PadSpaces_Done

AccBankData_PadSpaces_Loop:
	st_dri3b A, 0x07, 0xE8, 0xE0
	addda32 xbc, 21980
	stib_dri 0xE5, 0xA0, 0x00, 0x20
	inc 1, xde
	cp xde, 0x10
	jr c, AccBankData_PadSpaces_Loop

AccBankData_PadSpaces_Done:
	inc1_berp 0xFB
	add wa, 0x60
	cp_erpb 0xFB, 0x0C
	jr c, AccBankData_InitSlot_OuterLoop
	stdi8 18646, 0
	resda 0, 13744
	ldi_berp 0xFB, 0

AccBankData_ProcessSlot:
	lda_24 xwa, 0x069800
	stda32 14766, xwa
	ldto_berp A, 0xFB
	stda8 14764, a
	call AccPatch_InitFromSlotIndex
	ldda32 xwa, 15708
	stda32 14766, xwa
	lda_24 xwa, 0x069800
	stda32 14770, xwa
	ldto_berp A, 0xFB
	stda8 14765, a
	ldto_berp A, 0xFB
	stda8 14764, a
	call DualVoice_ParamLoadDone
	ldda8 a, 13744
	extz wa
	bit 0, wa
	jr z, AccBankData_SlotFound
	stdi8 18646, 1
	jr AccBankData_ReInitAllSlots

AccBankData_SlotFound:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x1E
	jr c, AccBankData_ProcessSlot
	cpdi8 18646, 0
	jr z, AccBankData_FinalizeCheck

AccBankData_ReInitAllSlots:
	lda_24 xwa, 0x069800
	stda32 14766, xwa
	ldi_berp 0xFB, 0

AccBankData_ReInit_Loop:
	ldto_berp A, 0xFB
	stda8 14764, a
	call AccPatch_InitFromSlotIndex
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x1E
	jr c, AccBankData_ReInit_Loop

AccBankData_FinalizeCheck:
	cpdi8 18646, 0
	jr nz, AccBankData_Return
	ldda32 xwa, 15708
	add xwa, 0x16800
	ld bc, (xwa)
	lds32 xwa, 4
	lds de, 3
	call SoundParam_NotifyChange
	call SeqTimer_UpdateTempoReg
	ldda32 xbc, 15708
	add xbc, 0x16C00
	ld xix, xbc
	ldi_berp 0xFB, 0
	ldada xde, 58298

AccBankData_CompareLoop:
	ldto_berp A, 0xFB
	extz wa
	ld hl, wa
	extz xhl
	add xhl, xde
	ld_spib A, 0xF0
	cp a, (xhl)
	jr nz, AccBankData_Return
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr c, AccBankData_CompareLoop
	ld xix, xbc
	lda_24 xbc, 0x1e0000
	lds32 xde, 0

AccBankData_CopyToExtRAM:
	ld_spib A, 0xF0
	lda_dpi XBC, 0xE4
	inc 1, xde
	cp xde, 0x72A6
	jr c, AccBankData_CopyToExtRAM
	lds wa, 0
	call PostTmSave_Success

AccBankData_Return:
	pop_werp 0xFA
	ret

AccBankData_ProcessWithCopy:
	dec 2, xsp
	push_werp 0xFA
	ld (xsp + 2), a
	ldda32 xbc, 15708
	stda32 21980, xbc
	pushw 0xD
	ldda32 xwa, 15708
	add xwa, 0x16802
	push xwa
	st_dri3b W, 0xE5, 0xA0, 0x00
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	ldi_berp 0xFB, 0
	lds bc, 0

AccBankData_CopyLoop:
	ld de, bc
	add de, 0xA0
	ldda32 xwa, 21980
	st_dri3b W, 0x07, 0xE0, 0xE8
	ld e, (xwa)
	cps e, 0
	jr nz, AccBankData_CopyLoop_NonZero
	ldb e, 0x20

AccBankData_CopyLoop_NonZero:
	ld (xwa), e
	inc1_berp 0xFB
	inc 1, bc
	cp_erpb 0xFB, 0x10
	jr c, AccBankData_CopyLoop
	cp (xsp + 2), 0x2
	jr ule, AccBankData_InitSlotScan
	call Vga_BackupPlane3ToBuffer
	ld c, (xsp + 2)
	inc 7, c
	extz bc
	ldda32 xde, 15708
	lds wa, 0
	call DualVoice_LoadAndScan
	call Vga_RestorePlane3FromBuffer
	call AccPatch_CountSlotsAlt
	jrl AccBankData_PostModeChange

AccBankData_InitSlotScan:
	stdi8 18646, 0
	resda 0, 13744
	ldi_berp 0xFB, 0

AccBankData_SlotScan_Loop:
	lda_24 xwa, 0x069800
	stda32 14766, xwa
	ld c, (xsp + 2)
	extz bc
	ldto_berp A, 0xFB
	extz wa
	muls wa, 0x3
	ld de, wa
	add de, bc
	lda_24 xwa, 0xe4c114
	ldmm_srib 0x07, 0xE0, 0xE8, 0xAC, 0x39
	call AccPatch_InitFromSlotIndex
	ldda32 xwa, 15708
	stda32 14766, xwa
	lda_24 xwa, 0x069800
	stda32 14770, xwa
	ldto_berp A, 0xFB
	extz wa
	muls wa, 0x3
	ld bc, wa
	lda_24 xde, 0xe4c114
	ldmm_srib 0x07, 0xE8, 0xE4, 0xAC, 0x39
	ld a, (xsp + 2)
	extz wa
	add bc, wa
	ldmm_srib 0x07, 0xE8, 0xE4, 0xAD, 0x39
	call DualVoice_ParamLoadDone
	ldda8 a, 13744
	extz wa
	bit 0, wa
	jr z, AccBankData_SlotScan_Next
	stdi8 18646, 1
	jr AccBankData_SlotScan_ReInit

AccBankData_SlotScan_Next:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x0A
	jr c, AccBankData_SlotScan_Loop
	cpdi8 18646, 0
	jr z, AccBankData_NotifyAndUpdateTempo

AccBankData_SlotScan_ReInit:
	lda_24 xwa, 0x069800
	stda32 14766, xwa
	ldi_berp 0xFB, 0

AccBankData_ReInit_ScanLoop:
	ld c, (xsp + 2)
	extz bc
	ldto_berp A, 0xFB
	extz wa
	muls wa, 0x3
	ld de, wa
	add de, bc
	lda_24 xwa, 0xe4c114
	ldmm_srib 0x07, 0xE0, 0xE8, 0xAC, 0x39
	call AccPatch_InitFromSlotIndex
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x0A
	jr c, AccBankData_ReInit_ScanLoop
	jr AccBankData_PostModeChange

AccBankData_NotifyAndUpdateTempo:
	ldda32 xwa, 15708
	add xwa, 0x16800
	ld bc, (xwa)
	lds32 xwa, 4
	lds de, 3
	call SoundParam_NotifyChange
	call SeqTimer_UpdateTempoReg

AccBankData_PostModeChange:
	ldw wa, 0x16
	call UI_PostModeChangeEvent
	pop_werp 0xFA
	inc 2, xsp
	ret

AccBankData_CopyDataBlock:
	ldada	xbc, 18614
	ld	xwa, xbc
	lda	xbc, (xbc+32)
	.byte 0xf5, 0xe0, 0x00, 0x00
	cp	xwa, xbc
	jr	c, -8
	ret

StyleBuf_ClearAllEntries:
	ldada xbc, 16264
	ld xwa, xbc
	st_dri3b A, 0xE5, 0x00, 0x08

StyleBuf_ClearEntry_Outer:
	ld xde, xwa
	lda xhl, (xwa + 32)

StyleBuf_ClearEntry_Inner:
	stib_dpi 0xE8, 0x00
	cp xde, xhl
	jr c, StyleBuf_ClearEntry_Inner
	lda xwa, (xwa + 32)
	cp xwa, xbc
	jr c, StyleBuf_ClearEntry_Outer
	ret

StyleConv_ClearWorkBuffer:
	ldada xbc, 18572
	ld xwa, xbc
	lda xbc, (xbc + 32)

StyleConv_ClearWorkBuf_Loop:
	stib_dpi 0xE0, 0x00
	cp xwa, xbc
	jr c, StyleConv_ClearWorkBuf_Loop
	ret

StyleConv_ClearEntryTables:
	ldada xwa, 18312
	ld xbc, xwa
	ldada xde, 16264
	st_dri3b C, 0xE1, 0x00, 0x01

StyleConv_ClearEntry_Outer:
	ld xwa, xde
	lda xix, (xde + 32)

StyleConv_ClearEntry_Inner:
	stib_dpi 0xE0, 0x00
	cp xwa, xix
	jr c, StyleConv_ClearEntry_Inner
	lds32 xwa, 0
	st_dpil XWA, 0xE6
	lda xde, (xde + 32)
	cp xbc, xhl
	jr c, StyleConv_ClearEntry_Outer
	ret

StyleConv_InitEntryTable:
	pushw iz
	lds ix, 0

StyleConvInit_OuterLoop:
	ld hl, ix
	mul hl, 0x25
	ldada xde, 21988
	ld bc, hl
	extz xbc
	add xbc, xde
	ld wa, ix
	extz xwa
	div wa, 0x14
	ldto_werp WA, 0xE2
	ld (xbc), a
	lds iz, 0

StyleConvInit_InnerLoop:
	ldi_berp 0xE2, 0
	cp iz, 0xC
	jr nc, StyleConvInit_StoreChar
	ldi_erpb 0xE2, 0x20

StyleConvInit_StoreChar:
	ld wa, hl
	add wa, iz
	ld iy, wa
	extz xiy
	add xiy, xde
	ldto_berp A, 0xE2
	ld (xiy + 1), a
	inc 1, iz
	cp iz, 0x20
	jr c, StyleConvInit_InnerLoop
	lds32 xwa, 0
	ld (xbc + 33), xwa
	inc 1, ix
	cp ix, 0x100
	jr c, StyleConvInit_OuterLoop
	popw iz
	ret

SoundMem_ClearRegion:
	ld xwa, 0xFFC00

SoundMem_ClearLoop:
	stib_dpi 0xE0, 0x00
	cp xwa, 0x100000
	jr c, SoundMem_ClearLoop
	ret

StyleFile_ClearAllTables:
	ldada xwa, 21852
	ld xbc, xwa
	ldada xde, 18652
	st_dri3b C, 0xE1, 0x80, 0x00

StyleFile_ClearTable_Outer:
	ld xwa, xde
	lda xix, (xde + 100)

StyleFile_ClearTable_Inner:
	stib_dpi 0xE0, 0x00
	cp xwa, xix
	jr c, StyleFile_ClearTable_Inner
	lds32 xwa, 0
	st_dpil XWA, 0xE6
	lda xde, (xde + 100)
	cp xbc, xhl
	jr c, StyleFile_ClearTable_Outer
	ret

DialUI_PostInitEvents:
	lds wa, 1
	call UI_PostDialEnable
	ldw wa, 0x82
	call UI_PostDialValueEvent
	lds wa, 2
	jp UI_PostDialRangeEvent

DialUI_CalcProlog:
	dec 2, xsp
	push xiz
	ld iz, wa
	extz xde
	div xde, xiz
	mul xde, xiz
	ld (xsp + 4), de
	ldi_werp 0xFA, 0
	cps iz, 0
	jr ule, DialCalc_Return

DialCalc_EventLoop:
	ld xbc, 0x110002
	ldda8 a, 36150
	cp a, 0x15
	jr z, DialCalc_SetMode15
	cp a, 0x12
	jr z, DialCalc_SetMode12
	cp a, 0x11
	jr nz, PostEventSetup_Send
	ld xbc, 0x110002
	jr PostEventSetup_Send

DialCalc_SetMode12:
	ld xbc, 0x120002
	jr PostEventSetup_Send

DialCalc_SetMode15:
	ld xbc, 0x150002

PostEventSetup_Send:
	ld xwa, xbc
	ld bc, (xsp + 4)
	add_werp BC, 0xFA
	mul bc, 0x25
	ldada xhl, 21988
	ld de, bc
	extz xde
	add xde, xhl
	ld xbc, 0x1C0000F
	call ApPostEvent
	inc1_werp 0xFA
	ldto_werp WA, 0xFA
	cp wa, iz
	jr c, DialCalc_EventLoop

DialCalc_Return:
	pop xiz
	inc 2, xsp
	ret
__pad_F6C160:

StylCnvWaitTtlFunc:
	cp xbc, 0x1C00007
	jr z, AccChord_ReturnZero
	cp xbc, 0x1C00013
	jr nz, AccChord_ReturnZero
	cp xde, 0x3
	jr z, StylCnvWait_HandleClose
	cp xde, 0x8
	jr z, AccChord_ReturnZero
	cp xde, 0x2
	jr nz, AccChord_ReturnZero
	cpdi8 36151, 96
	jr nz, StylCnvWait_CheckPending
	calr StyleConv_InitEntryTable
	stdi8 15622, 0
	calr AccDisplay_FullInit
	call FileIO_CheckMediaIsWritable
	cps hl, 0
	jr nz, StylCnvWait_SetStatus
	ldw wa, 0x11
	call UI_PostModeChangeEvent

StylCnvWait_SetStatus:
	stdi8 18650, 0
	jr AccChord_ReturnZero

StylCnvWait_CheckPending:
	cpdi8 18650, 0
	jr z, AccChord_ReturnZero
	stdi8 32578, 74
	ldw wa, 0xEE
	call SoundCtrl_SendCommand
	stdi8 18650, 0
	jr AccChord_ReturnZero

StylCnvWait_HandleClose:
	cpdi8 36150, 96
	jr z, StylCnvWait_RestoreDisplay
	cpdi8 36148, 6
	jr z, AccChord_ReturnZero

StylCnvWait_RestoreDisplay:
	calr Display_RestoreEntry

AccChord_ReturnZero:
	lds32 xhl, 0
	ret
__pad_F6C1DE:

StylCnvTxtTtlFunc:
	cp xbc, 0x1C00007
	jr z, StylCnvTxt_ReturnZero
	cp xbc, 0x1C00013
	jr nz, StylCnvTxt_ReturnZero
	cp xde, 0x3
	jr z, StylCnvTxt_HandleClose
	cp xde, 0x8
	jr z, StylCnvTxt_ReturnZero
	cp xde, 0x2
	jr nz, StylCnvTxt_ReturnZero
	cpi8_24 0x0ffc00, 0x05
	jr nz, StylCnvTxt_ReturnZero
	sti8_24 0x0ffc00, 0xff
	calr TableData_JumpToEntry
	calr FloppyState_Dispatch
	jr StylCnvTxt_ReturnZero

StylCnvTxt_HandleClose:
	cpdi8 36148, 6
	call_24 nz, 0xF6BCD6

StylCnvTxt_ReturnZero:
	lds32 xhl, 0
	ret
__pad_F6C229:

StylCnvModlTtlFunc:
	lda xsp, (xsp - 36)
	push xiz
	ld xhl, xde
	ldda16 xde, 15620
	ld iz, de
	ldda16 xwa, 14978
	cp xbc, 0x1C00007
	jrl z, StylCnvModl_HandleOK
	cp xbc, 0x1C00013
	jrl nz, StylCnvModl_Return
	cp xhl, 0x4
	jrl z, StylCnvModl_HandleOpenItem
	cp xhl, 0x5
	jrl z, StylCnvModl_HandleClose
	cp xhl, 0x3
	jrl z, StylCnvModl_HandleRedraw
	cp xhl, 0x8
	jrl z, StylCnvModl_HandleScroll
	cp xhl, 0x2
	jrl nz, StylCnvModl_Return
	calr DialUI_PostInitEvents
	stdi8 18650, 0
	ld xwa, 0xE4C132
	call ControlState_ProcessCommand
	stdi16 14978, 0
	lds iz, 0

StylCnvModl_ScanMatchingModels:
	ld bc, iz
	mul bc, 0x25
	ldada xwa, 21988
	extz xbc
	add xbc, xwa
	lda xwa, (xbc + 1)
	lda xbc, (xbc + 33)
	call FileIO_SearchStringMatch
	cps hl, 0
	jr nz, StylCnvModl_ScanDone
	incdi16 1, 14978
	inc 1, iz
	cp iz, 0x100
	jr c, StylCnvModl_ScanMatchingModels

StylCnvModl_ScanDone:
	cpdi16 14978, 0
	jr nz, StylCnvModl_PadModelNames
	ldw wa, 0x10
	jrl StylCnvModl_OK_Select_ShowError

StylCnvModl_PadModelNames:
	cp iz, 0x100
	jr nc, StylCnvModl_InitListDisplay
	ldada xhl, 21988
	ld bc, iz
	mul bc, 0x25

StylCnvModl_PadOuterLoop:
	lds iy, 0
	ld de, bc

StylCnvModl_PadInnerLoop:
	ldb a, 0x0
	cp iy, 0xC
	jr nc, StylCnvModl_PadStoreChar
	ldb a, 0x20

StylCnvModl_PadStoreChar:
	ld ix, de
	extz xix
	add xix, xhl
	ld (xix + 1), a
	inc 1, iy
	inc 1, de
	cp iy, 0x14
	jr c, StylCnvModl_PadInnerLoop
	inc 1, iz
	add bc, 0x25
	cp iz, 0x100
	jr c, StylCnvModl_PadOuterLoop

StylCnvModl_InitListDisplay:
	stdi16 15620, 0
	ld xwa, 0x110002
	ld xbc, 0x1E4002F
	lds32 xde, 0
	call ApPostEvent
	ldada xbc, 16232
	ld xwa, xbc
	lda xbc, (xbc + 32)

StylCnvModl_ClearDisplayBuf:
	stib_dpi 0xE0, 0x00
	cp xwa, xbc
	jr c, StylCnvModl_ClearDisplayBuf
	ld xwa, 0xE4C13E
	call ControlState_ProcessCommand
	lda xbc, (xsp + 36)
	ld xwa, 0x3F68
	call FileIO_SearchStringMatch
	ldada xwa, 16232
	cps hl, 0
	jr nz, StylCnvModl_CopyDefaultName
	pushw 0x2E
	push xwa
	call AudioCmd_StringLength
	inc 6, xsp
	or xhl, xhl
	jr z, StylCnvModl_FormatFilename
	ld (xhl), 0x0

StylCnvModl_FormatFilename:
	lds iy, 0
	ldada xde, 16232

StylCnvModl_FormatLoop:
	ld bc, iy
	extz xbc
	add xbc, xde
	ld a, (xbc)
	cps a, 0
	jr z, StylCnvModl_DrawListUI
	cp a, 0x5F
	jr nz, StylCnvModl_CheckPercent
	ld (xbc), 0x20
	jr StylCnvModl_FormatNext

StylCnvModl_CheckPercent:
	cp a, 0x25
	jr nz, StylCnvModl_FormatNext
	ld (xbc), 0x2E

StylCnvModl_FormatNext:
	inc 1, iy
	cp iy, 0x20
	jr c, StylCnvModl_FormatLoop
	jr StylCnvModl_DrawListUI

StylCnvModl_CopyDefaultName:
	pushw 0x0
	pushw 0xE3D2
	push xwa
	call Strcpy
	inc 8, xsp

StylCnvModl_DrawListUI:
	ld xwa, 0x110007
	ld xbc, 0x1C0000B
	lds32 xde, 0
	call ApDeliveryEvent
	lda xwa, (xsp + 4)
	lda xbc, (xsp + 36)
	call FileIO_SearchStringMatch
	cps hl, 0
	jrl nz, StylCnvModl_Return

StylCnvModl_WaitForAck:
	lda xwa, (xsp + 4)
	lda xbc, (xsp + 36)
	call FileIO_SearchStringMatch
	cps hl, 0
	jr z, StylCnvModl_WaitForAck
	jrl StylCnvModl_Return

StylCnvModl_HandleScroll:
	ld bc, wa
	cps wa, 0
	jrl z, StylCnvModl_Return
	ldw wa, 0x14
	jrl StylCnvModl_OK_CallRedraw

StylCnvModl_HandleRedraw:
	cpdi8 36150, 96
	jr z, StylCnvModl_RedrawDone
	cpdi8 36148, 6
	jr z, StylCnvModl_RedrawReturnZero

StylCnvModl_RedrawDone:
	calr Display_RestoreEntry

StylCnvModl_RedrawReturnZero:
	lds wa, 0
	jr StylCnvModl_CallReturnAction

StylCnvModl_HandleClose:
	calr DialUI_PostInitEvents
	jrl StylCnvModl_Return

StylCnvModl_HandleOpenItem:
	lds wa, 0

StylCnvModl_CallReturnAction:
	call UI_PostDialEnable
	jrl StylCnvModl_Return

StylCnvModl_HandleOK:
	cp xhl, 0xB
	jrl z, StylCnvModl_OK_SelectItem
	cp xhl, 0x84
	jrl z, StylCnvModl_OK_PageDown
	cp xhl, 0x4
	jrl z, StylCnvModl_OK_PageDown
	cp xhl, 0x83
	jrl z, StylCnvModl_OK_ScrollDown
	cp xhl, 0x82
	jrl z, StylCnvModl_OK_ScrollDown
	cp xhl, 0x3
	jrl z, StylCnvModl_OK_ScrollUp
	cp xhl, 0x2
	jrl z, StylCnvModl_OK_ScrollUp
	cp xhl, 0x81
	jr z, StylCnvModl_OK_PageUp
	cp xhl, 0x1
	jr nz, StylCnvModl_OK_LoadSelection

StylCnvModl_OK_PageUp:
	cp de, 0x14
	jr c, StylCnvModl_OK_LoadSelection
	sub de, 0x14

StylCnvModl_OK_StoreSelection:
	stda16 15620, xde

StylCnvModl_OK_LoadSelection:
	ldda16 xbc, 15620

StylCnvModl_OK_UpdateDisplay:
	cp iz, bc
	jrl z, StylCnvModl_Return
	extz xbc
	div bc, 0x14
	ldto_werp DE, 0xE6
	extz xde
	ld xwa, 0x110002
	ld xbc, 0x1E4002F
	call ApPostEvent
	ldda16 xde, 15620
	ld bc, de
	extz xbc
	div bc, 0x14
	ld wa, iz
	extz xwa
	div wa, 0x14
	cp wa, bc
	jrl nz, StylCnvModl_OK_PageRedraw
	mul iz, 0x25
	ldada xwa, 21988
	ld de, iz
	extz xde
	add xde, xwa
	ld xwa, 0x110002
	ld xbc, 0x1C0000F
	call ApPostEvent
	ldda16 xde, 15620
	mul de, 0x25
	ldada xwa, 21988
	extz xde
	add xde, xwa
	ld xwa, 0x110002
	ld xbc, 0x1C0000F
	call ApPostEvent
	jrl StylCnvModl_Return

StylCnvModl_OK_ScrollUp:
	lds wa, 1
	call UI_PostEvent_0x6E
	ldda16 xwa, 15620
	cps wa, 0
	jrl z, StylCnvModl_OK_LoadSelection
	dec 1, wa
	stda16 15620, xwa
	ld bc, wa
	jrl StylCnvModl_OK_UpdateDisplay

StylCnvModl_OK_ScrollDown:
	lds wa, 1
	call UI_PostEvent_0x6E
	ldda16 xbc, 14978
	dec 1, bc
	ldda16 xwa, 15620
	cp wa, bc
	jrl nc, StylCnvModl_OK_LoadSelection
	inc 1, wa
	stda16 15620, xwa
	ld bc, wa
	jrl StylCnvModl_OK_UpdateDisplay

StylCnvModl_OK_PageDown:
	ld bc, de
	add bc, 0x14
	ld hl, wa
	cp bc, wa
	jr nc, StylCnvModl_OK_PageDown_Clamp
	add de, 0x14
	jrl StylCnvModl_OK_StoreSelection

StylCnvModl_OK_PageDown_Clamp:
	ld bc, hl
	dec 1, bc
	ld ix, bc
	extz xix
	div ix, 0x14
	extz xde
	div de, 0x14
	cp de, ix
	jrl nc, StylCnvModl_OK_LoadSelection
	extz xhl
	div hl, 0x14
	ldto_werp WA, 0xEE
	cps wa, 0
	jrl z, StylCnvModl_OK_LoadSelection
	stda16 15620, xbc
	jrl StylCnvModl_OK_UpdateDisplay

StylCnvModl_OK_SelectItem:
	mul de, 0x25
	ldada xwa, 21989
	extz xde
	add xde, xwa
	ld xwa, xde
	ld xbc, 0xE4C14A
	call FileIO_OpenWithBuiltPath
	cps hl, 0
	jr ge, StylCnvModl_OK_Select_ClearMem
	ldw wa, 0x10
	jr StylCnvModl_OK_Select_ShowError

StylCnvModl_OK_Select_ClearMem:
	ld xbc, 0x80000
	lds32 xwa, 0

StylCnvModl_OK_Select_FillLoop:
	stib_dpi 0xE4, 0x00
	inc 1, xwa
	cp xwa, 0x30000
	jr c, StylCnvModl_OK_Select_FillLoop
	ldda16 xbc, 15620
	mul bc, 0x25
	ldada xwa, 22021
	extz xbc
	add xbc, xwa
	ld xbc, (xbc)
	ld xwa, 0x80000
	call FileIO_ReadBlock
	cp xhl, 0x0
	jr ge, StylCnvModl_OK_Select_LoadOK
	call FileIO_CloseHandle
	ldw wa, 0x10

StylCnvModl_OK_Select_ShowError:
	call UI_PostModeChangeEvent
	jrl StylCnvModl_Return

StylCnvModl_OK_Select_LoadOK:
	ldda16 xbc, 15620
	mul bc, 0x25
	ldada xwa, 22021
	extz xbc
	add xbc, xwa
	ld xbc, (xbc)
	ld xwa, xbc
	and xwa, 0xFF
	jr z, StylCnvModl_OK_Select_AlignSize
	and xbc, 0xFFFFFF00
	add xbc, 0x100

StylCnvModl_OK_Select_AlignSize:
	add xbc, 0x80000
	stda32 15708, xbc
	call FileIO_CloseHandle
	sti8_24 0x0ffbfe, 0x00
	ldda16 xwa, 15620
	stda16 18604, xwa
	lds iz, 0
	ldada xhl, 58314
	ldda16 xwa, 15620
	mul wa, 0x25
	ldada xbc, 21988

StylCnvModl_OK_Select_CompareNames:
	ld ix, iz
	extz xix
	add xix, xhl
	ld de, wa
	add de, iz
	extz xde
	add xde, xbc
	ld e, (xde + 1)
	cp e, (xix)
	jr nz, StylCnvModl_OK_Select_StoreResult
	inc 1, iz
	cp iz, 0x8
	jr c, StylCnvModl_OK_Select_CompareNames

StylCnvModl_OK_Select_StoreResult:
	cp iz, 0x8
	scc16 z, wa
	stda16 18604, xwa
	sti8_24 0x0ffc00, 0xff
	sti8_24 0x0ffc01, 0x00
	pushw 0x4
	ldda16 xwa, 15620
	mul wa, 0x25
	extz xwa
	add xwa, xbc
	lda xwa, (xwa + 33)
	push xwa
	ld xwa, 0xFFC02
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	ldda16 xbc, 15620
	mul bc, 0x25
	ldada xwa, 22021
	extz xbc
	add xbc, xwa
	ld xwa, (xbc)
	stda32 15704, xwa
	calr TableData_JumpToEntry
	calr FloppyState_Dispatch
	jr StylCnvModl_Return

StylCnvModl_OK_PageRedraw:
	ldda16 xbc, 14978
	ldw wa, 0x14

StylCnvModl_OK_CallRedraw:
	calr DialUI_CalcProlog

StylCnvModl_Return:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 36)
	ret
StylCnvModl_End:

StylCnvCnvtTtlFunc:
	push xiz
	ldda16 xhl, 15620
	ld iz, hl
	ldda16 xix, 14978
	cp xbc, 0x1C00007
	jrl z, StylCnvCnvt_HandleOK
	cp xbc, 0x1C00013
	jrl nz, StylCnvCnvt_Return
	cp xde, 0x4
	jrl z, StylCnvCnvt_HandleOpenItem
	cp xde, 0x5
	jrl z, StylCnvCnvt_HandleClose
	cp xde, 0x3
	jrl z, StylCnvCnvt_HandleRedraw
	cp xde, 0x8
	jrl z, StylCnvCnvt_HandleScroll
	cp xde, 0x2
	jrl nz, StylCnvCnvt_Return
	stdi8 18650, 0
	calr DialUI_PostInitEvents
	stdi16 14978, 0
	lds iz, 0

StylCnvCnvt_ScanMatchingStyles:
	ld bc, iz
	mul bc, 0x25
	ldada xwa, 21988
	extz xbc
	add xbc, xwa
	lda xwa, (xbc + 1)
	lda xbc, (xbc + 33)
	call FileIO_SearchStringMatch
	cps hl, 0
	jr nz, StylCnvCnvt_PadStyleNames
	incdi16 1, 14978
	inc 1, iz
	cp iz, 0x100
	jr c, StylCnvCnvt_ScanMatchingStyles

StylCnvCnvt_PadStyleNames:
	cp iz, 0x100
	jr nc, StylCnvCnvt_InitListDisplay
	ldada xhl, 21988
	ld bc, iz
	mul bc, 0x25

StylCnvCnvt_PadOuterLoop:
	lds iy, 0
	ld de, bc

StylCnvCnvt_PadInnerLoop:
	ldb a, 0x0
	cp iy, 0xC
	jr nc, StylCnvCnvt_PadStoreChar
	ldb a, 0x20

StylCnvCnvt_PadStoreChar:
	ld ix, de
	extz xix
	add xix, xhl
	ld (xix + 1), a
	inc 1, iy
	inc 1, de
	cp iy, 0x20
	jr c, StylCnvCnvt_PadInnerLoop
	inc 1, iz
	add bc, 0x25
	cp iz, 0x100
	jr c, StylCnvCnvt_PadOuterLoop

StylCnvCnvt_InitListDisplay:
	stdi16 15620, 0
	ld xwa, 0x120002
	ld xbc, 0x1E4002F
	lds32 xde, 0
	call ApPostEvent
	jrl StylCnvCnvt_Return

StylCnvCnvt_HandleScroll:
	ldw wa, 0x14
	ld bc, ix
	ld de, hl
	jrl StylCnvCnvt_OK_CallRedraw

StylCnvCnvt_HandleRedraw:
	cpdi8 36148, 6
	call_24 nz, 0xF6BCD6
	lds wa, 0
	jr StylCnvCnvt_CallReturnAction

StylCnvCnvt_HandleClose:
	calr DialUI_PostInitEvents
	jrl StylCnvCnvt_Return

StylCnvCnvt_HandleOpenItem:
	lds wa, 0

StylCnvCnvt_CallReturnAction:
	call UI_PostDialEnable
	jrl StylCnvCnvt_Return

StylCnvCnvt_HandleOK:
	cp xde, 0xB
	jrl z, StylCnvCnvt_OK_SelectItem
	cp xde, 0x84
	jrl z, StylCnvCnvt_OK_PageDown
	cp xde, 0x4
	jrl z, StylCnvCnvt_OK_PageDown
	cp xde, 0x83
	jrl z, StylCnvCnvt_OK_ScrollDown
	cp xde, 0x82
	jrl z, StylCnvCnvt_OK_ScrollDown
	cp xde, 0x3
	jrl z, StylCnvCnvt_OK_ScrollUp
	cp xde, 0x2
	jrl z, StylCnvCnvt_OK_ScrollUp
	cp xde, 0x81
	jr z, StylCnvCnvt_OK_PageUp
	cp xde, 0x1
	jr nz, StylCnvCnvt_OK_LoadSelection

StylCnvCnvt_OK_PageUp:
	cp hl, 0x14
	jr c, StylCnvCnvt_OK_LoadSelection
	sub hl, 0x14

StylCnvCnvt_OK_StoreSelection:
	stda16 15620, xhl

StylCnvCnvt_OK_LoadSelection:
	ldda16 xbc, 15620

StylCnvCnvt_OK_UpdateDisplay:
	cp iz, bc
	jrl z, StylCnvCnvt_Return
	extz xbc
	div bc, 0x14
	ldto_werp DE, 0xE6
	extz xde
	ld xwa, 0x120002
	ld xbc, 0x1E4002F
	call ApPostEvent
	ldda16 xde, 15620
	ld bc, de
	extz xbc
	div bc, 0x14
	ld wa, iz
	extz xwa
	div wa, 0x14
	cp wa, bc
	jrl nz, StylCnvCnvt_OK_PageRedraw
	mul iz, 0x25
	ldada xwa, 21988
	ld de, iz
	extz xde
	add xde, xwa
	ld xwa, 0x120002
	ld xbc, 0x1C0000F
	call ApPostEvent
	ldda16 xde, 15620
	mul de, 0x25
	ldada xwa, 21988
	extz xde
	add xde, xwa
	ld xwa, 0x120002
	ld xbc, 0x1C0000F
	call ApPostEvent
	jrl StylCnvCnvt_Return

StylCnvCnvt_OK_ScrollUp:
	lds wa, 1
	call UI_PostEvent_0x6E
	ldda16 xwa, 15620
	cps wa, 0
	jrl z, StylCnvCnvt_OK_LoadSelection
	dec 1, wa
	stda16 15620, xwa
	ld bc, wa
	jrl StylCnvCnvt_OK_UpdateDisplay

StylCnvCnvt_OK_ScrollDown:
	lds wa, 1
	call UI_PostEvent_0x6E
	ldda16 xbc, 14978
	dec 1, bc
	ldda16 xwa, 15620
	cp wa, bc
	jrl nc, StylCnvCnvt_OK_LoadSelection
	inc 1, wa
	stda16 15620, xwa
	ld bc, wa
	jrl StylCnvCnvt_OK_UpdateDisplay

StylCnvCnvt_OK_PageDown:
	ld wa, hl
	add wa, 0x14
	ld de, ix
	cp wa, ix
	jr nc, StylCnvCnvt_OK_PageDown_Clamp
	add hl, 0x14
	jrl StylCnvCnvt_OK_StoreSelection

StylCnvCnvt_OK_PageDown_Clamp:
	ld bc, de
	dec 1, bc
	ld ix, bc
	extz xix
	div ix, 0x14
	extz xhl
	div hl, 0x14
	cp hl, ix
	jrl nc, StylCnvCnvt_OK_LoadSelection
	extz xde
	div de, 0x14
	ldto_werp WA, 0xEA
	cps wa, 0
	jrl z, StylCnvCnvt_OK_LoadSelection
	stda16 15620, xbc
	jrl StylCnvCnvt_OK_UpdateDisplay

StylCnvCnvt_OK_SelectItem:
	ldda8 a, 15622
	cps a, 2
	jr z, StylCnvCnvt_OK_Select_WriteStyle
	cps a, 1
	jr nz, StylCnvCnvt_Return
	ldda16 xwa, 18604
	cps wa, 1
	jr z, StylCnvCnvt_OK_Select_Finalize
	cps wa, 0
	jr z, StylCnvCnvt_OK_Select_Finalize
	jr StylCnvCnvt_Return

StylCnvCnvt_OK_Select_WriteStyle:
	ldda32 xwa, 15708
	stda32 15712, xwa
	call FileIO_CheckMediaIsWritable
	ldda16 xbc, 15620
	mul bc, 0x25
	ldada xwa, 21989
	extz xbc
	add xbc, xwa
	ld xwa, xbc
	call FileIO_NormalizePath

StylCnvCnvt_OK_Select_Finalize:
	sti8_24 0x0ffc00, 0xff
	calr TableData_JumpToEntry
	calr FloppyState_Dispatch
	jr StylCnvCnvt_Return

StylCnvCnvt_OK_PageRedraw:
	ldda16 xbc, 14978
	ldw wa, 0x14

StylCnvCnvt_OK_CallRedraw:
	calr DialUI_CalcProlog

StylCnvCnvt_Return:
	lds32 xhl, 0
	pop xiz
	ret
StylCnvCnvt_End:

StylCnvSelTtlFunc:
	push xiz
	ld xhl, xbc
	ldda16 xix, 15620
	ld iz, ix
	ldda16 xbc, 14978
	cp xhl, 0x1C00007
	jr z, StylCnvSel_HandleOK
	cp xhl, 0x1C00013
	jrl nz, StylCnvSel_Return
	cp xde, 0x4
	jr z, StylCnvSel_HandleOpenItem
	cp xde, 0x5
	jr z, StylCnvSel_HandleClose
	cp xde, 0x3
	jr z, StylCnvSel_HandleRedraw
	cp xde, 0x8
	jr z, StylCnvSel_HandleScroll
	cp xde, 0x2
	jrl nz, StylCnvSel_Return
	calr DialUI_PostInitEvents
	stdi16 15620, 0
	ld xwa, 0x150002
	ld xbc, 0x1E4002F
	lds32 xde, 0
	call ApPostEvent
	jrl StylCnvSel_Return

StylCnvSel_HandleScroll:
	ldw wa, 0x14
	ld de, ix
	jrl StylCnvSel_OK_CallRedraw

StylCnvSel_HandleRedraw:
	cpdi8 36148, 6
	call_24 nz, 0xF6BCD6
	lds wa, 0
	jr StylCnvSel_CallReturnAction

StylCnvSel_HandleClose:
	calr DialUI_PostInitEvents
	jrl StylCnvSel_Return

StylCnvSel_HandleOpenItem:
	lds wa, 0

StylCnvSel_CallReturnAction:
	call UI_PostDialEnable
	jrl StylCnvSel_Return

StylCnvSel_HandleOK:
	cp xde, 0xB
	jrl z, StylCnvSel_OK_SelectItem
	cp xde, 0x84
	jrl z, StylCnvSel_OK_PageDown
	cp xde, 0x4
	jrl z, StylCnvSel_OK_PageDown
	cp xde, 0x83
	jrl z, StylCnvSel_OK_ScrollDown
	cp xde, 0x82
	jrl z, StylCnvSel_OK_ScrollDown
	cp xde, 0x3
	jrl z, StylCnvSel_OK_ScrollUp
	cp xde, 0x2
	jrl z, StylCnvSel_OK_ScrollUp
	cp xde, 0x81
	jr z, StylCnvSel_OK_PageUp
	cp xde, 0x1
	jr nz, StylCnvSel_OK_LoadSelection

StylCnvSel_OK_PageUp:
	cp ix, 0x14
	jr c, StylCnvSel_OK_LoadSelection
	sub ix, 0x14

StylCnvSel_OK_StoreSelection:
	stda16 15620, xix

StylCnvSel_OK_LoadSelection:
	ldda16 xbc, 15620

StylCnvSel_OK_UpdateDisplay:
	cp iz, bc
	jrl z, StylCnvSel_Return
	extz xbc
	div bc, 0x14
	ldto_werp DE, 0xE6
	extz xde
	ld xwa, 0x150002
	ld xbc, 0x1E4002F
	call ApPostEvent
	ldda16 xde, 15620
	ld bc, de
	extz xbc
	div bc, 0x14
	ld wa, iz
	extz xwa
	div wa, 0x14
	cp wa, bc
	jrl nz, StylCnvSel_OK_PageRedraw
	mul iz, 0x25
	ldada xbc, 21988
	ld de, iz
	extz xde
	add xde, xbc
	ld xwa, 0x150002
	ld xbc, 0x1C0000F
	call ApPostEvent
	ldda16 xwa, 15620
	mul wa, 0x25
	ldada xbc, 21988
	ld de, wa
	extz xde
	add xde, xbc
	ld xwa, 0x150002
	ld xbc, 0x1C0000F
	call ApPostEvent
	jrl StylCnvSel_Return

StylCnvSel_OK_ScrollUp:
	lds wa, 1
	call UI_PostEvent_0x6E
	ldda16 xwa, 15620
	cps wa, 0
	jrl z, StylCnvSel_OK_LoadSelection
	dec 1, wa
	stda16 15620, xwa
	ld bc, wa
	jrl StylCnvSel_OK_UpdateDisplay

StylCnvSel_OK_ScrollDown:
	lds wa, 1
	call UI_PostEvent_0x6E
	ldda16 xbc, 14978
	dec 1, bc
	ldda16 xwa, 15620
	cp wa, bc
	jrl nc, StylCnvSel_OK_LoadSelection
	inc 1, wa
	stda16 15620, xwa
	ld bc, wa
	jrl StylCnvSel_OK_UpdateDisplay

StylCnvSel_OK_PageDown:
	ld wa, ix
	add wa, 0x14
	ld de, bc
	cp wa, bc
	jr nc, StylCnvSel_OK_PageDown_Clamp
	add ix, 0x14
	jrl StylCnvSel_OK_StoreSelection

StylCnvSel_OK_PageDown_Clamp:
	ld bc, de
	dec 1, bc
	ld hl, bc
	extz xhl
	div hl, 0x14
	ld wa, ix
	extz xwa
	div wa, 0x14
	cp wa, hl
	jrl nc, StylCnvSel_OK_LoadSelection
	extz xde
	div de, 0x14
	ldto_werp WA, 0xEA
	cps wa, 0
	jrl z, StylCnvSel_OK_LoadSelection
	stda16 15620, xbc
	jrl StylCnvSel_OK_UpdateDisplay

StylCnvSel_OK_SelectItem:
	calr SoundMem_ClearRegion
	sti8_24 0x0ffc00, 0xff
	ldda16 xwa, 15620
	inc 1, a
	st8_24 0x0ffc01, a
	calr TableData_JumpToEntry
	calr FloppyState_Dispatch
	jr StylCnvSel_Return

StylCnvSel_OK_PageRedraw:
	ldda16 xbc, 14978
	ldw wa, 0x14

StylCnvSel_OK_CallRedraw:
	calr DialUI_CalcProlog

StylCnvSel_Return:
	lds32 xhl, 0
	pop xiz
	ret
StylCnvSel_End:

StylCnvContTtlFunc:
	cp xbc, 0x1C00007
	jr z, StylCnvCont_HandleOK
	cp xbc, 0x1C00013
	jrl nz, AccRhythm_ReturnZero
	cp xde, 0x3
	jr z, StylCnvCont_HandleClose
	cp xde, 0x8
	jrl z, AccRhythm_ReturnZero
	cp xde, 0x2
	jrl nz, AccRhythm_ReturnZero
	cpdi8 18646, 0
	jr z, StylCnvCont_CheckPending
	stdi8 32578, 15
	ldw wa, 0xEE
	call SoundCtrl_SendCommand
	stdi8 18646, 0

StylCnvCont_CheckPending:
	cpdi8 18650, 0
	jr z, AccRhythm_ReturnZero
	stdi8 32578, 74
	ldw wa, 0xEE
	call SoundCtrl_SendCommand
	stdi8 18650, 0
	jr AccRhythm_ReturnZero

StylCnvCont_HandleClose:
	cpdi8 36148, 6
	jr z, AccRhythm_ReturnZero
	calr Display_RestoreEntry
	jr AccRhythm_ReturnZero

StylCnvCont_HandleOK:
	cp xde, 0xB
	jr z, StylCnvCont_NotifyPart
	cp xde, 0xA
	jr nz, AccRhythm_ReturnZero
	stdi8 15622, 0
	calr SoundMem_ClearRegion
	sti8_24 0x0ffc00, 0xff
	sti8_24 0x0ffc01, 0x00
	pushw 0x4
	pushw 0x0
	pushw 0x3D58
	ld xwa, 0xFFC02
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	calr TableData_JumpToEntry
	calr FloppyState_Dispatch
	jr AccRhythm_ReturnZero

StylCnvCont_NotifyPart:
	lds wa, 1
	call UI_PostPartChangeEvent

AccRhythm_ReturnZero:
	lds32 xhl, 0
	ret
__pad_F6CBDE:

StylCnvStorTtlFunc:
	cp xbc, 0x1C00013
	jr nz, StylCnvStor_ReturnZero
	cp xde, 0x3
	jr z, StylCnvStor_HandleClose
	lds32 xhl, 0
	ret

StylCnvStor_HandleClose:
	cpdi8 36148, 6
	call_24 nz, 0xF6BCD6

StylCnvStor_ReturnZero:
	lds32 xhl, 0
	ret
__pad_F6CBFE:

MainStylCnvFunc:
	extz de
	ld wa, de
	calr AccBankData_ProcessWithCopy
	lds32 xhl, 0
	ret

StylCnv_ReportErrorAndReturn:
	stdi8 18650, 255
	ldw wa, 0x10
	jp UI_PostModeChangeEvent

FloppyState_Dispatch:
	lda xsp, (xsp - 114)
	push xiz

StyleConv_DispatchSoundMemState:
	ld8_24 a, 0x0ffc00
	cps a, 0
	jr nz, StylCnvDisp_CheckFE
	cpdi16 18604, 1
	jr nz, StylCnvDisp_PostMode13
	calr AccBankData_InitAllSlots
	lds wa, 1
	call UI_PostPartChangeEvent
	jrl StylCnv_Epilogue114

StylCnvDisp_PostMode13:
	ldw wa, 0x13
	jrl StylCnv_PostModeChange

StylCnvDisp_CheckFE:
	cp a, 0xFE
	jr nz, StylCnvDisp_CheckType
	stdi8 18650, 255
	ldw wa, 0x16
	jrl StylCnv_PostModeChange

StylCnvDisp_CheckType:
	cps a, 3
	jrl z, StylCnv_Multi_InitAndClear
	cps a, 4
	jrl z, StylCnv_DispatchByType
	cps a, 2
	jr z, StylCnvDisp_Type2_CheckSubtype
	ldada xbc, 15720
	cps a, 1
	jr z, StylCnvDisp_Type1_CopyPath
	cps a, 5
	jrl nz, StylCnv_AbortWithError
	ld xwa, 0xFFC01
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp
	stdi8 15622, 5
	ldw wa, 0x14
	jrl StylCnv_PostModeChange

StylCnvDisp_Type1_CopyPath:
	ld xwa, 0xFFC01
	push xwa
	push xbc
	jr StylCnvDisp_CopyAndFinalize

StylCnvDisp_Type2_CheckSubtype:
	ld8_24 a, 0x0ffc01
	cp a, 0x40
	jrl z, StylCnv_Type4_Init
	cp a, 0x80
	jr z, StylCnvDisp_Subtype80_Process
	cp a, 0x10
	jr z, StylCnvDisp_Subtype10_Process
	cps a, 0
	jrl nz, StyleConv_DispatchSoundMemState
	stdi8 15622, 1
	ld xwa, 0xFFC00
	call ControlState_ProcessCommand
	ldada xbc, 15624
	ld (xbc), 0x2
	ld (xbc + 1), 0x0
	ld xwa, 0xFFC02
	push xwa
	lda xwa, (xbc + 2)
	push xwa
	jr StylCnvDisp_CopyAndFinalize

StylCnvDisp_Subtype10_Process:
	stdi8 15622, 2
	ld xwa, 0xFFC00
	call ControlState_ProcessCommand
	ld xwa, 0xFFC00
	push xwa
	ldada xwa, 15624
	push xwa

StylCnvDisp_CopyAndFinalize:
	call Strcpy
	inc 8, xsp
	jrl StylCnv_ClearAndFinalize

StylCnvDisp_Subtype80_Process:
	cpi8_24 0x0ffc02, 0x2e
	jrl nz, ControlState_Type3
	stdi8 15622, 6
	calr StyleBuf_ClearAllEntries
	calr StyleConv_ClearWorkBuffer
	ldw (xsp + 4), 0x0
	stdi16 18648, 0

StylCnvDisp_ScanFileLoop:
	pushw 0x3
	pushw 0xE4
	pushw 0xC14E
	ld wa, (xsp + 10)
	inc 2, wa
	extz xwa
	add xwa, 0xFFC00
	push xwa
	call String_Compare
	add xsp, 0xA
	cps hl, 0
	jr z, StylCnv_ParseEntry_Done
	ld wa, (xsp + 4)
	inc 2, wa
	extz xwa
	add xwa, 0xFFC00
	ld a, (xwa)
	cp a, 0x2A
	jrl z, ControlState_Type3
	cp a, 0x3F
	jrl z, ControlState_Type3
	ldw (xsp + 6), 0x0

StylCnv_ParseEntry_ScanChar:
	ld wa, (xsp + 4)
	inc 2, wa
	extz xwa
	add xwa, 0xFFC00
	ld a, (xwa)
	cp a, 0x2C
	jr nz, StylCnv_ParseEntry_StoreChar
	incdi16 1, 18648
	jr StylCnv_ParseEntry_NextField

StylCnv_ParseEntry_StoreChar:
	ldda16 xbc, 18648
	sll bc, 5
	ld de, (xsp + 6)
	add de, bc
	ldada xbc, 16264
	extz xde
	add xde, xbc
	ld (xde), a
	incm 1, (xsp + 6)
	incm 1, (xsp + 4)
	cpw (xsp + 6), 0x20
	jr lt, StylCnv_ParseEntry_ScanChar

StylCnv_ParseEntry_NextField:
	incm 1, (xsp + 4)
	cpw (xsp + 4), 0x80
	jrl lt, StylCnvDisp_ScanFileLoop

StylCnv_ParseEntry_Done:
	ldw (xsp + 4), 0x0
	ldda16 xix, 15620
	mul ix, 0x25
	ldada xhl, 21988

StylCnv_CopyNameLoop:
	ld wa, (xsp + 4)
	add wa, ix
	extz xwa
	add xwa, xhl
	ld c, (xwa + 1)
	cp c, 0x2E
	jr z, StylCnv_CopyName_Finalize
	ldada xde, 18572
	ld wa, (xsp + 4)
	lda_dri3 XHL, 0x07, 0xE8, 0xE0
	incm 1, (xsp + 4)
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_CopyNameLoop

StylCnv_CopyName_Finalize:
	pushw 0x0
	pushw 0x3F88
	pushw 0x0
	pushw 0x488C
	jrl StylCnv_AppendAndClear

ControlState_Type3:
	stdi8 15622, 3
	ld xwa, 0xFFC00
	call ControlState_ProcessCommand
	jrl StylCnv_ClearAndFinalize

StylCnv_Type4_Init:
	stdi8 15622, 4
	ldada xde, 18614
	ld xwa, xde
	lda xbc, (xde + 32)

StylCnv_Type4_ClearLoop:
	stib_dpi 0xE0, 0x00
	cp xwa, xbc
	jr c, StylCnv_Type4_ClearLoop
	ldw (xsp + 4), 0x0
	lds iz, 0

StylCnv_Type4_MainLoop:
	cpw (xsp + 4), 0x0
	jr nz, LoopIndex_Reset
	ldw (xsp + 6), 0x0
	cpw (xsp + 4), 0x28
	jr ge, LoopIndex_Reset

StylCnv_Type4_CopyChars:
	ld wa, (xsp + 4)
	inc 2, wa
	extz xwa
	add xwa, 0xFFC00
	ld c, (xwa)
	cps c, 0
	jr z, LoopIndex_Reset
	ld wa, (xsp + 6)
	lda_dri3 XHL, 0x07, 0xE8, 0xE0
	incm 1, (xsp + 4)
	incm 1, (xsp + 6)
	cpw (xsp + 4), 0x28
	jr lt, StylCnv_Type4_CopyChars

LoopIndex_Reset:
	ldw (xsp + 6), 0x0

StylCnv_Type4_FindDot:
	ld wa, (xsp + 6)
	cp_srib_im 0x07, 0xE8, 0xE0, 0x2E
	jr z, StylCnv_Type4_CalcExtLen
	incm 1, (xsp + 6)
	cpw (xsp + 6), 0x20
	jr lt, StylCnv_Type4_FindDot

StylCnv_Type4_CalcExtLen:
	ldw (xsp + 16), 0x0

StylCnv_Type4_CountExt:
	ld wa, (xsp + 6)
	cp_srib_im 0x07, 0xE8, 0xE0, 0x00
	jr z, StylCnv_Type4_CalcCenter
	incm 1, (xsp + 16)
	incm 1, (xsp + 6)
	cpw (xsp + 16), 0x20
	jr lt, StylCnv_Type4_CountExt

StylCnv_Type4_CalcCenter:
	ld wa, (xsp + 16)
	exts xwa
	divs wa, 0x2
	ldto_werp WA, 0xE2
	ldi_werp 0xFA, 1
	cps wa, 0
	jr nz, StylCnv_Type4_CheckNull
	ldi_werp 0xFA, 2

StylCnv_Type4_CheckNull:
	ld wa, (xsp + 4)
	inc 2, wa
	extz xwa
	add xwa, 0xFFC00
	cp (xwa), 0x0
	jr nz, StylCnv_Type4_Advance
	inc 1, iz
	cp_werp IZ, 0xFA
	jr nz, StylCnv_Type4_Advance
	incm 1, (xsp + 4)
	pushw 0x4
	ld wa, (xsp + 6)
	inc 2, wa
	extz xwa
	add xwa, 0xFFC00
	push xwa
	pushw 0x0
	pushw 0x48AE
	call Mem_Copy
	incm 4, (xsp + 14)
	pushw 0x4
	ld wa, (xsp + 16)
	inc 2, wa
	extz xwa
	add xwa, 0xFFC00
	push xwa
	pushw 0x0
	pushw 0x48B2
	call Mem_Copy
	lda xsp, (xsp + 20)
	jr StylCnv_Type4_BuildOutput

StylCnv_Type4_Advance:
	incm 1, (xsp + 4)
	cpw (xsp + 4), 0x20
	jrl lt, StylCnv_Type4_MainLoop

StylCnv_Type4_BuildOutput:
	calr StyleConv_ClearWorkBuffer
	ldw (xsp + 4), 0x0
	ldda16 xix, 15620
	mul ix, 0x25
	ldada xhl, 21988

StylCnv_Type4_CopyNameLoop2:
	ld wa, (xsp + 4)
	add wa, ix
	extz xwa
	add xwa, xhl
	ld e, (xwa + 1)
	ldada xbc, 18572
	cp e, 0x2E
	jr z, StylCnv_Type4_AppendExt
	ld wa, (xsp + 4)
	lda_dri3 XIY, 0x07, 0xE4, 0xE0
	incm 1, (xsp + 4)
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_Type4_CopyNameLoop2

StylCnv_Type4_AppendExt:
	pushw 0x0
	pushw 0x48B6
	push xbc

StylCnv_AppendAndClear:
	call Strcat
	inc 8, xsp

StylCnv_ClearAndFinalize:
	sti8_24 0x0ffc00, 0xff
	jrl StylCnv_FinalizeAndCheckStatus

StylCnv_DispatchByType:
	ldda8 a, 15622
	cps a, 6
	jrl z, StylCnv_Type6_Dispatch
	cps a, 4
	jrl z, StylCnv_Type4_OpenFile
	cps a, 3
	jr z, StylCnv_Type3_ProcessFiles
	cps a, 2
	jr z, StylCnv_Type2_CheckSoundMem
	cps a, 1
	jrl nz, StyleConv_DispatchSoundMemState
	cpdi8 36150, 22
	jrl nz, StylCnv_Epilogue114
	ldw wa, 0x12
	jrl StylCnv_PostModeChange

StylCnv_Type2_CheckSoundMem:
	cpdi8 36150, 22
	jrl nz, StylCnv_Epilogue114
	ldw wa, 0x12
	jrl StylCnv_PostModeChange

StylCnv_Type3_ProcessFiles:
	ldda32 xwa, 15708
	ld (xsp + 10), xwa
	ldw (xsp + 4), 0x0
	calr StyleConv_ClearEntryTables
	calr StyleFile_ClearAllTables
	ld xwa, 0x488C
	ld xbc, 0x4888
	call FileIO_SearchStringMatch
	cps hl, 0
	jr lt, StylCnv_Type3_CheckCount

StylCnv_Type3_SearchLoop:
	cpw (xsp + 4), 0x20
	jr ge, StylCnv_Type3_SearchNext
	ldda32 xwa, 18568
	cp xwa, 0x0
	jr lt, StylCnv_Type3_SearchNext
	call FileIO_ExtractBasename
	push xhl
	lda xwa, (xsp + 22)
	push xwa
	call Strcpy
	pushw 0x0
	pushw 0x488C
	lda xwa, (xsp + 30)
	push xwa
	call Strcat
	lda xwa, (xsp + 34)
	push xwa
	ld wa, (xsp + 24)
	mul wa, 0x64
	ldada xbc, 18652
	extz xwa
	add xwa, xbc
	push xwa
	call Strcpy
	lda xsp, (xsp + 24)
	ld de, (xsp + 4)
	sll de, 2
	ldada xbc, 21852
	extz xde
	add xde, xbc
	ldda32 xwa, 18568
	ld (xde), xwa
	incm 1, (xsp + 4)

StylCnv_Type3_SearchNext:
	ld xwa, 0x488C
	ld xbc, 0x4888
	call FileIO_SearchStringMatch
	cps hl, 0
	jr ge, StylCnv_Type3_SearchLoop

StylCnv_Type3_CheckCount:
	cpw (xsp + 4), 0x0
	jrl z, StylCnv_AbortWithError
	ldw (xsp + 8), 0x0
	cpw (xsp + 4), 0x0
	jrl le, StylCnv_Type3_BuildFfcBuffer

StylCnv_Type3_LoadFileLoop:
	ld wa, (xsp + 8)
	mul wa, 0x64
	ldada xbc, 18652
	extz xwa
	add xwa, xbc
	push xwa
	lda xwa, (xsp + 22)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xwa, (xsp + 18)
	ld xbc, 0xE4C152
	call FileIO_OpenWithBuiltPath
	cps hl, 0
	jrl lt, StylCnv_AbortWithError
	ld wa, (xsp + 8)
	sll wa, 2
	ldada xbc, 21852
	extz xwa
	add xwa, xbc
	ld xbc, (xwa)
	stda32 18568, xbc
	ld xwa, (xsp + 10)
	call FileIO_ReadBlock
	cp xhl, 0x0
	jrl lt, FileIO_ErrorExit
	ld bc, (xsp + 8)
	sll bc, 2
	ldada xwa, 18312
	extz xbc
	add xbc, xwa
	ld xwa, (xsp + 10)
	ld (xbc), xwa
	ldda32 xwa, 18568
	add (xsp + 10), xwa
	ld xwa, (xsp + 10)
	stda32 15712, xwa
	pushw 0x2E
	lda xwa, (xsp + 20)
	push xwa
	call AudioCmd_StringLength
	inc 6, xsp
	ld wa, (xsp + 8)
	ldada xbc, 16264
	sll wa, 5
	extz xwa
	add xwa, xbc
	or xhl, xhl
	jr z, StylCnv_Type3_EmptyName
	push xhl
	push xwa
	call Strcpy
	inc 8, xsp
	jr StylCnv_Type3_CloseFile

StylCnv_Type3_EmptyName:
	ld (xwa), 0x0

StylCnv_Type3_CloseFile:
	call FileIO_CloseHandle
	incm 1, (xsp + 8)
	ld wa, (xsp + 8)
	cp wa, (xsp + 4)
	jrl lt, StylCnv_Type3_LoadFileLoop

StylCnv_Type3_BuildFfcBuffer:
	calr SoundMem_ClearRegion
	sti8_24 0x0ffc00, 0xff
	sti8_24 0x0ffc01, 0x00
	ldw (xsp + 16), 0x0
	ldi_werp 0xFA, 0
	cpw (xsp + 4), 0x0
	jrl le, StylCnv_FinalizeAndCheckStatus

StylCnv_Type3_CopyBlockLoop:
	pushw 0x4
	ld bc, (xsp + 18)
	sll bc, 2
	ldada xwa, 18312
	extz xbc
	add xbc, xwa
	push xbc
	ldto_werp WA, 0xFA
	inc 2, wa
	extz xwa
	add xwa, 0xFFC00
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	inc4_werp 0xFA
	lds iz, 0
	ld bc, (xsp + 16)
	sll bc, 5
	ldada xde, 16264

StylCnv_Type3_CopyNameChars:
	ld wa, iz
	inc 1, wa
	add wa, bc
	extz xwa
	add xwa, xde
	ld a, (xwa)
	cps a, 0
	jr z, StylCnv_Type3_TerminateName
	ldto_werp HL, 0xFA
	inc 2, hl
	extz xhl
	add xhl, 0xFFC00
	ld (xhl), a
	inc1_werp 0xFA
	inc 1, iz
	cp iz, 0x20
	jr lt, StylCnv_Type3_CopyNameChars

StylCnv_Type3_TerminateName:
	ldto_werp WA, 0xFA
	inc 2, wa
	extz xwa
	add xwa, 0xFFC00
	ld (xwa), 0x0
	inc1_werp 0xFA
	ld wa, iz
	exts xwa
	divs wa, 0x2
	ldto_werp WA, 0xE2
	cps wa, 0
	jr nz, StylCnv_Type3_NextBlock
	ldto_werp WA, 0xFA
	inc 2, wa
	extz xwa
	add xwa, 0xFFC00
	ld (xwa), 0x0
	inc1_werp 0xFA

StylCnv_Type3_NextBlock:
	incm 1, (xsp + 16)
	ld wa, (xsp + 16)
	cp wa, (xsp + 4)
	jrl lt, StylCnv_Type3_CopyBlockLoop
	jrl StylCnv_FinalizeAndCheckStatus

StylCnv_Type4_OpenFile:
	ld xwa, 0x488C
	ld xbc, 0xE4C156
	call FileIO_OpenWithMode
	cps hl, 0
	jr lt, StylCnv_AbortWithError
	lds32 xwa, 0
	lds bc, 2
	call FileIO_SeekAndReadBlock
	cps hl, 0
	jr lt, FileIO_ErrorExit
	call FileIO_SeekWriteBlock_Impl
	stda32 15716, xhl
	call FileIO_SeekRead_ExtReturn
	ldda32 xwa, 18606
	lds bc, 0
	call FileIO_SeekAndReadBlock
	cps hl, 0
	jr lt, FileIO_ErrorExit
	ldda32 xwa, 15708
	ldda32 xbc, 18610
	call FileIO_ReadBlock
	cp xhl, 0x0
	jr ge, StylCnv_Type4_ClearAndBuild

FileIO_ErrorExit:
	call FileIO_CloseHandle

StylCnv_AbortWithError:
	calr StylCnv_ReportErrorAndReturn
	jrl StylCnv_Epilogue114

StylCnv_Type4_ClearAndBuild:
	calr SoundMem_ClearRegion
	sti8_24 0x0ffc00, 0xff
	sti8_24 0x0ffc01, 0x00
	pushw 0x4
	pushw 0x0
	pushw 0x3D5C
	ld xwa, 0xFFC02
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	ldw (xsp + 4), 0x0
	ldada xde, 18614

StylCnv_Type4_CopyFieldLoop:
	ld bc, (xsp + 4)
	inc 6, bc
	extz xbc
	add xbc, 0xFFC00
	ld wa, (xsp + 4)
	inc 1, wa
	ld_srib3 A, 0x07, 0xE8, 0xE0
	ld (xbc), a
	cps a, 0
	jrl z, StylCnv_FinalizeAndCheckStatus
	incm 1, (xsp + 4)
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_Type4_CopyFieldLoop
	jrl StylCnv_FinalizeAndCheckStatus

StylCnv_Type6_Dispatch:
	ldda16 xwa, 18604
	cps wa, 1
	jrl z, StylCnv_Type6_Case1_CopyName
	cps wa, 0
	jrl nz, StyleConv_DispatchSoundMemState
	ldada xwa, 18312
	ld xbc, xwa
	st_dri3b B, 0xE1, 0x00, 0x01

StylCnv_Type6_ClearRegion:
	lds32 xwa, 0
	st_dpil XWA, 0xE6
	cp xbc, xde
	jr c, StylCnv_Type6_ClearRegion
	ldda32 xwa, 15708
	stda32 15712, xwa
	ldw (xsp + 4), 0x0
	cpdi16 18648, 0
	jrl ule, StylCnv_Type6_BuildFfcBuffer

StylCnv_Type6_MainLoop:
	lds iz, 0
	ldada xbc, 18572

StylCnv_Type6_FindDot:
	cp_srib_im 0x07, 0xE4, 0xF8, 0x2E
	jr z, StylCnv_Type6_ClearRemainder
	inc 1, iz
	cp iz, 0x20
	jr lt, StylCnv_Type6_FindDot

StylCnv_Type6_ClearRemainder:
	cp iz, 0x20
	jr ge, StylCnv_Type6_AppendName

StylCnv_Type6_ClearLoop:
	stib_dri 0x07, 0xE4, 0xF8, 0x00
	inc 1, iz
	cp iz, 0x20
	jr lt, StylCnv_Type6_ClearLoop

StylCnv_Type6_AppendName:
	ld de, (xsp + 4)
	sll de, 5
	ldada xwa, 16264
	extz xde
	add xde, xwa
	push xde
	push xbc
	call Strcat
	inc 8, xsp
	ld xwa, 0x488C
	ld xbc, 0xE4C15A
	call FileIO_OpenWithMode
	cps hl, 0
	jrl lt, StylCnv_Type6_FileOpenError
	lds32 xwa, 0
	lds bc, 2
	call FileIO_SeekAndReadBlock
	cps hl, 0
	jrl lt, StylCnv_Type6_FileReadError
	call FileIO_SeekWriteBlock_Impl
	stda32 15716, xhl
	call FileIO_SeekRead_ExtReturn
	ldda32 xwa, 15712
	ldda32 xbc, 15716
	call FileIO_ReadBlock
	call FileIO_CloseHandle
	cp xhl, 0x0
	jrl lt, StylCnv_AbortWithError
	ld bc, (xsp + 4)
	sll bc, 2
	ldada xwa, 18312
	extz xbc
	add xbc, xwa
	ldda32 xwa, 15712
	ld (xbc), xwa
	ldda32 xwa, 15716
	adddm32 15712, xwa

StylCnv_Type6_AdvanceEntry:
	incm 1, (xsp + 4)
	ld wa, (xsp + 4)
	cpda16 xwa, 18648
	jrl c, StylCnv_Type6_MainLoop

StylCnv_Type6_BuildFfcBuffer:
	calr SoundMem_ClearRegion
	sti8_24 0x0ffc00, 0xff
	sti8_24 0x0ffc01, 0x00
	ldw (xsp + 4), 0x0
	lds iz, 0
	cpdi16 18648, 0
	jrl ule, StylCnv_FinalizeAndCheckStatus

StylCnv_Type6_CopyBlockLoop:
	ld bc, (xsp + 4)
	sll bc, 2
	ldada xde, 18312
	extz xbc
	add xbc, xde
	ld xwa, (xbc)
	or xwa, xwa
	jrl z, StylCnv_Type6_NextBlock
	pushw 0x4
	push xbc
	ld wa, iz
	inc 2, wa
	extz xwa
	add xwa, 0xFFC00
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	inc 4, iz
	ldw (xsp + 6), 0x0
	ld bc, (xsp + 4)
	sll bc, 5
	ldada xde, 16264

StylCnv_Type6_CopyNameChars:
	ld wa, (xsp + 6)
	inc 1, wa
	add wa, bc
	extz xwa
	add xwa, xde
	ld a, (xwa)
	cps a, 0
	jr z, StylCnv_Type6_TerminateName
	ld hl, iz
	inc 2, hl
	extz xhl
	add xhl, 0xFFC00
	ld (xhl), a
	inc 1, iz
	incm 1, (xsp + 6)
	cpw (xsp + 6), 0x20
	jr lt, StylCnv_Type6_CopyNameChars

StylCnv_Type6_TerminateName:
	ld wa, iz
	inc 2, wa
	extz xwa
	add xwa, 0xFFC00
	ld (xwa), 0x0
	inc 1, iz
	ld wa, (xsp + 6)
	exts xwa
	divs wa, 0x2
	ldto_werp WA, 0xE2
	cps wa, 0
	jr nz, StylCnv_Type6_NextBlock
	ld wa, iz
	inc 2, wa
	extz xwa
	add xwa, 0xFFC00
	ld (xwa), 0x0
	inc 1, iz

StylCnv_Type6_NextBlock:
	incm 1, (xsp + 4)
	ld wa, (xsp + 4)
	cpda16 xwa, 18648
	jrl c, StylCnv_Type6_CopyBlockLoop
	jrl StylCnv_FinalizeAndCheckStatus

StylCnv_Type6_FileReadError:
	ld bc, (xsp + 4)
	sll bc, 5
	ldada xwa, 16264
	extz xbc
	add xbc, xwa
	ld (xbc), 0x0
	cpdi16 18648, 2
	jrl nc, StylCnv_Type6_AdvanceEntry
	jrl StylCnv_AbortWithError

StylCnv_Type6_FileOpenError:
	ld bc, (xsp + 4)
	sll bc, 5
	ldada xwa, 16264
	extz xbc
	add xbc, xwa
	ld (xbc), 0x0
	cpdi16 18648, 2
	jrl nc, StylCnv_Type6_AdvanceEntry
	jrl StylCnv_AbortWithError

StylCnv_Type6_Case1_CopyName:
	ldda16 xbc, 15620
	mul bc, 0x25
	ldada xwa, 21989
	extz xbc
	add xbc, xwa
	push xbc
	lda xwa, (xsp + 22)
	push xwa
	call Strcpy
	inc 8, xsp
	ldda32 xwa, 15708
	ld (xsp + 10), xwa
	ldw (xsp + 8), 0x0
	lda xwa, (xsp + 18)
	ld xbc, 0xE4C15E
	call FileIO_OpenWithMode
	cps hl, 0
	jrl lt, StylCnv_AbortWithError
	lds32 xwa, 0
	lds bc, 2
	call FileIO_SeekAndReadBlock
	cps hl, 0
	jrl lt, StylCnv_Epilogue114
	call FileIO_SeekWriteBlock_Impl
	ld (xsp + 14), xhl
	call FileIO_SeekRead_ExtReturn
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 14)
	call FileIO_ReadBlock
	call FileIO_CloseHandle
	cp xhl, 0x0
	jrl lt, StylCnv_AbortWithError
	ld xwa, (xsp + 10)
	stda32 18312, xwa
	ld xwa, (xsp + 14)
	add (xsp + 10), xwa
	ldw (xsp + 4), 0x0
	lda xwa, (xsp + 18)

StylCnv_Single_FindDot:
	ld bc, (xsp + 4)
	cp_srib_im 0x07, 0xE0, 0xE4, 0x2E
	jr z, StylCnv_Single_CopyExtension
	incm 1, (xsp + 4)
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_Single_FindDot

StylCnv_Single_CopyExtension:
	lds iz, 0
	cpw (xsp + 4), 0x20
	jr ge, StylCnv_Single_RenameTM

StylCnv_Single_CopyExt_Loop:
	ld de, iz
	ldada xbc, 16264
	extz xde
	add xde, xbc
	ld bc, (xsp + 4)
	ld_srib3 C, 0x07, 0xE0, 0xE4
	ld (xde), c
	cps c, 0
	jr z, StylCnv_Single_RenameTM
	incm 1, (xsp + 4)
	inc 1, iz
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_Single_CopyExt_Loop

StylCnv_Single_RenameTM:
	ldw (xsp + 4), 0x0

StylCnv_Single_FindDot2:
	ld bc, (xsp + 4)
	exts xbc
	add xbc, xwa
	incm 1, (xsp + 4)
	cp (xbc), 0x2E
	jr z, StylCnv_Single_WriteTMExtension
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_Single_FindDot2

StylCnv_Single_WriteTMExtension:
	ld bc, (xsp + 4)
	stib_dri 0x07, 0xE0, 0xE4, 0x54
	ld bc, (xsp + 4)
	inc 1, bc
	stib_dri 0x07, 0xE0, 0xE4, 0x4D
	ld bc, (xsp + 4)
	inc 2, bc
	stib_dri 0x07, 0xE0, 0xE4, 0x00
	ld xbc, 0xE4C162
	call FileIO_OpenWithMode
	cps hl, 0
	jrl lt, DRI_ParseFieldsAndOpenFile
	lds32 xwa, 0
	lds bc, 2
	call FileIO_SeekAndReadBlock
	cps hl, 0
	jrl lt, DRI_ParseFieldsAndOpenFile
	ldw (xsp + 8), 0x1
	call FileIO_SeekWriteBlock_Impl
	ld (xsp + 14), xhl
	call FileIO_SeekRead_ExtReturn
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 14)
	call FileIO_ReadBlock
	call FileIO_CloseHandle
	cp xhl, 0x0
	jrl lt, StylCnv_AbortWithError
	ld xwa, (xsp + 10)
	stda32 18316, xwa
	ld xwa, (xsp + 14)
	add (xsp + 10), xwa
	ldw (xsp + 4), 0x0
	lda xbc, (xsp + 18)

StylCnv_LSW_FindDot:
	ld wa, (xsp + 4)
	cp_srib_im 0x07, 0xE4, 0xE0, 0x2E
	jr z, StylCnv_LSW_CopyExtension
	incm 1, (xsp + 4)
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_LSW_FindDot

StylCnv_LSW_CopyExtension:
	lds iz, 0
	cpw (xsp + 4), 0x20
	jr ge, DRI_ParseFieldsAndOpenFile

StylCnv_LSW_CopyExt_Loop:
	ld de, iz
	add de, 0x20
	ldada xwa, 16264
	extz xde
	add xde, xwa
	ld wa, (xsp + 4)
	ld_srib3 A, 0x07, 0xE4, 0xE0
	ld (xde), a
	cps a, 0
	jr z, DRI_ParseFieldsAndOpenFile
	incm 1, (xsp + 4)
	inc 1, iz
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_LSW_CopyExt_Loop

DRI_ParseFieldsAndOpenFile:
	ldw (xsp + 4), 0x0
	lda xwa, (xsp + 18)

StylCnv_LSW_FindDot2:
	ld bc, (xsp + 4)
	exts xbc
	add xbc, xwa
	incm 1, (xsp + 4)
	cp (xbc), 0x2E
	jr z, StylCnv_LSW_WriteExtension
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_LSW_FindDot2

StylCnv_LSW_WriteExtension:
	ld bc, (xsp + 4)
	stib_dri 0x07, 0xE0, 0xE4, 0x4C
	ld bc, (xsp + 4)
	inc 1, bc
	stib_dri 0x07, 0xE0, 0xE4, 0x53
	ld bc, (xsp + 4)
	inc 2, bc
	stib_dri 0x07, 0xE0, 0xE4, 0x57
	ld bc, (xsp + 4)
	inc 3, bc
	stib_dri 0x07, 0xE0, 0xE4, 0x00
	ld xbc, 0xE4C166
	call FileIO_OpenWithMode
	cps hl, 0
	jrl lt, FileLoad_ResetAndStartProcessing
	lds32 xwa, 0
	lds bc, 2
	call FileIO_SeekAndReadBlock
	cps hl, 0
	jrl lt, FileLoad_ResetAndStartProcessing
	incm 1, (xsp + 8)
	call FileIO_SeekWriteBlock_Impl
	ld (xsp + 14), xhl
	call FileIO_SeekRead_ExtReturn
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 14)
	call FileIO_ReadBlock
	call FileIO_CloseHandle
	cp xhl, 0x0
	jrl lt, StylCnv_AbortWithError
	ld bc, (xsp + 8)
	ld (xsp + 16), bc
	sla bc, 2
	ldada xwa, 18312
	extz xbc
	add xbc, xwa
	ld xwa, (xsp + 10)
	ld (xbc), xwa
	ldw (xsp + 4), 0x0
	lda xbc, (xsp + 18)

StylCnv_LSW_FindDot3:
	ld wa, (xsp + 4)
	cp_srib_im 0x07, 0xE4, 0xE0, 0x2E
	jr z, StylCnv_LSW_CopyExt3
	incm 1, (xsp + 4)
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_LSW_FindDot3

StylCnv_LSW_CopyExt3:
	lds iz, 0
	cpw (xsp + 4), 0x20
	jr ge, FileLoad_ResetAndStartProcessing

StylCnv_LSW_CopyExt3_Loop:
	ld wa, (xsp + 16)
	sll wa, 5
	ld de, iz
	add de, wa
	ldada xwa, 16264
	extz xde
	add xde, xwa
	ld wa, (xsp + 4)
	ld_srib3 A, 0x07, 0xE4, 0xE0
	ld (xde), a
	cps a, 0
	jr z, FileLoad_ResetAndStartProcessing
	incm 1, (xsp + 4)
	inc 1, iz
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_LSW_CopyExt3_Loop

FileLoad_ResetAndStartProcessing:
	calr SoundMem_ClearRegion
	sti8_24 0x0ffc00, 0xff
	sti8_24 0x0ffc01, 0x00
	ldw (xsp + 4), 0x0
	lds iz, 0
	ld wa, (xsp + 8)
	add wa, 0x1
	jrl le, StylCnv_FinalizeAndCheckStatus

StylCnv_Final_CopyBlockLoop:
	pushw 0x4
	ld bc, (xsp + 6)
	sll bc, 2
	ldada xwa, 18312
	extz xbc
	add xbc, xwa
	push xbc
	ld wa, iz
	inc 2, wa
	extz xwa
	add xwa, 0xFFC00
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	inc 4, iz
	ldw (xsp + 6), 0x0
	ld bc, (xsp + 4)
	sll bc, 5
	ldada xde, 16264

StylCnv_Final_CopyNameChars:
	ld wa, (xsp + 6)
	inc 1, wa
	add wa, bc
	extz xwa
	add xwa, xde
	ld a, (xwa)
	cps a, 0
	jr z, StylCnv_Final_TerminateName
	ld hl, iz
	inc 2, hl
	extz xhl
	add xhl, 0xFFC00
	ld (xhl), a
	inc 1, iz
	incm 1, (xsp + 6)
	cpw (xsp + 6), 0x20
	jr lt, StylCnv_Final_CopyNameChars

StylCnv_Final_TerminateName:
	ld wa, iz
	inc 2, wa
	extz xwa
	add xwa, 0xFFC00
	ld (xwa), 0x0
	inc 1, iz
	ld wa, (xsp + 6)
	exts xwa
	divs wa, 0x2
	ldto_werp WA, 0xE2
	cps wa, 0
	jr nz, StylCnv_Final_NextBlock
	ld wa, iz
	inc 2, wa
	extz xwa
	add xwa, 0xFFC00
	ld (xwa), 0x0
	inc 1, iz

StylCnv_Final_NextBlock:
	incm 1, (xsp + 4)
	ld wa, (xsp + 8)
	inc 1, wa
	cp (xsp + 4), wa
	jrl lt, StylCnv_Final_CopyBlockLoop

StylCnv_FinalizeAndCheckStatus:
	calr TableData_JumpToEntry
	jrl StyleConv_DispatchSoundMemState

StylCnv_Multi_InitAndClear:
	calr StyleConv_InitEntryTable
	stdi16 14978, 0
	lda xbc, (xsp + 18)
	ld xwa, xbc
	lda xbc, (xbc + 100)

StylCnv_Multi_ClearLoop:
	stib_dpi 0xE0, 0x00
	cp xwa, xbc
	jr c, StylCnv_Multi_ClearLoop
	ldw (xsp + 4), 0x0
	lds iz, 0

StylCnv_Multi_ParseLoop:
	ldada xbc, 15720
	ld wa, (xsp + 4)
	st_dri3b C, 0x07, 0xE4, 0xE0
	ld e, (xhl)
	lda xbc, (xsp + 18)
	ldada xwa, 21988
	ld (xsp + 14), xwa
	cps e, 0
	jr nz, StylCnv_Multi_HandleSeparator
	cps iz, 0
	jr le, StylCnv_Multi_Finalize
	push xbc
	ld wa, iz
	dec 1, wa
	mul wa, 0x25
	extz xwa
	add xwa, (xsp + 18)
	inc 1, xwa
	push xwa
	call Strcpy
	inc 8, xsp
	incdi16 1, 14978
	jr StylCnv_Multi_Finalize

StylCnv_Multi_HandleSeparator:
	cp e, 0x7C
	jr nz, StylCnv_Multi_CopyChar
	ld (xhl), 0x0
	ldw (xsp + 6), 0x0
	inc 1, iz
	cps iz, 1
	jr le, LoopCounter_Increment
	push xbc
	ld wa, iz
	dec 2, wa
	mul wa, 0x25
	extz xwa
	add xwa, (xsp + 18)
	inc 1, xwa
	push xwa
	call Strcpy
	inc 8, xsp
	lda xbc, (xsp + 18)
	ld xwa, xbc
	lda xbc, (xbc + 100)

StylCnv_Multi_ClearSubLoop:
	stib_dpi 0xE0, 0x00
	cp xwa, xbc
	jr c, StylCnv_Multi_ClearSubLoop
	incdi16 1, 14978
	jr LoopCounter_Increment

StylCnv_Multi_CopyChar:
	cps iz, 0
	jr le, LoopCounter_Increment
	ld wa, (xsp + 6)
	lda_dri3 XIY, 0x07, 0xE4, 0xE0
	ld (xhl), 0x0
	incm 1, (xsp + 6)

LoopCounter_Increment:
	incm 1, (xsp + 4)
	ld wa, (xsp + 4)
	cp wa, 0x200
	jrl c, StylCnv_Multi_ParseLoop

StylCnv_Multi_Finalize:
	ldw wa, 0x15

StylCnv_PostModeChange:
	call UI_PostModeChangeEvent

StylCnv_Epilogue114:
	pop xiz
	lda xsp, (xsp + 114)
	ret

TableData_JumpToEntry:
	ld xhl, 0x80000
	jp (xhl)
AccStyle_TableDataEntry:
	call	15665047
	cps	hl, 0
	ret	z
	cpdi8	49277, 65
	ret	nz
	.byte 0xf1, 0x7f, 0xc0, 0xc8
	ret	z
	ldda8	c, 36150
	.byte 0xf1, 0x7e, 0xc0, 0xc8
	jr	z, 10
	cp	c, 17
	ret	nz
	ldw	wa, 16
	jr	98
	ldda8	a, 15622
	cp	c, 18
	jr	z, 61
	cp	c, 20
	jr	z, 18
	cp	c, 16
	ret	nz
	call	16296980
	cps	hl, 0
	ret	nz
	ldw	wa, 17
	jr	66
	cps	a, 2
	jr	z, 21
	cps	a, 5
	jr	z, 4
	cps	a, 1
	ret	nz
	call	16296980
	cps	hl, 0
	ret	nz
	ldw	wa, 18
	jr	41
	call	16296980
	cps	hl, 0
	ret	nz
	ldw	wa, 18
	jr	28
	cps	a, 2
	jr	z, 4
	cps	a, 1
	ret	nz
	call	16296980
	cps	hl, 0
	ret	nz
	ld	xwa, 15624
	call	16297253
	ldw	wa, 18
	call	16356496
	ret
	lda	xsp, (xsp-34)
	push	xiz
	ld	(xsp+34), c
	ld	(xsp+36), a
	ld	xiy, 14991752
	lda	xix, (xsp+4)
	ldw	bc, 15
	ldirw
	lda_24	xde, 608256
	lda_24	xbc, 700416
	sub	xbc, xde
	ld	xwa, 432128
	call	16289140
	cp	xhl, 0
	jrl	lt, 731
	lda_24	xbc, 432128
	stda32	31460, xbc
	lda_24	xwa, 608256
	stda32	31464, xwa
	stdi8	14672, 0
	ld	a, (xbc)
	ldfr_berp	a, 249
	ld	a, (xbc+1)
	ldfr_berp	a, 250
	ld	a, (xbc+2)
	ldfr_berp	a, 251
	.byte 0xc7, 0xf9, 0xcf, 0x48
	jr	nz, 11
	cpi_berp	250, 0
	jr	nz, 6
	.byte 0xc7, 0xfb, 0xcf, 0x4b
	jr	z, 38
	.byte 0xc7, 0xf9, 0xcf, 0x47
	jr	nz, 11
	cpi_berp	250, 0
	jr	nz, 6
	.byte 0xc7, 0xfb, 0xcf, 0x4b
	jr	z, 21
	.byte 0xc7, 0xf9, 0xcf, 0x4c
	jrl	nz, 336
	.byte 0xc7, 0xfa, 0xcf, 0x4b
	jrl	nz, 329
	.byte 0xc7, 0xfb, 0xcf, 0x45
	jrl	nz, 322
	ldda32	xwa, 31460
	ld	(xwa), 72
	ldda32	xwa, 31460
	ld	(xwa+1), 0
	ldda32	xwa, 31460
	ld	(xwa+2), 75
	ldda32	xbc, 31464
	cp	(xsp+36), 29
	jrl	ule, 264
	cp	(xsp+34), 29
	jrl	ule, 257
	ldda32	xwa, 31460
	ld	e, (xwa+14)
	cps	e, 0
	jr	nz, 6
	cp	(xwa+15), 0
	jr	z, 13
	ld	(xbc+14), e
	ldda32	xwa, 31460
	ld	a, (xwa+15)
	ld	(xbc+15), a
	.byte 0xc7, 0xf9, 0xcf, 0x48
	jr	nz, 12
	cpi_berp	250, 0
	jr	nz, 7
	.byte 0xc7, 0xfb, 0xcf, 0x4b
	jrl	z, 147
	ld	a, (xsp+36)
	sub	a, 30
	extz	wa
	extz	xwa
	add	xwa, 14991722
	ld	xbc, xwa
	ld	xde, xwa
	ld	xhl, xwa
	ld	xix, xwa
	lda	xiy, (xwa+30)
	ld	a, (xix)
	extz	wa
	muls	wa, 96
	ld	iz, wa
	add	iz, 96
	ldda32	xwa, 31460
	.byte 0xf3, 0x07, 0xe0, 0xf8, 0x30
	ld	(xwa+34), 64
	ld	a, (xhl)
	extz	wa
	muls	wa, 96
	ld	iz, wa
	add	iz, 96
	ldda32	xwa, 31460
	.byte 0xf3, 0x07, 0xe0, 0xf8, 0x30
	ld	(xwa+42), 12
	ld	a, (xde)
	extz	wa
	muls	wa, 96
	ld	iz, wa
	add	iz, 96
	ldda32	xwa, 31460
	.byte 0xf3, 0x07, 0xe0, 0xf8, 0x30
	ld	(xwa+50), 116
	ld	a, (xbc)
	extz	wa
	muls	wa, 96
	ld	iz, wa
	add	iz, 96
	ldda32	xwa, 31460
	.byte 0xf3, 0x07, 0xe0, 0xf8, 0x30
	ld	(xwa+58), 64
	inc	3, xix
	inc	3, xhl
	inc	3, xde
	inc	3, xbc
	cp	xbc, xiy
	jr	c, -120
	ld	a, (xsp+36)
	extz	wa
	ld	c, (xsp+34)
	extz	bc
	calr	392
	ldda8	a, 14672
	extz	wa
	bit	0, wa
	jrl	z, 357
	ldda32	xwa, 31464
	stda32	14766, xwa
	cp	(xsp+34), 30
	jrl	nc, 293
	ld	c, (xsp+34)
	extz	bc
	lda	xwa, (xsp+4)
	.byte 0xc3, 0x07, 0xe0, 0xe4, 0x19, 0xac, 0x39
	call	16117240
	jrl	320
	cp	(xsp+36), 29
	jr	ule, 6
	cp	(xsp+34), 30
	jr	c, 12
	cp	(xsp+36), 30
	jr	nc, 14
	cp	(xsp+34), 29
	jr	ule, 8
	stdi8	14672, 130
	jrl	304
	stda32	14766, xbc
	ld	c, (xsp+34)
	extz	bc
	lda	xwa, (xsp+4)
	.byte 0xc3, 0x07, 0xe0, 0xe4, 0x19, 0xac, 0x39
	call	16117240
	.byte 0xc7, 0xf9, 0xcf, 0x48
	jr	nz, 11
	cpi_berp	250, 0
	jr	nz, 6
	.byte 0xc7, 0xfb, 0xcf, 0x4b
	jr	z, 121
	ld	a, (xsp+36)
	extz	wa
	lda	xbc, (xsp+4)
	.byte 0xf3, 0x07, 0xe4, 0xe0, 0x31
	ld	a, (xbc)
	extz	wa
	muls	wa, 96
	ld	de, wa
	add	de, 96
	ldda32	xwa, 31460
	.byte 0xf3, 0x07, 0xe0, 0xe8, 0x30
	ld	(xwa+34), 64
	ld	a, (xbc)
	extz	wa
	muls	wa, 96
	ld	de, wa
	add	de, 96
	ldda32	xwa, 31460
	.byte 0xf3, 0x07, 0xe0, 0xe8, 0x30
	ld	(xwa+42), 12
	ld	a, (xbc)
	extz	wa
	muls	wa, 96
	ld	de, wa
	add	de, 96
	ldda32	xwa, 31460
	.byte 0xf3, 0x07, 0xe0, 0xe8, 0x30
	ld	(xwa+50), 116
	ld	a, (xbc)
	extz	wa
	muls	wa, 96
	ld	bc, wa
	add	bc, 96
	ldda32	xwa, 31460
	.byte 0xf3, 0x07, 0xe0, 0xe4, 0x30
	ld	(xwa+58), 64
	ldda32	xwa, 31460
	stda32	14766, xwa
	ldda32	xwa, 31464
	stda32	14770, xwa
	ld	a, (xsp+36)
	extz	wa
	lda	xbc, (xsp+4)
	.byte 0xc3, 0x07, 0xe4, 0xe0, 0x19, 0xac, 0x39
	ld	a, (xsp+34)
	extz	wa
	.byte 0xc3, 0x07, 0xe4, 0xe0, 0x19, 0xad, 0x39, 0xf1, 0xb0, 0x35, 0xb0
	call	16134719
	ldda8	a, 13744
	extz	wa
	bit	0, wa
	jr	z, 8
	stdi8	14672, 131
	jrl	-312
	stdi8	14672, 0
	jrl	-320
	ldi_berp	251, 0
	ld	c, (xsp+34)
	sub	c, 30
	extz	bc
	ldto_berp	a, 251
	extz	wa
	muls	wa, 3
	ld	de, wa
	add	de, bc
	lda_24	xwa, 14991722
	.byte 0xc3, 0x07, 0xe0, 0xe8, 0x19, 0xac, 0x39
	call	16117240
	inc_berp	251, 1
	.byte 0xc7, 0xfb, 0xcf, 0x0a
	jr	c, -46
	cpdi8	14672, 131
	jr	nz, 5
	ldw	hl, 65429
	jr	6
	call	16116089
	lds	hl, 0
	pop	xiz
	lda	xsp, (xsp+34)
	ret
	dec	4, xsp
	push qiz
	ld	(xsp+2), c
	ld	(xsp+4), a
	ldda32	xwa, 31464
	stda32	14766, xwa
	ldi_berp	251, 0
	ld	c, (xsp+2)
	sub	c, 30
	extz	bc
	ldto_berp	a, 251
	extz	wa
	muls	wa, 3
	ld	de, wa
	add	de, bc
	lda_24	xwa, 14991722
	.byte 0xc3, 0x07, 0xe0, 0xe8, 0x19, 0xac, 0x39
	call	16117240
	inc_berp	251, 1
	.byte 0xc7, 0xfb, 0xcf, 0x0a
	jr	c, -46
	ldda32	xwa, 31460
	stda32	14766, xwa
	ldda32	xwa, 31464
	stda32	14770, xwa
	stdi8	14672, 0
	.byte 0xf1, 0xb0, 0x35, 0xb0
	ldi_berp	251, 0
	ld	e, (xsp+4)
	sub	e, 30
	extz	de
	ldto_berp	a, 251
	extz	wa
	muls	wa, 3
	ld	bc, wa
	add	wa, de
	lda_24	xde, 14991722
	.byte 0xc3, 0x07, 0xe8, 0xe0, 0x19, 0xac, 0x39
	ld	a, (xsp+2)
	sub	a, 30
	extz	wa
	add	bc, wa
	.byte 0xc3, 0x07, 0xe8, 0xe4, 0x19, 0xad, 0x39
	call	16134719
	ldda8	a, 13744
	extz	wa
	bit	0, wa
	jr	z, 7
	stdi8	14672, 131
	jr	9
	inc_berp	251, 1
	.byte 0xc7, 0xfb, 0xcf, 0x0a
	jr	c, -81
	pop qiz
	inc	4, xsp
	ret

	.include "sequencer/accompseq_routines.s"
