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
	cp a, 0xf0
	jr c, Rhythm_DispatchNote_SetParam
	call AccTone_LookupByProgramWrapped
	jr Rhythm_DispatchNote_Return

Rhythm_DispatchNote_SetParam:
	and a, 0x7f
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
	call	AccTuning_DispatchDataBlock_A_0x4C
	ret

AccStyle_LookupTempoAndVelocity:
	push xhl
	push xwa
	xor xhl, xhl
	ldb_d8 l, 0x90ea
	cp l, 0xf
	jr ule, AccStyle_LookupTempo_ClampL
	xor l, l

AccStyle_LookupTempo_ClampL:
	sla l, 1
	ld xwa, AccStyle_TempoMultiplierTable
	ldw_sri HL, 0x03, 0xe0, 0xec
	xor xwa, xwa
	ldb_d8 a, 0x90eb
	cp a, 0x4f
	jr ule, AccStyle_LookupTempo_AddAndStore
	xor a, a

AccStyle_LookupTempo_AddAndStore:
	add xhl, xwa
	sla xhl, 1
	add xhl, Display_FontPalette_Table_0x4D07
	ld wa, (xhl)
	stb_d8 0x90ee, a
	stb_d8 0x90ef, w
	pop xwa
	pop xhl
	ret

AccStyle_TempoMultiplierTable:
	.byte 0x00, 0x00, 0x14, 0x00, 0x28, 0x00, 0x3c, 0x00
	.byte 0x50, 0x00, 0x64, 0x00, 0x78, 0x00, 0x8c, 0x00
	.byte 0xa0, 0x00, 0xb4, 0x00, 0xc8, 0x00, 0xdc, 0x00
	.byte 0xf0, 0x00, 0x04, 0x01, 0x18, 0x01, 0x68, 0x01

AccStyle_LookupVelocityTable:
	push xhl
	push xwa
	cpdi8 0x90ea, 128
	jr nc, AccStyle_Velocity_ExtendedRange
	xor xhl, xhl
	ldb_d8 l, 0x90ea
	sla xhl, 3
	xor xwa, xwa
	ldb_d8 a, 0x90eb
	and a, 0x7
	add xhl, xwa
	sla xhl, 1
	add xhl, Display_FontPalette_Table_0x4507
	ld wa, (xhl)
	jr AccStyle_Velocity_StoreResult

AccStyle_Velocity_ExtendedRange:
	cpdi8 0x90ea, 240
	jr nc, AccStyle_Velocity_HighRange
	xor xhl, xhl
	ldb_d8 l, 0x90ea
	and l, 0x7f
	cp l, 0xb
	jr ule, AccStyle_Velocity_ExtClamp
	xor l, l

AccStyle_Velocity_ExtClamp:
	sla xhl, 3
	xor xwa, xwa
	ldb_d8 a, 0x90eb
	and a, 0x7
	add xhl, xwa
	sla xhl, 1
	add xhl, Display_FontPalette_Table_0x4FFB
	ld wa, (xhl)
	jr AccStyle_Velocity_StoreResult

AccStyle_Velocity_HighRange:
	xor xhl, xhl
	ldb_d8 l, 0x90ea
	and l, 0xf
	cps l, 4
	jr ule, AccStyle_Velocity_HighClamp
	xor l, l

AccStyle_Velocity_HighClamp:
	sla xhl, 1
	add xhl, Display_FontPalette_Table_0x50FB
	ld wa, (xhl)

AccStyle_Velocity_StoreResult:
	stb_d8 0x90ee, a
	stb_d8 0x90ef, w
	pop xwa
	pop xhl
	ret

AccStyle_CheckRecordMode:
	ldb_d8 a, 0x32f1
	cp a, 0xe
	jr nz, AccStyle_CheckRecordReturn
	ldb_d8 a, 0x8d34
	cp a, 0xe
	jr z, AccStyle_CheckRecordReturn
	ordi8 0x34cd, 128

AccStyle_CheckRecordReturn:
	ret

AccStyle_DetectChanges:
	anddi8 0x333b, 254
	bitda 0, 0x3283
	jrl nz, AccStyle_DetectChanges_CompareParams
	bitda 1, 0x3283
	jrl z, AccStyle_DetectChanges_CompareParams
	bitda 4, 1057
	jr z, AccStyle_DetectChanges_Init
	call NoteMap_SendAllNotesOff

AccStyle_DetectChanges_Init:
	stdi8 0x32e2, 0
	call Rhythm_SendNoteOnMax
	call AccompVoice_BulkReadRegisters
	call Rhythm_SendChanPressure
	calr Rhythm_SendResetMsg
	anddi8 0x3314, 192
	anddi8 0x3315, 192
	anddi8 0x3312, 192
	anddi8 0x3313, 192
	anddi8 0x3316, 192
	anddi8 0x3317, 192
	anddi8 0x3318, 192
	anddi8 0x335d, 192
	anddi8 0x3326, 192
	anddi8 0x3327, 192
	anddi8 0x3284, 231
	xor a, a
	stb_d8 0x3309, a
	stb_d8 0x330a, a
	stb_d8 0x330b, a
	stb_d8 0x330c, a
	stb_d8 0x330d, a
	stb_d8 0x330e, a
	stb_d8 0x330f, a
	stdi8 0x332b, 0
	anddi8 0x3470, 2
	anddi8 0x3329, 192
	ldb_d8 a, 0xfc5f
	and a, 0xfc
	jr z, AccStyle_DetectChanges_QueueDone
	anddi8 0xfc5f, 3
	ldb a, 0x0
	ldb w, 0x0
	ldb d, 0x5
	ldb e, 0x48
	call Rhythm_QueuePartChangeEvent

AccStyle_DetectChanges_QueueDone:
	bitda 2, 0xfc60
	jr z, AccStyle_DetectChanges_MarkDirty
	anddi8 0xfc60, 251
	ldb a, 0x0
	ldb w, 0x0
	ldb d, 0x6
	ldb e, 0x48
	call Rhythm_QueuePartChangeEvent

AccStyle_DetectChanges_MarkDirty:
	ordi8 0x333b, 1

AccStyle_DetectChanges_CompareParams:
	bitda 0, 0x32f3
	jr nz, AccStyle_Compare_StyleNumber
	call Rhythm_SendChanPressure
	ordi8 0x333b, 1
	jrl AccStyle_DetectChanges_Epilogue

AccStyle_Compare_StyleNumber:
	ldb_d8 a, 0x32f5
	cpda8 a, 0x32f6
	jr z, AccStyle_Compare_StyleNumDone
	ordi8 0x333b, 1

AccStyle_Compare_StyleNumDone:
	ldb_d8 a, 0x32f7
	cpda8 a, 0x32f8
	jr z, AccStyle_Compare_Variation
	ordi8 0x333b, 1

AccStyle_Compare_Variation:
	ldb_d8 a, 0x32f9
	and a, 0x7
	cpda8 a, 0x32fa
	jr z, AccStyle_Compare_VariationDone
	ordi8 0x333b, 1

AccStyle_Compare_VariationDone:
	bitda 7, 0x34cd
	jr z, AccStyle_Compare_RegistrationFlag
	anddi8 0x34cd, 127
	ordi8 0x333b, 1

AccStyle_Compare_RegistrationFlag:
	ldb_d8 a, 0x3335
	xorda8 a, 0x32f2
	and a, 0x2
	cps a, 0
	jr z, AccStyle_Compare_SplitA
	ordi8 0x333b, 1
	jr AccStyle_DetectChanges_Epilogue

AccStyle_Compare_SplitA:
	ldb_d8 a, 0x32ff
	cpda8 a, 0x3300
	jr z, AccStyle_Compare_SplitADone
	ordi8 0x333b, 1

AccStyle_Compare_SplitADone:
	ldb_d8 a, 0x3301
	cpda8 a, 0x3302
	jr z, AccStyle_Compare_LayerA
	ordi8 0x333b, 1

AccStyle_Compare_LayerA:
	ldb_d8 a, 0x3305
	cpda8 a, 0x3306
	jr z, AccStyle_Compare_LayerADone
	ordi8 0x333b, 1

AccStyle_Compare_LayerADone:
	ldb_d8 a, 0x3307
	cpda8 a, 0x3308
	jr z, AccStyle_Compare_TuningState
	ordi8 0x333b, 1

AccStyle_Compare_TuningState:
	ldb_d8 a, 0x33e8
	xorda8 a, 0x33e9
	bit 0, a
	jr z, AccStyle_Compare_TuningDone
	ordi8 0x333b, 1

AccStyle_Compare_TuningDone:
	call AccTuning_Toggle

AccStyle_DetectChanges_Epilogue:
	bitda 0, 0x333b
	jr z, AccStyle_DetectChanges_ClearFlags
	calr AccStyle_ApplyChanges

AccStyle_DetectChanges_ClearFlags:
	stdi8 0x3354, 0
	stdi8 0x3355, 0
	stdi8 0x335f, 0
	anddi8 0x3357, 252
	anddi8 0x3361, 120
	ret

AccStyle_ApplyChanges:
	calr AccStyle_ResetAllVoiceState
	anddi8 0x3283, 251
	stdi8 1122, 0
	calr AccBuf_ResetAllPositions
	call AccompVoice_BulkReadRegisters
	ldb_d8 a, 0x32f7
	and a, 0x7f
	and a, 0x7
	stb_d8 0x32e6, a
	stb_d8 0x32e8, a
	ldb_d8 a, 0x32f5
	stb_d8 0x32e5, a
	stb_d8 0x32e7, a
	stb_d8 0x3370, a
	call AccTuning_Init
	cpdi8 0x32e5, 128
	jr nc, AccStyle_ApplyChanges_Extended
	calr AccStyle_ApplyStandardStyle
	jr AccStyle_ApplyChanges_Finalize

AccStyle_ApplyChanges_Extended:
	calr AccStyle_ApplyExtendedStyle
	jr AccStyle_ApplyChanges_Finalize

AccStyle_ApplyChanges_Finalize:
	calr AccBuf_InitKbd1WithMarkers
	ldb_d8 a, 1075
	stb_d8 1112, a
	stdi8 0x32ec, 1
	call Rhythm_ProcessAllPartsAndLoad
	ret

AccStyle_ResetAllVoiceState:
	xor wa, wa
	stb_d8 1045, a
	stb_d8 1046, a
	stb_d8 0x327f, a
	stb_d8 0x3280, a
	stda16 0x327d, xwa
	stb_d8 0x3328, a
	stb_d8 0x32ab, a
	stb_d8 0x32ac, a
	stb_d8 0x32b1, a
	stb_d8 0x32ad, a
	stb_d8 0x32ae, a
	stb_d8 0x32af, a
	stb_d8 0x32b0, a
	stb_d8 1076, a
	stb_d8 1077, a
	stb_d8 0x32b4, a
	stb_d8 0x32b5, a
	stb_d8 0x32b6, a
	stb_d8 0x32bb, a
	stb_d8 0x32b7, a
	stb_d8 0x32b8, a
	stb_d8 0x32b9, a
	stb_d8 0x32ba, a
	stb_d8 0x334d, a
	stb_d8 0x32bd, a
	stb_d8 0x32be, a
	stb_d8 0x32bf, a
	stb_d8 0x32c0, a
	stb_d8 0x32c1, a
	stb_d8 0x32c2, a
	stb_d8 0x3385, a
	stb_d8 0x3386, a
	stb_d8 0x3387, a
	stb_d8 0x3388, a
	stb_d8 0x3389, a
	stb_d8 0x338a, a
	call AccTone_CallWithSaveAll
	ret

AccStyle_ApplyStandardStyle:
	ldb_d8 a, 0x3305
	and a, 0x3
	stb_d8 0x3338, a
	stb_d8 0x333a, a
	ldb_d8 a, 0x32e5
	ldb_d8 h, 0x32e6
	call AccVoice_LookupWithOffset
	stda32 0x32ce, xiy
	call AccVoice_SelectAndApplyPatch
	call AccVoice_ReadBankAssign
	ldda32 xiy, 0x32ce
	call Rhythm_UpdateTuningConfig
	ldda32 xiy, 0x32ce
	ldb_d8 a, 0x32ff
	and a, 0x7
	jr z, AccStyle_ApplyStd_LoadTuning
	calr AccVoice_SelectPartOffset
	jr AccStyle_ApplyStd_Return

AccStyle_ApplyStd_LoadTuning:
	calr AccStyle_SetupPartAddresses
	ldb_d8 a, 0x32a3
	ldb w, 0x0
	calr AccPart_GetVoiceParamOffsetTable
	call AccVoice_LoadTuningBlock
	ordi8 0x332c, 63

AccStyle_ApplyStd_Return:
	ret

AccStyle_SetupPartAddresses:
	ldb_sri0 A, (xiy + 0x03d1)
	stb_d8 0x3285, a
	stdi8 0x33d4, 1
	ldb_d8 a, 0x32a3
	calr AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	stda16 0x3287, xwa
	stdi8 0x33d4, 2
	ldb_d8 a, 0x32a4
	calr AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	stda16 0x3289, xwa
	stdi8 0x33d4, 4
	ldb_d8 a, 0x32a5
	calr AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	stda16 0x328b, xwa
	stdi8 0x33d4, 8
	ldb_d8 a, 0x32a6
	calr AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	stda16 0x328d, xwa
	stdi8 0x33d4, 16
	ldb_d8 a, 0x32a7
	calr AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	stda16 0x328f, xwa
	stdi8 0x33d4, 32
	ldb_d8 a, 0x32a8
	calr AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	stda16 0x3291, xwa
	ld xwa, Display_FontPalette_Table_0x1D61
	add xwa, 0x6
	stda32 0x3293, xwa
	anddi8 0x3316, 192
	anddi8 0x3317, 192
	anddi8 0x3318, 192
	ret

AccStyle_ApplyExtendedStyle:
	ld xiy, Display_FontPalette_Table_0x1DA1
	ldb_d8 a, 0x32e5
	and a, 0x7f
	cp a, 0x1d
	jr ule, AccStyle_ApplyExt_ClampIndex
	xor a, a

AccStyle_ApplyExt_ClampIndex:
	ldb_sri A, 0x03, 0xf4, 0xe0
	stb_d8 0x3338, a
	ldb_d8 a, 0x32e5
	and a, 0x7f
	call AccVoice_ResolveParamAddr
	stda32 0x32ce, xiy
	ld l, (xiy + 16)
	ld h, (xiy + 17)
	and h, 0xf
	and h, 0x7
	cp hl, 0x208
	jr z, AccStyle_ApplyExt_SkipClamp
	cp hl, 0x318
	jr z, AccStyle_ApplyExt_SkipClamp
	call VoiceParam_ClampAndValidate

AccStyle_ApplyExt_SkipClamp:
	ld a, l
	call AccVoice_LookupWithOffset
	stda32 0x32d3, xiy
	call AccVoice_SelectAndApplyPatch
	ldb_d8 w, 0x32e5
	call AccPatch_SetByChordIndex
	bitda 0, 0x3363
	jr nz, AccStyle_ApplyExt_CheckSplit
	call AccPedal_ProcessAllChanges

AccStyle_ApplyExt_CheckSplit:
	ldb_d8 a, 0x32ff
	and a, 0x7
	jrl z, Seq_ProcessAndContinue
	bitda 0, 0x3363
	jrl z, AccStyle_ApplyExt_SelectPart
	bitda 1, 0x32ff
	jr z, AccStyle_ApplyExt_CheckBit0
	ldb_d8 a, 1075
	ld xhl, Display_FontPalette_Table_0x1D58
	bit_dri 0, 0x03, 0xec, 0xe0
	jr z, AccStyle_ApplyExt_SelectPart
	anddi8 0x32ff, 253
	anddi8 0xfc5f, 247
	ldb e, 0x48
	ldb d, 0x5
	ldb a, 0x0
	ldb w, 0x0
	call Rhythm_QueuePartChangeEvent
	jr Seq_ProcessAndContinue

AccStyle_ApplyExt_CheckBit0:
	bitda 0, 0x32ff
	jr z, AccStyle_ApplyExt_CheckBit1
	ldb_d8 a, 0x3364
	cpda8 a, 1075
	jr z, AccStyle_ApplyExt_UseSecondary
	anddi8 0x32ff, 254
	anddi8 0xfc5f, 251
	ldb e, 0x48
	ldb d, 0x5
	ldb a, 0x0
	ldb w, 0x0
	call Rhythm_QueuePartChangeEvent
	jr Seq_ProcessAndContinue

AccStyle_ApplyExt_CheckBit1:
	ldb_d8 a, 0x3366
	cpda8 a, 1075
	jr z, AccStyle_ApplyExt_UseSecondary
	anddi8 0x32ff, 251
	anddi8 0xfc60, 251
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
	ldda32 xiy, 0x32d3
	calr AccVoice_SelectPartOffset

AccStyle_ApplyExt_UpdateTuning:
	ldda32 xiy, 0x32d3
	calr Rhythm_UpdateTuningConfig
	ret

AccVoice_SelectPartOffset:
	ldw hl, 0x20
	bitda 0, 0x32ff
	jr nz, AccVoice_SelectPartOffset_Resolved
	ldw hl, 0x22
	bitda 1, 0x32ff
	jr nz, AccVoice_SelectPartOffset_Resolved
	ldw hl, 0x420

AccVoice_SelectPartOffset_Resolved:
	calr AccStyle_SetupPartAddressesByHL
	cpdi8 0x32e5, 128
	jr c, AccVoice_SelectPartOffset_Bound
	ldda32 xiy, 0x32ce
	call AccTuning_CopyAllPartsFromStyle
	jr AccVoice_SelectPartOffset_Apply63

AccVoice_SelectPartOffset_Bound:
	ldb_d8 a, 0x32a3
	ldb w, 0x3
	bitda 2, 0x32ff
	jr z, AccVoice_SelectPartOffset_SetModeW
	ldb w, 0x4

AccVoice_SelectPartOffset_SetModeW:
	calr AccPart_GetVoiceParamOffsetTable
	call AccVoice_LoadTuningBlock

AccVoice_SelectPartOffset_Apply63:
	ordi8 0x332c, 63
	bitda 0, 0x32ff
	jr z, AccVoice_SelectPartOffset_Bit1
	ordi8 0x3316, 63
	anddi8 0x3317, 192
	anddi8 0x3318, 192
	jr AccVoice_SelectPartOffset_Return

AccVoice_SelectPartOffset_Bit1:
	bitda 1, 0x32ff
	jr z, AccVoice_SelectPartOffset_Mode3
	anddi8 0x3316, 192
	ordi8 0x3317, 63
	anddi8 0x3318, 192
	jr AccVoice_SelectPartOffset_Return

AccVoice_SelectPartOffset_Mode3:
	anddi8 0x3316, 192
	anddi8 0x3317, 192
	ordi8 0x3318, 63

AccVoice_SelectPartOffset_Return:
	ret

AccStyle_SetupPartAddressesByHL:
	ldb_sri0 A, (xiy + 0x03d1)
	stb_d8 0x3285, a
	ldw_erp HL, 0x3c
	stdi8 0x33d4, 1
	call AccPart_GetParamAddr
	stda16 0x3287, xwa
	stw_erp HL, 0x3c
	stdi8 0x33d4, 2
	call AccPart_GetParamAddr
	stda16 0x3289, xwa
	stw_erp HL, 0x3c
	stdi8 0x33d4, 4
	call AccPart_GetParamAddr
	stda16 0x328b, xwa
	stw_erp HL, 0x3c
	stdi8 0x33d4, 8
	call AccPart_GetParamAddr
	stda16 0x328d, xwa
	stw_erp HL, 0x3c
	stdi8 0x33d4, 16
	call AccPart_GetParamAddr
	stda16 0x328f, xwa
	stw_erp HL, 0x3c
	stdi8 0x33d4, 32
	call AccPart_GetParamAddr
	stda16 0x3291, xwa
	ld xwa, Display_FontPalette_Table_0x1D61
	add xwa, 0x6
	stda32 0x3293, xwa
	ret

AccStyle_UseSecondarySource:
	ldb_d8 a, 0x3365
	bitda 0, 0x32ff
	jr nz, AccStyle_UseSecondary_Resolve
	ldb_d8 a, 0x3367

AccStyle_UseSecondary_Resolve:
	call AccVoice_ResolveParamAddr
	calr AccPart_InitPositionsAndBase
	call AccTuning_CopyAllPartsFromStyle
	ordi8 0x332c, 63
	bitda 0, 0x32ff
	jr z, AccStyle_UseSecondary_Mode3
	ordi8 0x3316, 63
	anddi8 0x3317, 192
	anddi8 0x3318, 192
	jr AccStyle_UseSecondary_Return

AccStyle_UseSecondary_Mode3:
	anddi8 0x3316, 192
	anddi8 0x3317, 192
	ordi8 0x3318, 63

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
	ld xwa, Display_FontPalette_Table_0x1D61
	add xwa, 0x6
	stda32 0x3293, xwa
	ret

AccPart_ResetAndCopyTuning:
	ldda32 xiy, 0x32ce
	calr AccPart_InitPositionsAndBase
	call AccTuning_CopyAllPartsFromStyle
	ordi8 0x332c, 63
	anddi8 0x3316, 192
	anddi8 0x3317, 192
	anddi8 0x3318, 192
	ret

AccBuf_ResetAllPositions:
	ld xhl, 0x2a94
	call AccBuf_ResetOnePosition
	ld xhl, 0x2b94
	call AccBuf_ResetOnePosition
	ld xhl, 0x2c94
	call AccBuf_ResetOnePosition
	ld xhl, 0x2d94
	call AccBuf_ResetOnePosition
	ld xhl, 0x2e94
	call AccBuf_ResetOnePosition
	ld xhl, 0x2f94
	call AccBuf_ResetOnePosition
	ret

AccBuf_InitKbd1WithMarkers:
	ld xhl, 0x2a94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	stib_ind 0x07, 0xec, 0xf4, 0xd0
	call RingBuf_AdvanceIndex
	stib_ind 0x07, 0xec, 0xf4, 0x01
	call RingBuf_AdvanceIndex
	stib_ind 0x07, 0xec, 0xf4, 0x10
	call RingBuf_AdvanceIndex
	stib_ind 0x07, 0xec, 0xf4, 0x01
	call RingBuf_AdvanceIndex
	ld (xhl + 4), iy
	ret

Rhythm_SendResetMsg:
	ldb a, 0xd8
	ldb w, 0x10
	ldb e, 0x0
	call Rhythm_Send3ByteMsg
	ret

Rhythm_UpdateTuningConfig:
	ldb_d8 w, 0x32d8
	ldb_d8 a, 0x3338
	calr Rhythm_LookupTuningByStyle
	stb_d8 0x32a3, a
	stb_d8 0x32a4, a
	stb_d8 0x32a5, a
	stb_d8 0x32a6, a
	stb_d8 0x32a7, a
	stb_d8 0x32a8, a
	ldb_d8 w, 0x32d8
	ldb_d8 a, 0x3338
	calr Rhythm_LookupTuningRange
	ret

Rhythm_LookupTuningByStyle:
	calr Rhythm_LookupStyleIndex
	calr AccVoice_LookupParamIndex
	ld xhl, AccVoice_ParamIndexData_0x5B
	ldb_sri A, 0x03, 0xec, 0xe0
	ret

Rhythm_LookupTuningRange:
	cpdi8 0x32e5, 128
	jr nc, Rhythm_LookupTuning_DefaultRange
	calr Rhythm_LookupStyleIndex
	calr AccVoice_LookupParamIndex
	ld xhl, AccVoice_ParamIndexData_0x63
	sla a, 1
	ldw_sri HL, 0x03, 0xec, 0xe0
	ldw_sri WA, 0x07, 0xf4, 0xec
	jr Rhythm_StoreTuningRange

Rhythm_LookupTuning_DefaultRange:
	ldb a, 0x39
	ldb w, 0x39

Rhythm_StoreTuningRange:
	stb_d8 0x333f, a
	stb_d8 0x3340, w
	ret

Rhythm_LookupStyleIndex:
	ld xhl, AccVoice_ParamIndexData_0x26
	cp w, 0x30
	jr c, Rhythm_LookupStyleIndex_Compute
	xor w, w

Rhythm_LookupStyleIndex_Compute:
	ldb_sri W, 0x03, 0xec, 0xe1
	and w, 0x3
	ld xhl, AccVoice_ParamIndexData_0x57
	ldb_sri L, 0x03, 0xec, 0xe1
	xor h, h
	ret

AccVoice_LookupParamIndex:
	push xhl
	ld xhl, AccVoice_ParamIndexData
	and wa, 0x3
	ldb_sri A, 0x07, 0xec, 0xe0
	pop xhl
	ret

AccVoice_ParamIndexData:
	nop
	pop	sr
	.byte 0x04
	reti
	add	hl, 994
	extz	wa
	.byte 0xd7
	ldw	wa, 0xd898
	.byte 0x83, 0xc3
	reti
	.byte 0xf4, 0xec
	ldb	a, 201
	.byte 0xcf
	swi	7
	jr	nz, 12
	.byte 0xd7
	ldw	wa, 0xd888
	or	b, w
	pop	sr
	.byte 0xc3
	reti
	.byte 0xf4, 0xe0
	ldb	a, 14
	nop
	nop
	.byte 0x01, 0x01
	nop
	push	sr
	.byte 0x01, 0x01
	push	sr
	.byte 0x01, 0x01, 0x01, 0x01
	nop
	.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
	push	sr
	.byte 0x01, 0x01
	nop
	.byte 0x01, 0x01, 0x01, 0x01, 0x01
	nop
	.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
	.byte 0x01, 0x01
	nop
	push	sr
	.zero 8
	ldio	4, 12
	nop
	halt
	ldwio	15, 6420
	calr	53795
	pop	sr
	.byte 0xd4
	pop	sr
	.byte 0xd6
	pop	sr
	ld	wa, 2002
	.byte 0xd4
	reti
	.byte 0xd6
	reti
	neg	wa

AccPart_GetVoiceParamOffsetTable:
	ld xhl, AccPart_VoiceParamDispatchTable
	ldb_erp W, 0x31
	extz wa
	sla wa, 2
	ld_sril3 XHL, 0x07, 0xec, 0xe0
	stb_erp W, 0x31
	sla w, 1
	ldw_sri HL, 0x03, 0xec, 0xe1
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
	.byte 0xc4
	nop
	ldb	h, 1
	ldb	h, 5
	.byte 0x57, 0x01, 0x57
	halt
AccPart_VoiceParamOffsets_BaseB:
	ldw	bc, 0x9300
	nop
	.byte 0xf5
	nop
	ldb	h, 1
	ldb	h, 5
	.byte 0x57, 0x01, 0x57
	halt
AccPart_VoiceParamOffsets_ChordA:
	nop
	.byte 0x04
	jr	le, 4
	.byte 0xc4, 0x04
	ldb	h, 1
	ldb	h, 5
	.byte 0x57, 0x01, 0x57
	halt
AccPart_VoiceParamOffsets_ChordB:
	ldw	bc, 0x9304
	.byte 0x04, 0xf5, 0x04
	ldb	h, 1
	ldb	h, 5
	.byte 0x57, 0x01, 0x57
	halt

AccPart_LookupBoundVoiceParam:
	ld w, a
	calr AccStyle_ReadParamOffset
	ld xhl, AccStyle_ByteDataBlock_0xAC
	cp a, 0x14
	jr c, AccPart_LookupBound_ComputeIdx
	ld xhl, AccStyle_ByteDataBlock_0xBC

AccPart_LookupBound_ComputeIdx:
	sla w, 1
	ldw_sri HL, 0x03, 0xec, 0xe1
	ret

AccStyle_ReadParamOffset:
	ld xhl, AccStyle_ByteDataBlock_0x5C
	sla w, 1
	ldw_sri HL, 0x03, 0xec, 0xe1
	extz xhl
	add xhl, xiy
	cpdi8 0x33d4, 1
	jr nz, AccStyle_ReadParamOff_Part2
	ld w, (xhl + 256)
	jr AccStyle_ReadParamRet

AccStyle_ReadParamOff_Part2:
	cpdi8 0x33d4, 2
	jr nz, AccStyle_ReadParamOff_Part4
	ld w, (xhl + 256)
	jr AccStyle_ReadParamRet

AccStyle_ReadParamOff_Part4:
	cpdi8 0x33d4, 4
	jr nz, AccStyle_ReadParamOff_Part8
	ld w, (xhl + 40)
	jr AccStyle_ReadParamRet

AccStyle_ReadParamOff_Part8:
	cpdi8 0x33d4, 8
	jr nz, AccStyle_ReadParamOff_Part16
	ld w, (xhl + 80)
	jr AccStyle_ReadParamRet

AccStyle_ReadParamOff_Part16:
	cpdi8 0x33d4, 16
	jr nz, AccStyle_ReadParamOff_Part32
	ld w, (xhl + 120)
	jr AccStyle_ReadParamRet

AccStyle_ReadParamOff_Part32:
	ldb_sri0 W, (xhl + 0x00a0)

AccStyle_ReadParamRet:
	ret

AccStyle_ByteDataBlock:
	ld	xhl, AccStyle_ByteDataBlock_0x5C
	sla	a, 1
	.byte 0xd3
	pop	sr
	or	xwa, xix
	ldb	c, 235
	ccf
	add	xhl, xiy
	.byte 0xc1, 0xd4
	ldw	hl, 319
	jr	nz, 5
	ld	a, (xhl+20)
	jr	62
	.byte 0xc1, 0xd4
	ldw	hl, 575
	jr	nz, 5
	ld	a, (xhl+20)
	jr	50
	.byte 0xc1, 0xd4
	ldw	hl, 1087
	jr	nz, 5
	.byte 0x8b
	.ascii "<!h&ÁÔ3"
	push	xsp
	ldio	110, 5
	ld	a, (xhl+100)
	jr	26
	.byte 0xc1, 0xd4
	ldw	hl, 4159
	jr	nz, 7
	ld	a, (xhl+140)
	jr	12
	.byte 0xc1, 0xd4
	.ascii "3? n"
	halt
	.byte 0xc3
	sbc	xix, xiy
	nop
	ldb	a, 14
	nop
	nop
	.byte 0x01
	nop
	push	sr
	nop
	pop	sr
	nop
	.byte 0x04
	nop
	halt
	nop
	di
	reti
	nop
	ldio	0, 9
	nop
	ldwio	0, 11
	incf
	nop
	decf
	nop
	ret
	nop
	retd	4096
	nop
	scf
	nop
	ccf
	nop
	zcf
	nop
	nop
	.byte 0x04, 0x01, 0x04
	push	sr
	.byte 0x04
	pop	sr
	.byte 0x04, 0x04, 0x04
	halt
	.byte 0x04
	ei	4
	reti
	.byte 0x04
	ldio	4, 9
	.byte 0x04
	ldwio	4, 1035
	incf
	.byte 0x04
	decf
	.byte 0x04
	ret
	.byte 0x04
	retd	4100
	.byte 0x04
	scf
	.byte 0x04
	ccf
	.byte 0x04
	zcf
	.byte 0x04
	nop
	nop
	push	sr
	nop
	.byte 0x04
	nop
	di
	ldio	0, 10
	nop
	incf
	nop
	ret
	nop
	nop
	.byte 0x04
	push	sr
	.byte 0x04, 0x04, 0x04
	ei	4
	ldio	4, 10
	.byte 0x04
	incf
	.byte 0x04
	ret
	.byte 0x04

AccVoice_ComputeParamAddr:
	cp a, 0xf
	jr nc, AccVoice_ParamAddr_Range0F_14
	ldw hl, 0x18
	bitda 0, 0x3309
	jr nz, AccVoice_ReturnExtHL
	ldw hl, 0x1a
	jr AccVoice_ReturnExtHL

AccVoice_ParamAddr_Range0F_14:
	cp a, 0x14
	jr nc, AccVoice_ParamAddr_Range14_23
	ldw hl, 0x1c
	bitda 0, 0x3309
	jr nz, AccVoice_ReturnExtHL
	ldw hl, 0x1e
	jr AccVoice_ReturnExtHL

AccVoice_ParamAddr_Range14_23:
	cp a, 0x23
	jr nc, AccVoice_ParamAddr_Range23Plus
	ldw hl, 0x418
	bitda 0, 0x3309
	jr nz, AccVoice_ReturnExtHL
	ldw hl, 0x41a
	jr AccVoice_ReturnExtHL

AccVoice_ParamAddr_Range23Plus:
	ldw hl, 0x41c
	bitda 0, 0x3309
	jr nz, AccVoice_ReturnExtHL
	ldw hl, 0x41e

AccVoice_ReturnExtHL:
	extz xhl
	ret

AccTuning_SetAllFromLookup:
	calr AccTuning_FetchValue
	stb_d8 0x32a3, a
	stb_d8 0x32a4, a
	stb_d8 0x32a5, a
	stb_d8 0x32a6, a
	stb_d8 0x32a7, a
	stb_d8 0x32a8, a
	ret

AccTuning_FetchValue:
	ld xhl, AccTuning_ValueTable
	ldb_sri A, 0x03, 0xec, 0xe0
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
	anddi8 0x32f4, 252
	stdi8 0x32ed, 0
	ldb a, 0x1
	stb_d8 0x33d4, a
	ldw_d16 xwa, 0x3297
	stda16 0x33d6, xwa
	ldw_d16 xwa, 0x3287
	stda16 0x33d8, xwa
	ldb_d8 a, 0x32b5
	stb_d8 0x33da, a
	ldb_d8 a, 0x32ab
	stb_d8 0x33db, a
	ldb_d8 a, 0x32a3
	stb_d8 0x33d5, a
	ldb_d8 a, 0x33eb
	stb_d8 0x33ea, a
	ret

AccVoice_RestorePartState1:
	ldw_d16 xwa, 0x33d6
	stda16 0x3297, xwa
	ldw_d16 xwa, 0x33d8
	stda16 0x3287, xwa
	ldb_d8 a, 0x33da
	stb_d8 0x32b5, a
	ldb_d8 a, 0x33db
	stb_d8 0x32ab, a
	ldb_d8 a, 0x33d5
	stb_d8 0x32a3, a
	ldb_d8 a, 0x33ea
	stb_d8 0x33eb, a
	ret


; -----------------------------------------------------------------------------
; Section: Voice Event Processing
; -----------------------------------------------------------------------------
; Per-voice event loop, event dispatch, and
; sound patch handling.
; -----------------------------------------------------------------------------

AccVoice_ProcessEventLoop:
	bitda 0, 0x32f4
	jr z, AccVoice_EventLoop_Active
	jr AccVoice_EventLoop_Idle

AccVoice_EventLoop_Active:
	calr AccVoice_DispatchByChannel
	bitda 0, 0x32f4
	jr z, AccVoice_EventLoop_Dispatch
	jr AccVoice_EventProcessingReturn

AccVoice_EventLoop_Dispatch:
	ldb_d8 w, 0x33d4
	ldw_d16 xiz, 0x33d6
	call AccVoice_SelectByMask
	ldw_d16 xiy, 0x33d8
	ldb_sri A, 0x07, 0xec, 0xf4
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
	cp a, 0xd1
	jr z, AccVoice_HandleEvent_D5
	cp a, 0xd2
	jr z, AccVoice_HandleEvent_D5
	cp a, 0xd3
	jr z, AccVoice_HandleEvent_D5
	cp a, 0xd4
	jr z, AccVoice_HandleEvent_D5
	cp a, 0xd5
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
	cpdi8 0x33d4, 1
	jr nz, AccVoice_DispatchCh_Kbd2
	bitda 0, 0x332c
	jr z, SoundPatch_NullRet
	calr AccKbd1_ProcessNotes
	jr SoundPatch_NullRet

AccVoice_DispatchCh_Kbd2:
	cpdi8 0x33d4, 2
	jr nz, AccVoice_DispatchCh_Acc1
	bitda 1, 0x332c
	jr z, SoundPatch_NullRet
	calr AccKbd2_ProcessNotes
	jr SoundPatch_NullRet

AccVoice_DispatchCh_Acc1:
	cpdi8 0x33d4, 4
	jr nz, AccVoice_DispatchCh_Acc2
	bitda 2, 0x332c
	jr z, SoundPatch_NullRet
	call AccCh1_ProcessNotes
	jr SoundPatch_NullRet

AccVoice_DispatchCh_Acc2:
	cpdi8 0x33d4, 8
	jr nz, AccVoice_DispatchCh_Acc3
	bitda 3, 0x332c
	jr z, SoundPatch_NullRet
	call AccCh2_ProcessNotes
	jr SoundPatch_NullRet

AccVoice_DispatchCh_Acc3:
	cpdi8 0x33d4, 16
	jr nz, AccVoice_DispatchCh_Acc4
	bitda 4, 0x332c
	jr z, SoundPatch_NullRet
	call AccCh3_ProcessNotes
	jr SoundPatch_NullRet

AccVoice_DispatchCh_Acc4:
	cpdi8 0x33d4, 32
	jr nz, SoundPatch_NullRet
	bitda 5, 0x332c
	jr z, SoundPatch_NullRet
	call AccCh4_ProcessNotes
	jr SoundPatch_NullRet

SoundPatch_NullRet:
	ret

AccVoice_AdvanceAndCheckEnd:
	calr AccBuf_AdvanceNoPage
	incdi8 1, 0x32ed
	cpdi8 0x32ed, 32
	jr nz, AccVoice_AdvanceAndCheck_Return
	call AccWrap_PlayModeDispatch
	call AccDemo_InitDone
	stdi8 0x32f5, 255
	ordi8 0x32f4, 33

AccVoice_AdvanceAndCheck_Return:
	ret

AccVoice_HandleNoteOnEvent:
	calr AccVoice_AdvanceWithSave
	ldb_d8 w, 0x33db
	calr AccVoice_LookupTableAddress
	ldw_d16 xbc, 0x327d
	ldb_d8 w, 0x33da
	calr AccTempo_PositionCompare
	cp a, 0x18
	jr ule, AccVoice_NoteOn_InRange
	ordi8 0x32f4, 1
	jr AccVoice_NoteOn_Return

AccVoice_NoteOn_InRange:
	calr AccMidi_Dispatch

AccVoice_NoteOn_Return:
	ret

AccVoice_HandleBarEndEvent:
	bitda 1, 0x32f4
	jr z, AccVoice_BarEnd_Process
	ordi8 0x32f4, 1
	jrl AccVoice_NullRet

AccVoice_BarEnd_Process:
	ldb_d8 w, 0x33db
	calr AccVoice_LookupExtParamAddr
	ldw_d16 xbc, 0x327d
	ldb_d8 w, 0x33da
	calr AccTempo_PositionCompare
	cp a, 0x18
	jr ule, AccVoice_BarEnd_InRange
	ordi8 0x32f4, 1
	jrl AccVoice_NullRet

AccVoice_BarEnd_InRange:
	ordi8 0x32f4, 2
	ldb_d8 a, 0x33db
	inc 1, a
	ld w, a
	and a, 0xf
	cpda8 a, 1075
	jr z, AccVoice_BarEnd_NextPage
	stb_d8 0x33db, w
	calr AccBuf_AdvanceNoPage
	jrl AccVoice_NullRet

AccVoice_BarEnd_NextPage:
	and w, 0xf0
	add w, 0x10
	stb_d8 0x33db, w
	incdi8 1, 0x33da
	calr AccBuf_AdvanceNoPage
	call AccVoice_IncrementBarWithSave
	calr AccPart_Reactivate
	anddi8 0x3361, 251
	bitda 0, 0x330c
	jr nz, AccVoice_BarEnd_CheckChord94
	ldb_d8 a, 0x330b
	and a, 0x3
	jr z, AccVoice_BarEnd_CheckChord65

AccVoice_BarEnd_CheckChord94:
	ldb_d8 a, 0x33d4
	andda8 a, 0x3326
	jr nz, AccVoice_SetChordChangeFlags

AccVoice_BarEnd_CheckChord65:
	ldb_d8 a, 0x3309
	and a, 0x3
	jr nz, AccVoice_BarEnd_CheckChord95
	ldb_d8 a, 0x330a
	and a, 0xd
	jr z, AccVoice_BarEnd_CheckSync69

AccVoice_BarEnd_CheckChord95:
	ldb_d8 a, 0x33d4
	andda8 a, 0x3327
	jr nz, AccVoice_SetChordChangeFlags

AccVoice_BarEnd_CheckSync69:
	bitda 0, 0x330d
	jr nz, AccVoice_SetChordChangeFlags
	ldb_d8 a, 0x335c
	and a, 0x3f
	jr z, AccVoice_NullRet
	bitda 7, 0x3361
	jr nz, AccVoice_SetChordChangeFlags
	jr AccVoice_NullRet


; -----------------------------------------------------------------------------
; Section: Chord, Table & Address Lookup
; -----------------------------------------------------------------------------
; Chord change flags, voice table address lookup,
; and buffer advance routines.
; -----------------------------------------------------------------------------

AccVoice_SetChordChangeFlags:
	ordi8 0x32f3, 128
	ordi8 0x32f4, 1
	ldb_d8 a, 0x3312
	orda8 a, 0x3313
	and a, 0x3f
	jr z, AccVoice_NullRet
	bitda 0, 0x3301
	jr z, AccVoice_NullRet
	anddi8 0x330e, 252
	ordi8 0x330e, 1
	ldb_d8 a, 0x33d4
	andda8 a, 0x3312
	jr z, AccVoice_NullRet
	ordi8 0x330e, 2

AccVoice_NullRet:
	ret

AccVoice_LookupTableAddress:
	ld xde, Display_FontPalette_Table_0x1D46
	and w, 0x7
	sla w, 1
	ldw_sri DE, 0x03, 0xe8, 0xe1
	xor w, w
	add de, wa
	ret

AccVoice_LookupExtParamAddr:
	ld xde, Display_FontPalette_Table_0x1D46
	and w, 0x7
	inc 1, w
	sla w, 1
	ldw_sri DE, 0x03, 0xe8, 0xe1
	ret

AccVoice_AdvanceWithSave:
	ldw_d16 xiy, 0x33d8
	ldw_d16 xiz, 0x33d6
	call AccBuf_AdvanceWithPageTurn
	ret

AccBuf_AdvanceNoPage:
	ldw_d16 xiy, 0x33d8
	ldw_d16 xiz, 0x33d6
	call AccBuf_Advance
	stda16 0x33d6, xiz
	stda16 0x33d8, xiy
	ret

AccVoice_HandleMarker83:
	ldb_d8 w, 0x33d4
	ldb_d8 a, 0x3314
	orda8 a, 0x3315
	and w, a
	jr nz, AccVoice_Marker83_Activate
	ldb_d8 a, 0x33d4
	andda8 a, 0x3328
	jr z, AccVoice_Marker83_CheckDeact

AccVoice_Marker83_Activate:
	calr AccVoice_ActivatePart
	jr AccVoice_Marker83_Return

AccVoice_Marker83_CheckDeact:
	calr AccPart_CheckAnyActive
	andda8 a, 0x33d4
	jr z, AccVoice_Marker83_NextPart
	calr AccPart_Deactivate
	jr AccVoice_Marker83_Return

AccVoice_Marker83_NextPart:
	calr AccPart_AdvanceAndResolve

AccVoice_Marker83_Return:
	ret

AccVoice_ActivatePart:
	ldb_d8 a, 0x33d4
	orddm8 0x332a, a
	orddm8 0x3328, a
	ordi8 0x32f4, 1
	ldb_d8 a, 0x332a
	and a, 0x3f
	cp a, 0x3f
	jr nz, AccVoice_ActivatePart_Return
	ordi8 0x3283, 4
	anddi8 0x332a, 192

AccVoice_ActivatePart_Return:
	ret

AccVoice_ActivateByteData:
	ldb_d8	a, 0x3470
	and	a, 192
	jr	nz, 10
	ldb_d8	a, 0x33d4
	andda8	a, 0x3329
	jr	z, 16
	calr	278
	ldb_d8	a, 0x33d4
	xor	a, 255
	anddm8	0x3329, a
	jr	104
	ldb_d8	a, 0x3316
	orda8	a, 0x3317
	orda8	a, 0x3318
	andda8	a, 0x33d4
	jr	nz, 43
	.byte 0xf1, 0x01
	ldw	hl, 0x66c8
	ldb	e, 193
	ret
	ldw	hl, 0xfc3c
	.byte 0xc1
	ret
	ldw	hl, 318
	ldb_d8	a, 0x33d4
	andda8	a, 0x3312
	jr	z, 5
	.byte 0xc1
	ret
	ldw	hl, 574
	.byte 0xc1, 0xf3
	ldw	de, 0x803e
	.byte 0xc1, 0xf4
	ldw	de, 318
	jr	6
	calr	46
	calr	102
	ldb_d8	a, 0x33d4
	xor	a, 255
	anddm8	0x3312, a
	anddm8	0x3313, a
	anddm8	0x3316, a
	anddm8	0x3317, a
	anddm8	0x3318, a
	stdi8	0x33db, 0
	stdi8	0x33ea, 0
	ret
	.byte 0xc1, 0xf4
	ldw	de, 318

AccPart_SelectSourceOrParam:
	cpdi8 0x32e5, 128
	jr c, AccPart_SelectSource_Param
	calr AccPart_SelectSource
	jr AccPart_SelectSource_Done

AccPart_SelectSource_Param:
	calr AccPart_LoadParamOffsetTable

AccPart_SelectSource_Done:
	ldb_d8 w, 0x33d4
	ret

AccPart_AdvanceAndResolve:
	calr AccPart_IncrementIndex
	ldb_d8 a, 0x33d4
	andda8 a, 0x335d
	jr z, AccPart_AdvanceResolve_Done
	call AccVoice_InitPerChannel
	calr AccPart_LoadParamOffsetTable
	ldb_d8 a, 0x33d4
	xor a, 0xff
	anddm8 0x335d, a
	call AccVoice_AssignPerPart

AccPart_AdvanceResolve_Done:
	calr AccPart_ResolveStyleAddr
	ret

AccPart_ResolveStyleAddr:
	cpdi8 0x32e5, 128
	jr c, AccPart_ResolveStyle_Bound
	ldb_d8 a, 0x32e5
	and a, 0x7f
	call AccVoice_ResolveParamAddr
	calr AccPart_GetFreeVoiceAddr
	stda16 0x33d6, xwa
	stdi16 0x33d8, 6
	jr AccPart_ResolveStyle_Return

AccPart_ResolveStyle_Bound:
	ldda32 xiy, 0x32ce
	ldb_d8 a, 0x33d5
	call AccPart_LookupBoundVoiceParam
	calr AccPart_GetParamAddr
	stda16 0x33d8, xwa

AccPart_ResolveStyle_Return:
	ret

AccPart_IncrementIndex:
	cpdi8 0x32e5, 128
	jr nc, AccPart_IncrementIndex_Return
	ldda32 xiy, 0x32ce
	incdi8 1, 0x33d5
	xor xhl, xhl
	ldb_d8 w, 0x33d5
	call AccStyle_ReadParamOffset
	cp w, 0x83
	jr nz, AccPart_IncrementIndex_Return
	ldb_d8 a, 0x33d5
	call AccTuning_FetchValue
	stb_d8 0x33d5, a

AccPart_IncrementIndex_Return:
	ret

AccPart_ResolveWithPedal:
	cpdi8 0x32e5, 128
	jr c, AccPart_ResolveWithPedal_Bound
	bitda 0, 0x3363
	jr nz, AccPart_ResolveWithPedal_DirB
	calr AccPedal_DirectionA
	ldda32 xiy, 0x32d3
	calr AccPart_GetParamAddr
	stda16 0x33d8, xwa
	jr AccPart_ResolveWithPedal_Return

AccPart_ResolveWithPedal_DirB:
	ldb_d8 w, 0x33d4
	calr AccPedal_DirectionB
	call AccVoice_ResolveParamAddr
	calr AccPart_GetFreeVoiceAddr
	stda16 0x33d6, xwa
	stdi16 0x33d8, 6
	jr AccPart_ResolveWithPedal_Return

AccPart_ResolveWithPedal_Bound:
	calr AccPedal_DirectionA
	ldda32 xiy, 0x32ce
	calr AccPart_GetParamAddr
	stda16 0x33d8, xwa

AccPart_ResolveWithPedal_Return:
	ret

AccPart_LoadParamOffsetTable:
	ldda32 xiy, 0x32ce
	ldb_d8 a, 0x33d5
	ldb w, 0x0
	call AccPart_GetVoiceParamOffsetTable
	calr AccPart_LoadTuningByChannel
	ret

AccPart_LoadTuningByChannel:
	cpdi8 0x33d4, 1
	jr nz, AccPart_LoadTuning_Kbd2
	call AccTuning_LoadAndApplyMaster
	ordi8 0x332c, 1
	jr AccPart_NullRet

AccPart_LoadTuning_Kbd2:
	cpdi8 0x33d4, 2
	jr nz, AccPart_LoadTuning_Acc1
	call AccTuning_LoadAndApplyMaster
	ordi8 0x332c, 2
	jr AccPart_NullRet

AccPart_LoadTuning_Acc1:
	cpdi8 0x33d4, 4
	jr nz, AccPart_LoadTuning_Acc2
	call AccTuning_LoadCoarseFromStyle
	ordi8 0x332c, 4
	jr AccPart_NullRet

AccPart_LoadTuning_Acc2:
	cpdi8 0x33d4, 8
	jr nz, AccPart_LoadTuning_Acc3
	call AccTuning_LoadFineFromStyle
	ordi8 0x332c, 8
	jr AccPart_NullRet

AccPart_LoadTuning_Acc3:
	cpdi8 0x33d4, 16
	jr nz, AccPart_LoadTuning_Acc4
	call AccTuning_LoadOctaveFromStyle
	ordi8 0x332c, 16
	jr AccPart_NullRet

AccPart_LoadTuning_Acc4:
	cpdi8 0x33d4, 32
	jr nz, AccPart_NullRet
	call AccTuning_LoadTransposeFromStyle
	ordi8 0x332c, 32

AccPart_NullRet:
	ret

AccPart_GetFreeVoiceAddr:
	ldb_d8 a, 0x33d4
	xor a, 0xff
	anddm8 0x33e0, a
	cpdi8 0x33d4, 1
	jr nz, AccPart_FreeAddr_Kbd2
	ld wa, (xiy + 256)
	jr AccPart_CheckEndOfDataMarker

AccPart_FreeAddr_Kbd2:
	cpdi8 0x33d4, 2
	jr nz, AccPart_FreeAddr_Acc1
	ldw wa, 0xfffe
	jr AccPart_CheckEndOfDataMarker

AccPart_FreeAddr_Acc1:
	cpdi8 0x33d4, 4
	jr nz, AccPart_FreeAddr_Acc2
	ld wa, (xiy + 4)
	jr AccPart_CheckEndOfDataMarker

AccPart_FreeAddr_Acc2:
	cpdi8 0x33d4, 8
	jr nz, AccPart_FreeAddr_Acc3
	ld wa, (xiy + 6)
	jr AccPart_CheckEndOfDataMarker

AccPart_FreeAddr_Acc3:
	cpdi8 0x33d4, 16
	jr nz, AccPart_FreeAddr_Acc4
	ld wa, (xiy + 8)
	jr AccPart_CheckEndOfDataMarker

AccPart_FreeAddr_Acc4:
	cpdi8 0x33d4, 32
	jr nz, AccPart_CheckEndOfDataMarker
	ld wa, (xiy + 10)

AccPart_CheckEndOfDataMarker:
	cp wa, 0xfffe
	jr nz, AccPart_FreeAddr_Return
	ldb_d8 a, 0x33d4
	orddm8 0x33e0, a
	ldw wa, 0xfffe

AccPart_FreeAddr_Return:
	ret

; ============================================================================
; AccPart_GetParamAddr - Get parameter address for accompaniment part
; ============================================================================
; Input:  HL = base pointer, channel selector bitmask at 13268
; Output: WA = parameter address for the selected part
; Adds per-part offset (0x118-0x1d6) based on channel (kbd/acc1-5).
; ============================================================================
AccPart_GetParamAddr:
	ldb_d8 a, 0x33d4
	xor a, 0xff
	anddm8 0x33e0, a
	cpdi8 0x33d4, 1
	jr nz, AccPart_ParamAddr_Kbd2
	add hl, 0x118
	ldw_sri WA, 0x07, 0xf4, 0xec
	jr AccPart_SubtractBaseAddr

AccPart_ParamAddr_Kbd2:
	cpdi8 0x33d4, 2
	jr nz, AccPart_ParamAddr_Acc1
	add hl, 0x13e
	ldw_sri WA, 0x07, 0xf4, 0xec
	jr AccPart_SubtractBaseAddr

AccPart_ParamAddr_Acc1:
	cpdi8 0x33d4, 4
	jr nz, AccPart_ParamAddr_Acc2
	add hl, 0x164
	ldw_sri WA, 0x07, 0xf4, 0xec
	jr AccPart_SubtractBaseAddr

AccPart_ParamAddr_Acc2:
	cpdi8 0x33d4, 8
	jr nz, AccPart_ParamAddr_Acc3
	add hl, 0x18a
	ldw_sri WA, 0x07, 0xf4, 0xec
	jr AccPart_SubtractBaseAddr

AccPart_ParamAddr_Acc3:
	cpdi8 0x33d4, 16
	jr nz, AccPart_ParamAddr_Acc4
	add hl, 0x1b0
	ldw_sri WA, 0x07, 0xf4, 0xec
	jr AccPart_SubtractBaseAddr

AccPart_ParamAddr_Acc4:
	cpdi8 0x33d4, 32
	jr nz, AccPart_SubtractBaseAddr
	add hl, 0x1d6
	ldw_sri WA, 0x07, 0xf4, 0xec
	jr AccPart_SubtractBaseAddr

AccPart_SubtractBaseAddr:
	sub wa, 0x8000
	add wa, 0x6
	ret

AccPart_SelectSource:
	ldda32 xiy, 0x32ce
	cpdi8 0x33d4, 1
	jr z, AccPart_SelectKbd
	cpdi8 0x33d4, 2
	jr nz, AccPart_CheckAcc1

AccPart_SelectKbd:
	add xiy, 0x18
	ld xix, 0x3246
	jr AccPart_CopyData

AccPart_CheckAcc1:
	cpdi8 0x33d4, 4
	jr nz, AccPart_CheckAcc2
	add xiy, 0x20
	ld xix, 0x324d
	jr AccPart_CopyData

AccPart_CheckAcc2:
	cpdi8 0x33d4, 8
	jr nz, AccPart_CheckAcc3
	add xiy, 0x28
	ld xix, 0x3254
	jr AccPart_CopyData

AccPart_CheckAcc3:
	cpdi8 0x33d4, 16
	jr nz, AccPart_CheckAcc4
	add xiy, 0x30
	ld xix, 0x325b
	jr AccPart_CopyData

AccPart_CheckAcc4:
	cpdi8 0x33d4, 32
	jr nz, AccPart_CheckAcc4
	add xiy, 0x38
	ld xix, 0x3262

AccPart_CopyData:
	lds bc, 7
	ldir85
	ldb_d8 a, 0x33d4
	orddm8 0x332c, a
	ret

AccPart_CheckAnyActive:
	ldb_d8 a, 0x3316
	orda8 a, 0x3317
	orda8 a, 0x3318
	orda8 a, 0x3312
	orda8 a, 0x3313
	ret


; -----------------------------------------------------------------------------
; Section: Pedal Direction & MIDI Dispatch
; -----------------------------------------------------------------------------
; Pedal direction control (forward/reverse/alternate)
; and accompaniment MIDI event dispatch.
; -----------------------------------------------------------------------------

AccPedal_DirectionA:
	ldb_d8 a, 0x3470
	and a, 0xc0
	jr z, AccPedal_DirA_CheckBit1
	bitda 7, 0x3470
	jr z, AccPedal_DirA_SetForward
	bitda 6, 0x3470
	jr z, AccPedal_DirA_SetReverse

AccPedal_DirA_CheckBit1:
	bitda 1, 0x32fb
	jr nz, AccPedal_DirA_SetReverse

AccPedal_DirA_SetForward:
	ordi8 0x3309, 1
	jr AccPedal_DirA_Apply

AccPedal_DirA_SetReverse:
	ordi8 0x3309, 2

AccPedal_DirA_Apply:
	ldb_d8 a, 0x33d5
	call AccVoice_ComputeParamAddr
	anddi8 0x3309, 252
	ret

AccPedal_DirectionB:
	ldb_d8 a, 0x3470
	and a, 0xc0
	jr z, AccPedal_DirB_CheckBit0
	bitda 7, 0x3470
	jr z, AccPedal_DirB_Alternate
	bitda 6, 0x3470
	jr z, AccPedal_DirB_InvertAndStore

AccPedal_DirB_CheckBit0:
	bitda 0, 0x32fb
	jr nz, AccPedal_DirB_Alternate

AccPedal_DirB_InvertAndStore:
	ld a, w
	xor w, 0xff
	anddm8 0x3312, w
	ldb_d8 w, 1075
	cpda8 w, 0x336a
	jr nz, AccPedal_DirB_DefaultStyle
	orddm8 0x3313, a
	ldb_d8 a, 0x336b
	jr AccPedal_DirB_Return

AccPedal_DirB_Alternate:
	ld a, w
	xor w, 0xff
	anddm8 0x3313, w
	ldb_d8 w, 1075
	cpda8 w, 0x3368
	jr nz, AccPedal_DirB_DefaultStyle
	orddm8 0x3312, a
	ldb_d8 a, 0x3369
	jr AccPedal_DirB_Return

AccPedal_DirB_DefaultStyle:
	ldb_d8 a, 0x32e5
	and a, 0x7f

AccPedal_DirB_Return:
	ret

AccMidi_Dispatch:
	calr AccMidi_NormalizeVelocity
	cp a, 0x90
	jr z, AccMidi_NoteEvent
	cp a, 0x91
	jr z, AccMidi_NoteEvent
	cp a, 0xd1
	jr z, AccMidi_ControlEvent
	cp a, 0xd2
	jr z, AccMidi_ControlEvent
	cp a, 0xd3
	jr z, AccMidi_ControlEvent
	cp a, 0xd4
	jr z, AccMidi_ControlEvent
	cp a, 0xd5
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
	stb_d8 0x33d2, a
	ldb_sri A, 0x07, 0xec, 0xf4
	ret

AccMidi_ParseNoteOn:
	calr AccMidi_ParseCommon
	cpdi8 0x342d, 145
	jr nz, AccMidi_ParseNoteOn_StorePos
	ldb_sri A, 0x07, 0xec, 0xf4
	stb_d8 0x3433, a
	call AccBuf_Advance
	ldb_sri A, 0x07, 0xec, 0xf4
	stb_d8 0x3434, a
	call AccBuf_Advance

AccMidi_ParseNoteOn_StorePos:
	stda16 0x33d8, xiy
	stda16 0x33d6, xiz
	ret

AccMidi_ParseCommon:
	stb_d8 0x342d, a
	call AccBuf_Advance
	stb_d8 0x342e, e
	call AccBuf_Advance
	ldb_sri A, 0x07, 0xec, 0xf4
	stb_d8 0x342f, a
	cpdi8 0x33d4, 1
	jr z, AccMidi_ParseCommon_ExtraFields
	cpdi8 0x33d4, 2
	jr z, AccMidi_ParseCommon_ExtraFields
	call Rhythm_CheckVelocityThreshold

AccMidi_ParseCommon_ExtraFields:
	call AccBuf_Advance
	ldb_sri A, 0x07, 0xec, 0xf4
	stb_d8 0x3430, a
	call AccBuf_Advance
	ldb_sri A, 0x07, 0xec, 0xf4
	stb_d8 0x3431, a
	call AccBuf_Advance
	ldb_sri A, 0x07, 0xec, 0xf4
	stb_d8 0x3432, a
	call AccBuf_Advance
	ret

AccMidi_SelectVelocitySource:
	ldb_d8 a, 0x33d4
	ldb_d8 w, 0x333f
	andda8 a, 0x3316
	jr nz, AccMidi_VelSource_Active
	andda8 a, 0x3317
	jr nz, AccMidi_VelSource_Active
	andda8 a, 0x3318
	jr nz, AccMidi_VelSource_Active
	andda8 a, 0x3314
	jr nz, AccMidi_VelSource_Active
	andda8 a, 0x3315
	jr z, AccMidi_VelSource_Store

AccMidi_VelSource_Active:
	ldb_d8 w, 0x3340

AccMidi_VelSource_Store:
	stb_d8 0x33de, w
	ret

AccMidi_DispatchPerPart:
	cpdi8 0x33d4, 1
	jr nz, AccMidi_DispatchKbd2
	calr AccKbd1_RingBufEntry
	jr AccMidi_DispatchAcc4Return

AccMidi_DispatchKbd2:
	cpdi8 0x33d4, 2
	jr nz, AccMidi_DispatchAcc1
	calr AccKbd2_RingBufEntry
	jr AccMidi_DispatchAcc4Return

AccMidi_DispatchAcc1:
	cpdi8 0x33d4, 4
	jr nz, AccMidi_DispatchAcc2
	call AccCh1_NoteOnEntry
	jr AccMidi_DispatchAcc4Return

AccMidi_DispatchAcc2:
	cpdi8 0x33d4, 8
	jr nz, AccMidi_DispatchAcc3
	call AccCh2_NoteOnEntry
	jr AccMidi_DispatchAcc4Return

AccMidi_DispatchAcc3:
	cpdi8 0x33d4, 16
	jr nz, AccMidi_DispatchAcc4
	call AccCh3_NoteOnEntry
	jr AccMidi_DispatchAcc4Return

AccMidi_DispatchAcc4:
	cpdi8 0x33d4, 32
	jr nz, AccMidi_DispatchAcc4Return
	call AccCh4_NoteOnEntry

AccMidi_DispatchAcc4Return:
	ret

AccKbd1_RingBufEntry:
	calr AccKbd1_CheckEligible
	bitda 0, 0x33e1
	jr z, AccKbd1_RingBufReturn
	ld xhl, 0x2a94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccBuf_WriteNoteEvent

AccKbd1_RingBufReturn:
	ret

AccKbd1_CheckEligible:
	anddi8 0x33e1, 254
	bitda 0, 0x33de
	jr z, AccKbd1_CheckReturn
	bitda 0, 0x3362
	jr nz, AccKbd1_CheckReturn
	bitda 0, 0x3307
	jr z, AccKbd1_CheckReturn
	bitda 4, 0x379b
	jr z, AccKbd1_CheckRecording
	bitda 2, 0x34cf
	jr nz, AccKbd1_CheckReturn
	bitda 7, 0x3558
	jr z, AccKbd1_CheckRecording
	ldb_d8 a, 0x3558
	and a, 0x7f
	cpda8 a, 0x342f
	jr z, AccKbd1_CheckReturn
	cp a, 0x30
	jr nz, AccKbd1_CheckRecording
	cpdi8 0x342f, 93
	jr z, AccKbd1_CheckReturn

AccKbd1_CheckRecording:
	bitda 1, 0x3335
	jr nz, AccKbd1_CheckReturn
	bitda 0, 0x347a
	jr nz, AccKbd1_CheckReturn
	bitda 0, 0x33e8
	jr nz, AccKbd1_CheckReturn
	ld xhl, 0x2a94
	calr AccBuf_ComputeFillLevel
	cpdi16 0x3324, 16
	jr ule, AccKbd1_CheckReturn
	ordi8 0x33e1, 1

AccKbd1_CheckReturn:
	ret

AccBuf_WriteNoteEvent:
	ldb_d8 a, 0x342d
	lda_dri XBC, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	call RhythmAccent_UpdateRingBufPosition
	ldb_d8 a, 0x342f
	lda_dri XBC, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	ldb_d8 a, 0x3430
	lda_dri XBC, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	ldb_d8 a, 0x3431
	cps a, 0
	jr nz, AccBuf_WriteNote_VelNonZero
	ldb a, 0x1

AccBuf_WriteNote_VelNonZero:
	lda_dri XBC, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	ldb_d8 a, 0x3432
	lda_dri XBC, 0x07, 0xec, 0xf4
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
	stda16 0x3324, xwa
	ret

AccTempo_PositionCompare:
	cpda8 w, 0x32b4
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
	cpda8 w, 0x32b4
	jr c, AccTempo_BarZero
	cp w, 0xff
	jr nz, AccTempo_ComputeDelta
	cpdi8 0x32b4, 0
	jr z, AccTempo_TooFar
	jr AccTempo_ComputeDelta

AccTempo_BarZero:
	cps w, 0
	jr nz, AccTempo_TooFar
	cpdi8 0x32b4, 255
	jr z, AccTempo_ComputeDelta

AccTempo_TooFar:
	ldb a, 0x0
	jr AccTempo_Return

AccTempo_ComputeDelta:
	xor xwa, xwa
	ldb_d8 a, 1112
	sla a, 1
	add xwa, Display_FontPalette_Table_0x1D46
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
	bitda 0, 0x32f4
	jr nz, AccKbd1_ProcessReturn
	calr AccKbd1_ScanSlots
	calr AccKbd1_DrainRingBuf
	ld xiy, 0x3214
	ld xix, 0x322d
	lds bc, 5
	ldir85
	ldb_d8 a, 0x343c
	stb_d8 0x32ec, a
	call RhythmPart1_ProcessAccentData
	anddi8 0x332c, 254

AccKbd1_ProcessReturn:
	ret

AccKbd1_TimingCheck:
	ldb a, 0x0
	ldb_d8 w, 0x33db
	calr AccVoice_LookupTableAddress
	ldw_d16 xbc, 0x327d
	ldb_d8 w, 0x33da
	calr AccTempo_PositionCompare
	cp a, 0x18
	jr ule, AccKbd1_TimingOK
	ordi8 0x32f4, 1
	jr AccKbd1_TimingReturn

AccKbd1_TimingOK:
	stb_d8 0x343c, a
	ldb a, 0x5f
	ldb_d8 w, 1112
	dec 1, w
	calr AccVoice_LookupTableAddress
	ldw_d16 xbc, 0x327d
	ldb_d8 w, 0x33da
	dec 1, w
	calr AccTempo_PositionCompare
	stb_d8 0x343b, a

AccKbd1_TimingReturn:
	ret

AccKbd1_ScanSlots:
	ld xhl, 0x3094

AccKbd1_ScanSlots_Loop:
	calr AccSlot_CheckAndUpdate
	add xhl, 0x6
	cp xhl, 0x30c4
	jr c, AccKbd1_ScanSlots_Loop
	ret

AccSlot_CheckAndUpdate:
	bitm 7, (xhl)
	jr z, AccSlot_Return
	ld de, (xhl + 4)
	ldb_d8 a, 0x343b
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
	cpdm16 0x3372, xwa
	jr ule, AccSlot_RestoreInterrupts
	stda16 0x3372, xwa

AccSlot_RestoreInterrupts:
	ei 0

AccSlot_Return:
	ret

AccKbd1_DrainRingBuf:
	ld xhl, 0x2a94
	ld iy, (xhl + 6)
	ld bc, (xhl + 2)

AccKbd1_DrainLoop:
	cp (xhl + 4), iy
	jr z, AccKbd1_DrainDone
	ldb_sri A, 0x07, 0xec, 0xf4
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
	ldb_sri W, 0x07, 0xec, 0xf4
	call Rhythm_AdvancePosition
	ldb_sri E, 0x07, 0xec, 0xf4
	pushw iy
	inc 1, iy
	cp iy, bc
	jr ule, AccBuf_NoteEvent_WrapPos
	ld iy, (xhl + 256)

AccBuf_NoteEvent_WrapPos:
	ldb_sri D, 0x07, 0xec, 0xf4
	popw iy
	ldb_d8 a, 0x343b
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
	lda_dri XBC, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	lda_dri XWA, 0x07, 0xec, 0xf4
	jr AccBuf_NoteEvent_Return

AccBuf_NoteEvent_SkipTiming:
	call RingBuf_AdvanceIndex

AccBuf_NoteEvent_Return:
	ei 0
	ret

AccKbd2_CheckActive:
	ldb_d8	a, 0x33d4
	andda8	a, 0x33e0
	jr	z, 76
	ldb_d8	a, 0x33d4
	ldb_d8	w, 0x3314
	orda8	w, 0x3315
	and	w, a
	jr	z, 10
	orddm8	0x332a, a
	orddm8	0x3328, a
	jr	50
	ldb_d8	a, 0x33d4
	xor	a, 255
	anddm8	0x3312, a
	anddm8	0x3313, a
	anddm8	0x3316, a
	anddm8	0x3317, a
	anddm8	0x3318, a
	anddm8	0x335d, a
	anddm8	0x3329, a
	stdi8	0x33ea, 0
	stdi8	0x33d6, 254
	stdi8	0x33d8, 6
	ret

AccKbd2_ProcessEntry:
	calr AccKbd2_SaveState
	calr AccVoice_ProcessEventLoop
	calr AccKbd2_RestoreState

AccKbd2_SaveState:
	anddi8 0x32f4, 252
	stdi8 0x32ed, 0
	ldb a, 0x2
	stb_d8 0x33d4, a
	ldw_d16 xwa, 0x3299
	stda16 0x33d6, xwa
	ldw_d16 xwa, 0x3289
	stda16 0x33d8, xwa
	ldb_d8 a, 0x32b6
	stb_d8 0x33da, a
	ldb_d8 a, 0x32ac
	stb_d8 0x33db, a
	ldb_d8 a, 0x32a4
	stb_d8 0x33d5, a
	ldb_d8 a, 0x33ec
	stb_d8 0x33ea, a
	ret

AccKbd2_RestoreState:
	ldw_d16 xwa, 0x33d6
	stda16 0x3299, xwa
	ldw_d16 xwa, 0x33d8
	stda16 0x3289, xwa
	ldb_d8 a, 0x33da
	stb_d8 0x32b6, a
	ldb_d8 a, 0x33db
	stb_d8 0x32ac, a
	ldb_d8 a, 0x33d5
	stb_d8 0x32a4, a
	ldb_d8 a, 0x33ea
	stb_d8 0x33ec, a
	ret

AccKbd2_RingBufEntry:
	calr AccKbd2_CheckEligible
	bitda 0, 0x33e1
	jr z, AccKbd2_RingBufReturn
	ld xhl, 0x2b94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccBuf_WriteNoteEvent

AccKbd2_RingBufReturn:
	ret

AccKbd2_CheckEligible:
	anddi8 0x33e1, 254
	cpdi8 0x32e5, 128
	jr nc, AccKbd2_CheckReturn
	bitda 1, 0x33de
	jr z, AccKbd2_CheckReturn
	bitda 0, 0x3307
	jr z, AccKbd2_CheckReturn
	bitda 1, 0x3335
	jr nz, AccKbd2_CheckReturn
	bitda 0, 0x347a
	jr nz, AccKbd2_CheckReturn
	bitda 0, 0x33e8
	jr nz, AccKbd2_CheckReturn
	ld xhl, 0x2b94
	calr AccBuf_ComputeFillLevel
	cpdi16 0x3324, 16
	jr ule, AccKbd2_CheckReturn
	ordi8 0x33e1, 1

AccKbd2_CheckReturn:
	ret

AccKbd2_ProcessNotes:
	calr AccKbd1_TimingCheck
	bitda 0, 0x32f4
	jr nz, AccKbd2_ProcessReturn
	calr AccKbd2_ScanSlots
	calr AccKbd2_DrainRingBuf
	anddi8 0x332c, 253

AccKbd2_ProcessReturn:
	ret

AccKbd2_ScanSlots:
	ld xhl, 0x30c4

AccKbd2_ScanSlots_Loop:
	calr AccSlot_CheckAndUpdate
	add xhl, 0x6
	cp xhl, 0x30f4
	jr c, AccKbd2_ScanSlots_Loop
	ret

AccKbd2_DrainRingBuf:
	ld xhl, 0x2b94
	ld iy, (xhl + 6)
	ld bc, (xhl + 2)

AccKbd2_DrainLoop:
	cp (xhl + 4), iy
	jr z, AccKbd2_DrainDone
	ldb_sri A, 0x07, 0xec, 0xf4
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
	anddi8 0x32f4, 252

AccSeq_ScanLoop:
	bitda 0, 0x32f4
	jrl nz, AccSeq_ScanDone
	ldda32 xhl, 0x3293
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
	ldb_d8 w, 0x32b1
	calr AccVoice_LookupTableAddress
	ldw_d16 xbc, 0x327d
	ldb_d8 w, 0x32bb
	calr AccTempo_PositionCompare
	cp a, 0x18
	jr ugt, AccSeq_NoteOn_TooFar
	calr AccSeq_ParseNoteEvent
	jr AccSeq_NoteOn_Continue

AccSeq_NoteOn_TooFar:
	ordi8 0x32f4, 1

AccSeq_NoteOn_Continue:
	jr AccSeq_ScanLoop

AccSeq_EndOfBar:
	bitda 1, 0x32f4
	jr z, AccSeq_EndOfBar_Process
	ordi8 0x32f4, 1
	jr AccSeq_ScanLoop

AccSeq_EndOfBar_Process:
	ldb_d8 w, 0x32b1
	calr AccVoice_LookupExtParamAddr
	ldw_d16 xbc, 0x327d
	ldb_d8 w, 0x32bb
	calr AccTempo_PositionCompare
	cp a, 0x18
	jr ugt, AccSeq_EndOfBar_TooFar
	ordi8 0x32f4, 2
	ldb_d8 a, 0x32b1
	inc 1, a
	ld w, a
	and a, 0xf
	cpda8 a, 1075
	jr z, AccSeq_NextBarPage
	stb_d8 0x32b1, w
	calr AccSeq_AdvancePointer
	jrl AccSeq_ScanLoop

AccSeq_NextBarPage:
	and w, 0xf0
	add w, 0x10
	stb_d8 0x32b1, w
	incdi8 1, 0x32bb
	ld xhl, Display_FontPalette_Table_0x1D61
	add xhl, 0x6
	stda32 0x3293, xhl
	jrl AccSeq_ScanLoop

AccSeq_EndOfBar_TooFar:
	ordi8 0x32f4, 1
	jrl AccSeq_ScanLoop

AccSeq_ScanDone:
	ret

AccSeq_ReadNextByte:
	ldda32 xhl, 0x3293
	inc 1, xhl
	ld a, (xhl)
	ret

AccSeq_AdvancePointer:
	ldda32 xhl, 0x3293
	inc 1, xhl
	stda32 0x3293, xhl
	ret

AccSeq_ResetToStart:
	ld xhl, Display_FontPalette_Table_0x1D61
	add xhl, 0x6
	stda32 0x3293, xhl
	ld a, (xhl)
	ret

AccSeq_ParseNoteEvent:
	cps a, 0
	jr nz, AccSeq_ParseNote_VelNonZero
	ldb a, 0x1

AccSeq_ParseNote_VelNonZero:
	ld e, a
	ldda32 xhl, 0x3293
	ld a, (xhl)
	stb_d8 0x342d, a
	calr AccSeq_AdvancePointer
	stb_d8 0x342e, e
	calr AccSeq_AdvancePointer
	ld a, (xhl)
	stb_d8 0x342f, a
	calr AccSeq_AdvancePointer
	ld a, (xhl)
	stb_d8 0x3430, a
	calr AccSeq_AdvancePointer
	ldb a, 0x1
	stb_d8 0x3431, a
	calr AccSeq_AdvancePointer
	ldb a, 0x0
	stb_d8 0x3432, a
	calr AccSeq_AdvancePointer
	ldb_d8 a, 0x379b
	and a, 0x3f
	jr z, AccSeq_ParseNote_CheckMode
	cpdi8 0x8d36, 181
	jr z, AccSeq_ParseNote_WriteToKbd2
	jr AccSeq_ParseNote_Return

AccSeq_ParseNote_CheckMode:
	ldb_d8 a, 0x3335
	cps a, 3
	jr nz, AccSeq_ParseNote_CheckRec
	bitda 0, 0x347a
	jr z, AccSeq_ParseNote_WriteToKbd2

AccSeq_ParseNote_CheckRec:
	bitda 0, 0x33e8
	jr z, AccSeq_ParseNote_Return

AccSeq_ParseNote_WriteToKbd2:
	ld xhl, 0x2b94
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
	anddi8 0x32f4, 252
	stdi8 0x32ed, 0
	ldb a, 0x4
	stb_d8 0x33d4, a
	ldw_d16 xwa, 0x329b
	stda16 0x33d6, xwa
	ldw_d16 xwa, 0x328b
	stda16 0x33d8, xwa
	ldb_d8 a, 0x32b7
	stb_d8 0x33da, a
	ldb_d8 a, 0x32ad
	stb_d8 0x33db, a
	ldb_d8 a, 0x32a5
	stb_d8 0x33d5, a
	ldb_d8 a, 0x33ed
	stb_d8 0x33ea, a
	ret

AccCh1_RestoreState:
	ldw_d16 xwa, 0x33d6
	stda16 0x329b, xwa
	ldw_d16 xwa, 0x33d8
	stda16 0x328b, xwa
	ldb_d8 a, 0x33da
	stb_d8 0x32b7, a
	ldb_d8 a, 0x33db
	stb_d8 0x32ad, a
	ldb_d8 a, 0x33d5
	stb_d8 0x32a5, a
	ldb_d8 a, 0x33ea
	stb_d8 0x33ed, a
	ret

AccVoice_AssignPerPart:
	cpdi8 0x33d4, 1
	jr z, AccVoice_AssignReturn
	cpdi8 0x33d4, 2
	jr z, AccVoice_AssignReturn
	ldb_d8 a, 0x33d5
	call AccTuning_FetchValue
	stb_d8 0x3349, a
	calr AccVoice_ScanInstruments
	calr AccVoice_SendProgChange

AccVoice_AssignReturn:
	ret

AccVoice_ScanInstruments:
	ldb_d8 e, 0x3349
	stdi8 0x3333, 0

AccVoice_ScanLoop:
	cpda8 e, 0x33d5
	jr z, AccVoice_ScanDone
	ldda32 xiy, 0x32ce
	ld a, e
	call AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	ld iy, wa
	ldb_d8 a, 0x3285
	call AccVoice_TableLookup
	call AccVoice_ScanForD3
	inc 1, e
	jr AccVoice_ScanLoop

AccVoice_ScanDone:
	ret

AccVoice_SendProgChange:
	cpdi8 0x33d4, 4
	jr nz, AccVoice_SendD4
	ldb a, 0xd7
	ldb w, 0x3
	ldb_d8 e, 0x3333
	stb_d8 0x332f, e
	call Rhythm_Send3ByteMsg
	jr AccCh_ReturnStub

AccVoice_SendD4:
	cpdi8 0x33d4, 8
	jr nz, AccVoice_SendD5
	ldb a, 0xd4
	ldb w, 0x3
	ldb_d8 e, 0x3333
	stb_d8 0x3330, e
	call Rhythm_Send3ByteMsg
	jr AccCh_ReturnStub

AccVoice_SendD5:
	cpdi8 0x33d4, 16
	jr nz, AccVoice_SendD6
	ldb a, 0xd5
	ldb w, 0x3
	ldb_d8 e, 0x3333
	stb_d8 0x3331, e
	call Rhythm_Send3ByteMsg
	jr AccCh_ReturnStub

AccVoice_SendD6:
	ldb a, 0xd6
	ldb w, 0x3
	ldb_d8 e, 0x3333
	stb_d8 0x3332, e
	call Rhythm_Send3ByteMsg
	jr AccCh_ReturnStub

AccCh_ReturnStub:
	ret

AccBuf_Write3ByteEvent:
	ldb_d8 a, 0x342d
	lda_dri XBC, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	call RhythmAccent_UpdateRingBufPosition
	ldb_d8 a, 0x342f
	lda_dri XBC, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	ldb_d8 a, 0x3430
	lda_dri XBC, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	ld (xhl + 4), iy
	ret

AccCh1_Padding:
	nop
	nop

AccCh1_NoteOnEntry:
	calr AccCh1_CheckEligible
	bitda 0, 0x33e1
	jr z, AccCh1_NoteOnReturn
	ldb_d8 a, 0x32c3
	stb_d8 0x32cb, a
	ldb_d8 a, 0x32c7
	stb_d8 0x32cc, a
	anddi8 0x32f4, 251
	ordi8 0x32f4, 8
	ld xhl, 0x2c94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccBuf_WriteExtendedEvent

AccCh1_NoteOnReturn:
	ret

AccCh1_CheckEligible:
	anddi8 0x33e1, 254
	bitda 2, 0x3362
	jr nz, AccCh1_CheckReturn
	bitda 1, 0x3307
	jr z, AccCh1_CheckReturn
	bitda 3, 0xc5a0
	jr z, AccCh1_CheckReturn
	calr AccCh_CheckOverlap
	cps a, 0
	jr nz, AccCh1_CheckReturn
	bitda 1, 0x3335
	jr nz, AccCh1_CheckReturn
	bitda 0, 0x347a
	jr nz, AccCh1_CheckReturn
	bitda 0, 0x33e8
	jr nz, AccCh1_CheckReturn
	ld xhl, 0x2c94
	call AccBuf_ComputeFillLevel
	cpdi16 0x3324, 16
	jr ugt, AccCh1_SetReady
	calr AccBuf_InitWithDefaults
	jr AccCh1_CheckReturn

AccCh1_SetReady:
	ordi8 0x33e1, 1

AccCh1_CheckReturn:
	ret

AccBuf_WriteExtendedEvent:
	ldb_d8 a, 0x3433
	stb_d8 0x3336, a
	ldb_d8 a, 0x3434
	stb_d8 0x3337, a
	ldb_d8 a, 0x342d
	lda_dri XBC, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	call RhythmAccent_UpdateRingBufPosition
	ldb_d8 a, 0x342f
	stb_d8 0x3435, a
	calr AccVoice_CheckStyle
	lda_dri XBC, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	ldb_d8 a, 0x3430
	lda_dri XBC, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	ldb_d8 a, 0x3431
	cps a, 0
	jr nz, AccBuf_ExtEvt_VelNonZero
	ldb a, 0x1

AccBuf_ExtEvt_VelNonZero:
	lda_dri XBC, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	ldb_d8 a, 0x3432
	lda_dri XBC, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	calr AccBuf_ExtEvt_WriteExtra
	ldb_d8 a, 0x3435
	lda_dri XBC, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	ld (xhl + 4), iy
	ret

AccBuf_ExtEvt_WriteExtra:
	cpdi8 0x342d, 144
	jr z, AccBuf_ExtEvt_ExtraReturn
	ldb_d8 a, 0x3336
	lda_dri XBC, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	ldb_d8 a, 0x3337
	lda_dri XBC, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex

AccBuf_ExtEvt_ExtraReturn:
	ret

AccVoice_CheckStyle:
	cpdi8 0x32e5, 240
	jr c, AccVoice_CallCorrection

AccVoice_CallCorrection:
	call AccVoice_CorrectNote
	ret

AccVoice_CorrectionData:
	push	xhl
	pushw	iy
	ldb_d8	a, 0x342f
	.byte 0xf1, 0xf4
	ldw	de, 0x6ecc
	ret
	.byte 0xf1, 0xf4
	ldw	de, 0x66cb
	.byte 0x04
	call	Rhythm_CrossVoiceCorrect
	call	Rhythm_NoteRangeCheck
	call	Rhythm_VelocityCompute
	popw	iy
	pop	xhl
	ret

AccVoice_CorrectNote:
	push xhl
	pushw iy
	ldb_d8 a, 0x342f
	bitda 4, 0x32f4
	jr nz, AccVoice_VelocityLookup
	bitda 3, 0x32f4
	jr z, AccVoice_NoteRangeCheck
	call Rhythm_CrossVoiceCorrect

AccVoice_NoteRangeCheck:
	call Rhythm_NoteRangeCheck

AccVoice_VelocityLookup:
	cpdi8 0x342d, 145
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
	and a, 0xf0
	stb_d8 0x342d, a
	call AccBuf_Advance
	stb_d8 0x342e, e
	call AccBuf_Advance
	ld a, d
	and a, 0xf
	stb_d8 0x342f, a
	ldb_sri A, 0x07, 0xec, 0xf4
	stb_d8 0x3430, a
	call AccBuf_Advance
	stda16 0x33d8, xiy
	stda16 0x33d6, xiz
	ret

AccMidi_DispatchDType:
	cpdi8 0x33d4, 1
	jr nz, AccMidi_DType_CheckKbd2
	jr AccMidi_DType_Return

AccMidi_DType_CheckKbd2:
	cpdi8 0x33d4, 2
	jr nz, AccMidi_DType_CheckAcc1
	jr AccMidi_DType_Return

AccMidi_DType_CheckAcc1:
	cpdi8 0x33d4, 4
	jr nz, AccMidi_DType_CheckAcc2
	calr AccCh1_DTypeEntry
	jr AccMidi_DType_Return

AccMidi_DType_CheckAcc2:
	cpdi8 0x33d4, 8
	jr nz, AccMidi_DType_CheckAcc3
	calr AccCh2_DTypeEntry
	jr AccMidi_DType_Return

AccMidi_DType_CheckAcc3:
	cpdi8 0x33d4, 16
	jr nz, AccMidi_DType_CheckAcc4
	calr AccCh3_DTypeEntry
	jr AccMidi_DType_Return

AccMidi_DType_CheckAcc4:
	cpdi8 0x33d4, 32
	jr nz, AccMidi_DType_CheckAcc4
	calr AccCh4_DTypeEntry

AccMidi_DType_Return:
	ret

AccCh1_DTypeEntry:
	calr AccCh1_CheckEligible
	bitda 0, 0x33e1
	jr z, AccCh1_DTypeReturn
	ld xhl, 0x2c94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccBuf_Write3ByteEvent

AccCh1_DTypeReturn:
	ret

AccCh_CheckOverlap:
	ldb a, 0x0
	bitda 2, 0x34cf
	jr z, AccCh_OverlapReturn
	bitda 3, 0x379b
	jr z, AccCh_OverlapReturn
	ldb a, 0x1

AccCh_OverlapReturn:
	ret

AccBuf_InitWithDefaults:
	ldw (xhl + 256), 0xa
	ldw (xhl + 2), 0xff
	ldw (xhl + 4), 0xa
	ldw (xhl + 6), 0xa
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	stdi8 0x342d, 208
	ldb_d8 a, 0x33d2
	stb_d8 0x342e, a
	stdi8 0x342f, 2
	stdi8 0x3430, 64
	calr AccBuf_Write3ByteEvent
	ldb_d8 a, 0x33d2
	stb_d8 0x342e, a
	stdi8 0x342f, 1
	stdi8 0x3430, 0
	calr AccBuf_Write3ByteEvent
	ldb_d8 a, 0x33d2
	stb_d8 0x342e, a
	stdi8 0x342f, 3
	stdi8 0x3430, 0
	calr AccBuf_Write3ByteEvent
	ldb_d8 a, 0x33d2
	stb_d8 0x342e, a
	stdi8 0x342f, 5
	stdi8 0x3430, 127
	calr AccBuf_Write3ByteEvent
	ret

AccCh1_ProcessNotes:
	call AccKbd1_TimingCheck
	bitda 0, 0x32f4
	jr nz, AccCh1_ProcessReturn
	calr AccCh1_ScanSlots
	calr AccCh1_DrainRingBuf
	calr AccCh1_InitProgChange
	ld xiy, 0x3219
	ld xix, 0x3232
	lds bc, 5
	ldir85
	ldb_d8 a, 0x343c
	stb_d8 0x32ec, a
	call RhythmPart2_ProcessAccentData
	anddi8 0x332c, 251

AccCh1_ProcessReturn:
	ret

AccCh1_ScanSlots:
	ld xhl, 0x30f4

AccCh1_ScanSlots_Loop:
	call AccSlot_CheckAndUpdate
	add xhl, 0x9
	cp xhl, 0x313c
	jr c, AccCh1_ScanSlots_Loop
	ret

AccCh1_DrainRingBuf:
	ld xhl, 0x2c94
	ld iy, (xhl + 6)
	ld bc, (xhl + 2)

AccCh1_DrainLoop:
	cp (xhl + 4), iy
	jr z, AccCh1_DrainDone
	ldb_sri A, 0x07, 0xec, 0xf4
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
	anddi8 0x32f4, 252
	stdi8 0x32ed, 0
	ldb a, 0x8
	stb_d8 0x33d4, a
	ldw_d16 xwa, 0x329d
	stda16 0x33d6, xwa
	ldw_d16 xwa, 0x328d
	stda16 0x33d8, xwa
	ldb_d8 a, 0x32b8
	stb_d8 0x33da, a
	ldb_d8 a, 0x32ae
	stb_d8 0x33db, a
	ldb_d8 a, 0x32a6
	stb_d8 0x33d5, a
	ldb_d8 a, 0x33ee
	stb_d8 0x33ea, a
	ret

AccCh2_RestoreState:
	ldw_d16 xwa, 0x33d6
	stda16 0x329d, xwa
	ldw_d16 xwa, 0x33d8
	stda16 0x328d, xwa
	ldb_d8 a, 0x33da
	stb_d8 0x32b8, a
	ldb_d8 a, 0x33db
	stb_d8 0x32ae, a
	ldb_d8 a, 0x33d5
	stb_d8 0x32a6, a
	ldb_d8 a, 0x33ea
	stb_d8 0x33ee, a
	ret

AccCh2_NoteOnEntry:
	calr AccCh2_CheckEligible
	bitda 0, 0x33e1
	jr z, AccCh2_NoteOnReturn
	ldb_d8 a, 0x32c4
	stb_d8 0x32cb, a
	ldb_d8 a, 0x32c8
	stb_d8 0x32cc, a
	ordi8 0x32f4, 4
	anddi8 0x32f4, 247
	ld xhl, 0x2d94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccBuf_WriteExtendedEvent

AccCh2_NoteOnReturn:
	ret

AccCh2_CheckEligible:
	anddi8 0x33e1, 254
	bitda 3, 0x33de
	jr z, AccCh2_CheckReturn
	bitda 3, 0x3362
	jr nz, AccCh2_CheckReturn
	bitda 2, 0x3307
	jr z, AccCh2_CheckReturn
	bitda 0, 0x3310
	jr z, AccCh2_CheckReturn
	bitda 0, 0xc5a0
	jr z, AccCh2_CheckReturn
	calr AccCh2_CheckOverlap
	cps a, 0
	jr nz, AccCh2_CheckReturn
	bitda 1, 0x3335
	jr nz, AccCh2_CheckReturn
	bitda 0, 0x347a
	jr nz, AccCh2_CheckReturn
	bitda 0, 0x33e8
	jr nz, AccCh2_CheckReturn
	ld xhl, 0x2d94
	call AccBuf_ComputeFillLevel
	cpdi16 0x3324, 16
	jr ugt, AccCh2_SetReady
	calr AccBuf_InitWithDefaults
	jr AccCh2_CheckReturn

AccCh2_SetReady:
	ordi8 0x33e1, 1

AccCh2_CheckReturn:
	ret

AccCh2_DTypeEntry:
	calr AccCh2_CheckEligible
	bitda 0, 0x33e1
	jr z, AccCh2_DTypeReturn
	ld xhl, 0x2d94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccBuf_Write3ByteEvent

AccCh2_DTypeReturn:
	ret

AccCh2_CheckOverlap:
	ldb a, 0x0
	bitda 2, 0x34cf
	jr z, AccCh2_OverlapReturn
	bitda 0, 0x379b
	jr z, AccCh2_OverlapReturn
	ldb a, 0x1

AccCh2_OverlapReturn:
	ret

AccCh2_ProcessNotes:
	call AccKbd1_TimingCheck
	bitda 0, 0x32f4
	jr nz, AccCh2_ProcessReturn
	calr AccCh2_ScanSlots
	calr AccCh2_DrainRingBuf
	calr AccCh2_InitProgChange
	ld xiy, 0x321e
	ld xix, 0x3237
	lds bc, 5
	ldir85
	ldb_d8 a, 0x343c
	stb_d8 0x32ec, a
	call AccVoice_LoadRhythmParams_Part3
	anddi8 0x332c, 247

AccCh2_ProcessReturn:
	ret

AccCh2_ScanSlots:
	ld xhl, 0x313c

AccCh2_ScanSlots_Loop:
	call AccSlot_CheckAndUpdate
	add xhl, 0x9
	cp xhl, 0x3184
	jr c, AccCh2_ScanSlots_Loop
	ret

AccCh2_DrainRingBuf:
	ld xhl, 0x2d94
	ld iy, (xhl + 6)
	ld bc, (xhl + 2)

AccCh2_DrainLoop:
	cp (xhl + 4), iy
	jr z, AccCh2_DrainDone
	ldb_sri A, 0x07, 0xec, 0xf4
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
	anddi8 0x32f4, 252
	stdi8 0x32ed, 0
	ldb a, 0x10
	stb_d8 0x33d4, a
	ldw_d16 xwa, 0x329f
	stda16 0x33d6, xwa
	ldw_d16 xwa, 0x328f
	stda16 0x33d8, xwa
	ldb_d8 a, 0x32b9
	stb_d8 0x33da, a
	ldb_d8 a, 0x32af
	stb_d8 0x33db, a
	ldb_d8 a, 0x32a7
	stb_d8 0x33d5, a
	ldb_d8 a, 0x33ef
	stb_d8 0x33ea, a
	ret

AccCh3_RestoreState:
	ldw_d16 xwa, 0x33d6
	stda16 0x329f, xwa
	ldw_d16 xwa, 0x33d8
	stda16 0x328f, xwa
	ldb_d8 a, 0x33da
	stb_d8 0x32b9, a
	ldb_d8 a, 0x33db
	stb_d8 0x32af, a
	ldb_d8 a, 0x33d5
	stb_d8 0x32a7, a
	ldb_d8 a, 0x33ea
	stb_d8 0x33ef, a
	ret

AccCh3_NoteOnEntry:
	calr AccCh3_CheckEligible
	bitda 0, 0x33e1
	jr z, AccCh3_NoteOnReturn
	ldb_d8 a, 0x32c5
	stb_d8 0x32cb, a
	ldb_d8 a, 0x32c9
	stb_d8 0x32cc, a
	anddi8 0x32f4, 251
	anddi8 0x32f4, 247
	ld xhl, 0x2e94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccBuf_WriteExtendedEvent

AccCh3_NoteOnReturn:
	ret

AccCh3_CheckEligible:
	anddi8 0x33e1, 254
	bitda 4, 0x33de
	jr z, AccCh3_CheckReturn
	bitda 4, 0x3362
	jr nz, AccCh3_CheckReturn
	bitda 3, 0x3307
	jr z, AccCh3_CheckReturn
	bitda 1, 0x3310
	jr z, AccCh3_CheckReturn
	bitda 1, 0xc5a0
	jr z, AccCh3_CheckReturn
	calr AccCh3_CheckOverlap
	cps a, 0
	jr nz, AccCh3_CheckReturn
	bitda 1, 0x3335
	jr nz, AccCh3_CheckReturn
	bitda 0, 0x347a
	jr nz, AccCh3_CheckReturn
	bitda 0, 0x33e8
	jr nz, AccCh3_CheckReturn
	ld xhl, 0x2e94
	call AccBuf_ComputeFillLevel
	cpdi16 0x3324, 16
	jr ugt, AccCh3_SetReady
	calr AccBuf_InitWithDefaults
	jr AccCh3_CheckReturn

AccCh3_SetReady:
	ordi8 0x33e1, 1

AccCh3_CheckReturn:
	ret

AccCh3_DTypeEntry:
	calr AccCh3_CheckEligible
	bitda 0, 0x33e1
	jr z, AccCh3_DTypeReturn
	ld xhl, 0x2e94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccBuf_Write3ByteEvent

AccCh3_DTypeReturn:
	ret

AccCh3_CheckOverlap:
	ldb a, 0x0
	bitda 2, 0x34cf
	jr z, AccCh3_OverlapReturn
	bitda 1, 0x379b
	jr z, AccCh3_OverlapReturn
	ldb a, 0x1

AccCh3_OverlapReturn:
	ret

AccCh3_ProcessNotes:
	call AccKbd1_TimingCheck
	bitda 0, 0x32f4
	jr nz, AccCh3_ProcessReturn
	calr AccCh3_ScanSlots
	calr AccCh3_DrainRingBuf
	calr AccCh3_InitProgChange
	ld xiy, 0x3223
	ld xix, 0x323c
	lds bc, 5
	ldir85
	ldb_d8 a, 0x343c
	stb_d8 0x32ec, a
	call AccVoice_LoadRhythmParams_Part4
	anddi8 0x332c, 239

AccCh3_ProcessReturn:
	ret

AccCh3_ScanSlots:
	ld xhl, 0x3184

AccCh3_ScanSlots_Loop:
	call AccSlot_CheckAndUpdate
	add xhl, 0x9
	cp xhl, 0x31cc
	jr c, AccCh3_ScanSlots_Loop
	ret

AccCh3_DrainRingBuf:
	ld xhl, 0x2e94
	ld iy, (xhl + 6)
	ld bc, (xhl + 2)

AccCh3_DrainLoop:
	cp (xhl + 4), iy
	jr z, AccCh3_DrainDone
	ldb_sri A, 0x07, 0xec, 0xf4
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
	anddi8 0x32f4, 252
	stdi8 0x32ed, 0
	ldb a, 0x20
	stb_d8 0x33d4, a
	ldw_d16 xwa, 0x32a1
	stda16 0x33d6, xwa
	ldw_d16 xwa, 0x3291
	stda16 0x33d8, xwa
	ldb_d8 a, 0x32ba
	stb_d8 0x33da, a
	ldb_d8 a, 0x32b0
	stb_d8 0x33db, a
	ldb_d8 a, 0x32a8
	stb_d8 0x33d5, a
	ldb_d8 a, 0x33f0
	stb_d8 0x33ea, a
	ret

AccCh4_RestoreState:
	ldw_d16 xwa, 0x33d6
	stda16 0x32a1, xwa
	ldw_d16 xwa, 0x33d8
	stda16 0x3291, xwa
	ldb_d8 a, 0x33da
	stb_d8 0x32ba, a
	ldb_d8 a, 0x33db
	stb_d8 0x32b0, a
	ldb_d8 a, 0x33d5
	stb_d8 0x32a8, a
	ldb_d8 a, 0x33ea
	stb_d8 0x33f0, a
	ret

AccCh4_NoteOnEntry:
	calr AccCh4_CheckEligible
	bitda 0, 0x33e1
	jr z, AccCh4_NoteOnReturn
	ldb_d8 a, 0x32c6
	stb_d8 0x32cb, a
	ldb_d8 a, 0x32ca
	stb_d8 0x32cc, a
	anddi8 0x32f4, 251
	anddi8 0x32f4, 247
	ld xhl, 0x2f94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccBuf_WriteExtendedEvent

AccCh4_NoteOnReturn:
	ret

AccCh4_CheckEligible:
	anddi8 0x33e1, 254
	bitda 5, 0x33de
	jr z, AccCh4_CheckReturn
	bitda 5, 0x3362
	jr nz, AccCh4_CheckReturn
	bitda 4, 0x3307
	jr z, AccCh4_CheckReturn
	bitda 2, 0x3310
	jr z, AccCh4_CheckReturn
	bitda 2, 0xc5a0
	jr z, AccCh4_CheckReturn
	calr AccCh4_CheckOverlap
	cps a, 0
	jr nz, AccCh4_CheckReturn
	bitda 1, 0x3335
	jr nz, AccCh4_CheckReturn
	bitda 0, 0x347a
	jr nz, AccCh4_CheckReturn
	bitda 0, 0x33e8
	jr nz, AccCh4_CheckReturn
	ld xhl, 0x2f94
	call AccBuf_ComputeFillLevel
	cpdi16 0x3324, 16
	jr ugt, AccCh4_SetReady
	calr AccBuf_InitWithDefaults
	jr AccCh4_CheckReturn

AccCh4_SetReady:
	ordi8 0x33e1, 1

AccCh4_CheckReturn:
	ret

AccCh4_DTypeEntry:
	calr AccCh4_CheckEligible
	bitda 0, 0x33e1
	jr z, AccCh4_DTypeReturn
	ld xhl, 0x2f94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccBuf_Write3ByteEvent

AccCh4_DTypeReturn:
	ret

AccCh4_CheckOverlap:
	ldb a, 0x0
	bitda 2, 0x34cf
	jr z, AccCh4_OverlapReturn
	bitda 2, 0x379b
	jr z, AccCh4_OverlapReturn
	ldb a, 0x1

AccCh4_OverlapReturn:
	ret

AccCh4_ProcessNotes:
	call AccKbd1_TimingCheck
	bitda 0, 0x32f4
	jr nz, AccCh4_ProcessReturn
	calr AccCh4_ScanSlots
	calr AccCh4_DrainRingBuf
	calr AccCh4_InitProgChange
	ld xiy, 0x3228
	ld xix, 0x3241
	lds bc, 5
	ldir85
	ldb_d8 a, 0x343c
	stb_d8 0x32ec, a
	call AccVoice_LoadRhythmParams_Part5
	anddi8 0x332c, 223

AccCh4_ProcessReturn:
	ret

AccCh4_ScanSlots:
	ld xhl, 0x31cc

AccCh4_ScanSlots_Loop:
	call AccSlot_CheckAndUpdate
	add xhl, 0x9
	cp xhl, 0x3214
	jr c, AccCh4_ScanSlots_Loop
	ret

AccCh4_DrainRingBuf:
	ld xhl, 0x2f94
	ld iy, (xhl + 6)
	ld bc, (xhl + 2)

AccCh4_DrainLoop:
	cp (xhl + 4), iy
	jr z, AccCh4_DrainDone
	ldb_sri A, 0x07, 0xec, 0xf4
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
	ld xhl, 0x2c94
	calr AccBuf_WriteD0Defaults
	ret

AccCh2_InitProgChange:
	ld xhl, 0x2d94
	calr AccBuf_WriteD0Defaults
	ret

AccCh3_InitProgChange:
	ld xhl, 0x2e94
	calr AccBuf_WriteD0Defaults
	ret

AccCh4_InitProgChange:
	ld xhl, 0x2f94
	calr AccBuf_WriteD0Defaults
	ret

AccBuf_WriteD0Defaults:
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	stdi8 0x342d, 208
	ldb_d8 a, 0x343c
	stb_d8 0x342e, a
	stdi8 0x342f, 2
	stdi8 0x3430, 64
	calr AccBuf_Write3ByteEvent
	ldb_d8 a, 0x343c
	stb_d8 0x342e, a
	stdi8 0x342f, 1
	stdi8 0x3430, 0
	calr AccBuf_Write3ByteEvent
	ldb_d8 a, 0x343c
	stb_d8 0x342e, a
	stdi8 0x342f, 3
	stdi8 0x3430, 0
	calr AccBuf_Write3ByteEvent
	ldb_d8 a, 0x343c
	stb_d8 0x342e, a
	stdi8 0x342f, 5
	stdi8 0x3430, 127
	calr AccBuf_Write3ByteEvent
	ret

AccPart_Deactivate:
	ldb_d8 a, 0x3470
	and a, 0xc0
	jr nz, AccPart_Deactivate_WithPedal
	ldb_d8 a, 0x33d4
	andda8 a, 0x3329
	jr z, AccPart_Deactivate_NoPedal

AccPart_Deactivate_WithPedal:
	calr AccPart_ResolveWithPedal
	ldb_d8 a, 0x33d4
	xor a, 0xff
	anddm8 0x3329, a
	jrl AccPart_DeactivateReturn

AccPart_Deactivate_NoPedal:
	ldb_d8 a, 0x3316
	orda8 a, 0x3317
	orda8 a, 0x3318
	andda8 a, 0x33d4
	jr nz, AccPart_Deactivate_ActiveNote
	bitda 0, 0x3301
	jr nz, AccPart_Deactivate_WithSync
	bitda 0, 0x330f
	jr nz, AccPart_Deactivate_SetDone
	jr AccPart_Deactivate_SendOff

AccPart_Deactivate_WithSync:
	anddi8 0x330e, 252
	ordi8 0x330e, 1
	ldb_d8 a, 0x33d4
	andda8 a, 0x3312
	jr z, AccPart_Deactivate_SetDone
	ordi8 0x330e, 2
	jr AccPart_Deactivate_SetDone

AccPart_Deactivate_ActiveNote:
	bitda 0, 0x330f
	jr z, AccPart_Deactivate_SendOff

AccPart_Deactivate_SetDone:
	ordi8 0x32f3, 128
	ordi8 0x32f4, 1
	jr AccPart_Deactivate_ClearMasks

AccPart_Deactivate_SendOff:
	calr AccPart_SelectSourceOrParam
	calr AccPart_ResolveStyleAddr

AccPart_Deactivate_ClearMasks:
	ldb_d8 a, 0x33d4
	xor a, 0xff
	anddm8 0x3312, a
	anddm8 0x3313, a
	anddm8 0x3316, a
	anddm8 0x3317, a
	anddm8 0x3318, a
	stdi8 0x33db, 0
	stdi8 0x33ea, 0

AccPart_DeactivateReturn:
	ret

AccPart_Reactivate:
	ldb_d8 a, 0x33d4
	andda8 a, 0x33e0
	jr z, AccPart_ReactivateReturn
	ldb_d8 a, 0x33d4
	ldb_d8 w, 0x3314
	orda8 w, 0x3315
	and w, a
	jr z, AccPart_Reactivate_Inactive
	orddm8 0x332a, a
	orddm8 0x3328, a
	stdi8 0x33d6, 254
	stdi8 0x33d8, 6
	jr AccPart_ReactivateReturn

AccPart_Reactivate_Inactive:
	ldb_d8 a, 0x33d4
	xor a, 0xff
	anddm8 0x3312, a
	anddm8 0x3313, a
	anddm8 0x3316, a
	anddm8 0x3317, a
	anddm8 0x3318, a
	anddm8 0x335d, a
	anddm8 0x3329, a
	stdi8 0x33ea, 0
	stdi8 0x33d6, 254
	stdi8 0x33d8, 6

AccPart_ReactivateReturn:
	ret

AccTick_Main:
	bitda 2, 0x3283
	jrl nz, AccTick_CheckCollect
	calr AccTempo_BarCompare
	bitda 6, 0x32f4
	jrl nz, AccTick_Return
	calr AccPedal_CheckCombined
	bitda 6, 0x32f4
	jrl nz, AccTick_Return
	call AccTuning_ApplyChange
	bitda 7, 0x332c
	jr z, AccTick_AfterSync
	call Rhythm_ProcessAllPartsAndLoad
	anddi8 0x332c, 127

AccTick_AfterSync:
	call AccVoice_ProcessAllSixParts
	bitda 5, 0x32f4
	jrl nz, AccTick_Return
	call AccKbd2_ProcessEntry
	call AccSeq_ScanPattern
	bitda 0, 0x347a
	jr nz, AccTick_ProcessAccChannels
	bitda 0, 0x3283
	jr z, AccTick_CheckNoteOn
	ldw_d16 xwa, 0xc596
	and wa, 0x200
	jr z, AccTick_CheckNoteOn

AccTick_ProcessAccChannels:
	call AccCh1_ProcessEntry
	call AccCh2_ProcessEntry
	call AccCh3_ProcessEntry
	call AccCh4_ProcessEntry

AccTick_CheckNoteOn:
	bitda 7, 0x32f3
	jr z, AccTick_CheckCollect
	anddi8 0x32f3, 127
	call AccTempo_CalcPosition
	bitda 0, 0x330e
	jr nz, AccTick_DispatchNoteOn
	bitda 0, 0x330f
	jr nz, AccTick_DispatchNoteOn
	bitda 0, 0x330d
	jr nz, AccTick_DispatchNoteOn
	bitda 0, 0x330c
	jr nz, AccTick_DispatchNoteOn
	ldb_d8 a, 0x3309
	and a, 0x3
	jr nz, AccTick_DispatchNoteOn
	ldb_d8 a, 0x330a
	and a, 0xd
	jr nz, AccTick_DispatchNoteOn
	ldb_d8 a, 0x330b
	and a, 0x3
	jr z, AccTick_FlushAndRepeat

AccTick_DispatchNoteOn:
	call AccFlags_Aggregate

AccTick_FlushAndRepeat:
	call AccNote_FlushAll
	jrl AccTick_AfterSync

AccTick_CheckCollect:
	bitda 2, 0x3283
	jr z, AccTick_Return
	call AccState_CollectAll

AccTick_Return:
	ret

AccVelocity_CurveTable:
	.byte 0x0d, 0x1a, 0x33, 0x4d, 0x66, 0x80, 0x9a, 0xb3
	.byte 0xcc, 0xe6, 0xff

AccVoice_InitPerChannel:
	cpdi8 0x33d4, 4
	jr nz, AccVoice_InitCh2
	calr AccVoice_InitCh1_D7
	jr AccVoice_InitReturn

AccVoice_InitCh2:
	cpdi8 0x33d4, 8
	jr nz, AccVoice_InitCh3
	calr AccVoice_InitCh2_D4
	jr AccVoice_InitReturn

AccVoice_InitCh3:
	cpdi8 0x33d4, 16
	jr nz, AccVoice_InitCh4
	calr AccVoice_InitCh3_D5
	jr AccVoice_InitReturn

AccVoice_InitCh4:
	cpdi8 0x33d4, 32
	jr nz, AccVoice_InitReturn
	calr AccVoice_InitCh4_D6

AccVoice_InitReturn:
	ret

AccVoice_InitCh1_D7:
	pushw hl
	push xiy
	ld xhl, 0x2c94
	calr AccBuf_DrainAndReset
	ldb a, 0xd7
	ldb w, 0x2
	ldb e, 0x40
	call Rhythm_Send3ByteMsg
	ldb a, 0xd7
	ldb w, 0x1
	ldb e, 0x0
	call Rhythm_Send3ByteMsg
	ldb a, 0xd7
	ldb w, 0x3
	ldb e, 0x0
	call Rhythm_Send3ByteMsg
	stdi8 0x332f, 0
	ldb a, 0xd7
	ldb w, 0x5
	ldb e, 0x7f
	call Rhythm_Send3ByteMsg
	pop xiy
	popw hl
	ret

AccBuf_WriteD0WithVoice:
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	stib_ind 0x07, 0xec, 0xf4, 0xd0
	call RingBuf_AdvanceIndex
	ldb_d8 a, 0x32ea
	stb_d8 0x342e, a
	call RhythmAccent_UpdateRingBufPosition
	stib_ind 0x07, 0xec, 0xf4, 0x03
	call RingBuf_AdvanceIndex
	ldb_d8 a, 0x3333
	lda_dri XBC, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	ld (xhl + 4), iy
	ret

AccVoice_InitCh2_D4:
	pushw hl
	push xiy
	ld xhl, 0x2d94
	calr AccBuf_DrainAndReset
	ldb a, 0xd4
	ldb w, 0x2
	ldb e, 0x40
	call Rhythm_Send3ByteMsg
	ldb a, 0xd4
	ldb w, 0x1
	ldb e, 0x0
	call Rhythm_Send3ByteMsg
	ldb a, 0xd4
	ldb w, 0x3
	ldb e, 0x0
	call Rhythm_Send3ByteMsg
	stdi8 0x3330, 0
	ldb a, 0xd4
	ldb w, 0x5
	ldb e, 0x7f
	call Rhythm_Send3ByteMsg
	pop xiy
	popw hl
	ret

AccVoice_InitCh3_D5:
	pushw hl
	push xiy
	ld xhl, 0x2e94
	calr AccBuf_DrainAndReset
	ldb a, 0xd5
	ldb w, 0x2
	ldb e, 0x40
	call Rhythm_Send3ByteMsg
	ldb a, 0xd5
	ldb w, 0x1
	ldb e, 0x0
	call Rhythm_Send3ByteMsg
	ldb a, 0xd5
	ldb w, 0x3
	ldb e, 0x0
	call Rhythm_Send3ByteMsg
	stdi8 0x3331, 0
	ldb a, 0xd5
	ldb w, 0x5
	ldb e, 0x7f
	call Rhythm_Send3ByteMsg
	pop xiy
	popw hl
	ret

AccVoice_InitCh4_D6:
	pushw hl
	push xiy
	ld xhl, 0x2f94
	calr AccBuf_DrainAndReset
	ldb a, 0xd6
	ldb w, 0x2
	ldb e, 0x40
	call Rhythm_Send3ByteMsg
	ldb a, 0xd6
	ldb w, 0x1
	ldb e, 0x0
	call Rhythm_Send3ByteMsg
	ldb a, 0xd6
	ldb w, 0x3
	ldb e, 0x0
	call Rhythm_Send3ByteMsg
	stdi8 0x3332, 0
	ldb a, 0xd6
	ldb w, 0x5
	ldb e, 0x7f
	call Rhythm_Send3ByteMsg
	pop xiy
	popw hl
	ret

AccPedal_CheckCombined:
	bitda 0, 0x330c
	jr nz, AccPedal_CheckFlags
	ldb_d8 a, 0x330b
	and a, 0x3
	jr z, AccPedal_CheckDirection

AccPedal_CheckFlags:
	ldb_d8 a, 0x3326
	and a, 0x3f
	jr z, AccPedal_TriggerReInit

AccPedal_CheckDirection:
	ldb_d8 a, 0x330a
	and a, 0xd
	jr nz, AccPedal_CheckCounter
	ldb_d8 a, 0x3309
	and a, 0x3
	jr z, AccPedal_CombinedReturn

AccPedal_CheckCounter:
	ldb_d8 a, 0x3327
	and a, 0x3f
	jr nz, AccPedal_CombinedReturn

AccPedal_TriggerReInit:
	calr AccInit_FullReInit

AccPedal_CombinedReturn:
	ret

AccTick_ByteData:
	call	Rhythm_SendNoteOnMax
	call	AccompVoice_BulkReadRegisters
	calr	3162
	call	Rhythm_SendChanPressure
	calr	3214
	ldb_d8	a, 0x3312
	orda8	a, 0x3313
	and	a, 63
	jr	z, 44
	bitda	0, 0x3301
	jr	z, 38
	ordi8	0x330c, 1
	ldb_d8	a, 0x3312
	and	a, 63
	jr	z, 13
	cpdi8	0x333a, 0
	jr	z, 17
	.byte 0xc1
	.ascii ":3ih"
	pushw	0x3ac1
	ldw	hl, 831
	jr	z, 4
	incdi8	1, 0x333a
	.byte 0xf1
	retd	0xc833
	jr	nz, 15
	.byte 0xf1
	incf
	ldw	hl, 0x66c8
	.byte 0x17
	ldb_d8	a, 0x3326
	and	a, 63
	jr	nz, 14
	calr	1022
	calr	1298
	ldb_d8	a, 1075
	stb_d8	1112, a
	ldb_d8	a, 0x330a
	and	a, 13
	jr	z, 3
	calr	1654
	ldb_d8	a, 0x3309
	and	a, 3
	jr	nz, 24
	.byte 0xf1
	jrl	f, -12748
	jr	z, 7
	.byte 0xc1
	push	51
	push	xiz
	.byte 0x01
	jr	11
	.byte 0xf1
	jrl	f, -12492
	jr	z, 8
	.byte 0xc1
	push	51
	push	xiz
	push	sr
	calr	2118
	ldb_d8	a, 0x330b
	and	a, 3
	jr	z, 10
	calr	3222
	call	AccInit_ResetSongCounter
	calr	2665
	.byte 0xc1, 0xab
	ldw	de, 0xf03c
	.byte 0xc1, 0xac
	ldw	de, 0xf03c
	.byte 0xc1, 0xad
	ldw	de, 0xf03c
	.byte 0xc1, 0xae
	ldw	de, 0xf03c
	.byte 0xc1, 0xaf
	ldw	de, 0xf03c
	.byte 0xc1
	lda	xde, (xwa)
	push	xix
	.byte 0xf0
	calr	100
	.byte 0xf1, 0xf4
	ldw	de, 0x6ece
	pop	sr
	calr	569
	.byte 0xc1
	pushw	ix
	ldw	hl, 0x803e
	ret

AccTempo_BarCompare:
	ldb_d8 w, 0x32b5
	cpda8 w, 0x32b4
	jr c, AccTempo_BarLess
	jr z, AccTempo_BarEqual
	jr ugt, AccTempo_BarGreater

AccTempo_BarLess:
	cps w, 0
	jr nz, AccTempo_BarChanged
	cpdi8 0x32b4, 255
	jr nz, AccTempo_BarChanged
	jr AccTempo_ComputeSubDelta

AccTempo_BarEqual:
	ldw_d16 xwa, 0x32e3
	cpdm8 0x3280, w
	jr c, AccTempo_ComputeSubDelta
	jr ugt, AccTempo_BarChanged
	cpdm8 0x327f, a
	jr ule, AccTempo_ComputeSubDelta
	jr AccTempo_BarChanged

AccTempo_BarGreater:
	cp w, 0xff
	jr nz, AccTempo_ComputeSubDelta
	cpdi8 0x32b4, 0
	jr nz, AccTempo_ComputeSubDelta

AccTempo_BarChanged:
	ldb a, 0x1
	jr AccTempo_StoreDelta

AccTempo_ComputeSubDelta:
	ldw_d16 xwa, 0x32e3
	subda8 a, 0x327f
	jr nc, AccTempo_StoreDelta
	add a, 0x60

AccTempo_StoreDelta:
	stb_d8 0x32ea, a
	stb_d8 0x32ec, a
	ret

AccSeq_DualPartScan:
	ldw_d16 xde, 0x32e3
	stdi8 0x32ee, 0
	stdi8 0x3333, 0
	ldw_d16 xwa, 0x3287
	stda16 0x33d8, xwa
	ldb_d8 a, 0x32ab
	stb_d8 0x33db, a
	ldw_d16 xiz, 0x3297
	stda16 0x33d6, xiz
	ldb w, 0x1
	calr AccVoice_SelectByMask
	calr AccSeq_PatternScanner
	ldw_d16 xwa, 0x33d6
	stda16 0x3297, xwa
	ldb_d8 a, 0x33db
	stb_d8 0x32ab, a
	ldw_d16 xwa, 0x33d8
	stda16 0x3287, xwa
	bitda 6, 0x32f4
	jr nz, AccSeq_DualPartReturn
	ldw_d16 xde, 0x32e3
	stdi8 0x32ee, 0
	stdi8 0x3333, 0
	ldw_d16 xwa, 0x3289
	stda16 0x33d8, xwa
	ldb_d8 a, 0x32ac
	stb_d8 0x33db, a
	ldw_d16 xiz, 0x3299
	stda16 0x33d6, xiz
	ldb w, 0x2
	calr AccVoice_SelectByMask
	calr AccSeq_PatternScanner
	ldw_d16 xwa, 0x33d6
	stda16 0x3299, xwa
	ldb_d8 a, 0x33db
	stb_d8 0x32ac, a
	ldw_d16 xwa, 0x33d8
	stda16 0x3289, xwa

AccSeq_DualPartReturn:
	ret

AccSeq_PatternScanner:
	ldw_d16 xiy, 0x33d8
	ldw_d16 xiz, 0x33d6
	anddi8 0x32f4, 254
	xor bc, bc

AccSeq_ScannerLoop:
	bitda 0, 0x32f4
	jrl nz, AccSeq_Scanner_Done
	ldb_sri A, 0x07, 0xec, 0xf4
	cp a, 0x81
	jr nz, AccSeq_Scanner_EventType
	add b, 0x1
	xor c, c
	cp de, bc
	jr nc, AccSeq_Scanner_BarEnd
	ordi8 0x32f4, 1
	jr AccSeq_ScannerLoop

AccSeq_Scanner_BarEnd:
	ldb_d8 a, 0x33db
	inc 1, a
	ld w, a
	and a, 0xf
	cpda8 a, 1075
	jr nz, AccSeq_Scanner_StorePos
	and w, 0xf0
	add w, 0x10

AccSeq_Scanner_StorePos:
	stb_d8 0x33db, w
	calr AccBuf_Advance
	jr AccSeq_ScannerLoop

AccSeq_Scanner_EventType:
	cp a, 0x90
	jr z, AccSeq_Scanner_EventMatch
	cp a, 0x91
	jr z, AccSeq_Scanner_EventMatch
	cp a, 0xd1
	jr z, AccSeq_Scanner_EventMatch
	cp a, 0xd2
	jr z, AccSeq_Scanner_EventMatch
	cp a, 0xd3
	jr z, AccSeq_Scanner_EventMatch
	cp a, 0xd4
	jr z, AccSeq_Scanner_EventMatch
	cp a, 0xd5
	jr z, AccSeq_Scanner_EventMatch
	jr nz, AccSeq_Scanner_Unknown

AccSeq_Scanner_EventMatch:
	calr AccBuf_AdvanceWithPageTurn
	ld c, a
	cp de, bc
	jr nc, AccSeq_Scanner_SkipFields
	ordi8 0x32f4, 1
	jr AccSeq_ScannerLoop

AccSeq_Scanner_SkipFields:
	ldb_sri A, 0x07, 0xec, 0xf4
	cp a, 0xd3
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
	ldb_sri A, 0x07, 0xec, 0xf4
	stb_d8 0x3333, a
	calr AccBuf_Advance
	jrl AccSeq_ScannerLoop

AccSeq_Scanner_Unknown:
	incdi8 1, 0x32ee
	cpdi8 0x32ee, 32
	jr c, AccSeq_Scanner_Skip1
	call AccWrap_PlayModeDispatch
	call AccDemo_InitDone
	stdi8 0x32f5, 255
	ordi8 0x32f4, 65

AccSeq_Scanner_Skip1:
	calr AccBuf_Advance
	jrl AccSeq_ScannerLoop

AccSeq_Scanner_Done:
	stda16 0x33d6, xiz
	stda16 0x33d8, xiy
	ret

AccSeq_ScannerPadding:
	nop
	nop

AccBuf_AdvanceWithPageTurn:
	pushw iy
	inc 1, iy
	ldb_sri A, 0x07, 0xec, 0xf4
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
	ldb_sri A, 0x07, 0xec, 0xf4
	cp a, 0x87
	jr nz, AccBuf_AdvanceSimpleReturn
	ld hl, (xhl + 3)
	ld iz, hl
	calr AccWave_BankResolve
	lds iy, 6

AccBuf_AdvanceSimpleReturn:
	ret

AccSeq_FourChannelScan:
	ldw_d16 xde, 0x32e3
	stdi8 0x32ee, 0
	stdi8 0x3333, 0
	ldw_d16 xwa, 0x328b
	stda16 0x33d8, xwa
	ldb_d8 a, 0x32ad
	stb_d8 0x33db, a
	ldw_d16 xiz, 0x329b
	stda16 0x33d6, xiz
	ldb w, 0x4
	calr AccVoice_SelectByMask
	calr AccSeq_PatternScanner
	ldw_d16 xwa, 0x33d6
	stda16 0x329b, xwa
	ldb_d8 a, 0x33db
	stb_d8 0x32ad, a
	ldw_d16 xwa, 0x33d8
	stda16 0x328b, xwa
	ld xhl, 0x2c94
	calr AccBuf_WriteD0WithVoice
	bitda 6, 0x32f4
	jrl nz, AccSeq_FourChannelReturn
	ldw_d16 xde, 0x32e3
	stdi8 0x32ee, 0
	stdi8 0x3333, 0
	ldw_d16 xwa, 0x328d
	stda16 0x33d8, xwa
	ldb_d8 a, 0x32ae
	stb_d8 0x33db, a
	ldw_d16 xiz, 0x329d
	stda16 0x33d6, xiz
	ldb w, 0x8
	calr AccVoice_SelectByMask
	calr AccSeq_PatternScanner
	ldw_d16 xwa, 0x33d6
	stda16 0x329d, xwa
	ldb_d8 a, 0x33db
	stb_d8 0x32ae, a
	ldw_d16 xwa, 0x33d8
	stda16 0x328d, xwa
	ld xhl, 0x2d94
	calr AccBuf_WriteD0WithVoice
	bitda 6, 0x32f4
	jrl nz, AccSeq_FourChannelReturn
	ldw_d16 xde, 0x32e3
	stdi8 0x32ee, 0
	stdi8 0x3333, 0
	ldw_d16 xwa, 0x328f
	stda16 0x33d8, xwa
	ldb_d8 a, 0x32af
	stb_d8 0x33db, a
	ldw_d16 xiz, 0x329f
	stda16 0x33d6, xiz
	ldb w, 0x10
	calr AccVoice_SelectByMask
	calr AccSeq_PatternScanner
	ldw_d16 xwa, 0x33d6
	stda16 0x329f, xwa
	ldb_d8 a, 0x33db
	stb_d8 0x32af, a
	ldw_d16 xwa, 0x33d8
	stda16 0x328f, xwa
	ld xhl, 0x2e94
	calr AccBuf_WriteD0WithVoice
	bitda 6, 0x32f4
	jr nz, AccSeq_FourChannelReturn
	ldw_d16 xde, 0x32e3
	stdi8 0x32ee, 0
	stdi8 0x3333, 0
	ldw_d16 xwa, 0x3291
	stda16 0x33d8, xwa
	ldb_d8 a, 0x32b0
	stb_d8 0x33db, a
	ldw_d16 xiz, 0x32a1
	stda16 0x33d6, xiz
	ldb w, 0x20
	calr AccVoice_SelectByMask
	calr AccSeq_PatternScanner
	ldw_d16 xwa, 0x33d6
	stda16 0x32a1, xwa
	ldb_d8 a, 0x33db
	stb_d8 0x32b0, a
	ldw_d16 xwa, 0x33d8
	stda16 0x3291, xwa
	ld xhl, 0x2f94
	calr AccBuf_WriteD0WithVoice

AccSeq_FourChannelReturn:
	ret

AccStyle_Init:
	ldb_d8 a, 0x32e8
	and a, 0x7f
	and a, 0x7
	stb_d8 0x32e6, a
	ldb_d8 a, 0x32e7
	stb_d8 0x32e5, a
	call AccTuning_Init
	cpdi8 0x32e5, 128
	jr nc, AccStyle_ExtendedInit
	ldb_d8 a, 0x333a
	and a, 0x3
	stb_d8 0x3338, a
	ldb_d8 a, 0x32e5
	ldb_d8 h, 0x32e6
	call AccVoice_LookupWithOffset
	stda32 0x32ce, xiy
	call Rhythm_UpdateTuningConfig
	ldb_d8 a, 0x32a3
	ldb w, 0x0
	call AccPart_GetVoiceParamOffsetTable
	call AccVoice_LoadTuningBlock
	ordi8 0x332c, 63
	jr AccStyle_Finalize

AccStyle_ExtendedInit:
	ld xiy, Display_FontPalette_Table_0x1DA1
	ldb_d8 a, 0x32e5
	and a, 0x7f
	cp a, 0x1d
	jr ule, AccStyle_LookupTable
	xor a, a

AccStyle_LookupTable:
	ldb_sri A, 0x03, 0xf4, 0xe0
	stb_d8 0x3338, a
	ldb_d8 a, 0x32e5
	and a, 0x7f
	call AccVoice_ResolveParamAddr
	stda32 0x32ce, xiy
	ld l, (xiy + 16)
	ld h, (xiy + 17)
	and h, 0xf
	and a, 0x7
	cp hl, 0x208
	jr z, AccStyle_LoadAndApply
	cp hl, 0x318
	jr z, AccStyle_LoadAndApply
	call VoiceParam_ClampAndValidate

AccStyle_LoadAndApply:
	ld a, l
	call AccVoice_LookupWithOffset
	stda32 0x32d3, xiy
	call Rhythm_UpdateTuningConfig
	ldda32 xiy, 0x32ce
	call AccTuning_CopyAllPartsFromStyle
	ordi8 0x332c, 63
	ldb_d8 w, 0x32e5
	call AccPatch_SetByChordIndex

AccStyle_Finalize:
	call AccVoice_SelectAndApplyPatch
	jr AccInit_ClearAllFlags

AccInit_ClearAllFlags:
	anddi8 0x330c, 254
	anddi8 0x330d, 254
	anddi8 0x330e, 252
	xor a, a
	stb_d8 0x3316, a
	stb_d8 0x3317, a
	stb_d8 0x3318, a
	stb_d8 0x3312, a
	stb_d8 0x3313, a
	stb_d8 0x3314, a
	stb_d8 0x3315, a
	stb_d8 0x335d, a
	stb_d8 0x334d, a
	stb_d8 0x32bd, a
	stb_d8 0x32be, a
	stb_d8 0x32bf, a
	stb_d8 0x32c0, a
	stb_d8 0x32c1, a
	stb_d8 0x32c2, a
	call AccTone_CallWithSaveAll
	ret

AccVoice_SetupAllParts:
	cpdi8 0x32e5, 128
	jr c, AccVoice_SetupAll_Extended
	ldda32 xiy, 0x32ce
	jr AccVoice_SetupAll_Dispatch

AccVoice_SetupAll_Extended:
	ldda32 xiy, 0x32ce
	ldb_sri0 A, (xiy + 0x03d1)
	stb_d8 0x3285, a

AccVoice_SetupAll_Dispatch:
	calr AccVoice_SetupKbd1
	calr AccVoice_SetupKbd2
	calr AccVoice_SetupAcc1
	calr AccVoice_SetupAcc2
	calr AccVoice_SetupAcc3
	calr AccVoice_SetupAcc4
	ret

AccVoice_SetupKbd1:
	anddi8 0x32ab, 15
	cpdi8 0x32e5, 128
	jr nc, AccVoice_SetupKbd1_Free
	stdi8 0x33d4, 1
	ldb_d8 a, 0x32a3
	call AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	stda16 0x3287, xwa
	jr AccVoice_SetupKbd1_Return

AccVoice_SetupKbd1_Free:
	stdi8 0x33d4, 1
	call AccPart_GetFreeVoiceAddr
	stda16 0x3297, xwa
	stdi16 0x3287, 6

AccVoice_SetupKbd1_Return:
	ret

AccVoice_SetupKbd2:
	anddi8 0x32ac, 15
	cpdi8 0x32e5, 128
	jr nc, AccVoice_SetupKbd2_Free
	stdi8 0x33d4, 2
	ldb_d8 a, 0x32a4
	call AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	stda16 0x3289, xwa
	jr AccVoice_SetupKbd2_Return

AccVoice_SetupKbd2_Free:
	stdi8 0x33d4, 2
	call AccPart_GetFreeVoiceAddr
	stda16 0x3299, xwa
	stdi16 0x3289, 6

AccVoice_SetupKbd2_Return:
	ret

AccVoice_SetupAcc1:
	anddi8 0x32ad, 15
	cpdi8 0x32e5, 128
	jr nc, AccVoice_SetupAcc1_Free
	stdi8 0x33d4, 4
	ldb_d8 a, 0x32a5
	call AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	stda16 0x328b, xwa
	jr AccVoice_SetupAcc1_Return

AccVoice_SetupAcc1_Free:
	stdi8 0x33d4, 4
	call AccPart_GetFreeVoiceAddr
	stda16 0x329b, xwa
	stdi16 0x328b, 6

AccVoice_SetupAcc1_Return:
	ret

AccVoice_SetupAcc2:
	anddi8 0x32ae, 15
	cpdi8 0x32e5, 128
	jr nc, AccVoice_SetupAcc2_Free
	stdi8 0x33d4, 8
	ldb_d8 a, 0x32a6
	call AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	stda16 0x328d, xwa
	jr AccVoice_SetupAcc2_Return

AccVoice_SetupAcc2_Free:
	stdi8 0x33d4, 8
	call AccPart_GetFreeVoiceAddr
	stda16 0x329d, xwa
	stdi16 0x328d, 6

AccVoice_SetupAcc2_Return:
	ret

AccVoice_SetupAcc3:
	anddi8 0x32af, 15
	cpdi8 0x32e5, 128
	jr nc, AccVoice_SetupAcc3_Free
	stdi8 0x33d4, 16
	ldb_d8 a, 0x32a7
	call AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	stda16 0x328f, xwa
	jr AccVoice_SetupAcc3_Return

AccVoice_SetupAcc3_Free:
	stdi8 0x33d4, 16
	call AccPart_GetFreeVoiceAddr
	stda16 0x329f, xwa
	stdi16 0x328f, 6

AccVoice_SetupAcc3_Return:
	ret

AccVoice_SetupAcc4:
	anddi8 0x32b0, 15
	cpdi8 0x32e5, 128
	jr nc, AccVoice_SetupAcc4_Free
	stdi8 0x33d4, 32
	ldb_d8 a, 0x32a8
	call AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	stda16 0x3291, xwa
	jrl AccVoice_SetupAcc4_Return

AccVoice_SetupAcc4_Free:
	stdi8 0x33d4, 32
	call AccPart_GetFreeVoiceAddr
	stda16 0x32a1, xwa
	stdi16 0x3291, 6

AccVoice_SetupAcc4_Return:
	ret

AccVoice_ResetAll:
	anddi8 0x32ab, 15
	anddi8 0x32ac, 15
	anddi8 0x32ad, 15
	anddi8 0x32ae, 15
	anddi8 0x32af, 15
	anddi8 0x32b0, 15
	cpdi8 0x32e5, 128
	jr c, AccVoice_Reset_UseStyle
	bitda 0, 0x3363
	jr z, AccVoice_Reset_UseSecondary
	calr AccVoice_Reassign
	jr AccVoice_Reset_SetMasks

AccVoice_Reset_UseSecondary:
	ldda32 xiy, 0x32d3
	jr AccVoice_Reset_SelectMode

AccVoice_Reset_UseStyle:
	ldda32 xiy, 0x32ce

AccVoice_Reset_SelectMode:
	ldw hl, 0x20
	bitda 0, 0x330a
	jr nz, AccVoice_Reset_LoadParams
	ldw hl, 0x22
	bitda 2, 0x330a
	jr nz, AccVoice_Reset_LoadParams
	ldw hl, 0x420

AccVoice_Reset_LoadParams:
	calr AccVoice_LoadAllParts
	cpdi8 0x32e5, 128
	jr c, AccVoice_Reset_Extended
	ldda32 xiy, 0x32ce
	call AccTuning_CopyAllPartsFromStyle
	jr AccVoice_Reset_ApplyAll

AccVoice_Reset_Extended:
	ldb_d8 a, 0x32a3
	ldb w, 0x3
	bitda 3, 0x330a
	jr z, AccVoice_Reset_SetMode
	ldb w, 0x4

AccVoice_Reset_SetMode:
	call AccPart_GetVoiceParamOffsetTable
	call AccVoice_LoadTuningBlock

AccVoice_Reset_ApplyAll:
	ordi8 0x332c, 63

AccVoice_Reset_SetMasks:
	bitda 3, 0x330a
	jrl nz, AccVoice_Reset_Mode3
	bitda 2, 0x330a
	jr nz, AccVoice_Reset_Mode2
	anddi8 0x330a, 254
	ordi8 0x3316, 63
	xor a, a
	stb_d8 0x3312, a
	stb_d8 0x3313, a
	stb_d8 0x3317, a
	stb_d8 0x3318, a
	stb_d8 0x3314, a
	stb_d8 0x3315, a
	stb_d8 0x335d, a
	stb_d8 0x3328, a
	stb_d8 0x332a, a
	anddi8 0x3283, 251
	jrl AccVoice_Reset_Return

AccVoice_Reset_Mode2:
	anddi8 0x330a, 251
	ordi8 0x3317, 63
	xor a, a
	stb_d8 0x3312, a
	stb_d8 0x3313, a
	stb_d8 0x3316, a
	stb_d8 0x3318, a
	stb_d8 0x3314, a
	stb_d8 0x3315, a
	stb_d8 0x335d, a
	stb_d8 0x3328, a
	stb_d8 0x332a, a
	anddi8 0x3283, 251
	jr AccVoice_Reset_Return

AccVoice_Reset_Mode3:
	anddi8 0x330a, 247
	ordi8 0x3318, 63
	xor a, a
	stb_d8 0x3312, a
	stb_d8 0x3313, a
	stb_d8 0x3316, a
	stb_d8 0x3317, a
	stb_d8 0x3314, a
	stb_d8 0x3315, a
	stb_d8 0x335d, a
	stb_d8 0x3328, a
	stb_d8 0x332a, a
	anddi8 0x3283, 251

AccVoice_Reset_Return:
	ret

AccVoice_Reassign:
	bitda 3, 0x330a
	jrl nz, AccVoice_Reassign_Mode3
	bitda 2, 0x330a
	jr nz, AccVoice_Reassign_Mode2
	ldb_d8 a, 0x32e5
	and a, 0x7f
	call AccPatch_SetVoiceParam
	cpda8 a, 0x3364
	jr z, AccVoice_Reassign_MatchA
	anddi8 0xfc5f, 251
	ldb e, 0x48
	ldb d, 0x5
	ldb w, 0x0
	ldb a, 0x0
	call Rhythm_QueuePartChangeEvent
	ldda32 xiy, 0x32ce
	jr AccVoice_Reassign_Apply

AccVoice_Reassign_MatchA:
	ldb_d8 a, 0x3365
	call AccVoice_ResolveParamAddr
	jr AccVoice_Reassign_Apply

AccVoice_Reassign_Mode2:
	ldb_d8 a, 0x32e5
	and a, 0x7f
	call AccPatch_SetVoiceParam
	ld xhl, Display_FontPalette_Table_0x1D58
	bit_dri 1, 0x03, 0xec, 0xe0
	jr z, AccVoice_Reassign_Fallback
	anddi8 0xfc5f, 247
	ldb e, 0x48
	ldb d, 0x5
	ldb w, 0x0
	ldb a, 0x0
	call Rhythm_QueuePartChangeEvent
	ldda32 xiy, 0x32ce
	jr AccVoice_Reassign_Apply

AccVoice_Reassign_Mode3:
	ldb_d8 a, 0x32e5
	and a, 0x7f
	call AccPatch_SetVoiceParam
	cpda8 a, 0x3366
	jr z, AccVoice_Reassign_MatchB
	anddi8 0xfc60, 251
	ldb e, 0x48
	ldb d, 0x6
	ldb w, 0x0
	ldb a, 0x0
	call Rhythm_QueuePartChangeEvent
	ldda32 xiy, 0x32ce
	jr AccVoice_Reassign_Apply

AccVoice_Reassign_MatchB:
	ldb_d8 a, 0x3367
	call AccVoice_ResolveParamAddr

AccVoice_Reassign_Apply:
	calr AccInit_AllPartPositions
	call AccTuning_CopyAllPartsFromStyle
	ordi8 0x332c, 63
	jr AccVoice_Reassign_Return

AccVoice_Reassign_Fallback:
	ldda32 xiy, 0x32d3
	ldw hl, 0x22
	calr AccVoice_LoadAllParts
	xor xhl, xhl
	ldw hl, 0x126
	call AccVoice_LoadTuningBlock
	ordi8 0x332c, 63

AccVoice_Reassign_Return:
	ret

AccVoice_SplitPointSetup:
	anddi8 0x32ab, 15
	anddi8 0x32ac, 15
	anddi8 0x32ad, 15
	anddi8 0x32ae, 15
	anddi8 0x32af, 15
	anddi8 0x32b0, 15
	cpdi8 0x32e5, 128
	jr c, AccVoice_Split_UseStyle
	bitda 0, 0x3363
	jr z, AccVoice_Split_UseSecondary
	calr AccVoice_SplitReassign
	jr AccVoice_Split_SetForward

AccVoice_Split_UseSecondary:
	ldda32 xiy, 0x32d3
	jr AccVoice_Split_LoadAndApply

AccVoice_Split_UseStyle:
	ldda32 xiy, 0x32ce

AccVoice_Split_LoadAndApply:
	ldb_d8 a, 0x32a3
	call AccVoice_ComputeParamAddr
	calr AccVoice_LoadAllParts
	ldb_d8 a, 0x32a3
	call AccTuning_SetAllFromLookup
	cpdi8 0x32e5, 128
	jr c, AccVoice_Split_StyleMode
	ldda32 xiy, 0x32ce
	call AccTuning_CopyAllPartsFromStyle
	jr AccVoice_Split_Apply63

AccVoice_Split_StyleMode:
	ldb_d8 a, 0x32a3
	ldb w, 0x2
	call AccPart_GetVoiceParamOffsetTable
	call AccVoice_LoadTuningBlock

AccVoice_Split_Apply63:
	ordi8 0x332c, 63

AccVoice_Split_SetForward:
	bitda 0, 0x3309
	jr z, AccVoice_Split_SetReverse
	anddi8 0x3309, 254
	ordi8 0x3312, 63
	xor a, a
	stb_d8 0x3316, a
	stb_d8 0x3317, a
	stb_d8 0x3318, a
	stb_d8 0x3313, a
	stb_d8 0x3314, a
	stb_d8 0x3315, a
	stb_d8 0x335d, a
	stb_d8 0x3328, a
	stb_d8 0x332a, a
	anddi8 0x3283, 251
	jr AccVoice_Split_Return

AccVoice_Split_SetReverse:
	anddi8 0x3309, 253
	ordi8 0x3313, 63
	xor a, a
	stb_d8 0x3316, a
	stb_d8 0x3317, a
	stb_d8 0x3318, a
	stb_d8 0x3312, a
	stb_d8 0x3314, a
	stb_d8 0x3315, a
	stb_d8 0x335d, a
	stb_d8 0x3328, a
	stb_d8 0x332a, a
	anddi8 0x3283, 251

AccVoice_Split_Return:
	ret

AccVoice_SplitReassign:
	bitda 0, 0x3309
	jr z, AccVoice_SplitReassign_Reverse
	ldb_d8 a, 0x32e5
	and a, 0x7f
	call AccPatch_SetVoiceParam
	cpda8 a, 0x3368
	jr z, AccVoice_SplitReassign_MatchFwd
	anddi8 0xfc5f, 191
	ldb e, 0x48
	ldb d, 0x5
	ldb w, 0x0
	ldb a, 0x0
	call Rhythm_QueuePartChangeEvent
	ldda32 xiy, 0x32ce
	jr AccVoice_SplitReassign_Apply

AccVoice_SplitReassign_MatchFwd:
	ldb_d8 a, 0x3369
	call AccVoice_ResolveParamAddr
	jr AccVoice_SplitReassign_Apply

AccVoice_SplitReassign_Reverse:
	ldb_d8 a, 0x32e5
	and a, 0x7f
	call AccPatch_SetVoiceParam
	cpda8 a, 0x336a
	jr z, AccVoice_SplitReassign_MatchRev
	anddi8 0xfc5f, 127
	ldb e, 0x48
	ldb d, 0x5
	ldb w, 0x0
	ldb a, 0x0
	call Rhythm_QueuePartChangeEvent
	ldda32 xiy, 0x32ce
	jr AccVoice_SplitReassign_Apply

AccVoice_SplitReassign_MatchRev:
	ldb_d8 a, 0x336b
	call AccVoice_ResolveParamAddr

AccVoice_SplitReassign_Apply:
	calr AccInit_AllPartPositions
	call AccTuning_CopyAllPartsFromStyle
	ordi8 0x332c, 63
	ret

AccVoice_LoadAllParts:
	ldb_sri0 A, (xiy + 0x03d1)
	stb_d8 0x3285, a
	ldw_erp HL, 0x3c
	stdi8 0x33d4, 1
	call AccPart_GetParamAddr
	stda16 0x3287, xwa
	stw_erp HL, 0x3c
	stdi8 0x33d4, 2
	call AccPart_GetParamAddr
	stda16 0x3289, xwa
	stw_erp HL, 0x3c
	stdi8 0x33d4, 4
	call AccPart_GetParamAddr
	stda16 0x328b, xwa
	stw_erp HL, 0x3c
	stdi8 0x33d4, 8
	call AccPart_GetParamAddr
	stda16 0x328d, xwa
	stw_erp HL, 0x3c
	stdi8 0x33d4, 16
	call AccPart_GetParamAddr
	stda16 0x328f, xwa
	stw_erp HL, 0x3c
	stdi8 0x33d4, 32
	call AccPart_GetParamAddr
	stda16 0x3291, xwa
	ret

AccInit_AllPartPositions:
	stdi8 0x33d4, 1
	call AccPart_GetFreeVoiceAddr
	stda16 0x3297, xwa
	stdi16 0x3287, 6
	stdi8 0x33d4, 4
	call AccPart_GetFreeVoiceAddr
	stda16 0x329b, xwa
	stdi16 0x328b, 6
	stdi8 0x33d4, 8
	call AccPart_GetFreeVoiceAddr
	stda16 0x329d, xwa
	stdi16 0x328d, 6
	stdi8 0x33d4, 16
	call AccPart_GetFreeVoiceAddr
	stda16 0x329f, xwa
	stdi16 0x328f, 6
	stdi8 0x33d4, 32
	call AccPart_GetFreeVoiceAddr
	stda16 0x32a1, xwa
	stdi16 0x3291, 6
	stdi8 0x33d4, 2
	call AccPart_GetFreeVoiceAddr
	stda16 0x3299, xwa
	stdi16 0x3289, 6
	ret

AccVoice_ThirdLayer:
	anddi8 0x32ab, 15
	anddi8 0x32ac, 15
	anddi8 0x32ad, 15
	anddi8 0x32ae, 15
	anddi8 0x32af, 15
	anddi8 0x32b0, 15
	cpdi8 0x32e5, 128
	jr c, AccVoice_ThirdLayer_Style
	bitda 0, 0x3363
	jr z, AccVoice_ThirdLayer_Secondary
	calr AccVoice_ThirdLayerReassign
	jr AccVoice_ThirdLayer_SetMasks

AccVoice_ThirdLayer_Secondary:
	ldda32 xiy, 0x32d3
	jr AccVoice_ThirdLayer_SelectMode

AccVoice_ThirdLayer_Style:
	ldda32 xiy, 0x32ce

AccVoice_ThirdLayer_SelectMode:
	ldw hl, 0x24
	bitda 0, 0x330b
	jr nz, AccVoice_ThirdLayer_LoadParams
	ldw hl, 0x424

AccVoice_ThirdLayer_LoadParams:
	calr AccVoice_LoadAllParts
	ldb_d8 a, 0x32a3
	call AccTuning_SetAllFromLookup
	cpdi8 0x32e5, 128
	jr c, AccVoice_ThirdLayer_StyleMode
	ldda32 xiy, 0x32ce
	call AccTuning_CopyAllPartsFromStyle
	jr AccVoice_ThirdLayer_Apply

AccVoice_ThirdLayer_StyleMode:
	ldb_d8 a, 0x32a3
	ldb w, 0x5
	bitda 1, 0x330b
	jr z, AccVoice_ThirdLayer_SetModeW
	ldb w, 0x6

AccVoice_ThirdLayer_SetModeW:
	call AccPart_GetVoiceParamOffsetTable
	call AccVoice_LoadTuningBlock

AccVoice_ThirdLayer_Apply:
	ordi8 0x332c, 63

AccVoice_ThirdLayer_SetMasks:
	bitda 0, 0x330b
	jr z, AccVoice_ThirdLayer_Reverse
	anddi8 0x330b, 254
	ordi8 0x3314, 63
	xor a, a
	stb_d8 0x3316, a
	stb_d8 0x3317, a
	stb_d8 0x3318, a
	stb_d8 0x3312, a
	stb_d8 0x3313, a
	stb_d8 0x3315, a
	stb_d8 0x335d, a
	jr AccVoice_ThirdLayer_Return

AccVoice_ThirdLayer_Reverse:
	anddi8 0x330b, 253
	ordi8 0x3315, 63
	xor a, a
	stb_d8 0x3316, a
	stb_d8 0x3317, a
	stb_d8 0x3318, a
	stb_d8 0x3312, a
	stb_d8 0x3313, a
	stb_d8 0x3314, a
	stb_d8 0x335d, a

AccVoice_ThirdLayer_Return:
	ret

AccVoice_ThirdLayerReassign:
	bitda 0, 0x330b
	jr z, AccVoice_ThirdReassign_Reverse
	ldb_d8 a, 0x32e5
	and a, 0x7f
	call AccPatch_SetVoiceParam
	cpda8 a, 0x336c
	jr z, AccVoice_ThirdReassign_MatchFwd
	anddi8 0xfc5f, 239
	ldb e, 0x48
	ldb d, 0x5
	ldb w, 0x0
	ldb a, 0x0
	call Rhythm_QueuePartChangeEvent
	ldda32 xiy, 0x32ce
	jr AccVoice_ThirdReassign_Apply

AccVoice_ThirdReassign_MatchFwd:
	ldb_d8 a, 0x336d
	call AccVoice_ResolveParamAddr
	jr AccVoice_ThirdReassign_Apply

AccVoice_ThirdReassign_Reverse:
	ldb_d8 a, 0x32e5
	and a, 0x7f
	call AccPatch_SetVoiceParam
	cpda8 a, 0x336e
	jr z, AccVoice_ThirdReassign_MatchRev
	anddi8 0xfc5f, 223
	ldb e, 0x48
	ldb d, 0x5
	ldb w, 0x0
	ldb a, 0x0
	call Rhythm_QueuePartChangeEvent
	ldda32 xiy, 0x32ce
	jr AccVoice_ThirdReassign_Apply

AccVoice_ThirdReassign_MatchRev:
	ldb_d8 a, 0x336f
	call AccVoice_ResolveParamAddr

AccVoice_ThirdReassign_Apply:
	calr AccInit_AllPartPositions
	call AccTuning_CopyAllPartsFromStyle
	ordi8 0x332c, 63
	ret

AccBuf_WriteAllNotesOff:
	ld xhl, 0x2a94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	stib_ind 0x07, 0xec, 0xf4, 0x9f
	call RingBuf_AdvanceIndex
	ldb_d8 a, 0x32ea
	stb_d8 0x342e, a
	call RhythmAccent_UpdateRingBufPosition
	ldb a, 0x7f
	lda_dri XBC, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	lda_dri XBC, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	ld (xhl + 4), iy
	ret

AccBuf_AllNotesOffPadding:
	nop
	nop

AccBuf_ResetAll4:
	ld xhl, 0x2c94
	calr AccBuf_DrainAndReset
	ld xhl, 0x2d94
	calr AccBuf_DrainAndReset
	ld xhl, 0x2e94
	calr AccBuf_DrainAndReset
	ld xhl, 0x2f94
	calr AccBuf_DrainAndReset
	ret

AccBuf_DrainAndReset:
	ld iy, (xhl + 6)
	ld bc, (xhl + 2)

AccBuf_DrainReset_Loop:
	cp iy, (xhl + 4)
	jr z, AccBuf_DrainReset_Done
	ldb_sri A, 0x07, 0xec, 0xf4
	cp a, 0xd0
	jr z, AccBuf_DrainReset_D0Found
	call RingBuf_AdvanceIndex
	jr AccBuf_DrainReset_Loop

AccBuf_DrainReset_D0Found:
	call RingBuf_AdvanceIndex
	call RingBuf_AdvanceIndex
	ldb_sri A, 0x07, 0xec, 0xf4
	cps a, 2
	jr nz, AccBuf_DrainReset_Sub1
	call RingBuf_AdvanceIndex
	stib_ind 0x07, 0xec, 0xf4, 0x40
	call RingBuf_AdvanceIndex
	jr AccBuf_DrainReset_Loop

AccBuf_DrainReset_Sub1:
	cps a, 1
	jr nz, AccBuf_DrainReset_Sub3
	call RingBuf_AdvanceIndex
	stib_ind 0x07, 0xec, 0xf4, 0x00
	call RingBuf_AdvanceIndex
	jr AccBuf_DrainReset_Loop

AccBuf_DrainReset_Sub3:
	cps a, 3
	jr nz, AccBuf_DrainReset_Sub5
	call RingBuf_AdvanceIndex
	stib_ind 0x07, 0xec, 0xf4, 0x00
	call RingBuf_AdvanceIndex
	jr AccBuf_DrainReset_Loop

AccBuf_DrainReset_Sub5:
	cps a, 5
	jr nz, AccBuf_DrainReset_Other
	call RingBuf_AdvanceIndex
	stib_ind 0x07, 0xec, 0xf4, 0x7f
	call RingBuf_AdvanceIndex
	jr AccBuf_DrainReset_Loop

AccBuf_DrainReset_Other:
	call RingBuf_AdvanceIndex
	jr AccBuf_DrainReset_Loop

AccBuf_DrainReset_Done:
	ret

AccTiming_CallHelper:
	bitda 1, 0x3284
	jr z, AccTiming_HelperReturn
	call SeqEvt_CallTimingHelper
	call Voice_UpdatePlayModeState
	call AccChord_ReadAndStoreKeys
	call AccChord_CompareAndSetDirty
	call Rhythm_CompareAndTrigger

AccTiming_HelperReturn:
	ret

AccVoice_SelectByMask:
	cpdi8 0x32e5, 128
	jr c, AccVoice_SelectByMask_Default
	ldb_erp W, 0x31
	andda8 w, 0x3317
	jr nz, AccVoice_SelectByMask_Default
	bitda 0, 0x3363
	jr nz, AccVoice_SelectByMask_Direct
	ldb_d8 a, 0x3316
	orda8 a, 0x3318
	orda8 a, 0x3312
	orda8 a, 0x3313
	orda8 a, 0x3314
	orda8 a, 0x3315
	orda8 a, 0x3328
	andb_erp A, 0x31
	jr nz, AccVoice_SelectByMask_Default

AccVoice_SelectByMask_Direct:
	calr AccWave_BankResolve
	jr AccVoice_SelectReturn

AccVoice_SelectByMask_Default:
	ldb_d8 a, 0x3285
	call AccVoice_TableLookup

AccVoice_SelectReturn:
	ret

AccWave_BankResolve_Short:
	cp	iz, 0xfffe
	jr	nz, 7
	ld	xhl, 0x095bc0
	jr	13
	extz	xiz
	ld	xhl, xiz
	sla	xhl, 8
	add	xhl, 0x095c00
	ret

AccWave_BankResolve:
	push xwa
	push xix
	push xiz
	cp iz, 0xfffe
	jr nz, AccWave_BankResolve_Normal
	ld xhl, 0x95bc0
	jr AccWave_BankResolve_Epilogue

AccWave_BankResolve_Normal:
	ld wa, iz
	and iz, 0xfff
	extz xiz
	ld xhl, xiz
	sla xhl, 8
	srl wa, 10
	ld xix, AccWave_BankTable
	ld_sril3 XIX, 0x07, 0xf0, 0xe0
	add xhl, xix

AccWave_BankResolve_Epilogue:
	pop xiz
	pop xix
	pop xwa
	ret

AccWave_BankTable:
	.byte 0x00, 0x5c, 0x09, 0x00, 0x00, 0x14, 0x30, 0x00
	.byte 0x00, 0xac, 0x31, 0x00, 0x00, 0x14, 0x33, 0x00
	.byte 0x00, 0xac, 0x34, 0x00, 0x00, 0x14, 0x36, 0x00
	.byte 0x00, 0xac, 0x37, 0x00, 0x00, 0x14, 0x39, 0x00

AccVoice_TableLookup:
	call AccVoice_TableLookup_Inner
	add xhl, 0x8000
	ret

AccVoice_TableLookup_Inner:
	cp a, 0x3f
	jr ule, AccVoice_TableLookup_Compute
	xor a, a

AccVoice_TableLookup_Compute:
	xor xhl, xhl
	xor w, w
	ld hl, wa
	sll xhl, 2
	add xhl, AccVoice_OffsetTable
	ld xhl, (xhl)
	addda32 xhl, 0x3277
	ret

AccVoice_OffsetTable:
	.byte 0x00, 0x00, 0x40, 0x00, 0x00, 0x00, 0x41, 0x00
	.byte 0x00, 0x00, 0x42, 0x00, 0x00, 0x00, 0x43, 0x00
	.byte 0x00, 0x00, 0x44, 0x00, 0x00, 0x00, 0x45, 0x00
	.byte 0x00, 0x00, 0x46, 0x00, 0x00, 0x00, 0x47, 0x00
	.byte 0x00, 0x00, 0x48, 0x00, 0x00, 0x00, 0x49, 0x00
	.byte 0x00, 0x00, 0x4a, 0x00, 0x00, 0x00, 0x4b, 0x00
	.byte 0x00, 0x00, 0x4c, 0x00, 0x00, 0x00, 0x4d, 0x00
	.byte 0x00, 0x00, 0x4e, 0x00, 0x00, 0x00, 0x4f, 0x00
	.byte 0x00, 0x00, 0x50, 0x00, 0x00, 0x00, 0x51, 0x00
	.byte 0x00, 0x00, 0x52, 0x00, 0x00, 0x00, 0x53, 0x00
	.byte 0x00, 0x00, 0x54, 0x00, 0x00, 0x00, 0x55, 0x00
	.byte 0x00, 0x00, 0x56, 0x00, 0x00, 0x00, 0x57, 0x00
	.byte 0x00, 0x00, 0x58, 0x00, 0x00, 0x00, 0x59, 0x00
	.byte 0x00, 0x00, 0x5a, 0x00, 0x00, 0x00, 0x5b, 0x00
	.byte 0x00, 0x00, 0x5c, 0x00, 0x00, 0x00, 0x5d, 0x00
	.byte 0x00, 0x00, 0x5e, 0x00, 0x00, 0x00, 0x5f, 0x00
	.byte 0x00, 0x00, 0x60, 0x00, 0x00, 0x00, 0x61, 0x00
	.byte 0x00, 0x00, 0x62, 0x00, 0x00, 0x00, 0x63, 0x00
	.byte 0x00, 0x00, 0x64, 0x00, 0x00, 0x00, 0x65, 0x00
	.byte 0x00, 0x00, 0x66, 0x00, 0x00, 0x00, 0x67, 0x00
	.byte 0x00, 0x00, 0x68, 0x00, 0x00, 0x00, 0x69, 0x00
	.byte 0x00, 0x00, 0x6a, 0x00, 0x00, 0x00, 0x6b, 0x00
	.byte 0x00, 0x00, 0x6c, 0x00, 0x00, 0x00, 0x6d, 0x00
	.byte 0x00, 0x00, 0x6e, 0x00, 0x00, 0x00, 0x6f, 0x00
	.byte 0x00, 0x00, 0x70, 0x00, 0x00, 0x00, 0x71, 0x00
	.byte 0x00, 0x00, 0x72, 0x00, 0x00, 0x00, 0x73, 0x00
	.byte 0x00, 0x00, 0x74, 0x00, 0x00, 0x00, 0x75, 0x00
	.byte 0x00, 0x00, 0x76, 0x00, 0x00, 0x00, 0x77, 0x00
	.byte 0x00, 0x00, 0x78, 0x00, 0x00, 0x00, 0x79, 0x00
	.byte 0x00, 0x00, 0x7a, 0x00, 0x00, 0x00, 0x7b, 0x00
	.byte 0x00, 0x00, 0x7c, 0x00, 0x00, 0x00, 0x7d, 0x00
	.byte 0x00, 0x00, 0x7e, 0x00, 0x00, 0x00, 0x7f, 0x00

AccState_CollectAll:
	bitda 3, 1054
	jrl nz, AccState_CollectReturn
	bitda 2, 1054
	jrl z, AccState_CollectReturn
	ld xhl, 0x3094
	xor iy, iy
	ldb_sri A, 0x07, 0xec, 0xf4

AccState_CollectKbd1_Loop:
	or_srib_rm A, 0x07, 0xec, 0xf4
	add iy, 0x6
	cp iy, 0x30
	jr c, AccState_CollectKbd1_Loop
	ld xhl, 0x30c4
	xor iy, iy

AccState_CollectKbd2_Loop:
	or_srib_rm A, 0x07, 0xec, 0xf4
	add iy, 0x6
	cp iy, 0x30
	jr c, AccState_CollectKbd2_Loop
	ld xhl, 0x30f4
	xor iy, iy

AccState_CollectAcc1_Loop:
	or_srib_rm A, 0x07, 0xec, 0xf4
	add iy, 0x9
	cp iy, 0x48
	jr c, AccState_CollectAcc1_Loop
	ld xhl, 0x313c
	xor iy, iy

AccState_CollectAcc2_Loop:
	or_srib_rm A, 0x07, 0xec, 0xf4
	add iy, 0x9
	cp iy, 0x48
	jr c, AccState_CollectAcc2_Loop
	ld xhl, 0x3184
	xor iy, iy

AccState_CollectAcc3_Loop:
	or_srib_rm A, 0x07, 0xec, 0xf4
	add iy, 0x9
	cp iy, 0x48
	jr c, AccState_CollectAcc3_Loop
	ld xhl, 0x31cc
	xor iy, iy

AccState_CollectAcc4_Loop:
	or_srib_rm A, 0x07, 0xec, 0xf4
	add iy, 0x9
	cp iy, 0x48
	jr c, AccState_CollectAcc4_Loop
	bit 7, a
	jr nz, AccState_CollectReturn
	cpdi16 0x28b4, 0
	jr nz, AccState_CollectAcc4_Active
	cpdi16 0x28a8, 0
	jr nz, AccState_CollectAcc4_Active
	call AccWrap_PlayModeStopSync
	jr AccState_Apply

AccState_CollectAcc4_Active:
	call AccWrap_PlayModeStartPlay

AccState_Apply:
	call AccInit_CallF435A9
	ldb_d8 a, 0xcedf
	stb_d8 0x8d42, a
	ldb_d8 a, 0xcee0
	stb_d8 0x8d40, a
	call AccDisplay_RefreshIfDiskActive
	anddi8 0xfc5f, 207
	anddi8 0x3283, 251
	xor a, a
	stb_d8 0x3314, a
	stb_d8 0x3315, a
	stb_d8 0x3312, a
	stb_d8 0x3313, a
	stb_d8 0x3316, a
	stb_d8 0x3317, a
	stb_d8 0x3318, a
	ordi8 0x349f, 2

AccState_CollectReturn:
	ret

AccState_ScanLookupTable:
	.byte 0x00, 0x01, 0x02, 0x03, 0x04, 0x00, 0x01, 0x02
	.byte 0x03, 0x04, 0x00, 0x01, 0x02, 0x03, 0x04, 0x00
	.byte 0x01, 0x02, 0x03, 0x04, 0x00, 0x00, 0x00, 0x00
	.zero 10

AccVoice_ScanForD3:
	ldb_sri A, 0x07, 0xec, 0xf4
	cp a, 0x83
	jr z, AccVoice_ScanDone2
	cp a, 0xd3
	jr nz, AccVoice_ScanSkip
	call AccBuf_Advance
	call AccBuf_Advance
	ldb_sri A, 0x07, 0xec, 0xf4
	stb_d8 0x3333, a

AccVoice_ScanSkip:
	call AccBuf_Advance
	jr AccVoice_ScanForD3

AccVoice_ScanDone2:
	ret

AccVoice_SetupByteData:
	stdi8	0x33d4, 4
	ldb_d8	e, 0x3349
	stdi8	0x3333, 0
	ldda32	xiy, 0x32ce
	.byte 0xc1, 0xa5
	ldw	de, 0x66f5
	.byte 0x1c
	ld	a, e
	call	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	ld	iy, wa
	ldb_d8	a, 0x3285
	call	AccVoice_TableLookup
	call	AccVoice_ScanForD3
	inc	1, e
	jr	-38
	ret
	stdi8	0x33d4, 8
	ldb_d8	e, 0x3349
	stdi8	0x3333, 0
	ldda32	xiy, 0x32ce
	.byte 0xc1, 0xa6
	ldw	de, 0x66f5
	.byte 0x1c
	ld	a, e
	call	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	ld	iy, wa
	ldb_d8	a, 0x3285
	call	AccVoice_TableLookup
	call	AccVoice_ScanForD3
	inc	1, e
	jr	-38
	ret
	stdi8	0x33d4, 8
	ldb_d8	e, 0x3349
	stdi8	0x3333, 0
	ldda32	xiy, 0x32ce
	.byte 0xc1, 0xa7
	ldw	de, 0x66f5
	.byte 0x1c
	ld	a, e
	call	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	ld	iy, wa
	ldb_d8	a, 0x3285
	call	AccVoice_TableLookup
	call	AccVoice_ScanForD3
	inc	1, e
	jr	-38
	ret
	stdi8	0x33d4, 8
	ldb_d8	e, 0x3349
	stdi8	0x3333, 0
	ldda32	xiy, 0x32ce
	.byte 0xc1, 0xa8
	ldw	de, 0x66f5
	.byte 0x1c
	ld	a, e
	call	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	ld	iy, wa
	ldb_d8	a, 0x3285
	call	AccVoice_TableLookup
	call	AccVoice_ScanForD3
	inc	1, e
	jr	-38
	ret
	.byte 0xc3, 0xf5, 0xd1
	pop	sr
	ldb	a, 241
	.byte 0x85
	ldw	de, 0xf141
	.byte 0xd4
	ldw	hl, 256
	ldb_d8	a, 0x32a3
	call	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	stda16	0x3287, wa
	stdi8	0x33d4, 2
	ldb_d8	a, 0x32a4
	call	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	stda16	0x3289, wa
	stdi8	0x33d4, 4
	ldb_d8	a, 0x32a5
	call	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	stda16	0x328b, wa
	stdi8	0x33d4, 8
	ldb_d8	a, 0x32a6
	call	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	stda16	0x328d, wa
	stdi8	0x33d4, 16
	ldb_d8	a, 0x32a7
	call	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	stda16	0x328f, wa
	stdi8	0x33d4, 32
	ldb_d8	l, 0x32a8
	call	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	stda16	0x3291, wa
	ret

AccFlags_Aggregate:
	anddi8 0x3326, 192
	anddi8 0x3327, 192
	calr AccBuf_ResetAll4Positions
	bitda 0, 0x330e
	jr z, AccFlags_BuildIndex
	ordi8 0x330d, 1
	bitda 1, 0x330e
	jr z, AccFlags_CheckDecay
	cpdi8 0x333a, 0
	jr z, AccFlags_BuildIndex
	decdi8 1, 0x333a
	jr AccFlags_BuildIndex

AccFlags_CheckDecay:
	cpdi8 0x333a, 3
	jr z, AccFlags_BuildIndex
	incdi8 1, 0x333a

AccFlags_BuildIndex:
	xor w, w
	ldb_d8 a, 0x330a
	and a, 0xd
	jr z, AccFlags_CheckDir65
	or w, 0x1

AccFlags_CheckDir65:
	ldb_d8 a, 0x3309
	and a, 0x3
	jr z, AccFlags_CheckDir67
	or w, 0x2

AccFlags_CheckDir67:
	ldb_d8 a, 0x330b
	and a, 0x3
	jr z, AccFlags_CheckNoteOn
	or w, 0x4

AccFlags_CheckNoteOn:
	bitda 0, 0x330c
	jr z, AccFlags_CheckSync69
	or w, 0x8
	bitda 6, 0x3470
	jr z, AccFlags_PedalBit7
	or w, 0x2
	ordi8 0x3309, 1

AccFlags_PedalBit7:
	bitda 7, 0x3470
	jr z, AccFlags_CheckSync69
	or w, 0x2
	ordi8 0x3309, 2

AccFlags_CheckSync69:
	bitda 0, 0x330d
	jr z, AccFlags_CheckSync71
	or w, 0x8

AccFlags_CheckSync71:
	bitda 0, 0x330f
	jr z, AccFlags_Dispatch
	or w, 0x8

AccFlags_Dispatch:
	and w, 0xf
	sla w, 2
	ld xhl, AccFlags_JumpTable
	ld_sril3 XWA, 0x03, 0xec, 0xe1
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
	call	AccStyle_Init
	call	AccVoice_SetupAllParts
	anddi8	0x3316, 192
	anddi8	0x3317, 192
	anddi8	0x3318, 192
	anddi8	0x3312, 192
	anddi8	0x3313, 192
	jr	62
AccFlags_Handler4:
	call	AccTiming_CallHelper
	call	AccInit_ResetSongCounter
	call	AccVoice_ThirdLayer
	jr	48
AccFlags_Handler8:
	call	AccStyle_Init
	call	AccTiming_CallHelper
	call	AccInit_ResetSongCounter
	call	AccVoice_ThirdLayer
	jr	t, 0x1e
AccFlags_Handler2:
	call	AccVoice_SplitPointSetup
	jr	24
AccFlags_Handler10:
	call	AccStyle_Init
	call	AccVoice_SplitPointSetup
	jr	t, 0x0e
AccFlags_Handler1:
	call	AccVoice_ResetAll
	jr	8
AccFlags_Handler9:
	call	AccStyle_Init
	call	AccVoice_ResetAll
	call	Rhythm_Send_Ch90_7F_7E
	call	Rhythm_SendChanPressure
	calr	59
	ret

AccBuf_ResetAll4Positions:
	ld xhl, 0x2c94
	calr AccBuf_ResetOnePosition
	ld xhl, 0x2d94
	calr AccBuf_ResetOnePosition
	ld xhl, 0x2e94
	calr AccBuf_ResetOnePosition
	ld xhl, 0x2f94
	calr AccBuf_ResetOnePosition
	ret

AccBuf_ResetOnePosition:
	ld (xhl + 256), 0xa
	ld (xhl + 2), 0xff
	ldw wa, 0xa
	ldw bc, 0xa
	ei 6
	ld (xhl + 4), wa
	ld (xhl + 6), bc
	ei 0
	ret

AccBuf_ResetByteData:
	ldb	a, 0
	ld	xhl, 0x30f4
	xor	iy, iy
	.byte 0xf3
	reti
	cp	xix, xix
	ld	xbc, 0x09c8dd
	cp	iy, 72
	jr	c, -15
	ld	xhl, 0x313c
	xor	iy, iy
	.byte 0xf3
	reti
	cp	xix, xix
	ld	xbc, 0x09c8dd
	cp	iy, 72
	jr	c, -15
	ld	xhl, 0x3184
	xor	iy, iy
	.byte 0xf3
	reti
	cp	xix, xix
	ld	xbc, 0x09c8dd
	cp	iy, 72
	jr	c, -15
	ld	xhl, 0x31cc
	xor	iy, iy
	.byte 0xf3
	reti
	cp	xix, xix
	ld	xbc, 0x09c8dd
	cp	iy, 72
	jr	c, -15
	ret

AccNote_FlushAll:
	ldb_d8 a, 0x332c
	and a, 0x3f
	jr z, AccNote_FlushReturn
	call RhythmPart_CopyData
	call RhythmPart1_ProcessAccentData
	ldb a, 0x1
	stb_d8 0x32ec, a
	call RhythmPart2_ProcessAccentData
	call AccVoice_LoadRhythmParams_Part3
	call AccVoice_LoadRhythmParams_Part4
	call AccVoice_LoadRhythmParams_Part5
	anddi8 0x332c, 192

AccNote_FlushReturn:
	ret

AccTempo_CalcPosition:
	ldb a, 0x5f
	ldb_d8 w, 1112
	dec 1, w
	call AccVoice_LookupTableAddress
	ldw_d16 xbc, 0x327d
	ldb_d8 w, 0x32b5
	dec 1, w
	call AccTempo_PositionCompare
	stb_d8 0x32ec, a
	stb_d8 0x32ea, a
	ret

AccInit_FullReInit:
	call Rhythm_SendNoteOnMax
	call AccompVoice_BulkReadRegisters
	calr AccBuf_WriteAllNotesOff
	call Rhythm_SendChanPressure
	calr AccBuf_ResetAll4
	ldb_d8 a, 0x3312
	orda8 a, 0x3313
	and a, 0x3f
	jr z, AccInit_ReInit_CheckNoteOn
	bitda 0, 0x3301
	jr z, AccInit_ReInit_CheckNoteOn
	ordi8 0x330c, 1
	ldb_d8 a, 0x3312
	and a, 0x3f
	jr z, AccInit_ReInit_AdjustDecay
	cpdi8 0x333a, 0
	jr z, AccInit_ReInit_CheckNoteOn
	decdi8 1, 0x333a
	jr AccInit_ReInit_CheckNoteOn

AccInit_ReInit_AdjustDecay:
	cpdi8 0x333a, 3
	jr z, AccInit_ReInit_CheckNoteOn
	incdi8 1, 0x333a

AccInit_ReInit_CheckNoteOn:
	bitda 0, 0x330c
	jr z, AccInit_ReInit_CheckModes
	ldb_d8 a, 0x3326
	and a, 0x3f
	jr nz, AccInit_ReInit_CheckModes
	calr AccStyle_Init
	calr AccVoice_SetupAllParts
	ldb_d8 a, 1075
	stb_d8 1112, a

AccInit_ReInit_CheckModes:
	ldb_d8 a, 0x330a
	and a, 0xd
	jr z, AccInit_ReInit_CheckSplit
	calr AccVoice_ResetAll

AccInit_ReInit_CheckSplit:
	ldb_d8 a, 0x3309
	and a, 0x3
	jr nz, AccInit_ReInit_ApplySplit
	bitda 6, 0x3470
	jr z, AccInit_ReInit_CheckPedalBit7
	ordi8 0x3309, 1
	jr AccInit_ReInit_ApplySplit

AccInit_ReInit_CheckPedalBit7:
	bitda 7, 0x3470
	jr z, AccInit_ReInit_CheckThird
	ordi8 0x3309, 2

AccInit_ReInit_ApplySplit:
	calr AccVoice_SplitPointSetup

AccInit_ReInit_CheckThird:
	ldb_d8 a, 0x330b
	and a, 0x3
	jr z, AccInit_ReInit_ClearHighBits
	calr AccTiming_CallHelper
	call AccInit_ResetSongCounter
	calr AccVoice_ThirdLayer

AccInit_ReInit_ClearHighBits:
	anddi8 0x32ab, 240
	anddi8 0x32ac, 240
	anddi8 0x32ad, 240
	anddi8 0x32ae, 240
	anddi8 0x32af, 240
	anddi8 0x32b0, 240
	calr AccSeq_DualPartScan
	bitda 6, 0x32f4
	jr nz, AccInit_ReInit_SetDirty
	calr AccSeq_FourChannelScan

AccInit_ReInit_SetDirty:
	ordi8 0x332c, 128
	ret

AccInit_ResetSongCounter:
	cpdi8 0x32e2, 0
	jr nz, AccInit_ResetSong_Store
	call SeqVoice_SendNoteOffAndFlush

AccInit_ResetSong_Store:
	stdi8 0x32e2, 0
	ret

AccInit_CallF435A9:
	call SeqVoice_SendNoteOffAndFlush
	ret

AccTuning_CheckChange:
	cpdi8 0x32e5, 128
	jr nc, AccTuning_ChangeReturn
	ldb_d8 a, 0x3391
	xorda8 a, 0x3392
	bit 0, a
	jr z, AccTuning_ChangeReturn
	ordi8 0x3393, 1

AccTuning_ChangeReturn:
	ret

AccTuning_LoadFromROM:
	push xwa
	push xhl
	call AccHelper_ComputeVoiceOffset
	add xhl, 0x1e7810
	bitm 7, (xhl + 1)
	jrl z, AccTuning_LoadReturn
	ld a, (xhl + 4)
	stb_d8 0x3254, a
	ld a, (xhl + 5)
	ld w, a
	and w, 0x7f
	stb_d8 0x3255, w
	and a, 0x80
	srl a, 7
	stb_d8 0x3257, a
	ld a, (xhl + 6)
	stb_d8 0x325b, a
	ld a, (xhl + 7)
	ld w, a
	and w, 0x7f
	stb_d8 0x325c, w
	and a, 0x80
	srl a, 7
	stb_d8 0x325e, a
	ld a, (xhl + 8)
	stb_d8 0x3262, a
	ld a, (xhl + 9)
	ld w, a
	and w, 0x7f
	stb_d8 0x3263, w
	and a, 0x80
	srl a, 7
	stb_d8 0x3265, a
	ld a, (xhl + 2)
	stb_d8 0x324d, a
	ld a, (xhl + 3)
	ld w, a
	and w, 0x7f
	stb_d8 0x324e, w
	and a, 0x80
	srl a, 7
	stb_d8 0x3250, a
	ld a, (xhl + 256)
	stb_d8 0x3246, a
	ld a, (xhl + 1)
	and a, 0x7f
	stb_d8 0x3247, a

AccTuning_LoadReturn:
	pop xhl
	pop xwa
	ret

AccTuning_LoadMaster:
	call AccHelper_ComputeVoiceOffset
	add xhl, 0x1e7810
	bitm 7, (xhl + 1)
	jr z, AccTuning_LoadMasterReturn
	ld a, (xhl + 256)
	stb_d8 0x3246, a
	ld a, (xhl + 1)
	and a, 0x7f
	stb_d8 0x3247, a

AccTuning_LoadMasterReturn:
	ret

AccTuning_LoadCoarse:
	call AccHelper_ComputeVoiceOffset
	add xhl, 0x1e7810
	bitm 7, (xhl + 1)
	jr z, AccTuning_LoadCoarseReturn
	ld a, (xhl + 2)
	stb_d8 0x324d, a
	ld a, (xhl + 3)
	ld w, a
	and w, 0x7f
	stb_d8 0x324e, w
	and a, 0x80
	srl a, 7
	stb_d8 0x3250, a

AccTuning_LoadCoarseReturn:
	ret

AccTuning_LoadFine:
	call AccHelper_ComputeVoiceOffset
	add xhl, 0x1e7810
	bitm 7, (xhl + 1)
	jr z, AccTuning_LoadFineReturn
	ld a, (xhl + 4)
	stb_d8 0x3254, a
	ld a, (xhl + 5)
	ld w, a
	and w, 0x7f
	stb_d8 0x3255, w
	and a, 0x80
	srl a, 7
	stb_d8 0x3257, a

AccTuning_LoadFineReturn:
	ret

AccTuning_LoadOctave:
	call AccHelper_ComputeVoiceOffset
	add xhl, 0x1e7810
	bitm 7, (xhl + 1)
	jr z, AccTuning_LoadOctaveReturn
	ld a, (xhl + 6)
	stb_d8 0x325b, a
	ld a, (xhl + 7)
	ld w, a
	and w, 0x7f
	stb_d8 0x325c, w
	and a, 0x80
	srl a, 7
	stb_d8 0x325e, a

AccTuning_LoadOctaveReturn:
	ret

AccTuning_LoadTranspose:
	call AccHelper_ComputeVoiceOffset
	add xhl, 0x1e7810
	bitm 7, (xhl + 1)
	jr z, AccTuning_LoadTransposeReturn
	ld a, (xhl + 8)
	stb_d8 0x3262, a
	ld a, (xhl + 9)
	ld w, a
	and w, 0x7f
	stb_d8 0x3263, w
	and a, 0x80
	srl a, 7
	stb_d8 0x3265, a

AccTuning_LoadTransposeReturn:
	ret

AccTuning_ApplyChange:
	bitda 0, 0x3393
	jrl z, AccTuning_ApplyReturn
	call AccHelper_ComputeVoiceOffset
	add xhl, 0x1e7810
	bitda 0, 0x3391
	jr z, AccTuning_ApplyChange_ClearBit
	ormi8 (xhl + 1), 0x80
	jr AccTuning_ApplyChange_SelectMode

AccTuning_ApplyChange_ClearBit:
	andmi8 (xhl + 1), 0x7f

AccTuning_ApplyChange_SelectMode:
	ldb_d8 a, 0x3316
	orda8 a, 0x3317
	and a, 0x3f
	jrl nz, AccTuning_Mode_078
	ldb_d8 a, 0x3318
	and a, 0x3f
	jr nz, AccTuning_Mode_080
	ldb_d8 a, 0x3314
	and a, 0x3f
	jr nz, AccTuning_Mode_076
	orda8 a, 0x3315
	and a, 0x3f
	jr nz, AccTuning_Mode_077
	ldb_d8 a, 0x3312
	orda8 a, 0x3313
	and a, 0x3f
	jr nz, AccTuning_Mode_074
	ldb_d8 a, 0x335d
	and a, 0x3f
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
	ldb_d8 a, 0x32a3
	ldda32 xiy, 0x32ce
	call AccPart_GetVoiceParamOffsetTable
	call AccVoice_LoadTuningBlock
	ordi8 0x332c, 63
	ordi8 0x332c, 128

AccTuning_ApplyReturn:
	anddi8 0x3393, 254
	ret

AccTuning_Toggle:
	cpdi8 0x32e5, 128
	jr nc, AccTuning_Toggle_NoStyle
	ldb_d8 a, 0x3391
	xorda8 a, 0x3392
	bit 0, a
	jr z, AccTuning_Toggle_CheckDirty
	call AccHelper_ComputeVoiceOffset
	add xhl, 0x1e7810
	bitda 0, 0x3391
	jr z, AccTuning_Toggle_ClearBit
	ormi8 (xhl + 1), 0x80
	jr AccTuning_Toggle_SetFlag

AccTuning_Toggle_ClearBit:
	andmi8 (xhl + 1), 0x7f

AccTuning_Toggle_SetFlag:
	ordi8 0x333b, 1
	jr AccTuning_Toggle_Return

AccTuning_Toggle_CheckDirty:
	bitda 0, 0x3393
	jr z, AccTuning_Toggle_Return
	anddi8 0x3393, 254
	ordi8 0x333b, 1
	jr AccTuning_Toggle_Return

AccTuning_Toggle_NoStyle:
	anddi8 0x3391, 254
	call AccTuning_LEDOff

AccTuning_Toggle_Return:
	ret

AccTuning_SaveState:
	ldb_d8 a, 0x3391
	stb_d8 0x3392, a
	ret

AccTuning_Init:
	push xwa
	push xhl
	cpdi8 0x32e5, 128
	jr nc, AccTuning_Init_NoTuning
	call AccHelper_ComputeVoiceOffset
	add xhl, 0x1e7810
	bitm 7, (xhl + 1)
	jr z, AccTuning_Init_NoTuning
	ordi8 0x3391, 1
	call AccTuning_LEDOn
	ldb_d8 a, 0x3391
	stb_d8 0x3392, a
	jr AccTuning_Init_Epilogue

AccTuning_Init_NoTuning:
	anddi8 0x3391, 254
	call AccTuning_LEDOff
	ldb_d8 a, 0x3391
	stb_d8 0x3392, a

AccTuning_Init_Epilogue:
	pop xhl
	pop xwa
	ret

AccTuning_DisableIfNoStyle:
	cpdi8 0x32e5, 128
	jr c, AccTuning_DisableReturn
	anddi8 0x3391, 254
	call AccTuning_LEDOff

AccTuning_DisableReturn:
	ret

AccTuning_LEDOn:
	stdi8 0x3390, 1
	ldb a, 0x4a
	call CtrlPanel_SetIndicatorBit
	ret

AccTuning_LEDOff:
	stdi8 0x3390, 0
	ldb a, 0x4a
	call CtrlPanel_SetIndicatorBit
	ret

AccWrap_JumpTable:
	jp	AccWrap_JumpTable_0x15
	jp	AccWrap_JumpTable_0x14
	jp	AccWrap_JumpTable_0x14
	jp	AccWrap_JumpTable_0x14
	jp	AccWrap_JumpTable_0x14
	ret
	ret
AccWrap_ReplayStop:
	jp	AccPedal_EventDispatch
AccWrap_ReplayStopAlt:
	jp	AccPedal_RawHandler_0x2

AccWrap_AutoPlayCheck:
	push xiz
	call AccAutoPlay_NoteDispatch
	pop xiz
	ret

AccWrap_PlayModeByteData:
	jp	AccReplay_FullRestart
	jp	AccAutoPlay_ActionDispatch

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
	jp	AccPlayMode_StopExprC

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
	call	AccPos_ClearOnStart_Padding_0x2
	pop	xiz
	ret

AccWrap_FlagSync:
	jp AccFlags_SyncTo64607
AccWrap_PlayModeStopData2:
	jp	AccTempo_WriteMarker_Padding_0x2

AccWrap_AutoPlayZoneTrack:
	push xiz
	call AccAutoPlay_ZoneTrack
	pop xiz
	ret

AccWrap_AutoPlayByteData:
	jp	AccAutoPlay_PeriodicCheck
	push	xiz
	calr	5156
	pop	xiz
	ret
	push	xiz
	calr	5268
	pop	xiz
	ret

AccPedal_EventDispatch:
	ldb_d8 a, 0xc07d
	stb_d8 0x348a, a
	cps a, 5
	jr z, AccPedal_TypeSustainOrExpr
	cps a, 6
	jr z, AccPedal_TypeSustainOrExpr
	jr AccPedal_CheckType0

AccPedal_TypeSustainOrExpr:
	ldb_d8 a, 0xc07e
	stb_d8 0x347e, a
	ldb_d8 a, 0xc07f
	cp a, 0xff
	jr nz, AccPedal_ParseValue
	xor a, a

AccPedal_ParseValue:
	stb_d8 0x347f, a
	calr AccPedal_SustainHandler
	calr AccPedal_ExprToggle
	calr AccPedal_DistributeParams

AccPedal_CheckType0:
	ldb_d8 a, 0xc07d
	cps a, 0
	jr z, AccPedal_SavePosition
	cps a, 7
	jr nz, AccPedal_EventReturn
	ldb_d8 a, 0xc07f
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
	ldb_d8	a, 0xc07d
	cps	a, 3
	jr	nz, 27
	ldb_d8	a, 0xc07e
	and	a, 7
	stb_d8	0x347e, a
	ldb_d8	a, 0xc07f
	stb_d8	0x347f, a
	ldb_d8	a, 0xc07d
	stb_d8	0x348a, a
	ret
	nop
	nop

AccPedal_SustainHandler:
	cpdi8 0x348a, 5
	jrl nz, AccPedal_SustainReturn
	ldb_d8 a, 0x347e
	andda8 a, 0x347f
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
	cpdi8 0x7f0b, 0
	jr z, AccPedal_Sustain_CheckStyle
	call AccPlay_ToggleEntry
	jrl AccPedal_SustainReturn

AccPedal_Sustain_CheckStyle:
	cpdi8 0x8d36, 111
	jr z, AccPedal_Sustain_SpecialStyle
	cpdi8 0x8d36, 112
	jr z, AccPedal_Sustain_SpecialStyle
	cpdi8 0x8d36, 113
	jr z, AccPedal_Sustain_SpecialStyle
	cpdi8 0x8d36, 114
	jr nz, AccPedal_Sustain_CheckPlay

AccPedal_Sustain_SpecialStyle:
	ordi8 3381, 1
	jrl AccPedal_SustainReturn

AccPedal_Sustain_CheckPlay:
	bitda 2, 0x28a7
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
	cpdi8 0x8d36, 120
	jr z, AccPedal_Sustain_MultiMatch
	cpdi8 0x8d36, 122
	jr z, AccPedal_Sustain_MultiMatch
	cpdi8 0x8d36, 115
	jr z, AccPedal_Sustain_MultiMatch
	cpdi8 0x8d36, 116
	jr z, AccPedal_Sustain_MultiMatch
	cpdi8 0x8d36, 117
	jr z, AccPedal_Sustain_MultiMatch
	cpdi8 0x8d36, 118
	jr z, AccPedal_Sustain_MultiMatch
	cpdi8 0x8d36, 119
	jr z, AccPedal_Sustain_MultiMatch
	cpdi8 0x8d36, 121
	jr z, AccPedal_Sustain_MultiMatch
	cpdi8 0x8d36, 108
	jr z, AccPedal_Sustain_MultiMatch
	cpdi8 0x8d36, 109
	jr z, AccPedal_Sustain_MultiMatch
	cpdi8 0x8d36, 110
	jr nz, AccPedal_Sustain_Normal

AccPedal_Sustain_MultiMatch:
	ordi8 3381, 1
	jr AccPedal_SustainReturn

AccPedal_Sustain_Normal:
	bitda 2, 0x28b2
	jr nz, AccPedal_SustainReturn
	pushw wa
	calr AccPedal_StyleCheck
	cps a, 1
	popw wa
	jr z, AccPedal_SustainReturn
	ei 6
	ldb_d8 a, 1056
	bit 2, a
	jr nz, AccPedal_Sustain_CallPlayMode
	bit 0, a
	jr z, AccPedal_Sustain_CallPlayMode
	xor a, a
	stb_d8 1056, a
	stb_d8 1054, a
	stb_d8 1057, a
	ei 0
	jr AccPedal_SustainReturn

AccPedal_Sustain_CallPlayMode:
	ei 0
	calr AccPlayMode_TransitionRouter

AccPedal_SustainReturn:
	ret

AccPedal_SustainPadding:
	nop
	nop

AccPedal_StyleCheck:
	cpdi8 0x8d36, 111
	jr z, AccPedal_StyleCheck_Ineligible
	cpdi8 0x8d36, 108
	jr c, AccPedal_StyleCheck_Extended
	cpdi8 0x8d36, 122
	jr ugt, AccPedal_StyleCheck_Extended
	jr AccPedal_StyleCheck_Ineligible

AccPedal_StyleCheck_Extended:
	cpdi8 0x8d34, 19
	jr z, AccPedal_StyleCheck_Ineligible
	cpdi8 0x8d36, 120
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
	cpdi8 0x348a, 5
	jr nz, AccPedal_ExprReturn
	ldb_d8 a, 0x347e
	andda8 a, 0x347f
	bit 1, a
	jr z, AccPedal_ExprReturn
	ldb a, 0x2
	xordm8 0xfc5f, a
	cpdi8 0x90f8, 255
	jr z, AccPedal_ExprReturn
	bitda 3, 0xfd56
	jr z, AccPedal_ExprReturn
	ldb_d8 e, 0xfc5f
	and e, 0x2
	ld xix, 0x38e8
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
	nop
	nop

AccPedal_DistributeParams:
	cpdi8 0x8d34, 14
	jr z, AccPedal_Distribute_JumpMain
	bitda 0, 0x28a6
	jr z, AccPedal_Distribute_ClearAll

AccPedal_Distribute_JumpMain:
	jp AccPedal_DistributeReturn

AccPedal_Distribute_ClearAll:
	xor wa, wa
	stb_d8 0x3480, a
	stb_d8 0x3481, a
	stb_d8 0x3482, a
	stb_d8 0x3483, a
	stb_d8 0x3484, a
	stb_d8 0x3485, a
	stb_d8 0x3486, a
	stb_d8 0x3487, a
	calr AccPedal_ProcessAllBits
	bitda 3, 3411
	jr z, AccPedal_Distribute_CheckRecord
	anddi8 0xfc5f, 15
	stdi8 0x3481, 0
	stdi8 0x3483, 0
	stdi8 0x3485, 0
	stdi8 0x3487, 0

AccPedal_Distribute_CheckRecord:
	calr AccPedal_StateSync
	bitda 3, 3411
	jr z, AccPedal_DistributeReturn
	cpdi8 3429, 0
	jr z, AccPedal_DistributeReturn
	xor wa, wa
	stb_d8 0x3480, a
	stb_d8 0x3481, a
	stb_d8 0x3484, a
	stb_d8 0x3485, a
	calr AccPedal_MapToAcc
	calr AccPedal_SendEvents

AccPedal_DistributeReturn:
	ret

AccPedal_DistributePadding:
	nop
	nop

AccPedal_SendEvents:
	ldb_d8 a, 0x3480
	xor a, 0xff
	andda8 a, 0x3481
	cps a, 0
	jr z, AccPedal_SendEvents_Group2
	ldb b, 0x5
	ldb c, 0x48
	ld d, a
	ldb_d8 e, 0x3480
	call MIDI_TransmitTempoCC

AccPedal_SendEvents_Group2:
	ldb_d8 a, 0x3484
	xor a, 0xff
	andda8 a, 0x3485
	cps a, 0
	jr z, AccPedal_SendEvents_OnSustain
	ldb b, 0x6
	ldb c, 0x48
	ld d, a
	ldb_d8 e, 0x3484
	call MIDI_TransmitTempoCC

AccPedal_SendEvents_OnSustain:
	ldb_d8 a, 0x3480
	andda8 a, 0x3481
	cps a, 0
	jr z, AccPedal_SendEvents_OnExpr
	ldb b, 0x5
	ldb c, 0x48
	ld d, a
	ldb_d8 e, 0x3480
	call MIDI_TransmitTempoCC

AccPedal_SendEvents_OnExpr:
	ldb_d8 a, 0x3484
	andda8 a, 0x3485
	cps a, 0
	jr z, AccPedal_SendEventsReturn
	ldb b, 0x6
	ldb c, 0x48
	ld d, a
	ldb_d8 e, 0x3484
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
	nop
	nop

AccPedal_Bit2_Sustain:
	cpdi8 0x348a, 5
	jr nz, AccPedal_Bit2_Return
	ldb_d8 a, 0x347e
	andda8 a, 0x347f
	bit 2, a
	jr z, AccPedal_Bit2_Off
	ordi16 4360, 4
	cpdi8 0x90f8, 127
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
	bitda 2, 0x347f
	jr z, AccPedal_Bit2_Return
	bitda 2, 0x347e
	jr nz, AccPedal_Bit2_Return
	cpdi8 0x90f8, 127
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
	cpdi8 0x348a, 6
	jr nz, AccPedal_Expr_Return
	ldb_d8 a, 0x347e
	andda8 a, 0x347f
	bit 2, a
	jr z, AccPedal_Expr_Off
	lds de, 4
	sla de, 8
	orddm16 4360, xde
	cpdi8 0x90f8, 127
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
	bitda 2, 0x347f
	jr z, AccPedal_Expr_Return
	bitda 2, 0x347e
	jr nz, AccPedal_Expr_Return
	cpdi8 0x90f8, 127
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
	cpdi8 0x348a, 5
	jr nz, AccPedal_Bit7_Return
	ldb_d8 a, 0x347e
	andda8 a, 0x347f
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
	bitda 7, 0x347f
	jr z, AccPedal_Bit7_Return
	bitda 7, 0x347e
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
	cpdi8 0x348a, 5
	jr nz, AccPedal_Bit6_Return
	ldb_d8 a, 0x347e
	andda8 a, 0x347f
	bit 6, a
	jr z, AccPedal_Bit6_HoldOff
	ordi16 4360, 64
	bitda 2, 1054
	jr z, AccPedal_Bit6_HoldOff
	calr AccPedal_HoldOn
	jr AccPedal_Bit6_HoldOff

AccPedal_Bit6_HoldOff:
	bitda 6, 0x347f
	jr z, AccPedal_Bit6_Return
	bitda 6, 0x347e
	jr nz, AccPedal_Bit6_Return
	bitda 2, 1054
	jr z, AccPedal_Bit6_Return
	calr AccPedal_HoldOff
	jr AccPedal_Bit6_Return

AccPedal_Bit6_Return:
	ret

AccPedal_Bit4_Sostenuto:
	cpdi8 0x348a, 5
	jr nz, AccPedal_Bit4_Return
	ldb_d8 a, 0x347e
	andda8 a, 0x347f
	bit 4, a
	jr z, AccPedal_Bit4_Off
	bitda 2, 1054
	jr z, AccPedal_Bit4_Off
	calr AccPedal_SostenutoOn

AccPedal_Bit4_Off:
	bitda 4, 0x347f
	jr z, AccPedal_Bit4_Return
	bitda 4, 0x347e
	jr nz, AccPedal_Bit4_Return
	bitda 2, 1054
	jr z, AccPedal_Bit4_Return
	calr AccPedal_SostenutoOff

AccPedal_Bit4_Return:
	ret

AccPedal_Bit5_Soft:
	cpdi8 0x348a, 5
	jr nz, AccPedal_Bit5_Return
	ldb_d8 a, 0x347e
	andda8 a, 0x347f
	bit 5, a
	jr z, AccPedal_Bit5_Off
	bitda 2, 1054
	jr z, AccPedal_Bit5_Off
	calr AccPedal_SoftOn

AccPedal_Bit5_Off:
	bitda 5, 0x347f
	jr z, AccPedal_Bit5_Return
	bitda 5, 0x347e
	jr nz, AccPedal_Bit5_Return
	bitda 2, 1054
	jr z, AccPedal_Bit5_Return
	calr AccPedal_SoftOff

AccPedal_Bit5_Return:
	ret

AccPedal_Bit3_Damper:
	cpdi8 0x348a, 5
	jr nz, AccPedal_Bit3_Return
	ldb_d8 a, 0x347e
	andda8 a, 0x347f
	bit 3, a
	jr z, AccPedal_Bit3_Off
	calr AccPedal_DamperOn

AccPedal_Bit3_Off:
	bitda 3, 0x347f
	jr z, AccPedal_Bit3_Return
	bitda 3, 0x347e
	jr nz, AccPedal_Bit3_Return
	calr AccPedal_DamperOff

AccPedal_Bit3_Return:
	ret

AccPedal_StateSync:
	cpdi8 0x90f8, 127
	jr z, AccPedal_Sync_SendEvents
	cpdi8 0x90f8, 255
	jr nz, AccPedal_Sync_DispatchAll

AccPedal_Sync_SendEvents:
	calr AccPedal_SendEvents

AccPedal_Sync_DispatchAll:
	cpdi8 0x90f8, 255
	jr z, AccPedal_Sync_Return
	call AccPedal_SendCtrl1
	call AccPedal_SendCtrl2
	call AccPedal_SendCtrl3
	call AccPedal_SendCtrl4

AccPedal_Sync_Return:
	ret

AccPedal_SendCtrl1:
	ldb_d8 a, 0x3482
	xor a, 0xff
	andda8 a, 0x3483
	cps a, 0
	jr z, AccPedal_SendCtrl1_Return
	bitda 3, 0xfd56
	jr z, AccPedal_SendCtrl1_CheckPort
	ldb b, 0x5
	ld d, a
	ldb_d8 e, 0x3482
	ld xix, 0x38e8
	ld (xix + 256), 0x48
	ld (xix + 1), b
	ld (xix + 2), e
	ld (xix + 3), d
	push xix
	call MidiPkt_DispatchViaTable_4DCE
	inc 4, xsp

AccPedal_SendCtrl1_CheckPort:
	bitda 4, 0xfd50
	jr nz, AccPedal_SendCtrl1_Return
	ldb_d8 a, 0x90e4
	and a, 0x8f
	stb_d8 0x90e5, a
	cpdi8 0x90f8, 127
	jr nz, AccPedal_SendCtrl1_UpdateMask
	anddi8 0x90e5, 127

AccPedal_SendCtrl1_UpdateMask:
	ldb_d8 a, 0x3482
	xor a, 0xff
	andda8 a, 0x3483
	ldb b, 0x5
	ldb c, 0x48
	ld d, a
	ldb_d8 e, 0x3482
	call MIDI_DispatchCC

AccPedal_SendCtrl1_Return:
	ret

AccPedal_SendCtrl2:
	ldb_d8 a, 0x3486
	xor a, 0xff
	andda8 a, 0x3487
	cps a, 0
	jr z, AccPedal_SendCtrl2_Return
	bitda 3, 0xfd56
	jr z, AccPedal_SendCtrl2_CheckPort
	ldb b, 0x6
	ld d, a
	ldb_d8 e, 0x3486
	ld xix, 0x38e8
	ld (xix + 256), 0x48
	ld (xix + 1), b
	ld (xix + 2), e
	ld (xix + 3), d
	push xix
	call MidiPkt_DispatchViaTable_4DCE
	inc 4, xsp

AccPedal_SendCtrl2_CheckPort:
	bitda 4, 0xfd50
	jr nz, AccPedal_SendCtrl2_Return
	ldb_d8 a, 0x90e4
	and a, 0x8f
	stb_d8 0x90e5, a
	cpdi8 0x90f8, 127
	jr nz, AccPedal_SendCtrl2_UpdateMask
	anddi8 0x90e5, 127

AccPedal_SendCtrl2_UpdateMask:
	ldb_d8 a, 0x3486
	xor a, 0xff
	andda8 a, 0x3487
	ldb b, 0x6
	ldb c, 0x48
	ld d, a
	ldb_d8 e, 0x3486
	call MIDI_DispatchCC

AccPedal_SendCtrl2_Return:
	ret

AccPedal_SendCtrl3:
	ldb_d8 a, 0x3482
	andda8 a, 0x3483
	cps a, 0
	jr z, AccPedal_SendCtrl3_Return
	bitda 3, 0xfd56
	jr z, AccPedal_SendCtrl3_CheckPort
	ldb b, 0x5
	ld d, a
	ldb_d8 e, 0x3482
	ld xix, 0x38e8
	ld (xix + 256), 0x48
	ld (xix + 1), b
	ld (xix + 2), e
	ld (xix + 3), d
	push xix
	call MidiPkt_DispatchViaTable_4DCE
	inc 4, xsp

AccPedal_SendCtrl3_CheckPort:
	bitda 4, 0xfd50
	jr nz, AccPedal_SendCtrl3_Return
	ldb_d8 a, 0x90e4
	and a, 0x8f
	stb_d8 0x90e5, a
	cpdi8 0x90f8, 127
	jr nz, AccPedal_SendCtrl3_UpdateMask
	anddi8 0x90e5, 127

AccPedal_SendCtrl3_UpdateMask:
	ldb_d8 a, 0x3482
	andda8 a, 0x3483
	ldb b, 0x5
	ldb c, 0x48
	ld d, a
	ldb_d8 e, 0x3482
	call MIDI_DispatchCC

AccPedal_SendCtrl3_Return:
	ret

AccPedal_SendCtrl4:
	ldb_d8 a, 0x3486
	andda8 a, 0x3487
	cps a, 0
	jr z, AccPedal_SendCtrl4_Return
	bitda 3, 0xfd56
	jr z, AccPedal_SendCtrl4_CheckPort
	ldb b, 0x6
	ld d, a
	ldb_d8 e, 0x3486
	ld xix, 0x38e8
	ld (xix + 256), 0x48
	ld (xix + 1), b
	ld (xix + 2), e
	ld (xix + 3), d
	push xix
	call MidiPkt_DispatchViaTable_4DCE
	inc 4, xsp

AccPedal_SendCtrl4_CheckPort:
	bitda 4, 0xfd50
	jr nz, AccPedal_SendCtrl4_Return
	ldb_d8 a, 0x90e4
	and a, 0x8f
	stb_d8 0x90e5, a
	cpdi8 0x90f8, 127
	jr nz, AccPedal_SendCtrl4_UpdateMask
	anddi8 0x90e5, 127

AccPedal_SendCtrl4_UpdateMask:
	ldb_d8 a, 0x3486
	andda8 a, 0x3487
	ldb b, 0x6
	ldb c, 0x48
	ld d, a
	ldb_d8 e, 0x3486
	call MIDI_DispatchCC

AccPedal_SendCtrl4_Return:
	ret

AccPedal_MapToAcc:
	cpdi8 0x348a, 5
	jr nz, AccPedal_MapToAcc_Send
	ldb_d8 a, 0x347e
	andda8 a, 0x347f
	bit 6, a
	jr z, AccPedal_MapToAcc_Send
	call AccPedal_ScanVoiceSlots
	bitda 1, 3411
	jr z, AccPedal_MapToAcc_Send
	ordi8 0x3481, 64
	ordi8 0x3480, 64

AccPedal_MapToAcc_Send:
	cpdi8 0x348a, 5
	jr nz, AccPedal_MapToAcc_UpdateMask
	ldb_d8 a, 0x347e
	andda8 a, 0x347f
	bit 7, a
	jr z, AccPedal_MapToAcc_UpdateMask
	call AccPedal_ScanVoiceSlots
	bitda 1, 3411
	jr z, AccPedal_MapToAcc_CheckDir
	ordi8 0x3481, 128
	ordi8 0x3480, 128
	jr AccPedal_MapToAcc_UpdateMask

AccPedal_MapToAcc_CheckDir:
	ordi8 0x3481, 8
	ordi8 0x3480, 8

AccPedal_MapToAcc_UpdateMask:
	cpdi8 0x348a, 5
	jr nz, AccPedal_MapToAcc_SetMask
	ldb_d8 a, 0x347e
	andda8 a, 0x347f
	bit 2, a
	jr z, AccPedal_MapToAcc_SetMask
	call AccPedal_ScanVoiceSlots
	bitda 1, 3411
	jr z, AccPedal_MapToAcc_ClearMask
	ordi8 0x3481, 16
	ordi8 0x3480, 16
	jr AccPedal_MapToAcc_SetMask

AccPedal_MapToAcc_ClearMask:
	ordi8 0x3481, 4
	ordi8 0x3480, 4

AccPedal_MapToAcc_SetMask:
	cpdi8 0x348a, 6
	jr nz, AccPedal_MapToAcc_Return
	ldb_d8 a, 0x347e
	andda8 a, 0x347f
	bit 2, a
	jr z, AccPedal_MapToAcc_Return
	call AccPedal_ScanVoiceSlots
	bitda 1, 3411
	jr z, AccPedal_MapToAcc_Apply
	ordi8 0x3481, 32
	ordi8 0x3480, 32
	jr AccPedal_MapToAcc_Return

AccPedal_MapToAcc_Apply:
	ordi8 0x3485, 4
	ordi8 0x3484, 4

AccPedal_MapToAcc_Return:
	cpdi8 0x348a, 5
	jr nz, AccPedal_MapPadding
	ldb_d8 a, 0x347e
	andda8 a, 0x347f
	bit 5, a
	jr z, AccPedal_MapPadding
	call AccPedal_ScanVoiceSlots
	bitda 1, 3411
	jr z, AccPedal_MapPadding
	ordi8 0x3481, 32
	ordi8 0x3480, 32
	jr AccPedal_MapPadding

AccPedal_MapPadding:
	ret

AccPedal_MapPadding2:
	nop
	nop

AccPedal_SustainOn:
	bitda 2, 0x3470
	jrl nz, AccPedal_SustainOn_AltRoute
	ordi8 0x3470, 4
	bitda 2, 0xfc5f
	jr nz, AccPedal_SustainOn_SetMask
	ordi8 0xfc5f, 4
	ordi8 0x3482, 4
	ordi8 0x3480, 4
	jr AccPedal_SustainOn_Update64607

AccPedal_SustainOn_SetMask:
	cpdi8 0x90f8, 127
	jr nz, AccPedal_SustainOn_Update64607
	anddi8 0xfc5f, 251
	anddi8 0x3482, 251
	anddi8 0x3480, 251

AccPedal_SustainOn_Update64607:
	ordi8 0x3481, 4
	ordi8 0x3483, 4
	bitda 3, 0xfc5f
	jr z, AccPedal_SustainOn_Post
	anddi8 0xfc5f, 247
	anddi8 0x3480, 247
	ordi8 0x3481, 8
	anddi8 0x3482, 247
	ordi8 0x3483, 8

AccPedal_SustainOn_Post:
	bitda 2, 0xfc60
	jr z, AccPedal_SustainOn_Finalize
	anddi8 0xfc60, 251
	anddi8 0x3484, 251
	ordi8 0x3485, 4
	anddi8 0x3486, 251
	ordi8 0x3487, 4

AccPedal_SustainOn_Finalize:
	bitda 6, 0xfc5f
	jr z, AccPedal_SustainOn_CheckAlt
	anddi8 0xfc5f, 191

AccPedal_SustainOn_CheckAlt:
	bitda 7, 0xfc5f
	jr z, AccPedal_SustainOn_AltRoute
	anddi8 0xfc5f, 127

AccPedal_SustainOn_AltRoute:
	cpdi8 0x90f8, 127
	jr z, AccPedal_SustainOn_Return
	anddi8 0x3470, 251

AccPedal_SustainOn_Return:
	ret

AccPedal_SustainOff_Padding:
	nop
	nop

AccPedal_SustainOff:
	bitda 2, 0x3470
	jr z, AccPedal_SustainOff_Clear
	anddi8 0x3470, 251

AccPedal_SustainOff_Clear:
	cpdi8 0x90f8, 127
	jr z, AccPedal_SustainOff_Return
	anddi8 0xfc5f, 251

AccPedal_SustainOff_Return:
	ret

AccPedal_ExprOn_Padding:
	nop
	nop

AccPedal_ExprOn:
	bitda 0, 0x3470
	jrl nz, AccPedal_ExprOn_AltRoute
	ordi8 0x3470, 1
	bitda 2, 0xfc60
	jr nz, AccPedal_ExprOn_SetMask
	ordi8 0xfc60, 4
	ordi8 0x3486, 4
	ordi8 0x3484, 4
	jr AccPedal_ExprOn_Update64607

AccPedal_ExprOn_SetMask:
	cpdi8 0x90f8, 127
	jr nz, AccPedal_ExprOn_Update64607
	anddi8 0xfc60, 251
	anddi8 0x3486, 251
	anddi8 0x3484, 251

AccPedal_ExprOn_Update64607:
	ordi8 0x3485, 4
	ordi8 0x3487, 4
	bitda 3, 0xfc5f
	jr z, AccPedal_ExprOn_Post
	anddi8 0xfc5f, 247
	anddi8 0x3480, 247
	ordi8 0x3481, 8
	anddi8 0x3482, 247
	ordi8 0x3483, 8

AccPedal_ExprOn_Post:
	bitda 2, 0xfc5f
	jr z, AccPedal_ExprOn_Finalize
	anddi8 0xfc5f, 251
	anddi8 0x3480, 251
	ordi8 0x3481, 4
	anddi8 0x3482, 251
	ordi8 0x3483, 4

AccPedal_ExprOn_Finalize:
	bitda 6, 0xfc5f
	jr z, AccPedal_ExprOn_CheckAlt
	anddi8 0xfc5f, 191

AccPedal_ExprOn_CheckAlt:
	bitda 7, 0xfc5f
	jr z, AccPedal_ExprOn_AltRoute
	anddi8 0xfc5f, 127

AccPedal_ExprOn_AltRoute:
	cpdi8 0x90f8, 127
	jr z, AccPedal_ExprOn_Return
	anddi8 0x3470, 254

AccPedal_ExprOn_Return:
	ret

AccPedal_ExprOff_Padding:
	nop
	nop

AccPedal_ExprOff:
	bitda 0, 0x3470
	jr z, AccPedal_ExprOff_Clear
	anddi8 0x3470, 254

AccPedal_ExprOff_Clear:
	cpdi8 0x90f8, 127
	jr z, AccPedal_ExprOff_Return
	anddi8 0xfc60, 251

AccPedal_ExprOff_Return:
	ret

AccPedal_SostenutoOn_Padding:
	nop
	nop

AccPedal_SostenutoOn:
	bitda 4, 0x3470
	jrl nz, AccPedal_SostenutoOn_Return
	ordi8 0x3470, 16
	ordi8 0xfc5f, 16
	ordi8 0x3481, 16
	ordi8 0x3480, 16
	ordi8 0x3483, 16
	ordi8 0x3482, 16
	bitda 5, 0xfc5f
	jr z, AccPedal_SostenutoOn_SetMask
	anddi8 0xfc5f, 223

AccPedal_SostenutoOn_SetMask:
	bitda 6, 0xfc5f
	jr z, AccPedal_SostenutoOn_Update
	anddi8 0xfc5f, 191

AccPedal_SostenutoOn_Update:
	bitda 7, 0xfc5f
	jr z, AccPedal_SostenutoOn_Post
	anddi8 0xfc5f, 127

AccPedal_SostenutoOn_Post:
	bitda 2, 0xfc5f
	jr z, AccPedal_SostenutoOn_Finalize
	anddi8 0xfc5f, 251
	ordi8 0x3483, 4
	anddi8 0x3482, 251
	ordi8 0x3481, 4
	anddi8 0x3480, 251

AccPedal_SostenutoOn_Finalize:
	bitda 3, 0xfc5f
	jr z, AccPedal_SostenutoOn_CheckAlt
	anddi8 0xfc5f, 247
	ordi8 0x3483, 8
	anddi8 0x3482, 247
	ordi8 0x3481, 8
	anddi8 0x3480, 247

AccPedal_SostenutoOn_CheckAlt:
	bitda 2, 0xfc60
	jr z, AccPedal_SostenutoOn_Return
	anddi8 0xfc60, 251
	ordi8 0x3487, 4
	anddi8 0x3486, 251
	ordi8 0x3485, 4
	anddi8 0x3484, 251

AccPedal_SostenutoOn_Return:
	ret

AccPedal_SostenutoOff_Padding:
	nop
	nop

AccPedal_SostenutoOff:
	bitda 4, 0x3470
	jr z, AccPedal_SostenutoOff_Return
	anddi8 0x3470, 239
	ordi8 0x3481, 16
	anddi8 0x3480, 239
	ordi8 0x3483, 16
	anddi8 0x3482, 239

AccPedal_SostenutoOff_Return:
	ret

AccPedal_SostenutoOff_Padding2:
	nop
	nop

AccPedal_SoftOn:
	bitda 5, 0x3470
	jrl nz, AccPedal_SoftOn_Return
	ordi8 0x3470, 32
	ordi8 0xfc5f, 32
	ordi8 0x3481, 32
	ordi8 0x3480, 32
	ordi8 0x3483, 32
	ordi8 0x3482, 32
	bitda 4, 0xfc5f
	jr z, AccPedal_SoftOn_SetMask
	anddi8 0xfc5f, 239

AccPedal_SoftOn_SetMask:
	bitda 6, 0xfc5f
	jr z, AccPedal_SoftOn_Update
	anddi8 0xfc5f, 191

AccPedal_SoftOn_Update:
	bitda 7, 0xfc5f
	jr z, AccPedal_SoftOn_Post
	anddi8 0xfc5f, 127

AccPedal_SoftOn_Post:
	bitda 2, 0xfc5f
	jr z, AccPedal_SoftOn_Finalize
	anddi8 0xfc5f, 251
	ordi8 0x3483, 4
	anddi8 0x3482, 251
	ordi8 0x3481, 4
	anddi8 0x3480, 251

AccPedal_SoftOn_Finalize:
	bitda 3, 0xfc5f
	jr z, AccPedal_SoftOn_CheckAlt
	anddi8 0xfc5f, 247
	ordi8 0x3483, 8
	anddi8 0x3482, 247
	ordi8 0x3481, 8
	anddi8 0x3480, 247

AccPedal_SoftOn_CheckAlt:
	bitda 2, 0xfc60
	jr z, AccPedal_SoftOn_Return
	anddi8 0xfc60, 251
	ordi8 0x3487, 4
	anddi8 0x3486, 251
	ordi8 0x3485, 4
	anddi8 0x3484, 251

AccPedal_SoftOn_Return:
	ret

AccPedal_SoftOff_Padding:
	nop
	nop

AccPedal_SoftOff:
	bitda 5, 0x3470
	jr z, AccPedal_SoftOff_Return
	anddi8 0x3470, 223
	ordi8 0x3481, 32
	anddi8 0x3480, 223
	ordi8 0x3483, 32
	anddi8 0x3482, 223

AccPedal_SoftOff_Return:
	ret

AccPedal_HoldOn_Padding:
	nop
	nop

AccPedal_HoldOn:
	bitda 6, 0x3470
	jrl nz, AccPedal_HoldOn_Return
	ordi8 0x3470, 64
	ordi8 0xfc5f, 64
	ordi8 0x3481, 64
	ordi8 0x3480, 64
	ordi8 0x3483, 64
	ordi8 0x3482, 64
	bitda 4, 0xfc5f
	jr z, AccPedal_HoldOn_SetMask
	anddi8 0xfc5f, 239

AccPedal_HoldOn_SetMask:
	bitda 5, 0xfc5f
	jr z, AccPedal_HoldOn_Update
	anddi8 0xfc5f, 223

AccPedal_HoldOn_Update:
	bitda 2, 0xfc5f
	jr z, AccPedal_HoldOn_Post
	anddi8 0xfc5f, 251
	ordi8 0x3483, 4
	anddi8 0x3482, 251
	ordi8 0x3481, 4
	anddi8 0x3480, 251

AccPedal_HoldOn_Post:
	bitda 3, 0xfc5f
	jr z, AccPedal_HoldOn_Finalize
	anddi8 0xfc5f, 247
	ordi8 0x3483, 8
	anddi8 0x3482, 247
	ordi8 0x3481, 8
	anddi8 0x3480, 247

AccPedal_HoldOn_Finalize:
	bitda 2, 0xfc60
	jr z, AccPedal_HoldOn_CheckAlt
	anddi8 0xfc60, 251
	ordi8 0x3487, 4
	anddi8 0x3486, 251
	ordi8 0x3485, 4
	anddi8 0x3484, 251

AccPedal_HoldOn_CheckAlt:
	bitda 7, 0xfc5f
	jr z, AccPedal_HoldOn_Return
	anddi8 0xfc5f, 127

AccPedal_HoldOn_Return:
	ret

AccPedal_HoldOff_Padding:
	nop
	nop

AccPedal_HoldOff:
	bitda 6, 0x3470
	jr z, AccPedal_HoldOff_Return
	anddi8 0x3470, 191
	ordi8 0x3481, 64
	anddi8 0x3480, 191
	ordi8 0x3483, 64
	anddi8 0x3482, 191

AccPedal_HoldOff_Return:
	ret

AccPedal_HoldOff_Padding2:
	nop
	nop

AccPedal_DamperOn:
	bitda 3, 0x3470
	jrl nz, AccPedal_DamperOn_FinalCheck
	ordi8 0x3470, 8
	bitda 3, 0xfc5f
	jr nz, AccPedal_DamperOn_SetMask
	ordi8 0xfc5f, 8
	ordi8 0x3482, 8
	ordi8 0x3480, 8
	jr AccPedal_DamperOn_Update

AccPedal_DamperOn_SetMask:
	cpdi8 0x90f8, 127
	jr nz, AccPedal_DamperOn_Update
	anddi8 0xfc5f, 247
	anddi8 0x3482, 247
	anddi8 0x3480, 247

AccPedal_DamperOn_Update:
	ordi8 0x3481, 8
	ordi8 0x3483, 8
	bitda 2, 0xfc5f
	jr z, AccPedal_DamperOn_Post
	anddi8 0xfc5f, 251
	anddi8 0x3480, 251
	ordi8 0x3481, 4
	anddi8 0x3482, 251
	ordi8 0x3483, 4

AccPedal_DamperOn_Post:
	bitda 2, 0xfc60
	jr z, AccPedal_DamperOn_Finalize
	anddi8 0xfc60, 251
	anddi8 0x3484, 251
	ordi8 0x3485, 4
	anddi8 0x3486, 251
	ordi8 0x3487, 4

AccPedal_DamperOn_Finalize:
	bitda 6, 0xfc5f
	jr z, AccPedal_DamperOn_CheckAlt
	anddi8 0xfc5f, 191

AccPedal_DamperOn_CheckAlt:
	bitda 7, 0xfc5f
	jr z, AccPedal_DamperOn_AltRoute
	anddi8 0xfc5f, 127

AccPedal_DamperOn_AltRoute:
	bitda 4, 0xfc5f
	jr z, AccPedal_DamperOn_Apply
	anddi8 0xfc5f, 239

AccPedal_DamperOn_Apply:
	bitda 5, 0xfc5f
	jr z, AccPedal_DamperOn_FinalCheck
	anddi8 0xfc5f, 223

AccPedal_DamperOn_FinalCheck:
	cpdi8 0x90f8, 127
	jr z, AccPedal_DamperOn_Return
	anddi8 0x3470, 247

AccPedal_DamperOn_Return:
	ret

AccPedal_DamperOff_Padding:
	nop
	nop

AccPedal_DamperOff:
	bitda 3, 0x3470
	jr z, AccPedal_DamperOff_Clear
	anddi8 0x3470, 247

AccPedal_DamperOff_Clear:
	cpdi8 0x90f8, 127
	jr z, AccPedal_DamperOff_Return
	anddi8 0xfc5f, 247

AccPedal_DamperOff_Return:
	ret

AccPedal_DamperOff_Padding2:
	nop
	nop

AccPedal_PortamentoOn:
	bitda 7, 0x3470
	jrl nz, AccPedal_PortamentoOn_Return
	ordi8 0x3470, 128
	ordi8 0xfc5f, 128
	ordi8 0x3481, 128
	ordi8 0x3480, 128
	ordi8 0x3483, 128
	ordi8 0x3482, 128
	bitda 4, 0xfc5f
	jr z, AccPedal_PortamentoOn_SetMask
	anddi8 0xfc5f, 239

AccPedal_PortamentoOn_SetMask:
	bitda 5, 0xfc5f
	jr z, AccPedal_PortamentoOn_Update
	anddi8 0xfc5f, 223

AccPedal_PortamentoOn_Update:
	bitda 2, 0xfc5f
	jr z, AccPedal_PortamentoOn_Post
	anddi8 0xfc5f, 251
	ordi8 0x3483, 4
	anddi8 0x3482, 251
	ordi8 0x3481, 4
	anddi8 0x3480, 251

AccPedal_PortamentoOn_Post:
	bitda 3, 0xfc5f
	jr z, AccPedal_PortamentoOn_Finalize
	anddi8 0xfc5f, 247
	ordi8 0x3483, 8
	anddi8 0x3482, 247
	ordi8 0x3481, 8
	anddi8 0x3480, 247

AccPedal_PortamentoOn_Finalize:
	bitda 2, 0xfc60
	jr z, AccPedal_PortamentoOn_CheckAlt
	anddi8 0xfc60, 251
	ordi8 0x3487, 4
	anddi8 0x3486, 251
	ordi8 0x3485, 4
	anddi8 0x3484, 251

AccPedal_PortamentoOn_CheckAlt:
	bitda 6, 0xfc5f
	jr z, AccPedal_PortamentoOn_Return
	anddi8 0xfc5f, 191

AccPedal_PortamentoOn_Return:
	ret

AccPedal_PortamentoOff_Padding:
	nop
	nop

AccPedal_PortamentoOff:
	bitda 7, 0x3470
	jr z, AccPedal_PortamentoOff_Return
	anddi8 0x3470, 127
	ordi8 0x3481, 128
	anddi8 0x3480, 127
	ordi8 0x3483, 128
	anddi8 0x3482, 127

AccPedal_PortamentoOff_Return:
	ret

AccPedal_PortamentoOff_Padding2:
	nop
	nop

AccAutoPlay_NoteDispatch:
	ld w, a
	ld a, c
	cpdi8 0x7f0b, 0
	jr nz, AccAutoPlay_NoteDispatch_Process
	pushw wa
	calr AccPedal_StyleCheck
	cps a, 1
	popw wa
	jr z, AccAutoPlay_NoteDispatch_Process
	bitda 2, 0x28a7
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
	ordi8 0x3498, 1

AccAutoPlay_NoteDispatch_Check:
	ordi8 0x3498, 128

AccAutoPlay_NoteDispatch_Process:
	cpdi16 0x28a8, 0
	jr z, AccAutoPlay_NoteDispatch_Return
	bitda 2, 1054
	jr nz, AccAutoPlay_NoteDispatch_Return
	bitda 1, 0xfc5f
	jr z, AccAutoPlay_NoteDispatch_Return
	bitda 3, 0x28b3
	jr z, AccAutoPlay_NoteDispatch_Return
	bitda 0, 0x28b2
	jr nz, AccAutoPlay_NoteDispatch_Return
	bitda 2, 0x28b1
	jr nz, AccAutoPlay_NoteDispatch_Return
	bitda 0, 0x3498
	jr z, AccAutoPlay_NoteDispatch_Return
	anddi8 0x28b3, 247
	call Audio_CheckSubsystemReady

AccAutoPlay_NoteDispatch_Return:
	ret

AccAutoPlay_SplitDetect:
	ldb c, 0x0
	cpdi16 0x28a8, 0
	jr z, AccAutoPlay_SplitDetect_Check
	bitda 3, 0x28b3
	jr z, AccAutoPlay_SplitDetect_Check
	bitda 0, 0x28b2
	jr nz, AccAutoPlay_SplitDetect_Return
	bitda 2, 0x28b1
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
	bitda 0, 0xfd53
	jr nz, AccAutoPlay_SplitDetect_NoSplit
	and w, 0xf
	ldb_d8 l, 0xf9c3
	and l, 0xf
	cp l, w
	jr z, AccAutoPlay_SplitDetect_Lower
	ldb_d8 l, 0xfbe5
	bit 7, l
	jr nz, AccAutoPlay_SplitDetect_Apply
	and l, 0xf
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
	and w, 0xf
	ldb_d8 l, 0xf9f7
	bit 7, l
	jr nz, AccAutoPlay_SplitDetect_Store
	and l, 0xf
	cp l, w
	jr nz, AccAutoPlay_SplitDetect_Store
	ldb c, 0x1
	jr AccAutoPlay_SplitDetect_Return

AccAutoPlay_SplitDetect_Store:
	ldb_d8 l, 0xfbe5
	bit 7, l
	jr nz, AccAutoPlay_SplitDetect_Return
	and l, 0xf
	cp l, w
	jr nz, AccAutoPlay_SplitDetect_Return
	ldb c, 0x1

AccAutoPlay_SplitDetect_Return:
	ret

AccAutoPlay_ZoneTrack:
	cpdi8 0x7f0b, 0
	jr nz, AccAutoPlay_ZoneTrack_Update
	pushw wa
	calr AccPedal_StyleCheck
	cps a, 1
	popw wa
	jr z, AccAutoPlay_ZoneTrack_Update
	bitda 2, 0x28a7
	jr nz, AccAutoPlay_ZoneTrack_Update
	calr AccAutoPlay_ZoneTrack_Apply
	ldw_d16 xhl, 0x349c
	stda16 0x349a, xhl
	stda16 0x349c, xwa

AccAutoPlay_ZoneTrack_Update:
	ret

AccAutoPlay_ZoneTrack_Apply:
	ld xix, 0xceff
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
	ldb l, 0xf0

AccAutoPlay_ZoneTrack_Store:
	ld w, l
	calr AccAutoPlay_ZoneTrack_SetFlag
	stdi16 0x38e8, 0
	ld bc, (xix + 256)
	ldb e, 0x5

AccAutoPlay_ZoneTrack_Clear:
	cps bc, 0
	jr z, AccAutoPlay_ZoneTrack_Default
	ldb_sri A, 0x03, 0xf0, 0xe8
	cp l, a
	jr c, AccAutoPlay_ZoneTrack_Finalize
	incdi16 1, 0x38e8

AccAutoPlay_ZoneTrack_Finalize:
	inc 2, e
	dec 1, bc
	jr AccAutoPlay_ZoneTrack_Clear

AccAutoPlay_ZoneTrack_Default:
	ldw_d16 xwa, 0x38e8
	ret

AccAutoPlay_ZoneTrack_SetFlag:
	ldb c, 0x0
	bit 7, w
	jr z, AccAutoPlay_ZoneTrack_Done
	calr AccAutoPlay_ModeAvail
	jr AccAutoPlay_ZoneTrack_Return2

AccAutoPlay_ZoneTrack_Done:
	bitda 0, 0xfd53
	jr nz, AccAutoPlay_ZoneTrack_Final
	calr AccAutoPlay_ModeAvail
	jr AccAutoPlay_ZoneTrack_Return2

AccAutoPlay_ZoneTrack_Final:
	ldb l, 0x7f

AccAutoPlay_ZoneTrack_Return2:
	ret

AccAutoPlay_ZoneTrack_Return:
	ret

AccAutoPlay_StateMachine:
	calr AccAutoPlay_TriggerCheck
	bitda 6, 0x346e
	jr z, AccAutoPlay_SM_CheckEligible
	cpdi16 0xf19e, 0
	jr z, AccAutoPlay_SM_CheckEligible
	cpdi16 0x28a8, 0
	jr nz, AccAutoPlay_SM_CheckEligible
	calr AccAutoPlay_SetConfig
	bitda 7, 0x346d
	jr nz, AccAutoPlay_SM_CheckEligible
	calr AccAutoPlay_Disable

AccAutoPlay_SM_CheckEligible:
	stdi8 0x3474, 0
	calr AccAutoPlay_ActionDispatch
	bitda 0, 0x3474
	jr z, AccAutoPlay_SM_Return
	stdi8 0x3474, 0
	ordi8 0x346e, 4
	calr AccReplay_FullRestart

AccAutoPlay_SM_Return:
	ret

AccAutoPlay_SM_Padding:
	nop
	nop

AccAutoPlay_TriggerCheck:
	bitda 2, 0x28a7
	jrl nz, AccAutoPlay_ModeAvail_Padding2
	calr AccAutoPlay_SetConfig
	bitda 0, 0x3498
	jrl z, AccAutoPlay_ModeAvail_Padding2
	bitda 0, 0x3499
	jrl nz, AccAutoPlay_Trigger_Activate
	bitda 7, 0x346d
	jr nz, AccAutoPlay_Trigger_Evaluate
	bitda 2, 1054
	jr nz, AccAutoPlay_Trigger_Process
	bitda 1, 0xfc5f
	jr z, AccAutoPlay_Trigger_Process

AccAutoPlay_Trigger_Evaluate:
	calr AccAutoPlay_Configure

AccAutoPlay_Trigger_Process:
	ordi8 0x3498, 1
	ordi8 0x3499, 1
	jr AccAutoPlay_ModeAvail_Padding

AccAutoPlay_Trigger_Activate:
	bitda 7, 0x3498
	jr nz, AccAutoPlay_ModeAvail_Padding
	bitda 7, 0x346d
	jr z, AccAutoPlay_Trigger_Return
	cpdi16 0x349c, 0
	jr nz, AccAutoPlay_Trigger_Configure
	cpdi16 0x349a, 0
	jr z, AccAutoPlay_Trigger_Configure
	calr AccAutoPlay_SeqHandoff
	anddi8 0x3498, 254
	anddi8 0x3499, 254
	stdi16 0x349a, 0
	jr AccAutoPlay_ModeAvail_Padding

AccAutoPlay_Trigger_Configure:
	cpdi16 0x349c, 0
	jr nz, AccAutoPlay_Trigger_Finalize
	cpdi16 0x349a, 0
	jr nz, AccAutoPlay_Trigger_Finalize
	stdi8 0x3498, 0
	stdi8 0x3499, 0

AccAutoPlay_Trigger_Finalize:
	jr AccAutoPlay_ModeAvail_Padding

AccAutoPlay_Trigger_Return:
	anddi8 0x3498, 254
	anddi8 0x3499, 254
	jr AccAutoPlay_ModeAvail_Padding

AccAutoPlay_ModeAvail_Padding:
	anddi8 0x3498, 127

AccAutoPlay_ModeAvail_Padding2:
	ret

AccAutoPlay_ModeAvail_Padding3:
	nop
	nop

AccAutoPlay_ModeAvail:
	ldb_d8 l, 0xfd02
	and l, 0x3
	cps l, 0
	jr nz, AccAutoPlay_ModeAvail_Process
	ldb_d8 l, 0xfd03
	and l, 0x7f
	dec 1, l
	cp l, 0xff
	jr nz, AccAutoPlay_ModeAvail_Check
	ldb l, 0x0

AccAutoPlay_ModeAvail_Check:
	jr AccAutoPlay_ModeAvail_SetMode

AccAutoPlay_ModeAvail_Process:
	push l
	lds32 xhl, 0
	pop l
	add xhl, AccAutoPlay_ModeAvail_Extended_0x2
	ld l, (xhl)

AccAutoPlay_ModeAvail_SetMode:
	cpdi8 0x8d34, 14
	jr nz, AccAutoPlay_ModeAvail_Return
	ldb l, 0x7f

AccAutoPlay_ModeAvail_Return:
	ret

AccAutoPlay_ModeAvail_Extended:
	nop
	nop
	push	xhl
	ldw	iz, 0x423b
	ld	xsp, 0xca041ef1
	jr	nz, 34
	.byte 0xf1
	jr	nz, 52
	inc	6, a
	.byte 0x1c, 0xf1
	and	(xwa+52), wa
	jr	z, 22
	.byte 0xf1
	and	(xbc+52), wa
	jr	nz, 16
	calr	72
	ldb_d8	a, 0x3498
	stb_d8	0x3499, a
	.byte 0xc1, 0x98
	ldw	ix, 318
	ret

AccAutoPlay_SetConfig:
	cpdi16 0x28a8, 0
	jr nz, AccAutoPlay_SetConfig_Apply
	cpdi16 0xf19e, 0
	jr nz, AccAutoPlay_SetConfig_Apply
	cpdi8 0x379b, 0
	jr nz, AccAutoPlay_SetConfig_Apply
	ldb_d8 a, 0xfc5d
	bit 3, a
	jr nz, AccAutoPlay_SetConfig_Apply
	and a, 0x7
	cps a, 0
	jr z, AccAutoPlay_SetConfig_Apply
	bitda 1, 0xfc5f
	jr z, AccAutoPlay_SetConfig_Apply
	ordi8 0x346d, 128
	jr AccAutoPlay_SetConfig_Return

AccAutoPlay_SetConfig_Apply:
	stdi8 0x346d, 0

AccAutoPlay_SetConfig_Return:
	ret

AccAutoPlay_Configure:
	anddi8 0x346e, 31
	cpdi8 0x379b, 0
	jr nz, AccAutoPlay_Configure_Mode1
	cpdi16 0x28a8, 0
	jr nz, AccAutoPlay_Configure_Mode2
	cpdi16 0xf19e, 0
	jr z, AccAutoPlay_Configure_Mode1
	jr AccAutoPlay_Configure_Store

AccAutoPlay_Configure_Mode1:
	ordi8 0x346e, 160
	calr AccAutoPlay_SubModeA
	jr AccAutoPlay_Configure_Return

AccAutoPlay_Configure_Mode2:
	cpdi16 0xf19e, 0
	jr nz, AccAutoPlay_Configure_Store
	bitda 2, 1056
	jr z, AccAutoPlay_Configure_Apply
	ordi8 0x346e, 128
	jr AccAutoPlay_Configure_Check

AccAutoPlay_Configure_Apply:
	ordi8 0x346e, 224

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
	bitda	1, 0x346e
	jr nz, AccAutoPlay_Configure_Final
	anddi8	0x3499, 254
	anddi8	0x3498, 254
	jr t, AccAutoPlay_Configure_Return2
AccAutoPlay_Configure_Final:
	bitda	0, 0x3498
	jr nz, AccAutoPlay_Configure_Return2
	bitda	0, 0x3499
	jr z, AccAutoPlay_Configure_Return2
	bitda	7, 0x346d
	jr z, AccAutoPlay_Configure_Done
	calr AccAutoPlay_SeqHandoff
AccAutoPlay_Configure_Done:
	.byte 0xc1, 0x99
	ldw	ix, 0xfe3c
	.byte 0xc1, 0x98
	ldw	ix, 0xfe3c
AccAutoPlay_Configure_Return2:
	ret
	nop
	nop


AccAutoPlay_PeriodicCheck:
	bitda 1, 0xfc5f
	jr nz, AccAutoPlay_Periodic_Evaluate
	jr AccAutoPlay_Periodic_Return

AccAutoPlay_Periodic_Evaluate:
	bitda 2, 0x346e
	jr z, AccAutoPlay_Periodic_Process
	calr AccAutoPlay_SetConfig
	bitda 7, 0x346d
	jr nz, AccAutoPlay_Periodic_Padding
	calr AccAutoPlay_Disable
	jr AccAutoPlay_Periodic_Padding

AccAutoPlay_Periodic_Padding:
	anddi8 0x346e, 251
	jr AccAutoPlay_Periodic_Return

AccAutoPlay_Periodic_Process:
	cpdi16 0xf19e, 0
	jr nz, AccAutoPlay_Periodic_Toggle
	cpdi16 0x28a8, 0
	jr z, AccAutoPlay_Periodic_Return

AccAutoPlay_Periodic_Toggle:
	calr AccAutoPlay_Disable

AccAutoPlay_Periodic_Return:
	ret

AccAutoPlay_Disable:
	anddi8 0xfc5f, 253
	ldb w, 0x2
	ldb a, 0x0
	ldb d, 0x5
	ldb e, 0x48
	call SwbtWr_QueuePostEvent
	ret

AccAutoPlay_Disable_Return:
	nop
	nop

AccAutoPlay_SubModeA:
	bitda 7, 0x346d
	jr z, AccAutoPlay_SubModeA_Return
	bitda 2, 1054
	jr nz, AccAutoPlay_SubModeA_Apply
	bitda 0, 0x3283
	jr z, AccAutoPlay_SubModeA_Check
	bitda 1, 0x3283
	jr z, AccAutoPlay_SubModeA_Check
	anddi8 0x346d, 239
	ordi8 0x346d, 1
	jr AccAutoPlay_SubModeA_Return

AccAutoPlay_SubModeA_Check:
	anddi8 0x346d, 239
	ordi8 0x346d, 4
	jr AccAutoPlay_SubModeA_Return

AccAutoPlay_SubModeA_Apply:
	ldb_d8 a, 1056
	bit 2, a
	jr z, AccAutoPlay_SubModeA_Return
	bit 3, a
	jr z, AccAutoPlay_SubModeA_Return
	anddi8 1056, 247
	anddi8 1054, 247
	anddi8 0x346d, 239
	ordi8 0x346d, 8

AccAutoPlay_SubModeA_Return:
	ret

AccAutoPlay_SubModeA_Padding:
	nop
	nop

AccAutoPlay_SubModeB:
	bitda 7, 0x346d
	jr z, AccAutoPlay_SubModeB_Return
	bitda 2, 1054
	jr nz, AccAutoPlay_SubModeB_Apply
	bitda 0, 0x3283
	jr z, AccAutoPlay_SubModeB_Check
	bitda 1, 0x3283
	jr z, AccAutoPlay_SubModeB_Check
	anddi8 0x346d, 239
	ordi8 0x346d, 2
	jr AccAutoPlay_SubModeB_Return

AccAutoPlay_SubModeB_Check:
	anddi8 0x346d, 239
	ordi8 0x346d, 4
	jr AccAutoPlay_SubModeB_Return

AccAutoPlay_SubModeB_Apply:
	ldb_d8 a, 1056
	bit 2, a
	jr z, AccAutoPlay_SubModeB_Return
	bit 3, a
	jr z, AccAutoPlay_SubModeB_Return
	anddi8 1056, 247
	anddi8 1054, 247
	anddi8 1057, 247
	anddi8 0x346d, 239
	ordi8 0x346d, 8

AccAutoPlay_SubModeB_Return:
	ret

AccAutoPlay_SubModeB_Padding:
	nop
	nop

AccAutoPlay_SeqHandoff:
	cpdi8 0x379b, 0
	jr nz, AccAutoPlay_SeqHandoff_Return
	cpdi16 0x28aa, 0
	jr nz, AccAutoPlay_SeqHandoff_Return
	bitda 2, 1054
	jr z, AccAutoPlay_SeqHandoff_Return
	anddi8 0x346d, 247
	ordi8 0x346d, 16
	cpdi16 0xf19e, 0
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
	nop
	nop

AccAutoPlay_ModeDecode:
	ldb_d8 a, 0x28a7
	and a, 0x3
	cps a, 2
	jr nz, AccAutoPlay_ModeDecode_Process
	ordi8 0x346e, 160
	jr AccAutoPlay_ModeDecode_Return

AccAutoPlay_ModeDecode_Process:
	cps a, 1
	jr nz, AccAutoPlay_ModeDecode_Apply
	ordi8 0x346e, 96
	jr AccAutoPlay_ModeDecode_Return

AccAutoPlay_ModeDecode_Apply:
	cps a, 3
	jr nz, AccAutoPlay_ModeDecode_Return
	ordi8 0x346e, 224

AccAutoPlay_ModeDecode_Return:
	ret

AccAutoPlay_ModeDecode_Padding:
	nop
	nop

AccAutoPlay_ActionDispatch:
	ldb_d8 a, 0x346d
	bit 7, a
	jr z, AccAutoPlay_Action_Check
	bitda 2, 0x346d
	jr z, AccAutoPlay_Action_Finalize
	and a, 0xfb
	or a, 0x8
	stb_d8 0x346d, a

AccAutoPlay_Action_Check:
	ldb_d8 a, 0x346e
	ld b, a
	and a, 0xe0
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
	bitda 3, 0x346d
	jr nz, AccAutoPlay_Action_Finalize

AccAutoPlay_Action_Finalize:
	anddi8 0x346e, 31

AccAutoPlay_Action_Return:
	ret

AccAutoPlay_Action_Padding:
	nop
	nop

AccAutoPlay_DeferredAction:
	bitda 7, 0x346d
	jr z, AccAutoPlay_Deferred_Return
	bitda 0, 0x346d
	jr z, AccAutoPlay_Deferred_Process
	anddi8 0x346d, 238
	ordi8 0x346d, 8
	ei 6
	calr AccPlayMode_StartAccPlayFull
	ei 0
	calr AccReplay_FullRestart
	jr AccAutoPlay_Deferred_Return

AccAutoPlay_Deferred_Process:
	bitda 1, 0x346d
	jr z, AccAutoPlay_Deferred_Return
	anddi8 0x346d, 237
	ordi8 0x346d, 8
	ei 6
	calr AccPlayMode_StartPlay
	ei 0
	calr AccReplay_FullRestart

AccAutoPlay_Deferred_Return:
	ret

AccAutoPlay_Deferred_Padding:
	nop
	nop

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
	ld xwa, AccPlayMode_Dispatch_Table_0x2
	add xhl, xwa
	ld xwa, (xhl)
	call (xwa)
	ei 0
	ret

AccPlayMode_Dispatch_Table:
	.byte 0x00, 0x00, 0x19, 0xae, 0xf5, 0x00, 0x4d, 0xaf
	.byte 0xf5, 0x00, 0xd0, 0xaf, 0xf5, 0x00, 0x04, 0xb0
	.byte 0xf5, 0x00, 0xb7, 0xaf, 0xf5, 0x00, 0x3c, 0xaf
	.byte 0xf5, 0x00, 0xb2, 0xaf, 0xf5, 0x00, 0x9d, 0xaf
	.byte 0xf5, 0x00, 0x0e, 0x00, 0x00

AccPlayMode_TransitionRouter:
	cpdi16 0x28a8, 0
	jr z, AccPlayMode_Router_Process
	cpdi16 0xf19e, 0
	jr z, AccPlayMode_Router_Check
	calr AccPlayMode_Router_Alt
	jr AccPlayMode_Router_Return

AccPlayMode_Router_Check:
	calr AccPlayMode_StartRecording
	jr AccPlayMode_Router_Return

AccPlayMode_Router_Process:
	cpdi16 0xf19e, 0
	jr z, AccPlayMode_Router_Apply
	calr AccPlayMode_StartAcc
	jr AccPlayMode_Router_Return

AccPlayMode_Router_Apply:
	calr AccPlayMode_StopToSync

AccPlayMode_Router_Return:
	ret

AccPlayMode_Router_Padding:
	nop
	nop

AccPlayMode_Router_Alt:
	bitda 2, 1056
	jr nz, AccPlayMode_Router_AltPadding
	calr AccPlayMode_StartPlay
	jr AccPlayMode_Router_AltPadding

AccPlayMode_Router_AltPadding:
	ret

AccPlayMode_StartRecording_Padding:
	nop
	nop

AccPlayMode_StartRecording:
	bitda 2, 1056
	jr nz, AccPlayMode_StartRec_Apply
	bitda 1, 0x28a7
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
	nop
	nop

AccPlayMode_StartAcc:
	bitda 2, 1056
	jr nz, AccPlayMode_StartAcc_Apply
	bitda 1, 0x28a7
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
	nop
	nop

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
	nop
	nop

AccPlayMode_StartPlay:
	bitda 2, 0x28a7
	jr nz, AccPlayMode_StartPlay_Return
	bitda 1, 0x28a7
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
	nop
	nop

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
	nop
	nop

AccPlayMode_StopExprB:
	bitda 0, 1056
	jr nz, AccPlayMode_StopExprB_Return
	bitda 2, 1056
	jr nz, AccPlayMode_StopExprB_Return
	bitda 2, 0x28b2
	jr nz, AccPlayMode_StopExprB_Process
	bitda 1, 0x28b2
	jr z, AccPlayMode_StopExprB_Process
	call SeqPlay_SetBarAndResetScroll
	stdi8 1054, 128
	ordi8 0x28b2, 4
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
	ordi8 0x3474, 1
	calr AccTempo_ClearPositions
	ldb a, 0x85
	calr AccTempo_WriteStartMarker

AccPlayMode_StartAccPlay_Return:
	ret

AccPlayMode_StartAccPlay_Padding:
	nop
	nop

AccPlayMode_StopToSync2:
	bitda 3, 1056
	jr nz, AccPlayMode_StartPlay2
	bitda 2, 1056
	jr z, AccPlayMode_StartPlay2
	stdi8 1056, 12

AccPlayMode_StartPlay2:
	stdi8 1054, 12
	stdi8 0x3470, 0
	ldb a, 0x86
	calr AccTempo_WriteStartMarker
	ret

AccPlayMode_StartPlay2_Padding:
	nop
	nop

AccPlayMode_StartPlayFull:
	bitda 2, 0x28b2
	jr nz, AccPlayMode_StartPlayFull_Process
	bitda 1, 0x28b2
	jr z, AccPlayMode_StartPlayFull_Process
	call SeqPlay_SetBarAndResetScroll
	stdi8 1054, 128
	ordi8 0x28b2, 4
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
	nop
	nop

AccPlayMode_StopExprFull:
	stdi8 1054, 12
	bitda 0, 0x28b2
	jr nz, AccPlayMode_StopExprFull_Process
	ordi8 0x347a, 4

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
	stdi8 0x3470, 0
	ret

AccPlayMode_StopExprC_Return:
	nop
	nop

AccPlayMode_StopExprD:
	stdi8 1057, 12
	ret

AccPlayMode_StopExprD_Return:
	nop
	nop

AccPlayMode_StartAccPlayFull:
	stdi8 1054, 1
	ordi8 0x3474, 1
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
	.byte 0xc1
	jrl	f, 15412
	retd	0x8621
	calr	108
	ret
	nop
	nop

AccTempo_ClearCounters:
	xor wa, wa
	ei 6
	stb_d8 1047, a
	stda16 1048, xwa
	ei 0
	ret

AccTempo_ClearPositions:
	xor wa, wa
	ei 6
	bitda 0, 0x28a6
	jr nz, AccTempo_ClearPositions_Loop
	stb_d8 1045, a
	stb_d8 1046, a

AccTempo_ClearPositions_Loop:
	stb_d8 1076, a
	stb_d8 1077, a
	ei 0
	anddi8 0x28a6, 254
	ret

AccTempo_ClearSubPos:
	xor wa, wa
	ei 6
	bitda 3, 0x28a7
	jr nz, AccTempo_ClearSubPos_Loop
	stda16 1052, xwa
	stb_d8 1051, a

AccTempo_ClearSubPos_Loop:
	ei 0
	ret

AccSync_MidiClock:
	bitda 2, 0xfd52
	jr z, AccSync_MidiClock_Return
	ei 6
	bitda 3, 0x28a7
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
	nop
	nop

AccTempo_WriteStartMarker:
	cpdi16 0x28aa, 0
	jr z, AccTempo_WriteMarker_Return

AccTempo_WriteStopMarker:
	ei 6
	pushw wa
	call TempoRingBuf_WriteByte_Ext
	inc 2, xsp
	ldb_d8 a, 1051
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
	stdi8 0x3474, 0
	ordi8 0x3491, 1
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
	anddi8 0x3491, 254
	ret

AccReplay_Restart_Return:
	nop
	nop

AccTiming_AlignTo8Tick:
	pushw hl
	ldw bc, 0x8
	ldw_d16 xwa, 1033
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
	nop
	nop

AccTempo_CheckSource:
	cpdi8 1115, 1
	jr nz, AccTempo_CheckSource_Process
	cpdi8 0xcedf, 0
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
	nop
	nop

AccReplay_SavedPedal:
	ldb_d8 a, 0xc07d
	pushw wa
	ldb_d8 w, 0xc07e
	ldb_d8 a, 0xc07f
	pushw wa
	ldb_d8 a, 0x3488
	stb_d8 0xc07d, a
	ldb_d8 a, 0x3475
	stb_d8 0xc07e, a
	ldb_d8 a, 0x3476
	stb_d8 0xc07f, a
	ldb_d8 a, 0x90f8
	pushw wa
	stdi8 0x90f8, 0
	calr AccPedal_EventDispatch
	popw wa
	stb_d8 0x90f8, a
	popw wa
	stb_d8 0xc07e, w
	stb_d8 0xc07f, a
	popw wa
	stb_d8 0xc07d, a
	xor a, a
	stb_d8 0x3475, a
	stb_d8 0x3476, a
	stb_d8 0x3488, a
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
	nop
	nop

AccReplay_SendPedalType5:
	push xiz
	calr AccReplay_SendPedalType6
	pop xiz
	ret

AccReplay_SendPedalType6:
	ld hl, wa
	ldb_d8 a, 0xc07d
	pushw wa
	ldb_d8 w, 0xc07e
	ldb_d8 a, 0xc07f
	pushw wa
	cps l, 0
	jr nz, AccReplay_SendPedal_Process
	stdi8 0xc07d, 5
	stdi8 0xc07e, 4
	stdi8 0xc07f, 4
	jr AccReplay_SendPedal_Dispatch

AccReplay_SendPedal_Process:
	stdi8 0xc07d, 6
	stdi8 0xc07e, 4
	stdi8 0xc07f, 4

AccReplay_SendPedal_Dispatch:
	ldb_d8 a, 0x90f8
	pushw wa
	stdi8 0x90f8, 0
	calr AccPedal_EventDispatch
	popw wa
	stb_d8 0x90f8, a
	popw wa
	stb_d8 0xc07e, w
	stb_d8 0xc07f, a
	popw wa
	stb_d8 0xc07d, a
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
	nop
	nop

AccReplay_SavedExpression:
	ldb_d8 a, 0xc07d
	pushw wa
	ldb_d8 w, 0xc07e
	ldb_d8 a, 0xc07f
	pushw wa
	ldb_d8 a, 0x3489
	stb_d8 0xc07d, a
	ldb_d8 a, 0x347c
	stb_d8 0xc07e, a
	ldb_d8 a, 0x347d
	stb_d8 0xc07f, a
	ldb_d8 a, 0x90f8
	pushw wa
	stdi8 0x90f8, 255
	calr AccPedal_EventDispatch
	popw wa
	stb_d8 0x90f8, a
	popw wa
	stb_d8 0xc07e, w
	stb_d8 0xc07f, a
	popw wa
	stb_d8 0xc07d, a
	xor a, a
	stb_d8 0x347c, a
	stb_d8 0x347d, a
	stb_d8 0x3489, a
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
	ld	xwa, 0x094800
	add	xwa, 14
	ld	wa, (xwa)
	cps	wa, 0
	jr	z, 4
	call	AccDemo_InitDone
	ret
	nop
	nop

AccReplay_FullStop:
	ldb_d8 a, 0xfc5f
	and a, 0xc
	ldb_d8 c, 0xfc60
	and c, 0x4
	or a, c
	cps a, 0
	jr z, AccReplay_Stop_ClearPedals
	anddi8 0xfc5f, 243
	lds wa, 0
	ldb d, 0x5
	ldb e, 0x48
	call SwbtWr_QueuePostEvent
	anddi8 0xfc60, 251
	lds wa, 0
	ldb d, 0x6
	ldb e, 0x48
	call SwbtWr_QueuePostEvent

AccReplay_Stop_ClearPedals:
	call Seq_DispatcherEntry
	cpdi8 0x3479, 0
	jr z, AccReplay_Stop_ResetPosition
	ldb_d8 a, 0x3479
	adddm8 1079, a
	stdi8 0x3479, 0

AccReplay_Stop_ResetPosition:
	anddi8 1079, 7
	ldb_d8 a, 1079
	cpda8 a, 1075
	jr c, AccReplay_Stop_Rebuild
	subda8 a, 1075
	stb_d8 1079, a
	ldb_d8 a, 1075
	stb_d8 0x3479, a

AccReplay_Stop_Rebuild:
	xor wa, wa
	stb_d8 1045, a
	stb_d8 1046, a
	ordi8 0x34cd, 128
	ordi8 0x347a, 1
	ldb_d8 e, 1078
	ldb_d8 d, 1079
	cps de, 0
	jr z, AccReplay_Stop_Finalize
	sub e, 0x18
	jr nc, AccReplay_Stop_CheckMode
	add e, 0x60
	dec 1, d
	cp d, 0xff
	jr nz, AccReplay_Stop_CheckMode
	lds de, 0

AccReplay_Stop_CheckMode:
	xor bc, bc
	anddi8 0x347a, 127

AccReplay_Stop_Process:
	stb_d8 1045, c
	stb_d8 1046, b
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
	bitda 7, 0x347a
	jr nz, AccReplay_Stop_Finalize
	cp bc, de
	jr c, AccReplay_Stop_Process
	ordi8 0x347a, 128
	cp bc, de
	jr z, AccReplay_Stop_Process
	ld bc, de
	jr AccReplay_Stop_Process

AccReplay_Stop_Finalize:
	ldb_d8 a, 1078
	stb_d8 1045, a
	ldb_d8 a, 1079
	stb_d8 1046, a
	anddi8 0x347a, 254
	call Seq_DispatcherEntry
	ret

AccReplay_Stop_Return:
	nop
	nop

AccPos_SaveOnStop:
	ldb_d8 a, 0xc07f
	cps a, 0
	jr z, AccPos_SaveOnStop_Return
	bitda 0, 0x28a6
	jr z, AccPos_SaveOnStop_Return
	ei 6
	ldb_d8 a, 1045
	stb_d8 1078, a
	ldb_d8 a, 1046
	stb_d8 1079, a
	xor wa, wa
	stb_d8 1045, a
	stb_d8 1046, a
	ei 0
	calr AccReplay_FullStop

AccPos_SaveOnStop_Return:
	ret

AccPos_SaveOnStop_Padding:
	nop
	nop

AccPos_ClearOnStart:
	bitda 0, 0x3283
	jr nz, AccPos_ClearOnStart_Return
	xor wa, wa
	ei 6
	stb_d8 1045, a
	stb_d8 1046, a
	ei 0
	stb_d8 1078, a
	stb_d8 1079, a
	stb_d8 0x3479, a
	ordi8 0x34cd, 128
	call Seq_DispatcherEntry

AccPos_ClearOnStart_Return:
	ret

AccPos_ClearOnStart_Padding:
	nop
	nop
	.byte 0xc1
	ldw	ix, 0x3f8d
	zcf
	jr	nz, 12
	.byte 0xc1
	jrl	gt, 15412
	swi	5
	.byte 0xc1, 0xa6
	pushw	wa
	push	xix
	swi	6
	jr	30
	.byte 0xf1
	jrl	gt, -14028
	jr	z, 24
	ldb_d8	a, 0x3283
	and	a, 3
	cps	a, 0
	jr	nz, 13
	stdi8	0x3479, 0
	calr	65158
	.byte 0xc1
	jrl	gt, 15412
	swi	5
	ret
	nop
	nop

AccFlags_SyncTo64607:
	ldb_d8 e, 1056
	anddi8 0xfc5f, 254
	bit 2, e
	jr z, AccFlags_Sync_Process
	ordi8 0xfc5f, 1

AccFlags_Sync_Process:
	ld a, e
	xorda8 a, 0x347b
	bit 2, a
	jr z, AccFlags_Sync_UpdateLED
	ldb a, 0x22
	call CtrlPanel_SetIndicatorBit

AccFlags_Sync_UpdateLED:
	stb_d8 0x347b, e
	bitda 0, 0x349e
	jr z, AccFlags_Sync_Return
	anddi8 0x349e, 254

AccFlags_Sync_Return:
	ret

AccFlags_Sync_Padding:
	nop
	nop

AccTiming_InitAllParts:
	stdi16 0x3374, 0xff5f
	stdi16 0x337c, 6
	stdi16 0x337e, 48
	ld xbc, 0x3094
	calr AccKbdTiming_TableScan
	ld xbc, 0x30c4
	calr AccKbdTiming_TableScan
	stdi16 0x337c, 9
	stdi16 0x337e, 72
	stdi8 0x338c, 7
	ld xbc, 0x30f4
	calr AccAccTiming_TableScan
	stdi8 0x338c, 4
	ld xbc, 0x313c
	calr AccAccTiming_TableScan
	stdi8 0x338c, 5
	ld xbc, 0x3184
	calr AccAccTiming_TableScan
	stdi8 0x338c, 6
	ld xbc, 0x31cc
	calr AccAccTiming_TableScan
	ldw_d16 xwa, 0x3374
	stda16 0x3372, xwa
	jr AccTiming_MasterTick_Return

AccTiming_MasterTick_Return:
	ret

AccTiming_MasterTick:
	stdi8 0x3377, 95
	stdi16 0x337c, 6
	stdi16 0x337e, 48
	ldb_d8 a, 0x3385
	stb_d8 0x3384, a
	ld xhl, 0x2a94
	ld xbc, 0x3094
	calr AccKbdTiming_ScanRingBuf
	ldb_d8 a, 0x3384
	stb_d8 0x3385, a
	ldb_d8 a, 0x3386
	stb_d8 0x3384, a
	ld xhl, 0x2b94
	ld xbc, 0x30c4
	calr AccKbdTiming_ScanRingBuf
	ldb_d8 a, 0x3384
	stb_d8 0x3386, a
	stdi16 0x337c, 9
	anddi8 0x338d, 254
	stdi16 0x337e, 72
	stdi8 0x338c, 7
	ldb_d8 a, 0x3387
	stb_d8 0x3384, a
	ldb_d8 a, 0x332f
	stb_d8 0x3333, a
	ld xhl, 0x2c94
	ld xbc, 0x30f4
	calr AccAccTiming_ScanRingBuf
	ldb_d8 a, 0x3384
	stb_d8 0x3387, a
	ldb_d8 a, 0x3333
	stb_d8 0x332f, a
	stdi8 0x338c, 4
	ldb_d8 a, 0x3388
	stb_d8 0x3384, a
	ldb_d8 a, 0x3330
	stb_d8 0x3333, a
	ld xhl, 0x2d94
	ld xbc, 0x313c
	calr AccAccTiming_ScanRingBuf
	ldb_d8 a, 0x3384
	stb_d8 0x3388, a
	ldb_d8 a, 0x3333
	stb_d8 0x3330, a
	stdi8 0x338c, 5
	ldb_d8 a, 0x3389
	stb_d8 0x3384, a
	ldb_d8 a, 0x3331
	stb_d8 0x3333, a
	ld xhl, 0x2e94
	ld xbc, 0x3184
	calr AccAccTiming_ScanRingBuf
	ldb_d8 a, 0x3384
	stb_d8 0x3389, a
	ldb_d8 a, 0x3333
	stb_d8 0x3331, a
	stdi8 0x338c, 6
	ldb_d8 a, 0x338a
	stb_d8 0x3384, a
	ldb_d8 a, 0x3332
	stb_d8 0x3333, a
	ld xhl, 0x2f94
	ld xbc, 0x31cc
	calr AccAccTiming_ScanRingBuf
	ldb_d8 a, 0x3384
	stb_d8 0x338a, a
	ldb_d8 a, 0x3333
	stb_d8 0x3332, a
	ldb_d8 a, 0x3377
	stb_d8 0x3376, a
	jr AccKbdTiming_Ret

AccKbdTiming_Ret:
	ret

AccKbdTiming_ScanRingBuf:
	stdi8 0x3a78, 255
	ld ix, (xhl + 6)

AccKbdTiming_EventLoop:
	cp (xhl + 4), ix
	jrl z, AccKbdTiming_ScanDone
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_ClassifyEvent
	ld ix, (xhl + 256)

AccKbdTiming_ClassifyEvent:
	ld w, a
	cp a, 0xdf
	jr z, AccKbdTiming_SpecialEvent
	cp a, 0x9f
	jr nz, AccKbdTiming_CheckNoteOn

AccKbdTiming_SpecialEvent:
	stdi8 0x3380, 2
	jr AccKbdTiming_StoreEventData

AccKbdTiming_CheckNoteOn:
	cp a, 0x90
	jr nz, AccKbdTiming_CheckProgramChg
	stdi8 0x3380, 4
	jr AccKbdTiming_StoreEventData

AccKbdTiming_CheckProgramChg:
	and a, 0xf0
	cp a, 0xc0
	jr nz, AccKbdTiming_CheckControl
	stdi8 0x3380, 5
	jr AccKbdTiming_StoreEventData

AccKbdTiming_CheckControl:
	cp a, 0xd0
	jrl nz, AccKbdTiming_SkipEvent
	stdi8 0x3380, 2

AccKbdTiming_StoreEventData:
	stb_d8 0x3a79, a
	ldb_sri A, 0x07, 0xec, 0xf0
	stda16 0x3378, xix
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_CheckTimestamp
	ld ix, (xhl + 256)

AccKbdTiming_CheckTimestamp:
	cpda8 a, 1117
	jrl ugt, AccKbdTiming_TimestampOverflow
	ld a, w
	and a, 0xf0
	cp w, 0x9f
	jrl z, AccKbdTiming_WriteNonNote
	cp w, 0xdf
	jrl z, AccKbdTiming_WriteNonNote
	cp a, 0x90
	jrl nz, AccKbdTiming_WriteNonNote_Prep
	cpdi8 0x3a78, 0
	jr nz, AccKbdTiming_NoteSlotScan
	pushw wa
	ldb a, 0x8
	stb_d8 0x3a7c, a
	popw wa
	calr AccKbdTiming_CatchupReplay
	stdi8 0x3a78, 255

AccKbdTiming_NoteSlotScan:
	xor iz, iz

AccKbdTiming_SlotLoop:
	cpda16 xiz, 0x337e
	jr nc, AccKbdTiming_SlotOverflow
	bit_dri 7, 0x07, 0xe4, 0xf8
	jr z, AccKbdTiming_WriteNoteEvent
	addda16 xiz, 0x337c
	jr AccKbdTiming_SlotLoop

AccKbdTiming_SlotOverflow:
	pushw wa
	xor xwa, xwa
	ldb_d8 a, 0x3384
	sla xwa, 2
	add xwa, AccTiming_SlotOffsetTables
	ld iz, (xwa)
	ldb_sri A, 0x07, 0xe4, 0xf8
	and_srib_im 0x07, 0xe4, 0xf8, 0x7f
	pushw iz
	inc 2, iz
	ldb_sri W, 0x07, 0xe4, 0xf8
	and a, 0xf0
	or a, 0x8
	calr AccSeq_WriteByte
	ld a, w
	calr AccSeq_WriteByte
	ldb a, 0x0
	calr AccSeq_WriteByte
	popw iz
	popw wa
	incdi8 1, 0x3384
	cpdi8 0x3384, 8
	jr c, AccKbdTiming_SlotOverflow_Done
	stdi8 0x3384, 0

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
	lda_dri XBC, 0x07, 0xe4, 0xf8
	inc 1, iz
	ldb a, 0x0
	lda_dri XBC, 0x07, 0xe4, 0xf8
	inc 1, iz
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNote_Byte2
	ld ix, (xhl + 256)

AccKbdTiming_WriteNote_Byte2:
	calr AccSeq_WriteByte
	lda_dri XBC, 0x07, 0xe4, 0xf8
	inc 1, iz
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNote_Byte3
	ld ix, (xhl + 256)

AccKbdTiming_WriteNote_Byte3:
	calr AccSeq_WriteByte
	lda_dri XBC, 0x07, 0xe4, 0xf8
	inc 1, iz
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNote_ReadTiming
	ld ix, (xhl + 256)

AccKbdTiming_WriteNote_ReadTiming:
	ldb_sri W, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNote_ClampTiming
	ld ix, (xhl + 256)

AccKbdTiming_WriteNote_ClampTiming:
	cp wa, 0xa
	jr ugt, AccKbdTiming_WriteNote_AddBase
	ldw wa, 0xa

AccKbdTiming_WriteNote_AddBase:
	addda16 xwa, 1118
	cp a, 0x60
	jr c, AccKbdTiming_WriteNote_StoreTiming
	inc 1, w
	sub a, 0x60

AccKbdTiming_WriteNote_StoreTiming:
	stw_dri WA, 0x07, 0xe4, 0xf8
	cpda16 xwa, 0x3372
	jr nc, AccKbdTiming_WriteNote_UpdateReadPos
	stda16 0x3372, xwa

AccKbdTiming_WriteNote_UpdateReadPos:
	ld (xhl + 6), ix
	jrl AccKbdTiming_EventLoop

AccKbdTiming_WriteNonNote_Prep:
	ld w, a
	or a, 0x8

AccKbdTiming_WriteNonNote:
	calr AccSeq_WriteByte
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNonNote_Byte2
	ld ix, (xhl + 256)

AccKbdTiming_WriteNonNote_Byte2:
	calr AccSeq_WriteByte
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNonNote_Byte3
	ld ix, (xhl + 256)

AccKbdTiming_WriteNonNote_Byte3:
	calr AccSeq_WriteByte
	cp w, 0xdf
	jr nz, AccKbdTiming_WriteNonNote_CheckType
	ldb a, 0x0
	stb_d8 0x332f, a
	stb_d8 0x3330, a
	stb_d8 0x3331, a
	stb_d8 0x3332, a
	jr AccKbdTiming_WriteNonNote_Done

AccKbdTiming_WriteNonNote_CheckType:
	cp w, 0x9f
	jr z, AccKbdTiming_WriteNonNote_Done
	cp w, 0xd0
	jr z, AccKbdTiming_WriteNonNote_Done
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNonNote_Byte4
	ld ix, (xhl + 256)

AccKbdTiming_WriteNonNote_Byte4:
	calr AccSeq_WriteByte
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNonNote_Byte5
	ld ix, (xhl + 256)

AccKbdTiming_WriteNonNote_Byte5:
	calr AccSeq_WriteByte
	ldb_sri A, 0x07, 0xec, 0xf0
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
	cpdi8 0x3a79, 192
	jr nz, AccKbdTiming_Overflow_SubBase
	stdi8 0x3a78, 0

AccKbdTiming_Overflow_SubBase:
	subda8 a, 1117
	cpda8 a, 0x3377
	jr nc, AccKbdTiming_Overflow_CalcSkip
	stb_d8 0x3377, a

AccKbdTiming_Overflow_CalcSkip:
	ldw_d16 xix, 0x3378
	lda_dri XBC, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_Overflow_AdvancePos
	ld ix, (xhl + 256)

AccKbdTiming_Overflow_AdvancePos:
	xor wa, wa
	ldb_d8 a, 0x3380
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
	ldb_sri A, 0x07, 0xec, 0xf0
	ld w, a
	and w, 0xf0
	cp w, 0xc0
	jr nz, AccKbdTiming_Catchup_SkipNonC0
	ld a, w
	orda8 a, 0x3a7c
	calr AccSeq_WriteByte
	calr AccKbdTiming_AdvancePos
	calr AccKbdTiming_AdvancePos
	ldb_sri A, 0x07, 0xec, 0xf0
	calr AccSeq_WriteByte
	calr AccKbdTiming_AdvancePos
	ldb_sri A, 0x07, 0xec, 0xf0
	calr AccSeq_WriteByte
	calr AccKbdTiming_AdvancePos
	ldb_sri A, 0x07, 0xec, 0xf0
	calr AccSeq_WriteByte
	calr AccKbdTiming_AdvancePos
	ldb_sri A, 0x07, 0xec, 0xf0
	calr AccSeq_WriteByte
	calr AccKbdTiming_AdvancePos
	ldb_sri A, 0x07, 0xec, 0xf0
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
	cpda16 xiz, 0x337e
	jp_24 nc, AccKbdTiming_TableScan_Done
	bit_dri 7, 0x07, 0xe4, 0xf8
	jr z, AccKbdTiming_TableScan_NextSlot
	ld ix, iz
	ldb_sri A, 0x07, 0xe4, 0xf0
	stb_d8 0x3381, a
	inc 2, ix
	ldb_sri A, 0x07, 0xe4, 0xf0
	stb_d8 0x3382, a
	inc 1, ix
	ldb_sri A, 0x07, 0xe4, 0xf0
	stb_d8 0x3383, a
	inc 1, ix
	ldw_sri WA, 0x07, 0xe4, 0xf0
	cpda16 xwa, 1118
	jr gt, AccKbdTiming_TableScan_Decrement
	ldb a, 0xf0
	andda8 a, 0x3381
	or a, 0x8
	calr AccSeq_WriteByte
	ldb_d8 a, 0x3382
	calr AccSeq_WriteByte
	ldb a, 0x0
	calr AccSeq_WriteByte
	and_srib_im 0x07, 0xe4, 0xf8, 0x7f
	jr AccKbdTiming_TableScan_NextSlot

AccKbdTiming_TableScan_Decrement:
	subda16 xwa, 1118
	bit 7, a
	jr z, AccKbdTiming_TableScan_StoreTiming
	add a, 0x60

AccKbdTiming_TableScan_StoreTiming:
	stw_dri WA, 0x07, 0xe4, 0xf0
	cpda16 xwa, 0x3374
	jr nc, AccKbdTiming_TableScan_NextSlot
	stda16 0x3374, xwa

AccKbdTiming_TableScan_NextSlot:
	addda16 xiz, 0x337c
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
	stdi8 0x3a7a, 255
	ld ix, (xhl + 6)

AccAccTiming_EventLoop:
	cp (xhl + 4), ix
	jrl z, AccAccTiming_ScanDone
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_ClassifyEvent
	ld ix, (xhl + 256)

AccAccTiming_ClassifyEvent:
	ld w, a
	cp a, 0x90
	jr nz, AccAccTiming_Check0x91
	stdi8 0x3380, 5
	jr AccAccTiming_StoreEventData

AccAccTiming_Check0x91:
	cp a, 0x91
	jr nz, AccAccTiming_Check0x92
	stdi8 0x3380, 7
	jr AccAccTiming_StoreEventData

AccAccTiming_Check0x92:
	cp a, 0x92
	jr nz, AccAccTiming_CheckProgramChg
	stdi8 0x3380, 6
	jr AccAccTiming_StoreEventData

AccAccTiming_CheckProgramChg:
	and a, 0xf0
	cp a, 0xc0
	jr nz, AccAccTiming_CheckControl
	stdi8 0x3380, 5
	jr AccAccTiming_StoreEventData

AccAccTiming_CheckControl:
	cp a, 0xd0
	jrl nz, AccAccTiming_SkipEvent
	stdi8 0x3380, 2

AccAccTiming_StoreEventData:
	stb_d8 0x3a7b, a
	ldb_sri A, 0x07, 0xec, 0xf0
	stda16 0x337a, xix
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_CheckTimestamp
	ld ix, (xhl + 256)

AccAccTiming_CheckTimestamp:
	cpda8 a, 1117
	jrl ugt, AccAccTiming_TimestampOverflow
	ld a, w
	and a, 0xf0
	cp a, 0x90
	jrl nz, AccAccTiming_WriteNonNote
	cpdi8 0x3a7a, 0
	jr nz, AccAccTiming_NoteSlotScan
	pushw wa
	ldb_d8 a, 0x338c
	stb_d8 0x3a7c, a
	popw wa
	calr AccKbdTiming_CatchupReplay
	stdi8 0x3a7a, 255

AccAccTiming_NoteSlotScan:
	pushw wa
	ldb_sri W, 0x07, 0xec, 0xf0
	xor iz, iz

AccAccTiming_NoteSlot_Loop:
	cpda16 xiz, 0x337e
	jr nc, AccAccTiming_NoteSlot_FindFree
	bit_dri 7, 0x07, 0xe4, 0xf8
	jr z, AccAccTiming_NoteSlot_NextSlot
	ldw_erp IZ, 0xfa
	add iz, 0x2
	cpb_sri_mr W, 0x07, 0xe4, 0xf8
	stw_erp IZ, 0xfa
	jr z, AccAccTiming_NoteSlot_SendNoteOff

AccAccTiming_NoteSlot_NextSlot:
	addda16 xiz, 0x337c
	jr AccAccTiming_NoteSlot_Loop

AccAccTiming_NoteSlot_SendNoteOff:
	ldb_sri A, 0x07, 0xe4, 0xf8
	and_srib_im 0x07, 0xe4, 0xf8, 0x7f
	and a, 0xf0
	orda8 a, 0x338c
	calr AccSeq_WriteByte
	ld a, w
	calr AccSeq_WriteByte
	ldb a, 0x0
	calr AccSeq_WriteByte
	bitda 0, 0x338d
	jr nz, AccAccTiming_NoteSlot_FindFree
	ordi8 0x338d, 1
	ldb a, 0x90
	calr AccSeq_WriteByte
	ldb a, 0x0
	calr AccSeq_WriteByte
	calr AccSeq_WriteByte

AccAccTiming_NoteSlot_FindFree:
	popw wa
	xor iz, iz

AccAccTiming_NoteSlot_FreeLoop:
	cpda16 xiz, 0x337e
	jr nc, AccAccTiming_SlotOverflow
	bit_dri 7, 0x07, 0xe4, 0xf8
	jr z, AccAccTiming_WriteNoteEvent
	addda16 xiz, 0x337c
	jr AccAccTiming_NoteSlot_FreeLoop

AccAccTiming_SlotOverflow:
	pushw wa
	xor xwa, xwa
	ldb_d8 a, 0x3384
	sla xwa, 2
	add xwa, AccTiming_SlotOffsetTables_0x20
	ld iz, (xwa)
	ldb_sri A, 0x07, 0xe4, 0xf8
	and_srib_im 0x07, 0xe4, 0xf8, 0x7f
	pushw iz
	inc 2, iz
	ldb_sri W, 0x07, 0xe4, 0xf8
	and a, 0xf0
	orda8 a, 0x338c
	calr AccSeq_WriteByte
	ld a, w
	calr AccSeq_WriteByte
	ldb a, 0x0
	calr AccSeq_WriteByte
	popw iz
	popw wa
	incdi8 1, 0x3384
	cpdi8 0x3384, 8
	jr c, AccAccTiming_SlotOverflow_Done
	stdi8 0x3384, 0

AccAccTiming_SlotOverflow_Done:
	jr AccAccTiming_WriteNoteEvent

AccAccTiming_SkipEvent:
	ld ix, (xhl + 4)
	ld (xhl + 6), ix
	jrl AccAccTiming_EventLoop

AccAccTiming_WriteNoteEvent:
	orda8 a, 0x338c
	calr AccSeq_WriteByte
	ld a, w
	lda_dri XBC, 0x07, 0xe4, 0xf8
	inc 1, iz
	ldb a, 0x0
	lda_dri XBC, 0x07, 0xe4, 0xf8
	inc 1, iz
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNote_Byte2
	ld ix, (xhl + 256)

AccAccTiming_WriteNote_Byte2:
	calr AccSeq_WriteByte
	lda_dri XBC, 0x07, 0xe4, 0xf8
	inc 1, iz
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNote_Byte3
	ld ix, (xhl + 256)

AccAccTiming_WriteNote_Byte3:
	calr AccSeq_WriteByte
	lda_dri XBC, 0x07, 0xe4, 0xf8
	inc 1, iz
	pushw wa
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNote_ReadTimingLo
	ld ix, (xhl + 256)

AccAccTiming_WriteNote_ReadTimingLo:
	ldb_sri W, 0x07, 0xec, 0xf0
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
	stw_dri WA, 0x07, 0xe4, 0xf8
	inc 2, iz
	cpda16 xwa, 0x3372
	jr nc, AccAccTiming_WriteNote_ExtraBytes
	stda16 0x3372, xwa

AccAccTiming_WriteNote_ExtraBytes:
	popw wa
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNote_StoreExtra1
	ld ix, (xhl + 256)

AccAccTiming_WriteNote_StoreExtra1:
	lda_dri XBC, 0x07, 0xe4, 0xf8
	inc 1, iz
	cp w, 0x90
	jr z, AccAccTiming_WriteNote_Done
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNote_StoreExtra2
	ld ix, (xhl + 256)

AccAccTiming_WriteNote_StoreExtra2:
	lda_dri XBC, 0x07, 0xe4, 0xf8
	inc 1, iz
	cp w, 0x92
	jr z, AccAccTiming_WriteNote_Done
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNote_StoreExtra3
	ld ix, (xhl + 256)

AccAccTiming_WriteNote_StoreExtra3:
	lda_dri XBC, 0x07, 0xe4, 0xf8
	inc 1, iz

AccAccTiming_WriteNote_Done:
	ld (xhl + 6), ix
	jrl AccAccTiming_EventLoop

AccAccTiming_WriteNonNote:
	ld w, a
	orda8 a, 0x338c
	calr AccSeq_WriteByte
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNonNote_Byte2
	ld ix, (xhl + 256)

AccAccTiming_WriteNonNote_Byte2:
	calr AccSeq_WriteByte
	stb_d8 0x3334, a
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNonNote_Byte3
	ld ix, (xhl + 256)

AccAccTiming_WriteNonNote_Byte3:
	calr AccSeq_WriteByte
	cp w, 0xd0
	jr nz, AccAccTiming_WriteNonNote_ExtBytes
	cpdi8 0x3334, 3
	jr nz, AccAccTiming_WriteNonNote_Done
	stb_d8 0x3333, a
	jr AccAccTiming_WriteNonNote_Done

AccAccTiming_WriteNonNote_ExtBytes:
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNonNote_Byte5
	ld ix, (xhl + 256)

AccAccTiming_WriteNonNote_Byte5:
	calr AccSeq_WriteByte
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNonNote_Byte6
	ld ix, (xhl + 256)

AccAccTiming_WriteNonNote_Byte6:
	calr AccSeq_WriteByte
	ldb_sri A, 0x07, 0xec, 0xf0
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
	cpdi8 0x3a7b, 192
	jr nz, AccAccTiming_Overflow_SubBase
	stdi8 0x3a7a, 0

AccAccTiming_Overflow_SubBase:
	subda8 a, 1117
	cpda8 a, 0x3377
	jr nc, AccAccTiming_Overflow_CalcSkip
	stb_d8 0x3377, a

AccAccTiming_Overflow_CalcSkip:
	ldw_d16 xix, 0x337a
	lda_dri XBC, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_Overflow_AdvancePos
	ld ix, (xhl + 256)

AccAccTiming_Overflow_AdvancePos:
	xor wa, wa
	ldb_d8 a, 0x3380
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
	cpda16 xiz, 0x337e
	jp_24 nc, AccAccTiming_TableScan_Done
	bit_dri 7, 0x07, 0xe4, 0xf8
	jr z, AccAccTiming_TableScan_NextSlot
	ld ix, iz
	ldb_sri A, 0x07, 0xe4, 0xf0
	stb_d8 0x3381, a
	inc 2, ix
	ldb_sri A, 0x07, 0xe4, 0xf0
	stb_d8 0x3382, a
	inc 1, ix
	ldb_sri A, 0x07, 0xe4, 0xf0
	stb_d8 0x3383, a
	inc 1, ix
	ldw_sri WA, 0x07, 0xe4, 0xf0
	cpda16 xwa, 1118
	jr gt, AccAccTiming_TableScan_Decrement
	ldb a, 0xf0
	andda8 a, 0x3381
	orda8 a, 0x338c
	calr AccSeq_WriteByte
	ldb_d8 a, 0x3382
	calr AccSeq_WriteByte
	ldb a, 0x0
	calr AccSeq_WriteByte
	and_srib_im 0x07, 0xe4, 0xf8, 0x7f
	jr AccAccTiming_TableScan_NextSlot

AccAccTiming_TableScan_Decrement:
	subda16 xwa, 1118
	bit 7, a
	jr z, AccAccTiming_TableScan_StoreTiming
	add a, 0x60

AccAccTiming_TableScan_StoreTiming:
	stw_dri WA, 0x07, 0xe4, 0xf0
	cpda16 xwa, 0x3374
	jr nc, AccAccTiming_TableScan_NextSlot
	stda16 0x3374, xwa

AccAccTiming_TableScan_NextSlot:
	addda16 xiz, 0x337c
	jrl AccAccTiming_TableScan_Loop

AccAccTiming_TableScan_Done:
	ret

AccTiming_SlotOffsetTables:
	nop
	nop
	nop
	nop
	di
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
	push_f
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
	push	0
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
	cpdi8 0x34a7, 0
	jr nz, AccDir_CheckLeftNote
	cpdi8 0x34a8, 0
	jr z, AccDir_CheckLeftNote
	ordi8 0x349f, 1

AccDir_CheckLeftNote:
	cpdi8 0x34a9, 0
	jr nz, AccDir_CheckRightHandState
	cpdi8 0x34aa, 0
	jr z, AccDir_CheckRightHandState
	ordi8 0x349f, 8

AccDir_CheckRightHandState:
	ldb_d8 a, 0x34a5
	bit 0, a
	jr nz, AccDir_Finalize
	bit 1, a
	jr z, AccDir_Finalize
	anddi8 0x349f, 246
	stdi8 0x34a6, 0

AccDir_Finalize:
	calr AccDir_AdjustDirection
	calr AccDir_SavePrevState
	ret

AccDir_Padding1:
	nop
	nop

AccDir_ReadState:
	ldb_d8 a, 0xfc5a
	stb_d8 0x34a4, a
	ldb_d8 a, 0x3312
	and a, 0x3f
	stb_d8 0x34a7, a
	ldb_d8 a, 0x3313
	and a, 0x3f
	stb_d8 0x34a9, a
	ldb_d8 a, 1045
	stb_d8 0x34a0, a
	ldb_d8 a, 0x34a5
	and a, 0xfe
	bitda 0, 0x3283
	jr z, AccDir_ReadState_StoreFlags
	or a, 0x1

AccDir_ReadState_StoreFlags:
	stb_d8 0x34a5, a
	ldb_d8 a, 0xfd99
	bit 0, a
	jr nz, AccDir_ReadState_Ret
	anddi8 0x349f, 246

AccDir_ReadState_Ret:
	ret

AccDir_Padding2:
	nop
	nop

AccDir_SavePrevState:
	ldb_d8 a, 0x34a7
	stb_d8 0x34a8, a
	ldb_d8 a, 0x34a9
	stb_d8 0x34aa, a
	ldb_d8 a, 0x34a5
	and a, 0xfd
	bit 0, a
	jr z, AccDir_SavePrevState_StoreFlags
	or a, 0x2

AccDir_SavePrevState_StoreFlags:
	stb_d8 0x34a5, a
	ret

AccDir_Padding3:
	nop
	nop

AccDir_AdjustDirection:
	ldb_d8 a, 0x349f
	and a, 0x9
	cps a, 0
	jp_24 z, AccDir_Adjust_Ret
	bitda 0, 0x349f
	jr z, AccDir_Adjust_LeftHand
	anddi8 0x349f, 254
	cpdi8 0x34a4, 128
	jr nc, AccDir_Adjust_LeftHand
	ldb_d8 w, 0xfd99
	and w, 0x1
	ldb_d8 a, 0xfc61
	and a, 0x30
	srl a, 4
	cps w, 0
	jr z, AccDir_Adjust_LeftHand
	dec 1, a
	cp a, 0xff
	jr nz, AccDir_Adjust_RightDec
	ldb a, 0x0

AccDir_Adjust_RightDec:
	sll a, 4
	anddi8 0xfc61, 207
	orddm8 0xfc61, a
	calr AccDir_DispatchEvent

AccDir_Adjust_LeftHand:
	bitda 3, 0x349f
	jr z, AccDir_Adjust_SetChanged
	anddi8 0x349f, 247
	cpdi8 0x34a4, 128
	jr nc, AccDir_Adjust_SetChanged
	ldb_d8 w, 0xfd99
	and w, 0x1
	ldb_d8 a, 0xfc61
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
	anddi8 0xfc61, 207
	orddm8 0xfc61, a
	calr AccDir_DispatchEvent

AccDir_Adjust_SetChanged:
	stdi8 0x34a6, 1

AccDir_Adjust_Ret:
	ret

AccDir_Padding4:
	nop
	nop

AccDir_DispatchEvent:
	ldb_d8 w, 0xfd99
	and w, 0x1
	cps w, 0
	jr z, AccDir_DispatchEvent_Ret
	cpdi8 0x34a4, 128
	jr nc, AccDir_DispatchEvent_Ret
	ldb e, 0x48
	ldb d, 0x7
	ldb_d8 a, 0xfc61
	ldb w, 0x30
	call SwbtWr_QueuePostEvent
	ldb_d8 a, 0xfd99
	and a, 0x70
	cp a, 0x10
	jr z, AccDir_DispatchEvent_Ret
	ldb_d8 a, 0xfc61
	and a, 0x30
	srl a, 4
	stb_d8 0x8d54, a
	call EffectMode_ReinitWithFlag

AccDir_DispatchEvent_Ret:
	ret

AccDir_Padding5:
	nop
	nop

AccDir_PeriodicCheck:
	bitda 4, 0x3284
	jr z, AccDir_Periodic_Ret
	cpdi8 0x34a6, 0
	jr z, AccDir_Periodic_CheckCountdown
	decdi8 1, 0x34a6

AccDir_Periodic_CheckCountdown:
	cpdi8 0x34a6, 0
	jr nz, AccDir_Periodic_Ret
	ldb_d8 a, 1045
	cp a, 0x5d
	jr nc, AccDir_Periodic_DisableAndReset
	cp a, 0x30
	jr ugt, AccDir_Periodic_Ret

AccDir_Periodic_DisableAndReset:
	anddi8 0x3284, 239
	anddi8 0x3284, 251
	call AudioMode_SetStereoFlags

AccDir_Periodic_Ret:
	ret

AccDir_JumpTable:
	.byte 0x00, 0x00, 0x1d, 0x4e, 0xbf, 0xf5, 0x0e

AccProcess_Entry:
	call AccProcess_TimerCompare
	ret

AccProcess_InlinedCode:
	ldb_d8	a, 0xc07d
	cp	a, 18
	.byte 0xf2, 0xe1, 0xbf, 0xf5
	and	bc, iz
	jrl	nz, 8640
	andda8	a, 0xc07f
	and	a, 1
	cps	a, 1
	.byte 0xf2, 0xe1, 0xbf, 0xf5
	cp	bc, iz
	.byte 0x90
	ldw	ix, 0x6ec8
	retd	2513
	.byte 0x04
	ldb	w, 241
	.byte 0x8e
	ldw	ix, 0xc150
	.byte 0x90
	ldw	ix, 318
	jr	96
	ldw_d16	wa, 1033
	ldw_d16	bc, 0x348e
	cp	wa, bc
	jr	c, 4
	sub	wa, bc
	jr	20
	and	xwa, 0xffff
	and	xbc, 0xffff
	add	xwa, 0x010000
	sub	xwa, xbc
	cp	wa, 750
	jr	c, 3
	ldw	wa, 750
	cp	wa, 100
	jr	ugt, 3
	ldw	wa, 100
	ld	bc, wa
	ld	xwa, 0x7530
	div	xwa, xbc
	pushw	wa
	calr	30
	popw	wa
	ldw_d16	hl, 0x3494
	stda16	0x3496, hl
	ldw_d16	hl, 0x3492
	stda16	0x3494, hl
	stda16	0x3492, wa
	ldw_d16	wa, 1033
	stda16	0x348e, wa
	ret
	ldw_d16	de, 0x3492
	ldw_d16	bc, 0x3494
	cps	de, 0
	jr	nz, 4
	jp	AccProcess_InlinedCode_0xBF
	cps	bc, 0
	jr	nz, 9
	add	wa, de
	srl	wa, 1
	jp	AccProcess_InlinedCode_0xBF
	add	wa, de
	add	wa, bc
	and	xwa, 0xffff
	div	wa, 3
	ldb	e, 72
	ldb	d, 8
	call	SwbtWr_TrailingBytecode
	ret

AccProcess_TimerCompare:
	bitda 0, 0x3490
	jr z, AccProcess_Timer_Ret
	ldw_d16 xwa, 1033
	ldw_d16 xbc, 0x348e
	cp wa, bc
	jr c, AccProcess_Timer_WrapCase
	sub wa, bc
	cp wa, 0x400
	jr c, AccProcess_Timer_Skip
	anddi8 0x3490, 254
	xor wa, wa
	stda16 0x3492, xwa
	stda16 0x3494, xwa
	stda16 0x3496, xwa

AccProcess_Timer_Skip:
	jr AccProcess_Timer_Ret

AccProcess_Timer_WrapCase:
	and xwa, 0xffff
	and xbc, 0xffff
	add xwa, 0x10000
	sub xwa, xbc
	cp wa, 0x400
	jr c, AccProcess_Timer_Ret
	anddi8 0x3490, 254
	xor wa, wa
	stda16 0x3492, xwa
	stda16 0x3494, xwa
	stda16 0x3496, xwa

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
	cp l, 0xf
	jr nz, AccVoice_Dispatch_Type0E
	calr AccVoice_ROMLookup
	jr AccVoice_Dispatch_Epilogue

AccVoice_Dispatch_Type0E:
	cp l, 0xe
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
	ld xiy, 0x34ab
	ret

AccVoice_Dispatch_Padding:
	nop
	nop

AccVoice_ComputedCopy:
	ld a, l
	xor w, w
	muls wa, 0x14
	ld l, h
	xor h, h
	add wa, hl
	muls wa, 0xd
	add xwa, Display_FontPalette_Table_0x22EF
	ld xiy, xwa
	ld xix, 0x34ab
	ldw bc, 0xd
	ldir85
	ret

AccVoice_ComputedCopy_Padding:
	nop
	nop

AccVoice_ROMLookup:
	ld l, h
	and hl, 0xf
	sla hl, 2
	ld xix, AccVoice_ROMLookup_OffsetTable_0x2
	ld xiy, 0x94800
	add_sril_rm XIY, 0x07, 0xf0, 0xec
	ld xix, 0x34ab
	ldw bc, 0xd
	ldir85
	ret

AccVoice_ROMLookup_OffsetTable:
	.byte 0x00, 0x00, 0xa0, 0x00, 0x00, 0x00, 0x00, 0x01


	naka_header NAKA_TYPE_0x00
	.byte 0x00, 0x00, 0xc0, 0x01
	.byte 0x00, 0x00, 0x20, 0x02, 0x00, 0x00, 0x80, 0x02
	.byte 0x00, 0x00, 0xe0, 0x02, 0x00, 0x00, 0x40, 0x03
	.byte 0x00, 0x00, 0xa0, 0x03, 0x00, 0x00, 0x00, 0x04
	.byte 0x00, 0x00, 0x60, 0x04, 0x00, 0x00, 0xc0, 0x04
	.byte 0x00, 0x00, 0xa0, 0x00, 0x00, 0x00, 0xa0, 0x00
	.byte 0x00, 0x00, 0xa0, 0x00, 0x00, 0x00, 0xa0, 0x00
	.byte 0x00, 0x00

AccVoice_IndexedTableLookup:
	ld l, h
	xor h, h
	sla hl, 2
	ld xix, AccVoice_IndexedTableLookup_BaseOffsets_0x2
	ld_sril3 XIY, 0x07, 0xf0, 0xec
	ld xix, AccVoice_IndexedTableLookup_BaseOffsets_0x152
	add_sril_rm XIY, 0x07, 0xf0, 0xec
	ld xix, 0x34ab
	ldw bc, 0xd
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
	.byte 0x98
	ldw	bc, 0
	.byte 0x98
	ldw	bc, 0
	.byte 0x98
	ldw	bc, 0
	.byte 0x98
	ldw	bc, 0
	.byte 0x98
	ldw	bc, 0
	.byte 0x98
	ldw	bc, 0
	.byte 0x98
	ldw	bc, 0
	.byte 0x98
	ldw	bc, 0
	.byte 0x98
	ldw	bc, 0
	.byte 0x98
	ldw	bc, 0
	.byte 0x98
	ldw	bc, 0
	.byte 0x98
	ldw	bc, 0
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
	.byte 0x98
	ldw	ix, 0
	.byte 0x98
	ldw	ix, 0
	.byte 0x98
	ldw	ix, 0
	.byte 0x98
	ldw	ix, 0
	.byte 0x98
	ldw	ix, 0
	.byte 0x98
	ldw	ix, 0
	.byte 0x98
	ldw	ix, 0
	.byte 0x98
	ldw	ix, 0
	.byte 0x98
	ldw	ix, 0
	.byte 0x98
	ldw	ix, 0
	.byte 0x98
	ldw	ix, 0
	.byte 0x98
	ldw	ix, 0
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
	.byte 0x98, 0x37
	nop
	nop
	.byte 0x98, 0x37
	nop
	nop
	.byte 0x98, 0x37
	nop
	nop
	.byte 0x98, 0x37
	nop
	nop
	.byte 0x98, 0x37
	nop
	nop
	.byte 0x98, 0x37
	nop
	nop
	.byte 0x98, 0x37
	nop
	nop
	.byte 0x98, 0x37
	nop
	nop
	.byte 0x98, 0x37
	nop
	nop
	.byte 0x98, 0x37
	nop
	nop
	.byte 0x98, 0x37
	nop
	nop
	.byte 0x98, 0x37
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
	nop
	nop
	push	xbc
	nop
	.byte 0xa0
	nop
	nop
	nop
	nop
	.byte 0x01


	naka_header NAKA_TYPE_0x00
	nop
	nop
	.byte 0xc0, 0x01
	nop
	nop
	ldb	w, 2
	nop
	nop
	.byte 0x80
	push	sr
	nop
	nop
	.byte 0xe0
	push	sr
	nop
	nop
	ld	xwa, 0xa0000003
	pop	sr
	nop
	nop
	nop
	.byte 0x04
	nop
	nop
	jr	f, 4
	nop
	nop
	.byte 0xc0, 0x04
	nop
	nop
	.byte 0xa0
	nop
	nop
	nop
	nop
	.byte 0x01


	naka_header NAKA_TYPE_0x00
	nop
	nop
	.byte 0xc0, 0x01
	nop
	nop
	ldb	w, 2
	nop
	nop
	.byte 0x80
	push	sr
	nop
	nop
	.byte 0xe0
	push	sr
	nop
	nop
	ld	xwa, 0xa0000003
	pop	sr
	nop
	nop
	nop
	.byte 0x04
	nop
	nop
	jr	f, 4
	nop
	nop
	.byte 0xc0, 0x04
	nop
	nop
	.byte 0xa0
	nop
	nop
	nop
	nop
	.byte 0x01


	naka_header NAKA_TYPE_0x00
	nop
	nop
	.byte 0xc0, 0x01
	nop
	nop
	ldb	w, 2
	nop
	nop
	.byte 0x80
	push	sr
	nop
	nop
	.byte 0xe0
	push	sr
	nop
	nop
	ld	xwa, 0xa0000003
	pop	sr
	nop
	nop
	nop
	.byte 0x04
	nop
	nop
	jr	f, 4
	nop
	nop
	.byte 0xc0, 0x04
	nop
	nop
	.byte 0xa0
	nop
	nop
	nop
	nop
	.byte 0x01


	naka_header NAKA_TYPE_0x00
	nop
	nop
	.byte 0xc0, 0x01
	nop
	nop
	ldb	w, 2
	nop
	nop
	.byte 0x80
	push	sr
	nop
	nop
	.byte 0xe0
	push	sr
	nop
	nop
	ld	xwa, 0xa0000003
	pop	sr
	nop
	nop
	nop
	.byte 0x04
	nop
	nop
	jr	f, 4
	nop
	nop
	.byte 0xc0, 0x04
	nop
	nop
	.byte 0xa0
	nop
	nop
	nop
	nop
	.byte 0x01


	naka_header NAKA_TYPE_0x00
	nop
	nop
	.byte 0xc0, 0x01
	nop
	nop
	ldb	w, 2
	nop
	nop
	.byte 0x80
	push	sr
	nop
	nop
	.byte 0xe0
	push	sr
	nop
	nop
	ld	xwa, 0xa0000003
	pop	sr
	nop
	nop
	nop
	.byte 0x04
	nop
	nop
	jr	f, 4
	nop
	nop
	.byte 0xc0, 0x04
	nop
	nop
	.byte 0xa0
	nop
	nop
	nop
	nop
	.byte 0x01


	naka_header NAKA_TYPE_0x00
	nop
	nop
	.byte 0xc0, 0x01
	nop
	nop
	ldb	w, 2
	nop
	nop
	.byte 0x80
	push	sr
	nop
	nop
	.byte 0xe0
	push	sr
	nop
	nop
	ld	xwa, 0xa0000003
	pop	sr
	nop
	nop
	nop
	.byte 0x04
	nop
	nop
	jr	f, 4
	nop
	nop
	.byte 0xc0, 0x04
	nop
	nop
	.byte 0xa0
	nop
	nop
	nop
	nop
	.byte 0x01


	naka_header NAKA_TYPE_0x00
	nop
	nop
	.byte 0xc0, 0x01
	nop
	nop
	ldb	w, 2
	nop
	nop
	.byte 0x80
	push	sr
	nop
	nop
	.byte 0xe0
	push	sr
	nop
	nop
	ld	xwa, 0xa0000003
	pop	sr
	nop
	nop
	nop
	.byte 0x04
	nop
	nop
	jr	f, 4
	nop
	nop
	.byte 0xc0, 0x04
	nop
	nop
	sub	l, 140
	and	hl, 7
	sla	hl, 2
	ld	xix, AccVoice_IndexedTableLookup_BaseOffsets_0x2C8
	ld	xiy, 0x094800
	.byte 0xe3
	reti
	.byte 0xf0
	add	xiy, xix
	ld	xix, 0x34ab
	ldw	bc, 13
	.byte 0x85
	scf
	ret
	nop
	nop
	.byte 0xb0
	pushw	0
	.byte 0xd0
	pushw	0
	.byte 0xf0
	pushw	0
	rcf
	incf
	nop
	nop
	ldw	wa, 12
	nop
	.byte 0xb0
	pushw	0
	.byte 0xb0
	pushw	0
	.byte 0xb0
	pushw	0

AccVoice_GetChannelCount:
	push xix
	cp l, 0x10
	jr c, AccVoice_GetChannelCount_Lookup
	xor l, l

AccVoice_GetChannelCount_Lookup:
	and hl, 0x1f
	ld xix, AccVoice_ChannelCountTable_0x2
	ldb_sri L, 0x07, 0xf0, 0xec
	pop xix
	ret

AccVoice_ChannelCountTable:
	.byte 0x00, 0x00, 0x0f, 0x0c, 0x10, 0x09, 0x12, 0x0d
	.byte 0x0c, 0x0e, 0x0c, 0x12, 0x0b, 0x0b, 0x0c, 0x0d
	.byte 0x13, 0x0b

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
	add xwa, Display_FontPalette_Table_0x21EF
	ld xiy, xwa
	ld xix, 0x34ab
	ldw bc, 0x10
	ldir85
	pop xiy
	pop xhl
	pop xbc
	pop xwa
	ld xiy, 0x34ab
	ret

AccVoice_CopyFromROM_DataBlock:
	nop
	nop
	pushw	hl
	calr	64464
	popw	hl
	lds32	xix, 0
	ldw	bc, 8
	ldirw
	ld	xiy, AccVoice_CopyFromROM_DataBlock_0x46
	jr	c, 5
	ld	xiy, AccVoice_CopyFromROM_DataBlock_0x6D
	ld	wa, (xiy)
	ld	c, (xiy+2)
	cp	wa, 0xffff
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
	pop	sr
	push	sr
	nop
	.byte 0x04
	pop	sr
	nop
	.byte 0x04, 0x04
	nop
	halt
	push	sr
	nop
	ei	4
	nop
	ei	6
	.byte 0x01
	pushw	3
	pushw	4
	decf
	push	sr
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
	pop	sr
	push	sr
	nop
	.byte 0x04
	push	sr
	nop
	.byte 0x04
	di
	halt
	push	sr
	nop
	pushw	2
	pushw	261
	decf
	push	sr
	nop
	ret
	reti
	nop
	ret
	push	1
	ret
	ldwio	1, 0xffff
	nop
	swi	7
	swi	7
	nop

AccStyle_Entry:
	jp AccStyle_Process
AccStyle_JumpTable:
	jp	AccStyle_ToggleBit0
	jp	AccStyle_ModeEnter
	jp	AccStyle_ModeExit
	jp	AccStyle_InlinedBlock_0x6

AccStyle_InitVRAM_Wrap:
	push xiz
	call AccStyle_InitVRAM
	pop xiz
	ret

AccStyle_JumpTable2:
	jp	AccStyle_IndexedLookup
	jp	AccStyle_SC0ByteSelect
	jp	AccStyle_SC0ByteSelect_0x19
	jp	AccStyle_SC0ByteSelect_0x32
	jp	AccStyle_SC0ByteSelect_0x4B
	jp	AccStyle_SC0ByteSelect_0x64
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
	ldb_d8 a, 0x338e
	and a, 0x1f
	jr z, AccStyle_Process_SaveState
	ldb_d8 a, 0x338f
	and a, 0x1f
	jr nz, AccStyle_Process_DoChain
	calr AccVoiceState_Snapshot

AccStyle_Process_DoChain:
	calr AccHelper_ComputeVoiceOffset
	ld xiy, xhl
	add xiy, 0x1e7810
	calr AccVoiceDelta_Part1
	calr AccVoiceDelta_Part2
	calr AccVoiceDelta_Part3
	calr AccVoiceDelta_Part4
	calr AccVoiceDelta_Part5

AccStyle_Process_SaveState:
	ldb_d8 a, 0x338e
	stb_d8 0x338f, a
	ret

AccStyle_ToggleBit0:
	; --- Routine 1: XOR toggle bit 0 at (0x3391), conditional calls (51 bytes) ---
	cpdi8	0x8d34, 17
	jr nz, AccStyle_ToggleBit0_CheckC07D
	jr t, AccStyle_ToggleBit0_Ret
AccStyle_ToggleBit0_CheckC07D:
	cpdi8	0xc07d, 6
	jr nz, AccStyle_ToggleBit0_Ret
	ldb_d8	a, 0xc07e
	andda8	a, 0xc07f
	bit 0, a
	jr z, AccStyle_ToggleBit0_Ret
	xordi8	0x3391, 1
	bitda	0, 0x3391
	jr nz, AccStyle_ToggleBit0_CallOn
	call AccTuning_LEDOff
	jr t, AccStyle_ToggleBit0_Ret
AccStyle_ToggleBit0_CallOn:
	call AccTuning_LEDOn
AccStyle_ToggleBit0_Ret:
	ret
AccStyle_IndexedLookup:
	; --- Routine 2: indexed table lookup at 0xf5c8b4, store + DE/W setup (63 bytes) ---
	cpdi8	0x8d34, 17
	jr nz, AccStyle_IndexedLookup_Ret
	cpdi8	0xc07d, 16
	jr nz, AccStyle_IndexedLookup_Ret
	ldb_d8	a, 0x338e
	and a, 0x1f
	jr z, AccStyle_IndexedLookup_Ret
	ldb_d8	l, 0x338e
	and l, 0x1f
	extz hl
	ld xwa, 0x00f5c8b4
	ld_rrb	a, xwa, hl
	cpdm8	0x8d3a, a
	jr z, AccStyle_IndexedLookup_Ret
	stb_d8	0x8d3a, a
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
	cpdi8 0x8d35, 17
	jr z, AccStyle_ModeEnter_Ret
	stdi8 0x338e, 0
	stdi8 0x338f, 0
	stdi8 0x339f, 0
	anddi8 0x33d1, 254
	cpdi16 0xf19e, 0
	jr z, AccStyle_ModeEnter_SetFlags
	call SeqAcc_SetIndicator_PB
	stdi16 0xf19e, 0
	call Audio_CheckSubsystemReady
	ordi8 0x33d1, 1

AccStyle_ModeEnter_SetFlags:
	ordi8 0x34cd, 8
	ordi8 0x33d3, 1
	ldb a, 0x4b
	call CtrlPanel_SetIndicatorBit

AccStyle_ModeEnter_Ret:
	ret

AccStyle_ModeExit_Wrap:
	push xiz
	calr AccStyle_ModeExit
	pop xiz
	ret

AccStyle_ModeExit:
	cpdi8 0x8d34, 17
	jr z, AccStyle_ModeExit_Ret
	stdi8 0x338e, 0
	stdi8 0x338f, 0
	stdi8 0x339f, 0
	anddi8 0x34cd, 247
	bitda 0, 0x33d1
	jr z, AccStyle_ModeExit_ClearFlags
	anddi8 0x33d1, 254
	call AccWrap_PlayModeDispatch
	call SeqAcc_RestorePlaybackState

AccStyle_ModeExit_ClearFlags:
	anddi8 0x33d3, 252
	call PartSelect_UpdateDisplayState

AccStyle_ModeExit_Ret:
	ret

AccStyle_InlinedBlock:
	push	xiz
	calr	2
	pop	xiz
	ret
	.byte 0xc1, 0x37
	xor	(xiy+63), d
	jrl	z, 354
	.byte 0xc1
	pop	xde
	swi	4
	push	xsp
	incm8	7, (xwa)
	.byte 0x17
	stdi8	0x339f, 1
	ldb	a, 8
	call	MIDI_SendSysExCmd
	stdi8	0x7f42, 54
	call	DrumVoice_NotifyEE
	jrl	371
	stdi8	0x338e, 32
	call	AccHelper_ComputeVoiceOffset
	add	xhl, 0x1e7810
	.byte 0x8b, 0x01
	push	xiz
	.byte 0x80
	calr	799
	call	AccTuning_LoadFromROM
	.byte 0xc1, 0x46
	ldw	de, 0xc125
	ld	xsp, 0x14432432
	ldw	de, 0
	ld	(xhl), e
	ld	(xhl+1), d
	ldb_d8	e, 0x324d
	ldb_d8	d, 0x324e
	ldb_d8	a, 0x324f
	stb_d8	0x342f, a
	ldb_d8	a, 0x3250
	stb_d8	0x3430, a
	ldb_d8	a, 0x3251
	stb_d8	0x3431, a
	ldb_d8	a, 0x3252
	stb_d8	0x32c3, a
	ldb_d8	a, 0x3253
	stb_d8	0x32c7, a
	call	Rhythm_PackVelocityHighBit
	ld	xhl, 0x3219
	call	AccVoiceReg_StoreParamRecord
	ldb_d8	e, 0x3254
	ldb_d8	d, 0x3255
	ldb_d8	a, 0x3256
	stb_d8	0x342f, a
	ldb_d8	a, 0x3257
	stb_d8	0x3430, a
	ldb_d8	a, 0x3258
	stb_d8	0x3431, a
	ldb_d8	a, 0x3259
	stb_d8	0x32c3, a
	ldb_d8	a, 0x325a
	stb_d8	0x32c7, a
	call	Rhythm_PackVelocityHighBit
	ld	xhl, 0x321e
	call	AccVoiceReg_StoreParamRecord
	ldb_d8	e, 0x325b
	ldb_d8	d, 0x325c
	ldb_d8	a, 0x325d
	stb_d8	0x342f, a
	ldb_d8	a, 0x325e
	stb_d8	0x3430, a
	ldb_d8	a, 0x325f
	stb_d8	0x3431, a
	ldb_d8	a, 0x3260
	stb_d8	0x32c3, a
	ldb_d8	a, 0x3261
	stb_d8	0x32c7, a
	call	Rhythm_PackVelocityHighBit
	ld	xhl, 0x3223
	call	AccVoiceReg_StoreParamRecord
	ldb_d8	e, 0x3262
	ldb_d8	d, 0x3263
	ldb_d8	a, 0x3264
	stb_d8	0x342f, a
	ldb_d8	a, 0x3265
	stb_d8	0x3430, a
	ldb_d8	a, 0x3266
	stb_d8	0x3431, a
	ldb_d8	a, 0x3267
	stb_d8	0x32c3, a
	ldb_d8	a, 0x3268
	stb_d8	0x32c7, a
	call	Rhythm_PackVelocityHighBit
	ld	xhl, 0x3228
	call	AccVoiceReg_StoreParamRecord
	calr	481
	calr	402
	calr	171
	calr	244
	calr	317
	stdi8	0x338e, 1
	ldb	a, 20
	stb_d8	0x8d3a, a
	ldb	e, 144
	ldb	d, 16
	ldb	w, 255
	call	SwbtWr_QueuePostEvent
	.byte 0xc1, 0x9f
	ldw	hl, 319
	jr	nz, 10
	xor	wa, wa
	ldb	a, 1
	call	UI_PostPartChangeEvent
	jr	30
	ldb_d8	a, 0x338e
	and	a, 31
	jr	z, 16
	.byte 0xc1, 0xd3
	ldw	hl, 0xfd3c
	.byte 0xc1, 0x91
	ldw	hl, 318
	call	AccTuning_LEDOn
	jr	5
	.byte 0xc1, 0xd3
	ldw	hl, 574
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
	push	sr
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	.zero 24
	nop
	push_a
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
	cpdi8 0x8d34, 17
	jr nz, AccVoiceReg_WritePart3_Ret
	ldb_d8 a, 0x338e
	and a, 0x1f
	jr nz, AccVoiceReg_WritePart3_Ret
	ldb_d8 a, 0x321e
	ldb_d8 w, 0x321f
	bit 4, w
	jr z, AccVoiceReg_WritePart3_StoreBit4
	or a, 0x80
	and w, 0xef

AccVoiceReg_WritePart3_StoreBit4:
	stb_d8 0xfb56, a
	and w, 0x7f
	anddi8 0xfb57, 128
	orddm8 0xfb57, w
	ldb_d8 a, 0x3221
	sla a, 6
	and a, 0x40
	anddi8 0xfb5a, 191
	orddm8 0xfb5a, a
	ldb l, 0x4
	calr AccVoiceState_DispatchChange

AccVoiceReg_WritePart3_Ret:
	ret

AccVoiceReg_WritePart4:
	cpdi8 0x8d34, 17
	jr nz, AccVoiceReg_WritePart4_Ret
	ldb_d8 a, 0x338e
	and a, 0x1f
	jr nz, AccVoiceReg_WritePart4_Ret
	ldb_d8 a, 0x3223
	ldb_d8 w, 0x3224
	bit 4, w
	jr z, AccVoiceReg_WritePart4_StoreBit4
	or a, 0x80
	and w, 0xef

AccVoiceReg_WritePart4_StoreBit4:
	stb_d8 0xfb70, a
	and w, 0x7f
	anddi8 0xfb71, 128
	orddm8 0xfb71, w
	ldb_d8 a, 0x3226
	sla a, 6
	and a, 0x40
	anddi8 0xfb74, 191
	orddm8 0xfb74, a
	ldb l, 0x8
	calr AccVoiceState_DispatchChange

AccVoiceReg_WritePart4_Ret:
	ret

AccVoiceReg_WritePart5:
	cpdi8 0x8d34, 17
	jr nz, AccVoiceReg_WritePart5_Ret
	ldb_d8 a, 0x338e
	and a, 0x1f
	jr nz, AccVoiceReg_WritePart5_Ret
	ldb_d8 a, 0x3228
	ldb_d8 w, 0x3229
	bit 4, w
	jr z, AccVoiceReg_WritePart5_StoreBit4
	or a, 0x80
	and w, 0xef

AccVoiceReg_WritePart5_StoreBit4:
	stb_d8 0xfb8a, a
	and w, 0x7f
	anddi8 0xfb8b, 128
	orddm8 0xfb8b, w
	ldb_d8 a, 0x322b
	sla a, 6
	and a, 0x40
	anddi8 0xfb8e, 191
	orddm8 0xfb8e, a
	ldb l, 0x10
	calr AccVoiceState_DispatchChange

AccVoiceReg_WritePart5_Ret:
	ret

AccVoiceReg_WritePart2:
	cpdi8 0x8d34, 17
	jr nz, AccVoiceReg_WritePart2_Ret
	ldb_d8 a, 0x338e
	and a, 0x1f
	jr nz, AccVoiceReg_WritePart2_Ret
	ldb_d8 a, 0x3219
	ldb_d8 w, 0x321a
	bit 4, w
	jr z, AccVoiceReg_WritePart2_StoreBit4
	or a, 0x80
	and w, 0xef

AccVoiceReg_WritePart2_StoreBit4:
	stb_d8 0xfba4, a
	and w, 0x7f
	anddi8 0xfba5, 128
	orddm8 0xfba5, w
	ldb_d8 a, 0x321c
	sla a, 6
	and a, 0x40
	anddi8 0xfba8, 191
	orddm8 0xfba8, a
	ldb l, 0x2
	calr AccVoiceState_DispatchChange

AccVoiceReg_WritePart2_Ret:
	ret

AccVoiceReg_WritePart1:
	cpdi8 0x8d34, 17
	jr nz, AccVoiceReg_WritePart1_Ret
	ldb_d8 a, 0x338e
	and a, 0x1f
	jr nz, AccVoiceReg_WritePart1_Ret
	ldb_d8 a, 0x3214
	or a, 0xf0
	ldb_d8 w, 0x3215
	and w, 0x7f
	stb_d8 0xfbbe, a
	anddi8 0xfbbf, 128
	orddm8 0xfbbf, w
	ldb l, 0x1
	calr AccVoiceState_DispatchChange

AccVoiceReg_WritePart1_Ret:
	ret

AccVoiceState_Snapshot:
	calr AccHelper_ComputeVoiceOffset
	ld xiy, xhl
	add xiy, 0x1e7810
	ldb_d8 a, 0xfbbe
	ldb_d8 w, 0xfbbf
	and w, 0x7f
	stda16 0x3395, xwa
	and a, 0xf
	ld (xiy + 256), a
	andmi8 (xiy + 1), 0x80
	or (xiy + 1), w
	ldb_d8 a, 0xfba4
	ldb_d8 w, 0xfba5
	and w, 0x7f
	ldb_d8 l, 0xfba8
	and l, 0x40
	sla l, 1
	or w, l
	stda16 0x3397, xwa
	ld (xiy + 2), a
	andmi8 (xiy + 3), 0x0
	or (xiy + 3), w
	ldb_d8 a, 0xfb56
	ldb_d8 w, 0xfb57
	and w, 0x7f
	ldb_d8 l, 0xfb5a
	and l, 0x40
	sla l, 1
	or w, l
	stda16 0x3399, xwa
	ld (xiy + 4), a
	andmi8 (xiy + 5), 0x0
	or (xiy + 5), w
	ldb_d8 a, 0xfb70
	ldb_d8 w, 0xfb71
	and w, 0x7f
	ldb_d8 l, 0xfb74
	and l, 0x40
	sla l, 1
	or w, l
	stda16 0x339b, xwa
	ld (xiy + 6), a
	andmi8 (xiy + 7), 0x0
	or (xiy + 7), w
	ldb_d8 a, 0xfb8a
	ldb_d8 w, 0xfb8b
	and w, 0x7f
	ldb_d8 l, 0xfb8e
	and l, 0x40
	sla l, 1
	or w, l
	stda16 0x339d, xwa
	ld (xiy + 8), a
	andmi8 (xiy + 9), 0x0
	or (xiy + 9), w
	ordi8 0x3393, 1
	ret

AccVoiceState_DispatchChange:
	push xiy
	ld xwa, AccStyle_InlinedBlock_0x1E0
	ldb_sri E, 0x03, 0xe0, 0xec
	extz hl
	sla hl, 2
	ld xwa, AccVoiceState_PartLookupTable_0x80
	ld_sril3 XWA, 0x07, 0xe0, 0xec
	ld xiy, AccVoiceState_PartLookupTable
	ld_sril3 XIY, 0x07, 0xf4, 0xec
	stb_d8 0x90f7, e
	ld l, (xiy + 256)
	and l, 0xff
	ld h, (xiy + 1)
	and h, 0x7f
	pushw de
	push xwa
	push xiy
	call PartCtrl_WriteProgramChange
	pop xiy
	pop xwa
	popw de
	lda_dri XIZ, 0x03, 0xe0, 0xec
	ld a, (xiy + 1)
	and a, 0x7f
	ldb w, 0x7f
	ldb d, 0x1
	pushw wa
	pushw de
	push xhl
	call SwbtWr_QueuePostEvent
	pop xhl
	popw de
	popw wa
	ld a, (xiy + 256)
	and a, 0xff
	ldb w, 0xff
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
	.byte 0x00, 0x00, 0x00, 0x00, 0xbe, 0xfb, 0x00, 0x00
	.byte 0xa4, 0xfb, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x56, 0xfb, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x70, 0xfb, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 24
	.byte 0x8a, 0xfb, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 56
	.byte 0x00, 0x00, 0x00, 0x00, 0x6a, 0xff, 0x00, 0x00
	.byte 0x56, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x1a, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x2e, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 24
	.byte 0x42, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 56

AccVoiceDelta_Part1:
	ldb_d8 a, 0xfbbe
	ldb_d8 w, 0xfbbf
	and w, 0x7f
	cpdm16 0x3395, xwa
	jr z, AccVoiceDelta_Part1_Store
	and a, 0xf
	ld (xiy + 256), a
	andmi8 (xiy + 1), 0x80
	or (xiy + 1), w
	or a, 0xf0
	ordi8 0x3393, 1

AccVoiceDelta_Part1_Store:
	stda16 0x3395, xwa
	ret

AccVoiceDelta_Part2:
	ldb_d8 a, 0xfba4
	ldb_d8 w, 0xfba5
	and w, 0x7f
	ldb_d8 l, 0xfba8
	and l, 0x40
	sla l, 1
	or w, l
	cpdm16 0x3397, xwa
	jr z, AccVoiceDelta_Part2_Store
	ld (xiy + 2), a
	andmi8 (xiy + 3), 0x0
	or (xiy + 3), w
	ordi8 0x3393, 1

AccVoiceDelta_Part2_Store:
	stda16 0x3397, xwa
	ret

AccVoiceDelta_Part3:
	ldb_d8 a, 0xfb56
	ldb_d8 w, 0xfb57
	and w, 0x7f
	ldb_d8 l, 0xfb5a
	and l, 0x40
	sla l, 1
	or w, l
	cpdm16 0x3399, xwa
	jr z, AccVoiceDelta_Part3_Store
	ld (xiy + 4), a
	andmi8 (xiy + 5), 0x0
	or (xiy + 5), w
	ordi8 0x3393, 1

AccVoiceDelta_Part3_Store:
	stda16 0x3399, xwa
	ret

AccVoiceDelta_Part4:
	ldb_d8 a, 0xfb70
	ldb_d8 w, 0xfb71
	and w, 0x7f
	ldb_d8 l, 0xfb74
	and l, 0x40
	sla l, 1
	or w, l
	cpdm16 0x339b, xwa
	jr z, AccVoiceDelta_Part4_Store
	ld (xiy + 6), a
	andmi8 (xiy + 7), 0x0
	or (xiy + 7), w
	ordi8 0x3393, 1

AccVoiceDelta_Part4_Store:
	stda16 0x339b, xwa
	ret

AccVoiceDelta_Part5:
	ldb_d8 a, 0xfb8a
	ldb_d8 w, 0xfb8b
	and w, 0x7f
	ldb_d8 l, 0xfb8e
	and l, 0x40
	sla l, 1
	or w, l
	cpdm16 0x339d, xwa
	jr z, AccVoiceDelta_Part5_Store
	ld (xiy + 8), a
	andmi8 (xiy + 9), 0x0
	or (xiy + 9), w
	ordi8 0x3393, 1

AccVoiceDelta_Part5_Store:
	stda16 0x339d, xwa
	ret

AccStyle_InitVRAM:
	xor a, a
	ld xiy, Display_FontPalette_Table_0x3127
	ld xix, 0x1e7800
	ldw bc, 0x7e0
	ldir85
	ret

AccStyle_SC0ByteSelect:
	.long Pad_AfterBitmap_Dredt0k_2
	rcf
	ldb_d8	a, 0x338e
	and	a, 31
	jr	nz, 5
	stdi8	0xe3de, 16
	stdi8	0x338e, 1
	ret
	stdi8	0xe3e0, 16
	ldb_d8	a, 0x338e
	and	a, 31
	jr	nz, 5
	stdi8	0xe3de, 16
	stdi8	0x338e, 16
	ret
	stdi8	0xe3e0, 16
	ldb_d8	a, 0x338e
	and	a, 31
	jr	nz, 5
	.long Pad_AfterBitmap_Dredt0k
	rcf
	stdi8	0x338e, 8
	ret
	stdi8	0xe3e0, 16
	ldb_d8	a, 0x338e
	and	a, 31
	jr	nz, 5
	stdi8	0xe3de, 16
	stdi8	0x338e, 4
	ret
	stdi8	0xe3e0, 16
	ldb_d8	a, 0x338e
	and	a, 31
	jr	nz, 5
	stdi8	0xe3de, 16
	stdi8	0x338e, 2
	ret

AccHelper_ComputeVoiceOffset:
	xor xwa, xwa
	ldb_d8 l, 0xfc5a
	ldb_d8 h, 0xfc5b
	and h, 0x7
	stdi8 0x90f7, 72
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
	stdi16 0x34d4, 190
	anddi8 0x32f3, 254
	bitda 7, 0x34d1
	jr nz, AccDemo_Init_ConfigTimers
	call AccWidget_DispatchTable

AccDemo_Init_ConfigTimers:
	anddi8 0x34d1, 127
	stdi8 0x39b6, 0
	stdi8 0x39b7, 10
	ret

AccDemo_Init_DataBlock:
	nop
	nop
	ld	xix, 0x094800
	ld	(xix+2976), 0
	ld	(xix+2977), 1
	ld	(xix+2978), 2
	ld	(xix+2979), 3
	ret

AccDemo_LoadRhythm:
	ld xiy, Demo_StyleRhythmData
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
	ld xiy, Demo_StyleRhythmData_0x240
	ldw bc, 0x34
	ldir85
	ld xiy, Demo_StyleRhythmData_0x60
	xor xde, xde
	ld e, a
	mul e, 0x10
	add xiy, xde
	ldw bc, 0x10
	ldir85
	ld xiy, Demo_StyleRhythmData_0x57C
	ldw bc, 0x10
	ldir85
	add a, 0x1
	cp a, 0x1e
	jr lt, AccDemo_LoadVariation_EntryLoop
	ret

AccDemo_LoadVariation_DataBlock:
	ld	xiy, Demo_StyleRhythmData_0x274
	ld	xix, 0x094800
	add	xix, 2976
	ldw	bc, 160
	.byte 0x85
	scf
	ret
	lds32	xwa, 0
	ld	xix, 0x094800
	add	xix, 3136
	lds32	xde, 0
	.byte 0xd7
	lds32	xde, 6
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
	add xix, 0x13c0
	ld xiy, Demo_StyleRhythmData_0x334
	ldir85
	ret

AccDemo_LoadVariationData:
	ld xix, 0x94800
	add xix, 0x1400
	ldb a, 0x1e

Demo_LoadVariationData:
	ld xiy, Demo_StyleRhythmData_0x374
	ldw bc, 0x100
	ldir85
	ldb l, 0x4

Demo_LoadVariationData_Inner:
	ld xiy, Demo_StyleRhythmData_0x474
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
	add xix, 0xaa00
	ldb a, 0xbe

Demo_LoadVariationC_Loop:
	ld xiy, Demo_StyleRhythmData_0x574
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
	push	sr
	push	sr
	push	sr
	push	sr
	nop
	cpd
	jr	f, 0
	jr	f, 0
	calr	0
	.byte 0x01, 0x54, 0x01
	ld	xwa, 0x80000000
	ex_ff
	.zero 48
	.ascii "a-variation1    a-variation2    a-variation3    a-variation4    b-variation1    b-variation2    b-variation3    b-variation4    c-variation1    c-variation2    c-variation3    c-variation4     a-intro 1       a-intro 2       a-fill in 1     a-fill in 2     a-ending 1      a-ending 2      b-intro 1       b-intro 2       b-fill in 1     b-fill in 2     b-ending 1      b-ending 2      c-intro 1       c-intro 2       c-fill in 1     c-fill in 2     c-ending 1      c-ending 2     "
	reti
	pop	sr
	ldb	w, 0
	pop	xwa
	push	sr
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	ld	xwa, 0x7f005000
	nop
	pushw	wa
	nop
	ld	xwa, 0x7f065000
	nop
	nop
	nop
	ld	xwa, 0x7f065000
	nop
	.byte 0x1c
	nop
	ld	xwa, 0x7f065000
	nop
	call	0x4000
	.byte 0x50, 0x06
	jrl	nc, 0
	swi	7
	swi	7
	swi	7
	.zero 12
	.ascii "chord map 1     "
	.byte 0x01
	swi	7
	swi	7
	swi	7
	.zero 12
	.ascii "chord map 2     "
	push	sr
	swi	7
	swi	7
	swi	7
	.zero 12
	.ascii "chord map 3     "
	pop	sr
	swi	7
	swi	7
	swi	7
	.zero 12
	.ascii "chord map 4     "
	.byte 0x04
	swi	7
	swi	7
	swi	7
	.zero 12
	.asciz "chord map 5     "
	nop
	di
	nop
	nop
	di
	nop
	nop
	di
	nop
	nop
	di
	nop
	nop
	di
	nop
	nop
	di
	nop
	nop
	di
	nop
	nop
	di
	cp	(xwa), l
	swi	7
	swi	7
	swi	7
	.byte 0x87, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81
	.byte 0x81, 0x83
	nop
	nop
	nop
	nop
	nop
	.zero 40
	nop
	nop
	nop
	.byte 0x87
	cp	(xwa), l
	swi	7
	swi	7
	swi	7
	.byte 0x87, 0x90
	nop
	ld	xhl, 0x81000358
	.byte 0x90
	nop
	ld	xhl, 0x81000340
	.byte 0x90
	nop
	ld	xhl, 0x81000340
	.byte 0x90
	nop
	ld	xhl, 0x81000340
	.byte 0x90
	nop
	ld	xhl, 0x81000358
	.byte 0x90
	nop
	ld	xhl, 0x81000340
	.byte 0x90
	nop
	ld	xhl, 0x81000340
	.byte 0x90
	nop
	ld	xhl, 0x81000340
	.byte 0x90
	nop
	ld	xhl, 0x81000358
	.byte 0x90
	nop
	ld	xhl, 0x81000340
	.byte 0x90
	nop
	ld	xhl, 0x81000340
	.byte 0x90
	nop
	ld	xhl, 0x81000340
	.byte 0x90
	nop
	ld	xhl, 0x81000358
	.byte 0x90
	nop
	ld	xhl, 0x81000340
	.byte 0x90
	nop
	ld	xhl, 0x81000340
	.byte 0x90
	nop
	ld	xhl, 0x81000340
	.byte 0x83
	nop
	nop
	nop
	nop
	nop
	.zero 128
	nop
	nop
	nop
	.byte 0x87
	cp	(xwa), l
	swi	7
	swi	7
	swi	7
	.byte 0x87, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81
	.fill 8, 1, 0x81
	.byte 0x81, 0x81, 0x83
	nop
	nop
	nop
	nop
	nop
	.zero 224
	nop
	nop
	nop
	.byte 0x87
	nop
	swi	7
	swi	7
	swi	7
	swi	7
	.byte 0x87
	nop
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
	sub a, 0xf0
	extz wa
	sla wa, 2
	lda_24 xbc, Display_FontPalette_Table_0x515C
	ld_sril3 XDE, 0x07, 0xe4, 0xe0
	ld a, (xde)
	extz wa
	sla wa, 2
	lda_24 xbc, RhythmTiming_OffsetTable
	ld xde, 0x94860
	add_sril_rm XDE, 0x07, 0xe4, 0xe0
	ld a, (xde + 12)
	extz wa
	lda_24 xbc, Display_FontPalette_Table_0x1D32
	ldb_sri L, 0x07, 0xe4, 0xe0
	ret

AccTone_ReadAndProcess:
	dec 4, xsp
	lda_d16 xbc, 0xfc5a
	ld e, (xbc)
	and e, 0xff
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
	cp (xwa), 0xf0
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
	sub a, 0xf0
	extz wa
	sla wa, 2
	lda_24 xbc, Display_FontPalette_Table_0x515C
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
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
	ldb_erp A, 0xf4
	extz iy
	ldw_d16 xde, 4360
	ld ix, de
	and ix, 0x4
	lda_24 xhl, Display_FontPalette_Table_0x1EBF
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
	jr AccTone_ExtendAndDispatch_Body

AccTone_ExtendAndDispatch_Body:
	push xiz
	extz bc
	sla bc, 2
	lda_24 xde, Display_FontPalette_Table_0x513C
	ld_sril3 XIY, 0x07, 0xe8, 0xe4
	ld e, a
	extz de
	ld wa, de
	sla wa, 2
	lda_24 xix, RhythmTiming_OffsetTable
	ld xiz, xiy
	add_sril_rm XIZ, 0x07, 0xf0, 0xe0
	ld a, (xiz + 12)
	extz wa
	lda_24 xhl, Display_FontPalette_Table_0x1D32
	ldb_sri A, 0x07, 0xec, 0xe0
	ldb_erp A, 0xe2
	lda_24 xiz, Display_FontPalette_Table_0x511C
	ld_sril3 XBC, 0x07, 0xf8, 0xe4
	add de, 0x11
	ldb_sri C, 0x07, 0xe4, 0xe8
	ldw_d16 xwa, 4360
	ld de, wa
	and de, 0x4
	extz bc
	cps de, 4
	jr nz, AccTone_CheckBit10Flag
	lda_24 xde, Display_FontPalette_Table_0x51E4
	ldb_sri A, 0x07, 0xe8, 0xe4
	extz wa
	sla wa, 2
	ld xiz, xiy
	add_sril_rm XIZ, 0x07, 0xf0, 0xe0
	ld c, (xiz + 12)
	extz bc
	stb_erp A, 0xe2
	cpb_sri_rm A, 0x07, 0xec, 0xe4
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
	lda_24 xde, Display_FontPalette_Table_0x51E8
	ldb_sri A, 0x07, 0xe8, 0xe4
	extz wa
	sla wa, 2
	ld xiz, xiy
	add_sril_rm XIZ, 0x07, 0xf0, 0xe0
	ld c, (xiz + 12)
	extz bc
	stb_erp A, 0xe2
	cpb_sri_rm A, 0x07, 0xec, 0xe4
	jr nz, AccTone_SetupExit

AccTone_FoundMatch_IncRet:
	ld l, (xiz + 13)
	inc 1, l
	jr AccTone_ExtendAndDispatch_PopRet

AccTone_CheckBit3Flag:
	and wa, 0x8
	cp wa, 0x8
	jr nz, AccTone_SetupExit
	stb_erp A, 0xe2
	extz wa
	lda_24 xbc, Display_FontPalette_Table_0x1D58
	bit_dri 0, 0x07, 0xe4, 0xe0
	jr nz, AccTone_SetupExit
	ldb l, 0x1
	jr AccTone_ExtendAndDispatch_PopRet
	dec 4, xsp
	ldw_d16 xde, 4360
	and de, 0x40c
	jrl z, AccTone_LookupFailed
	extz bc
	sla bc, 2
	lda_24 xde, Display_FontPalette_Table_0x513C
	ld_sril3 XDE, 0x07, 0xe8, 0xe4
	extz wa
	sla wa, 2
	lda_24 xbc, RhythmTiming_OffsetTable
	add_sril_rm XDE, 0x07, 0xe4, 0xe0
	ld a, (xde + 12)
	extz wa
	lda_24 xbc, Display_FontPalette_Table_0x1D32
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	lda_24 xbc, Display_FontPalette_Table_0x1D58
	bit_dri 0, 0x07, 0xe4, 0xe0
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
	ldb_d8 a, 0x32ff
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
	.byte 0xf1, 0x1f, 0x34, 0xb0, 0xc1, 0x17, 0x33, 0x3f
	.byte 0x00, 0xd9, 0x76, 0xc1, 0x16, 0x33, 0x3f, 0x00
	.byte 0xda, 0x76, 0xd9, 0xc2, 0xc1, 0x18, 0x33, 0x3f
	.byte 0x00, 0xd9, 0x76, 0xda, 0xc1, 0xc1, 0x12, 0x33
	.byte 0x3f, 0x00, 0xda, 0x76, 0xd9, 0xc2, 0xc1, 0x13
	.byte 0x33, 0x3f, 0x00, 0xd9, 0x76, 0xda, 0xc1, 0xc1
	.byte 0x14, 0x33, 0x3f, 0x00, 0xda, 0x76, 0xd9, 0xc2
	.byte 0xc1, 0x15, 0x33, 0x3f, 0x00, 0xd8, 0x76, 0xda
	.byte 0xc0, 0xb0, 0xf6, 0xc1, 0xe5, 0x32, 0x3f, 0xf0
	.byte 0xb0, 0xf7, 0xc1, 0x80, 0x32, 0x21, 0xc1, 0x25
	.byte 0x34, 0xf1, 0x66, 0x04, 0xf1, 0x1e, 0x34, 0xb0
	.byte 0xf1, 0x1e, 0x34, 0xc8, 0xb0, 0xfe, 0x1e, 0x1f
	.byte 0x00, 0xc1, 0x21, 0x34, 0x21, 0xc1, 0x2a, 0x34
	.byte 0xf1, 0x66, 0x08, 0xf1, 0x1f, 0x34, 0xb8, 0xf1
	.byte 0x1e, 0x34, 0xb8, 0xc1, 0x2a, 0x34, 0x19, 0x21
	.byte 0x34, 0xc1, 0x2b, 0x34, 0x19, 0x20, 0x34, 0x0e
	.byte 0xc1, 0xd8, 0x32, 0x21, 0xd8, 0x12, 0xf2, 0xc8
	.byte 0x9f, 0xe4, 0x31, 0xc3, 0x07, 0xe4, 0xe0, 0x21
	.byte 0xf1, 0x2b, 0x34, 0x41, 0xe1, 0xce, 0x32, 0x21
	.byte 0xd8, 0x12, 0xc3, 0x07, 0xe4, 0xe0, 0x21, 0xf1
	.byte 0x2a, 0x34, 0x41, 0xc9, 0xcf, 0xff, 0xb0, 0xfe
	.byte 0x81, 0x19, 0x2a, 0x34, 0xf1, 0x2b, 0x34, 0x00
	.byte 0x00, 0x0e, 0xf1, 0x1f, 0x34, 0xc8, 0xb0, 0xf6
	.byte 0x1d, 0xad, 0xe7, 0xf5, 0x1d, 0xb4, 0xe7, 0xf5
	.byte 0xc1, 0x21, 0x34, 0x21, 0xd8, 0x12, 0xd8, 0xec
	.byte 0x02, 0xf2, 0x12, 0x63, 0xe4, 0x32, 0x41, 0x60
	.byte 0x48, 0x09, 0x00, 0xe3, 0x07, 0xe8, 0xe0, 0x81
	.byte 0xf1, 0x26, 0x34, 0x61, 0xe9, 0x88, 0x1d, 0x29
	.byte 0xe7, 0xf5, 0xc1
	.byte 0x2c, 0x33, 0x3e, 0x3f
	.byte 0xf1
	.byte 0x2c, 0x33, 0xbf, 0x1e, 0x17, 0x00, 0xc1, 0xd8
	.byte 0x32, 0x19, 0xdf, 0x32, 0xc1, 0xd9, 0x32, 0x19
	.byte 0xe0, 0x32, 0xc1, 0xda, 0x32, 0x19, 0xe1, 0x32
	.byte 0xf1, 0x1f, 0x34, 0xb0, 0x0e, 0x1e, 0x2f, 0x05
	.byte 0xc1, 0xab, 0x32, 0x3c, 0xf0, 0xc1, 0xac, 0x32
	.byte 0x3c, 0xf0, 0xc1, 0xad, 0x32, 0x3c, 0xf0, 0xc1
	.byte 0xae, 0x32, 0x3c, 0xf0, 0xc1, 0xaf, 0x32, 0x3c
	.byte 0xf0, 0xc1, 0xb0, 0x32, 0x3c, 0xf0, 0x1d, 0xbb
	.byte 0xe7, 0xf5, 0xf1, 0xf4, 0x32, 0xce, 0xb0, 0xfe
	.byte 0x1d, 0xc2, 0xe7, 0xf5, 0x0e, 0xda, 0x12, 0xda
	.byte 0xec, 0x02, 0xd9, 0x12, 0xd9, 0xec, 0x05, 0xd9
	.byte 0x8b, 0xda, 0x83, 0x20, 0x00, 0xe8, 0x12, 0xe8
	.byte 0x89, 0xe9, 0xee, 0x02, 0xe8, 0x81, 0xe9, 0xee
	.byte 0x05, 0xe9, 0xc8, 0x40, 0x54, 0x09, 0x00, 0xd3
	.byte 0x07, 0xe4, 0xec, 0x23, 0x0e, 0xda, 0x12, 0xda
	.byte 0xec, 0x02, 0xd9, 0x12, 0xd9, 0xec, 0x05, 0xd9
	.byte 0x8b, 0xda, 0x83, 0x20, 0x00, 0xe8, 0x12, 0xe8
	.byte 0x89, 0xe9, 0xee, 0x02, 0xe8, 0x81, 0xe9, 0xee
	.byte 0x05, 0xe9, 0xc8, 0x40, 0x54, 0x09, 0x00, 0xf3
	.byte 0x07, 0xe4, 0xec, 0x30, 0x98, 0x02, 0x23, 0x0e
	.byte 0xef, 0x6a, 0x3e, 0xc1, 0xe5, 0x32, 0x21, 0xc9
	.byte 0xca, 0xf0, 0xd8, 0x12, 0xd8, 0xec, 0x02, 0xf2
	.byte 0xb4, 0x9f, 0xe4, 0x31, 0xe3, 0x07, 0xe4, 0xe0
	.byte 0x20, 0xf1, 0xce, 0x32, 0x60, 0x80, 0x21, 0xf1
	.byte 0xf1, 0x33, 0x41, 0xd8, 0x12, 0xf2, 0xf9, 0x6b
	.byte 0xe4, 0x31, 0xc3, 0x07, 0xe4, 0xe0, 0x19, 0x38
	.byte 0x33, 0xd8, 0x89, 0xd9, 0xec, 0x02, 0xf2, 0x12
	jr	ule, 0xe4
	.byte 0x32, 0x40, 0x60, 0x48
	.byte 0x09, 0x00
	.byte 0xe3, 0x07, 0xe8, 0xe4, 0x80, 0xf1, 0xf2, 0x33
	.byte 0x60, 0xe8, 0x8e, 0xbf, 0x04, 0x30, 0x8e, 0x10
	.byte 0x23, 0xb0, 0x43, 0x8e, 0x11, 0x25, 0xb8, 0x01
	.byte 0x45, 0x80, 0x27, 0xdb, 0x12, 0xda, 0x12, 0xda
	.byte 0xee, 0x08, 0xda, 0x89, 0xdb, 0xe1, 0xd9, 0xcf
	.byte 0x08, 0x02, 0x66, 0x0f, 0x80, 0x23, 0xd9, 0x12
	.byte 0xd9, 0xe2, 0xda, 0xcf, 0x18, 0x03, 0xf2, 0xeb
	.byte 0xe6, 0xf5, 0xee, 0xbf, 0x04, 0x31, 0x81, 0x21
	.byte 0xd8, 0x12, 0x89, 0x01, 0x23, 0xd9, 0x12, 0x1d
	.byte 0x00, 0xe7, 0xf5, 0xeb, 0x88, 0x1d, 0x17, 0xe7
	.byte 0xf5, 0x8e, 0x0c, 0x21, 0xd8, 0x12, 0xf2, 0x8a
	.byte 0x6b, 0xe4, 0x31, 0xc3, 0x07, 0xe4, 0xe0, 0x19
	.byte 0x33, 0x04, 0xc1, 0x33, 0x04, 0x21, 0xd8, 0x12
	.byte 0xd8, 0x80, 0xf2, 0x9e, 0x6b, 0xe4, 0x31, 0xd3
	.byte 0x07, 0xe4, 0xe0, 0x19, 0x7b, 0x32, 0xc1, 0xf1
	.byte 0x33, 0x21, 0xc9, 0xc8, 0x80, 0xf1, 0x2c, 0x34
	.byte 0x41, 0xd8, 0x12, 0x1d, 0x20, 0xe7, 0xf5, 0x1e
	.byte 0x2e, 0xfe, 0xc1, 0x2a, 0x34, 0x21, 0xf1, 0x21
	.byte 0x34, 0x41, 0xc1, 0x2b, 0x34, 0x19, 0x20, 0x34
	.byte 0xc1, 0x2a, 0x34, 0x21, 0xd8, 0x12, 0xd8, 0xec
	.byte 0x02, 0xf2, 0x12, 0x63, 0xe4, 0x32, 0x41, 0x60
	.byte 0x48, 0x09, 0x00, 0xe3, 0x07, 0xe8, 0xe0, 0x81
	.byte 0xf1, 0x26, 0x34, 0x61, 0xe9, 0x88, 0x1d, 0x29
	.byte 0xe7, 0xf5, 0xc1
	.byte 0x2c, 0x33, 0x3e, 0x3f, 0x5e
	.byte 0xef, 0x62, 0x0e, 0xc1, 0xe5, 0x32, 0x3f, 0xf0
	.byte 0xb0, 0xf7, 0x1e, 0xeb, 0xfd, 0xc1, 0x2a, 0x34
	.byte 0x21, 0xc1, 0x21, 0x34, 0xf1, 0xb0, 0xf6, 0xf1
	.byte 0x3b, 0x33, 0xb8, 0x0e, 0xef, 0x6a, 0x3e, 0xc1
	.byte 0xe5, 0x32, 0x21, 0xc9, 0xca, 0xf0, 0xd8, 0x12
	.byte 0xd8, 0xec, 0x02, 0xf2, 0xb4, 0x9f, 0xe4, 0x31
	.byte 0xe3, 0x07, 0xe4, 0xe0, 0x20, 0xf1, 0xce, 0x32
	.byte 0x60, 0x80, 0x21, 0xf1, 0xf1, 0x33, 0x41, 0xd8
	.byte 0x12, 0xf2, 0xf9, 0x6b, 0xe4, 0x31, 0xc3, 0x07
	.byte 0xe4, 0xe0, 0x19, 0x38, 0x33, 0xd8, 0x89, 0xd9
	.byte 0xec, 0x02, 0xf2, 0x12, 0x63, 0xe4, 0x32, 0x40
	.byte 0x60, 0x48, 0x09, 0x00, 0xe3, 0x07, 0xe8, 0xe4
	.byte 0x80, 0xf1, 0xf2, 0x33, 0x60, 0xe8, 0x8e, 0xbf
	.byte 0x04, 0x30, 0x8e, 0x10, 0x23, 0xb0, 0x43, 0x8e
	.byte 0x11, 0x25, 0xb8, 0x01, 0x45, 0x80, 0x27, 0xdb
	.byte 0x12, 0xda, 0x12, 0xda, 0xee, 0x08, 0xda, 0x89
	.byte 0xdb, 0xe1, 0xd9, 0xcf, 0x08, 0x02, 0x66, 0x0f
	.byte 0x80, 0x23, 0xd9, 0x12, 0xd9, 0xe2, 0xda, 0xcf
	.byte 0x18, 0x03, 0xf2, 0xeb, 0xe6, 0xf5, 0xee, 0xbf
	.byte 0x04, 0x31, 0x81, 0x21, 0xd8, 0x12, 0x89, 0x01
	.byte 0x23, 0xd9, 0x12, 0x1d, 0x00, 0xe7, 0xf5, 0xeb
	.byte 0x88, 0x1d, 0x17, 0xe7, 0xf5, 0x8e, 0x0c, 0x21
	.byte 0xd8, 0x12, 0xf2, 0x8a, 0x6b, 0xe4, 0x31, 0xc3
	.byte 0x07, 0xe4, 0xe0, 0x19, 0x33, 0x04, 0xc1, 0x33
	.byte 0x04, 0x21, 0xd8, 0x12, 0xd8, 0x80, 0xf2, 0x9e
	.byte 0x6b, 0xe4, 0x31, 0xd3, 0x07, 0xe4, 0xe0, 0x19
	.byte 0x7b, 0x32, 0xc1, 0xf1, 0x33, 0x21, 0xc9, 0xc8
	.byte 0x80, 0xf1, 0x2c, 0x34, 0x41, 0xd8, 0x12, 0x1d
	.byte 0x20, 0xe7, 0xf5, 0x1e, 0x12, 0xfd, 0xc1, 0x2a
	.byte 0x34, 0x19, 0x21, 0x34, 0xc1, 0x2b, 0x34, 0x19
	.byte 0x20, 0x34, 0xf1, 0x63, 0x33, 0xc8, 0xf2, 0x68
	.byte 0xe7, 0xf5, 0xe6, 0xc1, 0x21, 0x34, 0x23, 0xd9
	.byte 0x12, 0xd9, 0xec, 0x02, 0xf2, 0x12, 0x63, 0xe4
	.byte 0x32, 0x40, 0x60, 0x48
	.byte 0x09, 0x00, 0xe3, 0x07
	.byte 0xe8, 0xe4, 0x80, 0xf1, 0x26, 0x34, 0x60, 0x1e
	.byte 0x04, 0x00, 0x5e, 0xef, 0x62, 0x0e, 0xc1, 0xff
	.byte 0x32, 0x23, 0xcb, 0x89, 0xc9, 0xcc, 0x07, 0x66
	.byte 0x28, 0xf1, 0x63, 0x33, 0xc8, 0x66, 0x24, 0xcb
	.byte 0xd9, 0x66, 0x31, 0xcb, 0xdc, 0x66, 0x1e, 0xcb
	.byte 0xda, 0x6e, 0x29, 0xc1, 0x33, 0x04, 0x21, 0xd8
	.byte 0x12, 0xf2, 0xb0, 0x6b, 0xe4, 0x31, 0xc3, 0x07
	.byte 0xe4, 0xe0, 0x3f, 0x01, 0x6e, 0x05, 0x1e, 0xfc
	nop
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
	stdi8 0x33eb, 0
	stdi8 0x33ec, 0
	stdi8 0x33ed, 0
	stdi8 0x33ee, 0
	stdi8 0x33ef, 0
	stdi8 0x33f0, 0
	ret

AccVoice_IncrementBarCounter:
	ldb_d8 a, 0x33ea
	inc 1, a
	stb_d8 0x33ea, a
	ldda32 xbc, 0x3426
	cp a, (xbc + 13)
	ret ule
	stdi8 0x33ea, 0
	ret

AccVoice_BarCounterBytecodeData:
	.byte 0xf1, 0xe0, 0x33, 0x00, 0x00, 0xc1, 0x21, 0x34
	.byte 0x21, 0xd8, 0x12, 0xc1, 0xeb, 0x33, 0x25, 0xda
	.byte 0x12, 0xd9, 0xa8, 0x1e, 0xe8, 0xfa, 0xf1, 0x97
	.byte 0x32, 0x53, 0xdb, 0xcf, 0xfe, 0xff, 0x6e, 0x04
	.byte 0xf1, 0xe0, 0x33, 0xb8, 0xc1, 0x21, 0x34, 0x21
	.byte 0xd8, 0x12, 0xc1, 0xeb, 0x33, 0x25, 0xda, 0x12
	.byte 0xd9, 0xa8, 0x1e, 0xf1, 0xfa, 0xf1, 0x87, 0x32
	.byte 0x53, 0xc1, 0x21, 0x34, 0x21, 0xd8, 0x12, 0xc1
	.byte 0xed, 0x33, 0x25, 0xda, 0x12, 0xd9, 0xa9, 0x1e
	.byte 0xb4, 0xfa, 0xf1, 0x9b, 0x32, 0x53, 0xdb, 0xcf
	.byte 0xfe, 0xff, 0x6e, 0x04, 0xf1, 0xe0, 0x33, 0xba
	.byte 0xc1, 0x21, 0x34, 0x21, 0xd8, 0x12, 0xc1, 0xed
	.byte 0x33, 0x25, 0xda, 0x12, 0xd9, 0xa9, 0x1e, 0xbd
	.byte 0xfa, 0xf1, 0x8b, 0x32, 0x53, 0xc1, 0x21, 0x34
	.byte 0x21, 0xd8, 0x12, 0xc1, 0xee, 0x33, 0x25, 0xda
	.byte 0x12, 0xd9, 0xaa, 0x1e, 0x80, 0xfa, 0xf1, 0x9d
	.byte 0x32, 0x53, 0xdb, 0xcf, 0xfe, 0xff, 0x6e, 0x04
	.byte 0xf1, 0xe0, 0x33, 0xbb, 0xc1, 0x21, 0x34, 0x21
	.byte 0xd8, 0x12, 0xc1, 0xee, 0x33, 0x25, 0xda, 0x12
	.byte 0xd9, 0xaa, 0x1e, 0x89, 0xfa, 0xf1, 0x8d, 0x32
	.byte 0x53, 0xc1, 0x21, 0x34, 0x21, 0xd8, 0x12, 0xc1
	.byte 0xef, 0x33, 0x25, 0xda, 0x12, 0xd9, 0xab, 0x1e
	.byte 0x4c, 0xfa, 0xf1, 0x9f, 0x32, 0x53, 0xdb, 0xcf
	.byte 0xfe, 0xff, 0x6e, 0x04, 0xf1, 0xe0, 0x33, 0xbc
	.byte 0xc1, 0x21, 0x34, 0x21, 0xd8, 0x12, 0xc1, 0xef
	.byte 0x33, 0x25, 0xda, 0x12, 0xd9, 0xab, 0x1e, 0x55
	.byte 0xfa, 0xf1, 0x8f, 0x32, 0x53, 0xc1, 0x21, 0x34
	.byte 0x21, 0xd8, 0x12, 0xc1, 0xf0, 0x33, 0x25, 0xda
	.byte 0x12, 0xd9, 0xac, 0x1e, 0x18, 0xfa, 0xf1, 0xa1
	.byte 0x32, 0x53, 0xdb, 0xcf, 0xfe, 0xff, 0x6e, 0x04
	.byte 0xf1, 0xe0, 0x33, 0xbd, 0xc1, 0x21, 0x34, 0x21
	.byte 0xd8, 0x12, 0xc1, 0xf0, 0x33, 0x25, 0xda, 0x12
	.byte 0xd9, 0xac, 0x1e, 0x21, 0xfa, 0xf1, 0x91, 0x32
	.byte 0x53, 0xf1, 0x99, 0x32, 0x02, 0xfe, 0xff, 0xf1
	.byte 0x89, 0x32, 0x02, 0x06, 0x00, 0xf1, 0xe0, 0x33
	.byte 0xb9, 0x0e, 0xef, 0x6a, 0x3e, 0xf2, 0x12, 0x63
	.byte 0xe4, 0x31, 0xf1, 0x63, 0x33, 0xc8, 0x66, 0x7e
	.byte 0xc1, 0x0b, 0x33, 0x21, 0xc9, 0xd9, 0x66, 0x3e
	.byte 0xc9, 0xda, 0x6e, 0x3a, 0xc1, 0x33, 0x04, 0x21
	.byte 0xc1, 0x6e, 0x33, 0xf1, 0x6e, 0x1e, 0xc1, 0x6f
	.byte 0x33, 0x21, 0xd8, 0x12, 0xd8, 0xec, 0x02, 0x46
	.byte 0x60, 0x48, 0x09, 0x00, 0xe3, 0x07, 0xe4, 0xe0
	.byte 0x86, 0xee, 0x88, 0x1d, 0x5f, 0xe7, 0xf5, 0xee
	.byte 0x88, 0x78, 0xac, 0x00, 0x1e, 0x9b, 0xfd, 0xe1
	.byte 0x26, 0x34, 0x20, 0x1d, 0x5f, 0xe7, 0xf5, 0xe1
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
	.byte 0xb3, 0x45, 0x84, 0x25, 0xb1, 0x45, 0x83, 0x27
	.byte 0xdb, 0x12, 0xda, 0x12, 0xda, 0xee, 0x08, 0xda
	.byte 0x89, 0xdb, 0xe1, 0xd9, 0xcf, 0x08, 0x02, 0x66
	.byte 0x0f, 0x80, 0x23, 0xd9, 0x12, 0xd9, 0xe2, 0xda
	.byte 0xcf, 0x18, 0x03, 0xf2, 0xeb, 0xe6, 0xf5, 0xee
	.byte 0xbf, 0x04, 0x31, 0x81, 0x21, 0xd8, 0x12, 0x89
	.byte 0x01, 0x23, 0xd9, 0x12, 0x1d, 0x00, 0xe7, 0xf5
	.byte 0xeb, 0x8e, 0xc1, 0x0a, 0x33, 0x21, 0xc9, 0xd9
	.byte 0x66, 0x13, 0xc9, 0xdc, 0x66, 0x0a, 0xc9, 0xcf
	.byte 0x08, 0x6e, 0x0a, 0x31, 0x20, 0x04, 0x68, 0x08
	.byte 0x31, 0x22, 0x00, 0x68, 0x03, 0x31, 0x20, 0x00
	.byte 0xee, 0x88, 0x1d, 0x80, 0xe7, 0xf5, 0xe1, 0xf2
	.byte 0x33, 0x20, 0x1d, 0x29, 0xe7, 0xf5, 0xc1, 0x2c
	.byte 0x33, 0x3e, 0x3f, 0x5e
	.byte 0xef, 0x62, 0x0e

AccTuning_ReadAndApplyOffset:
	ldb_d8 a, 0x3423
	extz wa
	lda_24 xbc, Display_FontPalette_Table_0x5170
	ldmm_srib 0x07, 0xe4, 0xe0, 0x22, 0x34
	ret

AccTuning_ComplexBytecodeData:
	.byte 0xef, 0x6a, 0x3e, 0xf1, 0x63, 0x33, 0xc8, 0x76
	.byte 0xb3, 0x00, 0xc1, 0x70, 0x34, 0x23, 0xcb, 0x8d
	.byte 0xcd, 0xcc, 0x80, 0xc1, 0xd4, 0x33, 0x27, 0xcf
	.byte 0x06, 0xcd, 0xcf, 0x80, 0x66, 0x0d, 0xc1, 0xfb
	.byte 0x32, 0x25, 0xcd, 0x89, 0xc9, 0xcc, 0x02, 0xc9
	.byte 0xda, 0x6e, 0x30, 0xc1, 0x12, 0x33, 0xcf, 0xc1
	.byte 0x33, 0x04, 0x21, 0xc1, 0x6a, 0x33, 0xf1, 0x6e
	.byte 0x0e, 0xc1, 0xd4, 0x33, 0x21, 0xc1, 0x13, 0x33
	and	xbc, xbc
	.ascii "k3%h"
	.byte 0x04, 0xc1
	.byte 0x21, 0x34, 0x25, 0xc1, 0xd4, 0x33, 0x21, 0xc9
	.byte 0xda, 0x6e, 0x35, 0xf1, 0xd6, 0x33, 0x02, 0xfe
	.byte 0xff, 0x68, 0x5a, 0xcb, 0xcc, 0x40, 0xcb, 0xcf
	.byte 0x40, 0x66, 0x09, 0xcd, 0xcc, 0x01, 0xcd, 0x89
	.byte 0xc9, 0xd9, 0x6e, 0xdf, 0xc1, 0x13, 0x33, 0xcf
	.byte 0xc1, 0x33, 0x04, 0x21, 0xc1, 0x68, 0x33, 0xf1
	.byte 0x6e, 0xcd, 0xc1, 0xd4, 0x33, 0x21, 0xc1, 0x12
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
	ret

AccTone_WriteProgramChange:
	push xiz
	ld xix, xwa
	ld l, (xbc)
	ld h, (xbc + 1)
	stdi8 0x90f7, 72
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
	call	AccVoice_LookupWithOffset
	ld	xhl, xiy
	pop	xiz
	ret
	push	xiz
	ld	xiy, xwa
	call	Rhythm_UpdateTuningConfig
	pop	xiz
	ret
	push	xiz
	ld	w, a
	call	AccPatch_SetByChordIndex
	pop	xiz
	ret
	push	xiz
	ld	xiy, xwa
	call	AccTuning_CopyAllPartsFromStyle
	pop	xiz
	ret
	push	xiz
	ld	xiy, xwa
	ld	xhl, xbc
	and	xhl, 0xffff
	call	AccVoice_LoadTuningBlock
	pop	xiz
	ret
	push	xiz
	and	xwa, 255
	call	AccVoice_ComputeParamAddr
	and	xhl, 0xffff
	pop	xiz
	ret
	push	xiz
	ld	xiy, xwa
	call	AccPart_InitPositionsAndBase
	pop	xiz
	ret
	push	xiz
	ld	xiy, xwa
	call	AccInit_AllPartPositions
	pop	xiz
	ret
	push	xiz
	call	AccPedal_ProcessAllChanges
	pop	xiz
	ret
	push	xiz
	ld	xiy, xwa
	ld	xhl, xbc
	and	xhl, 0xffff
	call	AccStyle_SetupPartAddressesByHL
	pop	xiz
	ret
	push	xiz
	ld	xiy, xwa
	ld	xhl, xbc
	and	xhl, 0xffff
	call	AccVoice_LoadAllParts
	pop	xiz
	ret
	push	xiz
	call	AccStyle_ApplyChanges
	pop	xiz
	ret
	push	xiz
	call	Rhythm_SendNoteOnMax
	pop	xiz
	ret
	push	xiz
	call	AccompVoice_BulkReadRegisters
	pop	xiz
	ret
	push	xiz
	call	AccBuf_WriteAllNotesOff
	pop	xiz
	ret
	push	xiz
	call	Rhythm_SendChanPressure
	pop	xiz
	ret
	push	xiz
	call	AccBuf_ResetAll4
	pop	xiz
	ret
	push	xiz
	call	AccSeq_DualPartScan
	pop	xiz
	ret
	push	xiz
	call	AccSeq_FourChannelScan
	pop	xiz
	ret
	push	xiz
	call	AccPedal_DirectionA
	and	xhl, 0xffff
	pop	xiz
	ret
	push	xiz
	ld	xiy, xwa
	ld	xhl, xbc
	and	xhl, 0xffff
	call	AccPart_GetParamAddr
	and	xwa, 0xffff
	ld	xhl, xwa
	pop	xiz
	ret
	push	xix
	.ascii "=>89:;"
	xor	xwa, xwa
	ldb_d8	a, 0x33d4
	call	AccTone_InlineBytecodeData_0x576
	.ascii "[ZYX^]\\"
	ret
	.ascii "<=>89:;è"
	.byte 0xd0
	ldb_d8	a, 0x33d4
	call	AccTone_InlineBytecodeData_0x5A4
	.ascii "[ZYX^]\\"
	ret

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
	call	AccVoice_BarCounterBytecodeData
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
	call	AccVoice_BarCounterBytecodeData_0x11A
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
	call	AccVoice_BarCounterBytecodeData_0x215
	.ascii "[ZYX^]\\"
	ret
	.ascii "<=>89:;"
	call	AccVoice_BarCounterBytecodeData_0x30A
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
	call	AccTone_ReadAndProcess
	ld	a, l
	pop	xhl
	pop	xde
	ld	e, a
	pop	xbc
	pop	xwa
	pop	xiz
	pop	xiy
	pop	xix
	ret

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
	call	AccTuning_ComplexBytecodeData
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
	and xwa, 0xff
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
	call	AccTone_InlineBytecodeData
	ret
	call	AccTone_InlineBytecodeData_0x2A4
	ret
	call	AccTone_InlineBytecodeData_0x28B
	ret
	call	AccTone_InlineBytecodeData_0x188
	ret
	call	AccTone_InlineBytecodeData_0xB2
	ret
	push	xiz
	call	AccStyle_UseSecondarySource
	pop	xiz
	ret
	push_f
	cp	xiy, xbc
	nop
	.byte 0x17
	cp	xiy, xbc
	nop
	ldw	bc, 0xf5e9
	nop
	ldb	a, 233
	.byte 0xf5
	nop

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
	stdi8 0x39b7, 10
	ret

AccDemo_InitDone:
	push xiz
	call AccDemo_Init_Wrap
	calr AccPatch_CountAvailableSlots
	pop xiz
	ret

AccPatch_InitByteData:
	push	xiz
	call	AccPatch_InitSlotChain_WithAddr
	pop	xiz
	ret
	call	AccPatch_VoiceAssignDataBlock
	ret
	call	AccDemo_Init_Wrap
	ret
	push	xiz
	calr	4581
	calr	2801
	.byte 0xc1, 0xcd
	ldw	ix, 0x803e
	pop	xiz
	ret

AccDemo_InitWithFlag:
	push xiz
	ordi8 0x34d1, 128
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
	call	AccPatch_InitSlotChain_WithAddr
	pop	xiz
	ret
	push	xiz
	calr	2
	pop	xiz
	ret

AccPatch_ClearModeFlag:
	stdi8 0x35d5, 0
	ret


Not_sure_maybe_SOFT_VERSION_related:
	.byte 0xc1
	ex_ff
	ldw	iz, 0xfe3c
	stdi8	0x35d5, 0
	ld	xwa, 0x094800
	cps	hl, 0
	jr	z, 19
	stdi8	0x35d5, 1
	call	Get_Firmware_Version
	cp	l, 255
	jr	z, 5
	stdi8	0x35d5, 0
	ret
	.byte 0xc1, 0x9b, 0x37, 0x04, 0xc1
	ex_ff
	ldw	iz, 0xfe3c
	stdi8	0x35d5, 0
	.byte 0xc1, 0xd6
	ldw	ix, 0xf104
	.byte 0xd6
	ldw	ix, 0
	.byte 0xc1, 0xd6
	ldw	ix, 7743
	jr	z, 46
	stdi8	0x379b, 16
	calr	62
	stdi8	0x379b, 8
	calr	54
	stdi8	0x379b, 1
	calr	46
	stdi8	0x379b, 2
	calr	38
	stdi8	0x379b, 4
	calr	30
	incdi8	1, 0x34d6
	jr	-53
	.byte 0xf1, 0xd6
	ldw	ix, 0xf104
	.byte 0x9b, 0x37, 0x04, 0xc1
	ex_ff
	ldw	iz, 0xfe3c
	.byte 0xc1, 0xd5
	ldw	iy, 63
	jr	z, 3
	calr	65314
	ret
	calr	367
	calr	446
	ldb	w, 0
	mul8rr	a, c
	calr	38
	.byte 0xd1
	ccf
	ldw	iz, 0xff3f
	swi	7
	jr	z, 5
	calr	145
	jr	8
	calr	65284
	.byte 0xc1
	ex_ff
	ldw	iz, 318
	.byte 0xf1
	ex_ff
	ldw	iz, 0x66c8
	halt
	stdi8	0x35d5, 1
	.byte 0xc1
	ex_ff
	ldw	iz, 0xfe3c
	ret
	ldb	w, 0
	ldb	c, 0
	cp	c, a
	jr	z, 26
	push	c
	pushw	wa
	calr	350
	cp	a, 131
	jr	z, 7
	popw	wa
	pop	c
	inc	1, c
	jr	-22
	popw	wa
	pop	c
	calr	3
	ld	w, b
	ret
	cp	c, a
	jr	z, 17
	push	c
	push_a
	calr	17
	cps	b, 1
	jr	z, 9
	pop_a
	pop	c
	inc	1, c
	jr	-21
	jr	3
	pop_a
	pop	c
	ret
	ldw_d16	hl, 0x3612
	calr	836
	ldw_d16	hl, 0x3614
	.byte 0xf3
	.long StyleGroup_FunkFusion_Pad
	.byte 0x81
	ldw_d16	wa, 0x3614
	cp	wa, 254
	jr	nz, 20
	.byte 0xd1, 0xd4
	ldw	ix, 63
	nop
	jr	nz, 4
	ldb	b, 1
	jr	16
	call	AccPatch_SeqAdvStep_WrapToNext
	ldb	b, 0
	jr	8
	inc	1, wa
	stda16	0x3614, wa
	ldb	b, 0
	ret
	ldw_d16	hl, 0x3612
	calr	780
	ldw_d16	hl, 0x3614
	.byte 0xf3
	.long StyleGroup_FunkFusion_Pad
	.byte 0x83
	ld	hl, (xix+3)
	.byte 0xbc
	pop	sr
	push	sr
	swi	7
	swi	7
	cp	hl, 340
	jr	nc, 21
	calr	753
	.byte 0x84
	push	xix
	jrl	nc, 924
	ldb	c, 188
	.byte 0x01
	push	sr
	swi	7
	swi	7
	.byte 0xbc
	pop	sr
	push	sr
	swi	7
	swi	7
	jr	-27
	ret

AccPatch_CheckAndInitDemo:
	ld xiy, 0x94800
	add xiy, 0xe
	ld wa, (xiy)
	cps wa, 0
	jr z, AccPatch_CheckAndInitDemo_Ret
	call AccDemo_Init_Wrap

AccPatch_CheckAndInitDemo_Ret:
	ret

AccPatch_SlotConfigByteData:
	ret
	ret
	.byte 0xc1, 0x9b, 0x37, 0x04, 0xc1, 0xd6
	ldw	ix, 0xf104
	.byte 0xd6
	ldw	ix, 0
	.byte 0xc1, 0xd6
	ldw	ix, 3135
	jr	z, 46
	stdi8	0x379b, 16
	calr	47
	stdi8	0x379b, 8
	calr	39
	stdi8	0x379b, 1
	calr	31
	stdi8	0x379b, 2
	calr	23
	stdi8	0x379b, 4
	calr	15
	incdi8	1, 0x34d6
	jr	-53
	.byte 0xf1, 0xd6
	ldw	ix, 0xf104
	.byte 0x9b, 0x37, 0x04
	ret
	.byte 0xc1, 0xd6
	ldw	ix, 3135
	jr	nc, 41
	calr	39
	calr	62
	calr	115
	ld	e, c
	ldb	c, 1
	cp	c, e
	jr	z, 24
	push	e
	push_a
	push	c
	calr	121
	pop	c
	push	c
	calr	134
	pop	c
	pop_a
	pop	e
	inc	1, c
	jr	-28
	ret

AccPatch_InitCurrentSlotPointer:
	calr AccPatch_GetCurrentSlotAddr
	ldb_d8 a, 0x379b
	calr MapBitFlagsToChannelOffset
	ldw_sri HL, 0x03, 0xf4, 0xe1
	stda16 0x3612, xhl
	stdi16 0x3614, 6
	ret

AccPatch_SlotScanByteData:
	ldb	c, 0
	cp	c, 8
	jr	z, 11
	push	c
	calr	86
	pop	c
	inc	1, c
	jr	-16
	ret
	call	AccPatch_SeqReadByte
	cp	a, 129
	jr	z, 19
	cp	a, 131
	jr	z, 22
	push_a
	call	AccPatch_AdvanceSeqIndex
	pop_a
	.byte 0xf1
	ex_ff
	ldw	iz, 0x6ec8
	push	sr
	jr	-28
	push_a
	call	AccPatch_AdvanceSeqIndex
	pop_a
	jr	0
	ret
	calr	435
	lds32	xwa, 0
	ld	a, (xiy+12)
	add	xwa, Display_FontPalette_Table_0x1D32
	ld	a, (xwa)
	ld	c, (xiy+13)
	inc	1, c
	ret
	ldb	c, 0
	cp	c, a
	jr	z, 13
	push	c
	push_a
	calr	65465
	pop_a
	pop	c
	inc	1, c
	jr	-17
	ret
	push	c
	lds32	xwa, 0
	ldb	a, 160
	ldb_d8	c, 0x34d6
	mul8rr	a, c
	lds32	xbc, 0
	ldb_d8	c, 0x379b
	and	c, 31
	srl	c, 1
	add	xbc, AccPatch_SlotScanByteData_0xB2
	lds32	xde, 0
	ld	e, (xbc)
	mul	de, 32
	add	xwa, xde
	add	xwa, 3136
	add	xwa, 0x094800
	ld	xix, xwa
	pop	c
	sll	c, 2
	ldw_d16	wa, 0x3612
	.byte 0xf3
	pop	sr
	.byte 0xf0, 0xe4, 0x50
	ldw_d16	wa, 0x3614
	inc	2, c
	.byte 0xf3
	pop	sr
	.byte 0xf0, 0xe4, 0x50
	ret
	push	sr
	pop	sr
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
	add xhl, AccPatch_VoiceStrideTable
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
	cpdi8 0x8d36, 178
	jr z, RhythmProc_StyleChange_Init
	jr RhythmProc_StyleChange_Ret

RhythmProc_StyleChange_Init:
	bitda 2, 0x34cd
	jr z, RhythmProc_StyleChange_Ret
	anddi8 0x34cd, 251
	calr AccPatch_InitCurrentSlot
	calr AccPatch_UpdateAllChains
	call RhythmPatInit_LoadParams

RhythmProc_StyleChange_Ret:
	ret

RhythmProc_CheckPlayMode:
	cpdi8 0x8d36, 181
	jr z, RhythmProc_PlayMode_Compare
	ldb_d8 a, 0x34cf
	and a, 0xf3
	stb_d8 0x34cf, a
	jr AccPatch_CopySlotsExit

RhythmProc_PlayMode_Compare:
	cpdi8 0x3525, 181
	jr z, RhythmProc_PlayMode_SendTempo
	stdi8 0x35fe, 0
	ldb_d8 a, 0x32b3
	and a, 0x7
	stb_d8 0x34dc, a

RhythmProc_PlayMode_SendTempo:
	bitda 1, 0x34cf
	jr z, AccPatch_DetectModeChange
	anddi8 0x34cf, 253
	ldb_d8 a, 0x34cf
	and a, 0xc
	cps a, 0
	jr nz, AccPatch_DetectModeChange
	ldb_d8 a, 0x35fc
	and a, 0xc
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
	ldb_d8 a, 0x32b3
	and a, 0x7
	cpda8 a, 0x34dc
	jr z, AccPatch_CopySlotsExit
	stb_d8 0x34dc, a
	cpdi8 0x8d38, 181
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
	ld xix, 0x34bc
	push xix
	push xiy
	pop xix
	pop xiy
	ld xbc, 0x10
	ldir85
	ret

RhythmProc_ChannelMapTable:
	.byte 0x00, 0x00, 0x00, 0x00, 0x04, 0x04, 0x04, 0x04
	.byte 0x08, 0x08, 0x08, 0x08, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04
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
	ldb_d8 l, 0x34d6
	cp l, 0x1e
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
	ldb_d8	l, 0x34d6
	cp	l, 30
	jr	c, 2
	xor	l, l
	mul	hl, 96
	add	xhl, 96
	ld	xiy, 0x094800
	add	xiy, xhl
	pop	xix
	pop	xwa
	ret

; ============================================================================
; AccPatch_GetEntryAddr - Get address of an accompaniment patch entry by index
; ============================================================================
; Input:  HL = patch entry index (0xffff = return immediately)
; Output: XIX = pointer to patch entry (at 0x95c00 + index*256)
; Converts a patch index to a memory address in the patch data table.
; Each entry is 256 bytes. Returns immediately if index is 0xffff (invalid).
; ============================================================================
AccPatch_GetEntryAddr:
	cp hl, 0xffff
	jr z, AccPatch_GetEntryAddr_Ret
	pushw hl
	pushw hl
	lds32 xhl, 0
	popw hl
	sll xhl, 8
	ld xix, 0x95c00
	add xix, xhl
	popw hl

AccPatch_GetEntryAddr_Ret:
	ret

AccPatch_InitCurrentSlot:
	calr AccPatch_GetCurrentSlotAddr
	calr AccPatch_FreeAllChains
	calr AccPatch_CopyDefaultsForInit
	calr AccPatch_FillAllVoiceData
	ordi8 0x34cd, 128
	calr AccPatch_ScanToSequenceStart
	ret

AccPatch_InitFromSlotIndex:
	push xiz
	calr AccPatch_InitFromIndex
	pop xiz
	ret

AccPatch_InitFromIndex:
	xor xhl, xhl
	ldb_d8 l, 0x39ac
	cp l, 0x1e
	jr c, AccPatch_InitFromIndex_Valid
	xor l, l

AccPatch_InitFromIndex_Valid:
	mul hl, 0x60
	add xhl, 0x60
	ldda32 xiy, 0x39ae
	add xiy, xhl
	calr AccPatch_FreeAllChains_Alt
	calr AccPatch_CopyDefaultsToSlot
	calr AccPatch_FillAllSlots_Alt
	ordi8 0x34cd, 128
	calr AccPatch_ScanSequenceToEnd
	ret

AccPatch_InitByteStub:
	push	xiz
	calr	2
	pop	xiz
	ret

AccPat_InitWorkAreaFromSlot:
	push xwa
	ldb_d8 a, 0x34d6
	stb_d8 0x39ac, a
	ld xwa, 0x94800
	stda32 0x39ae, xwa
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
	add xiy, 0xc
	ld xix, AccPatch_DefaultSlotData
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
	ldb_d8 w, 0x39ac
	cp w, 0xe
	jr nz, AccPatch_ClearSlot13_Check0F
	ld (xiy + 13), a

AccPatch_ClearSlot13_Check0F:
	cp w, 0xf
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
	cp w, 0x1a
	jr nz, AccPatch_ClearSlot13_Check1B
	ld (xiy + 13), a

AccPatch_ClearSlot13_Check1B:
	cp w, 0x1b
	jr nz, AccPatch_ClearSlot13_Done
	ld (xiy + 13), a

AccPatch_ClearSlot13_Done:
	pop xwa
	ret

AccPatch_MiscByteData:
	calr	65262
	calr	15
	calr	177
	calr	88
	.byte 0xc1, 0xcd
	ldw	ix, 0x803e
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
	cp wa, 0xffff
	jr z, AccPatch_FreeChain_Done

AccPatch_FreeChainLoop:
	ld hl, wa
	ldw (xix + 3), 0xffff
	calr AccPatch_GetEntryAddr
	ldw (xix + 1), 0xffff
	andmi8 (xix), 0x7f
	incdi16 1, 0x34d4
	ld wa, (xix + 3)
	cp wa, 0xffff
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
	ld xbc, Display_FontPalette_Table_0x1D32
	ldb_sri A, 0x07, 0xe4, 0xec
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
	add xiy, 0xc
	ld xix, AccPatch_DefaultSlotData
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
	push	sr
	nop
	nop
	.zero 8
	nop
	nop
	nop
	nop
	pushw	wa
	nop
	ld	xwa, 0x7f065000
	nop
	nop
	nop
	incf
	nop
	.byte 0x50, 0x06
	jrl	nc, 14336
	nop
	jrl	ov, 20480
	.byte 0x06
	jrl	nc, 16640
	nop
	ld	xwa, 0x7f065000
	nop
	.asciz "    clear       "
	.zero 15

AccPatch_ClearSlot13BySlotIdx:
	ldb a, 0x0
	cpdi8 0x34d6, 14
	jr nz, AccPatch_ClearSlot13_Idx0F
	ld (xiy + 13), a

AccPatch_ClearSlot13_Idx0F:
	cpdi8 0x34d6, 15
	jr nz, AccPatch_ClearSlot13_Idx14
	ld (xiy + 13), a

AccPatch_ClearSlot13_Idx14:
	cpdi8 0x34d6, 20
	jr nz, AccPatch_ClearSlot13_Idx15
	ld (xiy + 13), a

AccPatch_ClearSlot13_Idx15:
	cpdi8 0x34d6, 21
	jr nz, AccPatch_ClearSlot13_Idx1A
	ld (xiy + 13), a

AccPatch_ClearSlot13_Idx1A:
	cpdi8 0x34d6, 26
	jr nz, AccPatch_ClearSlot13_Idx1B
	ld (xiy + 13), a

AccPatch_ClearSlot13_Idx1B:
	cpdi8 0x34d6, 27
	jr nz, AccPatch_ClearSlot13_IdxDone
	ld (xiy + 13), a

AccPatch_ClearSlot13_IdxDone:
	ret

AccPatch_SetVoiceAndInit:
	calr AccPatch_GetCurrentSlotAddr
	ldb_d8 a, 0x34d8
	ld (xiy + 12), a
	push xiy
	calr AccPatch_InitAllSentinels
	pop xiy
	lds32 xhl, 0
	ldb_d8 l, 0x34d8
	sll l, 1
	xor h, h
	add xhl, AccPatch_VoiceStrideTable
	ld wa, (xhl)
	ld (xiy + 16), wa
	calr AccPatch_CheckConfigType
	ordi8 0x34cd, 128
	ret

AccPatch_VoiceStrideTable:
	.byte 0x00, 0x00, 0x58, 0x02, 0x08, 0x02, 0x18, 0x03
	.byte 0x00, 0x00, 0x00, 0x00, 0x09, 0x01, 0x58, 0x02
	.byte 0x00, 0x00, 0x08, 0x02, 0x00, 0x00, 0x18, 0x03
	.byte 0x00, 0x00, 0x00, 0x00, 0x09, 0x01, 0x58, 0x02
	.byte 0x00, 0x00, 0x08, 0x02, 0x00, 0x00, 0x18, 0x03

AccPatch_CheckConfigType:
	cpdi8 0x34d9, 6
	jr z, RhythmConfig_CheckAndSkip
	cpdi8 0x34d9, 8
	jr z, RhythmConfig_CheckAndSkip
	cpdi8 0x34d9, 4
	jr z, RhythmConfig_CheckAndSkip
	cpdi8 0x34d9, 3
	jr z, RhythmConfig_CheckAndSkip
	jr AccPatch_CheckConfig_Done

RhythmConfig_CheckAndSkip:
	call RhythmConfig_ReturnStub

AccPatch_CheckConfig_Done:
	ret

AccPatch_InitAllSentinels:
	calr AccPatch_ReadVoiceStride
	lds32 xwa, 0
	ldb_d8 a, 0x34d9
	ldb_d8 b, 0x34d7
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
	ldb_d8 l, 0x34d8
	ld xbc, Display_FontPalette_Table_0x1D32
	add xbc, xhl
	ld a, (xbc)
	stb_d8 0x34d9, a
	ret

RhythmProc_CheckRhythmEdit:
	cpdi8 0x8d36, 180
	jr nz, RhythmProc_RhythmEdit_Ret
	calr RhythmProc_CheckVoiceChange
	calr RhythmProc_CheckConfigBits

RhythmProc_RhythmEdit_Ret:
	ret

RhythmProc_CheckVoiceChange:
	bitda 1, 0x34ce
	jr z, RhythmProc_CheckVoiceUpdate
	anddi8 0x34ce, 253
	calr AccPatch_SetVoiceAndInit

RhythmProc_CheckVoiceUpdate:
	bitda 0, 0x34ce
	jr z, RhythmProc_VoiceUpdate_Ret
	anddi8 0x34ce, 254
	calr RhythmProc_UpdateVoiceSentinels

RhythmProc_VoiceUpdate_Ret:
	ret

RhythmProc_UpdateVoiceSentinels:
	calr AccPatch_GetCurrentSlotAddr
	ldb_d8 a, 0x34d7
	and a, 0x7
	ld (xiy + 13), a
	calr AccPatch_InitAllSentinels
	ret

RhythmProc_CheckConfigBits:
	bitda 0, 0x34d2
	jr z, RhythmProc_ConfigBit1
	anddi8 0x34d2, 254
	calr AccPatch_GetCurrentSlotAddr
	andmi8 (xiy + 14), 0xf0
	ldb_d8 a, 0x34e9
	and a, 0xf
	or (xiy + 14), a

RhythmProc_ConfigBit1:
	bitda 1, 0x34d2
	jr z, RhythmProc_ConfigBit2
	anddi8 0x34d2, 253
	calr AccPatch_GetCurrentSlotAddr
	andmi8 (xiy + 14), 0xef
	bitda 4, 0x34ea
	jr z, RhythmProc_ConfigBit2
	ormi8 (xiy + 14), 0x10

RhythmProc_ConfigBit2:
	bitda 2, 0x34d2
	jr z, RhythmProc_ConfigBits_Done
	anddi8 0x34d2, 251
	calr AccPatch_GetCurrentSlotAddr
	andmi8 (xiy + 14), 0x9f
	bitda 5, 0x34ea
	jr z, RhythmProc_ConfigBit2_SetBit6
	ormi8 (xiy + 14), 0x20

RhythmProc_ConfigBit2_SetBit6:
	bitda 6, 0x34ea
	jr z, RhythmProc_ConfigBits_Done
	ormi8 (xiy + 14), 0x40

RhythmProc_ConfigBits_Done:
	ret

AccPatch_RebuildChannelSlot:
	ldb_d8 a, 0x379b
	and a, 0x1f
	cps a, 0
	jr z, AccPatch_RebuildChannel_Done
	calr MapBitFlagsToChannelOffset
	stb_d8 0x342e, w
	ld c, w
	push c
	calr AccPatch_GetCurrentSlotAddr
	pop c
	ldw_sri HL, 0x03, 0xf4, 0xe4
	stda16 0x343d, xhl
	calr AccPatch_FreeChainEntries
	lds32 xhl, 0
	ldb_d8 l, 0x34d8
	add xhl, Display_FontPalette_Table_0x1D32
	ld a, (xhl)
	lds32 xhl, 0
	ldb_d8 l, 0x34d7
	and l, 0x7
	inc 1, l
	mul8rr l, a
	and hl, 0x7f
	ld c, l
	ldw_d16 xhl, 0x343d
	calr AccPatch_InitSlotSentinels
	calr AccPatch_ComputeSeqPosition
	stdi8 0x35fe, 0
	calr AccPatch_WriteRhythmInit
	bitda 0, 0x3283
	jr nz, AccPatch_RebuildChannel_Done
	ordi8 0x34cd, 128

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
	ldb w, 0xa

MapBitFlags_NullRet:
	ret

AccPatch_ComputeSeqPosition:
	lds32 xwa, 0
	ldb_d8 a, 0x32b3
	ldb_d8 c, 0x34d9
	mul8rr a, c
	addda8 a, 0x3280
	ld l, a
	ldb_d8 a, 0x327f
	add a, 0x18
	cp a, 0x60
	jr lt, AccPatch_SeqPosition_Store
	inc 1, l
	lds32 xwa, 0
	ldb_d8 a, 0x34d9
	ldb_d8 c, 0x34d7
	inc 1, c
	mul8rr a, c
	cp a, l
	jr nz, AccPatch_SeqPosition_Store
	ldb l, 0x0

AccPatch_SeqPosition_Store:
	lds32 xbc, 0
	ld c, l
	ldw_d16 xhl, 0x343d
	lds wa, 6
	add wa, bc
	lds32 xhl, 0
	ldb_d8 l, 0x342e
	sll l, 1
	add xhl, AccPatch_SeqBaseAddrTable
	ld xhl, (xhl)
	ld (xhl), wa
	lds32 xhl, 0
	ldb_d8 l, 0x342e
	sll l, 1
	add xhl, AccPatch_SeqBaseAddrTable_0x18
	ld xhl, (xhl)
	ldw_d16 xwa, 0x343d
	ld (xhl), wa
	ret

AccPatch_SeqBaseAddrTable:
	.byte 0x87, 0x32, 0x00, 0x00, 0x89, 0x32, 0x00, 0x00
	.byte 0x8b, 0x32, 0x00, 0x00, 0x8d, 0x32, 0x00, 0x00
	.byte 0x8f, 0x32, 0x00, 0x00, 0x91, 0x32, 0x00, 0x00
	.byte 0x97, 0x32, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x9b, 0x32, 0x00, 0x00, 0x9d, 0x32, 0x00, 0x00
	.byte 0x9f, 0x32, 0x00, 0x00, 0xa1, 0x32, 0x00, 0x00

AccPatch_WriteRhythmInit:
	ldb_d8 l, 0x342e
	cps l, 0
	jr z, AccPatch_WriteRhythm_Done
	lds32 xhl, 0
	ldb_d8 l, 0x342e
	add xhl, AccPatch_ChannelToParamTable
	ld a, (xhl)
	push_sd16b 0x2e, 0x34
	calr AccPatch_WriteRhythmParams
	popb_dd16 0x2e, 0x34
	lds32 xhl, 0
	ldb_d8 l, 0x342e
	sll hl, 1
	add xhl, AccPatch_ChannelToParamTable_0x10
	ld xhl, (xhl)
	ld iy, (xhl + 4)
	ld (xhl + 6), iy

AccPatch_WriteRhythm_Done:
	ret

AccPatch_ChannelToParamTable:
	.byte 0x00, 0x00, 0x00, 0x00, 0xd7, 0x00, 0xd4, 0x00
	.byte 0xd5, 0x00, 0xd6, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x94, 0x2c, 0x00, 0x00, 0x94, 0x2d, 0x00, 0x00
	.byte 0x94, 0x2e, 0x00, 0x00, 0x94, 0x2f, 0x00, 0x00

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
	ld xwa, AccPatch_RhythmParamDefaults
	ldb_sri A, 0x03, 0xe0, 0xe4
	push c
	pushw wa
	call RhythmBuf_WriteByte
	inc 2, xsp
	pop c
	inc 1, c
	ld xwa, AccPatch_RhythmParamDefaults
	ldb_sri A, 0x03, 0xe0, 0xe4
	cps c, 7
	jr nz, AccPatch_WriteRhythmParam_Push
	ldb_d8 a, 0x344d

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
	push	sr
	ld	xwa, 0x40040003
	halt
	jrl	nc, 6

AccPatch_FetchVolumeForChannel:
	push xwa
	push xhl
	push xix
	push xiy
	calr AccPatch_GetCurrentSlotAddr
	ld xix, 0x22
	cp a, 0xd7
	jr z, ToneGen_FetchSelectRestore
	ld xix, 0x2a
	cp a, 0xd4
	jr z, ToneGen_FetchSelectRestore
	ld xix, 0x32
	cp a, 0xd5
	jr z, ToneGen_FetchSelectRestore
	ld xix, 0x3a
	cp a, 0xd6
	jr z, ToneGen_FetchSelectRestore
	ldb a, 0x40
	jr AccPatch_FetchVolume_Default

ToneGen_FetchSelectRestore:
	add xix, xiy
	ld a, (xix)

AccPatch_FetchVolume_Default:
	stb_d8 0x344d, a
	pop xiy
	pop xix
	pop xhl
	pop xwa
	ret

RhythmProc_CheckStyleSwitch:
	cpdi8 0x8d36, 184
	jr z, RhythmProc_StyleSwitch_Call
	jr RhythmProc_StyleSwitch_Ret

RhythmProc_StyleSwitch_Call:
	call AccPat_DispatchNoteChange

RhythmProc_StyleSwitch_Ret:
	ret

RhythmProc_CheckRepeatFlag:
	cpdi8 0x8d36, 189
	jr nz, RhythmProc_RepeatFlag_Ret
	bitda 1, 0x34d3
	jr z, RhythmProc_RepeatFlag_Ret
	anddi8 0x34d3, 253
	ld xiy, 0x94800
	add xiy, 0x0
	add xiy, 0x10
	ld a, (xiy)
	and a, 0xfe
	bitda 0, 0x34d3
	jr z, RhythmProc_RepeatFlag_Store
	or a, 0x1

RhythmProc_RepeatFlag_Store:
	ld (xiy), a

RhythmProc_RepeatFlag_Ret:
	ret

RhythmProc_SavePrevState:
	ldb_d8 a, 0x8d36
	stb_d8 0x3525, a
	ldb_d8 a, 0x379b
	and a, 0x7f
	stb_d8 0x3510, a
	ldb_d8 a, 0x3283
	stb_d8 0x3601, a
	cpdi8 0x8d34, 14
	jr z, RhythmProc_SavePrevState_Done
	stdi8 0x379b, 0

RhythmProc_SavePrevState_Done:
	ret

AccPatch_CountAvailableSlots:
	ldw wa, 0xbe
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
	stda16 0x34d4, xwa
	ret

AccPatch_CountSlotsAlt_Body:
	ldda32 xix, 0x39ae
	push xix
	ld xix, 0x69800
	stda32 0x39ae, xix
	ldw wa, 0xbe
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
	stda16 0x34d4, xwa
	pop xix
	stda32 0x39ae, xix
	ret

AccPatch_MiscDataBlock:
	ld	xwa, 100
	.byte 0xd1, 0xd4
	ldw	ix, 0x3340
	.byte 0xbe
	nop
	div	xwa, xhl
	cp	a, 100
	jr	c, 2
	ldb	a, 99
	stb_d8	0x39ab, a
	ret

AccPatch_ProcessPartChanges:
	ldb_d8 a, 0x379b
	and a, 0x1f
	cps a, 0
	jr nz, AccPatch_PartChanges_MapLookup
	ldb_d8 w, 0x3510
	and w, 0x1f
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
	ldb_d8 a, 0x379b
	and a, 0x1f
	lds32 xhl, 0
	ld l, a
	add xhl, AccPatch_PartNumberTable
	ld a, (xhl)
	stb_d8 0x8d3a, a
	ld e, a
	ldb_d8 a, 0x379b
	ldb_d8 w, 0x3510
	and a, 0x1f
	and w, 0x1f
	cp w, a
	jr z, AccPatch_PartChanges_Update
	ld a, e
	ldb e, 0x90
	ldb d, 0x10
	ldb w, 0xff
	call SwbtWr_QueuePostEvent

AccPatch_PartChanges_Update:
	calr AccPatch_SyncAllVoiceParams

AccPatch_PartChanges_CheckFlag:
	ldb_d8 a, 0x3510
	bit 6, a
	jr z, AccPatch_PartChanges_Done
	ldb_d8 w, 0x379b
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
	anddi8 0x34d3, 254
	jr AccPatch_SetRepeatBit_Done

AccPatch_SetRepeatBitOn:
	ordi8 0x34d3, 1

AccPatch_SetRepeatBit_Done:
	ret

AccPatch_PartNumberTable:
	.byte 0x00, 0x10, 0x11, 0x00, 0x12, 0x00, 0x00, 0x00
	.byte 0x13, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x14, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
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
	ld xix, 0xfba4
	ld a, (xiy + 3)
	and a, 0x1
	sll a, 6
	andmi8 (xix + 4), 0xbf
	andmi8 (xix + 4), 0xf7
	or (xix + 4), a
	ld b, a
	ld a, (xiy + 1)
	and a, 0x7f
	andmi8 (xix + 1), 0x80
	or (xix + 1), a
	ld d, a
	ld a, (xiy + 256)
	andmi8 (xix + 256), 0x0
	or (xix + 256), a
	ld e, a
	sll b, 1
	stb_d8 0x34e1, e
	stb_d8 0x34e2, d
	orddm8 0x34e2, b
	push d
	push e
	ld a, d
	ldb d, 0x1
	ldb w, 0x7f
	ldb e, 0x13
	call SwbtWr_QueuePostEvent
	pop e
	push e
	ld a, e
	ldb d, 0x0
	ldb w, 0xff
	ldb e, 0x13
	call SwbtWr_QueuePostEvent
	pop e
	pop d
	ld h, d
	ld l, e
	stdi8 0x90f7, 19
	call PartCtrl_WriteProgramChange
	ld xbc, 0xff56
	lda_dri XIZ, 0x03, 0xe4, 0xec
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
	ld xix, 0xfbbe
	ld a, (xiy + 3)
	and a, 0x1
	sll a, 6
	andmi8 (xix + 4), 0xbf
	andmi8 (xix + 4), 0xf7
	or (xix + 4), a
	ld b, a
	ld a, (xiy + 1)
	and a, 0x7f
	andmi8 (xix + 1), 0x80
	or (xix + 1), a
	ld d, a
	ld a, (xiy + 256)
	or a, 0xf0
	andmi8 (xix + 256), 0x0
	or (xix + 256), a
	ld e, a
	sll b, 1
	stb_d8 0x34df, e
	stb_d8 0x34e0, d
	orddm8 0x34e0, b
	push d
	push e
	ld a, d
	ldb d, 0x1
	ldb w, 0x7f
	ldb e, 0x14
	call SwbtWr_QueuePostEvent
	pop e
	push e
	ld a, e
	ldb d, 0x0
	ldb w, 0xff
	ldb e, 0x14
	call SwbtWr_QueuePostEvent
	pop e
	pop d
	ld h, d
	ld l, e
	stdi8 0x90f7, 20
	call PartCtrl_WriteProgramChange
	ld xbc, 0xff6a
	lda_dri XIZ, 0x03, 0xe4, 0xec
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
	ld xix, 0xfb56
	ld a, (xiy + 3)
	and a, 0x1
	sll a, 6
	andmi8 (xix + 4), 0xbf
	andmi8 (xix + 4), 0xf7
	or (xix + 4), a
	ld b, a
	ld a, (xiy + 1)
	and a, 0x7f
	andmi8 (xix + 1), 0x80
	or (xix + 1), a
	ld d, a
	ld a, (xiy + 256)
	andmi8 (xix + 256), 0x0
	or (xix + 256), a
	ld e, a
	sll b, 1
	stb_d8 0x34e3, e
	stb_d8 0x34e4, d
	orddm8 0x34e4, b
	push d
	push e
	ld a, d
	ldb d, 0x1
	ldb w, 0x7f
	ldb e, 0x10
	call SwbtWr_QueuePostEvent
	pop e
	push e
	ld a, e
	ldb d, 0x0
	ldb w, 0xff
	ldb e, 0x10
	call SwbtWr_QueuePostEvent
	pop e
	pop d
	ld h, d
	ld l, e
	stdi8 0x90f7, 16
	call PartCtrl_WriteProgramChange
	ld xbc, 0xff1a
	lda_dri XIZ, 0x03, 0xe4, 0xec
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
	ld xix, 0xfb70
	ld a, (xiy + 3)
	and a, 0x1
	sll a, 6
	andmi8 (xix + 4), 0xbf
	andmi8 (xix + 4), 0xf7
	or (xix + 4), a
	ld b, a
	ld a, (xiy + 1)
	and a, 0x7f
	andmi8 (xix + 1), 0x80
	or (xix + 1), a
	ld d, a
	ld a, (xiy + 256)
	andmi8 (xix + 256), 0x0
	or (xix + 256), a
	ld e, a
	sll b, 1
	stb_d8 0x34e5, e
	stb_d8 0x34e6, d
	orddm8 0x34e6, b
	push d
	push e
	ld a, d
	ldb d, 0x1
	ldb w, 0x7f
	ldb e, 0x11
	call SwbtWr_QueuePostEvent
	pop e
	push e
	ld a, e
	ldb d, 0x0
	ldb w, 0xff
	ldb e, 0x11
	call SwbtWr_QueuePostEvent
	pop e
	pop d
	ld h, d
	ld l, e
	stdi8 0x90f7, 17
	call PartCtrl_WriteProgramChange
	ld xbc, 0xff2e
	lda_dri XIZ, 0x03, 0xe4, 0xec
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
	ld xix, 0xfb8a
	ld a, (xiy + 3)
	and a, 0x1
	sll a, 6
	andmi8 (xix + 4), 0xbf
	andmi8 (xix + 4), 0xf7
	or (xix + 4), a
	ld b, a
	ld a, (xiy + 1)
	and a, 0x7f
	andmi8 (xix + 1), 0x80
	or (xix + 1), a
	ld d, a
	ld a, (xiy + 256)
	andmi8 (xix + 256), 0x0
	or (xix + 256), a
	ld e, a
	sll b, 1
	stb_d8 0x34e7, e
	stb_d8 0x34e8, d
	orddm8 0x34e8, b
	push d
	push e
	ld a, d
	ldb d, 0x1
	ldb w, 0x7f
	ldb e, 0x12
	push xiy
	call SwbtWr_QueuePostEvent
	pop xiy
	pop e
	push e
	ld a, e
	ldb d, 0x0
	ldb w, 0xff
	ldb e, 0x12
	push xiy
	call SwbtWr_QueuePostEvent
	pop xiy
	pop e
	pop d
	ld h, d
	ld l, e
	stdi8 0x90f7, 18
	push xiy
	call PartCtrl_WriteProgramChange
	pop xiy
	ld xbc, 0xff42
	lda_dri XIZ, 0x03, 0xe4, 0xec
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
	ld xix, 0xfba4
	ld w, (xix + 256)
	and w, 0xff
	ld a, (xix + 1)
	and a, 0x7f
	bitm 6, (xix + 4)
	jr z, AccPatch_SyncRhythm_HasBank
	ldb h, 0x40
	sll h, 1
	or a, h

AccPatch_SyncRhythm_HasBank:
	ldb_d8 h, 0x34e1
	ldb_d8 l, 0x34e2
	cp hl, wa
	jr z, AccPatch_SyncRhythm_Done
	pushw wa
	ld (xiy + 256), w
	ld c, a
	and c, 0x7f
	ld (xiy + 1), c
	and a, 0x80
	srl a, 7
	ld (xiy + 3), a
	popw wa
	stb_d8 0x34e1, w
	stb_d8 0x34e2, a
	ld xix, 0x3219
	calr AccPatch_LoadVoiceParams

AccPatch_SyncRhythm_Done:
	pop xiy
	ret

AccPatch_SyncVoice_Bass:
	push xiy
	add xiy, 0x18
	ld xix, 0xfbbe
	ld w, (xix + 256)
	and w, 0xff
	and w, 0xf
	ld a, (xix + 1)
	and a, 0x7f
	bitm 6, (xix + 4)
	jr z, AccPatch_SyncBass_HasBank
	ldb h, 0x40
	sll h, 1
	or a, h

AccPatch_SyncBass_HasBank:
	ldb_d8 h, 0x34df
	ldb_d8 l, 0x34e0
	cp hl, wa
	jr z, AccPatch_SyncBass_Done
	pushw wa
	ld (xiy + 256), w
	ld c, a
	and c, 0x7f
	ld (xiy + 1), c
	and a, 0x80
	srl a, 7
	ld (xiy + 3), a
	popw wa
	stb_d8 0x34df, w
	stb_d8 0x34e0, a
	ld xix, 0x3214
	calr AccPatch_LoadVoiceParams

AccPatch_SyncBass_Done:
	pop xiy
	ret

AccPatch_SyncVoice_Acc1:
	push xiy
	add xiy, 0x28
	ld xix, 0xfb56
	ld w, (xix + 256)
	and w, 0xff
	ld a, (xix + 1)
	and a, 0x7f
	bitm 6, (xix + 4)
	jr z, AccPatch_SyncAcc1_HasBank
	ldb h, 0x40
	sll h, 1
	or a, h

AccPatch_SyncAcc1_HasBank:
	ldb_d8 h, 0x34e3
	ldb_d8 l, 0x34e4
	cp hl, wa
	jr z, AccPatch_SyncAcc1_Done
	pushw wa
	ld (xiy + 256), w
	ld c, a
	and c, 0x7f
	ld (xiy + 1), c
	and a, 0x80
	srl a, 7
	ld (xiy + 3), a
	popw wa
	stb_d8 0x34e3, w
	stb_d8 0x34e4, a
	ld xix, 0x321e
	calr AccPatch_LoadVoiceParams

AccPatch_SyncAcc1_Done:
	pop xiy
	ret

AccPatch_SyncVoice_Acc2:
	push xiy
	add xiy, 0x30
	ld xix, 0xfb70
	ld w, (xix + 256)
	and w, 0xff
	ld a, (xix + 1)
	and a, 0x7f
	bitm 6, (xix + 4)
	jr z, AccPatch_SyncAcc2_HasBank
	ldb h, 0x40
	sll h, 1
	or a, h

AccPatch_SyncAcc2_HasBank:
	ldb_d8 h, 0x34e5
	ldb_d8 l, 0x34e6
	cp hl, wa
	jr z, AccPatch_SyncAcc2_Done
	pushw wa
	ld (xiy + 256), w
	ld c, a
	and c, 0x7f
	ld (xiy + 1), c
	and a, 0x80
	srl a, 7
	ld (xiy + 3), a
	popw wa
	stb_d8 0x34e5, w
	stb_d8 0x34e6, a
	ld xix, 0x3223
	calr AccPatch_LoadVoiceParams

AccPatch_SyncAcc2_Done:
	pop xiy
	ret

AccPatch_SyncVoice_Acc3:
	push xiy
	add xiy, 0x38
	ld xix, 0xfb8a
	ld w, (xix + 256)
	and w, 0xff
	ld a, (xix + 1)
	and a, 0x7f
	bitm 6, (xix + 4)
	jr z, AccPatch_SyncAcc3_HasBank
	ldb h, 0x40
	sll h, 1
	or a, h

AccPatch_SyncAcc3_HasBank:
	ldb_d8 h, 0x34e7
	ldb_d8 l, 0x34e8
	cp hl, wa
	jr z, AccPatch_SyncAcc3_Done
	pushw wa
	ld (xiy + 256), w
	ld c, a
	and c, 0x7f
	ld (xiy + 1), c
	and a, 0x80
	srl a, 7
	ld (xiy + 3), a
	popw wa
	stb_d8 0x34e7, w
	stb_d8 0x34e8, a
	ld xix, 0x3228
	calr AccPatch_LoadVoiceParams

AccPatch_SyncAcc3_Done:
	pop xiy
	ret

AccPatch_LoadVoiceParams:
	ld e, (xiy + 256)
	ld d, (xiy + 1)
	ld a, (xiy + 2)
	stb_d8 0x342f, a
	ld a, (xiy + 3)
	stb_d8 0x3430, a
	ld a, (xiy + 4)
	stb_d8 0x3431, a
	calr AccPatch_CallParamLookup
	ret

AccPatch_CallParamLookup:
	push xix
	pushw de
	push_sd16b 0x2f, 0x34
	push_sd16b 0x30, 0x34
	push_sd16b 0x31, 0x34
	call RhythmPart_CopyData_Tramp
	popb_dd16 0x31, 0x34
	popb_dd16 0x30, 0x34
	popb_dd16 0x2f, 0x34
	popw de
	pop xix
	bit 7, e
	jr z, AccPatch_StoreVoiceParams
	or d, 0x10
	and e, 0x7f

AccPatch_StoreVoiceParams:
	ld (xix), e
	ld (xix + 1), d
	ldb_d8 a, 0x342f
	ld (xix + 2), a
	ldb_d8 a, 0x3430
	ld (xix + 3), a
	ldb_d8 a, 0x3431
	ld (xix + 4), a
	call AccVoice_LoadAllChannelParams
	ret

AccPatch_ComplexDataBlock:
	ldb_d8	a, 0x8d34
	cp	a, 14
	jr	nz, 3
	calr	1
	ret
	ldb_d8	a, 0xc07d
	cps	a, 0
	jr	nz, 51
	.byte 0xc1
	jrl	nz, 16320
	decm8	7, (xwa)
	pushw	ix
	.byte 0xc1
	jrl	nc, 16320
	nop
	jr	z, 37
	ldb_d8	a, 0x8d36
	cp	a, 180
	jr	nz, 28
	ld	xiy, 0x094800
	add	xiy, 0
	ld	a, (xiy+16)
	bit	0, a
	jr	nz, 9
	call	DrumVoice_Handler7_0x323
	stdi8	0x3540, 7
	ldb_d8	a, 0xc07d
	cps	a, 0
	jr	nz, 28
	.byte 0xc1
	jrl	nc, 16320
	nop
	jr	z, 21
	ldb_d8	a, 0x8d36
	cp	a, 184
	jr	nz, 12
	call	TimeSig_DisplayStrings_0x233
	call	TimeSig_DisplayStrings_0x2EE
	call	DrumVoice_Handler7_0x323
	ret
	calr	48
	ret
	ld	xiy, 0x094800
	add	xiy, 0
	add	xiy, 0
	.byte 0x8d
	nop
	ldb	a, 201
	muls8rr	w, l
	jr	nz, 17
	ld	a, (xiy+1)
	cps	a, 0
	jr	nz, 10
	ld	a, (xiy+2)
	cp	a, 75
	jr	nz, 2
	jr	4
	call	AccDemo_Init_Wrap
	ret
	add	xiy, 0
	add	xiy, 0
	.byte 0x8d
	nop
	ldb	a, 201
	muls8rr	w, l
	jr	nz, 22
	ld	a, (xiy+1)
	cps	a, 0
	jr	nz, 15
	ld	a, (xiy+2)
	cp	a, 75
	jr	nz, 7
	call	AccPatch_ComplexDataBlock_0x14D
	jrl	130
	.byte 0x85
	push	xsp
	popw	ix
	jr	nz, 22
	.byte 0x8d, 0x01
	push	xsp
	popw	hl
	jr	nz, 16
	.byte 0x8d
	push	sr
	push	xsp
	ld	xiy, 0x151d0a6e
	swi	4
	.byte 0xf5
	call	AccPatch_ComplexDataBlock_0x14E
	jr	103
	.byte 0x8d
	nop
	ldb	a, 201
	mul8rr	l, l
	jr	nz, 25
	ld	a, (xiy+1)
	cps	a, 0
	jr	nz, 18
	ld	a, (xiy+2)
	cp	a, 75
	jr	nz, 10
	call	AccPatch_ComplexDataBlock_0x14D
	call	AccPatch_ComplexDataBlock_0x14E
	jr	70
	.byte 0x8d
	nop
	ldb	a, 201
	mul8rr	h, l
	jr	nz, 17
	ld	a, (xiy+1)
	cps	a, 0
	jr	nz, 10
	ld	a, (xiy+2)
	cp	a, 75
	jr	nz, 2
	jr	39
	.byte 0x8d
	nop
	ldb	a, 201
	muls8rr	e, l
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
	call	AccDemo_Init_Wrap
	jr	6
	call	AccPatch_VoiceAssignDataBlock
	jr	0
	ret
	ret
	ld	xiy, 0x094800
	add	xiy, 0
	add	xiy, 0
	ldb	a, 72
	.byte 0xbd
	nop
	ld	xbc, 0x01bd0021
	ld	xbc, 0x02bd4b21
	ld	xbc, 0xf1501e0e
	calr	62261
	calr	1
	ret
	.byte 0x9d
	nop
	ldb	c, 30
	pop_f
	nop
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
	calr	61800
	.byte 0xbc
	pop	sr
	push	sr
	swi	7
	swi	7
	pushw	hl
	ld	l, (xiy+12)
	xor	h, h
	lds32	xwa, 0
	ld	xbc, Display_FontPalette_Table_0x1D32
	.byte 0xc3
	reti
	.byte 0xe4, 0xec
	ldb	a, 233
	.byte 0xa8
	ld	b, (xiy+13)
	inc	1, b
	mul8rr	a, b
	popw	hl
	calr	61764
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
	cp wa, 0xffff
	jr z, AccPatch_FreeChain_Alt_Done

AccPatch_FreeChainLoop_Alt:
	ld hl, wa
	ldw (xix + 3), 0xffff
	calr AccPatch_ResolveSlotAddr
	ldw (xix + 1), 0xffff
	andmi8 (xix), 0x7f
	incdi16 1, 0x34d4
	ld wa, (xix + 3)
	cp wa, 0xffff
	jr z, AccPatch_FreeChain_Alt_Done
	jr AccPatch_FreeChainLoop_Alt

AccPatch_FreeChain_Alt_Done:
	pop xiy
	ret

AccPatch_ResolveSlotAddr:
	cp hl, 0xffff
	jr z, AccPatch_ResolveSlotAddr_Ret
	pushw hl
	pushw hl
	lds32 xhl, 0
	popw hl
	sll xhl, 8
	ldda32 xix, 0x39ae
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
	ld xbc, Display_FontPalette_Table_0x1D32
	ldb_sri A, 0x07, 0xe4, 0xec
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
	bitda 0, 0x3616
	jr nz, AccPatch_ScanSeq_StorePosAndRet
	jr AccPatch_ScanSeq_Loop

AccPatch_ScanSeq_StorePosAndRet:
	ldw_d16 xwa, 0x3612
	stda16 0x3606, xwa
	ldw_d16 xwa, 0x3614
	stda16 0x3608, xwa
	ret

AccPatch_SeqReadByte_Alt:
	push xix
	ldw_d16 xhl, 0x3612
	calr AccPatch_ResolveSlotAddr
	ldw_d16 xhl, 0x3614
	ldb_sri A, 0x07, 0xf0, 0xec
	pop xix
	ret

AccPatch_SeqAdvance_Alt:
	ldw_d16 xwa, 0x3614
	cp wa, 0xfe
	jr nz, AccPatch_SeqAdvance_Inc
	ldw_d16 xhl, 0x3612
	calr AccPatch_ResolveSlotAddr
	ld wa, (xix + 3)
	stda16 0x3612, xwa
	cp wa, 0xffff
	jr nz, AccPatch_SeqAdvance_CheckLimit
	ordi8 0x3616, 1

AccPatch_SeqAdvance_CheckLimit:
	cp wa, 0x154
	jr lt, AccPatch_SeqAdvance_ResetBase
	ordi8 0x3616, 1

AccPatch_SeqAdvance_ResetBase:
	lds wa, 6
	jr AccPatch_SeqAdvance_Store

AccPatch_SeqAdvance_Inc:
	inc 1, wa

AccPatch_SeqAdvance_Store:
	stda16 0x3614, xwa
	ret

AccPatch_InitSlotPointer_Alt:
	xor xhl, xhl
	ldb_d8 l, 0x39ac
	cp l, 0x1e
	jr c, AccPatch_InitSlotAlt_Valid
	xor l, l

AccPatch_InitSlotAlt_Valid:
	mul hl, 0x60
	add xhl, 0x60
	ldda32 xiy, 0x39ae
	add xiy, xhl
	ldb_d8 a, 0x379b
	calr MapBitFlagsToChannelOffset
	ldw_sri HL, 0x03, 0xf4, 0xe1
	stda16 0x3612, xhl
	stdi16 0x3614, 6
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
	ldw_d16 xhl, 0x3612
	calr AccPatch_GetEntryAddr
	ldw_d16 xhl, 0x3614
	ldb_sri A, 0x07, 0xf0, 0xec
	pop xix
	ret

AccPatch_SeqDispatch_Padding:
	nop
	nop

AccPatch_AdvanceSeqIndex:
	ldw_d16 xwa, 0x3614
	cp wa, 0xfe
	jr nz, AccPatch_AdvSeq_Inc
	ldw_d16 xhl, 0x3612
	calr AccPatch_GetEntryAddr
	ld wa, (xix + 3)
	stda16 0x3612, xwa
	cp wa, 0xffff
	jr nz, AccPatch_AdvSeq_CheckLimit
	ordi8 0x3616, 1

AccPatch_AdvSeq_CheckLimit:
	cp wa, 0x154
	jr lt, AccPatch_AdvSeq_ResetBase
	ordi8 0x3616, 1

AccPatch_AdvSeq_ResetBase:
	lds wa, 6
	jr AccPatch_AdvSeq_Store

AccPatch_AdvSeq_Inc:
	inc 1, wa

AccPatch_AdvSeq_Store:
	stda16 0x3614, xwa
	ret

AccPatch_AdvSeq_Padding:
	nop
	nop

AccPatch_SeqDispatch_Main:
	ldb_d8 a, 0x379b
	cpda8 a, 0x35fe
	jr z, AccPatch_SeqDispatch_CheckEmpty
	calr AccPatch_ScanToSequenceStart
	calr AccPatch_InitAndLoadSequence

AccPatch_SeqDispatch_CheckEmpty:
	ldb_d8 a, 0x379b
	and a, 0x1f
	cps a, 0
	jr nz, AccPatch_SeqDispatch_CheckPlaying
	jrl AccPatch_SyncStateAndReturn

AccPatch_SeqDispatch_CheckPlaying:
	bitda 0, 0x3283
	jr nz, AccPatch_SeqDispatch_CheckStarted
	call TempoRingBuf_ReInitAndRet
	jrl AccPatch_SyncStateAndReturn

AccPatch_SeqDispatch_CheckStarted:
	bitda 0, 0x3601
	jr nz, AccPatch_SeqDispatch_ProcessFlags
	calr AccPatch_ResetSeqCounters
	calr AccPatch_InitCurrentSlotPointer
	ldw_d16 xwa, 0x3612
	stda16 0x3602, xwa
	ldw_d16 xwa, 0x3614
	stda16 0x3604, xwa

AccPatch_SeqDispatch_ProcessFlags:
	calr AccPatch_ReadModeFlags
	ldb_d8 a, 0x34cf
	and a, 0xc
	cps a, 0
	jr nz, AccPatch_SeqDispatch_ModeChange
	ldb_d8 a, 0x35fc
	and a, 0xc
	cps a, 0
	jr z, AccPatch_SeqDispatch_RunNotes

AccPatch_SeqDispatch_ModeChange:
	calr AccPatch_UpdateSequenceState
	jr AccPatch_SyncStateAndReturn

AccPatch_SeqDispatch_RunNotes:
	call AccPatch_CheckEmpty
	cps wa, 0
	jr z, AccPatch_SyncStateAndReturn
	stdi16 0x360a, 0
	stdi16 0x360e, 0
	stdi8 0x35ff, 0
	calr AccPatch_EventDispatch_Nop
	cpdi16 0x360a, 0
	jr z, AccPatch_SeqDispatch_CheckQueued
	ldw_d16 xwa, 0x3602
	stda16 0x36fe, xwa
	ldw_d16 xwa, 0x3604
	stda16 0x3700, xwa
	calr AccPatch_InitSlotAndCopyData
	calr AccPatch_AdvancePlayPos
	calr AccPatch_AdvanceAllSteps
	stdi16 0x360a, 0

AccPatch_SeqDispatch_CheckQueued:
	cpdi16 0x360e, 0
	jr z, AccPatch_SyncStateAndReturn
	calr AccPatch_DispatchQueuedNotes

AccPatch_SyncStateAndReturn:
	ldb_d8 a, 0x379b
	stb_d8 0x35fe, a
	ret

AccPatch_SeqDispatch_MiscData:
	nop
	nop
	.byte 0xc1, 0xcf
	ldw	ix, 2110
	ret
	.byte 0xc1, 0xcf
	ldw	ix, 0xf73c
	call	AccPatch_InitAndLoadSequence
	ret

AccPatch_ReadModeFlags:
	ldb_d8 a, 0x34cf
	and a, 0xf3
	stb_d8 0x34cf, a
	cpdi8 0x8d38, 181
	jr z, AccPatch_ReadModeFlags_Active
	jr AccPatch_SetFlagExit

AccPatch_ReadModeFlags_Active:
	ldl_da xwa, 0x02749a
	orda32_24 xwa, 0x02749e
	stda32 4560, xwa
	ldl_da xwa, 0x02749e
	stda32 0x39e0, xwa
	ldda32 xwa, 4560
	and xwa, 0x200
	cp xwa, 0x0
	jr z, AccPatch_ReadModeFlags_Check400
	ldda32 xwa, 0x39e0
	and xwa, 0x200
	cp xwa, 0x0
	jr nz, AccPatch_ReadModeFlags_Check400
	ldb_d8 a, 0x34cf
	or a, 0x4
	stb_d8 0x34cf, a

AccPatch_ReadModeFlags_Check400:
	ldda32 xwa, 4560
	and xwa, 0x400
	cp xwa, 0x0
	jr z, AccPatch_SetFlagExit
	ldda32 xwa, 0x39e0
	and xwa, 0x400
	cp xwa, 0x0
	jr nz, AccPatch_SetFlagExit
	ldb_d8 a, 0x34cf
	or a, 0x8
	stb_d8 0x34cf, a

AccPatch_SetFlagExit:
	ret

AccPatch_ScanSeq_PaddingByte:
	ret

AccPatch_ScanToSequenceStart:
	calr AccPatch_InitCurrentSlotPointer

AccPatch_ScanSeq_ReadLoop:
	calr AccPatch_SeqReadByte
	cp a, 0x83
	jr z, AccPatch_ScanSeq_StorePosition
	calr AccPatch_AdvanceSeqIndex
	bitda 0, 0x3616
	jr nz, AccPatch_ScanSeq_StorePosition
	jr AccPatch_ScanSeq_ReadLoop

AccPatch_ScanSeq_StorePosition:
	ldw_d16 xwa, 0x3612
	stda16 0x3606, xwa
	ldw_d16 xwa, 0x3614
	stda16 0x3608, xwa
	ret

AccPatch_ScanSeq_PaddingWord:
	nop
	nop

AccPatch_InitAndLoadSequence:
	ld xhl, 0x361a
	ldw bc, 0x8

AccPatch_InitSeq_ClearLoop:
	ldw (xhl), 0x0
	add hl, 0x6
	djnz xbc, AccPatch_InitSeq_ClearLoop
	ei 6
	bitda 0, 0x364a
	jr nz, AccPatch_InitSeq_LoadTempo
	call TempoRingBuf_ReInitAndRet

AccPatch_InitSeq_LoadTempo:
	ldb_d8 a, 1077
	ldb_d8 c, 1046
	ei 0
	anddi8 0x364a, 254
	ldb_d8 b, 0x34d9
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
	nop
	nop

AccPatch_ResetSeqCounters:
	ld xhl, 0x361a
	ldw bc, 0x8

AccPatch_ResetSeqCounters_Loop:
	ldw (xhl), 0x0
	add hl, 0x6
	djnz xbc, AccPatch_ResetSeqCounters_Loop
	ei 6
	ldb_d8 a, 1077
	ldb_d8 c, 1046
	ei 0
	anddi8 0x364a, 254
	ldb_d8 b, 0x34d9
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
	nop
	nop

AccPatch_ScanToSequenceEnd:
	calr AccPatch_SeqReadByte
	cp a, 0x81
	jr z, AccPatch_ScanSeqEnd_HandleMarker
	calr AccPatch_AdvanceSeqIndex
	bitda 0, 0x3616
	jr nz, AccPatch_ScanDone
	jr AccPatch_ScanToSequenceEnd

AccPatch_ScanSeqEnd_HandleMarker:
	calr AccPatch_AdvanceSeqIndex
	bitda 0, 0x3616
	jr nz, AccPatch_ScanDone
	calr AccPatch_SeqReadByte
	cp a, 0x83
	jr nz, AccPatch_ScanDone
	calr AccPatch_MarkAllSlotsActive

AccPatch_ScanDone:
	ret

__pad_F600A1:
	nop
	nop

AccPatch_MarkAllSlotsActive:
	ld xhl, 0x361a

AccPatch_MarkSlots_Loop:
	bitm 7, (xhl)
	jr z, AccPatch_MarkSlots_Next
	ormi8 (xhl + 1), 0x80

AccPatch_MarkSlots_Next:
	add xhl, 0x6
	cp xhl, 0x364a
	jr c, AccPatch_MarkSlots_Loop
	calr AccPatch_InitCurrentSlotPointer
	ret

AccPatch_UpdateSequenceState:
	ldw_d16 xwa, 0x3612
	stda16 0x35da, xwa
	ldw_d16 xwa, 0x3614
	stda16 0x35dc, xwa
	ei 6
	ldb_d8 a, 1077
	stb_d8 0x35f9, a
	ldw_d16 xwa, 1045
	stda16 0x3706, xwa
	ei 0
	ldb_d8 a, 0x34cf
	ldb_d8 w, 0x35fc
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
	ordi8 0x35fd, 1
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
	bitda 4, 0x379b
	jr z, AccPatch_LoadNextSequencePointers
	ldb_d8 a, 0x3558
	stb_d8 0x35fb, a
	bitda 3, 0x34cf
	jr z, AccPatch_UpdateSeqState_ClearBit7
	bitda 7, 0x3558
	jr nz, AccPatch_UpdateSeqState_ScanNoteOff
	calr AccPatch_ClearAndScanForNote
	jr AccPatch_UpdateSeqState_AfterScan

AccPatch_UpdateSeqState_ScanNoteOff:
	calr AccPatch_ScanForNoteOff

AccPatch_UpdateSeqState_AfterScan:
	jr AccPatch_UpdateSeqState_CompareBits

AccPatch_UpdateSeqState_ClearBit7:
	anddi8 0x3558, 127

AccPatch_UpdateSeqState_CompareBits:
	ldb_d8 a, 0x3558
	ldb_d8 c, 0x35fb
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
	ldw_d16 xwa, 0x35da
	stda16 0x3612, xwa
	ldw_d16 xwa, 0x35dc
	stda16 0x3614, xwa

AccPatch_UpdateSeqState_CheckBit3:
	bitda 3, 0x34cf
	jr nz, AccPatch_UpdateSeqState_StoreFlags
	bitda 3, 0x35fc
	jr z, AccPatch_UpdateSeqState_StoreFlags
	calr AccPatch_InitAndLoadSequence

AccPatch_UpdateSeqState_StoreFlags:
	ldb_d8 a, 0x34cf
	stb_d8 0x35fc, a
	anddi8 0x35fb, 253
	bitda 0, 0x35fb
	jr z, AccPatch_UpdateSeqState_Return
	ordi8 0x35fb, 2

AccPatch_UpdateSeqState_Return:
	ret

__pad_F601A3:
	nop
	nop

AccPatch_ClearAndScanForNote:
	anddi8 0x3558, 127

AccPatch_ScanForActiveNote:
	call AccPatch_CheckEmpty
	cps wa, 0
	jr z, AccPatch_ScanNote_Done
	lds bc, 1
	calr TempoRingBuf_SkipBytes
	ld w, a
	and w, 0xf0
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
	stb_d8 0x3558, l
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
	and w, 0xf0
	cp w, 0x90
	jr nz, AccPatch_ErrorExit
	lds bc, 2
	calr TempoRingBuf_SkipBytes
	ld l, a
	ldb_d8 h, 0x3558
	and h, 0x7f
	cp h, l
	jr nz, AccPatch_ErrorExit
	lds bc, 1
	calr TempoRingBuf_SkipBytes
	cps a, 0
	jr nz, AccPatch_ErrorExit
	anddi8 0x3558, 127
	call TempoRingBuf_ReInitAndRet

AccPatch_ErrorExit:
	jr AccPatch_ScanForNoteOff

AccPatch_ScanForNoteOff_Done:
	ret

AccPatch_SeekToPosition:
	calr AccPatch_SeekForwardSteps
	ldb_d8 a, 0x3706
	stb_d8 0x36f8, a
	calr AccPatch_ParseSequenceHeader
	ldw_d16 xwa, 0x3612
	stda16 0x35de, xwa
	ldw_d16 xwa, 0x3614
	stda16 0x35e0, xwa
	ret

AccPatch_SeekForwardSteps:
	ldb_d8 a, 0x35f9
	ldb_d8 c, 0x3707
	ldb_d8 b, 0x34d9
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
	nop
	nop

AccPatch_ParseSequenceHeader:
	ldw_d16 xwa, 0x3612
	stda16 0x36fa, xwa
	ldw_d16 xwa, 0x3614
	stda16 0x36fc, xwa
	calr AccPatch_SeqReadByte
	cp a, 0x81
	jr z, AccPatch_ParseHdr_RestorePos
	cp a, 0x83
	jr nz, AccPatch_ParseHdr_AdvanceAndCompare
	ordi8 0x3616, 2
	jr AccPatch_ParseHdr_Return

AccPatch_ParseHdr_AdvanceAndCompare:
	calr AccPatch_AdvanceSeqIndex
	calr AccPatch_SeqReadByte
	cpda8 a, 0x36f8
	jr ugt, AccPatch_ParseHdr_RestorePos

AccPatch_ParseHdr_AdvanceAndRead:
	calr AccPatch_AdvanceSeqIndex
	calr AccPatch_SeqReadByte
	bitda 0, 0x3616
	jr z, AccPatch_ParseHdr_CheckBit7
	jr AccPatch_ParseHdr_Return

AccPatch_ParseHdr_CheckBit7:
	bit 7, a
	jr z, AccPatch_ParseHdr_AdvanceAndRead
	jr AccPatch_ParseSequenceHeader

AccPatch_ParseHdr_RestorePos:
	ldw_d16 xwa, 0x36fa
	stda16 0x3612, xwa
	ldw_d16 xwa, 0x36fc
	stda16 0x3614, xwa

AccPatch_ParseHdr_Return:
	ret

__pad_F602CB:
	nop
	nop

AccPatch_ResumeSequencePlayback:
	anddi8 0x35fd, 254
	calr AccPatch_PrepareSequencePlayback
	ldw_d16 xwa, 0x35de
	stda16 0x3612, xwa
	ldw_d16 xwa, 0x35e0
	stda16 0x3614, xwa
	stdi16 0x360a, 0

AccPatch_ResumeSeq_ComparePos:
	ldw_d16 xwa, 0x3612
	cpda16 xwa, 0x35e2
	jr nz, AccPatch_ResumeSeq_ReadByte
	ldw_d16 xwa, 0x3614
	cpda16 xwa, 0x35e4
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
	and a, 0xf0
	cp a, 0xd0
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
	adddm16 0x360a, xbc

AccPatch_ResumeSeq_AdvLoop:
	calr AccPatch_AdvanceSeqIndex
	djnz xbc, AccPatch_ResumeSeq_AdvLoop
	jr AccPatch_ResumeSeq_ComparePos

AccPatch_ResumeSeq_HandleMarker:
	calr AccPatch_CheckSequenceChanged
	calr AccPatch_AdvanceSeqIndex
	ldw_d16 xwa, 0x3612
	stda16 0x35de, xwa
	ldw_d16 xwa, 0x3614
	stda16 0x35e0, xwa
	calr AccPatch_SeqReadByte
	cp a, 0x83
	jr z, AccPatch_ResumeSeq_InitSlot
	cpdi16 0x360a, 0
	jr z, AccPatch_ResumeSeq_LoopBack
	calr AccPatch_PrepareSequencePlayback
	stdi16 0x360a, 0

AccPatch_ResumeSeq_LoopBack:
	jrl AccPatch_ResumeSeq_ComparePos

AccPatch_ResumeSeq_InitSlot:
	calr AccPatch_InitCurrentSlotPointer
	ldw_d16 xwa, 0x3612
	stda16 0x35de, xwa
	ldw_d16 xwa, 0x3614
	stda16 0x35e0, xwa

AccPatch_ResumeSeq_Return:
	ret

__pad_F60386:
	nop
	nop

AccPatch_PrepareSequencePlayback:
	calr AccPatch_SeekForwardSteps
	ldb_d8 a, 0x3706
	stb_d8 0x36f8, a
	calr AccPatch_ParseSequenceHeader
	ldw_d16 xwa, 0x3612
	stda16 0x35e2, xwa
	ldw_d16 xwa, 0x3614
	stda16 0x35e4, xwa
	ret

AccPatch_CheckSequenceChanged:
	cpdi16 0x360a, 0
	jr z, AccPatch_CheckChanged_Return
	ldw_d16 xwa, 0x35de
	stda16 0x365a, xwa
	ldw_d16 xwa, 0x35e0
	stda16 0x3660, xwa
	ldw_d16 xwa, 0x3612
	stda16 0x3658, xwa
	ldw_d16 xwa, 0x3614
	stda16 0x365e, xwa
	ldw_d16 xwa, 0x365a
	cpda16 xwa, 0x3658
	jr nz, AccPatch_CheckChanged_DoCopy
	ldw_d16 xwa, 0x3660
	cpda16 xwa, 0x365e
	jr nz, AccPatch_CheckChanged_DoCopy
	jr AccPatch_CheckChanged_Return

AccPatch_CheckChanged_DoCopy:
	calr AccPatch_CopySequenceEntry
	calr AccPatch_UpdateEntryFromTable
	ldw_d16 xwa, 0x35de
	stda16 0x3612, xwa
	ldw_d16 xwa, 0x35e0
	stda16 0x3614, xwa

AccPatch_CheckChanged_Return:
	ret

__pad_F603FC:
	nop
	nop

AccPatch_CopySequenceEntry:
	ldw_d16 xde, 0x3606
	ldw_d16 xwa, 0x3608
	stda16 0x3662, xwa
	ldw_d16 xhl, 0x3658
	calr AccPatch_GetEntryAddr
	stda32 0x3650, xix
	ldw_d16 xhl, 0x365a
	calr AccPatch_GetEntryAddr
	stda32 0x364c, xix
	calr AccPatch_SetupBlockCopyDispatch
	dec 1, ix
	stda16 0x3704, xix
	ldw_d16 xwa, 0x365a
	cpda16 xwa, 0x3606
	jr z, AccPatch_CopyEntry_Store
	incdi16 1, 0x34d4
	ldw_d16 xhl, 0x365a
	calr AccPatch_GetEntryAddr
	ld wa, (xix + 3)
	ldw (xix + 3), 0xffff
	ld hl, wa
	calr AccPatch_GetEntryAddr
	andmi8 (xix), 0x7f
	ldw (xix + 1), 0xffff

AccPatch_CopyEntry_Store:
	ldw_d16 xwa, 0x365a
	stda16 0x3606, xwa
	ldw_d16 xwa, 0x3704
	stda16 0x3608, xwa
	ret

__pad_F60464:
	nop
	nop

AccPatch_UpdateEntryFromTable:
	calr AccPatch_LoadTablePointers
	ld de, (xix)
	ld hl, (xiy)
	pushw de
	pushw hl
	calr AccPatch_GetEntryAddr
	popw hl
	popw de
	cpda16 xhl, 0x35de
	jr z, AccPatch_UpdateEntry_CheckDE
	cpw (xix + 1), 0xffff
	jr z, AccPatch_NullRet
	calr AccPatch_AdjustTableEntryPos
	jr AccPatch_NullRet

AccPatch_UpdateEntry_CheckDE:
	cpda16 xde, 0x35e0
	jr nc, AccPatch_UpdateEntry_AdjustOffset
	jr AccPatch_NullRet

AccPatch_UpdateEntry_AdjustOffset:
	subda16 xde, 0x360a
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
	ldw hl, 0xff
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
	nop
	nop

AccPatch_LoadTablePointers:
	push xbc
	lds32 xbc, 0
	ldb_d8 c, 0x379b
	sll bc, 2
	push xbc
	add xbc, AccPatch_AdvPlayPos_DataBlock_0x4B
	ld xix, xbc
	ld xix, (xix)
	pop xbc
	ld xiy, AccPatch_AdvPlayPos_DataBlock_0x7
	add xiy, xbc
	ld xiy, (xiy)
	pop xbc
	ret

AccPatch_AdjustTableEntryPos:
	calr AccPatch_LoadTablePointers
	ld de, (xix)
	ld wa, (xiy)
	sub de, 0x6
	cpda16 xde, 0x360a
	jr c, AccPatch_AdjustEntry_Overflow
	subda16 xde, 0x360a
	add de, 0x6
	ld (xix), de
	jr AccPatch_AdjustEntry_Return

AccPatch_AdjustEntry_Overflow:
	ldw_d16 xhl, 0x360a
	sub hl, de
	ldw de, 0xff
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
	ldw_d16 xwa, 0x35de
	stda16 0x3612, xwa
	ldw_d16 xwa, 0x35e0
	stda16 0x3614, xwa

AccPatch_ProcessSequenceEvents:
	ldw_d16 xwa, 0x3612
	cpda16 xwa, 0x35e2
	jr nz, AccPatch_ProcessSeqEvt_SavePos
	ldw_d16 xwa, 0x3614
	cpda16 xwa, 0x35e4
	jr nz, AccPatch_ProcessSeqEvt_SavePos
	jrl AccPatch_ProcessSeqEvt_StorePos

AccPatch_ProcessSeqEvt_SavePos:
	ldw_d16 xwa, 0x3612
	stda16 0x36fa, xwa
	ldw_d16 xwa, 0x3614
	stda16 0x36fc, xwa
	calr AccPatch_SeqReadByte
	stb_d8 0x36f9, a
	cp a, 0x90
	jr z, AccPatch_SkipNoteOff
	cp a, 0x91
	jr z, AccPatch_SkipNoteOff
	cp a, 0x92
	jr z, AccPatch_SkipNoteOff
	cp a, 0x81
	jr z, AccPatch_ProcessSeqEvt_HandleEnd
	and a, 0xf0
	cp a, 0xd0
	jr z, AccPatch_ProcessSeqEvt_SkipD
	jrl AccPatch_ProcessSeqEvt_RetNop

AccPatch_SkipNoteOff:
	calr AccPatch_AdvanceSeqIndex
	calr AccPatch_AdvanceSeqIndex
	calr AccPatch_SeqReadByte
	stb_d8 0x35fa, a
	lds bc, 6
	cpdi8 0x36f9, 145
	jr z, AccPatch_ProcessSeqEvt_AdvLoop
	lds bc, 4

AccPatch_ProcessSeqEvt_AdvLoop:
	calr AccPatch_AdvanceSeqIndex
	djnz xbc, AccPatch_ProcessSeqEvt_AdvLoop
	ldb_d8 a, 0x35fa
	ldb_d8 b, 0x3558
	and b, 0x7f
	cp a, b
	jr z, AccPatch_ProcessSeqEvt_SetSize
	cp a, 0x5d
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
	stdi16 0x360a, 8
	cpdi8 0x36f9, 145
	jr z, AccPatch_ProcessSeqEvt_StoreAndPrep
	stdi16 0x360a, 6

AccPatch_ProcessSeqEvt_StoreAndPrep:
	ldw_d16 xwa, 0x36fa
	stda16 0x35de, xwa
	ldw_d16 xwa, 0x36fc
	stda16 0x35e0, xwa
	calr AccPatch_CheckSequenceChanged
	stdi16 0x360a, 0
	calr AccPatch_PrepareSequencePlayback
	jrl AccPatch_ProcessSequenceEvents

AccPatch_ProcessSeqEvt_InitSlot:
	calr AccPatch_InitCurrentSlotPointer

AccPatch_ProcessSeqEvt_StorePos:
	ldw_d16 xwa, 0x3612
	stda16 0x35de, xwa
	ldw_d16 xwa, 0x3614
	stda16 0x35e0, xwa
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
	ldb w, 0xf0
	and w, a
	cp w, 0x90
	jr z, AccPatch_EventDispatch_NoteOn
	cp a, 0xd1
	jr nz, AccPatch_EventDispatch_CheckD2
	jr AccPatch_ProcessMarkerCommand

AccPatch_EventDispatch_CheckD2:
	cp a, 0xd2
	jr nz, AccPatch_EventDispatch_CheckD4
	jr AccPatch_ProcessMarkerCommand

AccPatch_EventDispatch_CheckD4:
	cp a, 0xd4
	jr nz, AccPatch_EventDispatch_CheckD3
	jr AccPatch_ProcessMarkerCommand

AccPatch_EventDispatch_CheckD3:
	cp a, 0xd3
	jr nz, AccPatch_EventDispatch_CheckD5
	jr AccPatch_ProcessMarkerCommand

AccPatch_EventDispatch_CheckD5:
	cp a, 0xd5
	jr z, AccPatch_ProcessMarkerCommand
	calr AccPatch_SkipToMarker
	jr AccPatch_ContinueProcessing

AccPatch_EventDispatch_NoteOn:
	lds bc, 5
	calr AccPatch_ReadRingBufBytes
	cpdi8 0x36ed, 0
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
	bitda 1, 0x364a
	jr nz, AccPatch_EventDispatch_AdvSlots
	calr AccPatch_ScanToSequenceEnd

AccPatch_EventDispatch_AdvSlots:
	calr AccPatch_AdvanceSlotCounters
	anddi8 0x364a, 253
	jr AccPatch_ContinueProcessing

AccPatch_ProcessMarkerCommand:
	lds bc, 3
	calr AccPatch_ReadRingBufBytes
	calr AccPatch_ParseAndResolve
	calr AccPatch_ProcessMarkerEvent
	jr AccPatch_ContinueProcessing

AccPatch_ContinueProcessing:
	jrl AccPatch_EventDispatchLoop

AccPatch_EventDispatch_Done:
	ret

__pad_F60699:
	nop
	nop

AccPatch_UpdatePlayback:
	cpdi16 0x360a, 0
	jr z, AccPatch_UpdatePlayback_CheckQueue
	ldw_d16 xwa, 0x3602
	stda16 0x36fe, xwa
	ldw_d16 xwa, 0x3604
	stda16 0x3700, xwa
	calr AccPatch_InitSlotAndCopyData
	calr AccPatch_AdvancePlayPos
	calr AccPatch_AdvanceAllSteps
	stdi16 0x360a, 0

AccPatch_UpdatePlayback_CheckQueue:
	cpdi16 0x360e, 0
	jr z, AccPatch_UpdatePlayback_ClearStep
	calr AccPatch_DispatchQueuedNotes

AccPatch_UpdatePlayback_ClearStep:
	stdi8 0x35ff, 0
	ret

__pad_F606D3:
	nop
	nop

AccPatch_AdvanceSlotCounters:
	ld xhl, 0x361a

AccPatch_AdvSlotCtr_Loop:
	bitm 7, (xhl)
	jr z, AccPatch_AdvSlotCtr_Next
	ld a, (xhl + 1)
	cp a, 0xff
	jr z, AccPatch_AdvSlotCtr_Store
	inc 1, a

AccPatch_AdvSlotCtr_Store:
	ld (xhl + 1), a

AccPatch_AdvSlotCtr_Next:
	add xhl, 0x6
	cp xhl, 0x364a
	jr nz, AccPatch_AdvSlotCtr_Loop
	ret

__pad_F606FA:
	nop
	nop

AccPatch_ReadRingBufBytes:
	lds32 xhl, 0

AccPatch_ReadBuf_Loop:
	cp hl, bc
	jr z, AccPatch_ReadBuf_Done
	pushw bc
	pushw hl
	call TempoRingBuf_ReadByteToA
	cp a, 0xff
	jr nz, AccPatch_ReadBuf_StoreAndNext
	nop

AccPatch_ReadBuf_StoreAndNext:
	popw hl
	popw bc
	ld xiz, 0x36ea
	lda_dri XBC, 0x07, 0xf8, 0xec
	inc 1, hl
	jr AccPatch_ReadBuf_Loop

AccPatch_ReadBuf_Done:
	ret

__pad_F6071F:
	nop
	nop

AccPatch_ParseAndResolve:
	ldb_d8 a, 0x36eb
	stb_d8 0x36f7, a
	stb_d8 0x36f8, a
	calr AccPatch_LookupStepByDrumParam
	cpdi8 0x35ff, 0
	jr z, AccPatch_ParseResolve_ParseHdr
	ldb_d8 a, 0x3600
	cpda8 a, 0x36f8
	jr z, AccPatch_ParseResolve_IncStep
	calr AccPatch_UpdatePlayback

AccPatch_ParseResolve_ParseHdr:
	calr AccPatch_ParseSequenceHeader
	ldw_d16 xwa, 0x3612
	stda16 0x3602, xwa
	ldw_d16 xwa, 0x3614
	stda16 0x3604, xwa

AccPatch_ParseResolve_IncStep:
	incdi8 1, 0x35ff
	ldb_d8 a, 0x36f8
	stb_d8 0x3600, a
	ret

__pad_F60764:
	nop
	nop

AccPatch_LookupStepByDrumParam:
	xor w, w
	ld iy, wa
	ldb_d8 a, 0x34db
	cps a, 0
	jr z, AccPatch_SetStepDone
	ld wa, iy
	ldb_d8 w, 0x34db
	and w, 0x7
	call DrumParam_Wrapper
	cp a, 0x7f
	jr nz, AccPatch_LookupStep_StoreResult
	ldb a, 0x0
	stb_d8 0x36f8, a
	stb_d8 0x36eb, a
	bitda 1, 0x364a
	jr nz, AccPatch_SetStepDone
	ordi8 0x364a, 2
	calr AccPatch_UpdatePlayback
	calr AccPatch_ScanToSequenceEnd
	jr AccPatch_SetStepDone

AccPatch_LookupStep_StoreResult:
	stb_d8 0x36f8, a
	stb_d8 0x36eb, a

AccPatch_SetStepDone:
	ret

__pad_F607AA:
	nop
	nop

AccPatch_CopyNoteStepsToSlots:
	ld xhl, 0x361a
	xor iy, iy

AccPatch_CopySteps_FindFreeSlot:
	bit_dri 7, 0x07, 0xec, 0xf4
	jr z, AccPatch_CopySteps_ProcessEntry
	add iy, 0x6
	cp iy, 0x30
	jr z, AccPatch_CopyStepsDone
	jr AccPatch_CopySteps_FindFreeSlot

AccPatch_CopySteps_ProcessEntry:
	ld de, iy
	cpdi16 0x34d4, 0
	jr z, AccPatch_CopySteps_Overflow
	stdi8 0x3431, 0
	stdi8 0x36ea, 144
	bitda 4, 0x379b
	jr nz, AccPatch_CopySteps_StartFetch
	calr AccPatch_TransposeNote

AccPatch_CopySteps_StartFetch:
	ldb_d8 a, 0x36ea
	calr AccPatch_FetchStepEntry
	calr AccPatch_SeqAdvanceStep
	ldb_d8 a, 0x36eb
	calr AccPatch_FetchStepEntry
	calr AccPatch_SeqAdvanceStep
	ldb_d8 a, 0x36ec
	calr AccPatch_FetchStepEntry
	calr AccPatch_UpdateSlotVoiceData
	calr AccPatch_SeqAdvanceStep
	ldb_d8 a, 0x36ed
	calr AccPatch_FetchStepEntry
	calr AccPatch_SeqAdvanceStep
	ldb a, 0x10
	calr AccPatch_FetchStepEntry
	calr AccPatch_SeqAdvanceStep
	ldb a, 0x0
	calr AccPatch_FetchStepEntry
	calr AccPatch_SeqAdvanceStep
	bitda 0, 0x3431
	jr z, AccPatch_CopyStepsDone
	ldb_d8 a, 0x36f0
	calr AccPatch_FetchStepEntry
	calr AccPatch_SeqAdvanceStep
	ldb_d8 a, 0x36f1
	calr AccPatch_FetchStepEntry
	calr AccPatch_SeqAdvanceStep

AccPatch_CopyStepsDone:
	ret

AccPatch_CopySteps_Overflow:
	stdi8 0x7f42, 15
	call DrumVoice_NotifyEE
	ldb a, 0x8
	call MIDI_SendSysExCmd
	jr AccPatch_CopyStepsDone

AccPatch_TransposeNote:
	ldb_d8 a, 0x34e9
	and a, 0xf
	cps a, 0
	jr z, AccPatch_Transpose_LookupTable
	calr AccPatch_ReadTransposeAmount
	cpda8 a, 0x3a4e
	jr ugt, AccPatch_Transpose_AddBack
	subdm8 0x36ec, a
	jr nc, AccPatch_Transpose_Done
	ldb a, 0xc
	adddm8 0x36ec, a

AccPatch_Transpose_Done:
	jr AccPatch_Transpose_LookupTable

AccPatch_Transpose_AddBack:
	ldb w, 0xc
	sub w, a
	adddm8 0x36ec, w

AccPatch_Transpose_LookupTable:
	lds32 xhl, 0
	ldb_d8 l, 0x36ec
	add xhl, Display_FontPalette_Table_0x12EA
	ld a, (xhl)
	bitda 4, 0x34ea
	jr z, AccPatch_Transpose_CheckBit6
	ld w, a
	lds32 xhl, 0
	ld l, a
	add xhl, AccPatch_TransposeNoteTable_0x2
	ld l, (xhl)
	bit 0, l
	jr z, AccPatch_Transpose_CheckBit6
	inc 1, w
	ldb_d8 a, 0x36ec
	inc 1, a
	stb_d8 0x36ec, a
	ld a, w

AccPatch_Transpose_CheckBit6:
	bitda 6, 0x34ea
	jr z, AccPatch_Transpose_CheckBit5
	bitda 3, 0x379b
	jr z, AccPatch_Transpose_CheckBit5
	jr AccPatch_Transpose_SetDrumSplit

AccPatch_Transpose_CheckBit5:
	bitda 5, 0x34ea
	jr z, AccPatch_StoreDrumParams
	bitda 3, 0x379b
	jr nz, AccPatch_StoreDrumParams

AccPatch_Transpose_SetDrumSplit:
	cps a, 7
	jr nz, AccPatch_StoreDrumParams
	stdi8 0x3431, 1
	stdi8 0x36f0, 3
	stdi8 0x36f1, 0
	jr AccPatch_StoreDrumParams_CheckSplit

AccPatch_StoreDrumParams:
	lds32 xhl, 0
	ld l, a
	sll a, 1
	add l, a
	add xhl, AccPatch_TransposeNoteTable_0xE
	ld a, (xhl)
	stb_d8 0x3431, a
	ld a, (xhl + 1)
	stb_d8 0x36f0, a
	ld a, (xhl + 2)
	stb_d8 0x36f1, a

AccPatch_StoreDrumParams_CheckSplit:
	bitda 0, 0x3431
	jr z, AccPatch_StoreDrumParams_Return
	stdi8 0x36ea, 145

AccPatch_StoreDrumParams_Return:
	ret

AccPatch_TransposeNoteTable:
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01
	.byte 0x00, 0x11, 0x01, 0x00, 0x11, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01
	.byte 0x11, 0x11

AccPatch_ReadTransposeAmount:
	push xwa
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	call AccPatch_GetCurrentSlotAddr
	ldb_d8 a, 0x379b
	ld xix, 0x25
	bit 3, a
	jr nz, AccPatch_SelectTranspose
	ld xix, 0x2d
	bit 0, a
	jr nz, AccPatch_SelectTranspose
	ld xix, 0x35
	bit 1, a
	jr nz, AccPatch_SelectTranspose
	ld xix, 0x3d

AccPatch_SelectTranspose:
	add xix, xiy
	ld a, (xix)
	stb_d8 0x3a4e, a
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	pop xwa
	ret

AccPatch_FetchStepEntry:
	ld xiy, 0x366a
	ldw_d16 xhl, 0x360a
	lda_dri XBC, 0x07, 0xf4, 0xec
	inc 1, hl
	stda16 0x360a, xhl
	ret

AccPatch_FetchStepData:
	ld	xiy, 0x36aa
	ldw_d16	hl, 0x360e
	.byte 0xf3
	reti
	.byte 0xf4, 0xec
	ld	xbc, 0x0ef161db
	ldw	iz, 3667

AccPatch_SeqAdvanceStep:
	ldw_d16 xwa, 0x3614
	cp wa, 0xfe
	jr nz, AccPatch_SeqAdvStep_Increment
	cpdi16 0x34d4, 0
	jr z, AccPatch_SeqAdvStep_Return
	calr AccPatch_SeqAdvStep_WrapToNext
	jr AccPatch_SeqAdvStep_Return

AccPatch_SeqAdvStep_Increment:
	inc 1, wa
	stda16 0x3614, xwa

AccPatch_SeqAdvStep_Return:
	ret

AccPatch_SeqAdvStep_WrapToNext:
	ldw_d16 xhl, 0x3612
	calr AccPatch_GetEntryAddr
	ld hl, (xix + 3)
	cp hl, 0xffff
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
	stda16 0x3612, xhl
	stdi16 0x3614, 6
	ret

__pad_F609EE:
	nop
	nop

AccPatch_UpdateSlotVoiceData:
	ld xhl, 0x361a
	ld iy, de
	or a, 0x80
	lda_dri XBC, 0x07, 0xec, 0xf4
	pushw iy
	inc 1, iy
	stib_ind 0x07, 0xec, 0xf4, 0x00
	ldb_d8 a, 0x36f7
	inc 1, iy
	lda_dri XBC, 0x07, 0xec, 0xf4
	ldw_d16 xwa, 0x3612
	inc 1, iy
	stw_dri WA, 0x07, 0xec, 0xf4
	ldw_d16 xwa, 0x3614
	inc 2, iy
	lda_dri XBC, 0x07, 0xec, 0xf4
	popw iy
	ret

AccPatch_TransposeAndCopyNote:
	bitda 4, 0x379b
	jr nz, AccPatch_TransposeCopy_DoCopy
	calr AccPatch_TransposeNote

AccPatch_TransposeCopy_DoCopy:
	ld xiy, 0x36ea
	ld xix, 0x36aa
	lds32 xbc, 0
	ldw_d16 xbc, 0x360e
	add xix, xbc
	lds bc, 6
	ldir85
	adddi16 0x360e, 6
	ret

__pad_F60A51:
	nop
	nop

AccPatch_ProcessMarkerEvent:
	cpdi16 0x34d4, 0
	jr z, AccPatch_ProcessMarker_Return
	ldb_d8 a, 0x36ea
	cp a, 0xd4
	jr nz, AccPatch_ProcessMarker_CheckD3
	ldb a, 0xd3
	jr AccPatch_FetchSequence

AccPatch_ProcessMarker_CheckD3:
	cp a, 0xd3
	jr nz, AccPatch_ProcessMarker_CheckD5
	ldb a, 0xd5
	jr AccPatch_FetchSequence

AccPatch_ProcessMarker_CheckD5:
	cp a, 0xd5
	jr nz, AccPatch_FetchSequence
	ldb a, 0xd4
	jr AccPatch_FetchSequence

AccPatch_FetchSequence:
	calr AccPatch_FetchStepEntry
	calr AccPatch_SeqAdvanceStep
	ldb_d8 a, 0x36eb
	calr AccPatch_FetchStepEntry
	calr AccPatch_SeqAdvanceStep
	ldb_d8 a, 0x36ec
	calr AccPatch_FetchStepEntry
	calr AccPatch_SeqAdvanceStep

AccPatch_ProcessMarker_Return:
	ret

__pad_F60A95:
	nop
	nop

AccPatch_SkipToMarker:
	call TempoRingBuf_ReadByteToA
	bit 7, a
	jr z, AccPatch_SkipToMarker
	ret

AccPatch_SlotCopyDataBlock:
	nop
	nop
	pushw	bc
	call	TempoRingBuf_ReadByteToA
	popw	bc
	dec	1, bc
	cps	bc, 0
	jr	nz, -12
	ret
	stdi16	0x3610, 0
	ld	xix, 0x36aa
	.byte 0xd1
	rcf
	ldw	iz, 7812
	.byte 0x98
	push	sr
	ldw_d16	wa, 0x3610
	add	wa, 6
	stda16	0x3610, wa
	.byte 0xd1
	ret
	ldw	iz, 0x67f0
	.byte 0xe2
	stdi16	0x360e, 0
	ret

AccPatch_InitSlotAndCopyData:
	lds32 xhl, 0
	ldb_d8 l, 0x34d6
	call AccPatch_GetCurrentSlotAddr
	andmi8 (xiy + 15), 0x7f
	ldw_d16 xde, 0x3602
	ldw_d16 xhl, 0x3606
	stda16 0x3658, xhl
	calr AccPatch_GetEntryAddr
	stda32 0x3650, xix
	ldw_d16 xwa, 0x3608
	stda16 0x365e, xwa
	ldw bc, 0xfe
	sub bc, wa
	stda16 0x3702, xbc
	cpda16 xbc, 0x360a
	jr nc, AccPatch_InitSlot_SameBlock
	jr AccPatch_InitSlot_CrossBlock

AccPatch_InitSlot_SameBlock:
	ldw_d16 xhl, 0x3606
	stda16 0x365a, xhl
	calr AccPatch_GetEntryAddr
	stda32 0x364c, xix
	ldw_d16 xwa, 0x3608
	addda16 xwa, 0x360a
	stda16 0x3660, xwa
	jr AccPatch_InitSlot_StoreAddrs

AccPatch_InitSlot_CrossBlock:
	calr AccPatch_FindFreeEntrySlot
	stda16 0x365a, xwa
	ld hl, wa
	calr AccPatch_GetEntryAddr
	stda32 0x364c, xix
	ldw_d16 xwa, 0x360a
	subda16 xwa, 0x3702
	add wa, 0x5
	stda16 0x3660, xwa

AccPatch_InitSlot_StoreAddrs:
	ldw_d16 xwa, 0x365a
	stda16 0x3606, xwa
	ldw_d16 xwa, 0x3660
	stda16 0x3608, xwa
	calr AccPatch_CalcBlockCopySetup
	inc 1, ix
	stda16 0x3704, xix
	ldw_d16 xhl, 0x3602
	calr AccPatch_GetEntryAddr
	lds32 xwa, 0
	ldw_d16 xwa, 0x3604
	add xix, xwa
	ld xiy, 0x366a
	lds32 xbc, 0
	ldw bc, 0xfe
	subda16 xbc, 0x3604
	inc 1, bc
	cpda16 xbc, 0x360a
	jr c, AccPatch_InitSlot_SplitCopy
	lds32 xbc, 0
	ldw_d16 xbc, 0x360a
	ldir85
	jr AccPatch_InitSlot_Finalize

AccPatch_InitSlot_SplitCopy:
	ld wa, bc
	ldir85
	lds32 xbc, 0
	ldw_d16 xbc, 0x360a
	sub bc, wa
	ldw_d16 xhl, 0x3602
	calr AccPatch_GetEntryAddr
	ld hl, (xix + 3)
	calr AccPatch_GetEntryAddr
	add xix, 0x6
	cps bc, 0
	jr z, AccPatch_InitSlot_Finalize
	ldir85

AccPatch_InitSlot_Finalize:
	ldw_d16 xwa, 0x365a
	stda16 0x3602, xwa
	ldw_d16 xwa, 0x3704
	stda16 0x3604, xwa
	ret

__pad_F60BD0:
	nop
	nop

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
	ldw_d16 xhl, 0x3606
	pushw wa
	calr AccPatch_GetEntryAddr
	popw wa
	ld (xix + 3), wa
	pop xix
	ormi8 (xix), 0x80
	ldw_d16 xbc, 0x3606
	ld (xix + 1), bc
	ldw (xix + 3), 0xffff
	decdi16 1, 0x34d4
	ret

__pad_F60C04:
	nop
	nop

AccPatch_AdvancePlayPos:
	calr AccPatch_LoadTablePointers
	ld de, (xix)
	ld hl, (xiy)
	pushw de
	pushw hl
	calr AccPatch_GetEntryAddr
	popw hl
	popw de
	cpda16 xhl, 0x36fe
	jr z, AccPatch_AdvPlayPos_CheckDE
	cpw (xix + 1), 0xffff
	jr nz, AccPatch_AdvPlayPos_AddAndCheck
	jr AccPatch_StoreEntryPtr

AccPatch_AdvPlayPos_CheckDE:
	cpda16 xde, 0x3700
	jr nc, AccPatch_AdvPlayPos_AddAndCheck
	jr AccPatch_StoreEntryPtr

AccPatch_AdvPlayPos_AddAndCheck:
	addda16 xde, 0x360a
	cp de, 0xfe
	jr z, AccPatch_AdvPlayPos_StoreDirect
	jr c, AccPatch_AdvPlayPos_StoreDirect
	sub de, 0xfe
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
	.byte 0x9d
	ldw	de, 0
	.byte 0x9f
	ldw	de, 0
	nop
	nop
	nop
	nop
	.byte 0xa1
	ldw	de, 0
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
	.byte 0x9b
	ldw	de, 0
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
	.byte 0x97
	ldw	de, 0
	nop
	nop
	nop
	nop
	.byte 0x8d
	ldw	de, 0
	.byte 0x8f
	ldw	de, 0
	nop
	nop
	nop
	nop
	.byte 0x91
	ldw	de, 0
	nop
	.zero 8
	nop
	nop
	nop
	.byte 0x8b
	ldw	de, 0
	nop
	.zero 24
	nop
	nop
	nop
	.byte 0x87
	ldw	de, 0

AccPatch_AdvanceAllSteps:
	ld xix, 0x361a

AccPatch_AdvAllSteps_Loop:
	bitm 7, (xix + 1)
	jr z, AccPatch_AdvAllSteps_Next
	ldw_d16 xbc, 0x360a

AccPatch_AdvAllSteps_InnerLoop:
	calr AccPatch_AdvanceSingleStep
	djnz xbc, AccPatch_AdvAllSteps_InnerLoop

AccPatch_AdvAllSteps_Next:
	add xix, 0x6
	cp xix, 0x364a
	jr c, AccPatch_AdvAllSteps_Loop
	ret

__pad_F60D0C:
	nop
	nop

AccPatch_AdvanceSingleStep:
	xor w, w
	ld a, (xix + 5)
	cp wa, 0xfe
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
	nop
	nop

AccPatch_DispatchQueuedNotes:
	ld xix, 0x36aa

AccPatch_DispatchQueued_Loop:
	calr AccPatch_DispatchNoteToVoice
	add xix, 0x6
	ld xwa, xix
	sub xwa, 0x36aa
	cpda16 xwa, 0x360e
	jr c, AccPatch_DispatchQueued_Loop
	stdi16 0x360e, 0
	ret

__pad_F60D58:
	nop
	nop

AccPatch_DispatchNoteToVoice:
	ld xhl, 0x361a
	ldw iy, 0x2a

AccPatch_DispatchNote_Loop:
	bit_dri 7, 0x07, 0xec, 0xf4
	jr z, AccPatch_DispatchNote_NextSlot
	ldb_sri A, 0x07, 0xec, 0xf4
	and a, 0x7f
	cp a, (xix + 2)
	jr nz, AccPatch_DispatchNote_NextSlot
	and_srib_im 0x07, 0xec, 0xf4, 0x7f
	inc 1, iy
	and_srib_im 0x07, 0xec, 0xf4, 0x7f
	ldb_sri D, 0x07, 0xec, 0xf4
	inc 1, iy
	ldb_sri A, 0x07, 0xec, 0xf4
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
	nop
	nop

AccPatch_WriteVelocityToSeq:
	pushw de
	pushw wa
	ldw_d16 xwa, 0x3612
	stda16 0x36fa, xwa
	ldw_d16 xwa, 0x3614
	stda16 0x36fc, xwa
	inc 1, iy
	ldw_sri WA, 0x07, 0xec, 0xf4
	stda16 0x3612, xwa
	pushw iy
	inc 2, iy
	xor wa, wa
	ldb_sri A, 0x07, 0xec, 0xf4
	popw iy
	stda16 0x3614, xwa
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
	ldw_d16 xwa, 0x36fa
	stda16 0x3612, xwa
	ldw_d16 xwa, 0x36fc
	stda16 0x3614, xwa
	ret

__pad_F60E12:
	nop
	nop

AccPatch_WriteSeqByte:
	push xix
	ldw_d16 xhl, 0x3612
	calr AccPatch_GetEntryAddr
	push xwa
	lds32 xwa, 0
	ldw_d16 xwa, 0x3614
	add xix, xwa
	pop xwa
	ld (xix), a
	pop xix
	ret

__pad_F60E2A:
	nop
	nop

AccPatch_CalcBlockCopySetup:
	stdi8 0x7f42, 0
	cpda16 xde, 0x3658
	jr nz, AccPatch_CalcBlockCopy_DiffEntry
	ldw_d16 xiy, 0x365e
	sub iy, 0x6
	inc 1, iy
	stda16 0x3664, xiy
	ldw_d16 xiy, 0x365e
	ldw_d16 xix, 0x3660
	sub ix, 0x6
	inc 1, ix
	stda16 0x3666, xix
	ldw_d16 xix, 0x3660
	calr AccPatch_CalcBlockCopyBounds
	jr AccPatch_CalcBlockCopy_Done

AccPatch_CalcBlockCopy_DiffEntry:
	ldw_d16 xwa, 0x3660
	cpda16 xwa, 0x365e
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
	cpdi8 0x7f42, 0
	jr nz, AccPatch_CalcBlockCopy_Done
	calr AccPatch_CalcBlockCopyBounds

AccPatch_CalcBlockCopy_Done:
	ret

__pad_F60E86:
	ldw_d16 xwa, 0x3660
	subda16 xwa, 0x365e
	stda16 0x3654, xwa
	ldw bc, 0xff
	sub bc, 0x6
	sub bc, wa
	stda16 0x3656, xbc
	lds32 xix, 0
	lds32 xiy, 0
	ldw_d16 xiy, 0x365e
	ldw_d16 xix, 0x3660
	ldw_d16 xbc, 0x365e
	sub bc, 0x6
	inc 1, bc
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IY
	cpdi8 0x7f42, 0
	jr z, BlockCopy_Rev_CheckSameEntry
	jr DSP_SetupDone

BlockCopy_Rev_CheckSameEntry:
	cpda16 xde, 0x3658
	jr nz, BlockCopy_Rev_CopyDiffEntry
	jr BlockCopy_Rev_StoreBounds

BlockCopy_Rev_CopyDiffEntry:
	ldw_d16 xbc, 0x3654
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IX
	cpdi8 0x7f42, 0
	jr z, BlockCopy_Rev_CopyRemainder
	jr DSP_SetupDone

BlockCopy_Rev_CopyRemainder:
	ldw_d16 xbc, 0x3656
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IY
	cpdi8 0x7f42, 0
	jr z, BlockCopy_Rev_CheckSameEntry
	jr DSP_SetupDone

BlockCopy_Rev_StoreBounds:
	ldw_d16 xwa, 0x3654
	stda16 0x3666, xwa
	ldw bc, 0xff
	sub bc, 0x6
	stda16 0x3664, xbc

DSP_SetupDone:
	ret

DSP_BlockCopyReverse:
	push xwa
	push xhl
	and xiy, 0xff
	and xix, 0xff
	ldda32 xwa, 0x364c
	ldda32 xhl, 0x3650
	push xwa
	push xhl
	add xwa, xix
	ld xix, xwa
	add xhl, xiy
	ld xiy, xhl
	lddr85
	pop xhl
	pop xwa
	stda32 0x3650, xhl
	stda32 0x364c, xwa
	and xiy, 0xff
	and xix, 0xff
	pop xhl
	pop xwa
	ret

DSP_BlockCopyForward:
	push xwa
	push xhl
	and xiy, 0xff
	and xix, 0xff
	ldda32 xwa, 0x364c
	ldda32 xhl, 0x3650
	push xwa
	push xhl
	add xwa, xix
	ld xix, xwa
	add xhl, xiy
	ld xiy, xhl
	ldir85
	pop xhl
	pop xwa
	stda32 0x3650, xhl
	stda32 0x364c, xwa
	and xiy, 0xff
	and xix, 0xff
	pop xhl
	pop xwa
	ret

BlockCopy_SameEntry_Reverse:
	ldw_d16 xbc, 0x365e
	sub bc, 0x6
	inc 1, bc
	ldw_d16 xiy, 0x365e
	ldw_d16 xix, 0x3660
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IX
	cpdi8 0x7f42, 0
	jr z, BlockCopy_SameEntry_AdvIY
	jr DSP_NullRet

BlockCopy_SameEntry_AdvIY:
	calr AccPatch_AdvanceNextEntry_IY
	cpdi8 0x7f42, 0
	jr z, BlockCopy_SameEntry_CheckDE
	jr DSP_NullRet

BlockCopy_SameEntry_CheckDE:
	cpda16 xde, 0x3658
	jr nz, BlockCopy_SameEntry_FullCopy
	jr BlockCopy_SameEntry_StoreBounds

BlockCopy_SameEntry_FullCopy:
	ldw bc, 0xff
	sub bc, 0x6
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IX
	cpdi8 0x7f42, 0
	jr z, BlockCopy_SameEntry_AdvIYLoop
	jr DSP_NullRet

BlockCopy_SameEntry_AdvIYLoop:
	calr AccPatch_AdvanceNextEntry_IY
	cpdi8 0x7f42, 0
	jr z, BlockCopy_SameEntry_CheckDE
	jr DSP_NullRet

BlockCopy_SameEntry_StoreBounds:
	ldw bc, 0xff
	sub bc, 0x6
	stda16 0x3666, xbc
	stda16 0x3664, xbc

DSP_NullRet:
	ret

BlockCopy_IXFirst_Reverse:
	ldw_d16 xwa, 0x365e
	subda16 xwa, 0x3660
	stda16 0x3654, xwa
	ldw bc, 0xff
	sub bc, 0x6
	sub bc, wa
	stda16 0x3656, xbc
	lds32 xix, 0
	lds32 xiy, 0
	ldw_d16 xiy, 0x365e
	ldw_d16 xix, 0x3660
	ldw_d16 xbc, 0x3660
	sub bc, 0x6
	inc 1, bc
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IX
	cpdi8 0x7f42, 0
	jr z, BlockCopy_IXFirst_CopyOffset
	jr DSP_NullRet2

BlockCopy_IXFirst_CopyOffset:
	ldw_d16 xbc, 0x3654
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IY
	cpdi8 0x7f42, 0
	jr z, BlockCopy_IXFirst_CheckDE
	jr DSP_NullRet2

BlockCopy_IXFirst_CheckDE:
	cpda16 xde, 0x3658
	jr nz, BlockCopy_IXFirst_CopyRemainder
	jr BlockCopy_IXFirst_StoreBounds

BlockCopy_IXFirst_CopyRemainder:
	ldw_d16 xbc, 0x3656
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IX
	cpdi8 0x7f42, 0
	jr z, BlockCopy_IXFirst_CopyOffset2
	jr DSP_NullRet2

BlockCopy_IXFirst_CopyOffset2:
	ldw_d16 xbc, 0x3654
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IY
	cpdi8 0x7f42, 0
	jr z, BlockCopy_IXFirst_CheckDE
	jr DSP_NullRet2

BlockCopy_IXFirst_StoreBounds:
	ldw_d16 xwa, 0x3656
	stda16 0x3666, xwa
	ldw wa, 0xff
	sub wa, 0x6
	stda16 0x3664, xwa

DSP_NullRet2:
	ret

AccPatch_CalcBlockCopyBounds:
	ldw_d16 xwa, 0x3604
	sub wa, 0x6
	ldw_d16 xbc, 0x3664
	sub bc, wa
	stda16 0x3668, xbc
	cpdm16 0x3666, xbc
	jr nc, BlockCopyBounds_UseBC
	jr BlockCopyBounds_UseSmaller

BlockCopyBounds_UseBC:
	calr DSP_BlockCopyReverse
	jr BlockCopyBounds_Return

BlockCopyBounds_UseSmaller:
	ldw_d16 xbc, 0x3666
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IX
	cpdi8 0x7f42, 0
	jr z, BlockCopyBounds_CopyRemainder
	jr BlockCopyBounds_Return

BlockCopyBounds_CopyRemainder:
	ldw_d16 xbc, 0x3668
	subda16 xbc, 0x3666
	calr DSP_BlockCopyReverse

BlockCopyBounds_Return:
	ret

AccPatch_AdvanceNextEntry_IY:
	push xix
	ldda32 xiy, 0x3650
	ld hl, (xiy + 1)
	stda16 0x3658, xhl
	calr AccPatch_GetEntryAddr
	bitm 7, (xix + 256)
	jr nz, AdvNextEntry_IY_StoreAndReset
	stdi8 0x7f42, 11
	jr AdvNextEntry_IY_Return

AdvNextEntry_IY_StoreAndReset:
	stda32 0x3650, xix
	lds32 xiy, 0
	ldw iy, 0xfe

AdvNextEntry_IY_Return:
	pop xix
	ret

AccPatch_AdvanceNextEntry_IX:
	ldda32 xix, 0x364c
	ld hl, (xix + 1)
	stda16 0x365a, xhl
	calr AccPatch_GetEntryAddr
	bitm 7, (xix + 256)
	jr nz, AdvNextEntry_IX_StoreAndReset
	stdi8 0x7f42, 11
	jr AdvNextEntry_IX_Return

AdvNextEntry_IX_StoreAndReset:
	stda32 0x364c, xix
	lds32 xix, 0
	ldw ix, 0xfe

AdvNextEntry_IX_Return:
	ret

AccPatch_SetupBlockCopyDispatch:
	stdi8 0x7f42, 0
	ldw_d16 xhl, 0x3658
	calr AccPatch_GetEntryAddr
	stda32 0x3650, xix
	cpda16 xde, 0x3658
	jr nz, BlockCopyDisp_CompareOffsets
	lds32 xiy, 0
	ldw iy, 0xff
	subda16 xiy, 0x365e
	stda16 0x3664, xiy
	ldw_d16 xiy, 0x365e
	lds32 xix, 0
	ldw ix, 0xff
	subda16 xix, 0x3660
	stda16 0x3666, xix
	ldw_d16 xix, 0x3660
	calr AccPatch_ForwardBlockCopy
	jr BlockCopyDisp_Return

BlockCopyDisp_CompareOffsets:
	ldw_d16 xwa, 0x3660
	cpda16 xwa, 0x365e
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
	jr BlockCopyDisp_CheckAndForward

BlockCopyDisp_CheckAndForward:
	cpdi8 0x7f42, 0
	jr nz, BlockCopyDisp_Return
	calr AccPatch_ForwardBlockCopy

BlockCopyDisp_Return:
	ret

BlockCopy_FwdIYSmaller:
	ldw wa, 0xff
	subda16 xwa, 0x3660
	ldw bc, 0xff
	subda16 xbc, 0x365e
	sub wa, bc
	stda16 0x3654, xwa
	ldw bc, 0xff
	sub bc, 0x6
	sub bc, wa
	stda16 0x3656, xbc
	lds32 xiy, 0
	ldw_d16 xiy, 0x365e
	lds32 xix, 0
	ldw_d16 xix, 0x3660
	ldw bc, 0xff
	subda16 xbc, 0x365e
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IY
	cpdi8 0x7f42, 0
	jr z, BlockCopy_FwdIYSmall_CheckDE
	jr DSP_CopyDone

BlockCopy_FwdIYSmall_CheckDE:
	cpda16 xde, 0x3658
	jr nz, BlockCopy_FwdIYSmall_CopyOffset
	jr BlockCopy_FwdIYSmall_StoreBounds

BlockCopy_FwdIYSmall_CopyOffset:
	ldw_d16 xbc, 0x3654
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IX
	cpdi8 0x7f42, 0
	jr z, BlockCopy_FwdIYSmall_CopyRem
	jr DSP_CopyDone

BlockCopy_FwdIYSmall_CopyRem:
	ldw_d16 xbc, 0x3656
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IY
	cpdi8 0x7f42, 0
	jr z, BlockCopy_FwdIYSmall_CheckDE
	jr DSP_CopyDone

BlockCopy_FwdIYSmall_StoreBounds:
	ldw_d16 xwa, 0x3654
	stda16 0x3666, xwa
	ldw bc, 0xff
	sub bc, 0x6
	stda16 0x3664, xbc

DSP_CopyDone:
	ret

BlockCopy_FwdEqual:
	ldw bc, 0xff
	subda16 xbc, 0x365e
	lds32 xiy, 0
	ldw_d16 xiy, 0x365e
	lds32 xix, 0
	ldw_d16 xix, 0x3660
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IY
	cpdi8 0x7f42, 0
	jr z, BlockCopy_FwdEqual_AdvIX
	jr AccPatch_NullRet2

BlockCopy_FwdEqual_AdvIX:
	calr AccPatch_AdvancePrevEntry_IX
	cpdi8 0x7f42, 0
	jr z, BlockCopy_FwdEqual_CheckDE
	jr AccPatch_NullRet2

BlockCopy_FwdEqual_CheckDE:
	cpda16 xde, 0x3658
	jr nz, BlockCopy_FwdEqual_FullCopy
	jr BlockCopy_FwdEqual_StoreBounds

BlockCopy_FwdEqual_FullCopy:
	ldw bc, 0xff
	sub bc, 0x6
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IY
	cpdi8 0x7f42, 0
	jr z, BlockCopy_FwdEqual_AdvIXLoop
	jr AccPatch_NullRet2

BlockCopy_FwdEqual_AdvIXLoop:
	calr AccPatch_AdvancePrevEntry_IX
	cpdi8 0x7f42, 0
	jr z, BlockCopy_FwdEqual_CheckDE
	jr AccPatch_NullRet2

BlockCopy_FwdEqual_StoreBounds:
	ldw bc, 0xff
	sub bc, 0x6
	stda16 0x3666, xbc
	stda16 0x3664, xbc

AccPatch_NullRet2:
	ret

BlockCopy_FwdIXSmaller:
	ldw wa, 0xff
	subda16 xwa, 0x365e
	ldw bc, 0xff
	subda16 xbc, 0x3660
	sub wa, bc
	stda16 0x3654, xwa
	ldw bc, 0xff
	sub bc, 0x6
	sub bc, wa
	stda16 0x3656, xbc
	lds32 xiy, 0
	ldw_d16 xiy, 0x365e
	lds32 xix, 0
	ldw_d16 xix, 0x3660
	ldw bc, 0xff
	subda16 xbc, 0x3660
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IX
	cpdi8 0x7f42, 0
	jr z, BlockCopy_FwdIXSmall_CopyOff
	jr AccPatch_NullRet3

BlockCopy_FwdIXSmall_CopyOff:
	ldw_d16 xbc, 0x3654
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IY
	cpdi8 0x7f42, 0
	jr z, BlockCopy_FwdIXSmall_CheckDE
	jr AccPatch_NullRet3

BlockCopy_FwdIXSmall_CheckDE:
	cpda16 xde, 0x3658
	jr nz, BlockCopy_FwdIXSmall_CopyRem
	jr BlockCopy_FwdIXSmall_StoreBounds

BlockCopy_FwdIXSmall_CopyRem:
	ldw_d16 xbc, 0x3656
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IX
	cpdi8 0x7f42, 0
	jr z, BlockCopy_FwdIXSmall_CopyOff2
	jr AccPatch_NullRet3

BlockCopy_FwdIXSmall_CopyOff2:
	ldw_d16 xbc, 0x3654
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IY
	cpdi8 0x7f42, 0
	jr z, BlockCopy_FwdIXSmall_CheckDE
	jr AccPatch_NullRet3

BlockCopy_FwdIXSmall_StoreBounds:
	ldw_d16 xwa, 0x3656
	stda16 0x3666, xwa
	ldw wa, 0xff
	sub wa, 0x6
	stda16 0x3664, xwa

AccPatch_NullRet3:
	ret

AccPatch_ForwardBlockCopy:
	cpdi8 0x7f42, 0
	jr nz, AccPatch_DoneBlockCopy
	ldw wa, 0xfe
	subda16 xwa, 0x3662
	ldw_d16 xbc, 0x3664
	sub bc, wa
	stda16 0x3668, xbc
	cpdm16 0x3666, xbc
	jr nc, FwdBlockCopy_UseFull
	jr FwdBlockCopy_UseSmaller

FwdBlockCopy_UseFull:
	calr DSP_BlockCopyForward
	jr AccPatch_DoneBlockCopy

FwdBlockCopy_UseSmaller:
	ldw_d16 xbc, 0x3666
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IX
	cpdi8 0x7f42, 0
	jr z, FwdBlockCopy_CopyRemainder
	jr AccPatch_DoneBlockCopy

FwdBlockCopy_CopyRemainder:
	ldw_d16 xbc, 0x3668
	subda16 xbc, 0x3666
	calr DSP_BlockCopyForward

AccPatch_DoneBlockCopy:
	ret

AccPatch_AdvancePrevEntry_IX:
	ldda32 xix, 0x364c
	ld hl, (xix + 3)
	stda16 0x365a, xhl
	calr AccPatch_GetEntryAddr
	bitm 7, (xix)
	jr nz, AdvPrevEntry_IX_StoreAndReset
	stdi8 0x7f42, 11
	jr AdvPrevEntry_IX_Return

AdvPrevEntry_IX_StoreAndReset:
	stda32 0x364c, xix
	lds32 xix, 0
	lds ix, 6

AdvPrevEntry_IX_Return:
	ret

AccPatch_AdvancePrevEntry_IY:
	push xix
	ldda32 xix, 0x3650
	ld hl, (xix + 3)
	stda16 0x3658, xhl
	calr AccPatch_GetEntryAddr
	bitm 7, (xix)
	jr nz, AdvPrevEntry_IY_StoreAndReset
	stdi8 0x7f42, 11
	jr AdvPrevEntry_IY_Return

AdvPrevEntry_IY_StoreAndReset:
	stda32 0x3650, xix
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
	anddi8 0x34d0, 239
	ldb_d8 a, 0x379b
	and a, 0x7f
	cpda8 a, 0x3510
	jr z, AccPlayback_CheckStyleMatch
	and a, 0x1f
	cps a, 0
	jr z, AccPlayback_CheckStyleMatch
	ordi8 0x34d0, 16

AccPlayback_CheckStyleMatch:
	ldb_d8 a, 0x8d36
	cp a, 0xb6
	jr z, AccPlayback_CheckActiveStyle
	jrl AccPlayback_Finalize

AccPlayback_CheckActiveStyle:
	cpda8 a, 0x3525
	jr z, AccPlayback_CheckBit4
	stdi8 0x34fd, 0
	call TempoRingBuf_Init
	bitda 0, 0x3283
	jr nz, AccPlayback_GetSlotAddr
	ordi8 0x34cd, 128

AccPlayback_GetSlotAddr:
	call AccPatch_GetCurrentSlotAddr
	call AccPatch_ReadVoiceStride

AccPlayback_CheckBit4:
	bitda 4, 0x34d0
	jr nz, AccPlayback_InitTimingVars
	ldb_d8 a, 0x3525
	cp a, 0xb6
	jr z, AccPlayback_CheckStateFlags

AccPlayback_InitTimingVars:
	ldb a, 0x0
	stb_d8 0x34fa, a
	stb_d8 0x34fc, a
	stb_d8 0x34fb, a
	stb_d8 0x3746, a
	stdi16 0x3747, 1
	calr AccPlayback_CalcTimingPosition
	call AccPatch_GetCurrentSlotAddr
	call AccPatch_ScanToSequenceStart
	stdi8 0x3712, 4
	stdi8 0x3717, 255
	stdi8 0x3522, 0
	anddi8 0x34cf, 127

AccPlayback_CheckStateFlags:
	anddi8 0x34d0, 254
	ldb_d8 a, 0x3713
	and a, 0xc0
	cps a, 0
	jr z, AccPlayback_CheckSkipInit
	ordi8 0x34d0, 1
	calr AccPlayback_AdjustBeatPosition
	calr AccPlayback_CalcTimingPosition
	call AccPatch_GetCurrentSlotAddr
	calr AccVoice_InitPatternBuffer
	ordi8 0xe3e0, 16

AccPlayback_CheckSkipInit:
	bitda 4, 0x34d0
	jr nz, AccPlayback_ApplyChanges
	bitda 0, 0x34d0
	jr nz, AccPlayback_ApplyChanges
	ldb_d8 a, 0x3525
	cp a, 0xb6
	jr z, AccPlayback_CheckBit0_3

AccPlayback_ApplyChanges:
	anddi8 0x34d0, 223
	calr AccPlayback_ProcessStyleChanges
	anddi8 0x34d0, 254
	anddi8 0x3713, 63

AccPlayback_CheckBit0_3:
	ldb_d8 a, 0x3713
	and a, 0x3
	cps a, 0
	jr z, AccPlayback_ProcessMiscFlags
	calr AccPlayback_ProcessPartChanges
	anddi8 0x3713, 252

AccPlayback_ProcessMiscFlags:
	ldb_d8 a, 0x372d
	and a, 0x3f
	cps a, 0
	jr z, AccPlayback_RunPeriodicTasks
	calr AccPlayback_ProcessVoiceType5
	anddi8 0x372d, 192

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
; Output: XHL = 0x95c00 + (HL & 0xffff) * 256
; Calculates address into tone generator hardware buffer memory.
; Called from MIDI voice processing code (handles status bytes 0x81-0x91).
; ============================================================================
ToneGen_CalcBufferAddr:
	and xhl, 0xffff
	sla xhl, 8
	add xhl, 0x95c00
	ret

__pad_F614C1:
	nop
	nop

AccPlayback_CalcTimingPosition:
	ldb_d8 a, 0x34fa
	inc 1, a
	xor w, w
	stda16 0x371a, xwa
	calr ToneGen_StepFwd_Alternate
	jr AccTiming_ComputeOffset
	ldb a, 0x20
	cpdi8 0x34fb, 4
	jr c, AccTiming_StorePartA

AccTiming_StorePartA:
	stb_d8 0x371c, a

AccTiming_ComputeOffset:
	ldb_d8 w, 0x34fb
	ldb a, 0x8
	muls8rr a, w
	ld h, a
	ldb_d8 a, 0x34fc
	xor w, w
	ldb l, 0xc
	div8rr a, l
	add h, a
	inc 1, h
	ldb_d8 a, 0x34fa
	subda8 a, 0x3746
	ldb w, 0x20
	cpdi8 0x34d9, 5
	jr c, AccTiming_UseFullBar
	ldb w, 0x40

AccTiming_UseFullBar:
	muls8rr a, w
	add h, a
	stb_d8 0x370f, h
	jr AccTiming_CompareStyles
	cp h, 0x20
	jr ule, AccTiming_StoreResult
	sub h, 0x20

AccTiming_StoreResult:
	stb_d8 0x370f, h

AccTiming_CompareStyles:
	ldb_d8 a, 0x8d36
	cpda8 a, 0x8d38
	jr nz, AccTiming_Return

AccTiming_Return:
	ret

__pad_F6152D:
	nop
	nop

AccPlayback_AdjustBeatPosition:
	ldw_d16 xwa, 0x371a
	dec 1, a
	bitda 7, 0x3713
	jr z, AccBeatAdj_CheckBit6
	inc 1, a
	cpda8 a, 0x34d7
	jr ule, AccBeatAdj_CheckBit6
	ldb a, 0x0

AccBeatAdj_CheckBit6:
	bitda 6, 0x3713
	jr z, AccBeatAdj_StoreAndClear
	dec 1, a
	cp a, 0xff
	jr nz, AccBeatAdj_StoreAndClear
	ldb_d8 a, 0x34d7

AccBeatAdj_StoreAndClear:
	stb_d8 0x34fa, a
	stdi8 0x34fc, 0
	stdi8 0x34fb, 0
	ret

__pad_F61565:
	nop
	nop

AccVoice_InitPatternBuffer:
	ld xhl, 0x372e
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
	ldb_d8 a, 0x3746
	ldb_d8 w, 0x34d9
	muls8rr a, w
	ld c, a
	jr ToneGen_SkipToNoteEntry
	ldb_d8 a, 0x34fa
	ldb_d8 w, 0x34d9
	muls8rr a, w
	ld c, a
	cpdi8 0x34d9, 5
	jr c, ToneGen_SkipToNoteEntry
	cpdi8 0x34fb, 4
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
	stdi8 0x350e, 0
	ldb_d8 c, 0x373e
	calr ToneGen_ParseEventBuffer
	incdi8 1, 0x350e
	ldb_d8 c, 0x373f
	calr ToneGen_ParseEventBuffer
	incdi8 1, 0x350e
	ldb_d8 c, 0x3740
	calr ToneGen_ParseEventBuffer
	incdi8 1, 0x350e
	ldb_d8 c, 0x3741
	calr ToneGen_ParseEventBuffer
	ldb_d8 a, 0x8d36
	cpda8 a, 0x8d38
	jr nz, ToneGen_SaveRegsAndCall
	stdi8 0xe3e0, 16

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
	nop
	nop

ToneGen_ParseEventBuffer:
	stdi8 0x350f, 0

EventBuffer_ParseLoop:
	cps c, 0
	jr nz, EventBuffer_ReadByte
	jrl ToneGen_ParseEvent_Done

EventBuffer_ReadByte:
	ld a, (xix)
	cp a, 0x81
	jr nz, EventBuffer_CheckNoteType
	dec 1, c
	incdi8 1, 0x350f
	calr ToneGen_ReadBufferWithIndirection
	jr EventBuffer_ParseLoop

EventBuffer_CheckNoteType:
	cp a, 0x90
	jr z, ToneGen_MapNoteToOctaveBitmask
	cp a, 0x91
	jr z, ToneGen_MapNoteToOctaveBitmask
	cp a, 0xd1
	jr z, ToneGen_MapNoteToOctaveBitmask
	cp a, 0xd2
	jr z, ToneGen_MapNoteToOctaveBitmask
	cp a, 0xd3
	jr z, ToneGen_MapNoteToOctaveBitmask
	cp a, 0xd4
	jr z, ToneGen_MapNoteToOctaveBitmask
	cp a, 0xd5
	jr z, ToneGen_MapNoteToOctaveBitmask
	cp a, 0xd6
	jr z, ToneGen_MapNoteToOctaveBitmask
	calr ToneGen_ReadBufferWithIndirection
	jr EventBuffer_ParseLoop

ToneGen_MapNoteToOctaveBitmask:
	calr ToneGen_ReadBufferWithIndirection
	ld a, (xix)
	xor w, w
	ldb l, 0xc
	div8rr a, l
	pushw bc
	push xix
	and a, 0x7
	ld c, a
	xor b, b
	ld xix, ToneGen_MapNoteToOctaveBitmask_0x20
	ldb_sri C, 0x07, 0xf0, 0xe4
	jr ToneGen_MapNote_OrMask
	; Bit mask lookup table (powers of 2):
	normal
	push	sr
	max
	ldio	16, 32
	.byte 0x40, 0x80

ToneGen_MapNote_OrMask:
	ldb_d8 l, 0x350f
	xor h, h
	ldb_d8 a, 0x350e
	and a, 0x3
	sla a, 2
	add l, a
	ld xix, 0x372e
	ldb_sri A, 0x07, 0xf0, 0xec
	or a, c
	lda_dri XBC, 0x07, 0xf0, 0xec
	pop xix
	popw bc
	calr ToneGen_ReadBufferWithIndirection
	jrl EventBuffer_ParseLoop

ToneGen_ParseEvent_Done:
	ret

__pad_F616D5:
	nop
	nop

AccPlayback_ProcessStyleChanges:
	stdi8 0x370f, 1
	stdi8 0x3712, 4
	stdi8 0x3717, 255
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
	stb_d8 0x34f7, a
	stb_d8 0x34fb, a
	stb_d8 0x34fc, a
	ldw_d16 xwa, 0x371a
	dec 1, a
	stb_d8 0x34fa, a
	call AccPatch_GetCurrentSlotAddr
	calr AccPlayback_CalcTimingPosition
	calr AccVoice_InitPatternBuffer
	ret

AccStyleChange_CheckPartCount:
	nop
	nop

AccPlayback_ProcessPartChanges:
	anddi8 0x3522, 115
	cpdi8 0x34fc, 0
	jr nz, AccPartChange_Bit1
	ordi8 0x3522, 4

AccPartChange_Bit1:
	bitda 0, 0x3713
	jr nz, AccPartChange_CheckBit2
	calr ToneGen_ProcessWithRestore
	jrl ToneGen_UpdateAndInitPattern

AccPartChange_CheckBit2:
	bitda 5, 0x34d0
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
	anddi8 0x34d0, 223

ToneGen_CalcAndRestart:
	calr ToneGen_RecalcAndRestart
	jrl ToneGen_UpdateAndInitPattern

__pad_F61760:
	ldw_d16 xwa, 0x346b
	stda16 0x3514, xwa
	ldw_d16 xwa, 0x3449
	stda16 0x3512, xwa
	ordi8 0x34d0, 32
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ldw_d16 xwa, 0x3449
	ldb_sri A, 0x07, 0xec, 0xe0
	cp a, 0x81
	jr nz, ToneGen_PushAndReadType
	calr ToneGen_StepToNextVoiceSlot
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ldw_d16 xwa, 0x3449
	ldb_sri A, 0x07, 0xec, 0xe0
	cp a, 0x90
	jr z, ToneGen_ProcessVoiceEvent
	cp a, 0x91
	jr z, ToneGen_ProcessVoiceEvent
	cp a, 0xd1
	jr z, ToneGen_ProcessVoiceEvent
	cp a, 0xd2
	jr z, ToneGen_ProcessVoiceEvent
	cp a, 0xd3
	jr z, ToneGen_ProcessVoiceEvent
	cp a, 0xd4
	jr z, ToneGen_ProcessVoiceEvent
	cp a, 0xd5
	jr z, ToneGen_ProcessVoiceEvent
	cp a, 0xd6
	jr z, ToneGen_ProcessVoiceEvent
	jr ToneGen_CalcAndRestart

ToneGen_ProcessVoiceEvent:
	calr AccVoice_ReadCurrentToneType
	cps a, 0
	jr nz, ToneGen_CalcAndRestart
	ldw_d16 xwa, 0x346b
	stda16 0x3514, xwa
	ldw_d16 xwa, 0x3449
	stda16 0x3512, xwa
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ldw_d16 xwa, 0x3449
	ldb_sri A, 0x07, 0xec, 0xe0
	pushw wa
	push xhl
	calr ToneGen_AdvancePeriodWrap
	pop xhl
	popw wa

ToneGen_PushAndReadType:
	pushw wa
	calr AccVoice_ReadCurrentToneType
	ld w, a
	stb_d8 0x34fc, w
	popw wa
	calr ToneGen_ClassifyAndDispatch

ToneGen_UpdateAndInitPattern:
	anddi8 0x34cf, 127
	calr AccPlayback_CalcTimingPosition
	call AccPatch_GetCurrentSlotAddr
	calr AccVoice_InitPatternBuffer
	ordi8 0xe3e0, 16
	ret

ToneGen_VoiceSlotLookupTable:
	.byte 0x00, 0x00, 0x00, 0x94, 0x95, 0x00, 0x96, 0x00
	.byte 0x00, 0x00, 0x97, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x98

ToneGen_ProcessWithRestore:
	bitda 5, 0x34d0
	jr z, ToneGen_ProcessRestore_Direct
	calr ToneGen_RestoreFromSavedPos
	jr ToneGen_ProcessRestore_CalcPos

ToneGen_ProcessRestore_Direct:
	call AccPatch_GetCurrentSlotAddr
	calr ToneGen_ProcessVoiceSlots
	anddi8 0x3522, 254

ToneGen_ProcessRestore_CalcPos:
	calr ToneGen_CalcNotePosition
	ldw_d16 xbc, 0x3520
	cp bc, wa
	jr c, ToneGen_ProcessRestore_CheckDelta
	sub bc, wa
	cp bc, 0x200
	jr ugt, ToneGen_ProcessRestore_CheckDelta
	jr ToneGen_ProcessRestore_UseSaved

ToneGen_ProcessRestore_CheckDelta:
	cps bc, 0
	jr nz, ToneGen_ProcessRestore_ClearBit5
	bitda 3, 0x3522
	jr z, ToneGen_ProcessRestore_ClearBit5
	jr ToneGen_ProcessRestore_UseSaved

ToneGen_ProcessRestore_ClearBit5:
	anddi8 0x34d0, 223

ToneGen_ProcessRestore_CalcNote:
	ldb_d8 a, 0x34fc
	ld e, a
	xor w, w
	ldb l, 0xc
	div8rr a, l
	cps w, 0
	jr nz, ToneGen_ProcessRestore_AdjNote
	ldb w, 0xc

ToneGen_ProcessRestore_AdjNote:
	calr ToneGen_AdjustNoteWrap
	ldb a, 0x4
	stb_d8 0x3712, a
	ldb w, 0xff
	stdi8 0x3717, 255
	jr ToneGen_ProcessRestore_Return

ToneGen_ProcessRestore_UseSaved:
	bitda 0, 0x3522
	jr nz, ToneGen_ProcessRestore_UseActive
	ldw_d16 xwa, 0x351a
	stda16 0x3514, xwa
	stda16 0x346b, xwa
	ldw_d16 xwa, 0x351e
	stda16 0x3512, xwa
	stda16 0x3449, xwa
	jr ToneGen_ProcessRestore_SetBit5

ToneGen_ProcessRestore_UseActive:
	ldw_d16 xwa, 0x346b
	stda16 0x3514, xwa
	ldw_d16 xwa, 0x3449
	stda16 0x3512, xwa

ToneGen_ProcessRestore_SetBit5:
	ordi8 0x34d0, 32
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ldb_sri A, 0x07, 0xec, 0xe0
	cp a, 0x81
	jr nz, ToneGen_ProcessRestore_ReadType
	bitda 7, 0x34cf
	jr z, ToneGen_ProcessRestore_JumpCalc
	anddi8 0x34d0, 223
	anddi8 0x34cf, 127

ToneGen_ProcessRestore_JumpCalc:
	jr ToneGen_ProcessRestore_CalcNote

ToneGen_ProcessRestore_ReadType:
	pushw wa
	calr AccVoice_ReadCurrentToneType
	ldb_d8 w, 0x34fc
	sub w, a
	jr nc, ToneGen_ProcessRestore_WrapOctave
	add w, 0x60

ToneGen_ProcessRestore_WrapOctave:
	ldb_d8 e, 0x34fc
	calr ToneGen_AdjustNoteWrap
	popw wa
	calr ToneGen_ClassifyAndDispatch

ToneGen_ProcessRestore_Return:
	ret

__pad_F618FF:
	nop
	nop

ToneGen_RestoreFromSavedPos:
	ldw_d16 xiy, 0x3512
	stda16 0x3449, xiy
	ldw_d16 xwa, 0x3514
	stda16 0x346b, xwa
	ldb a, 0x0
	stb_d8 0x3435, a
	anddi8 0x3522, 253
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ldw_d16 xwa, 0x3449
	ldb_sri A, 0x07, 0xec, 0xe0
	cp a, 0x81
	jr nz, ToneGen_EventDispatchLoop
	ordi8 0x3522, 2
	anddi8 0x3522, 251

ToneGen_EventDispatchLoop:
	calr ToneGen_StepVoiceForward
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ldw_d16 xwa, 0x3449
	ldb_sri A, 0x07, 0xec, 0xe0
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
	cp a, 0xd1
	jr z, ToneGen_CalcEventVelocity_WithFlags
	cp a, 0xd2
	jr z, ToneGen_CalcEventVelocity_WithFlags
	cp a, 0xd3
	jr z, ToneGen_CalcEventVelocity_WithFlags
	cp a, 0xd4
	jr z, ToneGen_CalcEventVelocity_WithFlags
	cp a, 0xd5
	jr z, ToneGen_CalcEventVelocity_WithFlags
	cp a, 0xd6
	jr z, ToneGen_CalcEventVelocity_WithFlags
	jr ToneGen_EventDispatchLoop

ToneGen_EventDisp_EndOfBlock:
	call AccPatch_GetCurrentSlotAddr
	calr ToneGen_GetSlotIndex
	stda16 0x346b, xhl
	calr ToneGen_CalcBufferAddr
	lds ix, 6
	stda16 0x3449, xix
	stdi8 0x3435, 6
	jr ToneGen_EventDispatchLoop

ToneGen_CalcEventVelocity_WithFlags:
	calr AccVoice_ReadCurrentToneType
	ld c, a
	ldb_d8 b, 0x34fb
	bitda 1, 0x3522
	jr z, ToneGen_Velocity_SkipDec
	dec 1, b
	cp b, 0xff
	jr nz, ToneGen_Velocity_SkipDec
	ldb_d8 b, 0x34d9
	dec 1, b
	ldb_d8 a, 0x34d9
	ldb_d8 w, 0x34fa
	dec 1, w
	cp w, 0xff
	jr nz, ToneGen_Velocity_Multiply
	ldb_d8 w, 0x34d7

ToneGen_Velocity_Multiply:
	muls8rr a, w
	add b, a
	jr ToneGen_Velocity_Store

ToneGen_Velocity_SkipDec:
	jr VoiceVelocity_CalcDone

ToneGen_Velocity_HandleEnd:
	bitda 7, 0x3522
	jr nz, VoiceVelocity_CalcDone
	bitda 2, 0x3522
	jr z, ToneGen_Velocity_DefaultCalc
	ordi8 0x3522, 2
	ordi8 0x3522, 128
	jrl ToneGen_EventDispatchLoop

ToneGen_Velocity_DefaultCalc:
	ldb c, 0x0
	ldb_d8 b, 0x34fb
	dec 1, b
	cp b, 0xff
	jr nz, VoiceVelocity_CalcDone
	ldb_d8 b, 0x34d9
	dec 1, b

VoiceVelocity_CalcDone:
	ldb_d8 a, 0x34d9
	ldb_d8 w, 0x34fa
	muls8rr a, w
	add b, a

ToneGen_Velocity_Store:
	stda16 0x3520, xbc
	ordi8 0x3522, 1
	ret

__pad_F61A1C:
	nop
	nop

ToneGen_CalcNotePosition:
	ldb_d8 a, 0x34fc
	ld e, a
	xor w, w
	ldb l, 0xc
	div8rr a, l
	ldb_d8 d, 0x34fb
	ld bc, wa
	ldb_d8 a, 0x34d9
	ldb_d8 w, 0x34fa
	muls8rr a, w
	add d, a
	ld wa, bc
	cps w, 0
	jr nz, ToneGen_CalcPos_SubOctave
	ldb w, 0xc

ToneGen_CalcPos_SubOctave:
	ld a, e
	sub a, w
	jr nc, ToneGen_CalcPos_Return
	add a, 0x60
	dec 1, d
	cp d, 0xff
	jr nz, ToneGen_CalcPos_Return
	ldb_d8 d, 0x34d9
	dec 1, d
	ordi8 0x3522, 8

ToneGen_CalcPos_Return:
	ld w, d
	ret

__pad_F61A62:
	nop
	nop

ToneGen_AdjustNoteWrap:
	ld a, e
	sub a, w
	jr c, ToneGen_AdjWrap_AddOctave
	stb_d8 0x34fc, a
	jr SustainLevel_SetExit

ToneGen_AdjWrap_AddOctave:
	add a, 0x60
	stb_d8 0x34fc, a
	ldb_d8 a, 0x34fb
	dec 1, a
	cp a, 0xff
	jr z, ToneGen_AdjWrap_WrapBar
	stb_d8 0x34fb, a
	jr SustainLevel_SetExit

ToneGen_AdjWrap_WrapBar:
	ldb_d8 a, 0x34d9
	dec 1, a
	stb_d8 0x34fb, a
	ldb_d8 a, 0x34fa
	dec 1, a
	cp a, 0xff
	jr z, ToneGen_AdjWrap_WrapMeasure
	stb_d8 0x34fa, a
	jr SustainLevel_SetExit

ToneGen_AdjWrap_WrapMeasure:
	ldb_d8 a, 0x34d7
	and a, 0x7
	stb_d8 0x34fa, a

SustainLevel_SetExit:
	ret

__pad_F61AAF:
	nop
	nop

ToneGen_ScanRestoredVoiceEvents:
	ldw_d16 xiy, 0x3512
	stda16 0x3449, xiy
	ldw_d16 xwa, 0x3514
	stda16 0x346b, xwa
	ldb a, 0x0
	stb_d8 0x3435, a

ToneGen_ScanRestored_Loop:
	calr ToneGen_StepToNextVoiceSlot
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ldw_d16 xwa, 0x3449
	ldb_sri A, 0x07, 0xec, 0xe0
	cp a, 0x81
	jrl z, ToneGen_ScanRestored_EndMarker
	cp a, 0x83
	jr z, ToneGen_ScanRestored_EndBlock
	cp a, 0x90
	jr z, ToneGen_CalcEventVelocity_Restored
	cp a, 0x91
	jr z, ToneGen_CalcEventVelocity_Restored
	cp a, 0xd1
	jr z, ToneGen_CalcEventVelocity_Restored
	cp a, 0xd2
	jr z, ToneGen_CalcEventVelocity_Restored
	cp a, 0xd3
	jr z, ToneGen_CalcEventVelocity_Restored
	cp a, 0xd4
	jr z, ToneGen_CalcEventVelocity_Restored
	cp a, 0xd5
	jr z, ToneGen_CalcEventVelocity_Restored
	cp a, 0xd6
	jr z, ToneGen_CalcEventVelocity_Restored
	jr ToneGen_ScanRestored_Loop

ToneGen_ScanRestored_EndBlock:
	call AccPatch_GetCurrentSlotAddr
	calr ToneGen_GetSlotIndex
	stda16 0x346b, xhl
	calr ToneGen_CalcBufferAddr
	lds ix, 6
	stda16 0x3449, xix
	stdi8 0x3435, 6
	jr ToneGen_ScanRestored_Loop

ToneGen_CalcEventVelocity_Restored:
	calr AccVoice_ReadCurrentToneType
	ld c, a
	ldb_d8 b, 0x34fb
	ldb_d8 a, 0x34d9
	ldb_d8 w, 0x34fa
	muls8rr a, w
	add b, a
	jr ToneGen_ScanRestored_Return

ToneGen_ScanRestored_EndMarker:
	ldb c, 0x0
	ldb_d8 b, 0x34fb
	inc 1, b
	ldb_d8 a, 0x34d9
	ldb_d8 w, 0x34fa
	muls8rr a, w
	add b, a

ToneGen_ScanRestored_Return:
	ret

__pad_F61B56:
	nop
	nop

ToneGen_GetSlotIndex:
	ldb_d8 a, 0x379b
	and a, 0x1f
	cps a, 0
	jr nz, ToneGen_GetSlot_Lookup
	or a, 0x10
	stb_d8 0x379b, a

ToneGen_GetSlot_Lookup:
	call MapBitFlagsToChannelOffset
	ld l, w
	xor h, h
	ldw_sri HL, 0x07, 0xf4, 0xec
	ret

__pad_F61B78:
	nop
	nop

ToneGen_CalcNoteWithWrap:
	ldb_d8 a, 0x34fc
	ld e, a
	xor w, w
	ldb l, 0xc
	div8rr a, l
	ld a, e
	sub a, w
	add a, 0xc
	ldb_d8 w, 0x34fb
	cp a, 0x60
	jr nz, ToneGen_CalcWrap_Store
	ldb a, 0x0
	inc 1, w

ToneGen_CalcWrap_Store:
	ld hl, wa
	ldb_d8 a, 0x34d9
	ldb_d8 w, 0x34fa
	muls8rr a, w
	add h, a
	ld wa, hl
	ret

__pad_F61BAB:
	nop
	nop

ToneGen_RecalcAndRestart:
	ldb_d8 a, 0x34fc
	ld e, a
	xor w, w
	ldb l, 0xc
	div8rr a, l
	ld a, e
	sub a, w
	add a, 0xc
	calr ToneGen_StoreNoteOrWrap
	stdi8 0x3712, 4
	stdi8 0x3717, 255
	ret

__pad_F61BCE:
	nop
	nop

ToneGen_StoreNoteOrWrap:
	cp a, 0x60
	jr z, ToneGen_AdvancePeriodWrap
	stb_d8 0x34fc, a
	jr PitchValidate_Exit

ToneGen_AdvancePeriodWrap:
	stdi8 0x34fc, 0
	ldb_d8 a, 0x34fb
	inc 1, a
	cpda8 a, 0x34d9
	jr z, ToneGen_PeriodWrap_NextBar
	stb_d8 0x34fb, a
	jr PitchValidate_Exit

ToneGen_PeriodWrap_NextBar:
	stdi8 0x34fb, 0
	ldb_d8 a, 0x34fa
	inc 1, a
	ldb_d8 w, 0x34d7
	and w, 0x7
	inc 1, w
	cp a, w
	jr z, ToneGen_PeriodWrap_ResetBar
	stb_d8 0x34fa, a
	jr PitchValidate_Exit

ToneGen_PeriodWrap_ResetBar:
	stdi8 0x34fa, 0

PitchValidate_Exit:
	ret

__pad_F61C16:
	nop
	nop

ToneGen_ClassifyAndDispatch:
	cp a, 0xd1
	jr z, ToneGen_ClassifyStereoType
	cp a, 0xd2
	jr z, ToneGen_ClassifyStereoType
	cp a, 0xd3
	jr z, ToneGen_ClassifyStereoType
	cp a, 0xd4
	jr z, ToneGen_ClassifyStereoType
	cp a, 0xd5
	jr z, ToneGen_ClassifyStereoType
	cp a, 0xd6
	jr z, ToneGen_ClassifyStereoType
	calr ToneGen_ClassifyMonoEvent
	jr ToneGen_Classify_Return

ToneGen_ClassifyStereoType:
	calr ToneGen_ClassifyStereoEvent

ToneGen_Classify_Return:
	ret

__pad_F61C3F:
	nop
	nop

ToneGen_ClassifyStereoEvent:
	ldb a, 0x5
	stb_d8 0x3712, a
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ldw_d16 xwa, 0x3449
	ldb_sri A, 0x07, 0xec, 0xe0
	ldb e, 0x1
	cp a, 0xd2
	jr z, ToneGen_ClassifyStereoSlot_Common
	ldb e, 0x2
	cp a, 0xd1
	jr z, ToneGen_ClassifyStereoSlot_Common
	ldb e, 0x3
	cp a, 0xd3
	jr z, ToneGen_ClassifyStereoSlot_Common
	ldb e, 0x4
	cp a, 0xd4
	jr z, ToneGen_ClassifyStereoSlot_Common
	ldb e, 0x5
	cp a, 0xd5
	jr z, ToneGen_ClassifyStereoSlot_Common
	ldb e, 0x6

ToneGen_ClassifyStereoSlot_Common:
	stb_d8 0x3720, e
	calr ToneGen_StepToNextStereoSlot
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ldw_d16 xwa, 0x3449
	ldb_sri A, 0x07, 0xec, 0xe0
	stb_d8 0x3721, a
	ret

__pad_F61C98:
	nop
	nop

ToneGen_ClassifyMonoEvent:
	ldb a, 0x4
	stb_d8 0x3712, a
	calr ToneGen_StepToNextStereoSlot
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ldw_d16 xwa, 0x3449
	ldb_sri A, 0x07, 0xec, 0xe0
	stb_d8 0x3718, a
	calr ToneGen_StepToNextVoiceSlot
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ldw_d16 xwa, 0x3449
	ldb_sri W, 0x07, 0xec, 0xe0
	stb_d8 0x3717, w
	ldb_d8 a, 0x3718
	ld de, wa
	ldb_d8 a, 0x379b
	and a, 0x1f
	cps a, 0
	jr nz, ToneGen_ClassifyMono_MapChannel
	or a, 0x10
	stb_d8 0x379b, a

ToneGen_ClassifyMono_MapChannel:
	ld l, a
	xor h, h
	ld xiy, ToneGen_VoiceSlotLookupTable_0x2
	ldb_sri A, 0x07, 0xf4, 0xec
	cpdi8 0x3518, 0
	jr z, ToneGen_ClassifyMono_WriteNew
	pushw de
	pushw wa
	ldb_d8 a, 0x3516
	pushw wa
	call RhythmBuf_WriteByte
	inc 2, xsp
	ldb_d8 a, 0x3517
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
	stb_d8 0x3516, a
	stb_d8 0x3517, e
	ldb a, 0x10
	stb_d8 0x3518, a
	bitda 4, 0x379b
	jr z, ToneGen_ClassifyMono_Return
	ldb_d8 a, 0x3718
	ldb_d8 w, 0xfbbe
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
	stb_d8 0x3718, a

ToneGen_ClassifyMono_Return:
	ret

__pad_F61D76:
	nop
	nop

AccPlayback_ReadEventLoop:
	anddi8 0x34d0, 127

AccPlayback_ReadEvt_CheckEmpty:
	call AccPatch_CheckEmpty
	cps wa, 0
	jr z, AccPlayback_ReadEvt_CheckBit7
	bitda 7, 0x34d0
	jr nz, AccPlayback_ReadEvt_CheckBit7
	call TempoRingBuf_ReadByteToA
	cp a, 0x90
	jr nz, AccPlayback_ReadEvt_Continue
	calr AccPlayback_ProcessNoteOnEvent

AccPlayback_ReadEvt_Continue:
	jr AccPlayback_ReadEvt_CheckEmpty

AccPlayback_ReadEvt_CheckBit7:
	bitda 7, 0x34d0
	jr z, ToneGenSetup_Done
	cpdi16 0x34d4, 0
	jr nz, AccPlayback_ReadEvt_HasEntries
	stdi8 0x7f42, 15
	stdi8 0xe3dc, 238
	stdi8 0xe3de, 64
	anddi8 0x34d0, 127
	ldb a, 0x8
	call MIDI_SendSysExCmd
	jr ToneGenSetup_Done

AccPlayback_ReadEvt_HasEntries:
	anddi8 0x34d0, 223
	calr ToneGen_CalcTempo
	bitda 4, 0x379b
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
	stdi8 0x3712, 4
	stdi8 0x3717, 255
	ldb_d8 a, 0x8d36
	cpda8 a, 0x8d38
	jr nz, ToneGenSetup_Done
	stdi8 0xe3e0, 16

ToneGenSetup_Done:
	ret

AccPlayback_ReadEvt_Return:
	nop
	nop

AccPlayback_ProcessNoteOnEvent:
	call TempoRingBuf_ReadByteToA
	call TempoRingBuf_ReadByteToA
	stb_d8 0x342d, a
	call TempoRingBuf_ReadByteToA
	stb_d8 0x342e, a
	call TempoRingBuf_ReadByteToA
	cpdi8 0x342e, 0
	jr nz, AccPlayback_NoteOn_ReadParams
	jr AccPlayback_NoteOn_WriteVoice

AccPlayback_NoteOn_ReadParams:
	ldb_d8 l, 0x34fd
	cps l, 5
	jr ugt, AccPlayback_NoteOn_Store
	xor h, h
	ld xiy, 0x3500
	ldb_d8 a, 0x342d
	lda_dri XBC, 0x07, 0xf4, 0xec
	ldb_d8 a, 0x342e
	pushw hl
	add hl, 0x6
	lda_dri XBC, 0x07, 0xf4, 0xec
	popw hl
	inc 1, l
	stb_d8 0x34fd, l
	cpda8 l, 0x34fe
	jr ule, AccPlayback_NoteOn_Store
	stb_d8 0x34fe, l

AccPlayback_NoteOn_Store:
	jr TimeoutCounter_CheckExit

AccPlayback_NoteOn_WriteVoice:
	ldb_d8 a, 0x34fd
	dec 1, a
	cp a, 0xff
	jr z, TimeoutCounter_CheckExit
	stb_d8 0x34fd, a
	cps a, 0
	jr nz, TimeoutCounter_CheckExit
	ordi8 0x34d0, 128

TimeoutCounter_CheckExit:
	ret

AccPlayback_NoteOn_SetBit:
	nop
	nop

AccPlayback_NoteOn_Check91:
	lds wa, 0
	stda16 0x360a, xwa
	ldb_d8 e, 0x34fe
	xor h, h
	ld xix, 0x3500
	ld xiy, 0x366a

AccPlayback_NoteOn_WritePan:
	cps e, 0
	jr z, AccPlayback_NoteOn_Return
	ld l, e
	dec 1, l
	adddi16 0x360a, 6
	ld (xiy), 0x90
	inc 1, xiy
	calr ToneGen_WriteVoiceEventEntry
	dec 1, e
	jr AccPlayback_NoteOn_WritePan

AccPlayback_NoteOn_Return:
	ret

__pad_F61EAF:
	nop
	nop

ToneGen_WriteVoiceEventEntry:
	ldb_d8 a, 0x34fc
	ld (xiy), a
	inc 1, xiy
	ldb_sri A, 0x07, 0xf0, 0xec
	ld (xiy), a
	inc 1, xiy
	pushw hl
	add hl, 0x6
	ldb_sri A, 0x07, 0xf0, 0xec
	ld (xiy), a
	popw hl
	inc 1, xiy
	ldb_d8 a, 0x342d
	ld (xiy), a
	inc 1, xiy
	ldb_d8 a, 0x342e
	ld (xiy), a
	inc 1, xiy
	ret

AccPlayback_AdvancePattern:
	nop
	nop

AccPlayback_AdvPattern_Loop:
	lds wa, 0
	stda16 0x360a, xwa
	ldb_d8 e, 0x34fe
	xor h, h
	ld xix, 0x3500
	ld xiy, 0x366a

AccPlayback_AdvPattern_Check81:
	cps e, 0
	jr z, AccPlayback_AdvPattern_Nop
	ld l, e
	dec 1, l
	calr AccPlayback_AdvanceRingBuffer
	bitda 0, 0x3431
	jr nz, AccPlayback_AdvPattern_Check90
	adddi16 0x360a, 6
	ld (xiy), 0x90
	inc 1, xiy
	calr ToneGen_WriteVoiceEventEntry
	jr AccPlayback_AdvPattern_Done

AccPlayback_AdvPattern_Check90:
	adddi16 0x360a, 8
	ld (xiy), 0x91
	inc 1, xiy
	calr ToneGen_WriteVoiceEventEntry
	ldb_d8 a, 0x3432
	ld (xiy), a
	inc 1, xiy
	ldb_d8 a, 0x3433
	ld (xiy), a
	inc 1, xiy

AccPlayback_AdvPattern_Done:
	dec 1, e
	jr AccPlayback_AdvPattern_Check81

AccPlayback_AdvPattern_Nop:
	ret

__pad_F61F3E:
	nop
	nop

AccPlayback_AdvanceRingBuffer:
	ldb_d8 a, 0x34e9
	and a, 0xf
	cps a, 0
	jr z, AccPlayback_TrackPosition
	call AccPatch_ReadTransposeAmount
	cpda8 a, 0x3a4e
	jr ugt, __pad_F61F65
	sub_srib_mr A, 0x07, 0xf0, 0xec
	jr nc, AccPlayback_AdvRingBuf_Return
	ldb a, 0xc
	add_srib_mr A, 0x07, 0xf0, 0xec

AccPlayback_AdvRingBuf_Return:
	jr AccPlayback_TrackPosition

__pad_F61F65:
	ldb w, 0xc
	sub w, a
	add_srib_mr W, 0x07, 0xf0, 0xec

AccPlayback_TrackPosition:
	ldb_sri A, 0x07, 0xf0, 0xec
	push xix
	xor w, w
	ld xix, Display_FontPalette_Table_0x12EA
	ldb_sri A, 0x07, 0xf0, 0xe0
	pop xix
	bitda 4, 0x34ea
	jr z, __pad_F61FAC
	ld c, a
	push xix
	xor w, w
	ld xix, __pad_F62002_0x2
	ldb_sri A, 0x07, 0xf0, 0xe0
	pop xix
	bit 0, a
	jr z, AccPlayback_TrackPos_Return
	inc 1, c
	ldb_sri A, 0x07, 0xf0, 0xec
	inc 1, a
	lda_dri XBC, 0x07, 0xf0, 0xec

AccPlayback_TrackPos_Return:
	ld a, c

__pad_F61FAC:
	bitda 6, 0x34ea
	jr z, AccPlayback_TrackPos_WrapCheck
	bitda 3, 0x379b
	jr z, AccPlayback_TrackPos_WrapCheck
	jr AccPlayback_TrackPos_WrapDone

AccPlayback_TrackPos_WrapCheck:
	bitda 5, 0x34ea
	jr z, ToneGen_LoadRhythmPatternParams
	bitda 3, 0x379b
	jr nz, ToneGen_LoadRhythmPatternParams

AccPlayback_TrackPos_WrapDone:
	cps a, 7
	jr nz, ToneGen_LoadRhythmPatternParams
	stdi8 0x3431, 1
	stdi8 0x3432, 3
	stdi8 0x3433, 0
	jr AccPlayback_StyleRecalc_Return

ToneGen_LoadRhythmPatternParams:
	xor xbc, xbc
	ld c, a
	sla a, 1
	add c, a
	push xix
	ld xix, __pad_F62002_0xE
	add xix, xbc
	ld a, (xix)
	stb_d8 0x3431, a
	ld a, (xix + 1)
	stb_d8 0x3432, a
	ld a, (xix + 2)
	stb_d8 0x3433, a
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
	andmi8 (xiy + 15), 0x7f
	calr ToneGen_ProcessVoiceSlots
	ldw_d16 xwa, 0x346b
	stda16 0x3602, xwa
	xor w, w
	ldb_d8 a, 0x3435
	stda16 0x3604, xwa
	stda16 0x3445, xwa
	ldw_d16 xwa, 0x3602
	stda16 0x3447, xwa
	ldw_d16 xwa, 0x360a
	stda16 0x344b, xwa
	call AccPatch_InitSlotAndCopyData
	calr ToneGen_AdvanceSeqList
	stdi8 0x34fe, 0
	bitda 0, 0x3283
	jr nz, ToneGen_NullRet
	cpdi8 0x34fa, 0
	jr nz, ToneGen_NullRet
	cpdi8 0x34fb, 0
	jr nz, ToneGen_NullRet
	cpdi8 0x34fc, 48
	jr ugt, ToneGen_NullRet
	ordi8 0x34cd, 128

ToneGen_NullRet:
	ret

AccPlayback_Ongoing_HandleType:
	nop
	nop

ToneGen_ProcessVoiceSlots:
	calr AccPlayback_Ongoing_AdvSlot
	calr ToneGen_GetSlotIndex
	stda16 0x346b, xhl
	calr ToneGen_CalcBufferAddr
	stdi16 0x3449, 6
	ldb_d8 a, 0x34fa
	ldb_d8 w, 0x34d9
	muls8rr a, w
	ld d, a
	ldb_d8 a, 0x34fb
	add d, a
	ldb_d8 e, 0x34fc
	anddi8 0x32f4, 254
	xor bc, bc
	stdi8 0x3435, 6

AccPlayback_Ongoing_NoteOff:
	bitda 0, 0x32f4
	jr z, AccPlayback_Ongoing_NoteOffDone
	jrl AccPlayback_Ongoing_Return

AccPlayback_Ongoing_NoteOffDone:
	ldw_d16 xiy, 0x3449
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ldb_sri A, 0x07, 0xec, 0xf4
	cp a, 0x81
	jr nz, AccPlayback_Ongoing_D2Type
	add b, 0x1
	xor c, c
	cp de, bc
	jr c, AccPlayback_Ongoing_D1Type
	calr ToneGen_StepToNextVoiceSlot
	jr AccPlayback_Ongoing_D1_Return

AccPlayback_Ongoing_D1Type:
	ordi8 0x32f4, 1

AccPlayback_Ongoing_D1_Return:
	jr AccPlayback_Ongoing_NoteOff

AccPlayback_Ongoing_D2Type:
	calr AccVoice_ReadCurrentToneType
	ld c, a
	cp de, bc
	jr ule, AccPlayback_Ongoing_StoreDone
	calr __pad_F621A7
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ldb_sri A, 0x07, 0xec, 0xf4
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
	cp a, 0xd1
	jr z, ToneGen_StepToNextStereoVoicePair
	cp a, 0xd2
	jr z, ToneGen_StepToNextStereoVoicePair
	cp a, 0xd3
	jr z, ToneGen_StepToNextStereoVoicePair
	cp a, 0xd4
	jr z, ToneGen_StepToNextStereoVoicePair
	cp a, 0xd5
	jr z, ToneGen_StepToNextStereoVoicePair
	cp a, 0xd6
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
	ordi8 0x32f4, 1

ToneGen_StepVoiceReturn:
	jrl AccPlayback_Ongoing_NoteOff

AccPlayback_Ongoing_Return:
	ret

__pad_F62169:
	nop
	nop

AccPlayback_Ongoing_AdvSlot:
	ldw_d16 xwa, 0x3608
	dec 1, a
	stb_d8 0x351c, a
	ld e, a
	ldw_d16 xwa, 0x3606
	stda16 0x351a, xwa
	ld hl, wa
	calr ToneGen_CalcBufferAddr
	ldb_d8 a, 0x351c
	xor w, w
	stda16 0x351e, xwa
	ldb_d8 a, 0x34d7
	inc 1, a
	ldb_d8 w, 0x34d9
	muls8rr a, w
	dec 1, a
	ld b, a
	xor c, c
	stda16 0x3520, xbc
	ret

AccPlayback_Ongoing_AdvDone:
	nop
	nop

__pad_F621A7:
	ldw_d16 xwa, 0x346b
	stda16 0x351a, xwa
	ldb_d8 a, 0x3435
	stb_d8 0x351c, a
	ldw_d16 xwa, 0x3449
	stda16 0x351e, xwa
	stda16 0x3520, xbc
	ret

AccPlayback_UpdateVoiceState:
	nop
	nop

ToneGen_AdvanceSeqList:
	calr ToneGen_InitPlaybackState
	ldda32 xhl, 0x3548
	ld wa, (xhl)
	cpda16 xwa, 0x3447
	jr z, AccPlayback_VoiceState_NoChange
	ldw_d16 xde, 0x3441
	calr ToneGen_SearchVoiceBuffer
	jr AccPlayback_VoiceState_Changed

AccPlayback_VoiceState_NoChange:
	ldw_d16 xde, 0x3441
	cpda16 xde, 0x3445
	jr c, AccPlayback_VoiceState_Changed
	ordi8 0x34d0, 64

AccPlayback_VoiceState_Changed:
	bitda 6, 0x34d0
	jr z, AccPlayback_VoiceState_Return
	ldw_d16 xwa, 0x344b
	add de, wa
	cp de, 0xff
	jr nc, AccPlayback_VoiceState_CalcOff
	ldw_d16 xix, 0x3441
	ldw_d16 xwa, 0x344b
	add ix, wa
	ldda32 xhl, 0x354c
	ld (xhl), ix
	jr AccPlayback_VoiceState_Return

AccPlayback_VoiceState_CalcOff:
	ldw_d16 xhl, 0x3534
	calr ToneGen_CalcBufferAddr
	ld hl, (xhl + 3)
	ldda32 xix, 0x3548
	ld (xix), hl
	lds ix, 6
	sub de, 0xff
	add ix, de
	ldda32 xhl, 0x354c
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
	.byte 0x9d
	ldw	de, 0
	.byte 0x9f
	ldw	de, 0
	nop
	nop
	nop
	nop
	.byte 0xa1
	ldw	de, 0
	nop
	nop
	.zero 8
	nop
	nop
	.byte 0x9b
	ldw	de, 0
	nop
	nop
	.zero 24
	nop
	nop
	.byte 0x97
	ldw	de, 0
	nop
	nop
	nop
	nop
	.byte 0x8d
	ldw	de, 0
	.byte 0x8f
	ldw	de, 0
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
	.byte 0x87
	ldw	de, 0

ToneGen_SearchVoiceBuffer:
	call AccPatch_GetCurrentSlotAddr
	ldb_d8 a, 0x379b
	and a, 0x1f
	cps a, 0
	jr nz, ToneGen_SearchBuf_MapChannel
	or a, 0x10
	stb_d8 0x379b, a

ToneGen_SearchBuf_MapChannel:
	call MapBitFlagsToChannelOffset
	ld l, w
	xor h, h
	ldw_sri WA, 0x07, 0xf4, 0xec

ToneGen_SearchBuf_CompareLoop:
	cpda16 xwa, 0x3447
	jr nz, ToneGen_SearchBuf_CheckEnd
	ordi8 0x34d0, 64
	jr ToneGen_SearchBuf_Return

ToneGen_SearchBuf_CheckEnd:
	cpda16 xwa, 0x3534
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
	nop
	nop

AccPlayback_ProcessBit5Change:
	bitda 5, 0x3713
	jr nz, AccBit5_CheckBit5Active
	jrl AccBit5_Return

AccBit5_CheckBit5Active:
	bitda 5, 0x34d0
	jr nz, AccBit5_InitAndScan
	jrl FlagClear_Exit

AccBit5_InitAndScan:
	anddi8 0x34d0, 223
	anddi8 0x34cf, 127
	ldw_d16 xwa, 0x3514
	stda16 0x346b, xwa
	stda16 0x365a, xwa
	stda16 0x3530, xwa
	ldw_d16 xiy, 0x3512
	stda16 0x344b, xiy
	stda16 0x3449, xiy
	stda16 0x3660, xiy
	ld wa, iy
	stb_d8 0x3435, a
	ldw_d16 xiy, 0x3512
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ldb_sri A, 0x07, 0xec, 0xf4
	cp a, 0x81
	jrl z, FlagClear_Exit
	stdi8 0x344d, 6
	cp a, 0x90
	jr z, AccBit5_StepTwice
	stdi8 0x344d, 8
	cp a, 0x91
	jr z, AccBit5_StepOnce
	stdi8 0x344d, 3
	cp a, 0xd1
	jr z, AccVoice_InitPlaybackState
	cp a, 0xd2
	jr z, AccVoice_InitPlaybackState
	cp a, 0xd3
	jr z, AccVoice_InitPlaybackState
	cp a, 0xd4
	jr z, AccVoice_InitPlaybackState
	cp a, 0xd5
	jr z, AccVoice_InitPlaybackState
	cp a, 0xd6
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
	ldw_d16 xwa, 0x346b
	stda16 0x3658, xwa
	stda16 0x3532, xwa
	xor w, w
	ldb_d8 a, 0x3435
	stda16 0x365e, xwa
	calr ToneGen_ScanVoicePosition
	call AccPatch_CopySequenceEntry
	call AccPatch_GetCurrentSlotAddr
	calr AccVoice_InitPatternBuffer
	stdi8 0x3712, 4
	stdi8 0x3717, 255
	stdi8 0xe3e0, 16

FlagClear_Exit:
	anddi8 0x3713, 223

AccBit5_Return:
	ret

__pad_F623D8:
	nop
	nop

ToneGen_ScanVoicePosition:
	calr ToneGen_InitPlaybackState
	call AccPatch_GetCurrentSlotAddr
	calr ToneGen_GetSlotIndex
	ld de, hl
	calr ToneGen_CalcBufferAddr
	ldb c, 0x3
	lds iy, 3
	stdi8 0x3523, 0

ToneGen_ScanPos_CompareLoop:
	cpda16 xiy, 0x344b
	jr nz, ToneGen_ScanPos_CheckEnd
	cpda16 xde, 0x3530
	jr nz, ToneGen_ScanPos_CheckEnd
	ordi8 0x3523, 1
	jr VoiceState_CheckExit

ToneGen_ScanPos_CheckEnd:
	cpda16 xiy, 0x3449
	jr nz, VoiceState_CheckExit
	cpda16 xde, 0x3532
	jr nz, VoiceState_CheckExit
	ordi8 0x3523, 2

VoiceState_CheckExit:
	cpda16 xiy, 0x3441
	jr nz, ToneGen_ScanPos_AdvanceStep
	cpda16 xde, 0x3534
	jr nz, ToneGen_ScanPos_AdvanceStep
	jr ToneGen_ScanPos_ProcessFlags

ToneGen_ScanPos_AdvanceStep:
	calr ToneGen_AdvanceVoiceStep
	jr ToneGen_ScanPos_CompareLoop

ToneGen_ScanPos_ProcessFlags:
	ldb_d8 a, 0x3523
	and a, 0x3
	cps a, 0
	jr z, PlaybackState_InitDone
	bitda 1, 0x3523
	jr nz, ToneGen_ScanPos_AdjustBit1
	ldw_d16 xiy, 0x344b
	ldda32 xix, 0x354c
	ld (xix), iy
	ldda32 xix, 0x3548
	ld (xix), de
	stb_d8 0x3435, c
	jr PlaybackState_InitDone

ToneGen_ScanPos_AdjustBit1:
	ldw_d16 xiy, 0x344d
	and iy, 0xff
	ld wa, iy
	sub c, a
	jr c, ToneGen_ScanPos_WrapBlock
	cps c, 6
	jr c, ToneGen_ScanPos_WrapBlock
	stb_d8 0x3435, c
	ldda32 xix, 0x354c
	ld wa, (xix)
	sub wa, iy
	ld (xix), wa
	ldda32 xix, 0x3548
	ld (xix), de
	jr PlaybackState_InitDone

ToneGen_ScanPos_WrapBlock:
	sub c, 0x7
	stb_d8 0x3435, c
	ld hl, de
	calr ToneGen_CalcBufferAddr
	ld wa, (xhl + 1)
	ldda32 xix, 0x3548
	ld (xix), wa
	xor w, w
	ld a, c
	ldda32 xix, 0x354c
	ld (xix), iy

PlaybackState_InitDone:
	ret

__pad_F62498:
	nop
	nop

ToneGen_InitPlaybackState:
	anddi8 0x34d0, 191
	ldb_d8 a, 0x379b
	and a, 0x1f
	cps a, 0
	jr nz, ToneGen_InitPlay_SetupTables
	or a, 0x10
	stb_d8 0x379b, a

ToneGen_InitPlay_SetupTables:
	sla a, 2
	ld l, a
	xor h, h
	ld xix, __pad_F62230_0x2
	ld_sril3 XIX, 0x07, 0xf0, 0xec
	stda32 0x3548, xix
	ld xix, __pad_F62230_0x46
	ld_sril3 XIX, 0x07, 0xf0, 0xec
	stda32 0x354c, xix
	ld hl, (xix)
	stda16 0x3441, xhl
	ldda32 xix, 0x3548
	ld hl, (xix)
	stda16 0x3534, xhl
	ret

__pad_F624E5:
	nop
	nop

ToneGen_AdvanceVoiceStep:
	inc 1, iy
	inc 1, c
	cp c, 0xff
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
	nop
	nop

AccPlayback_ProcessTempoAdvance:
	bitda 2, 0x3713
	jr z, AccPlayback_TempoAdv_Return
	anddi8 0x34d0, 223
	calr ToneGen_CalcTempo
	calr ToneGen_AdvanceByTempo
	calr AccPlayback_CalcTimingPosition
	call AccPatch_GetCurrentSlotAddr
	calr AccVoice_InitPatternBuffer
	stdi8 0x3712, 4
	stdi8 0x3717, 255
	stdi8 0xe3e0, 16
	anddi8 0x3713, 251

AccPlayback_TempoAdv_Return:
	ret

__pad_F62534:
	nop
	nop

ToneGen_CalcTempo:
	ldb_d8 l, 0x3714
	cps l, 0
	jr nz, ToneGen_CalcTempo_Lookup
	ldb l, 0x6

ToneGen_CalcTempo_Lookup:
	sla l, 1
	xor h, h
	push xix
	ld xix, ToneGen_CalcTempo_DataTable_0x2
	ldw_sri DE, 0x07, 0xf0, 0xec
	ldb_d8 l, 0x3715
	sla l, 1
	ldw_sri BC, 0x07, 0xf0, 0xec
	add de, bc
	pop xix
	ld wa, de
	ldb l, 0x60
	div8rr a, l
	stb_d8 0x342f, w
	stb_d8 0x3430, a
	ldb_d8 a, 0x3716
	cps a, 1
	jr nz, ToneGen_CalcTempo_Mode0
	sla de, 2
	ld wa, de
	xor de, de
	lds hl, 5
	ldw_erp DE, 0xe2
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
	ldw_erp DE, 0xe2
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
	stb_d8 0x342d, w
	stb_d8 0x342e, a
	ordi8 0x34cf, 128
	ret

ToneGen_CalcTempo_DataTable:
	.byte 0x00, 0x00, 0x00, 0x00, 0x08, 0x00, 0x0c, 0x00
	.byte 0x10, 0x00, 0x18, 0x00, 0x20, 0x00, 0x30, 0x00
	.byte 0x40, 0x00, 0x60, 0x00, 0xc0, 0x00, 0x80, 0x01
	.byte 0x00, 0x03, 0x80, 0x04, 0x00, 0x06

ToneGen_AdvanceByTempo:
	ldb_d8 a, 0x342f
	ldb_d8 w, 0x3430
	addda8 a, 0x34fc
	cp a, 0x60
	jr c, ToneGen_AdvTempo_StoreNote
	sub a, 0x60
	inc 1, w

ToneGen_AdvTempo_StoreNote:
	stb_d8 0x34fc, a
	addda8 w, 0x34fb
	ldb_d8 l, 0x34d9
	ldb_d8 h, 0x34d7
	and h, 0x7
	inc 1, h

ToneGen_AdvTempo_WrapLoop:
	cp w, l
	jr c, ToneGen_AdvTempo_StoreBeat
	sub w, l
	incdi8 1, 0x34fa
	cpda8 h, 0x34fa
	jr nz, ToneGen_AdvTempo_Continue
	stdi8 0x34fa, 0

ToneGen_AdvTempo_Continue:
	jr ToneGen_AdvTempo_WrapLoop

ToneGen_AdvTempo_StoreBeat:
	stb_d8 0x34fb, w
	ret

__pad_F62627:
	nop
	nop

AccPlayback_UpdateRhythmSustain:
	ldb_d8 a, 0x3518
	cps a, 0
	jr z, AccPlayback_RhythmSust_Return
	dec 1, a
	stb_d8 0x3518, a
	cps a, 0
	jr nz, AccPlayback_RhythmSust_Return
	ldb_d8 a, 0x3516
	ldb_d8 e, 0x3517
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
	nop
	nop

AccPlayback_ProcessVoiceType5:
	bitda 5, 0x34d0
	jr z, AccVoice_DispatchType5Handler
	cpdi8 0x3712, 4
	jr nz, AccVoice_DispatchType5Handler
	ldb_d8 a, 0x372d
	and a, 0xc
	cps a, 0
	jr z, AccVoiceType5_CheckBit01
	calr ToneGen_AdjustVoiceVelocity

AccVoiceType5_CheckBit01:
	ldb_d8 a, 0x372d
	and a, 0x3
	cps a, 0
	jr z, AccVoice_DispatchType5Handler
	calr ToneGen_AdjustVolumePan

AccVoice_DispatchType5Handler:
	bitda 5, 0x34d0
	jr z, TempoCheck_Exit
	cpdi8 0x3712, 5
	jr nz, TempoCheck_Exit
	ldb_d8 a, 0x372d
	and a, 0x30
	cps a, 0
	jr z, TempoCheck_Exit
	calr ToneGen_ProcessStereoType

TempoCheck_Exit:
	ret

__pad_F626A6:
	nop
	nop

ToneGen_AdjustVoiceVelocity:
	ldw_d16 xwa, 0x3512
	stda16 0x3449, xwa
	ldw_d16 xwa, 0x3514
	stda16 0x346b, xwa
	stdi8 0x3435, 0
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ldw_d16 xwa, 0x3449
	ldb_sri A, 0x07, 0xec, 0xe0
	cp a, 0x81
	jrl z, ToneGen_AdjVel_Return
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ldw_d16 xwa, 0x3449
	ldb_sri A, 0x07, 0xec, 0xe0
	bitda 4, 0x379b
	jr z, ToneGen_AdjVel_CheckBit2
	ldb_d8 w, 0xfbbe
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
	bitda 2, 0x372d
	jr z, ToneGen_AdjVel_Decrement
	inc 1, a
	cp a, 0x80
	jr c, ToneGen_AdjVel_ClampHigh
	ldb a, 0x7f

ToneGen_AdjVel_ClampHigh:
	jr ToneGen_AdjVel_StoreAndParam

ToneGen_AdjVel_Decrement:
	dec 1, a
	cp a, 0xff
	jr nz, ToneGen_AdjVel_StoreAndParam
	ldb a, 0x0

ToneGen_AdjVel_StoreAndParam:
	ld e, a
	bitda 4, 0x379b
	jr z, ToneGen_AdjVel_WriteToBuffer
	ldb_d8 w, 0xfbbe
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
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	pushw ix
	ldw_d16 xix, 0x3449
	lda_dri XBC, 0x07, 0xec, 0xf0
	stb_d8 0x3718, e
	popw ix
	push xde
	call AccScreen_DrawInit_StackWrap
	pop xde
	ldb_d8 a, 0x379b
	and a, 0xf
	cps a, 0
	jr z, ToneGen_AdjVel_Return
	calr ToneGen_WriteMultiChanParam

ToneGen_AdjVel_Return:
	ret

__pad_F62776:
	nop
	nop

ToneGen_AdjustVolumePan:
	ldw_d16 xwa, 0x3512
	stda16 0x3449, xwa
	ldw_d16 xwa, 0x3514
	stda16 0x346b, xwa
	stdi8 0x3435, 0
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ldw_d16 xwa, 0x3449
	ldb_sri A, 0x07, 0xec, 0xe0
	cp a, 0x81
	jr z, ToneGen_AdjVol_Return
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ldw_d16 xwa, 0x3449
	ldb_sri A, 0x07, 0xec, 0xe0
	bitda 0, 0x372d
	jr z, ToneGen_AdjVol_Decrement
	inc 1, a
	cp a, 0x80
	jr c, ToneGen_AdjVol_ClampHigh
	ldb a, 0x7f

ToneGen_AdjVol_ClampHigh:
	jr ToneGen_AdjVol_WriteToBuffer

ToneGen_AdjVol_Decrement:
	dec 1, a
	cps a, 0
	jr z, ToneGen_AdjVol_ClampLow
	cp a, 0xff
	jr nz, ToneGen_AdjVol_WriteToBuffer

ToneGen_AdjVol_ClampLow:
	ldb a, 0x1

ToneGen_AdjVol_WriteToBuffer:
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	pushw ix
	ldw_d16 xix, 0x3449
	lda_dri XBC, 0x07, 0xec, 0xf0
	stb_d8 0x3717, a
	popw ix
	call AccScreen_UpdateBeat_StackWrap

ToneGen_AdjVol_Return:
	ret

__pad_F627F4:
	nop
	nop

ToneGen_ProcessStereoType:
	ldw_d16 xwa, 0x3512
	stda16 0x3449, xwa
	ldw_d16 xwa, 0x3514
	stda16 0x346b, xwa
	stdi8 0x3435, 0
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ldw_d16 xwa, 0x3449
	ldb_sri A, 0x07, 0xec, 0xe0
	cp a, 0x81
	jr z, ToneGen_Stereo_Return
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ldw_d16 xwa, 0x3449
	ldb_sri C, 0x07, 0xec, 0xe0
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ldw_d16 xwa, 0x3449
	ldb_sri A, 0x07, 0xec, 0xe0
	cp c, 0xd3
	jr z, ToneGen_Stereo_ClampLow
	bitda 4, 0x372d
	jr z, ToneGen_Stereo_Increment
	inc 1, a
	cp a, 0x80
	jr c, ToneGen_Stereo_CheckInc
	ldb a, 0x7f

ToneGen_Stereo_CheckInc:
	jr ToneGen_Stereo_Decrement

ToneGen_Stereo_Increment:
	dec 1, a
	cp a, 0xff
	jr nz, ToneGen_Stereo_Decrement
	ldb a, 0x0

ToneGen_Stereo_Decrement:
	jr ToneGen_Stereo_WriteParam

ToneGen_Stereo_ClampLow:
	bitda 4, 0x372d
	jr z, ToneGen_Stereo_Store
	ldb a, 0x7f
	jr ToneGen_Stereo_WriteParam

ToneGen_Stereo_Store:
	ldb a, 0x0

ToneGen_Stereo_WriteParam:
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	pushw ix
	ldw_d16 xix, 0x3449
	lda_dri XBC, 0x07, 0xec, 0xf0
	stb_d8 0x3721, a
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
	push	sr
	.byte 0x53, 0x54
	.ascii "UVWX_`aR"
	pop	sr
	.ascii "bcdefghPiQj'(*,.$%& "
	.byte 0x1f
	pushw	bc
	.byte 0x21
	.ascii "+\"-#/0123456789:=>"
	jp	0x1e1d1c
	.byte 0x41, 0x42
	.ascii "CDEkl"
	pop_f
	.byte 0x1a
	ld	xiz, 0x114b4c18
	ccf
	zcf
	push_a
	pop_a
	ex_ff
	ldf	77
	popw	iz
	popw	sp
	incf
	decf
	ret
	retd	2576
	pushw	0x4709
	reti
	ldio	59, 60
	ld	xwa, 0x4906053f
	.byte 0x04
	.ascii "JHmnopqrstuvwxyz{|}~"
	jrl	nc, 14
	nop
	.ascii "b_]^XYZ[\\NOPQRSTKHI=>?@('*,.$%&"
	.byte 0x1f
	.ascii " )!+\"-#/0123456789:cd;<feABCDEJ`likMLUVW"
	jp	0x09121d
	ldwio	11, 3340
	ret
	.byte 0x01
	push	sr
	pop	sr
	.byte 0x04
	halt
	reti
	retd	4368
	push_a
	pop_a
	ex_ff
	ldf	24
	pop_f
	.byte 0x1a, 0x1c, 0x1e
	.ascii "FGmnopqrstuvwxyz{|}~"
	.byte 0x7f

ToneGen_WriteMultiChanParam:
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ldw_d16 xiy, 0x3512
	ldb_sri D, 0x07, 0xec, 0xf4
	xor h, h
	ld l, e
	push xix
	ld xix, Display_FontPalette_Table_0x12EA
	ldb_sri A, 0x07, 0xf0, 0xec
	pop xix
	ldb e, 0x90
	bitda 6, 0x34ea
	jr z, ToneGen_MultiChan_Compare
	bitda 3, 0x379b
	jr z, ToneGen_MultiChan_Compare
	jr ToneGen_MultiChan_AdjustVel

ToneGen_MultiChan_Compare:
	bitda 5, 0x34ea
	jr z, AccVoice_ResolveNoteOnOffType
	bitda 3, 0x379b
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
	ld xix, __pad_F62002_0xE
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
	nop
	nop

ToneGen_CompareVoiceBlocks:
	calr __pad_F62A0D
	calr __pad_F62AAC
	calr __pad_F62B29
	calr ToneGen_StepWithBoundsCheck
	ret

ToneGen_MultiChan_Return:
	nop
	nop

__pad_F62A0D:
	ldw_d16 xwa, 0x3512
	stda16 0x3449, xwa
	ldw_d16 xwa, 0x3514
	stda16 0x346b, xwa
	stdi8 0x3435, 0
	ldw_d16 xiy, 0x3449
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ldb_sri A, 0x07, 0xec, 0xf4
	stb_d8 0x3436, a
	calr ToneGen_StepToNextVoiceSlot
	ldw_d16 xiy, 0x3449
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ldb_sri A, 0x07, 0xec, 0xf4
	stb_d8 0x3437, a
	calr ToneGen_StepToNextVoiceSlot
	ldw_d16 xiy, 0x3449
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ldb_sri A, 0x07, 0xec, 0xf4
	stb_d8 0x3438, a
	calr ToneGen_StepToNextVoiceSlot
	ldw_d16 xiy, 0x3449
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ldb_sri A, 0x07, 0xec, 0xf4
	stb_d8 0x3439, a
	calr ToneGen_StepToNextVoiceSlot
	ldw_d16 xiy, 0x3449
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ldb_sri A, 0x07, 0xec, 0xf4
	stb_d8 0x343a, a
	calr ToneGen_StepToNextVoiceSlot
	ldw_d16 xiy, 0x3449
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ldb_sri A, 0x07, 0xec, 0xf4
	stb_d8 0x343b, a
	ret

ToneGen_VoiceParamDisp_Return:
	nop
	nop

__pad_F62AAC:
	ldw_d16 xwa, 0x3514
	stda16 0x346b, xwa
	stda16 0x365a, xwa
	stda16 0x3530, xwa
	ldw_d16 xiy, 0x3512
	stda16 0x344b, xiy
	stda16 0x3449, xiy
	stda16 0x3660, xiy
	ld wa, iy
	stb_d8 0x3435, a
	stdi8 0x344d, 6
	ldw_d16 xiy, 0x3512
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ldb_sri A, 0x07, 0xec, 0xf4
	cp a, 0x90
	jr z, ToneGen_CalcBeatSubdivision
	stdi8 0x344d, 8
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot

ToneGen_CalcBeatSubdivision:
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot
	ldw_d16 xwa, 0x346b
	stda16 0x3658, xwa
	stda16 0x3532, xwa
	xor w, w
	ldb_d8 a, 0x3435
	stda16 0x365e, xwa
	calr ToneGen_ScanVoicePosition
	call AccPatch_CopySequenceEntry
	ret

ToneGen_CalcBeat_Return:
	nop
	nop

__pad_F62B29:
	ld xiy, 0x366a
	ldb_d8 a, 0x3436
	ld (xiy), a
	ldb_d8 a, 0x3437
	ld (xiy + 1), a
	ldb_d8 a, 0x3438
	ld (xiy + 2), a
	ldb_d8 a, 0x3439
	ld (xiy + 3), a
	ldb_d8 a, 0x343a
	ld (xiy + 4), a
	ldb_d8 a, 0x343b
	ld (xiy + 5), a
	ldb_d8 a, 0x3438
	xor h, h
	ld l, a
	push xix
	ld xix, Display_FontPalette_Table_0x12EA
	ldb_sri A, 0x07, 0xf0, 0xec
	pop xix
	bitda 6, 0x34ea
	jr z, ToneGen_ReadBufferUtility
	bitda 3, 0x379b
	jr z, ToneGen_ReadBufferUtility
	jr ToneGen_ReadBufUtil_Loop

ToneGen_ReadBufferUtility:
	bitda 5, 0x34ea
	jr z, AccVoice_WriteNoteEventToBuffer
	bitda 3, 0x379b
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
	ld xix, __pad_F62002_0xE
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
	nop
	nop

ToneGen_StepWithBoundsCheck:
	cpdi16 0x34d4, 0
	jr z, ToneGen_SeqAdvanceMain
	ld xiy, 0x366a
	ld a, (xiy)
	stdi16 0x360a, 6
	cp a, 0x90
	jr z, ToneGen_StepBounds_Return
	stdi16 0x360a, 8

ToneGen_StepBounds_Return:
	ldw_d16 xwa, 0x3514
	stda16 0x346b, xwa
	ldw_d16 xiy, 0x3512
	ld wa, iy
	stb_d8 0x3435, a
	ldw_d16 xwa, 0x346b
	stda16 0x3602, xwa
	xor w, w
	ldb_d8 a, 0x3435
	stda16 0x3604, xwa
	ldw_d16 xwa, 0x3604
	stda16 0x3445, xwa
	ldw_d16 xwa, 0x3602
	stda16 0x3447, xwa
	ldw_d16 xwa, 0x360a
	stda16 0x344b, xwa
	call AccPatch_InitSlotAndCopyData
	calr ToneGen_AdvanceSeqList
	jr ToneGen_SeqAdv_Return

ToneGen_SeqAdvanceMain:
	stdi8 0x7f42, 15
	stdi8 0xe3dc, 238
	stdi8 0xe3de, 64
	ldb a, 0x8
	call MIDI_SendSysExCmd

ToneGen_SeqAdv_Return:
	ret

__pad_F62C3E:
	nop
	nop

AccVoice_ReadCurrentToneType:
	push xiy
	push xhl
	xor xiy, xiy
	ldw_d16 xiy, 0x3449
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	add xhl, xiy
	ld a, (xhl + 1)
	cp a, 0x87
	jr nz, ToneGen_InterpolateParam
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ld hl, (xhl + 3)
	calr ToneGen_CalcBufferAddr
	ld a, (xhl + 6)

ToneGen_InterpolateParam:
	pop xhl
	pop xiy
	ret

ToneGen_Interp_Loop:
	nop
	nop

ToneGen_StepToNextVoiceSlot:
	push xiy
	push xhl
	ldw_d16 xiy, 0x3449
	inc 1, iy
	incdi8 1, 0x3435
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ldb_sri A, 0x07, 0xec, 0xf4
	cp a, 0x87
	jr z, ToneGen_Interp_StoreResult
	cp a, 0x83
	jr nz, ToneGen_Interp_WrapPoint
	jr ToneGen_Interp_CheckExit

ToneGen_Interp_StoreResult:
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ld hl, (xhl + 3)
	stda16 0x346b, xhl
	calr ToneGen_CalcBufferAddr
	lds iy, 6
	stdi8 0x3435, 6
	jr ToneGen_Interp_WrapPoint

ToneGen_Interp_CheckExit:
	call AccPatch_GetCurrentSlotAddr
	calr ToneGen_GetSlotIndex
	stda16 0x346b, xhl
	calr ToneGen_CalcBufferAddr
	lds iy, 6
	stdi8 0x3435, 6

ToneGen_Interp_WrapPoint:
	stda16 0x3449, xiy
	pop xhl
	pop xiy
	ret

ToneGen_Interp_Done:
	nop
	nop

ToneGen_StepToNextStereoSlot:
	push xiy
	push xhl
	ldw_d16 xiy, 0x3449
	inc 1, iy
	incdi8 1, 0x3435
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ldb_sri A, 0x07, 0xec, 0xf4
	cp a, 0x87
	jr nz, ToneGen_Interp_Return
	calr ToneGen_StepToNextBuffer

ToneGen_Interp_Return:
	inc 1, iy
	incdi8 1, 0x3435
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ldb_sri A, 0x07, 0xec, 0xf4
	cp a, 0x87
	jr nz, ToneGen_Interp_OverflowCheck
	calr ToneGen_StepToNextBuffer

ToneGen_Interp_OverflowCheck:
	stda16 0x3449, xiy
	pop xhl
	pop xiy
	ret

ToneGen_Interp_OverflowDone:
	nop
	nop

ToneGen_StepToNextBuffer:
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	xor iy, iy
	ld hl, (xhl + 3)
	stda16 0x346b, xhl
	calr ToneGen_CalcBufferAddr
	lds iy, 6
	stdi8 0x3435, 6
	ret

ToneGen_AdvanceBeatCounter:
	nop
	nop
	inc	1, iy
	cp	iy, bc
	jr	ule, 3
	.byte 0x9b
	nop
	ldb	e, 14
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
	nop
	nop

ToneGen_StepVoiceForward:
	push xiy
	push xhl
	ldw_d16 xiy, 0x3449
	dec 1, iy
	decdi8 1, 0x3435
	ldw_d16 xhl, 0x346b
	calr ToneGen_CalcBufferAddr
	ldb_sri A, 0x07, 0xec, 0xf4
	cp a, 0x87
	jr nz, ToneGen_StepFwd_WrapDone
	ld hl, (xhl + 1)
	cp hl, 0xffff
	jr z, ToneGen_StepFwd_CheckWrap
	stda16 0x346b, xhl
	calr ToneGen_CalcBufferAddr
	ldw iy, 0xfe
	stdi8 0x3435, 254
	jr ToneGen_StepFwd_WrapDone

ToneGen_StepFwd_CheckWrap:
	ldw_d16 xhl, 0x3606
	stda16 0x346b, xhl
	calr ToneGen_CalcBufferAddr
	ldw_d16 xhl, 0x3608
	dec 1, hl
	ld iy, hl
	stb_d8 0x3435, l

ToneGen_StepFwd_WrapDone:
	stda16 0x3449, xiy
	pop xhl
	pop xiy
	ret

ToneGen_StepFwd_Exit:
	nop
	nop

ToneGen_StepFwd_Alternate:
	ldb_d8 e, 0x371a
	ldb_d8 d, 0x3747
	ldb_d8 c, 0x3746
	ldb_d8 b, 0x34d7
	cpdi8 0x34d9, 4
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
	stb_d8 0x3746, c
	xor d, d
	stda16 0x3747, xde
	calr AccPlayback_DetectMeasurePos
	ret

ToneGen_StepAlt_Done:
	nop
	nop

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
	nop
	nop

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
	nop
	nop

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
	nop
	nop

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
	nop
	nop

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
	nop
	nop

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
	nop
	nop

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
	nop
	nop

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
	nop
	nop

AccPlayback_DetectMeasurePos:
	ld a, c
	inc 1, a
	cpdi8 0x34d9, 4
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
	stb_d8 0x3746, c
	jr RhythmChannel_NullRet

AccPlayback_MeasPos_SetUpper:
	ld c, e
	sub c, 0x3
	dec 1, c
	stb_d8 0x3746, c
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
	stb_d8 0x3746, c
	jr RhythmChannel_NullRet

AccPlayback_MeasPos_SmallUpper:
	ld c, e
	sub c, 0x1
	dec 1, c
	stb_d8 0x3746, c

RhythmChannel_NullRet:
	ret

__pad_F62F32:
	nop
	nop

AccPlayback_InitPartAssignment:
	xor wa, wa
	stda16 0x373e, xwa
	stda16 0x3740, xwa
	stda16 0x3742, xwa
	stda16 0x3744, xwa
	jr AccPlayback_PartAssign_Check4
	ldb_d8 a, 0x34d9
	cps a, 4
	jr ule, AccPlayback_PartAssign_Store
	cpdi8 0x34fb, 4
	jr nc, AccPlayback_PartAssign_Sub4
	ldb a, 0x4
	jr AccPlayback_PartAssign_Store

AccPlayback_PartAssign_Sub4:
	sub a, 0x4

AccPlayback_PartAssign_Store:
	stb_d8 0x373e, a
	jrl RhythmFunc_NullRet

AccPlayback_PartAssign_Check4:
	cpdi8 0x34d9, 4
	jrl ugt, AccPlayback_PartAssign_LargeBeat
	cpdi8 0x34d7, 2
	jr ugt, AccPlayback_PartAssign_LargeMeasure
	cpdi8 0x3746, 0
	jr z, AccPlayback_PartAssign_SmallPart
	jrl RhythmFunc_NullRet

AccPlayback_PartAssign_SmallPart:
	ldb_d8 a, 0x34d9
	stb_d8 0x373e, a
	stdi8 0x3742, 1
	cpdi8 0x34d7, 1
	jr c, AccPlayback_PartAssign_Check2
	stb_d8 0x373f, a
	stdi8 0x3743, 2

AccPlayback_PartAssign_Check2:
	cpdi8 0x34d7, 2
	jr c, AccPlayback_PartAssign_Check3
	stb_d8 0x3740, a
	stdi8 0x3744, 3

AccPlayback_PartAssign_Check3:
	jrl RhythmFunc_NullRet

AccPlayback_PartAssign_LargeMeasure:
	ldb_d8 a, 0x34d7
	subda8 a, 0x3746
	cps a, 2
	jr gt, AccPlayback_PartAssign_FullSetup
	jrl RhythmFunc_NullRet

AccPlayback_PartAssign_FullSetup:
	ldb_d8 a, 0x34d9
	stb_d8 0x373e, a
	stb_d8 0x373f, a
	stb_d8 0x3740, a
	stb_d8 0x3741, a
	ldb_d8 a, 0x3746
	inc 1, a
	stb_d8 0x3742, a
	inc 1, a
	stb_d8 0x3743, a
	inc 1, a
	stb_d8 0x3744, a
	inc 1, a
	stb_d8 0x3745, a
	jr RhythmFunc_NullRet

AccPlayback_PartAssign_LargeBeat:
	cpdi8 0x34d7, 0
	jr nz, AccPlayback_PartAssign_LargeBeat2
	cpdi8 0x3746, 0
	jr nz, RhythmFunc_NullRet
	stdi8 0x373e, 4
	ldb_d8 a, 0x34d9
	sub a, 0x4
	stb_d8 0x373f, a
	stdi8 0x3742, 1
	jr RhythmFunc_NullRet

AccPlayback_PartAssign_LargeBeat2:
	ldb_d8 a, 0x34d7
	subda8 a, 0x3746
	cps a, 0
	jr le, RhythmFunc_NullRet
	stdi8 0x373e, 4
	ldb_d8 a, 0x34d9
	sub a, 0x4
	stb_d8 0x373f, a
	stdi8 0x3740, 4
	stb_d8 0x3741, a
	ldb_d8 a, 0x3746
	inc 1, a
	stb_d8 0x3742, a
	inc 1, a
	stb_d8 0x3744, a

RhythmFunc_NullRet:
	ret

AccPlayback_PartAssign_DataBlock:
	nop
	nop
	cpdi8	0x8d38, 182
	jr	z, 2
	jr	60
	ldb_d8	a, 0x370f
	ldw	ix, 480
	calr	53
	ldb_d8	a, 0x371a
	ldw	ix, 6962
	calr	43
	ldb_d8	a, 0x3718
	ldw	ix, 6967
	calr	33
	ldb_d8	a, 0x3717
	ldw	ix, 6972
	calr	23
	ldb_d8	a, 0x3714
	ldw	ix, 6977
	calr	13
	ldb_d8	a, 0x3715
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
	nop
	.ascii "0123456789ABCDEF"
	ret

AccPat_ShiftAndMask:
	pushw hl
	and hl, 0xfff
	sla hl, 4
	popw hl
	ret

__pad_F630DE:
	nop
	nop

AccPat_IndexToAddress:
	and xhl, 0xffff
	sla xhl, 8
	add xhl, 0x95c00
	ret

AccPat_InlineFunctions_DataBlock:
	nop
	nop
	and	xhl, 0xffff
	sla	xhl, 8
	add	xhl, 0x095c00
	ret
	push	xwa
	push	xix
	ld	wa, hl
	and	xhl, 4095
	sla	xhl, 8
	and	wa, 0xf000
	srl	wa, 10
	ld	xix, AccPat_InlineFunctions_DataBlock_0x35
	.byte 0xe3
	reti
	.byte 0xf0, 0xe0
	ldb	d, 236
	.byte 0x83
	pop	xix
	pop	xwa
	ret
	nop
	pop	xix
	push	0
	nop
	pop	xix
	push	0
	nop
	pop	xix
	push	0
	nop
	pop	xix
	push	0
	nop
	pop	xix
	push	0
	nop
	pop	xix
	push	0
	nop
	pop	xix
	push	0
	nop
	pop	xix
	push	0
	nop
	pop	xix
	push	0
	push	xiz
	calr	2
	pop	xiz
	ret

AccPat_DispatchNoteChange:
	bitda 0, 0x34d1
	jr nz, AccPat_Dispatch_AllocAndProcess
	jp AccPat_Dispatch_Return

AccPat_Dispatch_AllocAndProcess:
	ld xwa, 0x800
	push xwa
	call Malloc
	add xsp, 0x4
	stda32 0x3564, xhl
	ldb_d8 a, 0x34ed
	ldb_d8 w, 0x34ee
	pushw wa
	anddi8 0x34d1, 254
	anddi8 0x35b0, 254
	ldb_d8 a, 0x34ed
	cp a, 0x80
	jr c, AccPat_Dispatch_LowRange
	cp a, 0xa0
	jrl nc, AccPat_CleanupAndFree
	cpdi8 0x34ef, 26
	jr nz, AccPat_Dispatch_CalcAccent
	calr AccWidget_ProcessSpecialCmd
	jrl AccPat_CleanupAndFree

AccPat_Dispatch_CalcAccent:
	calr AccPat_CalcAccentVelocity
	ldb_d8 a, 0x34ed
	and a, 0x7f
	cpda8 a, 0x34d6
	jr z, AccPat_CleanupAndFree
	cp a, 0x1e
	jr nc, AccPat_CleanupAndFree
	ordi8 0x34cd, 128
	call AccPat_InitWorkAreaFromSlot
	ldb_d8 a, 0x34ed
	and a, 0x7f
	stb_d8 0x39ac, a
	ldb_d8 a, 0x34d6
	stb_d8 0x39ad, a
	push xix
	ld xix, 0x94800
	stda32 0x39ae, xix
	stda32 0x39b2, xix
	pop xix
	calr AccPatch_LoadDualVoiceParams
	jr AccPat_Dispatch_CheckBit0

AccPat_Dispatch_LowRange:
	ordi8 0x34cd, 128
	cpdi8 0x34ef, 26
	jr nz, AccPat_Dispatch_InitWorkArea
	calr RhythmROM_LoadDrumKit
	jr AccPat_CleanupAndFree

AccPat_Dispatch_InitWorkArea:
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher

AccPat_Dispatch_CheckBit0:
	bitda 0, 0x35b0
	jr nz, AccPat_Dispatch_InitSlot
	cpdi8 0x8d36, 184
	jr nz, AccPat_CleanupAndFree
	stdi8 0x7f42, 20
	call DrumVoice_NotifyEE
	jr AccPat_CleanupAndFree

AccPat_Dispatch_InitSlot:
	call AccPatch_InitCurrentSlot
	stdi8 0x7f42, 23
	call DrumVoice_NotifyEE
	ldb a, 0x8
	call MIDI_SendSysExCmd

AccPat_CleanupAndFree:
	popw wa
	stb_d8 0x34ed, a
	stb_d8 0x34ee, w
	ldda32 xwa, 0x3564
	push xwa
	call Free
	add xsp, 0x4

AccPat_Dispatch_Return:
	ret

__pad_F6323D:
	nop
	nop

DualVoice_ParamLoadDone:
	push xiz
	calr AccPatch_LoadDualVoiceParams
	pop xiz
	ret

AccPatch_LoadDualVoiceParams:
	ldb_d8 l, 0x39ac
	cp l, 0x1e
	jr c, AccPat_DualVoice_ClampIndex
	xor l, l

AccPat_DualVoice_ClampIndex:
	sla l, 2
	xor h, h
	ld xix, RhythmTiming_OffsetTable
	ld_sril3 XIY, 0x07, 0xf0, 0xec
	addda32 xiy, 0x39ae
	add xiy, 0x60
	stda32 0x355c, xiy
	ldb_d8 l, 0x39ad
	cp l, 0x1e
	jr c, AccPat_DualVoice_ClampIndex2
	xor l, l

AccPat_DualVoice_ClampIndex2:
	sla l, 2
	xor h, h
	ld xix, RhythmTiming_OffsetTable
	ld_sril3 XIY, 0x07, 0xf0, 0xec
	addda32 xiy, 0x39b2
	add xiy, 0x60
	stda32 0x3560, xiy
	ldda32 xiy, 0x355c
	add xiy, 0xc
	ldda32 xix, 0x3560
	add xix, 0xc
	ldw bc, 0x54
	ldir85
	calr AccPat_DualVoice_ReadParamsA
	calr AccPatch_LoadDualVoiceParamsB
	calr AccPat_DualVoice_CopyAllBanks
	ret

AccPat_DualVoice_DataBlock:
	nop
	nop
	ldb_d8	l, 0x34ed
	and	l, 127
	cp	l, 30
	jr	c, 2
	xor	l, l
	sla	l, 2
	xor	h, h
	ld	xix, RhythmTiming_OffsetTable
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	e, 237
	.byte 0xc8
	nop
	popw	wa
	push	0
	add	xiy, 96
	stda32	0x355c, xiy
	ldb_d8	l, 0x34d6
	cp	l, 30
	jr	c, 2
	xor	l, l
	sla	l, 2
	xor	h, h
	.byte 0x44
	.long RhythmTiming_OffsetTable
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	e, 237
	.byte 0xc8
	nop
	popw	wa
	push	0
	add	xiy, 96
	.byte 0xf1
	jr	f, 53
	jr	mi, 0x0e

AccPat_DualVoice_ReadParamsA:
	ldda32 xiy, 0x355c
	ld hl, (xiy + 256)
	stda16 0x35a4, xhl
	ld hl, (xiy + 4)
	stda16 0x35a6, xhl
	ld hl, (xiy + 6)
	stda16 0x35a8, xhl
	ld hl, (xiy + 8)
	stda16 0x35aa, xhl
	ld hl, (xiy + 10)
	stda16 0x35ac, xhl
	ret

__pad_F6333A:
	nop
	nop

AccPatch_LoadDualVoiceParamsB:
	ldda32 xiy, 0x3560
	ld hl, (xiy + 256)
	stda16 0x3598, xhl
	ld hl, (xiy + 4)
	stda16 0x359a, xhl
	ld hl, (xiy + 6)
	stda16 0x359c, xhl
	ld hl, (xiy + 8)
	stda16 0x359e, xhl
	ld hl, (xiy + 10)
	stda16 0x35a0, xhl
	ret

__pad_F63364:
	nop
	nop

AccPat_DualVoice_CopyAllBanks:
	ldw_d16 xiy, 0x35a4
	ldw_d16 xix, 0x3598
	calr ToneBank_CopyEntry
	ldw_d16 xiy, 0x35a6
	ldw_d16 xix, 0x359a
	calr ToneBank_CopyEntry
	ldw_d16 xiy, 0x35a8
	ldw_d16 xix, 0x359c
	calr ToneBank_CopyEntry
	ldw_d16 xiy, 0x35aa
	ldw_d16 xix, 0x359e
	calr ToneBank_CopyEntry
	ldw_d16 xiy, 0x35ac
	ldw_d16 xix, 0x35a0
	calr ToneBank_CopyEntry
	ret

__pad_F6339E:
	nop
	nop

ToneBank_CopyEntry:
	stda16 0x3596, xix
	stda16 0x35a2, xiy
	ld hl, iy
	ldda32 xwa, 0x39ae
	calr ToneBank_ComputeEntryAddress
	ld wa, (xhl + 3)
	stda16 0x35ae, xwa
	ldw_d16 xhl, 0x3596
	ldda32 xwa, 0x39b2
	calr ToneBank_ComputeEntryAddress
	ld xix, xhl
	ldw_d16 xhl, 0x35a2
	ldda32 xwa, 0x39ae
	calr ToneBank_ComputeEntryAddress
	ld xiy, xhl
	add xiy, 0x6
	add xix, 0x6
	ldw bc, 0xf9
	ldir85

__pad_F633E3:
	cpdi16 0x35ae, 0xffff
	jrl z, ToneBank_CopyComplete_Return
	calr ToneBank_CopyChunk_Return
	bitda 0, 0x35b0
	jr nz, ToneBank_CopyComplete_Return
	decdi16 1, 0x34d4
	ld hl, de
	ldda32 xwa, 0x39b2
	calr ToneBank_ComputeEntryAddress
	ormi8 (xhl), 0x80
	ldw_d16 xhl, 0x3596
	ldda32 xwa, 0x39b2
	calr ToneBank_ComputeEntryAddress
	ld (xhl + 3), de
	ld hl, de
	ldda32 xwa, 0x39b2
	calr ToneBank_ComputeEntryAddress
	ldw_d16 xwa, 0x3596
	ld (xhl + 1), wa
	stda16 0x3596, xde
	ldw_d16 xwa, 0x35ae
	stda16 0x35a2, xwa
	ld hl, wa
	ldda32 xwa, 0x39ae
	calr ToneBank_ComputeEntryAddress
	ld wa, (xhl + 3)
	stda16 0x35ae, xwa
	calr AccPat_ShiftAndMask
	ldw_d16 xhl, 0x3596
	ldda32 xwa, 0x39b2
	calr ToneBank_ComputeEntryAddress
	ld xix, xhl
	ldw_d16 xhl, 0x35a2
	ldda32 xwa, 0x39ae
	calr ToneBank_ComputeEntryAddress
	ld xiy, xhl
	add xiy, 0x6
	add xix, 0x6
	ldw bc, 0xf9
	ldir85
	jrl __pad_F633E3

ToneBank_CopyComplete_Return:
	ldw_d16 xhl, 0x3596
	ldda32 xwa, 0x39b2
	calr ToneBank_ComputeEntryAddress
	ldw wa, 0xffff
	ld (xhl + 3), wa
	ret

ToneBank_CopyChunk:
	nop

ToneBank_ComputeEntryAddress:
	and xhl, 0xfff
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
	ldda32 xwa, 0x39b2
	calr ToneBank_ComputeEntryAddress
	bitm 7, (xhl)
	jr z, ToneBank_ComputeAddr_Return
	inc 1, de
	jr __pad_F63498

ToneBank_ComputeAddr_CheckRange:
	ordi8 0x35b0, 1

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
	ordi8 0x35b0, 1

ToneBank_SwapCopy_Pad:
	ret

__pad_F634D1:
	nop
	nop
	ldw	de, 150
	cp	de, 340
	jr	nc, 13
	ld	hl, de
	calr	64529
	.byte 0xb3
	inc	6, l
	push	218
	jr	lt, 104
	and	xbc, xiy
	lda	xiy, (xwa)
	push	xiz
	.byte 0x01
	or	de, 0x8000
	ret

RhythmROM_PatternDispatcher:
	anddi8 0x35b0, 249
	ldb_d8 l, 0x34ed
	ldb_d8 h, 0x34ee
	call VoiceParam_ClampAndValidate_Tramp
	stb_d8 0x34ed, l
	stb_d8 0x34ee, h
	sla l, 1
	sla hl, 1
	ld xiy, Display_FontPalette_Table_0x2EA
	ldw_sri WA, 0x07, 0xf4, 0xec
	stda16 0x355a, xwa
	add hl, 0x2
	ldw_sri WA, 0x07, 0xf4, 0xec
	stda16 0x355c, xwa
	ldb_d8 l, 0x34d6
	cp l, 0x1e
	jr c, AccPat_CalcAccentVelocity_Body
	xor l, l

AccPat_CalcAccentVelocity_Body:
	sla l, 2
	xor h, h
	ld xix, RhythmTiming_OffsetTable
	ld_sril3 XIY, 0x07, 0xf0, 0xec
	add xiy, 0x94800
	add xiy, 0x60
	stda32 0x3560, xiy
	calr RhythmROM_LoadPattern
	cpdi8 0x34ef, 0
	jr z, RhythmROM_LoadAndInit
	cpdi8 0x34ef, 1
	jr z, RhythmROM_LoadAndInit
	cpdi8 0x34ef, 2
	jr z, RhythmROM_LoadAndInit
	cpdi8 0x34ef, 3
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
	nop
	nop

RhythmROM_LoadPattern:
	ldw_d16 xwa, 0x355a
	ld w, a
	calr RhythmROM_CalcPatternAddr
	xor xiy, xiy
	ldw_d16 xiy, 0x355c
	add xiy, xix
	ldda32 xix, 0x3564
	ldw bc, 0x400
	ldirw
	ldb_d8 l, 0x34ef
	and l, 0xf
	xor h, h
	sla hl, 1
	ld xix, RhythmROM_LoadPattern_0x34
	xor xwa, xwa
	ldw_sri WA, 0x07, 0xf0, 0xec
	jr RhythmROM_PatternDisp_ReadByte
	xorda16_24 xde, 0x03d803
	reti
RhythmROM_PatternDisp_InitLoop:
	neg	wa
	.byte 0xd3
	pop	sr
	.byte 0xd3
	reti
	.byte 0xd3
	pop	sr
	.byte 0xd3
	reti
	.byte 0xd2
	pop	sr
	.byte 0xd2
	pop	sr
	ld	wa, 984
	xordm16_24	0x07d207, wa
	reti
	neg	wa

RhythmROM_PatternDisp_ReadByte:
	ldda32 xiy, 0x3564
	add xiy, xwa
	ld a, (xiy)
	stb_d8 0x35b1, a
	ldda32 xiy, 0x3564
	ldda32 xix, 0x3560
	add xix, 0xc
	ldb_sri0 A, (xiy + 0x03d0)
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
	ldb_d8 a, 0x34ed
	ld (xix), a
	inc 1, xix
	ldb_d8 a, 0x34ee
	ld (xix), a
	inc 1, xix
	ldb_d8 l, 0x34ef
	and l, 0xf
	xor h, h
	sla hl, 1
	ld xix, RhythmROM_PatternDisp_CheckCmd
	xor xwa, xwa
	ldw_sri WA, 0x07, 0xf0, 0xec
	jr RhythmROM_PatternDisp_Handle90

RhythmROM_PatternDisp_CheckCmd:
	popw	wa
	push	sr
	jrl	ge, 18434
	.byte 0x06
	jrl	ge, 28166
	pop	sr
	jr	nz, 7
	.byte 0x9f
	pop	sr
	.byte 0x9f
	reti
	incf
	pop	sr
	incf
	pop	sr
	push	xiy
	pop	sr
	push	xiy
	pop	sr
	incf
	reti
	incf
	reti
	push	xiy
	reti
	push	xiy
	reti

RhythmROM_PatternDisp_Handle90:
	ldda32 xiy, 0x3564
	add xiy, xwa
	ldda32 xix, 0x3560
	add xix, 0x18
	ldb a, 0x5

RhythmROM_PatternDisp_Check91:
	lds bc, 7
	ldir85
	inc 1, xix
	dec 1, a
	cps a, 0
	jr nz, RhythmROM_PatternDisp_Check91
	ldda32 xix, 0x3560
	ld xiy, 0x22
	add xiy, xix
	ld (xiy), 0x40
	ld xiy, 0x2a
	add xiy, xix
	ld (xiy), 0xc
	ld xiy, 0x32
	add xiy, xix
	ld (xiy), 0x74
	ld xiy, 0x3a
	add xiy, xix
	ld (xiy), 0x40
	ldb_d8 a, 0x34ed
	stb_d8 0x90ea, a
	ldb_d8 a, 0x34ee
	stb_d8 0x90eb, a
	call Rhythm_DispatchNote_Finalize
	ldb_d8 h, 0x90ef
	ldb_d8 l, 0x90ee
	call AccVoice_DispatchEntry
	ld xiy, 0x34ab
	ldda32 xix, 0x3560
	add xix, 0x40
	ldw bc, 0x10
	ldir85
	ret

RhythmROM_PatternDisp_Handle91:
	nop
	nop

RhythmROM_CalcPatternAddr:
	and xwa, 0xff00
	sla xwa, 8
	ld xix, 0x400000
	addda32 xix, 0x3277
	add xix, xwa
	ret

RhythmROM_PatternDisp_Return:
	nop
	nop

__pad_F636FB:
	ldda32 xhl, 0x3564
	add xhl, 0x118
	calr RhythmROM_CountEntries
	stb_d8 0x35b3, e
	ldb_d8 a, 0x34ef
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
	ldda32 xhl, 0x3560
	xor wa, wa
	ld a, (xhl + 12)
	ld xhl, __pad_F63EC6_0x2
	ldb_sri L, 0x07, 0xec, 0xe0
	ldb a, 0x7
	cpda8 l, 0x35b3
	jr nz, RhythmVoice_WriteParam_Return
	ordi8 0x35b0, 2
	ldb a, 0x3

RhythmVoice_WriteParam_Return:
	jp RhythmROM_NullRet

__pad_F63748:
	ldda32 xhl, 0x3564
	add xhl, 0x138
	cps a, 4
	jr z, RhythmROM_ProcessPattern
	ldda32 xhl, 0x3564
	add xhl, 0x13c
	cps a, 6
	jr z, RhythmROM_ProcessPattern
	ldda32 xhl, 0x3564
	add xhl, 0x538
	cps a, 5
	jr z, RhythmROM_ProcessPattern
	ldda32 xhl, 0x3564
	add xhl, 0x53c
	cps a, 7
	jr z, RhythmROM_ProcessPattern
	jr RhythmVoice_SetupChannels

RhythmROM_ProcessPattern:
	calr RhythmROM_CountEntries
	ldda32 xhl, 0x3560
	xor wa, wa
	ld a, (xhl + 12)
	ld xhl, __pad_F63EC6_0x2
	ldb_sri A, 0x07, 0xec, 0xe0
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
	cp a, 0xa
	jr z, RhythmROM_ReturnZero
	cp a, 0xb
	jr z, RhythmROM_ReturnZero
	cp a, 0xc
	jr z, RhythmROM_ReturnZero
	cp a, 0xd
	jr z, RhythmROM_ReturnZero
	cp a, 0xe
	jr z, RhythmROM_ReturnZero
	cp a, 0xf
	jr z, RhythmROM_ReturnZero
	jr RhythmROM_NullRet

RhythmROM_ReturnZero:
	xor a, a

RhythmROM_NullRet:
	ret

RhythmVoice_SetupChan_Finalize:
	nop
	nop

RhythmROM_CountEntries:
	push xhl
	ldda32 xhl, 0x3564
	add xhl, 0x3d1
	ld w, (xhl)
	pop xhl
	calr RhythmROM_CalcPatternAddr
	ld hl, (xhl)
	and xhl, 0xffff
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
	ldda32 xix, 0x3564
	ldda32 xiy, 0x3564
	cpdi8 0x34ef, 0
	jr nz, DrumKit_DataTable_Entry1
	add xix, 0x0
	add xiy, 0x118

DrumKit_DataTable_Entry1:
	cpdi8 0x34ef, 1
	jr nz, DrumKit_DataTable_Entry2
	add xix, 0xf
	add xiy, 0x118

DrumKit_DataTable_Entry2:
	cpdi8 0x34ef, 2
	jr nz, DrumKit_DataTable_Entry3
	add xix, 0x400
	add xiy, 0x518

DrumKit_DataTable_Entry3:
	cpdi8 0x34ef, 3
	jr nz, DrumKit_DataTable_Entry4
	add xix, 0x40f
	add xiy, 0x518

DrumKit_DataTable_Entry4:
	lds32 xhl, 0
	bitda 0, 0x35b1
	jr nz, DrumKit_DataTable_Entry5
	ld xhl, 0x26

DrumKit_DataTable_Entry5:
	add xhl, xiy
	ld a, (xix + 256)
	calr ToneData_LookupEffectParam
	stb_d8 0x358c, a
	stda16 0x356a, xhl
	ld xhl, 0x4c
	add xhl, xiy
	ld a, (xix + 40)
	calr ToneData_LookupEffectParam
	stb_d8 0x358d, a
	stda16 0x356c, xhl
	ld xhl, 0x72
	add xhl, xiy
	ld a, (xix + 80)
	calr ToneData_LookupEffectParam
	stb_d8 0x358e, a
	stda16 0x356e, xhl
	ld xhl, 0x98
	add xhl, xiy
	ld a, (xix + 120)
	calr ToneData_LookupEffectParam
	stb_d8 0x358f, a
	stda16 0x3570, xhl
	ld xhl, 0xbe
	add xhl, xiy
	ldb_sri0 A, (xix + 0x00a0)
	calr ToneData_LookupEffectParam
	stb_d8 0x3590, a
	stda16 0x3572, xhl
	lds32 xhl, 0
	bitda 0, 0x35b1
	jr nz, DrumKit_DataTable_Entry6
	ld xhl, 0x26

DrumKit_DataTable_Entry6:
	add xhl, xiy
	ld a, (xix + 1)
	calr ToneData_LookupEffectParam
	stb_d8 0x3591, a
	stda16 0x3574, xhl
	ld xhl, 0x4c
	add xhl, xiy
	ld a, (xix + 41)
	calr ToneData_LookupEffectParam
	stb_d8 0x3592, a
	stda16 0x3576, xhl
	ld xhl, 0x72
	add xhl, xiy
	ld a, (xix + 81)
	calr ToneData_LookupEffectParam
	stb_d8 0x3593, a
	stda16 0x3578, xhl
	ld xhl, 0x98
	add xhl, xiy
	ld a, (xix + 121)
	calr ToneData_LookupEffectParam
	stb_d8 0x3594, a
	stda16 0x357a, xhl
	ld xhl, 0xbe
	add xhl, xiy
	ldb_sri0 A, (xix + 0x00a1)
	calr ToneData_LookupEffectParam
	stb_d8 0x3595, a
	stda16 0x357c, xhl
	lds32 xhl, 0
	bitda 0, 0x35b1
	jr nz, DrumKit_DataTable_Entry7
	ld xhl, 0x26

DrumKit_DataTable_Entry7:
	add xhl, xiy
	ld a, (xix + 2)
	calr ToneData_LookupEffectParam
	stb_d8 0x35c0, a
	stda16 0x35b6, xhl
	ld xhl, 0x4c
	add xhl, xiy
	ld a, (xix + 42)
	calr ToneData_LookupEffectParam
	stb_d8 0x35c1, a
	stda16 0x35b8, xhl
	ld xhl, 0x72
	add xhl, xiy
	ld a, (xix + 82)
	calr ToneData_LookupEffectParam
	stb_d8 0x35c2, a
	stda16 0x35ba, xhl
	ld xhl, 0x98
	add xhl, xiy
	ld a, (xix + 122)
	calr ToneData_LookupEffectParam
	stb_d8 0x35c3, a
	stda16 0x35bc, xhl
	ld xhl, 0xbe
	add xhl, xiy
	ldb_sri0 A, (xix + 0x00a2)
	calr ToneData_LookupEffectParam
	stb_d8 0x35c4, a
	stda16 0x35be, xhl
	lds32 xhl, 0
	bitda 0, 0x35b1
	jr nz, DrumKit_DataTable_Entry8
	ld xhl, 0x26

DrumKit_DataTable_Entry8:
	add xhl, xiy
	ld a, (xix + 3)
	calr ToneData_LookupEffectParam
	stb_d8 0x35d0, a
	stda16 0x35c6, xhl
	ld xhl, 0x4c
	add xhl, xiy
	ld a, (xix + 43)
	calr ToneData_LookupEffectParam
	stb_d8 0x35d1, a
	stda16 0x35c8, xhl
	ld xhl, 0x72
	add xhl, xiy
	ld a, (xix + 83)
	calr ToneData_LookupEffectParam
	stb_d8 0x35d2, a
	stda16 0x35ca, xhl
	ld xhl, 0x98
	add xhl, xiy
	ld a, (xix + 123)
	calr ToneData_LookupEffectParam
	stb_d8 0x35d3, a
	stda16 0x35cc, xhl
	ld xhl, 0xbe
	add xhl, xiy
	ldb_sri0 A, (xix + 0x00a3)
	calr ToneData_LookupEffectParam
	stb_d8 0x35d4, a
	stda16 0x35ce, xhl
	ret

RhythmROM_LoadKit_InitLDA:
	nop
	nop

ToneData_LookupEffectParam:
	sla a, 1
	xor w, w
	ldw_sri HL, 0x07, 0xec, 0xe0
	push xix
	ldda32 xix, 0x3564
	add xix, 0x3d1
	ld a, (xix)
	pop xix
	ret

RhythmROM_LoadKit_Return:
	nop
	nop

__pad_F63A6C:
	ldda32 xix, 0x3564
	add xix, 0x3d1
	ld a, (xix)
	stb_d8 0x358c, a
	stb_d8 0x358d, a
	stb_d8 0x358e, a
	stb_d8 0x358f, a
	stb_d8 0x3590, a
	calr __pad_F63AE7
	ldda32 xiy, 0x3564
	xor xhl, xhl
	ldw_d16 xhl, 0x35b4
	add xiy, xhl
	lds32 xhl, 0
	bitda 0, 0x35b1
	jr nz, RhythmROM_LoadKit_CopyLoop
	ld xhl, 0x26

RhythmROM_LoadKit_CopyLoop:
	add xhl, xiy
	ld hl, (xhl)
	stda16 0x356a, xhl
	ld xhl, 0x4c
	add xhl, xiy
	ld hl, (xhl)
	stda16 0x356c, xhl
	ld xhl, 0x72
	add xhl, xiy
	ld hl, (xhl)
	stda16 0x356e, xhl
	ld xhl, 0x98
	add xhl, xiy
	ld hl, (xhl)
	stda16 0x3570, xhl
	ld xhl, 0xbe
	add xhl, xiy
	ld hl, (xhl)
	stda16 0x3572, xhl
	ret

RhythmROM_LoadKit_CopyReturn:
	nop
	nop

__pad_F63AE7:
	ldb_d8 l, 0x34ef
	and l, 0xf
	xor h, h
	sla hl, 1
	ld xix, VoiceSlot_ResolveIndex_0x2
	ldw_sri WA, 0x07, 0xf0, 0xec
	stda16 0x35b4, xwa
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
	ldw	wa, 0x3201
	.byte 0x01
	ldw	ix, 0x3601
	.byte 0x01
	ldw	wa, 0x3205
	halt
	ldw	ix, 0x3605
	halt
	ret
	nop
	nop

VoiceSlot_Resolve_Loop:
	ldb_d8 w, 0x358c
	calr RhythmROM_CalcPatternAddr
	ldw_d16 xiy, 0x356a
	ldw_d16 xde, 0x3598
	bitda 0, 0x35b1
	jr nz, VoiceSlot_Resolve_CheckA
	bitda 1, 0x35b1
	jr nz, VoiceSlot_Resolve_CheckA
	jr VoiceSlot_Resolve_CheckB

VoiceSlot_Resolve_CheckA:
	calr RhythmBuf_LoadPattern
	jr VoiceSlot_Resolve_StoreA

VoiceSlot_Resolve_CheckB:
	calr RhythmBuf_FillEmptyPattern

VoiceSlot_Resolve_StoreA:
	anddi8 0x35b0, 251
	ldb_d8 w, 0x358d
	calr RhythmROM_CalcPatternAddr
	ldw_d16 xiy, 0x356c
	ldw_d16 xde, 0x359a
	bitda 2, 0x35b1
	jr z, VoiceSlot_Resolve_CheckC
	calr RhythmBuf_LoadPattern
	jr VoiceSlot_Resolve_StoreB

VoiceSlot_Resolve_CheckC:
	calr RhythmBuf_FillEmptyPattern

VoiceSlot_Resolve_StoreB:
	anddi8 0x35b0, 251
	ldb_d8 w, 0x358e
	calr RhythmROM_CalcPatternAddr
	ldw_d16 xiy, 0x356e
	ldw_d16 xde, 0x359c
	bitda 3, 0x35b1
	jr z, VoiceSlot_Resolve_CheckD
	calr RhythmBuf_LoadPattern
	jr VoiceSlot_Resolve_StoreC

VoiceSlot_Resolve_CheckD:
	calr RhythmBuf_FillEmptyPattern

VoiceSlot_Resolve_StoreC:
	anddi8 0x35b0, 251
	ldb_d8 w, 0x358f
	calr RhythmROM_CalcPatternAddr
	ldw_d16 xiy, 0x3570
	ldw_d16 xde, 0x359e
	bitda 4, 0x35b1
	jr z, VoiceSlot_Resolve_CheckE
	calr RhythmBuf_LoadPattern
	jr VoiceSlot_Resolve_StoreD

VoiceSlot_Resolve_CheckE:
	calr RhythmBuf_FillEmptyPattern

VoiceSlot_Resolve_StoreD:
	anddi8 0x35b0, 251
	ldb_d8 w, 0x3590
	calr RhythmROM_CalcPatternAddr
	ldw_d16 xiy, 0x3572
	ldw_d16 xde, 0x35a0
	bitda 5, 0x35b1
	jr z, VoiceSlot_Resolve_StoreE
	calr RhythmBuf_LoadPattern
	jr VoiceSlot_Resolve_Done

VoiceSlot_Resolve_StoreE:
	calr RhythmBuf_FillEmptyPattern

VoiceSlot_Resolve_Done:
	anddi8 0x35b0, 251
	ret

__pad_F63BDA:
	nop
	nop
	ldb_d8	w, 0x358c
	calr	64257
	ldw_d16	iy, 0x356a
	ldw_d16	ix, 0x3580
	ldw_d16	de, 0x3598
	calr	577
	ldb_d8	w, 0x3591
	calr	64235
	ldw_d16	iy, 0x3574
	calr	563
	.byte 0xc1
	lda	xiy, (xwa)
	push	xix
	swi	3
	ldb_d8	w, 0x358d
	calr	64216
	ldw_d16	iy, 0x356c
	ldw_d16	ix, 0x3582
	ldw_d16	de, 0x359a
	calr	536
	ldb_d8	w, 0x3592
	calr	64194
	ldw_d16	iy, 0x3576
	calr	522
	.byte 0xc1
	lda	xiy, (xwa)
	push	xix
	swi	3
	ldb_d8	w, 0x358e
	calr	64175
	ldw_d16	iy, 0x356e
	ldw_d16	ix, 0x3584
	ldw_d16	de, 0x359c
	calr	495
	ldb_d8	w, 0x3593
	calr	64153
	ldw_d16	iy, 0x3578
	calr	481
	.byte 0xc1
	lda	xiy, (xwa)
	push	xix
	swi	3
	ldb_d8	w, 0x358f
	calr	64134
	ldw_d16	iy, 0x3570
	ldw_d16	ix, 0x3586
	ldw_d16	de, 0x359e
	calr	454
	ldb_d8	w, 0x3594
	calr	64112
	ldw_d16	iy, 0x357a
	calr	440
	.byte 0xc1
	lda	xiy, (xwa)
	push	xix
	swi	3
	ldb_d8	w, 0x3590
	calr	64093
	ldw_d16	iy, 0x3572
	ldw_d16	ix, 0x3588
	ldw_d16	de, 0x35a0
	calr	413
	ldb_d8	w, 0x3595
	calr	64071
	ldw_d16	iy, 0x357c
	calr	399
	.byte 0xc1
	lda	xiy, (xwa)
	push	xix
	swi	3
	ret
	nop
	nop

AccSection_ProcessEntry:
	ldb_d8 w, 0x358c
	calr RhythmROM_CalcPatternAddr
	ldw_d16 xiy, 0x356a
	ldw_d16 xde, 0x3598
	bitda 0, 0x35b1
	jr nz, AccSection_Process_Loop
	bitda 1, 0x35b1
	jr nz, AccSection_Process_Loop
	jr AccSection_Process_Return

AccSection_Process_Loop:
	calr RhythmBuf_LoadPattern
	ldb_d8 w, 0x3591
	calr RhythmROM_CalcPatternAddr
	ldw_d16 xiy, 0x3574
	calr RhythmBuf_LoadPattern
	ldb_d8 w, 0x35c0
	calr RhythmROM_CalcPatternAddr
	ldw_d16 xiy, 0x35b6
	calr RhythmBuf_LoadPattern
	ldb_d8 w, 0x35d0
	calr RhythmROM_CalcPatternAddr
	ldw_d16 xiy, 0x35c6
	calr RhythmBuf_LoadPattern
	jr __pad_F63CFB

AccSection_Process_Return:
	calr RhythmBuf_FillEmptyPattern

__pad_F63CFB:
	anddi8 0x35b0, 251
	ldb_d8 w, 0x358d
	calr RhythmROM_CalcPatternAddr
	ldw_d16 xiy, 0x356c
	ldw_d16 xde, 0x359a
	bitda 2, 0x35b1
	jr z, AccSection_Process2_Return
	calr RhythmBuf_LoadPattern
	ldb_d8 w, 0x3592
	calr RhythmROM_CalcPatternAddr
	ldw_d16 xiy, 0x3576
	calr RhythmBuf_LoadPattern
	ldb_d8 w, 0x35c1
	calr RhythmROM_CalcPatternAddr
	ldw_d16 xiy, 0x35b8
	calr RhythmBuf_LoadPattern
	ldb_d8 w, 0x35d1
	calr RhythmROM_CalcPatternAddr
	ldw_d16 xiy, 0x35c8
	calr RhythmBuf_LoadPattern
	jr __pad_F63D47

AccSection_Process2_Return:
	calr RhythmBuf_FillEmptyPattern

__pad_F63D47:
	anddi8 0x35b0, 251
	ldb_d8 w, 0x358e
	calr RhythmROM_CalcPatternAddr
	ldw_d16 xiy, 0x356e
	ldw_d16 xde, 0x359c
	bitda 3, 0x35b1
	jr z, AccSection_Process3_Return
	calr RhythmBuf_LoadPattern
	ldb_d8 w, 0x3593
	calr RhythmROM_CalcPatternAddr
	ldw_d16 xiy, 0x3578
	calr RhythmBuf_LoadPattern
	ldb_d8 w, 0x35c2
	calr RhythmROM_CalcPatternAddr
	ldw_d16 xiy, 0x35ba
	calr RhythmBuf_LoadPattern
	ldb_d8 w, 0x35d2
	calr RhythmROM_CalcPatternAddr
	ldw_d16 xiy, 0x35ca
	calr RhythmBuf_LoadPattern
	jr __pad_F63D93

AccSection_Process3_Return:
	calr RhythmBuf_FillEmptyPattern

__pad_F63D93:
	anddi8 0x35b0, 251
	ldb_d8 w, 0x358f
	calr RhythmROM_CalcPatternAddr
	ldw_d16 xiy, 0x3570
	ldw_d16 xde, 0x359e
	bitda 4, 0x35b1
	jr z, AccSection_Process4_Return
	calr RhythmBuf_LoadPattern
	ldb_d8 w, 0x3594
	calr RhythmROM_CalcPatternAddr
	ldw_d16 xiy, 0x357a
	calr RhythmBuf_LoadPattern
	ldb_d8 w, 0x35c3
	calr RhythmROM_CalcPatternAddr
	ldw_d16 xiy, 0x35bc
	calr RhythmBuf_LoadPattern
	ldb_d8 w, 0x35d3
	calr RhythmROM_CalcPatternAddr
	ldw_d16 xiy, 0x35cc
	calr RhythmBuf_LoadPattern
	jr __pad_F63DDF

AccSection_Process4_Return:
	calr RhythmBuf_FillEmptyPattern

__pad_F63DDF:
	anddi8 0x35b0, 251
	ldb_d8 w, 0x3590
	calr RhythmROM_CalcPatternAddr
	ldw_d16 xiy, 0x3572
	ldw_d16 xde, 0x35a0
	bitda 5, 0x35b1
	jr z, AccSection_Process5_Return
	calr RhythmBuf_LoadPattern
	ldb_d8 w, 0x3595
	calr RhythmROM_CalcPatternAddr
	ldw_d16 xiy, 0x357c
	calr RhythmBuf_LoadPattern
	ldb_d8 w, 0x35c4
	calr RhythmROM_CalcPatternAddr
	ldw_d16 xiy, 0x35be
	calr RhythmBuf_LoadPattern
	ldb_d8 w, 0x35d4
	calr RhythmROM_CalcPatternAddr
	ldw_d16 xiy, 0x35ce
	calr RhythmBuf_LoadPattern
	jr __pad_F63E2B

AccSection_Process5_Return:
	calr RhythmBuf_FillEmptyPattern

__pad_F63E2B:
	anddi8 0x35b0, 251
	ret

AccSection_Finalize:
	nop
	nop

; ============================================================================
; RhythmBuf_LoadPattern - Load rhythm pattern from ROM to DRAM buffer
; ============================================================================
; Input:  XIY = source ROM pointer, XIZ = write offset, XDE = dest base
; Output: Pattern data at 0x95c00 + index*256
; Copies bytes until end marker (0x83) or buffer full (0xfe). Chains buffers.
; ============================================================================
RhythmBuf_LoadPattern:
	bitda 0, 0x35b0
	jr z, AccFill_CheckPattern
	jp AccFill_AdvCheck_Done

AccFill_CheckPattern:
	add iy, 0x6
	and xiy, 0xffff
	add xiy, xix
	bitda 2, 0x35b0
	jr z, AccFill_ProcessEntry
	jr AccFill_ProcessDone

AccFill_ProcessEntry:
	ordi8 0x35b0, 4
	stda16 0x3596, xde
	lds32 xiz, 6

AccFill_ProcessDone:
	ld a, (xiy)
	ldw_d16 xhl, 0x3596
	calr AccPat_IndexToAddress
	add xhl, xiz
	ld (xhl), a

__pad_F63E69:
	cp a, 0x83
	jr z, AccFill_AdvCheck_Return
	inc 1, xiy
	inc 1, xiz
	cp xiz, 0xfe
	jr ule, AccFill_AdvanceAndCheck
	calr __pad_F634B5
	bitda 0, 0x35b0
	jr nz, AccFill_AdvCheck_Return
	push xiy
	ldw_d16 xhl, 0x3596
	calr AccPat_IndexToAddress
	lds32 xiy, 3
	add xiy, xhl
	ld (xiy), de
	ld hl, de
	calr AccPat_IndexToAddress
	lds32 xiy, 1
	add xiy, xhl
	ldw_d16 xwa, 0x3596
	ld (xiy), wa
	stda16 0x3596, xde
	ormi8 (xhl), 0x80
	decdi16 1, 0x34d4
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
	ldw wa, 0xffff
	ld hl, de
	calr AccPat_IndexToAddress
	lds32 xiy, 3

AccFill_AdvCheck_Done:
	ret

__pad_F63EC6:
	nop
	nop
	push	sr
	.byte 0x04, 0x06
	ldio	1, 2
	pop	sr
	.byte 0x04
	halt
	ei	7
	ldio	1, 2
	pop	sr
	.byte 0x04
	halt
	ei	7
	.byte 0x08

RhythmBuf_FillEmptyPattern:
	ldda32 xiy, 0x3560
	ld l, (xiy + 12)
	xor h, h
	ld xix, __pad_F63EC6_0x2
	ldb_sri W, 0x07, 0xf0, 0xec
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
	.byte 0xc1, 0xef
	ldw	ix, 4159
	jr	ule, 30
	ldb	a, 123
	.byte 0xc1, 0xed
	ldw	ix, 0x843f
	jr	c, 13
	add	a, 6
	.byte 0xc1, 0xed
	ldw	ix, 0x883f
	jr	c, 3
	add	a, 6
	addda8	a, 0x34ef
	stb_d8	0x34ed, a
	ret
	nop
	nop

AccPat_CalcAccentVelocity:
	cpdi8 0x34ef, 19
	jr ule, StyleConvert_Reload_Return
	ldb a, 0x78
	cpdi8 0x34ed, 132
	jr c, StyleConvert_Reload_CheckEnd
	add a, 0x6
	cpdi8 0x34ed, 136
	jr c, StyleConvert_Reload_CheckEnd
	add a, 0x6

StyleConvert_Reload_CheckEnd:
	addda8 a, 0x34ef
	stb_d8 0x34ed, a
	jr StyleConvert_Reload_Done

StyleConvert_Reload_Return:
	cpdi8 0x34ef, 16
	jr c, StyleConvert_Reload_Done
	ldb a, 0x70
	cpdi8 0x34ed, 132
	jr c, StyleConvert_Reload_Fallback
	add a, 0x4
	cpdi8 0x34ed, 136
	jr c, StyleConvert_Reload_Fallback
	add a, 0x4

StyleConvert_Reload_Fallback:
	addda8 a, 0x34ef
	stb_d8 0x34ed, a

StyleConvert_Reload_Done:
	ret

__pad_F63F8F:
	ldb_d8	l, 0x34ed
	ldb_d8	h, 0x34ee
	call	VoiceParam_ClampAndValidate_Tramp
	ld	de, hl
	ld	xiy, __pad_F63F8F_0x33
	xor	hl, hl
	.byte 0xd3
	reti
	.byte 0xf4, 0xec
	ldb	w, 216
	.byte 0xcf
	swi	7
	swi	7
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
	di
	ei	1
	ei	2
	ei	3
	reti
	nop
	reti
	.byte 0x01
	reti
	push	sr
	swi	7
	swi	7
	swi	7
	swi	7
	ldb_d8	l, 0x34ed
	ldb_d8	h, 0x34d6
	cp	l, 128
	jr	nc, 42
	cp	h, 12
	jr	nc, 12
	ldb	a, 0
	ldb_d8	w, 0xfc61
	jr	z, 2
	ldb	a, 1
	jr	48
	ldb_d8	a, 0x34d6
	sub	a, 12
	and	a, 3
	ldb_d8	w, 0xfc61
	jr	z, 3
	or	a, 4
	xor	hl, hl
	ld	l, a
	jr	23
	cp	h, 12
	jr	nc, 4
	ldb	a, 0
	jr	14
	ldb_d8	a, 0x34d6
	sub	a, 12
	and	a, 3
	xor	hl, hl
	ld	l, a
	stb_d8	0x34ef, a
	ret
	nop
	nop
	.byte 0x04
	ldio	9, 6
	.byte 0x04
	ldio	9, 6
	ret
	.byte 0xf1
	decdi16	6, 0xc834
	.byte 0x04
	jp	__pad_F63F8F_0x1A8
	ldb_d8	l, 0x34d6
	ldb_d8	a, 0x34ed
	ldb_d8	w, 0x34ee
	pushw	hl
	pushw	wa
	.byte 0xc1, 0xed
	ldw	ix, 0x803f
	jr	c, 4
	jp	__pad_F63F8F_0x18D
	.byte 0xc1, 0xd6
	ldw	ix, 63
	jr	z, 4
	jp	__pad_F63F8F_0x18D
	stdi8	0x34d6, 0
	stdi8	0x34d6, 6
	stdi8	0x34d6, 7
	stdi8	0x34d6, 8
	stdi8	0x34d6, 9
	.byte 0xc1
	lda	xiy, (xwa)
	push	xix
	ldx
	stdi8	0x34ef, 0
	stdi8	0x34d6, 0
	.byte 0xc1, 0xd1
	ldw	ix, 318
	calr	61631
	.byte 0xf1
	lda	xiy, (xwa)
	inc	6, w
	halt
	.byte 0xc1
	lda	xiy, (xwa)
	push	xiz
	ldio	241, 239
	ldw	ix, 1024
	stdi8	0x34d6, 6
	.byte 0xc1, 0xd1
	ldw	ix, 318
	calr	61602
	.byte 0xf1
	lda	xiy, (xwa)
	inc	6, w
	halt
	.byte 0xc1
	lda	xiy, (xwa)
	push	xiz
	ldio	241, 239
	ldw	ix, 2048
	stdi8	0x34d6, 7
	.byte 0xc1, 0xd1
	ldw	ix, 318
	calr	61573
	.byte 0xf1
	lda	xiy, (xwa)
	inc	6, w
	halt
	.byte 0xc1
	lda	xiy, (xwa)
	push	xiz
	ldio	241, 239
	ldw	ix, 2304
	stdi8	0x34d6, 8
	.byte 0xc1, 0xd1
	ldw	ix, 318
	calr	61544
	.byte 0xf1
	lda	xiy, (xwa)
	inc	6, w
	halt
	.byte 0xc1
	lda	xiy, (xwa)
	push	xiz
	ldio	241, 239
	ldw	ix, 1536
	stdi8	0x34d6, 9
	.byte 0xc1, 0xd1
	ldw	ix, 318
	calr	61515
	.byte 0xf1
	lda	xiy, (xwa)
	inc	6, w
	halt
	.byte 0xc1
	lda	xiy, (xwa)
	push	xiz
	ldio	241, 176
	ldw	iy, 0x66cb
	halt
	.byte 0xc1
	lda	xiy, (xwa)
	push	xiz
	.byte 0x01
	jr	13
	stdi8	0x34ef, 0
	.byte 0xc1, 0xd1
	ldw	ix, 318
	calr	61478
	popw	wa
	popw	hl
	stb_d8	0x34ee, w
	stb_d8	0x34ed, a
	stb_d8	0x34d6, l
	ret
	nop
	nop

AccWidget_DispatchTable:
	ld xiy, 0x9b4000
	ld xix, 0x94800
	ldw bc, 0x8000
	ldirw
	jp AccWidget_Dispatch_Return

AccWidget_Dispatch_Return:
	ret

__pad_F6414E:
	nop
	nop

AccWidget_ProcessSpecialCmd:
	cpdi8 0x34ee, 0
	jr nz, __pad_F64174
	ldb_d8 a, 0x34ed
	and a, 0x7f
	ld xix, DrumKit_GroupAssignTable
	ldb_sri A, 0x03, 0xf0, 0xe0
	ldb_d8 w, 0x34d6
	sub w, 0x1e
	cp a, w
	jrl z, DrumKit_Return

__pad_F64174:
	ldb_d8 a, 0x34ed
	ldb_d8 w, 0x34ee
	ldb_d8 l, 0x34ef
	ldb_d8 h, 0x34d6
	pushw wa
	pushw hl
	ordi8 0x34cd, 128
	stdi8 0x34ef, 16
	ldb_d8 l, 0x34d6
	sub l, 0x1e
	stb_d8 0x39a5, l
	ld xix, DrumKit_GroupAssignTable_0x3C
	ldb_sri L, 0x03, 0xf0, 0xec
	stb_d8 0x34d6, l
	stb_d8 0x39a6, l
	calr AccPat_CalcAccentVelocity
	call AccPat_InitWorkAreaFromSlot
	ldb_d8 a, 0x34ed
	and a, 0x7f
	stb_d8 0x39ac, a
	ldb_d8 a, 0x34d6
	stb_d8 0x39ad, a
	push xix
	ld xix, 0x94800
	stda32 0x39ae, xix
	stda32 0x39b2, xix
	pop xix
	calr AccPatch_LoadDualVoiceParams
	bitda 0, 0x35b0
	jrl nz, DrumKit_ErrorFallbackLoop
	stdi8 0x34ef, 17
	ldb_d8 l, 0x39a6
	inc 1, l
	stb_d8 0x34d6, l
	calr AccPat_CalcAccentVelocity
	call AccPat_InitWorkAreaFromSlot
	ldb_d8 a, 0x34ed
	and a, 0x7f
	stb_d8 0x39ac, a
	ldb_d8 a, 0x34d6
	stb_d8 0x39ad, a
	push xix
	ld xix, 0x94800
	stda32 0x39ae, xix
	stda32 0x39b2, xix
	pop xix
	calr AccPatch_LoadDualVoiceParams
	bitda 0, 0x35b0
	jrl nz, DrumKit_ErrorFallbackLoop
	stdi8 0x34ef, 18
	ldb_d8 l, 0x39a6
	add l, 0x2
	stb_d8 0x34d6, l
	calr AccPat_CalcAccentVelocity
	call AccPat_InitWorkAreaFromSlot
	ldb_d8 a, 0x34ed
	and a, 0x7f
	stb_d8 0x39ac, a
	ldb_d8 a, 0x34d6
	stb_d8 0x39ad, a
	push xix
	ld xix, 0x94800
	stda32 0x39ae, xix
	stda32 0x39b2, xix
	pop xix
	calr AccPatch_LoadDualVoiceParams
	bitda 0, 0x35b0
	jrl nz, DrumKit_ErrorFallbackLoop
	stdi8 0x34ef, 19
	ldb_d8 l, 0x39a6
	add l, 0x3
	stb_d8 0x34d6, l
	calr AccPat_CalcAccentVelocity
	call AccPat_InitWorkAreaFromSlot
	ldb_d8 a, 0x34ed
	and a, 0x7f
	stb_d8 0x39ac, a
	ldb_d8 a, 0x34d6
	stb_d8 0x39ad, a
	push xix
	ld xix, 0x94800
	stda32 0x39ae, xix
	stda32 0x39b2, xix
	pop xix
	calr AccPatch_LoadDualVoiceParams
	bitda 0, 0x35b0
	jrl nz, DrumKit_ErrorFallbackLoop
	stdi8 0x34ef, 20
	ldb_d8 a, 0x34ed
	pushw wa
	calr AccPat_CalcAccentVelocity
	ldb_d8 l, 0x39a5
	ld xix, DrumKit_GroupAssignTable_0x3F
	ldb_sri L, 0x03, 0xf0, 0xec
	stb_d8 0x34d6, l
	call AccPat_InitWorkAreaFromSlot
	ldb_d8 a, 0x34ed
	and a, 0x7f
	stb_d8 0x39ac, a
	ldb_d8 a, 0x34d6
	stb_d8 0x39ad, a
	push xix
	ld xix, 0x94800
	stda32 0x39ae, xix
	stda32 0x39b2, xix
	pop xix
	calr AccPatch_LoadDualVoiceParams
	popw wa
	stb_d8 0x34ed, a
	bitda 0, 0x35b0
	jrl nz, DrumKit_ErrorFallbackLoop
	stdi8 0x34ef, 21
	ldb_d8 a, 0x34ed
	pushw wa
	calr AccPat_CalcAccentVelocity
	ldb_d8 l, 0x39a5
	ld xix, DrumKit_GroupAssignTable_0x42
	ldb_sri L, 0x03, 0xf0, 0xec
	stb_d8 0x34d6, l
	call AccPat_InitWorkAreaFromSlot
	ldb_d8 a, 0x34ed
	and a, 0x7f
	stb_d8 0x39ac, a
	ldb_d8 a, 0x34d6
	stb_d8 0x39ad, a
	push xix
	ld xix, 0x94800
	stda32 0x39ae, xix
	stda32 0x39b2, xix
	pop xix
	calr AccPatch_LoadDualVoiceParams
	popw wa
	stb_d8 0x34ed, a
	bitda 0, 0x35b0
	jrl nz, DrumKit_ErrorFallbackLoop
	stdi8 0x34ef, 22
	ldb_d8 a, 0x34ed
	pushw wa
	calr AccPat_CalcAccentVelocity
	ldb_d8 l, 0x39a5
	ld xix, DrumKit_GroupAssignTable_0x45
	ldb_sri L, 0x03, 0xf0, 0xec
	stb_d8 0x34d6, l
	call AccPat_InitWorkAreaFromSlot
	ldb_d8 a, 0x34ed
	and a, 0x7f
	stb_d8 0x39ac, a
	ldb_d8 a, 0x34d6
	stb_d8 0x39ad, a
	push xix
	ld xix, 0x94800
	stda32 0x39ae, xix
	stda32 0x39b2, xix
	pop xix
	calr AccPatch_LoadDualVoiceParams
	popw wa
	stb_d8 0x34ed, a
	bitda 0, 0x35b0
	jrl nz, DrumKit_ErrorFallbackLoop
	stdi8 0x34ef, 23
	ldb_d8 a, 0x34ed
	pushw wa
	calr AccPat_CalcAccentVelocity
	ldb_d8 l, 0x39a5
	ld xix, DrumKit_GroupAssignTable_0x48
	ldb_sri L, 0x03, 0xf0, 0xec
	stb_d8 0x34d6, l
	call AccPat_InitWorkAreaFromSlot
	ldb_d8 a, 0x34ed
	and a, 0x7f
	stb_d8 0x39ac, a
	ldb_d8 a, 0x34d6
	stb_d8 0x39ad, a
	push xix
	ld xix, 0x94800
	stda32 0x39ae, xix
	stda32 0x39b2, xix
	pop xix
	calr AccPatch_LoadDualVoiceParams
	popw wa
	stb_d8 0x34ed, a
	bitda 0, 0x35b0
	jrl nz, DrumKit_ErrorFallbackLoop
	stdi8 0x34ef, 24
	ldb_d8 a, 0x34ed
	pushw wa
	calr AccPat_CalcAccentVelocity
	ldb_d8 l, 0x39a5
	ld xix, DrumKit_GroupAssignTable_0x4B
	ldb_sri L, 0x03, 0xf0, 0xec
	stb_d8 0x34d6, l
	call AccPat_InitWorkAreaFromSlot
	ldb_d8 a, 0x34ed
	and a, 0x7f
	stb_d8 0x39ac, a
	ldb_d8 a, 0x34d6
	stb_d8 0x39ad, a
	push xix
	ld xix, 0x94800
	stda32 0x39ae, xix
	stda32 0x39b2, xix
	pop xix
	calr AccPatch_LoadDualVoiceParams
	popw wa
	stb_d8 0x34ed, a
	bitda 0, 0x35b0
	jrl nz, DrumKit_ErrorFallbackLoop
	stdi8 0x34ef, 25
	ldb_d8 a, 0x34ed
	pushw wa
	calr AccPat_CalcAccentVelocity
	ldb_d8 l, 0x39a5
	ld xix, DrumKit_GroupAssignTable_0x4E
	ldb_sri L, 0x03, 0xf0, 0xec
	stb_d8 0x34d6, l
	call AccPat_InitWorkAreaFromSlot
	ldb_d8 a, 0x34ed
	and a, 0x7f
	stb_d8 0x39ac, a
	ldb_d8 a, 0x34d6
	stb_d8 0x39ad, a
	push xix
	ld xix, 0x94800
	stda32 0x39ae, xix
	stda32 0x39b2, xix
	pop xix
	calr AccPatch_LoadDualVoiceParams
	popw wa
	stb_d8 0x34ed, a
	bitda 0, 0x35b0
	jr z, DrumKit_SetErrorCode20

DrumKit_ErrorFallbackLoop:
	xor c, c
	ld xix, DrumKit_FallbackSlotTable

DrumKit_ErrorFallbackSlotIter:
	ldb_d8 a, 0x39a5
	ld w, a
	sll a, 3
	sll w, 1
	add a, w
	extz wa
	extz xwa
	add xwa, xix
	ldb_sri A, 0x03, 0xe0, 0xe4
	stb_d8 0x34d6, a
	push xbc
	push xix
	call AccPat_InitWorkAreaFromSlot
	pop xix
	pop xbc
	inc 1, c
	cp c, 0xa
	jr c, DrumKit_ErrorFallbackSlotIter
	stdi8 0x7f42, 23
	call DrumVoice_NotifyEE
	ldb a, 0x8
	call MIDI_SendSysExCmd
	jr DrumKit_RestoreRegisters

DrumKit_SetErrorCode20:
	stdi8 0x7f42, 20
	call DrumVoice_NotifyEE

DrumKit_RestoreRegisters:
	popw hl
	popw wa
	stb_d8 0x34ef, l
	stb_d8 0x34d6, h
	stb_d8 0x34ee, w
	stb_d8 0x34ed, a

DrumKit_Return:
	ret

DrumKit_GroupAssignTable:
	.byte 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01
	.byte 0x02, 0x02, 0x02, 0x02, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
	.byte 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x00, 0x00
	.byte 0x00, 0x00, 0x04, 0x04, 0x04, 0x04, 0x08, 0x08
	.byte 0x08, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x08, 0x08
	.byte 0x08, 0x08, 0x08, 0x08, 0x00, 0x04, 0x08, 0x0c
	.byte 0x12, 0x18, 0x0d, 0x13, 0x19, 0x0e, 0x14, 0x1a
	.byte 0x0f, 0x15, 0x1b, 0x10, 0x16, 0x1c, 0x11, 0x17
	.byte 0x1d

RhythmROM_LoadDrumKit:
	ldb_d8 a, 0x34ed
	ldb_d8 w, 0x34ee
	ldb_d8 l, 0x34ef
	ldb_d8 h, 0x34d6
	pushw wa
	pushw hl
	stdi8 0x34ef, 0
	ldb_d8 l, 0x34d6
	sub l, 0x1e
	stb_d8 0x39a5, l
	sll l, 2
	ld xix, DrumKit_GroupAssignTable_0x1E
	ldb_sri L, 0x03, 0xf0, 0xec
	stb_d8 0x34d6, l
	stb_d8 0x39a6, l
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher
	bitda 0, 0x35b0
	jrl nz, DrumKit_PatternLoadFailed
	stdi8 0x34ef, 1
	ldb_d8 l, 0x39a6
	inc 1, l
	stb_d8 0x34d6, l
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher
	bitda 0, 0x35b0
	jrl nz, DrumKit_PatternLoadFailed
	stdi8 0x34ef, 2
	ldb_d8 l, 0x39a6
	add l, 0x2
	stb_d8 0x34d6, l
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher
	bitda 0, 0x35b0
	jrl nz, DrumKit_PatternLoadFailed
	stdi8 0x34ef, 3
	ldb_d8 l, 0x39a6
	add l, 0x3
	stb_d8 0x34d6, l
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher
	bitda 0, 0x35b0
	jrl nz, DrumKit_PatternLoadFailed
	stdi8 0x34ef, 4
	ldb_d8 l, 0x39a5
	ld xix, DrumKit_GroupAssignTable_0x3F
	ldb_sri L, 0x03, 0xf0, 0xec
	stb_d8 0x34d6, l
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher
	bitda 0, 0x35b0
	jrl nz, DrumKit_PatternLoadFailed
	stdi8 0x34ef, 5
	ldb_d8 l, 0x39a5
	ld xix, DrumKit_GroupAssignTable_0x42
	ldb_sri L, 0x03, 0xf0, 0xec
	stb_d8 0x34d6, l
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher
	bitda 0, 0x35b0
	jrl nz, DrumKit_PatternLoadFailed
	stdi8 0x34ef, 10
	ldb_d8 l, 0x39a5
	ld xix, DrumKit_GroupAssignTable_0x45
	ldb_sri L, 0x03, 0xf0, 0xec
	stb_d8 0x34d6, l
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher
	bitda 0, 0x35b0
	jrl nz, DrumKit_PatternLoadFailed
	stdi8 0x34ef, 11
	ldb_d8 l, 0x39a5
	ld xix, DrumKit_GroupAssignTable_0x48
	ldb_sri L, 0x03, 0xf0, 0xec
	stb_d8 0x34d6, l
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher
	bitda 0, 0x35b0
	jrl nz, DrumKit_PatternLoadFailed
	stdi8 0x34ef, 6
	ldb_d8 l, 0x39a5
	ld xix, DrumKit_GroupAssignTable_0x4B
	ldb_sri L, 0x03, 0xf0, 0xec
	stb_d8 0x34d6, l
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher
	bitda 0, 0x35b0
	jr nz, DrumKit_PatternLoadFailed
	stdi8 0x34ef, 7
	ldb_d8 l, 0x39a5
	ld xix, DrumKit_GroupAssignTable_0x4E
	ldb_sri L, 0x03, 0xf0, 0xec
	stb_d8 0x34d6, l
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher
	bitda 0, 0x35b0
	jr z, DrumKit_AllPatternsOK

DrumKit_PatternLoadFailed:
	xor c, c
	ld xix, DrumKit_FallbackSlotTable

DrumKit_FallbackSlotLoop:
	ldb_d8 a, 0x39a5
	ld w, a
	sll a, 3
	sll w, 1
	add a, w
	extz wa
	extz xwa
	add xwa, xix
	ldb_sri A, 0x03, 0xe0, 0xe4
	stb_d8 0x34d6, a
	push xbc
	push xix
	call AccPat_InitWorkAreaFromSlot
	pop xix
	pop xbc
	inc 1, c
	cp c, 0xa
	jr c, DrumKit_FallbackSlotLoop
	stdi8 0x7f42, 23
	call DrumVoice_NotifyEE
	ldb a, 0x8
	call MIDI_SendSysExCmd
	jr DrumKit_Epilogue

DrumKit_AllPatternsOK:
	stdi8 0x7f42, 20
	call DrumVoice_NotifyEE

DrumKit_Epilogue:
	popw hl
	popw wa
	stb_d8 0x34d6, h
	stb_d8 0x34ef, l
	stb_d8 0x34ee, w
	stb_d8 0x34ed, a
	ret

DrumKit_FallbackSlotTable:
	.byte 0x00, 0x01, 0x02, 0x03, 0x0c, 0x0d, 0x0e, 0x0f
	.byte 0x10, 0x11, 0x04, 0x05, 0x06, 0x07, 0x12, 0x13
	.byte 0x14, 0x15, 0x16, 0x17, 0x08, 0x09, 0x0a, 0x0b
	.byte 0x18, 0x19, 0x1a, 0x1b, 0x1d, 0x1d

DrumParam_Wrapper:
	calr DrumParam_Lookup
	ret

DrumParam_Lookup:
	push xhl
	lds32 xhl, 0
	and w, 0x7
	sll w, 2
	ld l, w
	add xhl, DrumParam_PointerTableAndData_0x2
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
	.byte 0x9b
	ld	xsp, 0x49db00f6
	.byte 0xf6
	nop
	.byte 0xbb
	popw	wa
	.byte 0xf6
	nop
	jrl	ugt, -2487
	nop
	pop	xhl
	popw	wa
	.byte 0xf6
	nop
	jp	0xf649
	swi	3
	ld	xsp, 0x479b00f6
	.byte 0xf6
	nop
	.byte 0xf4, 0xf4, 0xf4, 0xf4, 0xf4, 0xf4
	.fill 8, 1, 0xf4
	.byte 0xf4, 0xf4
	nop
	nop
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
	jrl	nc, 32639
	jrl	nc, 32639
	.fill 8, 1, 0x7f
	.fill 8, 1, 0x7f
	jrl	nc, 127
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
	push_f
	push_f
	.fill 8, 1, 0x18
	.fill 8, 1, 0x18
	push_f
	push_f
	push_f
	push_f
	push_f
	push_f
	.byte 0x30, 0x30
	.ascii "0000000000000000000000HHHHHHHHHHHHHHHHHHHHHHHH"
	.byte 0x7f, 0x7f
	.fill 8, 1, 0x7f
	jrl	nc, 127
	nop
	nop
	nop
	nop
	nop
	.fill 8, 1, 0x0c
	incf
	incf
	incf
	incf
	push_f
	push_f
	push_f
	push_f
	.fill 8, 1, 0x18
	.ascii "$$$$$$$$$$$$000000000000<<<<<<<<<<<<IIIIIIIIIIIITTTTTTTTTTTT"
	jrl	nc, 32639
	jrl	nc, 32639
	nop
	nop
	nop
	nop
	nop
	nop
	.zero 10
	.ascii "                                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
	jrl	nc, 32639
	jrl	nc, 32639
	.fill 8, 1, 0x7f
	jrl	nc, 127
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	rcf
	rcf
	rcf
	rcf
	rcf
	rcf
	.fill 8, 1, 0x10
	rcf
	rcf
	.ascii "                0000000000000000@@@@@@@@@@@@@@@@PPPPPPPPPPPPPPPP"
	jrl	nc, 32639
	jrl	nc, 32639
	jrl	nc, 127
	nop
	nop
	nop
	ldio	8, 8
	ldio	8, 8
	ldio	8, 16
	rcf
	rcf
	rcf
	rcf
	rcf
	rcf
	rcf
	push_f
	push_f
	push_f
	push_f
	push_f
	push_f
	push_f
	push_f
	ldb	w, 32
	.ascii "      ((((((((0000000088888888@@@@@@@@HHHHHHHHPPPPPPPPXXXXXXXX"
	jrl	nc, 32639
	.byte 0x7f

DrumKitInit_Wrapper:
	push xiz
	call DrumKitInit_Entry
	pop xiz
	ret

DrumKitInit_Entry:
	ldb a, 0x48
	call CtrlPanel_SetIndicatorBit
	cpdi8 0x8d35, 14
	jr nz, DrumKitInit_Setup
	jrl DrumKitInit_Return

DrumKitInit_Setup:
	stdi8 0x34f1, 0
	stdi8 0x34db, 0
	stdi8 0x3714, 4
	stdi8 0x3715, 0
	stdi8 0x3716, 1
	call AccWrap_PlayModeDispatch
	ordi8 0x28a7, 4
	stdi8 0x379b, 64
	ldb_d8 a, 0xfc5a
	stb_d8 0x34ed, a
	ldb_d8 a, 0xfc5b
	stb_d8 0x34ee, a
	ldb_d8 a, 0xfc5a
	stb_d8 0x352b, a
	ldb_d8 a, 0xfc5b
	stb_d8 0x352c, a
	calr DrumKit_SendProgramChange
	bitda 2, 0xfc5f
	jr nz, DrumKitInit_ClearAssignFlags
	bitda 3, 0xfc5f
	jr z, DrumKitInit_CheckExtAssign

DrumKitInit_ClearAssignFlags:
	anddi8 0xfc5f, 243
	ldb d, 0x5
	ldb e, 0x48
	xor wa, wa
	call SwbtWr_QueuePostEvent

DrumKitInit_CheckExtAssign:
	bitda 2, 0xfc60
	jr z, DrumKitInit_FinalSetup
	anddi8 0xfc60, 251
	ldb d, 0x6
	ldb e, 0x48
	xor wa, wa
	call SwbtWr_QueuePostEvent

DrumKitInit_FinalSetup:
	call AccPatch_CountSlots_Wrapper
	stdi8 0x350c, 0
	call SeqAcc_SetIndicator_PB
	stdi16 0xf19e, 0
	call Audio_CheckSubsystemReady
	anddi8 0xe3e2, 158
	ordi8 0x34cd, 64

DrumKitInit_Return:
	ret

DrumKit_SendProgramChange:
	lds32 xhl, 0
	ldb_d8 l, 0x34d6
	cp l, 0x1e
	jr c, DrumKit_SendPC_MaskAndSend
	sub l, 0x1e
	sll l, 2

DrumKit_SendPC_MaskAndSend:
	and l, 0x1f
	add l, 0x80
	ld xbc, 0xfc5a
	ldb a, 0x0
	lda_dri XSP, 0x03, 0xe4, 0xe0
	ldb a, 0x1
	ldb_sri H, 0x03, 0xe4, 0xe0
	and h, 0x80
	lda_dri XIZ, 0x03, 0xe4, 0xe0
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
	cpdi8 0x8d34, 14
	jr nz, DrumKitExit_CheckState1
	jrl DrumKitExit_Return

DrumKitExit_CheckState1:
	cpdi8 0x8d34, 1
	jr z, DrumKitExit_ClearFlags
	anddi8 0x8d88, 254

DrumKitExit_ClearFlags:
	anddi8 0x28a7, 251
	anddi8 0xe3e2, 254
	anddi8 0xe3e2, 247
	anddi8 0xe3e2, 223
	stdi8 0x34f1, 0
	stdi8 0x379b, 0
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
	bitda 6, 0x34cd
	jr z, DrumKitExit_PostRestore
	anddi8 0x34cd, 191
	ldb_d8 a, 0x352b
	stb_d8 0xfc5a, a
	ldb_d8 a, 0x352c
	and a, 0x7f
	anddi8 0xfc5b, 128
	orddm8 0xfc5b, a
	calr DrumKit_PostMidiEvents

DrumKitExit_PostRestore:
	call AccWrap_PlayModeDispatch
	calr DrumKit_ValidateBank
	call SeqAcc_RestorePlaybackState
	cpdi16 0x28a8, 0
	jr nz, DrumKitExit_ExtraInit
	cpdi16 0xf19e, 0
	jr nz, DrumKitExit_ExtraInit
	jr DrumKitExit_CheckAutoPlay

DrumKitExit_ExtraInit:
	call AccWrap_PlayModeDispatch

DrumKitExit_CheckAutoPlay:
	bitda 0, 0x3283
	jr nz, DrumKitExit_Return
	ordi8 0x34cd, 128

DrumKitExit_Return:
	ret

DrumKitExit_DataPad:
	ret
	push	xiz
	call	DrumKit_ValidateBank
	pop	xiz
	ret

DrumKit_ValidateBank:
	ldb_d8 a, 0xfc5a
	cp a, 0x80
	jr c, DrumKit_ValidateBank_Return
	cp a, 0x8b
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
	and l, 0x1f
	stb_d8 0x34d6, l
	calr DrumKit_SendProgramChange

DrumKit_ValidateBank_Return:
	ret

DrumKit_StoreAndSendBank:
	stb_d8 0xfc5a, l
	anddi8 0xfc5b, 128
	ldb h, 0x0
	call PartCtrl_WriteProgramChange
	ld xix, 0xff92
	lda_dri XIZ, 0x03, 0xf0, 0xec
	call DrumKit_PostMidiEvents
	ret

DrumKit_PostMidiEvents:
	ldb e, 0x48
	ldb_d8 a, 0xfc5b
	and a, 0x7f
	ldb d, 0x1
	ldb w, 0x0
	push_a
	call SwbtWr_QueuePostEvent
	pop_a
	ld h, a
	ldb e, 0x48
	ldb_d8 a, 0xfc5a
	and a, 0xff
	ldb d, 0x0
	ldb w, 0x0
	push h
	push_a
	call SwbtWr_QueuePostEvent
	pop_a
	pop h
	ld l, a
	stdi8 0x90f7, 72
	call PartCtrl_WriteProgramChange
	ldb c, 0x48
	call MIDI_SetupChannelParams
	ret

DrumKit_UpdateStatusFlags:
	ldb_d8 w, 0x34f1
	and w, 0xc2
	bit 7, w
	jr z, DrumKit_StoreStatus
	ldb_d8 a, 0x379b
	bit 4, a
	jr z, DrumKit_StatusBit3
	or w, 0x3c

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
	or w, 0x2d

DrumKit_StatusBit2:
	bit 2, a
	jr z, DrumKit_StoreStatus
	or w, 0x1d

DrumKit_StoreStatus:
	stb_d8 0x34f1, w
	ret

DrumKit_InlineCode1:
	push	xiz
	call	DrumKit_InlineCode1_0x7
	pop	xiz
	ret
	ret
	push	xiz
	call	DrumKit_InlineCode1_0xF
	pop	xiz
	ret
	.byte 0xc1, 0x37, 0x8d
	push	xsp
	ld	(xbc), xiz
	rcf
	calr	109
	stdi8	0x379b, 64
	.byte 0xc1, 0xcd
	ldw	ix, 0xbf3c
	calr	6
	.byte 0xc1, 0xe2, 0xe3
	push	xix
	.byte 0x9e
	ret
	ldb_d8	e, 0x34cd
	and	e, 48
	lds32	xhl, 0
	ldb_d8	l, 0x34d6
	ld	xwa, DrumKit_InlineCode1_0x61
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
	stb_d8	0x34d6, l
	calr	65007
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
	rcf
	rcf
	rcf
	rcf
	rcf
	rcf
	push	xiz
	call	DrumKit_InlineCode1_0x86
	pop	xiz
	ret
	xor	xwa, xwa
	xor	xde, xde
	ldb_d8	a, 0xfc5d
	and	a, 7
	cps	a, 0
	jr	nz, 28
	ldb	a, 2
	ldb	w, 7
	ldb	e, 72
	ldb	d, 3
	call	SwbtWr_TrailingBytecode
	ldb	a, 8
	orddm8	0xfc5d, a
	ldb	w, 8
	ldb	e, 72
	ldb	d, 3
	call	SwbtWr_QueuePostEvent
	ret

DrumSlot_DispatchWrapper:
	push xiz
	call DrumSlot_Dispatch
	pop xiz
	ret

DrumSlot_Dispatch:
	cp hl, 0xa
	jr c, DrumSlot_ClampAndLookup
	lds hl, 0

DrumSlot_ClampAndLookup:
	ld xiy, DrumSlot_HandlerTable
	pushw hl
	sll hl, 2
	ld_sril3 XWA, 0x07, 0xf4, 0xec
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
	; --- Offset calc 1: add 0/4/8 to L based on (0x34cd) bits 5:4 (30 bytes) ---
	ldb_d8	e, 0x34cd
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
	stb_d8	0x34d6, l
	ret
DrumSlot_OffsetCalc_Extended:
	; --- Offset calc 2: add 8/0x0e/0x14 to L based on (0x34cd) bits 5:4 (33 bytes) ---
	ldb_d8	e, 0x34cd
	and e, 0x30
	cps	e, 0
	jr nz, DrumSlot_ExtOffset_Check20
	add l, 0x08
	jr t, DrumSlot_ExtOffset_StoreAndRet
DrumSlot_ExtOffset_Check20:
	cp e, 0x20
	jr nz, DrumSlot_ExtOffset_AddHigh
	add l, 0x0e
	jr t, DrumSlot_ExtOffset_StoreAndRet
DrumSlot_ExtOffset_AddHigh:
	add l, 0x14
DrumSlot_ExtOffset_StoreAndRet:
	stb_d8	0x34d6, l
	ret
RhythmPatInit_Wrapper:
	; --- Push XIZ wrapper for inner routine (7 bytes) ---
	push xiz
	call RhythmPatInit_Entry
	pop xiz
	ret
RhythmPatInit_Entry:
	; --- Conditional init: check (0x8d37), calr, store, optional call (39 bytes) ---
	cpdi8	0x8d37, 178
	jr z, RhythmPatInit_Cleanup
	calr RhythmPatInit_LoadParams
	stdi8	0x379b, 32
	cpdi8	0x8d37, 181
	jr nz, RhythmPatInit_Cleanup
	call AccWrap_PlayModeDispatch
	ordi8	0x28a7, 4
	jr t, RhythmPatInit_Cleanup
RhythmPatInit_Cleanup:
	anddi8	0xe3e2, 158
	ret


RhythmPatInit_LoadParams:
	call AccPatch_GetCurrentSlotAddr
	ld a, (xiy + 12)
	stb_d8 0x34d8, a
	ld l, a
	ld xwa, RhythmPatInit_KitIndexTable
	ldb_sri A, 0x03, 0xe0, 0xec
	stb_d8 0x34d9, a
	ld a, (xiy + 13)
	stb_d8 0x34d7, a
	anddi8 0x34ce, 127
	ld a, (xiy + 15)
	bit 7, a
	jr z, RhythmPatInit_FlagBit7
	ordi8 0x34ce, 128

RhythmPatInit_FlagBit7:
	ld a, (xiy + 14)
	ld w, a
	and a, 0xf
	stb_d8 0x34e9, a
	anddi8 0x34ea, 143
	bit 4, w
	jr z, RhythmPatInit_Tempo4
	ordi8 0x34ea, 16

RhythmPatInit_Tempo4:
	bit 5, w
	jr z, RhythmPatInit_Tempo5
	ordi8 0x34ea, 32

RhythmPatInit_Tempo5:
	bit 6, w
	jr z, RhythmPatInit_CopyChannels
	ordi8 0x34ea, 64

RhythmPatInit_CopyChannels:
	add xiy, 0x40
	ld xix, 0x34bc
	ld xbc, 0xd
	ldir85
	stib_dsp 0xf0, 0x00
	stib_dsp 0xf0, 0x00
	ld (xix), 0x0
	ret

RhythmPatInit_KitIndexTable:
	.byte 0x02, 0x04, 0x06, 0x08, 0x01, 0x02, 0x03, 0x04
	.byte 0x05, 0x06, 0x07, 0x08, 0x01, 0x02, 0x03, 0x04
	.byte 0x05, 0x06, 0x07, 0x08, 0x3e, 0x1d, 0xb0, 0x4e
	.byte 0xf6, 0x5e, 0x0e, 0x2b, 0xeb, 0xa8, 0x4b, 0x44
	.byte 0xc8, 0x4e, 0xf6, 0x00, 0xdb, 0xcc, 0x03, 0x00
	.byte 0xdb, 0xee, 0x02, 0xe3, 0x07, 0xf0, 0xec, 0x23
	.byte 0xb3, 0xe8, 0x0e, 0xd9, 0x4e, 0xf6, 0x00, 0xff
	.byte 0x4e, 0xf6, 0x00, 0x15, 0x4f, 0xf6, 0x00, 0xd8
	.byte 0x4e, 0xf6, 0x00, 0x0e, 0xc1, 0x0c, 0x35, 0x3f
	.byte 0x01, 0x66, 0x07, 0xf1, 0x0c, 0x35, 0x00, 0x01
	.byte 0x68, 0x17, 0xc1, 0xcd, 0x34, 0x3e, 0x04, 0xf1
	.byte 0x0c, 0x35, 0x00, 0x00, 0xf1, 0x42, 0x7f, 0x00
	.byte 0x23, 0x1e, 0xf9, 0x09, 0xc1, 0x88, 0x8d, 0x3e
	.byte 0x01, 0x0e, 0xc1, 0x0c, 0x35, 0x3f, 0x01, 0x66
	.byte 0x09, 0xc1, 0xd6, 0x34, 0x3f, 0x0b, 0x6b, 0x00
	.byte 0x68, 0x05, 0xf1, 0x0c, 0x35, 0x00, 0x00, 0x0e
	.byte 0xc1, 0x0c, 0x35, 0x3f, 0x01, 0x66, 0x02, 0x68
	.byte 0x00, 0x0e

RhythmFillIn_Wrapper:
	push xiz
	call RhythmFillIn_Select
	pop xiz
	ret

RhythmFillIn_Select:
	anddi8 0xe3e2, 247
	ld xwa, RhythmFillIn_PatternTable
	cps hl, 4
	jr c, RhythmFillIn_LookupAndApply
	sub hl, 0x4

RhythmFillIn_LookupAndApply:
	ldb_sri A, 0x07, 0xe0, 0xec
	stb_d8 0x379b, a
	calr DrumKit_UpdateStatusFlags
	call AudioInit_SelectAndDispatch
	call AudioMode_ResetVoiceState
	ret

RhythmFillIn_PatternTable:
	.byte 0x10, 0x04, 0x02, 0x01, 0x08, 0x10, 0x10, 0x10
	.byte 0x3e, 0x1d, 0x5c, 0x4f, 0xf6, 0x5e, 0x0e, 0xc1
	.byte 0xa7, 0x28, 0x3c, 0xfb, 0xc1, 0xe2, 0xe3, 0x3c
	.byte 0xfe, 0xc1, 0x37, 0x8d, 0x3f, 0xb5, 0x66, 0x1f
	.byte 0xc1, 0x88, 0x8d, 0x3e, 0x01, 0xf1, 0x83, 0x32
	.byte 0xc8, 0x6e, 0x14, 0xc1, 0xcd, 0x34, 0x3e, 0x80
	.byte 0x1d, 0xe1, 0x32, 0xf5, 0xc1, 0x37, 0x8d, 0x3f
	.byte 0xb2, 0x6e, 0x04, 0x1d, 0xcb, 0x9a, 0xf5, 0x0e

RhythmMute_Wrapper:
	push xiz
	call RhythmMute_Toggle
	pop xiz
	ret

RhythmMute_Toggle:
	calr RhythmMute_StateMachine
	ret

RhythmMute_StateMachine:
	ordi8 0xe3e2, 8
	incdi8 1, 0x34db
	cpdi8 0x34db, 4
	jr nz, RhythmMute_State1
	stdi8 0x34db, 0
	jr RhythmMute_StateDone

RhythmMute_State1:
	cpdi8 0x34db, 1
	jr nz, RhythmMute_State8
	stdi8 0x34db, 4
	jr RhythmMute_StateDone

RhythmMute_State8:
	cpdi8 0x34db, 8
	jr nz, RhythmMute_StateDone
	stdi8 0x34db, 1

RhythmMute_StateDone:
	ret

RhythmMute_InlineCode:
	ordi8	0xe3e2, 8
	bit	7, w
	jr	nz, 41
	cpdi8	0x34db, 0
	jr	nz, 7
	stdi8	0x34db, 4
	jr	25
	cpdi8	0x34db, 3
	jr	nz, 7
	stdi8	0x34db, 0
	jr	11
	cpdi8	0x34db, 7
	jr	z, 4
	incdi8	1, 0x34db
	jr	39
	cpdi8	0x34db, 0
	jr	nz, 7
	stdi8	0x34db, 3
	jr	25
	cpdi8	0x34db, 4
	jr	nz, 7
	stdi8	0x34db, 0
	jr	11
	cpdi8	0x34db, 1
	jr	z, 4
	.byte 0xc1, 0xdb
	ldw	ix, 0x0e69

RhythmSolo_Wrapper:
	push xiz
	calr RhythmSolo_Toggle
	pop xiz
	ret

RhythmSolo_Toggle:
	bitda 7, 0x34f1
	jr nz, RhythmSolo_Disable
	stdi8 0x34f1, 128
	jr RhythmSolo_UpdateStatus

RhythmSolo_Disable:
	stdi8 0x34f1, 0

RhythmSolo_UpdateStatus:
	calr DrumKit_UpdateStatusFlags
	bitda 0, 0x3283
	jr nz, RhythmSolo_Return
	ordi8 0x34cd, 128

RhythmSolo_Return:
	ret

RhythmVariation_Wrapper:
	push xiz
	calr RhythmVariation_Select
	pop xiz
	ret

RhythmVariation_Select:
	ldb_d8 a, 0x34cf
	and a, 0xc
	cps a, 0
	jr nz, RhythmVariation_Return
	ldb_d8 a, 0x35fc
	and a, 0xc
	cps a, 0
	jr nz, RhythmVariation_Return
	and hl, 0xf
	ld xwa, RhythmFillIn_PatternTable
	ldb_sri A, 0x07, 0xe0, 0xec
	stb_d8 0x379b, a
	calr DrumKit_UpdateStatusFlags
	bitda 0, 0x3283
	jr nz, RhythmVariation_PostDispatch
	ordi8 0x34cd, 128

RhythmVariation_PostDispatch:
	call AudioInit_SelectAndDispatch
	call AudioMode_ResetVoiceState

RhythmVariation_Return:
	ret

RhythmVariation_InlineCode:
	calr	64462
	ret
	push	xiz
	calr	2
	pop	xiz
	ret
	.byte 0xc1, 0x37, 0x8d
	push	xsp
	ld	(xiz), xiz
	ldwio	241, 0x3712
	nop
	.byte 0x04, 0xc1, 0x88, 0x8d
	push	xiz
	.byte 0x01, 0xc1, 0xe2, 0xe3
	push	xix
	swi	6
	.byte 0xc1, 0xcd
	ldw	ix, 2110
	ret
	push	xiz
	calr	2
	pop	xiz
	ret
	.byte 0xc1, 0xcd
	ldw	ix, 0xf73c
	ret
	push	xiz
	calr	2
	pop	xiz
	ret
	lds32	xhl, 0
	ldb_d8	l, 0x379b
	and	l, 31
	add	xhl, RhythmVariation_InlineCode_0x59
	ld	a, (xhl)
	stb_d8	0x379b, a
	call	AudioInit_SelectAndDispatch
	call	AudioMode_ResetVoiceState
	calr	64377
	ret
	nop
	ldio	1, 0
	push	sr
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
	ldb_d8	l, 0x379b
	and	l, 31
	add	xhl, RhythmVariation_InlineCode_0xA0
	ld	a, (xhl)
	stb_d8	0x379b, a
	call	AudioInit_SelectAndDispatch
	call	AudioMode_ResetVoiceState
	calr	64306
	ret
	nop
	push	sr
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
	.byte 0xc1
	ccf
	.byte 0x37
	push	xsp
	.byte 0x04
	jr	z, 2
	jr	41
	bit	7, w
	jr	nz, 18
	incdi8	1, 0x3714
	.byte 0xc1
	push_a
	.byte 0x37
	push	xsp
	decf
	jr	ule, 23
	stdi8	0x3714, 13
	jr	16
	decdi8	1, 0x3714
	.byte 0xc1
	push_a
	.byte 0x37
	push	xsp
	.byte 0x01
	jr	ge, 5
	stdi8	0x3714, 1
	jr	0
	ret
	push	xiz
	calr	2
	pop	xiz
	ret
	.byte 0xc1
	ccf
	.byte 0x37
	push	xsp
	.byte 0x04
	jr	nz, 41
	bit	7, w
	jr	nz, 18
	incdi8	1, 0x3715
	.byte 0xc1
	pop_a
	.byte 0x37
	push	xsp
	decf
	jr	ule, 23
	stdi8	0x3715, 13
	jr	16
	decdi8	1, 0x3715
	.byte 0xc1
	pop_a
	.byte 0x37
	push	xsp
	swi	7
	jr	nz, 5
	stdi8	0x3715, 0
	jr	0
	ret
	push	xiz
	calr	2
	pop	xiz
	ret
	.byte 0xc1
	ccf
	.byte 0x37
	push	xsp
	.byte 0x04
	jr	z, 2
	jr	41
	bit	7, w
	jr	nz, 18
	incdi8	1, 0x3716
	.byte 0xc1
	ex_ff
	.byte 0x37
	push	xsp
	pop	sr
	jr	ule, 23
	stdi8	0x3716, 3
	jr	16
	decdi8	1, 0x3716
	.byte 0xc1
	ex_ff
	.byte 0x37
	push	xsp
	swi	7
	jr	nz, 5
	stdi8	0x3716, 0
	jr	17
	bit	7, w
	jr	nz, 7
	.byte 0xc1
	pushw	iy
	.byte 0x37
	push	xiz
	rcf
	jr	5
	.byte 0xc1
	pushw	iy
	.byte 0x37
	push	xiz
	ldb	w, 14
	push	xiz
	call	RhythmVariation_InlineCode_0x182
	pop	xiz
	ret
	.byte 0xc1, 0x37, 0x8d
	push	xsp
	ld	(xix), xiz
	jp	0x3540f1
	nop
	.byte 0x01
	call	AccPatch_GetCurrentSlotAddr
	ld	l, (xiy+16)
	and	l, 255
	ld	h, (xiy+17)
	and	h, 127
	calr	1955
	calr	63983
	calr	1435
	ret

RhythmConfig_ReturnStub:
	ret

RhythmConfig_InlineCode2:
	push	xiz
	call	RhythmConfig_InlineCode2_0x7
	pop	xiz
	ret
	.byte 0xc1
	ldw	iz, 0x3f8d
	ld	(xix), xiz
	pop	sr
	calr	63651
	ret

DrumTempo_Adjust:
	push xiz
	push xix
	ldb_d8 a, 0x3540
	bit 7, w
	jr nz, DrumTempo_Decrement
	ldb l, 0x6
	ld xix, 0x94800
	add xix, 0x10
	bitm 0, (xix)
	jr nz, DrumTempo_CheckMax
	cpdi8 0x34d6, 11
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
	stb_d8 0x3540, a

DrumTempo_Done:
	pop xix
	pop xiz
	ret

DrumVoice_Select:
	push xiz
	xor hl, hl
	ldb_d8 l, 0x3540
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
	call	DrumVoice_Dispatch
	pop	xiz
	ret

DrumVoice_Dispatch:
	ordi8 0x8d88, 1
	pushw hl
	lds32 xhl, 0
	popw hl
	and l, 0xf
	sll xhl, 2
	add xhl, DrumVoice_DispatchTable
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
	ret
DrumVoice_Handler0:
	.byte 0xf1, 0xce
	ldw	ix, 0x66cf
	pushw	iz
	bit	7, w
	jr	nz, 18
	incdi8	1, 0x34d7
	.byte 0xc1, 0xd7
	ldw	ix, 1855
	jr	ule, 23
	stdi8	0x34d7, 7
	jr	16
	decdi8	1, 0x34d7
	.byte 0xc1, 0xd7
	ldw	ix, 63
	jr	ge, 5
	stdi8	0x34d7, 0
	.byte 0xc1, 0xce
	ldw	ix, 318
	jr	8
	stdi8	0x7f42, 19
	calr	1470
	ret
DrumVoice_Handler1:
	.byte 0xf1, 0xce
	ldw	ix, 0x66cf
	pushw	iz
	bit	7, w
	jr	nz, 18
	incdi8	1, 0x34d8
	.byte 0xc1, 0xd8
	ldw	ix, 2879
	jr	ule, 23
	stdi8	0x34d8, 11
	jr	16
	decdi8	1, 0x34d8
	.byte 0xc1, 0xd8
	ldw	ix, 1087
	jr	ge, 5
	stdi8	0x34d8, 4
	.byte 0xc1, 0xce
	ldw	ix, 574
	jr	8
	stdi8	0x7f42, 19
	calr	1409
	ret
DrumVoice_Handler2:
	.byte 0xc1, 0xe2, 0xe3
	push	xiz
	ldio	200, 51
	reti
	jr	nz, 18
	incdi8	1, 0x34e9
	.byte 0xc1, 0xe9
	ldw	ix, 2879
	jr	ule, 23
	stdi8	0x34e9, 11
	jr	16
	decdi8	1, 0x34e9
	.byte 0xc1, 0xe9
	ldw	ix, 63
	jr	ge, 5
	stdi8	0x34e9, 0
	.byte 0xc1, 0xd2
	ldw	ix, 318
	ret
DrumVoice_Handler3:
	.byte 0xc1, 0xe2, 0xe3
	push	xiz
	ldio	200, 51
	reti
	jr	nz, 7
	.byte 0xc1, 0xea
	ldw	ix, 4158
	jr	5
	.byte 0xc1, 0xea
	ldw	ix, 0xef3c
	.byte 0xc1, 0xd2
	ldw	ix, 574
	ret
DrumVoice_Handler5:
	.byte 0xc1, 0xe2, 0xe3
	push	xix
	ldx
	bit	7, w
	jr	nz, 18
	.byte 0xf1, 0xea
	ldw	ix, 0x6ecd
	.byte 0x1c, 0xc1, 0xea
	ldw	ix, 8254
	.byte 0xc1
	decdi16_24	8, 0x043e34
	rcf
	.byte 0xf1, 0xea
	ldw	ix, 0x66cd
	ldwio	193, 0x34ea
	push	xix
	.byte 0xdf, 0xc1, 0xd2
	ldw	ix, 1086
	ret
DrumVoice_Handler4:
	.byte 0xc1, 0xe2, 0xe3
	push	xix
	ldx
	bit	7, w
	jr	nz, 18
	.byte 0xf1, 0xea
	ldw	ix, 0x6ece
	.byte 0x1c, 0xc1, 0xea
	ldw	ix, 0x403e
	.byte 0xc1
	decdi16_24	8, 0x043e34
	rcf
	.byte 0xf1, 0xea
	ldw	ix, 0x66ce
	ldwio	193, 0x34ea
	push	xix
	.byte 0xbf, 0xc1, 0xd2
	ldw	ix, 1086
	ret
	.byte 0xc1, 0xe2, 0xe3
	push	xiz
	ldio	193, 234
	ldw	ix, 0xc921
	inc	8, d
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
	.byte 0xc1, 0xea
	ldw	ix, 0x9f3c
	orddm8	0x34ea, a
	.byte 0xc1, 0xd2
	ldw	ix, 1086
	ret
DrumVoice_Handler6:
	.byte 0xc1, 0xe2, 0xe3
	push	xiz
	ldio	193, 226
	.byte 0xe3
	push	xiz
	.byte 0x01
	stdi16	0xe3e4, 1927
	stdi16	0xe3e4, 1670
	ld	xiy, 0x094800
	add	xiy, 16
	ld	a, (xiy)
	bit	0, a
	jr	nz, 9
	calr	722
	calr	63352
	calr	804
	ret
DrumVoice_Handler7:
	.byte 0xc1, 0xe2, 0xe3
	push	xiz
	ldio	193, 226
	.byte 0xe3
	push	xiz
	.byte 0x01
	stdi16	0xe3e4, 1927
	ld	xiy, 0x094800
	add	xiy, 16
	ld	a, (xiy)
	bit	0, a
	jr	nz, 9
	calr	839
	calr	63308
	calr	760
	ret
	push	xiz
	.byte 0xf1, 0xd3
	ldw	ix, 0x6ec8
	ldwio	193, 0x34d6
	push	xsp
	incf
	jr	nc, 3
	calr	2
	pop	xiz
	ret
	.byte 0xc1, 0x88, 0x8d
	push	xiz
	.byte 0x01, 0xc1, 0xe2, 0xe3
	push	xix
	ldx
	ld	xiy, 0x094800
	add	xiy, 16
	ld	a, (xiy)
	bit	0, a
	jr	nz, 10
	.byte 0xc1, 0xd6
	ldw	ix, 3135
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
	.byte 0xc1, 0xe2, 0xe3
	push	xix
	swi	6
	ret
	push	xiz
	call	DrumVoice_Handler7_0x7C
	pop	xiz
	ret
	.byte 0xc1, 0x37, 0x8d
	push	xsp
	.byte 0xb8
	jr	z, 22
	calr	1565
	ldb_d8	l, 0x34ed
	ldb_d8	h, 0x34ee
	calr	1168
	calr	63200
	.byte 0xc1, 0xcd
	ldw	ix, 0xbf3c
	calr	1520
	calr	4
	calr	1537
	ret
	ldb_d8	a, 0xfc5a
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
	ld	xix, DrumVoice_Handler7_0xE2
	.byte 0xc3
	pop	sr
	.byte 0xf0, 0xe0
	ldb	a, 241
	pop	xde
	swi	4
	ld	xbc, 0x4134edf1
	and	a, 127
	stb_d8	0xffa1, a
	stb_d8	0xffbf, a
	calr	63123
	ret
	.byte 0x80, 0x80, 0x80, 0x80, 0x84, 0x84, 0x84
	add	(xix), w
	add	(xwa-120), w
	push	xiz
	call	DrumVoice_Handler7_0xF5
	pop	xiz
	ret
	.byte 0xc1
	ldw	iz, 0x3f8d
	.byte 0xb8
	jr	z, 3
	calr	62783
	ret
	push	xiz
	call	DrumVoice_Handler7_0x107
	pop	xiz
	ret
	ldb_d8	a, 0x39a7
	bit	7, w
	jr	z, 8
	cps	a, 2
	jr	z, 14
	inc	1, a
	jr	6
	cps	a, 0
	jr	z, 6
	dec	1, a
	stb_d8	0x39a7, a
	ret
	push	xiz
	call	DrumVoice_Handler7_0x12A
	pop	xiz
	ret
	ldb_d8	a, 0x39a7
	sll	a, 1
	ld	xix, DrumVoice_Handler7_0x140
	.byte 0xd3
	pop	sr
	.byte 0xf0, 0xe0
	ldb	c, 29
	ld	xbc, 0x0ef656
	nop
	.byte 0x01
	nop
	push	sr
	nop
	push	xiz
	call	DrumVoice_Handler7_0x14D
	pop	xiz
	ret
	ldb_d8	a, 0x39a8
	bit	7, w
	jr	z, 8
	cps	a, 1
	jr	z, 14
	inc	1, a
	jr	6
	cps	a, 0
	jr	z, 6
	dec	1, a
	stb_d8	0x39a8, a
	ret
	push	xiz
	call	DrumVoice_Handler7_0x170
	pop	xiz
	ret
	ldb_d8	a, 0x39a8
	sll	a, 1
	ld	xix, DrumVoice_Handler7_0x186
	.byte 0xd3
	pop	sr
	.byte 0xf0, 0xe0
	ldb	c, 29
	ld	xbc, 0x030ef656
	nop
	.byte 0x04
	nop
	push	xiz
	call	DrumVoice_Handler7_0x191
	pop	xiz
	ret
	pushw	hl
	lds32	xhl, 0
	popw	hl
	and	hl, 7
	sll	hl, 2
	add	xhl, DrumVoice_Handler7_0x1A7
	ld	xhl, (xhl)
	call	(xhl)
	ret
	jrl	ule, -2474
	nop
	.byte 0x90, 0x56, 0xf6
	nop
	.byte 0xaa, 0x56, 0xf6
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
	.byte 0xc1, 0xe2, 0xe3
	push	xiz
	ldio	193, 226
	.byte 0xe3
	push	xiz
	.byte 0x01
	stdi16	0xe3e4, 128
	calr	889
	calr	62875
	calr	1200
	calr	1384
	ret
	.byte 0xc1, 0xe2, 0xe3
	push	xiz
	ldio	193, 226
	.byte 0xe3
	push	xiz
	.byte 0x01
	stdi16	0xe3e4, 385
	calr	1010
	calr	62846
	calr	1171
	ret
	.byte 0xc1, 0xe2, 0xe3
	push	xiz
	ldio	193, 226
	.byte 0xe3
	push	xiz
	.byte 0x01
	stdi16	0xe3e4, 642
	calr	1359
	ret
	.byte 0xc1, 0xe2, 0xe3
	push	xiz
	.byte 0x01
	stdi16	0xe3e4, 0x8505
	calr	1573
	ret
	.byte 0xc1, 0xe2, 0xe3
	push	xiz
	ldio	193, 226
	.byte 0xe3
	push	xiz
	.byte 0x01
	stdi16	0xe3e4, 1670
	calr	1668
	ret
	push	xiz
	call	DrumVoice_Handler7_0x238
	pop	xiz
	ret
	.byte 0xc1, 0x37, 0x8d
	push	xsp
	.byte 0xbd
	jr	z, 33
	.byte 0xc1, 0xcd
	ldw	ix, 0xbf3c
	ld	xix, 0x094800
	add	xix, 16
	ld	a, (xix)
	.byte 0xc1, 0xd3
	ldw	ix, 0xfe3c
	bit	0, a
	jr	z, 5
	.byte 0xc1, 0xd3
	ldw	ix, 318
	.byte 0xc1, 0xe2, 0xe3
	push	xix
	.byte 0xde
	ret
	ret
	ret
	push	xiz
	call	DrumVoice_Handler7_0x26F
	pop	xiz
	ret
	.byte 0xc1, 0x37, 0x8d
	push	xsp
	.byte 0xbb
	jr	z, 5
	.byte 0xc1, 0xcd
	ldw	ix, 0xbf3c
	.byte 0xc1
	push	xbc
	.byte 0x8d
	push	xsp
	ld	(xhl+102), 193
	.byte 0xe2, 0xe3
	push	xix
	swi	6
	ret
	.byte 0xc1, 0xe2, 0xe3
	push	xiz
	ldio	193, 186
	swi	5
	ldb	a, 201
	.byte 0xcc
	retd	0x88c9
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
	stb_d8	0xfdba, a
	cp	a, w
	jr	z, 10
	ldb	w, 15
	ldb	e, 145
	ldb	d, 4
	call	SwbtWr_QueuePostEvent
	ret
	ret
	stdi8	0x34d6, 0
	calr	62324
	ret
	push	w
	ldb_d8	l, 0xfc5a
	and	l, 255
	ldb_d8	h, 0xfc5b
	and	h, 127
	ldb	a, 72
	stb_d8	0x90f7, a
	call	PartCtrl_WriteProgramChange
	pop	w
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
	ld	xix, 0xff92
	.byte 0xc3
	pop	sr
	.byte 0xf0, 0xec
	ldb	h, 33
	popw	wa
	stb_d8	0x90f6, a
	call	SndParam_ApplyProgramChange_Safe
	and	l, 255
	stb_d8	0xfc5a, l
	and	h, 127
	stb_d8	0xfc5b, h
	ret
	ldb_d8	l, 0xfc5a
	and	l, 255
	ldb_d8	h, 0xfc5b
	and	h, 127
	sll	l, 1
	sll	hl, 1
	ld	xiy, Display_FontPalette_Table_0x2EA
	.byte 0xd3
	reti
	.byte 0xf4, 0xec
	ldb	w, 219
	.byte 0xc8
	push	sr
	nop
	lds32	xde, 0
	.byte 0xd3
	reti
	.byte 0xf4, 0xec
	ldb	b, 201
	and	(xwa-24), d
	nop
	swi	7
	nop
	nop
	sll	xwa, 8
	ld	xix, 0x400000
	add	xix, xwa
	add	xix, xde
	jr	0
	ld	a, (xix+976)
	stb_d8	0x34f0, a
	ret
	push	w
	ldb_d8	l, 0xfc5a
	and	l, 255
	ldb_d8	h, 0xfc5b
	and	h, 127
	ldb	a, 72
	stb_d8	0x90f7, a
	call	PartCtrl_WriteProgramChange
	ld	a, h
	pushw	hl
	call	AccVoice_GetChannelCount_Direct
	stb_d8	0x342d, l
	popw	hl
	pop	w
	bit	7, w
	jr	nz, 14
	inc	1, a
	.byte 0xc1
	pushw	iy
	ldw	ix, 0x63f1
	retd	0x2dc1
	ldw	ix, 0x6821
	push	201
	jr	ge, -55
	.byte 0xcf
	swi	7
	jr	nz, 2
	ldb	a, 0
	ld	h, a
	ld	xwa, 0xff92
	.byte 0xf3
	pop	sr
	.byte 0xe0, 0xec
	ld	xiz, 0xf6f14821
	.byte 0x90
	ld	xbc, 0xfca18c1d
	and	l, 255
	stb_d8	0xfc5a, l
	and	h, 127
	stb_d8	0xfc5b, h
	ret
	ldb_d8	l, 0x34f0
	and	l, 31
	xor	h, h
	sll	hl, 3
	ld	xbc, TimeSig_DisplayStrings
	add	xbc, 7
	.byte 0xc3
	reti
	.byte 0xe4, 0xec
	ldb	w, 193
	.byte 0xd8
	ldw	ix, 0xcf27
	.byte 0xcc, 0x1f
	xor	h, h
	sll	hl, 3
	ld	xbc, TimeSig_DisplayStrings
	add	xbc, 7
	.byte 0xc3
	reti
	.byte 0xe4, 0xec
	ldb	a, 200
	.byte 0xf1
	jr	nz, 34
	call	AccPatch_GetCurrentSlotAddr
	ldb_d8	a, 0xfc5a
	and	a, 255
	ld	(xiy+16), a
	ldb_d8	a, 0xfc5b
	and	a, 127
	ld	(xiy+17), a
	stdi8	0x7f42, 21
	calr	17
	jr	14
	stdi8	0x7f42, 22
	calr	7
	ldb	a, 8
	call	MIDI_SendSysExCmd
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
	ldb a, 0xee
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
	push	sr
	.ascii "(2/2)+0  "
	.byte 0x04
	.ascii "(3/2)+0  "
	.byte 0x06
	pushw	wa
	.byte 0x34
	.ascii "/2)+0  "
	.byte 0x08
	.ascii "(1/4)+0  "
	.byte 0x01
	.ascii "(2/4)+0  "
	push	sr
	.ascii "(3/4)+0  "
	pop	sr
	pushw	wa
	.byte 0x34
	.ascii "/4)+0  "
	.byte 0x04
	.ascii "(5/4)+0  "
	halt
	.ascii "(6/4)+0  "
	.byte 0x06
	.ascii "(7/4)+0  "
	reti
	pushw	wa
	push	xwa
	.ascii "/4)+0  "
	.byte 0x08
	.ascii "(2/8)+0  "
	.byte 0x01
	.ascii "(4/8)+0  "
	push	sr
	.ascii "(6/8)+0  "
	pop	sr
	pushw	wa
	push	xwa
	.ascii "/8)+0  "
	.byte 0x04
	.ascii "(10/8)+0 "
	halt
	.ascii "(12/8)+0 "
	.byte 0x06
	.ascii "(14/8)+0 "
	reti
	pushw	wa
	.byte 0x31
	.ascii "6/8)+0 "
	ldio	29, 229
	ldw	de, 0xf1f5
	pop	xde
	swi	4
	ld	xsp, 0xc17fccce
	pop	xhl
	swi	4
	push	xix
	.byte 0x80
	orddm8	0xfc5b, h
	stdi8	0x90f7, 72
	call	PartCtrl_WriteProgramChange
	ld	w, h
	extz	hl
	extz	xhl
	add	xhl, 0xff92
	jr	0
	ld	(xhl), w
	ret
	push	w
	ldb_d8	l, 0xfc5a
	and	l, 255
	ldb_d8	h, 0xfc5b
	and	h, 127
	ldb	a, 72
	stb_d8	0x90f7, a
	call	PartCtrl_WriteProgramChange
	pop	w
	bit	7, w
	jr	nz, 20
	inc	1, l
	cp	l, 14
	jr	nz, 4
	ldb	l, 15
	jr	27
	cp	l, 16
	jr	c, 22
	ldb	l, 15
	jr	18
	dec	1, l
	cp	l, 14
	jr	nz, 4
	ldb	l, 13
	jr	7
	cp	l, 255
	jr	nz, 2
	ldb	l, 0
	ld	a, l
	ld	xix, 0xff92
	.byte 0xc3
	pop	sr
	.byte 0xf0, 0xec
	ldb	h, 201
	.byte 0x8f
	ldb	a, 72
	stb_d8	0x90f6, a
	call	SndParam_ApplyProgramChange_Safe
	and	l, 255
	stb_d8	0xfc5a, l
	and	h, 127
	stb_d8	0xfc5b, h
	.byte 0xc1, 0xef
	ldw	ix, 6719
	jr	z, 33
	.byte 0xc1
	pop	xde
	swi	4
	push	xsp
	incm8	7, (xwa)
	ret
	.byte 0xc1, 0xef
	ldw	ix, 4159
	jr	nc, 19
	stdi8	0x34ef, 16
	jr	12
	.byte 0xc1, 0xef
	ldw	ix, 4159
	jr	c, 5
	stdi8	0x34ef, 0
	ret
	push	w
	ldb_d8	l, 0xfc5a
	and	l, 255
	ldb_d8	h, 0xfc5b
	and	h, 127
	ldb	a, 72
	stb_d8	0x90f7, a
	call	PartCtrl_WriteProgramChange
	ld	a, h
	pushw	hl
	call	AccVoice_GetChannelCount_Direct
	stb_d8	0x342d, l
	popw	hl
	pop	w
	bit	7, w
	jr	nz, 33
	cp	l, 15
	jr	nz, 14
	push	xix
	ld	xix, TimeSig_DisplayStrings_0x21B
	.byte 0xc3
	pop	sr
	.byte 0xf0, 0xe0
	.ascii "!\\h*ÉaÁ-"
	ldw	ix, 0x63f1
	ldb	b, 193
	pushw	iy
	ldw	ix, 0x6821
	.byte 0x1c
	cp	l, 15
	jr	nz, 14
	push	xix
	ld	xix, TimeSig_DisplayStrings_0x227
	.byte 0xc3
	pop	sr
	.byte 0xf0, 0xe0
	ldb	a, 92
	jr	9
	dec	1, a
	cp	a, 255
	jr	nz, 2
	ldb	a, 0
	ld	h, a
	ld	xwa, 0xff92
	.byte 0xf3
	pop	sr
	.byte 0xe0, 0xec
	ld	xiz, 0xf6f14821
	.byte 0x90
	ld	xbc, 0xfca18c1d
	and	l, 255
	stb_d8	0xfc5a, l
	and	h, 127
	stb_d8	0xfc5b, h
	ret
	.byte 0x04, 0x04, 0x04, 0x04
	ldio	8, 8
	ldio	8, 8
	ldio	8, 0
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x04, 0x04, 0x04, 0x04
	ldb_d8	a, 0xfc5a
	and	a, 255
	ldb_d8	w, 0xfc5b
	and	w, 127
	stb_d8	0x34ed, a
	stb_d8	0x34ee, w
	ret
	ldb_d8	l, 0x34ed
	and	l, 255
	cp	l, 240
	jr	c, 11
	ldb	l, 128
	stb_d8	0x34ed, l
	stdi8	0x34ee, 0
	cp	l, 128
	jr	c, 16
	ldb_d8	a, 0x34ee
	and	a, 127
	cps	a, 0
	jr	z, 5
	stdi8	0x34ee, 0
	cp	l, 128
	jr	c, 100
	.byte 0xc1, 0xef
	ldw	ix, 4159
	jr	nc, 5
	stdi8	0x34ef, 26
	.byte 0xc1, 0xef
	ldw	ix, 6719
	jr	nz, 37
	ldb_d8	a, 0x34cd
	and	a, 48
	cps	a, 0
	jr	z, 12
	cp	a, 32
	jr	z, 14
	stdi8	0x34d6, 32
	jr	72
	stdi8	0x34d6, 30
	jr	65
	stdi8	0x34d6, 31
	jr	58
	.byte 0xc1, 0xd6
	ldw	ix, 7743
	jr	c, 51
	ldb_d8	a, 0x34cd
	and	a, 48
	cps	a, 0
	jr	z, 19
	cp	a, 32
	jr	z, 7
	stdi8	0x34d6, 8
	jr	28
	stdi8	0x34d6, 4
	jr	21
	stdi8	0x34d6, 0
	jr	14
	.byte 0xc1, 0xef
	ldw	ix, 4159
	jr	c, 5
	stdi8	0x34ef, 26
	jr	-102
	ret
	ret
	.byte 0xc1, 0xed
	ldw	ix, 0x803f
	jr	c, 12
	.byte 0xc1, 0xef
	ldw	ix, 2623
	jr	c, 5
	stdi8	0x34ef, 0
	ret
	push	w
	ldb_d8	l, 0xfc5a
	and	l, 255
	ldb_d8	h, 0xfc5b
	and	h, 127
	ldb	a, 72
	stb_d8	0x90f7, a
	call	PartCtrl_WriteProgramChange
	pushw	hl
	call	AccVoice_GetChannelCount_Direct
	stb_d8	0x342d, h
	popw	hl
	ld	a, l
	cp	a, 15
	jr	lt, 12
	stdi8	0x342e, 25
	stdi8	0x342f, 16
	jr	10
	stdi8	0x342e, 15
	stdi8	0x342f, 0
	ldb_d8	a, 0x34ef
	pop	w
	bit	7, w
	jr	nz, 45
	cp	a, 26
	jr	nz, 26
	push	xix
	ldb_d8	a, 0x34d6
	ld	xix, TimeSig_DisplayStrings_0x3C7
	.byte 0xc3
	pop	sr
	.byte 0xf0, 0xe0
	ldb	a, 241
	.byte 0xd6
	ldw	ix, 0x5c41
	.byte 0xc1
	.ascii "/4!h3"
	inc	1, a
	.byte 0xc1
	pushw	iz
	ldw	ix, 0x63f1
	pushw	hl
	.byte 0xc1
	pushw	iz
	.ascii "4!h%"
	cp	a, 26
	jr	z, 32
	dec	1, a
	.byte 0xc1
	pushw	sp
	ldw	ix, 0x69f1
	push_f
	push	xix
	ldb_d8	a, 0x34d6
	ld	xix, TimeSig_DisplayStrings_0x3A6
	.byte 0xc3
	pop	sr
	.byte 0xf0, 0xe0
	ldb	a, 241
	.byte 0xd6
	ldw	ix, 0x5c41
	ldb	a, 26
	jr	0
	stb_d8	0x34ef, a
	ret
	calr	7710
	calr	7967
	.byte 0x1f, 0x1f
	ldb	w, 32
	ldb	w, 32
	calr	7710
	calr	7710
	.byte 0x1f, 0x1f, 0x1f, 0x1f, 0x1f, 0x1f
	ldb	w, 32
	.ascii "    "
	calr	8223
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
	ldio	200, 51
	reti
	jr	nz, 58
	.byte 0xf1, 0xcd
	ldw	ix, 0x66cd
	ex_ff
	.byte 0xc1, 0xcd
	ldw	ix, 0xcf3c
	.byte 0xc1, 0xcd
	ldw	ix, 4158
	stdi8	0x34d6, 32
	stdi8	0x34ef, 26
	jr	81
	.byte 0xf1, 0xcd
	ldw	ix, 0x66cc
	push	sr
	jr	73
	.byte 0xc1, 0xcd
	ldw	ix, 0xcf3c
	.byte 0xc1, 0xcd
	ldw	ix, 8254
	stdi8	0x34d6, 31
	stdi8	0x34ef, 26
	jr	51
	.byte 0xf1, 0xcd
	ldw	ix, 0x66cd
	scf
	.byte 0xc1, 0xcd
	ldw	ix, 0xcf3c
	stdi8	0x34d6, 30
	stdi8	0x34ef, 26
	jr	28
	.byte 0xf1, 0xcd
	ldw	ix, 0x66cc
	ex_ff
	.byte 0xc1, 0xcd
	ldw	ix, 0xcf3c
	.byte 0xc1, 0xcd
	ldw	ix, 8254
	stdi8	0x34d6, 31
	stdi8	0x34ef, 26
	jr	0
	ret
	ldb_d8	a, 0x34d6
	.byte 0xf1, 0xcd
	ldw	ix, 0x66cc
	halt
	calr	204
	jr	14
	.byte 0xf1, 0xcd
	ldw	ix, 0x66cd
	halt
	calr	115
	jr	3
	calr	5
	stb_d8	0x34d6, a
	ret
	bit	7, w
	jr	nz, 33
	inc	1, a
	cp	a, 31
	jr	nz, 7
	calr	65
	ldb	a, 0
	jr	17
	cps	a, 4
	jr	nz, 4
	ldb	a, 12
	jr	9
	cp	a, 18
	jr	lt, 4
	ldb	a, 17
	jr	0
	jr	41
	dec	1, a
	cp	a, 29
	jr	nz, 4
	ldb	a, 30
	jr	30
	cp	a, 255
	jr	nz, 9
	ldb	a, 30
	stdi8	0x34ef, 26
	jr	16
	cp	a, 11
	jr	nz, 4
	ldb	a, 3
	jr	7
	cp	a, 18
	jr	lt, 2
	ldb	a, 17
	ret
	ldb_d8	a, 0xfc5a
	and	a, 255
	cp	a, 128
	jr	c, 7
	stdi8	0x34ef, 16
	jr	5
	stdi8	0x34ef, 0
	ret
	bit	7, w
	jr	nz, 32
	inc	1, a
	cp	a, 32
	jr	nz, 7
	calr	65496
	ldb	a, 4
	jr	16
	cp	a, 8
	jr	nz, 4
	ldb	a, 18
	jr	7
	cp	a, 24
	jr	lt, 2
	ldb	a, 23
	jr	40
	dec	1, a
	cp	a, 30
	jr	nz, 4
	ldb	a, 31
	jr	29
	cps	a, 3
	jr	nz, 9
	ldb	a, 31
	stdi8	0x34ef, 26
	jr	16
	cp	a, 17
	jr	nz, 4
	ldb	a, 7
	jr	7
	cp	a, 24
	jr	lt, -40
	ldb	a, 23
	ret
	bit	7, w
	jr	nz, 34
	inc	1, a
	cp	a, 33
	jr	nz, 7
	calr	65418
	ldb	a, 8
	jr	18
	cp	a, 12
	jr	nz, 4
	ldb	a, 24
	jr	9
	cp	a, 30
	jr	lt, 4
	ldb	a, 29
	jr	0
	jr	42
	dec	1, a
	cp	a, 31
	jr	nz, 4
	ldb	a, 32
	jr	31
	cps	a, 7
	jr	nz, 9
	ldb	a, 32
	stdi8	0x34ef, 26
	jr	18
	cp	a, 23
	jr	nz, 4
	ldb	a, 11
	jr	9
	cp	a, 30
	jr	lt, -40
	ldb	a, 29
	jr	0
	ret
	call	AccWrap_PlayModeDispatch
	.byte 0xc1, 0xa7
	pushw	wa
	push	xiz
	.byte 0x04
	ldb_d8	a, 0xfc5a
	and	a, 15
	stb_d8	0x390a, a
	call	TimeSig_DisplayStrings_0x5CC
	stda32	0x391e, xiy
	add	xiy, 16
	stda32	0x3922, xiy
	.byte 0xf1
	ldb	h, 57
	dec	6, w
	ccf
	lds32	xbc, 4
	ldda32	xiy, 0x391e
	ld	xix, 0x390e
	.byte 0x85
	scf
	stdi8	0x390d, 0
	.byte 0xc1
	ldb	h, 57
	push	xix
	swi	6
	ret
	ret
	ret
	lds32	xwa, 0
	lds32	xbc, 0
	ldb	a, 32
	ldb_d8	c, 0x390a
	mul8rr	a, c
	add	xwa, 0x094800
	add	xwa, 2976
	ld	xiy, xwa
	ret
	ldb_d8	a, 0x390c
	ld	xiy, 0x390e
	.byte 0xc3
	pop	sr
	.byte 0xf4, 0xe0
	ldb	c, 241
	push	57
	ld	xhl, 0x390bc10e
	ldb	a, 69
	ret
	push	xbc
	nop
	nop
	.byte 0xc3
	pop	sr
	.byte 0xf4, 0xe0
	ldb	c, 241
	ldio	57, 67
	ret
	.byte 0xc1, 0xa7
	pushw	wa
	push	xix
	swi	3
	.byte 0xc1
	ldb	h, 57
	push	xix
	swi	6
	ret
	ldb_d8	a, 0x390a
	bit	7, w
	jr	nz, 12
	cps	a, 4
	jr	nc, 4
	inc	1, a
	jr	2
	ldb	a, 4
	jr	10
	cps	a, 0
	jr	ule, 4
	dec	1, a
	jr	2
	ldb	a, 0
	stb_d8	0x390a, a
	or	a, 240
	stb_d8	0xfc5a, a
	ldb	a, 0
	stb_d8	0xfc5b, a
	calr	60624
	stdi8	0x390d, 0
	ret
	push	w
	calr	65444
	pop	w
	bit	7, w
	jr	nz, 34
	.byte 0xc1
	ldio	57, 63
	pushw	1647
	incdi8	1, 0x3908
	jr	19
	.byte 0xc1
	ldio	57, 63
	swi	7
	jr	nz, 7
	stdi8	0x3908, 0
	jr	5
	stdi8	0x3908, 11
	jr	32
	.byte 0xc1
	ldio	57, 63
	nop
	jr	le, 6
	decdi8	1, 0x3908
	jr	19
	.byte 0xc1
	pushw	0x3f39
	nop
	jr	nz, 7
	stdi8	0x3908, 0
	jr	5
	stdi8	0x3908, 255
	ldb_d8	a, 0x3908
	stb_d8	0x3909, a
	ld	xix, 0x390e
	ldb_d8	c, 0x390b
	.byte 0xf3
	pop	sr
	.byte 0xf0, 0xe4
	ld	xbc, 0x390e44
	nop
	calr	6
	.byte 0xc1
	ldb	h, 57
	push	xiz
	.byte 0x01
	ret
	stdi8	0x390d, 0
	ldb	h, 0
	calr	63
	ld	wa, bc
	pushw	wa
	ldb	h, 1
	calr	55
	popw	wa
	cp	bc, 0xffff
	jr	z, 7
	cp	bc, wa
	jr	z, 3
	calr	81
	pushw	wa
	ldb	h, 2
	calr	35
	popw	wa
	cp	bc, 0xffff
	jr	z, 7
	cp	bc, wa
	jr	z, 3
	calr	61
	pushw	wa
	ldb	h, 3
	calr	15
	popw	wa
	cp	bc, 0xffff
	jr	z, 7
	cp	bc, wa
	jr	z, 3
	calr	41
	ret
	.byte 0xc3
	pop	sr
	.byte 0xf0, 0xed
	ldb	l, 207
	.byte 0xcf
	swi	7
	jr	z, 26
	.byte 0xc1, 0xd6
	ldw	ix, 0xf104
	.byte 0xd6
	ldw	ix, 0xce47
	.byte 0x04
	push	xix
	call	AccPatch_SlotScanByteData_0x38
	pop	xix
	pop	h
	.byte 0xf1, 0xd6
	ldw	ix, 0xc904
	.byte 0x8a
	jr	3
	ldw	bc, 0xffff
	ret
	push	xwa
	ld	xwa, TimeSig_DisplayStrings_0x745
	.byte 0xc3
	pop	sr
	.byte 0xe0, 0xed
	ldb	a, 193
	decf
	push	xbc
	.byte 0xe9
	pop	xwa
	ret
	.byte 0x01
	push	sr
	.byte 0x04
	ldio	8, 8
	ldio	8, 62
	call	TimeSig_DisplayStrings_0x754
	pop	xiz
	ret
	ret
	.byte 0xc1
	ldwio	57, 0xc104
	pushw	1081
	stdi8	0x390a, 0
	.byte 0xc1
	ldwio	57, 1343
	jr	z, 19
	calr	65120
	ld	xix, xiy
	push	xix
	calr	65361
	pop	xix
	calr	20
	incdi8	1, 0x390a
	jr	-26
	.byte 0xf1
	pushw	1081
	.byte 0xf1
	ldwio	57, 0xf104
	decf
	push	xbc
	nop
	nop
	ret
	.byte 0xf1
	decf
	push	xbc
	inc	6, a
	push	34
	swi	7
	ldb	a, 1
	.byte 0xf3
	pop	sr
	.byte 0xf0, 0xe0
	ld	xde, 0xca390df1
	jr	z, 9
	ldb	b, 255
	ldb	a, 2
	.byte 0xf3
	pop	sr
	.byte 0xf0, 0xe0
	ld	xde, 0xcb390df1
	jr	z, 9
	ldb	b, 255
	ldb	a, 3
	.byte 0xf3
	pop	sr
	.byte 0xf0, 0xe0
	ld	xde, 0xe1ace90e
	calr	9273
	ld	xiy, 0x390e
	.byte 0x85
	scf
	ret
	push	xiz
	call	TimeSig_DisplayStrings_0x7CD
	pop	xiz
	ret
	calr	15
	calr	60294
	call	AudioInit_SelectAndDispatch
	call	AudioMode_ResetVoiceState
	calr	60717
	ret
	stdi8	0x379b, 1
	.byte 0xf1, 0xc9, 0x37
	dec	6, d
	ldb	h, 241
	.byte 0x9b, 0x37
	nop
	push	sr
	.byte 0xf1, 0xc9, 0x37
	dec	6, e
	jp	0x379bf1
	nop
	.byte 0x04, 0xf1, 0xc9, 0x37
	dec	6, h
	rcf
	stdi8	0x379b, 8
	.byte 0xf1, 0xc9, 0x37
	dec	6, c
	halt
	stdi8	0x379b, 16
	ret
	stdi8	0x37c9, 16
	.byte 0xf1
	and	(xhl+55), wa
	jr	nz, 38
	stdi8	0x37c9, 32
	.byte 0xf1
	and	(xhl+55), bc
	jr	nz, 27
	stdi8	0x37c9, 64
	.byte 0xf1
	and	(xhl+55), de
	jr	nz, 16
	stdi8	0x37c9, 8
	.byte 0xf1
	and	(xhl+55), hl
	jr	nz, 5
	stdi8	0x37c9, 1
	ret
	push	xiz
	call	TimeSig_DisplayStrings_0x84A
	pop	xiz
	ret
	ldb_d8	a, 0x39aa
	bit	7, w
	jr	nz, 8
	cps	a, 3
	jr	z, 14
	inc	1, a
	jr	6
	cps	a, 0
	jr	z, 6
	dec	1, a
	stb_d8	0x39aa, a
	ret
	push	xiz
	call	TimeSig_DisplayStrings_0x86D
	pop	xiz
	ret
	pushw	wa
	call	AccPatch_GetCurrentSlotAddr
	popw	wa
	ld	xix, TimeSig_DisplayStrings_0x8A0
	ldb_d8	a, 0x39aa
	.byte 0xc3
	pop	sr
	.byte 0xf0, 0xe0
	ldb	a, 195
	pop	sr
	.byte 0xf4, 0xe0
	ldb	l, 200
	ldw	hl, 0x6e07
	push	207
	scc8	nc, l
	jr	z, 15
	inc	1, l
	jr	6
	cps	l, 0
	jr	z, 7
	dec	1, l
	.byte 0xf3
	pop	sr
	.byte 0xf4, 0xe0
	ld	xsp, 0x322a220e
	push	xde
	push	xiz
	call	TimeSig_DisplayStrings_0x8AB
	pop	xiz
	ret
	pushw	wa
	call	AccPatch_GetCurrentSlotAddr
	popw	wa
	ld	xix, TimeSig_DisplayStrings_0x8DE
	ldb_d8	a, 0x39aa
	.byte 0xc3
	pop	sr
	.byte 0xf0, 0xe0
	ldb	a, 195
	pop	sr
	.byte 0xf4, 0xe0
	ldb	l, 200
	ldw	hl, 0x6e07
	push	207
	divs	l, 102
	retd	0x61cf
	jr	6
	cps	l, 0
	jr	z, 7
	dec	1, l
	.byte 0xf3
	pop	sr
	.byte 0xf4, 0xe0
	ld	xsp, 0x352d250e
	push	xiy
	ldb_d8	a, 0x8d36
	.byte 0xc1, 0x37, 0x8d, 0xf1
	ret	z
	ldb_da	a, 0xffe3
	inc	1, a
	stb_d8	0x3989, a
	ldw_d16	wa, 0x398a
	cps	wa, 0
	ret	nz
	stdi16	0x398a, 1
	stdi16	0x398c, 1
	stdi8	0x398e, 25
	stdi8	0x398f, 0
	stdi8	0x3990, 0
	stdi8	0x3991, 0
	stdi8	0x3992, 0
	stdi8	0x3993, 0
	stdi8	0x3994, 0
	stdi8	0x3995, 0
	ret
	ret
	ld	de, wa
	cp	de, 23
	ret	ugt
	and	bc, 128
	cps	bc, 0
	scc8	nz, a
	extz	wa
	ld	bc, de
	extz	xbc
	sll	xbc, 2
	ld	xde, Display_FontPalette_Table_0x51EC
	add	xde, xbc
	ld	xhl, (xde)
	call	(xhl)
	ret

Tempo_AdjustStartMeasure:
	dec 2, xsp
	ld (xsp), a
	ldw wa, 0x80
	lds bc, 0
	calr Tempo_DisplayParamCommon
	ldw_d16 xwa, 0x398a
	cp (xsp), 0x0
	jr nz, Tempo_StartMeasureDec
	ld bc, wa
	cp wa, 0x3e7
	jr nc, Tempo_StartMeasureReturn
	inc 1, bc
	stda16 0x398a, xbc
	jr Tempo_StartMeasureSync

Tempo_StartMeasureDec:
	ld bc, wa
	cps wa, 1
	jr ule, Tempo_StartMeasureReturn
	dec 1, bc
	stda16 0x398a, xbc

Tempo_StartMeasureSync:
	ldw_d16 xbc, 0x398c
	ldw_d16 xwa, 0x398a
	cp wa, bc
	jr ule, Tempo_StartMeasureSyncFar
	stda16 0x398c, xwa
	jr Tempo_StartMeasureSetDirty

Tempo_StartMeasureSyncFar:
	inc 7, wa
	cp wa, bc
	jr nc, Tempo_StartMeasureSetDirty
	stda16 0x398c, xwa

Tempo_StartMeasureSetDirty:
	setda 4, 0xe3e0

Tempo_StartMeasureReturn:
	inc 2, xsp
	ret

Tempo_AdjustEndMeasure:
	dec 2, xsp
	ld (xsp), a
	ldw wa, 0x81
	lds bc, 1
	calr Tempo_DisplayParamCommon
	ldw_d16 xwa, 0x398c
	cp (xsp), 0x0
	jr nz, Tempo_EndMeasureDec
	ld bc, wa
	cp wa, 0x3e7
	jr nc, Tempo_EndMeasureReturn
	inc 1, bc
	stda16 0x398c, xbc
	ld wa, bc
	jr Tempo_EndMeasureSyncStart

Tempo_EndMeasureDec:
	ld bc, wa
	cps wa, 1
	jr ule, Tempo_EndMeasureReturn
	dec 1, bc
	stda16 0x398c, xbc
	ldw_d16 xwa, 0x398c

Tempo_EndMeasureSyncStart:
	ldw_d16 xbc, 0x398a
	cp bc, wa
	jr ule, Tempo_EndMeasureSyncFar
	stda16 0x398a, xwa
	jr Tempo_EndMeasureSetDirty

Tempo_EndMeasureSyncFar:
	inc 7, bc
	cp bc, wa
	jr nc, Tempo_EndMeasureSetDirty
	dec 7, wa
	stda16 0x398a, xwa

Tempo_EndMeasureSetDirty:
	setda 4, 0xe3e0

Tempo_EndMeasureReturn:
	inc 2, xsp
	ret

Tempo_AdjustQuantize:
	dec 2, xsp
	ld (xsp), a
	ldw wa, 0x82
	lds bc, 2
	calr Tempo_DisplayParamCommon
	ldb_d8 a, 0x398e
	cp (xsp), 0x0
	jr nz, Tempo_QuantizeDec
	ld c, a
	cp a, 0x31
	jr nc, Tempo_QuantizeReturn
	inc 1, c
	stb_d8 0x398e, c
	jr Tempo_QuantizeSetDirty

Tempo_QuantizeDec:
	ld c, a
	cps a, 1
	jr ule, Tempo_QuantizeReturn
	dec 1, c
	stb_d8 0x398e, c

Tempo_QuantizeSetDirty:
	setda 4, 0xe3e0

Tempo_QuantizeReturn:
	inc 2, xsp
	ret

Tempo_AdjustEffect:
	dec 2, xsp
	ld (xsp), a
	ldw wa, 0x86
	lds bc, 6
	calr Tempo_DisplayParamCommon
	ldb_d8 a, 0x3990
	extz wa
	sla wa, 2
	lda_24 xbc, Display_FontPalette_Table_0x524C
	ld_sril3 XBC, 0x07, 0xe4, 0xe0
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
	setda 4, 0xe3e0

Tempo_EffectReturn:
	inc 2, xsp
	ret

Tempo_IncrementTimeSigNum:
	cps a, 0
	ret nz
	ldw wa, 0x9
	ldw bc, 0x8
	calr Tempo_DisplayParamCommon
	ldb_d8 a, 0x398f
	cp a, 0x1d
	ret nc
	inc 1, a
	stb_d8 0x398f, a
	setda 4, 0xe3e0
	ret

Tempo_DecrementTimeSigNum:
	cps a, 0
	ret nz
	ldw wa, 0x9
	ldw bc, 0x8
	calr Tempo_DisplayParamCommon
	ldb_d8 a, 0x398f
	cps a, 0
	ret z
	dec 1, a
	stb_d8 0x398f, a
	setda 4, 0xe3e0
	ret

Tempo_TimeSigCodeBlock:
	cps	a, 0
	ret	nz
	ldw	wa, 10
	ldw	bc, 11
	calr	391
	ldb_d8	a, 0x3990
	cps	a, 0
	ret	z
	dec	1, a
	stb_d8	0x3990, a
	.byte 0xf1, 0xe0, 0xe3, 0xbc
	ret
	dec	2, xsp
	ld	(xsp), a
	ldw	wa, 132
	lds	bc, 4
	calr	360
	ldb_d8	a, 0x3990
	.byte 0x87
	push	xsp
	nop
	jr	nz, 14
	ld	c, a
	cps	a, 4
	jr	nc, 24
	inc	1, c
	stb_d8	0x3990, c
	jr	12
	ld	c, a
	cps	a, 0
	jr	z, 10
	dec	1, c
	stb_d8	0x3990, c
	.byte 0xf1, 0xe0, 0xe3
	ld	(xix-17), xde
	ret

Tempo_EditBPM:
	cps a, 0
	ret nz
	setda 0, 0x8d88
	calr Tempo_DisplayParamReturn
	stb_d8 0x3988, l
	cps l, 1
	jr z, Tempo_EditBPMDec
	cps l, 0
	jr nz, Tempo_EditBPMClamp
	ldw wa, 0x23
	calr Tempo_DisplayParamSkipClear
	jr Tempo_EditBPMClamp

Tempo_EditBPMDec:
	ldw wa, 0xf
	calr Tempo_DisplayParamSkipClear
	ldw wa, 0x8
	call MIDI_SendSysExCmd

Tempo_EditBPMClamp:
	setda 7, 0x34cd
	setda 7, 0x34cd
	ret

Tempo_EditBPMApply:
	cps	a, 0
	ret	nz
	ldw	wa, 176
	call	UI_PostModeChangeEvent
	ret
	dec	2, xsp
	ld	(xsp), a
	ldw	wa, 146
	ldw	bc, 18
	calr	240
	ldw_d16	wa, 0x398a
	.byte 0x87
	push	xsp
	nop
	jr	nz, 32
	ld	bc, wa
	cp	wa, 999
	jr	nc, 84
	cp	bc, 989
	jr	c, 8
	stdi16	0x398a, 999
	jr	38
	add	bc, 10
	stda16	0x398a, bc
	jr	28
	ld	bc, wa
	cps	wa, 1
	jr	ule, 54
	cp	bc, 10
	jr	ugt, 8
	stdi16	0x398a, 1
	jr	8
	sub	bc, 10
	stda16	0x398a, bc
	ldw_d16	bc, 0x398c
	ldw_d16	wa, 0x398a
	cp	wa, bc
	jr	ule, 6
	stda16	0x398c, wa
	jr	10
	inc	7, wa
	cp	wa, bc
	jr	nc, 4
	stda16	0x398c, wa
	.byte 0xf1, 0xe0, 0xe3
	ld	(xix-17), xde
	ret
	dec	2, xsp
	ld	(xsp), a
	ldw	wa, 147
	ldw	bc, 19
	calr	123
	ldw_d16	wa, 0x398c
	.byte 0x87
	push	xsp
	nop
	jr	nz, 37
	ld	bc, wa
	cp	wa, 999
	jr	nc, 93
	cp	bc, 989
	jr	c, 11
	stdi16	0x398c, 999
	ldw	wa, 999
	jr	46
	add	bc, 10
	stda16	0x398c, bc
	ld	wa, bc
	jr	34
	ld	bc, wa
	cps	wa, 1
	jr	ule, 58
	cp	bc, 10
	jr	ugt, 10
	stdi16	0x398c, 1
	lds	wa, 1
	jr	12
	sub	bc, 10
	stda16	0x398c, bc
	ldw_d16	wa, 0x398c
	ldw_d16	bc, 0x398a
	cp	bc, wa
	jr	ule, 6
	stda16	0x398a, wa
	jr	12
	inc	7, bc
	cp	bc, wa
	jr	nc, 6
	dec	7, wa
	stda16	0x398a, wa
	.byte 0xf1, 0xe0, 0xe3
	ld	(xix-17), xde
	ret
	extz	wa
	jrl	-581
	extz	wa
	jrl	-531

Tempo_DisplayParamCommon:
	ordi8 0xe3e2, 9
	stb_d8 0xe3e4, a
	stb_d8 0xe3e6, c
	ret

Tempo_DisplayParamSkipClear:
	stb_d8 0x7f42, a
	ldw wa, 0xee
	jp SoundCtrl_SendCommand
Tempo_DisplayParamFormat:
	.long Pad_AfterBitmap_Dredt0k
	cp	a, (xwa)
	or	hl, ix
	.byte 0x41
	ret
	ret

Tempo_DisplayParamReturn:
	pushw_erp 0xfa
	ldib_erp 0xfb, 0
	calr MIDIChan_ScanForFree
	calr VoiceSlot_UpdateState
	calr Tempo_DisplayBPMReturn
	lds wa, 0
	calr SeqRec_ValidateDone
	ldb_d8 a, 0x3991
	cps a, 0
	jr z, Tempo_DisplayStartMeasure
	extz wa
	calr Part_IsPercussionType
	cps l, 0
	jr nz, Tempo_DisplayStartMeasure
	ldb_d8 c, 0x3991
	extz bc
	ldw_d16 xwa, 0x398a
	calr SetWall_StoreAndResolve
	cpdi8 0x287a, 0
	jr nz, Tempo_DisplayStartMeasure
	lds wa, 0
	calr Part_StoreVoiceTableIndex
	lds wa, 0
	calr Tempo_FormatBPM
	ldb_erp L, 0xfb
	cpib_erp 0xfb, 1
	jrl z, Tempo_DisplayEffect

Tempo_DisplayStartMeasure:
	lds wa, 1
	calr SeqRec_ValidateDone
	ldb_d8 a, 0x3992
	cps a, 0
	jr z, Tempo_DisplayEndMeasure
	extz wa
	calr Part_IsPercussionType
	cps l, 0
	jr nz, Tempo_DisplayEndMeasure
	ldb_d8 c, 0x3992
	extz bc
	ldw_d16 xwa, 0x398a
	calr SetWall_StoreAndResolve
	cpdi8 0x287a, 0
	jr nz, Tempo_DisplayEndMeasure
	lds wa, 1
	calr Part_StoreVoiceTableIndex
	lds wa, 1
	calr Tempo_FormatBPM
	ldb_erp L, 0xfb
	cpib_erp 0xfb, 1
	jrl z, Tempo_DisplayEffect

Tempo_DisplayEndMeasure:
	lds wa, 2
	calr SeqRec_ValidateDone
	ldb_d8 a, 0x3993
	cps a, 0
	jr z, Tempo_DisplayQuantize
	extz wa
	calr Part_IsPercussionType
	cps l, 0
	jr nz, Tempo_DisplayQuantize
	ldb_d8 c, 0x3993
	extz bc
	ldw_d16 xwa, 0x398a
	calr SetWall_StoreAndResolve
	cpdi8 0x287a, 0
	jr nz, Tempo_DisplayQuantize
	lds wa, 2
	calr Part_StoreVoiceTableIndex
	lds wa, 2
	calr Tempo_FormatBPM
	ldb_erp L, 0xfb
	cpib_erp 0xfb, 1
	jr z, Tempo_DisplayEffect

Tempo_DisplayQuantize:
	lds wa, 3
	calr SeqRec_ValidateDone
	ldb_d8 a, 0x3994
	cps a, 0
	jr z, Tempo_DisplayTimeSigNum
	extz wa
	calr Part_IsPercussionType
	cps l, 0
	jr nz, Tempo_DisplayTimeSigNum
	ldb_d8 c, 0x3994
	extz bc
	ldw_d16 xwa, 0x398a
	calr SetWall_StoreAndResolve
	cpdi8 0x287a, 0
	jr nz, Tempo_DisplayTimeSigNum
	lds wa, 3
	calr Part_StoreVoiceTableIndex
	lds wa, 3
	calr Tempo_FormatBPM
	ldb_erp L, 0xfb
	cpib_erp 0xfb, 1
	jr z, Tempo_DisplayEffect

Tempo_DisplayTimeSigNum:
	lds wa, 4
	calr SeqRec_ValidateDone
	ldb_d8 a, 0x3995
	cps a, 0
	jr z, Tempo_DisplayEffectLookup
	extz wa
	calr Part_IsPercussionType
	cps l, 0
	jr nz, Tempo_DisplayEffectLookup
	ldb_d8 c, 0x3995
	extz bc
	ldw_d16 xwa, 0x398a
	calr SetWall_StoreAndResolve
	cpdi8 0x287a, 0
	jr nz, Tempo_DisplayEffectLookup
	lds wa, 4
	calr Part_StoreVoiceTableIndex
	lds wa, 4
	calr Tempo_FormatBPM
	ldb_erp L, 0xfb
	cpib_erp 0xfb, 1
	jr nz, Tempo_DisplayEffectLookup

Tempo_DisplayEffect:
	calr Tempo_DisplayEffectRender

Tempo_DisplayEffectLookup:
	stb_erp L, 0xfb
	popw_erp 0xfa
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
	pushw_erp 0xfa
	lda_d16 xde, 0x3998
	ld xbc, xde
	lda xde, (xde + 10)

Tempo_FormatBPMDigit:
	stib_dsp 0xe4, 0x00
	cp xbc, xde
	jr c, Tempo_FormatBPMDigit
	cps a, 0
	jr nz, Tempo_FormatBPMDone
	setda 0, 0x3997
	jr Tempo_FormatBPMOutput

Tempo_FormatBPMDone:
	resda 0, 0x3997

Tempo_FormatBPMOutput:
	cps a, 1
	jr nz, Tempo_FormatBPMPad
	setda 1, 0x3997
	jr Tempo_DisplayBPMValue

Tempo_FormatBPMPad:
	resda 1, 0x3997

Tempo_DisplayBPMValue:
	ldw_d16 xwa, 0x398c
	subda16 xwa, 0x398a
	inc 1, a
	ldb_erp A, 0xfa
	mul_sd16b 1, 0x86, 0x39
	ldb_erp A, 0xfa

Tempo_DisplayBPMFraction:
	cpib_erp 0xfa, 0
	jr z, Tempo_DisplayBPMWithDec
	calr Voice_ReadEventBytes
	calr RhythmParam_TypeCheck
	ldb_d8 a, 0x3998
	cp a, 0x81
	jr nz, Tempo_DisplayBPMNoFrac
	dec1b_erp 0xfa
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
	cpib_erp 0xfa, 0
	jr z, Tempo_DisplayBPMClean
	ldib_erp 0xfb, 0

Tempo_DisplayBPMFinal:
	stdi8 0x3998, 129
	calr Voice_ScanTableByType
	cps l, 1
	jr z, Tempo_DisplayBPMExit
	inc1b_erp 0xfb
	stb_erp A, 0xfb
	cpb_erp A, 0xfa
	jr nz, Tempo_DisplayBPMFinal

Tempo_DisplayBPMClean:
	stdi8 0x3998, 131
	calr Voice_ScanTableByType
	cps l, 1
	jr z, Tempo_DisplayBPMExit
	ldb l, 0x0

Tempo_DisplayBPMExit:
	popw_erp 0xfa
	ret

Tempo_DisplayBPMReturn:
	lda xsp, (xsp - 18)
	push xiz
	ld xiy, Display_FontPalette_Table_0x5260
	lda xix, (xsp + 6)
	ldw bc, 0x8
	ldirw
	ldb_d8 e, 0x398f
	lds32 xwa, 0
	ld a, e
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 5
	ld xiz, xbc
	add xiz, 0x94860
	lda xbc, (xiz + 12)
	ldb_d8 a, 0x3986
	inc 3, a
	cp a, (xbc)
	jr z, Tempo_DisplayMeasureRange
	ldmi16 (xsp + 4), 0x34d6
	stb_d8 0x34d6, e
	ldb_d8 a, 0x3986
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
	mrdb5 0x8f, 0x04, 0x19, 0xd6, 0x34

Tempo_DisplayMeasureRange:
	ldw_d16 xwa, 0x398c
	subda16 xwa, 0x398a
	ld (xiz + 13), a
	resm 7, (xiz + 15)
	lda xde, (xsp + 6)
	lda xwa, (xiz + 64)
	ld xbc, xwa
	lda xhl, (xwa + 16)

Tempo_DisplayMeasureStart:
	ldb_spi A, 0xe8
	lda_dpi XBC, 0xe4
	cp xbc, xhl
	jr c, Tempo_DisplayMeasureStart
	cpdi8 0x3991, 0
	jr z, Tempo_DisplayMeasureSep
	lds wa, 0
	calr Tempo_DisplayEffectValLookup

Tempo_DisplayMeasureSep:
	cpdi8 0x3992, 0
	jr z, Tempo_DisplayMeasureEnd
	lds wa, 1
	calr Tempo_DisplayEffectValLookup

Tempo_DisplayMeasureEnd:
	cpdi8 0x3993, 0
	jr z, Tempo_DisplayQuantizeVal
	lds wa, 2
	calr Tempo_DisplayEffectValLookup

Tempo_DisplayQuantizeVal:
	cpdi8 0x3994, 0
	jr z, Tempo_DisplayTimeSig
	lds wa, 3
	calr Tempo_DisplayEffectValLookup

Tempo_DisplayTimeSig:
	cpdi8 0x3995, 0
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
	ldb_d8 a, 0x3991
	ldb_erp A, 0xfb
	ld (xsp + 8), 0x18
	jr Tempo_RefreshDisplay5

Tempo_RefreshDisplay1:
	ldb_d8 a, 0x3992
	ldb_erp A, 0xfb
	ld (xsp + 8), 0x20
	jr Tempo_RefreshDisplay5

Tempo_RefreshDisplay2:
	ldb_d8 a, 0x3993
	ldb_erp A, 0xfb
	ld (xsp + 8), 0x28
	jr Tempo_RefreshDisplay5

Tempo_RefreshDisplay3:
	ldb_d8 a, 0x3994
	ldb_erp A, 0xfb
	ld (xsp + 8), 0x30
	jr Tempo_RefreshDisplay5

Tempo_RefreshDisplay4:
	ldb_d8 a, 0x3995
	ldb_erp A, 0xfb
	ld (xsp + 8), 0x38

Tempo_RefreshDisplay5:
	cpib_erp 0xfb, 0
	jrl z, SeqRec_UpdateFlags
	lds32 xwa, 0
	ldb_d8 a, 0x398f
	ld xhl, xwa
	add xhl, xhl
	add xhl, xwa
	sll xhl, 5
	add xhl, 0x94860
	ld (xsp + 4), xhl
	stb_erp A, 0xfb
	dec 1, a
	extz wa
	lda_d16 xbc, 0xf1a0
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	extz wa
	sla wa, 2
	lda_24 xbc, Display_FontPalette_Table_0x5270
	ld_sril3 XIX, 0x07, 0xe4, 0xe0
	ld e, (xix + 1)
	extz de
	ld c, (xsp + 8)
	extz bc
	cp (xsp + 10), 0x0
	jr nz, SeqRec_InitState
	stb_dri W, 0x07, 0xec, 0xe4
	ld c, (xix)
	extz bc
	calr SeqRec_CheckOverflow
	jr SeqRec_InitChannels

SeqRec_InitState:
	ld xwa, (xsp + 4)
	stb_dri W, 0x07, 0xe0, 0xe4
	ld c, (xix)
	extz bc
	calr SeqRec_OverflowCleanup

SeqRec_InitChannels:
	stb_erp C, 0xfb
	extz bc
	lds wa, 1
	calr SetWall_StoreAndResolve
	ldw_d16 xbc, 0x398a
	dec 1, bc
	ldb_d8 a, 0x3986
	extz wa
	ldw_erp WA, 0xfa
	mul xwa, xbc
	ldw_erp WA, 0xfa
	lds iz, 0

SeqRec_StartRecord:
	cpw_erp IZ, 0xfa
	jr nc, SeqRec_UpdateFlags

SeqRec_StartRecordImpl:
	calr Voice_ReadEventBytes
	lda_d16 xhl, 0x3998
	ld c, (xhl)
	ld a, c
	and a, 0xf0
	cp a, 0xc0
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
	stb_dri W, 0x07, 0xe0, 0xe8
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
	cpw_erp IZ, 0xfa
	jr c, SeqRec_StartRecordImpl

SeqRec_UpdateFlags:
	pop xiz
	inc 8, xsp
	ret

SeqRec_CheckOverflow:
	lda xhl, (xwa + 1)
	cp c, 0xf0
	jr c, SeqRec_HandleOverflow
	and c, 0xf
	ld (xwa), c
	ld (xhl), e
	ret

SeqRec_HandleOverflow:
	ld (xwa), 0x0
	ld (xhl), 0x0
	ret

SeqRec_OverflowCleanup:
	lda xhl, (xwa + 1)
	cp c, 0xf0
	jr nc, SeqRec_CommitData
	cp c, 0x80
	jr c, SeqRec_CommitData
	cps e, 7
	jr nz, SeqRec_CommitData
	ldb c, 0x58
	jr SeqRec_CommitFinalize

SeqRec_CommitData:
	cp c, 0xf0
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
	pushw_erp 0xfa
	ldb_d8 c, 0x34d6
	ldb_erp C, 0xfa
	ldb_d8 c, 0x379b
	ldb_erp C, 0xfb
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
	stdi8 0x379b, 16
	jr Part_LoadAndIndexVoiceTable

SeqRec_Cleanup:
	stdi8 0x379b, 8
	jr Part_LoadAndIndexVoiceTable

Part_SetVoiceType1:
	stdi8 0x379b, 1
	jr Part_LoadAndIndexVoiceTable

Part_SetVoiceType2:
	stdi8 0x379b, 2
	jr Part_LoadAndIndexVoiceTable

Part_SetVoiceType4:
	stdi8 0x379b, 4

Part_LoadAndIndexVoiceTable:
	ldb_d8 a, 0x398f
	stb_d8 0x34d6, a
	lds32 xwa, 0
	ldb_d8 a, 0x398f
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 5
	add xbc, 0x94860
	ld a, (xbc + 12)
	dec 3, a
	stb_d8 0x34d9, a
	ld a, (xbc + 13)
	stb_d8 0x34d7, a
	push xde
	push xhl
	push xix
	push xiz
	call VoiceSlot_InitFromTable
	pop xiz
	pop xix
	pop xhl
	pop xde
	stb_erp A, 0xfa
	stb_d8 0x34d6, a
	stb_erp A, 0xfb
	stb_d8 0x379b, a
	popw_erp 0xfa
	ret

Part_StoreVoiceTableIndex:
	ld c, a
	extz bc
	ldb_d8 a, 0x398f
	extz wa
	mul wa, 0x5
	add wa, bc
	stda16 0x3980, xwa
	stdi16 0x3984, 6
	ret

SetWall_StoreAndResolve:
	stda16 0x287f, xwa
	extz bc
	ld wa, bc
	jp Voice_ResolveSlotAddr

MIDIChan_ScanForFree:
	ld xbc, 0xf1a0
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
	stdi8 0x3996, 0
	ret

MIDIChan_StoreResult:
	stb_d8 0x3996, a
	ret

VoiceSlot_UpdateState:
	ldb_d8 a, 0x3996
	stb_d8 0x288d, a
	cpdi8 0x3996, 0
	jr nz, VoiceSlot_SetBit2
	resda 2, 0x287b
	jr VoiceSlot_ValidateAndResolve

VoiceSlot_SetBit2:
	setda 2, 0x287b

VoiceSlot_ValidateAndResolve:
	call SeqVoice_ValidateAndProcessState
	ldmm16 0x287f, 0x398a
	ldb_d8 a, 0x3993
	cps a, 0
	jr z, VoiceSlot_CheckSlot2
	extz wa
	jr VoiceSlot_ResolveAddr

VoiceSlot_CheckSlot2:
	ldb_d8 a, 0x3994
	cps a, 0
	jr z, VoiceSlot_CheckSlot3
	extz wa
	jr VoiceSlot_ResolveAddr

VoiceSlot_CheckSlot3:
	ldb_d8 a, 0x3995
	cps a, 0
	jr z, VoiceSlot_CheckSlot4
	extz wa
	jr VoiceSlot_ResolveAddr

VoiceSlot_CheckSlot4:
	ldb_d8 a, 0x3992
	cps a, 0
	jr z, VoiceSlot_CheckSlot5
	extz wa
	jr VoiceSlot_ResolveAddr

VoiceSlot_CheckSlot5:
	ldb_d8 a, 0x3991
	cps a, 0
	jr z, VoiceSlot_StoreAndReturn
	extz wa

VoiceSlot_ResolveAddr:
	call Voice_ResolveSlotAddr

VoiceSlot_StoreAndReturn:
	ldmm8 0x3986, 0x288e
	ret

Part_IsPercussionType:
	dec 1, a
	extz wa
	extz xwa
	add xwa, 0xf1a0
	ld a, (xwa)
	cp a, 0xd
	jr z, EventCode_CheckExit
	cp a, 0xe
	jr z, EventCode_CheckExit
	cp a, 0xf
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
	and c, 0xf0
	cp c, 0x80
	jr z, VoiceEvt_Size1
	cp c, 0xd0
	jr z, VoiceEvt_CheckD2
	cp c, 0xc0
	jr z, VoiceEvt_Size6
	cp c, 0xb0
	jr z, VoiceEvt_Size6
	cp c, 0x90
	jr nz, VoiceEvt_Size1

VoiceEvt_Size6:
	ldiw_erp 0xfa, 6
	jr VoiceBuffer_CopyLoop

VoiceEvt_CheckD2:
	cp (xwa), 0xd2
	jr nz, VoiceEvt_Size3
	ldiw_erp 0xfa, 4
	jr VoiceBuffer_CopyLoop

VoiceEvt_Size3:
	ldiw_erp 0xfa, 3
	jr VoiceBuffer_CopyLoop

VoiceEvt_Size1:
	ldiw_erp 0xfa, 1

VoiceBuffer_CopyLoop:
	lds iz, 0
	cpiw_erp 0xfa, 0
	jr ule, VoiceBuf_CopyDone

VoiceBuf_CopyLoop:
	lda_d16 xbc, 0x3998
	ld de, iz
	extz xde
	add xde, xbc
	ld c, (xwa)
	ld (xde), c
	calr VoiceTable_AdvanceReadPos
	ld xwa, xhl
	inc 1, iz
	cpw_erp IZ, 0xfa
	jr c, VoiceBuf_CopyLoop

VoiceBuf_CopyDone:
	pop xiz
	ret

Voice_ScanTableByType:
	push xiz
	calr Voice_ResolveTableAddr
	ld xwa, xhl
	ldb_d8 c, 0x3998
	cp c, 0x83
	jr z, VoiceScan_Size1
	cp c, 0x81
	jr z, VoiceScan_Size1
	cp c, 0xd5
	jr z, Voice_SetScanType3
	cp c, 0xd4
	jr z, Voice_SetScanType3
	cp c, 0xd3
	jr z, Voice_SetScanType3
	cp c, 0xd2
	jr z, Voice_SetScanType3
	cp c, 0xd1
	jr z, Voice_SetScanType3
	cp c, 0x91
	jr z, VoiceScan_Size8
	cp c, 0x90
	jr nz, VoiceScan_Size0
	ldiw_erp 0xfa, 6
	jr Voice_ScanTableEntries

VoiceScan_Size8:
	ldi_erpw 0xfa, 0x08, 0x00
	jr Voice_ScanTableEntries

Voice_SetScanType3:
	ldiw_erp 0xfa, 3
	jr Voice_ScanTableEntries

VoiceScan_Size1:
	ldiw_erp 0xfa, 1
	jr Voice_ScanTableEntries

VoiceScan_Size0:
	ldiw_erp 0xfa, 0

Voice_ScanTableEntries:
	lds iz, 0
	cpiw_erp 0xfa, 0
	jr ule, VoiceScan_NotFound

VoiceScan_WriteLoop:
	lda_d16 xbc, 0x3998
	ld de, iz
	extz xde
	add xde, xbc
	ld c, (xde)
	ld (xwa), c
	calr VoiceTable_AdvanceWritePos
	ld xwa, xhl
	cp xwa, 0xffffffff
	jr nz, VoiceScan_NextEntry
	ldb l, 0x1
	jr VoiceScan_Return

VoiceScan_NextEntry:
	inc 1, iz
	cpw_erp IZ, 0xfa
	jr c, VoiceScan_WriteLoop

VoiceScan_NotFound:
	ldb l, 0x0

VoiceScan_Return:
	pop xiz
	ret

VoiceTable_AdvanceReadPos:
	ld xhl, xwa
	ldw_d16 xwa, 0x3982
	inc 1, wa
	stda16 0x3982, xwa
	cp wa, 0x100
	jr c, VoiceTable_AdvRead_Done
	ldw_d16 xwa, 0x397e
	dec 1, wa
	extz xwa
	sll xwa, 8
	ld xde, xwa
	add xde, 0xb0000
	ld c, (xde + 4)
	extz bc
	sll bc, 8
	ld a, (xde + 3)
	extz wa
	add wa, bc
	stda16 0x397e, xwa
	stdi16 0x3982, 5

VoiceTable_AdvRead_Done:
	jr VoiceTable_ResolveReadAddr

VoiceTable_ResolveReadAddr:
	ldw_d16 xbc, 0x3982
	extz xbc
	ldw_d16 xwa, 0x397e
	dec 1, wa
	extz xwa
	sll xwa, 8
	add xwa, 0xb0000
	add xwa, xbc
	ld xhl, xwa
	ret

VoiceTable_AdvanceWritePos:
	ld xhl, xwa
	ldw_d16 xwa, 0x3984
	inc 1, wa
	stda16 0x3984, xwa
	cp wa, 0xff
	jr c, RhythmParam_Setup
	ldw_d16 xwa, 0x34d4
	cps wa, 0
	jr nz, VoiceTable_AdvWrite_AllocSlot
	ld xhl, 0xffffffff
	jr RhythmParam_Entry

VoiceTable_AdvWrite_AllocSlot:
	dec 1, wa
	stda16 0x34d4, xwa
	ldw bc, 0x96
	ld xde, 0x9f200

VoiceTable_AdvWrite_ScanLoop:
	bitm 7, (xde)
	jr z, VoiceTable_AdvWrite_LinkEntry
	inc 1, bc
	stb_dri B, 0xe9, 0x00, 0x01
	cp bc, 0x153
	jr ule, VoiceTable_AdvWrite_ScanLoop

VoiceTable_AdvWrite_LinkEntry:
	ldw_d16 xwa, 0x3980
	extz xwa
	sll xwa, 8
	ld xhl, xwa
	add xhl, 0x95c00
	ld a, c
	ld (xhl + 3), a
	ld wa, bc
	srl wa, 8
	ld (xhl + 4), a
	ldw_d16 xwa, 0x3980
	ld (xde + 1), a
	ldw_d16 xwa, 0x3980
	srl wa, 8
	ld (xde + 2), a
	stda16 0x3980, xbc
	stdi16 0x3984, 6
	setm 7, (xde)

; Rhythm parameter dispatch setup
RhythmParam_Setup:
	calr Voice_ResolveTableAddr

; Rhythm parameter entry
RhythmParam_Entry:
	ret

Voice_ResolveTableAddr:
	ldw_d16 xbc, 0x3984
	extz xbc
	ldw_d16 xwa, 0x3980
	extz xwa
	sll xwa, 8
	add xwa, 0x95c00
	add xwa, xbc
	ld xhl, xwa
	ret

; Rhythm parameter type check
RhythmParam_TypeCheck:
	lda_d16 xwa, 0x3998
	bitda 0, 0x3997
	jr z, RhythmParam_Process
	ld xde, xwa
	ld c, (xwa)
	ld a, c
	and a, 0xf0
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
	lda_24 xix, Display_FontPalette_Table_0x52CE
	ldw_sri BC, 0x07, 0xf0, 0xe4
	lda_24 xix, RhythmParam_CheckExit
	jp_ind 8, 0x07, 0xf0, 0xe4

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
	and d, 0xf0
	cp d, 0x80
	jrl z, VoiceSlot_Dispatch
	lda xbc, (xhl + 2)
	lda xwa, (xhl + 3)
	cp d, 0xd0
	jrl z, VoiceParam_D0Handler
	cp d, 0xb0
	jrl z, VoiceParam_B0_Handler
	cp d, 0x90
	jrl nz, Voice_ClearSlotAndRet
	ldb_d8 e, 0x398e
	cp e, 0x19
	jr ule, VoiceNote_SubtractOffset
	ld xix, xbc
	sub e, 0x19
	ld a, (xbc)
	add a, e
	ld (xbc), a
	cp a, 0x7f
	jr ule, Voice_BoundaryCheck
	ld (xix), 0x7f
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
	bitda 1, 0x3997
	jr z, VoiceBound_CalcOctave
	lda xbc, (xhl + 2)
	ld a, (xbc)
	cp a, 0xc
	jr c, VoiceBound_CalcOctave
	sub a, 0xc
	ld (xbc), a

VoiceBound_CalcOctave:
	ld a, (xhl + 2)
	extz wa
	div a, 0xc
	ld e, w
	lda xwa, (xhl + 6)
	lda xbc, (xhl + 7)
	cp e, 0xb
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
	and a, 0x1f
	lda xbc, (xhl + 4)
	lda xix, (xhl + 5)
	cps a, 4
	jr nz, __pad_F66E4B
	bitm 3, (xix)
	jr z, __pad_F66E4B
	ld (xhl), 0xd3
	bitm 3, (xbc)
	jr nz, VoiceParam_B0_Process
	ld (xde), 0x0
	ret

VoiceParam_B0_Process:
	ld (xde), 0x7f
	ret

__pad_F66E4B:
	cp a, 0x8
	jr nz, Voice_ClearSlotAndRet
	ld a, (xix)
	res 7, a
	cps a, 0
	jr z, Voice_ClearSlotAndRet
	ld (xhl), 0xd4
	ld a, (xbc)
	res 7, a
	ld (xde), a
	ret

; Voice parameter D0 type (fine tuning)
VoiceParam_D0Handler:
	cp e, 0xd2
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
	cp e, 0xd3
	ret nz
	ld (xhl), 0xd5
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
	lda_24 xix, Display_FontPalette_Table_0x52C0
	ldw_sri DE, 0x07, 0xf0, 0xe8
	lda_24 xix, Voice_ClearSlotAndRet
	jp_ind 8, 0x07, 0xf0, 0xe8

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
	call	TimeSig_DisplayStrings_0x935
	inc	4, xsp
	ret

Voice_ResolveSlotAddr:
	push xiz
	ldb_d8 w, 0x3996
	call SetWall_SlotResolve
	stda16 0x3982, xiy
	ldw_d16 xiy, 0x28af
	stda16 0x397e, xiy
	pop xiz
	ret

VoiceSlot_Dispatch_Type81:
	ldb a, 0x7f
	stb_d8 0x37c8, a
	ldb a, 0xff
	stb_d8 0x37c7, a
	ldb c, 0x0

VoiceSlot_Dispatch_Type90:
	cps c, 7
	jr z, VoiceSlot_Dispatch_D0Type
	ld xwa, 0x37ab
	ldb e, 0x0
	lda_dri XIY, 0x03, 0xe0, 0xe4
	ld xwa, 0x37b2
	ldb e, 0x1
	lda_dri XIY, 0x03, 0xe0, 0xe4
	ld xwa, 0x37b9
	ldb e, 0xff
	lda_dri XIY, 0x03, 0xe0, 0xe4
	ld xwa, 0x37c0
	ldb e, 0xff
	lda_dri XIY, 0x03, 0xe0, 0xe4
	inc 1, c
	jr VoiceSlot_Dispatch_Type90

VoiceSlot_Dispatch_D0Type:
	stdi8 0x37c9, 64
	calr RhythmDrum_LoadVoiceParams
	stdi8 0x37c9, 32
	calr RhythmDrum_LoadVoiceParams
	stdi8 0x37c9, 16
	calr RhythmDrum_LoadVoiceParams
	stdi8 0x37c9, 8
	calr RhythmDrum_LoadVoiceParams
	stdi8 0x37c9, 4
	calr RhythmDrum_LoadVoiceParams
	stdi8 0x37c9, 2
	calr RhythmDrum_LoadVoiceParams
	stdi8 0x37c9, 1
	calr RhythmDrum_LoadVoiceParams
	ret

VoiceSlot_Dispatch_Return:
	push	xiz
	call	VoiceSlot_Dispatch_Return_0x7
	pop	xiz
	ret
	bit	7, a
	jr	nz, 20
	.byte 0xc1, 0xd6
	ldw	ix, 2879
	jr	ge, 6
	incdi8	1, 0x34d6
	jr	5
	stdi8	0x34d6, 11
	jr	18
	.byte 0xc1, 0xd6
	ldw	ix, 63
	jr	gt, 7
	stdi8	0x34d6, 0
	jr	4
	decdi8	1, 0x34d6
	calr	4
	calr	174
	ret
	lds32	xhl, 0
	ldb_d8	l, 0x34d6
	and	l, 31
	add	l, 128
	ld	xbc, 0xfc5a
	ldb	a, 0
	.byte 0xf3
	pop	sr
	.byte 0xe4, 0xe0
	ld	xsp, 0x03c30121
	.byte 0xe4, 0xe0
	ldb	h, 206
	add	w, d
	.byte 0xf3
	pop	sr
	.byte 0xe4, 0xe0
	ld	xiz, 0x21fc5ac1
	ldb	w, 0
	ldb	e, 72
	ldb	d, 0
	call	SwbtWr_QueuePostEvent
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
	ldb_d8 a, 0x39b8
	ld xix, PatIdx_Lookup_Return
	ldb_sri A, 0x03, 0xf0, 0xe0
	stb_d8 0x37c9, a
	pop xix
	pop xwa
	ret

PatIdx_Lookup_Return:
	.byte 0x01
	push	sr
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
	ld xiy, 0x37ab
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
	stb_d8 0x37c8, w
	xor bc, bc
	ldb w, 0x1
	ld xix, 0x37ab
	ld xiy, 0x37b9

VoiceTable_InitEntry_Store:
	ldb_spi A, 0xf0
	cp_spib A, 0xf4
	jr z, VoiceTable_InitEntry_Return
	orddm8 0x37c8, w

VoiceTable_InitEntry_Return:
	sll w, 1
	inc 1, bc
	cps bc, 7
	jr lt, VoiceTable_InitEntry_Store
	xor bc, bc
	ldb w, 0x1
	ld xix, 0x37b2
	ld xiy, 0x37c0

MultiVoice_SetupChannel:
	ldb_spi A, 0xf0
	cp_spib A, 0xf4
	jr z, MultiVoice_Setup_Loop
	orddm8 0x37c8, w

MultiVoice_Setup_Loop:
	sll w, 1
	inc 1, bc
	cps bc, 7
	jr lt, MultiVoice_SetupChannel
	ldb_d8 a, 0x34d6
	cpda8 a, 0x37c7
	jr z, MultiVoice_Setup_WriteParam
	ldb b, 0x7f
	stb_d8 0x37c8, b

MultiVoice_Setup_WriteParam:
	ret

Rhythm_MapChannelToDrumIndex:
	lds32 xbc, 0
	ldb_d8 c, 0x37c9
	srl c, 1
	add xbc, MultiVoice_Setup_Done
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
	push	sr
	nop
	pop	sr
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
	ld xix, 0x37b2
	add xix, xbc
	ld a, (xix)
	ret

RhythmDrum_LoadVoiceParams:
	calr Rhythm_MapChannelToDrumIndex
	ld xix, 0x37ab
	add xix, xbc
	lds32 xwa, 0
	ld a, (xix)
	mul bc, 0xa
	add xbc, xwa
	lds32 xde, 0
	lds32 xhl, 0
	ld xwa, Display_FontPalette_Table_0x537C

VoiceAssign_ProcessRequest:
	cp hl, bc
	jr z, VoiceAssign_Process_Loop
	push xbc
	ldb_sri C, 0x07, 0xe0, 0xec
	and xbc, 0xff
	add xde, xbc
	pop xbc
	inc 1, hl
	jr VoiceAssign_ProcessRequest

VoiceAssign_Process_Loop:
	push xde
	calr Rhythm_MapChannelToDrumIndex
	ld xix, 0x37b2
	add xix, xbc
	lds32 xwa, 0
	ld a, (xix)
	pop xde
	add xde, xwa
	sll xde, 2
	ld xwa, Display_FontPalette_Table_0x53C2
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
	stdi8 0x90f6, 72
	call SndParam_ApplyProgramChange_Safe
	call VoiceParam_ClampAndValidate_Tramp
	pushw hl
	calr Rhythm_MapChannelToDrumIndex
	popw hl
	ld xix, 0x38d2
	lda_dri XSP, 0x03, 0xf0, 0xe4
	ld xix, 0x38d9
	lda_dri XIZ, 0x03, 0xf0, 0xe4
	sll l, 1
	sll hl, 1
	ld xiy, Display_FontPalette_Table_0x2EA
	ldw_sri WA, 0x07, 0xf4, 0xec
	add hl, 0x2
	lds32 xde, 0
	ldw_sri DE, 0x07, 0xf4, 0xec
	ld w, a
	and xwa, 0xff00
	sll xwa, 8
	ld xix, 0x400000
	addda32 xix, 0x3277
	add xix, xwa
	add xix, xde
	jr VoiceAssign_StoreFinal

VoiceAssign_StoreFinal:
	ret

__pad_F671E7:
	pushw hl
	push xix
	calr Rhythm_MapChannelToDrumIndex
	pop xix
	popw hl
	ld xwa, RegPreset_LoadVoiceData
	ldb_sri A, 0x07, 0xe0, 0xec
	and xwa, 0x7
	push xwa
	ld xbc, xwa
	sll xbc, 1
	add xbc, RegPreset_LoadVoiceData_0x4
	lds32 xde, 0
	ld de, (xbc)
	push xix
	calr RegPreset_Load_Loop
	pop xix
	pop xwa
	push xwa
	ld xbc, xwa
	sll xbc, 1
	add xbc, RegPreset_LoadVoiceData_0x14
	lds32 xde, 0
	ld de, (xbc)
	push xix
	calr MIDIChan_DispatchDone
	pop xix
	pop xwa
	push xwa
	ld xbc, xwa
	sll xbc, 1
	add xbc, RegPreset_LoadVoiceData_0x24
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
	pop	sr
	.byte 0x04
	reti
	nop
	nop
	retd	3844
	.byte 0x04
	retd	0
	.byte 0x04
	retd	3844
	.byte 0x04
	retd	4
	nop
	ldw	bc, 0x3104
	.byte 0x04
	ldw	bc, 0
	.byte 0x04
	ldw	bc, 0x3104
	.byte 0x04
	ldw	bc, 4
	nop
	ei	4
	ei	4
	di
	nop
	.byte 0x04
	ei	4
	ei	4
	ei	4

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
	ldb_sri E, 0x07, 0xf0, 0xe0
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
	ldw_sri WA, 0x07, 0xf0, 0xe4
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
	add xwa, 0x380a
	pop xde
	add xde, 0x6
	ld (xwa), xde
	ret

MIDIChan_DispatchTable:
	ldw bc, 0x3d1
	lds32 xwa, 0
	ldb_sri W, 0x07, 0xf0, 0xe4
	and xwa, 0xff00
	sll xwa, 8
	ld xiy, 0x400000
	addda32 xix, 0x3277
	add xiy, xwa
	ret

DrumChannel_MapToIndexA:
	cpdi8 0x37c9, 1
	jr nz, MIDIChan_Dispatch_Ch1
	lds32 xbc, 0
	jr DrumChannel_MapA_NullRet

MIDIChan_Dispatch_Ch1:
	cpdi8 0x37c9, 2
	jr nz, MIDIChan_Dispatch_Ch2
	lds32 xbc, 0
	jr DrumChannel_MapA_NullRet

MIDIChan_Dispatch_Ch2:
	cpdi8 0x37c9, 4
	jr nz, MIDIChan_Dispatch_Ch3
	lds32 xbc, 0
	jr DrumChannel_MapA_NullRet

MIDIChan_Dispatch_Ch3:
	cpdi8 0x37c9, 8
	jr nz, MIDIChan_Dispatch_Ch4
	lds32 xbc, 1
	jr DrumChannel_MapA_NullRet

MIDIChan_Dispatch_Ch4:
	cpdi8 0x37c9, 16
	jr nz, MIDIChan_Dispatch_Ch5
	lds32 xbc, 2
	jr DrumChannel_MapA_NullRet

MIDIChan_Dispatch_Ch5:
	cpdi8 0x37c9, 32
	jr nz, MIDIChan_Dispatch_Ch6
	lds32 xbc, 3
	jr DrumChannel_MapA_NullRet

MIDIChan_Dispatch_Ch6:
	lds32 xbc, 4

DrumChannel_MapA_NullRet:
	ret

DrumChannel_MapToIndexB:
	cpdi8 0x37c9, 1
	jr nz, MIDIChan_Dispatch_Ch7
	lds32 xbc, 0
	jr DrumChannel_MapB_NullRet

MIDIChan_Dispatch_Ch7:
	cpdi8 0x37c9, 2
	jr nz, MIDIChan_Dispatch_Ch8
	lds32 xbc, 0
	jr DrumChannel_MapB_NullRet

MIDIChan_Dispatch_Ch8:
	cpdi8 0x37c9, 4
	jr nz, MIDIChan_Dispatch_Ch9
	lds32 xbc, 0
	jr DrumChannel_MapB_NullRet

MIDIChan_Dispatch_Ch9:
	cpdi8 0x37c9, 8
	jr nz, MIDIChan_Dispatch_Ch10
	lds32 xbc, 2
	jr DrumChannel_MapB_NullRet

MIDIChan_Dispatch_Ch10:
	cpdi8 0x37c9, 16
	jr nz, MIDIChan_Dispatch_Ch11
	lds32 xbc, 3
	jr DrumChannel_MapB_NullRet

MIDIChan_Dispatch_Ch11:
	cpdi8 0x37c9, 32
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
	add xbc, 0x37d1
	ld xiy, xbc
	lds32 xbc, 7
	push xiy
	push xix
	pop xiy
	pop xix
	ldir85
	ret

VoiceResolve_CheckAndStore:
	bitda 0, 0x37c9
	jr nz, Rhythm_ClearChannelDrumIndex
	bitda 1, 0x37c9
	jr nz, Rhythm_ClearChannelDrumIndex
	bitda 2, 0x37c9
	jr nz, Rhythm_ClearChannelDrumIndex
	bitda 3, 0x37c9
	jr nz, Rhythm_ClearChannelDrumIndex
	add de, 0x3d2
	ldb_sri A, 0x07, 0xf0, 0xe8
	calr Rhythm_MapChannelToDrumIndex
	add xbc, VoiceResolve_SearchDone
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
	add xbc, 0x387a
	ld (xbc), a
	ret

VoiceResolve_SearchDone:
	ldio	8, 8
	ldio	8, 16
	.byte 0x20

__pad_F6742B:
	ldw bc, 0x3d0
	ldb_sri A, 0x07, 0xf0, 0xe4
	push xix
	calr VoiceResolve_FindSlot
	pop xix
	push_a
	push xix
	calr Rhythm_MapChannelToDrumIndex
	pop xix
	pop_a
	add xbc, 0x37ca
	ld (xbc), a
	ret

VoiceResolve_FindSlot:
	push xbc
	ld xbc, Display_FontPalette_Table_0x1D32
	ldb_sri A, 0x03, 0xe4, 0xe0
	pop xbc
	ret

VoiceResolve_FindSlot_Return:
	add	a, 3
	ret

__pad_F67459:
	calr Rhythm_MapChannelToDrumIndex
	add xbc, 0x37ab
	lds32 xwa, 0
	ld a, (xbc)
	sll xwa, 4
	ld xiy, Display_FontPalette_Table_0x52DC
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
	ld xix, 0x37b2
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
	bitda 0, 0x37c9
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
	add xhl, 0x37ab
	ld l, (xhl)
	mul bc, 0xa
	ld xwa, Display_FontPalette_Table_0x537C
	add xwa, xbc
	ldb_sri W, 0x03, 0xe0, 0xec
	dec 1, w
	ret

ExtVoice_ProcessList:
	ret
	push	xiz
	call	ExtVoice_ProcessList_0x8
	pop	xiz
	ret
	.byte 0xf1
	calr	51716
	jr	nz, 13
	.byte 0xc1, 0xcd
	ldw	ix, 0x803e
	call	Seq_DispatcherEntry
	call	AccWrap_PlayModeStartAccPlay
	ret
	push	xiz
	call	ExtVoice_ProcessList_0x23
	pop	xiz
	ret
	call	AccWrap_PlayModeDispatch
	calr	80
	call	Seq_DispatcherEntry
	.byte 0xc1, 0xc9, 0x37, 0x04
	calr	78
	calr	115
	stdi8	0x7f42, 0
	calr	113
	.byte 0xc1
	ld	xde, 0x66003f7f
	.byte 0x0b, 0x1d
	and	(xhl-0x3e0b), xwa
	.byte 0x37
	push	xiz
	jrl	nc, 1384
	stdi8	0x37c8, 0
	.byte 0xf1, 0xc9, 0x37, 0x04, 0xc1, 0xcd
	ldw	ix, 0x803e
	call	Seq_DispatcherEntry
	.byte 0xc1
	ld	xde, 0x6e003f7f
	.byte 0x06
	call	AccWrap_PlayModeStartAccPlay
	jr	3
	calr	1
	ret
	call	DrumVoice_NotifyEE
	ret
	.byte 0xf1
	calr	51716
	jr	z, 2
	jr	-8
	ret
	stdi8	0x37c9, 1
	calr	64320
	ld	xwa, 0x37ca
	add	xwa, xbc
	ld	a, (xwa)
	.byte 0xc1, 0xd9
	ldw	ix, 0x66f1
	rcf
	stdi8	0x37c8, 127
	stb_d8	0x34d9, a
	calr	65211
	stb_d8	0x34d8, a
	ret
	stdi8	0x34d7, 3
	ret
	.byte 0xf1, 0xc8, 0x37
	inc	6, c
	jp	0x37c9f1
	nop
	ldio	30, 150
	nop
	calr	64265
	ld	xix, 0x387a
	.byte 0xc3
	reti
	.byte 0xf0, 0xe4
	push	xsp
	nop
	jr	nz, 3
	calr	337
	.byte 0xf1, 0xc8, 0x37
	inc	6, d
	jp	0x37c9f1
	nop
	rcf
	calr	117
	calr	64232
	ld	xix, 0x387a
	.byte 0xc3
	reti
	.byte 0xf0, 0xe4
	push	xsp
	nop
	jr	nz, 3
	calr	304
	.byte 0xf1, 0xc8, 0x37
	inc	6, e
	jp	0x37c9f1
	nop
	ldb	w, 30
	.byte 0x54
	nop
	calr	64199
	ld	xix, 0x387a
	.byte 0xc3
	reti
	.byte 0xf0, 0xe4
	push	xsp
	nop
	jr	nz, 3
	calr	271
	.byte 0xf1, 0xc8, 0x37
	inc	6, h
	jp	0x37c9f1
	nop
	ld	xwa, 0x1e00331e
	cp	(xiz), xde
	ld	xix, 0x387a
	.byte 0xc3
	reti
	.byte 0xf0, 0xe4
	push	xsp
	nop
	jr	nz, 3
	calr	238
	.byte 0xf1, 0xc8, 0x37
	dec	6, w
	ret
	.byte 0xf1, 0xc8, 0x37
	dec	6, a
	ldio	241, 200
	.byte 0x37
	dec	6, b
	push	sr
	jr	11
	stdi8	0x37c9, 1
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
	ldw (xwa), 0xffff
	pop xwa
	pushw hl
	calr Voice_ClearSlotBuffer
	calr __pad_F676C1
	popw hl

AccVoice_SetupSlots_Loop:
	cp hl, 0xffff
	jr z, AccVoice_SetupSlots_InitEntry
	calr AccPatch_ResolveEntryAddr
	push xwa
	add xwa, 0x3
	ld hl, (xwa)
	ldw (xwa), 0xffff
	pop xwa
	push xwa
	add xwa, 0x1
	ldw (xwa), 0xffff
	pop xwa
	push xwa
	andmi8 (xwa), 0x7f
	pop xwa
	pushw hl
	calr Voice_ClearSlotBuffer
	popw hl
	incdi16 1, 0x34d4
	jr AccVoice_SetupSlots_Loop

AccVoice_SetupSlots_InitEntry:
	popw hl
	ret

Voice_ClearSlotBuffer:
	add xwa, 0x6
	ld xix, xwa
	ld xbc, 0xf9

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
	ldb_d8 c, 0x34d7
	inc 1, c
	mul_sd16b 3, 0xd9, 0x34

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
	ldb_d8 l, 0x34d6
	cp l, 0x1e
	jr lt, AccVoice_SetupSlots_Write
	ldb l, 0x0

AccVoice_SetupSlots_Write:
	mul l, 0x60
	add hl, 0x60
	ld xix, 0x94800
	add xix, xhl
	ret

AccVoice_SetupSlots_WriteDone:
	nop
	nop

AccPatch_ResolveEntryAddr:
	push xix
	pushw hl
	pushw hl
	lds32 xhl, 0
	popw hl
	sll xhl, 8
	ld xwa, 0x95c00
	add xwa, xhl
	popw hl
	pop xix
	ret

AccVoice_SetupSlots_DataBlock:
	calr	63909
	add	xbc, 0x37b2
	ld	a, (xbc)
	cps	a, 0
	jr	z, 9
	calr	7
	calr	43
	calr	65
	ret
	calr	63884
	sll	xbc, 3
	add	xbc, 0x37d1
	ld	xiy, xbc
	calr	65445
	push	xix
	calr	64478
	pop	xix
	sll	bc, 3
	add	bc, 24
	add	xix, xbc
	ld	xbc, 8
	.byte 0x85
	scf
	ret
	calr	65420
	calr	64523
	sll	bc, 1
	.byte 0xd3
	reti
	.byte 0xf0, 0xe4
	ldb	c, 241
	ccf
	ldw	iz, 0xf153
	push_a
	ldw	iz, 1538
	nop
	ret
	ldb	c, 0
	stb_d8	0x38d1, c
	ldb_d8	c, 0x34d7
	inc	1, c
	.byte 0xc1
	incdi16	2, 0xf338
	zcf
	push	c
	calr	18
	pop	c
	ldb_d8	a, 0x38d1
	inc	1, a
	stb_d8	0x38d1, a
	jr	-25
	calr	466
	ret
	calr	52
	push	xwa
	calr	63775
	pop	xwa
	sll	xbc, 2
	add	xbc, 0x3898
	ld	(xbc), xwa
	ldb	a, 0
	stb_d8	0x38d0, a
	ldb_d8	c, 0x34d9
	cpdm8	0x38d0, c
	jr	ge, 19
	push	c
	calr	41
	ldb_d8	a, 0x38d0
	inc	1, a
	stb_d8	0x38d0, a
	pop	c
	jr	-25
	ret
	calr	63724
	sll	xbc, 4
	add	xbc, 0x380a
	lds32	xwa, 0
	ldb_d8	a, 0x38d1
	sll	xwa, 2
	add	xbc, xwa
	ld	xwa, (xbc)
	ret
	calr	53
	cp	a, 131
	jr	nz, 30
	calr	63690
	sll	bc, 2
	add	xbc, 0x3898
	ld	xwa, AccVoice_SetupSlots_DataBlock_0x106
	ld	(xbc), xwa
	push	xbc
	lds32	xbc, 1
	calr	110
	pop	xbc
	ldb	a, 129
	jr	5
	push_a
	calr	101
	pop_a
	cp	a, 129
	jr	z, 2
	jr	-50
	ret
	cp	(xbc), l
	swi	7
	swi	7
	swi	7
	calr	63642
	sll	xbc, 2
	add	xbc, 0x3898
	ld	xwa, (xbc)
	cp	xwa, AccVoice_SetupSlots_DataBlock_0x106
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
	calr	63555
	sll	xbc, 2
	add	xbc, 0x3898
	ld	xiy, (xbc)
	ld	a, (xiy)
	lds32	xbc, 0
	calr	65457
	ldw_d16	hl, 0x3612
	pushw	bc
	calr	65134
	popw	bc
	ld	xix, xwa
	lds32	xwa, 0
	ldw_d16	wa, 0x3614
	add	xix, xwa
	ldw	de, 255
	.byte 0xd1
	push_a
	ldw	iz, 0xdaa2
	.byte 0xf1
	jr	gt, 12
	.byte 0xd1
	push_a
	ldw	iz, 0xd989
	inc	6, wa
	push	sr
	.byte 0x85
	scf
	jr	60
	pushw	bc
	ld	bc, de
	.byte 0xd1
	push_a
	ldw	iz, 0xd989
	inc	6, wa
	push	sr
	.byte 0x85
	scf
	popw	bc
	push	xiy
	sub	bc, de
	stda16	0x343d, bc
	stda16	0x343f, de
	calr	64
	ldw_d16	hl, 0x3612
	calr	65065
	ld	xix, xwa
	lds32	xwa, 0
	ldw_d16	wa, 0x3614
	add	xix, xwa
	pop	xiy
	ldw_d16	bc, 0x343d
	.byte 0xd1
	push_a
	ldw	iz, 0xd989
	inc	6, wa
	push	sr
	.byte 0x85
	scf
	push	xiy
	calr	63431
	sll	xbc, 2
	add	xbc, 0x3898
	pop	xiy
	ld	(xbc), xiy
	cp	xiy, AccVoice_SetupSlots_DataBlock_0x107
	jr	nz, 7
	ld	xiy, AccVoice_SetupSlots_DataBlock_0x106
	ld	(xbc), xiy
	ret
	.byte 0xd1, 0xd4
	ldw	ix, 63
	nop
	jr	z, 66
	ldw	hl, 150
	pushw	hl
	calr	64993
	popw	hl
	.byte 0xb0
	inc	6, l
	.byte 0x04
	inc	1, hl
	jr	-13
	ld	c, (xwa)
	or	c, 128
	ld	(xwa), c
	lds	de, 1
	ldw_d16	bc, 0x3612
	.byte 0xf3
	reti
	.byte 0xe0, 0xe8, 0x51
	pushw	hl
	ldw_d16	hl, 0x3612
	calr	64958
	lds	de, 3
	popw	hl
	.byte 0xf3
	reti
	.byte 0xe0, 0xe8, 0x53
	decdi16	1, 0x34d4
	stda16	0x3612, hl
	lds	wa, 6
	stda16	0x3614, wa
	jr	11
	lds	wa, 6
	stda16	0x3614, wa
	stdi8	0x7f42, 15
	ret
	calr	63314
	sll	bc, 2
	add	xbc, 0x3898
	ld	xwa, AccVoice_SetupSlots_DataBlock_0x26C
	ld	(xbc), xwa
	ldb	c, 1
	calr	65271
	ret
	ld	a, (xhl)
	.byte 0x01
	stb_d8	0x37c9, a
	calr	64931
	calr	7
	calr	64964
	calr	124
	ret
	calr	64844
	ldb_d8	w, 0x34d8
	ldb	a, 12
	.byte 0xf3
	pop	sr
	.byte 0xf0, 0xe0
	ld	xwa, 0x2034d7c1
	ldb	a, 13
	.byte 0xf3
	pop	sr
	.byte 0xf0, 0xe0
	.ascii "@  !"
	ret
	.byte 0xf3
	pop	sr
	.byte 0xf0, 0xe0
	ld	xwa, 0x0f210020
	.byte 0xf3
	pop	sr
	.byte 0xf0, 0xe0
	ld	xwa, 0xc9f10121
	.byte 0x37
	ld	xbc, 0xf6f31e3c
	pop	xix
	ld	xiy, 0x38d2
	.byte 0xc3
	pop	sr
	.byte 0xf4, 0xe4
	ldb	w, 33
	rcf
	.byte 0xf3
	pop	sr
	.byte 0xf0, 0xe0
	ld	xwa, 0x38d945
	nop
	.byte 0xc3
	pop	sr
	.byte 0xf4, 0xe4
	ldb	w, 33
	scf
	.byte 0xf3
	pop	sr
	.byte 0xf0, 0xe0
	ld	xwa, 0xf67a0245
	nop
	add	xix, 64
	lds32	xbc, 0
	ldw	bc, 16
	.byte 0x85
	scf
	ret
	aligned_string "Easy            #"
	stb_d8	0x38d1, c
	ldb_d8	c, 0x34d7
	add	c, 1
	.byte 0xc1
	incdi16	2, 0xf338
	zcf
	push	c
	calr	18
	pop	c
	ldb_d8	a, 0x38d1
	inc	1, a
	stb_d8	0x38d1, a
	jr	-25
	calr	65327
	ret
	ldb	a, 1
	stb_d8	0x37c9, a
	calr	64907
	push	xwa
	calr	63094
	pop	xwa
	sll	xbc, 2
	add	xbc, 0x3898
	ld	(xbc), xwa
	ldb	a, 2
	stb_d8	0x37c9, a
	calr	64882
	push	xwa
	calr	63069
	pop	xwa
	sll	xbc, 2
	add	xbc, 0x3898
	ld	(xbc), xwa
	ldb	a, 4
	stb_d8	0x37c9, a
	calr	64857
	push	xwa
	calr	63044
	pop	xwa
	sll	xbc, 2
	add	xbc, 0x3898
	ld	(xbc), xwa
	ldb	a, 0
	stb_d8	0x38d0, a
	ldb_d8	c, 0x34d9
	cpdm8	0x38d0, c
	jr	ge, 19
	push	c
	calr	15
	ldb_d8	a, 0x38d0
	inc	1, a
	stb_d8	0x38d0, a
	pop	c
	jr	-25
	ret
	ldb	a, 1
	stb_d8	0x37c9, a
	calr	123
	ldb	a, 2
	stb_d8	0x37c9, a
	calr	114
	ldb	a, 4
	stb_d8	0x37c9, a
	calr	105
	calr	329
	push	l
	calr	168
	pop	l
	cps	w, 0
	jr	z, 13
	calr	224
	stb_d8	0x37c9, l
	calr	64923
	jrl	-54
	ldb	a, 1
	stb_d8	0x37c9, a
	lds32	xbc, 0
	ldb	c, 1
	calr	64907
	ldb	a, 2
	stb_d8	0x37c9, a
	calr	62920
	sll	xbc, 2
	add	xbc, 0x3898
	ld	xwa, (xbc)
	cp	xwa, AccVoice_SetupSlots_DataBlock_0x106
	jr	z, 4
	inc	1, xwa
	ld	(xbc), xwa
	ldb	a, 4
	stb_d8	0x37c9, a
	calr	62888
	sll	xbc, 2
	add	xbc, 0x3898
	ld	xwa, (xbc)
	cp	xwa, AccVoice_SetupSlots_DataBlock_0x106
	jr	z, 4
	inc	1, xwa
	ld	(xbc), xwa
	ret
	calr	62861
	add	xbc, 0x37b2
	ld	a, (xbc)
	cps	a, 0
	jr	z, 33
	calr	275
	calr	62843
	sll	xbc, 2
	add	xbc, 0x3898
	ld	xwa, (xbc)
	ld	l, (xwa)
	cp	l, 131
	jr	nz, 7
	ld	xwa, AccVoice_SetupSlots_DataBlock_0x106
	ld	(xbc), xwa
	jr	19
	calr	62813
	sll	xbc, 2
	add	xbc, 0x3898
	ld	xwa, AccVoice_SetupSlots_DataBlock_0x106
	ld	(xbc), xwa
	calr	92
	ret
	ldb	a, 1
	stb_d8	0x37c9, a
	calr	40
	cp	a, 129
	jr	nz, 32
	ldb	a, 2
	stb_d8	0x37c9, a
	calr	26
	cp	a, 129
	jr	nz, 18
	ldb	a, 4
	stb_d8	0x37c9, a
	calr	12
	cp	a, 129
	jr	nz, 4
	ldb	w, 0
	jr	2
	ldb	w, 1
	ret
	ld	xix, 0x342d
	push	xix
	calr	62735
	pop	xix
	.byte 0xc3
	pop	sr
	.byte 0xf0, 0xe4
	ldb	a, 14
	push	l
	lds32	xhl, 0
	pop	l
	and	l, 7
	add	xhl, AccVoice_SetupSlots_DataBlock_0x4B2
	ld	l, (xhl)
	ret
	.byte 0x01
	push	sr
	.byte 0x04
	ldio	16, 32
	ld	xwa, 0xf4eb1e40
	push	xbc
	add	xbc, 0x342d
	ld	xix, xbc
	pop	xbc
	sll	xbc, 2
	add	xbc, 0x3898
	ld	xwa, (xbc)
	ld	a, (xwa)
	cp	a, 144
	jr	z, 25
	cp	a, 145
	jr	z, 20
	ld	w, a
	and	w, 240
	cp	w, 208
	jr	z, 10
	ld	(xix), a
	cp	a, 135
	jr	nz, 1
	nop
	jr	8
	ld	xwa, (xbc)
	inc	1, xwa
	ld	a, (xwa)
	ld	(xix), a
	ret
	ldb	l, 0
	ldb	a, 0
	ld	xix, 0x342d
	cps	l, 2
	jr	gt, 46
	cps	a, 2
	jr	gt, 42
	.byte 0xc3
	pop	sr
	.byte 0xf0, 0xec
	ldb	h, 206
	ldw	hl, 0x6607
	.byte 0x04
	inc	1, l
	jr	26
	.byte 0xc3
	pop	sr
	.byte 0xf0, 0xe0
	ldb	w, 200
	ldw	hl, 0x6607
	.byte 0x04
	inc	1, a
	jr	12
	cp	h, w
	jr	gt, 4
	inc	1, a
	jr	4
	inc	1, l
	jr	0
	jr	-50
	cps	l, 2
	jr	le, 2
	ldb	l, 0
	ret
	calr	62568
	ld	ix, bc
	sll	xbc, 2
	add	xbc, 0x3898
	ld	xwa, (xbc)
	ld	a, (xwa)
	cp	a, 144
	jr	z, 17
	cp	a, 145
	jr	z, 12
	ld	e, a
	and	a, 240
	cp	a, 208
	jr	z, 2
	jr	38
	ld	xwa, (xbc)
	inc	2, xwa
	ld	a, (xwa)
	calr	30
	.byte 0xc1, 0xc9, 0x37, 0xf3
	jr	z, 23
	calr	62513
	sll	xbc, 2
	add	xbc, 0x3898
	ld	xix, (xbc)
	push	xbc
	calr	42
	pop	xbc
	ld	(xbc), xix
	jr	-64
	ret
	push_a
	calr	62488
	ld	xwa, 0x3881
	.byte 0xc3
	reti
	.byte 0xe0, 0xe4
	ldb	e, 205
	.byte 0x04
	lds32	xde, 0
	pop	e
	sll	de, 7
	add	xde, Display_FontPalette_Table_0x6E9A
	pop_a
	.byte 0xc3
	pop	sr
	or	xwa, xwa
	ldb	c, 14
	ld	a, (xix)
	calr	64371
	push	c
	lds32	xbc, 0
	pop	c
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
	stdi8 0x37c9, 16
	bitda 0, 0x379b
	jr nz, CmpMode_NullRet
	stdi8 0x37c9, 32
	bitda 1, 0x379b
	jr nz, CmpMode_NullRet
	stdi8 0x37c9, 64
	bitda 2, 0x379b
	jr nz, CmpMode_NullRet
	stdi8 0x37c9, 8
	bitda 3, 0x379b
	jr nz, CmpMode_NullRet
	stdi8 0x37c9, 1

CmpMode_NullRet:
	ret

__pad_F67D15:
	push	xiz
	call	__pad_F67D15_0x7
	pop	xiz
	ret
	ldb_d8	e, 0x37c9
	and	e, 1
	cps	e, 1
	jr	z, 70
	ldb_d8	e, 0x37c9
	and	e, 2
	cps	e, 2
	jr	z, 66
	ldb_d8	e, 0x37c9
	and	e, 4
	cps	e, 4
	jr	z, 48
	ldb_d8	e, 0x37c9
	and	e, 8
	cp	e, 8
	jr	z, 57
	ldb_d8	e, 0x37c9
	and	e, 16
	cp	e, 16
	jr	z, 52
	ldb_d8	e, 0x37c9
	and	e, 32
	cp	e, 32
	jr	z, 47
	ldb_d8	e, 0x37c9
	and	e, 64
	cp	e, 64
	jr	z, 42
	stdi8	0x39b8, 0
	jr	42
	stdi8	0x39b8, 1
	jr	35
	stdi8	0x39b8, 2
	jr	28
	stdi8	0x39b8, 3
	jr	21
	stdi8	0x39b8, 4
	jr	14
	stdi8	0x39b8, 5
	jr	7
	stdi8	0x39b8, 6
	jr	0
	ret
; CmpMenuTtlFunc setup
CmpMenuTtl_Setup:
CmpModeFunc:
	cp xbc, 0x1c00013
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
	cp xbc, 0x1c00007
	jr z, CmpMenuTtl_SpecialKeys
	cp xbc, 0x1c00013
	jr nz, CmpMenuTtl_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jr c, CmpMenuTtl_ReturnZero
	cp xde, 0x6
	jr ugt, CmpMenuTtl_ReturnZero
	add xde, xde
	add xde, Display_FontPalette_Table_0x701A
	ld de, (xde)
	lda_24 xix, CmpMenuTtl_Dispatch
	jp_ind 8, 0x07, 0xf0, 0xe8
; CmpMenuTtlFunc title dispatch
CmpMenuTtl_Dispatch:
	setda	2, 0x28a7
	call	AccWrap_PlayModeDispatch
	jr	t, 0x46

; CmpMenuTtl special key handler (0x88-0x8a)
CmpMenuTtl_SpecialKeys:
	ldb_d8 a, 0x34cd
	cp xde, 0x8a
	jr z, CmpMenuTtl_SetBit4
	cp xde, 0x89
	jr z, CmpMenuTtl_SetBit5
	cp xde, 0x88
	jr nz, CmpMenuTtl_ReturnZero
	anddi8 0x34cd, 207
	ldw wa, 0xb1
	jr CmpMenuTtl_PostModeEvent

; CmpMenuTtl set mode bit 5
CmpMenuTtl_SetBit5:
	and a, 0xcf
	set 5, a
	stb_d8 0x34cd, a
	ldw wa, 0xb1
	jr CmpMenuTtl_PostModeEvent

; CmpMenuTtl set mode bit 4
CmpMenuTtl_SetBit4:
	and a, 0xcf
	set 4, a
	stb_d8 0x34cd, a
	ldw wa, 0xb1

; CmpMenuTtl post mode change event
CmpMenuTtl_PostModeEvent:
	call UI_PostModeChangeEvent

CmpMenuTtl_ReturnZero:
	lds32 xhl, 0
	ret
; CmpSetTtlFunc main handler
CmpSetTtl_MainHandler:
CmpSetTtlFunc:
	cp xbc, 0x1c00007
	jr z, CmpSetTtl_ModeSwitch
	cp xbc, 0x1c00013
	jrl nz, CmpReal_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, CmpReal_ReturnZero
	cp xde, 0x6
	jrl ugt, CmpReal_ReturnZero
	add xde, xde
	add xde, Display_FontPalette_Table_0x7040
	ld de, (xde)
	lda_24 xix, CmpSetTtl_Dispatch
	jp_ind 8, 0x07, 0xf0, 0xe8
; CmpSetTtlFunc title dispatch
CmpSetTtl_Dispatch:
	cpdi8	0x8d37, 180
	jrl	z, 337
	call	RhythmVariation_InlineCode_0x17B
	ld	xwa, 0xb40007
	ld	xbc, 0x01e0008e
	ld	xde, 0xffff0001
	call	ApDeliveryEvent
	jrl	311
	cpdi8	0x8d36, 180
	jrl	z, 303
	call	RhythmConfig_InlineCode2
	jrl	296

; CmpSetTtl mode switch (5-way branch)
CmpSetTtl_ModeSwitch:
	cpdi8 0x350c, 0
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
	sub xde, 0x7a
	cp xde, 0x6
	jr c, CmpReal_ReturnZero
	cp xde, 0xb
	jr ugt, CmpReal_ReturnZero

; CmpSetTtl dynamic table lookup
CmpSetTtl_DynamicLookup:
	add xde, xde
	add xde, Display_FontPalette_Table_0x7028
	ld de, (xde)
	lda_24 xix, CmpSetTtl_Dispatch2
	jp_ind 8, 0x07, 0xf0, 0xe8
; CmpSetTtlFunc title dispatch 2
CmpSetTtl_Dispatch2:
	.asciz ":;<> "
	call	TimeSig_DisplayStrings_0x843
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
	ret
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
	cp xbc, 0x1c00007
	jr z, CmpRealTtl_MajorDispatch
	cp xbc, 0x1c00013
	jrl nz, CmpBk_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, CmpBk_ReturnZero
	cp xde, 0x6
	jrl ugt, CmpBk_ReturnZero
	add xde, xde
	add xde, Display_FontPalette_Table_0x7068
	ld de, (xde)
	lda_24 xix, CmpRealTtl_Dispatch
	jp_ind 8, 0x07, 0xf0, 0xe8
; CmpRealTtlFunc title dispatch
CmpRealTtl_Dispatch:
	.ascii ":;<>"
	call	RhythmFillIn_PatternTable_0x8
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	calr	7235
	jrl	678
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	RhythmFillIn_PatternTable_0x8
	.ascii "^\\[Zx—"
	push	sr

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
	cp xwa, 0xc
	jrl ugt, CmpBk_ReturnZero
	add xwa, xwa
	add xwa, Display_FontPalette_Table_0x704E
	ld wa, (xwa)
	lda_24 xix, CmpRealTtl_RhythmVar0
	jp_ind 8, 0x07, 0xf0, 0xe0

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
	ld xwa, 0xb50019
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb5001b
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb5001a
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb50018
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb5001c
	ld xbc, 0x1c0000b
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
	ld xwa, 0xb50019
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb5001b
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb5001a
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb50018
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb5001c
	ld xbc, 0x1c0000b
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
	ld xwa, 0xb50019
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb5001b
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb5001a
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb50018
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb5001c
	ld xbc, 0x1c0000b
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
	ld xwa, 0xb50019
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb5001b
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb5001a
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb50018
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb5001c
	ld xbc, 0x1c0000b
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
	ld xwa, 0xb50019
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb5001b
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb5001a
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb50018
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb5001c
	ld xbc, 0x1c0000b
	lds32 xde, 0
	jr CmpBk_DeliverEvent
	setda 1, 0x34cf
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
	ld xwa, 0xb5001d
	ld xbc, 0x1c0000b
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
	ld xwa, 0xb50019
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb5001b
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb5001a
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb50018
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb5001c
	ld xbc, 0x1c0000b
	lds32 xde, 0

CmpBk_DeliverEvent:
	call ApDeliveryEvent

CmpBk_ReturnZero:
	lds32 xhl, 0
	ret
; CmpOffsetFunc dispatch
CmpOffset_Dispatch:
CmpBkslTtlFunc:
	cp xbc, 0x1c00007
	jr z, CmpBkslTtl_Mode1
	cp xbc, 0x1c00013
	jrl nz, CmpBksl_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, CmpBksl_ReturnZero
	cp xde, 0x6
	jrl ugt, CmpBksl_ReturnZero
	add xde, xde
	add xde, Display_FontPalette_Table_0x7076
	ld de, (xde)
	lda_24 xix, CmpBkslTtl_Dispatch
	jp_ind 8, 0x07, 0xf0, 0xe8
; CmpBkslTtlFunc title dispatch
CmpBkslTtl_Dispatch:
	.ascii ":;<>"
	call	DrumKit_InlineCode1_0x8
	.ascii "^\\[Zx."
	.byte 0x01
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	DrumKit_InlineCode1_0x8
	pop	xiz
	.ascii "\\[Zx"
	.byte 0x1f, 0x01

; CmpBkslTtl mode 1
CmpBkslTtl_Mode1:
	cp xde, 0x8c
	jrl z, CmpBkslTtl_ModeDefault
	cp xde, 0xc
	jrl z, CmpBkslTtl_ModeSelect
	cp xde, 0x8b
	jrl z, DrumSlot_Dispatch_Slot6
	cp xde, 0xb
	jrl z, DrumSlot_Dispatch_Slot7
	cp xde, 0x8a
	jrl z, DrumSlot_Dispatch_Slot4
	cp xde, 0xa
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
	ldw wa, 0xb2
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
	ldw wa, 0xb2
	jrl CmpBksl_ApplyAndReturnZero

DrumSlot_Dispatch_Slot3_WithMode:
	push xde
	push xhl
	push xix
	push xiz
	lds hl, 3
	call DrumSlot_DispatchWrapper
	ldw wa, 0xb2
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
	ldw wa, 0xb2
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
	ldw wa, 0xb2
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
	ldw wa, 0xb2
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
	ldw wa, 0xb2
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
	ldw wa, 0xb2
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
	ldw wa, 0xb2
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
	ldw wa, 0xb2

CmpBksl_ApplyAndReturnZero:
	call UI_PostModeChangeEvent

CmpBksl_ReturnZero:
	lds32 xhl, 0
	ret
; CmpBksl_STtlFunc main handler
CmpBkslSTtl_MainHandler:
CmpBksl_STtlFunc:
	cp xbc, 0x1c00007
	jr z, CmpBkslSTtl_DirectMode
	cp xbc, 0x1c00013
	jrl nz, DisplayFunc_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, DisplayFunc_ReturnZero
	cp xde, 0x6
	jrl ugt, DisplayFunc_ReturnZero
	add xde, xde
	add xde, Display_FontPalette_Table_0x709A
	ld de, (xde)
	lda_24 xix, CmpBkslSTtl_Dispatch
	jp_ind 8, 0x07, 0xf0, 0xe8
; CmpBksl_STtlFunc title dispatch
CmpBkslSTtl_Dispatch:
	.ascii ":;<>"
	call	RhythmPatInit_Wrapper
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	stdi8	0x7f42, 0
	jrl	334
	stdi8	0x350c, 0
	jrl	326
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	RhythmPatInit_Wrapper
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
	cp xwa, 0xa
	jrl ugt, DisplayFunc_ReturnZero
	add xwa, xwa
	add xwa, Display_FontPalette_Table_0x7084
	ld wa, (xwa)
	lda_24 xix, CmpBkslSTtl_FillIn4
	jp_ind 8, 0x07, 0xf0, 0xe0

; CmpBkslSTtl fill-in level 4
CmpBkslSTtl_FillIn4:
	cpdi8 0x350c, 0
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
	ldw wa, 0xb5
	jrl CmpBk_PostModeChange

; CmpBkslSTtl fill-in level 5
CmpBkslSTtl_FillIn5:
	cpdi8 0x350c, 0
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
	ldw wa, 0xb5
	jrl CmpBk_PostModeChange

; CmpBkslSTtl fill-in level 6
CmpBkslSTtl_FillIn6:
	cpdi8 0x350c, 0
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
	ldw wa, 0xb5
	jrl CmpBk_PostModeChange

; CmpBkslSTtl fill-in level 7
CmpBkslSTtl_FillIn7:
	cpdi8 0x350c, 0
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
	ldw wa, 0xb5
	jr CmpBk_PostModeChange

; CmpBkslSTtl fill-in level 8
CmpBkslSTtl_FillIn8:
	cpdi8 0x350c, 0
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
	ldw wa, 0xb5
	jr CmpBk_PostModeChange
	cpdi8 0x350c, 0
	jr nz, DisplayFunc_ReturnZero
	cpib_da 0x0340ea, 0x00
	jr nz, CmpBkslSTtl_EventPost
	setda 2, 0x34cd
	stdi8 0x7f42, 35
	ldw wa, 0xee
	call SoundCtrl_SendCommand
	jr DisplayFunc_ReturnZero

; CmpBkslSTtl post accompaniment event
CmpBkslSTtl_EventPost:
	stdi8 0x350c, 1
	ld xwa, 0xb20012
	ld xbc, 0x1c00001
	lds32 xde, 5
	call ApPostEvent
	jr DisplayFunc_ReturnZero
	cpdi8 0x350c, 0
	jr nz, DisplayFunc_ReturnZero
	cpdi8 0x34d6, 12
	jr nc, DisplayFunc_ReturnZero
	ldw wa, 0xb3
	jr CmpBk_PostModeChange
	cpdi8 0x350c, 0
	jr nz, DisplayFunc_ReturnZero
	ldw wa, 0xb4

CmpBk_PostModeChange:
	call UI_PostModeChangeEvent

DisplayFunc_ReturnZero:
	lds32 xhl, 0
	ret
; CmpNcpTtlFunc main handler
CmpNcpTtl_MainHandler:
CmpNcpTtlFunc:
	cp xbc, 0x1c00007
	jrl z, CmpNcpTtl_SpecialMode7
	cp xbc, 0x1c00013
	jrl nz, CmEsy_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, CmEsy_ReturnZero
	cp xde, 0x6
	jrl ugt, CmEsy_ReturnZero
	add xde, xde
	add xde, Display_FontPalette_Table_0x70D0
	ld de, (xde)
	lda_24 xix, CmpNcpTtl_Dispatch
	jp_ind 8, 0x07, 0xf0, 0xe8
; CmpNcpTtlFunc title dispatch
CmpNcpTtl_Dispatch:
	.ascii ":;<>"
	call	DrumVoice_Handler7_0x75
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ldb_d8	a, 0x3a80
	cps	a, 1
	jr	z, 22
	cps	a, 0
	jrl	nz, 1482
	lds	wa, 1
	call	UI_PostDialEnable
	lds	wa, 2
	call	UI_PostDialValueEvent
	ldw	wa, 130
	jr	95
	lds	wa, 1
	call	UI_PostDialEnable
	lds	wa, 6
	call	UI_PostDialValueEvent
	ldw	wa, 134
	jr	78
	lds	wa, 0
	call	UI_PostDialEnable
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	DrumVoice_Handler7_0xEE
	.ascii "^\\[Zx"
	.byte 0x93
	halt
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	DrumVoice_Handler7_0x75
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ldb_d8	a, 0x3a80
	cps	a, 1
	jr	z, 22
	cps	a, 0
	jrl	nz, 1402
	lds	wa, 1
	call	UI_PostDialEnable
	lds	wa, 2
	call	UI_PostDialValueEvent
	ldw	wa, 130
	jr	15
	lds	wa, 1
	call	UI_PostDialEnable
	lds	wa, 6
	call	UI_PostDialValueEvent
	ldw	wa, 134
	call	UI_PostDialRangeEvent
	jrl	1363

; CmpNcpTtl special mode 7
CmpNcpTtl_SpecialMode7:
	cp xde, 0xb
	jr ule, CmpNcpTtl_TableDispatch
	sub xde, 0x74
	cp xde, 0xc
	jrl c, CmEsy_ReturnZero
	cp xde, 0x13
	jrl ugt, CmEsy_ReturnZero

; CmpNcpTtl table-driven dispatch
CmpNcpTtl_TableDispatch:
	add xde, xde
	add xde, Display_FontPalette_Table_0x70A8
	ld de, (xde)
	lda_24 xix, CmpNcpTtl_Dispatch2
	jp_ind 8, 0x07, 0xf0, 0xe8
; CmpNcpTtlFunc title dispatch 2
CmpNcpTtl_Dispatch2:
	lds	wa, 1
	call	UI_PostEvent_0x6E
	push	xde
	push	xhl
	push	xix
	push	xiz
	ldb	w, 0
	call	DrumVoice_Handler7_0x100
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	.byte 0xc1, 0x80
	push	xde
	push	xsp
	nop
	jr	z, 56
	stdi8	0x3a80, 0
	ld	xwa, 0xb8001b
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb8001a
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	lds	wa, 1
	call	UI_PostDialEnable
	lds	wa, 2
	call	UI_PostDialValueEvent
	ldw	wa, 130
	call	UI_PostDialRangeEvent
	ld	xwa, 0xb8001e
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb8001f
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb80012
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	jrl	1171
	lds	wa, 1
	call	UI_PostEvent_0x6E
	.ascii ":;<> "
	.byte 0x80
	call	DrumVoice_Handler7_0x100
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	.byte 0xc1, 0x80
	push	xde
	push	xsp
	nop
	jr	z, 56
	stdi8	0x3a80, 0
	ld	xwa, 0xb8001b
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb8001a
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	lds	wa, 1
	call	UI_PostDialEnable
	lds	wa, 2
	call	UI_PostDialValueEvent
	ldw	wa, 130
	call	UI_PostDialRangeEvent
	ld	xwa, 0xb8001e
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb8001f
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb80012
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	jrl	1041
	lds	wa, 1
	.byte 0x1d, 0x45
	cp	(xiy), bc
	.asciz ":;<> "
	call	DrumVoice_Handler7_0x123
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	.byte 0xc1, 0x80
	push	xde
	push	xsp
	nop
	jr	z, 56
	stdi8	0x3a80, 0
	ld	xwa, 0xb8001b
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb8001a
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	lds	wa, 1
	call	UI_PostDialEnable
	lds	wa, 2
	call	UI_PostDialValueEvent
	ldw	wa, 130
	call	UI_PostDialRangeEvent
	ldb_d8	a, 0x39a7
	cps	a, 2
	jr	z, 87
	cps	a, 1
	jr	z, 52
	cps	a, 0
	jrl	nz, 951
	ld	xwa, 0xb8001e
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb8001f
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb80012
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	jrl	894
	ld	xwa, 0xb8001f
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb8001b
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	jrl	863
	ld	xwa, 0xb80012
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb8001b
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	jrl	832
	lds	wa, 1
	call	UI_PostEvent_0x6E
	.ascii ":;<> "
	.byte 0x80
	call	DrumVoice_Handler7_0x123
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	.byte 0xc1, 0x80
	push	xde
	push	xsp
	nop
	jr	z, 56
	stdi8	0x3a80, 0
	ld	xwa, 0xb8001b
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb8001a
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	lds	wa, 1
	call	UI_PostDialEnable
	lds	wa, 2
	call	UI_PostDialValueEvent
	ldw	wa, 130
	call	UI_PostDialRangeEvent
	ldb_d8	a, 0x39a7
	cps	a, 2
	jr	z, 87
	cps	a, 1
	jr	z, 52
	cps	a, 0
	jrl	nz, 742
	ld	xwa, 0xb8001e
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb8001f
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb80012
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	jrl	685
	ld	xwa, 0xb8001f
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb8001b
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	jrl	654
	ld	xwa, 0xb80012
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb8001b
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	jrl	623
	push	xde
	push	xhl
	push	xix
	push	xiz
	ldb	w, 0
	call	DrumVoice_Handler7_0x146
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	.byte 0xc1, 0x80
	push	xde
	push	xsp
	.byte 0x01
	jr	z, 72
	stdi8	0x3a80, 1
	ld	xwa, 0xb8001e
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb8001f
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb80012
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	lds	wa, 1
	call	UI_PostDialEnable
	lds	wa, 6
	call	UI_PostDialValueEvent
	ldw	wa, 134
	call	UI_PostDialRangeEvent
	ld	xwa, 0xb8001a
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb8001b
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	jrl	499
	.ascii ":;<> €"
	call	DrumVoice_Handler7_0x146
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	.byte 0xc1, 0x80
	push	xde
	push	xsp
	.byte 0x01
	jr	z, 72
	stdi8	0x3a80, 1
	ld	xwa, 0xb8001e
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb8001f
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb80012
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	lds	wa, 1
	call	UI_PostDialEnable
	lds	wa, 6
	call	UI_PostDialValueEvent
	ldw	wa, 134
	call	UI_PostDialRangeEvent
	ld	xwa, 0xb8001b
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb8001a
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	jrl	375
	lds	wa, 1
	call	UI_PostEvent_0x6E
	push	xde
	push	xhl
	push	xix
	push	xiz
	ldb	w, 0
	call	DrumVoice_Handler7_0x169
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	.byte 0xc1, 0x80
	push	xde
	push	xsp
	.byte 0x01
	jr	z, 72
	stdi8	0x3a80, 1
	ld	xwa, 0xb8001e
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb8001f
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb80012
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	lds	wa, 1
	call	UI_PostDialEnable
	lds	wa, 6
	call	UI_PostDialValueEvent
	ldw	wa, 134
	call	UI_PostDialRangeEvent
	ldb_d8	a, 0x39a8
	cps	a, 1
	jr	z, 52
	cps	a, 0
	jrl	nz, 273
	ld	xwa, 0xb8001a
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb8001b
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb80012
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	jrl	216
	ld	xwa, 0xb8001b
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb80012
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	jrl	185
	lds	wa, 1
	.byte 0x1d, 0x45
	cp	(xiy), bc
	.ascii ":;<> €"
	call	DrumVoice_Handler7_0x169
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	.byte 0xc1, 0x80
	push	xde
	push	xsp
	.byte 0x01
	jr	z, 72
	stdi8	0x3a80, 1
	ld	xwa, 0xb8001e
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb8001f
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb80012
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	lds	wa, 1
	call	UI_PostDialEnable
	lds	wa, 6
	call	UI_PostDialValueEvent
	ldw	wa, 134
	call	UI_PostDialRangeEvent
	ldb_d8	a, 0x39a8
	cps	a, 1
	jr	z, 50
	cps	a, 0
	jr	nz, 84
	ld	xwa, 0xb8001a
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb8001b
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb80012
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	jr	28
	ld	xwa, 0xb8001b
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb80012
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	jr	4
	.byte 0xf1, 0xd1, 0x34, 0xb8

CmEsy_ReturnZero:
	lds32 xhl, 0
	ret
; CmEsyTtlFunc main handler
CmpEsyTtl_MainHandler:
CmEsyTtlFunc:
	cp xbc, 0x1c00007
	jrl z, CmpEsyTtl_Mode1
	cp xbc, 0x1c00013
	jrl nz, S2cTtl_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, S2cTtl_ReturnZero
	cp xde, 0x6
	jrl ugt, S2cTtl_ReturnZero
	add xde, xde
	add xde, Display_FontPalette_Table_0x70FE
	ld de, (xde)
	lda_24 xix, CmEsyTtl_Dispatch
	jp_ind 8, 0x07, 0xf0, 0xe8
; CmEsyTtlFunc title dispatch
CmEsyTtl_Dispatch:
	cpdi8	0x8d37, 186
	jrl	z, 388
	ldb_d8	a, 0x34d6
	cp	a, 29
	jr	ule, 10
	sub	a, 30
	sll	a, 2
	stb_d8	0x34d6, a
	ordi8	0x37c8, 127
	resda	2, 0x28a7
	resda	6, 0x34cd
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	DrumKit_InlineCode1_0x7F
	call	DrumKitExit_DataPad_0x1
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	stdi8	0x34f1, 0
	ld	xwa, 0xba000a
	ld	xbc, 0x01e0008e
	ld	xde, 0xffff0002
	jrl	219
	cpdi8	0x37b9, 255
	jrl	z, 309
	lda_d16	xiy, 0x37b9
	lda_d16	xix, 0x37ab
	lda_d16	xhl, 0x37c0
	lda_d16	xde, 0x37b2
	lds32	xbc, 0
	ldb_spi	a, 244
	.byte 0xf5, 0xf0, 0x41
	ldb_spi	a, 236
	.byte 0xf5, 0xe8, 0x41
	inc	1, xbc
	cp	xbc, 7
	jr	c, -22
	.byte 0xc1, 0xc7, 0x37
	pop_f
	.byte 0xd6, 0x34
	jrl	260

; CmpEsyTtl mode 1
CmpEsyTtl_Mode1:
	cp xde, 0xb
	jr ule, CmpEsyTtl_Mode2
	sub xde, 0x74
	cp xde, 0xc
	jrl c, S2cTtl_ReturnZero
	cp xde, 0x13
	jrl ugt, S2cTtl_ReturnZero

; CmpEsyTtl mode 2
CmpEsyTtl_Mode2:
	add xde, Display_FontPalette_Table_0x70DE
	ld de, (xde)
	extz de
	sll de, 1
	ld xix, Display_FontPalette_Table_0x70F2
	ldw_sri DE, 0x07, 0xf0, 0xe8
	lda_24 xix, CmEsyTtl_Dispatch2
	jp_ind 8, 0x07, 0xf0, 0xe8
; CmEsyTtlFunc title dispatch 2
CmEsyTtl_Dispatch2:
	; --- Multi-branch dispatch subroutine (195 bytes) ---
	lds	wa, 0
	jrl t, CmpEsyTtl_SubModeD_Cont
	push xde
	push xhl
	push xix
	push xiz
	call ExtVoice_ProcessList_0x1
	call TimeSig_DisplayStrings_0x7C6
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw wa, 0x00b5
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
	ld xwa, 0x00ba0009
	ld xbc, 0x01c0000b
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
	ld xwa, 0x00ba0009
	ld xbc, 0x01c0000b
	lds32	xde, 0
CmpEsy_DeliverEventAndCheck:
	call ApDeliveryEvent
	jr t, S2cTtl_ReturnZero
	cpdi8	0x37c8, 0
	jr z, CmpEsyTtl_SubModeC
	push xde
	push xhl
	push xix
	push xiz
	call ExtVoice_ProcessList_0x1C
	pop xiz
	pop xix
	pop xhl
	pop xde
	cpdi8	0x7f42, 0
	jr nz, CmpEsyTtl_SubModeD
	lda_d16	xiy, 0x37ab
	lda_d16	xix, 0x37b9
	lda_d16	xhl, 0x37b2
	lda_d16	xde, 0x37c0
	lds32	xbc, 0
; CmpEsyTtl sub-mode B
CmpEsyTtl_SubModeB:
	ldb_spi	a, 244
	.byte 0xf5, 0xf0, 0x41
	ldb_spi	a, 236
	.byte 0xf5, 0xe8, 0x41
	inc 1, xbc
	cp xbc, 0x00000007
	jr c, CmpEsyTtl_SubModeB
	.byte 0xc1, 0xd6
	ldw	ix, 0xc719
	.byte 0x37
	jr t, CmpEsyTtl_SubModeD
; CmpEsyTtl sub-mode C
CmpEsyTtl_SubModeC:
	push xde
	push xhl
	push xix
	push xiz
	call ExtVoice_ProcessList_0x1
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
	cp xbc, 0x1c00007
	jrl z, CmpEsyTtl_E_Var1
	cp xbc, 0x1c00013
	jrl nz, CstmCp_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, CstmCp_ReturnZero
	cp xde, 0x6
	jrl ugt, CstmCp_ReturnZero
	add xde, xde
	add xde, Display_FontPalette_Table_0x7124
	ld de, (xde)
	lda_24 xix, S2cTtl_Dispatch
	jp_ind 8, 0x07, 0xf0, 0xe8
; S2cTtlFunc title dispatch
S2cTtl_Dispatch:
	cpdi8	0x8d37, 185
	jr	z, 19
	ld	xwa, 0xb90021
	ld	xbc, 0x01e0008e
	ld	xde, 0xffff0002
	call	ApDeliveryEvent
	call	TimeSig_DisplayStrings_0x8E2
	jrl	999
	ldb_d8	a, 0x3a77
	cps	a, 2
	jr	z, 43
	cps	a, 1
	jr	z, 22
	cps	a, 0
	jrl	nz, 982
	lds	wa, 1
	call	UI_PostDialEnable
	lds	wa, 0
	call	UI_PostDialValueEvent
	ldw	wa, 128
	jr	32
	lds	wa, 1
	call	UI_PostDialEnable
	lds	wa, 1
	call	UI_PostDialValueEvent
	ldw	wa, 129
	jr	15
	lds	wa, 1
	call	UI_PostDialEnable
	lds	wa, 2
	call	UI_PostDialValueEvent
	ldw	wa, 130
	call	UI_PostDialRangeEvent
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
	cp xwa, 0xb
	jrl ugt, CstmCp_ReturnZero
	add xwa, xwa
	add xwa, Display_FontPalette_Table_0x710C
	ld wa, (xwa)
	lda_24 xix, CmpEsy_E_DispatchDataBlock
	jp_ind 8, 0x07, 0xf0, 0xe0

CmpEsy_E_DispatchDataBlock:
	lds	wa, 1
	call	UI_PostEvent_0x6E
	lds	wa, 1
	call	UI_PostDialEnable
	lds	wa, 0
	call	UI_PostDialValueEvent
	ldw	wa, 128
	call	UI_PostDialRangeEvent
	lds	wa, 0
	call	Tempo_AdjustStartMeasure
	cpdi8	0x3a77, 0
	jr	nz, 31
	ld	xwa, 0xb9001c
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb9001f
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	jrl	769
	stdi8	0x3a77, 0
	ld	xwa, 0xb9001c
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb9001f
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb90018
	ld	xbc, 0x01c0000c
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xb90021
	ld	xbc, 0x01e40031
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
	cpdi8 0x3a77, 0
	jr nz, CmpEsy_E_Var2_StoreMeasure
	ld xwa, 0xb9001c
	ld xbc, 0x1c0000c
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb9001f
	ld xbc, 0x1c0000c
	lds32 xde, 0
	jrl TtlFunc_SendEventAndReturn

CmpEsy_E_Var2_StoreMeasure:
	stdi8 0x3a77, 0
	ld xwa, 0xb9001c
	ld xbc, 0x1c0000c
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb9001f
	ld xbc, 0x1c0000c
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb90018
	ld xbc, 0x1c0000c
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb90021
	ld xbc, 0x1e40031
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
	cpdi8 0x3a77, 1
	jr nz, CmpEsy_E_EndMeasure_Store
	ld xwa, 0xb9001f
	ld xbc, 0x1c0000c
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb9001c
	ld xbc, 0x1c0000c
	lds32 xde, 0
	jrl TtlFunc_SendEventAndReturn

CmpEsy_E_EndMeasure_Store:
	stdi8 0x3a77, 1
	ld xwa, 0xb9001f
	ld xbc, 0x1c0000c
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb9001c
	ld xbc, 0x1c0000c
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb90018
	ld xbc, 0x1c0000c
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb90021
	ld xbc, 0x1e40031
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
	cpdi8 0x3a77, 1
	jr nz, CmpEsy_Main_EndMeasure_Store
	ld xwa, 0xb9001f
	ld xbc, 0x1c0000c
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb9001c
	ld xbc, 0x1c0000c
	lds32 xde, 0
	jrl TtlFunc_SendEventAndReturn

CmpEsy_Main_EndMeasure_Store:
	stdi8 0x3a77, 1
	ld xwa, 0xb9001f
	ld xbc, 0x1c0000c
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb9001c
	ld xbc, 0x1c0000c
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb90018
	ld xbc, 0x1c0000c
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb90021
	ld xbc, 0x1e40031
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
	cpdi8 0x3a77, 2
	jr nz, CmpEsy_Quantize_Store
	ld xwa, 0xb90018
	ld xbc, 0x1c0000c
	lds32 xde, 0
	jrl TtlFunc_SendEventAndReturn

CmpEsy_Quantize_Store:
	stdi8 0x3a77, 2
	ld xwa, 0xb90018
	ld xbc, 0x1c0000c
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb9001f
	ld xbc, 0x1c0000c
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb9001c
	ld xbc, 0x1c0000c
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb90021
	ld xbc, 0x1e40031
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
	cpdi8 0x3a77, 2
	jr nz, CmpEsy_SecQuantize_Store
	ld xwa, 0xb90018
	ld xbc, 0x1c0000c
	lds32 xde, 0
	jr TtlFunc_SendEventAndReturn

CmpEsy_SecQuantize_Store:
	stdi8 0x3a77, 2
	ld xwa, 0xb90018
	ld xbc, 0x1c0000c
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb9001f
	ld xbc, 0x1c0000c
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb9001c
	ld xbc, 0x1c0000c
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb90021
	ld xbc, 0x1e40031
	lds32 xde, 0
	jr TtlFunc_SendEventAndReturn
	lds wa, 1
	call UI_PostEvent_0x6E
	lds wa, 0
	call Tempo_IncrementTimeSigNum
	ld xwa, 0xb9001e
	ld xbc, 0x1c0000c
	lds32 xde, 0
	jr TtlFunc_SendEventAndReturn
	lds wa, 1
	call UI_PostEvent_0x6E
	lds wa, 0
	call Tempo_DecrementTimeSigNum
	ld xwa, 0xb9001e
	ld xbc, 0x1c0000c
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
	cp xbc, 0x1c00007
	jrl z, CstmCpTtl_RecMode1
	cp xbc, 0x1c00013
	jrl nz, CstmCp_ReturnZero2
	dec 2, xde
	cp xde, 0x0
	jrl c, CstmCp_ReturnZero2
	cp xde, 0x6
	jrl ugt, CstmCp_ReturnZero2
	add xde, xde
	add xde, Display_FontPalette_Table_0x715A
	ld de, (xde)
	lda_24 xix, CstmCpTtl_Dispatch
	jp_ind 8, 0x07, 0xf0, 0xe8
; CstmCpTtlFunc title dispatch
CstmCpTtl_Dispatch:
	cpdi8	0x8d37, 190
	jr	z, 8
	stdi8	0x3a7e, 0
	jrl	804
	cpdi8	0x8d39, 238
	jrl	nz, 796
	ldb_d8	a, 0x3a7e
	cps	a, 2
	jr	z, 5
	cps	a, 1
	jrl	nz, 783
	cpdi8	0x39b6, 3
	jr	nc, 15
	ld	xwa, 0xbe0011
	ld	xbc, 0x01c00001
	lds32	xde, 5
	jrl	708
	ld	xwa, 0xbe0019
	ld	xbc, 0x01c00001
	lds32	xde, 5
	jrl	693
	ldb_d8	a, 0x3a7e
	cps	a, 2
	jr	z, 5
	cps	a, 1
	jrl	nz, 733
	cpdi8	0x39b6, 3
	jr	nc, 15
	ld	xwa, 0xbe0011
	ld	xbc, 0x01c00001
	lds32	xde, 5
	jrl	658
	ld	xwa, 0xbe0019
	ld	xbc, 0x01c00001
	lds32	xde, 5
	jrl	t, 0x0283

; CstmCpTtl record mode 1
CstmCpTtl_RecMode1:
	cp xde, 0xb
	jr ule, CstmCpTtl_RecMode2
	sub xde, 0x74
	cp xde, 0xc
	jrl c, CstmCp_ReturnZero2
	cp xde, 0x13
	jrl ugt, CstmCp_ReturnZero2

; CstmCpTtl record mode 2
CstmCpTtl_RecMode2:
	add xde, xde
	add xde, Display_FontPalette_Table_0x7132
	ld de, (xde)
	lda_24 xix, CstmCpTtl_Dispatch2
	jp_ind 8, 0x07, 0xf0, 0xe8
; CstmCpTtlFunc title dispatch 2
CstmCpTtl_Dispatch2:
	cpdi8	0x3a7e, 0
	jrl	nz, 636
	lds	wa, 1
	call	UI_PostEvent_0x6E
	ldb	c, 29
	ldb_d8	a, 0x39b6
	cp	a, 10
	jr	nc, 2
	ldb	c, 2
	cp	a, c
	jrl	nc, 612
	inc	1, a
	stb_d8	0x39b6, a
	ld	xwa, 0xbe0003
	ld	xbc, 0x01c0000b
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xbe0004
	ld	xbc, 0x01c0000d
	lds32	xde, 0
	jrl	322
	cpdi8	0x3a7e, 0
	jrl	nz, 567
	lds	wa, 1
	call	UI_PostEvent_0x6E
	ldb	c, 10
	ldb_d8	a, 0x39b6
	cp	a, 10
	jr	nc, 2
	ldb	c, 0
	cp	a, c
	jrl	ule, 543
	dec	1, a
	stb_d8	0x39b6, a
	ld	xwa, 0xbe0003
	ld	xbc, 0x01c0000b
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xbe0004
	ld	xbc, 0x01c0000d
	lds32	xde, 0
	jrl	253
	cpdi8	0x3a7e, 0
	jrl	nz, 498
	ldb_d8	a, 0x39b6
	ldb_d8	c, 0x39b7
	stb_d8	0x39b6, c
	stb_d8	0x39b7, a
	ld	xwa, 0xbe0003
	ld	xbc, 0x01c0000b
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xbe000b
	ld	xbc, 0x01c0000b
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xbe000d
	ld	xbc, 0x01c0000b
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xbe000e
	ld	xbc, 0x01c0000b
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xbe0004
	ld	xbc, 0x01c0000d
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xbe000f
	ld	xbc, 0x01c0000d
	lds32	xde, 0
	jrl	134
	cpdi8	0x3a7e, 0
	jrl	nz, 379
	lds	wa, 1
	call	UI_PostEvent_0x6E
	ldb	c, 29
	ldb_d8	a, 0x39b7
	cp	a, 10
	jr	nc, 2
	ldb	c, 2
	cp	a, c
	jrl	nc, 355
	inc	1, a
	stb_d8	0x39b7, a
	ld	xwa, 0xbe000b
	ld	xbc, 0x01c0000b
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xbe000f
	ld	xbc, 0x01c0000d
	lds32	xde, 0
	jr	66
	cpdi8	0x3a7e, 0
	jrl	nz, 311
	lds	wa, 1
	call	UI_PostEvent_0x6E
	ldb	c, 10
	ldb_d8	a, 0x39b7
	cp	a, 10
	jr	nc, 2
	ldb	c, 0
	cp	a, c
	jrl	ule, 287
	dec	1, a
	stb_d8	0x39b7, a
	ld	xwa, 0xbe000b
	ld	xbc, 0x01c0000b
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 0xbe000f
	ld	xbc, 0x01c0000d
	lds32	xde, 0
	call	ApDeliveryEvent
	jrl	246
	ldb_d8	a, 0x3a7e
	cps	a, 2
	jr	z, 5
	cps	a, 1
	jrl	nz, 233
	lds	wa, 0
	call	Flash_InitBytecodeBlock_0x2BF
	cps	l, 1
	jrl	z, 222
	cps	l, 0
	jrl	nz, 217
	stdi8	0x3a7e, 0
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c00002
	lds32	xde, 0
	call	ApPostEvent
	stdi8	0x7f42, 35
	ldw	wa, 238
	jrl	181
	ldb_d8	a, 0x3a7e
	cps	a, 2
	jrl	z, 129
	cps	a, 1
	jr	z, 125
	cps	a, 0
	jrl	nz, 167
	cpdi8	0x39b6, 3
	jr	nc, 12
	.byte 0xf1, 0x42, 0x7f
	nop
	.long SeqData_SubDispatch_ParamB
	call	SoundCtrl_SendCommand
	ldb_d8	a, 0x39b6
	extz	wa
	ldb_d8	c, 0x39b7
	extz	bc
	call	Flash_InitBytecodeBlock
	cps	l, 2
	jr	z, 28
	cps	l, 1
	jr	z, 14
	cps	l, 0
	jr	nz, 120
	.byte 0xf1, 0x42, 0x7f
	nop
	.long SeqData_SubDispatch_ParamA
	jr	106
	stdi8	0x7f42, 15
	ldw	wa, 238
	jr	96
	ld	xwa, 0xffffffff
	ld	xbc, 0x01e00079
	lds32	xde, 0
	call	ApDeliveryEvent
	cpdi8	0x39b6, 3
	jr	nc, 7
	stdi8	0x3a7e, 1
	jr	70
	stdi8	0x3a7e, 2
	ld	xwa, 0xbe0019
	ld	xbc, 0x01c00001
	lds32	xde, 5
	call	ApPostEvent
	jr	47
	lds	wa, 2
	call	Flash_InitBytecodeBlock_0x2BF
	cps	l, 1
	jr	z, 37
	cps	l, 0
	jr	nz, 33
	stdi8	0x3a7e, 0
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c00002
	lds32	xde, 0
	call	ApPostEvent
	stdi8	0x7f42, 35
	ldw	wa, 238
	call	SoundCtrl_SendCommand

CstmCp_ReturnZero2:
	lds32 xhl, 0
	ret

CstmCp_StyleDataBlock:
	cp	xbc, 0x01e40016
	jr	nz, 40
	ldb_d8	a, 0x39b6
	extz	wa
	ldb_d8	c, 0x39b7
	extz	bc
	call	Flash_InitBytecodeBlock
	cps	l, 2
	jr	z, 20
	cps	l, 1
	jr	z, 16
	cps	l, 0
	jr	nz, 12
	.byte 0xf1, 0x42, 0x7f
	nop
	.long SeqData_SubDispatch_ParamA
	call	SoundCtrl_SendCommand
	lds32	xhl, 0
	ret
__pad_F695CA:

MainCstmNameFunc:
	lda xsp, (xsp - 120)
	push xiz
	ld xde, xbc
	ld xiy, Display_FontPalette_Table_0x7168
	lda xix, (xsp + 4)
	ldw bc, 0x3c
	ldirw
	cp xde, 0x1e4002c
	jr z, CstmName_HandleEvent2C
	cp xde, 0x1e4002b
	jrl nz, CstmName_ReturnZero
	pushw 0x11
	call Malloc
	ld xiz, xhl
	ldb_d8 a, 0x39b6
	extz wa
	sla wa, 2
	lda xbc, (xsp + 6)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	add xwa, 0x40
	pushw 0xd
	push xwa
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 12)
	ld (xiz + 13), 0x0
	ld (xiz + 14), 0x0
	ld (xiz + 15), 0x0
	ld (xiz + 16), 0x0
	ld xwa, 0xbe0004
	ld xbc, 0x1e4002d
	ld xde, xiz
	call ApDeliveryEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e00023
	ld xde, xiz
	jr CstmName_PostEventAndReturn

CstmName_HandleEvent2C:
	pushw 0x11
	call Malloc
	ld xiz, xhl
	ldb_d8 a, 0x39b7
	extz wa
	sla wa, 2
	lda xbc, (xsp + 6)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	add xwa, 0x40
	pushw 0xd
	push xwa
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 12)
	ld (xiz + 13), 0x0
	ld (xiz + 14), 0x0
	ld (xiz + 15), 0x0
	ld (xiz + 16), 0x0
	ld xwa, 0xbe000f
	ld xbc, 0x1e4002e
	ld xde, xiz
	call ApDeliveryEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e00023
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
	cp xbc, 0x1e40011
	jr z, S2cFunc_HandleEvent11
	cp xbc, 0x1e40010
	jrl nz, EventDelivery_ReturnZero
	stb_d8 0x3990, a
	lds wa, 0
	call Tempo_AdjustEffect
	ld xwa, (xsp)
	ld de, wa
	extz xde
	add xde, 0x10000
	ld xwa, 0xb90021
	ld xbc, 0x1e0008d
	call ApDeliveryEvent
	cpdi8 0x3a77, 3
	jrl z, EventDelivery_ReturnZero
	stdi8 0x3a77, 3
	ld xwa, 0xb9001c
	ld xbc, 0x1c0000c
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb9001f
	ld xbc, 0x1c0000c
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb90018
	ld xbc, 0x1c0000c
	lds32 xde, 0
	jr S2cFunc_DeliverAndReturn

S2cFunc_HandleEvent11:
	stb_d8 0x3990, a
	lds wa, 1
	call Tempo_AdjustEffect
	ld xwa, (xsp)
	ld de, wa
	extz xde
	add xde, 0x10000
	ld xwa, 0xb90021
	ld xbc, 0x1e0008d
	call ApDeliveryEvent
	cpdi8 0x3a77, 3
	jr z, EventDelivery_ReturnZero
	stdi8 0x3a77, 3
	ld xwa, 0xb9001c
	ld xbc, 0x1c0000c
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb9001f
	ld xbc, 0x1c0000c
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xb90018
	ld xbc, 0x1c0000c
	lds32 xde, 0

S2cFunc_DeliverAndReturn:
	call ApDeliveryEvent

EventDelivery_ReturnZero:
	lds32 xhl, 0
	inc 4, xsp
	ret
__pad_F69788:

MiddleNameFunc:
	lda_d16 xwa, 0x34bc
	cp xbc, 0x1e40001
	jr z, MiddleName_HandleEvent01
	cp xbc, 0x1e40000
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
	ldw wa, 0xb2
	jr MiddleName_PostModeChange

MiddleName_HandleEvent01:
	push xde
	push xwa
	call Strcpy
	inc 8, xsp
	ldb_d8 c, 0x7f3e
	ld a, c
	sll a, 4
	cps c, 2
	jr nc, MiddleName_CalcROMAddr_High
	ldb w, 0x0
	extz xwa
	add xwa, 0x1e8a80
	jr MiddleName_CopyAndPost

MiddleName_CalcROMAddr_High:
	sub a, 0x20
	ldb w, 0x0
	extz xwa
	add xwa, 0x1e8a40

MiddleName_CopyAndPost:
	pushw 0x10
	pushw 0x0
	pushw 0x34bc
	push xwa
	call Strncpy
	lda xsp, (xsp + 10)
	ldw wa, 0xca

MiddleName_PostModeChange:
	call UI_PostModeChangeEvent

MiddleName_ReturnZero:
	lds32 xhl, 0
	ret
__pad_F697FE:

MiddleCmpClrFunc:
	cp xbc, 0x1e40007
	jr z, MiddleCmpClr_HandleEvent07
	cp xbc, 0x1e40006
	jr nz, MiddleCmpClr_ReturnZero
	setda 2, 0x34cd
	stdi8 0x350c, 0
	ld xwa, 0xb20012
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	stdi8 0x7f42, 35
	ldw wa, 0xee
	call SoundCtrl_SendCommand
	jr MiddleCmpClr_ReturnZero

MiddleCmpClr_HandleEvent07:
	stdi8 0x350c, 0
	ld xwa, 0xb20012
	ld xbc, 0x1c00002
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0xb20000
	ld xbc, 0x1c0000a
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
	ld xiy, Display_FontPalette_Table_0x71E0
	lda xix, (xsp + 10)
	lds bc, 6
	ldirw
	cp xde, 0x1e40003
	jr z, MainCmpCp_HandleEvent03
	cp xde, 0x1e40002
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
	ld xwa, 0xb8001e
	ld xbc, 0x1e40004
	ld xde, xiz
	call ApDeliveryEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e00023
	ld xde, xiz
	jrl MainCmpSet_Case3

MainCmpCp_HandleEvent03:
	pushw 0xf
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
	cpdi8 0x8d38, 184
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
	pushw 0xd
	extz wa
	sla wa, 2
	lda xbc, (xsp + 12)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	jr MainCmpCp_MemCopyAndFinalize

MemCopy_SetupParams:
	pushw 0xd
	push xhl

MainCmpCp_MemCopyAndFinalize:
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld (xiz + 13), 0x0
	ldb_d8 a, 0x8d38
	cp a, 0xb8
	jr nz, MainCmpSet_Init
	ld xwa, 0xb8001f
	ld xbc, 0x1e40005
	ld xde, xiz
	jr MainCmpSet_Case1

; MainCmpSetFunc init
MainCmpSet_Init:
	cp a, 0xdc
	jr nz, MainCmpSet_Case2
	ld xwa, 0xdc0002
	ld xbc, 0x1e40005
	ld xde, xiz

; MainCmpSetFunc case 1
MainCmpSet_Case1:
	call ApDeliveryEvent

; MainCmpSetFunc case 2
MainCmpSet_Case2:
	ld xwa, 0xffffffff
	ld xbc, 0x1e00023
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
	ldb_d8 a, 0x34d6
	extz wa
	sla wa, 2
	lda_24 xde, RhythmTiming_OffsetTable
	ld xhl, 0x94860
	add_sril_rm XHL, 0x07, 0xe8, 0xe0
	ld xde, xhl
	ld xhl, xbc
	ld xwa, (xsp)
	ld c, a
	sub xhl, 0x1e40008
	cp xhl, 0x0
	jrl lt, CmpSong_VariantA
	cp xhl, 0x7
	jrl gt, CmpSong_VariantA
	add xhl, xhl
	add xhl, NakaInst_MEMORY_A_0xE
	ld hl, (xhl)
	lda_24 xix, MainCmpSet_Dispatch
	jp_ind 8, 0x07, 0xf0, 0xec
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
	add	xde, 0x010000
	ld	xwa, 0xb4000e
	ld	xbc, 0x01e0008d
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
	add	xde, 0x010000
	ld	xwa, 0xb4000e
	ld	xbc, 0x01e0008d
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
	add	xde, 0x020000
	ld	xwa, 0xb4000e
	ld	xbc, 0x01e0008d
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
	add	xde, 0x020000
	ld	xwa, 0xb4000e
	ld	xbc, 0x01e0008d
	jr	106
	ld	a, c
	stb_d8	0x3540, c
	cps	c, 2
	jr	ule, 6
	.byte 0xc9
	jr	gt, 0xf1
	.asciz "@5A:;<> "
	call	DrumVoice_Select
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	xwa, (xsp)
	ld	de, wa
	extz	xde
	add	xde, 0x010000
	ld	xwa, 0xb40007
	ld	xbc, 0x01e0008d
	jr	52
	ld	a, c
	stb_d8	0x3540, c
	cps	c, 2
	jr	ule, 6
	dec	2, a
	.byte 0xf1
	.ascii "@5A:;<> "
	.byte 0x80
	call	DrumVoice_Select
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	xwa, (xsp)
	ld	de, wa
	extz	xde
	add	xde, 0x010000
	ld	xwa, 0xb40007
	ld	xbc, 0x01e0008d
	call	ApDeliveryEvent

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
	cp xbc, 0x1e4002a
	jrl z, EsCmp_HandleEvent2A
	cp xbc, 0x1e40029
	jrl z, EsCmp_HandleEvent29
	cp xbc, 0x1e40028
	jr z, EsCmp_HandleEvent28
	cp xbc, 0x1e40027
	jrl nz, EsCmp_ReturnZero
	stb_d8 0x39b8, a
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
	ld xwa, 0xba000a
	ld xbc, 0x1e0008d
	call ApDeliveryEvent
	ld xwa, (xsp)
	ld de, wa
	extz xde
	add xde, 0x20000
	ld xwa, 0xba000a
	ld xbc, 0x1e0008d
	jrl MspBksl_EventDeliver

EsCmp_HandleEvent28:
	stb_d8 0x39b8, a
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
	ld xwa, 0xba000a
	ld xbc, 0x1e0008d
	call ApDeliveryEvent
	ld xwa, (xsp)
	ld de, wa
	extz xde
	add xde, 0x20000
	ld xwa, 0xba000a
	ld xbc, 0x1e0008d
	jr MspBksl_EventDeliver

EsCmp_HandleEvent29:
	stb_d8 0x39b8, a
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
	ld xwa, 0xba000a
	ld xbc, 0x1e0008d
	jr MspBksl_EventDeliver

EsCmp_HandleEvent2A:
	stb_d8 0x39b8, a
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
	ld xwa, 0xba000a
	ld xbc, 0x1e0008d

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
	cpdi8 0x8d38, 181
	ret nz
	ld xwa, 0xb5001e
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ret

SoundCtrl_SendTempoScaled:
	cpdi8 0x8d38, 181
	ret nz
	calr SoundCtrl_CalcScaledTempo
	ld xwa, 0xb50002
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ret

SoundCtrl_CalcScaledTempo:
	ld xhl, 0x64
	ldw_d16 xbc, 0x34d4
	extz xbc
	ld xwa, xhl
	call Math_MultiplyAccumulate
	ld xwa, xhl
	ld xbc, 0xbe
	call Math_DivideU32
	cp xhl, 0x63
	jr ule, SoundCtrl_CalcTempo_Clamp
	ld xhl, 0x63

SoundCtrl_CalcTempo_Clamp:
	stb_d8 0x39ab, l
	ret

AccGuard_ProgramChangeCheck:
	; --- Multi-condition guard with conditional calls (85 bytes) ---
	ldb_d8	c, 0xc07e
	ldb_d8	a, 0xc07d
	cps	a, 5
	jr nz, AccGuard_CheckMode09
	cpdi8	0xc07f, 0
	jr z, AccGuard_CheckMode09
	cps	c, 2
	ret nz
	jr t, AccGuard_SendProgramChange
AccGuard_CheckMode09:
	cp a, 0x09
	ret nz
	cpdi8	0xc07f, 0
	ret z
	cp c, 0x40
	ret nz
	ldb_d8	a, 0x8d36
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
	cpdi8 0x8d38, 201
	ret nz
	ld xwa, 0xc90009
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ret

AccSeq_DeliverC9_000A:
	cpdi8 0x8d38, 201
	ret nz
	ld xwa, 0xc9000a
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call ApDeliveryEvent
	ret
__pad_F69D47:

MainMspRgpSetFunc:
	ldb_d8 a, 0x7f3d
	sll a, 4
	ldb w, 0x0
	extz xwa
	add xwa, 0x1e8a00
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
	cp xbc, 0x1e40015
	jr z, MspMenuTtl_Case1
	cp xbc, 0x1e40014
	jr z, MspMenuTtl_Init
	cp xbc, 0x1e40013
	jr z, MspRgpSet_HandleEvent13
	cp xbc, 0x1e40012
	jrl nz, AccBass_ReturnZero
	cpdi8 0x7f0b, 0
	jr nz, AccBass_ReturnZero
	ld xbc, xix
	ld a, (xix)
	cp a, 0xe
	jr nc, AccBass_ReturnZero
	inc 1, a
	ld (xbc), a
	ld xwa, 0xcc0003
	ld xbc, 0x1e0008d
	ld xde, xhl
	jr AccBass_EventDeliver

MspRgpSet_HandleEvent13:
	cpdi8 0x7f0b, 0
	jr nz, AccBass_ReturnZero
	ld xbc, xix
	ld a, (xix)
	cps a, 0
	jr z, AccBass_ReturnZero
	dec 1, a
	ld (xbc), a
	ld xwa, 0xcc0003
	ld xbc, 0x1e0008d
	ld xde, xhl
	jr AccBass_EventDeliver

; MspMenuTtlFunc init
MspMenuTtl_Init:
	cpdi8 0x7f0b, 0
	jr nz, AccBass_ReturnZero
	ld xbc, xwa
	ld a, (xwa)
	cps a, 5
	jr nc, AccBass_ReturnZero
	inc 1, a
	ld (xbc), a
	ld xwa, 0xcc0003
	ld xbc, 0x1e0008d
	jr AccBass_EventDeliver

; MspMenuTtlFunc case 1
MspMenuTtl_Case1:
	cpdi8 0x7f0b, 0
	jr nz, AccBass_ReturnZero
	ld xbc, xwa
	ld a, (xwa)
	cps a, 0
	jr z, AccBass_ReturnZero
	dec 1, a
	ld (xbc), a
	ld xwa, 0xcc0003
	ld xbc, 0x1e0008d

AccBass_EventDeliver:
	call ApDeliveryEvent

AccBass_ReturnZero:
	lds32 xhl, 0
	ret
; MspMenuTtlFunc case 2
MspMenuTtl_Case2:
MspMenuTtlFunc:
	cp xbc, 0x1c00013
	jr nz, MspNameTtl_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jr c, MspNameTtl_ReturnZero
	cp xde, 0x6
	jr ugt, MspNameTtl_ReturnZero
	add xde, xde
	add xde, NakaInst_MEMORY_A_0x26
	ld de, (xde)
	lda_24 xix, MspMenuTtl_Dispatch
	jp_ind 8, 0x07, 0xf0, 0xe8
; MspMenuTtlFunc title dispatch
MspMenuTtl_Dispatch:
	ld	xwa, 0x028800
	call	SndParam_LookupReadOnly
	cp	l, 13
	jr	c, 5
	cp	l, 16
	jr	ule, 4
	ldb	l, 0
	jr	3
	sub	l, 13
	stb_d8	0x7f3e, l
	ld	a, l
	sll	a, 4
	cps	l, 2
	jr	nc, 12
	ldb	w, 0
	extz	xwa
	add	xwa, 0x1e8a80
	jr	13
	sub	a, 32
	ldb	w, 0
	extz	xwa
	add	xwa, 0x1e8a40
	pushw	16
	push	xwa
	pushw	0
	pushw	0x34bc
	call	Strncpy
	lda	xsp, (xsp+10)
	stdi8	0x34cc, 0

MspNameTtl_ReturnZero:
	lds32 xhl, 0
	ret
; MspNameTtlFunc mode 1
MspNameTtl_Mode1:
MspNameTtlFunc:
	cp xbc, 0x1c00013
	jr nz, MspRecMode_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jr c, MspRecMode_ReturnZero
	cp xde, 0x6
	jr ugt, MspRecMode_ReturnZero
	add xde, xde
	add xde, NakaInst_MEMORY_A_0x34
	ld de, (xde)
	lda_24 xix, MspNameTtl_Dispatch
	jp_ind 8, 0x07, 0xf0, 0xe8
; MspNameTtlFunc title dispatch
MspNameTtl_Dispatch:
	cpdi8	0x8d37, 203
	jr	z, 20
	ldb_d8	c, 0x7f3e
	add	c, 13
	extz	bc
	ld	xwa, 0x028800
	lds	de, 0
	call	SoundParam_NotifyChange
	cpdi8	0x8d37, 204
	jr	z, 19
	ld	xwa, 0xcc0003
	ld	xbc, 0x01e0008e
	ld	xde, 0xffff0002
	call	ApDeliveryEvent

MspRecMode_ReturnZero:
	lds32 xhl, 0
	ret
; MspNameTtlFunc mode 2
MspNameTtl_Mode2:
MspRecModeFunc:
	cp xbc, 0x1c00013
	jr nz, MspNameTtl_Mode4
	cp xde, 0x1
	jr z, MspNameTtl_Mode3
	or xde, xde
	jr nz, MspNameTtl_Mode4

; MspNameTtlFunc mode 3
MspNameTtl_Mode3:
	stdi8 0x7f0b, 0

; MspNameTtlFunc mode 4
MspNameTtl_Mode4:
	lds32 xhl, 0
	ret
; MspNameTtlFunc mode 5
MspNameTtl_Mode5:
MspRecTtlFunc:
	cp xbc, 0x1e4001f
	jrl z, MspRecTtl_SubA
	cp xbc, 0x1c00013
	jrl nz, MspRecTtl_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, MspRecTtl_ReturnZero
	cp xde, 0x6
	jrl ugt, MspRecTtl_ReturnZero
	add xde, xde
	add xde, NakaInst_MEMORY_A_0x42
	ld de, (xde)
	lda_24 xix, MspRecTtl_Dispatch
	jp_ind 8, 0x07, 0xf0, 0xe8
; MspRecTtlFunc title dispatch
MspRecTtl_Dispatch:
	cpdi8	0x8d37, 201
	jr	z, 61
	ld	xwa, 0x028103
	lds	bc, 0
	lds	de, 3
	call	SoundParam_NotifyChange
	ld	xwa, 0x028800
	call	SndParam_LookupReadOnly
	cp	l, 13
	jr	z, 5
	cp	l, 14
	jr	nz, 29
	ldb_d8	a, 0x7f14
	sll	a, 4
	ldb	w, 0
	extz	xwa
	add	xwa, 0x1e8820
	ld	a, (xwa)
	and	a, 16
	srl	a, 4
	stb_d8	0x7f3f, a
	lds	wa, 0
	call	UI_PostDialEnable
	jr	71
	cpdi8	0x8d36, 201
	jr	z, 64
	cpdi8	0x7f0b, 0
	jr	z, 57
	stdi8	0x7f0b, 0
	jr	50

; MspRecTtlFunc sub-handler A
MspRecTtl_SubA:
	ld xwa, 0x28800
	call SndParam_LookupReadOnly
	cp l, 0xd
	jr z, MspRecTtl_SubA_CheckRange
	cp l, 0xe
	jr nz, MspRecTtl_ReturnZero

MspRecTtl_SubA_CheckRange:
	ldb_d8 a, 0x7f14
	sll a, 4
	ldb w, 0x0
	extz xwa
	add xwa, 0x1e8820
	ldb_d8 c, 0x7f3f
	and c, 0x1
	sll c, 4
	resm 4, (xwa)
	or (xwa), c

MspRecTtl_ReturnZero:
	lds32 xhl, 0
	ret

AccSeq_PostEvent9E_Enable:
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 1
	jp ApPostEvent

AccSeq_PostEvent9E_Disable:
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	jp ApPostEvent
AccSeq_DcModeDataBlock:
	.byte 0xc1
	push	xwa
	xor	(xiy+63), d
	ret	nz
	ld	xwa, 0xdc0005
	ld	xbc, 0x01c0000f
	lds32	xde, 0
	call	ApDeliveryEvent
	ret
; SndArgTtlFunc sub-handler A
SndArgTtl_SubA:
SndArgModeFunc:
	cp xbc, 0x1c00013
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
	cp xbc, 0x1c00013
	jr nz, SndArgTtl_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jr c, SndArgTtl_ReturnZero
	cp xde, 0x6
	jr ugt, SndArgTtl_ReturnZero
	add xde, xde
	add xde, NakaInst_MEMORY_A_0x50
	ld de, (xde)
	lda_24 xix, SndArgTtl_Dispatch
	jp_ind 8, 0x07, 0xf0, 0xe8
; SndArgTtlFunc title dispatch
SndArgTtl_Dispatch:
	cpdi8	0x8d37, 220
	jr	z, 19
	ld	xwa, 0xdc0005
	ld	xbc, 0x01e0008e
	ld	xde, 0xffff0002
	call	ApDeliveryEvent
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	AccStyle_InlinedBlock
	.ascii "^\\[Z"

SndArgTtl_ReturnZero:
	lds32 xhl, 0
	ret
__pad_F6A0BB:

SndArgNmGet:
	lda xsp, (xsp - 76)
	pushw_erp 0xfa
	ld (xsp + 70), xde
	ld (xsp + 74), xbc
	ld xiy, NakaInst_MEMORY_A_0x5E
	lda xix, (xsp + 66)
	ldiw
	ldiw
	ld xiy, NakaInst_DashDash_0x4
	lda xix, (xsp + 58)
	lds bc, 4
	ldirw
	ld xiy, NakaInst_OFF_Str_0x4
	lda xix, (xsp + 52)
	lds bc, 2
	ldirw
	ldi85
	ld xiy, NakaInst_OFF_Str_0xA
	lda xix, (xsp + 32)
	ldw bc, 0xa
	ldirw
	ld xiy, NakaInst_OFF_Str_0x1E
	lda xix, (xsp + 12)
	ldw bc, 0xa
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
	ldb_erp L, 0xfb
	inc1b_erp 0xfb
	stb_erp A, 0xfb
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
	mul wa, 0xa
	extz xwa
	add xwa, 0x1e7810
	ld xix, xwa
	lda xwa, (xsp + 52)
	ld (xsp + 2), xwa
	dec 4, xhl
	ld xwa, (xsp + 74)
	cp xwa, 0x1e40024
	jrl z, SndArgNm_HandleEvent24
	add xhl, xix
	cp xwa, 0x1e40021
	jrl z, SndArgNm_HandleEvent21
	cp xwa, 0x1e40020
	jrl nz, SndArgNm_ReturnZero
	ld xix, xhl
	ld a, (xhl)
	ldb_erp A, 0xfb
	ld xiy, xde
	or xde, xde
	jr nz, SndArgNm_ProcessEntry
	or_erpb 0xfb, 0xf0

SndArgNm_ProcessEntry:
	lda xde, (xbc + 3)
	stb_erp A, 0xfb
	ld (xde), a
	ld a, (xix + 1)
	res 7, a
	ldb_erp A, 0xfb
	lda xhl, (xbc + 4)
	stb_erp A, 0xfb
	ld (xhl), a
	ld xwa, (xsp + 2)
	add xwa, xiy
	ld a, (xwa)
	ldb_erp A, 0xfb
	ld (xbc + 2), a
	ld xwa, (xsp + 70)
	dec 2, a
	ldb_erp A, 0xfb
	ld a, (xde)
	extz wa
	ld c, (xhl)
	extz bc
	stb_erp E, 0xfb
	extz de
	sla de, 2
	lda xhl, (xsp + 32)
	ld_sril3 XDE, 0x07, 0xec, 0xe8
	call SndParam_ApplyProgramChangeAsync
	stb_erp A, 0xfb
	extz wa
	sla wa, 2
	lda xbc, (xsp + 32)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld (xwa + 16), 0x0
	ld xwa, (xsp + 70)
	ld de, wa
	extz xde
	add xde, 0x10000
	ld xwa, 0xdc0005
	ld xbc, 0x1e40022
	jrl SndArgNm_DeliverAndReturn

SndArgNm_HandleEvent21:
	or xde, xde
	jr nz, SndArgNm_HandleEvent21_Copy
	pushw 0x3
	ld xwa, (xsp + 68)
	push xwa
	pushw 0x0
	pushw 0x39e4
	call Mem_Copy
	lda xsp, (xsp + 10)
	stdi8 0x39e7, 0
	jr SndArgNm_DeliverEvent

SndArgNm_HandleEvent21_Copy:
	ld a, (xhl + 1)
	and a, 0x80
	srl a, 7
	ldb_erp A, 0xfb
	ld xwa, (xsp + 70)
	ld e, a
	dec 2, e
	pushw 0x3
	stb_erp A, 0xfb
	extz wa
	sla wa, 2
	lda xbc, (xsp + 60)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	extz de
	sla de, 2
	lda xbc, (xsp + 18)
	ld_sril3 XWA, 0x07, 0xe4, 0xe8
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	stb_erp A, 0xfb
	extz wa
	sla wa, 2
	lda xbc, (xsp + 12)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld (xwa + 3), 0x0

SndArgNm_DeliverEvent:
	ld xwa, (xsp + 70)
	ld de, wa
	extz xde
	add xde, 0x20000
	ld xwa, 0xdc0005
	ld xbc, 0x1e40023

SndArgNm_DeliverAndReturn:
	call ApDeliveryEvent
	jr SndArgNm_ReturnZero

SndArgNm_HandleEvent24:
	ld xwa, (xsp + 2)
	add xwa, xde
	mrib4 0x80, 0x19, 0x3a, 0x8d
	ldb_d8 e, 0x8d3a
	extz de
	pushw 0xff
	ldw wa, 0x90
	ldw bc, 0x10
	call AddswbWr
	ldmm8 0x338f, 0x338e

SndArgNm_ReturnZero:
	lds32 xhl, 0
	popw_erp 0xfa
	lda xsp, (xsp + 76)
	ret
__pad_F6A2E2:

CmpStepTitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, NakaInst_OFF_Str_0x32
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

CmpStep_DataBlock:
	.byte 0xc1, 0x37, 0x8d
	push	xsp
	ld	(xiz), xiz
	pop_f
	ldw	wa, 255
	call	GraphicsRender_ByteData
	ldw	wa, 245
	call	TextRender_PopAndReturn_0x9
	call	GraphicsRender_ByteData_0x67
	ldw	wa, 255
	call	GraphicsRender_ByteData_0x6
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	AccScreen_DataBlock_0x17
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	AccScreen_DataBlock_0xE9
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
	call	GraphicsRender_ProcessEntries
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
	call	ColorBlit_WithPaletteSave
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
	call	DrawFunc_Init_Variant1_0x108
	pop	xwa
	ret
	push	xwa
	ld	xwa, xiy
	call	ColorBlit_Variant_ByteData
	pop	xwa
	ret
	push	xiz
	calr	2
	pop	xiz
	ret
	.byte 0xc1, 0x37, 0x8d
	push	xsp
	ld	(xiz), xiz
	zcf
	call	AccPlayback_InitOrUpdate
	stdi8	0x3525, 182
	.byte 0xc1, 0xe0, 0xe3
	push	xix
	and	xbc, xsp
	or	hl, iz
	push	xix
	.byte 0xef
	call	RhythmVariation_InlineCode_0x4
	.byte 0xf1, 0xe0, 0xe3
	dec	6, d
	incf
	ld	xwa, AccScreen_DataBlock_0x5A
	push	xwa
	call	DrawFunc_StackEntry
	inc	4, xsp
	ld	xwa, AccScreen_DataBlock_0x7A
	push	xwa
	call	DrawFunc_StackEntry
	inc	4, xsp
	ret
	calr	1530
	stib_da	0x03efa8, 2
	ld	xiy, AccScreen_UIDataBlock_0x33
	ld	xix, AccScreen_UIDataBlock_0x15A
	calr	65375
	calr	773
	calr	795
	calr	1176
	ret
	calr	726
	stib_da	0x03efa8, 1
	ld	xiy, AccScreen_UIDataBlock_0x291
	calr	65411
	calr	1155
	stib_da	0x03efa8, 0
	calr	1492
	.byte 0xc1, 0xd6
	ldw	ix, 0xbb19
	push	xbc
	.byte 0xc1
	ld	xde, 0x39bc1937
	.byte 0xc1
	ld	xhl, 0x39bd1937
	.byte 0xc1
	ld	xix, 0x39be1937
	.byte 0xc1
	ld	xiy, 0x39bf1937
	.byte 0xc1, 0x1a, 0x37
	pop_f
	.byte 0xc0
	push	xbc
	ld	xiy, AccScreen_UIDataBlock_0x1E7
	ld	xix, AccScreen_UIDataBlock_0x256
	calr	65296
	stib_da	0x03efa8, 0
	.byte 0xc1
	ccf
	.byte 0x37
	pop_f
	ld	(xhl+57), e
	push	xiz
	.byte 0xac, 0xf6
	nop
	calr	65307
	calr	765
	calr	1095
	calr	978
	calr	1402
	ret
	push	xiz
	calr	2
	pop	xiz
	ret
	call	RhythmVariation_InlineCode_0x26
	ret
	push	xiz
	calr	2
	pop	xiz
	ret
	ld	xix, AccScreen_DataBlock_0x103
	calr	81
	ret
	.byte 0x96, 0xa5, 0xf6
	nop
	.byte 0xa8, 0xa5, 0xf6
	nop
	.byte 0xc6, 0xa5, 0xf6
	nop
	.byte 0xe4, 0xa5, 0xf6
	nop
	.byte 0x04, 0xa6, 0xf6
	nop
	ldb	d, 166
	.byte 0xf6
	nop
	.byte 0x56, 0xa6, 0xf6
	nop
	jr	z, -90
	.byte 0xf6
	nop
	jrl	z, -2394
	nop
	.byte 0x90, 0xa6, 0xf6
	nop
	.byte 0xaa, 0xa6, 0xf6
	nop
	.byte 0xb5, 0xa6, 0xf6
	nop
	.byte 0xc0, 0xa6, 0xf6
	nop
	.byte 0xc1, 0xa6, 0xf6
	nop
	andda8_24	c, 0xf6a6
	.byte 0xa6, 0xf6
	nop
	.byte 0xd5, 0xa6, 0xf6
	nop
	.byte 0xd6, 0xa6, 0xf6
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
	.byte 0xc1, 0xe2, 0xe3
	push	xix
	swi	6
	ld	xbc, xhl
	and	l, 31
	sla	l, 2
	.byte 0xe3
	pop	sr
	.byte 0xf0, 0xec
	ldb	d, 180
	.byte 0xe8
	ret
	push	xix
	cp	e, 32
	jr	ule, 2
	xor	e, e
	sla	e, 2
	ld	xix, AccScreen_DataBlock_0x18C
	.byte 0xe3
	pop	sr
	.byte 0xf0, 0xe8
	ldb	b, 92
	ret
	nop
	nop
	nop
	nop
	.byte 0x01
	nop
	nop
	nop
	push	sr
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
	ld	xwa, 0x80000000
	nop
	nop
	nop
	nop
	.byte 0x01
	nop
	nop
	nop
	push	sr
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
	ld	xwa, 0x80000000
	nop
	nop
	nop
	nop
	.byte 0x01
	nop
	nop
	nop
	push	sr
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
	ld	xwa, 0x80000000
	nop
	nop
	nop
	nop
	.byte 0x01
	nop
	nop
	nop
	push	sr
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
	ld	xwa, 0x80000000
	bit	7, w
	jr	nz, 7
	.byte 0xc1
	zcf
	.byte 0x37
	push	xiz
	ld	xwa, 0x13c10568
	.byte 0x37
	push	xiz
	.byte 0x80
	ret
	.byte 0xc1
	ccf
	.byte 0x37
	push	xsp
	.byte 0x04
	jr	nz, 22
	.byte 0xc1, 0xe2, 0xe3
	push	xiz
	ldio	200, 51
	reti
	jr	nz, 7
	.byte 0xc1
	pushw	iy
	.byte 0x37
	push	xiz
	.byte 0x04
	jr	5
	.byte 0xc1
	pushw	iy
	.byte 0x37
	push	xiz
	ldio	14, 193
	ccf
	.byte 0x37
	push	xsp
	.byte 0x04
	jr	nz, 22
	.byte 0xc1, 0xe2, 0xe3
	push	xiz
	ldio	200, 51
	reti
	jr	nz, 7
	.byte 0xc1
	pushw	iy
	.byte 0x37
	push	xiz
	.byte 0x01
	jr	5
	.byte 0xc1
	pushw	iy
	.byte 0x37
	push	xiz
	push	sr
	ret
	.byte 0xc1, 0xe2, 0xe3
	push	xiz
	ldio	29, 82
	.byte 0x51, 0xf6
	ld	xwa, AccScreen_DataBlock_0x274
	push	xwa
	call	DrawFunc_StackEntry
	inc	4, xsp
	ret
	stib_da	0x03efa8, 0
	calr	813
	ret
	.byte 0xc1, 0xe2, 0xe3
	push	xiz
	ldio	29, 139
	.byte 0x51, 0xf6
	ld	xwa, AccScreen_DataBlock_0x294
	push	xwa
	call	DrawFunc_StackEntry
	inc	4, xsp
	ret
	stib_da	0x03efa8, 0
	calr	781
	ret
	.byte 0xc1, 0xe2, 0xe3
	push	xiz
	ldio	29, 194
	.byte 0x51, 0xf6, 0xc1
	ccf
	.byte 0x37
	push	xsp
	.byte 0x04
	jr	nz, 12
	ld	xwa, AccScreen_DataBlock_0x2BB
	push	xwa
	call	DrawFunc_StackEntry
	inc	4, xsp
	ret
	stib_da	0x03efa8, 0
	.byte 0xc1
	ex_ff
	.byte 0x37
	pop_f
	ld	(xhl+57), e
	.byte 0x8f, 0xad, 0xf6
	nop
	calr	64808
	ret
	.byte 0xc1, 0xe2, 0xe3
	push	xiz
	ldio	193, 19
	.byte 0x37
	push	xiz
	push	sr
	.byte 0xc1
	zcf
	.byte 0x37
	push	xix
	swi	6
	ret
	.byte 0xc1, 0xe2, 0xe3
	push	xiz
	ldio	193, 19
	.byte 0x37
	push	xiz
	.byte 0x01, 0xc1
	zcf
	.byte 0x37
	push	xix
	swi	5
	ret
	.byte 0xc1, 0xe2, 0xe3
	push	xiz
	ldio	200, 51
	reti
	jr	nz, 15
	.byte 0xf1
	and	(xhl+55), hl
	jr	nz, 9
	call	RhythmVariation_InlineCode_0x32
	.byte 0xc1, 0xe0, 0xe3
	push	xiz
	rcf
	ret
	.byte 0xc1, 0xe2, 0xe3
	push	xiz
	ldio	200, 51
	reti
	jr	nz, 15
	.byte 0xf1
	and	(xhl+55), ix
	jr	nz, 9
	call	RhythmVariation_InlineCode_0x79
	.byte 0xc1, 0xe0, 0xe3
	push	xiz
	rcf
	ret
	bit	7, w
	jr	nz, 5
	.byte 0xc1
	zcf
	.byte 0x37
	push	xiz
	ldb	w, 14
	bit	7, w
	jr	nz, 5
	.byte 0xc1
	zcf
	.byte 0x37
	push	xiz
	.byte 0x04
	ret
	ret
	ret
	ret
	bit	7, w
	jr	nz, 12
	stdi8	0xe3dc, 181
	stdi8	0xe3de, 128
	jr	0
	ret
	ret
	ret
	ret
	ret
	stib_da	0x03efa8, 2
	.byte 0xc1
	ccf
	.byte 0x37
	push	xsp
	.byte 0x04
	jr	nz, 15
	ld	xiy, AccScreen_UIDataBlock_0x15A
	ld	xix, AccScreen_UIDataBlock_0x1E7
	calr	64610
	jr	8
	ld	xiy, AccScreen_UIDataBlock_0x256
	calr	64663
	ret
	xor	wa, wa
	ld	xiy, AccScreen_UIDataBlock_0x4F6
	ld	xix, xiy
	ldb	a, 35
	ldb_d8	c, 0x373e
	mul8rr	a, c
	extz	xwa
	add	xix, xwa
	calr	64575
	ret
	ld	xiy, AccScreen_UIDataBlock_0x582
	ldb_d8	c, 0x373e
	calr	37
	ld	xiy, AccScreen_UIDataBlock_0x5DC
	ldb_d8	c, 0x373f
	calr	25
	ld	xiy, AccScreen_UIDataBlock_0x636
	ldb_d8	c, 0x3740
	calr	13
	ld	xiy, AccScreen_UIDataBlock_0x690
	ldb_d8	c, 0x3741
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
	calr	64500
	ret
	ld	xiy, 0x372e
	ld	xix, 2601
	xor	de, de
	xor	bc, bc
	ld	xiz, 0x373e
	xor	wa, wa
	ld	a, e
	extz	xwa
	add	xiz, xwa
	ld	d, (xiz)
	cps	d, 0
	.ascii "fW8;9:<=>"
	call	AccAudio_LockAcquire
	.ascii "^]\\ZY[XÛ"
	.byte 0xd3
	ld	l, c
	.byte 0xc3
	reti
	.byte 0xf4, 0xec
	ldb	l, 207
	.byte 0xcc
	retd	0x541e
	nop
	add	xix, 4
	xor	hl, hl
	ld	l, c
	.byte 0xc3
	reti
	.byte 0xf4, 0xec
	ldb	l, 207
	cp	w, d
	srl	l, 4
	calr	60
	add	xix, 4
	inc	1, c
	cp	c, d
	jr	c, 0xcd
	.ascii "8;9:<=>"
	call	AccAudio_LockRelease
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	inc	1, e
	cps	e, 4
	jr	ge, 23
	add	xiy, 4
	ldb	a, 8
	mul8rr	a, c
	extz	xwa
	sub	xix, xwa
	add	xix, 1200
	jrl	-137
	ret
	push	xiy
	push	xix
	pushw	de
	pushw	bc
	ld	xiy, AccScreen_UIDataBlock_0x4B6
	lds	bc, 4
	ldb	a, 6
	ld	xwa, 0x39cc
	ld	(xwa), 6
	ld	(xwa+1), 8
	ld	(xwa+2), ix
	extz	hl
	extz	xhl
	sll	xhl, 2
	add	xiy, xhl
	.byte 0xc5, 0xf4
	ldb	l, 184
	.byte 0x04
	ld	xsp, 0xb827f4c5
	halt
	ld	xsp, 0xb827f4c5
	.byte 0x06
	ld	xsp, 0x07b82785
	ld	xsp, 0xfb164e1d
	popw	bc
	popw	de
	pop	xix
	pop	xiy
	ret
	xor	wa, wa
	ldb_d8	a, 0x370f
	cps	a, 0
	jr	z, 2
	dec	1, a
	and	a, 127
	ldb	c, 32
	div8rr	a, c
	stb_d8	0x39b9, a
	sla	wa, 1
	xor	xhl, xhl
	ld	l, w
	ld	xiy, AccScreen_UIDataBlock_0x6EA
	add	xiy, xhl
	ld	bc, (xiy)
	stda16	0x39c4, bc
	add	bc, 6
	stda16	0x39c8, bc
	xor	xhl, xhl
	ld	l, a
	ld	xiy, AccScreen_UIDataBlock_0x72A
	add	xiy, xhl
	ld	bc, (xiy)
	stda16	0x39c6, bc
	add	bc, 8
	stda16	0x39ca, bc
	ldb	a, 5
	push	xwa
	ld	xwa, 0x39c2
	call	DrawText_LayoutAndRender_Variant1_0x6CA
	pop	xwa
	ret
	xor	wa, wa
	ldb_d8	a, 0x370f
	cps	a, 0
	jr	z, 2
	dec	1, a
	and	a, 127
	ldb	c, 32
	div8rr	a, c
	stb_d8	0x39b9, a
	ret
	stib_da	0x03efa8, 0
	.byte 0xc1
	ccf
	.byte 0x37
	push	xsp
	.byte 0x04
	jr	z, 5
	calr	215
	jr	32
	ldb_d8	a, 0x3717
	cp	a, 255
	jr	z, 6
	calr	21
	calr	54
	calr	93
	.byte 0xc1
	ex_ff
	.byte 0x37
	pop_f
	ld	(xhl+57), e
	.byte 0x8f, 0xad, 0xf6
	nop
	calr	64156
	ret

AccScreen_DrawTempoDisplay:
	calr AccScreen_CalcTempoParams
	ld xiy, AccScreen_UIDataBlock_0x360
	ld xix, AccScreen_UIDataBlock_0x37E
	calr AccGraphics_RenderStart
	ret

AccScreen_CalcTempoParams:
	xor wa, wa
	ldb_d8 a, 0x3718
	ldb l, 0xc
	divs8rr a, l
	stb_d8 0x39b8, w
	stb_d8 0x39ba, a
	ret

AccScreen_UpdateBeatDisplay:
	ldmm8 0x39bb, 0x3717
	ld xiy, AccScreen_UIDataBlock_0x37E
	push xwa
	ld xwa, xiy
	call DrawText_LayoutAndRender
	pop xwa
	cpdi8 0x3717, 99
	jr ugt, AccScreen_BeatDisplay_Large
	ld xiy, AccScreen_UIDataBlock_0x386
	jr AccScreen_BeatDisplay_Draw

AccScreen_BeatDisplay_Large:
	ld xiy, AccScreen_UIDataBlock_0x390

AccScreen_BeatDisplay_Draw:
	calr AccDraw_Init
	ret

AccScreen_BeatDataBlock:
	.byte 0xc1
	ccf
	.byte 0x37
	push	xsp
	.byte 0x04
	jr	nz, 25
	.byte 0xc1
	push_a
	.byte 0x37
	pop_f
	.byte 0xbb
	push	xbc
	.byte 0xc1
	pop_a
	.byte 0x37
	pop_f
	ld	(xix+57), e
	jrl	lt, -2387
	nop
	ld	xix, AccScreen_UIDataBlock_0x3B8
	calr	64014
	ret

AccScreen_DrawInit_StackWrap:
	ld xwa, AccScreen_DrawInit_Body
	push xwa
	call DrawFunc_StackEntry
	inc 4, xsp
	ret

AccScreen_DrawInit_Body:
	stib_da 0x03efa8, 0x00
	calr AccScreen_DrawTempoDisplay
	ret

AccScreen_UpdateBeat_StackWrap:
	ld xwa, AccScreen_UpdateBeat_Body
	push xwa
	call DrawFunc_StackEntry
	inc 4, xsp
	ret

AccScreen_UpdateBeat_Body:
	stib_da 0x03efa8, 0x00
	calr AccScreen_UpdateBeatDisplay
	ret

AccScreen_DrawMeasure_StackWrap:
	ld xwa, AccScreen_DrawMeasure_Body
	push xwa
	call DrawFunc_StackEntry
	inc 4, xsp
	ret

AccScreen_DrawMeasure_Body:
	stib_da 0x03efa8, 0x00
	calr AccScreen_DrawMeasureDetail
	ret

AccScreen_DrawMeasureDetail:
	ldb_d8 a, 0x3720
	dec 1, a
	stb_d8 0x39ba, a
	ld xiy, AccScreen_UIDataBlock_0x2BA
	calr AccDraw_Secondary
	ldb_d8 a, 0x3721
	stb_d8 0x39ba, a
	cpdi8 0x3720, 3
	jr nz, AccScreen_DrawMeas_Other
	ldb_d8 a, 0x3721
	cps a, 0
	jr z, AccScreen_DrawMeas_Variant3
	stdi8 0x39ba, 1

AccScreen_DrawMeas_Variant3:
	ld xiy, AccScreen_UIDataBlock_0x341
	calr AccDraw_Secondary
	jr AccScreen_DrawMeas_Return

AccScreen_DrawMeas_Other:
	ld xiy, AccScreen_UIDataBlock_0x356
	calr AccDraw_Init

AccScreen_DrawMeas_Return:
	ret

AccScreen_UIDataBlock:
; Accompaniment engine screen data block
; Total: 2096 bytes (698 + 15 + 120 + 15 + 6 + 287 + 955)
; Screen data blocks compiled from C source, included as .incbin

; Accompaniment step recording UI data: 698 bytes
	stib_da	0x03efa8, 0
	ldb	c, 0
	ldb	a, 12
	ldb	a, 16
	call	Display_DeferOrDrawWall
	ret
	ldb	c, 7
	ldb	a, 12
	call	Display_DeferOrUpdateScreen
	ret
	xor	wa, wa
	ldb_d8	a, 0x379b
	and	a, 31
	jr	z, 9
	srl	a, 1
	jr	c, 4
	inc	1, w
	jr	-9
	stb_d8	0x39b8, w
	ret
	ldb	c, 5
	ldw	ix, 45
	reti
	ccf
	.byte 0x84
	nop
	.byte 0x53, 0x54
	ld	xiy, 0x45522050
	ld	xhl, 0x4944524f
	popw	iz
	ld	xsp, 0x043a0c20
	.byte 0x50
	ld	xbc, 0x52455454
	popw	iz
	push	xde
	ldb	w, 9
	ldb	c, 4
	.byte 0x50
	ld	xbc, 0x063a5452
	halt
	.byte 0xc4
	halt
	.byte 0x8d, 0x06
	ldio	227, 8
	.byte 0x50
	ld	xbc, 0x05065452
	add	(xix+11), h
	ei	7
	.byte 0xcb
	scf
	ld	xiy, 0x08065352
	ldwio	24, 0x4552
	.byte 0x53, 0x54
	reti
	halt
	.byte 0xef
	halt
	scf
	reti
	halt
	.byte 0x8f
	pushw	1809
	halt
	.byte 0xa7
	scf
	scf
	reti
	halt
	.byte 0xe7, 0x17
	scf
	.byte 0x06
	ldio	25, 31
	popw	iy
	ld	xiy, 0x0a065341
	push	xwa
	.byte 0x1f
	ld	xhl, 0x4f535255
	.byte 0x52
	ei	5
	ldb	b, 33
	.byte 0x8d
	ei	5
	pushw	de
	ldb	c, 142
	ei	5
	push	xhl
	ldb	a, 141
	ei	5
	ld	xhl, 0x05068e23
	ldw	wa, 0x3c22
	ei	5
	ldw	iy, 0x3e22
	push	10
	pop_a
	.byte 0x01
	ldb	c, 0
	ldw	hl, 0x3201
	nop
	push	10
	zcf
	.byte 0x01
	ldb	a, 0
	ldw	iy, 0x3401
	nop
	push	10
	pop_a
	.byte 0x01
	ld	xsp, 0x56013300
	nop
	push	10
	zcf
	.byte 0x01
	ld	xiy, 0x58013500
	nop
	push	10
	pop_a
	.byte 0x01
	jr	nz, 0
	ldw	hl, 0x7d01
	nop
	push	10
	zcf
	.byte 0x01
	jr	nov, 0
	ldw	iy, 0x7f01
	nop
	push	10
	decf
	.byte 0x01, 0x96
	nop
	ldw	hl, 0xa501
	nop
	push	10
	pushw	0x9401
	nop
	ldw	iy, 0xa701
	nop
	ldwio	10, 12
	.byte 0xaa
	nop
	swi	2
	nop
	.byte 0xc0
	nop
	ldwio	10, 5
	ordm16_24	8960, ix
	nop
	ldwio	10, 205
	ordm16_24	0xeb00, ix
	nop
	ldwio	10, 245
	ordm16_24	0x011300, ix
	nop
	ldwio	10, 285
	ordm16_24	0x013b00, ix
	nop
	.byte 0x01
	ldwio	5, 0xdf00
	nop
	ldb	c, 0
	.byte 0xdf
	nop
	.byte 0x01
	ldwio	205, 0xdf00
	nop
	.byte 0xeb
	nop
	.byte 0xdf
	nop
	.byte 0x06
	pop_a
	calr	19999
	popw	sp
	.byte 0x54
	ld	xiy, 0x4c455620
	ldb	w, 32
	ldb	w, 76
	ld	xiy, 0x4854474e
	.byte 0x06
	push_a
	ldb	l, 33
	ld	w, (xiy+32)
	ldb	w, 32
	ld	w, (xiy+32)
	ldb	w, 32
	ld	w, (xiy+32)
	ldb	w, 32
	.byte 0x8d, 0x06
	push_a
	pushw	sp
	ldb	c, 142
	ldb	w, 32
	ldb	w, 32
	ld	w, (xiz+32)
	ldb	w, 32
	ld	w, (xiz+32)
	ldb	w, 32
	.byte 0x8e
	ldwio	10, 45
	ordm16_24	0x4b00, ix
	nop
	ldwio	10, 85
	ordm16_24	0x7300, ix
	nop
	ldwio	10, 125
	ordm16_24	0x9b00, ix
	nop
	ldwio	10, 165
	ordm16_24	0xc300, ix
	nop
	.byte 0x01
	ldwio	45, 0xdf00
	nop
	popw	hl
	nop
	.byte 0xdf
	nop
	.byte 0x01
	ldwio	85, 0xdf00
	nop
	jrl	ule, -8448
	nop
	.byte 0x01
	ldwio	125, 0xdf00
	nop
	.byte 0x9b
	nop
	.byte 0xdf
	nop
	.byte 0x01
	ldwio	165, 0xdf00
	nop
	.byte 0xc3
	nop
	.byte 0xdf
	nop
	push	sr
	retd	0x39bb
	swi	7
	nop
	ldb	w, 9
	.byte 0xb1, 0xf6
	nop
	reti
	nop
	.byte 0x1a, 0x04
	push	sr
	retd	0x39b8
	reti
	nop
	ldb	w, 92
	.byte 0xae, 0xf6
	nop
	ldio	0, 40
	.byte 0x04
	push	sr
	retd	0x39bc
	retd	1536
	sub	(xix), h
	.byte 0xf6
	nop
	.byte 0x01
	nop
	ldb	a, 8
	push	sr
	retd	0x39bd
	retd	1536
	sub	(xix), h
	.byte 0xf6
	nop
	.byte 0x01
	nop
	.byte 0xd1
	incf
	push	sr
	retd	0x39be
	retd	1536
	sub	(xix), h
	.byte 0xf6
	nop
	.byte 0x01
	nop
	.byte 0x81
	scf
	push	sr
	retd	0x39bf
	retd	1536
	sub	(xix), h
	.byte 0xf6
	nop
	.byte 0x01
	nop
	ldw	bc, 1046
	pushw	0
	nop
	nop
	ret
	.byte 0x8b, 0xac, 0xf6
	nop
	nop
	ldwio	192, 3897
	nop
	.byte 0x06, 0x83
	jp	0x0b0401
	nop
	nop
	nop
	nop
	ret
	push	xwa
	.byte 0xac, 0xf6
	nop
	call	5151
	pushw	wa
	nop
	push	sr
	retd	0x39bb
	.byte 0x01
	nop
	.byte 0x06
	popw	iy
	.byte 0xac, 0xf6
	nop
	halt
	nop
	ldw	bc, 8223
	.byte 0x50
	popw	wa
	.byte 0x52, 0x53, 0x56
	ld	xbc, 0x0445554c
	pushw	0
	nop
	nop
	ret
	jr	le, -84
	.byte 0xf6
	nop
	.byte 0xf0
	halt
	ldb	b, 0
	.byte 0x88
	nop
	.byte 0x04
	pushw	0x39b9
	pop	sr
	nop
	ret
	jrl	ule, -2388
	nop
	.byte 0x51
	ldwio	33, 2304
	nop
	.byte 0x01
	retd	33
	push	0
	.byte 0xb1
	zcf
	ldb	a, 0
	push	0
	jr	lt, 24
	ldb	a, 0
	push	0
	.byte 0xb9, 0x1a, 0x1f
	nop
	ex_ff
	nop

; accomp_section_widget: 15 bytes (compiled from C)
	.incbin "includes/generated/accomp_section_widget.bin"

; Accompaniment variation/section data: 120 bytes
	ld	xhl, 0x52544e4f
	popw	sp
	popw	ix
	ldb	w, 80
	popw	bc
	.byte 0x54
	ld	xhl, 0x45422048
	popw	iz
	ld	xix, 0x4f433d20
	popw	iz
	.byte 0x54, 0x52
	popw	sp
	popw	ix
	ldb	w, 77
	popw	sp
	ld	xix, 0x54414c55
	popw	bc
	popw	sp
	popw	iz
	ldb	w, 61
	ld	xhl, 0x52544e4f
	popw	sp
	popw	ix
	ldb	w, 83
	.byte 0x55, 0x53, 0x54
	ld	xbc, 0x20204e49
	ldb	w, 32
	push	xiy
	ld	xhl, 0x52544e4f
	popw	sp
	popw	ix
	ldb	w, 80
	ld	xbc, 0x544f504e
	ldb	w, 32
	ldb	w, 32
	ldb	w, 61
	ld	xhl, 0x52544e4f
	popw	sp
	popw	ix
	ldb	w, 69
	pop	xwa
	.byte 0x50, 0x52
	ld	xiy, 0x4f495353
	popw	iz
	ldb	w, 61
	ld	xhl, 0x52544e4f
	popw	sp
	popw	ix
	ldb	w, 65
	ld	xiz, 0x20524554
	.byte 0x54
	popw	sp
	.byte 0x55, 0x43
	popw	wa
	push	xiy

; accomp_part_widget: 15 bytes (compiled from C)
	.incbin "includes/generated/accomp_part_widget.bin"

; Gap: 6 bytes
	popw	sp
	ld	xiz, 0x4e4f2046

; accomp_display_full: 287 bytes (compiled from C)
	.incbin "includes/generated/accomp_display_full.bin"

; Accompaniment part names and ordering: 955 bytes
	.byte 0x54
	ld	xiy, 0x4f4e554e
	.byte 0x52
	popw	iy
	.byte 0x53, 0x54
	ld	xbc, 0x54554343
	.byte 0x54
	ld	xbc, 0x4d4f4343
	.byte 0x50
	ldb	w, 49
	ld	xbc, 0x4d4f4343
	.byte 0x50
	ldb	w, 50
	ld	xbc, 0x4d4f4343
	.byte 0x50
	ldb	w, 51
	ld	xde, 0x20535341
	ldb	w, 32
	ldb	w, 68
	.byte 0x52, 0x55
	popw	iy
	ldb	w, 32
	ldb	w, 32
	ldb	w, 49
	ldw	de, 0x3433
	ldw	iy, 0x3736
	push	xwa
	.byte 0x91, 0x91, 0x91, 0x91
	pushw	de
	.byte 0x91, 0x91, 0x91, 0x91
	pushw	de
	.byte 0x91, 0x91
	pushw	de
	pushw	de
	.byte 0x91, 0x91, 0x91, 0x91
	pushw	de
	.byte 0x91
	pushw	de
	.byte 0x91
	pushw	de
	.byte 0x91, 0x91
	pushw	de
	pushw	de
	.byte 0x91
	pushw	de
	pushw	de
	pushw	de
	.byte 0x91, 0x91, 0x91, 0x91
	pushw	de
	pushw	de
	.byte 0x91, 0x91
	pushw	de
	.byte 0x91
	pushw	de
	.byte 0x91
	pushw	de
	pushw	de
	pushw	de
	.byte 0x91
	pushw	de
	.byte 0x91, 0x91
	pushw	de
	pushw	de
	pushw	de
	.byte 0x91
	pushw	de
	pushw	de
	.byte 0x91
	pushw	de
	pushw	de
	pushw	de
	pushw	de
	pushw	de
	pushw	de
	pushw	de
	.byte 0x01
	ldwio	7, 0x3000
	nop
	ld	xiz, 0x02003000
	ldwio	7, 0x3000
	nop
	reti
	nop
	ldw	iy, 512
	ldwio	70, 0x3000
	nop
	ld	xiz, 0x06003500
	halt
	.byte 0xbd, 0x06
	pop_a
	.byte 0x01
	ldwio	74, 0x3000
	nop
	.byte 0x86
	nop
	ldw	wa, 512
	ldwio	74, 0x3000
	nop
	popw	de
	nop
	ldw	iy, 512
	ldwio	134, 0x3000
	nop
	.byte 0x86
	nop
	ldw	iy, 1536
	halt
	.byte 0xc5, 0x06
	pop_a
	.byte 0x01
	ldwio	138, 0x3000
	nop
	.byte 0xc6
	nop
	ldw	wa, 512
	ldwio	138, 0x3000
	nop
	.byte 0x8a
	nop
	ldw	iy, 512
	ldwio	198, 0x3000
	nop
	.byte 0xc6
	nop
	ldw	iy, 1536
	halt
	cpl	e
	pop_a
	.byte 0x01
	ldwio	202, 0x3000
	nop
	push	1
	ldw	wa, 512
	ldwio	202, 0x3000
	nop
	.byte 0xca
	nop
	ldw	iy, 512
	ldwio	9, 0x3001
	nop
	push	1
	ldw	iy, 1536
	halt
	.byte 0xd5, 0x06
	pop_a
	push	sr
	ldwio	7, 0x4500
	nop
	reti
	nop
	popw	ix
	nop
	.byte 0x01
	ldwio	7, 0x4c00
	nop
	popw	wa
	nop
	popw	ix
	nop
	push	sr
	ldwio	72, 0x4500
	nop
	popw	wa
	nop
	popw	ix
	nop
	.byte 0x01
	ldwio	73, 0x4c00
	nop
	.byte 0x88
	nop
	popw	ix
	nop
	push	sr
	ldwio	136, 0x4500
	nop
	.byte 0x88
	nop
	popw	ix
	nop
	.byte 0x01
	ldwio	137, 0x4c00
	nop
	.byte 0xc8
	nop
	popw	ix
	nop
	push	sr
	ldwio	200, 0x4500
	nop
	.byte 0xc8
	nop
	popw	ix
	nop
	.byte 0x01
	ldwio	201, 0x4c00
	nop
	push	1
	popw	ix
	nop
	push	sr
	ldwio	9, 0x4501
	nop
	push	1
	popw	ix
	nop
	push	sr
	ldwio	7, 0x6300
	nop
	reti
	nop
	jr	gt, 0
	.byte 0x01
	ldwio	7, 0x6a00
	nop
	popw	wa
	nop
	jr	gt, 0
	push	sr
	ldwio	72, 0x6300
	nop
	popw	wa
	nop
	jr	gt, 0
	.byte 0x01
	ldwio	73, 0x6a00
	nop
	.byte 0x88
	nop
	jr	gt, 0
	push	sr
	ldwio	136, 0x6300
	nop
	.byte 0x88
	nop
	jr	gt, 0
	.byte 0x01
	ldwio	137, 0x6a00
	nop
	.byte 0xc8
	nop
	jr	gt, 0
	push	sr
	ldwio	200, 0x6300
	nop
	.byte 0xc8
	nop
	jr	gt, 0
	.byte 0x01
	ldwio	201, 0x6a00
	nop
	push	1
	jr	gt, 0
	push	sr
	ldwio	9, 0x6301
	nop
	push	1
	jr	gt, 0
	push	sr
	ldwio	7, 0x8100
	nop
	reti
	nop
	.byte 0x88
	nop
	.byte 0x01
	ldwio	7, 0x8800
	nop
	popw	wa
	nop
	.byte 0x88
	nop
	push	sr
	ldwio	72, 0x8100
	nop
	popw	wa
	nop
	.byte 0x88
	nop
	.byte 0x01
	ldwio	73, 0x8800
	nop
	.byte 0x88
	nop
	.byte 0x88
	nop
	push	sr
	ldwio	136, 0x8100
	nop
	.byte 0x88
	nop
	.byte 0x88
	nop
	.byte 0x01
	ldwio	137, 0x8800
	nop
	.byte 0xc8
	nop
	.byte 0x88
	nop
	push	sr
	ldwio	200, 0x8100
	nop
	.byte 0xc8
	nop
	.byte 0x88
	nop
	.byte 0x01
	ldwio	201, 0x8800
	nop
	push	1
	.byte 0x88
	nop
	push	sr
	ldwio	9, 0x8101
	nop
	push	1
	.byte 0x88
	nop
	push	sr
	ldwio	7, 0x9f00
	nop
	reti
	nop
	.byte 0xa6
	nop
	.byte 0x01
	ldwio	7, 0xa600
	nop
	popw	wa
	nop
	.byte 0xa6
	nop
	push	sr
	ldwio	72, 0x9f00
	nop
	popw	wa
	nop
	.byte 0xa6
	nop
	.byte 0x01
	ldwio	73, 0xa600
	nop
	.byte 0x88
	nop
	.byte 0xa6
	nop
	push	sr
	ldwio	136, 0x9f00
	nop
	.byte 0x88
	nop
	.byte 0xa6
	nop
	.byte 0x01
	ldwio	137, 0xa600
	nop
	.byte 0xc8
	nop
	.byte 0xa6
	nop
	push	sr
	ldwio	200, 0x9f00
	nop
	.byte 0xc8
	nop
	.byte 0xa6
	nop
	.byte 0x01
	ldwio	201, 0xa600
	nop
	push	1
	.byte 0xa6
	nop
	push	sr
	ldwio	9, 0x9f01
	nop
	push	1
	.byte 0xa6
	nop
	push	0
	scf
	nop
	pop_f
	nop
	ldb	a, 0
	pushw	bc
	nop
	ldw	bc, 0x3900
	nop
	ld	xbc, 0x51004900
	nop
	pop	xbc
	nop
	jr	lt, 0
	jr	ge, 0
	jrl	lt, 30976
	nop
	.byte 0x81
	nop
	.byte 0x89
	nop
	.byte 0x91
	nop
	.byte 0x99
	nop
	.byte 0xa1
	nop
	.byte 0xa9
	nop
	ld	(xbc), 185
	nop
	.byte 0xc1
	nop
	.byte 0xc9
	nop
	.byte 0xd1
	nop
	.byte 0xd9
	nop
	.byte 0xe1
	nop
	.byte 0xe9
	nop
	stdi8	0xf900, 1
	.byte 0x01
	ld	xde, 0x7e006000
	nop
	.byte 0x9c
	nop
	ld	xbc, 0x7261762d
	jr	ge, 49
	ld	xbc, 0x7261762d
	jr	ge, 50
	ld	xbc, 0x7261762d
	jr	ge, 51
	ld	xbc, 0x7261762d
	jr	ge, 52
	ld	xde, 0x7261762d
	jr	ge, 49
	ld	xde, 0x7261762d
	jr	ge, 50
	ld	xde, 0x7261762d
	jr	ge, 51
	ld	xde, 0x7261762d
	jr	ge, 52
	ld	xhl, 0x7261762d
	jr	ge, 49
	ld	xhl, 0x7261762d
	jr	ge, 50
	ld	xhl, 0x7261762d
	jr	ge, 51
	ld	xhl, 0x7261762d
	jr	ge, 52
	ld	xbc, 0x544e492d
	ldb	w, 49
	ld	xbc, 0x544e492d
	ldb	w, 50
	ld	xbc, 0x4c49462d
	popw	ix
	ldw	bc, 0x2d41
	ld	xiz, 0x324c4c49
	ld	xbc, 0x444e452d
	ldb	w, 49
	ld	xbc, 0x444e452d
	ldb	w, 50
	ld	xde, 0x544e492d
	ldb	w, 49
	ld	xde, 0x544e492d
	ldb	w, 50
	ld	xde, 0x4c49462d
	popw	ix
	ldw	bc, 0x2d42
	ld	xiz, 0x324c4c49
	ld	xde, 0x444e452d
	ldb	w, 49
	ld	xde, 0x444e452d
	ldb	w, 50
	ld	xhl, 0x544e492d
	ldb	w, 49
	ld	xhl, 0x544e492d
	ldb	w, 50
	ld	xhl, 0x4c49462d
	popw	ix
	ldw	bc, 0x2d43
	ld	xiz, 0x324c4c49
	ld	xhl, 0x444e452d
	ldb	w, 49
	ld	xhl, 0x444e452d
	ldb	w, 50
	push	xhl
	ldb_d8	a, 0x353e
	pop	xhl
	ret
	nop
	.byte 0x01
	push	sr
	pop	sr
	incf
	decf
	ret
	retd	4368
	.byte 0x04
	halt
	ei	7
	ccf
	zcf
	push_a
	pop_a
	ex_ff
	.byte 0x17
	ldio	9, 10
	pushw	6424
	.byte 0x1a
	jp	0x3b1d1c
	ldb_d8	a, 0x353c
	pop	xhl
	ret

AccPatch_InitSlotChain_Wrap:
	push xiz
	calr AccPatch_InitSlotChain
	pop xiz
	ret

AccPatch_InitSlotChain_WithAddr:
	push xiz
	ld xiz, 0x94800
	stda32 0x39ae, xiz
	calr AccPatch_InitSlotChain
	pop xiz
	ret

AccPatch_InitSlotChain:
	xor xwa, xwa
	xor xbc, xbc
	ldda32 xhl, 0x39ae
	add xhl, 0x1400
	stda32 0x376e, xhl
	ld wa, (xhl + 3)
	stda16 0x377e, xwa
	ldw bc, 0x96
	stda16 0x378e, xbc
	ldda32 xhl, 0x39ae
	add xhl, 0xaa00
	stda32 0x376a, xhl
	ldw bc, 0x96
	xor xhl, xhl

AccPatch_IterateSlotChain:
	cpdi16 0x377e, 0xffff
	jr z, AccPatch_IterateSlot_NextBlock
	ldw_d16 xhl, 0x377e
	calr AccPatch_CalcSlotBufferAddr
	stda32 0x375a, xiz
	cpda16 xhl, 0x378e
	jr z, AccPatch_IterateSlot_Advance
	calr AccPatch_UpdateLinkPointers
	calr AccPatch_SwapSlotBuffers

AccPatch_IterateSlot_Advance:
	ldda32 xiz, 0x376a
	ld wa, (xiz + 3)
	stda16 0x377e, xwa
	incdi16 1, 0x378e
	ldw_d16 xhl, 0x378e
	calr AccPatch_CalcSlotBufferAddr
	stda32 0x376a, xiz
	jr AccPatch_IterateSlotChain

AccPatch_IterateSlot_NextBlock:
	ld xiz, 0x100
	adddm32 0x376e, xiz
	ldda32 xiz, 0x376e
	ld wa, (xiz + 3)
	stda16 0x377e, xwa
	djnz xbc, AccPatch_IterateSlotChain
	xor xwa, xwa
	xor xhl, xhl
	ldw_d16 xwa, 0x378e
	ldw hl, 0x100
	mul xwa, xhl
	add xwa, 0x1400
	add xwa, 0x3ff
	and xwa, 0xfffffc00
	srl xwa, 4
	ldda32 xiy, 0x39ae
	ld (xiy + 46), wa
	ret

AccPatch_SwapSlotBuffers:
	push xbc
	ld xwa, 0x400
	push xwa
	call Malloc
	add xsp, 0x4
	stda32 0x3564, xhl
	ldw bc, 0x100
	ldda32 xix, 0x3564
	ldda32 xiy, 0x376a
	ldir85
	ldw bc, 0x100
	ldda32 xix, 0x376a
	ldda32 xiy, 0x375a
	ldir85
	ldw bc, 0x100
	ldda32 xiy, 0x3564
	ldda32 xix, 0x375a
	ldir85
	ldda32 xwa, 0x3564
	push xwa
	call Free
	add xsp, 0x4
	pop xbc
	ret

AccPatch_UpdateLinkPointers:
	xor xwa, xwa
	xor xhl, xhl
	ldda32 xiy, 0x375a
	ld wa, (xiy + 3)
	stda16 0x3927, xwa
	ld wa, (xiy + 1)
	stda16 0x3929, xwa
	ldda32 xix, 0x376a
	ld wa, (xix + 3)
	stda16 0x392b, xwa
	ld wa, (xix + 1)
	stda16 0x392d, xwa
	ldw_d16 xhl, 0x3927
	cp hl, 0xffff
	jr z, AccPatch_UpdateLink_Back
	calr AccPatch_CalcSlotBufferAddr
	ldw_d16 xwa, 0x378e
	ld (xiz + 1), wa

AccPatch_UpdateLink_Back:
	ldw_d16 xhl, 0x3929
	cp hl, 0xffff
	jr z, AccPatch_UpdateLink_Fwd1
	calr AccPatch_CalcSlotBufferAddr
	ldw_d16 xwa, 0x378e
	ld (xiz + 3), wa

AccPatch_UpdateLink_Fwd1:
	ldw_d16 xhl, 0x392b
	cp hl, 0xffff
	jr z, AccPatch_UpdateLink_Fwd2
	calr AccPatch_CalcSlotBufferAddr
	ldw_d16 xwa, 0x377e
	ld (xiz + 1), wa

AccPatch_UpdateLink_Fwd2:
	ldw_d16 xhl, 0x392d
	cp hl, 0xffff
	jr z, AccPatch_UpdateLink_Return
	calr AccPatch_CalcSlotBufferAddr
	ldw_d16 xwa, 0x377e
	ld (xiz + 3), wa

AccPatch_UpdateLink_Return:
	ret

AccPatch_CalcSlotBufferAddr:
	xor xiz, xiz
	ld xiz, 0x100
	mul xiz, xhl
	addda32 xiz, 0x39ae
	add xiz, 0x1400
	ret

AccPatch_VoiceAssignDataBlock:
	ret
	ret
	ldda32	xiy, 0x374e
	.byte 0x8d
	nop
	ldb	a, 201
	dec	5, l
	jr	nz, 23
	ld	a, (xiy+1)
	cp	a, 107
	jr	nz, 45
	ld	a, (xiy+2)
	cp	a, 97
	jr	nz, 37
	stdi8	0x379a, 0
	jr	71
	.byte 0x8d
	nop
	ldb	a, 201
	inc	6, l
	jr	nz, 22
	ld	a, (xiy+1)
	cps	a, 0
	jr	nz, 15
	ld	a, (xiy+2)
	cp	a, 107
	jr	nz, 7
	stdi8	0x379a, 0
	jr	41
	.byte 0x8d
	nop
	ldb	a, 201
	dec	5, l
	jr	nz, 23
	ld	a, (xiy+1)
	cp	a, 107
	jr	nz, 15
	ld	a, (xiy+2)
	cp	a, 98
	jr	nz, 7
	stdi8	0x379a, 0
	jr	10
	stdi8	0x379a, 255
	stdi8	0x3950, 130
	ret
	xor	xbc, xbc
	ldw	bc, 42
	add	xiy, 12
	add	xix, 12
	.byte 0x95
	scf
	djnz8	e, -22
	ret
	cp	xix, xiy
	jr	ugt, 15
	xor	xbc, xbc
	ldw	bc, 128
	.byte 0x95
	scf
	dec	1, e
	cps	e, 0
	jr	ugt, -13
	jr	38
	push	d
	ldb	d, 0
	lds32	xbc, 0
	ldw	bc, 256
	mul	xbc, xde
	pop	d
	add	xix, xbc
	add	xiy, xbc
	push	xix
	push	xiy
	dec	1, xix
	dec	1, xiy
	lds32	xbc, 0
	ldw	bc, 256
	.byte 0x85
	zcf
	dec	1, e
	cps	e, 0
	jr	ugt, -13
	pop	xiy
	pop	xix
	ret
	xor	xbc, xbc
	ld	(xiy), 0
	.byte 0xbd, 0x01
	push	sr
	swi	7
	swi	7
	.byte 0xbd
	pop	sr
	push	sr
	swi	7
	swi	7
	ldb	c, 249
	add	xiy, 6
	.byte 0xf5, 0xf4
	nop
	nop
	dec	1, c
	cps	c, 0
	jr	ugt, -10
	inc	1, xiy
	dec	1, e
	cps	e, 0
	jr	ugt, -39
	ret
	xor	xbc, xbc
	ld	xiy, 0x09f200
	ldb_d8	c, 0x393e
	cp	(xiy+1), wa
	jr	nz, 31
	.byte 0x9d
	pop	sr
	push	xsp
	swi	7
	swi	7
	jr	nz, 6
	.byte 0xc1
	.ascii "=9ah"
	calr	15809
	push	xbc
	jr	lt, -19
	.byte 0xc8
	nop
	.byte 0x01
	nop
	nop
	dec	1, c
	cps	c, 0
	jr	ugt, -29
	jr	12
	add	xiy, 256
	dec	1, c
	cps	c, 0
	jr	ugt, -48
	inc	1, wa
	.byte 0xd7, 0xe2, 0xf0
	jr	ule, -64
	ret
	ld	xiy, 0x09f200
	xor	xbc, xbc
	ldb	c, 190
	.byte 0x85
	push	xsp
	decm8	6, (xwa)
	decf
	incdi8	1, 0x3942
	add	xiy, 256
	djnz8	c, -18
	ret
	xor	xde, xde
	ld	de, (xiy+3)
	cp	de, 0xffff
	jr	z, 115
	ldw_d16	de, 0x3946
	ld	(xiy+3), de
	ldw_d16	de, 0x3944
	ld	(xix+1), de
	stdi16	0x394c, 0
	.byte 0x9c
	pop	sr
	push	xsp
	swi	7
	swi	7
	jr	z, 61
	ldw_d16	de, 0x394c
	cps	de, 0
	jr	nz, 25
	incdi16	1, 0x3946
	ldw_d16	de, 0x3946
	ld	(xix+3), de
	add	xix, 256
	stdi16	0x394c, 255
	jr	-40
	ldw_d16	de, 0x3946
	dec	1, de
	ld	(xix+1), de
	incdi16	1, 0x3946
	ldw_d16	de, 0x3946
	ld	(xix+3), de
	add	xix, 256
	jr	-68
	ldw_d16	de, 0x394c
	cps	de, 0
	jr	z, 9
	ldw_d16	de, 0x3946
	dec	1, de
	ld	(xix+1), de
	incdi16	1, 0x3946
	add	xix, 256
	incdi16	1, 0x3944
	add	xiy, 256
	dec	1, c
	cps	c, 0
	jrl	ugt, -141
	ret
	xor	xiz, xiz
	ld	xiz, 256
	mul	xiz, xhl
	add	xiz, 0x095c00
	ret
	push	xiz
	call	AccPatch_VoiceAssignDataBlock_0x1EE
	pop	xiz
	ret
	stdi8	0x3950, 0
	stdi16	0x3970, 0
	stdi16	0x3972, 150
	calr	1581
	calr	1579
	.byte 0xc1, 0x50
	push	xbc
	push	xsp
	incm8	6, (xix)
	ldw	iz, 0x551e
	nop
	cp	w, 255
	jr	nz, 7
	stdi8	0x3950, 130
	jr	39
	calr	51
	call	AccScreen_UIDataBlock_0x804
	calr	148
	calr	164
	.byte 0xf1, 0x50
	push	xbc
	dec	6, l
	push_a
	calr	657
	.byte 0xf1, 0x50
	push	xbc
	dec	6, l
	pushw	0xdc1e
	.byte 0x04, 0xf1, 0x50
	push	xbc
	dec	6, l
	push	sr
	jr	7
	call	AccScreen_UIDataBlock_0x804
	calr	112
	calr	1511
	call	AccPatch_ClearModeFlag
	ret
	xor	xwa, xwa
	ld	xiy, 0x069800
	ld	wa, (xiy+14)
	ld	xiy, 0x094800
	ld	(xiy+14), wa
	ret
	ld	xhl, 0x069800
	.byte 0x8b, 0x01
	push	xsp
	popw	wa
	jr	nz, 16
	.byte 0x8b
	push	sr
	push	xsp
	nop
	jr	nz, 10
	.byte 0x8b
	push	sr
	push	xsp
	popw	hl
	jr	nz, 4
	ldb	w, 5
	jr	57
	.byte 0x8b
	nop
	ldb	a, 201
	inc	7, l
	jr	nz, 19
	ld	a, (xhl+1)
	cps	a, 0
	jr	nz, 12
	ld	a, (xhl+2)
	cp	a, 107
	jr	nz, 4
	ldb	w, 5
	jr	30
	.byte 0x8b
	nop
	ldb	a, 201
	muls8rr	d, l
	jr	nz, 20
	ld	a, (xhl+1)
	cp	a, 75
	jr	nz, 12
	ld	a, (xhl+2)
	cp	a, 69
	jr	nz, 4
	ldb	w, 5
	jr	2
	ldb	w, 255
	ret
	ldb_d8	w, 0x34d6
	stb_d8	0x34d6, a
	pushw	wa
	.byte 0x1d
	cp	xbc, (xhl+0x48f5)
	.byte 0xd6
	ldw	ix, 3648
	xor	xhl, xhl
	xor	xwa, xwa
	call	AccScreen_UIDataBlock_0x829
	ld	l, a
	ldb	a, 96
	mul8rr	a, l
	add	wa, 96
	stda16	0x397a, wa
	xor	xwa, xwa
	call	AccScreen_UIDataBlock_0x804
	ld	l, a
	ldb	a, 96
	mul8rr	a, l
	add	wa, 96
	stda16	0x397c, wa
	.byte 0xd1
	jrl	gt, 16185
	.byte 0xc0
	pop	sr
	jr	c, 26
	.byte 0xd1
	jrl	gt, 16185
	.byte 0xc0
	pop	sr
	jr	z, 23
	.byte 0xd1
	jrl	gt, 16185
	.byte 0xe0
	reti
	jr	c, 20
	.byte 0xd1
	jrl	gt, 16185
	.byte 0xe0
	reti
	.ascii "f!h4"
	calr	79
	jr	76
	calr	121
	jr	71
	calr	1293
	.byte 0xc1, 0x50
	push	xbc
	push	xsp
	incm8	6, (xbc)
	push	xiy
	.byte 0xd1
	jrl	gt, 14905
	nop
	.byte 0x04
	calr	53
	jr	50
	calr	1272
	.byte 0xc1, 0x50
	push	xbc
	push	xsp
	incm8	6, (xbc)
	pushw	wa
	.byte 0xd1
	jrl	gt, 14905
	nop
	.byte 0x04
	calr	79
	jr	29
	calr	1251
	.byte 0xc1, 0x50
	push	xbc
	push	xsp
	incm8	6, (xbc)
	zcf
	calr	1241
	.byte 0xc1, 0x50
	push	xbc
	push	xsp
	incm8	6, (xbc)
	push	209
	jrl	gt, 14905
	nop
	ldio	30, 140
	nop
	ret
	xor	xiz, xiz
	ld	xiy, 0x069800
	ldw_d16	iz, 0x397a
	add	xiy, xiz
	add	xiy, 12
	ld	xix, 0x094800
	ldw_d16	iz, 0x397c
	add	xix, xiz
	add	xix, 12
	xor	xbc, xbc
	ldw	bc, 84
	.byte 0x85
	scf
	calr	142
	ret
	xor	xwa, xwa
	xor	xbc, xbc
	xor	xiz, xiz
	ldw	wa, 1024
	.byte 0xd1
	jrl	gt, -24519
	ld	bc, wa
	sub	bc, 12
	ld	xiy, 0x069800
	ld	xix, 0x094800
	ldw_d16	iz, 0x397a
	add	xiy, xiz
	add	xiy, 12
	ldw_d16	iz, 0x397c
	add	xix, xiz
	add	xix, 12
	push	xbc
	.byte 0x85
	scf
	push	xiy
	push	xix
	calr	80
	calr	1113
	pop	xix
	pop	xiy
	.byte 0xf1, 0x50
	push	xbc
	dec	6, l
	zcf
	pop	xbc
	ld	xiy, 0x069800
	ldw	wa, 96
	sub	wa, bc
	ld	bc, wa
	sub	bc, 12
	.byte 0x85
	scf
	ret
	xor	xiy, xiy
	xor	xix, xix
	ldw_d16	iy, 0x397a
	add	xiy, 0x069800
	add	xiy, 12
	ldw_d16	ix, 0x397c
	add	xix, 0x094800
	add	xix, 12
	ldw	bc, 96
	sub	bc, 12
	.byte 0x85
	scf
	calr	1
	ret
	xor	xiy, xiy
	xor	xix, xix
	xor	xwa, xwa
	ldw_d16	iy, 0x397a
	ld	xhl, 0x069800
	add	xhl, 0
	.byte 0xd3
	reti
	cp	xix, xix
	ldb	w, 241
	.asciz "R9PC"
	.byte 0x98
	di
	add	xhl, 4
	.byte 0xd3
	reti
	cp	xix, xix
	ldb	w, 241
	.byte 0x54
	push	xbc
	.byte 0x50
	ld	xhl, 0x069800
	add	xhl, 6
	.byte 0xd3
	reti
	cp	xix, xix
	ldb	w, 241
	.asciz "V9PC"
	.byte 0x98
	di
	add	xhl, 8
	.byte 0xd3
	reti
	cp	xix, xix
	ldb	w, 241
	pop	xwa
	push	xbc
	.byte 0x50
	ld	xhl, 0x069800
	add	xhl, 10
	.byte 0xd3
	reti
	cp	xix, xix
	ldb	w, 241
	pop	xde
	push	xbc
	.byte 0x50
	ldw_d16	ix, 0x397c
	add	xix, 0x094800
	.byte 0x9c
	nop
	ldb	w, 241
	pop	xix
	push	xbc
	.byte 0x50
	ld	wa, (xix+4)
	stda16	0x395e, wa
	ld	wa, (xix+6)
	stda16	0x3960, wa
	ld	wa, (xix+8)
	stda16	0x3962, wa
	ld	wa, (xix+10)
	stda16	0x3964, wa
	ret
	calr	876
	.byte 0xf1, 0x50
	push	xbc
	dec	6, l
	.byte 0x1f
	lds32	xwa, 5
	push	xwa
	calr	865
	pop	xwa
	.byte 0xf1, 0x50
	push	xbc
	dec	6, l
	ccf
	djnz8	a, -14
	calr	13
	calr	54
	calr	95
	calr	136
	calr	177
	ret
	ldw_d16	wa, 0x3952
	stda16	0x3974, wa
	ldw_d16	wa, 0x395c
	stda16	0x3976, wa
	calr	201
	ldw_d16	wa, 0x3974
	stda16	0x3952, wa
	ldw_d16	wa, 0x3978
	stda16	0x3966, wa
	ldw_d16	wa, 0x3976
	stda16	0x395c, wa
	ret
	ldw_d16	wa, 0x3954
	stda16	0x3974, wa
	ldw_d16	wa, 0x395e
	stda16	0x3976, wa
	calr	157
	ldw_d16	wa, 0x3974
	stda16	0x3954, wa
	ldw_d16	wa, 0x3978
	stda16	0x3968, wa
	ldw_d16	wa, 0x3976
	stda16	0x395e, wa
	ret
	ldw_d16	wa, 0x3956
	stda16	0x3974, wa
	ldw_d16	wa, 0x3960
	stda16	0x3976, wa
	calr	113
	ldw_d16	wa, 0x3974
	stda16	0x3956, wa
	ldw_d16	wa, 0x3978
	stda16	0x396a, wa
	ldw_d16	wa, 0x3976
	stda16	0x3960, wa
	ret
	ldw_d16	wa, 0x3958
	stda16	0x3974, wa
	ldw_d16	wa, 0x3962
	stda16	0x3976, wa
	calr	69
	ldw_d16	wa, 0x3974
	stda16	0x3958, wa
	ldw_d16	wa, 0x3978
	stda16	0x396c, wa
	ldw_d16	wa, 0x3976
	stda16	0x3962, wa
	ret
	ldw_d16	wa, 0x395a
	stda16	0x3974, wa
	ldw_d16	wa, 0x3964
	stda16	0x3976, wa
	calr	25
	ldw_d16	wa, 0x3974
	stda16	0x395a, wa
	ldw_d16	wa, 0x3978
	stda16	0x396e, wa
	ldw_d16	wa, 0x3976
	stda16	0x3964, wa
	ret
	.byte 0xf1, 0x50
	push	xbc
	dec	6, l
	retd	3358
	nop
	.byte 0xf1, 0x50
	push	xbc
	dec	6, l
	.byte 0x06
	calr	219
	calr	262
	ret
	calr	65
	cps	de, 0
	jr	z, 60
	ldw_d16	wa, 0x3974
	.byte 0xd1
	jrl	f, -4039
	jr	c, 47
	xor	xhl, xhl
	xor	xbc, xbc
	ldw_d16	bc, 0x3974
	srl	bc, 2
	ldw_d16	hl, 0x3970
	srl	hl, 2
	sub	bc, hl
	cps	bc, 0
	jr	ule, 21
	push	xbc
	calr	552
	pop	xbc
	.byte 0xf1, 0x50
	push	xbc
	dec	6, l
	ldwio	209, 0x3970
	push	xwa
	.byte 0x04
	nop
	dec	1, bc
	jr	-25
	jr	3
	calr	35
	ret
	xor	xwa, xwa
	xor	xhl, xhl
	xor	xde, xde
	ldw_d16	wa, 0x3974
	ldw_d16	hl, 0x3970
	cp	wa, hl
	jr	c, 12
	add	hl, 3
	cp	wa, hl
	jr	ugt, 4
	lds	de, 0
	jr	3
	ldw	de, 255
	ret
	.byte 0xf1, 0x50
	push	xbc
	dec	6, l
	.byte 0x52, 0xd1
	.ascii "t9?T"
	.byte 0x01
	jr	nc, 69
	calr	477
	.byte 0xf1, 0x50
	push	xbc
	dec	6, l
	ld	xbc, 0x1e38ace8
	.byte 0xd2, 0x01
	pop	xwa
	.byte 0xf1, 0x50
	push	xbc
	dec	6, l
	ldw	ix, 7369
	stiw_da	0x3970f1, 0
	xor	xbc, xbc
	ldw_d16	bc, 0x3974
	srl	bc, 2
	inc	1, bc
	cps	bc, 0
	jr	ule, 21
	push	xbc
	calr	431
	pop	xbc
	.byte 0xf1, 0x50
	push	xbc
	dec	6, l
	scf
	.byte 0xd1
	jrl	f, 14393
	.byte 0x04
	nop
	dec	1, bc
	jr	-25
	jr	5
	stdi8	0x3950, 128
	ret
	xor	xwa, xwa
	xor	xhl, xhl
	ldw_d16	wa, 0x3974
	ldw_d16	hl, 0x3970
	sub	wa, hl
	ldw	hl, 256
	mul	xwa, xhl
	stda16	0x397a, wa
	ret
	calr	65509
	xor	xiy, xiy
	ldw_d16	iy, 0x397a
	add	xiy, 6
	add	xiy, 0x069800
	xor	xhl, xhl
	ldw_d16	hl, 0x3976
	calr	64261
	ld	xix, xiz
	add	xix, 6
	xor	xbc, xbc
	ldw	bc, 249
	.byte 0x85
	scf
	ret
	xor	xiy, xiy
	xor	xwa, xwa
	calr	65459
	.byte 0xd1
	.asciz "z9%C"
	.byte 0x98
	di
	add	xhl, 3
	.byte 0xd3
	reti
	cp	xix, xix
	ldb	w, 241
	jrl	ov, 20537
	xor	xhl, xhl
	ldw_d16	hl, 0x3976
	stda16	0x3978, hl
	calr	64201
	ld	wa, (xiz+3)
	stda16	0x3976, wa
	ret
	ldw_d16	wa, 0x3952
	stda16	0x3974, wa
	ldw_d16	wa, 0x3966
	stda16	0x3978, wa
	calr	77
	ldw_d16	wa, 0x3954
	stda16	0x3974, wa
	ldw_d16	wa, 0x3968
	stda16	0x3978, wa
	calr	58
	ldw_d16	wa, 0x3956
	stda16	0x3974, wa
	ldw_d16	wa, 0x396a
	stda16	0x3978, wa
	calr	39
	ldw_d16	wa, 0x3958
	stda16	0x3974, wa
	ldw_d16	wa, 0x396c
	stda16	0x3978, wa
	calr	20
	ldw_d16	wa, 0x395a
	stda16	0x3974, wa
	ldw_d16	wa, 0x396e
	stda16	0x3978, wa
	calr	1
	ret
	xor	xwa, xwa
	.byte 0xf1, 0x50
	push	xbc
	scc8	nz, l
	.byte 0x84
	nop
	.byte 0xd1
	jrl	ov, 16185
	swi	7
	swi	7
	jr	z, 123
	.byte 0x1e
	jrl	ugt, 0xd100
	.ascii "r9?T"
	.byte 0x01
	jr	nc, 100
	ldw_d16	wa, 0x3972
	stda16	0x3976, wa
	calr	65088
	.byte 0xf1, 0x50
	push	xbc
	dec	6, l
	.byte 0x53
	calr	65294
	xor	xhl, xhl
	ldw_d16	hl, 0x3978
	calr	64040
	ldw_d16	wa, 0x3976
	ld	(xiz+3), wa
	ld	hl, wa
	calr	64028
	.byte 0x86
	push	xiz
	.byte 0x80
	decdi16	1, 0x34d4
	ldw_d16	wa, 0x3978
	ld	(xiz+1), wa
	xor	xiy, xiy
	ldw_d16	iy, 0x397a
	add	xiy, 0x069800
	ld	wa, (xiy+3)
	cp	wa, 0xffff
	jr	z, 5
	ld	(xiz+3), wa
	jr	5
	.byte 0xbe
	pop	sr
	push	sr
	swi	7
	swi	7
	stda16	0x3974, wa
	ldw_d16	wa, 0x3976
	.byte 0xf1
	.ascii "x9Ph‰Ñv"
	push	xbc
	ldb	c, 30
	.byte 0xda
	swi	1
	.byte 0xbe
	pop	sr
	push	sr
	swi	7
	swi	7
	nop
	nop
	ret
	xor	xhl, xhl
	ldw_d16	hl, 0x3972
	cp	hl, 340
	jr	nc, 25
	.byte 0x1e
	and	(xiz+8582), a
	ldw	hl, 0x6607
	retd	0x61db
	cp	hl, 340
	jr	nc, 2
	jr	-20
	stdi8	0x3950, 131
	stda16	0x3972, hl
	ret
	ret
	ret
	ret
	ret
	.byte 0xc1, 0x50
	push	xbc
	push	xsp
	nop
	jr	z, 63
	.byte 0xc1, 0x50
	push	xbc
	push	xsp
	incm8	6, (xix)
	.byte 0x1c, 0xc1, 0x50
	push	xbc
	push	xsp
	incm8	6, (xde)
	pushw	de
	.byte 0xc1, 0x50
	push	xbc
	push	xsp
	incm8	6, (xhl)
	pop_a
	.byte 0xc1, 0x50
	push	xbc
	push	xsp
	incm8	6, (xbc)
	pop_a
	stdi8	0x7f42, 1
	jr	33
	stdi8	0x7f42, 3
	jr	26
	stdi8	0x7f42, 23
	jr	19
	stdi8	0x7f42, 1
	jr	12
	stdi8	0x7f42, 0
	jr	5
	stdi8	0x7f42, 35
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
	anddi8 0x8d88, 254
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
	ld xhl, 0x1e881c
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
	setda 2, 0x28a7
	call AudioInit_RefreshToneBank
	call NoteMap_ProcessAndMerge
	call Voice_InitializeAll
	call Voice_InitTablePair
	call Voice_InitTableGroup
	call MIDI_SendAllSoundOff
	call Vga_SetupMultiPlaneDisplay
	jr AccDisplay_CopyToBackBuffer

Display_RestoreEntry:
	resda 2, 0x28a7
	call Vga_RestoreMultiPlaneDisplay
	jr AccDisplay_CopyToFrontBuffer

AccDisplay_CopyToBackBuffer:
	lda_24 xbc, 0x094800
	stda32 0x55dc, xbc
	lda_24 xwa, 0x069800
	stda32 0x55e0, xwa
	ld xiy, xbc
	ld xix, xwa
	ldw bc, 0xb400
	ldirw
	ret

AccDisplay_CopyToFrontBuffer:
	lda_24 xde, 0x094800
	stda32 0x55dc, xde
	lda_24 xwa, 0x069800
	stda32 0x55e0, xwa
	ld xiy, xwa
	ld xix, xde
	ldw bc, 0xb400
	ldirw
	ret

AccBankData_InitAllSlots:
	pushw_erp 0xfa
	ldda32 xwa, 0x3d5c
	stda32 0x55dc, xwa
	ldib_erp 0xfb, 0
	lds wa, 0

AccBankData_InitSlot_OuterLoop:
	lds32 xde, 0

AccBankData_InitSlot_InnerLoop:
	stb_dri A, 0x07, 0xe8, 0xe0
	addda32 xbc, 0x55dc
	stb_dri A, 0xe5, 0xa0, 0x00
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
	stb_dri A, 0x07, 0xe8, 0xe0
	addda32 xbc, 0x55dc
	stib_ind 0xe5, 0xa0, 0x00, 0x20
	inc 1, xde
	cp xde, 0x10
	jr c, AccBankData_PadSpaces_Loop

AccBankData_PadSpaces_Done:
	inc1b_erp 0xfb
	add wa, 0x60
	cp_erpb 0xfb, 0x0c
	jr c, AccBankData_InitSlot_OuterLoop
	stdi8 0x48d6, 0
	resda 0, 0x35b0
	ldib_erp 0xfb, 0

AccBankData_ProcessSlot:
	lda_24 xwa, 0x069800
	stda32 0x39ae, xwa
	stb_erp A, 0xfb
	stb_d8 0x39ac, a
	call AccPatch_InitFromSlotIndex
	ldda32 xwa, 0x3d5c
	stda32 0x39ae, xwa
	lda_24 xwa, 0x069800
	stda32 0x39b2, xwa
	stb_erp A, 0xfb
	stb_d8 0x39ad, a
	stb_erp A, 0xfb
	stb_d8 0x39ac, a
	call DualVoice_ParamLoadDone
	ldb_d8 a, 0x35b0
	extz wa
	bit 0, wa
	jr z, AccBankData_SlotFound
	stdi8 0x48d6, 1
	jr AccBankData_ReInitAllSlots

AccBankData_SlotFound:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x1e
	jr c, AccBankData_ProcessSlot
	cpdi8 0x48d6, 0
	jr z, AccBankData_FinalizeCheck

AccBankData_ReInitAllSlots:
	lda_24 xwa, 0x069800
	stda32 0x39ae, xwa
	ldib_erp 0xfb, 0

AccBankData_ReInit_Loop:
	stb_erp A, 0xfb
	stb_d8 0x39ac, a
	call AccPatch_InitFromSlotIndex
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x1e
	jr c, AccBankData_ReInit_Loop

AccBankData_FinalizeCheck:
	cpdi8 0x48d6, 0
	jr nz, AccBankData_Return
	ldda32 xwa, 0x3d5c
	add xwa, 0x16800
	ld bc, (xwa)
	lds32 xwa, 4
	lds de, 3
	call SoundParam_NotifyChange
	call SeqTimer_UpdateTempoReg
	ldda32 xbc, 0x3d5c
	add xbc, 0x16c00
	ld xix, xbc
	ldib_erp 0xfb, 0
	lda_d16 xde, 0xe3ba

AccBankData_CompareLoop:
	stb_erp A, 0xfb
	extz wa
	ld hl, wa
	extz xhl
	add xhl, xde
	ldb_spi A, 0xf0
	cp a, (xhl)
	jr nz, AccBankData_Return
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, AccBankData_CompareLoop
	ld xix, xbc
	lda_24 xbc, 0x1e0000
	lds32 xde, 0

AccBankData_CopyToExtRAM:
	ldb_spi A, 0xf0
	lda_dpi XBC, 0xe4
	inc 1, xde
	cp xde, 0x72a6
	jr c, AccBankData_CopyToExtRAM
	lds wa, 0
	call PostTmSave_Success

AccBankData_Return:
	popw_erp 0xfa
	ret

AccBankData_ProcessWithCopy:
	dec 2, xsp
	pushw_erp 0xfa
	ld (xsp + 2), a
	ldda32 xbc, 0x3d5c
	stda32 0x55dc, xbc
	pushw 0xd
	ldda32 xwa, 0x3d5c
	add xwa, 0x16802
	push xwa
	stb_dri W, 0xe5, 0xa0, 0x00
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	ldib_erp 0xfb, 0
	lds bc, 0

AccBankData_CopyLoop:
	ld de, bc
	add de, 0xa0
	ldda32 xwa, 0x55dc
	stb_dri W, 0x07, 0xe0, 0xe8
	ld e, (xwa)
	cps e, 0
	jr nz, AccBankData_CopyLoop_NonZero
	ldb e, 0x20

AccBankData_CopyLoop_NonZero:
	ld (xwa), e
	inc1b_erp 0xfb
	inc 1, bc
	cp_erpb 0xfb, 0x10
	jr c, AccBankData_CopyLoop
	cp (xsp + 2), 0x2
	jr ule, AccBankData_InitSlotScan
	call Vga_BackupPlane3ToBuffer
	ld c, (xsp + 2)
	inc 7, c
	extz bc
	ldda32 xde, 0x3d5c
	lds wa, 0
	call DualVoice_LoadAndScan
	call Vga_RestorePlane3FromBuffer
	call AccPatch_CountSlotsAlt
	jrl AccBankData_PostModeChange

AccBankData_InitSlotScan:
	stdi8 0x48d6, 0
	resda 0, 0x35b0
	ldib_erp 0xfb, 0

AccBankData_SlotScan_Loop:
	lda_24 xwa, 0x069800
	stda32 0x39ae, xwa
	ld c, (xsp + 2)
	extz bc
	stb_erp A, 0xfb
	extz wa
	muls wa, 0x3
	ld de, wa
	add de, bc
	lda_24 xwa, NakaInst_OFF_Str_0x42
	ldmm_srib 0x07, 0xe0, 0xe8, 0xac, 0x39
	call AccPatch_InitFromSlotIndex
	ldda32 xwa, 0x3d5c
	stda32 0x39ae, xwa
	lda_24 xwa, 0x069800
	stda32 0x39b2, xwa
	stb_erp A, 0xfb
	extz wa
	muls wa, 0x3
	ld bc, wa
	lda_24 xde, NakaInst_OFF_Str_0x42
	ldmm_srib 0x07, 0xe8, 0xe4, 0xac, 0x39
	ld a, (xsp + 2)
	extz wa
	add bc, wa
	ldmm_srib 0x07, 0xe8, 0xe4, 0xad, 0x39
	call DualVoice_ParamLoadDone
	ldb_d8 a, 0x35b0
	extz wa
	bit 0, wa
	jr z, AccBankData_SlotScan_Next
	stdi8 0x48d6, 1
	jr AccBankData_SlotScan_ReInit

AccBankData_SlotScan_Next:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0a
	jr c, AccBankData_SlotScan_Loop
	cpdi8 0x48d6, 0
	jr z, AccBankData_NotifyAndUpdateTempo

AccBankData_SlotScan_ReInit:
	lda_24 xwa, 0x069800
	stda32 0x39ae, xwa
	ldib_erp 0xfb, 0

AccBankData_ReInit_ScanLoop:
	ld c, (xsp + 2)
	extz bc
	stb_erp A, 0xfb
	extz wa
	muls wa, 0x3
	ld de, wa
	add de, bc
	lda_24 xwa, NakaInst_OFF_Str_0x42
	ldmm_srib 0x07, 0xe0, 0xe8, 0xac, 0x39
	call AccPatch_InitFromSlotIndex
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0a
	jr c, AccBankData_ReInit_ScanLoop
	jr AccBankData_PostModeChange

AccBankData_NotifyAndUpdateTempo:
	ldda32 xwa, 0x3d5c
	add xwa, 0x16800
	ld bc, (xwa)
	lds32 xwa, 4
	lds de, 3
	call SoundParam_NotifyChange
	call SeqTimer_UpdateTempoReg

AccBankData_PostModeChange:
	ldw wa, 0x16
	call UI_PostModeChangeEvent
	popw_erp 0xfa
	inc 2, xsp
	ret

AccBankData_CopyDataBlock:
	lda_d16	xbc, 0x48b6
	ld	xwa, xbc
	lda	xbc, (xbc+32)
	.byte 0xf5, 0xe0
	nop
	nop
	cp	xwa, xbc
	jr	c, -8
	ret

StyleBuf_ClearAllEntries:
	lda_d16 xbc, 0x3f88
	ld xwa, xbc
	stb_dri A, 0xe5, 0x00, 0x08

StyleBuf_ClearEntry_Outer:
	ld xde, xwa
	lda xhl, (xwa + 32)

StyleBuf_ClearEntry_Inner:
	stib_dsp 0xe8, 0x00
	cp xde, xhl
	jr c, StyleBuf_ClearEntry_Inner
	lda xwa, (xwa + 32)
	cp xwa, xbc
	jr c, StyleBuf_ClearEntry_Outer
	ret

StyleConv_ClearWorkBuffer:
	lda_d16 xbc, 0x488c
	ld xwa, xbc
	lda xbc, (xbc + 32)

StyleConv_ClearWorkBuf_Loop:
	stib_dsp 0xe0, 0x00
	cp xwa, xbc
	jr c, StyleConv_ClearWorkBuf_Loop
	ret

StyleConv_ClearEntryTables:
	lda_d16 xwa, 0x4788
	ld xbc, xwa
	lda_d16 xde, 0x3f88
	stb_dri C, 0xe1, 0x00, 0x01

StyleConv_ClearEntry_Outer:
	ld xwa, xde
	lda xix, (xde + 32)

StyleConv_ClearEntry_Inner:
	stib_dsp 0xe0, 0x00
	cp xwa, xix
	jr c, StyleConv_ClearEntry_Inner
	lds32 xwa, 0
	stl_dpi XWA, 0xe6
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
	lda_d16 xde, 0x55e4
	ld bc, hl
	extz xbc
	add xbc, xde
	ld wa, ix
	extz xwa
	div wa, 0x14
	stw_erp WA, 0xe2
	ld (xbc), a
	lds iz, 0

StyleConvInit_InnerLoop:
	ldib_erp 0xe2, 0
	cp iz, 0xc
	jr nc, StyleConvInit_StoreChar
	ldi_erpb 0xe2, 0x20

StyleConvInit_StoreChar:
	ld wa, hl
	add wa, iz
	ld iy, wa
	extz xiy
	add xiy, xde
	stb_erp A, 0xe2
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
	ld xwa, 0xffc00

SoundMem_ClearLoop:
	stib_dsp 0xe0, 0x00
	cp xwa, 0x100000
	jr c, SoundMem_ClearLoop
	ret

StyleFile_ClearAllTables:
	lda_d16 xwa, 0x555c
	ld xbc, xwa
	lda_d16 xde, 0x48dc
	stb_dri C, 0xe1, 0x80, 0x00

StyleFile_ClearTable_Outer:
	ld xwa, xde
	lda xix, (xde + 100)

StyleFile_ClearTable_Inner:
	stib_dsp 0xe0, 0x00
	cp xwa, xix
	jr c, StyleFile_ClearTable_Inner
	lds32 xwa, 0
	stl_dpi XWA, 0xe6
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
	ldiw_erp 0xfa, 0
	cps iz, 0
	jr ule, DialCalc_Return

DialCalc_EventLoop:
	ld xbc, 0x110002
	ldb_d8 a, 0x8d36
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
	addw_erp BC, 0xfa
	mul bc, 0x25
	lda_d16 xhl, 0x55e4
	ld de, bc
	extz xde
	add xde, xhl
	ld xbc, 0x1c0000f
	call ApPostEvent
	inc1w_erp 0xfa
	stw_erp WA, 0xfa
	cp wa, iz
	jr c, DialCalc_EventLoop

DialCalc_Return:
	pop xiz
	inc 2, xsp
	ret
__pad_F6C160:

StylCnvWaitTtlFunc:
	cp xbc, 0x1c00007
	jr z, AccChord_ReturnZero
	cp xbc, 0x1c00013
	jr nz, AccChord_ReturnZero
	cp xde, 0x3
	jr z, StylCnvWait_HandleClose
	cp xde, 0x8
	jr z, AccChord_ReturnZero
	cp xde, 0x2
	jr nz, AccChord_ReturnZero
	cpdi8 0x8d37, 96
	jr nz, StylCnvWait_CheckPending
	calr StyleConv_InitEntryTable
	stdi8 0x3d06, 0
	calr AccDisplay_FullInit
	call FileIO_CheckMediaIsWritable
	cps hl, 0
	jr nz, StylCnvWait_SetStatus
	ldw wa, 0x11
	call UI_PostModeChangeEvent

StylCnvWait_SetStatus:
	stdi8 0x48da, 0
	jr AccChord_ReturnZero

StylCnvWait_CheckPending:
	cpdi8 0x48da, 0
	jr z, AccChord_ReturnZero
	stdi8 0x7f42, 74
	ldw wa, 0xee
	call SoundCtrl_SendCommand
	stdi8 0x48da, 0
	jr AccChord_ReturnZero

StylCnvWait_HandleClose:
	cpdi8 0x8d36, 96
	jr z, StylCnvWait_RestoreDisplay
	cpdi8 0x8d34, 6
	jr z, AccChord_ReturnZero

StylCnvWait_RestoreDisplay:
	calr Display_RestoreEntry

AccChord_ReturnZero:
	lds32 xhl, 0
	ret
__pad_F6C1DE:

StylCnvTxtTtlFunc:
	cp xbc, 0x1c00007
	jr z, StylCnvTxt_ReturnZero
	cp xbc, 0x1c00013
	jr nz, StylCnvTxt_ReturnZero
	cp xde, 0x3
	jr z, StylCnvTxt_HandleClose
	cp xde, 0x8
	jr z, StylCnvTxt_ReturnZero
	cp xde, 0x2
	jr nz, StylCnvTxt_ReturnZero
	cpib_da 0x0ffc00, 0x05
	jr nz, StylCnvTxt_ReturnZero
	stib_da 0x0ffc00, 0xff
	calr TableData_JumpToEntry
	calr FloppyState_Dispatch
	jr StylCnvTxt_ReturnZero

StylCnvTxt_HandleClose:
	cpdi8 0x8d34, 6
	call_24 nz, Display_RestoreEntry

StylCnvTxt_ReturnZero:
	lds32 xhl, 0
	ret
__pad_F6C229:

StylCnvModlTtlFunc:
	lda xsp, (xsp - 36)
	push xiz
	ld xhl, xde
	ldw_d16 xde, 0x3d04
	ld iz, de
	ldw_d16 xwa, 0x3a82
	cp xbc, 0x1c00007
	jrl z, StylCnvModl_HandleOK
	cp xbc, 0x1c00013
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
	stdi8 0x48da, 0
	ld xwa, NakaInst_OFF_Str_0x60
	call ControlState_ProcessCommand
	stdi16 0x3a82, 0
	lds iz, 0

StylCnvModl_ScanMatchingModels:
	ld bc, iz
	mul bc, 0x25
	lda_d16 xwa, 0x55e4
	extz xbc
	add xbc, xwa
	lda xwa, (xbc + 1)
	lda xbc, (xbc + 33)
	call FileIO_SearchStringMatch
	cps hl, 0
	jr nz, StylCnvModl_ScanDone
	incdi16 1, 0x3a82
	inc 1, iz
	cp iz, 0x100
	jr c, StylCnvModl_ScanMatchingModels

StylCnvModl_ScanDone:
	cpdi16 0x3a82, 0
	jr nz, StylCnvModl_PadModelNames
	ldw wa, 0x10
	jrl StylCnvModl_OK_Select_ShowError

StylCnvModl_PadModelNames:
	cp iz, 0x100
	jr nc, StylCnvModl_InitListDisplay
	lda_d16 xhl, 0x55e4
	ld bc, iz
	mul bc, 0x25

StylCnvModl_PadOuterLoop:
	lds iy, 0
	ld de, bc

StylCnvModl_PadInnerLoop:
	ldb a, 0x0
	cp iy, 0xc
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
	stdi16 0x3d04, 0
	ld xwa, 0x110002
	ld xbc, 0x1e4002f
	lds32 xde, 0
	call ApPostEvent
	lda_d16 xbc, 0x3f68
	ld xwa, xbc
	lda xbc, (xbc + 32)

StylCnvModl_ClearDisplayBuf:
	stib_dsp 0xe0, 0x00
	cp xwa, xbc
	jr c, StylCnvModl_ClearDisplayBuf
	ld xwa, NakaInst_OFF_Str_0x6C
	call ControlState_ProcessCommand
	lda xbc, (xsp + 36)
	ld xwa, 0x3f68
	call FileIO_SearchStringMatch
	lda_d16 xwa, 0x3f68
	cps hl, 0
	jr nz, StylCnvModl_CopyDefaultName
	pushw 0x2e
	push xwa
	call Sprintf_StringLength
	inc 6, xsp
	or xhl, xhl
	jr z, StylCnvModl_FormatFilename
	ld (xhl), 0x0

StylCnvModl_FormatFilename:
	lds iy, 0
	lda_d16 xde, 0x3f68

StylCnvModl_FormatLoop:
	ld bc, iy
	extz xbc
	add xbc, xde
	ld a, (xbc)
	cps a, 0
	jr z, StylCnvModl_DrawListUI
	cp a, 0x5f
	jr nz, StylCnvModl_CheckPercent
	ld (xbc), 0x20
	jr StylCnvModl_FormatNext

StylCnvModl_CheckPercent:
	cp a, 0x25
	jr nz, StylCnvModl_FormatNext
	ld (xbc), 0x2e

StylCnvModl_FormatNext:
	inc 1, iy
	cp iy, 0x20
	jr c, StylCnvModl_FormatLoop
	jr StylCnvModl_DrawListUI

StylCnvModl_CopyDefaultName:
	pushw 0x0
	pushw 0xe3d2
	push xwa
	call Strcpy
	inc 8, xsp

StylCnvModl_DrawListUI:
	ld xwa, 0x110007
	ld xbc, 0x1c0000b
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
	cpdi8 0x8d36, 96
	jr z, StylCnvModl_RedrawDone
	cpdi8 0x8d34, 6
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
	cp xhl, 0xb
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
	stda16 0x3d04, xde

StylCnvModl_OK_LoadSelection:
	ldw_d16 xbc, 0x3d04

StylCnvModl_OK_UpdateDisplay:
	cp iz, bc
	jrl z, StylCnvModl_Return
	extz xbc
	div bc, 0x14
	stw_erp DE, 0xe6
	extz xde
	ld xwa, 0x110002
	ld xbc, 0x1e4002f
	call ApPostEvent
	ldw_d16 xde, 0x3d04
	ld bc, de
	extz xbc
	div bc, 0x14
	ld wa, iz
	extz xwa
	div wa, 0x14
	cp wa, bc
	jrl nz, StylCnvModl_OK_PageRedraw
	mul iz, 0x25
	lda_d16 xwa, 0x55e4
	ld de, iz
	extz xde
	add xde, xwa
	ld xwa, 0x110002
	ld xbc, 0x1c0000f
	call ApPostEvent
	ldw_d16 xde, 0x3d04
	mul de, 0x25
	lda_d16 xwa, 0x55e4
	extz xde
	add xde, xwa
	ld xwa, 0x110002
	ld xbc, 0x1c0000f
	call ApPostEvent
	jrl StylCnvModl_Return

StylCnvModl_OK_ScrollUp:
	lds wa, 1
	call UI_PostEvent_0x6E
	ldw_d16 xwa, 0x3d04
	cps wa, 0
	jrl z, StylCnvModl_OK_LoadSelection
	dec 1, wa
	stda16 0x3d04, xwa
	ld bc, wa
	jrl StylCnvModl_OK_UpdateDisplay

StylCnvModl_OK_ScrollDown:
	lds wa, 1
	call UI_PostEvent_0x6E
	ldw_d16 xbc, 0x3a82
	dec 1, bc
	ldw_d16 xwa, 0x3d04
	cp wa, bc
	jrl nc, StylCnvModl_OK_LoadSelection
	inc 1, wa
	stda16 0x3d04, xwa
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
	stw_erp WA, 0xee
	cps wa, 0
	jrl z, StylCnvModl_OK_LoadSelection
	stda16 0x3d04, xbc
	jrl StylCnvModl_OK_UpdateDisplay

StylCnvModl_OK_SelectItem:
	mul de, 0x25
	lda_d16 xwa, 0x55e5
	extz xde
	add xde, xwa
	ld xwa, xde
	ld xbc, NakaInst_OFF_Str_0x78
	call FileIO_OpenWithBuiltPath
	cps hl, 0
	jr ge, StylCnvModl_OK_Select_ClearMem
	ldw wa, 0x10
	jr StylCnvModl_OK_Select_ShowError

StylCnvModl_OK_Select_ClearMem:
	ld xbc, 0x80000
	lds32 xwa, 0

StylCnvModl_OK_Select_FillLoop:
	stib_dsp 0xe4, 0x00
	inc 1, xwa
	cp xwa, 0x30000
	jr c, StylCnvModl_OK_Select_FillLoop
	ldw_d16 xbc, 0x3d04
	mul bc, 0x25
	lda_d16 xwa, 0x5605
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
	ldw_d16 xbc, 0x3d04
	mul bc, 0x25
	lda_d16 xwa, 0x5605
	extz xbc
	add xbc, xwa
	ld xbc, (xbc)
	ld xwa, xbc
	and xwa, 0xff
	jr z, StylCnvModl_OK_Select_AlignSize
	and xbc, 0xffffff00
	add xbc, 0x100

StylCnvModl_OK_Select_AlignSize:
	add xbc, 0x80000
	stda32 0x3d5c, xbc
	call FileIO_CloseHandle
	stib_da 0x0ffbfe, 0x00
	ldw_d16 xwa, 0x3d04
	stda16 0x48ac, xwa
	lds iz, 0
	lda_d16 xhl, 0xe3ca
	ldw_d16 xwa, 0x3d04
	mul wa, 0x25
	lda_d16 xbc, 0x55e4

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
	stda16 0x48ac, xwa
	stib_da 0x0ffc00, 0xff
	stib_da 0x0ffc01, 0x00
	pushw 0x4
	ldw_d16 xwa, 0x3d04
	mul wa, 0x25
	extz xwa
	add xwa, xbc
	lda xwa, (xwa + 33)
	push xwa
	ld xwa, 0xffc02
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	ldw_d16 xbc, 0x3d04
	mul bc, 0x25
	lda_d16 xwa, 0x5605
	extz xbc
	add xbc, xwa
	ld xwa, (xbc)
	stda32 0x3d58, xwa
	calr TableData_JumpToEntry
	calr FloppyState_Dispatch
	jr StylCnvModl_Return

StylCnvModl_OK_PageRedraw:
	ldw_d16 xbc, 0x3a82
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
	ldw_d16 xhl, 0x3d04
	ld iz, hl
	ldw_d16 xix, 0x3a82
	cp xbc, 0x1c00007
	jrl z, StylCnvCnvt_HandleOK
	cp xbc, 0x1c00013
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
	stdi8 0x48da, 0
	calr DialUI_PostInitEvents
	stdi16 0x3a82, 0
	lds iz, 0

StylCnvCnvt_ScanMatchingStyles:
	ld bc, iz
	mul bc, 0x25
	lda_d16 xwa, 0x55e4
	extz xbc
	add xbc, xwa
	lda xwa, (xbc + 1)
	lda xbc, (xbc + 33)
	call FileIO_SearchStringMatch
	cps hl, 0
	jr nz, StylCnvCnvt_PadStyleNames
	incdi16 1, 0x3a82
	inc 1, iz
	cp iz, 0x100
	jr c, StylCnvCnvt_ScanMatchingStyles

StylCnvCnvt_PadStyleNames:
	cp iz, 0x100
	jr nc, StylCnvCnvt_InitListDisplay
	lda_d16 xhl, 0x55e4
	ld bc, iz
	mul bc, 0x25

StylCnvCnvt_PadOuterLoop:
	lds iy, 0
	ld de, bc

StylCnvCnvt_PadInnerLoop:
	ldb a, 0x0
	cp iy, 0xc
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
	stdi16 0x3d04, 0
	ld xwa, 0x120002
	ld xbc, 0x1e4002f
	lds32 xde, 0
	call ApPostEvent
	jrl StylCnvCnvt_Return

StylCnvCnvt_HandleScroll:
	ldw wa, 0x14
	ld bc, ix
	ld de, hl
	jrl StylCnvCnvt_OK_CallRedraw

StylCnvCnvt_HandleRedraw:
	cpdi8 0x8d34, 6
	call_24 nz, Display_RestoreEntry
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
	cp xde, 0xb
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
	stda16 0x3d04, xhl

StylCnvCnvt_OK_LoadSelection:
	ldw_d16 xbc, 0x3d04

StylCnvCnvt_OK_UpdateDisplay:
	cp iz, bc
	jrl z, StylCnvCnvt_Return
	extz xbc
	div bc, 0x14
	stw_erp DE, 0xe6
	extz xde
	ld xwa, 0x120002
	ld xbc, 0x1e4002f
	call ApPostEvent
	ldw_d16 xde, 0x3d04
	ld bc, de
	extz xbc
	div bc, 0x14
	ld wa, iz
	extz xwa
	div wa, 0x14
	cp wa, bc
	jrl nz, StylCnvCnvt_OK_PageRedraw
	mul iz, 0x25
	lda_d16 xwa, 0x55e4
	ld de, iz
	extz xde
	add xde, xwa
	ld xwa, 0x120002
	ld xbc, 0x1c0000f
	call ApPostEvent
	ldw_d16 xde, 0x3d04
	mul de, 0x25
	lda_d16 xwa, 0x55e4
	extz xde
	add xde, xwa
	ld xwa, 0x120002
	ld xbc, 0x1c0000f
	call ApPostEvent
	jrl StylCnvCnvt_Return

StylCnvCnvt_OK_ScrollUp:
	lds wa, 1
	call UI_PostEvent_0x6E
	ldw_d16 xwa, 0x3d04
	cps wa, 0
	jrl z, StylCnvCnvt_OK_LoadSelection
	dec 1, wa
	stda16 0x3d04, xwa
	ld bc, wa
	jrl StylCnvCnvt_OK_UpdateDisplay

StylCnvCnvt_OK_ScrollDown:
	lds wa, 1
	call UI_PostEvent_0x6E
	ldw_d16 xbc, 0x3a82
	dec 1, bc
	ldw_d16 xwa, 0x3d04
	cp wa, bc
	jrl nc, StylCnvCnvt_OK_LoadSelection
	inc 1, wa
	stda16 0x3d04, xwa
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
	stw_erp WA, 0xea
	cps wa, 0
	jrl z, StylCnvCnvt_OK_LoadSelection
	stda16 0x3d04, xbc
	jrl StylCnvCnvt_OK_UpdateDisplay

StylCnvCnvt_OK_SelectItem:
	ldb_d8 a, 0x3d06
	cps a, 2
	jr z, StylCnvCnvt_OK_Select_WriteStyle
	cps a, 1
	jr nz, StylCnvCnvt_Return
	ldw_d16 xwa, 0x48ac
	cps wa, 1
	jr z, StylCnvCnvt_OK_Select_Finalize
	cps wa, 0
	jr z, StylCnvCnvt_OK_Select_Finalize
	jr StylCnvCnvt_Return

StylCnvCnvt_OK_Select_WriteStyle:
	ldda32 xwa, 0x3d5c
	stda32 0x3d60, xwa
	call FileIO_CheckMediaIsWritable
	ldw_d16 xbc, 0x3d04
	mul bc, 0x25
	lda_d16 xwa, 0x55e5
	extz xbc
	add xbc, xwa
	ld xwa, xbc
	call FileIO_NormalizePath

StylCnvCnvt_OK_Select_Finalize:
	stib_da 0x0ffc00, 0xff
	calr TableData_JumpToEntry
	calr FloppyState_Dispatch
	jr StylCnvCnvt_Return

StylCnvCnvt_OK_PageRedraw:
	ldw_d16 xbc, 0x3a82
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
	ldw_d16 xix, 0x3d04
	ld iz, ix
	ldw_d16 xbc, 0x3a82
	cp xhl, 0x1c00007
	jr z, StylCnvSel_HandleOK
	cp xhl, 0x1c00013
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
	stdi16 0x3d04, 0
	ld xwa, 0x150002
	ld xbc, 0x1e4002f
	lds32 xde, 0
	call ApPostEvent
	jrl StylCnvSel_Return

StylCnvSel_HandleScroll:
	ldw wa, 0x14
	ld de, ix
	jrl StylCnvSel_OK_CallRedraw

StylCnvSel_HandleRedraw:
	cpdi8 0x8d34, 6
	call_24 nz, Display_RestoreEntry
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
	cp xde, 0xb
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
	stda16 0x3d04, xix

StylCnvSel_OK_LoadSelection:
	ldw_d16 xbc, 0x3d04

StylCnvSel_OK_UpdateDisplay:
	cp iz, bc
	jrl z, StylCnvSel_Return
	extz xbc
	div bc, 0x14
	stw_erp DE, 0xe6
	extz xde
	ld xwa, 0x150002
	ld xbc, 0x1e4002f
	call ApPostEvent
	ldw_d16 xde, 0x3d04
	ld bc, de
	extz xbc
	div bc, 0x14
	ld wa, iz
	extz xwa
	div wa, 0x14
	cp wa, bc
	jrl nz, StylCnvSel_OK_PageRedraw
	mul iz, 0x25
	lda_d16 xbc, 0x55e4
	ld de, iz
	extz xde
	add xde, xbc
	ld xwa, 0x150002
	ld xbc, 0x1c0000f
	call ApPostEvent
	ldw_d16 xwa, 0x3d04
	mul wa, 0x25
	lda_d16 xbc, 0x55e4
	ld de, wa
	extz xde
	add xde, xbc
	ld xwa, 0x150002
	ld xbc, 0x1c0000f
	call ApPostEvent
	jrl StylCnvSel_Return

StylCnvSel_OK_ScrollUp:
	lds wa, 1
	call UI_PostEvent_0x6E
	ldw_d16 xwa, 0x3d04
	cps wa, 0
	jrl z, StylCnvSel_OK_LoadSelection
	dec 1, wa
	stda16 0x3d04, xwa
	ld bc, wa
	jrl StylCnvSel_OK_UpdateDisplay

StylCnvSel_OK_ScrollDown:
	lds wa, 1
	call UI_PostEvent_0x6E
	ldw_d16 xbc, 0x3a82
	dec 1, bc
	ldw_d16 xwa, 0x3d04
	cp wa, bc
	jrl nc, StylCnvSel_OK_LoadSelection
	inc 1, wa
	stda16 0x3d04, xwa
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
	stw_erp WA, 0xea
	cps wa, 0
	jrl z, StylCnvSel_OK_LoadSelection
	stda16 0x3d04, xbc
	jrl StylCnvSel_OK_UpdateDisplay

StylCnvSel_OK_SelectItem:
	calr SoundMem_ClearRegion
	stib_da 0x0ffc00, 0xff
	ldw_d16 xwa, 0x3d04
	inc 1, a
	stb_da 0x0ffc01, a
	calr TableData_JumpToEntry
	calr FloppyState_Dispatch
	jr StylCnvSel_Return

StylCnvSel_OK_PageRedraw:
	ldw_d16 xbc, 0x3a82
	ldw wa, 0x14

StylCnvSel_OK_CallRedraw:
	calr DialUI_CalcProlog

StylCnvSel_Return:
	lds32 xhl, 0
	pop xiz
	ret
StylCnvSel_End:

StylCnvContTtlFunc:
	cp xbc, 0x1c00007
	jr z, StylCnvCont_HandleOK
	cp xbc, 0x1c00013
	jrl nz, AccRhythm_ReturnZero
	cp xde, 0x3
	jr z, StylCnvCont_HandleClose
	cp xde, 0x8
	jrl z, AccRhythm_ReturnZero
	cp xde, 0x2
	jrl nz, AccRhythm_ReturnZero
	cpdi8 0x48d6, 0
	jr z, StylCnvCont_CheckPending
	stdi8 0x7f42, 15
	ldw wa, 0xee
	call SoundCtrl_SendCommand
	stdi8 0x48d6, 0

StylCnvCont_CheckPending:
	cpdi8 0x48da, 0
	jr z, AccRhythm_ReturnZero
	stdi8 0x7f42, 74
	ldw wa, 0xee
	call SoundCtrl_SendCommand
	stdi8 0x48da, 0
	jr AccRhythm_ReturnZero

StylCnvCont_HandleClose:
	cpdi8 0x8d34, 6
	jr z, AccRhythm_ReturnZero
	calr Display_RestoreEntry
	jr AccRhythm_ReturnZero

StylCnvCont_HandleOK:
	cp xde, 0xb
	jr z, StylCnvCont_NotifyPart
	cp xde, 0xa
	jr nz, AccRhythm_ReturnZero
	stdi8 0x3d06, 0
	calr SoundMem_ClearRegion
	stib_da 0x0ffc00, 0xff
	stib_da 0x0ffc01, 0x00
	pushw 0x4
	pushw 0x0
	pushw 0x3d58
	ld xwa, 0xffc02
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
	cp xbc, 0x1c00013
	jr nz, StylCnvStor_ReturnZero
	cp xde, 0x3
	jr z, StylCnvStor_HandleClose
	lds32 xhl, 0
	ret

StylCnvStor_HandleClose:
	cpdi8 0x8d34, 6
	call_24 nz, Display_RestoreEntry

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
	stdi8 0x48da, 255
	ldw wa, 0x10
	jp UI_PostModeChangeEvent

FloppyState_Dispatch:
	lda xsp, (xsp - 114)
	push xiz

StyleConv_DispatchSoundMemState:
	ldb_da a, 0x0ffc00
	cps a, 0
	jr nz, StylCnvDisp_CheckFE
	cpdi16 0x48ac, 1
	jr nz, StylCnvDisp_PostMode13
	calr AccBankData_InitAllSlots
	lds wa, 1
	call UI_PostPartChangeEvent
	jrl StylCnv_Epilogue114

StylCnvDisp_PostMode13:
	ldw wa, 0x13
	jrl StylCnv_PostModeChange

StylCnvDisp_CheckFE:
	cp a, 0xfe
	jr nz, StylCnvDisp_CheckType
	stdi8 0x48da, 255
	ldw wa, 0x16
	jrl StylCnv_PostModeChange

StylCnvDisp_CheckType:
	cps a, 3
	jrl z, StylCnv_Multi_InitAndClear
	cps a, 4
	jrl z, StylCnv_DispatchByType
	cps a, 2
	jr z, StylCnvDisp_Type2_CheckSubtype
	lda_d16 xbc, 0x3d68
	cps a, 1
	jr z, StylCnvDisp_Type1_CopyPath
	cps a, 5
	jrl nz, StylCnv_AbortWithError
	ld xwa, 0xffc01
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp
	stdi8 0x3d06, 5
	ldw wa, 0x14
	jrl StylCnv_PostModeChange

StylCnvDisp_Type1_CopyPath:
	ld xwa, 0xffc01
	push xwa
	push xbc
	jr StylCnvDisp_CopyAndFinalize

StylCnvDisp_Type2_CheckSubtype:
	ldb_da a, 0x0ffc01
	cp a, 0x40
	jrl z, StylCnv_Type4_Init
	cp a, 0x80
	jr z, StylCnvDisp_Subtype80_Process
	cp a, 0x10
	jr z, StylCnvDisp_Subtype10_Process
	cps a, 0
	jrl nz, StyleConv_DispatchSoundMemState
	stdi8 0x3d06, 1
	ld xwa, 0xffc00
	call ControlState_ProcessCommand
	lda_d16 xbc, 0x3d08
	ld (xbc), 0x2
	ld (xbc + 1), 0x0
	ld xwa, 0xffc02
	push xwa
	lda xwa, (xbc + 2)
	push xwa
	jr StylCnvDisp_CopyAndFinalize

StylCnvDisp_Subtype10_Process:
	stdi8 0x3d06, 2
	ld xwa, 0xffc00
	call ControlState_ProcessCommand
	ld xwa, 0xffc00
	push xwa
	lda_d16 xwa, 0x3d08
	push xwa

StylCnvDisp_CopyAndFinalize:
	call Strcpy
	inc 8, xsp
	jrl StylCnv_ClearAndFinalize

StylCnvDisp_Subtype80_Process:
	cpib_da 0x0ffc02, 0x2e
	jrl nz, ControlState_Type3
	stdi8 0x3d06, 6
	calr StyleBuf_ClearAllEntries
	calr StyleConv_ClearWorkBuffer
	ldw (xsp + 4), 0x0
	stdi16 0x48d8, 0

StylCnvDisp_ScanFileLoop:
	pushw 0x3
	pushw 0xe4
	pushw 0xc14e
	ld wa, (xsp + 10)
	inc 2, wa
	extz xwa
	add xwa, 0xffc00
	push xwa
	call String_Compare
	add xsp, 0xa
	cps hl, 0
	jr z, StylCnv_ParseEntry_Done
	ld wa, (xsp + 4)
	inc 2, wa
	extz xwa
	add xwa, 0xffc00
	ld a, (xwa)
	cp a, 0x2a
	jrl z, ControlState_Type3
	cp a, 0x3f
	jrl z, ControlState_Type3
	ldw (xsp + 6), 0x0

StylCnv_ParseEntry_ScanChar:
	ld wa, (xsp + 4)
	inc 2, wa
	extz xwa
	add xwa, 0xffc00
	ld a, (xwa)
	cp a, 0x2c
	jr nz, StylCnv_ParseEntry_StoreChar
	incdi16 1, 0x48d8
	jr StylCnv_ParseEntry_NextField

StylCnv_ParseEntry_StoreChar:
	ldw_d16 xbc, 0x48d8
	sll bc, 5
	ld de, (xsp + 6)
	add de, bc
	lda_d16 xbc, 0x3f88
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
	ldw_d16 xix, 0x3d04
	mul ix, 0x25
	lda_d16 xhl, 0x55e4

StylCnv_CopyNameLoop:
	ld wa, (xsp + 4)
	add wa, ix
	extz xwa
	add xwa, xhl
	ld c, (xwa + 1)
	cp c, 0x2e
	jr z, StylCnv_CopyName_Finalize
	lda_d16 xde, 0x488c
	ld wa, (xsp + 4)
	lda_dri XHL, 0x07, 0xe8, 0xe0
	incm 1, (xsp + 4)
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_CopyNameLoop

StylCnv_CopyName_Finalize:
	pushw 0x0
	pushw 0x3f88
	pushw 0x0
	pushw 0x488c
	jrl StylCnv_AppendAndClear

ControlState_Type3:
	stdi8 0x3d06, 3
	ld xwa, 0xffc00
	call ControlState_ProcessCommand
	jrl StylCnv_ClearAndFinalize

StylCnv_Type4_Init:
	stdi8 0x3d06, 4
	lda_d16 xde, 0x48b6
	ld xwa, xde
	lda xbc, (xde + 32)

StylCnv_Type4_ClearLoop:
	stib_dsp 0xe0, 0x00
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
	add xwa, 0xffc00
	ld c, (xwa)
	cps c, 0
	jr z, LoopIndex_Reset
	ld wa, (xsp + 6)
	lda_dri XHL, 0x07, 0xe8, 0xe0
	incm 1, (xsp + 4)
	incm 1, (xsp + 6)
	cpw (xsp + 4), 0x28
	jr lt, StylCnv_Type4_CopyChars

LoopIndex_Reset:
	ldw (xsp + 6), 0x0

StylCnv_Type4_FindDot:
	ld wa, (xsp + 6)
	cpib_sri 0x07, 0xe8, 0xe0, 0x2e
	jr z, StylCnv_Type4_CalcExtLen
	incm 1, (xsp + 6)
	cpw (xsp + 6), 0x20
	jr lt, StylCnv_Type4_FindDot

StylCnv_Type4_CalcExtLen:
	ldw (xsp + 16), 0x0

StylCnv_Type4_CountExt:
	ld wa, (xsp + 6)
	cpib_sri 0x07, 0xe8, 0xe0, 0x00
	jr z, StylCnv_Type4_CalcCenter
	incm 1, (xsp + 16)
	incm 1, (xsp + 6)
	cpw (xsp + 16), 0x20
	jr lt, StylCnv_Type4_CountExt

StylCnv_Type4_CalcCenter:
	ld wa, (xsp + 16)
	exts xwa
	divs wa, 0x2
	stw_erp WA, 0xe2
	ldiw_erp 0xfa, 1
	cps wa, 0
	jr nz, StylCnv_Type4_CheckNull
	ldiw_erp 0xfa, 2

StylCnv_Type4_CheckNull:
	ld wa, (xsp + 4)
	inc 2, wa
	extz xwa
	add xwa, 0xffc00
	cp (xwa), 0x0
	jr nz, StylCnv_Type4_Advance
	inc 1, iz
	cpw_erp IZ, 0xfa
	jr nz, StylCnv_Type4_Advance
	incm 1, (xsp + 4)
	pushw 0x4
	ld wa, (xsp + 6)
	inc 2, wa
	extz xwa
	add xwa, 0xffc00
	push xwa
	pushw 0x0
	pushw 0x48ae
	call Mem_Copy
	incm 4, (xsp + 14)
	pushw 0x4
	ld wa, (xsp + 16)
	inc 2, wa
	extz xwa
	add xwa, 0xffc00
	push xwa
	pushw 0x0
	pushw 0x48b2
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
	ldw_d16 xix, 0x3d04
	mul ix, 0x25
	lda_d16 xhl, 0x55e4

StylCnv_Type4_CopyNameLoop2:
	ld wa, (xsp + 4)
	add wa, ix
	extz xwa
	add xwa, xhl
	ld e, (xwa + 1)
	lda_d16 xbc, 0x488c
	cp e, 0x2e
	jr z, StylCnv_Type4_AppendExt
	ld wa, (xsp + 4)
	lda_dri XIY, 0x07, 0xe4, 0xe0
	incm 1, (xsp + 4)
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_Type4_CopyNameLoop2

StylCnv_Type4_AppendExt:
	pushw 0x0
	pushw 0x48b6
	push xbc

StylCnv_AppendAndClear:
	call Strcat
	inc 8, xsp

StylCnv_ClearAndFinalize:
	stib_da 0x0ffc00, 0xff
	jrl StylCnv_FinalizeAndCheckStatus

StylCnv_DispatchByType:
	ldb_d8 a, 0x3d06
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
	cpdi8 0x8d36, 22
	jrl nz, StylCnv_Epilogue114
	ldw wa, 0x12
	jrl StylCnv_PostModeChange

StylCnv_Type2_CheckSoundMem:
	cpdi8 0x8d36, 22
	jrl nz, StylCnv_Epilogue114
	ldw wa, 0x12
	jrl StylCnv_PostModeChange

StylCnv_Type3_ProcessFiles:
	ldda32 xwa, 0x3d5c
	ld (xsp + 10), xwa
	ldw (xsp + 4), 0x0
	calr StyleConv_ClearEntryTables
	calr StyleFile_ClearAllTables
	ld xwa, 0x488c
	ld xbc, 0x4888
	call FileIO_SearchStringMatch
	cps hl, 0
	jr lt, StylCnv_Type3_CheckCount

StylCnv_Type3_SearchLoop:
	cpw (xsp + 4), 0x20
	jr ge, StylCnv_Type3_SearchNext
	ldda32 xwa, 0x4888
	cp xwa, 0x0
	jr lt, StylCnv_Type3_SearchNext
	call FileIO_ExtractBasename
	push xhl
	lda xwa, (xsp + 22)
	push xwa
	call Strcpy
	pushw 0x0
	pushw 0x488c
	lda xwa, (xsp + 30)
	push xwa
	call Strcat
	lda xwa, (xsp + 34)
	push xwa
	ld wa, (xsp + 24)
	mul wa, 0x64
	lda_d16 xbc, 0x48dc
	extz xwa
	add xwa, xbc
	push xwa
	call Strcpy
	lda xsp, (xsp + 24)
	ld de, (xsp + 4)
	sll de, 2
	lda_d16 xbc, 0x555c
	extz xde
	add xde, xbc
	ldda32 xwa, 0x4888
	ld (xde), xwa
	incm 1, (xsp + 4)

StylCnv_Type3_SearchNext:
	ld xwa, 0x488c
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
	lda_d16 xbc, 0x48dc
	extz xwa
	add xwa, xbc
	push xwa
	lda xwa, (xsp + 22)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xwa, (xsp + 18)
	ld xbc, NakaInst_OFF_Str_0x80
	call FileIO_OpenWithBuiltPath
	cps hl, 0
	jrl lt, StylCnv_AbortWithError
	ld wa, (xsp + 8)
	sll wa, 2
	lda_d16 xbc, 0x555c
	extz xwa
	add xwa, xbc
	ld xbc, (xwa)
	stda32 0x4888, xbc
	ld xwa, (xsp + 10)
	call FileIO_ReadBlock
	cp xhl, 0x0
	jrl lt, FileIO_ErrorExit
	ld bc, (xsp + 8)
	sll bc, 2
	lda_d16 xwa, 0x4788
	extz xbc
	add xbc, xwa
	ld xwa, (xsp + 10)
	ld (xbc), xwa
	ldda32 xwa, 0x4888
	add (xsp + 10), xwa
	ld xwa, (xsp + 10)
	stda32 0x3d60, xwa
	pushw 0x2e
	lda xwa, (xsp + 20)
	push xwa
	call Sprintf_StringLength
	inc 6, xsp
	ld wa, (xsp + 8)
	lda_d16 xbc, 0x3f88
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
	stib_da 0x0ffc00, 0xff
	stib_da 0x0ffc01, 0x00
	ldw (xsp + 16), 0x0
	ldiw_erp 0xfa, 0
	cpw (xsp + 4), 0x0
	jrl le, StylCnv_FinalizeAndCheckStatus

StylCnv_Type3_CopyBlockLoop:
	pushw 0x4
	ld bc, (xsp + 18)
	sll bc, 2
	lda_d16 xwa, 0x4788
	extz xbc
	add xbc, xwa
	push xbc
	stw_erp WA, 0xfa
	inc 2, wa
	extz xwa
	add xwa, 0xffc00
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	inc4w_erp 0xfa
	lds iz, 0
	ld bc, (xsp + 16)
	sll bc, 5
	lda_d16 xde, 0x3f88

StylCnv_Type3_CopyNameChars:
	ld wa, iz
	inc 1, wa
	add wa, bc
	extz xwa
	add xwa, xde
	ld a, (xwa)
	cps a, 0
	jr z, StylCnv_Type3_TerminateName
	stw_erp HL, 0xfa
	inc 2, hl
	extz xhl
	add xhl, 0xffc00
	ld (xhl), a
	inc1w_erp 0xfa
	inc 1, iz
	cp iz, 0x20
	jr lt, StylCnv_Type3_CopyNameChars

StylCnv_Type3_TerminateName:
	stw_erp WA, 0xfa
	inc 2, wa
	extz xwa
	add xwa, 0xffc00
	ld (xwa), 0x0
	inc1w_erp 0xfa
	ld wa, iz
	exts xwa
	divs wa, 0x2
	stw_erp WA, 0xe2
	cps wa, 0
	jr nz, StylCnv_Type3_NextBlock
	stw_erp WA, 0xfa
	inc 2, wa
	extz xwa
	add xwa, 0xffc00
	ld (xwa), 0x0
	inc1w_erp 0xfa

StylCnv_Type3_NextBlock:
	incm 1, (xsp + 16)
	ld wa, (xsp + 16)
	cp wa, (xsp + 4)
	jrl lt, StylCnv_Type3_CopyBlockLoop
	jrl StylCnv_FinalizeAndCheckStatus

StylCnv_Type4_OpenFile:
	ld xwa, 0x488c
	ld xbc, NakaInst_OFF_Str_0x84
	call FileIO_OpenWithMode
	cps hl, 0
	jr lt, StylCnv_AbortWithError
	lds32 xwa, 0
	lds bc, 2
	call FileIO_SeekAndReadBlock
	cps hl, 0
	jr lt, FileIO_ErrorExit
	call FileIO_SeekWriteBlock_Impl
	stda32 0x3d64, xhl
	call FileIO_SeekRead_ExtReturn
	ldda32 xwa, 0x48ae
	lds bc, 0
	call FileIO_SeekAndReadBlock
	cps hl, 0
	jr lt, FileIO_ErrorExit
	ldda32 xwa, 0x3d5c
	ldda32 xbc, 0x48b2
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
	stib_da 0x0ffc00, 0xff
	stib_da 0x0ffc01, 0x00
	pushw 0x4
	pushw 0x0
	pushw 0x3d5c
	ld xwa, 0xffc02
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	ldw (xsp + 4), 0x0
	lda_d16 xde, 0x48b6

StylCnv_Type4_CopyFieldLoop:
	ld bc, (xsp + 4)
	inc 6, bc
	extz xbc
	add xbc, 0xffc00
	ld wa, (xsp + 4)
	inc 1, wa
	ldb_sri A, 0x07, 0xe8, 0xe0
	ld (xbc), a
	cps a, 0
	jrl z, StylCnv_FinalizeAndCheckStatus
	incm 1, (xsp + 4)
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_Type4_CopyFieldLoop
	jrl StylCnv_FinalizeAndCheckStatus

StylCnv_Type6_Dispatch:
	ldw_d16 xwa, 0x48ac
	cps wa, 1
	jrl z, StylCnv_Type6_Case1_CopyName
	cps wa, 0
	jrl nz, StyleConv_DispatchSoundMemState
	lda_d16 xwa, 0x4788
	ld xbc, xwa
	stb_dri B, 0xe1, 0x00, 0x01

StylCnv_Type6_ClearRegion:
	lds32 xwa, 0
	stl_dpi XWA, 0xe6
	cp xbc, xde
	jr c, StylCnv_Type6_ClearRegion
	ldda32 xwa, 0x3d5c
	stda32 0x3d60, xwa
	ldw (xsp + 4), 0x0
	cpdi16 0x48d8, 0
	jrl ule, StylCnv_Type6_BuildFfcBuffer

StylCnv_Type6_MainLoop:
	lds iz, 0
	lda_d16 xbc, 0x488c

StylCnv_Type6_FindDot:
	cpib_sri 0x07, 0xe4, 0xf8, 0x2e
	jr z, StylCnv_Type6_ClearRemainder
	inc 1, iz
	cp iz, 0x20
	jr lt, StylCnv_Type6_FindDot

StylCnv_Type6_ClearRemainder:
	cp iz, 0x20
	jr ge, StylCnv_Type6_AppendName

StylCnv_Type6_ClearLoop:
	stib_ind 0x07, 0xe4, 0xf8, 0x00
	inc 1, iz
	cp iz, 0x20
	jr lt, StylCnv_Type6_ClearLoop

StylCnv_Type6_AppendName:
	ld de, (xsp + 4)
	sll de, 5
	lda_d16 xwa, 0x3f88
	extz xde
	add xde, xwa
	push xde
	push xbc
	call Strcat
	inc 8, xsp
	ld xwa, 0x488c
	ld xbc, NakaInst_OFF_Str_0x88
	call FileIO_OpenWithMode
	cps hl, 0
	jrl lt, StylCnv_Type6_FileOpenError
	lds32 xwa, 0
	lds bc, 2
	call FileIO_SeekAndReadBlock
	cps hl, 0
	jrl lt, StylCnv_Type6_FileReadError
	call FileIO_SeekWriteBlock_Impl
	stda32 0x3d64, xhl
	call FileIO_SeekRead_ExtReturn
	ldda32 xwa, 0x3d60
	ldda32 xbc, 0x3d64
	call FileIO_ReadBlock
	call FileIO_CloseHandle
	cp xhl, 0x0
	jrl lt, StylCnv_AbortWithError
	ld bc, (xsp + 4)
	sll bc, 2
	lda_d16 xwa, 0x4788
	extz xbc
	add xbc, xwa
	ldda32 xwa, 0x3d60
	ld (xbc), xwa
	ldda32 xwa, 0x3d64
	adddm32 0x3d60, xwa

StylCnv_Type6_AdvanceEntry:
	incm 1, (xsp + 4)
	ld wa, (xsp + 4)
	cpda16 xwa, 0x48d8
	jrl c, StylCnv_Type6_MainLoop

StylCnv_Type6_BuildFfcBuffer:
	calr SoundMem_ClearRegion
	stib_da 0x0ffc00, 0xff
	stib_da 0x0ffc01, 0x00
	ldw (xsp + 4), 0x0
	lds iz, 0
	cpdi16 0x48d8, 0
	jrl ule, StylCnv_FinalizeAndCheckStatus

StylCnv_Type6_CopyBlockLoop:
	ld bc, (xsp + 4)
	sll bc, 2
	lda_d16 xde, 0x4788
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
	add xwa, 0xffc00
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	inc 4, iz
	ldw (xsp + 6), 0x0
	ld bc, (xsp + 4)
	sll bc, 5
	lda_d16 xde, 0x3f88

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
	add xhl, 0xffc00
	ld (xhl), a
	inc 1, iz
	incm 1, (xsp + 6)
	cpw (xsp + 6), 0x20
	jr lt, StylCnv_Type6_CopyNameChars

StylCnv_Type6_TerminateName:
	ld wa, iz
	inc 2, wa
	extz xwa
	add xwa, 0xffc00
	ld (xwa), 0x0
	inc 1, iz
	ld wa, (xsp + 6)
	exts xwa
	divs wa, 0x2
	stw_erp WA, 0xe2
	cps wa, 0
	jr nz, StylCnv_Type6_NextBlock
	ld wa, iz
	inc 2, wa
	extz xwa
	add xwa, 0xffc00
	ld (xwa), 0x0
	inc 1, iz

StylCnv_Type6_NextBlock:
	incm 1, (xsp + 4)
	ld wa, (xsp + 4)
	cpda16 xwa, 0x48d8
	jrl c, StylCnv_Type6_CopyBlockLoop
	jrl StylCnv_FinalizeAndCheckStatus

StylCnv_Type6_FileReadError:
	ld bc, (xsp + 4)
	sll bc, 5
	lda_d16 xwa, 0x3f88
	extz xbc
	add xbc, xwa
	ld (xbc), 0x0
	cpdi16 0x48d8, 2
	jrl nc, StylCnv_Type6_AdvanceEntry
	jrl StylCnv_AbortWithError

StylCnv_Type6_FileOpenError:
	ld bc, (xsp + 4)
	sll bc, 5
	lda_d16 xwa, 0x3f88
	extz xbc
	add xbc, xwa
	ld (xbc), 0x0
	cpdi16 0x48d8, 2
	jrl nc, StylCnv_Type6_AdvanceEntry
	jrl StylCnv_AbortWithError

StylCnv_Type6_Case1_CopyName:
	ldw_d16 xbc, 0x3d04
	mul bc, 0x25
	lda_d16 xwa, 0x55e5
	extz xbc
	add xbc, xwa
	push xbc
	lda xwa, (xsp + 22)
	push xwa
	call Strcpy
	inc 8, xsp
	ldda32 xwa, 0x3d5c
	ld (xsp + 10), xwa
	ldw (xsp + 8), 0x0
	lda xwa, (xsp + 18)
	ld xbc, NakaInst_OFF_Str_0x8C
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
	stda32 0x4788, xwa
	ld xwa, (xsp + 14)
	add (xsp + 10), xwa
	ldw (xsp + 4), 0x0
	lda xwa, (xsp + 18)

StylCnv_Single_FindDot:
	ld bc, (xsp + 4)
	cpib_sri 0x07, 0xe0, 0xe4, 0x2e
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
	lda_d16 xbc, 0x3f88
	extz xde
	add xde, xbc
	ld bc, (xsp + 4)
	ldb_sri C, 0x07, 0xe0, 0xe4
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
	cp (xbc), 0x2e
	jr z, StylCnv_Single_WriteTMExtension
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_Single_FindDot2

StylCnv_Single_WriteTMExtension:
	ld bc, (xsp + 4)
	stib_ind 0x07, 0xe0, 0xe4, 0x54
	ld bc, (xsp + 4)
	inc 1, bc
	stib_ind 0x07, 0xe0, 0xe4, 0x4d
	ld bc, (xsp + 4)
	inc 2, bc
	stib_ind 0x07, 0xe0, 0xe4, 0x00
	ld xbc, NakaInst_OFF_Str_0x90
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
	stda32 0x478c, xwa
	ld xwa, (xsp + 14)
	add (xsp + 10), xwa
	ldw (xsp + 4), 0x0
	lda xbc, (xsp + 18)

StylCnv_LSW_FindDot:
	ld wa, (xsp + 4)
	cpib_sri 0x07, 0xe4, 0xe0, 0x2e
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
	lda_d16 xwa, 0x3f88
	extz xde
	add xde, xwa
	ld wa, (xsp + 4)
	ldb_sri A, 0x07, 0xe4, 0xe0
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
	cp (xbc), 0x2e
	jr z, StylCnv_LSW_WriteExtension
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_LSW_FindDot2

StylCnv_LSW_WriteExtension:
	ld bc, (xsp + 4)
	stib_ind 0x07, 0xe0, 0xe4, 0x4c
	ld bc, (xsp + 4)
	inc 1, bc
	stib_ind 0x07, 0xe0, 0xe4, 0x53
	ld bc, (xsp + 4)
	inc 2, bc
	stib_ind 0x07, 0xe0, 0xe4, 0x57
	ld bc, (xsp + 4)
	inc 3, bc
	stib_ind 0x07, 0xe0, 0xe4, 0x00
	ld xbc, NakaInst_OFF_Str_0x94
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
	lda_d16 xwa, 0x4788
	extz xbc
	add xbc, xwa
	ld xwa, (xsp + 10)
	ld (xbc), xwa
	ldw (xsp + 4), 0x0
	lda xbc, (xsp + 18)

StylCnv_LSW_FindDot3:
	ld wa, (xsp + 4)
	cpib_sri 0x07, 0xe4, 0xe0, 0x2e
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
	lda_d16 xwa, 0x3f88
	extz xde
	add xde, xwa
	ld wa, (xsp + 4)
	ldb_sri A, 0x07, 0xe4, 0xe0
	ld (xde), a
	cps a, 0
	jr z, FileLoad_ResetAndStartProcessing
	incm 1, (xsp + 4)
	inc 1, iz
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_LSW_CopyExt3_Loop

FileLoad_ResetAndStartProcessing:
	calr SoundMem_ClearRegion
	stib_da 0x0ffc00, 0xff
	stib_da 0x0ffc01, 0x00
	ldw (xsp + 4), 0x0
	lds iz, 0
	ld wa, (xsp + 8)
	add wa, 0x1
	jrl le, StylCnv_FinalizeAndCheckStatus

StylCnv_Final_CopyBlockLoop:
	pushw 0x4
	ld bc, (xsp + 6)
	sll bc, 2
	lda_d16 xwa, 0x4788
	extz xbc
	add xbc, xwa
	push xbc
	ld wa, iz
	inc 2, wa
	extz xwa
	add xwa, 0xffc00
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	inc 4, iz
	ldw (xsp + 6), 0x0
	ld bc, (xsp + 4)
	sll bc, 5
	lda_d16 xde, 0x3f88

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
	add xhl, 0xffc00
	ld (xhl), a
	inc 1, iz
	incm 1, (xsp + 6)
	cpw (xsp + 6), 0x20
	jr lt, StylCnv_Final_CopyNameChars

StylCnv_Final_TerminateName:
	ld wa, iz
	inc 2, wa
	extz xwa
	add xwa, 0xffc00
	ld (xwa), 0x0
	inc 1, iz
	ld wa, (xsp + 6)
	exts xwa
	divs wa, 0x2
	stw_erp WA, 0xe2
	cps wa, 0
	jr nz, StylCnv_Final_NextBlock
	ld wa, iz
	inc 2, wa
	extz xwa
	add xwa, 0xffc00
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
	stdi16 0x3a82, 0
	lda xbc, (xsp + 18)
	ld xwa, xbc
	lda xbc, (xbc + 100)

StylCnv_Multi_ClearLoop:
	stib_dsp 0xe0, 0x00
	cp xwa, xbc
	jr c, StylCnv_Multi_ClearLoop
	ldw (xsp + 4), 0x0
	lds iz, 0

StylCnv_Multi_ParseLoop:
	lda_d16 xbc, 0x3d68
	ld wa, (xsp + 4)
	stb_dri C, 0x07, 0xe4, 0xe0
	ld e, (xhl)
	lda xbc, (xsp + 18)
	lda_d16 xwa, 0x55e4
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
	incdi16 1, 0x3a82
	jr StylCnv_Multi_Finalize

StylCnv_Multi_HandleSeparator:
	cp e, 0x7c
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
	stib_dsp 0xe0, 0x00
	cp xwa, xbc
	jr c, StylCnv_Multi_ClearSubLoop
	incdi16 1, 0x3a82
	jr LoopCounter_Increment

StylCnv_Multi_CopyChar:
	cps iz, 0
	jr le, LoopCounter_Increment
	ld wa, (xsp + 6)
	lda_dri XIY, 0x07, 0xe4, 0xe0
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
	call	Boot_CheckConfigFlag7
	cps	hl, 0
	ret	z
	cpdi8	0xc07d, 65
	ret	nz
	bitda	0, 0xc07f
	ret	z
	ldb_d8	c, 0x8d36
	bitda	0, 0xc07e
	jr	z, 10
	cp	c, 17
	ret	nz
	ldw	wa, 16
	jr	98
	ldb_d8	a, 0x3d06
	cp	c, 18
	jr	z, 61
	cp	c, 20
	jr	z, 18
	cp	c, 16
	ret	nz
	call	FileIO_CheckMediaIsWritable
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
	call	FileIO_CheckMediaIsWritable
	cps	hl, 0
	ret	nz
	ldw	wa, 18
	jr	41
	call	FileIO_CheckMediaIsWritable
	cps	hl, 0
	ret	nz
	ldw	wa, 18
	jr	28
	cps	a, 2
	jr	z, 4
	cps	a, 1
	ret	nz
	call	FileIO_CheckMediaIsWritable
	cps	hl, 0
	ret	nz
	ld	xwa, 0x3d08
	call	ControlState_ProcessCommand
	ldw	wa, 18
	call	UI_PostModeChangeEvent
	ret
	lda	xsp, (xsp-34)
	push	xiz
	ld	(xsp+34), c
	ld	(xsp+36), a
	ld	xiy, NakaInst_OFF_Str_0xB6
	lda	xix, (xsp+4)
	ldw	bc, 15
	ldirw
	lda_24	xde, 0x094800
	lda_24	xbc, 0x0ab000
	sub	xbc, xde
	ld	xwa, 0x069800
	call	FileIO_ReadBlock
	cp	xhl, 0
	jrl	lt, 731
	lda_24	xbc, 0x069800
	stda32	0x7ae4, xbc
	lda_24	xwa, 0x094800
	stda32	0x7ae8, xwa
	stdi8	0x3950, 0
	ld	a, (xbc)
	ldb_erp	a, 249
	ld	a, (xbc+1)
	ldb_erp	a, 250
	ld	a, (xbc+2)
	ldb_erp	a, 251
	cp_erpb	249, 72
	jr	nz, 11
	cpib_erp	250, 0
	jr	nz, 6
	cp_erpb	251, 75
	jr	z, 38
	cp_erpb	249, 71
	jr	nz, 11
	cpib_erp	250, 0
	jr	nz, 6
	cp_erpb	251, 75
	jr	z, 21
	cp_erpb	249, 76
	jrl	nz, 336
	cp_erpb	250, 75
	jrl	nz, 329
	cp_erpb	251, 69
	jrl	nz, 322
	ldda32	xwa, 0x7ae4
	ld	(xwa), 72
	ldda32	xwa, 0x7ae4
	ld	(xwa+1), 0
	ldda32	xwa, 0x7ae4
	ld	(xwa+2), 75
	ldda32	xbc, 0x7ae8
	cp	(xsp+36), 29
	jrl	ule, 264
	cp	(xsp+34), 29
	jrl	ule, 257
	ldda32	xwa, 0x7ae4
	ld	e, (xwa+14)
	cps	e, 0
	jr	nz, 6
	cp	(xwa+15), 0
	jr	z, 13
	ld	(xbc+14), e
	ldda32	xwa, 0x7ae4
	ld	a, (xwa+15)
	ld	(xbc+15), a
	cp_erpb	249, 72
	jr	nz, 12
	cpib_erp	250, 0
	jr	nz, 7
	cp_erpb	251, 75
	jrl	z, 147
	ld	a, (xsp+36)
	sub	a, 30
	extz	wa
	extz	xwa
	add	xwa, NakaInst_OFF_Str_0x98
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
	ldda32	xwa, 0x7ae4
	lda_rr	xwa, xwa, iz
	ld	(xwa+34), 64
	ld	a, (xhl)
	extz	wa
	muls	wa, 96
	ld	iz, wa
	add	iz, 96
	ldda32	xwa, 0x7ae4
	lda_rr	xwa, xwa, iz
	ld	(xwa+42), 12
	ld	a, (xde)
	extz	wa
	muls	wa, 96
	ld	iz, wa
	add	iz, 96
	ldda32	xwa, 0x7ae4
	lda_rr	xwa, xwa, iz
	ld	(xwa+50), 116
	ld	a, (xbc)
	extz	wa
	muls	wa, 96
	ld	iz, wa
	add	iz, 96
	ldda32	xwa, 0x7ae4
	lda_rr	xwa, xwa, iz
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
	ldb_d8	a, 0x3950
	extz	wa
	bit	0, wa
	jrl	z, 357
	ldda32	xwa, 0x7ae8
	stda32	0x39ae, xwa
	cp	(xsp+34), 30
	jrl	nc, 293
	ld	c, (xsp+34)
	extz	bc
	lda	xwa, (xsp+4)
	.byte 0xc3
	reti
	.byte 0xe0, 0xe4
	pop_f
	.byte 0xac
	push	xbc
	call	AccPatch_InitFromSlotIndex
	jrl	320
	cp	(xsp+36), 29
	jr	ule, 6
	cp	(xsp+34), 30
	jr	c, 12
	cp	(xsp+36), 30
	jr	nc, 14
	cp	(xsp+34), 29
	jr	ule, 8
	stdi8	0x3950, 130
	jrl	304
	stda32	0x39ae, xbc
	ld	c, (xsp+34)
	extz	bc
	lda	xwa, (xsp+4)
	.byte 0xc3
	reti
	.byte 0xe0, 0xe4
	pop_f
	.byte 0xac
	push	xbc
	call	AccPatch_InitFromSlotIndex
	cp_erpb	249, 72
	jr	nz, 11
	cpib_erp	250, 0
	jr	nz, 6
	cp_erpb	251, 75
	jr	z, 121
	ld	a, (xsp+36)
	extz	wa
	lda	xbc, (xsp+4)
	lda_rr	xbc, xbc, wa
	ld	a, (xbc)
	extz	wa
	muls	wa, 96
	ld	de, wa
	add	de, 96
	ldda32	xwa, 0x7ae4
	lda_rr	xwa, xwa, de
	ld	(xwa+34), 64
	ld	a, (xbc)
	extz	wa
	muls	wa, 96
	ld	de, wa
	add	de, 96
	ldda32	xwa, 0x7ae4
	lda_rr	xwa, xwa, de
	ld	(xwa+42), 12
	ld	a, (xbc)
	extz	wa
	muls	wa, 96
	ld	de, wa
	add	de, 96
	ldda32	xwa, 0x7ae4
	lda_rr	xwa, xwa, de
	ld	(xwa+50), 116
	ld	a, (xbc)
	extz	wa
	muls	wa, 96
	ld	bc, wa
	add	bc, 96
	ldda32	xwa, 0x7ae4
	lda_rr	xwa, xwa, bc
	ld	(xwa+58), 64
	ldda32	xwa, 0x7ae4
	stda32	0x39ae, xwa
	ldda32	xwa, 0x7ae8
	stda32	0x39b2, xwa
	ld	a, (xsp+36)
	extz	wa
	lda	xbc, (xsp+4)
	.byte 0xc3
	reti
	.byte 0xe4, 0xe0
	pop_f
	.byte 0xac
	push	xbc
	ld	a, (xsp+34)
	extz	wa
	.byte 0xc3
	reti
	.byte 0xe4, 0xe0
	pop_f
	.byte 0xad
	push	xbc
	resda	0, 0x35b0
	call	DualVoice_ParamLoadDone
	ldb_d8	a, 0x35b0
	extz	wa
	bit	0, wa
	jr	z, 8
	stdi8	0x3950, 131
	jrl	-312
	stdi8	0x3950, 0
	jrl	-320
	ldib_erp	251, 0
	ld	c, (xsp+34)
	sub	c, 30
	extz	bc
	stb_erp	a, 251
	extz	wa
	muls	wa, 3
	ld	de, wa
	add	de, bc
	lda_24	xwa, NakaInst_OFF_Str_0x98
	.byte 0xc3
	reti
	.byte 0xe0, 0xe8
	pop_f
	.byte 0xac
	push	xbc
	call	AccPatch_InitFromSlotIndex
	incb_erp	251, 1
	cp_erpb	251, 10
	jr	c, -46
	cpdi8	0x3950, 131
	jr	nz, 5
	ldw	hl, 0xff95
	jr	6
	call	AccPatch_MultiCallWrapper_0x13
	lds	hl, 0
	pop	xiz
	lda	xsp, (xsp+34)
	ret
	dec	4, xsp
	push qiz
	ld	(xsp+2), c
	ld	(xsp+4), a
	ldda32	xwa, 0x7ae8
	stda32	0x39ae, xwa
	ldib_erp	251, 0
	ld	c, (xsp+2)
	sub	c, 30
	extz	bc
	stb_erp	a, 251
	extz	wa
	muls	wa, 3
	ld	de, wa
	add	de, bc
	lda_24	xwa, NakaInst_OFF_Str_0x98
	.byte 0xc3
	reti
	.byte 0xe0, 0xe8
	pop_f
	.byte 0xac
	push	xbc
	call	AccPatch_InitFromSlotIndex
	incb_erp	251, 1
	cp_erpb	251, 10
	jr	c, -46
	ldda32	xwa, 0x7ae4
	stda32	0x39ae, xwa
	ldda32	xwa, 0x7ae8
	stda32	0x39b2, xwa
	stdi8	0x3950, 0
	resda	0, 0x35b0
	ldib_erp	251, 0
	ld	e, (xsp+4)
	sub	e, 30
	extz	de
	stb_erp	a, 251
	extz	wa
	muls	wa, 3
	ld	bc, wa
	add	wa, de
	lda_24	xde, NakaInst_OFF_Str_0x98
	.byte 0xc3
	reti
	or	xwa, xwa
	pop_f
	.byte 0xac
	push	xbc
	ld	a, (xsp+2)
	sub	a, 30
	extz	wa
	add	bc, wa
	.byte 0xc3
	reti
	or	xix, xwa
	pop_f
	.byte 0xad
	push	xbc
	call	DualVoice_ParamLoadDone
	ldb_d8	a, 0x35b0
	extz	wa
	bit	0, wa
	jr	z, 7
	stdi8	0x3950, 131
	jr	9
	incb_erp	251, 1
	cp_erpb	251, 10
	jr	c, -81
	pop qiz
	inc	4, xsp
	ret

	.include "sequencer/accompseq_routines.s"
